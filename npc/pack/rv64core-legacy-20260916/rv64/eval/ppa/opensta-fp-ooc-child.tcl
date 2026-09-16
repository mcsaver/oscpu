# OpenSTA max/min evidence for one registered sequential FP child.  Every
# declared port family is queried separately; D pins are endpoints only and
# real register Q/output pins are the only register launch objects.

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

proc tsv_atom {value label} {
  if {$value eq "" || [regexp {[\t\r\n;]} $value]} {
    error "$label is empty or contains a TSV/list delimiter"
  }
  return $value
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

proc write_query_progress {phase query_index kind path_delay endpoint_cap group_cap \
                           pathend_count cumulative_pathends cumulative_validations status} {
  global fp_ooc_progress_stream
  puts $fp_ooc_progress_stream [join [list \
    $phase $query_index $kind $path_delay $endpoint_cap $group_cap \
    $pathend_count $cumulative_pathends $cumulative_validations $status] "\t"]
  flush $fp_ooc_progress_stream
}

proc configure_query_budget {module register_d_count nonclock_input_count \
                             output_count dynamic_output_count} {
  global fp_ooc_progress_stream fp_ooc_expected_find_calls
  global fp_ooc_pathend_limit fp_ooc_validation_limit
  global fp_ooc_find_calls fp_ooc_pathend_count fp_ooc_validation_count
  global fp_ooc_query_open fp_ooc_current_query_index
  global fp_ooc_current_pathend_count fp_ooc_current_validation_start
  set path_class_count [expr {$module eq "OooFpMulProductPipe" ? 3 : 4}]
  set register_path_class_multiplier \
    [expr {$module eq "OooFpMulProductPipe" ? 2 : 3}]
  set fp_ooc_expected_find_calls \
    [expr {$path_class_count + 2 * $nonclock_input_count + 1}]
  set fp_ooc_pathend_limit [expr {
    $register_path_class_multiplier * $register_d_count +
    2 * $dynamic_output_count + 2 * $nonclock_input_count
  }]
  set fp_ooc_validation_limit $fp_ooc_pathend_limit
  set fp_ooc_find_calls 0
  set fp_ooc_pathend_count 0
  set fp_ooc_validation_count 0
  set fp_ooc_query_open 0
  set fp_ooc_current_query_index 0
  set fp_ooc_current_pathend_count 0
  set fp_ooc_current_validation_start 0

  if {$module eq "OooFpAddSubPipe" &&
      ($register_d_count != 608 || $nonclock_input_count != 134 ||
       $output_count != 138 || $dynamic_output_count != 136 ||
       $fp_ooc_expected_find_calls != 273 || $fp_ooc_pathend_limit != 2364)} {
    error "OooFpAddSubPipe current-design query-budget dimensions drifted"
  }
  foreach pair [list \
      [list expected_find_calls $fp_ooc_expected_find_calls] \
      [list pathend_limit $fp_ooc_pathend_limit] \
      [list validation_limit $fp_ooc_validation_limit] \
      [list register_d_endpoints $register_d_count] \
      [list nonclock_input_bits $nonclock_input_count] \
      [list output_bits $output_count] \
      [list dynamic_output_bits $dynamic_output_count]] {
    puts $fp_ooc_progress_stream [join $pair "\t"]
  }
  puts $fp_ooc_progress_stream \
    "phase\tquery_index\tkind\tpath_delay\tendpoint_path_count\tgroup_path_count\tpathend_count\tcumulative_pathends\tcumulative_validations\tstatus"
  flush $fp_ooc_progress_stream
}

proc budgeted_find_timing_paths {from_objects to_objects path_delay \
                                 endpoint_path_count group_path_count phase kind} {
  global fp_ooc_expected_find_calls fp_ooc_find_calls fp_ooc_pathend_count
  global fp_ooc_validation_count fp_ooc_query_open
  global fp_ooc_current_query_index fp_ooc_current_pathend_count
  global fp_ooc_current_validation_start
  if {$fp_ooc_query_open} {
    error "timing query started before the previous PathEnds were materialized"
  }
  if {$endpoint_path_count != 1 || $group_path_count < 1} {
    error "timing query uses an invalid endpoint/group path budget"
  }
  incr fp_ooc_find_calls
  if {$fp_ooc_find_calls > $fp_ooc_expected_find_calls} {
    error "timing query count exceeds the registered budget"
  }
  set fp_ooc_query_open 1
  set fp_ooc_current_query_index $fp_ooc_find_calls
  set fp_ooc_current_validation_start $fp_ooc_validation_count
  write_query_progress $phase $fp_ooc_current_query_index $kind $path_delay \
    $endpoint_path_count $group_path_count - $fp_ooc_pathend_count \
    $fp_ooc_validation_count BEGIN
  set paths [find_timing_paths -from $from_objects -to $to_objects \
    -path_delay $path_delay -endpoint_path_count $endpoint_path_count \
    -group_path_count $group_path_count -sort_by_slack]
  set fp_ooc_current_pathend_count [collection_count $paths]
  return $paths
}

proc complete_timing_query {paths phase kind path_delay endpoint_cap group_cap} {
  global fp_ooc_pathend_limit fp_ooc_validation_limit
  global fp_ooc_pathend_count fp_ooc_validation_count fp_ooc_query_open
  global fp_ooc_current_query_index fp_ooc_current_pathend_count
  global fp_ooc_current_validation_start
  if {!$fp_ooc_query_open ||
      [collection_count $paths] != $fp_ooc_current_pathend_count} {
    error "timing query completion does not match its Search result"
  }
  set validation_delta \
    [expr {$fp_ooc_validation_count - $fp_ooc_current_validation_start}]
  if {$validation_delta != $fp_ooc_current_pathend_count} {
    error "each Search-owned PathEnd must be materialized exactly once"
  }
  incr fp_ooc_pathend_count $fp_ooc_current_pathend_count
  if {$fp_ooc_pathend_count > $fp_ooc_pathend_limit ||
      $fp_ooc_validation_count > $fp_ooc_validation_limit} {
    error "runtime PathEnd/validation count exceeds the registered budget"
  }
  write_query_progress $phase $fp_ooc_current_query_index $kind $path_delay \
    $endpoint_cap $group_cap $fp_ooc_current_pathend_count \
    $fp_ooc_pathend_count $fp_ooc_validation_count COMPLETE
  set fp_ooc_query_open 0
}

proc verify_query_budget {} {
  global fp_ooc_expected_find_calls fp_ooc_find_calls fp_ooc_pathend_limit
  global fp_ooc_validation_limit fp_ooc_pathend_count fp_ooc_validation_count
  global fp_ooc_query_open
  if {$fp_ooc_query_open || $fp_ooc_find_calls != $fp_ooc_expected_find_calls ||
      $fp_ooc_pathend_count > $fp_ooc_pathend_limit ||
      $fp_ooc_validation_count > $fp_ooc_validation_limit ||
      $fp_ooc_pathend_count != $fp_ooc_validation_count} {
    error "query budget did not close at its exact terminal state"
  }
}

proc object_name {object} {
  return [tsv_atom [get_full_name $object] timing_object]
}

proc object_name_list {objects} {
  set names {}
  foreach object $objects { lappend names [object_name $object] }
  return [lsort -unique $names]
}

proc normalized_object_method_name {object label} {
  foreach method {as_string name} {
    if {![catch {$object $method} rendered] && $rendered ne ""} {
      set normalized [string tolower [string trim $rendered]]
      return [regsub -all {[_-]+} $normalized { }]
    }
  }
  set rendered [string trim $object]
  if {$rendered eq "" || [regexp {^_p_} $rendered]} {
    error "$label does not expose a canonical OpenSTA name"
  }
  set normalized [string tolower $rendered]
  return [regsub -all {[_-]+} $normalized { }]
}

proc path_end_min_max_name {path_end label} {
  if {[catch {$path_end min_max} object]} {
    error "$label lacks PathEnd min_max"
  }
  return [normalized_object_method_name $object "$label min_max"]
}

proc path_end_check_role_name {path_end label} {
  if {[catch {$path_end check_role} object]} {
    error "$label lacks PathEnd check_role"
  }
  return [normalized_object_method_name $object "$label check_role"]
}

proc validate_path_end {path_end label expected_min_max expected_roles from_names to_names} {
  # PathEnd exposes the query identity and its Path point list.  Numeric
  # arrival/slack properties below are already rendered in the configured UI
  # nanosecond domain; never apply a second UI-time conversion or mix in a raw
  # SWIG Path arrival method.
  set actual_min_max [path_end_min_max_name $path_end $label]
  if {$actual_min_max ne $expected_min_max} {
    error "$label min_max is $actual_min_max, expected $expected_min_max"
  }
  set actual_role [path_end_check_role_name $path_end $label]
  if {$actual_role ni $expected_roles} {
    error "$label check_role is $actual_role, expected one of $expected_roles"
  }
  set slack_ns [finite_decimal [get_property $path_end slack] "$label constrained slack UI-ns"]
  set endpoint_clock [get_property $path_end endpoint_clock]
  if {$endpoint_clock eq "" || $endpoint_clock eq "NULL"} {
    error "$label is not a constrained PathEnd"
  }

  set startpoint [object_name [get_property $path_end startpoint]]
  set endpoint [object_name [get_property $path_end endpoint]]
  if {$startpoint ni $from_names || $endpoint ni $to_names} {
    error "$label escapes its actual query object sets"
  }
  set points [get_property $path_end points]
  if {[collection_count $points] < 2} {
    error "$label does not expose a multi-point PathEnd points list"
  }
  set first_point [lindex $points 0]
  set last_point [lindex $points end]
  set first_pin [object_name [get_property $first_point pin]]
  set last_pin [object_name [get_property $last_point pin]]
  if {$first_pin ne $startpoint || $last_pin ne $endpoint} {
    error "$label PathEnd startpoint/endpoint differ from points first/last pins"
  }
  set first_arrival_ns [finite_decimal \
    [get_property $first_point arrival] "$label first Path arrival UI-ns"]
  set endpoint_arrival_ns [finite_decimal \
    [get_property $last_point arrival] "$label endpoint Path arrival UI-ns"]
  # OpenSTA 3.1 exposes arrival/slack on PathEnd but does not expose a Tcl
  # `required` property for this object.  Recover only the ordinary scalar
  # required-time context from the timing identity; this is an oracle for
  # uniform-vs-nonuniform constraints, never a path-delay derivation.
  set required_ns [expr {$expected_min_max eq "max" ?
    $endpoint_arrival_ns + $slack_ns : $endpoint_arrival_ns - $slack_ns}]
  set observation [dict create \
    slack_ns $slack_ns startpoint $startpoint endpoint $endpoint \
    first_arrival_ns $first_arrival_ns endpoint_arrival_ns $endpoint_arrival_ns \
    required_ns $required_ns]
  if {[info exists ::fp_ooc_query_open] && $::fp_ooc_query_open} {
    incr ::fp_ooc_validation_count
  }
  return $observation
}

proc measured_path_delay_ns {observation label measurement} {
  global fp_ooc_input_seed_ns fp_ooc_clock_origin_ns
  global fp_ooc_clock_source_latency_ns fp_ooc_clock_network_latency_ns
  global fp_ooc_clock_insertion_ns fp_ooc_clock_propagated
  set first_arrival_ns [dict get $observation first_arrival_ns]
  set endpoint_arrival_ns [dict get $observation endpoint_arrival_ns]
  set tolerance_ns 1.0e-9
  if {$measurement eq "input_to_register_d"} {
    if {abs($fp_ooc_input_seed_ns) > $tolerance_ns ||
        abs($first_arrival_ns - $fp_ooc_input_seed_ns) > $tolerance_ns} {
      error "$label input Path arrival seed is not explicit zero UI-ns"
    }
    set delay_ns [expr {$endpoint_arrival_ns - $first_arrival_ns}]
    if {$delay_ns < -$tolerance_ns} {
      error "$label input-to-register-D Path arrival increment is negative"
    }
    return [expr {max(0.0, $delay_ns)}]
  }
  if {$measurement ne "register_q_to_output"} {
    error "$label has unknown Path arrival measurement basis: $measurement"
  }
  if {abs($fp_ooc_clock_origin_ns) > $tolerance_ns ||
      abs($fp_ooc_clock_source_latency_ns) > $tolerance_ns ||
      abs($fp_ooc_clock_network_latency_ns) > $tolerance_ns ||
      abs($fp_ooc_clock_insertion_ns) > $tolerance_ns ||
      $fp_ooc_clock_propagated != 0} {
    error "$label clock-to-Q basis is not zero-origin zero-latency unpropagated"
  }
  if {$first_arrival_ns <= $tolerance_ns ||
      $endpoint_arrival_ns + $tolerance_ns < $first_arrival_ns} {
    error "$label does not retain cumulative register clock-to-Q Path arrival"
  }
  # The Q point already contains the real register clock-to-Q arc.  Subtracting
  # it would leave only Q-to-port combinational delay, so use the endpoint's
  # cumulative arrival from the explicit zero clock edge.
  return $endpoint_arrival_ns
}

proc parse_port_contract {raw label} {
  set result [dict create]
  foreach entry [split $raw " "] {
    if {![regexp {^([A-Za-z_][A-Za-z0-9_]*)=([1-9][0-9]*)$} $entry -> name width]} {
      error "$label contains a malformed name=width entry: $entry"
    }
    if {[dict exists $result $name]} { error "$label duplicates $name" }
    dict set result $name $width
  }
  if {[dict size $result] == 0} { error "$label is empty" }
  return $result
}

proc exact_port_family {family width direction} {
  if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $family]} {
    error "port family is not a canonical identifier: $family"
  }
  if {![string is integer -strict $width] || $width < 1} {
    error "port family $family has invalid width: $width"
  }
  if {$direction ni {input output}} {
    error "port family $family has invalid direction: $direction"
  }

  # Brace-quoted format templates prevent Tcl from treating [0-9] as a
  # command substitution while retaining the three mapped-port spellings
  # emitted by supported Yosys/OpenSTA versions.
  set bracket_pattern [format {^%s\[([0-9]+)\]$} $family]
  set splitnets_pattern [format {^%s__v([0-9]+)$} $family]
  set underscore_pattern [format {^%s_([0-9]+)_$} $family]
  set selected_style ""
  set indexed_ports [dict create]
  foreach port [get_ports *] {
    set name [get_full_name $port]
    set style ""
    set index_text ""
    if {$name eq $family} {
      set style scalar
      set index_text 0
    } elseif {[regexp $bracket_pattern $name -> index_text]} {
      set style bracket
    } elseif {[regexp $splitnets_pattern $name -> index_text]} {
      set style splitnets
    } elseif {[regexp $underscore_pattern $name -> index_text]} {
      set style underscore
    } else {
      continue
    }

    if {[get_property $port direction] ne $direction} {
      error "port family $family contains wrong-direction object: $name"
    }
    if {![regexp {^(?:0|[1-9][0-9]*)$} $index_text]} {
      error "port family $family contains noncanonical index: $name"
    }
    scan $index_text %d index
    if {$index < 0 || $index >= $width} {
      error "port family $family index is outside 0..[expr {$width - 1}]: $name"
    }
    if {$selected_style ne "" && $selected_style ne $style} {
      error "port family $family mixes $selected_style and $style representations"
    }
    set selected_style $style
    if {[dict exists $indexed_ports $index]} {
      error "port family $family duplicates index $index"
    }
    dict set indexed_ports $index $port
  }

  if {$width == 1 && $selected_style ne "scalar"} {
    error "width-one port family $family must use its exact scalar name"
  }
  if {$width > 1 && $selected_style ni {bracket splitnets underscore}} {
    error "vector port family $family must use one indexed representation"
  }
  set result {}
  for {set index 0} {$index < $width} {incr index} {
    if {![dict exists $indexed_ports $index]} {
      error "port family $family is missing index $index"
    }
    lappend result [dict get $indexed_ports $index]
  }
  if {[collection_count $result] != $width} {
    error "port family $family/$direction cardinality differs from $width"
  }
  return $result
}

