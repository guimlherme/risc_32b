library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    port (
        clk	:	in std_logic;
		reset : in std_logic;
		decoder_stall : in std_logic;
		decoder_flush : in std_logic;
		  
        instruction: in std_logic_vector(31 downto 0);
		
		reg_write_flag: out std_logic;
		reg_write_address: out std_logic_vector(4 downto 0);
		
		alu_reg_in1: out std_logic_vector(4 downto 0);
		alu_reg_in2: out std_logic_vector(4 downto 0);
		alu_immediate_in: out std_logic_vector(31 downto 0);
		alu_op: out std_logic_vector(6 downto 0);
		alu_funct3: out std_logic_vector(2 downto 0);
		alu_funct7: out std_logic_vector(6 downto 0);

		decoder_pc: in std_logic_vector(31 downto 0);
		alu_pc: out std_logic_vector(31 downto 0)
    );
end decoder;

architecture decoder_a of decoder is

constant NOP_instruction : std_logic_vector(31 downto 0) := "00000000000000000000000000010011";

signal opcode: std_logic_vector(6 downto 0);
signal reg_dest: std_logic_vector(4 downto 0);

signal funct3: std_logic_vector(2 downto 0);
signal reg_in1: std_logic_vector(4 downto 0);
signal reg_in2: std_logic_vector(4 downto 0);
signal funct7: std_logic_vector(6 downto 0);

signal imm_sign: std_logic;
signal imm_10_5_isbj: std_logic_vector(5 downto 0);
signal imm_4_1_ij: std_logic_vector(3 downto 0);
signal imm_4_1_sb: std_logic_vector(3 downto 0);
signal imm_30_20_u: std_logic_vector(10 downto 0);
signal imm_19_12_uj: std_logic_vector(7 downto 0);


begin

	-- Decompose the entry into helper signals
	-- R-type
	opcode <= instruction(6 downto 0);
	reg_dest <= instruction(11 downto 7); -- rd
	funct3 <= instruction(14 downto 12);
	reg_in1 <= instruction(19 downto 15); -- rs1
	reg_in2 <= instruction(24 downto 20); -- rs2
	funct7 <= instruction(31 downto 25);

	-- Immediate
	imm_sign <= instruction(31);
	imm_10_5_isbj <= instruction(30 downto 25);
	imm_4_1_ij <= instruction(24 downto 21);
	imm_4_1_sb <= instruction(11 downto 8);
	imm_30_20_u <= instruction(30 downto 20);
	imm_19_12_uj <= instruction(19 downto 12);



	decode_reg:process(instruction, reg_in1, reg_in2)
	begin
		alu_reg_in1 <= reg_in1;
		alu_reg_in2 <= reg_in2;
	end process decode_reg;

	decode:process(clk, reset)
	begin
	
	if reset='1' then
		alu_op <= NOP_instruction(6 downto 0);
		reg_write_flag <= '0';
		reg_write_address <= NOP_instruction(11 downto 7);
	
	elsif rising_edge(clk) then
		if decoder_stall='0' and decoder_flush='0' then

			-- Default values
			alu_pc <= decoder_pc;

			reg_write_flag <= '0';
			reg_write_address <= reg_dest;

			alu_op <= opcode;
			alu_funct3 <= funct3;
			alu_funct7 <= funct7;

			-- Decode signals

			case opcode is
				when "0010011" => -- Operations with immediates
					reg_write_flag <= '1';
				
				when "0110111" => -- LUI
					reg_write_flag <= '1';
				
				when "0010111" => -- AUIPC
					reg_write_flag <= '1';

				when "0110011" => -- Operations with registers
					reg_write_flag <= '1';
					
				
				when "1101111" => -- JAL
					reg_write_flag <= '1';
				
				when "1100111" => -- JALR
					reg_write_flag <= '1';
				
				when "1100011" => -- branches
					reg_write_flag <= '0';
		
				when "0000011" => -- loads
					reg_write_flag <= '1'; -- Not the usual write
					--mem_enable_flag <= '1';
				
				when "0100011" => -- stores
					reg_write_flag <= '0';
					--mem_enable_flag <= '1';

				when others => NULL;
			end case;

			-- Reg x0 is read only
			if reg_dest = "00000" then
				reg_write_flag <= '0';
			end if;

			-- Decode immediate
			-- #TODO: optimize funct7 by encoding it here
			case opcode is
				when "1100111"|"0000011"|"0010011" => -- I-type
					alu_immediate_in(31 downto 11) <= (others => imm_sign);
					alu_immediate_in(10 downto 5) <= imm_10_5_isbj;
					alu_immediate_in(4 downto 1) <= imm_4_1_ij;
					alu_immediate_in(0) <= instruction(20);
				when "0100011" => -- S-type
					alu_immediate_in(31 downto 11) <= (others => imm_sign);
					alu_immediate_in(10 downto 5) <= imm_10_5_isbj;
					alu_immediate_in(4 downto 1) <= imm_4_1_sb;
					alu_immediate_in(0) <= instruction(7);
				when "1100011" => -- B-type
					alu_immediate_in(31 downto 12) <= (others => imm_sign);
					alu_immediate_in(11) <= instruction(7);
					alu_immediate_in(10 downto 5) <= imm_10_5_isbj;
					alu_immediate_in(4 downto 1) <= imm_4_1_sb;
					alu_immediate_in(0) <= '0';
				when "0110111"|"0010111" => -- U-type
					alu_immediate_in(31) <= imm_sign;
					alu_immediate_in(30 downto 20) <= imm_30_20_u;
					alu_immediate_in(19 downto 12) <= imm_19_12_uj;
					alu_immediate_in(11 downto 0) <= (others => '0');
				when "1101111" => -- J-type
					alu_immediate_in(31 downto 20) <= (others => imm_sign);
					alu_immediate_in(19 downto 12) <= imm_19_12_uj;
					alu_immediate_in(11) <= instruction(20);
					alu_immediate_in(10 downto 5) <= imm_10_5_isbj;
					alu_immediate_in(4 downto 1) <= imm_4_1_ij;
					alu_immediate_in(0) <= '0';
				when others => 
					alu_immediate_in <= (others => '-');
			end case;

		elsif decoder_flush='1' then
			alu_op <= NOP_instruction(6 downto 0);
			alu_immediate_in <= (others => '-');
			alu_funct3 <= (others => '-');
			alu_funct7 <= (others => '-');
			reg_write_flag <= '0';
			reg_write_address <= NOP_instruction(11 downto 7);
		end if;
	end if;


	end process decode;
	 
	 
end decoder_a;
