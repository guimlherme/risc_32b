library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    port (
        clk: in std_logic;
        alu_stall: in std_logic;
        alu_flush: in std_logic;

        rs1, rs2, imm: in std_logic_vector(31 downto 0);
        op: in std_logic_vector(6 downto 0);
        funct3: in std_logic_vector(2 downto 0);
        funct7: in std_logic_vector(6 downto 0);
        result_out: out std_logic_vector(31 downto 0);
        zero_flag: out std_logic;

        alu_pc: in std_logic_vector(31 downto 0);

        jmp_flag_alu: out std_logic;
        jmp_dest_alu: out std_logic_vector(31 downto 0);

        reg_write_flag_decoder: in std_logic;
        reg_write_address_decoder: in std_logic_vector(4 downto 0);
        reg_write_flag_alu: out std_logic;
        reg_write_address_alu: out std_logic_vector(4 downto 0);

        mem_enable_flag_alu: out std_logic;
        mem_address_alu: out std_logic_vector(31 downto 0);
        mem_funct3_alu: out std_logic_vector(2 downto 0);
        mem_mode_alu: out std_logic

    );
end ALU;		

architecture ALU_arch of ALU is

signal result : std_logic_vector(31 downto 0);
signal jmp_flag : std_logic;
signal jmp_dest : std_logic_vector(31 downto 0);

-- signal reg_write_flag : std_logic;

signal mem_enable_flag: std_logic;
signal mem_address: std_logic_vector(31 downto 0);
signal mem_funct3: std_logic_vector(2 downto 0);
signal mem_mode: std_logic;

constant zeros : std_logic_vector(31 downto 0) := (others => '0');

begin

process(clk)
begin
if rising_edge(clk) then

    if alu_stall='0' and alu_flush='0' then
        reg_write_address_alu <= reg_write_address_decoder;
        jmp_dest_alu <= jmp_dest;
        mem_address_alu <= mem_address;
        mem_funct3_alu <= mem_funct3;
        mem_mode_alu <= mem_mode;

        if (result = zeros) then
            zero_flag <= '1';
        else
            zero_flag <= '0';
        end if;
        result_out <= result;

        reg_write_flag_alu <= reg_write_flag_decoder;
        jmp_flag_alu <= jmp_flag;
        mem_enable_flag_alu <= mem_enable_flag;

        -- Reg x0 is read only
	    if reg_write_address_decoder = "00000" then
		    reg_write_flag_alu <= '0';
	    end if;

    elsif alu_flush='1' then

        reg_write_address_alu <= (others => '-');
        jmp_dest_alu <= (others => '-');
        mem_address_alu <= (others => '-');
        mem_funct3_alu <= (others => '-');
        mem_mode_alu <= '-';
        zero_flag <= '-';

        reg_write_flag_alu <= '0';
        jmp_flag_alu <= '0';
        mem_enable_flag_alu <= '0';
    
    end if;

end if;
end process;

-- process(all) -- Unsupported in VHDL 1993
process(rs1, rs2, imm, alu_pc, op, funct3, funct7)

variable unsigned_rs1 : unsigned(31 downto 0);
variable signed_rs1   : signed(31 downto 0);
variable unsigned_rs2 : unsigned(31 downto 0);
variable signed_rs2   : signed(31 downto 0);
variable unsigned_imm : unsigned(31 downto 0);
variable signed_imm   : signed(31 downto 0);
variable shift_amount_imm : natural;
variable shift_amount_rs2 : natural;
variable signed_alu_pc : signed(31 downto 0);

