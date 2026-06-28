`include "define.v"

// FP 长延迟运算（FDIV/FSQRT，单/双精度）：从 OooFpPendingExec 抽出的时序 owner。
// 内含 OooFpDivIter / OooFpSqrtIter 迭代单元，外加 operand 准备（dividend/divisor/
// radicand）、结果装配与 fflags。op-decode（is_div/is_sqrt）由父模块从 funct7 算好后
// 输入；long_start_i 触发迭代。busy/done/result/fflags 输出给父模块的 long 路径。
// 行为与原 OooFpPendingExec 内联实现等价。
module OooFpLongOpGate (
  input              clk,
  input              rst,
  input              flush_i,
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input              double_i,
  input  [2:0]       rm_i,
  input              long_start_i,
  input              is_div_i,
  input              is_sqrt_i,
  output             div_busy_o,
  output             sqrt_busy_o,
  output             long_done_o,
  output [`XLEN-1:0] long_done_result_o,
  output [4:0]       long_done_fflags_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  function [`XLEN-1:0] fp_div_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] rm;
    input [55:0] quotient_ext_i;
    input remainder_nonzero_i;
    begin
      fp_div_value = is_double ?
          fp_div_d_value(rs1_value, rs2_value, rm, quotient_ext_i,
                         remainder_nonzero_i) :
          fp_div_s_value(rs1_value, rs2_value, rm, quotient_ext_i[26:0],
                         remainder_nonzero_i);
    end
  endfunction

  function [`XLEN-1:0] fp_div_d_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    input [55:0] quotient_ext_i;
    input remainder_nonzero_i;
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
    reg [55:0] quotient_ext;
    reg [55:0] quotient_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sub_shift;
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
        fp_div_d_value = 64'h7ff8000000000000;
      end else if ((a_is_zero && b_is_zero) ||
                   (a_is_inf && b_is_inf)) begin
        fp_div_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf || b_is_zero) begin
        fp_div_d_value = {sign_z, 11'h7ff, 52'b0};
      end else if (a_is_zero || b_is_inf) begin
        fp_div_d_value = {sign_z, 63'b0};
      end else begin
        exp_z = ((exp_a == 11'h000) ? 1 : exp_a) -
                ((exp_b == 11'h000) ? 1 : exp_b) + 1023;

        quotient_ext = quotient_ext_i;
        if (quotient_ext[55]) begin
          quotient_norm = quotient_ext;
        end else begin
          quotient_norm = {quotient_ext[54:0], 1'b0};
          exp_z = exp_z - 1;
        end
        quotient_norm[0] = quotient_norm[0] | remainder_nonzero_i;

        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 56)
            sub_shift = 7'd56;
          else
            sub_shift = sub_shift_int;
          quotient_norm = fp_shift_right_jam_56(quotient_norm, sub_shift);
          exp_z = 1;
        end

        mant53 = quotient_norm[55:3];
        guard = quotient_norm[2];
        sticky = quotient_norm[1] | quotient_norm[0];
        inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53]) begin
          mant53 = mant_round_ext[53:1];
          exp_z = exp_z + 1;
        end else begin
          mant53 = mant_round_ext[52:0];
        end

        if (exp_z >= 2047) begin
          fp_div_d_value = {sign_z, 11'h7ff, 52'b0};
        end else if ((exp_z <= 1) && !mant53[52]) begin
          fp_div_d_value = {sign_z, 11'b0, mant53[51:0]};
        end else begin
          fp_div_d_value = {sign_z, exp_z[10:0], mant53[51:0]};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_div_s_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    input [26:0] quotient_ext_i;
    input remainder_nonzero_i;
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
    reg [26:0] quotient_ext;
    reg [26:0] quotient_norm;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [5:0] sub_shift;
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
        fp_div_s_value = 64'hffffffff7fc00000;
      end else if ((a_is_zero && b_is_zero) ||
                   (a_is_inf && b_is_inf)) begin
        fp_div_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf || b_is_zero) begin
        fp_div_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
      end else if (a_is_zero || b_is_inf) begin
        fp_div_s_value = {32'hffff_ffff, sign_z, 31'b0};
      end else begin
        exp_z = ((exp_a == 8'h00) ? 1 : exp_a) -
                ((exp_b == 8'h00) ? 1 : exp_b) + 127;

        quotient_ext = quotient_ext_i;
        if (quotient_ext[26]) begin
          quotient_norm = quotient_ext;
        end else begin
          quotient_norm = {quotient_ext[25:0], 1'b0};
          exp_z = exp_z - 1;
        end
        quotient_norm[0] = quotient_norm[0] | remainder_nonzero_i;

        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 27)
            sub_shift = 6'd27;
          else
            sub_shift = sub_shift_int;
          quotient_norm = fp_shift_right_jam_27(quotient_norm, sub_shift);
          exp_z = 1;
        end

        mant24 = quotient_norm[26:3];
        guard = quotient_norm[2];
        sticky = quotient_norm[1] | quotient_norm[0];
        inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          mant24 = mant_round_ext[24:1];
          exp_z = exp_z + 1;
        end else begin
          mant24 = mant_round_ext[23:0];
        end

        if (exp_z >= 255) begin
          fp_div_s_value = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
        end else if ((exp_z <= 1) && !mant24[23]) begin
          fp_div_s_value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
        end else begin
          fp_div_s_value = {32'hffff_ffff, sign_z, exp_z[7:0], mant24[22:0]};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_sqrt_value;
    input [`XLEN-1:0] rs1_value;
    input is_double;
    input [2:0] rm;
    input [55:0] root_ext_i;
    input remainder_nonzero_i;
    begin
      fp_sqrt_value = is_double ?
          fp_sqrt_d_value(rs1_value, rm, root_ext_i,
                          remainder_nonzero_i) :
          fp_sqrt_s_value(rs1_value, rm, root_ext_i[26:0],
                          remainder_nonzero_i);
    end
  endfunction

  function [`XLEN-1:0] fp_sqrt_d_value;
    input [`XLEN-1:0] rs1_value;
    input [2:0] rm;
    input [55:0] root_ext_i;
    input remainder_nonzero_i;
    reg sign_a;
    reg [10:0] exp_a;
    reg [51:0] frac_a;
    reg a_is_nan;
    reg a_is_inf;
    reg a_is_zero;
    reg [52:0] sig_a;
    reg [55:0] root_ext;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [5:0] norm_shift;
    integer exp_unbiased;
    integer sqrt_exp;
    integer exp_z;
    begin
      sign_a = rs1_value[63];
      exp_a = rs1_value[62:52];
      frac_a = rs1_value[51:0];
      a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
      a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
      a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);

      if (a_is_nan) begin
        fp_sqrt_d_value = 64'h7ff8000000000000;
      end else if (sign_a && !a_is_zero) begin
        fp_sqrt_d_value = 64'h7ff8000000000000;
      end else if (a_is_inf) begin
        fp_sqrt_d_value = {1'b0, 11'h7ff, 52'b0};
      end else if (a_is_zero) begin
        fp_sqrt_d_value = {sign_a, 63'b0};
      end else begin
        sig_a = {(exp_a != 11'h000), frac_a};
        exp_unbiased = ((exp_a == 11'h000) ? 1 : exp_a) - 1023;
        if (exp_a == 11'h000) begin
          norm_shift = fp_norm_shift_53(sig_a);
          sig_a = sig_a << norm_shift;
          exp_unbiased = exp_unbiased - norm_shift;
        end

        sqrt_exp = exp_unbiased >>> 1;

        root_ext = root_ext_i;
        mant53 = root_ext[55:3];
        guard = root_ext[2];
        sticky = root_ext[1] | root_ext[0] | remainder_nonzero_i;
        inc = fp_round_increment(1'b0, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        exp_z = sqrt_exp + 1023;
        if (mant_round_ext[53]) begin
          mant53 = mant_round_ext[53:1];
          exp_z = exp_z + 1;
        end else begin
          mant53 = mant_round_ext[52:0];
        end

        if (exp_z >= 2047) begin
          fp_sqrt_d_value = {1'b0, 11'h7ff, 52'b0};
        end else if ((exp_z <= 1) && !mant53[52]) begin
          fp_sqrt_d_value = {1'b0, 11'b0, mant53[51:0]};
        end else begin
          fp_sqrt_d_value = {1'b0, exp_z[10:0], mant53[51:0]};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_sqrt_s_value;
    input [`XLEN-1:0] rs1_value;
    input [2:0] rm;
    input [26:0] root_ext_i;
    input remainder_nonzero_i;
    reg [31:0] a;
    reg sign_a;
    reg [7:0] exp_a;
    reg [22:0] frac_a;
    reg a_is_nan;
    reg a_is_inf;
    reg a_is_zero;
    reg [23:0] sig_a;
    reg [26:0] root_ext;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [4:0] norm_shift;
    integer exp_unbiased;
    integer sqrt_exp;
    integer exp_z;
    begin
      a = rs1_value[31:0];
      sign_a = a[31];
      exp_a = a[30:23];
      frac_a = a[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      a_is_inf = (rs1_value[63:32] == 32'hffff_ffff) &&
                 (exp_a == 8'hff) && (frac_a == 23'b0);
      a_is_zero = (rs1_value[63:32] == 32'hffff_ffff) &&
                  (exp_a == 8'h00) && (frac_a == 23'b0);

      if (a_is_nan) begin
        fp_sqrt_s_value = 64'hffffffff7fc00000;
      end else if (sign_a && !a_is_zero) begin
        fp_sqrt_s_value = 64'hffffffff7fc00000;
      end else if (a_is_inf) begin
        fp_sqrt_s_value = {32'hffff_ffff, 1'b0, 8'hff, 23'b0};
      end else if (a_is_zero) begin
        fp_sqrt_s_value = {32'hffff_ffff, sign_a, 31'b0};
      end else begin
        sig_a = {(exp_a != 8'h00), frac_a};
        exp_unbiased = ((exp_a == 8'h00) ? 1 : exp_a) - 127;
        if (exp_a == 8'h00) begin
          norm_shift = fp_norm_shift_24(sig_a);
          sig_a = sig_a << norm_shift;
          exp_unbiased = exp_unbiased - norm_shift;
        end

        sqrt_exp = exp_unbiased >>> 1;

        root_ext = root_ext_i;
        mant24 = root_ext[26:3];
        guard = root_ext[2];
        sticky = root_ext[1] | root_ext[0] | remainder_nonzero_i;
        inc = fp_round_increment(1'b0, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        exp_z = sqrt_exp + 127;
        if (mant_round_ext[24]) begin
          mant24 = mant_round_ext[24:1];
          exp_z = exp_z + 1;
        end else begin
          mant24 = mant_round_ext[23:0];
        end

        if (exp_z >= 255) begin
          fp_sqrt_s_value = {32'hffff_ffff, 1'b0, 8'hff, 23'b0};
        end else if ((exp_z <= 1) && !mant24[23]) begin
          fp_sqrt_s_value = {32'hffff_ffff, 1'b0, 8'b0, mant24[22:0]};
        end else begin
          fp_sqrt_s_value = {32'hffff_ffff, 1'b0, exp_z[7:0], mant24[22:0]};
        end
      end
    end
  endfunction

  function [107:0] fp_div_dividend_value;
    input [`XLEN-1:0] rs1_value;
    input is_double;
    reg [52:0] sig_d;
    reg [23:0] sig_s;
    begin
      if (is_double) begin
        sig_d = {(rs1_value[62:52] != 11'h000), rs1_value[51:0]};
        fp_div_dividend_value = {sig_d, 55'b0};
      end else begin
        sig_s = {(rs1_value[30:23] != 8'h00), rs1_value[22:0]};
        fp_div_dividend_value = {58'b0, sig_s, 26'b0};
      end
    end
  endfunction

  function [52:0] fp_div_divisor_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    reg [52:0] sig_d;
    reg [23:0] sig_s;
    begin
      if (is_double) begin
        sig_d = {(rs2_value[62:52] != 11'h000), rs2_value[51:0]};
        fp_div_divisor_value = sig_d;
      end else begin
        sig_s = {(rs2_value[30:23] != 8'h00), rs2_value[22:0]};
        fp_div_divisor_value = {29'b0, sig_s};
      end
    end
  endfunction

  function [111:0] fp_sqrt_radicand_value;
    input [`XLEN-1:0] rs1_value;
    input is_double;
    reg [52:0] sig_d;
    reg [23:0] sig_s;
    reg [53:0] radicand_s;
    reg [5:0] norm_shift_d;
    reg [4:0] norm_shift_s;
    integer exp_unbiased;
    begin
      if (is_double) begin
        sig_d = {(rs1_value[62:52] != 11'h000), rs1_value[51:0]};
        exp_unbiased = ((rs1_value[62:52] == 11'h000) ? 1 :
                        rs1_value[62:52]) - 1023;
        if (rs1_value[62:52] == 11'h000) begin
          norm_shift_d = fp_norm_shift_53(sig_d);
          sig_d = sig_d << norm_shift_d;
          exp_unbiased = exp_unbiased - norm_shift_d;
        end
        fp_sqrt_radicand_value =
            exp_unbiased[0] ? ({59'b0, sig_d} << 59) :
                              ({59'b0, sig_d} << 58);
      end else begin
        sig_s = {(rs1_value[30:23] != 8'h00), rs1_value[22:0]};
        exp_unbiased = ((rs1_value[30:23] == 8'h00) ? 1 :
                        rs1_value[30:23]) - 127;
        if (rs1_value[30:23] == 8'h00) begin
          norm_shift_s = fp_norm_shift_24(sig_s);
          sig_s = sig_s << norm_shift_s;
          exp_unbiased = exp_unbiased - norm_shift_s;
        end
        radicand_s = exp_unbiased[0] ? ({30'b0, sig_s} << 30) :
                                      ({30'b0, sig_s} << 29);
        fp_sqrt_radicand_value = {58'b0, radicand_s};
      end
    end
  endfunction

  function [4:0] fp_div_s_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    input [26:0] quotient_ext_i;
    input remainder_nonzero_i;
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
    reg [26:0] quotient_norm;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [5:0] sub_shift;
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
      fp_div_s_fflags = 5'b00000;

      if (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
          (a_is_zero && b_is_zero) || (a_is_inf && b_is_inf)) begin
        fp_div_s_fflags = `FP_FLAG_NV;
      end else if (!a_is_nan && !b_is_nan && !a_is_zero && b_is_zero) begin
        fp_div_s_fflags = `FP_FLAG_DZ;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        exp_z = ((exp_a == 8'h00) ? 1 : exp_a) -
                ((exp_b == 8'h00) ? 1 : exp_b) + 127;
        if (quotient_ext_i[26]) begin
          quotient_norm = quotient_ext_i;
        end else begin
          quotient_norm = {quotient_ext_i[25:0], 1'b0};
          exp_z = exp_z - 1;
        end
        quotient_norm[0] = quotient_norm[0] | remainder_nonzero_i;
        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 27)
            sub_shift = 6'd27;
          else
            sub_shift = sub_shift_int;
          quotient_norm = fp_shift_right_jam_27(quotient_norm, sub_shift);
          exp_z = 1;
        end
        mant24 = quotient_norm[26:3];
        guard = quotient_norm[2];
        sticky = quotient_norm[1] | quotient_norm[0];
        inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          mant24 = mant_round_ext[24:1];
          exp_z = exp_z + 1;
        end else begin
          mant24 = mant_round_ext[23:0];
        end
        fp_div_s_fflags = fp_round_flags_s(sign_z, exp_z[7:0], mant24,
                                           guard, sticky);
        if (exp_z >= 255)
          fp_div_s_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
    end
  endfunction

  function [4:0] fp_div_d_fflags;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input [2:0] rm;
    input [55:0] quotient_ext_i;
    input remainder_nonzero_i;
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
    reg [55:0] quotient_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sub_shift;
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
      fp_div_d_fflags = 5'b00000;

      if (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
          (a_is_zero && b_is_zero) || (a_is_inf && b_is_inf)) begin
        fp_div_d_fflags = `FP_FLAG_NV;
      end else if (!a_is_nan && !b_is_nan && !a_is_zero && b_is_zero) begin
        fp_div_d_fflags = `FP_FLAG_DZ;
      end else if (!(a_is_nan || b_is_nan || a_is_inf || b_is_inf ||
                   a_is_zero || b_is_zero)) begin
        exp_z = ((exp_a == 11'h000) ? 1 : exp_a) -
                ((exp_b == 11'h000) ? 1 : exp_b) + 1023;
        if (quotient_ext_i[55]) begin
          quotient_norm = quotient_ext_i;
        end else begin
          quotient_norm = {quotient_ext_i[54:0], 1'b0};
          exp_z = exp_z - 1;
        end
        quotient_norm[0] = quotient_norm[0] | remainder_nonzero_i;
        if (exp_z < 1) begin
          sub_shift_int = 1 - exp_z;
          if (sub_shift_int >= 56)
            sub_shift = 7'd56;
          else
            sub_shift = sub_shift_int;
          quotient_norm = fp_shift_right_jam_56(quotient_norm, sub_shift);
          exp_z = 1;
        end
        mant53 = quotient_norm[55:3];
        guard = quotient_norm[2];
        sticky = quotient_norm[1] | quotient_norm[0];
        inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53]) begin
          mant53 = mant_round_ext[53:1];
          exp_z = exp_z + 1;
        end else begin
          mant53 = mant_round_ext[52:0];
        end
        fp_div_d_fflags = fp_round_flags_d(sign_z, exp_z[10:0], mant53,
                                           guard, sticky);
        if (exp_z >= 2047)
          fp_div_d_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end
    end
  endfunction

  function [4:0] fp_sqrt_s_fflags;
    input [`XLEN-1:0] rs1_value;
    input [2:0] rm;
    input [26:0] root_ext_i;
    input remainder_nonzero_i;
    reg [31:0] a;
    reg sign_a;
    reg [7:0] exp_a;
    reg [22:0] frac_a;
    reg a_is_nan;
    reg a_is_inf;
    reg a_is_zero;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    integer exp_z;
    begin
      a = rs1_value[31:0];
      sign_a = a[31];
      exp_a = a[30:23];
      frac_a = a[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      a_is_inf = fp_is_inf_s_value(rs1_value);
      a_is_zero = fp_is_zero_s_value(rs1_value);
      fp_sqrt_s_fflags = 5'b00000;
      if (fp_is_snan_s_value(rs1_value) || (sign_a && !a_is_zero)) begin
        fp_sqrt_s_fflags = `FP_FLAG_NV;
      end else if (!(a_is_nan || a_is_inf || a_is_zero)) begin
        mant24 = root_ext_i[26:3];
        guard = root_ext_i[2];
        sticky = root_ext_i[1] | root_ext_i[0] | remainder_nonzero_i;
        inc = fp_round_increment(1'b0, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        exp_z = 127;
        if (mant_round_ext[24])
          mant24 = mant_round_ext[24:1];
        else
          mant24 = mant_round_ext[23:0];
        fp_sqrt_s_fflags = fp_round_flags_s(1'b0, exp_z[7:0], mant24,
                                            guard, sticky);
      end
    end
  endfunction

  function [4:0] fp_sqrt_d_fflags;
    input [`XLEN-1:0] rs1_value;
    input [2:0] rm;
    input [55:0] root_ext_i;
    input remainder_nonzero_i;
    reg sign_a;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard;
    reg sticky;
    reg inc;
    begin
      sign_a = rs1_value[63];
      fp_sqrt_d_fflags = 5'b00000;
      if (fp_is_snan_d_value(rs1_value) ||
          (sign_a && !fp_is_zero_d_value(rs1_value) &&
           !fp_is_nan_d_value(rs1_value))) begin
        fp_sqrt_d_fflags = `FP_FLAG_NV;
      end else if (!(fp_is_nan_d_value(rs1_value) ||
                   fp_is_inf_d_value(rs1_value) ||
                   fp_is_zero_d_value(rs1_value))) begin
        mant53 = root_ext_i[55:3];
        guard = root_ext_i[2];
        sticky = root_ext_i[1] | root_ext_i[0] | remainder_nonzero_i;
        inc = fp_round_increment(1'b0, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53])
          mant53 = mant_round_ext[53:1];
        else
          mant53 = mant_round_ext[52:0];
        fp_sqrt_d_fflags = fp_round_flags_d(1'b0, 11'd1023, mant53,
                                            guard, sticky);
      end
    end
  endfunction

  // operand 准备
  wire [107:0] dividend_w = fp_div_dividend_value(frs1_value_i, double_i);
  wire [52:0]  divisor_w  = fp_div_divisor_value(frs2_value_i, double_i);
  wire [111:0] radicand_w = fp_sqrt_radicand_value(frs1_value_i, double_i);

  wire [55:0] div_quotient_w;
  wire        div_remainder_nonzero_w;
  wire        div_busy_w;
  wire        div_done_w;
  wire [55:0] sqrt_root_w;
  wire        sqrt_remainder_nonzero_w;
  wire        sqrt_busy_w;
  wire        sqrt_done_w;

  OooFpDivIter u_fp_div_iter (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .start_i(long_start_i && is_div_i),
    .dividend_i(dividend_w),
    .divisor_i(divisor_w),
    .busy_o(div_busy_w),
    .done_o(div_done_w),
    .quotient_o(div_quotient_w),
    .remainder_nonzero_o(div_remainder_nonzero_w)
  );

  OooFpSqrtIter u_fp_sqrt_iter (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .start_i(long_start_i && is_sqrt_i),
    .value_i(radicand_w),
    .busy_o(sqrt_busy_w),
    .done_o(sqrt_done_w),
    .root_o(sqrt_root_w),
    .remainder_nonzero_o(sqrt_remainder_nonzero_w)
  );

  wire [`XLEN-1:0] div_value_w =
      fp_div_value(frs1_value_i, frs2_value_i, double_i, rm_i,
                   div_quotient_w, div_remainder_nonzero_w);
  wire [`XLEN-1:0] sqrt_value_w =
      fp_sqrt_value(frs1_value_i, double_i, rm_i,
                    sqrt_root_w, sqrt_remainder_nonzero_w);
  wire [4:0] div_fflags_w = double_i ?
      fp_div_d_fflags(frs1_value_i, frs2_value_i, rm_i,
                      div_quotient_w, div_remainder_nonzero_w) :
      fp_div_s_fflags(frs1_value_i, frs2_value_i, rm_i,
                      div_quotient_w[26:0], div_remainder_nonzero_w);
  wire [4:0] sqrt_fflags_w = double_i ?
      fp_sqrt_d_fflags(frs1_value_i, rm_i,
                       sqrt_root_w, sqrt_remainder_nonzero_w) :
      fp_sqrt_s_fflags(frs1_value_i, rm_i,
                       sqrt_root_w[26:0], sqrt_remainder_nonzero_w);

  assign div_busy_o         = div_busy_w;
  assign sqrt_busy_o        = sqrt_busy_w;
  assign long_done_o        = div_done_w || sqrt_done_w;
  assign long_done_result_o = div_done_w ? div_value_w : sqrt_value_w;
  assign long_done_fflags_o = div_done_w ? div_fflags_w : sqrt_fflags_w;

endmodule
