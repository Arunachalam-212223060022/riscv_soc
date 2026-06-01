# ============================================================
#  vivado_riscv_soc_v2.tcl  —  Full SoC with SPI + I2C + UART RX
#  Board: Spartan-7 Boolean  xc7s50csga324-1
# ============================================================

set RISCV_DIR "/home/user/riscv_soc"
set PART      "xc7s50csga324-1"
set PROJ_DIR  "$RISCV_DIR/vivado_project_v2"

# 1. Create project
create_project riscv_soc_v2 $PROJ_DIR -part $PART -force
set_property target_language  Verilog [current_project]
set_property simulator_language Mixed [current_project]

# 2. Add RTL
read_verilog $RISCV_DIR/rtl/cpu/pc.v
read_verilog $RISCV_DIR/rtl/cpu/regfile.v
read_verilog $RISCV_DIR/rtl/cpu/alu.v
read_verilog $RISCV_DIR/rtl/cpu/alu_ctrl.v
read_verilog $RISCV_DIR/rtl/cpu/control.v
read_verilog $RISCV_DIR/rtl/cpu/immgen.v
read_verilog $RISCV_DIR/rtl/cpu/cpu_top.v
read_verilog $RISCV_DIR/rtl/memory/imem.v
read_verilog $RISCV_DIR/rtl/memory/dmem.v
read_verilog $RISCV_DIR/rtl/peripheral/uart.v
read_verilog $RISCV_DIR/rtl/peripheral/gpio.v
read_verilog $RISCV_DIR/rtl/peripheral/timer.v
read_verilog $RISCV_DIR/rtl/peripheral/intc.v
read_verilog $RISCV_DIR/rtl/peripheral/spi.v
read_verilog $RISCV_DIR/rtl/peripheral/i2c.v
read_verilog $RISCV_DIR/rtl/soc_top.v
set_property top soc_top [current_fileset]
puts "RTL loaded — 16 files"

# 3. Add testbenches
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_alu.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_regfile.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_immgen.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_control.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_uart.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_gpio.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_timer.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_intc.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_cpu_top.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_spi.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_i2c.sv
add_files -fileset sim_1 -norecurse $RISCV_DIR/tb/tb_soc_top.sv
set_property file_type SystemVerilog \
    [get_files -of_objects [get_filesets sim_1] *.sv]
set_property top         tb_soc_top     [get_filesets sim_1]
set_property top_lib     xil_defaultlib [get_filesets sim_1]
puts "Testbenches loaded — 12 files"

# 4. XDC — Spartan-7 Boolean board
set xdc_dir $PROJ_DIR/riscv_soc_v2.srcs/constrs_1/new
file mkdir $xdc_dir
set fh [open $xdc_dir/riscv_soc.xdc w]
puts $fh {# Spartan-7 Boolean Board — xc7s50csga324-1
# 12 MHz onboard oscillator
create_clock -period 83.333 -name sys_clk [get_ports clk]
set_false_path -from [get_ports rst_n]
set_input_delay  -clock sys_clk -max 2.0 [get_ports {gpio_in[*] uart_rx spi_miso i2c_sda_in}]
set_input_delay  -clock sys_clk -min 0.5 [get_ports {gpio_in[*] uart_rx spi_miso i2c_sda_in}]
set_output_delay -clock sys_clk -max 2.0 [get_ports {gpio_out[*] uart_tx spi_sck spi_mosi spi_cs_n i2c_scl_oe i2c_sda_oe}]
set_output_delay -clock sys_clk -min 0.5 [get_ports {gpio_out[*] uart_tx spi_sck spi_mosi spi_cs_n i2c_scl_oe i2c_sda_oe}]

# ── Boolean Board Pin Assignments ──────────────────────
# Clock (12 MHz)
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk]
# Reset (active low button)
set_property -dict {PACKAGE_PIN C1  IOSTANDARD LVCMOS33} [get_ports rst_n]
# UART TX/RX
set_property -dict {PACKAGE_PIN G1  IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN F1  IOSTANDARD LVCMOS33} [get_ports uart_rx]
# SPI
set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33} [get_ports spi_sck]
set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN F2  IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN E2  IOSTANDARD LVCMOS33} [get_ports spi_cs_n]
# I2C
set_property -dict {PACKAGE_PIN H1  IOSTANDARD LVCMOS33} [get_ports i2c_scl_oe]
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports i2c_sda_oe]
set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33} [get_ports i2c_sda_in]
# GPIO OUT → LEDs
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {gpio_out[0]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {gpio_out[1]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {gpio_out[2]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports {gpio_out[3]}]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {gpio_out[4]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {gpio_out[5]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {gpio_out[6]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {gpio_out[7]}]
# GPIO IN → Switches
set_property -dict {PACKAGE_PIN D1  IOSTANDARD LVCMOS33} [get_ports {gpio_in[0]}]
set_property -dict {PACKAGE_PIN E1  IOSTANDARD LVCMOS33} [get_ports {gpio_in[1]}]
set_property -dict {PACKAGE_PIN F3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[2]}]
set_property -dict {PACKAGE_PIN G3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[3]}]
set_property -dict {PACKAGE_PIN H3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[4]}]
set_property -dict {PACKAGE_PIN J3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[5]}]
set_property -dict {PACKAGE_PIN K3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[6]}]
set_property -dict {PACKAGE_PIN L3  IOSTANDARD LVCMOS33} [get_ports {gpio_in[7]}]

# Config voltage
set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
}
close $fh
add_files -fileset constrs_1 -norecurse $xdc_dir/riscv_soc.xdc
puts "XDC loaded"

# 5. Simulation settings
set_property -name {xsim.simulate.runtime}         -value {5ms}  -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# 6. Launch simulation — tb_soc_top
puts "Launching simulation..."











# 7. Synthesis
puts "Starting synthesis..."
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "SYNTHESIS FAILED"
}
open_run synth_1 -name synth_1
report_utilization    -file $PROJ_DIR/report_util.rpt
report_timing_summary -file $PROJ_DIR/report_timing.rpt -max_paths 10
puts "Synthesis done"

# 8. Implementation + bitstream
puts "Starting implementation..."
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "IMPLEMENTATION FAILED"
}
open_run impl_1 -name impl_1
report_timing_summary -file $PROJ_DIR/report_impl_timing.rpt -max_paths 10
report_utilization    -file $PROJ_DIR/report_impl_util.rpt

puts "=========================================="
puts " ALL STEPS COMPLETE"
puts " Bitstream: $PROJ_DIR/riscv_soc_v2.runs/impl_1/soc_top.bit"
puts " Util rpt : $PROJ_DIR/report_impl_util.rpt"
puts " Timing   : $PROJ_DIR/report_impl_timing.rpt"
puts "=========================================="
