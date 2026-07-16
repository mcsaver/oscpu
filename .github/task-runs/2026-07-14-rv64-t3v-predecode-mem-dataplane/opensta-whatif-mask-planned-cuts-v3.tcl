# OpenSTA models the synchronous SRAM timing endpoint as the macro cell rather
# than its addr_i pin.  Reuse the v1 setup/masks, then constrain that endpoint
# object directly to expose the next independent path family.
rename exit t3v_real_exit
proc exit args {}
source [file join [file dirname [info script]] opensta-whatif-mask-planned-cuts.tcl]
rename exit t3v_noop_exit
rename t3v_real_exit exit

set dcache_sram_cell [get_cells -quiet \
  u_core/u_ooo_mem_bridge/u_dcache/u_sram]
if {[llength $dcache_sram_cell] != 1} {
  error "T3V what-if ABI mismatch: D-cache SRAM cells=[llength $dcache_sram_cell]"
}
set_false_path -to $dcache_sram_cell
set report_path [file join $out_dir top40-mask-planned-cuts-v3.rpt]
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
