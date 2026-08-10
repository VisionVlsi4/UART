# UART Master–Slave RTL Design with 16× Oversampling and Parity

## 📌 Project Overview

This project implements a **UART (Universal Asynchronous Receiver Transmitter)** communication system using **Verilog HDL**.

The design consists of:

* UART Master (Transmitter)
* UART Slave (Receiver)
* Baud Rate Generator
* 16× Oversampling Generator
* Master FSM
* Slave FSM
* Parity Generation
* Parity Checking
* Data Shift Registers
* Testbench for Functional Verification

The UART Master converts parallel data into serial data and transmits it through the `TX` line. The UART Slave receives the serial data through the `RX` line, samples it using **16× oversampling**, checks the parity bit, and reconstructs the original parallel data.

---

# ⚙️ UART Specifications

| Parameter                   | Value                    |
| --------------------------- | ------------------------ |
| System Clock Frequency      | 50 MHz                   |
| System Clock Period         | 20 ns                    |
| Baud Rate                   | 9600 bps                 |
| UART Bit Time               | 104.167 µs               |
| Master Clock Cycles per Bit | 5208 cycles              |
| Oversampling Rate           | 16×                      |
| Oversampling Frequency      | 153.6 kHz                |
| Slave Sampling Clock Cycles | Approximately 325 cycles |
| Data Bits                   | 8                        |
| Start Bits                  | 1                        |
| Parity Bits                 | 1                        |
| Stop Bits                   | 1                        |
| Total Bits per Frame        | 11                       |
| Data Transmission           | LSB First                |
| Parity Support              | Even / Odd               |
| Receiver Sampling           | Center Sampling          |

---

# 🧮 Timing Calculations

## 1. System Clock Period

The system clock frequency is:

50 MHz

Therefore:

Tclk = 1 / 50,000,000

Tclk = 20 ns

Thus, one system clock cycle takes:

**20 ns**

---

## 2. UART Bit Time

The baud rate is:

9600 bits per second

Therefore:

Tbit = 1 / Baud Rate

Tbit = 1 / 9600

Tbit = 104.167 µs

Thus, each UART bit is transmitted for approximately:

**104.167 µs**

---

## 3. Master Clock Cycles per UART Bit

The number of 50 MHz clock cycles required for one UART bit is:

Clock Cycles per Bit = System Clock Frequency / Baud Rate

Clock Cycles per Bit = 50,000,000 / 9600

Clock Cycles per Bit = 5208.33

Therefore, the design uses approximately:

**5208 clock cycles per UART bit**

---

## 4. Receiver Oversampling Calculation

The UART receiver uses **16× oversampling**.

Oversampling Frequency = Baud Rate × 16

Oversampling Frequency = 9600 × 16

Oversampling Frequency = 153600 Hz

The number of system clock cycles required for one oversampling tick is:

Sampling Clock Cycles = 50,000,000 / 153600

Sampling Clock Cycles = 325.52

Therefore, the receiver sampling generator uses approximately:

**325 system clock cycles per sample**

---

## 5. Sampling Position

Since 16× oversampling is used:

```text
1 UART Bit = 16 Sampling Ticks
```

The start bit is verified near its center:

```text
Start Bit Center = 8 Sampling Ticks
```

Each data bit is sampled after:

```text
16 Sampling Ticks
```

This improves the reliability of UART reception.

---

# 🏗️ Overall UART System Block Diagram

```text
                         SYSTEM CLOCK
                            50 MHz
                               │
              ┌────────────────┴────────────────┐
              │                                 │
              ▼                                 ▼
    ┌───────────────────┐             ┌──────────────────────┐
    │ Baud Rate         │             │ Oversampling         │
    │ Generator         │             │ Generator            │
    │                   │             │                      │
    │ 9600 Baud         │             │ 16× Oversampling     │
    │ 5208 Clocks/Bit   │             │ ≈325 Clocks/Sample   │
    └─────────┬─────────┘             └──────────┬───────────┘
              │                                  │
              │ baud_tick                        │ sample_tick
              ▼                                  ▼
    ┌───────────────────┐             ┌──────────────────────┐
    │ UART MASTER / TX  │    TX/RX    │ UART SLAVE / RX      │
    │                   │────────────►│                      │
    │   Master FSM      │             │     Slave FSM        │
    │   Parity Gen      │             │     Parity Check     │
    │   Shift Register  │             │     Shift Register   │
    └─────────┬─────────┘             └──────────┬───────────┘
              │                                  │
              ▼                                  ▼
            TX_OUT                            DATA_OUT
```

