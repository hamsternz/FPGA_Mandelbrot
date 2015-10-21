-----------------------------------------------------------------------------
-- Project: mandelbrot_ng - my next-gen FPGA Mandelbrot Fractal Viewer
--
-- File : user_interface.vhd
--
-- Author : Mike Field <hamster@snap.net.nz>
--
-- Date    : 9th May 2015
--
-- This is the the user interface of my fractal viewer. All it does is
-- wait for the VGA vertical sync to be asserted, and then updates the 
-- top/left of the screen and the zoom/scale factor based on the 
-- four buttons
--
-- It had to be pipelined a little to meet timing, so is a little bit
-- ungainly
--
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity user_interface is
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
end user_interface;

architecture Behavioral of user_interface is
                                                --- these are in 4.32 fixed-point signed binary
    signal x_internal          : unsigned(34 downto 0)  := (others => '0');
    signal y_internal          : unsigned(34 downto 0)  := (others => '0');

    signal x_left              : unsigned(34 downto 0)         := (others => '0');
    signal x_right             : unsigned(34 downto 0)         := (others => '0');
    signal y_up                : unsigned(34 downto 0)         := (others => '0');
    signal y_down              : unsigned(34 downto 0)         := (others => '0');

    signal scale_left          : unsigned(34 downto 0)     := (others => '0');
    signal scale_right         : unsigned(34 downto 0)     := (others => '0');
    signal scale_right_sub     : unsigned(28 downto 0)     := (others => '0');
    
    signal scale_internal      : unsigned(34 downto 0)  := (23 => '1', others => '0');
    signal scale_internal_last : unsigned(34 downto 0) := (23 => '1', others => '0');
    signal  scale_left_range_limit  : std_logic := '0';

    signal x_buffer            : std_logic_vector(34 downto 0) := (others => '0');
    signal y_buffer            : std_logic_vector(34 downto 0) := (others => '0');
    signal scale_buffer        : std_logic_vector(34 downto 0) := (others => '0');

    signal vsync_last     : std_logic;
    signal update_now     : std_logic;

    signal btnU_sync      : STD_LOGIC := '0';
    signal btnD_sync      : STD_LOGIC := '0';
    signal btnL_sync      : STD_LOGIC := '0';
    signal btnR_sync      : STD_LOGIC := '0';
    signal btnC_sync      : STD_LOGIC := '0';

begin
    x     <= std_logic_vector(x_buffer);
    y     <= std_logic_vector(y_buffer);
    scale <= std_logic_vector(scale_buffer);
clk_proc: process(clk)
    begin
        if rising_edge(clk) then            
            -- 1024 is close enough to 1040
            x_buffer     <= std_logic_vector(x_internal
                        - (scale_internal(scale_internal'high-10 downto 0)&"0000000000"));
            -- 512 is close to the 540
            y_buffer     <= std_logic_vector(y_internal
                          - (scale_internal(scale_internal'high-9 downto 0)&"000000000"));
            scale_buffer <= std_logic_vector(scale_internal);


            if update_now = '1' then
                if btnC_sync = '0' then
                    if btnL_sync = '1' then
                        x_internal <= x_left;
                    end if;
                    if btnR_sync = '1' then
                        x_internal <= x_right;
                    end if;
                    if btnU_sync = '1' then
                        y_internal <= y_up;
                    end if;
                    if btnD_sync = '1' then
                        y_internal <= y_down;
                    end if;
                else
                    if btnL_sync = '1' then
                        scale_internal <= scale_left;
                    end if;
                    if btnR_sync = '1' then
                        scale_internal <= scale_right;
                    end if;
                end if;                
            end if;

            x_left  <= x_internal - (scale_internal(scale_internal'high-2 downto 0) & "00");
            x_right <= x_internal + (scale_internal(scale_internal'high-2 downto 0) & "00");
            y_up    <= y_internal - (scale_internal(scale_internal'high-2 downto 0) & "00");
            y_down  <= y_internal + (scale_internal(scale_internal'high-2 downto 0) & "00");

           scale_right <= scale_internal - scale_right_sub;
            
            if scale_internal(scale_internal'high downto 6) = 0 then
                if scale_internal(10 downto 0) /= 1 then
                   scale_right_sub <= (0=>'1', others => '0');
                else 
                    scale_right_sub <= (others => '0');
                end if;
            else
               scale_right_sub <= scale_internal(scale_internal'high downto 6); 
            end if;

            if  scale_left_range_limit = '1' then
               scale_left <= scale_internal + 1;
            else
               scale_left <= scale_internal + scale_internal(scale_internal'high downto 6);
            end if;
        
            if scale_internal(scale_internal'high downto 6) = 0 then
                scale_left_range_limit <= '1';
            else
                scale_left_range_limit <= '0';
            end if;
            
            if vsync_last = '0' and vsync = '1' then
                update_now <= '1';
            else
                update_now <= '0';
            end if;

            btnU_sync <= btnU;
            btnD_sync <= btnD;
            btnL_sync <= btnL;
            btnR_sync <= btnR;
            btnC_sync <= btnC;

            vsync_last <= vsync;
        end if;
    end process;

end Behavioral;