`include "define.v"

module ALU (
  input [`XLEN-1:0] src1_i,
  input [`XLEN-1:0] src2_i,
  input [3:0] alu_op_i,
  output reg [`XLEN-1:0] result_o
);

  wire signed_lt_w = ($signed(src1_i) < $signed(src2_i));
  wire unsigned_lt_w = (src1_i < src2_i);

  // 保持 ALU 纯组合，便于顶层状态机把“算出结果”和“允许提交”两件事分开管理。
  always @(*) begin
    case (alu_op_i)
      `ALU_OP_ADD:    result_o = src1_i + src2_i;
      `ALU_OP_SUB:    result_o = src1_i - src2_i;
      `ALU_OP_SLL:    result_o = src1_i << src2_i[`SHIFT_AMT_W-1:0];
      `ALU_OP_SLT:    result_o = {{(`XLEN-1){1'b0}}, signed_lt_w};
      `ALU_OP_SLTU:   result_o = {{(`XLEN-1){1'b0}}, unsigned_lt_w};
      `ALU_OP_XOR:    result_o = src1_i ^ src2_i;
      `ALU_OP_SRL:    result_o = src1_i >> src2_i[`SHIFT_AMT_W-1:0];
      `ALU_OP_SRA:    result_o = $signed(src1_i) >>> src2_i[`SHIFT_AMT_W-1:0];
      `ALU_OP_OR:     result_o = src1_i | src2_i;
      `ALU_OP_AND:    result_o = src1_i & src2_i;
      `ALU_OP_COPY_B: result_o = src2_i;
      `ALU_OP_COPY_A: result_o = src1_i;
      default:        result_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
