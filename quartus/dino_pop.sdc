create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
# Only cut the asynchronous input -> FIRST synchronizer stage paths.
# Subsequent synchronizer stages and every gameplay/video path remain timed.
set_false_path -from [get_ports {KEY[*] SW[*]}] -to [get_registers {*inputs*sync_meta*}]
# VGA drives a resistor DAC, not a source-synchronous digital receiver.
# Bound register-to-pad delay while retaining a real output timing check.
set_output_delay -clock clk50 -max 5.0 [get_ports {VGA_*}]
set_output_delay -clock clk50 -min 0.0 [get_ports {VGA_*}]
