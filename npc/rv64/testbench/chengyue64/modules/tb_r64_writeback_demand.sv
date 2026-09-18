`timescale 1ns/1ps
module tb_r64_writeback_demand;
  localparam S=7,T=9,R=32;
  reg clk=0;always #5 clk=~clk;
  reg rst=1,flush=0;
  reg [31:0] km=0;
  reg [S-1:0] sv=0;
  wire [S-1:0] sr;
  reg [S*T-1:0] st=0;
  reg [S*R-1:0] sd=0;
  wire [1:0] wv;
  wire [2*T-1:0] wt;
  wire [2*R-1:0] wd;
  integer i,j,n,cycles,total,seen[0:S-1],waited[0:S-1],sent[0:S-1],expect_count;
  reg [1:0] expect_valid;
  reg [2*T-1:0] expect_tag;
  reg [2*R-1:0] expect_data;
  R64Writeback #(.DEFER_REQUEST(0),.SOURCES(S),.RESULT_W(R)) wb(
    .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
    .source_valid_i(sv),.source_ready_o(sr),.source_tag_i(st),.source_result_i(sd),
    .wb_valid_o(wv),.wb_tag_o(wt),.wb_result_o(wd)
  );
  task tick;begin @(posedge clk);#1;end endtask
  task check;input condition;input [511:0] message;
    begin if(condition!==1'b1)$fatal(1,"%0s",message);end
  endtask
  initial begin
    for(i=0;i<S;i=i+1)begin st[i*T+:T]=T'(i);sd[i*R+:R]=32'(100+i);seen[i]=0;waited[i]=0;sent[i]=0;end
    tick();rst=0;sv=7'b1000000;#1;
    check(!sr[6],"new source already had an unrelated initial grant");
    tick();check(sr[6]&&!wv,"direct demand did not obtain the next-cycle grant");
    tick();check((wv[0]&&wt[0+:T]==6)||(wv[1]&&wt[T+:T]==6),
        "new source took an extra demand-sampling cycle");
    rst=1;sv=0;tick();rst=0;sv=2;#1;
    tick();check(wv==2&&wt[T+:T]==1&&wd[R+:R]==101,
        "lane1-only completion must keep its physical lane");
    rst=1;sv=0;tick();rst=0;sv=3;#1;
    // No contention: ALU0+ALU1 both enter and leave every cycle.
    for(cycles=0;cycles<60;cycles=cycles+1)begin
      #1;check(sr[1:0]==3,"uncontended dual ALU WB backpressure");tick();
      check(wv==3,"dual ALU WB bubble");
      check((wt=={T'(1),T'(0)})&&(wd=={32'd101,32'd100}),"ALU WB payload");
    end
    // Full contention: every persistent source served within four cycles.
    sv={S{1'b1}};tick(); // Fill registered demand before the steady-state fairness window.
    total=0;
    for(cycles=0;cycles<70;cycles=cycles+1)begin
      #1;n=0;
      for(i=0;i<S;i=i+1)begin
        if(sr[i])begin n=n+1;seen[i]=seen[i]+1;waited[i]=0;end
        else waited[i]=waited[i]+1;
        check(waited[i]<=4,"long FU starved behind ALUs");
      end
      check(n==2,"contended WB capacity lost");tick();
      check(wv==3,"contended WB output bubble");
      for(j=0;j<2;j=j+1)check(wd[j*R+:R]==100+wt[j*T+:T],"WB tag/result torn");
      total=total+2;
    end
    for(i=0;i<S;i=i+1)check(seen[i]==20,"round-robin service imbalance");
    // Killed registered and incoming results disappear even without a grant.
    // Sources cancel locally; READY no longer carries the asynchronous kill map.
    km=32'h7f;#1;
    tick();km=0;sv=0;#1;check(wv==0,"killed source reappeared");
    sv=3;tick();flush=1;tick();check(wv==0,"flush did not clear registered result");flush=0;sv=0;
    // Random source gaps exercise rotating selection without loss/duplication.
    for(cycles=0;cycles<200;cycles=cycles+1)begin
      for(i=0;i<S;i=i+1)begin
        if(!sv[i])sv[i]=(($random&3)!=0);
        st[i*T+:T]=T'(i);sd[i*R+:R]=32'(sent[i]*S+i);
      end
      #1;expect_valid=0;expect_count=0;
      // Selected order follows rotating index, so compare source identity/data.
      for(i=0;i<S;i=i+1)if(sv[i]&&sr[i])begin
        expect_valid[expect_count]=1;expect_count=expect_count+1;
        seen[i]=sent[i];
      end
      tick();check(({1'b0,wv[0]}+{1'b0,wv[1]})==expect_count,
          "random completion count");
      for(j=0;j<2;j=j+1)if(wv[j])begin
        i=wt[j*T+:T];
        check(wd[j*R+:R]==seen[i]*S+i,"random completion payload");
      end
      // Advance exactly the sources actually observed at registered outputs.
      for(j=0;j<2;j=j+1)if(wv[j])begin i=wt[j*T+:T];sent[i]=sent[i]+1;sv[i]=0;end
    end
    $display("[R64-WRITEBACK] two ALUs=2/cycle seven-source contention 140 results/70 cycles every_source=20 PASS");
    $display("[PASS] tb_r64_writeback_demand");$finish;
  end
endmodule
