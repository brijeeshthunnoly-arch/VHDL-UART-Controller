library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLK_FREQ  : integer := 50000000;
        BAUD_RATE : integer := 115200
    );
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        tx_start : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        tx_out   : out std_logic;
        tx_busy  : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is

    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;

    signal clk_cnt  : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_cnt  : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0);

begin

process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            state <= IDLE;
            tx_out <= '1';
            tx_busy <= '0';
            clk_cnt <= 0;

        else
            case state is

                when IDLE =>
                    tx_out <= '1';
                    tx_busy <= '0';
                    clk_cnt <= 0;

                    if tx_start = '1' then
                        shift_reg <= data_in;
                        state <= START;
                        tx_busy <= '1';
                    end if;

                when START =>
                    tx_out <= '0';

                    if clk_cnt = CLKS_PER_BIT-1 then
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        state <= DATA;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA =>
                    tx_out <= shift_reg(0);

                    if clk_cnt = CLKS_PER_BIT-1 then
                        clk_cnt <= 0;
                        shift_reg <= '0' & shift_reg(7 downto 1);

                        if bit_cnt = 7 then
                            state <= STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when STOP =>
                    tx_out <= '1';

                    if clk_cnt = CLKS_PER_BIT-1 then
                        clk_cnt <= 0;
                        state <= IDLE;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

            end case;
        end if;
    end if;
end process;

end Behavioral;
