`include "define.v"

module tb_dcache;
  `include "tb_common.svh"
  localparam LINE_WORDS = `DCACHE_LINE_WORDS;
  localparam FLUSH_TIMEOUT = (`DCACHE_LINE_COUNT * 4) + (`DCACHE_LINE_WORDS * 8);

  reg clk;
  reg rst;
  reg invalidate_i;
  reg flush_i;
  wire flush_done;
  reg cpu_req_valid;
  wire cpu_req_ready;
  reg cpu_req_write;
  reg [`XLEN-1:0] cpu_req_addr;
  reg [`XLEN-1:0] cpu_req_wdata;
  reg [3:0] cpu_req_wstrb;
  wire cpu_rsp_valid;
  reg cpu_rsp_ready;
  wire [`XLEN-1:0] cpu_rsp_rdata;
  wire cpu_rsp_error;

  wire axi_arvalid;
  reg axi_arready;
  wire [`XLEN-1:0] axi_araddr;
  reg axi_rvalid;
  wire axi_rready;
  reg [`XLEN-1:0] axi_rdata;
  reg [1:0] axi_rresp;
  wire axi_awvalid;
  reg axi_awready;
  wire [`XLEN-1:0] axi_awaddr;
  wire axi_wvalid;
  reg axi_wready;
  wire [`XLEN-1:0] axi_wdata;
  wire [3:0] axi_wstrb;
  reg axi_bvalid;
  wire axi_bready;
  reg [1:0] axi_bresp;

  DCache dut (
    .clk(clk),
    .rst(rst),
    .invalidate_i(invalidate_i),
    .flush_i(flush_i),
    .flush_done_o(flush_done),
    .cpu_req_valid_i(cpu_req_valid),
    .cpu_req_ready_o(cpu_req_ready),
    .cpu_req_write_i(cpu_req_write),
    .cpu_req_addr_i(cpu_req_addr),
    .cpu_req_wdata_i(cpu_req_wdata),
    .cpu_req_wstrb_i(cpu_req_wstrb),
    .cpu_rsp_valid_o(cpu_rsp_valid),
    .cpu_rsp_ready_i(cpu_rsp_ready),
    .cpu_rsp_rdata_o(cpu_rsp_rdata),
    .cpu_rsp_error_o(cpu_rsp_error),
    .axi_arvalid_o(axi_arvalid),
    .axi_arready_i(axi_arready),
    .axi_araddr_o(axi_araddr),
    .axi_rvalid_i(axi_rvalid),
    .axi_rready_o(axi_rready),
    .axi_rdata_i(axi_rdata),
    .axi_rresp_i(axi_rresp),
    .axi_awvalid_o(axi_awvalid),
    .axi_awready_i(axi_awready),
    .axi_awaddr_o(axi_awaddr),
    .axi_wvalid_o(axi_wvalid),
    .axi_wready_i(axi_wready),
    .axi_wdata_o(axi_wdata),
    .axi_wstrb_o(axi_wstrb),
    .axi_bvalid_i(axi_bvalid),
    .axi_bready_o(axi_bready),
    .axi_bresp_i(axi_bresp)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      invalidate_i = 1'b0;
      flush_i = 1'b0;
      cpu_req_valid = 1'b0;
      cpu_req_write = 1'b0;
      cpu_req_addr = 32'h0;
      cpu_req_wdata = 32'h0;
      cpu_req_wstrb = 4'h0;
      cpu_rsp_ready = 1'b1;
      axi_arready = 1'b1;
      axi_rvalid = 1'b0;
      axi_rdata = 32'h0;
      axi_rresp = 2'b00;
      axi_awready = 1'b1;
      axi_wready = 1'b1;
      axi_bvalid = 1'b0;
      axi_bresp = 2'b00;
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic send_fill_word;
    input [`XLEN-1:0] exp_addr;
    input [`XLEN-1:0] data;
    integer guard;
    begin
      guard = 0;
      while (!axi_arvalid && guard < 16) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1("dcache fill arvalid", axi_arvalid, 1'b1);
      tb_check32("dcache fill araddr", axi_araddr, exp_addr);
      `TB_TICK(clk);
      tb_check1("dcache fill rready", axi_rready, 1'b1);
      axi_rvalid = 1'b1;
      axi_rdata = data;
      axi_rresp = 2'b00;
      `TB_TICK(clk);
      axi_rvalid = 1'b0;
      axi_rdata = 32'h0;
    end
  endtask

  task automatic accept_write_word;
    input [`XLEN-1:0] exp_addr;
    input [`XLEN-1:0] exp_data;
    input [3:0] exp_wstrb;
    integer guard;
    begin
      guard = 0;
      while (!(axi_awvalid && axi_wvalid) && guard < 16) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1("dcache write awvalid", axi_awvalid, 1'b1);
      tb_check1("dcache write wvalid", axi_wvalid, 1'b1);
      tb_check32("dcache write addr", axi_awaddr, exp_addr);
      tb_check32("dcache write data", axi_wdata, exp_data);
      tb_check32("dcache write wstrb", {28'b0, axi_wstrb}, {28'b0, exp_wstrb});
      `TB_TICK(clk);
      tb_check1("dcache write bready", axi_bready, 1'b1);
      axi_bvalid = 1'b1;
      axi_bresp = 2'b00;
      `TB_TICK(clk);
      axi_bvalid = 1'b0;
    end
  endtask

  task automatic wait_rsp;
    input [1023:0] name;
    input [`XLEN-1:0] exp_data;
    input exp_error;
    integer guard;
    begin
      guard = 0;
      while (!cpu_rsp_valid && guard < 32) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " valid"}, cpu_rsp_valid, 1'b1);
      tb_check32(name, cpu_rsp_rdata, exp_data);
      tb_check1({name, " error"}, cpu_rsp_error, exp_error);
      `TB_TICK(clk);
    end
  endtask

  task automatic cpu_read;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] exp_data;
    begin
      cpu_req_valid = 1'b1;
      cpu_req_write = 1'b0;
      cpu_req_addr = addr;
      cpu_req_wdata = 32'h0;
      cpu_req_wstrb = 4'h0;
      #1;
      if (cpu_rsp_valid) begin
        tb_check32("read same-cycle response", cpu_rsp_rdata, exp_data);
        tb_check1("read same-cycle error", cpu_rsp_error, 1'b0);
        `TB_TICK(clk);
	      end else begin
	        `TB_TICK(clk);
	        cpu_req_valid = 1'b0;
	        wait_rsp("read response", exp_data, 1'b0);
	      end
	      cpu_req_valid = 1'b0;
	      #1;
	    end
	  endtask

  integer i;

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();
    #1;
    tb_check1("reset ready", cpu_req_ready, 1'b1);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_0008;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      send_fill_word(32'h8000_0000 + (i << 2), 32'h0000_2000 + i);
    end
    wait_rsp("miss fill read", 32'h0000_2002, 1'b0);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_0008;
    cpu_req_wdata = 32'h0;
    cpu_req_wstrb = 4'h0;
    #1;
    tb_check1("load hit no immediate valid", cpu_rsp_valid, 1'b0);
    tb_check1("load hit no axi read", axi_arvalid, 1'b0);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_rsp("load hit sync response", 32'h0000_2002, 1'b0);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_0008;
    cpu_req_wdata = 32'h0;
    cpu_req_wstrb = 4'h0;
    `TB_TICK(clk);
    cpu_req_addr = 32'h8000_000c;
    #1;
    tb_check1("dcache first pipelined load rsp", cpu_rsp_valid, 1'b1);
    tb_check1("dcache accepts next load hit", cpu_req_ready, 1'b1);
    tb_check32("dcache first pipelined data", cpu_rsp_rdata, 32'h0000_2002);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    #1;
    tb_check1("dcache second pipelined load rsp", cpu_rsp_valid, 1'b1);
    tb_check32("dcache second pipelined data", cpu_rsp_rdata, 32'h0000_2003);
    `TB_TICK(clk);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_0008;
    cpu_req_wdata = 32'h0;
    cpu_req_wstrb = 4'h0;
    cpu_rsp_ready = 1'b0;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!cpu_rsp_valid) `TB_TICK(clk);
    #1;
    tb_check1("load hit backpressure valid", cpu_rsp_valid, 1'b1);
    tb_check32("load hit backpressure data", cpu_rsp_rdata, 32'h0000_2002);
    `TB_TICK(clk);
    #1;
    tb_check1("load hit backpressure holds valid", cpu_rsp_valid, 1'b1);
    tb_check32("load hit backpressure holds data", cpu_rsp_rdata, 32'h0000_2002);
    cpu_rsp_ready = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("load hit backpressure releases", cpu_rsp_valid, 1'b0);

    cpu_read(32'h8000_0008, 32'h0000_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b1;
    cpu_req_addr = 32'h8000_0008;
    cpu_req_wdata = 32'haaaa_0000;
    cpu_req_wstrb = 4'b1100;
    #1;
    tb_check1("store hit no immediate valid", cpu_rsp_valid, 1'b0);
    tb_check1("store hit no axi write", axi_awvalid, 1'b0);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_rsp("store hit sync response", 32'h0, 1'b0);
    cpu_read(32'h8000_0008, 32'haaaa_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_1008;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      send_fill_word(32'h8000_1000 + (i << 2), 32'h0000_3000 + i);
    end
    wait_rsp("second way refill read", 32'h0000_3002, 1'b0);
    cpu_read(32'h8000_0008, 32'haaaa_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b1;
    cpu_req_addr = 32'h8000_1008;
    cpu_req_wdata = 32'hfeed_0002;
    cpu_req_wstrb = 4'b1111;
    #1;
    tb_check1("second way store hit no immediate valid", cpu_rsp_valid, 1'b0);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_rsp("second way store hit", 32'h0, 1'b0);

    cpu_read(32'h8000_0008, 32'haaaa_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_2008;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      accept_write_word(32'h8000_1000 + (i << 2),
                        (i == 2) ? 32'hfeed_0002 : (32'h0000_3000 + i),
                        4'b1111);
    end
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      send_fill_word(32'h8000_2000 + (i << 2), 32'h0000_4000 + i);
    end
    wait_rsp("third line evicts lru dirty way", 32'h0000_4002, 1'b0);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b1;
    cpu_req_addr = 32'h8000_2008;
    cpu_req_wdata = 32'hcafe_0002;
    cpu_req_wstrb = 4'b1111;
    #1;
    tb_check1("flush setup store no immediate valid", cpu_rsp_valid, 1'b0);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_rsp("flush setup third way store hit", 32'h0, 1'b0);

    flush_i = 1'b1;
    tb_check1("flush starts not done", flush_done, 1'b0);
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      accept_write_word(32'h8000_0000 + (i << 2),
                        (i == 2) ? 32'haaaa_2002 : (32'h0000_2000 + i),
                        4'b1111);
    end
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      accept_write_word(32'h8000_2000 + (i << 2),
                        (i == 2) ? 32'hcafe_0002 : (32'h0000_4000 + i),
                        4'b1111);
    end
    for (i = 0; !flush_done && (i < FLUSH_TIMEOUT); i = i + 1) begin
      `TB_TICK(clk);
    end
    #1;
    tb_check1("flush writes dirty line", flush_done, 1'b1);
    flush_i = 1'b0;
    `TB_TICK(clk);
    #1;
    tb_check1("flush returns ready", cpu_req_ready, 1'b1);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'ha000_0000;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!axi_arvalid) `TB_TICK(clk);
    tb_check32("uncached addr", axi_araddr, 32'ha000_0000);
    `TB_TICK(clk);
    axi_rvalid = 1'b1;
    axi_rdata = 32'h1234_abcd;
    axi_rresp = 2'b00;
    `TB_TICK(clk);
    axi_rvalid = 1'b0;
    wait_rsp("uncached read", 32'h1234_abcd, 1'b0);

    invalidate_i = 1'b1;
    `TB_TICK(clk);
    invalidate_i = 1'b0;
    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_1008;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    `TB_TICK(clk);
    tb_check1("invalidate causes miss fill", axi_arvalid, 1'b1);

    tb_finish("tb_dcache");
  end
endmodule
