`include "define.v"

// F2 canonical fabric: two complete memory bridges retain their
// own station/DTLB/D-cache/FSM/identity/response paths.  Only raw miss/PTW/
// store/A-D AXI traffic is serialized by the already-verified F0 arbiter.
// NpcCoreTop instantiates this wrapper; reusable backend layers keep dual
// issue parameterized off unless their parent explicitly enables it.
module OooDualMemBridgeWrapper (
  input clk,
  input rst,
  input flush_i,
  input mmu_flush_i,
  input dcache_dma_invalidate_all_i,

  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [`XLEN-1:0] satp_i,
  input svpbmt_en_i,
  input [`PMP_CFG_BUS_W-1:0] pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] pmpaddr_i,

  input lane0_req_valid_i,
  output lane0_req_ready_o,
  input lane0_req_write_i,
  input lane0_req_probe_i,
  input lane0_req_pretrans_i,
  input lane0_req_nokill_i,
  input lane0_req_attr_valid_i,
  input [1:0] lane0_req_class_i,
  input lane0_req_cacheable_i,
  input [1:0] lane0_req_owner_kind_i,
  input [4:0] lane0_req_owner_token_i,
  input [1:0] lane0_req_mmu_epoch_i,
  input [`XLEN-1:0] lane0_req_fault_tval_i,
  input lane0_expected_valid_i,
  input [1:0] lane0_expected_owner_kind_i,
  input [4:0] lane0_expected_owner_token_i,
  input [1:0] lane0_expected_mmu_epoch_i,
  input lane0_expected_tval_valid_i,
  input [`XLEN-1:0] lane0_expected_fault_tval_i,
  input lane0_expected_effective_killed_i,
  input lane0_tracker_expected_valid_i,
  input [1:0] lane0_tracker_expected_owner_kind_i,
  input [4:0] lane0_tracker_expected_owner_token_i,
  input [1:0] lane0_tracker_expected_mmu_epoch_i,
  input lane0_station_expected_valid_i,
  input [1:0] lane0_station_expected_owner_kind_i,
  input [4:0] lane0_station_expected_owner_token_i,
  input [1:0] lane0_station_expected_mmu_epoch_i,
  input lane0_device_release_i,
  input lane0_device_cancel_i,
  input [`XLEN-1:0] lane0_req_addr_i,
  input [`XLEN-1:0] lane0_req_wdata_i,
  input [`STRB_W-1:0] lane0_req_wstrb_i,
  output lane0_rsp_valid_o,
  input lane0_rsp_ready_i,
  output [`XLEN-1:0] lane0_rsp_rdata_o,
  output lane0_rsp_error_o,
  output lane0_rsp_page_fault_o,
  output lane0_rsp_attr_valid_o,
  output [1:0] lane0_rsp_class_o,
  output lane0_rsp_cacheable_o,
  output [1:0] lane0_rsp_owner_kind_o,
  output [4:0] lane0_rsp_owner_token_o,
  output [1:0] lane0_rsp_mmu_epoch_o,
  output [`XLEN-1:0] lane0_rsp_fault_tval_o,
  output lane0_drop0_valid_o,
  output [1:0] lane0_drop0_owner_kind_o,
  output [4:0] lane0_drop0_owner_token_o,
  output [1:0] lane0_drop0_mmu_epoch_o,
  output [`XLEN-1:0] lane0_drop0_fault_tval_o,
  output lane0_drop1_valid_o,
  output [1:0] lane0_drop1_owner_kind_o,
  output [4:0] lane0_drop1_owner_token_o,
  output [1:0] lane0_drop1_mmu_epoch_o,
  output [`XLEN-1:0] lane0_drop1_fault_tval_o,
  output lane0_owner_query_valid_o,
  output [4:0] lane0_owner_query_token_o,
  output lane0_station_query_valid_o,
  output [4:0] lane0_station_query_token_o,
  output lane0_sq_query_valid_o,
  output [1:0] lane0_sq_query_owner_kind_o,
  output [4:0] lane0_sq_query_owner_token_o,
  output [1:0] lane0_sq_query_mmu_epoch_o,
  output [`XLEN-1:0] lane0_sq_query_paddr_o,
  output lane0_sq_query_attr_valid_o,
  output [1:0] lane0_sq_query_class_o,
  output [`STRB_W-1:0] lane0_sq_query_wstrb_o,
  input lane0_sq_query_allow_i,
  input lane0_sq_query_forward_i,
  input lane0_sq_query_replay_i,
  input lane0_sq_query_retry_ready_i,
  input [`XLEN-1:0] lane0_sq_query_forward_data_i,
  output [31:0] lane0_owner_residency_mask_o,
  output lane0_idle_o,
  output lane0_translate_active_o,

  input lane1_req_valid_i,
  output lane1_req_ready_o,
  input lane1_req_write_i,
  input lane1_req_probe_i,
  input lane1_req_pretrans_i,
  input lane1_req_nokill_i,
  input lane1_req_attr_valid_i,
  input [1:0] lane1_req_class_i,
  input lane1_req_cacheable_i,
  input [1:0] lane1_req_owner_kind_i,
  input [4:0] lane1_req_owner_token_i,
  input [1:0] lane1_req_mmu_epoch_i,
  input [`XLEN-1:0] lane1_req_fault_tval_i,
  input lane1_expected_valid_i,
  input [1:0] lane1_expected_owner_kind_i,
  input [4:0] lane1_expected_owner_token_i,
  input [1:0] lane1_expected_mmu_epoch_i,
  input lane1_expected_tval_valid_i,
  input [`XLEN-1:0] lane1_expected_fault_tval_i,
  input lane1_expected_effective_killed_i,
  input lane1_tracker_expected_valid_i,
  input [1:0] lane1_tracker_expected_owner_kind_i,
  input [4:0] lane1_tracker_expected_owner_token_i,
  input [1:0] lane1_tracker_expected_mmu_epoch_i,
  input lane1_station_expected_valid_i,
  input [1:0] lane1_station_expected_owner_kind_i,
  input [4:0] lane1_station_expected_owner_token_i,
  input [1:0] lane1_station_expected_mmu_epoch_i,
  input lane1_device_release_i,
  input lane1_device_cancel_i,
  input [`XLEN-1:0] lane1_req_addr_i,
  input [`XLEN-1:0] lane1_req_wdata_i,
  input [`STRB_W-1:0] lane1_req_wstrb_i,
  output lane1_rsp_valid_o,
  input lane1_rsp_ready_i,
  output [`XLEN-1:0] lane1_rsp_rdata_o,
  output lane1_rsp_error_o,
  output lane1_rsp_page_fault_o,
  output lane1_rsp_attr_valid_o,
  output [1:0] lane1_rsp_class_o,
  output lane1_rsp_cacheable_o,
  output [1:0] lane1_rsp_owner_kind_o,
  output [4:0] lane1_rsp_owner_token_o,
  output [1:0] lane1_rsp_mmu_epoch_o,
  output [`XLEN-1:0] lane1_rsp_fault_tval_o,
  output lane1_drop0_valid_o,
  output [1:0] lane1_drop0_owner_kind_o,
  output [4:0] lane1_drop0_owner_token_o,
  output [1:0] lane1_drop0_mmu_epoch_o,
  output [`XLEN-1:0] lane1_drop0_fault_tval_o,
  output lane1_drop1_valid_o,
  output [1:0] lane1_drop1_owner_kind_o,
  output [4:0] lane1_drop1_owner_token_o,
  output [1:0] lane1_drop1_mmu_epoch_o,
  output [`XLEN-1:0] lane1_drop1_fault_tval_o,
  output lane1_owner_query_valid_o,
  output [4:0] lane1_owner_query_token_o,
  output lane1_station_query_valid_o,
  output [4:0] lane1_station_query_token_o,
  output lane1_sq_query_valid_o,
  output [1:0] lane1_sq_query_owner_kind_o,
  output [4:0] lane1_sq_query_owner_token_o,
  output [1:0] lane1_sq_query_mmu_epoch_o,
  output [`XLEN-1:0] lane1_sq_query_paddr_o,
  output lane1_sq_query_attr_valid_o,
  output [1:0] lane1_sq_query_class_o,
  output [`STRB_W-1:0] lane1_sq_query_wstrb_o,
  input lane1_sq_query_allow_i,
  input lane1_sq_query_forward_i,
  input lane1_sq_query_replay_i,
  input lane1_sq_query_retry_ready_i,
  input [`XLEN-1:0] lane1_sq_query_forward_data_i,
  output [31:0] lane1_owner_residency_mask_o,
  output lane1_idle_o,
  output lane1_translate_active_o,

  output d_axi_arvalid_o,
  input d_axi_arready_i,
  output [`XLEN-1:0] d_axi_araddr_o,
  output [3:0] d_axi_arid_o,
  output [7:0] d_axi_arlen_o,
  output [2:0] d_axi_arsize_o,
  output [1:0] d_axi_arburst_o,
  output [2:0] d_axi_arprot_o,
  input d_axi_rvalid_i,
  output d_axi_rready_o,
  input [`XLEN-1:0] d_axi_rdata_i,
  input [1:0] d_axi_rresp_i,
  output d_axi_awvalid_o,
  input d_axi_awready_i,
  output [`XLEN-1:0] d_axi_awaddr_o,
  output [3:0] d_axi_awid_o,
  output [7:0] d_axi_awlen_o,
  output [2:0] d_axi_awsize_o,
  output [1:0] d_axi_awburst_o,
  output d_axi_wvalid_o,
  input d_axi_wready_i,
  output [`XLEN-1:0] d_axi_wdata_o,
  output [`STRB_W-1:0] d_axi_wstrb_o,
  output d_axi_wlast_o,
  input d_axi_bvalid_i,
  output d_axi_bready_o,
  input [1:0] d_axi_bresp_i
);

  // Explicit lane-local request/response boundaries are intentional checker
  // and mutation anchors: no F0 state or peer response may gate/merge them.
  wire lane0_req_ready_w;
  wire lane1_req_ready_w;
  assign lane0_req_ready_o = lane0_req_ready_w;
  assign lane1_req_ready_o = lane1_req_ready_w;

  wire lane0_rsp_valid_w;
  wire [`XLEN-1:0] lane0_rsp_rdata_w;
  wire lane0_rsp_error_w;
  wire lane0_rsp_page_fault_w;
  wire lane0_rsp_attr_valid_w;
  wire [1:0] lane0_rsp_class_w;
  wire lane0_rsp_cacheable_w;
  wire [1:0] lane0_rsp_owner_kind_w;
  wire [4:0] lane0_rsp_owner_token_w;
  wire [1:0] lane0_rsp_mmu_epoch_w;
  wire [`XLEN-1:0] lane0_rsp_fault_tval_w;
  assign lane0_rsp_valid_o = lane0_rsp_valid_w;
  assign lane0_rsp_rdata_o = lane0_rsp_rdata_w;
  assign lane0_rsp_error_o = lane0_rsp_error_w;
  assign lane0_rsp_page_fault_o = lane0_rsp_page_fault_w;
  assign lane0_rsp_attr_valid_o = lane0_rsp_attr_valid_w;
  assign lane0_rsp_class_o = lane0_rsp_class_w;
  assign lane0_rsp_cacheable_o = lane0_rsp_cacheable_w;
  assign lane0_rsp_owner_kind_o = lane0_rsp_owner_kind_w;
  assign lane0_rsp_owner_token_o = lane0_rsp_owner_token_w;
  assign lane0_rsp_mmu_epoch_o = lane0_rsp_mmu_epoch_w;
  assign lane0_rsp_fault_tval_o = lane0_rsp_fault_tval_w;

  wire lane1_rsp_valid_w;
  wire [`XLEN-1:0] lane1_rsp_rdata_w;
  wire lane1_rsp_error_w;
  wire lane1_rsp_page_fault_w;
  wire lane1_rsp_attr_valid_w;
  wire [1:0] lane1_rsp_class_w;
  wire lane1_rsp_cacheable_w;
  wire [1:0] lane1_rsp_owner_kind_w;
  wire [4:0] lane1_rsp_owner_token_w;
  wire [1:0] lane1_rsp_mmu_epoch_w;
  wire [`XLEN-1:0] lane1_rsp_fault_tval_w;
  assign lane1_rsp_valid_o = lane1_rsp_valid_w;
  assign lane1_rsp_rdata_o = lane1_rsp_rdata_w;
  assign lane1_rsp_error_o = lane1_rsp_error_w;
  assign lane1_rsp_page_fault_o = lane1_rsp_page_fault_w;
  assign lane1_rsp_attr_valid_o = lane1_rsp_attr_valid_w;
  assign lane1_rsp_class_o = lane1_rsp_class_w;
  assign lane1_rsp_cacheable_o = lane1_rsp_cacheable_w;
  assign lane1_rsp_owner_kind_o = lane1_rsp_owner_kind_w;
  assign lane1_rsp_owner_token_o = lane1_rsp_owner_token_w;
  assign lane1_rsp_mmu_epoch_o = lane1_rsp_mmu_epoch_w;
  assign lane1_rsp_fault_tval_o = lane1_rsp_fault_tval_w;

  wire lane0_peer_maintenance_valid_w;
  wire [`XLEN-1:0] lane0_peer_maintenance_addr_w;
  wire [`STRB_W-1:0] lane0_peer_maintenance_wstrb_w;
  wire lane1_peer_maintenance_valid_w;
  wire [`XLEN-1:0] lane1_peer_maintenance_addr_w;
  wire [`STRB_W-1:0] lane1_peer_maintenance_wstrb_w;

  wire lane0_axi_arvalid_w;
  wire lane0_axi_arready_w;
  wire [`XLEN-1:0] lane0_axi_araddr_w;
  wire [3:0] lane0_axi_arid_w;
  wire [7:0] lane0_axi_arlen_w;
  wire [2:0] lane0_axi_arsize_w;
  wire [1:0] lane0_axi_arburst_w;
  wire [2:0] lane0_axi_arprot_w;
  wire lane0_axi_rvalid_w;
  wire lane0_axi_rready_w;
  wire [`XLEN-1:0] lane0_axi_rdata_w;
  wire [1:0] lane0_axi_rresp_w;
  wire lane0_axi_awvalid_w;
  wire lane0_axi_awready_w;
  wire [`XLEN-1:0] lane0_axi_awaddr_w;
  wire [3:0] lane0_axi_awid_w;
  wire [7:0] lane0_axi_awlen_w;
  wire [2:0] lane0_axi_awsize_w;
  wire [1:0] lane0_axi_awburst_w;
  wire lane0_axi_wvalid_w;
  wire lane0_axi_wready_w;
  wire [`XLEN-1:0] lane0_axi_wdata_w;
  wire [`STRB_W-1:0] lane0_axi_wstrb_w;
  wire lane0_axi_wlast_w;
  wire lane0_axi_bvalid_w;
  wire lane0_axi_bready_w;
  wire [1:0] lane0_axi_bresp_w;

  wire lane1_axi_arvalid_w;
  wire lane1_axi_arready_w;
  wire [`XLEN-1:0] lane1_axi_araddr_w;
  wire [3:0] lane1_axi_arid_w;
  wire [7:0] lane1_axi_arlen_w;
  wire [2:0] lane1_axi_arsize_w;
  wire [1:0] lane1_axi_arburst_w;
  wire [2:0] lane1_axi_arprot_w;
  wire lane1_axi_rvalid_w;
  wire lane1_axi_rready_w;
  wire [`XLEN-1:0] lane1_axi_rdata_w;
  wire [1:0] lane1_axi_rresp_w;
  wire lane1_axi_awvalid_w;
  wire lane1_axi_awready_w;
  wire [`XLEN-1:0] lane1_axi_awaddr_w;
  wire [3:0] lane1_axi_awid_w;
  wire [7:0] lane1_axi_awlen_w;
  wire [2:0] lane1_axi_awsize_w;
  wire [1:0] lane1_axi_awburst_w;
  wire lane1_axi_wvalid_w;
  wire lane1_axi_wready_w;
  wire [`XLEN-1:0] lane1_axi_wdata_w;
  wire [`STRB_W-1:0] lane1_axi_wstrb_w;
  wire lane1_axi_wlast_w;
  wire lane1_axi_bvalid_w;
  wire lane1_axi_bready_w;
  wire [1:0] lane1_axi_bresp_w;

  OooMemAxiBridge #(
    .ENABLE_PEER_INVALIDATE(1)
  ) u_bridge0 (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .mmu_flush_i(mmu_flush_i),
    .dcache_dma_invalidate_all_i(dcache_dma_invalidate_all_i),
    .peer_invalidate_valid_i(lane1_peer_maintenance_valid_w),
    .peer_invalidate_addr_i(lane1_peer_maintenance_addr_w),
    .peer_invalidate_wstrb_i(lane1_peer_maintenance_wstrb_w),
    .priv_mode_i(priv_mode_i),
    .mstatus_i(mstatus_i),
    .satp_i(satp_i),
    .svpbmt_en_i(svpbmt_en_i),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .mem0_req_valid_i(lane0_req_valid_i),
    .mem0_req_ready_o(lane0_req_ready_w),
    .mem0_req_write_i(lane0_req_write_i),
    .mem0_req_probe_i(lane0_req_probe_i),
    .mem0_req_pretrans_i(lane0_req_pretrans_i),
    .mem0_req_nokill_i(lane0_req_nokill_i),
    .mem0_req_attr_valid_i(lane0_req_attr_valid_i),
    .mem0_req_class_i(lane0_req_class_i),
    .mem0_req_cacheable_i(lane0_req_cacheable_i),
    .mem0_req_owner_kind_i(lane0_req_owner_kind_i),
    .mem0_req_owner_token_i(lane0_req_owner_token_i),
    .mem0_req_mmu_epoch_i(lane0_req_mmu_epoch_i),
    .mem0_req_fault_tval_i(lane0_req_fault_tval_i),
    .mem0_expected_valid_i(lane0_expected_valid_i),
    .mem0_expected_owner_kind_i(lane0_expected_owner_kind_i),
    .mem0_expected_owner_token_i(lane0_expected_owner_token_i),
    .mem0_expected_mmu_epoch_i(lane0_expected_mmu_epoch_i),
    .mem0_expected_tval_valid_i(lane0_expected_tval_valid_i),
    .mem0_expected_fault_tval_i(lane0_expected_fault_tval_i),
    .mem0_expected_effective_killed_i(lane0_expected_effective_killed_i),
    .mem0_tracker_expected_valid_i(lane0_tracker_expected_valid_i),
    .mem0_tracker_expected_owner_kind_i(
        lane0_tracker_expected_owner_kind_i),
    .mem0_tracker_expected_owner_token_i(
        lane0_tracker_expected_owner_token_i),
    .mem0_tracker_expected_mmu_epoch_i(
        lane0_tracker_expected_mmu_epoch_i),
    .mem0_station_expected_valid_i(lane0_station_expected_valid_i),
    .mem0_station_expected_owner_kind_i(
        lane0_station_expected_owner_kind_i),
    .mem0_station_expected_owner_token_i(
        lane0_station_expected_owner_token_i),
    .mem0_station_expected_mmu_epoch_i(
        lane0_station_expected_mmu_epoch_i),
    .mem0_device_release_i(lane0_device_release_i),
    .mem0_device_cancel_i(lane0_device_cancel_i),
    .mem0_req_addr_i(lane0_req_addr_i),
    .mem0_req_wdata_i(lane0_req_wdata_i),
    .mem0_req_wstrb_i(lane0_req_wstrb_i),
    .mem0_rsp_valid_o(lane0_rsp_valid_w),
    .mem0_rsp_ready_i(lane0_rsp_ready_i),
    .mem0_rsp_rdata_o(lane0_rsp_rdata_w),
    .mem0_rsp_error_o(lane0_rsp_error_w),
    .mem0_rsp_page_fault_o(lane0_rsp_page_fault_w),
    .mem0_rsp_attr_valid_o(lane0_rsp_attr_valid_w),
    .mem0_rsp_class_o(lane0_rsp_class_w),
    .mem0_rsp_cacheable_o(lane0_rsp_cacheable_w),
    .mem0_rsp_owner_kind_o(lane0_rsp_owner_kind_w),
    .mem0_rsp_owner_token_o(lane0_rsp_owner_token_w),
    .mem0_rsp_mmu_epoch_o(lane0_rsp_mmu_epoch_w),
    .mem0_rsp_fault_tval_o(lane0_rsp_fault_tval_w),
    .mem0_drop0_valid_o(lane0_drop0_valid_o),
    .mem0_drop0_owner_kind_o(lane0_drop0_owner_kind_o),
    .mem0_drop0_owner_token_o(lane0_drop0_owner_token_o),
    .mem0_drop0_mmu_epoch_o(lane0_drop0_mmu_epoch_o),
    .mem0_drop0_fault_tval_o(lane0_drop0_fault_tval_o),
    .mem0_drop1_valid_o(lane0_drop1_valid_o),
    .mem0_drop1_owner_kind_o(lane0_drop1_owner_kind_o),
    .mem0_drop1_owner_token_o(lane0_drop1_owner_token_o),
    .mem0_drop1_mmu_epoch_o(lane0_drop1_mmu_epoch_o),
    .mem0_drop1_fault_tval_o(lane0_drop1_fault_tval_o),
    .mem0_owner_query_valid_o(lane0_owner_query_valid_o),
    .mem0_owner_query_token_o(lane0_owner_query_token_o),
    .mem0_station_query_valid_o(lane0_station_query_valid_o),
    .mem0_station_query_token_o(lane0_station_query_token_o),
    .mem0_sq_query_valid_o(lane0_sq_query_valid_o),
    .mem0_sq_query_owner_kind_o(lane0_sq_query_owner_kind_o),
    .mem0_sq_query_owner_token_o(lane0_sq_query_owner_token_o),
    .mem0_sq_query_mmu_epoch_o(lane0_sq_query_mmu_epoch_o),
    .mem0_sq_query_paddr_o(lane0_sq_query_paddr_o),
    .mem0_sq_query_attr_valid_o(lane0_sq_query_attr_valid_o),
    .mem0_sq_query_class_o(lane0_sq_query_class_o),
    .mem0_sq_query_wstrb_o(lane0_sq_query_wstrb_o),
    .mem0_sq_query_allow_i(lane0_sq_query_allow_i),
    .mem0_sq_query_forward_i(lane0_sq_query_forward_i),
    .mem0_sq_query_replay_i(lane0_sq_query_replay_i),
    .mem0_sq_query_retry_ready_i(lane0_sq_query_retry_ready_i),
    .mem0_sq_query_forward_data_i(lane0_sq_query_forward_data_i),
    .mem0_owner_residency_mask_o(lane0_owner_residency_mask_o),
    .mem0_idle_o(lane0_idle_o),
    .translate_active_o(lane0_translate_active_o),
    .peer_maintenance_valid_o(lane0_peer_maintenance_valid_w),
    .peer_maintenance_addr_o(lane0_peer_maintenance_addr_w),
    .peer_maintenance_wstrb_o(lane0_peer_maintenance_wstrb_w),
    .lsu_axi_arvalid_o(lane0_axi_arvalid_w),
    .lsu_axi_arready_i(lane0_axi_arready_w),
    .lsu_axi_araddr_o(lane0_axi_araddr_w),
    .lsu_axi_arid_o(lane0_axi_arid_w),
    .lsu_axi_arlen_o(lane0_axi_arlen_w),
    .lsu_axi_arsize_o(lane0_axi_arsize_w),
    .lsu_axi_arburst_o(lane0_axi_arburst_w),
    .lsu_axi_arprot_o(lane0_axi_arprot_w),
    .lsu_axi_rvalid_i(lane0_axi_rvalid_w),
    .lsu_axi_rready_o(lane0_axi_rready_w),
    .lsu_axi_rdata_i(lane0_axi_rdata_w),
    .lsu_axi_rresp_i(lane0_axi_rresp_w),
    .lsu_axi_awvalid_o(lane0_axi_awvalid_w),
    .lsu_axi_awready_i(lane0_axi_awready_w),
    .lsu_axi_awaddr_o(lane0_axi_awaddr_w),
    .lsu_axi_awid_o(lane0_axi_awid_w),
    .lsu_axi_awlen_o(lane0_axi_awlen_w),
    .lsu_axi_awsize_o(lane0_axi_awsize_w),
    .lsu_axi_awburst_o(lane0_axi_awburst_w),
    .lsu_axi_wvalid_o(lane0_axi_wvalid_w),
    .lsu_axi_wready_i(lane0_axi_wready_w),
    .lsu_axi_wdata_o(lane0_axi_wdata_w),
    .lsu_axi_wstrb_o(lane0_axi_wstrb_w),
    .lsu_axi_wlast_o(lane0_axi_wlast_w),
    .lsu_axi_bvalid_i(lane0_axi_bvalid_w),
    .lsu_axi_bready_o(lane0_axi_bready_w),
    .lsu_axi_bresp_i(lane0_axi_bresp_w)
  );

  OooDualMemAxiArbiter u_miss_arbiter (
    .clk(clk),
    .rst(rst),
    .lane0_axi_arvalid_i(lane0_axi_arvalid_w),
    .lane0_axi_arready_o(lane0_axi_arready_w),
    .lane0_axi_araddr_i(lane0_axi_araddr_w),
    .lane0_axi_arid_i(lane0_axi_arid_w),
    .lane0_axi_arlen_i(lane0_axi_arlen_w),
    .lane0_axi_arsize_i(lane0_axi_arsize_w),
    .lane0_axi_arburst_i(lane0_axi_arburst_w),
    .lane0_axi_arprot_i(lane0_axi_arprot_w),
    .lane0_axi_rvalid_o(lane0_axi_rvalid_w),
    .lane0_axi_rready_i(lane0_axi_rready_w),
    .lane0_axi_rdata_o(lane0_axi_rdata_w),
    .lane0_axi_rresp_o(lane0_axi_rresp_w),
    .lane0_axi_awvalid_i(lane0_axi_awvalid_w),
    .lane0_axi_awready_o(lane0_axi_awready_w),
    .lane0_axi_awaddr_i(lane0_axi_awaddr_w),
    .lane0_axi_awid_i(lane0_axi_awid_w),
    .lane0_axi_awlen_i(lane0_axi_awlen_w),
    .lane0_axi_awsize_i(lane0_axi_awsize_w),
    .lane0_axi_awburst_i(lane0_axi_awburst_w),
    .lane0_axi_wvalid_i(lane0_axi_wvalid_w),
    .lane0_axi_wready_o(lane0_axi_wready_w),
    .lane0_axi_wdata_i(lane0_axi_wdata_w),
    .lane0_axi_wstrb_i(lane0_axi_wstrb_w),
    .lane0_axi_wlast_i(lane0_axi_wlast_w),
    .lane0_axi_bvalid_o(lane0_axi_bvalid_w),
    .lane0_axi_bready_i(lane0_axi_bready_w),
    .lane0_axi_bresp_o(lane0_axi_bresp_w),
    .lane1_axi_arvalid_i(lane1_axi_arvalid_w),
    .lane1_axi_arready_o(lane1_axi_arready_w),
    .lane1_axi_araddr_i(lane1_axi_araddr_w),
    .lane1_axi_arid_i(lane1_axi_arid_w),
    .lane1_axi_arlen_i(lane1_axi_arlen_w),
    .lane1_axi_arsize_i(lane1_axi_arsize_w),
    .lane1_axi_arburst_i(lane1_axi_arburst_w),
    .lane1_axi_arprot_i(lane1_axi_arprot_w),
    .lane1_axi_rvalid_o(lane1_axi_rvalid_w),
    .lane1_axi_rready_i(lane1_axi_rready_w),
    .lane1_axi_rdata_o(lane1_axi_rdata_w),
    .lane1_axi_rresp_o(lane1_axi_rresp_w),
    .lane1_axi_awvalid_i(lane1_axi_awvalid_w),
    .lane1_axi_awready_o(lane1_axi_awready_w),
    .lane1_axi_awaddr_i(lane1_axi_awaddr_w),
    .lane1_axi_awid_i(lane1_axi_awid_w),
    .lane1_axi_awlen_i(lane1_axi_awlen_w),
    .lane1_axi_awsize_i(lane1_axi_awsize_w),
    .lane1_axi_awburst_i(lane1_axi_awburst_w),
    .lane1_axi_wvalid_i(lane1_axi_wvalid_w),
    .lane1_axi_wready_o(lane1_axi_wready_w),
    .lane1_axi_wdata_i(lane1_axi_wdata_w),
    .lane1_axi_wstrb_i(lane1_axi_wstrb_w),
    .lane1_axi_wlast_i(lane1_axi_wlast_w),
    .lane1_axi_bvalid_o(lane1_axi_bvalid_w),
    .lane1_axi_bready_i(lane1_axi_bready_w),
    .lane1_axi_bresp_o(lane1_axi_bresp_w),
    .d_axi_arvalid_o(d_axi_arvalid_o),
    .d_axi_arready_i(d_axi_arready_i),
    .d_axi_araddr_o(d_axi_araddr_o),
    .d_axi_arid_o(d_axi_arid_o),
    .d_axi_arlen_o(d_axi_arlen_o),
    .d_axi_arsize_o(d_axi_arsize_o),
    .d_axi_arburst_o(d_axi_arburst_o),
    .d_axi_arprot_o(d_axi_arprot_o),
    .d_axi_rvalid_i(d_axi_rvalid_i),
    .d_axi_rready_o(d_axi_rready_o),
    .d_axi_rdata_i(d_axi_rdata_i),
    .d_axi_rresp_i(d_axi_rresp_i),
    .d_axi_awvalid_o(d_axi_awvalid_o),
    .d_axi_awready_i(d_axi_awready_i),
    .d_axi_awaddr_o(d_axi_awaddr_o),
    .d_axi_awid_o(d_axi_awid_o),
    .d_axi_awlen_o(d_axi_awlen_o),
    .d_axi_awsize_o(d_axi_awsize_o),
    .d_axi_awburst_o(d_axi_awburst_o),
    .d_axi_wvalid_o(d_axi_wvalid_o),
    .d_axi_wready_i(d_axi_wready_i),
    .d_axi_wdata_o(d_axi_wdata_o),
    .d_axi_wstrb_o(d_axi_wstrb_o),
    .d_axi_wlast_o(d_axi_wlast_o),
    .d_axi_bvalid_i(d_axi_bvalid_i),
    .d_axi_bready_o(d_axi_bready_o),
    .d_axi_bresp_i(d_axi_bresp_i)
  );

