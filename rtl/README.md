# RTL Source Code

This folder contains all the Verilog files that describe the hardware — the actual logic of the RISC-V SoC. Every file here defines a real hardware module that gets synthesized into gates (and eventually transistors).

> **Two versions exist:**  
> - `rtl/` (this folder) — uses SystemVerilog `logic` keyword. Works with Vivado and VCS/Verdi.  
> - `synthesis/genus/rtl/` — identical logic, but `logic` is replaced with `wire`. Required for Cadence Genus and NCLaunch.

---

## Files Overview

```
rtl/
├── soc_top.v          ← The whole SoC in one file: CPU + memories + all peripherals wired together
├── soc_top_demo.v     ← Same SoC but with the 7-segment display and switches wired for the FPGA demo
├── cpu/
│   ├── cpu_top.v      ← CPU: connects all 6 sub-modules together
│   ├── pc.v           ← Program Counter (tracks which instruction to run next)
│   ├── regfile.v      ← Register File (32 general-purpose 32-bit registers)
│   ├── immgen.v       ← Immediate Generator (extracts constants from instructions)
│   ├── control.v      ← Control Unit (decodes instructions into control signals)
│   ├── alu_ctrl.v     ← ALU Control (tells the ALU which operation to do)
│   └── alu.v          ← Arithmetic Logic Unit (does the actual math and logic)
├── memory/
│   ├── imem.v         ← Instruction Memory (stores the program, read-only)
│   └── dmem.v         ← Data Memory (stores variables, read-write)
└── peripheral/
    ├── uart.v         ← Serial communication (UART TX/RX)
    ├── gpio.v         ← General Purpose I/O (LEDs and switches)
    ├── timer.v        ← Countdown timer with interrupt
    ├── intc.v         ← Interrupt Controller (manages which events CPU handles)
    ├── spi.v          ← SPI serial protocol master
    ├── i2c.v          ← I2C serial protocol master
    └── seg7_ctrl.v    ← 7-segment display driver
```

---

## `soc_top.v` — The Top-Level SoC

This is the "glue" file. It doesn't contain much logic itself — it instantiates (creates) every other module and wires them all together.

### Power-On Reset

The SoC has a built-in power-on reset that holds everything in reset for 256 clock cycles after power-up. This ensures all registers start in a known state before the CPU begins fetching instructions.

```verilog
reg [7:0] por_cnt = 8'h0;
wire rst_n_int = por_cnt[7] & rst_n;   // CPU only runs when POR is done AND external reset is released
always @(posedge clk)
    if (!por_cnt[7]) por_cnt <= por_cnt + 1;
```

### Address Map

Every peripheral appears at a specific address. The CPU reads/writes to these addresses just like it reads/writes to memory — this is called **memory-mapped I/O**.

| Address | Module | Size | Description |
|---------|--------|------|-------------|
| `0x00000000` | IMEM | 8 KB | Instruction memory (CPU fetches from here) |
| `0x00002000` | DMEM | 8 KB | Data memory (variables, stack) |
| `0x10000000` | UART | 16 B | Serial port registers |
| `0x20000000` | GPIO | 16 B | LED and switch registers |
| `0x20000100` | Seg7 | 4 B | 7-segment display register |
| `0x30000000` | Timer | 16 B | Timer countdown registers |
| `0x40000000` | INTC | 16 B | Interrupt controller registers |
| `0x50000000` | SPI | 16 B | SPI master registers |
| `0x60000000` | I2C | 16 B | I2C master registers |

### How the Address Decoder Works

When the CPU accesses an address, a small combinational circuit checks which range it falls in and activates only that peripheral:

```verilog
wire dmem_sel  = (dbus_addr[31:14] == 18'h0) && (dbus_addr[13] == 1'b1);
wire uart_sel  = (dbus_addr[31:4]  == 28'h1000000);
wire gpio_sel  = (dbus_addr[31:4]  == 28'h2000000);
// ...and so on for each peripheral
```

