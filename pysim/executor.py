from math import copysign

from typing import TYPE_CHECKING

from emulators import float_to_signed, signed_to_float, signed_to_unsigned

if TYPE_CHECKING:
    from program import Program  # Only for type checking, not at runtime

class RiscVExecutor:
    
    def __init__(self, program: "Program") -> None:

        self.program = program

        # Initialize integer and floating-point registers
        self.reg_int = program.reg_int
        self.reg_fp = program.reg_fp

        self.ram = program.ram
        self.accelerator = program.accelerator

    def add(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] + self.reg_int[rs2]

    def sub(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] - self.reg_int[rs2]
    
    def mul(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] * self.reg_int[rs2]

    def and_(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] & self.reg_int[rs2]
    
    def andi(self, rd, rs1, imm, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] & imm

    def or_(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] | self.reg_int[rs2]
    
    def ori(self, rd, rs1, imm, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] | imm

    def xor_(self, rd, rs1, rs2, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] ^ self.reg_int[rs2]

    def xori(self, rd, rs1, imm, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] ^ imm

    def addi(self, rd, rs1, imm, **kwargs):
        self.reg_int[rd] = self.reg_int[rs1] + imm
    
    def load_imm(self, rd, imm, **kwargs):
        self.reg_int[rd] = imm
    
    def auipc(self, pc, rd, imm, **kwargs):
        self.reg_int[rd] = imm + pc

    def slti(self, rd, rs1, imm, **kwargs):
        if self.reg_int[rs1] < imm:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0

    def sltiu(self, rd, rs1, imm, **kwargs):
        unsigned_rs1 = signed_to_unsigned(self.reg_int[rs1])
        unsigned_imm = signed_to_unsigned(imm)
        if unsigned_rs1 < unsigned_imm:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0
    
    def slli(self, rd, rs1, rs2, **kwargs):
        shift_amount = rs2 # Acts as an immediate
        self.reg_int[rd] = (self.reg_int[rs1] << shift_amount) & 0xFFFFFFFF  # Shift left and mask to 32 bits

    def srli(self, rd, rs1, rs2, **kwargs):
        
        shift_amount = rs2 # Acts as an immediate
        result = self.reg_int[rs1] >> shift_amount  # Logical right shift
        
        # Store the result in the destination register rd
        self.reg_int[rd] = result


    def srai(self, rd, rs1, rs2, **kwargs):
        
        shift_amount = rs2 # Acts as an immediate
        value = self.reg_int[rs1]
        
        # Check if the sign bit is set
        if value & 0x80000000:
            result = (value >> shift_amount) | (0xFFFFFFFF << (32 - shift_amount))
        else:
            result = value >> shift_amount

        self.reg_int[rd] = result & 0xFFFFFFFF  # Mask to 32 bits

    def jal(self, pc, rd, imm, **kwargs):

        dest = pc + imm

        self.reg_int[rd] = pc + 4
        self.program.set_PC(dest)

    def jalr(self, pc, rd, rs1, imm, **kwargs):

        dest = self.reg_int[rs1] + imm

        self.reg_int[rd] = pc + 4
        self.program.set_PC(dest)

    def beq(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if self.reg_int[rs1] == self.reg_int[rs2]:
            self.program.set_PC(jmp_dest)
    
    def bne(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if self.reg_int[rs1] != self.reg_int[rs2]:
            self.program.set_PC(jmp_dest)
    
    def blt(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if self.reg_int[rs1] < self.reg_int[rs2]:
            self.program.set_PC(jmp_dest)
    
    def bltu(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if signed_to_unsigned(self.reg_int[rs1]) >= signed_to_unsigned(self.reg_int[rs2]):
            self.program.set_PC(jmp_dest)
    
    def bge(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if self.reg_int[rs1] < self.reg_int[rs2]:
            self.program.set_PC(jmp_dest)
    
    def bgeu(self, pc, rs1, rs2, imm, **kwargs):
        
        jmp_dest = pc + imm
        if signed_to_unsigned(self.reg_int[rs1]) >= signed_to_unsigned(self.reg_int[rs2]):
            self.program.set_PC(jmp_dest)
    
    def sb(self, rs1, rs2, imm, **kwargs):
        
        mem_addr = self.reg_int[rs1] + imm
        self.ram[mem_addr] = self.reg_int[rs2] & 0x000000FF

    def sh(self, rs1, rs2, imm, **kwargs):
        
        mem_addr = self.reg_int[rs1] + imm
        self.ram[mem_addr] = self.reg_int[rs2] & 0x0000FFFF
    
    def sw(self, rs1, rs2, imm, **kwargs):
        
        mem_addr = self.reg_int[rs1] + imm
        self.ram[mem_addr] = self.reg_int[rs2] & 0xFFFFFFFF

    def slt(self, rd, rs1, rs2, imm, **kwargs):
        if self.reg_int[rs1] < self.reg_int[rs2]:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0

    def sltu(self, rd, rs1, rs2, imm, **kwargs):
        if signed_to_unsigned(self.reg_int[rs1]) < signed_to_unsigned(self.reg_int[rs2]):
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0

    def sll(self, rd, rs1, rs2, **kwargs):
        shift_amount = self.reg_int[rs2]
        self.reg_int[rd] = (self.reg_int[rs1] << shift_amount) & 0xFFFFFFFF  # Shift left and mask to 32 bits

    def srl(self, rd, rs1, rs2, **kwargs):
        
        shift_amount = self.reg_int[rs2]
        result = self.reg_int[rs1] >> shift_amount  # Logical right shift
        
        # Store the result in the destination register rd
        self.reg_int[rd] = result


    def sra(self, rd, rs1, rs2, **kwargs):
        
        shift_amount = self.reg_int[rs2]
        value = self.reg_int[rs1]
        
        # Check if the sign bit is set
        if value & 0x80000000:
            result = (value >> shift_amount) | (0xFFFFFFFF << (32 - shift_amount))
        else:
            result = value >> shift_amount

        self.reg_int[rd] = result

    def lb(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr] & 0x000000FF
        self.reg_int[rd] = mem_content if mem_content < 0x80 else mem_content - 0x100  # sign-extend
    
    def lh(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr] & 0x0000FFFF
        self.reg_int[rd] = mem_content if mem_content < 0x8000 else mem_content - 0x10000  # sign-extend
    
    def lw(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr]
        if type(mem_content) is not int: raise TypeError("Tried to load int from non-int data")
        self.reg_int[rd] = mem_content
    
    def lbu(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr] & 0x000000FF
        self.reg_int[rd] = mem_content

    def lhu(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr] & 0x0000FFFF
        self.reg_int[rd] = mem_content

    def fsw(self, rs1, rs2, imm, **kwargs):
        mem_addr = self.reg_int[rs1] + imm
        self.ram[mem_addr] = float_to_signed(self.reg_fp[rs2])

    def flw(self, rd, rs1, imm, **kwargs):
        addr = self.reg_int[rs1] + imm
        mem_content = self.ram[addr]
        self.reg_fp[rd] = signed_to_float(mem_content)

    def fmvxw(self, rd, rs1, **kwargs):
        self.reg_int[rd] = float_to_signed(self.reg_fp[rs1])

    def fmvwx(self, rd, rs1, **kwargs):
        self.reg_fp[rd] = signed_to_float(self.reg_int[rs1])
    
    def fcvtsw(self, rd, rs1, **kwargs):
        self.reg_fp[rd] = float(self.reg_int[rs1])

    def fadds(self, rd, rs1, rs2, **kwargs):
        self.reg_fp[rd] = self.reg_fp[rs1] + self.reg_fp[rs2]
    
    def fsubs(self, rd, rs1, rs2, **kwargs):
        self.reg_fp[rd] = self.reg_fp[rs1] - self.reg_fp[rs2]
    
    def fmuls(self, rd, rs1, rs2, **kwargs):
        self.reg_fp[rd] = self.reg_fp[rs1] * self.reg_fp[rs2]
    
    def feqs(self, rd, rs1, rs2, **kwargs):
        if self.reg_fp[rs1] == self.reg_fp[rs2]:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0
    
    def flts(self, rd, rs1, rs2, **kwargs):
        if self.reg_fp[rs1] < self.reg_fp[rs2]:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0
    
    def fles(self, rd, rs1, rs2, **kwargs):
        if self.reg_fp[rs1] <= self.reg_fp[rs2]:
            self.reg_int[rd] = 1
        else:
            self.reg_int[rd] = 0
    
    def fsgnjs(self, rd, rs1, rs2, **kwargs):
        self.reg_fp[rd] = copysign(self.reg_fp[rs1], self.reg_fp[rs2])
    
    def fsgnjns(self, rd, rs1, rs2, **kwargs):
        self.reg_fp[rd] = copysign(self.reg_fp[rs1], -self.reg_fp[rs2])
    
    def fsgnjxs(self, rd, rs1, rs2, **kwargs):
        aux = copysign(1.0, self.reg_fp[rs1])
        self.reg_fp[rd] = copysign(self.reg_fp[rs1], aux * self.reg_fp[rs2])

    def macc(self, **kwargs):
        self.accelerator.macc()

    def setpa(self, imm, **kwargs):
        self.accelerator.set_pa(imm)

    def setpb(self, imm, **kwargs):
        self.accelerator.set_pb(imm)

    def storeacc(self, imm, **kwargs):
        self.accelerator.store(imm)

    def addpa(self, **kwargs):
        self.accelerator.add_pa()

    def addpb(self, **kwargs):
        self.accelerator.add_pb()

    def setacc(self, imm, **kwargs):
        self.accelerator.set_acc(imm)

    

    def execute(self, decode_dict):

        decode_dict["pc"] = self.program.get_PC()

        opcode = decode_dict["opcode"]
        funct3 = decode_dict["funct3"]
        funct7 = decode_dict["funct7"]
        imm = decode_dict["imm"]

        match opcode:
            
            case 0b0010011: # "ADDI"|"SLTI"|"SLTIU"|"XORI"|"ORI"|"ANDI"
                if funct3==0b000: # ADDI
                    self.addi(**decode_dict)
                
                elif funct3==0b010: # SLTI
                    self.slti(**decode_dict)
                elif funct3==0b011: # SLTIU
                    self.sltiu(**decode_dict)
                
                elif funct3==0b100: # XORI
                    self.xori(**decode_dict)
                elif funct3==0b110: # ORI
                    self.ori(**decode_dict)
                elif funct3==0b111: # ANDI
                    self.andi(**decode_dict)
                
                elif funct3==0b001: # SLLI
                    self.slli(**decode_dict)
                elif funct3==0b101: # SRLI/SRAI
                    if (imm & (1 << 10)) == 0 : # SRLI
                        self.srli(**decode_dict)
                    else: # SRAI
                        self.srai(**decode_dict)
                
            case 0b0110111: # LUI
                self.load_imm(**decode_dict)
            case 0b0010111: # AUIPC
                self.auipc(**decode_dict)
            case 0b1101111: # JAL
                self.jal(**decode_dict)
            case 0b1100111: # JALR
                self.jalr(**decode_dict)
            case 0b1100011: # "BEQ"|"BNE"|"BLT"|"BGE"|"BLTU"|"BGEU"
                if funct3==0b000: # BEQ
                    self.beq(**decode_dict)
                elif funct3==0b001: # BNE
                    self.bne(**decode_dict)
                elif funct3==0b100: # BLT
                    self.blt(**decode_dict)
                elif funct3==0b110: # BLTU
                    self.bltu(**decode_dict)
                elif funct3==0b101: # BGE
                    self.bge(**decode_dict)
                elif funct3==0b111: # BGEU
                    self.bgeu(**decode_dict)
            
            case 0b0000011: # "LB"|"LH"|"LW"|"LBU"|"LHU"
                if funct3==0b000: # LB
                    self.lb(**decode_dict)
                elif funct3==0b001: # LH
                    self.lh(**decode_dict)
                elif funct3==0b010: # LW
                    self.lw(**decode_dict)
                elif funct3==0b100: # LBU
                    self.lbu(**decode_dict)
                elif funct3==0b101: # LHU
                    self.lhu(**decode_dict)
            
            case 0b0100011: # "SB"|"SH"|"SW"
                if funct3==0b000: # SB
                    self.sb(**decode_dict)
                elif funct3==0b001: # SH
                    self.sh(**decode_dict)
                elif funct3==0b010: # SW
                    self.sw(**decode_dict)
                
            case 0b0110011: # "ADD"|"SUB"|"MUL"|"SLL"|"SLT"|"SLTU"|"XOR"|"SRL"|"SRA"|"OR"|"AND":
                if funct3==0:
                    if funct7&(1<<5)==0 and funct7&(1<<0)==0: # ADD
                        self.add(**decode_dict)
                    elif funct7&(1<<5)>=1 and funct7&(1<<0)==0: # SUB
                        self.sub(**decode_dict)
                    else: # MUL
                        self.mul(**decode_dict)

                elif funct3==0b010: # SLT
                    self.slt(**decode_dict)
                elif funct3==0b011: # SLTU
                    self.sltu(**decode_dict)
                
                elif funct3==0b100: # XOR
                    self.xor_(**decode_dict)
                elif funct3==0b110: # OR
                    self.or_(**decode_dict)
                elif funct3==0b111: # AND
                    self.and_(**decode_dict)

                elif funct3==0b001: # SLL
                    self.sll(**decode_dict)
                elif funct3==0b101: # SRL/SRA
                    if funct7&(1<<5)==0: # SRL
                        self.srl(**decode_dict)
                    else: # SRA
                        self.sra(**decode_dict)
            
            case 0b1010011: # "FADD.S"|"FSUB.S"|"FMUL.S"|"FEQ.S"|"FLT.S"|"FLE.S"|"FMV.X.W"|"FMV.W.X"|"FSGNJ.S"|"FSGNJN.S"|"FSGNJX.S":
                if funct7==0b0000000: # FADD.S
                    self.fadds(**decode_dict)
                elif funct7==0b0000100: # FSUB.S
                    self.fsubs(**decode_dict)
                elif funct7==0b0001000: # FMUL.S
                    self.fmuls(**decode_dict)
                elif funct7==0b1010000: # Comparisons
                    if funct3==0b010: # FEQ.S
                        self.feqs(**decode_dict)
                    elif funct3==0b001: # FLT.S 
                        self.flts(**decode_dict)
                    elif funct3==0b000: # FLE.S
                        self.fles(**decode_dict)
                    else:
                        raise ValueError
                elif funct7==0b1110000: # FMV.X.W (float to integer)
                    self.fmvxw(**decode_dict)
                elif funct7==0b1111000: # FMV.W.X (integer to float)
                    self.fmvwx(**decode_dict)
                elif funct7==0b0010000: # Sign injection
                    if funct3==0b000: # FSGNJ.S
                        self.fsgnjs(**decode_dict)
                    elif funct3==0b001: # FSGNJN.S
                        self.fsgnjns(**decode_dict)
                    elif funct3==0b010: # FSGNJX.S
                        self.fsgnjxs(**decode_dict)
                    else:
                        raise ValueError
                elif funct7==0b1101000: # FCVT.S.W
                    self.fcvtsw(**decode_dict)
                else:
                    raise ValueError
            case 0b0000111: # "FLW":
                self.flw(**decode_dict)
            case 0b0100111: # FSW
                self.fsw(**decode_dict)
            case 0b0001011: # Accelerator
                if decode_dict["rd"]&0x7==0b000: # Macc
                    self.macc(**decode_dict)
                elif decode_dict["rd"]&0x7==0b001: # SetPA
                    self.setpa(**decode_dict)
                elif decode_dict["rd"]&0x7==0b010: # SetPB
                    self.setpb(**decode_dict)
                elif decode_dict["rd"]&0x7==0b011: # Store
                    self.storeacc(**decode_dict)
                elif decode_dict["rd"]&0x7==0b100: # AddPA
                    self.addpa(**decode_dict)
                elif decode_dict["rd"]&0x7==0b101: # AddPB
                    self.addpb(**decode_dict)
                elif decode_dict["rd"]&0x7==0b110: # SetACC
                    self.setacc(**decode_dict)
                else:
                    raise ValueError
            case _:
                print("Warning: unknown instruction found: ", opcode)

    def __call__(self, decode_dict):
        return self.execute(decode_dict)
