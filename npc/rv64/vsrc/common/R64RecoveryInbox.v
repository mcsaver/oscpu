`include "R64Protocol.vh"
// Each domain owns its recovery observation. The publisher revokes architectural
// authority immediately; consumers drain/cancel their local transactions next cycle.
// Lifecycle admission fences the publication and delivery cycles.
module R64RecoveryInbox #(parameter N = 32) (
  input clk_i,
  input rst_i,
  input [`R64_RECOVERY_W(N)-1:0] event_i,
  output reg [`R64_RECOVERY_W(N)-1:0] event_o,
  output pending_o
);
  always @(posedge clk_i) begin
    if (rst_i) event_o <= 0;
    else event_o <= event_i;
  end
  assign pending_o = event_o[`R64_RECOVERY_FLUSH(N)] |
                     event_o[`R64_RECOVERY_ACTIVE(N)] |
                     event_o[`R64_RECOVERY_REDIRECT(N)];
endmodule
