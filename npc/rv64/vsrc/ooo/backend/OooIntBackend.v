`include "define.v"

// ALU-only OoO integer backend slice.  The frontend still supplies decoded uops;
// this module closes the loop from rename/issue through PRF read, dual ALU
// execute, writeback wakeup, and in-order ROB commit.
module OooIntBackend #(
  parameter PHY_REG_ADDR_W = 6,
  parameter ROB_INDEX_W = 4,
  parameter ROB_COUNT_W = 5,
  parameter FREE_COUNT_W = 7,
  parameter ISSUE_COUNT_W = 4
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
    .issue_mem_block_i(mem_issue_block_w),
    .pending_load0_valid_i(pending_load0_valid_w),
    .pending_load0_pdest_i(pending_load0_pdest_w),
    .pending_load1_valid_i(pending_load1_valid_w),
    .pending_load1_pdest_i(pending_load1_pdest_w),
    .dispatch0_valid_i(dispatch0_valid_i),
    .dispatch0_ready_o(dispatch0_ready_o),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
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
  wire dispatch1_branch_fire_w =
      dispatch1_fire_w && !dispatch1_optional_i &&
      dispatch1_ctrl_i[`CTRL_BRANCH_BIT];
  // lane1 branch 仍正常进入 IQ 执行；dispatch 同拍 fast resolve 只保留 lane0，
  // 避免 lane1 合成 payload 反向参与前端 ready/return-continuation 组合环。
  wire dispatch_branch_fast_lane1_enable_w = 1'b0;
  wire dispatch_branch_from1_w =
      dispatch_branch_fast_lane1_enable_w &&
      !dispatch1_optional_i && !dispatch0_branch_fire_w &&
      dispatch1_branch_fire_w;
  wire dispatch_branch_fast_candidate_w =
      dispatch0_branch_fire_w || dispatch_branch_from1_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src1_preg_w =
      dispatch_branch_from1_w ? dispatch1_src1_preg_w :
                                dispatch0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch_branch_src2_preg_w =
      dispatch_branch_from1_w ? dispatch1_src2_preg_w :
                                dispatch0_src2_preg_w;

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
    .read8_addr_i(load_branch_fast_src1_preg_w),
    .read8_data_o(load_branch_fast_src1_data_w),
    .read9_addr_i(load_branch_fast_src2_preg_w),
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

  function [`XLEN-1:0] amo_old_value;
    input [`XLEN-1:0] load_data;
    input [1:0] size;
    begin
      amo_old_value = (size == `MEM_SIZE_WORD) ?
                      sign_extend_word(load_data[31:0]) : load_data;
    end
  endfunction

  function [`XLEN-1:0] amo_result_value;
    input [`INST_W-1:0] inst;
    input [`XLEN-1:0] old_value;
    input [`XLEN-1:0] src2;
    input [1:0] size;
    reg signed [31:0] old_s32;
    reg signed [31:0] src_s32;
    reg signed [`XLEN-1:0] old_s64;
    reg signed [`XLEN-1:0] src_s64;
    reg [31:0] old_u32;
    reg [31:0] src_u32;
    reg [31:0] result32;
    begin
      old_s32 = old_value[31:0];
      src_s32 = src2[31:0];
      old_s64 = old_value;
      src_s64 = src2;
      old_u32 = old_value[31:0];
      src_u32 = src2[31:0];
      if (size == `MEM_SIZE_WORD) begin
        case (inst[31:27])
          5'b00001: result32 = src2[31:0];
          5'b00000: result32 = old_u32 + src_u32;
          5'b00100: result32 = old_u32 ^ src_u32;
          5'b01100: result32 = old_u32 & src_u32;
          5'b01000: result32 = old_u32 | src_u32;
          5'b10000: result32 = (old_s32 < src_s32) ? old_u32 : src_u32;
          5'b10100: result32 = (old_s32 > src_s32) ? old_u32 : src_u32;
          5'b11000: result32 = (old_u32 < src_u32) ? old_u32 : src_u32;
          5'b11100: result32 = (old_u32 > src_u32) ? old_u32 : src_u32;
          default:  result32 = old_u32;
        endcase
        amo_result_value = sign_extend_word(result32);
      end else begin
        case (inst[31:27])
          5'b00001: amo_result_value = src2;
          5'b00000: amo_result_value = old_value + src2;
          5'b00100: amo_result_value = old_value ^ src2;
          5'b01100: amo_result_value = old_value & src2;
          5'b01000: amo_result_value = old_value | src2;
          5'b10000: amo_result_value = (old_s64 < src_s64) ? old_value : src2;
          5'b10100: amo_result_value = (old_s64 > src_s64) ? old_value : src2;
          5'b11000: amo_result_value = (old_value < src2) ? old_value : src2;
          5'b11100: amo_result_value = (old_value > src2) ? old_value : src2;
          default:  amo_result_value = old_value;
        endcase
      end
    end
  endfunction

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

  function [3:0] bitmanip_clz8;
    input [7:0] value;
    begin
      casez (value)
        8'b1???????: bitmanip_clz8 = 4'd0;
        8'b01??????: bitmanip_clz8 = 4'd1;
        8'b001?????: bitmanip_clz8 = 4'd2;
        8'b0001????: bitmanip_clz8 = 4'd3;
        8'b00001???: bitmanip_clz8 = 4'd4;
        8'b000001??: bitmanip_clz8 = 4'd5;
        8'b0000001?: bitmanip_clz8 = 4'd6;
        8'b00000001: bitmanip_clz8 = 4'd7;
        default:     bitmanip_clz8 = 4'd8;
      endcase
    end
  endfunction

  function [3:0] bitmanip_ctz8;
    input [7:0] value;
    begin
      casez (value)
        8'b???????1: bitmanip_ctz8 = 4'd0;
        8'b??????10: bitmanip_ctz8 = 4'd1;
        8'b?????100: bitmanip_ctz8 = 4'd2;
        8'b????1000: bitmanip_ctz8 = 4'd3;
        8'b???10000: bitmanip_ctz8 = 4'd4;
        8'b??100000: bitmanip_ctz8 = 4'd5;
        8'b?1000000: bitmanip_ctz8 = 4'd6;
        8'b10000000: bitmanip_ctz8 = 4'd7;
        default:     bitmanip_ctz8 = 4'd8;
      endcase
    end
  endfunction

  function [3:0] bitmanip_popcount8;
    input [7:0] value;
    reg [1:0] pair0;
    reg [1:0] pair1;
    reg [1:0] pair2;
    reg [1:0] pair3;
    reg [2:0] nibble0;
    reg [2:0] nibble1;
    begin
      pair0 = {1'b0, value[0]} + {1'b0, value[1]};
      pair1 = {1'b0, value[2]} + {1'b0, value[3]};
      pair2 = {1'b0, value[4]} + {1'b0, value[5]};
      pair3 = {1'b0, value[6]} + {1'b0, value[7]};
      nibble0 = {1'b0, pair0} + {1'b0, pair1};
      nibble1 = {1'b0, pair2} + {1'b0, pair3};
      bitmanip_popcount8 = {1'b0, nibble0} + {1'b0, nibble1};
    end
  endfunction

  function [6:0] bitmanip_clz64;
    input [63:0] value;
    begin
      // Zbb count 类指令用 byte 级优先树表达，避免 64 次循环覆盖结果形成长组合链。
      if (value[63:56] != 8'b0)
        bitmanip_clz64 = {3'b000, bitmanip_clz8(value[63:56])};
      else if (value[55:48] != 8'b0)
        bitmanip_clz64 = 7'd8 + {3'b000, bitmanip_clz8(value[55:48])};
      else if (value[47:40] != 8'b0)
        bitmanip_clz64 = 7'd16 + {3'b000, bitmanip_clz8(value[47:40])};
      else if (value[39:32] != 8'b0)
        bitmanip_clz64 = 7'd24 + {3'b000, bitmanip_clz8(value[39:32])};
      else if (value[31:24] != 8'b0)
        bitmanip_clz64 = 7'd32 + {3'b000, bitmanip_clz8(value[31:24])};
      else if (value[23:16] != 8'b0)
        bitmanip_clz64 = 7'd40 + {3'b000, bitmanip_clz8(value[23:16])};
      else if (value[15:8] != 8'b0)
        bitmanip_clz64 = 7'd48 + {3'b000, bitmanip_clz8(value[15:8])};
      else if (value[7:0] != 8'b0)
        bitmanip_clz64 = 7'd56 + {3'b000, bitmanip_clz8(value[7:0])};
      else
        bitmanip_clz64 = 7'd64;
    end
  endfunction

  function [6:0] bitmanip_ctz64;
    input [63:0] value;
    begin
      if (value[7:0] != 8'b0)
        bitmanip_ctz64 = {3'b000, bitmanip_ctz8(value[7:0])};
      else if (value[15:8] != 8'b0)
        bitmanip_ctz64 = 7'd8 + {3'b000, bitmanip_ctz8(value[15:8])};
      else if (value[23:16] != 8'b0)
        bitmanip_ctz64 = 7'd16 + {3'b000, bitmanip_ctz8(value[23:16])};
      else if (value[31:24] != 8'b0)
        bitmanip_ctz64 = 7'd24 + {3'b000, bitmanip_ctz8(value[31:24])};
      else if (value[39:32] != 8'b0)
        bitmanip_ctz64 = 7'd32 + {3'b000, bitmanip_ctz8(value[39:32])};
      else if (value[47:40] != 8'b0)
        bitmanip_ctz64 = 7'd40 + {3'b000, bitmanip_ctz8(value[47:40])};
      else if (value[55:48] != 8'b0)
        bitmanip_ctz64 = 7'd48 + {3'b000, bitmanip_ctz8(value[55:48])};
      else if (value[63:56] != 8'b0)
        bitmanip_ctz64 = 7'd56 + {3'b000, bitmanip_ctz8(value[63:56])};
      else
        bitmanip_ctz64 = 7'd64;
    end
  endfunction

  function [6:0] bitmanip_cpop64;
    input [63:0] value;
    reg [3:0] pop0;
    reg [3:0] pop1;
    reg [3:0] pop2;
    reg [3:0] pop3;
    reg [3:0] pop4;
    reg [3:0] pop5;
    reg [3:0] pop6;
    reg [3:0] pop7;
    reg [4:0] sum01;
    reg [4:0] sum23;
    reg [4:0] sum45;
    reg [4:0] sum67;
    reg [5:0] sum0123;
    reg [5:0] sum4567;
    begin
      pop0 = bitmanip_popcount8(value[7:0]);
      pop1 = bitmanip_popcount8(value[15:8]);
      pop2 = bitmanip_popcount8(value[23:16]);
      pop3 = bitmanip_popcount8(value[31:24]);
      pop4 = bitmanip_popcount8(value[39:32]);
      pop5 = bitmanip_popcount8(value[47:40]);
      pop6 = bitmanip_popcount8(value[55:48]);
      pop7 = bitmanip_popcount8(value[63:56]);
      sum01 = {1'b0, pop0} + {1'b0, pop1};
      sum23 = {1'b0, pop2} + {1'b0, pop3};
      sum45 = {1'b0, pop4} + {1'b0, pop5};
      sum67 = {1'b0, pop6} + {1'b0, pop7};
      sum0123 = {1'b0, sum01} + {1'b0, sum23};
      sum4567 = {1'b0, sum45} + {1'b0, sum67};
      bitmanip_cpop64 = {1'b0, sum0123} + {1'b0, sum4567};
    end
  endfunction

  function [`XLEN-1:0] bitmanip_result;
    input [6:0] opcode;
    input [9:0] funct10;
    input [5:0] imm;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg [4:0] imm5;
    reg [5:0] shamt;
    reg [6:0] inv_shamt;
    begin
      imm5 = imm[4:0];
      shamt = src2[`SHIFT_AMT_W-1:0];
      inv_shamt = 7'd64 - {1'b0, shamt};
      bitmanip_result = {`XLEN{1'b0}};

      if (opcode == `OPCODE_OP_IMM) begin
        case (funct10)
          {7'h14, `FUNCT3_SLL},
          {7'h15, `FUNCT3_SLL}:     bitmanip_result = src1 | (64'h1 << imm);
          {7'h24, `FUNCT3_SLL},
          {7'h25, `FUNCT3_SLL}:     bitmanip_result = src1 & ~(64'h1 << imm);
          {7'h34, `FUNCT3_SLL},
          {7'h35, `FUNCT3_SLL}:     bitmanip_result = src1 ^ (64'h1 << imm);
          {7'h30, `FUNCT3_SRL_SRA},
          {7'h31, `FUNCT3_SRL_SRA}: bitmanip_result = (imm == 6'h0) ? src1 :
                                                     ((src1 >> imm) | (src1 << (7'd64 - {1'b0, imm})));
          {7'h24, `FUNCT3_SRL_SRA},
          {7'h25, `FUNCT3_SRL_SRA}: bitmanip_result = {{(`XLEN-1){1'b0}}, src1[imm]};
          {7'h14, `FUNCT3_SRL_SRA}: bitmanip_result = {
              (src1[63:56] != 8'h00) ? 8'hff : 8'h00,
              (src1[55:48] != 8'h00) ? 8'hff : 8'h00,
              (src1[47:40] != 8'h00) ? 8'hff : 8'h00,
              (src1[39:32] != 8'h00) ? 8'hff : 8'h00,
              (src1[31:24] != 8'h00) ? 8'hff : 8'h00,
              (src1[23:16] != 8'h00) ? 8'hff : 8'h00,
              (src1[15:8]  != 8'h00) ? 8'hff : 8'h00,
              (src1[7:0]   != 8'h00) ? 8'hff : 8'h00
          };
          {7'h34, `FUNCT3_SRL_SRA},
          {7'h35, `FUNCT3_SRL_SRA}: bitmanip_result = {src1[7:0], src1[15:8], src1[23:16], src1[31:24],
                                                     src1[39:32], src1[47:40], src1[55:48], src1[63:56]};
          {7'h30, `FUNCT3_SLL}: begin
            case (imm5)
              5'h00: bitmanip_result = {{(`XLEN-7){1'b0}},
                                         bitmanip_clz64(src1)};
              5'h01: bitmanip_result = {{(`XLEN-7){1'b0}},
                                         bitmanip_ctz64(src1)};
              5'h02: bitmanip_result = {{(`XLEN-7){1'b0}},
                                         bitmanip_cpop64(src1)};
              5'h04: bitmanip_result = {{(`XLEN-8){src1[7]}}, src1[7:0]};
              5'h05: bitmanip_result = {{(`XLEN-16){src1[15]}}, src1[15:0]};
              default: begin end
            endcase
          end
          default: begin end
        endcase
      end else if (opcode == `OPCODE_OP_IMM_32) begin
        case ({funct10[9:4], funct10[2:0]})
          {6'h02, `FUNCT3_SLL}: bitmanip_result = ({{(`XLEN-32){1'b0}}, src1[31:0]}) << imm;
          default: begin end
        endcase
      end else begin
        case (funct10)
          {7'h04, `FUNCT3_ADD_SUB}: bitmanip_result = {{(`XLEN-32){1'b0}}, src1[31:0]} + src2;
          {7'h10, `FUNCT3_SLT}:     bitmanip_result = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 1) + src2;
          {7'h10, `FUNCT3_XOR}:     bitmanip_result = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 2) + src2;
          {7'h10, `FUNCT3_OR}:      bitmanip_result = (((opcode == `OPCODE_OP_32) ? {{(`XLEN-32){1'b0}}, src1[31:0]} : src1) << 3) + src2;
          {7'h20, `FUNCT3_AND}:     bitmanip_result = src1 & ~src2;
          {7'h20, `FUNCT3_OR}:      bitmanip_result = src1 | ~src2;
          {7'h20, `FUNCT3_XOR}:     bitmanip_result = ~(src1 ^ src2);
          {7'h30, `FUNCT3_SLL}:     bitmanip_result = (shamt == 5'h0) ? src1 :
                                                     ((src1 << shamt) | (src1 >> inv_shamt));
          {7'h30, `FUNCT3_SRL_SRA}: bitmanip_result = (shamt == 5'h0) ? src1 :
                                                     ((src1 >> shamt) | (src1 << inv_shamt));
          {7'h05, `FUNCT3_XOR}:     bitmanip_result = ($signed(src1) < $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_SRL_SRA}: bitmanip_result = (src1 < src2) ? src1 : src2;
          {7'h05, `FUNCT3_OR}:      bitmanip_result = ($signed(src1) > $signed(src2)) ? src1 : src2;
          {7'h05, `FUNCT3_AND}:     bitmanip_result = (src1 > src2) ? src1 : src2;
          {7'h14, `FUNCT3_SLL}:     bitmanip_result = src1 | (64'h1 << shamt);
          {7'h24, `FUNCT3_SLL}:     bitmanip_result = src1 & ~(64'h1 << shamt);
          {7'h24, `FUNCT3_SRL_SRA}: bitmanip_result = {{(`XLEN-1){1'b0}}, src1[shamt]};
          {7'h34, `FUNCT3_SLL}:     bitmanip_result = src1 ^ (64'h1 << shamt);
          {7'h04, `FUNCT3_XOR}:     bitmanip_result = {{(`XLEN-16){1'b0}}, src1[15:0]};
          default: begin end
        endcase
      end
    end
  endfunction

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

  assign issue0_exec_result_w =
      issue0_ctrl_w[`CTRL_BITMANIP_BIT] ?
      bitmanip_result(issue0_inst_w[6:0], {issue0_inst_w[31:25], issue0_inst_w[14:12]},
                      issue0_inst_w[25:20], issue0_src1_data_w, issue0_src2_data_w) :
      issue0_alu_result_final_w;
  assign issue1_exec_result_w =
      issue1_ctrl_w[`CTRL_BITMANIP_BIT] ?
      bitmanip_result(issue1_inst_w[6:0], {issue1_inst_w[31:25], issue1_inst_w[14:12]},
                      issue1_inst_w[25:20], issue1_src1_value_w, issue1_src2_value_w) :
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

  assign mem_amo_old_value_w = amo_old_value(mem_rsp_load_data_w, mem_size_q);
  assign mem_amo_result_value_w =
      amo_result_value(mem_amo_inst_q, mem_amo_old_value_w,
                       mem_amo_src2_q, mem_size_q);

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

  wire issue0_mem_exception_w = issue0_is_mem_w && issue0_mem_misaligned_w;
  wire issue1_mem_exception_w = issue1_is_mem_w && issue1_mem_misaligned_w;
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
  wire mem_amo_read_rsp_w =
      mem_rsp_fire_w && mem_amo_q && !mem_amo_lr_q && !mem_amo_sc_q &&
      !mem_amo_write_phase_q;
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

  wire dispatch0_src1_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch0_src1_preg_w);
  wire dispatch0_src1_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch0_src1_preg_w);
  wire dispatch0_src2_issue0_match_w =
      issue0_current_result_valid_w &&
      (issue0_pdest_w == dispatch0_src2_preg_w);
  wire dispatch0_src2_issue1_match_w =
      issue1_current_result_valid_w &&
      (issue1_pdest_w == dispatch0_src2_preg_w);
  wire dispatch0_src1_fast_ready_w =
      dispatch0_src1_ready_w ||
      dispatch0_src1_issue0_match_w ||
      dispatch0_src1_issue1_match_w;
  wire dispatch0_src2_fast_ready_w =
      dispatch0_src2_ready_w ||
      dispatch0_src2_issue0_match_w ||
      dispatch0_src2_issue1_match_w;
  wire [`XLEN-1:0] dispatch0_src1_value_w =
      dispatch0_src1_issue1_match_w ? issue1_wb_data_w :
      dispatch0_src1_issue0_match_w ? issue0_wb_data_w :
                                      dispatch0_src1_data_w;
  wire [`XLEN-1:0] dispatch0_src2_value_w =
      dispatch0_src2_issue1_match_w ? issue1_wb_data_w :
      dispatch0_src2_issue0_match_w ? issue0_wb_data_w :
                                      dispatch0_src2_data_w;
  wire [`XLEN-1:0] dispatch0_fast_alu_src1_w =
      select_op1(dispatch0_ctrl_i[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 dispatch0_src1_value_w, dispatch0_pc_i);
  wire [`XLEN-1:0] dispatch0_fast_alu_src2_w =
      select_op2(dispatch0_ctrl_i[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 dispatch0_src2_value_w, dispatch0_imm_i);
  wire [`XLEN-1:0] dispatch0_fast_alu_raw_w;
  ALU u_dispatch0_fast_alu (
    .src1_i(dispatch0_fast_alu_src1_w),
    .src2_i(dispatch0_fast_alu_src2_w),
    .alu_op_i(dispatch0_ctrl_i[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(dispatch0_fast_alu_raw_w)
  );
  wire [`XLEN-1:0] dispatch0_fast_alu_result_w =
      dispatch0_ctrl_i[`CTRL_WORD_OP_BIT] ?
      rv64_word_alu_result(dispatch0_ctrl_i[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB],
                           dispatch0_fast_alu_src1_w,
                           dispatch0_fast_alu_src2_w) :
      dispatch0_fast_alu_raw_w;
  wire dispatch0_fast_alu_valid_w =
      dispatch0_fire_w &&
      dispatch0_ctrl_i[`CTRL_VALID_BIT] &&
      !dispatch0_ctrl_i[`CTRL_ILLEGAL_BIT] &&
      dispatch0_ctrl_i[`CTRL_NEED_EXEC_BIT] &&
      dispatch0_ctrl_i[`CTRL_RD_EN_BIT] &&
      (dispatch0_ctrl_i[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_ALU) &&
      !dispatch0_ctrl_i[`CTRL_BRANCH_BIT] &&
      !dispatch0_ctrl_i[`CTRL_JAL_BIT] &&
      !dispatch0_ctrl_i[`CTRL_JALR_BIT] &&
      !dispatch0_ctrl_i[`CTRL_LOAD_BIT] &&
      !dispatch0_ctrl_i[`CTRL_STORE_BIT] &&
      !dispatch0_ctrl_i[`CTRL_ECALL_BIT] &&
      !dispatch0_ctrl_i[`CTRL_EBREAK_BIT] &&
      !dispatch0_ctrl_i[`CTRL_FENCE_BIT] &&
      !dispatch0_ctrl_i[`CTRL_SYSTEM_BIT] &&
      !dispatch0_ctrl_i[`CTRL_MISC_MEM_BIT] &&
      !dispatch0_ctrl_i[`CTRL_CSR_BIT] &&
      !dispatch0_ctrl_i[`CTRL_MRET_BIT] &&
      !dispatch0_ctrl_i[`CTRL_WFI_BIT] &&
      !dispatch0_ctrl_i[`CTRL_MULDIV_BIT] &&
      !dispatch0_ctrl_i[`CTRL_BITMANIP_BIT] &&
      !dispatch0_ctrl_i[`CTRL_SFENCE_VMA_BIT] &&
      !dispatch0_ctrl_i[`CTRL_SRET_BIT] &&
      !dispatch0_ctrl_i[`CTRL_AMO_BIT] &&
      (dispatch0_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
      dispatch0_src1_fast_ready_w &&
      dispatch0_src2_fast_ready_w;
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
  wire dispatch_branch_src1_dispatch0_match_w =
      dispatch_branch_from1_w && dispatch0_fast_alu_valid_w &&
      (dispatch0_pdest_w == dispatch_branch_src1_preg_w);
  wire dispatch_branch_src2_dispatch0_match_w =
      dispatch_branch_from1_w && dispatch0_fast_alu_valid_w &&
      (dispatch0_pdest_w == dispatch_branch_src2_preg_w);

  wire dispatch_branch_src1_base_ready_w =
      dispatch_branch_from1_w ? dispatch1_src1_ready_w :
                                dispatch0_src1_ready_w;
  wire dispatch_branch_src2_base_ready_w =
      dispatch_branch_from1_w ? dispatch1_src2_ready_w :
                                dispatch0_src2_ready_w;
  wire dispatch_branch_src1_ready_w =
      dispatch_branch_src1_base_ready_w ||
      dispatch_branch_src1_dispatch0_match_w ||
      dispatch_branch_src1_issue0_match_w ||
      dispatch_branch_src1_issue1_match_w;
  wire dispatch_branch_src2_ready_w =
      dispatch_branch_src2_base_ready_w ||
      dispatch_branch_src2_dispatch0_match_w ||
      dispatch_branch_src2_issue0_match_w ||
      dispatch_branch_src2_issue1_match_w;
  wire dispatch_branch_ready_w =
      dispatch_branch_fast_candidate_w &&
      dispatch_branch_src1_ready_w && dispatch_branch_src2_ready_w;

  wire [`XLEN-1:0] dispatch_branch_src1_value_w =
      dispatch_branch_src1_dispatch0_match_w ? dispatch0_fast_alu_result_w :
      dispatch_branch_src1_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src1_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src1_data_w;
  wire [`XLEN-1:0] dispatch_branch_src2_value_w =
      dispatch_branch_src2_dispatch0_match_w ? dispatch0_fast_alu_result_w :
      dispatch_branch_src2_issue1_match_w ? issue1_wb_data_w :
      dispatch_branch_src2_issue0_match_w ? issue0_wb_data_w :
                                            dispatch_branch_src2_data_w;
  wire [`XLEN-1:0] dispatch_branch_pc_w =
      dispatch_branch_from1_w ? dispatch1_pc_i : dispatch0_pc_i;
  wire [`XLEN-1:0] dispatch_branch_fallthrough_w =
      dispatch_branch_from1_w ? dispatch1_next_pc_i : dispatch0_next_pc_i;
  wire [`XLEN-1:0] dispatch_branch_imm_w =
      dispatch_branch_from1_w ? dispatch1_imm_i : dispatch0_imm_i;
  wire [2:0] dispatch_branch_cmp_op_w =
      dispatch_branch_from1_w ?
      dispatch1_ctrl_i[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] :
      dispatch0_ctrl_i[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
  wire dispatch_branch_taken_w;
  wire [`XLEN-1:0] dispatch_branch_target_w =
      dispatch_branch_pc_w + dispatch_branch_imm_w;
  wire [`XLEN-1:0] dispatch_branch_next_pc_w =
      dispatch_branch_taken_w ? dispatch_branch_target_w :
                                dispatch_branch_fallthrough_w;
  wire dispatch_branch_misaligned_w =
      dispatch_branch_taken_w && dispatch_branch_target_w[0];
  wire [ROB_INDEX_W-1:0] dispatch_branch_rob_idx_w =
      dispatch_branch_from1_w ? dispatch1_rob_idx_w : dispatch0_rob_idx_w;

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

  wire load_branch_fast_rsp0_w =
      load_branch_fast_wait_load0_w &&
      mem_rsp_final_fire_w && mem_load_q && !mem_store_q && !mem_amo_q &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire load_branch_fast_rsp1_w =
      load_branch_fast_wait_load1_w &&
      mem1_rsp_fire_w && !mem1_rsp_error_i && !mem1_rsp_page_fault_i;
  wire load_branch_fast_rsp_w =
      load_branch_fast_rsp0_w || load_branch_fast_rsp1_w;
  wire load_branch_fast_pc_match_w =
      pending_branch_fast_valid_i &&
      (load_branch_fast_pc_w == pending_branch_fast_pc_i);
  wire load_branch_fast_src1_rsp0_w =
      load_branch_fast_rsp0_w &&
      (load_branch_fast_src1_preg_w == mem_pdest_q);
  wire load_branch_fast_src2_rsp0_w =
      load_branch_fast_rsp0_w &&
      (load_branch_fast_src2_preg_w == mem_pdest_q);
  wire load_branch_fast_src1_rsp1_w =
      load_branch_fast_rsp1_w &&
      (load_branch_fast_src1_preg_w == mem1_pdest_q);
  wire load_branch_fast_src2_rsp1_w =
      load_branch_fast_rsp1_w &&
      (load_branch_fast_src2_preg_w == mem1_pdest_q);
  wire [`XLEN-1:0] load_branch_fast_src1_value_w =
      load_branch_fast_src1_rsp0_w ? mem_rsp_load_data_w :
      load_branch_fast_src1_rsp1_w ? mem1_rsp_load_data_w :
                                     load_branch_fast_src1_data_w;
  wire [`XLEN-1:0] load_branch_fast_src2_value_w =
      load_branch_fast_src2_rsp0_w ? mem_rsp_load_data_w :
      load_branch_fast_src2_rsp1_w ? mem1_rsp_load_data_w :
                                     load_branch_fast_src2_data_w;
  wire load_branch_fast_resolve_w =
      1'b0;
  wire [`XLEN-1:0] load_branch_fast_target_w =
      load_branch_fast_pc_w + load_branch_fast_imm_w;
  wire load_branch_fast_taken_w;
  wire [`XLEN-1:0] load_branch_fast_resolve_next_pc_w =
      load_branch_fast_taken_w ? load_branch_fast_target_w :
                                 load_branch_fast_next_pc_w;
  wire load_branch_fast_misaligned_w =
      load_branch_fast_taken_w && load_branch_fast_target_w[0];
  wire fast_branch_track_push_w =
      dispatch_branch_track_push_w || load_branch_fast_resolve_w;
  wire [ROB_INDEX_W-1:0] fast_branch_track_rob_idx_w =
      load_branch_fast_resolve_w ? load_branch_fast_rob_idx_w :
                                   dispatch_branch_rob_idx_w;

  CompareUnit u_load_branch_fast_compare (
    .lhs_i(load_branch_fast_src1_value_w),
    .rhs_i(load_branch_fast_src2_value_w),
    .cmp_op_i(load_branch_fast_cmp_op_w),
    .cmp_true_o(load_branch_fast_taken_w)
  );

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
  wire [`XLEN-1:0] mem_buffer_aligned_addr_w =
      mem_buffer_eff_addr_q & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}};
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
                          (mem_eff_addr_q & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}}) :
                          mem_buffer_req_valid_w ? mem_buffer_aligned_addr_w :
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
        ex0_cause_q <= (issue0_is_load_w && !issue0_is_amo_w) ?
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
                       ((issue1_is_load_w && !issue1_is_amo_w) ?
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
  wire issue0_branch_resolve_emit_w =
      issue0_branch_fire_w && !issue0_fast_branch_suppressed_w;
  wire issue1_branch_resolve_emit_w =
      issue1_branch_fire_w && !issue1_fast_branch_suppressed_w;

  assign branch_resolve_valid_o =
      issue0_branch_resolve_emit_w || issue1_branch_resolve_emit_w;
  assign branch_resolve_pc_o =
      issue0_branch_resolve_emit_w ? issue0_pc_w : issue1_pc_w;
  assign branch_resolve_next_pc_o = issue0_branch_resolve_emit_w ?
                                    issue0_branch_next_pc_w :
                                    issue1_branch_next_pc_w;
  assign branch_resolve_misaligned_o =
      issue0_branch_resolve_emit_w ? (issue0_branch_taken_w &&
                                      issue0_branch_target_w[0]) :
                                     (issue1_branch_taken_w &&
                                      issue1_branch_target_w[0]);
  assign dispatch_branch_resolve_valid_o =
      dispatch_branch_fast_resolve_w || load_branch_fast_resolve_w;
  assign dispatch_branch_resolve_pc_o =
      load_branch_fast_resolve_w ? load_branch_fast_pc_w :
      dispatch_branch_fast_resolve_w ? dispatch_branch_pc_w : {`XLEN{1'b0}};
  assign dispatch_branch_resolve_next_pc_o =
      load_branch_fast_resolve_w ? load_branch_fast_resolve_next_pc_w :
      dispatch_branch_fast_resolve_w ? dispatch_branch_next_pc_w :
                                      {`XLEN{1'b0}};
  assign dispatch_branch_resolve_misaligned_o =
      load_branch_fast_resolve_w ? load_branch_fast_misaligned_w :
      (dispatch_branch_fast_resolve_w && dispatch_branch_misaligned_w);

  wire unused_issue_payload_w =
      (|issue0_inst_w) | (|issue1_inst_w) |
      (|issue0_mem_load_unused_w) | (|issue1_mem_load_unused_w) |
      mem_store_q | mem_rsp_to_wb0_w | mem1_rsp_to_wb0_w |
      (|mem_rsp_addr_unused_w) | (|mem_rsp_wdata_unused_w) |
      (|mem_rsp_wstrb_unused_w) | mem_rsp_misaligned_unused_w |
      (|mem1_rsp_addr_unused_w) | (|mem1_rsp_wdata_unused_w) |
      (|mem1_rsp_wstrb_unused_w) | mem1_rsp_misaligned_unused_w;

endmodule
