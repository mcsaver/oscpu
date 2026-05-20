`include "define.v"

module tb_dcache;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg invalidate_i;
  reg cpu_req_valid;
  wire cpu_req_ready;
  reg cpu_req_write;
  reg [`XLEN-1:0] cpu_req_addr;
  reg [`XLEN-1:0] cpu_req_wdata;
  reg [3:0] cpu_req_wstrb;
  wire cpu_rsp_valid;
  wire [`XLEN-1:0] cpu_rsp_rdata;
  wire cpu_rsp_error;
  wire mem_req_valid;
  reg mem_req_ready;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [3:0] mem_req_wstrb;
  reg mem_rsp_valid;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;

  DCache dut (
    .clk(clk),
    .rst(rst),
    .invalidate_i(invalidate_i),
    .cpu_req_valid_i(cpu_req_valid),
    .cpu_req_ready_o(cpu_req_ready),
    .cpu_req_write_i(cpu_req_write),
    .cpu_req_addr_i(cpu_req_addr),
    .cpu_req_wdata_i(cpu_req_wdata),
    .cpu_req_wstrb_i(cpu_req_wstrb),
    .cpu_rsp_valid_o(cpu_rsp_valid),
    .cpu_rsp_rdata_o(cpu_rsp_rdata),
    .cpu_rsp_error_o(cpu_rsp_error),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_req_write_o(mem_req_write),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      invalidate_i = 1'b0;
      cpu_req_valid = 1'b0;
      cpu_req_write = 1'b0;
      cpu_req_addr = 32'h0;
      cpu_req_wdata = 32'h0;
      cpu_req_wstrb = 4'h0;
      mem_req_ready = 1'b1;
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = 32'h0;
      mem_rsp_error = 1'b0;
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
      while (!mem_req_valid && guard < 8) begin
        `TB_TICK(clk);
        guard = guard + 1;
      end
      tb_check1("dcache fill req", mem_req_valid, 1'b1);
      tb_check1("dcache fill read", mem_req_write, 1'b0);
      tb_check32("dcache fill addr", mem_req_addr, exp_addr);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = data;
      mem_rsp_error = 1'b0;
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = 32'h0;
    end
  endtask

  task automatic wait_rsp;
    input [1023:0] name;
    input [`XLEN-1:0] exp_data;
    input exp_error;
    integer guard;
    begin
      guard = 0;
      while (!cpu_rsp_valid && guard < 16) begin
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
      `TB_TICK(clk);
      cpu_req_valid = 1'b0;
      wait_rsp("read response", exp_data, 1'b0);
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
    for (i = 0; i < 16; i = i + 1) begin
      send_fill_word(32'h8000_0000 + (i << 2), 32'h0000_2000 + i);
    end
    wait_rsp("miss fill read", 32'h0000_2002, 1'b0);

    cpu_read(32'h8000_0008, 32'h0000_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b1;
    cpu_req_addr = 32'h8000_0008;
    cpu_req_wdata = 32'haaaa_0000;
    cpu_req_wstrb = 4'b1100;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!mem_req_valid) `TB_TICK(clk);
    tb_check1("store write-through", mem_req_write, 1'b1);
    tb_check32("store addr", mem_req_addr, 32'h8000_0008);
    tb_check32("store wdata", mem_req_wdata, 32'haaaa_0000);
    tb_check32("store wstrb", {28'b0, mem_req_wstrb}, 32'h0000_000c);
    `TB_TICK(clk);
    mem_rsp_valid = 1'b1;
    mem_rsp_error = 1'b0;
    `TB_TICK(clk);
    mem_rsp_valid = 1'b0;
    wait_rsp("store response", 32'h0, 1'b0);
    cpu_read(32'h8000_0008, 32'haaaa_2002);

    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'ha000_0000;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    while (!mem_req_valid) `TB_TICK(clk);
    tb_check32("uncached addr", mem_req_addr, 32'ha000_0000);
    `TB_TICK(clk);
    mem_rsp_valid = 1'b1;
    mem_rsp_rdata = 32'h1234_abcd;
    mem_rsp_error = 1'b0;
    `TB_TICK(clk);
    mem_rsp_valid = 1'b0;
    wait_rsp("uncached read", 32'h1234_abcd, 1'b0);

    invalidate_i = 1'b1;
    `TB_TICK(clk);
    invalidate_i = 1'b0;
    cpu_req_valid = 1'b1;
    cpu_req_write = 1'b0;
    cpu_req_addr = 32'h8000_0008;
    `TB_TICK(clk);
    cpu_req_valid = 1'b0;
    `TB_TICK(clk);
    tb_check1("invalidate causes miss fill", mem_req_valid, 1'b1);

    tb_finish("tb_dcache");
  end
endmodule
