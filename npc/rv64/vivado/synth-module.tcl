# Vivado 轻量【按模块】OOC 综合：只综合指定模块子树，内存/时间骤降，避免整核综合撑爆 WSL。
# 环境变量：FILELIST INCDIR TOP(要分析的模块) PART PERIOD OUTDIR
set_param general.maxThreads 2

set filelist $::env(FILELIST)
set incdir   $::env(INCDIR)
set top      $::env(TOP)
set part     $::env(PART)
set period   $::env(PERIOD)
set outdir   $::env(OUTDIR)
file mkdir $outdir

set fh [open $filelist r]; set files {}
while {[gets $fh line] >= 0} { set line [string trim $line]; if {$line ne ""} { lappend files $line } }
close $fh
read_verilog -sv $files
set vsrcdir [file dirname $incdir]

# -flatten_hierarchy none：保留层次，内存远低于 rebuilt(整核展平是崩溃主因之一)。
# 只从 $top 向下综合，其余文件仅作依赖解析，不进入网表。
synth_design -top $top -part $part -mode out_of_context \
             -include_dirs [list $vsrcdir $incdir] -flatten_hierarchy none

create_clock -name clk -period $period [get_ports -quiet clk]
report_timing_summary -file $outdir/timing_summary.rpt
report_timing -max_paths 10 -nworst 10 -file $outdir/timing_paths.rpt
report_utilization -file $outdir/utilization.rpt
# 摘要：最差路径延迟(数据路径 ns)
puts "\[synth-module\] $top done -> $outdir"