proc validate_output_bit_driver_contract {outputs output_objects} {
  if {![info exists ::fp_ooc_output_bit_driver_contract_id] ||
      ![regexp {^[0-9a-f]{64}$} $::fp_ooc_output_bit_driver_contract_id]} {
    error "output-bit driver contract id is missing or invalid"
  }
  if {![info exists ::fp_ooc_output_bit_driver_contract]} {
    error "output-bit driver contract rows are missing"
  }
  set expected 0
  foreach family [dict keys $outputs] { incr expected [dict get $outputs $family] }
  if {[llength $::fp_ooc_output_bit_driver_contract] != $expected} {
    error "output-bit driver contract row count differs from $expected"
  }
  set result [dict create]
  foreach row $::fp_ooc_output_bit_driver_contract {
    if {[llength $row] != 6} { error "output-bit driver row field count drifted" }
    lassign $row family index object_name classification value binding_sha
    if {![dict exists $outputs $family]} {
      error "output-bit driver row names undeclared family $family"
    }
    set width [dict get $outputs $family]
    if {![string is integer -strict $index] || $index < 0 || $index >= $width} {
      error "output-bit driver row index is invalid: $family/$index"
    }
    set key [list $family $index]
    if {[dict exists $result $key]} {
      error "output-bit driver contract duplicates $family/$index"
    }
    set actual [object_name [lindex [dict get $output_objects $family] $index]]
    if {$object_name ne $actual} {
      error "output-bit driver OpenSTA object drifted: $family/$index"
    }
    if {$classification ni {DYNAMIC CONSTANT_0 CONSTANT_1} ||
        ![regexp {^[0-9a-f]{64}$} $binding_sha]} {
      error "output-bit driver class/binding is invalid: $family/$index"
    }
    if {($classification eq "DYNAMIC" && $value ne "-") ||
        ($classification eq "CONSTANT_0" && $value ne "0") ||
        ($classification eq "CONSTANT_1" && $value ne "1")} {
      error "output-bit driver class/value disagree: $family/$index"
    }
    dict set result $key [dict create family $family index $index \
      object [lindex [dict get $output_objects $family] $index] \
      object_name $object_name classification $classification value $value \
      driver_binding_sha256 $binding_sha]
  }
  if {[dict size $result] != $expected} {
    error "output-bit driver contract does not cover every output bit"
  }
  return $result
}

