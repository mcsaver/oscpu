`include "define.v"

// ALU-only OoO integer backend slice.  The frontend still supplies decoded uops;
// this module closes the loop from rename/issue through PRF read, dual ALU
// execute, writeback wakeup, and in-order ROB commit.
/* verilator lint_off UNOPTFLAT */
// 【B-FP 簇】FP 交叉 wakeup/ready 菱形使 Verilator 跨实例保守判环
// (__Vcellinp__ 端口注入形态)。行为正确性由全量测试守; 真伪甄别与
// 结构化真修(交叉唤醒打拍)列为 FP 簇收尾项。
module OooIntBackend #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,
  input checkpoint_quiesce_i,
  input mem_issue_block_i,
  input pending_branch_fast_valid_i,
  input [`XLEN-1:0] pending_branch_fast_pc_i,
  input [`XLEN * `REG_NUM - 1:0] recover_gprs_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rd_arch_i,
  input [`XLEN-1:0] dispatch0_imm_i,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rd_arch_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  // 【F2】BPU 查询快照随行(bht_idx=lookup 拍 pc^ghr): thread 进 IQ, resolve 拍导出回训
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,

  // 【B-FP 簇】FP dispatch 属性(AluDecodeBackend 旁路 decode 供给; spec §7)
  input dispatch0_is_fp_i,
  input dispatch0_fp_load_i,
  input dispatch0_fp_store_i,
  input dispatch0_fp_double_i,
  input dispatch0_fp_gpr_write_i,
  input dispatch0_fp_gpr_src_i,
  input dispatch0_fp_fs1_en_i,
  input dispatch0_fp_fs2_en_i,
  input dispatch0_fp_fs3_en_i,
  input dispatch1_is_fp_i,
  input dispatch1_fp_load_i,
  input dispatch1_fp_store_i,
  input dispatch1_fp_double_i,
  input dispatch1_fp_gpr_write_i,
  input dispatch1_fp_gpr_src_i,
  input dispatch1_fp_fs1_en_i,
  input dispatch1_fp_fs2_en_i,
  input dispatch1_fp_fs3_en_i,
  input [2:0] frm_i,
  output [4:0] commit0_fflags_o,
  output commit0_is_fp_rd_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  // 【LSQ·SQ 切换】事务属性(spec §3.6): probe=store 翻译探测(不写, PA 回传);
  // pretrans+nokill=SQ drain 落存(已翻译、写必达)。
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  // 当前上下文数据访问是否经 Sv39 翻译(load-vs-SQ 判定在翻译开启时保守 blind, 防 VA 别名)
  input mem_translate_active_i,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,
  output mem_idle_o,
  // 退休侧访存静默(SQ 排空且无 drain 在飞): AND 进 backend_drained, 保证 system/trap/FP
  // 等串行点看到的"后端排空"包含已退休未落存的 store(SQ 化后 ROB 空不再隐含内存静默)。
  output mem_retire_quiet_o,
  output execute0_valid_o,
  output execute1_valid_o,

  output branch_resolve_valid_o,
  output [`XLEN-1:0] branch_resolve_pc_o,
  output [`XLEN-1:0] branch_resolve_next_pc_o,
  output branch_resolve_misaligned_o,
  // B2：导出解析分支的 rob_idx（kill_younger_than 的年龄基准；issue 路径）。
  // 详见 design/arch/b2-branch-spec-redirect.md §3.1/§7。本切片纯增量，未接消费者。
  output [ROB_INDEX_W-1:0] branch_resolve_rob_idx_o,
  // B2 片4：被选中 lane 的 branch/JALR mispredict 脉冲（mode=1 驱动 ROB-walk kill + redirect）。
  output branch_resolve_mispredict_o,
  // 【F2】resolve 总线随行导出: BPU issue-resolve 回训(前端消费, 只在 is_branch 拍)
  output branch_resolve_is_branch_o,
  output branch_resolve_taken_o,
  output branch_resolve_pred_taken_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o
);

  localparam [1:0] CLMUL_OP_LOW = 2'd0;
  localparam [1:0] CLMUL_OP_HIGH = 2'd1;
  localparam [1:0] CLMUL_OP_REV = 2'd2;

  wire wb0_valid_w;
  wire [ROB_INDEX_W-1:0] wb0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb0_pdest_w;
  wire [`XLEN-1:0] wb0_data_w;
  wire wb0_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb0_cause_w;
  wire [`XLEN-1:0] wb0_tval_w;
  wire wb1_valid_w;
  wire [ROB_INDEX_W-1:0] wb1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb1_pdest_w;
  wire [`XLEN-1:0] wb1_data_w;
  wire wb1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb1_cause_w;
  wire [`XLEN-1:0] wb1_tval_w;
  wire issue0_valid_w;
  wire issue0_ready_w;
  wire [`XLEN-1:0] issue0_pc_w;
  wire [`XLEN-1:0] issue0_next_pc_w;
  wire [`XLEN-1:0] issue0_pred_npc_w;
  wire [`BPU_BHT_INDEX_W-1:0] issue0_bht_idx_w;
  wire issue0_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] issue1_bht_idx_w;
  wire issue1_pred_taken_w;
  wire [`INST_W-1:0] issue0_inst_w;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest_w;
  wire [`XLEN-1:0] issue0_imm_w;

  wire issue1_valid_w;
  wire issue1_ready_w;
  wire [`XLEN-1:0] issue1_pc_w;
  wire [`XLEN-1:0] issue1_next_pc_w;
  wire [`XLEN-1:0] issue1_pred_npc_w;
  wire [`INST_W-1:0] issue1_inst_w;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest_w;
  wire [`XLEN-1:0] issue1_imm_w;
  wire mem_issue_block_w = mem_issue_block_i || checkpoint_quiesce_i;

  // 【B-FP 簇】dispatch 分流: FP 算术/跨域 → FpBackend.disp; FP load → fpld_alloc
  // (lane0/lane1 均可, 每拍一条); FP store → fpst_query(数据源进整数 IQ fp_src2)。
  // fire 原子性: 双方 ready 交叉 gate 对方 valid(容量型 ready 无组合环)。
  wire d0_fp_arith_w = dispatch0_is_fp_i && !dispatch0_fp_load_i &&
                       !dispatch0_fp_store_i;
  wire d1_fp_arith_w = dispatch1_is_fp_i && !dispatch1_fp_load_i &&
                       !dispatch1_fp_store_i;
  wire d0_is_fp_rd_w = dispatch0_is_fp_i && !dispatch0_fp_store_i &&
                       !dispatch0_fp_gpr_write_i;   // FPR 目的(含 FP load)
  wire d1_is_fp_rd_w = dispatch1_is_fp_i && !dispatch1_fp_store_i &&
                       !dispatch1_fp_gpr_write_i;
  wire fp_disp_ready_w;
  wire fp_disp1_ready_w;
  wire fp_alloc0_ready_w;
  wire fp_alloc1_ready_w;
  wire d0_fp_ok_w = !dispatch0_is_fp_i ||
                    (d0_fp_arith_w ? fp_disp_ready_w :
                     dispatch0_fp_load_i ? fp_alloc0_ready_w : 1'b1);
  wire d1_fp_ok_w = !dispatch1_is_fp_i ||
                    (d1_fp_arith_w ? fp_disp1_ready_w :
                     dispatch1_fp_load_i ? fp_alloc1_ready_w : 1'b1);
  wire [PHY_REG_ADDR_W-1:0] fp_disp_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp1_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld0_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld0_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld1_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpst0_query_preg_w;
  wire fpst0_query_ready_w;
  wire [PHY_REG_ADDR_W-1:0] fpst1_query_preg_w;
  wire fpst1_query_ready_w;
  wire fp_wake0_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fp_wake0_preg_w;
  wire fp_wake1_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fp_wake1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] fpst_read_preg_w;
  wire [`XLEN-1:0] fpst_read_data_w;
  wire [PHY_REG_ADDR_W-1:0] fp_gpr_read_addr_w;
  wire [`XLEN-1:0] fp_gpr_read_data_w;
  wire fpwb_valid_w;
  wire [ROB_INDEX_W-1:0] fpwb_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] fpwb_pdest_w;
  wire fpwb_rd_en_w;
  wire [`XLEN-1:0] fpwb_data_w;
  wire [4:0] fpwb_fflags_w;
  wire fpwb_ready_w;
  wire rob_walk0_is_fp_w;
  wire rob_walk1_is_fp_w;
  wire commit0_is_fp_rd_w;
  wire commit1_is_fp_rd_w;
  wire issue0_fp_pdest_w;
  wire issue0_fp_st_en_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_fp_st_preg_w;
  wire issue1_fp_pdest_w;
  wire issue1_fp_st_en_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_fp_st_preg_w;
  wire rob_recover_active_w;
  wire dispatch0_dbe_ready_w;
  wire dispatch1_dbe_ready_w;
  // lane1 GPR 目的 FP 的整数 pdest(经 DispatchBackend 新输出)
  wire [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest_probe_w;
  wire walk0_fp_valid_w;
  wire [`REG_ADDR_W-1:0] walk0_fp_arch_w;
  wire [PHY_REG_ADDR_W-1:0] walk0_fp_old_w;
  wire [PHY_REG_ADDR_W-1:0] walk0_fp_new_w;
  wire walk1_fp_valid_w;
  wire [`REG_ADDR_W-1:0] walk1_fp_arch_w;
  wire [PHY_REG_ADDR_W-1:0] walk1_fp_old_w;
  wire [PHY_REG_ADDR_W-1:0] walk1_fp_new_w;
  wire [4:0] wb0_fflags_w;
  wire [4:0] wb1_fflags_w;
  assign dispatch0_ready_o = dispatch0_dbe_ready_w && d0_fp_ok_w;
  assign dispatch1_ready_o = dispatch1_dbe_ready_w && d1_fp_ok_w;
  wire dispatch0_fire_w;
  wire [ROB_INDEX_W-1:0] dispatch0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_w;
  wire dispatch0_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_w;
  wire dispatch0_src2_ready_w;
  wire dispatch1_fire_w;
  wire [ROB_INDEX_W-1:0] dispatch1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_w;
  wire dispatch1_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_w;
  wire dispatch1_src2_ready_w;
  wire [ROB_INDEX_W-1:0] rob_head_idx_w;
  wire rob_head_valid_w;

  wire unused_issue_ctrl_bits_w =
      (|{issue0_ctrl_w[42:24], issue0_ctrl_w[15:0]}) |
      (|{issue1_ctrl_w[42:24], issue1_ctrl_w[15:0]});

  OooDispatchBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_dispatch_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),   // B2 ROB-walk：mispredict 控制流 rob_idx（与 mispredict 同拍）
    .branch_mispredict_valid_i(branch_resolve_mispredict_w),  // B2 片4：ROB-walk kill 触发
    .issue_mem_block_i(mem_issue_block_w),
    .sq_alloc0_ready_i(sq_alloc0_ready_w),
    .sq_alloc1_ready_i(sq_alloc1_ready_w),
    .dispatch0_valid_i(dispatch0_valid_i && d0_fp_ok_w),
    .dispatch0_ready_o(dispatch0_dbe_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch_i),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch_i),
    .dispatch0_rd_arch_i(dispatch0_rd_arch_i),
    .dispatch0_is_fp_rd_i(d0_is_fp_rd_w),
    .dispatch0_is_fp_i(dispatch0_is_fp_i),
    .dispatch0_fp_pdest_i(dispatch0_fp_load_i ? fpld0_new_pdest_w
                                              : fp_disp_new_pdest_w),
    .dispatch0_fp_old_pdest_i(dispatch0_fp_load_i ? fpld0_old_pdest_w
                                                  : fp_disp_old_pdest_w),
    .dispatch0_fp_st_src_en_i(dispatch0_fp_store_i),
    .dispatch0_fp_st_src_preg_i(fpst0_query_preg_w),
    .dispatch0_fp_st_src_ready_i(fpst0_query_ready_w),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch0_bht_idx_i(dispatch0_bht_idx_i),
    .dispatch0_pred_taken_i(dispatch0_pred_taken_i),
    .dispatch1_bht_idx_i(dispatch1_bht_idx_i),
    .dispatch1_pred_taken_i(dispatch1_pred_taken_i),
    .dispatch1_valid_i(dispatch1_valid_i && d1_fp_ok_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(dispatch1_dbe_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch_i),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch_i),
    .dispatch1_rd_arch_i(dispatch1_rd_arch_i),
    .dispatch1_is_fp_rd_i(d1_is_fp_rd_w),
    .dispatch1_is_fp_i(dispatch1_is_fp_i),
    .dispatch1_fp_pdest_i(dispatch1_fp_load_i ? fpld1_new_pdest_w
                                              : fp_disp1_new_pdest_w),
    .dispatch1_fp_old_pdest_i(dispatch1_fp_load_i ? fpld1_old_pdest_w
                                                  : fp_disp1_old_pdest_w),
    .dispatch1_fp_st_src_en_i(dispatch1_fp_store_i),
    .dispatch1_fp_st_src_preg_i(fpst1_query_preg_w),
    .dispatch1_fp_st_src_ready_i(fpst1_query_ready_w),
    .fp_wake0_valid_i(fp_wake0_valid_w),
    .fp_wake0_preg_i(fp_wake0_preg_w),
    .fp_wake1_valid_i(fp_wake1_valid_w),
    .fp_wake1_preg_i(fp_wake1_preg_w),
    .dispatch1_imm_i(dispatch1_imm_i),
    .wb0_valid_i(wb0_valid_w),
    .wb0_rob_idx_i(wb0_rob_idx_w),
    .wb0_pdest_i(wb0_pdest_w),
    .wb0_data_i(wb0_data_w),
    .wb0_exception_i(wb0_exception_w),
    .wb0_cause_i(wb0_cause_w),
    .wb0_tval_i(wb0_tval_w),
    .wb0_fflags_i(wb0_fflags_w),
    .wb1_valid_i(wb1_valid_w),
    .wb1_rob_idx_i(wb1_rob_idx_w),
    .wb1_pdest_i(wb1_pdest_w),
    .wb1_data_i(wb1_data_w),
    .wb1_exception_i(wb1_exception_w),
    .wb1_cause_i(wb1_cause_w),
    .wb1_tval_i(wb1_tval_w),
    .wb1_fflags_i(wb1_fflags_w),
    .issue0_valid_o(issue0_valid_w),
    .issue0_ready_i(issue0_ready_w),
    .issue0_pc_o(issue0_pc_w),
    .issue0_next_pc_o(issue0_next_pc_w),
    .issue0_pred_npc_o(issue0_pred_npc_w),
    .issue0_inst_o(issue0_inst_w),
    .issue0_ctrl_o(issue0_ctrl_w),
    .issue0_rob_idx_o(issue0_rob_idx_w),
    .issue0_src1_preg_o(issue0_src1_preg_w),
    .issue0_src2_preg_o(issue0_src2_preg_w),
    .issue0_pdest_o(issue0_pdest_w),
    .issue0_fp_pdest_o(issue0_fp_pdest_w),
    .issue0_fp_st_src_en_o(issue0_fp_st_en_w),
    .issue0_fp_st_src_preg_o(issue0_fp_st_preg_w),
    .issue0_imm_o(issue0_imm_w),
    .issue0_bht_idx_o(issue0_bht_idx_w),
    .issue0_pred_taken_o(issue0_pred_taken_w),
    .issue1_bht_idx_o(issue1_bht_idx_w),
    .issue1_pred_taken_o(issue1_pred_taken_w),
    .issue1_valid_o(issue1_valid_w),
    .issue1_ready_i(issue1_ready_w),
    .issue1_pc_o(issue1_pc_w),
    .issue1_next_pc_o(issue1_next_pc_w),
    .issue1_pred_npc_o(issue1_pred_npc_w),
    .issue1_inst_o(issue1_inst_w),
    .issue1_ctrl_o(issue1_ctrl_w),
    .issue1_rob_idx_o(issue1_rob_idx_w),
    .issue1_src1_preg_o(issue1_src1_preg_w),
    .issue1_src2_preg_o(issue1_src2_preg_w),
    .issue1_pdest_o(issue1_pdest_w),
    .issue1_fp_pdest_o(issue1_fp_pdest_w),
    .issue1_fp_st_src_en_o(issue1_fp_st_en_w),
    .issue1_fp_st_src_preg_o(issue1_fp_st_preg_w),
    .issue1_imm_o(issue1_imm_w),
    .dispatch0_fire_o(dispatch0_fire_w),
    .dispatch0_rob_idx_o(dispatch0_rob_idx_w),
    .dispatch0_pdest_o(dispatch0_pdest_w),
    .dispatch1_pdest_o(dispatch1_new_pdest_probe_w),
    .dispatch0_src1_preg_o(dispatch0_src1_preg_w),
    .dispatch0_src1_ready_o(dispatch0_src1_ready_w),
    .dispatch0_src2_preg_o(dispatch0_src2_preg_w),
    .dispatch0_src2_ready_o(dispatch0_src2_ready_w),
    .dispatch1_fire_o(dispatch1_fire_w),
    .dispatch1_rob_idx_o(dispatch1_rob_idx_w),
    .dispatch1_src1_preg_o(dispatch1_src1_preg_w),
    .dispatch1_src1_ready_o(dispatch1_src1_ready_w),
    .dispatch1_src2_preg_o(dispatch1_src2_preg_w),
    .dispatch1_src2_ready_o(dispatch1_src2_ready_w),
    .commit_ready_i(commit_ready_i && !checkpoint_capture_i &&
                    !checkpoint_restore_i && !checkpoint_quiesce_i),
    .commit1_block_i(commit1_block_i),
    // 【serialize Phase1 §9/§10.4】mem 门控用 mem_idle 单独(miq_empty=无在飞 AXI probe/load/drain), 不含
    // mem_retire_quiet(sq_empty)。★关键: 加 sq_empty 会死锁——head0-CSR 在 ROB 队头, 若有 younger uncommitted
    // store 在 SQ(它既不能 drain[未 committed] 又不能 retire[被队头 CSR 挡]), sq 永不空→CSR 永不 commit。
    // refute:sq-flush 已证 mem_idle 单独足够: committed store 恒存活 flush_all + 边界 drain nokill 免疫;
    // younger store 的 probe 在 mem_idle 前完成, 之后被 serial_flush 干净 flush(uncommitted 丢弃)。
    .mem_quiet_i(mem_idle_o),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_is_fp_rd_o(commit0_is_fp_rd_w),
    .commit0_fflags_o(commit0_fflags_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_o),
    .commit0_new_pdest_o(commit0_new_pdest_o),
    .commit0_data_o(commit0_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_o),
    .commit0_tval_o(commit0_tval_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_is_fp_rd_o(commit1_is_fp_rd_w),
    .commit1_fflags_o(commit1_fflags_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_o),
    .commit1_new_pdest_o(commit1_new_pdest_o),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_o),
    .commit1_tval_o(commit1_tval_o),
    .rob_head_idx_o(rob_head_idx_w),
    .rob_recover_active_o(rob_recover_active_w),
    .walk0_fp_valid_o(walk0_fp_valid_w),
    .walk0_fp_arch_o(walk0_fp_arch_w),
    .walk0_fp_old_pdest_o(walk0_fp_old_w),
    .walk0_fp_new_pdest_o(walk0_fp_new_w),
    .walk1_fp_valid_o(walk1_fp_valid_w),
    .walk1_fp_arch_o(walk1_fp_arch_w),
    .walk1_fp_old_pdest_o(walk1_fp_old_w),
    .walk1_fp_new_pdest_o(walk1_fp_new_w),
    .rob_head_valid_o(rob_head_valid_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
	  );

  wire [`XLEN-1:0] issue0_src1_data_w;
  wire [`XLEN-1:0] issue0_src2_data_w;
  wire [`XLEN-1:0] issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_data_w;
  // Wave4b 删除：dispatch 拍分支快解析全族（candidate/src/value/FAST_BRANCH_TRACK/
  // CompareUnit/PRF read4-5）——`!(`OOO_DBRANCH_DOMAIN_A)` 恒 0 证死。分支恒经 IQ →
  // issue-resolve → 强制 mispredict + ROB-walk kill（活 F2 路径，不受本次删除影响）。

  OooPhysRegFile #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_phys_reg_file (
    .clk(clk),
    .rst(rst),
    .recover_i(flush_i),
    .recover_gprs_i(recover_gprs_i),
    .read0_addr_i(issue0_src1_preg_w),
    .read0_data_o(issue0_src1_data_w),
    .read1_addr_i(issue0_src2_preg_w),
    .read1_data_o(issue0_src2_data_w),
    .read2_addr_i(issue1_src1_preg_w),
    .read2_data_o(issue1_src1_data_w),
    .read3_addr_i(issue1_src2_preg_w),
    .read3_data_o(issue1_src2_data_w),
    .read8_addr_i(fp_gpr_read_addr_w),
    .read8_data_o(fp_gpr_read_data_w),
    .write0_valid_i(wb0_valid_w && (wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}})),
    .write0_addr_i(wb0_pdest_w),
    .write0_data_i(wb0_data_w),
    .write1_valid_i(wb1_valid_w && (wb1_pdest_w != {PHY_REG_ADDR_W{1'b0}})),
    .write1_addr_i(wb1_pdest_w),
    .write1_data_i(wb1_data_w)
  );

  function [`XLEN-1:0] select_op1;
    input [1:0] op1_sel;
    input [`XLEN-1:0] rs1_data;
    input [`XLEN-1:0] pc;
    begin
      case (op1_sel)
        `OP1_SEL_RS1:  select_op1 = rs1_data;
        `OP1_SEL_PC:   select_op1 = pc;
        `OP1_SEL_ZERO: select_op1 = {`XLEN{1'b0}};
        default:       select_op1 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] select_op2;
    input [1:0] op2_sel;
    input [`XLEN-1:0] rs2_data;
    input [`XLEN-1:0] imm;
    begin
      case (op2_sel)
        `OP2_SEL_RS2:  select_op2 = rs2_data;
        `OP2_SEL_IMM:  select_op2 = imm;
        `OP2_SEL_FOUR: select_op2 = {{(`XLEN-3){1'b0}}, 3'd4};
        `OP2_SEL_ZERO: select_op2 = {`XLEN{1'b0}};
        default:       select_op2 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] sign_extend_word;
    input [31:0] word;
    begin
      sign_extend_word = {{(`XLEN-32){word[31]}}, word};
    end
  endfunction

  function [`XLEN-1:0] zero_extend_word;
    input [31:0] word;
    begin
      zero_extend_word = {{(`XLEN-32){1'b0}}, word};
    end
  endfunction

  // AMO 结果计算已抽到 execute/OooAmoGate.v

  // AMO 结果计算已抽到 execute/OooAmoGate.v

  function [`XLEN-1:0] rv64_word_alu_result;
    input [3:0] alu_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg [31:0] result32;
    begin
      case (alu_op)
        `ALU_OP_ADD: result32 = src1[31:0] + src2[31:0];
        `ALU_OP_SUB: result32 = src1[31:0] - src2[31:0];
        `ALU_OP_SLL: result32 = src1[31:0] << src2[4:0];
        `ALU_OP_SRL: result32 = src1[31:0] >> src2[4:0];
        `ALU_OP_SRA: result32 = $signed(src1[31:0]) >>> src2[4:0];
        default:     result32 = src1[31:0] + src2[31:0];
      endcase
      rv64_word_alu_result = sign_extend_word(result32);
    end
  endfunction

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  function is_clmul_inst;
    input [`INST_W-1:0] inst;
    begin
      is_clmul_inst =
          (inst[6:0] == `OPCODE_OP) && (inst[31:25] == 7'h05) &&
          ((inst[14:12] == `FUNCT3_SLL) ||
           (inst[14:12] == `FUNCT3_SLT) ||
           (inst[14:12] == `FUNCT3_SLTU));
    end
  endfunction

  function [1:0] clmul_op_from_funct3;
    input [2:0] funct3;
    begin
      case (funct3)
        `FUNCT3_SLT:  clmul_op_from_funct3 = CLMUL_OP_HIGH;
        `FUNCT3_SLTU: clmul_op_from_funct3 = CLMUL_OP_REV;
        default:      clmul_op_from_funct3 = CLMUL_OP_LOW;
      endcase
    end
  endfunction

  wire issue1_src1_issue0_forward_w =
      issue0_current_result_valid_w &&
      (issue1_src1_preg_w == issue0_pdest_w) &&
      (issue1_src1_preg_w != {PHY_REG_ADDR_W{1'b0}});
  wire issue1_src2_issue0_forward_w =
      issue0_current_result_valid_w &&
      (issue1_src2_preg_w == issue0_pdest_w) &&
      (issue1_src2_preg_w != {PHY_REG_ADDR_W{1'b0}});
  wire [`XLEN-1:0] issue1_src1_value_w =
      issue1_src1_issue0_forward_w ? issue0_wb_data_w :
                                     issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_value_w =
      issue1_src2_issue0_forward_w ? issue0_wb_data_w :
                                     issue1_src2_data_w;

  wire [`XLEN-1:0] issue0_alu_src1_w =
      select_op1(issue0_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue0_src1_data_w, issue0_pc_w);
  wire [`XLEN-1:0] issue0_alu_src2_w =
      select_op2(issue0_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue0_src2_data_w, issue0_imm_w);
  wire [`XLEN-1:0] issue1_alu_src1_w =
      select_op1(issue1_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue1_src1_value_w, issue1_pc_w);
  wire [`XLEN-1:0] issue1_alu_src2_w =
      select_op2(issue1_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue1_src2_value_w, issue1_imm_w);

  wire [`XLEN-1:0] issue0_alu_result_w;
  wire [`XLEN-1:0] issue1_alu_result_w;
  wire [`XLEN-1:0] issue0_alu_result_final_w;
  wire [`XLEN-1:0] issue1_alu_result_final_w;
  wire [`XLEN-1:0] issue0_exec_result_w;
  wire [`XLEN-1:0] issue1_exec_result_w;
  wire [`XLEN-1:0] issue0_wb_data_w;
  wire [`XLEN-1:0] issue1_wb_data_w;
  wire issue0_is_branch_w = issue0_valid_w && issue0_ctrl_w[`CTRL_BRANCH_BIT];
  wire issue1_is_branch_w = issue1_valid_w && issue1_ctrl_w[`CTRL_BRANCH_BIT];
  wire issue0_branch_taken_w;
  wire issue1_branch_taken_w;
  wire [`XLEN-1:0] issue0_branch_target_w = issue0_pc_w + issue0_imm_w;
  wire [`XLEN-1:0] issue1_branch_target_w = issue1_pc_w + issue1_imm_w;
  wire [`XLEN-1:0] issue0_branch_next_pc_w =
      issue0_branch_taken_w ? issue0_branch_target_w : issue0_next_pc_w;
  wire [`XLEN-1:0] issue1_branch_next_pc_w =
      issue1_branch_taken_w ? issue1_branch_target_w : issue1_next_pc_w;
  CompareUnit u_branch_compare0 (
    .lhs_i(issue0_src1_data_w),
    .rhs_i(issue0_src2_data_w),
    .cmp_op_i(issue0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .cmp_true_o(issue0_branch_taken_w)
  );

  CompareUnit u_branch_compare1 (
    .lhs_i(issue1_src1_value_w),
    .rhs_i(issue1_src2_value_w),
    .cmp_op_i(issue1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .cmp_true_o(issue1_branch_taken_w)
  );

  ALU u_alu0 (
    .src1_i(issue0_alu_src1_w),
    .src2_i(issue0_alu_src2_w),
    .alu_op_i(issue0_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue0_alu_result_w)
  );

  ALU u_alu1 (
    .src1_i(issue1_alu_src1_w),
    .src2_i(issue1_alu_src2_w),
    .alu_op_i(issue1_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue1_alu_result_w)
  );

  // RV64 的 ADDW/SLLIW 等 *W 指令写回前必须截断到 32 位再符号扩展；
  // OoO 后端复用 RV32 ALU 时不能直接写回 64-bit 组合结果。
  assign issue0_alu_result_final_w =
      (issue0_ctrl_w[`CTRL_WORD_OP_BIT] && !issue0_ctrl_w[`CTRL_MULDIV_BIT]) ?
      rv64_word_alu_result(issue0_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB],
                           issue0_alu_src1_w, issue0_alu_src2_w) :
      issue0_alu_result_w;
  assign issue1_alu_result_final_w =
      (issue1_ctrl_w[`CTRL_WORD_OP_BIT] && !issue1_ctrl_w[`CTRL_MULDIV_BIT]) ?
      rv64_word_alu_result(issue1_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB],
                           issue1_alu_src1_w, issue1_alu_src2_w) :
      issue1_alu_result_w;

  // bitmanip 结果计算下沉到 OooBitmanipGate（两条 issue lane 各一个实例）。
  wire [`XLEN-1:0] issue0_bitmanip_result_w;
  wire [`XLEN-1:0] issue1_bitmanip_result_w;
  OooBitmanipGate u_bitmanip0 (
    .opcode_i(issue0_inst_w[6:0]),
    .funct10_i({issue0_inst_w[31:25], issue0_inst_w[14:12]}),
    .imm_i(issue0_inst_w[25:20]),
    .src1_i(issue0_src1_data_w),
    .src2_i(issue0_src2_data_w),
    .result_o(issue0_bitmanip_result_w)
  );
  OooBitmanipGate u_bitmanip1 (
    .opcode_i(issue1_inst_w[6:0]),
    .funct10_i({issue1_inst_w[31:25], issue1_inst_w[14:12]}),
    .imm_i(issue1_inst_w[25:20]),
    .src1_i(issue1_src1_value_w),
    .src2_i(issue1_src2_value_w),
    .result_o(issue1_bitmanip_result_w)
  );
  assign issue0_exec_result_w =
      issue0_ctrl_w[`CTRL_BITMANIP_BIT] ?
      issue0_bitmanip_result_w :
      issue0_alu_result_final_w;
  assign issue1_exec_result_w =
      issue1_ctrl_w[`CTRL_BITMANIP_BIT] ?
      issue1_bitmanip_result_w :
      issue1_alu_result_final_w;

  WBU u_wbu0 (
    .wb_sel_i(issue0_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue0_exec_result_w),
    .pc_plus4_i(issue0_next_pc_w),
    .imm_data_i(issue0_imm_w),
    .csr_data_i(issue0_imm_w),
    .wb_data_o(issue0_wb_data_w)
  );

  WBU u_wbu1 (
    .wb_sel_i(issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue1_exec_result_w),
    .pc_plus4_i(issue1_next_pc_w),
    .imm_data_i(issue1_imm_w),
    .csr_data_i(issue1_imm_w),
    .wb_data_o(issue1_wb_data_w)
  );

  wire issue0_is_load_w = issue0_valid_w && issue0_ctrl_w[`CTRL_LOAD_BIT];
  wire issue0_is_store_w = issue0_valid_w && issue0_ctrl_w[`CTRL_STORE_BIT];
  wire issue0_is_amo_w = issue0_valid_w && issue0_ctrl_w[`CTRL_AMO_BIT];
  wire issue0_is_lr_w = issue0_is_amo_w && issue0_ctrl_w[`CTRL_AMO_LR_BIT];
  wire issue0_is_sc_w = issue0_is_amo_w && issue0_ctrl_w[`CTRL_AMO_SC_BIT];
  wire issue1_is_load_w = issue1_valid_w && issue1_ctrl_w[`CTRL_LOAD_BIT];
  wire issue1_is_store_w = issue1_valid_w && issue1_ctrl_w[`CTRL_STORE_BIT];
  wire issue1_is_amo_w = issue1_valid_w && issue1_ctrl_w[`CTRL_AMO_BIT];
  wire issue1_is_lr_w = issue1_is_amo_w && issue1_ctrl_w[`CTRL_AMO_LR_BIT];
  wire issue1_is_sc_w = issue1_is_amo_w && issue1_ctrl_w[`CTRL_AMO_SC_BIT];

  wire [`XLEN-1:0] issue0_mem_addr_w;
  wire [`XLEN-1:0] issue0_mem_wdata_w;
  wire [`STRB_W-1:0] issue0_mem_wstrb_w;
  wire [`XLEN-1:0] issue0_mem_load_unused_w;
  wire issue0_mem_misaligned_w;
  wire [`XLEN-1:0] issue1_mem_addr_w;
  wire [`XLEN-1:0] issue1_mem_wdata_w;
  wire [`STRB_W-1:0] issue1_mem_wstrb_w;
  wire [`XLEN-1:0] issue1_mem_load_unused_w;
  wire issue1_mem_misaligned_w;

  LSU u_issue0_lsu (
    .eff_addr_i(issue0_alu_result_w),
    .store_data_i(issue0_fp_st_en_w ? fpst_read_data_w
                                      : issue0_src2_data_w),
    .mem_size_i(issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue0_mem_addr_w),
    .mem_wdata_o(issue0_mem_wdata_w),
    .mem_wstrb_o(issue0_mem_wstrb_w),
    .load_data_o(issue0_mem_load_unused_w),
    .misaligned_o(issue0_mem_misaligned_w)
  );

  LSU u_issue1_lsu (
    .eff_addr_i(issue1_alu_result_w),
    .store_data_i(issue1_fp_st_en_w ? fpst_read_data_w
                                      : issue1_src2_value_w),
    .mem_size_i(issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue1_mem_addr_w),
    .mem_wdata_o(issue1_mem_wdata_w),
    .mem_wstrb_o(issue1_mem_wstrb_w),
    .load_data_o(issue1_mem_load_unused_w),
    .misaligned_o(issue1_mem_misaligned_w)
  );

  reg reservation_valid_q;
  reg [`XLEN-1:0] reservation_addr_q;

  wire [`XLEN-1:0] issue0_reservation_addr_w =
      (issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] == `MEM_SIZE_WORD) ?
      (issue0_alu_result_w & {{(`XLEN-2){1'b1}}, 2'b00}) :
      (issue0_alu_result_w & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}});
  wire [`XLEN-1:0] issue1_reservation_addr_w =
      (issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] == `MEM_SIZE_WORD) ?
      (issue1_alu_result_w & {{(`XLEN-2){1'b1}}, 2'b00}) :
      (issue1_alu_result_w & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}});
  wire issue0_sc_success_w = issue0_is_sc_w && reservation_valid_q &&
                             (reservation_addr_q == issue0_reservation_addr_w);
  wire issue1_sc_success_w = issue1_is_sc_w && reservation_valid_q &&
                             (reservation_addr_q == issue1_reservation_addr_w);
  wire issue0_is_mem_w = (issue0_is_load_w || issue0_is_store_w || issue0_is_amo_w) &&
                         !(issue0_is_sc_w && !issue0_sc_success_w);
  wire issue1_is_mem_w = (issue1_is_load_w || issue1_is_store_w || issue1_is_amo_w) &&
                         !(issue1_is_sc_w && !issue1_sc_success_w);
  // plain store(非 AMO/SC): SQ 模式下走 probe→SQ→退休 drain 生命周期
  wire issue0_is_plain_store_w = issue0_is_store_w && !issue0_is_amo_w;
  wire issue1_is_plain_store_w = issue1_is_store_w && !issue1_is_amo_w;

  reg mem_pending_q;
  reg [ROB_INDEX_W-1:0] mem_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_pdest_q;
  reg mem_pdest_fp_q;
  reg mem_load_q;
  reg mem_store_q;
  reg mem_amo_q;
  reg mem_amo_lr_q;
  reg mem_amo_sc_q;
  reg mem_amo_write_phase_q;
  reg mem_amo_write_sent_q;
  reg [`XLEN-1:0] mem_eff_addr_q;
  reg [1:0] mem_size_q;
  reg mem_unsigned_q;
  reg [`INST_W-1:0] mem_amo_inst_q;
  reg [`XLEN-1:0] mem_amo_src2_q;
  reg [`XLEN-1:0] mem_amo_old_value_q;
  reg [`XLEN-1:0] mem_amo_write_data_q;
  reg [`STRB_W-1:0] mem_amo_write_wstrb_q;
  reg mem_buffer_valid_q;
  reg [ROB_INDEX_W-1:0] mem_buffer_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_buffer_pdest_q;
  reg mem_buffer_pdest_fp_q;
  reg mem_buffer_load_q;
  reg mem_buffer_store_q;
  reg [`XLEN-1:0] mem_buffer_eff_addr_q;
  reg [1:0] mem_buffer_size_q;
  reg mem_buffer_unsigned_q;
  reg [`XLEN-1:0] mem_buffer_wdata_q;
  reg [`STRB_W-1:0] mem_buffer_wstrb_q;

  // ===== 【LSQ·SQ 切换】(spec ooo-lsq-implementation-plan.md §3.6) =====
  // mode=1: plain store 发射即 probe(翻译探测), rsp 拍 PA+data 进 SQ, 退休后 drain 落存;
  // mode=0: 旧路径(store 队头发射+真事务), SQ 保持影子对拍(深 16 不反压)。
  localparam SQ_ENTRY_W = `OOO_SQ_STORE_PATH ? 2 : 4;
  localparam SQ_ENTRY_N = (1 << SQ_ENTRY_W);
  wire sq_mode_w = `OOO_SQ_STORE_PATH;
  // 【B-FP 簇】FP store 数据读地址(issue0/1 互斥走 mem 口)
  assign fpst_read_preg_w = issue0_fp_st_en_w ? issue0_fp_st_preg_w
                                              : issue1_fp_st_preg_w;
  reg mem_probe_q;                     // 当前 pending 事务是 store 翻译探测
  reg [`XLEN-1:0] mem_store_wdata_q;   // probe 完成后回填 SQ 的 store 数据
  reg [`STRB_W-1:0] mem_store_wstrb_q;
  reg drain_inflight_q;                // SQ drain 落存事务在飞(退休副作用, flush 免疫)
  wire sq_alloc0_ready_w;
  wire sq_alloc1_ready_w;
  wire sq_drain_valid_w;
  wire [`XLEN-1:0] sq_drain_addr_w;
  wire [`XLEN-1:0] sq_drain_data_w;
  wire [`STRB_W-1:0] sq_drain_strb_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_valid_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_addr_valid_w;
  wire [SQ_ENTRY_N*`XLEN-1:0] sq_snoop_addr_w;
  wire [SQ_ENTRY_N*`XLEN-1:0] sq_snoop_data_w;
  wire [SQ_ENTRY_N*`STRB_W-1:0] sq_snoop_strb_w;
  wire [SQ_ENTRY_N*ROB_INDEX_W-1:0] sq_snoop_rob_idx_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_committed_w;
  wire [SQ_ENTRY_W-1:0] sq_snoop_head_w;
  wire [SQ_ENTRY_W:0] sq_count_w;
  wire sq_empty_w = (sq_count_w == {(SQ_ENTRY_W+1){1'b0}});
  wire sq_no_committed_w = (sq_snoop_committed_w == {SQ_ENTRY_N{1'b0}});

  // pending_load0/1 唤醒口已随 IQ load-branch-fast 死硅整族删除（消费端 E7 已删，
  // IQ 内选择逻辑空转）。miq_head 前递仍活于其它通路，此处不再驱动 IQ 二次唤醒。

  wire [`XLEN-1:0] mem_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem_rsp_wdata_unused_w;
  wire [`STRB_W-1:0] mem_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem_rsp_load_data_w;
  wire mem_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_write_addr_unused_w;
  wire [`XLEN-1:0] mem_amo_write_wdata_w;
  wire [`STRB_W-1:0] mem_amo_write_wstrb_w;
  wire [`XLEN-1:0] mem_amo_write_load_unused_w;
  wire mem_amo_write_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_old_value_w;
  wire [`XLEN-1:0] mem_amo_result_value_w;

  LSU u_mem_rsp_lsu (
    // rsp 数据展开按 MIQ 队头(LEGACY entry 的字段与单例一致, 恒可用 head)
    .eff_addr_i(miq_head_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(miq_head_size_w),
    .mem_unsigned_i(miq_head_unsigned_w),
    .mem_rdata_i(mem_rsp_rdata_i),
    .mem_addr_o(mem_rsp_addr_unused_w),
    .mem_wdata_o(mem_rsp_wdata_unused_w),
    .mem_wstrb_o(mem_rsp_wstrb_unused_w),
    .load_data_o(mem_rsp_load_data_w),
    .misaligned_o(mem_rsp_misaligned_unused_w)
  );

  // AMO 旧值规整与结果计算下沉到 OooAmoGate。
  OooAmoGate u_amo_gate (
    .inst_i(mem_amo_inst_q),
    .load_data_i(mem_rsp_load_data_w),
    .src2_i(mem_amo_src2_q),
    .size_i(mem_size_q),
    .old_value_o(mem_amo_old_value_w),
    .result_o(mem_amo_result_value_w)
  );

  LSU u_mem_amo_write_lsu (
    .eff_addr_i(mem_eff_addr_q),
    .store_data_i(mem_amo_result_value_w),
    .mem_size_i(mem_size_q),
    .mem_unsigned_i(1'b0),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(mem_amo_write_addr_unused_w),
    .mem_wdata_o(mem_amo_write_wdata_w),
    .mem_wstrb_o(mem_amo_write_wstrb_w),
    .load_data_o(mem_amo_write_load_unused_w),
    .misaligned_o(mem_amo_write_misaligned_unused_w)
  );

  // ===========================================================================
  // 【LSQ Phase2+3 第一刀】访存在飞顺序队列(MIQ): plain LOAD/PROBE/DRAIN 可背
  // 靠背在飞(桥 back-to-back 已支持), AMO/LR/SC 走 LEGACY 独占。rsp 恒配队头。
  // ===========================================================================
  localparam MIQ_ENTRY_N = 4;
  localparam MIQ_ENTRY_W = 2;
  localparam [1:0] MIQ_KIND_LOAD = 2'd0;
  localparam [1:0] MIQ_KIND_PROBE = 2'd1;
  localparam [1:0] MIQ_KIND_DRAIN = 2'd2;
  localparam [1:0] MIQ_KIND_LEGACY = 2'd3;
  wire miq_push_valid_w;
  wire [1:0] miq_push_kind_w;
  wire [ROB_INDEX_W-1:0] miq_push_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq_push_pdest_w;
  wire miq_push_pdest_fp_w;
  wire [1:0] miq_push_size_w;
  wire miq_push_unsigned_w;
  wire [`XLEN-1:0] miq_push_addr_w;
  wire [`XLEN-1:0] miq_push_wdata_w;
  wire [`STRB_W-1:0] miq_push_wstrb_w;
  wire miq_pop_w;
  wire miq_head_valid_w;
  wire [1:0] miq_head_kind_w;
  wire miq_head_killed_w;
  wire [ROB_INDEX_W-1:0] miq_head_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq_head_pdest_w;
  wire miq_head_pdest_fp_w;
  wire [1:0] miq_head_size_w;
  wire miq_head_unsigned_w;
  wire [`XLEN-1:0] miq_head_addr_w;
  wire [`XLEN-1:0] miq_head_wdata_w;
  wire [`STRB_W-1:0] miq_head_wstrb_w;
  wire [MIQ_ENTRY_W:0] miq_count_w;
  wire miq_empty_w;
  wire miq_full_w;
  wire [MIQ_ENTRY_N-1:0] miq_entry_valid_unused_w;
  wire [MIQ_ENTRY_N*2-1:0] miq_entry_kind_unused_w;
  wire [MIQ_ENTRY_N*ROB_INDEX_W-1:0] miq_entry_rob_unused_w;
  wire [MIQ_ENTRY_N*`XLEN-1:0] miq_entry_addr_unused_w;

  OooMemInflightQueue #(
    .ENTRY_N(MIQ_ENTRY_N),
    .ENTRY_W(MIQ_ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_mem_inflight_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_i),
    .push_valid_i(miq_push_valid_w),
    .push_kind_i(miq_push_kind_w),
    .push_rob_idx_i(miq_push_rob_w),
    .push_pdest_i(miq_push_pdest_w),
    .push_pdest_fp_i(miq_push_pdest_fp_w),
    .push_size_i(miq_push_size_w),
    .push_unsigned_i(miq_push_unsigned_w),
    .push_eff_addr_i(miq_push_addr_w),
    .push_wdata_i(miq_push_wdata_w),
    .push_wstrb_i(miq_push_wstrb_w),
    .pop_valid_i(miq_pop_w),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .head_valid_o(miq_head_valid_w),
    .head_kind_o(miq_head_kind_w),
    .head_killed_o(miq_head_killed_w),
    .head_rob_idx_o(miq_head_rob_w),
    .head_pdest_o(miq_head_pdest_w),
    .head_pdest_fp_o(miq_head_pdest_fp_w),
    .head_size_o(miq_head_size_w),
    .head_unsigned_o(miq_head_unsigned_w),
    .head_eff_addr_o(miq_head_addr_w),
    .head_wdata_o(miq_head_wdata_w),
    .head_wstrb_o(miq_head_wstrb_w),
    .count_o(miq_count_w),
    .empty_o(miq_empty_w),
    .full_o(miq_full_w),
    .entry_valid_o(miq_entry_valid_unused_w),
    .entry_kind_o(miq_entry_kind_unused_w),
    .entry_rob_idx_o(miq_entry_rob_unused_w),
    .entry_addr_o(miq_entry_addr_unused_w)
  );

  // 【正确性修复 2026-07-03: rtl-ground-truth §3.1 #2】跨 4KB 页 misaligned plain load/store
  // 精确异常。桥(OooMemAxiBridge)只翻译起始 VA 一次、第二页字节按起始 PA 物理连续读写
  // (OooMemAxiBridge.v:455-456/471/475-476/490); plain 访存 misaligned 又不 trap(下方原门只放 AMO),
  // 分页开启(Sv39)时跨 4KB 页 → 静默读错/写坏相邻物理页。此处对"分页开 + plain LS + misaligned +
  // 跨 4KB 页"抛精确 LOAD/STORE_ADDR_MISALIGN,交软件 trap-and-emulate(cause/tval/请求关断/ROB-commit
  // 上报整链复用 AMO misaligned 机制,一字未改; 页内 misaligned 仍由 byte-window 硬件正常支持不 trap;
  // M 态/satp=Bare(mem_translate_active_i=0)与对齐访存(cross_page=0)全不受影响)。
  wire issue0_plain_ls_w =
      (issue0_is_load_w && !issue0_is_amo_w) || issue0_is_plain_store_w;
  wire issue1_plain_ls_w =
      (issue1_is_load_w && !issue1_is_amo_w) || issue1_is_plain_store_w;
  // nbytes = 1<<size (BYTE/HALF/WORD/DWORD=00/01/10/11 → 1/2/4/8)。
  wire [3:0] issue0_acc_bytes_w =
      4'd1 << issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  wire [3:0] issue1_acc_bytes_w =
      4'd1 << issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  // 跨 4KB 页 ⟺ EA[11:0]+nbytes > 0x1000 (13 位加法容纳 0xFFF+8=0x1007 不截断)。
  // 跨页 ⟹ 必 misaligned(4KB 是任何自然对齐的整数倍); &&misaligned 冗余但作为 cross_page 若误判对齐访存的
  // 安全网(对齐访存 misaligned=0 兜住,防误伤成回归)。
  wire issue0_cross_page_w =
      ({1'b0, issue0_alu_result_w[11:0]} + {9'b0, issue0_acc_bytes_w}) > 13'h1000;
  wire issue1_cross_page_w =
      ({1'b0, issue1_alu_result_w[11:0]} + {9'b0, issue1_acc_bytes_w}) > 13'h1000;
  wire issue0_xpage_misalign_w =
      mem_translate_active_i && issue0_plain_ls_w &&
      issue0_mem_misaligned_w && issue0_cross_page_w;
  wire issue1_xpage_misalign_w =
      mem_translate_active_i && issue1_plain_ls_w &&
      issue1_mem_misaligned_w && issue1_cross_page_w;
  wire issue0_mem_exception_w =
      (issue0_is_amo_w && issue0_mem_misaligned_w) || issue0_xpage_misalign_w;
  wire issue1_mem_exception_w =
      (issue1_is_amo_w && issue1_mem_misaligned_w) || issue1_xpage_misalign_w;
  // MMIO(非 PMEM)load 保守独占: 设备读有副作用, 多在飞会乱设备序。
  wire issue0_mem_mmio_w =
      !((issue0_mem_addr_w & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire issue1_mem_mmio_w =
      !((issue1_mem_addr_w & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire issue_block_w =
      checkpoint_capture_i || checkpoint_quiesce_i;
  // rsp 归属 = MIQ 队头。LEGACY 头沿旧 mem_pending_q 语义; plain 头按 kind 分派。
  wire miq_head_load_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_LOAD);
  wire miq_head_probe_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_PROBE);
  wire miq_head_drain_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_DRAIN);
  wire miq_head_legacy_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_LEGACY);
  // 旧 wants 语义收窄到 LEGACY(AMO/LR/SC/MMIO 独占族)
  wire mem_rsp_wants_w = miq_head_legacy_w && mem_pending_q &&
                         mem_rsp_valid_i && !flush_i;
  // plain LOAD: killed 恒收(静默弃); 活 load 需 wb 槽。PROBE: fault 需 wb 槽,
  // 正常 fill 不占 wb。DRAIN: 恒收(nokill, flush 拍也送达)。
  wire miq_load_rsp_wants_w = miq_head_load_w && mem_rsp_valid_i;
  wire miq_probe_rsp_wants_w = miq_head_probe_w && mem_rsp_valid_i;
  wire miq_drain_rsp_wants_w = miq_head_drain_w && mem_rsp_valid_i;
  wire mem_rsp_fault_w = mem_rsp_error_i || mem_rsp_page_fault_i;
  assign mem_idle_o =
      miq_empty_w && !mem_pending_q && !mem_buffer_valid_q;
  // 【LSQ·SQ 切换】退休侧静默: SQ 排空且无 drain 在飞。AND 进 backend_drained,
  // system/trap/FP 等串行点等它(mem_idle_o 保持原语义, 供分支恢复 quiet 判定)。
  assign mem_retire_quiet_o =
      !sq_mode_w || (sq_empty_w && !drain_inflight_q);
  wire [1:0] wb_free_count_w =
      {1'b0, !ex0_valid_q} + {1'b0, !ex1_valid_q};
  wire wb_slot_free_w = (wb_free_count_w != 2'b00);
  // ready 按队头 kind: LOAD(killed 恒收/活 load 等 wb 槽); PROBE(正常恒收,
  // fault 等 wb 槽); DRAIN 恒收; LEGACY 沿旧(wants && wb 槽)。
  assign mem_rsp_ready_o =
      miq_head_drain_w ? 1'b1 :
      miq_head_load_w ? (miq_head_killed_w || wb_slot_free_w) :
      miq_head_probe_w ? (miq_head_killed_w || wb_slot_free_w) :
      (mem_rsp_wants_w && wb_slot_free_w);
  // LEGACY 消费 fire(旧路径全部沿用此名)
  wire mem_rsp_fire_w = mem_rsp_wants_w && mem_rsp_ready_o;
  // plain 消费 fire
  wire miq_load_rsp_fire_w = miq_load_rsp_wants_w && mem_rsp_ready_o;
  wire miq_probe_rsp_fire_w = miq_probe_rsp_wants_w && mem_rsp_ready_o;
  wire miq_drain_rsp_fire_w = miq_drain_rsp_wants_w;
  // 队头出队: 任一类消费完成。AMO 读阶段(amo_read_rsp)也出队——AMO 写请求
  // 发射时再 push 一个新 LEGACY entry(读/写两事务两 entry, 序天然正确)。
  assign miq_pop_w = mem_rsp_fire_w || miq_load_rsp_fire_w ||
                     miq_probe_rsp_fire_w || miq_drain_rsp_fire_w;
  // AMO#2: 读阶段若 fault(error/page_fault),不得进入写阶段(否则病态 PMP W&!R 下会静默错写 +
  // rd 垃圾 + 无异常)。fault 时 mem_amo_read_rsp_w=0 → 走 mem_rsp_final_fire_w 经 mem_rsp_wb_cause_w
  // 报 LOAD fault(对齐 NEMU "AMO 先 Mr→Load fault"),且不写内存。常态(无 fault)行为不变。
  wire mem_amo_read_rsp_w =
      mem_rsp_fire_w && mem_amo_q && !mem_amo_lr_q && !mem_amo_sc_q &&
      !mem_amo_write_phase_q &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w;
  // LEGACY 单例空闲(AMO/LR/SC 独占通道)
  wire mem_legacy_slot_open_w = !mem_pending_q || mem_rsp_final_fire_w;
  // plain(LOAD/PROBE)发射: MIQ 有空且 LEGACY 空(AMO 在飞时保守不混发,
  // 保持原子窗口语义与旧版一致)。MIQ 同拍 pop 腾位计入。
  wire miq_slot_open_w = mem_legacy_slot_open_w &&
                         (!miq_full_w || miq_pop_w);
  // AMO/LR/SC 独占: MIQ 必须全空(其读-改-写窗口内无任何 plain 在飞)。
  wire mem_amo_slot_open_w = mem_legacy_slot_open_w &&
                             (miq_empty_w || (miq_pop_w &&
                              (miq_count_w == {{MIQ_ENTRY_W{1'b0}}, 1'b1})));
  // 兼容名: 旧引用点按"发射者是否 AMO 族"细分, 在下方逐点替换。
  wire mem_request_slot_open_w = miq_slot_open_w;
  function [ROB_INDEX_W:0] rob_distance_from_head;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_distance_from_head = {1'b0, (idx - head)};
    end
  endfunction

  function rob_idx_older_than;
    input [ROB_INDEX_W-1:0] older_idx;
    input [ROB_INDEX_W-1:0] younger_idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_idx_older_than =
          rob_distance_from_head(older_idx, head) <
          rob_distance_from_head(younger_idx, head);
    end
  endfunction

  wire mem_pending_store_order_block_w =
      mem_pending_q && (mem_store_q || mem_amo_q);
  wire mem_buffer_store_order_block_w =
      mem_buffer_valid_q && mem_buffer_store_q;
  // 【LSQ·歧义消解切片(spec Phase2 前半)】load 对更老在飞 store 的等待从 addr-blind
  //   (任何 store 在飞就等)细化为地址重叠判定: 双方 8B line 距离 ≤1(覆盖任一侧跨线
  //   misaligned 的保守窗口)才等, 不重叠即放行——独立 load 不再被无关 store 卡死。
  //   保守保留 blind 等待的场景: AMO/LR/SC(原子语义)与 MMIO/非 PMEM store(设备顺序),
  //   经 mem_pending_amo/mmio 判定; store→load 同址可见性仍由 dcache 精确 per-store
  //   更新(LSQ Step1)+ 重叠即等待保证, 前递(forwarding)属 Phase2 后半未启用。
  function line_overlap_1;
    input [`XLEN-1:0] la;
    input [`XLEN-1:0] sa;
    reg [`XLEN-4:0] ll;
    reg [`XLEN-4:0] sl;
    begin
      ll = la[`XLEN-1:3];
      sl = sa[`XLEN-1:3];
      line_overlap_1 = (ll == sl) ||
                       (ll + {{(`XLEN-4){1'b0}}, 1'b1} == sl) ||
                       (sl + {{(`XLEN-4){1'b0}}, 1'b1} == ll);
    end
  endfunction
  // 非 PMEM(MMIO)store 保守 blind: 与设备写序相关, 不做重叠放行。
  wire mem_pending_store_mmio_w =
      !((mem_eff_addr_q & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire mem_pending_blind_w =
      mem_pending_q && (mem_amo_q || (mem_store_q && mem_pending_store_mmio_w));
  wire mem_buffer_store_mmio_w =
      !((mem_buffer_eff_addr_q & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  // 【LSQ·SQ 切换】load 对 SQ 中在飞 store(probe 完成、未落存)的等待判定:
  // committed entry 恒视为更老(其 rob_idx 已随退休回收, 不可作环形 age 比较);
  // 未 committed entry 用 rob_idx age(SQ 中可能存在比 load 年轻的 store, 不拦)。
  // 翻译开启时保守 blind(SQ 存 PA、load 只有 VA, VA 别名使 VA 比对不安全);
  // MMIO entry blind(设备访问序); M-mode(VA=PA)用 8B line 重叠精确判定。
  // addr_valid=0 的 entry(probe 未完成)由 IQ older_store_seen + pending/buffer 判定覆盖。
  // issue0/issue1 分两个 always 块: 同块合并会让 Verilator 把"issue1 地址经旁路
  // 依赖 issue0_fire"的单向链误判为组合环(UNOPTFLAT)。
  reg issue0_sq_block_r;
  reg issue1_sq_block_r;
  always @(*) begin : sq_load_block0_blk
    integer k;
    reg [`XLEN-1:0] entry_addr_r;
    reg entry_mmio_r;
    issue0_sq_block_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      entry_addr_r = sq_snoop_addr_w[k*`XLEN +: `XLEN];
      entry_mmio_r =
          ((entry_addr_r & `NPC_AXI_PMEM_MASK) != `NPC_AXI_PMEM_BASE);
      if (sq_snoop_valid_w[k] && sq_snoop_addr_valid_w[k] &&
          (mem_translate_active_i || entry_mmio_r ||
           line_overlap_1(issue0_mem_addr_w, entry_addr_r)) &&
          (sq_snoop_committed_w[k] ||
           rob_idx_older_than(sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W],
                              issue0_rob_idx_w, rob_head_idx_w)))
        issue0_sq_block_r = 1'b1;
    end
  end
  always @(*) begin : sq_load_block1_blk
    integer k;
    reg [`XLEN-1:0] entry_addr_r;
    reg entry_mmio_r;
    issue1_sq_block_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      entry_addr_r = sq_snoop_addr_w[k*`XLEN +: `XLEN];
      entry_mmio_r =
          ((entry_addr_r & `NPC_AXI_PMEM_MASK) != `NPC_AXI_PMEM_BASE);
      if (sq_snoop_valid_w[k] && sq_snoop_addr_valid_w[k] &&
          (mem_translate_active_i || entry_mmio_r ||
           line_overlap_1(issue1_mem_addr_w, entry_addr_r)) &&
          (sq_snoop_committed_w[k] ||
           rob_idx_older_than(sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W],
                              issue1_rob_idx_w, rob_head_idx_w)))
        issue1_sq_block_r = 1'b1;
    end
  end

  // 【LSQ·前递】(spec §3.7) load 命中 SQ"最年轻的更老重叠 entry"且被其全覆盖时
  // 直接取数完成(不访存)。字节语义: entry 覆盖 [eaddr, eaddr+esize)、数据低位
  // 对齐(LSU wstrb=连续 1/wdata 不 shift/内存按 addr 顺序字节), 判定=区间包含
  // (天然支持 misaligned), 数据=entry.data 右移 delta 字节后按 size/unsigned
  // 抽取。禁前递(回落 sq_block 等待): Sv39(VA 别名)/load 或 entry MMIO(设备读
  // 语义)/存在更老 addr 未知 entry(probe 未完成防御)。issue0/issue1 独立块。
  function [3:0] strb_size;
    input [`STRB_W-1:0] strb;
    integer b;
    begin
      strb_size = 4'd0;
      for (b = 0; b < `STRB_W; b = b + 1)
        if (strb[b]) strb_size = strb_size + 4'd1;
    end
  endfunction

  reg issue0_sq_fwd_hit_r;
  reg [`XLEN-1:0] issue0_sq_fwd_raw_r;
  always @(*) begin : sq_fwd0_blk
    integer i;
    reg [SQ_ENTRY_W-1:0] idx_r;
    reg [`XLEN-1:0] laddr_r;
    reg [3:0] lsize_r;
    reg [`XLEN-1:0] eaddr_r;
    reg [3:0] esize_r;
    reg older_r;
    reg overlap_r;
    reg contain_r;
    reg poison_r;
    reg [2:0] delta_r;
    laddr_r = issue0_mem_addr_w;
    lsize_r = strb_size(issue0_mem_wstrb_w);
    eaddr_r = {`XLEN{1'b0}};
    esize_r = 4'd0;
    older_r = 1'b0;
    overlap_r = 1'b0;
    contain_r = 1'b0;
    delta_r = 3'd0;
    idx_r = {SQ_ENTRY_W{1'b0}};
    issue0_sq_fwd_hit_r = 1'b0;
    issue0_sq_fwd_raw_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    for (i = 0; i < SQ_ENTRY_N; i = i + 1) begin
      idx_r = sq_snoop_head_w + i[SQ_ENTRY_W-1:0];
      older_r = sq_snoop_committed_w[idx_r] ||
          rob_idx_older_than(
              sq_snoop_rob_idx_w[idx_r*ROB_INDEX_W +: ROB_INDEX_W],
              issue0_rob_idx_w, rob_head_idx_w);
      if (sq_snoop_valid_w[idx_r] && older_r) begin
        if (!sq_snoop_addr_valid_w[idx_r]) begin
          poison_r = 1'b1;
        end else begin
          eaddr_r = sq_snoop_addr_w[idx_r*`XLEN +: `XLEN];
          esize_r = strb_size(sq_snoop_strb_w[idx_r*`STRB_W +: `STRB_W]);
          overlap_r =
              !((laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <= eaddr_r) ||
                (eaddr_r + {{(`XLEN-4){1'b0}}, esize_r} <= laddr_r));
          if (overlap_r) begin
            // 程序序扫描, 后命中者更年轻——覆盖旧记录=取最年轻的更老重叠
            contain_r =
                (eaddr_r <= laddr_r) &&
                (laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <=
                 eaddr_r + {{(`XLEN-4){1'b0}}, esize_r}) &&
                ((eaddr_r & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
            delta_r = laddr_r[2:0] - eaddr_r[2:0];
            issue0_sq_fwd_hit_r = contain_r;
            issue0_sq_fwd_raw_r =
                sq_snoop_data_w[idx_r*`XLEN +: `XLEN] >> {delta_r, 3'b000};
          end
        end
      end
    end
    if (poison_r || mem_translate_active_i ||
        ((laddr_r & `NPC_AXI_PMEM_MASK) != `NPC_AXI_PMEM_BASE))
      issue0_sq_fwd_hit_r = 1'b0;
  end

  reg issue1_sq_fwd_hit_r;
  reg [`XLEN-1:0] issue1_sq_fwd_raw_r;
  always @(*) begin : sq_fwd1_blk
    integer i;
    reg [SQ_ENTRY_W-1:0] idx_r;
    reg [`XLEN-1:0] laddr_r;
    reg [3:0] lsize_r;
    reg [`XLEN-1:0] eaddr_r;
    reg [3:0] esize_r;
    reg older_r;
    reg overlap_r;
    reg contain_r;
    reg poison_r;
    reg [2:0] delta_r;
    laddr_r = issue1_mem_addr_w;
    lsize_r = strb_size(issue1_mem_wstrb_w);
    eaddr_r = {`XLEN{1'b0}};
    esize_r = 4'd0;
    older_r = 1'b0;
    overlap_r = 1'b0;
    contain_r = 1'b0;
    delta_r = 3'd0;
    idx_r = {SQ_ENTRY_W{1'b0}};
    issue1_sq_fwd_hit_r = 1'b0;
    issue1_sq_fwd_raw_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    for (i = 0; i < SQ_ENTRY_N; i = i + 1) begin
      idx_r = sq_snoop_head_w + i[SQ_ENTRY_W-1:0];
      older_r = sq_snoop_committed_w[idx_r] ||
          rob_idx_older_than(
              sq_snoop_rob_idx_w[idx_r*ROB_INDEX_W +: ROB_INDEX_W],
              issue1_rob_idx_w, rob_head_idx_w);
      if (sq_snoop_valid_w[idx_r] && older_r) begin
        if (!sq_snoop_addr_valid_w[idx_r]) begin
          poison_r = 1'b1;
        end else begin
          eaddr_r = sq_snoop_addr_w[idx_r*`XLEN +: `XLEN];
          esize_r = strb_size(sq_snoop_strb_w[idx_r*`STRB_W +: `STRB_W]);
          overlap_r =
              !((laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <= eaddr_r) ||
                (eaddr_r + {{(`XLEN-4){1'b0}}, esize_r} <= laddr_r));
          if (overlap_r) begin
            contain_r =
                (eaddr_r <= laddr_r) &&
                (laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <=
                 eaddr_r + {{(`XLEN-4){1'b0}}, esize_r}) &&
                ((eaddr_r & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
            delta_r = laddr_r[2:0] - eaddr_r[2:0];
            issue1_sq_fwd_hit_r = contain_r;
            issue1_sq_fwd_raw_r =
                sq_snoop_data_w[idx_r*`XLEN +: `XLEN] >> {delta_r, 3'b000};
          end
        end
      end
    end
    if (poison_r || mem_translate_active_i ||
        ((laddr_r & `NPC_AXI_PMEM_MASK) != `NPC_AXI_PMEM_BASE))
      issue1_sq_fwd_hit_r = 1'b0;
  end

  // FP load 不吃前递: 前递走 ex0 单拍完成路(整数 wb), 无 FP PRF 写/FP 唤醒
  // 通道 → FP 目的悬死。FP load 命中重叠时按序等 SQ drain(慢但正确)。
  wire issue0_sq_fwd_w =
      sq_mode_w && issue0_is_load_w && !issue0_is_amo_w &&
      !issue0_fp_pdest_w &&
      issue0_sq_fwd_hit_r;
  wire issue1_sq_fwd_w =
      sq_mode_w && issue1_is_load_w && !issue1_is_amo_w &&
      !issue1_fp_pdest_w &&
      issue1_sq_fwd_hit_r;

  // 前递数据抽取: 已右移的原始数据作 rdata, 按 load size/unsigned 扩展。
  wire [`XLEN-1:0] issue0_sq_fwd_data_w;
  wire [`XLEN-1:0] issue1_sq_fwd_data_w;
  wire [`XLEN-1:0] fwd0_extract_addr_unused_w;
  wire [`XLEN-1:0] fwd0_extract_wdata_unused_w;
  wire [`XLEN-1:0] fwd1_extract_addr_unused_w;
  wire [`XLEN-1:0] fwd1_extract_wdata_unused_w;
  LSUDataPath u_issue0_fwd_extract (
    .eff_addr_i(issue0_mem_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .byte_shift_i({`XLEN_BIT_SHIFT{1'b0}}),
    .load_size_i(issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .load_unsigned_i(issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i(issue0_sq_fwd_raw_r),
    .mem_addr_o(fwd0_extract_addr_unused_w),
    .mem_wdata_o(fwd0_extract_wdata_unused_w),
    .load_data_o(issue0_sq_fwd_data_w)
  );
  LSUDataPath u_issue1_fwd_extract (
    .eff_addr_i(issue1_mem_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .byte_shift_i({`XLEN_BIT_SHIFT{1'b0}}),
    .load_size_i(issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .load_unsigned_i(issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i(issue1_sq_fwd_raw_r),
    .mem_addr_o(fwd1_extract_addr_unused_w),
    .mem_wdata_o(fwd1_extract_wdata_unused_w),
    .load_data_o(issue1_sq_fwd_data_w)
  );
  // sq_block 不受 rob_head_valid gate: dispatch-bypass 发射的 load 在发射拍自身
  // ROB 记账尚不可见(count=0/hv=0), 旧语义"ROB 空=无在飞 store"被 SQ 打破——
  // SQ 中仍可能有已退休未落存的 committed store(其拦截判定不依赖 head 有效性;
  // 未 committed entry 在 hv=0 拍必然 addr_valid=0, 已被 addr_valid gate 排除)。
  // MIQ 在飞 PROBE = store 地址未知窗口(SQ fill 未达), 更老者拦住 load。
  // PROBE 的 eff_addr 是 VA(发射拍), 翻译开启时不可与 load VA 比对(别名),
  // 保守 blind; M-mode(VA=PA)用 line 重叠精确判。
  reg issue0_miq_probe_block_r;
  reg issue1_miq_probe_block_r;
  integer mpb;
  always @(*) begin : miq_probe_block_blk
    reg older0;
    reg older1;
    reg addr_hit0;
    reg addr_hit1;
    issue0_miq_probe_block_r = 1'b0;
    issue1_miq_probe_block_r = 1'b0;
    for (mpb = 0; mpb < MIQ_ENTRY_N; mpb = mpb + 1) begin
      older0 = 1'b0; older1 = 1'b0; addr_hit0 = 1'b0; addr_hit1 = 1'b0;
      if (miq_entry_valid_unused_w[mpb] &&
          (miq_entry_kind_unused_w[mpb*2 +: 2] == MIQ_KIND_PROBE)) begin
        older0 = rob_idx_older_than(
            miq_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            issue0_rob_idx_w, rob_head_idx_w);
        older1 = rob_idx_older_than(
            miq_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            issue1_rob_idx_w, rob_head_idx_w);
        // 与旧 mem_pending 判定同语义: 翻译开启 blind(entry 存 VA, 别名不安全);
        // M-mode(VA=PA)line 重叠精判。entry addr 用 MIQ eff_addr 快照。
        addr_hit0 = mem_translate_active_i ||
            line_overlap_1(issue0_mem_addr_w,
                           miq_entry_addr_unused_w[mpb*`XLEN +: `XLEN]);
        addr_hit1 = mem_translate_active_i ||
            line_overlap_1(issue1_mem_addr_w,
                           miq_entry_addr_unused_w[mpb*`XLEN +: `XLEN]);
        if (older0 && addr_hit0) issue0_miq_probe_block_r = 1'b1;
        if (older1 && addr_hit1) issue1_miq_probe_block_r = 1'b1;
      end
    end
  end

  wire issue0_load_waits_for_inflight_store_w =
      issue0_is_load_w && !issue0_is_amo_w &&
      ((rob_head_valid_w &&
        ((mem_pending_store_order_block_w &&
          rob_idx_older_than(mem_rob_idx_q, issue0_rob_idx_w, rob_head_idx_w) &&
          (mem_pending_blind_w ||
           line_overlap_1(issue0_mem_addr_w, mem_eff_addr_q))) ||
         (mem_buffer_store_order_block_w &&
          rob_idx_older_than(mem_buffer_rob_idx_q, issue0_rob_idx_w,
                             rob_head_idx_w) &&
          (mem_buffer_store_mmio_w ||
           line_overlap_1(issue0_mem_addr_w, mem_buffer_eff_addr_q))))) ||
       (rob_head_valid_w && issue0_miq_probe_block_r) ||
       (issue0_sq_block_r && !issue0_sq_fwd_w));
  wire issue1_load_waits_for_inflight_store_w =
      issue1_is_load_w && !issue1_is_amo_w &&
      ((rob_head_valid_w &&
        ((mem_pending_store_order_block_w &&
          rob_idx_older_than(mem_rob_idx_q, issue1_rob_idx_w, rob_head_idx_w) &&
          (mem_pending_blind_w ||
           line_overlap_1(issue1_mem_addr_w, mem_eff_addr_q))) ||
         (mem_buffer_store_order_block_w &&
          rob_idx_older_than(mem_buffer_rob_idx_q, issue1_rob_idx_w,
                             rob_head_idx_w) &&
          (mem_buffer_store_mmio_w ||
           line_overlap_1(issue1_mem_addr_w, mem_buffer_eff_addr_q))))) ||
       (rob_head_valid_w && issue1_miq_probe_block_r) ||
       (issue1_sq_block_r && !issue1_sq_fwd_w));
  // 【LSQ·SQ 切换】plain store 不再等 ROB 队头(probe 无副作用可投机发射);
  // AMO/SC(真读改写)仍队头, 且要求 SQ 无 committed 残留(更老 store 已全部落存)。
  wire amo_sq_quiet_w =
      !sq_mode_w || (sq_no_committed_w && !drain_inflight_q);
  // 队头豁免的 SQ 修正: 旧语义"队头=最老=内存序天然安全"被 SQ 打破——store 退休
  // 出 ROB 后仍可能在 SQ 未落存, 队头 load 与它有 RAW, 必须仍受 sq_block 约束
  // (sd 实测: store commit 拍 load 升队头, 豁免发射读到旧值)。
  // 【F2】MMIO load 从"plain load 任意投机发射"臂排除, 归入 ROB 队头独占臂(与
  // AMO 同): 设备读副作用不可撤销, wrong-path 投机发射本身即架构错误——且其
  // LEGACY 在飞事务不受 MIQ killed/walk 保护(mem_pending 只 flush 清), 迟到
  // rsp 会写已被 walk 回收的 preg, 并毒化 difftest 的 MMIO skip 配对
  // (CoreMark 0x2d4c wrong-path lw 案)。旧恒-mispredict 节奏下窗口极窄未显形,
  // 属预存漏洞, F2 免 redirect 后必踩。
  wire issue0_mem_order_ready_w =
      !issue0_is_mem_w ||
      (issue0_is_load_w && !issue0_is_amo_w && !issue0_mem_mmio_w &&
       !issue0_load_waits_for_inflight_store_w) ||
      (sq_mode_w && issue0_is_plain_store_w) ||
      (rob_head_valid_w && (issue0_rob_idx_w == rob_head_idx_w) &&
       !(issue0_is_load_w && !issue0_is_amo_w && issue0_sq_block_r));
  wire issue1_mem_order_ready_w =
      !issue1_is_mem_w ||
      (issue1_is_load_w && !issue1_is_amo_w && !issue1_mem_mmio_w &&
       !issue1_load_waits_for_inflight_store_w) ||
      (sq_mode_w && issue1_is_plain_store_w) ||
      (rob_head_valid_w && (issue1_rob_idx_w == rob_head_idx_w) &&
       !(issue1_is_load_w && !issue1_is_amo_w && issue1_sq_block_r));
  wire issue0_mem_can_fire_w =
      issue0_is_mem_w &&
      !mem_issue_block_w &&
      issue0_mem_order_ready_w &&
      (!issue0_is_amo_w || amo_sq_quiet_w) &&
      (issue0_mem_exception_w ||
       issue0_sq_fwd_w ||
       (!mem_buffer_valid_q && mem_request_slot_open_w &&
        mem_req_ready_i) ||
       (!issue0_is_amo_w && mem_pending_q && !mem_rsp_fire_w &&
        !mem_buffer_valid_q));
  wire issue1_mem_can_fire_w =
      issue1_is_mem_w &&
      !mem_issue_block_w &&
      issue1_mem_order_ready_w &&
      (!issue1_is_amo_w || amo_sq_quiet_w) &&
      // mem1(双发射 load 第二端口)死硅删除:issue1 访存只能走主端口 mem0
      // (仅当 issue0 非访存时),原 dual-load-port1 分支恒不命中,已化简移除。
      (issue1_mem_exception_w ||
       issue1_sq_fwd_w ||
       ((!issue0_is_mem_w || issue0_mem_exception_w) &&
        !mem_buffer_valid_q && mem_request_slot_open_w &&
        mem_req_ready_i));

  // LR/SC 修复:reservation 由前序 LR 的内存响应(晚于 LR issue 数拍)才置位，而 SC 的
  // sc_success 在 issue 当拍组合评估。失败的 SC(sc_success=0)因 issue*_is_mem_w=0 完全
  // 绕过「mem-order-ready=ROB 队头」约束→会先于前序 LR 完成就以失败短路退休，造成
  // 连续 lr;sc 重试活锁(rv64ua-p-lrsc 死循环)。修法:**只把当前评估为失败的 SC** 阻塞到
  // 它成为 ROB 队头且访存空闲——此时前序 LR 已退休并置好 reservation，sc_success 会重评为真，
  // SC 转为正常条件存(is_mem=1 走 mem_can_fire);若 reservation 确实无效则照常以失败退休。
  // 成功的 SC(sc_success=1，premature_w=0)路径不受影响，仍由既有 mem_order_ready 顺序约束。
  wire mem_idle_for_sc_w = !mem_pending_q && !mem_buffer_valid_q;
  wire issue0_sc_premature_w =
      issue0_is_sc_w && !issue0_sc_success_w &&
      !((rob_head_valid_w && (issue0_rob_idx_w == rob_head_idx_w)) &&
        mem_idle_for_sc_w);
  wire issue1_sc_premature_w =
      issue1_is_sc_w && !issue1_sc_success_w &&
      !((rob_head_valid_w && (issue1_rob_idx_w == rob_head_idx_w)) &&
        mem_idle_for_sc_w);

  wire mem_rsp_waiting_for_wb_w =
      mem_rsp_wants_w && !mem_rsp_ready_o;
  wire issue0_is_muldiv_w =
      issue0_valid_w && issue0_ctrl_w[`CTRL_MULDIV_BIT];
  wire issue1_is_muldiv_w =
      issue1_valid_w && issue1_ctrl_w[`CTRL_MULDIV_BIT];
  wire issue0_is_clmul_w =
      issue0_valid_w && issue0_ctrl_w[`CTRL_BITMANIP_BIT] &&
      is_clmul_inst(issue0_inst_w);
  wire issue1_is_clmul_w =
      issue1_valid_w && issue1_ctrl_w[`CTRL_BITMANIP_BIT] &&
      is_clmul_inst(issue1_inst_w);
  wire muldiv_req_valid_w;
  wire muldiv_req_ready_w;
  wire muldiv_resp_valid_w;
  wire muldiv_resp_ready_w;
  wire [ROB_INDEX_W-1:0] muldiv_resp_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] muldiv_resp_pdest_w;
  wire [`XLEN-1:0] muldiv_resp_data_w;
  wire clmul_req_valid_w;
  wire clmul_req_ready_w;
  wire clmul_resp_valid_w;
  wire clmul_resp_ready_w;
  wire [ROB_INDEX_W-1:0] clmul_resp_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] clmul_resp_pdest_w;
  wire [`XLEN-1:0] clmul_resp_data_w;

  assign issue0_ready_w = !flush_i && !issue_block_w &&
                          !issue0_sc_premature_w &&
                          (!issue0_is_mem_w || issue0_mem_can_fire_w) &&
                          (!issue0_is_muldiv_w || muldiv_req_ready_w) &&
                          (!issue0_is_clmul_w || clmul_req_ready_w);
  assign issue1_ready_w = !flush_i && !issue_block_w &&
                          !mem_rsp_waiting_for_wb_w &&
                          !issue1_sc_premature_w &&
                          (!issue1_is_mem_w || issue1_mem_can_fire_w) &&
                          (!issue1_is_muldiv_w ||
                           (muldiv_req_ready_w && !issue0_is_muldiv_w)) &&
                          (!issue1_is_clmul_w ||
                           (clmul_req_ready_w && !issue0_is_clmul_w)) &&
                          (!issue0_is_mem_w || issue0_mem_can_fire_w ||
                           !issue1_is_mem_w);

  wire issue0_fire_w = issue0_valid_w && issue0_ready_w;
  wire issue1_fire_w = issue1_valid_w && issue1_ready_w;
  wire issue0_muldiv_fire_w = issue0_fire_w && issue0_is_muldiv_w;
  wire issue1_muldiv_fire_w = issue1_fire_w && issue1_is_muldiv_w;
  wire issue0_clmul_fire_w = issue0_fire_w && issue0_is_clmul_w;
  wire issue1_clmul_fire_w = issue1_fire_w && issue1_is_clmul_w;
  wire issue0_branch_fire_w = issue0_fire_w && issue0_is_branch_w;
  wire issue1_branch_fire_w = issue1_fire_w && issue1_is_branch_w;

  // ===== B2 片2：后端 branch+JAL+JALR 统一控制流解析（issue 级 per-uop mispredict）=====
  // mode=0 时只解析 BRANCH（JAL/JALR 仍走 pending+drain），下列表达式代数化简后与 branch-only 逐位等价。
  wire mode_walk_w = `OOO_ROB_WALK_MODE;
  wire issue0_is_jal_w  = issue0_valid_w && issue0_ctrl_w[`CTRL_JAL_BIT];
  wire issue0_is_jalr_w = issue0_valid_w && issue0_ctrl_w[`CTRL_JALR_BIT];
  wire issue1_is_jal_w  = issue1_valid_w && issue1_ctrl_w[`CTRL_JAL_BIT];
  wire issue1_is_jalr_w = issue1_valid_w && issue1_ctrl_w[`CTRL_JALR_BIT];
  // 【F2】jal/jalr 恒判(不再挂 mode 条件): pred_npc 单源化后 jal 前后端同算 target
  // 恒免 redirect, ret/jalr-BTB/direct-jal 预测命中免——这些在旧强制项下每条都吃
  // redirect+ROB-walk。
  wire issue0_is_ctrlflow_w =
      issue0_is_branch_w || issue0_is_jal_w || issue0_is_jalr_w;
  wire issue1_is_ctrlflow_w =
      issue1_is_branch_w || issue1_is_jal_w || issue1_is_jalr_w;
  // JALR 目标 = (rs1+imm) & ~1；JAL 目标 = pc+imm(=branch_target)；BRANCH = taken?target:fallthrough。
  wire [`XLEN-1:0] issue0_jalr_target_w =
      (issue0_src1_data_w + issue0_imm_w) & {{(`XLEN-1){1'b1}}, 1'b0};
  wire [`XLEN-1:0] issue1_jalr_target_w =
      (issue1_src1_value_w + issue1_imm_w) & {{(`XLEN-1){1'b1}}, 1'b0};
  wire [`XLEN-1:0] issue0_ctrlflow_next_pc_w =
      issue0_is_jalr_w ? issue0_jalr_target_w :
      issue0_is_jal_w  ? issue0_branch_target_w :
                         issue0_branch_next_pc_w;
  wire [`XLEN-1:0] issue1_ctrlflow_next_pc_w =
      issue1_is_jalr_w ? issue1_jalr_target_w :
      issue1_is_jal_w  ? issue1_branch_target_w :
                         issue1_branch_next_pc_w;
  // 目标对齐异常（IALIGN=16）：JALR 清 bit0 故恒不失配；JAL 看 target[0]；BRANCH taken 看 target[0]。
  wire issue0_ctrlflow_misaligned_w =
      issue0_is_jalr_w ? 1'b0 :
      issue0_is_jal_w  ? issue0_branch_target_w[0] :
                         (issue0_branch_taken_w && issue0_branch_target_w[0]);
  wire issue1_ctrlflow_misaligned_w =
      issue1_is_jalr_w ? 1'b0 :
      issue1_is_jal_w  ? issue1_branch_target_w[0] :
                         (issue1_branch_taken_w && issue1_branch_target_w[0]);
  wire issue0_ctrlflow_fire_w = issue0_fire_w && issue0_is_ctrlflow_w;
  wire issue1_ctrlflow_fire_w = issue1_fire_w && issue1_is_ctrlflow_w;
  // 误预测 = 架构后继 PC ≠ 前端 threaded 的预测后继 PC(pred_npc)，且非对齐异常(misaligned 走 trap)。
  // 【F2 分步落地·当前保留强制项】pred_npc 源已修好(OooFrontend.head_pred_succ_w = 统一 FIFO+bypass 的
  //   head_packet_next_pc_w，寄存/无环/取指时确定)——这是 F2 的必要前置。但仅此不足:去掉 mode_walk_w||
  //   启用真预测后,difftest 定位到 ROB-walk 恢复对**wrong-path squash 有缺陷**(预测-taken 的分支被真
  //   取错路后,mispredict redirect 未能干净 squash 错路指令→wrong-path 提交,如 rv64ui-p-add 的
  //   0x1ac bne)。此缺陷在强制项下从未被锻炼(强制项使前端从不真取预测错路)。故先锁定 pred_npc
  //   foundation、保留强制项,recovery 缺陷用现已可用的 difftest 单独死磕(见 known-issues #105)。
  // domain-A 拆总闸的正确性态: 强制 mispredict(每 ctrlflow redirect+ROB-walk kill)保证
  //   与前端任意取指决策一致(direct fire 的 BHT 重定向被 redirect 覆盖纠正)。F2 叠加
  //   (预测正确免 redirect)需 9946410ef 三件套完整移植(pred_npc BHT 项+DispatchMux 哨兵
  //   可靠性编码), 单独 pred 项会在取指-预测错配边界跑飞(CoreMark boot 1595 条→pc=0),
  //   纯哨兵版在 taken 紧循环退化(IPC 锁 0.53)。见 #105。
  // 【F2 整体落地 2026-07-03】强制项拆除, 真预测启用。pred_npc 已单源化(前端
  //   direct_fire_succ 与 next_fetch 共享同一 wire; dual 双发臂=d1.pc; 顺序臂=
  //   下包 pc0/64'h1 哨兵)——预测正确的控制流免 redirect+ROB-walk。历史 8 轮
  //   单点失败与三障碍的结构解详见 spec ooo-f2-per-packet-pred + known-issues #105。
  wire issue0_mispredict_w =
      (issue0_ctrlflow_next_pc_w != issue0_pred_npc_w) &&
      !issue0_ctrlflow_misaligned_w;
  wire issue1_mispredict_w =
      (issue1_ctrlflow_next_pc_w != issue1_pred_npc_w) &&
      !issue1_ctrlflow_misaligned_w;

  wire issue0_current_result_valid_w =
      issue0_fire_w && !issue0_is_mem_w && !issue0_is_muldiv_w &&
      !issue0_is_clmul_w &&
      (issue0_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  wire issue1_current_result_valid_w =
      issue1_fire_w && !dispatch1_optional_i && !issue1_is_mem_w &&
      !issue1_is_muldiv_w && !issue1_is_clmul_w &&
      (issue1_pdest_w != {PHY_REG_ADDR_W{1'b0}});

  assign muldiv_req_valid_w = issue0_muldiv_fire_w || issue1_muldiv_fire_w;
  wire [ROB_INDEX_W-1:0] muldiv_req_rob_idx_w =
      issue0_muldiv_fire_w ? issue0_rob_idx_w : issue1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] muldiv_req_pdest_w =
      issue0_muldiv_fire_w ? issue0_pdest_w : issue1_pdest_w;
  wire [`INST_W-1:0] muldiv_req_inst_w =
      issue0_muldiv_fire_w ? issue0_inst_w : issue1_inst_w;
  wire [`XLEN-1:0] muldiv_req_src1_w =
      issue0_muldiv_fire_w ? issue0_src1_data_w : issue1_src1_value_w;
  wire [`XLEN-1:0] muldiv_req_src2_w =
      issue0_muldiv_fire_w ? issue0_src2_data_w : issue1_src2_value_w;
  wire muldiv_req_word_w =
      issue0_muldiv_fire_w ? issue0_ctrl_w[`CTRL_WORD_OP_BIT] :
                             issue1_ctrl_w[`CTRL_WORD_OP_BIT];

  OooMulDivUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) u_muldiv_unit (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_i),
    .req_valid_i(muldiv_req_valid_w),
    .req_ready_o(muldiv_req_ready_w),
    .req_rob_idx_i(muldiv_req_rob_idx_w),
    .req_pdest_i(muldiv_req_pdest_w),
    .req_inst_i(muldiv_req_inst_w),
    .req_src1_i(muldiv_req_src1_w),
    .req_src2_i(muldiv_req_src2_w),
    .req_word_i(muldiv_req_word_w),
    .resp_valid_o(muldiv_resp_valid_w),
    .resp_ready_i(muldiv_resp_ready_w),
    .resp_rob_idx_o(muldiv_resp_rob_idx_w),
    .resp_pdest_o(muldiv_resp_pdest_w),
    .resp_data_o(muldiv_resp_data_w)
  );

  assign clmul_req_valid_w = issue0_clmul_fire_w || issue1_clmul_fire_w;
  wire [ROB_INDEX_W-1:0] clmul_req_rob_idx_w =
      issue0_clmul_fire_w ? issue0_rob_idx_w : issue1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] clmul_req_pdest_w =
      issue0_clmul_fire_w ? issue0_pdest_w : issue1_pdest_w;
  wire [1:0] clmul_req_op_w =
      clmul_op_from_funct3(issue0_clmul_fire_w ? issue0_inst_w[14:12] :
                                                  issue1_inst_w[14:12]);
  wire [`XLEN-1:0] clmul_req_src1_w =
      issue0_clmul_fire_w ? issue0_src1_data_w : issue1_src1_value_w;
  wire [`XLEN-1:0] clmul_req_src2_w =
      issue0_clmul_fire_w ? issue0_src2_data_w : issue1_src2_value_w;

  OooClmulUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) u_clmul_unit (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_i),
    .req_valid_i(clmul_req_valid_w),
    .req_ready_o(clmul_req_ready_w),
    .req_rob_idx_i(clmul_req_rob_idx_w),
    .req_pdest_i(clmul_req_pdest_w),
    .req_op_i(clmul_req_op_w),
    .req_src1_i(clmul_req_src1_w),
    .req_src2_i(clmul_req_src2_w),
    .resp_valid_o(clmul_resp_valid_w),
    .resp_ready_i(clmul_resp_ready_w),
    .resp_rob_idx_o(clmul_resp_rob_idx_w),
    .resp_pdest_o(clmul_resp_pdest_w),
    .resp_data_o(clmul_resp_data_w)
  );

  // Wave4b 删除：dispatch 拍分支快解析支撑网（src issue0/1 前递匹配、base/合成 ready、
  // src value、pc/fallthrough/imm/cmp_op、taken/target/next_pc/misaligned/rob_idx）——
  // 唯一 consumer dispatch_branch_fast_resolve_w 已随 candidate（恒 0）死硅摘除。

  // 前递命中的 load 单拍完成(ex 通道), 不发桥请求、不进 buffer、不占 mux。
  wire issue0_mem_request_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      !issue0_sq_fwd_w &&
      mem_request_slot_open_w && mem_req_ready_i && !mem_buffer_valid_q;
  wire issue0_mem_buffer_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_is_amo_w &&
      !issue0_mem_exception_w && !issue0_sq_fwd_w &&
      !issue0_mem_request_fire_w && !mem_buffer_valid_q;
  wire mem_buffer_req_valid_w =
      mem_buffer_valid_q && mem_request_slot_open_w;
  wire mem_buffer_req_fire_w = mem_buffer_req_valid_w && mem_req_ready_i;
  wire issue0_mem_needs_excl_w =
      issue0_is_amo_w || (issue0_is_load_w && issue0_mem_mmio_w);
  wire issue0_mem_req_valid_w =
      issue0_valid_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      // AMO 未 SQ 静默时不得占请求 mux(否则饿死更低优先级的 drain=死锁环)
      (!issue0_is_amo_w || amo_sq_quiet_w) && !issue0_sq_fwd_w &&
      (issue0_mem_needs_excl_w ? mem_amo_slot_open_w
                               : mem_request_slot_open_w) &&
      !mem_buffer_valid_q && !flush_i &&
      !issue_block_w && !mem_issue_block_w && issue0_mem_order_ready_w;
  wire issue1_mem_request_fire_w =
      issue1_fire_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      !issue1_sq_fwd_w &&
      !issue0_is_mem_w && mem_request_slot_open_w && mem_req_ready_i &&
      !mem_buffer_valid_q;
  wire issue1_mem_buffer_fire_w =
      1'b0;
  wire issue1_mem_needs_excl_w =
      issue1_is_amo_w || (issue1_is_load_w && issue1_mem_mmio_w);
  wire issue1_mem_req_valid_w =
      issue1_valid_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      (!issue1_is_amo_w || amo_sq_quiet_w) && !issue1_sq_fwd_w &&
      !issue0_is_mem_w &&
      (issue1_mem_needs_excl_w ? mem_amo_slot_open_w
                               : mem_request_slot_open_w) &&
      !mem_buffer_valid_q &&
      !flush_i && !issue_block_w && !mem_issue_block_w &&
      issue1_mem_order_ready_w;
  wire issue0_mem_req_write_w =
      issue0_is_store_w && (!issue0_is_amo_w || issue0_is_sc_w);
  wire issue1_mem_req_write_w =
      issue1_is_store_w && (!issue1_is_amo_w || issue1_is_sc_w);
  wire mem_amo_write_req_valid_w =
      mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
      !mem_amo_write_sent_q && !flush_i;

  // 【LSQ·SQ 切换】SQ drain 落存请求源(最低优先级): 队头 committed entry 就绪、
  // 无 drain 在飞、且当拍无更高优先级请求竞争时占用桥 slot(pretrans+nokill 写必达)。
  // rsp 归属互斥: 复用 slot_open(pending 的 rsp 同拍完成消费或本就空)+ buffer 空。
  // FP pending 直写与 drain 互斥由 backend_drained(含 mem_retire_quiet)保证。
  wire sq_drain_req_valid_w =
      sq_mode_w && sq_drain_valid_w && !drain_inflight_q &&
      mem_request_slot_open_w && !mem_buffer_valid_q &&
      !mem_amo_write_req_valid_w &&
      !issue0_mem_req_valid_w && !issue1_mem_req_valid_w;
  wire sq_drain_req_fire_w = sq_drain_req_valid_w && mem_req_ready_i;

  assign mem_req_valid_o = mem_amo_write_req_valid_w ||
                           mem_buffer_req_valid_w || issue0_mem_req_valid_w ||
                           issue1_mem_req_valid_w || sq_drain_req_valid_w;
  assign mem_req_write_o = mem_amo_write_req_valid_w ? 1'b1 :
                           mem_buffer_req_valid_w ? mem_buffer_store_q :
                           issue0_mem_req_valid_w ? issue0_mem_req_write_w :
                           issue1_mem_req_valid_w ? issue1_mem_req_write_w :
                                                    1'b1;
  assign mem_req_addr_o = mem_amo_write_req_valid_w ?
                          mem_eff_addr_q :
                          mem_buffer_req_valid_w ? mem_buffer_eff_addr_q :
                          issue0_mem_req_valid_w ? issue0_mem_addr_w :
                          issue1_mem_req_valid_w ? issue1_mem_addr_w :
                                                   sq_drain_addr_w;
  assign mem_req_wdata_o = mem_amo_write_req_valid_w ? mem_amo_write_data_q :
                           mem_buffer_req_valid_w ? mem_buffer_wdata_q :
                           issue0_mem_req_valid_w ? issue0_mem_wdata_w :
                           issue1_mem_req_valid_w ? issue1_mem_wdata_w :
                                                    sq_drain_data_w;
  assign mem_req_wstrb_o = mem_amo_write_req_valid_w ? mem_amo_write_wstrb_q :
                           mem_buffer_req_valid_w ? mem_buffer_wstrb_q :
                           issue0_mem_req_valid_w ? issue0_mem_wstrb_w :
                           issue1_mem_req_valid_w ? issue1_mem_wstrb_w :
                                                    sq_drain_strb_w;
  // 事务属性: probe 只标 plain store 的发射请求; drain 请求 pretrans+nokill。
  assign mem_req_probe_o =
      mem_amo_write_req_valid_w ? 1'b0 :
      mem_buffer_req_valid_w ? (sq_mode_w && mem_buffer_store_q) :
      issue0_mem_req_valid_w ? (sq_mode_w && issue0_is_plain_store_w) :
      issue1_mem_req_valid_w ? (sq_mode_w && issue1_is_plain_store_w) :
      1'b0;
  assign mem_req_pretrans_o = sq_drain_req_valid_w;
  assign mem_req_nokill_o = sq_drain_req_valid_w;

  // ============ MIQ push(与桥 req fire 同拍, 优先级与 req mux 一致) ============
  wire mem_req_fire_any_w = mem_req_valid_o && mem_req_ready_i;
  wire push_amo_write_w = mem_amo_write_req_valid_w && mem_req_ready_i;
  wire push_buffer_w = mem_buffer_req_fire_w;
  wire push_issue0_w = issue0_mem_request_fire_w;
  wire push_issue1_w = issue1_mem_request_fire_w;
  wire push_drain_w = sq_drain_req_fire_w;
  assign miq_push_valid_w = mem_req_fire_any_w;
  // kind: AMO 写阶段/AMO 族发射=LEGACY; drain=DRAIN; plain store(probe)=PROBE;
  // plain load=LOAD。buffer 只存 plain。
  wire issue0_is_excl_kind_w = issue0_is_amo_w ||
                               (issue0_is_load_w && issue0_mem_mmio_w);
  wire issue1_is_excl_kind_w = issue1_is_amo_w ||
                               (issue1_is_load_w && issue1_mem_mmio_w);
  assign miq_push_kind_w =
      push_amo_write_w ? MIQ_KIND_LEGACY :
      push_buffer_w ? (mem_buffer_store_q ? MIQ_KIND_PROBE : MIQ_KIND_LOAD) :
      push_issue0_w ? (issue0_is_excl_kind_w ? MIQ_KIND_LEGACY :
                       issue0_is_plain_store_w ? MIQ_KIND_PROBE :
                                                 MIQ_KIND_LOAD) :
      push_issue1_w ? (issue1_is_excl_kind_w ? MIQ_KIND_LEGACY :
                       issue1_is_plain_store_w ? MIQ_KIND_PROBE :
                                                 MIQ_KIND_LOAD) :
                      MIQ_KIND_DRAIN;
  assign miq_push_rob_w =
      push_amo_write_w ? mem_rob_idx_q :
      push_buffer_w ? mem_buffer_rob_idx_q :
      push_issue0_w ? issue0_rob_idx_w :
      push_issue1_w ? issue1_rob_idx_w : {ROB_INDEX_W{1'b0}};
  assign miq_push_pdest_w =
      push_amo_write_w ? mem_pdest_q :
      push_buffer_w ? mem_buffer_pdest_q :
      push_issue0_w ? issue0_pdest_w :
      push_issue1_w ? issue1_pdest_w : {PHY_REG_ADDR_W{1'b0}};
  assign miq_push_pdest_fp_w =
      push_amo_write_w ? mem_pdest_fp_q :
      push_buffer_w ? mem_buffer_pdest_fp_q :
      push_issue0_w ? issue0_fp_pdest_w :
      push_issue1_w ? issue1_fp_pdest_w : 1'b0;
  assign miq_push_size_w =
      push_amo_write_w ? mem_size_q :
      push_buffer_w ? mem_buffer_size_q :
      push_issue0_w ? issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] :
      push_issue1_w ? issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] :
                      2'b00;
  assign miq_push_unsigned_w =
      push_amo_write_w ? mem_unsigned_q :
      push_buffer_w ? mem_buffer_unsigned_q :
      push_issue0_w ? issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT] :
      push_issue1_w ? issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT] : 1'b0;
  assign miq_push_addr_w = mem_req_addr_o;
  assign miq_push_wdata_w = mem_req_wdata_o;
  assign miq_push_wstrb_w = mem_req_wstrb_o;
  reg ex0_valid_q;
  reg [ROB_INDEX_W-1:0] ex0_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] ex0_pdest_q;
  reg [`XLEN-1:0] ex0_result_q;
  reg ex0_exception_q;
  reg [`TRAP_CAUSE_W-1:0] ex0_cause_q;
  reg [`XLEN-1:0] ex0_tval_q;
  reg ex1_valid_q;
  reg [ROB_INDEX_W-1:0] ex1_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] ex1_pdest_q;
  reg [`XLEN-1:0] ex1_result_q;
  reg ex1_exception_q;
  reg [`TRAP_CAUSE_W-1:0] ex1_cause_q;
  reg [`XLEN-1:0] ex1_tval_q;

  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_i) begin
      mem_pending_q <= 1'b0;
      mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_pdest_fp_q <= 1'b0;
      mem_load_q <= 1'b0;
      mem_store_q <= 1'b0;
      mem_amo_q <= 1'b0;
      mem_amo_lr_q <= 1'b0;
      mem_amo_sc_q <= 1'b0;
      mem_amo_write_phase_q <= 1'b0;
      mem_amo_write_sent_q <= 1'b0;
      mem_eff_addr_q <= {`XLEN{1'b0}};
      mem_size_q <= 2'b00;
      mem_unsigned_q <= 1'b0;
      mem_amo_inst_q <= {`INST_W{1'b0}};
      mem_amo_src2_q <= {`XLEN{1'b0}};
      mem_amo_old_value_q <= {`XLEN{1'b0}};
      mem_amo_write_data_q <= {`XLEN{1'b0}};
      mem_amo_write_wstrb_q <= {`STRB_W{1'b0}};
      mem_probe_q <= 1'b0;
      mem_store_wdata_q <= {`XLEN{1'b0}};
      mem_store_wstrb_q <= {`STRB_W{1'b0}};
      mem_buffer_valid_q <= 1'b0;
      mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_buffer_pdest_fp_q <= 1'b0;
      mem_buffer_load_q <= 1'b0;
      mem_buffer_store_q <= 1'b0;
      mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
      mem_buffer_size_q <= 2'b00;
      mem_buffer_unsigned_q <= 1'b0;
      mem_buffer_wdata_q <= {`XLEN{1'b0}};
      mem_buffer_wstrb_q <= {`STRB_W{1'b0}};
      reservation_valid_q <= 1'b0;
      reservation_addr_q <= {`XLEN{1'b0}};
      ex0_valid_q <= 1'b0;
      ex0_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      ex0_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      ex0_result_q <= {`XLEN{1'b0}};
      ex0_exception_q <= 1'b0;
      ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      ex0_tval_q <= {`XLEN{1'b0}};
      ex1_valid_q <= 1'b0;
      ex1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      ex1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      ex1_result_q <= {`XLEN{1'b0}};
      ex1_exception_q <= 1'b0;
      ex1_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      ex1_tval_q <= {`XLEN{1'b0}};
    end else begin
      if (mem_amo_read_rsp_w) begin
        mem_amo_write_phase_q <= 1'b1;
        mem_amo_write_sent_q <= 1'b0;
        mem_amo_old_value_q <= mem_amo_old_value_w;
        mem_amo_write_data_q <= mem_amo_write_wdata_w;
        mem_amo_write_wstrb_q <= mem_amo_write_wstrb_w;
      end else if (mem_rsp_final_fire_w) begin
        if (mem_amo_lr_q && !mem_rsp_error_i) begin
          reservation_valid_q <= 1'b1;
          reservation_addr_q <= (mem_size_q == `MEM_SIZE_WORD) ?
              (mem_eff_addr_q & {{(`XLEN-2){1'b1}}, 2'b00}) :
              (mem_eff_addr_q & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}});
        end else if (mem_amo_sc_q) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_pending_q <= 1'b0;
        mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_load_q <= 1'b0;
        mem_store_q <= 1'b0;
        mem_amo_q <= 1'b0;
        mem_amo_lr_q <= 1'b0;
        mem_amo_sc_q <= 1'b0;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= {`XLEN{1'b0}};
        mem_size_q <= 2'b00;
        mem_unsigned_q <= 1'b0;
        mem_amo_inst_q <= {`INST_W{1'b0}};
        mem_amo_src2_q <= {`XLEN{1'b0}};
        mem_amo_old_value_q <= {`XLEN{1'b0}};
        mem_amo_write_data_q <= {`XLEN{1'b0}};
        mem_amo_write_wstrb_q <= {`STRB_W{1'b0}};
        mem_probe_q <= 1'b0;
      end
      if (mem_buffer_req_fire_w) begin
        if (mem_buffer_store_q) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_buffer_valid_q <= 1'b0;
        mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_buffer_load_q <= 1'b0;
        mem_buffer_store_q <= 1'b0;
        mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
        mem_buffer_size_q <= 2'b00;
        mem_buffer_unsigned_q <= 1'b0;
        mem_buffer_wdata_q <= {`XLEN{1'b0}};
        mem_buffer_wstrb_q <= {`STRB_W{1'b0}};
      end
      if (mem_amo_write_req_valid_w && mem_req_ready_i) begin
        mem_amo_write_sent_q <= 1'b1;
        reservation_valid_q <= 1'b0;
        reservation_addr_q <= {`XLEN{1'b0}};
      end
      if ((issue0_fire_w && issue0_is_sc_w && !issue0_sc_success_w) ||
          (issue1_fire_w && issue1_is_sc_w && !issue1_sc_success_w)) begin
        reservation_valid_q <= 1'b0;
        reservation_addr_q <= {`XLEN{1'b0}};
      end
      if (issue0_mem_request_fire_w) begin
        if (issue0_mem_req_write_w && !issue0_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
      end
      // 单例(LEGACY)只承载 AMO/LR/SC/MMIO-load 独占族; plain 状态在 MIQ。
      if (issue0_mem_request_fire_w && issue0_is_excl_kind_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue0_rob_idx_w;
        mem_pdest_q <= issue0_pdest_w;
        mem_pdest_fp_q <= issue0_fp_pdest_w;
        mem_load_q <= issue0_is_load_w || issue0_is_lr_w ||
                      (issue0_is_amo_w && !issue0_is_sc_w);
        mem_store_q <= issue0_mem_req_write_w;
        mem_amo_q <= issue0_is_amo_w;
        mem_amo_lr_q <= issue0_is_lr_w;
        mem_amo_sc_q <= issue0_is_sc_w;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= issue0_alu_result_w;
        mem_size_q <= issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT] ||
                          (issue0_is_amo_w &&
                           (issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] ==
                            `MEM_SIZE_DWORD));
        mem_amo_inst_q <= issue0_inst_w;
        mem_amo_src2_q <= issue0_src2_data_w;
        mem_probe_q <= sq_mode_w && issue0_is_plain_store_w;
        mem_store_wdata_q <= issue0_mem_wdata_w;
        mem_store_wstrb_q <= issue0_mem_wstrb_w;
      end
      if (issue1_mem_request_fire_w) begin
        if (issue1_mem_req_write_w && !issue1_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
      end
      if (issue1_mem_request_fire_w && issue1_is_excl_kind_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue1_rob_idx_w;
        mem_pdest_q <= issue1_pdest_w;
        mem_pdest_fp_q <= issue1_fp_pdest_w;
        mem_load_q <= issue1_is_load_w || issue1_is_lr_w ||
                      (issue1_is_amo_w && !issue1_is_sc_w);
        mem_store_q <= issue1_mem_req_write_w;
        mem_amo_q <= issue1_is_amo_w;
        mem_amo_lr_q <= issue1_is_lr_w;
        mem_amo_sc_q <= issue1_is_sc_w;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= issue1_alu_result_w;
        mem_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT] ||
                          (issue1_is_amo_w &&
                           (issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] ==
                            `MEM_SIZE_DWORD));
        mem_amo_inst_q <= issue1_inst_w;
        mem_amo_src2_q <= issue1_src2_value_w;
        mem_probe_q <= sq_mode_w && issue1_is_plain_store_w;
        mem_store_wdata_q <= issue1_mem_wdata_w;
        mem_store_wstrb_q <= issue1_mem_wstrb_w;
      end
      // buffer 迁移的 plain 事务状态在 MIQ, 不再写单例(LEGACY 只承载
      // AMO/LR/SC/MMIO-load 独占族)。
      if (issue0_mem_buffer_fire_w) begin
        if (issue0_is_store_w && !issue0_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= issue0_rob_idx_w;
        mem_buffer_pdest_q <= issue0_pdest_w;
        mem_buffer_pdest_fp_q <= issue0_fp_pdest_w;
        mem_buffer_load_q <= issue0_is_load_w;
        mem_buffer_store_q <= issue0_is_store_w;
        mem_buffer_eff_addr_q <= issue0_alu_result_w;
        mem_buffer_size_q <= issue0_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <= issue0_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue0_mem_wdata_w;
        mem_buffer_wstrb_q <= issue0_mem_wstrb_w;
      end
      if (issue1_mem_buffer_fire_w) begin
        if (issue1_is_store_w && !issue1_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= issue1_rob_idx_w;
        mem_buffer_pdest_q <= issue1_pdest_w;
        mem_buffer_pdest_fp_q <= issue1_fp_pdest_w;
        mem_buffer_load_q <= issue1_is_load_w;
        mem_buffer_store_q <= issue1_is_store_w;
        mem_buffer_eff_addr_q <= issue1_alu_result_w;
        mem_buffer_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue1_mem_wdata_w;
        mem_buffer_wstrb_q <= issue1_mem_wstrb_w;
      end

      ex0_valid_q <= issue0_fire_w && !issue0_is_muldiv_w &&
                     !issue0_is_clmul_w &&
                     (!issue0_is_mem_w || issue0_mem_exception_w ||
                      issue0_sq_fwd_w);
      if (issue0_fire_w && issue0_sq_fwd_w) begin
        // 【LSQ·前递】load 命中 SQ 全覆盖 entry, 单拍完成(不访存)。
        ex0_rob_idx_q <= issue0_rob_idx_w;
        ex0_pdest_q <= issue0_pdest_w;
        ex0_result_q <= issue0_sq_fwd_data_w;
        ex0_exception_q <= 1'b0;
        ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex0_tval_q <= {`XLEN{1'b0}};
      end else if (issue0_fire_w && !issue0_is_mem_w && !issue0_is_muldiv_w &&
          !issue0_is_clmul_w) begin
        ex0_rob_idx_q <= issue0_rob_idx_w;
        ex0_pdest_q <= issue0_pdest_w;
        ex0_result_q <= (issue0_is_sc_w && !issue0_sc_success_w) ?
                        {{(`XLEN-1){1'b0}}, 1'b1} : issue0_wb_data_w;
        ex0_exception_q <= 1'b0;
        ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex0_tval_q <= {`XLEN{1'b0}};
      end else if (issue0_fire_w && issue0_mem_exception_w) begin
        ex0_rob_idx_q <= issue0_rob_idx_w;
        ex0_pdest_q <= issue0_pdest_w;
        ex0_result_q <= {`XLEN{1'b0}};
        ex0_exception_q <= 1'b1;
        // AMO/SC 非对齐报 Store/AMO,但 LR 非对齐报 Load(NEMU 金标:funct5==LR→LOAD_MISALIGN)。
        ex0_cause_q <= ((issue0_is_load_w && !issue0_is_amo_w) || issue0_is_lr_w) ?
                       `EXC_LOAD_ADDR_MISALIGN :
                       `EXC_STORE_ADDR_MISALIGN;
        ex0_tval_q <= issue0_alu_result_w;
      end else begin
        ex0_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        ex0_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        ex0_result_q <= {`XLEN{1'b0}};
        ex0_exception_q <= 1'b0;
        ex0_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex0_tval_q <= {`XLEN{1'b0}};
      end

      ex1_valid_q <= issue1_fire_w && !issue1_is_muldiv_w &&
                     !issue1_is_clmul_w &&
                     (!issue1_is_mem_w || issue1_mem_exception_w ||
                      issue1_sq_fwd_w);
      if (issue1_fire_w && !issue1_is_muldiv_w && !issue1_is_clmul_w) begin
        ex1_rob_idx_q <= issue1_rob_idx_w;
        ex1_pdest_q <= issue1_pdest_w;
        ex1_result_q <= issue1_sq_fwd_w ? issue1_sq_fwd_data_w :
                        issue1_mem_exception_w ? {`XLEN{1'b0}} :
                        ((issue1_is_sc_w && !issue1_sc_success_w) ?
                         {{(`XLEN-1){1'b0}}, 1'b1} : issue1_wb_data_w);
        ex1_exception_q <= issue1_mem_exception_w;
        ex1_cause_q <= issue1_mem_exception_w ?
                       (((issue1_is_load_w && !issue1_is_amo_w) || issue1_is_lr_w) ?
                        `EXC_LOAD_ADDR_MISALIGN :
                        `EXC_STORE_ADDR_MISALIGN) :
                       {`TRAP_CAUSE_W{1'b0}};
        ex1_tval_q <= issue1_mem_exception_w ? issue1_alu_result_w :
                                                {`XLEN{1'b0}};
      end else begin
        ex1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        ex1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        ex1_result_q <= {`XLEN{1'b0}};
        ex1_exception_q <= 1'b0;
        ex1_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        ex1_tval_q <= {`XLEN{1'b0}};
      end
    end
  end

  // mem 侧 wb 事务: LEGACY 完成(旧 final_fire) + plain LOAD(活) +
  // PROBE fault(store 翻译失败→精确异常)。killed 事务不 wb。
  wire miq_load_wb_fire_w = miq_load_rsp_fire_w && !miq_head_killed_w;
  // PROBE 无论成败都要 wb 一次: 正常=标 ROB done(rd_en=0), fault=精确异常。
  wire miq_probe_wb_fire_w = miq_probe_rsp_fire_w && !miq_head_killed_w;
  wire mem_wb_fire_w = mem_rsp_final_fire_w || miq_load_wb_fire_w ||
                       miq_probe_wb_fire_w;
  wire mem_rsp_to_wb0_w = mem_wb_fire_w && !ex0_valid_q;
  wire mem_rsp_to_wb1_w = mem_wb_fire_w && !mem_rsp_to_wb0_w;
  // mem1(双发射 load 第二端口)死硅删除:第二 load 响应通道(mem1_rsp_to_wb*)整条移除。
  wire muldiv_rsp_to_wb0_w =
      muldiv_resp_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w;
  wire muldiv_rsp_to_wb1_w =
      muldiv_resp_valid_w && !muldiv_rsp_to_wb0_w && !ex1_valid_q &&
      !mem_rsp_to_wb1_w;
  wire clmul_rsp_to_wb0_w =
      clmul_resp_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w &&
      !muldiv_rsp_to_wb0_w;
  wire clmul_rsp_to_wb1_w =
      clmul_resp_valid_w && !clmul_rsp_to_wb0_w && !ex1_valid_q &&
      !mem_rsp_to_wb1_w && !muldiv_rsp_to_wb1_w;
  // 【B-FP 簇】FP 完成事务(ROB done 载体)第五源, 最低优先, ready 反压回 FpBackend。
  wire fpwb_to_wb0_w =
      fpwb_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w &&
      !muldiv_rsp_to_wb0_w && !clmul_rsp_to_wb0_w;
  wire fpwb_to_wb1_w =
      fpwb_valid_w && !fpwb_to_wb0_w && !ex1_valid_q && !mem_rsp_to_wb1_w &&
      !muldiv_rsp_to_wb1_w && !clmul_rsp_to_wb1_w;
  assign fpwb_ready_w = fpwb_to_wb0_w || fpwb_to_wb1_w;
  // 【B-FP 簇】FP load: NaN-box(FLW 高 32 全 1)后进 ROB data(commit 写架构 FPR)
  // 与 fpld_wb(写 FP 物理堆+FP 唤醒); int PRF 写与 int 唤醒按 fp gate(pdest 置 0)。
  // wb 事务是否 load 语义(plain LOAD 恒是; LEGACY 按单例)
  wire mem_wb_is_load_w = miq_load_wb_fire_w ||
                          (mem_rsp_final_fire_w && mem_load_q);
  wire mem_rsp_fp_load_w = miq_head_pdest_fp_w && mem_wb_is_load_w;
  wire [`XLEN-1:0] mem_rsp_fp_boxed_w =
      (miq_head_size_w == `MEM_SIZE_DWORD) ? mem_rsp_load_data_w :
      {32'hffff_ffff, mem_rsp_load_data_w[31:0]};
  wire [`XLEN-1:0] mem_rsp_wb_data_w =
      miq_probe_wb_fire_w ? {`XLEN{1'b0}} :
      (mem_rsp_final_fire_w && mem_amo_q) ?
                  (mem_amo_sc_q ? {`XLEN{1'b0}} :
                   (mem_amo_write_phase_q ? mem_amo_old_value_q :
                                            mem_amo_old_value_w)) :
      mem_rsp_fp_load_w ? mem_rsp_fp_boxed_w :
      mem_wb_is_load_w ? mem_rsp_load_data_w : {`XLEN{1'b0}};
  // store 语义(fault cause 用): PROBE(plain store 探测)或 LEGACY store/AMO 写臂
  wire mem_wb_store_cause_w =
      miq_probe_wb_fire_w ||
      (mem_rsp_final_fire_w &&
       (mem_store_q || (mem_amo_q && (mem_amo_sc_q || mem_amo_write_phase_q))));
  wire [`TRAP_CAUSE_W-1:0] mem_rsp_wb_cause_w =
      mem_rsp_page_fault_i ?
      (mem_wb_store_cause_w ? `EXC_STORE_PAGE_FAULT : `EXC_LOAD_PAGE_FAULT) :
      (mem_wb_store_cause_w ? `EXC_STORE_ACCESS_FAULT : `EXC_LOAD_ACCESS_FAULT);

  assign muldiv_resp_ready_w = muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w;
  assign clmul_resp_ready_w = clmul_rsp_to_wb0_w || clmul_rsp_to_wb1_w;

  assign wb0_valid_w =
      ex0_valid_q || mem_rsp_to_wb0_w ||
      muldiv_rsp_to_wb0_w || clmul_rsp_to_wb0_w || fpwb_to_wb0_w;
  assign wb0_rob_idx_w = ex0_valid_q ? ex0_rob_idx_q :
                         mem_rsp_to_wb0_w ? miq_head_rob_w :
                         muldiv_rsp_to_wb0_w ? muldiv_resp_rob_idx_w :
                         clmul_rsp_to_wb0_w ? clmul_resp_rob_idx_w :
                                              fpwb_rob_idx_w;
  assign wb0_pdest_w = ex0_valid_q ? ex0_pdest_q :
                       mem_rsp_to_wb0_w ? ((miq_head_pdest_fp_w ||
                                            miq_probe_wb_fire_w) ?
                                           {PHY_REG_ADDR_W{1'b0}} :
                                           miq_head_pdest_w) :
                       muldiv_rsp_to_wb0_w ? muldiv_resp_pdest_w :
                       clmul_rsp_to_wb0_w ? clmul_resp_pdest_w :
                       (fpwb_rd_en_w ? fpwb_pdest_w
                                     : {PHY_REG_ADDR_W{1'b0}});
  assign wb0_data_w = ex0_valid_q ? ex0_result_q :
                      mem_rsp_to_wb0_w ? mem_rsp_wb_data_w :
                      muldiv_rsp_to_wb0_w ? muldiv_resp_data_w :
                      clmul_rsp_to_wb0_w ? clmul_resp_data_w :
                                           fpwb_data_w;
  assign wb0_exception_w = ex0_valid_q ? ex0_exception_q :
                           mem_rsp_to_wb0_w ?
                             (miq_probe_wb_fire_w ? mem_rsp_fault_w
                                                  : mem_rsp_error_i) :
                                               1'b0;
  assign wb0_cause_w = ex0_valid_q ? ex0_cause_q :
                       mem_rsp_to_wb0_w ? mem_rsp_wb_cause_w :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb0_tval_w = ex0_valid_q ? ex0_tval_q :
                      mem_rsp_to_wb0_w ? miq_head_addr_w :
                                          {`XLEN{1'b0}};
  assign wb0_fflags_w = fpwb_to_wb0_w ? fpwb_fflags_w : 5'b00000;
  assign wb1_fflags_w = fpwb_to_wb1_w ? fpwb_fflags_w : 5'b00000;
  assign wb1_valid_w =
      ex1_valid_q || mem_rsp_to_wb1_w ||
      muldiv_rsp_to_wb1_w || clmul_rsp_to_wb1_w || fpwb_to_wb1_w;
  assign wb1_rob_idx_w = ex1_valid_q ? ex1_rob_idx_q :
                         mem_rsp_to_wb1_w ? miq_head_rob_w :
                         muldiv_rsp_to_wb1_w ? muldiv_resp_rob_idx_w :
                         clmul_rsp_to_wb1_w ? clmul_resp_rob_idx_w :
                                              fpwb_rob_idx_w;
  assign wb1_pdest_w = ex1_valid_q ? ex1_pdest_q :
                       mem_rsp_to_wb1_w ? ((miq_head_pdest_fp_w ||
                                            miq_probe_wb_fire_w) ?
                                           {PHY_REG_ADDR_W{1'b0}} :
                                           miq_head_pdest_w) :
                       muldiv_rsp_to_wb1_w ? muldiv_resp_pdest_w :
                       clmul_rsp_to_wb1_w ? clmul_resp_pdest_w :
                       (fpwb_rd_en_w ? fpwb_pdest_w
                                     : {PHY_REG_ADDR_W{1'b0}});
  assign wb1_data_w = ex1_valid_q ? ex1_result_q :
                      mem_rsp_to_wb1_w ? mem_rsp_wb_data_w :
                      muldiv_rsp_to_wb1_w ? muldiv_resp_data_w :
                      clmul_rsp_to_wb1_w ? clmul_resp_data_w :
                                           fpwb_data_w;
  assign wb1_exception_w = ex1_valid_q ? ex1_exception_q :
                           mem_rsp_to_wb1_w ?
                             (miq_probe_wb_fire_w ? mem_rsp_fault_w
                                                  : mem_rsp_error_i) :
                                               1'b0;
  assign wb1_cause_w = ex1_valid_q ? ex1_cause_q :
                       mem_rsp_to_wb1_w ? mem_rsp_wb_cause_w :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb1_tval_w = ex1_valid_q ? ex1_tval_q :
                      mem_rsp_to_wb1_w ? miq_head_addr_w :
                                          {`XLEN{1'b0}};

  assign execute0_valid_o = wb0_valid_w;
  assign execute1_valid_o = wb1_valid_w;
  // Wave4b: issue0/1_fast_branch_suppressed_w 恒 0（FAST_BRANCH_TRACK 死硅已摘，
  // fast_branch_valid_q 永不置位）→ issue-resolve emit 直通 ctrlflow_fire（活 F2 路径，
  // 行为与化简前逐拍等价）。
  wire issue0_resolve_emit_w = issue0_ctrlflow_fire_w;
  wire issue1_resolve_emit_w = issue1_ctrlflow_fire_w;
  wire issue0_redirect_w = issue0_resolve_emit_w && issue0_mispredict_w;
  wire issue1_redirect_w = issue1_resolve_emit_w && issue1_mispredict_w;
  // lane 选择：mode=1 取最老 mispredict（issue0 优先）；mode=0 退化为原 issue0-first（中性）。
  wire branch_resolve_pick1_w =
      mode_walk_w ? (!issue0_redirect_w && issue1_redirect_w)
                  : (!issue0_resolve_emit_w);

  assign branch_resolve_valid_o =
      issue0_resolve_emit_w || issue1_resolve_emit_w;
  assign branch_resolve_pc_o =
      branch_resolve_pick1_w ? issue1_pc_w : issue0_pc_w;
  assign branch_resolve_next_pc_o =
      branch_resolve_pick1_w ? issue1_ctrlflow_next_pc_w
                             : issue0_ctrlflow_next_pc_w;
  assign branch_resolve_misaligned_o =
      branch_resolve_pick1_w ? issue1_ctrlflow_misaligned_w
                             : issue0_ctrlflow_misaligned_w;
  // B2：解析控制流的 rob_idx，与 branch_resolve_pc/next_pc 同源选 issue0/issue1。
  assign branch_resolve_rob_idx_o =
      branch_resolve_pick1_w ? issue1_rob_idx_w : issue0_rob_idx_w;
  // 【F2】BPU 回训随行(与 pick1 同源): is_branch gate 掉 jal/jalr(方向表只训条件分支);
  // taken 用 compare 真值, bht_idx/pred_taken 为 dispatch 拍 thread 进 IQ 的查询快照。
  assign branch_resolve_is_branch_o =
      branch_resolve_pick1_w ? issue1_is_branch_w : issue0_is_branch_w;
  assign branch_resolve_taken_o =
      branch_resolve_pick1_w ? issue1_branch_taken_w : issue0_branch_taken_w;
  assign branch_resolve_pred_taken_o =
      branch_resolve_pick1_w ? issue1_pred_taken_w : issue0_pred_taken_w;
  assign branch_resolve_bht_idx_o =
      branch_resolve_pick1_w ? issue1_bht_idx_w : issue0_bht_idx_w;
  // 片2 计算、片4 接线导出：被选中 lane 的 mispredict 脉冲（mode=1 驱动 ROB-walk kill + redirect）。
  wire branch_resolve_mispredict_w =
      branch_resolve_pick1_w ? issue1_redirect_w : issue0_redirect_w;
`ifdef DBRA_PROBE
  always @(posedge clk) begin
    if (branch_resolve_valid_o)
      $display("[BRP ] pc=%h next=%h mis=%b rob=%h",
               branch_resolve_pc_o, branch_resolve_next_pc_o,
               branch_resolve_mispredict_w, branch_resolve_rob_idx_o);
  end
`endif
  assign branch_resolve_mispredict_o = branch_resolve_mispredict_w;
  // Wave4b: dispatch 拍分支快解析族已物理删除；输出恒 0 tie-off。跨模块消费者
  // (OooDirectBranchResolveGate 的 dispatch 臂、OooCommitOutputMux 的 synth-append) 在
  // domain-A 下本就只见 0，保持既有 0 语义，行为中性。
  assign dispatch_branch_resolve_valid_o = 1'b0;
  assign dispatch_branch_resolve_pc_o = {`XLEN{1'b0}};
  assign dispatch_branch_resolve_next_pc_o = {`XLEN{1'b0}};
  assign dispatch_branch_resolve_misaligned_o = 1'b0;

  // dispatch backend 的 load_branch_fast_* 输出族已物理删除（IQ 死硅摘除）；
  // 仅存 pending_branch_fast_* 输入（另一未删死硅族）悬空，reduction-OR 收口。
  wire unused_pending_branch_fast_w =
      pending_branch_fast_valid_i |
      (|pending_branch_fast_pc_i);

  wire unused_issue_payload_w =
      (|issue0_inst_w) | (|issue1_inst_w) |
      (|issue0_mem_load_unused_w) | (|issue1_mem_load_unused_w) |
      mem_store_q | mem_rsp_to_wb0_w |
      (|mem_rsp_addr_unused_w) | (|mem_rsp_wdata_unused_w) |
      (|mem_rsp_wstrb_unused_w) | mem_rsp_misaligned_unused_w |
      // Wave4b: dispatch0_src2 preg/ready 原仅喂 dispatch 拍分支快解析（已删）→ reduction-OR 收口。
      (|dispatch0_src2_preg_w) | dispatch0_src2_ready_w;

`ifdef ROB_WALK_DEBUG
  always @(posedge clk) begin
    if (!rst && branch_resolve_valid_o)
      $display("[CF] mispred=%b pick1=%b | i0 emit=%b jalr=%b jal=%b br=%b rob=%0d pc=%h next=%h s1p=%0d s1v=%h imm=%h | i1 emit=%b jalr=%b rob=%0d pc=%h next=%h",
               branch_resolve_mispredict_w, branch_resolve_pick1_w,
               issue0_resolve_emit_w, issue0_is_jalr_w, issue0_is_jal_w, issue0_is_branch_w, issue0_rob_idx_w, issue0_pc_w, issue0_ctrlflow_next_pc_w, issue0_src1_preg_w, issue0_src1_data_w, issue0_imm_w,
               issue1_resolve_emit_w, issue1_is_jalr_w, issue1_rob_idx_w, issue1_pc_w, issue1_ctrlflow_next_pc_w);
  end
`endif


  // ===========================================================================
  // 【B-FP 簇】FP 后端一体实例(spec ooo-fp-cluster §7): rename/IQ/物理堆/执行簇/
  // 完成 FIFO。FP load 写回=mem rsp 分流(box 后), FP store 数据=发射拍 R3 读。
  // ===========================================================================
  wire fpld_wb_valid_w = mem_wb_fire_w && mem_rsp_fp_load_w &&
                         !mem_rsp_error_i && !mem_rsp_page_fault_i;

  OooFpBackend #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_fp_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .frm_i(frm_i),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .recover_active_i(rob_recover_active_w),
    .walk0_fp_valid_i(walk0_fp_valid_w),
    .walk0_arch_i(walk0_fp_arch_w),
    .walk0_old_pdest_i(walk0_fp_old_w),
    .walk0_new_pdest_i(walk0_fp_new_w),
    .walk1_fp_valid_i(walk1_fp_valid_w),
    .walk1_arch_i(walk1_fp_arch_w),
    .walk1_old_pdest_i(walk1_fp_old_w),
    .walk1_new_pdest_i(walk1_fp_new_w),
    .disp_valid_i(dispatch0_valid_i && d0_fp_arith_w &&
                  dispatch0_dbe_ready_w),
    .disp_ready_o(fp_disp_ready_w),
    .disp_rob_idx_i(dispatch0_rob_idx_w),
    .disp_inst_i(dispatch0_inst_i),
    .disp_double_i(dispatch0_fp_double_i),
    .disp_frd_en_i(!dispatch0_fp_gpr_write_i),
    .disp_frd_arch_i(dispatch0_inst_i[11:7]),
    .disp_dst_gpr_i(dispatch0_fp_gpr_write_i),
    .disp_gpr_pdest_i(dispatch0_pdest_w),
    .disp_fs1_en_i(dispatch0_fp_fs1_en_i),
    .disp_fs1_arch_i(dispatch0_inst_i[19:15]),
    .disp_fs2_en_i(dispatch0_fp_fs2_en_i),
    .disp_fs2_arch_i(dispatch0_inst_i[24:20]),
    .disp_fs3_en_i(dispatch0_fp_fs3_en_i),
    .disp_fs3_arch_i(dispatch0_inst_i[31:27]),
    .disp_gpr_src_en_i(dispatch0_fp_gpr_src_i),
    .disp_gpr_src_preg_i(dispatch0_src1_preg_w),
    .disp_gpr_src_ready_i(dispatch0_src1_ready_w),
    .disp_frd_new_pdest_o(fp_disp_new_pdest_w),
    .disp_frd_old_pdest_o(fp_disp_old_pdest_w),
    .disp1_valid_i(dispatch1_valid_i && d1_fp_arith_w &&
                   dispatch1_dbe_ready_w),
    .disp1_ready_o(fp_disp1_ready_w),
    .disp1_rob_idx_i(dispatch1_rob_idx_w),
    .disp1_inst_i(dispatch1_inst_i),
    .disp1_double_i(dispatch1_fp_double_i),
    .disp1_frd_en_i(!dispatch1_fp_gpr_write_i),
    .disp1_frd_arch_i(dispatch1_inst_i[11:7]),
    .disp1_dst_gpr_i(dispatch1_fp_gpr_write_i),
    .disp1_gpr_pdest_i(dispatch1_new_pdest_probe_w),
    .disp1_fs1_en_i(dispatch1_fp_fs1_en_i),
    .disp1_fs1_arch_i(dispatch1_inst_i[19:15]),
    .disp1_fs2_en_i(dispatch1_fp_fs2_en_i),
    .disp1_fs2_arch_i(dispatch1_inst_i[24:20]),
    .disp1_fs3_en_i(dispatch1_fp_fs3_en_i),
    .disp1_fs3_arch_i(dispatch1_inst_i[31:27]),
    .disp1_gpr_src_en_i(dispatch1_fp_gpr_src_i),
    .disp1_gpr_src_preg_i(dispatch1_src1_preg_w),
    .disp1_gpr_src_ready_i(dispatch1_src1_ready_w),
    .disp1_frd_new_pdest_o(fp_disp1_new_pdest_w),
    .disp1_frd_old_pdest_o(fp_disp1_old_pdest_w),
    .fpld0_alloc_valid_i(dispatch0_valid_i && dispatch0_is_fp_i &&
                         dispatch0_fp_load_i && dispatch0_dbe_ready_w),
    .fpld0_alloc_arch_i(dispatch0_inst_i[11:7]),
    .fpld0_new_pdest_o(fpld0_new_pdest_w),
    .fpld0_old_pdest_o(fpld0_old_pdest_w),
    .fpld1_alloc_valid_i(dispatch1_valid_i && dispatch1_is_fp_i &&
                         dispatch1_fp_load_i && dispatch1_dbe_ready_w),
    .fpld1_alloc_arch_i(dispatch1_inst_i[11:7]),
    .fpld1_new_pdest_o(fpld1_new_pdest_w),
    .fpld1_old_pdest_o(fpld1_old_pdest_w),
    .fp_alloc0_ready_o(fp_alloc0_ready_w),
    .fp_alloc1_ready_o(fp_alloc1_ready_w),
    .fpst0_query_arch_i(dispatch0_inst_i[24:20]),
    .fpst0_query_preg_o(fpst0_query_preg_w),
    .fpst0_query_ready_o(fpst0_query_ready_w),
    .fpst1_query_arch_i(dispatch1_inst_i[24:20]),
    .fpst1_query_preg_o(fpst1_query_preg_w),
    .fpst1_query_ready_o(fpst1_query_ready_w),
    .fp_wake0_valid_o(fp_wake0_valid_w),
    .fp_wake0_preg_o(fp_wake0_preg_w),
    .fp_wake1_valid_o(fp_wake1_valid_w),
    .fp_wake1_preg_o(fp_wake1_preg_w),
    .fpst_read_preg_i(fpst_read_preg_w),
    .fpst_read_data_o(fpst_read_data_w),
    .fpld_wb_valid_i(fpld_wb_valid_w),
    .fpld_wb_pdest_i(miq_head_pdest_w),
    .fpld_wb_data_i(mem_rsp_fp_boxed_w),
    .fpld_wb_double_i(1'b1),
    .int_wake0_valid_i(wb0_valid_w),
    .int_wake0_preg_i(wb0_pdest_w),
    .int_wake1_valid_i(wb1_valid_w),
    .int_wake1_preg_i(wb1_pdest_w),
    .gpr_read_addr_o(fp_gpr_read_addr_w),
    .gpr_read_data_i(fp_gpr_read_data_w),
    .fpwb_valid_o(fpwb_valid_w),
    .fpwb_rob_idx_o(fpwb_rob_idx_w),
    .fpwb_pdest_o(fpwb_pdest_w),
    .fpwb_rd_en_o(fpwb_rd_en_w),
    .fpwb_data_o(fpwb_data_w),
    .fpwb_fflags_o(fpwb_fflags_w),
    .fpwb_ready_i(fpwb_ready_w),
    .commit0_fp_valid_i(commit0_valid_o && commit0_is_fp_rd_w &&
                        !commit0_exception_o),
    .commit0_fp_arch_i(commit0_arch_rd_o),
    .commit0_fp_data_i(commit0_data_o),
    .commit0_fp_old_pdest_i(commit0_old_pdest_o),
    .commit1_fp_valid_i(commit1_valid_o && commit1_is_fp_rd_w &&
                        !commit1_exception_o),
    .commit1_fp_arch_i(commit1_arch_rd_o),
    .commit1_fp_data_i(commit1_data_o),
    .commit1_fp_old_pdest_i(commit1_old_pdest_o)
  );


  // ===========================================================================
  // 【LSQ·SQ 接线】(spec ooo-lsq-implementation-plan.md §3.4/§3.6)
  // mode=1(切换): dispatch alloc(满则经 DispatchBackend 反压)/ probe rsp 拍回填
  //   PA+寄存 data / ROB 退休标记(exception commit 不标)/ kill·trap squash /
  //   队头 committed entry 经 drain 请求(pretrans+nokill)落存, rsp 释放。
  // mode=0(影子): 发射拍回填 VA、退休标记、drain 即时释放(不落存), 行为零变化,
  //   [SQSHADOW-FAIL] 断言对拍守恒。
  // store 判定含 FP store(FSW/FSD opcode 0100111)——FP store 同走 SQ 生命周期
  wire sq_d0_store_w =
      dispatch0_fire_w && ((dispatch0_inst_i[6:0] == 7'b0100011) ||
       ((dispatch0_inst_i[6:0] == 7'b0100111) &&
        ((dispatch0_inst_i[14:12] == 3'b010) || (dispatch0_inst_i[14:12] == 3'b011))));
  wire sq_d1_store_w =
      dispatch1_fire_w && ((dispatch1_inst_i[6:0] == 7'b0100011) ||
       ((dispatch1_inst_i[6:0] == 7'b0100111) &&
        ((dispatch1_inst_i[14:12] == 3'b010) || (dispatch1_inst_i[14:12] == 3'b011))));
  wire sq_alloc0_valid_w = sq_d0_store_w || sq_d1_store_w;
  wire [ROB_INDEX_W-1:0] sq_alloc0_rob_w =
      sq_d0_store_w ? dispatch0_rob_idx_w : dispatch1_rob_idx_w;
  wire sq_alloc1_valid_w = sq_d0_store_w && sq_d1_store_w;

  // 回填: mode=1 在 probe rsp 拍(PA=rsp_rdata + 发射拍寄存的 data/strb);
  // mode=0 影子在发射拍(VA; req 直入/req lane1/buffer 暂存三路同拍互斥)。
  // AMO/SC/FP-store 未 alloc, CAM miss 自然忽略。
  wire sq_fill_probe_w =
      miq_probe_rsp_fire_w && !miq_head_killed_w &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire shadow_fill_req0_w = issue0_mem_request_fire_w && issue0_is_store_w;
  wire shadow_fill_req1_w = issue1_mem_request_fire_w && issue1_is_store_w;
  wire shadow_fill_buf0_w = issue0_mem_buffer_fire_w && issue0_is_store_w;
  wire shadow_fill_valid_w =
      shadow_fill_req0_w || shadow_fill_req1_w || shadow_fill_buf0_w;
  wire [ROB_INDEX_W-1:0] shadow_fill_rob_w =
      shadow_fill_req1_w ? issue1_rob_idx_w : issue0_rob_idx_w;
  wire [`XLEN-1:0] shadow_fill_addr_w =
      shadow_fill_req1_w ? issue1_alu_result_w : issue0_alu_result_w;
  wire [`XLEN-1:0] shadow_fill_data_w =
      shadow_fill_req1_w ? issue1_mem_wdata_w : issue0_mem_wdata_w;
  wire [`STRB_W-1:0] shadow_fill_strb_w =
      shadow_fill_req1_w ? issue1_mem_wstrb_w : issue0_mem_wstrb_w;
  wire sq_fill_valid_w =
      sq_mode_w ? sq_fill_probe_w : shadow_fill_valid_w;
  wire [ROB_INDEX_W-1:0] sq_fill_rob_w =
      sq_mode_w ? miq_head_rob_w : shadow_fill_rob_w;
  wire [`XLEN-1:0] sq_fill_addr_w =
      sq_mode_w ? mem_rsp_rdata_i : shadow_fill_addr_w;
  wire [`XLEN-1:0] sq_fill_data_w =
      sq_mode_w ? miq_head_wdata_w : shadow_fill_data_w;
  wire [`STRB_W-1:0] sq_fill_strb_w =
      sq_mode_w ? miq_head_wstrb_w : shadow_fill_strb_w;

  // ROB 退休标记(commit0=ROB head, commit1=head+1; 位宽自然回卷)。
  // exception commit 不标: fault store 不得进 committed 流(随 trap flush_all
  // 清除), 否则会被 drain 落存 = 假异常副作用。
  wire sq_mark0_valid_w =
      commit0_valid_o && ((commit0_inst_o[6:0] == 7'b0100011) ||
       ((commit0_inst_o[6:0] == 7'b0100111) &&
        ((commit0_inst_o[14:12] == 3'b010) || (commit0_inst_o[14:12] == 3'b011)))) &&
      !commit0_exception_o;
  wire [ROB_INDEX_W-1:0] sq_mark0_rob_w = rob_head_idx_w;
  wire sq_mark1_valid_w =
      commit1_valid_o && ((commit1_inst_o[6:0] == 7'b0100011) ||
       ((commit1_inst_o[6:0] == 7'b0100111) &&
        ((commit1_inst_o[14:12] == 3'b010) || (commit1_inst_o[14:12] == 3'b011)))) &&
      !commit1_exception_o;
  wire [ROB_INDEX_W-1:0] sq_mark1_rob_w =
      rob_head_idx_w + {{(ROB_INDEX_W-1){1'b0}}, 1'b1};

  // squash: flush_i=全局(trap/checkpoint)全清; mispredict=boundary 清(ROB-walk
  // kill 同源, 严格更年轻者被 squash)
  wire sq_flush_valid_w = flush_i || branch_resolve_mispredict_w;

  // drain 完成(落存 rsp, nokill 事务 flush 拍也送达)→ 释放 SQ entry。
  // 多在飞下 rsp 归属=MIQ 队头(旧 drain_inflight&&rsp_valid 会误吃他人 rsp)。
  wire sq_drain_rsp_fire_w = miq_drain_rsp_fire_w;
  wire sq_drain_fire_w = sq_mode_w ? sq_drain_rsp_fire_w : 1'b1;

  always @(posedge clk) begin
    if (rst) begin
      drain_inflight_q <= 1'b0;
    end else if (sq_drain_req_fire_w) begin
      drain_inflight_q <= 1'b1;
    end else if (sq_drain_rsp_fire_w) begin
      drain_inflight_q <= 1'b0;
    end
  end

  OooStoreQueue #(
    .ENTRY_COUNT_W(SQ_ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) u_store_queue (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(sq_flush_valid_w),
    .flush_all_i(flush_i),
    .flush_rob_head_i(rob_head_idx_w),
    .flush_boundary_rob_i(branch_resolve_rob_idx_o),
    .alloc0_valid_i(sq_alloc0_valid_w),
    .alloc0_ready_o(sq_alloc0_ready_w),
    .alloc0_rob_idx_i(sq_alloc0_rob_w),
    .alloc1_valid_i(sq_alloc1_valid_w),
    .alloc1_ready_o(sq_alloc1_ready_w),
    .alloc1_rob_idx_i(dispatch1_rob_idx_w),
    .fill0_valid_i(sq_fill_valid_w),
    .fill0_rob_idx_i(sq_fill_rob_w),
    .fill0_addr_i(sq_fill_addr_w),
    .fill0_data_i(sq_fill_data_w),
    .fill0_strb_i(sq_fill_strb_w),
    .fill1_valid_i(1'b0),
    .fill1_rob_idx_i({ROB_INDEX_W{1'b0}}),
    .fill1_addr_i({`XLEN{1'b0}}),
    .fill1_data_i({`XLEN{1'b0}}),
    .fill1_strb_i({`STRB_W{1'b0}}),
    .mark0_valid_i(sq_mark0_valid_w),
    .mark0_rob_idx_i(sq_mark0_rob_w),
    .mark1_valid_i(sq_mark1_valid_w),
    .mark1_rob_idx_i(sq_mark1_rob_w),
    .drain_valid_o(sq_drain_valid_w),
    .drain_addr_o(sq_drain_addr_w),
    .drain_data_o(sq_drain_data_w),
    .drain_strb_o(sq_drain_strb_w),
    .drain_fire_i(sq_drain_fire_w),
    .snoop_valid_o(sq_snoop_valid_w),
    .snoop_addr_valid_o(sq_snoop_addr_valid_w),
    .snoop_addr_o(sq_snoop_addr_w),
    .snoop_data_o(sq_snoop_data_w),
    .snoop_strb_o(sq_snoop_strb_w),
    .snoop_rob_idx_o(sq_snoop_rob_idx_w),
    .snoop_committed_o(sq_snoop_committed_w),
    .snoop_head_o(sq_snoop_head_w),
    .count_o(sq_count_w)
  );

  // 对拍断言(外部 CAM 查 snoop 面): 退休的 store 必在 SQ 且已回填(mode=1 下
  // "已回填"=probe 必须先于退休完成, 由 ROB done 前提保证); alloc 永不溢出
  // (mode=1 下由 DispatchBackend 反压保证, 触发=反压逻辑 bug)。
  reg sq_mark0_hit_r;
  reg sq_mark0_filled_r;
  reg sq_mark1_hit_r;
  reg sq_mark1_filled_r;
  always @(*) begin : sq_mark_cam_blk
    integer k;
    sq_mark0_hit_r = 1'b0;
    sq_mark0_filled_r = 1'b0;
    sq_mark1_hit_r = 1'b0;
    sq_mark1_filled_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      if (sq_snoop_valid_w[k] &&
          (sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W] ==
           sq_mark0_rob_w)) begin
        sq_mark0_hit_r = 1'b1;
        sq_mark0_filled_r = sq_snoop_addr_valid_w[k];
      end
      if (sq_snoop_valid_w[k] &&
          (sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W] ==
           sq_mark1_rob_w)) begin
        sq_mark1_hit_r = 1'b1;
        sq_mark1_filled_r = sq_snoop_addr_valid_w[k];
      end
    end
  end



  reg [7:0] sq_fail_count_q;
  always @(posedge clk) begin
    if (rst) begin
      sq_fail_count_q <= 8'd0;
    end else if (sq_fail_count_q < 8'd32) begin
      if (sq_alloc0_valid_w && !sq_alloc0_ready_w) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] alloc0 overflow rob=%0d count=%0d",
                 sq_alloc0_rob_w, sq_count_w);
      end
      if (sq_alloc1_valid_w && !sq_alloc1_ready_w) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] alloc1 overflow rob=%0d count=%0d",
                 dispatch1_rob_idx_w, sq_count_w);
      end
      if (sq_mark0_valid_w && !sq_mark0_hit_r) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] commit0 store not in SQ rob=%0d pc=0x%h",
                 sq_mark0_rob_w, commit0_pc_o);
      end
      if (sq_mark0_valid_w && sq_mark0_hit_r &&
          !sq_mark0_filled_r &&
          !(sq_fill_valid_w && (sq_fill_rob_w == sq_mark0_rob_w))) begin
        // probe rsp 与同拍 commit(ROB wb-to-commit 旁路)时 fill 时序写尚不可见,
        // 本拍 fill 命中同 rob 即视为已回填(非错误)。
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] commit0 store unfilled rob=%0d pc=0x%h",
                 sq_mark0_rob_w, commit0_pc_o);
      end
      if (sq_mark1_valid_w && !sq_mark1_hit_r) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] commit1 store not in SQ rob=%0d pc=0x%h",
                 sq_mark1_rob_w, commit1_pc_o);
      end
      if (sq_mark1_valid_w && sq_mark1_hit_r &&
          !sq_mark1_filled_r &&
          !(sq_fill_valid_w && (sq_fill_rob_w == sq_mark1_rob_w))) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] commit1 store unfilled rob=%0d pc=0x%h",
                 sq_mark1_rob_w, commit1_pc_o);
      end
      // drain 落存 error(退休后无法精确 trap): 只警告计数——known-limitation,
      // PMP/翻译 fault 已在 probe 拍前置, 残余=未映射地址/SLVERR(测试集不触及)。
      if (sq_drain_rsp_fire_w && mem_rsp_error_i) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQ-DRAIN-ERROR] retired store bus error addr=0x%h",
                 sq_drain_addr_w);
      end
    end
  end

  assign commit0_is_fp_rd_o = commit0_is_fp_rd_w;
  assign commit1_is_fp_rd_o = commit1_is_fp_rd_w;

endmodule