---

# 📤 UART Master / Transmitter Block Diagram

The UART Master transmits parallel 8-bit data serially.

```text
                         ┌──────────────────┐
                         │   System Clock   │
                         │      50 MHz      │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ Baud Generator   │
                         │  9600 Baud Rate  │
                         │  5208 Cycles/Bit │
                         └────────┬─────────┘
                                  │
                              baud_tick
                                  │
        data_in ──────────────────┼──────────┐
        data_valid ───────────────┼──────────┤
                                  ▼          ▼
                         ┌─────────────────────────┐
                         │      UART MASTER FSM    │
                         │                         │
                         │ IDLE                    │
                         │ START                   │
                         │ DATA                    │──────► TX
                         │ PARITY                  │
                         │ STOP                    │
                         └────────────┬────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
          ┌──────────────────┐                ┌──────────────────┐
          │ Shift Register   │                │ Parity Generator │
          │    8-bit Data    │                │ Even / Odd       │
          └──────────────────┘                └──────────────────┘
```

---

# 🔄 UART Master FSM

The UART Master uses five states:

```text
IDLE → START → DATA → PARITY → STOP → IDLE
```

## Master FSM State Diagram

```text
                           +-----------+
                           |   IDLE    |
                           |   TX = 1  |
                           +-----+-----+
                                 |
                            data_valid
                                 |
                                 ▼
                           +-----------+
                           |   START   |
                           |   TX = 0  |
                           +-----+-----+
                                 |
                           1 Bit Period
                           5208 Clocks
                                 |
                                 ▼
                           +-----------+
                           |   DATA    |
                           | D0 → D7   |
                           +-----+-----+
                                 |
                            8 Bits Done
                                 |
                                 ▼
                           +-----------+
                           |  PARITY   |
                           | TX = P    |
                           +-----+-----+
                                 |
                           1 Bit Period
                                 |
                                 ▼
                           +-----------+
                           |   STOP    |
                           |   TX = 1  |
                           +-----+-----+
                                 |
                           1 Bit Period
                                 |
                                 ▼
                               IDLE
```

---

# 📤 Master FSM State Description

## 1. IDLE State

* TX line remains HIGH.
* UART Master waits for `data_valid`.
* When `data_valid = 1`, the input data is loaded into the shift register.
* The parity bit is calculated.
* The FSM moves to the START state.

```text
TX = 1
```

---

## 2. START State

* The Master sends a LOW start bit.
* The start bit remains LOW for one UART bit period.

```text
TX = 0
```

Duration:

```text
104.167 µs
```

Master clock cycles:

```text
5208 cycles
```

After one bit time, the FSM moves to the DATA state.

---

## 3. DATA State

* The Master transmits 8 bits.
* Data is transmitted **LSB first**.

Transmission order:

```text
D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7
```

Each data bit is transmitted for:

```text
1 bit time = 104.167 µs
          ≈ 5208 clock cycles
```

After all 8 bits are transmitted, the FSM moves to the PARITY state.

---

## 4. PARITY State

The Master transmits the calculated parity bit.

The parity bit is transmitted after the 8 data bits.

```text
D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → PARITY
```

The parity bit remains on the TX line for one UART bit period.

After transmitting the parity bit, the FSM moves to the STOP state.

---

## 5. STOP State

* The Master transmits a HIGH stop bit.
* The stop bit remains HIGH for one UART bit period.

```text
TX = 1
```

After the stop bit is transmitted, the FSM returns to the IDLE state.

---

# 🔐 Parity Generation

Parity is used for simple error detection during serial communication.

The UART design supports:

* Even Parity
* Odd Parity

---

## Even Parity

For even parity, the total number of `1`s in:

