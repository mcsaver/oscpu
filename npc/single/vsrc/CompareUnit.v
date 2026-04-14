`include "define.v"

module CompareUnit (
  input [`XLEN-1:0] lhs_i,
  input [`XLEN-1:0] rhs_i,
  input [2:0] cmp_op_i,
  output reg cmp_true_o
);

  wire eq_w = (lhs_i == rhs_i);
  wire signed_lt_w = ($signed(lhs_i) < $signed(rhs_i));
  wire unsigned_lt_w = (lhs_i < rhs_i);

  // 把关系比较和跳转决策拆开，后续加异常或重定向时不会把比较器变成控制器。
  always @(*) begin
    case (cmp_op_i)
      `CMP_OP_EQ:  cmp_true_o = eq_w;
      `CMP_OP_NE:  cmp_true_o = ~eq_w;
      `CMP_OP_LT:  cmp_true_o = signed_lt_w;
      `CMP_OP_GE:  cmp_true_o = ~signed_lt_w;
      `CMP_OP_LTU: cmp_true_o = unsigned_lt_w;
      `CMP_OP_GEU: cmp_true_o = ~unsigned_lt_w;
      default:     cmp_true_o = 1'b0;
    endcase
  end

endmodule
