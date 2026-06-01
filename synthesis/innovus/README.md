# Cadence Innovus — Place & Route

This folder covers **physical implementation** — taking the gate-level netlist from Genus and turning it into an actual chip layout (GDSII file).

---

## What Is Place & Route?

After logic synthesis, you have a list of gates and how they're connected — but no information about where those gates physically sit on the chip or how the wires between them actually route.

**Place & Route (PnR)** solves this:
- **Floorplan** — decide the chip's dimensions and where I/O pads go
- **Placement** — place each standard cell in a physical location on the chip
- **Clock Tree Synthesis (CTS)** — build a balanced clock distribution network
- **Routing** — draw the actual metal wires connecting all the placed cells
- **GDSII export** — produce the final layout file the fab uses to manufacture the chip

---

## Folder Structure

```
innovus/
├── scripts/          ← TCL scripts to run each PnR step
│   ├── innovus_init.tcl     ← Initialize design (load netlist, LEF, SDC)
│   └── pnr_flow.tcl         ← Complete automated PnR flow
├── reports/          ← Post-route reports (timing, power, area)
└── results/          ← Final outputs
    ├── final.gds     ← GDSII layout (the chip blueprint)
    └── final.def     ← Design exchange format (alternative layout format)
```

---

## Before You Start

You need:
1. **Cadence Innovus** installed and licensed
2. The **Genus outputs** from `synthesis/genus/netlist/`:
   - `soc_top_netlist.v` — gate-level netlist
   - `soc_top.sdc` — timing constraints
   - `soc_top.sdf` — timing annotation
3. **Technology LEF** — the physical design rules for the process node
4. **Standard cell LEF** — the physical dimensions of each standard cell

---

## How to Run

### Full Automated Flow
```bash
cd synthesis/innovus/
innovus -batch -files scripts/pnr_flow.tcl
```

### Interactive (Recommended for Learning)
```bash
innovus
# Then run commands interactively or source the script:
# source scripts/pnr_flow.tcl
```

---

## PnR Flow — Step by Step

### Step 1 — Design Initialization

Load the netlist, technology files, and constraints:

```tcl
read_physical -lef {tech.lef cells.lef}      # Physical design rules + cell shapes
read_netlist synthesis/genus/netlist/soc_top_netlist.v  # Gate-level netlist
read_sdc synthesis/genus/netlist/soc_top.sdc # Timing constraints
init_design
```

After this step, Innovus knows: which gates exist, how they connect, and what timing to target. But nothing is placed yet — all cells are piled up at position (0,0).

---

### Step 2 — Floorplanning

Define the chip's physical dimensions and where the I/O pads go:

```tcl
floorPlan -r 0.6 0.75 5.0 5.0 5.0 5.0
# -r: core utilization ratio (0.6 = use 60% of core area for cells)
# 0.75: aspect ratio (height/width)
# 5.0 5.0 5.0 5.0: margins (top, bottom, left, right) in microns
```

**What utilization ratio means:** A ratio of 0.6 means standard cells will occupy 60% of the available core area. The remaining 40% is needed for routing channels (wire space). Too high a ratio → routing congestion. Too low → wasted area.

---

### Step 3 — Power Planning

Create the power distribution network (VDD and GND):

```tcl
# Power rings surround the core (thick wires for low resistance)
addRing -nets {VDD GND} -width 2 -spacing 1 \
        -layer {top M6 bottom M6 left M5 right M5}

# Power stripes run across the core (grid pattern)
addStripe -nets {VDD GND} -width 1 -spacing 0.5 -layer M5 -direction vertical
```

Every flip-flop and logic gate needs VDD and GND. This power grid ensures all cells can reach a power rail with short, low-resistance connections.

---

### Step 4 — Placement

Place all standard cells in legal positions:

```tcl
place_design
optDesign -preCTS -hold    # Fix hold violations before clock tree
```

