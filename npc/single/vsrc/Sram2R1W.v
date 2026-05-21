`include "define.v"

module Sram2R1W #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 6,
  parameter DEPTH = 64
) (
  input clk,
  input clear_i,

  input rd0_en_i,
  input [ADDR_WIDTH-1:0] rd0_addr_i,
  output [DATA_WIDTH-1:0] rd0_data_o,

  input rd1_en_i,
  input [ADDR_WIDTH-1:0] rd1_addr_i,
  output [DATA_WIDTH-1:0] rd1_data_o,

  input wr_en_i,
  input [ADDR_WIDTH-1:0] wr_addr_i,
  input [DATA_WIDTH-1:0] wr_data_i,
  input [DATA_WIDTH-1:0] wr_mask_i
);

  reg [DATA_WIDTH-1:0] mem_q [0:DEPTH-1];
  integer i;

  // ICache 可能在同一拍拼接跨 line 的 4 字节窗口，因此提供两个专用组合读口。
  assign rd0_data_o = rd0_en_i ? mem_q[rd0_addr_i] : {DATA_WIDTH{1'b0}};
  assign rd1_data_o = rd1_en_i ? mem_q[rd1_addr_i] : {DATA_WIDTH{1'b0}};

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
