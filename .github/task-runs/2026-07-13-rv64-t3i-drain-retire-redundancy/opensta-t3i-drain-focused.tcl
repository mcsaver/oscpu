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

proc report_through_to {path through_coll to_coll} {
  set through_count [llength $through_coll]
  set to_count [llength $to_coll]
  if {$through_count == 0 || $to_count == 0} {
    write_note $path "status=EMPTY_COLLECTION through_count=$through_count to_count=$to_count"
    return "EMPTY_COLLECTION"
  }
  report_checks -path_delay max -group_path_count 10 -digits 3 \
      -through $through_coll -to $to_coll > $path
  set fp [open $path r]
  set report_text [read $fp]
  close $fp
  if {[file size $path] == 0 || [string trim $report_text] eq "No paths found."} {
    write_note $path "status=NO_TIMING_PATH through_count=$through_count to_count=$to_count"
    return "NO_TIMING_PATH"
  }
  return "PATHS_PRESENT"
}

proc write_collection {fp label coll} {
  puts $fp "\[$label\] count=[llength $coll]"
  foreach obj $coll {
    puts $fp [get_full_name $obj]
  }
}

proc write_query_binding {fp name selector path status source_label source_coll target_label target_coll} {
  puts $fp "\[$name\]"
  puts $fp "report=[file tail $path]"
  puts $fp "selector=$selector"
  puts $fp "status=$status"
  puts $fp "source_label=$source_label"
  puts $fp "source_count=[llength $source_coll]"
  foreach obj $source_coll {
    puts $fp "source_object=[get_full_name $obj]"
  }
  puts $fp "target_label=$target_label"
  puts $fp "target_count=[llength $target_coll]"
  foreach obj $target_coll {
    puts $fp "target_object=[get_full_name $obj]"
  }
  puts $fp ""
}

proc run_through_query {fp name path source_label source_coll target_label target_coll} {
  set status [report_through_to $path $source_coll $target_coll]
  write_query_binding $fp $name through $path $status \
      $source_label $source_coll $target_label $target_coll
}

proc run_removed_query {fp name path source_label source_coll target_label target_coll} {
  if {[llength $source_coll] != 0 || [llength $target_coll] == 0} {
    error "removed query contract failed name=$name source_count=[llength $source_coll] target_count=[llength $target_coll]"
  }
  write_note $path "status=REMOVED_THROUGH_PORT source_count=0 target_count=[llength $target_coll]"
  write_query_binding $fp $name removed $path REMOVED_THROUGH_PORT \
      $source_label $source_coll $target_label $target_coll
}

proc write_fanout_endpoints {path source_label source_coll} {
  if {[llength $source_coll] == 0} {
    error "fanout source collection is empty: $source_label"
  }
  set endpoints [get_fanout -from $source_coll -flat \
      -endpoints_only -trace_arcs timing]
  set endpoint_names {}
  foreach endpoint $endpoints {
    lappend endpoint_names [get_full_name $endpoint]
  }
  set endpoint_names [lsort -unique $endpoint_names]
  set fp [open $path w]
  puts $fp "source_label=$source_label"
  puts $fp "source_count=[llength $source_coll]"
  foreach source $source_coll {
    puts $fp "source_object=[get_full_name $source]"
  }
  puts $fp "endpoint_count=[llength $endpoint_names]"
  foreach endpoint_name $endpoint_names {
    puts $fp "endpoint_object=$endpoint_name"
  }
  close $fp
}

set netlist   [file normalize [require_env T3I_STA_NETLIST]]
set out_dir   [file normalize [require_env T3I_STA_OUT_DIR]]
set std_lib   [file normalize [require_env T3I_STA_STD_LIB]]
set macro_raw [require_env T3I_STA_MACRO_LIBS]
set period_ns [require_env T3I_STA_PERIOD_NS]
set expect    [require_env T3I_STA_EXPECT_RETIRED_PORTS]
set netlist_sha256 [require_env T3I_STA_NETLIST_SHA256]

