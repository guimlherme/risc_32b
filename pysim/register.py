from typing import Generic, TypeVar, Union

from emulators import emulate_float32, emulate_int32, signed_to_float, float_to_signed, print_float_bits

T = TypeVar("T", int, float)

def emulate_T(value: T) -> T:
    if isinstance(value, int):
        return emulate_int32(value)
    else:
        return emulate_float32(value)

class Register(Generic[T]):
    def __init__(self, length: int = 32, default_value: T = 0, addressing_type: str = "default") -> None:
        self.length = length
        self.data: list[T] = [default_value] * length
        self.nzdata: list[T] = [default_value] * length
        self.addressing_type = addressing_type
        self.access_counter : int = 0

    def convert_address(self, address: int) -> int:
        address = emulate_int32(address)
        if self.addressing_type == "default":
            return address
        else:
            return address//4

    def __setitem__(self, key: int, value: T) -> None:
        self.access_counter += 1
        addr = self.convert_address(key)
        self.data[addr] = emulate_T(value)
        if value != 0: self.nzdata[addr] = emulate_T(value)

    def __getitem__(self, key: int) -> T:
        self.access_counter += 1
        return self.data[self.convert_address(key)]
