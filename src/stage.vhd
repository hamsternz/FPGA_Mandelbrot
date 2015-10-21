-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : stage.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- This is the the calculation engine my fractal viewer. It is a 13 stage
-- pipeline, that evicts one set of values when each new input value is presented.
-- If you present new input one cycle in three, then each item will go around the 
-- pipeline three times before being ejected. 
--
-- Multiple instances of stages can be cascaded together to get the depth you wish.
--
-- Although the a*b multiplication is inferred, the a*a multiplicaiton is acheived
-- using primatives. This has two benefits:
--
-- * It saves DSP blocks, as a:b * a:b can be calculated as a*a:0:0 + 2*a*b:0 + b*b,
--   rather than a*a:0:0 + a*b:0:0 + a*b:0:0 + b*b, which uses four DSP blocks.
--   This allows a stage to use 10 multiplications, rather than the 12 that is 
--   inferred.
-- * Some of the multiplcations can be implemented using LUTs rather than DSP blocks
--   incresing the FPGA LUT rersource usage and increasing the number of stages that
--   can fit on a given device.
--
-- The pipeline is set up using long/wide shift registers that cover all steps of
-- the pipeline, and it is left up to the optimizer to trim out the large number
-- of unused registers. It makes the code a lot simpler.
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity stage is
    generic (
        phase_len     : integer;
        use_lut_mults : integer 
    );
      port (
        clk          : in std_logic;
        -- Inputs
        ca_in        : in std_logic_vector; -- The real constant
        cb_in        : in std_logic_vector; -- The imaginary constant
        a_in         : in std_logic_vector; -- the current real value
        b_in         : in std_logic_vector; -- the current imaginary value
        i_in         : in std_logic_vector; -- the current increment count
        overflow_in  : in std_logic;        -- has an overflow occured?
        sync_in      : in std_logic_vector; -- any control/video signals along for the ride

        ca_out       : out std_logic_vector;
        cb_out       : out std_logic_vector;
        a_out        : out std_logic_vector;
        b_out        : out std_logic_vector;
        i_out        : out std_logic_vector;
        overflow_out : out std_logic;
        sync_out     : out std_logic_vector
    );
end entity;

