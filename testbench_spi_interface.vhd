library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity spi_interface_tb is
end spi_interface_tb;

architecture behave of spi_interface_tb is
	-- system clock
	constant c_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period
	-- spi clock
	constant c_SPI_CLOCK_HALF_PERIOD : time := 10 us; -- 100 kHz clock -> 10 us period -> 5 us half period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;
	signal bitCounter : natural range 0 to 255;

	-- wishbone interface of the UUT
	constant c_WB_ADDRESS_BUS_WITDH : integer := 16;
	constant c_WB_DATA_BUS_WITDH : integer := 8;

	signal DAT_I : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal DAT_O : std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0);
	signal ADR_O : std_logic_vector (c_WB_ADDRESS_BUS_WITDH - 1 downto 0);
	signal ACK_I : std_logic := '0';
	signal CYC_O : std_logic := '0';
	signal STB_O : std_logic := '0';
	signal ERR_I : std_logic := '0';
	signal WE_O : std_logic := '0';


	-- input signals to the UUT
	signal clock: std_logic := '0';
	signal reset: std_logic := '0'; -- high active

	signal cs: std_logic := '1'; -- high active
	signal sclk: std_logic := '0';
	signal mosi: std_logic := '0';

	-- output signals from the UUT
	signal miso: std_logic;


	-- Component declaration for the UUT
	component spi_interface is
		generic (
			g_WB_ADDRESS_BUS_WITDH : integer := 16;
			g_WB_DATA_BUS_WITDH : integer := 8
			);
		port (
			-- spi interface
			i_cs: in std_logic;
			i_sclk: in std_logic;
			i_mosi: in std_logic;
			o_miso: out std_logic;

			-- wishbone interface
			i_wb_rst : in std_logic; -- High active
			i_wb_clk : in std_logic; -- For simplicity this module also uses the WISHBONE clock for its internal logic
			o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			i_wb_ack : in std_logic;
			o_wb_cyc : out std_logic;
			o_wb_stb : out std_logic;
			i_wb_err : in std_logic; -- TODO: currently unimplemented
			o_wb_we : out std_logic
			);
	end component spi_interface;

begin
	-- Instantiate the UUT
	UUT: spi_interface
		port map (
			i_wb_clk => clock,
			i_wb_rst => reset,
			o_wb_dat => DAT_O,
			i_wb_dat => DAT_I,
			o_wb_adr => ADR_O,
			i_wb_ack => ACK_I,
			o_wb_cyc => CYC_O,
			o_wb_stb => STB_O,
			i_wb_err => ERR_I, -- TODO: currently unimplemented
			o_wb_we => WE_O,

			i_cs => cs,
			i_sclk => sclk,
			i_mosi => mosi,
			o_miso => miso
			);

	p_Clock_Generator : process is
	begin
		wait for c_CLOCK_PERIOD/2;
		clock <= not clock;
	end process p_Clock_Generator;

	p_SCLK_Generator : process is
	begin
		if cs = '0' then
			wait for c_SPI_CLOCK_HALF_PERIOD;
			sclk <= not sclk;
		else
			wait for c_CLOCK_PERIOD/2;
		end if;
	end process p_SCLK_Generator;


process
	-- shared procedures
	procedure Reset_Testbench is
	begin
		-- reset the UUT
		reset <= '1';
		wait for c_CLOCK_PERIOD * 10;
		reset <= '0';
	-- TODO: assert that the interface is fully reset

		testPhaseCounter <= 0;
		bitCounter <= 0;

		DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
		ACK_I <= '0';
		ERR_I <= '0';
	end procedure;
	-- TODO: also reset test bench


	-- TODO: asserts on internal signals:
	-- - for VHDL 2008: https://stackoverflow.com/questions/34061074/is-it-possible-to-access-components-of-the-uut-in-vhdl-testbench
	-- - for older version: https://stackoverflow.com/questions/40286725/how-can-i-get-internal-signals-to-testbench-in-vhdl-97-and-isim

	-- test cases
	procedure Test_Case_Write_Operation is
	begin
		testCaseId <= 1;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions
		cs <= '1';
		mosi <= '0';
		wait for 10 us;

		-- test
		cs <= '0';
		for i in 0 to 23 loop
			mosi <= not mosi;

			wait until rising_edge(sclk);
			if (CYC_O = '1') then
				ACK_I <= '1';
				wait for c_CLOCK_PERIOD;
				ACK_I <= '0';
			end if;

			wait until falling_edge(sclk);

		end loop;

		wait for c_SPI_CLOCK_HALF_PERIOD/2; -- Wait a bit to de-assert cs
		cs <= '1';


	end procedure;

	procedure Test_Case_Read_Operation is
	begin
		testCaseId <= 2;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions
		cs <= '1';
		mosi <= '0';
		wait for 10 us;

		-- test
		cs <= '0';
		mosi <= '1';
		wait for c_CLOCK_PERIOD;
		for i in 0 to 23 loop
			mosi <= not mosi;

			wait until rising_edge(sclk);

			wait for c_CLOCK_PERIOD;
			if (CYC_O = '1') then
				ACK_I <= '1';
				DAT_I <= std_logic_vector(to_unsigned(16#BB#, c_WB_DATA_BUS_WITDH));
				wait for c_CLOCK_PERIOD;
				ACK_I <= '0';
			end if;

			wait until falling_edge(sclk);

		end loop;

		wait for c_SPI_CLOCK_HALF_PERIOD/2; -- Wait a bit to de-assert cs
		cs <= '1';


	end procedure;

	-- main testing sequence
	begin
		Test_Case_Write_Operation;
		wait for c_SPI_CLOCK_HALF_PERIOD * 10;
		Test_Case_Read_Operation;

		-- testing finished
		wait;
end process;

end behave;
