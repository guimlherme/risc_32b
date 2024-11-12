library ieee;

use IEEE.STD_LOGIC_1164.ALL;
Use ieee.numeric_std.all ;
use std.textio.all;


entity memory is
	generic(
		mem_size : in natural;
		mem_file : in string := "output.txt"
	);
	port(
			rw,en		:	in std_logic;
			clk		:	in std_logic;
			Address	:	in natural;
			Data_in	:	in std_logic_vector(31 downto 0);
			Data_out:	out std_logic_vector(31 downto 0);

			accelerator_addr1 : in std_logic_vector(31 downto 0);
			accelerator_data1 : out std_logic_vector(31 downto 0);
			accelerator_addr2 : in std_logic_vector(31 downto 0);
			accelerator_data2 : out std_logic_vector(31 downto 0);
			accelerator_addr3 : in std_logic_vector(31 downto 0);
			accelerator_data3 : out std_logic_vector(31 downto 0);
			accelerator_addr4 : in std_logic_vector(31 downto 0);
			accelerator_data4 : out std_logic_vector(31 downto 0);

			accelerator_write  : in std_logic;
			accelerator_addrin : in std_logic_vector(31 downto 0);
			accelerator_datain : in std_logic_vector(31 downto 0)
	);
end memory;

architecture memory_a of memory is

type ram is array(0 to mem_size-1) of std_logic_vector(31 downto 0);

impure function InitRamFromFile(RamFileName : in string) return ram is
	FILE RamFile : text is RamFileName;
	variable RamFileLine : line;
	variable RAM : ram := (others => (others => 'X'));
	variable temp_bitvector : BIT_VECTOR(31 downto 0);
	begin
	for i in ram'range loop
		if endfile(RamFile) then
			return RAM;
		end if;
		readline(RamFile, RamFileLine);
		if RamFileLine'length=0 then
			return RAM;
		end if;
		read(RamFileLine, temp_bitvector);
		RAM(i) := To_StdLogicVector(temp_bitvector);
	end loop;
	return RAM;
end function;

signal Data_Ram : ram := InitRamFromFile(mem_file);
signal Address_4bytes : natural;

--------------- BEGIN -----------------------------------------------------------------
begin

Address_4bytes <= Address / 4;

accelerator_data1 <= Data_Ram(to_integer(unsigned(accelerator_addr1))/4);
accelerator_data2 <= Data_Ram(to_integer(unsigned(accelerator_addr2))/4);
accelerator_data3 <= Data_Ram(to_integer(unsigned(accelerator_addr3))/4);
accelerator_data4 <= Data_Ram(to_integer(unsigned(accelerator_addr4))/4);

-- rw='1' means write
	acces_ram:process(clk)
		begin
		if rising_edge(clk) then
			if accelerator_write='1' then
				Data_Ram(to_integer(unsigned(accelerator_addrin))/4) <= accelerator_datain;
			end if;
			if en='1' then
				if rw='1' then
					Data_Ram(Address_4bytes) <= Data_in;
				end if;
            	Data_out <= Data_Ram(Address_4bytes);
			end if;
        end if;
		
	end process acces_ram;

end memory_a;
