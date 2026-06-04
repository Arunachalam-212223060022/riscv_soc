# Cadence Innovus — Place & Route Flow

**Tool:** Cadence Innovus™ Implementation System 21.15  
**Design:** `soc_top` — RISC-V RV32I SoC  
**Path:** `/home/learner01/ARUNACHALAM/riscv_soc_fixed/riscv_fixed/soc_top`  
**Script:** `synthesis/innovus/scripts/pnr_flow.tcl`

The six images below capture six sequential checkpoints in the Cadence Innovus Place & Route flow — from an empty floorplan all the way through post-CTS optimisation with a fully realised clock tree and routed power grid.

---

## Stage 1 — Floorplan (Empty Die)

<img width="1433" height="865" alt="Screenshot 2026-06-04 100352" src="https://github.com/user-attachments/assets/d092a4d4-7225-47e8-b712-78a6c75d84c0" />


**Command:** `floorPlan -r 0.6 0.75 5.0 5.0 5.0 5.0`  
**View:** Innovus Layout — no cells placed yet

This is the starting point of the physical design flow. The Innovus floorplan command has defined the **die boundary** and **core boundary** for the SoC:

- The **cyan/teal border** is the core area boundary — the region inside which all standard cells will be placed. This is derived from the floorplan aspect ratio (0.75) and core utilisation target (60%).
- The **orange/brown border** is the die boundary, including the I/O ring margin and power ring spacing (5 µm on all sides as specified in the `floorPlan` command).
- The large **grey interior** is completely empty — no standard cells, no routing, no power stripes yet. The core is a blank canvas ready to receive the 143,438 standard cells from the Genus netlist.

This image confirms that the die dimensions and aspect ratio were set correctly before any placement begins. The core area at this stage corresponds to approximately **1.75 mm²**, which — at 64.47% utilisation — will accommodate the full SoC logic including 63,455 scan flip-flops.

---

## Stage 2 — Post-Floorplan: Standard Cell Rows & Power Grid


<img width="1647" height="907" alt="Screenshot 2026-06-04 100613" src="https://github.com/user-attachments/assets/08651f21-b562-4c18-9af7-29236d0e6e1d" />




**Commands:** `addRing` → `addStripe` → cell row creation  
**View:** Innovus Layout — standard cell rows and power grid defined

After floorplanning, Innovus populates the core with **standard cell rows** and lays down the **power distribution network**. The grid pattern now visible is the result of two steps:

- **Cyan vertical lines** — standard cell row boundaries. Each row is one cell-height tall and spans the full core width. These rows define the legal placement sites for every standard cell in the design. All 143,438 cells from the Genus netlist will snap to these rows during `place_design`. The row density (~562 rows visible) matches the reported 562 standard cell rows in the post-route results.
- **Orange/brown horizontal lines** — power strap grid. These are the VDD and GND power rings and stripes laid down by `addRing` and `addStripe`. The horizontal stripes run on Metal 6 (top layer for horizontal power), and the vertical power stripes run on Metal 5. Together they form the power mesh that supplies current to every standard cell row.

At this stage the design is still **logically empty** — no logic cells are placed yet — but the physical infrastructure (rows, power, I/O pad slots) is fully committed. Any changes to core size or power topology after this point require a refloorplan.

---

## Stage 3 — Post-Placement (Pre-CTS)

<img width="1920" height="1020" alt="Screenshot 2026-06-04 103751" src="https://github.com/user-attachments/assets/a73cf87e-08fe-485e-926c-07fae3ae35ce" />




**Command:** `place_design` followed by `optDesign -preCTS -hold`  
**View:** Innovus Layout — all standard cells placed, no clock tree yet

This is the design after `place_design` completes. Every one of the **143,438 standard cells** (plus CTS buffers not yet inserted) from the Genus gate-level netlist has been legally placed into the cell rows. The colour map in this view reflects **cell density and metal layer activity**:

- **Red/dark-red regions** — high cell density areas where the CPU datapath (ALU, register file, data path mux, control logic) and peripheral register files are concentrated. These are the logic-heaviest parts of the SoC.
- **Yellow/orange regions** — medium density areas: peripheral state machines (UART, SPI, I2C, Timer, INTC), address decode logic, and bus multiplexers.
- **Green regions** — lower density areas and filler cells. The green band visible at the top and in scattered patches represents regions where the placer left whitespace for routing and CTS buffer insertion.
- **Blue border** (bottom and sides) — I/O pad ring and power ring structure.
- **Yellow markers** (left side) — I/O pad connections for the SoC's external pins (`uart_tx`, `gpio_out[7:0]`, `gpio_in[7:0]`, `clk`, `rst_n`).

The dense, relatively uniform fill across the core confirms the **64.47% core utilisation** reported in the post-route results — there is enough whitespace (the green patches) for the router to complete all nets without congestion, but not so much that the die is wastefully large.

At this stage, the **clock net is not yet distributed** — it exists as a single high-fanout wire connecting to all 63,455 scan flip-flop clock pins simultaneously. This creates a huge timing pessimism in pre-CTS analysis; the actual clock skew and hold violations will be resolved in Stage 4.

`optDesign -preCTS -hold` has already run at this point, fixing any setup violations that placement introduced and pre-sizing cells along the critical path.

---

## Stage 4 — Post-CTS (After Clock Tree Synthesis)

<img width="1920" height="1020" alt="Screenshot 2026-06-04 111447" src="https://github.com/user-attachments/assets/509aa5df-f133-486c-a87c-fc9d692a2d64" />


**Commands:** `create_clock_tree_spec` → `clockDesign` → `optDesign -postCTS -hold`  
**View:** Innovus Layout — clock tree buffers inserted and optimised

