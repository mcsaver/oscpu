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

proc report_from_to {path from_coll to_coll} {
  set from_count [llength $from_coll]
  set to_count [llength $to_coll]
  if {$from_count == 0 || $to_count == 0} {
    write_note $path "status=EMPTY_COLLECTION from_count=$from_count to_count=$to_count"
    return
  }
  report_checks -path_delay max -group_path_count 10 \
      -from $from_coll -to $to_coll -digits 3 > $path
  set fp [open $path r]
  set report_text [read $fp]
  close $fp
  if {[file size $path] == 0 ||
      [string trim $report_text] eq "No paths found."} {
    write_note $path "status=NO_TIMING_PATH from_count=$from_count to_count=$to_count"
  }
}

proc write_fanout_endpoints {path source_coll} {
  if {[llength $source_coll] == 0} {
    write_note $path "status=EMPTY_COLLECTION source_count=0 endpoint_count=0"
    return
  }
  set endpoints [get_fanout -from $source_coll -flat \
      -endpoints_only -trace_arcs timing]
  set names {}
  foreach endpoint $endpoints {
    lappend names [get_full_name $endpoint]
  }
  set names [lsort -unique $names]
  set fp [open $path w]
  puts $fp "source_count=[llength $source_coll]"
  puts $fp "endpoint_count=[llength $names]"
  foreach name $names {
    puts $fp $name
  }
  close $fp
}

proc write_collection {fp label coll} {
  puts $fp "\[$label\] count=[llength $coll]"
  foreach obj $coll {
    puts $fp [get_full_name $obj]
  }
}

set out_dir   [file normalize [require_env T3H_STA_OUT_DIR]]
file mkdir $out_dir
set complete_path [file join $out_dir opensta-t3h-focused-complete.txt]
file delete -force $complete_path

set netlist   [file normalize [require_env T3H_STA_NETLIST]]
set std_lib   [file normalize [require_env T3H_STA_STD_LIB]]
set macro_raw [require_env T3H_STA_MACRO_LIBS]
set period_ns [require_env T3H_STA_PERIOD_NS]

if {abs(double($period_ns) - 5.0) > 1.0e-9} {
  error "T3H focused STA requires exact 5.0 ns period, got: $period_ns"
}
read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period $period_ns [get_ports clk]

