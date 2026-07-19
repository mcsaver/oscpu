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
  reg tb_decode_follow_en;
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
  wire [`XLEN-1:0] tb_dec0_pc;
  wire [`XLEN-1:0] tb_dec0_next_pc;
  wire [`INST_W-1:0] tb_dec0_inst;
  wire [1:0] tb_dec0_resp;
  wire [`XLEN-1:0] tb_dec1_pc;
  wire [`XLEN-1:0] tb_dec1_next_pc;
  wire [`INST_W-1:0] tb_dec1_inst;
  wire [1:0] tb_dec1_resp;
  wire [`XLEN-1:0] tb_packet_next_pc;
  wire [`XLEN-1:0] fetch_req_pc_to_dut =
      (tb_decode_follow_en && fetch_rsp_valid) ?
      tb_packet_next_pc : fetch_req_pc;
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
  localparam [3:0] S_AR0_TB = 4'd3;
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
  localparam [`XLEN-1:0] SATP_ASID1 =
      SATP_VALUE | 64'h0000_1000_0000_0000;
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
  // Directed II=1 contexts use distinct FPC and ITLB indices.  U/ASID0 owns
  // a two-RVC 4B footprint; S/ASID1 owns a conventional 8B packet.
  localparam [`XLEN-1:0] PAGED_U_PC = USER_VA + 64'h40;
  localparam [`XLEN-1:0] PAGED_U_PA = USER_PA + 64'h40;
  localparam [`XLEN-1:0] PAGED_S_PC = SUP_VA + 64'h80;
  localparam [`XLEN-1:0] PAGED_S_PA = SUP_PA + 64'h80;
  localparam [`XLEN-1:0] PAGED_U_BEAT = 64'h0000_0000_0001_0001;
  localparam [`XLEN-1:0] PAGED_S_BEAT = 64'h0050_0293_0060_0313;
  // Mixed packet: C.NOP followed by 32-bit ADDI, hence packet-next-PC=PC+6.
  localparam [`XLEN-1:0] MIXED_PC = 64'h0000_0000_8000_1242;
  localparam [`XLEN-1:0] MIXED_NEXT_PC = MIXED_PC + 64'd6;
  localparam [`XLEN-1:0] MIXED_BEAT = 64'h0000_0010_0093_0001;
  localparam [`XLEN-1:0] MIXED_NEXT_BEAT = 64'h0000_0000_0001_0001;
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
    .fetch_req_pc_i(fetch_req_pc_to_dut),
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

  // Test-only production decoder recurrence.  When enabled, a valid bridge
  // response directly supplies the successor request PC through the same
  // packet decoder used by OooFrontend.
  OooFetchPacketDecode u_tb_packet_decode (
    .rsp_pc_i(fetch_req_owner_pc),
    .rsp_inst0_i(fetch_rsp_inst0),
    .rsp_resp0_i(fetch_rsp_resp0),
    .rsp_inst1_i(fetch_rsp_inst1),
    .rsp_resp1_i(fetch_rsp_resp1),
    .rsp_resp0_bytes_i(fetch_rsp_resp0_bytes),
    .dec0_pc_o(tb_dec0_pc),
    .dec0_next_pc_o(tb_dec0_next_pc),
    .dec0_inst_o(tb_dec0_inst),
    .dec0_resp_o(tb_dec0_resp),
    .dec0_control_stop_o(),
    .dec1_pc_o(tb_dec1_pc),
    .dec1_next_pc_o(tb_dec1_next_pc),
    .dec1_inst_o(tb_dec1_inst),
    .dec1_resp_o(tb_dec1_resp),
    .dec1_control_stop_o(),
    .dec0_branch_o(),
    .dec0_bimm_o(),
    .dec1_branch_o(),
    .dec1_bimm_o(),
    .packet_next_pc_o(tb_packet_next_pc),
    .fault_tval_o()
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

  // Independent packet-length oracle cross-checks the production decoder used
  // by the test-only response -> successor recurrence.
  function [`XLEN-1:0] packet_next_pc_from_rsp;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    reg first_compressed;
    reg second_compressed;
    reg [15:0] second_halfword;
    begin
      first_compressed = (inst0[1:0] != 2'b11);
      second_halfword = first_compressed ? inst0[31:16] : inst1[15:0];
      second_compressed = (second_halfword[1:0] != 2'b11);
      packet_next_pc_from_rsp =
          pc +
          (first_compressed ? 64'd2 : 64'd4) +
          (second_compressed ? 64'd2 : 64'd4);
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
      tb_decode_follow_en = 1'b0;
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
      tb_decode_follow_en = 1'b0;
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

  task automatic start_fetch_ctx;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [1:0] req_priv;
    input [`XLEN-1:0] req_satp;
    begin
      priv_mode = req_priv;
      satp = req_satp;
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1(what, fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
    end
  endtask

  task automatic start_fetch;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [1:0] req_priv;
    begin
      start_fetch_ctx(what, pc, req_priv, SATP_VALUE);
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

  task automatic drive_fetch_packet_bytes;
    input [1023:0] what;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] packet;
    input integer byte_count;
    integer offset;
    begin
      for (offset = 0; offset < byte_count; offset = offset + 2) begin
        expect_ar(what, paddr + offset);
        drive_fetch_halfword(packet, offset[2:0]);
      end
    end
  endtask

  task automatic drive_fetch_packet;
    input [1023:0] what;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] packet;
    begin
      drive_fetch_packet_bytes(what, paddr, packet, 8);
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

  task automatic walk_to_fetch_bytes;
    input [1023:0] what;
    input [`XLEN-1:0] vaddr;
    input [`XLEN-1:0] paddr;
    input [`XLEN-1:0] leaf_flags;
    input [`XLEN-1:0] inst_beat;
    input integer byte_count;
    begin
      expect_ar(what, pte_addr(ROOT_PT, vaddr, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, vaddr, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, vaddr, 2'd0));
      drive_r(pte_for_page(paddr, leaf_flags), RESP_OK);
      drive_fetch_packet_bytes(what, paddr, inst_beat, byte_count);
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

  // II=1 focused contract: after one seed request, every H1 cycle retires
  // one hit and launches the next synchronous read on the same edge.  The
  // alternating PCs occupy distinct direct-mapped indices and were warmed by
  // the caller, so any bubble here is a bridge protocol regression rather
  // than a replacement artifact.
  task automatic check_ii1_hit_turnover_burst;
    integer beat;
    reg [`XLEN-1:0] current_pc;
    reg [`XLEN-1:0] next_pc;
    reg [`XLEN-1:0] current_packet;
    begin
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      fetch_rsp_ready = 1'b1;
      fetch_req_pc = FUSION_PC1;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("II1 seed request ready", fetch_req_ready, 1'b1);
      tb_check1("II1 idle pre-opens SRAM read window",
                dut.fetch_cache_read_window_w, 1'b1);
      tb_check1("II1 seed fire is semantic cache issue",
                dut.fetch_cache_lookup_issue_w, 1'b1);
      tb_check1("II1 seed fire enables SRAM",
                dut.u_fetch_packet_cache.sram_en_w, 1'b1);
      tick();

      for (beat = 0; beat < 64; beat = beat + 1) begin
        if ((beat & 1) == 0) begin
          current_pc = FUSION_PC1;
          current_packet = FUSION_BEAT1;
          next_pc = FUSION_PC2;
        end else begin
          current_pc = FUSION_PC2;
          current_packet = FUSION_BEAT2;
          next_pc = FUSION_PC1;
        end
        fetch_req_pc = next_pc;
        fetch_req_valid = 1'b1;
        #1;
        tb_check1("II1 burst remains in H1 result state",
                  dut.state_q == S_CACHE_READ_TB, 1'b1);
        tb_check1("II1 burst returns one hit every cycle",
                  fetch_rsp_valid, 1'b1);
        tb_check64_local("II1 burst response owner",
                         fetch_req_owner_pc, current_pc);
        tb_check32_local("II1 burst inst0 payload",
                         fetch_rsp_inst0,
                         current_packet[`INST_W-1:0]);
        tb_check32_local("II1 burst inst1 payload",
                         fetch_rsp_inst1,
                         current_packet[`XLEN-1:`INST_W]);
        tb_check1("II1 burst accepts successor every cycle",
                  fetch_req_ready, 1'b1);
        tb_check1("II1 burst response fires every cycle",
                  dut.fetch_rsp_fire_w, 1'b1);
        tb_check1("II1 burst successor fires every cycle",
                  dut.fetch_req_fire_w, 1'b1);
        tb_check1("II1 burst successor is semantic lookup",
                  dut.fetch_cache_lookup_issue_w, 1'b1);
        tb_check1("II1 burst keeps physical read window open",
                  dut.fetch_cache_read_window_w, 1'b1);
        tick();
      end

      // The 64th turnover launched PC1.  Drain that tail response without a
      // replacement and prove the elastic H1 owner returns directly to IDLE.
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      #1;
      tb_check1("II1 burst tail response valid", fetch_rsp_valid, 1'b1);
      tb_check64_local("II1 burst tail owner",
                       fetch_req_owner_pc, FUSION_PC1);
      tb_check32_local("II1 burst tail payload", fetch_rsp_inst0,
                       FUSION_BEAT1[`INST_W-1:0]);
      tick();
      fetch_rsp_ready = 1'b0;
      #1;
      tb_check1("II1 burst drains directly to idle",
                dut.state_q == S_IDLE_TB, 1'b1);
      $display("[II1-IFU-HIT-TURNOVER] 64 consecutive response+request turnovers passed");
    end
  endtask

  // Paging-on II=1 contract: alternate two independently warmed translation
  // and packet-cache contexts for the policy baseline of 64 consecutive H1
  // turnovers.  Every cycle must retire one response and issue one successor.
  task automatic check_paging_context_ii1_turnover;
    integer beat;
    reg [`XLEN-1:0] current_pc;
    reg [`XLEN-1:0] current_pa;
    reg [`XLEN-1:0] current_satp;
    reg [1:0] current_priv;
    reg [`XLEN-1:0] current_packet;
    reg [`XLEN-1:0] next_pc;
    reg [`XLEN-1:0] next_satp;
    reg [1:0] next_priv;
    begin
      reset_protocol_case();

      start_fetch_ctx("paging II1 warm U request", PAGED_U_PC,
                      `PRIV_U, SATP_VALUE);
      walk_to_fetch_bytes("paging II1 warm U walk/fill", PAGED_U_PC,
                          PAGED_U_PA, PTE_USER_X_FLAGS,
                          PAGED_U_BEAT, 4);
      expect_rsp("paging II1 warm U response",
                 RESP_OK, RESP_OK, PAGED_U_BEAT);

      start_fetch_ctx("paging II1 warm S/ASID1 request", PAGED_S_PC,
                      `PRIV_S, SATP_ASID1);
      walk_to_fetch("paging II1 warm S/ASID1 walk/fill", PAGED_S_PC,
                    PAGED_S_PA, PTE_SUP_X_FLAGS, PAGED_S_BEAT);
      expect_rsp("paging II1 warm S/ASID1 response",
                 RESP_OK, RESP_OK, PAGED_S_BEAT);

      fetch_rsp_ready = 1'b1;
      priv_mode = `PRIV_U;
      satp = SATP_VALUE;
      fetch_req_pc = PAGED_U_PC;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("paging II1 seed accepted", fetch_req_ready, 1'b1);
      tb_check1("paging II1 seed ITLB context hit",
                dut.req_itlb_context_hit_w, 1'b1);
      tb_check1("paging II1 seed ITLB permission passes",
                dut.req_itlb_perm_fault_w, 1'b0);
      tick();

      for (beat = 0; beat < 64; beat = beat + 1) begin
        if ((beat & 1) == 0) begin
          current_pc = PAGED_U_PC;
          current_pa = PAGED_U_PA;
          current_priv = `PRIV_U;
          current_satp = SATP_VALUE;
          current_packet = PAGED_U_BEAT;
          next_pc = PAGED_S_PC;
          next_priv = `PRIV_S;
          next_satp = SATP_ASID1;
        end else begin
          current_pc = PAGED_S_PC;
          current_pa = PAGED_S_PA;
          current_priv = `PRIV_S;
          current_satp = SATP_ASID1;
          current_packet = PAGED_S_BEAT;
          next_pc = PAGED_U_PC;
          next_priv = `PRIV_U;
          next_satp = SATP_VALUE;
        end

        fetch_req_pc = next_pc;
        priv_mode = next_priv;
        satp = next_satp;
        fetch_req_valid = 1'b1;
        #1;
        tb_check1("paging II1 remains in H1",
                  dut.state_q == S_CACHE_READ_TB, 1'b1);
        tb_check64_local("paging II1 candidate PC",
                         dut.fetch_ctx_candidate_pc_q, current_pc);
        tb_check2("paging II1 candidate privilege",
                  dut.fetch_ctx_candidate_priv_q, current_priv);
        tb_check64_local("paging II1 candidate SATP",
                         dut.fetch_ctx_candidate_satp_q, current_satp);
        tb_check1("paging II1 candidate paging enabled",
                  dut.fetch_ctx_candidate_paging_q, 1'b1);
        tb_check1("paging II1 registered ITLB hit",
                  dut.lookup_itlb_hit_q, 1'b1);
        tb_check1("paging II1 registered permission passes",
                  dut.lookup_itlb_perm_fault_q, 1'b0);
        tb_check64_local("paging II1 registered physical owner",
                         dut.lookup_exec_paddr_q, current_pa);
        tb_check1("paging II1 FPC context hit",
                  dut.fetch_cache_context_unused_w, 1'b1);
        tb_check1("paging II1 raw FPC hit", dut.cache_hit_raw_w, 1'b1);
        tb_check1("paging II1 first fixed PMP window passes",
                  dut.req_exec_pmp_fault_w, 1'b0);
        tb_check1("paging II1 second fixed PMP window passes",
                  dut.req_exec1_pmp_fault_w, 1'b0);
        tb_check1("paging II1 fusion hit qualifies",
                  dut.cache_hit_fusion_w, 1'b1);
        tb_check1("paging II1 response valid", fetch_rsp_valid, 1'b1);
        tb_check64_local("paging II1 response owner",
                         fetch_req_owner_pc, current_pc);
        tb_check32_local("paging II1 response inst0",
                         fetch_rsp_inst0,
                         current_packet[`INST_W-1:0]);
        tb_check32_local("paging II1 response inst1",
                         fetch_rsp_inst1,
                         current_packet[`XLEN-1:`INST_W]);
        tb_check1("paging II1 response split is four bytes",
                  fetch_rsp_resp0_bytes == 3'd4, 1'b1);
        tb_check1("paging II1 successor accepted",
                  fetch_req_ready, 1'b1);
        tb_check1("paging II1 response fires",
                  dut.fetch_rsp_fire_w, 1'b1);
        tb_check1("paging II1 successor fires",
                  dut.fetch_req_fire_w, 1'b1);
        tb_check1("paging II1 successor issues FPC read",
                  dut.fetch_cache_lookup_issue_w, 1'b1);
        tb_check1("paging II1 emits no AXI AR", ifu_axi_arvalid, 1'b0);
        tb_check1("paging II1 performs no FPC fill",
                  dut.fetch_cache_fill_valid_w, 1'b0);
        tb_check1("paging II1 performs no ITLB fill",
                  dut.itlb_fill_valid_w, 1'b0);
        tick();
      end

      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      #1;
      tb_check1("paging II1 tail response valid", fetch_rsp_valid, 1'b1);
      tb_check64_local("paging II1 tail owner",
                       fetch_req_owner_pc, PAGED_U_PC);
      tb_check32_local("paging II1 tail inst0", fetch_rsp_inst0,
                       PAGED_U_BEAT[`INST_W-1:0]);
      tick();
      fetch_rsp_ready = 1'b0;
      #1;
      tb_check1("paging II1 drains to idle",
                dut.state_q == S_IDLE_TB, 1'b1);
      $display("[II1-PAGING-CONTEXT] 64 U/ASID0 <-> S/ASID1 turnovers passed");
    end
  endtask

  // The packet and translation entries warmed above remain live.  Exercise
  // each authority gate separately: a conservative 8B fast-gate rejection
  // must downgrade to exact 2B reads, whereas an exact first-halfword PMP
  // denial and an ITLB permission denial must return architectural faults.
  task automatic check_paging_fast_gate_policy;
    begin
      tb_check1("paging policy starts idle",
                dut.state_q == S_IDLE_TB, 1'b1);

      // TOR0 allows [0,U_PA+4), TOR1 denies [U_PA+4,U_PA+8).  The cached
      // two-C packet needs only the first four bytes, so fixed checker #1 must
      // reject the fast path while exact halfword reads remain legal.
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      pmpcfg[0 +: 8] = 8'h0c;
      pmpcfg[8 +: 8] = 8'h08;
      pmpcfg[16 +: 8] = 8'h1f;
      pmpaddr[0 +: `XLEN] = (PAGED_U_PA + 64'd4) >> 2;
      pmpaddr[`XLEN +: `XLEN] = (PAGED_U_PA + 64'd8) >> 2;
      pmpaddr[2*`XLEN +: `XLEN] = {`XLEN{1'b1}};
      fetch_rsp_ready = 1'b1;
      start_fetch_ctx("paging policy conservative-gate request",
                      PAGED_U_PC, `PRIV_U, SATP_VALUE);
      #1;
      tb_check1("paging policy conservative gate reaches H1",
                dut.state_q == S_CACHE_READ_TB, 1'b1);
      tb_check1("paging policy conservative gate has raw FPC hit",
                dut.cache_hit_raw_w, 1'b1);
      tb_check1("paging policy conservative gate has ITLB hit",
                dut.lookup_itlb_hit_q, 1'b1);
      tb_check1("paging policy first fixed window passes",
                dut.req_exec_pmp_fault_w, 1'b0);
      tb_check1("paging policy second fixed window rejects",
                dut.req_exec1_pmp_fault_w, 1'b1);
      tb_check1("paging policy reject suppresses fast response",
                fetch_rsp_valid, 1'b0);
      tb_check1("paging policy reject suppresses turnover",
                fetch_req_ready, 1'b0);
      tick();
      #1;
      tb_check1("paging policy reject downgrades to exact fetch",
                dut.state_q == S_AR0_TB, 1'b1);
      drive_fetch_packet_bytes("paging policy exact four-byte refill",
                               PAGED_U_PA, PAGED_U_BEAT, 4);
      expect_rsp("paging policy exact four-byte response",
                 RESP_OK, RESP_OK, PAGED_U_BEAT);

      // Restoring allow-all exposes the same refilled packet as a fast hit,
      // proving the conservative rejection was only a performance downgrade.
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;
      fetch_rsp_ready = 1'b1;
      start_fetch_ctx("paging policy post-downgrade fast request",
                      PAGED_U_PC, `PRIV_U, SATP_VALUE);
      #1;
      tb_check1("paging policy post-downgrade fast response",
                fetch_rsp_valid, 1'b1);
      tb_check1("paging policy post-downgrade raw hit",
                dut.cache_hit_raw_w, 1'b1);
      tick();
      fetch_rsp_ready = 1'b0;

      // No PMP entries in U mode is default-deny.  A raw cache/ITLB hit must
      // first downgrade, then the exact 2B checker returns access fault at
      // byte offset zero without presenting an AXI request.
      pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
      fetch_rsp_ready = 1'b1;
      start_fetch_ctx("paging policy exact-PMP-deny request",
                      PAGED_U_PC, `PRIV_U, SATP_VALUE);
      #1;
      tb_check1("paging policy exact-PMP-deny raw hit",
                dut.cache_hit_raw_w, 1'b1);
      tb_check1("paging policy exact-PMP-deny ITLB hit",
                dut.lookup_itlb_hit_q, 1'b1);
      tb_check1("paging policy exact-PMP-deny closes fast gate",
                dut.req_exec_pmp_fault_w, 1'b1);
      tb_check1("paging policy exact-PMP-deny emits no H1 response",
                fetch_rsp_valid, 1'b0);
      tick();
      #1;
      tb_check1("paging policy exact-PMP-deny reaches S_AR0",
                dut.state_q == S_AR0_TB, 1'b1);
      tb_check1("paging policy exact-PMP-deny exact checker faults",
                dut.fetch_current_pmp_fault_w, 1'b1);
      tb_check1("paging policy exact-PMP-deny suppresses AR",
                ifu_axi_arvalid, 1'b0);
      tick();
      #1;
      tb_check1("paging policy exact-PMP-deny response valid",
                fetch_rsp_valid, 1'b1);
      tb_check2("paging policy exact-PMP-deny access fault",
                fetch_rsp_resp1, RESP_ACCESS_FAULT);
      tb_check1("paging policy exact-PMP-deny split zero",
                fetch_rsp_resp0_bytes == 3'd0, 1'b1);
      tick();
      fetch_rsp_ready = 1'b0;
      pmpcfg = PMP_ALLOW_ALL_CFG;
      pmpaddr = PMP_ALLOW_ALL_ADDR;

      // Reuse the U PTE under S privilege.  The ITLB context still matches
      // SATP+VA, but the current privilege permission check must fail.  FPC
      // privilege tagging independently prevents a packet-cache hit.
      fetch_rsp_ready = 1'b1;
      priv_mode = `PRIV_S;
      satp = SATP_VALUE;
      fetch_req_pc = PAGED_U_PC;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("paging policy permission request accepted",
                fetch_req_ready, 1'b1);
      tb_check1("paging policy permission ITLB context matches",
                dut.req_itlb_context_hit_w, 1'b1);
      tb_check1("paging policy permission issue faults",
                dut.req_itlb_perm_fault_w, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      #1;
      tb_check1("paging policy privilege tag blocks FPC context",
                dut.fetch_cache_context_unused_w, 1'b0);
      tb_check1("paging policy privilege tag blocks raw FPC hit",
                dut.cache_hit_raw_w, 1'b0);
      tb_check1("paging policy permission fault registered",
                dut.lookup_itlb_perm_fault_q, 1'b1);
      tb_check1("paging policy permission emits no AXI AR",
                ifu_axi_arvalid, 1'b0);
      tb_check1("paging policy permission H1 emits no response",
                fetch_rsp_valid, 1'b0);
      tick();
      #1;
      tb_check1("paging policy permission response valid",
                fetch_rsp_valid, 1'b1);
      tb_check2("paging policy permission page fault",
                fetch_rsp_resp1, RESP_PAGE_FAULT);
      tb_check1("paging policy permission split zero",
                fetch_rsp_resp0_bytes == 3'd0, 1'b1);
      tick();
      fetch_rsp_ready = 1'b0;

      // Full SATP (including ASID) participates in both tags.  End with this
      // negative lookup because the cancellation flush intentionally clears
      // the warmed packet cache and ITLB.
      priv_mode = `PRIV_U;
      satp = SATP_ASID1;
      fetch_req_pc = PAGED_U_PC;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("paging policy ASID mismatch request accepted",
                fetch_req_ready, 1'b1);
      tb_check1("paging policy ASID mismatch ITLB misses",
                dut.req_itlb_context_hit_w, 1'b0);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      #1;
      tb_check1("paging policy ASID mismatch blocks FPC context",
                dut.fetch_cache_context_unused_w, 1'b0);
      tb_check1("paging policy ASID mismatch blocks raw FPC hit",
                dut.cache_hit_raw_w, 1'b0);
      tb_check1("paging policy ASID mismatch has no ITLB hit",
                dut.lookup_itlb_hit_q, 1'b0);
      tb_check1("paging policy ASID mismatch emits no response",
                fetch_rsp_valid, 1'b0);
      tick();
      #1;
      tb_check1("paging policy ASID mismatch enters walk check",
                dut.state_q == S_WALK_CHECK_TB, 1'b1);
      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      #1;
      tb_check1("paging policy ASID mismatch cancel returns idle",
                dut.state_q == S_IDLE_TB, 1'b1);
      $display("[II1-PAGING-AUTHORITY] conservative downgrade, exact PMP fault, ITLB permission, and ASID isolation passed");
    end
  endtask

  // Use the production OooFetchPacketDecode output as the live successor PC.
  // MIXED_PC ends at address ...42 so its +6 successor occupies a different
  // direct-mapped FPC index (...48), allowing both entries to stay resident.
  task automatic check_mixed_rvc_decoder_follow;
    begin
      reset_protocol_case();
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};

      start_fetch_ctx("mixed decoder warm C+32 request", MIXED_PC,
                      `PRIV_M, {`XLEN{1'b0}});
      drive_fetch_packet_bytes("mixed decoder warm C+32 fill",
                               MIXED_PC, MIXED_BEAT, 6);
      expect_rsp("mixed decoder warm C+32 response",
                 RESP_OK, RESP_OK, MIXED_BEAT);

      start_fetch_ctx("mixed decoder warm successor request", MIXED_NEXT_PC,
                      `PRIV_M, {`XLEN{1'b0}});
      drive_fetch_packet_bytes("mixed decoder warm successor fill",
                               MIXED_NEXT_PC, MIXED_NEXT_BEAT, 4);
      expect_rsp("mixed decoder warm successor response",
                 RESP_OK, RESP_OK, MIXED_NEXT_BEAT);

      fetch_rsp_ready = 1'b1;
      start_fetch_ctx("mixed decoder seed request", MIXED_PC,
                      `PRIV_M, {`XLEN{1'b0}});
      tb_decode_follow_en = 1'b1;
      fetch_req_valid = 1'b1;
      // This sentinel proves the request accepted below comes from the decoder
      // mux rather than the manually driven fallback PC.
      fetch_req_pc = 64'hffff_ffff_ffff_fffe;
      #1;
      tb_check1("mixed decoder seed H1 hit", fetch_rsp_valid, 1'b1);
      tb_check64_local("mixed decoder slot0 PC",
                       tb_dec0_pc, MIXED_PC);
      tb_check64_local("mixed decoder slot0 next PC",
                       tb_dec0_next_pc, MIXED_PC + 64'd2);
      tb_check32_local("mixed decoder slot0 decompressed C.NOP",
                       tb_dec0_inst, 32'h0000_0013);
      tb_check2("mixed decoder slot0 response",
                tb_dec0_resp, RESP_OK);
      tb_check64_local("mixed decoder slot1 PC",
                       tb_dec1_pc, MIXED_PC + 64'd2);
      tb_check64_local("mixed decoder slot1 next PC",
                       tb_dec1_next_pc, MIXED_NEXT_PC);
      tb_check32_local("mixed decoder slot1 32-bit ADDI",
                       tb_dec1_inst, 32'h0010_0093);
      tb_check2("mixed decoder slot1 response",
                tb_dec1_resp, RESP_OK);
      tb_check64_local("mixed decoder production packet next PC",
                       tb_packet_next_pc, MIXED_NEXT_PC);
      tb_check64_local("mixed decoder independent length oracle",
                       packet_next_pc_from_rsp(fetch_req_owner_pc,
                                               fetch_rsp_inst0,
                                               fetch_rsp_inst1),
                       MIXED_NEXT_PC);
      tb_check64_local("mixed decoder drives bridge successor input",
                       fetch_req_pc_to_dut, MIXED_NEXT_PC);
      tb_check1("mixed decoder response fires",
                dut.fetch_rsp_fire_w, 1'b1);
      tb_check1("mixed decoder successor fires",
                dut.fetch_req_fire_w, 1'b1);
      tick();

      fetch_req_valid = 1'b0;
      #1;
      tb_check1("mixed decoder successor H1 hit",
                fetch_rsp_valid, 1'b1);
      tb_check64_local("mixed decoder successor owner",
                       fetch_req_owner_pc, MIXED_NEXT_PC);
      tb_check32_local("mixed decoder successor inst0",
                       fetch_rsp_inst0,
                       MIXED_NEXT_BEAT[`INST_W-1:0]);
      tb_check64_local("mixed decoder successor packet next PC",
                       tb_packet_next_pc, MIXED_NEXT_PC + 64'd4);
      tick();
      tb_decode_follow_en = 1'b0;
      fetch_rsp_ready = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      #1;
      tb_check1("mixed decoder recurrence drains to idle",
                dut.state_q == S_IDLE_TB, 1'b1);
      $display("[II1-MIXED-DECODE-FOLLOW] production decoder C+32 successor turnover passed");
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

    // T3X dirty-owner replacement, migrated to the collapsed II=1 boundary:
    // S_RESP consumes the old cross-page packet and launches the replacement
    // read on the same edge.  The following H1 cycle owns the new context and
    // directly decides the non-canonical fault; S_LOOKUP is never entered.
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
    tb_check1("S_RESP replacement launches physical read",
              dut.fetch_cache_read_window_w, 1'b1);
    tb_check1("S_RESP replacement is semantic cache issue",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("dirty replacement reaches H1 owner",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check64_local("dirty replacement H1 owns captured pc",
                     fetch_req_owner_pc, NONCANON_VA);
    tb_check64_local("dirty packet survives until H1 decision edge",
                     dut.fetch_data_q, CROSS_MERGED_BEAT);
    tb_check1("dirty replacement H1 emits no stale response",
              fetch_rsp_valid, 1'b0);
    tb_check1("dirty replacement H1 emits no AR", ifu_axi_arvalid, 1'b0);
    tick();
    #1;
    tb_check1("noncanonical H1 decision enters response skid",
              dut.state_q == S_RESP_TB, 1'b1);
    tb_check64_local("H1 clears stale packet before fault response",
                     dut.fetch_data_q, {`XLEN{1'b0}});
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
    $display("[II1-IFU-DIRTY-FIRST-FAULT] S_RESP replacement reaches H1 fault directly");
    fetch_rsp_ready = 1'b1;
    tick();
    fetch_rsp_ready = 1'b0;

    // Warm two distinct M-mode packet-cache entries through the unchanged miss
    // path, then demand 32 back-to-back H1 response+successor turnovers.
    start_fetch("II1 warm pc1 accepted", FUSION_PC1, `PRIV_M);
    drive_fetch_packet("II1 warm pc1 goes axi", FUSION_PC1, FUSION_BEAT1);
    expect_rsp("II1 warm pc1 resp", RESP_OK, RESP_OK, FUSION_BEAT1);
    start_fetch("II1 warm pc2 accepted", FUSION_PC2, `PRIV_M);
    drive_fetch_packet("II1 warm pc2 goes axi", FUSION_PC2, FUSION_BEAT2);
    expect_rsp("II1 warm pc2 resp", RESP_OK, RESP_OK, FUSION_BEAT2);
    check_ii1_hit_turnover_burst();

    // Fast-hit backpressure must convert the combinational H1 response into
    // the existing registered S_RESP skid.  While stalled, the live request is
    // only a dummy SRAM read and cannot become a semantic request.
    priv_mode = `PRIV_M;
    satp = {`XLEN{1'b0}};
    svpbmt_en = 1'b0;
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("fast-stall seed accepted from idle", fetch_req_ready, 1'b1);
    tb_check1("fast-stall seed is semantic lookup",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tick();

    fetch_req_pc = FUSION_PC3_COLD;
    #1;
    tb_check1("fast-stall appears in H1",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check1("fast-stall H1 response is visible", fetch_rsp_valid, 1'b1);
    tb_check32_local("fast-stall H1 payload", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tb_check64_local("fast-stall H1 owner", fetch_req_owner_pc, FUSION_PC2);
    tb_check1("fast-stall rejects live successor", fetch_req_ready, 1'b0);
    tb_check1("rejected successor is not semantic lookup",
              dut.fetch_cache_lookup_issue_w, 1'b0);
    tick();

    #1;
    tb_check1("fast-stall captures into S_RESP",
              dut.state_q == S_RESP_TB, 1'b1);
    tb_check1("S_RESP skid remains valid", fetch_rsp_valid, 1'b1);
    tb_check32_local("S_RESP skid payload", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tb_check64_local("S_RESP skid owner", fetch_req_owner_pc, FUSION_PC2);
    tb_check1("stalled S_RESP rejects live successor", fetch_req_ready, 1'b0);
    tb_check1("S_RESP keeps replacement read window pre-open",
              dut.fetch_cache_read_window_w, 1'b1);
    tick();
    #1;
    tb_check1("S_RESP stalled valid is stable", fetch_rsp_valid, 1'b1);
    tb_check32_local("S_RESP stalled payload is stable", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tb_check64_local("S_RESP stalled owner is stable",
                     fetch_req_owner_pc, FUSION_PC2);

    // Release the skid and replace it atomically.  S_RESP's pre-open window
    // launches PC1, so the very next cycle is already its H1 response.
    fetch_req_pc = FUSION_PC1;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tb_check1("S_RESP replacement accepts successor", fetch_req_ready, 1'b1);
    tb_check1("S_RESP replacement retires old response",
              dut.fetch_rsp_fire_w, 1'b1);
    tb_check1("S_RESP replacement fires successor",
              dut.fetch_req_fire_w, 1'b1);
    tb_check1("S_RESP replacement launches semantic lookup",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tick();
    #1;
    tb_check1("S_RESP replacement reaches successor H1",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tb_check1("S_RESP replacement has no bubble", fetch_rsp_valid, 1'b1);
    tb_check64_local("S_RESP replacement owner", fetch_req_owner_pc,
                     FUSION_PC1);
    tb_check32_local("S_RESP replacement payload", fetch_rsp_inst0,
                     FUSION_BEAT1[`INST_W-1:0]);
    fetch_req_valid = 1'b0;
    tick();
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("replacement tail drains to idle",
              dut.state_q == S_IDLE_TB, 1'b1);
    $display("[II1-IFU-ELASTIC-SKID] fast stall -> S_RESP -> replacement passed");

    // Invalidate window ②: an unrelated store arriving in H1 globally disables
    // the timing fusion arm, but exact lookup remains a hit and is captured to
    // S_RESP.  This deliberately inserts one elastic bubble without exposing a
    // stale packet or starting AXI.
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();
    fetch_req_valid = 1'b0;
    invalidate_valid = 1'b1;
    invalidate_addr = 64'h0000_0000_8000_5000;
    #1;
    tb_check1("different-window H1 exact hit survives",
              dut.cache_hit_w, 1'b1);
    tb_check1("different-window invalidate disables fusion",
              dut.cache_hit_fusion_w, 1'b0);
    tb_check1("different-window H1 does not expose fast response",
              fetch_rsp_valid, 1'b0);
    tb_check1("different-window H1 cannot accept successor",
              fetch_req_ready, 1'b0);
    tick();
    invalidate_valid = 1'b0;
    #1;
    tb_check1("different-window exact hit lands in S_RESP",
              dut.state_q == S_RESP_TB, 1'b1);
    tb_check1("different-window exact hit response valid",
              fetch_rsp_valid, 1'b1);
    tb_check32_local("different-window exact hit payload",
                     fetch_rsp_inst0, FUSION_BEAT2[`INST_W-1:0]);
    tick();
    fetch_rsp_ready = 1'b0;

    // Invalidate window ②, overlapping store: exact H1 hit is killed before
    // delivery and the request falls back to the unchanged slow refetch path.
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();
    fetch_req_valid = 1'b0;
    invalidate_valid = 1'b1;
    invalidate_addr = FUSION_PC2;
    #1;
    tb_check1("same-window H1 invalidate kills exact hit",
              dut.cache_hit_w, 1'b0);
    tb_check1("same-window H1 invalidate emits no response",
              fetch_rsp_valid, 1'b0);
    tb_check1("same-window H1 invalidate blocks request turnover",
              fetch_req_ready, 1'b0);
    tick();
    invalidate_valid = 1'b0;
    #1;
    tb_check1("same-window H1 invalidate enters direct miss AR",
              dut.state_q != S_LOOKUP_TB, 1'b1);
    drive_fetch_packet("same-window H1 refetch packet",
                       FUSION_PC2, FUSION_BEAT2);
    expect_rsp("same-window H1 refetched response",
               RESP_OK, RESP_OK, FUSION_BEAT2);

    // Invalidate window ①: a store overlapping the request-fire edge is
    // latched in lkp_inv_q and also clears valid_q.  Lowering invalidate in H1
    // must not resurrect the stale packet.
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    invalidate_valid = 1'b1;
    invalidate_addr = FUSION_PC2;
    #1;
    tb_check1("fire-window invalidate request still handshakes",
              fetch_req_ready, 1'b1);
    tb_check1("fire-window invalidate is semantic lookup",
              dut.fetch_cache_lookup_issue_w, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    invalidate_valid = 1'b0;
    #1;
    tb_check1("fire-window poison is retained",
              dut.u_fetch_packet_cache.lkp_inv_q, 1'b1);
    tb_check1("fire-window poison kills H1 hit", dut.cache_hit_w, 1'b0);
    tb_check1("fire-window poison emits no response", fetch_rsp_valid, 1'b0);
    tick();
    drive_fetch_packet("fire-window refetch packet",
                       FUSION_PC2, FUSION_BEAT2);
    expect_rsp("fire-window refetched response",
               RESP_OK, RESP_OK, FUSION_BEAT2);
    $display("[II1-IFU-INVALIDATE-WINDOWS] exact downgrade, H1 poison, and fire poison passed");

    // A cold request still owns the single context and therefore blocks H1
    // turnover until its slow miss completes.
    fetch_req_pc = FUSION_PC3_COLD;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tb_check1("cold miss request accepted", fetch_req_ready, 1'b1);
    tick();
    fetch_req_valid = 1'b0;
    #1;
    tb_check1("cold miss H1 emits no response", fetch_rsp_valid, 1'b0);
    tb_check1("cold miss H1 accepts no successor", fetch_req_ready, 1'b0);
    tb_check1("cold miss never enters legacy lookup",
              dut.state_q == S_CACHE_READ_TB, 1'b1);
    tick();
    drive_fetch_packet("cold miss direct AR", FUSION_PC3_COLD, FUSION_BEAT3);
    expect_rsp("cold miss response unchanged",
               RESP_OK, RESP_OK, FUSION_BEAT3);

    // Bridge-observable redirect proxy: this module has no branch-redirect
    // input.  mmu_flush_i is the only cancellation interface.  Assert it while
    // a warmed PC3 hit is in H1 and a successor is offered; both response and
    // request must be suppressed, and the owner/cache are dropped on the edge.
    fetch_req_pc = FUSION_PC3_COLD;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();
    fetch_req_pc = FUSION_PC2;
    fetch_req_valid = 1'b1;
    mmu_flush = 1'b1;
    #1;
    tb_check1("H1 mmu-flush proxy masks fast response",
              fetch_rsp_valid, 1'b0);
    tb_check1("H1 mmu-flush proxy rejects successor",
              fetch_req_ready, 1'b0);
    tb_check1("H1 mmu-flush proxy prevents response fire",
              dut.fetch_rsp_fire_w, 1'b0);
    tb_check1("H1 mmu-flush proxy prevents request fire",
              dut.fetch_req_fire_w, 1'b0);
    tick();
    mmu_flush = 1'b0;
    fetch_req_valid = 1'b0;
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("H1 mmu-flush proxy returns idle",
              dut.state_q == S_IDLE_TB, 1'b1);
    tb_check1("H1 mmu-flush proxy leaks no response",
              fetch_rsp_valid, 1'b0);
    $display("[II1-IFU-MMU-FLUSH-PROXY] H1 hit and successor cancelled (not a branch-redirect port)");

    check_paging_context_ii1_turnover();
    check_paging_fast_gate_policy();
    check_mixed_rvc_decoder_follow();

    // ===== T4A PTW READ authorization：deny 判决必须寄存并抑制 AR =====
    reset_protocol_case();
    pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
    pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
    ifu_axi_arready = 1'b0;
    start_fetch("PTW deny request accepted", USER_VA, `PRIV_U);
    tick();                       // H1 miss -> S_WALK_CHECK
    tick();                       // registered check -> S_WALK_AR
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
