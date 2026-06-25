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
  output [6:0] free_count_o,
  output [4:0] rob_count_o,
  output [3:0] issue_count_o
);

  localparam OOO_ROB_INDEX_W = 4;
  localparam OOO_ROB_COUNT_W = OOO_ROB_INDEX_W + 1;
  localparam OOO_ISSUE_INDEX_W = 3;
  localparam OOO_ISSUE_COUNT_W = OOO_ISSUE_INDEX_W + 1;

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

  OooAluFetchCore #(
    .ROB_INDEX_W(OOO_ROB_INDEX_W),
    .ROB_COUNT_W(OOO_ROB_COUNT_W),
    .ISSUE_COUNT_W(OOO_ISSUE_COUNT_W)
  ) u_ooo_core (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .run_i(1'b1),
    .reset_pc_i(`RESET_PC),
    .time_i(mtime_i),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
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
    .priv_mode_o(ooo_priv_mode_w),
    .mstatus_o(ooo_mstatus_w),
    .satp_o(ooo_satp_w),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(debug_gprs_o),
    .retire_count_o(retire_count_o),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
  );

  assign ifu_axi_abort_o = ooo_mmu_flush_w;
  assign lsu_axi_abort_o = ooo_mem_flush_w;
  assign exit_pc_o = debug_pc_o;

endmodule
