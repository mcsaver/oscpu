# Copyright 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#===========================================================
#   set parameter
#===========================================================
set DESIGN                  [lindex $argv 0]
set PDK                     [lindex $argv 1]
set VERILOG_FILES           [string map {"\"" ""} [lindex $argv 2]]
set NETLIST_SYN_V           [lindex $argv 3]
set VERILOG_INCLUDE_DIRS    [string map {"\"" ""} [lindex $argv 4]]
set VERILOG_DEFINES         ""
if {[llength $argv] > 5} {
  set VERILOG_DEFINES       [string map {"\"" ""} [lindex $argv 5]]
}
set RESULT_DIR              [file dirname $NETLIST_SYN_V]

source "[file dirname [info script]]/common.tcl"

set CLK_FREQ_MHZ            500
if {[info exists env(CLK_FREQ_MHZ)]} {
  set CLK_FREQ_MHZ          $::env(CLK_FREQ_MHZ)
} else {
  puts "Warning: Environment CLK_FREQ_MHZ is not defined. Use $CLK_FREQ_MHZ MHz by default."
}
set CLK_PERIOD_NS           [expr 1000.0 / $CLK_FREQ_MHZ]
set CLK_PERIOD_PS           [expr 1000.0 * $CLK_PERIOD_NS]
set SYNTH_FLATTEN           1
if {[info exists env(SYNTH_FLATTEN)]} {
  set SYNTH_FLATTEN         $::env(SYNTH_FLATTEN)
}
set SYNTH_SHARE             1
if {[info exists env(SYNTH_SHARE)]} {
  set SYNTH_SHARE           $::env(SYNTH_SHARE)
}
set SYNTH_STOP_AFTER_COARSE 0
if {[info exists env(SYNTH_STOP_AFTER_COARSE)]} {
  set SYNTH_STOP_AFTER_COARSE $::env(SYNTH_STOP_AFTER_COARSE)
}
set SYNTH_PUBLIC_AUTONAME 1
if {[info exists env(SYNTH_PUBLIC_AUTONAME)]} {
  set SYNTH_PUBLIC_AUTONAME $::env(SYNTH_PUBLIC_AUTONAME)
}
set SYNTH_DFF_AUTONAME 1
if {[info exists env(SYNTH_DFF_AUTONAME)]} {
  set SYNTH_DFF_AUTONAME $::env(SYNTH_DFF_AUTONAME)
}
set SYNTH_STA_FLATTEN_EXPORT 0
if {[info exists env(SYNTH_STA_FLATTEN_EXPORT)]} {
  set SYNTH_STA_FLATTEN_EXPORT $::env(SYNTH_STA_FLATTEN_EXPORT)
}
set SYNTH_STAGE_SCC 0
if {[info exists env(SYNTH_STAGE_SCC)]} {
  set SYNTH_STAGE_SCC $::env(SYNTH_STAGE_SCC)
}
set SYNTH_BLACKBOX_MODULES ""
if {[info exists env(SYNTH_BLACKBOX_MODULES)]} {
  set SYNTH_BLACKBOX_MODULES $::env(SYNTH_BLACKBOX_MODULES)
}
set SYNTH_KNOWN_OOC_MODULES ""
if {[info exists env(SYNTH_KNOWN_OOC_MODULES)]} {
  set SYNTH_KNOWN_OOC_MODULES $::env(SYNTH_KNOWN_OOC_MODULES)
}
set SYNTH_COMPOSITE_CENSUS_JSON ""
if {[info exists env(SYNTH_COMPOSITE_CENSUS_JSON)]} {
  set SYNTH_COMPOSITE_CENSUS_JSON $::env(SYNTH_COMPOSITE_CENSUS_JSON)
}
set SYNTH_COMPOSITE_DESIGN_JSON ""
if {[info exists env(SYNTH_COMPOSITE_DESIGN_JSON)]} {
  set SYNTH_COMPOSITE_DESIGN_JSON $::env(SYNTH_COMPOSITE_DESIGN_JSON)
}
set KEEP_HIERARCHY_MODULES ""
if {[info exists env(KEEP_HIERARCHY_MODULES)]} {
  set KEEP_HIERARCHY_MODULES $::env(KEEP_HIERARCHY_MODULES)
}

