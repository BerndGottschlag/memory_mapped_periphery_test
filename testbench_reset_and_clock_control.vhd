library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity reset_and_clock_control_tb is
end reset_and_clock_control_tb;

architecture behave of reset_and_clock_control_tb is
	-- osci clock
	constant c_OSCI_CLOCK_PERIOD : time := 20 ns; -- 50 MHz clock -> 20 ns period
	-- system clock
	constant c_PLL_CLOCK_PERIOD : time := 10 ns; -- 100 MHz clock -> 10 ns period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;

	-- input signals to the UUT
	signal r_osci_clock_input: std_logic := '0';
	signal r_reset_input: std_logic := '0';
	signal r_pll_clock: std_logic := '0';
	signal r_pll_lock: std_logic := '0';

	-- output signals from the UUT
	signal r_reset: std_logic := '0';

	-- Component declaration for the UUT
	component reset_and_clock_control is
		port (
			-- inputs from external pins
			i_osci_clk : in std_logic;
			i_reset : in std_logic; -- low active

			-- interface to the PLL
			i_pll_lock: in std_logic; -- high active

			-- outputs
			o_reset: out std_logic -- high active
		);
	end component reset_and_clock_control;
begin
	-- Instantiate the UUT
	UUT: reset_and_clock_control
		port map (
			i_osci_clk => r_osci_clock_input,
			i_reset => r_reset_input,
			i_pll_lock => r_pll_lock,
			o_reset => r_reset
			);

	p_Osci_Clock_Generator : process is
	begin
		wait for c_OSCI_CLOCK_PERIOD/2;
		r_osci_clock_input <= not r_osci_clock_input;
	end process p_Osci_Clock_Generator;

	p_PLL_Clock_Generator : process is
	begin
		wait for c_PLL_CLOCK_PERIOD/2;
		r_pll_clock <= not r_pll_clock;
	end process p_PLL_Clock_Generator;

	--p_SCLK_Generator : process is
	--begin
	--	if reset = '0' then
	--		if r_cs = '0' then
	--			wait for c_SPI_CLOCK_HALF_PERIOD;
	--			r_sclk <= '1';
	--			wait for c_SPI_CLOCK_HALF_PERIOD;
	--			r_sclk <= '0';
	--		else
	--			wait for c_OSCI_CLOCK_PERIOD/2;
	--		end if;
	--	else
	--		r_sclk <= '0';
	--		wait for c_OSCI_CLOCK_PERIOD/2;
	--	end if;
	--end process p_SCLK_Generator;

process
	-- shared procedures
	procedure Reset_Testbench is
	begin

		-- reset testbench signals
		r_reset_input <= '0';
		r_pll_lock <= '0';
	end procedure;

	-- test cases
	procedure Test_Case_PLL_Lock is
	begin
		report "Test_Case_PLL_Lock" severity note;
		Reset_Testbench;
		wait until rising_edge(r_osci_clock_input);

		r_reset_input <= '1';
		r_pll_lock <= '0';
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '1' report "Not in reset!" severity warning;

		wait until rising_edge(r_osci_clock_input);
		r_pll_lock <= '1';
		wait until rising_edge(r_osci_clock_input);
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '0' report "In reset!" severity warning;

		wait until rising_edge(r_osci_clock_input);
		r_pll_lock <= '0';
		wait until rising_edge(r_osci_clock_input);
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '1' report "Not in reset!" severity warning;
	end procedure;

	procedure Test_Case_Reset is
	begin
		report "Test_Case_Reset" severity note;
		Reset_Testbench;
		wait until rising_edge(r_osci_clock_input);

		r_reset_input <= '0';
		r_pll_lock <= '1';
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '1' report "Not in reset!" severity warning;

		wait until rising_edge(r_osci_clock_input);
		r_reset_input <= '1';
		wait until rising_edge(r_osci_clock_input);
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '0' report "In reset!" severity warning;

		wait until rising_edge(r_osci_clock_input);
		r_reset_input <= '0';
		wait until rising_edge(r_osci_clock_input);
		wait until rising_edge(r_osci_clock_input);

		assert r_reset = '1' report "Not in reset!" severity warning;
	end procedure;

-- main testing sequence
begin
		testCaseId <= 1;
		Test_Case_PLL_Lock;
		wait for c_OSCI_CLOCK_PERIOD * 5;

		testCaseId <= 2;
		Test_Case_Reset;
		wait for c_OSCI_CLOCK_PERIOD * 5;

		-- testing finished
		wait;
end process;

end behave;

