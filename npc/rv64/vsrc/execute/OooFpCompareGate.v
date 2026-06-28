`include "define.v"

// FP 比较与最值（FEQ/FLT/FLE、FMIN/FMAX，单/双精度）：
// 从 OooFpPendingExec 抽出的纯组合 owner。
// cmp_op = 指令 funct3：010 FEQ、001 FLT、000 FLE；FCMP 含 NaN 时结果位为 0，
//   sNaN 或（FLT/FLE 遇 qNaN）置 NV。is_max = funct3[0]：FMIN=0、FMAX=1；
//   min/max 单 NaN 取非 NaN 操作数、双 NaN 返回 canonical qNaN、±0 按符号定序，
//   仅 sNaN 置 NV。
//
// 【硬件结构】纯组合,无寄存器/无 FSM。4 个 always @(*) 组合块分别算 compare
// value/fflags、minmax value/fflags;NaN/sNaN 谓词由 OooFpPredicates 小 helper 提供。
// 可综合 .v 用 always @(*) 不用 always_comb(iverilog 模块 TB 约束)。datapath body
// 与原 function 逐字等价(仅入口改端口别名)。
module OooFpCompareGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              double_i,
  input  [2:0]       cmp_op_i,
  input              is_max_i,
  output reg [`XLEN-1:0] compare_value_o,
  output reg [4:0]       compare_fflags_o,
  output reg [`XLEN-1:0] minmax_value_o,
  output reg [4:0]       minmax_fflags_o
);

  `include "execute/OooFpPredicates.v"

  // FCMP fflags（NV）组合块
  always @(*) begin : compare_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_double;
    reg [2:0] op;
    reg nan_operand;
    reg snan_operand;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    is_double = double_i; op = cmp_op_i;
    nan_operand = is_double ?
        (fp_is_nan_d_value(rs1_value) || fp_is_nan_d_value(rs2_value)) :
        (fp_is_nan_s_value(rs1_value) || fp_is_nan_s_value(rs2_value));
    snan_operand = is_double ?
        (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value)) :
        (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value));
    compare_fflags_o =
        (snan_operand || (nan_operand && (op != 3'b010))) ?
        `FP_FLAG_NV : 5'b00000;
  end

  // FMIN/FMAX fflags（NV）组合块
  always @(*) begin : minmax_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_double;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i; is_double = double_i;
    minmax_fflags_o =
        (is_double ?
         (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value)) :
         (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value))) ?
        `FP_FLAG_NV : 5'b00000;
  end

  // FCMP 比较结果组合块（datapath）
  always @(*) begin : compare_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_double;
    reg [2:0] op;
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
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    is_double = double_i; op = cmp_op_i;
    sign1 = 0; sign2 = 0; nan_operand = 0; both_zero = 0; equal_value = 0;
    less_value = 0; mag1_d = 0; mag2_d = 0; mag1_s = 0; mag2_s = 0; result_bit = 0;
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
      compare_value_o = {{(`XLEN-1){1'b0}}, result_bit};
  end

  // FMIN/FMAX 结果组合块（datapath）
  always @(*) begin : minmax_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_double;
    reg is_max;
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
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    is_double = double_i; is_max = is_max_i;
    sign1 = 0; sign2 = 0; nan1 = 0; nan2 = 0; both_zero = 0; less_value = 0;
    mag1_d = 0; mag2_d = 0; mag1_s = 0; mag2_s = 0;
      if (is_double) begin
        nan1 = fp_is_nan_d_value(rs1_value);
        nan2 = fp_is_nan_d_value(rs2_value);
        sign1 = rs1_value[63];
        sign2 = rs2_value[63];
        mag1_d = rs1_value[62:0];
        mag2_d = rs2_value[62:0];
        both_zero = (mag1_d == 63'b0) && (mag2_d == 63'b0);
        if (nan1 && nan2) begin
          minmax_value_o = 64'h7ff8000000000000;
        end else if (nan1) begin
          minmax_value_o = rs2_value;
        end else if (nan2) begin
          minmax_value_o = rs1_value;
        end else if (both_zero) begin
          if (is_max)
            minmax_value_o = sign1 ? rs2_value : rs1_value;
          else
            minmax_value_o = sign1 ? rs1_value : rs2_value;
        end else begin
          if (sign1 != sign2) begin
            less_value = sign1;
          end else if (sign1) begin
            less_value = mag1_d > mag2_d;
          end else begin
            less_value = mag1_d < mag2_d;
          end
          minmax_value_o = is_max ?
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
          minmax_value_o = 64'hffffffff7fc00000;
        end else if (nan1) begin
          minmax_value_o = {32'hffff_ffff, rs2_value[31:0]};
        end else if (nan2) begin
          minmax_value_o = {32'hffff_ffff, rs1_value[31:0]};
        end else if (both_zero) begin
          if (is_max)
            minmax_value_o = {32'hffff_ffff,
                               (sign1 ? rs2_value[31:0] : rs1_value[31:0])};
          else
            minmax_value_o = {32'hffff_ffff,
                               (sign1 ? rs1_value[31:0] : rs2_value[31:0])};
        end else begin
          if (sign1 != sign2) begin
            less_value = sign1;
          end else if (sign1) begin
            less_value = mag1_s > mag2_s;
          end else begin
            less_value = mag1_s < mag2_s;
          end
          minmax_value_o = {32'hffff_ffff,
              (is_max ?
               (less_value ? rs2_value[31:0] : rs1_value[31:0]) :
               (less_value ? rs1_value[31:0] : rs2_value[31:0]))};
        end
      end
  end

endmodule
