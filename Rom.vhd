library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity rom is
	port(
			en			:	in std_logic;
			clk		:	in std_logic;
			Address	:	in std_logic_vector(31 downto 0);
			Data_out:	out std_logic_vector(31 downto 0)
			);
end rom;

architecture rom_a of rom is

type rom is array(0 to 255) of std_logic_vector(31 downto 0);

signal Data_Rom : rom ;
signal Address_int : integer;
	


--------------- BEGIN -----------------------------------------------------------------
begin

Address_int <= to_integer(unsigned(Address));

-- Code here




	-- acces_rom:process(clk)
	-- 	begin
		
	-- 	if rising_edge(clk) then
	-- 		if en='1'then
				Data_out <= Data_Rom(Address_int+12) & Data_Rom(Address_int+8) &
							Data_Rom(Address_int+4) & Data_Rom(Address_int);
		-- 	end if;

		-- end if;	
		
	-- end process acces_rom;

end rom_a;
