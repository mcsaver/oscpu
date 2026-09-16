`timescale 1ns/1ps
module tb_r64_axi_write #(parameter B_BYPASS=0);
reg clk=0;always #5 clk=~clk;
reg rst=1;
reg[1:0] cv=0,dv=0,rr=0;
wire[1:0] cr,dr,rv;
reg[127:0] ca=0,di=0;
reg[15:0] cl=0,st=0;
reg[5:0] cs={2{3'd3}},cp=0;
wire[3:0] rp;
wire av,wv,wl,br;reg ar=0,wr=0,bv=0;
wire[3:0] ai;
wire[63:0] aa,wd;
wire[7:0] an,ws;
wire[2:0] az,ap;
wire[1:0] ab;
reg[3:0] bi=0;
reg[1:0] bp=0;
wire error;
R64AxiWrite #(.B_BYPASS(B_BYPASS)) dut(clk,rst,cv,cr,ca,cl,cs,cp,dv,dr,di,st,rv,rr,rp,
 av,ar,ai,aa,an,az,ap,ab,wv,wr,wd,ws,wl,bv,br,bi,bp,error);
integer launched[0:1],produced[0:1],length[0:1];
reg[63:0] address[0:1];
reg active[0:1],awseen[0:1],wseen[0:1],bsent[0:1];
integer order_id[0:2047],order_len[0:2047];
reg[63:0] order_addr[0:2047];
integer tail=0,awhead=0,whead=0,wbeat=0,total=0,beats=0,c,cycle,choice;
integer direct_count=0,buffered_count=0;
integer early_w=0,early_aw=0,wblocked=0,bblocked=0;
reg[31:0] random_q=32'h52034caa;
reg hold_aw=0,hold_w=0;
reg[78:0] held_aw;
reg[72:0] held_w;
reg[1:0] hold_rsp=0;
reg[1:0] held_rsp[0:1];
reg negative;
reg bus_taken_q=0;
function[31:0] rng(input[31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
function[63:0] data_for(input[63:0] addr,input integer beat);
data_for=addr^64'h1758_cea9_8430_376e^{56'b0,beat[7:0]};endfunction
function[7:0] strb_for(input[63:0] addr,input integer beat);
strb_for=addr[13:6]^beat[7:0];endfunction
function[1:0] resp_for(input[63:0] addr);
resp_for=addr[7:6]==3?2'b10:2'b0;endfunction

always @(posedge clk) if(!rst) begin
 bus_taken_q=bv&&br;
 if(dut.bdirect_pop_w)direct_count=direct_count+1;
 if(dut.bpush_w)buffered_count=buffered_count+1;
 if(hold_aw&&(!av||{ai,aa,an,az}!==held_aw)) $fatal(1,"AW changed while blocked");
 if(hold_w&&(!wv||{wd,ws,wl}!==held_w)) $fatal(1,"W changed while blocked");
 hold_aw=av&&!ar;held_aw={ai,aa,an,az};
 hold_w=wv&&!wr;held_w={wd,ws,wl};
 for(c=0;c<2;c=c+1) begin
  if(hold_rsp[c]&&(!rv[c]||rp[c*2+:2]!==held_rsp[c])) $fatal(1,"client B unstable");
  hold_rsp[c]=rv[c]&&!rr[c];held_rsp[c]=rp[c*2+:2];
  if(rv[c]&&rr[c]) begin
   if(!active[c]||!awseen[c]||!wseen[c]||rp[c*2+:2]!==resp_for(address[c]))
    $fatal(1,"response owner/error client %0d",c);
   active[c]=0;total=total+1;
  end
  if(cv[c]&&cr[c]) begin
   if(active[c]) $fatal(1,"client ID reused before terminal");
   active[c]=1;address[c]=ca[c*64+:64];length[c]=cl[c*8+:8]+1;
   produced[c]=0;awseen[c]=0;wseen[c]=0;bsent[c]=0;
   order_id[tail]=c;order_len[tail]=length[c];order_addr[tail]=address[c];tail=tail+1;
   launched[c]=launched[c]+1;
  end
  if(dv[c]&&dr[c]) produced[c]=produced[c]+1;
 end
 if(av&&ar) begin
  if(awhead>=tail||ai!=order_id[awhead]||aa!==order_addr[awhead]||
     an!=order_len[awhead]-1||az!=3||ap!=0||ab!=1)
   $fatal(1,"AW descriptor or command order mismatch");
  awseen[ai]=1;if(!wseen[ai]) early_aw=early_aw+1;
  awhead=awhead+1;
 end
 if(wv&&wr) begin
  if(whead>=tail||wd!==data_for(order_addr[whead],wbeat)||
     ws!==strb_for(order_addr[whead],wbeat)||wl!=(wbeat==order_len[whead]-1))
   $fatal(1,"W order/data/last mismatch head=%0d beat=%0d",whead,wbeat);
  beats=beats+1;wbeat=wbeat+1;
  if(wl) begin
   wseen[order_id[whead]]=1;
   if(!awseen[order_id[whead]]) early_w=early_w+1;
   whead=whead+1;wbeat=0;
  end
 end
 if(bv&&br&&!negative) bsent[bi]=1;
 if(wv&&!wr) wblocked=wblocked+1;
 if(bv&&!br) bblocked=bblocked+1;
end

initial begin
negative=$test$plusargs("early-b");
for(c=0;c<2;c=c+1) begin
launched[c]=0;produced[c]=0;length[c]=0;active[c]=0;
awseen[c]=0;wseen[c]=0;bsent[c]=0;address[c]=0;
end
repeat(3) @(negedge clk);rst=0;
if(negative) begin
bv=1;bi=0;bp=0;
repeat(5) @(negedge clk);
$fatal(1,"premature B was not rejected");
end
for(cycle=0;cycle<20000&&total<512;cycle=cycle+1) begin
 random_q=rng(random_q);
 ar=cycle>=35&&(random_q[0]||random_q[1]);
 wr=random_q[2]||random_q[3];rr=random_q[5:4];
 for(c=0;c<2;c=c+1) begin
  cv[c]=launched[c]<256;ca[c*64+:64]=64'h80000000+(c<<20)+(launched[c]<<6);
  cl[c*8+:8]=launched[c]%8;
  dv[c]=active[c]&&produced[c]<length[c]&&random_q[8+c];
  di[c*64+:64]=data_for(address[c],produced[c]);
  st[c*8+:8]=strb_for(address[c],produced[c]);
 end
 if(!bv||bus_taken_q) begin
  bv=0;choice=-1;
  for(c=0;c<2;c=c+1)
   if(active[c]&&awseen[c]&&wseen[c]&&!bsent[c]&&(choice<0||random_q[12])) choice=c;
  if(choice>=0&&random_q[13]) begin bv=1;bi=choice;bp=resp_for(address[choice]);end
 end
 @(negedge clk);
end
if(total!=512||beats!=2304||early_w==0||early_aw<100||wblocked<500||error)
 $fatal(1,"coverage total=%0d beats=%0d earlyW=%0d earlyAW=%0d stalls=%0d",total,beats,early_w,early_aw,wblocked);
if(B_BYPASS&&(direct_count==0||buffered_count==0))$fatal(1,"B bypass coverage missing");
$display("B_PATH bypass=%0d direct=%0d buffered=%0d",B_BYPASS,direct_count,buffered_count);
$display("[PASS] tb_r64_axi_write");
$display("COVERAGE transactions=%0d beats=%0d W_before_AW=%0d AW_before_W=%0d W_stalls=%0d B_stalls=%0d",
 total,beats,early_w,early_aw,wblocked,bblocked);
$finish;
end
endmodule
