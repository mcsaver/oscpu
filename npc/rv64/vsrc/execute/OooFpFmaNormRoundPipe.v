`include "define.v"

// FMA S4-S5 production child。FmaAlignAdd 的完整 S3 Q 直接驱动 S4 组合锥，
// 无额外边界寄存器；S5 仅做一次 fused rounding 并原子寄存 {value,fflags}。
module OooFpFmaNormRoundPipe (
  input                   clk,
  input                   rst,
  input                   flush_i,

  input                   fma_d_special_q_i,
  input  [63:0]           fma_d_spval_q_i,
  input  [4:0]            fma_d_spff_q_i,
  input  [127:0]          fma_d_mag_q_i,
  input                   fma_d_ressign_q_i,
  input  signed [31:0]    fma_d_refw_q_i,
  input  [2:0]            fma_d_rm_q_i,

  input                   fma_s_special_q_i,
  input  [63:0]           fma_s_spval_q_i,
  input  [4:0]            fma_s_spff_q_i,
  input  [127:0]          fma_s_mag_q_i,
  input                   fma_s_ressign_q_i,
  input  signed [31:0]    fma_s_refw_q_i,
  input  [2:0]            fma_s_rm_q_i,

  output reg [63:0]       fma_d_value_q_o,
  output reg [4:0]        fma_d_fflags_q_o,
  output reg [63:0]       fma_s_value_q_o,
  output reg [4:0]        fma_s_fflags_q_o
);

  `include "execute/OooFpRound.v"

  reg [127:0] fma_d_s4_magn_c, fma_d_s4_magn_q;
  reg signed [13:0] fma_d_s4_ebiased_c, fma_d_s4_ebiased_q;
  reg fma_d_s4_iszero_c, fma_d_s4_iszero_q;
  reg fma_d_s4_ressign_q;
  reg [2:0] fma_d_s4_rm_q;
  reg fma_d_s4_special_q;
  reg [63:0] fma_d_s4_spval_q;
  reg [4:0] fma_d_s4_spff_q;
  reg [63:0] fma_d_s5_value_c;
  reg [4:0] fma_d_s5_fflags_c;

  // S4 double：S3 full mag[127:0]（含 mag[0] jam）直入 LZC/normalize。
  always @(*) begin : fma_d_s4_comb
    reg [127:0] mag, magn;
    reg [7:0] lzc_m;
    integer ref_w, e_biased, sub_shift, negsh;
    mag = fma_d_mag_q_i;
    ref_w = fma_d_refw_q_i;
    magn = 128'b0; lzc_m = 0; e_biased = 0; sub_shift = 0; negsh = 0;
    fma_d_s4_iszero_c = (mag == 128'b0);
    if (mag != 128'b0) begin
      lzc_m = fp_lzc_128(mag);
      magn = mag << lzc_m;
      e_biased = ref_w + 1024 - lzc_m;
      if (e_biased < 1) begin
        sub_shift = 1 - e_biased;
        negsh = (sub_shift > 128) ? 128 : sub_shift;
        magn = fp_shift_right_jam_128(magn, negsh[7:0]);
        e_biased = 1;
      end
    end
    fma_d_s4_magn_c = magn;
    fma_d_s4_ebiased_c = e_biased;
  end

  // S5 double：单次舍入、组装与 special/zero 选择。
  always @(*) begin : fma_d_s5_comb
    reg [127:0] magn;
    reg signed [13:0] e_biased;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard, sticky, inc, res_sign;
    reg [2:0] rm;
    reg [63:0] value;
    reg [4:0] fflags;
    magn = fma_d_s4_magn_q;
    e_biased = fma_d_s4_ebiased_q;
    res_sign = fma_d_s4_ressign_q;
    rm = fma_d_s4_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 1'b0;
    sticky = 1'b0; inc = 1'b0;
    value = 64'b0; fflags = 5'b00000;
    if (fma_d_s4_iszero_q) begin
      value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
    end else begin
      mant53 = magn[127:75];
      guard = magn[74];
      sticky = |magn[73:0];
      inc = fp_round_increment(res_sign, rm, mant53[0], guard, sticky);
      mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
      if (mant_round_ext[53]) begin
        e_biased = e_biased + 1;
        mant53 = mant_round_ext[53:1];
      end else mant53 = mant_round_ext[52:0];
      fflags = fp_round_flags_d(
          res_sign, e_biased[10:0], mant53, guard, sticky);
      if (e_biased >= 2047) begin
        value = fp_overflow_d(res_sign, rm);
        fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end else if ((e_biased <= 1) && !mant53[52]) begin
        value = {res_sign, 11'b0, mant53[51:0]};
      end else begin
        value = {res_sign, e_biased[10:0], mant53[51:0]};
      end
    end
    fma_d_s5_value_c = fma_d_s4_special_q ? fma_d_s4_spval_q : value;
    fma_d_s5_fflags_c = fma_d_s4_special_q ? fma_d_s4_spff_q : fflags;
  end

  reg [127:0] fma_s_s4_magn_c, fma_s_s4_magn_q;
  reg signed [13:0] fma_s_s4_ebiased_c, fma_s_s4_ebiased_q;
  reg fma_s_s4_iszero_c, fma_s_s4_iszero_q;
  reg fma_s_s4_ressign_q;
  reg [2:0] fma_s_s4_rm_q;
  reg fma_s_s4_special_q;
  reg [63:0] fma_s_s4_spval_q;
  reg [4:0] fma_s_s4_spff_q;
  reg [63:0] fma_s_s5_value_c;
  reg [4:0] fma_s_s5_fflags_c;

  // S4 single：同样直接消费完整 S3 mag，保持 jam 到 sticky reduction。
  always @(*) begin : fma_s_s4_comb
    reg [127:0] mag, magn;
    reg [7:0] lzc_m;
    integer ref_w, e_biased, sub_shift, negsh;
    mag = fma_s_mag_q_i;
    ref_w = fma_s_refw_q_i;
    magn = 128'b0; lzc_m = 0; e_biased = 0; sub_shift = 0; negsh = 0;
    fma_s_s4_iszero_c = (mag == 128'b0);
    if (mag != 128'b0) begin
      lzc_m = fp_lzc_128(mag);
      magn = mag << lzc_m;
      e_biased = ref_w + 128 - lzc_m;
      if (e_biased < 1) begin
        sub_shift = 1 - e_biased;
        negsh = (sub_shift > 128) ? 128 : sub_shift;
        magn = fp_shift_right_jam_128(magn, negsh[7:0]);
        e_biased = 1;
      end
    end
    fma_s_s4_magn_c = magn;
    fma_s_s4_ebiased_c = e_biased;
  end

  // S5 single：单次舍入、组装与 special/zero 选择。
  always @(*) begin : fma_s_s5_comb
    reg [127:0] magn;
    reg signed [13:0] e_biased;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard, sticky, inc, res_sign;
    reg [2:0] rm;
    reg [63:0] value;
    reg [4:0] fflags;
    magn = fma_s_s4_magn_q;
    e_biased = fma_s_s4_ebiased_q;
    res_sign = fma_s_s4_ressign_q;
    rm = fma_s_s4_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 1'b0;
    sticky = 1'b0; inc = 1'b0;
    value = 64'b0; fflags = 5'b00000;
    if (fma_s_s4_iszero_q) begin
      value = (rm == 3'b010) ?
              64'hffffffff80000000 : 64'hffffffff00000000;
    end else begin
      mant24 = magn[127:104];
      guard = magn[103];
      sticky = |magn[102:0];
      inc = fp_round_increment(res_sign, rm, mant24[0], guard, sticky);
      mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
      if (mant_round_ext[24]) begin
        e_biased = e_biased + 1;
        mant24 = mant_round_ext[24:1];
      end else mant24 = mant_round_ext[23:0];
      fflags = fp_round_flags_s(
          res_sign, e_biased[7:0], mant24, guard, sticky);
      if (e_biased >= 255) begin
        value = fp_overflow_s(res_sign, rm);
        fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      end else if ((e_biased <= 1) && !mant24[23]) begin
        value = {32'hffff_ffff, res_sign, 8'b0, mant24[22:0]};
      end else begin
        value = {32'hffff_ffff, res_sign, e_biased[7:0], mant24[22:0]};
      end
    end
    fma_s_s5_value_c = fma_s_s4_special_q ? fma_s_s4_spval_q : value;
    fma_s_s5_fflags_c = fma_s_s4_special_q ? fma_s_s4_spff_q : fflags;
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      fma_d_s4_magn_q <= 128'b0;
      fma_d_s4_ebiased_q <= 0;
      fma_d_s4_iszero_q <= 1'b0;
      fma_d_s4_ressign_q <= 1'b0;
      fma_d_s4_rm_q <= 3'b0;
      fma_d_s4_special_q <= 1'b0;
      fma_d_s4_spval_q <= 64'b0;
      fma_d_s4_spff_q <= 5'b0;
      fma_d_value_q_o <= 64'b0;
      fma_d_fflags_q_o <= 5'b0;
      fma_s_s4_magn_q <= 128'b0;
      fma_s_s4_ebiased_q <= 0;
      fma_s_s4_iszero_q <= 1'b0;
      fma_s_s4_ressign_q <= 1'b0;
      fma_s_s4_rm_q <= 3'b0;
      fma_s_s4_special_q <= 1'b0;
      fma_s_s4_spval_q <= 64'b0;
      fma_s_s4_spff_q <= 5'b0;
      fma_s_value_q_o <= 64'b0;
      fma_s_fflags_q_o <= 5'b0;
    end else begin
      fma_d_s4_magn_q <= fma_d_s4_magn_c;
      fma_d_s4_ebiased_q <= fma_d_s4_ebiased_c;
      fma_d_s4_iszero_q <= fma_d_s4_iszero_c;
      fma_d_s4_ressign_q <= fma_d_ressign_q_i;
      fma_d_s4_rm_q <= fma_d_rm_q_i;
      fma_d_s4_special_q <= fma_d_special_q_i;
      fma_d_s4_spval_q <= fma_d_spval_q_i;
      fma_d_s4_spff_q <= fma_d_spff_q_i;
      fma_d_value_q_o <= fma_d_s5_value_c;
      fma_d_fflags_q_o <= fma_d_s5_fflags_c;
      fma_s_s4_magn_q <= fma_s_s4_magn_c;
      fma_s_s4_ebiased_q <= fma_s_s4_ebiased_c;
      fma_s_s4_iszero_q <= fma_s_s4_iszero_c;
      fma_s_s4_ressign_q <= fma_s_ressign_q_i;
      fma_s_s4_rm_q <= fma_s_rm_q_i;
      fma_s_s4_special_q <= fma_s_special_q_i;
      fma_s_s4_spval_q <= fma_s_spval_q_i;
      fma_s_s4_spff_q <= fma_s_spff_q_i;
      fma_s_value_q_o <= fma_s_s5_value_c;
      fma_s_fflags_q_o <= fma_s_s5_fflags_c;
    end
  end

endmodule
