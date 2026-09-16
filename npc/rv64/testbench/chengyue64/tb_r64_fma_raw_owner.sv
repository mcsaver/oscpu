
`timescale 1ns/1ps
`include "R64Uop.vh"
module tb_r64_fma_raw_owner;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,fire=0,ready=0;
 reg [31:0] kill=0;reg [8:0] tag=0;
 reg [`R64_UOP_W-1:0] uop=0;reg [191:0] operand=0;
 wire [1:0] credit,valid;
 wire [17:0] result_tag;wire [2*`R64_RESULT_W-1:0] result;
 R64FpExecute #(.Q_CREDIT_INGRESS(1),.RAW_FAST_DISPATCH(1),.RAW_FMA_DISPATCH(1)) dut(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit[1]),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i(operand),
 .fp_enabled_i(1'b1),.frm_i(3'b0),.out_valid_o(valid[1]),.out_ready_i(ready),
 .out_tag_o(result_tag[9+:9]),.out_result_o(result[`R64_RESULT_W+:`R64_RESULT_W]));
 R64FpExecute #(.Q_CREDIT_INGRESS(1),.RAW_FAST_DISPATCH(1),.RAW_FMA_DISPATCH(0)) refdut(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit[0]),.in_tag_i(tag),.in_uop_i(uop),.in_operand_i(operand),
 .fp_enabled_i(1'b1),.frm_i(3'b0),.out_valid_o(valid[0]),.out_ready_i(ready),
 .out_tag_o(result_tag[0+:9]),.out_result_o(result[0+:`R64_RESULT_W]));
 reg [511:0] pending[0:1];reg [63:0] expected[0:511];
 integer accepted[0:1],completed[0:1],canceled[0:1],output_cycle[0:1][0:511];
 integer dispatch_cycle[0:1][0:511];
 integer extra=0,cycles=0,n,phase,waits,kt,older=22,reused;
 reg [1:0] held=0;reg [8:0] held_tag[0:1];reg [`R64_RESULT_W-1:0] held_data[0:1];
 integer hot_run[0:1],hot_longest[0:1];reg hot=0;
 task tick;begin @(posedge clk);#1;end endtask
 task neg;begin @(negedge clk);end endtask
 task prepare(input [8:0] t);
 begin
  tag=t;uop=0;
  // Real FADD.D 2+3 and FMADD.D 2*3+4.
  uop[159:128]=t[0]?32'h02000043:32'h02000053;
  operand={64'h4010000000000000,64'h4008000000000000,64'h4000000000000000};
  expected[t]=t[0]?64'h4024000000000000:64'h4014000000000000;
 end endtask
 task put(input [8:0] t);
 begin neg();prepare(t);while(!(&credit))neg();fire=1;tick();neg();fire=0;end endtask
 task drain;
 begin
  ready=1;waits=0;
  while((pending[0]!=0||pending[1]!=0||dut.fma.owner.reserved_hot_q!=1||
   refdut.fma.owner.reserved_hot_q!=1||dut.ingress_valid_q||refdut.ingress_valid_q)&&waits<300)begin tick();waits=waits+1;end
  if(waits==300)$fatal(1,"FMA owner drain timed out");
  repeat(4)tick();
 end endtask
 always @(posedge clk)begin
  cycles=cycles+1;
  for(integer m=0;m<2;m=m+1)begin
   if(rst||flush)begin
    for(integer a=0;a<512;a=a+1)if(pending[m][a])canceled[m]=canceled[m]+1;
    pending[m]=0;held[m]=0;
   end else begin
    for(integer a=0;a<512;a=a+1)if(pending[m][a]&&kill[a%32])begin
     pending[m][a]=0;canceled[m]=canceled[m]+1;
    end
    if(fire)begin
     if(!credit[m])$fatal(1,"A/B input violated real credit");
     accepted[m]=accepted[m]+1;
     if(kill[tag%32])canceled[m]=canceled[m]+1;
     else begin if(pending[m][tag])$fatal(1,"fulltag reused while live");pending[m][tag]=1;end
    end
    if(held[m]&&!kill[held_tag[m]%32])
     if(!valid[m]||result_tag[m*9+:9]!==held_tag[m]||result[m*`R64_RESULT_W+:`R64_RESULT_W]!==held_data[m])
      $fatal(1,"held FMA visible payload changed");
    held[m]=valid[m]&&!ready;held_tag[m]=result_tag[m*9+:9];held_data[m]=result[m*`R64_RESULT_W+:`R64_RESULT_W];
    if(valid[m]&&ready)begin
     if(!pending[m][result_tag[m*9+:9]])$fatal(1,"killed/stale/anonymous FMA result m%0d tag%h",m,result_tag[m*9+:9]);
     if(result[m*`R64_RESULT_W+:`R64_RESULT_W]!=={{(`R64_RESULT_W-64){1'b0}},expected[result_tag[m*9+:9]]})
      $fatal(1,"wrong FMA numeric result");
     pending[m][result_tag[m*9+:9]]=0;completed[m]=completed[m]+1;
     output_cycle[m][result_tag[m*9+:9]]=cycles;
     if(hot)begin hot_run[m]=hot_run[m]+1;if(hot_run[m]>hot_longest[m])hot_longest[m]=hot_run[m];end
    end else hot_run[m]=0;
   end
  end
  if(!rst&&!flush)begin
   if(dut.fire[0])dispatch_cycle[1][dut.tag_q]=cycles;
   if(refdut.fire[0])dispatch_cycle[0][refdut.tag_q]=cycles;
   if(dut.fma_offer_w&&!dut.fire[0])begin
    if(!kill[dut.tag_q[4:0]])$fatal(1,"raw FMA extra offer is live");
    extra=extra+1;
   end
  end
 end
 initial begin
  for(integer m=0;m<2;m=m+1)begin
   pending[m]=0;accepted[m]=0;completed[m]=0;canceled[m]=0;hot_run[m]=0;hot_longest[m]=0;
   for(integer a=0;a<512;a=a+1)begin output_cycle[m][a]=-1;dispatch_cycle[m][a]=-1;end
  end
  tick();neg();rst=0;
  n=0;
  while(!(dut.fma.owner.reserved_hot_q[21]&&!dut.fma.owner.credit_return_q&&
   dut.ingress_valid_q&&dut.path_q==0&&dut.path_ready[0])&&n<40)begin
   neg();prepare(64+n);if(!(&credit))$fatal(1,"did not reach final capacity with real input credit");
   fire=1;tick();fire=0;n=n+1;
  end
  if(n==40)$fatal(1,"missing final FMA reservation boundary");
  neg();kt=dut.tag_q;reused=kt^32;kill[kt%32]=1;#1;
  if(!dut.fma_offer_w||dut.fire[0])$fatal(1,"no canceled FMA birth");
  tick();
  if(!dut.fma.owner.token_q[0]||!dut.fma.owner.dead_q[0]||
   !dut.fma.owner.reserved_hot_q[22]||dut.fma.stage_live_w[0])
   $fatal(1,"birth killed FMA producer missing token/dead/reservation");
  neg();kill=0;
  put(older);put(reused);
  if(dut.path_ready[0])$fatal(1,"full capacity fabricated FMA credit");
  repeat(8)tick();
  if(dispatch_cycle[0][older]<0||dispatch_cycle[1][older]>=0)$fatal(1,"full dead reservation did not expose real dispatch cost");
  neg();drain();
  $display("[FMA-RAW-COST] older dispatch base=%0d candidate=%0d output base=%0d candidate=%0d delta=%0d reuse_output_delta=%0d",
   dispatch_cycle[0][older],dispatch_cycle[1][older],output_cycle[0][older],output_cycle[1][older],
   output_cycle[1][older]-output_cycle[0][older],output_cycle[1][reused]-output_cycle[0][reused]);
  put(9'd160);repeat(5)tick();neg();kill[0]=1;tick();neg();kill=0;
  put(9'd192);drain();neg();ready=0;put(9'd193);
  waits=0;while(!(&valid)&&waits<60)begin tick();waits=waits+1;end
  if(waits==60)$fatal(1,"held FMA did not become visible");
  repeat(5)tick();neg();kill[1]=1;tick();neg();kill=0;ready=1;
  put(9'd225);drain();
  for(phase=0;phase<2;phase=phase+1)begin
   neg();prepare(9'd300+phase);fire=1;tick();fire=0;
   neg();if(!dut.fma_offer_w)$fatal(1,"missing raw reset-edge offer");
   if(phase==0)flush=1;else rst=1;tick();
   if(dut.fma.owner.token_q!=0||dut.fma.owner.reserved_hot_q!=1||!dut.fma.owner.empty_q)
    $fatal(1,"reset left unowned FMA completion");
   neg();flush=0;rst=0;put(9'd332+phase);drain();
  end
  hot=1;ready=1;
  for(n=0;n<32;n=n+1)begin neg();prepare(9'd384+n);if(!(&credit))$fatal(1,"hot FMA credit bubble");fire=1;tick();end
  neg();fire=0;drain();hot=0;
  for(n=384;n<416;n=n+1)if(output_cycle[0][n]!=output_cycle[1][n])$fatal(1,"ordinary FMA latency changed");
  if(hot_longest[0]!=32||hot_longest[1]!=32)$fatal(1,"FMA lost II1");
  for(n=0;n<2;n=n+1)if(accepted[n]!=completed[n]+canceled[n])$fatal(1,"owner conservation");
  if(extra!=1)$fatal(1,"raw killed FMA head offered repeatedly");
  $display("[PASS] tb_r64_fma_raw_owner accepted=%0d complete=%0d cancel=%0d extra_dead=%0d cycles=%0d hot_II1=%0d",
   accepted[1],completed[1],canceled[1],extra,cycles,hot_longest[1]);
  $finish;
 end
 initial begin #1000000;$fatal(1,"timeout");end
endmodule
