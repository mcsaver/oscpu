module OooBackendDrainTracker (
  input clk,
  input rst,

  input backend_empty_i,
  input dispatch_fire_i,
  input force_drained_i,

  output drained_o
);

  reg drained_q;

  assign drained_o = drained_q;

  always @(posedge clk) begin
    if (rst || force_drained_i) begin
      drained_q <= 1'b1;
    end else begin
      drained_q <= backend_empty_i && !dispatch_fire_i;
    end
  end

endmodule
