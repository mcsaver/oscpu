`timescale 1ns/1ps
module tb_r64_service_qcredit;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;reg [1:0] cv=0,kr=0;
 reg [9:0] ct=0;reg [127:0] ca=0,cd=0;reg [3:0] co=0;
 reg [1:0] cc=3,fs=0;reg [5:0] cz=0;reg [15:0] cs=0;reg [9:0] cm=0;
 wire [1:0] cr,kv,kfs,kcache,krr,crv,cre;wire [9:0] crt;
 wire [15:0] kt;wire [127:0] ka,kd,kx,crd;wire [3:0] ko;
 wire [5:0] kz;wire [15:0] ks;wire [9:0] km;wire idle;
 wire [3:0] ar,arv,are,arc;wire[255:0] ard;
 R64MemoryService dut(
 .clk_i(clk),.rst_i(rst),.cpu_fast_store_i(fs),.cache_fast_store_o(kfs),
 .cpu_valid_i(cv),.cpu_ready_o(cr),.cpu_token_i(ct),.cpu_addr_i(ca),.cpu_data_i(cd),
 .cpu_op_i(co),.cpu_cache_i(cc),.cpu_size_i(cz),.cpu_strb_i(cs),.cpu_amo_i(cm),
 .cpu_rsp_valid_o(crv),.cpu_rsp_ready_i(2'b11),.cpu_rsp_token_o(crt),.cpu_rsp_data_o(crd),.cpu_rsp_error_o(cre),
 .aux_valid_i(4'b0),.aux_ready_o(ar),.aux_addr_i(256'b0),.aux_data_i(256'b0),.aux_expected_i(256'b0),
 .aux_op_i(8'b0),.aux_cache_i(4'b0),.aux_size_i(12'b0),.aux_strb_i(32'b0),
 .aux_rsp_valid_o(arv),.aux_rsp_ready_i(4'b1111),.aux_rsp_data_o(ard),.aux_rsp_error_o(are),.aux_rsp_compare_o(arc),
 .cache_valid_o(kv),.cache_ready_i(kr),.cache_token_o(kt),.cache_addr_o(ka),.cache_data_o(kd),.cache_expected_o(kx),
 .cache_op_o(ko),.cache_cache_o(kcache),.cache_size_o(kz),.cache_strb_o(ks),.cache_amo_o(km),
 .cache_rsp_valid_i(2'b0),.cache_rsp_ready_o(krr),.cache_rsp_token_i(16'b0),.cache_rsp_data_i(128'b0),
 .cache_rsp_error_i(2'b0),.cache_rsp_compare_i(2'b0),.idle_o(idle));
 reg [219:0] expect_q[0:1][0:16383],held_q[0:1];
 integer wr[0:1],rd[0:1],n[0:1],serial[0:1];
 wire [219:0] observed[0:1],incoming[0:1];
 genvar g;generate for(g=0;g<2;g=g+1)begin:g_pack
  assign observed[g]={kt[g*8+:8],ka[g*64+:64],kd[g*64+:64],kx[g*64+:64],
   ko[g*2+:2],kcache[g],kz[g*3+:3],ks[g*8+:8],km[g*5+:5],kfs[g]};
  assign incoming[g]={3'b0,ct[g*5+:5],ca[g*64+:64],cd[g*64+:64],64'b0,
   co[g*2+:2],cc[g],cz[g*3+:3],cs[g*8+:8],cm[g*5+:5],fs[g]};
 end endgenerate
 reg [1:0] accepted,held=0;reg baseline=0;
 integer cycle=0,l,hot=0,held_checks=0,lane1_only=0,full_checks=0,first_accept=-1,first_offer=-1;
 reg [31:0] rng=32'h54129837;
 task random_next;begin rng=(rng<<13)^rng;rng=(rng>>17)^rng;rng=(rng<<5)^rng;end endtask
 task new_payload(input integer lane);begin
  serial[lane]=serial[lane]+1;random_next;
  ct[lane*5+:5]=serial[lane][4:0];
  ca[lane*64+:64]=64'h80000000+64'(serial[lane]*16+lane*8);
  cd[lane*64+:64]={rng,~rng};co[lane*2+:2]=0;
  cc[lane]=rng[0];cz[lane*3+:3]=rng[3:1];cs[lane*8+:8]=rng[15:8];
  cm[lane*5+:5]=rng[20:16];fs[lane]=rng[21];
 end endtask
 always @(posedge clk)begin
  if(rst)begin
   accepted=0;held=0;
   for(l=0;l<2;l=l+1)begin wr[l]=0;rd[l]=0;n[l]=0;end
  end else begin
   accepted=cv&cr;
   if(first_accept<0&&(|accepted))first_accept=cycle;
   if(first_offer<0&&(|kv))first_offer=cycle;
   if(accepted==2)lane1_only=lane1_only+1;
   for(l=0;l<2;l=l+1)begin
    if(held[l])begin
     if(!kv[l]||observed[l]!==held_q[l])$fatal(1,"Service held request payload/owner changed lane=%0d",l);
     held_checks=held_checks+1;
    end
    held[l]=kv[l]&&!kr[l];held_q[l]=observed[l];
    if(kv[l]&&kr[l])begin
     if(n[l]==0||observed[l]!==expect_q[l][rd[l]])
      $fatal(1,"Service request lost/reordered/corrupted lane=%0d cycle=%0d",l,cycle);
     rd[l]=rd[l]+1;n[l]=n[l]-1;
    end
    if(accepted[l])begin expect_q[l][wr[l]]=incoming[l];wr[l]=wr[l]+1;n[l]=n[l]+1;end
    if(n[l]>(baseline?1:2))$fatal(1,"Service request capacity overbooked");
   end
   if(cycle>=30&&cycle<230)begin
    if((cv&cr)!=3||kv!=3)$fatal(1,"Service hot dual II lost");
    hot=hot+1;
   end
  end
 end
 always @(negedge clk)if(!rst)begin
  if(idle!==((n[0]==0)&&(n[1]==0)))$fatal(1,"Service idle omitted an accepted request slot");
 end
 reg [1:0] saved_credit;
 initial begin
  baseline=$test$plusargs("baseline");
  serial[0]=0;serial[1]=0;
  repeat(3)@(negedge clk);rst=0;
  for(cycle=0;cycle<6000;cycle=cycle+1)begin
   for(l=0;l<2;l=l+1)if(!cv[l]||accepted[l])begin
    random_next;cv[l]=cycle<230?1'b1:rng[0]|rng[1];
    if(cv[l])new_payload(l);
   end
   if(cycle<6)kr=0;
   else if(cycle<17)kr=2;
   else if(cycle<230)kr=3;
   else begin random_next;kr=(cycle%61)<16?2'b0:rng[1:0];end
   #1;
   if(cycle==5)begin
    if(n[0]!=(baseline?1:2)||n[1]!=(baseline?1:2)||cr!=0)
     $fatal(1,"Service actual full capacity mismatch");
    saved_credit=cr;kr=3;#1;
    if(!baseline&&cr!==saved_credit)$fatal(1,"Service borrowed predicted pop for full Q credit");
    kr=0;full_checks=full_checks+1;
   end
   @(negedge clk);
  end
  for(cycle=6000;cycle<6100;cycle=cycle+1)begin
   for(l=0;l<2;l=l+1)if(!cv[l]||accepted[l])cv[l]=0;
   kr=3;@(negedge clk);
   if(cv==0&&idle)begin
    if(n[0]!=0||n[1]!=0||hot!=200||held_checks<100||lane1_only<5||first_offer-first_accept!=1)
     $fatal(1,"Service credit coverage/drain/first-cycle failed");
    $display("[PASS] tb_r64_service_qcredit baseline=%0d hot200=%0d held=%0d lane1_only=%0d full=%0d accepted=%0d/%0d first_gap=%0d",
      baseline,hot,held_checks,lane1_only,full_checks,wr[0],wr[1],first_offer-first_accept);
    $finish;
   end
  end
  $fatal(1,"Service owners failed to drain");
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
