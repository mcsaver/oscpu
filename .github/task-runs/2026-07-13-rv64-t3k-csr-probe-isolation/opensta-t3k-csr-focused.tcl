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

proc write_collection {fp label coll} {
  puts $fp "\[$label\] count=[llength $coll]"
  foreach object $coll {
    puts $fp [get_full_name $object]
  }
}

proc report_through_to {path through_coll to_coll} {
  if {[llength $through_coll] == 0 || [llength $to_coll] == 0} {
    error "directed timing query has an empty collection"
  }
  report_checks -path_delay max -group_path_count 20 -digits 3 \
      -through $through_coll -to $to_coll > $path
  set fp [open $path r]
  set report_text [read $fp]
  close $fp
  if {[file size $path] == 0 || [string trim $report_text] eq "No paths found."} {
    write_note $path "status=NO_TIMING_PATH through_count=[llength $through_coll] to_count=[llength $to_coll]"
    return "NO_TIMING_PATH"
  }
  return "PATHS_PRESENT"
}

proc write_query {fp name report status source_coll target_coll} {
  puts $fp "\[$name\]"
  puts $fp "report=[file tail $report]"
  puts $fp "selector=through_to"
  puts $fp "status=$status"
  puts $fp "source_count=[llength $source_coll]"
  foreach source $source_coll {
    puts $fp "source_object=[get_full_name $source]"
  }
  puts $fp "target_count=[llength $target_coll]"
  foreach target $target_coll {
    puts $fp "target_object=[get_full_name $target]"
  }
  puts $fp ""
}

proc run_query {fp out_dir name source_coll target_coll} {
  set report [file join $out_dir "opensta-t3k-$name.rpt"]
  set status [report_through_to $report $source_coll $target_coll]
  write_query $fp $name $report $status $source_coll $target_coll
}

proc write_fanout_intersection {path source_coll target_coll} {
  if {[llength $source_coll] == 0 || [llength $target_coll] == 0} {
    error "fanout intersection has an empty source/target collection"
  }
  set target_names {}
  foreach target $target_coll {
    lappend target_names [get_full_name $target]
  }
  set endpoints [get_fanout -from $source_coll -flat \
      -endpoints_only -trace_arcs timing]
  set endpoint_names {}
  foreach endpoint $endpoints {
    set name [get_full_name $endpoint]
    if {[lsearch -exact $target_names $name] >= 0} {
      lappend endpoint_names $name
    }
  }
  set endpoint_names [lsort -unique $endpoint_names]
  set fp [open $path w]
  puts $fp "source_count=[llength $source_coll]"
  foreach source $source_coll {
    puts $fp "source_object=[get_full_name $source]"
  }
  puts $fp "target_count=[llength $target_coll]"
  puts $fp "intersection_count=[llength $endpoint_names]"
  foreach endpoint_name $endpoint_names {
    puts $fp "intersection_object=$endpoint_name"
  }
  close $fp
}

