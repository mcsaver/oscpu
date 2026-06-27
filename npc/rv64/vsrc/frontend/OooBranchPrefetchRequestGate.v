// Pure combinational request gate for branch/JALR prefetch.
`include "define.v"

module OooBranchPrefetchRequestGate (
  input stop_pending_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input branch_resolve_pending_match_i,
  input jalr_btb_hit_i,
  input pending_jump_dispatched_i,
  input branch_prefetch_active_i,
  input outstanding_valid_i,
  input discard_fetch_rsp_i,
  input branch_spec_checkpoint_pending_i,
  input branch_spec_active_i,
  input halted_i,
  input trap_valid_i,
  input exit_valid_i,
  input [`XLEN-1:0] branch_pred_pc_i,
  input [`XLEN-1:0] jalr_btb_target_i,

  output branch_req_valid_o,
  output jalr_req_valid_o,
  output req_valid_o,
  output [`XLEN-1:0] req_pc_o
);

  wire shared_clear_w =
      !branch_prefetch_active_i &&
      !outstanding_valid_i &&
      !discard_fetch_rsp_i &&
      !branch_spec_checkpoint_pending_i &&
      !branch_spec_active_i &&
      !halted_i &&
      !trap_valid_i &&
      !exit_valid_i;

  assign branch_req_valid_o =
      stop_pending_i &&
      pending_branch_i &&
      pending_branch_dispatched_i &&
      shared_clear_w &&
      !branch_resolve_pending_match_i;

  assign jalr_req_valid_o =
      jalr_btb_hit_i &&
      !pending_jump_dispatched_i &&
      shared_clear_w;

  assign req_valid_o = branch_req_valid_o || jalr_req_valid_o;
  assign req_pc_o = jalr_req_valid_o ? jalr_btb_target_i : branch_pred_pc_i;

endmodule