proc env_flag_enabled {value} {
  set norm [string tolower $value]
  return [expr {!($norm eq "0" || $norm eq "false" || $norm eq "no" || $norm eq "off")}]
}

set SYNTH_FLATTEN_ENABLED [env_flag_enabled $SYNTH_FLATTEN]
set SYNTH_SHARE_ENABLED   [env_flag_enabled $SYNTH_SHARE]
set SYNTH_STOP_AFTER_COARSE_ENABLED [env_flag_enabled $SYNTH_STOP_AFTER_COARSE]
set SYNTH_PUBLIC_AUTONAME_ENABLED [env_flag_enabled $SYNTH_PUBLIC_AUTONAME]
set SYNTH_DFF_AUTONAME_ENABLED [env_flag_enabled $SYNTH_DFF_AUTONAME]
set SYNTH_STA_FLATTEN_EXPORT_ENABLED [env_flag_enabled $SYNTH_STA_FLATTEN_EXPORT]
set SYNTH_STAGE_SCC_ENABLED [env_flag_enabled $SYNTH_STAGE_SCC]

set LIBS [concat {*}[lmap lib $LIB_FILES {concat "-liberty" $lib}]]
set EXCLUDE_CELLS [concat {*}[lmap cell $DONT_USE_CELLS {concat "-dont_use" $cell}]]
set VERILOG_INCLUDE_ARGS [concat {*}[lmap dir $VERILOG_INCLUDE_DIRS {concat "-I$dir"}]]
set VERILOG_DEFINE_ARGS [concat {*}[lmap define $VERILOG_DEFINES {concat "-D$define"}]]

#===========================================================
#   set parameter for ABC
#===========================================================

set SYNTH_STRATEGY "DELAY 4"

set buffering 1
set sizing 1

set driver $BUF_CELL
# unit: pF
set cap_load 1.6

# input pin cap of BUF
set max_FO 24
set max_TR 0

#===========================================================
#   scripts for ABC
#===========================================================

# Create SDC File
set sdc_file $RESULT_DIR/abc.sdc
set outfile [open ${sdc_file} w]
puts $outfile "set_driving_cell ${driver}"
puts $outfile "set_load ${cap_load}"
close $outfile

# Assemble Scripts (By Strategy)
set abc_rs_K    "resub,-K,"
set abc_rs      "resub"
set abc_rsz     "resub,-z"
set abc_rw_K    "rewrite,-K,"
set abc_rw      "rewrite"
set abc_rwz     "rewrite,-z"
set abc_rf      "refactor"
set abc_rfz     "refactor,-z"
set abc_b       "balance"

set abc_resyn2        "${abc_b}; ${abc_rw}; ${abc_rf}; ${abc_b}; ${abc_rw}; ${abc_rwz}; ${abc_b}; ${abc_rfz}; ${abc_rwz}; ${abc_b}"
set abc_share         "strash; multi,-m; ${abc_resyn2}"
set abc_resyn2a       "${abc_b};${abc_rw};${abc_b};${abc_rw};${abc_rwz};${abc_b};${abc_rwz};${abc_b}"
set abc_resyn3        "balance;resub;resub,-K,6;balance;resub,-z;resub,-z,-K,6;balance;resub,-z,-K,5;balance"
set abc_resyn2rs      "${abc_b};${abc_rs_K},6;${abc_rw};${abc_rs_K},6,-N,2;${abc_rf};${abc_rs_K},8;${abc_rw};${abc_rs_K},10;${abc_rwz};${abc_rs_K},10,-N,2;${abc_b},${abc_rs_K},12;${abc_rfz};${abc_rs_K},12,-N,2;${abc_rwz};${abc_b}"

set abc_choice        "fraig_store; ${abc_resyn2}; fraig_store; ${abc_resyn2}; fraig_store; fraig_restore"
set abc_choice2       "fraig_store; balance; fraig_store; ${abc_resyn2}; fraig_store; ${abc_resyn2}; fraig_store; ${abc_resyn2}; fraig_store; fraig_restore"

set abc_map_old_cnt			"map,-p,-a,-B,0.2,-A,0.9,-M,0"
set abc_map_old_dly     "map,-p,-B,0.2,-A,0.9,-M,0"
set abc_retime_area     "retime,-D,{D},-M,5"
set abc_retime_dly      "retime,-D,{D},-M,6"
set abc_map_new_area    "amap,-m,-Q,0.1,-F,20,-A,20,-C,5000"

