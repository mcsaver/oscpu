`include "define.v"

module OooFrontendBackendDispatchMux (
  input branch_prefetch_dispatch_attempt_i,
  input branch_prefetch_dispatch_buffer_i,
  input branch_prefetch_dispatch_rsp_i,
  input system_csr_dispatch_valid_i,
  input frontend_dispatch_to_backend_valid_i,
  input direct_branch0_dispatch_valid_i,
  input direct_jal0_dispatch_valid_i,
  input direct_ret0_dispatch_valid_i,
  input lane1_barrier_dispatch0_valid_i,
  input jump_dispatch_valid_i,
  input mem_dispatch_valid_i,
  input return_cont_attempt_i,
  input branch_target_append_attempt_i,
  input branch_fallthrough_append_attempt_i,
  input direct_jal1_fire_i,
  input direct_ret1_fire_i,
  input dispatch0_ready_i,

  input [`XLEN-1:0] branch_prefetch_buf_pc0_i,
  input [`XLEN-1:0] branch_prefetch_buf_next_pc0_i,
  input [`INST_W-1:0] branch_prefetch_buf_inst0_i,
  input [`XLEN-1:0] branch_prefetch_buf_pc1_i,
  input [`XLEN-1:0] branch_prefetch_buf_next_pc1_i,
  input [`INST_W-1:0] branch_prefetch_buf_inst1_i,

  input [`XLEN-1:0] fetch_dec0_pc_i,
  input [`XLEN-1:0] fetch_dec0_next_pc_i,
  input [`INST_W-1:0] fetch_dec0_inst_i,
  input [`XLEN-1:0] fetch_dec1_pc_i,
  input [`XLEN-1:0] fetch_dec1_next_pc_i,
  input [`INST_W-1:0] fetch_dec1_inst_i,

  input [`XLEN-1:0] pending_system_pc_i,
  input [`XLEN-1:0] pending_system_next_pc_i,
  input [`INST_W-1:0] pending_system_inst_i,
  input [`XLEN-1:0] pending_system_csr_rdata_i,

  input [`XLEN-1:0] pending_jump_pc_i,
  input [`XLEN-1:0] pending_jump_next_pc_i,
  input [`INST_W-1:0] pending_jump_inst_i,

  input [`XLEN-1:0] pending_mem_pc_i,
  input [`XLEN-1:0] pending_mem_next_pc_i,
  input [`INST_W-1:0] pending_mem_inst_i,

  input [`XLEN-1:0] head_pc0_i,
  input [`XLEN-1:0] head_next_pc0_i,
  input [`INST_W-1:0] head_inst0_i,
  input [`XLEN-1:0] head_pc1_i,
  input [`XLEN-1:0] head_next_pc1_i,
  input [`INST_W-1:0] head_inst1_i,

  input [`XLEN-1:0] next_fetch_pc_i,

  input [`XLEN-1:0] return_cont_pc_i,
  input [`XLEN-1:0] return_cont_next_pc_i,
  input [`INST_W-1:0] return_cont_inst_i,

  input [`XLEN-1:0] branch_target_cache_target_pc_i,
  input [`XLEN-1:0] branch_target_cache_next_pc_i,
  input [`INST_W-1:0] branch_target_cache_inst_i,
  input [`XLEN-1:0] direct_ret_target_i,

  output core_dispatch0_valid_o,
  output core_dispatch1_valid_o,
  output core_dispatch0_fire_o,
  output jump_dispatch_fire_o,
  output mem_dispatch_fire_o,
  output [`XLEN-1:0] core_dispatch0_pc_o,
  output [`XLEN-1:0] core_dispatch0_next_pc_o,
  output [`INST_W-1:0] core_dispatch0_inst_o,
  output [`XLEN-1:0] core_dispatch0_csr_rdata_o,
  output [`XLEN-1:0] core_dispatch1_pc_o,
  output [`XLEN-1:0] core_dispatch1_next_pc_o,
  output [`INST_W-1:0] core_dispatch1_inst_o,

  output [`XLEN-1:0] core_dispatch0_pred_npc_o,
  output [`XLEN-1:0] core_dispatch1_pred_npc_o
);

  assign core_dispatch0_valid_o =
      branch_prefetch_dispatch_attempt_i ||
      system_csr_dispatch_valid_i ||
      frontend_dispatch_to_backend_valid_i ||
      direct_branch0_dispatch_valid_i ||
      direct_jal0_dispatch_valid_i ||
      direct_ret0_dispatch_valid_i ||
      lane1_barrier_dispatch0_valid_i ||
      jump_dispatch_valid_i || mem_dispatch_valid_i;

  assign core_dispatch1_valid_o =
      branch_prefetch_dispatch_attempt_i ||
      (return_cont_attempt_i || branch_target_append_attempt_i ||
       branch_fallthrough_append_attempt_i ||
       frontend_dispatch_to_backend_valid_i);

  assign core_dispatch0_fire_o =
      core_dispatch0_valid_o && dispatch0_ready_i;
  assign jump_dispatch_fire_o =
      jump_dispatch_valid_i && dispatch0_ready_i;
  assign mem_dispatch_fire_o =
      mem_dispatch_valid_i && dispatch0_ready_i;

  assign core_dispatch0_pc_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_pc0_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec0_pc_i :
      system_csr_dispatch_valid_i ? pending_system_pc_i :
      jump_dispatch_valid_i ? pending_jump_pc_i :
      mem_dispatch_valid_i ? pending_mem_pc_i :
      head_pc0_i;

  assign core_dispatch0_next_pc_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_next_pc0_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec0_next_pc_i :
      system_csr_dispatch_valid_i ? pending_system_next_pc_i :
      jump_dispatch_valid_i ? pending_jump_next_pc_i :
      mem_dispatch_valid_i ? pending_mem_next_pc_i :
      direct_jal0_dispatch_valid_i ? head_next_pc0_i :
      direct_ret0_dispatch_valid_i ? direct_ret_target_i :
      head_next_pc0_i;

  assign core_dispatch0_inst_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_inst0_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec0_inst_i :
      system_csr_dispatch_valid_i ? pending_system_inst_i :
      jump_dispatch_valid_i ? pending_jump_inst_i :
      mem_dispatch_valid_i ? pending_mem_inst_i :
      head_inst0_i;

  assign core_dispatch0_csr_rdata_o =
      system_csr_dispatch_valid_i ? pending_system_csr_rdata_i :
                                    {`XLEN{1'b0}};

  assign core_dispatch1_pc_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_pc1_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec1_pc_i :
      return_cont_attempt_i ? return_cont_pc_i :
      branch_target_append_attempt_i ?
      branch_target_cache_target_pc_i :
                                       head_pc1_i;

  assign core_dispatch1_next_pc_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_next_pc1_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec1_next_pc_i :
      return_cont_attempt_i ? return_cont_next_pc_i :
      branch_target_append_attempt_i ?
      branch_target_cache_next_pc_i :
      direct_jal1_fire_i ? head_next_pc1_i :
      direct_ret1_fire_i ? direct_ret_target_i :
                                        head_next_pc1_i;

  assign core_dispatch1_inst_o =
      branch_prefetch_dispatch_buffer_i ? branch_prefetch_buf_inst1_i :
      branch_prefetch_dispatch_rsp_i ? fetch_dec1_inst_i :
      return_cont_attempt_i ? return_cont_inst_i :
      branch_target_append_attempt_i ?
      branch_target_cache_inst_i :
                                       head_inst1_i;

  // ---- pred_npc: 前端「实际预测的 next-fetch PC」（与 next_pc 平行的新字段，B2 后端 per-branch mispredict 用）----
  // pred_npc 必须等于前端为本 packet 实际取指的后继（= 下一条 FIFO entry 的 pc0，由 next_fetch_pc_i 传入），
  // 否则前端按预测 taken 取了 wrong-path、而后端 pred=fallthrough 判 mis=0 不 squash → wrong-path 提交。
  //   双发射：d0 后继=d1.pc（核内 head 路径 core_dispatch1_pc_o==head_pc1==d1.pc）；d1 后继=packet 预测后继。
  //   单发射/d0 预测跳转：d0 后继=packet 预测后继(next_fetch_pc_i)。
  assign core_dispatch0_pred_npc_o =
      core_dispatch1_valid_o ? core_dispatch1_pc_o : next_fetch_pc_i;
  assign core_dispatch1_pred_npc_o = next_fetch_pc_i;

endmodule
