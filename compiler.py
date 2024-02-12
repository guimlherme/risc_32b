# Python code to convert assembly to machine code

from collections import defaultdict 

funct3_map = {
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
    "SLL" : "001",
    "SLT" : "010",
    "SLTU" : "011",
    "XOR" : "100",
    "SRL" : "101",
    "SRA" : "101",
    "OR" : "110",
    "AND" : "111",
}

funct7_map = defaultdict(lambda: "0000000")
funct7_map.update({
    "SRAI": "0100000",
    "SUB" : "0100000",
    "SRA" : "0100000",
})

def int2signedbin(number, digits):
    if number >= 0:
        return number
    else:
        xor_mask = int("1"*digits, 2)
        two_complement = (abs(number) ^ xor_mask) + 1
        return two_complement


# Using readlines()
file_r = open('input.txt', 'r')
file_w = open('output.txt', 'w')

Lines = file_r.readlines()
gotos = {}
counter = 0
for line in Lines:
    line = line.strip().rstrip("\n").upper()
    words = line.split(' ')
    opcode = words[0]
    if opcode == "":
        continue
    elif opcode[-1] != ":":
        counter += 1
    else:
        gotos[opcode.rstrip(":")] = counter



print("Gotos:", gotos)

file_r = open('input.txt', 'r')
Lines = file_r.readlines()
counter = 0
for line in Lines:
    line = line.strip().rstrip("\n").upper()
    words = line.split(' ')
    words = [w.rstrip().rstrip(',') for w in words]
    print(words)
    opcode = words[0]
    opcode = opcode.upper()

    #Pseudoinstructions
    if opcode == "MOV" or opcode == "MV":
        opcode = "ADDI"
        try:
            int(words[2])
            words = ["ADDI", words[1], "x0", words[2]]
        except ValueError:
            words = ["ADDI", words[1], words[2], "0"]
    elif opcode == "NOP":
        opcode = "ADDI"
        words = ["ADDI", "x0", "x0", "0"]

    if opcode == "":
        continue
    elif opcode[-1] == ":":
        assert(gotos[opcode.rstrip(":")] == counter)
    else:
        match opcode:
            case "LUI":
                rd = int(words[1][1:])
                imm = int(words[2])
                imm = int2signedbin(imm, 20)
                opcode_number = int("0110111", 2)
                bytecode = '{:020b}{:05b}{:07b}'.format(imm, rd, opcode_number)
            case "AUIPC":
                rd = int(words[1][1:])
                imm = int(words[2][1:])
                imm = int2signedbin(imm, 20)
                opcode_number = int("0010111", 2)
                bytecode = '{:020b}{:05b}{:07b}'.format(imm, rd, opcode_number)
            case "JAL":
                rd = int(words[1][1:])
                imm = int(words[2][1:])
                imm = int2signedbin(imm, 30)
                opcode_number = int("0010111", 2)
                binary_imm = '{:030b}'.format(imm)[::-1]
                formated_binary_imm = binary_imm[20] + binary_imm[10:0:-1] + binary_imm[11] + binary_imm[19:11:-1]
                bytecode = '{}{}{}{}{:05b}{:07b}'.format(formated_binary_imm, rd, opcode_number)
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
                rs1 = int(words[1][1:])
                rs2 = int(words[2][1:])
                imm = int(words[3])
                imm = int2signedbin(imm, 12)
                opcode_number = int("0100011", 2)
                binary_imm = '{:012b}'.format(imm)[::-1]
                formated_binary_imm1 =  binary_imm[11:4:-1]
                formated_binary_imm2 = binary_imm[4:-1:-1]
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
            case "ADD"|"SUB"|"SLL"|"SLT"|"SLTU"|"XOR"|"SRL"|"SRA"|"OR"|"AND":
                rd = int(words[1][1:])
                rs1 = int(words[2][1:])
                rs2 = int(words[3][1:])
                opcode_number = int("0110011", 2)
                bytecode = '{}{:05b}{:05b}{}{:05b}{:07b}'.format(funct7_map[opcode], rs2, rs1, funct3_map[opcode], rd, opcode_number)
            # Pseudoinstructions
            case "MOV":
                rd = int(words[1][1:])
                rs1 = int(words[2][1:])
                imm = int(words[3])
                imm = int2signedbin(imm, 12)
                opcode_number = int("0010011", 2)
                bytecode = '{:012b}{:05b}{}{:05b}{:07b}'.format(imm, rs1, funct3_map[opcode],rd, opcode_number)
            


        assert (len(bytecode) == 32)
        file_w.write('Data_Rom({:d}) <= \"{}\";\n'.format(counter,bytecode[0:8]))
        counter += 1
        file_w.write('Data_Rom({:d}) <= \"{}\";\n'.format(counter,bytecode[8:16]))
        counter += 1
        file_w.write('Data_Rom({:d}) <= \"{}\";\n'.format(counter,bytecode[16:24]))
        counter += 1
        file_w.write('Data_Rom({:d}) <= \"{}\";\n'.format(counter,bytecode[24:32]))
        counter += 1




print("Finished decoding")
input()