`ifdef OOO_ASSERT
  // Carrying contract: a context flush is presented only after both complete
  // bridge state holders report idle.  The children independently block
  // request READY and DTLB context hits in the event cycle.
  always @(posedge clk) begin
    if (!rst && mmu_flush_i && (!lane0_idle_o || !lane1_idle_o)) begin
      $error("[DMBW-MMU-FLUSH-NONIDLE] mmu_flush requires both bridges idle: lane0=%b lane1=%b @%0t",
             lane0_idle_o, lane1_idle_o, $time);
      $fatal;
    end
    if (!rst && mmu_flush_i &&
        (lane0_req_ready_o || lane1_req_ready_o)) begin
      $error("[DMBW-MMU-FLUSH-READY] request READY survived mmu_flush @%0t",
             $time);
      $fatal;
    end
  end
`endif

  OooMemAxiBridge #(
    .ENABLE_PEER_INVALIDATE(1)
  ) u_bridge1 (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .mmu_flush_i(mmu_flush_i),
    .dcache_dma_invalidate_all_i(dcache_dma_invalidate_all_i),
    .peer_invalidate_valid_i(lane0_peer_maintenance_valid_w),
    .peer_invalidate_addr_i(lane0_peer_maintenance_addr_w),
    .peer_invalidate_wstrb_i(lane0_peer_maintenance_wstrb_w),
    .priv_mode_i(priv_mode_i),
    .mstatus_i(mstatus_i),
    .satp_i(satp_i),
    .svpbmt_en_i(svpbmt_en_i),
    .pmpcfg_i(pmpcfg_i),
    .pmpaddr_i(pmpaddr_i),
    .mem0_req_valid_i(lane1_req_valid_i),
    .mem0_req_ready_o(lane1_req_ready_w),
    .mem0_req_write_i(lane1_req_write_i),
    .mem0_req_probe_i(lane1_req_probe_i),
    .mem0_req_pretrans_i(lane1_req_pretrans_i),
    .mem0_req_nokill_i(lane1_req_nokill_i),
    .mem0_req_attr_valid_i(lane1_req_attr_valid_i),
    .mem0_req_class_i(lane1_req_class_i),
    .mem0_req_cacheable_i(lane1_req_cacheable_i),
    .mem0_req_owner_kind_i(lane1_req_owner_kind_i),
    .mem0_req_owner_token_i(lane1_req_owner_token_i),
    .mem0_req_mmu_epoch_i(lane1_req_mmu_epoch_i),
    .mem0_req_fault_tval_i(lane1_req_fault_tval_i),
    .mem0_expected_valid_i(lane1_expected_valid_i),
    .mem0_expected_owner_kind_i(lane1_expected_owner_kind_i),
    .mem0_expected_owner_token_i(lane1_expected_owner_token_i),
    .mem0_expected_mmu_epoch_i(lane1_expected_mmu_epoch_i),
    .mem0_expected_tval_valid_i(lane1_expected_tval_valid_i),
    .mem0_expected_fault_tval_i(lane1_expected_fault_tval_i),
    .mem0_expected_effective_killed_i(lane1_expected_effective_killed_i),
    .mem0_tracker_expected_valid_i(lane1_tracker_expected_valid_i),
    .mem0_tracker_expected_owner_kind_i(
        lane1_tracker_expected_owner_kind_i),
    .mem0_tracker_expected_owner_token_i(
        lane1_tracker_expected_owner_token_i),
    .mem0_tracker_expected_mmu_epoch_i(
        lane1_tracker_expected_mmu_epoch_i),
    .mem0_station_expected_valid_i(lane1_station_expected_valid_i),
    .mem0_station_expected_owner_kind_i(
        lane1_station_expected_owner_kind_i),
    .mem0_station_expected_owner_token_i(
        lane1_station_expected_owner_token_i),
    .mem0_station_expected_mmu_epoch_i(
        lane1_station_expected_mmu_epoch_i),
    .mem0_device_release_i(lane1_device_release_i),
    .mem0_device_cancel_i(lane1_device_cancel_i),
    .mem0_req_addr_i(lane1_req_addr_i),
    .mem0_req_wdata_i(lane1_req_wdata_i),
    .mem0_req_wstrb_i(lane1_req_wstrb_i),
    .mem0_rsp_valid_o(lane1_rsp_valid_w),
    .mem0_rsp_ready_i(lane1_rsp_ready_i),
    .mem0_rsp_rdata_o(lane1_rsp_rdata_w),
    .mem0_rsp_error_o(lane1_rsp_error_w),
    .mem0_rsp_page_fault_o(lane1_rsp_page_fault_w),
    .mem0_rsp_attr_valid_o(lane1_rsp_attr_valid_w),
    .mem0_rsp_class_o(lane1_rsp_class_w),
    .mem0_rsp_cacheable_o(lane1_rsp_cacheable_w),
    .mem0_rsp_owner_kind_o(lane1_rsp_owner_kind_w),
    .mem0_rsp_owner_token_o(lane1_rsp_owner_token_w),
    .mem0_rsp_mmu_epoch_o(lane1_rsp_mmu_epoch_w),
    .mem0_rsp_fault_tval_o(lane1_rsp_fault_tval_w),
    .mem0_drop0_valid_o(lane1_drop0_valid_o),
    .mem0_drop0_owner_kind_o(lane1_drop0_owner_kind_o),
    .mem0_drop0_owner_token_o(lane1_drop0_owner_token_o),
    .mem0_drop0_mmu_epoch_o(lane1_drop0_mmu_epoch_o),
    .mem0_drop0_fault_tval_o(lane1_drop0_fault_tval_o),
    .mem0_drop1_valid_o(lane1_drop1_valid_o),
    .mem0_drop1_owner_kind_o(lane1_drop1_owner_kind_o),
    .mem0_drop1_owner_token_o(lane1_drop1_owner_token_o),
    .mem0_drop1_mmu_epoch_o(lane1_drop1_mmu_epoch_o),
    .mem0_drop1_fault_tval_o(lane1_drop1_fault_tval_o),
    .mem0_owner_query_valid_o(lane1_owner_query_valid_o),
    .mem0_owner_query_token_o(lane1_owner_query_token_o),
    .mem0_station_query_valid_o(lane1_station_query_valid_o),
    .mem0_station_query_token_o(lane1_station_query_token_o),
    .mem0_sq_query_valid_o(lane1_sq_query_valid_o),
    .mem0_sq_query_owner_kind_o(lane1_sq_query_owner_kind_o),
    .mem0_sq_query_owner_token_o(lane1_sq_query_owner_token_o),
    .mem0_sq_query_mmu_epoch_o(lane1_sq_query_mmu_epoch_o),
    .mem0_sq_query_paddr_o(lane1_sq_query_paddr_o),
    .mem0_sq_query_attr_valid_o(lane1_sq_query_attr_valid_o),
    .mem0_sq_query_class_o(lane1_sq_query_class_o),
    .mem0_sq_query_wstrb_o(lane1_sq_query_wstrb_o),
    .mem0_sq_query_allow_i(lane1_sq_query_allow_i),
    .mem0_sq_query_forward_i(lane1_sq_query_forward_i),
    .mem0_sq_query_replay_i(lane1_sq_query_replay_i),
    .mem0_sq_query_retry_ready_i(lane1_sq_query_retry_ready_i),
    .mem0_sq_query_forward_data_i(lane1_sq_query_forward_data_i),
    .mem0_owner_residency_mask_o(lane1_owner_residency_mask_o),
    .mem0_idle_o(lane1_idle_o),
    .translate_active_o(lane1_translate_active_o),
    .peer_maintenance_valid_o(lane1_peer_maintenance_valid_w),
    .peer_maintenance_addr_o(lane1_peer_maintenance_addr_w),
    .peer_maintenance_wstrb_o(lane1_peer_maintenance_wstrb_w),
    .lsu_axi_arvalid_o(lane1_axi_arvalid_w),
    .lsu_axi_arready_i(lane1_axi_arready_w),
    .lsu_axi_araddr_o(lane1_axi_araddr_w),
    .lsu_axi_arid_o(lane1_axi_arid_w),
    .lsu_axi_arlen_o(lane1_axi_arlen_w),
    .lsu_axi_arsize_o(lane1_axi_arsize_w),
    .lsu_axi_arburst_o(lane1_axi_arburst_w),
    .lsu_axi_arprot_o(lane1_axi_arprot_w),
    .lsu_axi_rvalid_i(lane1_axi_rvalid_w),
    .lsu_axi_rready_o(lane1_axi_rready_w),
    .lsu_axi_rdata_i(lane1_axi_rdata_w),
    .lsu_axi_rresp_i(lane1_axi_rresp_w),
    .lsu_axi_awvalid_o(lane1_axi_awvalid_w),
    .lsu_axi_awready_i(lane1_axi_awready_w),
    .lsu_axi_awaddr_o(lane1_axi_awaddr_w),
    .lsu_axi_awid_o(lane1_axi_awid_w),
    .lsu_axi_awlen_o(lane1_axi_awlen_w),
    .lsu_axi_awsize_o(lane1_axi_awsize_w),
    .lsu_axi_awburst_o(lane1_axi_awburst_w),
    .lsu_axi_wvalid_o(lane1_axi_wvalid_w),
    .lsu_axi_wready_i(lane1_axi_wready_w),
    .lsu_axi_wdata_o(lane1_axi_wdata_w),
    .lsu_axi_wstrb_o(lane1_axi_wstrb_w),
    .lsu_axi_wlast_o(lane1_axi_wlast_w),
    .lsu_axi_bvalid_i(lane1_axi_bvalid_w),
    .lsu_axi_bready_o(lane1_axi_bready_w),
    .lsu_axi_bresp_i(lane1_axi_bresp_w)
  );

endmodule
