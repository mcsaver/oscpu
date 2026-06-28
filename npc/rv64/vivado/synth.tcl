# Vivado 非工程(OOC)综合脚本：综合 NpcTop 核 RTL，报告时序/关键路径/资源。
# 由 run-synth.sh 通过环境变量传参：FILELIST INCDIR TOP PART PERIOD OUTDIR
set_param general.maxThreads 8

set filelist $::env(FILELIST)
set incdir   $::env(INCDIR)
set top      $::env(TOP)
set part     $::env(PART)
set period   $::env(PERIOD)
set outdir   $::env(OUTDIR)
file mkdir $outdir

# 读取核 RTL（每行一个绝对路径）
set fh [open $filelist r]
set files {}
while {[gets $fh line] >= 0} {
  set line [string trim $line]
  if {$line ne ""} { lappend files $line }
}
close $fh
puts "\[synth\] reading [llength $files] RTL files, top=$top part=$part period=${period}ns"
read_verilog -sv $files

# include 搜索路径需同时含 vsrc/(根) 与 vsrc/include/：文件里既有 "include/define.v"、
# "common/OooSlotFacts.v"(相对 vsrc/)，也有 "define.v"(相对 vsrc/include/)。对齐 Verilator 的 -I。
set vsrcdir [file dirname $incdir]
set incdirs [list $vsrcdir $incdir]
# OOC 综合（不需要约束 I/O 物理引脚；只做逻辑综合 + 时序估计找关键路径）
synth_design -top $top -part $part -mode out_of_context -include_dirs $incdirs \
             -flatten_hierarchy rebuilt

# 时钟约束：用激进周期逼出负 slack，使关键路径显现
create_clock -name clk -period $period [get_ports clk]

report_timing_summary -file $outdir/timing_summary.rpt
# 最差 30 条路径(跨所有端点)，供定位关键路径模块/信号
report_timing -max_paths 30 -nworst 30 -path_type full_clock_expanded \
              -input_pins -file $outdir/timing_paths.rpt
report_utilization -file $outdir/utilization.rpt
puts "\[synth\] done -> $outdir/{timing_summary,timing_paths,utilization}.rpt"
