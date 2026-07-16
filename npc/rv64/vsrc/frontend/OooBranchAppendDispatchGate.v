`include "include/define.v"

module OooBranchAppendDispatchGate #(
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W
) (
  input dispatch0_branch_i,
  input return_cont_match_i,
  input direct_branch0_lane1_ret_i,
  input ctrl_commit_valid_i,
  input commit_ready_i,
  input core_commit0_valid_i,
  input core_commit1_valid_i,
  input [ROB_COUNT_W-1:0] rob_count_i,
  input outstanding_valid_i,
  input [`XLEN-1:0] outstanding_pc_i,
  input [`XLEN-1:0] head_next_pc1_i,
  input branch_fallthrough_safe_i,
  input branch_target_cache_hit_i,
  input direct_branch0_fire_i,
  input direct_branch_resolve_redirect_i,
  input direct_branch_resolve_taken_i,
  input dispatch1_ready_i,
  input fetch_rsp_fire_i,
  input branch_prefetch_active_i,
  input branch_prefetch_buffer_valid_i,
  input stop_pending_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input fetch_rsp_valid_i,
  input [`XLEN-1:0] branch_prefetch_pc_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,
  input direct_frontend_flush_i,
  input branch_resolve_pending_match_i,
  input branch_spec_active_i,
  input core_branch_resolve_misaligned_i,
  input branch_prefetch_buffer_match_i,
  input branch_prefetch_dispatch0_safe_i,
  input branch_prefetch_dispatch1_safe_i,
  input branch_prefetch_rsp_dispatch0_safe_i,
  input branch_prefetch_rsp_dispatch1_safe_i,
  output return_cont_optional_o,
  output return_cont_attempt_ready_o,
  output return_cont_attempt_o,
  output branch_fallthrough_outstanding_match_o,
  output branch_target_append_candidate_o,
  output branch_fallthrough_append_safe_o,
  output branch_fallthrough_append_candidate_o,
  output branch_target_append_attempt_o,
  output branch_fallthrough_append_attempt_o,
  output synth_lane1_branch_append_o,
  output branch_target_append_o,
  output branch_fallthrough_append_o,
  output return_cont_dispatch_o,
  output branch_target_dispatch_o,
  output branch_fallthrough_dispatch_o,
  output branch_fallthrough_keep_outstanding_o,
  output branch_prefetch_rsp_raw_match_o,
  output branch_prefetch_dispatch_buffer_o,
  output branch_prefetch_dispatch_rsp_o,
  output branch_prefetch_dispatch_attempt_o,
  output branch_prefetch_dispatch_fire_o,
  output dispatch1_optional_o
);
  localparam BRANCH_APPEND_DISPATCH_ENABLE = 1'b0;
  localparam BRANCH_PREFETCH_DISPATCH_ENABLE = 1'b0;

  assign return_cont_optional_o =
      dispatch0_branch_i && return_cont_match_i;
  assign return_cont_attempt_ready_o =
      direct_branch0_lane1_ret_i &&
      !ctrl_commit_valid_i && commit_ready_i &&
      return_cont_match_i &&
      core_commit0_valid_i && !core_commit1_valid_i &&
      (rob_count_i == {{(ROB_COUNT_W-1){1'b0}}, 1'b1});

  // Same-cycle lane1 append fast paths are intentionally disabled until their
  // ready/resolve feedback cones are retimed.
  assign return_cont_attempt_o = 1'b0;

  assign branch_fallthrough_outstanding_match_o =
      outstanding_valid_i && (outstanding_pc_i == head_next_pc1_i);
  assign branch_target_append_candidate_o =
      dispatch0_branch_i && branch_target_cache_hit_i;
  assign branch_fallthrough_append_safe_o =
      branch_fallthrough_safe_i &&
      (!outstanding_valid_i ||
       branch_fallthrough_outstanding_match_o);
  assign branch_fallthrough_append_candidate_o =
      dispatch0_branch_i && branch_fallthrough_append_safe_o;

  assign branch_target_append_attempt_o =
      BRANCH_APPEND_DISPATCH_ENABLE &&
      branch_target_append_candidate_o &&
      direct_branch0_fire_i && direct_branch_resolve_redirect_i &&
      direct_branch_resolve_taken_i;
  assign branch_fallthrough_append_attempt_o =
      BRANCH_APPEND_DISPATCH_ENABLE &&
      branch_fallthrough_append_candidate_o &&
      direct_branch0_fire_i && direct_branch_resolve_redirect_i &&
      !direct_branch_resolve_taken_i;

  assign synth_lane1_branch_append_o =
      return_cont_attempt_o && dispatch1_ready_i;
  assign branch_target_append_o =
      branch_target_append_attempt_o && dispatch1_ready_i;
  assign branch_fallthrough_append_o =
      branch_fallthrough_append_attempt_o && dispatch1_ready_i;
  assign return_cont_dispatch_o = synth_lane1_branch_append_o;
  assign branch_target_dispatch_o = branch_target_append_o;
  assign branch_fallthrough_dispatch_o = branch_fallthrough_append_o;

  assign branch_fallthrough_keep_outstanding_o =
      branch_fallthrough_dispatch_o &&
      branch_fallthrough_outstanding_match_o && !fetch_rsp_fire_i;
  assign branch_prefetch_rsp_raw_match_o =
      branch_prefetch_active_i && !branch_prefetch_buffer_valid_i &&
      stop_pending_i && pending_branch_i && pending_branch_dispatched_i &&
      fetch_rsp_valid_i &&
      (branch_prefetch_pc_i == core_branch_resolve_next_pc_i);
  assign branch_prefetch_dispatch_buffer_o =
      BRANCH_PREFETCH_DISPATCH_ENABLE &&
      !direct_frontend_flush_i && stop_pending_i && pending_branch_i &&
      pending_branch_dispatched_i && branch_resolve_pending_match_i &&
      !branch_spec_active_i && !core_branch_resolve_misaligned_i &&
      branch_prefetch_buffer_match_i &&
      branch_prefetch_dispatch0_safe_i &&
      branch_prefetch_dispatch1_safe_i;
  assign branch_prefetch_dispatch_rsp_o =
      BRANCH_PREFETCH_DISPATCH_ENABLE &&
      !direct_frontend_flush_i && stop_pending_i && pending_branch_i &&
      pending_branch_dispatched_i && branch_resolve_pending_match_i &&
      !branch_spec_active_i && !core_branch_resolve_misaligned_i &&
      branch_prefetch_rsp_raw_match_o &&
      branch_prefetch_rsp_dispatch0_safe_i &&
      branch_prefetch_rsp_dispatch1_safe_i;
  assign branch_prefetch_dispatch_attempt_o =
      branch_prefetch_dispatch_buffer_o || branch_prefetch_dispatch_rsp_o;
  assign branch_prefetch_dispatch_fire_o = 1'b0;
  // 【F2】optional 恒 0: direct 模型 lane1 选发槽遗产(append 快速路已恒禁)。F2 的
  // dual 双发(not-taken 分支+head1)必须 pair 原子——optional 让 DispatchBackend 豁免
  // pair-ready 后 d0 可独发, dbranch pop 会把未发射的 head1 从 FIFO 蒸发。
  assign dispatch1_optional_o = 1'b0;
endmodule
