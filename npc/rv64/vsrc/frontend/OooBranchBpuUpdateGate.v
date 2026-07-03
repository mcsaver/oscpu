`include "include/define.v"

module OooBranchBpuUpdateGate (
  input direct_frontend_flush_i,
  input can_run_i,
  input fifo_has_packet_i,
  input dispatch0_branch_i,
  input direct_branch0_dispatch_valid_i,
  input dispatch1_barrier_fire_i,
  input head1_branch_raw_i,
  input direct_branch_fire_i,
  input direct_branch_bht_valid_i,
  input head0_branch_bht_valid_i,
  input head1_branch_bht_valid_i,
  input direct_branch_resolve_valid_i,
  input stop_pending_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input branch_resolve_pending_match_i,
  input drain_complete_i,
  input pending_branch_commit_resolve_i,
  input core_branch_resolve_misaligned_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,
  input [`XLEN-1:0] pending_branch_target_i,
  input pending_branch_taken_i,
  input direct_branch_resolve_taken_i,
  input pending_branch_pred_taken_i,
  input direct_branch_predict_taken_i,
  input [`XLEN-1:0] pending_branch_pc_i,
  input [`XLEN-1:0] direct_branch_pc_i,
  input [`BPU_BHT_INDEX_W-1:0] pending_branch_bht_idx_i,
  input [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx_i,
  // 【F2】issue-resolve update: 后端每条分支 resolve 都回训 BPU(bht_idx/pred_taken 随
  // dispatch 载荷 thread 进 IQ 后随 resolve 总线导出)。wrong-path 分支被 walk kill 后
  // 不 issue 故天然不污染; 此前四臂在 mode=1+domain-A 下全死, BHT 从不学习。
  input resolve_update_valid_i,
  input resolve_update_taken_i,
  input resolve_update_pred_taken_i,
  input [`XLEN-1:0] resolve_update_pc_i,
  input [`BPU_BHT_INDEX_W-1:0] resolve_update_bht_idx_i,
  output branch_bpu_pending0_capture_o,
  output branch_bpu_pending1_capture_o,
  output branch_bpu_lookup_event_o,
  output branch_bpu_lookup_bht_valid_o,
  output branch_bpu_direct_update_o,
  output branch_bpu_pending_update_o,
  output branch_bpu_drained_update_o,
  output branch_bpu_commit_update_o,
  output branch_bpu_update_valid_o,
  output branch_bpu_pending_like_update_o,
  output branch_bpu_update_taken_o,
  output branch_bpu_update_pred_taken_o,
  output branch_bpu_update_correct_o,
  output [`XLEN-1:0] branch_bpu_update_pc_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx_o
);
  assign branch_bpu_pending0_capture_o =
      !direct_frontend_flush_i && can_run_i && fifo_has_packet_i &&
      dispatch0_branch_i && !direct_branch0_dispatch_valid_i;
  assign branch_bpu_pending1_capture_o =
      !direct_frontend_flush_i && can_run_i && fifo_has_packet_i &&
      dispatch1_barrier_fire_i && head1_branch_raw_i;

  assign branch_bpu_lookup_event_o =
      direct_branch_fire_i || branch_bpu_pending0_capture_o ||
      branch_bpu_pending1_capture_o;
  assign branch_bpu_lookup_bht_valid_o =
      (direct_branch_fire_i ? direct_branch_bht_valid_i : 1'b0) |
      (branch_bpu_pending0_capture_o ? head0_branch_bht_valid_i : 1'b0) |
      (branch_bpu_pending1_capture_o ? head1_branch_bht_valid_i : 1'b0);

  assign branch_bpu_direct_update_o = direct_branch_resolve_valid_i;
  assign branch_bpu_pending_update_o =
      stop_pending_i && pending_branch_i && pending_branch_dispatched_i &&
      branch_resolve_pending_match_i;
  assign branch_bpu_drained_update_o =
      stop_pending_i && drain_complete_i &&
      pending_branch_i && !pending_branch_dispatched_i;
  assign branch_bpu_commit_update_o = pending_branch_commit_resolve_i;

  assign branch_bpu_update_valid_o =
      branch_bpu_direct_update_o || branch_bpu_pending_update_o ||
      branch_bpu_drained_update_o || branch_bpu_commit_update_o ||
      resolve_update_valid_i;
  assign branch_bpu_pending_like_update_o =
      branch_bpu_pending_update_o || branch_bpu_drained_update_o ||
      branch_bpu_commit_update_o;

  assign branch_bpu_update_taken_o =
      branch_bpu_pending_update_o ?
          (!core_branch_resolve_misaligned_i &&
           (core_branch_resolve_next_pc_i == pending_branch_target_i)) :
      (branch_bpu_drained_update_o || branch_bpu_commit_update_o) ?
          pending_branch_taken_i :
      branch_bpu_direct_update_o ? direct_branch_resolve_taken_i :
                                   resolve_update_taken_i;
  assign branch_bpu_update_pred_taken_o =
      branch_bpu_pending_like_update_o ? pending_branch_pred_taken_i :
      branch_bpu_direct_update_o ? direct_branch_predict_taken_i :
                                   resolve_update_pred_taken_i;
  assign branch_bpu_update_correct_o =
      branch_bpu_update_pred_taken_o == branch_bpu_update_taken_o;
  assign branch_bpu_update_pc_o =
      branch_bpu_pending_like_update_o ? pending_branch_pc_i :
      branch_bpu_direct_update_o ? direct_branch_pc_i :
                                   resolve_update_pc_i;
  assign branch_bpu_update_bht_idx_o =
      branch_bpu_pending_like_update_o ? pending_branch_bht_idx_i :
      branch_bpu_direct_update_o ? direct_branch_bht_idx_i :
                                   resolve_update_bht_idx_i;
endmodule
