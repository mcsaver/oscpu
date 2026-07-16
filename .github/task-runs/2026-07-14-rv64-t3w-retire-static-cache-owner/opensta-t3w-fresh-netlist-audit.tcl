# T3W mapped-netlist directed audit.  This is a clean 5.000 ns timing run:
# there are deliberately no false paths, disabled arcs, case analyses or
# exploratory masks in this file.

proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable missing: $name"
  }
  return $::env($name)
}

proc require_count {label objects expected} {
  set count [llength $objects]
  if {$count != $expected} {
    error "$label object count mismatch: expected=$expected actual=$count"
  }
}

proc require_min_count {label objects minimum} {
  set count [llength $objects]
  if {$count < $minimum} {
    error "$label object count too small: minimum=$minimum actual=$count"
  }
}

proc pin_leaf {pin} {
  return [lindex [split [get_full_name $pin] "/"] end]
}

# Return Q/QN pins, their matching D pins and cells for state whose mapped Q
# net retains the requested RTL name.  The count checks make this fail closed
# if synthesis renames, clones or optimizes the intended boundary.
proc collect_named_state {hierarchy_prefix net_pattern} {
  set q_pins {}
  set d_pins {}
  set state_cells {}
  foreach cell [get_cells -hierarchical *] {
    set cell_name [get_full_name $cell]
    if {![string match "$hierarchy_prefix/*" $cell_name]} {
      continue
    }
    set cell_match 0
    foreach pin [get_pins -quiet -of_objects $cell] {
      set leaf [pin_leaf $pin]
      if {[get_property $pin direction] ne "output" ||
          ($leaf ne "Q" && $leaf ne "QN")} {
        continue
      }
      foreach net [get_nets -quiet -of_objects $pin] {
        if {[string match "$hierarchy_prefix/$net_pattern" [get_full_name $net]]} {
          lappend q_pins $pin
          set cell_match 1
        }
      }
    }
    if {$cell_match} {
      lappend state_cells $cell
      foreach pin [get_pins -quiet -of_objects $cell] {
        if {[get_property $pin direction] eq "input" && [pin_leaf $pin] eq "D"} {
          lappend d_pins $pin
        }
      }
    }
  }
  return [list [lsort -unique $q_pins] [lsort -unique $d_pins] \
               [lsort -unique $state_cells]]
}

proc path_count {report_path} {
  set stream [open $report_path r]
  set contents [read $stream]
  close $stream
  return [regexp -all -line {^Startpoint:} $contents]
}

proc require_required_report {label report_path} {
  set count [path_count $report_path]
  if {$count < 1} {
    error "$label required path missing: $report_path"
  }
}

proc require_forbidden_report {label report_path} {
  set count [path_count $report_path]
  if {$count != 0} {
    error "$label forbidden path present count=$count: $report_path"
  }
}

set netlist [file normalize [require_env T3W_AUDIT_NETLIST]]
set out_dir [file normalize [require_env T3W_AUDIT_OUT_DIR]]
set std_lib [file normalize [require_env T3W_AUDIT_STD_LIB]]
set macro_raw [require_env T3W_AUDIT_MACRO_LIBS]
set structural_manifest [file normalize \
  [require_env T3W_AUDIT_STRUCTURAL_MANIFEST]]

file mkdir $out_dir
read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

set fifo_prefix u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo
set ifu_prefix u_core/u_ooo_fetch_bridge
set rob_prefix \
  u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob
set dcache_prefix u_core/u_ooo_mem_bridge/u_dcache

lassign [collect_named_state $fifo_prefix "head_q_*"] \
  fifo_head_q_pins fifo_head_d_pins fifo_head_cells
lassign [collect_named_state $ifu_prefix "pc_q_*"] \
  ifu_pc_q_pins ifu_pc_d_pins ifu_pc_cells
