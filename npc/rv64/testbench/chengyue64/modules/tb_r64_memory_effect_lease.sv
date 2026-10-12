`timescale 1ns/1ps
`include "R64Protocol.vh"
module tb_r64_memory_effect_lease;
  parameter SUCCESSOR=1;
  reg successor=0;
  reg [8:0] next_tag=0;
  reg clk=0; always #5 clk=~clk;
  reg rst=1,present=0,complete=0,allow=1,recover=0,flush=0;
  reg [8:0] head=0;
  reg [7:0] kind=0;
  wire valid; wire [8:0] tag;
  integer k,n;
  R64MemoryEffectLease #(.SUCCESSOR_STORE_LEASE(SUCCESSOR)) dut(.clk_i(clk),.rst_i(rst),.head_present_i(present),
    .successor_grant_i(successor),.successor_tag_i(next_tag),
    .head_tag_i(head),.head_kind_i(kind),.head_complete_i(complete),
    .allow_i(allow),.recover_i(recover),.flush_i(flush),.valid_o(valid),.tag_o(tag));
  task tick; begin @(posedge clk); @(negedge clk); #1; end endtask
  initial begin
    repeat(2) tick; rst=0; tick;
    for(k=0;k<17;k=k+1) begin
      kind=8'(k); head=9'(32+k); present=1; complete=0;
      #1; if(valid) $fatal(1,"combinational grant");
      tick;
      if(valid !== (k>=2 && k<=4)) $fatal(1,"nonmemory or missing lease kind=%0d",k);
      if(valid) begin
        // Backpressure and branch recovery cannot revoke granted permission.
        recover=1; allow=0;
        repeat(5) begin
          tick; if(!valid || tag!=head) $fatal(1,"lease revoked before terminal");
        end
        recover=0;
        // The same full tag terminal releases even when allow is false (fault).
        complete=1; tick;
        if(valid) $fatal(1,"fault/terminal failed to release lease");
        allow=1;
        repeat(3) begin tick; if(valid) $fatal(1,"completed head regranted"); end
      end
      present=0; tick; complete=0; allow=1;
    end
    kind=`R64_K_STORE; head=9'h145; present=1; recover=1;
    tick; if(valid) $fatal(1,"grant crossed recovery");
    recover=0; flush=1;
    tick; if(valid) $fatal(1,"grant crossed fullflush");
    flush=0; complete=1;
    tick; if(valid) $fatal(1,"grant and existing completion made lease");
    complete=0;
    tick; if(!valid || tag!=head) $fatal(1,"new generation not granted");
    // A completion becoming visible immediately after grant drains next edge.
    complete=1; tick; if(valid) $fatal(1,"grant/late completion deadlock");
    present=0; tick;
    // A real retirement certificate can install directly from live or empty
    // old permission. The current head changes only after that sampled edge.
    for(n=0;n<2;n=n+1)begin
      head=9'h11f;kind=`R64_K_STORE;present=1;complete=0;allow=1;tick;
      if(!valid||tag!=head)$fatal(1,"successor fixture lacks old lease");
      complete=1;
      if(n!=0)begin tick;if(valid)$fatal(1,"Trace hold did not empty old lease");end
      successor=1;next_tag=9'h120;#1;
      if(valid && tag!=head)$fatal(1,"successor combinationally replaced lease");
      tick;successor=0;head=next_tag;complete=0;
      if(valid!==(SUCCESSOR!=0)||(valid&&tag!=head))$fatal(1,"successor install valid/empty");
      if(!valid)tick;
      complete=1;tick;present=0;tick;
    end
    // A hint alone cannot bypass each of the independent grant guards.
    for(n=0;n<4;n=n+1)begin
      head=9'h121;present=1;complete=1;successor=1;next_tag=9'h122;
      allow=(n!=0);recover=(n==1);flush=(n==2);
      if(n==3)complete=0;
      tick;
      if(valid && tag==next_tag)$fatal(1,"successor bypassed grant qualification");
      successor=0;allow=1;recover=0;flush=0;complete=1;tick;present=0;tick;
    end
    $display("[PASS] tb_r64_memory_effect_lease successor=%0d valid_empty_recovery_flush_allow_terminal=1",SUCCESSOR); $finish;
  end
endmodule
