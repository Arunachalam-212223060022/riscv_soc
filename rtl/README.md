<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RISC-V SoC — RTL Source Code</title>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0d1117;
    --bg2: #161b22;
    --bg3: #1c2128;
    --border: #30363d;
    --border2: #484f58;
    --text: #e6edf3;
    --text2: #8b949e;
    --text3: #6e7681;
    --green: #3fb950;
    --green-dim: #1a3a22;
    --green-text: #7ee787;
    --blue: #58a6ff;
    --blue-dim: #0d2140;
    --blue-text: #79c0ff;
    --amber: #d29922;
    --amber-dim: #2d2008;
    --amber-text: #e3b341;
    --purple: #bc8cff;
    --purple-dim: #1f1335;
    --purple-text: #d2a8ff;
    --coral: #f78166;
    --coral-dim: #3d1a14;
    --coral-text: #ffa198;
    --teal: #39d353;
    --teal-dim: #0d2d18;
    --mono: 'IBM Plex Mono', monospace;
    --sans: 'IBM Plex Sans', sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--sans);
    font-size: 15px;
    line-height: 1.7;
    padding: 0;
  }

  /* ── HERO ── */
  .hero {
    background: var(--bg);
    border-bottom: 1px solid var(--border);
    padding: 60px 48px 40px;
    position: relative;
    overflow: hidden;
  }
  .hero::before {
    content: '';
    position: absolute;
    top: -60px; right: -80px;
    width: 420px; height: 420px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(63,185,80,0.07) 0%, transparent 70%);
    pointer-events: none;
  }
  .hero-eyebrow {
    font-family: var(--mono);
    font-size: 12px;
    color: var(--green);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    margin-bottom: 14px;
    display: flex; align-items: center; gap: 8px;
  }
  .hero-eyebrow::before {
    content: '';
    display: inline-block;
    width: 28px; height: 1px;
    background: var(--green);
  }
  .hero h1 {
    font-family: var(--mono);
    font-size: 38px;
    font-weight: 600;
    color: var(--text);
    letter-spacing: -0.02em;
    line-height: 1.15;
    margin-bottom: 16px;
  }
  .hero h1 span { color: var(--green); }
  .hero-desc {
    font-size: 16px;
    color: var(--text2);
    max-width: 560px;
    line-height: 1.7;
    margin-bottom: 28px;
  }
  .badge-row { display: flex; flex-wrap: wrap; gap: 8px; }
  .badge {
    font-family: var(--mono);
    font-size: 11px;
    padding: 4px 10px;
    border-radius: 20px;
    border: 1px solid;
    letter-spacing: 0.04em;
  }
  .badge-green  { color: var(--green-text);  border-color: var(--green);  background: var(--green-dim); }
  .badge-blue   { color: var(--blue-text);   border-color: var(--blue);   background: var(--blue-dim); }
  .badge-amber  { color: var(--amber-text);  border-color: var(--amber);  background: var(--amber-dim); }
  .badge-purple { color: var(--purple-text); border-color: var(--purple); background: var(--purple-dim); }

  /* ── LAYOUT ── */
  .container { max-width: 900px; margin: 0 auto; padding: 48px 48px; }

  /* ── SECTION HEADER ── */
  .section-label {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text3);
    text-transform: uppercase;
    letter-spacing: 0.12em;
    margin-bottom: 6px;
  }
  .section-title {
    font-family: var(--mono);
    font-size: 22px;
    font-weight: 500;
    color: var(--text);
    margin-bottom: 20px;
    padding-bottom: 12px;
    border-bottom: 1px solid var(--border);
  }
  section { margin-bottom: 56px; }

  /* ── FILE TREE ── */
  .tree {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 20px 24px;
    font-family: var(--mono);
    font-size: 13px;
    line-height: 2;
    overflow-x: auto;
  }
  .tree-item { display: flex; align-items: baseline; gap: 10px; }
  .tree-branch { color: var(--border2); user-select: none; }
  .tree-dir  { color: var(--blue-text); font-weight: 500; }
  .tree-file { color: var(--text); }
  .tree-top  { color: var(--amber-text); font-weight: 600; }
  .tree-comment { color: var(--text3); margin-left: auto; font-size: 12px; }
  .tree-spacer  { height: 4px; }

  /* ── MODULE CARDS ── */
  .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; margin-top: 4px; }
  .card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 18px 20px;
    transition: border-color 0.15s;
  }
  .card:hover { border-color: var(--border2); }
  .card-header { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
  .card-icon {
    width: 32px; height: 32px; border-radius: 6px;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--mono); font-size: 14px; font-weight: 600; flex-shrink: 0;
  }
  .icon-green  { background: var(--green-dim);  color: var(--green-text); }
  .icon-blue   { background: var(--blue-dim);   color: var(--blue-text); }
  .icon-amber  { background: var(--amber-dim);  color: var(--amber-text); }
  .icon-purple { background: var(--purple-dim); color: var(--purple-text); }
  .icon-coral  { background: var(--coral-dim);  color: var(--coral-text); }
  .card-name {
    font-family: var(--mono);
    font-size: 13px;
    font-weight: 500;
    color: var(--text);
  }
  .card-file { font-size: 11px; color: var(--text3); font-family: var(--mono); margin-top: 1px; }
  .card-desc { font-size: 13px; color: var(--text2); line-height: 1.6; }
  .card-tags { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
  .tag {
    font-family: var(--mono);
    font-size: 10px;
    padding: 2px 7px;
    border-radius: 4px;
    border: 1px solid var(--border);
    color: var(--text3);
  }

  /* ── CODE BLOCK ── */
  pre {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-left: 3px solid var(--green);
    border-radius: 0 6px 6px 0;
    padding: 16px 20px;
    font-family: var(--mono);
    font-size: 12.5px;
    line-height: 1.8;
    overflow-x: auto;
    color: var(--text2);
    margin: 16px 0;
  }
  pre .kw  { color: #f97583; }
  pre .type{ color: #79b8ff; }
  pre .str { color: var(--green-text); }
  pre .cmt { color: var(--text3); }
  pre .num { color: var(--amber-text); }
  pre .sig { color: var(--purple-text); }

  /* ── ADDRESS MAP TABLE ── */
  .addr-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    font-family: var(--mono);
    margin-top: 12px;
  }
  .addr-table thead tr { border-bottom: 1px solid var(--border2); }
  .addr-table th {
    text-align: left;
    padding: 8px 12px;
    color: var(--text3);
    font-size: 11px;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    font-weight: 400;
  }
  .addr-table td { padding: 9px 12px; border-bottom: 1px solid var(--border); color: var(--text2); }
  .addr-table tr:last-child td { border-bottom: none; }
  .addr-table .addr { color: var(--green-text); }
  .addr-table .mod  { color: var(--blue-text); font-weight: 500; }
  .addr-table .size { color: var(--amber-text); }
  .addr-table tr:hover td { background: var(--bg3); }

  /* ── REGISTER TABLE ── */
  .reg-table { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 12px; }
  .reg-table th {
    text-align: left; padding: 7px 12px;
    border-bottom: 1px solid var(--border2);
    color: var(--text3); font-size: 11px;
    text-transform: uppercase; letter-spacing: 0.06em; font-weight: 400;
    font-family: var(--mono);
  }
  .reg-table td { padding: 8px 12px; border-bottom: 1px solid var(--border); color: var(--text2); font-size: 13px; }
  .reg-table tr:last-child td { border-bottom: none; }
  .reg-table .offset { color: var(--green-text); font-family: var(--mono); }
  .reg-table .name   { color: var(--amber-text); font-family: var(--mono); font-weight: 500; }
  .reg-table .rw     { color: var(--purple-text); font-family: var(--mono); font-size: 11px; }

  .reg-wrap {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    overflow: hidden;
    margin-top: 16px;
  }
  .reg-wrap + .reg-wrap { margin-top: 16px; }
  .reg-label {
    padding: 9px 14px;
    font-family: var(--mono);
    font-size: 12px;
    font-weight: 500;
    border-bottom: 1px solid var(--border);
    display: flex; align-items: center; gap: 8px;
  }
  .reg-label.uart  { color: var(--blue-text);   background: var(--blue-dim); }
  .reg-label.gpio  { color: var(--green-text);  background: var(--green-dim); }
  .reg-label.timer { color: var(--amber-text);  background: var(--amber-dim); }
  .reg-label.intc  { color: var(--purple-text); background: var(--purple-dim); }
  .reg-label.spi   { color: var(--coral-text);  background: var(--coral-dim); }
  .reg-label.i2c   { color: var(--amber-text);  background: var(--amber-dim); }

  /* ── ISA GRID ── */
  .isa-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
  .isa-card {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 14px 16px;
  }
  .isa-card h4 {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--text3);
    text-transform: uppercase;
    letter-spacing: 0.1em;
    margin-bottom: 8px;
  }
  .isa-pills { display: flex; flex-wrap: wrap; gap: 5px; }
  .isa-pill {
    font-family: var(--mono);
    font-size: 11px;
    padding: 3px 8px;
    border-radius: 4px;
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text);
  }

  /* ── CALLOUT ── */
  .callout {
    display: flex; gap: 14px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-left: 3px solid;
    border-radius: 0 8px 8px 0;
    padding: 14px 18px;
    margin: 16px 0;
    font-size: 14px;
    color: var(--text2);
    line-height: 1.6;
  }
  .callout-info   { border-left-color: var(--blue); }
  .callout-warn   { border-left-color: var(--amber); }
  .callout-icon { font-size: 16px; flex-shrink: 0; margin-top: 1px; }

  /* ── SIGNAL TABLE ── */
  .sig-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .sig-box {
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    overflow: hidden;
  }
  .sig-box-header {
    padding: 8px 14px;
    font-family: var(--mono);
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    border-bottom: 1px solid var(--border);
  }
  .sig-box-header.in  { color: var(--green-text);  background: var(--green-dim); }
  .sig-box-header.out { color: var(--coral-text);  background: var(--coral-dim); }
  .sig-row {
    display: flex; justify-content: space-between; align-items: baseline;
    padding: 7px 14px;
    border-bottom: 1px solid var(--border);
    font-size: 13px;
  }
  .sig-row:last-child { border-bottom: none; }
  .sig-name { font-family: var(--mono); color: var(--text); font-size: 12px; }
  .sig-desc { color: var(--text3); font-size: 12px; text-align: right; max-width: 55%; }

  /* ── DIVIDER ── */
  .divider { border: none; border-top: 1px solid var(--border); margin: 48px 0; }

  /* ── PIPELINE FLOW ── */
  .pipeline {
    display: flex; align-items: center; gap: 0;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 8px;
    overflow: hidden;
    margin-top: 12px;
  }
  .pipe-stage {
    flex: 1; padding: 14px 10px; text-align: center;
    border-right: 1px solid var(--border);
    font-size: 12px;
  }
  .pipe-stage:last-child { border-right: none; }
  .pipe-stage-name { font-family: var(--mono); font-weight: 500; color: var(--text); font-size: 13px; }
  .pipe-stage-sub  { font-size: 11px; color: var(--text3); margin-top: 4px; }

  footer {
    border-top: 1px solid var(--border);
    padding: 28px 48px;
    font-family: var(--mono);
    font-size: 12px;
    color: var(--text3);
    display: flex; justify-content: space-between; align-items: center;
    flex-wrap: wrap; gap: 12px;
  }
  footer a { color: var(--green); text-decoration: none; }
  footer a:hover { text-decoration: underline; }

  h2 { font-family: var(--mono); font-size: 18px; font-weight: 500; color: var(--text); margin-bottom: 6px; }
  h3 { font-family: var(--sans); font-size: 15px; font-weight: 500; color: var(--text); margin: 20px 0 10px; }
  p  { color: var(--text2); margin-bottom: 12px; }
  code {
    font-family: var(--mono); font-size: 12px;
    background: var(--bg3); border: 1px solid var(--border);
    border-radius: 4px; padding: 1px 6px; color: var(--green-text);
  }
  strong { color: var(--text); font-weight: 500; }