```text
Data Bits + Parity Bit
```

must be even.

The even parity bit is calculated as:

```text
parity_bit = D0 ^ D1 ^ D2 ^ D3 ^ D4 ^ D5 ^ D6 ^ D7
```

### Example

Data:

```text
10110001
```

Number of `1`s = 4

Since the number of `1`s is already even:

```text
Parity Bit = 0
```

---

## Odd Parity

For odd parity, the total number of `1`s in:

```text
Data Bits + Parity Bit
```

must be odd.

The odd parity bit is:

```text
parity_bit = ~(D0 ^ D1 ^ D2 ^ D3 ^ D4 ^ D5 ^ D6 ^ D7)
```

---

# 📥 UART Slave / Receiver Block Diagram

The UART Slave receives serial data and reconstructs the original 8-bit parallel data.

```text
                         ┌──────────────────┐
                         │   System Clock   │
                         │      50 MHz      │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ Oversampling     │
                         │ Generator        │
                         │                  │
                         │ 16× Sampling     │
                         │ ≈325 Cycles/Tick │
                         └────────┬─────────┘
                                  │
                              sample_tick
                                  │
                                  ▼
RX ─────────────────────────►┌─────────────────────────┐
                             │     UART SLAVE FSM      │
                             │                         │
                             │ IDLE                    │
                             │ START                   │
                             │ DATA                    │
                             │ PARITY                  │
                             │ STOP                    │
                             └────────────┬────────────┘
                                          │
                         ┌────────────────┴───────────────┐
                         ▼                                ▼
                ┌──────────────────┐             ┌──────────────────┐
                │ Shift Register   │             │ Parity Checker   │
                │   8-bit Data     │             │ parity_error     │
                └────────┬─────────┘             └──────────────────┘
                         │
                         ▼
                      DATA_OUT
```

---

# 🔄 UART Slave FSM

The UART Slave uses 16× oversampling to accurately sample incoming data.

The FSM consists of five states:

```text
IDLE → START → DATA → PARITY → STOP → IDLE
```

## Slave FSM State Diagram

```text
                           +-----------+
                           |   IDLE    |
                           | Wait RX=0 |
                           +-----+-----+
                                 |
                            RX goes LOW
                                 |
                                 ▼
                           +-----------+
                           |   START   |
                           | Wait for  |
                           | 8 samples |
                           +-----+-----+
                                 |
                          Valid Start Bit
                                 |
                                 ▼
                           +-----------+
                           |   DATA    |
                           | Sample    |
                           | 8 Bits    |
                           +-----+-----+
                                 |
                           8 Bits Done
                                 |
                                 ▼
                           +-----------+
                           |  PARITY   |
                           | Sample P  |
                           | Check P   |
                           +-----+-----+
                                 |
                           Parity Checked
                                 |
                                 ▼
                           +-----------+
                           |   STOP    |
                           | Check RX=1|
                           +-----+-----+
                                 |
                                 ▼
                               IDLE
```

---

# 📥 Slave FSM State Description

## 1. IDLE State

The receiver continuously monitors the RX line.

```text
RX = 1 → Stay in IDLE
RX = 0 → Start Bit Detected
```

When the RX line becomes LOW, the Slave enters the START state.

---

## 2. START State

The receiver waits for approximately half of the start-bit duration.

Since 16× oversampling is used:

```text
Half Bit Time = 8 Sampling Ticks
```

The receiver samples the center of the start bit.

```text
RX = 0 → Valid Start Bit → DATA State
RX = 1 → False Start Bit → IDLE State
```

This prevents noise or glitches from being incorrectly detected as a valid start bit.

---

## 3. DATA State

The Slave receives the 8 data bits.

Each UART bit corresponds to:

```text
16 Sampling Ticks
```

The receiver samples each data bit near its center.

Data reception order:

```text
D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7
```

After receiving all 8 bits, the FSM moves to the PARITY state.

---

## 4. PARITY State

The Slave samples the received parity bit.

The received parity bit is compared with the expected parity calculated from the received 8-bit data.

```text
Received Parity = Expected Parity
```

If both parity values match:

```text
parity_error = 0
```

