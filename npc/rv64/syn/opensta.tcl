# Same real mapped netlist, Liberty corner, clock and I/O constraints as iEDA.
set PDK $::env(STA_PDK)
source scripts/common.tcl
foreach lib $ALL_LIB_FILES { read_liberty $lib }
read_verilog $::env(STA_NETLIST)
link_design $::env(STA_DESIGN)
read_sdc $::env(STA_SDC)
check_setup -verbose
set out $::env(STA_OUTPUT)
report_checks -path_delay min_max -group_path_count 10 -format full_clock_expanded -fields {slew capacitance fanout} -digits 4 > $out/opensta.rpt
# Includes Liberty setup/hold arcs on ICG enable pins in their clock group.
report_checks -path_delay min_max -group_path_count 10 -format json > $out/opensta.json
if {[info exists ::env(STA_HOLD_PATHS)]} {
  report_checks -path_delay min -slack_max 0 -group_path_count 100000 -format json > $::env(STA_HOLD_PATHS)
}
# SRAM clock limits are independent of setup/hold path slack.
report_check_types -min_period -format end -digits 9 -no_line_splits > $out/opensta-min-period.rpt
report_check_types -min_pulse_width -format end -digits 9 -no_line_splits > $out/opensta-min-pulse-width.rpt
report_worst_slack -max -digits 9
report_worst_slack -min -digits 9
exit
