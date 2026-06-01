# Simulation Filelists

This folder contains **filelist files** (`.f` files) — simple text files that list which Verilog/SystemVerilog source files should be compiled for simulation. Think of them as a manifest or a build target.

---

## Files

| File | Used With | What It Includes |
|------|-----------|-----------------|
| `filelist/rtl.f` | VCS, Vivado XSim | All RTL from `rtl/` — the original SystemVerilog version |
| `filelist/tb.f` | VCS, Vivado XSim | Testbench files from `tb/` |
| `filelist/rtl_nclaunch.f` | Cadence NCLaunch | RTL from `synthesis/genus/rtl/` — the wire-fixed version for Cadence tools |

---

## Why Are There Two RTL Filelists?

The design exists in two versions:

| Version | Location | Net type used | Works with |
|---------|----------|--------------|------------|
| Original | `rtl/` | `logic` (SystemVerilog) | Vivado, VCS, Verdi |
| Wire-fixed | `synthesis/genus/rtl/` | `wire` (Verilog-2001) | Cadence Genus, NCLaunch, Innovus |

Cadence tools in standard Verilog-2001 mode do not support `logic` as a net type — it's a SystemVerilog extension. To avoid tool errors, a separate copy of the RTL was made where every `logic` is replaced with `wire`. The actual hardware behavior is identical.

So:
- Use `rtl.f` for VCS and Vivado
- Use `rtl_nclaunch.f` for Cadence NCLaunch

---

## How to Use

### VCS
```bash
# From the repo root
vcs -full64 -sverilog -f sim/filelist/rtl.f tb/tb_soc_top.sv -o simv
./simv
```

### VCS with testbench filelist
```bash
vcs -full64 -sverilog -f sim/filelist/rtl.f -f sim/filelist/tb.f -o simv
./simv
```

### Cadence NCLaunch
In the NCLaunch GUI, add `sim/filelist/rtl_nclaunch.f` as the design filelist.  
Then add the testbench (`tb/tb_soc_top.sv`) separately.

---

## What's Inside a Filelist

A `.f` file is just a list of paths to source files, one per line. For example, `rtl.f` contains entries like:

```
rtl/cpu/pc.v
rtl/cpu/regfile.v
rtl/cpu/alu.v
...
rtl/soc_top.v
```

The simulator reads these files in order, so lower-level modules (leaves of the hierarchy) should come before the modules that instantiate them.