The CPU reads data back through a mux — only one peripheral drives the bus at a time:

```verilog
assign dbus_rdata = dmem_sel  ? dmem_rdata  :
                    uart_sel  ? uart_rdata  :
                    gpio_sel  ? gpio_rdata  :
                    timer_sel ? timer_rdata :
                    intc_sel  ? intc_rdata  :
                                32'h0;       // returns 0 if nothing is selected
```

---

## CPU Core

### `cpu_top.v` — CPU Integration

This file wires all six CPU sub-modules together. The CPU itself contains no logic — it's a structural wrapper that connects the pieces.

**What it connects:**
- PC → IMEM (fetch address)
- IMEM → Decoder (instruction bits)
- Decoder → Control Unit (opcode)
- Control Unit → RegFile, ALU, Memory (control signals)
- RegFile → ALU (source operands)
- ALU result → DMEM address and write data
- DMEM read data → RegFile write-back

**PC update logic** — picks the next instruction address:
```verilog
assign pc_next = jalr         ? (rs1_data + imm) & ~32'h1  :  // JALR (force bit 0 to 0)
                 jal          ? pc + imm                    :  // JAL (jump and link)
                 branch_taken ? pc + imm                    :  // branch instruction taken
                                pc + 32'd4;                    // normal: next instruction
```

**Branch conditions** — all six RISC-V branch types:
```
BEQ  (funct3=000): branch if rs1 == rs2
BNE  (funct3=001): branch if rs1 != rs2
BLT  (funct3=100): branch if rs1 <  rs2 (signed)
BGE  (funct3=101): branch if rs1 >= rs2 (signed)
BLTU (funct3=110): branch if rs1 <  rs2 (unsigned)
BGEU (funct3=111): branch if rs1 >= rs2 (unsigned)
```

**Store byte enables** — lets the CPU write 1, 2, or 4 bytes at a time:
```
SB (funct3=000): writes 1 byte  → dbus_we = 0001, shifted to correct byte lane
SH (funct3=001): writes 2 bytes → dbus_we = 0011, shifted to correct byte lane
SW (funct3=010): writes 4 bytes → dbus_we = 1111 (all bytes)
```

---

### `pc.v` — Program Counter

The Program Counter holds the address of the current instruction. It's just a 32-bit register that resets to 0 and updates every clock cycle.

```verilog
always @(posedge clk or negedge rst_n)
    if (!rst_n) pc_out <= 32'h0000_0000;   // reset: start at address 0
    else        pc_out <= pc_next;           // normal: next address from cpu_top
```

The `pc_next` value comes from `cpu_top` — it's either PC+4 (next instruction), a branch target, or a jump target.

---

### `regfile.v` — Register File

The CPU has **32 registers**, each 32 bits wide (named x0 through x31). These are the CPU's working memory — variables in hardware.

Key rules:
- **x0 is always zero.** Any read returns 0. Writes are silently ignored. This is hardwired in the design.
- **Reads are instant** (combinational — no clock needed).
- **Writes happen on the rising clock edge** (synchronous).

```verilog
// Read: immediate, any time
assign rs1_data = (rs1 == 5'b0) ? 32'h0 : regs[rs1];
assign rs2_data = (rs2 == 5'b0) ? 32'h0 : regs[rs2];

// Write: only on clock edge, only if write-enable is on, only if not x0
always @(posedge clk)
    if (we && rd != 5'b0) regs[rd] <= wdata;
```

Two registers can be read at the same time (rs1 and rs2) — needed for instructions like `ADD rd, rs1, rs2`.

---

### `immgen.v` — Immediate Generator

Many instructions include a constant value embedded in the instruction bits. This module extracts that constant and sign-extends it to 32 bits.

RISC-V has five different ways instructions encode constants (called "formats"). The immediate generator handles all five:

