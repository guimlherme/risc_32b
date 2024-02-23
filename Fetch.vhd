library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity Fetch is
	port(
			en			:	in std_logic;
			clk		:	in std_logic;
			reset		:	in std_logic;
			fetch_stall : in std_logic;
			fetch_flush : in std_logic;
			PC_jump_flag	:	in std_logic;
			PC_jump_addr	:	in std_logic_vector(31 downto 0);
			PC_out	:	out std_logic_vector(31 downto 0);
			Data_out:	out std_logic_vector(31 downto 0)
			);
end Fetch;


architecture Fetch_a of Fetch is

constant NOP_instruction : std_logic_vector(31 downto 0) := "00000000000000000000000000010011";

signal PC_counter: std_logic_vector(31 downto 0) :=  (others=>'0');
signal PC_counter_plus_4: std_logic_vector(31 downto 0);
signal PC_counter_next: std_logic_vector(31 downto 0);
signal instruction_fetched: std_logic_vector(31 downto 0);
signal next_data_flush: std_logic := '0';
signal next_data_stall: std_logic := '0';
signal last_instruction: std_logic_vector(31 downto 0);

Begin

PC_counter_plus_4 <= std_logic_vector(unsigned(PC_counter)+4);

process(PC_jump_flag, PC_jump_addr, PC_counter_plus_4)
begin
	If PC_jump_flag='1' then
		PC_counter_next <= PC_jump_addr;
	else
		PC_counter_next <= PC_counter_plus_4;
	end if;
end process;

rom_inst:	entity work.rom 
PORT MAP
			(en	=> en,
			clk => clk,
			Address => PC_counter_next,
			Data_out => instruction_fetched);

Process (clk, reset)

begin
	
	if reset='1' then
		PC_counter <= (others=>'0');
		next_data_flush <= '0';
	else
		If rising_edge(clk) then
			if en='1' and fetch_stall='0' and fetch_flush='0' then
				PC_counter <= PC_counter_next;
			end if;
			
			next_data_flush <= fetch_flush;
			next_data_stall <= fetch_stall;
			last_instruction <= instruction_fetched;
		end if;
		
	end if;
	
end Process;

process(PC_counter, instruction_fetched, next_data_flush)
begin
	PC_out <= PC_counter;
	if reset='1' then
		Data_out <= NOP_instruction;
	elsif next_data_flush='1' then
		Data_out <= NOP_instruction;
	elsif next_data_stall='1' then
		Data_out <= last_instruction;
	else 
		Data_out <= instruction_fetched;
	end if;
end process;

end Architecture Fetch_a;

	
			
	