set netlist [file normalize [require_env T3K_STA_NETLIST]]
set out_dir [file normalize [require_env T3K_STA_OUT_DIR]]
set std_lib [file normalize [require_env T3K_STA_STD_LIB]]
set macro_raw [require_env T3K_STA_MACRO_LIBS]
set period_ns [require_env T3K_STA_PERIOD_NS]
set expect [require_env T3K_STA_EXPECT_PROBE]
set netlist_sha256 [require_env T3K_STA_NETLIST_SHA256]
set input_manifest_sha256 [require_env T3K_STA_INPUT_MANIFEST_SHA256]
set parameters_sha256 [require_env T3K_STA_PARAMETERS_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3K focused STA requires exact period_ns=5.0, got: $period_ns"
}
if {$expect ne "old" && $expect ne "fresh"} {
  error "T3K_STA_EXPECT_PROBE must be old or fresh"
}
foreach required_file [list $netlist $std_lib] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
}
file mkdir $out_dir
foreach stale [glob -nocomplain [file join $out_dir opensta-t3k-*]] {
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
  error "T3K focused STA requires exactly four macro liberties"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

set mux_cells {}
set csr_cells {}
set pending_cells {}
set commit_source_pins {}
set pending_source_pins {}
set head_source_pins {}
set legacy_mux_output_pins {}
set probe_mux_output_pins {}
set legacy_csr_input_pins {}
set probe_csr_input_pins {}
set illegal_output_pins {}
set state_priv_q_pins {}
set state_mstatus_q_pins {}
set state_mcounteren_q_pins {}
set state_scounteren_q_pins {}
set pending_trap_d_pins {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set is_mux [string match "*u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux" $cell_name]
  set is_csr [string match "*u_core/u_csr_file" $cell_name]
  set is_pending [string match "*u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer" $cell_name]
  if {$is_mux} {
    lappend mux_cells $cell
  }
  if {$is_csr} {
    lappend csr_cells $cell
  }
  if {$is_pending} {
    lappend pending_cells $cell
  }
  if {$is_mux || $is_csr} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      set pin_name [get_name $pin]
      set pin_direction [get_property $pin direction]
      if {$is_mux && $pin_direction eq "input" &&
          ($pin_name eq "core_commit0_valid_i" ||
          $pin_name eq "core_commit0_exception_i" ||
          [string match "core_commit0_pc_i_*" $pin_name] ||
          [string match "core_commit0_inst_i_*" $pin_name])} {
        lappend commit_source_pins $pin
      }
      if {$is_mux && $pin_direction eq "input" &&
          ($pin_name eq "pending_system_i" ||
          $pin_name eq "pending_system_csr_i" ||
          $pin_name eq "pending_system_dispatched_i" ||
          $pin_name eq "pending_system_sfence_i" ||
          [string match "pending_system_pc_i_*" $pin_name] ||
          [string match "pending_system_inst_i_*" $pin_name])} {
        lappend pending_source_pins $pin
      }
      if {$is_mux && $pin_direction eq "input" && (
          [string match "head_inst0_i_*" $pin_name] ||
          [string match "head_inst1_i_*" $pin_name] ||
          $pin_name eq "head0_csr_raw_i" ||
          $pin_name eq "head1_csr_raw_i" ||
          $pin_name eq "dispatch_valid_i" ||
          $pin_name eq "dispatch0_system_i" ||
          $pin_name eq "dispatch1_barrier_i")} {
        lappend head_source_pins $pin
      }
      if {$is_mux && $pin_direction eq "output" &&
          [string match "csr_access_*_o*" $pin_name] &&
          ![string match "csr_access_rs1_data_o*" $pin_name] &&
          $pin_name ne "csr_access_inst_o_0_"} {
        if {$pin_name eq "csr_access_valid_o" ||
            [string match "csr_access_addr_o_*" $pin_name] ||
            [string match "csr_access_funct3_o_*" $pin_name] ||
            [string match "csr_access_rs1_idx_o_*" $pin_name]} {
          lappend legacy_mux_output_pins $pin
        }
      }
      if {$is_mux && $pin_direction eq "output" &&
          [string match "csr_probe_*_o*" $pin_name]} {
        lappend probe_mux_output_pins $pin
      }
      if {$is_csr && $pin_direction eq "input" &&
          ($pin_name eq "csr_valid_i" ||
          [string match "csr_addr_i_*" $pin_name] ||
          [string match "csr_funct3_i_*" $pin_name] ||
          [string match "csr_rs1_idx_i_*" $pin_name])} {
        lappend legacy_csr_input_pins $pin
      }
      if {$is_csr && $pin_direction eq "input" &&
          [string match "csr_probe_*_i*" $pin_name]} {
        lappend probe_csr_input_pins $pin
      }
      if {$is_csr && $pin_direction eq "output" &&
          $pin_name eq "csr_illegal_o"} {
        lappend illegal_output_pins $pin
      }
    }
  }

  if {[string match "*u_core/u_csr_file/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] ne "Q"} {
        continue
      }
      foreach net [get_nets -quiet -of_objects $pin] {
        set net_name [get_full_name $net]
        if {[string match "*priv_mode_o_*" $net_name] ||
            [string match "*priv_mode_q_*" $net_name]} {
          lappend state_priv_q_pins $pin
        }
        if {[string match "*mstatus_o_*" $net_name] ||
            [string match "*csr_mstatus_q_*" $net_name]} {
          lappend state_mstatus_q_pins $pin
        }
        if {[string match "*csr_mcounteren_q_*" $net_name]} {
          lappend state_mcounteren_q_pins $pin
        }
        if {[string match "*csr_scounteren_q_*" $net_name]} {
          lappend state_scounteren_q_pins $pin
        }
      }
    }
  }

  if {[string match "*u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/*" $cell_name]} {
    set d_pins {}
    set q_nets {}
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] eq "D"} {
        lappend d_pins $pin
      }
      if {[get_name $pin] eq "Q"} {
        foreach net [get_nets -quiet -of_objects $pin] {
          lappend q_nets [get_full_name $net]
        }
      }
    }
    set is_trap_payload 0
    foreach q_net $q_nets {
      if {[string match "*pending_trap_cause_o_*" $q_net] ||
          [string match "*pending_trap_pc_o_*" $q_net] ||
          [string match "*pending_trap_tval_o_*" $q_net]} {
        set is_trap_payload 1
      }
    }
    if {$is_trap_payload} {
      foreach d_pin $d_pins {
        lappend pending_trap_d_pins $d_pin
      }
    }
  }
}

