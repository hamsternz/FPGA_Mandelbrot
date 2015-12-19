----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.12.2015 21:54:54
-- Design Name: 
-- Module Name: fan_pwm - Behavioral
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

entity fan_pwm_control is
    Port ( clk100 : in STD_LOGIC;
           temp_k : in STD_LOGIC_VECTOR (8 downto 0);
           fan_pwm : out STD_LOGIC);
end fan_pwm_control;

architecture Behavioral of fan_pwm_control is
    signal cycle_counter : unsigned(19 downto 0) := (others => '0');
    signal ms_counter    : unsigned(4 downto 0)  := (others => '0');
    signal new_ms        : std_logic             := '0';
    signal pwm_level     : unsigned(4 downto 0)  := (others => '0');
begin

process(clk100)
    begin
        if rising_edge(clk100) then
            if ms_counter < pwm_level then
                fan_pwm <= '1';
            else
                fan_pwm <= '0';
            end if;
            
            
            if new_ms = '1' then
               if ms_counter = 15 then
                    ms_counter <= (others => '0');

                    if unsigned(temp_k) < 30+273 then
                        pwm_level <= to_unsigned(2,5);
                    elsif unsigned(temp_k) < 35+273 then
                        pwm_level <= to_unsigned(4,5);
                    elsif unsigned(temp_k) < 40+273 then
                        pwm_level <= to_unsigned(6,5);                
                    elsif unsigned(temp_k) < 45+273 then
                        pwm_level <= to_unsigned(7,5);                
                    elsif unsigned(temp_k) < 50+273 then
                        pwm_level <= to_unsigned(8,5);                
                    elsif unsigned(temp_k) < 55+273 then
                        pwm_level <= to_unsigned(10,5);                
                    elsif unsigned(temp_k) < 60+273 then
                        pwm_level <= to_unsigned(12,5);                
                    elsif unsigned(temp_k) < 65+273 then
                        pwm_level <= to_unsigned(14,5);                
                    else
                        pwm_level <= to_unsigned(16,5);                
                    end if;

               else
                  ms_counter <= ms_counter + 1; 
               end if;
            end if;
            if cycle_counter = 999999 then
                new_ms  <= '1';
                cycle_counter <= (others => '0');
            else
                new_ms  <= '0';
                cycle_counter <= cycle_counter + 1;
            end if;
        end if;
    end process;

end Behavioral;