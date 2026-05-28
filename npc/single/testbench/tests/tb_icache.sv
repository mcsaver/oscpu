`include "define.v"

module tb_icache;
  `include "tb_common.svh"
  localparam LINE_WORDS = `ICACHE_LINE_WORDS;

  reg clk;
  reg rst;
  reg abort_i;
  reg invalidate_i;
  reg cpu_req_valid;
  wire cpu_req_ready;
  reg [`XLEN-1:0] cpu_req_addr;
  wire cpu_rsp_valid;
  reg cpu_rsp_ready;
  wire [`XLEN-1:0] cpu_rsp_data;
  wire cpu_rsp_error;
  wire axi_arvalid;
  reg axi_arready;
  wire [`XLEN-1:0] axi_araddr;
  reg axi_rvalid;
  wire axi_rready;
  reg [`XLEN-1:0] axi_rdata;
  reg [1:0] axi_rresp;

  ICache dut (
    .clk(clk),
    .rst(rst),
    .abort_i(abort_i),
    .invalidate_i(invalidate_i),
    .cpu_req_valid_i(cpu_req_valid),
    .cpu_req_ready_o(cpu_req_ready),
    .cpu_req_addr_i(cpu_req_addr),
    .cpu_rsp_valid_o(cpu_rsp_valid),
    .cpu_rsp_ready_i(cpu_rsp_ready),
    .cpu_rsp_data_o(cpu_rsp_data),
    .cpu_rsp_error_o(cpu_rsp_error),
    .axi_arvalid_o(axi_arvalid),
    .axi_arready_i(axi_arready),
    .axi_araddr_o(axi_araddr),
    .axi_rvalid_i(axi_rvalid),
    .axi_rready_o(axi_rready),
    .axi_rdata_i(axi_rdata),
    .axi_rresp_i(axi_rresp)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      abort_i = 1'b0;
      invalidate_i = 1'b0;
      cpu_req_valid = 1'b0;
      cpu_rsp_ready = 1'b1;
      cpu_req_addr = 32'h0;
      axi_arready = 1'b1;
      axi_rvalid = 1'b0;
      axi_rdata = 32'h0;
      axi_rresp = 2'b00;
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic send_mem_word;
    input [`XLEN-1:0] exp_addr;
    input [`XLEN-1:0] data;
    integer guard;
    begin
      guard = 0;
      while (!axi_arvalid && guard < 8) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1("icache axi arvalid", axi_arvalid, 1'b1);
      tb_check32("icache axi araddr", axi_araddr, exp_addr);
      `TB_TICK(clk);
      tb_check1("icache axi rready", axi_rready, 1'b1);
      axi_rvalid = 1'b1;
      axi_rdata = data;
      axi_rresp = 2'b00;
      `TB_TICK(clk);
      axi_rvalid = 1'b0;
      axi_rdata = 32'h0;
    end
  endtask

  task automatic wait_cpu_rsp;
    input [1023:0] name;
    input [`XLEN-1:0] exp_data;
    input exp_error;
    input check_data;
    integer guard;
    begin
      guard = 0;
      while (!cpu_rsp_valid && guard < 16) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1({name, " valid"}, cpu_rsp_valid, 1'b1);
      if (check_data)
        tb_check32(name, cpu_rsp_data, exp_data);
      tb_check1({name, " error"}, cpu_rsp_error, exp_error);
      `TB_TICK(clk);
    end
  endtask

  integer i;

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();
    #1;
    tb_check1("reset ready", cpu_req_ready, 1'b1);

    cpu_req_addr = 32'h8000_0001;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_cpu_rsp("misaligned sync rsp", 32'h0, 1'b1, 1'b0);

    cpu_req_addr = 32'h8000_0004;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      send_mem_word(32'h8000_0000 + (i << 2), 32'h0000_1000 + i);
    end
    tb_check32("filled sram word1", dut.u_data_sram.mem_q[0][32 +: 32], 32'h0000_1001);
    wait_cpu_rsp("filled line response", 32'h0000_1001, 1'b0, 1'b0);

    cpu_req_addr = 32'h8000_0004;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_cpu_rsp("hit sync rsp", 32'h0000_1001, 1'b0, 1'b1);
    tb_check32("hit sram word1", dut.u_data_sram.mem_q[0][32 +: 32], 32'h0000_1001);

    cpu_req_valid = 1'b1;
    cpu_req_addr = 32'h8000_0004;
    `TB_TICK(clk);
    cpu_req_addr = 32'h8000_0008;
    #1;
    tb_check1("icache first pipelined hit rsp", cpu_rsp_valid, 1'b1);
    tb_check1("icache accepts next hit", cpu_req_ready, 1'b1);
    tb_check32("icache first pipelined data", cpu_rsp_data, 32'h0000_1001);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    #1;
    tb_check1("icache second pipelined hit rsp", cpu_rsp_valid, 1'b1);
    tb_check32("icache second pipelined data", cpu_rsp_data, 32'h0000_1002);
    `TB_TICK(clk);

    cpu_req_addr = 32'h8000_0004;
    cpu_req_valid = 1'b1;
    cpu_rsp_ready = 1'b0;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!cpu_rsp_valid) `TB_TICK(clk);
    #1;
    tb_check1("hit backpressure valid", cpu_rsp_valid, 1'b1);
    tb_check32("hit backpressure data", cpu_rsp_data, 32'h0000_1001);
    `TB_TICK(clk);
    #1;
    tb_check1("hit backpressure holds valid", cpu_rsp_valid, 1'b1);
    tb_check32("hit backpressure holds data", cpu_rsp_data, 32'h0000_1001);
    cpu_rsp_ready = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("hit backpressure releases", cpu_rsp_valid, 1'b0);

    cpu_req_addr = 32'h8000_1004;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    for (i = 0; i < LINE_WORDS; i = i + 1) begin
      send_mem_word(32'h8000_1000 + (i << 2), 32'h0000_3000 + i);
    end
    wait_cpu_rsp("second way filled response", 32'h0000_3001, 1'b0, 1'b0);

    cpu_req_addr = 32'h8000_0004;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    wait_cpu_rsp("first way still hits", 32'h0000_1001, 1'b0, 1'b1);

    cpu_req_addr = 32'h9000_0000;
    cpu_req_valid = 1'b1;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!axi_arvalid) `TB_TICK(clk);
    tb_check32("uncached req addr", axi_araddr, 32'h9000_0000);
    `TB_TICK(clk);
    axi_rvalid = 1'b1;
    axi_rdata = 32'hfeed_cafe;
    axi_rresp = 2'b00;
    `TB_TICK(clk);
    axi_rvalid = 1'b0;
    wait_cpu_rsp("uncached response", 32'hfeed_cafe, 1'b0, 1'b1);

    invalidate_i = 1'b1;
    `TB_TICK(clk);
    invalidate_i = 1'b0;
    cpu_req_addr = 32'h8000_0004;
    cpu_req_valid = 1'b1;
    #1;
    tb_check1("invalidate removes immediate hit", cpu_rsp_valid, 1'b0);
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;

    tb_finish("tb_icache");
  end
endmodule
