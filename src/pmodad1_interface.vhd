library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
 
entity pmodad1_interface is
    port(   clk      : in std_logic;   -- 100MHz clock
            ADC_CS   : out std_logic;  -- ADC chip select
            ADC_SCLK : out std_logic;  -- ADC serial clock
            ADC_D0   : in std_logic;   -- ADC Channel 0
            ADC_D1   : in std_logic;   -- ADC Channel 1
            ch0      : out std_logic_vector(11 downto 0);
            ch1      : out std_logic_vector(11 downto 0)
            );
end pmodad1_interface;
 
architecture Behavioral of pmodad1_interface is    
    signal data_0 : std_logic_vector(11 downto 0) := (others=>'0');
    signal data_1 : std_logic_vector(11 downto 0) := (others=>'0');
    
    -----------------------------------------------------------------------------
    -- You can control the sampling frequency with the length of 
    -- sequncer_shift_reg and ce_sr.
    --
    -- F(sclk) =F(clk)/(2*(ce_sr'length+1))
    --
    -- Sampling freqency is F(sclk)/ (sequncer_shift_reg'length+1)
    --
    -- with 225MHz and ce_sr being 11 bits long SCLK is almost 10MHz.
    -- with sequncer_shift_reg of 19 bits, that gives a sample rate of 0.5MHz
    -----------------------------------------------------------------------------
    signal ce_sr               : std_logic_vector(10 downto 0) := (others=>'X');    
    signal sequncer_shift_reg  : std_logic_vector(18 downto 0) := (others=>'X');
 
    signal clock_state         : std_logic := 'X';
    signal clock_enable        : std_logic := 'X';
    signal din0_shift_reg      : std_logic_vector(15 downto 0) := (others=>'X');
    signal din1_shift_reg      : std_logic_vector(15 downto 0) := (others=>'X');

begin
    ch0 <= std_logic_vector(data_0);
    ch1 <= std_logic_vector(data_1);
    -----------------------------------
    -- Generate the clock_enable signal
    -- For the rest of the design.
    --
    -- Change the length of ce_sr to 
    -- change the Serial clock speed
    -----------------------------------
    clock_divide : process(CLK)
        begin
             if rising_edge(CLK) then
                --------------------------------------
                -- Self-recovering in case of a glitch
                --------------------------------------
                if unsigned(ce_sr) = 0 then
                  ce_sr <= ce_sr(ce_sr'high-1 downto 0) & '1';
                  clock_enable <= '1';
                else
                  ce_sr <= ce_sr(ce_sr'high-1 downto 0) & '0';
                  clock_enable <= '0';
               end if;
            end if;
        end process clock_divide;
        
    main : process (CLK)
        begin
            if rising_edge(CLK) then
               if clock_enable = '1' then
                  if clock_state = '0' then
                     -- Things to do on the rising edge of the clock.
                     
                     -----------------------------------------------------------------
                     -- Capture the bits coming in from the ADC
                     -----------------------------------------------------------------
                     if sequncer_shift_reg(16) = '1' then
                        data_0 <= din0_shift_reg(11 downto 0);
                        data_1 <= din1_shift_reg(11 downto 0);
                     end if;
                     din0_shift_reg <= din0_shift_reg(din0_shift_reg'high-1 downto 0) & adc_d0;
                     din1_shift_reg <= din1_shift_reg(din1_shift_reg'high-1 downto 0) & adc_d1;
   

                     -----------------------------------------------------------------
                     -- And update the sequencing shift register
                     -- Self-recovering in case of a glitch
                     -----------------------------------------------------------------
                     if unsigned(sequncer_shift_reg) = 0 then
                        sequncer_shift_reg <= sequncer_shift_reg(sequncer_shift_reg'high-1 downto 0) & '1'; 
                     else
                        sequncer_shift_reg <= sequncer_shift_reg(sequncer_shift_reg'high-1 downto 0) & '0'; 
                     end if;
                     ----------------------------
                     -- Output rising clock edge
                     ----------------------------
                     adc_sclk    <= '1';
                     clock_state <= '1';
                  else
                     ----------------------------
                     -- Output falling clock edge
                     ----------------------------
                     adc_sclk    <= '0';
                     clock_state <= '0';
                  end if;
               end if;
 
               -----------------------------------------------------------------
               -- A special kludge to get CS to rise and fall while SCLK 
               -- is high on the ADC. This ensures setup and hold times are met.
               -----------------------------------------------------------------
               if ce_sr(ce_sr'length/2) = '1' and clock_state = '1' then
                  if sequncer_shift_reg(0) = '1' then
                     adc_cs <= '1';
                  elsif sequncer_shift_reg(1) = '1' then
                     adc_cs <= '0';
                  end if;
               end if;
            end if;
        end process main;
end Behavioral;
