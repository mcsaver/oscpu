# prepare_sdc.py supplies every scalar data input from the mapped top module.
# This avoids unsupported collection subtraction/globbing in the bundled iEDA.
if {![info exists r64_data_input_names]} {
  error "Run prepare_sdc.py to enumerate the actual mapped data inputs."
}
set clock_period 1.0
if {[info exists env(CLK_FREQ_MHZ)]} {
  set clock_period [expr 1000.0 / $::env(CLK_FREQ_MHZ)]
}
create_clock -name core_clock -period $clock_period [get_ports $r64_clock_port]
# This iEDA version disables both default polarities and both default check
# types. Spell out all four combinations so the intended 50 ps is effective.
set_clock_uncertainty -setup -rise 0.05 [get_clocks core_clock]
set_clock_uncertainty -setup -fall 0.05 [get_clocks core_clock]
set_clock_uncertainty -hold -rise 0.05 [get_clocks core_clock]
set_clock_uncertainty -hold -fall 0.05 [get_clocks core_clock]
foreach port $r64_data_input_names {
  set_input_delay -max 0.4 -clock core_clock [get_ports $port]
  set_input_delay -min 0.0 -clock core_clock [get_ports $port]
  set_input_transition 0.05 [get_ports $port]
}
foreach port $r64_data_output_names {
  set_output_delay -max 0.4 -clock core_clock [get_ports $port]
  set_output_delay -min 0.0 -clock core_clock [get_ports $port]
  set_load 0.02 [get_ports $port]
}
