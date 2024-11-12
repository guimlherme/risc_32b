library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FP_add is
    port (
        
        rs1_exponent : in unsigned(7 downto 0);
        rs2_exponent : in unsigned(7 downto 0);
        rs1_radical : in unsigned(23 downto 0);
        rs2_radical : in unsigned(23 downto 0);
        rs1_sign     : in std_logic;
        rs2_sign     : in std_logic;
        
        add_sub: in std_logic; -- 0 = add, 1 = sub

        fp_result : out std_logic_vector(31 downto 0)
    );
end FP_add;		

architecture FP_add_arch of FP_add is

signal aligned_rs1_radical : unsigned(24 downto 0); -- Extra space for the overflow bit of the addition
signal aligned_rs2_radical : unsigned(24 downto 0);
signal aligned_exponent : unsigned(7 downto 0);

signal intermediate_radical : unsigned(24 downto 0);
signal intermediate_sign : std_logic;

signal normalized_final_radical : unsigned(24 downto 0);
signal normalized_final_exponent : unsigned(7 downto 0);

signal rs2_sign_op_adjusted : std_logic;

constant zeros : std_logic_vector(31 downto 0) := (others => '0');

begin

-- process(all) -- Unsupported in VHDL 1993
process(add_sub, rs1_exponent, rs2_exponent, rs1_radical, rs2_radical, rs1_sign, rs2_sign,
aligned_rs1_radical, aligned_rs2_radical, aligned_exponent, intermediate_radical, intermediate_sign,
normalized_final_radical, rs2_sign_op_adjusted)

variable exponent_diff : unsigned(7 downto 0);
variable trailing_zeros : integer range 0 to 25;
variable stop_counting_trailing_zeros : boolean;

begin

    -- It's all combinatorial
    
    -- Align mantissas
    if rs1_exponent > rs2_exponent then
        exponent_diff := rs1_exponent - rs2_exponent;
        aligned_rs2_radical <= '0' & shift_right(rs2_radical, to_integer(exponent_diff));
        aligned_rs1_radical <= '0' & rs1_radical;
        aligned_exponent <= rs1_exponent; -- compensates "extra" one from the overflow of the mantissa
    else
        exponent_diff := rs2_exponent - rs1_exponent;
        aligned_rs1_radical <= '0' & shift_right(rs1_radical, to_integer(exponent_diff));
        aligned_rs2_radical <= '0' & rs2_radical;
        aligned_exponent <= rs2_exponent; -- compensates "extra" one from the overflow of the mantissa
    end if;

    rs2_sign_op_adjusted <= rs2_sign xor add_sub;

    -- Perform operation
    if rs1_sign = rs2_sign_op_adjusted then
        intermediate_radical <= aligned_rs1_radical + aligned_rs2_radical;
        intermediate_sign <= rs1_sign;
    else
        if aligned_rs1_radical > aligned_rs2_radical then
            intermediate_radical <= aligned_rs1_radical - aligned_rs2_radical;
            intermediate_sign <= rs1_sign;
        else
            intermediate_radical <= aligned_rs2_radical - aligned_rs1_radical;
            intermediate_sign <= rs2_sign_op_adjusted;
        end if;
    end if;

    -- Count trailing zeros
    trailing_zeros := 0;
    stop_counting_trailing_zeros := False;
    for i in 24 downto 0 loop
        if (stop_counting_trailing_zeros = False) and (intermediate_radical(i) = '0') then
            trailing_zeros := trailing_zeros + 1;
        elsif intermediate_radical(i) = '1' then
            stop_counting_trailing_zeros := True;
        end if;
    end loop;

    -- Adjust to output format
    -- if intermediate_radical(23) = '1' then
    --     fp_result <= std_logic_vector(intermediate_sign & aligned_exponent & intermediate_radical(22 downto 0));
    -- else
    --     fp_result <= std_logic_vector(intermediate_sign & (aligned_exponent - 1) & shift_left(intermediate_radical(22 downto 0), 1));
    -- end if;
    
    normalized_final_radical <= shift_left(intermediate_radical, trailing_zeros);
    -- the +1 compensates for the extra bit inserted to accomodate the addition
    normalized_final_exponent <= aligned_exponent - trailing_zeros + 1; 
    if trailing_zeros > aligned_exponent then
        fp_result <= (others => '0'); -- Underflow
    elsif aligned_exponent = "11111111" and trailing_zeros = 0 then
        fp_result <= (31 => intermediate_sign, others => '1'); -- Overflow
    else
        fp_result <= std_logic_vector(intermediate_sign & normalized_final_exponent & normalized_final_radical(23 downto 1));
    end if;

end process;


end FP_add_arch;
