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

entity toplevel is
	port (
		i_osci_clock : in std_logic; -- Has to be 50 MHz
		i_reset : in std_logic; -- Has to be 50 MHz
		o_osci_enable : out std_logic;

		-- SPI interface
		i_cs: in std_logic;
		i_sclk: in std_logic;
		i_mosi: in std_logic;
		o_miso: out std_logic;

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
end toplevel;

-- TODO: implement the SYSCON module
--     - p. 32 Wishbone B4 specification: Recommendation 3.00: RST_O should be asserted during a power-up condition
architecture rtl of toplevel is
	-- misc
	signal r_sys_clk: std_logic := '0';
	signal r_pll_lock: std_logic := '0';

	signal r_reset: std_logic := '0'; -- TODO: connect to input pin and r_pll_lock

	-- Wishbone interfaces
	constant c_WB_DATA_BUS_WITDH : integer := 8;
	constant c_M0_WB_ADDRESS_BUS_WITDH : integer := 16;
	constant c_S0_WB_ADDRESS_BUS_WITDH : integer := 10;
	constant c_S1_WB_ADDRESS_BUS_WITDH : integer := 10;

	-- synchronized input signals
	signal r_cs_sync: std_logic;
	signal r_sclk_sync: std_logic;
	signal r_mosi_sync: std_logic;

	signal r_button_0_sync : std_logic;
	signal r_button_1_sync : std_logic;
	signal r_button_2_sync : std_logic;
	signal r_button_3_sync : std_logic;

	-- SPI interface (master)
	signal r_m0_wb_dat_miso: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_m0_wb_dat_mosi: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_m0_wb_adr: std_logic_vector (c_M0_WB_ADDRESS_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_M0_WB_ADDRESS_BUS_WITDH));
	signal r_m0_wb_ack: std_logic := '0';
	signal r_m0_wb_cyc: std_logic := '0';
	signal r_m0_wb_stb: std_logic := '0';
	signal r_m0_wb_err: std_logic := '0';
	signal r_m0_wb_we: std_logic := '0';

	-- BUTTON_INPUT_INSTANCE (slave 0)
	signal r_s0_wb_dat_miso: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_s0_wb_dat_mosi: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_s0_wb_adr: std_logic_vector (c_S0_WB_ADDRESS_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_S0_WB_ADDRESS_BUS_WITDH));
	signal r_s0_wb_ack: std_logic := '0';
	signal r_s0_wb_cyc: std_logic := '0';
	signal r_s0_wb_stb: std_logic := '0';
	signal r_s0_wb_err: std_logic := '0';
	signal r_s0_wb_we: std_logic := '0';

	-- LED_OUTPUT_INSTANCE (slave 1)
	signal r_s1_wb_dat_miso: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_s1_wb_dat_mosi: std_logic_vector (c_WB_DATA_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_WB_DATA_BUS_WITDH));
	signal r_s1_wb_adr: std_logic_vector (c_S1_WB_ADDRESS_BUS_WITDH - 1 downto 0) := std_logic_vector(to_unsigned(0, c_S1_WB_ADDRESS_BUS_WITDH));
	signal r_s1_wb_ack: std_logic := '0';
	signal r_s1_wb_cyc: std_logic := '0';
	signal r_s1_wb_stb: std_logic := '0';
	signal r_s1_wb_err: std_logic := '0';
	signal r_s1_wb_we: std_logic := '0';

	-- Synchronizer for asynchronous inputs
	component asynchronous_input_synchronizer is
		port (
			i_clock: in std_logic;

			-- unsynchronized inputs
			-- SPI interface
			i_cs: in std_logic;
			i_sclk: in std_logic;
			i_mosi: in std_logic;

			-- buttons
			i_button_0: in std_logic;
			i_button_1: in std_logic;
			i_button_2: in std_logic;
			i_button_3: in std_logic;

			-- synchronized outputs
			-- SPI interface
			o_cs: out std_logic;
			o_sclk: out std_logic;
			o_mosi: out std_logic;

			-- buttons
			o_button_0: out std_logic;
			o_button_1: out std_logic;
			o_button_2: out std_logic;
			o_button_3: out std_logic
		);
	end component asynchronous_input_synchronizer;

	-- PLL
	component pll is
		port (
			CLK: in std_logic;
			CLKOP: out std_logic;
			LOCK: out std_logic
		);
	end component pll;

	-- reset and clock control
	component reset_and_clock_control is
		port (
			-- inputs from external pins
			i_osci_clk : in std_logic;
			i_reset : in std_logic; -- low active

			-- interface to the PLL
			i_pll_lock: in std_logic; -- high active

			-- outputs
			o_reset: out std_logic; -- high active
			o_osci_enable: out std_logic
		);
	end component reset_and_clock_control;

	-- SPI interface
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
			i_wb_clk : in std_logic; -- For simplicity this module also uses the WISHBONE clock for it's internal logic
			o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
			o_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WITDH - 1 downto 0);
			i_wb_ack : in std_logic;
			o_wb_cyc : out std_logic;
			o_wb_stb : out std_logic;
			i_wb_err : in std_logic;
			o_wb_we : out std_logic
		);
	end component spi_interface;

	-- Intercon
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

	-- button input
	component button_input is
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

			-- button inputs
			i_button_0 : in std_logic;
			i_button_1 : in std_logic;
			i_button_2 : in std_logic;
			i_button_3 : in std_logic
		);
	end component button_input;

	-- LED output
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

	ASYNCHRONOUS_INPUT_SYNCHRONIZER_INSTANCE : asynchronous_input_synchronizer
		port map (
			i_clock => r_sys_clk,

			-- unsynchronized inputs
			-- SPI interface
			i_cs => i_cs,
			i_sclk => i_sclk,
			i_mosi => i_mosi,

			-- buttons
			i_button_0 => i_button_0,
			i_button_1 => i_button_1,
			i_button_2 => i_button_2,
			i_button_3 => i_button_3,

			-- synchronized outputs
			-- SPI interface
			o_cs => r_cs_sync,
			o_sclk => r_sclk_sync,
			o_mosi => r_mosi_sync,

			-- buttons
			o_button_0 => r_button_0_sync,
			o_button_1 => r_button_1_sync,
			o_button_2 => r_button_2_sync,
			o_button_3 => r_button_3_sync
		);

	PLL_INSTANCE : pll
		port map (
			CLK => i_osci_clock,
			CLKOP => r_sys_clk,
			LOCK => r_pll_lock
		);

	RESET_AND_CLOCK_CONTROL_INSTANCE : reset_and_clock_control
		port map (
			-- inputs from external pins
			i_osci_clk => i_osci_clock,
			i_reset => i_reset,

			-- interface to the PLL
			i_pll_lock => r_pll_lock,

			-- outputs
			o_reset => r_reset,
			o_osci_enable => o_osci_enable
		);

	SPI_INTERFACE_INSTANCE : spi_interface
		port map (
			-- spi interface
			i_cs => r_cs_sync,
			i_sclk => r_sclk_sync,
			i_mosi => r_mosi_sync,
			o_miso => o_miso,

			-- wishbone interface
			i_wb_rst => r_reset,
			i_wb_clk => r_sys_clk,
			o_wb_dat => r_m0_wb_dat_mosi,
			i_wb_dat => r_m0_wb_dat_miso,
			o_wb_adr => r_m0_wb_adr,
			i_wb_ack => r_m0_wb_ack,
			o_wb_cyc => r_m0_wb_cyc,
			o_wb_stb => r_m0_wb_stb,
			i_wb_err => r_m0_wb_err,
			o_wb_we => r_m0_wb_we
		);

	-- Intercon
	INTERCON_INSTANCE : intercon
		port map (
			-- shared signals
			i_wb_rst => r_reset,
			i_wb_clk => r_sys_clk,

			-- master interface (wishbown slave)
			i_m0_wb_dat => r_m0_wb_dat_mosi,
			o_m0_wb_dat => r_m0_wb_dat_miso,
			i_m0_wb_adr => r_m0_wb_adr,
			o_m0_wb_ack => r_m0_wb_ack,
			i_m0_wb_cyc => r_m0_wb_cyc,
			i_m0_wb_stb => r_m0_wb_stb,
			o_m0_wb_err => r_m0_wb_err,
			i_m0_wb_we => r_m0_wb_we,

			-- slave 0 interface (wishbown master)
			o_s0_wb_dat => r_s0_wb_dat_mosi,
			i_s0_wb_dat => r_s0_wb_dat_miso,
			o_s0_wb_adr => r_s0_wb_adr,
			i_s0_wb_ack => r_s0_wb_ack,
			o_s0_wb_cyc => r_s0_wb_cyc,
			o_s0_wb_stb => r_s0_wb_stb,
			i_s0_wb_err => r_s0_wb_err,
			o_s0_wb_we => r_s0_wb_we,

			-- slave 1 interface (wishbown master)
			o_s1_wb_dat => r_s1_wb_dat_mosi,
			i_s1_wb_dat => r_s1_wb_dat_miso,
			o_s1_wb_adr => r_s1_wb_adr,
			i_s1_wb_ack => r_s1_wb_ack,
			o_s1_wb_cyc => r_s1_wb_cyc,
			o_s1_wb_stb => r_s1_wb_stb,
			i_s1_wb_err => r_s1_wb_err,
			o_s1_wb_we => r_s1_wb_we
		);

	-- button input
	BUTTON_INPUT_INSTANCE : button_input
		port map (
			-- shared signals
			i_wb_rst => r_reset,
			i_wb_clk => r_sys_clk,

			-- wishbone interface (slave)
			i_wb_dat => r_s0_wb_dat_mosi,
			o_wb_dat => r_s0_wb_dat_miso,
			i_wb_adr => r_s0_wb_adr,
			o_wb_ack => r_s0_wb_ack,
			i_wb_cyc => r_s0_wb_cyc,
			i_wb_stb => r_s0_wb_stb,
			o_wb_err => r_s0_wb_err,
			i_wb_we => r_s0_wb_we,

			-- button_inputs
			i_button_0 => r_button_0_sync,
			i_button_1 => r_button_1_sync,
			i_button_2 => r_button_2_sync,
			i_button_3 => r_button_3_sync
		);

	-- LED output
	LED_OUTPUT_INSTANCE : led_output
		port map (
			-- shared signals
			i_wb_rst => r_reset,
			i_wb_clk => r_sys_clk,

			-- wishbone interface (slave)
			i_wb_dat => r_s1_wb_dat_mosi,
			o_wb_dat => r_s1_wb_dat_miso,
			i_wb_adr => r_s1_wb_adr,
			o_wb_ack => r_s1_wb_ack,
			i_wb_cyc => r_s1_wb_cyc,
			i_wb_stb => r_s1_wb_stb,
			o_wb_err => r_s1_wb_err,
			i_wb_we => r_s1_wb_we,

			-- LED outputs
			o_led_0 => o_led_0,
			o_led_1 => o_led_1,
			o_led_2 => o_led_2,
			o_led_3 => o_led_3,
			o_led_4 => o_led_4,
			o_led_5 => o_led_5,
			o_led_6 => o_led_6,
			o_led_7 => o_led_7
		);
end rtl;
