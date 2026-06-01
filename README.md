# RISC-V SoC — From Code to Chip

> A complete RISC-V processor and system-on-chip built from scratch in Verilog, verified in simulation, tested on real FPGA hardware, and taken all the way through ASIC chip design flow.

---

## What Is This Project?

This project builds a **RISC-V processor** (a type of CPU) from scratch using Verilog — the hardware description language used to design real chips. The design was:

1. **Written** — every logic block coded in Verilog/SystemVerilog
2. **Simulated** — tested in three different simulation tools to confirm it works correctly
3. **Deployed to FPGA** — programmed onto a real chip (Spartan-7 Boolean Board) and physically tested
4. **Synthesized and placed** — run through the same professional tools used to make actual silicon chips, producing a GDSII file (the blueprint sent to a chip fab)

If you've ever wondered how a CPU works at the transistor level, or how engineers go from code to a physical chip, this project walks through that entire journey.

---

## What Does "RISC-V" Mean?

**RISC-V** (pronounced "risk five") is an open, free instruction set — basically the "language" a CPU understands. Just like x86 is what Intel CPUs speak and ARM is what phone chips speak, RISC-V is an alternative that anyone can use without paying licensing fees.

This project implements the **RV32I** subset — 32-bit, base integer instructions — which is 37 instructions total. That's enough to run real programs.

---

## What Is an SoC?

**SoC** stands for System-on-Chip. Instead of just a CPU, an SoC includes the CPU *plus* all the other hardware a system needs — memory, communication ports, timers, etc. — all on one chip.

This SoC includes:

| Component | What it does |
|-----------|-------------|
| **CPU Core** | Executes RISC-V instructions |
| **Instruction Memory (IMEM)** | Stores the program (like a ROM) |
| **Data Memory (DMEM)** | Stores variables while the program runs (like RAM) |
| **UART** | Serial communication (like a USB-to-serial port) |
| **GPIO** | Controls LEDs, reads switches |
| **SPI** | High-speed serial protocol for sensors/displays |
| **I2C** | Another serial protocol, common for sensors |
| **Timer** | Counts time, generates interrupts |
| **Interrupt Controller (INTC)** | Manages which events the CPU should respond to |
| **7-Segment Display Driver** | Drives the digit displays on the FPGA board |

---

## Project At a Glance

| Fact | Value |
|------|-------|
| CPU Architecture | Single-cycle RISC-V RV32I |
| Clock Speed | 100 MHz |
| Instruction Memory | 8 KB |
| Data Memory | 8 KB |
| Number of Peripherals | 7 |
| FPGA Board | Xilinx Spartan-7 (Boolean Board) |
| Simulation Tools | Synopsys VCS + Verdi, Cadence NCLaunch, Vivado XSim |
| ASIC Tools | Cadence Genus (synthesis) + Cadence Innovus (place & route) |
| DRC Violations | 0 |
| FPGA Power | 68 mW total |

---

## Repository Layout

```
riscv_soc/
│
├── rtl/              ← All the Verilog source code (the actual design)
│   ├── cpu/          ← CPU core: PC, registers, ALU, decoder, etc.
│   ├── memory/       ← Instruction and data memory
│   └── peripheral/   ← UART, GPIO, SPI, I2C, Timer, INTC, Seg7
│
├── tb/               ← Testbenches: code that tests each module
├── sim/              ← Simulation file lists (tells tools which files to compile)
│
├── fpga/             ← Everything for FPGA implementation
│   ├── constraints/  ← Pin assignments and timing constraints
│   ├── scripts/      ← Vivado build scripts
│   ├── reports/      ← Timing, power, utilization reports
│   └── bitstream/    ← The .bit file to program the FPGA board
│
├── synthesis/        ← ASIC design flow
│   ├── genus/        ← Cadence Genus logic synthesis (RTL → gates)
│   └── innovus/      ← Cadence Innovus place & route (gates → GDSII)
│
├── sw/               ← Embedded software: the assembly program the CPU runs
└── docs/             ← Images, screenshots, diagrams
```

Each folder has its own README that explains what's inside in detail.

---

## How the CPU Works (Simple Explanation)

The CPU is a **single-cycle** design — every instruction completes in exactly one clock cycle. Here's what happens for every instruction:

```
Clock tick ──►

1. FETCH      PC register → sends address to IMEM → gets 32-bit instruction
2. DECODE     Control unit reads opcode → generates control signals
              ImmGen reads instruction → produces immediate value
3. EXECUTE    Register file reads rs1, rs2
              ALU performs the operation (add, subtract, compare, etc.)
4. MEMORY     If it's a Load: read from DMEM
              If it's a Store: write to DMEM
5. WRITE-BACK If instruction produces a result: write it back to register file
              PC updates to next instruction address
```

