-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : generate_constants.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- By following the sync signals, generate the 'a' and 'b' values that 
-- are sent through to the calculation pipeline.
--
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity generate_constants is
    port (
        clk       : in std_logic;

        blank_in  : in std_logic;
        hsync_in  : in std_logic;
        vsync_in  : in std_logic;
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
end generate_constants;

architecture Behavioral of generate_constants is
    signal current_x  : std_logic_vector(x'range) := (34 => '1', 33=> '1', 32=> '1', 31=> '1', others => '0');
    signal current_y  : std_logic_vector(y'range) := (34 => '1', 33=> '1', 32=> '1', 31=> '1', others => '0');
    signal blank_last : std_logic                 := '0';
begin
    ca <= current_x;
    cb <= current_y;
    
process(clk)
    begin
        if rising_edge(clk) then
            if blank_in = '1' then
                current_x <= x;
            else
                current_x <= std_logic_vector(unsigned(current_x) + unsigned(x_step));
            end if; 
    
            if vsync_in = '1' then
                if field = '0' then
                    current_y <= y;
                else
                    current_y <= std_logic_vector(unsigned(y) + unsigned(y_step));
                end if;
            elsif blank_last = '1' and blank_in = '0' then
                if interlaced = '1' then
                    current_y <= std_logic_vector(unsigned(current_y) + unsigned(y_step(y_step'high-1 downto 0) & '0'));
                else
                    current_y <= std_logic_vector(unsigned(current_y) + unsigned(y_step));
                end if;
            end if;
            
            blank_last <= blank_in;
            blank_out  <= blank_in;
            hsync_out  <= hsync_in;
            vsync_out  <= vsync_in;
        end if;
    end process;
end Behavioral;