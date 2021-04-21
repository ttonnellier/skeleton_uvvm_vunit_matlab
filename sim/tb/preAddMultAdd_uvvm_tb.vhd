use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_scoreboard;
use bitvis_vip_scoreboard.generic_sb_support_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

library design_library;

entity preAddMultAdd_uvvm_tb is
     generic (
        runner_cfg : string  := "";
        DATA_PATH  : string  := "../data/";
        FILE_IN    : string  := "preAddMultAdd_in.txt";
        FILE_OUT   : string  := "preAddMultAdd_out.txt";
        AWIDTH     : natural := 8;
        BWIDTH     : natural := 8;
        CWIDTH     : natural := 8
    );
end entity;

architecture functional of preAddMultAdd_uvvm_tb is

    -- constants
    constant C_SCOPE      : string := "preAddMultAdd_uvvm_tb.vhd";
    constant C_CLK_PERIOD : time   := 10 ns;
    constant C_DELAY      : time   :=  1 ns;

    -- files
    file golden_data_in  : text open read_mode is DATA_PATH & FILE_IN;
    file golden_data_out : text open read_mode is DATA_PATH & FILE_OUT;

    -- general control signals
    signal clk     : std_logic := '0';
    signal clk_ena : boolean   := false;

    -- internal signals
    signal subadd     : std_logic;
    signal a_in       : std_logic_vector(AWIDTH - 1 downto 0);
    signal b_in       : std_logic_vector(BWIDTH - 1 downto 0);
    signal c_in       : std_logic_vector(CWIDTH - 1 downto 0);
    signal d_in       : std_logic_vector(BWIDTH + CWIDTH downto 0);
    signal p_out      : std_logic_vector(BWIDTH + CWIDTH + 1 downto 0);
    signal p_expected : std_logic_vector(BWIDTH + CWIDTH + 1 downto 0);

    signal process_ena          : boolean := false;
    signal process_checker_over : boolean := false;

    -- scoreboard parameters
    package my_tb_sb_pkg is new bitvis_vip_scoreboard.generic_sb_pkg
    generic map (t_element =>  std_logic_vector(BWIDTH+CWIDTH+1 downto 0),
                 element_match => std_match,
                 to_string_element => to_string);
    --use my_tb_sb_pkg.all;
    shared variable TB_SB : my_tb_sb_pkg.t_generic_sb;

    -- procedures to read from files 
    procedure read_golden_vectors_in(
        signal A_sig, B_sig, C_sig, D_sig : out std_logic_vector;
        signal SUBADD_sig                 : out std_logic
    ) is
        variable current_line: line;
        variable A, B, C, D  : integer;
        variable SUBADD      : std_logic;
    begin
        readline(golden_data_in, current_line);
        while current_line.all(1) = '#' and not endfile(golden_data_in) loop
            readline(golden_data_in, current_line);
        end loop;
        read(current_line, A);
        read(current_line, B);
        read(current_line, C);
        read(current_line, D);
        read(current_line, SUBADD);

        A_sig <= std_logic_vector(to_signed(A, A_sig'length));
        B_sig <= std_logic_vector(to_signed(B, B_sig'length));
        C_sig <= std_logic_vector(to_signed(C, C_sig'length));
        D_sig <= std_logic_vector(to_signed(D, D_sig'length));
        SUBADD_sig <= SUBADD;
    end;

    procedure read_golden_vectors_out(
        signal   P_sig :   out std_logic_vector;
        variable TB_SB : inout my_tb_sb_pkg.t_generic_sb
    ) is
        variable current_line: line;
        variable P           : integer;
    begin
        readline(golden_data_out, current_line);
        while current_line.all(1) = '#' and not endfile(golden_data_out) loop
            readline(golden_data_out, current_line);
        end loop;
        read(current_line, P);
        P_sig <= std_logic_vector(to_signed(P, P_sig'length));
        TB_SB.add_expected(std_logic_vector(to_signed(P, P_sig'length)));
    end;

begin

    p_clk: clock_generator(clk, clk_ena, C_CLK_PERIOD, "tb clock");

    dut: entity design_library.preAddMultAdd generic map (AWIDTH => AWIDTH,
                                                          BWIDTH => BWIDTH,
                                                          CWIDTH => CWIDTH) 
                                             port map (clk    => clk   ,
                                                       subadd => subadd,
                                                       ain    => a_in  ,
                                                       bin    => b_in  ,
                                                       cin    => c_in  ,
                                                       din    => d_in  ,
                                                       pout   => p_out );

    stimulus_generator: process
    begin
        wait until process_ena;
        wait for C_CLK_PERIOD/2;
        while not endfile(golden_data_in) loop
            read_golden_vectors_in(a_in, b_in, c_in, d_in, subadd);
            wait for C_CLK_PERIOD;
        end loop;
        wait;
    end process;

    response_checker: process
    begin
        wait until process_ena;
        wait for 4*C_CLK_PERIOD;
        while not endfile(golden_data_out) loop
            read_golden_vectors_out(p_expected, TB_SB);
            wait for C_DELAY;
            TB_SB.check_received(p_out);
            wait until rising_edge(clk);
        end loop;
        process_checker_over <= true;
        wait;
    end process;

    p_sequencer : process
    begin
        if runner_cfg /= "" then
            test_runner_setup(runner, runner_cfg);
        end if;

        log(ID_LOG_HDR_XL, "TB preAddMultAdd_uvvm_tb", C_SCOPE);
        set_alert_stop_limit(ERROR, 0); -- continue on errors

        TB_SB.set_scope("SB preAddMultAdd");
        
        log(ID_LOG_HDR, "Set configuration", C_SCOPE);
        TB_SB.config(C_SB_CONFIG_DEFAULT, "Set config for SB UART");

        log(ID_LOG_HDR, "Enable SB", C_SCOPE);
        TB_SB.enable(VOID);
        TB_SB.enable_log_msg(ID_DATA);

        clk_ena <= true;

        log(ID_LOG_HDR_LARGE, "Launch processes read and compare", C_SCOPE);
        process_ena <= true;

        wait until process_checker_over;

        TB_SB.report_counters(VOID);

        -- end of the simulation
        wait for 10*C_CLK_PERIOD;
        report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
        
        set_alert_stop_limit(ERROR, 1); -- stop if errors found
        
        log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
        if runner_cfg /= "" then
          test_runner_cleanup(runner);
        else
          std.env.finish; --stop
        end if;

        wait;
    end process;

end architecture;