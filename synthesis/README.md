# ASIC Synthesis & Physical Design

This folder contains the complete **ASIC back-end flow** — the process of turning Verilog code into a GDSII file (the format sent to a chip foundry for fabrication).

---

## What Is an ASIC?

An **ASIC** (Application-Specific Integrated Circuit) is a custom chip designed to do one specific thing. Unlike an FPGA (which is general-purpose and reconfigurable), an ASIC is manufactured with fixed logic — it's faster, smaller, and more power-efficient, but takes months and millions of dollars to produce.

This project uses the same professional tools (Cadence Genus and Innovus) that real chip design teams use, producing a real GDSII file that could theoretically be sent to a foundry.

---

## Two Sub-Flows

```
synthesis/
├── genus/      ← Step 1: Logic Synthesis (Verilog → Gate-level Netlist)
└── innovus/    ← Step 2: Place & Route (Netlist → Physical Layout → GDSII)
```

Each has its own README with detailed instructions.

---

## The Big Picture

```
┌─────────────────────────────────┐
│  Verilog RTL (synthesis/genus/rtl/) │
│  (wire-fixed version for Cadence)│
└────────────────┬────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  Cadence Genus  │  Logic Synthesis
        │                 │
        │  1. Read libs   │  ← Standard cell library (slow.lib)
        │  2. Elaborate   │  ← Build design hierarchy
        │  3. syn_generic │  ← Boolean optimization
        │  4. syn_map     │  ← Map to real standard cells
        │  5. syn_opt     │  ← Timing/area optimization
        └────────┬────────┘
                 │
                 │  Outputs:
                 ├── soc_top_netlist.v  (gate-level Verilog)
                 ├── soc_top.sdc        (timing constraints)
                 └── soc_top.sdf        (timing annotation)
                 │
                 ▼
        ┌─────────────────────┐
        │  Cadence Innovus    │  Place & Route
        │                     │
        │  1. Floorplan       │  ← Define chip area and I/O
        │  2. Power planning  │  ← VDD/GND power rings and stripes
        │  3. Placement       │  ← Place standard cells
        │  4. Clock Tree (CTS)│  ← Build balanced clock network
        │  5. Routing         │  ← Connect all the wires
        │  6. GDSII export    │  ← Final chip layout
        └────────┬────────────┘
                 │
                 │  Outputs:
                 ├── final.gds   (GDSII layout — the "blueprint" for the fab)
                 └── final.def   (design exchange format)
```

---

## Why a Separate RTL Version?

The main `rtl/` directory uses SystemVerilog's `logic` keyword. Cadence tools in standard Verilog-2001 mode don't support `logic` as a net type — only `wire` and `reg`.

So `synthesis/genus/rtl/` contains an **identical design** with all `logic` → `wire`. The logic behavior is exactly the same. This is also the version used for **Cadence NCLaunch** simulation.

| | `rtl/` | `synthesis/genus/rtl/` |
|-|--------|----------------------|
| Net type | `logic` | `wire` |
| Works with | Vivado, VCS, Verdi | Cadence Genus, NCLaunch, Innovus |
| Functional difference | None | None |

---

## See Also

- [Genus Synthesis README](genus/README.md) — how to run logic synthesis step by step
- [Innovus Place & Route README](innovus/README.md) — how to run the physical design flow
