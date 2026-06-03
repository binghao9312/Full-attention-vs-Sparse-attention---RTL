create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0 -clock clk [all_outputs]