# Retained hierarchy prevents one wildcard from seeing every leaf.  Walk every
# cell once and collect both module-boundary inputs and leaf state/stage pins.
# A zero collection is an explicit failure in the post-run checker, never a cut.
set dcache_rdata {}
set int_ex0_d {}
set int_ex1_d {}
set fp_exec1_d {}
set fpiq_q {}
set fpprf_q {}
set fetch_payload_en {}
set fpiq_wake0 {}
set fpiq_wake1 {}
set intiq_wake0 {}
set intiq_wake1 {}
set fpprf_write0 {}
set fpprf_write1 {}
set fpprf_read0 {}
set fpprf_read1 {}
set fpprf_read2 {}
set fpprf_read3 {}

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set want_dcache [string match "*u_dcache/u_sram" $cell_name]
  set want_int_ex0 [string match "*u_int_backend/u_ex0_stage/*" $cell_name]
  set want_int_ex1 [string match "*u_int_backend/u_ex1_stage/*" $cell_name]
  set want_fp_exec1 [string match "*u_fp_backend/u_exec1_stage/*" $cell_name]
  set want_fpiq_leaf [string match "*u_fp_backend/u_fp_issue_queue/*" $cell_name]
  set want_fpprf_leaf [string match "*u_fp_backend/u_fp_phys_reg_file/*" $cell_name]
  set want_fetch_payload \
      [string match "*u_fetch_packet_cache/u_payload_sram" $cell_name]
  set want_fpiq_port [string match "*u_fp_backend/u_fp_issue_queue" $cell_name]
  set want_intiq_port [string match "*u_dispatch_backend/u_issue_queue" $cell_name]
  set want_fpprf_port \
      [string match "*u_fp_backend/u_fp_phys_reg_file" $cell_name]

  if {$want_dcache || $want_int_ex0 || $want_int_ex1 ||
      $want_fp_exec1 || $want_fpiq_leaf || $want_fpprf_leaf ||
      $want_fetch_payload || $want_fpiq_port || $want_intiq_port ||
      $want_fpprf_port} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      set pin_name [get_name $pin]
      if {$want_dcache && [string match "rdata_o*" $pin_name]} {
        lappend dcache_rdata $pin
      }
      if {$want_int_ex0 && $pin_name eq "D"} {
        lappend int_ex0_d $pin
      }
      if {$want_int_ex1 && $pin_name eq "D"} {
        lappend int_ex1_d $pin
      }
      if {$want_fp_exec1 && $pin_name eq "D"} {
        lappend fp_exec1_d $pin
      }
      if {$want_fpiq_leaf && $pin_name eq "Q"} {
        lappend fpiq_q $pin
      }
      if {$want_fpprf_leaf && $pin_name eq "Q"} {
        lappend fpprf_q $pin
      }
      if {$want_fetch_payload && $pin_name eq "en_i"} {
        lappend fetch_payload_en $pin
      }
      if {$want_fpiq_port && [string match "fp_wake0_*" $pin_name]} {
        lappend fpiq_wake0 $pin
      }
      if {$want_fpiq_port && [string match "fp_wake1_*" $pin_name]} {
        lappend fpiq_wake1 $pin
      }
      if {$want_intiq_port && [string match "fp_wake0_*" $pin_name]} {
        lappend intiq_wake0 $pin
      }
      if {$want_intiq_port && [string match "fp_wake1_*" $pin_name]} {
        lappend intiq_wake1 $pin
      }
      if {$want_fpprf_port && [string match "write0_*" $pin_name]} {
        lappend fpprf_write0 $pin
      }
      if {$want_fpprf_port && [string match "write1_*" $pin_name]} {
        lappend fpprf_write1 $pin
      }
      if {$want_fpprf_port && [string match "read0_data_o*" $pin_name]} {
        lappend fpprf_read0 $pin
      }
      if {$want_fpprf_port && [string match "read1_data_o*" $pin_name]} {
        lappend fpprf_read1 $pin
      }
      if {$want_fpprf_port && [string match "read2_data_o*" $pin_name]} {
        lappend fpprf_read2 $pin
      }
      if {$want_fpprf_port && [string match "read3_data_o*" $pin_name]} {
        lappend fpprf_read3 $pin
      }
    }
  }
}

set counts_path [file join $out_dir opensta-t3h-focused-counts.txt]
set counts_fp [open $counts_path w]
set labels [list dcache_rdata int_ex0_d int_ex1_d fp_exec1_d fpiq_q \
    fpprf_q fetch_payload_en fpiq_wake0 fpiq_wake1 intiq_wake0 \
    intiq_wake1 fpprf_write0 fpprf_write1 fpprf_read0 fpprf_read1 \
    fpprf_read2 fpprf_read3]
set colls [list $dcache_rdata $int_ex0_d $int_ex1_d $fp_exec1_d $fpiq_q \
    $fpprf_q $fetch_payload_en $fpiq_wake0 $fpiq_wake1 $intiq_wake0 \
    $intiq_wake1 $fpprf_write0 $fpprf_write1 $fpprf_read0 $fpprf_read1 \
    $fpprf_read2 $fpprf_read3]
for {set i 0} {$i < [llength $labels]} {incr i} {
  puts $counts_fp "[lindex $labels $i]=[llength [lindex $colls $i]]"
}
close $counts_fp

set objects_path [file join $out_dir opensta-t3h-focused-objects.txt]
set objects_fp [open $objects_path w]
for {set i 0} {$i < [llength $labels]} {incr i} {
  write_collection $objects_fp [lindex $labels $i] [lindex $colls $i]
}
close $objects_fp

