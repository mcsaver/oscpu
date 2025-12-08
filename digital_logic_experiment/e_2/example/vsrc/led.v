module led(
  input clk,
  input rst,
  input [4:0] btn,
  input [8:0] sw,
  output [15:0] ledr,
  output input_f
);
  reg [31:0] count;
  reg [6:0] led;
  always @(posedge clk) begin
    if (rst) begin led <= 1; count <= 0; end
    else begin
      if (count == 0) led <= {led[5:0], led[6]};
      count <= (count >= 5000000 ? 32'b0 : count + 1);
    end
  end

  assign input_f = |sw[7:0];
  assign ledr = {led[6:0], sw};
endmodule
