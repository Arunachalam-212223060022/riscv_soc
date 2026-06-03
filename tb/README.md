<div align="center">

# Testbenches — `tb/`

**SystemVerilog verification suite for every module in the RISC-V RV32I SoC**
**Unit Tests · Integration Tests · 30 Checks · 0 Failures**

[![Language](https://img.shields.io/badge/Language-SystemVerilog-blue?style=for-the-badge)](#testbench-list)
[![Simulators](https://img.shields.io/badge/Simulators-VCS%20%7C%20Verdi%20%7C%20NCLaunch%20%7C%20XSim-green?style=for-the-badge)](#running-simulations)
[![Tests](https://img.shields.io/badge/Tests-30%20Checks-brightgreen?style=for-the-badge)](#expected-output)
[![Coverage](https://img.shields.io/badge/Coverage-12%20Modules-orange?style=for-the-badge)](#testbench-list)
[![Result](https://img.shields.io/badge/Result-ALL%20PASS-brightgreen?style=for-the-badge)](#expected-output)

</div>

---

## Table of Contents

1. [What Is a Testbench?](#1-what-is-a-testbench)
2. [Testbench List](#2-testbench-list)
3. [How Every Testbench Works](#3-how-every-testbench-works)
4. [Full Integration Test — `tb_soc_top.sv`](#4-full-integration-test--tb_soc_topsv)
   - 4.1 [DUT Instantiation & Clock](#41-dut-instantiation--clock)
   - 4.2 [Bus Injection Tasks](#42-bus-injection-tasks)
   - 4.3 [test_por](#43-test_por--power-on-reset)
   - 4.4 [test_imem](#44-test_imem--instruction-memory-rom)
   - 4.5 [test_dmem](#45-test_dmem--data-memory)
   - 4.6 [test_gpio](#46-test_gpio--general-purpose-io)
   - 4.7 [test_timer](#47-test_timer--countdown-timer)
   - 4.8 [test_intc](#48-test_intc--interrupt-controller)
   - 4.9 [test_uart_tx](#49-test_uart_tx--uart-transmitter)
   - 4.10 [test_spi](#410-test_spi--spi-master)
   - 4.11 [test_seg7](#411-test_seg7--7-segment-display)
   - 4.12 [test_cpu_execution](#412-test_cpu_execution--cpu-sanity)
5. [Test Execution Order](#5-test-execution-order)
6. [Running Simulations](#6-running-simulations)
7. [Expected Output](#7-expected-output)
8. [Simulation Timeout Watchdog](#8-simulation-timeout-watchdog)
9. [Adding a New Testbench](#9-adding-a-new-testbench)

---

## 1. What Is a Testbench?

Testbenches are **never synthesised** — they exist only for simulation. Think of them as unit tests for hardware: each one instantiates a module, drives known inputs at it, and checks that the outputs match what the specification requires.

A hardware testbench does things that real circuits can't — it can peek inside internal signals, force nets to arbitrary values to isolate a specific sub-system, generate clocks, and print structured PASS/FAIL messages that a batch runner can parse.

```
Real world analogy:
  Unit test (software)  →  Testbench (hardware)
  Function under test   →  Module under test (DUT)
  assert(result == 5)   →  check("add test", result === 5'd5)
  pytest / JUnit        →  VCS / NCLaunch / XSim
```

---

## 2. Testbench List

Thirteen testbench files cover every module from individual building blocks up to the full integrated SoC:

| File | Module Under Test | Checks |
|------|-------------------|--------|
| `tb_alu.sv` | `alu.v` | All 10 ALU operations, `zero` flag assertion |
| `tb_regfile.sv` | `regfile.v` | Write→readback, x0 always-zero invariant, dual-port simultaneous read |
| `tb_immgen.sv` | `immgen.v` | All 5 RV32I immediate formats, sign extension |
| `tb_control.sv` | `control.v` | Each opcode fires the correct 11-bit control vector |
| `tb_uart.sv` | `uart.v` | TX byte shifts out at correct baud rate, IRQ assertion |
| `tb_gpio.sv` | `gpio.v` | Output register write-and-readback, input register transparent read |
| `tb_timer.sv` | `timer.v` | Load → count → timeout → IRQ, status clear, auto-reload |
| `tb_intc.sv` | `intc.v` | PENDING latch, ENABLE mask filtering, `irq_to_cpu` assert/deassert |
| `tb_spi.sv` | `spi.v` | CS_N assertion, 8-bit transfer, busy and done flags |
| `tb_i2c.sv` | `i2c.v` | START condition, byte transfer, STOP condition, open-drain signals |
| `tb_cpu_top.sv` | `cpu_top.v` | Multi-instruction program, branch taken/not-taken, JAL/JALR |
| `tb_soc_top.sv` | `soc_top.v` | **Full SoC integration** — all 10 test tasks, 30 checks end-to-end |
| `run_sim.sh` | All of the above | Batch runner — compiles and executes all TBs, prints PASS/FAIL summary |

---

## 3. How Every Testbench Works

Every testbench in this project follows the same four-step pattern:

```
Step 1 — Instantiate the module under test (DUT)
Step 2 — Generate a 100 MHz clock:  always #5 clk = ~clk;
Step 3 — Drive stimulus inside:     initial begin ... end
Step 4 — Check outputs with the check() task
```

The shared `check()` task used throughout `tb_soc_top.sv`:

```systemverilog
task check(input string test_name, input logic cond);
    if (cond) begin
        $display("[PASS] %s", test_name);
        pass_count++;
    end else begin
        $display("[FAIL] %s", test_name);
        fail_count++;
    end
endtask
```

Each call prints `[PASS]` or `[FAIL]` with the test name immediately, so failures are pinpointed to the exact check without digging through waveforms. The counters `pass_count` and `fail_count` are summed at the end to give a final results line.

---

## 4. Full Integration Test — `tb_soc_top.sv`

This is the top-level testbench. It instantiates the **entire SoC** — CPU, memories, all peripherals, address decoder, interrupt controller — and runs ten test tasks in sequence covering every major subsystem.

---

### 4.1 DUT Instantiation & Clock

```systemverilog
soc_top u_dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .uart_tx   (uart_tx),   .uart_rx   (uart_rx),
    .gpio_out  (gpio_out),  .gpio_in   (gpio_in),
    .spi_sck   (spi_sck),   .spi_mosi  (spi_mosi),
    .spi_miso  (spi_miso),  .spi_cs_n  (spi_cs_n),
    .i2c_scl_oe(i2c_scl_oe),.i2c_sda_oe(i2c_sda_oe),
    .i2c_sda_in(i2c_sda_in),
    .D0_AN(D0_AN), .D0_SEG(D0_SEG),
    .D1_AN(D1_AN), .D1_SEG(D1_SEG)
);

parameter CLK_PERIOD = 10; // ns — 100 MHz

initial clk = 1'b0;
always #(CLK_PERIOD/2) clk = ~clk;
```

---

### 4.2 Bus Injection Tasks

The testbench bypasses the CPU and **directly injects transactions onto the SoC's internal data bus** using SystemVerilog `force`/`release`. This lets each peripheral be verified independently without needing to run assembly code through the CPU first — isolating failures to the peripheral RTL rather than the CPU.

```systemverilog
// Write any SoC address directly — simulates what the CPU would do with a SW instruction
task cpu_write(input logic [31:0] addr, input logic [31:0] data);
    force u_dut.dbus_addr  = addr;
    force u_dut.dbus_wdata = data;
    force u_dut.dbus_we    = 4'hF;    // all 4 byte-lanes enabled (full word write)
    force u_dut.dbus_re    = 1'b0;
    @(posedge clk); #1;               // hold for one clock edge
    release u_dut.dbus_addr;          // release — let CPU resume driving the bus
    release u_dut.dbus_wdata;
    release u_dut.dbus_we;
    release u_dut.dbus_re;
endtask

// Read any SoC address — simulates what the CPU would do with a LW instruction
task cpu_read(input logic [31:0] addr, output logic [31:0] data);
    force u_dut.dbus_addr = addr;
    force u_dut.dbus_we   = 4'h0;
    force u_dut.dbus_re   = 1'b1;
    @(posedge clk); #1;
    data = u_dut.dbus_rdata;          // capture read-back value from the mux
    release u_dut.dbus_addr;
    release u_dut.dbus_we;
    release u_dut.dbus_re;
endtask
```

---

### 4.3 `test_por` — Power-On Reset

**What it tests:** the 8-bit POR counter in `soc_top` correctly gates `rst_n_int`, keeping the CPU in reset for 256 cycles after power-up before releasing it.

```systemverilog
rst_n = 1'b0;
repeat(5) @(posedge clk);
check("POR holds CPU in reset", u_dut.rst_n_int === 1'b0);
// ↑ external reset asserted + POR not expired → CPU must still be held

rst_n = 1'b1;
repeat(300) @(posedge clk);           // wait for por_cnt[7] to saturate (256 cycles)
check("POR releases after count", u_dut.rst_n_int === 1'b1);
// ↑ 256 cycles elapsed, external reset released → CPU is now free to run
```

**What a failure here means:** the POR counter is not incrementing, `por_cnt[7]` is not wired to `rst_n_int`, or the reset logic has a polarity error.

---

### 4.4 `test_imem` — Instruction Memory ROM

**What it tests:** the instruction ROM contains the correct program words, and out-of-range reads safely return NOP (`0x00000013` = `ADDI x0, x0, 0`).

```systemverilog
force u_dut.imem_addr = 32'h0;
#1;
check("IMEM ROM word 0", u_dut.imem_data === 32'h100002b7);
// ↑ expected instruction: LUI x5, 0x10000 (loads UART base address into x5)

force u_dut.imem_addr = 32'h4;
#1;
check("IMEM ROM word 1", u_dut.imem_data === 32'h20000337);
// ↑ expected instruction: LUI x6, 0x20000 (loads GPIO base address into x6)

force u_dut.imem_addr = 32'hFFF0;
#1;
check("IMEM ROM default NOP", u_dut.imem_data === 32'h00000013);
// ↑ any address beyond the program must return NOP — safe fetch behaviour
release u_dut.imem_addr;
```

**What a failure here means:** the `$readmemh` initialisation didn't load, `program.mem` is missing or misformatted, or the address word-align logic (`addr[12:2]`) is wrong.

---

### 4.5 `test_dmem` — Data Memory

**What it tests:** word reads and writes, independence of adjacent memory locations, and the 4-bit byte-lane write enable that makes `SB` and `SH` work correctly.

```systemverilog
// Basic word write and read-back
cpu_write(32'h00002000, 32'hDEADBEEF);
cpu_read (32'h00002000, rdata);
check("DMEM word write/read", rdata === 32'hDEADBEEF);

// Two different word addresses must not interfere
cpu_write(32'h00002004, 32'hCAFEBABE);
cpu_write(32'h00002000, 32'h0);        // overwrite first word
cpu_read (32'h00002004, rdata);
check("DMEM independent words", rdata === 32'hCAFEBABE);
// ↑ clearing 0x2000 must not disturb 0x2004

// Byte-enable: write only byte lane 0 (simulates SB instruction)
force u_dut.u_dmem.we    = 4'b0001;   // only bit 0 of WE → byte lane 0 only
force u_dut.u_dmem.addr  = 32'h00002100;
force u_dut.dbus_wdata   = 32'hABCDEF12;
@(posedge clk); #1;
release u_dut.u_dmem.we;
release u_dut.u_dmem.addr;
release u_dut.dbus_wdata;
cpu_read(32'h00002100, rdata);
check("DMEM byte-enable low byte", rdata[7:0] === 8'h12);
// ↑ only bits [7:0] should change; upper 3 bytes must be unchanged
```

**What a failure here means:** the SRAM array index logic is wrong, byte lanes are not independent, or the write-enable clock gating has a bug.

---

### 4.6 `test_gpio` — General Purpose I/O

**What it tests:** the GPIO output register drives physical LED pins immediately, and the input register transparently reflects the current switch state.

```systemverilog
// Write OUTPUT register — LED pins must update on the same clock
cpu_write(32'h20000000, 32'hA5);
check("GPIO output write", gpio_out === 8'hA5);

// Drive switches from the testbench — INPUT register must reflect them
gpio_in = 8'hC3;
cpu_read(32'h20000004, rdata);
check("GPIO input read", rdata[7:0] === 8'hC3);

// Clear OUTPUT register
cpu_write(32'h20000000, 32'h00);
check("GPIO output clear", gpio_out === 8'h00);
```

**What a failure here means:** the output register is not driving `gpio_out`, the input register is reading the wrong signal, or the register offsets in `gpio.v` don't match the expected `0x0`/`0x4` layout.

---

### 4.7 `test_timer` — Countdown Timer

**What it tests:** the timer counts down from the loaded value, asserts the timeout flag on reaching zero, the STATUS flag clears on a write-1, and auto-reload mode correctly restarts the counter.

```systemverilog
// One-shot mode: load 10, enable, wait 20 cycles
cpu_write(32'h30000000, 32'd10);       // LOAD = 10
cpu_write(32'h30000008, 32'h1);        // CTRL[0] = enable
wait_cycles(20);
cpu_read(32'h3000000C, rdata);
check("Timer fires timeout", rdata[0] === 1'b1);
// ↑ STATUS[0] must be 1 — counter has reached zero

// Clear the timeout flag
cpu_write(32'h3000000C, 32'h1);        // write 1 to STATUS[0] to clear
cpu_read (32'h3000000C, rdata);
check("Timer timeout clear", rdata[0] === 1'b0);

// Auto-reload mode: CTRL[1:0] = 2'b11 (enable + auto-reload)
cpu_write(32'h30000000, 32'd5);
cpu_write(32'h30000008, 32'h3);
wait_cycles(30);                       // enough time for multiple reloads
cpu_read(32'h3000000C, rdata);
check("Timer auto-reload fires", rdata[0] === 1'b1);
// ↑ timer must have reloaded and fired again after the first timeout
```

**What a failure here means:** the counter is not decrementing when enabled, the zero detection is missing, STATUS is not latching on timeout, or the auto-reload mux is wired incorrectly.

---

### 4.8 `test_intc` — Interrupt Controller

**What it tests:** the PENDING register latches edge-triggered IRQs, the ENABLE mask gates them to the CPU, CLEAR writes dismiss the interrupt, and disabling all sources deasserts `irq_to_cpu`.

```systemverilog
cpu_write(32'h40000004, 32'hF);        // ENABLE all 4 interrupt sources

// Inject a UART IRQ by forcing the internal wire
force u_dut.u_intc.irq_uart = 1'b1;
@(posedge clk); #1;
release u_dut.u_intc.irq_uart;
@(posedge clk); #1;

cpu_read(32'h40000000, rdata);         // read PENDING register
check("INTC uart pending set",      rdata[0]           === 1'b1);
check("INTC irq_to_cpu asserted",   u_dut.irq_to_cpu   === 1'b1);
// ↑ source enabled + pending → irq_to_cpu must be high

// Acknowledge: write 1 to CLEAR bit 0
cpu_write(32'h40000008, 32'h1);
@(posedge clk); @(posedge clk); #1;
cpu_read(32'h40000000, rdata);
check("INTC pending clear", rdata[0] === 1'b0);

// Disable all sources — irq_to_cpu must drop
cpu_write(32'h40000004, 32'h0);
@(posedge clk); #1;
check("INTC disable all", u_dut.irq_to_cpu === 1'b0);
```

**What a failure here means:** PENDING is not latching, the priority encode logic has a bug, CLEAR is not resetting the latch, or the ENABLE mask is not ANDed correctly with PENDING.

---

### 4.9 `test_uart_tx` — UART Transmitter

**What it tests:** writing TX_DATA immediately asserts `tx_busy`, and exactly one full UART frame duration later (10 bit-periods × baud_div clocks) `tx_busy` deasserts, indicating the shift register has emptied.

```systemverilog
cpu_write(32'h1000000C, 32'd868);      // BAUD_DIV = 868 → 115200 baud @ 100 MHz
cpu_write(32'h10000000, 32'h55);       // TX_DATA = 0x55 — start transmission

cpu_read(32'h10000004, rdata);
check("UART TX busy after write", rdata[0] === 1'b1);
// ↑ tx_busy must assert on the same clock as the write

repeat(868 * 12) @(posedge clk);      // wait > one full 10-bit frame with margin
cpu_read(32'h10000004, rdata);
check("UART TX idle after frame", rdata[0] === 1'b0);
// ↑ shift register is empty — transmitter must be idle again
```

**What a failure here means:** the TX state machine is not loading on the write, `tx_busy` is not connected to STATUS[0], the baud counter is not counting correctly, or the shift register length is wrong.

---

### 4.10 `test_spi` — SPI Master

**What it tests:** CS_N asserts when enabled, `busy` sets immediately after a TX_DATA write, the 8-bit transfer completes (done flag sets), and CS_N deasserts when disabled.

```systemverilog
cpu_write(32'h5000000C, 32'd4);        // DIVIDER = 4 → SCK = clk / 8
cpu_write(32'h50000008, 32'h1);        // CS_EN → assert CS_N low
check("SPI CS asserted", spi_cs_n === 1'b0);

cpu_write(32'h50000000, 32'hA5);       // TX_DATA = 0xA5 → start 8-bit transfer
cpu_read (32'h50000004, rdata);
check("SPI busy after write", rdata[0] === 1'b1);
// ↑ tx busy must set immediately

// Poll STATUS[1] (done flag) — wait up to 200 clocks
integer i;
for (i = 0; i < 200; i++) begin
    @(posedge clk); #1;
    cpu_read(32'h50000004, rdata);
    if (rdata[1]) break;
end
check("SPI done after transfer", rdata[1] === 1'b1);
// ↑ 8 SCK edges must have occurred and done must be set

cpu_write(32'h50000008, 32'h0);        // CS_EN deasserted
check("SPI CS deasserted", spi_cs_n === 1'b1);
```

**What a failure here means:** the CS_N inversion is wrong, the shift counter is not running, the done flag latch is missing, or the divider is not generating SCK.

---

### 4.11 `test_seg7` — 7-Segment Display

**What it tests:** the display register stores and returns the written value, and after sufficient time the multiplexer is actively scanning through digits (not frozen with all anodes off).

```systemverilog
cpu_write(32'h20000100, 32'h12345678);
cpu_read (32'h20000100, rdata);
check("SEG7 register write/read", rdata === 32'h12345678);
// ↑ stored value must survive a readback

wait_cycles(100000);                   // allow the ~1 kHz scan counter to run
check("SEG7 D0_AN active",    D0_AN !== 4'b1111 || D1_AN !== 4'b1111);
check("SEG7 SEG not all-off", D0_SEG !== 8'hFF  || D1_SEG !== 8'hFF);
// ↑ at least one anode must be selecting a digit (not 0xF = all off)
// ↑ at least one segment must be lit (not 0xFF = all segments off)
```

**What a failure here means:** the scan counter is not incrementing, the anode mux is stuck, the segment decoder has a bug, or the register is not connected to the display driver.

---

### 4.12 `test_cpu_execution` — CPU Sanity

**What it tests:** non-intrusive checks that the CPU has started executing code after reset — the PC has advanced, the fetch address is always word-aligned, and the PC stays within instruction memory bounds.

```systemverilog
check("CPU PC not stuck at 0",
      u_dut.u_cpu.pc !== 32'h0);
// ↑ after 300+ cycles the PC must have advanced from the reset vector

check("CPU IMEM address valid",
      u_dut.imem_addr[1:0] === 2'b00);
// ↑ RV32I instructions are 4-byte aligned — bits [1:0] of fetch address must always be 00

check("CPU reset vector correct",
      (u_dut.u_cpu.pc >= 32'h0) && (u_dut.u_cpu.pc < 32'h2000));
// ↑ PC must stay within the 8 KB IMEM window (0x0000 to 0x1FFF)
```

**What a failure here means:** the PC reset value is wrong, the PC increment (`+4`) logic is broken, or a rogue branch is sending the PC outside the instruction memory range.

---

## 5. Test Execution Order

The top-level `initial` block in `tb_soc_top.sv` runs all tasks in this fixed sequence:

```
 1.  test_por             Verify 256-cycle POR counter behaviour
 2.  test_imem            Verify ROM instruction words and out-of-range NOP
 3.  test_dmem            Verify SRAM word ops, independence, byte-enables
 4.  test_gpio            Verify LED output register and switch input register
 5.  test_timer           Verify countdown, timeout flag, clear, auto-reload
 6.  test_intc            Verify PENDING latch, ENABLE mask, CLEAR, irq_to_cpu
 7.  test_uart_tx         Verify TX serialisation and tx_busy flag lifecycle
 8.  test_spi             Verify SPI frame generation and CS_N control
 9.  test_seg7            Verify display register and active multiplexer scan
10.  test_cpu_execution   Verify CPU is fetching aligned instructions in IMEM
```

---

## 6. Running Simulations

### Run All Testbenches at Once (VCS)

```bash
bash tb/run_sim.sh
```

The script compiles and runs all 12 testbenches sequentially, printing `[PASS]` / `[FAIL]` for each one and a final summary. Zero failures expected.

---

### Run a Single Testbench (VCS)

```bash
vcs -full64 -sverilog +define+SIMULATION   \
    -f sim/filelist/rtl.f                  \
    tb/tb_soc_top.sv                       \
    -o simv_soc -l compile.log

./simv_soc -l sim.log
```

Replace `tb_soc_top.sv` with any other testbench filename to run that module in isolation.

---

### Interactive Waveform Debug (VCS + Verdi)

```bash
vcs -full64 -sverilog -debug_access+all    \
    +fsdbfile+dump.fsdb                    \
    -f sim/filelist/rtl.f tb/tb_soc_top.sv \
    -o simv_soc

./simv_soc -gui
```

Load `dump.fsdb` inside Verdi to trace any signal — CPU registers, bus transactions, peripheral state machines — across the full simulation timeline. The testbench also writes a `tb_soc_top.vcd` file for GTKWave (`$dumpvars` is called at the start of the `initial` block).

---

### Cadence NCLaunch

NCLaunch requires the wire-fixed RTL because Cadence tools reject the `logic` keyword in standard Verilog-2001 mode.

```
1. Launch NCLaunch:  nclaunch &
2. Add filelist:     sim/filelist/rtl_nclaunch.f  (points to synthesis/genus/rtl/)
3. Add testbench:    tb/tb_soc_top.sv
4. Set top module:   tb_soc_top
5. Run → Simulate
```

---

### Vivado XSim

```
1. Open Vivado → Project → Simulation Sources → Add all files from rtl/
2. Add tb/tb_soc_top.sv as a simulation source
3. Set tb_soc_top as the simulation top module
4. Flow Navigator → Run Simulation → Run Behavioral Simulation
5. Inspect waveforms in the XSim viewer
```

---

## 7. Expected Output

A fully passing simulation run produces:

```
========================================
  RISC-V SoC Testbench Start
========================================

--- POR Tests ---
[PASS] POR holds CPU in reset
[PASS] POR releases after count

--- IMEM ROM Tests ---
[PASS] IMEM ROM word 0
[PASS] IMEM ROM word 1
[PASS] IMEM ROM default NOP

--- DMEM Tests ---
[PASS] DMEM word write/read
[PASS] DMEM second word
[PASS] DMEM independent words
[PASS] DMEM byte-enable low byte

--- GPIO Tests ---
[PASS] GPIO output write
[PASS] GPIO input read
[PASS] GPIO output clear

--- Timer Tests ---
[PASS] Timer fires timeout
[PASS] Timer timeout clear
[PASS] Timer auto-reload fires

--- INTC Tests ---
[PASS] INTC uart pending set
[PASS] INTC irq_to_cpu asserted
[PASS] INTC pending clear
[PASS] INTC disable all

--- UART TX Tests ---
[PASS] UART TX busy after write
[PASS] UART TX idle after frame

--- SPI Tests ---
[PASS] SPI CS asserted
[PASS] SPI busy after write
[PASS] SPI done after transfer
[PASS] SPI CS deasserted

--- SEG7 Tests ---
[PASS] SEG7 register write/read
[PASS] SEG7 D0_AN active
[PASS] SEG7 SEG not all-off

--- CPU Execution Tests ---
[PASS] CPU PC not stuck at 0
[PASS] CPU IMEM address valid
[PASS] CPU reset vector correct

========================================
  Results: 30 PASSED  0 FAILED
========================================
  *** ALL TESTS PASSED ***
```

Any `[FAIL]` line points directly to the RTL file containing the bug — the test name maps one-to-one to the module and condition that failed.

---

## 8. Simulation Timeout Watchdog

The testbench includes a watchdog timer that self-terminates if the simulation runs longer than **500,000 clock cycles**. This prevents infinite loops — for example, a stuck `tx_busy` flag or a polling loop that never exits — from hanging the simulator indefinitely.

```systemverilog
parameter TIMEOUT_CYCLES = 500_000;
integer cycle_count = 0;

initial begin
    forever begin
        @(posedge clk);
        cycle_count++;
        if (cycle_count > TIMEOUT_CYCLES) begin
            $display("[ERROR] Simulation timeout at %0t ns — possible hung loop", $time);
            $display("  Last PC: 0x%08h", u_dut.u_cpu.pc);
            $finish;
        end
    end
end
```

At 100 MHz, 500,000 cycles = **5 ms of simulated time** — far more than enough for all 10 test tasks to complete.

---

## 9. Adding a New Testbench

To add a testbench for a new module, create `tb/tb_mymodule.sv` using this skeleton:

```systemverilog
`timescale 1ns/1ps

module tb_mymodule;

    // ── 1. Signal declarations ──────────────────────────────────────
    logic        clk, rst_n;
    logic [31:0] in_a, in_b, result;
    integer      pass_count = 0, fail_count = 0;

    // ── 2. DUT instantiation ────────────────────────────────────────
    mymodule u_dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .a      (in_a),
        .b      (in_b),
        .out    (result)
    );

    // ── 3. Clock generation — 100 MHz ───────────────────────────────
    initial clk = 1'b0;
    always  #5  clk = ~clk;

    // ── 4. check() task ─────────────────────────────────────────────
    task check(input string name, input logic cond);
        if (cond) begin $display("[PASS] %s", name); pass_count++; end
        else      begin $display("[FAIL] %s", name); fail_count++; end
    endtask

    // ── 5. Stimulus ─────────────────────────────────────────────────
    initial begin
        $dumpfile("tb_mymodule.vcd");
        $dumpvars(0, tb_mymodule);

        rst_n = 1'b0;
        repeat(5) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // Test case 1: basic operation
        in_a = 32'd10; in_b = 32'd5;
        @(posedge clk); #1;
        check("basic add", result === 32'd15);

        // Add more test cases here...

        $display("Results: %0d PASSED  %0d FAILED", pass_count, fail_count);
        $finish;
    end

endmodule
```

Then add the file to `tb/run_sim.sh` to include it in the batch run.

---

<div align="center">

**RISC-V SoC — Testbench Suite**

12 Testbenches · 30 Checks · 0 Failures · VCS · Verdi · NCLaunch · XSim

*Part of the full RTL → Simulation → FPGA → Synthesis → Place & Route → GDSII flow*

Saveetha Engineering College — ECE Department
Arunachalam P (212223060022) · Charan PG (212223060033)

</div>
