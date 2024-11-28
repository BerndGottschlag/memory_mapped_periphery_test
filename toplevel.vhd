library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: global reset

entity toplevel is 
	port (
		i_osci_clock : in std_logic -- Has to be 50 MHz
	);
end toplevel;

-- TODO: implement the SYSCON module
--     - p. 32 Wishbone B4 specification: Recommendation 3.00: RST_O should be asserted during a power-up condition
architecture rtl of toplevel is
	-- misc
	signal r_sys_clk: std_logic:= '0';
	signal r_pll_lock: std_logic:= '0';

	-- PLL
	component pll is
		port (
			CLK: in std_logic;
			CLKOP: out std_logic;
			LOCK: out std_logic
		);
	end component pll;

begin

	PLL_INSTANCE : pll
		port map (
			CLK => i_osci_clock,
			CLKOP => r_sys_clk,
			LOCK => r_pll_lock
		);
end rtl;