All of steps 1–5 happen in one clock cycle. Simple, but it works for every RISC-V RV32I instruction.

---

## How Everything Connects

```
                    ┌──────────────────────────────┐
                    │        CPU Core               │
                    │  PC → IMEM → Decode → ALU     │
                    │  RegFile ← Writeback ←────── │
                    └──────────────┬───────────────┘
                                   │ Data Bus (address + data + read/write)
                    ┌──────────────▼───────────────┐
                    │      Address Decoder          │
                    │  (picks which peripheral      │
                    │   the CPU is talking to)      │
                    └──┬──┬──┬──┬──┬──┬────────────┘
                       │  │  │  │  │  │
                    DMEM UART GPIO Timer INTC SPI/I2C/Seg7
```

The CPU uses **memory-mapped I/O** — peripherals appear as if they are memory locations. Writing to address `0x10000000` sends a byte over UART. Reading address `0x20000004` reads the switch states. The address decoder figures out which peripheral to activate based on the address bits.

---

## Complete Design Flow

```
Write Verilog (rtl/)
       │
       ├──► Simulate (tb/ + sim/)
       │         ├── Synopsys VCS + Verdi
       │         ├── Cadence NCLaunch
       │         └── Vivado XSim
       │
       ├──► FPGA (fpga/)
       │         ├── Vivado: Synthesize + Implement
       │         ├── Generate bitstream (.bit file)
       │         └── Program Boolean board → TESTED ON HARDWARE ✓
       │
       └──► ASIC (synthesis/)
                 ├── Cadence Genus: RTL → Gate-level netlist
                 └── Cadence Innovus: Netlist → Floorplan → Place → Route → GDSII ✓
```

---

## Quick Start

### Run Simulations (VCS)
```bash
# Test all modules at once
bash tb/run_sim.sh

# Test just the full SoC
vcs -full64 -sverilog -f sim/filelist/rtl.f tb/tb_soc_top.sv -o simv
./simv
```

### Build FPGA Bitstream (Vivado)
```bash
vivado -mode batch -source fpga/scripts/vivado_riscv_soc_v2.tcl
# Output: fpga/bitstream/soc_top_demo.bit
```

### Program the Board
1. Connect the Boolean board over USB
2. Open Vivado → Hardware Manager → Auto Connect
3. Program Device → select `fpga/bitstream/soc_top_demo.bit`

### Run ASIC Synthesis (Genus)
```bash
cd synthesis/genus/
genus -batch -files scripts/genus_run.tcl
```

### Build the Embedded Software
```bash
cd sw/
make
# Produces: program.mem (loaded by the CPU's instruction memory)
```

---

## Tools Required

| Tool | Purpose |
|------|---------|
| Xilinx Vivado 2022.2+ | FPGA synthesis, implementation, bitstream |
| Synopsys VCS | RTL simulation |
| Synopsys Verdi | Waveform viewer |
| Cadence NCLaunch | Alternative simulation (Cadence-native) |
| Cadence Genus | ASIC logic synthesis |
| Cadence Innovus | ASIC place & route |
| RISC-V GNU Toolchain (`riscv64-unknown-elf`) | Compile the embedded software |
| Python 3.6+ | Run `bin2mem.py` conversion script |

---

## What the Demo Does

When the FPGA is programmed, the CPU immediately starts running the assembly program in `sw/demo.S`:

1. Prints `RISCV SOC OK` over UART at 115200 baud (visible in any serial terminal)
2. Continuously reads the 8 slide switches and mirrors their state to the 8 LEDs
3. Also sends the switch value to the 7-segment display

This demonstrates the CPU actually executing instructions and the memory-mapped peripherals responding correctly.

---

## Folder READMEs

| Folder | README |
|--------|--------|
| `rtl/` | [RTL Source Code](rtl/README.md) — every Verilog module explained |
| `tb/` | [Testbenches](tb/README.md) — how each module is tested |
| `sim/` | [Simulation Filelists](sim/README.md) — how to run simulations |
| `fpga/` | [FPGA Implementation](fpga/README.md) — Vivado flow and board programming |
| `sw/` | [Embedded Software](sw/README.md) — the assembly program and build steps |
| `synthesis/genus/` | [Genus Synthesis](synthesis/genus/README.md) — ASIC logic synthesis |
| `synthesis/innovus/` | [Innovus PnR](synthesis/innovus/README.md) — place, route, and GDSII |
| `docs/` | [Documentation](docs/README.md) — images and screenshots guide |

---

## About

**Institution:** Sri Sivasubramaniya Nadar College of Engineering  
**Department:** Electronics and Communication Engineering  
**Author:** Arunachalam (Roll No. 212223060022)  
**Project:** Design and Implementation of a RISC-V Soft-Core SoC on FPGA with Integrated Peripheral Subsystems
