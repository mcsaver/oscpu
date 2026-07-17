`include "define.v"

module tb_ooo_mem_axi_bridge #(
  parameter S2_G1_CASE = 0
);
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg mmu_flush;
  reg dcache_dma_invalidate_all;

  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr;

  reg mem0_req_valid;
  wire mem0_req_ready;
  reg mem0_req_write;
  reg mem0_req_probe;
  reg mem0_req_pretrans;
  reg mem0_req_nokill;
  reg mem0_req_attr_valid;
  reg [1:0] mem0_req_class;
  reg mem0_req_cacheable;
  reg s2_station_identity_mutate;
  reg s2_active_identity_mutate;
  reg s2_active_tracker_mutate;
  reg s2_active_tval_mutate;
  reg s2_expected_effective_killed;
  reg [4:0] mem0_req_owner_token;
  wire [1:0] mem0_req_owner_kind = mem0_req_write ? 2'b01 : 2'b00;
  wire [1:0] mem0_req_mmu_epoch = 2'b01;
  wire [`XLEN-1:0] mem0_req_fault_tval = mem0_req_addr;
  reg mem0_device_release;
  reg mem0_device_cancel;
  reg [`XLEN-1:0] mem0_req_addr;
  reg [`XLEN-1:0] mem0_req_wdata;
  reg [`STRB_W-1:0] mem0_req_wstrb;
  wire mem0_rsp_valid;
  reg mem0_rsp_ready;
  wire [`XLEN-1:0] mem0_rsp_rdata;
  wire mem0_rsp_error;
  wire mem0_rsp_page_fault;
  wire mem0_rsp_attr_valid;
  wire [1:0] mem0_rsp_class;
  wire mem0_rsp_cacheable;
  wire [1:0] mem0_rsp_owner_kind;
  wire [4:0] mem0_rsp_owner_token;
  wire [1:0] mem0_rsp_mmu_epoch;
  wire [`XLEN-1:0] mem0_rsp_fault_tval;
  wire mem0_drop0_valid;
  wire [1:0] mem0_drop0_owner_kind;
  wire [4:0] mem0_drop0_owner_token;
  wire [1:0] mem0_drop0_mmu_epoch;
  wire [`XLEN-1:0] mem0_drop0_fault_tval;
  wire mem0_drop1_valid;
  wire [1:0] mem0_drop1_owner_kind;
  wire [4:0] mem0_drop1_owner_token;
  wire [1:0] mem0_drop1_mmu_epoch;
  wire [`XLEN-1:0] mem0_drop1_fault_tval;
  wire mem0_owner_query_valid;
  wire [4:0] mem0_owner_query_token;
  wire mem0_station_query_valid;
  wire [4:0] mem0_station_query_token;
  wire [31:0] mem0_owner_residency_mask;
  reg [1:0] owner_kind_model [0:31];
  reg [1:0] owner_epoch_model [0:31];
  reg [`XLEN-1:0] owner_tval_model [0:31];
  integer owner_model_i;
  wire mem_translate_active;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  wire [2:0] lsu_axi_arsize;
  reg lsu_axi_rvalid;
  wire lsu_axi_rready;
  reg [`XLEN-1:0] lsu_axi_rdata;
  reg [1:0] lsu_axi_rresp;
  wire lsu_axi_awvalid;
  reg lsu_axi_awready;
  wire [`XLEN-1:0] lsu_axi_awaddr;
  wire lsu_axi_wvalid;
  reg lsu_axi_wready;
  wire [`XLEN-1:0] lsu_axi_wdata;
  wire [`STRB_W-1:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] DATA_VA = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] DATA_PA = 64'h0000_0000_8000_3000;
  // A/D 更新测试专用数据地址(同超页同 leaf PTE=ROOT_PT+16, 但不同 PA), 避免 store
  // 污染 DATA_PA 的物理 dcache(mmu_flush 不清物理索引 dcache)干扰后续 dtlb 测试。
  localparam [`XLEN-1:0] DATA_VA_AD = 64'h0000_0000_8000_a000;
  localparam [`XLEN-1:0] DATA_PA_AD = 64'h0000_0000_8000_a000;
  localparam [`XLEN-1:0] ROOT_PPN = ROOT_PT >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PPN =
      64'h0000_0000_8000_0000 >> 12;
  localparam [`XLEN-1:0] LEAF_FLAGS = 64'h0cf;
  localparam [`XLEN-1:0] LEAF_NO_ACCESS_FLAGS = 64'h08f;
  localparam [`XLEN-1:0] LEAF_NO_DIRTY_FLAGS = 64'h04f;
  localparam [`XLEN-1:0] SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | LEAF_FLAGS;
  // T4M counterexample: VA numerically belongs to the PMEM window, but a
  // level-2 Sv39 leaf maps it to the PLIC physical window.
  localparam [`XLEN-1:0] DEVICE_VA = 64'h0000_0000_8c00_0004;
  localparam [`XLEN-1:0] DEVICE_PA = 64'h0000_0000_0c00_0004;
  localparam [`XLEN-1:0] DEVICE_SUPERPAGE_PTE = LEAF_FLAGS;
  // T3W speculative-lookup owner tests: S-mode + SUM first fills this user
  // superpage DTLB entry, then SUM=0/mmu_flush create permission-fault and
  // context-miss cases while the translated physical line remains hot.
  localparam [`XLEN-1:0] SPEC_USER_VA = 64'h0000_0000_8000_b000;
  localparam [`XLEN-1:0] SPEC_USER_PA = 64'h0000_0000_8000_b000;
  localparam [`XLEN-1:0] SPEC_USER_DATA = 64'hd71b_5eed_f00d_cafe;
  localparam [`XLEN-1:0] SPEC_USER_SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | 64'h0df;
  localparam [`XLEN-1:0] PMA_BAD_VA = 64'h0000_0000_4000_3000;
  localparam [`XLEN-1:0] PMA_BAD_PA = 64'h0000_0000_4000_3000;
  localparam [`XLEN-1:0] PMA_BAD_SUPERPAGE_PTE =
      ((64'h0000_0000_4000_0000 >> 12) << 10) | LEAF_FLAGS;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR = {`PMP_ADDR_BUS_W{1'b1}};
  // Entry0 is an 8-byte NAPOT region allowing only the root leaf-PTE read.
  // All other S-mode addresses (including DATA_PA) have no match and deny.
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ROOT_PTE_READ_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h19};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ROOT_PTE_READ_ADDR =
      {{(`PMP_ADDR_BUS_W-`XLEN){1'b0}}, ((ROOT_PT + 64'd16) >> 2)};

  reg class_access_valid;
  reg class_pma_fault;
  reg class_addr_cacheable;
  reg class_pbmt_valid;
  reg [1:0] class_pbmt;
  wire class_pbmt_fault;
  wire class_cacheable;
  wire class_serialized;

  OooPostTranslateMemoryClass class_dut (
    .clk(clk),
    .rst(rst),
    .access_valid_i(class_access_valid),
    .pma_fault_i(class_pma_fault),
    .address_cacheable_i(class_addr_cacheable),
    .pbmt_valid_i(class_pbmt_valid),
    .pbmt_i(class_pbmt),
    .pbmt_fault_o(class_pbmt_fault),
    .cacheable_o(class_cacheable),
    .serialized_o(class_serialized)
  );

  OooMemAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .mmu_flush_i(mmu_flush),
    .dcache_dma_invalidate_all_i(dcache_dma_invalidate_all),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(pmpcfg),
    .pmpaddr_i(pmpaddr),
    .mem0_req_valid_i(mem0_req_valid),
    .mem0_req_ready_o(mem0_req_ready),
    .mem0_req_write_i(mem0_req_write),
    .mem0_req_probe_i(mem0_req_probe),
    .mem0_req_pretrans_i(mem0_req_pretrans),
    .mem0_req_nokill_i(mem0_req_nokill),
    .mem0_req_attr_valid_i(mem0_req_attr_valid),
    .mem0_req_class_i(mem0_req_class),
    .mem0_req_cacheable_i(mem0_req_cacheable),
    .mem0_req_owner_kind_i(mem0_req_owner_kind),
    .mem0_req_owner_token_i(mem0_req_owner_token),
    .mem0_req_mmu_epoch_i(mem0_req_mmu_epoch),
    .mem0_req_fault_tval_i(mem0_req_fault_tval),
    .mem0_expected_valid_i(mem0_owner_query_valid),
    .mem0_expected_owner_kind_i(owner_kind_model[mem0_owner_query_token]),
    .mem0_expected_owner_token_i(mem0_owner_query_token ^
        (s2_active_identity_mutate ? 5'b00001 : 5'b00000)),
    .mem0_expected_mmu_epoch_i(owner_epoch_model[mem0_owner_query_token]),
    .mem0_expected_tval_valid_i(mem0_owner_query_valid),
    .mem0_expected_fault_tval_i(owner_tval_model[mem0_owner_query_token] ^
        (s2_active_tval_mutate ? {{(`XLEN-1){1'b0}}, 1'b1} : {`XLEN{1'b0}})),
    .mem0_expected_effective_killed_i(s2_expected_effective_killed),
    .mem0_tracker_expected_valid_i(mem0_owner_query_valid),
    .mem0_tracker_expected_owner_kind_i(owner_kind_model[mem0_owner_query_token]),
    .mem0_tracker_expected_owner_token_i(mem0_owner_query_token ^
        (s2_active_tracker_mutate ? 5'b00001 : 5'b00000)),
    .mem0_tracker_expected_mmu_epoch_i(owner_epoch_model[mem0_owner_query_token]),
    .mem0_station_expected_valid_i(mem0_station_query_valid),
    .mem0_station_expected_owner_kind_i(owner_kind_model[mem0_station_query_token]),
    .mem0_station_expected_owner_token_i(mem0_station_query_token ^
        (s2_station_identity_mutate ? 5'b00001 : 5'b00000)),
    .mem0_station_expected_mmu_epoch_i(owner_epoch_model[mem0_station_query_token]),
    .mem0_device_release_i(mem0_device_release),
    .mem0_device_cancel_i(mem0_device_cancel),
    .mem0_req_addr_i(mem0_req_addr),
    .mem0_req_wdata_i(mem0_req_wdata),
    .mem0_req_wstrb_i(mem0_req_wstrb),
    .mem0_rsp_valid_o(mem0_rsp_valid),
    .mem0_rsp_ready_i(mem0_rsp_ready),
    .mem0_rsp_rdata_o(mem0_rsp_rdata),
    .mem0_rsp_error_o(mem0_rsp_error),
    .mem0_rsp_page_fault_o(mem0_rsp_page_fault),
    .mem0_rsp_attr_valid_o(mem0_rsp_attr_valid),
    .mem0_rsp_class_o(mem0_rsp_class),
    .mem0_rsp_cacheable_o(mem0_rsp_cacheable),
    .mem0_rsp_owner_kind_o(mem0_rsp_owner_kind),
    .mem0_rsp_owner_token_o(mem0_rsp_owner_token),
    .mem0_rsp_mmu_epoch_o(mem0_rsp_mmu_epoch),
    .mem0_rsp_fault_tval_o(mem0_rsp_fault_tval),
    .mem0_drop0_valid_o(mem0_drop0_valid),
    .mem0_drop0_owner_kind_o(mem0_drop0_owner_kind),
    .mem0_drop0_owner_token_o(mem0_drop0_owner_token),
    .mem0_drop0_mmu_epoch_o(mem0_drop0_mmu_epoch),
    .mem0_drop0_fault_tval_o(mem0_drop0_fault_tval),
    .mem0_drop1_valid_o(mem0_drop1_valid),
    .mem0_drop1_owner_kind_o(mem0_drop1_owner_kind),
    .mem0_drop1_owner_token_o(mem0_drop1_owner_token),
    .mem0_drop1_mmu_epoch_o(mem0_drop1_mmu_epoch),
    .mem0_drop1_fault_tval_o(mem0_drop1_fault_tval),
    .mem0_owner_query_valid_o(mem0_owner_query_valid),
    .mem0_owner_query_token_o(mem0_owner_query_token),
    .mem0_station_query_valid_o(mem0_station_query_valid),
    .mem0_station_query_token_o(mem0_station_query_token),
    .mem0_owner_residency_mask_o(mem0_owner_residency_mask),
    .translate_active_o(mem_translate_active),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_arsize_o(lsu_axi_arsize),
    .lsu_axi_rvalid_i(lsu_axi_rvalid),
    .lsu_axi_rready_o(lsu_axi_rready),
    .lsu_axi_rdata_i(lsu_axi_rdata),
    .lsu_axi_rresp_i(lsu_axi_rresp),
    .lsu_axi_awvalid_o(lsu_axi_awvalid),
    .lsu_axi_awready_i(lsu_axi_awready),
    .lsu_axi_awaddr_o(lsu_axi_awaddr),
    .lsu_axi_wvalid_o(lsu_axi_wvalid),
    .lsu_axi_wready_i(lsu_axi_wready),
    .lsu_axi_wdata_o(lsu_axi_wdata),
    .lsu_axi_wstrb_o(lsu_axi_wstrb),
    .lsu_axi_bvalid_i(lsu_axi_bvalid),
    .lsu_axi_bready_o(lsu_axi_bready),
    .lsu_axi_bresp_i(lsu_axi_bresp)
  );

  // Minimal independent tracker/MIQ model for this legacy bridge regression.
  // Focused S2-G1 tests below use explicit mutations; this table simply keeps
  // the pre-existing long-form test supplied with edge-old token metadata.
  always @(posedge clk) begin
    if (rst) begin
      mem0_req_owner_token <= 5'b0;
      for (owner_model_i = 0; owner_model_i < 32;
           owner_model_i = owner_model_i + 1) begin
        owner_kind_model[owner_model_i] <= 2'b00;
        owner_epoch_model[owner_model_i] <= 2'b01;
        owner_tval_model[owner_model_i] <= {`XLEN{1'b0}};
      end
    end else if (mem0_req_valid && mem0_req_ready) begin
      owner_kind_model[mem0_req_owner_token] <= mem0_req_owner_kind;
      owner_epoch_model[mem0_req_owner_token] <= mem0_req_mmu_epoch;
      owner_tval_model[mem0_req_owner_token] <= mem0_req_fault_tval;
      mem0_req_owner_token <= mem0_req_owner_token + 5'd1;
    end
  end

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

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      mmu_flush = 1'b0;
      dcache_dma_invalidate_all = 1'b0;
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      mem0_req_valid = 1'b0;
      mem0_req_write = 1'b0;
      mem0_req_probe = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_attr_valid = 1'b0;
      mem0_req_class = `OOO_MEM_CLASS_RSVD;
      mem0_req_cacheable = 1'b0;
      s2_station_identity_mutate = 1'b0;
      s2_active_identity_mutate = 1'b0;
      s2_active_tracker_mutate = 1'b0;
      s2_active_tval_mutate = 1'b0;
      s2_expected_effective_killed = 1'b0;
      mem0_device_release = 1'b0;
      mem0_device_cancel = 1'b0;
      mem0_req_addr = {`XLEN{1'b0}};
      mem0_req_wdata = {`XLEN{1'b0}};
      mem0_req_wstrb = {`STRB_W{1'b0}};
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      lsu_axi_rresp = 2'b00;
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      lsu_axi_bvalid = 1'b0;
      lsu_axi_bresp = 2'b00;
    end
  endtask

  // T4P: a line that is already hot when synchronous virtio DMA completes
  // must not escape through the S_LOOKUP hit-fusion arm.  The same request
  // becomes an AXI miss, refills host-updated PMEM data, and is hot thereafter.
  task automatic dma_invalidate_blocks_hit_fusion;
    localparam [`XLEN-1:0] DMA_ADDR = 64'h0000_0000_8000_d000;
    localparam [`XLEN-1:0] STALE_DATA = 64'h1111_2222_3333_4444;
    localparam [`XLEN-1:0] FRESH_DATA = 64'ha5a5_5a5a_c3c3_3c3c;
    begin
      // Seed a cold line through the real miss/fill path.
      issue_mem0_read(DMA_ADDR);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = STALE_DATA;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("dma seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("dma seed response data", mem0_rsp_rdata, STALE_DATA);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // Reissue the hot line.  Assert invalidate only in its decision cycle:
      // raw tag/data are stale, but the visible hit and fusion response are 0.
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DMA_ADDR;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("dma hot request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      dcache_dma_invalidate_all = 1'b1;
      #1;
      tb_check1("dma masks cached decision", dut.dcache_lookup_hit_w, 1'b0);
      tb_check1("dma masks hit fusion", dut.lookup_hit_fusion_w, 1'b0);
      tb_check1("dma decision has no stale response", mem0_rsp_valid, 1'b0);
      tb_check1("dma decision refetches PMEM", lsu_axi_arvalid, 1'b1);
      tb_check64("dma refetch address", lsu_axi_araddr, DMA_ADDR);
      tick();
      dcache_dma_invalidate_all = 1'b0;
      lsu_axi_arready = 1'b0;

      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = FRESH_DATA;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("dma refill response valid", mem0_rsp_valid, 1'b1);
      tb_check64("dma refill exposes fresh data", mem0_rsp_rdata, FRESH_DATA);
      tick();
      mem0_rsp_ready = 1'b0;

      // The new fill is cacheable again; no permanent disable/deadlock.
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DMA_ADDR;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("post-dma line hits", mem0_rsp_valid, 1'b1);
      tb_check64("post-dma hit returns fresh data", mem0_rsp_rdata, FRESH_DATA);
      tb_check1("post-dma hit avoids AR", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
    end
  endtask

  task automatic t4m_issue_device_load;
    input expect_walk;
    begin
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DEVICE_VA;
      mem0_req_wstrb = 8'h0f;
      #1;
      tb_check1("T4M device request ready", mem0_req_ready, 1'b1);
      tb_check1("T4M device request fire has no AR", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("T4M device request advance has no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      if (expect_walk) begin
        tb_check1("T4M device walk AR valid", lsu_axi_arvalid, 1'b1);
        tb_check64("T4M device walk PTE address", lsu_axi_araddr,
                   ROOT_PT + 64'd16);
        lsu_axi_arready = 1'b1;
        tick();
        #1;
        tb_check1("T4M device walk waits PTE", lsu_axi_rready, 1'b1);
        lsu_axi_rvalid = 1'b1;
        lsu_axi_rdata = DEVICE_SUPERPAGE_PTE;
        tick();
        lsu_axi_rvalid = 1'b0;
        #1;
      end
    end
  endtask

  task automatic sv39_posttranslate_device_owner;
    reg old_logic_leaked_ar;
    begin
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_device_release = 1'b0;
      mem0_device_cancel = 1'b0;
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;

      // PTW first access.  The old VA-based policy enters S_LOOKUP and exposes
      // DEVICE_PA immediately; keep the branch recoverable so RED finishes.
      t4m_issue_device_load(1'b1);
      old_logic_leaked_ar = lsu_axi_arvalid;
      tb_check1("T4M translated device waits without AR",
                old_logic_leaked_ar, 1'b0);
      tb_check64("T4M translated device final PA", dut.paddr_q, DEVICE_PA);
      if (old_logic_leaked_ar) begin
        $display("[T4M-OLD-LOGIC-LEAK] wrong-path AR addr=%h", lsu_axi_araddr);
        tick();
        lsu_axi_arready = 1'b0;
        lsu_axi_rvalid = 1'b1;
        lsu_axi_rdata = 64'hbad0_bad0_bad0_bad0;
        tick();
        lsu_axi_rvalid = 1'b0;
        #1;
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
      end else begin
        tb_check1("T4M translated device enters owner wait",
                  dut.state_q == 4'd10, 1'b1);
        tick();
        #1;
        tb_check1("T4M owner wait remains AR quiet", lsu_axi_arvalid, 1'b0);
        mem0_device_cancel = 1'b1;
        #1;
        tb_check1("T4M killed owner has no AR", lsu_axi_arvalid, 1'b0);
        tick();
        mem0_device_cancel = 1'b0;
        lsu_axi_arready = 1'b0;
        #1;
        tb_check1("T4M killed owner gets quiet response", mem0_rsp_valid, 1'b1);
        tb_check1("T4M killed owner response has no error", mem0_rsp_error, 1'b0);
        tb_check1("T4M killed owner response is not page fault",
                  mem0_rsp_page_fault, 1'b0);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
      end

      // The leaf filled DTLB even though the first owner was cancelled.  A
      // global flush while the DTLB-hit device request waits must stay AR quiet.
      lsu_axi_arready = 1'b1;
      t4m_issue_device_load(1'b0);
      tb_check1("T4M DTLB-hit device enters owner wait",
                dut.state_q == 4'd10, 1'b1);
      tb_check1("T4M DTLB-hit device waits without AR", lsu_axi_arvalid, 1'b0);
      flush = 1'b1;
      #1;
      tb_check1("T4M wait flush has no AR side effect", lsu_axi_arvalid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("T4M wait flush returns idle", dut.state_q == 4'd0, 1'b1);
      tb_check1("T4M wait flush has no ghost response", mem0_rsp_valid, 1'b0);
      tb_check1("T4M wait flush has no ghost AR", lsu_axi_arvalid, 1'b0);

      // A live exact owner is the only path that may expose the PLIC read.
      t4m_issue_device_load(1'b0);
      tb_check1("T4M live device initially waits", lsu_axi_arvalid, 1'b0);
      mem0_device_release = 1'b1;
      #1;
      tb_check1("T4M live owner releases one AR", lsu_axi_arvalid, 1'b1);
      tb_check64("T4M live owner AR uses translated PA", lsu_axi_araddr,
                 DEVICE_PA);
      tb_check64("T4M live owner AR keeps exact word size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd2});
      tick();
      mem0_device_release = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0000_0000_1234_5678;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("T4M live device response valid", mem0_rsp_valid, 1'b1);
      tb_check64("T4M live device response data", mem0_rsp_rdata,
                 64'h0000_0000_1234_5678);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      lsu_axi_arready = 1'b0;
      $display("[T4M-POSTTRANSLATE-DEVICE] cancel+flush quiet, live owner exact AR");
    end
  endtask

  task automatic check_svpbmt_pte_reserved_policy;
    reg [`XLEN-1:0] pbmt1_leaf;
    reg [`XLEN-1:0] pbmt2_leaf;
    reg [`XLEN-1:0] pbmt3_leaf;
    reg [`XLEN-1:0] pbmt1_nonleaf;
    reg [`XLEN-1:0] napot_leaf;
    reg [`XLEN-1:0] napot_bad_leaf;
    reg [`XLEN-1:0] napot_nonleaf;
    begin
      pbmt1_leaf = SUPERPAGE_PTE | (64'd1 << 61);
      pbmt2_leaf = SUPERPAGE_PTE | (64'd2 << 61);
      pbmt3_leaf = SUPERPAGE_PTE | (64'd3 << 61);
      pbmt1_nonleaf = ((ROOT_PT >> 12) << 10) | 64'h001 | (64'd1 << 61);
      napot_leaf =
          (SUPERPAGE_PTE & ~(64'hf << 10)) | (64'h8 << 10) | `SV39_PTE_N;
      napot_bad_leaf =
          (SUPERPAGE_PTE & ~(64'hf << 10)) | (64'h7 << 10) | `SV39_PTE_N;
      napot_nonleaf = ((ROOT_PT >> 12) << 10) | 64'h001 | `SV39_PTE_N;

      tb_check1("mem structural checker leaves PBMT=1 to typed owner",
                dut.pte_reserved_fault(pbmt1_leaf, 2'd0), 1'b0);
      tb_check1("mem structural checker leaves PBMT=2 to typed owner",
                dut.pte_reserved_fault(pbmt2_leaf, 2'd0), 1'b0);
      tb_check1("mem structural checker leaves PBMT=3 to typed owner",
                dut.pte_reserved_fault(pbmt3_leaf, 2'd0), 1'b0);
      tb_check1("mem non-leaf PBMT remains reserved",
                dut.pte_reserved_fault(pbmt1_nonleaf, 2'd1), 1'b1);
      tb_check1("mem Svnapot 64KiB leaf is legal",
                dut.pte_reserved_fault(napot_leaf, 2'd0), 1'b0);
      tb_check1("mem Svnapot bad ppn encoding faults",
                dut.pte_reserved_fault(napot_bad_leaf, 2'd0), 1'b1);
      tb_check1("mem Svnapot non-leaf faults",
                dut.pte_reserved_fault(napot_nonleaf, 2'd1), 1'b1);
      tb_check1("mem Svnapot level1 leaf faults",
                dut.pte_reserved_fault(napot_leaf, 2'd1), 1'b1);
      tb_check64("mem Svnapot PA uses VA low PPN bits",
                 dut.leaf_paddr(napot_leaf, DATA_VA, 2'd0), DATA_PA);
    end
  endtask

  task automatic check_post_translate_memory_class;
    integer raw_cacheable;
    integer pma_fault_case;
    integer pbmt_case;
    reg expected_fault;
    reg expected_cacheable;
    reg expected_serialized;
    begin
      class_access_valid = 1'b0;
      class_pma_fault = 1'b1;
      class_addr_cacheable = 1'b1;
      class_pbmt_valid = 1'b1;
      class_pbmt = 2'b00;
      #1;
      tb_check1("inactive classifier has no PBMT fault", class_pbmt_fault, 1'b0);
      tb_check1("inactive classifier has no cache class", class_cacheable, 1'b0);
      tb_check1("inactive classifier has no serialized class", class_serialized, 1'b0);

      class_access_valid = 1'b1;
      class_pbmt_valid = 1'b1;
      for (raw_cacheable = 0; raw_cacheable < 2; raw_cacheable = raw_cacheable + 1) begin
        for (pma_fault_case = 0; pma_fault_case < 2;
             pma_fault_case = pma_fault_case + 1) begin
          for (pbmt_case = 0; pbmt_case < 4; pbmt_case = pbmt_case + 1) begin
            class_addr_cacheable = raw_cacheable[0];
            class_pma_fault = pma_fault_case[0];
            class_pbmt = pbmt_case[1:0];
            expected_fault = (pbmt_case[1:0] == 2'b11);
            expected_cacheable = raw_cacheable[0] && !pma_fault_case[0] &&
                                 (pbmt_case[1:0] == 2'b00);
            expected_serialized = !pma_fault_case[0] &&
                                  (pbmt_case[1:0] != 2'b11) &&
                                  !expected_cacheable;
            #1;
            tb_check1("post-translate PBMT fault matrix",
                      class_pbmt_fault, expected_fault);
            tb_check1("post-translate cacheable matrix",
                      class_cacheable, expected_cacheable);
            tb_check1("post-translate serialized matrix",
                      class_serialized, expected_serialized);
          end
        end
      end

      class_pbmt_valid = 1'b0;
      class_pbmt = 2'b10;
      class_pma_fault = 1'b0;
      class_addr_cacheable = 1'b1;
      #1;
      tb_check1("disabled Svpbmt uses PMA default cacheability",
                class_cacheable, 1'b1);
      tb_check1("disabled Svpbmt ignores leaf bits",
                class_pbmt_fault, 1'b0);
      $display("[R4-S0-POSTXLATE-CLASS] 2x2x4 matrix + inactive/default PASS");
    end
  endtask

  task automatic issue_mem0_read;
    input [`XLEN-1:0] addr;
    begin
      issue_mem0_read_strb(addr, {`STRB_W{1'b1}});
    end
  endtask

  // 【line-dcache】读 miss 语义(AXI4 化 S3 后以 ARSIZE 表达): 不跨线 → 对齐
  // AR(addr&~7)+ARSIZE=8B(取整线); 跨线 → 原窗口 AR+ARSIZE=log2(访问宽度)。
  function automatic [3:0] strb_nbytes;
    input [`STRB_W-1:0] strb;
    integer bi;
    begin
      strb_nbytes = 4'd0;
      for (bi = 0; bi < `STRB_W; bi = bi + 1)
        if (strb[bi]) strb_nbytes = strb_nbytes + 4'd1;
      if (strb_nbytes == 4'd0) strb_nbytes = 4'd1;
    end
  endfunction

  function automatic [2:0] axsize_from_nbytes;
    input [3:0] nbytes;
    begin
      axsize_from_nbytes = (nbytes >= 4'd8) ? 3'd3 :
                           (nbytes >= 4'd4) ? 3'd2 :
                           (nbytes >= 4'd2) ? 3'd1 : 3'd0;
    end
  endfunction

  // 【刀 M·寄存站】读请求 fire 拍只进寄存站(零计算, 不发 lookup/AR); 次拍
  // stage_advance 发 dcache SRAM 读(不发 AR); 再次拍 S_LOOKUP 判决 miss 后才发
  // AR——本 task 只用于 miss 场景, AR 检查较 SRAM 同步读版再右移一拍, task 结束
  // 时桥已进 S_READ_DATA(对调用方等价)。
  task automatic issue_mem0_read_strb;
    input [`XLEN-1:0] addr;
    input [`STRB_W-1:0] strb;
    reg is_cross_r;
    begin
      is_cross_r = ({1'b0, addr[2:0]} + strb_nbytes(strb)) > 5'd8;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = addr;
      mem0_req_wstrb = strb;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("mem0 read request ready", mem0_req_ready, 1'b1);
      tb_check1("mem0 read no AR at fire", lsu_axi_arvalid, 1'b0);
      // 【刀 M·负测试锚点】fire 拍(寄存站空)不得出现 req 源 dcache lookup——
      // 对旧"fire 拍发 lookup"实现本检查必 FAIL(负测试证据存 task-runs)。
      tb_check1("mem0 read no req lookup at fire", dut.req_read_lookup_fire_w,
                1'b0);
      tb_check1("mem0 read no speculative lookup at fire",
                dut.req_read_lookup_issue_w, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      // advance 拍: 寄存站项进 FSM 并发 dcache lookup, AR 最早在判决拍。
      tb_check1("mem0 read advance no AR", lsu_axi_arvalid, 1'b0);
      tb_check1("mem0 read req lookup at advance", dut.req_read_lookup_fire_w,
                1'b1);
      tb_check1("mem0 read speculative lookup at advance",
                dut.req_read_lookup_issue_w, 1'b1);
      tick();
      #1;
      tb_check1("mem0 read issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("mem0 read AR address", lsu_axi_araddr,
                 is_cross_r ? addr : {addr[`XLEN-1:3], 3'b000});
      tb_check64("mem0 read AR size", {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 is_cross_r ? {{(`XLEN-3){1'b0}}, axsize_from_nbytes(strb_nbytes(strb))}
                       : {{(`XLEN-3){1'b0}}, 3'd3});
      tick();
      lsu_axi_arready = 1'b0;
    end
  endtask

  task automatic read_arsize_tracks_load_mask;
    begin
      issue_mem0_read_strb(64'h0000_0000_8000_1005, 8'b0010_0000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0102_0304_0506_0708;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("masked read response valid", mem0_rsp_valid, 1'b1);
      // 窗口视图: 对齐 line 右移 paddr[2:0]*8(off=5)
      tb_check64("masked read window data", mem0_rsp_rdata,
                 64'h0000_0000_0001_0203);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // 【刀 M+SRAM 同步读】hit 路径统一在 S_LOOKUP 判决拍以锁存 paddr_q[2:0] 移位
  // (fire→advance→判决→S_RESP, 共 +1 拍); 本场景补两块原 cache 组合口负责、
  // SRAM 化后移到桥判决拍的语义审核:
  //   (a) unaligned hit 的窗口移位视图(接住 cache TB 里被移走的移位检查);
  //   (b) 跨线窗口即使 line 有效也必须 miss 走 AXI 原窗口读(read_cross_q 阻断
  //       hit——DWC-I2 的桥侧新落点)。
  task automatic cached_window_shift_and_cross_block;
    begin
      // (a) 前场景已 fill line 0x8000_1000=0x0102_0304_0506_0708; 同址 unaligned hit
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1005;
      mem0_req_wstrb = 8'b0010_0000;
      lsu_axi_arready = 1'b1;   // 陷阱: advance/判决拍均不得发 AR
      #1;
      tb_check1("cached window read ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("cached window advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("cached window hit no AR", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("cached window response valid", mem0_rsp_valid, 1'b1);
      tb_check64("cached window shifted data", mem0_rsp_rdata,
                 64'h0000_0000_0001_0203);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // (b) 跨线窗口(off=6, 4B): line 0x8000_1000 有效仍必须 miss(原窗口 AR,
      //     数据原样回传、不 fill)
      issue_mem0_read_strb(64'h0000_0000_8000_1006, 8'b0000_1111);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1a2b_3c4d_5e6f_7081;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("cross-line read response valid", mem0_rsp_valid, 1'b1);
      tb_check64("cross-line read data passthrough", mem0_rsp_rdata,
                 64'h1a2b_3c4d_5e6f_7081);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // IFU-ACCESS-G1 总线刀只收窄 instruction read；LSU data 仍保留 exact-address /
      // 低位窗口 ABI。用 off=5,size=4 再钉一行，防止 sized DPI 改造把 data narrow
      // 误套成 instruction 的标准 byte-lane 布局。
      issue_mem0_read_strb(64'h0000_0000_8000_1005, 8'b0000_1111);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h8877_6655_4433_2211;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("cross-line off5 size4 response valid", mem0_rsp_valid, 1'b1);
      tb_check64("cross-line off5 size4 data stays low-window", mem0_rsp_rdata,
                 64'h8877_6655_4433_2211);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  task automatic held_response_flush_drop;
    begin
      // 【line-dcache】前一场景(1005 掩码读)已 fill 对齐 line 0x80001000,
      // 换未被 fill 的地址保持"miss→等 R"场景语义。
      issue_mem0_read(64'h0000_0000_8000_6000);
      #1;
      tb_check1("mem0 read waits for R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1122_3344_5566_7788;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("mem0 response is held", mem0_rsp_valid, 1'b1);
      tb_check64("mem0 held response data", mem0_rsp_rdata,
                 64'h1122_3344_5566_7788);

      flush = 1'b1;
      #1;
      tb_check1("flush hides held response", mem0_rsp_valid, 1'b0);
      tb_check1("flush blocks new request", mem0_req_ready, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("held response dropped", mem0_rsp_valid, 1'b0);
      tb_check1("bridge accepts request after held drop", mem0_req_ready, 1'b1);
    end
  endtask

  task automatic inflight_read_flush_abort;
    begin
      issue_mem0_read(64'h0000_0000_8000_3000);
      flush = 1'b1;
      #1;
      tb_check1("flush keeps current R channel ready", lsu_axi_rready, 1'b1);
      tb_check1("flush suppresses inflight response", mem0_rsp_valid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      // 【AXI4 化 S1 契约反转】flush 后桥不再即刻空闲(旧=依赖 xbar abort 吞 R),
      // 改为本地持械等 R(drop_rsp_q)——rready 保持, 吞完残 R 才回 IDLE。
      tb_check1("flushed read keeps draining R", lsu_axi_rready, 1'b1);
      tb_check1("flushed read has no CPU response", mem0_rsp_valid, 1'b0);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hdead_dead_dead_dead;  // 残 R: 必须被吞掉不上交
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("stale R swallowed no response", mem0_rsp_valid, 1'b0);
      tb_check1("bridge idle after drain", mem0_req_ready, 1'b1);

      issue_mem0_read(64'h0000_0000_8000_3008);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'haaaa_bbbb_cccc_dddd;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("post-abort read response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-abort read response data", mem0_rsp_rdata,
                 64'haaaa_bbbb_cccc_dddd);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // T4E：AXI AR 一旦在 READY=0 时呈现，flush/drop 只能把事务转为本地
  // drain，不能撤回 VALID 或改 payload。分别覆盖 data miss 与 PTW walk，含
  // repeated flush、live-input poison，以及 flush+READY 同拍握手。
  task automatic stalled_ar_survives_flush;
    reg [`XLEN-1:0] held_araddr;
    begin
      // (a) data miss: S_LOOKUP 首拍 AR stall 后进入注册地址 owner S_READ_ADDR。
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_7000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b0;
      tick();
      mem0_req_valid = 1'b0;
      tick();                    // advance -> S_LOOKUP
      #1;
      tb_check1("T4E data stalled AR is presented", lsu_axi_arvalid, 1'b1);
      held_araddr = lsu_axi_araddr;
      tick();                    // sampled VALID&&!READY -> S_READ_ADDR

      flush = 1'b1;
      mem0_req_addr = 64'hffff_ffff_dead_beef;  // live-input poison
      #1;
      tb_check1("T4E data flush holds ARVALID", lsu_axi_arvalid, 1'b1);
      tb_check64("T4E data flush holds ARADDR", lsu_axi_araddr, held_araddr);
      tick();                    // repeated flush, still stalled
      #1;
      tb_check1("T4E data repeated flush holds ARVALID", lsu_axi_arvalid,
                1'b1);
      tb_check64("T4E data repeated flush holds ARADDR", lsu_axi_araddr,
                 held_araddr);

      lsu_axi_arready = 1'b1;
      tick();                    // flush+READY: AR handshake must complete
      lsu_axi_arready = 1'b0;
      flush = 1'b0;
      #1;
      tb_check1("T4E data post-AR drains R", lsu_axi_rready, 1'b1);
      tb_check1("T4E data drain suppresses CPU response", mem0_rsp_valid,
                1'b0);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hbad0_bad0_bad0_bad0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("T4E data stale R swallowed", mem0_rsp_valid, 1'b0);
      tb_check1("T4E data drain returns idle", mem0_req_ready, 1'b1);

      // (b) PTW: S_WALK_AR itself is the registered owner.  Hold for one
      // full stalled beat before asserting flush, then handshake under flush.
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_addr = DATA_VA;
      mem0_req_valid = 1'b1;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      tick();
      mem0_req_valid = 1'b0;
      tick();                    // advance -> S_WALK_AR
      #1;
      tb_check1("T4E walk stalled AR is presented", lsu_axi_arvalid, 1'b1);
      held_araddr = lsu_axi_araddr;
      tick();                    // sampled VALID&&!READY, remains S_WALK_AR

      flush = 1'b1;
      mem0_req_addr = 64'h1111_2222_3333_4444;  // live-input poison
      #1;
      tb_check1("T4E walk flush holds ARVALID", lsu_axi_arvalid, 1'b1);
      tb_check64("T4E walk flush holds ARADDR", lsu_axi_araddr, held_araddr);
      tick();
      #1;
      tb_check1("T4E walk repeated flush holds ARVALID", lsu_axi_arvalid,
                1'b1);
      tb_check64("T4E walk repeated flush holds ARADDR", lsu_axi_araddr,
                 held_araddr);

      lsu_axi_arready = 1'b1;
      tick();                    // flush+READY: walk AR handshake
      lsu_axi_arready = 1'b0;
      flush = 1'b0;
      #1;
      tb_check1("T4E walk post-AR drains PTE R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SUPERPAGE_PTE;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("T4E walk stale PTE swallowed", mem0_rsp_valid, 1'b0);
      tb_check1("T4E walk drain returns idle", mem0_req_ready, 1'b1);

      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      mem0_req_addr = {`XLEN{1'b0}};
      $display("[T4E-MEM-AR-HOLD] data+walk valid/payload held; repeated-flush+ready drained");
    end
  endtask

  task automatic partial_write_flush_drain;
    begin
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_4000;
      mem0_req_wdata = 64'h0102_0304_0506_0708;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("write request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;

      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b0;
      #1;
      // 【刀 M】advance 拍: 寄存站项进 FSM, AW/W 最早次拍可见。
      tb_check1("write advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("write issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("write issues W", lsu_axi_wvalid, 1'b1);
      tb_check64("write AW address", lsu_axi_awaddr,
                 64'h0000_0000_8000_4000);
      tick();
      lsu_axi_awready = 1'b0;

      flush = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("flush drains remaining W", lsu_axi_wvalid, 1'b1);
      tb_check64("flush drain W data", lsu_axi_wdata,
                 64'h0102_0304_0506_0708);
      tick();
      flush = 1'b0;
      lsu_axi_wready = 1'b0;
      // 【刀 M·免费 skid】drop 窗口 ready=1: 在 B 等待拍把 correct-path load
      // 提前送进寄存站排队(旧契约此处 ready=0), advance 由 state 门挡住。
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_4100;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("write drain waits for B", lsu_axi_bready, 1'b1);
      tb_check1("write drain suppresses response", mem0_rsp_valid, 1'b0);
      tb_check1("drop window accepts into stage (skid)", mem0_req_ready, 1'b1);

      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      mem0_req_valid = 1'b0;
      #1;
      // Killed write cleanup is conservative invalidate-only: it must not use
      // the exact-owner RMW path.  Therefore no RMW bubble blocks the staged
      // correct-path load; it advances immediately after the B/drop terminal.
      tb_check1("write drain invalidate lets staged load advance",
                dut.stage_advance_w, 1'b1);
      tb_check1("write drain staged load owns req lookup",
                dut.req_read_lookup_fire_w, 1'b1);
      tb_check1("write drain never exposes response", mem0_rsp_valid, 1'b0);
      lsu_axi_arready = 1'b1;
      tick();
      #1;
      // 判决拍: 0x8000_4100 未 fill → miss 发 AR, 走通整条 skid load。
      tb_check1("post-drain skid load issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("post-drain skid load AR address", lsu_axi_araddr,
                 64'h0000_0000_8000_4100);
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h5a5a_a5a5_5a5a_a5a5;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("post-drain skid load response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-drain skid load response data", mem0_rsp_rdata,
                 64'h5a5a_a5a5_5a5a_a5a5);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check1("bridge idle after write drain", mem0_req_ready, 1'b1);
    end
  endtask

  task automatic flushed_store_does_not_poison_dcache;
    begin
      issue_mem0_read(64'h0000_0000_8000_5000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("dcache seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("dcache seed response data", mem0_rsp_rdata,
                 64'h1111_2222_3333_4444);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("aborted store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;

      flush = 1'b1;
      #1;
      tb_check1("aborted store hides response", mem0_rsp_valid, 1'b0);
      // 【刀 M】flush 拍站内 plain store 被当拍清除(未 advance 即止损, 比现状
      // 更早): 全程不得出现 AW。
      tb_check1("aborted store never issues AW", lsu_axi_awvalid, 1'b0);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("aborted store returns idle", mem0_req_ready, 1'b1);
      tb_check1("aborted store cleared from stage", dut.stg_valid_q, 1'b0);

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      #1;
      tb_check1("post-abort read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【刀 M+1-cycle 同步读】hit 判定在 S_LOOKUP 判决拍(advance 次拍):
      // aborted store 未 commit 不失效 line, 判决拍命中、不发 AR。
      #1;
      tb_check1("post-abort read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-abort read hits cache", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-abort cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("aborted store must not update dcache", mem0_rsp_rdata,
                 64'h1111_2222_3333_4444);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("committed store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("committed store advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("committed store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("committed store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("committed store waits B", lsu_axi_bready, 1'b1);
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("committed store response valid", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("post-commit read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【store RMW·write-update】committed store 在完成拍 2 拍 RMW 线内合并,
      // line 保持有效且已含新数据: 同址读判决拍命中, 不发 AR, 数据来自 cache
      // (与 PMEM 一致, MEM-I2 下 store 数据已落 PMEM)。
      #1;
      tb_check1("post-commit read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-commit read hits updated line", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("post-commit cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("committed store data visible via cache hit", mem0_rsp_rdata,
                 64'haaaa_bbbb_cccc_dddd);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      mem0_req_wdata = 64'h1234_5678_9abc_def0;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("drained store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("drained store advance no AW", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("drained store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("drained store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("drained store waits B", lsu_axi_bready, 1'b1);
      flush = 1'b1;
      lsu_axi_bvalid = 1'b1;
      tick();
      flush = 1'b0;
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("drained store hides response", mem0_rsp_valid, 1'b0);

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("post-drain read no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // A killed write may have reached PMEM, but it is not authorized to RMW
      // cache data.  Its B terminal conservatively invalidates the alias; the
      // next read must miss and refill the externally visible value.
      #1;
      tb_check1("post-drain read advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("post-drain read refetches invalidated line", lsu_axi_arvalid, 1'b1);
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1234_5678_9abc_def0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("post-drain refill response valid", mem0_rsp_valid, 1'b1);
      tb_check64("drained store data visible after refill", mem0_rsp_rdata,
                 64'h1234_5678_9abc_def0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // R4 S0: an aggregated B error does not prove that no split sub-write reached
  // memory.  The bridge must therefore invalidate a possible hot alias without
  // starting the B-OK RMW path.  The following read must miss and refill.
  task automatic b_error_invalidates_possible_partial_store_alias;
    localparam [`XLEN-1:0] HOT_ADDR = 64'h0000_0000_8000_7800;
    begin
      clear_inputs();
      tick();

      issue_mem0_read(HOT_ADDR);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("B-error alias seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("B-error alias seed data", mem0_rsp_rdata,
                 64'h1111_2222_3333_4444);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_attr_valid = 1'b1;
      mem0_req_class = `OOO_MEM_CLASS_CACHED;
      mem0_req_cacheable = 1'b1;
      mem0_req_addr = HOT_ADDR;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("B-error alias store request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_attr_valid = 1'b0;
      mem0_req_class = `OOO_MEM_CLASS_RSVD;
      mem0_req_cacheable = 1'b0;
      tick();
      #1;
      tb_check1("B-error alias store AW valid", lsu_axi_awvalid, 1'b1);
      tb_check1("B-error alias store W valid", lsu_axi_wvalid, 1'b1);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("B-error alias store waits terminal", lsu_axi_bready, 1'b1);
      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = 2'b10;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("B-error alias response valid", mem0_rsp_valid, 1'b1);
      tb_check1("B-error alias response reports error", mem0_rsp_error, 1'b1);
      tb_check1("B-error alias does not start RMW", dut.dcache_rmw_busy_w,
                1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      lsu_axi_bresp = 2'b00;

      // issue_mem0_read contains the decisive no-hit/AR-present checks.  It
      // would fail in the old implementation that kept the stale hot line.
      issue_mem0_read(HOT_ADDR);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h5555_6666_7777_8888;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("B-error alias refill response valid", mem0_rsp_valid, 1'b1);
      tb_check64("B-error alias refills non-stale memory view", mem0_rsp_rdata,
                 64'h5555_6666_7777_8888);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      $display("[R4-S0-BERR-ALIAS] terminal error invalidates hot line without RMW PASS");
    end
  endtask

  // 【store RMW×刀 M 定向】write-update 的 2 拍 RMW 与读口仲裁:
  //   (a) store advance 拍站口即空出——back-to-back load 当拍进寄存站(免费 skid);
  //   (b) store 完成次拍(RMW 判决拍)rmw_busy 压 stage_advance——站内 load 被
  //       保持 1 bubble(观察点从旧 req_ready 压制改为寄存站保持, 契约不弱化);
  //   (c) bubble 后的同址 load 命中 RMW 合并后的 line(部分字节 wstrb 合并,
  //       数据来自 cache 而非 AXI——本场景 R 通道全程不驱动即为证明)。
  task automatic store_rmw_write_update_and_bubble;
    begin
      // 种子 fill: 读 0x8000_7000 → line = 0x1111_2222_3333_4444
      issue_mem0_read(64'h0000_0000_8000_7000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("rmw seed response valid", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 低 4B 部分 store：AW/W 仅被 adapter 接收，聚合 B 才 commit/RMW。
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_7000;
      mem0_req_wdata = 64'h0000_0000_dead_beef;
      mem0_req_wstrb = 8'b0000_1111;
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      #1;
      tb_check1("rmw store request ready", mem0_req_ready, 1'b1);
      tick();
      // 同拍立即换上 back-to-back load 请求(考寄存站 back-to-back+RMW 保持)
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_7000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      #1;
      // store advance 拍: 站口腾出, back-to-back load 可当拍 fire 进站。
      tb_check1("rmw store advance accepts next (stage b2b)",
                mem0_req_ready, 1'b1);
      tb_check1("rmw store advance no AW yet", lsu_axi_awvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("rmw store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("rmw store issues W", lsu_axi_wvalid, 1'b1);
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("rmw store waits aggregate B", lsu_axi_bready, 1'b1);
      tb_check1("rmw store has no pre-B response", mem0_rsp_valid, 1'b0);
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      // B-ok 后的 RMW 判决拍: store 响应有效(S_RESP)且被消费，
      // 但 rmw_busy 必须压住站内
      // load 的 advance(不发 lookup)——这就是 store 后 1 bubble 的新观察点。
      tb_check1("rmw decision cycle store response valid", mem0_rsp_valid,
                1'b1);
      tb_check1("rmw decision cycle holds staged load (1 bubble)",
                dut.stage_advance_w, 1'b0);
      tb_check1("rmw decision cycle no req lookup",
                dut.req_read_lookup_fire_w, 1'b0);
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      // bubble 之后站内 load 恢复 advance(发 lookup)。
      tb_check1("staged load advances after rmw bubble",
                dut.stage_advance_w, 1'b1);
      lsu_axi_arready = 1'b1;   // 陷阱: 命中不得发 AR
      tick();
      #1;
      tb_check1("post-rmw load hits merged line (no AR)", lsu_axi_arvalid,
                1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("post-rmw load response valid", mem0_rsp_valid, 1'b1);
      tb_check64("post-rmw load returns byte-merged data", mem0_rsp_rdata,
                 64'h1111_2222_dead_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      tick();
    end
  endtask

  task automatic sv39_dtlb_and_paddr_cache_hit;
    begin
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("sv39 first request ready", mem0_req_ready, 1'b1);
      tb_check1("sv39 first request no direct data AR", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;

      #1;
      // 【刀 M】advance 拍才做 DTLB 判定并转 S_WALK_AR, walk AR 次拍可见。
      tb_check1("sv39 advance no walk AR yet", lsu_axi_arvalid, 1'b0);
      tick();

      #1;
      tb_check1("sv39 first walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 first walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      tb_check64("sv39 first walk AR size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd3});
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 first walk waits R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SUPERPAGE_PTE;
      tick();
      lsu_axi_rvalid = 1'b0;

      #1;
      tb_check1("sv39 translated data AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 translated data AR physical", lsu_axi_araddr, DATA_PA);
      tb_check64("sv39 translated data AR size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd3});
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 data waits R", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hfeed_face_cafe_beef;
      tick();
      lsu_axi_rvalid = 1'b0;

      #1;
      tb_check1("sv39 first response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 first response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("sv39 repeat request ready", mem0_req_ready, 1'b1);
      tb_check1("sv39 repeat no AR at fire", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      // 【刀 M+1-cycle 同步读】第二次同页同字访问由 DTLB + 物理 data cache 命中:
      // advance 拍 DTLB 命中发 lookup, hit 判定在 S_LOOKUP 判决拍, 全程不发
      // page-walk/data AR。
      #1;
      tb_check1("sv39 repeat advance no AXI AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 repeat request no AXI AR", lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("sv39 repeat response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 repeat response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 【新增·walk-hit 路径】mmu_flush 清 DTLB(物理索引 dcache 不清)后重访:
      // TLB miss → walk 读 PTE → leaf-ok 拍发 dcache 读 → S_LOOKUP 判决 hit,
      // 不发 data AR。该路径覆盖旧 walk 组合口(无移位/无跨线检查)错值 bug 的
      // 修复落点: 判决拍统一按锁存 paddr_q 移位。
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("sv39 walk-hit request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("sv39 walk-hit advance no AR yet", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 walk-hit walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 walk-hit walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("sv39 walk-hit waits PTE", lsu_axi_rready, 1'b1);
      // T4C: S_WALK_R owns the leaf-derived payload even before RVALID, while
      // enable remains low.  Poison the live RDATA so a qualified-fire mux
      // regression selects the stale paddr_q and is directly observable.
      // Level-2 leaves preserve PTE[53:28] and replace PTE[27:10] with the
      // virtual-page offset.  Flip PTE bit 28 so the poison is guaranteed to
      // change the derived PA (bit 30), rather than an ignored superpage bit.
      lsu_axi_rdata = SUPERPAGE_PTE ^ 64'h0000_0000_1000_0000;
      #1;
      tb_check1("T4C walk wait owns payload", dut.walk_lookup_payload_owner_w,
                1'b1);
      tb_check1("T4C walk wait has no lookup", dut.dcache_lookup_en_w, 1'b0);
      tb_check64("T4C poison leaf PA",
                 dut.walk_leaf_paddr_w,
                 DATA_PA ^ 64'h0000_0000_4000_0000);
      tb_check1("T4C poison differs from fallback",
                (dut.walk_leaf_paddr_w !== dut.paddr_q), 1'b1);
      tb_check64("T4C walk wait selects leaf payload",
                 dut.dcache_lookup_addr_w, dut.walk_leaf_paddr_w);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SUPERPAGE_PTE;
      #1;
      tb_check1("T4C qualified walk keeps owner",
                dut.walk_lookup_payload_owner_w, 1'b1);
      tb_check1("T4C qualified walk issues lookup",
                dut.dcache_lookup_en_w, 1'b1);
      tb_check64("T4C qualified walk selects leaf PA",
                 dut.dcache_lookup_addr_w, dut.walk_leaf_paddr_w);
      $display("[T4C-WALK-PAYLOAD-OWNER] waiting=owner/no-en qualified=owner/en");
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("sv39 walk-hit no data AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("sv39 walk-hit response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 walk-hit response data", mem0_rsp_rdata,
                 64'hfeed_face_cafe_beef);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
    end
  endtask

  // A PBMT NC/IO leaf may map to a PA whose raw address is in PMEM.  Keep the
  // physical line hot, clear only the DTLB, then prove that the translated
  // request ignores the raw cache hit and waits for the precise serialized
  // owner before issuing an exact AXI read.
  // S1 fault priority, DTLB-hit form.  First cache DATA_PA and fill a DTLB
  // entry carrying legal PBMT-NC.  Then disable PBMTE and simultaneously PMP
  // deny DATA_PA: the now-reserved PBMT must win as page fault, provenance is
  // poisoned, and the known-hot cache line must not receive a lookup enable.
  task automatic pbmt_reserved_beats_pmp_dtlb_hit;
    reg [`XLEN-1:0] pbmt_nc_leaf;
    begin
      pbmt_nc_leaf = SUPERPAGE_PTE | (64'd1 << 61);
      clear_inputs();
      tick();
      dcache_dma_invalidate_all = 1'b1;
      tick();
      dcache_dma_invalidate_all = 1'b0;

      // Seed a known-hot physical line.
      issue_mem0_read(DATA_PA);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h5eed_cafe_1234_5678;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("PBMT/PMP DTLB seed cached response", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // Fill DTLB with PBMT-NC while all permissions allow.
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      svpbmt_en = 1'b1;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("PBMT/PMP DTLB fill request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("PBMT/PMP DTLB fill walk AR", lsu_axi_arvalid, 1'b1);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = pbmt_nc_leaf;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("PBMT/PMP legal leaf fills DTLB", dut.dtlb_fill_valid_w, 1'b1);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("PBMT/PMP NC bypass presents exact AR", lsu_axi_arvalid, 1'b1);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h1111_2222_3333_4444;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("PBMT/PMP DTLB fill response", mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // Same cached DTLB PTE: PBMTE-off makes PBMT=01 reserved, while the
      // root-only PMP map independently denies final DATA_PA.
      svpbmt_en = 1'b0;
      pmpcfg = PMP_ROOT_PTE_READ_CFG;
      pmpaddr = PMP_ROOT_PTE_READ_ADDR;
      mem0_req_valid = 1'b1;
      mem0_req_addr = DATA_VA;
      #1;
      tb_check1("PBMT/PMP DTLB deny request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("PBMT/PMP DTLB context hit", dut.req_dtlb_context_hit_w, 1'b1);
      tb_check1("PBMT/PMP DTLB reserved detected", dut.req_typed_page_fault_w,
                1'b1);
      tb_check1("PBMT/PMP DTLB final PA independently PMP denied",
                dut.req_data_pmp_fault_w, 1'b1);
      tb_check1("PBMT/PMP DTLB final attr poisoned",
                dut.req_effective_attr_valid_w, 1'b0);
      tb_check32("PBMT/PMP DTLB final class poison",
                 {30'b0, dut.req_effective_class_w},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("PBMT/PMP DTLB hot line lookup suppressed",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check1("PBMT/PMP DTLB has no target side effect",
                lsu_axi_arvalid | lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      tick();
      #1;
      tb_check1("PBMT/PMP DTLB response valid", mem0_rsp_valid, 1'b1);
      tb_check1("PBMT/PMP DTLB priority reports page fault",
                mem0_rsp_page_fault, 1'b1);
      tb_check1("PBMT/PMP DTLB response attr invalid",
                mem0_rsp_attr_valid, 1'b0);
      tb_check32("PBMT/PMP DTLB response class poison",
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("PBMT/PMP DTLB response cacheable poison",
                mem0_rsp_cacheable, 1'b0);
      tb_check1("PBMT/PMP DTLB response still no target",
                lsu_axi_arvalid | lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      $display("[S1-PBMT-PMP-PRIORITY-DTLB] page>PMP, attr poison, no lookup/target PASS");
    end
  endtask

  // Same priority counterexample at the PTW leaf.  PMP allows the PTE read but
  // denies final DATA_PA, while PBMT=11 is reserved.  No DTLB fill, cache
  // lookup, A/D write, or data target may escape.
  task automatic pbmt_reserved_beats_pmp_ptw_leaf;
    reg [`XLEN-1:0] pbmt_reserved_leaf;
    begin
      pbmt_reserved_leaf = SUPERPAGE_PTE | (64'd3 << 61);
      clear_inputs();
      tick();
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      svpbmt_en = 1'b1;
      pmpcfg = PMP_ROOT_PTE_READ_CFG;
      pmpaddr = PMP_ROOT_PTE_READ_ADDR;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("PBMT/PMP PTW request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("PBMT/PMP PTW root PTE AR allowed", lsu_axi_arvalid, 1'b1);
      tb_check64("PBMT/PMP PTW root PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = pbmt_reserved_leaf;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("PBMT/PMP PTW reserved detected",
                dut.walk_leaf_page_fault_w, 1'b1);
      tb_check1("PBMT/PMP PTW final PA independently PMP denied",
                dut.walk_leaf_pmp_fault_w, 1'b1);
      tb_check1("PBMT/PMP PTW final attr poisoned",
                dut.walk_leaf_attr_valid_w, 1'b0);
      tb_check32("PBMT/PMP PTW final class poison",
                 {30'b0, dut.walk_leaf_class_w},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("PBMT/PMP PTW cannot fill DTLB", dut.dtlb_fill_valid_w, 1'b0);
      tb_check1("PBMT/PMP PTW cannot lookup cache", dut.dcache_lookup_en_w,
                1'b0);
      tb_check1("PBMT/PMP PTW leaf has no target/write side effect",
                lsu_axi_arvalid | lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("PBMT/PMP PTW response valid", mem0_rsp_valid, 1'b1);
      tb_check1("PBMT/PMP PTW priority reports page fault",
                mem0_rsp_page_fault, 1'b1);
      tb_check1("PBMT/PMP PTW response attr invalid",
                mem0_rsp_attr_valid, 1'b0);
      tb_check32("PBMT/PMP PTW response class poison",
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("PBMT/PMP PTW response cacheable poison",
                mem0_rsp_cacheable, 1'b0);
      tb_check1("PBMT/PMP PTW response has no target/write side effect",
                lsu_axi_arvalid | lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      $display("[S1-PBMT-PMP-PRIORITY-PTW] page>PMP, no fill/lookup/target PASS");
    end
  endtask

  task automatic sv39_pbmt_pmem_bypasses_dcache;
    input [1:0] pbmt;
    input [`XLEN-1:0] returned_data;
    reg [`XLEN-1:0] pbmt_leaf;
    begin
      pbmt_leaf = SUPERPAGE_PTE | ({{(`XLEN-2){1'b0}}, pbmt} << 61);
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      svpbmt_en = 1'b1;
      mem0_device_release = 1'b0;
      mem0_device_cancel = 1'b0;
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("PBMT PMEM request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("PBMT PMEM walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("PBMT PMEM walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = pbmt_leaf;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check64("PBMT PMEM final PA", dut.paddr_q, DATA_PA);
      tb_check1("PBMT PMEM final class is non-cacheable",
                dut.access_attr_valid_q &&
                (dut.access_class_q == `OOO_MEM_CLASS_CACHED), 1'b0);
      tb_check1("PBMT PMEM typed attr valid",
                dut.access_attr_valid_q, 1'b1);
      tb_check32("PBMT PMEM exact typed class",
                 {30'b0, dut.access_class_q},
                 {30'b0, (pbmt == 2'b01) ? `OOO_MEM_CLASS_NC :
                                           `OOO_MEM_CLASS_IO});
      tb_check1("PBMT PMEM hot line cannot respond", mem0_rsp_valid, 1'b0);
      if (pbmt == 2'b01) begin
        tb_check1("PBMT NC enters exact read owner",
                  dut.state_q == 4'd3, 1'b1);
        tb_check1("PBMT NC presents exact AR without device wait",
                  lsu_axi_arvalid, 1'b1);
      end else begin
        tb_check1("PBMT IO enters serialized owner wait",
                  dut.state_q == 4'd10, 1'b1);
        tb_check1("PBMT IO wait presents no unowned AR",
                  lsu_axi_arvalid, 1'b0);
        mem0_device_release = 1'b1;
      end
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("PBMT PMEM exact AR visible", lsu_axi_arvalid, 1'b1);
      tb_check64("PBMT PMEM exact AR address", lsu_axi_araddr, DATA_PA);
      tick();
      mem0_device_release = 1'b0;
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = returned_data;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("PBMT PMEM exact response valid", mem0_rsp_valid, 1'b1);
      tb_check64("PBMT PMEM exact response data", mem0_rsp_rdata,
                 returned_data);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      $display("[R4-S0-PBMT-PMEM] pbmt=%0d hot-line bypass + exact owner PASS", pbmt);
    end
  endtask

  // HW-managed A/D（Svadu，对齐 NEMU）：leaf 真权限过但 A=0(任意)/D=0(store) 不再 page fault，
  // 而是经 S_AD_UPDATE 写回 leaf PTE 置 A(D) 位、填 TLB 后续原访问：
  //   A=0 load  → 写 PTE|A → load miss 续 S_READ_ADDR(data AR) → 返回数据；
  //   D=0 store → 写 PTE|A|D → 续 S_WRITE_REQ(store AW/W→DATA_PA→B) 后完成。
  // 两情形置位后 PTE 均 == SUPERPAGE_PTE(A=1,D=1)。
  task automatic sv39_leaf_ad_update;
    input [1023:0] what;
    input write_access;
    input [`XLEN-1:0] leaf_flags;
    reg [`XLEN-1:0] orig_pte;
    reg [`XLEN-1:0] ad_pte;
    begin
      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
      ad_pte = orig_pte | 64'h40 | (write_access ? 64'h80 : 64'h0);
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = write_access;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wdata = 64'haaaa_bbbb_cccc_dddd;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1(what, mem0_req_ready, 1'b1);
      tb_check1("sv39 A/D update request no direct AXI", lsu_axi_arvalid,
                1'b0);
      tick();
      mem0_req_valid = 1'b0;

      #1;
      tb_check1("sv39 A/D update advance no AR yet", lsu_axi_arvalid, 1'b0);
      tick();

      #1;
      tb_check1("sv39 A/D update walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 A/D update walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 A/D update waits PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = orig_pte;
      #1;
      tb_check1("T4C A/D-needed walk keeps payload owner",
                dut.walk_lookup_payload_owner_w, 1'b1);
      tb_check1("T4C A/D-needed walk suppresses lookup",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check64("T4C A/D-needed walk selects leaf PA",
                 dut.dcache_lookup_addr_w, dut.walk_leaf_paddr_w);
      tick();
      lsu_axi_rvalid = 1'b0;

      // S_AD_UPDATE：写回置位 PTE 到 leaf PTE 物理地址（全 8B），非 fault。
      #1;
      tb_check1("sv39 A/D update issues AW", lsu_axi_awvalid, 1'b1);
      tb_check1("sv39 A/D update issues W", lsu_axi_wvalid, 1'b1);
      tb_check64("sv39 A/D update write PTE address", lsu_axi_awaddr,
                 ROOT_PT + 64'd16);
      tb_check64("sv39 A/D update write PTE data", lsu_axi_wdata, ad_pte);
      tb_check1("sv39 A/D update write full strb", &lsu_axi_wstrb, 1'b1);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = 2'b00;
      tick();
      lsu_axi_bvalid = 1'b0;

      if (write_access) begin
        // 续 store：AW/W 到 DATA_PA（store 数据），等聚合 B 后报完成。
        #1;
        tb_check1("sv39 A/D update store issues AW", lsu_axi_awvalid, 1'b1);
        tb_check64("sv39 A/D update store AW address", lsu_axi_awaddr,
                   DATA_PA_AD);
        tb_check64("sv39 A/D update store W data", lsu_axi_wdata,
                   64'haaaa_bbbb_cccc_dddd);
        lsu_axi_awready = 1'b1;
        lsu_axi_wready = 1'b1;
        tick();
        lsu_axi_awready = 1'b0;
        lsu_axi_wready = 1'b0;
        #1;
        tb_check1("sv39 A/D update store waits B", lsu_axi_bready, 1'b1);
        tb_check1("sv39 A/D update store no pre-B response", mem0_rsp_valid,
                  1'b0);
        lsu_axi_bvalid = 1'b1;
        tick();
        lsu_axi_bvalid = 1'b0;
        #1;
        tb_check1("sv39 A/D update store response valid", mem0_rsp_valid,
                  1'b1);
        tb_check1("sv39 A/D update store no error", mem0_rsp_error, 1'b0);
        tb_check1("sv39 A/D update store no page fault", mem0_rsp_page_fault,
                  1'b0);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
      end else begin
        // 续 load miss：S_READ_ADDR → data AR(DATA_PA) → R → 返回数据。
        #1;
        tb_check1("sv39 A/D update load issues data AR", lsu_axi_arvalid,
                  1'b1);
        tb_check64("sv39 A/D update load data AR address", lsu_axi_araddr,
                   DATA_PA_AD);
        lsu_axi_arready = 1'b1;
        tick();
        lsu_axi_arready = 1'b0;
        #1;
        tb_check1("sv39 A/D update load waits R", lsu_axi_rready, 1'b1);
        lsu_axi_rvalid = 1'b1;
        lsu_axi_rdata = 64'hfeed_face_cafe_beef;
        tick();
        lsu_axi_rvalid = 1'b0;
        #1;
        tb_check1("sv39 A/D update load response valid", mem0_rsp_valid, 1'b1);
        tb_check1("sv39 A/D update load no error", mem0_rsp_error, 1'b0);
        tb_check64("sv39 A/D update load response data", mem0_rsp_rdata,
                   64'hfeed_face_cafe_beef);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
      end

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
    end
  endtask

  // T4F：PTE 地址所在 TOR 区域 R-only，最终 data PA 由后续 allow-all
  // entry 放行。A/D-needed leaf 必须形成原 load/store 的 access fault，
  // 不进入 S_AD_UPDATE、不发 AW/W。参数化覆盖 load-A 与 store-D 两类。
  task automatic sv39_ad_write_pmp_deny;
    input [1023:0] what;
    input write_access;
    input [`XLEN-1:0] leaf_flags;
    reg [`XLEN-1:0] orig_pte;
    begin
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      orig_pte = (SUPERPAGE_PPN << 10) | leaf_flags;
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      // entry0: TOR [0,0x8000_8000), R-only；entry1: NAPOT all, RWX。
      pmpcfg[0 +: 8] = 8'h09;
      pmpcfg[8 +: 8] = 8'h1f;
      pmpaddr[0 +: `XLEN] = 64'h0000_0000_8000_8000 >> 2;
      pmpaddr[`XLEN +: `XLEN] = {`XLEN{1'b1}};
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = write_access;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wdata = 64'h1234_5678_9abc_def0;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b0;
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1(what, mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("T4F LSU PTE read remains allowed", lsu_axi_arvalid, 1'b1);
      tb_check64("T4F LSU PTE read address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("T4F LSU waits leaf PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rdata = orig_pte;
      lsu_axi_rresp = 2'b00;
      lsu_axi_rvalid = 1'b1;
      #1;
      tb_check1("T4F LSU final data PMP remains allowed",
                dut.walk_leaf_pmp_fault_w, 1'b0);
      tb_check1("T4F LSU PTE WRITE PMP denies",
                dut.walk_pte_write_pmp_fault_w, 1'b1);
      tb_check1("T4F LSU deny event qualified", dut.walk_ad_write_deny_w,
                1'b1);
      tb_check1("T4F LSU denied PTE emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4F LSU denied PTE emits no W", lsu_axi_wvalid, 1'b0);
      tick();
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4F LSU deny returns response", mem0_rsp_valid, 1'b1);
      tb_check1("T4F LSU deny is access fault", mem0_rsp_error, 1'b1);
      tb_check1("T4F LSU deny is not page fault", mem0_rsp_page_fault, 1'b0);
      tb_check1("T4F LSU response still has no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4F LSU response still has no W", lsu_axi_wvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      $display("[T4F-LSU-PTW-PMP-WRITE] op=%0s read=allow write=deny access-fault aw=0 w=0",
               write_access ? "store" : "load");
    end
  endtask

  // 【LSQ·SQ 切换】probe: write 探测走完翻译+PMP 后不写内存, PA 经 rsp_rdata 回传。
  task automatic probe_write_returns_pa;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = DATA_PA;
      mem0_req_wdata = 64'hdead_beef_0123_4567;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("probe request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      #1;
      // 【刀 M】probe 短路判定在 advance 拍完成, rsp 次拍可见。
      tb_check1("probe advance no response yet", mem0_rsp_valid, 1'b0);
      tick();
      #1;
      tb_check1("probe response valid", mem0_rsp_valid, 1'b1);
      tb_check1("probe no error", mem0_rsp_error, 1'b0);
      tb_check1("probe no page fault", mem0_rsp_page_fault, 1'b0);
      tb_check64("probe returns PA in rdata", mem0_rsp_rdata, DATA_PA);
      tb_check1("probe does not issue AW", lsu_axi_awvalid, 1'b0);
      tb_check1("probe does not issue W", lsu_axi_wvalid, 1'b0);
      tb_check1("probe does not issue AR", lsu_axi_arvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // T4H / MEM-PMA-G1：M-mode PMP no-match allow 不能授权 default/stub PA。
  // probe 必须在 ROB 完成前返回 access fault，且不能向 xbar 呈现任何 data channel。
  task automatic probe_write_pma_deny_bare;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = 64'h0000_0000_1800_0000;
      mem0_req_wdata = 64'h55aa_aa55_1234_5678;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("T4H bare PMA request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      #1;
      tb_check1("T4H bare PMA deny qualified",
                dut.req_data_pma_fault_w, 1'b1);
      tb_check1("T4H bare PMA advance emits no AR", lsu_axi_arvalid, 1'b0);
      tb_check1("T4H bare PMA advance emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4H bare PMA advance emits no W", lsu_axi_wvalid, 1'b0);
      tick();
      #1;
      tb_check1("T4H bare PMA response valid", mem0_rsp_valid, 1'b1);
      tb_check1("T4H bare PMA is access fault", mem0_rsp_error, 1'b1);
      tb_check1("T4H bare PMA is not page fault",
                mem0_rsp_page_fault, 1'b0);
      tb_check1("T4H bare PMA response emits no AR", lsu_axi_arvalid, 1'b0);
      tb_check1("T4H bare PMA response emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4H bare PMA response emits no W", lsu_axi_wvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      $display("[T4H-PMA-BARE-PROBE] default PA rejected before AW/W with access fault");
    end
  endtask

  // Sv39 leaf 可通过权限/PMP、却把最终 data PA 指向当前 NpcTop stub window。
  // PMA deny 必须先于 A/D/data side effect，并沿原 store probe fault ABI 返回。
  task automatic probe_write_pma_deny_sv39_leaf;
    begin
      clear_inputs();
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = PMA_BAD_VA;
      mem0_req_wdata = 64'h0123_4567_89ab_cdef;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("T4H Sv39 PMA request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      tick();
      #1;
      tb_check1("T4H Sv39 PMA walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("T4H Sv39 PMA root PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd8);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = PMA_BAD_SUPERPAGE_PTE;
      #1;
      tb_check64("T4H Sv39 PMA leaf physical address",
                 dut.walk_leaf_paddr_w, PMA_BAD_PA);
      tb_check1("T4H Sv39 PMA leaf deny qualified",
                dut.walk_leaf_pma_fault_w, 1'b1);
      tb_check1("T4H Sv39 PMA leaf emits no data AR",
                lsu_axi_arvalid, 1'b0);
      tb_check1("T4H Sv39 PMA leaf emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4H Sv39 PMA leaf emits no W", lsu_axi_wvalid, 1'b0);
      tick();
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4H Sv39 PMA response valid", mem0_rsp_valid, 1'b1);
      tb_check1("T4H Sv39 PMA is access fault", mem0_rsp_error, 1'b1);
      tb_check1("T4H Sv39 PMA is not page fault",
                mem0_rsp_page_fault, 1'b0);
      tb_check1("T4H Sv39 PMA response emits no AW", lsu_axi_awvalid, 1'b0);
      tb_check1("T4H Sv39 PMA response emits no W", lsu_axi_wvalid, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      $display("[T4H-PMA-SV39-PROBE] leaf-to-stub PA rejected before A/D/data side effects");
    end
  endtask

  // 【LSQ·SQ 切换×刀 M】pretrans+nokill(退休 store 落存): 跳过翻译直写 PA, 且
  // flush 期间事务照常推进(写必达)——寄存站项 flush 拍经 nokill 豁免照常
  // advance 进 FSM, 响应不被 kill 压制。
  task automatic pretrans_nokill_store_survives_flush;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_attr_valid = 1'b1;
      mem0_req_class = `OOO_MEM_CLASS_CACHED;
      mem0_req_cacheable = 1'b1;
      mem0_req_addr = DATA_PA;
      mem0_req_wdata = 64'h1122_3344_5566_7788;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("pretrans request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_attr_valid = 1'b0;
      mem0_req_class = `OOO_MEM_CLASS_RSVD;
      mem0_req_cacheable = 1'b0;
      // 立刻 flush: 站内 nokill 项必须在 flush 拍照常 advance 进 FSM(写必达)
      flush = 1'b1;
      #1;
      tb_check1("nokill staged item advances under flush",
                dut.stage_advance_w, 1'b1);
      tb_check1("nokill advance cycle no AW yet", lsu_axi_awvalid, 1'b0);
      tick();
      #1;
      tb_check1("nokill write still issues AW under flush",
                lsu_axi_awvalid, 1'b1);
      tb_check1("nokill write still issues W under flush",
                lsu_axi_wvalid, 1'b1);
      tb_check64("nokill write AW address", lsu_axi_awaddr, DATA_PA);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      // nokill store 在 flush 下仍等待并接收聚合 B。
      tb_check1("nokill waits B under flush", lsu_axi_bready, 1'b1);
      tb_check1("nokill has no pre-B response under flush", mem0_rsp_valid,
                1'b0);
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("nokill response valid under flush", mem0_rsp_valid, 1'b1);
      tb_check1("nokill response no error", mem0_rsp_error, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      flush = 1'b0;
      tick();
    end
  endtask

  // T4N bridge half of the precise terminal ABI.  All legal B outcomes produce
  // exactly one held response; OKAY maps error=0, while SLVERR and DECERR both
  // map error=1 for the backend's cause-7/tval-VA terminal WB.
  task automatic pretrans_bresp_terminal_case;
    input [1023:0] label;
    input [`XLEN-1:0] pa;
    input [1:0] bresp;
    input exp_error;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_attr_valid = 1'b1;
      mem0_req_class = `OOO_MEM_CLASS_CACHED;
      mem0_req_cacheable = 1'b1;
      mem0_req_addr = pa;
      mem0_req_wdata = 64'h55aa_1122_3344_7788;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1({label, " request ready"}, mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_attr_valid = 1'b0;
      mem0_req_class = `OOO_MEM_CLASS_RSVD;
      mem0_req_cacheable = 1'b0;
      #1;
      tick();
      #1;
      tb_check1({label, " AW valid"}, lsu_axi_awvalid, 1'b1);
      tb_check1({label, " W valid"}, lsu_axi_wvalid, 1'b1);
      tb_check64({label, " physical AW address"}, lsu_axi_awaddr, pa);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1({label, " waits B"}, lsu_axi_bready, 1'b1);
      tb_check1({label, " no pre-B response"}, mem0_rsp_valid, 1'b0);
      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = bresp;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1({label, " response valid"}, mem0_rsp_valid, 1'b1);
      tb_check1({label, " response error mapping"},
                mem0_rsp_error, exp_error);
      tb_check1({label, " response is not page fault"},
                mem0_rsp_page_fault, 1'b0);
      // B is a post-target terminal: the public typed response must echo the
      // SQ drain provenance, including errors, instead of poisoning it like a
      // pre-target translation/PMP/PMA fault.
      tb_check1({label, " response typed attr valid"},
                mem0_rsp_attr_valid, 1'b1);
      tb_check32({label, " response typed class retained"},
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_CACHED});
      tb_check1({label, " response cacheability retained"},
                mem0_rsp_cacheable, 1'b1);
      // Backend WB credit can stall ready.  The bridge must retain the one
      // terminal and all public typed provenance rather than consume/recreate
      // or reclassify it.
      tick();
      #1;
      tb_check1({label, " response held under credit stall"},
                mem0_rsp_valid, 1'b1);
      tb_check1({label, " held error stable"}, mem0_rsp_error, exp_error);
      tb_check1({label, " held typed attr stable"},
                mem0_rsp_attr_valid, 1'b1);
      tb_check32({label, " held typed class stable"},
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_CACHED});
      tb_check1({label, " held cacheability stable"},
                mem0_rsp_cacheable, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check1({label, " response consumed exactly once"},
                mem0_rsp_valid, 1'b0);
      $display("[S1-PRETRANS-BRESP-ATTR-HOLD] %0s error=%0d typed provenance retained PASS",
               label, exp_error);
    end
  endtask

  // 【刀 M·定向】寄存站 skid 保持(PSR-HOLD 型)与 flush 语义:
  //   (a) FSM 忙(等 R)期间 ready=1——plain load 提前进站排队并字段冻结
  //       (BRG-STG-HOLD 断言同拍在跑), 站满后 ready=0(单深度), flush 把未发射
  //       的 plain 项当拍清除(比现状更早止损: 全程不发任何 lookup/AR/rsp);
  //   (b) nokill(pretrans drain 落存)项 flush 拍原地存活(BRG-STG-NOKILL),
  //       flush 解除后照常 advance 完成写(写必达)。
  task automatic stage_skid_hold_and_flush_semantics;
    begin
      clear_inputs();
      tick();
      // (a) 底座: 慢读 A(miss, 不给 R)占住 FSM
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_8000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("skid base read ready", mem0_req_ready, 1'b1);
      tick();
      // A advance 拍立刻换上第二个 load B: back-to-back 进站
      mem0_req_addr = 64'h0000_0000_8000_8100;
      #1;
      tb_check1("skid back-to-back ready during advance",
                mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      // A 判决拍(miss→AR); B 在站保持: FSM 忙 → advance=0, 单深度 → ready=0
      tb_check1("skid holds while busy (no advance)",
                dut.stage_advance_w, 1'b0);
      tb_check1("skid full blocks ready", mem0_req_ready, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      // A 等 R; B 字段冻结检查(BRG-STG-HOLD 的 TB 对照)
      tb_check1("skid staged item persists", dut.stg_valid_q, 1'b1);
      tb_check64("skid staged addr frozen", dut.stg_addr_q,
                 64'h0000_0000_8000_8100);
      // flush: FSM 的 A 走读 abort(本地释放), 站内 plain B 被当拍清除
      flush = 1'b1;
      tick();
      flush = 1'b0;
      #1;
      tb_check1("flush clears staged plain load", dut.stg_valid_q, 1'b0);
      tb_check1("flushed staged load never ARs", lsu_axi_arvalid, 1'b0);
      tb_check1("bridge ready after skid flush", mem0_req_ready, 1'b1);
      tick();
      #1;
      tb_check1("no ghost AR after skid flush", lsu_axi_arvalid, 1'b0);
      tb_check1("no ghost response after skid flush", mem0_rsp_valid, 1'b0);
      // 【AXI4 化 S1】A 的残 R 排水(新契约: 桥自吞, 不再依赖 xbar abort)
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("skid flush drained back to idle", mem0_req_ready, 1'b1);

      // (b) nokill 项 flush 拍存活: 慢读 C 占 FSM, drain(nokill)进站, flush
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_8200;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      lsu_axi_arready = 1'b1;
      #1;
      tb_check1("nokill-hold base read ready", mem0_req_ready, 1'b1);
      tick();
      // C advance 拍换上 drain 落存(pretrans+nokill write)进站
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_attr_valid = 1'b1;
      mem0_req_class = `OOO_MEM_CLASS_CACHED;
      mem0_req_cacheable = 1'b1;
      mem0_req_addr = 64'h0000_0000_8000_8300;
      mem0_req_wdata = 64'hc001_c0de_0000_ffff;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("nokill-hold drain enters stage", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      mem0_req_write = 1'b0;
      mem0_req_attr_valid = 1'b0;
      mem0_req_class = `OOO_MEM_CLASS_RSVD;
      mem0_req_cacheable = 1'b0;
      #1;
      tick();   // C 判决拍 miss→AR fire→S_READ_DATA
      lsu_axi_arready = 1'b0;
      // flush 拍: C(S_READ_DATA)本地释放; 站内 nokill 项不得被清除
      flush = 1'b1;
      #1;
      tb_check1("nokill staged survives flush cycle", dut.stg_valid_q, 1'b1);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("nokill staged still valid after flush",
                dut.stg_valid_q, 1'b1);
      // 【AXI4 化 S1】C 的残 R 先排水(drop_rsp_q 持械), 排完 nokill 才 advance
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("nokill staged advances after drain",
                dut.stage_advance_w, 1'b1);
      tick();
      #1;
      tb_check1("nokill staged store issues AW", lsu_axi_awvalid, 1'b1);
      tb_check64("nokill staged store AW address", lsu_axi_awaddr,
                 64'h0000_0000_8000_8300);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("nokill staged store waits B", lsu_axi_bready, 1'b1);
      tb_check1("nokill staged store has no pre-B response", mem0_rsp_valid,
                1'b0);
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("nokill staged store response valid", mem0_rsp_valid, 1'b1);
      tb_check1("nokill staged store no error", mem0_rsp_error, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      // 再空转一拍越过 RMW 判决拍。
      tick();
    end
  endtask

  // ===== 刀D 融合拍定向用例(load hit 流 1 拍/load 契约) =====
  // 【时序 T2】融合谓词已 tie-0(链头退回 FF), FUSION_EN=0 跳过融合契约用例;
  // 将来重新使能融合时改回 1。(c)(d) 的 flush 关断/miss 拍禁 advance 两用例
  // 与 tie-0 兼容, 保持常开。
  localparam FUSION_EN = 1'b1;
  task automatic dcache_hit_fusion_cases;
    begin
      if (FUSION_EN) begin
      // (a) 融合拍 back-to-back: 两个 hit load 连发, 稳态 1 拍/load
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;   // 陷阱: 全程不得发 AR
      #1;
      tb_check1("fusion load1 ready", mem0_req_ready, 1'b1);
      tick();                    // fire load1 进寄存站
      #1;
      tb_check1("fusion load1 advance lookup", dut.req_read_lookup_fire_w,
                1'b1);
      tick();                    // advance: load1 发 lookup, load2 fire 进站
      #1;
      // 判决拍=融合拍: load1 rsp 组合交付, 同拍 advance load2 发 lookup
      tb_check1("fusion beat rsp valid (1-cycle hit)", mem0_rsp_valid, 1'b1);
      tb_check64("fusion beat rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      tb_check1("fusion beat advances next", dut.stage_advance_w, 1'b1);
      tb_check1("fusion beat next lookup fires", dut.req_read_lookup_fire_w,
                1'b1);
      tick();                    // 融合拍结束: load2 进判决拍
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("fusion back-to-back second rsp", mem0_rsp_valid, 1'b1);
      tb_check64("fusion second rdata", mem0_rsp_rdata,
                 64'h0102_0304_0506_0708);
      tb_check1("fusion no AR throughout", lsu_axi_arvalid, 1'b0);
      tick();                    // load2 消费, 站空回 IDLE
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("fusion drain back to ready", mem0_req_ready, 1'b1);

      // (b) rsp 反压: hit 拍 rsp_ready=0 → 组合 rsp 不消费, 落寄存 S_RESP(skid)
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b0;
      #1;
      tick();                    // fire
      mem0_req_valid = 1'b0;
      #1;
      tick();                    // advance 发 lookup
      #1;
      tb_check1("stalled hit rsp valid", mem0_rsp_valid, 1'b1);
      tick();                    // 落寄存进 S_RESP
      #1;
      tb_check1("skid holds rsp", mem0_rsp_valid, 1'b1);
      tb_check64("skid holds rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      mem0_rsp_ready = 1'b1;
      tick();                    // 消费
      mem0_rsp_ready = 1'b0;

      end  // FUSION_EN (a)(b)

      // (d) miss 拍禁 advance: miss load 判决拍时站中已有下一项——advance 必须
      // 等 S_RESP 消费拍(mutation 杀手: advance 放宽到 miss 拍会覆写 paddr_q,
      // AR 地址错/事务丢失)
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_4000;  // 冷地址(miss), 与 0x8000_1000 不同 index
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      lsu_axi_arready = 1'b1;
      #1;
      tick();                    // fire miss-load 进寄存站
      mem0_req_addr = 64'h0000_0000_8000_1000;  // 下一项(hit 地址)排队
      #1;
      tick();                    // advance: miss-load 发 lookup, 下一项 fire 进站
      mem0_req_valid = 1'b0;
      #1;
      // miss 判决拍: 站有项但不得 advance(否则 paddr_q 被覆写)
      tb_check1("miss beat no advance", dut.stage_advance_w, 1'b0);
      tb_check1("miss beat no rsp", mem0_rsp_valid, 1'b0);
      tb_check1("miss beat AR fires", lsu_axi_arvalid, 1'b1);
      tb_check64("miss beat AR addr intact", lsu_axi_araddr,
                 64'h0000_0000_8000_4000);
      tick();                    // AR 握手 → S_READ_DATA
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hdead_beef_0000_4000;
      lsu_axi_rresp = 2'b00;
      #1;
      tick();                    // R beat → fill+S_RESP
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("miss resolved rsp", mem0_rsp_valid, 1'b1);
      tb_check64("miss resolved rdata", mem0_rsp_rdata,
                 64'hdead_beef_0000_4000);
      tick();                    // S_RESP 消费拍: 同拍 advance 下一项(hit)发 lookup
      #1;                        // 下一项判决拍
      if (FUSION_EN) begin
        tb_check1("queued hit rsp after miss", mem0_rsp_valid, 1'b1);
        tb_check64("queued hit rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      end else begin
        tick();                  // T2: 落寄存, S_RESP 拍交付
        #1;
        tb_check1("queued hit rsp after miss", mem0_rsp_valid, 1'b1);
        tb_check64("queued hit rdata", mem0_rsp_rdata, 64'h0102_0304_0506_0708);
      end
      tick();
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;
      #1;

      // (c) flush(kill)拍融合关断: 判决拍撞 flush → 谓词含 !cpu_kill,
      // rsp 不得组合交付(p42 型污染防线), flush 分支释放 S_LOOKUP
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_1000;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      mem0_rsp_ready = 1'b1;
      #1;
      tick();                    // fire
      mem0_req_valid = 1'b0;
      #1;
      tick();                    // advance 发 lookup
      flush = 1'b1;
      #1;
      tb_check1("flush beat masks fusion rsp", mem0_rsp_valid, 1'b0);
      tick();                    // flush 分支释放 S_LOOKUP
      flush = 1'b0;
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check1("flush drained back to ready", mem0_req_ready, 1'b1);
    end
  endtask

  // S1 strict authorization: seed a hot line, then PMP-deny the exact same
  // address.  Even a potential hit must not issue a raw SRAM lookup.
  task automatic speculative_cache_hit_cannot_bypass_pmp;
    // Keep this line cold with respect to the preceding window/fusion cases;
    // 0x8000_6000 is intentionally populated earlier with different data.
    localparam [`XLEN-1:0] SPEC_DENY_ADDR = 64'h0000_0000_8000_9000;
    localparam [`XLEN-1:0] SPEC_DENY_DATA = 64'h5a5a_c3c3_9696_0f0f;
    begin
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      mem0_rsp_ready = 1'b0;

      issue_mem0_read(SPEC_DENY_ADDR);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SPEC_DENY_DATA;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("spec PMP seed accepts AXI R", lsu_axi_rready, 1'b1);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("spec PMP seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("spec PMP seed response data", mem0_rsp_rdata,
                 SPEC_DENY_DATA);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      priv_mode = `PRIV_S;
      // Entry0 NAPOT spans the full address space but grants no R/W/X.
      pmpcfg = {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h18};
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = SPEC_DENY_ADDR;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("spec PMP denied request enters station", mem0_req_ready,
                1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec PMP denied read issues no internal lookup",
                dut.req_read_lookup_issue_w, 1'b0);
      tb_check1("spec PMP denied read is not authorized",
                dut.req_read_lookup_fire_w, 1'b0);
      tb_check1("spec PMP denied macro enable is low",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check1("spec PMP denied read has no AXI AR", lsu_axi_arvalid,
                1'b0);
      tick();
      #1;
      tb_check1("spec PMP denied hit cannot fuse",
                dut.lookup_hit_fusion_w, 1'b0);
      tb_check1("spec PMP denied response valid", mem0_rsp_valid, 1'b1);
      tb_check1("spec PMP denied response is access fault",
                mem0_rsp_error, 1'b1);
      tb_check1("spec PMP denied response is not page fault",
                mem0_rsp_page_fault, 1'b0);
      tb_check1("spec PMP denied response attr invalid",
                mem0_rsp_attr_valid, 1'b0);
      tb_check32("spec PMP denied response class poison",
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("spec PMP denied response still has no AXI AR",
                lsu_axi_arvalid, 1'b0);
      $display("[S1-DCACHE-NO-PREVIEW-PMP] hot-line potential, lookup_en=0 access_fault=1");

      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      priv_mode = `PRIV_M;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
    end
  endtask

  // T3W: 先用 SUM=1 的 S-mode walk 建立 user-page DTLB 项，并让翻译后的
  // 物理行保持 hot；随后仅清 SUM。相同 DTLB context 此时必须命中旧 PTE 但
  // 由权限检查产生 page fault，投机 SRAM hit 不能融合、不能发 data AR，也
  // 不能改变 cache 内容。
  task automatic speculative_cache_hit_cannot_bypass_dtlb_permission;
    begin
      // 先以 bare M-mode 填入物理 cache 行，后续允许的 page walk 应直接命中。
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      issue_mem0_read(SPEC_USER_PA);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SPEC_USER_DATA;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("spec DTLB seed response valid", mem0_rsp_valid, 1'b1);
      tb_check64("spec DTLB seed response data", mem0_rsp_rdata,
                 SPEC_USER_DATA);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // SUM=1 允许 S-mode 访问 U=1 leaf，完成真实 walk + DTLB fill；物理
      // 行已 hot，因此 leaf 后只能走 internal hit，不能出现 data AR。
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      priv_mode = `PRIV_S;
      mstatus = `MSTATUS_SUM;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = SPEC_USER_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("spec DTLB fill request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec DTLB fill advance no AR", lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("spec DTLB fill walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("spec DTLB fill walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("spec DTLB fill waits PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = SPEC_USER_SUPERPAGE_PTE;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("spec DTLB fill leaf hits hot line",
                dut.dcache_lookup_hit_w, 1'b1);
      tb_check1("spec DTLB fill leaf has no data AR", lsu_axi_arvalid,
                1'b0);
      tick();
      #1;
      tb_check1("spec DTLB fill response valid", mem0_rsp_valid, 1'b1);
      tb_check64("spec DTLB fill response data", mem0_rsp_rdata,
                 SPEC_USER_DATA);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // 同一 TLB 项在 SUM=0 下必须成为 permission fault；给 AR ready 置 1
      // 作为陷阱，确保既不会把 internal hit 当 data response，也不会发总线读。
      mstatus = {`XLEN{1'b0}};
      lsu_axi_arready = 1'b1;
      mem0_req_valid = 1'b1;
      mem0_req_addr = SPEC_USER_VA;
      #1;
      tb_check1("spec DTLB denied request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec DTLB denied context hit",
                dut.req_dtlb_context_hit_w, 1'b1);
      tb_check1("spec DTLB denied permission fault",
                dut.req_dtlb_perm_fault_w, 1'b1);
      tb_check1("spec DTLB denied issues no internal lookup",
                dut.req_read_lookup_issue_w, 1'b0);
      tb_check1("spec DTLB denied lookup is not authorized",
                dut.req_read_lookup_fire_w, 1'b0);
      tb_check1("spec DTLB denied macro enable is low",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check64("spec DTLB denied lookup keeps translated PA",
                 dut.dcache_lookup_addr_w, SPEC_USER_PA);
      tb_check1("spec DTLB denied advance has no data AR", lsu_axi_arvalid,
                1'b0);
      tick();
      #1;
      tb_check1("spec DTLB denied hit cannot fuse",
                dut.lookup_hit_fusion_w, 1'b0);
      tb_check1("spec DTLB denied response valid", mem0_rsp_valid, 1'b1);
      tb_check1("spec DTLB denied response error", mem0_rsp_error, 1'b1);
      tb_check1("spec DTLB denied response is page fault",
                mem0_rsp_page_fault, 1'b1);
      tb_check1("spec DTLB denied response attr invalid",
                mem0_rsp_attr_valid, 1'b0);
      tb_check32("spec DTLB denied response class poison",
                 {30'b0, mem0_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("spec DTLB denied response has no data AR", lsu_axi_arvalid,
                1'b0);
      tb_check1("spec DTLB denied response has no write side effect",
                lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      $display("[S1-DCACHE-NO-PREVIEW-DTLB-PERM] hot-line potential, lookup_en=0 page_fault=1");
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      lsu_axi_arready = 1'b0;

      // 恢复 SUM 后同一 DTLB/物理 cache 行仍须直接命中原数据，证明 fault
      // 期间的 speculative SRAM read 没有更新、失效或污染 cache。
      mstatus = `MSTATUS_SUM;
      lsu_axi_arready = 1'b1;
      mem0_req_valid = 1'b1;
      mem0_req_addr = SPEC_USER_VA;
      #1;
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec DTLB post-fault authorized lookup",
                dut.req_read_lookup_fire_w, 1'b1);
      tb_check1("spec DTLB post-fault advance no AR", lsu_axi_arvalid,
                1'b0);
      tick();
      #1;
      tb_check1("spec DTLB post-fault cache hit",
                dut.dcache_lookup_hit_w, 1'b1);
      tb_check1("spec DTLB post-fault response valid", mem0_rsp_valid,
                1'b1);
      tb_check64("spec DTLB post-fault cache data unchanged",
                 mem0_rsp_rdata, SPEC_USER_DATA);
      tb_check1("spec DTLB post-fault still has no AR", lsu_axi_arvalid,
                1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("spec DTLB post-fault held response valid", mem0_rsp_valid,
                1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
    end
  endtask

  // T3W: mmu_flush 只清 TLB valid，旧 PTE payload 仍可能让 speculative
  // candidate 恰好指向 hot cache 行。context miss 必须由 page-walk owner 接管；
  // 这里让 walk 返回 invalid PTE，精确验证 internal hit 不能伪造 data response。
  task automatic speculative_stale_tlb_candidate_cannot_bypass_walk;
    begin
      priv_mode = `PRIV_S;
      mstatus = `MSTATUS_SUM;
      satp = (64'h8 << 60) | ROOT_PPN;
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = SPEC_USER_VA;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("spec stale TLB request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec stale TLB context misses",
                dut.req_dtlb_context_hit_w, 1'b0);
      tb_check1("spec stale TLB issues no internal lookup",
                dut.req_read_lookup_issue_w, 1'b0);
      tb_check1("spec stale TLB lookup is not authorized",
                dut.req_read_lookup_fire_w, 1'b0);
      tb_check1("spec stale TLB macro enable is low",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check64("spec stale TLB candidate aliases hot PA",
                 dut.dcache_lookup_addr_w, SPEC_USER_PA);
      tb_check1("spec stale TLB advance has no AR", lsu_axi_arvalid,
                1'b0);
      tick();
      #1;
      tb_check1("spec stale TLB hit cannot fuse",
                dut.lookup_hit_fusion_w, 1'b0);
      tb_check1("spec stale TLB walk AR owns channel", lsu_axi_arvalid,
                1'b1);
      tb_check64("spec stale TLB walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      tb_check64("spec stale TLB walk AR size",
                 {{(`XLEN-3){1'b0}}, lsu_axi_arsize},
                 {{(`XLEN-3){1'b0}}, 3'd3});
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      tb_check1("spec stale TLB walk waits PTE", lsu_axi_rready, 1'b1);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = {`XLEN{1'b0}};
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("T4C invalid PTE keeps walk payload owner",
                dut.walk_lookup_payload_owner_w, 1'b1);
      tb_check1("T4C invalid PTE suppresses lookup",
                dut.dcache_lookup_en_w, 1'b0);
      tb_check64("T4C invalid PTE still selects leaf payload",
                 dut.dcache_lookup_addr_w, dut.walk_leaf_paddr_w);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("spec stale TLB invalid PTE response valid",
                mem0_rsp_valid, 1'b1);
      tb_check1("spec stale TLB invalid PTE response error",
                mem0_rsp_error, 1'b1);
      tb_check1("spec stale TLB invalid PTE is page fault",
                mem0_rsp_page_fault, 1'b1);
      tb_check64("spec stale TLB hit data never becomes response",
                 mem0_rsp_rdata, {`XLEN{1'b0}});
      tb_check1("spec stale TLB fault has no second data AR",
                lsu_axi_arvalid, 1'b0);
      tb_check1("spec stale TLB fault has no write side effect",
                lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      $display("[S1-DCACHE-NO-PREVIEW-TLB-MISS] lookup_en=0 walk_owner=1 page_fault=1");
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;

      // bare 物理回读必须仍命中原数据；若 miss/fault 路错误地把 speculative
      // result 当成 fill/store owner，这个检查会暴露 cache 状态污染。
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      lsu_axi_arready = 1'b1;
      mem0_req_valid = 1'b1;
      mem0_req_addr = SPEC_USER_PA;
      #1;
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("spec stale TLB post-fault physical lookup authorized",
                dut.req_read_lookup_fire_w, 1'b1);
      tb_check1("spec stale TLB post-fault physical advance no AR",
                lsu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("spec stale TLB post-fault physical cache hit",
                dut.dcache_lookup_hit_w, 1'b1);
      tb_check1("spec stale TLB post-fault physical response valid",
                mem0_rsp_valid, 1'b1);
      tb_check64("spec stale TLB post-fault cache data unchanged",
                 mem0_rsp_rdata, SPEC_USER_DATA);
      tb_check1("spec stale TLB post-fault physical no AR",
                lsu_axi_arvalid, 1'b0);
      tick();
      lsu_axi_arready = 1'b0;
      #1;
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
    end
  endtask

  // S2-G1: once either write channel presents VALID, flush may not revoke it.
  // Parameter 0 stalls both, 1 stalls AW only, 2 stalls W only for a full beat.
  task automatic s2_g1_write_valid_hold_case;
    input integer mode;
    reg [4:0] token;
    reg [`XLEN-1:0] addr;
    reg [`XLEN-1:0] held_awaddr;
    reg [`XLEN-1:0] held_wdata;
    reg [`STRB_W-1:0] held_wstrb;
    begin
      clear_inputs();
      tick();
      addr = 64'h0000_0000_8000_9000 + (mode * 64'h20);
      token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = addr;
      mem0_req_wdata = 64'h5100_0000_0000_0000 + mode;
      mem0_req_wstrb = 8'h3c;
      #1;
      tb_check1("S2-G1 write-hold request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      lsu_axi_awready = (mode == 2);
      lsu_axi_wready = (mode == 1);
      tick();
      #1;
      tb_check1("S2-G1 write-hold AW presented", lsu_axi_awvalid, 1'b1);
      tb_check1("S2-G1 write-hold W presented", lsu_axi_wvalid, 1'b1);
      held_awaddr = lsu_axi_awaddr;
      held_wdata = lsu_axi_wdata;
      held_wstrb = lsu_axi_wstrb;
      tick();

      flush = 1'b1;
      #1;
      if (mode != 2) begin
        tb_check1("S2-G1 flush keeps stalled AWVALID", lsu_axi_awvalid, 1'b1);
        tb_check64("S2-G1 flush keeps AWADDR", lsu_axi_awaddr, held_awaddr);
      end else begin
        tb_check1("S2-G1 fired AW stays done", lsu_axi_awvalid, 1'b0);
      end
      if (mode != 1) begin
        tb_check1("S2-G1 flush keeps stalled WVALID", lsu_axi_wvalid, 1'b1);
        tb_check64("S2-G1 flush keeps WDATA", lsu_axi_wdata, held_wdata);
        if (lsu_axi_wstrb !== held_wstrb) begin
          $display("[CHECK-FAIL] S2-G1 flush changed WSTRB");
          tb_errors = tb_errors + 1;
        end
      end else begin
        tb_check1("S2-G1 fired W stays done", lsu_axi_wvalid, 1'b0);
      end
      tb_check1("S2-G1 no pre-B owner drop", mem0_drop0_valid, 1'b0);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("S2-G1 write-hold waits B", lsu_axi_bready, 1'b1);
      tb_check1("S2-G1 still no pre-B drop", mem0_drop0_valid, 1'b0);
      lsu_axi_bvalid = 1'b1;
      #1;
      tb_check1("S2-G1 B is unique drop terminal", mem0_drop0_valid, 1'b1);
      tb_check32("S2-G1 B drop token", {27'b0, mem0_drop0_owner_token},
                 {27'b0, token});
      tb_check32("S2-G1 B drop kind", {30'b0, mem0_drop0_owner_kind}, 32'd1);
      tb_check32("S2-G1 B drop epoch", {30'b0, mem0_drop0_mmu_epoch}, 32'd1);
      tb_check64("S2-G1 B drop tval", mem0_drop0_fault_tval, addr);
      tick();
      lsu_axi_bvalid = 1'b0;
      flush = 1'b0;
      #1;
      tb_check1("S2-G1 drop pulses exactly once", mem0_drop0_valid, 1'b0);
      tb_check1("S2-G1 killed write exposes no response", mem0_rsp_valid, 1'b0);
      $display("[S2-G1-BRG-AW-W-HOLD][PASS] mode=%0d token=%0d", mode, token);
    end
  endtask

  task automatic s2_g1_dual_drop_distinct_tuple;
    reg [4:0] active_token;
    reg [4:0] station_token;
    localparam [`XLEN-1:0] ACTIVE_ADDR = 64'h0000_0000_8000_9800;
    localparam [`XLEN-1:0] STATION_ADDR = 64'h0000_0000_8000_9880;
    begin
      clear_inputs();
      tick();
      active_token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = ACTIVE_ADDR;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      tick();
      #1;
      tb_check1("S2-G1 dual-drop active response held", mem0_rsp_valid, 1'b1);

      station_token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = STATION_ADDR;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      flush = 1'b1;
      #1;
      tb_check1("S2-G1 active drop present", mem0_drop0_valid, 1'b1);
      tb_check1("S2-G1 station drop present", mem0_drop1_valid, 1'b1);
      tb_check32("S2-G1 active drop token", {27'b0, mem0_drop0_owner_token},
                 {27'b0, active_token});
      tb_check32("S2-G1 station drop token", {27'b0, mem0_drop1_owner_token},
                 {27'b0, station_token});
      tb_check64("S2-G1 active drop tval", mem0_drop0_fault_tval, ACTIVE_ADDR);
      tb_check64("S2-G1 station drop tval", mem0_drop1_fault_tval, STATION_ADDR);
      tb_check1("S2-G1 active residency bit",
                mem0_owner_residency_mask[active_token], 1'b1);
      tb_check1("S2-G1 station residency bit",
                mem0_owner_residency_mask[station_token], 1'b1);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("S2-G1 dual active drop pulses once", mem0_drop0_valid, 1'b0);
      tb_check1("S2-G1 dual station drop pulses once", mem0_drop1_valid, 1'b0);
      $display("[S2-G1-BRG-DUAL-DROP][PASS] active=%0d station=%0d",
               active_token, station_token);
    end
  endtask

  task automatic s2_g1_rsp_flush_nokill_atomic_replace;
    reg [4:0] old_token;
    reg [4:0] new_token;
    localparam [`XLEN-1:0] OLD_ADDR = 64'h0000_0000_8000_9900;
    localparam [`XLEN-1:0] NEW_ADDR = 64'h0000_0000_8000_9980;
    begin
      clear_inputs();
      tick();
      old_token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_probe = 1'b1;
      mem0_req_addr = OLD_ADDR;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_probe = 1'b0;
      tick();
      #1;
      tb_check1("S2-G1 replace old response held", mem0_rsp_valid, 1'b1);

      new_token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_attr_valid = 1'b1;
      mem0_req_class = `OOO_MEM_CLASS_CACHED;
      mem0_req_cacheable = 1'b1;
      mem0_req_addr = NEW_ADDR;
      mem0_req_wdata = 64'h55aa_0123_4567_89ab;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      flush = 1'b1;
      mem0_rsp_ready = 1'b1;
      #1;
      tb_check1("S2-G1 replace advances nokill station", dut.stage_advance_w, 1'b1);
      tb_check1("S2-G1 replace drops old rsp", mem0_drop0_valid, 1'b1);
      tb_check1("S2-G1 replace does not drop nokill station", mem0_drop1_valid, 1'b0);
      tb_check32("S2-G1 replace old rsp token", {27'b0, mem0_drop0_owner_token},
                 {27'b0, old_token});
      tb_check64("S2-G1 replace old rsp tval", mem0_drop0_fault_tval, OLD_ADDR);
      tick();
      mem0_rsp_ready = 1'b0;
      #1;
      tb_check32("S2-G1 replacement active token", {27'b0, dut.active_owner_token_q},
                 {27'b0, new_token});
      tb_check32("S2-G1 replacement rsp snapshot", {27'b0, dut.rsp_owner_token_q},
                 {27'b0, new_token});
      tb_check1("S2-G1 replacement AW survives flush", lsu_axi_awvalid, 1'b1);
      tb_check1("S2-G1 replacement W survives flush", lsu_axi_wvalid, 1'b1);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("S2-G1 nokill response survives flush", mem0_rsp_valid, 1'b1);
      tb_check32("S2-G1 nokill response token", {27'b0, mem0_rsp_owner_token},
                 {27'b0, new_token});
      tb_check64("S2-G1 nokill response tval", mem0_rsp_fault_tval, NEW_ADDR);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      flush = 1'b0;
      $display("[S2-G1-BRG-ATOMIC-REPLACE][PASS] old=%0d new=%0d",
               old_token, new_token);
    end
  endtask

  // Focused owner-provenance mutation cases.  These are compiled separately
  // from the long bridge regression so each OOO_ASSERT run has one precise
  // expected fatal marker.  Equality may qualify side effects, but it must not
  // enter transport VALID/READY or state advancement.
  task automatic s2_g1_focused_station_mismatch;
    reg [4:0] token;
    localparam [`XLEN-1:0] ADDR = 64'h0000_0000_8000_e800;
    begin
      token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = ADDR;
      mem0_req_wstrb = 8'hff;
      #1;
      tb_check1("S2-G1 station mismatch request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      s2_station_identity_mutate = 1'b1;
      #1;
      tb_check1("S2-G1 station mismatch still advances transport station",
                dut.stage_advance_w, 1'b1);
      tb_check1("S2-G1 station mismatch blocks cache lookup",
                dut.req_read_lookup_fire_w, 1'b0);
      tick();
      // OOO_ASSERT terminates on the edge above.  Release builds enter an
      // explicit recovery-only hold and expose no AXI or response side effect.
      s2_station_identity_mutate = 1'b0;
      #1;
      tb_check32("S2-G1 station mismatch enters owner hold",
                 {28'b0, dut.state_q}, 32'd11);
      tb_check1("S2-G1 owner hold has no AR", lsu_axi_arvalid, 1'b0);
      tb_check1("S2-G1 owner hold has no AW/W",
                lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      tb_check1("S2-G1 owner hold has no response", mem0_rsp_valid, 1'b0);
      flush = 1'b1;
      #1;
      tb_check1("S2-G1 explicit recovery emits exact drop", mem0_drop0_valid, 1'b1);
      tb_check32("S2-G1 owner-hold drop token",
                 {27'b0, mem0_drop0_owner_token}, {27'b0, token});
      tb_check64("S2-G1 owner-hold drop tval", mem0_drop0_fault_tval, ADDR);
      tick();
      flush = 1'b0;
      #1;
      tb_check1("S2-G1 owner-hold drop pulses once", mem0_drop0_valid, 1'b0);
      $display("[S2-G1-BRG-STATION-FAILCLOSED][PASS] token=%0d", token);
    end
  endtask

  task automatic s2_g1_focused_active_identity_mismatch;
    reg [4:0] token;
    localparam [`XLEN-1:0] ADDR = 64'h0000_0000_8000_e900;
    begin
      token = mem0_req_owner_token;
      issue_mem0_read(ADDR);
      s2_active_identity_mutate = 1'b1;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0123_4567_89ab_cdef;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("S2-G1 MIQ mismatch still drains AXI R", lsu_axi_rready, 1'b1);
      tb_check1("S2-G1 MIQ mismatch blocks dcache fill",
                dut.dcache_read_fill_valid_w, 1'b0);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("S2-G1 MIQ mismatch does not suppress response transport",
                mem0_rsp_valid, 1'b1);
      tb_check32("S2-G1 mismatched response keeps captured token",
                 {27'b0, mem0_rsp_owner_token}, {27'b0, token});
      tb_check64("S2-G1 mismatched response keeps captured tval",
                 mem0_rsp_fault_tval, ADDR);
      mem0_rsp_ready = 1'b1;
      tick();
      // OOO_ASSERT terminates on the response edge above.  The release build
      // proves READY remains independent of equality and drains transport.
      mem0_rsp_ready = 1'b0;
      s2_active_identity_mutate = 1'b0;
      #1;
      tb_check1("S2-G1 mismatch transport drained", mem0_rsp_valid, 1'b0);
      $display("[S2-G1-BRG-RSP-FAILCLOSED][PASS] token=%0d", token);
    end
  endtask

  task automatic s2_g1_focused_active_tracker_mismatch;
    localparam [`XLEN-1:0] ADDR = 64'h0000_0000_8000_ea00;
    begin
      issue_mem0_read(ADDR);
      s2_active_tracker_mutate = 1'b1;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h5a5a_a5a5_c3c3_3c3c;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("S2-G1 tracker mismatch still drains AXI R", lsu_axi_rready, 1'b1);
      tb_check1("S2-G1 nonlive tracker mismatch blocks dcache fill",
                dut.dcache_read_fill_valid_w, 1'b0);
      tick();
      // OOO_ASSERT terminates on the R edge above.  In a release build the
      // transport may continue, but no tracker-mismatched side effect occurs.
      lsu_axi_rvalid = 1'b0;
      s2_active_tracker_mutate = 1'b0;
      #1;
      tb_check1("S2-G1 tracker mismatch transport remains visible",
                mem0_rsp_valid, 1'b1);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      $display("[S2-G1-BRG-TRACKER-FAILCLOSED][PASS]");
    end
  endtask

  task automatic s2_g1_focused_tval_drift;
    reg [4:0] token;
    localparam [`XLEN-1:0] ADDR = 64'h0000_0000_8000_eb00;
    begin
      token = mem0_req_owner_token;
      issue_mem0_read(ADDR);
      s2_active_tval_mutate = 1'b1;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'hfeed_face_7654_3210;
      lsu_axi_rresp = 2'b00;
      #1;
      tb_check1("S2-G1 tval-only drift does not block exact-owner fill",
                dut.dcache_read_fill_valid_w, 1'b1);
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("S2-G1 tval-only drift keeps response transport",
                mem0_rsp_valid, 1'b1);
      tb_check32("S2-G1 tval drift keeps exact token",
                 {27'b0, mem0_rsp_owner_token}, {27'b0, token});
      tb_check64("S2-G1 tval drift uses capture-time payload",
                 mem0_rsp_fault_tval, ADDR);
      mem0_rsp_ready = 1'b1;
      tick();
      // OOO_ASSERT terminates on the response edge above.  Non-assert builds
      // consume the exact 9-bit owner despite diagnostic tval echo drift.
      mem0_rsp_ready = 1'b0;
      s2_active_tval_mutate = 1'b0;
      $display("[S2-G1-BRG-TVAL-PAYLOAD][PASS] token=%0d", token);
    end
  endtask

  // The highest-risk escaped-write case is a hardware A/D PTE update: the
  // original load can be killed after registered AW/W presentation, the MIQ
  // head can advance, and the late B must still invalidate the PTE alias while
  // remaining forbidden from filling the DTLB or producing any response.
  task automatic s2_g1_focused_killed_ad_maintenance;
    reg [4:0] token;
    reg [`XLEN-1:0] orig_pte;
    begin
      clear_inputs();
      tick();
      token = mem0_req_owner_token;
      orig_pte = (SUPERPAGE_PPN << 10) | LEAF_NO_ACCESS_FLAGS;
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("S2-G1 killed A/D request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("S2-G1 killed A/D walk AR", lsu_axi_arvalid, 1'b1);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = orig_pte;
      lsu_axi_rresp = 2'b00;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("S2-G1 killed A/D registered AW", lsu_axi_awvalid, 1'b1);
      tb_check1("S2-G1 killed A/D registered W", lsu_axi_wvalid, 1'b1);
      tb_check1("S2-G1 killed A/D not escaped before READY",
                dut.write_escaped_q, 1'b0);

      // Capture while edge-old MIQ/tracker/sticky identity is still exact.
      s2_expected_effective_killed = 1'b1;
      flush = 1'b1;
      #1;
      tb_check1("S2-G1 killed A/D exact kill captures authority",
                dut.killed_write_maintenance_capture_w, 1'b1);
      tb_check1("S2-G1 killed A/D kill edge blocks DTLB fill",
                dut.dtlb_fill_valid_w, 1'b0);
      tick();
      s2_expected_effective_killed = 1'b0;
      s2_active_identity_mutate = 1'b1;
      #1;
      tb_check1("S2-G1 killed A/D authority latched",
                dut.killed_write_maintenance_authorized_q, 1'b1);
      tb_check1("S2-G1 killed A/D MIQ head advanced",
                dut.active_expected_identity_match_w, 1'b0);

      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      #1;
      tb_check1("S2-G1 killed A/D waits real B", lsu_axi_bready, 1'b1);
      lsu_axi_bvalid = 1'b1;
      lsu_axi_bresp = 2'b00;
      #1;
      tb_check1("S2-G1 killed A/D late B invalidates alias",
                dut.dcache_store_commit_w, 1'b1);
      tb_check1("S2-G1 killed A/D late B forbids RMW",
                dut.dcache_store_rmw_en_w, 1'b0);
      tb_check1("S2-G1 killed A/D late B forbids DTLB fill",
                dut.dtlb_fill_valid_w, 1'b0);
      tb_check1("S2-G1 killed A/D late B has no response",
                mem0_rsp_valid, 1'b0);
      tb_check1("S2-G1 killed A/D late B is exact drop terminal",
                mem0_drop0_valid, 1'b1);
      tb_check32("S2-G1 killed A/D drop token",
                 {27'b0, mem0_drop0_owner_token}, {27'b0, token});
      tick();
      lsu_axi_bvalid = 1'b0;
      flush = 1'b0;
      s2_active_identity_mutate = 1'b0;
      #1;
      tb_check1("S2-G1 killed A/D authority consumed once",
                dut.killed_write_maintenance_authorized_q, 1'b0);
      tb_check1("S2-G1 killed A/D commit pulses once",
                dut.dcache_store_commit_w, 1'b0);
      tb_check1("S2-G1 killed A/D drop pulses once", mem0_drop0_valid, 1'b0);
      $display("[S2-G1-BRG-KILLED-AD-MAINT][PASS] token=%0d", token);
    end
  endtask

  // Counterexample for the old `(cpu_kill || effective_killed)` bypass: if
  // the edge-old MIQ owner is already different, neither raw flush nor a naked
  // killed bit may mint cache-maintenance authority for the active write.
  task automatic s2_g1_focused_killed_write_mismatch_failclosed;
    reg [4:0] token;
    localparam [`XLEN-1:0] ADDR = 64'h0000_0000_8000_ec00;
    begin
      clear_inputs();
      tick();
      token = mem0_req_owner_token;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_addr = ADDR;
      mem0_req_wdata = 64'hcafe_f00d_1234_5678;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("S2-G1 mismatched killed write presents AW/W",
                lsu_axi_awvalid & lsu_axi_wvalid, 1'b1);
      s2_active_identity_mutate = 1'b1;
      s2_expected_effective_killed = 1'b1;
      flush = 1'b1;
      #1;
      tb_check1("S2-G1 mismatched kill cannot capture authority",
                dut.killed_write_maintenance_capture_w, 1'b0);
      tick();
      s2_expected_effective_killed = 1'b0;
      #1;
      tb_check1("S2-G1 mismatched kill leaves authority clear",
                dut.killed_write_maintenance_authorized_q, 1'b0);
      lsu_axi_awready = 1'b1;
      lsu_axi_wready = 1'b1;
      tick();
      lsu_axi_awready = 1'b0;
      lsu_axi_wready = 1'b0;
      lsu_axi_bvalid = 1'b1;
      #1;
      tb_check1("S2-G1 mismatched late B cannot maintain cache",
                dut.dcache_store_commit_w, 1'b0);
      tb_check1("S2-G1 mismatched late B cannot RMW cache",
                dut.dcache_store_rmw_en_w, 1'b0);
      tb_check1("S2-G1 mismatched late B still drains transport",
                lsu_axi_bready, 1'b1);
      tb_check1("S2-G1 mismatched late B still names exact drop",
                mem0_drop0_valid, 1'b1);
      tb_check32("S2-G1 mismatched killed drop token",
                 {27'b0, mem0_drop0_owner_token}, {27'b0, token});
      tick();
      lsu_axi_bvalid = 1'b0;
      flush = 1'b0;
      s2_active_identity_mutate = 1'b0;
      #1;
      tb_check1("S2-G1 mismatched killed drop pulses once",
                mem0_drop0_valid, 1'b0);
      $display("[S2-G1-BRG-KILLED-WRITE-FAILCLOSED][PASS] token=%0d", token);
    end
  endtask

  // A kill before any write phase has presented AW/W is cancelable and must
  // not create the escaped-write exception.
  task automatic s2_g1_focused_prewrite_kill_no_authority;
    begin
      clear_inputs();
      tick();
      priv_mode = `PRIV_S;
      satp = (64'h8 << 60) | ROOT_PPN;
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = DATA_VA_AD;
      mem0_req_wstrb = 8'hff;
      tick();
      mem0_req_valid = 1'b0;
      tick();
      #1;
      tb_check1("S2-G1 prewrite kill is still a read walk",
                lsu_axi_arvalid, 1'b1);
      tb_check1("S2-G1 prewrite kill has no AW/W",
                lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
      s2_expected_effective_killed = 1'b1;
      flush = 1'b1;
      #1;
      tb_check1("S2-G1 prewrite kill cannot capture write authority",
                dut.killed_write_maintenance_capture_w, 1'b0);
      tick();
      s2_expected_effective_killed = 1'b0;
      #1;
      tb_check1("S2-G1 prewrite kill leaves authority clear",
                dut.killed_write_maintenance_authorized_q, 1'b0);
      lsu_axi_arready = 1'b1;
      tick();
      lsu_axi_arready = 1'b0;
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = {`XLEN{1'b0}};
      tick();
      lsu_axi_rvalid = 1'b0;
      flush = 1'b0;
      #1;
      tb_check1("S2-G1 prewrite kill produced no cache maintenance",
                dut.dcache_store_commit_w, 1'b0);
      $display("[S2-G1-BRG-PREWRITE-KILL][PASS]");
    end
  endtask

  wire unused_outputs =
      mem0_rsp_error | mem0_rsp_page_fault | (|lsu_axi_wstrb) |
      mem_translate_active | mem0_rsp_cacheable;

`ifndef S2_G1_BRIDGE_FOCUSED
  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;
    check_svpbmt_pte_reserved_policy();
    check_post_translate_memory_class();

    held_response_flush_drop();
    inflight_read_flush_abort();
    stalled_ar_survives_flush();
    read_arsize_tracks_load_mask();
    cached_window_shift_and_cross_block();
    dcache_hit_fusion_cases();
    dma_invalidate_blocks_hit_fusion();
    speculative_cache_hit_cannot_bypass_pmp();
    speculative_cache_hit_cannot_bypass_dtlb_permission();
    speculative_stale_tlb_candidate_cannot_bypass_walk();
    partial_write_flush_drain();
    flushed_store_does_not_poison_dcache();
    b_error_invalidates_possible_partial_store_alias();
    store_rmw_write_update_and_bubble();
    sv39_ad_write_pmp_deny("T4F load A-update PTE write denied", 1'b0,
                           LEAF_NO_ACCESS_FLAGS);
    sv39_ad_write_pmp_deny("T4F store D-update PTE write denied", 1'b1,
                           LEAF_NO_DIRTY_FLAGS);
    sv39_leaf_ad_update("sv39 A=0 load triggers HW A update", 1'b0,
                       LEAF_NO_ACCESS_FLAGS);
    sv39_leaf_ad_update("sv39 D=0 store triggers HW D update", 1'b1,
                       LEAF_NO_DIRTY_FLAGS);
    sv39_posttranslate_device_owner();
    sv39_dtlb_and_paddr_cache_hit();
    pbmt_reserved_beats_pmp_dtlb_hit();
    pbmt_reserved_beats_pmp_ptw_leaf();
    sv39_pbmt_pmem_bypasses_dcache(2'b01, 64'h1111_0000_aaaa_5555);
    sv39_pbmt_pmem_bypasses_dcache(2'b10, 64'h2222_0000_bbbb_6666);
    probe_write_returns_pa();
    probe_write_pma_deny_bare();
    probe_write_pma_deny_sv39_leaf();
    pretrans_bresp_terminal_case("T4N B OKAY", DATA_PA + 64'h100,
                                 2'b00, 1'b0);
    pretrans_bresp_terminal_case("T4N B SLVERR", DATA_PA + 64'h108,
                                 2'b10, 1'b1);
    pretrans_bresp_terminal_case("T4N B DECERR", DATA_PA + 64'h110,
                                 2'b11, 1'b1);
    pretrans_nokill_store_survives_flush();
    stage_skid_hold_and_flush_semantics();
    s2_g1_write_valid_hold_case(0);
    s2_g1_write_valid_hold_case(1);
    s2_g1_write_valid_hold_case(2);
    s2_g1_dual_drop_distinct_tuple();
    s2_g1_rsp_flush_nokill_atomic_replace();

    tb_check1("unused outputs settle", unused_outputs, unused_outputs);
    tb_finish("tb_ooo_mem_axi_bridge");
  end
`else
  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;
    case (S2_G1_CASE)
      1: s2_g1_focused_station_mismatch();
      2: s2_g1_focused_active_identity_mismatch();
      3: s2_g1_focused_active_tracker_mismatch();
      4: s2_g1_focused_tval_drift();
      5: s2_g1_focused_killed_ad_maintenance();
      6: s2_g1_focused_killed_write_mismatch_failclosed();
      7: s2_g1_focused_prewrite_kill_no_authority();
      default: begin
        $display("[S2-G1-BRG-FOCUSED][FAIL] unsupported case=%0d", S2_G1_CASE);
        tb_errors = tb_errors + 1;
      end
    endcase
    tb_finish("tb_ooo_mem_axi_bridge");
  end
`endif

endmodule
