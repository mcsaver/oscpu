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

proc require_bit_set {label actual width} {
  set expected {}
  for {set bit 0} {$bit < $width} {incr bit} {
    lappend expected $bit
  }
  set normalized [lsort -integer -unique $actual]
  if {$normalized ne $expected || [llength $actual] != $width} {
    error "$label bit contract mismatch: actual=$actual expected=$expected"
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
  set report [file join $out_dir "opensta-t3l-$name.rpt"]
  set status [report_through_to $report $source_coll $target_coll]
  write_query $fp $name $report $status $source_coll $target_coll
}

proc absent_query {fp out_dir name} {
  set report [file join $out_dir "opensta-t3l-$name.rpt"]
  write_note $report "status=PORT_ABSENT source_count=0 target_count=0"
  puts $fp "\[$name\]"
  puts $fp "report=[file tail $report]"
  puts $fp "selector=through_to"
  puts $fp "status=PORT_ABSENT"
  puts $fp "source_count=0"
  puts $fp "target_count=0"
  puts $fp ""
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
  puts $fp "target_count=[llength $target_coll]"
  puts $fp "intersection_count=[llength $endpoint_names]"
  foreach endpoint_name $endpoint_names {
    puts $fp "intersection_object=$endpoint_name"
  }
  close $fp
}

proc absent_intersection {path} {
  write_note $path "status=PORT_ABSENT\nsource_count=0\ntarget_count=0\nintersection_count=0"
}

set netlist [file normalize [require_env T3L_STA_NETLIST]]
set out_dir [file normalize [require_env T3L_STA_OUT_DIR]]
set std_lib [file normalize [require_env T3L_STA_STD_LIB]]
set macro_raw [require_env T3L_STA_MACRO_LIBS]
set period_ns [require_env T3L_STA_PERIOD_NS]
set expect [require_env T3L_STA_EXPECT_BRANCH]
set netlist_sha256 [require_env T3L_STA_NETLIST_SHA256]
set input_manifest_sha256 [require_env T3L_STA_INPUT_MANIFEST_SHA256]
set parameters_sha256 [require_env T3L_STA_PARAMETERS_SHA256]

if {$period_ns ne "5.0" || abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3L focused STA requires exact period_ns=5.0, got: $period_ns"
}
if {$expect ne "old" && $expect ne "fresh"} {
  error "T3L_STA_EXPECT_BRANCH must be old or fresh"
}
foreach required_file [list $netlist $std_lib] {
  if {![file exists $required_file] || [file type $required_file] ne "file"} {
    error "required regular file does not exist: $required_file"
  }
}
file mkdir $out_dir
foreach stale [glob -nocomplain [file join $out_dir opensta-t3l-*]] {
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
  error "T3L focused STA requires exactly four macro liberties"
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

set frontend_cells {}
set decoder_cells {}
set target_cells {}
set dec0_bimm_pins {}
set dec1_bimm_pins {}
set dec0_bimm_bits {}
set dec1_bimm_bits {}
set dec0_sign_pins {}
set dec1_sign_pins {}
set dec0_wide_pins {}
set dec1_wide_pins {}
set target_bimm_pins {}
set target_bimm_bits {}
set target_sign_pins {}
set target_output_pins {}
set target_output_bits {}
set pc_outstanding_d_pins {}
set packet_fifo_d_pins {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set is_frontend [string match "*u_core/u_ooo_core/u_frontend" $cell_name]
  set is_decoder [string match "*u_core/u_ooo_core/u_frontend/u_fetch_packet_decode" $cell_name]
  set is_target [regexp {.*u_core/u_ooo_core/u_frontend/u_fetch_dec[01]_branch_target$} $cell_name]
  if {$is_frontend} {
    lappend frontend_cells $cell
  }
  if {$is_decoder} {
    lappend decoder_cells $cell
  }
  if {$is_target} {
    lappend target_cells $cell
  }
  if {$is_decoder || $is_target} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      set pin_name [get_name $pin]
      set pin_direction [get_property $pin direction]
      if {$is_decoder && $pin_direction eq "output" &&
          [regexp {^dec0_bimm_o_([0-9]+)_$} $pin_name match bit]} {
        lappend dec0_bimm_pins $pin
        lappend dec0_bimm_bits $bit
        if {$bit == 12} { lappend dec0_sign_pins $pin }
        if {$bit >= 13} { lappend dec0_wide_pins $pin }
      }
      if {$is_decoder && $pin_direction eq "output" &&
          [regexp {^dec1_bimm_o_([0-9]+)_$} $pin_name match bit]} {
        lappend dec1_bimm_pins $pin
        lappend dec1_bimm_bits $bit
        if {$bit == 12} { lappend dec1_sign_pins $pin }
        if {$bit >= 13} { lappend dec1_wide_pins $pin }
      }
      if {$is_target && $pin_direction eq "input" &&
          [regexp {^bimm_i_([0-9]+)_$} $pin_name match bit]} {
        lappend target_bimm_pins $pin
        lappend target_bimm_bits $bit
        if {$bit == 12} { lappend target_sign_pins $pin }
      }
      if {$is_target && $pin_direction eq "output" &&
          [regexp {^target_o_([0-9]+)_$} $pin_name match bit]} {
        lappend target_output_pins $pin
        lappend target_output_bits $bit
      }
    }
  }
  if {[string match "*u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] eq "D" && [get_property $pin direction] eq "input"} {
        lappend pc_outstanding_d_pins $pin
      }
    }
  }
  if {[string match "*u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_name $pin] eq "D" && [get_property $pin direction] eq "input"} {
        lappend packet_fifo_d_pins $pin
      }
    }
  }
}

