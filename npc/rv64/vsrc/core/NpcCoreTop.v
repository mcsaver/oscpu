`include "define.v"

// Core-level top: owns the concrete core implementation choice and presents the
// same IFU/LSU bus boundary to simulation, SoC integration, and synthesis.
module NpcCoreTop (
  input clk,
  input rst,
  input dcache_dma_invalidate_all_i,

  output ifu_axi_arvalid_o,
  input ifu_axi_arready_i,
  output [`XLEN-1:0] ifu_axi_araddr_o,
  output [3:0] ifu_axi_arid_o,
  output [7:0] ifu_axi_arlen_o,
  output [2:0] ifu_axi_arsize_o,
  output [1:0] ifu_axi_arburst_o,
  output [2:0] ifu_axi_arprot_o,
  input ifu_axi_rvalid_i,
  output ifu_axi_rready_o,
  input [`XLEN-1:0] ifu_axi_rdata_i,
  input [1:0] ifu_axi_rresp_i,
  // HW-managed A 更新：取指桥新写通道(写回 PTE 置 A 位)。
  output ifu_axi_awvalid_o,
  input ifu_axi_awready_i,
  output [`XLEN-1:0] ifu_axi_awaddr_o,
  output [3:0] ifu_axi_awid_o,
  output [7:0] ifu_axi_awlen_o,
  output [2:0] ifu_axi_awsize_o,
  output [1:0] ifu_axi_awburst_o,
  output ifu_axi_wvalid_o,
  input ifu_axi_wready_i,
  output [`XLEN-1:0] ifu_axi_wdata_o,
  output [`STRB_W-1:0] ifu_axi_wstrb_o,
  output ifu_axi_wlast_o,
  input ifu_axi_bvalid_i,
  output ifu_axi_bready_o,
  input [1:0] ifu_axi_bresp_i,

  output lsu_axi_arvalid_o,
  input lsu_axi_arready_i,
  output [`XLEN-1:0] lsu_axi_araddr_o,
  output [3:0] lsu_axi_arid_o,
  output [7:0] lsu_axi_arlen_o,
  output [2:0] lsu_axi_arsize_o,
  output [1:0] lsu_axi_arburst_o,
  output [2:0] lsu_axi_arprot_o,
  input lsu_axi_rvalid_i,
  output lsu_axi_rready_o,
  input [`XLEN-1:0] lsu_axi_rdata_i,
  input [1:0] lsu_axi_rresp_i,
  output lsu_axi_awvalid_o,
  input lsu_axi_awready_i,
  output [`XLEN-1:0] lsu_axi_awaddr_o,
  output [3:0] lsu_axi_awid_o,
  output [7:0] lsu_axi_awlen_o,
  output [2:0] lsu_axi_awsize_o,
  output [1:0] lsu_axi_awburst_o,
  output lsu_axi_wvalid_o,
  input lsu_axi_wready_i,
  output [`XLEN-1:0] lsu_axi_wdata_o,
  output [`STRB_W-1:0] lsu_axi_wstrb_o,
  output lsu_axi_wlast_o,
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
  wire [`XLEN-1:0] ooo_fetch_req_owner_pc_w;
  wire ooo_fetch_rsp_valid_w;
  wire ooo_fetch_rsp_ready_w;
  wire [`INST_W-1:0] ooo_fetch_rsp_inst0_w;
  wire [1:0] ooo_fetch_rsp_resp0_w;
  wire [`INST_W-1:0] ooo_fetch_rsp_inst1_w;
  wire [1:0] ooo_fetch_rsp_resp1_w;
  wire [2:0] ooo_fetch_rsp_resp0_bytes_w;

  wire ooo_mem0_req_valid_w;
  wire ooo_mem0_req_ready_w;
  wire ooo_mem0_req_write_w;
  wire ooo_mem0_req_probe_w;
  wire ooo_mem0_req_pretrans_w;
  wire ooo_mem0_req_nokill_w;
  wire ooo_mem0_req_attr_valid_w;
  wire [1:0] ooo_mem0_req_class_w;
  wire ooo_mem0_req_cacheable_w;
  wire [`XLEN-1:0] ooo_mem0_req_addr_w;
  wire [`XLEN-1:0] ooo_mem0_req_wdata_w;
  wire [`STRB_W-1:0] ooo_mem0_req_wstrb_w;
  wire ooo_mem0_req_device_release_w;
  wire ooo_mem0_req_device_cancel_w;
  wire ooo_mem0_rsp_valid_w;
  wire ooo_mem0_rsp_ready_w;
  wire [`XLEN-1:0] ooo_mem0_rsp_rdata_w;
  wire ooo_mem0_rsp_error_w;
  wire ooo_mem0_rsp_page_fault_w;
  wire ooo_mem0_rsp_attr_valid_w;
  wire [1:0] ooo_mem0_rsp_class_w;
  wire ooo_mem0_rsp_cacheable_w;
  wire ooo_mem_translate_active_w;

  wire ooo_mem_flush_w;
  wire ooo_mmu_flush_w;
  wire [1:0] ooo_priv_mode_w;
  wire [`XLEN-1:0] ooo_mstatus_w;
  wire [`XLEN-1:0] ooo_satp_w;
  wire [2:0] ooo_frm_w;  // FP#1: fcsr.frm 从 CsrFile 路由到 FP datapath
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
  wire ooo_head0_csr_commit_w;   // 【serialize Phase1】head0-CSR 队头提交脉冲 → CSR 状态写
  wire ooo_csr_access_valid_w;
  wire [11:0] ooo_csr_access_addr_w;
  wire [2:0] ooo_csr_access_funct3_w;
  wire [`REG_ADDR_W-1:0] ooo_csr_access_rs1_idx_w;
  wire [`XLEN-1:0] ooo_csr_access_rs1_data_w;
  wire ooo_csr_probe_valid_w;
  wire [11:0] ooo_csr_probe_addr_w;
  wire [2:0] ooo_csr_probe_funct3_w;
  wire [`REG_ADDR_W-1:0] ooo_csr_probe_rs1_idx_w;
  wire ooo_pending_fp_fflags_commit_w;
  wire ooo_fp_dirty_commit_w;
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


  // Bridge-side logical low-window ABI.  Registered lane adapters below own
  // the conversion to the standard AXI byte-lane ABI exported by NpcCoreTop.
  wire lsu_raw_arvalid_w;
  wire lsu_raw_arready_w;
  wire [`XLEN-1:0] lsu_raw_araddr_w;
  wire [2:0] lsu_raw_arsize_w;
  wire [2:0] lsu_raw_arprot_w;
  wire lsu_raw_rvalid_w;
  wire lsu_raw_rready_w;
  wire [`XLEN-1:0] lsu_raw_rdata_w;
  wire [1:0] lsu_raw_rresp_w;
  wire lsu_raw_awvalid_w;
  wire lsu_raw_awready_w;
  wire [`XLEN-1:0] lsu_raw_awaddr_w;
  wire [2:0] lsu_raw_awsize_w;
  wire lsu_raw_wvalid_w;
  wire lsu_raw_wready_w;
  wire [`XLEN-1:0] lsu_raw_wdata_w;
  wire [`STRB_W-1:0] lsu_raw_wstrb_w;
  wire lsu_raw_bvalid_w;
  wire lsu_raw_bready_w;
  wire [1:0] lsu_raw_bresp_w;

  OooFetchAxiBridge u_ooo_fetch_bridge (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(ooo_mmu_flush_w),
    // R2.5 coherence contract: an ordinary store does not make instruction
    // bytes visible to fetch.  Software must execute FENCE.I, whose serialized
    // commit reaches this bridge through mmu_flush_i and clears the whole I$.
    // Keep the generic bridge/cache invalidate ABI, but do not reconnect it to
    // a speculative or completed LSU store without a new coherence contract.
    .invalidate_valid_i(1'b0),
    .invalidate_addr_i({`XLEN{1'b0}}),
    .priv_mode_i(ooo_priv_mode_w),
    .satp_i(ooo_satp_w),
    .svpbmt_en_i(ooo_svpbmt_en_w),
    .pmpcfg_i(ooo_pmpcfg_w),
    .pmpaddr_i(ooo_pmpaddr_w),
    .fetch_req_valid_i(ooo_fetch_req_valid_w),
    .fetch_req_ready_o(ooo_fetch_req_ready_w),
    .fetch_req_pc_i(ooo_fetch_req_pc_w),
    .fetch_req_owner_pc_o(ooo_fetch_req_owner_pc_w),
    .fetch_rsp_valid_o(ooo_fetch_rsp_valid_w),
    .fetch_rsp_ready_i(ooo_fetch_rsp_ready_w),
    .fetch_rsp_inst0_o(ooo_fetch_rsp_inst0_w),
    .fetch_rsp_resp0_o(ooo_fetch_rsp_resp0_w),
    .fetch_rsp_inst1_o(ooo_fetch_rsp_inst1_w),
    .fetch_rsp_resp1_o(ooo_fetch_rsp_resp1_w),
    .fetch_rsp_resp0_bytes_o(ooo_fetch_rsp_resp0_bytes_w),
    .ifu_axi_arvalid_o(ifu_axi_arvalid_o),
    .ifu_axi_arready_i(ifu_axi_arready_i),
    .ifu_axi_araddr_o(ifu_axi_araddr_o),
    .ifu_axi_arid_o(ifu_axi_arid_o),
    .ifu_axi_arlen_o(ifu_axi_arlen_o),
    .ifu_axi_arsize_o(ifu_axi_arsize_o),
    .ifu_axi_arburst_o(ifu_axi_arburst_o),
    .ifu_axi_arprot_o(ifu_axi_arprot_o),
    .ifu_axi_rvalid_i(ifu_axi_rvalid_i),
    .ifu_axi_rready_o(ifu_axi_rready_o),
    .ifu_axi_rdata_i(ifu_axi_rdata_i),
    .ifu_axi_rresp_i(ifu_axi_rresp_i),
    .ifu_axi_awvalid_o(ifu_axi_awvalid_o),
    .ifu_axi_awready_i(ifu_axi_awready_i),
    .ifu_axi_awaddr_o(ifu_axi_awaddr_o),
    .ifu_axi_awid_o(ifu_axi_awid_o),
    .ifu_axi_awlen_o(ifu_axi_awlen_o),
    .ifu_axi_awsize_o(ifu_axi_awsize_o),
    .ifu_axi_awburst_o(ifu_axi_awburst_o),
    .ifu_axi_wvalid_o(ifu_axi_wvalid_o),
    .ifu_axi_wready_i(ifu_axi_wready_i),
    .ifu_axi_wdata_o(ifu_axi_wdata_o),
    .ifu_axi_wstrb_o(ifu_axi_wstrb_o),
    .ifu_axi_wlast_o(ifu_axi_wlast_o),
    .ifu_axi_bvalid_i(ifu_axi_bvalid_i),
    .ifu_axi_bready_o(ifu_axi_bready_o),
    .ifu_axi_bresp_i(ifu_axi_bresp_i)
  );

  OooMemAxiBridge u_ooo_mem_bridge (
    .clk(clk),
    .rst(rst),
    .flush_i(ooo_mem_flush_w),
    .mmu_flush_i(ooo_mmu_flush_w),
    .dcache_dma_invalidate_all_i(dcache_dma_invalidate_all_i),
    .priv_mode_i(ooo_priv_mode_w),
    .mstatus_i(ooo_mstatus_w),
    .satp_i(ooo_satp_w),
    .svpbmt_en_i(ooo_svpbmt_en_w),
    .pmpcfg_i(ooo_pmpcfg_w),
    .pmpaddr_i(ooo_pmpaddr_w),
    .mem0_req_valid_i(ooo_mem0_req_valid_w),
    .mem0_req_ready_o(ooo_mem0_req_ready_w),
    .mem0_req_write_i(ooo_mem0_req_write_w),
    .mem0_req_probe_i(ooo_mem0_req_probe_w),
    .mem0_req_pretrans_i(ooo_mem0_req_pretrans_w),
    .mem0_req_nokill_i(ooo_mem0_req_nokill_w),
    .mem0_req_attr_valid_i(ooo_mem0_req_attr_valid_w),
    .mem0_req_class_i(ooo_mem0_req_class_w),
    .mem0_req_cacheable_i(ooo_mem0_req_cacheable_w),
    .mem0_device_release_i(ooo_mem0_req_device_release_w),
    .mem0_device_cancel_i(ooo_mem0_req_device_cancel_w),
    .mem0_req_addr_i(ooo_mem0_req_addr_w),
    .mem0_req_wdata_i(ooo_mem0_req_wdata_w),
    .mem0_req_wstrb_i(ooo_mem0_req_wstrb_w),
    .mem0_rsp_valid_o(ooo_mem0_rsp_valid_w),
    .mem0_rsp_ready_i(ooo_mem0_rsp_ready_w),
    .mem0_rsp_rdata_o(ooo_mem0_rsp_rdata_w),
    .mem0_rsp_error_o(ooo_mem0_rsp_error_w),
    .mem0_rsp_page_fault_o(ooo_mem0_rsp_page_fault_w),
    .mem0_rsp_attr_valid_o(ooo_mem0_rsp_attr_valid_w),
    .mem0_rsp_class_o(ooo_mem0_rsp_class_w),
    .mem0_rsp_cacheable_o(ooo_mem0_rsp_cacheable_w),
    .translate_active_o(ooo_mem_translate_active_w),
    .lsu_axi_arvalid_o(lsu_raw_arvalid_w),
    .lsu_axi_arready_i(lsu_raw_arready_w),
    .lsu_axi_araddr_o(lsu_raw_araddr_w),
    .lsu_axi_arid_o(lsu_axi_arid_o),
    .lsu_axi_arlen_o(lsu_axi_arlen_o),
    .lsu_axi_arsize_o(lsu_raw_arsize_w),
    .lsu_axi_arburst_o(lsu_axi_arburst_o),
    .lsu_axi_arprot_o(lsu_raw_arprot_w),
    .lsu_axi_rvalid_i(lsu_raw_rvalid_w),
    .lsu_axi_rready_o(lsu_raw_rready_w),
    .lsu_axi_rdata_i(lsu_raw_rdata_w),
    .lsu_axi_rresp_i(lsu_raw_rresp_w),
    .lsu_axi_awvalid_o(lsu_raw_awvalid_w),
    .lsu_axi_awready_i(lsu_raw_awready_w),
    .lsu_axi_awaddr_o(lsu_raw_awaddr_w),
    .lsu_axi_awid_o(lsu_axi_awid_o),
    .lsu_axi_awlen_o(lsu_axi_awlen_o),
    .lsu_axi_awsize_o(lsu_raw_awsize_w),
    .lsu_axi_awburst_o(lsu_axi_awburst_o),
    .lsu_axi_wvalid_o(lsu_raw_wvalid_w),
    .lsu_axi_wready_i(lsu_raw_wready_w),
    .lsu_axi_wdata_o(lsu_raw_wdata_w),
    .lsu_axi_wstrb_o(lsu_raw_wstrb_w),
    .lsu_axi_wlast_o(lsu_axi_wlast_o),
    .lsu_axi_bvalid_i(lsu_raw_bvalid_w),
    .lsu_axi_bready_o(lsu_raw_bready_w),
    .lsu_axi_bresp_i(lsu_raw_bresp_w)
  );

  wire lsu_raw_ar_pmem_w =
      ((lsu_raw_araddr_w & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire lsu_raw_aw_pmem_w =
      ((lsu_raw_awaddr_w & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
  wire lsu_raw_split_allowed_w =
      (lsu_raw_arvalid_w && lsu_raw_ar_pmem_w) ||
      (lsu_raw_awvalid_w && lsu_raw_aw_pmem_w);

  // Only ordinary PMEM may split.  The backend already traps translating
  // cross-page misaligned accesses, while bridge PMP/PMA check the complete
  // logical footprint before either channel can be accepted here.
  OooLsuAxiLaneAdapter u_lsu_lane_adapter (
    .clk(clk),
    .rst(rst),
    .u_axi_split_allowed_i(lsu_raw_split_allowed_w),
    .u_axi_arvalid_i(lsu_raw_arvalid_w),
    .u_axi_arready_o(lsu_raw_arready_w),
    .u_axi_araddr_i(lsu_raw_araddr_w),
    .u_axi_arsize_i(lsu_raw_arsize_w),
    .u_axi_arprot_i(lsu_raw_arprot_w),
    .u_axi_rvalid_o(lsu_raw_rvalid_w),
    .u_axi_rready_i(lsu_raw_rready_w),
    .u_axi_rdata_o(lsu_raw_rdata_w),
    .u_axi_rresp_o(lsu_raw_rresp_w),
    .u_axi_awvalid_i(lsu_raw_awvalid_w),
    .u_axi_awready_o(lsu_raw_awready_w),
    .u_axi_awaddr_i(lsu_raw_awaddr_w),
    .u_axi_awsize_i(lsu_raw_awsize_w),
    .u_axi_wvalid_i(lsu_raw_wvalid_w),
    .u_axi_wready_o(lsu_raw_wready_w),
    .u_axi_wdata_i(lsu_raw_wdata_w),
    .u_axi_wstrb_i(lsu_raw_wstrb_w),
    .u_axi_bvalid_o(lsu_raw_bvalid_w),
    .u_axi_bready_i(lsu_raw_bready_w),
    .u_axi_bresp_o(lsu_raw_bresp_w),
    .d_axi_arvalid_o(lsu_axi_arvalid_o),
    .d_axi_arready_i(lsu_axi_arready_i),
    .d_axi_araddr_o(lsu_axi_araddr_o),
    .d_axi_arsize_o(lsu_axi_arsize_o),
    .d_axi_arprot_o(lsu_axi_arprot_o),
    .d_axi_rvalid_i(lsu_axi_rvalid_i),
    .d_axi_rready_o(lsu_axi_rready_o),
    .d_axi_rdata_i(lsu_axi_rdata_i),
    .d_axi_rresp_i(lsu_axi_rresp_i),
    .d_axi_awvalid_o(lsu_axi_awvalid_o),
    .d_axi_awready_i(lsu_axi_awready_i),
    .d_axi_awaddr_o(lsu_axi_awaddr_o),
    .d_axi_awsize_o(lsu_axi_awsize_o),
    .d_axi_wvalid_o(lsu_axi_wvalid_o),
    .d_axi_wready_i(lsu_axi_wready_i),
    .d_axi_wdata_o(lsu_axi_wdata_o),
    .d_axi_wstrb_o(lsu_axi_wstrb_o),
    .d_axi_bvalid_i(lsu_axi_bvalid_i),
    .d_axi_bready_o(lsu_axi_bready_o),
    .d_axi_bresp_i(lsu_axi_bresp_i)
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
    .fetch_req_owner_pc_i(ooo_fetch_req_owner_pc_w),
    .fetch_rsp_valid_i(ooo_fetch_rsp_valid_w),
    .fetch_rsp_ready_o(ooo_fetch_rsp_ready_w),
    .fetch_rsp_inst0_i(ooo_fetch_rsp_inst0_w),
    .fetch_rsp_resp0_i(ooo_fetch_rsp_resp0_w),
    .fetch_rsp_inst1_i(ooo_fetch_rsp_inst1_w),
    .fetch_rsp_resp1_i(ooo_fetch_rsp_resp1_w),
    .fetch_rsp_resp0_bytes_i(ooo_fetch_rsp_resp0_bytes_w),
    .mem_req_valid_o(ooo_mem0_req_valid_w),
    .mem_req_ready_i(ooo_mem0_req_ready_w),
    .mem_req_write_o(ooo_mem0_req_write_w),
    .mem_req_probe_o(ooo_mem0_req_probe_w),
    .mem_req_pretrans_o(ooo_mem0_req_pretrans_w),
    .mem_req_nokill_o(ooo_mem0_req_nokill_w),
    .mem_req_attr_valid_o(ooo_mem0_req_attr_valid_w),
    .mem_req_class_o(ooo_mem0_req_class_w),
    .mem_req_cacheable_o(ooo_mem0_req_cacheable_w),
    .mem_req_device_release_o(ooo_mem0_req_device_release_w),
    .mem_req_device_cancel_o(ooo_mem0_req_device_cancel_w),
    .mem_req_addr_o(ooo_mem0_req_addr_w),
    .mem_req_wdata_o(ooo_mem0_req_wdata_w),
    .mem_req_wstrb_o(ooo_mem0_req_wstrb_w),
    .mem_rsp_valid_i(ooo_mem0_rsp_valid_w),
    .mem_rsp_ready_o(ooo_mem0_rsp_ready_w),
    .mem_rsp_rdata_i(ooo_mem0_rsp_rdata_w),
    .mem_rsp_error_i(ooo_mem0_rsp_error_w),
    .mem_rsp_page_fault_i(ooo_mem0_rsp_page_fault_w),
    .mem_rsp_attr_valid_i(ooo_mem0_rsp_attr_valid_w),
    .mem_rsp_class_i(ooo_mem0_rsp_class_w),
    .mem_rsp_cacheable_i(ooo_mem0_rsp_cacheable_w),
    .mem_translate_active_i(ooo_mem_translate_active_w),
    .mem_flush_o(ooo_mem_flush_w),
    .mmu_flush_o(ooo_mmu_flush_w),
    .csr_cycle_count_enable_w(ooo_csr_cycle_count_enable_w),
    .core_retire_count_w(ooo_core_retire_count_w),
    .pending_system_csr_commit_w(ooo_pending_system_csr_commit_w),
    .head0_csr_commit_w(ooo_head0_csr_commit_w),
    .csr_access_valid_w(ooo_csr_access_valid_w),
    .csr_access_addr_w(ooo_csr_access_addr_w),
    .csr_access_funct3_w(ooo_csr_access_funct3_w),
    .csr_access_rs1_idx_w(ooo_csr_access_rs1_idx_w),
    .csr_access_rs1_data_w(ooo_csr_access_rs1_data_w),
    .csr_probe_valid_w(ooo_csr_probe_valid_w),
    .csr_probe_addr_w(ooo_csr_probe_addr_w),
    .csr_probe_funct3_w(ooo_csr_probe_funct3_w),
    .csr_probe_rs1_idx_w(ooo_csr_probe_rs1_idx_w),
    .pending_fp_fflags_commit_w(ooo_pending_fp_fflags_commit_w),
    .fp_dirty_commit_w(ooo_fp_dirty_commit_w),
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
    .csr_frm_w(ooo_frm_w),
    .csr_svpbmt_en_w(ooo_svpbmt_en_w),
    .csr_pmpcfg_w(ooo_pmpcfg_w),
    .csr_pmpaddr_w(ooo_pmpaddr_w),
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
    // INSTRET-G1: consume the final two-lane ISA-retirement count after
    // control/core arbitration and exception filtering, not raw ROB dequeue.
    .instret_inc_i(retire_count_o),
    .csr_valid_i(ooo_csr_access_valid_w),
    .csr_addr_i(ooo_csr_access_addr_w),
    .csr_funct3_i(ooo_csr_access_funct3_w),
    .csr_rs1_idx_i(ooo_csr_access_rs1_idx_w),
    .csr_rs1_data_i(ooo_csr_access_rs1_data_w),
    .csr_zimm_i(ooo_csr_access_rs1_idx_w),
    .csr_probe_valid_i(ooo_csr_probe_valid_w),
    .csr_probe_addr_i(ooo_csr_probe_addr_w),
    .csr_probe_funct3_i(ooo_csr_probe_funct3_w),
    .csr_probe_rs1_idx_i(ooo_csr_probe_rs1_idx_w),
    // 【serialize Phase1 §E5】CSR 状态写在 drain 路(pending_system_csr_commit) 或 head0 队头路(mem 静默拍) fire。
    // csr_valid_i/addr/rs1 已由 csr_access_* 覆盖 head0-CSR(core_commit0_csr 优先)；
    // csr_probe_* 独立回答 current-head legality，不参与 satp/其它 CSR 写副作用。
    // 注: satp 的 mmu_flush 不在 head0 拍开(靠 serial_flush redirect + ITLB satp-tag miss)。
    .csr_commit_i(ooo_pending_system_csr_commit_w || ooo_head0_csr_commit_w),
    .csr_rdata_o(ooo_csr_rdata_w),
    .csr_illegal_o(ooo_csr_illegal_w),
    .fp_fflags_valid_i(ooo_pending_fp_fflags_commit_w),
    .fp_fflags_i(ooo_pending_fp_commit_fflags_w),
    // F8：FP 写 FP 态的脏脉冲 = fflags 提交 | FPR load 写 | FPR 结果写，置 mstatus.FS=Dirty。
    // F8: FS=Dirty 脉冲 = FPR 目的 commit | fflags commit(pending-FP 壳已拆)
    .fp_dirty_i(ooo_fp_dirty_commit_w),
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
    .frm_o(ooo_frm_w),
    .pmpcfg_o(ooo_pmpcfg_w),
    .pmpaddr_o(ooo_pmpaddr_w)
  );

  assign exit_pc_o = debug_pc_o;

endmodule
