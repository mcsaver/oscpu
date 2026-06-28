`include "define.v"

// FP 比较与最值（FEQ/FLT/FLE、FMIN/FMAX，单/双精度）：
// 从 OooFpPendingExec 抽出的纯组合 owner。
// cmp_op = 指令 funct3：010 FEQ、001 FLT、000 FLE；FCMP 含 NaN 时结果位为 0，
//   sNaN 或（FLT/FLE 遇 qNaN）置 NV。is_max = funct3[0]：FMIN=0、FMAX=1；
//   min/max 单 NaN 取非 NaN 操作数、双 NaN 返回 canonical qNaN、±0 按符号定序，
//   仅 sNaN 置 NV。行为与原 OooFpPendingExec 内联实现等价。
module OooFpCompareGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              double_i,
  input  [2:0]       cmp_op_i,
  input              is_max_i,
  output [`XLEN-1:0] compare_value_o,
  output [4:0]       compare_fflags_o,
  output [`XLEN-1:0] minmax_value_o,
  output [4:0]       minmax_fflags_o
);

  `include "execute/OooFpPredicates.v"

  function [4:0] fp_compare_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] op;
    reg nan_operand;
    reg snan_operand;
    begin
      nan_operand = is_double ?
          (fp_is_nan_d_value(rs1_value) || fp_is_nan_d_value(rs2_value)) :
          (fp_is_nan_s_value(rs1_value) || fp_is_nan_s_value(rs2_value));
      snan_operand = is_double ?
          (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value)) :
          (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value));
      fp_compare_fflags =
          (snan_operand || (nan_operand && (op != 3'b010))) ?
          `FP_FLAG_NV : 5'b00000;
    end
  endfunction

  function [4:0] fp_minmax_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    begin
      fp_minmax_fflags =
          (is_double ?
           (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value)) :
           (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value))) ?
          `FP_FLAG_NV : 5'b00000;
    end
  endfunction

  function [`XLEN-1:0] fp_compare_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] op;
    reg sign1;
    reg sign2;
    reg nan_operand;
    reg both_zero;
    reg equal_value;
    reg less_value;
    reg [62:0] mag1_d;
    reg [62:0] mag2_d;
    reg [30:0] mag1_s;
    reg [30:0] mag2_s;
    reg result_bit;
    begin
      if (is_double) begin
        sign1 = rs1_value[63];
        sign2 = rs2_value[63];
        mag1_d = rs1_value[62:0];
        mag2_d = rs2_value[62:0];
        nan_operand = fp_is_nan_d_value(rs1_value) ||
                      fp_is_nan_d_value(rs2_value);
        both_zero = (mag1_d == 63'b0) && (mag2_d == 63'b0);
        equal_value = both_zero || (rs1_value == rs2_value);
        if (both_zero || equal_value) begin
          less_value = 1'b0;
        end else if (sign1 != sign2) begin
          less_value = sign1;
        end else if (sign1) begin
          less_value = mag1_d > mag2_d;
        end else begin
          less_value = mag1_d < mag2_d;
        end
      end else begin
        sign1 = rs1_value[31];
        sign2 = rs2_value[31];
        mag1_s = rs1_value[30:0];
        mag2_s = rs2_value[30:0];
        nan_operand = fp_is_nan_s_value(rs1_value) ||
                      fp_is_nan_s_value(rs2_value);
        both_zero = (mag1_s == 31'b0) && (mag2_s == 31'b0);
        equal_value = both_zero || (rs1_value[31:0] == rs2_value[31:0]);
        if (both_zero || equal_value) begin
          less_value = 1'b0;
        end else if (sign1 != sign2) begin
          less_value = sign1;
        end else if (sign1) begin
          less_value = mag1_s > mag2_s;
        end else begin
          less_value = mag1_s < mag2_s;
        end
      end

      if (nan_operand) begin
        result_bit = 1'b0;
      end else begin
        case (op)
          3'b000: result_bit = less_value || equal_value;
          3'b001: result_bit = less_value;
          3'b010: result_bit = equal_value;
          default: result_bit = 1'b0;
        endcase
      end
      fp_compare_value = {{(`XLEN-1){1'b0}}, result_bit};
    end
  endfunction

  function [`XLEN-1:0] fp_minmax_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input is_max;
    reg sign1;
    reg sign2;
    reg nan1;
    reg nan2;
    reg both_zero;
    reg less_value;
    reg [62:0] mag1_d;
    reg [62:0] mag2_d;
    reg [30:0] mag1_s;
    reg [30:0] mag2_s;
    begin
      if (is_double) begin
        nan1 = fp_is_nan_d_value(rs1_value);
        nan2 = fp_is_nan_d_value(rs2_value);
        sign1 = rs1_value[63];
        sign2 = rs2_value[63];
        mag1_d = rs1_value[62:0];
        mag2_d = rs2_value[62:0];
        both_zero = (mag1_d == 63'b0) && (mag2_d == 63'b0);
        if (nan1 && nan2) begin
          fp_minmax_value = 64'h7ff8000000000000;
        end else if (nan1) begin
          fp_minmax_value = rs2_value;
        end else if (nan2) begin
          fp_minmax_value = rs1_value;
        end else if (both_zero) begin
          if (is_max)
            fp_minmax_value = sign1 ? rs2_value : rs1_value;
          else
            fp_minmax_value = sign1 ? rs1_value : rs2_value;
        end else begin
          if (sign1 != sign2) begin
            less_value = sign1;
          end else if (sign1) begin
            less_value = mag1_d > mag2_d;
          end else begin
            less_value = mag1_d < mag2_d;
          end
          fp_minmax_value = is_max ?
              (less_value ? rs2_value : rs1_value) :
              (less_value ? rs1_value : rs2_value);
        end
      end else begin
        nan1 = fp_is_nan_s_value(rs1_value);
        nan2 = fp_is_nan_s_value(rs2_value);
        sign1 = rs1_value[31];
        sign2 = rs2_value[31];
        mag1_s = rs1_value[30:0];
        mag2_s = rs2_value[30:0];
        both_zero = (mag1_s == 31'b0) && (mag2_s == 31'b0);
        if (nan1 && nan2) begin
          fp_minmax_value = 64'hffffffff7fc00000;
        end else if (nan1) begin
          fp_minmax_value = {32'hffff_ffff, rs2_value[31:0]};
        end else if (nan2) begin
          fp_minmax_value = {32'hffff_ffff, rs1_value[31:0]};
        end else if (both_zero) begin
          if (is_max)
            fp_minmax_value = {32'hffff_ffff,
                               (sign1 ? rs2_value[31:0] : rs1_value[31:0])};
          else
            fp_minmax_value = {32'hffff_ffff,
                               (sign1 ? rs1_value[31:0] : rs2_value[31:0])};
        end else begin
          if (sign1 != sign2) begin
            less_value = sign1;
          end else if (sign1) begin
            less_value = mag1_s > mag2_s;
          end else begin
            less_value = mag1_s < mag2_s;
          end
          fp_minmax_value = {32'hffff_ffff,
              (is_max ?
               (less_value ? rs2_value[31:0] : rs1_value[31:0]) :
               (less_value ? rs1_value[31:0] : rs2_value[31:0]))};
        end
      end
    end
  endfunction

  assign compare_value_o  = fp_compare_value(frs1_value_i, frs2_value_i, double_i, cmp_op_i);
  assign compare_fflags_o = fp_compare_fflags(frs1_value_i, frs2_value_i, double_i, cmp_op_i);
  assign minmax_value_o   = fp_minmax_value(frs1_value_i, frs2_value_i, double_i, is_max_i);
  assign minmax_fflags_o  = fp_minmax_fflags(frs1_value_i, frs2_value_i, double_i);

endmodule