| Format | Used by | How bits are arranged |
|--------|---------|----------------------|
| I-type | ADDI, LW, JALR | `instr[31:20]`, sign-extended |
| S-type | SW, SH, SB | `instr[31:25]` and `instr[11:7]` joined together |
| B-type | BEQ, BNE, BLT... | Bits scattered: `[31,7,30:25,11:8]` + LSB forced 0 |
| U-type | LUI, AUIPC | `instr[31:12]` shifted left by 12 |
| J-type | JAL | Bits scattered: `[31,19:12,20,30:21]` + LSB forced 0 |

B-type and J-type have their lowest bit forced to 0 because branches and jumps always go to even addresses (2-byte aligned).

---

### `control.v` — Control Unit

The control unit is the "brain" that tells every other module what to do for each instruction. It reads the 7-bit opcode and produces 11 control signals.

It's purely combinational — no registers, no clock, just combinational logic:

```verilog
case (opcode)
    7'b0110011: begin reg_write=1; alu_op=2'b10; end          // R-type (ADD, SUB, AND...)
    7'b0010011: begin reg_write=1; alu_src=1; alu_op=2'b10; end // I-ALU (ADDI, ANDI...)
    7'b0000011: begin reg_write=1; alu_src=1; mem_read=1; mem_to_reg=1; end // Load (LW, LB...)
    7'b0100011: begin alu_src=1; mem_write=1; end              // Store (SW, SH, SB)
    7'b1100011: begin branch=1; alu_op=2'b01; end              // Branch (BEQ, BNE...)
    7'b1101111: begin reg_write=1; jal=1; end                  // JAL
    7'b1100111: begin reg_write=1; jalr=1; alu_src=1; end      // JALR
    7'b0110111: begin reg_write=1; lui=1; end                  // LUI
    7'b0010111: begin reg_write=1; auipc=1; end                // AUIPC
endcase
```

**What each signal does:**

| Signal | Effect when 1 |
|--------|--------------|
| `reg_write` | Write result back to the register file |
| `alu_src` | ALU uses the immediate value (not register rs2) |
| `mem_read` | Read from data memory (load instruction) |
| `mem_write` | Write to data memory (store instruction) |
| `mem_to_reg` | Write-back comes from memory (load result) |
| `branch` | This is a branch instruction — check the condition |
| `jal` | Unconditional jump, PC-relative |
| `jalr` | Unconditional jump, register-based |
| `lui` | Load upper immediate directly into register |
| `auipc` | Load PC + upper immediate into register |
| `alu_op[1:0]` | Tells ALU control what kind of operation to expect |

---

### `alu_ctrl.v` — ALU Control

Translates the `alu_op` signal (from the control unit) plus `funct3` and `funct7` bits (from the instruction) into a 4-bit `alu_sel` that tells the ALU exactly which operation to perform.

```
alu_op = 00  →  always ADD           (used by load/store: address = base + offset)
alu_op = 01  →  always SUB           (used by branches: compare = subtract and check zero)
alu_op = 10  →  decode funct3/funct7 (used by R-type and I-ALU instructions)
```

For `alu_op = 10`, the funct3 and funct7 fields in the instruction decide the operation:
- `funct3=000, funct7=0`: ADD
- `funct3=000, funct7=1`: SUB (the only difference is bit 5 of funct7)
- `funct3=101, funct7=0`: SRL (shift right, fill with zeros)
- `funct3=101, funct7=1`: SRA (shift right, fill with sign bit)

---

### `alu.v` — Arithmetic Logic Unit

The ALU performs 10 operations based on the 4-bit `alu_sel` from `alu_ctrl`:

