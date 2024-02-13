LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;

LIBRARY work;

entity pipeline_control is
    port(
        data_hazard_SDRAM : in std_logic;
        branching_hazard : in std_logic;

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
begin

pipeline_stall:process(data_hazard_SDRAM)
begin

    -- Default values
    fetch_stall_command <= '0';
    decoder_stall_command <= '0';
    alu_stall_command <= '0';
    memory_stall_command <= '0';

    if data_hazard_SDRAM = '1' then
        fetch_stall_command <= '1';
        decoder_stall_command <= '1';
        alu_stall_command <= '1';
        memory_stall_command <= '1';
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