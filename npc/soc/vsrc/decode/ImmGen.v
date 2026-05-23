`include "define.v"

module ImmGen (
  input [`INST_W-1:0] inst_i,
  input [2:0] imm_type_i,
  output reg [`XLEN-1:0] imm_o
);

  /* verilator lint_off UNUSED */
  wire [6:0] opcode_bits_unused_w = inst_i[6:0];
  /* verilator lint_on UNUSED */

  // 把所有立即数拼接收口到一个地方，能显著降低分支、跳转和访存地址生成时的重复错误。
  always @(*) begin
    case (imm_type_i)
      `IMM_TYPE_I: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
      `IMM_TYPE_S: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
      `IMM_TYPE_B: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
      `IMM_TYPE_U: imm_o = {inst_i[31:12], 12'b0};
      `IMM_TYPE_J: imm_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
      default:     imm_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
