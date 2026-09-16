# NpcTop timing evidence for the inline FP wrapper and five known OOC macros.
# Boundary queries are generated from the Registry exact instance/pin contract;
# every selected object is intersected with the real OpenSTA pin/port/register
# collections before it may contribute evidence.
# Per-bit child Liberty is authoritative: structural-constant macro outputs
# keep their literal function and never receive a synthetic top-level timing
# arc or timing override.

proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

proc require_regular_file {path label} {
  set normalized [file normalize $path]
  if {![file exists $normalized] || [file type $normalized] ne "file" ||
      [file size $normalized] == 0} {
    error "$label is not a non-empty regular file: $normalized"
  }
  return $normalized
}

proc finite_decimal {value label} {
  if {![regexp {^-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$} $value]} {
    error "$label is not finite decimal: $value"
  }
  return [expr {double($value)}]
}

proc collection_count {objects} {
  set count 0
  foreach object $objects { incr count }
  return $count
}

proc canonical_fp_name {object} {
  set name [get_full_name $object]
  if {$name eq "" || [regexp {[\t\r\n;]} $name]} {
    error "timing object name is empty or non-canonical"
  }
  regsub -all {\.} $name {/} name
  if {[regexp {(u_fp_arith/.*)$} $name -> tail]} { return $tail }
  return $name
}

proc object_name_list {objects} {
  set names {}
  foreach object $objects { lappend names [canonical_fp_name $object] }
  return [lsort -unique $names]
}

proc parse_family_widths {raw label} {
  set result [dict create]
  foreach entry $raw {
    if {![regexp {^([A-Za-z_][A-Za-z0-9_]*)=([1-9][0-9]*)$} $entry -> name width]} {
      error "$label contains malformed family width: $entry"
    }
    if {[dict exists $result $name]} { error "$label duplicates $name" }
    dict set result $name $width
  }
  if {[dict size $result] == 0} { error "$label is empty" }
  return $result
}

proc family_match {candidate family} {
  return [expr {$candidate eq $family ||
    [regexp "^${family}(?:\\\[[0-9]+\\\]|__v[0-9]+)$" $candidate]}]
}

proc actual_pin_crosscheck {pin direction label} {
  set full [get_full_name $pin]
  set exact [get_pins -hierarchical -quiet $full]
  set exact_name ""
  foreach matched $exact { set exact_name [get_full_name $matched] }
  if {[collection_count $exact] != 1 || $exact_name ne $full ||
      [get_property $pin direction] ne $direction} {
    error "$label is not exactly one real $direction OpenSTA pin: $full"
  }
}

proc actual_parent_cell_crosscheck {pin instance_path family label} {
  set parents [get_cells -quiet -of_objects $pin]
  set parent_count 0
  set parent_name ""
  foreach parent $parents {
    incr parent_count
    set parent_name [canonical_fp_name $parent]
  }
  set prefix "${instance_path}/"
  if {$parent_count != 1 || ![string match "${prefix}*" $parent_name]} {
    error "$label does not belong to the exact backend owner: $parent_name"
  }
  set tail [string range $parent_name [string length $prefix] end]
  if {![regexp "(?:^|[/._])${family}(?:$|\\\[|__v|[/._$])" $tail]} {
    error "$label parent is outside register family $family: $parent_name"
  }
}

proc exact_macro_pin_objects {instance_path widths direction} {
  set result {}
  set counts [dict create]
  foreach family [dict keys $widths] { dict set counts $family 0 }
  foreach pin [get_pins -hierarchical -quiet *] {
    set name [canonical_fp_name $pin]
    set prefix "${instance_path}/"
    if {![string match "${prefix}*" $name]} { continue }
    set tail [string range $name [string length $prefix] end]
    foreach family [dict keys $widths] {
      if {[family_match $tail $family]} {
        actual_pin_crosscheck $pin $direction "$instance_path/$family"
        lappend result $pin
        dict incr counts $family
        break
      }
    }
  }
  if {$counts ne $widths} {
    error "macro exact pin cardinality drifted at $instance_path: $counts != $widths"
  }
  return $result
}

