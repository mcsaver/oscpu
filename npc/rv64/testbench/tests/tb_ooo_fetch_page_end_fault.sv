`include "define.v"
`include "tb_common.svh"

// IFU-FETCH-G2 永久回归：跨页 packet 的 fault 必须按真实指令字节归属，而不是按
// 固定 32-bit word 或“本页剩余字节 < 4”粗判。bridge 后接真实 packet decoder，
// 因此这里检查的是前端最终两条指令槽可见的 resp，而不是 bridge 内部中间编码。
module tb_ooo_fetch_page_end_fault;
  reg clk;
  reg rst;
  reg mmu_flush;
  reg invalidate_valid;
  reg [`XLEN-1:0] invalidate_addr;
  reg [1:0] priv_mode;
  reg [`XLEN-1:0] satp;
  reg svpbmt_en;
  reg fetch_req_valid;
  wire fetch_req_ready;
  reg [`XLEN-1:0] fetch_req_pc;
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
  wire ifu_axi_awvalid;
  reg ifu_axi_awready;
  wire [`XLEN-1:0] ifu_axi_awaddr;
  wire ifu_axi_wvalid;
  reg ifu_axi_wready;
  wire [`XLEN-1:0] ifu_axi_wdata;
  wire [`STRB_W-1:0] ifu_axi_wstrb;
  wire ifu_axi_wlast;
  reg ifu_axi_bvalid;
  wire ifu_axi_bready;
  reg [1:0] ifu_axi_bresp;

  reg [`XLEN-1:0] rsp_pc;
  wire [`XLEN-1:0] dec0_pc;
  wire [`XLEN-1:0] dec0_next_pc;
  wire [`INST_W-1:0] dec0_inst;
  wire [1:0] dec0_resp;
  wire dec0_control_stop;
  wire [`XLEN-1:0] dec1_pc;
  wire [`XLEN-1:0] dec1_next_pc;
  wire [`INST_W-1:0] dec1_inst;
  wire [1:0] dec1_resp;
  wire dec1_control_stop;
  wire dec0_branch;
  wire [12:0] dec0_bimm;
  wire dec1_branch;
  wire [12:0] dec1_bimm;
  wire [`XLEN-1:0] packet_next_pc;
  wire [`XLEN-1:0] dec_fault_tval;

  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] L1_PT = 64'h0000_0000_8100_1000;
  localparam [`XLEN-1:0] L0_PT = 64'h0000_0000_8100_2000;
  localparam [`XLEN-1:0] FETCH_PA_PAGE = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] NEXT_FETCH_PA_PAGE = 64'h0000_0000_8200_5000;
  localparam [`XLEN-1:0] PC_FFA = 64'h0000_0000_0000_4ffa;
  localparam [`XLEN-1:0] PC_FFC = 64'h0000_0000_0000_4ffc;
  localparam [`XLEN-1:0] PC_FFE = 64'h0000_0000_0000_4ffe;
  localparam [`XLEN-1:0] PC_STALE_PREFILL = 64'h0000_0000_0000_6000;
  localparam [`XLEN-1:0] PC_F0 = 64'h0000_0000_0000_7000;
  localparam [`XLEN-1:0] NEXT_PAGE_VA = 64'h0000_0000_0000_5000;
  localparam [`XLEN-1:0] SATP_VALUE =
      64'h8000_0000_0000_0000 | (ROOT_PT >> 12);
  localparam [`XLEN-1:0] PTE_NONLEAF_FLAGS = 64'h001;
  localparam [`XLEN-1:0] PTE_USER_X_FLAGS = 64'h0df;
  localparam [`XLEN-1:0] PTE_USER_X_A0_FLAGS = 64'h09f;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR =
      {`PMP_ADDR_BUS_W{1'b1}};

  // 只在真实 second-page invalid-PTE 行启用：分别记录 fault transaction 是否
  // 误触发 packet-cache fill/SRAM write，以及 fault frontier 后是否又呈现年轻 AR。
  reg fault_txn_monitor_q;
  reg fault_frontier_seen_q;
  integer fault_cache_fill_count_q;
  integer fault_sram_write_count_q;
  integer fault_monitor_cycles_q;
  integer fault_frontier_cycles_q;
  integer fault_instruction_ar_count_q;
  integer fault_post_frontier_ar_count_q;
  integer raw_frontier_f2_rows_q;
  integer raw_frontier_f4_rows_q;
  integer raw_frontier_f6_rows_q;
  integer fault_stall_rows_q;
  integer fault_stall_cycles_q;
  integer fault_post_accept_quiet_cycles_q;
  reg preserve_state_for_next_case_q;
  reg positive_control_monitor_q;
  integer positive_control_instruction_ar_count_q;
  integer positive_control_cache_fill_count_q;
  integer positive_control_sram_write_count_q;

  OooFetchAxiBridge u_bridge (
    .clk(clk),
    .rst(rst),
    .mmu_flush_i(mmu_flush),
    .invalidate_valid_i(invalidate_valid),
    .invalidate_addr_i(invalidate_addr),
    .priv_mode_i(priv_mode),
    .satp_i(satp),
    .svpbmt_en_i(svpbmt_en),
    .pmpcfg_i(PMP_ALLOW_ALL_CFG),
    .pmpaddr_i(PMP_ALLOW_ALL_ADDR),
    .fetch_req_valid_i(fetch_req_valid),
    .fetch_req_ready_o(fetch_req_ready),
    .fetch_req_pc_i(fetch_req_pc),
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
    .ifu_axi_wlast_o(ifu_axi_wlast),
    .ifu_axi_bvalid_i(ifu_axi_bvalid),
    .ifu_axi_bready_o(ifu_axi_bready),
    .ifu_axi_bresp_i(ifu_axi_bresp)
  );

  OooFetchPacketDecode u_decode (
    .rsp_pc_i(rsp_pc),
    .rsp_inst0_i(fetch_rsp_inst0),
    .rsp_resp0_i(fetch_rsp_resp0),
    .rsp_inst1_i(fetch_rsp_inst1),
    .rsp_resp1_i(fetch_rsp_resp1),
    .rsp_resp0_bytes_i(fetch_rsp_resp0_bytes),
    .dec0_pc_o(dec0_pc),
    .dec0_next_pc_o(dec0_next_pc),
    .dec0_inst_o(dec0_inst),
    .dec0_resp_o(dec0_resp),
    .dec0_control_stop_o(dec0_control_stop),
    .dec1_pc_o(dec1_pc),
    .dec1_next_pc_o(dec1_next_pc),
    .dec1_inst_o(dec1_inst),
    .dec1_resp_o(dec1_resp),
    .dec1_control_stop_o(dec1_control_stop),
    .dec0_branch_o(dec0_branch),
    .dec0_bimm_o(dec0_bimm),
    .dec1_branch_o(dec1_branch),
    .dec1_bimm_o(dec1_bimm),
    .packet_next_pc_o(packet_next_pc),
    .packet_raw_next_pc_o(),
    .fault_tval_o(dec_fault_tval)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (fault_txn_monitor_q) begin
      // !==0 同时拒绝 X，避免内部 owner 未初始化时静默假绿。
      fault_monitor_cycles_q <= fault_monitor_cycles_q + 1;
      if (u_bridge.fetch_cache_fill_valid_w !== 1'b0)
        fault_cache_fill_count_q <= fault_cache_fill_count_q + 1;
      if (u_bridge.u_fetch_packet_cache.sram_we_w !== 1'b0)
        fault_sram_write_count_q <= fault_sram_write_count_q + 1;
      if ((ifu_axi_arvalid === 1'b1) &&
          (ifu_axi_arprot === 3'b100))
        fault_instruction_ar_count_q <= fault_instruction_ar_count_q + 1;
      if (fault_frontier_seen_q) begin
        fault_frontier_cycles_q <= fault_frontier_cycles_q + 1;
        if (ifu_axi_arvalid !== 1'b0)
          fault_post_frontier_ar_count_q <=
              fault_post_frontier_ar_count_q + 1;
      end
    end
    if (positive_control_monitor_q) begin
      if ((ifu_axi_arvalid === 1'b1) &&
          (ifu_axi_arprot === 3'b100))
        positive_control_instruction_ar_count_q <=
            positive_control_instruction_ar_count_q + 1;
      if (u_bridge.fetch_cache_fill_valid_w === 1'b1)
        positive_control_cache_fill_count_q <=
            positive_control_cache_fill_count_q + 1;
      if (u_bridge.u_fetch_packet_cache.sram_we_w === 1'b1)
        positive_control_sram_write_count_q <=
            positive_control_sram_write_count_q + 1;
    end
  end

  task automatic check_resp;
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

  // IFU-ACCESS-G1：先真实取回 page+FFE 的 2B prefix，再让第二页 L0 leaf 以
  // A=0 返回。任务结束时 DUT 必须持有 second-page A-update write owner，同时
  // frontier/prefix 仍是 offset=2/原 halfword；后续 normal 与 flush-drain 两路复用。
  task automatic enter_second_page_ad_update;
    input [1023:0] what;
    input [`XLEN-1:0] packet;
    reg [`XLEN-1:0] second_leaf_a0;
    begin
      reset_case();
      rsp_pc = PC_FFE;
      fetch_req_pc = PC_FFE;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("AD second-page fetch request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};

      expect_ar(what, pte_addr(ROOT_PT, PC_FFE, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L1_PT, PC_FFE, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L0_PT, PC_FFE, 2'd0));
      drive_r(pte_for_page(FETCH_PA_PAGE, PTE_USER_X_FLAGS));

      expect_ar(what, FETCH_PA_PAGE + 64'hffe);
      drive_fetch_halfword(packet, 3'd0);

      expect_ar(what, pte_addr(ROOT_PT, NEXT_PAGE_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L1_PT, NEXT_PAGE_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0));
      second_leaf_a0 = pte_for_page(NEXT_FETCH_PA_PAGE,
                                    PTE_USER_X_A0_FLAGS);
      drive_r(second_leaf_a0);

      // 白盒只用于证明 bridge 没在进入写 owner 时遗失已成功 prefix；总线后继仍
      // 全部通过外部 AXI channel 验证，避免把状态 deposit 当成功路径。
      tb_check1("AD second-page owner presents AW", ifu_axi_awvalid, 1'b1);
      tb_check1("AD second-page owner presents W", ifu_axi_wvalid, 1'b1);
      tb_check1("AD second-page owner keeps BREADY", ifu_axi_bready, 1'b1);
      tb_check1("AD successful prefix frontier retained",
                u_bridge.fetch_offset_q == 3'd2, 1'b1);
      tb_check1("AD successful prefix data retained",
                u_bridge.fetch_data_q[15:0] == packet[15:0], 1'b1);
      check_xlen("AD second-page PTE write address", ifu_axi_awaddr,
                 pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0));
      check_xlen("AD second-page PTE write payload", ifu_axi_wdata,
                 second_leaf_a0 | 64'h40);
      tb_check1("AD PTE write covers all bytes", &ifu_axi_wstrb, 1'b1);
      tb_check1("AD PTE write is single last beat", ifu_axi_wlast, 1'b1);
    end
  endtask

  // A=0 第二页正常完成：AW/W/B 后只从当前 L0 leaf re-walk，不重走更老级；
  // PC=FFE 的 C+C 总 footprint=4B，因此第二页只能再出现一个 2B data AR。
  task automatic run_second_page_ad_success;
    reg [`XLEN-1:0] packet;
    reg [`XLEN-1:0] second_leaf_a1;
    integer waits;
    begin
      packet = 64'hfeed_beef_0001_0001;
      second_leaf_a1 = pte_for_page(NEXT_FETCH_PA_PAGE, PTE_USER_X_FLAGS);
      enter_second_page_ad_update("AD success path", packet);

      tick();
      tb_check1("AD normal AW accepted", ifu_axi_awvalid, 1'b0);
      tb_check1("AD normal W accepted", ifu_axi_wvalid, 1'b0);
      tb_check1("AD normal waits for B", ifu_axi_bready, 1'b1);
      tb_check1("AD normal emits no premature AR", ifu_axi_arvalid, 1'b0);
      tb_check1("AD normal emits no premature response", fetch_rsp_valid, 1'b0);

      ifu_axi_bvalid = 1'b1;
      tick();
      ifu_axi_bvalid = 1'b0;

      expect_ar("AD success re-walks same second-page L0 leaf only",
                pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0));
      drive_r(second_leaf_a1);
      expect_ar("AD success fetches exact remaining halfword",
                NEXT_FETCH_PA_PAGE);
      drive_fetch_halfword(packet, 3'd2);

      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("AD success response arrives", fetch_rsp_valid, 1'b1);
      tb_check1("AD success has no younger data AR", ifu_axi_arvalid, 1'b0);
      tb_check32("AD success preserves prefix and second halfword",
                 fetch_rsp_inst0, 32'h0001_0001);
      tb_check32("AD success leaves unused tail deterministic",
                 fetch_rsp_inst1, 32'h0000_0000);
      check_resp("AD success raw resp0", fetch_rsp_resp0, RESP_OK);
      check_resp("AD success raw resp1", fetch_rsp_resp1, RESP_OK);
      tb_check1("AD success raw split is canonical success=4",
                fetch_rsp_resp0_bytes == 3'd4, 1'b1);
      check_resp("AD success decoded slot0", dec0_resp, RESP_OK);
      check_resp("AD success decoded slot1", dec1_resp, RESP_OK);
      $display("[ACCESS-AD-NORMAL] prefix=2B aw=%016x rewalk=%016x remaining_ar=%016x raw=%08x/%08x split=%0d",
               pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0),
               pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0),
               NEXT_FETCH_PA_PAGE, fetch_rsp_inst0, fetch_rsp_inst1,
               fetch_rsp_resp0_bytes);
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
    end
  endtask

  // 同一 second-page 真实上下文中制造 AW-first + mmu_flush：flush 只能 sticky-drop
  // 旧 fetch 语义，仍须保持 W payload、补齐 W 并消费 B；即使 BRESP error 也不得
  // re-walk、发剩余 data AR 或交付旧 response，B 后必须释放 owner 接受新请求。
  task automatic run_second_page_ad_flush_drop;
    reg [`XLEN-1:0] packet;
    reg [`XLEN-1:0] held_awaddr;
    reg [`XLEN-1:0] held_wdata;
    begin
      packet = 64'hfeed_beef_0001_0001;
      enter_second_page_ad_update("AD flush-drop path", packet);
      held_awaddr = ifu_axi_awaddr;
      held_wdata = ifu_axi_wdata;

      ifu_axi_wready = 1'b0;
      tick();
      ifu_axi_awready = 1'b0;
      tb_check1("AD flush setup accepted AW only", ifu_axi_awvalid, 1'b0);
      tb_check1("AD flush setup leaves W pending", ifu_axi_wvalid, 1'b1);
      tb_check1("AD flush setup keeps BREADY", ifu_axi_bready, 1'b1);

      mmu_flush = 1'b1;
      tick();
      mmu_flush = 1'b0;
      tb_check1("AD flush retains write owner", ifu_axi_bready, 1'b1);
      tb_check1("AD flush keeps missing W valid", ifu_axi_wvalid, 1'b1);
      check_xlen("AD flush preserves AW address owner", ifu_axi_awaddr,
                 held_awaddr);
      check_xlen("AD flush preserves W payload", ifu_axi_wdata, held_wdata);
      tb_check1("AD flush suppresses read reissue", ifu_axi_arvalid, 1'b0);
      tb_check1("AD flush suppresses old response", fetch_rsp_valid, 1'b0);

      ifu_axi_wready = 1'b1;
      tick();
      ifu_axi_wready = 1'b0;
      tb_check1("AD flush completes missing W", ifu_axi_wvalid, 1'b0);
      tb_check1("AD flush waits delayed B", ifu_axi_bready, 1'b1);
      tb_check1("AD flush still has no read", ifu_axi_arvalid, 1'b0);

      ifu_axi_bresp = 2'b10;
      ifu_axi_bvalid = 1'b1;
      tick();
      ifu_axi_bvalid = 1'b0;
      ifu_axi_bresp = RESP_OK;
      tb_check1("AD flush B releases owner", ifu_axi_bready, 1'b0);
      tb_check1("AD flush B returns bridge ready", fetch_req_ready, 1'b1);
      repeat (3) begin
        tb_check1("AD flush never re-walks old leaf", ifu_axi_arvalid, 1'b0);
        tb_check1("AD flush never returns old fetch", fetch_rsp_valid, 1'b0);
        tick();
      end
      $display("[ACCESS-AD-FLUSH] prefix=2B aw-first=1 flush-drop=1 w-complete=1 b-error-consumed=1 owner-released=%0b",
               fetch_req_ready);
    end
  endtask

  task automatic check_xlen;
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
      pte_addr = base + {{(`XLEN-12){1'b0}}, vpn_by_level(vaddr, level),
                         3'b000};
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

  task automatic reset_case;
    begin
      rst = 1'b1;
      mmu_flush = 1'b0;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
      priv_mode = `PRIV_U;
      satp = SATP_VALUE;
      svpbmt_en = 1'b0;
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
      rsp_pc = {`XLEN{1'b0}};
      repeat (3) tick();
      rst = 1'b0;
      tick();
    end
  endtask

  task automatic expect_ar;
    input [1023:0] what;
    input [`XLEN-1:0] exp_addr;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_arvalid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, ifu_axi_arvalid, 1'b1);
      if (ifu_axi_arvalid === 1'b1) begin
        check_xlen(what, ifu_axi_araddr, exp_addr);
      end
      tick();
    end
  endtask

  task automatic drive_r;
    input [`XLEN-1:0] data;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_rready !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("G2 AXI R channel ready", ifu_axi_rready, 1'b1);
      ifu_axi_rdata = data;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
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
      while ((ifu_axi_rready !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("G2 instruction R channel ready", ifu_axi_rready, 1'b1);
      tb_check1("G2 instruction ARSIZE=2B", ifu_axi_arsize == 3'd1, 1'b1);
      tb_check1("G2 instruction ARPROT=exec", ifu_axi_arprot == 3'b100, 1'b1);
      case (byte_offset)
        3'd0: halfword = packet[15:0];
        3'd2: halfword = packet[31:16];
        3'd4: halfword = packet[47:32];
        default: halfword = packet[63:48];
      endcase
      lane_data = {{(`XLEN-16){1'b0}}, halfword} <<
                  {ifu_axi_araddr[2:0], 3'b000};
      ifu_axi_rdata = lane_data;
      ifu_axi_rresp = RESP_OK;
      ifu_axi_rvalid = 1'b1;
      tick();
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
    end
  endtask

  // 每一行矩阵都走真实 Sv39 三级 walk。只有真实 N>B 时才启动第二页 walk，并在
  // L0 返回 invalid PTE；N<=B 必须在第一页 exact footprint 后直接成功。
  task automatic walk_first_page_ok_next_page_fault;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] first_beat;
    integer l0_bytes;
    integer l1_bytes;
    integer needed_bytes;
    integer first_page_bytes;
    integer offset;
    begin
      expect_ar(what, pte_addr(ROOT_PT, pc, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L1_PT, pc, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L0_PT, pc, 2'd0));
      drive_r(pte_for_page(FETCH_PA_PAGE, PTE_USER_X_FLAGS));

      l0_bytes = (first_beat[1:0] == 2'b11) ? 4 : 2;
      l1_bytes = (l0_bytes == 2) ?
                 ((first_beat[17:16] == 2'b11) ? 4 : 2) :
                 ((first_beat[33:32] == 2'b11) ? 4 : 2);
      needed_bytes = l0_bytes + l1_bytes;
      first_page_bytes = 4096 - pc[11:0];
      for (offset = 0;
           (offset < needed_bytes) && (offset < first_page_bytes);
           offset = offset + 2) begin
        expect_ar(what, FETCH_PA_PAGE + {52'd0, pc[11:0]} + offset);
        drive_fetch_halfword(first_beat, offset[2:0]);
      end

      if (needed_bytes > first_page_bytes) begin
        expect_ar(what, pte_addr(ROOT_PT, NEXT_PAGE_VA, 2'd2));
        drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
        expect_ar(what, pte_addr(L1_PT, NEXT_PAGE_VA, 2'd1));
        drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
        expect_ar(what, pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0));
        // invalid leaf R 是 fault frontier 的闭合事件；从该拍起任何新 AR 都是
        // 年轻访问，必须在 response 被消费前持续为零。
        fault_frontier_seen_q = 1'b1;
        drive_r({`XLEN{1'b0}});  // V=0: 真实 next-page instruction page fault
      end
    end
  endtask

  // 先完成一笔四个 halfword 都非零的 8B packet，再不复位进入下一笔 fault。
  // 下一笔只覆盖 successful prefix；若 S_CACHE_READ 未清空 scratch，未取回 suffix
  // 会保留这笔 transaction 的旧值，tail-zero oracle 因而不是复位零值假绿。
  task automatic prefill_stale_packet_for_next_case;
    reg [`XLEN-1:0] packet;
    integer waits;
    integer offset;
    begin
      packet = 64'h8877_6657_4433_2213;
      preserve_state_for_next_case_q = 1'b0;
      positive_control_monitor_q = 1'b0;
      reset_case();
      positive_control_instruction_ar_count_q = 0;
      positive_control_cache_fill_count_q = 0;
      positive_control_sram_write_count_q = 0;
      positive_control_monitor_q = 1'b1;
      rsp_pc = PC_STALE_PREFILL;
      fetch_req_pc = PC_STALE_PREFILL;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("G2 stale prefill request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};

      expect_ar("G2 stale prefill root PTE",
                pte_addr(ROOT_PT, PC_STALE_PREFILL, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar("G2 stale prefill L1 PTE",
                pte_addr(L1_PT, PC_STALE_PREFILL, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar("G2 stale prefill L0 PTE",
                pte_addr(L0_PT, PC_STALE_PREFILL, 2'd0));
      drive_r(pte_for_page(FETCH_PA_PAGE, PTE_USER_X_FLAGS));

      for (offset = 0; offset < 8; offset = offset + 2) begin
        expect_ar("G2 stale prefill instruction halfword",
                  FETCH_PA_PAGE + {61'd0, offset[2:0]});
        drive_fetch_halfword(packet, offset[2:0]);
      end

      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("G2 stale prefill response arrives", fetch_rsp_valid, 1'b1);
      tb_check32("G2 stale prefill raw low word",
                 fetch_rsp_inst0, packet[31:0]);
      tb_check32("G2 stale prefill raw high word",
                 fetch_rsp_inst1, packet[63:32]);
      check_resp("G2 stale prefill raw resp0", fetch_rsp_resp0, RESP_OK);
      check_resp("G2 stale prefill raw resp1", fetch_rsp_resp1, RESP_OK);
      tb_check1("G2 stale prefill canonical success split",
                fetch_rsp_resp0_bytes == 3'd4, 1'b1);
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
      tb_check1("G2 stale prefill retires to request-ready",
                fetch_req_ready, 1'b1);
      tb_check1("G2 positive control presents four instruction AR offers",
                positive_control_instruction_ar_count_q == 4, 1'b1);
      tb_check1("G2 positive control presents one packet-cache fill",
                positive_control_cache_fill_count_q == 1, 1'b1);
      tb_check1("G2 positive control presents one effective SRAM write",
                positive_control_sram_write_count_q == 1, 1'b1);
      positive_control_monitor_q = 1'b0;
      preserve_state_for_next_case_q = 1'b1;
      $display("[G2-STALE-PREFILL] pc=%016x raw=%016x no_reset_next=1 PASS",
               PC_STALE_PREFILL, packet);
      $display("[G2-POSITIVE-CONTROL] instruction_ar=%0d cache_fill=%0d sram_write=%0d PASS",
               positive_control_instruction_ar_count_q,
               positive_control_cache_fill_count_q,
               positive_control_sram_write_count_q);
    end
  endtask

  // response ABI 的零 frontier 可达性：第一页根 PTE 即 V=0，故不存在成功
  // instruction byte。bridge 必须输出 split=0/全零 raw packet；decoder 在读取
  // 任一长度位前让两个 slot 都消费 page fault 并净化为 NOP。
  task automatic run_first_page_f0_fault;
    integer waits;
    reg [`INST_W-1:0] held_inst0;
    reg [`INST_W-1:0] held_inst1;
    reg [1:0] held_resp0;
    reg [1:0] held_resp1;
    reg [2:0] held_frontier;
    begin
      fault_txn_monitor_q = 1'b0;
      fault_frontier_seen_q = 1'b0;
      reset_case();
      fault_cache_fill_count_q = 0;
      fault_sram_write_count_q = 0;
      fault_monitor_cycles_q = 0;
      fault_frontier_cycles_q = 0;
      fault_instruction_ar_count_q = 0;
      fault_post_frontier_ar_count_q = 0;
      fault_txn_monitor_q = 1'b1;
      rsp_pc = PC_F0;
      fetch_req_pc = PC_F0;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("G2 F0 fetch request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};

      expect_ar("G2 F0 root PTE", pte_addr(ROOT_PT, PC_F0, 2'd2));
      fault_frontier_seen_q = 1'b1;
      drive_r({`XLEN{1'b0}});
      tb_check1("G2 F0 frontier immediately blocks younger AR",
                ifu_axi_arvalid, 1'b0);

      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("G2 F0 response arrives", fetch_rsp_valid, 1'b1);
      held_inst0 = fetch_rsp_inst0;
      held_resp0 = fetch_rsp_resp0;
      held_inst1 = fetch_rsp_inst1;
      held_resp1 = fetch_rsp_resp1;
      held_frontier = fetch_rsp_resp0_bytes;
      tb_check32("G2 F0 raw low word is zero", held_inst0, 32'd0);
      tb_check32("G2 F0 raw high word is zero", held_inst1, 32'd0);
      check_resp("G2 F0 raw prefix owner", held_resp0, RESP_OK);
      check_resp("G2 F0 raw fault owner", held_resp1, RESP_PAGE_FAULT);
      tb_check1("G2 F0 raw split is zero", held_frontier == 3'd0, 1'b1);
      check_resp("G2 F0 decoded slot0 fault", dec0_resp, RESP_PAGE_FAULT);
      check_resp("G2 F0 decoded slot1 inherited fault",
                 dec1_resp, RESP_PAGE_FAULT);
      tb_check32("G2 F0 decoded slot0 sanitized", dec0_inst, 32'h0000_0013);
      tb_check32("G2 F0 decoded slot1 sanitized", dec1_inst, 32'h0000_0013);
      check_xlen("G2 F0 precise fault tval", dec_fault_tval, PC_F0);

      fetch_req_pc = PC_F0 ^ 64'h0000_0000_0000_0882;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("G2 F0 stalled owner blocks alternate request",
                fetch_req_ready, 1'b0);
      repeat (2) begin
        tick();
        tb_check1("G2 F0 stalled response remains valid",
                  fetch_rsp_valid, 1'b1);
        tb_check32("G2 F0 stalled low word stable",
                   fetch_rsp_inst0, held_inst0);
        tb_check32("G2 F0 stalled high word stable",
                   fetch_rsp_inst1, held_inst1);
        check_resp("G2 F0 stalled resp0 stable", fetch_rsp_resp0, held_resp0);
        check_resp("G2 F0 stalled resp1 stable", fetch_rsp_resp1, held_resp1);
        tb_check1("G2 F0 stalled frontier stable",
                  fetch_rsp_resp0_bytes == held_frontier, 1'b1);
        tb_check1("G2 F0 stalled owner keeps alternate request blocked",
                  fetch_req_ready, 1'b0);
      end
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
      repeat (2) begin
        tb_check1("G2 F0 accepted response is no longer valid",
                  fetch_rsp_valid, 1'b0);
        tb_check1("G2 F0 post-accept window has no younger AR",
                  ifu_axi_arvalid, 1'b0);
        tb_check1("G2 F0 post-accept window has no cache fill",
                  u_bridge.fetch_cache_fill_valid_w, 1'b0);
        tb_check1("G2 F0 post-accept window has no SRAM write",
                  u_bridge.u_fetch_packet_cache.sram_we_w, 1'b0);
        tick();
      end
      tb_check1("G2 F0 emits zero instruction-data AR",
                fault_instruction_ar_count_q == 0, 1'b1);
      tb_check1("G2 F0 emits no younger AR",
                fault_post_frontier_ar_count_q == 0, 1'b1);
      tb_check1("G2 F0 emits no packet-cache fill",
                fault_cache_fill_count_q == 0, 1'b1);
      tb_check1("G2 F0 emits no effective SRAM write",
                fault_sram_write_count_q == 0, 1'b1);
      $display("[G2-BRIDGE-F0] split=0 raw_zero=1 decoded_fault=2/2 sanitized=1/1 instruction_ar=%0d stall_cycles=2 post_accept_quiet_cycles=2 younger_ar=%0d cache_fill=%0d sram_write=%0d PASS",
               fault_instruction_ar_count_q, fault_post_frontier_ar_count_q,
               fault_cache_fill_count_q, fault_sram_write_count_q);
      fault_txn_monitor_q = 1'b0;
      fault_frontier_seen_q = 1'b0;
    end
  endtask

  task automatic run_case;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] first_beat;
    input [1:0] exp_dec0_resp;
    input [1:0] exp_dec1_resp;
    integer waits;
    integer first_page_bytes;
    reg fault_case;
    reg [2:0] expected_frontier;
    reg [`XLEN-1:0] raw_packet;
    reg prefix_ok;
    reg tail_zero;
    reg [`INST_W-1:0] held_inst0;
    reg [1:0] held_resp0;
    reg [`INST_W-1:0] held_inst1;
    reg [1:0] held_resp1;
    reg [2:0] held_frontier;
    begin
      first_page_bytes = 4096 - pc[11:0];
      // 是否为 fault 行直接取既有 matrix owner 期望，避免 monitor 与 DUT/driver
      // 共用一份长度判定而把同一个错误同时算成“不需要观察”。
      fault_case = (exp_dec0_resp == RESP_PAGE_FAULT) ||
                   (exp_dec1_resp == RESP_PAGE_FAULT);
      expected_frontier = first_page_bytes[2:0];

      fault_txn_monitor_q = 1'b0;
      fault_frontier_seen_q = 1'b0;
      if (preserve_state_for_next_case_q) begin
        preserve_state_for_next_case_q = 1'b0;
        tb_check1("G2 preserved-state case starts request-ready",
                  fetch_req_ready, 1'b1);
      end else begin
        reset_case();
      end
      fault_cache_fill_count_q = 0;
      fault_sram_write_count_q = 0;
      fault_monitor_cycles_q = 0;
      fault_frontier_cycles_q = 0;
      fault_instruction_ar_count_q = 0;
      fault_post_frontier_ar_count_q = 0;
      fault_txn_monitor_q = fault_case;
      rsp_pc = pc;
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("G2 fetch request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};

      walk_first_page_ok_next_page_fault(what, pc, first_beat);
      if (fault_case) begin
        // 故意 hold response 两拍；若 fault 后错误续发 instruction/PTE AR，
        // sticky monitor 与逐拍直接检查会同时报错。
        tb_check1("G2 fault frontier immediately blocks younger AR",
                  ifu_axi_arvalid, 1'b0);
        repeat (2) begin
          tick();
          tb_check1("G2 held fault response blocks younger AR",
                    ifu_axi_arvalid, 1'b0);
        end
      end
      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1({what, " response arrives"}, fetch_rsp_valid, 1'b1);
      if (fetch_rsp_valid === 1'b1) begin
        if (fault_case) begin
          held_inst0 = fetch_rsp_inst0;
          held_resp0 = fetch_rsp_resp0;
          held_inst1 = fetch_rsp_inst1;
          held_resp1 = fetch_rsp_resp1;
          held_frontier = fetch_rsp_resp0_bytes;
          fetch_req_pc = pc ^ 64'h0000_0000_0000_0882;
          fetch_req_valid = 1'b1;
          #1;
          tb_check1({what, " stalled owner blocks alternate request"},
                    fetch_req_ready, 1'b0);
          repeat (2) begin
            tick();
            tb_check1({what, " stalled owner keeps alternate request blocked"},
                      fetch_req_ready, 1'b0);
            tb_check1({what, " stalled response remains valid"},
                      fetch_rsp_valid, 1'b1);
            tb_check32({what, " stalled inst0 stable"},
                       fetch_rsp_inst0, held_inst0);
            check_resp({what, " stalled resp0 stable"},
                       fetch_rsp_resp0, held_resp0);
            tb_check32({what, " stalled inst1 stable"},
                       fetch_rsp_inst1, held_inst1);
            check_resp({what, " stalled resp1 stable"},
                       fetch_rsp_resp1, held_resp1);
            tb_check1({what, " stalled frontier stable"},
                      fetch_rsp_resp0_bytes == held_frontier, 1'b1);
          end
          fetch_req_valid = 1'b0;
          fetch_req_pc = {`XLEN{1'b0}};
          fault_stall_rows_q = fault_stall_rows_q + 1;
          fault_stall_cycles_q = fault_stall_cycles_q + 2;
        end
        $display("[G2-MATRIX] %0s pc=%016x raw=%0b/%0b decoded=%0b/%0b expected=%0b/%0b",
                 what, pc, fetch_rsp_resp0, fetch_rsp_resp1,
                 dec0_resp, dec1_resp, exp_dec0_resp, exp_dec1_resp);
        check_xlen("G2 slot0 PC", dec0_pc, pc);
        check_xlen("G2 slot1 PC follows true slot0 length", dec1_pc,
                   pc + ((first_beat[1:0] == 2'b11) ? 64'd4 : 64'd2));
        check_resp({what, " slot0 response"}, dec0_resp, exp_dec0_resp);
        check_resp({what, " slot1 response"}, dec1_resp, exp_dec1_resp);
        if (exp_dec0_resp != RESP_OK)
          tb_check32({what, " slot0 faulted inst is NOP"},
                     dec0_inst, 32'h0000_0013);
        if (exp_dec1_resp != RESP_OK)
          tb_check32({what, " slot1 faulted inst is NOP"},
                     dec1_inst, 32'h0000_0013);
        if (fault_case) begin
          raw_packet = {fetch_rsp_inst1, fetch_rsp_inst0};
          prefix_ok = 1'b0;
          tail_zero = 1'b0;
          case (expected_frontier)
            3'd2: begin
              prefix_ok = raw_packet[15:0] === first_beat[15:0];
              tail_zero = raw_packet[63:16] === 48'd0;
              raw_frontier_f2_rows_q = raw_frontier_f2_rows_q + 1;
            end
            3'd4: begin
              prefix_ok = raw_packet[31:0] === first_beat[31:0];
              tail_zero = raw_packet[63:32] === 32'd0;
              raw_frontier_f4_rows_q = raw_frontier_f4_rows_q + 1;
            end
            3'd6: begin
              prefix_ok = raw_packet[47:0] === first_beat[47:0];
              tail_zero = raw_packet[63:48] === 16'd0;
              raw_frontier_f6_rows_q = raw_frontier_f6_rows_q + 1;
            end
            default: begin
              prefix_ok = 1'b0;
              tail_zero = 1'b0;
            end
          endcase
          check_resp({what, " raw prefix owner"}, fetch_rsp_resp0, RESP_OK);
          check_resp({what, " raw fault owner"}, fetch_rsp_resp1,
                     RESP_PAGE_FAULT);
          tb_check1({what, " raw resp0_bytes is exact F=2/4/6"},
                    fetch_rsp_resp0_bytes == expected_frontier, 1'b1);
          check_xlen({what, " precise fault portion tval"}, dec_fault_tval,
                     pc + {{(`XLEN-3){1'b0}}, expected_frontier});
          tb_check1({what, " successful raw prefix retained"}, prefix_ok,
                    1'b1);
          tb_check1({what, " raw instruction tail after F is zero"},
                    tail_zero, 1'b1);
          tb_check1({what, " fault monitor spans transaction"},
                    fault_monitor_cycles_q > 0, 1'b1);
          tb_check1({what, " fault frontier monitor is non-vacuous"},
                    fault_frontier_cycles_q >= 3, 1'b1);
          tb_check1({what, " instruction AR count stops exactly at F"},
                    fault_instruction_ar_count_q ==
                        (expected_frontier >> 1), 1'b1);
          tb_check1({what, " fault frontier emits no younger AR"},
                    fault_post_frontier_ar_count_q == 0, 1'b1);
          tb_check1({what, " fault transaction emits no cache fill"},
                    fault_cache_fill_count_q == 0, 1'b1);
          tb_check1({what, " fault transaction emits no SRAM write"},
                    fault_sram_write_count_q == 0, 1'b1);
          $display("[G2-RAW-FAULT-OWNER] %0s F=%0d split=%0d prefix_ok=%0b tail_zero=%0b inst_ar=%0d monitor_cycles=%0d frontier_cycles=%0d younger_ar=%0d cache_fill=%0d sram_write=%0d raw=%016x",
                   what, expected_frontier, fetch_rsp_resp0_bytes,
                   prefix_ok, tail_zero, fault_instruction_ar_count_q,
                   fault_monitor_cycles_q, fault_frontier_cycles_q,
                   fault_post_frontier_ar_count_q,
                   fault_cache_fill_count_q, fault_sram_write_count_q,
                   raw_packet);
        end
      end
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
      if (fault_case) begin
        repeat (2) begin
          tb_check1({what, " accepted fault response is no longer valid"},
                    fetch_rsp_valid, 1'b0);
          tb_check1({what, " post-accept window has no younger AR"},
                    ifu_axi_arvalid, 1'b0);
          tb_check1({what, " post-accept window has no cache fill"},
                    u_bridge.fetch_cache_fill_valid_w, 1'b0);
          tb_check1({what, " post-accept window has no SRAM write"},
                    u_bridge.u_fetch_packet_cache.sram_we_w, 1'b0);
          tick();
        end
        fault_post_accept_quiet_cycles_q =
            fault_post_accept_quiet_cycles_q + 2;
        tb_check1({what, " late fault transaction emits no younger AR"},
                  fault_post_frontier_ar_count_q == 0, 1'b1);
        tb_check1({what, " late fault transaction emits no cache fill"},
                  fault_cache_fill_count_q == 0, 1'b1);
        tb_check1({what, " late fault transaction emits no SRAM write"},
                  fault_sram_write_count_q == 0, 1'b1);
        $display("[G2-POST-ACCEPT-QUIET] %0s cycles=2 younger_ar=%0d cache_fill=%0d sram_write=%0d PASS",
                 what, fault_post_frontier_ar_count_q,
                 fault_cache_fill_count_q, fault_sram_write_count_q);
      end
      fault_txn_monitor_q = 1'b0;
      fault_frontier_seen_q = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    fault_txn_monitor_q = 1'b0;
    fault_frontier_seen_q = 1'b0;
    fault_cache_fill_count_q = 0;
    fault_sram_write_count_q = 0;
    fault_monitor_cycles_q = 0;
    fault_frontier_cycles_q = 0;
    fault_instruction_ar_count_q = 0;
    fault_post_frontier_ar_count_q = 0;
    raw_frontier_f2_rows_q = 0;
    raw_frontier_f4_rows_q = 0;
    raw_frontier_f6_rows_q = 0;
    fault_stall_rows_q = 0;
    fault_stall_cycles_q = 0;
    fault_post_accept_quiet_cycles_q = 0;
    preserve_state_for_next_case_q = 1'b0;
    positive_control_monitor_q = 1'b0;
    positive_control_instruction_ar_count_q = 0;
    positive_control_cache_fill_count_q = 0;
    positive_control_sram_write_count_q = 0;

    // PC=FFA：本页还剩 6B。C+32 与 32+C 的两条指令都完整落在本页；
    // 32+32 仅第二条跨页。旧 word-resp 映射会把前两种的 slot1 错报为 fault。
    run_case("G2 FFA C+C", PC_FFA, 64'hbeef_dead_0001_0001,
             RESP_OK, RESP_OK);
    run_case("G2 FFA C+32", PC_FFA, 64'hdead_0010_0093_0001,
             RESP_OK, RESP_OK);
    run_case("G2 FFA 32+C", PC_FFA, 64'hdead_0001_0010_0093,
             RESP_OK, RESP_OK);
    run_case("G2 FFA 32+32", PC_FFA, 64'h0010_0093_0010_0093,
             RESP_OK, RESP_PAGE_FAULT);

    // PC=FFC：本页还剩 4B。只有 C+C 或首条 32-bit 能完全留在本页；其余 slot1
    // 需要下一页。四种长度组合共同钉住边界等号与 decoder 的 resp 选择。
    run_case("G2 FFC C+C", PC_FFC, 64'hbeef_dead_0001_0001,
             RESP_OK, RESP_OK);
    run_case("G2 FFC C+32", PC_FFC, 64'hdead_0010_0093_0001,
             RESP_OK, RESP_PAGE_FAULT);
    run_case("G2 FFC 32+C", PC_FFC, 64'hdead_0001_0010_0093,
             RESP_OK, RESP_PAGE_FAULT);
    run_case("G2 FFC 32+32", PC_FFC, 64'h0010_0093_0010_0093,
             RESP_OK, RESP_PAGE_FAULT);

    // PC=FFE：本页只剩 2B。第一条 C 必须成功、slot1 必须 fault；第一条 32-bit
    // 必须 fault。C+C 特意令无效 tail halfword=16'h0001（看似 C.NOP），证明 fault
    // 归属不能由 next-page 垃圾解码结果决定。
    run_case("G2 FFE C+C tail-garbage-C", PC_FFE,
             64'hfeed_beef_0001_0001, RESP_OK, RESP_PAGE_FAULT);
    run_case("G2 FFE C+32", PC_FFE, 64'hfeed_0010_0093_0001,
             RESP_OK, RESP_PAGE_FAULT);
    run_case("G2 FFE 32+C", PC_FFE, 64'hfeed_0001_0010_0093,
             RESP_PAGE_FAULT, RESP_PAGE_FAULT);
    run_case("G2 FFE 32+32", PC_FFE, 64'h0010_0093_0010_0093,
             RESP_PAGE_FAULT, RESP_PAGE_FAULT);

    // 使用上一笔完整非零 packet 污染 scratch，然后无复位重放 F=2 fault。
    prefill_stale_packet_for_next_case();
    run_case("G2 FFE C+32 after stale prefill", PC_FFE,
             64'hfeed_0010_0093_0001, RESP_OK, RESP_PAGE_FAULT);

    run_first_page_f0_fault();

    // IFU-ACCESS-G1：把 second-page A=0 与 exact 2B footprint、prefix provenance、
    // A-update re-walk，以及 mmu_flush write-drain 绑定到同一真实跨页请求。
    run_second_page_ad_success();
    run_second_page_ad_flush_drop();

    tb_check1("G2 raw fault matrix covers five F=2 rows",
              raw_frontier_f2_rows_q == 5, 1'b1);
    tb_check1("G2 raw fault matrix covers three F=4 rows",
              raw_frontier_f4_rows_q == 3, 1'b1);
    tb_check1("G2 raw fault matrix covers one F=6 row",
              raw_frontier_f6_rows_q == 1, 1'b1);
    tb_check1("G2 all fault rows hold response under backpressure",
              fault_stall_rows_q == 9, 1'b1);
    tb_check1("G2 fault response stability spans eighteen cycles",
              fault_stall_cycles_q == 18, 1'b1);
    tb_check1("G2 post-accept quiet window spans eighteen cycles",
              fault_post_accept_quiet_cycles_q == 18, 1'b1);
    $display("[G2-RAW-FAULT-SUMMARY] F2=%0d F4=%0d F6=%0d total=%0d",
             raw_frontier_f2_rows_q, raw_frontier_f4_rows_q,
             raw_frontier_f6_rows_q,
             raw_frontier_f2_rows_q + raw_frontier_f4_rows_q +
             raw_frontier_f6_rows_q);
    $display("[G2-CURRENT-DESIGN] matrix_rows=13 fault_rows=9 F2=5 F4=3 F6=1 stall_rows=%0d stall_cycles=%0d post_accept_quiet_cycles=%0d payload_stability=1 stale_prefill=1 PASS",
             fault_stall_rows_q, fault_stall_cycles_q,
             fault_post_accept_quiet_cycles_q);
    $display("[TVAL-G1-PAGE-END] PF=9 F2=5 F4=3 F6=1 tval=packet_pc+F PASS");

    tb_finish("tb_ooo_fetch_page_end_fault");
  end

endmodule
