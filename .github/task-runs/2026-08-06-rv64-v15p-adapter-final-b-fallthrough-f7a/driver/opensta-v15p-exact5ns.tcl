proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

proc write_note {path text} {
  set stream [open $path w]
  puts $stream $text
  close $stream
}

set netlist [file normalize [require_env V15P_STA_NETLIST]]
set out_dir [file normalize [require_env V15P_STA_OUT_DIR]]
set std_lib [file normalize [require_env V15P_STA_STD_LIB]]
set macro_raw [require_env V15P_STA_MACRO_LIBS]
set period_ns [require_env V15P_STA_PERIOD_NS]
set mode [require_env V15P_STA_MODE]
set netlist_sha256 [require_env V15P_STA_NETLIST_SHA256]
set input_manifest_sha256 [require_env V15P_STA_INPUT_MANIFEST_SHA256]
set parameters_sha256 [require_env V15P_STA_PARAMETERS_SHA256]
set opensta_binary [file normalize [require_env V15P_STA_OPENSTA_BINARY]]
set opensta_binary_sha256 [require_env V15P_STA_OPENSTA_BINARY_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "V15P STA requires exact period_ns=5.0, got: $period_ns"
}
if {$mode ne "parent" && $mode ne "candidate"} {
  error "V15P STA mode must be parent or candidate, got: $mode"
}
foreach required_file [list $netlist $std_lib $opensta_binary] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
}

file mkdir $out_dir
set setup_path [file join $out_dir opensta-check-setup.txt]
set top40_path [file join $out_dir opensta-top40.rpt]
set power_path [file join $out_dir opensta-power.rpt]
set complete_path [file join $out_dir opensta-complete.txt]
foreach stale [list $setup_path $top40_path $power_path $complete_path] {
  file delete -force $stale
}

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
  error "V15P STA requires exactly four macro liberties, got: $macro_count"
}

if {[catch {
  read_verilog $netlist
  link_design NpcTop
  create_clock -name core_clock -period $period_ns [get_ports clk]
  check_setup -verbose > $setup_path
  report_checks -path_delay max -group_path_count 40 -sort_by_slack -digits 9 > $top40_path
  report_tns -max -digits 9 >> $top40_path
  report_wns -max -digits 9 >> $top40_path
  report_power > $power_path
  write_note $complete_path "status=COMPLETE
mode=$mode
period_ns=$period_ns
top=NpcTop
clock_port=clk
clock_name=core_clock
netlist=$netlist
netlist_sha256=$netlist_sha256
std_lib=$std_lib
macro_lib_count=$macro_count
input_manifest_sha256=$input_manifest_sha256
parameters_sha256=$parameters_sha256
opensta_binary=$opensta_binary
opensta_binary_sha256=$opensta_binary_sha256"
} sta_error]} {
  puts stderr "V15P_OPENSTA_STAGE_FAIL: $sta_error"
  exit 1
}
exit