| `alu_sel` | Operation | Description |
|-----------|-----------|-------------|
| `0000` | ADD | a + b |
| `0001` | SUB | a - b |
| `0010` | AND | a & b (bitwise) |
| `0011` | OR | a \| b (bitwise) |
| `0100` | XOR | a ^ b (bitwise) |
| `0101` | SLL | a << b[4:0] (shift left, fill 0) |
| `0110` | SRL | a >> b[4:0] (shift right, fill 0) |
| `0111` | SRA | a >>> b[4:0] (shift right, fill sign bit) |
| `1000` | SLT | 1 if a < b (signed), else 0 |
| `1001` | SLTU | 1 if a < b (unsigned), else 0 |

The ALU also produces a `zero` flag — set to 1 when the result is 0. The branch unit in `cpu_top` uses this flag to detect `BEQ` (branch if equal = subtract and check if zero).

---

## Memory Subsystem

### `imem.v` — Instruction Memory

An 8 KB read-only memory that stores the program. The CPU fetches one 32-bit instruction per cycle.

```verilog
reg [31:0] mem [0:2047];            // 2048 words × 32 bits = 8 KB
initial $readmemh("program.mem", mem);  // preloaded from hex file at startup

assign data = mem[addr[12:2]];      // word-indexed: byte address ÷ 4
```

- **Read is instant** — no clock, combinational output (zero wait states)
- The `program.mem` file is built from the assembly source in `sw/`
- Address bits [1:0] are ignored because all instructions are 4-byte aligned

### `dmem.v` — Data Memory

An 8 KB read-write memory for variables, the stack, and heap.

```verilog
// Writes happen on clock edge, byte-lane controlled
always @(posedge clk) begin
    if (we[0]) mem[idx][7:0]   <= wdata[7:0];   // byte 0
    if (we[1]) mem[idx][15:8]  <= wdata[15:8];  // byte 1
    if (we[2]) mem[idx][23:16] <= wdata[23:16]; // byte 2
    if (we[3]) mem[idx][31:24] <= wdata[31:24]; // byte 3
end

// Reads are instant (combinational)
always @(*) rdata = re ? mem[idx] : 32'h0;
```

The **4-bit byte-lane write enable** (`we[3:0]`) lets the CPU write just 1 byte (`SB`), 2 bytes (`SH`), or all 4 bytes (`SW`) without disturbing the other bytes in the same word.

---

## Peripheral Modules

All peripherals use the same simple interface:
- `addr[3:0]` — which register inside the peripheral (0, 4, 8, or 12)
- `wdata[31:0]` — data to write
- `rdata[31:0]` — data to read (always driven, combinational)
- `we` — write enable (set by soc_top when this peripheral is selected and CPU is writing)

---

### `uart.v` — Serial Communication

UART (Universal Asynchronous Receiver/Transmitter) is how the SoC talks to a PC over a serial/USB connection.

**Registers:**

