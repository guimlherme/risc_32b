
hextobinary = {
    "0": "0000",
    "1": "0001",
    "2": "0010",
    "3": "0011",
    "4": "0100",
    "5": "0101",
    "6": "0110",
    "7": "0111",
    "8": "1000",
    "9": "1001",
    "A": "1010",
    "B": "1011",
    "C": "1100",
    "D": "1101",
    "E": "1110",
    "F": "1111",
    "\n": "\n",
}

def invert_instruction_endianness(hex_instruction: str):
    return hex_instruction[6:8] + hex_instruction[4:6] + hex_instruction[2:4] + hex_instruction[0:2]


def binary_to_str(binary_file_path, str_file_path):
    """
    Converts a binary file to a string file.

    Parameters:
    - binary_file_path: str, the path to the binary file to read.
    - str_file_path: str, the path to the output str file to write.
    """
    try:
        # Open the binary file in read-binary mode
        with open(binary_file_path, 'rb') as bin_file:
            # Read the entire binary file content
            binary_str = bin_file.read()

        # Convert binary data to a hexadecimal string
        hex_data = binary_str.hex('\n', 4).upper().split('\n')

        hex_data_bigendian = "\n".join([invert_instruction_endianness(h) for h in hex_data])

        binary_str = map(lambda x: hextobinary[x], hex_data_bigendian)

        # Open the hex file in write mode
        with open(str_file_path, 'w') as str_file:
            # Write the hex data in uppercase and split into lines if desired
            str_file.write("".join(binary_str))

        print(f"Successfully converted {binary_file_path} to {str_file_path}")
    
    

    except FileNotFoundError:
        print(f"File not found: {binary_file_path}")
    except IOError as e:
        print(f"Error reading or writing file: {e}")


if __name__ == "__main__":
    binary_file = "input.bin"
    str_file = "output.txt"
    binary_to_str(binary_file, str_file)
