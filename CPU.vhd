LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

LIBRARY work;


-- Entity declaration

ENTITY CPU IS 
	PORT
	(
		MAX10_CLK1_50 :  IN  STD_LOGIC; -- 50 MHz clock
		RESET : IN STD_LOGIC;
		SW :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX1 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX2 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX3 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX4 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX5 :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		LEDR :  OUT  STD_LOGIC_VECTOR(9 DOWNTO 0)
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

SIGNAL	reg_write_flag_decoder : std_logic;
SIGNAL	reg_write_address_decoder : std_logic_vector(4 downto 0);
SIGNAL	reg_write_flag_alu : std_logic;
SIGNAL	reg_write_address_alu : std_logic_vector(4 downto 0);
SIGNAL  reg_write_flag_mem : std_logic;
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
SIGNAL	alu_result : std_logic_vector(31 downto 0);
SIGNAL	alu_zero : std_logic;

SIGNAL  mem_enable_flag_alu : std_logic;
SIGNAL  mem_address_alu : std_logic_vector(31 downto 0);
SIGNAL  mem_funct3_alu : std_logic_vector(2 downto 0);
SIGNAL  mem_mode_alu : std_logic;

SIGNAL  reg_data_in_mem : std_logic_vector(31 downto 0);

SIGNAL	zero :  STD_LOGIC;
SIGNAL	one :  STD_LOGIC;
SIGNAL	display_number: STD_LOGIC_VECTOR(15 downto 0);
SIGNAL	HEX_out0 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HEX_out1 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HEX_out2 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HEX_out3 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HEX_out4 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	seg7_in0 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	seg7_in1 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	seg7_in2 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	seg7_in3 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	seg7_in4 :  STD_LOGIC_VECTOR(3 DOWNTO 0);



BEGIN 

-- Reset signals

fetch_reset <= RESET;


-- Component instantiation inside the concurrent statements



pipeline_control_inst: entity work.pipeline_control
port map (
  mem_delayed     => mem_delayed,
  branching_hazard      => jmp_flag_alu,
  address_decoder_1 => alu_reg_in1,
  address_decoder_2 => alu_reg_in1,
  reg_write_flag_decoder => reg_write_flag_decoder,
  address_decoder_write => reg_write_address_decoder,
  reg_write_flag_alu => reg_write_flag_alu,
  address_alu => reg_write_address_alu,
  reg_write_flag_mem => reg_write_flag_mem,
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
			clk => MAX10_CLK1_50,
			reset => fetch_reset,
			fetch_stall => fetch_stall,
			fetch_flush => fetch_flush,
			PC_jump_flag => jmp_flag_alu,
			PC_jump_addr => jmp_dest_alu,
			PC_out => instruction_address,
			Data_out => instruction);


decoder_inst: entity work.decoder
PORT MAP (
			clk => MAX10_CLK1_50,
			reset => RESET,
			instruction => instruction,
			decoder_stall => decoder_stall,
			decoder_flush => decoder_flush,
			reg_write_flag => reg_write_flag_decoder,
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
			clk => MAX10_CLK1_50,
			reset => RESET,
			alu_stall => alu_stall,
        	alu_flush => alu_flush,
			rs1 => reg_data_out1, 
			rs2 => reg_data_out2,
			imm => alu_immediate_in, 
			op => alu_op, 
			funct3 => alu_funct3,
			funct7 => alu_funct7,
			result_out => alu_result,
			zero_flag => alu_zero,
			alu_pc => alu_pc,
			jmp_flag_alu => jmp_flag_alu,
			jmp_dest_alu => jmp_dest_alu,
			reg_write_flag_decoder => reg_write_flag_decoder,
			reg_write_address_decoder => reg_write_address_decoder,
			reg_write_flag_alu => reg_write_flag_alu,
			reg_write_address_alu => reg_write_address_alu,
			mem_enable_flag_alu => mem_enable_flag_alu,
			mem_address_alu => mem_address_alu,
			mem_funct3_alu => mem_funct3_alu,
			mem_mode_alu => mem_mode_alu
	);

ram_inst:   entity work.ram
PORT MAP(
			rw       => mem_mode_alu,
			en       => mem_enable_flag_alu,
			clk	     => MAX10_CLK1_50,
			rst      => RESET,
			stall    => memory_stall,
			funct3   => mem_funct3_alu,
			Address	 => mem_address_alu,
			Data_in	 => alu_result,
			Data_out_mem => reg_data_in_mem,
			reg_write_flag_alu => reg_write_flag_alu,
			reg_write_flag_mem => reg_write_flag_mem,
			reg_write_address_alu => reg_write_address_alu,
			reg_write_address_mem => reg_write_address_mem,
			mem_delayed => mem_delayed
			);

reg_inst:	entity work.reg 
PORT MAP(
			w_enable => reg_write_flag_mem,
			clk => MAX10_CLK1_50,
			reset => RESET,
			SW => SW,
			Address_w => reg_write_address_mem,
			Address_r_1 => alu_reg_in1,
			Address_r_2 => alu_reg_in2,
			Data_in_mem => reg_data_in_mem,
			Data_out_1 => reg_data_out1,
			Data_out_2 => reg_data_out2,
			Display_out => display_number);




-- LED display components

b2v_inst : entity work.seg7_lut
PORT MAP(iDIG => seg7_in0,
		 oSEG => HEX_out4(6 DOWNTO 0));


b2v_inst1 : entity work.seg7_lut
PORT MAP(iDIG => seg7_in1,
		 oSEG => HEX_out3(6 DOWNTO 0));



b2v_inst2 : entity work.seg7_lut
PORT MAP(iDIG => seg7_in2,
		 oSEG => HEX_out2(6 DOWNTO 0));


b2v_inst3 : entity work.seg7_lut
PORT MAP(iDIG => seg7_in3,
		 oSEG => HEX_out1(6 DOWNTO 0));


b2v_inst4 : entity work.seg7_lut
PORT MAP(iDIG => seg7_in4,
		 oSEG => HEX_out0(6 DOWNTO 0));


b2v_inst5 : entity work.dig2dec
PORT MAP(vol => display_number,
		 seg0 => seg7_in4,
		 seg1 => seg7_in3,
		 seg2 => seg7_in2,
		 seg3 => seg7_in1,
		 seg4 => seg7_in0);


HEX0 <= HEX_out0;
HEX1 <= HEX_out1;
HEX2 <= HEX_out2;
HEX3 <= HEX_out3;
HEX4 <= HEX_out4;
HEX5(7) <= one;
HEX5(6) <= one;
HEX5(5) <= one;
HEX5(4) <= one;
HEX5(3) <= one;
HEX5(2) <= one;
HEX5(1) <= one;
HEX5(0) <= one;

zero <= '0';
one <= '1';
HEX_out0(7) <= '1';
HEX_out1(7) <= '1';
HEX_out2(7) <= '1';
HEX_out3(7) <= '1';
HEX_out4(7) <= '1';



LEDR <= SW;

END bdf_type;