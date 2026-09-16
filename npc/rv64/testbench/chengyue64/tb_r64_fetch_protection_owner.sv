
`timescale 1ns/1ps
module tb_r64_fetch_protection_owner;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,inv=0,v=0,rr=1,cr=1,bv=0,blast=0;
 reg [63:0] addr=64'h80000000,bd=0;
 reg tfault=0;reg [4:0] cause=12;reg [1:0] priv=3,br=0;
 reg [15:0] active=0;reg [895:0] lower=0,upper=0;reg [63:0] perm=0;
 wire [7:0] mask;wire nc;wire [129:0] facts;wire nc2;
 R64FetchProtection protect(addr,priv,active,lower,upper,perm,mask,nc);
 R64FetchProtectionPrepare prepare(addr,priv,active,lower,upper,perm,facts,nc2);
 wire ready0,ready1,rv0,rv1,rf0,rf1,cv0,cv1,bready0,bready1;
 wire [127:0] rd0,rd1;wire [4:0] rc0,rc1;wire [7:0] rm0,rm1,cl0,cl1;
 wire [63:0] ca0,ca1;wire [2:0] cs0,cs1;
 R64ICacheReference #(.SET_W(6)) refcache(
  .clk_i(clk),.rst_i(rst),.invalidate_i(inv),.req_valid_i(v),.req_ready_o(ready0),
  .req_paddr_i(addr),.req_uncached_i(nc),.req_fault_i(tfault),.req_cause_i(cause),.req_access_mask_i(mask),
  .rsp_valid_o(rv0),.rsp_ready_i(rr),.rsp_data_o(rd0),.rsp_fault_o(rf0),.rsp_cause_o(rc0),.rsp_access_mask_o(rm0),
  .cmd_valid_o(cv0),.cmd_ready_i(cr),.cmd_addr_o(ca0),.cmd_len_o(cl0),.cmd_size_o(cs0),
  .beat_valid_i(bv),.beat_ready_o(bready0),.beat_data_i(bd),.beat_resp_i(br),.beat_last_i(blast));
 R64ICache #(.SET_W(6),.PREPARED_PROTECTION(1)) dut(
  .clk_i(clk),.rst_i(rst),.invalidate_i(inv),.req_valid_i(v),.req_ready_o(ready1),
  .req_paddr_i(addr),.req_uncached_i(nc2),.req_fault_i(tfault),.req_cause_i(cause),.req_access_mask_i(8'b0),
  .req_protection_facts_i(facts),
  .rsp_valid_o(rv1),.rsp_ready_i(rr),.rsp_data_o(rd1),.rsp_fault_o(rf1),.rsp_cause_o(rc1),.rsp_access_mask_o(rm1),
  .cmd_valid_o(cv1),.cmd_ready_i(cr),.cmd_addr_o(ca1),.cmd_len_o(cl1),.cmd_size_o(cs1),
  .beat_valid_i(bv),.beat_ready_o(bready1),.beat_data_i(bd),.beat_resp_i(br),.beat_last_i(blast));
 integer cyc=0,accepted=0,returned=0,hot=0,held=0,overflow=0,partial=0,fullfault=0,translationfault=0,invalidations=0,errors=0;
 integer accept_cycle[0:8191];integer cold_latency=-1;
 integer sent=0,total=0;reg mem_busy=0;reg [63:0] mem_addr=0;reg mem_bad=0;
 reg [31:0] rng=32'h923148ac;
 function [31:0] step(input [31:0] x);step={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
 reg input_held=0;reg [71:0] input_payload_q;
 reg previous_held=0;reg [141:0] held_payload;
 always @(posedge clk)if(!rst)begin
  if({ready0,rv0,cv0,bready0}!=={ready1,rv1,cv1,bready1})$fatal(1,"cycle handshake %d",cyc);
  if(rv0&&{rd0,rf0,rc0,rm0}!=={rd1,rf1,rc1,rm1})$fatal(1,"response owner %d",cyc);
  if(cv0&&{ca0,cl0,cs0}!=={ca1,cl1,cs1})$fatal(1,"command owner %d",cyc);
  if(previous_held&&(!rv1||held_payload!=={rd1,rf1,rc1,rm1}))$fatal(1,"held response");
  previous_held=rv1&&!rr;held_payload={rd1,rf1,rc1,rm1};
  if(input_held&&(!v||input_payload_q!=={addr,tfault,cause,priv}))$fatal(1,"producer changed held translation");
  input_payload_q={addr,tfault,cause,priv};input_held=v&&!ready0;
  if(v&&ready0)begin
   accept_cycle[accepted]=cyc;accepted=accepted+1;
   if(mask!=0&&mask!=255)partial=partial+1;
   if(mask==255)fullfault=fullfault+1;
   if(tfault)translationfault=translationfault+1;
  end
  if(rv0&&rr)begin
   if(returned==0)cold_latency=cyc-accept_cycle[returned];
   if(cyc>=80&&cyc<280&&cyc-accept_cycle[returned]!=2)$fatal(1,"resident hit latency");
   returned=returned+1;
  end
  if(cyc>=80&&cyc<280)begin
   if(!(v&&ready0&&rv0&&rr))$fatal(1,"hot II1 bubble %d",cyc);
   hot=hot+1;
  end
  if(rv1&&!rr)held=held+1;
  if(dut.overflow_valid_q)overflow=overflow+1;
  if(inv)invalidations=invalidations+1;
  if(cv0&&cr)begin
   if(mem_busy)$fatal(1,"two refill owners");
   mem_busy=1;mem_addr=ca0;total=cl0+1;sent=0;mem_bad=cyc>300&&rng[7:3]==0;
  end
  if(bv&&bready0)begin
   sent=sent+1;if(br!=0)errors=errors+1;
   if(sent==total)mem_busy=0;
  end
 end
 integer i;
 initial begin
  repeat(3)@(negedge clk);rst=0;
  for(cyc=0;cyc<8000;cyc=cyc+1)begin
   rng=step(rng);
   // Request payload may change every cycle; both machines own it at their
   // identical real acceptance edge. PMP updates continue during stalls.
   if(cyc<300)begin v=1;addr=64'h80000000;active=0;priv=3;tfault=0;rr=1;cr=1;inv=0;end
   else begin
    if(!input_held)v=cyc<7600&&rng[0];rr=rng[2:1]!=0;cr=rng[4:3]!=0;inv=rng[12:5]==0;
    if(!input_held)begin addr=64'h80000000+{48'b0,rng[11:4],4'b0};priv=rng[14:13];tfault=rng[19:15]==0;
    cause=rng[20]?5'd12:5'd1;end
    for(i=0;i<16;i=i+1)begin
     rng=step(rng);active[i]=rng[0];
     lower[i*56+:56]=56'h80000000+{40'b0,rng[13:2],2'b0};
     upper[i*56+:56]=lower[i*56+:56]+{50'b0,rng[7:2]};
     perm[i*4+:4]=rng[11:8];
    end
    // Exact low-word overlaps, including two denied middle halfwords.
    if(cyc%7==0)begin active=1;if(!input_held)priv=3;lower[55:0]=addr[55:0]+4;upper[55:0]=addr[55:0]+7;perm[3:0]=8;end
   end
   bv=mem_busy&&(cyc<300||rng[1]);blast=sent==total-1;
   bd=mem_addr+sent*8;br=mem_bad&&sent==2?2'b10:2'b00;
   @(negedge clk);
  end
  v=0;rr=1;cr=1;inv=0;
  for(cyc=8000;cyc<8200;cyc=cyc+1)begin
   bv=mem_busy;blast=sent==total-1;bd=mem_addr+sent*8;br=0;
   @(negedge clk);
  end
  if(accepted!=returned||hot!=200||held==0||overflow==0||partial==0||fullfault==0||
    translationfault==0||invalidations==0||errors==0)
   $fatal(1,"coverage a%0d r%0d hot%0d held%0d overflow%0d partial%0d all%0d tf%0d inv%0d err%0d",
    accepted,returned,hot,held,overflow,partial,fullfault,translationfault,invalidations,errors);
  $display("[PASS] tb_r64_fetch_protection_owner a%0d r%0d hot%0d held%0d overflow%0d partial%0d all%0d tf%0d inv%0d err%0d hit_latency2 cold_latency%0d",
    accepted,returned,hot,held,overflow,partial,fullfault,translationfault,invalidations,errors,cold_latency);$finish;
 end
endmodule
