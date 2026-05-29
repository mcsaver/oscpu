`include "define.v"

// 真实指令到 OoO ALU-only 后端的接入适配层：
// 复用现有 DecodeStage 生成控制包，只允许基础 ALU 子集进入乱序后端。
module OooAluDecodeBackend #(
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

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  output dispatch0_unsupported_o,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  output dispatch1_unsupported_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [3:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [3:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,

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
  output execute0_valid_o,
  output execute1_valid_o,

  output branch_resolve_valid_o,
  output [`XLEN-1:0] branch_resolve_pc_o,
  output [`XLEN-1:0] branch_resolve_next_pc_o,
  output branch_resolve_misaligned_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o
);

  wire [`CTRL_BUS_W-1:0] decode0_ctrl_w;
  wire [`REG_ADDR_W-1:0] decode0_rs1_w;
  wire [`REG_ADDR_W-1:0] decode0_rs2_w;
  wire [`REG_ADDR_W-1:0] decode0_rd_w;
  wire [`XLEN-1:0] decode0_imm_w;

  wire [`CTRL_BUS_W-1:0] decode1_ctrl_w;
  wire [`REG_ADDR_W-1:0] decode1_rs1_w;
  wire [`REG_ADDR_W-1:0] decode1_rs2_w;
  wire [`REG_ADDR_W-1:0] decode1_rd_w;
  wire [`XLEN-1:0] decode1_imm_w;

  DecodeStage u_decode0 (
    .inst_i(dispatch0_inst_i),
    .ctrl_o(decode0_ctrl_w),
    .rs1_idx_o(decode0_rs1_w),
    .rs2_idx_o(decode0_rs2_w),
    .rd_idx_o(decode0_rd_w),
    .imm_o(decode0_imm_w)
  );

  DecodeStage u_decode1 (
    .inst_i(dispatch1_inst_i),
    .ctrl_o(decode1_ctrl_w),
    .rs1_idx_o(decode1_rs1_w),
    .rs2_idx_o(decode1_rs2_w),
    .rd_idx_o(decode1_rd_w),
    .imm_o(decode1_imm_w)
  );

  /* verilator lint_off UNUSEDSIGNAL */
  function ctrl_supported;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
	      ctrl_supported = ctrl[`CTRL_VALID_BIT] &&
	                       !ctrl[`CTRL_ILLEGAL_BIT] &&
	                       ctrl[`CTRL_NEED_EXEC_BIT] &&
	                       !ctrl[`CTRL_SYSTEM_BIT] &&
                       !ctrl[`CTRL_CSR_BIT] &&
                       !ctrl[`CTRL_MRET_BIT] &&
                       !ctrl[`CTRL_WFI_BIT];
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  wire dispatch0_supported_w = ctrl_supported(decode0_ctrl_w);
  wire dispatch1_supported_w = ctrl_supported(decode1_ctrl_w);
  /* verilator lint_off UNOPTFLAT */
  wire backend_dispatch0_valid_w = dispatch0_valid_i && dispatch0_supported_w;
  wire backend_dispatch1_valid_w = dispatch1_valid_i && dispatch1_supported_w;
  wire backend_dispatch0_ready_w;
  /* verilator lint_on UNOPTFLAT */
  wire backend_dispatch1_ready_w;

  assign dispatch0_ready_o = dispatch0_supported_w && backend_dispatch0_ready_w;
  assign dispatch1_ready_o = dispatch1_supported_w && backend_dispatch1_ready_w;
  assign dispatch0_unsupported_o = dispatch0_valid_i && !dispatch0_supported_w;
  assign dispatch1_unsupported_o = dispatch1_valid_i && !dispatch1_supported_w;

  OooIntBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_int_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .checkpoint_quiesce_i(checkpoint_quiesce_i),
    .mem_issue_block_i(mem_issue_block_i),
    .dispatch0_valid_i(backend_dispatch0_valid_w),
    .dispatch0_ready_o(backend_dispatch0_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(decode0_ctrl_w),
    .dispatch0_rs1_arch_i(decode0_rs1_w),
    .dispatch0_rs2_arch_i(decode0_rs2_w),
    .dispatch0_rd_arch_i(decode0_rd_w),
    .dispatch0_imm_i(decode0_imm_w),
    .dispatch1_valid_i(backend_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(backend_dispatch1_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(decode1_ctrl_w),
    .dispatch1_rs1_arch_i(decode1_rs1_w),
    .dispatch1_rs2_arch_i(decode1_rs2_w),
    .dispatch1_rd_arch_i(decode1_rd_w),
    .dispatch1_imm_i(decode1_imm_w),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem1_req_valid_o(mem1_req_valid_o),
    .mem1_req_ready_i(mem1_req_ready_i),
    .mem1_req_write_o(mem1_req_write_o),
    .mem1_req_addr_o(mem1_req_addr_o),
    .mem1_req_wdata_o(mem1_req_wdata_o),
    .mem1_req_wstrb_o(mem1_req_wstrb_o),
    .mem1_rsp_valid_i(mem1_rsp_valid_i),
    .mem1_rsp_ready_o(mem1_rsp_ready_o),
    .mem1_rsp_rdata_i(mem1_rsp_rdata_i),
    .mem1_rsp_error_i(mem1_rsp_error_i),
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
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
	    .issue_count_o(issue_count_o),
	    .execute0_valid_o(execute0_valid_o),
	    .execute1_valid_o(execute1_valid_o),
	    .branch_resolve_valid_o(branch_resolve_valid_o),
	    .branch_resolve_pc_o(branch_resolve_pc_o),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc_o),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned_o),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid_o),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc_o),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc_o),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned_o)
  );

endmodule
