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
  // 【F2】issue-resolve update 单源：后端每条分支 resolve 都回训 BPU(bht_idx/pred_taken 随
  // dispatch 载荷 thread 进 IQ 后随 resolve 总线导出)。wrong-path 分支被 walk kill 后不 issue
  // 故天然不污染。
  // [wave5b 死硅拆除] 旧四臂 direct/pending/drained/commit + pending_like 已删——direct_update
  // 依赖 direct_branch_resolve_valid(OOO_DBRANCH_DOMAIN_A=1 恒0)、pending/drained/commit 依赖
  // pending_branch(capture 恒0)，四臂在 mode=1+domain-A 下全死。原 update_valid/taken/pred_taken/
  // pc/bht_idx 的 4-way mux 在四臂谓词全 0 时逐拍落到 resolve_update 分支，故化简为单源逐位等价。
  input resolve_update_valid_i,
  input resolve_update_taken_i,
  input resolve_update_pred_taken_i,
  input [`XLEN-1:0] resolve_update_pc_i,
  input [`BPU_BHT_INDEX_W-1:0] resolve_update_bht_idx_i,
  output branch_bpu_pending0_capture_o,
  output branch_bpu_pending1_capture_o,
  output branch_bpu_lookup_event_o,
  output branch_bpu_lookup_bht_valid_o,
  output branch_bpu_update_valid_o,
  output branch_bpu_update_taken_o,
  output branch_bpu_update_pred_taken_o,
  output branch_bpu_update_correct_o,
  output [`XLEN-1:0] branch_bpu_update_pc_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx_o
);
  // BHT lookup 触发（活 F2 预测路径，与旧 pending 存储无关，保留原样）
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

  // BHT update 单源 = issue-resolve
  assign branch_bpu_update_valid_o = resolve_update_valid_i;
  assign branch_bpu_update_taken_o = resolve_update_taken_i;
  assign branch_bpu_update_pred_taken_o = resolve_update_pred_taken_i;
  assign branch_bpu_update_correct_o =
      branch_bpu_update_pred_taken_o == branch_bpu_update_taken_o;
  assign branch_bpu_update_pc_o = resolve_update_pc_i;
  assign branch_bpu_update_bht_idx_o = resolve_update_bht_idx_i;
endmodule
