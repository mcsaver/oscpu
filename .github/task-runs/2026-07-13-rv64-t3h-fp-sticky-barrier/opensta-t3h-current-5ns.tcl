proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist   [file normalize [require_env T3H_STA_NETLIST]]
set out_dir   [file normalize [require_env T3H_STA_OUT_DIR]]
set std_lib   [file normalize [require_env T3H_STA_STD_LIB]]
set macro_raw [require_env T3H_STA_MACRO_LIBS]
set period_ns [require_env T3H_STA_PERIOD_NS]

if {abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3H current STA requires exact 5.0 ns period, got: $period_ns"
}

if {![file exists $netlist]} {
  error "netlist does not exist: $netlist"
}
file mkdir $out_dir

set liberty_files [list $std_lib]
foreach macro_lib [split $macro_raw ":"] {
  lappend liberty_files [file normalize $macro_lib]
}
foreach liberty_file $liberty_files {
  if {![file exists $liberty_file]} {
    error "liberty does not exist: $liberty_file"
  }
  read_liberty $liberty_file
}

read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

check_setup -verbose > [file join $out_dir opensta-current-check-setup.txt]
report_checks -path_delay max -group_path_count 40 -digits 3 \
    > [file join $out_dir opensta-current-top40.rpt]
report_tns >> [file join $out_dir opensta-current-top40.rpt]
report_wns >> [file join $out_dir opensta-current-top40.rpt]
report_power > [file join $out_dir opensta-current-power.rpt]
exit