lassign [collect_named_state $ifu_prefix "lookup_exec_paddr_q_*"] \
  ifu_lookup_q_pins ifu_lookup_d_pins ifu_lookup_cells

require_count fifo_head_q_pins $fifo_head_q_pins 2
require_count fifo_head_d_pins $fifo_head_d_pins 2
require_min_count ifu_pc_q_pins $ifu_pc_q_pins 60
require_min_count ifu_lookup_q_pins $ifu_lookup_q_pins 60

set fifo_production_pins {}
foreach pattern [list \
  head_pc0_o* head_pc1_o* head_next_pc0_o* head_next_pc1_o* \
  head_packet_next_pc_o* head_inst0_o* head_inst1_o* \
  head_ctrl0_o* head_ctrl1_o* head_static_facts0_o* head_static_facts1_o* \
  head_rs1_0_o* head_rs2_0_o* head_rd0_o* head_imm0_o* \
  head_rs1_1_o* head_rs2_1_o* head_rd1_o* head_imm1_o* \
  head_resp0_o* head_resp1_o* head_pred_taken0_o* head_pred_taken1_o* \
  head_bht_idx0_o* head_bht_idx1_o* head_bht_valid0_o* head_bht_valid1_o* \
  head_slot1_valid_o*] {
  set fifo_production_pins [concat $fifo_production_pins \
    [get_pins -quiet "$fifo_prefix/$pattern"]]
}
set fifo_production_pins [lsort -unique $fifo_production_pins]
require_count fifo_production_pins $fifo_production_pins 709

# head_packet_q names are intentionally allowed to coalesce with output port
# nets in the mapped Verilog.  The independent Python connectivity audit emits
# the exact 709 mapped owner cells; resolve every name again in OpenSTA so a
# stale or forged handoff fails closed.
set fifo_shadow_q_pins {}
set fifo_shadow_d_pins {}
set fifo_shadow_cells {}
set manifest_stream [open $structural_manifest r]
set manifest_contents [read $manifest_stream]
close $manifest_stream
foreach line [split [string trim $manifest_contents] "\n"] {
  lassign $line object_kind cell_leaf
  if {$object_kind ne "fifo_shadow_cell" ||
      ![regexp {^_[0-9]+_$} $cell_leaf]} {
    error "invalid structural manifest line: $line"
  }
  set cells [get_cells -quiet "$fifo_prefix/$cell_leaf"]
  require_count fifo_shadow_manifest_cell $cells 1
  foreach cell $cells {
    lappend fifo_shadow_cells $cell
    foreach cell_pin [get_pins -quiet -of_objects $cell] {
      set leaf [pin_leaf $cell_pin]
      set direction [get_property $cell_pin direction]
      if {$direction eq "output" && ($leaf eq "Q" || $leaf eq "QN")} {
        lappend fifo_shadow_q_pins $cell_pin
      }
      if {$direction eq "input" && $leaf eq "D"} {
        lappend fifo_shadow_d_pins $cell_pin
      }
    }
  }
}
set fifo_shadow_q_pins [lsort -unique $fifo_shadow_q_pins]
set fifo_shadow_d_pins [lsort -unique $fifo_shadow_d_pins]
set fifo_shadow_cells [lsort -unique $fifo_shadow_cells]
require_count fifo_shadow_cells $fifo_shadow_cells 709
require_count fifo_shadow_q_pins $fifo_shadow_q_pins 709
require_count fifo_shadow_d_pins $fifo_shadow_d_pins 709

set ifu_pmp0_paddr_pins [get_pins -quiet \
  "$ifu_prefix/u_req_exec_pmp_checker/paddr_i_*"]
set ifu_pmp1_paddr_pins [get_pins -quiet \
  "$ifu_prefix/u_req_exec1_pmp_checker/paddr_i_*"]
require_count ifu_pmp0_paddr_pins $ifu_pmp0_paddr_pins 64
require_count ifu_pmp1_paddr_pins $ifu_pmp1_paddr_pins 64

