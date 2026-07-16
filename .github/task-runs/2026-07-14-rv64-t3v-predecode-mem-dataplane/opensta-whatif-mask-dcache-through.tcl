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

# Exploratory only.  OpenSTA reports the SRAM macro as the startpoint object,
# so the first -from experiment did not remove this family.  A through-point
# constraint on every rdata pin is used here and is verified by the runner.
set dcache_rdata_pins [get_pins -quiet \
  u_core/u_ooo_mem_bridge/u_dcache/u_sram/rdata_o*]
if {[llength $dcache_rdata_pins] != 113} {
  error "T3V what-if ABI mismatch: dcache rdata pins=[llength $dcache_rdata_pins]"
}
set_false_path -through $dcache_rdata_pins

set report_path [file join $out_dir top40-mask-dcache-through.rpt]
set count_path [file join $out_dir masked-object-count.txt]
set count_fp [open $count_path w]
puts $count_fp "dcache_rdata_pins=[llength $dcache_rdata_pins]"
close $count_fp
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
