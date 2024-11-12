# Python code to convert assembly to machine code

from collections import defaultdict 
import struct
from sys import argv

# Warning: this register might be arbitrarily overwritten due to intermediate instructions
TEMPORARY_REGISTER = "x30"

register_equivalence = {
    "zero": "x0",
    "ra": "x1",
    "sp": "x2",
    "gp": "x3",
    "tp": "x4",
    "t0": "x5",
    "t1": "x6",
    "t2": "x7",
    "s0": "x8",
    "s1": "x9",
    "a0": "x10",
    "a1": "x11",
    "a2": "x12",
    "a3": "x13",
    "a4": "x14",
    "a5": "x15",
    "a6": "x16",
    "a7": "x17",
    "s2": "x18",
    "s3": "x19",
    "s4": "x20",
    "s5": "x21",
    "s6": "x22",
    "s7": "x23",
    "s8": "x24",
    "s9": "x25",
    "s10": "x26",
    "s11": "x27",
    "t3": "x28",
    "t4": "x29",
    "t5": "x30",
    "t6": "x31",
    "ft0": "f0",
    "ft1": "f1",
    "ft2": "f2",
    "ft3": "f3",
    "ft4": "f4",
    "ft5": "f5",
    "ft6": "f6",
    "ft7": "f7",
    "fs0": "f8",
    "fs1": "f9",
    "fa0": "f10",
    "fa1": "f11",
    "fa2": "f12",
    "fa3": "f13",
    "fa4": "f14",
    "fa5": "f15",
    "fa6": "f16",
    "fa7": "f17",
    "fs2": "f18",
    "fs3": "f19",
    "fs4": "f20",
    "fs5": "f21",
    "fs6": "f22",
    "fs7": "f23",
    "fs8": "f24",
    "fs9": "f25",
    "fs10": "f26",
    "fs11": "f27",
    "ft8": "f28",
    "ft9": "f29",
    "ft10": "f30",
    "ft11": "f31",
}


funct3_map = {
    "JALR": "000",
    "BEQ": "000",
    "BNE": "001",
    "BLT": "100",
    "BGE": "101",
    "BLTU": "110",
    "BGEU": "111",
    "LB": "000",
    "LH": "001",
    "LW": "010",
    "LBU" : "100",
    "LHU" : "101",
    "SB" : "000",
    "SH" : "001",
    "SW" : "010",
    "ADDI" : "000",
    "SLTI" : "010",
    "SLTIU" : "011",
    "XORI" : "100",
    "ORI" : "110",
    "ANDI" : "111",
    "SLLI" : "001",
    "SRLI" : "101",
    "SRAI" : "101",
    "ADD" : "000",
    "SUB" : "000",
    "MUL" : "000",
    "SLL" : "001",
    "SLT" : "010",
    "SLTU" : "011",
    "XOR" : "100",
    "SRL" : "101",
    "SRA" : "101",
    "OR" : "110",
    "AND" : "111",
    "FADD.S" : "000",
    "FSUB.S" : "000",
    "FMUL.S" : "000",
    "FEQ.S" : "010",
    "FLT.S" : "001",
    "FLE.S" : "000",
    "FMV.X.W" : "000",
    "FMV.W.X" : "000",
    "FSGNJ.S" : "000",
    "FSGNJN.S" : "001",
    "FSGNJX.S" : "010",
    "FCVT.S.W" : "000",
    "FLW" : "010",
    "FSW" : "010",
}

funct7_map = defaultdict(lambda: "0000000")
funct7_map.update({
    "SRAI": "0100000",
    "SUB" : "0100000",
    "MUL" : "0000001",
    "SRA" : "0100000",
    "FADD.S" : "0000000",
    "FSUB.S" : "0000100",
    "FMUL.S" : "0001000",
    "FEQ.S" : "1010000",
    "FLT.S" : "1010000",
    "FLE.S" : "1010000",
    "FMV.X.W" : "1110000",
    "FMV.W.X" : "1111000",
    "FSGNJ.S" : "0010000",
    "FSGNJN.S" : "0010000",
    "FSGNJX.S" : "0010000",
    "FCVT.S.W" : "1101000",
})

def int2signedbin(number: int, digits: int) -> int:
    assert -2 ** digits < number < 2 ** digits 
    if number >= 0:
        return number
    else:
        xor_mask = int("1"*digits, 2)
        two_complement = (abs(number) ^ xor_mask) + 1
        return two_complement

