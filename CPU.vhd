LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

LIBRARY work;


-- Entity declaration

ENTITY CPU IS 
	PORT
	(
		CLK :  IN  STD_LOGIC; -- 50 MHz clock
		RESET : IN STD_LOGIC;
		SW :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		REG_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		-- HEX0 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- HEX1 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- HEX2 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- HEX3 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- HEX4 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- HEX5 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		-- LEDR :  OUT  STD_LOGIC_VECTOR(9 DOWNTO 0)
	);

END CPU;


ARCHITECTURE bdf_type OF CPU IS 

--Signal declarations

SIGNAL	fetch_enable : std_logic := '1';
SIGNAL	fetch_reset : std_logic := '1';

SIGNAL  fetch_stall : std_logic := '0';
SIGNAL  fetch_flush : std_logic := '0';
SIGNAL  decoder_stall : std_logic := '0';
SIGNAL  decoder_flush : std_logic := '0';
SIGNAL  alu_stall : std_logic := '0';
SIGNAL  alu_flush : std_logic := '0';
SIGNAL  memory_stall : std_logic := '0';
SIGNAL  mem_delayed : std_logic := '0';
--SIGNAL  memory_flush : std_logic := '0'; -- for future use

constant NOP_instruction : std_logic_vector(31 downto 0) := "00000000000000000000000000010011";
SIGNAL	instruction_address : std_logic_vector(31 downto 0) := x"00000000";
SIGNAL  instruction : std_logic_vector(31 downto 0) := NOP_instruction;


SIGNAL  jmp_flag_alu : std_logic;
SIGNAL  jmp_dest_alu :  std_logic_vector(31 downto 0);

SIGNAL	reg_write_flag_int_decoder : std_logic;
SIGNAL	reg_write_address_decoder : std_logic_vector(4 downto 0);
SIGNAL  reg_write_flag_fp_decoder : std_logic;
SIGNAL	reg_write_flag_int_alu : std_logic;
SIGNAL	reg_write_address_alu : std_logic_vector(4 downto 0);
SIGNAL  reg_write_flag_fp_alu : std_logic;
SIGNAL  reg_write_flag_int_mem : std_logic;
SIGNAL  reg_write_flag_fp_mem : std_logic;
SIGNAL  reg_write_address_mem : std_logic_vector(4 downto 0);

SIGNAL	alu_reg_in1 : std_logic_vector(4 downto 0);
SIGNAL	alu_reg_in2 : std_logic_vector(4 downto 0);
SIGNAL	alu_immediate_in: std_logic_vector(31 downto 0);
SIGNAL	alu_op: std_logic_vector(6 downto 0);
SIGNAL  alu_funct3: std_logic_vector(2 downto 0);
SIGNAL  alu_funct7: std_logic_vector(6 downto 0);
SIGNAL	alu_pc: std_logic_vector(31 downto 0);

SIGNAL	reg_data_out1 : std_logic_vector(31 downto 0);
SIGNAL	reg_data_out2 : std_logic_vector(31 downto 0);
SIGNAL	reg_data_out_fp1 : std_logic_vector(31 downto 0);
SIGNAL	reg_data_out_fp2 : std_logic_vector(31 downto 0);
SIGNAL	alu_result : std_logic_vector(31 downto 0);
SIGNAL	alu_zero : std_logic;

SIGNAL  mem_enable_flag_alu : std_logic;
SIGNAL  mem_address_alu : std_logic_vector(31 downto 0);
SIGNAL  mem_funct3_alu : std_logic_vector(2 downto 0);
SIGNAL  mem_mode_alu : std_logic;

SIGNAL  reg_data_in_mem : std_logic_vector(31 downto 0);

SIGNAL accelerator_en : std_logic;
SIGNAL accelerator_imm: std_logic_vector(31 downto 0);
SIGNAL accelerator_funct3: std_logic_vector(2 downto 0);

