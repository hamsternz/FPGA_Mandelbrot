-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : vga_gen.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- Generate the VGA 640x480 timing signals, where the pixel clock is 
-- clk/pixel_len. 
-- 
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_gen_720p is
    Port ( clk        : in STD_LOGIC;
    
           blank      : out STD_LOGIC := '0';
           hsync      : out STD_LOGIC := '0';
           vsync      : out STD_LOGIC := '0';
           field      : out STD_LOGIC := '0';
           interlaced : out STD_LOGIC := '0');
end vga_gen_720p;

architecture Behavioral of vga_gen_720p is
    signal x : unsigned(10 downto 0) := (others => '0');
    signal y : unsigned(10 downto 0) := (others => '0');
begin

clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if x = 1279 then
                blank <= '1';
            elsif x = 1648-1 and (y = 749 or y < 719) then
                blank <= '0';            
            end if;
            
            if x = 1280+72-1 then
                hsync <= '1';
            elsif x = 1280+72+80-1 then
                hsync <= '0';
            end if;

            if x = 1648-1 then
                x <= (others => '0');
                
                if y = 720+3-1 then
                    vsync  <= '1';
                elsif y = 720+3+5-1 then
                    vsync  <= '0';
                end if;
                
                if y = 750-1 then
                    y <= (others => '0');
                else
                    y <= y +1;
                end if;
            else
                x <= x + 1;        
            end if;            
        end if;            
    end process;
end Behavioral;