`include "define.v"

// 保留 single 的模块名以复用 filelist，但内部按 XLEN 实现 RVM 乘法。
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

  localparam PRODUCT_W = `XLEN * 2;

  reg rsp_valid_q;
  reg [`XLEN-1:0] rsp_data_q;

  wire signed [PRODUCT_W-1:0] src1_ss_w = {{`XLEN{req_src1_i[`XLEN-1]}}, req_src1_i};
  wire signed [PRODUCT_W-1:0] src2_ss_w = {{`XLEN{req_src2_i[`XLEN-1]}}, req_src2_i};
  wire signed [PRODUCT_W-1:0] src2_us_w = {{`XLEN{1'b0}}, req_src2_i};
  wire [PRODUCT_W-1:0] src1_uu_w = {{`XLEN{1'b0}}, req_src1_i};
  wire [PRODUCT_W-1:0] src2_uu_w = {{`XLEN{1'b0}}, req_src2_i};

  wire [PRODUCT_W-1:0] product_ss_w = src1_ss_w * src2_ss_w;
  wire [PRODUCT_W-1:0] product_su_w = src1_ss_w * src2_us_w;
  wire [PRODUCT_W-1:0] product_uu_w = src1_uu_w * src2_uu_w;

  wire [`XLEN-1:0] result_w =
      (req_funct3_i == 3'b000) ? product_uu_w[`XLEN-1:0] :
      (req_funct3_i == 3'b001) ? product_ss_w[PRODUCT_W-1:`XLEN] :
      (req_funct3_i == 3'b010) ? product_su_w[PRODUCT_W-1:`XLEN] :
      (req_funct3_i == 3'b011) ? product_uu_w[PRODUCT_W-1:`XLEN] :
      {`XLEN{1'b0}};

  wire req_fire_w = req_valid_i && req_ready_o;

  assign req_ready_o = !flush_i && (!rsp_valid_q || rsp_ready_i);
  assign rsp_valid_o = rsp_valid_q;
  assign rsp_data_o = rsp_data_q;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      rsp_valid_q <= 1'b0;
      rsp_data_q <= {`XLEN{1'b0}};
    end else begin
      if (req_fire_w) begin
        rsp_valid_q <= 1'b1;
        rsp_data_q <= result_w;
      end else if (rsp_valid_q && rsp_ready_i) begin
        rsp_valid_q <= 1'b0;
      end
    end
  end

endmodule
