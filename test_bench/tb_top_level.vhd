----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.05.2015 22:31:40
-- Design Name: 
-- Module Name: tb_top_level - Behavioral
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

entity tb_top_level is
end tb_top_level;

architecture Behavioral of tb_top_level is
    component top_level is
    Port ( 
        clk100    : in STD_LOGIC;
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
    end component;

    signal clk100        : STD_LOGIC := '0';
    signal hdmi_tx_rscl  : std_logic;
    signal hdmi_tx_rsda  : std_logic;
    signal hdmi_tx_hpd   : std_logic;
    signal hdmi_tx_cec   : std_logic;
    
    signal hdmi_tx_clk_p : std_logic;
    signal hdmi_tx_clk_n : std_logic;
    signal hdmi_tx_p     : std_logic_vector(2 downto 0);
    signal hdmi_tx_n     : std_logic_vector(2 downto 0);
begin

uut: top_level port map(
        clk100    => clk100,
        btnU      => '0',
        btnD      => '0',
        btnL      => '0',
        btnR      => '0',
        btnC      => '0',

        hdmi_tx_rscl  => hdmi_tx_rscl, 
        hdmi_tx_rsda  => hdmi_tx_rsda,
        hdmi_tx_hpd   => hdmi_tx_hpd,
        hdmi_tx_cec   => hdmi_tx_cec,
        hdmi_tx_clk_p => hdmi_tx_clk_p,
        hdmi_tx_clk_n => hdmi_tx_clk_n,
        hdmi_tx_p     => hdmi_tx_p,
        hdmi_tx_n     => hdmi_tx_n
    );

clk_proc: process
    begin
        wait for 5 ns;
        clk100 <= '1';
        wait for 5 ns;
        clk100 <= '0';       
    end process;
end Behavioral;
