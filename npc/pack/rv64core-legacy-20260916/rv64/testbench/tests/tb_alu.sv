`include "define.v"

module tb_alu;
  `include "tb_common.svh"

  reg [`XLEN-1:0] src1;
  reg [`XLEN-1:0] src2;
  reg [3:0] alu_op;
  wire [`XLEN-1:0] result;
  localparam [`XLEN-1:0] SIGN_MIN = {1'b1, {(`XLEN-1){1'b0}}};
  localparam [`XLEN-1:0] LOW_SHIFT_WRAP = {{(`XLEN-7){1'b0}}, 7'd65};
  localparam [5:0] SIGN_SHIFT_VAL = `XLEN - 1;
  localparam [`XLEN-1:0] SIGN_SHIFT = {{(`XLEN-6){1'b0}}, SIGN_SHIFT_VAL};

  ALU dut (
    .src1_i(src1),
    .src2_i(src2),
    .alu_op_i(alu_op),
    .result_o(result)
  );

  task automatic run_op;
    input [1023:0] name;
    input [3:0] op;
    input [`XLEN-1:0] a;
    input [`XLEN-1:0] b;
    input [`XLEN-1:0] exp;
    begin
      alu_op = op;
      src1 = a;
      src2 = b;
      #1;
      tb_check32(name, result, exp);
    end
  endtask

  initial begin
    tb_errors = 0;

    run_op("add wrap", `ALU_OP_ADD, 32'hffff_ffff, 32'd2, 32'd1);
    run_op("sub", `ALU_OP_SUB, 32'd3, 32'd5, 32'hffff_fffe);
    run_op("sll low shift", `ALU_OP_SLL, 32'h0000_0001, LOW_SHIFT_WRAP, 32'h0000_0002);
    run_op("slt signed", `ALU_OP_SLT, SIGN_MIN, 32'd1, 32'd1);
    run_op("sltu unsigned", `ALU_OP_SLTU, SIGN_MIN, 32'd1, 32'd0);
    run_op("xor", `ALU_OP_XOR, 32'h55aa_0f0f, 32'h0ff0_ffff, 32'h5a5a_f0f0);
    run_op("srl", `ALU_OP_SRL, SIGN_MIN, SIGN_SHIFT, 32'd1);
    run_op("sra", `ALU_OP_SRA, SIGN_MIN, SIGN_SHIFT, 32'hffff_ffff);
    run_op("or", `ALU_OP_OR, 32'hf000_0000, 32'h0000_000f, 32'hf000_000f);
    run_op("and", `ALU_OP_AND, 32'hff00_ff00, 32'h0f0f_0f0f, 32'h0f00_0f00);
    run_op("copy b", `ALU_OP_COPY_B, 32'h1111_1111, 32'h2222_2222, 32'h2222_2222);
    run_op("copy a", `ALU_OP_COPY_A, 32'h1111_1111, 32'h2222_2222, 32'h1111_1111);
    run_op("default zero", 4'h9, 32'hffff_ffff, 32'hffff_ffff, 32'h0000_0000);

    tb_finish("tb_alu");
  end
endmodule
