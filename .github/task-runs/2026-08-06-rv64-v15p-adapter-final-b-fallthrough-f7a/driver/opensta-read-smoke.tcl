set lib_path $::env(V15P_SMOKE_STD_LIB)
set netlist_path $::env(V15P_SMOKE_NETLIST)
set marker_path $::env(V15P_SMOKE_MARKER)
file delete -force $marker_path

if {[catch {
  read_liberty $lib_path
  read_verilog $netlist_path
  link_design StaExportCompatFixture
  create_clock -name smoke_clock -period 5.0 [get_ports clk]
  report_checks -path_delay max -group_path_count 1 -digits 6
} smoke_error]} {
  puts stderr "V15P_STA_EXPORT_SMOKE_FAIL: $smoke_error"
  exit 1
}

set marker [open $marker_path w]
puts $marker "status=PASS"
close $marker
exit
