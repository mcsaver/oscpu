`include "define.v"

// ALU-only 乱序 core slice：真实指令经 DecodeStage 进入 OoO 后端，
// ROB 按序退休后再更新架构 GPR，为后续替换 NpcCore 写回/提交边界做准备。
module OooAluCoreSlice #(
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
  input serial_write_valid_i,
  input [`REG_ADDR_W-1:0] serial_write_arch_rd_i,
  input [`XLEN-1:0] serial_write_data_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`XLEN-1:0] dispatch0_csr_rdata_i,
  output dispatch0_unsupported_o,
  output dispatch0_unsupported_raw_o,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`XLEN-1:0] dispatch1_csr_rdata_i,
  // 【serialize-at-retire Phase1】commit-time rd 覆写: head0-CSR 队头化后 dispatch 拍 csr_rdata=0(读点已迁队头),
  // 其 ROB data 是垃圾。提交拍(head0_csr_commit_i)把架构组合读 csr_rdata(commit0_csr_rdata_i)覆写进 commit0_data,
  // 同时修 arch GPR(→ArchRegFile) 与 difftest 流(→core_commit0_rd_data)。必须 commit-time(非 dispatch): fsflags 坑
  // ——OLDER FP 在 CSR dispatch 后/commit 前更新 fflags, 只有提交拍架构读才对。
  input head0_csr_commit_i,
  input [`XLEN-1:0] commit0_csr_rdata_i,
  output dispatch1_unsupported_o,
  output dispatch1_unsupported_raw_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
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
  input mem_translate_active_i,
  input [2:0] frm_i,
  output mem_retire_quiet_o,
  output [4:0] commit0_fflags_o,
  output commit0_is_fp_rd_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,
  output commit1_write_o,

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
  output branch_resolve_is_branch_o,
  output branch_resolve_taken_o,
  output branch_resolve_pred_taken_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o,
  // 【P4 shadow】ROB 队头指针透传（AluDecodeBackend→本层→ExecuteBackend，纯观测端口）
  output [ROB_INDEX_W-1:0] rob_head_idx_o,
  output [1:0] retire_count_o,
  output [`XLEN-1:0] a0_data_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o
);

  wire [PHY_REG_ADDR_W-1:0] commit0_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] commit0_new_pdest_w;
  wire [`TRAP_CAUSE_W-1:0] commit0_cause_w;
  wire [`XLEN-1:0] commit0_tval_w;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest_w;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause_w;
  wire [`XLEN-1:0] commit1_tval_w;
  wire [`XLEN * `REG_NUM - 1:0] arch_debug_gprs_w;
  // 【serialize Phase1】ROB 原始 commit0 data(未覆写); head0-CSR 提交拍用架构 csr_rdata 覆写。
  wire [`XLEN-1:0] commit0_data_raw_w;
  assign commit0_data_o =
      head0_csr_commit_i ? commit0_csr_rdata_i : commit0_data_raw_w;

  OooAluDecodeBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_decode_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
    .checkpoint_restore_i(checkpoint_restore_i),
    .checkpoint_quiesce_i(checkpoint_quiesce_i),
    .mem_issue_block_i(mem_issue_block_i),
    .pending_branch_fast_valid_i(pending_branch_fast_valid_i),
    .pending_branch_fast_pc_i(pending_branch_fast_pc_i),
    .recover_gprs_i(arch_debug_gprs_w),
	    .dispatch0_valid_i(dispatch0_valid_i),
    .dispatch0_ready_o(dispatch0_ready_o),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_bht_idx_i(dispatch0_bht_idx_i),
    .dispatch0_pred_taken_i(dispatch0_pred_taken_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_csr_rdata_i(dispatch0_csr_rdata_i),
    .dispatch0_unsupported_o(dispatch0_unsupported_o),
    .dispatch0_unsupported_raw_o(dispatch0_unsupported_raw_o),
    .dispatch1_valid_i(dispatch1_valid_i),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(dispatch1_ready_o),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_bht_idx_i(dispatch1_bht_idx_i),
    .dispatch1_pred_taken_i(dispatch1_pred_taken_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_csr_rdata_i(dispatch1_csr_rdata_i),
    .dispatch1_unsupported_o(dispatch1_unsupported_o),
    .dispatch1_unsupported_raw_o(dispatch1_unsupported_raw_o),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_probe_o(mem_req_probe_o),
    .mem_req_pretrans_o(mem_req_pretrans_o),
    .mem_req_nokill_o(mem_req_nokill_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
    .mem_translate_active_i(mem_translate_active_i),
    .frm_i(frm_i),
    .mem_retire_quiet_o(mem_retire_quiet_o),
    .commit0_fflags_o(commit0_fflags_o),
    .commit0_is_fp_rd_o(commit0_is_fp_rd_o),
    .commit1_is_fp_rd_o(commit1_is_fp_rd_o),
    .commit1_fflags_o(commit1_fflags_o),
    .commit_ready_i(commit_ready_i),
    .commit1_block_i(commit1_block_i),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_w),
    .commit0_new_pdest_o(commit0_new_pdest_w),
    .commit0_data_o(commit0_data_raw_w),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_w),
    .commit0_tval_o(commit0_tval_w),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_w),
    .commit1_new_pdest_o(commit1_new_pdest_w),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_w),
    .commit1_tval_o(commit1_tval_w),
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
	    .branch_resolve_is_branch_o(branch_resolve_is_branch_o),
	    .branch_resolve_taken_o(branch_resolve_taken_o),
	    .branch_resolve_pred_taken_o(branch_resolve_pred_taken_o),
	    .branch_resolve_bht_idx_o(branch_resolve_bht_idx_o),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid_o),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc_o),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc_o),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned_o),
	    .rob_head_idx_o(rob_head_idx_o)
  );

  OooArchRegFile u_arch_reg_file (
    .clk(clk),
    .rst(rst),
    .commit0_valid_i(commit0_valid_o),
    .commit0_rd_en_i(commit0_rd_en_o),
    .commit0_arch_rd_i(commit0_arch_rd_o),
    .commit0_data_i(commit0_data_o),
    .commit0_exception_i(commit0_exception_o),
    .commit1_valid_i(commit1_valid_o),
    .commit1_rd_en_i(commit1_rd_en_o),
    .commit1_arch_rd_i(commit1_arch_rd_o),
    .commit1_data_i(commit1_data_o),
    .commit1_exception_i(commit1_exception_o),
    .serial_write_valid_i(serial_write_valid_i),
    .serial_write_arch_rd_i(serial_write_arch_rd_i),
    .serial_write_data_i(serial_write_data_i),
    .commit0_write_o(commit0_write_o),
	    .commit1_write_o(commit1_write_o),
	    .a0_data_o(a0_data_o),
	    .debug_gprs_o(arch_debug_gprs_w)
	  );

  assign debug_gprs_o = arch_debug_gprs_w;
  assign retire_count_o = {1'b0, commit0_valid_o} + {1'b0, commit1_valid_o};

`ifdef OOO_ASSERT
  // T3I drain 定理：ROB 的 commit0 以 count_q!=0 为必要条件，commit1 又
  // 蕴含 commit0；故精确空 ROB 不可能同时产生 core retire。这个跨模块不变量
  // 允许 drain gate 删除冗余 retire-count 输入，且防止未来 ROB 改写破坏前提。
  always @(posedge clk) begin
    if (!rst && (rob_count_o === {ROB_COUNT_W{1'b0}}) &&
        (retire_count_o !== 2'b00)) begin
      $error("[CORE-RETIRE-REQUIRES-ROB] retire=%0d while ROB is empty @%0t",
             retire_count_o, $time);
    end
  end
`endif

  assign commit0_cause_o = commit0_cause_w;
  assign commit0_tval_o = commit0_tval_w;
  assign commit1_cause_o = commit1_cause_w;
  assign commit1_tval_o = commit1_tval_w;

  wire unused_commit_payload_w =
      (|commit0_old_pdest_w) | (|commit0_new_pdest_w) |
      (|commit1_old_pdest_w) | (|commit1_new_pdest_w);

endmodule
