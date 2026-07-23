proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env V8F_CONE_NETLIST]]
set out_dir [file normalize [require_env V8F_CONE_OUT_DIR]]
set std_lib [file normalize [require_env V8F_CONE_STD_LIB]]
set macro_raw [require_env V8F_CONE_MACRO_LIBS]
set start_name [require_env V8F_CONE_START_PIN]
set structural_start_name [require_env V8F_CONE_STRUCTURAL_START_PIN]
set int_prefix [require_env V8F_CONE_INT_PREFIX]

read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]
file mkdir $out_dir

set start [get_pins $start_name]
if {[llength $start] != 1} {
  error "expected one ROB generation start pin, got [llength $start]: $start_name"
}
set structural_start [get_pins $structural_start_name]
if {[llength $structural_start] != 1} {
  error "expected one ROB generation structural start pin, got [llength $structural_start]: $structural_start_name"
}

set targets [list \
  [list mem_ready "$int_prefix/mem_rsp_ready_o"] \
  [list issue1_ready "$int_prefix/u_dispatch_backend/u_issue_queue/issue1_ready_i"] \
  [list muldiv_ready "$int_prefix/u_muldiv_unit/resp_ready_i"] \
  [list clmul_ready "$int_prefix/u_clmul_unit/resp_ready_i"] \
  [list fp_ready "$int_prefix/u_fp_backend/fpwb_ready_i"] \
  [list rob_wb0_authority "$int_prefix/u_dispatch_backend/u_rob/wb0_valid_i"]]

set manifest [open [file join $out_dir pin-manifest.txt] w]
set reachability [open [file join $out_dir reachability.kv] w]
puts $manifest "semantic_start_q=$start_name count=[llength $start]"
puts $manifest "opensta_structural_start_ck=$structural_start_name count=[llength $structural_start]"
puts $manifest "structural_method=get_fanin_flat_startpoints_only_trace_arcs_all"
puts $manifest "method_note=OpenSTA represents sequential data sources as clock-pin timing startpoints in this query"
foreach target $targets {
  lassign $target label pin_name
  set pin [get_pins $pin_name]
  puts $manifest "$label=$pin_name count=[llength $pin]"
  if {[llength $pin] != 1} {
    close $manifest
    close $reachability
    error "expected one target pin for $label, got [llength $pin]: $pin_name"
  }
  set fanin_startpoints [get_fanin -to $pin -flat -startpoints_only -trace_arcs all]
  set structural_start_hits 0
  set fanin_file [open [file join $out_dir "$label.fanin-startpoints.txt"] w]
  foreach fanin_pin $fanin_startpoints {
    set fanin_name [get_full_name $fanin_pin]
    puts $fanin_file $fanin_name
    if {$fanin_name eq $structural_start_name} {
      incr structural_start_hits
    }
  }
  close $fanin_file
  puts $reachability "${label}_structural_start_hits=$structural_start_hits"
  puts $reachability "${label}_fanin_startpoint_count=[llength $fanin_startpoints]"
  report_checks -from $start -to $pin -unconstrained -path_delay max \
    -group_path_count 1 -sort_by_slack -digits 9 \
    > [file join $out_dir "$label.rpt"]
}
close $manifest
close $reachability
exit
