`include "define.v"

// 这个单元把 DIV/REM 从 EX 组合路径移走，用 1bit/周期的迭代除法换取可综合、可收敛的 ASIC 时序。
module Rv32Divider (
  input clk,
  input rst,

  input flush_i,
  input req_valid_i,
  output req_ready_o,
  input [2:0] req_funct3_i,
  input [`XLEN-1:0] req_src1_i,
  input [`XLEN-1:0] req_src2_i,

  output rsp_valid_o,
  input rsp_ready_i,
  output [`XLEN-1:0] rsp_data_o
);

  reg busy_q;
  reg rsp_valid_q;
  reg [`XLEN-1:0] rsp_data_q;
  reg [`XLEN-1:0] dividend_q;
  reg [`XLEN-1:0] divisor_q;
  reg [`XLEN-2:0] quotient_shift_q;
  reg [`XLEN-1:0] remainder_q;
  reg [5:0] bit_count_q;
  reg want_rem_q;
  reg quotient_neg_q;
  reg remainder_neg_q;

  wire [`XLEN-1:0] xlen_one_w = {{(`XLEN-1){1'b0}}, 1'b1};
  wire [`XLEN-1:0] xlen_signed_min_w = {1'b1, {(`XLEN-1){1'b0}}};
  wire [`XLEN-1:0] xlen_all_ones_w = {`XLEN{1'b1}};
  wire req_is_divrem_w = req_funct3_i[2];
  wire req_is_rem_w = req_is_divrem_w && req_funct3_i[1];
  wire req_is_signed_w = req_is_divrem_w && ~req_funct3_i[0];
  wire req_divisor_zero_w = (req_src2_i == {`XLEN{1'b0}});
  wire req_signed_overflow_w = req_is_signed_w &&
                               (req_src1_i == xlen_signed_min_w) &&
                               (req_src2_i == xlen_all_ones_w);
  wire req_special_w = req_divisor_zero_w | req_signed_overflow_w;
  wire [`XLEN-1:0] req_src1_abs_w =
      (req_is_signed_w && req_src1_i[`XLEN-1]) ? ((~req_src1_i) + xlen_one_w) : req_src1_i;
  wire [`XLEN-1:0] req_src2_abs_w =
      (req_is_signed_w && req_src2_i[`XLEN-1]) ? ((~req_src2_i) + xlen_one_w) : req_src2_i;
  wire [`XLEN-1:0] req_special_result_w =
      req_divisor_zero_w ? (req_is_rem_w ? req_src1_i : {`XLEN{1'b1}}) :
      req_is_rem_w ? {`XLEN{1'b0}} :
                     xlen_signed_min_w;

  wire [`XLEN:0] trial_remainder_w = {remainder_q, dividend_q[`XLEN-1]};
  wire trial_subtract_w = trial_remainder_w >= {1'b0, divisor_q};
  wire [`XLEN-1:0] next_remainder_w = trial_subtract_w ?
                                      (trial_remainder_w[`XLEN-1:0] - divisor_q) :
                                      trial_remainder_w[`XLEN-1:0];
  wire [`XLEN-1:0] next_quotient_w = {quotient_shift_q, trial_subtract_w};
  wire [`XLEN-1:0] final_quotient_w =
      quotient_neg_q ? ((~next_quotient_w) + xlen_one_w) : next_quotient_w;
  wire [`XLEN-1:0] final_remainder_w =
      remainder_neg_q ? ((~next_remainder_w) + xlen_one_w) : next_remainder_w;

  assign req_ready_o = ~busy_q & ~rsp_valid_q;
  assign rsp_valid_o = rsp_valid_q;
  assign rsp_data_o = rsp_data_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      busy_q <= 1'b0;
      rsp_valid_q <= 1'b0;
      rsp_data_q <= {`XLEN{1'b0}};
      dividend_q <= {`XLEN{1'b0}};
      divisor_q <= {`XLEN{1'b0}};
      quotient_shift_q <= {(`XLEN-1){1'b0}};
      remainder_q <= {`XLEN{1'b0}};
      bit_count_q <= 6'd0;
      want_rem_q <= 1'b0;
      quotient_neg_q <= 1'b0;
      remainder_neg_q <= 1'b0;
    end else begin
      if (rsp_valid_q && rsp_ready_i) begin
        rsp_valid_q <= 1'b0;
      end

      if (busy_q) begin
        dividend_q <= {dividend_q[`XLEN-2:0], 1'b0};
        quotient_shift_q <= next_quotient_w[`XLEN-2:0];
        remainder_q <= next_remainder_w;

        if (bit_count_q == (`XLEN - 1)) begin
          busy_q <= 1'b0;
          rsp_valid_q <= 1'b1;
          rsp_data_q <= want_rem_q ? final_remainder_w : final_quotient_w;
          bit_count_q <= 6'd0;
        end else begin
          bit_count_q <= bit_count_q + 6'd1;
        end
      end else if (req_valid_i && req_ready_o) begin
        if (req_special_w) begin
          rsp_valid_q <= 1'b1;
          rsp_data_q <= req_special_result_w;
        end else begin
          busy_q <= 1'b1;
          dividend_q <= req_src1_abs_w;
          divisor_q <= req_src2_abs_w;
          quotient_shift_q <= {(`XLEN-1){1'b0}};
          remainder_q <= {`XLEN{1'b0}};
          bit_count_q <= 6'd0;
          want_rem_q <= req_is_rem_w;
          quotient_neg_q <= req_is_signed_w && (req_src1_i[`XLEN-1] ^ req_src2_i[`XLEN-1]);
          remainder_neg_q <= req_is_signed_w && req_src1_i[`XLEN-1];
        end
      end
    end
  end

endmodule