SIGNAL accelerator_addr1 : std_logic_vector(31 downto 0);
SIGNAL accelerator_data1 : std_logic_vector(31 downto 0);
SIGNAL accelerator_addr2 : std_logic_vector(31 downto 0);
SIGNAL accelerator_data2 : std_logic_vector(31 downto 0);
SIGNAL accelerator_addr3 : std_logic_vector(31 downto 0);
SIGNAL accelerator_data3 : std_logic_vector(31 downto 0);
SIGNAL accelerator_addr4 : std_logic_vector(31 downto 0);
SIGNAL accelerator_data4 : std_logic_vector(31 downto 0);
SIGNAL accelerator_write  : std_logic;
SIGNAL accelerator_addrin : std_logic_vector(31 downto 0);
SIGNAL accelerator_datain : std_logic_vector(31 downto 0);

SIGNAL	display_number: STD_LOGIC_VECTOR(15 downto 0);



BEGIN 

-- Reset signals

fetch_reset <= RESET;


-- Component instantiation inside the concurrent statements



pipeline_control_inst: entity work.pipeline_control
port map (
  mem_delayed     => mem_delayed,
  branching_hazard      => jmp_flag_alu,
  address_decoder_1 => alu_reg_in1,
  address_decoder_2 => alu_reg_in2,
  reg_write_flag_int_decoder => reg_write_flag_int_decoder,
  reg_write_flag_fp_decoder => reg_write_flag_fp_decoder,
  address_decoder_write => reg_write_address_decoder,
  reg_write_flag_int_alu => reg_write_flag_int_alu,
  reg_write_flag_fp_alu => reg_write_flag_fp_alu,
  address_alu => reg_write_address_alu,
  reg_write_flag_int_mem => reg_write_flag_int_mem,
  reg_write_flag_fp_mem => reg_write_flag_fp_mem,
  address_mem => reg_write_address_mem,
  fetch_stall_command   => fetch_stall,
  decoder_stall_command => decoder_stall,
  alu_stall_command     => alu_stall,
  memory_stall_command  => memory_stall,
  fetch_flush_command   => fetch_flush,
  decoder_flush_command => decoder_flush,
  alu_flush_command     => alu_flush
  );

fetch_inst:	entity work.Fetch 
PORT MAP(
			en => fetch_enable,
			clk => CLK,
			reset => fetch_reset,
			fetch_stall => fetch_stall,
			fetch_flush => fetch_flush,
			PC_jump_flag => jmp_flag_alu,
			PC_jump_addr => jmp_dest_alu,
			PC_out => instruction_address,
			Data_out => instruction);


decoder_inst: entity work.decoder
PORT MAP (
			clk => CLK,
			reset => RESET,
			instruction => instruction,
			decoder_stall => decoder_stall,
			decoder_flush => decoder_flush,
			reg_write_flag_int => reg_write_flag_int_decoder,
			reg_write_flag_fp => reg_write_flag_fp_decoder,
			reg_write_address => reg_write_address_decoder,
			alu_reg_in1 => alu_reg_in1,
			alu_reg_in2 => alu_reg_in2,
			alu_immediate_in => alu_immediate_in,
			alu_op => alu_op,
			alu_funct3=> alu_funct3,
			alu_funct7=> alu_funct7,
			decoder_pc => instruction_address,
			alu_pc => alu_pc
		);


