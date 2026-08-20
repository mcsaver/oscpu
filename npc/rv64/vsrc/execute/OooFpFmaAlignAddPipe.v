`include "define.v"

// FMA S1-S3 production child：special/product/ref/align/add-sub 的数值 Q 唯一 owner。
// S3 导出完整 mag[127:0]；mag[0] 继续承载 fp_shift_right_jam_128 的 jam 信息。
module OooFpFmaAlignAddPipe (
  input                   clk,
  input                   rst,
  input                   flush_i,
  input  [`XLEN-1:0]      frs1_value_i,
  input  [`XLEN-1:0]      frs2_value_i,
  input  [`XLEN-1:0]      frs3_value_i,
  input                   negate_product_i,
  input                   subtract_addend_i,
  input  [2:0]            rm_i,

  output reg              fma_d_special_q_o,
  output reg [63:0]       fma_d_spval_q_o,
  output reg [4:0]        fma_d_spff_q_o,
  output reg [127:0]      fma_d_mag_q_o,
  output reg              fma_d_ressign_q_o,
  output reg signed [31:0] fma_d_refw_q_o,
  output reg [2:0]        fma_d_rm_q_o,

  output reg              fma_s_special_q_o,
  output reg [63:0]       fma_s_spval_q_o,
  output reg [4:0]        fma_s_spff_q_o,
  output reg [127:0]      fma_s_mag_q_o,
  output reg              fma_s_ressign_q_o,
  output reg signed [31:0] fma_s_refw_q_o,
  output reg [2:0]        fma_s_rm_q_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  // ---- double S1/S2 state and S3 combinational result ----
  reg         fma_d_s1_special_c, fma_d_s1_special_q;
  reg [63:0]  fma_d_s1_spval_c, fma_d_s1_spval_q;
  reg [4:0]   fma_d_s1_spff_c, fma_d_s1_spff_q;
  reg [105:0] fma_d_s1_product_c, fma_d_s1_product_q;
  reg [52:0]  fma_d_s1_sigc_c, fma_d_s1_sigc_q;
  reg signed [31:0] fma_d_s1_ep_c, fma_d_s1_ep_q;
  reg signed [31:0] fma_d_s1_ec_c, fma_d_s1_ec_q;
  reg         fma_d_s1_signp_c, fma_d_s1_signp_q;
  reg         fma_d_s1_signc_c, fma_d_s1_signc_q;
  reg [2:0]   fma_d_s1_rm_c, fma_d_s1_rm_q;

  reg         fma_d_s2_special_q;
  reg [63:0]  fma_d_s2_spval_q;
  reg [4:0]   fma_d_s2_spff_q;
  reg [105:0] fma_d_s2_product_q;
  reg [52:0]  fma_d_s2_sigc_q;
  reg signed [31:0] fma_d_s2_shiftp_c, fma_d_s2_shiftp_q;
  reg signed [31:0] fma_d_s2_shiftc_c, fma_d_s2_shiftc_q;
  reg signed [31:0] fma_d_s2_refw_c, fma_d_s2_refw_q;
  reg         fma_d_s2_signp_q;
  reg         fma_d_s2_signc_q;
  reg [2:0]   fma_d_s2_rm_q;
  reg [127:0] fma_d_s3_mag_c;
  reg         fma_d_s3_ressign_c;

  always @(*) begin : fma_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value, rs3_value;
    reg negate_product, subtract_addend;
    reg sign_a, sign_b, sign_c, sign_p;
    reg [10:0] exp_a, exp_b, exp_c;
    reg [51:0] frac_a, frac_b, frac_c;
    reg [52:0] sig_a, sig_b, sig_c;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0;
    fma_d_s1_special_c = 1'b0; fma_d_s1_spval_c = 64'b0;
    fma_d_s1_spff_c = 5'b00000; fma_d_s1_product_c = 106'b0;
    fma_d_s1_sigc_c = 53'b0; fma_d_s1_ep_c = 0; fma_d_s1_ec_c = 0;
    sign_a = rs1_value[63]; sign_b = rs2_value[63];
    sign_c = rs3_value[63] ^ subtract_addend;
    sign_p = sign_a ^ sign_b ^ negate_product;
    exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52];
    exp_c = rs3_value[62:52];
    frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0];
    frac_c = rs3_value[51:0];
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
    if (result_is_nan) begin
      fma_d_s1_special_c = 1'b1;
      fma_d_s1_spval_c = 64'h7ff8000000000000;
      fma_d_s1_spff_c = nv ? `FP_FLAG_NV : 5'b00000;
    end else if (prod_is_inf) begin
      fma_d_s1_special_c = 1'b1;
      fma_d_s1_spval_c = {sign_p, 11'h7ff, 52'b0};
    end else if (c_is_inf) begin
      fma_d_s1_special_c = 1'b1;
      fma_d_s1_spval_c = {sign_c, 11'h7ff, 52'b0};
    end else if (prod_is_zero && c_is_zero) begin
      fma_d_s1_special_c = 1'b1;
      fma_d_s1_spval_c = {((sign_p == sign_c) ?
                           sign_p : (rm_i == 3'b010)), 63'b0};
    end else if (prod_is_zero) begin
      fma_d_s1_special_c = 1'b1;
      fma_d_s1_spval_c = {sign_c, exp_c, frac_c};
    end
    exp_a_eff = (exp_a == 11'h000) ? 1 : exp_a;
    exp_b_eff = (exp_b == 11'h000) ? 1 : exp_b;
    exp_c_eff = (exp_c == 11'h000) ? 1 : exp_c;
    sig_a = {(exp_a != 11'h000), frac_a};
    sig_b = {(exp_b != 11'h000), frac_b};
    sig_c = {(exp_c != 11'h000), frac_c};
    fma_d_s1_product_c = sig_a * sig_b;
    fma_d_s1_ep_c = exp_a_eff + exp_b_eff - 2150;
    fma_d_s1_ec_c = exp_c_eff - 1075;
    fma_d_s1_sigc_c = sig_c;
    fma_d_s1_signp_c = sign_p;
    fma_d_s1_signc_c = sign_c;
    fma_d_s1_rm_c = rm_i;
  end

  always @(*) begin : fma_d_s2_comb
    reg [7:0] lzc_p;
    reg [5:0] lzc_c53;
    integer ep, ec, pw, cw, ref_w;
    lzc_p = fp_lzc_106(fma_d_s1_product_q);
    lzc_c53 = fp_norm_shift_53(fma_d_s1_sigc_q);
    ep = fma_d_s1_ep_q; ec = fma_d_s1_ec_q;
    pw = ep + 105 - lzc_p;
    cw = ec + 52 - lzc_c53;
    ref_w = (pw >= cw) ? pw : cw;
    fma_d_s2_refw_c = ref_w;
    fma_d_s2_shiftp_c = ep - ref_w + 126;
    fma_d_s2_shiftc_c = ec - ref_w + 126;
  end

  always @(*) begin : fma_d_s3_comb
    reg [127:0] prod_field, addend_field;
    integer shift_p, shift_c, negsh;
    reg sign_p, sign_c;
    shift_p = fma_d_s2_shiftp_q; shift_c = fma_d_s2_shiftc_q;
    sign_p = fma_d_s2_signp_q; sign_c = fma_d_s2_signc_q;
    negsh = 0;
    if (shift_p >= 0) begin
      prod_field = {22'b0, fma_d_s2_product_q} << shift_p;
    end else begin
      negsh = (-shift_p > 128) ? 128 : -shift_p;
      prod_field = fp_shift_right_jam_128(
          {22'b0, fma_d_s2_product_q}, negsh[7:0]);
    end
    if (shift_c >= 0) begin
      addend_field = {75'b0, fma_d_s2_sigc_q} << shift_c;
    end else begin
      negsh = (-shift_c > 128) ? 128 : -shift_c;
      addend_field = fp_shift_right_jam_128(
          {75'b0, fma_d_s2_sigc_q}, negsh[7:0]);
    end
    if (sign_p == sign_c) begin
      fma_d_s3_mag_c = prod_field + addend_field;
      fma_d_s3_ressign_c = sign_p;
    end else if (prod_field >= addend_field) begin
      fma_d_s3_mag_c = prod_field - addend_field;
      fma_d_s3_ressign_c = sign_p;
    end else begin
      fma_d_s3_mag_c = addend_field - prod_field;
      fma_d_s3_ressign_c = sign_c;
    end
  end

  // ---- single S1/S2 state and S3 combinational result ----
  reg         fma_s_s1_special_c, fma_s_s1_special_q;
  reg [63:0]  fma_s_s1_spval_c, fma_s_s1_spval_q;
  reg [4:0]   fma_s_s1_spff_c, fma_s_s1_spff_q;
  reg [47:0]  fma_s_s1_product_c, fma_s_s1_product_q;
  reg [23:0]  fma_s_s1_sigc_c, fma_s_s1_sigc_q;
  reg signed [31:0] fma_s_s1_ep_c, fma_s_s1_ep_q;
  reg signed [31:0] fma_s_s1_ec_c, fma_s_s1_ec_q;
  reg         fma_s_s1_signp_c, fma_s_s1_signp_q;
  reg         fma_s_s1_signc_c, fma_s_s1_signc_q;
  reg [2:0]   fma_s_s1_rm_c, fma_s_s1_rm_q;

  reg         fma_s_s2_special_q;
  reg [63:0]  fma_s_s2_spval_q;
  reg [4:0]   fma_s_s2_spff_q;
  reg [47:0]  fma_s_s2_product_q;
  reg [23:0]  fma_s_s2_sigc_q;
  reg signed [31:0] fma_s_s2_shiftp_c, fma_s_s2_shiftp_q;
  reg signed [31:0] fma_s_s2_shiftc_c, fma_s_s2_shiftc_q;
  reg signed [31:0] fma_s_s2_refw_c, fma_s_s2_refw_q;
  reg         fma_s_s2_signp_q;
  reg         fma_s_s2_signc_q;
  reg [2:0]   fma_s_s2_rm_q;
  reg [127:0] fma_s_s3_mag_c;
  reg         fma_s_s3_ressign_c;

  always @(*) begin : fma_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value, rs3_value;
    reg negate_product, subtract_addend;
    reg [31:0] a, b, c;
    reg sign_a, sign_b, sign_c, sign_p;
    reg [7:0] exp_a, exp_b, exp_c;
    reg [22:0] frac_a, frac_b, frac_c;
    reg [23:0] sig_a, sig_b, sig_c;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    a = 0; b = 0; c = 0;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0;
    fma_s_s1_special_c = 1'b0; fma_s_s1_spval_c = 64'b0;
    fma_s_s1_spff_c = 5'b00000; fma_s_s1_product_c = 48'b0;
    fma_s_s1_sigc_c = 24'b0; fma_s_s1_ep_c = 0; fma_s_s1_ec_c = 0;
    a = rs1_value[31:0]; b = rs2_value[31:0]; c = rs3_value[31:0];
    sign_a = a[31]; sign_b = b[31];
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
    if (result_is_nan) begin
      fma_s_s1_special_c = 1'b1;
      fma_s_s1_spval_c = 64'hffffffff7fc00000;
      fma_s_s1_spff_c = nv ? `FP_FLAG_NV : 5'b00000;
    end else if (prod_is_inf) begin
      fma_s_s1_special_c = 1'b1;
      fma_s_s1_spval_c = {32'hffff_ffff, sign_p, 8'hff, 23'b0};
    end else if (c_is_inf) begin
      fma_s_s1_special_c = 1'b1;
      fma_s_s1_spval_c = {32'hffff_ffff, sign_c, 8'hff, 23'b0};
    end else if (prod_is_zero && c_is_zero) begin
      fma_s_s1_special_c = 1'b1;
      fma_s_s1_spval_c = {32'hffff_ffff,
          ((sign_p == sign_c) ? sign_p : (rm_i == 3'b010)), 31'b0};
    end else if (prod_is_zero) begin
      fma_s_s1_special_c = 1'b1;
      fma_s_s1_spval_c = {32'hffff_ffff, sign_c, exp_c, frac_c};
    end
    exp_a_eff = (exp_a == 8'h00) ? 1 : exp_a;
    exp_b_eff = (exp_b == 8'h00) ? 1 : exp_b;
    exp_c_eff = (exp_c == 8'h00) ? 1 : exp_c;
    sig_a = {(exp_a != 8'h00), frac_a};
    sig_b = {(exp_b != 8'h00), frac_b};
    sig_c = {(exp_c != 8'h00), frac_c};
    fma_s_s1_product_c = sig_a * sig_b;
    fma_s_s1_ep_c = exp_a_eff + exp_b_eff - 300;
    fma_s_s1_ec_c = exp_c_eff - 150;
    fma_s_s1_sigc_c = sig_c;
    fma_s_s1_signp_c = sign_p;
    fma_s_s1_signc_c = sign_c;
    fma_s_s1_rm_c = rm_i;
  end

  always @(*) begin : fma_s_s2_comb
    reg [5:0] lzc_p;
    reg [4:0] lzc_c24;
    integer ep, ec, pw, cw, ref_w;
    lzc_p = fp_lzc_48(fma_s_s1_product_q);
    lzc_c24 = fp_norm_shift_24(fma_s_s1_sigc_q);
    ep = fma_s_s1_ep_q; ec = fma_s_s1_ec_q;
    pw = ep + 47 - lzc_p;
    cw = ec + 23 - lzc_c24;
    ref_w = (pw >= cw) ? pw : cw;
    fma_s_s2_refw_c = ref_w;
    fma_s_s2_shiftp_c = ep - ref_w + 126;
    fma_s_s2_shiftc_c = ec - ref_w + 126;
  end

  always @(*) begin : fma_s_s3_comb
    reg [127:0] prod_field, addend_field;
    integer shift_p, shift_c, negsh;
    reg sign_p, sign_c;
    shift_p = fma_s_s2_shiftp_q; shift_c = fma_s_s2_shiftc_q;
    sign_p = fma_s_s2_signp_q; sign_c = fma_s_s2_signc_q;
    negsh = 0;
    if (shift_p >= 0) begin
      prod_field = {80'b0, fma_s_s2_product_q} << shift_p;
    end else begin
      negsh = (-shift_p > 128) ? 128 : -shift_p;
      prod_field = fp_shift_right_jam_128(
          {80'b0, fma_s_s2_product_q}, negsh[7:0]);
    end
    if (shift_c >= 0) begin
      addend_field = {104'b0, fma_s_s2_sigc_q} << shift_c;
    end else begin
      negsh = (-shift_c > 128) ? 128 : -shift_c;
      addend_field = fp_shift_right_jam_128(
          {104'b0, fma_s_s2_sigc_q}, negsh[7:0]);
    end
    if (sign_p == sign_c) begin
      fma_s_s3_mag_c = prod_field + addend_field;
      fma_s_s3_ressign_c = sign_p;
    end else if (prod_field >= addend_field) begin
      fma_s_s3_mag_c = prod_field - addend_field;
      fma_s_s3_ressign_c = sign_p;
    end else begin
      fma_s_s3_mag_c = addend_field - prod_field;
      fma_s_s3_ressign_c = sign_c;
    end
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      fma_d_s1_special_q <= 1'b0; fma_d_s1_spval_q <= 64'b0;
      fma_d_s1_spff_q <= 5'b0; fma_d_s1_product_q <= 106'b0;
      fma_d_s1_sigc_q <= 53'b0; fma_d_s1_ep_q <= 0;
      fma_d_s1_ec_q <= 0; fma_d_s1_signp_q <= 1'b0;
      fma_d_s1_signc_q <= 1'b0; fma_d_s1_rm_q <= 3'b0;
      fma_d_s2_special_q <= 1'b0; fma_d_s2_spval_q <= 64'b0;
      fma_d_s2_spff_q <= 5'b0; fma_d_s2_product_q <= 106'b0;
      fma_d_s2_sigc_q <= 53'b0; fma_d_s2_shiftp_q <= 0;
      fma_d_s2_shiftc_q <= 0; fma_d_s2_refw_q <= 0;
      fma_d_s2_signp_q <= 1'b0; fma_d_s2_signc_q <= 1'b0;
      fma_d_s2_rm_q <= 3'b0;
      fma_d_special_q_o <= 1'b0; fma_d_spval_q_o <= 64'b0;
      fma_d_spff_q_o <= 5'b0; fma_d_mag_q_o <= 128'b0;
      fma_d_ressign_q_o <= 1'b0; fma_d_refw_q_o <= 0;
      fma_d_rm_q_o <= 3'b0;
      fma_s_s1_special_q <= 1'b0; fma_s_s1_spval_q <= 64'b0;
      fma_s_s1_spff_q <= 5'b0; fma_s_s1_product_q <= 48'b0;
      fma_s_s1_sigc_q <= 24'b0; fma_s_s1_ep_q <= 0;
      fma_s_s1_ec_q <= 0; fma_s_s1_signp_q <= 1'b0;
      fma_s_s1_signc_q <= 1'b0; fma_s_s1_rm_q <= 3'b0;
      fma_s_s2_special_q <= 1'b0; fma_s_s2_spval_q <= 64'b0;
      fma_s_s2_spff_q <= 5'b0; fma_s_s2_product_q <= 48'b0;
      fma_s_s2_sigc_q <= 24'b0; fma_s_s2_shiftp_q <= 0;
      fma_s_s2_shiftc_q <= 0; fma_s_s2_refw_q <= 0;
      fma_s_s2_signp_q <= 1'b0; fma_s_s2_signc_q <= 1'b0;
      fma_s_s2_rm_q <= 3'b0;
      fma_s_special_q_o <= 1'b0; fma_s_spval_q_o <= 64'b0;
      fma_s_spff_q_o <= 5'b0; fma_s_mag_q_o <= 128'b0;
      fma_s_ressign_q_o <= 1'b0; fma_s_refw_q_o <= 0;
      fma_s_rm_q_o <= 3'b0;
    end else begin
      fma_d_s1_special_q <= fma_d_s1_special_c;
      fma_d_s1_spval_q <= fma_d_s1_spval_c;
      fma_d_s1_spff_q <= fma_d_s1_spff_c;
      fma_d_s1_product_q <= fma_d_s1_product_c;
      fma_d_s1_sigc_q <= fma_d_s1_sigc_c;
      fma_d_s1_ep_q <= fma_d_s1_ep_c;
      fma_d_s1_ec_q <= fma_d_s1_ec_c;
      fma_d_s1_signp_q <= fma_d_s1_signp_c;
      fma_d_s1_signc_q <= fma_d_s1_signc_c;
      fma_d_s1_rm_q <= fma_d_s1_rm_c;
      fma_d_s2_special_q <= fma_d_s1_special_q;
      fma_d_s2_spval_q <= fma_d_s1_spval_q;
      fma_d_s2_spff_q <= fma_d_s1_spff_q;
      fma_d_s2_product_q <= fma_d_s1_product_q;
      fma_d_s2_sigc_q <= fma_d_s1_sigc_q;
      fma_d_s2_shiftp_q <= fma_d_s2_shiftp_c;
      fma_d_s2_shiftc_q <= fma_d_s2_shiftc_c;
      fma_d_s2_refw_q <= fma_d_s2_refw_c;
      fma_d_s2_signp_q <= fma_d_s1_signp_q;
      fma_d_s2_signc_q <= fma_d_s1_signc_q;
      fma_d_s2_rm_q <= fma_d_s1_rm_q;
      fma_d_special_q_o <= fma_d_s2_special_q;
      fma_d_spval_q_o <= fma_d_s2_spval_q;
      fma_d_spff_q_o <= fma_d_s2_spff_q;
      fma_d_mag_q_o <= fma_d_s3_mag_c;
      fma_d_ressign_q_o <= fma_d_s3_ressign_c;
      fma_d_refw_q_o <= fma_d_s2_refw_q;
      fma_d_rm_q_o <= fma_d_s2_rm_q;
      fma_s_s1_special_q <= fma_s_s1_special_c;
      fma_s_s1_spval_q <= fma_s_s1_spval_c;
      fma_s_s1_spff_q <= fma_s_s1_spff_c;
      fma_s_s1_product_q <= fma_s_s1_product_c;
      fma_s_s1_sigc_q <= fma_s_s1_sigc_c;
      fma_s_s1_ep_q <= fma_s_s1_ep_c;
      fma_s_s1_ec_q <= fma_s_s1_ec_c;
      fma_s_s1_signp_q <= fma_s_s1_signp_c;
      fma_s_s1_signc_q <= fma_s_s1_signc_c;
      fma_s_s1_rm_q <= fma_s_s1_rm_c;
      fma_s_s2_special_q <= fma_s_s1_special_q;
      fma_s_s2_spval_q <= fma_s_s1_spval_q;
      fma_s_s2_spff_q <= fma_s_s1_spff_q;
      fma_s_s2_product_q <= fma_s_s1_product_q;
      fma_s_s2_sigc_q <= fma_s_s1_sigc_q;
      fma_s_s2_shiftp_q <= fma_s_s2_shiftp_c;
      fma_s_s2_shiftc_q <= fma_s_s2_shiftc_c;
      fma_s_s2_refw_q <= fma_s_s2_refw_c;
      fma_s_s2_signp_q <= fma_s_s1_signp_q;
      fma_s_s2_signc_q <= fma_s_s1_signc_q;
      fma_s_s2_rm_q <= fma_s_s1_rm_q;
      fma_s_special_q_o <= fma_s_s2_special_q;
      fma_s_spval_q_o <= fma_s_s2_spval_q;
      fma_s_spff_q_o <= fma_s_s2_spff_q;
      fma_s_mag_q_o <= fma_s_s3_mag_c;
      fma_s_ressign_q_o <= fma_s_s3_ressign_c;
      fma_s_refw_q_o <= fma_s_s2_refw_q;
      fma_s_rm_q_o <= fma_s_s2_rm_q;
    end
  end

endmodule