set state_q_pins [concat $state_priv_q_pins $state_mstatus_q_pins \
    $state_mcounteren_q_pins $state_scounteren_q_pins]
if {[llength $mux_cells] != 1 || [llength $csr_cells] != 1 ||
    [llength $pending_cells] != 1 || [llength $commit_source_pins] != 98 ||
    [llength $pending_source_pins] != 100 || [llength $head_source_pins] != 69 ||
    [llength $legacy_mux_output_pins] != 21 ||
    [llength $legacy_csr_input_pins] != 21 ||
    [llength $illegal_output_pins] != 1 ||
    [llength $state_priv_q_pins] != 1 ||
    [llength $state_mstatus_q_pins] != 62 ||
    [llength $state_mcounteren_q_pins] != 3 ||
    [llength $state_scounteren_q_pins] != 3 ||
    [llength $pending_trap_d_pins] != 133} {
  error "T3K focused base object contract failed: mux=[llength $mux_cells] csr=[llength $csr_cells] pending=[llength $pending_cells] commit=[llength $commit_source_pins] pending_src=[llength $pending_source_pins] head=[llength $head_source_pins] legacy_mux=[llength $legacy_mux_output_pins] legacy_csr=[llength $legacy_csr_input_pins] illegal=[llength $illegal_output_pins] state_priv=[llength $state_priv_q_pins] state_mstatus=[llength $state_mstatus_q_pins] state_mcounteren=[llength $state_mcounteren_q_pins] state_scounteren=[llength $state_scounteren_q_pins] pending_d=[llength $pending_trap_d_pins]"
}
if {$expect eq "old" && ([llength $probe_mux_output_pins] != 0 ||
    [llength $probe_csr_input_pins] != 0)} {
  error "old T3J netlist unexpectedly contains T3K probe pins"
}
if {$expect eq "fresh" && ([llength $probe_mux_output_pins] != 21 ||
    [llength $probe_csr_input_pins] != 21)} {
  error "fresh T3K netlist must contain 21 mux-output and 21 CsrFile-input probe pins"
}

set labels [list mux_cells csr_cells pending_cells commit_source_pins \
    pending_source_pins head_source_pins legacy_mux_output_pins \
    probe_mux_output_pins legacy_csr_input_pins probe_csr_input_pins \
    illegal_output_pins state_priv_q_pins state_mstatus_q_pins \
    state_mcounteren_q_pins state_scounteren_q_pins state_q_pins \
    pending_trap_d_pins]
