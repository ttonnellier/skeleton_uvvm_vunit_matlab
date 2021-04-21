library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity preAddMultAdd is
    generic(
        AWIDTH : natural := 12;
        BWIDTH : natural := 16;
        CWIDTH : natural := 17
    );
    port(
        clk     : in  std_logic;
        subadd  : in  std_logic;
        ain     : in  std_logic_vector(AWIDTH - 1 downto 0);
        bin     : in  std_logic_vector(BWIDTH - 1 downto 0);
        cin     : in  std_logic_vector(CWIDTH - 1 downto 0);
        din     : in  std_logic_vector(BWIDTH + CWIDTH downto 0);
        pout    : out std_logic_vector(BWIDTH + CWIDTH +1 downto 0);
        d_valid : out std_logic
    );
end preAddMultAdd;


architecture rtl of preAddMultAdd is
    signal subadd_d           : std_logic;
    signal a                  : signed(AWIDTH - 1 downto 0);
    signal b                  : signed(BWIDTH - 1 downto 0);
    signal c, c_d             : signed(CWIDTH - 1 downto 0);
    signal add                : signed(BWIDTH downto 0);
    signal d, d_d, d_dd, mult : signed(BWIDTH + CWIDTH downto 0);
    signal p                  : signed(BWIDTH + CWIDTH + 1 downto 0);
begin
    
    assert BWIDTH >= AWIDTH report "Size not supported." severity error;

    process(clk)
    begin
        if rising_edge(clk) then
            a    <= signed(ain);
            b    <= signed(bin);
            c    <= signed(cin);
            d    <= signed(din);
            
            -- delays
            c_d  <= c;
            d_d  <= d;
            d_dd <= d_d;

            subadd_d <= subadd;
            if subadd_d = '1' then
                add <= resize(a, BWIDTH + 1) - resize(b, BWIDTH + 1);
            else
                add <= resize(a, BWIDTH + 1) + resize(b, BWIDTH + 1);
            end if;
            mult <= add * c_d;
            p    <= resize(mult, p'length) + resize(d_dd, p'length);
        end if;
    end process;

    pout <= std_logic_vector(p);
end;