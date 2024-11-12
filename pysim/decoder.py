from typing import Any

class RiscVDecoder:
    def __init__(self):
        pass

    def sign_extend(self, value, bits):
        sign_bit = 1 << (bits - 1)
        return (value & (sign_bit - 1)) - (value & sign_bit)

    def decode_imm(self, instruction: int, opcode: int):

        # Decode based on opcode
        
        if opcode in [0b1100111, 0b0000011, 0b0010011, 0b0000111]:  # I-type
            imm = (instruction >> 20) & 0xFFF
            return self.sign_extend(imm, 12)

        elif opcode in [0b0100011, 0b0100111]:  # S-type
            imm = ((instruction >> 7) & 0x1F) | ((instruction >> 25) & 0x7F) << 5
            return self.sign_extend(imm, 12)

        elif opcode in [0b1100011]:  # B-type
            imm = ((instruction >> 8) & 0xF) << 1 | ((instruction >> 25) & 0x3F) << 5
            imm |= ((instruction >> 7) & 0x1) << 11 | (instruction >> 31) << 12
            return self.sign_extend(imm, 13)

        elif opcode in [0b0110111, 0b0010111]:  # U-type
            imm = instruction & 0xFFFFF000
            return imm  # Already in upper 20 bits

        elif opcode in [0b1101111]:  # J-type
            imm = ((instruction >> 21) & 0x3FF) << 1 | ((instruction >> 20) & 0x1) << 11
            imm |= ((instruction >> 12) & 0xFF) << 12 | (instruction >> 31) << 20
            return self.sign_extend(imm, 21)  # Jump offsets are multiplied by 2
        
        elif opcode in [0b0001011]:   # Accelerator
            imm = (instruction >> 12) & 0xFFFFF
            return imm
        
        else:  # R-type
            imm = 0 # No immediate

        return imm

    def decode(self, instruction: int):

        decode_dict = {
            "opcode" : instruction & 0x7F,
            "rd" : (instruction >> 7) & 0x1F,
            "funct3" : (instruction >> 12) & 0x07,
            "rs1" : (instruction >> 15) & 0x1F,
            "rs2" : (instruction >> 20) & 0x1F,
            "funct7" : (instruction >> 25) & 0x7F,
        }
        
        opcode = decode_dict["opcode"]
        decode_dict["imm"] = self.decode_imm(instruction, opcode)

        return decode_dict

    def __call__(self, instruction) -> Any:
        return self.decode(instruction)
