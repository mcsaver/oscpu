`include "define.v"

module tb_axi_lite_clint;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg arvalid;
  wire arready;
  reg [31:0] araddr;
  wire rvalid;
  reg rready;
  wire [31:0] rdata;
  wire [1:0] rresp;

  reg awvalid;
  wire awready;
  reg [31:0] awaddr;
  reg wvalid;
  wire wready;
  reg [31:0] wdata;
  reg [3:0] wstrb;
  wire bvalid;
  reg bready;
  wire [1:0] bresp;

  wire [63:0] mtime;
  wire msip_irq;
  wire mtip_irq;

  wire inc_arready;
  wire inc_rvalid;
  wire [31:0] inc_rdata;
  wire [1:0] inc_rresp;
  wire inc_awready;
  wire inc_wready;
  wire inc_bvalid;
  wire [1:0] inc_bresp;
  wire [63:0] inc_mtime;
  wire inc_msip_irq;
  wire inc_mtip_irq;

  reg axi64_arvalid;
  wire axi64_arready;
  reg [63:0] axi64_araddr;
  wire axi64_rvalid;
  reg axi64_rready;
  wire [63:0] axi64_rdata;
  wire [1:0] axi64_rresp;

  reg axi64_awvalid;
  wire axi64_awready;
  reg [63:0] axi64_awaddr;
  reg axi64_wvalid;
  wire axi64_wready;
  reg [63:0] axi64_wdata;
  reg [7:0] axi64_wstrb;
  wire axi64_bvalid;
  reg axi64_bready;
  wire [1:0] axi64_bresp;

  wire [63:0] axi64_mtime;
  wire axi64_msip_irq;
  wire axi64_mtip_irq;

  AxiLiteClint #(
    .MTIME_INCREMENT(64'd0)
  ) dut (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(arvalid),
    .s_axi_arready_o(arready),
    .s_axi_araddr_i(araddr),
    .s_axi_rvalid_o(rvalid),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata),
    .s_axi_rresp_o(rresp),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(awready),
    .s_axi_awaddr_i(awaddr),
    .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(wready),
    .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb),
    .s_axi_bvalid_o(bvalid),
    .s_axi_bready_i(bready),
    .s_axi_bresp_o(bresp),
    .mtime_o(mtime),
    .msip_irq_o(msip_irq),
    .mtip_irq_o(mtip_irq)
  );

  AxiLiteClint #(
    .MTIME_INCREMENT(64'd1)
  ) inc_dut (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(1'b0),
    .s_axi_arready_o(inc_arready),
    .s_axi_araddr_i(32'h0),
    .s_axi_rvalid_o(inc_rvalid),
    .s_axi_rready_i(1'b0),
    .s_axi_rdata_o(inc_rdata),
    .s_axi_rresp_o(inc_rresp),
    .s_axi_awvalid_i(1'b0),
    .s_axi_awready_o(inc_awready),
    .s_axi_awaddr_i(32'h0),
    .s_axi_wvalid_i(1'b0),
    .s_axi_wready_o(inc_wready),
    .s_axi_wdata_i(32'h0),
    .s_axi_wstrb_i(4'h0),
    .s_axi_bvalid_o(inc_bvalid),
    .s_axi_bready_i(1'b0),
    .s_axi_bresp_o(inc_bresp),
    .mtime_o(inc_mtime),
    .msip_irq_o(inc_msip_irq),
    .mtip_irq_o(inc_mtip_irq)
  );
  wire unused_inc_outputs_w = |{
      inc_arready, inc_rvalid, inc_rdata, inc_rresp,
      inc_awready, inc_wready, inc_bvalid, inc_bresp,
      inc_msip_irq, inc_mtip_irq
  };

  AxiLiteClint #(
    .ADDR_W(64),
    .DATA_W(64),
    .STRB_W(8),
    .MTIME_INCREMENT(64'd0)
  ) dut64 (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(axi64_arvalid),
    .s_axi_arready_o(axi64_arready),
    .s_axi_araddr_i(axi64_araddr),
    .s_axi_rvalid_o(axi64_rvalid),
    .s_axi_rready_i(axi64_rready),
    .s_axi_rdata_o(axi64_rdata),
    .s_axi_rresp_o(axi64_rresp),
    .s_axi_awvalid_i(axi64_awvalid),
    .s_axi_awready_o(axi64_awready),
    .s_axi_awaddr_i(axi64_awaddr),
    .s_axi_wvalid_i(axi64_wvalid),
    .s_axi_wready_o(axi64_wready),
    .s_axi_wdata_i(axi64_wdata),
    .s_axi_wstrb_i(axi64_wstrb),
    .s_axi_bvalid_o(axi64_bvalid),
    .s_axi_bready_i(axi64_bready),
    .s_axi_bresp_o(axi64_bresp),
    .mtime_o(axi64_mtime),
    .msip_irq_o(axi64_msip_irq),
    .mtip_irq_o(axi64_mtip_irq)
  );

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      arvalid = 1'b0;
      araddr = 32'h0;
      rready = 1'b0;
      awvalid = 1'b0;
      awaddr = 32'h0;
      wvalid = 1'b0;
      wdata = 32'h0;
      wstrb = 4'h0;
      bready = 1'b0;
      axi64_arvalid = 1'b0;
      axi64_araddr = 64'h0;
      axi64_rready = 1'b0;
      axi64_awvalid = 1'b0;
      axi64_awaddr = 64'h0;
      axi64_wvalid = 1'b0;
      axi64_wdata = 64'h0;
      axi64_wstrb = 8'h0;
      axi64_bready = 1'b0;
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic axi_read_word;
    input [31:0] addr;
    input [31:0] exp_data;
    begin
      araddr = addr;
      arvalid = 1'b1;
      rready = 1'b0;
      #1;
      tb_check1("read arready", arready, 1'b1);
      `TB_TICK(clk);
      arvalid = 1'b0;
      #1;
      tb_check1("read rvalid", rvalid, 1'b1);
      tb_check32("read data", rdata, exp_data);
      tb_check32("read resp", {30'b0, rresp}, 32'h0);
      rready = 1'b1;
      `TB_TICK(clk);
      rready = 1'b0;
    end
  endtask

  task automatic axi_write_word;
    input [31:0] addr;
    input [31:0] data;
    input [3:0] strb;
    begin
      awaddr = addr;
      wdata = data;
      wstrb = strb;
      awvalid = 1'b1;
      wvalid = 1'b1;
      bready = 1'b0;
      #1;
      tb_check1("write awready", awready, 1'b1);
      tb_check1("write wready", wready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wvalid = 1'b0;
      #1;
      tb_check1("write bvalid", bvalid, 1'b1);
      tb_check32("write bresp", {30'b0, bresp}, 32'h0);
      bready = 1'b1;
      `TB_TICK(clk);
      bready = 1'b0;
    end
  endtask

  task automatic axi64_read_word;
    input [63:0] addr;
    input [63:0] exp_data;
    begin
      axi64_araddr = addr;
      axi64_arvalid = 1'b1;
      axi64_rready = 1'b0;
      #1;
      tb_check1("read64 arready", axi64_arready, 1'b1);
      `TB_TICK(clk);
      axi64_arvalid = 1'b0;
      #1;
      tb_check1("read64 rvalid", axi64_rvalid, 1'b1);
      tb_check32("read64 data low", axi64_rdata[31:0], exp_data[31:0]);
      tb_check32("read64 data high", axi64_rdata[63:32], exp_data[63:32]);
      tb_check32("read64 resp", {30'b0, axi64_rresp}, 32'h0);
      axi64_rready = 1'b1;
      `TB_TICK(clk);
      axi64_rready = 1'b0;
    end
  endtask

  task automatic axi64_write_word;
    input [63:0] addr;
    input [63:0] data;
    input [7:0] strb;
    begin
      axi64_awaddr = addr;
      axi64_wdata = data;
      axi64_wstrb = strb;
      axi64_awvalid = 1'b1;
      axi64_wvalid = 1'b1;
      axi64_bready = 1'b0;
      #1;
      tb_check1("write64 awready", axi64_awready, 1'b1);
      tb_check1("write64 wready", axi64_wready, 1'b1);
      `TB_TICK(clk);
      axi64_awvalid = 1'b0;
      axi64_wvalid = 1'b0;
      #1;
      tb_check1("write64 bvalid", axi64_bvalid, 1'b1);
      tb_check32("write64 bresp", {30'b0, axi64_bresp}, 32'h0);
      axi64_bready = 1'b1;
      `TB_TICK(clk);
      axi64_bready = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check1("msip irq reset low", msip_irq, 1'b0);
    tb_check1("mtip irq reset low", mtip_irq, 1'b0);
    tb_check32("incrementing mtime after reset", inc_mtime[31:0], 32'd1);
    `TB_TICK(clk);
    `TB_TICK(clk);
    tb_check32("mtime increments", inc_mtime[31:0], 32'd3);

    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'h0000_0000);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_bffc, 32'h0000_0000);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_0000, 32'h0000_0000);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_4000, 32'hffff_ffff);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_4004, 32'hffff_ffff);

    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_0000, 32'h0000_0001, 4'b1111);
    tb_check1("msip irq set", msip_irq, 1'b1);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_0000, 32'h0000_0001);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_0000, 32'h0000_0000, 4'b1111);
    tb_check1("msip irq clear", msip_irq, 1'b0);

    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'h1234_5678, 4'b1111);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_bffc, 32'h0000_0009, 4'b1111);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'h1234_5678);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_bffc, 32'h0000_0009);
    tb_check32("mtime output low", mtime[31:0], 32'h1234_5678);
    tb_check32("mtime output high", mtime[63:32], 32'h0000_0009);

    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'haaaa_55ff, 4'b0011);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'h1234_55ff);

    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_bff8, 32'h0000_0005, 4'b1111);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_bffc, 32'h0000_0000, 4'b1111);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_4004, 32'h0000_0000, 4'b1111);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_4000, 32'h0000_0003, 4'b1111);
    tb_check1("mtip irq set by compare", mtip_irq, 1'b1);
    axi_read_word(`NPC_AXI_CLINT_BASE + 32'h0000_4000, 32'h0000_0003);
    axi_write_word(`NPC_AXI_CLINT_BASE + 32'h0000_4000, 32'h0000_000a, 4'b1111);
    tb_check1("mtip irq clear by compare", mtip_irq, 1'b0);

    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'hffff_ffff_ffff_ffff);
    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'h1357_9bdf_2468_ace0, 8'hff);
    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'h1357_9bdf_2468_ace0);
    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'hffff_ffff_0000_0000, 8'hf0);
    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'hffff_ffff_2468_ace0);
    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_4004, 64'h0000_0000_ffff_ffff);

    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_bff8, 64'h0000_0001_0000_0002, 8'hff);
    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_bff8, 64'h0000_0001_0000_0002);
    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_bff8, 64'h0000_0007_0000_0000, 8'hf0);
    axi64_read_word(`NPC_AXI_CLINT_BASE + 64'h0000_bff8, 64'h0000_0007_0000_0002);
    tb_check32("mtime64 output low", axi64_mtime[31:0], 32'h0000_0002);
    tb_check32("mtime64 output high", axi64_mtime[63:32], 32'h0000_0007);

    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_bff8, 64'h0000_0000_0000_0005, 8'hff);
    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'h0000_0000_0000_0003, 8'hff);
    tb_check1("mtip64 irq set by aligned compare", axi64_mtip_irq, 1'b1);
    axi64_write_word(`NPC_AXI_CLINT_BASE + 64'h0000_4000, 64'h0000_0000_0000_000a, 8'hff);
    tb_check1("mtip64 irq clear by aligned compare", axi64_mtip_irq, 1'b0);

    tb_finish("tb_axi_lite_clint");
  end
endmodule
