proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

set netlist [file normalize [require_env T3U_WHATIF_NETLIST]]
set out_dir [file normalize [require_env T3U_WHATIF_OUT_DIR]]
set std_lib [file normalize [require_env T3U_WHATIF_STD_LIB]]
set macro_raw [require_env T3U_WHATIF_MACRO_LIBS]

file mkdir $out_dir
read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

# Exploratory only: mask every output pin in the two dispatch-side DecodeStage
# instances.  T3V intends to move this pure decode before the packet FIFO write;
# masking the old cone reveals timing families that such a cut cannot improve.
set decode_output_pins {}
foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  if {[string match "*u_core/u_ooo_core/u_frontend/u_head0_decode/*" $cell_name] ||
      [string match "*u_core/u_ooo_core/u_frontend/u_head1_decode/*" $cell_name]} {
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[get_property $pin direction] eq "output"} {
        lappend decode_output_pins $pin
      }
    }
  }
}
if {[llength $decode_output_pins] == 0} {
  error "T3U what-if ABI mismatch: no head decode output pins"
}
set_false_path -through $decode_output_pins

set report_path [file join $out_dir top40-mask-head-decode.rpt]
set count_path [file join $out_dir masked-object-count.txt]
set count_fp [open $count_path w]
puts $count_fp "decode_output_pins=[llength $decode_output_pins]"
close $count_fp
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
