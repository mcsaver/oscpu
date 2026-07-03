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
  // 【F2】pred_npc 单源化与 d1 squash(见 spec ooo-f2-per-packet-pred §2)
  input dispatch1_ready_i,
  input dispatch1_squash_i,        // solo 分支(taken/!dual)或非返回 JALR 拍禁 d1 影子
  input d0_ctrlflow_fired_i,       // d0 是本拍 fire 的控制流(jal0/ret0/branch0/jump_spec)
  input d1_ctrlflow_fired_i,       // d1 是本拍 fire 的控制流(jal1/ret1/branch1)
  input [`XLEN-1:0] direct_fire_succ_i,  // 本拍 direct fire 的实际重取目标(单一真源)

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

  // 【F2】solo 分支/非返回 JALR 拍 d1 影子必须 squash: 免 redirect 后不再有恒 ROB-walk
  // 兜底砍它, 若照旧双发, wrong-path fall-through 会顺序提交(#110 边界 2)。
  assign core_dispatch1_valid_o =
      branch_prefetch_dispatch_attempt_i ||
      ((return_cont_attempt_i || branch_target_append_attempt_i ||
        branch_fallthrough_append_attempt_i ||
        frontend_dispatch_to_backend_valid_i) && !dispatch1_squash_i);

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

  // ---- pred_npc: 前端「实际取指后继」(后端 per-uop mispredict 判据) ----
  // 【F2 单源化】pred_npc 恒等于前端本拍实际取指决策, 不允许推断/近似(#105 障碍②的结构解):
  //   d0/d1 是本拍 fire 的控制流 → direct_fire_succ_i(与 OutstandingSequencer.next_fetch
  //     共享同一 wire, 机械同源——jal/ret 精确 target、taken 分支=pred target、
  //     solo not-taken 分支=fallthrough, 解析一致即免 redirect);
  //   d0 非控制流/不 fire 且 d1 实际双发(valid&&ready, pair 原子) → d0 后继=d1.pc;
  //   其余(顺序流) → next_fetch_pc_i = head_pred_succ(count>=2 时下包 pc0, 否则 64'h1
  //     哨兵恒 mispredict 兜底)。
  wire d1_present_w = core_dispatch1_valid_o && dispatch1_ready_i;
  assign core_dispatch0_pred_npc_o =
      d0_ctrlflow_fired_i ? direct_fire_succ_i :
      d1_present_w        ? core_dispatch1_pc_o :
                            next_fetch_pc_i;
  assign core_dispatch1_pred_npc_o =
      d1_ctrlflow_fired_i ? direct_fire_succ_i :
                            next_fetch_pc_i;

endmodule
