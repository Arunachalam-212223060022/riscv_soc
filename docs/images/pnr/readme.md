<div align="center">

# Cadence Innovus — Place & Route Implementation Results

**Complete post-implementation record for the RISC-V RV32I SoC on 90nm CMOS Technology**

[![Tool](https://img.shields.io/badge/Tool-Cadence%20Innovus%2021.15-blue?style=for-the-badge)](#implementation-flow)
[![Design](https://img.shields.io/badge/Design-RISC--V%20RV32I%20SoC-orange?style=for-the-badge)](#target-design)
[![Node](https://img.shields.io/badge/Node-90nm%20CMOS-green?style=for-the-badge)](#target-design)
[![Cells](https://img.shields.io/badge/Cells-164%2C285%20Post--CTS-purple?style=for-the-badge)](#stage-4--post-cts-after-clock-tree-synthesis)
[![DRC](https://img.shields.io/badge/DRC-0%20Violations-brightgreen?style=for-the-badge)](#stage-6--post-route-drc-verification-pass)
[![Power](https://img.shields.io/badge/Power-106.55%20mW-yellow?style=for-the-badge)](#flow-summary)
[![Wire](https://img.shields.io/badge/Wire%20Length-7.045%20m-red?style=for-the-badge)](#stage-5--post-route-fully-routed-design)

</div>

---

## Table of Contents

1. [Target Design](#1-target-design)
2. [Mandatory Inputs for Physical Design](#2-mandatory-inputs-for-physical-design)
3. [Implementation Flow](#3-implementation-flow)
4. [Stage 1 — Floorplan (Empty Die)](#4-stage-1--floorplan-empty-die)
5. [Stage 2 — Post-Floorplan: Standard Cell Rows & Power Grid](#5-stage-2--post-floorplan-standard-cell-rows--power-grid)
6. [Stage 3 — Post-Placement (Pre-CTS)](#6-stage-3--post-placement-pre-cts)
7. [Stage 4 — Post-CTS (After Clock Tree Synthesis)](#7-stage-4--post-cts-after-clock-tree-synthesis)
8. [Stage 5 — Post-Route (Fully Routed Design)](#8-stage-5--post-route-fully-routed-design)
9. [Stage 6 — Post-Route DRC Verification Pass](#9-stage-6--post-route-drc-verification-pass)
10. [Flow Summary](#10-flow-summary)

---

## 1. Target Design

The RISC-V SoC was implemented using **Cadence Innovus 21.15** on a **90nm CMOS** standard cell process using the GSCLIB090 foundry library.

| Parameter | Value |
|-----------|-------|
| **Design** | `soc_top` — RISC-V RV32I SoC |
| **Tool** | Cadence Innovus™ Implementation System 21.15 |
| **Technology Node** | 90nm CMOS |
| **Standard Cell Library** | GSCLIB090 (gsclib090_translated.lef) |
| **Liberty Files** | slow.lib (Setup) / fast.lib (Hold) |
| **Power Supply** | VDD / VSS |
| **Target Frequency** | 100 MHz |
| **Core Area** | 1.7462 mm² |
| **Chip Area** | 2.83 mm² |
| **Core Utilisation** | 64.47% |
| **Total Cells (Post-CTS)** | 164,285 |
| **Scan Flip-Flops** | 63,455 (`SDFFQXL`) |
| **Total Wire Length** | 7.045 m |
| **Total Power** | 106.55 mW |
| **DRC Violations** | 0 |

The SoC integrates the following modules:

| Module | Function |
|--------|----------|
| `cpu_top` | RISC-V RV32I 5-stage pipeline (IF/ID/EX/MEM/WB) |
| `imem` | 8 KB Instruction Memory |
| `dmem` | 8 KB Data SRAM |
| `uart` | Universal Asynchronous Receiver/Transmitter |
| `spi` | Serial Peripheral Interface |
| `i2c` | Inter-Integrated Circuit |
| `gpio` | General Purpose I/O (8-bit bidirectional) |
| `timer` | 32-bit Down Counter with IRQ |
| `intc` | Interrupt Controller |

---

## 2. Mandatory Inputs for Physical Design

Before launching Innovus, the following files were required from the upstream Genus synthesis flow:

| Input | File | Source |
|-------|------|--------|
| **Gate-Level Netlist** | `soc_top_netlist.v` | Genus synthesis output |
| **Block-Level SDC** | `soc_top_tool.sdc` | Genus synthesis output |
| **Liberty Files (.lib)** | `slow.lib`, `fast.lib` | `/home/install/FOUNDRY/digital/90nm/dig/lib/` |
| **LEF Files** | `gsclib090_translated.lef` | `/home/install/FOUNDRY/digital/90nm/dig/lef/` |
| **Cap Table** | `capTable` | `/home/install/FOUNDRY/digital/45nm/LIBS/captbl/worst/` |
| **QRC Tech File** | `qrcTechFile` | `/home/install/FOUNDRY/digital/45nm/LIBS/qx/` |

**Expected Outputs from Physical Design:**

| Output | File | Purpose |
|--------|------|---------|
| **GDSII** | `final.gds` | Fabrication tape-out deliverable |
| **SPEF** | `soc_top.spef` | Parasitic extraction for sign-off STA |
| **SDF** | `soc_top.sdf` | Back-annotated delay file |
| **DEF** | `final.def` | Final placement for handoff |

---

## 3. Implementation Flow

The complete physical design flow is executed inside Cadence Innovus using the TCL script:

```bash
innovus -init pnr_flow.tcl
```

Innovus runs through these stages in sequence:

```
Gate-Level Netlist (.v)    SDC Constraints    LEF / Liberty Files
         │                       │                    │
         └───────────────────────┼────────────────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  1. IMPORT DESIGN      │  readNetlist + readDEF
                    │  Load netlist + libs   │  143,438 cells · MMMC setup
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  2. FLOORPLAN          │  floorPlan -r 0.6 0.75 5 5 5 5
                    │  Die area + core rows  │  Core: 1.7462 mm²
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  3. POWER PLANNING     │  addRing + addStripe
                    │  VDD/VSS mesh          │  Metal5 (V) + Metal6 (H)
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  4. PRE-PLACEMENT      │  addEndCap + addWellTap
                    │  Physical cells        │  FILL64 end caps · 30µm taps
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  5. PLACEMENT          │  place_design (Timing-Driven)
                    │  143,438 cells placed  │  optDesign -preCTS -hold
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  6. CTS                │  clockDesign (CCOpt)
                    │  Clock tree inserted   │  +20,847 buffers · skew < 0.1ns
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  7. ROUTING            │  routeDesign (NanoRoute)
                    │  All nets routed M1–M9 │  7.045 m total wire length
                    └────────────┬───────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  8. SIGNOFF            │  verifyDRC + verifyConnectivity
                    │  DRC + LVS clean       │  0 violations → streamOut GDS
                    └────────────┬───────────┘
                                 ▼
                         final.gds  ←── Tape-out deliverable
```

---

## 4. Stage 1 — Floorplan (Empty Die)

<img width="1433" height="865" alt="Screenshot 2026-06-04 100352" src="https://github.com/user-attachments/assets/d092a4d4-7225-47e8-b712-78a6c75d84c0" />

**Command:**
```tcl
floorPlan -r 0.6 0.75 5.0 5.0 5.0 5.0
```

**Floorplan Parameters Used:**

| Parameter | Value | Meaning |
|-----------|-------|---------|
| Aspect Ratio (H/W) | **0.75** | Slightly wider than tall — suits peripheral I/O placement |
| Core Utilisation | **0.60** (60%) | 60% of core area used — leaves routing headroom |
| Core to IO Margin | **5.0 µm** all sides | Channel for power rings + IO pin routing |
| Core Area | **~1.75 mm²** | Calculated from utilisation + netlist cell area |
| Standard Cell Rows | **562 rows** | Horizontal rows spanning full core width |

**What This View Shows:**

This is the starting point of the physical design flow. The floorplan command defines two nested boundaries visible in the GUI:

- The **cyan/teal border** is the **core boundary** — the region where all standard cells will legally be placed. This is derived from the aspect ratio (0.75) and core utilisation target (60%). All 143,438 standard cells from the Genus netlist will snap into rows within this boundary.
- The **orange/brown outer border** is the **die boundary** — includes the IO ring margin and power ring spacing (5 µm on all four sides as specified in the `floorPlan` command).
- The large **grey interior** is completely empty — no standard cells, no routing, no power stripes yet. The core is a blank canvas.

At 60% core utilisation, approximately **40% of the core area is reserved as whitespace** for signal routing, clock tree buffers, and filler cells. This is the single most important parameter for achieving clean routing — going above 75% utilisation typically causes congestion failures.

This image confirms that die dimensions and aspect ratio were set correctly before any placement begins.

---

## 5. Stage 2 — Post-Floorplan: Standard Cell Rows & Power Grid

<img width="1647" height="907" alt="Screenshot 2026-06-04 100613" src="https://github.com/user-attachments/assets/08651f21-b562-4c18-9af7-29236d0e6e1d" />

**Commands:**
```tcl
# Global Net Connections
globalNetConnect VDD -type pgpin -pin VDD -inst * -module {}
globalNetConnect VSS -type pgpin -pin VSS -inst * -module {}

# Power Rings (around core boundary)
addRing -nets {VDD VSS} -type core_rings -follow core \
        -layer {top Metal9 bottom Metal9 left Metal8 right Metal8} \
        -width 2.4 -spacing 0.8 -offset center_in_channel

# Power Stripes — Horizontal (Metal9)
addStripe -nets {VDD VSS} -layer Metal9 -direction horizontal \
          -width 2.4 -spacing 0.8 -number_of_sets 5 \
          -start_from bottom -set_to_set_distance 100 \
          -stripe_boundary core_ring

# Power Stripes — Vertical (Metal8)
addStripe -nets {VDD VSS} -layer Metal8 -direction vertical \
          -width 2.4 -spacing 0.8 -number_of_sets 5 \
          -start_from left -set_to_set_distance 100 \
          -stripe_boundary core_ring

# Special Route — connect stripes to Metal1 via stacked vias
sroute -nets {VDD VSS}
```

**Power Grid Specifications:**

| Element | Layer | Direction | Width | Spacing | Count |
|---------|-------|-----------|-------|---------|-------|
| Power Ring (H) | Metal9 | Horizontal | 2.4 µm | 0.8 µm | 1 ring |
| Power Ring (V) | Metal8 | Vertical | 2.4 µm | 0.8 µm | 1 ring |
| Power Stripes (H) | Metal9 | Horizontal | 2.4 µm | 0.8 µm | 5 sets |
| Power Stripes (V) | Metal8 | Vertical | 2.4 µm | 0.8 µm | 5 sets |

**What This View Shows:**

After floorplanning, Innovus creates **standard cell rows** and lays down the **power distribution network**. The grid pattern now visible results from two steps:

- **Cyan vertical lines** — standard cell row boundaries. Each row is one cell-height tall and spans the full core width. These rows define the legal placement sites for every standard cell. All 143,438 cells from the Genus netlist will snap to these rows during `place_design`. The ~562 rows visible match the post-route results.
- **Orange/brown grid** — VDD and VSS power rings and stripes. Horizontal stripes run on Metal9 (top layer for horizontal power) and vertical stripes run on Metal8. Together they form the power mesh that supplies current to every standard cell row through stacked vias down to Metal1.

**Why These Metal Layers:**
Highest metal layers (Metal8, Metal9) are used for power because they have the greatest thickness and width, meaning the **lowest sheet resistance** and thus the lowest IR drop from the power supply to the cells. The `sroute` step creates stacked via pillars connecting Metal9 → Metal8 → ... → Metal1, where VDD/VSS rails of each standard cell row sit.

At this stage the design is still **logically empty** — no logic cells are placed yet — but the physical infrastructure (rows, power, I/O pad slots) is fully committed.

---

## 6. Stage 3 — Post-Placement (Pre-CTS)

<img width="1920" height="1020" alt="Screenshot 2026-06-04 103751" src="https://github.com/user-attachments/assets/a73cf87e-08fe-485e-926c-07fae3ae35ce" />

**Commands:**
```tcl
# Pre-placement physical cells
addEndCap -preCap FILL64 -postCap FILL64

addWellTap -cell FILL4 -cellInterval 30 -prefix WELLTAP

# Full placement with timing-driven mode
setPlaceMode -congEffort high \
             -timingDriven true \
             -clkGatingAware true \
             -powerDriven true \
             -placeIOPins true \
             -maxRouteLayer 6

place_design

# Pre-CTS hold optimisation
optDesign -preCTS -hold
```

**Placement Configuration:**

| Parameter | Value | Reason |
|-----------|-------|--------|
| Congestion Effort | **High** | Multi-module SoC with 8 blocks — prevents local hotspots |
| Timing Driven | **True** | Critical path cells placed closer together |
| Clock Gating Aware | **True** | 63,455 scan FFs benefit from clock-aware placement |
| Power Driven | **True** | Minimises switching activity on high-fanout nets |
| Place IO Pins | **True** | Distributes external pins along die boundary |
| Max Route Layer | **6** | Tells placer to estimate routing using up to Metal6 |

**End Cap Cells:**

| Cell | Stage | Purpose |
|------|-------|---------|
| **FILL64** | Pre End Cap | Left/right boundary of every row — prevents cells sliding out |
| **FILL64** | Post End Cap | Right boundary of every row — completes N-well continuity |

**Well Tap Cells:**

| Cell | Interval | Purpose |
|------|----------|---------|
| **FILL4** | 30 µm | Shunt resistance connection — prevents latch-up in bulk CMOS |

**What This View Shows:**

This is the design after `place_design` completes. Every one of the **143,438 standard cells** has been legally placed into the cell rows. The colour density map reflects **cell concentration and local utilisation**:

- **Red/dark-red regions** — high cell density: CPU datapath (ALU, register file, data path mux, control logic), these are the logic-heaviest parts of the SoC
- **Yellow/orange regions** — medium density: peripheral state machines (UART, SPI, I2C, Timer, INTC), address decode logic, and bus multiplexers
- **Green regions** — lower density and filler cells; whitespace reserved for routing and CTS buffer insertion
- **Blue border** — I/O pad ring and power ring structure
- **Yellow markers** (left side) — I/O pad connections for the SoC's external pins

The dense but relatively uniform fill across the core confirms **64.47% core utilisation** — enough whitespace (green patches) for the router to complete all nets without congestion.

**At this stage, the clock net is not yet distributed** — it connects as a single high-fanout wire to all 63,455 scan flip-flop clock pins simultaneously. Timing pessimism from this will be resolved in Stage 4.

`optDesign -preCTS -hold` fixes any setup violations that placement introduced and pre-sizes cells along the critical path.

---

## 7. Stage 4 — Post-CTS (After Clock Tree Synthesis)

<img width="1920" height="1020" alt="Screenshot 2026-06-04 111447" src="https://github.com/user-attachments/assets/509aa5df-f133-486c-a87c-fc9d692a2d64" />

**Commands:**
```tcl
# Set clock tree specification
create_clock_tree_spec -output clock.ctstch -bufferList {BUFX2 BUFX4 BUFX8}

# Run CCOpt clock tree synthesis
setClockTreeSynthesisMode -autoAssignBuffers true \
                          -targetMaxTrans 0.15 \
                          -targetSkew 0.05

clockDesign -specFile clock.ctstch -outDir CTS_output

# Post-CTS optimisation for setup and hold
optDesign -postCTS -hold
```

**CTS Targets:**

| Parameter | Target | Achieved |
|-----------|--------|----------|
| Max Transition Time | 0.15 ns | ✅ Met |
| Target Clock Skew | 0.05 ns | ✅ < 0.1 ns |
| Buffer Cells Inserted | — | ~20,847 cells |
| Hold Violations Post-CTS | 0 | ✅ Clean |

**Cell Count Delta After CTS:**

| Stage | Cell Count | Delta |
|-------|-----------|-------|
| Post-Placement | 143,438 | — |
| Post-CTS | **164,285** | **+20,847** |

The additional ~20,847 cells are **CTS buffers and hold-fix buffers** inserted by `clockDesign`. Despite adding ~20K cells, the core area remains essentially flat — these are minimum-strength buffer cells.

**What This View Shows:**

This image captures the design immediately after Clock Tree Synthesis. Innovus inserted a hierarchical tree of clock buffers and inverters to distribute the 100 MHz clock to all **63,455 scan flip-flops** (`SDFFQXL`) with minimal skew.

Key changes visible when comparing to Stage 3:

- **Cell count increased** — total cells grew from 143,438 to **164,285** post-CTS. The additional cells are CTS buffers distributed at intermediate fanout points throughout the core.
- **Colour distribution shifted** — the top region shows changed density from newly inserted CTS buffers spreading across the hierarchy. Small green patches at top-centre are regions where these buffers were inserted.
- **Red dominance increased** — with hold-fix buffers added by `optDesign -postCTS -hold`, overall cell density increased slightly.

After CTS, **timing analysis becomes meaningful** for the first time: the clock tree has a defined topology, skew is controlled, and setup/hold margins are evaluated with real clock propagation delays rather than ideal-clock assumptions.

---

## 8. Stage 5 — Post-Route (Fully Routed Design)

<img width="1920" height="1020" alt="Screenshot 2026-06-04 112057" src="https://github.com/user-attachments/assets/b82e3ebc-b8f9-4d94-af4a-8d0a40b09fb1" />

**Commands:**
```tcl
# Run NanoRoute global and detail routing
routeDesign

# Post-route timing optimisation
optDesign -postRoute

# Post-route hold fixing
optDesign -postRoute -hold
```

**Routing Stack — Layer Usage:**

| Colour in View | Metal Layer | Direction | Primary Use |
|----------------|-------------|-----------|-------------|
| **Red/dark-red** | M1, M3, M5 (odd) | Horizontal | Local interconnect, cell internal routing |
| **Green** | M2, M4, M6 (even) | Vertical | Signal routing, mid-level connections |
| **Yellow/orange** | Via layers | — | Layer transitions between metals |
| **Cyan** | M7–M9 (upper) | H + V | Long global routes, clock distribution |
| **Blue** | Power stripes | — | VDD/GND power mesh |

**Post-Route Results:**

| Metric | Value | Status |
|--------|-------|--------|
| Total Wire Length | **7.045 m** | All layers combined |
| Unrouted Nets | **0** | ✅ 100% routing completion |
| Multi-driven Nets | **0** | ✅ Clean |
| Floating PG Pins | **0** | ✅ Clean |
| Setup WNS | **Positive** | ✅ Timing met |
| Hold WNS | **Positive** | ✅ No hold violations |

**What This View Shows:**

This is the **fully routed design** — every signal net in the SoC has been assigned specific metal tracks and via stacks across the 9-layer metal stack (M1–M9). This is the most complex view in the flow.

The **total post-route wire length of 7.045 metres** is the combined length of all signal wires across all 9 routing layers needed to connect 164,285 cells. The dense, uniform weave of horizontal and vertical lines across the core confirms that the router successfully completed all nets with zero unrouted connections.

**Understanding the Wire Density:**
The dense crosshatch pattern is not congestion — it is the expected result of routing ~150K nets across 9 metal layers in a 1.75 mm² area. The uniformity of the weave (no large patches of one colour, no voids) confirms the placer correctly distributed cells so the router had balanced demand across all routing layers.

The **yellow I/O stubs** on the left side are the SoC's external pad connections: UART, GPIO, clock, and reset signals routed to the die boundary.

`optDesign -postRoute` runs timing-driven post-route optimisation, adjusting wire sizing and buffer placement on critical paths to maintain the 10 ns (100 MHz) timing constraint through the additional parasitic delays introduced by physical routing.

---

## 9. Stage 6 — Post-Route DRC Verification Pass

<img width="1920" height="1020" alt="Screenshot 2026-06-04 112057" src="https://github.com/user-attachments/assets/9b48d53c-71a1-4578-b059-c0f40d6a85da" />

**Commands:**
```tcl
# Design Rule Check
verifyDRC -report soc_top.drc.rpt

# Connectivity Verification
verifyConnectivity -report soc_top.connect.rpt -type all

# Antenna Check
verifyProcessAntenna -report soc_top.antenna.rpt -error 1000

# Stream out final GDSII
streamOut final.gds \
    -mapFile /home/install/FOUNDRY/digital/90nm/gds/streamOut.map \
    -libName soc_top \
    -units 1000 \
    -mode ALL

# Write final DEF
defOut final.def
```

**Sign-off Results:**

| Check | Command | Result |
|-------|---------|--------|
| Design Rule Check | `verifyDRC` | **0 violations** ✅ |
| Connectivity | `verifyConnectivity` | **0 unconnected nets** ✅ |
| Multi-driven Nets | — | **0** ✅ |
| Floating PG Pins | — | **0** ✅ |
| Combinational Loops | — | **0** ✅ |
| Antenna Violations | `verifyProcessAntenna` | **0** ✅ |

**What This View Shows:**

This is a second post-route view of the same fully routed design captured at a different scroll position. The two views together demonstrate that the dense routing pattern is **consistent and uniform across the entire core** — no localised congestion hotspots, no large unrouted regions, and no DRC marker highlights (which would appear as bright white or orange markers if present).

**Understanding DRC = 0:**
A DRC violation would indicate a physical design rule from the foundry has been broken — minimum spacing between two metal lines, minimum wire width, via enclosure rules, etc. **Zero DRC violations** is a hard requirement for tape-out: any violation would cause a lithography defect on silicon. Achieving 0 DRC on a design of this complexity (164,285 cells, 7 metres of wire, 9 metal layers) confirms that NanoRoute's rule-aware router correctly honoured every 90nm foundry constraint throughout the entire routing run.

With 0 DRC violations confirmed, `streamOut` exports the final **GDSII layout file** (`final.gds`) — the tape-out deliverable containing the complete geometric description of every polygon on every layer of the chip, ready for submission to a silicon foundry.

---

## 10. Flow Summary

| Stage | Image | Key Command | Key Output |
|-------|-------|-------------|------------|
| **1 — Floorplan** | Empty die + core boundary | `floorPlan -r 0.6 0.75 5 5 5 5` | Die area: ~1.75 mm² core |
| **2 — Power Grid** | Cell rows + power mesh | `addRing` + `addStripe` + `sroute` | 562 rows · VDD/GND on M8/M9 |
| **3 — Placement** | All 143,438 cells placed | `place_design` + `optDesign -preCTS` | 64.47% utilisation · 0 DRC |
| **4 — CTS** | Clock tree inserted | `clockDesign` + `optDesign -postCTS` | +20,847 CTS buffers · skew < 0.1 ns |
| **5 — Route** | All nets routed M1–M9 | `routeDesign` + `optDesign -postRoute` | 7.045 m wire · 0 unrouted |
| **6 — Sign-off** | DRC-clean layout exported | `verifyDRC` + `streamOut` | 0 DRC violations → `final.gds` ✅ |

---

### Final Design Metrics

| Metric | Value |
|--------|-------|
| **Tool** | Cadence Innovus™ 21.15 |
| **Host** | `cadence-saveetha-in` |
| **Technology** | 90nm CMOS (GSCLIB090) |
| **Core Area** | 1.7462 mm² |
| **Chip Area** | 2.83 mm² |
| **Core Utilisation** | 64.47% |
| **Standard Cell Rows** | 562 |
| **Total Cells (Pre-CTS)** | 143,438 |
| **Total Cells (Post-CTS)** | 164,285 |
| **CTS Buffers Added** | ~20,847 |
| **Scan Flip-Flops** | 63,455 (`SDFFQXL`) |
| **Total Wire Length** | 7.045 m |
| **Metal Layers Used** | M1 – M9 |
| **Power (VDD)** | Metal9 (H) + Metal8 (V) |
| **Total Power** | 106.55 mW |
| **DRC Violations** | **0** |
| **Unrouted Nets** | **0** |
| **Tape-out Output** | `synthesis/innovus/results/final.gds` |

---

<div align="center">

**RISC-V SoC — Physical Design Complete**

164,285 Cells · 7.045 m Wire · 0 DRC Violations · 106.55 mW · `final.gds` Generated

*Floorplan → Power Grid → Placement → CTS → Route → Sign-off → Tape-out*

Saveetha Engineering College — ECE Department  
Arunachalam P (212223060022) · Charan PG (212223060033)

</div>
