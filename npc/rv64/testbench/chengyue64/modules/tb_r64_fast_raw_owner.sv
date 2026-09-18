`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_fast_raw_owner;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=0;
 reg [31:0] kill=0;reg [8:0] tag=0;
 reg [`R64_UOP_W-1:0] uop=0;reg [191:0] operand=0;
 wire credit,valid;wire [8:0] result_tag;wire [`R64_RESULT_W-1:0] result;
 R64FpExecute #(.Q_CREDIT_INGRESS(1),.RAW_FAST_DISPATCH(1),.RAW_FMA_DISPATCH(1)) dut(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i(operand),
 .fp_enabled_i(1'b1),.frm_i(3'b0),.out_valid_o(valid),.out_ready_i(ready),
 .out_tag_o(result_tag),.out_result_o(result));
 reg [511:0] pending=0;reg [63:0] expected[0:511];
 integer accepted=0,completed=0,canceled=0,extra=0,cycles=0,n,phase,waits;
 integer born_slot,killed_tag,serial_number=10,extra_before;
 reg [63:0] value;
 reg held=0;reg [8:0] held_tag;reg [`R64_RESULT_W-1:0] held_data;
 task tick;begin @(posedge clk);#1;end endtask
 task negative_edge;begin @(negedge clk);end endtask
 task prepare(input [8:0] t,input conversion);
 begin
  tag=t;uop=0;
  // FCVT.L.D(2.0) or FMV.X.D with a unique exact bit pattern.
  uop[159:128]=conversion?32'hc2200053:32'he2000053;
  value=conversion?64'h4000000000000000:(64'h3456000000000000|{55'b0,t});
  operand={128'b0,value};expected[t]=conversion?64'd2:value;
 end endtask
 task put(input [8:0] t,input conversion);
 begin
  negative_edge();prepare(t,conversion);
  while(!credit)negative_edge();
  fire=1;tick();negative_edge();fire=0;
 end endtask
 task drain;
 begin
  ready=1;waits=0;
  while((pending!=0||dut.fast.owner.allocated_q!=0||dut.ingress_valid_q||dut.fast.token_q!=0)&&waits<400)begin tick();waits=waits+1;end
  if(pending!=0||dut.fast.owner.allocated_q!=0||dut.fast.token_q!=0)$fatal(1,"Fast numerical owner failed to drain");
  repeat(12)tick();
 end endtask
 always @(posedge clk)begin
  cycles=cycles+1;
  if(rst||flush)begin
   for(integer a=0;a<512;a=a+1)if(pending[a])canceled=canceled+1;
   pending=0;held=0;
  end else begin
   for(integer a=0;a<512;a=a+1)if(pending[a]&&kill[a%32])begin pending[a]=0;canceled=canceled+1;end
   if(fire)begin
    accepted=accepted+1;
    if(kill[tag%32])canceled=canceled+1;
    else begin if(pending[tag])$fatal(1,"test reused live full tag");pending[tag]=1;end
   end
   if(dut.fast_offer_w&&!dut.fire[2])begin
    if(!kill[dut.tag_q[4:0]])$fatal(1,"extra numeric producer lacks killed owner");
    extra=extra+1;
   end
   if(held&&!kill[held_tag%32])begin
    if(!valid||result_tag!==held_tag||result!==held_data)$fatal(1,"held visible FP result changed");
   end
   held=valid&&!ready;held_tag=result_tag;held_data=result;
   if(valid&&ready)begin
    if(!pending[result_tag])$fatal(1,"killed/stale/anonymous fulltag result %h",result_tag);
    if(result[`R64_RESULT_W-1:64]!==0||result[63:0]!==expected[result_tag])
      $fatal(1,"wrong live FP value tag%h value%h expected%h",result_tag,result[63:0],expected[result_tag]);
    pending[result_tag]=0;completed=completed+1;
   end
  end
 end
 initial begin
  tick();negative_edge();rst=0;
  // Both the short producer and the ten-stage conversion must mark a
  // cancellation birth dead before its first possible numeric completion.
  for(phase=0;phase<2;phase=phase+1)begin
   ready=0;extra_before=extra;
   // Fill actual Fast slots under actual terminal backpressure. Stop at
   // the final free slot with a real ingress head, without forcing credit.
   n=0;
   while(!(dut.fast.owner.reserved_q[13]&&dut.ingress_valid_q&&dut.path_q==2&&dut.path_ready[2])&&n<30)begin
    negative_edge();prepare(serial_number[8:0],phase!=0);
    if(!credit)$fatal(1,"ingress filled before final Fast slot boundary");
    fire=1;tick();fire=0;serial_number=serial_number+1;n=n+1;
   end
   if(n==30)$fatal(1,"did not reach actual final Fast slot");
   negative_edge();killed_tag=dut.tag_q;born_slot=dut.fast.allocation_w;
   kill[killed_tag%32]=1;#1;
   if(!dut.fast_offer_w||dut.fire[2])$fatal(1,"cancellation numerical offer not reached");
   tick();
   if(!dut.fast.owner.allocated_q[born_slot]||!dut.fast.owner.birth_killed_q||!dut.fast.owner.reserved_q[14])
     $fatal(1,"killed producer did not own actual final slot");
   negative_edge();kill=0;tick();
   if(dut.fast.owner.dead_q[born_slot]==0)$fatal(1,"killed birth not sticky before completion");
   if(extra!=extra_before+1)$fatal(1,"killed head dispatched repeatedly");
   // A numerically older live request and a reused ROB slot generation
   // wait in ingress while all real Fast slots, including the dead one, drain.
   put(9'd0,0);put((killed_tag^32),0);
   if(dut.path_ready[2])$fatal(1,"full Fast capacity fabricated credit");
   negative_edge();drain();negative_edge();
  end
  // Raw offer on fullflush/reset must leave no producer without a slot.
  for(phase=0;phase<2;phase=phase+1)begin
   ready=1;negative_edge();prepare((9'd300+phase),1);fire=1;tick();fire=0;
   negative_edge();if(!dut.fast_offer_w)$fatal(1,"no raw offer at local reset boundary");
   if(phase==0)flush=1;else rst=1;
   tick();
   if(dut.fast.token_q!=0||dut.fast.owner.allocated_q!=0||dut.fast.owner.reserved_q!=1)
     $fatal(1,"reset split numeric producer from completion owner");
   negative_edge();flush=0;rst=0;
   put((9'd332+phase),0);drain();
  end
  if(extra!=2||accepted!=completed+canceled)$fatal(1,"owner conservation %0d/%0d/%0d extra%0d",accepted,completed,canceled,extra);
  $display("[PASS] tb_r64_fast_raw_owner accepted=%0d completed=%0d canceled=%0d extra_dead=%0d cycles=%0d",accepted,completed,canceled,extra,cycles);
  $finish;
 end
 initial begin #1000000;$fatal(1,"timeout");end
endmodule
