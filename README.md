# VHDL UART Controller (TX & RX)

A robust, fully synchronous **UART (Universal Asynchronous Receiver-Transmitter)** implementation in VHDL, designed for FPGA deployment.  
Tested with a **50 MHz system clock** and **115,200 baud rate**, and fully parameterized for flexible configurations.

---

## Features

- **Parameterized Design**
  - Easily configurable `CLK_FREQ` and `BAUD_RATE` via generics

- **Robust RX Synchronization**
  - Double flip-flop synchronizer to mitigate metastability from asynchronous input

- **Center-Point Sampling**
  - Samples incoming data at the middle of each bit period for improved noise immunity

- **Start Bit Validation (Glitch Filtering)**
  - Confirms valid start bit at half-bit interval to reject noise spikes

- **Standard UART Protocol**
  - 8 data bits, No parity, 1 stop bit (8N1)

- **Clock Counter-Based Timing**
  - No external baud generator required

---

## Architecture Overview

---

### Transmitter (`uart_tx.vhd`)

Converts parallel 8-bit data into serial UART stream.

#### State Machine:

- **IDLE**
  - Line held HIGH
- **START**
  - Sends start bit (LOW)
- **DATA**
  - Sends 8 bits (LSB first)
- **STOP**
  - Sends stop bit (HIGH)

#### Handshake:
- `tx_start` → trigger transmission
- `tx_busy` → indicates active transmission

---

### Receiver (`uart_rx.vhd`)

Converts serial UART stream into parallel 8-bit data.

#### State Machine:

- **IDLE**
  - Waits for falling edge (start bit)
- **START**
  - Waits `CLKS_PER_BIT/2` and validates start bit
- **DATA**
  - Samples each bit at center of bit period
- **STOP**
  - Captures stop bit and asserts `data_valid`

---

## Hardware Parameters

| Parameter        | Value            |
|----------------|------------------|
| Baud Rate       | 115,200 bps      |
| System Clock    | 50 MHz           |
| Bit Duration    | ~8.68 µs         |
| Frame Duration  | ~86.8 µs (10 bits) |
| Target FPGA     | Spartan-7 |

---

## Module Interfaces

```vhdl
-- =========================
-- UART Transmitter
-- =========================
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
end entity;

-- =========================
-- UART Receiver
-- =========================
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
end entity;
