<div align="center">

# FPGA Implementation — RISC-V RV32I SoC

**Xilinx Spartan-7 Boolean Board · Vivado 2023.1 · Full RTL → Bitstream**

[![Board](https://img.shields.io/badge/Board-Spartan--7%20Boolean-orange?style=for-the-badge)](https://digilent.com/reference/programmable-logic/boolean/start)
[![Device](https://img.shields.io/badge/Device-XC7S50CSGA324--1-blue?style=for-the-badge)](#2-target-hardware)
[![Build](https://img.shields.io/badge/Build-Complete%20%E2%9C%85-brightgreen?style=for-the-badge)](#4-vivado-results)
[![WNS](https://img.shields.io/badge/Setup%20WNS-%2B2.489%20ns-brightgreen?style=for-the-badge)](#41-timing)
[![Hold](https://img.shields.io/badge/Hold%20WHS-%2B0.151%20ns-brightgreen?style=for-the-badge)](#41-timing)
[![DRC](https://img.shields.io/badge/DRC-0%20Errors-brightgreen?style=for-the-badge)](#44-drc)
[![Power](https://img.shields.io/badge/Power-77%20mW-yellow?style=for-the-badge)](#42-power)

</div>

---

## Table of Contents

1. [What Is FPGA Implementation?](#1-what-is-fpga-implementation)
2. [Target Hardware](#2-target-hardware)
3. [Folder Structure](#3-folder-structure)
4. [Vivado Results](#4-vivado-results)
   - 4.1 [Timing](#41-timing)
   - 4.2 [Power](#42-power)
   - 4.3 [Utilisation](#43-utilisation)
   - 4.4 [DRC](#44-drc)
5. [How to Build](#5-how-to-build)
6. [Build Script Walkthrough](#6-build-script-walkthrough)
7. [Constraints File](#7-constraints-file)
8. [Programming the Board](#8-programming-the-board)
9. [What Happens After Programming](#9-what-happens-after-programming)

---

## 1. What Is FPGA Implementation?

An FPGA (Field-Programmable Gate Array) is a chip made of configurable logic blocks. Rather than fabricating a custom silicon chip, you configure an FPGA to **behave exactly like your RTL design** — giving you real hardware validation at a fraction of the cost and turnaround time of tape-out.

The implementation flow has three stages:

```
  Verilog / SystemVerilog RTL
            │
            ▼
  ┌─────────────────────────────────────────────────┐
  │  SYNTHESIS                                      │
  │  Maps RTL to technology primitives:             │
  │  LUTs (combinational logic) + FFs (registers)   │
  └──────────────────────┬──────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────┐
  │  IMPLEMENTATION                                 │
  │  Place  — assigns cells to physical locations   │
  │  Route  — draws wires between placed cells      │
  │  Verify — confirms all timing paths are met     │
  └──────────────────────┬──────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────┐
  │  BITSTREAM GENERATION                           │
  │  Produces soc_top_demo.bit                      │
  │  Program to board → CPU starts running          │
  └─────────────────────────────────────────────────┘
```

---

## 2. Target Hardware

| Parameter | Value |
|-----------|-------|
| **Board** | Digilent Spartan-7 Boolean Board |
| **FPGA Device** | Xilinx XC7S50CSGA324-1 |
| **Speed Grade** | -1 |
| **Clock** | 100 MHz on-board crystal oscillator |
| **Logic Capacity** | 32,600 LUTs · 65,200 FFs · 75 BRAMs · 120 DSPs |
| **I/O Capacity** | 210 bonded IOBs |
| **On-board Peripherals** | USB-UART bridge · 8 LEDs · 8 slide switches · 8-digit 7-segment display |
| **EDA Tool** | Xilinx Vivado 2023.1 |

---

## 3. Folder Structure

```
fpga/
├── constraints/
│   ├── soc_top_boolean.xdc      ← Main constraints (pin assignments + timing)
│   ├── soc_top_demo.xdc         ← Demo top-level constraints
│   └── riscv_soc.xdc            ← Base project constraints
│
├── scripts/
│   ├── vivado_riscv_soc_v2.tcl  ← Full automated build: synth → impl → bitstream
│   ├── run_impl.tcl             ← Implementation only (if synthesis already done)
│   └── run_reports.tcl          ← Generate all reports without rebuilding
│
├── reports/
│   ├── utilization.rpt          ← LUT / FF / BRAM / IO usage
│   ├── timing.rpt               ← WNS, TNS, failing endpoints
│   ├── power.rpt                ← On-chip power breakdown
│   ├── drc.rpt                  ← Design Rule Check results
│   └── clock.rpt                ← Clock domain summary
│
└── bitstream/
    ├── soc_top_demo.bit         ← ← ← Program this to the FPGA board
    └── soc_top_demo.bin         ← Alternative binary format
```

---

## 4. Vivado Results

All results are from **Vivado 2023.1**, post-implementation, device `xc7s50csga324-1`.

| Stage | Status | Messages |
|-------|--------|----------|
| **Synthesis** | ✅ Complete | 19 warnings · 0 errors |
| **Implementation** | ✅ Complete | 1 critical warning · 2 warnings · 0 errors |

> The critical warning in implementation is a clock-buffer methodology advisory (BUFG usage). It does not affect functionality, timing closure, or bitstream correctness.

---

### 4.1 Timing

<img width="1608" height="858" alt="image" src="https://github.com/user-attachments/assets/4e2f2bfc-edd1-43dc-b2a4-ed5cb2d9ed99" />

**Vivado verdict: "All user specified timing constraints are met."**

The full timing report covers all three STA modes — Setup, Hold, and Pulse Width — across all 640 analysed endpoints.

#### Setup (Critical Path — Register-to-Register)

| Metric | Value | Status |
|--------|-------|--------|
| Worst Negative Slack (WNS) | **+2.489 ns** | ✅ Positive — setup fully met |
| Total Negative Slack (TNS) | **0.000 ns** | ✅ Zero accumulated deficit |
| Failing Endpoints | **0 / 640** | ✅ Every single path passes |

#### Hold (Minimum Delay — No Early Capture)

| Metric | Value | Status |
|--------|-------|--------|
| Worst Hold Slack (WHS) | **+0.151 ns** | ✅ Positive — hold fully met |
| Total Hold Slack (THS) | **0.000 ns** | ✅ Zero accumulated deficit |
| Failing Endpoints | **0 / 640** | ✅ Every single path passes |

#### Pulse Width (Clock Integrity)

| Metric | Value | Status |
|--------|-------|--------|
| Worst Pulse Width Slack (WPWS) | **+9.500 ns** | ✅ |
| Total Pulse Width Negative Slack (TPWS) | **0.000 ns** | ✅ |
| Failing Endpoints | **0 / 258** | ✅ |

#### What These Numbers Mean

With a **10 ns clock period** (100 MHz), a Setup WNS of **+2.489 ns** means the critical combinational path completes in **7.511 ns**, with 2.489 ns of margin to spare. At this speed grade, the design could theoretically be pushed to approximately **133 MHz** before setup violations would appear.

The Hold WHS of **+0.151 ns** confirms that no flip-flop captures data before it is stable. Hold violations are often introduced by clock tree synthesis; the positive margin here confirms clean clock distribution throughout the design.

---

### 4.2 Power

<img width="1608" height="858" alt="image" src="https://github.com/user-attachments/assets/1fcad019-96b9-47fb-b1af-156bcf81e057" />

| Metric | Value |
|--------|-------|
| **Total On-Chip Power** | **0.077 W (77 mW)** |
| **Junction Temperature** | **25.4 °C** |
| Thermal Margin | 59.6 °C (12.0 W headroom) |
| Ambient Temperature | 25.0 °C |
| Effective θJA | 4.9 °C/W |
| Power to off-chip devices | 0 W |
| Process Corner | Typical |
| Confidence Level | Low* |

#### On-Chip Power Breakdown

| Category | Power (W) | Share of Total |
|----------|-----------|----------------|
| **Dynamic** | **0.005 W** | **7%** |
| &nbsp;&nbsp;&nbsp;&nbsp;Clocks | 0.001 W | 17% of dynamic |
| &nbsp;&nbsp;&nbsp;&nbsp;Signals | <0.001 W | 3% of dynamic |
| &nbsp;&nbsp;&nbsp;&nbsp;Logic | <0.001 W | 3% of dynamic |
| &nbsp;&nbsp;&nbsp;&nbsp;I/O | 0.004 W | 77% of dynamic |
| **Device Static** | **0.072 W** | **93%** |

The power profile is dominated by **device static power (93%, 72 mW)** — the quiescent leakage of the XC7S50 die itself, independent of any logic switching. This is normal and expected for an FPGA prototype running at low logic utilisation. Dynamic power is only **5 mW** total, reflecting the small logic footprint of the SoC.

Within dynamic power, the **I/O subsystem accounts for 77% (4 mW)** — consistent with a peripheral-heavy design actively driving UART, GPIO, and 7-segment display pins.

> **On confidence level:** Power confidence is rated **Low** because switching activity was derived from the constraints file and vectorless analysis rather than an annotated `.saif` file from post-implementation simulation. The static component (93% of total) is accurate regardless of confidence. To obtain a high-confidence dynamic power estimate, run a post-implementation timing simulation with representative input stimulus and annotate the resulting `.saif` before re-running the power report.

**Thermal note:** A junction temperature of **25.4 °C** with **59.6 °C of thermal margin** (12.0 W headroom) means the device operates comfortably at room temperature with no heatsink required. The board can sustain ambient temperatures up to approximately **85 °C** before thermal risk.

---

### 4.3 Utilisation

<img width="1599" height="904" alt="image" src="https://github.com/user-attachments/assets/612d0cd5-c394-46d3-8977-58b428e2b4dc" />


| Resource | Utilisation | Available | Used % |
|----------|-------------|-----------|--------|
| **Slice LUTs** | — | 32,600 | **1%** |
| **Slice FFs (Registers)** | — | 65,200 | **1%** |
| **Bonded IO** | — | 210 | **32%** |
| **BUFG** | — | 32 | **3%** |
| Block RAM | 0 | 75 | 0% |
| DSP | 0 | 120 | 0% |

The design occupies only **1% of available LUTs and FFs** while consuming **32% of I/O pins** — the characteristic signature of a peripheral-heavy SoC. The CPU core, memories, and all peripheral register logic fit comfortably within the logic budget, leaving enormous headroom for future expansion: pipelining the CPU, adding more peripherals, or scaling program memory.

Zero BRAMs and DSPs are consumed. No block RAM macros or multiplier primitives are instantiated in this design.

---

### 4.4 DRC

| Severity | Count | Impact |
|----------|-------|--------|
| Critical | **0** | ✅ None |
| Error | **0** | ✅ None |
| Warning | **1** | ℹ️ Informational only |

Zero DRC errors of any severity. The single warning is a clock-buffer methodology advisory and does not affect bitstream correctness, board operation, or timing closure. See `fpga/reports/drc.rpt` for the full report.

---

## 5. How to Build

### Option A — Fully Automated (Recommended)

Run the complete flow — synthesis, implementation, and bitstream generation — with one command:

```bash
vivado -mode batch -source fpga/scripts/vivado_riscv_soc_v2.tcl
```

Build time: approximately 5–15 minutes depending on host machine. Output:

```
fpga/bitstream/soc_top_demo.bit
```

---

### Option B — Vivado GUI

1. Open Vivado 2023.1
2. Create a new RTL project targeting part `xc7s50csga324-1`
3. Add all design sources from `rtl/`
4. Add constraints file: `fpga/constraints/soc_top_boolean.xdc`
5. Set top module to `soc_top_demo`
6. Flow Navigator → **Run Synthesis** → **Run Implementation** → **Generate Bitstream**

---

### Option C — Implementation Only

If synthesis has already completed and only implementation needs to be re-run (e.g. after a constraint change):

```bash
vivado -mode batch -source fpga/scripts/run_impl.tcl
```

---

### Option D — Pre-Built Bitstream

> The bitstream is already built and committed to the repository.
> To test the hardware immediately, skip the build entirely:
>
> ```
> fpga/bitstream/soc_top_demo.bit
> ```

---

## 6. Build Script Walkthrough

The TCL script `vivado_riscv_soc_v2.tcl` runs these steps in order:

| Step | TCL Command | Action |
|------|-------------|--------|
| 1 | `read_verilog` | Load all `.v` / `.sv` RTL sources from `rtl/` |
| 2 | `read_xdc` | Load pin assignments and timing constraints |
| 3 | `synth_design -top soc_top_demo` | Synthesise RTL → LUTs and flip-flops |
| 4 | `opt_design` | Optimise netlist — remove redundant logic |
| 5 | `place_design` | Place all logic primitives on FPGA fabric |
| 6 | `phys_opt_design` | Physical optimisation for critical-path timing |
| 7 | `route_design` | Route all net connections between placed cells |
| 8 | `write_bitstream` | Generate final `.bit` programming file |

All reports are written automatically to `fpga/reports/` after each relevant stage.

---

## 7. Constraints File

### Timing Constraint

```tcl
# 100 MHz system clock — 10 ns period
create_clock -period 10.000 -name sys_clk [get_ports clk]

# I/O timing budgets
set_input_delay  -clock sys_clk 2.0 [all_inputs]
set_output_delay -clock sys_clk 2.0 [all_outputs]
```

This allocates **8.0 ns** of combinational logic budget per path after accounting for I/O delays. The achieved critical path of **7.511 ns** (WNS +2.489 ns) uses 94% of this budget — well within margin.

---

### Pin Assignments

| Signal | FPGA Pin | Board Resource | Direction |
|--------|----------|----------------|-----------|
| `clk` | W5 | 100 MHz crystal oscillator | Input |
| `rst_n` | U18 | SW0 — slide left = active-low reset | Input |
| `uart_tx` | B18 | USB-UART bridge TX → PC COM port | Output |
| `gpio_out[0]` | U16 | LED LD0 | Output |
| `gpio_out[1]` | E19 | LED LD1 | Output |
| `gpio_out[2]` | U19 | LED LD2 | Output |
| `gpio_out[3]` | V19 | LED LD3 | Output |
| `gpio_out[4]` | W18 | LED LD4 | Output |
| `gpio_out[5]` | U15 | LED LD5 | Output |
| `gpio_out[6]` | U14 | LED LD6 | Output |
| `gpio_out[7]` | V14 | LED LD7 | Output |
| `gpio_in[0]` | V17 | Slide switch SW0 | Input |
| `gpio_in[1]` | V16 | Slide switch SW1 | Input |
| `gpio_in[2]` | W16 | Slide switch SW2 | Input |
| `gpio_in[3]` | W17 | Slide switch SW3 | Input |
| `gpio_in[4]` | W15 | Slide switch SW4 | Input |
| `gpio_in[5]` | V15 | Slide switch SW5 | Input |

See `fpga/constraints/soc_top_boolean.xdc` for all 7-segment display segment and anode pin assignments.

---

## 8. Programming the Board

### Via Vivado Hardware Manager

```
1. Connect the Boolean board to your PC via the USB programming cable
2. Open Vivado → Flow Navigator → Hardware Manager → Open Hardware Manager
3. Click "Open Target" → "Auto Connect"
4. Device xc7s50_0 should appear in the Hardware panel
5. Right-click the device → "Program Device..."
6. Set Bitstream file to: fpga/bitstream/soc_top_demo.bit
7. Click "Program"
```

Programming completes in approximately 3–5 seconds. The CPU begins executing from reset vector `0x00000000` immediately after the progress bar completes.

### Via Vivado Tcl Console

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {fpga/bitstream/soc_top_demo.bit} [get_hw_devices xc7s50_0]
program_hw_devices [get_hw_devices xc7s50_0]
```

---

## 9. What Happens After Programming

The CPU starts executing the demo program (`sw/demo.S`) from `0x00000000` the moment programming completes.

### UART Output

Open a serial terminal at **115200 baud, 8N1** on the COM port assigned to the board:

```
RISCV SOC OK
```

This confirms the full SoC datapath is working: instruction fetch → decode → register file → ALU → data memory → UART peripheral register write → bus.

### LEDs

The 8 LEDs (LD0–LD7) mirror the 8 slide switches (SW0–SW7) in real time. Toggling any switch immediately toggles the corresponding LED — confirming GPIO peripheral access, memory-mapped register reads and writes, and the CPU control loop.

### 7-Segment Display

The binary value of the switch positions is displayed as hexadecimal on the 7-segment display. All switches off = `0x00`; all switches on = `0xFF`.

---

<div align="center">

**RISC-V SoC — FPGA Implementation**

Setup WNS +2.489 ns ✅ · Hold WHS +0.151 ns ✅ · WPWS +9.500 ns ✅
0 DRC Errors ✅ · 640 Endpoints · 77 mW · 25.4 °C

*Part of the full RTL → Simulation → FPGA → Synthesis → Place & Route → GDSII flow*

Saveetha Engineering College — ECE Department
Arunachalam P (212223060022) · Charan PG (212223060033)

</div>
