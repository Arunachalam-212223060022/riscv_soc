# Documentation & Images

This folder stores all **visual documentation** for the project — screenshots from simulation tools, FPGA implementation views, synthesis reports, place-and-route visuals, and board photos.

The images folder is currently empty and ready for you to populate as you run each stage of the flow.

---

## Folder Map

```
docs/
└── images/
    ├── simulation/    ← Waveform screenshots and simulation console output
    ├── fpga/          ← Vivado screenshots (schematic, device view, report panels)
    ├── synthesis/     ← Cadence Genus report screenshots
    ├── pnr/           ← Cadence Innovus layout screenshots at each stage
    └── board/         ← Photos and video of the FPGA board running the demo
```

---

## What to Add

### `images/simulation/`

Simulation waveforms are the primary way to verify hardware behavior. Add:

| Suggested Filename | What to Capture |
|-------------------|----------------|
| `vcs_soc_top_pass.png` | VCS terminal showing all tests PASSED |
| `verdi_soc_top_waveform.png` | Verdi waveform: full SoC simulation — show clk, rst_n, pc, instruction, gpio signals |
| `verdi_uart_waveform.png` | Zoom into UART TX: show the serial line shifting out a byte |
| `verdi_timer_irq.png` | Show timer counting down, timeout flag asserting, irq_to_cpu going high |
| `nclaunch_waveform.png` | Cadence NCLaunch simulation waveform window |

**How to capture waveforms from Verdi:**  
1. Run VCS with `-debug_access+all` flag  
2. Open Verdi: `./simv -gui`  
3. Load signals into the waveform panel (nWave window)  
4. Zoom to the region of interest  
5. Screenshot with Print Screen or Verdi's built-in export

---

### `images/fpga/`

These show the Vivado implementation results. Add after running the full build:

| Suggested Filename | What to Capture |
|-------------------|----------------|
| `vivado_schematic.png` | Post-synthesis schematic (RTL Analysis → Open Elaborated Design → Schematic) |
| `vivado_device_view.png` | Post-implementation device view showing placement on the FPGA fabric |
| `vivado_timing_summary.png` | Timing Summary panel (shows WNS, TNS, number of failing paths) |
| `vivado_utilization.png` | Utilization Summary panel (LUT %, FF %, BRAM %) |
| `vivado_power_summary.png` | Power Report panel (on-chip power breakdown) |
| `vivado_drc_clean.png` | DRC Results showing 0 violations |

**How to open these views in Vivado:**  
After `Run Implementation`, click **Open Implemented Design**.  
Then use the menu: Reports → Timing Summary, Reports → Utilization, Reports → Power.

---

### `images/synthesis/`

Cadence Genus screenshots showing synthesis completed successfully:

| Suggested Filename | What to Capture |
|-------------------|----------------|
| `genus_synthesis_done.png` | Genus terminal showing `syn_opt` completed with no errors |
| `genus_area_report.png` | Screenshot of `reports/area.rpt` — shows total cell area and breakdown |
| `genus_timing_report.png` | Screenshot of `reports/timing.rpt` — shows WNS and critical path |
| `genus_power_report.png` | Screenshot of `reports/power.rpt` — shows leakage and dynamic power |

---

### `images/pnr/`

Innovus visual output at each stage of place and route. These are the most visually interesting screenshots:

| Suggested Filename | Stage | What to Show |
|-------------------|-------|-------------|
| `innovus_floorplan.png` | After floorPlan | Die boundary, I/O ring, power rings (thick colored lines around core) |
| `innovus_placement.png` | After place_design | Standard cells placed — the core area is filled with colored rectangles |
| `innovus_pre_cts.png` | Before clockDesign | Clock shown as a simple connection from port |
| `innovus_post_cts.png` | After clockDesign | Clock tree visible with buffer cells branching out to all flip-flops |
| `innovus_routed.png` | After routeDesign | Fully routed — all wires drawn across the chip |
| `innovus_3d.png` | Any stage | 3D view (View → 3D View) showing stacked metal layers |
| `innovus_gdsii.png` | After streamOut | Open `final.gds` in KLayout or Innovus to view the final GDSII layout |

**How to take Innovus screenshots:**  
In Innovus, use View → Visibility to control which layers are shown.  
Save image: File → Save Image (or press `Ctrl+Shift+S`).  
For GDSII viewing: Download KLayout (free, open-source) from https://klayout.de

---

### `images/board/`

Hardware photos prove the design works on real silicon. Add:

| Suggested Filename | What to Show |
|-------------------|-------------|
| `board_photo_overview.jpg` | Full board photo with Boolean board connected via USB |
| `board_gpio_leds.jpg` | Closeup of the LEDs lit up based on switch positions |
| `board_uart_terminal.png` | Screenshot of serial terminal showing "RISCV SOC OK" message |
| `board_demo_video.mp4` | Short video (or link to YouTube) showing switches → LEDs in real time |

**Serial terminal settings:**  
Baud rate: **115200** | Data bits: 8 | Stop bits: 1 | Parity: None | Flow control: None  
On Linux: `minicom -b 115200 -D /dev/ttyUSB0`  
On Windows: PuTTY → Serial → COM port → 115200 baud

---

## File Naming Convention

Use lowercase with underscores. Include the tool and stage name so files are easy to identify:

```
{tool}_{stage}_{description}.{ext}

Examples:
  vcs_sim_soc_top_pass.png
  vivado_impl_device_view.png
  genus_syn_area_report.png
  innovus_pnr_post_route.png
  board_demo_uart_output.png
```