begin
    
	 -- Helper signals
	 unsigned_rs1 := unsigned(rs1);
    signed_rs1   := signed(rs1);
    unsigned_rs2 := unsigned(rs2);
    signed_rs2   := signed(rs2);
    unsigned_imm := unsigned(imm);
    signed_imm   := signed(imm);
    shift_amount_imm := to_integer(unsigned(imm(4 downto 0)));
    shift_amount_rs2 := to_integer(unsigned(rs2(4 downto 0)));
    signed_alu_pc := signed(alu_pc);
    
    -- Default values
    result <= (others => '-');
    jmp_dest <= (others => '-');
    jmp_flag <= '0';
    mem_enable_flag <= '0';
    -- reg_write_flag <= '0';
    mem_address <= (others => '-');
    mem_funct3 <= (others => '-');
    mem_mode <= '-';

    case op is
        when "0010011" => -- Operations with immediates
            -- reg_write_flag <= '1';

            if funct3="000" then -- ADDI
                result <= std_logic_vector(signed_rs1 + signed_imm);
            
            elsif funct3="010" then -- SLTI
                if signed_rs1 < signed_imm then result <= (0 => '1', others => '0');
                else result <= (others => '0'); end if;
            elsif funct3="011" then -- SLTIU
                if unsigned_rs1 < unsigned_imm then result <= (0 => '1', others => '0');
                else result <= (others => '0'); end if;
            
            elsif funct3="100" then -- XORI
                result <= rs1 xor imm;
            elsif funct3="110" then -- ORI
                result <= rs1 or imm;
            elsif funct3="111" then -- ANDI
                result <= rs1 and imm;
            
            elsif funct3="001" then -- SLLI
                result <= std_logic_vector(shift_left(unsigned_rs1, shift_amount_imm));
            elsif funct3="101" then -- SRLI/SRAI
                if imm(10)='0' then -- SRLI
                    result <= std_logic_vector(shift_right(unsigned_rs1, shift_amount_imm));
                else -- SRAI
                    result <= std_logic_vector(shift_right(signed_rs1, shift_amount_imm));
                end if;
            
            end if;
        
        
        when "0110111" => -- LUI
            -- reg_write_flag <= '1';
            result <= imm;
        

        when "0010111" => -- AUIPC
            -- reg_write_flag <= '1';
            result <= std_logic_vector(signed_imm + signed_alu_pc);

        
        when "0110011" => -- Operations with registers
            -- reg_write_flag <= '1';

            if funct3="000" then
                if funct7(5)='0' then -- ADD
                    result <= std_logic_vector(signed_rs1 + signed_rs2);
                else -- SUB
                    result <= std_logic_vector(signed_rs1 - signed_rs2); -- #TODO: optimize SUB
                end if;

            elsif funct3="010" then -- SLT
                if signed_rs1 < signed_rs2 then result <= (0 => '1', others => '0'); 
                else result <= (others => '0'); end if;
            elsif funct3="011" then -- SLTU
                if unsigned_rs1 < unsigned_rs2 then result <= (0 => '1', others => '0'); 
                else result <= (others => '0'); end if;
            
            elsif funct3="100" then -- XOR
                result <= rs1 xor rs2;
            elsif funct3="110" then -- OR
                result <= rs1 or rs2;
            elsif funct3="111" then -- AND
                result <= rs1 and rs2;

            elsif funct3="001" then -- SLL
                result <= std_logic_vector(shift_left(unsigned_rs1, shift_amount_rs2));
            elsif funct3="101" then -- SRL/SRA
                if funct7(5)='0' then -- SRL
                    result <= std_logic_vector(shift_right(unsigned_rs1, shift_amount_imm));
                else -- SRA
                    result <= std_logic_vector(shift_right(signed_rs1, shift_amount_imm));
                end if;
            
            end if;
            
        
        when "1101111" => -- JAL
            -- reg_write_flag <= '1';
            jmp_flag <= '1';
            jmp_dest <= std_logic_vector(signed_alu_pc + signed_imm);
            result <= std_logic_vector(signed_alu_pc + 4);
        
        when "1100111" => -- JALR
            -- reg_write_flag <= '1';
            jmp_flag <= '1';
            jmp_dest <= std_logic_vector(signed_rs1 + signed_imm);
            jmp_dest(0) <= '0';
            result <= std_logic_vector(signed_alu_pc + 4);
            -- #TODO: add exception if jmp_dest % 4 == 0
        
        when "1100011" => -- branches
            -- reg_write_flag <= '0';
            jmp_dest <= std_logic_vector(signed_alu_pc + signed_imm);
            if funct3="000" then -- BEQ
                if signed_rs1 = signed_rs2 then jmp_flag <= '1';
                else jmp_flag <= '0'; end if;
            elsif funct3="001" then -- BNE
                if signed_rs1 = signed_rs2 then jmp_flag <= '0';
                else jmp_flag <= '1'; end if;
            elsif funct3="100" then -- BLT
                if signed_rs1 < signed_rs2 then jmp_flag <= '1';
                else jmp_flag <= '0'; end if;
            elsif funct3="110" then -- BLTU
                if unsigned_rs1 < unsigned_rs2 then jmp_flag <= '1';
                else jmp_flag <= '0'; end if;
            elsif funct3="101" then -- BGE
                if signed_rs1 < signed_rs2 then jmp_flag <= '0';
                else jmp_flag <= '1'; end if;
            elsif funct3="111" then -- BGEU
                if unsigned_rs1 < unsigned_rs2 then jmp_flag <= '0';
                else jmp_flag <= '1'; end if;
            end if;

        when "0000011" => -- loads
            -- reg_write_flag <= '1'; -- Not the usual write
            mem_address <= std_logic_vector(signed_rs1 + signed_imm);
            mem_funct3 <= funct3;
            mem_enable_flag <= '1';
            mem_mode <= '0'; -- read
        
        when "0100011" => -- stores
            -- reg_write_flag <= '0';
            mem_address <= std_logic_vector(signed_rs1 + signed_imm);
            mem_funct3 <= funct3;
            mem_enable_flag <= '1';
            mem_mode <= '1'; -- write
        when others => NULL;
    end case;

end process;


end ALU_arch;
