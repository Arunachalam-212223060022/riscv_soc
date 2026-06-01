# Embedded Software

This folder contains the **assembly program** that runs on the RISC-V CPU, along with the tools to build and convert it into a format the CPU can load.

---

## What Is This?

The CPU needs a program to run. This folder provides that program — written in RISC-V assembly language. It's the "hello world" of the SoC: it proves the CPU, memory, and peripherals all work together.

---

## Files

| File | What It Is |
|------|-----------|
| `demo.S` | RISC-V assembly source code (the program) |
| `link.ld` | Linker script — tells the linker where in memory to place code and data |
| `Makefile` | Build instructions — type `make` to compile everything |
| `bin2mem.py` | Python script that converts the binary output into a hex format Verilog can read |
| `program.mem` | The final hex file that gets loaded into the CPU's instruction memory |
| `demo.elf` | Compiled ELF binary (intermediate build artifact) |
| `demo.bin` | Raw binary of the program (intermediate build artifact) |

---

## What the Program Does

The demo program (`demo.S`) does three things in order:

**Step 1 — Print a message over UART**  
Sends the string `RISCV SOC OK` followed by a carriage return and newline over the serial port at 115200 baud. If you open a terminal (PuTTY, minicom, etc.) connected to the board's USB-UART port, you'll see this message when the FPGA is powered on.

**Step 2 — Mirror switches to LEDs (infinite loop)**  
Reads the 8 slide switches (via GPIO input register) and immediately writes that value to the LEDs (via GPIO output register). This runs forever, so moving a switch immediately flips the corresponding LED.

**Step 3 — Display switch value on the 7-segment display**  
The same switch value is also written to the 7-segment display controller, so the hex digits update in real time as you flip switches.

---

## The Assembly Code Explained

```asm
_start:
    li t0, 0x10000000   # Load UART base address into register t0
    li t1, 0x20000000   # Load GPIO base address into register t1
    li t2, 0x20000100   # Load 7-segment base address into register t2

    la a0, msg          # Point a0 to the start of our message string

print_loop:
    lb a1, 0(a0)        # Load one byte from the string
    beqz a1, main_loop  # If it's 0 (null terminator), we're done — jump to main loop

wait_tx:
    lw a2, 4(t0)        # Read UART STATUS register (offset 4 from UART base)
    andi a2, a2, 1      # Isolate bit 0 (tx_busy flag)
    bnez a2, wait_tx    # If tx_busy=1, keep waiting

    sw a1, 0(t0)        # Write the byte to UART TX register → sends it
    addi a0, a0, 1      # Advance to next character
    j print_loop        # Loop back for next character

main_loop:
    lw a0, 4(t1)        # Read GPIO INPUT register (switches)
    sw a0, 0(t1)        # Write same value to GPIO OUTPUT register (LEDs)
    sw a0, 0(t2)        # Write same value to 7-segment display
    j main_loop         # Repeat forever

msg:
    .string "RISCV SOC OK\r\n"   # The message to send (null-terminated)
```

Every line of this program uses real RISC-V instructions — `li`, `la`, `lb`, `lw`, `sw`, `beqz`, `bnez`, `addi`, `j` — all implemented by the CPU in `rtl/cpu/`.

---

## Memory Layout

The linker script (`link.ld`) defines where the program and data live:

```
IMEM (instruction memory): 0x00000000 to 0x00001FFF   (8 KB)
DMEM (data memory):        0x00002000 to 0x00003FFF   (8 KB)
```

`.text` (code) and `.rodata` (read-only data like strings) go into IMEM.  
`.data` and `.bss` (variables) go into DMEM.

This matches the SoC's address map exactly.

---

## How to Build

### Prerequisites

Install the RISC-V cross-compilation toolchain:

```bash
# Ubuntu/Debian
sudo apt install gcc-riscv64-unknown-elf

# Or download a pre-built toolchain from:
# https://github.com/riscv-collab/riscv-gnu-toolchain/releases
```

### Build

```bash
cd sw/
make
```

This runs four commands automatically:

1. **Assemble:** `riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 ... demo.S -o demo.elf`  
   Converts assembly source → ELF binary (like a `.exe` but for RISC-V)

2. **Extract binary:** `riscv64-unknown-elf-objcopy -O binary demo.elf demo.bin`  
   Strips ELF headers → raw binary (just the bytes the CPU will execute)

3. **Convert to hex:** `python3 bin2mem.py demo.bin program.mem`  
   Converts binary → hex file in `$readmemh` format

4. **Copy to RTL:** Copies `program.mem` to `rtl/memory/program.mem`  
   So `imem.v` picks it up automatically when the simulator runs

### Clean

```bash
make clean
# Removes: demo.elf, demo.bin, program.mem
```

---

## How `bin2mem.py` Works

Verilog's `$readmemh` function loads a memory from a text file of hex values. The format it expects is one 32-bit word per line, in hexadecimal, most-significant byte first.

`bin2mem.py` reads the raw binary file 4 bytes at a time (one word), converts each word to a hex string, and writes it as a line in `program.mem`.

Example of what `program.mem` looks like:
```
37100001   ← first instruction (li t0, 0x10000000)
37100002   ← second instruction (li t1, 0x20000000)
...
```

---

## Pre-Built Version

The `program.mem` file in this folder is already built and ready to use. If you don't want to install the toolchain, the simulation and FPGA flow will use this pre-built version automatically.

Only rebuild if you modify `demo.S` and want to test your changes.
