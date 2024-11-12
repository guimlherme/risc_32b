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
signal PC_counter_next_natural: natural;
signal instruction_fetched: std_logic_vector(31 downto 0);
signal last_data_flush: std_logic := '0';
signal last_data_stall: std_logic := '0';
signal last_instruction: std_logic_vector(31 downto 0);

Begin

PC_counter_plus_4 <= std_logic_vector(unsigned(PC_counter)+4);
PC_counter_next_natural <= to_integer(unsigned(PC_counter_next));

process(PC_jump_flag, PC_jump_addr, PC_counter_plus_4)
begin
	If PC_jump_flag='1' then
		PC_counter_next <= PC_jump_addr;
	else
		PC_counter_next <= PC_counter_plus_4;
	end if;
end process;

rom_inst: entity work.memory
 generic map(
	mem_size => 65536
)
 port map(
	rw => '0',
	en => en,
	clk => clk,
	Address => PC_counter_next_natural,
	Data_in => (others => '0'),
	Data_out => instruction_fetched,

	accelerator_addr1 => (others => '0'),
	accelerator_data1 => open,
	accelerator_addr2 => (others => '0'),
	accelerator_data2 => open,
	accelerator_addr3 => (others => '0'),
	accelerator_data3 => open,
	accelerator_addr4 => (others => '0'),
	accelerator_data4 => open,
	accelerator_write  => '0',
	accelerator_addrin => (others => '0'),
	accelerator_datain => (others => '0')
);

Process (clk, reset)

begin
	
	if reset='1' then
		PC_counter <= (others=>'0');
		last_data_flush <= '0';
	else
		If rising_edge(clk) then
			if en='1' and fetch_stall='0' and fetch_flush='0' then
				PC_counter <= PC_counter_next;
			end if;

			if last_data_stall='0' and fetch_stall='1' then
				last_instruction <= instruction_fetched;
			end if;
			
			last_data_flush <= fetch_flush;
			last_data_stall <= fetch_stall;

		end if;
		
	end if;
	
end Process;

process(PC_counter, instruction_fetched, last_data_stall, last_data_flush, last_instruction, reset)
begin
	PC_out <= PC_counter;
	if reset='1' then
		Data_out <= NOP_instruction;
	elsif last_data_flush='1' then
		Data_out <= NOP_instruction;
	elsif last_data_stall='1' then
		Data_out <= last_instruction;
	else 
		Data_out <= instruction_fetched;
	end if;
end process;

end Architecture Fetch_a;

	
			
	