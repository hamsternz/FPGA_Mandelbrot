-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : top_level.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- This is the top level of my fractal viewer. The big difference from 
-- my other attempts is that it doesn't have a freame buffer - all
-- pixels are completely calculated every time they are shown.
--
-- This allows for very smooth scrolling and zooming, with no 
-- restrictions on the speed of scrolling. However the 'depth' is 
-- limited by the resources available on the FPGA and the pixel 
-- clock rate.
--
-- The performance can be tuned to match the Fmax of the FPGA size,
-- FPGA speed and the screen resolution.
--
-- Config rules:
-- 
-- constant clocks_per_pixel : integer := 9;
--     This is the number of clocks per display pixel
--     It can be anything from 1 to 12. If anything above 12  
--     is used the pipeline in "stage" will eject a pxel too
--     early.
--
-- constant stages : integer := 12;
--     Number of processing stages in the processing pipeline
--     Alter this to change the number of DSP blocks used
--
-- With these values it will allow you to explore at depths of  
-- of 9*12 = 108 iterations. On a larger FPGA you can increase
-- the values.
--
-- Also in stage.vhd, you have the option to implement some of the 
-- multiplications using LUTs rather than DSP blocks. Adjusting
-- this can allow you to include extra stages.
-- 
-- It is currently configured to use 7 DSP blocks per stage, out
-- of a maximum of 10 (the other three are implemented in LUTs). 
--
--
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity top_level is
    Port ( 
-------------------------------------
-- Genesys2 has differnetal clock
-------------------------------------      
        clk100_p    : in STD_LOGIC;
        clk100_n    : in STD_LOGIC;
-------------------------------------
-- Nexys Video has single ended clock  
-------------------------------------      
--        clk100    : in STD_LOGIC;

        
        btnU      : in STD_LOGIC;
        btnD      : in STD_LOGIC;
        btnL      : in STD_LOGIC;
        btnR      : in STD_LOGIC;
        btnC      : in STD_LOGIC;
        
        hdmi_tx_rscl  : out   std_logic;
        hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_hpd   : in    std_logic;
        hdmi_tx_cec   : inout std_logic;
        
        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_p     : out std_logic_vector(2 downto 0);
        hdmi_tx_n     : out std_logic_vector(2 downto 0)
);
end top_level;