</style>
</head>
<body>

<!-- ──────────────────────── HERO ──────────────────────── -->
<div class="hero">
  <div class="hero-eyebrow">RTL Source Code</div>
  <h1>RISC-V <span>SoC</span></h1>
  <p class="hero-desc">
    A complete 32-bit RISC-V processor (RV32I) implemented in synthesisable Verilog — 
    CPU core, memories, and seven peripherals wired together into a single System-on-Chip.
  </p>
  <div class="badge-row">
    <span class="badge badge-green">RV32I — 37 instructions</span>
    <span class="badge badge-blue">100 MHz target clock</span>
    <span class="badge badge-amber">16 KB memory (8 KB IMEM + 8 KB DMEM)</span>
    <span class="badge badge-purple">7 peripherals</span>
  </div>
</div>

<div class="container">

  <!-- ──────────────────────── FILE TREE ──────────────────────── -->
  <section>
    <div class="section-label">Project layout</div>
    <div class="section-title">Repository structure</div>
    <p>Every file here describes a real hardware module that gets synthesised into gates.</p>

    <div class="callout callout-info">
      <span class="callout-icon">ℹ</span>
      <div>
        Two RTL variants exist. <code>rtl/</code> uses SystemVerilog <code>logic</code> — works with Vivado and VCS/Verdi.
        <code>synthesis/genus/rtl/</code> replaces <code>logic</code> with <code>wire</code>, required for Cadence Genus and NCLaunch.
      </div>
    </div>

    <div class="tree">
      <div class="tree-item"><span class="tree-top">soc_top.v</span><span class="tree-comment">← whole SoC: CPU + memories + peripherals</span></div>
      <div class="tree-item"><span class="tree-top">soc_top_demo.v</span><span class="tree-comment">← same SoC, FPGA demo wiring</span></div>
      <div class="tree-spacer"></div>
      <div class="tree-item"><span class="tree-dir">cpu/</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">cpu_top.v</span><span class="tree-comment">connects all 6 sub-modules</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">pc.v</span><span class="tree-comment">program counter</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">regfile.v</span><span class="tree-comment">32 × 32-bit register file</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">immgen.v</span><span class="tree-comment">immediate value extractor</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">control.v</span><span class="tree-comment">instruction decoder → control signals</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">alu_ctrl.v</span><span class="tree-comment">picks which ALU operation to run</span></div>
      <div class="tree-item"><span class="tree-branch">└──</span><span class="tree-file">alu.v</span><span class="tree-comment">does the actual math and logic</span></div>
      <div class="tree-spacer"></div>
      <div class="tree-item"><span class="tree-dir">memory/</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">imem.v</span><span class="tree-comment">instruction memory (8 KB, read-only)</span></div>
      <div class="tree-item"><span class="tree-branch">└──</span><span class="tree-file">dmem.v</span><span class="tree-comment">data memory (8 KB, read-write)</span></div>
      <div class="tree-spacer"></div>
      <div class="tree-item"><span class="tree-dir">peripheral/</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">uart.v</span><span class="tree-comment">serial TX/RX (115200 default)</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">gpio.v</span><span class="tree-comment">8 LEDs + 8 switches</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">timer.v</span><span class="tree-comment">countdown timer with interrupt</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">intc.v</span><span class="tree-comment">interrupt controller (4 sources)</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">spi.v</span><span class="tree-comment">SPI master</span></div>
      <div class="tree-item"><span class="tree-branch">├──</span><span class="tree-file">i2c.v</span><span class="tree-comment">I2C master</span></div>
      <div class="tree-item"><span class="tree-branch">└──</span><span class="tree-file">seg7_ctrl.v</span><span class="tree-comment">7-segment display driver</span></div>
    </div>
  </section>

  <!-- ──────────────────────── SOC TOP ──────────────────────── -->
  <section>
    <div class="section-label">Top level</div>
    <div class="section-title">soc_top.v — the glue file</div>
    <p>
      This file contains almost no logic itself. Its job is to <strong>instantiate every other module and wire them together</strong>.
      Think of it as a circuit board: it defines what chips are present and how they connect.
    </p>

    <h3>Power-on reset    <p>
      After power-up, the SoC holds everything in reset for <strong>256 clock cycles</strong>
      before the CPU starts. This guarantees all registers initialise to known values.
    </p>
