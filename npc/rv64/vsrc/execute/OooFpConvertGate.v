`include "define.v"

// FP 转换（FCVT.int.fp / FCVT.fp.int / FCVT.S.D / FCVT.D.S）：
// 从 OooFpPendingExec 抽出的纯组合 owner。源/目的精度与 fp↔fp 判定由父模块从 funct7
// 算好后作为 src_double/dst_double/fpr_to_fpr 输入；int_fmt = inst[21:20]（W/WU/L/LU）、
// rm = inst[14:12]（舍入模式）。输出 fp→int(to_gpr) 与 int→fp / fp↔fp(to_fpr) 的
// value + fflags。行为与原 OooFpPendingExec 内联实现等价。
module OooFpConvertGate (
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] int_rs1_value_i,
  input              src_double_i,
  input              dst_double_i,
  input              fpr_to_fpr_i,
  input  [1:0]       int_fmt_i,
  input  [2:0]       rm_i,
  output [`XLEN-1:0] to_gpr_value_o,
  output [4:0]       to_gpr_fflags_o,
  output [`XLEN-1:0] to_fpr_value_o,
  output [4:0]       to_fpr_fflags_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  function [`XLEN-1:0] fp_int_to_d_value;
    input [`XLEN-1:0] value;
    input [1:0] src_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [63:0] src_ext;
    reg [63:0] mag;
    reg [5:0] msb_idx;
    reg [10:0] exp_bits;
    reg [63:0] shifted_mag;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg [51:0] frac_bits;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer shift_count;
    begin
      is_signed = (src_fmt == 2'b00) || (src_fmt == 2'b10);
      is_word = (src_fmt == 2'b00) || (src_fmt == 2'b01);
      if (is_word) begin
        src_ext = is_signed ? {{32{value[31]}}, value[31:0]} :
                              {32'b0, value[31:0]};
      end else begin
        src_ext = value;
      end
      sign = is_signed && src_ext[63];
      mag = sign ? (~src_ext + 64'd1) : src_ext;
      if (mag == 64'b0) begin
        fp_int_to_d_value = 64'b0;
      end else begin
        msb_idx = fp_u64_msb_index(mag);
        exp_bits = 11'd1023 + {5'b0, msb_idx};
        if (msb_idx <= 6'd52) begin
          shift_count = 52 - msb_idx;
          shifted_mag = mag << shift_count;
          frac_bits = shifted_mag[51:0];
        end else begin
          shift_count = msb_idx - 52;
          mant53 = mag >> shift_count;
          guard = mag[shift_count - 1];
          sticky_bit_count = shift_count - 1;
          sticky = fp_u64_low_or(mag, sticky_bit_count);
          inc = fp_round_increment(sign, rm, mant53[0], guard, sticky);
          mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
          if (mant_round_ext[53]) begin
            exp_bits = exp_bits + 11'd1;
            frac_bits = mant_round_ext[52:1];
          end else begin
            frac_bits = mant_round_ext[51:0];
          end
        end
        // 当前串行转换先覆盖 Ubuntu userland 常见 exact/RTZ 路径；全 fflags 后续再接 CSR。
        fp_int_to_d_value = {sign, exp_bits, frac_bits};
      end
    end
  endfunction

  function [`XLEN-1:0] fp_d_to_int_value;
    input [`XLEN-1:0] value;
    input [1:0] dst_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [10:0] exp;
    reg [51:0] frac;
    reg [52:0] sig;
    reg [64:0] sig_ext;
    reg [64:0] mag_ext;
    reg [64:0] int_part_ext;
    reg [64:0] max_pos_mag;
    reg [64:0] max_neg_mag;
    reg [63:0] sat_pos_value;
    reg [63:0] sat_neg_value;
    reg [63:0] signed_value;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer unbiased_exp;
    integer shift_count;
    begin
      is_signed = (dst_fmt == 2'b00) || (dst_fmt == 2'b10);
      is_word = (dst_fmt == 2'b00) || (dst_fmt == 2'b01);
      sign = value[63];
      exp = value[62:52];
      frac = value[51:0];
      if (is_word) begin
        max_pos_mag = is_signed ? 65'h0000000007fffffff :
                                  65'h000000000ffffffff;
        max_neg_mag = is_signed ? 65'h00000000080000000 :
                                  65'h00000000000000000;
        sat_pos_value = is_signed ? 64'h000000007fffffff :
                                    64'hffffffffffffffff;
        sat_neg_value = is_signed ? 64'hffffffff80000000 :
                                    64'h0000000000000000;
      end else begin
        max_pos_mag = is_signed ? 65'h07fffffffffffffff :
                                  65'h0ffffffffffffffff;
        max_neg_mag = is_signed ? 65'h08000000000000000 :
                                  65'h00000000000000000;
        sat_pos_value = is_signed ? 64'h7fffffffffffffff :
                                    64'hffffffffffffffff;
        sat_neg_value = is_signed ? 64'h8000000000000000 :
                                    64'h0000000000000000;
      end

      if (exp == 11'h7ff) begin
        if (frac != 52'b0) begin
          fp_d_to_int_value = sat_pos_value;
        end else begin
          fp_d_to_int_value = sign ? sat_neg_value : sat_pos_value;
        end
      end else begin
        if (exp == 11'h000) begin
          sig = {1'b0, frac};
          unbiased_exp = -1022;
        end else begin
          sig = {1'b1, frac};
          unbiased_exp = exp - 11'd1023;
        end
        sig_ext = {{12{1'b0}}, sig};
        if (unbiased_exp >= 64) begin
          mag_ext = 65'h10000000000000000;
        end else if (unbiased_exp >= 52) begin
          mag_ext = sig_ext << (unbiased_exp - 52);
        end else begin
          shift_count = 52 - unbiased_exp;
          if (shift_count > 53) begin
            int_part_ext = 65'b0;
            guard = 1'b0;
            sticky = |sig;
          end else begin
            int_part_ext = sig_ext >> shift_count;
            guard = sig[shift_count - 1];
            sticky_bit_count = shift_count - 1;
            sticky = fp_u64_low_or({11'b0, sig}, sticky_bit_count);
          end
          inc = fp_round_increment(sign, rm, int_part_ext[0], guard, sticky);
          mag_ext = int_part_ext + {{64{1'b0}}, inc};
        end

        if (!is_signed && sign && (mag_ext != 65'b0)) begin
          fp_d_to_int_value = sat_neg_value;
        end else if (sign) begin
          if (mag_ext > max_neg_mag) begin
            fp_d_to_int_value = sat_neg_value;
          end else begin
            signed_value = ~mag_ext[63:0] + 64'd1;
            fp_d_to_int_value = is_word ?
                {{32{signed_value[31]}}, signed_value[31:0]} :
                signed_value;
          end
        end else begin
          if (mag_ext > max_pos_mag) begin
            fp_d_to_int_value = sat_pos_value;
          end else begin
            fp_d_to_int_value = is_word ?
                {{32{mag_ext[31]}}, mag_ext[31:0]} :
                mag_ext[63:0];
          end
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_int_to_s_value;
    input [`XLEN-1:0] value;
    input [1:0] src_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [63:0] src_ext;
    reg [63:0] mag;
    reg [5:0] msb_idx;
    reg [7:0] exp_bits;
    reg [63:0] shifted_mag;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg [22:0] frac_bits;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer shift_count;
    begin
      is_signed = (src_fmt == 2'b00) || (src_fmt == 2'b10);
      is_word = (src_fmt == 2'b00) || (src_fmt == 2'b01);
      if (is_word) begin
        src_ext = is_signed ? {{32{value[31]}}, value[31:0]} :
                              {32'b0, value[31:0]};
      end else begin
        src_ext = value;
      end
      sign = is_signed && src_ext[63];
      mag = sign ? (~src_ext + 64'd1) : src_ext;
      if (mag == 64'b0) begin
        fp_int_to_s_value = {32'hffff_ffff, 32'b0};
      end else begin
        msb_idx = fp_u64_msb_index(mag);
        exp_bits = 8'd127 + {2'b0, msb_idx};
        if (msb_idx <= 6'd23) begin
          shift_count = 23 - msb_idx;
          shifted_mag = mag << shift_count;
          frac_bits = shifted_mag[22:0];
        end else begin
          shift_count = msb_idx - 23;
          mant24 = mag >> shift_count;
          guard = mag[shift_count - 1];
          sticky_bit_count = shift_count - 1;
          sticky = fp_u64_low_or(mag, sticky_bit_count);
          inc = fp_round_increment(sign, rm, mant24[0], guard, sticky);
          mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
          if (mant_round_ext[24]) begin
            exp_bits = exp_bits + 8'd1;
            frac_bits = mant_round_ext[23:1];
          end else begin
            frac_bits = mant_round_ext[22:0];
          end
        end
        fp_int_to_s_value = {32'hffff_ffff, sign, exp_bits, frac_bits};
      end
    end
  endfunction

  function [`XLEN-1:0] fp_s_to_int_value;
    input [`XLEN-1:0] value;
    input [1:0] dst_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [23:0] sig;
    reg [64:0] sig_ext;
    reg [64:0] mag_ext;
    reg [64:0] int_part_ext;
    reg [64:0] max_pos_mag;
    reg [64:0] max_neg_mag;
    reg [63:0] sat_pos_value;
    reg [63:0] sat_neg_value;
    reg [63:0] signed_value;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer unbiased_exp;
    integer shift_count;
    begin
      is_signed = (dst_fmt == 2'b00) || (dst_fmt == 2'b10);
      is_word = (dst_fmt == 2'b00) || (dst_fmt == 2'b01);
      sign = value[31];
      exp = value[30:23];
      frac = value[22:0];
      if (is_word) begin
        max_pos_mag = is_signed ? 65'h0000000007fffffff :
                                  65'h000000000ffffffff;
        max_neg_mag = is_signed ? 65'h00000000080000000 :
                                  65'h00000000000000000;
        sat_pos_value = is_signed ? 64'h000000007fffffff :
                                    64'hffffffffffffffff;
        sat_neg_value = is_signed ? 64'hffffffff80000000 :
                                    64'h0000000000000000;
      end else begin
        max_pos_mag = is_signed ? 65'h07fffffffffffffff :
                                  65'h0ffffffffffffffff;
        max_neg_mag = is_signed ? 65'h08000000000000000 :
                                  65'h00000000000000000;
        sat_pos_value = is_signed ? 64'h7fffffffffffffff :
                                    64'hffffffffffffffff;
        sat_neg_value = is_signed ? 64'h8000000000000000 :
                                    64'h0000000000000000;
      end

      if (fp_is_nan_s_value(value)) begin
        fp_s_to_int_value = sat_pos_value;
      end else if (exp == 8'hff) begin
        fp_s_to_int_value = sign ? sat_neg_value : sat_pos_value;
      end else begin
        if (exp == 8'h00) begin
          sig = {1'b0, frac};
          unbiased_exp = -126;
        end else begin
          sig = {1'b1, frac};
          unbiased_exp = exp - 8'd127;
        end
        sig_ext = {{41{1'b0}}, sig};
        if (unbiased_exp >= 64) begin
          mag_ext = 65'h10000000000000000;
        end else if (unbiased_exp >= 23) begin
          mag_ext = sig_ext << (unbiased_exp - 23);
        end else begin
          shift_count = 23 - unbiased_exp;
          if (shift_count > 24) begin
            int_part_ext = 65'b0;
            guard = 1'b0;
            sticky = |sig;
          end else begin
            int_part_ext = sig_ext >> shift_count;
            guard = sig[shift_count - 1];
            sticky_bit_count = shift_count - 1;
            sticky = fp_u64_low_or({40'b0, sig}, sticky_bit_count);
          end
          inc = fp_round_increment(sign, rm, int_part_ext[0], guard, sticky);
          mag_ext = int_part_ext + {{64{1'b0}}, inc};
        end

        if (!is_signed && sign && (mag_ext != 65'b0)) begin
          fp_s_to_int_value = sat_neg_value;
        end else if (sign) begin
          if (mag_ext > max_neg_mag) begin
            fp_s_to_int_value = sat_neg_value;
          end else begin
            signed_value = ~mag_ext[63:0] + 64'd1;
            fp_s_to_int_value = is_word ?
                {{32{signed_value[31]}}, signed_value[31:0]} :
                signed_value;
          end
        end else begin
          if (mag_ext > max_pos_mag) begin
            fp_s_to_int_value = sat_pos_value;
          end else begin
            fp_s_to_int_value = is_word ?
                {{32{mag_ext[31]}}, mag_ext[31:0]} :
                mag_ext[63:0];
          end
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_s_to_d_value;
    input [`XLEN-1:0] value;
    reg sign;
    reg [7:0] exp_s;
    reg [22:0] frac_s;
    reg [23:0] sig_s;
    reg [4:0] norm_shift;
    reg [10:0] exp_d;
    integer unbiased_exp;
    begin
      sign = value[31];
      exp_s = value[30:23];
      frac_s = value[22:0];
      if (fp_is_nan_s_value(value)) begin
        fp_s_to_d_value = 64'h7ff8000000000000;
      end else if (exp_s == 8'hff) begin
        fp_s_to_d_value = {sign, 11'h7ff, 52'b0};
      end else if ((exp_s == 8'h00) && (frac_s == 23'b0)) begin
        fp_s_to_d_value = {sign, 63'b0};
      end else begin
        if (exp_s == 8'h00) begin
          sig_s = {1'b0, frac_s};
          norm_shift = fp_norm_shift_24(sig_s);
          sig_s = sig_s << norm_shift;
          unbiased_exp = -126 - norm_shift;
        end else begin
          sig_s = {1'b1, frac_s};
          unbiased_exp = exp_s - 8'd127;
        end
        exp_d = unbiased_exp + 11'd1023;
        fp_s_to_d_value = {sign, exp_d, sig_s[22:0], 29'b0};
      end
    end
  endfunction

  function [`XLEN-1:0] fp_d_to_s_value;
    input [`XLEN-1:0] value;
    input [2:0] rm;
    reg sign;
    reg [10:0] exp_d;
    reg [51:0] frac_d;
    reg [52:0] sig_d;
    reg [5:0] norm_shift;
    reg [55:0] sig_ext;
    reg [55:0] shifted;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg [22:0] frac_s;
    reg [6:0] shift_amt;
    reg guard;
    reg sticky;
    reg inc;
    integer unbiased_exp;
    integer exp_s;
    integer shift_count;
    begin
      sign = value[63];
      exp_d = value[62:52];
      frac_d = value[51:0];
      if (fp_is_nan_d_value(value)) begin
        fp_d_to_s_value = 64'hffffffff7fc00000;
      end else if (exp_d == 11'h7ff) begin
        fp_d_to_s_value = {32'hffff_ffff, sign, 8'hff, 23'b0};
      end else if ((exp_d == 11'h000) && (frac_d == 52'b0)) begin
        fp_d_to_s_value = {32'hffff_ffff, sign, 31'b0};
      end else begin
        if (exp_d == 11'h000) begin
          sig_d = {1'b0, frac_d};
          norm_shift = fp_norm_shift_53(sig_d);
          sig_d = sig_d << norm_shift;
          unbiased_exp = -1022 - norm_shift;
        end else begin
          sig_d = {1'b1, frac_d};
          unbiased_exp = exp_d - 11'd1023;
        end

        exp_s = unbiased_exp + 127;
        shift_count = 29;
        if (exp_s < 1) begin
          shift_count = shift_count + (1 - exp_s);
          exp_s = 1;
        end
        if (shift_count >= 56)
          shift_amt = 7'd56;
        else
          shift_amt = shift_count;

        sig_ext = {sig_d, 3'b000};
        shifted = fp_shift_right_jam_56(sig_ext, shift_amt);
        mant24 = shifted[26:3];
        guard = shifted[2];
        sticky = shifted[1] | shifted[0];
        inc = fp_round_increment(sign, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          exp_s = exp_s + 1;
          frac_s = mant_round_ext[23:1];
        end else begin
          mant24 = mant_round_ext[23:0];
          frac_s = mant_round_ext[22:0];
        end

        if (exp_s >= 255) begin
          fp_d_to_s_value = fp_overflow_s(sign, rm);
        end else if ((exp_s <= 1) && !mant24[23]) begin
          fp_d_to_s_value = {32'hffff_ffff, sign, 8'b0, frac_s};
        end else begin
          fp_d_to_s_value = {32'hffff_ffff, sign, exp_s[7:0], frac_s};
        end
      end
    end
  endfunction

  function [4:0] fp_s_to_int_fflags;
    input [`XLEN-1:0] value;
    input [1:0] dst_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [7:0] exp;
    reg [22:0] frac;
    reg [23:0] sig;
    reg [64:0] sig_ext;
    reg [64:0] mag_ext;
    reg [64:0] int_part_ext;
    reg [64:0] max_pos_mag;
    reg [64:0] max_neg_mag;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer unbiased_exp;
    integer shift_count;
    begin
      is_signed = (dst_fmt == 2'b00) || (dst_fmt == 2'b10);
      is_word = (dst_fmt == 2'b00) || (dst_fmt == 2'b01);
      sign = value[31];
      exp = value[30:23];
      frac = value[22:0];
      fp_s_to_int_fflags = 5'b00000;
      if (is_word) begin
        max_pos_mag = is_signed ? 65'h0000000007fffffff :
                                  65'h000000000ffffffff;
        max_neg_mag = is_signed ? 65'h00000000080000000 :
                                  65'h00000000000000000;
      end else begin
        max_pos_mag = is_signed ? 65'h07fffffffffffffff :
                                  65'h0ffffffffffffffff;
        max_neg_mag = is_signed ? 65'h08000000000000000 :
                                  65'h00000000000000000;
      end
      if (fp_is_nan_s_value(value) || (exp == 8'hff)) begin
        fp_s_to_int_fflags = `FP_FLAG_NV;
      end else begin
        if (exp == 8'h00) begin
          sig = {1'b0, frac};
          unbiased_exp = -126;
        end else begin
          sig = {1'b1, frac};
          unbiased_exp = exp - 8'd127;
        end
        sig_ext = {{41{1'b0}}, sig};
        if (unbiased_exp >= 64) begin
          mag_ext = 65'h10000000000000000;
          guard = 1'b0;
          sticky = 1'b0;
        end else if (unbiased_exp >= 23) begin
          mag_ext = sig_ext << (unbiased_exp - 23);
          guard = 1'b0;
          sticky = 1'b0;
        end else begin
          shift_count = 23 - unbiased_exp;
          if (shift_count > 24) begin
            int_part_ext = 65'b0;
            guard = 1'b0;
            sticky = |sig;
          end else begin
            int_part_ext = sig_ext >> shift_count;
            guard = sig[shift_count - 1];
            sticky_bit_count = shift_count - 1;
            sticky = fp_u64_low_or({40'b0, sig}, sticky_bit_count);
          end
          inc = fp_round_increment(sign, rm, int_part_ext[0], guard, sticky);
          mag_ext = int_part_ext + {{64{1'b0}}, inc};
        end
        if ((!is_signed && sign && (mag_ext != 65'b0)) ||
            (sign && (mag_ext > max_neg_mag)) ||
            (!sign && (mag_ext > max_pos_mag))) begin
          fp_s_to_int_fflags = `FP_FLAG_NV;
        end else if (guard || sticky) begin
          fp_s_to_int_fflags = `FP_FLAG_NX;
        end
      end
    end
  endfunction

  function [4:0] fp_d_to_int_fflags;
    input [`XLEN-1:0] value;
    input [1:0] dst_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [10:0] exp;
    reg [51:0] frac;
    reg [52:0] sig;
    reg [64:0] sig_ext;
    reg [64:0] mag_ext;
    reg [64:0] int_part_ext;
    reg [64:0] max_pos_mag;
    reg [64:0] max_neg_mag;
    reg guard;
    reg sticky;
    reg inc;
    reg [6:0] sticky_bit_count;
    integer unbiased_exp;
    integer shift_count;
    begin
      is_signed = (dst_fmt == 2'b00) || (dst_fmt == 2'b10);
      is_word = (dst_fmt == 2'b00) || (dst_fmt == 2'b01);
      sign = value[63];
      exp = value[62:52];
      frac = value[51:0];
      fp_d_to_int_fflags = 5'b00000;
      if (is_word) begin
        max_pos_mag = is_signed ? 65'h0000000007fffffff :
                                  65'h000000000ffffffff;
        max_neg_mag = is_signed ? 65'h00000000080000000 :
                                  65'h00000000000000000;
      end else begin
        max_pos_mag = is_signed ? 65'h07fffffffffffffff :
                                  65'h0ffffffffffffffff;
        max_neg_mag = is_signed ? 65'h08000000000000000 :
                                  65'h00000000000000000;
      end
      if (fp_is_nan_d_value(value) || (exp == 11'h7ff)) begin
        fp_d_to_int_fflags = `FP_FLAG_NV;
      end else begin
        if (exp == 11'h000) begin
          sig = {1'b0, frac};
          unbiased_exp = -1022;
        end else begin
          sig = {1'b1, frac};
          unbiased_exp = exp - 11'd1023;
        end
        sig_ext = {{12{1'b0}}, sig};
        guard = 1'b0;
        sticky = 1'b0;
        if (unbiased_exp >= 64) begin
          mag_ext = 65'h10000000000000000;
        end else if (unbiased_exp >= 52) begin
          mag_ext = sig_ext << (unbiased_exp - 52);
        end else begin
          shift_count = 52 - unbiased_exp;
          if (shift_count > 53) begin
            int_part_ext = 65'b0;
            guard = 1'b0;
            sticky = |sig;
          end else begin
            int_part_ext = sig_ext >> shift_count;
            guard = sig[shift_count - 1];
            sticky_bit_count = shift_count - 1;
            sticky = fp_u64_low_or({11'b0, sig}, sticky_bit_count);
          end
          inc = fp_round_increment(sign, rm, int_part_ext[0], guard, sticky);
          mag_ext = int_part_ext + {{64{1'b0}}, inc};
        end
        if ((!is_signed && sign && (mag_ext != 65'b0)) ||
            (sign && (mag_ext > max_neg_mag)) ||
            (!sign && (mag_ext > max_pos_mag))) begin
          fp_d_to_int_fflags = `FP_FLAG_NV;
        end else if (guard || sticky) begin
          fp_d_to_int_fflags = `FP_FLAG_NX;
        end
      end
    end
  endfunction

  function [4:0] fp_int_to_s_fflags;
    input [`XLEN-1:0] value;
    input [1:0] src_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [63:0] src_ext;
    reg [63:0] mag;
    reg [5:0] msb_idx;
    reg guard;
    reg sticky;
    reg inc_unused;
    reg [6:0] sticky_bit_count;
    integer shift_count;
    begin
      is_signed = (src_fmt == 2'b00) || (src_fmt == 2'b10);
      is_word = (src_fmt == 2'b00) || (src_fmt == 2'b01);
      src_ext = is_word ?
          (is_signed ? {{32{value[31]}}, value[31:0]} :
                       {32'b0, value[31:0]}) :
          value;
      sign = is_signed && src_ext[63];
      mag = sign ? (~src_ext + 64'd1) : src_ext;
      fp_int_to_s_fflags = 5'b00000;
      if (mag != 64'b0) begin
        msb_idx = fp_u64_msb_index(mag);
        if (msb_idx > 6'd23) begin
          shift_count = msb_idx - 23;
          guard = mag[shift_count - 1];
          sticky_bit_count = shift_count - 1;
          sticky = fp_u64_low_or(mag, sticky_bit_count);
          inc_unused = fp_round_increment(sign, rm, 1'b0, guard, sticky);
          if (guard || sticky || inc_unused)
            fp_int_to_s_fflags = `FP_FLAG_NX;
        end
      end
    end
  endfunction

  function [4:0] fp_int_to_d_fflags;
    input [`XLEN-1:0] value;
    input [1:0] src_fmt;
    input [2:0] rm;
    reg is_signed;
    reg is_word;
    reg sign;
    reg [63:0] src_ext;
    reg [63:0] mag;
    reg [5:0] msb_idx;
    reg guard;
    reg sticky;
    reg inc_unused;
    reg [6:0] sticky_bit_count;
    integer shift_count;
    begin
      is_signed = (src_fmt == 2'b00) || (src_fmt == 2'b10);
      is_word = (src_fmt == 2'b00) || (src_fmt == 2'b01);
      src_ext = is_word ?
          (is_signed ? {{32{value[31]}}, value[31:0]} :
                       {32'b0, value[31:0]}) :
          value;
      sign = is_signed && src_ext[63];
      mag = sign ? (~src_ext + 64'd1) : src_ext;
      fp_int_to_d_fflags = 5'b00000;
      if (mag != 64'b0) begin
        msb_idx = fp_u64_msb_index(mag);
        if (msb_idx > 6'd52) begin
          shift_count = msb_idx - 52;
          guard = mag[shift_count - 1];
          sticky_bit_count = shift_count - 1;
          sticky = fp_u64_low_or(mag, sticky_bit_count);
          inc_unused = fp_round_increment(sign, rm, 1'b0, guard, sticky);
          if (guard || sticky || inc_unused)
            fp_int_to_d_fflags = `FP_FLAG_NX;
        end
      end
    end
  endfunction

  function [4:0] fp_d_to_s_fflags;
    input [`XLEN-1:0] value;
    input [2:0] rm;
    reg sign;
    reg [10:0] exp_d;
    reg [51:0] frac_d;
    reg [52:0] sig_d;
    reg [5:0] norm_shift;
    reg [55:0] sig_ext;
    reg [55:0] shifted;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg [6:0] shift_amt;
    reg guard;
    reg sticky;
    reg inc;
    integer unbiased_exp;
    integer exp_s;
    integer shift_count;
    begin
      sign = value[63];
      exp_d = value[62:52];
      frac_d = value[51:0];
      fp_d_to_s_fflags = 5'b00000;
      if (fp_is_snan_d_value(value)) begin
        fp_d_to_s_fflags = `FP_FLAG_NV;
      end else if (!(fp_is_nan_d_value(value) ||
                   fp_is_inf_d_value(value) ||
                   fp_is_zero_d_value(value))) begin
        if (exp_d == 11'h000) begin
          sig_d = {1'b0, frac_d};
          norm_shift = fp_norm_shift_53(sig_d);
          sig_d = sig_d << norm_shift;
          unbiased_exp = -1022 - norm_shift;
        end else begin
          sig_d = {1'b1, frac_d};
          unbiased_exp = exp_d - 11'd1023;
        end
        exp_s = unbiased_exp + 127;
        shift_count = 29;
        if (exp_s < 1) begin
          shift_count = shift_count + (1 - exp_s);
          exp_s = 1;
        end
        if (shift_count >= 56)
          shift_amt = 7'd56;
        else
          shift_amt = shift_count;
        sig_ext = {sig_d, 3'b000};
        shifted = fp_shift_right_jam_56(sig_ext, shift_amt);
        mant24 = shifted[26:3];
        guard = shifted[2];
        sticky = shifted[1] | shifted[0];
        inc = fp_round_increment(sign, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin
          exp_s = exp_s + 1;
          mant24 = mant_round_ext[24:1];
        end else begin
          mant24 = mant_round_ext[23:0];
        end
        if (exp_s >= 255) begin
          fp_d_to_s_fflags = `FP_FLAG_OF | `FP_FLAG_NX;
        end else begin
          fp_d_to_s_fflags = fp_round_flags_s(sign, exp_s[7:0],
                                              mant24, guard, sticky);
        end
      end
    end
  endfunction

  // fp -> int（FCVT.W/WU/L/LU.S/D）
  assign to_gpr_value_o = src_double_i ?
      fp_d_to_int_value(frs1_value_i, int_fmt_i, rm_i) :
      fp_s_to_int_value(frs1_value_i, int_fmt_i, rm_i);
  assign to_gpr_fflags_o = src_double_i ?
      fp_d_to_int_fflags(frs1_value_i, int_fmt_i, rm_i) :
      fp_s_to_int_fflags(frs1_value_i, int_fmt_i, rm_i);

  // int -> fp（FCVT.S/D.W/WU/L/LU）
  wire [`XLEN-1:0] int_to_fpr_value_w = dst_double_i ?
      fp_int_to_d_value(int_rs1_value_i, int_fmt_i, rm_i) :
      fp_int_to_s_value(int_rs1_value_i, int_fmt_i, rm_i);
  wire [4:0] int_to_fpr_fflags_w = dst_double_i ?
      fp_int_to_d_fflags(int_rs1_value_i, int_fmt_i, rm_i) :
      fp_int_to_s_fflags(int_rs1_value_i, int_fmt_i, rm_i);

  // fp -> fp（FCVT.D.S 升精度 / FCVT.S.D 降精度）
  wire [`XLEN-1:0] fpr_to_fpr_value_w = dst_double_i ?
      fp_s_to_d_value(frs1_value_i) :
      fp_d_to_s_value(frs1_value_i, rm_i);
  wire [4:0] fpr_to_fpr_fflags_w = dst_double_i ?
      (fp_is_snan_s_value(frs1_value_i) ? `FP_FLAG_NV : 5'b00000) :
      fp_d_to_s_fflags(frs1_value_i, rm_i);

  assign to_fpr_value_o  = fpr_to_fpr_i ? fpr_to_fpr_value_w  : int_to_fpr_value_w;
  assign to_fpr_fflags_o = fpr_to_fpr_i ? fpr_to_fpr_fflags_w : int_to_fpr_fflags_w;

endmodule
