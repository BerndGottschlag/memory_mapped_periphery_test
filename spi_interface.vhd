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


-- This SPI interface implement a SPI-slave using SPI mode 0 (CPOL=0, CPHA=0).
-- The packet format is the following:
-- 1 bit opcode (0 for reading, 1 for writing)
-- 15 bit address, msb first
-- n times 8 bits data, either received on MOSI or sent on MISO, msb first



-- This component implements a wishbone interface:
-- Revision Level of the WISHBONE specification: B4
-- General description: 8-bit MASTER port
-- Supported cycles: 
-- Data port, size: 8-bit
-- Data port, granularity: 8-bit
-- Data port, maximum operand size: 8-bit
-- Data transfer orderung: Big endian and/or little endian
-- Supported signal list and cross reference to equivalent WISHBONE signals:
-- | Signal Name | WISHBONE Equivalent |
-- | ----------- | ------------------- |
-- | i_wb_rst    | RST_I               |
-- | i_wb_clk    | CLK_I               |
-- | i_wb_dat()  | DAT_I()             |
-- | o_wb_dat()  | DAT_O()             |
-- | o_wb_adr()  | ADR_O()             |
-- | i_wb_ack    | ACK_I               |
-- | o_wb_cyc    | CYC_O               |
-- | o_wb_stb    | STB_O               |
-- | i_wb_err    | ERR_I               | TODO: currently unimplemented
-- | o_wb_we     | WE_I                |
--
--
--
--

entity spi_interface is
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
		i_wb_clk : in std_logic; -- For simplicity this module also uses the WISHBONE clock for it's internal logic
		o_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		i_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		o_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		i_wb_ack : in std_logic;
		o_wb_cyc : out std_logic;
		o_wb_stb : out std_logic;
		i_wb_err : in std_logic; -- TODO: currently unimplemented
		o_wb_we : out std_logic
	);
end;

architecture rtl of spi_interface is
	constant c_NUMBER_OF_ADDRESS_BITS: integer := 15;
	constant c_NUMBER_OF_DATA_BITS: integer := 8;

	type t_PACKET_PHASE is (OPCODE, ADDRESS, DATA);
	type t_OPERATION_TYPE is (READ_OPERATION, WRITE_OPERATION);

	signal r_sclk_last : std_logic := '0';

	signal r_PACKET_PHASE : t_PACKET_PHASE := OPCODE;

	signal r_OPERATION_TYPE : t_OPERATION_TYPE := READ_OPERATION;

	signal r_addressBitCounter : integer range 0 to c_NUMBER_OF_ADDRESS_BITS - 1 := c_NUMBER_OF_ADDRESS_BITS - 1;
	signal r_dataBitCounter : integer range 0 to c_NUMBER_OF_DATA_BITS - 1 := c_NUMBER_OF_DATA_BITS - 1;

	signal r_address : std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(0, g_WB_ADDRESS_BUS_WIDTH)) ;
	signal r_data : std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));
	signal r_perform_write : std_logic;
	signal r_perform_read : std_logic;
