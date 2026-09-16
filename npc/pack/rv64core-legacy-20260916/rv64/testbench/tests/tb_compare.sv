`include "define.v"

module tb_compare;
  `include "tb_common.svh"

  reg [`XLEN-1:0] lhs;
  reg [`XLEN-1:0] rhs;
  reg [2:0] cmp_op;
  wire cmp_true;
  localparam [`XLEN-1:0] NEG_TWO = {`XLEN{1'b1}} - {{(`XLEN-1){1'b0}}, 1'b1};

  CompareUnit dut (
    .lhs_i(lhs),
    .rhs_i(rhs),
    .cmp_op_i(cmp_op),
    .cmp_true_o(cmp_true)
  );

  task automatic run_cmp;
    input [1023:0] name;
    input [2:0] op;
    input [`XLEN-1:0] a;
    input [`XLEN-1:0] b;
    input exp;
    begin
      cmp_op = op;
      lhs = a;
      rhs = b;
      #1;
      tb_check1(name, cmp_true, exp);
    end
  endtask

  initial begin
    tb_errors = 0;

    run_cmp("eq true", `CMP_OP_EQ, 32'h1234, 32'h1234, 1'b1);
    run_cmp("eq false", `CMP_OP_EQ, 32'h1234, 32'h5678, 1'b0);
    run_cmp("ne true", `CMP_OP_NE, 32'h1234, 32'h5678, 1'b1);
    run_cmp("lt signed", `CMP_OP_LT, NEG_TWO, 32'd1, 1'b1);
    run_cmp("ge signed", `CMP_OP_GE, NEG_TWO, 32'd1, 1'b0);
    run_cmp("ltu unsigned", `CMP_OP_LTU, 32'd1, 32'hffff_fffe, 1'b1);
    run_cmp("geu unsigned", `CMP_OP_GEU, 32'hffff_fffe, 32'd1, 1'b1);
    run_cmp("default false", `CMP_OP_NONE, 32'h0, 32'h0, 1'b0);

    tb_finish("tb_compare");
  end
endmodule
