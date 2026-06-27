`include "define.v"

// 先把 OoO dispatch/rename 后端边界串成一个可验证闭环：
// rename/free-list/ROB/busy-table/issue-queue 在这里按 2-wide 程序序协同，
// 后续执行单元只需要消费 issue 端口并通过 writeback 端口唤醒与完成 ROB。
module OooDispatchBackend #(
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
  input issue_mem_block_i,
  input pending_load0_valid_i,
  input [PHY_REG_ADDR_W-1:0] pending_load0_pdest_i,
  input pending_load1_valid_i,
  input [PHY_REG_ADDR_W-1:0] pending_load1_pdest_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
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
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rd_arch_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  input wb0_valid_i,
  input [ROB_INDEX_W-1:0] wb0_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] wb0_pdest_i,
  input [`XLEN-1:0] wb0_data_i,
  input wb0_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb0_cause_i,
  input [`XLEN-1:0] wb0_tval_i,

  input wb1_valid_i,
  input [ROB_INDEX_W-1:0] wb1_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] wb1_pdest_i,
  input [`XLEN-1:0] wb1_data_i,
  input wb1_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb1_cause_i,
  input [`XLEN-1:0] wb1_tval_i,

  output issue0_valid_o,
  input issue0_ready_i,
  output [`XLEN-1:0] issue0_pc_o,
  output [`XLEN-1:0] issue0_next_pc_o,
  output [`INST_W-1:0] issue0_inst_o,
  output [`CTRL_BUS_W-1:0] issue0_ctrl_o,
  output [ROB_INDEX_W-1:0] issue0_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_pdest_o,
  output [`XLEN-1:0] issue0_imm_o,

  output issue1_valid_o,
  input issue1_ready_i,
  output [`XLEN-1:0] issue1_pc_o,
  output [`XLEN-1:0] issue1_next_pc_o,
  output [`INST_W-1:0] issue1_inst_o,
  output [`CTRL_BUS_W-1:0] issue1_ctrl_o,
  output [ROB_INDEX_W-1:0] issue1_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_pdest_o,
  output [`XLEN-1:0] issue1_imm_o,

  output dispatch0_fire_o,
  output [ROB_INDEX_W-1:0] dispatch0_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] dispatch0_pdest_o,
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

  output [ROB_INDEX_W-1:0] rob_head_idx_o,
  output rob_head_valid_o,
  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,
  output pending_load_branch_dep_o,
  output load_branch_fast_valid_o,
  output [ROB_INDEX_W-1:0] load_branch_fast_rob_idx_o,
  output [`XLEN-1:0] load_branch_fast_pc_o,
  output [`XLEN-1:0] load_branch_fast_next_pc_o,
  output [`XLEN-1:0] load_branch_fast_imm_o,
  output [2:0] load_branch_fast_cmp_op_o,
  output [PHY_REG_ADDR_W-1:0] load_branch_fast_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] load_branch_fast_src2_preg_o,
  output load_branch_fast_wait_load0_o,
  output load_branch_fast_wait_load1_o
);

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

  wire free_ok1_pair_w =
      !dispatch1_writes_rd_w ||
      (free_count_w >= (dispatch0_writes_rd_w ?
                        {{(FREE_COUNT_W-2){1'b0}}, 2'd2} :
                        {{(FREE_COUNT_W-1){1'b0}}, 1'b1}));
  wire dispatch1_pair_ready_w =
      !dispatch1_valid_i ||
      dispatch1_optional_i ||
      (rob_pair_ready_w && iq_pair_ready_w && free_ok1_pair_w);

  wire free_ok1_w = !dispatch1_writes_rd_w ||
                    (free_count_w >= (dispatch0_alloc_w ?
                                      {{(FREE_COUNT_W-2){1'b0}}, 2'd2} :
                                      {{(FREE_COUNT_W-1){1'b0}}, 1'b1}));
  // Dispatch owner 直接用容量计数生成 ready，避免 parent fire 再反喂
  // ROB/IQ ready 形成跨层组合环；子模块仍接收同一个 fire 更新状态。
  assign dispatch0_ready_o = rob_slot0_ready_w && iq_slot0_ready_w &&
                             free_ok0_w && dispatch1_pair_ready_w;

  assign dispatch1_ready_o = dispatch0_fire_w && rob_pair_ready_w &&
                             iq_pair_ready_w && free_ok1_w;

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
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .alloc0_valid_i(freelist_alloc0_valid_w),
    .alloc0_ready_o(freelist_alloc0_ready_w),
    .alloc0_preg_o(freelist_alloc0_preg_w),
    .alloc1_valid_i(freelist_alloc1_valid_w),
    .alloc1_ready_o(freelist_alloc1_ready_w),
    .alloc1_preg_o(freelist_alloc1_preg_w),
    .free0_valid_i(commit0_valid_o && commit0_rd_en_o),
    .free0_preg_i(commit0_old_pdest_o),
    .free1_valid_i(commit1_valid_o && commit1_rd_en_o),
    .free1_preg_i(commit1_old_pdest_o),
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
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
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
    .debug_map_o(debug_map_unused_w)
  );

  OooBusyTable #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_busy_table (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
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
    .query3_ready_o(dispatch1_src2_ready_w)
  );

  OooRob #(
    .ROB_ENTRIES(ROB_ENTRY_COUNT),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_rob (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .dispatch0_valid_i(dispatch0_fire_w),
    .dispatch0_ready_o(rob_dispatch0_ready_w),
    .dispatch0_rob_idx_o(rob_dispatch0_idx_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_rd_en_i(dispatch0_writes_rd_w),
    .dispatch0_arch_rd_i(dispatch0_rd_arch_i),
    .dispatch0_old_pdest_i(dispatch0_writes_rd_w ? rename0_old_pdest_w : {PHY_REG_ADDR_W{1'b0}}),
    .dispatch0_new_pdest_i(dispatch0_new_pdest_w),
    .dispatch1_valid_i(dispatch1_fire_w),
    .dispatch1_ready_o(rob_dispatch1_ready_w),
    .dispatch1_rob_idx_o(rob_dispatch1_idx_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_rd_en_i(dispatch1_writes_rd_w),
    .dispatch1_arch_rd_i(dispatch1_rd_arch_i),
    .dispatch1_old_pdest_i(dispatch1_writes_rd_w ? rename1_old_pdest_w : {PHY_REG_ADDR_W{1'b0}}),
    .dispatch1_new_pdest_i(dispatch1_new_pdest_w),
    .wb0_valid_i(wb0_valid_i),
    .wb0_rob_idx_i(wb0_rob_idx_i),
    .wb0_data_i(wb0_data_i),
    .wb0_exception_i(wb0_exception_i),
    .wb0_cause_i(wb0_cause_i),
    .wb0_tval_i(wb0_tval_i),
    .wb1_valid_i(wb1_valid_i),
    .wb1_rob_idx_i(wb1_rob_idx_i),
    .wb1_data_i(wb1_data_i),
    .wb1_exception_i(wb1_exception_i),
    .wb1_cause_i(wb1_cause_i),
    .wb1_tval_i(wb1_tval_i),
    .commit_ready_i(commit_ready_i),
    .commit1_block_i(commit1_block_i),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
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
    .full_o(rob_full_w)
  );

  assign rob_head_idx_o = rob_head_idx_w;
  assign rob_head_valid_o = rob_head_valid_w;

  OooIntIssueQueue #(
    .ENTRY_COUNT(ISSUE_ENTRY_COUNT),
    .ENTRY_INDEX_W(ISSUE_ENTRY_INDEX_W),
    .ENTRY_COUNT_W(ISSUE_COUNT_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) u_issue_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .issue_mem_block_i(issue_mem_block_i),
    .dispatch0_valid_i(dispatch0_fire_w),
    .dispatch0_ready_o(iq_dispatch0_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_rob_idx_i(rob_dispatch0_idx_w),
    .dispatch0_src1_preg_i(dispatch0_src1_preg_w),
    .dispatch0_src1_ready_i(!dispatch0_uses_rs1_w || dispatch0_src1_ready_w),
    .dispatch0_src2_preg_i(dispatch0_src2_preg_w),
    .dispatch0_src2_ready_i(!dispatch0_uses_rs2_w || dispatch0_src2_ready_w),
    .dispatch0_pdest_i(dispatch0_new_pdest_w),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch1_valid_i(dispatch1_fire_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(iq_dispatch1_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_rob_idx_i(rob_dispatch1_idx_w),
    .dispatch1_src1_preg_i(dispatch1_src1_preg_w),
    .dispatch1_src1_ready_i(!dispatch1_uses_rs1_w || dispatch1_src1_ready_w),
    .dispatch1_src2_preg_i(dispatch1_src2_preg_w),
    .dispatch1_src2_ready_i(!dispatch1_uses_rs2_w || dispatch1_src2_ready_w),
    .dispatch1_pdest_i(dispatch1_new_pdest_w),
    .dispatch1_imm_i(dispatch1_imm_i),
    .wakeup0_valid_i(wb0_valid_i),
    .wakeup0_pdest_i(wb0_pdest_i),
    .wakeup1_valid_i(wb1_valid_i),
    .wakeup1_pdest_i(wb1_pdest_i),
    .pending_load0_valid_i(pending_load0_valid_i),
    .pending_load0_pdest_i(pending_load0_pdest_i),
    .pending_load1_valid_i(pending_load1_valid_i),
    .pending_load1_pdest_i(pending_load1_pdest_i),
    .issue0_valid_o(issue0_valid_o),
    .issue0_ready_i(issue0_ready_i),
    .issue0_pc_o(issue0_pc_o),
    .issue0_next_pc_o(issue0_next_pc_o),
    .issue0_inst_o(issue0_inst_o),
    .issue0_ctrl_o(issue0_ctrl_o),
    .issue0_rob_idx_o(issue0_rob_idx_o),
    .issue0_src1_preg_o(issue0_src1_preg_o),
    .issue0_src2_preg_o(issue0_src2_preg_o),
    .issue0_pdest_o(issue0_pdest_o),
    .issue0_imm_o(issue0_imm_o),
    .issue1_valid_o(issue1_valid_o),
    .issue1_ready_i(issue1_ready_i),
    .issue1_pc_o(issue1_pc_o),
    .issue1_next_pc_o(issue1_next_pc_o),
    .issue1_inst_o(issue1_inst_o),
    .issue1_ctrl_o(issue1_ctrl_o),
    .issue1_rob_idx_o(issue1_rob_idx_o),
    .issue1_src1_preg_o(issue1_src1_preg_o),
    .issue1_src2_preg_o(issue1_src2_preg_o),
    .issue1_pdest_o(issue1_pdest_o),
    .issue1_imm_o(issue1_imm_o),
    .count_o(iq_count_w),
    .empty_o(iq_empty_w),
    .full_o(iq_full_w),
    .pending_load_branch_dep_o(pending_load_branch_dep_o),
    .load_branch_fast_valid_o(load_branch_fast_valid_o),
    .load_branch_fast_rob_idx_o(load_branch_fast_rob_idx_o),
    .load_branch_fast_pc_o(load_branch_fast_pc_o),
    .load_branch_fast_next_pc_o(load_branch_fast_next_pc_o),
    .load_branch_fast_imm_o(load_branch_fast_imm_o),
    .load_branch_fast_cmp_op_o(load_branch_fast_cmp_op_o),
    .load_branch_fast_src1_preg_o(load_branch_fast_src1_preg_o),
    .load_branch_fast_src2_preg_o(load_branch_fast_src2_preg_o),
    .load_branch_fast_wait_load0_o(load_branch_fast_wait_load0_o),
    .load_branch_fast_wait_load1_o(load_branch_fast_wait_load1_o)
  );

  assign free_count_o = free_count_w;
  assign rob_count_o = rob_count_w;
  assign issue_count_o = iq_count_w;
  assign dispatch0_fire_o = dispatch0_fire_w;
  assign dispatch0_rob_idx_o = rob_dispatch0_idx_w;
  assign dispatch0_pdest_o = dispatch0_new_pdest_w;
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
                         (|rename0_new_pdest_unused_w) |
                         (|rename1_new_pdest_unused_w) | (|debug_map_unused_w);

endmodule
