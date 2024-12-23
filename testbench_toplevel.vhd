library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity toplevel_tb is
end toplevel_tb;

architecture behave of toplevel_tb is
	-- system clock
	constant c_OSCI_CLOCK_PERIOD : time := 20 ns; -- 50 MHz clock -> 20 ns period
	-- spi clock
	constant c_SPI_CLOCK_HALF_PERIOD : time := 10 us; -- 100 kHz clock -> 10 us period -> 5 us half period

	-- internal signals of the test bench
	signal testCaseId: natural range 0 to 255;
	signal testPhaseCounter: natural range 0 to 255;

	-- misc constants
	constant c_NUMBER_OF_MODE_BITS: integer := 1;
	constant c_NUMBER_OF_ADDRESS_BITS: integer := 15;
	constant c_NUMBER_OF_DATA_BITS: integer := 8;

	constant c_BUTTON_INPUT_REGISTER_BASE_ADDRESS: integer := 16#0#;
	constant c_LED_OUTPUT_REGISTER_BASE_ADDRESS: integer := 16#400#;

	-- SPI interface
	constant c_MODE_READ: integer := 0;
	constant c_MODE_WRITE: integer := 1;

	signal r_cs: std_logic := '1';
	signal r_sclk: std_logic := '0';
	signal r_mosi: std_logic := '0';
	signal r_miso: std_logic := '0';

	signal r_mode : std_logic_vector (c_NUMBER_OF_MODE_BITS - 1 downto 0);
	signal r_address : std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0);
	signal r_data : std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0);

	-- buttons
	signal r_button_0: std_logic := '0';
	signal r_button_1: std_logic := '0';
	signal r_button_2: std_logic := '0';
	signal r_button_3: std_logic := '0';

	-- leds
	signal r_led_0: std_logic := '0';
	signal r_led_1: std_logic := '0';
	signal r_led_2: std_logic := '0';
	signal r_led_3: std_logic := '0';
	signal r_led_4: std_logic := '0';
	signal r_led_5: std_logic := '0';
	signal r_led_6: std_logic := '0';
	signal r_led_7: std_logic := '0';

	-- other input signals to the UUT
	signal osci_clock: std_logic := '0';
	signal reset: std_logic := '0'; -- low active
	signal r_osci_enable: std_logic;

	signal r_test: std_logic := '0';
	signal r_test_int: integer := 0;
	signal r_test_mode : std_logic_vector (c_NUMBER_OF_MODE_BITS - 1 downto 0);

	-- Component declaration for the UUT
	component toplevel is
		port (
			i_osci_clock : in std_logic; -- Has to be 50 MHz
			i_reset : in std_logic;

			-- SPI interface
			i_cs: in std_logic;
			i_sclk: in std_logic;
			i_mosi: in std_logic;
			o_miso: out std_logic;
			o_osci_enable : out std_logic;

			-- buttons
			i_button_0 : in std_logic;
			i_button_1 : in std_logic;
			i_button_2 : in std_logic;
			i_button_3 : in std_logic;

			-- leds
			o_led_0 : out std_logic;
			o_led_1 : out std_logic;
			o_led_2 : out std_logic;
			o_led_3 : out std_logic;
			o_led_4 : out std_logic;
			o_led_5 : out std_logic;
			o_led_6 : out std_logic;
			o_led_7 : out std_logic
		);
	end component toplevel;
begin
	-- Instantiate the UUT
	UUT: toplevel
		port map (
			i_osci_clock => osci_clock,
			i_reset => reset,
			o_osci_enable => r_osci_enable,

			-- SPI interface
			i_cs => r_cs,
			i_sclk => r_sclk,
			i_mosi => r_mosi,
			o_miso => r_miso,

			-- buttons
			i_button_0 => r_button_0,
			i_button_1 => r_button_1,
			i_button_2 => r_button_2,
			i_button_3 => r_button_3,

			-- leds
			o_led_0 => r_led_0,
			o_led_1 => r_led_1,
			o_led_2 => r_led_2,
			o_led_3 => r_led_3,
			o_led_4 => r_led_4,
			o_led_5 => r_led_5,
			o_led_6 => r_led_6,
			o_led_7 => r_led_7
			);

	p_Clock_Generator : process is
	begin
		wait for c_OSCI_CLOCK_PERIOD/2;
		osci_clock <= not osci_clock;
	end process p_Clock_Generator;

