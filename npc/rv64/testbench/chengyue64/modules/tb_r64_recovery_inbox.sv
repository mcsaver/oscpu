`timescale 1ns/1ps
`include "R64Protocol.vh"
module tb_r64_recovery_inbox;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;
  reg [`R64_RECOVERY_W(32)-1:0] source=0;
  wire [`R64_RECOVERY_W(32)-1:0] delivered;
  wire pending;
  reg [`R64_RECOVERY_W(32)-1:0] expected=0;
  integer n;
  R64RecoveryInbox dut(.clk_i(clk),.rst_i(rst),.event_i(source),
    .event_o(delivered),.pending_o(pending));
  task tick;
    begin
      @(posedge clk);
      expected = rst ? 0 : source;
      #1;
      if (delivered !== expected) $fatal(1,"recovery record was lost or mixed");
      if (pending !== (expected[98] | expected[33] | expected[32]))
        $fatal(1,"recovery pending changed event meaning");
      @(negedge clk);
    end
  endtask
  initial begin
    tick; rst=0;
    // Inactive candidates are hints, including all-one victims.
    source[31:0]=32'hffffffff;
    #1; if (delivered!==0 || pending) $fatal(1,"source bypassed inbox");
    tick; if (pending) $fatal(1,"hint became cancellation");
    // Back-to-back full, selective and zero-victim redirect events retain
    // each complete record; no coalescing can overwrite a redirect PC.
    for(n=0;n<24;n=n+1) begin
      source=0; source[97:34]=64'h80000000 + 64'(n*4);
      source[98]=(n%3==0); source[33]=(n%3==1); source[32]=(n%3==2);
      source[31:0]=(n%3==0) ? 0 : (32'b1 << n);
      #1; if(delivered!==expected) $fatal(1,"combinational source propagation");
      tick; if(!pending) $fatal(1,"zero-victim event lost");
    end
    source=0; tick;
    if(pending) $fatal(1,"event repeated after delivery");
    rst=1; source='1; tick;
    $display("[PASS] tb_r64_recovery_inbox"); $finish;
  end
endmodule