If both parity values do not match:

```text
parity_error = 1
```

After checking parity, the FSM moves to the STOP state.

---

## 5. STOP State

The receiver checks the stop bit.

Expected value:

```text
RX = 1
```

If the stop bit is valid:

* Received data is transferred to `data_out`.
* `data_valid` is asserted.
* Parity status is available through `parity_error`.
* The Slave returns to the IDLE state.

---

# 📊 UART Frame Format

The UART frame contains **11 bits**.

```text
 ┌───────┬────┬────┬────┬────┬────┬────┬────┬────┬────────┬──────┐
 │ START │ D0 │ D1 │ D2 │ D3 │ D4 │ D5 │ D6 │ D7 │ PARITY │ STOP │
 ├───────┼────┼────┼────┼────┼────┼────┼────┼────┼────────┼──────┤
 │   0   │             8-BIT DATA              │    P     │  1   │
 └───────┴────┴────┴────┴────┴────┴────┴────┴────┴────────┴──────┘
```

Transmission sequence:

```text
START → D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → PARITY → STOP
```

Data is transmitted **LSB first**.

---

# ⏱️ UART Timing Summary

```text
System Clock Frequency        = 50 MHz
System Clock Period           = 20 ns

Baud Rate                     = 9600 bps
UART Bit Time                 = 104.167 µs

Master Cycles per UART Bit    ≈ 5208 cycles

Oversampling Rate             = 16×

Oversampling Frequency        = 153.6 kHz

Slave Sampling Period         ≈ 6.51 µs

Slave Clock Cycles per Sample ≈ 325 cycles

Sampling Ticks per UART Bit   = 16

Start Bit Verification        = 8 sampling ticks

Data Bits                     = 8
Parity Bits                   = 1
Stop Bits                     = 1

Total Frame Length            = 11 bits
```

---

# 🧪 UART Loopback Verification

For simulation, the TX output of the UART Master can be connected directly to the RX input of the UART Slave.

```text
                 UART MASTER                    UART SLAVE

      data_in ───►                           ───► data_out
      data_valid                              data_valid
           │                                      ▲
           │                                      │
           ▼                                      │
      ┌───────────┐        Serial Data       ┌───────────┐
      │   MASTER  │ ───────── TX ─────────►  │   SLAVE   │
      │    FSM    │                           │    FSM    │
      └───────────┘                           └───────────┘
```

The testbench should verify that:

```text
Input Data
    │
    ▼
UART Master
    │
    ▼
Serial TX Data
    │
    ▼
UART Slave
    │
    ▼
Received Data = Original Input Data
```

---

# 🧪 Testbench Verification Steps

The UART testbench should perform the following operations:

1. Generate a **50 MHz clock**.
2. Apply reset to the UART Master and Slave.
3. Provide 8-bit parallel input data.
4. Assert `data_valid`.
5. Wait for the Master to transmit:

   * Start bit
   * 8 data bits
   * Parity bit
   * Stop bit
6. Connect TX to RX for loopback operation.
7. Allow the Slave to detect the start bit.
8. Sample the data using 16× oversampling.
9. Verify the parity bit.
10. Check the stop bit.
11. Compare `data_out` with the original transmitted data.
12. Check the `parity_error` signal.

---

# 📁 Project Structure

```text
UART_Project/
│
├── rtl/
│   ├── uart_top.v
│   ├── uart_master.v
│   ├── uart_slave.v
│   ├── baud_generator.v
│   ├── oversampling_generator.v
│   └── parity_generator.v
│
├── tb/
│   └── uart_tb.v
│
├── waveform/
│   └── uart_simulation.png
│
├── docs/
│   ├── uart_master_block_diagram.png
│   ├── uart_slave_block_diagram.png
│   ├── uart_master_fsm.png
│   └── uart_slave_fsm.png
│
└── README.md
```



---

# 🔮 Future Improvements

The following features can be added in future versions:

* Configurable baud rate.
* Configurable data width.
* Runtime parity selection.
* No-parity mode.
* Multiple stop bits.
* FIFO buffering.
* FPGA hardware implementation.
* Full-duplex UART communication.

---


