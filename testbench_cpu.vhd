library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity testbench  is
end testbench;

architecture testbench_cpu of testbench is

signal clk	: std_logic := '1' ; -- system clock
signal reset	: std_logic := '1' ; -- reset signal
signal enable	: std_logic := '1' ; -- enable signal


begin

    -- clock control
    clk <= not clk after 10 ps;

    -- CPU instantiation 
    UUT : entity work.CPU port map(CLK => clk,
    RESET => reset,
    SW => (others => '0'));     

    process
    begin

    reset <= '1';
    wait until rising_edge(clk);
    reset <= '1';
    enable <= '0';
    wait until rising_edge(clk);

    reset <= '0';
    enable <= '1';

    wait for 1 hr;
    end process ;
end testbench_cpu;

