set_db init_lib_search_path {./lib}
set_db init_hdl_search_path {./rtl}

read_libs slow.lib

set_db hdl_error_on_blackbox true

read_hdl cpu/pc.v
read_hdl cpu/regfile.v
read_hdl cpu/alu.v
read_hdl cpu/alu_ctrl.v
read_hdl cpu/immgen.v
read_hdl cpu/control.v
read_hdl cpu/cpu_top.v

read_hdl memory/imem.v
read_hdl memory/dmem.v

read_hdl peripheral/gpio.v
read_hdl peripheral/timer.v
read_hdl peripheral/uart.v
read_hdl peripheral/spi.v
read_hdl peripheral/i2c.v
read_hdl peripheral/intc.v
read_hdl peripheral/seg7_ctrl.v

read_hdl soc_top.v

elaborate soc_top

check_design -unresolved

read_sdc ./constraints.sdc

set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

syn_generic
syn_map
syn_opt

report_timing  > reports/timing.rpt
report_power   > reports/power.rpt
report_area    > reports/area.rpt
report_gates   > reports/gates.rpt

write_hdl      > netlist/soc_top_netlist.v
write_sdf      > netlist/soc_top.sdf
write_sdc      > netlist/soc_top.sdc

puts "Synthesis complete."