def float2signedbin(value: float) -> int:
    packed_value = struct.pack('>f', value)  # big-endian, 32-bit float
    # return ''.join(f'{byte:08b}' for byte in packed_value) # String
    return struct.unpack('>i', packed_value)[0]

def divide_lui_addi(value: int) -> tuple[int, int]:
    # Parte of the "load immediate" chain
    # Divides the 32-bit integer into two immediates that go to lui and addi instruction
    lui_int = value >> 12

    addi_int = value & 0xFFF # Take 12 bits
    # ADDI is sign-extended, so a small compensation might be needed
    if (value & 0x800) != 0: # Takes the 12-th bit
        lui_int += 1 # Annulates the sign-extension of ADDI
        addi_int -= 0x1000 # The immediate will be negative
    
    return lui_int, addi_int

print(len(argv))

if len(argv) >= 2:
    file_r_name = argv[1]
else:
    file_r_name = 'input.txt'

if len(argv) >= 3:
    file_w_name = argv[2]
else:
    file_w_name = 'output.txt'

file_r = open(file_r_name, 'r')
file_w = open(file_w_name, 'w')

Lines = file_r.readlines()
gotos = {}
counter_goto = 0
for line in Lines:
    line = line.strip().rstrip("\n").upper()
    words = line.split(' ')
    opcode = words[0]
    if opcode == "":
        continue
    elif opcode[-1] != ":":
        counter_goto += 4
    else:
        gotos[opcode.rstrip(":")] = counter_goto



print("Gotos:", gotos)

