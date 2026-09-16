# Versioned entry for one registered FP production-child OOC mapping.
# The implementation delegates the technology mapping recipe to the shared
# yosys-sta script; this entry only freezes the legal child/source boundary and
# rejects accidental blackboxing or top-level reuse.

set fp_ooc_children {
  OooFpAddSubPipe
  OooFpMulProductPipe
  OooFpMulNormRoundPipe
  OooFpFmaAlignAddPipe
  OooFpFmaNormRoundPipe
}

if {![info exists ::env(FP_OOC_CHILD_MODULE)] ||
    $::env(FP_OOC_CHILD_MODULE) eq ""} {
  error "FP_OOC_CHILD_MODULE is required"
}
set fp_ooc_child $::env(FP_OOC_CHILD_MODULE)
if {$fp_ooc_child ni $fp_ooc_children} {
  error "unregistered FP OOC child: $fp_ooc_child"
}
if {![info exists ::env(FP_OOC_PROFILE)] ||
    $::env(FP_OOC_PROFILE) ne "fp-arith-ooc-composite-v1"} {
  error "child synthesis profile differs from fp-arith-ooc-composite-v1"
}
if {[llength $argv] < 5 || [lindex $argv 0] ne $fp_ooc_child} {
  error "Yosys top/FP_OOC_CHILD_MODULE mismatch"
}
if {[info exists ::env(SYNTH_BLACKBOX_MODULES)] &&
    $::env(SYNTH_BLACKBOX_MODULES) ne ""} {
  error "child OOC synthesis cannot carry top-level blackboxes"
}
if {[info exists ::env(SYNTH_KNOWN_OOC_MODULES)] &&
    $::env(SYNTH_KNOWN_OOC_MODULES) ne ""} {
  error "child OOC synthesis cannot recursively instantiate known OOC macros"
}
if {![info exists ::env(SYNTH_COMPOSITE_CENSUS_JSON)] ||
    $::env(SYNTH_COMPOSITE_CENSUS_JSON) eq ""} {
  error "child OOC synthesis requires a machine census output"
}
if {![info exists ::env(SYNTH_COMPOSITE_DESIGN_JSON)] ||
    $::env(SYNTH_COMPOSITE_DESIGN_JSON) eq ""} {
  error "child OOC synthesis requires a retained port/leaf/instance design JSON"
}
set ::env(KEEP_HIERARCHY_MODULES) $fp_ooc_child
set ::env(SYNTH_FLATTEN) 0
set ::env(SYNTH_SHARE) 0
set ::env(SYNTH_STOP_AFTER_COARSE) 0
set ::env(SYNTH_STA_FLATTEN_EXPORT) 0

set shared_yosys [file normalize \
  [file join [file dirname [info script]] ../../../../yosys-sta/scripts/yosys.tcl]]
if {![file exists $shared_yosys] || [file type $shared_yosys] ne "file"} {
  error "shared yosys-sta entry is missing: $shared_yosys"
}
source $shared_yosys
