`include "define.v"

module tb_axi_reset_syscon;
  `include "tb_common.svh"

  localparam [63:0] SYSCON_BASE = 64'h0000_0000_0010_0000;

  reg clk;
  reg rst;
  reg arvalid;
  wire arready;
  reg [63:0] araddr;
  reg [2:0] arsize;
  wire rvalid;
  reg rready;
  wire [63:0] rdata;
  wire [1:0] rresp;
  reg awvalid;
  wire awready;
  reg [63:0] awaddr;
  reg [2:0] awsize;
  reg wvalid;
  wire wready;
  reg [63:0] wdata;
  reg [7:0] wstrb;
  wire bvalid;
  reg bready;
  wire [1:0] bresp;
  wire syscon_write_valid;
  wire [31:0] syscon_write_value;

  AxiResetSyscon dut (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(arvalid),
    .s_axi_arready_o(arready),
    .s_axi_araddr_i(araddr),
    .s_axi_arsize_i(arsize),
    .s_axi_rvalid_o(rvalid),
    .s_axi_rready_i(rready),
    .s_axi_rdata_o(rdata),
    .s_axi_rresp_o(rresp),
    .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(awready),
    .s_axi_awaddr_i(awaddr),
    .s_axi_awsize_i(awsize),
    .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(wready),
    .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb),
    .s_axi_bvalid_o(bvalid),
    .s_axi_bready_i(bready),
    .s_axi_bresp_o(bresp),
    .syscon_write_valid_o(syscon_write_valid),
    .syscon_write_value_o(syscon_write_value)
  );

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      arvalid = 1'b0;
      araddr = 64'h0;
      arsize = 3'd2;
      rready = 1'b0;
      awvalid = 1'b0;
      awaddr = 64'h0;
      awsize = 3'd2;
      wvalid = 1'b0;
      wdata = 64'h0;
      wstrb = 8'h0;
      bready = 1'b0;
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic check_event_after_b;
    input [31:0] expected_value;
    begin
      tb_check1("event absent before B handshake", syscon_write_valid, 1'b0);
      bready = 1'b1;
      `TB_TICK(clk);
      bready = 1'b0;
      #1;
      tb_check1("event pulses after B handshake", syscon_write_valid, 1'b1);
      tb_check32("event reports merged value", syscon_write_value,
                 expected_value);
      `TB_TICK(clk);
      #1;
      tb_check1("event is exactly one cycle", syscon_write_valid, 1'b0);
    end
  endtask

  task automatic write_same_cycle;
    input [63:0] addr;
    input [2:0] size;
    input [31:0] data;
    input [3:0] strb;
    input [1:0] expected_resp;
    begin
      awaddr = addr;
      awsize = size;
      wdata = {32'h0000_0000, data} << {addr[2:0], 3'b000};
      wstrb = {4'h0, strb} << addr[2:0];
      awvalid = 1'b1;
      wvalid = 1'b1;
      bready = 1'b0;
      #1;
      tb_check1("same-cycle AW ready", awready, 1'b1);
      tb_check1("same-cycle W ready", wready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wvalid = 1'b0;
      #1;
      tb_check1("same-cycle B valid", bvalid, 1'b1);
      tb_check32("same-cycle B response", {30'h0, bresp},
                 {30'h0, expected_resp});
    end
  endtask

  task automatic write_aw_first;
    input [31:0] data;
    begin
      awaddr = SYSCON_BASE;
      awsize = 3'd2;
      awvalid = 1'b1;
      wvalid = 1'b0;
      bready = 1'b0;
      #1;
      tb_check1("AW-first address ready", awready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      #1;
      tb_check1("AW cache blocks duplicate", awready, 1'b0);
      wdata = {32'h0, data};
      wstrb = 8'h0f;
      wvalid = 1'b1;
      tb_check1("AW-first data ready", wready, 1'b1);
      `TB_TICK(clk);
      wvalid = 1'b0;
      #1;
      tb_check1("AW-first B valid", bvalid, 1'b1);
      tb_check32("AW-first B OKAY", {30'h0, bresp}, 32'h0);
    end
  endtask

  task automatic write_w_first;
    input [31:0] data;
    begin
      wdata = {32'h0, data};
      wstrb = 8'h0f;
      wvalid = 1'b1;
      awvalid = 1'b0;
      bready = 1'b0;
      #1;
      tb_check1("W-first data ready", wready, 1'b1);
      `TB_TICK(clk);
      wvalid = 1'b0;
      #1;
      tb_check1("W cache blocks duplicate", wready, 1'b0);
      awaddr = SYSCON_BASE;
      awsize = 3'd2;
      awvalid = 1'b1;
      tb_check1("W-first address ready", awready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      #1;
      tb_check1("W-first B valid", bvalid, 1'b1);
      tb_check32("W-first B OKAY", {30'h0, bresp}, 32'h0);
    end
  endtask

  task automatic write_with_bready_high;
    input [31:0] data;
    begin
      awaddr = SYSCON_BASE;
      awsize = 3'd2;
      wdata = {32'h0, data};
      wstrb = 8'h0f;
      awvalid = 1'b1;
      wvalid = 1'b1;
      bready = 1'b1;
      #1;
      tb_check1("BREADY-high AW ready", awready, 1'b1);
      tb_check1("BREADY-high W ready", wready, 1'b1);
      `TB_TICK(clk);
      awvalid = 1'b0;
      wvalid = 1'b0;
      #1;
      tb_check1("BREADY-high B becomes valid", bvalid, 1'b1);
      tb_check1("BREADY-high event waits for handshake", syscon_write_valid,
                1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("BREADY-high B consumed", bvalid, 1'b0);
      tb_check1("BREADY-high event pulses once", syscon_write_valid, 1'b1);
      tb_check32("BREADY-high event value", syscon_write_value, data);
      bready = 1'b0;
      `TB_TICK(clk);
      #1;
      tb_check1("BREADY-high event clears", syscon_write_valid, 1'b0);
    end
  endtask

  task automatic read_request;
    input [63:0] addr;
    input [2:0] size;
    input [63:0] expected_data;
    input [1:0] expected_resp;
    begin
      araddr = addr;
      arsize = size;
      arvalid = 1'b1;
      rready = 1'b0;
      #1;
      tb_check1("read address ready", arready, 1'b1);
      `TB_TICK(clk);
      arvalid = 1'b0;
      #1;
      tb_check1("read response valid", rvalid, 1'b1);
      tb_check32("read data low", rdata[31:0], expected_data[31:0]);
      tb_check32("read data high", rdata[63:32], expected_data[63:32]);
      tb_check32("read response", {30'h0, rresp},
                 {30'h0, expected_resp});
      tb_check1("read backpressure blocks AR", arready, 1'b0);
    end
  endtask

  task automatic finish_read;
    begin
      rready = 1'b1;
      `TB_TICK(clk);
      rready = 1'b0;
      #1;
      tb_check1("read response consumed", rvalid, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check1("event reset low", syscon_write_valid, 1'b0);
    read_request(SYSCON_BASE, 3'd2, 64'h0, 2'b00);
    // 改变请求输入并多停一拍，证明 R payload 不受背压期间输入扰动影响。
    araddr = SYSCON_BASE + 64'h4;
    arsize = 3'd3;
    `TB_TICK(clk);
    #1;
    tb_check1("stalled R remains valid", rvalid, 1'b1);
    tb_check32("stalled R data stable", rdata[31:0], 32'h0);
    tb_check32("stalled R response stable", {30'h0, rresp}, 32'h0);
    finish_read();

    // 同拍 AW/W：B 背压期间既不发事件，也不接受下一笔写。
    write_same_cycle(SYSCON_BASE, 3'd2, 32'h0000_5555, 4'hf, 2'b00);
    awaddr = SYSCON_BASE + 64'h4;
    awsize = 3'd3;
    `TB_TICK(clk);
    #1;
    tb_check1("stalled B remains valid", bvalid, 1'b1);
    tb_check32("stalled B response stable", {30'h0, bresp}, 32'h0);
    tb_check1("B pending blocks AW", awready, 1'b0);
    tb_check1("B pending blocks W", wready, 1'b0);
    check_event_after_b(32'h0000_5555);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_0000_5555, 2'b00);
    finish_read();

    write_aw_first(32'h0000_7777);
    check_event_after_b(32'h0000_7777);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_0000_7777, 2'b00);
    finish_read();

    write_w_first(32'h0000_3333);
    check_event_after_b(32'h0000_3333);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_0000_3333, 2'b00);
    finish_read();

    // byte0/byte2 更新，byte1/byte3 保留：0x00003333 -> 0x00bb33dd。
    write_same_cycle(SYSCON_BASE, 3'd2, 32'haa_bb_cc_dd, 4'b0101, 2'b00);
    check_event_after_b(32'h00bb_33dd);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_00bb_33dd, 2'b00);
    finish_read();

    // 全零 WSTRB 是无数据字节写：响应 OKAY，但不得伪造 reset 事件。
    write_same_cycle(SYSCON_BASE, 3'd2, 32'h0000_5555, 4'h0, 2'b00);
    bready = 1'b1;
    `TB_TICK(clk);
    bready = 1'b0;
    #1;
    tb_check1("zero-strobe write has no event", syscon_write_valid, 1'b0);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_00bb_33dd, 2'b00);
    finish_read();

    // master 从事务开始就拉高 BREADY，响应与事件仍不能丢失或重复。
    write_with_bready_high(32'h0000_7777);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_0000_7777, 2'b00);
    finish_read();

    // size/offset 错误都必须 SLVERR，且即使 B 握手也不得产生 syscon 事件。
    write_same_cycle(SYSCON_BASE, 3'd3, 32'hdead_beef, 4'hf, 2'b10);
    bready = 1'b1;
    `TB_TICK(clk);
    bready = 1'b0;
    #1;
    tb_check1("invalid-size write has no event", syscon_write_valid, 1'b0);

    write_same_cycle(SYSCON_BASE + 64'h4, 3'd2,
                     32'hcafe_babe, 4'hf, 2'b10);
    bready = 1'b1;
    `TB_TICK(clk);
    bready = 1'b0;
    #1;
    tb_check1("invalid-offset write has no event", syscon_write_valid, 1'b0);
    read_request(SYSCON_BASE, 3'd2, 64'h0000_0000_0000_7777, 2'b00);
    finish_read();

    read_request(SYSCON_BASE, 3'd3, 64'h0, 2'b10);
    finish_read();
    read_request(SYSCON_BASE + 64'h4, 3'd2, 64'h0, 2'b10);
    finish_read();

    $display("[T4O-RESET-SYSCON] order=same/AW-first/W-first backpressure=R+B event=post-B zero-strobe=no-event BREADY-high=once values=5555/7777/3333 errors=size+offset");
    tb_finish("tb_axi_reset_syscon");
  end
endmodule
