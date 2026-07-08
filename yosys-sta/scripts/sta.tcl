set SDC_FILE   [lindex $argv 0]
set NETLIST_V  [lindex $argv 1]
set DESIGN     [lindex $argv 2]
set PDK        [lindex $argv 3]
set RESULT_DIR [file dirname $NETLIST_V]

source "[file dirname [info script]]/common.tcl"

set_design_workspace $RESULT_DIR
read_netlist $NETLIST_V
# 标准单元库 + 额外宏库(EXTRA_LIB_FILES,黑盒宏占位 liberty,默认空,见 common.tcl)
read_liberty [concat $LIB_FILES $EXTRA_LIB_FILES]
link_design $DESIGN
read_sdc  $SDC_FILE
report_timing -max_path 5
report_power -toggle 0.1
