proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env DIAG_STA_NETLIST]]
set out_path [file normalize [require_env DIAG_STA_OUT]]
set std_lib [file normalize [require_env DIAG_STA_STD_LIB]]
set macro_raw [require_env DIAG_STA_MACRO_LIBS]
set start_pin_name [require_env DIAG_STA_START_PIN]

read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

set start_pin [get_pins $start_pin_name]
if {[llength $start_pin] != 1} {
  error "expected exactly one start pin, got [llength $start_pin]: $start_pin_name"
}
report_checks -from $start_pin -path_delay max -group_path_count 40 \
  -sort_by_slack -digits 9 > $out_path
report_tns -max -digits 9 >> $out_path
report_wns -max -digits 9 >> $out_path
exit
