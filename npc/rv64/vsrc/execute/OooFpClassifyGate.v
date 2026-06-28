`include "define.v"

// FP 分类（FCLASS.S/FCLASS.D）：从 OooFpPendingExec 抽出的纯组合 owner。
// 输入 frs1 与 double 选择，输出 10 位 class mask 零扩展到 XLEN：
// bit0 -inf, 1 -normal, 2 -subnormal, 3 -0, 4 +0, 5 +subnormal,
// 6 +normal, 7 +inf, 8 sNaN, 9 qNaN。与原 fp_class_s/d_value 等价。
module OooFpClassifyGate (
  input  [`XLEN-1:0] frs1_value_i,
  input              double_i,
  output [`XLEN-1:0] class_value_o
);

  function [`XLEN-1:0] fp_class_s_value;
    input [31:0] value;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [9:0] class_bits;
    begin
      sign = value[31];
      exp = value[30:23];
      frac = value[22:0];
      class_bits = 10'b0;
      if (exp == 8'hff) begin
        if (frac == 23'b0) begin
          class_bits[sign ? 0 : 7] = 1'b1;
        end else begin
          class_bits[frac[22] ? 9 : 8] = 1'b1;
        end
      end else if (exp == 8'h00) begin
        if (frac == 23'b0) begin
          class_bits[sign ? 3 : 4] = 1'b1;
        end else begin
          class_bits[sign ? 2 : 5] = 1'b1;
        end
      end else begin
        class_bits[sign ? 1 : 6] = 1'b1;
      end
      fp_class_s_value = {{(`XLEN-10){1'b0}}, class_bits};
    end
  endfunction

  function [`XLEN-1:0] fp_class_d_value;
    input [`XLEN-1:0] value;
    reg sign;
    reg [10:0] exp;
    reg [51:0] frac;
    reg [9:0] class_bits;
    begin
      sign = value[63];
      exp = value[62:52];
      frac = value[51:0];
      class_bits = 10'b0;
      if (exp == 11'h7ff) begin
        if (frac == 52'b0) begin
          class_bits[sign ? 0 : 7] = 1'b1;
        end else begin
          class_bits[frac[51] ? 9 : 8] = 1'b1;
        end
      end else if (exp == 11'h000) begin
        if (frac == 52'b0) begin
          class_bits[sign ? 3 : 4] = 1'b1;
        end else begin
          class_bits[sign ? 2 : 5] = 1'b1;
        end
      end else begin
        class_bits[sign ? 1 : 6] = 1'b1;
      end
      fp_class_d_value = {{(`XLEN-10){1'b0}}, class_bits};
    end
  endfunction

  assign class_value_o = double_i ? fp_class_d_value(frs1_value_i)
                                  : fp_class_s_value(frs1_value_i[31:0]);

endmodule
