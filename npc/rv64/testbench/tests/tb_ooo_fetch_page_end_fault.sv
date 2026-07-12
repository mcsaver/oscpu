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
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;
  wire ifu_axi_awvalid;
  reg ifu_axi_awready;
  wire ifu_axi_wvalid;
  reg ifu_axi_wready;
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
  wire [`XLEN-1:0] dec0_bimm;
  wire dec1_branch;
  wire [`XLEN-1:0] dec1_bimm;
  wire [`XLEN-1:0] packet_next_pc;

  localparam [1:0] RESP_OK = 2'b00;
  localparam [1:0] RESP_PAGE_FAULT = 2'b10;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] L1_PT = 64'h0000_0000_8100_1000;
  localparam [`XLEN-1:0] L0_PT = 64'h0000_0000_8100_2000;
  localparam [`XLEN-1:0] FETCH_PA_PAGE = 64'h0000_0000_8200_4000;
  localparam [`XLEN-1:0] PC_FFA = 64'h0000_0000_0000_4ffa;
  localparam [`XLEN-1:0] PC_FFC = 64'h0000_0000_0000_4ffc;
  localparam [`XLEN-1:0] PC_FFE = 64'h0000_0000_0000_4ffe;
  localparam [`XLEN-1:0] NEXT_PAGE_VA = 64'h0000_0000_0000_5000;
  localparam [`XLEN-1:0] SATP_VALUE =
      64'h8000_0000_0000_0000 | (ROOT_PT >> 12);
  localparam [`XLEN-1:0] PTE_NONLEAF_FLAGS = 64'h001;
  localparam [`XLEN-1:0] PTE_USER_X_FLAGS = 64'h0df;
  localparam [`PMP_CFG_BUS_W-1:0] PMP_ALLOW_ALL_CFG =
      {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
  localparam [`PMP_ADDR_BUS_W-1:0] PMP_ALLOW_ALL_ADDR =
      {`PMP_ADDR_BUS_W{1'b1}};

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
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .ifu_axi_awvalid_o(ifu_axi_awvalid),
    .ifu_axi_awready_i(ifu_axi_awready),
    .ifu_axi_wvalid_o(ifu_axi_wvalid),
    .ifu_axi_wready_i(ifu_axi_wready),
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
    .packet_next_pc_o(packet_next_pc)
  );

  always #5 clk = ~clk;

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

  // 每一行矩阵都走真实 Sv39 三级 walk：第一页得到可执行 leaf，第二页在 L0 返回
  // invalid PTE，随后仍只取回第一页剩余字节。这样 RED 不依赖层次化 deposit。
  task automatic walk_first_page_ok_next_page_fault;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] first_beat;
    begin
      expect_ar(what, pte_addr(ROOT_PT, pc, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L1_PT, pc, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L0_PT, pc, 2'd0));
      drive_r(pte_for_page(FETCH_PA_PAGE, PTE_USER_X_FLAGS));

      expect_ar(what, pte_addr(ROOT_PT, NEXT_PAGE_VA, 2'd2));
      drive_r(pte_for_page(L1_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L1_PT, NEXT_PAGE_VA, 2'd1));
      drive_r(pte_for_page(L0_PT, PTE_NONLEAF_FLAGS));
      expect_ar(what, pte_addr(L0_PT, NEXT_PAGE_VA, 2'd0));
      drive_r({`XLEN{1'b0}});  // V=0: 真实 next-page instruction page fault

      expect_ar(what, FETCH_PA_PAGE + {52'd0, pc[11:0]});
      drive_r(first_beat);
    end
  endtask

  task automatic run_case;
    input [1023:0] what;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] first_beat;
    input [1:0] exp_dec0_resp;
    input [1:0] exp_dec1_resp;
    integer waits;
    begin
      reset_case();
      rsp_pc = pc;
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("G2 fetch request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};

      walk_first_page_ok_next_page_fault(what, pc, first_beat);
      waits = 0;
      while ((fetch_rsp_valid !== 1'b1) && (waits < 30)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1(what, fetch_rsp_valid, 1'b1);
      if (fetch_rsp_valid === 1'b1) begin
        $display("[G2-MATRIX] %0s pc=%016x raw=%0b/%0b decoded=%0b/%0b expected=%0b/%0b",
                 what, pc, fetch_rsp_resp0, fetch_rsp_resp1,
                 dec0_resp, dec1_resp, exp_dec0_resp, exp_dec1_resp);
        check_xlen("G2 slot0 PC", dec0_pc, pc);
        check_xlen("G2 slot1 PC follows true slot0 length", dec1_pc,
                   pc + ((first_beat[1:0] == 2'b11) ? 64'd4 : 64'd2));
        check_resp({what, " slot0 response"}, dec0_resp, exp_dec0_resp);
        check_resp({what, " slot1 response"}, dec1_resp, exp_dec1_resp);
      end
      fetch_rsp_ready = 1'b1;
      tick();
      fetch_rsp_ready = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;

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

    tb_finish("tb_ooo_fetch_page_end_fault");
  end

endmodule