if {abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3I focused STA requires exact 5.0 ns period, got: $period_ns"
}
if {$expect ne "present" && $expect ne "absent"} {
  error "T3I_STA_EXPECT_RETIRED_PORTS must be present or absent"
}
file mkdir $out_dir
set complete_path [file join $out_dir opensta-t3i-focused-complete.txt]
foreach stale [list \
    $complete_path \
    [file join $out_dir opensta-t3i-focused-counts.txt] \
    [file join $out_dir opensta-t3i-focused-objects.txt] \
    [file join $out_dir opensta-t3i-focused-queries.txt] \
    [file join $out_dir opensta-t3i-retire-fanout-endpoints.txt] \
    [file join $out_dir opensta-t3i-retire-to-fetch.rpt] \
    [file join $out_dir opensta-t3i-retire-to-pending-trap.rpt] \
    [file join $out_dir opensta-t3i-rob-count-to-fetch.rpt] \
    [file join $out_dir opensta-t3i-rob-count-to-pending-trap.rpt]] {
  file delete -force $stale
}

read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

set gate_cells {}
set trap_parent_cells {}
set retire_producer_cells {}
set retire_pins {}
set retire_producer_pins {}
set rob_count_pins {}
set issue_count_pins {}
set backend_drained_pins {}
set fetch_payload_en {}
set pending_trap_d {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set want_gate [string match "*u_pending_drain_resolve_gate" $cell_name]
  set want_retire_producer [string match "*u_execute_backend/u_core_slice" $cell_name]
  set want_fetch [string match "*u_fetch_packet_cache/u_payload_sram" $cell_name]
  set want_trap_parent [string match "*u_pending_trap_exit_sequencer" $cell_name]
  set want_trap_leaf [string match "*u_pending_trap_exit_sequencer/*" $cell_name]
  if {$want_gate} {
    lappend gate_cells $cell
  }
  if {$want_trap_parent} {
    lappend trap_parent_cells $cell
  }
  if {$want_retire_producer} {
    lappend retire_producer_cells $cell
  }
  if {$want_gate || $want_retire_producer || $want_fetch || $want_trap_leaf} {
    set cell_pins [get_pins -quiet -of_objects $cell]
    set trap_d_candidates {}
    set trap_has_ck 0
    set trap_has_q 0
    foreach pin $cell_pins {
      set pin_name [get_name $pin]
      if {$want_gate && [string match "core_retire_count_i*" $pin_name]} {
        lappend retire_pins $pin
      }
      if {$want_gate && [string match "rob_count_i*" $pin_name]} {
        lappend rob_count_pins $pin
      }
      if {$want_gate && [string match "issue_count_i*" $pin_name]} {
        lappend issue_count_pins $pin
      }
      if {$want_gate && [string match "backend_drained_o*" $pin_name]} {
        lappend backend_drained_pins $pin
      }
      if {$want_retire_producer && [string match "retire_count_o*" $pin_name]} {
        lappend retire_producer_pins $pin
      }
      if {$want_fetch && $pin_name eq "en_i"} {
        lappend fetch_payload_en $pin
      }
      if {$want_trap_leaf && $pin_name eq "D"} {
        lappend trap_d_candidates $pin
      }
      if {$want_trap_leaf && $pin_name eq "CK"} {
        set trap_has_ck 1
      }
      if {$want_trap_leaf && ($pin_name eq "Q" || $pin_name eq "QN")} {
        set trap_has_q 1
      }
    }
    if {$want_trap_leaf && $trap_has_ck && $trap_has_q &&
        [llength $trap_d_candidates] == 1} {
      lappend pending_trap_d [lindex $trap_d_candidates 0]
    }
  }
}

if {[llength $gate_cells] != 1 || [llength $trap_parent_cells] != 1 ||
    [llength $retire_producer_cells] != 1} {
  error "parent instance contract failed gate=[llength $gate_cells] trap=[llength $trap_parent_cells] retire_producer=[llength $retire_producer_cells]"
}
if {[llength $rob_count_pins] != 5 || [llength $issue_count_pins] != 4 ||
    [llength $backend_drained_pins] != 1 || [llength $fetch_payload_en] != 1 ||
    [llength $retire_producer_pins] != 2 || [llength $pending_trap_d] != 137} {
  error "focused object contract failed"
}
if {$expect eq "present" && [llength $retire_pins] != 2} {
  error "expected two legacy retire pins, got [llength $retire_pins]"
}
if {$expect eq "absent" && [llength $retire_pins] != 0} {
  error "expected retire pins removed, got [llength $retire_pins]"
}

