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
  reg [DATA_WIDTH-1:0] rd0_data_q;
  reg [DATA_WIDTH-1:0] rd1_data_q;
  integer i;

  // ICache 跨 line 取指仍使用两个读口，但读数据必须晚一拍返回。
  assign rd0_data_o = rd0_data_q;
  assign rd1_data_o = rd1_data_q;

  always @(posedge clk) begin
    if (clear_i) begin
      rd0_data_q <= {DATA_WIDTH{1'b0}};
      rd1_data_q <= {DATA_WIDTH{1'b0}};
      /* verilator lint_off BLKSEQ */
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem_q[i] = {DATA_WIDTH{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else begin
      if (rd0_en_i && !wr_en_i) begin
        rd0_data_q <= mem_q[rd0_addr_i];
      end
      if (rd1_en_i && !wr_en_i) begin
        rd1_data_q <= mem_q[rd1_addr_i];
      end
      if (wr_en_i) begin
        mem_q[wr_addr_i] <= (mem_q[wr_addr_i] & ~wr_mask_i) | (wr_data_i & wr_mask_i);
      end
    end
  end

endmodule
