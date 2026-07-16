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

# Exploratory only: remove the common direct-frontend-flush OR pin seen in all
# T3U Top40 paths, so the next unmasked timing family can be classified.  This
# is deliberately not a sign-off constraint and must never be used as closure.
set direct_action_pin [get_pins \
  u_core/u_ooo_core/u_frontend/u_frontend_action_gate/_16_/Y]
if {[llength $direct_action_pin] != 1} {
  error "T3U what-if ABI mismatch: direct_action_pin=[llength $direct_action_pin]"
}
set_false_path -through $direct_action_pin

set report_path [file join $out_dir top40-mask-direct-action.rpt]
report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
