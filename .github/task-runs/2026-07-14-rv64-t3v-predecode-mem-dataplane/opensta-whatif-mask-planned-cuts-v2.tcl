# Reuse the frozen exploratory setup and masks, but keep control after its
# terminal `exit` so the endpoint-specific correction can be applied.  The v1
# experiment proved that `-through` does not suppress an endpoint pin in
# OpenSTA; `-to` is required for the D-cache SRAM address input.
rename exit t3v_real_exit
proc exit args {}
source [file join [file dirname [info script]] opensta-whatif-mask-planned-cuts.tcl]
rename exit t3v_noop_exit
rename t3v_real_exit exit

set_false_path -to $dcache_addr_pins
set report_path [file join $out_dir top40-mask-planned-cuts-v2.rpt]
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
