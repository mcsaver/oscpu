`timescale 1ns/1ps
module tb_r64_axi_read;
reg clk=0;always #5 clk=~clk;
reg rst=1;
reg[3:0] cv=0,rr=0;
wire[3:0] cr,rv,rl;
reg[255:0] ca=0;
reg[31:0] cl=0;
reg[11:0] cs={4{3'd3}},cp=0;
wire[255:0] rd;
wire[7:0] rp;
wire av;reg ar=0;
wire[3:0] ai;
wire[63:0] aa;
wire[7:0] an;
wire[2:0] az,ap;
wire[1:0] ab;
reg bv=0;wire br;
reg[3:0] bi=0;
reg[63:0] bd=0;
reg[1:0] bp=0;
reg bl=0;
wire error;
R64AxiRead dut(clk,rst,cv,cr,ca,cl,cs,cp,rv,rr,rd,rp,rl,
  av,ar,ai,aa,an,az,ap,ab,bv,br,bi,bd,bp,bl,error);
integer launched[0:3],arrived[0:3],sent[0:3],seen[0:3],length[0:3];
reg [63:0] address[0:3];
integer total=0,beats=0,cycle,which,offset,c,choice,backpressure=0,out_of_order=0;
reg active[0:3];
reg[31:0] random_q=32'h91ee8ad3;
reg hold_ar=0;
reg[78:0] held_ar;
reg[3:0] hold_r=0;
reg[66:0] held_r[0:3];
reg negative;
reg bus_taken_q=0;
function[31:0] rng(input[31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
function[63:0] data_for(input[63:0] addr,input integer beat);
data_for=addr^64'hcadf_913e_c76e_8a50^{56'b0,beat[7:0]};endfunction
function[1:0] resp_for(input[63:0] addr,input integer beat);
resp_for=(addr[7:5]==3&&beat==0)?2'b10:2'b0;endfunction

always @(posedge clk) if(!rst) begin
 bus_taken_q=bv&&br;
  if(hold_ar&&(!av||{ai,aa,an,az}!==held_ar))
    $fatal(1,"AR changed under backpressure");
  hold_ar=av&&!ar;held_ar={ai,aa,an,az};
  for(c=0;c<4;c=c+1) begin
    if(hold_r[c] && (!rv[c] || {rd[c*64+:64],rp[c*2+:2],rl[c]}!==held_r[c]))
      $fatal(1,"client response changed while blocked");
    hold_r[c]=rv[c]&&!rr[c];
    held_r[c]={rd[c*64+:64],rp[c*2+:2],rl[c]};
    if(cv[c]&&cr[c]) launched[c]=launched[c]+1;
    if(rv[c]&&rr[c]) begin
      if(!active[c]||rd[c*64+:64]!==data_for(address[c],seen[c])||
         rp[c*2+:2]!==resp_for(address[c],seen[c])||rl[c]!=(seen[c]==length[c]-1))
        $fatal(1,"response route/order client=%0d beat=%0d data=%h",c,seen[c],rd[c*64+:64]);
      seen[c]=seen[c]+1;beats=beats+1;
      if(rl[c]) begin active[c]=0;total=total+1;end
    end
  end
  if(av&&ar) begin
    if(ai>=4||active[ai]||az!=3||ab!=1||ap!=0)
      $fatal(1,"AR owner/control");
    active[ai]=1;address[ai]=aa;length[ai]=an+1;
    seen[ai]=0;sent[ai]=0;arrived[ai]=arrived[ai]+1;
  end
  if(bv&&br&&!negative) begin sent[bi]=sent[bi]+1;out_of_order=out_of_order+(bi!=0);end
  if(bv&&!br) backpressure=backpressure+1;
end

initial begin
negative=$test$plusargs("bad-id");
for(c=0;c<4;c=c+1) begin
launched[c]=0;arrived[c]=0;sent[c]=0;seen[c]=0;length[c]=0;active[c]=0;address[c]=0;hold_r[c]=0;
end
repeat(3) @(negedge clk);rst=0;
if(negative) begin
bv=1;bi=4'hf;bd=0;bl=1;
repeat(5) @(negedge clk);
$fatal(1,"negative case was not rejected");
end
for(cycle=0;cycle<20000&&total<512;cycle=cycle+1) begin
 random_q=rng(random_q);
 ar=random_q[0]||random_q[1];rr=random_q[7:4];
 for(c=0;c<4;c=c+1) begin
 cv[c]=launched[c]<128;
 ca[c*64+:64]=64'h80000000+(c<<20)+(launched[c]<<6);
 cl[c*8+:8]=launched[c]%8;
 end
 // A slave may interleave beats of distinct IDs; retain R payload until ready.
 if(!bv||bus_taken_q) begin
  bv=0;choice=-1;
  for(offset=0;offset<4;offset=offset+1) begin
   which=(random_q[10:9]+offset)%4;
   if(choice<0&&active[which]&&sent[which]<length[which]) choice=which;
  end
  if(choice>=0&&random_q[12]) begin
   bv=1;bi=choice;bd=data_for(address[choice],sent[choice]);
   bp=resp_for(address[choice],sent[choice]);bl=sent[choice]==length[choice]-1;
  end
 end
 @(negedge clk);
end
if(total!=512||beats!=2304||backpressure<100||out_of_order<500||error)
 $fatal(1,"coverage total=%0d beats=%0d stalls=%0d",total,beats,backpressure);
$display("[PASS] tb_r64_axi_read");
$display("COVERAGE transactions=%0d beats=%0d bus_stalls=%0d interleaved_beats=%0d",total,beats,backpressure,out_of_order);
$finish;
end
endmodule
