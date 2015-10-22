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
    signal colour : std_logic_vector(23 downto 0) := (others => '0');
    type a_palette is array(0 to 255) of std_logic_vector(23 downto 0);

    signal palette : a_palette := (
    x"000002", x"000006", x"00000c", x"000010", x"000014", x"000017", x"01001f", x"01002e", 
    x"01003c", x"00004a", x"020057", x"01006b", x"03007c", x"030090", x"0300a3", x"0300b3",
    x"0200bf", x"0400ce", x"0400db", x"0400e5", x"0400ea", x"0400ee", x"0400f2", x"0400f6",
    x"0300fa", x"0500fd", x"0500fa", x"0500f6", x"0400f0", x"0600ed", x"0600e8", x"0600e2",
--32
    x"0500d5", x"0700c7", x"0700b8", x"0600a8", x"080095", x"070081", x"09006d", x"0a0058",
    x"09004a", x"0b003b", x"0c002b", x"0b001d", x"0d0015", x"0e0012", x"0d000c", x"0f0009",
    x"100005", x"0f0000", x"110002", x"120007", x"13040b", x"14050f", x"130913", x"150a16",
    x"160e1b", x"161026", x"151935", x"172142", x"18294e", x"19305c", x"183a6f", x"194681",
--64
    x"1c5193", x"1b5ca4", x"1d66b3", x"1d6cbe", x"2076cc", x"217cd9", x"2185e6", x"2489e9",
    x"258bed", x"268cf1", x"2690f5", x"2992f7", x"2a94fc", x"2b95fd", x"2c91f7", x"2d90f4",
    x"2e8cf0", x"2e8bea", x"3188e7", x"3285e2", x"337dd3", x"3474c5", x"356ab5", x"3563a8",
    x"385897", x"384d83", x"3b406d", x"3b355b", x"3e2e4c", x"40253f", x"421b2f", x"441322",
--96
    x"440d17", x"470c14", x"490810", x"49070a", x"4c0307", x"4c0102", x"4f0000", x"510505", 
    x"520909", x"520d0d", x"55100f", x"571613", x"591a18", x"5b2623", x"5b3430", x"5f443f",
    x"5f514d", x"62625a", x"64756b", x"668a80", x"689d93", x"68aea5", x"6cbcb1", x"6ecac1", 
    x"70d8cf", x"72e4dc", x"72e9e5", x"75ede9", x"77f0ec", x"79f6f2", x"7bfaf6", x"7cfdfa",
-- 128                                 
    x"80fbfd", x"80f7fb", x"83f3f7", x"85edf1", x"87eaee", x"89e6ea", x"8bdfe6", x"8dd0dd",
    x"8fc4d0", x"91b4c0", x"93a8b4", x"9396a5", x"968493", x"98707e", x"9a5e6d", x"9c4e59",
    x"9e424c", x"a0333c", x"a22630", x"a41a21", x"a41417", x"a71014", x"a90e10", x"a90a0c",
    x"ac0608", x"ae0102", x"b00000", x"b00602", x"b30a03", x"b50d07", x"b71308", x"b7160c",
-- 160
    x"ba1d0d", x"bb2a14", x"bb391d", x"be4725", x"c0542b", x"c26636", x"c27a3f", x"c58d4b",
    x"c5a056", x"c8ad5f", x"c9bd67", x"c9cb6f", x"ccd977", x"cde47e", x"cee981", x"cfed82",
    x"d0f186", x"d1f487", x"d2fa8b", x"d2fd8d", x"d5fb8c", x"d6f788", x"d7f187", x"d7ee85",
    x"daea83", x"dbe581", x"dcdc7c", x"ddce73", x"ddbe6d", x"e0b266", x"e1a25e", x"e28f55",
-- 192
    x"e37c49", x"e46740", x"e55534", x"e6462d", x"e53924", x"e72b1e", x"e61c15", x"e8160e",
    x"e9130b", x"ea0e0a", x"e90806", x"eb0605", x"ea0103", x"ec0000", x"ed0600", x"ee0800",
    x"ed0c00", x"ef1200", x"f01500", x"ef1a00", x"f12500", x"f23200", x"f14100", x"f34d00",
    x"f45c00", x"f36f00", x"f58000", x"f69400", x"f7a500", x"f6b300", x"f8c100", x"f8ce00",
-- 224
    x"f8db00", x"f8e500", x"f8e900", x"f7ed00", x"f9f100", x"f9f500", x"f8f800", x"faff00",
    x"fafb00", x"faf700", x"f9f300", x"fbef00", x"fbeb00", x"fbe600", x"fbdd00", x"fbd000",
    x"fbc200", x"fbb300", x"faa400", x"fc9100", x"fc7e00", x"fb6900", x"fd5600", x"fd4900",
    x"fd3b00", x"fc2b00", x"fe1e00", x"fe1700", x"fe1200", x"fe0f00", x"fe0b00", x"000000");

begin
    colour <= palette(to_integer(unsigned(iterations_in)));
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
                    vga_red   <= colour(23 downto 16);
                    vga_green <= colour(15 downto  8);
                    vga_blue  <= colour( 7 downto  0);
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
