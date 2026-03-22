`include "define.v"

module RegisterFile (
  input clk,
  input [`DATA_WIDTH-1:0] wdata,
  input [`ADDR_WIDTH-1:0] waddr,
  input wen
);
  reg [`DATA_WIDTH-1:0] rf [2**`ADDR_WIDTH-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end
endmodule
