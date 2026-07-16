`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_axi_bridge;
  reg clk;
  reg rst;
  reg mmu_flush;
  reg invalidate_valid;
  reg [`XLEN-1:0] invalidate_addr;
  reg [1:0] priv_mode;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr;
  reg fetch_req_valid;
  wire fetch_req_ready;
  reg [`XLEN-1:0] fetch_req_pc;
  wire [`XLEN-1:0] fetch_req_owner_pc;
  wire fetch_rsp_valid;
  reg fetch_rsp_ready;
  wire [`INST_W-1:0] fetch_rsp_inst0;
  wire [1:0] fetch_rsp_resp0;
  wire [`INST_W-1:0] fetch_rsp_inst1;
  wire [1:0] fetch_rsp_resp1;
  wire [2:0] fetch_rsp_resp0_bytes;
  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
  wire [2:0] ifu_axi_arsize;
  wire [2:0] ifu_axi_arprot;
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;
  // HW-managed A 更新写通道
  wire ifu_axi_awvalid;
  reg ifu_axi_awready;
  wire [`XLEN-1:0] ifu_axi_awaddr;
  wire ifu_axi_wvalid;
  reg ifu_axi_wready;
  wire [`XLEN-1:0] ifu_axi_wdata;
  wire [`STRB_W-1:0] ifu_axi_wstrb;
  reg ifu_axi_bvalid;
  wire ifu_axi_bready;
  reg [1:0] ifu_axi_bresp;

  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_ACCESS_FAULT = 2'b01;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam [3:0] S_IDLE_TB = 4'd0;
  localparam [3:0] S_WALK_AR_TB = 4'd1;
  localparam [3:0] S_R0_TB = 4'd4;
  localparam [3:0] S_RESP_TB = 4'd7;
  localparam [3:0] S_AD_UPDATE_TB = 4'd8;
  localparam [3:0] S_LOOKUP_TB = 4'd9;
  localparam [3:0] S_DRAIN_TB = 4'd10;
  localparam [3:0] S_CACHE_READ_TB = 4'd11;
  localparam [3:0] S_WALK_CHECK_TB = 4'd12;
  localparam [3:0] S_WALK_AR_DROP_TB = 4'd13;
  localparam [3:0] S_FETCH_AR_DROP_TB = 4'd14;
  localparam [`XLEN-1:0] PTE_A_BIT_TB = 64'h40;  // bit 6 (Accessed)
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] L1_PT = 64'h0000_0000_8100_1000;
  localparam [`XLEN-1:0] L0_PT = 64'h0000_0000_8100_2000;
  localparam [`XLEN-1:0] USER_VA = 64'h0000_0000_0000_4000;
  localparam [`XLEN-1:0] USER_PA = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] CROSS_VA = 64'h0000_0000_0000_4ffe;
  localparam [`XLEN-1:0] CROSS_NEXT_VA = 64'h0000_0000_0000_5000;
  localparam [`XLEN-1:0] NONCANON_VA = 64'h0000_0080_0000_0000;
  localparam [`XLEN-1:0] CROSS_PA0 = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] CROSS_PA1 = 64'h0000_0000_8200_9000;
  localparam [`XLEN-1:0] SUP_VA = 64'h0000_0000_0000_8000;
  localparam [`XLEN-1:0] SUP_PA = 64'h0000_0000_8200_8000;
  localparam [`XLEN-1:0] NO_ACCESS_VA = 64'h0000_0000_0000_c000;
  localparam [`XLEN-1:0] NO_ACCESS_PA = 64'h0000_0000_8200_c000;
  localparam [`XLEN-1:0] SATP_VALUE =
      64'h8000_0000_0000_0000 | (ROOT_PT >> 12);
  localparam [`XLEN-1:0] PTE_NONLEAF_FLAGS = 64'h001;
  localparam [`XLEN-1:0] PTE_USER_X_FLAGS = 64'h0df;
  localparam [`XLEN-1:0] PTE_USER_X_NO_ACCESS_FLAGS = 64'h09f;
  localparam [`XLEN-1:0] PTE_SUP_X_FLAGS = 64'h0cf;
  localparam [`XLEN-1:0] USER_INST_BEAT = 64'h0010_0093_0000_0013;
  // 刀F 融合拍用例: M 模式直取地址(paging off), 不同 cache index
  localparam [`XLEN-1:0] FUSION_PC1 = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] FUSION_PC2 = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] FUSION_PC3_COLD = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] FUSION_BEAT1 = 64'h0020_0113_0000_0013;
  localparam [`XLEN-1:0] FUSION_BEAT2 = 64'h0030_0193_0000_0013;
  localparam [`XLEN-1:0] FUSION_BEAT3 = 64'h0040_0213_0000_0013;
  localparam [`XLEN-1:0] CROSS_FIRST_BEAT = 64'hcccc_cccc_97de_1693;
  localparam [`XLEN-1:0] CROSS_SECOND_BEAT = 64'h0073_0016_8693_0024;
  localparam [`XLEN-1:0] CROSS_MERGED_BEAT = 64'h0016_8693_0024_1693;
  localparam [`XLEN-1:0] SUP_INST_BEAT = 64'h0020_0113_0000_0013;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR = {`PMP_ADDR_BUS_W{1'b1}};

  OooFetchAxiBridge dut (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(mmu_flush),
    .invalidate_valid_i(invalidate_valid),
    .invalidate_addr_i(invalidate_addr),
    .priv_mode_i(priv_mode),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(pmpcfg),
    .pmpaddr_i(pmpaddr),
    .fetch_req_valid_i(fetch_req_valid),
    .fetch_req_ready_o(fetch_req_ready),
    .fetch_req_pc_i(fetch_req_pc),
    .fetch_req_owner_pc_o(fetch_req_owner_pc),
    .fetch_rsp_valid_o(fetch_rsp_valid),
    .fetch_rsp_ready_i(fetch_rsp_ready),
    .fetch_rsp_inst0_o(fetch_rsp_inst0),
    .fetch_rsp_resp0_o(fetch_rsp_resp0),
    .fetch_rsp_inst1_o(fetch_rsp_inst1),
    .fetch_rsp_resp1_o(fetch_rsp_resp1),
    .fetch_rsp_resp0_bytes_o(fetch_rsp_resp0_bytes),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_arsize_o(ifu_axi_arsize),
    .ifu_axi_arprot_o(ifu_axi_arprot),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .ifu_axi_awvalid_o(ifu_axi_awvalid),
    .ifu_axi_awready_i(ifu_axi_awready),
    .ifu_axi_awaddr_o(ifu_axi_awaddr),
    .ifu_axi_wvalid_o(ifu_axi_wvalid),
    .ifu_axi_wready_i(ifu_axi_wready),
    .ifu_axi_wdata_o(ifu_axi_wdata),
    .ifu_axi_wstrb_o(ifu_axi_wstrb),
    .ifu_axi_bvalid_i(ifu_axi_bvalid),
    .ifu_axi_bready_o(ifu_axi_bready),
    .ifu_axi_bresp_i(ifu_axi_bresp)
  );

  always #5 clk = ~clk;

  task automatic tb_check2;
    input [1023:0] what;
    input [1:0] got;
    input [1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%0b expected=%0b", what, got, exp);
      end
    end
  endtask

  task automatic tb_check32_local;
    input [1023:0] what;
    input [`INST_W-1:0] got;
    input [`INST_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%08x expected=0x%08x",
                 what, got, exp);
      end
    end
  endtask

  task automatic tb_check64_local;
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

  function [8:0] vpn_by_level;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      case (level)
        2'd2: vpn_by_level = vaddr[38:30];
        2'd1: vpn_by_level = vaddr[29:21];
        default: vpn_by_level = vaddr[20:12];
      endcase
    end
  endfunction

  function [`XLEN-1:0] pte_addr;
    input [`XLEN-1:0] base;
    input [`XLEN-1:0] vaddr;
    input [1:0] level;
    begin
      pte_addr = base + {{(`XLEN-12){1'b0}}, vpn_by_level(vaddr, level), 3'b000};
    end
  endfunction

  function [`XLEN-1:0] pte_for_page;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] flags;
    begin
      pte_for_page = ((paddr >> 12) << 10) | flags;
    end
  endfunction

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      mmu_flush = 1'b0;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      fetch_rsp_ready = 1'b0;
      ifu_axi_arready = 1'b1;
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;
      ifu_axi_awready = 1'b1;
      ifu_axi_wready = 1'b1;
      ifu_axi_bvalid = 1'b0;
      ifu_axi_bresp = RESP_OK;
      repeat (3) tick();
      rst = 1'b0;
      tick();
    end
  endtask

  // IFU-AXI-G1 focused case reset。这里不重写 clk，允许在主测试中多次重置同一 DUT。
  task automatic reset_protocol_case;
    begin
      rst = 1'b1;
      mmu_flush = 1'b0;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      fetch_rsp_ready = 1'b0;
      ifu_axi_arready = 1'b1;
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;
      ifu_axi_awready = 1'b0;
      ifu_axi_wready = 1'b0;
      ifu_axi_bvalid = 1'b0;
      ifu_axi_bresp = RESP_OK;
      repeat (3) tick();
      rst = 1'b0;
      tick();
    end
  endtask

  // 直接把已由自然 A-update/独立 PTW-CHECK 用例验证的边界产物投影到
  // S_AD_UPDATE，定向隔离 write owner 生命周期。不能先呈现一个 stalled AR
  // 再用 XMR 跳走，否则测试本身会违反 VALID-until-fire。
  task automatic seed_ad_update;
    input [`XLEN-1:0] pte_data;
    begin
      // Establish the immutable context through the real request handshake so
      // the T4A candidate/exec handoff assertions remain meaningful.  Let both
      // registered request-boundary checks retire before projecting the FSM.
      @(negedge clk);
      fetch_req_pc = USER_VA;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("A-update seed request ready", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      tick();
      tick();
      @(negedge clk);
      dut.state_q = S_AD_UPDATE_TB;
      dut.walk_pte_addr_q = pte_addr(L0_PT, USER_VA, 2'd0);
      dut.ad_pte_q = pte_data;
      dut.aw_done_q = 1'b0;
      dut.w_done_q = 1'b0;
      ifu_axi_arready = 1'b1;
      #1;
      tb_check1("seeded A-update presents AW", ifu_axi_awvalid, 1'b1);
      tb_check1("seeded A-update presents W", ifu_axi_wvalid, 1'b1);
      tb_check1("seeded A-update presents BREADY", ifu_axi_bready, 1'b1);
      tb_check64_local("seeded A-update owner PC", fetch_req_owner_pc,
                       USER_VA);
      tb_check64_local("seeded A-update AWADDR", ifu_axi_awaddr,
                       pte_addr(L0_PT, USER_VA, 2'd0));
      tb_check64_local("seeded A-update WDATA", ifu_axi_wdata, pte_data);
    end
  endtask

  task automatic check_dropped_write_quiet;
    input [1023:0] what;
    begin
      #1;
      tb_check1(what, dut.state_q == S_IDLE_TB, 1'b1);
      tb_check1("dropped A-update emits no fetch response", fetch_rsp_valid, 1'b0);
      tb_check1("dropped A-update emits no re-walk AR", ifu_axi_arvalid, 1'b0);
      repeat (2) begin
        tick();
        tb_check1("dropped A-update stays response-quiet", fetch_rsp_valid, 1'b0);
        tb_check1("dropped A-update stays read-quiet", ifu_axi_arvalid, 1'b0);
      end
    end
  endtask

  task automatic start_fetch;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [1:0] req_priv;
    begin
      priv_mode = req_priv;
      satp = SATP_VALUE;
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1(what, fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
    end
  endtask

  task automatic expect_ar;
    input [1023:0] what;
    input [`XLEN-1:0] exp_addr;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_arvalid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, ifu_axi_arvalid, 1'b1);
      if (ifu_axi_arvalid === 1'b1) begin
        tb_check64_local(what, ifu_axi_araddr, exp_addr);
      end
      tick();
    end
  endtask

  task automatic drive_r;
    input [`XLEN-1:0] data;
    input [1:0] resp;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_rready !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("read channel ready", ifu_axi_rready, 1'b1);
      ifu_axi_rdata = data;
      ifu_axi_rresp = resp;
      ifu_axi_rvalid = 1'b1;
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;
    end
  endtask

  task automatic drive_fetch_halfword;
    input [`XLEN-1:0] packet;
    input [2:0] byte_offset;
    reg [15:0] halfword;
    reg [`XLEN-1:0] lane_data;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_rready !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("instruction read channel ready", ifu_axi_rready, 1'b1);
      tb_check1("instruction read ARSIZE=2B", ifu_axi_arsize == 3'd1, 1'b1);
      tb_check1("instruction read ARPROT=exec", ifu_axi_arprot == 3'b100, 1'b1);
      case (byte_offset)
        3'd0: halfword = packet[15:0];
        3'd2: halfword = packet[31:16];
        3'd4: halfword = packet[47:32];
        default: halfword = packet[63:48];
      endcase
      lane_data = {{(`XLEN-16){1'b0}}, halfword} <<
                  ({ifu_axi_araddr[2:0], 3'b000});
      ifu_axi_rdata = lane_data;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      #1;
      if (dut.fetch_cache_fill_complete_w) begin
        tb_check1("final R0 fill owns state", dut.state_q == S_R0_TB, 1'b1);
        tb_check1("final R0 fill closes physical read window",
                  dut.fetch_cache_read_window_w, 1'b0);
        tb_check1("final R0 fill drives SRAM write",
                  dut.u_fetch_packet_cache.sram_we_w, 1'b1);
      end
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = RESP_OK;
    end
  endtask

  task automatic drive_fetch_packet;
    input [1023:0] what;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] packet;
    integer offset;
    begin
      for (offset = 0; offset < 8; offset = offset + 2) begin
        expect_ar(what, paddr + offset);
        drive_fetch_halfword(packet, offset[2:0]);
      end
    end
  endtask

  task automatic walk_to_fetch;
    input [1023:0] what;
    input [`XLEN-1:0] vaddr;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] leaf_flags;
    input [`XLEN-1:0] inst_beat;
    begin
      expect_ar(what, pte_addr(ROOT_PT, vaddr, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, vaddr, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, vaddr, 2'd0));
      drive_r(pte_for_page(paddr, leaf_flags), RESP_OK);
      drive_fetch_packet(what, paddr, inst_beat);
    end
  endtask

  task automatic walk_to_fetch_page_fault;
    input [1023:0] what;
    input [`XLEN-1:0] vaddr;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] leaf_flags;
    begin
      expect_ar(what, pte_addr(ROOT_PT, vaddr, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, vaddr, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, vaddr, 2'd0));
      drive_r(pte_for_page(paddr, leaf_flags), RESP_OK);
    end
  endtask

  // HW-managed A：取指到 A=0 leaf → 桥经 S_AD_UPDATE 写回 PTE|A，本任务模拟写侧握手 + 校验
  // 写地址=本级 leaf PTE 地址、写数据=置 A 位的 PTE、wstrb 全置。
  task automatic drive_ad_write;
    input [1023:0] what;
    input [`XLEN-1:0] exp_addr;
    input [`XLEN-1:0] exp_wdata;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_awvalid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, ifu_axi_awvalid, 1'b1);
      tb_check1(what, ifu_axi_wvalid, 1'b1);
      if (ifu_axi_awvalid === 1'b1) begin
        tb_check64_local(what, ifu_axi_awaddr, exp_addr);
        tb_check64_local(what, ifu_axi_wdata, exp_wdata);
        tb_check1(what, &ifu_axi_wstrb, 1'b1);
      end
      tick();                     // AW/W 握手(awready/wready=1 → aw_done/w_done)
      ifu_axi_bvalid = 1'b1;
      ifu_axi_bresp = RESP_OK;
      tick();                     // FSM 见 bvalid → 完成 → re-walk 本级
      ifu_axi_bvalid = 1'b0;
    end
  endtask

  // A=0 取指全序: 三级 walk 到 A=0 leaf → 写回 PTE|A → re-walk 本级(读回 A=1) → 取指令。
  task automatic walk_to_fetch_with_ad_update;
    input [1023:0] what;
    input [`XLEN-1:0] vaddr;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] leaf_flags_a0;
    input [`XLEN-1:0] inst_beat;
    reg [`XLEN-1:0] leaf_pte_a0;
    reg [`XLEN-1:0] leaf_pte_a1;
    reg [`XLEN-1:0] l0_leaf_addr;
    begin
      leaf_pte_a0 = pte_for_page(paddr, leaf_flags_a0);
      leaf_pte_a1 = leaf_pte_a0 | PTE_A_BIT_TB;
      l0_leaf_addr = pte_addr(L0_PT, vaddr, 2'd0);
      expect_ar(what, pte_addr(ROOT_PT, vaddr, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, vaddr, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, l0_leaf_addr);
      drive_r(leaf_pte_a0, RESP_OK);          // A=0 leaf → 触发 A 更新
      drive_ad_write(what, l0_leaf_addr, leaf_pte_a1);
      expect_ar(what, l0_leaf_addr);          // re-walk 本级
      drive_r(leaf_pte_a1, RESP_OK);          // 读回 A=1
      drive_fetch_packet(what, paddr, inst_beat);
    end
  endtask

  // T4F：PTE 区域允许隐式 READ、拒绝隐式 WRITE，最终取指 PA 由后续
  // allow-all entry 放行。A=0 leaf 必须返回 instruction access fault，且
  // 不能进入 A-update owner 或呈现任何 AW/W。
  task automatic ptw_ad_write_pmp_deny;
    reg [`XLEN-1:0] leaf_pte_a0;
    begin
      reset_protocol_case();
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      // entry0: TOR [0,0x8180_0000), R-only；entry1: NAPOT all, RWX。
      pmpcfg[0 +: 8] = 8'h09;
      pmpcfg[8 +: 8] = 8'h1f;
      pmpaddr[0 +: `XLEN] = 64'h0000_0000_8180_0000 >> 2;
      pmpaddr[`XLEN +: `XLEN] = {`XLEN{1'b1}};
      ifu_axi_arready = 1'b1;
      leaf_pte_a0 = pte_for_page(USER_PA, PTE_USER_X_NO_ACCESS_FLAGS);

      start_fetch("T4F IFU PTE-write deny request accepted", USER_VA,
                  `PRIV_U);
      expect_ar("T4F IFU root PTE read allowed",
                pte_addr(ROOT_PT, USER_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar("T4F IFU L1 PTE read allowed",
                pte_addr(L1_PT, USER_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar("T4F IFU leaf PTE read allowed",
                pte_addr(L0_PT, USER_VA, 2'd0));

      while (ifu_axi_rready !== 1'b1) tick();
      ifu_axi_rdata = leaf_pte_a0;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      #1;
      tb_check1("T4F IFU final exec PMP remains allowed",
                dut.walk_leaf_current_pmp_fault_w, 1'b0);
      tb_check1("T4F IFU PTE WRITE PMP denies",
                dut.walk_pte_write_pmp_fault_w, 1'b1);
      tb_check1("T4F IFU deny event qualified", dut.walk_ad_write_deny_w,
                1'b1);
      tb_check1("T4F IFU denied PTE emits no AW", ifu_axi_awvalid, 1'b0);
      tb_check1("T4F IFU denied PTE emits no W", ifu_axi_wvalid, 1'b0);
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4F IFU deny never enters A-update",
                dut.state_q == S_AD_UPDATE_TB, 1'b0);
      tb_check1("T4F IFU deny returns response", fetch_rsp_valid, 1'b1);
      tb_check2("T4F IFU deny returns access fault", fetch_rsp_resp1,
                RESP_ACCESS_FAULT);
      tb_check1("T4F IFU deny owns first halfword",
                fetch_rsp_resp0_bytes == 3'd0, 1'b1);
      tb_check1("T4F IFU response still has no AW", ifu_axi_awvalid, 1'b0);
      tb_check1("T4F IFU response still has no W", ifu_axi_wvalid, 1'b0);
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      $display("[T4F-IFU-PTW-PMP-WRITE] read=allow write=deny access-fault aw=0 w=0");
    end
  endtask

  task automatic walk_to_cross_fetch;
    input [1023:0] what;
    begin
      expect_ar(what, pte_addr(ROOT_PT, CROSS_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, CROSS_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, CROSS_VA, 2'd0));
      drive_r(pte_for_page(CROSS_PA0, PTE_USER_X_FLAGS), RESP_OK);

      // 只有首个 2B prefix 成功且证明还需要 offset2 后，bridge 才允许翻译第二页。
      expect_ar(what, CROSS_PA0 + 64'hffe);
      drive_fetch_halfword(CROSS_MERGED_BEAT, 3'd0);

      expect_ar(what, pte_addr(ROOT_PT, CROSS_NEXT_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, CROSS_NEXT_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, CROSS_NEXT_VA, 2'd0));
      drive_r(pte_for_page(CROSS_PA1, PTE_USER_X_FLAGS), RESP_OK);

      expect_ar(what, CROSS_PA1);
      drive_fetch_halfword(CROSS_MERGED_BEAT, 3'd2);
      expect_ar(what, CROSS_PA1 + 64'd2);
      drive_fetch_halfword(CROSS_MERGED_BEAT, 3'd4);
      expect_ar(what, CROSS_PA1 + 64'd4);
      drive_fetch_halfword(CROSS_MERGED_BEAT, 3'd6);
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
      pbmt1_leaf = pte_for_page(USER_PA, PTE_USER_X_FLAGS) | (64'd1 << 61);
      pbmt2_leaf = pte_for_page(USER_PA, PTE_USER_X_FLAGS) | (64'd2 << 61);
      pbmt3_leaf = pte_for_page(USER_PA, PTE_USER_X_FLAGS) | (64'd3 << 61);
      pbmt1_nonleaf =
          pte_for_page(L1_PT, PTE_NONLEAF_FLAGS) | (64'd1 << 61);
      napot_leaf =
          (pte_for_page(USER_PA, PTE_USER_X_FLAGS) & ~(64'hf << 10)) |
          (64'h8 << 10) | `SV39_PTE_N;
      napot_bad_leaf =
          (pte_for_page(USER_PA, PTE_USER_X_FLAGS) & ~(64'hf << 10)) |
          (64'h7 << 10) | `SV39_PTE_N;
      napot_nonleaf = pte_for_page(L1_PT, PTE_NONLEAF_FLAGS) | `SV39_PTE_N;

      tb_check1("fetch PBMT=1 leaf faults while Svpbmt disabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("fetch PBMT=1 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt1_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("fetch PBMT=2 leaf is legal when Svpbmt enabled",
                dut.pte_reserved_fault(pbmt2_leaf, 1'b1, 2'd0), 1'b0);
      tb_check1("fetch PBMT=3 leaf remains reserved",
                dut.pte_reserved_fault(pbmt3_leaf, 1'b1, 2'd0), 1'b1);
      tb_check1("fetch non-leaf PBMT remains reserved",
                dut.pte_reserved_fault(pbmt1_nonleaf, 1'b1, 2'd1), 1'b1);
      tb_check1("fetch Svnapot 64KiB leaf is legal",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd0), 1'b0);
      tb_check1("fetch Svnapot bad ppn encoding faults",
                dut.pte_reserved_fault(napot_bad_leaf, 1'b0, 2'd0), 1'b1);
      tb_check1("fetch Svnapot non-leaf faults",
                dut.pte_reserved_fault(napot_nonleaf, 1'b0, 2'd1), 1'b1);
      tb_check1("fetch Svnapot level1 leaf faults",
                dut.pte_reserved_fault(napot_leaf, 1'b0, 2'd1), 1'b1);
      tb_check64_local("fetch Svnapot PA uses VA low PPN bits",
                       dut.leaf_paddr(napot_leaf, USER_VA, 2'd0), USER_PA);
    end
  endtask

  task automatic expect_rsp;
    input [1023:0] what;
    input [1:0] exp_resp0;
    input [1:0] exp_resp1;
    input [`XLEN-1:0] exp_inst_beat;
    integer waits;
    begin
      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 20)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, fetch_rsp_valid, 1'b1);
      if (fetch_rsp_valid === 1'b1) begin
        tb_check2(what, fetch_rsp_resp0, exp_resp0);
        tb_check2(what, fetch_rsp_resp1, exp_resp1);
        if (exp_resp0 == RESP_OK) begin
          tb_check32_local(what, fetch_rsp_inst0, exp_inst_beat[`INST_W-1:0]);
        end
        if (exp_resp1 == RESP_OK) begin
          tb_check32_local(what, fetch_rsp_inst1, exp_inst_beat[`XLEN-1:`INST_W]);
        end
      end
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();
    check_svpbmt_pte_reserved_policy();

    start_fetch("user fetch request accepted", USER_VA, `PRIV_U);
    priv_mode = `PRIV_S;
    walk_to_fetch("user fetch keeps request privilege", USER_VA, USER_PA,
                  PTE_USER_X_FLAGS, USER_INST_BEAT);
    expect_rsp("user fetch response ok after privilege drift",
               RESP_OK, RESP_OK, USER_INST_BEAT);

    start_fetch("supervisor fetch request accepted", SUP_VA, `PRIV_S);
    priv_mode = `PRIV_U;
    walk_to_fetch("supervisor fetch keeps request privilege", SUP_VA, SUP_PA,
                  PTE_SUP_X_FLAGS, SUP_INST_BEAT);
    expect_rsp("supervisor fetch response ok after privilege drift",
               RESP_OK, RESP_OK, SUP_INST_BEAT);

    start_fetch("supervisor cannot execute user page", USER_VA, `PRIV_S);
    expect_rsp("itlb permissions use current request privilege",
               RESP_OK, RESP_PAGE_FAULT, {`XLEN{1'b0}});

    // HW-managed A（Svadu，对齐 NEMU）：取指到 A=0 可执行页不再 page fault，
    // 而是经 S_AD_UPDATE 写回 PTE 置 A 位、re-walk 后正常取指成功。
    start_fetch("user fetch with A=0 request accepted", NO_ACCESS_VA,
                `PRIV_U);
    walk_to_fetch_with_ad_update("user fetch A=0 triggers HW A update",
                                 NO_ACCESS_VA, NO_ACCESS_PA,
                                 PTE_USER_X_NO_ACCESS_FLAGS, USER_INST_BEAT);
    expect_rsp("user fetch A=0 succeeds after HW A update",
               RESP_OK, RESP_OK, USER_INST_BEAT);

    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    tick();

    ptw_ad_write_pmp_deny();

    start_fetch("cross-page user fetch request accepted", CROSS_VA, `PRIV_U);
    walk_to_cross_fetch("cross-page packet uses translated next page");

    // T3X dirty-owner replacement: 旧跨页 slow path 在 fetch_data_q 留下完整非零
    // packet。S_RESP 消费旧响应同拍接收 non-canonical 新请求；接收拍不能清宽
    // scratch，而 S_CACHE_READ 必须在新请求 fault 判决前清净全部 payload/split。
    priv_mode = `PRIV_U;
    satp = SATP_VALUE;
    fetch_req_pc = NONCANON_VA;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tb_check1("dirty replacement old response valid", fetch_rsp_valid, 1'b1);
    tb_check2("dirty replacement old resp0", fetch_rsp_resp0, RESP_OK);
    tb_check2("dirty replacement old resp1", fetch_rsp_resp1, RESP_OK);
    tb_check32_local("dirty replacement old inst0", fetch_rsp_inst0,
                     CROSS_MERGED_BEAT[`INST_W-1:0]);
    tb_check32_local("dirty replacement old inst1", fetch_rsp_inst1,
                     CROSS_MERGED_BEAT[`XLEN-1:`INST_W]);
    tb_check1("dirty replacement old split is complete",
              fetch_rsp_resp0_bytes == 3'd4, 1'b1);
    tb_check1("dirty replacement accepts noncanonical request",
              fetch_req_ready, 1'b1);
    tb_check1("dirty replacement request fires", dut.fetch_req_fire_w, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("dirty replacement reaches cache-read owner",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check64_local("dirty packet survives immutable-context capture",
                     dut.fetch_data_q, CROSS_MERGED_BEAT);
    tb_check1("dirty replacement cache-read emits no AR", ifu_axi_arvalid, 1'b0);
    tick();
    #1;
    tb_check1("dirty replacement reaches lookup", dut.state_q == S_LOOKUP_TB,
              1'b1);
    tb_check64_local("cache-read clears dirty packet before fault lookup",
                     dut.fetch_data_q, {`XLEN{1'b0}});
    tb_check1("noncanonical lookup emits no AR", ifu_axi_arvalid, 1'b0);
    tick();
    #1;
    tb_check1("noncanonical replacement response valid", fetch_rsp_valid, 1'b1);
    tb_check2("noncanonical replacement resp0", fetch_rsp_resp0, RESP_OK);
    tb_check2("noncanonical replacement resp1", fetch_rsp_resp1,
              RESP_PAGE_FAULT);
    tb_check32_local("noncanonical replacement inst0 is zero",
                     fetch_rsp_inst0, {`INST_W{1'b0}});
    tb_check32_local("noncanonical replacement inst1 is zero",
                     fetch_rsp_inst1, {`INST_W{1'b0}});
    tb_check1("noncanonical replacement split is zero",
              fetch_rsp_resp0_bytes == 3'd0, 1'b1);
    tb_check1("noncanonical response never emits AR", ifu_axi_arvalid, 1'b0);
    $display("[T3X-IFU-DIRTY-FIRST-FAULT] replacement clears stale packet and returns split=0 without AR");
    fetch_rsp_ready = 1'b1;
    tick();
    fetch_rsp_ready = 1'b0;

    // ===== T3R fetch request/response 双侧非穿透边界 =====
    // 预热两个 M 模式直取包(miss+fill)
    start_fetch("boundary warm pc1 accepted", FUSION_PC1, `PRIV_M);
    drive_fetch_packet("boundary warm pc1 goes axi", FUSION_PC1, FUSION_BEAT1);
    expect_rsp("boundary warm pc1 resp", RESP_OK, RESP_OK, FUSION_BEAT1);
    start_fetch("boundary warm pc2 accepted", FUSION_PC2, `PRIV_M);
    drive_fetch_packet("boundary warm pc2 goes axi", FUSION_PC2, FUSION_BEAT2);
    expect_rsp("boundary warm pc2 resp", RESP_OK, RESP_OK, FUSION_BEAT2);

    // C0: IDLE 只捕获请求，不用 live PC 开 SRAM 读口。
    priv_mode = `PRIV_M;
    satp = 64'h1111_2222_3333_4444;
    svpbmt_en = 1'b1;
    fetch_req_pc = FUSION_PC1;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tb_check1("boundary refetch pc1 ready", fetch_req_ready, 1'b1);
    tb_check1("idle keeps physical read window closed",
              dut.fetch_cache_read_window_w, 1'b0);
    tb_check1("idle fire captures request",
              dut.fetch_req_fire_w, 1'b1);
    tb_check1("idle capture does not enable payload SRAM",
              dut.u_fetch_packet_cache.sram_en_w, 1'b0);
    tick();                       // C0 fire PC1 → C1 S_CACHE_READ

    // C1: 只用 captured q 发射同步读；live 请求改成 PC2 也不得早 accept。
    fetch_req_pc = FUSION_PC2;
    satp = 64'h2222_3333_4444_5555;
    svpbmt_en = 1'b0;
    #1;
    tb_check1("captured request reaches cache read",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check1("cache read opens physical window",
              dut.fetch_cache_read_window_w, 1'b1);
    tb_check1("cache read is semantic lookup",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tb_check64_local("cache read uses captured pc",
                     dut.u_fetch_packet_cache.lookup_pc_i, FUSION_PC1);
    tb_check64_local("Bridge owner output uses captured pc",
                     fetch_req_owner_pc, FUSION_PC1);
    tb_check64_local("candidate captures request-fire pc",
                     dut.fetch_ctx_candidate_pc_q, FUSION_PC1);
    tb_check64_local("exec still owns previous transaction in cache-read",
                     dut.fetch_ctx_exec_pc_q, FUSION_PC2);
    tb_check1("captured context keeps paging off", dut.paging_q, 1'b0);
    tb_check2("captured context keeps privilege", dut.req_priv_q, `PRIV_M);
    tb_check64_local("captured context keeps SATP", dut.req_satp_q,
                     64'h1111_2222_3333_4444);
    tb_check1("captured context keeps Svpbmt", dut.req_svpbmt_en_q, 1'b1);
    // T3X physical contract: accept 只锁不可重建 context。此时仍能看到上一
    // owner 的非零 scratch，证明 frontend ready/control 没有在 fire 拍驱动
    // 宽 paddr/data D mux；本拍末由 registered S_CACHE_READ 统一初始化。
    tb_check64_local("accept defers paddr scratch init to cache-read owner",
                     dut.paddr0_q, FUSION_PC2);
    tb_check64_local("accept defers data scratch init to cache-read owner",
                     dut.fetch_data_q, FUSION_BEAT2);
    tb_check1("cache read cannot accept live pc2", fetch_req_ready, 1'b0);
    tb_check1("cache read cannot expose response", fetch_rsp_valid, 1'b0);
    tick();                       // C1 read PC1 → C2 S_LOOKUP

    // C2: 只判决并在拍尾落 payload，cache 内部结果不得穿透到端口。
    #1;
    tb_check1("cache result reaches lookup decision",
              dut.state_q == S_LOOKUP_TB, 1'b1);
    tb_check1("lookup closes physical read window",
              dut.fetch_cache_read_window_w, 1'b0);
    tb_check64_local("candidate may advance to live pc after cache-read",
                     dut.fetch_ctx_candidate_pc_q, FUSION_PC2);
    tb_check64_local("cache-read hands request pc into frozen exec",
                     dut.fetch_ctx_exec_pc_q, FUSION_PC1);
    tb_check64_local("owner handoff keeps request pc stable",
                     fetch_req_owner_pc, FUSION_PC1);
    tb_check1("exec handoff keeps captured paging off",
              dut.fetch_ctx_exec_paging_q, 1'b0);
    tb_check2("exec handoff keeps captured privilege",
              dut.fetch_ctx_exec_priv_q, `PRIV_M);
    tb_check64_local("exec handoff keeps captured SATP",
                     dut.fetch_ctx_exec_satp_q,
                     64'h1111_2222_3333_4444);
    tb_check1("exec handoff keeps captured Svpbmt",
              dut.fetch_ctx_exec_svpbmt_en_q, 1'b1);
    tb_check64_local("cache-read owner initializes paddr from captured pc",
                     dut.paddr0_q, FUSION_PC1);
    tb_check64_local("cache-read owner clears stale data before lookup",
                     dut.fetch_data_q, {`XLEN{1'b0}});
    $display("[T3X-IFU-INIT-BOUNDARY] stale paddr/data survive accept and are initialized before lookup");
    tb_check1("lookup cannot accept live pc2", fetch_req_ready, 1'b0);
    tb_check1("lookup cannot expose combinational hit", fetch_rsp_valid, 1'b0);
    tick();                       // C2 落 PC1 payload → C3 S_RESP

    // C3: registered PC1 response 与 PC2 replacement request 同拍 fire。
    #1;
    tb_check1("registered pc1 response valid", fetch_rsp_valid, 1'b1);
    tb_check64_local("old response still sees old owner",
                     fetch_req_owner_pc, FUSION_PC1);
    tb_check32_local("registered pc1 response payload", fetch_rsp_inst0,
                     FUSION_BEAT1[`INST_W-1:0]);
    tb_check1("response replacement accepts pc2", fetch_req_ready, 1'b1);
    tb_check1("response replacement request fires", dut.fetch_req_fire_w, 1'b1);
    tb_check1("response replacement still does not read SRAM",
              dut.fetch_cache_read_window_w, 1'b0);
    tick();                       // rsp1 fire + capture PC2 → C4 S_CACHE_READ
    fetch_req_valid = 1'b0;
    fetch_req_pc = FUSION_PC3_COLD; // 改 live 值，必须不影响已捕获 PC2
    priv_mode = `PRIV_U;
    satp = SATP_VALUE;
    svpbmt_en = 1'b1;
    #1;
    tb_check1("replacement reaches cache read",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check64_local("replacement pc remains captured",
                     dut.u_fetch_packet_cache.lookup_pc_i, FUSION_PC2);
    tb_check64_local("replacement atomically swaps Bridge owner",
                     fetch_req_owner_pc, FUSION_PC2);
    tb_check64_local("replacement candidate owns new pc in cache-read",
                     dut.fetch_ctx_candidate_pc_q, FUSION_PC2);
    tb_check64_local("replacement exec retains old response owner for one stage",
                     dut.fetch_ctx_exec_pc_q, FUSION_PC1);
    tb_check2("replacement keeps captured privilege", dut.req_priv_q, `PRIV_M);
    tb_check64_local("replacement keeps captured SATP", dut.req_satp_q,
                     64'h2222_3333_4444_5555);
    tb_check1("replacement keeps captured Svpbmt", dut.req_svpbmt_en_q, 1'b0);
    tb_check1("replacement read has no stale response", fetch_rsp_valid, 1'b0);
    tick();                       // read PC2 → lookup
    #1;
    tb_check1("replacement lookup has no early response", fetch_rsp_valid, 1'b0);
    tb_check64_local("replacement live poison reaches candidate only",
                     dut.fetch_ctx_candidate_pc_q, FUSION_PC3_COLD);
    tb_check64_local("replacement cache-read freezes new exec pc",
                     dut.fetch_ctx_exec_pc_q, FUSION_PC2);
    tb_check64_local("replacement owner handoff stays on new pc",
                     fetch_req_owner_pc, FUSION_PC2);
    tick();                       // lookup → registered response
    #1;
    tb_check1("replacement registered response valid", fetch_rsp_valid, 1'b1);
    tb_check32_local("replacement response owns captured pc2", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tick();                       // consume PC2, no request → idle
    fetch_rsp_ready = 1'b0;
    priv_mode = `PRIV_M;

    // 响应反压：registered valid/payload 必须稳定，stall 期间不预读 live 请求。
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    #1;
    tick();                       // capture
    fetch_req_valid = 1'b0;
    tick();                       // read
    tick();                       // lookup 落 response
    #1;
    tb_check1("stalled registered response valid", fetch_rsp_valid, 1'b1);
    tb_check32_local("stalled registered response payload", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tb_check1("stalled response rejects next request", fetch_req_ready, 1'b0);
    tb_check1("stalled response keeps SRAM closed",
              dut.fetch_cache_read_window_w, 1'b0);
    fetch_req_pc = FUSION_PC3_COLD;
    priv_mode = `PRIV_U;
    satp = SATP_VALUE ^ 64'h0000_0000_0000_1234;
    svpbmt_en = 1'b1;
    tick();
    #1;
    tb_check1("stalled response remains valid", fetch_rsp_valid, 1'b1);
    tb_check32_local("stalled response remains stable", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tb_check64_local("stalled response keeps active owner",
                     fetch_req_owner_pc, FUSION_PC2);
    fetch_rsp_ready = 1'b1;
    tick();                       // consume stalled response
    fetch_rsp_ready = 1'b0;
    priv_mode = `PRIV_M;
    satp = {`XLEN{1'b0}};
    svpbmt_en = 1'b0;

    // 判决拍的异 window invalidate 不得破坏精确 hit，但仍禁止组合响应。
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();                       // capture → read
    fetch_req_valid = 1'b0;
    tick();                       // read → lookup
    invalidate_valid = 1'b1;
    invalidate_addr = 64'h0000_0000_8000_5000;  // 不同 window 的失效
    #1;
    tb_check1("different-window decision has no early rsp", fetch_rsp_valid, 1'b0);
    tick();                       // exact hit 落寄存
    invalidate_valid = 1'b0;
    #1;
    tb_check1("different-window hit delivered registered", fetch_rsp_valid, 1'b1);
    tb_check32_local("different-window hit payload intact", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tick();                       // 消费
    fetch_rsp_ready = 1'b0;

    // invalidate 同 window 撞判决拍: 精确 hit 被杀 → 走 miss(AR), 不交付 stale 包
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();                       // capture → read
    fetch_req_valid = 1'b0;
    tick();                       // read → lookup
    invalidate_valid = 1'b1;
    invalidate_addr = FUSION_PC2;  // 同 window 失效(窗口②)
    #1;
    tb_check1("same-window invalidate kills hit", fetch_rsp_valid, 1'b0);
    tb_check1("invalidated packet uses registered miss path",
              ifu_axi_arvalid, 1'b0);
    tick();                       // lookup miss → S_AR0
    invalidate_valid = 1'b0;
    drive_fetch_packet("refetch packet", FUSION_PC2, FUSION_BEAT2);
    expect_rsp("refetched packet resp", RESP_OK, RESP_OK, FUSION_BEAT2);

    // invalidate 同 window 撞 SRAM read 拍：即使判决拍 pulse 已拉低，也必须保留 poison。
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();                       // capture → read
    fetch_req_valid = 1'b0;
    invalidate_valid = 1'b1;
    invalidate_addr = FUSION_PC2;
    #1;
    tb_check1("read-window invalidate occurs with cache issue",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tick();                       // read + invalidate → lookup
    invalidate_valid = 1'b0;
    #1;
    tb_check1("read-window poison kills stale hit", dut.cache_hit_w, 1'b0);
    tb_check1("read-window poison emits no response", fetch_rsp_valid, 1'b0);
    tick();                       // lookup miss → S_AR0
    drive_fetch_packet("read-window refetch packet", FUSION_PC2, FUSION_BEAT2);
    expect_rsp("read-window refetched packet resp",
               RESP_OK, RESP_OK, FUSION_BEAT2);

    // miss 拍 ready=0: 冷地址判决拍不受理新请求(1RW/上下文单套防线)
    fetch_req_pc = FUSION_PC3_COLD;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();                       // capture → read
    fetch_req_valid = 1'b0;
    tick();                       // read → lookup(miss)
    #1;
    tb_check1("miss beat rsp not valid", fetch_rsp_valid, 1'b0);
    tb_check1("miss beat not ready", fetch_req_ready, 1'b0);
    tick();                       // lookup miss → S_AR0
    drive_fetch_packet("miss beat direct AR", FUSION_PC3_COLD, FUSION_BEAT3);
    expect_rsp("miss path resp unchanged", RESP_OK, RESP_OK, FUSION_BEAT3);

    // ===== T4A PTW READ authorization：deny 判决必须寄存并抑制 AR =====
    reset_protocol_case();
    pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
    pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
    ifu_axi_arready = 1'b0;
    start_fetch("PTW deny request accepted", USER_VA, `PRIV_U);
    tick();                       // S_CACHE_READ -> S_LOOKUP
    tick();                       // S_LOOKUP -> S_WALK_CHECK
    tick();                       // S_WALK_CHECK -> S_WALK_AR
    #1;
    tb_check1("PTW deny reaches registered AR decision",
              dut.state_q == S_WALK_AR_TB, 1'b1);
    tb_check64_local("PTW deny registers exact PTE address",
                     dut.walk_pte_addr_q,
                     pte_addr(ROOT_PT, USER_VA, 2'd2));
    tb_check1("PTW deny registers read-side PMP fault",
              dut.walk_pte_pmp_fault_q, 1'b1);
    tb_check1("PTW deny suppresses ARVALID", ifu_axi_arvalid, 1'b0);
    tick();                       // registered fault -> S_RESP
    tb_check1("PTW deny returns response", fetch_rsp_valid, 1'b1);
    tb_check2("PTW deny returns access fault", fetch_rsp_resp1,
              RESP_ACCESS_FAULT);
    tb_check1("PTW deny faults first halfword",
              fetch_rsp_resp0_bytes == 3'd0, 1'b1);
    fetch_rsp_ready = 1'b1;
    tick();
    fetch_rsp_ready = 1'b0;

    // ===== IFU read AR VALID-until-fire：flush 只能 drop 语义，不能撤 owner =====
    // Walk AR：先形成真实 stall，再 pulse/repeat flush。DROP owner 必须保持
    // 8B/data metadata 与 PTE 地址；ready 后先 fire，再在 S_DRAIN 吞错误 R。
    reset_protocol_case();
    ifu_axi_arready = 1'b0;
    start_fetch("stalled walk AR request accepted", USER_VA, `PRIV_U);
    expect_ar("stalled walk AR exact address",
              pte_addr(ROOT_PT, USER_VA, 2'd2));
    mmu_flush = 1'b1;
    #1;
    tb_check1("walk AR remains valid on flush", ifu_axi_arvalid, 1'b1);
    tb_check64_local("walk AR address remains stable on flush",
                     ifu_axi_araddr, pte_addr(ROOT_PT, USER_VA, 2'd2));
    tb_check1("walk ARSIZE remains 8B on flush",
              ifu_axi_arsize == 3'd3, 1'b1);
    tb_check1("walk ARPROT remains data on flush",
              ifu_axi_arprot == 3'b000, 1'b1);
    tick();
    mmu_flush = 1'b0;
    #1;
    tb_check1("walk AR enters dropped owner",
              dut.state_q == S_WALK_AR_DROP_TB, 1'b1);
    tb_check1("walk dropped owner keeps valid", ifu_axi_arvalid, 1'b1);
    tb_check1("walk dropped owner waits before RREADY", ifu_axi_rready, 1'b0);
    tb_check1("walk dropped owner emits no response", fetch_rsp_valid, 1'b0);
    tb_check64_local("walk dropped owner keeps PTE address",
                     ifu_axi_araddr, pte_addr(ROOT_PT, USER_VA, 2'd2));
    // Repeated flush while still stalled must be idempotent.
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    tb_check1("repeated flush keeps walk dropped owner",
              dut.state_q == S_WALK_AR_DROP_TB, 1'b1);
    tb_check1("repeated flush keeps walk ARVALID", ifu_axi_arvalid, 1'b1);
    ifu_axi_arready = 1'b1;
    tick();                       // dropped AR fire -> S_DRAIN
    ifu_axi_arready = 1'b0;
    tb_check1("walk dropped AR fire enters drain",
              dut.state_q == S_DRAIN_TB, 1'b1);
    tb_check1("walk dropped AR drain raises RREADY", ifu_axi_rready, 1'b1);
    drive_r(64'hdead_beef_dead_beef, RESP_ACCESS_FAULT);
    tb_check1("walk dropped R returns idle", fetch_req_ready, 1'b1);
    tb_check1("walk dropped R never returns fetch response",
              fetch_rsp_valid, 1'b0);

    // Direct instruction AR uses a different payload dependency set.  Poison
    // every live context input after flush; DROP must retain old exec/scratch.
    reset_protocol_case();
    ifu_axi_arready = 1'b0;
    start_fetch("stalled direct AR request accepted", FUSION_PC3_COLD,
                `PRIV_M);
    expect_ar("stalled direct AR exact address", FUSION_PC3_COLD);
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    fetch_req_pc = USER_VA;
    priv_mode = `PRIV_U;
    satp = SATP_VALUE;
    svpbmt_en = 1'b1;
    #1;
    tb_check1("direct AR enters dropped owner",
              dut.state_q == S_FETCH_AR_DROP_TB, 1'b1);
    tb_check1("direct dropped owner keeps valid", ifu_axi_arvalid, 1'b1);
    tb_check64_local("direct dropped owner keeps address",
                     ifu_axi_araddr, FUSION_PC3_COLD);
    tb_check1("direct dropped owner keeps 2B size",
              ifu_axi_arsize == 3'd1, 1'b1);
    tb_check1("direct dropped owner keeps exec protection",
              ifu_axi_arprot == 3'b100, 1'b1);
    tick();
    tb_check64_local("live poison cannot move dropped AR address",
                     ifu_axi_araddr, FUSION_PC3_COLD);
    ifu_axi_arready = 1'b1;
    tick();
    ifu_axi_arready = 1'b0;
    tb_check1("direct dropped AR fire enters drain",
              dut.state_q == S_DRAIN_TB, 1'b1);
    drive_r(64'hfeed_face_cafe_beef, RESP_OK);
    tb_check1("direct dropped R returns idle", fetch_req_ready, 1'b1);
    tb_check1("direct dropped R never fills packet cache",
              dut.fetch_cache_fill_valid_w, 1'b0);

    // Flush 与 READY 同拍：此前 stall 的 AR 仍须完成唯一一次 fire，不能回
    // IDLE 丢 owner，也不能错误等待一个从未发出的 R。
    reset_protocol_case();
    ifu_axi_arready = 1'b0;
    start_fetch("flush-ready AR request accepted", FUSION_PC3_COLD,
                `PRIV_M);
    expect_ar("flush-ready AR exact address", FUSION_PC3_COLD);
    mmu_flush = 1'b1;
    ifu_axi_arready = 1'b1;
    #1;
    tb_check1("flush-ready keeps ARVALID", ifu_axi_arvalid, 1'b1);
    tick();                       // same-cycle AR fire -> S_DRAIN
    mmu_flush = 1'b0;
    ifu_axi_arready = 1'b0;
    tb_check1("flush-ready AR enters drain",
              dut.state_q == S_DRAIN_TB, 1'b1);
    drive_r(64'h0, RESP_OK);
    tb_check1("flush-ready drain completes", fetch_req_ready, 1'b1);
    ifu_axi_arready = 1'b1;

    // ===== AXI4 化 S1: mmu_flush 在飞读自吞(S_DRAIN)定向用例 =====
    // 先清 ITLB/cache(前序用例热态), 保证下面 fetch 走完整 walk
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    tick();
    // walk 中途(等 R 态)flush: 桥不再依赖 xbar abort, 自己保持 rready 吞 R 后回 IDLE
    start_fetch("drain case walk fetch accepted", USER_VA, `PRIV_U);
    expect_ar("drain case walk first AR", pte_addr(ROOT_PT, USER_VA, 2'd2));
    // AR 已 fire, 桥在 S_WALK_R 等 R —— 此拍打 mmu_flush
    mmu_flush = 1'b1;
    #1;
    tb_check1("drain: no new AR during flush", ifu_axi_arvalid, 1'b0);
    tick();
    mmu_flush = 1'b0;
    #1;
    // 桥应在 S_DRAIN: ready 压住、rready 保持
    tb_check1("drain: req not ready while draining", fetch_req_ready, 1'b0);
    tb_check1("drain: rready held to swallow R", ifu_axi_rready, 1'b1);
    tb_check1("drain: no rsp during drain", fetch_rsp_valid, 1'b0);
    // 残 R 到达 → 吞掉回 IDLE
    ifu_axi_rvalid = 1'b1;
    ifu_axi_rdata = 64'hbad0_bad0_bad0_bad0;
    tick();
    ifu_axi_rvalid = 1'b0;
    #1;
    tb_check1("drain: back to ready after swallow", fetch_req_ready, 1'b1);
    tb_check1("drain: swallowed rsp not delivered", fetch_rsp_valid, 1'b0);
    // 后续正常取指不受影响
    start_fetch("post-drain fetch accepted", USER_VA, `PRIV_U);
    walk_to_fetch("post-drain walk works", USER_VA, USER_PA,
                  PTE_USER_X_FLAGS, USER_INST_BEAT);
    expect_rsp("post-drain rsp ok", RESP_OK, RESP_OK, USER_INST_BEAT);
    // flush 拍 R 同拍到达: 本拍即消费, 不进 DRAIN 直接回 IDLE
    start_fetch("same-beat case fetch accepted", CROSS_VA, `PRIV_U);
    expect_ar("same-beat cached-translation data AR", CROSS_PA0 + 64'hffe);
    mmu_flush = 1'b1;
    ifu_axi_rvalid = 1'b1;
    ifu_axi_rdata = 64'h0;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_rvalid = 1'b0;
    #1;
    tb_check1("same-beat flush+R back to idle", fetch_req_ready, 1'b1);

    // ===== IFU-AXI-G1：flush 不得撤销已经呈现/部分接受的 A-update write =====
    // AW-first：flush 后必须补齐 W 并消费 B；B error 属于已 drop 的旧请求，不得回 fault。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_1234_004f);
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b0;
    tick();
    ifu_axi_awready = 1'b0;
    tb_check1("A-update AW-first accepted", dut.aw_done_q, 1'b1);
    tb_check1("A-update AW-first leaves W pending", dut.w_done_q, 1'b0);
    // Poison every live context field while the write owner is stalled.  T4A
    // candidate must continue tracking it, but frozen exec/AW provenance must
    // remain on the accepted USER_VA request across flush and channel drain.
    fetch_req_pc = CROSS_VA;
    priv_mode = `PRIV_U;
    satp = SATP_VALUE;
    svpbmt_en = 1'b1;
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    #1;
    tb_check1("flush keeps A-update write owner", dut.state_q == S_AD_UPDATE_TB, 1'b1);
    tb_check1("flush preserves accepted AW", dut.aw_done_q, 1'b1);
    tb_check1("flush keeps missing W valid", ifu_axi_wvalid, 1'b1);
    tb_check1("flush keeps BREADY", ifu_axi_bready, 1'b1);
    tb_check64_local("A-update poison reaches candidate only",
                     dut.fetch_ctx_candidate_pc_q, CROSS_VA);
    tb_check64_local("A-update flush retains exec PC",
                     dut.fetch_ctx_exec_pc_q, USER_VA);
    tb_check2("A-update flush retains exec privilege",
              dut.fetch_ctx_exec_priv_q, `PRIV_M);
    tb_check64_local("A-update flush retains exec SATP",
                     dut.fetch_ctx_exec_satp_q, {`XLEN{1'b0}});
    tb_check1("A-update flush retains exec Svpbmt",
              dut.fetch_ctx_exec_svpbmt_en_q, 1'b0);
    tb_check64_local("A-update flush retains owner PC",
                     fetch_req_owner_pc, USER_VA);
    tb_check64_local("A-update flush retains AWADDR",
                     ifu_axi_awaddr, pte_addr(L0_PT, USER_VA, 2'd0));
    tb_check64_local("flush preserves W payload", ifu_axi_wdata,
                     64'h0000_0000_1234_004f);
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_wready = 1'b0;
    tb_check1("post-flush W accepted", dut.w_done_q, 1'b1);
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    check_dropped_write_quiet("AW-first flush drains to IDLE");

    // W-first 对称覆盖；flush 与最后缺失 AW 同拍，fire 必须被记账。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_5678_004f);
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_wready = 1'b0;
    tb_check1("A-update W-first accepted", dut.w_done_q, 1'b1);
    mmu_flush = 1'b1;
    ifu_axi_awready = 1'b1;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_awready = 1'b0;
    #1;
    tb_check1("flush+last AW keeps owner", dut.state_q == S_AD_UPDATE_TB, 1'b1);
    tb_check1("flush+last AW records fire", dut.aw_done_q, 1'b1);
    tb_check1("flush+last AW preserves prior W", dut.w_done_q, 1'b1);
    tb_check1("both channels done waits B", ifu_axi_bready, 1'b1);
    ifu_axi_bvalid = 1'b1;
    tick();
    ifu_axi_bvalid = 1'b0;
    check_dropped_write_quiet("W-first flush drains to IDLE");

    // accepted_next 承重边界：AW 已完成，flush + 最后 W fire + B fire 全同拍。
    // 下游正常 AXI 通常在 W fire 后才给 B；本例是防御性压力测试，确保 completion 公式
    // 不被 flush 分支吞掉，并钉住同拍有效的 accepted_next 语义。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_789a_004f);
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b0;
    tick();
    ifu_axi_awready = 1'b0;
    tb_check1("same-beat setup AW accepted", dut.aw_done_q, 1'b1);
    mmu_flush = 1'b1;
    ifu_axi_wready = 1'b1;
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_wready = 1'b0;
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    check_dropped_write_quiet("flush+last-W+B completes to IDLE");

    // 两通道均被反压时 flush 仍不能撤 valid/payload；重复 flush 必须幂等。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_9abc_004f);
    mmu_flush = 1'b1;
    repeat (2) begin
      tick();
      #1;
      tb_check1("repeated flush keeps AW valid", ifu_axi_awvalid, 1'b1);
      tb_check1("repeated flush keeps W valid", ifu_axi_wvalid, 1'b1);
      tb_check1("repeated flush keeps BREADY", ifu_axi_bready, 1'b1);
      tb_check64_local("repeated flush keeps AWADDR", ifu_axi_awaddr,
                       pte_addr(L0_PT, USER_VA, 2'd0));
      tb_check64_local("repeated flush keeps WDATA", ifu_axi_wdata,
                       64'h0000_0000_9abc_004f);
    end
    mmu_flush = 1'b0;
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b0;
    tb_check1("repeated-flush AW accepted", dut.aw_done_q, 1'b1);
    tb_check1("repeated-flush W accepted", dut.w_done_q, 1'b1);
    // flush 与 B 同拍：B 完成有效，但语义 drop 胜出，不能 re-walk。
    mmu_flush = 1'b1;
    ifu_axi_bvalid = 1'b1;
    tick();
    mmu_flush = 1'b0;
    ifu_axi_bvalid = 1'b0;
    check_dropped_write_quiet("flush+B drains to IDLE");

    // 无 flush 的 B error 仍必须走原 access-fault 路径，证明 drop 没吞正常错误。
    reset_protocol_case();
    seed_ad_update(64'h0000_0000_def0_004f);
    ifu_axi_awready = 1'b1;
    ifu_axi_wready = 1'b1;
    tick();
    ifu_axi_awready = 1'b0;
    ifu_axi_wready = 1'b0;
    ifu_axi_bvalid = 1'b1;
    ifu_axi_bresp = 2'b10;
    tick();
    ifu_axi_bvalid = 1'b0;
    ifu_axi_bresp = RESP_OK;
    #1;
    tb_check1("non-flushed B error enters response", dut.state_q == S_RESP_TB, 1'b1);
    tb_check2("non-flushed B error successful-prefix resp0", fetch_rsp_resp0, RESP_OK);
    tb_check2("non-flushed B error resp1", fetch_rsp_resp1, RESP_ACCESS_FAULT);

    // T3W registered ITLB/PMP owner boundary: a flush on the physical
    // S_CACHE_READ edge must drop both the lookup and its temporal assertion
    // shadow.  Keep this after cache-hit tests because mmu_flush deliberately
    // clears the fetch packet cache.  A one-cycle pulse is important: stale
    // checker ownership would otherwise fail only on the next unflushed edge.
    reset_protocol_case();
    fetch_req_pc = FUSION_PC1;
    fetch_req_valid = 1'b1;
    #1;
    tb_check1("cache-read flush setup accepts request", fetch_req_ready, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    #1;
    tb_check1("cache-read flush setup reaches boundary",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    mmu_flush = 1'b1;
    tick();
    mmu_flush = 1'b0;
    #1;
    tb_check1("cache-read flush drops request to idle",
              dut.state_q == S_IDLE_TB, 1'b1);
    tb_check1("cache-read flush exposes no response", fetch_rsp_valid, 1'b0);
    tick();
    tb_check1("cache-read one-shot flush leaves checker idle",
              dut.state_q == S_IDLE_TB, 1'b1);

    tb_finish("tb_ooo_fetch_axi_bridge");
  end
endmodule
