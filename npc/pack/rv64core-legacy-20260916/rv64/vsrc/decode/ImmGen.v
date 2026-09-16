`include "define.v"

module ImmGen (
  input [`INST_W-1:7] inst_imm_i,
  input [2:0] imm_type_i,
  output reg [`XLEN-1:0] imm_o
);

  // 只接入 inst[31:7] 的立即数字段，opcode 仍由 DecodeUnit 消费，避免模块端口过宽。
  always @(*) begin
    case (imm_type_i)
      `IMM_TYPE_I: imm_o = {{(`XLEN-12){inst_imm_i[31]}}, inst_imm_i[31:20]};
      `IMM_TYPE_S: imm_o = {{(`XLEN-12){inst_imm_i[31]}}, inst_imm_i[31:25], inst_imm_i[11:7]};
      `IMM_TYPE_B: imm_o = {{(`XLEN-13){inst_imm_i[31]}}, inst_imm_i[31], inst_imm_i[7], inst_imm_i[30:25], inst_imm_i[11:8], 1'b0};
      `IMM_TYPE_U: imm_o = {{(`XLEN-32){inst_imm_i[31]}}, inst_imm_i[31:12], 12'b0};
      `IMM_TYPE_J: imm_o = {{(`XLEN-21){inst_imm_i[31]}}, inst_imm_i[31], inst_imm_i[19:12], inst_imm_i[20], inst_imm_i[30:21], 1'b0};
      default:     imm_o = {`XLEN{1'b0}};
    endcase
  end

endmodule
