`include "define.v"

// FP 符号注入（FSGNJ/FSGNJN/FSGNJX，单/双精度）：从 OooFpPendingExec 抽出的纯组合 owner。
// op = 指令 funct3：000 FSGNJ（取 rs2 符号）、001 FSGNJN（取 rs2 反符号）、
// 010 FSGNJX（rs1^rs2 符号）。单精度结果按 RV64 约定 NaN-box（高 32 位全 1）；
// 单精度源未正确 NaN-box 时按 canonical qNaN(0x7fc00000) 处理。
// 行为与原 OooFpPendingExec 内联 fp_sgnj_value 等价。
module OooFpSgnjGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              double_i,
  input  [2:0]       op_i,
  output [`XLEN-1:0] sgnj_value_o
);

  // 与父模块同义的 NaN-box 检查（trivial helper，随 owner 复制以保持自包含）。
  function fp_is_boxed_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_boxed_s_value = (value[63:32] == 32'hffff_ffff);
    end
  endfunction

  function [`XLEN-1:0] fp_sgnj_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] op;
    reg sign_bit;
    reg [31:0] rs1_single_bits;
    reg [31:0] rs2_single_bits;
    reg [31:0] single_bits;
    begin
      if (is_double) begin
        case (op)
          3'b000: sign_bit = rs2_value[63];
          3'b001: sign_bit = ~rs2_value[63];
          3'b010: sign_bit = rs1_value[63] ^ rs2_value[63];
          default: sign_bit = rs1_value[63];
        endcase
        fp_sgnj_value = {sign_bit, rs1_value[62:0]};
      end else begin
        rs1_single_bits = fp_is_boxed_s_value(rs1_value) ?
                          rs1_value[31:0] : 32'h7fc0_0000;
        rs2_single_bits = fp_is_boxed_s_value(rs2_value) ?
                          rs2_value[31:0] : 32'h7fc0_0000;
        case (op)
          3'b000: sign_bit = rs2_single_bits[31];
          3'b001: sign_bit = ~rs2_single_bits[31];
          3'b010: sign_bit = rs1_single_bits[31] ^ rs2_single_bits[31];
          default: sign_bit = rs1_single_bits[31];
        endcase
        single_bits = {sign_bit, rs1_single_bits[30:0]};
        fp_sgnj_value = {32'hffff_ffff, single_bits};
      end
    end
  endfunction

  assign sgnj_value_o = fp_sgnj_value(frs1_value_i, frs2_value_i, double_i, op_i);

endmodule
