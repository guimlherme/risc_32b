library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;
use std.standard.all ;


entity rom is
	port(
			en			:	in std_logic;
			clk		:	in std_logic;
			Address	:	in std_logic_vector(31 downto 0);
			Data_out:	out std_logic_vector(31 downto 0)
			);
end rom;

architecture rom_a of rom is

type rom is array(0 to 4096) of std_logic_vector(7 downto 0);

signal Data_Rom : rom ;
signal Address_int : integer;
	


--------------- BEGIN -----------------------------------------------------------------
begin

Address_int <= to_integer(unsigned(Address(11 downto 0)));

-- Code here

Data_Rom(0) <= "10010011";
Data_Rom(1) <= "00000000";
Data_Rom(2) <= "00000000";
Data_Rom(3) <= "00000001";
Data_Rom(4) <= "00010011";
Data_Rom(5) <= "00000001";
Data_Rom(6) <= "00000000";
Data_Rom(7) <= "00000000";
Data_Rom(8) <= "10110011";
Data_Rom(9) <= "10000001";
Data_Rom(10) <= "00100000";
Data_Rom(11) <= "00000000";
Data_Rom(12) <= "10010011";
Data_Rom(13) <= "10000001";
Data_Rom(14) <= "00000000";
Data_Rom(15) <= "00000000";
Data_Rom(16) <= "10010011";
Data_Rom(17) <= "10000001";
Data_Rom(18) <= "00000000";
Data_Rom(19) <= "00000000";
Data_Rom(20) <= "10010011";
Data_Rom(21) <= "10000001";
Data_Rom(22) <= "00000000";
Data_Rom(23) <= "00000000";
Data_Rom(24) <= "10010011";
Data_Rom(25) <= "10000001";
Data_Rom(26) <= "00000000";
Data_Rom(27) <= "00000000";
Data_Rom(28) <= "10010011";
Data_Rom(29) <= "10000001";
Data_Rom(30) <= "00000000";
Data_Rom(31) <= "00000000";
Data_Rom(32) <= "01101111";
Data_Rom(33) <= "11110000";
Data_Rom(34) <= "01011111";
Data_Rom(35) <= "11111111";
Data_Rom(36) <= "10010011";
Data_Rom(37) <= "10000001";
Data_Rom(38) <= "00000000";
Data_Rom(39) <= "00000000";





	acces_rom:process(clk)
		begin
		
		if rising_edge(clk) then
			if en='1'then
				Data_out <= Data_Rom(Address_int+3) & Data_Rom(Address_int+2) &
							Data_Rom(Address_int+1) & Data_Rom(Address_int);
			end if;

		end if;	
		
	end process acces_rom;

end rom_a;