| Offset | Name | Read/Write | What it does |
|--------|------|------------|-------------|
| `0x0` | TX_DATA | Write | Send this byte over the serial line |
| `0x4` | STATUS | Read | Bit 0 = `tx_busy` (1 = currently sending, don't write yet) |
| `0x8` | RX_DATA | Read | Bit [7:0] = received byte, Bit [8] = 1 when a new byte arrived |
| `0xC` | BAUD_DIV | Read/Write | Sets the baud rate. Default 868 → 115200 baud at 100 MHz |

**Baud rate formula:** `baud_div = clock_frequency / baud_rate - 1`  
For 115200 baud at 100 MHz: `100,000,000 / 115200 ≈ 868`

**How TX works:**  
When you write to TX_DATA, the UART loads the byte into a 10-bit shift register and shifts it out one bit at a time: start bit (0), then 8 data bits LSB-first, then stop bit (1). This matches the standard UART protocol.

**How RX works:**  
The RX input is constantly monitored for a falling edge (start bit). When detected, the UART waits half a bit-period then samples each bit at the middle of its window. This "mid-bit sampling" makes it robust to timing differences between sender and receiver.

The RX input goes through a **2-stage synchronizer** before use — two back-to-back flip-flops that prevent metastability (glitches from sampling an asynchronous signal).

**Interrupt:** The UART asserts `irq` when a byte is received or the transmitter finishes sending.

---

### `gpio.v` — General Purpose I/O

Controls the 8 LEDs (output) and reads the 8 slide switches (input) on the FPGA board.

**Registers:**

| Offset | Name | Read/Write | What it does |
|--------|------|------------|-------------|
| `0x0` | OUTPUT | Write | Sets the state of gpio_out[7:0] → LED pins |
| `0x4` | INPUT | Read | Reads the state of gpio_in[7:0] ← switch pins |

Writing `0xFF` to OUTPUT turns all 8 LEDs on. Reading INPUT returns the 8 switch positions.

---

### `timer.v` — Countdown Timer

A programmable timer that counts down from a loaded value to zero and generates an interrupt.

**Registers:**

| Offset | Name | Read/Write | What it does |
|--------|------|------------|-------------|
| `0x0` | LOAD | Read/Write | The value to count down from. Writing here also resets the counter immediately |
| `0x4` | COUNT | Read | Current counter value (decreases every clock when enabled) |
| `0x8` | CTRL | Read/Write | Bit 0 = enable (1=counting), Bit 1 = auto-reload (1=restart after timeout) |
| `0xC` | STATUS | Read/Write | Bit 0 = timeout flag. Write 1 to clear it |

**Auto-reload mode:** If `CTRL[1]=1`, when the counter reaches zero it automatically reloads from LOAD and keeps going — useful for periodic interrupts.

**One-shot mode:** If `CTRL[1]=0`, the timer stops after one countdown — useful for timeouts.

---

### `intc.v` — Interrupt Controller

Manages up to 4 interrupt sources and signals the CPU with a single `irq_to_cpu` line.

**Interrupt sources:**
- Bit 0: UART (byte received or TX done)
- Bit 1: Timer (countdown reached zero)
- Bit 2: SPI (transfer complete)
- Bit 3: I2C (transfer complete)

**Registers:**

| Offset | Name | Read/Write | What it does |
|--------|------|------------|-------------|
| `0x0` | PENDING | Read | Which interrupts have fired (bits 0–3) |
| `0x4` | ENABLE | Read/Write | Which interrupts are allowed to reach the CPU |
| `0x8` | CLEAR | Write | Write 1 to a bit to clear that interrupt |
| `0xC` | PRIORITY | Read/Write | Mark interrupt as high (1) or low (0) priority |

**Typical usage in software:**
1. Read PENDING to see which interrupt fired
2. Service that peripheral
3. Write to CLEAR to acknowledge the interrupt

---

### `spi.v` — SPI Master

SPI (Serial Peripheral Interface) is a fast, simple protocol used to talk to sensors, displays, and memory chips.

The SPI master initiates all transfers. It drives the SCK (clock), MOSI (master-out-slave-in), and CS_N (chip select) signals.

---

### `i2c.v` — I2C Master

I2C is a two-wire serial protocol (SDA = data, SCL = clock) used for short-range communication with peripherals like temperature sensors and accelerometers.

---

### `seg7_ctrl.v` — 7-Segment Display Driver

Drives the two 4-digit 7-segment displays on the Boolean FPGA board. It multiplexes between digits using a scanning technique — each digit is lit briefly in rapid succession, which looks like all 8 are on at once because human eyes can't see the flicker.

---

## All Supported Instructions

| Category | Instructions |
|----------|-------------|
| Arithmetic | ADD, ADDI, SUB |
| Logical | AND, ANDI, OR, ORI, XOR, XORI |
| Shift | SLL, SLLI, SRL, SRLI, SRA, SRAI |
| Compare | SLT, SLTI, SLTU, SLTIU |
| Load | LB, LH, LW, LBU, LHU |
| Store | SB, SH, SW |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| Jump | JAL, JALR |
| Upper Immediate | LUI, AUIPC |

**Total: 37 instructions** — the complete RV32I base integer ISA.