architecture Behavioral of top_level is
    constant stages           : integer :=  85;
    constant clocks_per_pixel : integer :=  3;
    
    signal clk_calc      : std_logic;
    signal clk_pixel_x1  : std_logic;
    signal clk_pixel_x5  : std_logic;

    signal blank : std_logic := '0';
    signal hsync : std_logic := '0';
    signal vsync : std_logic := '0';
    signal field         : std_logic;
    signal interlaced    : std_logic;

    component vga_gen_720p is
        port (
           clk        : in  std_logic;
            
           blank      : out std_logic;
           hsync      : out std_logic;
           vsync      : out std_logic;
           field      : out std_logic;
           interlaced : out std_logic
           );
    end component;    

    component vga_gen_1080i is
        port (
           clk        : in  std_logic;
            
           blank      : out std_logic;
           hsync      : out std_logic;
           vsync      : out std_logic;
           field      : out std_logic;
           interlaced : out std_logic
        );
    end component;    

    component user_interface is
        port (
            clk       : in STD_LOGIC;
            btnU      : in STD_LOGIC;
            btnD      : in STD_LOGIC;
            btnL      : in STD_LOGIC;
            btnR      : in STD_LOGIC;
            btnC      : in STD_LOGIC;
            vsync     : in STD_LOGIC;
            x         : out std_logic_vector(34 downto 0);
            y         : out std_logic_vector(34 downto 0);
            scale     : out std_logic_vector(34 downto 0)
           );
    end component;
                                                --- these are in 4.31 fixed-point signed binary
    signal x      : std_logic_vector(34 downto 0) := (others => '0');
    signal y      : std_logic_vector(34 downto 0) := (others => '0');
    signal scale  : std_logic_vector(34 downto 0) := (others => '0');
    
    signal ca_new   : std_logic_vector(34 downto 0) := (others => '0');
    signal cb_new   : std_logic_vector(34 downto 0) := (others => '0');
    signal sync_new : std_logic_vector( 2 downto 0) := (others => '0');


    type a_fixed_point is array (0 to stages) of std_logic_vector(34 downto 0);
    type a_count       is array (0 to stages) of std_logic_vector(7 downto 0);
    type a_sync        is array (0 to stages) of std_logic_vector(2 downto 0);

    signal ca         : a_fixed_point := (others => (others => '0'));
    signal cb         : a_fixed_point := (others => (others => '0'));
    signal a          : a_fixed_point := (others => (others => '0'));
    signal b          : a_fixed_point := (others => (others => '0'));
    signal iterations : a_count       := (0 => "00000001", others => (others => '0'));
    signal sync       : a_sync        := (others => (others => '0'));
    signal overflow   : unsigned(stages downto 0) := (others => '0');

    component generate_constants is
        port (
            clk       : in std_logic;

            blank_in   : in std_logic;
            hsync_in   : in std_logic;
            vsync_in   : in std_logic;
            field      : in std_logic;
            interlaced : in std_logic;

            x         : in  std_logic_vector;
            y         : in  std_logic_vector;
            x_step    : in  std_logic_vector;
            y_step    : in  std_logic_vector;
            
            blank_out : out std_logic;
            hsync_out : out std_logic;
            vsync_out : out std_logic;
            
            ca        : out std_logic_vector;
            cb        : out std_logic_vector

        );
    end component;
    
    component stage is 
    generic (
        phase_len : integer 
    );
    port (
        clk    : std_logic;
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
    end component;

    component vga_output is
        Port ( clk : in STD_LOGIC;
               hsync_in : in STD_LOGIC;
               vsync_in : in STD_LOGIC;
               blank_in : in STD_LOGIC;
               iterations_in : in STD_LOGIC_VECTOR(7 downto 0);
               vga_hsync : out std_logic;
               vga_vsync : out std_logic;
               vga_red   : out std_logic_vector(7 downto 0);
               vga_green : out std_logic_vector(7 downto 0);
               vga_blue  : out std_logic_vector(7 downto 0);
               vga_blank : out std_logic);
    end component;

    signal vga_hsync     : std_logic;
    signal vga_vsync     : std_logic;
    signal vga_red       : std_logic_vector(7 downto 0);
    signal vga_green     : std_logic_vector(7 downto 0);
    signal vga_blue      : std_logic_vector(7 downto 0);
    signal vga_blank     : std_logic;
    signal reset         : std_logic;
    component vga_to_hdmi is
        port ( pixel_clk    : in std_logic;
               pixel_clk_x5 : in std_logic;
               reset  : in std_logic;

               vga_hsync : in std_logic;
               vga_vsync : in std_logic;
               vga_red   : in std_logic_vector(7 downto 0);
               vga_green : in std_logic_vector(7 downto 0);
               vga_blue  : in std_logic_vector(7 downto 0);
               vga_blank : in std_logic;
               
               hdmi_tx_rscl  : out   std_logic;
               hdmi_tx_rsda  : inout std_logic;
               hdmi_tx_hpd   : in    std_logic;
               hdmi_tx_cec   : inout std_logic;
               hdmi_tx_clk_p : out   std_logic;
               hdmi_tx_clk_n : out   std_logic;
               hdmi_tx_p     : out   std_logic_vector(2 downto 0);
               hdmi_tx_n     : out   std_logic_vector(2 downto 0)
               );
    end component;

    signal locked        : std_logic;
    signal clkfb         : std_logic;
    ------------------------
    -- For Genesys2
    ------------------------
    signal clk100        : std_logic;
begin
    reset <= not locked;
    ------------------------------
    -- For the Genesys2
    ------------------------------
clk100_buff: ibufds port map
    (
        i => clk100_p,
        ib => clk100_n,
        o => clk100
    );
MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      DIVCLK_DIVIDE   => 8,        -- Master division value (1-106)
      CLKFBOUT_MULT_F => 44.5,    -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
      CLKIN1_PERIOD => 10.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE_F => 5.0,   -- Divide amount for CLKOUT0 (1.000-128.000).
      CLKOUT1_DIVIDE   => 15,
      CLKOUT2_DIVIDE   => 3,
      CLKOUT3_DIVIDE   => 1,
      CLKOUT4_DIVIDE   => 1,
      CLKOUT5_DIVIDE   => 1,
      CLKOUT6_DIVIDE   => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0   => clk_calc,     -- 1-bit output: CLKOUT0
      CLKOUT0B  => open,         -- 1-bit output: Inverted CLKOUT0
      CLKOUT1   => clk_pixel_x1, -- 1-bit output: CLKOUT1
      CLKOUT1B  => open,         -- 1-bit output: Inverted CLKOUT1
      CLKOUT2   => clk_pixel_x5, -- 1-bit output: CLKOUT2
      CLKOUT2B  => open,         -- 1-bit output: Inverted CLKOUT2
      CLKOUT3   => open,         -- 1-bit output: CLKOUT3
      CLKOUT3B  => open,         -- 1-bit output: Inverted CLKOUT3
      CLKOUT4   => open,         -- 1-bit output: CLKOUT4
      CLKOUT5   => open,         -- 1-bit output: CLKOUT5
      CLKOUT6   => open,         -- 1-bit output: CLKOUT6
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT  => clkfb,  -- 1-bit output: Feedback clock
      CLKFBOUTB => open,   -- 1-bit output: Inverted CLKFBOUT
      -- Status Ports: 1-bit (each) output: MMCM status ports
      LOCKED    => locked,   -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock input
      CLKIN1    => clk100, -- 1-bit input: Clock
      -- Control Ports: 1-bit (each) input: MMCM control ports
      PWRDWN    => '0',    -- 1-bit input: Power-down
      RST       => '0',    -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN   => clkfb   -- 1-bit input: Feedback clock
   );