proc register_d_pins {} {
  set result [all_registers -data_pins]
  if {[collection_count $result] == 0} { error "register-D collection is empty" }
  return $result
}

proc register_q_pins {} {
  set result {}
  foreach cell [all_registers -cells] {
    foreach pin [get_pins -of_objects $cell] {
      if {[get_property $pin direction] eq "output"} { lappend result $pin }
    }
  }
  if {[collection_count $result] == 0} { error "register-Q collection is empty" }
  return $result
}

proc collect_paths {from_objects to_objects path_delay endpoint_cap group_cap phase kind label} {
  set paths [budgeted_find_timing_paths $from_objects $to_objects $path_delay \
    $endpoint_cap $group_cap $phase $kind]
  if {[collection_count $paths] == 0} {
    complete_timing_query $paths $phase $kind $path_delay $endpoint_cap $group_cap
    error "$label has no real timing path"
  }
  return $paths
}

proc collect_path_class {path_class from_objects to_objects path_delay start_class end_class} {
  if {[collection_count $from_objects] == 0 || [collection_count $to_objects] == 0} {
    error "$path_class query has an empty endpoint collection"
  }
  set endpoint_cap 1
  set group_cap [collection_count $to_objects]
  set paths [collect_paths $from_objects $to_objects $path_delay \
    $endpoint_cap $group_cap path_class $path_class $path_class]
  set count 0
  set negative 0
  set worst_slack 0.0
  set worst_startpoint ""
  set worst_endpoint ""
  set from_names [object_name_list $from_objects]
  set to_names [object_name_list $to_objects]
  set expected_role [expr {$end_class eq "PORT" ?
    ($path_delay eq "max" ? "output setup" : "output hold") :
    ($path_delay eq "max" ? "setup" : "hold")}]
  foreach path $paths {
    set observation [validate_path_end $path "$path_class path" $path_delay \
      [list $expected_role] $from_names $to_names]
    set slack [dict get $observation slack_ns]
    if {$count == 0 || $slack < $worst_slack} {
      set worst_slack $slack
      set worst_startpoint [dict get $observation startpoint]
      set worst_endpoint [dict get $observation endpoint]
    }
    if {$slack < 0.0} { incr negative }
    incr count
  }
  complete_timing_query $paths path_class $path_class $path_delay \
    $endpoint_cap $group_cap
  set startpoint $worst_startpoint
  set endpoint $worst_endpoint
  if {$startpoint ni $from_names || $endpoint ni $to_names} {
    error "$path_class worst path escapes its actual query object sets"
  }
  return [list $path_class OBSERVED $count $negative \
    [format %.12g $worst_slack] $startpoint $endpoint $start_class $end_class \
    [join $from_names {;}] [join $to_names {;}]]
}

