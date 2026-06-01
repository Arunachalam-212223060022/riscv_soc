open_project /home/user/riscv_soc/vivado_project_v2/riscv_soc_v2.xpr
open_run impl_1 -name impl_1

# Timing — WNS WHS
report_timing_summary -delay_type min_max -max_paths 10 \
    -file /home/user/riscv_soc/vivado_project_v2/rpt_timing.rpt
puts "TIMING DONE"

# Utilization — LUT FF BRAM DSP
report_utilization \
    -file /home/user/riscv_soc/vivado_project_v2/rpt_util.rpt
puts "UTIL DONE"

# Power
report_power \
    -file /home/user/riscv_soc/vivado_project_v2/rpt_power.rpt
puts "POWER DONE"

# DRC
report_drc \
    -file /home/user/riscv_soc/vivado_project_v2/rpt_drc.rpt
puts "DRC DONE"

# Clock utilization
report_clock_utilization \
    -file /home/user/riscv_soc/vivado_project_v2/rpt_clock.rpt
puts "CLOCK DONE"

puts "========================"
puts "ALL REPORTS DONE"
puts "========================"
