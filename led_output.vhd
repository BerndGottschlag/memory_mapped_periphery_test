library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity led_output is
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
end;

architecture rtl of led_output is
	constant c_REGISTER_SIZE_IN_BITS : integer := 8;

	-- TODO: register write masks to avoid setting unused masks during a write access

	constant r_led_state_register_0_address : integer := 0;
	constant r_led_state_register_1_address : integer := 1;
	constant r_led_state_register_2_address : integer := 2;
	constant r_led_state_register_3_address : integer := 3;
	constant r_led_state_register_4_address : integer := 4;
	constant r_led_state_register_5_address : integer := 5;
	constant r_led_state_register_6_address : integer := 6;
	constant r_led_state_register_7_address : integer := 7;
	type t_Registers is array (0 to r_led_state_register_7_address) of std_logic_vector(c_REGISTER_SIZE_IN_BITS - 1 downto 0);

	signal r_registers : t_Registers := (others => std_logic_vector(to_unsigned(0, c_REGISTER_SIZE_IN_BITS)));

	signal r_termination_signaled : std_logic := '0';

	procedure p_RESET_WB_INTERFACE (
		signal o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WITDH - 1 downto 0);
		signal o_wb_ack : out std_logic;
		signal o_wb_err : out std_logic
	) is
	begin
		o_wb_dat <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WITDH));
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

				-- reset LED outputs
				o_led_0 <= '1';
				o_led_1 <= '1';
				o_led_2 <= '1';
				o_led_3 <= '1';
				o_led_4 <= '1';
				o_led_5 <= '1';
				o_led_6 <= '1';
				o_led_7 <= '1';
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

				-- set LED outputs according to state registers
				-- TODO set this outside of the clock?
				o_led_0 <= NOT(r_registers(r_led_state_register_0_address)(0));
				o_led_1 <= NOT(r_registers(r_led_state_register_1_address)(0));
				o_led_2 <= NOT(r_registers(r_led_state_register_2_address)(0));
				o_led_3 <= NOT(r_registers(r_led_state_register_3_address)(0));
				o_led_4 <= NOT(r_registers(r_led_state_register_4_address)(0));
				o_led_5 <= NOT(r_registers(r_led_state_register_5_address)(0));
				o_led_6 <= NOT(r_registers(r_led_state_register_6_address)(0));
				o_led_7 <= NOT(r_registers(r_led_state_register_7_address)(0));
			end if;
		end if;
	end process p_CONTROL;
end rtl;
