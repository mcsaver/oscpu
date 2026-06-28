`include "define.v"

// FP 分类（FCLASS.S/FCLASS.D）：从 OooFpPendingExec 抽出的纯组合 owner。
// 输入 frs1 与 double 选择，输出 10 位 class mask 零扩展到 XLEN：
// bit0 -inf, 1 -normal, 2 -subnormal, 3 -0, 4 +0, 5 +subnormal,
// 6 +normal, 7 +inf, 8 sNaN, 9 qNaN。
//
// 【硬件结构】纯组合,无寄存器/无 FSM。两个 always @(*) 组合块分别算单/双精度
// class mask,输出处按 double_i + NaN-box 显式 mux。可综合 .v 用 always @(*)
// 不用 always_comb(iverilog 模块 TB 约束,见 rtl-generation-workflow.instructions.md)。
module OooFpClassifyGate (
  input  [`XLEN-1:0] frs1_value_i,
  input              double_i,
  output [`XLEN-1:0] class_value_o
);

  // 单精度 class mask 组合块
  reg [9:0] class_s_bits;
  always @(*) begin : class_s_datapath
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    sign = frs1_value_i[31];
    exp  = frs1_value_i[30:23];
    frac = frs1_value_i[22:0];
    class_s_bits = 10'b0;
    if (exp == 8'hff) begin
      if (frac == 23'b0)
        class_s_bits[sign ? 0 : 7] = 1'b1;
      else
        class_s_bits[frac[22] ? 9 : 8] = 1'b1;
    end else if (exp == 8'h00) begin
      if (frac == 23'b0)
        class_s_bits[sign ? 3 : 4] = 1'b1;
      else
        class_s_bits[sign ? 2 : 5] = 1'b1;
    end else begin
      class_s_bits[sign ? 1 : 6] = 1'b1;
    end
  end

  // 双精度 class mask 组合块
  reg [9:0] class_d_bits;
  always @(*) begin : class_d_datapath
    reg sign;
    reg [10:0] exp;
    reg [51:0] frac;
    sign = frs1_value_i[63];
    exp  = frs1_value_i[62:52];
    frac = frs1_value_i[51:0];
    class_d_bits = 10'b0;
    if (exp == 11'h7ff) begin
      if (frac == 52'b0)
        class_d_bits[sign ? 0 : 7] = 1'b1;
      else
        class_d_bits[frac[51] ? 9 : 8] = 1'b1;
    end else if (exp == 11'h000) begin
      if (frac == 52'b0)
        class_d_bits[sign ? 3 : 4] = 1'b1;
      else
        class_d_bits[sign ? 2 : 5] = 1'b1;
    end else begin
      class_d_bits[sign ? 1 : 6] = 1'b1;
    end
  end

  // FP#6:FCLASS.S 须查 NaN-boxing。未正确 box(高 32 位非全 1)的单精度值视为
  // quiet NaN(class bit 9),而非按原始低 32 位分类。共享输出 mux。
  wire single_nan_boxed_w = (frs1_value_i[`XLEN-1:32] == 32'hffff_ffff);
  assign class_value_o =
      double_i           ? {{(`XLEN-10){1'b0}}, class_d_bits} :
      single_nan_boxed_w ? {{(`XLEN-10){1'b0}}, class_s_bits} :
                           {{(`XLEN-10){1'b0}}, 10'h200};  // qNaN: bit 9

endmodule
