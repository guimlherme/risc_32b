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


Data_Rom(0) <= "00010011";
Data_Rom(1) <= "00000000";
Data_Rom(2) <= "00000000";
Data_Rom(3) <= "00000000";
Data_Rom(4) <= "00010011";
Data_Rom(5) <= "00000000";
Data_Rom(6) <= "00000000";
Data_Rom(7) <= "00000000";
Data_Rom(8) <= "00010011";
Data_Rom(9) <= "00000001";
Data_Rom(10) <= "00000000";
Data_Rom(11) <= "01111101";
Data_Rom(12) <= "11101111";
Data_Rom(13) <= "00000000";
Data_Rom(14) <= "10000000";
Data_Rom(15) <= "00000001";
Data_Rom(16) <= "00010011";
Data_Rom(17) <= "00000000";
Data_Rom(18) <= "00000000";
Data_Rom(19) <= "00000000";
Data_Rom(20) <= "00010011";
Data_Rom(21) <= "00000000";
Data_Rom(22) <= "00000000";
Data_Rom(23) <= "00000000";
Data_Rom(24) <= "00010011";
Data_Rom(25) <= "00000000";
Data_Rom(26) <= "00000000";
Data_Rom(27) <= "00000000";
Data_Rom(28) <= "00010011";
Data_Rom(29) <= "00000000";
Data_Rom(30) <= "00000000";
Data_Rom(31) <= "00000000";
Data_Rom(32) <= "11101111";
Data_Rom(33) <= "11110000";
Data_Rom(34) <= "01011111";
Data_Rom(35) <= "11111111";
Data_Rom(36) <= "00010011";
Data_Rom(37) <= "00000000";
Data_Rom(38) <= "00000000";
Data_Rom(39) <= "00000000";
Data_Rom(40) <= "00010011";
Data_Rom(41) <= "00000001";
Data_Rom(42) <= "11000001";
Data_Rom(43) <= "11111111";
Data_Rom(44) <= "00100011";
Data_Rom(45) <= "00100000";
Data_Rom(46) <= "00010001";
Data_Rom(47) <= "00000000";
Data_Rom(48) <= "00010011";
Data_Rom(49) <= "00000001";
Data_Rom(50) <= "00000001";
Data_Rom(51) <= "00000000";
Data_Rom(52) <= "00010111";
Data_Rom(53) <= "00000011";
Data_Rom(54) <= "00000000";
Data_Rom(55) <= "00000000";
Data_Rom(56) <= "00010011";
Data_Rom(57) <= "00000011";
Data_Rom(58) <= "10000011";
Data_Rom(59) <= "00000000";
Data_Rom(60) <= "00000011";
Data_Rom(61) <= "00101110";
Data_Rom(62) <= "00000011";
Data_Rom(63) <= "00000100";
Data_Rom(64) <= "00010011";
Data_Rom(65) <= "00000011";
Data_Rom(66) <= "01010000";
Data_Rom(67) <= "00000000";
Data_Rom(68) <= "10010111";
Data_Rom(69) <= "00000010";
Data_Rom(70) <= "00000000";
Data_Rom(71) <= "00000000";
Data_Rom(72) <= "10010011";
Data_Rom(73) <= "10000010";
Data_Rom(74) <= "10000010";
Data_Rom(75) <= "00000000";
Data_Rom(76) <= "00100011";
Data_Rom(77) <= "10101000";
Data_Rom(78) <= "01100010";
Data_Rom(79) <= "00000010";
Data_Rom(80) <= "10010111";
Data_Rom(81) <= "00000010";
Data_Rom(82) <= "00000000";
Data_Rom(83) <= "00000000";
Data_Rom(84) <= "10010011";
Data_Rom(85) <= "10000010";
Data_Rom(86) <= "10000010";
Data_Rom(87) <= "00000000";
Data_Rom(88) <= "10000011";
Data_Rom(89) <= "10100011";
Data_Rom(90) <= "01000010";
Data_Rom(91) <= "00000010";
Data_Rom(92) <= "00010011";
Data_Rom(93) <= "00000011";
Data_Rom(94) <= "00010000";
Data_Rom(95) <= "00000000";
Data_Rom(96) <= "10110011";
Data_Rom(97) <= "00000010";
Data_Rom(98) <= "01110011";
Data_Rom(99) <= "00000000";
Data_Rom(100) <= "00010011";
Data_Rom(101) <= "10000101";
Data_Rom(102) <= "00000010";
Data_Rom(103) <= "00000000";
Data_Rom(104) <= "11101111";
Data_Rom(105) <= "00000000";
Data_Rom(106) <= "01000000";
Data_Rom(107) <= "00000000";
Data_Rom(108) <= "00010011";
Data_Rom(109) <= "00000000";
Data_Rom(110) <= "00000000";
Data_Rom(111) <= "00000000";
Data_Rom(112) <= "10000011";
Data_Rom(113) <= "00100000";
Data_Rom(114) <= "00000001";
Data_Rom(115) <= "00000000";
Data_Rom(116) <= "00010011";
Data_Rom(117) <= "00000001";
Data_Rom(118) <= "10000001";
Data_Rom(119) <= "00000000";
Data_Rom(120) <= "11100111";
Data_Rom(121) <= "10000000";
Data_Rom(122) <= "00000000";
Data_Rom(123) <= "00000000";







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
