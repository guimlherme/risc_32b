library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity reg is
	port(
			w_enable :  in std_logic;
			clk		:	in std_logic;
			SW :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0); -- board switches
			Address_w	:	in std_logic_vector(4 downto 0);
			Address_r_1 :  in std_logic_vector(4 downto 0); --address of rs1
			Address_r_2 :  in std_logic_vector(4 downto 0); --address of rs2
			Data_in_mem	:	in std_logic_vector(31 downto 0);
			Data_out_1:	out std_logic_vector(31 downto 0); -- value rs1 in ALU
			Data_out_2:	out std_logic_vector(31 downto 0); -- value rs2 in ALU
			Display_out: out std_logic_vector(15 downto 0) -- goes to the display
	);
end reg;

architecture reg_arch of reg is


type reg is array(0 to 31) of std_logic_vector(31 downto 0);

signal Data_reg : reg := (others => (others => '0')) ;
signal Address_w_int : integer ;

--------------- BEGIN -----------------------------------------------------------------
begin

Address_w_int <= to_integer(unsigned(Address_w)) ;

Display_out <= Data_reg(1)(15 downto 0);

	acces_reg:process(clk)
		begin
		if rising_edge(clk) then
			if w_enable='1' then
				if Address_w_int = 0 then -- x0 is hard wired to zero;
					Data_reg(0) <= x"00000000";
				else
					Data_reg(Address_w_int) <= Data_in_mem;
				end if;
			end if;
			-- Data_reg(XXXXXX) <= SW(8 downto 1);
		end if;
		
	end process acces_reg;

	Data_out_1 <= Data_reg(to_integer(unsigned(Address_r_1)));
	Data_out_2 <= Data_reg(to_integer(unsigned(Address_r_2)));
	
end reg_arch;
