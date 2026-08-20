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

proc require_tsv_atom {value label} {
  if {$value eq "" || [regexp {[\t\r\n]} $value]} {
    error "$label is empty or contains a TSV delimiter"
  }
  return $value
}

proc write_bpu_negative_slack_inventory {path} {
  set matched_pin_count 0
  set numeric_slack_pin_count 0
  set negative_rows {}
  array set seen_pin_names {}

  foreach pin [get_pins -hierarchical -quiet *u_branch_direction_predictor*] {
    incr matched_pin_count
    set full_name [require_tsv_atom [get_full_name $pin] "BPU pin full_name"]
    if {[info exists seen_pin_names($full_name)]} {
      error "duplicate BPU hierarchical pin full_name: $full_name"
    }
    set seen_pin_names($full_name) 1
    set slack_raw [get_property $pin slack_max]
    # OpenSTA may return INF for an unconstrained pin; only finite decimal
    # slack values enter the numeric and negative-slack inventories.
    if {![regexp {^-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$} $slack_raw]} {
      continue
    }
    incr numeric_slack_pin_count
    set slack_value [expr {double($slack_raw)}]
    if {$slack_value < 0.0} {
      lappend negative_rows [list $full_name [format %.12g $slack_value]]
    }
  }
  if {$matched_pin_count == 0 || $numeric_slack_pin_count == 0} {
    error "BPU pin inventory lacks matched or numeric-slack pins: matched=$matched_pin_count numeric=$numeric_slack_pin_count"
  }
  set negative_rows [lsort -ascii -index 0 $negative_rows]

  set stream [open $path w]
  puts $stream "schema\tnpc-rv64-opensta-bpu-negative-slack-inventory-v1"
  puts $stream "inventory_semantics\tcomplete_hierarchical_pin_inventory_not_unique_timing_paths"
  puts $stream "matched_pin_count\t$matched_pin_count"
  puts $stream "numeric_slack_pin_count\t$numeric_slack_pin_count"
  puts $stream "negative_slack_pin_count\t[llength $negative_rows]"
  puts $stream "full_name\tslack_max_ns"
  foreach row $negative_rows {
    puts $stream "[lindex $row 0]\t[lindex $row 1]"
  }
  close $stream
}

proc write_bpu_update_fanout_inventory {path} {
  set source_rows {}
  array set seen_source_names {}

  foreach source [get_pins -hierarchical -quiet *u_branch_direction_predictor*u_local_pht*update_taken_i] {
    set source_name [require_tsv_atom [get_full_name $source] "BPU update source full_name"]
    if {[info exists seen_source_names($source_name)]} {
      error "duplicate BPU update source full_name: $source_name"
    }
    set seen_source_names($source_name) 1
    set endpoint_names {}
    unset -nocomplain seen_endpoint_names
    array set seen_endpoint_names {}
    foreach endpoint [get_fanout -from [list $source] -flat -endpoints_only -trace_arcs timing] {
      set endpoint_name [require_tsv_atom [get_full_name $endpoint] "BPU fanout endpoint full_name"]
      if {![info exists seen_endpoint_names($endpoint_name)]} {
        set seen_endpoint_names($endpoint_name) 1
        lappend endpoint_names $endpoint_name
      }
    }
    lappend source_rows [list $source_name [lsort -ascii $endpoint_names]]
  }
  if {[llength $source_rows] == 0} {
    error "BPU local-PHT update_taken_i source inventory is empty"
  }
  set source_rows [lsort -ascii -index 0 $source_rows]

  set stream [open $path w]
  puts $stream "schema\tnpc-rv64-opensta-bpu-update-fanout-inventory-v1"
  puts $stream "inventory_semantics\tcomplete_flat_sequential_endpoint_inventory_not_unique_timing_paths"
  puts $stream "matched_source_count\t[llength $source_rows]"
  puts $stream "record_type\tsource_full_name\tvalue"
  foreach row $source_rows {
    set source_name [lindex $row 0]
    set endpoint_names [lindex $row 1]
    puts $stream "source\t$source_name\t[llength $endpoint_names]"
    foreach endpoint_name $endpoint_names {
      puts $stream "endpoint\t$source_name\t$endpoint_name"
    }
  }
  close $stream
}