proc collect_arc_family {arc_class family family_objects target_objects path_delay declared source_class endpoint_class} {
  set family_names [object_name_list $family_objects]
  set target_names [object_name_list $target_objects]
  if {[llength $family_names] != $declared} {
    error "$arc_class/$family does not select every declared port bit"
  }
  set observed_names {}
  set count 0
  set selected_valid 0
  set selected_slack 0.0
  set selected_delay 0.0
  set selected_startpoint ""
  set selected_endpoint ""
  foreach object $family_objects {
    set object_name [object_name $object]
    set kind "$arc_class/$family/[llength $observed_names]"
    if {$arc_class eq "clk_to_q"} {
      set paths [collect_paths $target_objects [list $object] $path_delay \
        1 1 input_arc $kind "$arc_class/$family"]
    } else {
      set paths [collect_paths [list $object] $target_objects $path_delay \
        1 1 input_arc $kind "$arc_class/$family"]
    }
    lappend observed_names $object_name
    foreach path $paths {
      if {$arc_class eq "clk_to_q"} {
        set from_names $target_names
        set to_names [list $object_name]
        set expected_role [expr {$path_delay eq "max" ?
          "output setup" : "output hold"}]
        set measurement register_q_to_output
      } else {
        set from_names [list $object_name]
        set to_names $target_names
        set expected_role [expr {$arc_class eq "setup" ? "setup" : "hold"}]
        set measurement input_to_register_d
      }
      set observation [validate_path_end $path "$arc_class/$family path" \
        $path_delay [list $expected_role] $from_names $to_names]
      set slack [dict get $observation slack_ns]
      set delay [measured_path_delay_ns $observation "$arc_class/$family" \
        $measurement]
      set path_startpoint [dict get $observation startpoint]
      set path_endpoint [dict get $observation endpoint]
      if {!$selected_valid ||
          ($arc_class ne "clk_to_q" && $slack < $selected_slack) ||
          ($arc_class eq "clk_to_q" && $path_delay eq "max" && $delay > $selected_delay) ||
          ($arc_class eq "clk_to_q" && $path_delay eq "min" && $delay < $selected_delay)} {
        set selected_valid 1
        set selected_slack $slack
        set selected_delay $delay
        set selected_startpoint $path_startpoint
        set selected_endpoint $path_endpoint
      }
      incr count
    }
    complete_timing_query $paths input_arc $kind $path_delay 1 1
  }
  set observed_names [lsort -unique $observed_names]
  if {$observed_names ne $family_names || [llength $observed_names] != $declared} {
    error "$arc_class/$family observed cardinality is incomplete"
  }
  if {!$selected_valid} {
    error "$arc_class/$family has no materialized PathEnd observation"
  }
  set startpoint $selected_startpoint
  set endpoint $selected_endpoint
  if {$arc_class eq "clk_to_q"} {
    if {$endpoint ni $family_names} { error "$arc_class/$family endpoint is forged" }
  } elseif {$startpoint ni $family_names} {
    error "$arc_class/$family startpoint is forged"
  }
  return [list $arc_class $family $path_delay $declared [llength $observed_names] \
    $count [format %.12g $selected_delay] [format %.12g $selected_slack] \
    $source_class $endpoint_class [join $family_names {;}] $startpoint $endpoint]
}