proc exact_wrapper_register_d_objects {instance_path widths} {
  set result {}
  set counts [dict create]
  foreach family [dict keys $widths] { dict set counts $family 0 }
  foreach pin [all_registers -data_pins] {
    set name [canonical_fp_name $pin]
    set prefix "${instance_path}/"
    if {![string match "${prefix}*" $name]} { continue }
    set tail [string range $name [string length $prefix] end]
    foreach family [dict keys $widths] {
      if {[regexp "(?:^|[/._])${family}(?:$|\\\[|__v|[/._$])" $tail]} {
        actual_pin_crosscheck $pin input "$instance_path/$family register-D"
        lappend result $pin
        dict incr counts $family
        break
      }
    }
  }
  if {$counts ne $widths} {
    error "wrapper register-D cardinality drifted: $counts != $widths"
  }
  return $result
}

proc exact_backend_completion_register_d_objects {instance_path widths} {
  set result {}
  set counts [dict create]
  foreach family [dict keys $widths] { dict set counts $family 0 }
  foreach pin [all_registers -data_pins] {
    set name [canonical_fp_name $pin]
    set prefix "${instance_path}/"
    if {![string match "${prefix}*" $name]} { continue }
    set tail [string range $name [string length $prefix] end]
    foreach family [dict keys $widths] {
      if {[regexp "(?:^|[/._])${family}(?:$|\\\[|__v|[/._$])" $tail]} {
        actual_pin_crosscheck $pin input "$instance_path/$family register-D"
        actual_parent_cell_crosscheck \
          $pin $instance_path $family "$instance_path/$family register-D"
        lappend result $pin
        dict incr counts $family
        break
      }
    }
  }
  if {$counts ne $widths} {
    error "backend completion register-D cardinality drifted: $counts != $widths"
  }
  return $result
}

proc collect_boundary {boundary from_objects to_objects path_delay start_class end_class} {
  if {[collection_count $from_objects] == 0 || [collection_count $to_objects] == 0} {
    error "$boundary query has an empty exact object collection"
  }
  set paths [find_timing_paths -from $from_objects -to $to_objects \
    -path_delay $path_delay -group_count 100000 -sort_by_slack]
  set count 0
  set negative 0
  set worst_path ""
  set worst_slack 0.0
  foreach path $paths {
    set slack [finite_decimal [get_property $path slack] "$boundary slack"]
    if {$count == 0 || $slack < $worst_slack} {
      set worst_path $path
      set worst_slack $slack
    }
    if {$slack < 0.0} { incr negative }
    incr count
  }
  if {$count == 0 || $worst_path eq ""} { error "$boundary has no real timing path" }
  set from_names [object_name_list $from_objects]
  set to_names [object_name_list $to_objects]
  set startpoint [canonical_fp_name [get_property $worst_path startpoint]]
  set endpoint [canonical_fp_name [get_property $worst_path endpoint]]
  if {$startpoint ni $from_names || $endpoint ni $to_names} {
    error "$boundary worst path escapes its exact actual object sets"
  }
  return [list $boundary OBSERVED $count $negative [format %.12g $worst_slack] \
    $startpoint $endpoint $start_class $end_class \
    [join $from_names {;}] [join $to_names {;}]]
}

