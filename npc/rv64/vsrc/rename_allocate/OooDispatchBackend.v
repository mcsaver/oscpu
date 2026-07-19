`include "define.v"

// 先把 OoO dispatch/rename 后端边界串成一个可验证闭环：
// rename/free-list/ROB/busy-table/issue-queue 在这里按 2-wide 程序序协同，
// 后续执行单元只需要消费 issue 端口并通过 writeback 端口唤醒与完成 ROB。
/* verilator lint_off UNOPTFLAT */
// F2 predict_taken→lane1 fire→IQ/alloc ready 的跨实例保守判环族。
module OooDispatchBackend #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input clk,
  input rst,
  input flush_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,   // T3N：已寄存 coherent resolve packet 的 rob_idx
  input branch_mispredict_valid_i,          // T3N：已寄存 coherent resolve packet 的 mispredict valid
  input issue_mem_block_i,
  // Registered downstream occupancy of the physical Universal terminal.
  // Kept separate from memory dispatch blocking and combinational ready.
  input universal_owner_present_i,
  // 【LSQ·SQ 切换】SQ 空闲槽(由 SQ count_q 时序生成, 无跨层组合环): store dispatch
  // 需要 SQ slot, 满则反压。
  input sq_alloc0_ready_i,
  input sq_alloc1_ready_i,

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
  // 【B-FP Phase0 地基】FPR 目的标记透传(接 0=行为中性)
  input dispatch0_is_fp_rd_i,
  // 【B-FP 簇】FP uop 协作: is_fp=不进整数 IQ; fp_pdest/old=FP rename 侧的
  // 目的(is_fp_rd 时替换 ROB old/new 与 IQ pdest); fp_st_src=FP store 数据源
  // (进 IQ fp_src2, 监听 FP wakeup)。
  input dispatch0_is_fp_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_fp_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_fp_old_pdest_i,
  input dispatch0_fp_st_src_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_fp_st_src_preg_i,
  input dispatch0_fp_st_src_ready_i,
  input [`XLEN-1:0] dispatch0_imm_i,
  // 【F2】BPU 查询快照随行(thread 进 IQ, issue 侧导出供 resolve 回训)
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,

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
  input dispatch1_is_fp_rd_i,
  input dispatch1_is_fp_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fp_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fp_old_pdest_i,
  input dispatch1_fp_st_src_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fp_st_src_preg_i,
  input dispatch1_fp_st_src_ready_i,
  input [`XLEN-1:0] dispatch1_imm_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,

  input wb0_valid_i,
  input [ROB_INDEX_W-1:0] wb0_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] wb0_pdest_i,
  input [`XLEN-1:0] wb0_data_i,
  input wb0_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb0_cause_i,
  input [`XLEN-1:0] wb0_tval_i,
  input [4:0] wb0_fflags_i,

  input wb1_valid_i,
  input [ROB_INDEX_W-1:0] wb1_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] wb1_pdest_i,
  input [`XLEN-1:0] wb1_data_i,
  input wb1_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb1_cause_i,
  input [`XLEN-1:0] wb1_tval_i,
  input [4:0] wb1_fflags_i,

  // v8f EX-stage exact completion query.  ProducerId is carried by the EX
  // stage; OooRob returns a Q-only current/open decision used before any WB
  // side effect.  Mismatch is consumed-and-dropped by the caller.
  input completion0_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion0_query_producer_id_i,
  output completion0_query_match_o,
  input completion1_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion1_query_producer_id_i,
  output completion1_query_match_o,

  // R3.2 actual-fire lookahead wake.  These pulses update only IQ sticky
  // readiness; formal WB remains the sole BusyTable/PRF completion source.
  input early_wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] early_wakeup0_pdest_i,
  input early_wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] early_wakeup1_pdest_i,

  // 【B-FP 簇】FP wakeup(整数 IQ 的 fp_src2 监听) + FP walk 分流输出
  input fp_wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake0_preg_i,
  input fp_wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake1_preg_i,
  output walk0_fp_valid_o,
  output [`REG_ADDR_W-1:0] walk0_fp_arch_o,
  output [PHY_REG_ADDR_W-1:0] walk0_fp_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk0_fp_new_pdest_o,
  output walk1_fp_valid_o,
  output [`REG_ADDR_W-1:0] walk1_fp_arch_o,
  output [PHY_REG_ADDR_W-1:0] walk1_fp_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk1_fp_new_pdest_o,

  output issue0_valid_o,
  input issue0_ready_i,
  output [`XLEN-1:0] issue0_pc_o,
  output [`XLEN-1:0] issue0_next_pc_o,
  output [`XLEN-1:0] issue0_pred_npc_o,
  output [`INST_W-1:0] issue0_inst_o,
  output [`CTRL_BUS_W-1:0] issue0_ctrl_o,
  output [ROB_INDEX_W-1:0] issue0_rob_idx_o,
  output [PRODUCER_ID_W-1:0] issue0_producer_id_o,
  output issue0_producer_current_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_pdest_o,
  output issue0_fixed_gpr_producer_o,
  output issue0_fp_pdest_o,
  output issue0_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue0_fp_st_src_preg_o,
  output [`XLEN-1:0] issue0_imm_o,
  output [`BPU_BHT_INDEX_W-1:0] issue0_bht_idx_o,
  output issue0_pred_taken_o,
  output issue_pair_swapped_o,

  output issue1_valid_o,
  input issue1_ready_i,
  output [`XLEN-1:0] issue1_pc_o,
  output [`XLEN-1:0] issue1_next_pc_o,
  output [`XLEN-1:0] issue1_pred_npc_o,
  output [`INST_W-1:0] issue1_inst_o,
  output [`CTRL_BUS_W-1:0] issue1_ctrl_o,
  output [ROB_INDEX_W-1:0] issue1_rob_idx_o,
  output [PRODUCER_ID_W-1:0] issue1_producer_id_o,
  output issue1_producer_current_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_pdest_o,
  output issue1_fixed_gpr_producer_o,
  output issue1_fp_pdest_o,
  output issue1_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue1_fp_st_src_preg_o,
  output [`XLEN-1:0] issue1_imm_o,
  output [`BPU_BHT_INDEX_W-1:0] issue1_bht_idx_o,
  output issue1_pred_taken_o,

  output dispatch0_fire_o,
  output [ROB_INDEX_W-1:0] dispatch0_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] dispatch0_pdest_o,
  output [PHY_REG_ADDR_W-1:0] dispatch1_pdest_o,
  output [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_o,
  output dispatch0_src1_ready_o,
  output [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_o,
  output dispatch0_src2_ready_o,
  output dispatch1_fire_o,
  output [ROB_INDEX_W-1:0] dispatch1_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_o,
  output dispatch1_src1_ready_o,
  output [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_o,
  output dispatch1_src2_ready_o,

  input commit_ready_i,
  input commit1_block_i,
  input mem_quiet_i,   // 【serialize Phase1 §9】mem 静默(=mem_idle&&mem_retire_quiet), 门控 head0-CSR 退休
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output commit0_is_fp_rd_o,
  output [4:0] commit0_fflags_o,
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
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [ROB_INDEX_W-1:0] rob_head_idx_o,
  output rob_head_valid_o,
  output rob_recover_active_o,
  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,

  // S2-Q2 v8a：末级 wrapper 只把 permit/facts 映射到 canonical ROB。
  input head0_context_permit_i,
  input fencei_retire_permit_i,
  output head0_retire_candidate_valid_o,
  output head0_identity_valid_o,
  output [`OOO_CONTEXT_ID_W-1:0] head0_identity_o
);

  // 【B-FP 簇】FP 算术(非 mem)不进整数 IQ(在 FP IQ); FP mem 正常进(mem 通道)。
  wire dispatch0_fp_arith_w = dispatch0_is_fp_i &&
                              !dispatch0_ctrl_i[`CTRL_LOAD_BIT] &&
                              !dispatch0_ctrl_i[`CTRL_STORE_BIT];
  wire dispatch1_fp_arith_w = dispatch1_is_fp_i &&
                              !dispatch1_ctrl_i[`CTRL_LOAD_BIT] &&
                              !dispatch1_ctrl_i[`CTRL_STORE_BIT];
  wire dispatch0_uses_rs1_w = dispatch0_ctrl_i[`CTRL_RS1_EN_BIT];
  wire dispatch0_uses_rs2_w = dispatch0_ctrl_i[`CTRL_RS2_EN_BIT];
  wire dispatch0_writes_rd_w = dispatch0_ctrl_i[`CTRL_RD_EN_BIT] &&
                               (dispatch0_rd_arch_i != {`REG_ADDR_W{1'b0}});
  wire dispatch1_uses_rs1_w = dispatch1_ctrl_i[`CTRL_RS1_EN_BIT];
  wire dispatch1_uses_rs2_w = dispatch1_ctrl_i[`CTRL_RS2_EN_BIT];
  wire dispatch1_writes_rd_w = dispatch1_ctrl_i[`CTRL_RD_EN_BIT] &&
                               (dispatch1_rd_arch_i != {`REG_ADDR_W{1'b0}});

  wire rob_dispatch0_ready_w;
  wire rob_dispatch1_ready_w;
  wire [ROB_INDEX_W-1:0] rob_dispatch0_idx_w;
  wire [ROB_INDEX_W-1:0] rob_dispatch1_idx_w;
  wire [PRODUCER_ID_W-1:0] rob_dispatch0_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_dispatch1_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_head0_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_commit0_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_commit1_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_walk0_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_walk1_producer_id_w;
  wire [ROB_INDEX_W-1:0] rob_head_idx_w;
  wire rob_head_valid_w;
  wire [ROB_COUNT_W-1:0] rob_count_w;
  wire rob_empty_w;
  wire rob_full_w;

  wire iq_dispatch0_ready_w;
  wire iq_dispatch1_ready_w;
  wire [ISSUE_COUNT_W-1:0] iq_count_w;
  wire iq_empty_w;
  wire iq_full_w;

  wire [FREE_COUNT_W-1:0] free_count_w;
  wire free_empty_w;
  wire free_full_w;
  wire freelist_alloc0_ready_w;
  wire freelist_alloc1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] freelist_alloc0_preg_w;
  wire [PHY_REG_ADDR_W-1:0] freelist_alloc1_preg_w;

  // ROB/IQ 的真实数组深度必须随指针位宽同步扩大；否则只会得到
  // “计数位宽变宽、可用槽位未变”的假窗口。
  localparam ROB_ENTRY_COUNT = (1 << ROB_INDEX_W);
  localparam ISSUE_ENTRY_INDEX_W = ISSUE_COUNT_W - 1;
  localparam ISSUE_ENTRY_COUNT = (1 << ISSUE_ENTRY_INDEX_W);
  localparam [ROB_COUNT_W-1:0] ROB_PAIR_MAX_COUNT =
      (1 << ROB_INDEX_W) - 2;
  localparam [ISSUE_COUNT_W-1:0] IQ_PAIR_MAX_COUNT =
      (1 << ISSUE_ENTRY_INDEX_W) - 2;

  wire free_ok0_w = !dispatch0_writes_rd_w ||
                    (free_count_w >= {{(FREE_COUNT_W-1){1'b0}}, 1'b1});

  wire rob_slot0_ready_w =
      (rob_count_w != ROB_ENTRY_COUNT[ROB_COUNT_W-1:0]);
  wire iq_slot0_ready_w =
      (iq_count_w != ISSUE_ENTRY_COUNT[ISSUE_COUNT_W-1:0]);
  wire rob_pair_ready_w = (rob_count_w <= ROB_PAIR_MAX_COUNT);
  wire iq_pair_ready_w = (iq_count_w <= IQ_PAIR_MAX_COUNT);

  wire dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  wire dispatch0_alloc_w = dispatch0_fire_w && dispatch0_writes_rd_w;

  // 【LSQ·SQ 切换】store 的 SQ slot 判定: slot0 给 d0(或 d0 非 store 时给 d1);
  // d0/d1 双 store 时 d1 需第二 slot(alloc1_ready)。
  wire dispatch0_is_store_w = ((dispatch0_inst_i[6:0] == 7'b0100011) ||
       ((dispatch0_inst_i[6:0] == 7'b0100111) &&
        ((dispatch0_inst_i[14:12] == 3'b010) || (dispatch0_inst_i[14:12] == 3'b011))));
  wire dispatch1_is_store_w = ((dispatch1_inst_i[6:0] == 7'b0100011) ||
       ((dispatch1_inst_i[6:0] == 7'b0100111) &&
        ((dispatch1_inst_i[14:12] == 3'b010) || (dispatch1_inst_i[14:12] == 3'b011))));
  wire sq_ok0_w = !dispatch0_is_store_w || sq_alloc0_ready_i;
  wire sq_ok1_w = !dispatch1_is_store_w ||
                  (dispatch0_is_store_w ? sq_alloc1_ready_i :
                                          sq_alloc0_ready_i);

  wire free_ok1_pair_w =
      !dispatch1_writes_rd_w ||
      (free_count_w >= (dispatch0_writes_rd_w ?
                        {{(FREE_COUNT_W-2){1'b0}}, 2'd2} :
                        {{(FREE_COUNT_W-1){1'b0}}, 1'b1}));
  wire dispatch1_pair_ready_w =
      !dispatch1_valid_i ||
      dispatch1_optional_i ||
      (rob_pair_ready_w && (iq_pair_ready_w || dispatch1_fp_arith_w) &&
       free_ok1_pair_w && sq_ok1_w);

  wire free_ok1_w = !dispatch1_writes_rd_w ||
                    (free_count_w >= (dispatch0_alloc_w ?
                                      {{(FREE_COUNT_W-2){1'b0}}, 2'd2} :
                                      {{(FREE_COUNT_W-1){1'b0}}, 1'b1}));
  // B2 ROB-walk 声明前置：以下信号的驱动逻辑在文件后段，但本行起即被引用；
  // iverilog 14 对 net-declaration-assignment 中的前向引用无法绑定(12 才容忍)，故声明上移。
  wire rob_recover_active_w;
  wire rob_walk0_valid_w;
  wire [`REG_ADDR_W-1:0] rob_walk0_arch_rd_w;
  wire [PHY_REG_ADDR_W-1:0] rob_walk0_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] rob_walk0_new_pdest_w;
  wire rob_walk0_rd_en_w;
  wire rob_walk1_valid_w;
  wire [`REG_ADDR_W-1:0] rob_walk1_arch_rd_w;
  wire [PHY_REG_ADDR_W-1:0] rob_walk1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] rob_walk1_new_pdest_w;
  wire rob_walk1_rd_en_w;
  wire rename_restore0_en_w;
  wire rename_restore1_en_w;
  // Dispatch owner 直接用容量计数生成 ready，避免 parent fire 再反喂
  // ROB/IQ ready 形成跨层组合环；子模块仍接收同一个 fire 更新状态。
  // T3N 关键：输入 kill 本身来自 resolve PipeStageReg q；可直接在同拍冻结
  // tail/dispatch 并驱动 IQ squash，不再重复打一拍，也不会重建旧 resolve→ready 环。
  // 而本层 ready 只看 count(非满)，不知道冻结 → 仍会 dispatch，使 ROB tail 不前进而 rob_idx 复用、
  // 多条指令共用同一 ROB 槽 → wakeup 错配/僵尸项。故用「已寄存」的 recover/kill 同步冻结本层 dispatch
  // （均为寄存来源，不引入跨层组合环）。
  wire rob_walk_mode_w = `OOO_ROB_WALK_MODE;
  wire rob_kill_valid_w = rob_walk_mode_w && branch_mispredict_valid_i;
  wire [ROB_INDEX_W-1:0] rob_kill_idx_w = kill_rob_idx_i;
  // reset/flush 与 child state-update priority 同域：parent ready 也必须拉低，
  // 否则上游会观察到一次并未被 ROB/IQ/rename 接受的伪 fire。
  wire dispatch_freeze_w = rst || flush_i ||
                           rob_recover_active_w || rob_kill_valid_w;
  assign dispatch0_ready_o = rob_slot0_ready_w &&
                             (iq_slot0_ready_w || dispatch0_fp_arith_w) &&
                             free_ok0_w && sq_ok0_w &&
                             dispatch1_pair_ready_w &&
                             !dispatch_freeze_w;

  assign dispatch1_ready_o = dispatch0_fire_w && rob_pair_ready_w &&
                             (iq_pair_ready_w || dispatch1_fp_arith_w) &&
                             free_ok1_w && sq_ok1_w;

  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;
  wire dispatch1_alloc_w = dispatch1_fire_w && dispatch1_writes_rd_w;

  wire freelist_alloc0_valid_w = dispatch0_alloc_w ||
                                 (dispatch1_alloc_w && !dispatch0_alloc_w);
  wire freelist_alloc1_valid_w = dispatch0_alloc_w && dispatch1_alloc_w;

  wire [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest_w =
      dispatch0_alloc_w ? freelist_alloc0_preg_w : {PHY_REG_ADDR_W{1'b0}};
  wire [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest_w =
      dispatch1_alloc_w ? (dispatch0_alloc_w ? freelist_alloc1_preg_w :
                                             freelist_alloc0_preg_w) :
                          {PHY_REG_ADDR_W{1'b0}};

  wire [PHY_REG_ADDR_W-1:0] rename0_rs1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] rename0_rs2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] rename0_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] rename0_new_pdest_unused_w;
  wire [PHY_REG_ADDR_W-1:0] rename1_rs1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] rename1_rs2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] rename1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] rename1_new_pdest_unused_w;
  wire [PHY_REG_ADDR_W * `REG_NUM - 1:0] debug_map_unused_w;

  wire [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_w =
      dispatch0_uses_rs1_w ? rename0_rs1_preg_w : {PHY_REG_ADDR_W{1'b0}};
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_w =
      dispatch0_uses_rs2_w ? rename0_rs2_preg_w : {PHY_REG_ADDR_W{1'b0}};
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_w =
      dispatch1_uses_rs1_w ? rename1_rs1_preg_w : {PHY_REG_ADDR_W{1'b0}};
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_w =
      dispatch1_uses_rs2_w ? rename1_rs2_preg_w : {PHY_REG_ADDR_W{1'b0}};

  wire dispatch0_src1_ready_w;
  wire dispatch0_src2_ready_w;
  wire dispatch1_src1_ready_w;
  wire dispatch1_src2_ready_w;

  OooFreeList #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .FREE_COUNT_W(FREE_COUNT_W)
  ) u_free_list (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .alloc0_valid_i(freelist_alloc0_valid_w),
    .alloc0_ready_o(freelist_alloc0_ready_w),
    .alloc0_preg_o(freelist_alloc0_preg_w),
    .alloc1_valid_i(freelist_alloc1_valid_w),
    .alloc1_ready_o(freelist_alloc1_ready_w),
    .alloc1_preg_o(freelist_alloc1_preg_w),
    // 恢复期：free 回收 walk 的 new_pdest（squashed 且 rd_en）；常规期：free commit 的 old_pdest。
    .free0_valid_i(rob_recover_active_w ? (rob_walk0_valid_w && rob_walk0_rd_en_w)
                                        : (commit0_valid_o && commit0_rd_en_o)),
    .free0_preg_i(rob_recover_active_w ? rob_walk0_new_pdest_w : commit0_old_pdest_o),
    .free1_valid_i(rob_recover_active_w ? (rob_walk1_valid_w && rob_walk1_rd_en_w)
                                        : (commit1_valid_o && commit1_rd_en_o)),
    .free1_preg_i(rob_recover_active_w ? rob_walk1_new_pdest_w : commit1_old_pdest_o),
    .free_count_o(free_count_w),
    .empty_o(free_empty_w),
    .full_o(free_full_w)
  );

  OooRenameMap #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_rename_map (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .rename0_valid_i(dispatch0_fire_w),
    .rename0_rs1_arch_i(dispatch0_rs1_arch_i),
    .rename0_rs2_arch_i(dispatch0_rs2_arch_i),
    .rename0_rd_en_i(dispatch0_writes_rd_w),
    .rename0_rd_arch_i(dispatch0_rd_arch_i),
    .rename0_new_pdest_i(dispatch0_new_pdest_w),
    .rename0_rs1_preg_o(rename0_rs1_preg_w),
    .rename0_rs2_preg_o(rename0_rs2_preg_w),
    .rename0_old_pdest_o(rename0_old_pdest_w),
    .rename0_new_pdest_o(rename0_new_pdest_unused_w),
    .rename1_valid_i(dispatch1_fire_w),
    .rename1_rs1_arch_i(dispatch1_rs1_arch_i),
    .rename1_rs2_arch_i(dispatch1_rs2_arch_i),
    .rename1_rd_en_i(dispatch1_writes_rd_w),
    .rename1_rd_arch_i(dispatch1_rd_arch_i),
    .rename1_new_pdest_i(dispatch1_new_pdest_w),
    .rename1_rs1_preg_o(rename1_rs1_preg_w),
    .rename1_rs2_preg_o(rename1_rs2_preg_w),
    .rename1_old_pdest_o(rename1_old_pdest_w),
    .rename1_new_pdest_o(rename1_new_pdest_unused_w),
    .restore_valid_i(rob_recover_active_w),
    .restore0_en_i(rename_restore0_en_w),
    .restore0_arch_i(rob_walk0_arch_rd_w),
    .restore0_pdest_i(rob_walk0_old_pdest_w),
    .restore1_en_i(rename_restore1_en_w),
    .restore1_arch_i(rob_walk1_arch_rd_w),
    .restore1_pdest_i(rob_walk1_old_pdest_w),
    .debug_map_o(debug_map_unused_w)
  );

  // 声明须先于下方实例端口引用(iverilog 14 拒绝输出端口的前向引用)。
  wire busy_raw_unused_w;
  OooBusyTable #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_busy_table (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .alloc0_valid_i(freelist_alloc0_valid_w),
    .alloc0_pdest_i(freelist_alloc0_valid_w ? freelist_alloc0_preg_w : {PHY_REG_ADDR_W{1'b0}}),
    .alloc1_valid_i(freelist_alloc1_valid_w),
    .alloc1_pdest_i(freelist_alloc1_valid_w ? freelist_alloc1_preg_w : {PHY_REG_ADDR_W{1'b0}}),
    .wakeup0_valid_i(wb0_valid_i),
    .wakeup0_pdest_i(wb0_pdest_i),
    .wakeup1_valid_i(wb1_valid_i),
    .wakeup1_pdest_i(wb1_pdest_i),
    .query0_preg_i(dispatch0_src1_preg_w),
    .query0_ready_o(dispatch0_src1_ready_w),
    .query1_preg_i(dispatch0_src2_preg_w),
    .query1_ready_o(dispatch0_src2_ready_w),
    .query2_preg_i(dispatch1_src1_preg_w),
    .query2_ready_o(dispatch1_src1_ready_w),
    .query3_preg_i(dispatch1_src2_preg_w),
    .query3_ready_o(dispatch1_src2_ready_w),
    .query_raw_preg_i({PHY_REG_ADDR_W{1'b0}}),
    .query_raw_ready_o(busy_raw_unused_w)
  );

  // B2 ROB-walk 恢复数据通路；walk/kill 相关声明已前置到 dispatch_freeze_w
  // 之前，此处只留驱动逻辑。后端显式 branch/JALR mispredict
  // (branch_mispredict_valid_i) 驱动 ROB-walk kill；
  // kill_rob_idx 来自后端解析控制流 rob_idx（ROB-walk 全阵列 restore，无 checkpoint）。
  // 旧版在这里把组合 branch resolve 再寄存一拍以断环；T3N 已把完整 resolve
  // packet 在 OooIntBackend 统一寄存，故本层直接消费 q，保持 issue→ROB/IQ kill
  // 总延迟仍为一拍，并保证 valid/index 同源同拍。
  // walk→rename restore：恢复 map[arch]=old_pdest（仅 squashed 且 rd_en）。
  assign rename_restore0_en_w = rob_walk0_valid_w && rob_walk0_rd_en_w;
  assign rename_restore1_en_w = rob_walk1_valid_w && rob_walk1_rd_en_w;
  // FP walk 分流(FPR 目的 rd_en=0 → 整数 restore/free 天然跳过; is_fp_rd 单独出)
  wire rob_walk0_is_fp_w;
  wire rob_walk1_is_fp_w;
  assign walk0_fp_valid_o = rob_recover_active_w && rob_walk0_valid_w &&
                            rob_walk0_is_fp_w;
  assign walk0_fp_arch_o = rob_walk0_arch_rd_w;
  assign walk0_fp_old_pdest_o = rob_walk0_old_pdest_w;
  assign walk0_fp_new_pdest_o = rob_walk0_new_pdest_w;
  assign walk1_fp_valid_o = rob_recover_active_w && rob_walk1_valid_w &&
                            rob_walk1_is_fp_w;
  assign walk1_fp_arch_o = rob_walk1_arch_rd_w;
  assign walk1_fp_old_pdest_o = rob_walk1_old_pdest_w;
  assign walk1_fp_new_pdest_o = rob_walk1_new_pdest_w;

  OooRob #(
    .ROB_ENTRIES(ROB_ENTRY_COUNT),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_rob (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .head0_context_permit_i(head0_context_permit_i),
    .fencei_retire_permit_i(fencei_retire_permit_i),
    .head0_retire_candidate_valid_o(head0_retire_candidate_valid_o),
    .head0_identity_valid_o(head0_identity_valid_o),
    .head0_identity_o(head0_identity_o),
    .head0_producer_id_o(rob_head0_producer_id_w),
    .dispatch0_valid_i(dispatch0_fire_w),
    .dispatch0_ready_o(rob_dispatch0_ready_w),
    .dispatch0_rob_idx_o(rob_dispatch0_idx_w),
    .dispatch0_producer_id_o(rob_dispatch0_producer_id_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_rd_en_i(dispatch0_writes_rd_w),
    .dispatch0_is_fp_rd_i(dispatch0_is_fp_rd_i),
    .dispatch0_arch_rd_i(dispatch0_rd_arch_i),
    .dispatch0_old_pdest_i(dispatch0_is_fp_rd_i ? dispatch0_fp_old_pdest_i :
                           dispatch0_writes_rd_w ? rename0_old_pdest_w :
                           {PHY_REG_ADDR_W{1'b0}}),
    .dispatch0_new_pdest_i(dispatch0_is_fp_rd_i ? dispatch0_fp_pdest_i
                                                  : dispatch0_new_pdest_w),
    .dispatch1_valid_i(dispatch1_fire_w),
    .dispatch1_ready_o(rob_dispatch1_ready_w),
    .dispatch1_rob_idx_o(rob_dispatch1_idx_w),
    .dispatch1_producer_id_o(rob_dispatch1_producer_id_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_rd_en_i(dispatch1_writes_rd_w),
    .dispatch1_is_fp_rd_i(dispatch1_is_fp_rd_i),
    .dispatch1_arch_rd_i(dispatch1_rd_arch_i),
    .dispatch1_old_pdest_i(dispatch1_is_fp_rd_i ? dispatch1_fp_old_pdest_i :
                           dispatch1_writes_rd_w ? rename1_old_pdest_w :
                           {PHY_REG_ADDR_W{1'b0}}),
    .dispatch1_new_pdest_i(dispatch1_is_fp_rd_i ? dispatch1_fp_pdest_i
                                                  : dispatch1_new_pdest_w),
    .wb0_valid_i(wb0_valid_i),
    .wb0_rob_idx_i(wb0_rob_idx_i),
    .wb0_pdest_i(wb0_pdest_i),
    .wb0_data_i(wb0_data_i),
    .wb0_exception_i(wb0_exception_i),
    .wb0_cause_i(wb0_cause_i),
    .wb0_tval_i(wb0_tval_i),
    .wb0_fflags_i(wb0_fflags_i),
    .wb1_valid_i(wb1_valid_i),
    .wb1_rob_idx_i(wb1_rob_idx_i),
    .wb1_pdest_i(wb1_pdest_i),
    .wb1_data_i(wb1_data_i),
    .wb1_exception_i(wb1_exception_i),
    .wb1_cause_i(wb1_cause_i),
    .wb1_tval_i(wb1_tval_i),
    .wb1_fflags_i(wb1_fflags_i),
    .current0_query_valid_i(issue0_valid_o),
    .current0_query_producer_id_i(issue0_producer_id_o),
    .current0_query_match_o(issue0_producer_current_o),
    .current1_query_valid_i(issue1_valid_o),
    .current1_query_producer_id_i(issue1_producer_id_o),
    .current1_query_match_o(issue1_producer_current_o),
    .completion0_query_valid_i(completion0_query_valid_i),
    .completion0_query_producer_id_i(completion0_query_producer_id_i),
    .completion0_query_match_o(completion0_query_match_o),
    .completion1_query_valid_i(completion1_query_valid_i),
    .completion1_query_producer_id_i(completion1_query_producer_id_i),
    .completion1_query_match_o(completion1_query_match_o),
    .commit_ready_i(commit_ready_i),
    .commit1_block_i(commit1_block_i),
    .mem_quiet_i(mem_quiet_i),
    .commit0_valid_o(commit0_valid_o),
    .commit0_producer_id_o(rob_commit0_producer_id_w),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_is_fp_rd_o(commit0_is_fp_rd_o),
    .commit0_fflags_o(commit0_fflags_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_o),
    .commit0_new_pdest_o(commit0_new_pdest_o),
    .commit0_data_o(commit0_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_o),
    .commit0_tval_o(commit0_tval_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_producer_id_o(rob_commit1_producer_id_w),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_is_fp_rd_o(commit1_is_fp_rd_o),
    .commit1_fflags_o(commit1_fflags_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_o),
    .commit1_new_pdest_o(commit1_new_pdest_o),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_o),
    .commit1_tval_o(commit1_tval_o),
    .head_idx_o(rob_head_idx_w),
    .head_valid_o(rob_head_valid_w),
    .count_o(rob_count_w),
    .empty_o(rob_empty_w),
    .full_o(rob_full_w),
    .kill_valid_i(rob_kill_valid_w),
    .kill_rob_idx_i(rob_kill_idx_w),
    .recover_active_o(rob_recover_active_w),
    .walk0_valid_o(rob_walk0_valid_w),
    .walk0_producer_id_o(rob_walk0_producer_id_w),
    .walk0_arch_rd_o(rob_walk0_arch_rd_w),
    .walk0_old_pdest_o(rob_walk0_old_pdest_w),
    .walk0_new_pdest_o(rob_walk0_new_pdest_w),
    .walk0_rd_en_o(rob_walk0_rd_en_w),
    .walk1_valid_o(rob_walk1_valid_w),
    .walk1_producer_id_o(rob_walk1_producer_id_w),
    .walk1_arch_rd_o(rob_walk1_arch_rd_w),
    .walk1_old_pdest_o(rob_walk1_old_pdest_w),
    .walk1_new_pdest_o(rob_walk1_new_pdest_w),
    .walk1_rd_en_o(rob_walk1_rd_en_w),
    .walk0_is_fp_o(rob_walk0_is_fp_w),
    .walk1_is_fp_o(rob_walk1_is_fp_w)
  );

  assign rob_head_idx_o = rob_head_idx_w;
  assign rob_head_valid_o = rob_head_valid_w;
  assign rob_recover_active_o = rob_recover_active_w;

  OooIntIssueQueue #(
    .ENTRY_COUNT(ISSUE_ENTRY_COUNT),
    .ENTRY_INDEX_W(ISSUE_ENTRY_INDEX_W),
    .ENTRY_COUNT_W(ISSUE_COUNT_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_issue_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .issue_mem_block_i(issue_mem_block_i),
    .universal_owner_present_i(universal_owner_present_i),
    .dispatch0_valid_i(dispatch0_fire_w && !dispatch0_fp_arith_w),
    .dispatch0_ready_o(iq_dispatch0_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_is_fp_i(dispatch0_is_fp_i),
    .dispatch0_rob_idx_i(rob_dispatch0_idx_w),
    .dispatch0_producer_id_i(rob_dispatch0_producer_id_w),
    .dispatch0_src1_preg_i(dispatch0_src1_preg_w),
    .dispatch0_src1_ready_i(!dispatch0_uses_rs1_w || dispatch0_src1_ready_w),
    .dispatch0_src2_preg_i(dispatch0_src2_preg_w),
    .dispatch0_src2_ready_i(!dispatch0_uses_rs2_w || dispatch0_src2_ready_w),
    .dispatch0_pdest_i(dispatch0_is_fp_rd_i ? dispatch0_fp_pdest_i
                                              : dispatch0_new_pdest_w),
    .dispatch0_fp_pdest_i(dispatch0_is_fp_rd_i),
    .dispatch0_fp_st_src_en_i(dispatch0_fp_st_src_en_i),
    .dispatch0_fp_st_src_preg_i(dispatch0_fp_st_src_preg_i),
    .dispatch0_fp_st_src_ready_i(dispatch0_fp_st_src_ready_i),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch0_bht_idx_i(dispatch0_bht_idx_i),
    .dispatch0_pred_taken_i(dispatch0_pred_taken_i),
    .dispatch1_valid_i(dispatch1_fire_w && !dispatch1_fp_arith_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(iq_dispatch1_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_is_fp_i(dispatch1_is_fp_i),
    .dispatch1_rob_idx_i(rob_dispatch1_idx_w),
    .dispatch1_producer_id_i(rob_dispatch1_producer_id_w),
    .dispatch1_src1_preg_i(dispatch1_src1_preg_w),
    .dispatch1_src1_ready_i(!dispatch1_uses_rs1_w || dispatch1_src1_ready_w),
    .dispatch1_src2_preg_i(dispatch1_src2_preg_w),
    .dispatch1_src2_ready_i(!dispatch1_uses_rs2_w || dispatch1_src2_ready_w),
    .dispatch1_pdest_i(dispatch1_is_fp_rd_i ? dispatch1_fp_pdest_i
                                              : dispatch1_new_pdest_w),
    .dispatch1_fp_pdest_i(dispatch1_is_fp_rd_i),
    .dispatch1_fp_st_src_en_i(dispatch1_fp_st_src_en_i),
    .dispatch1_fp_st_src_preg_i(dispatch1_fp_st_src_preg_i),
    .dispatch1_fp_st_src_ready_i(dispatch1_fp_st_src_ready_i),
    .dispatch1_imm_i(dispatch1_imm_i),
    .dispatch1_bht_idx_i(dispatch1_bht_idx_i),
    .dispatch1_pred_taken_i(dispatch1_pred_taken_i),
    .wakeup0_valid_i(wb0_valid_i),
    .wakeup0_pdest_i(wb0_pdest_i),
    .wakeup1_valid_i(wb1_valid_i),
    .wakeup1_pdest_i(wb1_pdest_i),
    .early_wakeup0_valid_i(early_wakeup0_valid_i),
    .early_wakeup0_pdest_i(early_wakeup0_pdest_i),
    .early_wakeup1_valid_i(early_wakeup1_valid_i),
    .early_wakeup1_pdest_i(early_wakeup1_pdest_i),
    .fp_wake0_valid_i(fp_wake0_valid_i),
    .fp_wake0_preg_i(fp_wake0_preg_i),
    .fp_wake1_valid_i(fp_wake1_valid_i),
    .fp_wake1_preg_i(fp_wake1_preg_i),
    .issue0_valid_o(issue0_valid_o),
    .issue0_ready_i(issue0_ready_i),
    .issue0_pc_o(issue0_pc_o),
    .issue0_next_pc_o(issue0_next_pc_o),
    .issue0_pred_npc_o(issue0_pred_npc_o),
    .issue0_inst_o(issue0_inst_o),
    .issue0_ctrl_o(issue0_ctrl_o),
    .issue0_rob_idx_o(issue0_rob_idx_o),
    .issue0_producer_id_o(issue0_producer_id_o),
    .issue0_src1_preg_o(issue0_src1_preg_o),
    .issue0_src2_preg_o(issue0_src2_preg_o),
    .issue0_pdest_o(issue0_pdest_o),
    .issue0_fixed_gpr_producer_o(issue0_fixed_gpr_producer_o),
    .issue0_fp_pdest_o(issue0_fp_pdest_o),
    .issue0_fp_st_src_en_o(issue0_fp_st_src_en_o),
    .issue0_fp_st_src_preg_o(issue0_fp_st_src_preg_o),
    .issue0_imm_o(issue0_imm_o),
    .issue0_bht_idx_o(issue0_bht_idx_o),
    .issue0_pred_taken_o(issue0_pred_taken_o),
    .issue_pair_swapped_o(issue_pair_swapped_o),
    .issue1_valid_o(issue1_valid_o),
    .issue1_ready_i(issue1_ready_i),
    .issue1_pc_o(issue1_pc_o),
    .issue1_next_pc_o(issue1_next_pc_o),
    .issue1_pred_npc_o(issue1_pred_npc_o),
    .issue1_inst_o(issue1_inst_o),
    .issue1_ctrl_o(issue1_ctrl_o),
    .issue1_rob_idx_o(issue1_rob_idx_o),
    .issue1_producer_id_o(issue1_producer_id_o),
    .issue1_src1_preg_o(issue1_src1_preg_o),
    .issue1_src2_preg_o(issue1_src2_preg_o),
    .issue1_pdest_o(issue1_pdest_o),
    .issue1_fixed_gpr_producer_o(issue1_fixed_gpr_producer_o),
    .issue1_fp_pdest_o(issue1_fp_pdest_o),
    .issue1_fp_st_src_en_o(issue1_fp_st_src_en_o),
    .issue1_fp_st_src_preg_o(issue1_fp_st_src_preg_o),
    .issue1_imm_o(issue1_imm_o),
    .issue1_bht_idx_o(issue1_bht_idx_o),
    .issue1_pred_taken_o(issue1_pred_taken_o),
    .count_o(iq_count_w),
    .empty_o(iq_empty_w),
    .full_o(iq_full_w),
    // B2 ROB-walk：暂行为中性（kill=0、recover=0）；Step B 接 ROB.recover_active + kill 源。
    .kill_valid_i(rob_kill_valid_w),
    .kill_rob_idx_i(rob_kill_idx_w),
    .rob_head_idx_i(rob_head_idx_w),
    .recover_active_i(rob_recover_active_w)
  );

  assign free_count_o = free_count_w;
  assign rob_count_o = rob_count_w;
  assign issue_count_o = iq_count_w;
  assign dispatch0_fire_o = dispatch0_fire_w;
  assign dispatch0_rob_idx_o = rob_dispatch0_idx_w;
  assign dispatch0_pdest_o = dispatch0_new_pdest_w;
  assign dispatch1_pdest_o = dispatch1_new_pdest_w;
  assign dispatch0_src1_preg_o = dispatch0_src1_preg_w;
  assign dispatch0_src1_ready_o = !dispatch0_uses_rs1_w || dispatch0_src1_ready_w;
  assign dispatch0_src2_preg_o = dispatch0_src2_preg_w;
  assign dispatch0_src2_ready_o = !dispatch0_uses_rs2_w || dispatch0_src2_ready_w;
  assign dispatch1_fire_o = dispatch1_fire_w;
  assign dispatch1_rob_idx_o = rob_dispatch1_idx_w;
  assign dispatch1_src1_preg_o = dispatch1_src1_preg_w;
  assign dispatch1_src1_ready_o = !dispatch1_uses_rs1_w || dispatch1_src1_ready_w;
  assign dispatch1_src2_preg_o = dispatch1_src2_preg_w;
  assign dispatch1_src2_ready_o = !dispatch1_uses_rs2_w || dispatch1_src2_ready_w;

  wire unused_status_w = free_empty_w | free_full_w |
                         freelist_alloc0_ready_w | freelist_alloc1_ready_w |
                         rob_dispatch0_ready_w | rob_dispatch1_ready_w |
                         iq_dispatch0_ready_w | iq_dispatch1_ready_w |
                         rob_empty_w | rob_full_w | iq_empty_w | iq_full_w |
                         (|rob_head0_producer_id_w) |
                         (|rob_commit0_producer_id_w) |
                         (|rob_commit1_producer_id_w) |
                         (|rob_walk0_producer_id_w) |
                         (|rob_walk1_producer_id_w) |
                         (|rename0_new_pdest_unused_w) |
                         (|rename1_new_pdest_unused_w) | (|debug_map_unused_w);

`ifdef ROB_WALK_DEBUG
  always @(posedge clk) begin
    if (!rst) begin
      if (dispatch0_fire_w)
        $display("[D0] pc=%h rd=%0d newp=%0d rs1=%0d s1p=%0d s1rdy=%b rs2=%0d s2p=%0d s2rdy=%b rob=%0d", dispatch0_pc_i, dispatch0_rd_arch_i, dispatch0_new_pdest_w, dispatch0_rs1_arch_i, dispatch0_src1_preg_w, (!dispatch0_uses_rs1_w||dispatch0_src1_ready_w), dispatch0_rs2_arch_i, dispatch0_src2_preg_w, (!dispatch0_uses_rs2_w||dispatch0_src2_ready_w), rob_dispatch0_idx_w);
      if (dispatch1_fire_w)
        $display("[D1] pc=%h rd=%0d newp=%0d rs1=%0d s1p=%0d s1rdy=%b rs2=%0d s2p=%0d s2rdy=%b rob=%0d", dispatch1_pc_i, dispatch1_rd_arch_i, dispatch1_new_pdest_w, dispatch1_rs1_arch_i, dispatch1_src1_preg_w, (!dispatch1_uses_rs1_w||dispatch1_src1_ready_w), dispatch1_rs2_arch_i, dispatch1_src2_preg_w, (!dispatch1_uses_rs2_w||dispatch1_src2_ready_w), rob_dispatch1_idx_w);
    end
  end
`endif


endmodule
/* verilator lint_on UNOPTFLAT */