proc write_fp_negative_slack_inventory {path} {
  set matched_pin_count 0
  set numeric_slack_pin_count 0
  set negative_rows {}
  array set seen_pin_names {}

  foreach pin [get_pins -hierarchical -quiet *u_fp_arith*] {
    incr matched_pin_count
    set full_name [require_tsv_atom [get_full_name $pin] "FP pin full_name"]
    if {[info exists seen_pin_names($full_name)]} {
      error "duplicate FP hierarchical pin full_name: $full_name"
    }
    set seen_pin_names($full_name) 1
    set slack_raw [get_property $pin slack_max]
    if {![regexp {^-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$} $slack_raw]} {
      continue
    }
    incr numeric_slack_pin_count
    set slack_value [expr {double($slack_raw)}]
    if {$slack_value < 0.0} {
      lappend negative_rows [list $full_name [format %.12g $slack_value]]
    }
  }
  if {$matched_pin_count == 0 || $numeric_slack_pin_count == 0 || [llength $negative_rows] == 0} {
    error "FP pin inventory lacks matched, numeric, or negative-slack pins: matched=$matched_pin_count numeric=$numeric_slack_pin_count negative=[llength $negative_rows]"
  }
  set negative_rows [lsort -ascii -index 0 $negative_rows]

  set stream [open $path w]
  puts $stream "schema\tnpc-rv64-opensta-fp-negative-slack-inventory-v1"
  puts $stream "inventory_semantics\tcomplete_fp_arith_hierarchical_pin_inventory_not_unique_timing_paths"
  puts $stream "matched_pin_count\t$matched_pin_count"
  puts $stream "numeric_slack_pin_count\t$numeric_slack_pin_count"
  puts $stream "negative_slack_pin_count\t[llength $negative_rows]"
  puts $stream "full_name\tslack_max_ns"
  foreach row $negative_rows {
    puts $stream "[lindex $row 0]\t[lindex $row 1]"
  }
  close $stream
}

proc write_fp_internal_timing_paths {path} {
  set fp_pins [get_pins -hierarchical -quiet *u_fp_arith*]
  set matched_pin_count 0
  foreach pin $fp_pins {
    incr matched_pin_count
  }
  if {$matched_pin_count == 0} {
    error "FP internal timing-path query has no u_fp_arith pins"
  }
  report_checks -path_delay max -from $fp_pins -to $fp_pins \
    -group_path_count 10 -sort_by_slack -digits 9 > $path
  if {![file exists $path] || [file size $path] == 0} {
    error "FP internal timing-path report is empty"
  }
}

set netlist [file normalize [require_env V15P_STA_NETLIST]]
set out_dir [file normalize [require_env V15P_STA_OUT_DIR]]
set std_lib [file normalize [require_env V15P_STA_STD_LIB]]
set macro_raw [require_env V15P_STA_MACRO_LIBS]
set expected_macro_count_raw [require_env V15P_STA_EXPECTED_MACRO_LIB_COUNT]
set mapped_artifact_profile [require_env V15P_STA_MAPPED_ARTIFACT_PROFILE]
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
if {$mapped_artifact_profile ni {none bpu-local-pht-v1 fp-arith-children-v1}} {
  error "unsupported mapped artifact profile: $mapped_artifact_profile"
}
if {![regexp {^[1-9][0-9]*$} $expected_macro_count_raw]} {
  error "traceable mapped STA expected macro-lib count must be a positive integer, got: $expected_macro_count_raw"
}
set expected_macro_count [expr {int($expected_macro_count_raw)}]
foreach required_file [list $netlist $std_lib $opensta_binary] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
}

file mkdir $out_dir
set setup_path [file join $out_dir opensta-check-setup.txt]
set top40_path [file join $out_dir opensta-top40.rpt]
set power_path [file join $out_dir opensta-power.rpt]
set bpu_negative_slack_path [file join $out_dir opensta-bpu-negative-slack.tsv]
set bpu_update_fanout_path [file join $out_dir opensta-bpu-update-fanout.tsv]
set fp_negative_slack_path [file join $out_dir opensta-fp-negative-slack.tsv]
set fp_internal_paths_path [file join $out_dir opensta-fp-internal-paths.rpt]
set complete_path [file join $out_dir opensta-complete.txt]
foreach stale [list $setup_path $top40_path $power_path \
                    $bpu_negative_slack_path $bpu_update_fanout_path \
                    $fp_negative_slack_path $fp_internal_paths_path \
                    $complete_path] {
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
if {$macro_count != $expected_macro_count} {
  error "traceable mapped STA macro-lib projection mismatch: expected $expected_macro_count, got $macro_count"
}

if {[catch {
  read_verilog $netlist
  link_design NpcTop
  create_clock -name core_clock -period $period_ns [get_ports clk]
  check_setup -verbose > $setup_path
  report_checks -path_delay max -group_path_count 40 -sort_by_slack -digits 9 > $top40_path
  report_tns -max -digits 9 >> $top40_path
  report_wns -max -digits 9 >> $top40_path
  switch -- $mapped_artifact_profile {
    none {}
    bpu-local-pht-v1 {
      write_bpu_negative_slack_inventory $bpu_negative_slack_path
      write_bpu_update_fanout_inventory $bpu_update_fanout_path
    }
    fp-arith-children-v1 {
      write_fp_negative_slack_inventory $fp_negative_slack_path
      write_fp_internal_timing_paths $fp_internal_paths_path
    }
    default {
      error "unsupported mapped artifact profile after link: $mapped_artifact_profile"
    }
  }
  report_power > $power_path
  write_note $complete_path "status=COMPLETE
mode=$mode
period_ns=$period_ns
top=NpcTop
clock_port=clk
clock_name=core_clock
mapped_artifact_profile=$mapped_artifact_profile
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
