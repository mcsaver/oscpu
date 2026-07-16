proc require_env {name} {
  if {![info exists ::env($name)] || $::env($name) eq ""} {
    error "required environment variable is missing: $name"
  }
  return $::env($name)
}

proc matches_any {name patterns} {
  foreach pattern $patterns {
    if {[string match $pattern $name]} {
      return 1
    }
  }
  return 0
}

set netlist [file normalize [require_env T3V_WHATIF_NETLIST]]
set out_dir [file normalize [require_env T3V_WHATIF_OUT_DIR]]
set std_lib [file normalize [require_env T3V_WHATIF_STD_LIB]]
set macro_raw [require_env T3V_WHATIF_MACRO_LIBS]

file mkdir $out_dir
read_liberty $std_lib
foreach macro_lib [split $macro_raw ":"] {
  read_liberty [file normalize $macro_lib]
}
read_verilog $netlist
link_design NpcTop
create_clock -name core_clock -period 5.0 [get_ports clk]

# Exploratory-only timing-family reveal.  Every exception below represents an
# architectural cut being evaluated for T3W; none is a sign-off constraint.
set dcache_prefix \
  u_core/u_ooo_mem_bridge/u_dcache
set dcache_sram_cell [get_cells -quiet \
  $dcache_prefix/u_sram]
set dcache_rdata_pins [get_pins -quiet \
  $dcache_prefix/u_sram/rdata_o*]
set dcache_addr_pins [get_pins -quiet \
  $dcache_prefix/u_sram/addr_i*]
set dcache_en_pins [get_pins -quiet \
  $dcache_prefix/u_sram/en_i]
if {[llength $dcache_sram_cell] != 1 ||
    [llength $dcache_rdata_pins] != 113 ||
    [llength $dcache_addr_pins] != 12 ||
    [llength $dcache_en_pins] != 1} {
  error "T3V what-if D-cache SRAM ABI mismatch"
}

# OpenSTA exposes the SRAM response as a macro startpoint, so -through is the
# effective form (the earlier -from experiment was intentionally retained as
# separate T3V evidence).  Likewise, every internal sequential startpoint must
# traverse its Q/QN pin.
set dcache_q_pins {}
set fpdecode_output_pins {}
set commit_tail_output_pins {}
set commit_tail_endpoint_cells {}
set commit_tail_d_pins {}
set csr_endpoint_cells {}
set csr_d_pins {}

set fpdecode_patterns [list \
  "*u_fetch_head_pair_gate/u_head0_classify_gate/u_fp_decode/*" \
  "*u_fetch_head_pair_gate/u_head1_classify_gate/u_fp_decode/*"]

# This bounded list is the commit/CSR/trap tail explicitly removed by the v4
# experiment.  It includes the ROB-facing commit mux and the named control-tail
# blocks, while leaving IQ/PRF/ALU/EX and unrelated backend paths timed.
set commit_tail_patterns [list \
  "*u_writeback/u_commit_output_mux/*" \
  "*u_control_plane/u_csr_access_request_mux/*" \
  "*u_control_plane/u_csr_trap_request_mux/*" \
  "*u_control_plane/u_pending_dispatch_arbiter/*" \
  "*u_control_plane/u_control_flush_sequencer/*" \
  "*u_control_plane/u_pending_system_sequencer/*" \
  "*u_control_plane/u_pending_trap_exit_sequencer/*" \
  "*u_control_plane/u_trap_exit_event_mux/*" \
  "*u_control_plane/u_trap_exit_output_sequencer/*"]

foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set in_dcache [string match "$dcache_prefix/*" $cell_name]
  set in_fpdecode [matches_any $cell_name $fpdecode_patterns]
  set in_commit_tail [matches_any $cell_name $commit_tail_patterns]
  set in_csr_file [string match "u_core/u_csr_file/*" $cell_name]

  foreach pin [get_pins -quiet -of_objects $cell] {
    set pin_name [get_full_name $pin]
    set pin_leaf [lindex [split $pin_name "/"] end]
    set pin_direction [get_property $pin direction]

    if {$in_dcache && $pin_direction eq "output" &&
        ($pin_leaf eq "Q" || $pin_leaf eq "QN")} {
      lappend dcache_q_pins $pin
    }
    if {$in_fpdecode && $pin_direction eq "output"} {
      lappend fpdecode_output_pins $pin
    }
    if {$in_commit_tail && $pin_direction eq "output"} {
      lappend commit_tail_output_pins $pin
    }
    if {$pin_leaf eq "D" && $pin_direction eq "input"} {
      if {$in_commit_tail} {
        lappend commit_tail_d_pins $pin
        lappend commit_tail_endpoint_cells $cell
      }
      if {$in_csr_file} {
        lappend csr_d_pins $pin
        lappend csr_endpoint_cells $cell
      }
    }
  }
}

if {[llength $dcache_q_pins] == 0 ||
    [llength $fpdecode_output_pins] == 0 ||
    [llength $commit_tail_output_pins] == 0 ||
    [llength $commit_tail_d_pins] == 0 ||
    [llength $csr_d_pins] == 0} {
  error "T3V what-if hierarchy ABI mismatch"
}

set_false_path -through $dcache_rdata_pins
set_false_path -through $dcache_q_pins
set_false_path -through $fpdecode_output_pins
set_false_path -through $commit_tail_output_pins

# The SRAM Liberty model reports one macro-cell endpoint instead of distinct
# addr_i/en_i endpoint objects.  The cell exception is therefore the required
# exploratory proxy for speculative lookup; addr/en pin exceptions are also
# kept to document the intended architectural boundary.
set_false_path -to $dcache_addr_pins
set_false_path -to $dcache_en_pins
set_false_path -to $dcache_sram_cell

# Endpoint forms make the intended tail cut explicit even when a path terminates
# at a state element before traversing another primitive output.
set_false_path -to $commit_tail_d_pins
set_false_path -to $commit_tail_endpoint_cells
set_false_path -to $csr_d_pins
set_false_path -to $csr_endpoint_cells

set report_path [file join $out_dir top40-mask-planned-cuts-v4.rpt]
set count_path [file join $out_dir masked-object-count.txt]
set count_fp [open $count_path w]
puts $count_fp "exploratory_only=1"
puts $count_fp "clock_period_ns=5.0"
puts $count_fp "dcache_rdata_pins=[llength $dcache_rdata_pins]"
puts $count_fp "dcache_q_pins=[llength $dcache_q_pins]"
puts $count_fp "dcache_addr_pins=[llength $dcache_addr_pins]"
puts $count_fp "dcache_en_pins=[llength $dcache_en_pins]"
puts $count_fp "dcache_sram_endpoint_proxy_cells=[llength $dcache_sram_cell]"
puts $count_fp "fpdecode_output_pins=[llength $fpdecode_output_pins]"
puts $count_fp "commit_tail_output_pins=[llength $commit_tail_output_pins]"
puts $count_fp "commit_tail_d_pins=[llength $commit_tail_d_pins]"
puts $count_fp "commit_tail_endpoint_cells=[llength $commit_tail_endpoint_cells]"
puts $count_fp "csr_d_pins=[llength $csr_d_pins]"
puts $count_fp "csr_endpoint_cells=[llength $csr_endpoint_cells]"
close $count_fp

report_checks -path_delay max -group_path_count 40 -digits 3 > $report_path
report_tns >> $report_path
report_wns >> $report_path
exit
