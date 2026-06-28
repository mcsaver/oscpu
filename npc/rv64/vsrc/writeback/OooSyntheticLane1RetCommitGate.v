`include "define.v"

// synthetic lane1 return 的 commit/drop 排序属于 writeback retire 边界。
module OooSyntheticLane1RetCommitGate (
  input ret_pending_i,
  input ret_branch_seen_i,
  input [`XLEN-1:0] ret_branch_pc_i,
  input branch_drop_pending_i,
  input [`XLEN-1:0] branch_drop_pc_i,
  input core_commit0_valid_i,
  input [`XLEN-1:0] core_commit0_pc_i,
  input core_commit1_valid_i,
  input [`XLEN-1:0] core_commit1_pc_i,
  input ctrl_commit_valid_i,
  input commit_ready_i,

  output ret_branch_commit0_o,
  output ret_branch_commit1_o,
  output branch_drop_match_o,
  output ret_drop_branch_o,
  output ret_before_core0_o,
  output ret_after_core0_o,
  output ret_commit_o
);

  assign ret_branch_commit0_o =
      ret_pending_i && !ret_branch_seen_i &&
      core_commit0_valid_i && (core_commit0_pc_i == ret_branch_pc_i);
  assign ret_branch_commit1_o =
      ret_pending_i && !ret_branch_seen_i &&
      core_commit1_valid_i && (core_commit1_pc_i == ret_branch_pc_i);

  assign branch_drop_match_o =
      branch_drop_pending_i &&
      core_commit0_valid_i && (core_commit0_pc_i == branch_drop_pc_i);
  assign ret_drop_branch_o =
      branch_drop_match_o && ret_pending_i && ret_branch_seen_i &&
      !ctrl_commit_valid_i && commit_ready_i;
  assign ret_before_core0_o =
      ret_pending_i && ret_branch_seen_i && !branch_drop_match_o &&
      !ctrl_commit_valid_i && commit_ready_i;
  assign ret_after_core0_o =
      !ctrl_commit_valid_i && ret_branch_commit0_o;
  assign ret_commit_o =
      ret_before_core0_o || ret_after_core0_o || ret_drop_branch_o;

endmodule
