# FPGA Implementation

This folder contains everything needed to build and deploy the RISC-V SoC on the **Xilinx Spartan-7 Boolean Board** using Vivado.

---

## What Is FPGA Implementation?

An FPGA (Field-Programmable Gate Array) is a chip full of configurable logic blocks. Instead of designing a custom chip, you configure an FPGA to behave exactly like your design. It's a fast and cheap way to test hardware before committing to actual chip manufacturing.

The implementation flow has three stages:
1. **Synthesis** — Vivado converts your Verilog code into logic gates (LUTs and flip-flops)
2. **Implementation** — Vivado places those gates on the FPGA fabric and connects them with wires (routing)
3. **Bitstream** — Vivado generates a `.bit` file that programs the FPGA

---

## Target Hardware

| | |
|--|--|
| **Board** | Spartan-7 Boolean Board (by Digilent) |
| **FPGA Chip** | Xilinx XC7S50CSGA324-1 |
| **Clock** | 100 MHz onboard oscillator |
| **Interfaces** | UART via USB-UART bridge, 8 LEDs, 8 slide switches, 8-digit 7-segment display |
| **Tool** | Xilinx Vivado 2023.1 |

---

## Folder Structure

```
fpga/
├── constraints/
│   ├── soc_top_boolean.xdc    ← Main constraints file (pin assignments + timing)
│   ├── soc_top_demo.xdc       ← Demo top-level constraints
│   └── riscv_soc.xdc          ← Base project constraints
├── scripts/
│   ├── vivado_riscv_soc_v2.tcl   ← Full automated build (synth → impl → bitstream)
│   ├── run_impl.tcl              ← Run just implementation (if synthesis already done)
│   └── run_reports.tcl           ← Generate reports only
├── reports/
│   ├── utilization.rpt        ← How many LUTs, FFs, BRAMs are used
│   ├── timing.rpt             ← Timing analysis (is 100 MHz met?)
│   ├── power.rpt              ← On-chip power consumption
│   ├── drc.rpt                ← Design Rule Check (0 violations)
│   └── clock.rpt              ← Clock domain summary
└── bitstream/
    ├── soc_top_demo.bit       ← Program this to the FPGA board
    └── soc_top_demo.bin       ← Alternative binary format
```

---

## How to Build

### Option 1 — Fully Automated (Command Line)

Run the complete flow (synthesis → implementation → bitstream) with one command:

```bash
vivado -mode batch -source fpga/scripts/vivado_riscv_soc_v2.tcl
```

This takes several minutes. When done, the bitstream is at `fpga/bitstream/soc_top_demo.bit`.

### Option 2 — Vivado GUI

1. Open Vivado
2. Create or open a project
3. Add all design sources from `rtl/`
4. Add the constraints file: `fpga/constraints/soc_top_boolean.xdc`
5. Set the top module to: `soc_top_demo`
6. Click **Run Synthesis**, then **Run Implementation**, then **Generate Bitstream**

### Option 3 — Implementation Only

If synthesis was already run and you just need to re-run implementation:

```bash
vivado -mode batch -source fpga/scripts/run_impl.tcl
```

---

## What the Build Script Does

The TCL script `vivado_riscv_soc_v2.tcl` runs these steps in order:

1. `read_verilog` — loads all Verilog source files from `rtl/`
2. `read_xdc` — loads pin assignment and timing constraints
3. `synth_design -top soc_top_demo` — synthesizes into LUTs and FFs
4. `opt_design` — optimizes the synthesized netlist
5. `place_design` — places logic blocks on the FPGA fabric
6. `phys_opt_design` — physically optimizes placement for better timing
7. `route_design` — routes all connections between placed blocks
8. `write_bitstream` — generates the final `.bit` file

---

## Constraints File (`soc_top_boolean.xdc`)

The constraints file tells Vivado two things:

**1. Timing — how fast to run:**
```tcl
create_clock -period 10.000 -name sys_clk [get_ports clk]
# 10 ns period = 100 MHz clock
```

**2. Pin assignments — which FPGA pin connects to which signal:**

| Signal | FPGA Pin | What it connects to on the board |
|--------|----------|----------------------------------|
| `clk` | W5 | 100 MHz crystal oscillator |
| `rst_n` | U18 | Slide switch SW0 (slide left = reset) |
| `uart_tx` | B18 | USB-UART bridge (shows up as COM port on PC) |
| `gpio_out[7:0]` | U16 – V14 | LEDs LD0–LD7 |
| `gpio_in[7:0]` | V17 – V15 | Slide switches SW0–SW7 |

See the `.xdc` file for the full list of all pin assignments.

---

## Programming the Board

Once you have the bitstream (`fpga/bitstream/soc_top_demo.bit`):

1. Connect the Boolean board to your computer via USB
2. Open Vivado
3. Click **Hardware Manager** (bottom of the Flow Navigator)
4. Click **Open Target** → **Auto Connect**
5. Right-click on the device in the Hardware panel → **Program Device**
6. Browse to: `fpga/bitstream/soc_top_demo.bit`
7. Click **Program**

The board is programmed in seconds. The CPU starts running immediately.

> **The bitstream is already built.** If you just want to test the hardware, you can skip building and use the pre-built `soc_top_demo.bit` directly.

---

## What Happens After Programming

The CPU immediately starts running the demo program (`sw/demo.S`):

- **UART:** Opens a serial terminal at 115200 baud (e.g. PuTTY or minicom) and you'll see `RISCV SOC OK` printed
- **LEDs:** The 8 LEDs mirror the state of the 8 slide switches in real time
- **7-Segment Display:** Shows the binary value of the switches as hex digits

This confirms the CPU is running and all the peripherals (UART, GPIO, Seg7) are working.

---

## Understanding the Reports

After building, Vivado generates reports in `fpga/reports/`:

**`utilization.rpt`** — How much of the FPGA is used  
Look for "Slice LUTs" and "Slice Registers" to see logic usage. The SoC is small relative to the XC7S50's capacity.

**`timing.rpt`** — Does the design meet 100 MHz?  
Look for **WNS (Worst Negative Slack)**. A positive WNS means timing is met. Negative means there's a timing violation.

**`power.rpt`** — Power consumption breakdown  
Total on-chip power is approximately 68 mW (mostly static/idle power of the FPGA device itself).

**`drc.rpt`** — Design Rule Check  
Should show 0 violations. Any violations here would prevent the bitstream from working correctly.

---

## Adding Screenshots

After running the implementation and programming the board, add screenshots to [`docs/images/fpga/`](../docs/images/fpga/):

- Vivado schematic view (post-synthesis)
- Device view showing placement (post-implementation)
- Timing summary
- Utilization summary
- Photos of the board running the demo
