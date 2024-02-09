LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

LIBRARY work;


-- Entity declaration

ENTITY CPU IS 
	PORT
	(
		MAX10_CLK1_50 :  IN  STD_LOGIC; -- 50 MHz clock
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
SIGNAL	rom_enable : std_logic := '1';
SIGNAL	fetch_reset : std_logic := '0';

SIGNAL	instruction_address : std_logic_vector(7 downto 0) := "00000000";
SIGNAL	instruction : std_logic_vector(22 downto 0) := "10100000000000000000000";

SIGNAL	jmp_flag : std_logic;
SIGNAL	jmp_dest:  std_logic_vector(7 downto 0);
SIGNAL	reg_write_flag : std_logic;
SIGNAL	reg_write_address : std_logic_vector(3 downto 0);
SIGNAL	alu_reg_in1 : std_logic_vector(3 downto 0);
SIGNAL	alu_reg_in2 : std_logic_vector(3 downto 0);
SIGNAL	alu_immediate_in: std_logic_vector(7 downto 0);
SIGNAL	alu_op: std_logic_vector(2 downto 0);

SIGNAL	reg_data_out1 : std_logic_vector(7 downto 0);
SIGNAL	reg_data_out2 : std_logic_vector(7 downto 0);
SIGNAL	alu_result : std_logic_vector(7 downto 0);
SIGNAL	alu_zero : std_logic;


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

-- Component instantiation inside the concurrent statements


decoder_inst: entity work.decoder
    PORT MAP (
			clk => MAX10_CLK1_50,
			instruction => instruction,
			alu_zero => alu_zero,
			jmp => jmp_flag,
			jmp_dest => jmp_dest,
			reg_write => reg_write_flag,
			reg_write_address => reg_write_address,
			alu_reg_in1 => alu_reg_in1,
			alu_reg_in2 => alu_reg_in2,
			alu_immediate_in => alu_immediate_in,
			alu_op => alu_op);

reg_inst:	entity work.reg 
PORT MAP(
			w_enable => reg_write_flag,
			clk => MAX10_CLK1_50,
			SW => SW,
			Address_w => reg_write_address,
			Address_r_1 => alu_reg_in1,
			Address_r_2 => alu_reg_in2,
			Data_in => alu_result,
			Data_out_1 => reg_data_out1,
			Data_out_2 => reg_data_out2,
			Display_out => display_number);


rom_inst:	entity work.rom 
PORT MAP
			(en	=> rom_enable,
			clk => MAX10_CLK1_50,
			Address => instruction_address,
			Data_out => instruction);

fetch_inst:	entity work.Fetch 
PORT MAP(
			en => fetch_enable,
			clk => MAX10_CLK1_50,
			rst => fetch_reset,
			PC_load=> jmp_flag,
			PC_Jump=> jmp_dest,
		   	PC_out=> instruction_address);

alu_inst:	entity work.ALU 
PORT MAP(
			a => reg_data_out1, 
			b => reg_data_out2,
			c => alu_immediate_in, 
			op => alu_op, 
			result_out => alu_result,
			zero_flag => alu_zero);

			

		 
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