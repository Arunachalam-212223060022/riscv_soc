<div align="center">

# RTL Source — RISC-V RV32I SoC

**A complete 32-bit RISC-V processor built from scratch in synthesisable Verilog**
**CPU Core · Memories · Seven Peripherals · Single-Cycle · Memory-Mapped I/O**

[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-blue?style=for-the-badge)](https://riscv.org/)
[![Instructions](https://img.shields.io/badge/Instructions-37%20RV32I-blueviolet?style=for-the-badge)](#instruction-set--rv32i-37-instructions)
[![Clock](https://img.shields.io/badge/Target%20Clock-100%20MHz-orange?style=for-the-badge)](#synthesis--timing-constraints)
[![Memory](https://img.shields.io/badge/Memory-16%20KB%20Total-green?style=for-the-badge)](#memory-subsystem--memory)
[![Peripherals](https://img.shields.io/badge/Peripherals-7%20IPs-red?style=for-the-badge)](#peripherals--peripheral)
[![DRC](https://img.shields.io/badge/DRC-0%20Violations-brightgreen?style=for-the-badge)](../fpga/README.md)

</div>

---

## Table of Contents

1. [Overview](#1-overview)
2. [RTL Variants](#2-rtl-variants)
3. [Repository Structure](#3-repository-structure)
4. [SoC Top Level — `soc_top.v`](#4-soc-top-level--soc_topv)
   - 4.1 [Power-On Reset](#41-power-on-reset)
   - 4.2 [Address Map](#42-address-map)
   - 4.3 [Read-Back Mux](#43-read-back-mux)
5. [CPU Core — `cpu/`](#5-cpu-core--cpu)
   - 5.1 [Program Counter](#51-program-counter--pcv)
   - 5.2 [Register File](#52-register-file--regfilev)
   - 5.3 [Immediate Generator](#53-immediate-generator--immgenv)
   - 5.4 [Control Unit](#54-control-unit--controlv)
   - 5.5 [ALU Control](#55-alu-control--alu_ctrlv)
   - 5.6 [ALU](#56-alu--aluv)
   - 5.7 [PC Update Logic](#57-pc-update-logic)
   - 5.8 [Branch Conditions](#58-branch-conditions)
   - 5.9 [Store Byte-Enables](#59-store-byte-enables)
6. [Memory Subsystem — `memory/`](#6-memory-subsystem--memory)
7. [Peripherals — `peripheral/`](#7-peripherals--peripheral)
8. [Top-Level Ports](#8-top-level-ports)
9. [Instruction Set — RV32I](#9-instruction-set--rv32i-37-instructions)
10. [Synthesis & Timing Constraints](#10-synthesis--timing-constraints)
11. [Simulation & Testbench](#11-simulation--testbench)

---

## 1. Overview

This directory contains the complete synthesisable RTL for a **RISC-V RV32I System-on-Chip**. Every module — from the program counter to the I2C master — was written from scratch with no pre-built IP. The design implements the full base integer instruction set (37 instructions) in a **single-cycle, non-pipelined architecture**: every instruction, including loads, stores, branches, and jumps, completes in exactly one clock cycle.

| Parameter | Value |
|-----------|-------|
| **ISA** | RISC-V RV32I — 37 instructions |
| **Architecture** | Single-cycle (non-pipelined) |
| **Target clock** | 100 MHz |
| **Instruction memory** | 8 KB (2048 × 32-bit ROM) |
| **Data memory** | 8 KB (2048 × 32-bit SRAM, byte-addressable) |
| **Total on-chip memory** | 16 KB |
| **Peripherals** | UART · GPIO · Timer · INTC · SPI · I2C · Seg7 |
| **Bus type** | Custom memory-mapped, combinational address decode |
| **Reset** | Active-low asynchronous, 256-cycle power-on reset |

---

## 2. RTL Variants

Two functionally identical RTL versions exist to accommodate tool-specific requirements:

| Version | Location | Tools | Key Difference |
|---------|----------|-------|----------------|
| **Original** | `rtl/` | Vivado · VCS/Verdi · XSim | Uses SystemVerilog `logic` net type |
| **Wire-fixed** | `synthesis/genus/rtl/` | Cadence Genus · NCLaunch | All `logic` replaced with `wire` |

Cadence tools in Verilog-2001 mode do not accept `logic` as a net type. The wire-fixed version is also extended with SPI, I2C, and Seg7 for the complete ASIC demonstration. The RTL logic is **bit-for-bit identical** between both versions.

```verilog
// Original rtl/           →    // Wire-fixed synthesis/genus/rtl/
logic branch_taken;        →    wire  branch_taken;
logic [31:0] alu_result;   →    wire  [31:0] alu_result;
// reg declarations remain unchanged in both versions
```

---

## 3. Repository Structure

```
rtl/
├── soc_top.v               ← Full SoC: CPU + memories + all peripherals wired together
├── soc_top_demo.v          ← Same SoC wired for the Spartan-7 Boolean FPGA demo board
│
├── cpu/
│   ├── cpu_top.v           ← Structural wrapper: connects all 6 CPU sub-modules
│   ├── pc.v                ← Program counter (32-bit, resets to 0x0)
│   ├── regfile.v           ← 32 × 32-bit register file (x0 hardwired to 0)
│   ├── immgen.v            ← Immediate extractor (5 RV32I formats, sign-extended)
│   ├── control.v           ← Instruction decoder — opcode → 11 control signals
│   ├── alu_ctrl.v          ← ALU operation selector (funct3/funct7 → alu_sel)
│   └── alu.v               ← 32-bit ALU (10 operations + zero flag)
│
├── memory/
│   ├── imem.v              ← 8 KB instruction ROM (async read, $readmemh init)
│   └── dmem.v              ← 8 KB data SRAM (sync write, async read, byte-lane WE)
│
└── peripheral/
    ├── uart.v              ← Full-duplex UART (115200 baud default, IRQ)
    ├── gpio.v              ← 8-bit GPIO (output register + input register)
    ├── timer.v             ← Countdown timer (auto-reload, IRQ)
    ├── intc.v              ← 4-source priority interrupt controller
    ├── spi.v               ← SPI master (CPOL/CPHA modes, IRQ)
    ├── i2c.v               ← I2C master (9-state FSM, open-drain, IRQ)
    └── seg7_ctrl.v         ← Dual 4-digit 7-segment display driver (multiplexed)
```

---

## 4. SoC Top Level — `soc_top.v`

`soc_top.v` contains almost no logic of its own. Its job is to **instantiate every module and wire them all together** — the structural glue that defines what the chip contains and how everything connects. Think of it as the PCB schematic for the entire SoC.

The data path through the SoC on every instruction cycle:

```
CPU (cpu_top)
    │
    │  dbus_addr[31:0]
    │  dbus_wdata[31:0]
    │  dbus_we[3:0]
    │  dbus_re
    ▼
Address Decoder (combinational)
    │
    ├──► DMEM  (0x0000_2000)
    ├──► UART  (0x1000_0000)
    ├──► GPIO  (0x2000_0000)
    ├──► Seg7  (0x2000_0100)
    ├──► Timer (0x3000_0000)
    ├──► INTC  (0x4000_0000)
    ├──► SPI   (0x5000_0000)
    └──► I2C   (0x6000_0000)
    │
    ▼
Read-back Mux → dbus_rdata[31:0] → CPU
```

---

### 4.1 Power-On Reset

After power-up, the SoC holds everything in reset for **256 clock cycles** before the CPU starts executing. This guarantees all flip-flops and registers across every peripheral initialise to known values before the first instruction fetch.

```verilog
reg [7:0] por_cnt;
// CPU only runs when POR counter has saturated AND external reset is released
wire rst_n_int = por_cnt[7] & rst_n;

always @(posedge clk)
    if (!por_cnt[7]) por_cnt <= por_cnt + 1;
```

`por_cnt[7]` goes high after 128 increments — at 100 MHz this is a **1.28 µs** startup delay, more than enough for clocks and I/O to stabilise.

---

### 4.2 Address Map

The CPU talks to every peripheral by reading and writing specific memory addresses — no special CPU instructions needed. A combinational decoder checks the upper address bits and asserts the chip-select for the correct module.

| Base Address | Module | Region Size | Description |
|-------------|--------|-------------|-------------|
| `0x0000_0000` | IMEM | 8 KB | Program code — CPU fetches instructions from here |
| `0x0000_2000` | DMEM | 8 KB | Variables, stack, heap |
| `0x1000_0000` | UART | 16 B | Serial port registers |
| `0x2000_0000` | GPIO | 16 B | LED output and switch input registers |
| `0x2000_0100` | Seg7 | 4 B | 7-segment display register |
| `0x3000_0000` | Timer | 16 B | Countdown timer registers |
| `0x4000_0000` | INTC | 16 B | Interrupt controller registers |
| `0x5000_0000` | SPI | 16 B | SPI master registers |
| `0x6000_0000` | I2C | 16 B | I2C master registers |

---

### 4.3 Read-Back Mux

Only one peripheral can drive the CPU data bus at a time. A combinational priority chain selects the active peripheral's read data. All unselected peripherals return `32'h0`:

```verilog
assign dbus_rdata = dmem_sel  ? dmem_rdata  :
                    uart_sel  ? uart_rdata  :
                    gpio_sel  ? gpio_rdata  :
                    timer_sel ? timer_rdata :
                    intc_sel  ? intc_rdata  :
                    spi_sel   ? spi_rdata   :
                    i2c_sel   ? i2c_rdata   :
                    seg7_sel  ? seg7_rdata  :
                                32'h0;
```

---

## 5. CPU Core — `cpu/`

The CPU is decomposed into six cooperating modules. `cpu_top.v` is a **pure structural wrapper** — it contains no logic, only wire declarations connecting the sub-modules. Every instruction is fetched, decoded, executed, and written back in a single clock cycle.

```
  ┌──────────────────────────────────────────────────────┐
  │                    cpu_top.v                         │
  │                                                      │
  │  PC → IMEM → ImmGen ──────────────────────────────┐  │
  │   ↑           │                                   │  │
  │   │         Decode                                │  │
  │   │     (control.v)                               │  │
  │   │           │                                   ▼  │
  │   │         RegFile → ALU Ctrl → ALU → Writeback  │  │
  │   │        (regfile.v)(alu_ctrl)(alu.v)    │      │  │
  │   │                                        │      │  │
  │   └──────────── pc_next ◄──────────────────┘      │  │
  │                                                   │  │
  │                              dbus_addr/wdata/rdata│  │
  └───────────────────────────────────────────────────┘  │
                                                          │
                                              To soc_top bus
```

---

### 5.1 Program Counter — `pc.v`

A single 32-bit register holding the byte address of the currently executing instruction. Resets synchronously to `0x0000_0000` on active-low reset. Every clock edge it advances to `pc_next`, which is computed combinationally in `cpu_top` based on the instruction type.

```verilog
always @(posedge clk or negedge rst_n)
    if (!rst_n) pc_out <= 32'h0000_0000;
    else        pc_out <= pc_next;
```

---

### 5.2 Register File — `regfile.v`

32 general-purpose 32-bit registers (x0–x31). Two registers can be read simultaneously in the same cycle (combinational, zero latency). Writes are clocked — the result is committed on the next rising edge.

**x0 is hardwired to zero** — reads always return `0`, writes are silently discarded:

```verilog
// Combinational read — x0 always returns 0
assign rs1_data = (rs1 == 5'h0) ? 32'h0 : regs[rs1];
assign rs2_data = (rs2 == 5'h0) ? 32'h0 : regs[rs2];

// Synchronous write — write-enable guards x0
always @(posedge clk)
    if (we && rd != 5'h0) regs[rd] <= wdata;
```

---

### 5.3 Immediate Generator — `immgen.v`

Many RV32I instructions embed a constant directly in their 32-bit encoding. The constant bits are scattered across five different scrambled layouts depending on instruction type. This module extracts and reassembles the correct bits, then sign-extends the result to 32 bits.

| Format | Used By | Source Bits |
|--------|---------|-------------|
| **I-type** | ADDI, LW, JALR, LB, LH, etc. | `instr[31:20]`, sign-extended |
| **S-type** | SW, SH, SB | `instr[31:25]` ++ `instr[11:7]`, sign-extended |
| **B-type** | BEQ, BNE, BLT, BGE, BLTU, BGEU | `instr[31,7,30:25,11:8]` ++ `1'b0` |
| **U-type** | LUI, AUIPC | `instr[31:12]` << 12 |
| **J-type** | JAL | `instr[31,19:12,20,30:21]` ++ `1'b0` |

B-type and J-type force the lowest bit to `0` because branch and jump targets are always 4-byte aligned (odd addresses are illegal in RV32I).

---

### 5.4 Control Unit — `control.v`

Reads the 7-bit opcode field (`instr[6:0]`) and asserts 11 independent control signals that drive every mux and enable in the datapath. Purely combinational — one `case` statement, no registers, no clock.

| Signal | Width | Effect When Asserted |
|--------|-------|---------------------|
| `reg_write` | 1 | Write result back to the register file |
| `alu_src` | 1 | ALU second operand comes from the immediate (not rs2) |
| `mem_read` | 1 | Read from data memory this cycle (load instruction) |
| `mem_write` | 1 | Write to data memory this cycle (store instruction) |
| `mem_to_reg` | 1 | Register write-back data comes from memory (load result) |
| `branch` | 1 | This is a conditional branch — evaluate the branch condition |
| `jal` | 1 | Unconditional PC-relative jump (JAL) |
| `jalr` | 1 | Unconditional register-based jump (JALR) |
| `lui` | 1 | Load upper immediate directly into register |
| `auipc` | 1 | Load PC + upper immediate into register |
| `alu_op[1:0]` | 2 | Hint to ALU control: ADD-forced / SUB-forced / decode funct3 |

**Opcode → control signal mapping:**

| Opcode | Type | `reg_write` | `alu_src` | `mem_read` | `mem_write` | `branch` | `jal` | `jalr` | `lui` | `auipc` | `alu_op` |
|--------|------|:-----------:|:---------:|:----------:|:-----------:|:--------:|:-----:|:------:|:-----:|:-------:|:--------:|
| `0110011` | R-type | ✓ | — | — | — | — | — | — | — | — | 10 |
| `0010011` | I-ALU | ✓ | ✓ | — | — | — | — | — | — | — | 10 |
| `0000011` | Load | ✓ | ✓ | ✓ | — | — | — | — | — | — | 00 |
| `0100011` | Store | — | ✓ | — | ✓ | — | — | — | — | — | 00 |
| `1100011` | Branch | — | — | — | — | ✓ | — | — | — | — | 01 |
| `1101111` | JAL | ✓ | — | — | — | — | ✓ | — | — | — | — |
| `1100111` | JALR | ✓ | ✓ | — | — | — | — | ✓ | — | — | — |
| `0110111` | LUI | ✓ | — | — | — | — | — | — | ✓ | — | — |
| `0010111` | AUIPC | ✓ | — | — | — | — | — | — | — | ✓ | — |

---

### 5.5 ALU Control — `alu_ctrl.v`

Translates the control unit's 2-bit `alu_op` hint plus the instruction's `funct3` and `funct7[5]` fields into a 4-bit `alu_sel` that drives the ALU.

| `alu_op` | Meaning | `alu_sel` Result |
|----------|---------|-----------------|
| `00` | Force ADD | Always `0000` — used by load/store: `addr = base + offset` |
| `01` | Force SUB | Always `0001` — used by branches: compare by subtracting |
| `10` | Decode | Decode from `funct3` / `funct7[5]` — R-type and I-ALU instructions |

For `alu_op = 10`, bit `funct7[5]` is the critical disambiguation bit: it distinguishes ADD from SUB (same `funct3 = 000`) and SRL from SRA (same `funct3 = 101`).

---

### 5.6 ALU — `alu.v`

Executes 10 operations on two 32-bit operands based on the 4-bit `alu_sel`. Also produces a `zero` flag (`result == 0`) used by the branch logic.

| `alu_sel` | Operation | Expression |
|-----------|-----------|------------|
| `0000` | ADD | `a + b` |
| `0001` | SUB | `a - b` |
| `0010` | AND | `a & b` |
| `0011` | OR | `a \| b` |
| `0100` | XOR | `a ^ b` |
| `0101` | SLL | `a << b[4:0]` (zero-fill) |
| `0110` | SRL | `a >> b[4:0]` (zero-fill) |
| `0111` | SRA | `a >>> b[4:0]` (sign-extend) |
| `1000` | SLT | `(signed(a) < signed(b)) ? 1 : 0` |
| `1001` | SLTU | `(a < b) ? 1 : 0` (unsigned) |

---

### 5.7 PC Update Logic

Each clock cycle, `cpu_top` selects the next PC from four candidates via a priority mux:

```verilog
assign pc_next =
    jalr         ? (rs1_data + imm) & ~32'h1  // JALR: reg+offset, bit[0] forced 0
  : jal          ? pc + imm                    // JAL:  PC-relative unconditional jump
  : branch_taken ? pc + imm                    // Branch taken: PC-relative signed offset
  :                pc + 32'd4;                 // Default: sequential fetch (PC+4)
```

JALR clears bit 0 of the target address to enforce 4-byte alignment, as required by the RISC-V specification.

---

### 5.8 Branch Conditions

All six RISC-V conditional branch types are decoded from `funct3`. The ALU computes `rs1 - rs2` and the branch unit examines the `zero` flag and sign bits:

| `funct3` | Instruction | Condition Checked |
|----------|-------------|-------------------|
| `000` | BEQ | `rs1 == rs2` (zero flag set) |
| `001` | BNE | `rs1 != rs2` (zero flag clear) |
| `100` | BLT | `rs1 < rs2` (signed comparison) |
| `101` | BGE | `rs1 >= rs2` (signed comparison) |
| `110` | BLTU | `rs1 < rs2` (unsigned comparison) |
| `111` | BGEU | `rs1 >= rs2` (unsigned comparison) |

---

### 5.9 Store Byte-Enables

The CPU can write 1, 2, or 4 bytes to memory without disturbing the remaining bytes in the same word. The 4-bit `dbus_we` byte-enable mask is generated from `funct3` and the two LSBs of the effective address:

| Instruction | `funct3` | `dbus_we` | Bytes Written |
|-------------|----------|-----------|---------------|
| SB | `000` | `4'b0001 << addr[1:0]` | 1 byte at offset |
| SH | `001` | `4'b0011 << addr[1:0]` | 2 bytes at offset |
| SW | `010` | `4'b1111` | All 4 bytes |

```verilog
assign dbus_we = mem_write ? (
    (funct3 == 3'b000) ? (4'b0001 << alu_result[1:0]) :  // SB
    (funct3 == 3'b001) ? (4'b0011 << alu_result[1:0]) :  // SH
                          4'b1111                         // SW
) : 4'b0000;
```

---

## 6. Memory Subsystem — `memory/`

### `imem.v` — Instruction Memory

8 KB read-only program store (2048 × 32-bit words). The CPU fetches one instruction per cycle with **zero wait states** — the read is combinational (asynchronous), so the instruction is available within the same clock cycle as the fetch address.

- Initialised from `program.mem` using `$readmemh` at simulation/elaboration time
- Address bits `[1:0]` are ignored — all instructions are 4-byte word-aligned
- `assign data = mem[addr[12:2]]` — shifts the byte address to a word index

---

### `dmem.v` — Data Memory

8 KB byte-addressable SRAM (2048 × 32-bit words). Reads are combinational (asynchronous); writes are synchronous (clocked). The 4-bit byte-lane write-enable natively supports SB, SH, and SW without any external logic:

```verilog
always @(posedge clk) begin
    if (we[0]) mem[idx][7:0]   <= wdata[7:0];   // byte lane 0
    if (we[1]) mem[idx][15:8]  <= wdata[15:8];  // byte lane 1
    if (we[2]) mem[idx][23:16] <= wdata[23:16]; // byte lane 2
    if (we[3]) mem[idx][31:24] <= wdata[31:24]; // byte lane 3
end
```

Each byte lane is independently enabled, so `SB` and `SH` write exactly 1 or 2 bytes without disturbing neighbours in the same word.

---

## 7. Peripherals — `peripheral/`

All peripherals share a common bus interface: `addr[3:0]` selects a register within the peripheral, `wdata[31:0]` / `rdata[31:0]` carry data, and `we` is the write enable (driven by the address decoder in `soc_top`). Each peripheral also outputs an optional `irq` line to the interrupt controller.

---

### `uart.v` — Serial Communication

Full-duplex UART with independent TX and RX state machines, configurable baud rate divisor, mid-bit RX sampling, 2-stage synchroniser on RX input, and IRQ generation.

**Register Map (base `0x1000_0000`):**

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| `0x0` | TX_DATA | W | Write a byte to transmit. Ignored if `tx_busy = 1` |
| `0x4` | STATUS | R | `[0]` = `tx_busy` — poll before writing the next byte |
| `0x8` | RX_DATA | R | `[7:0]` = received byte · `[8]` = `rx_ready` flag |
| `0xC` | BAUD_DIV | R/W | Baud rate divisor. Default `868` → 115200 baud @ 100 MHz |

**Baud rate formula:** `BAUD_DIV = (clock_freq / baud_rate) - 1`

**TX operation:** Writing to TX_DATA loads a 10-bit shift register `{1'b1, data[7:0], 1'b0}` (stop · data LSB-first · start) and clocks it out one bit per `BAUD_DIV` cycles.

**RX operation:** Detects the falling start-bit edge, waits half a bit-period (`BAUD_DIV / 2`) to align to mid-bit, then samples each data bit at the centre of its window for maximum noise immunity. The RX input passes through a **2-stage flip-flop synchroniser** to prevent metastability at the async domain crossing.

**IRQ:** Asserted when `rx_ready` is high (byte fully received) or when `tx_busy` falls (transmitter becomes idle).

---

### `gpio.v` — LEDs and Switches

8-bit bidirectional GPIO with separate output and input registers.

**Register Map (base `0x2000_0000`):**

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| `0x0` | OUTPUT | R/W | Drives `gpio_out[7:0]` — the 8 LED pins. Write `0xFF` to light all |
| `0x4` | INPUT | R | Reads `gpio_in[7:0]` — the 8 slide switch positions |

---

### `timer.v` — Countdown Timer

Programmable 32-bit countdown timer with auto-reload and IRQ generation.

**Register Map (base `0x3000_0000`):**

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| `0x0` | LOAD | R/W | Load value. Writing also immediately reloads and resets the counter |
| `0x4` | COUNT | R | Current counter value — decrements each clock when enabled |
| `0x8` | CTRL | R/W | `[0]` = enable · `[1]` = auto-reload |
| `0xC` | STATUS | R/W | `[0]` = timeout flag — write `1` to clear |

**Auto-reload mode** (`CTRL[1] = 1`): on reaching zero, the counter reloads from LOAD and continues — generates periodic interrupts at a fixed rate.

**One-shot mode** (`CTRL[1] = 0`): the counter stops at zero after a single countdown. Software must re-enable to start again.

---

### `intc.v` — Interrupt Controller

Priority-based 4-source interrupt aggregator. Collects IRQ lines from all peripherals and presents a single `irq_to_cpu` to the processor.

**IRQ Sources:**

| Bit | Source | Fired When |
|-----|--------|------------|
| 0 | UART | Byte fully received |
| 1 | Timer | Countdown reached zero |
| 2 | SPI | Transfer complete |
| 3 | I2C | Transfer complete |

**Register Map (base `0x4000_0000`):**

| Offset | Name | R/W | Description |
|--------|------|-----|-------------|
| `0x0` | PENDING | R | `[3:0]` — latched IRQ bits, one per source |
| `0x4` | ENABLE | R/W | `[3:0]` — interrupt enable mask |
| `0x8` | CLEAR | W | Write `1` to a bit to acknowledge and clear that interrupt |
| `0xC` | PRIORITY | R/W | `[3:0]` — `1` = high priority, `0` = low priority |

**Typical software interrupt handler:**
1. Read PENDING to identify which source fired
2. Service that peripheral (e.g. read UART RX_DATA)
3. Write the corresponding bit to CLEAR to acknowledge

**Priority encode logic:**
```verilog
wire [31:0] active   = pending & enable_reg;
wire [31:0] high_pri = active & priority_reg;
// High-priority sources fire first; falls back to any active if none are high-priority
assign irq_to_cpu = |high_pri ? |high_pri : |active;
```

---

### `spi.v` — SPI Master

Full SPI master controller driving SCK, MOSI, CS_N with MISO receive capability. Supports CPOL and CPHA mode configuration for compatibility with a wide range of SPI sensors, flash memories, and display drivers.

**Usage:** Write the byte to transmit → poll STATUS until `busy = 0` → read RX_DATA for the received byte. Asserts `irq` on transfer completion.

---

### `i2c.v` — I2C Master

Two-wire I2C master implementing a 9-state FSM:

```
IDLE → START → ADDR+RW → ACK → DATA → ACK → ... → STOP → IDLE
```

Uses open-drain output-enable signals (`scl_oe`, `sda_oe`) rather than driving SCL/SDA directly — the bus is released by de-asserting the output-enable, which allows the external pull-up resistor to bring the line high. This correctly implements the open-drain wired-AND topology required by the I2C specification.

Asserts `irq` on transaction completion (after the final STOP condition).

---

### `seg7_ctrl.v` — 7-Segment Display Driver

Drives two 4-digit 7-segment displays (8 digits total) on the Boolean FPGA board. Uses **time-division multiplexing** — each digit is asserted briefly in turn at approximately **1 kHz** per digit. At this refresh rate, persistence of vision makes all 8 digits appear simultaneously lit to the human eye.

Write a 32-bit hexadecimal value to the display register; the driver decodes each nibble to its 7-segment encoding and cycles through the anodes automatically. No software intervention is needed after the initial write.

---

## 8. Top-Level Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `clk` | in | 1 | System clock (100 MHz) |
| `rst_n` | in | 1 | Active-low asynchronous reset |
| `uart_tx` | out | 1 | Serial data out to host |
| `uart_rx` | in | 1 | Serial data in from host |
| `gpio_out[7:0]` | out | 8 | LED drive pins |
| `gpio_in[7:0]` | in | 8 | Slide switch input pins |
| `spi_sck` | out | 1 | SPI clock |
| `spi_mosi` | out | 1 | SPI master data out |
| `spi_miso` | in | 1 | SPI master data in |
| `spi_cs_n` | out | 1 | SPI chip select (active-low) |
| `i2c_scl_oe` | out | 1 | I2C clock open-drain output enable |
| `i2c_sda_oe` | out | 1 | I2C data open-drain output enable |
| `i2c_sda_in` | in | 1 | I2C data input |
| `D0_AN[3:0]` | out | 4 | Display 0 digit anode select |
| `D0_SEG[7:0]` | out | 8 | Display 0 segment drive |
| `D1_AN[3:0]` | out | 4 | Display 1 digit anode select |
| `D1_SEG[7:0]` | out | 8 | Display 1 segment drive |

---

## 9. Instruction Set — RV32I (37 Instructions)

The design implements the complete RV32I base integer instruction set. All 37 instructions are decoded and executed:

| Category | Instructions |
|----------|-------------|
| **Arithmetic** | `ADD` `ADDI` `SUB` |
| **Logical** | `AND` `ANDI` `OR` `ORI` `XOR` `XORI` |
| **Shift** | `SLL` `SLLI` `SRL` `SRLI` `SRA` `SRAI` |
| **Compare** | `SLT` `SLTI` `SLTU` `SLTIU` |
| **Load** | `LB` `LH` `LW` `LBU` `LHU` |
| **Store** | `SB` `SH` `SW` |
| **Branch** | `BEQ` `BNE` `BLT` `BGE` `BLTU` `BGEU` |
| **Jump** | `JAL` `JALR` |
| **Upper Immediate** | `LUI` `AUIPC` |

---

## 10. Synthesis & Timing Constraints

The SDC constraints file (`synthesis/genus/scripts/constraints.sdc`) targets a **100 MHz clock** and models realistic I/O delays:

| Parameter | Value | Notes |
|-----------|-------|-------|
| Clock period | 10.0 ns | 100 MHz target |
| Clock transition | 0.1 ns | Slew modelling |
| Clock uncertainty | 0.15 ns | Jitter + skew budget |
| Input delay | 2.0 ns | External register to chip input |
| Output delay | 2.0 ns | Chip output to external register |
| Driving cell | `BUFX4` | Source impedance model |
| Output load | 0.05 pF | Destination load model |
| False path | `rst_n` | Asynchronous reset — excluded from STA |

**Effective logic budget per path:**
`10.0 ns − 2.0 ns (input) − 0.15 ns (uncertainty) = 7.85 ns`

The FPGA implementation on Spartan-7 achieved **WNS = +2.489 ns** (critical path = 7.511 ns), consuming 95.6% of this budget with comfortable margin.

---

## 11. Simulation & Testbench

### Testbench — `tb/tb_soc_top.sv`

The top-level SystemVerilog testbench instantiates `soc_top` and drives the full SoC through a structured test sequence:

| Parameter | Value |
|-----------|-------|
| Clock period | 10 ns (100 MHz) |
| Simulation timeout | 500,000 cycles |
| Reset duration | 20 cycles (external) + 256 cycles (POR) |
| Waveform output | `.vcd` — view in GTKWave or Verdi |

**Structured checking:** all checks use a `check(name, condition)` task that prints `[PASS]` or `[FAIL]` with the test name, enabling automated PASS/FAIL batch reporting.

**Startup sequence:** reset is held for 20 cycles, then the testbench waits an additional 300 cycles for the power-on reset counter to clear before beginning functional verification. This mirrors the exact startup behaviour of the physical hardware.

### Running Simulations

```bash
# All testbenches — VCS batch runner (prints PASS/FAIL for each)
bash tb/run_sim.sh

# Single testbench — VCS
vcs -full64 -sverilog +define+SIMULATION \
    -f sim/filelist/rtl.f tb/tb_soc_top.sv \
    -o simv_soc -l compile.log
./simv_soc -l sim.log

# With Verdi interactive waveform (FSDB)
vcs -full64 -sverilog -debug_access+all +fsdbfile+dump.fsdb \
    -f sim/filelist/rtl.f tb/tb_soc_top.sv -o simv_soc
./simv_soc -gui

# Cadence NCLaunch (uses wire-fixed RTL filelist)
nclaunch &
# Add: sim/filelist/rtl_nclaunch.f + tb/tb_soc_top.sv
# Top: tb_soc_top → Run → Simulate
```

### Testbench Coverage

| Testbench | Module | What Is Verified |
|-----------|--------|-----------------|
| `tb_alu.sv` | `alu` | All 10 operations, zero flag |
| `tb_regfile.sv` | `regfile` | Write/read, x0 invariant, dual-port read |
| `tb_immgen.sv` | `immgen` | All 5 formats, sign extension |
| `tb_control.sv` | `control` | All 9 opcodes → correct 11-signal decode |
| `tb_uart.sv` | `uart` | TX shift-out, RX mid-bit sampling, IRQ |
| `tb_gpio.sv` | `gpio` | Output write, input read |
| `tb_timer.sv` | `timer` | Load, countdown, IRQ, auto-reload |
| `tb_intc.sv` | `intc` | Multi-source, enable mask, priority encode |
| `tb_spi.sv` | `spi` | Frame generation, CPOL/CPHA modes |
| `tb_i2c.sv` | `i2c` | START/STOP conditions, byte transmit |
| `tb_cpu_top.sv` | `cpu_top` | Multi-instruction programs, branch/jump |
| `tb_soc_top.sv` | Full SoC | End-to-end: CPU → bus → peripherals |

---

<div align="center">

**RISC-V SoC — RTL Source**

RV32I · 37 Instructions · Single-Cycle · 100 MHz · 16 KB Memory · 7 Peripheral IPs

*Part of the full RTL → Simulation → FPGA → Synthesis → Place & Route → GDSII flow*

Saveetha Engineering College — ECE Department
Arunachalam P (212223060022) · Charan PG (212223060033)

</div>
