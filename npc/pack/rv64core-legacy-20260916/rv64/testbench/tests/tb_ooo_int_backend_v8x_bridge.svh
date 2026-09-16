`ifdef V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
// V8X focused integration adapter.
//
// This include is active only in V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED builds.
// It replaces the leaf backend testbench's hand-written memory model with the
// canonical two-bridge wrapper.  Every owner/query/terminal face is connected
// to OooIntBackend; only the shared AXI slave remains a testbench model.

  localparam [`PMP_CFG_BUS_W-1:0] V8X_PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] V8X_PMP_ALLOW_ALL_ADDR =
      {`PMP_ADDR_BUS_W{1'b1}};

`ifdef V13Q_BACKEND_BRIDGE_STORE_ERROR_BP_FOCUSED
  // V13Q drives one real Sv39 root-leaf translation so the store's original
  // VA and final AXI PA differ; this makes the cause/tval oracle source-sensitive.
  reg [1:0] v13q_priv_mode;
  reg [`XLEN-1:0] v13q_satp;
  wire [1:0] v8x_priv_mode_cfg = v13q_priv_mode;
  wire [`XLEN-1:0] v8x_satp_cfg = v13q_satp;
`else
  wire [1:0] v8x_priv_mode_cfg = `PRIV_M;
  wire [`XLEN-1:0] v8x_satp_cfg = {`XLEN{1'b0}};
`endif

  wire v8x_lane0_req_ready;
  wire v8x_lane0_rsp_valid;
  wire [`XLEN-1:0] v8x_lane0_rsp_rdata;
  wire v8x_lane0_rsp_error;
  wire v8x_lane0_rsp_page_fault;
  wire v8x_lane0_rsp_attr_valid;
  wire [1:0] v8x_lane0_rsp_class;
  wire v8x_lane0_rsp_cacheable;
  wire [1:0] v8x_lane0_rsp_owner_kind;
  wire [4:0] v8x_lane0_rsp_owner_token;
  wire [1:0] v8x_lane0_rsp_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane0_rsp_fault_tval;
  wire v8x_lane0_drop0_valid;
  wire [1:0] v8x_lane0_drop0_owner_kind;
  wire [4:0] v8x_lane0_drop0_owner_token;
  wire [1:0] v8x_lane0_drop0_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane0_drop0_fault_tval;
  wire v8x_lane0_drop1_valid;
  wire [1:0] v8x_lane0_drop1_owner_kind;
  wire [4:0] v8x_lane0_drop1_owner_token;
  wire [1:0] v8x_lane0_drop1_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane0_drop1_fault_tval;
  wire v8x_lane0_owner_query_valid;
  wire [4:0] v8x_lane0_owner_query_token;
  wire v8x_lane0_station_query_valid;
  wire [4:0] v8x_lane0_station_query_token;
  wire v8x_lane0_sq_query_valid;
  wire [1:0] v8x_lane0_sq_query_owner_kind;
  wire [4:0] v8x_lane0_sq_query_owner_token;
  wire [1:0] v8x_lane0_sq_query_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane0_sq_query_paddr;
  wire v8x_lane0_sq_query_attr_valid;
  wire [1:0] v8x_lane0_sq_query_class;
  wire [`STRB_W-1:0] v8x_lane0_sq_query_wstrb;
  wire [31:0] v8x_lane0_owner_residency_mask;
  wire v8x_lane0_idle;
  wire v8x_lane0_translate_active;

  wire v8x_lane1_req_ready;
  wire v8x_lane1_rsp_valid;
  wire [`XLEN-1:0] v8x_lane1_rsp_rdata;
  wire v8x_lane1_rsp_error;
  wire v8x_lane1_rsp_page_fault;
  wire v8x_lane1_rsp_attr_valid;
  wire [1:0] v8x_lane1_rsp_class;
  wire v8x_lane1_rsp_cacheable;
  wire [1:0] v8x_lane1_rsp_owner_kind;
  wire [4:0] v8x_lane1_rsp_owner_token;
  wire [1:0] v8x_lane1_rsp_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane1_rsp_fault_tval;
  wire v8x_lane1_drop0_valid;
  wire [1:0] v8x_lane1_drop0_owner_kind;
  wire [4:0] v8x_lane1_drop0_owner_token;
  wire [1:0] v8x_lane1_drop0_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane1_drop0_fault_tval;
  wire v8x_lane1_drop1_valid;
  wire [1:0] v8x_lane1_drop1_owner_kind;
  wire [4:0] v8x_lane1_drop1_owner_token;
  wire [1:0] v8x_lane1_drop1_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane1_drop1_fault_tval;
  wire v8x_lane1_owner_query_valid;
  wire [4:0] v8x_lane1_owner_query_token;
  wire v8x_lane1_station_query_valid;
  wire [4:0] v8x_lane1_station_query_token;
  wire v8x_lane1_sq_query_valid;
  wire [1:0] v8x_lane1_sq_query_owner_kind;
  wire [4:0] v8x_lane1_sq_query_owner_token;
  wire [1:0] v8x_lane1_sq_query_mmu_epoch;
  wire [`XLEN-1:0] v8x_lane1_sq_query_paddr;
  wire v8x_lane1_sq_query_attr_valid;
  wire [1:0] v8x_lane1_sq_query_class;
  wire [`STRB_W-1:0] v8x_lane1_sq_query_wstrb;
  wire [31:0] v8x_lane1_owner_residency_mask;
  wire v8x_lane1_idle;
  wire v8x_lane1_translate_active;

  wire v8x_d_axi_arvalid;
  reg v8x_d_axi_arready;
  wire [`XLEN-1:0] v8x_d_axi_araddr;
  wire [3:0] v8x_d_axi_arid;
  wire [7:0] v8x_d_axi_arlen;
  wire [2:0] v8x_d_axi_arsize;
  wire [1:0] v8x_d_axi_arburst;
  wire [2:0] v8x_d_axi_arprot;
  reg v8x_d_axi_rvalid;
  wire v8x_d_axi_rready;
  reg [`XLEN-1:0] v8x_d_axi_rdata;
  reg [1:0] v8x_d_axi_rresp;
  wire v8x_d_axi_awvalid;
  reg v8x_d_axi_awready;
  wire [`XLEN-1:0] v8x_d_axi_awaddr;
  wire [3:0] v8x_d_axi_awid;
  wire [7:0] v8x_d_axi_awlen;
  wire [2:0] v8x_d_axi_awsize;
  wire [1:0] v8x_d_axi_awburst;
  wire v8x_d_axi_wvalid;
  reg v8x_d_axi_wready;
  wire [`XLEN-1:0] v8x_d_axi_wdata;
  wire [`STRB_W-1:0] v8x_d_axi_wstrb;
  wire v8x_d_axi_wlast;
  reg v8x_d_axi_bvalid;
  wire v8x_d_axi_bready;
  reg [1:0] v8x_d_axi_bresp;

  OooDualMemBridgeWrapper v8x_bridge (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .control_full_flush_barrier_i(1'b0),
    .mmu_flush_i(1'b0),
    .dcache_dma_invalidate_all_i(1'b0),
    .priv_mode_i(v8x_priv_mode_cfg),
    .mstatus_i({`XLEN{1'b0}}),
    .satp_i(v8x_satp_cfg),
    .svpbmt_en_i(1'b0),
    .pmpcfg_i(V8X_PMP_ALLOW_ALL_CFG),
    .pmpaddr_i(V8X_PMP_ALLOW_ALL_ADDR),

    .lane0_req_valid_i(mem_req_valid),
    .lane0_req_ready_o(v8x_lane0_req_ready),
    .lane0_req_write_i(mem_req_write),
    .lane0_req_probe_i(mem_req_probe),
    .lane0_req_pretrans_i(mem_req_pretrans),
    .lane0_req_nokill_i(mem_req_nokill),
    .lane0_req_attr_valid_i(mem_req_attr_valid),
    .lane0_req_class_i(mem_req_class),
    .lane0_req_cacheable_i(mem_req_cacheable),
    .lane0_req_owner_kind_i(mem_req_owner_kind),
    .lane0_req_owner_token_i(mem_req_owner_token),
    .lane0_req_mmu_epoch_i(mem_req_mmu_epoch),
    .lane0_req_fault_tval_i(mem_req_fault_tval),
    .lane0_expected_valid_i(mem_expected_valid),
    .lane0_expected_owner_kind_i(mem_expected_owner_kind),
    .lane0_expected_owner_token_i(mem_expected_owner_token),
    .lane0_expected_mmu_epoch_i(mem_expected_mmu_epoch),
    .lane0_expected_tval_valid_i(mem_expected_tval_valid),
    .lane0_expected_fault_tval_i(mem_expected_fault_tval),
    .lane0_expected_effective_killed_i(mem_expected_effective_killed),
    .lane0_tracker_expected_valid_i(mem_tracker_expected_valid),
    .lane0_tracker_expected_owner_kind_i(mem_tracker_expected_owner_kind),
    .lane0_tracker_expected_owner_token_i(mem_tracker_expected_owner_token),
    .lane0_tracker_expected_mmu_epoch_i(mem_tracker_expected_mmu_epoch),
    .lane0_station_expected_valid_i(mem_station_expected_valid),
    .lane0_station_expected_owner_kind_i(mem_station_expected_owner_kind),
    .lane0_station_expected_owner_token_i(mem_station_expected_owner_token),
    .lane0_station_expected_mmu_epoch_i(mem_station_expected_mmu_epoch),
    .lane0_device_release_i(mem_req_device_release),
    .lane0_device_cancel_i(mem_req_device_cancel),
    .lane0_req_addr_i(mem_req_addr),
    .lane0_req_wdata_i(mem_req_wdata),
    .lane0_req_wstrb_i(mem_req_wstrb),
    .lane0_rsp_valid_o(v8x_lane0_rsp_valid),
    .lane0_rsp_ready_i(mem_rsp_ready),
    .lane0_rsp_rdata_o(v8x_lane0_rsp_rdata),
    .lane0_rsp_error_o(v8x_lane0_rsp_error),
    .lane0_rsp_page_fault_o(v8x_lane0_rsp_page_fault),
    .lane0_rsp_attr_valid_o(v8x_lane0_rsp_attr_valid),
    .lane0_rsp_class_o(v8x_lane0_rsp_class),
    .lane0_rsp_cacheable_o(v8x_lane0_rsp_cacheable),
    .lane0_rsp_owner_kind_o(v8x_lane0_rsp_owner_kind),
    .lane0_rsp_owner_token_o(v8x_lane0_rsp_owner_token),
    .lane0_rsp_mmu_epoch_o(v8x_lane0_rsp_mmu_epoch),
    .lane0_rsp_fault_tval_o(v8x_lane0_rsp_fault_tval),
    .lane0_drop0_valid_o(v8x_lane0_drop0_valid),
    .lane0_drop0_owner_kind_o(v8x_lane0_drop0_owner_kind),
    .lane0_drop0_owner_token_o(v8x_lane0_drop0_owner_token),
    .lane0_drop0_mmu_epoch_o(v8x_lane0_drop0_mmu_epoch),
    .lane0_drop0_fault_tval_o(v8x_lane0_drop0_fault_tval),
    .lane0_drop1_valid_o(v8x_lane0_drop1_valid),
    .lane0_drop1_owner_kind_o(v8x_lane0_drop1_owner_kind),
    .lane0_drop1_owner_token_o(v8x_lane0_drop1_owner_token),
    .lane0_drop1_mmu_epoch_o(v8x_lane0_drop1_mmu_epoch),
    .lane0_drop1_fault_tval_o(v8x_lane0_drop1_fault_tval),
    .lane0_owner_query_valid_o(v8x_lane0_owner_query_valid),
    .lane0_owner_query_token_o(v8x_lane0_owner_query_token),
    .lane0_station_query_valid_o(v8x_lane0_station_query_valid),
    .lane0_station_query_token_o(v8x_lane0_station_query_token),
    .lane0_sq_query_valid_o(v8x_lane0_sq_query_valid),
    .lane0_sq_query_owner_kind_o(v8x_lane0_sq_query_owner_kind),
    .lane0_sq_query_owner_token_o(v8x_lane0_sq_query_owner_token),
    .lane0_sq_query_mmu_epoch_o(v8x_lane0_sq_query_mmu_epoch),
    .lane0_sq_query_paddr_o(v8x_lane0_sq_query_paddr),
    .lane0_sq_query_attr_valid_o(v8x_lane0_sq_query_attr_valid),
    .lane0_sq_query_class_o(v8x_lane0_sq_query_class),
    .lane0_sq_query_wstrb_o(v8x_lane0_sq_query_wstrb),
    .lane0_sq_query_allow_i(mem_sq_query_allow),
    .lane0_sq_query_forward_i(mem_sq_query_forward),
    .lane0_sq_query_replay_i(mem_sq_query_replay),
    .lane0_sq_query_retry_ready_i(mem_sq_query_retry_ready),
    .lane0_sq_query_forward_data_i(mem_sq_query_forward_data),
    .lane0_owner_residency_mask_o(v8x_lane0_owner_residency_mask),
    .lane0_idle_o(v8x_lane0_idle),
    .lane0_translate_active_o(v8x_lane0_translate_active),

    .lane1_req_valid_i(mem1_req_valid),
    .lane1_req_ready_o(v8x_lane1_req_ready),
    .lane1_req_write_i(mem1_req_write),
    .lane1_req_probe_i(mem1_req_probe),
    .lane1_req_pretrans_i(mem1_req_pretrans),
    .lane1_req_nokill_i(mem1_req_nokill),
    .lane1_req_attr_valid_i(mem1_req_attr_valid),
    .lane1_req_class_i(mem1_req_class),
    .lane1_req_cacheable_i(mem1_req_cacheable),
    .lane1_req_owner_kind_i(mem1_req_owner_kind),
    .lane1_req_owner_token_i(mem1_req_owner_token),
    .lane1_req_mmu_epoch_i(mem1_req_mmu_epoch),
    .lane1_req_fault_tval_i(mem1_req_fault_tval),
    .lane1_expected_valid_i(mem1_expected_valid),
    .lane1_expected_owner_kind_i(mem1_expected_owner_kind),
    .lane1_expected_owner_token_i(mem1_expected_owner_token),
    .lane1_expected_mmu_epoch_i(mem1_expected_mmu_epoch),
    .lane1_expected_tval_valid_i(mem1_expected_tval_valid),
    .lane1_expected_fault_tval_i(mem1_expected_fault_tval),
    .lane1_expected_effective_killed_i(mem1_expected_effective_killed),
    .lane1_tracker_expected_valid_i(mem1_tracker_expected_valid),
    .lane1_tracker_expected_owner_kind_i(mem1_tracker_expected_owner_kind),
    .lane1_tracker_expected_owner_token_i(mem1_tracker_expected_owner_token),
    .lane1_tracker_expected_mmu_epoch_i(mem1_tracker_expected_mmu_epoch),
    .lane1_station_expected_valid_i(mem1_station_expected_valid),
    .lane1_station_expected_owner_kind_i(mem1_station_expected_owner_kind),
    .lane1_station_expected_owner_token_i(mem1_station_expected_owner_token),
    .lane1_station_expected_mmu_epoch_i(mem1_station_expected_mmu_epoch),
    .lane1_device_release_i(mem1_req_device_release),
    .lane1_device_cancel_i(mem1_req_device_cancel),
    .lane1_req_addr_i(mem1_req_addr),
    .lane1_req_wdata_i(mem1_req_wdata),
    .lane1_req_wstrb_i(mem1_req_wstrb),
    .lane1_rsp_valid_o(v8x_lane1_rsp_valid),
    .lane1_rsp_ready_i(mem1_rsp_ready),
    .lane1_rsp_rdata_o(v8x_lane1_rsp_rdata),
    .lane1_rsp_error_o(v8x_lane1_rsp_error),
    .lane1_rsp_page_fault_o(v8x_lane1_rsp_page_fault),
    .lane1_rsp_attr_valid_o(v8x_lane1_rsp_attr_valid),
    .lane1_rsp_class_o(v8x_lane1_rsp_class),
    .lane1_rsp_cacheable_o(v8x_lane1_rsp_cacheable),
    .lane1_rsp_owner_kind_o(v8x_lane1_rsp_owner_kind),
    .lane1_rsp_owner_token_o(v8x_lane1_rsp_owner_token),
    .lane1_rsp_mmu_epoch_o(v8x_lane1_rsp_mmu_epoch),
    .lane1_rsp_fault_tval_o(v8x_lane1_rsp_fault_tval),
    .lane1_drop0_valid_o(v8x_lane1_drop0_valid),
    .lane1_drop0_owner_kind_o(v8x_lane1_drop0_owner_kind),
    .lane1_drop0_owner_token_o(v8x_lane1_drop0_owner_token),
    .lane1_drop0_mmu_epoch_o(v8x_lane1_drop0_mmu_epoch),
    .lane1_drop0_fault_tval_o(v8x_lane1_drop0_fault_tval),
    .lane1_drop1_valid_o(v8x_lane1_drop1_valid),
    .lane1_drop1_owner_kind_o(v8x_lane1_drop1_owner_kind),
    .lane1_drop1_owner_token_o(v8x_lane1_drop1_owner_token),
    .lane1_drop1_mmu_epoch_o(v8x_lane1_drop1_mmu_epoch),
    .lane1_drop1_fault_tval_o(v8x_lane1_drop1_fault_tval),
    .lane1_owner_query_valid_o(v8x_lane1_owner_query_valid),
    .lane1_owner_query_token_o(v8x_lane1_owner_query_token),
    .lane1_station_query_valid_o(v8x_lane1_station_query_valid),
    .lane1_station_query_token_o(v8x_lane1_station_query_token),
    .lane1_sq_query_valid_o(v8x_lane1_sq_query_valid),
    .lane1_sq_query_owner_kind_o(v8x_lane1_sq_query_owner_kind),
    .lane1_sq_query_owner_token_o(v8x_lane1_sq_query_owner_token),
    .lane1_sq_query_mmu_epoch_o(v8x_lane1_sq_query_mmu_epoch),
    .lane1_sq_query_paddr_o(v8x_lane1_sq_query_paddr),
    .lane1_sq_query_attr_valid_o(v8x_lane1_sq_query_attr_valid),
    .lane1_sq_query_class_o(v8x_lane1_sq_query_class),
    .lane1_sq_query_wstrb_o(v8x_lane1_sq_query_wstrb),
    .lane1_sq_query_allow_i(mem1_sq_query_allow),
    .lane1_sq_query_forward_i(mem1_sq_query_forward),
    .lane1_sq_query_replay_i(mem1_sq_query_replay),
    .lane1_sq_query_retry_ready_i(mem1_sq_query_retry_ready),
    .lane1_sq_query_forward_data_i(mem1_sq_query_forward_data),
    .lane1_owner_residency_mask_o(v8x_lane1_owner_residency_mask),
    .lane1_idle_o(v8x_lane1_idle),
    .lane1_translate_active_o(v8x_lane1_translate_active),

    .d_axi_arvalid_o(v8x_d_axi_arvalid),
    .d_axi_arready_i(v8x_d_axi_arready),
    .d_axi_araddr_o(v8x_d_axi_araddr),
    .d_axi_arid_o(v8x_d_axi_arid),
    .d_axi_arlen_o(v8x_d_axi_arlen),
    .d_axi_arsize_o(v8x_d_axi_arsize),
    .d_axi_arburst_o(v8x_d_axi_arburst),
    .d_axi_arprot_o(v8x_d_axi_arprot),
    .d_axi_rvalid_i(v8x_d_axi_rvalid),
    .d_axi_rready_o(v8x_d_axi_rready),
    .d_axi_rdata_i(v8x_d_axi_rdata),
    .d_axi_rresp_i(v8x_d_axi_rresp),
    .d_axi_awvalid_o(v8x_d_axi_awvalid),
    .d_axi_awready_i(v8x_d_axi_awready),
    .d_axi_awaddr_o(v8x_d_axi_awaddr),
    .d_axi_awid_o(v8x_d_axi_awid),
    .d_axi_awlen_o(v8x_d_axi_awlen),
    .d_axi_awsize_o(v8x_d_axi_awsize),
    .d_axi_awburst_o(v8x_d_axi_awburst),
    .d_axi_wvalid_o(v8x_d_axi_wvalid),
    .d_axi_wready_i(v8x_d_axi_wready),
    .d_axi_wdata_o(v8x_d_axi_wdata),
    .d_axi_wstrb_o(v8x_d_axi_wstrb),
    .d_axi_wlast_o(v8x_d_axi_wlast),
    .d_axi_bvalid_i(v8x_d_axi_bvalid),
    .d_axi_bready_o(v8x_d_axi_bready),
    .d_axi_bresp_i(v8x_d_axi_bresp)
  );

  wire backend_mem_req_ready_i = v8x_lane0_req_ready;
  wire backend_mem_rsp_valid_i = v8x_lane0_rsp_valid;
  wire [`XLEN-1:0] backend_mem_rsp_rdata_i = v8x_lane0_rsp_rdata;
  wire backend_mem_rsp_error_i = v8x_lane0_rsp_error;
  wire backend_mem_rsp_page_fault_i = v8x_lane0_rsp_page_fault;
  wire backend_mem_rsp_attr_valid_i = v8x_lane0_rsp_attr_valid;
  wire [1:0] backend_mem_rsp_class_i = v8x_lane0_rsp_class;
  wire backend_mem_rsp_cacheable_i = v8x_lane0_rsp_cacheable;
  wire [1:0] backend_mem_rsp_owner_kind_i = v8x_lane0_rsp_owner_kind;
  wire [4:0] backend_mem_rsp_owner_token_i = v8x_lane0_rsp_owner_token;
  wire [1:0] backend_mem_rsp_mmu_epoch_i = v8x_lane0_rsp_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_rsp_fault_tval_i =
      v8x_lane0_rsp_fault_tval;
  wire backend_mem_owner_query_valid_i = v8x_lane0_owner_query_valid;
  wire [4:0] backend_mem_owner_query_token_i =
      v8x_lane0_owner_query_token;
  wire backend_mem_station_query_valid_i = v8x_lane0_station_query_valid;
  wire [4:0] backend_mem_station_query_token_i =
      v8x_lane0_station_query_token;
  wire backend_mem_drop0_valid_i = v8x_lane0_drop0_valid;
  wire [1:0] backend_mem_drop0_owner_kind_i =
      v8x_lane0_drop0_owner_kind;
  wire [4:0] backend_mem_drop0_owner_token_i =
      v8x_lane0_drop0_owner_token;
  wire [1:0] backend_mem_drop0_mmu_epoch_i =
      v8x_lane0_drop0_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_drop0_fault_tval_i =
      v8x_lane0_drop0_fault_tval;
  wire backend_mem_drop1_valid_i = v8x_lane0_drop1_valid;
  wire [1:0] backend_mem_drop1_owner_kind_i =
      v8x_lane0_drop1_owner_kind;
  wire [4:0] backend_mem_drop1_owner_token_i =
      v8x_lane0_drop1_owner_token;
  wire [1:0] backend_mem_drop1_mmu_epoch_i =
      v8x_lane0_drop1_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_drop1_fault_tval_i =
      v8x_lane0_drop1_fault_tval;
  wire [31:0] backend_mem_bridge_owner_residency_mask_i =
      v8x_lane0_owner_residency_mask;
  wire backend_mem_sq_query_valid_i = v8x_lane0_sq_query_valid;
  wire [1:0] backend_mem_sq_query_owner_kind_i =
      v8x_lane0_sq_query_owner_kind;
  wire [4:0] backend_mem_sq_query_owner_token_i =
      v8x_lane0_sq_query_owner_token;
  wire [1:0] backend_mem_sq_query_mmu_epoch_i =
      v8x_lane0_sq_query_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_sq_query_paddr_i =
      v8x_lane0_sq_query_paddr;
  wire backend_mem_sq_query_attr_valid_i =
      v8x_lane0_sq_query_attr_valid;
  wire [1:0] backend_mem_sq_query_class_i = v8x_lane0_sq_query_class;
  wire [`STRB_W-1:0] backend_mem_sq_query_wstrb_i =
      v8x_lane0_sq_query_wstrb;
  wire backend_mem_translate_active_i = v8x_lane0_translate_active;

  wire backend_mem1_req_ready_i = v8x_lane1_req_ready;
  wire backend_mem1_rsp_valid_i = v8x_lane1_rsp_valid;
  wire [`XLEN-1:0] backend_mem1_rsp_rdata_i = v8x_lane1_rsp_rdata;
  wire backend_mem1_rsp_error_i = v8x_lane1_rsp_error;
  wire backend_mem1_rsp_page_fault_i = v8x_lane1_rsp_page_fault;
  wire backend_mem1_rsp_attr_valid_i = v8x_lane1_rsp_attr_valid;
  wire [1:0] backend_mem1_rsp_class_i = v8x_lane1_rsp_class;
  wire backend_mem1_rsp_cacheable_i = v8x_lane1_rsp_cacheable;
  wire [1:0] backend_mem1_rsp_owner_kind_i = v8x_lane1_rsp_owner_kind;
  wire [4:0] backend_mem1_rsp_owner_token_i = v8x_lane1_rsp_owner_token;
  wire [1:0] backend_mem1_rsp_mmu_epoch_i = v8x_lane1_rsp_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_rsp_fault_tval_i =
      v8x_lane1_rsp_fault_tval;
  wire backend_mem1_owner_query_valid_i = v8x_lane1_owner_query_valid;
  wire [4:0] backend_mem1_owner_query_token_i =
      v8x_lane1_owner_query_token;
  wire backend_mem1_station_query_valid_i = v8x_lane1_station_query_valid;
  wire [4:0] backend_mem1_station_query_token_i =
      v8x_lane1_station_query_token;
  wire backend_mem1_drop0_valid_i = v8x_lane1_drop0_valid;
  wire [1:0] backend_mem1_drop0_owner_kind_i =
      v8x_lane1_drop0_owner_kind;
  wire [4:0] backend_mem1_drop0_owner_token_i =
      v8x_lane1_drop0_owner_token;
  wire [1:0] backend_mem1_drop0_mmu_epoch_i =
      v8x_lane1_drop0_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_drop0_fault_tval_i =
      v8x_lane1_drop0_fault_tval;
  wire backend_mem1_drop1_valid_i = v8x_lane1_drop1_valid;
  wire [1:0] backend_mem1_drop1_owner_kind_i =
      v8x_lane1_drop1_owner_kind;
  wire [4:0] backend_mem1_drop1_owner_token_i =
      v8x_lane1_drop1_owner_token;
  wire [1:0] backend_mem1_drop1_mmu_epoch_i =
      v8x_lane1_drop1_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_drop1_fault_tval_i =
      v8x_lane1_drop1_fault_tval;
  wire [31:0] backend_mem1_bridge_owner_residency_mask_i =
      v8x_lane1_owner_residency_mask;
  wire backend_mem1_sq_query_valid_i = v8x_lane1_sq_query_valid;
  wire [1:0] backend_mem1_sq_query_owner_kind_i =
      v8x_lane1_sq_query_owner_kind;
  wire [4:0] backend_mem1_sq_query_owner_token_i =
      v8x_lane1_sq_query_owner_token;
  wire [1:0] backend_mem1_sq_query_mmu_epoch_i =
      v8x_lane1_sq_query_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_sq_query_paddr_i =
      v8x_lane1_sq_query_paddr;
  wire backend_mem1_sq_query_attr_valid_i =
      v8x_lane1_sq_query_attr_valid;
  wire [1:0] backend_mem1_sq_query_class_i = v8x_lane1_sq_query_class;
  wire [`STRB_W-1:0] backend_mem1_sq_query_wstrb_i =
      v8x_lane1_sq_query_wstrb;
  wire backend_mem1_translate_active_i = v8x_lane1_translate_active;

`else
  // Preserve the established leaf-backend memory model for every existing
  // configuration.  OooIntBackend consumes one uniform set of adapter wires,
  // so the V8X wrapper cannot perturb non-V8X tests.
  wire backend_mem_req_ready_i = mem_req_ready;
  wire backend_mem_rsp_valid_i = mem_rsp_valid;
  wire [`XLEN-1:0] backend_mem_rsp_rdata_i = mem_rsp_rdata;
  wire backend_mem_rsp_error_i = mem_rsp_error;
  wire backend_mem_rsp_page_fault_i = 1'b0;
  wire backend_mem_rsp_attr_valid_i = tb_mem_rsp_attr_valid;
  wire [1:0] backend_mem_rsp_class_i = tb_mem_rsp_class;
  wire backend_mem_rsp_cacheable_i = mem_rsp_cacheable;
  wire [1:0] backend_mem_rsp_owner_kind_i = mem_expected_owner_kind;
  wire [4:0] backend_mem_rsp_owner_token_i = mem_expected_owner_token;
  wire [1:0] backend_mem_rsp_mmu_epoch_i = mem_expected_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_rsp_fault_tval_i =
      mem_expected_fault_tval;
  wire backend_mem_owner_query_valid_i = mem_owner_query_valid;
  wire [4:0] backend_mem_owner_query_token_i = mem_owner_query_token;
  wire backend_mem_station_query_valid_i = mem_station_query_valid;
  wire [4:0] backend_mem_station_query_token_i = mem_station_query_token;
  wire backend_mem_drop0_valid_i = tb_mem_drop0_valid;
  wire [1:0] backend_mem_drop0_owner_kind_i = tb_mem_drop0_owner_kind;
  wire [4:0] backend_mem_drop0_owner_token_i = tb_mem_drop0_owner_token;
  wire [1:0] backend_mem_drop0_mmu_epoch_i = tb_mem_drop0_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_drop0_fault_tval_i =
      tb_mem_drop0_fault_tval;
  wire backend_mem_drop1_valid_i = 1'b0;
  wire [1:0] backend_mem_drop1_owner_kind_i = 2'b11;
  wire [4:0] backend_mem_drop1_owner_token_i = 5'b0;
  wire [1:0] backend_mem_drop1_mmu_epoch_i = 2'b0;
  wire [`XLEN-1:0] backend_mem_drop1_fault_tval_i = {`XLEN{1'b0}};
  wire [31:0] backend_mem_bridge_owner_residency_mask_i = 32'b0;
  wire backend_mem_sq_query_valid_i = mem_sq_query_valid;
  wire [1:0] backend_mem_sq_query_owner_kind_i = mem_sq_query_owner_kind;
  wire [4:0] backend_mem_sq_query_owner_token_i = mem_sq_query_owner_token;
  wire [1:0] backend_mem_sq_query_mmu_epoch_i = mem_sq_query_mmu_epoch;
  wire [`XLEN-1:0] backend_mem_sq_query_paddr_i = mem_sq_query_paddr;
  wire backend_mem_sq_query_attr_valid_i = mem_sq_query_attr_valid;
  wire [1:0] backend_mem_sq_query_class_i = mem_sq_query_class;
  wire [`STRB_W-1:0] backend_mem_sq_query_wstrb_i = mem_sq_query_wstrb;
  wire backend_mem_translate_active_i = mem_translate_active;

  wire backend_mem1_req_ready_i = mem1_req_ready;
  wire backend_mem1_rsp_valid_i = mem1_rsp_valid;
  wire [`XLEN-1:0] backend_mem1_rsp_rdata_i = mem1_rsp_rdata;
  wire backend_mem1_rsp_error_i = mem1_rsp_error;
  wire backend_mem1_rsp_page_fault_i = 1'b0;
  wire backend_mem1_rsp_attr_valid_i = tb_mem1_rsp_attr_valid;
  wire [1:0] backend_mem1_rsp_class_i = tb_mem1_rsp_class;
  wire backend_mem1_rsp_cacheable_i = mem1_rsp_cacheable;
  wire [1:0] backend_mem1_rsp_owner_kind_i = mem1_expected_owner_kind;
  wire [4:0] backend_mem1_rsp_owner_token_i = mem1_expected_owner_token;
  wire [1:0] backend_mem1_rsp_mmu_epoch_i = mem1_expected_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_rsp_fault_tval_i =
      mem1_expected_fault_tval;
  wire backend_mem1_owner_query_valid_i = mem1_owner_query_valid;
  wire [4:0] backend_mem1_owner_query_token_i = mem1_owner_query_token;
  wire backend_mem1_station_query_valid_i = mem1_station_query_valid;
  wire [4:0] backend_mem1_station_query_token_i =
      mem1_station_query_token;
  wire backend_mem1_drop0_valid_i = tb_mem1_drop0_valid;
  wire [1:0] backend_mem1_drop0_owner_kind_i = tb_mem1_drop0_owner_kind;
  wire [4:0] backend_mem1_drop0_owner_token_i = tb_mem1_drop0_owner_token;
  wire [1:0] backend_mem1_drop0_mmu_epoch_i = tb_mem1_drop0_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_drop0_fault_tval_i =
      tb_mem1_drop0_fault_tval;
  wire backend_mem1_drop1_valid_i = 1'b0;
  wire [1:0] backend_mem1_drop1_owner_kind_i = 2'b11;
  wire [4:0] backend_mem1_drop1_owner_token_i = 5'b0;
  wire [1:0] backend_mem1_drop1_mmu_epoch_i = 2'b0;
  wire [`XLEN-1:0] backend_mem1_drop1_fault_tval_i = {`XLEN{1'b0}};
  wire [31:0] backend_mem1_bridge_owner_residency_mask_i = 32'b0;
  wire backend_mem1_sq_query_valid_i = mem1_sq_query_valid;
  wire [1:0] backend_mem1_sq_query_owner_kind_i =
      mem1_sq_query_owner_kind;
  wire [4:0] backend_mem1_sq_query_owner_token_i =
      mem1_sq_query_owner_token;
  wire [1:0] backend_mem1_sq_query_mmu_epoch_i =
      mem1_sq_query_mmu_epoch;
  wire [`XLEN-1:0] backend_mem1_sq_query_paddr_i = mem1_sq_query_paddr;
  wire backend_mem1_sq_query_attr_valid_i = mem1_sq_query_attr_valid;
  wire [1:0] backend_mem1_sq_query_class_i = mem1_sq_query_class;
  wire [`STRB_W-1:0] backend_mem1_sq_query_wstrb_i = mem1_sq_query_wstrb;
  wire backend_mem1_translate_active_i = mem1_translate_active;
`endif
