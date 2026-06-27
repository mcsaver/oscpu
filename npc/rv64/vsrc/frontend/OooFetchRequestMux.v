// Pure combinational fetch request PC/source mux for the OoO front-end.
`include "define.v"

module OooFetchRequestMux (
  input outstanding_valid_i,
  input fetch_rsp_fire_i,
  input [`XLEN-1:0] fetch_rsp_packet_next_pc_i,
  input [`XLEN-1:0] next_fetch_pc_i,
  input direct_jal_fire_i,
  input direct_ret0_fire_i,
  input direct_ret1_fire_i,
  input direct_branch0_lane1_ret_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input direct_branch_resolve_redirect_i,
  input branch_resolve_redirect_i,
  input branch_spec_redirect_i,
  input branch_resolve_untracked_redirect_i,
  input branch_fallthrough_dispatch_i,
  input branch_fallthrough_outstanding_match_i,
  input return_cont_dispatch_i,
  input [`XLEN-1:0] return_cont_next_pc_i,
  input [`XLEN-1:0] ras_top_i,
  input branch_target_dispatch_i,
  input [`XLEN-1:0] branch_target_cache_next_pc_i,
  input [`XLEN-1:0] head_next_pc1_i,
  input [`XLEN-1:0] direct_jal_target_i,
  input [`XLEN-1:0] direct_ret_target_i,
  input [`XLEN-1:0] direct_branch_resolve_next_pc_i,
  input [`XLEN-1:0] pending_jump_resolved_target_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,
  input branch_prefetch_req_valid_i,
  input [`XLEN-1:0] branch_prefetch_req_pc_i,

  output direct_redirect_fetch_o,
  output redirect_fetch_req_valid_o,
  output [`XLEN-1:0] redirect_fetch_pc_o,
  output [`XLEN-1:0] fetch_req_pc_o
);

  wire [`XLEN-1:0] fetch_req_seq_pc_w =
      (outstanding_valid_i && fetch_rsp_fire_i) ?
      fetch_rsp_packet_next_pc_i : next_fetch_pc_i;

  assign direct_redirect_fetch_o =
      direct_jal_fire_i ||
      direct_ret0_fire_i ||
      direct_ret1_fire_i ||
      direct_branch0_lane1_ret_i ||
      pending_jump_nolink_commit_i ||
      pending_jump_redirect_after_dispatch_i ||
      direct_branch_resolve_redirect_i;

  assign redirect_fetch_req_valid_o =
      (direct_redirect_fetch_o ||
       branch_resolve_redirect_i ||
       branch_spec_redirect_i ||
       branch_resolve_untracked_redirect_i) &&
      (!branch_fallthrough_dispatch_i ||
       !branch_fallthrough_outstanding_match_i) &&
      (!outstanding_valid_i || fetch_rsp_fire_i);

  assign redirect_fetch_pc_o =
      direct_jal_fire_i ? direct_jal_target_i :
      (direct_ret0_fire_i || direct_ret1_fire_i) ? direct_ret_target_i :
      direct_branch0_lane1_ret_i ?
          (return_cont_dispatch_i ? return_cont_next_pc_i : ras_top_i) :
      branch_target_dispatch_i ? branch_target_cache_next_pc_i :
      branch_fallthrough_dispatch_i ? head_next_pc1_i :
      direct_branch_resolve_redirect_i ? direct_branch_resolve_next_pc_i :
      (pending_jump_nolink_commit_i ||
       pending_jump_redirect_after_dispatch_i) ? pending_jump_resolved_target_i :
      branch_spec_redirect_i ? core_branch_resolve_next_pc_i :
                               core_branch_resolve_next_pc_i;

  assign fetch_req_pc_o =
      redirect_fetch_req_valid_o ? redirect_fetch_pc_o :
      branch_prefetch_req_valid_i ? branch_prefetch_req_pc_i :
                                    fetch_req_seq_pc_w;

endmodule
