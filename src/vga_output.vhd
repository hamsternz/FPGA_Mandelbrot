-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : stage.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- Convert the iteration count into a colour
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity vga_output is
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
end vga_output;

architecture Behavioral of vga_output is
    signal max : unsigned(iterations_in'range) := (others => '0');
    signal colour : std_logic_vector(11 downto 0) := (others => '0');
    type a_palette is array(0 to 255) of std_logic_vector(11 downto 0);
    signal palette : a_palette := (
        x"000",x"001",x"002",x"003",  x"004",x"005",x"006",x"007",
        x"008",x"009",x"00A",x"00B",  x"00C",x"00D",x"00E",x"00F",
        x"01F",x"02F",x"03F",x"04F",  x"05F",x"06F",x"07F",x"08F",
        x"09F",x"0AF",x"0BF",x"0CF",  x"0DF",x"0EF",x"0FF",x"0FE",
--32
        x"0FD",x"0FC",x"0FB",x"0FA",  x"0F9",x"0F8",x"0F7",x"0F6",
        x"0F5",x"0F4",x"0F3",x"0F2",  x"0F1",x"0F0",x"1F0",x"2F0",
        x"3F0",x"4F0",x"5F0",x"6F0",  x"7F0",x"9F0",x"9F0",x"AF0",
        x"BF0",x"CF0",x"DF0",x"EF0",  x"EF0",x"FF0",x"EE1",x"DD2",
--64
        x"CC3",x"BB4",x"AA5",x"996",  x"887",x"778",x"669",x"55A",
        x"44B",x"33C",x"22D",x"11E",  x"00F",x"10F",x"20F",x"30F",
        x"40F",x"50F",x"60F",x"70F",  x"80F",x"90F",x"A0F",x"B0F",
        x"C0F",x"D0F",x"E0F",x"F0F",  x"f1f",x"F2F",x"F3F",x"F4F",
--96
        x"F5F",x"F6F",x"F7F",x"F8F",  x"F9F",x"FAF",x"FBF",x"FCF",
        x"FDF",x"FEF",x"FFF",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
-- 128                                 
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
-- 160
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
-- 192
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
-- 224
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000",
        x"000",x"000",x"000",x"000",  x"000",x"000",x"000",x"000");

begin
vga_buffer: process(clk)
    begin
        if rising_edge(clk) then
            vga_hsync <= hsync_in;
            vga_vsync <= vsync_in;
            if blank_in = '0' then
                if iterations_in = std_logic_vector(max) then
                    -- set the maximum value to black
                    vga_red    <= (others => '0');
                    vga_green  <= (others => '0');
                    vga_blue   <= (others => '0');   
                else
                    vga_green <= iterations_in( 5 downto 4) & iterations_in( 5 downto 4) & iterations_in( 5 downto 4) & iterations_in( 5 downto 4);
                    vga_red   <= iterations_in( 3 downto 2) & iterations_in( 3 downto 2) & iterations_in( 3 downto 2) & iterations_in( 3 downto 2);
                    vga_blue  <= iterations_in( 1 downto 0) & iterations_in( 1 downto 0) & iterations_in( 1 downto 0) & iterations_in( 1 downto 0);
                end if;

                if max < unsigned(iterations_in) then
                    max <= unsigned(iterations_in);
                end if;

                vga_blank <= '0';
            else
                vga_red    <= (others => '0');
                vga_green  <= (others => '0');
                vga_blue   <= (others => '0');   
                vga_blank <= '1';
            end if;
        end if;
    end process;

end Behavioral;
