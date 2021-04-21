use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library design_library;

entity preAddMultAdd_vunit_tb is
     generic (
        runner_cfg : string  := runner_cfg_default;
        DATA_PATH  : string  := "../data/";
        FILE_IN    : string  := "preAddMultAdd_in.txt";
        FILE_OUT   : string  := "preAddMultAdd_out.txt";
        AWIDTH     : natural := 8;
        BWIDTH     : natural := 8;
        CWIDTH     : natural := 8
    );
end entity;

architecture functional of preAddMultAdd_vunit_tb is

    -- constants
    constant CLK_PERIOD : time   := 10 ns;
    constant DELAY      : time   :=  1 ns;

    -- files
    file golden_data_in : text open read_mode is DATA_PATH & FILE_IN;
    file golden_data_out: text open read_mode is DATA_PATH & FILE_OUT;

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

    signal process_ena         : boolean := false;
    signal process_checker_over: boolean := false;

    -- procedures to read from files 
    procedure read_golden_vectors_in(
        signal A_sig, B_sig, C_sig, D_sig : out std_logic_vector;
        signal SUBADD_sig                 : out std_logic
    ) is
        variable current_line : line;
        variable A, B, C, D   : integer;
        variable SUBADD       : std_logic;
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
        signal   P_sig :   out std_logic_vector
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
    end;

begin

    p_clk: process
    begin
        if not clk_ena then
            clk <= '0';
            wait until clk_ena;
        end if;
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

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
        wait for CLK_PERIOD/2;
        while not endfile(golden_data_in) loop
            read_golden_vectors_in(a_in, b_in, c_in, d_in, subadd);
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process;

    response_checker: process
    begin
        wait until process_ena;
        wait for 4*CLK_PERIOD;
        while not endfile(golden_data_out) loop
            read_golden_vectors_out(p_expected);
            wait for DELAY;
            check_equal(p_expected, p_out, result("for result of preAddMultAddt"));
            wait until rising_edge(clk);
        end loop;
        process_checker_over <= true;
        wait;
    end process;

    p_sequencer : process
    begin
        test_runner_setup(runner, runner_cfg);

        set_stop_level(failure); -- to allow the test to continue on errors
        show(get_logger(default_checker), display_handler, pass);

        clk_ena <= true;
        process_ena <= true;
        info("Process Launched!");

        wait until process_checker_over;

        info("===Summary===" & LF & to_string(get_checker_stat));
        
        test_runner_cleanup(runner);

        wait;
    end process;

end architecture;