library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity intercon_tb is
end intercon_tb;

architecture behave of intercon_tb is
	-- system clock
	constant c_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;

	-- wishbone interfaces of the UUT
	constant c_WB_DATA_BUS_WITDH : integer := 8;
	constant c_M0_WB_ADDRESS_BUS_WITDH : integer := 16;
	constant c_S0_WB_ADDRESS_BUS_WITDH : integer := 10;
	constant c_S1_WB_ADDRESS_BUS_WITDH : integer := 10;

	signal M0_DAT_I : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal M0_DAT_O : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal M0_ADR_I : std_logic_vector (c_M0_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	signal M0_ACK_O : std_logic := '0';
	signal M0_CYC_I : std_logic := '0';
	signal M0_STB_I : std_logic := '0';
	signal M0_ERR_O : std_logic := '0';
	signal M0_WE_I : std_logic := '0';

	signal S0_DAT_O : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal S0_DAT_I : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal S0_ADR_O : std_logic_vector (c_S0_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	signal S0_ACK_I : std_logic := '0';
	signal S0_CYC_O : std_logic := '0';
	signal S0_STB_O : std_logic := '0';
	signal S0_ERR_I : std_logic := '0';
	signal S0_WE_O : std_logic := '0';

	signal S1_DAT_O : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal S1_DAT_I : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal S1_ADR_O : std_logic_vector (c_S1_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	signal S1_ACK_I : std_logic := '0';
	signal S1_CYC_O : std_logic := '0';
	signal S1_STB_O : std_logic := '0';
	signal S1_ERR_I : std_logic := '0';
	signal S1_WE_O : std_logic := '0';

	-- other input signals to the UUT
	signal clock: std_logic := '0';
	signal reset: std_logic := '0'; -- high active

	-- Component declaration for the UUT
	component intercon is
		generic (
			g_WB_DATA_BUS_WITDH : integer := 8;
			g_M0_WB_ADDRESS_BUS_WITDH : integer := 16;
			g_S0_WB_ADDRESS_BUS_WITDH : integer := 10;
			g_S1_WB_ADDRESS_BUS_WITDH : integer := 10;

			-- address space
			g_S0_ADDRESS_START : integer := 16#0#;
			g_S0_ADDRESS_END : integer := 16#3FF#;

			g_S1_ADDRESS_START : integer := 16#400#;
			g_S1_ADDRESS_END : integer := 16#7FF#
			);
		port (
			-- shared signals
			i_wb_rst : in std_logic;
			i_wb_clk : in std_logic;

			-- master interface (wishbown slave)
			i_m0_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_m0_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_m0_wb_adr : in std_logic_vector (g_M0_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			o_m0_wb_ack : out std_logic;
			i_m0_wb_cyc : in std_logic;
			i_m0_wb_stb : in std_logic;
			o_m0_wb_err : out std_logic;
			i_m0_wb_we : in std_logic;

			-- slave 0 interface (wishbown master)
			o_s0_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_s0_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_s0_wb_adr : out std_logic_vector (g_S0_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			i_s0_wb_ack : in std_logic;
			o_s0_wb_cyc : out std_logic;
			o_s0_wb_stb : out std_logic;
			i_s0_wb_err : in std_logic;
			o_s0_wb_we : out std_logic;

			-- slave 1 interface (wishbown master)
			o_s1_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_s1_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_s1_wb_adr : out std_logic_vector (g_S1_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			i_s1_wb_ack : in std_logic;
			o_s1_wb_cyc : out std_logic;
			o_s1_wb_stb : out std_logic;
			i_s1_wb_err : in std_logic;
			o_s1_wb_we : out std_logic
		);
	end component intercon;

begin
	-- Instantiate the UUT
	UUT: intercon
		port map (
			i_wb_clk => clock,
			i_wb_rst => reset,

			-- master interface (wishbown slave)
			i_m0_wb_dat => M0_DAT_I,
			o_m0_wb_dat => M0_DAT_O,
			i_m0_wb_adr => M0_ADR_I,
			o_m0_wb_ack => M0_ACK_O,
			i_m0_wb_cyc => M0_CYC_I,
			i_m0_wb_stb => M0_STB_I,
			o_m0_wb_err => M0_ERR_O,
			i_m0_wb_we => M0_WE_I,

			-- slave 0 interface (wishbown master)
			o_s0_wb_dat => S0_DAT_O,
			i_s0_wb_dat => S0_DAT_I,
			o_s0_wb_adr => S0_ADR_O,
			i_s0_wb_ack => S0_ACK_I,
			o_s0_wb_cyc => S0_CYC_O,
			o_s0_wb_stb => S0_STB_O,
			i_s0_wb_err => S0_ERR_I,
			o_s0_wb_we => S0_WE_O,

			-- slave 1 interface (wishbown master)
			o_s1_wb_dat => S1_DAT_O,
			i_s1_wb_dat => S1_DAT_I,
			o_s1_wb_adr => S1_ADR_O,
			i_s1_wb_ack => S1_ACK_I,
			o_s1_wb_cyc => S1_CYC_O,
			o_s1_wb_stb => S1_STB_O,
			i_s1_wb_err => S1_ERR_I,
			o_s1_wb_we => S1_WE_O
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
		M0_DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(0, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';
		S0_DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
		S0_ACK_I <= '0';
		S0_ERR_I <= '0';
		S1_DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
		S1_ACK_I <= '0';
		S1_ERR_I <= '0';

		wait for c_CLOCK_PERIOD;
		reset <= '0';
	end procedure;


	-- TODO: asserts on internal signals:
	-- - for VHDL 2008: https://stackoverflow.com/questions/34061074/is-it-possible-to-access-components-of-the-uut-in-vhdl-testbench
	-- - for older version: https://stackoverflow.com/questions/40286725/how-can-i-get-internal-signals-to-testbench-in-vhdl-97-and-isim

	-- test cases
	procedure Test_Case_Slave_0_Read_Address_0x0 is
	begin
		report "Test_Case_Slave_0_Read_Address_0x0" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#0#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '0';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '0' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S0_WB_ADDRESS_BUS_WITDH)) report "S0_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_DAT_I <= std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH));
		S0_ACK_I <= '1';
		S0_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '0' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S0_WB_ADDRESS_BUS_WITDH)) report "S0_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_ACK_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;
		assert M0_ACK_O = '1' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '0' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Slave_0_Write_Address_0x3FF is
	begin
		report "Test_Case_Slave_0_Write_Address_0x3FF" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#3FF#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '1';
		M0_DAT_I <= std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH));

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '1' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#3FF#, c_S0_WB_ADDRESS_BUS_WITDH)) report "S0_ADR_O not correct!" severity warning;
		assert S0_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_ACK_I <= '1';
		S0_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '1' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#3FF#, c_S0_WB_ADDRESS_BUS_WITDH)) report "S0_ADR_O not correct!" severity warning;
		assert S0_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_ACK_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_ACK_O = '1' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '0' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Slave_1_Read_Address_0x400 is
	begin
		report "Test_Case_Slave_1_Read_Address_0x400" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#400#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '0';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 1
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '0' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_DAT_I <= std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH));
		S1_ACK_I <= '1';
		S1_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 0
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '0' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_ACK_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;
		assert M0_ACK_O = '1' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '0' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Slave_1_Write_Address_0x7FF is
	begin
		report "Test_Case_Slave_1_Write_Address_0x7FF" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#7FF#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '1';
		M0_DAT_I <= std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH));

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 0
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '1' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#3FF#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;
		assert S1_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "S1_DAT_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_ACK_I <= '1';
		S1_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 0
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '1' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#3FF#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;
		assert S1_DAT_O = std_logic_vector(to_unsigned(16#AB#, c_WB_DATA_BUS_WITDH)) report "S1_DAT_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_ACK_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_ACK_O = '1' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '0' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Slave_0_Error is
	begin
		report "Test_Case_Slave_0_Error" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#0#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '0';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '0' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S0_WB_ADDRESS_BUS_WITDH)) report "0 S0_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		S0_ACK_I <= '0';
		S0_ERR_I <= '1';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Slave 0
		assert S0_CYC_O = '1' and S0_CYC_O = '1' and S0_WE_O = '0' report "Interface Slave 0 not active!" severity warning;
		assert S0_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S0_WB_ADDRESS_BUS_WITDH)) report "S0_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S0_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 1 has to be idle
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_DAT_O = std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;
		assert M0_ACK_O = '0' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '1' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Slave_1_Error is
	begin
		report "Test_Case_Slave_1_Error" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#400#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '0';

		wait until rising_edge(clock);
		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 1
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '0' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		S1_ACK_I <= '0';
		S1_ERR_I <= '1';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Slave 0
		assert S1_CYC_O = '1' and S1_CYC_O = '1' and S1_WE_O = '0' report "Interface Slave 1 not active!" severity warning;
		assert S1_ADR_O = std_logic_vector(to_unsigned(16#0#, c_S1_WB_ADDRESS_BUS_WITDH)) report "S1_ADR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set input on Slave 0
		S1_ERR_I <= '0';

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- Check output on Master 0
		assert M0_DAT_O = std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH)) report "M0_DAT_O not correct!" severity warning;
		assert M0_ACK_O = '0' report "M0_ACK_O not correct!" severity warning;
		assert M0_ERR_O = '1' report "M0_ERR_O not correct!" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;
	end procedure;

	procedure Test_Case_Read_Invalid_Address_0x800 is
	begin
		report "Test_Case_Read_Invalid_Address_0x800" severity note;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions

		-- test
		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

		-- set master signals
		M0_DAT_I <= std_logic_vector(to_unsigned(16#0#, c_WB_DATA_BUS_WITDH));
		M0_ADR_I <= std_logic_vector(to_unsigned(16#800#, c_M0_WB_ADDRESS_BUS_WITDH));
		M0_CYC_I <= '1';
		M0_STB_I <= '1';
		M0_WE_I <= '0';

		wait until rising_edge(clock);

		wait for c_CLOCK_PERIOD / 2;
		-- Slave 0 has to be idle
		-- Both slaves have to be idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;

		-- The Master interface has to signal an error
		assert M0_ERR_O = '1' report "M0_ERR_I not correct" severity warning;

		wait until rising_edge(clock);

		-- Set Master 0 to idle
		M0_CYC_I <= '0';
		M0_STB_I <= '0';
		M0_WE_I <= '0';

		wait for c_CLOCK_PERIOD / 2;

		-- Check that both slaves are idle
		assert S0_CYC_O = '0' and S0_CYC_O = '0' and S0_WE_O = '0' report "Interface Slave 0 not idle!" severity warning;
		assert S1_CYC_O = '0' and S1_CYC_O = '0' and S1_WE_O = '0' report "Interface Slave 1 not idle!" severity warning;

	end procedure;

	-- main testing sequence
	begin
		testCaseId <= 1;
		Test_Case_Slave_0_Read_Address_0x0;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 2;
		Test_Case_Slave_0_Write_Address_0x3FF;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 3;
		Test_Case_Slave_1_Read_Address_0x400;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 4;
		Test_Case_Slave_1_Write_Address_0x7FF;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 5;
		Test_Case_Slave_0_Error;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 6;
		Test_Case_Slave_1_Error;
		wait for c_CLOCK_PERIOD * 5;
		testCaseId <= 7;
		Test_Case_Read_Invalid_Address_0x800;
		wait for c_CLOCK_PERIOD * 5;
		-- TODO: error from slave

		-- testing finished
		wait;
end process;

end behave;
