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
			Data_out:	out std_logic_vector(31 downto 0);
			reg_write_flag_int_alu : in std_logic;
			reg_write_flag_fp_alu : in std_logic;
			reg_write_flag_int_mem : out std_logic;
			reg_write_flag_fp_mem : out std_logic;
			reg_write_address_alu : in std_logic_vector(4 downto 0);
			reg_write_address_mem : out std_logic_vector(4 downto 0);
			mem_delayed :   out std_logic
			);
end ram;

architecture ram_a of ram is

-- signal Address_int : integer range 0 to 4095 := 0;
signal Address_int : natural;

signal last_rw, last_en, last_stall : std_logic;

signal last_funct3 : std_logic_vector(2 downto 0);

signal Data_out_sig : std_logic_vector(31 downto 0);
signal Data_mem_in, Data_mem_out : std_logic_vector(31 downto 0);
signal Data_in_last, Data_out_last : std_logic_vector(31 downto 0);

--------------- BEGIN -----------------------------------------------------------------
begin

-- Address_int <= to_integer(unsigned(Address(11 downto 0)));
Address_int <= to_integer(unsigned(Address));

mem_delayed <= '0'; -- this memory made of block mem always has latency one
Data_out <= Data_out_sig;

-- rw='1' means write
memory_inst: entity work.memory
 generic map(
	mem_size => 1048576
 )
 port map(
	rw => rw,
	en => en,
	clk => clk,
	Address => Address_int,
	Data_in => Data_mem_in,
	Data_out => Data_mem_out
	);

update_controls:process(clk)
begin
	if rising_edge(clk) then
		if stall='0' then
			reg_write_flag_int_mem <= reg_write_flag_int_alu;
			reg_write_flag_fp_mem <= reg_write_flag_fp_alu;
			reg_write_address_mem <= reg_write_address_alu;
			last_en <= en;
			last_rw <= rw;
			last_funct3 <= funct3;
			last_stall <= stall;
			Data_in_last <= Data_in;
			Data_out_last <= Data_out_sig;
		end if;
	end if;
end process;


parse_run_out:process(last_funct3, last_en, last_rw, Data_in_last, Data_mem_out)
begin
	if last_stall='0' then
		if last_en='0' then
			Data_out_sig <= Data_in_last;
		elsif (last_rw='0') then 
			Data_out_sig <= (others => '0'); -- Fill the unsigned bits
			if last_funct3="000" then -- LB
				Data_out_sig(7 downto 0) <= Data_mem_out(7 downto 0);
				Data_out_sig(31 downto 8) <= (others => Data_mem_out(7));
			elsif last_funct3="001" then -- LH
				Data_out_sig(15 downto 0) <= Data_mem_out(15 downto 0);
				Data_out_sig(31 downto 16) <= (others => Data_mem_out(15));
			elsif last_funct3="010" then -- LW
				Data_out_sig <= Data_mem_out;
			elsif last_funct3="100" then -- LBU
				Data_out_sig(7 downto 0) <= Data_mem_out(7 downto 0);
			elsif last_funct3="101" then -- LHU
				Data_out_sig(15 downto 0) <= Data_mem_out(15 downto 0);
			end if;
		else
			Data_out_sig <= (others => '-');
		end if;
	else
		Data_out_sig <= Data_out_last;
	end if;
end process parse_run_out;

acces_ram_in:process(funct3, rw, Data_in)
begin
	if (rw='1') then 
		Data_mem_in <= (others => '0');
		if funct3="000" then -- SB
			Data_mem_in(7 downto 0)   <= Data_in(7 downto 0);
		elsif funct3="001" then -- SH
			Data_mem_in(15 downto 0) <= Data_in(15 downto 0);
		elsif funct3="010" then -- SW
			Data_mem_in <= Data_in;
		end if;
	end if;
end process acces_ram_in;

end ram_a;
