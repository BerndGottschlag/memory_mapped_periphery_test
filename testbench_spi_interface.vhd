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


entity spi_interface_tb is
end spi_interface_tb;

architecture behave of spi_interface_tb is
	-- system clock
	constant c_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period
	-- spi clock
	constant c_SPI_CLOCK_HALF_PERIOD : time := 10 us; -- 100 kHz clock -> 10 us period -> 5 us half period

	constant c_NUMBER_OF_ADDRESS_BITS: integer := 15;
	constant c_NUMBER_OF_DATA_BITS: integer := 8;

	constant c_MODE_READ: std_logic := '0';
	constant c_MODE_WRITE: std_logic := '1';

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;
	signal bitCounter : natural range 0 to 255;

	signal r_spi_address: std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0);
	signal r_spi_data: std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0);
	signal r_data_to_compare: std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0);

	signal r_debug_unsigned: natural range 0 to 255;

	-- wishbone interface of the UUT
	constant c_WB_ADDRESS_BUS_WIDTH : integer := 16;
	constant c_WB_DATA_BUS_WIDTH : integer := 8;

	signal DAT_I : std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0);
	signal DAT_O : std_logic_vector (c_WB_DATA_BUS_WIDTH - 1 downto 0);
	signal ADR_O : std_logic_vector (c_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
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
			g_WB_ADDRESS_BUS_WIDTH : integer := 16;
			g_WB_DATA_BUS_WIDTH : integer := 8
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
			o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
			i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
			o_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
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

		DAT_I <= std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WIDTH));
		ACK_I <= '0';
		ERR_I <= '0';

		r_spi_address <= std_logic_vector(to_unsigned(0, c_NUMBER_OF_ADDRESS_BITS));
		r_spi_data <= std_logic_vector(to_unsigned(0, c_NUMBER_OF_DATA_BITS));
		r_data_to_compare <= std_logic_vector(to_unsigned(0, c_NUMBER_OF_DATA_BITS));

		wait for c_CLOCK_PERIOD;
	end procedure;
	-- TODO: also reset test bench

	procedure Assert_Wishbone_Interface_Idle is
	begin
		assert STB_O = '0' report "STB_O not correct!" severity warning;
		assert CYC_O = '0' report "CYC_O not correct!" severity warning;
		assert WE_O = '0' report "WE_O not correct!" severity warning;
	end procedure;

	procedure Assert_Wishbone_Interface_Write(
		signal i_expected_address: in std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0);
		signal i_expected_data: in std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0)
	) is
	begin
		assert STB_O = '1' report "STB_O not correct!" severity warning;
		assert CYC_O = '1' report "CYC_O not correct!" severity warning;
		assert WE_O = '1' report "WE_O not correct!" severity warning;
		assert ADR_O(c_NUMBER_OF_ADDRESS_BITS - 1 downto 0) = i_expected_address report "Address not correct!" severity warning;
		assert DAT_O = i_expected_data report "Data not correct!" severity warning;
	end procedure;

	procedure Assert_Wishbone_Interface_Read(
		signal i_expected_address: in std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0)
	) is
	begin
		assert STB_O = '1' report "STB_O not correct!" severity warning;
		assert CYC_O = '1' report "CYC_O not correct!" severity warning;
		assert WE_O = '0' report "WE_O not correct!" severity warning;
		assert ADR_O(c_NUMBER_OF_ADDRESS_BITS - 1 downto 0) = i_expected_address report "Address not correct!" severity warning;
	end procedure;


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
				DAT_I <= std_logic_vector(to_unsigned(16#BB#, c_WB_DATA_BUS_WIDTH));
				wait for c_CLOCK_PERIOD;
				ACK_I <= '0';
			end if;

			wait until falling_edge(sclk);

		end loop;

		wait for c_SPI_CLOCK_HALF_PERIOD/2; -- Wait a bit to de-assert cs
		cs <= '1';
	end procedure;

	procedure Test_Case_Write_Operation_Multiple is
	begin
		report "Test_Case_Write_Operation_Multiple" severity note;
		testCaseId <= 3;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions
		cs <= '1';
		mosi <= '0';
		wait for 10 us;

		-- test
		r_spi_address <= std_logic_vector(to_unsigned(16#5ABC#, c_NUMBER_OF_ADDRESS_BITS));
		r_spi_data <= std_logic_vector(to_unsigned(16#DE#, c_NUMBER_OF_DATA_BITS));

		cs <= '0';

		-- mode
		mosi <= c_MODE_WRITE;

		-- address
		for i in 0 to c_NUMBER_OF_ADDRESS_BITS - 1 loop
			wait until falling_edge(sclk);
			mosi <= r_spi_address(c_NUMBER_OF_ADDRESS_BITS - 1 - i);
		end loop;

		-- data byte 0
		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			wait until falling_edge(sclk);
			mosi <= r_spi_data(c_NUMBER_OF_DATA_BITS - 1 - i);
		end loop;

		wait until rising_edge(CYC_O);
		wait until rising_edge(clock);
		ACK_I <= '1';
		Assert_Wishbone_Interface_Write(r_spi_address, r_spi_data);
		wait until rising_edge(clock);
		ACK_I <= '0';
		wait until rising_edge(clock);
		Assert_Wishbone_Interface_Idle;

		-- data byte 1
		r_spi_data <= std_logic_vector(to_unsigned(16#ED#, c_NUMBER_OF_DATA_BITS));
		r_spi_address <= std_logic_vector(unsigned(r_spi_address) + 1);
		wait until rising_edge(clock);
		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			wait until falling_edge(sclk);
			mosi <= r_spi_data(c_NUMBER_OF_DATA_BITS - 1 - i);
		end loop;

		wait until rising_edge(CYC_O);
		wait until rising_edge(clock);
		ACK_I <= '1';
		Assert_Wishbone_Interface_Write(r_spi_address, r_spi_data);
		wait until rising_edge(clock);
		ACK_I <= '0';
		wait until rising_edge(clock);
		Assert_Wishbone_Interface_Idle;

		wait until falling_edge(sclk);
		wait for c_SPI_CLOCK_HALF_PERIOD/2; -- Wait a bit to de-assert cs
		cs <= '1';
	end procedure;

	procedure Test_Case_Read_Operation_Multiple is
	begin
		report "Test_Case_Read_Operation_Multiple" severity note;
		testCaseId <= 4;
		Reset_Testbench;
		wait until rising_edge(clock);

		-- set up test start conditions
		cs <= '1';
		mosi <= '0';
		wait for 10 us;

		-- test
		r_spi_address <= std_logic_vector(to_unsigned(16#5ABC#, c_NUMBER_OF_ADDRESS_BITS));
		r_data_to_compare <= std_logic_vector(to_unsigned(16#DE#, c_NUMBER_OF_DATA_BITS));

		cs <= '0';

		-- mode
		mosi <= c_MODE_READ;

		-- address
		for i in 0 to c_NUMBER_OF_ADDRESS_BITS - 1 loop
			wait until falling_edge(sclk);
			mosi <= r_spi_address(c_NUMBER_OF_ADDRESS_BITS - 1 - i);
		end loop;

		wait until rising_edge(CYC_O);
		wait until rising_edge(clock);
		ACK_I <= '1';
		Assert_Wishbone_Interface_Read(r_spi_address);
		DAT_I <= r_data_to_compare;
			
		wait until rising_edge(clock);
		ACK_I <= '0';
		wait until rising_edge(clock);
		Assert_Wishbone_Interface_Idle;

		-- data byte 0
		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			wait until falling_edge(sclk);
			wait until rising_edge(sclk);
			r_spi_data(c_NUMBER_OF_DATA_BITS - 1 - i) <= miso;
			r_debug_unsigned <= c_NUMBER_OF_DATA_BITS - 1 - i;
		end loop;
		wait until rising_edge(clock);
		assert r_data_to_compare = r_spi_data report "Data not correct!" severity warning;

		-- data byte 1
		r_data_to_compare <= std_logic_vector(to_unsigned(16#ED#, c_NUMBER_OF_DATA_BITS));
		r_spi_address <= std_logic_vector(unsigned(r_spi_address) + 1);

		wait until rising_edge(CYC_O);
		wait until rising_edge(clock);
		ACK_I <= '1';
		Assert_Wishbone_Interface_Read(r_spi_address);
		DAT_I <= r_data_to_compare;
			
		wait until rising_edge(clock);
		ACK_I <= '0';
		wait until rising_edge(clock);
		Assert_Wishbone_Interface_Idle;

		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			wait until falling_edge(sclk);
			wait until rising_edge(sclk);
			r_spi_data(c_NUMBER_OF_DATA_BITS - 1 - i) <= miso;
			r_debug_unsigned <= c_NUMBER_OF_DATA_BITS - 1 - i;
		end loop;
		wait until rising_edge(clock);
		assert r_data_to_compare = r_spi_data report "Data not correct!" severity warning;

		-- Last dummy wishbone transaction so that the interface does not hang
		wait until rising_edge(CYC_O);
		wait until rising_edge(clock);
		ACK_I <= '1';
		wait until rising_edge(clock);
		ACK_I <= '0';

		wait until falling_edge(sclk);
		wait for c_SPI_CLOCK_HALF_PERIOD/2; -- Wait a bit to de-assert cs
		cs <= '1';
	end procedure;

	begin
		--Test_Case_Write_Operation;
		--wait for c_SPI_CLOCK_HALF_PERIOD * 10;
		--Test_Case_Read_Operation;
		--wait for c_SPI_CLOCK_HALF_PERIOD * 10;
		--Test_Case_Write_Operation_Multiple;
		--wait for c_SPI_CLOCK_HALF_PERIOD * 10;
		Test_Case_Read_Operation_Multiple;
		wait for c_SPI_CLOCK_HALF_PERIOD * 10;

		-- testing finished
		wait;
	end process;

end behave;