Innovus uses complex algorithms to minimize wire length while respecting:
- No overlapping cells
- All cells on the placement grid
- Timing goals (place cells that are timing-critical closer together)

After placement, the design looks like a grid of cells — but the clock hasn't been connected yet.

---

### Step 5 — Clock Tree Synthesis (CTS)

Build a balanced clock distribution network:

```tcl
create_clock_tree_spec   # Specify the clock target (from SDC)
clockDesign              # Build the tree with buffer/inverter insertion
optDesign -postCTS -hold # Fix hold violations after CTS
```

**Why CTS matters:** The clock must reach every flip-flop at almost exactly the same time. If some flops receive the clock 100ps later than others, that's **clock skew**, and it causes timing failures. CTS inserts clock buffers and inverters to balance path delays across the entire chip.

**Before CTS:** The clock is a single wire from the input pin — some flops are far away and receive the clock late.  
**After CTS:** The clock tree branches out like a tree, with inserted buffers ensuring all flops receive the clock within a few picoseconds of each other.

---

### Step 6 — Routing

Connect all the logic gates with metal wires:

```tcl
routeDesign        # Route all signals
optDesign -postRoute  # Final timing optimization after routing
```

Routing happens in two phases:
1. **Global routing** — plans which channels each net will use (like planning which streets to take)
2. **Detailed routing** — draws the actual wires pixel-by-pixel on each metal layer

Metal layers are used for different wire directions (e.g., M1 horizontal, M2 vertical) to avoid conflicts.

---

### Step 7 — Signoff and GDSII Export

Verify the design and export the final layout:

```tcl
verifyDRC            # Check design rules (spacing, width violations)
verifyConnectivity   # Check all nets are properly connected

streamOut synthesis/innovus/results/final.gds \
    -mapFile gds.map \
    -units 1000
```

**DRC (Design Rule Check):** The foundry has strict rules about minimum wire widths, spacing, and layer usage. DRC checks that no rules are violated. Zero violations = the chip can be manufactured.

**GDSII** is the industry-standard file format for chip layouts — like a PDF for chip designs. This file goes to the foundry.

---

## Visual Documentation Guide

Each PnR stage has a characteristic appearance in Innovus. Add screenshots to [`docs/images/pnr/`](../../docs/images/pnr/):

| Stage | What you should see | Filename |
|-------|---------------------|---------|
| After floorplan | Die boundary outline, I/O pads around edges, power rings (thick colored rectangles) | `innovus_floorplan.png` |
| After placement | Small colored rectangles (cells) filling the core area — should look dense | `innovus_placement.png` |
| Before CTS | Clock net shown as a single pin connection | `innovus_pre_cts.png` |
| After CTS | Clock shown as a tree branching to all flip-flops with inserted buffer cells visible | `innovus_post_cts.png` |
| After routing | The full chip covered in colored lines (each metal layer is a different color) | `innovus_routed.png` |
| 3D view | Stacked metal layers visible from an isometric angle | `innovus_3d.png` |
| GDSII (in KLayout) | Final chip layout viewable in KLayout (free GDS viewer) | `innovus_gdsii.png` |

---

## Key Metrics After PnR

After completing the full flow, record these results:

| Metric | How to find it | Meaning |
|--------|---------------|---------|
| Die area | Innovus GUI or `report_area` | Total chip size in µm² |
| Core utilization | Floorplan settings | % of core used by cells |
| WNS post-route | `report_timing` | Worst timing slack (≥ 0 = timing met) |
| Total wirelength | `report_route` | Total wire length in µm |
| DRC violations | `verifyDRC` output | Must be 0 for sign-off |
| Total power | `report_power` | mW total (post-route estimate) |

---

## Common Issues

**High routing congestion** → Lower the core utilization ratio in `floorPlan` command  
**Timing violations after routing** → Re-run `optDesign -postRoute` with more effort  
**DRC violations** → Often fixed by re-routing or adjusting cell placement in congested areas  
**Large clock skew** → Adjust CTS target skew or increase clock tree buffer strength
