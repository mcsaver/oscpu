`include "define.v"

// FP 符号注入（FSGNJ/FSGNJN/FSGNJX，单/双精度）：从 OooFpPendingExec 抽出的纯组合 owner。
// op = 指令 funct3：000 FSGNJ（取 rs2 符号）、001 FSGNJN（取 rs2 反符号）、
// 010 FSGNJX（rs1^rs2 符号）。单精度结果按 RV64 约定 NaN-box（高 32 位全 1）；
// 单精度源未正确 NaN-box 时按 canonical qNaN(0x7fc00000) 处理。
//
// 【硬件结构】纯组合,无寄存器/无 FSM。单个 always @(*) 组合块算 sgnj 结果。
// fp_is_boxed_s_value 是 1 行小型纯组合 helper(规范允许保留 function)。可综合 .v
// 用 always @(*) 不用 always_comb(iverilog 模块 TB 约束)。
module OooFpSgnjGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              double_i,
  input  [2:0]       op_i,
  output reg [`XLEN-1:0] sgnj_value_o
);

  // 与父模块同义的 NaN-box 检查（trivial 小 helper，随 owner 复制以保持自包含）。
  function fp_is_boxed_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_boxed_s_value = (value[63:32] == 32'hffff_ffff);
    end
  endfunction

  // 符号注入 datapath（显式组合块）
  always @(*) begin : sgnj_datapath
    reg sign_bit;
    reg [31:0] rs1_single_bits;
    reg [31:0] rs2_single_bits;
    reg [31:0] single_bits;
    sign_bit = 1'b0;
    rs1_single_bits = 32'b0;
    rs2_single_bits = 32'b0;
    single_bits = 32'b0;
    if (double_i) begin
      case (op_i)
        3'b000: sign_bit = frs2_value_i[63];
        3'b001: sign_bit = ~frs2_value_i[63];
        3'b010: sign_bit = frs1_value_i[63] ^ frs2_value_i[63];
        default: sign_bit = frs1_value_i[63];
      endcase
      sgnj_value_o = {sign_bit, frs1_value_i[62:0]};
    end else begin
      rs1_single_bits = fp_is_boxed_s_value(frs1_value_i) ?
                        frs1_value_i[31:0] : 32'h7fc0_0000;
      rs2_single_bits = fp_is_boxed_s_value(frs2_value_i) ?
                        frs2_value_i[31:0] : 32'h7fc0_0000;
      case (op_i)
        3'b000: sign_bit = rs2_single_bits[31];
        3'b001: sign_bit = ~rs2_single_bits[31];
        3'b010: sign_bit = rs1_single_bits[31] ^ rs2_single_bits[31];
        default: sign_bit = rs1_single_bits[31];
      endcase
      single_bits = {sign_bit, rs1_single_bits[30:0]};
      sgnj_value_o = {32'hffff_ffff, single_bits};
    end
  end

endmodule
