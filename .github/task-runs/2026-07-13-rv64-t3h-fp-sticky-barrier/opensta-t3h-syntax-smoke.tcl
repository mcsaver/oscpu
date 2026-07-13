# Plain Tcl syntax/control-flow smoke.  OpenSTA commands are stubbed; the real
# post-synthesis run must still prove non-empty collections and timing results.
proc unknown {args} {
  return {}
}
set ::env(T3H_STA_NETLIST) "/tmp/t3h-opensta-syntax-empty.v"
set ::env(T3H_STA_OUT_DIR) "/tmp/t3h-opensta-syntax-smoke"
set ::env(T3H_STA_STD_LIB) "/tmp/t3h-opensta-syntax-empty.lib"
set ::env(T3H_STA_MACRO_LIBS) "/tmp/t3h-opensta-syntax-empty.lib"
set ::env(T3H_STA_PERIOD_NS) "5.0"
source [file join [file dirname [info script]] opensta-t3h-focused.tcl]