<pre><span class="kw">reg</span> [<span class="num">7</span>:<span class="num">0</span>] por_cnt;
<span class="kw">wire</span> rst_n_int = por_cnt[<span class="num">7</span>] &amp; rst_n;   <span class="cmt">// CPU only runs when POR is done AND external reset released</span>
<span class="kw">always</span> @(<span class="kw">posedge</span> clk)
    <span class="kw">if</span> (!por_cnt[<span class="num">7</span>]) por_cnt &lt;= por_cnt + <span class="num">1</span>;</pre>

    <h3>Memory-mapped I/O — address map</h3>
    <p>
      The CPU talks to every peripheral by reading/writing specific memory addresses — no special CPU instructions needed.
      A small combinational decoder checks the address and routes each access to the right module.
    </p>

    <div style="background: var(--bg2); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; margin-top: 8px;">
      <table class="addr-table">
        <thead>
          <tr>
            <th>Address</th>
            <th>Module</th>
            <th>Size</th>
            <th>What it is</th>
          </tr>
        </thead>
        <tbody>
          <tr><td class="addr">0x0000_0000</td><td class="mod">IMEM</td><td class="size">8 KB</td><td>Program code (CPU fetches from here)</td></tr>
          <tr><td class="addr">0x0000_2000</td><td class="mod">DMEM</td><td class="size">8 KB</td><td>Variables, stack, heap</td></tr>
          <tr><td class="addr">0x1000_0000</td><td class="mod">UART</td><td class="size">16 B</td><td>Serial port registers</td></tr>
          <tr><td class="addr">0x2000_0000</td><td class="mod">GPIO</td><td class="size">16 B</td><td>LED and switch registers</td></tr>
          <tr><td class="addr">0x2000_0100</td><td class="mod">Seg7</td><td class="size">4 B</td><td>7-segment display register</td></tr>
          <tr><td class="addr">0x3000_0000</td><td class="mod">Timer</td><td class="size">16 B</td><td>Countdown timer</td></tr>
          <tr><td class="addr">0x4000_0000</td><td class="mod">INTC</td><td class="size">16 B</td><td>Interrupt controller</td></tr>
          <tr><td class="addr">0x5000_0000</td><td class="mod">SPI</td><td class="size">16 B</td><td>SPI master registers</td></tr>
          <tr><td class="addr">0x6000_0000</td><td class="mod">I2C</td><td class="size">16 B</td><td>I2C master registers</td></tr>
        </tbody>
      </table>
    </div>

    <h3>How the read-back mux works</h3>
    <p>
      Only one peripheral can drive the data bus at a time. The top-level file implements a priority chain —
      whichever peripheral is selected gets its data forwarded to the CPU:
    </p>
