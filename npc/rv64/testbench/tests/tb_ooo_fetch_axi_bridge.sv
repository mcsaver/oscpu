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
  reg fetch_req_valid;
  wire fetch_req_ready;
  reg [`XLEN-1:0] fetch_req_pc;
  wire fetch_rsp_valid;
  reg fetch_rsp_ready;
  wire [`INST_W-1:0] fetch_rsp_inst0;
  wire [1:0] fetch_rsp_resp0;
  wire [`INST_W-1:0] fetch_rsp_inst1;
  wire [1:0] fetch_rsp_resp1;
  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
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
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam [`XLEN-1:0] PTE_A_BIT_TB = 64'h40;  // bit 6 (Accessed)
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] L1_PT = 64'h0000_0000_8100_1000;
  localparam [`XLEN-1:0] L0_PT = 64'h0000_0000_8100_2000;
  localparam [`XLEN-1:0] USER_VA = 64'h0000_0000_0000_4000;
  localparam [`XLEN-1:0] USER_PA = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] CROSS_VA = 64'h0000_0000_0000_4ffe;
  localparam [`XLEN-1:0] CROSS_NEXT_VA = 64'h0000_0000_0000_5000;
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
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
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
      expect_ar(what, paddr);
      drive_r(inst_beat, RESP_OK);
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
      expect_ar(what, paddr);                 // 取指令
      drive_r(inst_beat, RESP_OK);
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

      expect_ar(what, pte_addr(ROOT_PT, CROSS_NEXT_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L1_PT, CROSS_NEXT_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS), RESP_OK);
      expect_ar(what, pte_addr(L0_PT, CROSS_NEXT_VA, 2'd0));
      drive_r(pte_for_page(CROSS_PA1, PTE_USER_X_FLAGS), RESP_OK);

      expect_ar(what, CROSS_PA0 + 64'hffe);
      drive_r(CROSS_FIRST_BEAT, RESP_OK);
      expect_ar(what, CROSS_PA1);
      drive_r(CROSS_SECOND_BEAT, RESP_OK);
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
               RESP_PAGE_FAULT, RESP_PAGE_FAULT, {`XLEN{1'b0}});

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

    start_fetch("cross-page user fetch request accepted", CROSS_VA, `PRIV_U);
    walk_to_cross_fetch("cross-page packet uses translated next page");
    expect_rsp("cross-page packet merges non-contiguous pages",
               RESP_OK, RESP_OK, CROSS_MERGED_BEAT);

    // ===== 刀F 融合拍定向用例(hit 流 1 包/拍契约) =====
    // 预热两个 M 模式直取包(miss+fill)
    start_fetch("fusion warm pc1 accepted", FUSION_PC1, `PRIV_M);
    expect_ar("fusion warm pc1 goes axi", FUSION_PC1);
    drive_r(FUSION_BEAT1, RESP_OK);
    expect_rsp("fusion warm pc1 resp", RESP_OK, RESP_OK, FUSION_BEAT1);
    start_fetch("fusion warm pc2 accepted", FUSION_PC2, `PRIV_M);
    expect_ar("fusion warm pc2 goes axi", FUSION_PC2);
    drive_r(FUSION_BEAT2, RESP_OK);
    expect_rsp("fusion warm pc2 resp", RESP_OK, RESP_OK, FUSION_BEAT2);

    // hit 1 拍口径 + 融合拍 back-to-back: fire 次拍 rsp 组合可见且同拍收下一请求
    priv_mode = `PRIV_M;
    fetch_req_pc = FUSION_PC1;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tb_check1("fusion refetch pc1 ready", fetch_req_ready, 1'b1);
    tick();                       // fire PC1 → 判决拍
    fetch_req_pc = FUSION_PC2;    // 判决拍驱动下一请求(valid 保持)
    #1;
    tb_check1("fusion hit rsp in 1 cycle", fetch_rsp_valid, 1'b1);
    tb_check32_local("fusion hit inst0", fetch_rsp_inst0,
                     FUSION_BEAT1[`INST_W-1:0]);
    tb_check1("fusion beat accepts next req", fetch_req_ready, 1'b1);
    tick();                       // 融合拍: PC1 rsp 消费 + PC2 fire, 留 S_LOOKUP
    fetch_req_valid = 1'b0;
    #1;
    tb_check1("fusion back-to-back second rsp", fetch_rsp_valid, 1'b1);
    tb_check32_local("fusion second inst0", fetch_rsp_inst0,
                     FUSION_BEAT2[`INST_W-1:0]);
    tick();                       // PC2 rsp 消费, 无新请求 → S_IDLE
    fetch_rsp_ready = 1'b0;
    #1;
    tb_check1("fusion drain back to idle ready", fetch_req_ready, 1'b1);

    // rsp 反压: hit 拍 rsp_ready=0 → 组合 rsp 保持 valid 但 ready=0, 次拍落寄存 S_RESP
    fetch_req_pc = FUSION_PC1;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b0;
    #1;
    tick();                       // fire → 判决拍
    fetch_req_valid = 1'b0;
    #1;
    tb_check1("stalled hit rsp valid", fetch_rsp_valid, 1'b1);
    tb_check1("stalled hit not ready for next", fetch_req_ready, 1'b0);
    tick();                       // 落寄存进 S_RESP(天然 skid)
    #1;
    tb_check1("skid holds rsp valid", fetch_rsp_valid, 1'b1);
    tb_check32_local("skid holds inst0", fetch_rsp_inst0,
                     FUSION_BEAT1[`INST_W-1:0]);
    fetch_rsp_ready = 1'b1;
    tick();                       // 消费
    fetch_rsp_ready = 1'b0;

    // miss 拍 ready=0: 冷地址判决拍不受理新请求(1RW/上下文单套防线)
    fetch_req_pc = FUSION_PC3_COLD;
    fetch_req_valid = 1'b1;
    fetch_rsp_ready = 1'b1;
    #1;
    tick();                       // fire → 判决拍(miss)
    #1;
    tb_check1("miss beat rsp not valid", fetch_rsp_valid, 1'b0);
    tb_check1("miss beat not ready", fetch_req_ready, 1'b0);
    fetch_req_valid = 1'b0;
    expect_ar("miss beat direct AR", FUSION_PC3_COLD);
    drive_r(FUSION_BEAT3, RESP_OK);
    expect_rsp("miss path resp unchanged", RESP_OK, RESP_OK, FUSION_BEAT3);

    tb_finish("tb_ooo_fetch_axi_bridge");
  end
endmodule