set abc_area_recovery_1 "${abc_choice}; map;"
set abc_area_recovery_2 "${abc_choice2}; map;"

set map_old_cnt			    "map,-p,-a,-B,0.2,-A,0.9,-M,0"
set map_old_dly			    "map,-p,-B,0.2,-A,0.9,-M,0"
set abc_retime_area   	"retime,-D,{D},-M,5"
set abc_retime_dly    	"retime,-D,{D},-M,6"
set abc_map_new_area  	"amap,-m,-Q,0.1,-F,20,-A,20,-C,5000"

if {$buffering==1} {
  set max_tr_arg ""
  if { $max_TR != 0 } {
    set max_tr_arg ",-S,${max_TR}"
  }
  set abc_fine_tune		"buffer,-N,${max_FO}${max_tr_arg};upsize,{D};dnsize,{D}"
} elseif {$sizing} {
  set abc_fine_tune   "upsize,{D};dnsize,{D}"
} else {
  set abc_fine_tune   ""
}

set delay_scripts [list \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_dly}; scleanup;${abc_map_old_dly};retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_dly}; scleanup;${abc_choice2};${abc_map_old_dly};${abc_area_recovery_2}; retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_dly}; scleanup;${abc_choice};${abc_map_old_dly};${abc_area_recovery_1}; retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_area};scleanup;${abc_choice2};${abc_map_new_area};${abc_choice2};${abc_map_old_dly};retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  "+&get -n;&st;&dch;&nf,{D};&put;&get -n;&st;&syn2;&if -g -K 6;&synch2;&nf;&put;&get -n;&st;&syn2;&if -g -K 6;&synch2;&nf;&put;&get -n;&st;&syn2;&if -g -K 6;&synch2;&nf;&put;&get -n;&st;&syn2;&if -g -K 6;&synch2;&nf;&put;&get -n;&st;&syn2;&if -g -K 6;&synch2;&nf;&put;buffer -c -N ${max_FO};topo;stime -c;upsize,{D};dnsize,{D};;stime,-p;print_stats -m" \
  ]

set area_scripts [list \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_area};scleanup;${abc_choice2};${abc_map_new_area};retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  \
  "+fx;mfs;strash;refactor;${abc_resyn2};${abc_retime_area};scleanup;${abc_choice2};${abc_map_new_area};${abc_choice2};${abc_map_new_area};retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  \
  "+fx;mfs;strash;refactor;${abc_choice2};${abc_retime_area};scleanup;${abc_choice2};${abc_map_new_area};${abc_choice2};${abc_map_new_area};retime,-D,{D};&get,-n;&st;&dch;&nf;&put;${abc_fine_tune};stime,-p;print_stats -m" \
  "+strash;dch;map -B 0.9;topo;stime -c;buffer -c -N ${max_FO};upsize -c;dnsize -c;stime,-p;print_stats -m" \
  ]

set strategy_parts [split $SYNTH_STRATEGY]

proc synth_strategy_format_err { } {
  upvar area_scripts area_scripts
  upvar delay_scripts delay_scripts
  log -stderr "\[ERROR] Misformatted SYNTH_STRATEGY (\"$SYNTH_STRATEGY\")."
  log -stderr "\[ERROR] Correct format is \"DELAY|AREA 0-[expr [llength $delay_scripts]-1]|0-[expr [llength $area_scripts]-1]\"."
  exit 1
}

proc strategy_consumes_delay_target {script} {
  # Yosys only substitutes {D}; require it on an ABC command that actually
  # consumes a delay target.  A decoy occurrence (for example in echo text)
  # must not make a DELAY strategy appear constrained.
  return [regexp {(^|;)[[:space:]]*(&nf|upsize|dnsize)[^;]*\{D\}} $script]
}

if { [llength $strategy_parts] != 2 } {
  synth_strategy_format_err
}

set strategy_type [lindex $strategy_parts 0]
set strategy_type_idx [lindex $strategy_parts 1]

