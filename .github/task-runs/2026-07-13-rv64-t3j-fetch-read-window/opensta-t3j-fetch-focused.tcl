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
    error "directed timing query has an empty collection: through=$through_count to=$to_count"
  }
  report_checks -path_delay max -group_path_count 20 -digits 3 \
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

proc write_query_binding {fp name path status source_label source_coll target_label target_coll} {
  puts $fp "\[$name\]"
  puts $fp "report=[file tail $path]"
  puts $fp "selector=through"
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
  write_query_binding $fp $name $path $status \
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

proc write_startpoint_provenance {path source_label source_coll} {
  if {[llength $source_coll] == 0} {
    error "fanin sink collection is empty: $source_label"
  }
  set startpoints [get_fanin -to $source_coll -flat \
      -startpoints_only -trace_arcs timing]
  if {[llength $startpoints] == 0} {
    error "physical read-window fanin has no timing startpoint"
  }
  set fp [open $path w]
  puts $fp "status=STARTPOINTS_PRESENT"
  puts $fp "source_label=$source_label"
  puts $fp "source_count=[llength $source_coll]"
  set source_index 0
  foreach source $source_coll {
    puts $fp "source.$source_index.object=[get_full_name $source]"
    incr source_index
  }
  puts $fp "startpoint_count=[llength $startpoints]"
  set startpoint_index 0
  foreach startpoint $startpoints {
    set cells [get_cells -quiet -of_objects $startpoint]
    set nets [get_nets -quiet -of_objects $startpoint]
    set q_pins {}
    foreach cell $cells {
      foreach pin [get_pins -quiet -of_objects $cell] {
        if {[get_name $pin] eq "Q"} {
          lappend q_pins $pin
        }
      }
    }
    set q_nets [get_nets -quiet -of_objects $q_pins]
    puts $fp "startpoint.$startpoint_index.object=[get_full_name $startpoint]"
    puts $fp "startpoint.$startpoint_index.cell_count=[llength $cells]"
    set cell_index 0
    foreach cell $cells {
      puts $fp "startpoint.$startpoint_index.cell.$cell_index=[get_full_name $cell]"
      incr cell_index
    }
    puts $fp "startpoint.$startpoint_index.net_count=[llength $nets]"
    set net_index 0
    foreach net $nets {
      puts $fp "startpoint.$startpoint_index.net.$net_index=[get_full_name $net]"
      incr net_index
    }
    puts $fp "startpoint.$startpoint_index.q_pin_count=[llength $q_pins]"
    set q_pin_index 0
    foreach q_pin $q_pins {
      puts $fp "startpoint.$startpoint_index.q_pin.$q_pin_index=[get_full_name $q_pin]"
      incr q_pin_index
    }
    puts $fp "startpoint.$startpoint_index.q_net_count=[llength $q_nets]"
    set q_net_index 0
    foreach q_net $q_nets {
      puts $fp "startpoint.$startpoint_index.q_net.$q_net_index=[get_full_name $q_net]"
      incr q_net_index
    }
    incr startpoint_index
  }
  close $fp
}

set netlist [file normalize [require_env T3J_STA_NETLIST]]
set out_dir [file normalize [require_env T3J_STA_OUT_DIR]]
set std_lib [file normalize [require_env T3J_STA_STD_LIB]]
set macro_raw [require_env T3J_STA_MACRO_LIBS]
set period_ns [require_env T3J_STA_PERIOD_NS]
set expect [require_env T3J_STA_EXPECT_READ_WINDOW]
set netlist_sha256 [require_env T3J_STA_NETLIST_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3J focused STA requires exact period_ns=5.0, got: $period_ns"
}
if {$expect ne "old" && $expect ne "fresh"} {
  error "T3J_STA_EXPECT_READ_WINDOW must be old or fresh"
}
if {![file exists $netlist]} {
  error "netlist does not exist: $netlist"
}
if {![file exists $std_lib]} {
  error "standard liberty does not exist: $std_lib"
}
file mkdir $out_dir
set complete_path [file join $out_dir opensta-t3j-focused-complete.txt]
foreach stale [list \
    $complete_path \
    [file join $out_dir opensta-t3j-focused-counts.txt] \
    [file join $out_dir opensta-t3j-focused-objects.txt] \
    [file join $out_dir opensta-t3j-focused-queries.txt] \
    [file join $out_dir opensta-t3j-accept-fanout-endpoints.txt] \
    [file join $out_dir opensta-t3j-address-fanout-endpoints.txt] \
    [file join $out_dir opensta-t3j-read-window-fanout-endpoints.txt] \
    [file join $out_dir opensta-t3j-read-window-startpoints.txt] \
    [file join $out_dir opensta-t3j-accept-to-payload-en.rpt] \
    [file join $out_dir opensta-t3j-pc-to-payload-addr.rpt] \
    [file join $out_dir opensta-t3j-read-window-to-payload-en.rpt]] {
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

set bridge_cells {}
set fpc_cells {}
set payload_cells {}
set accept_pins {}
set read_window_pins {}
set lookup_pc_pins {}
set payload_en_pins {}
set payload_addr_pins {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set want_bridge [string match "*u_core/u_ooo_fetch_bridge" $cell_name]
  set want_fpc [string match "*u_core/u_ooo_fetch_bridge/u_fetch_packet_cache" $cell_name]
  set want_payload [string match "*u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram" $cell_name]
  if {$want_bridge} {
    lappend bridge_cells $cell
  }
  if {$want_fpc} {
    lappend fpc_cells $cell
  }
  if {$want_payload} {
    lappend payload_cells $cell
  }
  if {$want_fpc || $want_payload} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      set pin_name [get_name $pin]
      if {$want_fpc && $pin_name eq "lookup_en_i"} {
        lappend accept_pins $pin
      }
      if {$want_fpc && $pin_name eq "lookup_read_en_i"} {
        lappend read_window_pins $pin
      }
      if {$want_fpc && [string match "lookup_pc_i_*_" $pin_name]} {
        lappend lookup_pc_pins $pin
      }
      if {$want_payload && $pin_name eq "en_i"} {
        lappend payload_en_pins $pin
      }
      if {$want_payload && [string match "addr_i*" $pin_name]} {
        lappend payload_addr_pins $pin
      }
    }
  }
}