begin
	p_CONTROL : process (i_wb_clk) is

	-- TODO: put the following into a package
	procedure p_WISHBONE_SINGLE_WRITE (
		signal r_perform_write : inout std_logic;
		signal r_address : inout std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		signal r_data : in std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);

		signal r_wb_dat : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		signal r_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		signal r_wb_ack : in std_logic;
		signal r_wb_cyc : out std_logic;
		signal r_wb_stb : out std_logic;
		signal r_wb_err : in std_logic;
		signal r_wb_we : out std_logic
	) is
	begin
		if (r_perform_write = '1') then
			if (r_wb_ack = '0') then
				r_wb_dat <= r_data;
				r_wb_adr <= r_address;
				r_wb_cyc <= '1';
				r_wb_stb <= '1';
				r_wb_we <= '1';
			else
				r_wb_cyc <= '0';
				r_wb_stb <= '0';
				r_wb_we <= '0';
				r_wb_dat <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));
				r_wb_adr <= std_logic_vector(to_unsigned(0, g_WB_ADDRESS_BUS_WIDTH));

				r_perform_write <= '0';

				r_address <= std_logic_vector(unsigned(r_address) + 1); -- Increment address for next byte
			end if;
		end if;
	end p_WISHBONE_SINGLE_WRITE;

	procedure p_WISHBONE_SINGLE_READ (
		signal r_perform_read : inout std_logic;
		signal r_address : inout std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		signal r_data : out std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);

		signal r_wb_dat : in std_logic_vector (g_WB_DATA_BUS_WIDTH - 1 downto 0);
		signal r_wb_adr : out std_logic_vector (g_WB_ADDRESS_BUS_WIDTH - 1 downto 0);
		signal r_wb_ack : in std_logic;
		signal r_wb_cyc : out std_logic;
		signal r_wb_stb : out std_logic;
		signal r_wb_err : in std_logic;
		signal r_wb_we : out std_logic
	) is
	begin
		if (r_perform_read = '1') then
			if (r_wb_ack = '0') then
				r_wb_adr <= r_address;
				r_wb_cyc <= '1';
				r_wb_stb <= '1';
			elsif (r_wb_err = '1') then
				-- This can happen if a SPI transaction fetched the last byte in the address space of the WB slave
				r_wb_cyc <= '0';
				r_wb_stb <= '0';
				r_wb_we <= '0';
				r_data <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));

				r_perform_read <= '0';
			else
				r_data <= r_wb_dat;
				r_wb_cyc <= '0';
				r_wb_stb <= '0';
				r_wb_we <= '0';
				r_wb_adr <= std_logic_vector(to_unsigned(0, g_WB_ADDRESS_BUS_WIDTH));

				r_perform_read <= '0';

				r_address <= std_logic_vector(unsigned(r_address) + 1); -- Increment address for next byte
			end if;
		end if;
	end p_WISHBONE_SINGLE_READ;

	begin
		if rising_edge(i_wb_clk) then
			r_sclk_last <= i_sclk;
			if i_wb_rst = '1' then
				o_miso <= '0';

				r_PACKET_PHASE <= OPCODE;
				r_addressBitCounter <= c_NUMBER_OF_ADDRESS_BITS - 1;
				r_dataBitCounter <= c_NUMBER_OF_DATA_BITS - 1;

				r_address <= std_logic_vector(to_unsigned(0, g_WB_ADDRESS_BUS_WIDTH));
				r_data <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));

				r_OPERATION_TYPE <= READ_OPERATION;
				r_perform_write <= '0';
				r_perform_read <= '0';

				-- Reset Wishbone interface
				o_wb_dat <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));
				o_wb_adr <= std_logic_vector(to_unsigned(0, g_WB_ADDRESS_BUS_WIDTH));
				o_wb_cyc <= '0';
				o_wb_stb <= '0';
				o_wb_we <= '0';
			else
				if (i_cs = '1') then
					r_PACKET_PHASE <= OPCODE;
					r_addressBitCounter <= c_NUMBER_OF_ADDRESS_BITS - 1;
					r_dataBitCounter <= c_NUMBER_OF_DATA_BITS - 1;
					o_miso <= '0';

					r_OPERATION_TYPE <= READ_OPERATION;
					r_data <= std_logic_vector(to_unsigned(0, g_WB_DATA_BUS_WIDTH));
				else
					if (r_sclk_last = '0' and i_sclk = '1') then
						if (r_PACKET_PHASE = OPCODE) then
							if (i_mosi = '0') then
								r_OPERATION_TYPE <= READ_OPERATION;
							else
								r_OPERATION_TYPE <= WRITE_OPERATION;
							end if;
							r_PACKET_PHASE <= ADDRESS;
						elsif (r_PACKET_PHASE = ADDRESS) then
							r_address(r_addressBitCounter) <= i_mosi;
							if (r_addressBitCounter > 0) then
								r_addressBitCounter <= r_addressBitCounter - 1;
							else
								r_PACKET_PHASE <= DATA;
							end if;
							if (r_OPERATION_TYPE = READ_OPERATION) then
								-- The data can be fetched via Wishbone bus as soon as the last address bit was received
								if (r_addressBitCounter = 0) then
									r_perform_read <= '1';
								end if;
							end if;
						elsif (r_PACKET_PHASE = DATA) then
							if (r_OPERATION_TYPE = WRITE_OPERATION) then
								r_data(r_dataBitCounter) <= i_mosi;
								-- The data can be transferred via Wishbone bus as soon as the last data bit was received
								if (r_dataBitCounter = 0) then
									r_perform_write <= '1';
								end if;
							else
								o_miso <= r_data(r_dataBitCounter);
								-- Fetch the next byte in case more than one byte is transferred
								if (r_dataBitCounter = 0) then
									r_perform_read <= '1';
								end if;
							end if;
							if (r_dataBitCounter > 0) then
								r_dataBitCounter <= r_dataBitCounter - 1;
							else
								r_dataBitCounter <= c_NUMBER_OF_DATA_BITS - 1;
							end if;
						end if;
					end if;

					if (r_sclk_last = '1' and i_sclk = '0') then
						if (r_PACKET_PHASE = DATA) then
							if (r_OPERATION_TYPE = READ_OPERATION) then
								o_miso <= r_data(r_dataBitCounter);
							end if;
						end if;
					end if;
				end if;

				if (r_perform_write = '1') then
					p_WISHBONE_SINGLE_WRITE(
						r_perform_write,
						r_address,
						r_data,
						o_wb_dat,
						o_wb_adr,
						i_wb_ack,
						o_wb_cyc,
						o_wb_stb,
						i_wb_err,
						o_wb_we
					);
				end if;

				if (r_perform_read = '1') then
					p_WISHBONE_SINGLE_READ(
						r_perform_read,
						r_address,
						r_data,
						i_wb_dat,
						o_wb_adr,
						i_wb_ack,
						o_wb_cyc,
						o_wb_stb,
						i_wb_err,
						o_wb_we
					);
				end if;
			end if;
		end if;
	end process p_CONTROL;
end rtl;