proc output_contract_by_object {output_bit_contract} {
  set result [dict create]
  foreach key [lsort -dictionary [dict keys $output_bit_contract]] {
    set record [dict get $output_bit_contract $key]
    set name [dict get $record object_name]
    if {[dict exists $result $name]} {
      error "output-bit driver contract duplicates OpenSTA object: $name"
    }
    dict set result $name $record
  }
  return $result
}

proc materialize_output_paths {paths output_bit_contract q_names output_names analysis} {
  set by_object [output_contract_by_object $output_bit_contract]
  set observations [dict create]
  set expected_role [expr {$analysis eq "max" ? "output setup" : "output hold"}]
  foreach path $paths {
    set observation [validate_path_end $path "clk_to_q/output_bulk" \
      $analysis [list $expected_role] $q_names $output_names]
    set endpoint [dict get $observation endpoint]
    if {![dict exists $by_object $endpoint]} {
      error "output bulk query returned an undeclared endpoint: $endpoint"
    }
    set bit_record [dict get $by_object $endpoint]
    if {[dict get $bit_record classification] ne "DYNAMIC"} {
      error "structurally constant output has a register-Q timing path: $endpoint"
    }
    if {[dict exists $observations $endpoint]} {
      error "output bulk query returned multiple paths for one endpoint: $endpoint"
    }
    set delay [measured_path_delay_ns $observation "clk_to_q/output_bulk" \
      register_q_to_output]
    dict set observation delay_ns $delay
    dict set observations $endpoint $observation
  }
  return $observations
}