<pre>assign dbus_rdata = dmem_sel  ? dmem_rdata  :
                    uart_sel  ? uart_rdata  :
                    gpio_sel  ? gpio_rdata  :
                    timer_sel ? timer_rdata :
                    intc_sel  ? intc_rdata  :
                    spi_sel   ? spi_rdata   :
                    i2c_sel   ? i2c_rdata   :
                    seg7_sel  ? seg7_rdata  :
                                <span class="num">32'h0</span>;       <span class="cmt">// returns 0 if nothing selected</span></pre>
  </section>

  <!-- ──────────────────────── CPU ──────────────────────── -->
  <section>
    <div class="section-label">CPU core</div>
    <div class="section-title">cpu/ — six modules, one processor</div>
    <p>
      The CPU is split into six cooperating modules. <code>cpu_top.v</code> is a structural wrapper
      that wires them together — it contains no logic of its own.
    </p>

    <div class="pipeline">
      <div class="pipe-stage">
        <div class="pipe-stage-name">PC</div>
        <div class="pipe-stage-sub">pc.v<br>fetch addr</div>
      </div>
      <div class="pipe-stage">
        <div class="pipe-stage-name">IMEM</div>
        <div class="pipe-stage-sub">imem.v<br>instruction bits</div>
      </div>
      <div class="pipe-stage">
        <div class="pipe-stage-name">Decode</div>
        <div class="pipe-stage-sub">control.v<br>immgen.v</div>
      </div>
      <div class="pipe-stage">
        <div class="pipe-stage-name">RegFile</div>
        <div class="pipe-stage-sub">regfile.v<br>rs1 / rs2</div>
      </div>
      <div class="pipe-stage">
        <div class="pipe-stage-name">ALU</div>
        <div class="pipe-stage-sub">alu.v<br>alu_ctrl.v</div>
      </div>
      <div class="pipe-stage">
        <div class="pipe-stage-name">Writeback</div>
        <div class="pipe-stage-sub">DMEM or<br>result → rd</div>
      </div>
    </div>

    <div class="cards" style="margin-top: 20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-blue">PC</div>
          <div>
            <div class="card-name">Program Counter</div>
            <div class="card-file">cpu/pc.v</div>
          </div>
        </div>
        <p class="card-desc">
          A single 32-bit register that holds the address of the <em>current</em> instruction.
          Resets to <code>0x0</code>. Every clock cycle it updates to the next address
          (PC+4, branch target, or jump target) as decided by <code>cpu_top</code>.
        </p>
        <div class="card-tags"><span class="tag">32-bit reg</span><span class="tag">sync reset</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-green">RF</div>
          <div>
            <div class="card-name">Register File</div>
            <div class="card-file">cpu/regfile.v</div>
          </div>
        </div>
        <p class="card-desc">
          32 general-purpose 32-bit registers (x0–x31). Two registers can be read
          simultaneously (combinational, instant). Writes happen on the clock edge.
          <strong>x0 is hardwired to zero</strong> — reads always return 0, writes are silently ignored.
        </p>
        <div class="card-tags"><span class="tag">2-port read</span><span class="tag">x0 = 0 hardwired</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-amber">IG</div>
          <div>
            <div class="card-name">Immediate Generator</div>
            <div class="card-file">cpu/immgen.v</div>
          </div>
        </div>
        <p class="card-desc">
          Many instructions embed a constant (immediate) value inside their 32 bits, 
          but in five different scrambled formats. This module extracts that constant
          and sign-extends it to 32 bits for all five RISC-V instruction formats (I, S, B, U, J).
        </p>
        <div class="card-tags"><span class="tag">I/S/B/U/J types</span><span class="tag">combinational</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-purple">CU</div>
          <div>
            <div class="card-name">Control Unit</div>
            <div class="card-file">cpu/control.v</div>
          </div>
        </div>
        <p class="card-desc">
          The "brain" — reads the 7-bit opcode and fires 11 control signals that tell
          every other module what to do. Purely combinational; no registers, no clock.
          One big <code>case</code> statement covering all 9 instruction types.
        </p>
        <div class="card-tags"><span class="tag">11 control signals</span><span class="tag">combinational</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-coral">AC</div>
          <div>
            <div class="card-name">ALU Control</div>
            <div class="card-file">cpu/alu_ctrl.v</div>
          </div>
        </div>
        <p class="card-desc">
          A translator between the Control Unit's 2-bit <code>alu_op</code> and the ALU's
          4-bit <code>alu_sel</code>. Uses <code>funct3</code> and <code>funct7</code> bits
          to distinguish, e.g., ADD from SUB (same opcode, different <code>funct7</code> bit).
        </p>
        <div class="card-tags"><span class="tag">4-bit alu_sel</span><span class="tag">funct3/7 decode</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-green">∑</div>
          <div>
            <div class="card-name">ALU</div>
            <div class="card-file">cpu/alu.v</div>
          </div>
        </div>
        <p class="card-desc">
          Performs 10 operations: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU.
          Also produces a <code>zero</code> flag (result == 0) used by branch instructions
          to decide whether to take the branch.
        </p>
        <div class="card-tags"><span class="tag">10 operations</span><span class="tag">zero flag</span></div>
      </div>
    </div>

    <h3>PC update logic</h3>
    <p>Each cycle, <code>cpu_top</code> chooses the next PC from four candidates:</p>
