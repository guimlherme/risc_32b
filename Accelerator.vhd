library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accelerator is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        enable       : in  std_logic;
        funct3       : in  std_logic_vector(2 downto 0);
        imm          : in  std_logic_vector(31 downto 0);

        addr1         : out  std_logic_vector(31 downto 0); -- Address to memory
        data1         : in  std_logic_vector(31 downto 0); -- Data input

        addr2         : out  std_logic_vector(31 downto 0); -- Address to memory
        data2         : in  std_logic_vector(31 downto 0); -- Data input

        addr3         : out  std_logic_vector(31 downto 0); -- Address to memory
        data3         : in  std_logic_vector(31 downto 0); -- Data input

        addr4         : out  std_logic_vector(31 downto 0); -- Address to memory
        data4         : in  std_logic_vector(31 downto 0); -- Data input

        mem_write    : out std_logic;
        addr_out     : out std_logic_vector(31 downto 0);
        data_out     : out std_logic_vector(31 downto 0) -- Data output
    );
end accelerator;

architecture accelerator_arch of accelerator is

    signal acc1 : std_logic_vector(31 downto 0) := (others => '0');
    signal PA, PB : unsigned(31 downto 0) := (others => '0');

    signal acc1_radical : unsigned(23 downto 0);
    signal acc1_exponent : unsigned(7 downto 0);
    signal acc1_sign : std_logic;

    signal maccsum : std_logic_vector(31 downto 0) := (others => '0');
    signal maccsum_radical : unsigned(23 downto 0);
    signal maccsum_exponent : unsigned(7 downto 0);
    signal maccsum_sign : std_logic;

    signal mul1 : std_logic_vector(31 downto 0) := (others => '0');
    signal mul1_radical : unsigned(23 downto 0);
    signal mul1_exponent : unsigned(7 downto 0);
    signal mul1_sign : std_logic;

    signal mul2 : std_logic_vector(31 downto 0) := (others => '0');
    signal mul2_radical : unsigned(23 downto 0);
    signal mul2_exponent : unsigned(7 downto 0);
    signal mul2_sign : std_logic;

    -- signal data1 : std_logic_vector(31 downto 0) := (others => '0');
    signal data1_radical : unsigned(23 downto 0);
    signal data1_exponent : unsigned(7 downto 0);
    signal data1_sign : std_logic;

    -- signal data2 : std_logic_vector(31 downto 0) := (others => '0');
    signal data2_radical : unsigned(23 downto 0);
    signal data2_exponent : unsigned(7 downto 0);
    signal data2_sign : std_logic;

    signal data3_radical : unsigned(23 downto 0);
    signal data3_exponent : unsigned(7 downto 0);
    signal data3_sign : std_logic;

    signal data4_radical : unsigned(23 downto 0);
    signal data4_exponent : unsigned(7 downto 0);
    signal data4_sign : std_logic;


    signal macc_result : std_logic_vector(31 downto 0);
    
    

begin

    mem_write <= '1' when (enable = '1' and funct3="011") else '0';
    addr_out <= imm;
    data_out <= acc1;

    addr1 <= std_logic_vector(PA) when funct3/="110" and funct3/="001" and funct3/="010" else imm; -- SetACC exception
    addr2 <= std_logic_vector(PB);
    
    addr3 <= std_logic_vector(PA + 4);
    addr4 <= std_logic_vector(PB + 4);

    -- FP Signals
    acc1_radical <= unsigned("1" & acc1(22 downto 0));
    acc1_exponent <= unsigned(acc1(30 downto 23));
    acc1_sign <= acc1(31);

    maccsum_radical <= unsigned("1" & maccsum(22 downto 0));
    maccsum_exponent <= unsigned(maccsum(30 downto 23));
    maccsum_sign <= maccsum(31);

    mul1_radical <= unsigned("1" & mul1(22 downto 0));
    mul1_exponent <= unsigned(mul1(30 downto 23));
    mul1_sign <= mul1(31);

    mul2_radical <= unsigned("1" & mul2(22 downto 0));
    mul2_exponent <= unsigned(mul2(30 downto 23));
    mul2_sign <= mul2(31);

    data1_radical <= unsigned("1" & data1(22 downto 0));
    data1_exponent <= unsigned(data1(30 downto 23));
    data1_sign <= data1(31);

    data2_radical <= unsigned("1" & data2(22 downto 0));
    data2_exponent <= unsigned(data2(30 downto 23));
    data2_sign <= data2(31);

    data3_radical <= unsigned("1" & data3(22 downto 0));
    data3_exponent <= unsigned(data3(30 downto 23));
    data3_sign <= data3(31);

    data4_radical <= unsigned("1" & data4(22 downto 0));
    data4_exponent <= unsigned(data4(30 downto 23));
    data4_sign <= data4(31);

    process(clk, reset)
    begin
        if reset = '1' then
            acc1 <= (others => '0');
            PA <= (others => '0');
            PB <= (others => '0');
        elsif rising_edge(clk) then

            -- Default values

            -- mem_write <= '0';
            -- data_out <= (others => '-');

            if enable = '1' then
                case funct3 is
                    when "000" =>  -- Macc
                        acc1 <= macc_result;

                    when "001" =>  -- SetPA
                        PA <= unsigned(data1);
                    
                    when "010" =>  -- SetPB
                        PB <= unsigned(data1);

                    when "011" =>  -- Store
                        -- mem_write <= '1'; -- This is handled outside
                        -- addr_out <= imm;
                        -- data_out <= acc1;
                        acc1 <= (others => '0'); 

                    when "100" =>  -- AddPA
                        PA <= PA + 8;

                    when "101" =>  -- AddPB
                        PB <= PB + 8;

                    when "110" =>  -- SetACC
                        acc1 <= data1;

                    when others =>  -- Other instructions
                        null;
                end case;
            end if;

        end if;
    end process;

FP_acc_inst: entity work.FP_add
port map(
    rs1_exponent => acc1_exponent,
    rs2_exponent => maccsum_exponent,
    rs1_radical => acc1_radical,
    rs2_radical => maccsum_radical,
    rs1_sign => acc1_sign,
    rs2_sign => maccsum_sign,
    add_sub => '0',
    fp_result => macc_result
);

FP_maccsum_inst: entity work.FP_add
 port map(
    rs1_exponent => mul1_exponent,
    rs2_exponent => mul2_exponent,
    rs1_radical => mul1_radical,
    rs2_radical => mul2_radical,
    rs1_sign => mul1_sign,
    rs2_sign => mul2_sign,
    add_sub => '0',
    fp_result => maccsum
);

FP_mul1_inst: entity work.FP_mul
 port map(
    rs1_exponent => data1_exponent,
    rs2_exponent => data2_exponent,
    rs1_radical => data1_radical,
    rs2_radical => data2_radical,
    rs1_sign => data1_sign,
    rs2_sign => data2_sign,
    fp_result => mul1
);

FP_mul2_inst: entity work.FP_mul
 port map(
    rs1_exponent => data3_exponent,
    rs2_exponent => data4_exponent,
    rs1_radical => data3_radical,
    rs2_radical => data4_radical,
    rs1_sign => data3_sign,
    rs2_sign => data4_sign,
    fp_result => mul2
);

end accelerator_arch;
