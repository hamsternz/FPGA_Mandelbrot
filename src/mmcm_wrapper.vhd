-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : mmcm_wrapper
--
-- A wrappper around the MMCM primative
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 21th Oct 2015
--
--
--
  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity mmcm_wrapper is
    generic ( div_to_25MHz  : integer );
    Port ( 
        clk_in        : in  std_logic;
        locked        : out std_logic;
        clk_calc      : out std_logic;
        clk_pixel_x1  : out std_logic;
        clk_pixel_x5  : out std_logic);
end mmcm_wrapper;

architecture Behavioral of mmcm_wrapper is
    signal clkfb           : std_logic;
    signal clk_calc_u      : std_logic;
    signal clk_pixel_x1_u  : std_logic;
    signal clk_pixel_x5_u  : std_logic;
begin

MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      DIVCLK_DIVIDE   => div_to_25MHz,        -- Master division value (1-106)
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
      CLKOUT0   => clk_calc_u,   -- 1-bit output: CLKOUT0
      CLKOUT0B  => open,         -- 1-bit output: Inverted CLKOUT0
      CLKOUT1   => clk_pixel_x1_u, -- 1-bit output: CLKOUT1
      CLKOUT1B  => open,         -- 1-bit output: Inverted CLKOUT1
      CLKOUT2   => clk_pixel_x5_u, -- 1-bit output: CLKOUT2
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
      CLKIN1    => clk_in, -- 1-bit input: Clock
      -- Control Ports: 1-bit (each) input: MMCM control ports
      PWRDWN    => '0',    -- 1-bit input: Power-down
      RST       => '0',    -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN   => clkfb   -- 1-bit input: Feedback clock
   );

clk_calc_bufg : bufg PORT MAP (
    i => clk_calc_u,
    o => clk_calc);

clk_pixel_x1_bufg : bufg PORT MAP (
    i => clk_pixel_x1_u,
    o => clk_pixel_x1);

clk_pixel_x5_bufg : bufg PORT MAP (
        i => clk_pixel_x5_u,
        o => clk_pixel_x5);
    
end Behavioral;
