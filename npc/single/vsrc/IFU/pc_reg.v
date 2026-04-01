`include "define.v"

module pc_reg (
  input clk,
  input [`DATA_WIDTH_pc-1:0] wdata,
  input [`ADDR_WIDTH_pc-1:0] waddr,
  input wen,
  output [`DATA_WIDTH_pc-1:0] data
);
  reg [`DATA_WIDTH_pc-1:0] rf [2**`ADDR_WIDTH_pc-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end

  assign data = rf;

endmodule
