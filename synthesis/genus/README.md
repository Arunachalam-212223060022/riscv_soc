# Cadence Genus — Logic Synthesis

This folder contains everything needed to run **logic synthesis** using Cadence Genus — the step that converts Verilog RTL into a gate-level netlist using a standard cell library.

---

## What Is Logic Synthesis?

Logic synthesis takes your Verilog code (which describes *what* the hardware does) and converts it into a netlist of real standard cells (AND gates, OR gates, flip-flops, etc.) from a library — describing *how* the hardware is physically built.

After synthesis, you know:
- Exactly which gates are used and how many
- Whether the design meets your timing target (100 MHz)
- Estimated power consumption
- Chip area

---

## Folder Structure

```
genus/
├── rtl/                    ← Cadence-compatible RTL (wire-fixed Verilog)
│   ├── soc_top.v           ← Top-level SoC
│   ├── cpu/                ← All CPU modules
│   │   ├── cpu_top.v
│   │   ├── pc.v
│   │   ├── regfile.v
│   │   ├── alu.v
│   │   ├── alu_ctrl.v
│   │   ├── control.v
│   │   └── immgen.v
│   ├── memory/
│   │   ├── imem.v
│   │   └── dmem.v
│   └── peripheral/
│       ├── uart.v
│       ├── gpio.v
│       ├── timer.v
│       ├── intc.v
│       ├── spi.v
│       ├── i2c.v
│       └── seg7_ctrl.v
├── scripts/
│   ├── genus_run.tcl       ← Main synthesis script (run this)
│   └── constraints.sdc     ← Timing constraints (100 MHz clock, I/O delays)
├── reports/                ← Generated after running synthesis
│   ├── area.rpt            ← Cell area breakdown
│   ├── timing.rpt          ← Timing analysis (WNS, critical path)
│   ├── power.rpt           ← Leakage and dynamic power
│   └── gates.rpt           ← Gate count by type
└── netlist/                ← Generated after running synthesis
    ├── soc_top_netlist.v   ← Gate-level netlist (input to Innovus)
    ├── soc_top.sdc         ← Propagated timing constraints
    └── soc_top.sdf         ← Standard delay file (for timing simulation)
```

---

## Before You Start

You need:
1. **Cadence Genus** installed and licensed
2. A **standard cell library** (`slow.lib`) placed at `synthesis/genus/lib/slow.lib`

The `slow.lib` is the "slow corner" timing library — synthesis with the slow corner ensures the design works even in worst-case conditions (slow transistors, low voltage, high temperature).

---

## How to Run Synthesis

### Command Line (Batch Mode)
```bash
cd synthesis/genus/
genus -batch -files scripts/genus_run.tcl
```

### Genus GUI
```bash
genus &
# In Genus: File → Open Script → scripts/genus_run.tcl
```

Synthesis takes a few minutes. When done, the `reports/` and `netlist/` folders will be populated.

---

## What the Synthesis Script Does

The script `scripts/genus_run.tcl` runs these steps:

**1. Setup — Tell Genus where to find things**
```tcl
set_db init_lib_search_path {./lib}   # Where to find slow.lib
set_db init_hdl_search_path {./rtl}   # Where to find the Verilog files
```

**2. Load the standard cell library**
```tcl
read_libs slow.lib
```
This tells Genus what gates are available: which cells, their timing, area, and power.

**3. Read the RTL files (bottom-up order)**
```tcl
read_hdl cpu/pc.v
read_hdl cpu/regfile.v
read_hdl cpu/alu.v
read_hdl cpu/alu_ctrl.v
read_hdl cpu/immgen.v
read_hdl cpu/control.v
read_hdl cpu/cpu_top.v
read_hdl memory/imem.v
read_hdl memory/dmem.v
read_hdl peripheral/gpio.v
read_hdl peripheral/timer.v
read_hdl peripheral/uart.v
read_hdl peripheral/spi.v
read_hdl peripheral/i2c.v
read_hdl peripheral/intc.v
read_hdl peripheral/seg7_ctrl.v
read_hdl soc_top.v
```
Bottom-up order means sub-modules are defined before the modules that use them.

