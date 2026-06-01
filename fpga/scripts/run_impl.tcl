open_project /home/user/riscv_soc/vivado_project_v2/riscv_soc_v2.xpr
reset_run impl_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] == "100%"} {
    puts "=============================="
    puts "BITSTREAM DONE"
    puts "=============================="
} else {
    puts "FAILED"
}
