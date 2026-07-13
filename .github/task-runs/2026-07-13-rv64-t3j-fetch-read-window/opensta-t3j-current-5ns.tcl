proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

proc write_note {path text} {
  set fp [open $path w]
  puts $fp $text
  close $fp
}

set netlist [file normalize [require_env T3J_STA_NETLIST]]
set out_dir [file normalize [require_env T3J_STA_OUT_DIR]]
set std_lib [file normalize [require_env T3J_STA_STD_LIB]]
set macro_raw [require_env T3J_STA_MACRO_LIBS]
set period_ns [require_env T3J_STA_PERIOD_NS]
set netlist_sha256 [require_env T3J_STA_NETLIST_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3J current STA requires exact period_ns=5.0, got: $period_ns"
}
if {![file exists $netlist]} {
  error "netlist does not exist: $netlist"
}
if {![file exists $std_lib]} {
  error "standard liberty does not exist: $std_lib"
}
file mkdir $out_dir
set setup_path [file join $out_dir opensta-current-check-setup.txt]
set top40_path [file join $out_dir opensta-current-top40.rpt]
set power_path [file join $out_dir opensta-current-power.rpt]
set complete_path [file join $out_dir opensta-current-complete.txt]
foreach stale [list $setup_path $top40_path $power_path $complete_path] {
  file delete -force $stale
}

read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  set normalized [file normalize $macro_lib]
  if {![file exists $normalized]} {
    error "macro liberty does not exist: $normalized"
  }
  read_liberty $normalized
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

check_setup -verbose > $setup_path
report_checks -path_delay max -group_path_count 40 -digits 3 > $top40_path
report_tns >> $top40_path
report_wns >> $top40_path
report_power > $power_path
write_note $complete_path "status=COMPLETE\nperiod_ns=$period_ns\nnetlist=$netlist\nnetlist_sha256=$netlist_sha256"
exit