**4. Elaborate and check**
```tcl
elaborate soc_top
check_design -unresolved   # Fails if any module is missing (black box)
```

**5. Apply timing constraints**
```tcl
read_sdc ./constraints.sdc
```

**6. Three-pass synthesis**
```tcl
syn_generic   # Pass 1: Boolean optimization (gate-independent)
syn_map       # Pass 2: Map to actual standard cells from the library
syn_opt       # Pass 3: Timing and area optimization after mapping
```

**7. Write reports and outputs**
```tcl
report_timing  > reports/timing.rpt    # Is 100 MHz timing met?
report_power   > reports/power.rpt     # How much power does it use?
report_area    > reports/area.rpt      # How much area does it take?
report_gates   > reports/gates.rpt     # How many gates of each type?

write_hdl  > netlist/soc_top_netlist.v  # Gate-level netlist → goes to Innovus
write_sdf  > netlist/soc_top.sdf        # Delay info for timing simulation
write_sdc  > netlist/soc_top.sdc        # Constraints for Innovus
```

---

## Understanding the Timing Constraints (`constraints.sdc`)

| Constraint | Value | Why |
|-----------|-------|-----|
| Clock period | 10.0 ns | Targets 100 MHz operation |
| Clock transition | 0.1 ns | Rise/fall time of the clock signal |
| Clock uncertainty | 0.15 ns | Accounts for clock jitter |
| Input delay | 2.0 ns | External inputs arrive 2 ns after clock edge |
| Output delay | 2.0 ns | Outputs must be ready 2 ns before next clock |
| Reset (`rst_n`) | False path | Async reset — excluded from timing analysis |

With these constraints, the actual budget for combinational logic is:  
**10 ns − 0.15 ns (uncertainty) − 2 ns (input) − 2 ns (output) = 5.85 ns**

The driving cell and load models help Genus estimate wire delays during optimization.

---

## Understanding the Reports

### `reports/timing.rpt`
Look for **WNS (Worst Negative Slack)**:
- WNS ≥ 0 ns → timing is met ✓
- WNS < 0 ns → timing violation (the critical path is too slow)

The report also shows the **critical path** — the longest chain of logic that determines the maximum clock speed.

### `reports/area.rpt`
Shows total cell area in µm² and the breakdown between:
- **Combinational area** — gates like AND, OR, MUX
- **Sequential area** — flip-flops that hold state

### `reports/power.rpt`
Shows:
- **Leakage power** — power consumed even when nothing is switching
- **Dynamic power** — power consumed by switching activity

### `reports/gates.rpt`
Lists each standard cell type used and how many. Useful for understanding what the synthesis tool chose.

---

## What the Netlist Looks Like

The output `soc_top_netlist.v` is Verilog, but instead of your behavioral RTL, it contains gate-level instantiations:

```verilog
// Instead of: assign result = a + b;
// You get something like:
FA1X fa1 (.A(a[0]), .B(b[0]), .CI(1'b0), .CO(carry[0]), .S(result[0]));
FA1X fa2 (.A(a[1]), .B(b[1]), .CI(carry[0]), .CO(carry[1]), .S(result[1]));
// ... and so on for every bit
```

This netlist is the input to Cadence Innovus for place and route.

---

## RTL Differences from `rtl/` (Original)

The RTL in `synthesis/genus/rtl/` was adapted from the original `rtl/` for Cadence compatibility:

| What changed | Why |
|-------------|-----|
| `logic` → `wire` for all internal nets | Cadence Verilog-2001 mode doesn't support `logic` as a net type |
| Added SPI, I2C, Seg7 peripherals to the top-level | Expanded SoC for a more complete ASIC demonstration |

The core CPU, memory, and base peripherals are functionally identical.

---

## Screenshots

After running synthesis, add report screenshots to [`docs/images/synthesis/`](../../docs/images/synthesis/).