set analysis [require_env FP_OOC_ANALYSIS]
if {$analysis ni {max min}} { error "FP_OOC_ANALYSIS must be max or min" }
if {[require_env FP_OOC_PROFILE] ne "fp-arith-ooc-composite-v1"} {
  error "top OpenSTA profile differs from fp-arith-ooc-composite-v1"
}
set run_id [require_env FP_OOC_RUN_ID]
if {![regexp {^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$} $run_id]} {
  error "FP OOC run_id is invalid"
}
set design_id [require_env FP_OOC_DESIGN_ID]
if {![regexp {^sha256:[0-9a-f]{64}$} $design_id]} { error "FP OOC design_id is invalid" }
set period_ns [require_env FP_OOC_PERIOD_NS]
if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "FP OOC top requires exact 5.0ns clock"
}
set contract_tcl [require_regular_file [require_env FP_OOC_TOP_BOUNDARY_CONTRACT_TCL] boundary_contract]
source $contract_tcl
if {![info exists fp_ooc_boundary_contract] || [llength $fp_ooc_boundary_contract] != 5} {
  error "Registry top boundary contract must contain exactly five rows"
}
set netlist [require_regular_file [require_env FP_OOC_NETLIST] top_netlist]
set std_lib [require_regular_file [require_env FP_OOC_STD_LIB] standard_cell_lib]
set macro_raw [require_env FP_OOC_MACRO_LIBS]
set placeholder_raw [require_env FP_OOC_PLACEHOLDER_LIBS]
set out_dir [file normalize [require_env FP_OOC_OUT_DIR]]
file mkdir $out_dir
set inventory [file join $out_dir "top-boundary-${analysis}.tsv"]
set report [file join $out_dir "top-boundary-${analysis}.rpt"]
file delete -force $inventory $report

read_liberty $std_lib
set macro_count 0
foreach liberty [split $macro_raw ":"] {
  read_liberty [require_regular_file $liberty known_ooc_liberty]
  incr macro_count
}
if {$macro_count != 5} { error "top requires exactly five known OOC Liberty models" }
set placeholder_count 0
foreach liberty [split $placeholder_raw ":"] {
  read_liberty [require_regular_file $liberty unknown_placeholder_liberty]
  incr placeholder_count
}
if {$placeholder_count != 3} {
  error "top requires exactly three unknown-placeholder Liberty module families"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

set rows {}
set seen [dict create]
foreach contract $fp_ooc_boundary_contract {
  if {[llength $contract] != 8} { error "top boundary contract row is malformed" }
  lassign $contract boundary source_instance source_class source_raw \
    endpoint_kind endpoint_instance endpoint_class endpoint_raw
  if {[dict exists $seen $boundary]} { error "top boundary contract duplicates $boundary" }
  dict set seen $boundary 1
  set source_widths [parse_family_widths $source_raw "$boundary source"]
  set endpoint_widths [parse_family_widths $endpoint_raw "$boundary endpoint"]
  set from_objects [exact_macro_pin_objects $source_instance $source_widths output]
  if {$endpoint_kind eq "known_ooc_macro_input"} {
    set to_objects [exact_macro_pin_objects $endpoint_instance $endpoint_widths input]
  } elseif {$endpoint_kind eq "wrapper_register_d"} {
    set to_objects [exact_wrapper_register_d_objects $endpoint_instance $endpoint_widths]
  } elseif {$endpoint_kind eq "backend_completion_register_d"} {
    set to_objects [exact_backend_completion_register_d_objects \
      $endpoint_instance $endpoint_widths]
  } else {
    error "$boundary endpoint kind/instance is invalid"
  }
  lappend rows [collect_boundary $boundary $from_objects $to_objects \
    $analysis $source_class $endpoint_class]
}

set stream [open $inventory w]
puts $stream "schema\tnpc-rv64-fp-ooc-timing-inventory-v1"
puts $stream "run_id\t$run_id"
puts $stream "design_id\t$design_id"
puts $stream "subject\tNpcTop"
puts $stream "analysis\t$analysis"
puts $stream "path_class\tstatus\tpath_count\tnegative_path_count\tworst_slack_ns\tstartpoint\tendpoint\tstartpoint_object_class\tendpoint_object_class\tfrom_objects\tto_objects"
foreach row $rows { puts $stream [join $row "\t"] }
close $stream

report_checks -path_delay $analysis -group_path_count 1000 \
  -sort_by_slack -digits 9 > $report
if {![file exists $inventory] || [file size $inventory] == 0 ||
    ![file exists $report] || [file size $report] == 0} {
  error "FP OOC top timing artifacts are incomplete"
}
exit
