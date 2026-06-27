`include "define.v"

// FP pending 执行数据通路：父模块仍持有 pending/FPR/commit 时序，
// 本模块只负责组合结果、fflags 和 FDIV/FSQRT 迭代单元包装。
module OooFpPendingExec (
  input clk,
  input rst,
  input flush_i,
  input pending_valid_i,
  input [`INST_W-1:0] inst_i,
  input load_i,
  input store_i,
  input double_i,
  input gpr_write_i,
  input [`XLEN-1:0] int_rs1_value_i,
  input [`XLEN-1:0] frs1_value_i,
  input [`XLEN-1:0] frs2_value_i,
  input [`XLEN-1:0] frs3_value_i,
  input long_start_i,

  output long_op_o,
  output compute_op_o,
  output div_busy_o,
  output sqrt_busy_o,
  output long_done_o,
  output [`XLEN-1:0] long_done_result_o,
  output [4:0] long_done_fflags_o,
  output [`XLEN-1:0] mem_addr_o,
  output [`XLEN-1:0] mem_aligned_addr_o,
  output [`XLEN-1:0] mem_wdata_o,
  output [`STRB_W-1:0] mem_wstrb_o,
  output [`XLEN-1:0] compute_value_o,
  output [4:0] compute_fflags_o
);

  localparam [6:0] FP_FUNCT7_FADD_S     = 7'b0000000;
  localparam [6:0] FP_FUNCT7_FADD_D     = 7'b0000001;
  localparam [6:0] FP_FUNCT7_FSUB_S     = 7'b0000100;
  localparam [6:0] FP_FUNCT7_FSUB_D     = 7'b0000101;
  localparam [6:0] FP_FUNCT7_FMUL_S     = 7'b0001000;
  localparam [6:0] FP_FUNCT7_FMUL_D     = 7'b0001001;
  localparam [6:0] FP_FUNCT7_FDIV_S     = 7'b0001100;
  localparam [6:0] FP_FUNCT7_FDIV_D     = 7'b0001101;
  localparam [6:0] FP_FUNCT7_FSQRT_S    = 7'b0101100;
  localparam [6:0] FP_FUNCT7_FSQRT_D    = 7'b0101101;
  localparam [6:0] FP_FUNCT7_FSGNJ_S    = 7'b0010000;
  localparam [6:0] FP_FUNCT7_FSGNJ_D    = 7'b0010001;
  localparam [6:0] FP_FUNCT7_FMINMAX_S  = 7'b0010100;
  localparam [6:0] FP_FUNCT7_FMINMAX_D  = 7'b0010101;
  localparam [6:0] FP_FUNCT7_FCVT_S_D   = 7'b0100000;
  localparam [6:0] FP_FUNCT7_FCVT_D_S   = 7'b0100001;
  localparam [6:0] FP_FUNCT7_FCMP_S     = 7'b1010000;
  localparam [6:0] FP_FUNCT7_FCMP_D     = 7'b1010001;
  localparam [6:0] FP_FUNCT7_FCVT_INT_S = 7'b1101000;
  localparam [6:0] FP_FUNCT7_FCVT_INT_D = 7'b1101001;
  localparam [6:0] FP_FUNCT7_FCVT_S_INT = 7'b1100000;
  localparam [6:0] FP_FUNCT7_FCVT_D_INT = 7'b1100001;
  localparam [6:0] FP_FUNCT7_FMV_X_W    = 7'b1110000;
  localparam [6:0] FP_FUNCT7_FMV_X_D    = 7'b1110001;
  localparam [4:0] FP_FLAG_NV = 5'b10000;
  localparam [4:0] FP_FLAG_DZ = 5'b01000;
  localparam [4:0] FP_FLAG_OF = 5'b00100;
  localparam [4:0] FP_FLAG_UF = 5'b00010;
  localparam [4:0] FP_FLAG_NX = 5'b00001;

  function [`XLEN-1:0] fp_i_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_i_imm = {{(`XLEN-12){inst[31]}}, inst[31:20]};
    end
  endfunction

  function [`XLEN-1:0] fp_s_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_s_imm = {{(`XLEN-12){inst[31]}}, inst[31:25], inst[11:7]};
    end
  endfunction

  function [`XLEN-1:0] fp_aligned_addr;
    input [`XLEN-1:0] addr;
    begin
      fp_aligned_addr = addr & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}};
    end
  endfunction

  function [`STRB_W-1:0] fp_store_wstrb;
    input [`XLEN-1:0] addr;
    input is_double;
    begin
      fp_store_wstrb = is_double ? {`STRB_W{1'b1}} :
                       ({{(`STRB_W-4){1'b0}}, 4'b1111} << addr[`XLEN_BYTE_W-1:0]);
    end
  endfunction

  function [`XLEN-1:0] fp_store_wdata;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_store_wdata = is_double ? value :
                       ({{32{1'b0}}, value[31:0]} << {addr[`XLEN_BYTE_W-1:0], 3'b000});
    end
  endfunction

  function [`XLEN-1:0] fp_move_to_gpr_value;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_move_to_gpr_value = is_double ? value :
                             {{32{value[31]}}, value[31:0]};
    end
  endfunction

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

  function fp_round_increment;
    input sign;
    input [2:0] rm;
    input lsb;
    input guard;
    input sticky;
    begin
      case (rm)
        3'b000,
        3'b111: fp_round_increment = guard && (sticky || lsb);
        3'b001: fp_round_increment = 1'b0;
        3'b010: fp_round_increment = sign && (guard || sticky);
        3'b011: fp_round_increment = !sign && (guard || sticky);
        3'b100: fp_round_increment = guard;
        default: fp_round_increment = guard && (sticky || lsb);
      endcase
    end
  endfunction

  function [5:0] fp_u64_msb_index;
    input [63:0] value;
    reg [31:0] stage32;
    reg [15:0] stage16;
    reg [7:0] stage8;
    reg [3:0] stage4;
    reg [1:0] stage2;
    begin
      fp_u64_msb_index[5] = |value[63:32];
      stage32 = fp_u64_msb_index[5] ? value[63:32] : value[31:0];
      fp_u64_msb_index[4] = |stage32[31:16];
      stage16 = fp_u64_msb_index[4] ? stage32[31:16] : stage32[15:0];
      fp_u64_msb_index[3] = |stage16[15:8];
      stage8 = fp_u64_msb_index[3] ? stage16[15:8] : stage16[7:0];
      fp_u64_msb_index[2] = |stage8[7:4];
      stage4 = fp_u64_msb_index[2] ? stage8[7:4] : stage8[3:0];
      fp_u64_msb_index[1] = |stage4[3:2];
      stage2 = fp_u64_msb_index[1] ? stage4[3:2] : stage4[1:0];
      fp_u64_msb_index[0] = stage2[1];
    end
  endfunction

  // byte 级 sticky 选择器用于 FP 转换舍入，避免函数内逐 bit 循环扫描低位。
  function fp_u64_low_or;
    input [63:0] value;
    input [6:0] bit_count;
    reg [7:0] byte_or;
    reg [7:0] partial_byte;
    reg full_byte_or;
    reg partial_or;
    begin
      byte_or[0] = |value[7:0];
      byte_or[1] = |value[15:8];
      byte_or[2] = |value[23:16];
      byte_or[3] = |value[31:24];
      byte_or[4] = |value[39:32];
      byte_or[5] = |value[47:40];
      byte_or[6] = |value[55:48];
      byte_or[7] = |value[63:56];

      case (bit_count[6:3])
        4'd0: full_byte_or = 1'b0;
        4'd1: full_byte_or = byte_or[0];
        4'd2: full_byte_or = |byte_or[1:0];
        4'd3: full_byte_or = |byte_or[2:0];
        4'd4: full_byte_or = |byte_or[3:0];
        4'd5: full_byte_or = |byte_or[4:0];
        4'd6: full_byte_or = |byte_or[5:0];
        4'd7: full_byte_or = |byte_or[6:0];
        default: full_byte_or = |byte_or;
      endcase

      case (bit_count[6:3])
        4'd0: partial_byte = value[7:0];
        4'd1: partial_byte = value[15:8];
        4'd2: partial_byte = value[23:16];
        4'd3: partial_byte = value[31:24];
        4'd4: partial_byte = value[39:32];
        4'd5: partial_byte = value[47:40];
        4'd6: partial_byte = value[55:48];
        4'd7: partial_byte = value[63:56];
        default: partial_byte = 8'b0;
      endcase

      case (bit_count[2:0])
        3'd0: partial_or = 1'b0;
        3'd1: partial_or = partial_byte[0];
        3'd2: partial_or = |partial_byte[1:0];
        3'd3: partial_or = |partial_byte[2:0];
        3'd4: partial_or = |partial_byte[3:0];
        3'd5: partial_or = |partial_byte[4:0];
        3'd6: partial_or = |partial_byte[5:0];
        default: partial_or = |partial_byte[6:0];
      endcase

      fp_u64_low_or = full_byte_or | partial_or;
    end
  endfunction

  function [6:0] fp_lzc_64;
    input [63:0] value;
    reg [31:0] stage32;
    reg [15:0] stage16;
    reg [7:0] stage8;
    reg [3:0] stage4;
    reg [1:0] stage2;
    begin
      if (value == 64'b0) begin
        fp_lzc_64 = 7'd64;
      end else begin
        fp_lzc_64 = 7'd0;
        fp_lzc_64[5] = ~|value[63:32];
        stage32 = fp_lzc_64[5] ? value[31:0] : value[63:32];
        fp_lzc_64[4] = ~|stage32[31:16];
        stage16 = fp_lzc_64[4] ? stage32[15:0] : stage32[31:16];
        fp_lzc_64[3] = ~|stage16[15:8];
        stage8 = fp_lzc_64[3] ? stage16[7:0] : stage16[15:8];
        fp_lzc_64[2] = ~|stage8[7:4];
        stage4 = fp_lzc_64[2] ? stage8[3:0] : stage8[7:4];
        fp_lzc_64[1] = ~|stage4[3:2];
        stage2 = fp_lzc_64[1] ? stage4[1:0] : stage4[3:2];
        fp_lzc_64[0] = ~stage2[1];
      end
    end
  endfunction

  function [6:0] fp_lzc_56;
    input [55:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 8'b0});
      fp_lzc_56 = (count > 7'd56) ? 7'd56 : count;
    end
  endfunction

  function [5:0] fp_lzc_27;
    input [26:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 37'b0});
      fp_lzc_27 = (count > 7'd27) ? 6'd27 : count[5:0];
    end
  endfunction

  // 乘法规格化复用宽 LZC 树，避免 product normalize 继续展开逐 bit 左移循环。
  function [7:0] fp_lzc_128;
    input [127:0] value;
    reg [6:0] high_count;
    reg [6:0] low_count;
    begin
      high_count = fp_lzc_64(value[127:64]);
      low_count = fp_lzc_64(value[63:0]);
      fp_lzc_128 = (high_count != 7'd64) ?
                   {1'b0, high_count} : (8'd64 + {1'b0, low_count});
    end
  endfunction

  function [7:0] fp_lzc_106;
    input [105:0] value;
    reg [7:0] count;
    begin
      count = fp_lzc_128({value, 22'b0});
      fp_lzc_106 = (count > 8'd106) ? 8'd106 : count;
    end
  endfunction

  function [5:0] fp_lzc_48;
    input [47:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 16'b0});
      fp_lzc_48 = (count > 7'd48) ? 6'd48 : count[5:0];
    end
  endfunction

  // FSQRT subnormal normalize 只允许旧循环上界内的左移次数。
  function [5:0] fp_norm_shift_53;
    input [52:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 11'b0});
      fp_norm_shift_53 = (count > 7'd52) ? 6'd52 : count[5:0];
    end
  endfunction

  function [4:0] fp_norm_shift_24;
    input [23:0] value;
    reg [6:0] count;
    begin
      count = fp_lzc_64({value, 40'b0});
      fp_norm_shift_24 = (count > 7'd23) ? 5'd23 : count[4:0];
    end
  endfunction

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
          fp_d_to_s_value = {32'hffff_ffff, sign, 8'hff, 23'b0};
        end else if ((exp_s <= 1) && !mant24[23]) begin
          fp_d_to_s_value = {32'hffff_ffff, sign, 8'b0, frac_s};
        end else begin
          fp_d_to_s_value = {32'hffff_ffff, sign, exp_s[7:0], frac_s};
        end
      end
    end
  endfunction

  function [`XLEN-1:0] fp_sgnj_value;
    input [`XLEN-1:0] rs1_value;
    input [`XLEN-1:0] rs2_value;
    input is_double;
    input [2:0] op;
    reg sign_bit;
    reg [31:0] rs1_single_bits;
    reg [31:0] rs2_single_bits;
    reg [31:0] single_bits;
    begin
      if (is_double) begin
        case (op)
          3'b000: sign_bit = rs2_value[63];
          3'b001: sign_bit = ~rs2_value[63];
          3'b010: sign_bit = rs1_value[63] ^ rs2_value[63];
          default: sign_bit = rs1_value[63];
        endcase
        fp_sgnj_value = {sign_bit, rs1_value[62:0]};
      end else begin
        rs1_single_bits = fp_is_boxed_s_value(rs1_value) ?
                          rs1_value[31:0] : 32'h7fc0_0000;
        rs2_single_bits = fp_is_boxed_s_value(rs2_value) ?
                          rs2_value[31:0] : 32'h7fc0_0000;
        case (op)
          3'b000: sign_bit = rs2_single_bits[31];
          3'b001: sign_bit = ~rs2_single_bits[31];
          3'b010: sign_bit = rs1_single_bits[31] ^ rs2_single_bits[31];
          default: sign_bit = rs1_single_bits[31];
        endcase
        single_bits = {sign_bit, rs1_single_bits[30:0]};
        fp_sgnj_value = {32'hffff_ffff, single_bits};
      end
    end
  endfunction

  function fp_is_nan_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_nan_s_value =
          (value[63:32] != 32'hffff_ffff) ||
          ((value[30:23] == 8'hff) && (value[22:0] != 23'b0));
    end
  endfunction

  function fp_is_nan_d_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_nan_d_value =
          (value[62:52] == 11'h7ff) && (value[51:0] != 52'b0);
    end
  endfunction

  function fp_is_boxed_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_boxed_s_value = (value[63:32] == 32'hffff_ffff);
    end
  endfunction

  function fp_is_snan_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_snan_s_value =
          fp_is_boxed_s_value(value) &&
          (value[30:23] == 8'hff) &&
          (value[22:0] != 23'b0) &&
          !value[22];
    end
  endfunction

  function fp_is_snan_d_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_snan_d_value =
          (value[62:52] == 11'h7ff) &&
          (value[51:0] != 52'b0) &&
          !value[51];
    end
  endfunction

  function fp_is_inf_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_inf_s_value =
          fp_is_boxed_s_value(value) &&
          (value[30:23] == 8'hff) &&
          (value[22:0] == 23'b0);
    end
  endfunction

  function fp_is_zero_s_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_zero_s_value =
          fp_is_boxed_s_value(value) &&
          (value[30:23] == 8'h00) &&
          (value[22:0] == 23'b0);
    end
  endfunction

  function fp_is_inf_d_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_inf_d_value =
          (value[62:52] == 11'h7ff) &&
          (value[51:0] == 52'b0);
    end
  endfunction

  function fp_is_zero_d_value;
    input [`XLEN-1:0] value;
    begin
      fp_is_zero_d_value =
          (value[62:52] == 11'h000) &&
          (value[51:0] == 52'b0);
    end
  endfunction

  function [4:0] fp_round_flags_s;
    input sign;
    input [7:0] exp_z;
    input [23:0] mant24;
    input guard;
    input sticky;
    reg inexact;
    begin
      inexact = guard | sticky;
      fp_round_flags_s = 5'b00000;
      if (exp_z >= 8'hff) begin
        fp_round_flags_s = FP_FLAG_OF | FP_FLAG_NX;
      end else if ((exp_z == 8'd1) && !mant24[23] && inexact) begin
        fp_round_flags_s = FP_FLAG_UF | FP_FLAG_NX;
      end else if (inexact) begin
        fp_round_flags_s = FP_FLAG_NX;
      end
    end
  endfunction

  function [4:0] fp_round_flags_d;
    input sign;
    input [10:0] exp_z;
    input [52:0] mant53;
    input guard;
    input sticky;
    reg inexact;
    begin
      inexact = guard | sticky;
      fp_round_flags_d = 5'b00000;
      if (exp_z >= 11'h7ff) begin
        fp_round_flags_d = FP_FLAG_OF | FP_FLAG_NX;
      end else if ((exp_z == 11'd1) && !mant53[52] && inexact) begin
        fp_round_flags_d = FP_FLAG_UF | FP_FLAG_NX;
      end else if (inexact) begin
        fp_round_flags_d = FP_FLAG_NX;
      end
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
        fp_addsub_s_fflags = FP_FLAG_NV;
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
        fp_mul_s_fflags = FP_FLAG_NV;
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
          fp_mul_s_fflags = FP_FLAG_OF | FP_FLAG_NX;
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
        fp_div_s_fflags = FP_FLAG_NV;
      end else if (!a_is_nan && !b_is_nan && !a_is_zero && b_is_zero) begin
        fp_div_s_fflags = FP_FLAG_DZ;
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
          fp_div_s_fflags = FP_FLAG_OF | FP_FLAG_NX;
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
        fp_sqrt_s_fflags = FP_FLAG_NV;
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
        fp_s_to_int_fflags = FP_FLAG_NV;
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
          fp_s_to_int_fflags = FP_FLAG_NV;
        end else if (guard || sticky) begin
          fp_s_to_int_fflags = FP_FLAG_NX;
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
        fp_d_to_int_fflags = FP_FLAG_NV;
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
          fp_d_to_int_fflags = FP_FLAG_NV;
        end else if (guard || sticky) begin
          fp_d_to_int_fflags = FP_FLAG_NX;
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
            fp_int_to_s_fflags = FP_FLAG_NX;
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
            fp_int_to_d_fflags = FP_FLAG_NX;
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
        fp_d_to_s_fflags = FP_FLAG_NV;
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
          fp_d_to_s_fflags = FP_FLAG_OF | FP_FLAG_NX;
        end else begin
          fp_d_to_s_fflags = fp_round_flags_s(sign, exp_s[7:0],
                                              mant24, guard, sticky);
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
        fp_addsub_d_fflags = FP_FLAG_NV;
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
        fp_mul_d_fflags = FP_FLAG_NV;
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
          fp_mul_d_fflags = FP_FLAG_OF | FP_FLAG_NX;
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
        fp_div_d_fflags = FP_FLAG_NV;
      end else if (!a_is_nan && !b_is_nan && !a_is_zero && b_is_zero) begin
        fp_div_d_fflags = FP_FLAG_DZ;
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
          fp_div_d_fflags = FP_FLAG_OF | FP_FLAG_NX;
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
        fp_sqrt_d_fflags = FP_FLAG_NV;
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
          FP_FLAG_NV : 5'b00000;
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
          FP_FLAG_NV : 5'b00000;
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
      // FCMP 结果位先闭合，异常标志后续接入 fflags CSR 聚合路径。
      fp_compare_value = {{(`XLEN-1){1'b0}}, result_bit};
    end
  endfunction

  function [55:0] fp_shift_right_jam_56;
    input [55:0] value;
    input [6:0] shamt;
    reg [55:0] stage;
    reg [55:0] stage_next;
    begin
      if (shamt == 7'd0) begin
        fp_shift_right_jam_56 = value;
      end else if (shamt >= 7'd56) begin
        fp_shift_right_jam_56 = {55'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[55:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[55:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[55:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[55:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[55:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[55:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_56 = stage;
      end
    end
  endfunction

  function [26:0] fp_shift_right_jam_27;
    input [26:0] value;
    input [5:0] shamt;
    reg [26:0] stage;
    reg [26:0] stage_next;
    begin
      if (shamt == 6'd0) begin
        fp_shift_right_jam_27 = value;
      end else if (shamt >= 6'd27) begin
        fp_shift_right_jam_27 = {26'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[26:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[26:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[26:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[26:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[26:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_27 = stage;
      end
    end
  endfunction

  function [105:0] fp_shift_right_jam_106;
    input [105:0] value;
    input [7:0] shamt;
    reg [105:0] stage;
    reg [105:0] stage_next;
    begin
      if (shamt == 8'd0) begin
        fp_shift_right_jam_106 = value;
      end else if (shamt >= 8'd106) begin
        fp_shift_right_jam_106 = {105'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[105:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[105:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[105:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[105:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[105:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[105:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        if (shamt[6]) begin
          stage_next = {64'b0, stage[105:64]};
          stage_next[0] = stage_next[0] | (|stage[63:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_106 = stage;
      end
    end
  endfunction

  function [47:0] fp_shift_right_jam_48;
    input [47:0] value;
    input [5:0] shamt;
    reg [47:0] stage;
    reg [47:0] stage_next;
    begin
      if (shamt == 6'd0) begin
        fp_shift_right_jam_48 = value;
      end else if (shamt >= 6'd48) begin
        fp_shift_right_jam_48 = {47'b0, |value};
      end else begin
        stage = value;
        if (shamt[0]) begin
          stage_next = {1'b0, stage[47:1]};
          stage_next[0] = stage_next[0] | stage[0];
          stage = stage_next;
        end
        if (shamt[1]) begin
          stage_next = {2'b0, stage[47:2]};
          stage_next[0] = stage_next[0] | (|stage[1:0]);
          stage = stage_next;
        end
        if (shamt[2]) begin
          stage_next = {4'b0, stage[47:4]};
          stage_next[0] = stage_next[0] | (|stage[3:0]);
          stage = stage_next;
        end
        if (shamt[3]) begin
          stage_next = {8'b0, stage[47:8]};
          stage_next[0] = stage_next[0] | (|stage[7:0]);
          stage = stage_next;
        end
        if (shamt[4]) begin
          stage_next = {16'b0, stage[47:16]};
          stage_next[0] = stage_next[0] | (|stage[15:0]);
          stage = stage_next;
        end
        if (shamt[5]) begin
          stage_next = {32'b0, stage[47:32]};
          stage_next[0] = stage_next[0] | (|stage[31:0]);
          stage = stage_next;
        end
        fp_shift_right_jam_48 = stage;
      end
    end
  endfunction

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
        fp_addsub_d_value = {sign_a & sign_b, 63'b0};
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
          fp_addsub_d_value = 64'b0;
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
        fp_addsub_s_value = {32'hffff_ffff, sign_a & sign_b, 31'b0};
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
          fp_addsub_s_value = 64'hffffffff00000000;
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

  wire pending_fp_q = pending_valid_i;
  wire [`INST_W-1:0] pending_fp_inst_q = inst_i;
  wire pending_fp_load_q = load_i;
  wire pending_fp_store_q = store_i;
  wire pending_fp_double_q = double_i;
  wire pending_fp_gpr_write_q = gpr_write_i;
  wire pending_fp_op_fp_w = pending_fp_inst_q[6:0] == `OPCODE_OP_FP;
  wire [`XLEN-1:0] pending_fp_int_rs1_value_w = int_rs1_value_i;
  wire [`XLEN-1:0] pending_fp_mem_addr_w =
      pending_fp_int_rs1_value_w +
      (pending_fp_load_q ? fp_i_imm(pending_fp_inst_q) :
                           fp_s_imm(pending_fp_inst_q));
  wire [`XLEN-1:0] pending_fp_store_value_w = frs2_value_i;
  wire [`XLEN-1:0] pending_fp_mem_wdata_w =
      fp_store_wdata(pending_fp_mem_addr_w,
                     pending_fp_store_value_w,
                     pending_fp_double_q);
  wire [`STRB_W-1:0] pending_fp_mem_wstrb_w =
      fp_store_wstrb(pending_fp_mem_addr_w, pending_fp_double_q);
  wire [`XLEN-1:0] pending_fp_move_to_fpr_value_w =
      pending_fp_double_q ? pending_fp_int_rs1_value_w :
      {32'hffff_ffff, pending_fp_int_rs1_value_w[31:0]};
  wire [`XLEN-1:0] pending_fp_frs1_value_w = frs1_value_i;
  wire [`XLEN-1:0] pending_fp_frs2_value_w = frs2_value_i;
  wire [`XLEN-1:0] pending_fp_frs3_value_w = frs3_value_i;
  wire pending_fp_class_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      (pending_fp_inst_q[14:12] == 3'b001) &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMV_X_W) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMV_X_D));
  wire pending_fp_compare_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCMP_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCMP_D));
  wire pending_fp_sgnj_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FSGNJ_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSGNJ_D));
  wire pending_fp_addsub_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FADD_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FADD_D) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_D));
  wire pending_fp_mul_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMUL_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMUL_D));
  wire pending_fp_fma_w =
      !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[6:0] == `OPCODE_MADD) ||
       (pending_fp_inst_q[6:0] == `OPCODE_MSUB) ||
       (pending_fp_inst_q[6:0] == `OPCODE_NMSUB) ||
       (pending_fp_inst_q[6:0] == `OPCODE_NMADD));
  wire pending_fp_div_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_D));
  wire pending_fp_sqrt_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_D));
  wire pending_fp_minmax_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMINMAX_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMINMAX_D));
  wire pending_fp_convert_to_gpr_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_INT) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_INT));
  wire pending_fp_int_to_fpr_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_D));
  wire pending_fp_fpr_to_fpr_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      (((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_D) &&
        (pending_fp_inst_q[24:20] == 5'b00001)) ||
       ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_S) &&
        (pending_fp_inst_q[24:20] == 5'b00000)));
  wire pending_fp_convert_to_fpr_w =
      pending_fp_int_to_fpr_w || pending_fp_fpr_to_fpr_w;

  wire pending_fp_long_op_w =
      pending_fp_q && pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_D) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_D));
  wire pending_fp_compute_op_w =
      pending_fp_q && !pending_fp_load_q && !pending_fp_store_q &&
      !pending_fp_long_op_w;
  wire pending_fp_long_start_w = long_start_i;
  wire [107:0] pending_fp_div_dividend_w =
      fp_div_dividend_value(pending_fp_frs1_value_w, pending_fp_double_q);
  wire [52:0] pending_fp_div_divisor_w =
      fp_div_divisor_value(pending_fp_frs2_value_w, pending_fp_double_q);
  wire [55:0] pending_fp_div_quotient_w;
  wire pending_fp_div_remainder_nonzero_w;
  wire pending_fp_div_busy_w;
  wire pending_fp_div_done_w;
  wire [111:0] pending_fp_sqrt_radicand_w =
      fp_sqrt_radicand_value(pending_fp_frs1_value_w, pending_fp_double_q);
  wire [55:0] pending_fp_sqrt_root_w;
  wire pending_fp_sqrt_remainder_nonzero_w;
  wire pending_fp_sqrt_busy_w;
  wire pending_fp_sqrt_done_w;

  OooFpDivIter u_pending_fp_div_iter (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .start_i(pending_fp_long_start_w && pending_fp_div_w),
    .dividend_i(pending_fp_div_dividend_w),
    .divisor_i(pending_fp_div_divisor_w),
    .busy_o(pending_fp_div_busy_w),
    .done_o(pending_fp_div_done_w),
    .quotient_o(pending_fp_div_quotient_w),
    .remainder_nonzero_o(pending_fp_div_remainder_nonzero_w)
  );

  OooFpSqrtIter u_pending_fp_sqrt_iter (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .start_i(pending_fp_long_start_w && pending_fp_sqrt_w),
    .value_i(pending_fp_sqrt_radicand_w),
    .busy_o(pending_fp_sqrt_busy_w),
    .done_o(pending_fp_sqrt_done_w),
    .root_o(pending_fp_sqrt_root_w),
    .remainder_nonzero_o(pending_fp_sqrt_remainder_nonzero_w)
  );

  wire pending_fp_convert_src_double_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_INT) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_D);
  wire pending_fp_convert_dst_double_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_D) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_S);
  wire [`XLEN-1:0] pending_fp_convert_to_gpr_value_w =
      pending_fp_convert_src_double_w ?
      fp_d_to_int_value(pending_fp_frs1_value_w,
                        pending_fp_inst_q[21:20],
                        pending_fp_inst_q[14:12]) :
      fp_s_to_int_value(pending_fp_frs1_value_w,
                        pending_fp_inst_q[21:20],
                        pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_int_to_fpr_value_w =
      pending_fp_convert_dst_double_w ?
      fp_int_to_d_value(pending_fp_int_rs1_value_w,
                        pending_fp_inst_q[21:20],
                        pending_fp_inst_q[14:12]) :
      fp_int_to_s_value(pending_fp_int_rs1_value_w,
                        pending_fp_inst_q[21:20],
                        pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_fpr_to_fpr_value_w =
      pending_fp_convert_dst_double_w ?
      fp_s_to_d_value(pending_fp_frs1_value_w) :
      fp_d_to_s_value(pending_fp_frs1_value_w,
                      pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_convert_to_fpr_value_w =
      pending_fp_fpr_to_fpr_w ? pending_fp_fpr_to_fpr_value_w :
                                pending_fp_int_to_fpr_value_w;
  wire [`XLEN-1:0] pending_fp_compare_value_w =
      fp_compare_value(pending_fp_frs1_value_w,
                       pending_fp_frs2_value_w,
                       pending_fp_double_q,
                       pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_sgnj_value_w =
      fp_sgnj_value(pending_fp_frs1_value_w,
                    pending_fp_frs2_value_w,
                    pending_fp_double_q,
                    pending_fp_inst_q[14:12]);
  wire pending_fp_sub_op_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_S) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_D);
  wire pending_fp_negate_product_w =
      (pending_fp_inst_q[6:0] == `OPCODE_NMSUB) ||
      (pending_fp_inst_q[6:0] == `OPCODE_NMADD);
  wire pending_fp_subtract_addend_w =
      (pending_fp_inst_q[6:0] == `OPCODE_MSUB) ||
      (pending_fp_inst_q[6:0] == `OPCODE_NMADD);
  wire [`XLEN-1:0] pending_fp_addsub_value_w =
      fp_addsub_value(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_double_q,
                      pending_fp_sub_op_w,
                      pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_mul_value_w =
      fp_mul_value(pending_fp_frs1_value_w,
                   pending_fp_frs2_value_w,
                   pending_fp_double_q,
                   pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_fma_value_w =
      fp_fma_value(pending_fp_frs1_value_w,
                   pending_fp_frs2_value_w,
                   pending_fp_frs3_value_w,
                   pending_fp_double_q,
                   pending_fp_negate_product_w,
                   pending_fp_subtract_addend_w,
                   pending_fp_inst_q[14:12]);
  wire [`XLEN-1:0] pending_fp_div_value_w =
      fp_div_value(pending_fp_frs1_value_w,
                   pending_fp_frs2_value_w,
                   pending_fp_double_q,
                   pending_fp_inst_q[14:12],
                   pending_fp_div_quotient_w,
                   pending_fp_div_remainder_nonzero_w);
  wire [`XLEN-1:0] pending_fp_sqrt_value_w =
      fp_sqrt_value(pending_fp_frs1_value_w,
                    pending_fp_double_q,
                    pending_fp_inst_q[14:12],
                    pending_fp_sqrt_root_w,
                    pending_fp_sqrt_remainder_nonzero_w);
  wire pending_fp_long_done_w =
      pending_fp_div_done_w || pending_fp_sqrt_done_w;
  wire [`XLEN-1:0] pending_fp_long_done_result_w =
      pending_fp_div_done_w ? pending_fp_div_value_w :
                              pending_fp_sqrt_value_w;
  wire [`XLEN-1:0] pending_fp_minmax_value_w =
      fp_minmax_value(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_double_q,
                      pending_fp_inst_q[12]);
  wire [`XLEN-1:0] pending_fp_fma_lhs_fflags_w =
      pending_fp_negate_product_w ?
      fp_neg_value(pending_fp_mul_value_w, pending_fp_double_q) :
      pending_fp_mul_value_w;
  wire [4:0] pending_fp_compare_fflags_w =
      fp_compare_fflags(pending_fp_frs1_value_w,
                        pending_fp_frs2_value_w,
                        pending_fp_double_q,
                        pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_addsub_fflags_w =
      pending_fp_double_q ?
      fp_addsub_d_fflags(pending_fp_frs1_value_w,
                         pending_fp_frs2_value_w,
                         pending_fp_sub_op_w,
                         pending_fp_inst_q[14:12]) :
      fp_addsub_s_fflags(pending_fp_frs1_value_w,
                         pending_fp_frs2_value_w,
                         pending_fp_sub_op_w,
                         pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_mul_fflags_w =
      pending_fp_double_q ?
      fp_mul_d_fflags(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_inst_q[14:12]) :
      fp_mul_s_fflags(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_fma_fflags_w =
      pending_fp_double_q ?
      (fp_mul_d_fflags(pending_fp_frs1_value_w,
                       pending_fp_frs2_value_w,
                       pending_fp_inst_q[14:12]) |
       fp_addsub_d_fflags(pending_fp_fma_lhs_fflags_w,
                          pending_fp_frs3_value_w,
                          pending_fp_subtract_addend_w,
                          pending_fp_inst_q[14:12])) :
      (fp_mul_s_fflags(pending_fp_frs1_value_w,
                       pending_fp_frs2_value_w,
                       pending_fp_inst_q[14:12]) |
       fp_addsub_s_fflags(pending_fp_fma_lhs_fflags_w,
                          pending_fp_frs3_value_w,
                          pending_fp_subtract_addend_w,
                          pending_fp_inst_q[14:12]));
  wire [4:0] pending_fp_div_fflags_w =
      pending_fp_double_q ?
      fp_div_d_fflags(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_inst_q[14:12],
                      pending_fp_div_quotient_w,
                      pending_fp_div_remainder_nonzero_w) :
      fp_div_s_fflags(pending_fp_frs1_value_w,
                      pending_fp_frs2_value_w,
                      pending_fp_inst_q[14:12],
                      pending_fp_div_quotient_w[26:0],
                      pending_fp_div_remainder_nonzero_w);
  wire [4:0] pending_fp_sqrt_fflags_w =
      pending_fp_double_q ?
      fp_sqrt_d_fflags(pending_fp_frs1_value_w,
                       pending_fp_inst_q[14:12],
                       pending_fp_sqrt_root_w,
                       pending_fp_sqrt_remainder_nonzero_w) :
      fp_sqrt_s_fflags(pending_fp_frs1_value_w,
                       pending_fp_inst_q[14:12],
                       pending_fp_sqrt_root_w[26:0],
                       pending_fp_sqrt_remainder_nonzero_w);
  wire [4:0] pending_fp_long_done_fflags_w =
      pending_fp_div_done_w ? pending_fp_div_fflags_w :
                              pending_fp_sqrt_fflags_w;
  wire [4:0] pending_fp_minmax_fflags_w =
      fp_minmax_fflags(pending_fp_frs1_value_w,
                       pending_fp_frs2_value_w,
                       pending_fp_double_q);
  wire [4:0] pending_fp_convert_to_gpr_fflags_w =
      pending_fp_convert_src_double_w ?
      fp_d_to_int_fflags(pending_fp_frs1_value_w,
                         pending_fp_inst_q[21:20],
                         pending_fp_inst_q[14:12]) :
      fp_s_to_int_fflags(pending_fp_frs1_value_w,
                         pending_fp_inst_q[21:20],
                         pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_int_to_fpr_fflags_w =
      pending_fp_convert_dst_double_w ?
      fp_int_to_d_fflags(pending_fp_int_rs1_value_w,
                         pending_fp_inst_q[21:20],
                         pending_fp_inst_q[14:12]) :
      fp_int_to_s_fflags(pending_fp_int_rs1_value_w,
                         pending_fp_inst_q[21:20],
                         pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_fpr_to_fpr_fflags_w =
      pending_fp_convert_dst_double_w ?
      (fp_is_snan_s_value(pending_fp_frs1_value_w) ? FP_FLAG_NV : 5'b00000) :
      fp_d_to_s_fflags(pending_fp_frs1_value_w, pending_fp_inst_q[14:12]);
  wire [4:0] pending_fp_convert_to_fpr_fflags_w =
      pending_fp_fpr_to_fpr_w ? pending_fp_fpr_to_fpr_fflags_w :
                                pending_fp_int_to_fpr_fflags_w;
  wire [4:0] pending_fp_gpr_fflags_w =
      pending_fp_compare_w ? pending_fp_compare_fflags_w :
      pending_fp_convert_to_gpr_w ? pending_fp_convert_to_gpr_fflags_w :
                                    5'b00000;
  wire [4:0] pending_fp_compute_fflags_w =
      pending_fp_gpr_write_q ? pending_fp_gpr_fflags_w :
      pending_fp_convert_to_fpr_w ? pending_fp_convert_to_fpr_fflags_w :
      pending_fp_addsub_w ? pending_fp_addsub_fflags_w :
      pending_fp_mul_w ? pending_fp_mul_fflags_w :
      pending_fp_fma_w ? pending_fp_fma_fflags_w :
      pending_fp_minmax_w ? pending_fp_minmax_fflags_w :
                            5'b00000;
  wire [`XLEN-1:0] pending_fp_gpr_value_w =
      pending_fp_class_w ?
      (pending_fp_double_q ? fp_class_d_value(pending_fp_frs1_value_w) :
       fp_class_s_value(pending_fp_frs1_value_w[31:0])) :
      pending_fp_compare_w ? pending_fp_compare_value_w :
      pending_fp_convert_to_gpr_w ? pending_fp_convert_to_gpr_value_w :
      fp_move_to_gpr_value(pending_fp_frs1_value_w, pending_fp_double_q);
  wire [`XLEN-1:0] pending_fp_compute_value_w =
      pending_fp_gpr_write_q ? pending_fp_gpr_value_w :
      pending_fp_convert_to_fpr_w ? pending_fp_convert_to_fpr_value_w :
      pending_fp_sgnj_w ? pending_fp_sgnj_value_w :
      pending_fp_addsub_w ? pending_fp_addsub_value_w :
      pending_fp_mul_w ? pending_fp_mul_value_w :
      pending_fp_fma_w ? pending_fp_fma_value_w :
      pending_fp_minmax_w ? pending_fp_minmax_value_w :
                               pending_fp_move_to_fpr_value_w;

  assign long_op_o = pending_fp_long_op_w;
  assign compute_op_o = pending_fp_compute_op_w;
  assign div_busy_o = pending_fp_div_busy_w;
  assign sqrt_busy_o = pending_fp_sqrt_busy_w;
  assign long_done_o = pending_fp_long_done_w;
  assign long_done_result_o = pending_fp_long_done_result_w;
  assign long_done_fflags_o = pending_fp_long_done_fflags_w;
  assign mem_addr_o = pending_fp_mem_addr_w;
  assign mem_aligned_addr_o = fp_aligned_addr(pending_fp_mem_addr_w);
  assign mem_wdata_o = pending_fp_mem_wdata_w;
  assign mem_wstrb_o = pending_fp_mem_wstrb_w;
  assign compute_value_o = pending_fp_compute_value_w;
  assign compute_fflags_o = pending_fp_compute_fflags_w;

endmodule