This image captures the design immediately after **Clock Tree Synthesis (CTS)**. The visual difference from Stage 3 is subtle in a full-chip view but represents a major physical change: Innovus has inserted a hierarchical tree of clock buffers and inverters to distribute the 100 MHz clock to all **63,455 scan flip-flops** (`SDFFQXL` cells) with minimal skew.

Key changes visible when comparing to Stage 3:

- **Cell count increased** — the total cell count grew from 143,438 (synthesis) to **164,285** post-CTS. The additional ~20,847 cells are the CTS buffers and hold-fix buffers inserted by `clockDesign`. Despite adding ~20K cells, the core area remains essentially flat (the −0.4% delta between synthesis wireload estimate and post-route area), confirming these are minimum-strength buffer cells.
- **Colour distribution shifted** — the top region shows a change in density pattern. CTS buffers are placed at intermediate fanout points throughout the core — the small green patches visible at the top-centre are newly inserted CTS buffers being distributed across the hierarchy.
- **Red dominance increased** — with hold-fix buffers inserted by `optDesign -postCTS -hold`, the overall cell density increased slightly, pushing more regions into the high-density red colouring.

After CTS, timing analysis becomes meaningful: the clock tree has a defined topology, skew is controlled, and setup/hold margins are now evaluated with real clock propagation delays rather than ideal-clock assumptions.

---

## Stage 5 — Post-Route (Fully Routed Design)


<img width="1920" height="1020" alt="Screenshot 2026-06-04 112057" src="https://github.com/user-attachments/assets/b82e3ebc-b8f9-4d94-af4a-8d0a40b09fb1" />



**Command:** `routeDesign` followed by `optDesign -postRoute`  
**View:** Innovus Layout — all signal nets routed across Metal 1–9

This is the **fully routed design** — every signal net in the SoC has been assigned specific metal tracks and via stacks across the 9-layer metal stack (M1–M9). This is the most complex view in the flow.

The colour encoding now represents **metal layer activity** across the full stack:

| Colour | Metal Layer | Direction | Typical Use |
|---|---|---|---|
| **Red/dark-red** | M1, M3, M5 (odd layers) | Horizontal | Local interconnect, cell internal routing |
| **Green** | M2, M4, M6 (even layers) | Vertical | Signal routing, power stripes |
| **Yellow/orange** | Via layers | — | Layer transitions between metals |
| **Cyan** | M7–M9 (upper layers) | Horizontal/Vertical | Long global routes, clock distribution |
| **Blue** | Power/Ground stripes | — | VDD/GND power mesh |

The **total post-route wire length is 7.045 metres** — confirmed in the post-route reports. This is the combined length of all signal wires across all 9 routing layers needed to connect 164,285 cells. The dense, uniform weave of horizontal and vertical lines across the core confirms that the router successfully completed all nets with no unrouted connections (0 multi-driven nets, 0 floating PG pins confirmed in `verifyConnectivity`).

The yellow I/O stubs on the left side are the SoC's external pad connections: UART, GPIO, clock, and reset signals routed to the die boundary.

`optDesign -postRoute` has run timing-driven post-route optimisation, adjusting wire sizing and buffer placement on critical paths to meet the 10 ns (100 MHz) timing constraint.

---

## Stage 6 — Post-Route Alternate View (DRC Verification Pass)

**Command:** `verifyDRC` → `verifyConnectivity` → `streamOut final.gds`  
**View:** Innovus Layout — post-route DRC verification complete

<img width="1920" height="1020" alt="Screenshot 2026-06-04 112057" src="https://github.com/user-attachments/assets/9b48d53c-71a1-4578-b059-c0f40d6a85da" />



This is a second post-route view of the same fully routed design, captured at a slightly different display scroll position (coordinates `1760.47900, 402.177` as shown in the status bar, versus `2515.637, 446.601` in Stage 5). The two views together show that the dense routing pattern is **consistent and uniform across the entire core** — there are no localised congestion hotspots, no large unrouted regions, and no DRC marker highlights (which would appear as bright white or orange violation markers if present).

The DRC verification result:

| Check | Result |
|---|---|
| `verifyDRC` | **0 violations** |
| `verifyConnectivity` | **0 unconnected nets** |
| Multi-driven nets | **0** |
| Floating PG pins | **0** |
| Combinational loops | **0** |

With 0 DRC violations confirmed, `streamOut` was called to export the final GDSII layout file (`synthesis/innovus/results/final.gds`) and DEF placement file (`synthesis/innovus/results/final.def`). The GDSII file is the tape-out deliverable — a complete, DRC-clean physical layout of the RISC-V SoC ready for submission to a silicon foundry.

---

## Flow Summary

| Stage | Image | Key Output |
|---|---|---|
| 1 — Floorplan (empty) | Empty die with core boundary | Die area defined: ~1.75 mm² core |
| 2 — Post-Floorplan | Cell rows + power grid visible | 562 rows, VDD/GND stripes on M5/M6 |
| 3 — Post-Placement (Pre-CTS) | All 143,438 cells placed | 64.47% core utilisation, 0 DRC |
| 4 — Post-CTS | Clock tree inserted | +20,847 CTS/hold buffers, skew controlled |
| 5 — Post-Route | All nets routed on M1–M9 | 7.045 m total wire length, 0 unrouted |
| 6 — DRC Verification | Clean layout exported | 0 DRC violations → `final.gds` generated |

> **Tool:** Cadence Innovus™ 21.15 on `cadence-saveetha-in`  
> **Core area:** 1.7462 mm² · **Chip area:** 2.83 mm² · **Total cells:** 164,285 · **Scan FFs:** 63,455 `SDFFQXL`  
> **Total power:** 106.55 mW · **Wire length:** 7.045 m · **DRC violations:** 0