alu_inst:	entity work.ALU 
PORT MAP(
			clk => CLK,
			reset => RESET,
			alu_stall => alu_stall,
        	alu_flush => alu_flush,
			rs1 => reg_data_out1, 
			rs2 => reg_data_out2,
			rsf1 => reg_data_out_fp1,
			rsf2 => reg_data_out_fp2,
			imm => alu_immediate_in, 
			op => alu_op, 
			funct3 => alu_funct3,
			funct7 => alu_funct7,
			result_out => alu_result,
			zero_flag => alu_zero,
			alu_pc => alu_pc,
			jmp_flag_alu => jmp_flag_alu,
			jmp_dest_alu => jmp_dest_alu,
			reg_write_flag_int_decoder => reg_write_flag_int_decoder,
			reg_write_flag_fp_decoder => reg_write_flag_fp_decoder,
			reg_write_address_decoder => reg_write_address_decoder,
			reg_write_flag_int_alu => reg_write_flag_int_alu,
			reg_write_flag_fp_alu => reg_write_flag_fp_alu,
			reg_write_address_alu => reg_write_address_alu,
			mem_enable_flag_alu => mem_enable_flag_alu,
			mem_address_alu => mem_address_alu,
			mem_funct3_alu => mem_funct3_alu,
			mem_mode_alu => mem_mode_alu,
			accelerator_en => accelerator_en,
			accelerator_imm => accelerator_imm,
        	accelerator_funct3 => accelerator_funct3
	);

accelerator_inst: entity work.accelerator
 port map(
	clk => clk,
	reset => reset,
	enable => accelerator_en,
	funct3 => accelerator_funct3,
	imm => accelerator_imm,
	addr1 => accelerator_addr1,
	data1 => accelerator_data1,
	addr2 => accelerator_addr2,
	data2 => accelerator_data2,
	addr3 => accelerator_addr3,
	data3 => accelerator_data3,
	addr4 => accelerator_addr4,
	data4 => accelerator_data4,
	mem_write => accelerator_write,
	addr_out => accelerator_addrin,
	data_out => accelerator_datain
);

ram_inst:   entity work.ram
PORT MAP(
			rw       => mem_mode_alu,
			en       => mem_enable_flag_alu,
			clk	     => CLK,
			rst      => RESET,
			stall    => memory_stall,
			funct3   => mem_funct3_alu,
			Address	 => mem_address_alu,
			Data_in	 => alu_result,
			Data_out => reg_data_in_mem,
			reg_write_flag_int_alu => reg_write_flag_int_alu,
			reg_write_flag_fp_alu => reg_write_flag_fp_alu,
			reg_write_flag_int_mem => reg_write_flag_int_mem,
			reg_write_flag_fp_mem => reg_write_flag_fp_mem,
			reg_write_address_alu => reg_write_address_alu,
			reg_write_address_mem => reg_write_address_mem,
			mem_delayed => mem_delayed,
			accelerator_addr1 => accelerator_addr1,
			accelerator_data1 => accelerator_data1,
			accelerator_addr2 => accelerator_addr2,
			accelerator_data2 => accelerator_data2,
			accelerator_addr3 => accelerator_addr3,
			accelerator_data3 => accelerator_data3,
			accelerator_addr4 => accelerator_addr4,
			accelerator_data4 => accelerator_data4,
			accelerator_write => accelerator_write,
			accelerator_addrin => accelerator_addrin,
			accelerator_datain => accelerator_datain
			);

reg_inst:	entity work.reg 
GENERIC MAP(
	x0_hardwired_to_zero => True
)
PORT MAP(
			w_enable => reg_write_flag_int_mem,
			clk => CLK,
			reset => RESET,
			SW => SW,
			Address_w => reg_write_address_mem,
			Address_r_1 => alu_reg_in1,
			Address_r_2 => alu_reg_in2,
			Data_in_mem => reg_data_in_mem,
			Data_out_1 => reg_data_out1,
			Data_out_2 => reg_data_out2,
			Display_out => open);

REG_OUT <= display_number;

fp_reg_inst:	entity work.reg 
GENERIC MAP(
	x0_hardwired_to_zero => False
)
PORT MAP(
			w_enable => reg_write_flag_fp_mem,
			clk => CLK,
			reset => RESET,
			SW => SW,
			
			Address_w => reg_write_address_mem,
			Address_r_1 => alu_reg_in1,
			Address_r_2 => alu_reg_in2,
			Data_in_mem => reg_data_in_mem,
			Data_out_1 => reg_data_out_fp1,
			Data_out_2 => reg_data_out_fp2,
			Display_out => display_number);


END bdf_type;