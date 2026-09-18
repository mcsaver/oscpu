`timescale 1ns/1ps
module tb_r64_fp_completion;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,iv=0,ready=0;reg [31:0] kill=0;reg [8:0] itag=0;
 wire credit,ov;wire [3:0] allocation;wire [8:0] otag;wire [68:0] data;
 reg [1:0] cv=0;reg [7:0] slot=0;reg [137:0] cd=0;
 reg [3:0] slots[0:13];integer i,n,cycles;
 R64FpCompletion dut(.clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
  .in_valid_i(iv),.in_ready_o(credit),.in_tag_i(itag),.allocation_o(allocation),
  .complete_valid_i(cv),.complete_slot_i(slot),.complete_data_i(cd),
  .out_valid_o(ov),.out_ready_i(ready),.out_tag_o(otag),.out_data_o(data));
 task tick;begin @(posedge clk);#1;end endtask
 task put(input integer index,input integer tagvalue);begin
  if(!credit)$fatal(1,"unexpected admission stall");
  iv=1;itag=9'(tagvalue);#1;slots[index]=allocation;tick();iv=0;
 end endtask
 task finish_one(input integer index,input integer tagvalue);begin
  cv=1;slot[3:0]=slots[index];cd[68:0]=69'(tagvalue)*69'd12345+69'd678;tick();cv=0;
 end endtask
 initial begin
  tick();rst=0;
  for(i=0;i<14;i=i+1)put(i,i);
  if(credit)$fatal(1,"full completion ring advertised capacity");
  for(i=2;i<14;i=i+2)finish_one(i,i);
  if(ov)$fatal(1,"younger completion crossed unfinished head");
  kill=1;tick();kill=0;
  cv=3;slot={slots[1],slots[0]};cd={69'd13023,69'd678};tick();cv=0;
  tick();
  repeat(7)begin
   if(!ov||otag!=1||data!=69'd13023)$fatal(1,"held next-head completion changed");
   tick();
  end
  for(i=3;i<14;i=i+2)finish_one(i,i);
  ready=1;n=1;cycles=0;
  while(n<14&&cycles<100)begin
   if(ov)begin
    if(otag!=9'(n)||data!=69'(n)*69'd12345+69'd678)$fatal(1,"completion order/data mismatch");
    n=n+1;
   end
   tick();cycles=cycles+1;
  end
  if(n!=14)$fatal(1,"completion drain stalled");
  repeat(4)tick();ready=0;
  for(i=0;i<14;i=i+1)put(i,32+i);
  kill=32'hffffffff;tick();kill=0;
  repeat(20)begin
   if(credit||ov)$fatal(1,"unfinished canceled producer slot released early");
   tick();
  end
  for(i=0;i<14;i=i+2)begin
   cv=3;slot={slots[i+1],slots[i]};cd={69'd777,69'd888};tick();cv=0;
   if(ov)$fatal(1,"canceled completion escaped");
  end
  repeat(30)begin tick();if(ov)$fatal(1,"canceled owner resurrected");end
  if(dut.allocated_q!=0||!credit)$fatal(1,"tombstone credits failed to return");
  put(0,64);cv=1;slot[3:0]=slots[0];cd[68:0]=69'd999;flush=1;tick();cv=0;flush=0;
  if(ov||dut.allocated_q!=0)$fatal(1,"flush captured stale completion");
  put(0,96);finish_one(0,96);
  if(!ov||otag!=96||data!=69'd1185798)$fatal(1,"generation reuse lost new result");
  ready=1;tick();repeat(4)tick();
  // An owner killed on its admission edge completes at the earliest
  // legal edge next cycle. Deferred birth cancellation must still win.
  ready=0;kill=32'h20;put(0,5);kill=0;finish_one(0,5);
  if(ov)$fatal(1,"admission-killed earliest completion escaped");
  repeat(5)tick();
  if(dut.allocated_q!=0||!credit)$fatal(1,"admission-killed owner failed to reclaim");
  put(0,37);finish_one(0,37);
  if(!ov||otag!=37||data!=69'd457443)$fatal(1,"admission-cancel generation reuse");
  ready=1;tick();repeat(4)tick();
  $display("[R64-FP-COMPLETION] out-of-order/two-port/14-reservations/held/kill-before-complete/flush/reuse PASS");
  $display("[PASS] tb_r64_fp_completion");$finish;
 end
 initial begin #100000;$fatal(1,"completion timeout");end
endmodule
