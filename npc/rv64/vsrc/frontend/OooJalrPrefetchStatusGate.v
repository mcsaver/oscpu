// Pure combinational status gate for JALR branch-prefetch hit handling.
`include "define.v"

module OooJalrPrefetchStatusGate (
  input branch_prefetch_active_i,
  input branch_prefetch_buffer_valid_i,
  input branch_prefetch_rsp_capture_i,
  input stop_pending_i,
  input pending_jump_i,
  input pending_jump_jalr_i,
  input pending_jump_dispatched_i,
  input [`XLEN-1:0] pending_jump_target_i,
  input pending_jump_resolve_ready_i,
  input [`XLEN-1:0] pending_jump_resolved_target_i,
  input pending_jump_misaligned_i,
  input [`XLEN-1:0] branch_prefetch_pc_i,

  output match_o,
  output buffer_match_o,
  output rsp_match_o,
  output hit_available_o,
  output pending_match_o
);

  wire target_ready_w =
      pending_jump_dispatched_i || pending_jump_resolve_ready_i;
  wire [`XLEN-1:0] target_w =
      pending_jump_dispatched_i ? pending_jump_target_i :
                                  pending_jump_resolved_target_i;

  assign match_o =
      branch_prefetch_active_i &&
      stop_pending_i &&
      pending_jump_i &&
      pending_jump_jalr_i &&
      target_ready_w &&
      !pending_jump_misaligned_i &&
      (branch_prefetch_pc_i == target_w);

  assign buffer_match_o = match_o && branch_prefetch_buffer_valid_i;
  assign rsp_match_o = match_o && branch_prefetch_rsp_capture_i;
  assign hit_available_o = buffer_match_o || rsp_match_o;
  assign pending_match_o = match_o && !hit_available_o;

endmodule
