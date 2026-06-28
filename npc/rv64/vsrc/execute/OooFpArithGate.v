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

  // 纯组合 datapath 结果(由各 always @(*) 块驱动,输出处按 double_i mux)。
  // 注:可综合 .v 用 always @(*),不用 SV always_comb(iverilog 模块 TB 对 always_comb
  // 常量位选静默错仿真,见 .github/instructions/rtl-generation-workflow.instructions.md)。
  reg [`XLEN-1:0] addsub_d_value, addsub_s_value, mul_d_value, mul_s_value;
  reg [4:0] addsub_d_fflags, addsub_s_fflags, mul_d_fflags, mul_s_fflags;

  always @(*) begin : addsub_d_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_sub;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    is_sub = sub_op_i;
    rm = rm_i;
    sign_z = 1'b0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0; sig_norm = 0;
    sig_sum = 0; mant53 = 0; mant_round_ext = 0; exp_diff = 0; shift_dist = 0;
    guard = 0; sticky = 0; inc = 0; a_lt_b_mag = 0; norm_lzc = 0; norm_shift = 0;
    norm_exp_limit = 0; addsub_d_value = 0;
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
        addsub_d_value =64'h7ff8000000000000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        addsub_d_value =64'h7ff8000000000000;
      end else if (a_is_inf) begin
        addsub_d_value ={sign_a, 11'h7ff, 52'b0};
      end else if (b_is_inf) begin
        addsub_d_value ={sign_b, 11'h7ff, 52'b0};
      end else if (a_is_zero && b_is_zero) begin
        // FP#4: (+0)+(-0) 等异号零和在 RDN(rm=010)下为 -0,其余模式 +0。
        addsub_d_value =
            {((rm == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 63'b0};
      end else if (a_is_zero) begin
        addsub_d_value ={sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        addsub_d_value =rs1_value;
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
          addsub_d_value =(rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
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
            addsub_d_value =fp_overflow_d(sign_z, rm);
          end else if ((exp_z == 11'd1) && !mant53[52]) begin
            addsub_d_value ={sign_z, 11'b0, mant53[51:0]};
          end else begin
            addsub_d_value ={sign_z, exp_z, mant53[51:0]};
          end
        end
      end
  end

  always @(*) begin : addsub_s_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_sub;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    is_sub = sub_op_i;
    rm = rm_i;
    sign_z = 1'b0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0; sig_norm = 0;
    sig_sum = 0; mant24 = 0; mant_round_ext = 0; exp_diff = 0; shift_dist = 0;
    guard = 0; sticky = 0; inc = 0; a_lt_b_mag = 0; norm_lzc = 0; norm_shift = 0;
    norm_exp_limit = 0; a = 0; b = 0; addsub_s_value = 0;
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
        addsub_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        addsub_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf) begin
        addsub_s_value = {32'hffff_ffff, sign_a, 8'hff, 23'b0};
      end else if (b_is_inf) begin
        addsub_s_value = {32'hffff_ffff, sign_b, 8'hff, 23'b0};
      end else if (a_is_zero && b_is_zero) begin
        // FP#4: 异号零和在 RDN 下为 -0(NaN-boxed)。
        addsub_s_value =
            {32'hffff_ffff, ((rm == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 31'b0};
      end else if (a_is_zero) begin
        addsub_s_value = {32'hffff_ffff, sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        addsub_s_value = {32'hffff_ffff, a};
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
          addsub_s_value = (rm == 3'b010) ? 64'hffffffff80000000
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
            addsub_s_value = fp_overflow_s(sign_z, rm);
          end else if ((exp_z == 8'd1) && !mant24[23]) begin
            addsub_s_value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
          end else begin
            addsub_s_value = {32'hffff_ffff, sign_z, exp_z, mant24[22:0]};
          end
        end
      end
  end

  always @(*) begin : mul_d_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rm = rm_i;
    sig_a = 0; sig_b = 0; product = 0; product_norm = 0; mant53 = 0;
    mant_round_ext = 0; guard = 0; sticky = 0; inc = 0; sub_shift = 0;
    norm_lzc = 0; norm_required = 0; norm_shift = 0; exp_z = 0; sub_shift_int = 0;
    mul_d_value = 0;
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
        mul_d_value = 64'h7ff8000000000000;
      end else if ((a_is_inf && b_is_zero) ||
                   (b_is_inf && a_is_zero)) begin
        mul_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf || b_is_inf) begin
        mul_d_value = {sign_z, 11'h7ff, 52'b0};
      end else if (a_is_zero || b_is_zero) begin
        mul_d_value = {sign_z, 63'b0};
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
          mul_d_value = fp_overflow_d(sign_z, rm);
        end else if ((exp_z <= 1) && !mant53[52]) begin
          mul_d_value = {sign_z, 11'b0, mant53[51:0]};
        end else begin
          mul_d_value = {sign_z, exp_z[10:0], mant53[51:0]};
        end
      end
  end

  always @(*) begin : mul_s_value_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rm = rm_i;
    sig_a = 0; sig_b = 0; product = 0; product_norm = 0; mant24 = 0;
    mant_round_ext = 0; guard = 0; sticky = 0; inc = 0; sub_shift = 0;
    norm_lzc = 0; norm_required = 0; norm_shift = 0; exp_z = 0; sub_shift_int = 0;
    mul_s_value = 0;
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
        mul_s_value = 64'hffffffff7fc00000;
      end else if ((a_is_inf && b_is_zero) ||
                   (b_is_inf && a_is_zero)) begin
        mul_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf || b_is_inf) begin
        mul_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
      end else if (a_is_zero || b_is_zero) begin
        mul_s_value = {32'hffff_ffff, sign_z, 31'b0};
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
          mul_s_value = fp_overflow_s(sign_z, rm);
        end else if ((exp_z <= 1) && !mant24[23]) begin
          mul_s_value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
        end else begin
          mul_s_value = {32'hffff_ffff, sign_z, exp_z[7:0], mant24[22:0]};
        end
      end
  end


  always @(*) begin : addsub_s_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_sub;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    is_sub = sub_op_i;
    rm = rm_i;
    sign_z = 0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0; sig_norm = 0;
    sig_sum = 0; mant24 = 0; mant_round_ext = 0; exp_diff = 0; shift_dist = 0;
    guard = 0; sticky = 0; inc = 0; a_lt_b_mag = 0; norm_lzc = 0; norm_shift = 0;
    norm_exp_limit = 0; a = 0; b = 0;
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
      addsub_s_fflags = 5'b00000;

      if (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
          (a_is_inf && b_is_inf && (sign_a != sign_b))) begin
        addsub_s_fflags = `FP_FLAG_NV;
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
          addsub_s_fflags = fp_round_flags_s(sign_z, exp_z, mant24,
                                                guard, sticky);
        end
      end
  end

  always @(*) begin : addsub_d_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg is_sub;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    is_sub = sub_op_i;
    rm = rm_i;
    sign_z = 0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0; sig_norm = 0;
    sig_sum = 0; mant53 = 0; mant_round_ext = 0; exp_diff = 0; shift_dist = 0;
    guard = 0; sticky = 0; inc = 0; a_lt_b_mag = 0; norm_lzc = 0; norm_shift = 0;
    norm_exp_limit = 0;
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
      addsub_d_fflags = 5'b00000;

      if (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
          (a_is_inf && b_is_inf && (sign_a != sign_b))) begin
        addsub_d_fflags = `FP_FLAG_NV;
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
          addsub_d_fflags = fp_round_flags_d(sign_z, exp_z, mant53,
                                                guard, sticky);
        end
      end
  end

  always @(*) begin : mul_s_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rm = rm_i;
    sig_a = 0; sig_b = 0; product = 0; product_norm = 0; mant24 = 0;
    mant_round_ext = 0; guard = 0; sticky = 0; inc = 0; sub_shift = 0;
    norm_lzc = 0; norm_required = 0; norm_shift = 0; exp_z = 0; sub_shift_int = 0;
    a = 0; b = 0;
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
      mul_s_fflags = 5'b00000;

      if (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
          (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        mul_s_fflags = `FP_FLAG_NV;
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
        mul_s_fflags = fp_round_flags_s(sign_z, exp_z[7:0], mant24,
                                           guard, sticky);
        if (exp_z >= 255)
          mul_s_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
  end

  always @(*) begin : mul_d_fflags_blk
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [2:0] rm;
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
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rm = rm_i;
    sig_a = 0; sig_b = 0; product = 0; product_norm = 0; mant53 = 0;
    mant_round_ext = 0; guard = 0; sticky = 0; inc = 0; sub_shift = 0;
    norm_lzc = 0; norm_required = 0; norm_shift = 0; exp_z = 0; sub_shift_int = 0;
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
      mul_d_fflags = 5'b00000;

      if (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
          (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        mul_d_fflags = `FP_FLAG_NV;
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
        mul_d_fflags = fp_round_flags_d(sign_z, exp_z[10:0], mant53,
                                           guard, sticky);
        if (exp_z >= 2047)
          mul_d_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
  end

  // ===========================================================================
  // FP#2 修复:fused multiply-add(单次舍入,IEEE-754 正确)——按硬件结构描述。
  //
  // 【硬件结构说明(本组合数据通路)】
  // - 寄存器:无。本块是纯组合 FMA 数据通路 gate;结果 fma_value_o/fma_fflags_o
  //   由父模块 OooFpPendingExec 的 FP 结果流水寄存器在下游打拍。
  // - 控制 FSM:无(单拍组合,无 valid/ready/flush 状态)。
  // - 组合 datapath(关键路径大致顺序,也是 FMA 之所以是最长 FP 组合路径的原因):
  //     特殊值译码 → 53×53 尾数乘法器(宽积 106/48b)→ addend 对齐 barrel shifter
  //     → 128b 宽加/减(进位链)→ 128b LZC 前导零优先编码器 → 规格化 barrel shifter
  //     → 末级舍入进位加法器 → 组装。
  // - 共享资源 mux:double/single 两条数据通路各算 {fflags,value},由 double_i 在
  //   输出处显式 mux(见文件末 assign fma_value_o/fma_fflags_o)。
  // - for-loop:无;所用 barrel shifter(fp_shift_right_jam_128)与优先编码器
  //   (fp_lzc_128)是展开的 log 级 mux 树纯组合 helper(综合成移位/编码网络)。
  //
  // 【实现形态说明 — 用 always@* 显式组合块,不用 always_comb 关键字,不藏进大 function】
  //   按规范:纯组合 datapath 用显式 always 块描述,使硬件结构可见;function 仅留给
  //   小型纯组合原语(lzc/barrel-shift/round/saturate/predicate)。
  //   关键工具链约束:本仓库"模块 testbench" gate 用 Icarus iverilog 12.0,实测其对
  //   **`always_comb` 关键字**内的变量常量位选会发 "sorry: constant selects in always_*
  //   ... all bits will be included"(静默错仿真),而 **`always @(*)` 与
  //   `always @(posedge clk)`** 对同样的常量位选完全正确。故本仓库可综合 .v 统一用
  //   `always @(*)`/`always @(posedge clk)`(Verilog-2001 写法,Vivado read_verilog -sv
  //   亦兼容),不用 SV 的 always_comb/always_ff 关键字(后者仅限 .sv 验证代码)。
  //   详见 .github/instructions/rtl-generation-workflow.instructions.md。
  //
  // 算法:精确宽积(106/48-bit)与 addend 在 128-bit 定点场内 anchor-at-larger 对齐
  //   (较小操作数 shift-right-jam 入粘滞),宽加/减 + 单次规格化 + 单次舍入。
  //   场:bit b 权重 = ref - 126 + b(较大操作数 MSB 置于 bit 126,bit 127 留进位)。
  //   E_biased = ref + 1024 - lzc(double) / ref + 128 - lzc(single)。
  //   c=0 折叠进主通路(sig_c=0 → addend_field=0 → 结果=round(a*b));product=0
  //   单列(其 ep 伪权重会污染 ref,不可折叠)。已用算例 1.5*1.0+1.0→2.5 + rv64uf/ud
  //   fmadd 金标 + 4000 迭代 difftest 对 NEMU fused softfloat 全匹配 验证。
  // 返回 {fflags[4:0], value[63:0]} 打包,避免 value/fflags 两份逻辑分歧。
  // ===========================================================================
  reg [63:0] fma_d_value, fma_s_value;     // 共享输出前的 per-precision 组合结果
  reg [4:0]  fma_d_fflags, fma_s_fflags;

  // ---- 双精度 fused FMA 纯组合 datapath(显式 always@* 组合块;命名块内局部变量)----
  always @(*) begin : fma_double_datapath
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [`XLEN-1:0] rs3_value;
    reg negate_product;
    reg subtract_addend;
    reg [2:0] rm;
    reg sign_a, sign_b, sign_c, sign_p, res_sign;
    reg [10:0] exp_a, exp_b, exp_c;
    reg [51:0] frac_a, frac_b, frac_c;
    reg [52:0] sig_a, sig_b, sig_c;
    reg [105:0] product;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    reg [4:0] fflags;
    reg [63:0] value;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    integer ep, ec, pw, cw, ref_w, shift_p, shift_c, e_biased, sub_shift, negsh;
    reg [7:0] lzc_p, lzc_m;
    reg [5:0] lzc_c53;
    reg [127:0] prod_field, addend_field, mag, magn;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard, sticky, inc;
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    rm = rm_i;
    // always@* 组合:中间临时量先给默认值,避免锁存器推断。
    res_sign = 1'b0;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0; product = 0;
    ep = 0; ec = 0; pw = 0; cw = 0; ref_w = 0; shift_p = 0; shift_c = 0;
    e_biased = 0; sub_shift = 0; negsh = 0;
    lzc_p = 0; lzc_m = 0; lzc_c53 = 0;
    prod_field = 0; addend_field = 0; mag = 0; magn = 0;
    mant53 = 0; mant_round_ext = 0; guard = 1'b0; sticky = 1'b0; inc = 1'b0;
    value = 64'b0;
      sign_a = rs1_value[63];
      sign_b = rs2_value[63];
      sign_c = rs3_value[63] ^ subtract_addend;
      sign_p = sign_a ^ sign_b ^ negate_product;
      exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52]; exp_c = rs3_value[62:52];
      frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0]; frac_c = rs3_value[51:0];
      a_is_nan = fp_is_nan_d_value(rs1_value);
      b_is_nan = fp_is_nan_d_value(rs2_value);
      c_is_nan = fp_is_nan_d_value(rs3_value);
      a_is_inf = fp_is_inf_d_value(rs1_value);
      b_is_inf = fp_is_inf_d_value(rs2_value);
      c_is_inf = fp_is_inf_d_value(rs3_value);
      a_is_zero = fp_is_zero_d_value(rs1_value);
      b_is_zero = fp_is_zero_d_value(rs2_value);
      c_is_zero = fp_is_zero_d_value(rs3_value);
      prod_is_inf = a_is_inf || b_is_inf;
      prod_is_zero = a_is_zero || b_is_zero;
      invalid_mul0inf = (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero);
      invalid_infsub = prod_is_inf && c_is_inf && (sign_c != sign_p);
      result_is_nan = a_is_nan || b_is_nan || c_is_nan ||
                      invalid_mul0inf || invalid_infsub;
      nv = fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
           fp_is_snan_d_value(rs3_value) || invalid_mul0inf || invalid_infsub;

      fflags = 5'b00000;
      if (result_is_nan) begin
        value = 64'h7ff8000000000000;
        fflags = nv ? `FP_FLAG_NV : 5'b00000;
      end else if (prod_is_inf) begin
        value = {sign_p, 11'h7ff, 52'b0};
      end else if (c_is_inf) begin
        value = {sign_c, 11'h7ff, 52'b0};
      end else if (prod_is_zero && c_is_zero) begin
        res_sign = (sign_p == sign_c) ? sign_p : (rm == 3'b010);
        value = {res_sign, 63'b0};
      end else if (prod_is_zero) begin
        value = {sign_c, exp_c, frac_c};
      end else begin
        // c=0 折叠至此:sig_c=0 → addend_field=0 → 结果=round(a*b)(单舍入)。
        exp_a_eff = (exp_a == 11'h000) ? 1 : exp_a;
        exp_b_eff = (exp_b == 11'h000) ? 1 : exp_b;
        exp_c_eff = (exp_c == 11'h000) ? 1 : exp_c;
        sig_a = {(exp_a != 11'h000), frac_a};
        sig_b = {(exp_b != 11'h000), frac_b};
        sig_c = {(exp_c != 11'h000), frac_c};
        product = sig_a * sig_b;
        ep = exp_a_eff + exp_b_eff - 2150;
        ec = exp_c_eff - 1075;
        lzc_p = fp_lzc_106(product);
        lzc_c53 = fp_norm_shift_53(sig_c);
        pw = ep + 105 - lzc_p;
        cw = ec + 52 - lzc_c53;
        ref_w = (pw >= cw) ? pw : cw;
        shift_p = ep - ref_w + 126;
        shift_c = ec - ref_w + 126;
        if (shift_p >= 0) begin
          prod_field = {22'b0, product} << shift_p;
        end else begin
          negsh = (-shift_p > 128) ? 128 : -shift_p;
          prod_field = fp_shift_right_jam_128({22'b0, product}, negsh[7:0]);
        end
        if (shift_c >= 0) begin
          addend_field = {75'b0, sig_c} << shift_c;
        end else begin
          negsh = (-shift_c > 128) ? 128 : -shift_c;
          addend_field = fp_shift_right_jam_128({75'b0, sig_c}, negsh[7:0]);
        end
        if (sign_p == sign_c) begin
          mag = prod_field + addend_field;
          res_sign = sign_p;
        end else if (prod_field >= addend_field) begin
          mag = prod_field - addend_field;
          res_sign = sign_p;
        end else begin
          mag = addend_field - prod_field;
          res_sign = sign_c;
        end
        if (mag == 128'b0) begin
          value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
        end else begin
          lzc_m = fp_lzc_128(mag);
          magn = mag << lzc_m;
          e_biased = ref_w + 1024 - lzc_m;
          if (e_biased < 1) begin
            sub_shift = 1 - e_biased;
            negsh = (sub_shift > 128) ? 128 : sub_shift;
            magn = fp_shift_right_jam_128(magn, negsh[7:0]);
            e_biased = 1;
          end
          mant53 = magn[127:75];
          guard = magn[74];
          sticky = |magn[73:0];
          inc = fp_round_increment(res_sign, rm, mant53[0], guard, sticky);
          mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
          if (mant_round_ext[53]) begin
            e_biased = e_biased + 1;
            mant53 = mant_round_ext[53:1];
          end else begin
            mant53 = mant_round_ext[52:0];
          end
          fflags = fp_round_flags_d(res_sign, e_biased[10:0], mant53,
                                    guard, sticky);
          if (e_biased >= 2047) begin
            value = fp_overflow_d(res_sign, rm);
            fflags = `FP_FLAG_OF | `FP_FLAG_NX;
          end else if ((e_biased <= 1) && !mant53[52]) begin
            value = {res_sign, 11'b0, mant53[51:0]};
          end else begin
            value = {res_sign, e_biased[10:0], mant53[51:0]};
          end
        end
      end
      fma_d_value = value;
      fma_d_fflags = fflags;
    end

  // ---- 单精度 fused FMA 纯组合 datapath(显式 always@*;场宽/偏置/slice 按 single)----
  always @(*) begin : fma_single_datapath
    reg [`XLEN-1:0] rs1_value;
    reg [`XLEN-1:0] rs2_value;
    reg [`XLEN-1:0] rs3_value;
    reg negate_product;
    reg subtract_addend;
    reg [2:0] rm;
    reg [31:0] a, b, c;
    reg sign_a, sign_b, sign_c, sign_p, res_sign;
    reg [7:0] exp_a, exp_b, exp_c;
    reg [22:0] frac_a, frac_b, frac_c;
    reg [23:0] sig_a, sig_b, sig_c;
    reg [47:0] product;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    reg [4:0] fflags;
    reg [63:0] value;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    integer ep, ec, pw, cw, ref_w, shift_p, shift_c, e_biased, sub_shift, negsh;
    reg [5:0] lzc_p;
    reg [7:0] lzc_m;
    reg [4:0] lzc_c24;
    reg [127:0] prod_field, addend_field, mag, magn;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard, sticky, inc;
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    rm = rm_i;
    res_sign = 1'b0;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0; product = 0;
    ep = 0; ec = 0; pw = 0; cw = 0; ref_w = 0; shift_p = 0; shift_c = 0;
    e_biased = 0; sub_shift = 0; negsh = 0;
    lzc_p = 0; lzc_m = 0; lzc_c24 = 0;
    prod_field = 0; addend_field = 0; mag = 0; magn = 0;
    mant24 = 0; mant_round_ext = 0; guard = 1'b0; sticky = 1'b0; inc = 1'b0;
    value = 64'b0;
      a = rs1_value[31:0]; b = rs2_value[31:0]; c = rs3_value[31:0];
      sign_a = a[31];
      sign_b = b[31];
      sign_c = c[31] ^ subtract_addend;
      sign_p = sign_a ^ sign_b ^ negate_product;
      exp_a = a[30:23]; exp_b = b[30:23]; exp_c = c[30:23];
      frac_a = a[22:0]; frac_b = b[22:0]; frac_c = c[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      c_is_nan = fp_is_nan_s_value(rs3_value);
      a_is_inf = fp_is_inf_s_value(rs1_value);
      b_is_inf = fp_is_inf_s_value(rs2_value);
      c_is_inf = fp_is_inf_s_value(rs3_value);
      a_is_zero = fp_is_zero_s_value(rs1_value);
      b_is_zero = fp_is_zero_s_value(rs2_value);
      c_is_zero = fp_is_zero_s_value(rs3_value);
      prod_is_inf = a_is_inf || b_is_inf;
      prod_is_zero = a_is_zero || b_is_zero;
      invalid_mul0inf = (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero);
      invalid_infsub = prod_is_inf && c_is_inf && (sign_c != sign_p);
      result_is_nan = a_is_nan || b_is_nan || c_is_nan ||
                      invalid_mul0inf || invalid_infsub;
      nv = fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
           fp_is_snan_s_value(rs3_value) || invalid_mul0inf || invalid_infsub;

      fflags = 5'b00000;
      if (result_is_nan) begin
        value = 64'hffffffff7fc00000;
        fflags = nv ? `FP_FLAG_NV : 5'b00000;
      end else if (prod_is_inf) begin
        value = {32'hffff_ffff, sign_p, 8'hff, 23'b0};
      end else if (c_is_inf) begin
        value = {32'hffff_ffff, sign_c, 8'hff, 23'b0};
      end else if (prod_is_zero && c_is_zero) begin
        res_sign = (sign_p == sign_c) ? sign_p : (rm == 3'b010);
        value = {32'hffff_ffff, res_sign, 31'b0};
      end else if (prod_is_zero) begin
        value = {32'hffff_ffff, sign_c, exp_c, frac_c};
      end else begin
        // c=0 折叠至此:sig_c=0 → addend_field=0 → 结果=round(a*b)(单舍入)。
        exp_a_eff = (exp_a == 8'h00) ? 1 : exp_a;
        exp_b_eff = (exp_b == 8'h00) ? 1 : exp_b;
        exp_c_eff = (exp_c == 8'h00) ? 1 : exp_c;
        sig_a = {(exp_a != 8'h00), frac_a};
        sig_b = {(exp_b != 8'h00), frac_b};
        sig_c = {(exp_c != 8'h00), frac_c};
        product = sig_a * sig_b;
        ep = exp_a_eff + exp_b_eff - 300;
        ec = exp_c_eff - 150;
        lzc_p = fp_lzc_48(product);
        lzc_c24 = fp_norm_shift_24(sig_c);
        pw = ep + 47 - lzc_p;
        cw = ec + 23 - lzc_c24;
        ref_w = (pw >= cw) ? pw : cw;
        shift_p = ep - ref_w + 126;
        shift_c = ec - ref_w + 126;
        if (shift_p >= 0) begin
          prod_field = {80'b0, product} << shift_p;
        end else begin
          negsh = (-shift_p > 128) ? 128 : -shift_p;
          prod_field = fp_shift_right_jam_128({80'b0, product}, negsh[7:0]);
        end
        if (shift_c >= 0) begin
          addend_field = {104'b0, sig_c} << shift_c;
        end else begin
          negsh = (-shift_c > 128) ? 128 : -shift_c;
          addend_field = fp_shift_right_jam_128({104'b0, sig_c}, negsh[7:0]);
        end
        if (sign_p == sign_c) begin
          mag = prod_field + addend_field;
          res_sign = sign_p;
        end else if (prod_field >= addend_field) begin
          mag = prod_field - addend_field;
          res_sign = sign_p;
        end else begin
          mag = addend_field - prod_field;
          res_sign = sign_c;
        end
        if (mag == 128'b0) begin
          value = (rm == 3'b010) ? 64'hffffffff80000000 : 64'hffffffff00000000;
        end else begin
          lzc_m = fp_lzc_128(mag);
          magn = mag << lzc_m;
          e_biased = ref_w + 128 - lzc_m;
          if (e_biased < 1) begin
            sub_shift = 1 - e_biased;
            negsh = (sub_shift > 128) ? 128 : sub_shift;
            magn = fp_shift_right_jam_128(magn, negsh[7:0]);
            e_biased = 1;
          end
          mant24 = magn[127:104];
          guard = magn[103];
          sticky = |magn[102:0];
          inc = fp_round_increment(res_sign, rm, mant24[0], guard, sticky);
          mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
          if (mant_round_ext[24]) begin
            e_biased = e_biased + 1;
            mant24 = mant_round_ext[24:1];
          end else begin
            mant24 = mant_round_ext[23:0];
          end
          fflags = fp_round_flags_s(res_sign, e_biased[7:0], mant24,
                                    guard, sticky);
          if (e_biased >= 255) begin
            value = fp_overflow_s(res_sign, rm);
            fflags = `FP_FLAG_OF | `FP_FLAG_NX;
          end else if ((e_biased <= 1) && !mant24[23]) begin
            value = {32'hffff_ffff, res_sign, 8'b0, mant24[22:0]};
          end else begin
            value = {32'hffff_ffff, res_sign, e_biased[7:0], mant24[22:0]};
          end
        end
      end
      fma_s_value = value;
      fma_s_fflags = fflags;
    end

  // FADD/FSUB —— value/fflags 由上方 always @(*) 块算出,double_i 输出 mux
  assign addsub_value_o  = double_i ? addsub_d_value  : addsub_s_value;
  assign addsub_fflags_o = double_i ? addsub_d_fflags : addsub_s_fflags;

  // FMUL —— 同上
  assign mul_value_o  = double_i ? mul_d_value  : mul_s_value;
  assign mul_fflags_o = double_i ? mul_d_fflags : mul_s_fflags;

  // FMADD 系列(FP#2 修复):fused multiply-add 单次舍入。双/单精度 always@* 组合块
  // 各算出 value/fflags;此处由 double_i 显式 mux 选择(共享输出端口)。
  assign fma_value_o  = double_i ? fma_d_value  : fma_s_value;
  assign fma_fflags_o = double_i ? fma_d_fflags : fma_s_fflags;

endmodule