# Forbidden T3H same-cycle paths.  Every collection must be non-empty and each
# report must say NO_TIMING_PATH; EMPTY_COLLECTION is never acceptance.
report_from_to [file join $out_dir opensta-t3h-dcache-to-int-ex0-d.rpt] \
    $dcache_rdata $int_ex0_d
report_from_to [file join $out_dir opensta-t3h-dcache-to-int-ex1-d.rpt] \
    $dcache_rdata $int_ex1_d
report_from_to [file join $out_dir opensta-t3h-dcache-to-fp-exec1-d.rpt] \
    $dcache_rdata $fp_exec1_d
report_from_to [file join $out_dir opensta-t3h-fpiq-wake0-to-fp-exec1-d.rpt] \
    $fpiq_wake0 $fp_exec1_d
report_from_to [file join $out_dir opensta-t3h-fpiq-wake1-to-fp-exec1-d.rpt] \
    $fpiq_wake1 $fp_exec1_d
report_from_to [file join $out_dir opensta-t3h-intiq-wake0-to-int-ex0-d.rpt] \
    $intiq_wake0 $int_ex0_d
report_from_to [file join $out_dir opensta-t3h-intiq-wake0-to-int-ex1-d.rpt] \
    $intiq_wake0 $int_ex1_d
report_from_to [file join $out_dir opensta-t3h-intiq-wake1-to-int-ex0-d.rpt] \
    $intiq_wake1 $int_ex0_d
report_from_to [file join $out_dir opensta-t3h-intiq-wake1-to-int-ex1-d.rpt] \
    $intiq_wake1 $int_ex1_d

foreach write_label [list write0 write1] \
        write_coll [list $fpprf_write0 $fpprf_write1] {
  report_from_to [file join $out_dir \
      opensta-t3h-fpprf-${write_label}-to-fp-exec1-d.rpt] \
      $write_coll $fp_exec1_d
  report_from_to [file join $out_dir \
      opensta-t3h-fpprf-${write_label}-to-int-ex0-d.rpt] \
      $write_coll $int_ex0_d
  report_from_to [file join $out_dir \
      opensta-t3h-fpprf-${write_label}-to-int-ex1-d.rpt] \
      $write_coll $int_ex1_d
  foreach read_label [list read0 read1 read2 read3] \
          read_coll [list $fpprf_read0 $fpprf_read1 $fpprf_read2 $fpprf_read3] {
    report_from_to [file join $out_dir \
        opensta-t3h-fpprf-${write_label}-to-${read_label}-data.rpt] \
        $write_coll $read_coll
  }
}

# Fanout endpoints prove wake/write pulses terminate at sticky/PRF state, rather
# than silently reaching execute D through an unqueried branch.
foreach label [list fpiq-wake0 fpiq-wake1 intiq-wake0 intiq-wake1 \
        fpprf-write0 fpprf-write1] \
        coll [list $fpiq_wake0 $fpiq_wake1 $intiq_wake0 $intiq_wake1 \
        $fpprf_write0 $fpprf_write1] {
  write_fanout_endpoints \
      [file join $out_dir opensta-t3h-${label}-fanout-endpoints.txt] $coll
}

# Legal residual families identify the next local bottleneck after the barrier.
report_from_to [file join $out_dir opensta-t3h-fpiq-q-to-fp-exec1-d.rpt] \
    $fpiq_q $fp_exec1_d
report_from_to [file join $out_dir opensta-t3h-fpprf-q-to-fp-exec1-d.rpt] \
    $fpprf_q $fp_exec1_d
report_from_to [file join $out_dir opensta-t3h-fpprf-q-to-int-ex0-d.rpt] \
    $fpprf_q $int_ex0_d
report_from_to [file join $out_dir opensta-t3h-fpprf-q-to-int-ex1-d.rpt] \
    $fpprf_q $int_ex1_d
report_from_to [file join $out_dir opensta-t3h-dcache-to-fetch-payload-en.rpt] \
    $dcache_rdata $fetch_payload_en
write_note $complete_path "status=COMPLETE"
exit
