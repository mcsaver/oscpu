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
  // [wave5b 死硅拆除] fetch 响应 bypass 直通 dispatch 通路物理删除：原式尾含
  // !(OOO_ROB_WALK_MODE)，在 OOO_ROB_WALK_MODE=1'b1 下恒 0（防 bypass-after-kill
  // 竞争，强制 wrong-path 经 FIFO）。整式已是编译期常量 0，故直接常量 0 tie-off，逐位等价。
  // 保留 fetch_rsp_valid_i / discard_fetch_rsp_i 端口（仅本 bypass 消费，现转未读输入，
  // 综合/lint 容忍；不递归删接口以免动 OooFrontend 布线）。
  assign fetch_rsp_dispatch_bypass_o = 1'b0;

  assign outstanding_count_o =
      {{(FETCH_COUNT_W-1){1'b0}}, outstanding_valid_i};
  assign fifo_reserve_available_o =
      ((fifo_count_i + outstanding_count_o) < fifo_depth_i);

endmodule