proc output_rows_from_observations {output_bit_contract observations analysis} {
  set rows {}
  foreach key [lsort -dictionary [dict keys $output_bit_contract]] {
    set bit_record [dict get $output_bit_contract $key]
    set family [dict get $bit_record family]
    set index [dict get $bit_record index]
    set object_name [dict get $bit_record object_name]
    set classification [dict get $bit_record classification]
    set value [dict get $bit_record value]
    set binding [dict get $bit_record driver_binding_sha256]
    if {$classification ne "DYNAMIC"} {
      if {[dict exists $observations $object_name]} {
        error "structurally constant output has a register-Q timing path: $object_name"
      }
      lappend rows [list $family $index $object_name $classification $value \
        $analysis 0 - - STRUCTURAL_CONSTANT PORT - - $binding]
      continue
    }
    if {![dict exists $observations $object_name]} {
      error "dynamic output has no real register-Q timing path: $object_name"
    }
    set observation [dict get $observations $object_name]
    lappend rows [list $family $index $object_name $classification - $analysis 1 \
      [format %.12g [dict get $observation delay_ns]] \
      [format %.12g [dict get $observation slack_ns]] REGISTER_Q PORT \
      [dict get $observation startpoint] [dict get $observation endpoint] $binding]
  }
  return $rows
}

proc collect_output_timing_bulk {output_bit_contract q_pins analysis} {
  set output_names {}
  set output_objects {}
  foreach key [lsort -dictionary [dict keys $output_bit_contract]] {
    set bit_record [dict get $output_bit_contract $key]
    lappend output_names [dict get $bit_record object_name]
    lappend output_objects [dict get $bit_record object]
  }
  set q_names [object_name_list $q_pins]
  set group_cap [llength $output_names]
  set paths [budgeted_find_timing_paths $q_pins $output_objects $analysis \
    1 $group_cap output_bulk all_outputs]
  set observations [materialize_output_paths $paths $output_bit_contract \
    $q_names $output_names $analysis]
  complete_timing_query $paths output_bulk all_outputs $analysis 1 $group_cap
  return [output_rows_from_observations \
    $output_bit_contract $observations $analysis]
}

proc aggregate_output_family {family declared bit_rows analysis} {
  set selected 0
  set selected_delay 0.0
  set selected_slack 0.0
  set selected_start "-"
  set selected_end "-"
  set object_names {}
  set path_count 0
  set seen [dict create]
  foreach row $bit_rows {
    if {[lindex $row 0] ne $family} { continue }
    set index [lindex $row 1]
    if {[dict exists $seen $index]} { error "output family $family duplicates bit $index" }
    dict set seen $index 1
    if {[lindex $row 3] ne "DYNAMIC"} { continue }
    lappend object_names [lindex $row 2]
    incr path_count [lindex $row 6]
    set delay [finite_decimal [lindex $row 7] "$family dynamic delay"]
    set slack [finite_decimal [lindex $row 8] "$family dynamic slack"]
    if {!$selected ||
        ($analysis eq "max" && $delay > $selected_delay) ||
        ($analysis eq "min" && $delay < $selected_delay)} {
      set selected 1
      set selected_delay $delay
      set selected_slack $slack
      set selected_start [lindex $row 11]
      set selected_end [lindex $row 12]
    }
  }
  if {[dict size $seen] != $declared} {
    error "output family $family bit inventory is incomplete"
  }
  set object_names [lsort -unique $object_names]
  if {!$selected} {
    return [list clk_to_q $family $analysis $declared 0 0 - - \
      REGISTER_Q PORT - - -]
  }
  return [list clk_to_q $family $analysis $declared \
    [llength $object_names] $path_count [format %.12g $selected_delay] \
    [format %.12g $selected_slack] REGISTER_Q PORT \
    [join $object_names {;}] $selected_start $selected_end]
}

