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
  integer i;

  // 组合读 + 时钟沿写，模拟当前 cache hit 低延迟路径使用的 SRAM macro 专用端口。
  assign rd_data_o = rd_en_i ? mem_q[rd_addr_i] : {DATA_WIDTH{1'b0}};

  always @(posedge clk) begin
    if (clear_i) begin
      /* verilator lint_off BLKSEQ */
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem_q[i] = {DATA_WIDTH{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else if (wr_en_i) begin
      mem_q[wr_addr_i] <= (mem_q[wr_addr_i] & ~wr_mask_i) | (wr_data_i & wr_mask_i);
    end
  end

endmodule