set counts_path [file join $out_dir opensta-t3i-focused-counts.txt]
set counts_fp [open $counts_path w]
foreach label [list gate_cells retire_pins rob_count_pins issue_count_pins \
        trap_parent_cells retire_producer_cells retire_producer_pins backend_drained_pins \
        fetch_payload_en pending_trap_d] \
        coll [list $gate_cells $retire_pins $rob_count_pins $issue_count_pins \
        $trap_parent_cells $retire_producer_cells $retire_producer_pins $backend_drained_pins \
        $fetch_payload_en $pending_trap_d] {
  puts $counts_fp "$label=[llength $coll]"
}
close $counts_fp

set objects_path [file join $out_dir opensta-t3i-focused-objects.txt]
set objects_fp [open $objects_path w]
foreach label [list gate_cells retire_pins rob_count_pins issue_count_pins \
        trap_parent_cells retire_producer_cells retire_producer_pins backend_drained_pins \
        fetch_payload_en pending_trap_d] \
        coll [list $gate_cells $retire_pins $rob_count_pins $issue_count_pins \
        $trap_parent_cells $retire_producer_cells $retire_producer_pins $backend_drained_pins \
        $fetch_payload_en $pending_trap_d] {
  write_collection $objects_fp $label $coll
}
close $objects_fp

# A hierarchy input pin is not a valid timing startpoint, so the legacy and ROB
# path reports use -through.  The query manifest binds each report to the exact
# collections passed to report_checks; the human-readable path need not expose
# zero-delay hierarchy pins.
set queries_path [file join $out_dir opensta-t3i-focused-queries.txt]
set queries_fp [open $queries_path w]
if {$expect eq "present"} {
  run_through_query $queries_fp retire_to_fetch \
      [file join $out_dir opensta-t3i-retire-to-fetch.rpt] \
      retire_pins $retire_pins fetch_payload_en $fetch_payload_en
  run_through_query $queries_fp retire_to_pending_trap \
      [file join $out_dir opensta-t3i-retire-to-pending-trap.rpt] \
      retire_pins $retire_pins pending_trap_d $pending_trap_d
} else {
  run_removed_query $queries_fp retire_to_fetch \
      [file join $out_dir opensta-t3i-retire-to-fetch.rpt] \
      retire_pins $retire_pins fetch_payload_en $fetch_payload_en
  run_removed_query $queries_fp retire_to_pending_trap \
      [file join $out_dir opensta-t3i-retire-to-pending-trap.rpt] \
      retire_pins $retire_pins pending_trap_d $pending_trap_d
}
# backend_drained_o is a hierarchy output pin rather than a valid timing
# endpoint, so report_checks -to it correctly returns no path even in T3H.
# Its exact presence/absence is covered by the gate ABI checker; the two
# downstream endpoint families below carry the timing/cone proof.
run_through_query $queries_fp rob_count_to_fetch \
    [file join $out_dir opensta-t3i-rob-count-to-fetch.rpt] \
    rob_count_pins $rob_count_pins fetch_payload_en $fetch_payload_en
run_through_query $queries_fp rob_count_to_pending_trap \
    [file join $out_dir opensta-t3i-rob-count-to-pending-trap.rpt] \
    rob_count_pins $rob_count_pins pending_trap_d $pending_trap_d
close $queries_fp

# The canonical retire producer remains live for instret/debug in both netlists.
# Its topological timing fanout must reach the focused drain consumers in T3H,
# but must have a non-empty disjoint endpoint set after T3I.  This guards against
# a renamed or bypassed drain dependency without treating the hierarchy output
# as a report_checks startpoint.
write_fanout_endpoints \
    [file join $out_dir opensta-t3i-retire-fanout-endpoints.txt] \
    retire_producer_pins $retire_producer_pins

write_note $complete_path "status=COMPLETE\nexpect=$expect\nperiod_ns=$period_ns\nnetlist=$netlist\nnetlist_sha256=$netlist_sha256"
exit
