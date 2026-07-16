proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env FILL_LOAD_NETLIST]]
set output [file normalize [require_env FILL_LOAD_OUTPUT]]
set std_lib [file normalize [require_env FILL_LOAD_STD_LIB]]
set macro_raw [require_env FILL_LOAD_MACRO_LIBS]
set driver_pin [require_env FILL_LOAD_DRIVER_PIN]

read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

set driver [get_pins $driver_pin]
set fill_net [get_nets -of_objects $driver]
set fill_net_name [get_full_name $fill_net]
report_net -digits 9 $fill_net_name > $output
report_checks -path_delay max -rise_through $driver -group_path_count 2 -sort_by_slack \
  -fields {capacitance slew fanout input_pin net} -digits 9 >> $output
report_checks -path_delay max -fall_through $driver -group_path_count 2 -sort_by_slack \
  -fields {capacitance slew fanout input_pin net} -digits 9 >> $output
exit
