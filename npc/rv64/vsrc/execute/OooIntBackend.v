`include "define.v"

// ALU-only OoO integer backend slice.  The frontend still supplies decoded uops;
// this module closes the loop from rename/issue through PRF read, dual ALU
// execute, writeback wakeup, and in-order ROB commit.
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

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [`STRB_W-1:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,
  input mem1_rsp_page_fault_i,

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
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o,
  output pending_load_branch_dep_o
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
  wire pending_load0_valid_w;
  wire [PHY_REG_ADDR_W-1:0] pending_load0_pdest_w;
  wire pending_load1_valid_w;
  wire [PHY_REG_ADDR_W-1:0] pending_load1_pdest_w;
  wire load_branch_fast_valid_w;
  wire [ROB_INDEX_W-1:0] load_branch_fast_rob_idx_w;
  wire [`XLEN-1:0] load_branch_fast_pc_w;
  wire [`XLEN-1:0] load_branch_fast_next_pc_w;
  wire [`XLEN-1:0] load_branch_fast_imm_w;
  wire [2:0] load_branch_fast_cmp_op_w;
  wire [PHY_REG_ADDR_W-1:0] load_branch_fast_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] load_branch_fast_src2_preg_w;
  wire load_branch_fast_wait_load0_w;
  wire load_branch_fast_wait_load1_w;

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
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),   // B2 ROB-walk：mispredict 控制流 rob_idx（与 mispredict 同拍）
    .branch_mispredict_valid_i(branch_resolve_mispredict_w),  // B2 片4：ROB-walk kill 触发
    .issue_mem_block_i(mem_issue_block_w),
    .pending_load0_valid_i(pending_load0_valid_w),
    .pending_load0_pdest_i(pending_load0_pdest_w),
    .pending_load1_valid_i(pending_load1_valid_w),
    .pending_load1_pdest_i(pending_load1_pdest_w),
    .dispatch0_valid_i(dispatch0_valid_i),
    .dispatch0_ready_o(dispatch0_ready_o),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch_i),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch_i),
    .dispatch0_rd_arch_i(dispatch0_rd_arch_i),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch1_valid_i(dispatch1_valid_i),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(dispatch1_ready_o),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch_i),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch_i),
    .dispatch1_rd_arch_i(dispatch1_rd_arch_i),
    .dispatch1_imm_i(dispatch1_imm_i),
    .wb0_valid_i(wb0_valid_w),
    .wb0_rob_idx_i(wb0_rob_idx_w),
    .wb0_pdest_i(wb0_pdest_w),
    .wb0_data_i(wb0_data_w),
    .wb0_exception_i(wb0_exception_w),
    .wb0_cause_i(wb0_cause_w),
    .wb0_tval_i(wb0_tval_w),
    .wb1_valid_i(wb1_valid_w),
    .wb1_rob_idx_i(wb1_rob_idx_w),
    .wb1_pdest_i(wb1_pdest_w),
    .wb1_data_i(wb1_data_w),
    .wb1_exception_i(wb1_exception_w),
    .wb1_cause_i(wb1_cause_w),
    .wb1_tval_i(wb1_tval_w),
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
    .issue0_imm_o(issue0_imm_w),
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
    .issue1_imm_o(issue1_imm_w),
    .dispatch0_fire_o(dispatch0_fire_w),
    .dispatch0_rob_idx_o(dispatch0_rob_idx_w),
    .dispatch0_pdest_o(dispatch0_pdest_w),
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
    .rob_head_idx_o(rob_head_idx_w),
    .rob_head_valid_o(rob_head_valid_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o),
    .pending_load_branch_dep_o(pending_load_branch_dep_o),
    .load_branch_fast_valid_o(load_branch_fast_valid_w),
    .load_branch_fast_rob_idx_o(load_branch_fast_rob_idx_w),
    .load_branch_fast_pc_o(load_branch_fast_pc_w),
    .load_branch_fast_next_pc_o(load_branch_fast_next_pc_w),
    .load_branch_fast_imm_o(load_branch_fast_imm_w),
    .load_branch_fast_cmp_op_o(load_branch_fast_cmp_op_w),
    .load_branch_fast_src1_preg_o(load_branch_fast_src1_preg_w),
    .load_branch_fast_src2_preg_o(load_branch_fast_src2_preg_w),
    .load_branch_fast_wait_load0_o(load_branch_fast_wait_load0_w),
    .load_branch_fast_wait_load1_o(load_branch_fast_wait_load1_w)
	  );

  wire [`XLEN-1:0] issue0_src1_data_w;
  wire [`XLEN-1:0] issue0_src2_data_w;
  wire [`XLEN-1:0] issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_data_w;
  wire [`XLEN-1:0] dispatch_branch_src1_data_w;
  wire [`XLEN-1:0] dispatch_branch_src2_data_w;
  wire [`XLEN-1:0] dispatch0_src1_data_w;
  wire [`XLEN-1:0] dispatch0_src2_data_w;
  wire [`XLEN-1:0] load_branch_fast_src1_data_w;
  wire [`XLEN-1:0] load_branch_fast_src2_data_w;

  wire dispatch0_branch_fire_w =
      dispatch0_fire_w && dispatch0_ctrl_i[`CTRL_BRANCH_BIT];
  // E8 删除：lane1 dispatch-branch 快解析恒禁用（原 dispatch_branch_fast_lane1_enable_w=1'b0
  // → dispatch_branch_from1_w 恒 0）。dispatch 同拍快解析只保留 lane0；dispatch1_branch_fire_w、
  // dispatch0 转发 ALU、from1 多路选择全部死硅，连同 lane1 来源一并移除。
  wire dispatch_branch_fast_candidate_w = dispatch0_branch_fire_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src1_preg_w = dispatch0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src2_preg_w = dispatch0_src2_preg_w;

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
    .read4_addr_i(dispatch_branch_src1_preg_w),
    .read4_data_o(dispatch_branch_src1_data_w),
    .read5_addr_i(dispatch_branch_src2_preg_w),
    .read5_data_o(dispatch_branch_src2_data_w),
    .read6_addr_i(dispatch0_src1_preg_w),
    .read6_data_o(dispatch0_src1_data_w),
    .read7_addr_i(dispatch0_src2_preg_w),
    .read7_data_o(dispatch0_src2_data_w),
    // E7 删除：load-branch-fast 死硅，read8/read9 地址接 0（保留端口，避免改 OooPhysRegFile）。
    .read8_addr_i({PHY_REG_ADDR_W{1'b0}}),
    .read8_data_o(load_branch_fast_src1_data_w),
    .read9_addr_i({PHY_REG_ADDR_W{1'b0}}),
    .read9_data_o(load_branch_fast_src2_data_w),
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
    .load_data_i({`XLEN{1'b0}}),
    .pc_plus4_i(issue0_next_pc_w),
    .imm_data_i(issue0_imm_w),
    .csr_data_i(issue0_imm_w),
    .wb_data_o(issue0_wb_data_w)
  );

  WBU u_wbu1 (
    .wb_sel_i(issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue1_exec_result_w),
    .load_data_i({`XLEN{1'b0}}),
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
    .store_data_i(issue0_src2_data_w),
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
    .store_data_i(issue1_src2_value_w),
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

  reg mem_pending_q;
  reg [ROB_INDEX_W-1:0] mem_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_pdest_q;
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
  reg mem_buffer_load_q;
  reg mem_buffer_store_q;
  reg [`XLEN-1:0] mem_buffer_eff_addr_q;
  reg [1:0] mem_buffer_size_q;
  reg mem_buffer_unsigned_q;
  reg [`XLEN-1:0] mem_buffer_wdata_q;
  reg [`STRB_W-1:0] mem_buffer_wstrb_q;
  reg mem1_pending_q;
  reg [ROB_INDEX_W-1:0] mem1_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem1_pdest_q;
  reg [`XLEN-1:0] mem1_eff_addr_q;
  reg [1:0] mem1_size_q;
  reg mem1_unsigned_q;

  assign pending_load0_valid_w =
      mem_pending_q && mem_load_q && !mem_store_q && !mem_amo_q;
  assign pending_load0_pdest_w = mem_pdest_q;
  assign pending_load1_valid_w = mem1_pending_q;
  assign pending_load1_pdest_w = mem1_pdest_q;

  wire [`XLEN-1:0] mem_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem_rsp_wdata_unused_w;
  wire [`STRB_W-1:0] mem_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem_rsp_load_data_w;
  wire mem_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem1_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem1_rsp_wdata_unused_w;
  wire [`STRB_W-1:0] mem1_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem1_rsp_load_data_w;
  wire mem1_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_write_addr_unused_w;
  wire [`XLEN-1:0] mem_amo_write_wdata_w;
  wire [`STRB_W-1:0] mem_amo_write_wstrb_w;
  wire [`XLEN-1:0] mem_amo_write_load_unused_w;
  wire mem_amo_write_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_old_value_w;
  wire [`XLEN-1:0] mem_amo_result_value_w;

  LSU u_mem_rsp_lsu (
    .eff_addr_i(mem_eff_addr_q),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(mem_size_q),
    .mem_unsigned_i(mem_unsigned_q),
    .mem_rdata_i(mem_rsp_rdata_i),
    .mem_addr_o(mem_rsp_addr_unused_w),
    .mem_wdata_o(mem_rsp_wdata_unused_w),
    .mem_wstrb_o(mem_rsp_wstrb_unused_w),
    .load_data_o(mem_rsp_load_data_w),
    .misaligned_o(mem_rsp_misaligned_unused_w)
  );

  LSU u_mem1_rsp_lsu (
    .eff_addr_i(mem1_eff_addr_q),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(mem1_size_q),
    .mem_unsigned_i(mem1_unsigned_q),
    .mem_rdata_i(mem1_rsp_rdata_i),
    .mem_addr_o(mem1_rsp_addr_unused_w),
    .mem_wdata_o(mem1_rsp_wdata_unused_w),
    .mem_wstrb_o(mem1_rsp_wstrb_unused_w),
    .load_data_o(mem1_rsp_load_data_w),
    .misaligned_o(mem1_rsp_misaligned_unused_w)
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

  wire issue0_mem_exception_w = issue0_is_amo_w && issue0_mem_misaligned_w;
  wire issue1_mem_exception_w = issue1_is_amo_w && issue1_mem_misaligned_w;
  wire issue_block_w =
      checkpoint_capture_i || checkpoint_quiesce_i;
  wire mem_rsp_wants_w = mem_pending_q && mem_rsp_valid_i && !flush_i;
  wire mem1_rsp_wants_w = mem1_pending_q && mem1_rsp_valid_i && !flush_i;
  assign mem_idle_o =
      !mem_pending_q && !mem1_pending_q && !mem_buffer_valid_q &&
      !mem_rsp_wants_w && !mem1_rsp_wants_w;
  wire [1:0] wb_free_count_w =
      {1'b0, !ex0_valid_q} + {1'b0, !ex1_valid_q};
  assign mem_rsp_ready_o = mem_rsp_wants_w &&
                           (wb_free_count_w != 2'b00);
  assign mem1_rsp_ready_o =
      mem1_rsp_wants_w &&
      (wb_free_count_w > {1'b0, mem_rsp_wants_w});
  wire mem_rsp_fire_w = mem_rsp_valid_i && mem_rsp_ready_o;
  wire mem1_rsp_fire_w = mem1_rsp_valid_i && mem1_rsp_ready_o;
  // AMO#2: 读阶段若 fault(error/page_fault),不得进入写阶段(否则病态 PMP W&!R 下会静默错写 +
  // rd 垃圾 + 无异常)。fault 时 mem_amo_read_rsp_w=0 → 走 mem_rsp_final_fire_w 经 mem_rsp_wb_cause_w
  // 报 LOAD fault(对齐 NEMU "AMO 先 Mr→Load fault"),且不写内存。常态(无 fault)行为不变。
  wire mem_amo_read_rsp_w =
      mem_rsp_fire_w && mem_amo_q && !mem_amo_lr_q && !mem_amo_sc_q &&
      !mem_amo_write_phase_q &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w;
  wire mem_request_slot_open_w = !mem_pending_q || mem_rsp_final_fire_w;
  wire mem1_request_slot_open_w = !mem1_pending_q || mem1_rsp_fire_w;
  wire issue1_dual_load_port1_candidate_w =
      issue0_is_load_w && !issue0_is_amo_w && !issue0_mem_exception_w &&
      issue1_is_load_w && !issue1_is_amo_w && !issue1_mem_exception_w &&
      issue0_mem_order_ready_w && issue1_mem_order_ready_w;
  wire issue1_dual_load_port1_ready_w =
      issue1_dual_load_port1_candidate_w &&
      !mem_buffer_valid_q &&
      mem_request_slot_open_w && mem_req_ready_i &&
      mem1_request_slot_open_w && mem1_req_ready_i;
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
  wire issue0_load_waits_for_inflight_store_w =
      issue0_is_load_w && !issue0_is_amo_w && rob_head_valid_w &&
      ((mem_pending_store_order_block_w &&
        rob_idx_older_than(mem_rob_idx_q, issue0_rob_idx_w, rob_head_idx_w)) ||
       (mem_buffer_store_order_block_w &&
        rob_idx_older_than(mem_buffer_rob_idx_q, issue0_rob_idx_w, rob_head_idx_w)));
  wire issue1_load_waits_for_inflight_store_w =
      issue1_is_load_w && !issue1_is_amo_w && rob_head_valid_w &&
      ((mem_pending_store_order_block_w &&
        rob_idx_older_than(mem_rob_idx_q, issue1_rob_idx_w, rob_head_idx_w)) ||
       (mem_buffer_store_order_block_w &&
        rob_idx_older_than(mem_buffer_rob_idx_q, issue1_rob_idx_w, rob_head_idx_w)));
  wire issue0_mem_order_ready_w =
      !issue0_is_mem_w ||
      (issue0_is_load_w && !issue0_is_amo_w &&
       !issue0_load_waits_for_inflight_store_w) ||
      (rob_head_valid_w && (issue0_rob_idx_w == rob_head_idx_w));
  wire issue1_mem_order_ready_w =
      !issue1_is_mem_w ||
      (issue1_is_load_w && !issue1_is_amo_w &&
       !issue1_load_waits_for_inflight_store_w) ||
      (rob_head_valid_w && (issue1_rob_idx_w == rob_head_idx_w));
  wire issue0_mem_can_fire_w =
      issue0_is_mem_w &&
      !mem_issue_block_w &&
      issue0_mem_order_ready_w &&
      (issue0_mem_exception_w ||
       (!mem_buffer_valid_q && mem_request_slot_open_w &&
        mem_req_ready_i) ||
       (!issue0_is_amo_w && mem_pending_q && !mem_rsp_fire_w &&
        !mem_buffer_valid_q));
  wire issue1_mem_can_fire_w =
      issue1_is_mem_w &&
      !mem_issue_block_w &&
      issue1_mem_order_ready_w &&
      (issue1_mem_exception_w ||
       (issue1_dual_load_port1_candidate_w ?
        issue1_dual_load_port1_ready_w :
        ((!issue0_is_mem_w || issue0_mem_exception_w) &&
        !mem_buffer_valid_q && mem_request_slot_open_w &&
         mem_req_ready_i)));

  wire mem_rsp_waiting_for_wb_w =
      (mem_rsp_wants_w && !mem_rsp_ready_o) ||
      (mem1_rsp_wants_w && !mem1_rsp_ready_o);
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
                          (!issue0_is_mem_w || issue0_mem_can_fire_w) &&
                          (!issue0_is_muldiv_w || muldiv_req_ready_w) &&
                          (!issue0_is_clmul_w || clmul_req_ready_w);
  assign issue1_ready_w = !flush_i && !issue_block_w &&
                          !mem_rsp_waiting_for_wb_w &&
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
  wire issue0_is_ctrlflow_w =
      issue0_is_branch_w || (mode_walk_w && (issue0_is_jal_w || issue0_is_jalr_w));
  wire issue1_is_ctrlflow_w =
      issue1_is_branch_w || (mode_walk_w && (issue1_is_jal_w || issue1_is_jalr_w));
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
  // 误预测 = 架构后继 PC ≠ 片1 threaded 的预测后继 PC，且非对齐异常（misaligned 走 trap，不走 redirect）。
  // mode 下「零方向投机」基线：每条控制流强制 mispredict→恒 redirect 到后端算的架构后继，
  // 不信任前端方向预测（堵住 pred_npc 与前端实际取指不一致的所有漏洞）。配合禁 dispatch-bypass，
  // wrong-path 只能经 FIFO 被 redirect 的 FIFO-clear 清掉。性能差（每条控制流 flush+重取），但功能正确——
  // 后续优化=精确 per-packet 预测后继使正确预测免于 redirect。
  // 【Wave3 尝试与回退记录】曾去掉 mode_walk_w|| 启用真预测：rv64ui --no-diff 退化 46/88
  //   (正确预测的分支保留投机 FIFO 后，某前端投机路径/域B边界交互产生 wrong-path 提交)。
  //   注意 difftest 无法直接定位该回归——所有 riscv-tests 启动码含 csrwi mnstatus(0x744)，
  //   DUT 与 NEMU 对该 CSR 处理不一致会让 --diff 在 0x800000e4 提前 abort（此发散 F2 前后皆有、
  //   属预存 difftest 覆盖缺口），需改用 ITRACE 诊断。属 B2 前端重构(统一 redirect 仲裁 +
  //   投机路径硬化)范畴，非本处两行可了。故保留强制项至 B2 落地。详见 known-issues #105。
  wire issue0_mispredict_w =
      (mode_walk_w || (issue0_ctrlflow_next_pc_w != issue0_pred_npc_w)) &&
      !issue0_ctrlflow_misaligned_w;
  wire issue1_mispredict_w =
      (mode_walk_w || (issue1_ctrlflow_next_pc_w != issue1_pred_npc_w)) &&
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

  // E8 删除：u_dispatch0_fast_alu（dispatch0 同拍转发 ALU）整块死硅。该 ALU 唯一去向是
  // 经 dispatch_branch_src1/2_dispatch0_match_w 把 dispatch0 结果同拍转发给 lane1 dispatch-branch，
  // 而 lane1 快解析已恒禁用（from1=0），故转发 ALU 及其 src/value/fast-ready/valid 支撑信号皆悬空。
  wire dispatch_branch_src1_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch_branch_src1_preg_w);
  wire dispatch_branch_src1_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch_branch_src1_preg_w);
  wire dispatch_branch_src2_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch_branch_src2_preg_w);
  wire dispatch_branch_src2_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch_branch_src2_preg_w);
  // E8 删除：dispatch_branch_src1/2_dispatch0_match_w 以 from1 为与项恒 0，连同 base_ready 的
  // from1 多路选择一并化简为 lane0 直通。
  wire dispatch_branch_src1_base_ready_w = dispatch0_src1_ready_w;
  wire dispatch_branch_src2_base_ready_w = dispatch0_src2_ready_w;
  wire dispatch_branch_src1_ready_w =
      dispatch_branch_src1_base_ready_w ||
      dispatch_branch_src1_issue0_match_w ||
      dispatch_branch_src1_issue1_match_w;
  wire dispatch_branch_src2_ready_w =
      dispatch_branch_src2_base_ready_w ||
      dispatch_branch_src2_issue0_match_w ||
      dispatch_branch_src2_issue1_match_w;
  wire dispatch_branch_ready_w =
      dispatch_branch_fast_candidate_w &&
      dispatch_branch_src1_ready_w && dispatch_branch_src2_ready_w;

  // E8 删除：dispatch0_match/from1 项恒 0，src value 与 pc/imm/cmp_op 化简为 lane0 直通。
  wire [`XLEN-1:0] dispatch_branch_src1_value_w =
      dispatch_branch_src1_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src1_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src1_data_w;
  wire [`XLEN-1:0] dispatch_branch_src2_value_w =
      dispatch_branch_src2_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src2_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src2_data_w;
  wire [`XLEN-1:0] dispatch_branch_pc_w = dispatch0_pc_i;
  wire [`XLEN-1:0] dispatch_branch_fallthrough_w = dispatch0_next_pc_i;
  wire [`XLEN-1:0] dispatch_branch_imm_w = dispatch0_imm_i;
  wire [2:0] dispatch_branch_cmp_op_w =
      dispatch0_ctrl_i[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
  wire dispatch_branch_taken_w;
  wire [`XLEN-1:0] dispatch_branch_target_w =
      dispatch_branch_pc_w + dispatch_branch_imm_w;
  wire [`XLEN-1:0] dispatch_branch_next_pc_w =
      dispatch_branch_taken_w ? dispatch_branch_target_w :
                                dispatch_branch_fallthrough_w;
  wire dispatch_branch_misaligned_w =
      dispatch_branch_taken_w && dispatch_branch_target_w[0];
  wire [ROB_INDEX_W-1:0] dispatch_branch_rob_idx_w = dispatch0_rob_idx_w;

  localparam FAST_BRANCH_TRACK_ENTRIES = 8;
  localparam FAST_BRANCH_TRACK_INDEX_W = 3;

  reg fast_branch_valid_q [0:FAST_BRANCH_TRACK_ENTRIES-1];
  reg [ROB_INDEX_W-1:0] fast_branch_rob_idx_q
      [0:FAST_BRANCH_TRACK_ENTRIES-1];

  reg issue0_fast_branch_suppressed_r;
  reg issue1_fast_branch_suppressed_r;
  reg [FAST_BRANCH_TRACK_INDEX_W-1:0] issue0_fast_branch_idx_r;
  reg [FAST_BRANCH_TRACK_INDEX_W-1:0] issue1_fast_branch_idx_r;
  reg fast_branch_alloc_ready_r;
  reg [FAST_BRANCH_TRACK_INDEX_W-1:0] fast_branch_alloc_idx_r;
  integer fast_branch_scan_i;
  integer fast_branch_track_i;

  always @(*) begin
    issue0_fast_branch_suppressed_r = 1'b0;
    issue1_fast_branch_suppressed_r = 1'b0;
    issue0_fast_branch_idx_r = {FAST_BRANCH_TRACK_INDEX_W{1'b0}};
    issue1_fast_branch_idx_r = {FAST_BRANCH_TRACK_INDEX_W{1'b0}};
    fast_branch_alloc_ready_r = 1'b0;
    fast_branch_alloc_idx_r = {FAST_BRANCH_TRACK_INDEX_W{1'b0}};
    for (fast_branch_scan_i = 0;
         fast_branch_scan_i < FAST_BRANCH_TRACK_ENTRIES;
         fast_branch_scan_i = fast_branch_scan_i + 1) begin
      if (fast_branch_valid_q[fast_branch_scan_i] &&
          issue0_branch_fire_w &&
          (fast_branch_rob_idx_q[fast_branch_scan_i] == issue0_rob_idx_w) &&
          !issue0_fast_branch_suppressed_r) begin
        issue0_fast_branch_suppressed_r = 1'b1;
        issue0_fast_branch_idx_r =
            fast_branch_scan_i[FAST_BRANCH_TRACK_INDEX_W-1:0];
      end
      if (fast_branch_valid_q[fast_branch_scan_i] &&
          issue1_branch_fire_w &&
          (fast_branch_rob_idx_q[fast_branch_scan_i] == issue1_rob_idx_w) &&
          !issue1_fast_branch_suppressed_r) begin
        issue1_fast_branch_suppressed_r = 1'b1;
        issue1_fast_branch_idx_r =
            fast_branch_scan_i[FAST_BRANCH_TRACK_INDEX_W-1:0];
      end
      if ((!fast_branch_valid_q[fast_branch_scan_i] ||
           (issue0_fast_branch_suppressed_r &&
            (issue0_fast_branch_idx_r ==
             fast_branch_scan_i[FAST_BRANCH_TRACK_INDEX_W-1:0])) ||
           (issue1_fast_branch_suppressed_r &&
            (issue1_fast_branch_idx_r ==
             fast_branch_scan_i[FAST_BRANCH_TRACK_INDEX_W-1:0]))) &&
          !fast_branch_alloc_ready_r) begin
        fast_branch_alloc_ready_r = 1'b1;
        fast_branch_alloc_idx_r =
            fast_branch_scan_i[FAST_BRANCH_TRACK_INDEX_W-1:0];
      end
    end
  end

  wire issue0_fast_branch_suppressed_w = issue0_fast_branch_suppressed_r;
  wire issue1_fast_branch_suppressed_w = issue1_fast_branch_suppressed_r;
  wire dispatch_branch_same_cycle_issue_w =
      (issue0_branch_fire_w && (issue0_rob_idx_w == dispatch_branch_rob_idx_w)) ||
      (issue1_branch_fire_w && (issue1_rob_idx_w == dispatch_branch_rob_idx_w));
  wire dispatch_branch_fast_resolve_w =
      dispatch_branch_ready_w &&
      (dispatch_branch_same_cycle_issue_w || fast_branch_alloc_ready_r);
  wire dispatch_branch_track_push_w =
      dispatch_branch_fast_resolve_w && !dispatch_branch_same_cycle_issue_w;

  CompareUnit u_dispatch_branch_compare (
    .lhs_i(dispatch_branch_src1_value_w),
    .rhs_i(dispatch_branch_src2_value_w),
    .cmp_op_i(dispatch_branch_cmp_op_w),
    .cmp_true_o(dispatch_branch_taken_w)
  );

  // E7 删除：load-branch-fast 投机解析路径整条死硅。唯一使能 load_branch_fast_resolve_w
  // 原硬接 1'b0，故 u_load_branch_fast_compare、其 rsp/src-value 转发、target/taken/
  // resolve_next_pc/misaligned 全无真实读者，连同悬空的 rsp_w/pc_match_w 一并移除。
  // dispatch backend 输出的 load_branch_fast_* 与 PRF read8/9 数据改由 unused-OR 收口。
  wire fast_branch_track_push_w = dispatch_branch_track_push_w;
  wire [ROB_INDEX_W-1:0] fast_branch_track_rob_idx_w = dispatch_branch_rob_idx_w;

  wire issue0_mem_request_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      mem_request_slot_open_w && mem_req_ready_i && !mem_buffer_valid_q;
  wire issue0_mem_buffer_fire_w =
      issue0_fire_w && issue0_is_mem_w && !issue0_is_amo_w &&
      !issue0_mem_exception_w &&
      mem_pending_q && !mem_rsp_fire_w && !mem_buffer_valid_q;
  wire mem_buffer_req_valid_w =
      mem_buffer_valid_q && mem_request_slot_open_w;
  wire mem_buffer_req_fire_w = mem_buffer_req_valid_w && mem_req_ready_i;
  wire issue0_mem_req_valid_w =
      issue0_valid_w && issue0_is_mem_w && !issue0_mem_exception_w &&
      mem_request_slot_open_w && !mem_buffer_valid_q && !flush_i &&
      !issue_block_w && !mem_issue_block_w && issue0_mem_order_ready_w;
  wire issue1_mem_request_fire_w =
      issue1_fire_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      !issue0_is_mem_w && mem_request_slot_open_w && mem_req_ready_i &&
      !mem_buffer_valid_q;
  wire issue1_mem1_request_fire_w =
      issue1_fire_w && issue1_is_load_w && !issue1_mem_exception_w &&
      issue1_dual_load_port1_ready_w;
  wire issue1_mem_buffer_fire_w =
      1'b0;
  wire issue1_mem_req_valid_w =
      issue1_valid_w && issue1_is_mem_w && !issue1_mem_exception_w &&
      !issue0_is_mem_w && mem_request_slot_open_w && !mem_buffer_valid_q &&
      !flush_i && !issue_block_w && !mem_issue_block_w &&
      issue1_mem_order_ready_w;
  wire issue1_mem1_req_valid_w =
      issue1_valid_w && issue1_is_load_w && !issue1_mem_exception_w &&
      issue1_dual_load_port1_ready_w &&
      !flush_i && !issue_block_w && !mem_issue_block_w;
  wire issue0_mem_req_write_w =
      issue0_is_store_w && (!issue0_is_amo_w || issue0_is_sc_w);
  wire issue1_mem_req_write_w =
      issue1_is_store_w && (!issue1_is_amo_w || issue1_is_sc_w);
  wire mem_amo_write_req_valid_w =
      mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
      !mem_amo_write_sent_q && !flush_i;

  assign mem_req_valid_o = mem_amo_write_req_valid_w ||
                           mem_buffer_req_valid_w || issue0_mem_req_valid_w ||
                           issue1_mem_req_valid_w;
  assign mem_req_write_o = mem_amo_write_req_valid_w ? 1'b1 :
                           mem_buffer_req_valid_w ? mem_buffer_store_q :
                           issue0_mem_req_valid_w ? issue0_mem_req_write_w :
                                                    issue1_mem_req_write_w;
  assign mem_req_addr_o = mem_amo_write_req_valid_w ?
                          mem_eff_addr_q :
                          mem_buffer_req_valid_w ? mem_buffer_eff_addr_q :
                          issue0_mem_req_valid_w ? issue0_mem_addr_w :
                                                   issue1_mem_addr_w;
  assign mem_req_wdata_o = mem_amo_write_req_valid_w ? mem_amo_write_data_q :
                           mem_buffer_req_valid_w ? mem_buffer_wdata_q :
                           issue0_mem_req_valid_w ? issue0_mem_wdata_w :
                                                    issue1_mem_wdata_w;
  assign mem_req_wstrb_o = mem_amo_write_req_valid_w ? mem_amo_write_wstrb_q :
                           mem_buffer_req_valid_w ? mem_buffer_wstrb_q :
                           issue0_mem_req_valid_w ? issue0_mem_wstrb_w :
                                                    issue1_mem_wstrb_w;
  assign mem1_req_valid_o = issue1_mem1_req_valid_w;
  assign mem1_req_write_o = 1'b0;
  assign mem1_req_addr_o = issue1_mem_addr_w;
  assign mem1_req_wdata_o = {`XLEN{1'b0}};
  assign mem1_req_wstrb_o = {`STRB_W{1'b0}};
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
      mem1_pending_q <= 1'b0;
      mem1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem1_eff_addr_q <= {`XLEN{1'b0}};
      mem1_size_q <= 2'b00;
      mem1_unsigned_q <= 1'b0;
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
      for (fast_branch_track_i = 0;
           fast_branch_track_i < FAST_BRANCH_TRACK_ENTRIES;
           fast_branch_track_i = fast_branch_track_i + 1) begin
        fast_branch_valid_q[fast_branch_track_i] <= 1'b0;
        fast_branch_rob_idx_q[fast_branch_track_i] <= {ROB_INDEX_W{1'b0}};
      end
    end else begin
      if (issue0_fast_branch_suppressed_w) begin
        fast_branch_valid_q[issue0_fast_branch_idx_r] <= 1'b0;
        fast_branch_rob_idx_q[issue0_fast_branch_idx_r] <= {ROB_INDEX_W{1'b0}};
      end
      if (issue1_fast_branch_suppressed_w) begin
        fast_branch_valid_q[issue1_fast_branch_idx_r] <= 1'b0;
        fast_branch_rob_idx_q[issue1_fast_branch_idx_r] <= {ROB_INDEX_W{1'b0}};
      end
      if (fast_branch_track_push_w) begin
        fast_branch_valid_q[fast_branch_alloc_idx_r] <= 1'b1;
        fast_branch_rob_idx_q[fast_branch_alloc_idx_r] <=
            fast_branch_track_rob_idx_w;
      end

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
      end
      if (mem1_rsp_fire_w) begin
        mem1_pending_q <= 1'b0;
        mem1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem1_eff_addr_q <= {`XLEN{1'b0}};
        mem1_size_q <= 2'b00;
        mem1_unsigned_q <= 1'b0;
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
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue0_rob_idx_w;
        mem_pdest_q <= issue0_pdest_w;
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
      end
      if (issue1_mem_request_fire_w) begin
        if (issue1_mem_req_write_w && !issue1_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= issue1_rob_idx_w;
        mem_pdest_q <= issue1_pdest_w;
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
      end
      if (issue1_mem1_request_fire_w) begin
        mem1_pending_q <= 1'b1;
        mem1_rob_idx_q <= issue1_rob_idx_w;
        mem1_pdest_q <= issue1_pdest_w;
        mem1_eff_addr_q <= issue1_alu_result_w;
        mem1_size_q <= issue1_ctrl_w[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem1_unsigned_q <= issue1_ctrl_w[`CTRL_MEM_UNSIGNED_BIT];
      end
      if (mem_buffer_req_fire_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= mem_buffer_rob_idx_q;
        mem_pdest_q <= mem_buffer_pdest_q;
        mem_load_q <= mem_buffer_load_q;
        mem_store_q <= mem_buffer_store_q;
        mem_amo_q <= 1'b0;
        mem_amo_lr_q <= 1'b0;
        mem_amo_sc_q <= 1'b0;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= mem_buffer_eff_addr_q;
        mem_size_q <= mem_buffer_size_q;
        mem_unsigned_q <= mem_buffer_unsigned_q;
        mem_amo_inst_q <= {`INST_W{1'b0}};
        mem_amo_src2_q <= {`XLEN{1'b0}};
      end
      if (issue0_mem_buffer_fire_w) begin
        if (issue0_is_store_w && !issue0_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
        end
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= issue0_rob_idx_w;
        mem_buffer_pdest_q <= issue0_pdest_w;
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
                     (!issue0_is_mem_w || issue0_mem_exception_w);
      if (issue0_fire_w && !issue0_is_mem_w && !issue0_is_muldiv_w &&
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
                     (!issue1_is_mem_w || issue1_mem_exception_w);
      if (issue1_fire_w && !issue1_is_muldiv_w && !issue1_is_clmul_w) begin
        ex1_rob_idx_q <= issue1_rob_idx_w;
        ex1_pdest_q <= issue1_pdest_w;
        ex1_result_q <= issue1_mem_exception_w ? {`XLEN{1'b0}} :
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

  wire mem_rsp_to_wb0_w = mem_rsp_final_fire_w && !ex0_valid_q;
  wire mem_rsp_to_wb1_w = mem_rsp_final_fire_w && !mem_rsp_to_wb0_w;
  wire mem1_rsp_to_wb0_w =
      mem1_rsp_fire_w && !ex0_valid_q && !mem_rsp_to_wb0_w;
  wire mem1_rsp_to_wb1_w = mem1_rsp_fire_w && !mem1_rsp_to_wb0_w;
  wire muldiv_rsp_to_wb0_w =
      muldiv_resp_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w &&
      !mem1_rsp_to_wb0_w;
  wire muldiv_rsp_to_wb1_w =
      muldiv_resp_valid_w && !muldiv_rsp_to_wb0_w && !ex1_valid_q &&
      !mem_rsp_to_wb1_w && !mem1_rsp_to_wb1_w;
  wire clmul_rsp_to_wb0_w =
      clmul_resp_valid_w && !ex0_valid_q && !mem_rsp_to_wb0_w &&
      !mem1_rsp_to_wb0_w && !muldiv_rsp_to_wb0_w;
  wire clmul_rsp_to_wb1_w =
      clmul_resp_valid_w && !clmul_rsp_to_wb0_w && !ex1_valid_q &&
      !mem_rsp_to_wb1_w && !mem1_rsp_to_wb1_w && !muldiv_rsp_to_wb1_w;
  wire [`XLEN-1:0] mem_rsp_wb_data_w =
      mem_amo_q ? (mem_amo_sc_q ? {`XLEN{1'b0}} :
                   (mem_amo_write_phase_q ? mem_amo_old_value_q :
                                            mem_amo_old_value_w)) :
      mem_load_q ? mem_rsp_load_data_w : {`XLEN{1'b0}};
  wire [`TRAP_CAUSE_W-1:0] mem_rsp_wb_cause_w =
      mem_rsp_page_fault_i ?
      ((mem_store_q || (mem_amo_q && (mem_amo_sc_q || mem_amo_write_phase_q))) ?
       `EXC_STORE_PAGE_FAULT : `EXC_LOAD_PAGE_FAULT) :
      ((mem_store_q || (mem_amo_q && (mem_amo_sc_q || mem_amo_write_phase_q))) ?
       `EXC_STORE_ACCESS_FAULT : `EXC_LOAD_ACCESS_FAULT);
  wire [`XLEN-1:0] mem1_rsp_wb_data_w = mem1_rsp_load_data_w;

  assign muldiv_resp_ready_w = muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w;
  assign clmul_resp_ready_w = clmul_rsp_to_wb0_w || clmul_rsp_to_wb1_w;

  assign wb0_valid_w =
      ex0_valid_q || mem_rsp_to_wb0_w || mem1_rsp_to_wb0_w ||
      muldiv_rsp_to_wb0_w || clmul_rsp_to_wb0_w;
  assign wb0_rob_idx_w = ex0_valid_q ? ex0_rob_idx_q :
                         mem_rsp_to_wb0_w ? mem_rob_idx_q :
                         mem1_rsp_to_wb0_w ? mem1_rob_idx_q :
                         muldiv_rsp_to_wb0_w ? muldiv_resp_rob_idx_w :
                                               clmul_resp_rob_idx_w;
  assign wb0_pdest_w = ex0_valid_q ? ex0_pdest_q :
                       mem_rsp_to_wb0_w ? mem_pdest_q :
                       mem1_rsp_to_wb0_w ? mem1_pdest_q :
                       muldiv_rsp_to_wb0_w ? muldiv_resp_pdest_w :
                                             clmul_resp_pdest_w;
  assign wb0_data_w = ex0_valid_q ? ex0_result_q :
                      mem_rsp_to_wb0_w ? mem_rsp_wb_data_w :
                      mem1_rsp_to_wb0_w ? mem1_rsp_wb_data_w :
                      muldiv_rsp_to_wb0_w ? muldiv_resp_data_w :
                                            clmul_resp_data_w;
  assign wb0_exception_w = ex0_valid_q ? ex0_exception_q :
                           mem_rsp_to_wb0_w ? mem_rsp_error_i :
                           mem1_rsp_to_wb0_w ? mem1_rsp_error_i :
                                               1'b0;
  assign wb0_cause_w = ex0_valid_q ? ex0_cause_q :
                       mem_rsp_to_wb0_w ? mem_rsp_wb_cause_w :
                       mem1_rsp_to_wb0_w ? (mem1_rsp_page_fault_i ?
                                            `EXC_LOAD_PAGE_FAULT :
                                            `EXC_LOAD_ACCESS_FAULT) :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb0_tval_w = ex0_valid_q ? ex0_tval_q :
                      mem_rsp_to_wb0_w ? mem_eff_addr_q :
                      mem1_rsp_to_wb0_w ? mem1_eff_addr_q :
                                          {`XLEN{1'b0}};
  assign wb1_valid_w =
      ex1_valid_q || mem_rsp_to_wb1_w || mem1_rsp_to_wb1_w ||
      muldiv_rsp_to_wb1_w || clmul_rsp_to_wb1_w;
  assign wb1_rob_idx_w = ex1_valid_q ? ex1_rob_idx_q :
                         mem_rsp_to_wb1_w ? mem_rob_idx_q :
                         mem1_rsp_to_wb1_w ? mem1_rob_idx_q :
                         muldiv_rsp_to_wb1_w ? muldiv_resp_rob_idx_w :
                                               clmul_resp_rob_idx_w;
  assign wb1_pdest_w = ex1_valid_q ? ex1_pdest_q :
                       mem_rsp_to_wb1_w ? mem_pdest_q :
                       mem1_rsp_to_wb1_w ? mem1_pdest_q :
                       muldiv_rsp_to_wb1_w ? muldiv_resp_pdest_w :
                                             clmul_resp_pdest_w;
  assign wb1_data_w = ex1_valid_q ? ex1_result_q :
                      mem_rsp_to_wb1_w ? mem_rsp_wb_data_w :
                      mem1_rsp_to_wb1_w ? mem1_rsp_wb_data_w :
                      muldiv_rsp_to_wb1_w ? muldiv_resp_data_w :
                                            clmul_resp_data_w;
  assign wb1_exception_w = ex1_valid_q ? ex1_exception_q :
                           mem_rsp_to_wb1_w ? mem_rsp_error_i :
                           mem1_rsp_to_wb1_w ? mem1_rsp_error_i :
                                               1'b0;
  assign wb1_cause_w = ex1_valid_q ? ex1_cause_q :
                       mem_rsp_to_wb1_w ? mem_rsp_wb_cause_w :
                       mem1_rsp_to_wb1_w ? (mem1_rsp_page_fault_i ?
                                            `EXC_LOAD_PAGE_FAULT :
                                            `EXC_LOAD_ACCESS_FAULT) :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb1_tval_w = ex1_valid_q ? ex1_tval_q :
                      mem_rsp_to_wb1_w ? mem_eff_addr_q :
                      mem1_rsp_to_wb1_w ? mem1_eff_addr_q :
                                          {`XLEN{1'b0}};

  assign execute0_valid_o = wb0_valid_w;
  assign execute1_valid_o = wb1_valid_w;
  wire issue0_resolve_emit_w =
      issue0_ctrlflow_fire_w && !issue0_fast_branch_suppressed_w;
  wire issue1_resolve_emit_w =
      issue1_ctrlflow_fire_w && !issue1_fast_branch_suppressed_w;
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
  // 片2 计算、片4 接线导出：被选中 lane 的 mispredict 脉冲（mode=1 驱动 ROB-walk kill + redirect）。
  wire branch_resolve_mispredict_w =
      branch_resolve_pick1_w ? issue1_redirect_w : issue0_redirect_w;
  assign branch_resolve_mispredict_o = branch_resolve_mispredict_w;
  // E7 删除后：load_branch_fast_resolve_w 恒 0，dispatch_branch_resolve_* 只保留 lane0 dispatch 快解析。
  assign dispatch_branch_resolve_valid_o = dispatch_branch_fast_resolve_w;
  assign dispatch_branch_resolve_pc_o =
      dispatch_branch_fast_resolve_w ? dispatch_branch_pc_w : {`XLEN{1'b0}};
  assign dispatch_branch_resolve_next_pc_o =
      dispatch_branch_fast_resolve_w ? dispatch_branch_next_pc_w : {`XLEN{1'b0}};
  assign dispatch_branch_resolve_misaligned_o =
      dispatch_branch_fast_resolve_w && dispatch_branch_misaligned_w;

  // E7 删除后：dispatch backend 的 load_branch_fast_* 输出、PRF read8/9 数据、以及
  // pending_branch_fast_* 输入全部悬空（其消费逻辑随死硅移除），统一 reduction-OR 收口。
  wire unused_load_branch_fast_w =
      load_branch_fast_valid_w |
      (|load_branch_fast_rob_idx_w) |
      (|load_branch_fast_pc_w) |
      (|load_branch_fast_next_pc_w) |
      (|load_branch_fast_imm_w) |
      (|load_branch_fast_cmp_op_w) |
      (|load_branch_fast_src1_preg_w) |
      (|load_branch_fast_src2_preg_w) |
      load_branch_fast_wait_load0_w |
      load_branch_fast_wait_load1_w |
      (|load_branch_fast_src1_data_w) |
      (|load_branch_fast_src2_data_w) |
      pending_branch_fast_valid_i |
      (|pending_branch_fast_pc_i);

  wire unused_issue_payload_w =
      (|issue0_inst_w) | (|issue1_inst_w) |
      (|issue0_mem_load_unused_w) | (|issue1_mem_load_unused_w) |
      mem_store_q | mem_rsp_to_wb0_w | mem1_rsp_to_wb0_w |
      (|mem_rsp_addr_unused_w) | (|mem_rsp_wdata_unused_w) |
      (|mem_rsp_wstrb_unused_w) | mem_rsp_misaligned_unused_w |
      (|mem1_rsp_addr_unused_w) | (|mem1_rsp_wdata_unused_w) |
      (|mem1_rsp_wstrb_unused_w) | mem1_rsp_misaligned_unused_w;

`ifdef ROB_WALK_DEBUG
  always @(posedge clk) begin
    if (!rst && branch_resolve_valid_o)
      $display("[CF] mispred=%b pick1=%b | i0 emit=%b jalr=%b jal=%b br=%b rob=%0d pc=%h next=%h s1p=%0d s1v=%h imm=%h | i1 emit=%b jalr=%b rob=%0d pc=%h next=%h",
               branch_resolve_mispredict_w, branch_resolve_pick1_w,
               issue0_resolve_emit_w, issue0_is_jalr_w, issue0_is_jal_w, issue0_is_branch_w, issue0_rob_idx_w, issue0_pc_w, issue0_ctrlflow_next_pc_w, issue0_src1_preg_w, issue0_src1_data_w, issue0_imm_w,
               issue1_resolve_emit_w, issue1_is_jalr_w, issue1_rob_idx_w, issue1_pc_w, issue1_ctrlflow_next_pc_w);
  end
`endif

endmodule
