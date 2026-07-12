`include "define.v"
`include "tb_common.svh"

// IFU-ACCESS-G1 属性 RED：旧 bridge 把所有 IFU read 都固定成 exec+8B；正确合同是
// PTE walk=data+8B、instruction data=exec+2B，且 ARVALID 反压期间 payload 不变。
module tb_ooo_fetch_axi_access_attrs;
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
  wire fetch_rsp_valid;
  reg fetch_rsp_ready;

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
  wire ifu_axi_wvalid;
  reg ifu_axi_wready;
  reg ifu_axi_bvalid;
  wire ifu_axi_bready;
  reg [1:0] ifu_axi_bresp;

  localparam [`XLEN-1:0] DIRECT_PC = 64'h0000_0000_8000_0102;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8100_0000;
  localparam [`XLEN-1:0] USER_VA = 64'h0000_0000_0000_4000;
  localparam [`XLEN-1:0] SATP_VALUE =
      64'h8000_0000_0000_0000 | (ROOT_PT >> 12);

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
    .fetch_rsp_valid_o(fetch_rsp_valid),
    .fetch_rsp_ready_i(fetch_rsp_ready),
    .fetch_rsp_inst0_o(),
    .fetch_rsp_resp0_o(),
    .fetch_rsp_inst1_o(),
    .fetch_rsp_resp1_o(),
    .fetch_rsp_resp0_bytes_o(),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_arid_o(),
    .ifu_axi_arlen_o(),
    .ifu_axi_arsize_o(ifu_axi_arsize),
    .ifu_axi_arburst_o(),
    .ifu_axi_arprot_o(ifu_axi_arprot),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .ifu_axi_awvalid_o(ifu_axi_awvalid),
    .ifu_axi_awready_i(ifu_axi_awready),
    .ifu_axi_awaddr_o(),
    .ifu_axi_awid_o(),
    .ifu_axi_awlen_o(),
    .ifu_axi_awsize_o(),
    .ifu_axi_awburst_o(),
    .ifu_axi_wvalid_o(ifu_axi_wvalid),
    .ifu_axi_wready_i(ifu_axi_wready),
    .ifu_axi_wdata_o(),
    .ifu_axi_wstrb_o(),
    .ifu_axi_wlast_o(),
    .ifu_axi_bvalid_i(ifu_axi_bvalid),
    .ifu_axi_bready_o(ifu_axi_bready),
    .ifu_axi_bresp_i(ifu_axi_bresp)
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
      #5 clk = 1'b1;
      #5 clk = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
      rst = 1'b1;
      mmu_flush = 1'b0;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      svpbmt_en = 1'b0;
      pmpcfg = {{(`PMP_ENTRY_COUNT-1){8'h00}}, 8'h1f};
      pmpaddr = {`PMP_ADDR_BUS_W{1'b1}};
      fetch_req_valid = 1'b0;
      fetch_req_pc = {`XLEN{1'b0}};
      fetch_rsp_ready = 1'b0;
      ifu_axi_arready = 1'b0;
      ifu_axi_rvalid = 1'b0;
      ifu_axi_rdata = {`XLEN{1'b0}};
      ifu_axi_rresp = 2'b00;
      ifu_axi_awready = 1'b0;
      ifu_axi_wready = 1'b0;
      ifu_axi_bvalid = 1'b0;
      ifu_axi_bresp = 2'b00;
      tick();
      tick();
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic accept_fetch;
    input [`XLEN-1:0] pc;
    begin
      fetch_req_pc = pc;
      fetch_req_valid = 1'b1;
      #1;
      tb_check1("fetch request accepted", fetch_req_ready, 1'b1);
      tick();
      fetch_req_valid = 1'b0;
    end
  endtask

  task automatic wait_arvalid;
    integer waits;
    begin
      waits = 0;
      while ((ifu_axi_arvalid !== 1'b1) && (waits < 8)) begin
        tick();
        waits = waits + 1;
      end
      tb_check1("AR becomes valid", ifu_axi_arvalid, 1'b1);
    end
  endtask

  task automatic check_stalled_ar_hold;
    input [1023:0] what;
    reg [`XLEN-1:0] held_addr;
    reg [2:0] held_size;
    reg [2:0] held_prot;
    begin
      held_addr = ifu_axi_araddr;
      held_size = ifu_axi_arsize;
      held_prot = ifu_axi_arprot;
      // 改动所有 live request 输入，证明 pending AR payload 只来自已锁存事务。
      fetch_req_pc = 64'hffff_ffff_dead_beee;
      priv_mode = `PRIV_M;
      satp = {`XLEN{1'b0}};
      repeat (2) begin
        tick();
        tb_check1({what, " valid"}, ifu_axi_arvalid, 1'b1);
        tb_check64({what, " addr"}, ifu_axi_araddr, held_addr);
        tb_check64({what, " size"}, {{(`XLEN-3){1'b0}}, ifu_axi_arsize},
                   {{(`XLEN-3){1'b0}}, held_size});
        tb_check64({what, " prot"}, {{(`XLEN-3){1'b0}}, ifu_axi_arprot},
                   {{(`XLEN-3){1'b0}}, held_prot});
      end
    end
  endtask

  initial begin
    clk = 1'b0;
    tb_errors = 0;

    reset_dut();
    accept_fetch(DIRECT_PC);
    wait_arvalid();
    tb_check64("instruction AR exact PC", ifu_axi_araddr, DIRECT_PC);
    tb_check64("instruction ARSIZE is 2B", {{(`XLEN-3){1'b0}}, ifu_axi_arsize},
               {{(`XLEN-3){1'b0}}, 3'd1});
    tb_check64("instruction ARPROT is exec", {{(`XLEN-3){1'b0}}, ifu_axi_arprot},
               {{(`XLEN-3){1'b0}}, 3'b100});
    check_stalled_ar_hold("instruction stalled AR holds");

    reset_dut();
    priv_mode = `PRIV_S;
    satp = SATP_VALUE;
    accept_fetch(USER_VA);
    wait_arvalid();
    tb_check64("PTW first PTE address", ifu_axi_araddr, ROOT_PT);
    tb_check64("PTW ARSIZE is 8B", {{(`XLEN-3){1'b0}}, ifu_axi_arsize},
               {{(`XLEN-3){1'b0}}, 3'd3});
    tb_check64("PTW ARPROT is data", {{(`XLEN-3){1'b0}}, ifu_axi_arprot},
               {{(`XLEN-3){1'b0}}, 3'b000});
    check_stalled_ar_hold("PTW stalled AR holds");

    tb_finish("tb_ooo_fetch_axi_access_attrs");
  end
endmodule
