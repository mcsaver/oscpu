`include "define.v"

// 双整数 lane 复用的组合 ALU：加减/比较共用进位链，左右移共用桶形移位器。
// 模块不增加流水延迟；是否写回由外部有效位和执行端口决定。
module ALU (
  input [`XLEN-1:0] src1_i,
  input [`XLEN-1:0] src2_i,
  input [3:0] alu_op_i,
  output reg [`XLEN-1:0] result_o
);
  wire subtract_w = (alu_op_i == `ALU_OP_SUB) ||
                    (alu_op_i == `ALU_OP_SLT) ||
                    (alu_op_i == `ALU_OP_SLTU);
  wire [`XLEN-1:0] add_rhs_w = src2_i ^ {`XLEN{subtract_w}};
  wire [`XLEN:0] sum_w = {1'b0,src1_i} + {1'b0,add_rhs_w} +
                         {{`XLEN{1'b0}},subtract_w};
  wire shared_signed_less_w = (src1_i[`XLEN-1] != src2_i[`XLEN-1]) ?
                     src1_i[`XLEN-1] : sum_w[`XLEN-1];
  wire shared_unsigned_less_w = !sum_w[`XLEN];

  wire shift_left_w = (alu_op_i == `ALU_OP_SLL);
  wire shift_sign_w = (alu_op_i == `ALU_OP_SRA) && src1_i[`XLEN-1];
  wire [`XLEN-1:0] reverse_src_w;
  wire [`XLEN-1:0] shift_input_w = shift_left_w ? reverse_src_w : src1_i;
  wire signed [`XLEN:0] shift_signed_w = {shift_sign_w,shift_input_w};
  wire [`XLEN:0] shift_right_w =
      shift_signed_w >>> src2_i[`SHIFT_AMT_W-1:0];
  wire [`XLEN-1:0] reverse_result_w;
  wire [`XLEN-1:0] shift_result_w =
      shift_left_w ? reverse_result_w : shift_right_w[`XLEN-1:0];
  genvar bit_idx;
  generate
    for (bit_idx=0; bit_idx<`XLEN; bit_idx=bit_idx+1) begin : gen_reverse
      assign reverse_src_w[bit_idx] = src1_i[`XLEN-1-bit_idx];
      assign reverse_result_w[bit_idx] = shift_right_w[`XLEN-1-bit_idx];
    end
  endgenerate

  always @(*) begin
    case (alu_op_i)
      `ALU_OP_ADD, `ALU_OP_SUB: result_o = sum_w[`XLEN-1:0];
      `ALU_OP_SLT:    result_o = {{(`XLEN-1){1'b0}},shared_signed_less_w};
      `ALU_OP_SLTU:   result_o = {{(`XLEN-1){1'b0}},shared_unsigned_less_w};
      `ALU_OP_SLL, `ALU_OP_SRL, `ALU_OP_SRA: result_o = shift_result_w;
      `ALU_OP_XOR:    result_o = src1_i ^ src2_i;
      `ALU_OP_OR:     result_o = src1_i | src2_i;
      `ALU_OP_AND:    result_o = src1_i & src2_i;
      `ALU_OP_COPY_B: result_o = src2_i;
      `ALU_OP_COPY_A: result_o = src1_i;
      default:        result_o = {`XLEN{1'b0}};
    endcase
  end
endmodule