if {[llength $frontend_cells] != 1 || [llength $decoder_cells] != 1 ||
    [llength $dec0_sign_pins] != 1 || [llength $dec1_sign_pins] != 1 ||
    [llength $pc_outstanding_d_pins] == 0 || [llength $packet_fifo_d_pins] == 0} {
  error "T3L focused base object contract failed: frontend=[llength $frontend_cells] decoder=[llength $decoder_cells] dec0_sign=[llength $dec0_sign_pins] dec1_sign=[llength $dec1_sign_pins] pc_d=[llength $pc_outstanding_d_pins] fifo_d=[llength $packet_fifo_d_pins]"
}
if {$expect eq "old"} {
  require_bit_set dec0_bimm $dec0_bimm_bits 64
  require_bit_set dec1_bimm $dec1_bimm_bits 64
  if {[llength $dec0_wide_pins] != 51 || [llength $dec1_wide_pins] != 51 ||
      [llength $target_cells] != 0 || [llength $target_bimm_pins] != 0 ||
      [llength $target_sign_pins] != 0 || [llength $target_output_pins] != 0} {
    error "old T3K branch ABI mismatch: dec0_wide=[llength $dec0_wide_pins] dec1_wide=[llength $dec1_wide_pins] targets=[llength $target_cells] target_bimm=[llength $target_bimm_pins] target_sign=[llength $target_sign_pins] target_out=[llength $target_output_pins]"
  }
} else {
  require_bit_set dec0_bimm $dec0_bimm_bits 13
  require_bit_set dec1_bimm $dec1_bimm_bits 13
  if {[llength $dec0_wide_pins] != 0 || [llength $dec1_wide_pins] != 0 ||
      [llength $target_cells] != 2 || [llength $target_bimm_pins] != 26 ||
      [llength $target_sign_pins] != 2 || [llength $target_output_pins] != 128} {
    error "fresh T3L branch ABI mismatch: dec0_wide=[llength $dec0_wide_pins] dec1_wide=[llength $dec1_wide_pins] targets=[llength $target_cells] target_bimm=[llength $target_bimm_pins] target_sign=[llength $target_sign_pins] target_out=[llength $target_output_pins]"
  }
  require_bit_set target_bimm_unique [lsort -integer -unique $target_bimm_bits] 13
  if {[llength [lsort -integer -unique $target_output_bits]] != 64} {
    error "fresh T3L target output bit set is not exactly 0..63"
  }
  require_bit_set target_output_unique [lsort -integer -unique $target_output_bits] 64
}

set decoder_sign_pins [concat $dec0_sign_pins $dec1_sign_pins]
set labels [list frontend_cells decoder_cells target_cells dec0_bimm_pins \
    dec1_bimm_pins dec0_sign_pins dec1_sign_pins dec0_wide_pins \
    dec1_wide_pins target_bimm_pins target_sign_pins target_output_pins \
    pc_outstanding_d_pins packet_fifo_d_pins]
set collections [list $frontend_cells $decoder_cells $target_cells \
    $dec0_bimm_pins $dec1_bimm_pins $dec0_sign_pins $dec1_sign_pins \
    $dec0_wide_pins $dec1_wide_pins $target_bimm_pins $target_sign_pins \
    $target_output_pins $pc_outstanding_d_pins $packet_fifo_d_pins]
set counts_fp [open [file join $out_dir opensta-t3l-focused-counts.txt] w]
set objects_fp [open [file join $out_dir opensta-t3l-focused-objects.txt] w]
foreach label $labels collection $collections {
  puts $counts_fp "$label=[llength $collection]"
  write_collection $objects_fp $label $collection
}
close $counts_fp
close $objects_fp

set queries_fp [open [file join $out_dir opensta-t3l-focused-queries.txt] w]
run_query $queries_fp $out_dir decoder_sign_to_pc \
    $decoder_sign_pins $pc_outstanding_d_pins
run_query $queries_fp $out_dir decoder_sign_to_fifo \
    $decoder_sign_pins $packet_fifo_d_pins
if {$expect eq "fresh"} {
  run_query $queries_fp $out_dir target_sign_to_pc \
      $target_sign_pins $pc_outstanding_d_pins
  run_query $queries_fp $out_dir target_output_to_pc \
      $target_output_pins $pc_outstanding_d_pins
  run_query $queries_fp $out_dir target_output_to_fifo \
      $target_output_pins $packet_fifo_d_pins
} else {
  absent_query $queries_fp $out_dir target_sign_to_pc
  absent_query $queries_fp $out_dir target_output_to_pc
  absent_query $queries_fp $out_dir target_output_to_fifo
}
close $queries_fp

write_fanout_intersection \
    [file join $out_dir opensta-t3l-decoder-pc-intersection.txt] \
    $decoder_sign_pins $pc_outstanding_d_pins
write_fanout_intersection \
    [file join $out_dir opensta-t3l-decoder-fifo-intersection.txt] \
    $decoder_sign_pins $packet_fifo_d_pins
if {$expect eq "fresh"} {
  write_fanout_intersection \
      [file join $out_dir opensta-t3l-target-pc-intersection.txt] \
      $target_output_pins $pc_outstanding_d_pins
  write_fanout_intersection \
      [file join $out_dir opensta-t3l-target-fifo-intersection.txt] \
      $target_output_pins $packet_fifo_d_pins
} else {
  absent_intersection [file join $out_dir opensta-t3l-target-pc-intersection.txt]
  absent_intersection [file join $out_dir opensta-t3l-target-fifo-intersection.txt]
}

write_note [file join $out_dir opensta-t3l-focused-complete.txt] "status=COMPLETE
expect=$expect
period_ns=$period_ns
top=NpcTop
netlist=$netlist
netlist_sha256=$netlist_sha256
input_manifest_sha256=$input_manifest_sha256
parameters_sha256=$parameters_sha256"
exit