if {[llength $bridge_cells] != 1 || [llength $fpc_cells] != 1 ||
    [llength $payload_cells] != 1 || [llength $accept_pins] != 1 ||
    [llength $lookup_pc_pins] != 64 || [llength $payload_en_pins] != 1 ||
    [llength $payload_addr_pins] != 12} {
  error "T3J focused object contract failed: bridge=[llength $bridge_cells] fpc=[llength $fpc_cells] payload=[llength $payload_cells] accept=[llength $accept_pins] lookup_pc=[llength $lookup_pc_pins] payload_en=[llength $payload_en_pins] payload_addr=[llength $payload_addr_pins]"
}
if {$expect eq "old" && [llength $read_window_pins] != 0} {
  error "old T3I netlist unexpectedly has lookup_read_en_i"
}
if {$expect eq "fresh" && [llength $read_window_pins] != 1} {
  error "fresh T3J netlist must have exactly one lookup_read_en_i pin"
}

set labels [list bridge_cells fpc_cells payload_cells accept_pins \
    read_window_pins lookup_pc_pins payload_en_pins payload_addr_pins]
set colls [list $bridge_cells $fpc_cells $payload_cells $accept_pins \
    $read_window_pins $lookup_pc_pins $payload_en_pins $payload_addr_pins]
set counts_fp [open [file join $out_dir opensta-t3j-focused-counts.txt] w]
set objects_fp [open [file join $out_dir opensta-t3j-focused-objects.txt] w]
foreach label $labels coll $colls {
  puts $counts_fp "$label=[llength $coll]"
  write_collection $objects_fp $label $coll
}
close $counts_fp
close $objects_fp

# Hierarchy input pins are not timing startpoints, so these directed checks use
# -through and bind their exact non-empty collections in a machine manifest.
set queries_fp [open [file join $out_dir opensta-t3j-focused-queries.txt] w]
run_through_query $queries_fp accept_to_payload_en \
    [file join $out_dir opensta-t3j-accept-to-payload-en.rpt] \
    accept_pins $accept_pins payload_en_pins $payload_en_pins
run_through_query $queries_fp pc_to_payload_addr \
    [file join $out_dir opensta-t3j-pc-to-payload-addr.rpt] \
    lookup_pc_pins $lookup_pc_pins payload_addr_pins $payload_addr_pins
if {$expect eq "fresh"} {
  run_through_query $queries_fp read_window_to_payload_en \
      [file join $out_dir opensta-t3j-read-window-to-payload-en.rpt] \
      read_window_pins $read_window_pins payload_en_pins $payload_en_pins
} else {
  write_note [file join $out_dir opensta-t3j-read-window-to-payload-en.rpt] \
      "status=PORT_ABSENT source_count=0 target_count=1"
}
close $queries_fp

# Fanout intersections are the topological half of the proof: old accept must
# reach SRAM en, fresh accept must not; PC address must retain all 12 addr pins.
write_fanout_endpoints \
    [file join $out_dir opensta-t3j-accept-fanout-endpoints.txt] \
    accept_pins $accept_pins
write_fanout_endpoints \
    [file join $out_dir opensta-t3j-address-fanout-endpoints.txt] \
    lookup_pc_pins $lookup_pc_pins
if {$expect eq "fresh"} {
  write_fanout_endpoints \
      [file join $out_dir opensta-t3j-read-window-fanout-endpoints.txt] \
      read_window_pins $read_window_pins
  write_startpoint_provenance \
      [file join $out_dir opensta-t3j-read-window-startpoints.txt] \
      read_window_pins $read_window_pins
} else {
  write_note [file join $out_dir opensta-t3j-read-window-fanout-endpoints.txt] \
      "status=PORT_ABSENT source_count=0"
  write_note [file join $out_dir opensta-t3j-read-window-startpoints.txt] \
      "status=PORT_ABSENT\nsource_label=read_window_pins\nsource_count=0\nstartpoint_count=0"
}

write_note $complete_path "status=COMPLETE\nexpect=$expect\nperiod_ns=$period_ns\nnetlist=$netlist\nnetlist_sha256=$netlist_sha256"
exit
