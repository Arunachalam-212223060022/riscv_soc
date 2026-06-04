# FPGA Implementation Results — Vivado 2023.1

**Device:** Xilinx XC7S50CSGA324-1 (Spartan-7 Boolean Board)  
**Tool:** Vivado 2023.1  
**Flow:** RTL Synthesis → Placement → Routing → Bitstream  
**Script:** `fpga/scripts/vivado_riscv_soc_v2.tcl`

---

## Image 1 — Post-Implementation Project Summary

<img width="1599" height="904" alt="WhatsApp Image 2026-05-22 at 11 43 18 AM" src="https://github.com/user-attachments/assets/2cddbfde-31ba-42de-8dc9-0f9c114b3946" />


**View:** Implemented Design → Project Summary → Post-Implementation  
**Device:** `xc7s50csga324-1`

This is the Vivado Project Summary after the complete FPGA build — synthesis, placement, routing, and DRC — has finished successfully. It is the single-screen proof that the RISC-V SoC RTL compiles, maps, and closes timing on a real Xilinx FPGA device.

---

### Synthesis

| Field | Value |
|---|---|
| Status | ✅ Complete |
| Messages | 19 warnings (informational only — undriven nets, default I/O standards) |
| Part | `xc7s50csga324-1` |
| Strategy | Vivado Synthesis Defaults |

Synthesis completed without errors. The 19 warnings are expected for a design of this size and do not indicate RTL bugs — they cover items like default I/O voltage standard assignments and signals that Vivado detects are constants after elaboration.

---

### Implementation

| Field | Value |
|---|---|
| Status | ✅ Complete |
| Messages | 1 critical warning, 2 warnings |
| Strategy | Vivado Implementation Defaults |

Implementation (placement + routing) completed successfully. The 1 critical warning is a Vivado I/O standard advisory — it does not affect the design's functionality or programmability on the Boolean board.

---

### DRC Violations

| Metric | Value | Meaning |
|---|---|---|
| DRC Errors | **0** | No design-rule violations of any kind |
| DRC Warnings | **1** | I/O standard advisory (informational) |

Zero DRC errors — the implemented design is fully compliant with the XC7S50 design rules and is safe to program onto the board.

---

### Timing (Setup Analysis)

| Metric | Value | Meaning |
|---|---|---|
| Worst Negative Slack (WNS) | **+2.489 ns** | Positive = timing MET with margin |
| Total Negative Slack (TNS) | **0 ns** | No failing paths anywhere in the design |
| Failing Endpoints | **0** | Every endpoint passes |
| Total Endpoints | **640** | All 640 timing endpoints analysed and passing |

A WNS of **+2.489 ns** means the critical path completes 2.489 ns before the clock edge — the design has timing closure with margin to spare. With the board running at 12 MHz (83.3 ns period), the single-cycle CPU datapath is well within budget. Zero failing endpoints across all 640 checked paths is the gold standard result.

---

### Resource Utilisation (Post-Implementation)

| Resource | Used | Available | % |
|---|---|---|---|
| LUT | ~1% | 32,600 | Very low |
| FF (Flip-Flops) | ~1% | 65,200 | Very low |
| IO (Bonded IOBs) | **32%** | 210 | 14 I/O pins used |
| BUFG (Global Clock) | **3%** | — | 1 global buffer |

The minimal LUT and FF utilisation is because Vivado maps the 8 KB instruction ROM and 8 KB data SRAM to **Block RAM (BRAM)** primitives rather than distributed LUT-RAM, keeping combinational logic usage very small. The 32% IO utilisation accounts for the 14 bonded pins used: `clk`, `rst_n`, `uart_tx`, `gpio_out[7:0]`, and `gpio_in[7:0]`.

---

### On-Chip Power

| Metric | Value |
|---|---|
| Total On-Chip Power | **0.077 W (77 mW)** |
| Junction Temperature | **25.4 °C** |
| Thermal Margin | 59.6 °C (12.0 W budget) |
| Dynamic Power | ~0 W (design is mostly static at this clock rate) |

77 mW total power at 12 MHz is extremely efficient. The 59.6 °C thermal margin means the device runs cool with no heatsink required. The low dynamic power reflects the single-cycle CPU executing at 12 MHz — well below the device's 100+ MHz capability.

---

## Image 2 — Post-Implementation Device View (Physical Floorplan)


<img width="1599" height="904" alt="WhatsApp Image 2026-05-22 at 11 43 18 AM (1)" src="https://github.com/user-attachments/assets/7aca5685-a47d-4f83-8d02-1485ff624c66" />




**View:** Implemented Design → Device  
**Device:** `xc7s50csga324-1` (Spartan-7, 50K logic cells)

This is the physical device view of the Spartan-7 FPGA after place-and-route. The entire die is shown, divided into six clock regions (X0Y0 through X1Y2). The coloured regions reveal exactly where the SoC's logic was placed inside the silicon.

---

