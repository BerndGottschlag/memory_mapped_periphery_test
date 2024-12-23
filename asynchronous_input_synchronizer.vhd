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

entity asynchronous_input_synchronizer is
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
end asynchronous_input_synchronizer;

architecture rtl of asynchronous_input_synchronizer is
    -- SPI interface
	signal r_cs_temp: std_logic;
	signal r_sclk_temp: std_logic;
	signal r_mosi_temp: std_logic;

    -- buttons
	signal r_button_0_temp : std_logic;
	signal r_button_1_temp : std_logic;
	signal r_button_2_temp : std_logic;
	signal r_button_3_temp : std_logic;
begin
	p_CONTROL : process (i_clock) is

	procedure p_SYNCHRONIZE_SIGNAL (
        signal r_input: in std_logic;
        signal r_temp: inout std_logic;
        signal r_output: out std_logic
	) is
	begin
        r_temp <= r_input;
        r_output <= r_temp;
	end p_SYNCHRONIZE_SIGNAL;

	begin
		if rising_edge(i_clock) then
            -- SPI interface
            p_SYNCHRONIZE_SIGNAL(i_cs, r_cs_temp, o_cs);
            p_SYNCHRONIZE_SIGNAL(i_sclk, r_sclk_temp, o_sclk);
            p_SYNCHRONIZE_SIGNAL(i_mosi, r_mosi_temp, o_mosi);

            -- buttons
            p_SYNCHRONIZE_SIGNAL(i_button_0, r_button_0_temp, o_button_0);
            p_SYNCHRONIZE_SIGNAL(i_button_1, r_button_1_temp, o_button_1);
            p_SYNCHRONIZE_SIGNAL(i_button_2, r_button_2_temp, o_button_2);
            p_SYNCHRONIZE_SIGNAL(i_button_3, r_button_3_temp, o_button_3);
        end if;
	end process p_CONTROL;
end rtl;
