proc require_arg {dict key} {
  if {![dict exists $dict $key]} {
    error "missing required argument: $key"
  }
  return [dict get $dict $key]
}

proc parse_args {argv} {
  set opts [dict create]
  set i 0
  while {$i < [llength $argv]} {
    set key [lindex $argv $i]
    if {![string match "-*" $key]} {
      error "unexpected argument: $key"
    }
    set key [string trimleft $key "-"]
    incr i
    if {$i >= [llength $argv]} {
      error "missing value for $key"
    }
    dict set opts $key [lindex $argv $i]
    incr i
  }
  return $opts
}

set opts [parse_args $argv]
set root [file normalize [require_arg $opts root]]
set project_name [require_arg $opts project-name]
set project_dir [file normalize [require_arg $opts project-dir]]
set part [require_arg $opts part]
set top [require_arg $opts top]
set filelist [file normalize [require_arg $opts filelist]]
set clock_period [require_arg $opts clock-period]
set vivado_threads [require_arg $opts vivado-threads]
set synth_directive [require_arg $opts synth-directive]
set synth_flatten [require_arg $opts synth-flatten]
set run_synth [require_arg $opts run-synth]

set report_dir [file normalize [file join $root fpga reports]]
set constraints_file [file normalize [file join $root fpga constraints rv64_core_ooc.xdc]]
set include_dir [file normalize [file join $root npc rv64 vsrc include]]

file mkdir $project_dir
file mkdir $report_dir

puts "== RV64 NPC Vivado project =="
puts "root           : $root"
puts "project        : $project_dir"
puts "part           : $part"
puts "top            : $top"
puts "filelist       : $filelist"
puts "clock period ns: $clock_period"
puts "vivado threads : $vivado_threads"
puts "synth directive: $synth_directive"
puts "synth flatten  : $synth_flatten"
puts "run synth      : $run_synth"

if {[catch {set_param general.maxThreads $vivado_threads} param_err]} {
  puts "WARNING: failed to set general.maxThreads: $param_err"
}

create_project -force $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]
set_property source_mgmt_mode All [current_project]

set fp [open $filelist r]
set rtl_files {}
while {[gets $fp line] >= 0} {
  set line [string trim $line]
  if {$line eq "" || [string match "#*" $line]} {
    continue
  }
  lappend rtl_files [file normalize $line]
}
close $fp

if {[llength $rtl_files] == 0} {
  error "empty RTL filelist: $filelist"
}

add_files -norecurse -fileset sources_1 $rtl_files
set_property include_dirs [list $include_dir] [get_filesets sources_1]
set_property verilog_define {SYNTHESIS=1} [get_filesets sources_1]
set_property top $top [get_filesets sources_1]

if {[file exists $constraints_file]} {
  add_files -fileset constrs_1 $constraints_file
  set_property used_in_synthesis true [get_files $constraints_file]
}

update_compile_order -fileset sources_1
report_compile_order -fileset sources_1 -file [file join $report_dir compile_order.rpt]

if {$run_synth eq "1"} {
  synth_design -top $top -part $part -mode out_of_context \
    -directive $synth_directive -flatten_hierarchy $synth_flatten
  if {[llength [get_clocks -quiet core_clk]] == 0} {
    create_clock -name core_clk -period $clock_period [get_ports clk]
  }
  report_utilization -hierarchical -file [file join $report_dir utilization_hier.rpt]
  report_utilization -file [file join $report_dir utilization.rpt]
  report_timing_summary -delay_type max -max_paths 20 -report_unconstrained \
    -file [file join $report_dir timing_summary.rpt]
  report_high_fanout_nets -timing -load_types -max_nets 50 \
    -file [file join $report_dir high_fanout_nets.rpt]
  report_drc -file [file join $report_dir drc.rpt]
  write_checkpoint -force [file join $report_dir ${top}_synth.dcp]
  write_verilog -force [file join $report_dir ${top}_synth.v]
}

close_project
