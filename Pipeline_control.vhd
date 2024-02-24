LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

LIBRARY work;

entity pipeline_control is
    port(
        mem_delayed : in std_logic;
        branching_hazard : in std_logic;

        address_decoder_1 : in std_logic_vector(4 downto 0);
        address_decoder_2 : in std_logic_vector(4 downto 0);
        reg_write_flag_decoder : in std_logic;
        address_decoder_write : in std_logic_vector(4 downto 0);
        reg_write_flag_alu : in std_logic;
        address_alu : in std_logic_vector(4 downto 0);
        reg_write_flag_mem : in std_logic;
        address_mem : in std_logic_vector(4 downto 0);
        
        fetch_stall_command : out std_logic;
        decoder_stall_command : out std_logic;
        alu_stall_command : out std_logic;
        memory_stall_command : out std_logic;

        fetch_flush_command : out std_logic;
        decoder_flush_command : out std_logic;
        alu_flush_command : out std_logic
    );
end pipeline_control;

architecture pipeline_control_a of pipeline_control is
    signal data_hazard_decoder : std_logic;
    signal data_hazard_alu : std_logic;
    signal data_hazard_mem : std_logic;
begin

calculate_data_hazard_decoder:process(address_decoder_write, address_decoder_1, address_decoder_2, reg_write_flag_decoder)
begin
    if reg_write_flag_decoder='1' and ((address_decoder_write=address_decoder_1) or (address_decoder_write=address_decoder_2)) then
        data_hazard_decoder <= '1';
    else
        data_hazard_decoder <= '0';
    end if;
end process calculate_data_hazard_decoder;

calculate_data_hazard_alu:process(address_alu, address_decoder_1, address_decoder_2, reg_write_flag_alu)
begin
    if reg_write_flag_alu='1' and ((address_alu=address_decoder_1) or (address_alu=address_decoder_2)) then
        data_hazard_alu <= '1';
    else
        data_hazard_alu <= '0';
    end if;
end process calculate_data_hazard_alu;

calculate_data_hazard_mem:process(address_mem, address_decoder_1, address_decoder_2, mem_delayed)
begin
    if reg_write_flag_mem='1' and ((address_mem=address_decoder_1) or (address_mem=address_decoder_2)) then
        data_hazard_mem <= '1';
    else
        data_hazard_mem <= '0';
    end if;
end process calculate_data_hazard_mem;

pipeline_control_proc:process(data_hazard_decoder, data_hazard_alu, data_hazard_mem, branching_hazard)
begin

    -- Default values
    fetch_stall_command <= '0';
    decoder_stall_command <= '0';
    alu_stall_command <= '0';
    memory_stall_command <= '0';

    fetch_flush_command <= '0';
    decoder_flush_command <= '0';
    alu_flush_command <= '0';

    if mem_delayed = '1' then
        fetch_stall_command <= '1';
        decoder_stall_command <= '1';
        alu_stall_command <= '1';
        memory_stall_command <= '1'; -- Maybe memory flush?
    end if;

    if data_hazard_mem = '1' or data_hazard_alu = '1' or data_hazard_decoder = '1' then
        fetch_stall_command <= '1';
        decoder_flush_command <= '1';
    end if;

    
    if branching_hazard = '1' then
        fetch_stall_command <= '0';
        decoder_flush_command <= '1';
        alu_flush_command <= '1';
    end if;

end process pipeline_control_proc;

end pipeline_control_a;