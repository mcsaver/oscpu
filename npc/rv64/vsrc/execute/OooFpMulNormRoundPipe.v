`include "define.v"

// FMUL S2-S3 production child。S1 Q 直接进入本模块的 S2 组合锥；边界不打拍。
// value 与 fflags 在同一 S3 时序块原子写入，且本模块不拥有事务 valid/kill。
module OooFpMulNormRoundPipe (
  input                  clk,
  input                  rst,
  input                  flush_i,

  input                  mul_d_special_q_i,
  input  [63:0]          mul_d_spval_q_i,
  input  [4:0]           mul_d_spff_q_i,
  input  [105:0]         mul_d_product_q_i,
  input  signed [13:0]   mul_d_expz_q_i,
  input                  mul_d_signz_q_i,
  input  [2:0]           mul_d_rm_q_i,

  input                  mul_s_special_q_i,
  input  [63:0]          mul_s_spval_q_i,
  input  [4:0]           mul_s_spff_q_i,
  input  [47:0]          mul_s_product_q_i,
  input  signed [13:0]   mul_s_expz_q_i,
  input                  mul_s_signz_q_i,
  input  [2:0]           mul_s_rm_q_i,

  output reg [63:0]      mul_d_value_q_o,
  output reg [4:0]       mul_d_fflags_q_o,
  output reg [63:0]      mul_s_value_q_o,
  output reg [4:0]       mul_s_fflags_q_o
);

  `include "execute/OooFpRound.v"

  reg        mul_d_s2_special_q;
  reg [63:0] mul_d_s2_spval_q;
  reg [4:0]  mul_d_s2_spff_q;
  reg [105:0] mul_d_s2_pnorm_c, mul_d_s2_pnorm_q;
  reg signed [13:0] mul_d_s2_expz_c, mul_d_s2_expz_q;
  reg        mul_d_s2_signz_q;
  reg [2:0]  mul_d_s2_rm_q;
  reg [63:0] mul_d_s3_value_c;
  reg [4:0]  mul_d_s3_fflags_c;

  reg        mul_s_s2_special_q;
  reg [63:0] mul_s_s2_spval_q;
  reg [4:0]  mul_s_s2_spff_q;
  reg [47:0] mul_s_s2_pnorm_c, mul_s_s2_pnorm_q;
  reg signed [13:0] mul_s_s2_expz_c, mul_s_s2_expz_q;
  reg        mul_s_s2_signz_q;
  reg [2:0]  mul_s_s2_rm_q;
  reg [63:0] mul_s_s3_value_c;
  reg [4:0]  mul_s_s3_fflags_c;

  // S2 double：直接消费 MulProduct 的 S1 Q，仅做左规格化。
  always @(*) begin : mul_d_s2_comb
    reg [105:0] product_norm;
    reg [7:0] norm_lzc, norm_required, norm_shift;
    reg signed [13:0] exp_z;
    product_norm = mul_d_product_q_i;
    exp_z = mul_d_expz_q_i;
    norm_lzc = 0; norm_required = 0; norm_shift = 0;
    if ((product_norm != 106'b0) && (exp_z > 1)) begin
      norm_lzc = fp_lzc_106(product_norm);
      norm_required = (norm_lzc > 8'd1) ? (norm_lzc - 8'd1) : 8'd0;
      norm_shift = (norm_required > (exp_z - 1)) ?
                   (exp_z - 1) : norm_required;
      product_norm = product_norm << norm_shift;
      exp_z = exp_z - $signed({1'b0, norm_shift});
    end
    mul_d_s2_pnorm_c = product_norm;
    mul_d_s2_expz_c = exp_z;
  end

  // S3 double：subnormal 右移、单次舍入、组装与特殊选择。
  always @(*) begin : mul_d_s3_comb
    reg [105:0] product_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard, sticky, inc;
    reg signed [13:0] exp_z;
    reg [7:0] sub_shift;
    integer sub_shift_int;
    reg sign_z; reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    product_norm = mul_d_s2_pnorm_q;
    exp_z = mul_d_s2_expz_q;
    sign_z = mul_d_s2_signz_q;
    rm = mul_d_s2_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    sub_shift = 0; sub_shift_int = 0;
    value = 64'b0; fflags = 5'b00000;
    if (exp_z < 1) begin
      sub_shift_int = 1 - exp_z;
      if (sub_shift_int >= 106) sub_shift = 8'd106;
      else sub_shift = sub_shift_int;
      product_norm = fp_shift_right_jam_106(product_norm, sub_shift);
      exp_z = 1;
    end
    if (product_norm[105]) begin
      mant53 = product_norm[105:53]; guard = product_norm[52];
      sticky = |product_norm[51:0]; exp_z = exp_z + 1;
    end else begin
      mant53 = product_norm[104:52]; guard = product_norm[51];
      sticky = |product_norm[50:0];
    end
    inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
    mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
    if (mant_round_ext[53]) begin
      mant53 = mant_round_ext[53:1]; exp_z = exp_z + 1;
    end else mant53 = mant_round_ext[52:0];
    if (exp_z >= 2047) value = fp_overflow_d(sign_z, rm);
    else if ((exp_z <= 1) && !mant53[52])
      value = {sign_z, 11'b0, mant53[51:0]};
    else value = {sign_z, exp_z[10:0], mant53[51:0]};
    fflags = fp_round_flags_d(sign_z, exp_z[10:0], mant53, guard, sticky);
    if (exp_z >= 2047) fflags = `FP_FLAG_OF | `FP_FLAG_NX;
    mul_d_s3_value_c = mul_d_s2_special_q ? mul_d_s2_spval_q : value;
    mul_d_s3_fflags_c = mul_d_s2_special_q ? mul_d_s2_spff_q : fflags;
  end

  // S2 single：直接消费 MulProduct 的 S1 Q，仅做左规格化。
  always @(*) begin : mul_s_s2_comb
    reg [47:0] product_norm;
    reg [5:0] norm_lzc, norm_required, norm_shift;
    reg signed [13:0] exp_z;
    product_norm = mul_s_product_q_i;
    exp_z = mul_s_expz_q_i;
    norm_lzc = 0; norm_required = 0; norm_shift = 0;
    if ((product_norm != 48'b0) && (exp_z > 1)) begin
      norm_lzc = fp_lzc_48(product_norm);
      norm_required = (norm_lzc > 6'd1) ? (norm_lzc - 6'd1) : 6'd0;
      norm_shift = (norm_required > (exp_z - 1)) ?
                   (exp_z - 1) : norm_required;
      product_norm = product_norm << norm_shift;
      exp_z = exp_z - $signed({1'b0, norm_shift});
    end
    mul_s_s2_pnorm_c = product_norm;
    mul_s_s2_expz_c = exp_z;
  end

  // S3 single：subnormal 右移、单次舍入、组装与特殊选择。
  always @(*) begin : mul_s_s3_comb
    reg [47:0] product_norm;
    reg [5:0] sub_shift;
    integer sub_shift_int;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard, sticky, inc;
    reg signed [13:0] exp_z;
    reg sign_z; reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    product_norm = mul_s_s2_pnorm_q;
    exp_z = mul_s_s2_expz_q;
    sign_z = mul_s_s2_signz_q;
    rm = mul_s_s2_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    sub_shift = 0; sub_shift_int = 0;
    value = 64'b0; fflags = 5'b00000;
    if (exp_z < 1) begin
      sub_shift_int = 1 - exp_z;
      if (sub_shift_int >= 48) sub_shift = 6'd48;
      else sub_shift = sub_shift_int;
      product_norm = fp_shift_right_jam_48(product_norm, sub_shift);
      exp_z = 1;
    end
    if (product_norm[47]) begin
      mant24 = product_norm[47:24]; guard = product_norm[23];
      sticky = |product_norm[22:0]; exp_z = exp_z + 1;
    end else begin
      mant24 = product_norm[46:23]; guard = product_norm[22];
      sticky = |product_norm[21:0];
    end
    inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
    mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
    if (mant_round_ext[24]) begin
      mant24 = mant_round_ext[24:1]; exp_z = exp_z + 1;
    end else mant24 = mant_round_ext[23:0];
    if (exp_z >= 255) value = fp_overflow_s(sign_z, rm);
    else if ((exp_z <= 1) && !mant24[23])
      value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
    else value = {32'hffff_ffff, sign_z, exp_z[7:0], mant24[22:0]};
    fflags = fp_round_flags_s(sign_z, exp_z[7:0], mant24, guard, sticky);
    if (exp_z >= 255) fflags = `FP_FLAG_OF | `FP_FLAG_NX;
    mul_s_s3_value_c = mul_s_s2_special_q ? mul_s_s2_spval_q : value;
    mul_s_s3_fflags_c = mul_s_s2_special_q ? mul_s_s2_spff_q : fflags;
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      mul_d_s2_special_q <= 1'b0;
      mul_d_s2_spval_q <= 64'b0;
      mul_d_s2_spff_q <= 5'b0;
      mul_d_s2_pnorm_q <= 106'b0;
      mul_d_s2_expz_q <= 0;
      mul_d_s2_signz_q <= 1'b0;
      mul_d_s2_rm_q <= 3'b0;
      mul_d_value_q_o <= 64'b0;
      mul_d_fflags_q_o <= 5'b0;
      mul_s_s2_special_q <= 1'b0;
      mul_s_s2_spval_q <= 64'b0;
      mul_s_s2_spff_q <= 5'b0;
      mul_s_s2_pnorm_q <= 48'b0;
      mul_s_s2_expz_q <= 0;
      mul_s_s2_signz_q <= 1'b0;
      mul_s_s2_rm_q <= 3'b0;
      mul_s_value_q_o <= 64'b0;
      mul_s_fflags_q_o <= 5'b0;
    end else begin
      mul_d_s2_special_q <= mul_d_special_q_i;
      mul_d_s2_spval_q <= mul_d_spval_q_i;
      mul_d_s2_spff_q <= mul_d_spff_q_i;
      mul_d_s2_pnorm_q <= mul_d_s2_pnorm_c;
      mul_d_s2_expz_q <= mul_d_s2_expz_c;
      mul_d_s2_signz_q <= mul_d_signz_q_i;
      mul_d_s2_rm_q <= mul_d_rm_q_i;
      mul_d_value_q_o <= mul_d_s3_value_c;
      mul_d_fflags_q_o <= mul_d_s3_fflags_c;
      mul_s_s2_special_q <= mul_s_special_q_i;
      mul_s_s2_spval_q <= mul_s_spval_q_i;
      mul_s_s2_spff_q <= mul_s_spff_q_i;
      mul_s_s2_pnorm_q <= mul_s_s2_pnorm_c;
      mul_s_s2_expz_q <= mul_s_s2_expz_c;
      mul_s_s2_signz_q <= mul_s_signz_q_i;
      mul_s_s2_rm_q <= mul_s_rm_q_i;
      mul_s_value_q_o <= mul_s_s3_value_c;
      mul_s_fflags_q_o <= mul_s_s3_fflags_c;
    end
  end

endmodule
