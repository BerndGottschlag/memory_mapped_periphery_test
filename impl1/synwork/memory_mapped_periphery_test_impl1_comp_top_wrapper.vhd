--
-- Synopsys
-- Vhdl wrapper for top level design, written on Mon Nov 25 21:42:01 2024
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wrapper_for_spi_interface is
   port (
      i_cs : in std_logic;
      i_sclk : in std_logic;
      i_mosi : in std_logic;
      o_miso : out std_logic;
      o_debug_output : out std_logic;
      i_wb_rst : in std_logic;
      i_wb_clk : in std_logic;
      o_wb_dat : out std_logic_vector(7 downto 0);
      i_wb_dat : in std_logic_vector(7 downto 0);
      o_wb_adr : out std_logic_vector(15 downto 0);
      i_wb_ack : in std_logic;
      o_wb_cyc : out std_logic;
      o_wb_stb : out std_logic;
      i_wb_err : in std_logic;
      o_wb_we : out std_logic
   );
end wrapper_for_spi_interface;

architecture rtl of wrapper_for_spi_interface is

component spi_interface
 port (
   i_cs : in std_logic;
   i_sclk : in std_logic;
   i_mosi : in std_logic;
   o_miso : out std_logic;
   o_debug_output : out std_logic;
   i_wb_rst : in std_logic;
   i_wb_clk : in std_logic;
   o_wb_dat : out std_logic_vector (7 downto 0);
   i_wb_dat : in std_logic_vector (7 downto 0);
   o_wb_adr : out std_logic_vector (15 downto 0);
   i_wb_ack : in std_logic;
   o_wb_cyc : out std_logic;
   o_wb_stb : out std_logic;
   i_wb_err : in std_logic;
   o_wb_we : out std_logic
 );
end component;

signal tmp_i_cs : std_logic;
signal tmp_i_sclk : std_logic;
signal tmp_i_mosi : std_logic;
signal tmp_o_miso : std_logic;
signal tmp_o_debug_output : std_logic;
signal tmp_i_wb_rst : std_logic;
signal tmp_i_wb_clk : std_logic;
signal tmp_o_wb_dat : std_logic_vector (7 downto 0);
signal tmp_i_wb_dat : std_logic_vector (7 downto 0);
signal tmp_o_wb_adr : std_logic_vector (15 downto 0);
signal tmp_i_wb_ack : std_logic;
signal tmp_o_wb_cyc : std_logic;
signal tmp_o_wb_stb : std_logic;
signal tmp_i_wb_err : std_logic;
signal tmp_o_wb_we : std_logic;

begin

tmp_i_cs <= i_cs;

tmp_i_sclk <= i_sclk;

tmp_i_mosi <= i_mosi;

o_miso <= tmp_o_miso;

o_debug_output <= tmp_o_debug_output;

tmp_i_wb_rst <= i_wb_rst;

tmp_i_wb_clk <= i_wb_clk;

o_wb_dat <= tmp_o_wb_dat;

tmp_i_wb_dat <= i_wb_dat;

o_wb_adr <= tmp_o_wb_adr;

tmp_i_wb_ack <= i_wb_ack;

o_wb_cyc <= tmp_o_wb_cyc;

o_wb_stb <= tmp_o_wb_stb;

tmp_i_wb_err <= i_wb_err;

o_wb_we <= tmp_o_wb_we;



u1:   spi_interface port map (
		i_cs => tmp_i_cs,
		i_sclk => tmp_i_sclk,
		i_mosi => tmp_i_mosi,
		o_miso => tmp_o_miso,
		o_debug_output => tmp_o_debug_output,
		i_wb_rst => tmp_i_wb_rst,
		i_wb_clk => tmp_i_wb_clk,
		o_wb_dat => tmp_o_wb_dat,
		i_wb_dat => tmp_i_wb_dat,
		o_wb_adr => tmp_o_wb_adr,
		i_wb_ack => tmp_i_wb_ack,
		o_wb_cyc => tmp_o_wb_cyc,
		o_wb_stb => tmp_o_wb_stb,
		i_wb_err => tmp_i_wb_err,
		o_wb_we => tmp_o_wb_we
       );
end rtl;