<pre>assign pc_next = jalr         ? (rs1_data + imm) &amp; ~<span class="num">32'h1</span>  <span class="cmt">// JALR: reg + offset, clear bit 0</span>
               : jal          ? pc + imm                    <span class="cmt">// JAL: PC-relative jump</span>
               : branch_taken ? pc + imm                    <span class="cmt">// branch: PC-relative offset</span>
               :                pc + <span class="num">32'd4</span>;                 <span class="cmt">// normal: next instruction</span></pre>

    <h3>Store byte-enables</h3>
    <p>
      The CPU can write 1, 2, or 4 bytes at a time without disturbing the other bytes in the same 32-bit word.
      The 4-bit write-enable (<code>dbus_we</code>) is set according to the store instruction:
    </p>
<pre>SB  funct3=000  →  4'b0001 shifted to correct byte lane  <span class="cmt">// 1 byte</span>
SH  funct3=001  →  4'b0011 shifted to correct byte lane  <span class="cmt">// 2 bytes</span>
SW  funct3=010  →  4'b1111                               <span class="cmt">// all 4 bytes</span></pre>
  </section>

  <!-- ──────────────────────── MEMORY ──────────────────────── -->
  <section>
    <div class="section-label">Memory subsystem</div>
    <div class="section-title">memory/ — instruction and data storage</div>

    <div class="cards">
      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-blue">IM</div>
          <div>
            <div class="card-name">Instruction Memory</div>
            <div class="card-file">memory/imem.v</div>
          </div>
        </div>
        <p class="card-desc">
          8 KB read-only program store (2048 × 32-bit words). The CPU fetches one instruction per cycle.
          Reads are combinational — zero wait states. The current program is hardcoded as a 
          <code>case</code> statement encoding 21 instructions (a UART "RISC-V SOC OK" boot message).
        </p>
        <div class="card-tags"><span class="tag">8 KB</span><span class="tag">combinational read</span><span class="tag">word-addressed</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-amber">DM</div>
          <div>
            <div class="card-name">Data Memory</div>
            <div class="card-file">memory/dmem.v</div>
          </div>
        </div>
        <p class="card-desc">
          8 KB read-write memory for variables, the stack, and heap. Reads are combinational;
          writes are synchronous (clocked) with 4-bit byte-lane enables so individual bytes
          can be written without touching neighbouring bytes.
        </p>
        <div class="card-tags"><span class="tag">8 KB</span><span class="tag">byte-lane writes</span><span class="tag">sync write</span></div>
      </div>
    </div>
