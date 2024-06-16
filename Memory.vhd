library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity memory is
	port(
			rw,en		:	in std_logic;
			clk		:	in std_logic;
			Address	:	in integer range 0 to 4046;
			Data_in	:	in std_logic_vector(31 downto 0);
			Data_out:	out std_logic_vector(31 downto 0)
			);
end memory;

architecture memory_a of memory is

type ram is array(0 to 4096) of std_logic_vector(31 downto 0);

signal Data_Ram : ram ;

--------------- BEGIN -----------------------------------------------------------------
begin

-- rw='1' means write
	acces_ram:process(clk)
		begin
		if rising_edge(clk) then
			if en='1' then
				if rw='1' then
					Data_Ram(Address) <= Data_in;
				end if;
            	Data_out <= Data_Ram(Address);
			end if;
        end if;
		
	end process acces_ram;

end memory_a;
