# ============================================================
#  soc_top_demo.xdc — Boolean Board (xc7s50csga324-1)
#  Matches soc_top_demo.v ports exactly
# ============================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ── CLOCK 100 MHz ────────────────────────────────────────────
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 20.000 -name sys_clk [get_ports clk]

# ── RESET — BTN0 active-low ──────────────────────────────────
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports rst_n]
set_false_path -from [get_ports rst_n]

# ── BUTTONS ──────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports {btn[3]}]
set_false_path -from [get_ports {btn[*]}]

# ── UART ─────────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports uart_rx]

# ── LEDs [15:0] ──────────────────────────────────────────────
set_property -dict {PACKAGE_PIN G1  IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN F1  IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN F2  IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN E2  IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN E5  IOSTANDARD LVCMOS33} [get_ports {led[7]}]
set_property -dict {PACKAGE_PIN E6  IOSTANDARD LVCMOS33} [get_ports {led[8]}]
set_property -dict {PACKAGE_PIN C3  IOSTANDARD LVCMOS33} [get_ports {led[9]}]
set_property -dict {PACKAGE_PIN B2  IOSTANDARD LVCMOS33} [get_ports {led[10]}]
set_property -dict {PACKAGE_PIN A2  IOSTANDARD LVCMOS33} [get_ports {led[11]}]
set_property -dict {PACKAGE_PIN B3  IOSTANDARD LVCMOS33} [get_ports {led[12]}]
set_property -dict {PACKAGE_PIN A3  IOSTANDARD LVCMOS33} [get_ports {led[13]}]
set_property -dict {PACKAGE_PIN B4  IOSTANDARD LVCMOS33} [get_ports {led[14]}]
set_property -dict {PACKAGE_PIN A4  IOSTANDARD LVCMOS33} [get_ports {led[15]}]

# ── SWITCHES [15:0] ──────────────────────────────────────────
set_property -dict {PACKAGE_PIN V2  IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN U2  IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN U1  IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN T2  IOSTANDARD LVCMOS33} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN T1  IOSTANDARD LVCMOS33} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN R2  IOSTANDARD LVCMOS33} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN R1  IOSTANDARD LVCMOS33} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN P2  IOSTANDARD LVCMOS33} [get_ports {sw[7]}]
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports {sw[8]}]
set_property -dict {PACKAGE_PIN N2  IOSTANDARD LVCMOS33} [get_ports {sw[9]}]
set_property -dict {PACKAGE_PIN N1  IOSTANDARD LVCMOS33} [get_ports {sw[10]}]
set_property -dict {PACKAGE_PIN M2  IOSTANDARD LVCMOS33} [get_ports {sw[11]}]
set_property -dict {PACKAGE_PIN M1  IOSTANDARD LVCMOS33} [get_ports {sw[12]}]
set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {sw[13]}]
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33} [get_ports {sw[14]}]
set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33} [get_ports {sw[15]}]
set_input_delay -clock sys_clk 2.0 [get_ports {sw[*]}]

# ── RGB0 ─────────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN V6  IOSTANDARD LVCMOS33} [get_ports RGB0_R]
set_property -dict {PACKAGE_PIN V4  IOSTANDARD LVCMOS33} [get_ports RGB0_G]
set_property -dict {PACKAGE_PIN U6  IOSTANDARD LVCMOS33} [get_ports RGB0_B]

# ── RGB1 ─────────────────────────────────────────────────────
set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports RGB1_R]
set_property -dict {PACKAGE_PIN V3  IOSTANDARD LVCMOS33} [get_ports RGB1_G]
set_property -dict {PACKAGE_PIN V5  IOSTANDARD LVCMOS33} [get_ports RGB1_B]

# ── 7-SEG D0 — RIGHT (sw value) ──────────────────────────────
set_property -dict {PACKAGE_PIN H3  IOSTANDARD LVCMOS33} [get_ports {D0_AN[0]}]
set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {D0_AN[1]}]
set_property -dict {PACKAGE_PIN F3  IOSTANDARD LVCMOS33} [get_ports {D0_AN[2]}]
set_property -dict {PACKAGE_PIN E4  IOSTANDARD LVCMOS33} [get_ports {D0_AN[3]}]
set_property -dict {PACKAGE_PIN F4  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[0]}]
set_property -dict {PACKAGE_PIN J3  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[1]}]
set_property -dict {PACKAGE_PIN D2  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[2]}]
set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[3]}]
set_property -dict {PACKAGE_PIN B1  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[4]}]
set_property -dict {PACKAGE_PIN H4  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[5]}]
set_property -dict {PACKAGE_PIN D1  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[6]}]
set_property -dict {PACKAGE_PIN C1  IOSTANDARD LVCMOS33} [get_ports {D0_SEG[7]}]

# ── 7-SEG D1 — LEFT (counter) ────────────────────────────────
set_property -dict {PACKAGE_PIN D5  IOSTANDARD LVCMOS33} [get_ports {D1_AN[0]}]
set_property -dict {PACKAGE_PIN C4  IOSTANDARD LVCMOS33} [get_ports {D1_AN[1]}]
set_property -dict {PACKAGE_PIN C7  IOSTANDARD LVCMOS33} [get_ports {D1_AN[2]}]
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {D1_AN[3]}]
set_property -dict {PACKAGE_PIN D7  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[0]}]
set_property -dict {PACKAGE_PIN C5  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[1]}]
set_property -dict {PACKAGE_PIN A5  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[2]}]
set_property -dict {PACKAGE_PIN B7  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[3]}]
set_property -dict {PACKAGE_PIN A7  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[4]}]
set_property -dict {PACKAGE_PIN D6  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[5]}]
set_property -dict {PACKAGE_PIN B5  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[6]}]
set_property -dict {PACKAGE_PIN A6  IOSTANDARD LVCMOS33} [get_ports {D1_SEG[7]}]

# clock-capable pins used as outputs
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {D0_SEG[1]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {D0_AN[1]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {D0_AN[0]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {D0_SEG[5]}]

# ── OUTPUT DELAYS ─────────────────────────────────────────────
set_output_delay -clock sys_clk 2.0 [get_ports {led[*]}]
set_output_delay -clock sys_clk 2.0 [get_ports {D0_AN[*] D0_SEG[*] D1_AN[*] D1_SEG[*]}]
set_output_delay -clock sys_clk 2.0 [get_ports {RGB0_R RGB0_G RGB0_B RGB1_R RGB1_G RGB1_B}]
set_output_delay -clock sys_clk 2.0 [get_ports uart_tx]
set_input_delay  -clock sys_clk 2.0 [get_ports uart_rx]