architecture stage_arch of stage is
   constant latency : integer := 13;
   constant scale   : integer := 4;
   constant mult_size : integer := 35;

  component mult_u17_u17_l4 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
  end component;
  component mult_u17_u17_l4_lut IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
  end component;

  component mult_u17_u17_l5_lut IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
  end component;
   
   signal phase  : std_logic_vector(phase_len-1 downto 0) := (0 => '1', others => '0');                                 

   type a_sync is array(latency-1 downto 0) of std_logic_vector(sync_in'range);
   signal sync : a_sync := (others => (others =>'0'));

   type a_i is array (latency-1 downto 0) of unsigned(i_in'range);
   signal i : a_i  := (others => (others =>'0'));

   type a_ca is array (latency-1 downto 0) of signed(ca_in'range);
   signal ca : a_ca  := (others => (others =>'0'));

   type a_cb is array (latency-1 downto 0) of signed(cb_in'range);
   signal cb : a_cb  := (others => (others =>'0'));

   type a_a is array (latency-1 downto 0) of signed(a_in'range);
   signal a : a_a  := (others => (others =>'0'));


   type a_b is array (latency-1 downto 0) of signed(b_in'range);
   signal b : a_b  := (others => (others =>'0'));
  
  ----------------------------------------------------- 
   -- Working storage. Most of this gets optimized away
  ----------------------------------------------------- 
   type a_a_abs is array (latency-1 downto 0) of unsigned(a_in'range);
   signal a_abs : a_a_abs := (others => (others =>'0'));

   type a_b_abs is array (latency-1 downto 0) of unsigned(a_in'range);
   signal b_abs : a_b_abs := (others => (others =>'0'));

   type a_a_times_b is array (latency-1 downto 0) of signed(a_in'length+b_in'length-1 downto 0);
   signal a_times_b : a_a_times_b  := (others => (others =>'0'));

   type a_a_squared is array (latency-1 downto 0) of unsigned(a_in'length+a_in'length-1 downto 0);
   signal a_squared      : a_a_squared  := (others => (others =>'0'));

   type a_a_squared_partial is array (latency-1 downto 0) of unsigned(33 downto 0);
   signal a_squared_hh : a_a_squared_partial  := (others => (others =>'0'));
   signal a_squared_hl : a_a_squared_partial  := (others => (others =>'0'));
   signal a_squared_ll : a_a_squared_partial  := (others => (others =>'0'));

   type a_b_squared is array (latency-1 downto 0) of unsigned(b_in'length+b_in'length-1 downto 0);
   signal b_squared      : a_b_squared  := (others => (others =>'0'));
   
   type a_b_squared_partial is array (latency-1 downto 0) of unsigned(33 downto 0);
   signal b_squared_hh : a_b_squared_partial  := (others => (others =>'0'));
   signal b_squared_hl : a_b_squared_partial  := (others => (others =>'0'));
   signal b_squared_ll : a_b_squared_partial  := (others => (others =>'0'));

   type a_magnitude is array (latency-1 downto 0) of unsigned(a_in'length-1 downto 0);
   signal magnitude : a_magnitude  := (others => (others =>'0'));

   signal overflow   : std_logic_vector(latency -1 downto 0) := (others => '0');
   signal mult_fault : std_logic; 
   
   signal a_s_hh : std_logic_vector(33 downto 0);
   signal a_s_hl : std_logic_vector(33 downto 0);
   signal a_s_ll : std_logic_vector(33 downto 0);

   signal b_s_hh : std_logic_vector(33 downto 0);
   signal b_s_hl : std_logic_vector(33 downto 0);
   signal b_s_ll : std_logic_vector(33 downto 0);
   
begin
--   mult_fault <= '0' when signed(a_squared(2)) = a_squared_orig(2) else '1';
clk_proc: process(clk)
    begin
        if rising_edge(clk) then
           -----------------------------------------------------------------
           -- First things, pass through all the signals, we will later
           -- overwrite the intermediate values with results of calculations
           --
           -- We will also rely on the optimizer to remove any infered shift
           -- registers that lead to dead-ends. This will give lots of 
           -- warning but will allow for easy incremental development.
           ------------------------------------------------------------

           if phase(0) = '1' then
               overflow <= overflow_in    & overflow(latency-1 downto 1);
               sync     <= sync_in        & sync(latency-1 downto 1);
               ca       <= signed(ca_in)  & ca(latency-1 downto 1);  
               cb       <= signed(cb_in)  & cb(latency-1 downto 1);
               a        <= signed(a_in)   & a(latency-1 downto 1);
               b        <= signed(b_in)   & b(latency-1 downto 1);
               i        <= unsigned(i_in) & i(latency-1 downto 1);
               
               overflow_out <= overflow(0);
               sync_out     <= sync(0);
               ca_out       <= std_logic_vector(ca(0));
               cb_out       <= std_logic_vector(cb(0));
               a_out        <= std_logic_vector(a(0));
               b_out        <= std_logic_vector(b(0)); 
               i_out        <= std_logic_vector(i(0));
           else
               overflow <= overflow(0) & overflow(latency-1 downto 1);
               sync     <= sync(0)     & sync(latency-1 downto 1);
               ca       <= ca(0)       & ca(latency-1 downto 1);  
               cb       <= cb(0)       & cb(latency-1 downto 1);
               a        <= a(0)        & a(latency-1 downto 1);
               b        <= b(0)        & b(latency-1 downto 1);
               i        <= i(0)        & i(latency-1 downto 1);
           end if;
           phase <= phase(0) & phase(phase'high downto 1);

           ----------------------------------------------------
           -- Now do the same for the working storage
           ----------------------------------------------------
           a_times_b      <= a_times_b(latency-1)      & a_times_b(latency-1 downto 1);

           a_abs          <= a_abs(latency-1)          & a_abs(latency-1 downto 1);
           a_squared      <= a_squared(latency-1)      & a_squared(latency-1 downto 1);
           if use_lut_mults > 0 then 
               a_squared_hh(3 downto 0) <= a_squared_hh(4 downto 1);
           else
               a_squared_hh(4 downto 0) <= a_squared_hh(5 downto 1);
           end if;
           a_squared_hl(4 downto 0) <= a_squared_hl(5 downto 1);
           a_squared_ll(4 downto 0) <= a_squared_ll(5 downto 1);

           b_abs          <= b_abs(latency-1)          & b_abs(latency-1 downto 1);
           b_squared      <= b_squared(latency-1)      & b_squared(latency-1 downto 1);
           if use_lut_mults > 1 then 
              b_squared_hh(3 downto 0) <= b_squared_hh(4 downto 1);
           else
              b_squared_hh(4 downto 0) <= b_squared_hh(5 downto 1);
           end if;
           b_squared_hl(4 downto 0) <= b_squared_hl(5 downto 1);
           b_squared_ll(4 downto 0) <= b_squared_ll(5 downto 1);
           magnitude      <= magnitude(latency-1)      & magnitude(latency-1 downto 1);

-------------------
-- Pipeline stage 0
-------------------
           ----------------------------------------------------
           -- Increase the iteration count, as long as we have
           -- not had an overflow. We don't need to check if 'i' 
           -- will roll over as we will have a fixed number of 
           -- stages it will pass though.
           ----------------------------------------------------
           if overflow(1) = '0' then
             i(0) <= i(1)+1;
           end if;

           ----------------------------------------------------
           -- Add on the constants to the real and imaginary
           -- parts
           ----------------------------------------------------
           a(0) <= a(1) + ca(1);
           b(0) <= b(1) + cb(1);

-------------------
-- Pipeline stage 1
-------------------
           --------------------------------------
           -- Check for overflow in the magnitude
           --------------------------------------
           if magnitude(2)(magnitude(2)'high downto magnitude(2)'high-1) /= "00" then
             overflow(1) <= '1';
           end if;
-------------------
-- Pipeline stage 2
-------------------
           ----------------------------------------------------
           -- Compute
           --  a <= a*a-b*b
           --  b <= 2*a*b;
           ----------------------------------------------------
           a(2) <= (others => '0');
           a(2)(a(2)'high downto a(2)'high-mult_size+1) <= signed(a_squared(3)(65 downto 65-mult_size+1) - b_squared(3)(65 downto 65-mult_size+1));
           b(2) <= (others => '0');
           b(2)(b(2)'high downto b(2)'high-mult_size+1) <= a_times_b(3)(64 downto 64-mult_size+1); -- Note - implicit scaling by 2 in the bit slice used
           magnitude(2) <= (others => '0');
           magnitude(2)(magnitude(2)'high downto magnitude(2)'high-mult_size+1) <= a_squared(3)(65 downto 65-mult_size+1) + b_squared(3)(65 downto 65-mult_size+1);
         
           if a_squared(3)(a_squared(3)'high downto a_squared(3)'high-5) /= "000000" or 
              b_squared(3)(b_squared(3)'high downto b_squared(3)'high-5) /= "000000"  then
             overflow(2) <= '1';
           end if;

-------------------
-- Pipeline stage 3
-------------------
            -- No processing done to allow for pipelinging the output of the multipliers
            a_squared(3) <=  a_squared(4) + (a_squared_hh(4) & "00" & x"00000000"); 
            b_squared(3) <=  b_squared(4) + (b_squared_hh(4) & "00" & x"00000000"); 
-------------------
-- Pipeline stage 4
-------------------
            -- No processing done to allow for pipelinging the output of the multipliers 
            A_squared(4) <= (others => '0'); 
            a_squared(4)(52 downto 0) <=  ("0" & a_squared_hl(5) & "00" & x"0000") + a_squared_ll(5);
            b_squared(4) <= (others => '0'); 
            b_squared(4)(52 downto 0) <=  ("0" & b_squared_hl(5) & "00" & x"0000") + b_squared_ll(5); 
-------------------
-- Pipeline stage 8
-------------------

--   These have been replaced with explicitly defined multipliers
--   to optimize resource usage.
--              
--            a_squared_orig(8) <= a(9) * a(9);
--            b_squared_orig(8) <= b(9) * b(9);

            a_times_b(8) <= a(9) * b(9);
            if a(9)(a(9)'high) /= a(9)(a(9)'high-1) or b(9)(b(9)'high) /= b(9)(b(9)'high-1) then
             overflow(8) <= '1';
            end if;   
-------------------
-- Pipeline stage 10
-------------------
            if a(11)(a(11)'high) = '1' then
                a_abs(10) <= unsigned((not a(11)) + 1);
            else
                a_abs(10) <= unsigned(a(11));
            end if;

            if b(11)(b(11)'high) = '1' then
                b_abs(10) <= unsigned((not b(11)) + 1);
            else
                b_abs(10) <= unsigned(b(11));
            end if;
        end if;
    end process;
    

------------------------------------------------
-- When two MULTs are implemented in LUTs
------------------------------------------------
g_hh2: if use_lut_mults > 1 generate
    
m_a_hh2: mult_u17_u17_l5_lut PORT MAP (
        clk => clk,
        a => std_logic_vector(a_abs(9)(33 downto 17)),
        b => std_logic_vector(a_abs(9)(33 downto 17)),
        p => a_s_hh
    );
    a_squared_hh(4) <= unsigned(a_s_hh);

m_b_hh2: mult_u17_u17_l5_lut PORT MAP (
            clk => clk,
            a => std_logic_vector(b_abs(9)(33 downto 17)),
            b => std_logic_vector(b_abs(9)(33 downto 17)),
            p => b_s_hh
    );
    b_squared_hh(4) <= unsigned(b_s_hh);
end generate;

------------------------------------------------
-- When one MULTs are implemented in LUTs
------------------------------------------------
g_hh1: if use_lut_mults = 1 generate
    
m_a_hh1: mult_u17_u17_l5_lut PORT MAP (
        clk => clk,
        a => std_logic_vector(a_abs(9)(33 downto 17)),
        b => std_logic_vector(a_abs(9)(33 downto 17)),
        p => a_s_hh
    );
    a_squared_hh(4) <= unsigned(a_s_hh);

m_b_hh1: mult_u17_u17_l4 PORT MAP (
            clk => clk,
            a => std_logic_vector(b_abs(9)(33 downto 17)),
            b => std_logic_vector(b_abs(9)(33 downto 17)),
            p => b_s_hh
    );
    b_squared_hh(5) <= unsigned(b_s_hh);
end generate;

------------------------------------------------
-- When no MULTs are implemented in LUTs
------------------------------------------------
g_hh0: if use_lut_mults = 0 generate
    
m_a_hh0: mult_u17_u17_l4 PORT MAP (
        clk => clk,
        a => std_logic_vector(a_abs(9)(33 downto 17)),
        b => std_logic_vector(a_abs(9)(33 downto 17)),
        p => a_s_hh
    );
    a_squared_hh(5) <= unsigned(a_s_hh);

m_b_hh0: mult_u17_u17_l4 PORT MAP (
            clk => clk,
            a => std_logic_vector(b_abs(9)(33 downto 17)),
            b => std_logic_vector(b_abs(9)(33 downto 17)),
            p => b_s_hh
    );
    b_squared_hh(5) <= unsigned(b_s_hh);
end generate;


m_a_hl: mult_u17_u17_l4 PORT MAP (
        clk => clk,
        a => std_logic_vector(a_abs(9)(33 downto 17)),
        b => std_logic_vector(a_abs(9)(16 downto  0)),
        p => a_s_hl
    );
    a_squared_hl(5) <= unsigned(a_s_hl);

m_a_ll: mult_u17_u17_l4 PORT MAP (
        clk => clk,
        a => std_logic_vector(a_abs(9)(16 downto  0)),
        b => std_logic_vector(a_abs(9)(16 downto  0)),
        p => a_s_ll
    );
    a_squared_ll(5) <= unsigned(a_s_ll);

m_b_hl: mult_u17_u17_l4 PORT MAP (
        clk => clk,
        a => std_logic_vector(b_abs(9)(33 downto 17)),
        b => std_logic_vector(b_abs(9)(16 downto  0)),
        p => b_s_hl
    );
    b_squared_hl(5) <= unsigned(b_s_hl);

m_b_ll: mult_u17_u17_l4 PORT MAP (
        clk => clk,
        a => std_logic_vector(b_abs(9)(16 downto 0)),
        b => std_logic_vector(b_abs(9)(16 downto 0)),
        p => b_s_ll
    );
    b_squared_ll(5) <= unsigned(b_s_ll);
                        
end architecture;