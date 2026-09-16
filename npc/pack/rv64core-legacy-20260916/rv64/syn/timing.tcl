# Native area/timing task. Power requires a separate activity-backed analysis.
set SDC_FILE [lindex $argv 0]
set NETLIST_V [lindex $argv 1]
set DESIGN [lindex $argv 2]
set PDK [lindex $argv 3]
source scripts/common.tcl
set_design_workspace [file dirname $NETLIST_V]
read_netlist $NETLIST_V
read_liberty $LIB_FILES
link_design $DESIGN
read_sdc $SDC_FILE
report_timing -max_path 10
exit
