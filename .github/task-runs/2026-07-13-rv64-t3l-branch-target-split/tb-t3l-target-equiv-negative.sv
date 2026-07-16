`include "define.v"

module tb_t3l_target_equiv_negative;
  reg clk;
  reg rst;
  reg valid;
  reg [`XLEN-1:0] pc;
  reg [12:0] bimm;
  wire [`XLEN-1:0] target;

  OooFetchBranchTarget dut (
    .clk(clk),
    .rst(rst),
    .valid_i(valid),
    .pc_i(pc),
    .bimm_i(bimm),
    .target_o(target)
  );

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    valid = 1'b0;
    pc = 64'h0;
    bimm = 13'h0;
    #1 clk = 1'b1;
    #1 clk = 1'b0;

    rst = 1'b0;
    valid = 1'b1;
    pc = 64'h0;
    bimm = 13'h1ffe;
    #1;
    $display("[T3L-NEGATIVE-PREMISE] pc=0 bimm=-2 valid=1");
    clk = 1'b1;
    #1 clk = 1'b0;
    valid = 1'b0;
    #1;
    $display("[T3L-NEGATIVE-DONE]");
    $finish;
  end
endmodule
