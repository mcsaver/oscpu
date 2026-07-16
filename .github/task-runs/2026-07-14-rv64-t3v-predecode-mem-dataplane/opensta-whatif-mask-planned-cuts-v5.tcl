# v5 adds exactly one exploratory architecture hypothesis to v4: register the
# FetchPacketFifo head presentation.  On this frozen netlist head_q[1:0] was
# cloned into four flops; two clones (_9253_/_9254_) directly drive the head
# read mux bank, and two (_9257_/_9258_) retain the named head_q state.
rename exit t3v_real_exit
proc exit args {}
source [file join [file dirname [info script]] \
  opensta-whatif-mask-planned-cuts-v4.tcl]
rename exit t3v_noop_exit
rename t3v_real_exit exit

set fifo_prefix \
  u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo
set fifo_head_pointer_q_pins [get_pins -quiet [list \
  $fifo_prefix/_9253_/Q \
  $fifo_prefix/_9254_/Q \
  $fifo_prefix/_9257_/Q \
  $fifo_prefix/_9258_/Q]]
if {[llength $fifo_head_pointer_q_pins] != 4} {
  error "T3V v5 FIFO head-pointer ABI mismatch: pins=[llength $fifo_head_pointer_q_pins]"
}
set_false_path -through $fifo_head_pointer_q_pins

set v5_count_path [file join $out_dir v5-mask-object-count.txt]
set v5_count_fp [open $v5_count_path w]
puts $v5_count_fp "exploratory_only=1"
puts $v5_count_fp "incremental_over_v4=fetch_packet_fifo_head_pointer_q"
puts $v5_count_fp "fifo_head_pointer_q_pins=[llength $fifo_head_pointer_q_pins]"
foreach pin $fifo_head_pointer_q_pins {
  puts $v5_count_fp "fifo_head_pointer_q_pin=[get_full_name $pin]"
}
close $v5_count_fp

set v5_report [file join $out_dir top40-mask-planned-cuts-v5.rpt]
report_checks -path_delay max -group_path_count 40 -digits 3 > $v5_report
report_tns >> $v5_report
report_wns >> $v5_report

# A directed one-path query proves that the broad commit-tail exceptions do not
# cover EX0 endpoints.  It is a report filter only and adds no false path.
set iq_q_pins {}
set prf_output_pins {}
set alu0_output_pins {}
set ex0_d_pins {}
foreach cell [get_cells -hierarchical *] {
  set cell_name [get_full_name $cell]
  set in_iq [string match "*u_dispatch_backend/u_issue_queue/*" $cell_name]
  set in_prf [string match "*u_int_backend/u_phys_reg_file/*" $cell_name]
  set in_alu0 [string match "*u_int_backend/u_alu0/*" $cell_name]
  set in_ex0 [string match "*u_int_backend/u_ex0_stage/*" $cell_name]
  foreach pin [get_pins -quiet -of_objects $cell] {
    set pin_name [get_full_name $pin]
    set pin_leaf [lindex [split $pin_name "/"] end]
    set pin_direction [get_property $pin direction]
    if {$in_iq && $pin_direction eq "output" &&
        ($pin_leaf eq "Q" || $pin_leaf eq "QN")} {
      lappend iq_q_pins $pin
    }
    if {$in_prf && $pin_direction eq "output"} {
      lappend prf_output_pins $pin
    }
    if {$in_alu0 && $pin_direction eq "output"} {
      lappend alu0_output_pins $pin
    }
    if {$in_ex0 && $pin_direction eq "input" && $pin_leaf eq "D"} {
      lappend ex0_d_pins $pin
    }
  }
}
if {[llength $iq_q_pins] == 0 ||
    [llength $prf_output_pins] == 0 ||
    [llength $alu0_output_pins] == 0 ||
    [llength $ex0_d_pins] == 0} {
  error "T3V v5 IQ/EX0 report-filter ABI mismatch"
}
set iq_report [file join $out_dir v5-iq-prf-alu0-ex0.rpt]
report_checks -path_delay max \
  -from $iq_q_pins \
  -through $prf_output_pins \
  -through $alu0_output_pins \
  -to $ex0_d_pins \
  -group_path_count 1 -digits 3 > $iq_report
exit
