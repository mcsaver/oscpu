`include "define.v"

// FMUL S1 production child：独占 single/double 的 special/product/exp/sign/rm Q。
// 本模块每拍采样输入；不拥有 valid、ROB age、kill、writeback 或 commit 状态。
module OooFpMulProductPipe (
  input                  clk,
  input                  rst,
  input                  flush_i,
  input  [`XLEN-1:0]     frs1_value_i,
  input  [`XLEN-1:0]     frs2_value_i,
  input  [2:0]           rm_i,

  output reg             mul_d_special_q_o,
  output reg [63:0]      mul_d_spval_q_o,
  output reg [4:0]       mul_d_spff_q_o,
  output reg [105:0]     mul_d_product_q_o,
  output reg signed [13:0] mul_d_expz_q_o,
  output reg             mul_d_signz_q_o,
  output reg [2:0]       mul_d_rm_q_o,

  output reg             mul_s_special_q_o,
  output reg [63:0]      mul_s_spval_q_o,
  output reg [4:0]       mul_s_spff_q_o,
  output reg [47:0]      mul_s_product_q_o,
  output reg signed [13:0] mul_s_expz_q_o,
  output reg             mul_s_signz_q_o,
  output reg [2:0]       mul_s_rm_q_o
);

  `include "execute/OooFpPredicates.v"

  reg        mul_d_special_c;
  reg [63:0] mul_d_spval_c;
  reg [4:0]  mul_d_spff_c;
  reg [105:0] mul_d_product_c;
  reg signed [13:0] mul_d_expz_c;
  reg        mul_d_signz_c;
  reg [2:0]  mul_d_rm_c;

  reg        mul_s_special_c;
  reg [63:0] mul_s_spval_c;
  reg [4:0]  mul_s_spff_c;
  reg [47:0] mul_s_product_c;
  reg signed [13:0] mul_s_expz_c;
  reg        mul_s_signz_c;
  reg [2:0]  mul_s_rm_c;

  // S1 double：特殊值判定 + 53x53 尾数积 + 指数基。
  always @(*) begin : mul_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg sign_z;
    reg [10:0] exp_a, exp_b;
    reg [51:0] frac_a, frac_b;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    reg [52:0] sig_a, sig_b;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    sig_a = 0; sig_b = 0;
    mul_d_special_c = 1'b0; mul_d_spval_c = 64'b0; mul_d_spff_c = 5'b0;
    mul_d_product_c = 106'b0; mul_d_expz_c = 0;
    sign_z = rs1_value[63] ^ rs2_value[63];
    exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52];
    frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0];
    a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
    b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
    a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
    b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
    a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
    b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);
    if (a_is_nan || b_is_nan || (a_is_inf && b_is_zero) ||
        (b_is_inf && a_is_zero)) begin
      mul_d_special_c = 1'b1;
      mul_d_spval_c = 64'h7ff8000000000000;
      mul_d_spff_c = (fp_is_snan_d_value(rs1_value) ||
                      fp_is_snan_d_value(rs2_value) ||
                      (a_is_inf && b_is_zero) ||
                      (b_is_inf && a_is_zero)) ? `FP_FLAG_NV : 5'b00000;
    end else if (a_is_inf || b_is_inf) begin
      mul_d_special_c = 1'b1;
      mul_d_spval_c = {sign_z, 11'h7ff, 52'b0};
    end else if (a_is_zero || b_is_zero) begin
      mul_d_special_c = 1'b1;
      mul_d_spval_c = {sign_z, 63'b0};
    end
    sig_a = {(exp_a != 11'h000), frac_a};
    sig_b = {(exp_b != 11'h000), frac_b};
    mul_d_expz_c = ((exp_a == 11'h000) ? 14'd1 : {3'b0, exp_a}) +
                   ((exp_b == 11'h000) ? 14'd1 : {3'b0, exp_b}) -
                   14'd1023;
    mul_d_product_c = sig_a * sig_b;
    mul_d_signz_c = sign_z;
    mul_d_rm_c = rm_i;
  end

  // S1 single：特殊值判定 + 24x24 尾数积 + 指数基。
  always @(*) begin : mul_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg [31:0] a, b;
    reg sign_z;
    reg [7:0] exp_a, exp_b;
    reg [22:0] frac_a, frac_b;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    reg [23:0] sig_a, sig_b;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    a = 0; b = 0; sig_a = 0; sig_b = 0;
    mul_s_special_c = 1'b0; mul_s_spval_c = 64'b0; mul_s_spff_c = 5'b0;
    mul_s_product_c = 48'b0; mul_s_expz_c = 0;
    a = rs1_value[31:0]; b = rs2_value[31:0];
    sign_z = a[31] ^ b[31];
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
    if (a_is_nan || b_is_nan || (a_is_inf && b_is_zero) ||
        (b_is_inf && a_is_zero)) begin
      mul_s_special_c = 1'b1;
      mul_s_spval_c = 64'hffffffff7fc00000;
      mul_s_spff_c = (fp_is_snan_s_value(rs1_value) ||
                      fp_is_snan_s_value(rs2_value) ||
                      (a_is_inf && b_is_zero) ||
                      (b_is_inf && a_is_zero)) ? `FP_FLAG_NV : 5'b00000;
    end else if (a_is_inf || b_is_inf) begin
      mul_s_special_c = 1'b1;
      mul_s_spval_c = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
    end else if (a_is_zero || b_is_zero) begin
      mul_s_special_c = 1'b1;
      mul_s_spval_c = {32'hffff_ffff, sign_z, 31'b0};
    end
    sig_a = {(exp_a != 8'h00), frac_a};
    sig_b = {(exp_b != 8'h00), frac_b};
    mul_s_expz_c = ((exp_a == 8'h00) ? 14'd1 : {6'b0, exp_a}) +
                   ((exp_b == 8'h00) ? 14'd1 : {6'b0, exp_b}) -
                   14'd127;
    mul_s_product_c = sig_a * sig_b;
    mul_s_signz_c = sign_z;
    mul_s_rm_c = rm_i;
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      mul_d_special_q_o <= 1'b0;
      mul_d_spval_q_o <= 64'b0;
      mul_d_spff_q_o <= 5'b0;
      mul_d_product_q_o <= 106'b0;
      mul_d_expz_q_o <= 0;
      mul_d_signz_q_o <= 1'b0;
      mul_d_rm_q_o <= 3'b0;
      mul_s_special_q_o <= 1'b0;
      mul_s_spval_q_o <= 64'b0;
      mul_s_spff_q_o <= 5'b0;
      mul_s_product_q_o <= 48'b0;
      mul_s_expz_q_o <= 0;
      mul_s_signz_q_o <= 1'b0;
      mul_s_rm_q_o <= 3'b0;
    end else begin
      mul_d_special_q_o <= mul_d_special_c;
      mul_d_spval_q_o <= mul_d_spval_c;
      mul_d_spff_q_o <= mul_d_spff_c;
      mul_d_product_q_o <= mul_d_product_c;
      mul_d_expz_q_o <= mul_d_expz_c;
      mul_d_signz_q_o <= mul_d_signz_c;
      mul_d_rm_q_o <= mul_d_rm_c;
      mul_s_special_q_o <= mul_s_special_c;
      mul_s_spval_q_o <= mul_s_spval_c;
      mul_s_spff_q_o <= mul_s_spff_c;
      mul_s_product_q_o <= mul_s_product_c;
      mul_s_expz_q_o <= mul_s_expz_c;
      mul_s_signz_q_o <= mul_s_signz_c;
      mul_s_rm_q_o <= mul_s_rm_c;
    end
  end

endmodule
