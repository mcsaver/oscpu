`include "define.v"

// Core-level top: owns the concrete core implementation choice and presents the
// same IFU/LSU bus boundary to simulation, SoC integration, and synthesis.
module NpcCoreTop (
  input clk,
  input rst,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  output ifu_axi_abort_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  output [`STRB_W-1:0] lsu_axi_arstrb_o,
  output lsu_axi_abort_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [`STRB_W-1:0] lsu_axi_wstrb_o,
  input lsu_axi_bvalid_i,
  output lsu_axi_bready_o,
  input [1:0] lsu_axi_bresp_i,

  input irq_software_i,
  input irq_timer_i,
  input irq_external_i,
  input [`XLEN-1:0] mtime_i,

  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_rd_addr_o,
  output [`XLEN-1:0] commit0_rd_data_o,
  output commit0_exception_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_rd_addr_o,
  output [`XLEN-1:0] commit1_rd_data_o,
  output commit1_exception_o,
  output commit1_write_o,

  output trap_valid_o,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output [`XLEN-1:0] trap_tval_o,
  output exit_valid_o,
  output exit_is_ecall_o,
  output exit_is_ebreak_o,
  output [`XLEN-1:0] exit_code_o,
  output [`XLEN-1:0] exit_pc_o,
  output halted_o,

  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o,
  output [1:0] retire_count_o,
  output [`OOO_FREE_COUNT_W-1:0] free_count_o,
  output [`OOO_ROB_COUNT_W-1:0] rob_count_o,
  output [`OOO_ISSUE_COUNT_W-1:0] issue_count_o
);

  wire ooo_fetch_req_valid_w;
  wire ooo_fetch_req_ready_w;
  wire [`XLEN-1:0] ooo_fetch_req_pc_w;
  wire ooo_fetch_rsp_valid_w;
  wire ooo_fetch_rsp_ready_w;
  wire [`INST_W-1:0] ooo_fetch_rsp_inst0_w;
  wire [1:0] ooo_fetch_rsp_resp0_w;
  wire [`INST_W-1:0] ooo_fetch_rsp_inst1_w;
  wire [1:0] ooo_fetch_rsp_resp1_w;

  wire ooo_mem0_req_valid_w;
  wire ooo_mem0_req_ready_w;
  wire ooo_mem0_req_write_w;
  wire [`XLEN-1:0] ooo_mem0_req_addr_w;
  wire [`XLEN-1:0] ooo_mem0_req_wdata_w;
  wire [`STRB_W-1:0] ooo_mem0_req_wstrb_w;
  wire ooo_mem0_rsp_valid_w;
  wire ooo_mem0_rsp_ready_w;
  wire [`XLEN-1:0] ooo_mem0_rsp_rdata_w;
  wire ooo_mem0_rsp_error_w;
  wire ooo_mem0_rsp_page_fault_w;

  wire ooo_mem1_req_valid_w;
  wire ooo_mem1_req_ready_w;
  wire ooo_mem1_req_write_w;
  wire [`XLEN-1:0] ooo_mem1_req_addr_w;
  wire [`XLEN-1:0] ooo_mem1_req_wdata_w;
  wire [`STRB_W-1:0] ooo_mem1_req_wstrb_w;
  wire ooo_mem1_rsp_valid_w;
  wire ooo_mem1_rsp_ready_w;
  wire [`XLEN-1:0] ooo_mem1_rsp_rdata_w;
  wire ooo_mem1_rsp_error_w;
  wire ooo_mem1_rsp_page_fault_w;
  wire ooo_mem_flush_w;
  wire ooo_mmu_flush_w;
  wire [1:0] ooo_priv_mode_w;
  wire [`XLEN-1:0] ooo_mstatus_w;
  wire [`XLEN-1:0] ooo_satp_w;
  wire ooo_svpbmt_en_w;
  wire [`PMP_CFG_BUS_W-1:0] ooo_pmpcfg_w;
  wire [`PMP_ADDR_BUS_W-1:0] ooo_pmpaddr_w;
  wire [1:0] ooo_observe_priv_mode_w;
  wire [`XLEN-1:0] ooo_observe_mstatus_w;
  wire [`XLEN-1:0] ooo_observe_satp_w;
  wire ooo_observe_svpbmt_en_w;
  wire [`PMP_CFG_BUS_W-1:0] ooo_observe_pmpcfg_w;
  wire [`PMP_ADDR_BUS_W-1:0] ooo_observe_pmpaddr_w;

  wire ooo_csr_cycle_count_enable_w;
  wire [1:0] ooo_core_retire_count_w;
  wire ooo_pending_system_csr_commit_w;
  wire ooo_csr_access_valid_w;
  wire [11:0] ooo_csr_access_addr_w;
  wire [2:0] ooo_csr_access_funct3_w;
  wire [`REG_ADDR_W-1:0] ooo_csr_access_rs1_idx_w;
  wire [`XLEN-1:0] ooo_csr_access_rs1_data_w;
  wire ooo_pending_fp_fflags_commit_w;
  wire [4:0] ooo_pending_fp_commit_fflags_w;
  wire ooo_csr_trap_mem_valid_w;
  wire [`XLEN-1:0] ooo_csr_trap_mem_pc_w;
  wire [`TRAP_CAUSE_W-1:0] ooo_csr_trap_mem_cause_w;
  wire [`XLEN-1:0] ooo_csr_trap_mem_tval_w;
  wire ooo_csr_trap_ex_valid_w;
  wire [`XLEN-1:0] ooo_csr_trap_ex_pc_w;
  wire [`TRAP_CAUSE_W-1:0] ooo_csr_trap_ex_cause_w;
  wire [`XLEN-1:0] ooo_csr_trap_ex_tval_w;
  wire ooo_csr_trap_irq_valid_w;
  wire [`XLEN-1:0] ooo_csr_trap_irq_pc_w;
  wire [`TRAP_CAUSE_W-1:0] ooo_csr_trap_irq_cause_w;
  wire ooo_csr_real_mret_valid_w;
  wire ooo_csr_sret_valid_w;
  wire [`XLEN-1:0] ooo_csr_rdata_w;
  wire ooo_csr_illegal_w;
  wire ooo_csr_irq_pending_w;
  wire [`TRAP_CAUSE_W-1:0] ooo_csr_irq_cause_w;
  wire [`XLEN-1:0] ooo_csr_trap_target_w;
  wire [`XLEN-1:0] ooo_csr_mepc_w;
  wire [`XLEN-1:0] ooo_csr_ret_target_w;
  wire [`TRAP_CAUSE_W-1:0] ooo_csr_ecall_cause_w;
  wire [`REG_ADDR_W-1:0] ooo_pending_fp_rs1_idx_w;
  wire [`REG_ADDR_W-1:0] ooo_pending_fp_rs2_idx_w;
  wire [`REG_ADDR_W-1:0] ooo_pending_fp_rs3_idx_w;
  wire [`XLEN-1:0] ooo_pending_fp_frs1_value_w;
  wire [`XLEN-1:0] ooo_pending_fp_frs2_value_w;
  wire [`XLEN-1:0] ooo_pending_fp_frs3_value_w;
  wire ooo_pending_fp_fpr_load_write_valid_w;
  wire [`REG_ADDR_W-1:0] ooo_pending_fp_fpr_load_write_addr_w;
  wire [`XLEN-1:0] ooo_pending_fp_fpr_load_write_data_w;
  wire ooo_pending_fp_fpr_result_write_valid_w;
  wire [`REG_ADDR_W-1:0] ooo_pending_fp_fpr_result_write_addr_w;
  wire [`XLEN-1:0] ooo_pending_fp_fpr_result_write_data_w;

  wire ooo_icache_invalidate_valid_w =
      (ooo_mem0_req_valid_w && ooo_mem0_req_ready_w && ooo_mem0_req_write_w) ||
      (ooo_mem1_req_valid_w && ooo_mem1_req_ready_w && ooo_mem1_req_write_w);
  wire [`XLEN-1:0] ooo_icache_invalidate_addr_w =
      (ooo_mem0_req_valid_w && ooo_mem0_req_ready_w && ooo_mem0_req_write_w) ?
      ooo_mem0_req_addr_w : ooo_mem1_req_addr_w;

  OooFetchAxiBridge u_ooo_fetch_bridge (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(ooo_mmu_flush_w),
    .invalidate_valid_i(ooo_icache_invalidate_valid_w),
    .invalidate_addr_i(ooo_icache_invalidate_addr_w),
    .priv_mode_i(ooo_priv_mode_w),
    .satp_i(ooo_satp_w),
    .svpbmt_en_i(ooo_svpbmt_en_w),
    .pmpcfg_i(ooo_pmpcfg_w),
    .pmpaddr_i(ooo_pmpaddr_w),
    .fetch_req_valid_i(ooo_fetch_req_valid_w),
    .fetch_req_ready_o(ooo_fetch_req_ready_w),
    .fetch_req_pc_i(ooo_fetch_req_pc_w),
    .fetch_rsp_valid_o(ooo_fetch_rsp_valid_w),
    .fetch_rsp_ready_i(ooo_fetch_rsp_ready_w),
    .fetch_rsp_inst0_o(ooo_fetch_rsp_inst0_w),
    .fetch_rsp_resp0_o(ooo_fetch_rsp_resp0_w),
    .fetch_rsp_inst1_o(ooo_fetch_rsp_inst1_w),
    .fetch_rsp_resp1_o(ooo_fetch_rsp_resp1_w),
    .ifu_axi_arvalid_o(ifu_axi_arvalid_o),
    .ifu_axi_arready_i(ifu_axi_arready_i),
    .ifu_axi_araddr_o(ifu_axi_araddr_o),
    .ifu_axi_rvalid_i(ifu_axi_rvalid_i),
    .ifu_axi_rready_o(ifu_axi_rready_o),
    .ifu_axi_rdata_i(ifu_axi_rdata_i),
    .ifu_axi_rresp_i(ifu_axi_rresp_i)
  );

  OooMemAxiBridge u_ooo_mem_bridge (
    .clk(clk),
    .rst(rst),
    .flush_i(ooo_mem_flush_w),
    .mmu_flush_i(ooo_mmu_flush_w),
    .priv_mode_i(ooo_priv_mode_w),
    .mstatus_i(ooo_mstatus_w),
    .satp_i(ooo_satp_w),
    .svpbmt_en_i(ooo_svpbmt_en_w),
    .pmpcfg_i(ooo_pmpcfg_w),
    .pmpaddr_i(ooo_pmpaddr_w),
    .mem0_req_valid_i(ooo_mem0_req_valid_w),
    .mem0_req_ready_o(ooo_mem0_req_ready_w),
    .mem0_req_write_i(ooo_mem0_req_write_w),
    .mem0_req_addr_i(ooo_mem0_req_addr_w),
    .mem0_req_wdata_i(ooo_mem0_req_wdata_w),
    .mem0_req_wstrb_i(ooo_mem0_req_wstrb_w),
    .mem0_rsp_valid_o(ooo_mem0_rsp_valid_w),
    .mem0_rsp_ready_i(ooo_mem0_rsp_ready_w),
    .mem0_rsp_rdata_o(ooo_mem0_rsp_rdata_w),
    .mem0_rsp_error_o(ooo_mem0_rsp_error_w),
    .mem0_rsp_page_fault_o(ooo_mem0_rsp_page_fault_w),
    .mem1_req_valid_i(ooo_mem1_req_valid_w),
    .mem1_req_ready_o(ooo_mem1_req_ready_w),
    .mem1_req_write_i(ooo_mem1_req_write_w),
    .mem1_req_addr_i(ooo_mem1_req_addr_w),
    .mem1_req_wdata_i(ooo_mem1_req_wdata_w),
    .mem1_req_wstrb_i(ooo_mem1_req_wstrb_w),
    .mem1_rsp_valid_o(ooo_mem1_rsp_valid_w),
    .mem1_rsp_ready_i(ooo_mem1_rsp_ready_w),
    .mem1_rsp_rdata_o(ooo_mem1_rsp_rdata_w),
    .mem1_rsp_error_o(ooo_mem1_rsp_error_w),
    .mem1_rsp_page_fault_o(ooo_mem1_rsp_page_fault_w),
    .lsu_axi_arvalid_o(lsu_axi_arvalid_o),
    .lsu_axi_arready_i(lsu_axi_arready_i),
    .lsu_axi_araddr_o(lsu_axi_araddr_o),
    .lsu_axi_arstrb_o(lsu_axi_arstrb_o),
    .lsu_axi_rvalid_i(lsu_axi_rvalid_i),
    .lsu_axi_rready_o(lsu_axi_rready_o),
    .lsu_axi_rdata_i(lsu_axi_rdata_i),
    .lsu_axi_rresp_i(lsu_axi_rresp_i),
    .lsu_axi_awvalid_o(lsu_axi_awvalid_o),
    .lsu_axi_awready_i(lsu_axi_awready_i),
    .lsu_axi_awaddr_o(lsu_axi_awaddr_o),
    .lsu_axi_wvalid_o(lsu_axi_wvalid_o),
    .lsu_axi_wready_i(lsu_axi_wready_i),
    .lsu_axi_wdata_o(lsu_axi_wdata_o),
    .lsu_axi_wstrb_o(lsu_axi_wstrb_o),
    .lsu_axi_bvalid_i(lsu_axi_bvalid_i),
    .lsu_axi_bready_o(lsu_axi_bready_o),
    .lsu_axi_bresp_i(lsu_axi_bresp_i)
  );

  OooCoreTopGlue #(
    .PHY_REG_ADDR_W(`OOO_PHY_REG_ADDR_W),
    .ROB_INDEX_W(`OOO_ROB_INDEX_W),
    .ROB_COUNT_W(`OOO_ROB_COUNT_W),
    .FREE_COUNT_W(`OOO_FREE_COUNT_W),
    .ISSUE_COUNT_W(`OOO_ISSUE_COUNT_W),
    .FETCH_PACKET_COUNT_W(`OOO_FETCH_PACKET_COUNT_W)
  ) u_ooo_core (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .run_i(1'b1),
    .reset_pc_i(`RESET_PC),
    .fetch_req_valid_o(ooo_fetch_req_valid_w),
    .fetch_req_ready_i(ooo_fetch_req_ready_w),
    .fetch_req_pc_o(ooo_fetch_req_pc_w),
    .fetch_rsp_valid_i(ooo_fetch_rsp_valid_w),
    .fetch_rsp_ready_o(ooo_fetch_rsp_ready_w),
    .fetch_rsp_inst0_i(ooo_fetch_rsp_inst0_w),
    .fetch_rsp_resp0_i(ooo_fetch_rsp_resp0_w),
    .fetch_rsp_inst1_i(ooo_fetch_rsp_inst1_w),
    .fetch_rsp_resp1_i(ooo_fetch_rsp_resp1_w),
    .mem_req_valid_o(ooo_mem0_req_valid_w),
    .mem_req_ready_i(ooo_mem0_req_ready_w),
    .mem_req_write_o(ooo_mem0_req_write_w),
    .mem_req_addr_o(ooo_mem0_req_addr_w),
    .mem_req_wdata_o(ooo_mem0_req_wdata_w),
    .mem_req_wstrb_o(ooo_mem0_req_wstrb_w),
    .mem_rsp_valid_i(ooo_mem0_rsp_valid_w),
    .mem_rsp_ready_o(ooo_mem0_rsp_ready_w),
    .mem_rsp_rdata_i(ooo_mem0_rsp_rdata_w),
    .mem_rsp_error_i(ooo_mem0_rsp_error_w),
    .mem_rsp_page_fault_i(ooo_mem0_rsp_page_fault_w),
    .mem1_req_valid_o(ooo_mem1_req_valid_w),
    .mem1_req_ready_i(ooo_mem1_req_ready_w),
    .mem1_req_write_o(ooo_mem1_req_write_w),
    .mem1_req_addr_o(ooo_mem1_req_addr_w),
    .mem1_req_wdata_o(ooo_mem1_req_wdata_w),
    .mem1_req_wstrb_o(ooo_mem1_req_wstrb_w),
    .mem1_rsp_valid_i(ooo_mem1_rsp_valid_w),
    .mem1_rsp_ready_o(ooo_mem1_rsp_ready_w),
    .mem1_rsp_rdata_i(ooo_mem1_rsp_rdata_w),
    .mem1_rsp_error_i(ooo_mem1_rsp_error_w),
    .mem1_rsp_page_fault_i(ooo_mem1_rsp_page_fault_w),
    .mem_flush_o(ooo_mem_flush_w),
    .mmu_flush_o(ooo_mmu_flush_w),
    .csr_cycle_count_enable_w(ooo_csr_cycle_count_enable_w),
    .core_retire_count_w(ooo_core_retire_count_w),
    .pending_system_csr_commit_w(ooo_pending_system_csr_commit_w),
    .csr_access_valid_w(ooo_csr_access_valid_w),
    .csr_access_addr_w(ooo_csr_access_addr_w),
    .csr_access_funct3_w(ooo_csr_access_funct3_w),
    .csr_access_rs1_idx_w(ooo_csr_access_rs1_idx_w),
    .csr_access_rs1_data_w(ooo_csr_access_rs1_data_w),
    .pending_fp_fflags_commit_w(ooo_pending_fp_fflags_commit_w),
    .pending_fp_commit_fflags_w(ooo_pending_fp_commit_fflags_w),
    .csr_trap_mem_valid_w(ooo_csr_trap_mem_valid_w),
    .csr_trap_mem_pc_w(ooo_csr_trap_mem_pc_w),
    .csr_trap_mem_cause_w(ooo_csr_trap_mem_cause_w),
    .csr_trap_mem_tval_w(ooo_csr_trap_mem_tval_w),
    .csr_trap_ex_valid_w(ooo_csr_trap_ex_valid_w),
    .csr_trap_ex_pc_w(ooo_csr_trap_ex_pc_w),
    .csr_trap_ex_cause_w(ooo_csr_trap_ex_cause_w),
    .csr_trap_ex_tval_w(ooo_csr_trap_ex_tval_w),
    .csr_trap_irq_valid_w(ooo_csr_trap_irq_valid_w),
    .csr_trap_irq_pc_w(ooo_csr_trap_irq_pc_w),
    .csr_trap_irq_cause_w(ooo_csr_trap_irq_cause_w),
    .csr_real_mret_valid_w(ooo_csr_real_mret_valid_w),
    .csr_sret_valid_w(ooo_csr_sret_valid_w),
    .csr_rdata_w(ooo_csr_rdata_w),
    .csr_illegal_w(ooo_csr_illegal_w),
    .csr_irq_pending_w(ooo_csr_irq_pending_w),
    .csr_irq_cause_w(ooo_csr_irq_cause_w),
    .csr_trap_target_w(ooo_csr_trap_target_w),
    .csr_mepc_w(ooo_csr_mepc_w),
    .csr_ret_target_w(ooo_csr_ret_target_w),
    .csr_priv_mode_w(ooo_priv_mode_w),
    .csr_ecall_cause_w(ooo_csr_ecall_cause_w),
    .csr_mstatus_w(ooo_mstatus_w),
    .csr_satp_w(ooo_satp_w),
    .csr_svpbmt_en_w(ooo_svpbmt_en_w),
    .csr_pmpcfg_w(ooo_pmpcfg_w),
    .csr_pmpaddr_w(ooo_pmpaddr_w),
    .pending_fp_rs1_idx_w(ooo_pending_fp_rs1_idx_w),
    .pending_fp_rs2_idx_w(ooo_pending_fp_rs2_idx_w),
    .pending_fp_rs3_idx_w(ooo_pending_fp_rs3_idx_w),
    .pending_fp_frs1_value_w(ooo_pending_fp_frs1_value_w),
    .pending_fp_frs2_value_w(ooo_pending_fp_frs2_value_w),
    .pending_fp_frs3_value_w(ooo_pending_fp_frs3_value_w),
    .pending_fp_fpr_load_write_valid_w(ooo_pending_fp_fpr_load_write_valid_w),
    .pending_fp_fpr_load_write_addr_w(ooo_pending_fp_fpr_load_write_addr_w),
    .pending_fp_fpr_load_write_data_w(ooo_pending_fp_fpr_load_write_data_w),
    .pending_fp_fpr_result_write_valid_w(ooo_pending_fp_fpr_result_write_valid_w),
    .pending_fp_fpr_result_write_addr_w(ooo_pending_fp_fpr_result_write_addr_w),
    .pending_fp_fpr_result_write_data_w(ooo_pending_fp_fpr_result_write_data_w),
    .commit_ready_i(1'b1),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_rd_addr_o(commit0_rd_addr_o),
    .commit0_rd_data_o(commit0_rd_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_write_o(commit0_write_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_rd_addr_o(commit1_rd_addr_o),
    .commit1_rd_data_o(commit1_rd_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_write_o(commit1_write_o),
    .trap_valid_o(trap_valid_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_valid_o(exit_valid_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .exit_code_o(exit_code_o),
    .halted_o(halted_o),
    .priv_mode_o(ooo_observe_priv_mode_w),
    .mstatus_o(ooo_observe_mstatus_w),
    .satp_o(ooo_observe_satp_w),
    .svpbmt_en_o(ooo_observe_svpbmt_en_w),
    .pmpcfg_o(ooo_observe_pmpcfg_w),
    .pmpaddr_o(ooo_observe_pmpaddr_w),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(debug_gprs_o),
    .retire_count_o(retire_count_o),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
  );

  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(ooo_csr_cycle_count_enable_w),
    .time_i(mtime_i),
    .instret_inc_i(ooo_core_retire_count_w),
    .csr_valid_i(ooo_csr_access_valid_w),
    .csr_addr_i(ooo_csr_access_addr_w),
    .csr_funct3_i(ooo_csr_access_funct3_w),
    .csr_rs1_idx_i(ooo_csr_access_rs1_idx_w),
    .csr_rs1_data_i(ooo_csr_access_rs1_data_w),
    .csr_zimm_i(ooo_csr_access_rs1_idx_w),
    .csr_commit_i(ooo_pending_system_csr_commit_w),
    .csr_rdata_o(ooo_csr_rdata_w),
    .csr_illegal_o(ooo_csr_illegal_w),
    .fp_fflags_valid_i(ooo_pending_fp_fflags_commit_w),
    .fp_fflags_i(ooo_pending_fp_commit_fflags_w),
    .trap_mem_valid_i(ooo_csr_trap_mem_valid_w),
    .trap_mem_pc_i(ooo_csr_trap_mem_pc_w),
    .trap_mem_cause_i(ooo_csr_trap_mem_cause_w),
    .trap_mem_tval_i(ooo_csr_trap_mem_tval_w),
    .trap_ex_valid_i(ooo_csr_trap_ex_valid_w),
    .trap_ex_pc_i(ooo_csr_trap_ex_pc_w),
    .trap_ex_cause_i(ooo_csr_trap_ex_cause_w),
    .trap_ex_tval_i(ooo_csr_trap_ex_tval_w),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_pending_o(ooo_csr_irq_pending_w),
    .irq_cause_o(ooo_csr_irq_cause_w),
    .trap_irq_valid_i(ooo_csr_trap_irq_valid_w),
    .trap_irq_pc_i(ooo_csr_trap_irq_pc_w),
    .trap_irq_cause_i(ooo_csr_trap_irq_cause_w),
    .mret_valid_i(ooo_csr_real_mret_valid_w),
    .sret_valid_i(ooo_csr_sret_valid_w),
    .trap_target_o(ooo_csr_trap_target_w),
    .mepc_o(ooo_csr_mepc_w),
    .ret_target_o(ooo_csr_ret_target_w),
    .priv_mode_o(ooo_priv_mode_w),
    .ecall_cause_o(ooo_csr_ecall_cause_w),
    .mstatus_o(ooo_mstatus_w),
    .satp_o(ooo_satp_w),
    .svpbmt_en_o(ooo_svpbmt_en_w),
    .pmpcfg_o(ooo_pmpcfg_w),
    .pmpaddr_o(ooo_pmpaddr_w)
  );

  OooFpRegFile u_fp_reg_file (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .read0_addr_i(ooo_pending_fp_rs1_idx_w),
    .read0_data_o(ooo_pending_fp_frs1_value_w),
    .read1_addr_i(ooo_pending_fp_rs2_idx_w),
    .read1_data_o(ooo_pending_fp_frs2_value_w),
    .read2_addr_i(ooo_pending_fp_rs3_idx_w),
    .read2_data_o(ooo_pending_fp_frs3_value_w),
    .load_write_valid_i(ooo_pending_fp_fpr_load_write_valid_w),
    .load_write_addr_i(ooo_pending_fp_fpr_load_write_addr_w),
    .load_write_data_i(ooo_pending_fp_fpr_load_write_data_w),
    .result_write_valid_i(ooo_pending_fp_fpr_result_write_valid_w),
    .result_write_addr_i(ooo_pending_fp_fpr_result_write_addr_w),
    .result_write_data_i(ooo_pending_fp_fpr_result_write_data_w)
  );

  assign ifu_axi_abort_o = ooo_mmu_flush_w;
  assign lsu_axi_abort_o = ooo_mem_flush_w;
  assign exit_pc_o = debug_pc_o;

endmodule
