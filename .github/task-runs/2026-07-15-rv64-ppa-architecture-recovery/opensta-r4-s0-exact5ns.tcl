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

set netlist [file normalize [require_env R4_S0_STA_NETLIST]]
set out_dir [file normalize [require_env R4_S0_STA_OUT_DIR]]
set std_lib [file normalize [require_env R4_S0_STA_STD_LIB]]
set macro_raw [require_env R4_S0_STA_MACRO_LIBS]
set period_ns [require_env R4_S0_STA_PERIOD_NS]
set run_id [require_env R4_S0_STA_RUN_ID]
set netlist_sha256 [require_env R4_S0_STA_NETLIST_SHA256]
set std_lib_sha256 [require_env R4_S0_STA_STD_LIB_SHA256]
set macro_manifest_sha256 [require_env R4_S0_STA_MACRO_MANIFEST_SHA256]
set input_manifest_sha256 [require_env R4_S0_STA_INPUT_MANIFEST_SHA256]
set parameters_sha256 [require_env R4_S0_STA_PARAMETERS_SHA256]
set opensta_binary [file normalize [require_env R4_S0_STA_OPENSTA_BINARY]]
set opensta_binary_sha256 [require_env R4_S0_STA_OPENSTA_BINARY_SHA256]
set synth_audit_summary [file normalize [require_env R4_S0_STA_SYNTH_AUDIT_SUMMARY]]
set synth_audit_summary_sha256 [require_env R4_S0_STA_SYNTH_AUDIT_SUMMARY_SHA256]
set synth_audit_netlist_sha256 [require_env R4_S0_STA_SYNTH_AUDIT_NETLIST_SHA256]
set synth_freeze_status_sha256 [require_env R4_S0_STA_SYNTH_FREEZE_STATUS_SHA256]
set synth_exit_status_sha256 [require_env R4_S0_STA_SYNTH_EXIT_STATUS_SHA256]
set synth_binding_sha256 [require_env R4_S0_STA_SYNTH_BINDING_SHA256]
set setup_members_manifest_sha256 [require_env R4_S0_STA_SETUP_MEMBERS_MANIFEST_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "R4-S0 current STA requires exact period_ns=5.0, got: $period_ns"
}
if {$run_id ne "run1" && $run_id ne "run2"} {
  error "R4-S0 current STA requires run1 or run2, got: $run_id"
}
foreach required_file [list $netlist $std_lib $opensta_binary $synth_audit_summary] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
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
  error "R4-S0 current STA requires exactly four macro liberties, got: $macro_count"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]
check_setup -verbose > $setup_path
report_checks -path_delay max -group_path_count 40 -sort_by_slack -digits 9 > $top40_path
report_tns -max -digits 9 >> $top40_path
report_wns -max -digits 9 >> $top40_path
report_power > $power_path
write_note $complete_path "status=COMPLETE
schema=ppa-r4-s0-opensta-completion-v2
run_id=$run_id
period_ns=$period_ns
top=NpcTop
clock_port=clk
clock_name=core_clock
netlist=$netlist
netlist_sha256=$netlist_sha256
std_lib=$std_lib
std_lib_sha256=$std_lib_sha256
macro_lib_count=$macro_count
macro_manifest_sha256=$macro_manifest_sha256
input_manifest_sha256=$input_manifest_sha256
parameters_sha256=$parameters_sha256
opensta_binary=$opensta_binary
opensta_binary_sha256=$opensta_binary_sha256
synth_audit_summary=$synth_audit_summary
synth_audit_summary_sha256=$synth_audit_summary_sha256
synth_audit_netlist_sha256=$synth_audit_netlist_sha256
synth_freeze_status_sha256=$synth_freeze_status_sha256
synth_exit_status_sha256=$synth_exit_status_sha256
synth_binding_sha256=$synth_binding_sha256
setup_members_manifest_sha256=$setup_members_manifest_sha256"
exit
