from emulators import float_to_signed, signed_to_float, emulate_float32, print_float_bits
from register import Register

class Accelerator:

    def __init__(self, ram : Register[int]) -> None:
        self.pa = 0
        self.pb = 0
        self.acc = 0
        self.ram = ram
    
    def reset_acc(self) -> None:
        self.acc = 0

    def set_pa(self, imm: int) -> None:
        self.pa = self.ram[imm]

    def set_pb(self, imm: int) -> None:
        self.pb = self.ram[imm]

    def add_pa(self) -> None:
        self.pa += 8

    def add_pb(self) -> None:
        self.pb += 8
    
    def macc(self) -> None:
        d1 = signed_to_float(self.ram[self.pa])
        d2 = signed_to_float(self.ram[self.pb])
        d3 = signed_to_float(self.ram[self.pa+4])
        d4 = signed_to_float(self.ram[self.pb+4])
        self.acc += emulate_float32(emulate_float32(d1 * d2) + emulate_float32(d3 * d4))
    
    def store(self, imm: int) -> None:
        self.ram[imm] = float_to_signed(self.acc)
        self.reset_acc()

    def set_acc(self, imm: int) -> None:
        self.acc = signed_to_float(self.ram[imm])