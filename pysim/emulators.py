import struct


def float_to_signed(value: float) -> int:
    packed_value = struct.pack('>f', value)  # big-endian, 32-bit float
    return struct.unpack('>i', packed_value)[0]


def signed_to_float(value: int) -> float:
    packed_value = struct.pack('>i', value)  # big-endian, 32-bit float
    return struct.unpack('>f', packed_value)[0]


def signed_to_unsigned(value):
    return value & 0xFFFFFFFF

def unsigned_to_signed(value):
    if value & 0x80000000:
        return value - 0x100000000
    else:
        return value

def emulate_int32(value: int) -> int:
    # Emulate 32-bit signed

    value = value & 0xFFFFFFFF

    if value >= 0x80000000:
        value -= 0x100000000
    return value


def emulate_float32(value: float) -> float:
    packed_value = struct.pack('>f', value)  # big-endian, 32-bit float
    return struct.unpack('>f', packed_value)[0]

def print_float_bits(value: float):
    value = float_to_signed(value)
    print(f"{value&0xFFFFFFFF:032b}")