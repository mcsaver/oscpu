proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env T4Q_STA_NETLIST]]
set std_lib [file normalize [require_env T4Q_STA_STD_LIB]]
set macro_raw [require_env T4Q_STA_MACRO_LIBS]
set period_ns [require_env T4Q_STA_PERIOD_NS]
set output [file normalize [require_env T4Q_STA_SETUP_PROBE_OUT]]
if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T4Q setup probe requires exact period_ns=5.0, got: $period_ns"
}
file delete -force $output
read_liberty $std_lib
set macro_count 0
foreach macro_lib [split $macro_raw ":"] {
  set normalized [file normalize $macro_lib]
  if {![file exists $normalized] || [file type $normalized] ne "file"} {
    error "macro liberty does not exist as a regular file: $normalized"
  }
  read_liberty $normalized
  incr macro_count
}
if {$macro_count != 4} {
  error "T4Q setup probe requires exactly four macro liberties, got: $macro_count"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]
check_setup -verbose > $output
exit