set rob_wb_pins [concat \
  [get_pins -quiet "$rob_prefix/wb0_*"] \
  [get_pins -quiet "$rob_prefix/wb1_*"]]
set rob_wb_data_pins [concat \
  [get_pins -quiet "$rob_prefix/wb0_data_i_*"] \
  [get_pins -quiet "$rob_prefix/wb1_data_i_*"]]
set rob_commit_pins {}
foreach lane [list 0 1] {
  foreach field [list \
    valid pc next_pc inst rd_en is_fp_rd fflags arch_rd old_pdest \
    new_pdest data exception cause tval] {
    set rob_commit_pins [concat $rob_commit_pins \
      [get_pins -quiet "$rob_prefix/commit${lane}_${field}_o*"]]
  }
}
set rob_state_d_pins {}
foreach cell [get_cells -hierarchical *] {
  if {![string match "$rob_prefix/*" [get_full_name $cell]]} {
    continue
  }
  foreach pin [get_pins -quiet -of_objects $cell] {
    if {[get_property $pin direction] eq "input" && [pin_leaf $pin] eq "D"} {
      lappend rob_state_d_pins $pin
    }
  }
}
set rob_wb_pins [lsort -unique $rob_wb_pins]
set rob_wb_data_pins [lsort -unique $rob_wb_data_pins]
set rob_commit_pins [lsort -unique $rob_commit_pins]
set rob_state_d_pins [lsort -unique $rob_state_d_pins]
require_min_count rob_wb_pins $rob_wb_pins 250
require_count rob_wb_data_pins $rob_wb_data_pins 128
require_count rob_commit_pins $rob_commit_pins 638
require_min_count rob_state_d_pins $rob_state_d_pins 1000

set dcache_rdata_pins [get_pins -quiet "$dcache_prefix/u_sram/rdata_o*"]
require_count dcache_rdata_pins $dcache_rdata_pins 113

# FIFO: the old head pointer must still reach the shadow D (non-vacuity), but
# it must not reach any production head output in the same timing cycle.  The
# registered shadow Q must have a real downstream consumer path.
set report_fifo_shadow [file join $out_dir fifo-headq-to-shadow-d-required.rpt]
report_checks -path_delay max -from $fifo_head_q_pins -to $fifo_shadow_d_pins \
  -group_path_count 2 -digits 3 > $report_fifo_shadow
require_required_report fifo_headq_to_shadow_d $report_fifo_shadow

set report_fifo_forbidden [file join $out_dir fifo-headq-to-production-forbidden.rpt]
report_checks -path_delay max -from $fifo_head_q_pins \
  -through $fifo_production_pins -group_path_count 2 -digits 3 \
  > $report_fifo_forbidden
require_forbidden_report fifo_headq_to_production $report_fifo_forbidden

set report_fifo_owner [file join $out_dir fifo-shadowq-to-production-required.rpt]
report_checks -path_delay max -from $fifo_shadow_q_pins \
  -through $fifo_production_pins -group_path_count 2 -digits 3 \
  > $report_fifo_owner
require_required_report fifo_shadowq_to_production $report_fifo_owner

# IFU: both fast PMP windows must be reachable from the registered lookup
# owner, while pc_q must have no same-cycle path through either paddr input.
set report_ifu_pmp0 [file join $out_dir ifu-lookupq-to-fast-pmp0-required.rpt]
report_checks -path_delay max -from $ifu_lookup_q_pins \
  -through $ifu_pmp0_paddr_pins -group_path_count 2 -digits 3 \
  > $report_ifu_pmp0
require_required_report ifu_lookupq_to_pmp0 $report_ifu_pmp0

set report_ifu_pmp1 [file join $out_dir ifu-lookupq-to-fast-pmp1-required.rpt]
report_checks -path_delay max -from $ifu_lookup_q_pins \
  -through $ifu_pmp1_paddr_pins -group_path_count 2 -digits 3 \
  > $report_ifu_pmp1
