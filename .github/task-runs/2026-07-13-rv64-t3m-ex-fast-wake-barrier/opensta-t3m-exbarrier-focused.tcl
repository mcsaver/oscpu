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

proc query_one_through_to {path source_coll target_coll} {
  if {[llength $source_coll] == 0 || [llength $target_coll] == 0} {
    error "one-through query has an empty collection"
  }
  report_checks -path_delay max -group_path_count 20 -digits 3 \
      -through $source_coll -to $target_coll > $path
  set fp [open $path r]
  set text [read $fp]
  close $fp
  if {[string first "Startpoint:" $text] < 0} {
    write_note $path "status=NO_TIMING_PATH source_count=[llength $source_coll] target_count=[llength $target_coll]"
    return "NO_TIMING_PATH"
  }
  return "PATHS_PRESENT"
}

proc query_two_through_to {path source_coll via_coll target_coll} {
  if {[llength $source_coll] == 0 || [llength $via_coll] == 0 ||
      [llength $target_coll] == 0} {
    error "two-through query has an empty collection"
  }
  report_checks -path_delay max -group_path_count 20 -digits 3 \
      -through $source_coll -through $via_coll -to $target_coll > $path
  set fp [open $path r]
  set text [read $fp]
  close $fp
  if {[string first "Startpoint:" $text] < 0} {
    write_note $path "status=NO_TIMING_PATH source_count=[llength $source_coll] via_count=[llength $via_coll] target_count=[llength $target_coll]"
    return "NO_TIMING_PATH"
  }
  return "PATHS_PRESENT"
}

proc write_objects {path collections} {
  set fp [open $path w]
  foreach pair $collections {
    set label [lindex $pair 0]
    set coll [lindex $pair 1]
    puts $fp "\[$label\] count=[llength $coll]"
    foreach object $coll {
      puts $fp [get_full_name $object]
    }
  }
  close $fp
}

set netlist [file normalize [require_env T3M_STA_NETLIST]]
set out_dir [file normalize [require_env T3M_STA_OUT_DIR]]
set std_lib [file normalize [require_env T3M_STA_STD_LIB]]
set macro_raw [require_env T3M_STA_MACRO_LIBS]
set period_ns [require_env T3M_STA_PERIOD_NS]
set expect [require_env T3M_STA_EXPECT_BARRIER]
set netlist_sha256 [require_env T3M_STA_NETLIST_SHA256]
set input_manifest_sha256 [require_env T3M_STA_INPUT_MANIFEST_SHA256]
set parameters_sha256 [require_env T3M_STA_PARAMETERS_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3M focused STA requires exact period_ns=5.0, got: $period_ns"
}
if {$expect ne "old" && $expect ne "fresh"} {
  error "T3M_STA_EXPECT_BARRIER must be old or fresh"
}
foreach required_file [list $netlist $std_lib] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
}
file mkdir $out_dir
foreach stale [glob -nocomplain [file join $out_dir opensta-t3m-*]] {
  file delete -force $stale
}

read_liberty $std_lib
set macro_count 0
foreach macro_lib [split $macro_raw ":"] {
  set normalized [file normalize $macro_lib]
  if {![file exists $normalized] || [file type $normalized] ne "file"} {
    error "macro liberty is not a regular file: $normalized"
  }
  read_liberty $normalized
  incr macro_count
}
if {$macro_count != 4} {
  error "T3M focused STA requires exactly four macro liberties"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

set iq_cells {}
set prf_cells {}
set select_wakeup_pins {}
set formal_wakeup_pins {}
set issue_output_pins {}
set prf_bypass_pins {}
set prf_write_pins {}
set prf_read_output_pins {}
set iq_d_pins {}
set ex_stage_d_pins {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set is_iq [string match "*/u_issue_queue" $cell_name]
  set is_prf [string match "*/u_phys_reg_file" $cell_name]
  if {$is_iq} {
    lappend iq_cells $cell
  }
  if {$is_prf} {
    lappend prf_cells $cell
  }
  if {$is_iq || $is_prf} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      set pin_name [get_name $pin]
      set direction [get_property $pin direction]
      if {$is_iq && $direction eq "input" &&
          [regexp {^select_wakeup[01]_(valid|pdest)_i(_[0-9]+_)?$} $pin_name]} {
        lappend select_wakeup_pins $pin
      }
      if {$is_iq && $direction eq "input" &&
          [regexp {^wakeup[01]_(valid|pdest)_i(_[0-9]+_)?$} $pin_name]} {
        lappend formal_wakeup_pins $pin
      }
      if {$is_iq && $direction eq "output" &&
          [regexp {^issue[01]_.+_o(_[0-9]+_)?$} $pin_name]} {
        lappend issue_output_pins $pin
      }
      if {$is_prf && $direction eq "input" &&
          [regexp {^bypass[01]_(valid|addr|data)_i(_[0-9]+_)?$} $pin_name]} {
        lappend prf_bypass_pins $pin
      }
      if {$is_prf && $direction eq "input" &&
          [regexp {^write[01]_(valid|addr|data)_i(_[0-9]+_)?$} $pin_name]} {
        lappend prf_write_pins $pin
      }
      if {$is_prf && $direction eq "output" &&
          [regexp {^read(0|1|2|3|8)_data_o_[0-9]+_$} $pin_name]} {
        lappend prf_read_output_pins $pin
      }
    }
  }
  if {[string match "*/u_issue_queue/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] eq "D" && [get_property $pin direction] eq "input"} {
        lappend iq_d_pins $pin
      }
    }
  }
  if {[string match "*/u_ex0_stage/*" $cell_name] ||
      [string match "*/u_ex1_stage/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] eq "D" && [get_property $pin direction] eq "input"} {
        lappend ex_stage_d_pins $pin
      }
    }
  }
}