<pre><span class="cmt">// Byte-lane write — only selected bytes change</span>
<span class="kw">always</span> @(<span class="kw">posedge</span> clk) <span class="kw">begin</span>
    <span class="kw">if</span> (we[<span class="num">0</span>]) mem[idx][<span class="num">7</span>:<span class="num">0</span>]   &lt;= wdata[<span class="num">7</span>:<span class="num">0</span>];
    <span class="kw">if</span> (we[<span class="num">1</span>]) mem[idx][<span class="num">15</span>:<span class="num">8</span>]  &lt;= wdata[<span class="num">15</span>:<span class="num">8</span>];
    <span class="kw">if</span> (we[<span class="num">2</span>]) mem[idx][<span class="num">23</span>:<span class="num">16</span>] &lt;= wdata[<span class="num">23</span>:<span class="num">16</span>];
    <span class="kw">if</span> (we[<span class="num">3</span>]) mem[idx][<span class="num">31</span>:<span class="num">24</span>] &lt;= wdata[<span class="num">31</span>:<span class="num">24</span>];
<span class="kw">end</span></pre>
  </section>

  <!-- ──────────────────────── PERIPHERALS ──────────────────────── -->
  <section>
    <div class="section-label">Peripherals</div>
    <div class="section-title">peripheral/ — seven hardware interfaces</div>
    <p>
      All peripherals share the same simple bus interface: a 4-bit register <code>addr</code>,
      32-bit <code>wdata</code>/<code>rdata</code>, and a <code>we</code> write-enable.
      The SoC top level activates the right <code>we</code> based on the address decoder.
    </p>

    <!-- UART -->
    <div class="reg-wrap">
      <div class="reg-label uart">uart.v — serial communication (UART)</div>
      <table class="reg-table">
        <thead><tr><th>Offset</th><th>Name</th><th>R/W</th><th>What it does</th></tr></thead>
        <tbody>
          <tr><td class="offset">0x0</td><td class="name">TX_DATA</td><td class="rw">W</td><td>Write a byte here to send it over the serial line</td></tr>
          <tr><td class="offset">0x4</td><td class="name">STATUS</td><td class="rw">R</td><td>Bit 0 = <code>tx_busy</code>. If 1, wait before writing another byte</td></tr>
          <tr><td class="offset">0x8</td><td class="name">RX_DATA</td><td class="rw">R</td><td>Bits [7:0] = received byte. Bit [8] = 1 when a new byte arrived</td></tr>
          <tr><td class="offset">0xC</td><td class="name">BAUD_DIV</td><td class="rw">R/W</td><td>Sets baud rate. Default 868 → 115200 baud at 100 MHz</td></tr>
        </tbody>
      </table>
    </div>
    <p style="margin-top: 10px; font-size: 13px;">
      <strong>How TX works:</strong> writing to TX_DATA loads a byte into a 10-bit shift register and clocks it out LSB-first
      with a start bit (0) and stop bit (1). <strong>How RX works:</strong> detects the falling edge (start bit), waits half a bit-period,
      then samples at the middle of each bit window for noise immunity. The RX line goes through a 2-stage synchroniser 
      to prevent metastability. The UART fires an <code>irq</code> when a byte is received.
    </p>

    <!-- GPIO -->
    <div class="reg-wrap">
      <div class="reg-label gpio">gpio.v — LEDs and switches</div>
      <table class="reg-table">
        <thead><tr><th>Offset</th><th>Name</th><th>R/W</th><th>What it does</th></tr></thead>
        <tbody>
          <tr><td class="offset">0x0</td><td class="name">OUTPUT</td><td class="rw">W</td><td>Drives <code>gpio_out[7:0]</code> — the 8 LED pins. Write <code>0xFF</code> to turn all on</td></tr>
          <tr><td class="offset">0x4</td><td class="name">INPUT</td><td class="rw">R</td><td>Reads <code>gpio_in[7:0]</code> — the 8 slide switch positions</td></tr>
        </tbody>
      </table>
    </div>

    <!-- Timer -->
    <div class="reg-wrap">
      <div class="reg-label timer">timer.v — countdown timer</div>
      <table class="reg-table">
        <thead><tr><th>Offset</th><th>Name</th><th>R/W</th><th>What it does</th></tr></thead>
        <tbody>
          <tr><td class="offset">0x0</td><td class="name">LOAD</td><td class="rw">R/W</td><td>Value to count down from. Writing here also resets the counter immediately</td></tr>
          <tr><td class="offset">0x4</td><td class="name">COUNT</td><td class="rw">R</td><td>Current counter value (decreases each clock when enabled)</td></tr>
          <tr><td class="offset">0x8</td><td class="name">CTRL</td><td class="rw">R/W</td><td>Bit 0 = enable. Bit 1 = auto-reload (1 = restart after timeout, 0 = one-shot)</td></tr>
          <tr><td class="offset">0xC</td><td class="name">STATUS</td><td class="rw">R/W</td><td>Bit 0 = timeout flag. Write 1 to clear it</td></tr>
        </tbody>
      </table>
    </div>

    <!-- INTC -->
    <div class="reg-wrap">
      <div class="reg-label intc">intc.v — interrupt controller</div>
      <table class="reg-table">
        <thead><tr><th>Offset</th><th>Name</th><th>R/W</th><th>What it does</th></tr></thead>
        <tbody>
          <tr><td class="offset">0x0</td><td class="name">PENDING</td><td class="rw">R</td><td>Which interrupts have fired (bits 0–3: UART, Timer, SPI, I2C)</td></tr>
          <tr><td class="offset">0x4</td><td class="name">ENABLE</td><td class="rw">R/W</td><td>Which interrupts are allowed to reach the CPU (mask register)</td></tr>
          <tr><td class="offset">0x8</td><td class="name">CLEAR</td><td class="rw">W</td><td>Write 1 to a bit to acknowledge and clear that interrupt</td></tr>
          <tr><td class="offset">0xC</td><td class="name">PRIORITY</td><td class="rw">R/W</td><td>Mark interrupt as high (1) or low (0) priority</td></tr>
        </tbody>
      </table>
    </div>
    <p style="font-size: 13px; margin-top: 10px;">
      <strong>Typical software usage:</strong> (1) read PENDING to see which interrupt fired,
      (2) service that peripheral, (3) write to CLEAR to acknowledge.
      High-priority interrupts always reach the CPU; low-priority ones only do when enabled.
    </p>

    <!-- SPI + I2C -->
    <div class="cards" style="margin-top: 16px;">
      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-coral">SP</div>
          <div>
            <div class="card-name">SPI Master</div>
            <div class="card-file">peripheral/spi.v</div>
          </div>
        </div>
        <p class="card-desc">
          Drives SCK (clock), MOSI (data out), and CS_N (chip select) to talk to
          sensors, displays, and flash memory. Write a byte to TX_DATA to start a
          transfer; poll STATUS until not busy; read RX_DATA for the response.
          Generates an <code>irq</code> on transfer complete.
        </p>
        <div class="card-tags"><span class="tag">SCK/MOSI/MISO/CS_N</span><span class="tag">irq on done</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-amber">I2</div>
          <div>
            <div class="card-name">I2C Master</div>
            <div class="card-file">peripheral/i2c.v</div>
          </div>
        </div>
        <p class="card-desc">
          Two-wire protocol (SDA data + SCL clock) for short-range sensors like
          temperature probes and accelerometers. Implements START, address+R/W,
          data byte, ACK, and STOP sequences. Uses open-drain output-enable signals
          rather than driving the bus directly.
        </p>
        <div class="card-tags"><span class="tag">SDA/SCL OE</span><span class="tag">9-state FSM</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-green">7S</div>
          <div>
            <div class="card-name">7-Segment Driver</div>
            <div class="card-file">peripheral/seg7_ctrl.v</div>
          </div>
        </div>
        <p class="card-desc">
          Drives two 4-digit 7-segment displays (8 digits total) on the Boolean FPGA board.
          Uses <em>multiplexing</em> — each digit is lit briefly in turn at ~1 kHz.
          Human eyes can't see the flicker, so all 8 digits appear on simultaneously.
          Write a 32-bit hex value to display it directly.
        </p>
        <div class="card-tags"><span class="tag">8 digits</span><span class="tag">multiplexed</span><span class="tag">~1 kHz scan</span></div>
      </div>
    </div>
  </section>

  <!-- ──────────────────────── ISA ──────────────────────── -->
  <section>
    <div class="section-label">Instruction set</div>
    <div class="section-title">RV32I — 37 instructions supported</div>
    <p>This implements the complete <strong>RV32I base integer ISA</strong>.</p>

    <div class="isa-grid">
      <div class="isa-card">
        <h4>Arithmetic</h4>
        <div class="isa-pills">
          <span class="isa-pill">ADD</span><span class="isa-pill">ADDI</span><span class="isa-pill">SUB</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Logical</h4>
        <div class="isa-pills">
          <span class="isa-pill">AND</span><span class="isa-pill">ANDI</span>
          <span class="isa-pill">OR</span><span class="isa-pill">ORI</span>
          <span class="isa-pill">XOR</span><span class="isa-pill">XORI</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Shift</h4>
        <div class="isa-pills">
          <span class="isa-pill">SLL</span><span class="isa-pill">SLLI</span>
          <span class="isa-pill">SRL</span><span class="isa-pill">SRLI</span>
          <span class="isa-pill">SRA</span><span class="isa-pill">SRAI</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Compare</h4>
        <div class="isa-pills">
          <span class="isa-pill">SLT</span><span class="isa-pill">SLTI</span>
          <span class="isa-pill">SLTU</span><span class="isa-pill">SLTIU</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Load</h4>
        <div class="isa-pills">
          <span class="isa-pill">LB</span><span class="isa-pill">LH</span><span class="isa-pill">LW</span>
          <span class="isa-pill">LBU</span><span class="isa-pill">LHU</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Store</h4>
        <div class="isa-pills">
          <span class="isa-pill">SB</span><span class="isa-pill">SH</span><span class="isa-pill">SW</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Branch</h4>
        <div class="isa-pills">
          <span class="isa-pill">BEQ</span><span class="isa-pill">BNE</span>
          <span class="isa-pill">BLT</span><span class="isa-pill">BGE</span>
          <span class="isa-pill">BLTU</span><span class="isa-pill">BGEU</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Jump</h4>
        <div class="isa-pills">
          <span class="isa-pill">JAL</span><span class="isa-pill">JALR</span>
        </div>
      </div>
      <div class="isa-card">
        <h4>Upper immediate</h4>
        <div class="isa-pills">
          <span class="isa-pill">LUI</span><span class="isa-pill">AUIPC</span>
        </div>
      </div>
    </div>
  </section>

  <!-- ──────────────────────── SIGNALS ──────────────────────── -->
  <section>
    <div class="section-label">Top-level ports</div>
    <div class="section-title">soc_top.v — external pin list</div>
    <div class="sig-grid">
      <div class="sig-box">
        <div class="sig-box-header in">Inputs</div>
        <div class="sig-row"><span class="sig-name">clk</span><span class="sig-desc">system clock</span></div>
        <div class="sig-row"><span class="sig-name">rst_n</span><span class="sig-desc">active-low reset</span></div>
        <div class="sig-row"><span class="sig-name">uart_rx</span><span class="sig-desc">serial data in</span></div>
        <div class="sig-row"><span class="sig-name">gpio_in [7:0]</span><span class="sig-desc">slide switches</span></div>
        <div class="sig-row"><span class="sig-name">spi_miso</span><span class="sig-desc">SPI data in</span></div>
        <div class="sig-row"><span class="sig-name">i2c_sda_in</span><span class="sig-desc">I2C data in</span></div>
      </div>
      <div class="sig-box">
        <div class="sig-box-header out">Outputs</div>
        <div class="sig-row"><span class="sig-name">uart_tx</span><span class="sig-desc">serial data out</span></div>
        <div class="sig-row"><span class="sig-name">gpio_out [7:0]</span><span class="sig-desc">LEDs</span></div>
        <div class="sig-row"><span class="sig-name">spi_sck / mosi / cs_n</span><span class="sig-desc">SPI bus</span></div>
        <div class="sig-row"><span class="sig-name">i2c_scl_oe / sda_oe</span><span class="sig-desc">I2C open-drain OE</span></div>
        <div class="sig-row"><span class="sig-name">D0_AN / D0_SEG</span><span class="sig-desc">display 0 (4 digits)</span></div>
        <div class="sig-row"><span class="sig-name">D1_AN / D1_SEG</span><span class="sig-desc">display 1 (4 digits)</span></div>
      </div>
    </div>
  </section>

  <!-- ──────────────────────── SYNTHESIS ──────────────────────── -->
  <section>
    <div class="section-label">Synthesis & simulation</div>
    <div class="section-title">Timing constraints & testbench</div>

    <div class="callout callout-warn">
      <span class="callout-icon">⚡</span>
      <div>
        The SDC constraints target a <strong>100 MHz clock</strong> (10 ns period) with 0.1 ns transition,
        0.15 ns uncertainty, 2 ns I/O delays. <code>rst_n</code> is set as a false path — it's asynchronous.
      </div>
    </div>

    <div class="cards" style="margin-top: 4px;">
      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-blue">TB</div>
          <div>
            <div class="card-name">Testbench</div>
            <div class="card-file">tb/tb_soc_top.sv</div>
          </div>
        </div>
        <p class="card-desc">
          SystemVerilog testbench with a 10 ns clock, 500 000-cycle timeout, and structured
          <code>check(name, condition)</code> tasks that print <code>[PASS]</code> / <code>[FAIL]</code>.
          Applies reset for 20 cycles, then waits 300 more for POR to clear before running tests.
        </p>
        <div class="card-tags"><span class="tag">10 ns clk</span><span class="tag">VCD waveform</span><span class="tag">pass/fail tasks</span></div>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-icon icon-amber">SDC</div>
          <div>
            <div class="card-name">Timing Constraints</div>
            <div class="card-file">constraints.sdc</div>
          </div>
        </div>
        <p class="card-desc">
          Standard SDC file for Cadence Genus (or compatible tools).
          Defines the 100 MHz clock, sets I/O delays to 2 ns,
          adds a driving cell model (<code>BUFX4</code>) and 0.05 pF output load.
        </p>
        <div class="card-tags"><span class="tag">100 MHz</span><span class="tag">BUFX4 drive</span><span class="tag">false path: rst_n</span></div>
      </div>
    </div>
  </section>

</div><!-- /container -->

<footer>
  <span>RISC-V SoC — RTL Source · RV32I · Verilog 2001 / SystemVerilog</span>
  <span>Arunachalam-212223060022</span>
</footer>

</body>
</html>