counter = 0
def process_line(line):

    global counter

    line = line.strip().rstrip("\n").upper()
    words = line.split(' ')
    words = [w.rstrip().rstrip(',') for w in words]
    opcode = words[0]
    opcode = opcode.upper()
    bytecode = ""

    if opcode == "":
        return
    if opcode == "CSRRW": #XXX: Ignore this instruction for now
        opcode = "NOP"
    if opcode[-1] == ":":
        assert(gotos[opcode.rstrip(":")] == counter)
        return
    
    #Pseudoinstructions
    if opcode == "MOV" or opcode == "MV":
        try:
            int(words[2])
            #TODO: Make it work with numbers bigger than 2**12
            words = ["ADDI", words[1], "x0", words[2]]
        except ValueError:
            words = ["ADDI", words[1], words[2], "0"]
    elif opcode == "NOP":
        words = ["ADDI", "x0", "x0", "0"]
    elif opcode == "FMOV" or opcode == "FMV" or opcode == "FMOV.S" or opcode == "FMV.S":
        try:
            #XXX: Warning: this uses the register X30
            float_imm = float(words[2])
            float_bin = float2signedbin(float_imm)
            lui_int, addi_int = divide_lui_addi(float_bin)
            process_line(f"LUI {TEMPORARY_REGISTER} {lui_int}")
            process_line(f"ADDI {TEMPORARY_REGISTER} {TEMPORARY_REGISTER} {addi_int}")
            words = ["FMV.W.X", words[1], TEMPORARY_REGISTER]
        except ValueError: # Move between FP registers
            words = ["FSGNJ.S", words[1], words[2], words[2]]

    # Reload opcode
    opcode = words[0]

    if '(' in words[2]:
        words.append((words[2].split('('))[0])
        words[2] = (words[2].split('('))[1][:-1]

    # Adjust register names
    for i, word in enumerate(words):
        if word.lower() in register_equivalence:
            words[i] = register_equivalence[word.lower()]

    match opcode:
        case "LUI":
            rd = int(words[1][1:])
            imm = int(words[2])
            imm = int2signedbin(imm, 20)
            opcode_number = int("0110111", 2)
            bytecode = '{:020b}{:05b}{:07b}'.format(imm, rd, opcode_number)
        case "AUIPC":
            rd = int(words[1][1:])
            imm = int(words[2])
            imm = int2signedbin(imm, 20)
            opcode_number = int("0010111", 2)
            bytecode = '{:020b}{:05b}{:07b}'.format(imm, rd, opcode_number)
        case "JAL":
            rd = int(words[1][1:])
            imm = int(words[2])
            imm = int2signedbin(imm, 30)
            opcode_number = int("1101111", 2)
            binary_imm = '{:030b}'.format(imm)[::-1]
            formated_binary_imm = binary_imm[20] + binary_imm[10:0:-1] + binary_imm[11] + binary_imm[19:11:-1]
            bytecode = '{}{:05b}{:07b}'.format(formated_binary_imm, rd, opcode_number)
        case "JALR":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("1100111", 2)
            bytecode = '{:012b}{:05b}{}{:05b}{:07b}'.format(imm, rs1, funct3_map[opcode],rd, opcode_number)
        case "BEQ"|"BNE"|"BLT"|"BGE"|"BLTU"|"BGEU":
            rs1 = int(words[1][1:])
            rs2 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 30)
            opcode_number = int("1100011", 2)
            binary_imm = '{:030b}'.format(imm)[::-1]
            formated_binary_imm1 = binary_imm[12] + binary_imm[10:4:-1]
            formated_binary_imm2 = binary_imm[4:0:-1] + binary_imm[11]
            bytecode = '{}{:05b}{:05b}{}{}{:07b}'.format(formated_binary_imm1, rs2, rs1, funct3_map[opcode], formated_binary_imm2, opcode_number)
        case "LB"|"LH"|"LW"|"LBU"|"LHU":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("0000011", 2)
            bytecode = '{:012b}{:05b}{}{:05b}{:07b}'.format(imm, rs1, funct3_map[opcode], rd, opcode_number)
        case "SB"|"SH"|"SW":
            rs2 = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("0100011", 2)
            binary_imm = '{:012b}'.format(imm)[::-1]
            formated_binary_imm1 =  binary_imm[11:4:-1]
            formated_binary_imm2 = binary_imm[4::-1]
            bytecode = '{}{:05b}{:05b}{}{}{:07b}'.format(formated_binary_imm1, rs2, rs1, funct3_map[opcode], formated_binary_imm2, opcode_number)
        case "ADDI"|"SLTI"|"SLTIU"|"XORI"|"ORI"|"ANDI":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("0010011", 2)
            bytecode = '{:012b}{:05b}{}{:05b}{:07b}'.format(imm, rs1, funct3_map[opcode], rd, opcode_number)
        case "SLLI"|"SRLI"|"SRAI":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            assert (imm >= 0)
            imm = int2signedbin(imm, 5)
            opcode_number = int("0010011", 2)
            bytecode = '{}{:05b}{:05b}{}{:05b}{:07b}'.format(funct7_map[opcode], imm, rs1, funct3_map[opcode], rd, opcode_number)
        case "ADD"|"SUB"|"MUL"|"SLL"|"SLT"|"SLTU"|"XOR"|"SRL"|"SRA"|"OR"|"AND":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            rs2 = int(words[3][1:])
            opcode_number = int("0110011", 2)
            bytecode = '{}{:05b}{:05b}{}{:05b}{:07b}'.format(funct7_map[opcode], rs2, rs1, funct3_map[opcode], rd, opcode_number)
        case "FADD.S"|"FSUB.S"|"FMUL.S"|"FEQ.S"|"FLT.S"|"FLE.S"|"FMV.X.W"|"FMV.W.X"|"FSGNJ.S"|"FSGNJN.S"|"FSGNJX.S"|"FCVT.S.W":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            rs2 = int(words[3][1:]) if len(words) > 3 else 0
            opcode_number = int("1010011", 2)
            bytecode = '{}{:05b}{:05b}{}{:05b}{:07b}'.format(funct7_map[opcode], rs2, rs1, funct3_map[opcode], rd, opcode_number)
        case "FLW":
            rd = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("0000111", 2)
            bytecode = '{:012b}{:05b}{}{:05b}{:07b}'.format(imm, rs1, funct3_map[opcode], rd, opcode_number)
        case "FSW":
            rs2 = int(words[1][1:])
            rs1 = int(words[2][1:])
            imm = int(words[3])
            imm = int2signedbin(imm, 12)
            opcode_number = int("0100111", 2)
            binary_imm = '{:012b}'.format(imm)[::-1]
            formated_binary_imm1 =  binary_imm[11:4:-1]
            formated_binary_imm2 = binary_imm[4::-1]
            bytecode = '{}{:05b}{:05b}{}{}{:07b}'.format(formated_binary_imm1, rs2, rs1, funct3_map[opcode], formated_binary_imm2, opcode_number)
        case _:
            raise ValueError("Opcode not found: ", opcode)

    print(words)
    print(bytecode)
    assert (len(bytecode) == 32)
    file_w.write(bytecode + "\n")
    counter += 4

file_r = open(file_r_name, 'r')
Lines = file_r.readlines()
for line in Lines:
    process_line(line)
file_r.close()



print(f"Finished decoding from {file_r_name} to {file_w_name}")
input()
