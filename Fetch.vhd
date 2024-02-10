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
			PC_jump_addr	:	in std_logic_vector(7 downto 0);
			PC_out	:	out std_logic_vector(7 downto 0)
			);
end Fetch;


architecture Fetch_a of Fetch is

signal PC_counter: std_logic_vector(7 downto 0);

Begin


Process (clk, reset)


begin

	
	if reset='1' then
		PC_counter<= (others=>'0');
	else
		If rising_edge(clk) then
			if en='1' and fetch_stall='0' and fetch_flush='0' then
				If PC_jump_flag='1' then
					PC_counter<=PC_jump_addr;
				else
					PC_counter<=std_logic_vector(unsigned(PC_counter)+1);
				end if;
			elsif fetch_flush='1' then
				-- empty for now

			end if;
			
		end if;
		
	end if;
	
end Process;


PC_out <= PC_counter;


end Architecture Fetch_a;

	
			
	