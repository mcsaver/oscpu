`include "define.v"

// FP 加减/乘/乘加（FADD/FSUB、FMUL、FMADD/FMSUB/FNMADD/FNMSUB，单/双精度）：
// 从 OooFpPendingExec 抽出的纯组合 owner。op-decode（sub_op/negate_product/
// subtract_addend）由父模块从 funct7 算好后输入；rm = inst[14:12]。
// FMA fflags = mul_fflags | addsub_fflags(product, frs3, subtract_addend)，其中
// product = negate_product ? -mul(frs1,frs2) : mul(frs1,frs2)。行为与原 OooFpPendingExec
// 内联实现等价。
module OooFpArithGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input  [`XLEN-1:0] frs3_value_i,
  input              double_i,
  input              sub_op_i,
  input              negate_product_i,
  input              subtract_addend_i,
  input  [2:0]       rm_i,
  output [`XLEN-1:0] addsub_value_o,
  output [4:0]       addsub_fflags_o,
  output [`XLEN-1:0] mul_value_o,
  output [4:0]       mul_fflags_o,
  output [`XLEN-1:0] fma_value_o,
  output [4:0]       fma_fflags_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  function [`XLEN-1:0] fp_addsub_d_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_sub;
    input [2:0] rm;
    reg sign_a;
    reg sign_b;
    reg sign_z;
    reg [10:0] exp_a;
    reg [10:0] exp_b;
    reg [10:0] exp_a_eff;
    reg [10:0] exp_b_eff;
    reg [10:0] exp_z;
    reg [51:0] frac_a;
    reg [51:0] frac_b;
    reg [55:0] sig_a;
    reg [55:0] sig_b;
    reg [55:0] sig_a_aligned;
    reg [55:0] sig_b_aligned;
    reg [55:0] sig_norm;
    reg [56:0] sig_sum;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg [10:0] exp_diff;
    reg [6:0] shift_dist;
    reg guard;
    reg sticky;
    reg inc;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg a_lt_b_mag;
    reg [6:0] norm_lzc;
    reg [6:0] norm_shift;
    reg [10:0] norm_exp_limit;
    begin
      sign_a = rs1_value[63];
      sign_b = rs2_value[63] ^ is_sub;
      exp_a = rs1_value[62:52];
      exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0];
      frac_b = rs2_value[51:0];
      a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
      b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
      a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
      b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
      a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
      b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);

      if (a_is_nan || b_is_nan) begin
        fp_addsub_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        fp_addsub_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf) begin
        fp_addsub_d_value = {sign_a, 11'h7ff, 52'b0};
      end else if (b_is_inf) begin
        fp_addsub_d_value = {sign_b, 11'h7ff, 52'b0};
      end else if (a_is_zero && b_is_zero) begin
        // FP#4: (+0)+(-0) 等异号零和在 RDN(rm=010)下为 -0,其余模式 +0。
        fp_addsub_d_value =
            {((rm == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 63'b0};
      end else if (a_is_zero) begin
        fp_addsub_d_value = {sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        fp_addsub_d_value = rs1_value;
      end else begin
        exp_a_eff = (exp_a == 11'h000) ? 11'd1 : exp_a;
        exp_b_eff = (exp_b == 11'h000) ? 11'd1 : exp_b;
        sig_a = {(exp_a != 11'h000), frac_a, 3'b000};
        sig_b = {(exp_b != 11'h000), frac_b, 3'b000};

        if (exp_a_eff >= exp_b_eff) begin
          exp_z = exp_a_eff;
          sig_a_aligned = sig_a;
          exp_diff = exp_a_eff - exp_b_eff;
          shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
          sig_b_aligned = fp_shift_right_jam_56(sig_b, shift_dist);
        end else begin
          exp_z = exp_b_eff;
          exp_diff = exp_b_eff - exp_a_eff;
          shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
          sig_a_aligned = fp_shift_right_jam_56(sig_a, shift_dist);
          sig_b_aligned = sig_b;
        end

        if (sign_a == sign_b) begin
          sign_z = sign_a;
          sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
          if (sig_sum[56]) begin
            sig_norm = sig_sum[56:1];
            sig_norm[0] = sig_norm[0] | sig_sum[0];
            exp_z = exp_z + 11'd1;
          end else begin
            sig_norm = sig_sum[55:0];
          end
        end else begin
          a_lt_b_mag =
              (exp_a_eff < exp_b_eff) ||
              ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
          if ((exp_a_eff == exp_b_eff) && (sig_a == sig_b)) begin
            sign_z = 1'b0;
            sig_norm = 56'b0;
          end else if (a_lt_b_mag) begin
            sign_z = sign_b;
            sig_norm = sig_b_aligned - sig_a_aligned;
          end else begin
            sign_z = sign_a;
            sig_norm = sig_a_aligned - sig_b_aligned;
          end
          if ((sig_norm != 56'b0) && (exp_z > 11'd1)) begin
            norm_lzc = fp_lzc_56(sig_norm);
            norm_exp_limit = exp_z - 11'd1;
            norm_shift = ({4'b0, norm_lzc} < norm_exp_limit) ?
                         norm_lzc : norm_exp_limit[6:0];
            sig_norm = sig_norm << norm_shift;
            exp_z = exp_z - {4'b0, norm_shift};
          end
        end

        if (sig_norm == 56'b0) begin
          // FP#4: 精确抵消(x+(-x))的零结果在 RDN 下为 -0,其余 +0。
          fp_addsub_d_value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
        end else begin
          mant53 = sig_norm[55:3];
          guard = sig_norm[2];
          sticky = sig_norm[1] | sig_norm[0];
          inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
          mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
          if (mant_round_ext[53]) begin
            exp_z = exp_z + 11'd1;
            mant53 = mant_round_ext[53:1];
          end else begin
            mant53 = mant_round_ext[52:0];
          end

          if (exp_z >= 11'h7ff) begin
            fp_addsub_d_value = {sign_z, 11'h7ff, 52'b0};
          end else if ((exp_z == 11'd1) && !mant53[52]) begin
            fp_addsub_d_value = {sign_z, 11'b0, mant53[51:0]};
          end else begin
            fp_addsub_d_value = {sign_z, exp_z, mant53[51:0]};
          end
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_addsub_s_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_sub;
    input [2:0] rm;
    reg [31:0] a;
    reg [31:0] b;
    reg sign_a;
    reg sign_b;
    reg sign_z;
    reg [7:0] exp_a;
    reg [7:0] exp_b;
    reg [7:0] exp_a_eff;
    reg [7:0] exp_b_eff;
    reg [7:0] exp_z;
    reg [22:0] frac_a;
    reg [22:0] frac_b;
    reg [26:0] sig_a;
    reg [26:0] sig_b;
    reg [26:0] sig_a_aligned;
    reg [26:0] sig_b_aligned;
    reg [26:0] sig_norm;
    reg [27:0] sig_sum;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg [7:0] exp_diff;
    reg [5:0] shift_dist;
    reg guard;
    reg sticky;
    reg inc;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg a_lt_b_mag;
    reg [5:0] norm_lzc;
    reg [5:0] norm_shift;
    reg [7:0] norm_exp_limit;
    begin
      a = rs1_value[31:0];
      b = rs2_value[31:0];
      sign_a = a[31];
      sign_b = b[31] ^ is_sub;
      exp_a = a[30:23];
      exp_b = b[30:23];
      frac_a = a[22:0];
      frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = (rs1_value[63:32] == 32'hffff_ffff) &&
                 (exp_a == 8'hff) && (frac_a == 23'b0);
      b_is_inf = (rs2_value[63:32] == 32'hffff_ffff) &&
                 (exp_b == 8'hff) && (frac_b == 23'b0);
      a_is_zero = (rs1_value[63:32] == 32'hffff_ffff) &&
                  (exp_a == 8'h00) && (frac_a == 23'b0);
      b_is_zero = (rs2_value[63:32] == 32'hffff_ffff) &&
                  (exp_b == 8'h00) && (frac_b == 23'b0);

      if (a_is_nan || b_is_nan) begin
        fp_addsub_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        fp_addsub_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf) begin
        fp_addsub_s_value = {32'hffff_ffff, sign_a, 8'hff, 23'b0};
      end else if (b_is_inf) begin
        fp_addsub_s_value = {32'hffff_ffff, sign_b, 8'hff, 23'b0};
      end else if (a_is_zero && b_is_zero) begin
        // FP#4: 异号零和在 RDN 下为 -0(NaN-boxed)。
        fp_addsub_s_value =
            {32'hffff_ffff, ((rm == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 31'b0};
      end else if (a_is_zero) begin
        fp_addsub_s_value = {32'hffff_ffff, sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        fp_addsub_s_value = {32'hffff_ffff, a};
      end else begin
        exp_a_eff = (exp_a == 8'h00) ? 8'd1 : exp_a;
        exp_b_eff = (exp_b == 8'h00) ? 8'd1 : exp_b;
        sig_a = {(exp_a != 8'h00), frac_a, 3'b000};
        sig_b = {(exp_b != 8'h00), frac_b, 3'b000};

        if (exp_a_eff >= exp_b_eff) begin
          exp_z = exp_a_eff;
          sig_a_aligned = sig_a;
          exp_diff = exp_a_eff - exp_b_eff;
          shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
          sig_b_aligned = fp_shift_right_jam_27(sig_b, shift_dist);
        end else begin
          exp_z = exp_b_eff;
          exp_diff = exp_b_eff - exp_a_eff;
          shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
          sig_a_aligned = fp_shift_right_jam_27(sig_a, shift_dist);
          sig_b_aligned = sig_b;
        end

        if (sign_a == sign_b) begin
          sign_z = sign_a;
          sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
          if (sig_sum[27]) begin
            sig_norm = sig_sum[27:1];
            sig_norm[0] = sig_norm[0] | sig_sum[0];
            exp_z = exp_z + 8'd1;
          end else begin
            sig_norm = sig_sum[26:0];
          end
        end else begin
          a_lt_b_mag =
              (exp_a_eff < exp_b_eff) ||
              ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
          if ((exp_a_eff == exp_b_eff) && (sig_a == sig_b)) begin
            sign_z = 1'b0;
            sig_norm = 27'b0;
          end else if (a_lt_b_mag) begin
            sign_z = sign_b;
            sig_norm = sig_b_aligned - sig_a_aligned;
          end else begin
            sign_z = sign_a;
            sig_norm = sig_a_aligned - sig_b_aligned;
          end
          if ((sig_norm != 27'b0) && (exp_z > 8'd1)) begin
            norm_lzc = fp_lzc_27(sig_norm);
            norm_exp_limit = exp_z - 8'd1;
            norm_shift = ({2'b0, norm_lzc} < norm_exp_limit) ?
                         norm_lzc : norm_exp_limit[5:0];
            sig_norm = sig_norm << norm_shift;
            exp_z = exp_z - {2'b0, norm_shift};
          end
        end

        if (sig_norm == 27'b0) begin
          // FP#4: 精确抵消零结果在 RDN 下为 -0(NaN-boxed)。
          fp_addsub_s_value = (rm == 3'b010) ? 64'hffffffff80000000
                                             : 64'hffffffff00000000;
        end else begin
          mant24 = sig_norm[26:3];
          guard = sig_norm[2];
          sticky = sig_norm[1] | sig_norm[0];
          inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
          mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
          if (mant_round_ext[24]) begin
            exp_z = exp_z + 8'd1;
            mant24 = mant_round_ext[24:1];
          end else begin
            mant24 = mant_round_ext[23:0];
          end

          if (exp_z >= 8'hff) begin
            fp_addsub_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
          end else if ((exp_z == 8'd1) && !mant24[23]) begin
            fp_addsub_s_value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
          end else begin
            fp_addsub_s_value = {32'hffff_ffff, sign_z, exp_z, mant24[22:0]};
          end
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_addsub_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input is_sub;
    input [2:0] rm;
    begin
      fp_addsub_value = is_double ?
          fp_addsub_d_value(rs1_value, rs2_value, is_sub, rm) :
          fp_addsub_s_value(rs1_value, rs2_value, is_sub, rm);
    end
  endfunction

  function [`XLEN-1:0] fp_mul_d_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    reg sign_z;
    reg [10:0] exp_a;
    reg [10:0] exp_b;
    reg [51:0] frac_a;
    reg [51:0] frac_b;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg [52:0] sig_a;
    reg [52:0] sig_b;
    reg [105:0] product;
    reg [105:0] product_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [7:0] sub_shift;
    reg [7:0] norm_lzc;
    reg [7:0] norm_required;
    reg [7:0] norm_shift;
    integer exp_z;
    integer sub_shift_int;
    begin
      sign_z = rs1_value[63] ^ rs2_value[63];
      exp_a = rs1_value[62:52];
      exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0];
      frac_b = rs2_value[51:0];
      a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
      b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
      a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
      b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
      a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
      b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);

      if (a_is_nan || b_is_nan) begin
        fp_mul_d_value = 64'h7ff8000000000000;
      end else if ((a_is_inf && b_is_zero) ||
                   (b_is_inf && a_is_zero)) begin
        fp_mul_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf || b_is_inf) begin
        fp_mul_d_value = {sign_z, 11'h7ff, 52'b0};
      end else if (a_is_zero || b_is_zero) begin
        fp_mul_d_value = {sign_z, 63'b0};
      end else begin
        sig_a = {(exp_a != 11'h000), frac_a};
        sig_b = {(exp_b != 11'h000), frac_b};
        exp_z = ((exp_a == 11'h000) ? 1 : exp_a) +
                ((exp_b == 11'h000) ? 1 : exp_b) - 1023;
        product = sig_a * sig_b;
        product_norm = product;

        if ((product_norm != 106'b0) && (exp_z > 1)) begin
          norm_lzc = fp_lzc_106(product_norm);
          norm_required = (norm_lzc > 8'd1) ? (norm_lzc - 8'd1) : 8'd0;
          norm_shift = (norm_required > (exp_z - 1)) ?
                       (exp_z - 1) : norm_required;
          product_norm = product_norm << norm_shift;
          exp_z = exp_z - norm_shift;
        end

        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 106)
            sub_shift = 8'd106;
          else
            sub_shift = sub_shift_int;
          product_norm = fp_shift_right_jam_106(product_norm, sub_shift);
          exp_z = 1;
        end

        if (product_norm[105]) begin
          mant53 = product_norm[105:53];
          guard = product_norm[52];
          sticky = |product_norm[51:0];
          exp_z = exp_z + 1;
        end else begin
          mant53 = product_norm[104:52];
          guard = product_norm[51];
          sticky = |product_norm[50:0];
        end

        inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53]) begin
          mant53 = mant_round_ext[53:1];
          exp_z = exp_z + 1;
        end else begin
          mant53 = mant_round_ext[52:0];
        end

        if (exp_z >= 2047) begin
          fp_mul_d_value = {sign_z, 11'h7ff, 52'b0};
        end else if ((exp_z <= 1) && !mant53[52]) begin
          fp_mul_d_value = {sign_z, 11'b0, mant53[51:0]};
        end else begin
          fp_mul_d_value = {sign_z, exp_z[10:0], mant53[51:0]};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_mul_s_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    reg [31:0] a;
    reg [31:0] b;
    reg sign_z;
    reg [7:0] exp_a;
    reg [7:0] exp_b;
    reg [22:0] frac_a;
    reg [22:0] frac_b;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg [23:0] sig_a;
    reg [23:0] sig_b;
    reg [47:0] product;
    reg [47:0] product_norm;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [5:0] sub_shift;
    reg [5:0] norm_lzc;
    reg [5:0] norm_required;
    reg [5:0] norm_shift;
    integer exp_z;
    integer sub_shift_int;
    begin
      a = rs1_value[31:0];
      b = rs2_value[31:0];
      sign_z = a[31] ^ b[31];
      exp_a = a[30:23];
      exp_b = b[30:23];
      frac_a = a[22:0];
      frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = (rs1_value[63:32] == 32'hffff_ffff) &&
                 (exp_a == 8'hff) && (frac_a == 23'b0);
      b_is_inf = (rs2_value[63:32] == 32'hffff_ffff) &&
                 (exp_b == 8'hff) && (frac_b == 23'b0);
      a_is_zero = (rs1_value[63:32] == 32'hffff_ffff) &&
                  (exp_a == 8'h00) && (frac_a == 23'b0);
      b_is_zero = (rs2_value[63:32] == 32'hffff_ffff) &&
                  (exp_b == 8'h00) && (frac_b == 23'b0);

      if (a_is_nan || b_is_nan) begin
        fp_mul_s_value = 64'hffffffff7fc00000;
      end else if ((a_is_inf && b_is_zero) ||
                   (b_is_inf && a_is_zero)) begin
        fp_mul_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf || b_is_inf) begin
        fp_mul_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
      end else if (a_is_zero || b_is_zero) begin
        fp_mul_s_value = {32'hffff_ffff, sign_z, 31'b0};
      end else begin
        sig_a = {(exp_a != 8'h00), frac_a};
        sig_b = {(exp_b != 8'h00), frac_b};
        exp_z = ((exp_a == 8'h00) ? 1 : exp_a) +
                ((exp_b == 8'h00) ? 1 : exp_b) - 127;
        product = sig_a * sig_b;
        product_norm = product;

        if ((product_norm != 48'b0) && (exp_z > 1)) begin
          norm_lzc = fp_lzc_48(product_norm);
          norm_required = (norm_lzc > 6'd1) ? (norm_lzc - 6'd1) : 6'd0;
          norm_shift = (norm_required > (exp_z - 1)) ?
                       (exp_z - 1) : norm_required;
          product_norm = product_norm << norm_shift;
          exp_z = exp_z - norm_shift;
        end

        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 48)
            sub_shift = 6'd48;
          else
            sub_shift = sub_shift_int;
          product_norm = fp_shift_right_jam_48(product_norm, sub_shift);
          exp_z = 1;
        end

        if (product_norm[47]) begin
          mant24 = product_norm[47:24];
          guard = product_norm[23];
          sticky = |product_norm[22:0];
          exp_z = exp_z + 1;
        end else begin
          mant24 = product_norm[46:23];
          guard = product_norm[22];
          sticky = |product_norm[21:0];
        end

        inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          mant24 = mant_round_ext[24:1];
          exp_z = exp_z + 1;
        end else begin
          mant24 = mant_round_ext[23:0];
        end

        if (exp_z >= 255) begin
          fp_mul_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
        end else if ((exp_z <= 1) && !mant24[23]) begin
          fp_mul_s_value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
        end else begin
          fp_mul_s_value = {32'hffff_ffff, sign_z, exp_z[7:0], mant24[22:0]};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_mul_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] rm;
    begin
      fp_mul_value = is_double ?
          fp_mul_d_value(rs1_value, rs2_value, rm) :
          fp_mul_s_value(rs1_value, rs2_value, rm);
    end
  endfunction

  function [`XLEN-1:0] fp_neg_value;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_neg_value = is_double ?
          (value ^ 64'h8000_0000_0000_0000) :
          (value ^ 64'h0000_0000_8000_0000);
    end
  endfunction

  function [`XLEN-1:0] fp_fma_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [`XLEN-1:0] rs3_value;
    input is_double;
    input negate_product;
    input subtract_addend;
    input [2:0] rm;
    reg [`XLEN-1:0] mul_value;
    reg [`XLEN-1:0] lhs_value;
    begin
      mul_value = fp_mul_value(rs1_value, rs2_value, is_double, rm);
      lhs_value = negate_product ? fp_neg_value(mul_value, is_double) :
                                  mul_value;
      fp_fma_value = fp_addsub_value(lhs_value, rs3_value, is_double,
                                     subtract_addend, rm);
    end
  endfunction

  function [4:0] fp_addsub_s_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_sub;
    input [2:0] rm;
    reg [31:0] a;
    reg [31:0] b;
    reg sign_a;
    reg sign_b;
    reg sign_z;
    reg [7:0] exp_a;
    reg [7:0] exp_b;
    reg [7:0] exp_a_eff;
    reg [7:0] exp_b_eff;
    reg [7:0] exp_z;
    reg [22:0] frac_a;
    reg [22:0] frac_b;
    reg [26:0] sig_a;
    reg [26:0] sig_b;
    reg [26:0] sig_a_aligned;
    reg [26:0] sig_b_aligned;
    reg [26:0] sig_norm;
    reg [27:0] sig_sum;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg [7:0] exp_diff;
    reg [5:0] shift_dist;
    reg guard;
    reg sticky;
    reg inc;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg a_lt_b_mag;
    reg [5:0] norm_lzc;
    reg [5:0] norm_shift;
    reg [7:0] norm_exp_limit;
    begin
      a = rs1_value[31:0];
      b = rs2_value[31:0];
      sign_a = a[31];
      sign_b = b[31] ^ is_sub;
      exp_a = a[30:23];
      exp_b = b[30:23];
      frac_a = a[22:0];
      frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = fp_is_inf_s_value(rs1_value);
      b_is_inf = fp_is_inf_s_value(rs2_value);
      a_is_zero = fp_is_zero_s_value(rs1_value);
      b_is_zero = fp_is_zero_s_value(rs2_value);
      fp_addsub_s_fflags = 5'b00000;

      if (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
          (a_is_inf && b_is_inf && (sign_a != sign_b))) begin
        fp_addsub_s_fflags = `FP_FLAG_NV;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        exp_a_eff = (exp_a == 8'h00) ? 8'd1 : exp_a;
        exp_b_eff = (exp_b == 8'h00) ? 8'd1 : exp_b;
        sig_a = {(exp_a != 8'h00), frac_a, 3'b000};
        sig_b = {(exp_b != 8'h00), frac_b, 3'b000};
        if (exp_a_eff >= exp_b_eff) begin
          exp_z = exp_a_eff;
          sig_a_aligned = sig_a;
          exp_diff = exp_a_eff - exp_b_eff;
          shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
          sig_b_aligned = fp_shift_right_jam_27(sig_b, shift_dist);
        end else begin
          exp_z = exp_b_eff;
          exp_diff = exp_b_eff - exp_a_eff;
          shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
          sig_a_aligned = fp_shift_right_jam_27(sig_a, shift_dist);
          sig_b_aligned = sig_b;
        end
        if (sign_a == sign_b) begin
          sign_z = sign_a;
          sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
          if (sig_sum[27]) begin
            sig_norm = sig_sum[27:1];
            sig_norm[0] = sig_norm[0] | sig_sum[0];
            exp_z = exp_z + 8'd1;
          end else begin
            sig_norm = sig_sum[26:0];
          end
        end else begin
          a_lt_b_mag =
              (exp_a_eff < exp_b_eff) ||
              ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
          if ((exp_a_eff == exp_b_eff) && (sig_a == sig_b)) begin
            sign_z = 1'b0;
            sig_norm = 27'b0;
          end else if (a_lt_b_mag) begin
            sign_z = sign_b;
            sig_norm = sig_b_aligned - sig_a_aligned;
          end else begin
            sign_z = sign_a;
            sig_norm = sig_a_aligned - sig_b_aligned;
          end
          if ((sig_norm != 27'b0) && (exp_z > 8'd1)) begin
            norm_lzc = fp_lzc_27(sig_norm);
            norm_exp_limit = exp_z - 8'd1;
            norm_shift = ({2'b0, norm_lzc} < norm_exp_limit) ?
                         norm_lzc : norm_exp_limit[5:0];
            sig_norm = sig_norm << norm_shift;
            exp_z = exp_z - {2'b0, norm_shift};
          end
        end
        if (sig_norm != 27'b0) begin
          mant24 = sig_norm[26:3];
          guard = sig_norm[2];
          sticky = sig_norm[1] | sig_norm[0];
          inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
          mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
          if (mant_round_ext[24]) begin
            exp_z = exp_z + 8'd1;
            mant24 = mant_round_ext[24:1];
          end else begin
            mant24 = mant_round_ext[23:0];
          end
          fp_addsub_s_fflags = fp_round_flags_s(sign_z, exp_z, mant24,
                                                guard, sticky);
        end
      end
    end
  endfunction

  function [4:0] fp_addsub_d_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_sub;
    input [2:0] rm;
    reg sign_a;
    reg sign_b;
    reg sign_z;
    reg [10:0] exp_a;
    reg [10:0] exp_b;
    reg [10:0] exp_a_eff;
    reg [10:0] exp_b_eff;
    reg [10:0] exp_z;
    reg [51:0] frac_a;
    reg [51:0] frac_b;
    reg [55:0] sig_a;
    reg [55:0] sig_b;
    reg [55:0] sig_a_aligned;
    reg [55:0] sig_b_aligned;
    reg [55:0] sig_norm;
    reg [56:0] sig_sum;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg [10:0] exp_diff;
    reg [6:0] shift_dist;
    reg guard;
    reg sticky;
    reg inc;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg a_lt_b_mag;
    reg [6:0] norm_lzc;
    reg [6:0] norm_shift;
    reg [10:0] norm_exp_limit;
    begin
      sign_a = rs1_value[63];
      sign_b = rs2_value[63] ^ is_sub;
      exp_a = rs1_value[62:52];
      exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0];
      frac_b = rs2_value[51:0];
      a_is_nan = fp_is_nan_d_value(rs1_value);
      b_is_nan = fp_is_nan_d_value(rs2_value);
      a_is_inf = fp_is_inf_d_value(rs1_value);
      b_is_inf = fp_is_inf_d_value(rs2_value);
      a_is_zero = fp_is_zero_d_value(rs1_value);
      b_is_zero = fp_is_zero_d_value(rs2_value);
      fp_addsub_d_fflags = 5'b00000;

      if (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
          (a_is_inf && b_is_inf && (sign_a != sign_b))) begin
        fp_addsub_d_fflags = `FP_FLAG_NV;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        exp_a_eff = (exp_a == 11'h000) ? 11'd1 : exp_a;
        exp_b_eff = (exp_b == 11'h000) ? 11'd1 : exp_b;
        sig_a = {(exp_a != 11'h000), frac_a, 3'b000};
        sig_b = {(exp_b != 11'h000), frac_b, 3'b000};
        if (exp_a_eff >= exp_b_eff) begin
          exp_z = exp_a_eff;
          sig_a_aligned = sig_a;
          exp_diff = exp_a_eff - exp_b_eff;
          shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
          sig_b_aligned = fp_shift_right_jam_56(sig_b, shift_dist);
        end else begin
          exp_z = exp_b_eff;
          exp_diff = exp_b_eff - exp_a_eff;
          shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
          sig_a_aligned = fp_shift_right_jam_56(sig_a, shift_dist);
          sig_b_aligned = sig_b;
        end
        if (sign_a == sign_b) begin
          sign_z = sign_a;
          sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
          if (sig_sum[56]) begin
            sig_norm = sig_sum[56:1];
            sig_norm[0] = sig_norm[0] | sig_sum[0];
            exp_z = exp_z + 11'd1;
          end else begin
            sig_norm = sig_sum[55:0];
          end
        end else begin
          a_lt_b_mag =
              (exp_a_eff < exp_b_eff) ||
              ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
          if ((exp_a_eff == exp_b_eff) && (sig_a == sig_b)) begin
            sign_z = 1'b0;
            sig_norm = 56'b0;
          end else if (a_lt_b_mag) begin
            sign_z = sign_b;
            sig_norm = sig_b_aligned - sig_a_aligned;
          end else begin
            sign_z = sign_a;
            sig_norm = sig_a_aligned - sig_b_aligned;
          end
          if ((sig_norm != 56'b0) && (exp_z > 11'd1)) begin
            norm_lzc = fp_lzc_56(sig_norm);
            norm_exp_limit = exp_z - 11'd1;
            norm_shift = ({4'b0, norm_lzc} < norm_exp_limit) ?
                         norm_lzc : norm_exp_limit[6:0];
            sig_norm = sig_norm << norm_shift;
            exp_z = exp_z - {4'b0, norm_shift};
          end
        end
        if (sig_norm != 56'b0) begin
          mant53 = sig_norm[55:3];
          guard = sig_norm[2];
          sticky = sig_norm[1] | sig_norm[0];
          inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
          mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
          if (mant_round_ext[53]) begin
            exp_z = exp_z + 11'd1;
            mant53 = mant_round_ext[53:1];
          end else begin
            mant53 = mant_round_ext[52:0];
          end
          fp_addsub_d_fflags = fp_round_flags_d(sign_z, exp_z, mant53,
                                                guard, sticky);
        end
      end
    end
  endfunction

  function [4:0] fp_mul_s_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    reg [31:0] a;
    reg [31:0] b;
    reg sign_z;
    reg [7:0] exp_a;
    reg [7:0] exp_b;
    reg [22:0] frac_a;
    reg [22:0] frac_b;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg [23:0] sig_a;
    reg [23:0] sig_b;
    reg [47:0] product;
    reg [47:0] product_norm;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [5:0] sub_shift;
    reg [5:0] norm_lzc;
    reg [5:0] norm_required;
    reg [5:0] norm_shift;
    integer exp_z;
    integer sub_shift_int;
    begin
      a = rs1_value[31:0];
      b = rs2_value[31:0];
      sign_z = a[31] ^ b[31];
      exp_a = a[30:23];
      exp_b = b[30:23];
      frac_a = a[22:0];
      frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = fp_is_inf_s_value(rs1_value);
      b_is_inf = fp_is_inf_s_value(rs2_value);
      a_is_zero = fp_is_zero_s_value(rs1_value);
      b_is_zero = fp_is_zero_s_value(rs2_value);
      fp_mul_s_fflags = 5'b00000;

      if (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
          (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        fp_mul_s_fflags = `FP_FLAG_NV;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        sig_a = {(exp_a != 8'h00), frac_a};
        sig_b = {(exp_b != 8'h00), frac_b};
        exp_z = ((exp_a == 8'h00) ? 1 : exp_a) +
                ((exp_b == 8'h00) ? 1 : exp_b) - 127;
        product = sig_a * sig_b;
        product_norm = product;
        if ((product_norm != 48'b0) && (exp_z > 1)) begin
          norm_lzc = fp_lzc_48(product_norm);
          norm_required = (norm_lzc > 6'd1) ? (norm_lzc - 6'd1) : 6'd0;
          norm_shift = (norm_required > (exp_z - 1)) ?
                       (exp_z - 1) : norm_required;
          product_norm = product_norm << norm_shift;
          exp_z = exp_z - norm_shift;
        end
        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 48)
            sub_shift = 6'd48;
          else
            sub_shift = sub_shift_int;
          product_norm = fp_shift_right_jam_48(product_norm, sub_shift);
          exp_z = 1;
        end
        if (product_norm[47]) begin
          mant24 = product_norm[47:24];
          guard = product_norm[23];
          sticky = |product_norm[22:0];
          exp_z = exp_z + 1;
        end else begin
          mant24 = product_norm[46:23];
          guard = product_norm[22];
          sticky = |product_norm[21:0];
        end
        inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          mant24 = mant_round_ext[24:1];
          exp_z = exp_z + 1;
        end else begin
          mant24 = mant_round_ext[23:0];
        end
        fp_mul_s_fflags = fp_round_flags_s(sign_z, exp_z[7:0], mant24,
                                           guard, sticky);
        if (exp_z >= 255)
          fp_mul_s_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
    end
  endfunction

  function [4:0] fp_mul_d_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    reg sign_z;
    reg [10:0] exp_a;
    reg [10:0] exp_b;
    reg [51:0] frac_a;
    reg [51:0] frac_b;
    reg a_is_nan;
    reg b_is_nan;
    reg a_is_inf;
    reg b_is_inf;
    reg a_is_zero;
    reg b_is_zero;
    reg [52:0] sig_a;
    reg [52:0] sig_b;
    reg [105:0] product;
    reg [105:0] product_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [7:0] sub_shift;
    reg [7:0] norm_lzc;
    reg [7:0] norm_required;
    reg [7:0] norm_shift;
    integer exp_z;
    integer sub_shift_int;
    begin
      sign_z = rs1_value[63] ^ rs2_value[63];
      exp_a = rs1_value[62:52];
      exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0];
      frac_b = rs2_value[51:0];
      a_is_nan = fp_is_nan_d_value(rs1_value);
      b_is_nan = fp_is_nan_d_value(rs2_value);
      a_is_inf = fp_is_inf_d_value(rs1_value);
      b_is_inf = fp_is_inf_d_value(rs2_value);
      a_is_zero = fp_is_zero_d_value(rs1_value);
      b_is_zero = fp_is_zero_d_value(rs2_value);
      fp_mul_d_fflags = 5'b00000;

      if (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
          (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        fp_mul_d_fflags = `FP_FLAG_NV;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        sig_a = {(exp_a != 11'h000), frac_a};
        sig_b = {(exp_b != 11'h000), frac_b};
        exp_z = ((exp_a == 11'h000) ? 1 : exp_a) +
                ((exp_b == 11'h000) ? 1 : exp_b) - 1023;
        product = sig_a * sig_b;
        product_norm = product;
        if ((product_norm != 106'b0) && (exp_z > 1)) begin
          norm_lzc = fp_lzc_106(product_norm);
          norm_required = (norm_lzc > 8'd1) ? (norm_lzc - 8'd1) : 8'd0;
          norm_shift = (norm_required > (exp_z - 1)) ?
                       (exp_z - 1) : norm_required;
          product_norm = product_norm << norm_shift;
          exp_z = exp_z - norm_shift;
        end
        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 106)
            sub_shift = 8'd106;
          else
            sub_shift = sub_shift_int;
          product_norm = fp_shift_right_jam_106(product_norm, sub_shift);
          exp_z = 1;
        end
        if (product_norm[105]) begin
          mant53 = product_norm[105:53];
          guard = product_norm[52];
          sticky = |product_norm[51:0];
          exp_z = exp_z + 1;
        end else begin
          mant53 = product_norm[104:52];
          guard = product_norm[51];
          sticky = |product_norm[50:0];
        end
        inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53]) begin
          mant53 = mant_round_ext[53:1];
          exp_z = exp_z + 1;
        end else begin
          mant53 = mant_round_ext[52:0];
        end
        fp_mul_d_fflags = fp_round_flags_d(sign_z, exp_z[10:0], mant53,
                                           guard, sticky);
        if (exp_z >= 2047)
          fp_mul_d_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
    end
  endfunction

  // FADD/FSUB
  assign addsub_value_o = fp_addsub_value(frs1_value_i, frs2_value_i, double_i, sub_op_i, rm_i);
  assign addsub_fflags_o = double_i ?
      fp_addsub_d_fflags(frs1_value_i, frs2_value_i, sub_op_i, rm_i) :
      fp_addsub_s_fflags(frs1_value_i, frs2_value_i, sub_op_i, rm_i);

  // FMUL
  wire [`XLEN-1:0] mul_value_w = fp_mul_value(frs1_value_i, frs2_value_i, double_i, rm_i);
  assign mul_value_o = mul_value_w;
  assign mul_fflags_o = double_i ?
      fp_mul_d_fflags(frs1_value_i, frs2_value_i, rm_i) :
      fp_mul_s_fflags(frs1_value_i, frs2_value_i, rm_i);

  // FMADD 系列：value 由 fp_fma_value 整体计算；fflags 由 mul 与 addsub(product,frs3) 合并
  assign fma_value_o = fp_fma_value(frs1_value_i, frs2_value_i, frs3_value_i,
                                    double_i, negate_product_i, subtract_addend_i, rm_i);
  wire [`XLEN-1:0] fma_lhs_w =
      negate_product_i ? fp_neg_value(mul_value_w, double_i) : mul_value_w;
  assign fma_fflags_o = double_i ?
      (fp_mul_d_fflags(frs1_value_i, frs2_value_i, rm_i) |
       fp_addsub_d_fflags(fma_lhs_w, frs3_value_i, subtract_addend_i, rm_i)) :
      (fp_mul_s_fflags(frs1_value_i, frs2_value_i, rm_i) |
       fp_addsub_s_fflags(fma_lhs_w, frs3_value_i, subtract_addend_i, rm_i));

endmodule
