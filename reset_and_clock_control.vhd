-- Copyright Bernd Gottschlag 2024.
--
-- This source describes Open Hardware and is licensed under the CERN-OHL-W v2
--
-- You may redistribute and modify this documentation and make products using it
-- under the terms of the CERN-OHL-W v2 (https:/cern.ch/cern-ohl). This
-- documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
-- INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A 
-- PARTICULAR PURPOSE. Please see the CERN-OHL-W v2 for applicable conditions.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: global reset

entity reset_and_clock_control is
	port (
		-- inputs from external pins
		i_osci_clk : in std_logic; -- This clock is used for the process of this module as it is active when the PLL is not yet locked.
		i_reset : in std_logic; -- low active

		-- interface to the PLL
		i_pll_lock: in std_logic; -- high active

		-- outputs
		o_reset: out std_logic; -- high active
		o_osci_enable: out std_logic
	);
end reset_and_clock_control;

architecture rtl of reset_and_clock_control is
	signal r_test: std_logic := '0';
begin
	-- always enable the external osci
	o_osci_enable <= '1';


	p_CONTROL : process (i_reset, i_pll_lock) is
	begin
		if i_reset = '0' or i_pll_lock = '0' then
			o_reset <= '1';
		else
			o_reset <= '0';
		end if;
	end process p_CONTROL;
end rtl;
