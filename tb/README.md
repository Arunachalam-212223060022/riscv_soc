# Testbenches

This folder contains **simulation tests** for every module in the SoC. Each testbench (TB) is a SystemVerilog file that creates an instance of a hardware module, feeds it inputs, and checks that the outputs are correct.

Think of testbenches as unit tests — but for hardware.

---

## What Is a Testbench?

A testbench is a simulation wrapper that:
1. Creates an instance of the module being tested
2. Applies test inputs (called "stimulus")
3. Waits for outputs
4. Checks if outputs match expected values and prints PASS or FAIL

Testbenches are not synthesized — they only exist for simulation.

---

## Testbench List

| File | Module Tested | What It Checks |
|------|--------------|----------------|
| `tb_alu.sv` | `alu.v` | All 10 ALU operations, the zero flag |
| `tb_regfile.sv` | `regfile.v` | Write then read back, x0 always returns 0, simultaneous rs1+rs2 reads |
| `tb_immgen.sv` | `immgen.v` | All 5 immediate formats and their sign extension |
| `tb_control.sv` | `control.v` | Each opcode produces the correct 11 control signals |
| `tb_uart.sv` | `uart.v` | TX byte shifts out at correct baud rate, IRQ assertion |
| `tb_gpio.sv` | `gpio.v` | Output register write-and-readback, input register |
| `tb_timer.sv` | `timer.v` | Load → count → timeout → IRQ, auto-reload behavior |
| `tb_intc.sv` | `intc.v` | Multiple sources set PENDING, enable mask filters, irq_to_cpu asserts |
| `tb_spi.sv` | `spi.v` | Full SPI frame: CS_N low, 8 clock edges, data shifts out |
| `tb_i2c.sv` | `i2c.v` | I2C start condition, byte transfer, stop condition |
| `tb_cpu_top.sv` | `cpu_top.v` | CPU executing a multi-instruction program |
| `tb_soc_top.sv` | `soc_top.v` | Full SoC: CPU writes to GPIO and UART, timer fires interrupt |

---

## Running Simulations

### Option 1 — Run Everything at Once (VCS)

```bash
# From the repo root directory
bash tb/run_sim.sh
```

This runs all testbenches one after another and reports PASS/FAIL for each.

### Option 2 — Run One Testbench (VCS)

```bash
# From the repo root directory
vcs -full64 -sverilog +define+SIMULATION \
    -f sim/filelist/rtl.f \
    tb/tb_soc_top.sv \
    -o simv_soc -l compile.log

./simv_soc -l sim.log
```

Replace `tb_soc_top.sv` with any other testbench file to test that module instead.

### Option 3 — View Waveforms with Verdi

```bash
# Compile with debug info
vcs -full64 -sverilog -debug_access+all \
    -f sim/filelist/rtl.f tb/tb_soc_top.sv \
    -o simv_soc

# Run and open Verdi GUI
./simv_soc -gui
```

In Verdi, load the waveform file (`dump.fsdb`) to see signal values over time as a waveform.

### Option 4 — Cadence NCLaunch

NCLaunch needs a slightly different set of source files because Cadence tools don't support the `logic` keyword in standard Verilog mode.

1. Launch NCLaunch
2. Add filelist: `sim/filelist/rtl_nclaunch.f` (points to wire-fixed RTL in `synthesis/genus/rtl/`)
3. Add testbench: `tb/tb_soc_top.sv`
4. Set top module: `tb_soc_top`
5. Run simulation

### Option 5 — Vivado XSim

1. Open Vivado → add all files from `rtl/` as design sources
2. Add the testbench file as a simulation source
3. Set `tb_soc_top` as the simulation top
4. Flow → Run Simulation → Run Behavioral Simulation

---

## Other Files

### `run_sim.sh` — Batch Simulation Script

Runs all testbenches using VCS and prints a summary. Edit this script if you want to add a new testbench to the batch run.

Usage:
```bash
bash tb/run_sim.sh
```

---

## What Good Output Looks Like

A passing simulation of `tb_soc_top.sv` prints something like:

```
[TB] Reset released at t=100ns
[TB] GPIO write: addr=0x20000000 data=0xA5
[TB] UART TX start
[TB] Timer IRQ asserted
[TB] INTC forwarding IRQ to CPU
[TB] ALL TESTS PASSED
```

Any FAIL message means a module output didn't match what was expected — that usually points to a bug in the RTL.

---

## Adding a New Testbench

1. Create a new `.sv` file in `tb/`, e.g. `tb_mymodule.sv`
2. Follow the pattern of an existing testbench:
   - `timescale 1ns/1ps`
   - Instantiate the module under test
   - Generate a clock with `always #5 clk = ~clk;`
   - Apply stimulus with `initial begin ... end`
   - Check outputs with `if (out !== expected) $display("FAIL");`
3. Add the new file to `tb/run_sim.sh` if you want it included in batch runs

---

## Waveform Screenshots

Add simulation waveform screenshots to [`docs/images/simulation/`](../docs/images/simulation/) for documentation.
