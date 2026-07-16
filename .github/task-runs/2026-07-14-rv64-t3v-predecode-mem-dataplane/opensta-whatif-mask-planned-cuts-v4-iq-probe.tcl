# Reuse the frozen v4 exploratory masks in a fresh evidence directory, then add
# a directed structural query for the IQ -> PRF -> ALU0 -> EX0 path.  This probe
# does not add another false path and therefore cannot improve the v4 metrics.
rename exit t3v_real_exit
proc exit args {}
source [file join [file dirname [info script]] \
  opensta-whatif-mask-planned-cuts-v4.tcl]
rename exit t3v_noop_exit
rename t3v_real_exit exit

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
  error "T3V v4 IQ probe hierarchy ABI mismatch"
}

set probe_count_path [file join $out_dir iq-probe-object-count.txt]
set probe_count_fp [open $probe_count_path w]
puts $probe_count_fp "iq_q_pins=[llength $iq_q_pins]"
puts $probe_count_fp "prf_output_pins=[llength $prf_output_pins]"
puts $probe_count_fp "alu0_output_pins=[llength $alu0_output_pins]"
puts $probe_count_fp "ex0_d_pins=[llength $ex0_d_pins]"
close $probe_count_fp

set probe_report [file join $out_dir iq-prf-alu0-ex0.rpt]
report_checks -path_delay max \
  -from $iq_q_pins \
  -through $prf_output_pins \
  -through $alu0_output_pins \
  -to $ex0_d_pins \
  -group_path_count 10 -digits 3 > $probe_report
exit
