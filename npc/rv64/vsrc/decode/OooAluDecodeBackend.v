`include "define.v"

// 真实指令到 OoO ALU-only 后端的接入适配层：
// 复用现有 DecodeStage 生成控制包，只允许基础 ALU 子集进入乱序后端。
module OooAluDecodeBackend #(
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
  input [`XLEN-1:0] dispatch0_csr_rdata_i,
  output dispatch0_unsupported_o,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`XLEN-1:0] dispatch1_csr_rdata_i,
  output dispatch1_unsupported_o,

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
  output [ROB_INDEX_W-1:0] branch_resolve_rob_idx_o,
  output branch_resolve_mispredict_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o,
  output pending_load_branch_dep_o
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

  // 只把支持性判定位送入 helper，避免把整条控制总线当成伪消费者。
  function ctrl_supported;
    input ctrl_valid;
    input ctrl_illegal;
    input ctrl_need_exec;
    input ctrl_system;
    input ctrl_csr;
    input ctrl_mret;
    input ctrl_sret;
    input ctrl_wfi;
    input ctrl_sfence_vma;
    begin
      ctrl_supported = ctrl_valid &&
                       !ctrl_illegal &&
                       ctrl_need_exec &&
                       (!ctrl_system || ctrl_csr) &&
                       !ctrl_mret &&
                       !ctrl_sret &&
                       !ctrl_wfi &&
                       !ctrl_sfence_vma;
    end
  endfunction

  wire dispatch0_supported_w =
      ctrl_supported(decode0_ctrl_w[`CTRL_VALID_BIT],
                     decode0_ctrl_w[`CTRL_ILLEGAL_BIT],
                     decode0_ctrl_w[`CTRL_NEED_EXEC_BIT],
                     decode0_ctrl_w[`CTRL_SYSTEM_BIT],
                     decode0_ctrl_w[`CTRL_CSR_BIT],
                     decode0_ctrl_w[`CTRL_MRET_BIT],
                     decode0_ctrl_w[`CTRL_SRET_BIT],
                     decode0_ctrl_w[`CTRL_WFI_BIT],
                     decode0_ctrl_w[`CTRL_SFENCE_VMA_BIT]);
  wire dispatch1_supported_w =
      ctrl_supported(decode1_ctrl_w[`CTRL_VALID_BIT],
                     decode1_ctrl_w[`CTRL_ILLEGAL_BIT],
                     decode1_ctrl_w[`CTRL_NEED_EXEC_BIT],
                     decode1_ctrl_w[`CTRL_SYSTEM_BIT],
                     decode1_ctrl_w[`CTRL_CSR_BIT],
                     decode1_ctrl_w[`CTRL_MRET_BIT],
                     decode1_ctrl_w[`CTRL_SRET_BIT],
                     decode1_ctrl_w[`CTRL_WFI_BIT],
                     decode1_ctrl_w[`CTRL_SFENCE_VMA_BIT]);
  // CSR 旧值作为该 uop 的写回数据，复用 imm payload 穿过 rename/issue/ROB。
  wire [`XLEN-1:0] backend_dispatch0_imm_w =
      decode0_ctrl_w[`CTRL_CSR_BIT] ? dispatch0_csr_rdata_i : decode0_imm_w;
  wire [`XLEN-1:0] backend_dispatch1_imm_w =
      decode1_ctrl_w[`CTRL_CSR_BIT] ? dispatch1_csr_rdata_i : decode1_imm_w;
  wire backend_dispatch0_valid_w = dispatch0_valid_i && dispatch0_supported_w;
  wire backend_dispatch1_valid_w = dispatch1_valid_i && dispatch1_supported_w;
  wire backend_dispatch0_ready_w;
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
	    .pending_branch_fast_valid_i(pending_branch_fast_valid_i),
	    .pending_branch_fast_pc_i(pending_branch_fast_pc_i),
	    .recover_gprs_i(recover_gprs_i),
	    .dispatch0_valid_i(backend_dispatch0_valid_w),
    .dispatch0_ready_o(backend_dispatch0_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(decode0_ctrl_w),
    .dispatch0_rs1_arch_i(decode0_rs1_w),
    .dispatch0_rs2_arch_i(decode0_rs2_w),
    .dispatch0_rd_arch_i(decode0_rd_w),
    .dispatch0_imm_i(backend_dispatch0_imm_w),
    .dispatch1_valid_i(backend_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(backend_dispatch1_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(decode1_ctrl_w),
    .dispatch1_rs1_arch_i(decode1_rs1_w),
    .dispatch1_rs2_arch_i(decode1_rs2_w),
    .dispatch1_rd_arch_i(decode1_rd_w),
    .dispatch1_imm_i(backend_dispatch1_imm_w),
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
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
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
    .mem1_rsp_page_fault_i(mem1_rsp_page_fault_i),
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
    .mem_idle_o(mem_idle_o),
    .execute0_valid_o(execute0_valid_o),
	    .execute1_valid_o(execute1_valid_o),
	    .branch_resolve_valid_o(branch_resolve_valid_o),
	    .branch_resolve_pc_o(branch_resolve_pc_o),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc_o),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned_o),
	    .branch_resolve_rob_idx_o(branch_resolve_rob_idx_o),
	    .branch_resolve_mispredict_o(branch_resolve_mispredict_o),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid_o),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc_o),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc_o),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned_o),
	    .pending_load_branch_dep_o(pending_load_branch_dep_o)
  );

endmodule
