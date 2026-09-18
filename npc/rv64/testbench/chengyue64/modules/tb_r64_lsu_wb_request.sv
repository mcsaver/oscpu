`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_lsu_wb_request;
 parameter ENABLE_HINTS=1;
 localparam S=9,T=9,R=`R64_RESULT_W;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] kill=0;
 reg [1:0] fire=0;wire [1:0] credit,cv,ch,cr;reg [2*T-1:0] it=0;reg [2*R-1:0] idata=0;
 wire [2*T-1:0] ct;wire [2*R-1:0] cd;wire [31:0] reuse;wire idle;
 reg contend=0;reg [S-1:0] false_hint=0;
 wire [S-1:0] sv,sr;wire [S*T-1:0] st;wire [S*R-1:0] sd;
 wire [1:0] wv;wire [2*T-1:0] wt;wire [2*R-1:0] wd;
 R64LsuCompletion cq(.clk_i(clk),.rst_i(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(it),.in_result_i(idata),
  .out_valid_o(cv),.out_request_o(ch),.out_ready_i(cr),.out_tag_o(ct),.out_result_o(cd),
  .reuse_block_o(reuse),.idle_o(idle));
 assign cr=sr[6:5];
 genvar g;
 generate for(g=0;g<S;g=g+1)begin:gen_source
  if(g==5||g==6)begin:lsu
   assign sv[g]=cv[g-5];assign st[g*T+:T]=ct[(g-5)*T+:T];assign sd[g*R+:R]=cd[(g-5)*R+:R];
  end else begin:filler
   assign sv[g]=contend;assign st[g*T+:T]=T'(400+g);assign sd[g*R+:R]=R'(g+100);
  end
 end endgenerate
 R64Writeback #(.SOURCES(S),.SOURCE_W(4),.RESULT_W(R),.DEFER_REQUEST(0),.REQUEST_HINTS(ENABLE_HINTS)) wb(
  .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .source_valid_i(sv),.source_request_i({2'b0,ch,5'b0}|false_hint),.source_ready_o(sr),
  .source_tag_i(st),.source_result_i(sd),.wb_valid_o(wv),.wb_tag_o(wt),.wb_result_o(wd),
  .owner_query_tag_o(),.owner_query_cert_i(72'b0),.wb_owner_cert_o());
 integer count[0:511];integer i,j,n,cycles=0,expected_count,observed_count,delivered=0;
 reg [S-1:0] accepted;
 reg [S*T-1:0] expected_tag;
 reg [S*R-1:0] expected_data;
 always @(posedge clk)begin
  cycles=cycles+1;accepted=0;expected_count=0;expected_tag=st;expected_data=sd;
  if(!rst&&!flush)for(i=0;i<S;i=i+1)
   if(sv[i]&&sr[i]&&!kill[st[i*T+:5]])begin accepted[i]=1;expected_count=expected_count+1;end
  #1;observed_count=0;
  for(j=0;j<2;j=j+1)if(wv[j])begin
   observed_count=observed_count+1;n=-1;
   for(i=0;i<S;i=i+1)if(accepted[i]&&wt[j*T+:T]==expected_tag[i*T+:T])begin
    if(wd[j*R+:R]!==expected_data[i*R+:R])$fatal(1,"WB forecast tore owner/data");
    accepted[i]=0;n=i;
   end
   if(n<0)$fatal(1,"request hint created an unaccepted completion");
   if(wd[j*R+48+:16]==16'hcafe)begin
    count[wt[j*T+:T]]=count[wt[j*T+:T]]+1;delivered=delivered+1;
    if(count[wt[j*T+:T]]!=1)$fatal(1,"duplicate LSU completion");
   end
  end
  if(observed_count!=expected_count||accepted!=0)$fatal(1,"WB accepted result lost");
 end
 task tick;begin @(posedge clk);#2;end endtask
 task offer;input [8:0] tag;begin
  @(negedge clk);while(!credit[0])@(negedge clk);
  fire=1;it={9'b0,tag};idata=0;idata[63:0]=64'hcafe000000000000|{55'b0,tag};
 end endtask
 integer k,budget;
 initial begin
  for(k=0;k<512;k=k+1)count[k]=0;
  repeat(3)@(negedge clk);rst=0;
  offer(1);tick();
  if(cv==0||(cv&cr)!=cv)$fatal(1,"cold LSU result did not get a port on its first valid cycle");
  @(negedge clk);fire=0;tick();
  if(count[1]!=1)$fatal(1,"cold LSU result retained the extra scheduling cycle");
  @(negedge clk);while(credit!=3)@(negedge clk);
  fire=3;it={9'd5,9'd4};idata=0;
  idata[63:0]=64'hcafe000000000004;idata[R+:64]=64'hcafe000000000005;
  tick();if(cv!=3||cr!=3)$fatal(1,"paired LSU forecast lost one physical port");
  @(negedge clk);fire=0;tick();
  if(count[4]!=1||count[5]!=1)$fatal(1,"paired cold completion lost");
  // Announced result canceled before the reserved port can capture it.
  offer(2);tick();@(negedge clk);fire=0;kill=4;tick();
  @(negedge clk);kill=0;repeat(3)tick();
  if(count[2]!=0)$fatal(1,"killed forecast escaped");
  // A deliberately wrong forecast must remain a harmless port reservation.
  @(negedge clk);false_hint=9'b001000000;repeat(3)tick();
  @(negedge clk);false_hint=0;
  offer(3);tick();@(negedge clk);fire=0;flush=1;tick();
  @(negedge clk);flush=0;repeat(3)tick();
  if(count[3]!=0)$fatal(1,"flush forecast escaped");
  // Both physical CQ lanes fill/skid while the other seven WB sources persist.
  @(negedge clk);contend=1;
  for(k=0;k<48;k=k+1)begin
   offer(9'(64+k));tick();@(negedge clk);fire=0;
  end
  budget=0;
  while(!idle&&budget<200)begin tick();budget=budget+1;end
  repeat(4)tick();
  for(k=0;k<48;k=k+1)if(count[64+k]!=1)$fatal(1,"contended result not delivered");
  if(!idle||delivered!=51)$fatal(1,"completion ownership did not drain");
  $display("[PASS] tb_r64_lsu_wb_request cold_capture=2_edges completed=%0d contention_sources=9 cancel=1 flush=1 false_hint=1",delivered);
  $finish;
 end
 initial begin #100000;$fatal(1,"LSU WB request timeout");end
endmodule
