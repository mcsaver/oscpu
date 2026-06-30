// Pure combinational run/credit gate for the OoO front-end.
`include "define.v"
module OooFrontendRunGate #(
  parameter FETCH_COUNT_W = 3
) (
  input run_i,
  input core_trap_flush_i,
  input core_serial_flush_i,
  input stop_pending_i,
  input pending_exit_i,
  input pending_branch_i,
  input pending_jump_i,
  input pending_mem_i,
  input pending_fp_i,
  input pending_arch_trap_i,
  input pending_system_i,
  input synth_lane1_ret_pending_i,
  input synth_lane1_branch_drop_pending_i,
  input branch_spec_checkpoint_pending_i,
  input branch_spec_active_i,
  input halted_i,
  input trap_valid_i,
  input exit_valid_i,
  input fifo_storage_head_valid_i,
  input outstanding_valid_i,
  input fetch_rsp_valid_i,
  input discard_fetch_rsp_i,
  input [FETCH_COUNT_W-1:0] fifo_count_i,
  input [FETCH_COUNT_W-1:0] fifo_depth_i,

  output orphan_stop_pending_o,
  output stop_pending_busy_o,
  output can_run_o,
  output fifo_empty_storage_o,
  output fetch_rsp_dispatch_bypass_o,
  output [FETCH_COUNT_W-1:0] outstanding_count_o,
  output fifo_reserve_available_o
);

  wire stop_pending_owner_w =
      pending_exit_i ||
      pending_branch_i ||
      pending_jump_i ||
      pending_mem_i ||
      pending_fp_i ||
      pending_arch_trap_i ||
      pending_system_i ||
      synth_lane1_ret_pending_i ||
      synth_lane1_branch_drop_pending_i ||
      branch_spec_checkpoint_pending_i ||
      branch_spec_active_i;

  assign orphan_stop_pending_o = stop_pending_i && !stop_pending_owner_w;
  assign stop_pending_busy_o = stop_pending_i && !orphan_stop_pending_o;
  assign can_run_o = run_i &&
                     !core_trap_flush_i &&
                     !core_serial_flush_i &&
                     !stop_pending_busy_o &&
                     !halted_i &&
                     !trap_valid_i &&
                     !exit_valid_i;

  assign fifo_empty_storage_o = !fifo_storage_head_valid_i;
  // B2: mode 下禁「取指响应直通 dispatch」的 bypass，强制 wrong-path 经 FIFO——mispredict redirect 的 FIFO-clear
  // 才能拦住它，使它无法绕过 FIFO/kill 窗口而 dispatch+提交（修 bypass-after-kill 竞争）。
  assign fetch_rsp_dispatch_bypass_o =
      fifo_empty_storage_o &&
      can_run_o &&
      outstanding_valid_i &&
      fetch_rsp_valid_i &&
      !discard_fetch_rsp_i &&
      !(`OOO_ROB_WALK_MODE);

  assign outstanding_count_o =
      {{(FETCH_COUNT_W-1){1'b0}}, outstanding_valid_i};
  assign fifo_reserve_available_o =
      ((fifo_count_i + outstanding_count_o) < fifo_depth_i);

endmodule
