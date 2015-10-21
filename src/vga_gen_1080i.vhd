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

entity vga_gen_1080i is
    Port ( clk        : in STD_LOGIC;
           blank      : out STD_LOGIC := '0';
           hsync      : out STD_LOGIC := '0';
           vsync      : out STD_LOGIC := '0';
           field      : out STD_LOGIC := '0';
           interlaced : out STD_LOGIC := '0');
end vga_gen_1080i;

architecture Behavioral of vga_gen_1080i is
    signal x : unsigned(11 downto 0) := (others => '0');
    signal y : unsigned(10 downto 0) := (others => '0');


    constant hSyncLen      : unsigned(11 downto 0) := to_unsigned(44,12);
    constant hBack      : unsigned(11 downto 0) := to_unsigned(149,12);
    constant hVisible   : unsigned(11 downto 0) := to_unsigned(1920,12);
    constant hFront     : unsigned(11 downto 0) := to_unsigned(88,12);
    constant hTotal     : unsigned(11 downto 0) := to_unsigned(2200,12);

    constant vFrame0    : unsigned(11 downto 0) := to_unsigned(540,12);
    constant vBlank0    : unsigned(11 downto 0) := to_unsigned(23,12);
    constant vFront0    : unsigned(11 downto 0) := to_unsigned(2,12);
    constant vSync0     : unsigned(11 downto 0) := to_unsigned(2,12);

    constant vFrame1    : unsigned(11 downto 0) := to_unsigned(540,12);
    constant vBlank1    : unsigned(11 downto 0) := to_unsigned(22,12);
    constant vFront1    : unsigned(11 downto 0) := to_unsigned(2,12);
    constant vSync1     : unsigned(11 downto 0) := to_unsigned(2,12);

    constant vTotal     : unsigned(11 downto 0) := to_unsigned(1125,12);

begin
    interlaced <= '1';
    
clk_proc: process(clk)
    begin
        if rising_edge(clk) then
            if x = hSyncLen+hBack+hVisible-1 then
                blank <= '1';
            elsif x = hSyncLen+hBack-1 then
                -------------------------------------------
                -- Unblank for the lines of the first field
                -------------------------------------------
                if y >= 0 and y < vFrame0 then 
                    blank <= '0';
                end if;            

                --------------------------------------------
                -- Unblank for the lines of the second field
                --------------------------------------------
                if y >= vFrame0 + vBlank0 and y < vFrame0 + vBlank0 + vFrame1 then 
                    blank <= '0';
                end if;            
            end if;
            
            ---------------------------------------
            -- Horizontal sync pulse
            ---------------------------------------
            if x = hTotal-1 then
                hsync <= '1';
            elsif x = hSyncLen - 1 then
                hsync <= '0';
            end if;

            -------------------------------------------------
            -- Frame0's Vsync starts midway through scan line
            -------------------------------------------------
            if x = hTotal/2-1 then
                if y = vFrame0 + vFront0 then
                    vsync  <= '1';
                elsif y = vFrame0 + vFront0 + vSync0  then
                    vsync  <= '0';
                end if;
            end if;            

            ----------------------------------------------------
            -- Frame1 Vsync starts with aligned with hsync pulse
            ----------------------------------------------------
            if x = hTotal-1 then
                if y = vFrame0 + vBlank0 + vFrame1 + vFront1-1 then
                    vsync  <= '1';
                elsif y = vFrame0 + vBlank0 + vFrame1 + vFront1 + vSync1-1  then
                    vsync  <= '0';
                end if;
            end if;            

            ---------------------------------------
            -- Set the interlacing field indicator 
            ---------------------------------------
            if x = hTotal-1 then
                if y = vFrame0 + vBlank0 - 1 then
                    field <= '1';
                end if;
                if y = vFrame0 + vBlank0 + vFrame1 + vBlank1 - 1 then
                    field <= '1';
                end if;
            end if;            

            ------------------------------------
            -- Advancing the counters
            ------------------------------------
            if x = hTotal-1 then
                x <= (others => '0');
                if y = vTotal-1 then
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