set allowed_children {
  OooFpAddSubPipe OooFpMulProductPipe OooFpMulNormRoundPipe
  OooFpFmaAlignAddPipe OooFpFmaNormRoundPipe
}
set module [require_env FP_OOC_CHILD_MODULE]
if {$module ni $allowed_children} { error "unregistered FP OOC child: $module" }
if {[require_env FP_OOC_PROFILE] ne "fp-arith-ooc-composite-v1"} {
  error "child OpenSTA profile differs from fp-arith-ooc-composite-v1"
}
set analysis [require_env FP_OOC_ANALYSIS]
if {$analysis ni {max min}} { error "FP_OOC_ANALYSIS must be max or min" }
set run_id [tsv_atom [require_env FP_OOC_RUN_ID] run_id]
set design_id [tsv_atom [require_env FP_OOC_DESIGN_ID] design_id]
if {![regexp {^sha256:[0-9a-f]{64}$} $design_id]} { error "FP OOC design_id is invalid" }
set period_ns [require_env FP_OOC_PERIOD_NS]
if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "FP OOC child requires exact 5.0ns clock"
}
set inputs [parse_port_contract [require_env FP_OOC_INPUT_PORT_CONTRACT] input_contract]
set outputs [parse_port_contract [require_env FP_OOC_OUTPUT_PORT_CONTRACT] output_contract]
if {![dict exists $inputs clk] || [dict get $inputs clk] != 1 ||
    ![dict exists $inputs rst] || ![dict exists $inputs flush_i]} {
  error "child input contract lacks exact clk/rst/flush controls"
}
set netlist [require_regular_file [require_env FP_OOC_NETLIST] child_netlist]
set std_lib [require_regular_file [require_env FP_OOC_STD_LIB] standard_cell_lib]
set driver_contract_tcl [require_regular_file \
  [require_env FP_OOC_OUTPUT_BIT_DRIVER_CONTRACT_TCL] output_bit_driver_contract]
source $driver_contract_tcl
set out_dir [file normalize [require_env FP_OOC_OUT_DIR]]
file mkdir $out_dir
set inventory [file join $out_dir "child-timing-${analysis}.tsv"]
set report [file join $out_dir "child-timing-${analysis}.rpt"]
set progress [file join $out_dir "child-query-progress-${analysis}.tsv"]
file delete -force $inventory $report $progress
set fp_ooc_progress_stream [open $progress w]
puts $fp_ooc_progress_stream "schema\tnpc-rv64-fp-ooc-query-progress-v1"
puts $fp_ooc_progress_stream "run_id\t$run_id"
puts $fp_ooc_progress_stream "design_id\t$design_id"
puts $fp_ooc_progress_stream "subject\t$module"
puts $fp_ooc_progress_stream "analysis\t$analysis"
puts $fp_ooc_progress_stream "phase_marker\tpre_link\tBEGIN"
flush $fp_ooc_progress_stream

read_liberty $std_lib
read_verilog $netlist
link_design $module
puts $fp_ooc_progress_stream "phase_marker\tlink\tCOMPLETE"
flush $fp_ooc_progress_stream
set fp_ooc_clock_origin_ns 0.0
set fp_ooc_clock_source_latency_ns 0.0
set fp_ooc_clock_network_latency_ns 0.0
set fp_ooc_clock_insertion_ns 0.0
set fp_ooc_clock_propagated 0
set fp_ooc_input_seed_ns 0.0
create_clock -name fp_ooc_clock -period $period_ns \
  -waveform [list $fp_ooc_clock_origin_ns [expr {$period_ns / 2.0}]] [get_ports clk]
set_clock_latency -source $fp_ooc_clock_source_latency_ns [get_clocks fp_ooc_clock]
set_clock_latency $fp_ooc_clock_network_latency_ns [get_clocks fp_ooc_clock]

set input_objects [dict create]
set data_input_objects {}
set control_objects {}
foreach family [lsort [dict keys $inputs]] {
  set objects [exact_port_family $family [dict get $inputs $family] input]
  dict set input_objects $family $objects
  if {$family eq "clk"} {
    continue
  } elseif {$family in {rst flush_i}} {
    foreach object $objects { lappend control_objects $object }
  } else {
    foreach object $objects { lappend data_input_objects $object }
  }
}
set output_objects [dict create]
set all_output_objects {}
foreach family [lsort [dict keys $outputs]] {
  set objects [exact_port_family $family [dict get $outputs $family] output]
  dict set output_objects $family $objects
  foreach object $objects { lappend all_output_objects $object }
}
set output_bit_contract [validate_output_bit_driver_contract $outputs $output_objects]
set dynamic_output_objects {}
foreach key [lsort -dictionary [dict keys $output_bit_contract]] {
  set bit_record [dict get $output_bit_contract $key]
  if {[dict get $bit_record classification] eq "DYNAMIC"} {
    lappend dynamic_output_objects [dict get $bit_record object]
  }
}
set all_nonclock_inputs [concat $data_input_objects $control_objects]
set_input_delay $fp_ooc_input_seed_ns -clock fp_ooc_clock $all_nonclock_inputs
set_output_delay 0.0 -clock fp_ooc_clock $all_output_objects
set data_pins [register_d_pins]
set q_pins [register_q_pins]
configure_query_budget $module [collection_count $data_pins] \
  [collection_count $all_nonclock_inputs] [collection_count $all_output_objects] \
  [collection_count $dynamic_output_objects]

