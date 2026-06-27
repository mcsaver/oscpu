// Pure combinational status gate for branch prefetch response/hit handling.
`include "define.v"

module OooBranchPrefetchStatusGate (
  input branch_prefetch_active_i,
  input branch_prefetch_buffer_valid_i,
  input stop_pending_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input pending_jump_i,
  input pending_jump_jalr_i,
  input fetch_rsp_fire_i,
  input [`XLEN-1:0] branch_prefetch_pc_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,

  output rsp_capture_o,
  output match_o,
  output buffer_match_o,
  output rsp_match_o,
  output hit_available_o,
  output pending_match_o
);

  wire capture_owner_w =
      (pending_branch_i && pending_branch_dispatched_i) ||
      (pending_jump_i && pending_jump_jalr_i);

  assign rsp_capture_o =
      branch_prefetch_active_i &&
      !branch_prefetch_buffer_valid_i &&
      stop_pending_i &&
      capture_owner_w &&
      fetch_rsp_fire_i;

  assign match_o =
      branch_prefetch_active_i &&
      (branch_prefetch_pc_i == core_branch_resolve_next_pc_i);

  assign buffer_match_o = match_o && branch_prefetch_buffer_valid_i;
  assign rsp_match_o = match_o && rsp_capture_o;
  assign hit_available_o = buffer_match_o || rsp_match_o;
  assign pending_match_o = match_o && !hit_available_o;

endmodule
