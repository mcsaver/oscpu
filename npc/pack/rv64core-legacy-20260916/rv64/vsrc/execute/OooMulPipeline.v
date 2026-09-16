`include "define.v"

// 64-bit 乘法数据通路。输入寄存后分为部分积、交叉项归并、最终进位三段。
// 每周期可接受一项；输出无反压，调用者须在接受输入时预留结果槽。
// 高半部符号修正：signed product high = unsigned high - (a_negative ? b : 0)
//                                               - (b_negative ? a : 0)。
module OooMulPipeline (
  input clk,
  input rst,
  input flush_i,
  input valid_i,
  input [63:0] src1_i,
  input [63:0] src2_i,
  input [2:0] funct3_i,
  input word_i,
  output valid_o,
  output [63:0] result_o
);
  reg [2:0] valid_q;
  reg [63:0] src1_q, src2_q;
  reg [2:0] funct3_q;
  reg word_q;
  reg [63:0] product_ll_q, product_lh_q, product_hl_q, product_hh_q;
  reg [63:0] correction_q;
  reg high_s1_q, word_s1_q;
  reg [65:0] cross_s2_q;
  reg [63:0] high_s2_q;
  reg [31:0] low_s2_q;
  reg high_s2_select_q, word_s2_q;

  wire [63:0] operand1_w = word_q ? {{32{src1_q[31]}},src1_q[31:0]} : src1_q;
  wire [63:0] operand2_w = word_q ? {{32{src2_q[31]}},src2_q[31:0]} : src2_q;
  wire negative1_w = ((funct3_q == 3'b001) || (funct3_q == 3'b010)) && operand1_w[63];
  wire negative2_w = (funct3_q == 3'b001) && operand2_w[63];
  wire [63:0] correction_w = (negative1_w ? operand2_w : 64'd0) +
                            (negative2_w ? operand1_w : 64'd0);
  wire [63:0] product_high_w = high_s2_q + {30'd0,cross_s2_q[65:32]};
  wire [63:0] result_w = high_s2_select_q ? product_high_w :
                                                        {cross_s2_q[31:0],low_s2_q};
  assign result_o = word_s2_q ? {{32{result_w[31]}},result_w[31:0]} : result_w;
  assign valid_o = valid_q[2];

  always @(posedge clk) begin
    if (rst || flush_i)
      valid_q <= 3'b000;
    else
      valid_q <= {valid_q[1:0],valid_i};

    if (valid_i) begin
      src1_q <= src1_i;
      src2_q <= src2_i;
      funct3_q <= funct3_i;
      word_q <= word_i;
    end
    if (valid_q[0]) begin
      product_ll_q <= operand1_w[31:0] * operand2_w[31:0];
      product_lh_q <= operand1_w[31:0] * operand2_w[63:32];
      product_hl_q <= operand1_w[63:32] * operand2_w[31:0];
      product_hh_q <= operand1_w[63:32] * operand2_w[63:32];
      correction_q <= correction_w;
      high_s1_q <= (funct3_q != 3'b000);
      word_s1_q <= word_q;
    end
    if (valid_q[1]) begin
      cross_s2_q <= {2'b00,product_lh_q} + {2'b00,product_hl_q} +
                    {34'd0,product_ll_q[63:32]};
      high_s2_q <= product_hh_q - correction_q;
      low_s2_q <= product_ll_q[31:0];
      high_s2_select_q <= high_s1_q;
      word_s2_q <= word_s1_q;
    end
  end
endmodule