set rows {}
lappend rows [collect_path_class port_to_register $data_input_objects $data_pins \
  $analysis PORT REGISTER_D]
if {$module eq "OooFpMulProductPipe"} {
  # register_to_register NOT_APPLICABLE: this production child owns only S1.
  lappend rows [list register_to_register NOT_APPLICABLE 0 0 - - - - - - -]
} else {
  lappend rows [collect_path_class register_to_register $q_pins $data_pins \
    $analysis REGISTER_Q REGISTER_D]
}
lappend rows [collect_path_class register_to_port $q_pins $dynamic_output_objects \
  $analysis REGISTER_Q PORT]
lappend rows [collect_path_class synchronous_control_to_register $control_objects \
  $data_pins $analysis PORT REGISTER_D]

set arc_rows {}
foreach family [lsort [dict keys $inputs]] {
  if {$family eq "clk"} { continue }
  set objects [dict get $input_objects $family]
  lappend arc_rows [collect_arc_family setup $family $objects $data_pins max \
    [dict get $inputs $family] PORT REGISTER_D]
  lappend arc_rows [collect_arc_family hold $family $objects $data_pins min \
    [dict get $inputs $family] PORT REGISTER_D]
}
set output_bit_rows {}
set output_bit_rows [collect_output_timing_bulk \
  $output_bit_contract $q_pins $analysis]
foreach family [lsort [dict keys $outputs]] {
  lappend arc_rows [aggregate_output_family $family [dict get $outputs $family] \
    $output_bit_rows $analysis]
}
set arc_rows [lsort -dictionary $arc_rows]
verify_query_budget

set stream [open $inventory w]
puts $stream "schema\tnpc-rv64-fp-ooc-timing-inventory-v1"
puts $stream "run_id\t$run_id"
puts $stream "design_id\t$design_id"
puts $stream "subject\t$module"
puts $stream "analysis\t$analysis"
puts $stream "path_class\tstatus\tpath_count\tnegative_path_count\tworst_slack_ns\tstartpoint\tendpoint\tstartpoint_object_class\tendpoint_object_class\tfrom_objects\tto_objects"
foreach row $rows { puts $stream [join $row "\t"] }
puts $stream "arc_inventory"
puts $stream "arc_class\tport_family\tpath_delay\tdeclared_cardinality\tobserved_cardinality\tpath_count\tworst_path_delay_ns\tworst_slack_ns\tsource_object_class\tendpoint_object_class\tobject_names\tstartpoint\tendpoint"
foreach row $arc_rows { puts $stream [join $row "\t"] }
puts $stream "output_bit_driver_contract_id\t$fp_ooc_output_bit_driver_contract_id"
puts $stream "output_bit_inventory"
puts $stream "port_family\tindex\tobject_name\tclassification\tconstant_value\tpath_delay\tpath_count\tworst_path_delay_ns\tworst_slack_ns\tsource_object_class\tendpoint_object_class\tstartpoint\tendpoint\tdriver_binding_sha256"
foreach row $output_bit_rows { puts $stream [join $row "\t"] }
close $stream

puts $fp_ooc_progress_stream "phase_marker\treport\tBEGIN"
flush $fp_ooc_progress_stream
report_checks -path_delay $analysis -group_path_count 1000 \
  -sort_by_slack -digits 9 > $report
puts $fp_ooc_progress_stream "phase_marker\treport\tCOMPLETE"
puts $fp_ooc_progress_stream \
  "completion_marker\t\[FP-OOC-QUERY-BUDGET\]\[PASS\]"
flush $fp_ooc_progress_stream
close $fp_ooc_progress_stream
if {![file exists $inventory] || [file size $inventory] == 0 ||
    ![file exists $report] || [file size $report] == 0 ||
    ![file exists $progress] || [file size $progress] == 0} {
  error "FP OOC child timing artifacts are incomplete"
}
puts [format {[FP-OOC-QUERY-BUDGET][PASS] module=%s analysis=%s find_calls=%d pathends=%d pathends_le=%d validations=%d validations_le=%d complete=1} \
  $module $analysis $fp_ooc_find_calls $fp_ooc_pathend_count \
  $fp_ooc_pathend_limit $fp_ooc_validation_count $fp_ooc_validation_limit]
exit
