proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env T3V_WHATIF_NETLIST]]
set out_dir [file normalize [require_env T3V_WHATIF_OUT_DIR]]
set std_lib [file normalize [require_env T3V_WHATIF_STD_LIB]]
set macro_raw [require_env T3V_WHATIF_MACRO_LIBS]

file mkdir $out_dir
read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

# Exploratory only: combine the effective D-cache response mask with the two
# dispatch-head OooFpDecode cones that T3W plans to precompute into FIFO static
# facts.  This reveals paths that neither architectural cut can improve.
set dcache_rdata_pins [get_pins -quiet \
  u_core/u_ooo_mem_bridge/u_dcache/u_sram/rdata_o*]
if {[llength $dcache_rdata_pins] != 113} {
  error "T3V what-if ABI mismatch: dcache rdata pins=[llength $dcache_rdata_pins]"
}
set_false_path -through $dcache_rdata_pins

set fpdecode_output_pins {}
foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  if {[string match "*u_fetch_head_pair_gate/u_head0_classify_gate/u_fp_decode/*" $cell_name] ||
      [string match "*u_fetch_head_pair_gate/u_head1_classify_gate/u_fp_decode/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_property $pin direction] eq "output"} {
        lappend fpdecode_output_pins $pin
      }
    }
  }
}
if {[llength $fpdecode_output_pins] == 0} {
  error "T3V what-if ABI mismatch: no head OooFpDecode output pins"
}
set_false_path -through $fpdecode_output_pins

set report_path [file join $out_dir top40-mask-dcache-fpdecode.rpt]
set count_path [file join $out_dir masked-object-count.txt]
set count_fp [open $count_path w]
puts $count_fp "dcache_rdata_pins=[llength $dcache_rdata_pins]"
puts $count_fp "fpdecode_output_pins=[llength $fpdecode_output_pins]"
close $count_fp
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