i_ui: user_interface  port map (
           clk   => clk_pixel_x1,
           btnU  => btnU,
           btnD  => btnD,
           btnL  => btnL,
           btnR  => btnR,
           btnC  => btnC,
           vsync => vsync,
           x     => x,
           y     => y,
           scale => scale
          );

i_vga_gen_1080i: vga_gen_1080i port map (
        clk        => clk_pixel_x1,
        blank      => blank, 
        hsync      => hsync,
        vsync      => vsync,
        field      => field,
        interlaced => interlaced
    );

i_generate_constants: generate_constants port map (
        clk       => clk_pixel_x1,

        blank_in   => blank,
        hsync_in   => hsync,
        vsync_in   => vsync,
        field      => field,
        interlaced => interlaced,
        
        x         => x,
        y         => y,
        x_step    => scale, 
        y_step    => scale,
        
        blank_out => sync(0)(0),
        hsync_out => sync(0)(1),
        vsync_out => sync(0)(2),
        
        ca        => ca(0),
        cb        => cb(0)
    );
    a(0)          <= (others =>'0'); 
    b(0)          <= (others =>'0'); 
    -- set starting colour
    overflow(0)   <= '0';  

g1: for i in 1 to stages generate
i_stage_1: stage generic map (
            phase_len => clocks_per_pixel
        ) port map (
            clk        => clk_calc,
            -- Inputs
            ca_in        => ca(i-1),
            cb_in        => cb(i-1),
            a_in         => a(i-1), 
            b_in         => b(i-1), 
            i_in         => iterations(i-1), 
            overflow_in  => overflow(i-1),
            sync_in      => sync(i-1),
    
            ca_out       => ca(i),
            cb_out       => cb(i),
            a_out        => a(i),
            b_out        => b(i),
            i_out        => iterations(i),
            overflow_out => overflow(i),
            sync_out     => sync(i)
        );
end generate;
    
i_vga_output: vga_output Port map ( 
            clk => clk_pixel_x1,
            hsync_in => sync(stages)(1),
            vsync_in => sync(stages)(2),
            blank_in => sync(stages)(0),
            iterations_in => iterations(stages),
            vga_hsync => vga_hsync, 
            vga_vsync => vga_vsync,
            vga_red   => vga_red,
            vga_green => vga_green,
            vga_blue  => vga_blue,
            vga_blank => vga_blank
        );
        
 i_vga_to_hdmi: vga_to_hdmi port map ( 
                pixel_clk => clk_pixel_x1,
                pixel_clk_x5 => clk_pixel_x5,
                reset        => reset,
                vga_hsync => vga_hsync, 
                vga_vsync => vga_vsync,
                vga_red   => vga_red,
                vga_green => vga_green,
                vga_blue  => vga_blue,
                vga_blank => vga_blank,
                  
                hdmi_tx_rscl  => hdmi_tx_rscl, 
                hdmi_tx_rsda  => hdmi_tx_rsda,
                hdmi_tx_hpd   => hdmi_tx_hpd,
                hdmi_tx_cec   => hdmi_tx_cec,
                hdmi_tx_clk_p => hdmi_tx_clk_p,
                hdmi_tx_clk_n => hdmi_tx_clk_n,
                hdmi_tx_p     => hdmi_tx_p,
                hdmi_tx_n     => hdmi_tx_n
       );

end Behavioral;