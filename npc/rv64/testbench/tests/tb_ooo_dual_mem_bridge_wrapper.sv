`include "define.v"

module tb_ooo_dual_mem_bridge_wrapper;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush_i;
  reg control_full_flush_barrier_i;
  reg mmu_flush_i;
  reg dcache_dma_invalidate_all_i;
  reg ifu_ad_update_invalidate_all_i;
  reg [1:0] priv_mode_i;
  reg [`XLEN-1:0] mstatus_i;
  reg [`XLEN-1:0] satp_i;
  reg svpbmt_en_i;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg_i;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr_i;

  reg lane0_req_valid_i;
  wire lane0_req_ready_o;
  reg lane0_req_write_i;
  reg lane0_req_probe_i;
  reg lane0_req_pretrans_i;
  reg lane0_req_nokill_i;
  reg lane0_req_attr_valid_i;
  reg [1:0] lane0_req_class_i;
  reg lane0_req_cacheable_i;
  wire [1:0] lane0_req_owner_kind_i =
      lane0_req_write_i ? 2'b01 : 2'b00;
  reg [4:0] lane0_req_owner_token_i;
  wire [1:0] lane0_req_mmu_epoch_i = 2'b01;
  wire [`XLEN-1:0] lane0_req_fault_tval_i = lane0_req_addr_i;
  reg lane0_expected_effective_killed_i;
  reg lane0_device_release_i;
  reg lane0_device_cancel_i;
  reg [`XLEN-1:0] lane0_req_addr_i;
  reg [`XLEN-1:0] lane0_req_wdata_i;
  reg [`STRB_W-1:0] lane0_req_wstrb_i;
  wire lane0_rsp_valid_o;
  reg lane0_rsp_ready_i;
  wire [`XLEN-1:0] lane0_rsp_rdata_o;
  wire lane0_rsp_error_o;
  wire lane0_rsp_page_fault_o;
  wire lane0_rsp_attr_valid_o;
  wire [1:0] lane0_rsp_class_o;
  wire lane0_rsp_cacheable_o;
  wire [1:0] lane0_rsp_owner_kind_o;
  wire [4:0] lane0_rsp_owner_token_o;
  wire [1:0] lane0_rsp_mmu_epoch_o;
  wire [`XLEN-1:0] lane0_rsp_fault_tval_o;
  wire lane0_drop0_valid_o;
  wire [1:0] lane0_drop0_owner_kind_o;
  wire [4:0] lane0_drop0_owner_token_o;
  wire [1:0] lane0_drop0_mmu_epoch_o;
  wire [`XLEN-1:0] lane0_drop0_fault_tval_o;
  wire lane0_drop1_valid_o;
  wire [1:0] lane0_drop1_owner_kind_o;
  wire [4:0] lane0_drop1_owner_token_o;
  wire [1:0] lane0_drop1_mmu_epoch_o;
  wire [`XLEN-1:0] lane0_drop1_fault_tval_o;
  wire lane0_owner_query_valid_o;
  wire [4:0] lane0_owner_query_token_o;
  wire lane0_station_query_valid_o;
  wire [4:0] lane0_station_query_token_o;
  wire lane0_sq_query_valid_o;
  wire [1:0] lane0_sq_query_owner_kind_o;
  wire [4:0] lane0_sq_query_owner_token_o;
  wire [1:0] lane0_sq_query_mmu_epoch_o;
  wire [`XLEN-1:0] lane0_sq_query_paddr_o;
  wire lane0_sq_query_attr_valid_o;
  wire [1:0] lane0_sq_query_class_o;
  wire [`STRB_W-1:0] lane0_sq_query_wstrb_o;
  wire lane0_sq_query_allow_i = lane0_sq_query_valid_o;
  wire lane0_sq_query_forward_i = 1'b0;
  wire lane0_sq_query_replay_i = 1'b0;
  wire lane0_sq_query_retry_ready_i = 1'b0;
  wire [`XLEN-1:0] lane0_sq_query_forward_data_i = {`XLEN{1'b0}};
  wire [31:0] lane0_owner_residency_mask_o;
  wire lane0_idle_o;
  wire lane0_translate_active_o;

  reg lane1_req_valid_i;
  wire lane1_req_ready_o;
  reg lane1_req_write_i;
  reg lane1_req_probe_i;
  reg lane1_req_pretrans_i;
  reg lane1_req_nokill_i;
  reg lane1_req_attr_valid_i;
  reg [1:0] lane1_req_class_i;
  reg lane1_req_cacheable_i;
  wire [1:0] lane1_req_owner_kind_i =
      lane1_req_write_i ? 2'b01 : 2'b00;
  reg [4:0] lane1_req_owner_token_i;
  wire [1:0] lane1_req_mmu_epoch_i = 2'b01;
  wire [`XLEN-1:0] lane1_req_fault_tval_i = lane1_req_addr_i;
  reg lane1_expected_effective_killed_i;
  reg lane1_device_release_i;
  reg lane1_device_cancel_i;
  reg [`XLEN-1:0] lane1_req_addr_i;
  reg [`XLEN-1:0] lane1_req_wdata_i;
  reg [`STRB_W-1:0] lane1_req_wstrb_i;
  wire lane1_rsp_valid_o;
  reg lane1_rsp_ready_i;
  wire [`XLEN-1:0] lane1_rsp_rdata_o;
  wire lane1_rsp_error_o;
  wire lane1_rsp_page_fault_o;
  wire lane1_rsp_attr_valid_o;
  wire [1:0] lane1_rsp_class_o;
  wire lane1_rsp_cacheable_o;
  wire [1:0] lane1_rsp_owner_kind_o;
  wire [4:0] lane1_rsp_owner_token_o;
  wire [1:0] lane1_rsp_mmu_epoch_o;
  wire [`XLEN-1:0] lane1_rsp_fault_tval_o;
  wire lane1_drop0_valid_o;
  wire [1:0] lane1_drop0_owner_kind_o;
  wire [4:0] lane1_drop0_owner_token_o;
  wire [1:0] lane1_drop0_mmu_epoch_o;
  wire [`XLEN-1:0] lane1_drop0_fault_tval_o;
  wire lane1_drop1_valid_o;
  wire [1:0] lane1_drop1_owner_kind_o;
  wire [4:0] lane1_drop1_owner_token_o;
  wire [1:0] lane1_drop1_mmu_epoch_o;
  wire [`XLEN-1:0] lane1_drop1_fault_tval_o;
  wire lane1_owner_query_valid_o;
  wire [4:0] lane1_owner_query_token_o;
  wire lane1_station_query_valid_o;
  wire [4:0] lane1_station_query_token_o;
  wire lane1_sq_query_valid_o;
  wire [1:0] lane1_sq_query_owner_kind_o;
  wire [4:0] lane1_sq_query_owner_token_o;
  wire [1:0] lane1_sq_query_mmu_epoch_o;
  wire [`XLEN-1:0] lane1_sq_query_paddr_o;
  wire lane1_sq_query_attr_valid_o;
  wire [1:0] lane1_sq_query_class_o;
  wire [`STRB_W-1:0] lane1_sq_query_wstrb_o;
  wire lane1_sq_query_allow_i = lane1_sq_query_valid_o;
  wire lane1_sq_query_forward_i = 1'b0;
  wire lane1_sq_query_replay_i = 1'b0;
  wire lane1_sq_query_retry_ready_i = 1'b0;
  wire [`XLEN-1:0] lane1_sq_query_forward_data_i = {`XLEN{1'b0}};
  wire [31:0] lane1_owner_residency_mask_o;
  wire lane1_idle_o;
  wire lane1_translate_active_o;

  wire d_axi_arvalid_o;
  reg d_axi_arready_i;
  wire [`XLEN-1:0] d_axi_araddr_o;
  wire [3:0] d_axi_arid_o;
  wire [7:0] d_axi_arlen_o;
  wire [2:0] d_axi_arsize_o;
  wire [1:0] d_axi_arburst_o;
  wire [2:0] d_axi_arprot_o;
  reg d_axi_rvalid_i;
  wire d_axi_rready_o;
  reg [`XLEN-1:0] d_axi_rdata_i;
  reg [1:0] d_axi_rresp_i;
  wire d_axi_awvalid_o;
  reg d_axi_awready_i;
  wire [`XLEN-1:0] d_axi_awaddr_o;
  wire [3:0] d_axi_awid_o;
  wire [7:0] d_axi_awlen_o;
  wire [2:0] d_axi_awsize_o;
  wire [1:0] d_axi_awburst_o;
  wire d_axi_wvalid_o;
  reg d_axi_wready_i;
  wire [`XLEN-1:0] d_axi_wdata_o;
  wire [`STRB_W-1:0] d_axi_wstrb_o;
  wire d_axi_wlast_o;
  reg d_axi_bvalid_i;
  wire d_axi_bready_o;
  reg [1:0] d_axi_bresp_i;

  reg [1:0] lane0_kind_model [0:31];
  reg [1:0] lane0_epoch_model [0:31];
  reg [`XLEN-1:0] lane0_tval_model [0:31];
  reg [1:0] lane1_kind_model [0:31];
  reg [1:0] lane1_epoch_model [0:31];
  reg [`XLEN-1:0] lane1_tval_model [0:31];
  integer owner_i;

  wire lane0_expected_valid_i = lane0_owner_query_valid_o;
  wire [1:0] lane0_expected_owner_kind_i =
      lane0_kind_model[lane0_owner_query_token_o];
  wire [4:0] lane0_expected_owner_token_i = lane0_owner_query_token_o;
  wire [1:0] lane0_expected_mmu_epoch_i =
      lane0_epoch_model[lane0_owner_query_token_o];
  wire lane0_expected_tval_valid_i = lane0_owner_query_valid_o;
  wire [`XLEN-1:0] lane0_expected_fault_tval_i =
      lane0_tval_model[lane0_owner_query_token_o];
  wire lane0_tracker_expected_valid_i = lane0_owner_query_valid_o;
  wire [1:0] lane0_tracker_expected_owner_kind_i =
      lane0_kind_model[lane0_owner_query_token_o];
  wire [4:0] lane0_tracker_expected_owner_token_i =
      lane0_owner_query_token_o;
  wire [1:0] lane0_tracker_expected_mmu_epoch_i =
      lane0_epoch_model[lane0_owner_query_token_o];
  wire lane0_station_expected_valid_i = lane0_station_query_valid_o;
  wire [1:0] lane0_station_expected_owner_kind_i =
      lane0_kind_model[lane0_station_query_token_o];
  wire [4:0] lane0_station_expected_owner_token_i =
      lane0_station_query_token_o;
  wire [1:0] lane0_station_expected_mmu_epoch_i =
      lane0_epoch_model[lane0_station_query_token_o];

  wire lane1_expected_valid_i = lane1_owner_query_valid_o;
  wire [1:0] lane1_expected_owner_kind_i =
      lane1_kind_model[lane1_owner_query_token_o];
  wire [4:0] lane1_expected_owner_token_i = lane1_owner_query_token_o;
  wire [1:0] lane1_expected_mmu_epoch_i =
      lane1_epoch_model[lane1_owner_query_token_o];
  wire lane1_expected_tval_valid_i = lane1_owner_query_valid_o;
  wire [`XLEN-1:0] lane1_expected_fault_tval_i =
      lane1_tval_model[lane1_owner_query_token_o];
  wire lane1_tracker_expected_valid_i = lane1_owner_query_valid_o;
  wire [1:0] lane1_tracker_expected_owner_kind_i =
      lane1_kind_model[lane1_owner_query_token_o];
  wire [4:0] lane1_tracker_expected_owner_token_i =
      lane1_owner_query_token_o;
  wire [1:0] lane1_tracker_expected_mmu_epoch_i =
      lane1_epoch_model[lane1_owner_query_token_o];
  wire lane1_station_expected_valid_i = lane1_station_query_valid_o;
  wire [1:0] lane1_station_expected_owner_kind_i =
      lane1_kind_model[lane1_station_query_token_o];
  wire [4:0] lane1_station_expected_owner_token_i =
      lane1_station_query_token_o;
  wire [1:0] lane1_station_expected_mmu_epoch_i =
      lane1_epoch_model[lane1_station_query_token_o];

  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR =
      {`PMP_ADDR_BUS_W{1'b1}};
  localparam [`XLEN-1:0] A0 = `NPC_AXI_PMEM_BASE + 64'h0000_2000;
  localparam [`XLEN-1:0] A1 = `NPC_AXI_PMEM_BASE + 64'h0000_3000;
  localparam [`XLEN-1:0] A2 = `NPC_AXI_PMEM_BASE + 64'h0000_4000;
  localparam [`XLEN-1:0] A3 = `NPC_AXI_PMEM_BASE + 64'h0000_5000;
  localparam [`XLEN-1:0] ROOT_PT =
      `NPC_AXI_PMEM_BASE + 64'h0000_6000;
  localparam [`XLEN-1:0] PAGED_VA =
      `NPC_AXI_PMEM_BASE + 64'h0000_7000;
  localparam [`XLEN-1:0] ROOT_PPN = ROOT_PT >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PPN =
      `NPC_AXI_PMEM_BASE >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | 64'h0cf;

  integer downstream_ar_fire_count;
  integer mutation_case;

  OooDualMemBridgeWrapper dut (.*);

  always @(posedge clk) begin
    if (rst) begin
      lane0_req_owner_token_i <= 5'd0;
      lane1_req_owner_token_i <= 5'd16;
      downstream_ar_fire_count <= 0;
      for (owner_i = 0; owner_i < 32; owner_i = owner_i + 1) begin
        lane0_kind_model[owner_i] <= 2'b00;
        lane0_epoch_model[owner_i] <= 2'b01;
        lane0_tval_model[owner_i] <= {`XLEN{1'b0}};
        lane1_kind_model[owner_i] <= 2'b00;
        lane1_epoch_model[owner_i] <= 2'b01;
        lane1_tval_model[owner_i] <= {`XLEN{1'b0}};
      end
    end else begin
      if (lane0_req_valid_i && lane0_req_ready_o) begin
        lane0_kind_model[lane0_req_owner_token_i] <=
            lane0_req_owner_kind_i;
        lane0_epoch_model[lane0_req_owner_token_i] <=
            lane0_req_mmu_epoch_i;
        lane0_tval_model[lane0_req_owner_token_i] <=
            lane0_req_fault_tval_i;
        lane0_req_owner_token_i <= lane0_req_owner_token_i + 5'd1;
      end
      if (lane1_req_valid_i && lane1_req_ready_o) begin
        lane1_kind_model[lane1_req_owner_token_i] <=
            lane1_req_owner_kind_i;
        lane1_epoch_model[lane1_req_owner_token_i] <=
            lane1_req_mmu_epoch_i;
        lane1_tval_model[lane1_req_owner_token_i] <=
            lane1_req_fault_tval_i;
        lane1_req_owner_token_i <= lane1_req_owner_token_i + 5'd1;
      end
      if (d_axi_arvalid_o && d_axi_arready_i)
        downstream_ar_fire_count <= downstream_ar_fire_count + 1;
    end
  end

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic tb_check5;
    input [1023:0] what;
    input [4:0] got;
    input [4:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%0d expected=%0d", what, got, exp);
      end
    end
  endtask

  task automatic mutation_reject;
    input [1023:0] reason;
    begin
      case (mutation_case)
        1: $display("[V8R-MUT-DISCONNECT-PEER-VALID] %0s", reason);
        2: $display("[V8R-MUT-SELF-ONLY-PEER] %0s", reason);
        3: $display("[V8R-MUT-SWAP-PEER-ADDR] %0s", reason);
        4: $display("[V8R-MUT-REQUEST-TIME-MAINTENANCE] %0s", reason);
        5: $display("[V8R-MUT-B-OK-ONLY-PEER] %0s", reason);
        6: $display("[V8R-MUT-DROP-CROSS-LINE-PEER] %0s", reason);
        7: $display("[V8R-MUT-REMOVE-SAME-CYCLE-HIT-BLOCK] %0s", reason);
        9: $display("[V8R-MUT-GATE-LANE1-READY] %0s", reason);
        10: $display("[V8R-MUT-MERGE-DUAL-RESPONSE] %0s", reason);
        default: $display("[V8R-MUT-UNEXPECTED-CASE] %0s", reason);
      endcase
      $fatal;
    end
  endtask

  task automatic clear_inputs;
    begin
      flush_i = 1'b0;
      control_full_flush_barrier_i = 1'b0;
      mmu_flush_i = 1'b0;
      dcache_dma_invalidate_all_i = 1'b0;
      ifu_ad_update_invalidate_all_i = 1'b0;
      priv_mode_i = `PRIV_M;
      mstatus_i = {`XLEN{1'b0}};
      satp_i = {`XLEN{1'b0}};
      svpbmt_en_i = 1'b0;
      pmpcfg_i = PMP_ALLOW_ALL_CFG;
      pmpaddr_i = PMP_ALLOW_ALL_ADDR;

      lane0_req_valid_i = 1'b0;
      lane0_req_write_i = 1'b0;
      lane0_req_probe_i = 1'b0;
      lane0_req_pretrans_i = 1'b0;
      lane0_req_nokill_i = 1'b0;
      lane0_req_attr_valid_i = 1'b0;
      lane0_req_class_i = `OOO_MEM_CLASS_RSVD;
      lane0_req_cacheable_i = 1'b0;
      lane0_expected_effective_killed_i = 1'b0;
      lane0_device_release_i = 1'b0;
      lane0_device_cancel_i = 1'b0;
      lane0_req_addr_i = A0;
      lane0_req_wdata_i = {`XLEN{1'b0}};
      lane0_req_wstrb_i = 8'hff;
      lane0_rsp_ready_i = 1'b0;

      lane1_req_valid_i = 1'b0;
      lane1_req_write_i = 1'b0;
      lane1_req_probe_i = 1'b0;
      lane1_req_pretrans_i = 1'b0;
      lane1_req_nokill_i = 1'b0;
      lane1_req_attr_valid_i = 1'b0;
      lane1_req_class_i = `OOO_MEM_CLASS_RSVD;
      lane1_req_cacheable_i = 1'b0;
      lane1_expected_effective_killed_i = 1'b0;
      lane1_device_release_i = 1'b0;
      lane1_device_cancel_i = 1'b0;
      lane1_req_addr_i = A1;
      lane1_req_wdata_i = {`XLEN{1'b0}};
      lane1_req_wstrb_i = 8'hff;
      lane1_rsp_ready_i = 1'b0;

      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b0;
      d_axi_rdata_i = {`XLEN{1'b0}};
      d_axi_rresp_i = 2'b00;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      d_axi_bvalid_i = 1'b0;
      d_axi_bresp_i = 2'b00;
    end
  endtask

  task automatic issue_load;
    input integer lane;
    input [`XLEN-1:0] addr;
    output [4:0] token;
    integer timeout;
    begin
      timeout = 0;
      if (lane == 0) begin
        lane0_req_write_i = 1'b0;
        lane0_req_pretrans_i = 1'b0;
        lane0_req_nokill_i = 1'b0;
        lane0_req_attr_valid_i = 1'b0;
        lane0_req_class_i = `OOO_MEM_CLASS_RSVD;
        lane0_req_cacheable_i = 1'b0;
        lane0_req_addr_i = addr;
        lane0_req_wdata_i = {`XLEN{1'b0}};
        lane0_req_wstrb_i = 8'hff;
        lane0_req_valid_i = 1'b1;
        #1;
        while (!lane0_req_ready_o && timeout < 80) begin
          tick();
          timeout = timeout + 1;
        end
        token = lane0_req_owner_token_i;
        tb_check1("lane0 request became ready", lane0_req_ready_o, 1'b1);
        tick();
        lane0_req_valid_i = 1'b0;
      end else begin
        lane1_req_write_i = 1'b0;
        lane1_req_pretrans_i = 1'b0;
        lane1_req_nokill_i = 1'b0;
        lane1_req_attr_valid_i = 1'b0;
        lane1_req_class_i = `OOO_MEM_CLASS_RSVD;
        lane1_req_cacheable_i = 1'b0;
        lane1_req_addr_i = addr;
        lane1_req_wdata_i = {`XLEN{1'b0}};
        lane1_req_wstrb_i = 8'hff;
        lane1_req_valid_i = 1'b1;
        #1;
        while (!lane1_req_ready_o && timeout < 80) begin
          tick();
          timeout = timeout + 1;
        end
        token = lane1_req_owner_token_i;
        tb_check1("lane1 request became ready", lane1_req_ready_o, 1'b1);
        tick();
        lane1_req_valid_i = 1'b0;
      end
      #1;
    end
  endtask

  task automatic issue_store;
    input integer lane;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    input [`STRB_W-1:0] strb;
    input [1:0] mem_class;
    output [4:0] token;
    integer timeout;
    begin
      timeout = 0;
      if (lane == 0) begin
        lane0_req_write_i = 1'b1;
        lane0_req_pretrans_i = 1'b1;
        lane0_req_nokill_i = 1'b1;
        lane0_req_attr_valid_i = 1'b1;
        lane0_req_class_i = mem_class;
        lane0_req_cacheable_i = (mem_class == `OOO_MEM_CLASS_CACHED);
        lane0_req_addr_i = addr;
        lane0_req_wdata_i = data;
        lane0_req_wstrb_i = strb;
        lane0_req_valid_i = 1'b1;
        #1;
        while (!lane0_req_ready_o && timeout < 80) begin
          tick();
          timeout = timeout + 1;
        end
        token = lane0_req_owner_token_i;
        tb_check1("lane0 store became ready", lane0_req_ready_o, 1'b1);
        tick();
        lane0_req_valid_i = 1'b0;
      end else begin
        lane1_req_write_i = 1'b1;
        lane1_req_pretrans_i = 1'b1;
        lane1_req_nokill_i = 1'b1;
        lane1_req_attr_valid_i = 1'b1;
        lane1_req_class_i = mem_class;
        lane1_req_cacheable_i = (mem_class == `OOO_MEM_CLASS_CACHED);
        lane1_req_addr_i = addr;
        lane1_req_wdata_i = data;
        lane1_req_wstrb_i = strb;
        lane1_req_valid_i = 1'b1;
        #1;
        while (!lane1_req_ready_o && timeout < 80) begin
          tick();
          timeout = timeout + 1;
        end
        token = lane1_req_owner_token_i;
        tb_check1("lane1 store became ready", lane1_req_ready_o, 1'b1);
        tick();
        lane1_req_valid_i = 1'b0;
      end
      #1;
    end
  endtask

  task automatic issue_dual_load;
    input [`XLEN-1:0] addr0;
    input [`XLEN-1:0] addr1;
    output [4:0] token0;
    output [4:0] token1;
    integer timeout;
    begin
      lane0_req_write_i = 1'b0;
      lane0_req_pretrans_i = 1'b0;
      lane0_req_nokill_i = 1'b0;
      lane0_req_attr_valid_i = 1'b0;
      lane0_req_class_i = `OOO_MEM_CLASS_RSVD;
      lane0_req_cacheable_i = 1'b0;
      lane0_req_addr_i = addr0;
      lane0_req_wstrb_i = 8'hff;
      lane1_req_write_i = 1'b0;
      lane1_req_pretrans_i = 1'b0;
      lane1_req_nokill_i = 1'b0;
      lane1_req_attr_valid_i = 1'b0;
      lane1_req_class_i = `OOO_MEM_CLASS_RSVD;
      lane1_req_cacheable_i = 1'b0;
      lane1_req_addr_i = addr1;
      lane1_req_wstrb_i = 8'hff;
      lane0_req_valid_i = 1'b1;
      lane1_req_valid_i = 1'b1;
      timeout = 0;
      #1;
      while ((!lane0_req_ready_o || !lane1_req_ready_o) && timeout < 80) begin
        tick();
        timeout = timeout + 1;
      end
      token0 = lane0_req_owner_token_i;
      token1 = lane1_req_owner_token_i;
      tb_check1("dual load lane0 ready", lane0_req_ready_o, 1'b1);
      tb_check1("dual load lane1 ready", lane1_req_ready_o, 1'b1);
      tick();
      lane0_req_valid_i = 1'b0;
      lane1_req_valid_i = 1'b0;
      #1;
    end
  endtask

  task automatic accept_read_address;
    input [`XLEN-1:0] expected_addr;
    integer timeout;
    begin
      timeout = 0;
      while (!d_axi_arvalid_o && timeout < 120) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("downstream AR became valid", d_axi_arvalid_o, 1'b1);
      tb_check64("downstream AR address", d_axi_araddr_o, expected_addr);
      d_axi_arready_i = 1'b1;
      tick();
      d_axi_arready_i = 1'b0;
      #1;
    end
  endtask

  task automatic send_read_data;
    input [`XLEN-1:0] data;
    input [1:0] resp;
    integer timeout;
    begin
      d_axi_rdata_i = data;
      d_axi_rresp_i = resp;
      d_axi_rvalid_i = 1'b1;
      timeout = 0;
      #1;
      while (!d_axi_rready_o && timeout < 80) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("downstream R became ready", d_axi_rready_o, 1'b1);
      tick();
      d_axi_rvalid_i = 1'b0;
      #1;
    end
  endtask

  task automatic service_read;
    input [`XLEN-1:0] expected_addr;
    input [`XLEN-1:0] data;
    begin
      accept_read_address(expected_addr);
      send_read_data(data, 2'b00);
    end
  endtask

  task automatic v9o_dual_registered_ar_barrier;
    reg [4:0] token0;
    reg [4:0] token1;
    reg selected_owner;
    reg [`XLEN-1:0] lane0_addr_hold;
    reg [`XLEN-1:0] lane1_addr_hold;
    reg [19:0] lane0_ctrl_hold;
    reg [19:0] lane1_ctrl_hold;
    reg [`XLEN-1:0] selected_addr;
    reg [`XLEN-1:0] pending_addr;
    reg [`XLEN-1:0] lane0_data;
    reg [`XLEN-1:0] lane1_data;
    integer ar_before;
    integer hold_cycle;
    integer timeout;
    begin
      // Establish two independent registered bridge owners before presenting
      // the C0 control-event barrier.  The barrier may block new pre-owner
      // launches, but it must not withdraw either already-presented AXI VALID.
      pulse_dma_invalidate();
      ar_before = downstream_ar_fire_count;
      lane0_data = 64'h0a0b_0c0d_0e0f_1011;
      lane1_data = 64'h1a1b_1c1d_1e1f_2021;
      issue_dual_load(A2, A3, token0, token1);

      timeout = 0;
      while (!(dut.u_bridge0.state_q == 4'd3 &&
               dut.u_bridge1.state_q == 4'd3 &&
               dut.lane0_axi_arvalid_w &&
               dut.lane1_axi_arvalid_w &&
               d_axi_arvalid_o) &&
             timeout < 120) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("V9O lane0 reached registered AR owner",
                dut.u_bridge0.state_q == 4'd3, 1'b1);
      tb_check1("V9O lane1 reached registered AR owner",
                dut.u_bridge1.state_q == 4'd3, 1'b1);
      tb_check1("V9O lane0 registered AR valid",
                dut.lane0_axi_arvalid_w, 1'b1);
      tb_check1("V9O lane1 registered AR valid",
                dut.lane1_axi_arvalid_w, 1'b1);
      tb_check1("V9O selected downstream AR valid", d_axi_arvalid_o, 1'b1);

      selected_owner = dut.u_miss_arbiter.owner_q;
      lane0_addr_hold = dut.lane0_axi_araddr_w;
      lane1_addr_hold = dut.lane1_axi_araddr_w;
      lane0_ctrl_hold = {dut.lane0_axi_arid_w,
                         dut.lane0_axi_arlen_w,
                         dut.lane0_axi_arsize_w,
                         dut.lane0_axi_arburst_w,
                         dut.lane0_axi_arprot_w};
      lane1_ctrl_hold = {dut.lane1_axi_arid_w,
                         dut.lane1_axi_arlen_w,
                         dut.lane1_axi_arsize_w,
                         dut.lane1_axi_arburst_w,
                         dut.lane1_axi_arprot_w};
      selected_addr = selected_owner ? lane1_addr_hold : lane0_addr_hold;
      pending_addr = selected_owner ? lane0_addr_hold : lane1_addr_hold;
      tb_check64("V9O lane0 registered AR address", lane0_addr_hold, A2);
      tb_check64("V9O lane1 registered AR address", lane1_addr_hold, A3);
      tb_check64("V9O selected downstream AR address",
                 d_axi_araddr_o, selected_addr);

      control_full_flush_barrier_i = 1'b1;
      for (hold_cycle = 0; hold_cycle < 4;
           hold_cycle = hold_cycle + 1) begin
        #1;
        tb_check1("V9O lane0 AR VALID held across C0 barrier",
                  dut.lane0_axi_arvalid_w, 1'b1);
        tb_check1("V9O lane1 AR VALID held across C0 barrier",
                  dut.lane1_axi_arvalid_w, 1'b1);
        tb_check64("V9O lane0 AR address held across C0 barrier",
                   dut.lane0_axi_araddr_w, lane0_addr_hold);
        tb_check64("V9O lane1 AR address held across C0 barrier",
                   dut.lane1_axi_araddr_w, lane1_addr_hold);
        tb_check1("V9O lane0 AR controls held across C0 barrier",
                  {dut.lane0_axi_arid_w,
                   dut.lane0_axi_arlen_w,
                   dut.lane0_axi_arsize_w,
                   dut.lane0_axi_arburst_w,
                   dut.lane0_axi_arprot_w} === lane0_ctrl_hold, 1'b1);
        tb_check1("V9O lane1 AR controls held across C0 barrier",
                  {dut.lane1_axi_arid_w,
                   dut.lane1_axi_arlen_w,
                   dut.lane1_axi_arsize_w,
                   dut.lane1_axi_arburst_w,
                   dut.lane1_axi_arprot_w} === lane1_ctrl_hold, 1'b1);
        tb_check1("V9O AXI arbiter owner held across C0 barrier",
                  dut.u_miss_arbiter.owner_q, selected_owner);
        tb_check1("V9O selected downstream AR VALID held",
                  d_axi_arvalid_o, 1'b1);
        tb_check64("V9O selected downstream AR payload held",
                   d_axi_araddr_o, selected_addr);
        tick();
      end

      // Drain both exact registered owners while the barrier remains asserted.
      // The shared arbiter may move to the second owner only after the first
      // R terminal; the pending lane's own VALID/payload must survive intact.
      accept_read_address(selected_addr);
      if (!selected_owner) begin
        tb_check1("V9O pending lane1 AR survives first address terminal",
                  dut.lane1_axi_arvalid_w, 1'b1);
        tb_check64("V9O pending lane1 AR address survives first terminal",
                   dut.lane1_axi_araddr_w, pending_addr);
        send_read_data(lane0_data, 2'b00);
      end else begin
        tb_check1("V9O pending lane0 AR survives first address terminal",
                  dut.lane0_axi_arvalid_w, 1'b1);
        tb_check64("V9O pending lane0 AR address survives first terminal",
                   dut.lane0_axi_araddr_w, pending_addr);
        send_read_data(lane1_data, 2'b00);
      end

      accept_read_address(pending_addr);
      if (!selected_owner)
        send_read_data(lane1_data, 2'b00);
      else
        send_read_data(lane0_data, 2'b00);

      if (downstream_ar_fire_count != ar_before + 2) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] V9O dual registered AR terminal count got=%0d expected=%0d",
                 downstream_ar_fire_count - ar_before, 2);
      end
      wait_lane_response(0, token0, lane0_data, 1'b0);
      wait_lane_response(1, token1, lane1_data, 1'b0);
      tb_check1("V9O lane0 exact response consumed once",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("V9O lane1 exact response consumed once",
                lane1_rsp_valid_o, 1'b0);
      control_full_flush_barrier_i = 1'b0;
      wait_both_idle();
      $display("[V9O-DUAL-REGISTERED-AR-BARRIER] lanes=2 hold_cycles=4 terminals=2 PASS");
    end
  endtask

  task automatic accept_write_channels;
    input [`XLEN-1:0] expected_addr;
    input [`XLEN-1:0] expected_data;
    input [`STRB_W-1:0] expected_strb;
    integer timeout;
    begin
      timeout = 0;
      while ((!d_axi_awvalid_o || !d_axi_wvalid_o) && timeout < 120) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("downstream AW became valid", d_axi_awvalid_o, 1'b1);
      tb_check1("downstream W became valid", d_axi_wvalid_o, 1'b1);
      tb_check64("downstream AW address", d_axi_awaddr_o, expected_addr);
      tb_check64("downstream W data", d_axi_wdata_o, expected_data);
      if (d_axi_wstrb_o !== expected_strb) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] downstream WSTRB got=%h expected=%h",
                 d_axi_wstrb_o, expected_strb);
      end
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      tick();
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      #1;
    end
  endtask

  task automatic send_write_response;
    input [1:0] resp;
    integer timeout;
    begin
      d_axi_bresp_i = resp;
      d_axi_bvalid_i = 1'b1;
      timeout = 0;
      #1;
      while (!d_axi_bready_o && timeout < 80) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("downstream B became ready", d_axi_bready_o, 1'b1);
      tick();
      d_axi_bvalid_i = 1'b0;
      #1;
    end
  endtask

  task automatic wait_lane_response;
    input integer lane;
    input [4:0] token;
    input [`XLEN-1:0] data;
    input error_expected;
    integer timeout;
    begin
      timeout = 0;
      if (lane == 0) begin
        while (!lane0_rsp_valid_o && timeout < 120) begin
          tick();
          timeout = timeout + 1;
        end
        tb_check1("lane0 response became valid", lane0_rsp_valid_o, 1'b1);
        tb_check5("lane0 response exact token", lane0_rsp_owner_token_o,
                  token);
        tb_check1("lane0 response error", lane0_rsp_error_o, error_expected);
        if (!error_expected)
          tb_check64("lane0 response data", lane0_rsp_rdata_o, data);
        lane0_rsp_ready_i = 1'b1;
        tick();
        lane0_rsp_ready_i = 1'b0;
      end else begin
        while (!lane1_rsp_valid_o && timeout < 120) begin
          tick();
          timeout = timeout + 1;
        end
        tb_check1("lane1 response became valid", lane1_rsp_valid_o, 1'b1);
        tb_check5("lane1 response exact token", lane1_rsp_owner_token_o,
                  token);
        tb_check1("lane1 response error", lane1_rsp_error_o, error_expected);
        if (!error_expected)
          tb_check64("lane1 response data", lane1_rsp_rdata_o, data);
        lane1_rsp_ready_i = 1'b1;
        tick();
        lane1_rsp_ready_i = 1'b0;
      end
      #1;
    end
  endtask

  task automatic warm_lane;
    input integer lane;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    reg [4:0] token;
    begin
      issue_load(lane, addr, token);
      service_read({addr[`XLEN-1:3], 3'b000}, data);
      wait_lane_response(lane, token, data, 1'b0);
    end
  endtask

  task automatic wait_both_idle;
    integer timeout;
    begin
      timeout = 0;
      while ((!lane0_idle_o || !lane1_idle_o) && timeout < 160) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("lane0 reached idle", lane0_idle_o, 1'b1);
      tb_check1("lane1 reached idle", lane1_idle_o, 1'b1);
    end
  endtask

  task automatic pulse_dma_invalidate;
    begin
      wait_both_idle();
      dcache_dma_invalidate_all_i = 1'b1;
      tick();
      dcache_dma_invalidate_all_i = 1'b0;
      #1;
    end
  endtask

  task automatic hot_load;
    input integer lane;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    reg [4:0] token;
    integer ar_before;
    begin
      ar_before = downstream_ar_fire_count;
      issue_load(lane, addr, token);
      wait_lane_response(lane, token, data, 1'b0);
      if (downstream_ar_fire_count != ar_before) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] hot lane%0d load escaped to downstream AR",
                 lane);
      end
    end
  endtask

  task automatic dual_hot_ready_matrix;
    integer combo;
    integer timeout;
    integer ar_before;
    reg [4:0] token0;
    reg [4:0] token1;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h0011_2233_4455_6677);
      warm_lane(1, A1, 64'h8899_aabb_ccdd_eeff);
      for (combo = 0; combo < 4; combo = combo + 1) begin
        wait_both_idle();
        ar_before = downstream_ar_fire_count;
        lane0_rsp_ready_i = combo[0];
        lane1_rsp_ready_i = combo[1];
        issue_dual_load(A0, A1, token0, token1);
        timeout = 0;
        #1;
        while ((!lane0_rsp_valid_o || !lane1_rsp_valid_o) &&
               timeout < 40) begin
          if (lane0_rsp_valid_o ^ lane1_rsp_valid_o) begin
            tb_errors = tb_errors + 1;
            $display("[CHECK-FAIL] dual hot response became one-sided combo=%0d",
                     combo);
          end
          tick();
          timeout = timeout + 1;
          #1;
        end
        tb_check1("dual hot lane0 response valid", lane0_rsp_valid_o, 1'b1);
        tb_check1("dual hot lane1 response valid", lane1_rsp_valid_o, 1'b1);
        tb_check5("dual hot lane0 exact token", lane0_rsp_owner_token_o,
                  token0);
        tb_check5("dual hot lane1 exact token", lane1_rsp_owner_token_o,
                  token1);
        tb_check64("dual hot lane0 data", lane0_rsp_rdata_o,
                   64'h0011_2233_4455_6677);
        tb_check64("dual hot lane1 data", lane1_rsp_rdata_o,
                   64'h8899_aabb_ccdd_eeff);
        tb_check64("dual hot lane0 tval", lane0_rsp_fault_tval_o, A0);
        tb_check64("dual hot lane1 tval", lane1_rsp_fault_tval_o, A1);
        if (downstream_ar_fire_count != ar_before) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] dual hot combo=%0d used downstream AR", combo);
        end
        // Consume lanes selected by this combination, then release any held
        // response with both READY high.  One lane's READY cannot affect the
        // other lane's response visibility or metadata.
        tick();
        lane0_rsp_ready_i = 1'b1;
        lane1_rsp_ready_i = 1'b1;
        #1;
        tick();
        lane0_rsp_ready_i = 1'b0;
        lane1_rsp_ready_i = 1'b0;
        #1;
      end
    end
  endtask

  task automatic hit_under_peer_miss;
    reg [4:0] cold_token;
    reg [4:0] hot_token;
    integer ar_before;
    begin
      pulse_dma_invalidate();
      warm_lane(1, A1, 64'h1111_2222_3333_4444);
      issue_load(0, A2, cold_token);
      accept_read_address(A2);
      ar_before = downstream_ar_fire_count;
      issue_load(1, A1, hot_token);
      wait_lane_response(1, hot_token, 64'h1111_2222_3333_4444, 1'b0);
      if (downstream_ar_fire_count != ar_before) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] lane1 hot hit depended on lane0 miss owner");
      end
      send_read_data(64'haaaa_bbbb_cccc_dddd, 2'b00);
      wait_lane_response(0, cold_token, 64'haaaa_bbbb_cccc_dddd, 1'b0);

      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h5555_6666_7777_8888);
      issue_load(1, A3, cold_token);
      accept_read_address(A3);
      ar_before = downstream_ar_fire_count;
      issue_load(0, A0, hot_token);
      wait_lane_response(0, hot_token, 64'h5555_6666_7777_8888, 1'b0);
      if (downstream_ar_fire_count != ar_before) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] lane0 hot hit depended on lane1 miss owner");
      end
      send_read_data(64'h9999_aaaa_bbbb_cccc, 2'b00);
      wait_lane_response(1, cold_token, 64'h9999_aaaa_bbbb_cccc, 1'b0);
    end
  endtask

  // V8W OOO-4 production-width integration: a branch recovery may retire one
  // exact lane owner while the peer lane continues normally.  The recovered
  // lane must produce its own precise terminal without borrowing the shared
  // AXI arbiter or suppressing the peer's final-PA SQ decision.
  task automatic selective_recovery_is_lane_local;
    reg [4:0] token0;
    reg [4:0] token1;
    localparam [`XLEN-1:0] LANE1_DATA = 64'h1357_9bdf_2468_ace0;
    begin
      pulse_dma_invalidate();
      issue_dual_load(A2, A3, token0, token1);
      tick();
      #1;
      tb_check1("V8W dual lane0 reaches SQ query",
                lane0_sq_query_valid_o, 1'b1);
      tb_check1("V8W dual lane1 reaches SQ query",
                lane1_sq_query_valid_o, 1'b1);

      lane0_expected_effective_killed_i = 1'b1;
      #1;
      tb_check1("V8W recovered lane0 query is masked",
                lane0_sq_query_valid_o, 1'b0);
      tb_check1("V8W recovered lane0 exact terminal",
                lane0_drop0_valid_o, 1'b1);
      tb_check5("V8W recovered lane0 terminal token",
                lane0_drop0_owner_token_o, token0);
      tb_check1("V8W peer lane1 query remains valid",
                lane1_sq_query_valid_o, 1'b1);
      tb_check5("V8W peer lane1 query token",
                lane1_sq_query_owner_token_o, token1);
      tb_check1("V8W final-PA query beat has no downstream AR",
                d_axi_arvalid_o, 1'b0);
      tick();
      lane0_expected_effective_killed_i = 1'b0;
      #1;
      tb_check1("V8W recovered lane0 reaches idle", lane0_idle_o, 1'b1);
      tb_check1("V8W recovered lane0 has no CPU response",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("V8W recovered lane0 terminal pulses once",
                lane0_drop0_valid_o, 1'b0);
      tb_check1("V8W peer lane1 local bridge presents its miss AR",
                dut.lane1_axi_arvalid_w, 1'b1);
      tb_check64("V8W peer lane1 local miss AR address",
                 dut.lane1_axi_araddr_w, A3);
      tb_check1("V8W shared arbiter keeps registered selection",
                d_axi_arvalid_o, 1'b0);
      tick();
      #1;
      tb_check1("V8W shared arbiter presents peer lane1 AR",
                d_axi_arvalid_o, 1'b1);
      tb_check64("V8W shared peer lane1 AR address", d_axi_araddr_o, A3);
      service_read(A3, LANE1_DATA);
      wait_lane_response(1, token1, LANE1_DATA, 1'b0);
      wait_both_idle();
      $display("[V8W-OOO4-DUAL-LANE-SELECTIVE-RECOVERY][PASS] recovered=%0d peer=%0d",
               token0, token1);
    end
  endtask

  // V8W OOO-4 lane-isolation drain coverage: lane0 already owns an accepted
  // downstream read when it is recovered.  While lane0 keeps the outstanding
  // R channel in sticky drain, lane1 must still complete an independent cache
  // hit and retain its exact response tuple.
  task automatic selective_recovery_drain_allows_peer_hit;
    localparam [`XLEN-1:0] PEER_DATA = 64'h0bad_f00d_cafe_5eed;
    reg [4:0] killed_token;
    reg [4:0] peer_token;
    integer ar_before_peer;
    begin
      pulse_dma_invalidate();
      warm_lane(1, A1, PEER_DATA);

      issue_load(0, A2, killed_token);
      accept_read_address(A2);
      tb_check1("V8W drain lane0 owns downstream R",
                d_axi_rready_o, 1'b1);
      lane0_expected_effective_killed_i = 1'b1;
      #1;
      tb_check1("V8W drain lane0 recognizes recovery",
                dut.u_bridge0.active_selective_recovery_w, 1'b1);
      tb_check1("V8W drain lane0 waits for exact R terminal",
                lane0_drop0_valid_o, 1'b0);
      tick();
      lane0_expected_effective_killed_i = 1'b0;
      #1;
      tb_check1("V8W drain lane0 keeps registered obligation",
                dut.u_bridge0.drop_rsp_q, 1'b1);
      tb_check1("V8W drain lane0 remains non-idle",
                lane0_idle_o, 1'b0);

      ar_before_peer = downstream_ar_fire_count;
      issue_load(1, A1, peer_token);
      wait_lane_response(1, peer_token, PEER_DATA, 1'b0);
      tb_check1("V8W drain lane0 still owns R after peer hit",
                d_axi_rready_o, 1'b1);
      tb_check1("V8W drain lane0 has no CPU response",
                lane0_rsp_valid_o, 1'b0);
      if (downstream_ar_fire_count != ar_before_peer) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] V8W peer hit used downstream AR during lane0 drain");
      end

      d_axi_rvalid_i = 1'b1;
      d_axi_rdata_i = 64'hdead_beef_0123_4567;
      d_axi_rresp_i = 2'b00;
      #1;
      tb_check1("V8W drain lane0 accepts late R", d_axi_rready_o, 1'b1);
      tb_check1("V8W drain lane0 emits exact terminal",
                lane0_drop0_valid_o, 1'b1);
      tb_check5("V8W drain lane0 terminal token",
                lane0_drop0_owner_token_o, killed_token);
      tb_check1("V8W drain lane0 late R has no CPU response",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("V8W drain peer emits no duplicate response",
                lane1_rsp_valid_o, 1'b0);
      tick();
      d_axi_rvalid_i = 1'b0;
      #1;
      tb_check1("V8W drain lane0 releases after late R",
                lane0_idle_o, 1'b1);
      tb_check1("V8W drain terminal pulses once",
                lane0_drop0_valid_o, 1'b0);
      wait_both_idle();
      $display("[V8W-OOO4-DUAL-LANE-DRAIN-PEER-HIT][PASS] recovered=%0d peer=%0d",
               killed_token, peer_token);
    end
  endtask

  task automatic peer_store_terminal_overlap;
    reg [4:0] store_token;
    reg [4:0] overlap_token;
    integer timeout;
    reg [`XLEN-1:0] held_awaddr;
    reg [`XLEN-1:0] held_wdata;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h0102_0304_0506_0708);
      warm_lane(1, A0, 64'h0102_0304_0506_0708);

      issue_store(0, A0, 64'h8877_6655_4433_2211, 8'hff,
                  `OOO_MEM_CLASS_CACHED, store_token);
      timeout = 0;
      while ((!d_axi_awvalid_o || !d_axi_wvalid_o) && timeout < 120) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("stalled store AW visible", d_axi_awvalid_o, 1'b1);
      tb_check1("stalled store W visible", d_axi_wvalid_o, 1'b1);
      held_awaddr = d_axi_awaddr_o;
      held_wdata = d_axi_wdata_o;

      // Request/AW/W presentation cannot invalidate the peer early.
      hot_load(1, A0, 64'h0102_0304_0506_0708);
      tb_check1("AW remains locked across peer hit", d_axi_awvalid_o, 1'b1);
      tb_check1("W remains locked across peer hit", d_axi_wvalid_o, 1'b1);
      tb_check64("AW payload remains stable", d_axi_awaddr_o, held_awaddr);
      tb_check64("W payload remains stable", d_axi_wdata_o, held_wdata);

      accept_write_channels(A0, 64'h8877_6655_4433_2211, 8'hff);

      // AW/W have fired but B is absent: peer cache must still be hot.
      hot_load(1, A0, 64'h0102_0304_0506_0708);

      // Align the next peer lookup decision exactly with producer B terminal.
      issue_load(1, A0, overlap_token);
      // F3 先在 S_SQ_QUERY 发射同步 SRAM lookup；再推进一拍后才是
      // S_LOOKUP 判决窗口。B terminal 必须与判决拍对齐，否则 valid
      // 清除会在下一沿兜底掩盖 same-cycle hit-block 缺失。
      tick();
      tick();
      d_axi_bresp_i = 2'b00;
      d_axi_bvalid_i = 1'b1;
      #1;
      tb_check1("store B terminal ready", d_axi_bready_o, 1'b1);
      tb_check1("authorized producer maintenance event",
                dut.lane0_peer_maintenance_valid_w, 1'b1);
      tb_check64("producer maintenance original byte PA",
                 dut.lane0_peer_maintenance_addr_w, A0);
      if (dut.lane0_peer_maintenance_wstrb_w !== 8'hff) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] producer maintenance WSTRB got=%h",
                 dut.lane0_peer_maintenance_wstrb_w);
      end
      tb_check1("peer exact decision blocks stale response",
                lane1_rsp_valid_o, 1'b0);
      tb_check1("peer exact D-cache hit is masked",
                dut.u_bridge1.dcache_lookup_hit_w, 1'b0);
      tick();
      d_axi_bvalid_i = 1'b0;
      #1;

      wait_lane_response(0, store_token, {`XLEN{1'b0}}, 1'b0);
      service_read(A0, 64'h8877_6655_4433_2211);
      wait_lane_response(1, overlap_token, 64'h8877_6655_4433_2211,
                         1'b0);

      // Producer keeps the exact all-OK CACHED store through its local RMW;
      // no downstream AR is allowed for this post-terminal load.
      wait_both_idle();
      hot_load(0, A0, 64'h8877_6655_4433_2211);
    end
  endtask

  task automatic peer_store_error_invalidate;
    reg [4:0] store_token;
    reg [4:0] load_token;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A1, 64'h1111_3333_5555_7777);
      warm_lane(1, A1, 64'h1111_3333_5555_7777);
      issue_store(0, A1, 64'haaaa_cccc_eeee_0000, 8'hff,
                  `OOO_MEM_CLASS_CACHED, store_token);
      accept_write_channels(A1, 64'haaaa_cccc_eeee_0000, 8'hff);
      send_write_response(2'b10);
      tb_check1("B error does not start local RMW",
                dut.u_bridge0.dcache_rmw_busy_w, 1'b0);
      wait_lane_response(0, store_token, {`XLEN{1'b0}}, 1'b1);

      // B error still conservatively invalidates both possible aliases.
      issue_load(0, A1, load_token);
      service_read(A1, 64'h1111_3333_5555_7777);
      wait_lane_response(0, load_token, 64'h1111_3333_5555_7777, 1'b0);
      issue_load(1, A1, load_token);
      service_read(A1, 64'h1111_3333_5555_7777);
      wait_lane_response(1, load_token, 64'h1111_3333_5555_7777, 1'b0);
    end
  endtask

  task automatic peer_cross_line_invalidate;
    reg [4:0] store_token;
    reg [4:0] load_token;
    integer ar_before;
    begin
      pulse_dma_invalidate();
      warm_lane(1, A2, 64'h0123_4567_89ab_cdef);
      warm_lane(1, A2 + 64'd8, 64'hfedc_ba98_7654_3210);
      issue_store(0, A2 + 64'd6, 64'h0000_0000_aabb_ccdd, 8'h0f,
                  `OOO_MEM_CLASS_CACHED, store_token);
      accept_write_channels(A2 + 64'd6, 64'h0000_0000_aabb_ccdd, 8'h0f);
      send_write_response(2'b00);
      wait_lane_response(0, store_token, {`XLEN{1'b0}}, 1'b0);
      wait_both_idle();

      ar_before = downstream_ar_fire_count;
      issue_load(1, A2, load_token);
      service_read(A2, 64'hccdd_4567_89ab_cdef);
      wait_lane_response(1, load_token, 64'hccdd_4567_89ab_cdef, 1'b0);
      issue_load(1, A2 + 64'd8, load_token);
      service_read(A2 + 64'd8, 64'hfedc_ba98_7654_aabb);
      wait_lane_response(1, load_token, 64'hfedc_ba98_7654_aabb, 1'b0);
      if (downstream_ar_fire_count != (ar_before + 2)) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] cross-line peer event did not force two misses");
      end
    end
  endtask

  task automatic dma_same_cycle_dual_lookup;
    reg [4:0] token0;
    reg [4:0] token1;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A3, 64'h1357_9bdf_2468_ace0);
      warm_lane(1, A3, 64'h1357_9bdf_2468_ace0);
      issue_dual_load(A3, A3, token0, token1);
      // Advance both stations and issue both local SRAM lookups.
      tick();
      dcache_dma_invalidate_all_i = 1'b1;
      #1;
      tb_check1("DMA masks lane0 lookup response immediately",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("DMA masks lane1 lookup response immediately",
                lane1_rsp_valid_o, 1'b0);
      tb_check1("DMA masks lane0 raw D-cache hit",
                dut.u_bridge0.dcache_lookup_hit_w, 1'b0);
      tb_check1("DMA masks lane1 raw D-cache hit",
                dut.u_bridge1.dcache_lookup_hit_w, 1'b0);
      tick();
      dcache_dma_invalidate_all_i = 1'b0;
      #1;

      // Both requests became real misses; the F0 owner serializes their two
      // identical ARs without merging either bridge response.
      service_read(A3, 64'h1357_9bdf_2468_ace0);
      service_read(A3, 64'h1357_9bdf_2468_ace0);
      wait_lane_response(0, token0, 64'h1357_9bdf_2468_ace0, 1'b0);
      wait_lane_response(1, token1, 64'h1357_9bdf_2468_ace0, 1'b0);
    end
  endtask

  task automatic ifu_ad_update_same_cycle_dual_lookup;
    reg [4:0] token0;
    reg [4:0] token1;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A3, 64'h2468_ace0_1357_9bdf);
      warm_lane(1, A3, 64'h2468_ace0_1357_9bdf);
      issue_dual_load(A3, A3, token0, token1);
      // Model the B-terminal pulse from OooFetchAxiBridge after it writes a
      // leaf PTE A bit.  Both D-cache replicas must reject their stale line.
      tick();
      ifu_ad_update_invalidate_all_i = 1'b1;
      #1;
      tb_check1("IFU A-update masks lane0 lookup response immediately",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("IFU A-update masks lane1 lookup response immediately",
                lane1_rsp_valid_o, 1'b0);
      tb_check1("IFU A-update masks lane0 raw D-cache hit",
                dut.u_bridge0.dcache_lookup_hit_w, 1'b0);
      tb_check1("IFU A-update masks lane1 raw D-cache hit",
                dut.u_bridge1.dcache_lookup_hit_w, 1'b0);
      tick();
      ifu_ad_update_invalidate_all_i = 1'b0;
      #1;

      service_read(A3, 64'h2468_ace0_1357_9bdf);
      service_read(A3, 64'h2468_ace0_1357_9bdf);
      wait_lane_response(0, token0, 64'h2468_ace0_1357_9bdf, 1'b0);
      wait_lane_response(1, token1, 64'h2468_ace0_1357_9bdf, 1'b0);
      $display("[V9P-IFU-AD-DCACHE-COHERENCE] ifu_pte_write_terminal=1 lane0_miss=1 lane1_miss=1");
    end
  endtask

  task automatic warm_paged_lane;
    input integer lane;
    reg [4:0] token;
    begin
      issue_load(lane, PAGED_VA, token);
      service_read(ROOT_PT + 64'd16, SUPERPAGE_PTE);
      service_read(PAGED_VA, 64'hdead_beef_0123_4567);
      wait_lane_response(lane, token, 64'hdead_beef_0123_4567, 1'b0);
    end
  endtask

  task automatic mmu_flush_dual_dtlb_rewalk;
    reg [4:0] token;
    integer ar_before;
    begin
      pulse_dma_invalidate();
      wait_both_idle();
      priv_mode_i = `PRIV_S;
      satp_i = (64'h8 << 60) | ROOT_PPN;
      warm_paged_lane(0);
      warm_paged_lane(1);
      wait_both_idle();

      mmu_flush_i = 1'b1;
      #1;
      tb_check1("legal mmu flush blocks lane0 READY",
                lane0_req_ready_o, 1'b0);
      tb_check1("legal mmu flush blocks lane1 READY",
                lane1_req_ready_o, 1'b0);
      tick();
      mmu_flush_i = 1'b0;
      #1;

      // Physical D-cache lines remain hot, but each private DTLB must issue a
      // fresh root-PTE read before it can consume that line again.
      ar_before = downstream_ar_fire_count;
      issue_load(0, PAGED_VA, token);
      service_read(ROOT_PT + 64'd16, SUPERPAGE_PTE);
      wait_lane_response(0, token, 64'hdead_beef_0123_4567, 1'b0);
      if (downstream_ar_fire_count != (ar_before + 1)) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] lane0 did not perform exactly one post-flush PTW AR");
      end
      ar_before = downstream_ar_fire_count;
      issue_load(1, PAGED_VA, token);
      service_read(ROOT_PT + 64'd16, SUPERPAGE_PTE);
      wait_lane_response(1, token, 64'hdead_beef_0123_4567, 1'b0);
      if (downstream_ar_fire_count != (ar_before + 1)) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] lane1 did not perform exactly one post-flush PTW AR");
      end
      wait_both_idle();
      priv_mode_i = `PRIV_M;
      satp_i = {`XLEN{1'b0}};
    end
  endtask

  task automatic sampled_reset_overlap;
    reg [4:0] token0;
    reg [4:0] token1;
    integer timeout;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h5555_aaaa_6666_bbbb);
      warm_lane(1, A1, 64'h7777_cccc_8888_dddd);
      issue_dual_load(A0, A1, token0, token1);
      timeout = 0;
      while ((!lane0_rsp_valid_o || !lane1_rsp_valid_o) && timeout < 40) begin
        tick();
        timeout = timeout + 1;
      end
      tb_check1("reset setup lane0 response held", lane0_rsp_valid_o, 1'b1);
      tb_check1("reset setup lane1 response held", lane1_rsp_valid_o, 1'b1);
      rst = 1'b1;
      dcache_dma_invalidate_all_i = 1'b1;
      tick();
      #1;
      tb_check1("sampled reset clears lane0 old response",
                lane0_rsp_valid_o, 1'b0);
      tb_check1("sampled reset clears lane1 old response",
                lane1_rsp_valid_o, 1'b0);
      tb_check1("sampled reset clears lane0 maintenance",
                dut.lane0_peer_maintenance_valid_w, 1'b0);
      tb_check1("sampled reset clears lane1 maintenance",
                dut.lane1_peer_maintenance_valid_w, 1'b0);
      tick();
      dcache_dma_invalidate_all_i = 1'b0;
      rst = 1'b0;
      tick();
      #1;
      tb_check1("reset release lane0 cold idle", lane0_idle_o, 1'b1);
      tb_check1("reset release lane1 cold idle", lane1_idle_o, 1'b1);
      tb_check1("reset release has no delayed lane0 maintenance",
                dut.lane0_peer_maintenance_valid_w, 1'b0);
      tb_check1("reset release has no delayed lane1 maintenance",
                dut.lane1_peer_maintenance_valid_w, 1'b0);
    end
  endtask

  task automatic mutation_peer_overlap_probe;
    input force_unrelated_self_addr;
    reg [4:0] store_token;
    reg [4:0] load_token;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h0102_0304_0506_0708);
      warm_lane(1, A0, 64'h0102_0304_0506_0708);
      issue_store(0, A0, 64'h8877_6655_4433_2211, 8'hff,
                  `OOO_MEM_CLASS_CACHED, store_token);
      accept_write_channels(A0, 64'h8877_6655_4433_2211, 8'hff);
      issue_load(1, A0, load_token);
      // 与 production overlap 场景相同：先让 S_SQ_QUERY 发射 lookup，
      // 再把 B terminal 放到 S_LOOKUP 的同步 SRAM 判决拍。
      tick();
      tick();
      // swap_peer_addr 若误接 consumer 自身 payload，普通 exact lookup 会
      // 因 paddr_q 也等于 A0 而偶然同值。仅在该 mutation 探针把未授权
      // self payload 固定为另一地址，建立可判定的非对称接线反例。
      if (force_unrelated_self_addr)
        force dut.lane1_peer_maintenance_addr_w = A1;
      d_axi_bresp_i = 2'b00;
      d_axi_bvalid_i = 1'b1;
      #1;
      if (lane1_rsp_valid_o || dut.u_bridge1.dcache_lookup_hit_w)
        mutation_reject("peer lookup exposed a stale hit on producer B terminal");
      tick();
      d_axi_bvalid_i = 1'b0;
      #1;
      if (lane1_rsp_valid_o || dut.u_bridge1.dcache_lookup_hit_w)
        mutation_reject("peer lookup exposed a stale hit on producer B terminal");
      if (force_unrelated_self_addr)
        release dut.lane1_peer_maintenance_addr_w;
    end
  endtask

  task automatic mutation_request_time_probe;
    reg [4:0] store_token;
    reg [4:0] load_token;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h1020_3040_5060_7080);
      warm_lane(1, A0, 64'h1020_3040_5060_7080);
      issue_store(0, A0, 64'h9080_7060_5040_3020, 8'hff,
                  `OOO_MEM_CLASS_CACHED, store_token);
      // No AW/W/B terminal exists yet.  A peer lookup must remain a real hit.
      issue_load(1, A0, load_token);
      tick();
      tick();
      #1;
      if (!lane1_rsp_valid_o || !dut.u_bridge1.dcache_lookup_hit_w)
        mutation_reject("request-time maintenance invalidated peer before B");
    end
  endtask

  task automatic mutation_b_error_probe;
    reg [4:0] store_token;
    reg [4:0] load_token;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A1, 64'h1111_3333_5555_7777);
      warm_lane(1, A1, 64'h1111_3333_5555_7777);
      issue_store(0, A1, 64'haaaa_cccc_eeee_0000, 8'hff,
                  `OOO_MEM_CLASS_CACHED, store_token);
      accept_write_channels(A1, 64'haaaa_cccc_eeee_0000, 8'hff);
      send_write_response(2'b10);
      issue_load(1, A1, load_token);
      tick();
      tick();
      #1;
      if (lane1_rsp_valid_o || dut.u_bridge1.dcache_lookup_hit_w)
        mutation_reject("B-error terminal failed to invalidate peer alias");
    end
  endtask

  task automatic mutation_cross_line_probe;
    reg [4:0] store_token;
    reg [4:0] load_token;
    begin
      pulse_dma_invalidate();
      warm_lane(1, A2, 64'h0123_4567_89ab_cdef);
      warm_lane(1, A2 + 64'd8, 64'hfedc_ba98_7654_3210);
      issue_store(0, A2 + 64'd6, 64'h0000_0000_aabb_ccdd, 8'h0f,
                  `OOO_MEM_CLASS_CACHED, store_token);
      accept_write_channels(A2 + 64'd6, 64'h0000_0000_aabb_ccdd, 8'h0f);
      send_write_response(2'b00);
      issue_load(1, A2 + 64'd8, load_token);
      tick();
      tick();
      #1;
      if (lane1_rsp_valid_o || dut.u_bridge1.dcache_lookup_hit_w)
        mutation_reject("cross-line peer maintenance left p1 visible");
    end
  endtask

  task automatic mutation_ready_bypass_probe;
    reg [4:0] cold_token;
    begin
      pulse_dma_invalidate();
      warm_lane(1, A1, 64'h1111_2222_3333_4444);
      issue_load(0, A2, cold_token);
      accept_read_address(A2);
      lane1_req_write_i = 1'b0;
      lane1_req_pretrans_i = 1'b0;
      lane1_req_nokill_i = 1'b0;
      lane1_req_attr_valid_i = 1'b0;
      lane1_req_class_i = `OOO_MEM_CLASS_RSVD;
      lane1_req_cacheable_i = 1'b0;
      lane1_req_addr_i = A1;
      lane1_req_wstrb_i = 8'hff;
      lane1_req_valid_i = 1'b1;
      #1;
      if (!lane1_req_ready_o)
        mutation_reject("lane1 hot admission was gated by F0 miss owner");
    end
  endtask

  task automatic mutation_dual_response_probe;
    reg [4:0] token0;
    reg [4:0] token1;
    begin
      pulse_dma_invalidate();
      warm_lane(0, A0, 64'h0011_2233_4455_6677);
      warm_lane(1, A1, 64'h8899_aabb_ccdd_eeff);
      issue_dual_load(A0, A1, token0, token1);
      tick();
      tick();
      #1;
      if (!lane0_rsp_valid_o || !lane1_rsp_valid_o)
        mutation_reject("simultaneous lane-local responses were merged");
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    mutation_case = 0;
    if (!$value$plusargs("MUTATION_CASE=%d", mutation_case))
      mutation_case = 0;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    tick();
    #1;
    tb_check1("cold reset lane0 idle", lane0_idle_o, 1'b1);
    tb_check1("cold reset lane1 idle", lane1_idle_o, 1'b1);

    if (mutation_case != 0) begin
      case (mutation_case)
        1: begin
          $display("[V8R-MUT-ACTIVE:disconnect_peer_valid]");
          mutation_peer_overlap_probe(1'b0);
        end
        2: begin
          $display("[V8R-MUT-ACTIVE:self_only_peer]");
          mutation_peer_overlap_probe(1'b0);
        end
        3: begin
          $display("[V8R-MUT-ACTIVE:swap_peer_addr]");
          mutation_peer_overlap_probe(1'b1);
        end
        4: begin
          $display("[V8R-MUT-ACTIVE:request_time_maintenance]");
          mutation_request_time_probe();
        end
        5: begin
          $display("[V8R-MUT-ACTIVE:b_ok_only_peer]");
          mutation_b_error_probe();
        end
        6: begin
          $display("[V8R-MUT-ACTIVE:drop_cross_line_peer]");
          mutation_cross_line_probe();
        end
        7: begin
          $display("[V8R-MUT-ACTIVE:remove_same_cycle_hit_block]");
          mutation_peer_overlap_probe(1'b0);
        end
        9: begin
          $display("[V8R-MUT-ACTIVE:gate_lane1_ready_on_arbiter_idle]");
          mutation_ready_bypass_probe();
        end
        10: begin
          $display("[V8R-MUT-ACTIVE:merge_dual_response]");
          mutation_dual_response_probe();
        end
        default: mutation_reject("unsupported wrapper mutation case");
      endcase
      $display("[V8R-MUT-NOT-REJECTED] case=%0d", mutation_case);
      $fatal;
    end else begin
      v9o_dual_registered_ar_barrier();
      selective_recovery_is_lane_local();
      selective_recovery_drain_allows_peer_hit();
      dual_hot_ready_matrix();
      hit_under_peer_miss();
      peer_store_terminal_overlap();
      peer_store_error_invalidate();
      peer_cross_line_invalidate();
      dma_same_cycle_dual_lookup();
      ifu_ad_update_same_cycle_dual_lookup();
      mmu_flush_dual_dtlb_rewalk();
      sampled_reset_overlap();

`ifdef OOO_DMBW_MMU_FLUSH_NONIDLE_NEGATIVE
      begin : mmu_flush_nonidle_negative
        reg [4:0] negative_token;
        issue_load(0, A0, negative_token);
        mmu_flush_i = 1'b1;
        tick();
        $display("[NEGATIVE-FAIL] non-idle mmu_flush was not rejected");
        $fatal;
      end
`else
      tb_finish("tb_ooo_dual_mem_bridge_wrapper");
`endif
    end
  end

  initial begin
    #200000;
    $display("[TIMEOUT] tb_ooo_dual_mem_bridge_wrapper");
    $fatal;
  end

endmodule
