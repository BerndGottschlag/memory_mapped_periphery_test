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

entity button_input is
	generic (
		g_WB_DATA_BUS_WIDTH : integer := 8;
		g_WB_ADDRESS_BUS_WIDTH : integer := 10
		);
	port (
		-- shared signals
		i_wb_rst : in std_logic;
		i_wb_clk : in std_logic;

		-- wishbone interface (slave)
		i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		i_wb_adr : in std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		o_wb_ack : out std_logic;
		i_wb_cyc : in std_logic;
		i_wb_stb : in std_logic;
		o_wb_err : out std_logic;
		i_wb_we : in std_logic;

		-- button inputs
		i_button_0 : in std_logic;
		i_button_1 : in std_logic;
		i_button_2 : in std_logic;
		i_button_3 : in std_logic
	);
end;

architecture rtl of button_input is
	constant c_REGISTER_SIZE_IN_BITS : integer := 8;

	-- TODO: register write masks to avoid setting unused masks during a write access -> writing button states shall not be allowed

	constant r_button_state_register_0_address : integer := 0;
	constant r_button_state_register_1_address : integer := 1;
	constant r_button_state_register_2_address : integer := 2;
	constant r_button_state_register_3_address : integer := 3;
	type t_Registers is array (0 to r_button_state_register_3_address) of std_logic_vector(c_REGISTER_SIZE_IN_BITS - 1 downto 0);

	signal r_registers : t_Registers := (others => std_logic_vector(to_unsigned(0, c_REGISTER_SIZE_IN_BITS)));

	signal r_termination_signaled : std_logic := '0';

	procedure p_RESET_WB_INTERFACE (
		signal o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		signal o_wb_ack : out std_logic;
		signal o_wb_err : out std_logic
	) is
	begin
		o_wb_dat <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));
		o_wb_ack <= '0';
		o_wb_err <= '0';
	end p_RESET_WB_INTERFACE;

begin
	p_CONTROL : process (i_wb_clk) is
	begin
		if rising_edge(i_wb_clk) then
			if i_wb_rst = '1' then
				p_RESET_WB_INTERFACE(o_wb_dat, o_wb_ack, o_wb_err);

				-- reset registers
				r_registers <= (others => std_logic_vector(to_unsigned(0, c_REGISTER_SIZE_IN_BITS)));
			else
				if (i_wb_cyc = '1') AND (i_wb_stb = '1') AND (r_termination_signaled = '0') then
					if to_integer(signed(i_wb_adr)) < r_registers'length then
						if i_wb_we = '1' then
							r_registers(to_integer(signed(i_wb_adr))) <= i_wb_dat;
							o_wb_ack <= '1';
						else
							o_wb_dat <= r_registers(to_integer(signed(i_wb_adr)));
							o_wb_ack <= '1';
						end if;
					else
						o_wb_err <= '1';
					end if;
					r_termination_signaled <= '1';
				else
					p_RESET_WB_INTERFACE(o_wb_dat, o_wb_ack, o_wb_err);
					r_termination_signaled <= '0';
				end if;

				-- read button inputs and write them to the state registers
				-- TODO set this outside of the clock?
				r_registers(r_button_state_register_0_address)(0) <= i_button_0;
				r_registers(r_button_state_register_1_address)(0) <= i_button_1;
				r_registers(r_button_state_register_2_address)(0) <= i_button_2;
				r_registers(r_button_state_register_3_address)(0) <= i_button_3;
			end if;
		end if;
	end process p_CONTROL;
end rtl;
-- TODO: prevent writing to the register values
