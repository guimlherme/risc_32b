library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FP_mul is
    port (
        
        rs1_exponent : in unsigned(7 downto 0);
        rs2_exponent : in unsigned(7 downto 0);
        rs1_radical : in unsigned(23 downto 0);
        rs2_radical : in unsigned(23 downto 0);
        rs1_sign     : in std_logic;
        rs2_sign     : in std_logic;

        fp_result : out std_logic_vector(31 downto 0)
    );
end FP_mul;		

architecture FP_mul_arch of FP_mul is

signal extended_intermediate_exponent : unsigned(8 downto 0);

signal intermediate_exponent : unsigned(7 downto 0);
signal intermediate_radical : unsigned(47 downto 0);
signal intermediate_sign : std_logic;

signal normalized_exponent : unsigned(7 downto 0);
signal normalized_radical : unsigned(47 downto 0);

constant bias : unsigned(7 downto 0) := to_unsigned(127, 8);
constant zeros : std_logic_vector(31 downto 0) := (others => '0');


begin

-- process(all) -- Unsupported in VHDL 1993
process(rs1_exponent, rs2_exponent, rs1_radical, rs2_radical, rs1_sign, rs2_sign,
intermediate_exponent, intermediate_radical, intermediate_sign,
normalized_exponent, normalized_radical)

begin

    -- It's all combinatorial
    -- #FIXME: This is more precise than the IEEE recommendation, probably due to extra bits somewhere
    
    -- Add exponents
    extended_intermediate_exponent <= ("0" & rs1_exponent) + ("0" & rs2_exponent) - ("0" & bias);

    if extended_intermediate_exponent(8) = '1' and rs1_exponent(7) = '1' then
        intermediate_exponent <= "11111110"; -- Overflow
    elsif extended_intermediate_exponent(8) = '1' and rs1_exponent(7) = '0' then
        intermediate_exponent <= "00000000"; -- Underflow
    else
        intermediate_exponent <= extended_intermediate_exponent(7 downto 0);
    end if;

    -- Multiply mantissas
    intermediate_radical <= rs1_radical * rs2_radical;

    -- Calculate sign
    intermediate_sign <= rs1_sign xor rs2_sign;

    -- Normalize result
    -- As the MSB of the mantissas is always one, there are two scenarios possible
    if intermediate_radical(47) = '1' then
        normalized_exponent <= intermediate_exponent + 1;
        normalized_radical <= intermediate_radical;
    else
        normalized_exponent <= intermediate_exponent;
        normalized_radical <= shift_left(intermediate_radical, 1);
    end if;

    -- #TODO: Make it work with overflows, subnormal, etc.
    fp_result <= std_logic_vector(intermediate_sign & normalized_exponent & normalized_radical(46 downto 24));

end process;


end FP_mul_arch;
