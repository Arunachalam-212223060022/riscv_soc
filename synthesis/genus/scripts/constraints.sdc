create_clock -name clk -period 10.0 [get_ports clk]

set_clock_transition 0.1 [get_clocks clk]
set_clock_uncertainty 0.15 [get_clocks clk]

set_input_delay  2.0 -clock clk [remove_from_collection [all_inputs]  [get_ports clk]]
set_output_delay 2.0 -clock clk [all_outputs]

set_driving_cell  -lib_cell BUFX4 [all_inputs]
set_load          0.05            [all_outputs]

set_false_path -from [get_ports rst_n]
