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


entity button_input_tb is
end button_input_tb;

architecture behave of button_input_tb is
	-- system clock
	constant c_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;

	-- wishbone interfaces of the UUT
	constant c_WB_DATA_BUS_WIDTH : integer := 8;
	constant c_WB_ADDRESS_BUS_WIDTH : integer := 10;

	signal DAT_I : std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0);
	signal DAT_O : std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0);
	signal ADR_I : std_logic_vector (c_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
	signal ACK_O : std_logic := '0';
	signal CYC_I : std_logic := '0';
	signal STB_I : std_logic := '0';
	signal ERR_O : std_logic := '0';
	signal WE_I : std_logic := '0';

	-- other input signals to the UUT
	signal clock: std_logic := '0';
	signal reset: std_logic := '0'; -- high active

	-- button inputs
	signal button_0 : std_logic := '0';
	signal button_1 : std_logic := '0';
	signal button_2 : std_logic := '0';
	signal button_3 : std_logic := '0';

	-- internal signals of the test bench
	signal data : std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0);
	signal address : std_logic_vector (c_WB_ADDRESS_BUS_WIDTH - 1 downto 0);

	-- Component declaration for the UUT
	component button_input is
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
	end component button_input;

begin
	-- Instantiate the UUT
	UUT: button_input
		port map (
			i_wb_clk => clock,
			i_wb_rst => reset,

			-- wishbone interface
			i_wb_dat => DAT_I,
			o_wb_dat => DAT_O,
			i_wb_adr => ADR_I,
			o_wb_ack => ACK_O,
			i_wb_cyc => CYC_I,
			i_wb_stb => STB_I,
			o_wb_err => ERR_O,
			i_wb_we => WE_I,

			-- LED outputs
			i_button_0 => button_0,
			i_button_1 => button_1,
			i_button_2 => button_2,
			i_button_3 => button_3
			);

	p_Clock_Generator : process is
	begin
		wait for c_CLOCK_PERIOD/2;
		clock <= not clock;
	end process p_Clock_Generator;

process
	-- shared procedures
	procedure Reset_Testbench is
	begin
		-- reset the UUT
		reset <= '1';
	-- TODO: assert that the interface is fully reset

		testPhaseCounter <= 0;

		-- reset testbench
		DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WIDTH));
		ADR_I <= std_logic_vector(to_unsigned(0, c_WB_ADDRESS_BUS_WIDTH));
		CYC_I <= '0';
		STB_I <= '0';
		WE_I <= '0';

		address <= std_logic_vector(to_unsigned(0, c_WB_ADDRESS_BUS_WIDTH));
		data <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WIDTH));

		-- reset button states
		button_0 <= '0';
		button_1 <= '0';
		button_2 <= '0';
		button_3 <= '0';

		wait for c_CLOCK_PERIOD;
		reset <= '0';

		assert
			ACK_O = '0' and
			ERR_O = '0'
		report "UUT not reset!" severity warning;
	end procedure;

	procedure Write_Value (signal i_address : in std_logic_vector (c_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
	                       signal i_data : in std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0)
	                       ) is
	begin
		ADR_I <= i_address;
		DAT_I <= i_data;
		CYC_I <= '1';
		STB_I <= '1';
		WE_I <= '1';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;

		assert ACK_O = '1' report "ACK_0 not correct!" severity warning;
		assert ERR_O = '0' report "ERR_0 not correct!" severity warning;

		wait until rising_edge(clock);

		CYC_I <= '0';
		STB_I <= '0';
		WE_I <= '0';
	end procedure;

	procedure Read_Value (signal i_address : in std_logic_vector (c_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
	                      signal o_data : out std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0)
	                      ) is
	begin
		ADR_I <= i_address;
		CYC_I <= '1';
		STB_I <= '1';
		WE_I <= '0';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		o_data <= DAT_O;

		assert ACK_O = '1' report "ACK_0 not correct!" severity warning;
		assert ERR_O = '0' report "ERR_0 not correct!" severity warning;

		wait until rising_edge(clock);

		CYC_I <= '0';
		STB_I <= '0';
	end procedure;

	-- test cases
	procedure Read_State_Button_0_Active is
	begin
		report "Read_State_Button_0_Active" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		button_0 <= '1';

		-- Read register Value
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WIDTH));
		wait until rising_edge(clock);
		Read_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert data = std_logic_vector(to_unsigned(16#1#, c_WB_DATA_BUS_WIDTH)) report "Register value not correct!" severity warning;
	end procedure;

	procedure Read_State_Button_0_Inactive is
	begin
		report "Read_State_Button_0_Inactive" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		button_0 <= '0';
		button_1 <= '0';
		button_2 <= '0';
		button_3 <= '0';

		-- Read register Value
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WIDTH));
		wait until rising_edge(clock);
		Read_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert data = std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WIDTH)) report "Register value not correct!" severity warning;
	end procedure;

	procedure Read_Invalid_Address is
	begin
		report "Read_Invalid_Address" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		ADR_I <= std_logic_vector(to_unsigned(4, c_WB_ADDRESS_BUS_WIDTH));
		CYC_I <= '1';
		STB_I <= '1';
		WE_I <= '1';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;

		assert ACK_O = '0' report "ACK_0 not correct!" severity warning;
		assert ERR_O = '1' report "ERR_0 not correct!" severity warning;

		wait until rising_edge(clock);

		CYC_I <= '0';
		STB_I <= '0';
		WE_I <= '0';
	end procedure;
begin
	testCaseId <= 1;
	Read_State_Button_0_Active;
	-- TODO: other buttons
	wait for c_CLOCK_PERIOD * 5;

	testCaseId <= 2;
	Read_State_Button_0_Inactive;
	-- TODO: other buttons
	wait for c_CLOCK_PERIOD * 5;

	testCaseId <= 3;
	Read_Invalid_Address;
	wait for c_CLOCK_PERIOD * 5;

	-- testing finished
	wait;
end process;

end behave;
