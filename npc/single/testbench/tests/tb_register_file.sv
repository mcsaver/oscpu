`include "define.v"

module tb_register_file;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg [`REG_ADDR_W-1:0] rs1_addr;
  reg [`REG_ADDR_W-1:0] rs2_addr;
  wire [`XLEN-1:0] rs1_data;
  wire [`XLEN-1:0] rs2_data;
  wire [`XLEN-1:0] a0_data;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs;
  reg wen;
  reg [`REG_ADDR_W-1:0] waddr;
  reg [`XLEN-1:0] wdata;

  RegisterFile dut (
    .clk(clk),
    .rst(rst),
    .rs1_addr_i(rs1_addr),
    .rs2_addr_i(rs2_addr),
    .rs1_data_o(rs1_data),
    .rs2_data_o(rs2_data),
    .a0_data_o(a0_data),
    .debug_gprs_o(debug_gprs),
    .wen_i(wen),
    .waddr_i(waddr),
    .wdata_i(wdata)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    rs1_addr = 5'd0;
    rs2_addr = 5'd1;
    wen = 1'b0;
    waddr = 5'd0;
    wdata = 32'h0;
    `TB_TICK(clk);
    rst = 1'b0;
    #1;
    tb_check32("x0 reset", rs1_data, 32'h0);
    tb_check32("x1 reset", rs2_data, 32'h0);

    wen = 1'b1; waddr = 5'd1; wdata = 32'h1234_5678;
    `TB_TICK(clk);
    wen = 1'b0; rs1_addr = 5'd1; #1;
    tb_check32("x1 write", rs1_data, 32'h1234_5678);
    tb_check32("debug x1", debug_gprs[1 * `XLEN +: `XLEN], 32'h1234_5678);

    wen = 1'b1; waddr = 5'd0; wdata = 32'hffff_ffff;
    `TB_TICK(clk);
    wen = 1'b0; rs1_addr = 5'd0; #1;
    tb_check32("x0 hard zero", rs1_data, 32'h0);
    tb_check32("debug x0", debug_gprs[0 +: `XLEN], 32'h0);

    wen = 1'b1; waddr = 5'd10; wdata = 32'hdead_beef;
    `TB_TICK(clk);
    wen = 1'b0; #1;
    tb_check32("a0 mirror", a0_data, 32'hdead_beef);

    tb_finish("tb_register_file");
  end
endmodule
