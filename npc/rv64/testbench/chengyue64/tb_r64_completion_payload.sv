`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_completion_payload;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] kill=0;
 reg [1:0] fire=0,consume=0;reg [17:0] tags=0;reg [279:0] packets=0;
 wire [1:0] ready[0:1],valid[0:1];wire [17:0] otag[0:1];wire [279:0] data[0:1];wire [31:0] reuse[0:1];wire [1:0] idle;
 R64LsuCompletionReference a(.clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(ready[0]),.in_tag_i(tags),.in_result_i(packets),
 .out_valid_o(valid[0]),.out_ready_i(consume),.out_tag_o(otag[0]),.out_result_o(data[0]),.reuse_block_o(reuse[0]),.idle_o(idle[0]));
 R64LsuCompletion b(.clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(ready[1]),.in_tag_i(tags),.in_result_i(packets),
 .out_valid_o(valid[1]),.out_ready_i(consume),.out_tag_o(otag[1]),.out_result_o(data[1]),.reuse_block_o(reuse[1]),.idle_o(idle[1]));
 reg [31:0] rng=32'hc014a219;reg [3:0] gen[0:31];
 integer cycle=0,l,s,j,accepted=0,returned=0,cancels=0,full=0,dual=0,held=0,reused=0,frontkill=0,backkill=0,freechanges=0;
 reg [31:0] unavailable;reg [17:0] oldtag;reg [279:0] olddata;reg [1:0] oldheld=0;
 function [31:0] step;input [31:0] x;reg [31:0] y;begin y=x^(x<<13);y=y^(y>>17);step=y^(y<<5);end endfunction
 always @(posedge clk)begin
   if(!rst)begin
     if({ready[0],valid[0],reuse[0],idle[0]}!=={ready[1],valid[1],reuse[1],idle[1]})$fatal(1,"control mismatch c=%0d",cycle);
     for(integer q=0;q<2;q=q+1)begin
       if(valid[0][q]&&{otag[0][q*9+:9],data[0][q*140+:140]}!=={otag[1][q*9+:9],data[1][q*140+:140]})$fatal(1,"valid payload mismatch c=%0d lane%0d",cycle,q);
       if(oldheld[q]&&!flush&&!kill[oldtag[q*9+:5]]&&(!valid[1][q]||{otag[1][q*9+:9],data[1][q*140+:140]}!=={oldtag[q*9+:9],olddata[q*140+:140]}))$fatal(1,"held payload changed");
       if(valid[0][q]&&consume[q])returned=returned+1;
       if(fire[q])accepted=accepted+1;
       if(oldheld[q])held=held+1;
       if(a.front_q[q]&&kill[a.front_tag_q[q][4:0]])frontkill=frontkill+1;
       if(a.back_q[q]&&kill[a.back_tag_q[q][4:0]])backkill=backkill+1;
       if(!a.front_q[q]&&a.front_result_q[q]!==b.front_result_q[q])freechanges=freechanges+1;
     end
     if(ready[0]==0)full=full+1;
     if(fire==3)dual=dual+1;
     if(kill||flush)cancels=cancels+1;
     oldheld=valid[1]&~consume;oldtag=otag[1];olddata=data[1];
   end else oldheld=0;
 end
 initial begin
   for(j=0;j<32;j=j+1)gen[j]=0;
   repeat(3)@(negedge clk);rst=0;
   for(cycle=0;cycle<20000;cycle=cycle+1)begin
     rng=step(rng);flush=cycle%271==270;kill=(rng[6:0]==7'd3)?(32'b1<<rng[11:7]):0;
     // Deliberately cancel populated skid slots, not just random unused tags.
     if(cycle%257==100)begin
       if(a.back_q[0])kill=kill|(32'b1<<a.back_tag_q[0][4:0]);
       if(a.back_q[1])kill=kill|(32'b1<<a.back_tag_q[1][4:0]);
     end
     consume=(cycle%131<16)?0:rng[17:16];fire=0;
     rng=step(rng);tags=rng[17:0];for(j=0;j<9;j=j+1)begin rng=step(rng);if(j<8)packets[j*32+:32]=rng;else packets[256+:24]=rng[23:0];end
     #1;unavailable=reuse[0]|kill;
     if(!flush)for(l=0;l<2;l=l+1)begin
       if(ready[0][l]&&(l==0||fire[0])&&rng[27-l])begin
         s=-1;for(j=0;j<32;j=j+1)if(!unavailable[j]&&s<0)s=j;
         if(s>=0)begin fire[l]=1;tags[l*9+:9]={gen[s],s[4:0]};if(gen[s]!=0)reused=reused+1;gen[s]=gen[s]+1'b1;unavailable[s]=1;end
       end
     end
     @(negedge clk);
   end
   fire=0;kill=0;flush=0;consume=3;repeat(6)@(negedge clk);
   if(!(&idle)||accepted<5000||dual<1000||held<1000||full<100||frontkill<5||backkill<5||reused<1000||freechanges<100)$fatal(1,"vacuous coverage %0d %0d %0d %0d %0d %0d %0d %0d",accepted,dual,held,full,frontkill,backkill,reused,freechanges);
   $display("[PASS] tb_r64_completion_payload cycles=%0d accepted=%0d returns=%0d dual=%0d held=%0d full=%0d cancels=%0d frontkill=%0d backkill=%0d reused=%0d freechanges=%0d",cycle,accepted,returned,dual,held,full,cancels,frontkill,backkill,reused,freechanges);$finish;
 end
 initial begin #300000;$fatal(1,"timeout");end
endmodule
