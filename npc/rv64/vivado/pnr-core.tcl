# Vivado 整核 P&R:synth(OOC)→opt→place→route,取【真实布线后】WNS,解阻塞 dispatch 流水化净收益判断。
# OOC 模块综合的 route 不可信(unplaced);本流程做真正 place+route 给可信时序。
# 由 run-pnr-core.sh 传参:FILELIST INCDIR TOP PART PERIOD OUTDIR
# 内存友好:maxThreads 2、-flatten_hierarchy none(全展平是 WSL 崩溃根因)。
set_param general.maxThreads 2

set filelist $::env(FILELIST)
set incdir   $::env(INCDIR)
set top      $::env(TOP)
set part     $::env(PART)
set period   $::env(PERIOD)
set outdir   $::env(OUTDIR)
file mkdir $outdir

set fh [open $filelist r]
set files {}
while {[gets $fh line] >= 0} {
  set line [string trim $line]
  if {$line ne ""} { lappend files $line }
}
close $fh
puts "\[pnr\] reading [llength $files] RTL files, top=$top part=$part period=${period}ns"
read_verilog -sv $files

set vsrcdir [file dirname $incdir]
set incdirs [list $vsrcdir $incdir]

# OOC 综合(不绑物理引脚),但保持层级以省内存(不全展平)
synth_design -top $top -part $part -mode out_of_context -include_dirs $incdirs \
             -flatten_hierarchy none
create_clock -name clk -period $period [get_ports clk]

# --- opt + place + route:得到真实布线时序 ---
opt_design
puts "\[pnr\] opt_design done"
place_design
puts "\[pnr\] place_design done"
report_timing_summary -file $outdir/timing_placed.rpt
phys_opt_design
route_design
puts "\[pnr\] route_design done"

# 布线后真实时序(WNS 可信)
report_timing_summary -file $outdir/timing_routed.rpt
report_timing -max_paths 30 -nworst 30 -path_type full_clock_expanded \
              -input_pins -file $outdir/timing_routed_paths.rpt
report_utilization -file $outdir/utilization.rpt
puts "\[pnr\] done -> $outdir/{timing_placed,timing_routed,timing_routed_paths,utilization}.rpt"
