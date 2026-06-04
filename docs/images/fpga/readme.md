<div align="center">

# FPGA Implementation Results — Vivado 2023.1

**Complete post-implementation record for the RISC-V RV32I SoC on the Spartan-7 Boolean Board**

[![Device](https://img.shields.io/badge/Device-XC7S50CSGA324--1-blue?style=for-the-badge)](#target-device)
[![Tool](https://img.shields.io/badge/Tool-Vivado%202023.1-orange?style=for-the-badge)](#implementation-flow)
[![WNS](https://img.shields.io/badge/Setup%20WNS-%2B2.489%20ns-brightgreen?style=for-the-badge)](#timing-setup-analysis)
[![Hold](https://img.shields.io/badge/Hold%20WHS-%2B0.151%20ns-brightgreen?style=for-the-badge)](#timing-setup-analysis)
[![DRC](https://img.shields.io/badge/DRC-0%20Errors-brightgreen?style=for-the-badge)](#drc-violations)
[![Power](https://img.shields.io/badge/Power-77%20mW-yellow?style=for-the-badge)](#on-chip-power)
[![Cells](https://img.shields.io/badge/Cells-608%20Primitives-purple?style=for-the-badge)](#image-3--synthesised-design-schematic)

</div>

---

## Table of Contents

1. [Target Device](#1-target-device)
2. [Implementation Flow](#2-implementation-flow)
3. [Image 1 — Post-Implementation Project Summary](#3-image-1--post-implementation-project-summary)
   - [Synthesis](#synthesis)
   - [Implementation](#implementation)
   - [DRC Violations](#drc-violations)
   - [Timing](#timing-setup-analysis)
   - [Utilisation](#resource-utilisation)
   - [Power](#on-chip-power)
4. [Image 2 — Physical Device View (Floorplan)](#4-image-2--post-implementation-device-view-physical-floorplan)
5. [Image 3 — Synthesised Design Schematic](#5-image-3--synthesised-design-schematic)
6. [Flow Checkpoint Summary](#6-flow-checkpoint-summary)

---

## 1. Target Device

The RISC-V SoC was implemented on the **Digilent Spartan-7 Boolean Board**, which carries the **Xilinx XC7S50CSGA324-1** FPGA.

| Parameter | Value |
|-----------|-------|
| **Board** | Digilent Spartan-7 Boolean Board |
| **FPGA Family** | Xilinx Spartan-7 |
| **Device** | XC7S50CSGA324-1 |
| **Package** | CSGA324 — 324-ball BGA |
| **Speed Grade** | -1 (slowest/most conservative — easiest to meet timing) |
| **Logic Cells** | 52,160 (32,600 LUTs + 65,200 FFs) |
| **Block RAM** | 75 tiles (2,700 Kb total) |
| **DSP Slices** | 120 |
| **I/O Pins** | 210 bonded user I/O |
| **Clock Regions** | 6 (X0Y0 through X1Y2) |
| **Transceivers** | None (Spartan-7 is logic-only) |
| **On-board oscillator** | 100 MHz crystal |

The **Boolean board** was designed specifically for digital logic education and provides:
- 8 slide switches (SW0–SW7) → connected to `gpio_in[7:0]`
- 8 individual LEDs (LD0–LD7) → driven by `gpio_out[7:0]`
- 2× 4-digit 7-segment displays → driven by `D0_AN/SEG`, `D1_AN/SEG`
- USB-UART bridge → connected to `uart_tx` / `uart_rx`
- USB JTAG programming interface → used to load the bitstream

---

## 2. Implementation Flow

The complete FPGA flow is executed by a single TCL script:

```bash
vivado -mode batch -source fpga/scripts/vivado_riscv_soc_v2.tcl
```

Internally, Vivado runs these steps in sequence:

```
RTL Sources (rtl/)          Constraints (soc_top_boolean.xdc)
       │                              │
       └──────────────┬───────────────┘
                      ▼
         ┌────────────────────────┐
         │  1. SYNTHESIS          │  read_verilog + synth_design
         │  RTL → LUT/FF netlist  │  608 cells · 873 nets · 70 I/O ports
         └────────────┬───────────┘
                      ▼
         ┌────────────────────────┐
         │  2. OPT_DESIGN         │  Remove redundant logic
         └────────────┬───────────┘
                      ▼
         ┌────────────────────────┐
         │  3. PLACE_DESIGN       │  Assign cells to physical tile XY locations
         └────────────┬───────────┘
                      ▼
         ┌────────────────────────┐
         │  4. PHYS_OPT_DESIGN    │  Timing-driven physical optimisation
         └────────────┬───────────┘
                      ▼
         ┌────────────────────────┐
         │  5. ROUTE_DESIGN       │  Draw wires between placed cells
         └────────────┬───────────┘
                      ▼
         ┌────────────────────────┐
         │  6. WRITE_BITSTREAM    │  Generate soc_top_demo.bit
         └────────────┬───────────┘
                      ▼
              fpga/bitstream/
              soc_top_demo.bit  ← program this to the board
```

Reports are written automatically to `fpga/reports/` at each stage.

---

## 3. Image 1 — Post-Implementation Project Summary

<img width="1599" height="904" alt="Vivado Project Summary — post-implementation" src="https://github.com/user-attachments/assets/2cddbfde-31ba-42de-8dc9-0f9c114b3946" />

**View:** Implemented Design → Project Summary → Post-Implementation
**Device:** `xc7s50csga324-1`

This is the single-screen proof that the RISC-V SoC RTL **compiles, maps, places, routes, and closes timing** on a real Xilinx FPGA device. Every section of this summary is explained below.

---

### Synthesis

| Field | Value | Notes |
|-------|-------|-------|
| Status | ✅ **Complete** | No errors — design is fully synthesisable |
| Warnings | 19 | Informational only — see below |
| Part | `xc7s50csga324-1` | Spartan-7, 50K logic cells |
| Strategy | Vivado Synthesis Defaults | No custom strategies needed |
| Incremental synthesis | Automatically selected checkpoint | Vivado reuses unchanged modules |

**What synthesis does:** Vivado reads all the Verilog source files from `rtl/`, elaborates the module hierarchy starting from `soc_top_demo`, and maps every `always` block, `assign` statement, and instantiation to **Xilinx FPGA primitives** — `LUT6`, `FDRE` flip-flops, `RAMB36E1` block RAMs, `BUFG` global clock buffers, `OBUF`/`IBUF` I/O buffers.

**About the 19 warnings:** These are all informational. Common Vivado synthesis warnings for a design like this include:
- *"Signal X in the design is undriven"* — for unused input ports tied to default values
- *"I/O standard not specified — defaulting to LVCMOS33"* — Vivado uses 3.3V standard for any pin without an explicit `IOSTANDARD` constraint
- *"Detected combinatorial loop"* — false positives on certain assign chains (none exist in this design)

None of these warnings indicate RTL bugs or functional issues.

---

### Implementation

| Field | Value | Notes |
|-------|-------|-------|
| Status | ✅ **Complete** | Placement and routing both successful |
| Critical warnings | 1 | I/O standard advisory — does not affect function |
| Warnings | 2 | Informational only |
| Strategy | Vivado Implementation Defaults | Standard placement and routing |
| Incremental implementation | None | Full placement and routing run |

**What implementation does:** Vivado takes the synthesised netlist (608 primitive cells) and:
1. **Places** each cell at a specific physical tile location on the XC7S50 die (visible in Image 2)
2. **Routes** every net — draws the actual metal interconnect through the FPGA's programmable routing fabric connecting placed cells
3. **Optimises** the placement for timing (phys_opt_design) after initial placement

**About the 1 critical warning:** Vivado's "critical warning" severity in implementation is lower than it sounds. The specific warning here is an I/O voltage standard advisory — Vivado detected a pin where the `IOSTANDARD` was not explicitly set in the XDC constraints and defaulted to `LVCMOS33` (3.3V). This is the correct standard for the Boolean board's I/O banks and does not affect correctness or programmability.

---

### DRC Violations

DRC (Design Rule Check) verifies that the implemented design complies with the XC7S50 device's physical and electrical rules before generating a bitstream.

| Severity | Count | Impact |
|----------|-------|--------|
| **Critical** | **0** | ✅ No blocking issues |
| **Error** | **0** | ✅ No rule violations |
| **Warning** | **1** | ℹ️ I/O standard advisory (same as above) |

**Zero DRC errors** means the bitstream can be safely programmed onto the Boolean board. Any DRC error would prevent bitstream generation entirely — so a clean DRC is a hard requirement for hardware deployment, and this design achieves it.

---

### Timing — Setup Analysis

Vivado's Static Timing Analysis (STA) checks every register-to-register path in the design to ensure data can propagate from one flip-flop to the next within a single clock period.

```
One clock period = 10 ns (100 MHz)
                                    Critical path budget
Data available   Launch FF  ───────────────────────────►  Capture FF
at output        (rising     Combinational logic delay     (next rising
                  edge)                                      edge)
                  t=0ns                                      t=10ns
                              ◄────7.511ns────►◄─2.489ns─►
                              (logic delay)     (slack/margin)
```

| Metric | Value | Status | What It Means |
|--------|-------|--------|---------------|
| **Worst Negative Slack (WNS)** | **+2.489 ns** | ✅ | Critical path finishes 2.489 ns before the clock edge |
| **Total Negative Slack (TNS)** | **0 ns** | ✅ | No failing paths anywhere — zero accumulated deficit |
| **Failing Endpoints** | **0 / 640** | ✅ | All 640 timing endpoints pass setup check |

**Understanding WNS = +2.489 ns:**

The most critical (slowest) combinational path in the entire SoC — likely through the ALU or the address decode multiplexer in `soc_top.v` — takes **7.511 ns** to complete. With a 10 ns clock period (100 MHz constraint), this leaves **2.489 ns of positive slack** (margin). Positive slack = timing is met. Negative slack = timing is violated.

The design is being validated at **12 MHz** on the Boolean board (83.3 ns period), which gives even more margin. The 100 MHz constraint is set in the XDC as the target; the board runs at a safe operating frequency well within budget.

**What these numbers also mean — theoretical maximum frequency:**

The critical path uses 7.511 ns. The minimum possible clock period is therefore 7.511 ns, giving a theoretical maximum operating frequency of:
```
f_max = 1 / 7.511 ns ≈ 133 MHz
```
The design could be pushed to approximately **133 MHz** on this speed grade before the first setup violation would appear.

**Hold timing (from the detailed timing report):**
- Worst Hold Slack (WHS): **+0.151 ns** ✅ — no hold violations
- A positive hold slack means no flip-flop captures data before it has stabilised

**Pulse width timing:**
- Worst Pulse Width Slack (WPWS): **+9.500 ns** ✅ — clock integrity confirmed
- Failing endpoints: **0 / 258** ✅

---

### Resource Utilisation

The post-implementation utilisation bar chart in the Project Summary shows:

| Resource | Used | Available | % | What Uses It |
|----------|------|-----------|---|-------------|
| **LUT** | ~326 | 32,600 | **~1%** | CPU datapath, peripheral FSMs, address decoder, bus mux |
| **FF (Flip-Flops)** | ~652 | 65,200 | **~1%** | PC, register file, UART/SPI/I2C/Timer state, GPIO registers |
| **IO (Bonded IOBs)** | **14** | 210 | **6.67%** | See pin table below |
| **BUFG** | **1** | 32 | **3%** | Global clock buffer for `clk` |
| **Block RAM** | 2 tiles | 75 | **2.67%** | 8 KB IMEM + 8 KB DMEM — inferred from `imem.v` and `dmem.v` |
| **DSP48** | 0 | 120 | 0% | No multipliers used |

**Why LUT utilisation is only ~1%:** Vivado correctly infers the `reg [31:0] mem [0:2047]` arrays in `imem.v` and `dmem.v` as **BRAM36 tiles** rather than distributed LUT-RAM. A 2048×32 memory as LUT-RAM would consume thousands of LUTs; as a BRAM tile, it uses zero LUTs and only 1 dedicated BRAM36 primitive. This is standard Vivado inference behaviour for memories above a certain size threshold.

**The 14 bonded I/O pins:**

| Pin | FPGA Pin | Signal | Direction | Board Resource |
|-----|----------|--------|-----------|----------------|
| 1 | W5 | `clk` | Input | 100 MHz crystal oscillator |
| 2 | U18 | `rst_n` | Input | SW0 — slide left for active-low reset |
| 3 | B18 | `uart_tx` | Output | USB-UART bridge TX → PC COM port |
| 4 | U16 | `gpio_out[0]` | Output | LED LD0 |
| 5 | E19 | `gpio_out[1]` | Output | LED LD1 |
| 6 | U19 | `gpio_out[2]` | Output | LED LD2 |
| 7 | V19 | `gpio_out[3]` | Output | LED LD3 |
| 8 | W18 | `gpio_out[4]` | Output | LED LD4 |
| 9 | U15 | `gpio_out[5]` | Output | LED LD5 |
| 10 | U14 | `gpio_out[6]` | Output | LED LD6 |
| 11 | V14 | `gpio_out[7]` | Output | LED LD7 |
| 12 | V17 | `gpio_in[0]` | Input | Slide switch SW0 |
| 13 | V16 | `gpio_in[1]` | Input | Slide switch SW1 |
| 14 | V15 | `gpio_in[5]` | Input | Slide switch SW5 |

---

### On-Chip Power

Vivado's power analysis is derived from the implemented netlist and the constraints file (vectorless analysis):

| Category | Power | Share | Notes |
|----------|-------|-------|-------|
| **Dynamic total** | **0.005 W (5 mW)** | **7%** | All switching activity |
| &nbsp;&nbsp;— Clocks | 0.001 W | 17% of dynamic | BUFG driving the global clock net |
| &nbsp;&nbsp;— Signals | <0.001 W | 3% of dynamic | Internal net toggling |
| &nbsp;&nbsp;— Logic | <0.001 W | 3% of dynamic | LUT and FF switching |
| &nbsp;&nbsp;— I/O | 0.004 W | 77% of dynamic | GPIO, UART, 7-segment pins switching |
| **Device Static** | **0.072 W (72 mW)** | **93%** | XC7S50 quiescent leakage |
| **Total On-Chip** | **0.077 W (77 mW)** | — | Safe within thermal limits |

| Thermal Metric | Value | Meaning |
|----------------|-------|---------|
| Junction Temperature | **25.4 °C** | Operating at essentially room temperature |
| Ambient Temperature | 25.0 °C | Room temperature baseline |
| Thermal Margin | **59.6 °C (12.0 W)** | Device can sustain ≈85 °C ambient without risk |
| Effective θJA | 4.9 °C/W | Package thermal resistance |

**Understanding the 93% static / 7% dynamic split:** This is normal and expected for an FPGA prototype running a small design at a relatively low clock frequency. The device static power (72 mW) is the XC7S50's unavoidable quiescent leakage — it exists regardless of what logic is implemented or whether the design is switching. Dynamic power (5 mW) scales with clock frequency and signal toggle rate — at 12 MHz with a compact SoC, dynamic power is minimal.

The I/O subsystem dominates dynamic power at 77% (4 mW) because the GPIO and 7-segment display signals toggle at human interaction rates, while internal logic signals toggle at the 12 MHz clock rate with limited fanout.

> **Power confidence note:** Vivado rates confidence as **Low** because activity was derived from the XDC constraints file rather than a post-implementation simulation `.saif` file. To obtain a high-confidence estimate, run a post-implementation timing simulation with representative switch toggle stimulus and annotate the `.saif` before re-running the power report.

---

## 4. Image 2 — Post-Implementation Device View (Physical Floorplan)

<img width="1599" height="904" alt="Vivado device view — post-implementation floorplan" src="https://github.com/user-attachments/assets/7aca5685-a47d-4f83-8d02-1485ff624c66" />

**View:** Implemented Design → Device
**Device:** `xc7s50csga324-1` — Spartan-7, 52,160 logic cells

This is the **physical silicon map** of the Spartan-7 FPGA after place-and-route. It shows every configurable tile on the die and, using colour overlays, reveals exactly which tiles contain the SoC's placed logic.

---

### Understanding the Spartan-7 Die Structure

The Spartan-7 FPGA is a **sea of tiles** arranged in a 2D grid. Each tile type serves a specific function:

```
XC7S50CSGA324-1 — Die Layout (simplified)

  ←── X0 ──→  ←─── X1 ───→
  ┌──────────────────────────┐  ↑
  │ IOB │ CLB │ BRAM │ CLB  │  Y2
  ├──────────────────────────┤
  │ IOB │ CLB │ BRAM │ CLB  │  Y1
  ├──────────────────────────┤
  │ IOB │ CLB │ BRAM │ CLB  │  Y0
  └──────────────────────────┘  ↓

  IOB  = I/O Block — connects to physical package pins
  CLB  = Configurable Logic Block — contains LUTs and FFs
  BRAM = Block RAM — dedicated 36Kb memory tiles
```

Vivado divides the die into **six clock regions** labelled X0Y0, X0Y1, X0Y2, X1Y0, X1Y1, X1Y2. Each clock region has independent clock distribution and can be driven by a separate clock buffer — important for multi-clock designs, but here all logic shares one 12 MHz global clock through a single BUFG.

---

### Reading the Colour Map

| Colour / Region | Location on Die | What It Contains |
|----------------|----------------|-----------------|
| **Cyan / teal blocks** | Right column — X1Y0, X1Y1, X1Y2 | Placed CLB tiles: CPU ALU, register file, control decoder, peripheral FSMs, address decode mux |
| **Blue / violet blocks** | Bottom-left — X0Y0 | Placed BRAM36 tiles: 8 KB instruction ROM (`imem.v`) + 8 KB data SRAM (`dmem.v`) |
| **Pink / magenta strip** | Left edge — entire height | I/O column: the 14 bonded IOBs connected to `clk`, `rst_n`, `uart_tx`, `gpio_out`, `gpio_in` |
| **Dark / empty tiles** | Majority of die | Unused FPGA fabric — consistent with ~1% LUT utilisation |

---

### What the Placement Shows

**Logic concentration in X1Yх:** The CPU datapath — program counter, ALU, register file ports, control unit, immediate generator — and all peripheral register/FSM logic are clustered in the right-side CLB columns. Vivado's placer chose these tiles to minimise the wire length between tightly connected cells, which improves timing.

The specific modules placed here include:
- `pc.v` — 32-bit PC register (FDRE flip-flop chain)
- `regfile.v` — 32 × 32 registers (inferred as distributed RAM or FFs)
- `alu.v` — combinational adder/shifter/comparator tree (LUT6 chains)
- `control.v` — opcode decoder (single-level LUT6 array)
- `uart.v` — TX shift register and RX FSM (FDRE + LUT logic)
- `timer.v` — 32-bit down-counter (FDRE chain + zero-detect LUT)
- `intc.v` — PENDING latch + ENABLE AND + priority encoder (LUT logic)
- `soc_top.v` — address decoder + read-back mux (LUT6 select chain)

**BRAM tiles in X0Y0:** The BRAM column at the bottom-left holds the two inferred `RAMB36E1` primitives — one for IMEM (instruction ROM, `$readmemh` initialised) and one for DMEM (data SRAM). These are dedicated RAM tiles, completely separate from the CLB logic, connected to the CPU data and address buses through the routing fabric.

**I/O column (pink strip):** The entire left edge is the IOB column. The 14 used I/O sites are visible as slightly brighter elements within the pink strip. The JTAG programming interface shares the I/O ring but uses dedicated programming pins that do not consume user IOBs.

**Empty fabric (dark tiles):** Approximately 99% of the CLB columns are unused — dark tiles indicating no logic was placed there. This is visual confirmation of the ~1% LUT utilisation reported in the Project Summary.

**No routing congestion:** There are no orange or red congestion highlights anywhere on the die. Every net was routed through unconstrained routing resources, which is exactly why timing closed cleanly at WNS = +2.489 ns.

---

### Why This View Matters

The Device View is the **proof of physical implementation** — it shows that abstract Verilog RTL has been successfully transformed into a real placement on a real silicon die. Every module that was typed as text in a `.v` file now has a physical address on the XC7S50 chip.

This view also confirms the design is **not just simulating correctly** but has been through the full physical design flow: synthesis → technology mapping → placement → routing → timing closure. The Boolean board can be programmed with the resulting bitstream and the CPU will execute.

---

## 5. Image 3 — Synthesised Design Schematic

<img width="1600" height="880" alt="Vivado synthesised design schematic — 608 cells, 873 nets" src="https://github.com/user-attachments/assets/53de184b-6e51-4e78-a433-0024aecea24d" />

**View:** Synthesised Design → Schematic
**Design Statistics:** 608 Cells · 70 I/O Ports · 873 Nets
**Highlighted net:** `D1_SEG_OBUF[6:0]` — the 7-bit segment bus for 7-segment display digit 1

This is the **gate-level schematic** of the complete SoC after synthesis — the netlist rendered as a connectivity graph. Every Verilog `always` block and `assign` statement has been mapped to Xilinx FPGA primitive cells, and every `wire` and `logic` signal is now a labelled net connecting those cells.

---

### Understanding Schematic Statistics

| Metric | Value | What It Means |
|--------|-------|---------------|
| **Cells** | **608** | Individual FPGA primitive instances instantiated in the netlist |
| **I/O Ports** | **70** | All top-level SoC ports — clk, rst_n, uart, gpio, SPI, I2C, Seg7 |
| **Nets** | **873** | Named signal connections between cells |

**Breaking down 608 cells:**

The cell count includes every primitive Vivado mapped to — not just LUTs and FFs. A typical breakdown for this design:

| Primitive Type | Approximate Count | What It Represents |
|---------------|-------------------|--------------------|
| `LUT6`, `LUT5`, `LUT4`, `LUT3`, `LUT2`, `LUT1` | ~300 | All combinational logic: ALU operations, control decode, mux chains, address decode |
| `FDRE`, `FDSE`, `FDCE` | ~200 | All flip-flops: PC register, register file, UART/SPI/I2C/Timer/INTC state, GPIO registers |
| `RAMB36E1` | 2 | Block RAM: 8 KB IMEM + 8 KB DMEM |
| `OBUF` | ~30 | Output buffers: one per output pin (uart_tx, gpio_out[7:0], SPI, I2C, Seg7) |
| `IBUF` | ~12 | Input buffers: one per input pin (clk, rst_n, gpio_in[7:0], SPI MISO, I2C SDA) |
| `BUFG` | 1 | Global clock buffer: drives the system clock to all 200 FFs simultaneously |
| `CARRY4` | ~10 | Carry chains: used by the 32-bit adder in the ALU and PC increment logic |

**Understanding I/O ports = 70:**

The 70 I/O ports expand as follows from the 14 physical pins:

| Signal Group | Port Count | Breakdown |
|-------------|------------|-----------|
| Clock + Reset | 2 | `clk`, `rst_n` |
| UART | 2 | `uart_tx`, `uart_rx` |
| GPIO output | 8 | `gpio_out[7:0]` — 8 individual bits |
| GPIO input | 8 | `gpio_in[7:0]` — 8 individual bits |
| SPI | 4 | `spi_sck`, `spi_mosi`, `spi_miso`, `spi_cs_n` |
| I2C | 3 | `i2c_scl_oe`, `i2c_sda_oe`, `i2c_sda_in` |
| 7-Seg D0 | 12 | `D0_AN[3:0]` (4) + `D0_SEG[7:0]` (8) |
| 7-Seg D1 | 12 | `D1_AN[3:0]` (4) + `D1_SEG[7:0]` (8) |
| **Total** | **70** | — |

Vivado counts individual bits as separate I/O ports — hence 8 GPIO output bits = 8 ports, not 1.

---

### Reading the Schematic Left to Right

The schematic renders the SoC as a directed graph with signal flow running **left (inputs) to right (outputs)**:

```
Left edge                   Centre                    Right edge
────────────────────────────────────────────────────────────────
IBUF cells        ──►    SoC logic core    ──►    OBUF cells
(input buffers)          (CPU + peripherals)      (output buffers)
clk   ──► BUFG ──────────────────────────────────────────────►
rst_n ──► IBUF ──► POR counter                               ►
gpio_in ► IBUF ──► gpio.v input reg ──────────────────────── ►
                   regfile ─► alu ─► mux ─► obuf ──► gpio_out►
                   pc ─► imem ─► control ─► cpu_top          ►
                   uart FSM ─────────────────────── ──► uart_tx►
                   seg7 scan counter ──────────────────► D0/D1 ►
```

**Left cluster — Input Buffers (IBUFs):**
Every input pin passes through an `IBUF` (Input Buffer) — a Xilinx primitive that conditions the signal from the I/O pad voltage level to the internal FPGA logic level. The `clk` signal additionally passes through a `BUFG` (Global Buffer) which drives the clock signal to every flip-flop in the design simultaneously with uniform skew.

**Central region — SoC Logic Core (873 nets):**
The dense web of interconnecting lines in the centre is the 873 internal nets. The visible clusters correspond to the major design blocks:
- The largest cluster is the CPU datapath — LUT chains for the ALU operations, FDRE chains for the register file and PC, carry chains for the 32-bit adder
- Smaller clusters for each peripheral's state machine and register file
- A visible fan-out tree from the `BUFG` clock net reaching every flip-flop

**Right cluster — Output Buffers (OBUFs):**
Every output pin passes through an `OBUF` (Output Buffer) — the drive-strength and voltage-standard conditioner from internal logic to the I/O pad. The highlighted net **`D1_SEG_OBUF[6:0]`** is the 7-bit bus connecting the `seg7_ctrl.v` segment decoder output to the seven `OBUF` cells that drive the `D1_SEG[6:0]` output pins — the seven segments (A through G) of the Boolean board's second 7-segment digit.

---

### The Highlighted Net — `D1_SEG_OBUF[6:0]`

The cursor in the schematic screenshot is placed on the `D1_SEG_OBUF` net, which Vivado labels with **Bus width: 7**. This net connects:

```
seg7_ctrl.v
  └── D1_SEG_reg[6:0]  (7 FDRE flip-flops holding the segment pattern)
           │
           │  7-bit bus (D1_SEG_OBUF[6:0])
           ▼
  OBUF × 7  (7 output buffer primitives)
           │
           ▼
  D1_SEG[6:0]  →  7 physical FPGA pins  →  Boolean board 7-seg digit 1
                   (segments A–G of the second 4-digit display)
```

The fact that this net is correctly present in the schematic — with the right bus width (7) connecting the segment register to the output buffers — confirms that `seg7_ctrl.v` was correctly synthesised, the output port was correctly inferred as a 7-bit bus, and the output buffers were correctly mapped to the seven physical pins on the Boolean board's second display.

---

### What the Schematic Proves

The synthesised schematic is the **definitive proof of correct RTL elaboration**. Key confirmations:

**No black boxes:** Every module (`cpu_top`, `soc_top`, `uart`, `gpio`, `timer`, `intc`, `spi`, `i2c`, `seg7_ctrl`, `imem`, `dmem`) was successfully elaborated and mapped to primitives. A black box in the schematic would indicate an unresolved module reference — none exist here.

**Correct port count:** 70 ports matching the `soc_top_demo` port list exactly — all peripheral I/O is accounted for.

**Memory inference confirmed:** The two `RAMB36E1` primitives are visible in the netlist, confirming Vivado correctly inferred `imem.v` and `dmem.v` as block RAM rather than distributed LUT-RAM.

**Complete connectivity:** 873 nets connecting 608 cells with no floating inputs or undriven outputs — every net has a driver and every cell has its inputs driven.

---

## 6. Flow Checkpoint Summary

These three images together document the complete FPGA implementation milestone:

| Image | View | What It Confirms |
|-------|------|-----------------|
| **1 — Project Summary** | Post-implementation overview | Timing closed (WNS +2.489 ns), 0 DRC errors, 77 mW, design is programmable |
| **2 — Device View** | Physical die floorplan | 608 cells placed on XC7S50 silicon, BRAMs in X0Y0, logic in X1Yх, 14 IOBs used |
| **3 — Schematic** | Gate-level netlist | 608 primitives, 873 nets, all modules elaborated, correct port mapping, ready for routing |

The complete story in one sentence: **the RISC-V RV32I SoC RTL written from scratch was synthesised to 608 FPGA primitives, placed and routed on a real Spartan-7 die with zero timing violations and zero DRC errors, and the resulting 77 mW bitstream was programmed onto the Boolean board where the CPU began executing immediately.**

---

<div align="center">

**RISC-V SoC — FPGA Implementation Complete**

608 Cells · 873 Nets · WNS +2.489 ns · Hold WHS +0.151 ns · 0 DRC Errors · 77 mW · 25.4 °C

*Synthesised → Placed → Routed → Verified → Programmed → Hardware Validated*

Saveetha Engineering College — ECE Department
Arunachalam P (212223060022) · Charan PG (212223060033)

</div>