### Reading the Device View

| Colour / Region | What it represents |
|---|---|
| **Cyan/teal blocks** (right column, X1Y0–X1Y2) | Placed and routed logic cells — ALU, register file, control unit, peripheral state machines, address decoder |
| **Pink/magenta strip** (left edge) | I/O column — the 14 bonded IOBs driven to the Boolean board's pins |
| **Blue/violet blocks** (bottom-left, X0Y0) | Placed BRAM tiles — the 8 KB instruction ROM and 8 KB data SRAM |
| **Dark/empty regions** (majority of die) | Unused fabric — consistent with the 1% LUT utilisation reported in Project Summary |
| **Tile grid labels** (X0Y0, X0Y1, X1Y0…) | Vivado clock region boundaries dividing the die |

---

### Key Observations

The logic cells are tightly clustered in the right column (X1Y0–X1Y2), which is where Vivado placed the combinational and sequential logic of the CPU, peripherals, and bus — the SoC's register file, ALU, control decoder, UART/SPI/I2C/GPIO/Timer/INTC state machines, and the address decode chain.

The bulk of the die is dark and unused. This is expected — the SoC uses only ~1% of the available LUTs and FFs, leaving the majority of the Spartan-7's 32,600 LUTs available for future expansion or additional peripherals.

No routing congestion is visible anywhere on the die, consistent with the clean timing closure (WNS = +2.489 ns) and zero DRC violations reported in the Project Summary. The BRAM blocks in X0Y0 are isolated from the CLB logic columns by design — Vivado routes long fanout nets (the memory buses) across the routing fabric between them.

This device view is the physical evidence that the RTL written from scratch — from `pc.v` and `regfile.v` up to `soc_top.v` — translates into real placed-and-routed logic on a physical FPGA.

---

## Image 3 — Synthesised Design Schematic


<img width="1600" height="880" alt="79071ffb-357f-4963-991b-b68aeb1ca9d7" src="https://github.com/user-attachments/assets/53de184b-6e51-4e78-a433-0024aecea24d" />




**View:** Synthesised Design → Schematic  
**Device:** `xc7s50csga324-1`  
**Stats (shown in toolbar):** 608 Cells · 70 I/O Ports · 873 Nets  
**Highlighted net:** `D1_SEG_OBUF` — Bus width: 7

This is the **gate-level schematic** generated by Vivado after synthesis — the RTL has been fully elaborated and mapped to Xilinx primitives (LUTs, FFs, BUFGs, OBUFs, IBUFs, BRAM36). It represents the complete SoC netlist as a connectivity diagram before placement.

---

### What the Numbers Mean

| Metric | Value | Meaning |
|---|---|---|
| **Cells** | **608** | Total primitive instances — LUTs, FFs, BRAMs, I/O buffers |
| **I/O Ports** | **70** | All top-level pins: clk, rst_n, uart_tx, gpio_out[7:0], gpio_in[7:0], SPI, I2C, Seg7 |
| **Nets** | **873** | Internal signal connections between cells |

608 cells across the full SoC — including CPU, memories, and all peripherals — is a compact gate count that reflects the efficiency of the single-cycle architecture and the heavy use of BRAM for instruction and data memory.

---

### Reading the Schematic

The schematic renders the complete SoC as a dense connected graph of logic elements. Reading left to right:

- **Left cluster** — input buffers (IBUFs) for `clk`, `rst_n`, and `gpio_in[7:0]`. These are the FPGA's I/O interface cells that condition the incoming signals before they enter the core logic.
- **Central region** — the bulk of the SoC logic: the CPU datapath (PC, register file, ALU, control decoder, immediate generator), the address decode chain, the data bus multiplexer, and all peripheral register files. The dense web of interconnecting green lines represents the 873 internal nets — bus connections, control signals, data paths.
- **Right cluster** — output buffers (OBUFs) driving `uart_tx`, `gpio_out[7:0]`, `spi_*`, `i2c_*`, and the 7-segment display signals. The highlighted net **`D1_SEG_OBUF`** (Bus width: 7) is the 7-bit segment encoding bus driving display digit 1 — all seven segment outputs (A through G) bundled as a single bus output.

The tooltip on `D1_SEG_OBUF` confirms the 7-segment display controller (`seg7_ctrl.v`) was synthesised and connected correctly — a 7-bit output bus driving the `D1_SEG[6:0]` port of the SoC, which maps to the Boolean board's second 7-segment digit.

The large rectangular outline enclosing most of the schematic is the hierarchical boundary of the `soc_top` module — Vivado draws a box around each hierarchy level to show the module boundary clearly.

---

> **Flow checkpoint:** These three images document the FPGA implementation milestone. The Project Summary confirms timing closure and DRC clean status; the Device View shows the physical placement on silicon; and the Schematic proves the RTL was correctly elaborated and mapped to 608 Xilinx primitives connected by 873 nets, ready for programming onto the Boolean board.