if { $strategy_type != "AREA" && $strategy_type != "DELAY" } {
  log -stderr "\[ERROR] AREA|DELAY tokens not found. ($strategy_type)"
  synth_strategy_format_err
}

if { $strategy_type == "DELAY" && $strategy_type_idx >= [llength $delay_scripts] } {
  log -stderr "\[ERROR] strategy index ($strategy_type_idx) is too high."
  synth_strategy_format_err
}

if { $strategy_type == "AREA" && $strategy_type_idx >= [llength $area_scripts] } {
  log -stderr "\[ERROR] strategy index ($strategy_type_idx) is too high."
  synth_strategy_format_err
}

set strategy_name "$strategy_type-$strategy_type_idx"
if { $strategy_type == "DELAY" } {
  set strategy_script [lindex $delay_scripts $strategy_type_idx]
} else {
  set strategy_script [lindex $area_scripts $strategy_type_idx]
}

# Custom ABC scripts do not consume `abc -D` unless they contain {D}.  A
# target-less DELAY strategy silently turns a frequency-specific synthesis run
# into an unconstrained mapping run, while the later STA still reports against
# the requested clock.  Fail closed so the netlist provenance cannot lie.
if {$strategy_type == "DELAY" &&
    ![strategy_consumes_delay_target $strategy_script]} {
  puts stderr "\[ERROR\] DELAY strategy $strategy_name does not pass {D} to &nf/upsize/dnsize; refusing target-less ABC mapping."
  exit 1
}

#===========================================================
#   main running
#===========================================================
yosys -import

