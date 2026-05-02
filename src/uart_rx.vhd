library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLK_FREQ  : integer := 50000000;
        BAUD_RATE : integer := 115200
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        rx_in      : in  std_logic;
        data_out   : out std_logic_vector(7 downto 0);
        data_valid : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is

    constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;

    signal clk_cnt  : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_cnt  : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0);

    -- Synchronizer 
    signal rx_meta, rx_sync : std_logic;

begin

-- Double flop synchronizer
process(clk)
begin
    if rising_edge(clk) then
        rx_meta <= rx_in;
        rx_sync <= rx_meta;
    end if;
end process;

process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            state <= IDLE;
            data_valid <= '0';
            clk_cnt <= 0;

        else
            

            case state is

                when IDLE =>
                    clk_cnt <= 0;
                    data_valid <= '0';
                    if rx_sync = '0' then
                        state <= START;
                    end if;

                when START =>
                    -- sample in middle of start bit
                    if clk_cnt = CLKS_PER_BIT/2 then
                        if rx_sync = '0' then
                            clk_cnt <= 0;
                            bit_cnt <= 0;
                            state <= DATA;
                        else
                            state <= IDLE;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA =>
                    if clk_cnt = CLKS_PER_BIT-1 then
                        clk_cnt <= 0;
                        shift_reg <= rx_sync & shift_reg(7 downto 1);

                        if bit_cnt = 7 then
                            state <= STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when STOP =>
                    if clk_cnt = CLKS_PER_BIT-1 then
                        data_out <= shift_reg;
                        data_valid <= '1';
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
