`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_fp_qcredit;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=1,enabled=1;
 reg [31:0] kill=0;reg [8:0] tag=0;reg [2:0] frm=0;
 reg [`R64_UOP_W-1:0] uop=0;reg [191:0] operands=0;
 wire credit,valid;wire [8:0] out_tag;wire [`R64_RESULT_W-1:0] result;
 R64FpExecute #(.Q_CREDIT_INGRESS(1)) dut(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i(operands),
 .fp_enabled_i(enabled),.frm_i(frm),.out_valid_o(valid),.out_ready_i(ready),
 .out_tag_o(out_tag),.out_result_o(result));
 reg [31:0] pending=0;
 reg [8:0] owners[0:31];
 integer accepted=0,completed=0,canceled=0,dispatches=0,cycles=0,full_release=0,k;
 reg [8:0] last_dispatch=0;
 reg held=0;reg [8:0] held_tag;reg [`R64_RESULT_W-1:0] held_result;
 task tick;begin @(posedge clk);#1;end endtask
 task put(input [8:0] id);begin
  if(!credit)$fatal(1,"put without queue credit");
  tag=id;fire=1;tick();fire=0;
 end endtask
 task drain;integer timeout_count;begin
  timeout_count=0;
  while(pending&&timeout_count<300)begin tick();timeout_count=timeout_count+1;end
  if(pending)$fatal(1,"queue failed to drain");
 end endtask
 always @(posedge clk)begin
  if(rst||flush)begin
   for(integer n=0;n<32;n=n+1)if(pending[n])canceled=canceled+1;
   pending=0;held=0;
  end else begin
   cycles=cycles+1;
   for(integer n=0;n<32;n=n+1)if(kill[n]&&pending[n])begin pending[n]=0;canceled=canceled+1;end
   if(fire&&!kill[tag[4:0]])begin
    if(pending[tag[4:0]])$fatal(1,"test reused live physical ROB slot");
    owners[tag[4:0]]=tag;pending[tag[4:0]]=1;accepted=accepted+1;
   end
   if(dut.dispatch)begin dispatches=dispatches+1;last_dispatch=dut.tag_q;end
   if(held&&!kill[held_tag[4:0]])begin
    if(!valid||out_tag!==held_tag||result!==held_result)$fatal(1,"held output changed");
   end
   held=valid&&!ready;held_tag=out_tag;held_result=result;
   if(valid&&ready)begin
    if(!pending[out_tag[4:0]]||owners[out_tag[4:0]]!==out_tag)$fatal(1,"stale or duplicate FP result");
    if(result[63:0]!==64'h3ff0000000000000||result[`R64_RESULT_W-1:64]!==0)$fatal(1,"FP result corrupted");
    pending[out_tag[4:0]]=0;completed=completed+1;
   end
  end
 end
 initial begin
  uop[159:128]=32'h22000053;
  operands={64'b0,64'h4000000000000000,64'h3ff0000000000000};
  tick();rst=0;tick();
  // Real younger ingress can be killed while an older RR instruction arrives.
  force dut.path_ready=4'b0;
  put(9'd20);
  kill[20]=1;
  if(!credit)$fatal(1,"single occupied queue did not accept older replacement");
  put(9'd10);kill=0;
  if(dut.tag_q!==9'd10||!dut.ingress_valid_q)$fatal(1,"killed head cleared older replacement");
  put(9'd11);
  if(credit)$fatal(1,"two owners did not consume both physical slots");
  if($test$plusargs("bad-credit"))begin fire=1;tag=30;tick();$fatal(1,"bad credit not rejected");end
  kill[11]=1;#1;
  if(credit)$fatal(1,"kill leaked into Q-only credit");
  tick();kill=0;
  if(!credit||dut.tag_q!==9'd10)$fatal(1,"tail kill lost head");
  put(9'd43);
  release dut.path_ready;#1;
  if(credit)$fatal(1,"pop lookahead leaked into full Q credit");
  tick();full_release=full_release+1;
  if(last_dispatch!==9'd10||!credit)$fatal(1,"full release did not retain old head");
  tick();
  if(last_dispatch!==9'd43)$fatal(1,"new generation was not second dispatch");
  drain();
  // Full dispatch releases a slot only after its edge; then pop+push is II1.
  force dut.path_ready=4'b0;
  put(9'd12);put(9'd13);
  release dut.path_ready;#1;
  if(credit||!dut.dispatch)$fatal(1,"full pop boundary not exercised");
  tick();full_release=full_release+1;
  put(9'd14);
  if(last_dispatch!==9'd13)$fatal(1,"simultaneous pop/push reordered old owner");
  tick();if(last_dispatch!==9'd14)$fatal(1,"new owner added empty-path cycle");
  drain();
  // Same-edge birth+kill never creates a live owner.
  kill[15]=1;put(9'd15);kill=0;
  if(dut.ingress_valid_q)$fatal(1,"birth kill revived owner");
  // Flush two occupied owners; reuse their slots with a new generation.
  force dut.path_ready=4'b0;
  put(9'd16);put(9'd17);
  flush=1;tick();flush=0;
  if(!credit||dut.ingress_valid_q)$fatal(1,"flush retained ingress owners");
  put(9'd48);release dut.path_ready;drain();
  // Held completion remains stable, then cancellation must drain without READY.
  ready=0;put(9'd18);
  k=0;while(!valid&&k<100)begin tick();k=k+1;end
  if(!valid)$fatal(1,"no held completion");
  repeat(20)tick();
  kill[18]=1;tick();kill=0;
  ready=1;put(9'd50);drain();
  if(full_release!=2||accepted!=completed+canceled)$fatal(1,"owner accounting");
  $display("[PASS] tb_r64_fp_qcredit accepted=%0d completed=%0d canceled=%0d full_release_bubbles=%0d dispatch=%0d cycles=%0d",accepted,completed,canceled,full_release,dispatches,cycles);
  $finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