require_required_report ifu_lookupq_to_pmp1 $report_ifu_pmp1

set report_ifu_pc0 [file join $out_dir ifu-pcq-to-fast-pmp0-forbidden.rpt]
report_checks -path_delay max -from $ifu_pc_q_pins \
  -through $ifu_pmp0_paddr_pins -group_path_count 2 -digits 3 \
  > $report_ifu_pc0
require_forbidden_report ifu_pcq_to_pmp0 $report_ifu_pc0

set report_ifu_pc1 [file join $out_dir ifu-pcq-to-fast-pmp1-forbidden.rpt]
report_checks -path_delay max -from $ifu_pc_q_pins \
  -through $ifu_pmp1_paddr_pins -group_path_count 2 -digits 3 \
  > $report_ifu_pc1
require_forbidden_report ifu_pcq_to_pmp1 $report_ifu_pc1

# ROB: WB and D-cache response traffic may terminate at ROB state D, but must
# not traverse commit valid/payload in the same cycle.  Hierarchical pins are
# used only as -through filters, matching the proven T3V OpenSTA discipline.
set report_rob_wb_forbidden [file join $out_dir rob-wb-to-commit-forbidden.rpt]
report_checks -path_delay max -through $rob_wb_pins \
  -through $rob_commit_pins -group_path_count 2 -digits 3 \
  > $report_rob_wb_forbidden
require_forbidden_report rob_wb_to_commit $report_rob_wb_forbidden

set report_dcache_commit [file join $out_dir dcache-to-commit-forbidden.rpt]
report_checks -path_delay max -through $dcache_rdata_pins \
  -through $rob_commit_pins -group_path_count 2 -digits 3 \
  > $report_dcache_commit
require_forbidden_report dcache_to_commit $report_dcache_commit

set report_dcache_rob [file join $out_dir dcache-to-rob-state-required.rpt]
report_checks -path_delay max -through $dcache_rdata_pins \
  -through $rob_wb_data_pins -to $rob_state_d_pins \
  -group_path_count 4 -digits 3 > $report_dcache_rob
require_required_report dcache_to_rob_state_d $report_dcache_rob

set count_path [file join $out_dir opensta-object-counts.txt]
set count_stream [open $count_path w]
puts $count_stream "clock_period_ns=5.000"
puts $count_stream "timing_exceptions_added=0"
puts $count_stream "fifo_head_q_pins=[llength $fifo_head_q_pins]"
puts $count_stream "fifo_shadow_q_pins=[llength $fifo_shadow_q_pins]"
puts $count_stream "fifo_shadow_d_pins=[llength $fifo_shadow_d_pins]"
puts $count_stream "fifo_production_pins=[llength $fifo_production_pins]"
puts $count_stream "ifu_pc_q_pins=[llength $ifu_pc_q_pins]"
puts $count_stream "ifu_lookup_q_pins=[llength $ifu_lookup_q_pins]"
puts $count_stream "ifu_pmp0_paddr_pins=[llength $ifu_pmp0_paddr_pins]"
puts $count_stream "ifu_pmp1_paddr_pins=[llength $ifu_pmp1_paddr_pins]"
puts $count_stream "rob_wb_pins=[llength $rob_wb_pins]"
puts $count_stream "rob_wb_data_pins=[llength $rob_wb_data_pins]"
puts $count_stream "rob_commit_pins=[llength $rob_commit_pins]"
puts $count_stream "rob_state_d_pins=[llength $rob_state_d_pins]"
puts $count_stream "dcache_rdata_pins=[llength $dcache_rdata_pins]"
close $count_stream

set metrics_path [file join $out_dir audit-global-metrics.rpt]
report_tns > $metrics_path
report_wns >> $metrics_path
puts {[T3W-FRESH-NETLIST-OPENSTA] PASS}
exit
