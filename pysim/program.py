from accelerator import Accelerator
from decoder import RiscVDecoder
from executor import RiscVExecutor
from emulators import emulate_int32, signed_to_float
from register import Register

def debug():
    while True:
        cmd = input()
        if len(cmd) > 0:
            exec(f"print({cmd})")
        else:
            break

class Program:

    def __init__(self, file: str) -> None:
        self.pc = 0
        self.jmp_flag = False

        self.reg_int = Register[int]()
        self.reg_fp = Register[float](default_value=0.0)

        self.ram = Register[int](length=1048576, addressing_type="ram")

        self.accelerator = Accelerator(self.ram)

        self.instructions = self.load_instructions(file) # Do not read directly
        self.decoder = RiscVDecoder()
        self.executor = RiscVExecutor(self)

    def load_instructions(self, file: str) -> list[int]:
        f = open(file, 'r').readlines()
        num_instructions = len(f)
        instructions = [0] * num_instructions
        for line_num, line in enumerate(f):
            instruction = int(line, 2)
            instructions[line_num] = instruction
            self.ram[line_num * 4] = instruction

        return instructions

    def load_instructions_on_ram(self, instructions):
        for addr, instruction in enumerate(instructions):
            self.ram[addr * 4] = instruction
    
    def read_instruction(self, addr: int):
        return self.instructions[addr // 4]
    
    def get_PC(self):
        return self.pc
    
    def set_PC(self, PC: int):
        self.pc = emulate_int32(PC)
        self.jmp_flag = True

    def execute_instruction(self):
        
        instruction = self.read_instruction(self.pc)
        decode_dict = self.decoder(instruction)
        # print(self.pc, f"{instruction:032b}", decode_dict)
        self.executor(decode_dict)

        if instruction == 0b11010000000000111000000011010011:
            debug()

        if not self.jmp_flag:
            self.pc += 4
        self.jmp_flag = False

    def run(self, stop_addr:int|None=None):
        if stop_addr is None:
            stop_addr = 4 * (len(self.instructions) - 1)
        
        while self.pc != stop_addr:
            self.execute_instruction()
        
        print("Execution finished with status 0")


if __name__ == "__main__":

    prog = Program("output.txt")

    prog.run(stop_addr=40)

    debug()
    