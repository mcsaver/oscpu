`timescale 1ns/1ps
`include "define.v"

module tb_ooo_fp_reg_file;
  reg clk;
  reg rst;
  reg flush;
  reg [`REG_ADDR_W-1:0] read0_addr;
  reg [`REG_ADDR_W-1:0] read1_addr;
  reg [`REG_ADDR_W-1:0] read2_addr;
  wire [`XLEN-1:0] read0_data;
  wire [`XLEN-1:0] read1_data;
  wire [`XLEN-1:0] read2_data;
  reg load_write_valid;
  reg [`REG_ADDR_W-1:0] load_write_addr;
  reg [`XLEN-1:0] load_write_data;
  reg result_write_valid;
  reg [`REG_ADDR_W-1:0] result_write_addr;
  reg [`XLEN-1:0] result_write_data;

  integer errors;

  OooFpRegFile dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .read0_addr_i(read0_addr),
    .read0_data_o(read0_data),
    .read1_addr_i(read1_addr),
    .read1_data_o(read1_data),
    .read2_addr_i(read2_addr),
    .read2_data_o(read2_data),
    .load_write_valid_i(load_write_valid),
    .load_write_addr_i(load_write_addr),
    .load_write_data_i(load_write_data),
    .result_write_valid_i(result_write_valid),
    .result_write_addr_i(result_write_addr),
    .result_write_data_i(result_write_data)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      read0_addr = {`REG_ADDR_W{1'b0}};
      read1_addr = {`REG_ADDR_W{1'b0}};
      read2_addr = {`REG_ADDR_W{1'b0}};
      load_write_valid = 1'b0;
      load_write_addr = {`REG_ADDR_W{1'b0}};
      load_write_data = {`XLEN{1'b0}};
      result_write_valid = 1'b0;
      result_write_addr = {`REG_ADDR_W{1'b0}};
      result_write_data = {`XLEN{1'b0}};
    end
  endtask

  task automatic check64;
    input [255:0] name;
    input [`XLEN-1:0] actual;
    input [`XLEN-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%016x expected=0x%016x",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    errors = 0;
    rst = 1'b1;
    clear_inputs();
    tick();
    rst = 1'b0;

    read0_addr = 5'd0;
    read1_addr = 5'd1;
    read2_addr = 5'd31;
    #1;
    check64("reset read0", read0_data, 64'h0);
    check64("reset read1", read1_data, 64'h0);
    check64("reset read2", read2_data, 64'h0);

    load_write_valid = 1'b1;
    load_write_addr = 5'd1;
    load_write_data = 64'h1111_2222_3333_4444;
    result_write_valid = 1'b1;
    result_write_addr = 5'd2;
    result_write_data = 64'haaaa_bbbb_cccc_dddd;
    tick();
    clear_inputs();
    read0_addr = 5'd1;
    read1_addr = 5'd2;
    #1;
    check64("load write stored", read0_data, 64'h1111_2222_3333_4444);
    check64("result write stored", read1_data, 64'haaaa_bbbb_cccc_dddd);

    load_write_valid = 1'b1;
    load_write_addr = 5'd3;
    load_write_data = 64'h0000_0000_0000_0001;
    result_write_valid = 1'b1;
    result_write_addr = 5'd3;
    result_write_data = 64'h0000_0000_0000_0002;
    tick();
    clear_inputs();
    read0_addr = 5'd3;
    #1;
    check64("result write priority", read0_data, 64'h0000_0000_0000_0002);

    result_write_valid = 1'b1;
    result_write_addr = 5'd0;
    result_write_data = 64'h5555_5555_5555_5555;
    tick();
    clear_inputs();
    read0_addr = 5'd0;
    #1;
    check64("f0 writable", read0_data, 64'h5555_5555_5555_5555);

    flush = 1'b1;
    tick();
    clear_inputs();
    read0_addr = 5'd0;
    read1_addr = 5'd1;
    read2_addr = 5'd2;
    #1;
    check64("flush clears f0", read0_data, 64'h0);
    check64("flush clears f1", read1_data, 64'h0);
    check64("flush clears f2", read2_data, 64'h0);

    if (errors == 0)
      $display("PASS tb_ooo_fp_reg_file");
    else
      $display("FAIL tb_ooo_fp_reg_file errors=%0d", errors);
    $finish;
  end
endmodule
