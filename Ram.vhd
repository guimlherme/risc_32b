library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;


entity ram is
	port(
			rw,en		:	in std_logic;
			clk		:	in std_logic;
			rst		:	in std_logic;
			stall   : in std_logic;
			funct3  :   in std_logic_vector(2 downto 0);
			Address	:	in std_logic_vector(31 downto 0);
			Data_in	:	in std_logic_vector(31 downto 0);
			Data_out_mem:	out std_logic_vector(31 downto 0);
			Data_out_alu:	out std_logic_vector(31 downto 0);
			mem_delayed :   out std_logic
			);
end ram;

architecture ram_a of ram is

type ram is array(0 to 4096) of std_logic_vector(7 downto 0);

signal Data_Ram : ram ;
signal Address_int : integer;



--------------- BEGIN -----------------------------------------------------------------
begin

Address_int <= to_integer(unsigned(Address(11 downto 0)));
mem_delayed <= '0'; -- this memory made of registers is instant

-- rw='1' alors lecture
	acces_ram:process(rst, clk)
		begin
		
		Data_out_alu <= Data_in;
		
		if rst='1' then
		
			for k in ram'range loop
				Data_Ram(k) <= (others=>'0');
			end loop;
		
		else
			if rising_edge(clk) then
				if en='1' and stall='0' then
					if(rw='1') then 
						Data_out_mem <= (others => '0');
						if funct3="000" then -- LB
							Data_out_mem(7 downto 0) <= Data_Ram(Address_int);
							Data_out_mem(31 downto 8) <= (others => Data_Ram(Address_int)(7));
						elsif funct3="001" then -- LH
							Data_out_mem(15 downto 0) <= Data_Ram(Address_int+1) & Data_Ram(Address_int);
							Data_out_mem(31 downto 16) <= (others => Data_Ram(Address_int+1)(7));
						elsif funct3="010" then -- LW
							Data_out_mem <= Data_Ram(Address_int+3) & Data_Ram(Address_int+2) &
							Data_Ram(Address_int+1) & Data_Ram(Address_int);
						elsif funct3="100" then -- LBU
							Data_out_mem(7 downto 0) <= Data_Ram(Address_int);
						elsif funct3="101" then -- LHU
							Data_out_mem(15 downto 0) <= Data_Ram(Address_int+1) & Data_Ram(Address_int);
						end if;
					else
						Data_Ram(Address_int+3) <= (others => '0');
						Data_Ram(Address_int+2) <= (others => '0');
						Data_Ram(Address_int+1) <= (others => '0');
						Data_Ram(Address_int)   <= (others => '0');
						if funct3="000" then -- SB
							Data_Ram(Address_int)   <= Data_in(7 downto 0);
						elsif funct3="001" then -- SH
							Data_Ram(Address_int+1) <= Data_in(15 downto 8);
							Data_Ram(Address_int)   <= Data_in(7 downto 0);
						elsif funct3="010" then -- SW
							Data_Ram(Address_int+3) <= Data_in(31 downto 24);
							Data_Ram(Address_int+2) <= Data_in(23 downto 16);
							Data_Ram(Address_int+1) <= Data_in(15 downto 8);
							Data_Ram(Address_int)   <= Data_in(7 downto 0);
						end if;
					end if;
				elsif en='0' and stall='0' then
					Data_out_mem <= Data_in;
				end if;
			end if;
		end if;
		
	end process acces_ram;

end ram_a;
