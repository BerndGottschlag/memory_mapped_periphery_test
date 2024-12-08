library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity led_output_tb is
end led_output_tb;

architecture behave of led_output_tb is
	-- system clock
	constant c_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;

	-- wishbone interfaces of the UUT
	constant c_WB_DATA_BUS_WITDH : integer := 8;
	constant c_WB_ADDRESS_BUS_WITDH : integer := 10;

	signal DAT_I : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal DAT_O : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal ADR_I : std_logic_vector (c_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	signal ACK_O : std_logic := '0';
	signal CYC_I : std_logic := '0';
	signal STB_I : std_logic := '0';
	signal ERR_O : std_logic := '0';
	signal WE_I : std_logic := '0';

	-- other input signals to the UUT
	signal clock: std_logic := '0';
	signal reset: std_logic := '0'; -- high active

	-- led outputs
	signal led_0 : std_logic := '0';
	signal led_1 : std_logic := '0';
	signal led_2 : std_logic := '0';
	signal led_3 : std_logic := '0';
	signal led_4 : std_logic := '0';
	signal led_5 : std_logic := '0';
	signal led_6 : std_logic := '0';
	signal led_7 : std_logic := '0';

	-- internal signals of the test bench
	signal data : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal address : std_logic_vector (c_WB_ADDRESS_BUS_WITDH - 1 downto 0);

	-- Component declaration for the UUT
	component led_output is
		generic (
			g_WB_DATA_BUS_WITDH : integer := 8;
			g_WB_ADDRESS_BUS_WITDH : integer := 10
			);
		port (
			-- shared signals
			i_wb_rst : in std_logic;
			i_wb_clk : in std_logic;

			-- wishbone interface (slave)
			i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_wb_adr : in std_logic_vector (g_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			o_wb_ack : out std_logic;
			i_wb_cyc : in std_logic;
			i_wb_stb : in std_logic;
			o_wb_err : out std_logic;
			i_wb_we : in std_logic;

			-- LED outputs
			o_led_0 : out std_logic;
			o_led_1 : out std_logic;
			o_led_2 : out std_logic;
			o_led_3 : out std_logic;
			o_led_4 : out std_logic;
			o_led_5 : out std_logic;
			o_led_6 : out std_logic;
			o_led_7 : out std_logic
		);
	end component led_output;

begin
	-- Instantiate the UUT
	UUT: led_output
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
			o_led_0 => led_0,
			o_led_1 => led_1,
			o_led_2 => led_2,
			o_led_3 => led_3,
			o_led_4 => led_4,
			o_led_5 => led_5,
			o_led_6 => led_6,
			o_led_7 => led_7
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
		DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
		ADR_I <= std_logic_vector(to_unsigned(0, c_WB_ADDRESS_BUS_WITDH));
		CYC_I <= '0';
		STB_I <= '0';
		WE_I <= '0';

		address <= std_logic_vector(to_unsigned(0, c_WB_ADDRESS_BUS_WITDH));
		data <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));

		-- reset led states

		wait for c_CLOCK_PERIOD;
		reset <= '0';

		assert
			ACK_O = '0' and
			ERR_O = '0' and
			led_0 = '0' and
			led_1 = '0' and
			led_2 = '0' and
			led_3 = '0' and
			led_4 = '0' and
			led_5 = '0' and
			led_6 = '0' and
			led_7 = '0'
		report "UUT not reset!" severity warning;
	end procedure;

	procedure Write_Value (signal i_address : in std_logic_vector (c_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	                       signal i_data : in std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0)
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

	procedure Read_Value (signal i_address : in std_logic_vector (c_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	                      signal o_data : out std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0)
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
	procedure Set_And_Reset_LED_0 is
	begin
		report "Set_And_Reset_LED_0" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- Set LED 0 to on
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WITDH));
		data <= std_logic_vector(to_unsigned(16#1#, c_WB_DATA_BUS_WITDH));
		wait until rising_edge(clock);
		Write_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert led_0 = '1' report "LED 0 not on!" severity warning;

		wait until rising_edge(clock);

		-- Set LED 0 to off
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WITDH));
		data <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		wait until rising_edge(clock);
		Write_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert led_0 = '0' report "LED 0 not off!" severity warning;
	end procedure;

	procedure Read_State_LED_0 is
	begin
		report "Read_State_LED_0" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- Set LED 0 to on so that the register value is /= 0
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WITDH));
		data <= std_logic_vector(to_unsigned(16#1#, c_WB_DATA_BUS_WITDH));
		wait until rising_edge(clock);
		Write_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert led_0 = '1' report "LED 0 not on!" severity warning;

		wait until rising_edge(clock);

		-- Read register Value
		address <= std_logic_vector(to_unsigned(16#0#, c_WB_ADDRESS_BUS_WITDH));
		wait until rising_edge(clock);
		Read_Value(address, data);
		wait for c_CLOCK_PERIOD / 2;
		assert data = std_logic_vector(to_unsigned(16#1#, c_WB_DATA_BUS_WITDH)) report "Register value not correct!" severity warning;
	end procedure;

	procedure Read_Invalid_Address is
	begin
		report "Read_Invalid_Address" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		ADR_I <= std_logic_vector(to_unsigned(8, c_WB_ADDRESS_BUS_WITDH));
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

	procedure Write_Invalid_Address is
	begin
		report "Write_Invalid_Address" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		ADR_I <= std_logic_vector(to_unsigned(8, c_WB_ADDRESS_BUS_WITDH));
		CYC_I <= '1';
		STB_I <= '1';
		WE_I <= '0';

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
	Set_And_Reset_LED_0;
	-- TODO: other registers
	wait for c_CLOCK_PERIOD * 5;

	testCaseId <= 2;
	Read_State_LED_0;
	-- TODO: other registers
	wait for c_CLOCK_PERIOD * 5;

	-- TODO: test case for invalid address
	testCaseId <= 3;
	Read_Invalid_Address;
	wait for c_CLOCK_PERIOD * 5;

	testCaseId <= 4;
	Write_Invalid_Address;
	wait for c_CLOCK_PERIOD * 5;

	-- testing finished
	wait;
end process;

end behave;
