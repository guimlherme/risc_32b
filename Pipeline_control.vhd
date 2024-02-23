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
        address_alu : in std_logic_vector(4 downto 0);
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
    signal data_hazard_alu : std_logic;
    signal data_hazard_mem : std_logic;
begin

calculate_data_hazard_alu:process(address_alu, address_decoder_1, address_decoder_2)
begin
    if (address_alu=address_decoder_1) or (address_alu=address_decoder_2) then
        data_hazard_alu <= '1';
    else
        data_hazard_alu <= '0';
    end if;
end process calculate_data_hazard_alu;

calculate_data_hazard_mem:process(address_mem, address_decoder_1, address_decoder_2)
begin
    if (address_mem=address_decoder_1) or (address_mem=address_decoder_2) then
        data_hazard_mem <= '1';
    elsif mem_delayed='1' then
        data_hazard_mem <= '1';
    else
        data_hazard_mem <= '0';
    end if;
end process calculate_data_hazard_mem;

pipeline_stall:process(data_hazard_alu, data_hazard_mem)
begin

    -- Default values
    fetch_stall_command <= '0';
    decoder_stall_command <= '0';
    alu_stall_command <= '0';
    memory_stall_command <= '0';

    if data_hazard_mem = '1' then
        fetch_stall_command <= '1';
        decoder_stall_command <= '1';
        alu_stall_command <= '1';
        memory_stall_command <= '1';
    end if;

    if data_hazard_alu = '1' then
        fetch_stall_command <= '1';
        decoder_stall_command <= '1';
        alu_stall_command <= '1';
    end if;
    
end process pipeline_stall;

pipeline_flush:process(branching_hazard)
begin

    -- Default values
    fetch_flush_command <= '0';
    decoder_flush_command <= '0';
    alu_flush_command <= '0';

    if branching_hazard = '1' then
        -- fetch_flush_command <= '1'; -- no need
        decoder_flush_command <= '1';
        alu_flush_command <= '1';
    end if;

end process pipeline_flush;

end pipeline_control_a;