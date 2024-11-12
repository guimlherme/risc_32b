library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FP_cvtsw is
    port (
        rs1 : in std_logic_vector(31 downto 0);
        fp_result : out std_logic_vector(31 downto 0)
    );
end FP_cvtsw;		

architecture FP_cvtsw_arch of FP_cvtsw is

signal intermediate_exponent : unsigned(7 downto 0);
signal intermediate_radical : unsigned(31 downto 0);
signal intermediate_sign : std_logic;

signal normalized_final_radical : unsigned(31 downto 0);
signal normalized_final_exponent : unsigned(7 downto 0);

signal rs2_sign_op_adjusted : std_logic;

constant zeros : std_logic_vector(31 downto 0) := (others => '0');

begin

-- process(all) -- Unsupported in VHDL 1993
process(rs1, intermediate_exponent, intermediate_radical, intermediate_sign,
normalized_final_radical, rs2_sign_op_adjusted, normalized_final_exponent)

variable trailing_zeros : integer range 0 to 32;
variable stop_counting_trailing_zeros : boolean;

begin

    -- It's all combinatorial

    intermediate_sign <= rs1(31);
    intermediate_radical <= unsigned(abs(signed(rs1))); 
    intermediate_exponent <= to_unsigned(127 + 31, intermediate_exponent'length);
    
    -- Count trailing zeros
    trailing_zeros := 0;
    stop_counting_trailing_zeros := False;
    for i in 31 downto 0 loop
        if (stop_counting_trailing_zeros = False) and (intermediate_radical(i) = '0') then
            trailing_zeros := trailing_zeros + 1;
        elsif intermediate_radical(i) = '1' then
            stop_counting_trailing_zeros := True;
        end if;
    end loop;

    normalized_final_radical <= shift_left(intermediate_radical, trailing_zeros);
    normalized_final_exponent <= intermediate_exponent - trailing_zeros; 
    fp_result <= std_logic_vector(intermediate_sign & normalized_final_exponent & normalized_final_radical(30 downto 8));

end process;


end FP_cvtsw_arch;