# Optional mapped-loop localization.  Each sample operates on a pushed copy,
# replaces standard-cell blackboxes with their Liberty Boolean functions, then
# flattens only that copy.  The production mapping state is restored unchanged
# before the next pass.  Reports are compact; expanded diagnostic designs are
# never written to disk.
proc capture_functional_flat_scc {stage} {
  global DESIGN RESULT_DIR LIB_FILES
  log "\[INFO\]: CAPTURING functional flat SCC at $stage"
  design -push-copy
  foreach l $LIB_FILES {
    read_liberty -overwrite -ignore_miss_func -ignore_miss_data_latch $l
    # Clock-gate outputs in this PDK intentionally omit Boolean `function`.
    # Restore only cells skipped by the functional import as blackbox shells;
    # -nooverwrite preserves every combinational function already loaded.
    read_liberty -lib -nooverwrite $l
  }
  setattr -unset keep_hierarchy */*
  setattr -mod -unset keep_hierarchy *
  hierarchy -check -top $DESIGN
  flatten -noscopeinfo
  hierarchy -check -top $DESIGN
  opt_clean -purge
  tee -o $RESULT_DIR/synth_scc_${stage}.txt \
    scc -set_attr synth_stage_scc_id {}
  tee -o $RESULT_DIR/synth_scc_${stage}_dump.txt \
    dump a:synth_stage_scc_id
  select -clear
  design -pop
}

# read verilog files
foreach file $VERILOG_FILES {
  read_verilog -sv {*}$VERILOG_INCLUDE_ARGS {*}$VERILOG_DEFINE_ARGS $file
}

foreach module $SYNTH_BLACKBOX_MODULES {
  if {$module eq ""} {
    continue
  }
  log "\[INFO\]: MARKING module $module as synthesis blackbox boundary"
  select -module $module
  blackbox
  select -clear
}

# Known OOC children are blackboxes only in the composite top run, where their
# exact sequential Liberty models are supplied separately.  Keep the explicit
# class projection distinct from legacy unknown placeholders and fail closed if
# a known macro was not included in the actual synthesis blackbox arguments.
foreach module $SYNTH_KNOWN_OOC_MODULES {
  if {$module eq ""} {
    continue
  }
  if {[lsearch -exact $SYNTH_BLACKBOX_MODULES $module] < 0} {
    error "known OOC module is absent from SYNTH_BLACKBOX_MODULES: $module"
  }
  log "\[INFO\]: CLASSIFYING module $module as known OOC macro boundary"
}

# 级间边界治理(pipeline-stage-boundary.md §6)：flatten 前保留指定模块层次，
# 让 ABC 沿寄存器边界切 cone。必须先显式 elaborate 派生 $paramod 实体再 setattr——
# read_verilog 后直接 setattr 落在 AST 占位上，synth 内部重派生时属性丢失(实测)。
if {[llength $KEEP_HIERARCHY_MODULES] > 0} {
  hierarchy -check -top $DESIGN
  foreach module $KEEP_HIERARCHY_MODULES {
    if {$module eq ""} {
      continue
    }
    log "\[INFO\]: KEEPING hierarchy of module $module through flatten"
    # 三种命名形态都要覆盖：原名(无参数化实例)、可读 paramod($paramod\Mod\P=V)、
    # 哈希 paramod($paramod$<hash>\Mod——参数值长时 yosys 用哈希, 模块名在末尾,
    # 实测 OooRob 等 7 keep 模块 5 个走此形态而漏保, 故补 "=*\\Mod" 后缀匹配)。
    setattr -mod -set keep_hierarchy 1 $module "=\$paramod*$module\\*" "=*\\$module"
  }
}

# generic synthesis (coarse)
set synth_args [list -top $DESIGN]
if {!$SYNTH_SHARE_ENABLED} {
  lappend synth_args -noshare
}
if {$SYNTH_FLATTEN_ENABLED} {
  lappend synth_args -flatten
}
lappend synth_args -run :fine
synth {*}$synth_args

if {!$SYNTH_SHARE_ENABLED} {
  log "\[INFO\]: SKIPPING SAT resource sharing passes"
} else {
  share -aggressive
}
onehot
muxpack
opt_demorgan
opt_ffinv

if {$SYNTH_STOP_AFTER_COARSE_ENABLED} {
  log "\[INFO\]: STOPPING after coarse generic synthesis"
  opt_clean -purge
  tee -o $RESULT_DIR/synth_scc.txt scc -set_attr synth_scc_id {}
  tee -o $RESULT_DIR/synth_scc_dump.txt dump a:synth_scc_id
  select -clear
  select *
  tee -o $RESULT_DIR/synth_check.txt check
  tee -o $RESULT_DIR/synth_stat.txt stat
  write_json $NETLIST_SYN_V.json
  write_rtlil $NETLIST_SYN_V.il
  write_verilog -sv -noattr -nohex -nodec $NETLIST_SYN_V
  exit
}

# generic synthesis (fine)
synth -run fine:

# remove unused cells and wires
opt_clean -purge

# split internal nets
splitnets -format __v
if {$SYNTH_DFF_AUTONAME_ENABLED} {
  # rename DFFs from the driven signal
  yosys rename -wire -suffix _reg_p t:*DFF*_P*
  yosys rename -wire -suffix _reg_n t:*DFF*_N*
  # rename all other cells
  autoname t:*DFF* %n
} else {
  log "\[INFO\]: SKIPPING DFF/cell autoname"
}

# technology mapping for clockgate
clockgate {*}$LIBS {*}$EXCLUDE_CELLS

# technology mapping for flip-flops
dfflibmap {*}$LIBS {*}$EXCLUDE_CELLS

# optimize the design
opt -undriven -purge

log "\[INFO\]: USING STRATEGY $strategy_name"
if {$strategy_type == "DELAY"} {
  log "\[INFO\]: ABC DELAY TARGET ${CLK_PERIOD_PS}ps (injected through {D})"
}

# technology mapping for cells
abc -D "$CLK_PERIOD_PS" \
  -constr "$sdc_file" \
  {*}$LIBS {*}$EXCLUDE_CELLS \
  -script "$strategy_script" \
  -showtmp

if {$SYNTH_STAGE_SCC_ENABLED} {
  capture_functional_flat_scc post_abc
}

# technology mapping for constant hi- and/or lo-drivers
hilomap -singleton -hicell {*}$TIEHI_CELL_AND_PORT -locell {*}$TIELO_CELL_AND_PORT

# replace undef values with defined constants
setundef -zero

# STA netlists must not carry simulation/formal side-effect cells. Yosys can
# preserve $print cells generated from $error/$fatal checks; iEDA's Verilog
# parser cannot read those cells or their defparam payload, and they are not
# part of the synthesized hardware timing graph.
delete t:\$print t:\$assert t:\$assume t:\$cover t:\$check

# remove unused cells and wires
opt_clean -purge

if {$SYNTH_STAGE_SCC_ENABLED} {
  capture_functional_flat_scc post_hilomap
}

# Generate public names for the various nets, resulting in very long names that include
# the full heirarchy, which is preferable to the internal names that are simply
# sequential numbers such as `_000019_`. Renamed net names can be very long, such as:
#     manual_reset_gf180mcu_fd_sc_mcu7t5v0__dffq_1_Q_D_gf180mcu_ \
#     fd_sc_mcu7t5v0__nor3_1_ZN_A1_gf180mcu_fd_sc_mcu7t5v0__aoi21_ \
#     1_A2_A1_gf180mcu_fd_sc_mcu7t5v0__nand3_1_ZN_A3_gf180mcu_fd_ \
#     sc_mcu7t5v0__and3_1_A3_Z_gf180mcu_fd_sc_mcu7t5v0__buf_1_I_Z
if {$SYNTH_PUBLIC_AUTONAME_ENABLED} {
  autoname
} else {
  log "\[INFO\]: SKIPPING public net autoname"
}

# write synthesized design for netlist simulation without splitting module ports
write_verilog -noattr -noexpr -nohex -nodec $NETLIST_SYN_V.sim

# splitting nets resolves unwanted compound assign statements in netlist (assign {..} = {..}
splitnets -format __v -ports

# remove unused cells and wires
opt_clean -purge

# load liberty file before checking
foreach l $LIB_FILES { read_liberty -lib $l }

# reports
# A mapped check that only prints diagnostics can silently leave $mul/$mux and
# other generic cells.  -assert makes any unmapped cell a non-zero Yosys exit.
tee -o $RESULT_DIR/synth_check.txt check -mapped -assert
tee -o $RESULT_DIR/synth_stat.txt stat {*}$LIBS
if {$SYNTH_COMPOSITE_CENSUS_JSON ne ""} {
  if {[file pathtype $SYNTH_COMPOSITE_CENSUS_JSON] ne "absolute"} {
    error "SYNTH_COMPOSITE_CENSUS_JSON must be absolute"
  }
  file mkdir [file dirname $SYNTH_COMPOSITE_CENSUS_JSON]
  tee -o $SYNTH_COMPOSITE_CENSUS_JSON stat -json {*}$LIBS
}
if {$SYNTH_COMPOSITE_DESIGN_JSON ne ""} {
  if {[file pathtype $SYNTH_COMPOSITE_DESIGN_JSON] ne "absolute"} {
    error "SYNTH_COMPOSITE_DESIGN_JSON must be absolute"
  }
  file mkdir [file dirname $SYNTH_COMPOSITE_DESIGN_JSON]
  # Retain the exact pre-cleanup port/cell/instance graph used to generate the
  # human-independent manifest; this is distinct from the aggregate stat JSON.
  write_json $SYNTH_COMPOSITE_DESIGN_JSON
}

# Keep mapping and recursive area accounting in the requested hierarchy.  Some
# standalone STA Verilog readers accept a narrower structural subset than the
# Yosys backend emits for parameter-derived hierarchy.  When requested, make
# only the final STA handoff flat and identifier-safe; the mapped cells and
# pre-export reports above remain unchanged.
if {$SYNTH_STA_FLATTEN_EXPORT_ENABLED} {
  log "\[INFO\]: FLATTENING mapped hierarchy only for STA netlist export"
  setattr -unset keep_hierarchy */*
  setattr -mod -unset keep_hierarchy *
  flatten -noscopeinfo
  hierarchy -check -top $DESIGN
  splitnets -format __v -ports
  opt_clean -purge
  yosys rename -unescape */*
  # OooFpArithGate is frozen as a fixed-interface Liberty macro for this
  # handoff.  Its elaboration parameters have already determined the port
  # widths, and standalone OpenSTA does not accept named instance overrides.
  setparam -unset ROB_INDEX_W -unset PRODUCER_GEN_W \
    -unset PRODUCER_ID_W -unset PHY_REG_ADDR_W t:OooFpArithGate
  if {$SYNTH_STAGE_SCC_ENABLED} {
    capture_functional_flat_scc post_export
  }
  tee -o $RESULT_DIR/sta_export_check.txt check -mapped -assert
}

# write synthesized design
write_verilog -noattr -noexpr -nohex -nodec -simple-lhs $NETLIST_SYN_V
