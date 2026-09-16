# Eliminate internal alias names before iEDA links the mapped netlist.
# Retain top ports and sequential cell names for readable timing endpoints.
yosys -import
set MAPPED [lindex $argv 0]
set OUTPUT [lindex $argv 1]
set DESIGN [lindex $argv 2]
set PDK [lindex $argv 3]
source scripts/common.tcl
read_verilog $MAPPED
foreach lib $LIB_FILES { read_liberty -lib $lib }
hierarchy -check -top $DESIGN
flatten -noscopeinfo
yosys rename -hide w:*
opt_clean -purge
splitnets -format __v -ports
tee -o [file join [file dirname $OUTPUT] sta_area.txt] stat -liberty [lindex $LIB_FILES 0]
tee -o [file join [file dirname $OUTPUT] sta_check.txt] check -mapped -assert
write_verilog -noattr -noexpr -nohex -nodec -simple-lhs $OUTPUT
