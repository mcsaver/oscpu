module StaExportLeaf #(
  parameter integer W = 7
) (
  input  wire                  clk,
  input  wire                  en_i,
  input  wire signed [W-1:0]   a_i,
  input  wire signed [W-1:0]   b_i,
  output reg  signed [W:0]     sum_o
);
  always @(posedge clk) begin
    if (en_i)
      sum_o <= a_i + b_i;
  end
endmodule

module StaExportCompatFixture (
  input  wire               clk,
  input  wire               en_i,
  input  wire signed [6:0]  a_i,
  input  wire signed [6:0]  b_i,
  output wire signed [7:0]  sum_o
);
  StaExportLeaf #(.W(7)) u_leaf (
    .clk   (clk),
    .en_i  (en_i),
    .a_i   (a_i),
    .b_i   (b_i),
    .sum_o (sum_o)
  );
endmodule
