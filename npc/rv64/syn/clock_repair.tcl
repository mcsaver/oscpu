# Run in yosys-sta, using the original common.tcl/PDK library selection.
# Load the design only after Python exits, avoiding concurrent full netlists.
if {[llength $argv] < 4} {
  error "clock_repair.tcl INPUT OUTPUT DESIGN PDK ?repair_clock_fanout.py options?"
}
set INPUT [lindex $argv 0]
set OUTPUT [lindex $argv 1]
set DESIGN [lindex $argv 2]
set PDK [lindex $argv 3]
if {[file normalize $INPUT] eq [file normalize $OUTPUT]} {
  error "Clock repair output must be separate from the parent flat netlist"
}
source scripts/common.tcl
set command [list python3 [file join [file dirname [info script]] repair_clock_fanout.py]]
lappend command {*}[lrange $argv 4 end]
# Bind source and outputs last so tuning flags cannot replace these paths.
lappend command --netlist $INPUT
foreach lib $ALL_LIB_FILES { lappend command --liberty $lib }
lappend command --output $OUTPUT --manifest [file join [file dirname $OUTPUT] cell-changes.json]
puts [exec {*}$command 2>@1]
yosys -import
foreach lib $ALL_LIB_FILES { read_liberty -lib $lib }
read_verilog $OUTPUT
hierarchy -check -top $DESIGN
set REPORT_LIBS [concat {*}[lmap lib $ALL_LIB_FILES {concat "-liberty" $lib}]]
tee -o [file join [file dirname $OUTPUT] synth_check.txt] check -mapped -assert
tee -o [file join [file dirname $OUTPUT] synth_stat.txt] stat {*}$REPORT_LIBS
