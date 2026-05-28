`include "define.v"

// RV32M 乘法从 EX 组合路径拆出，使用固定 5 级流水部分积累加，降低单拍关键路径压力。
module Rv32Multiplier (
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

  reg valid_s0_q;
  reg valid_s1_q;
  reg valid_s2_q;
  reg valid_s3_q;
  reg valid_s4_q;
  reg [2:0] funct3_s0_q;
  reg [2:0] funct3_s1_q;
  reg [2:0] funct3_s2_q;
  reg [2:0] funct3_s3_q;
  reg [`XLEN-1:0] lhs_s0_q;
  reg [`XLEN-1:0] lhs_s1_q;
  reg [`XLEN-1:0] lhs_s2_q;
  reg [`XLEN-1:0] lhs_s3_q;
  reg [`XLEN-1:0] rhs_s0_q;
  reg [`XLEN-1:0] rhs_s1_q;
  reg [`XLEN-1:0] rhs_s2_q;
  reg [`XLEN-1:0] rhs_s3_q;
  reg [63:0] accum_s0_q;
  reg [63:0] accum_s1_q;
  reg [63:0] accum_s2_q;
  reg [63:0] accum_s3_q;
  reg neg_s0_q;
  reg neg_s1_q;
  reg neg_s2_q;
  reg neg_s3_q;
  reg [`XLEN-1:0] data_s4_q;

  wire req_src1_signed_w = (req_funct3_i == 3'b001) || (req_funct3_i == 3'b010);
  wire req_src2_signed_w = (req_funct3_i == 3'b001);
  wire req_src1_neg_w = req_src1_signed_w && req_src1_i[`XLEN-1];
  wire req_src2_neg_w = req_src2_signed_w && req_src2_i[`XLEN-1];
  wire [`XLEN-1:0] req_lhs_abs_w = req_src1_neg_w ? ((~req_src1_i) + 32'd1) : req_src1_i;
  wire [`XLEN-1:0] req_rhs_abs_w = req_src2_neg_w ? ((~req_src2_i) + 32'd1) : req_src2_i;
  wire req_result_neg_w = req_src1_neg_w ^ req_src2_neg_w;

  wire ready_s4_w = (~valid_s4_q) || rsp_ready_i;
  wire ready_s3_w = (~valid_s3_q) || ready_s4_w;
  wire ready_s2_w = (~valid_s2_q) || ready_s3_w;
  wire ready_s1_w = (~valid_s1_q) || ready_s2_w;
  wire ready_s0_w = (~valid_s0_q) || ready_s1_w;
  wire [63:0] accum_s4_w = accum_s3_q + partial_product_chunk(lhs_s3_q, rhs_s3_q, 6'd26, 6'd31);
  wire [63:0] product_s4_w = neg_s3_q ? ((~accum_s4_w) + 64'd1) : accum_s4_w;
  wire [`XLEN-1:0] result_s4_w =
      (funct3_s3_q == 3'b000) ? product_s4_w[31:0] :
      ((funct3_s3_q == 3'b001) ||
       (funct3_s3_q == 3'b010) ||
       (funct3_s3_q == 3'b011)) ? product_s4_w[63:32] :
      {`XLEN{1'b0}};

  function [63:0] partial_product_chunk;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    input [5:0] lo_bit;
    input [5:0] hi_bit;
    integer i;
    begin
      partial_product_chunk = 64'd0;
      for (i = 0; i < `XLEN; i = i + 1) begin
        if ((i >= lo_bit) && (i <= hi_bit) && rhs[i])
          partial_product_chunk = partial_product_chunk + ({32'd0, lhs} << i);
      end
    end
  endfunction

  assign req_ready_o = (~flush_i) && ready_s0_w;
  assign rsp_valid_o = valid_s4_q;
  assign rsp_data_o = data_s4_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      valid_s0_q <= 1'b0;
      valid_s1_q <= 1'b0;
      valid_s2_q <= 1'b0;
      valid_s3_q <= 1'b0;
      valid_s4_q <= 1'b0;
      funct3_s0_q <= 3'b000;
      funct3_s1_q <= 3'b000;
      funct3_s2_q <= 3'b000;
      funct3_s3_q <= 3'b000;
      lhs_s0_q <= {`XLEN{1'b0}};
      lhs_s1_q <= {`XLEN{1'b0}};
      lhs_s2_q <= {`XLEN{1'b0}};
      lhs_s3_q <= {`XLEN{1'b0}};
      rhs_s0_q <= {`XLEN{1'b0}};
      rhs_s1_q <= {`XLEN{1'b0}};
      rhs_s2_q <= {`XLEN{1'b0}};
      rhs_s3_q <= {`XLEN{1'b0}};
      accum_s0_q <= 64'd0;
      accum_s1_q <= 64'd0;
      accum_s2_q <= 64'd0;
      accum_s3_q <= 64'd0;
      neg_s0_q <= 1'b0;
      neg_s1_q <= 1'b0;
      neg_s2_q <= 1'b0;
      neg_s3_q <= 1'b0;
      data_s4_q <= {`XLEN{1'b0}};
    end else begin
      if (ready_s4_w) begin
        valid_s4_q <= valid_s3_q;
        if (valid_s3_q)
          data_s4_q <= result_s4_w;
      end

      if (ready_s3_w) begin
        valid_s3_q <= valid_s2_q;
        if (valid_s2_q) begin
          funct3_s3_q <= funct3_s2_q;
          lhs_s3_q <= lhs_s2_q;
          rhs_s3_q <= rhs_s2_q;
          accum_s3_q <= accum_s2_q + partial_product_chunk(lhs_s2_q, rhs_s2_q, 6'd20, 6'd25);
          neg_s3_q <= neg_s2_q;
        end
      end

      if (ready_s2_w) begin
        valid_s2_q <= valid_s1_q;
        if (valid_s1_q) begin
          funct3_s2_q <= funct3_s1_q;
          lhs_s2_q <= lhs_s1_q;
          rhs_s2_q <= rhs_s1_q;
          accum_s2_q <= accum_s1_q + partial_product_chunk(lhs_s1_q, rhs_s1_q, 6'd14, 6'd19);
          neg_s2_q <= neg_s1_q;
        end
      end

      if (ready_s1_w) begin
        valid_s1_q <= valid_s0_q;
        if (valid_s0_q) begin
          funct3_s1_q <= funct3_s0_q;
          lhs_s1_q <= lhs_s0_q;
          rhs_s1_q <= rhs_s0_q;
          accum_s1_q <= accum_s0_q + partial_product_chunk(lhs_s0_q, rhs_s0_q, 6'd7, 6'd13);
          neg_s1_q <= neg_s0_q;
        end
      end

      if (ready_s0_w) begin
        valid_s0_q <= req_valid_i && req_ready_o;
        if (req_valid_i && req_ready_o) begin
          funct3_s0_q <= req_funct3_i;
          lhs_s0_q <= req_lhs_abs_w;
          rhs_s0_q <= req_rhs_abs_w;
          accum_s0_q <= partial_product_chunk(req_lhs_abs_w, req_rhs_abs_w, 6'd0, 6'd6);
          neg_s0_q <= req_result_neg_w;
        end
      end
    end
  end

endmodule
