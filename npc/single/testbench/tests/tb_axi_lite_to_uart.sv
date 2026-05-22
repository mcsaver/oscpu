module tb_axi_lite_to_uart;
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

  wire tx_valid;
  wire [7:0] tx_data;
  wire access_valid;
  wire access_write;

  AxiLiteToUart dut (
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
    .uart_tx_valid_o(tx_valid),
    .uart_tx_data_o(tx_data),
    .uart_access_valid_o(access_valid),
    .uart_access_write_o(access_write)
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
      tb_check1("read access pulse", access_valid, 1'b1);
      tb_check1("read access is read", access_write, 1'b0);
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
    input exp_tx;
    input [7:0] exp_ch;
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
      tb_check1("write access pulse", access_valid, 1'b1);
      tb_check1("write access is write", access_write, 1'b1);
      tb_check1("write tx_valid", tx_valid, exp_tx);
      if (exp_tx) tb_check32("write tx_data", {24'b0, tx_data}, {24'b0, exp_ch});
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

  initial begin
    tb_errors = 0;
    reset_dut();

    axi_read_word(32'h1000_0004, 32'h0000_6001);
    axi_write_word(32'h1000_0000, 32'h0000_0041, 4'b0001, 1'b1, 8'h41);
    axi_write_word(32'h1000_0000, 32'h0000_4200, 4'b0010, 1'b0, 8'h00);
    axi_write_word(32'h1000_0004, 32'h0000_0043, 4'b0001, 1'b0, 8'h00);

    tb_finish("tb_axi_lite_to_uart");
  end
endmodule