if {[llength $iq_cells] != 1 || [llength $prf_cells] != 1 ||
    [llength $formal_wakeup_pins] != 14 ||
    [llength $issue_output_pins] == 0 || [llength $prf_write_pins] == 0 ||
    [llength $prf_read_output_pins] != 320 ||
    [llength $iq_d_pins] == 0 || [llength $ex_stage_d_pins] == 0} {
  error "T3M focused base object contract failed: iq=[llength $iq_cells] prf=[llength $prf_cells] formal_wake=[llength $formal_wakeup_pins] issue_out=[llength $issue_output_pins] prf_write=[llength $prf_write_pins] prf_read=[llength $prf_read_output_pins] iq_d=[llength $iq_d_pins] ex_d=[llength $ex_stage_d_pins]"
}
if {$expect eq "old"} {
  if {[llength $select_wakeup_pins] != 14 || [llength $prf_bypass_pins] != 142} {
    error "old T3L fast-port contract failed: select=[llength $select_wakeup_pins] bypass=[llength $prf_bypass_pins]"
  }
} else {
  if {[llength $select_wakeup_pins] != 0 || [llength $prf_bypass_pins] != 0} {
    error "fresh T3M retired ports remain: select=[llength $select_wakeup_pins] bypass=[llength $prf_bypass_pins]"
  }
}

set counts_fp [open [file join $out_dir opensta-t3m-focused-counts.txt] w]
puts $counts_fp "expect=$expect"
puts $counts_fp "iq_cells=[llength $iq_cells]"
puts $counts_fp "prf_cells=[llength $prf_cells]"
puts $counts_fp "select_wakeup_pins=[llength $select_wakeup_pins]"
puts $counts_fp "formal_wakeup_pins=[llength $formal_wakeup_pins]"
puts $counts_fp "issue_output_pins=[llength $issue_output_pins]"
puts $counts_fp "prf_bypass_pins=[llength $prf_bypass_pins]"
puts $counts_fp "prf_write_pins=[llength $prf_write_pins]"
puts $counts_fp "prf_read_output_pins=[llength $prf_read_output_pins]"
puts $counts_fp "iq_d_pins=[llength $iq_d_pins]"
puts $counts_fp "ex_stage_d_pins=[llength $ex_stage_d_pins]"
close $counts_fp

write_objects [file join $out_dir opensta-t3m-focused-objects.txt] [list \
    [list iq_cells $iq_cells] \
    [list prf_cells $prf_cells] \
    [list select_wakeup_pins $select_wakeup_pins] \
    [list formal_wakeup_pins $formal_wakeup_pins] \
    [list issue_output_pins $issue_output_pins] \
    [list prf_bypass_pins $prf_bypass_pins] \
    [list prf_write_pins $prf_write_pins] \
    [list prf_read_output_pins $prf_read_output_pins] \
    [list iq_d_pins $iq_d_pins] \
    [list ex_stage_d_pins $ex_stage_d_pins]]

set query_fp [open [file join $out_dir opensta-t3m-focused-queries.txt] w]
if {$expect eq "old"} {
  set select_status [query_two_through_to \
      [file join $out_dir opensta-t3m-select-to-ex.rpt] \
      $select_wakeup_pins $issue_output_pins $ex_stage_d_pins]
  set bypass_status [query_two_through_to \
      [file join $out_dir opensta-t3m-bypass-to-ex.rpt] \
      $prf_bypass_pins $prf_read_output_pins $ex_stage_d_pins]
} else {
  set select_status "PORT_ABSENT"
  set bypass_status "PORT_ABSENT"
  write_note [file join $out_dir opensta-t3m-select-to-ex.rpt] \
      "status=PORT_ABSENT source_count=0"
  write_note [file join $out_dir opensta-t3m-bypass-to-ex.rpt] \
      "status=PORT_ABSENT source_count=0"
}
set formal_iq_status [query_one_through_to \
    [file join $out_dir opensta-t3m-formal-to-iq-d.rpt] \
    $formal_wakeup_pins $iq_d_pins]
set formal_ex_status [query_two_through_to \
    [file join $out_dir opensta-t3m-formal-to-ex.rpt] \
    $formal_wakeup_pins $issue_output_pins $ex_stage_d_pins]
puts $query_fp "select_to_ex=$select_status"
puts $query_fp "bypass_to_ex=$bypass_status"
puts $query_fp "formal_to_iq_d=$formal_iq_status"
puts $query_fp "formal_to_ex=$formal_ex_status"
close $query_fp

write_note [file join $out_dir opensta-t3m-focused-complete.txt] "status=COMPLETE
expect=$expect
period_ns=$period_ns
top=NpcTop
netlist=$netlist
netlist_sha256=$netlist_sha256
input_manifest_sha256=$input_manifest_sha256
parameters_sha256=$parameters_sha256"
exit