process
	-- shared procedures
	procedure Reset_Testbench is
	begin
		-- reset the UUT
		reset <= '0';

		testPhaseCounter <= 0;

		-- reset testbench signals
		-- TODO
		r_cs <= '1';
		r_mosi <= '0';
		r_sclk <= '0';

		r_mode  <= std_logic_vector(to_unsigned(c_MODE_READ, c_NUMBER_OF_MODE_BITS));
		r_address <= std_logic_vector(to_unsigned(0, c_NUMBER_OF_ADDRESS_BITS));
		r_data <= std_logic_vector(to_unsigned(0, c_NUMBER_OF_DATA_BITS));

		-- buttons
		r_button_0 <= '0';
		r_button_1 <= '0';
		r_button_2 <= '0';
		r_button_3 <= '0';

		wait for c_OSCI_CLOCK_PERIOD;
		reset <= '1';


		assert
			r_miso = '0' and
			r_led_0 = '0' and
			r_led_1 = '0' and
			r_led_2 = '0' and
			r_led_3 = '0' and
			r_led_4 = '0' and
			r_led_5 = '0' and
			r_led_6 = '0' and
			r_led_7 = '0'
		report "UUT not reset!" severity warning;
	end procedure;

	procedure Write_Register (signal i_mode : in std_logic_vector (c_NUMBER_OF_MODE_BITS - 1 downto 0);
	                          signal i_address : in std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0);
	                          signal i_data : in std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0)
	                         ) is
	begin
		r_test_mode <= i_mode;
		r_cs <= '0';
		r_sclk <= '0';
		for i in 0 to c_NUMBER_OF_MODE_BITS - 1 loop
			r_test_int <= c_NUMBER_OF_MODE_BITS - 1 - i;
			r_test <= i_mode(c_NUMBER_OF_MODE_BITS - 1 - i);
			r_mosi <= i_mode(c_NUMBER_OF_MODE_BITS - 1 - i);
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		for i in 0 to c_NUMBER_OF_ADDRESS_BITS - 1 loop
			r_mosi <= i_address(c_NUMBER_OF_ADDRESS_BITS - 1 - i);
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			r_mosi <= i_data(c_NUMBER_OF_DATA_BITS - 1 - i);
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		wait for c_SPI_CLOCK_HALF_PERIOD;
		r_cs <= '1';
	end procedure;

	procedure Read_Register (signal i_mode : in std_logic_vector (c_NUMBER_OF_MODE_BITS - 1 downto 0);
	                         signal i_address : in std_logic_vector (c_NUMBER_OF_ADDRESS_BITS - 1 downto 0);
	                         signal o_data : out std_logic_vector (c_NUMBER_OF_DATA_BITS - 1 downto 0)
	                        ) is
	begin
		r_test_mode <= i_mode;
		r_cs <= '0';
		r_sclk <= '0';
		for i in 0 to c_NUMBER_OF_MODE_BITS - 1 loop
			r_test_int <= c_NUMBER_OF_MODE_BITS - 1 - i;
			r_test <= i_mode(c_NUMBER_OF_MODE_BITS - 1 - i);
			r_mosi <= i_mode(c_NUMBER_OF_MODE_BITS - 1 - i);
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		for i in 0 to c_NUMBER_OF_ADDRESS_BITS - 1 loop
			r_mosi <= i_address(c_NUMBER_OF_ADDRESS_BITS - 1 - i);
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		for i in 0 to c_NUMBER_OF_DATA_BITS - 1 loop
			wait for c_SPI_CLOCK_HALF_PERIOD;
			o_data(c_NUMBER_OF_DATA_BITS - 1 - i) <= r_miso;
			r_sclk <= '1';
			wait for c_SPI_CLOCK_HALF_PERIOD;
			r_sclk <= '0';
		end loop;

		wait for c_SPI_CLOCK_HALF_PERIOD;
		r_cs <= '1';
	end procedure;


	-- test cases
	procedure Test_Case_Set_LED_0 is
	begin
		report "Test_Case_Set_LED_0" severity note;
		Reset_Testbench;
		wait until rising_edge(osci_clock);


		r_mode <= std_logic_vector(to_unsigned(c_MODE_WRITE, c_NUMBER_OF_MODE_BITS));
		r_address <= std_logic_vector(to_unsigned(c_LED_OUTPUT_REGISTER_BASE_ADDRESS, c_NUMBER_OF_ADDRESS_BITS));
		r_data <= std_logic_vector(to_unsigned(1, c_NUMBER_OF_DATA_BITS));
		wait until rising_edge(osci_clock);

		Write_Register(r_mode, r_address, r_data);
		wait until rising_edge(osci_clock);
		assert r_led_0 = '0' report "LED 0 not switched on!" severity warning;

	end procedure;

	procedure Test_Case_Read_Button_0 is
	begin
		report "Test_Case_Read_Button_0" severity note;
		Reset_Testbench;
		wait until rising_edge(osci_clock);

		r_button_0 <= '1';

		r_mode <= std_logic_vector(to_unsigned(c_MODE_READ, c_NUMBER_OF_MODE_BITS));
		r_address <= std_logic_vector(to_unsigned(c_BUTTON_INPUT_REGISTER_BASE_ADDRESS, c_NUMBER_OF_ADDRESS_BITS));
		wait until rising_edge(osci_clock);

		Read_Register(r_mode, r_address, r_data);
		wait until rising_edge(osci_clock);
		assert r_data = "00000001" report "Button 0 not read correctly!" severity warning;

	end procedure;


-- main testing sequence
begin
		wait for 250 ns; -- Wait until PLL lock
		-- TODO: assert PLL lock

		testCaseId <= 1;
		Test_Case_Set_LED_0;
		wait for c_OSCI_CLOCK_PERIOD * 5;

		testCaseId <= 2;
		Test_Case_Read_Button_0;
		wait for c_OSCI_CLOCK_PERIOD * 5;

		-- testing finished
		wait;
end process;

end behave;
