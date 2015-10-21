----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.06.2015 09:27:35
-- Design Name: 
-- Module Name: tb_vga_gen_1080i - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_vga_gen_1080i is
end tb_vga_gen_1080i;

architecture Behavioral of tb_vga_gen_1080i is
    component vga_gen_1080i is
    Port ( clk        : in STD_LOGIC;
           blank      : out STD_LOGIC := '0';
           hsync      : out STD_LOGIC := '0';
           vsync      : out STD_LOGIC := '0';
           field      : out STD_LOGIC := '0';
           interlaced : out STD_LOGIC := '0');
    end component;

    signal clk        : std_logic := '0';
    signal blank      : STD_LOGIC := '0';
    signal hsync      : STD_LOGIC := '0';
    signal vsync      : STD_LOGIC := '0';
    signal field      : STD_LOGIC := '0';
    signal interlaced : STD_LOGIC := '0';
begin
uut: vga_gen_1080i port map (
    clk        => clk,
    blank      => blank,
    hsync      => hsync,
    vsync      => vsync,
    field      => field,
    interlaced => interlaced);

proc_clk: process
    begin
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
    end process;

end Behavioral;
