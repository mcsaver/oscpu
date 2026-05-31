`include "define.v"

module Sram1Rw #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 6,
  parameter DEPTH = 64
) (
  input clk,
  input clear_i,

  input rd_en_i,
  input [ADDR_WIDTH-1:0] rd_addr_i,
  output [DATA_WIDTH-1:0] rd_data_o,

  input wr_en_i,
  input [ADDR_WIDTH-1:0] wr_addr_i,
  input [DATA_WIDTH-1:0] wr_data_i,
  input [DATA_WIDTH-1:0] wr_mask_i
);

  reg [DATA_WIDTH-1:0] mem_q [0:DEPTH-1];
  reg [DATA_WIDTH-1:0] rd_data_q;
  integer i;

  // 同步读 + 时钟沿写：cache 只能在发出读地址后的下一拍消费返回数据。
  assign rd_data_o = rd_data_q;

  always @(posedge clk) begin
    if (clear_i) begin
      rd_data_q <= {DATA_WIDTH{1'b0}};
      /* verilator lint_off BLKSEQ */
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem_q[i] = {DATA_WIDTH{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else begin
      if (rd_en_i && !wr_en_i) begin
        rd_data_q <= mem_q[rd_addr_i];
      end
      if (wr_en_i) begin
        mem_q[wr_addr_i] <= (mem_q[wr_addr_i] & ~wr_mask_i) | (wr_data_i & wr_mask_i);
      end
    end
  end

endmodule
