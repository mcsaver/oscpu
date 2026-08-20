`include "define.v"

// FADD/FSUB S1-S3 production child。single/double 数值与 fflags Q 全部由本模块独占；
// 每拍无条件推进，wrapper 仅在 resident meta S3 选择完整 {fflags,value} 对。
module OooFpAddSubPipe (
  input              clk,
  input              rst,
  input              flush_i,
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              sub_op_i,
  input  [2:0]       rm_i,
  output reg [63:0] addsub_d_value_q_o,
  output reg [4:0]  addsub_d_fflags_q_o,
  output reg [63:0] addsub_s_value_q_o,
  output reg [4:0]  addsub_s_fflags_q_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  // ---- double S1/S2/S3 state ----
  reg        as_d_s1_special_c, as_d_s1_special_q;
  reg [63:0] as_d_s1_spval_c, as_d_s1_spval_q;
  reg [4:0]  as_d_s1_spff_c, as_d_s1_spff_q;
  reg [55:0] as_d_s1_aaln_c, as_d_s1_aaln_q;
  reg [55:0] as_d_s1_baln_c, as_d_s1_baln_q;
  reg [10:0] as_d_s1_expz_c, as_d_s1_expz_q;
  reg        as_d_s1_signa_c, as_d_s1_signa_q;
  reg        as_d_s1_signb_c, as_d_s1_signb_q;
  reg        as_d_s1_altb_c, as_d_s1_altb_q;
  reg        as_d_s1_cancel_c, as_d_s1_cancel_q;
  reg [2:0]  as_d_s1_rm_c, as_d_s1_rm_q;
  reg [55:0] as_d_s2_signorm_c, as_d_s2_signorm_q;
  reg [10:0] as_d_s2_expz_c, as_d_s2_expz_q;
  reg        as_d_s2_signz_c, as_d_s2_signz_q;
  reg        as_d_s2_special_q;
  reg [63:0] as_d_s2_spval_q;
  reg [4:0]  as_d_s2_spff_q;
  reg [2:0]  as_d_s2_rm_q;
  reg [63:0] as_d_s3_value_c;
  reg [4:0]  as_d_s3_fflags_c;

  always @(*) begin : as_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg is_sub;
    reg sign_a, sign_b;
    reg [10:0] exp_a, exp_b, exp_a_eff, exp_b_eff, exp_z, exp_diff;
    reg [51:0] frac_a, frac_b;
    reg [55:0] sig_a, sig_b, sig_a_aligned, sig_b_aligned;
    reg [6:0] shift_dist;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i; is_sub = sub_op_i;
    exp_a_eff = 0; exp_b_eff = 0; exp_z = 0; exp_diff = 0;
    shift_dist = 0; sig_a = 0; sig_b = 0;
    sig_a_aligned = 0; sig_b_aligned = 0;
    as_d_s1_special_c = 1'b0; as_d_s1_spval_c = 64'b0;
    as_d_s1_spff_c = 5'b0; as_d_s1_altb_c = 1'b0;
    as_d_s1_cancel_c = 1'b0;
    sign_a = rs1_value[63];
    sign_b = rs2_value[63] ^ is_sub;
    exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52];
    frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0];
    a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
    b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
    a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
    b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
    a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
    b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);
    if (a_is_nan || b_is_nan) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = 64'h7ff8000000000000;
      as_d_s1_spff_c = (fp_is_snan_d_value(rs1_value) ||
                        fp_is_snan_d_value(rs2_value)) ?
                       `FP_FLAG_NV : 5'b00000;
    end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = 64'h7ff8000000000000;
      as_d_s1_spff_c = `FP_FLAG_NV;
    end else if (a_is_inf) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = {sign_a, 11'h7ff, 52'b0};
    end else if (b_is_inf) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = {sign_b, 11'h7ff, 52'b0};
    end else if (a_is_zero && b_is_zero) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = {((rm_i == 3'b010) ?
                           (sign_a | sign_b) : (sign_a & sign_b)), 63'b0};
    end else if (a_is_zero) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = {sign_b, exp_b, frac_b};
    end else if (b_is_zero) begin
      as_d_s1_special_c = 1'b1;
      as_d_s1_spval_c = rs1_value;
    end
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
    as_d_s1_altb_c = (exp_a_eff < exp_b_eff) ||
                     ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
    as_d_s1_cancel_c = (exp_a_eff == exp_b_eff) && (sig_a == sig_b);
    as_d_s1_aaln_c = sig_a_aligned;
    as_d_s1_baln_c = sig_b_aligned;
    as_d_s1_expz_c = exp_z;
    as_d_s1_signa_c = sign_a;
    as_d_s1_signb_c = sign_b;
    as_d_s1_rm_c = rm_i;
  end

  always @(*) begin : as_d_s2_comb
    reg [55:0] sig_a_aligned, sig_b_aligned, sig_norm;
    reg [56:0] sig_sum;
    reg [10:0] exp_z, norm_exp_limit;
    reg [6:0] norm_lzc, norm_shift;
    reg sign_a, sign_b, sign_z;
    sig_a_aligned = as_d_s1_aaln_q; sig_b_aligned = as_d_s1_baln_q;
    exp_z = as_d_s1_expz_q; sign_a = as_d_s1_signa_q;
    sign_b = as_d_s1_signb_q;
    sign_z = 1'b0; sig_norm = 0; sig_sum = 0; norm_exp_limit = 0;
    norm_lzc = 0; norm_shift = 0;
    if (sign_a == sign_b) begin
      sign_z = sign_a;
      sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
      if (sig_sum[56]) begin
        sig_norm = sig_sum[56:1];
        sig_norm[0] = sig_norm[0] | sig_sum[0];
        exp_z = exp_z + 11'd1;
      end else sig_norm = sig_sum[55:0];
    end else begin
      if (as_d_s1_cancel_q) begin
        sign_z = 1'b0; sig_norm = 56'b0;
      end else if (as_d_s1_altb_q) begin
        sign_z = sign_b; sig_norm = sig_b_aligned - sig_a_aligned;
      end else begin
        sign_z = sign_a; sig_norm = sig_a_aligned - sig_b_aligned;
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
    as_d_s2_signorm_c = sig_norm;
    as_d_s2_expz_c = exp_z;
    as_d_s2_signz_c = sign_z;
  end

  always @(*) begin : as_d_s3_comb
    reg [55:0] sig_norm;
    reg [10:0] exp_z;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg sign_z, guard, sticky, inc;
    reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    sig_norm = as_d_s2_signorm_q; exp_z = as_d_s2_expz_q;
    sign_z = as_d_s2_signz_q; rm = as_d_s2_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    value = 64'b0; fflags = 5'b00000;
    if (sig_norm == 56'b0) begin
      value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
      fflags = 5'b00000;
    end else begin
      mant53 = sig_norm[55:3];
      guard = sig_norm[2];
      sticky = sig_norm[1] | sig_norm[0];
      inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
      mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
      if (mant_round_ext[53]) begin
        exp_z = exp_z + 11'd1; mant53 = mant_round_ext[53:1];
      end else mant53 = mant_round_ext[52:0];
      if (exp_z >= 11'h7ff) value = fp_overflow_d(sign_z, rm);
      else if ((exp_z == 11'd1) && !mant53[52])
        value = {sign_z, 11'b0, mant53[51:0]};
      else value = {sign_z, exp_z, mant53[51:0]};
      fflags = fp_round_flags_d(sign_z, exp_z, mant53, guard, sticky);
    end
    as_d_s3_value_c = as_d_s2_special_q ? as_d_s2_spval_q : value;
    as_d_s3_fflags_c = as_d_s2_special_q ? as_d_s2_spff_q : fflags;
  end

  // ---- single S1/S2/S3 state ----
  reg        as_s_s1_special_c, as_s_s1_special_q;
  reg [63:0] as_s_s1_spval_c, as_s_s1_spval_q;
  reg [4:0]  as_s_s1_spff_c, as_s_s1_spff_q;
  reg [26:0] as_s_s1_aaln_c, as_s_s1_aaln_q;
  reg [26:0] as_s_s1_baln_c, as_s_s1_baln_q;
  reg [7:0]  as_s_s1_expz_c, as_s_s1_expz_q;
  reg        as_s_s1_signa_c, as_s_s1_signa_q;
  reg        as_s_s1_signb_c, as_s_s1_signb_q;
  reg        as_s_s1_altb_c, as_s_s1_altb_q;
  reg        as_s_s1_cancel_c, as_s_s1_cancel_q;
  reg [2:0]  as_s_s1_rm_c, as_s_s1_rm_q;
  reg [26:0] as_s_s2_signorm_c, as_s_s2_signorm_q;
  reg [7:0]  as_s_s2_expz_c, as_s_s2_expz_q;
  reg        as_s_s2_signz_c, as_s_s2_signz_q;
  reg        as_s_s2_special_q;
  reg [63:0] as_s_s2_spval_q;
  reg [4:0]  as_s_s2_spff_q;
  reg [2:0]  as_s_s2_rm_q;
  reg [63:0] as_s_s3_value_c;
  reg [4:0]  as_s_s3_fflags_c;

  always @(*) begin : as_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg is_sub;
    reg [31:0] a, b;
    reg sign_a, sign_b;
    reg [7:0] exp_a, exp_b, exp_a_eff, exp_b_eff, exp_z, exp_diff;
    reg [22:0] frac_a, frac_b;
    reg [26:0] sig_a, sig_b, sig_a_aligned, sig_b_aligned;
    reg [5:0] shift_dist;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i; is_sub = sub_op_i;
    a = 0; b = 0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0;
    exp_diff = 0; shift_dist = 0; sig_a = 0; sig_b = 0;
    sig_a_aligned = 0; sig_b_aligned = 0;
    as_s_s1_special_c = 1'b0; as_s_s1_spval_c = 64'b0;
    as_s_s1_spff_c = 5'b0; as_s_s1_altb_c = 1'b0;
    as_s_s1_cancel_c = 1'b0;
    a = rs1_value[31:0]; b = rs2_value[31:0];
    sign_a = a[31]; sign_b = b[31] ^ is_sub;
    exp_a = a[30:23]; exp_b = b[30:23];
    frac_a = a[22:0]; frac_b = b[22:0];
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
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = 64'hffffffff7fc00000;
      as_s_s1_spff_c = (fp_is_snan_s_value(rs1_value) ||
                        fp_is_snan_s_value(rs2_value)) ?
                       `FP_FLAG_NV : 5'b00000;
    end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = 64'hffffffff7fc00000;
      as_s_s1_spff_c = `FP_FLAG_NV;
    end else if (a_is_inf) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = {32'hffff_ffff, sign_a, 8'hff, 23'b0};
    end else if (b_is_inf) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = {32'hffff_ffff, sign_b, 8'hff, 23'b0};
    end else if (a_is_zero && b_is_zero) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = {32'hffff_ffff,
          ((rm_i == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)),
          31'b0};
    end else if (a_is_zero) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = {32'hffff_ffff, sign_b, exp_b, frac_b};
    end else if (b_is_zero) begin
      as_s_s1_special_c = 1'b1;
      as_s_s1_spval_c = {32'hffff_ffff, a};
    end
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
    as_s_s1_altb_c = (exp_a_eff < exp_b_eff) ||
                     ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
    as_s_s1_cancel_c = (exp_a_eff == exp_b_eff) && (sig_a == sig_b);
    as_s_s1_aaln_c = sig_a_aligned;
    as_s_s1_baln_c = sig_b_aligned;
    as_s_s1_expz_c = exp_z;
    as_s_s1_signa_c = sign_a;
    as_s_s1_signb_c = sign_b;
    as_s_s1_rm_c = rm_i;
  end

  always @(*) begin : as_s_s2_comb
    reg [26:0] sig_a_aligned, sig_b_aligned, sig_norm;
    reg [27:0] sig_sum;
    reg [7:0] exp_z, norm_exp_limit;
    reg [5:0] norm_lzc, norm_shift;
    reg sign_a, sign_b, sign_z;
    sig_a_aligned = as_s_s1_aaln_q; sig_b_aligned = as_s_s1_baln_q;
    exp_z = as_s_s1_expz_q; sign_a = as_s_s1_signa_q;
    sign_b = as_s_s1_signb_q;
    sign_z = 1'b0; sig_norm = 0; sig_sum = 0; norm_exp_limit = 0;
    norm_lzc = 0; norm_shift = 0;
    if (sign_a == sign_b) begin
      sign_z = sign_a;
      sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
      if (sig_sum[27]) begin
        sig_norm = sig_sum[27:1];
        sig_norm[0] = sig_norm[0] | sig_sum[0];
        exp_z = exp_z + 8'd1;
      end else sig_norm = sig_sum[26:0];
    end else begin
      if (as_s_s1_cancel_q) begin
        sign_z = 1'b0; sig_norm = 27'b0;
      end else if (as_s_s1_altb_q) begin
        sign_z = sign_b; sig_norm = sig_b_aligned - sig_a_aligned;
      end else begin
        sign_z = sign_a; sig_norm = sig_a_aligned - sig_b_aligned;
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
    as_s_s2_signorm_c = sig_norm;
    as_s_s2_expz_c = exp_z;
    as_s_s2_signz_c = sign_z;
  end

  always @(*) begin : as_s_s3_comb
    reg [26:0] sig_norm;
    reg [7:0] exp_z;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg sign_z, guard, sticky, inc;
    reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    sig_norm = as_s_s2_signorm_q; exp_z = as_s_s2_expz_q;
    sign_z = as_s_s2_signz_q; rm = as_s_s2_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    value = 64'b0; fflags = 5'b00000;
    if (sig_norm == 27'b0) begin
      value = (rm == 3'b010) ?
              64'hffffffff80000000 : 64'hffffffff00000000;
      fflags = 5'b00000;
    end else begin
      mant24 = sig_norm[26:3];
      guard = sig_norm[2];
      sticky = sig_norm[1] | sig_norm[0];
      inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
      mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
      if (mant_round_ext[24]) begin
        exp_z = exp_z + 8'd1; mant24 = mant_round_ext[24:1];
      end else mant24 = mant_round_ext[23:0];
      if (exp_z >= 8'hff) value = fp_overflow_s(sign_z, rm);
      else if ((exp_z == 8'd1) && !mant24[23])
        value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
      else value = {32'hffff_ffff, sign_z, exp_z, mant24[22:0]};
      fflags = fp_round_flags_s(sign_z, exp_z, mant24, guard, sticky);
    end
    as_s_s3_value_c = as_s_s2_special_q ? as_s_s2_spval_q : value;
    as_s_s3_fflags_c = as_s_s2_special_q ? as_s_s2_spff_q : fflags;
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      as_d_s1_special_q <= 1'b0; as_d_s1_spval_q <= 64'b0;
      as_d_s1_spff_q <= 5'b0; as_d_s1_aaln_q <= 56'b0;
      as_d_s1_baln_q <= 56'b0; as_d_s1_expz_q <= 11'b0;
      as_d_s1_signa_q <= 1'b0; as_d_s1_signb_q <= 1'b0;
      as_d_s1_altb_q <= 1'b0; as_d_s1_cancel_q <= 1'b0;
      as_d_s1_rm_q <= 3'b0; as_d_s2_signorm_q <= 56'b0;
      as_d_s2_expz_q <= 11'b0; as_d_s2_signz_q <= 1'b0;
      as_d_s2_special_q <= 1'b0; as_d_s2_spval_q <= 64'b0;
      as_d_s2_spff_q <= 5'b0; as_d_s2_rm_q <= 3'b0;
      addsub_d_value_q_o <= 64'b0; addsub_d_fflags_q_o <= 5'b0;
      as_s_s1_special_q <= 1'b0; as_s_s1_spval_q <= 64'b0;
      as_s_s1_spff_q <= 5'b0; as_s_s1_aaln_q <= 27'b0;
      as_s_s1_baln_q <= 27'b0; as_s_s1_expz_q <= 8'b0;
      as_s_s1_signa_q <= 1'b0; as_s_s1_signb_q <= 1'b0;
      as_s_s1_altb_q <= 1'b0; as_s_s1_cancel_q <= 1'b0;
      as_s_s1_rm_q <= 3'b0; as_s_s2_signorm_q <= 27'b0;
      as_s_s2_expz_q <= 8'b0; as_s_s2_signz_q <= 1'b0;
      as_s_s2_special_q <= 1'b0; as_s_s2_spval_q <= 64'b0;
      as_s_s2_spff_q <= 5'b0; as_s_s2_rm_q <= 3'b0;
      addsub_s_value_q_o <= 64'b0; addsub_s_fflags_q_o <= 5'b0;
    end else begin
      as_d_s1_special_q <= as_d_s1_special_c;
      as_d_s1_spval_q <= as_d_s1_spval_c;
      as_d_s1_spff_q <= as_d_s1_spff_c;
      as_d_s1_aaln_q <= as_d_s1_aaln_c;
      as_d_s1_baln_q <= as_d_s1_baln_c;
      as_d_s1_expz_q <= as_d_s1_expz_c;
      as_d_s1_signa_q <= as_d_s1_signa_c;
      as_d_s1_signb_q <= as_d_s1_signb_c;
      as_d_s1_altb_q <= as_d_s1_altb_c;
      as_d_s1_cancel_q <= as_d_s1_cancel_c;
      as_d_s1_rm_q <= as_d_s1_rm_c;
      as_d_s2_signorm_q <= as_d_s2_signorm_c;
      as_d_s2_expz_q <= as_d_s2_expz_c;
      as_d_s2_signz_q <= as_d_s2_signz_c;
      as_d_s2_special_q <= as_d_s1_special_q;
      as_d_s2_spval_q <= as_d_s1_spval_q;
      as_d_s2_spff_q <= as_d_s1_spff_q;
      as_d_s2_rm_q <= as_d_s1_rm_q;
      addsub_d_value_q_o <= as_d_s3_value_c;
      addsub_d_fflags_q_o <= as_d_s3_fflags_c;
      as_s_s1_special_q <= as_s_s1_special_c;
      as_s_s1_spval_q <= as_s_s1_spval_c;
      as_s_s1_spff_q <= as_s_s1_spff_c;
      as_s_s1_aaln_q <= as_s_s1_aaln_c;
      as_s_s1_baln_q <= as_s_s1_baln_c;
      as_s_s1_expz_q <= as_s_s1_expz_c;
      as_s_s1_signa_q <= as_s_s1_signa_c;
      as_s_s1_signb_q <= as_s_s1_signb_c;
      as_s_s1_altb_q <= as_s_s1_altb_c;
      as_s_s1_cancel_q <= as_s_s1_cancel_c;
      as_s_s1_rm_q <= as_s_s1_rm_c;
      as_s_s2_signorm_q <= as_s_s2_signorm_c;
      as_s_s2_expz_q <= as_s_s2_expz_c;
      as_s_s2_signz_q <= as_s_s2_signz_c;
      as_s_s2_special_q <= as_s_s1_special_q;
      as_s_s2_spval_q <= as_s_s1_spval_q;
      as_s_s2_spff_q <= as_s_s1_spff_q;
      as_s_s2_rm_q <= as_s_s1_rm_q;
      addsub_s_value_q_o <= as_s_s3_value_c;
      addsub_s_fflags_q_o <= as_s_s3_fflags_c;
    end
  end

endmodule