set collections [list $mux_cells $csr_cells $pending_cells \
    $commit_source_pins $pending_source_pins $head_source_pins \
    $legacy_mux_output_pins $probe_mux_output_pins $legacy_csr_input_pins \
    $probe_csr_input_pins $illegal_output_pins $state_priv_q_pins \
    $state_mstatus_q_pins $state_mcounteren_q_pins $state_scounteren_q_pins \
    $state_q_pins $pending_trap_d_pins]
set counts_fp [open [file join $out_dir opensta-t3k-focused-counts.txt] w]
set objects_fp [open [file join $out_dir opensta-t3k-focused-objects.txt] w]
foreach label $labels collection $collections {
  puts $counts_fp "$label=[llength $collection]"
  write_collection $objects_fp $label $collection
}
close $counts_fp
close $objects_fp

set queries_fp [open [file join $out_dir opensta-t3k-focused-queries.txt] w]
run_query $queries_fp $out_dir commit_to_illegal \
    $commit_source_pins $illegal_output_pins
run_query $queries_fp $out_dir pending_to_illegal \
    $pending_source_pins $illegal_output_pins
run_query $queries_fp $out_dir legacy_access_to_illegal \
    $legacy_csr_input_pins $illegal_output_pins
run_query $queries_fp $out_dir legacy_access_to_pending \
    $legacy_csr_input_pins $pending_trap_d_pins
run_query $queries_fp $out_dir head_to_illegal \
    $head_source_pins $illegal_output_pins
run_query $queries_fp $out_dir head_to_pending \
    $head_source_pins $pending_trap_d_pins
run_query $queries_fp $out_dir state_to_illegal \
    $state_q_pins $illegal_output_pins
run_query $queries_fp $out_dir state_to_pending \
    $state_q_pins $pending_trap_d_pins
run_query $queries_fp $out_dir illegal_to_pending \
    $illegal_output_pins $pending_trap_d_pins
if {$expect eq "fresh"} {
  run_query $queries_fp $out_dir probe_to_illegal \
      $probe_csr_input_pins $illegal_output_pins
  run_query $queries_fp $out_dir probe_to_pending \
      $probe_csr_input_pins $pending_trap_d_pins
} else {
  foreach name [list probe_to_illegal probe_to_pending] {
    set report [file join $out_dir "opensta-t3k-$name.rpt"]
    write_note $report "status=PORT_ABSENT source_count=0"
    puts $queries_fp "\[$name\]"
    puts $queries_fp "report=[file tail $report]"
    puts $queries_fp "selector=through_to"
    puts $queries_fp "status=PORT_ABSENT"
    puts $queries_fp "source_count=0"
    puts $queries_fp "target_count=0"
    puts $queries_fp ""
  }
}
close $queries_fp

write_fanout_intersection \
    [file join $out_dir opensta-t3k-legacy-pending-intersection.txt] \
    $legacy_csr_input_pins $pending_trap_d_pins
write_fanout_intersection \
    [file join $out_dir opensta-t3k-head-pending-intersection.txt] \
    $head_source_pins $pending_trap_d_pins
write_fanout_intersection \
    [file join $out_dir opensta-t3k-state-pending-intersection.txt] \
    $state_q_pins $pending_trap_d_pins
write_fanout_intersection \
    [file join $out_dir opensta-t3k-illegal-pending-intersection.txt] \
    $illegal_output_pins $pending_trap_d_pins
if {$expect eq "fresh"} {
  write_fanout_intersection \
      [file join $out_dir opensta-t3k-probe-pending-intersection.txt] \
      $probe_csr_input_pins $pending_trap_d_pins
} else {
  write_note [file join $out_dir opensta-t3k-probe-pending-intersection.txt] \
      "status=PORT_ABSENT\nsource_count=0\ntarget_count=133\nintersection_count=0"
}

write_note [file join $out_dir opensta-t3k-focused-complete.txt] "status=COMPLETE
expect=$expect
period_ns=$period_ns
top=NpcTop
netlist=$netlist
netlist_sha256=$netlist_sha256
input_manifest_sha256=$input_manifest_sha256
parameters_sha256=$parameters_sha256"
exit
