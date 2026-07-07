`include "define.v"

module tb_ooo_mem_axi_bridge;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg mmu_flush;

  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;

  reg mem0_req_valid;
  wire mem0_req_ready;
  reg mem0_req_write;
  reg mem0_req_probe;
  reg mem0_req_pretrans;
  reg mem0_req_nokill;
  reg [`XLEN-1:0] mem0_req_addr;
  reg [`XLEN-1:0] mem0_req_wdata;
  reg [`STRB_W-1:0] mem0_req_wstrb;
  wire mem0_rsp_valid;
  reg mem0_rsp_ready;
  wire [`XLEN-1:0] mem0_rsp_rdata;
  wire mem0_rsp_error;
  wire mem0_rsp_page_fault;
  wire mem_translate_active;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  wire [`STRB_W-1:0] lsu_axi_arstrb;
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
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR = {`PMP_ADDR_BUS_W{1'b1}};

  OooMemAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .mmu_flush_i(mmu_flush),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(PMP_ALLOW_ALL_CFG),
    .pmpaddr_i(PMP_ALLOW_ALL_ADDR),
    .mem0_req_valid_i(mem0_req_valid),
    .mem0_req_ready_o(mem0_req_ready),
    .mem0_req_write_i(mem0_req_write),
    .mem0_req_probe_i(mem0_req_probe),
    .mem0_req_pretrans_i(mem0_req_pretrans),
    .mem0_req_nokill_i(mem0_req_nokill),
    .mem0_req_addr_i(mem0_req_addr),
    .mem0_req_wdata_i(mem0_req_wdata),
    .mem0_req_wstrb_i(mem0_req_wstrb),
    .mem0_rsp_valid_o(mem0_rsp_valid),
    .mem0_rsp_ready_i(mem0_rsp_ready),
    .mem0_rsp_rdata_o(mem0_rsp_rdata),
    .mem0_rsp_error_o(mem0_rsp_error),
    .mem0_rsp_page_fault_o(mem0_rsp_page_fault),
    .translate_active_o(mem_translate_active),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_arstrb_o(lsu_axi_arstrb),
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
      priv_mode = `PRIV_M;
      mstatus = {`XLEN{1'b0}};
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      mem0_req_valid = 1'b0;
      mem0_req_write = 1'b0;
      mem0_req_probe = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
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

      tb_check1("mem PBMT=1 leaf faults while Svpbmt disabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("mem PBMT=1 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("mem PBMT=2 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt2_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("mem PBMT=3 leaf remains reserved",
                dut.pte_reserved_fault(pbmt3_leaf, 1'b1, 2'd0), 1'b1);
      tb_check1("mem non-leaf PBMT remains reserved",
                dut.pte_reserved_fault(pbmt1_nonleaf, 1'b1, 2'd1), 1'b1);
      tb_check1("mem Svnapot 64KiB leaf is legal",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd0), 1'b0);
      tb_check1("mem Svnapot bad ppn encoding faults",
                dut.pte_reserved_fault(napot_bad_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("mem Svnapot non-leaf faults",
                dut.pte_reserved_fault(napot_nonleaf, 1'b0, 2'd1), 1'b1);
      tb_check1("mem Svnapot level1 leaf faults",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd1), 1'b1);
      tb_check64("mem Svnapot PA uses VA low PPN bits",
                 dut.leaf_paddr(napot_leaf, DATA_VA, 2'd0), DATA_PA);
    end
  endtask

  task automatic issue_mem0_read;
    input [`XLEN-1:0] addr;
    begin
      issue_mem0_read_strb(addr, {`STRB_W{1'b1}});
    end
  endtask

  // 【line-dcache】读 miss 语义: 不跨线 → 对齐 AR(addr&~7)+strb 全 1(取整线);
  // 跨线 → 原窗口 AR+原 strb(uncached 直读)。
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
      tb_check1("mem0 read issues AR", lsu_axi_arvalid, 1'b1);
      tb_check64("mem0 read AR address", lsu_axi_araddr,
                 is_cross_r ? addr : {addr[`XLEN-1:3], 3'b000});
      tb_check64("mem0 read AR strb", {{(`XLEN-`STRB_W){1'b0}}, lsu_axi_arstrb},
                 is_cross_r ? {{(`XLEN-`STRB_W){1'b0}}, strb}
                       : {{(`XLEN-`STRB_W){1'b0}}, {`STRB_W{1'b1}}});
      tick();
      mem0_req_valid = 1'b0;
      lsu_axi_arready = 1'b0;
    end
  endtask

  task automatic read_arstrb_tracks_load_mask;
    begin
      issue_mem0_read_strb(64'h0000_0000_8000_1005, 8'b0010_0000);
      lsu_axi_rvalid = 1'b1;
      lsu_axi_rdata = 64'h0102_0304_0506_0708;
      tick();
      lsu_axi_rvalid = 1'b0;
      #1;
      tb_check1("masked read response valid", mem0_rsp_valid, 1'b1);
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
      tb_check1("aborted read no longer waits for R", lsu_axi_rready, 1'b0);
      tb_check1("aborted read has no CPU response", mem0_rsp_valid, 1'b0);
      tb_check1("bridge idle after read abort", mem0_req_ready, 1'b1);

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
      #1;
      tb_check1("write drain waits for B", lsu_axi_bready, 1'b1);
      tb_check1("write drain suppresses response", mem0_rsp_valid, 1'b0);

      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      #1;
      tb_check1("bridge idle after write drain", mem0_req_ready, 1'b1);
      tb_check1("write drain never exposes response", mem0_rsp_valid, 1'b0);
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
      tick();
      flush = 1'b0;
      #1;
      tb_check1("aborted store returns idle", mem0_req_ready, 1'b1);

      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b0;
      mem0_req_addr = 64'h0000_0000_8000_5000;
      #1;
      tb_check1("post-abort read hits cache", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
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
      #1;
      tb_check1("post-commit read hits cache", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("post-commit cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("committed store updates dcache", mem0_rsp_rdata,
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
      #1;
      tb_check1("post-drain read hits cache", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      #1;
      tb_check1("post-drain cached response valid", mem0_rsp_valid, 1'b1);
      tb_check64("drained store updates dcache", mem0_rsp_rdata,
                 64'h1234_5678_9abc_def0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
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
      tb_check1("sv39 first walk AR valid", lsu_axi_arvalid, 1'b1);
      tb_check64("sv39 first walk PTE address", lsu_axi_araddr,
                 ROOT_PT + 64'd16);
      tb_check64("sv39 first walk AR strb",
                 {{(`XLEN-`STRB_W){1'b0}}, lsu_axi_arstrb},
                 {{(`XLEN-`STRB_W){1'b0}}, {`STRB_W{1'b1}}});
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
      tb_check64("sv39 translated data AR strb",
                 {{(`XLEN-`STRB_W){1'b0}}, lsu_axi_arstrb},
                 {{(`XLEN-`STRB_W){1'b0}}, {`STRB_W{1'b1}}});
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
      // 第二次同页同字访问应由 DTLB + 物理 data cache 命中，不再发 page-walk/data AR。
      tb_check1("sv39 repeat request no AXI AR", lsu_axi_arvalid, 1'b0);
      tick();
      mem0_req_valid = 1'b0;
      lsu_axi_arready = 1'b0;

      #1;
      tb_check1("sv39 repeat response valid", mem0_rsp_valid, 1'b1);
      tb_check64("sv39 repeat response data", mem0_rsp_rdata,
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

  // HW-managed A/D（Svadu，对齐 NEMU）：leaf 真权限过但 A=0(任意)/D=0(store) 不再 page fault，
  // 而是经 S_AD_UPDATE 写回 leaf PTE 置 A(D) 位、填 TLB 后续原访问：
  //   A=0 load  → 写 PTE|A → load miss 续 S_READ_ADDR(data AR) → 返回数据；
  //   D=0 store → 写 PTE|A|D → 续 S_WRITE_REQ(store AW/W→DATA_PA, PMEM decouple 提前完成)。
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
        // 续 store：AW/W 到 DATA_PA（store 数据），PMEM decouple 提前报完成。
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
        tb_check1("sv39 A/D update store response valid", mem0_rsp_valid,
                  1'b1);
        tb_check1("sv39 A/D update store no error", mem0_rsp_error, 1'b0);
        tb_check1("sv39 A/D update store no page fault", mem0_rsp_page_fault,
                  1'b0);
        mem0_rsp_ready = 1'b1;
        tick();
        mem0_rsp_ready = 1'b0;
        // decoupled PMEM store 的 B（bpend）吸收。
        lsu_axi_bvalid = 1'b1;
        tick();
        lsu_axi_bvalid = 1'b0;
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

  // 【LSQ·SQ 切换】pretrans+nokill(退休 store 落存): 跳过翻译直写 PA, 且 flush
  // 期间事务照常推进(写必达)、响应不被 kill 压制。
  task automatic pretrans_nokill_store_survives_flush;
    begin
      clear_inputs();
      tick();
      mem0_req_valid = 1'b1;
      mem0_req_write = 1'b1;
      mem0_req_pretrans = 1'b1;
      mem0_req_nokill = 1'b1;
      mem0_req_addr = DATA_PA;
      mem0_req_wdata = 64'h1122_3344_5566_7788;
      mem0_req_wstrb = {`STRB_W{1'b1}};
      #1;
      tb_check1("pretrans request ready", mem0_req_ready, 1'b1);
      tick();
      mem0_req_valid = 1'b0;
      mem0_req_pretrans = 1'b0;
      mem0_req_nokill = 1'b0;
      // 立刻 flush: nokill 事务必须继续发出 AW/W 并完成
      flush = 1'b1;
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
      // PMEM store 解耦: AW/W 落地即响应, flush 不得压制 nokill 事务的 rsp_valid
      tb_check1("nokill response valid under flush", mem0_rsp_valid, 1'b1);
      tb_check1("nokill response no error", mem0_rsp_error, 1'b0);
      mem0_rsp_ready = 1'b1;
      tick();
      mem0_rsp_ready = 1'b0;
      flush = 1'b0;
      // 后台 B 由 bpend 吸收
      lsu_axi_bvalid = 1'b1;
      tick();
      lsu_axi_bvalid = 1'b0;
      tick();
    end
  endtask

  wire unused_outputs =
      mem0_rsp_error | mem0_rsp_page_fault | (|lsu_axi_wstrb) |
      mem_translate_active;

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

    held_response_flush_drop();
    inflight_read_flush_abort();
    read_arstrb_tracks_load_mask();
    partial_write_flush_drain();
    flushed_store_does_not_poison_dcache();
    sv39_leaf_ad_update("sv39 A=0 load triggers HW A update", 1'b0,
                       LEAF_NO_ACCESS_FLAGS);
    sv39_leaf_ad_update("sv39 D=0 store triggers HW D update", 1'b1,
                       LEAF_NO_DIRTY_FLAGS);
    sv39_dtlb_and_paddr_cache_hit();
    probe_write_returns_pa();
    pretrans_nokill_store_survives_flush();

    tb_check1("unused outputs settle", unused_outputs, unused_outputs);
    tb_finish("tb_ooo_mem_axi_bridge");
  end

endmodule
