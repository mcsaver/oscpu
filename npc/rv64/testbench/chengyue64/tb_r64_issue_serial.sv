`timescale 1ns/1ps
module tb_r64_issue_serial;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0,serial_allow=0,barrier_valid=0;
 reg [31:0] kill=0,active=0,released=0;
 reg [4:0] head=0,barrier=0;
 reg [1:0] enq=0,ready=3;reg [17:0] tags=0;reg [5:0] classes=0;
 wire [1:0] credit,fire;wire [17:0] issued_tag;wire [4:0] count;
 R64Issue #(.PAYLOAD_W(32)) dut(
  .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),.rob_head_i(head),
  .barrier_valid_i(barrier_valid),.barrier_slot_i(barrier),
  .serial_active_i(active),.serial_release_i(released),
  .enq_valid_i(enq),.enq_ready_o(credit),.enq_tag_i(tags),.enq_payload_i(64'b0),
  .enq_class_i(classes),.enq_gpr_dst_i(12'b0),.enq_src_preg_i(36'b0),
  .enq_src_fp_i(6'b0),.enq_src_used_i(6'b0),.enq_src_ready_i(6'b111111),
  .wake_valid_i(2'b0),.wake_fp_i(2'b0),.wake_preg_i(12'b0),.early_valid_i(2'b0),.early_preg_i(12'b0),
  .enq_mem_slot_i(10'b0),.issue_mem_slot_o(),.fu_allow_i(6'b111111),.serial_allow_i(serial_allow),
  .issue_ready_i(ready),.issue_fire_o(fire),.issue_tag_o(issued_tag),
  .issue_payload_o(),.issue_class_o(),.issue_gpr_dst_o(),.issue_src_preg_o(),
  .issue_src_fp_o(),.issue_src_used_o(),.count_o(count));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input good;input [511:0] msg;begin if(good!==1'b1)$fatal(1,"%0s",msg);end endtask
 task birth;
 input integer a,b,ca,cb;input [1:0] lanes;
 begin
  enq=lanes;tags={9'(b),9'(a)};classes={3'(cb),3'(ca)};#1;
  check((credit&lanes)==lanes,"serial owner birth credit");tick();enq=0;
 end endtask
 initial begin
  tick();rst=0;
  birth(0,1,5,0,3);active=1;barrier_valid=1;barrier=0;#1;
  check(fire==0,"same-bundle younger crossed newborn serial");
  serial_allow=1;#1;check(fire==1&&issued_tag[8:0]==0,"exact head serial permission");
  tick();serial_allow=0;#1;check(fire==0,"issued serial lost its unretired barrier");
  birth(2,3,0,5,3);active=9;birth(4,5,0,0,3);
  // Birth and retirement share the edge: the new owner depends only on
  // still-live serial 3, while owners 1/2 are released by serial 0.
  released=1;birth(6,0,0,0,1);released=0;active=8;barrier=3;head=1;#1;
  check(fire==3&&issued_tag=={9'd2,9'd1},"serial release did not expose exact older prefix");
  tick();#1;check(fire==0,"second unretired serial failed to hold younger owners");
  head=3;serial_allow=1;#1;check(fire==1&&issued_tag[8:0]==3,"second exact-head serial");
  tick();serial_allow=0;
  // Slot 3 changes generation on the same release/birth edge. Existing
  // owners 4/5/6 must not acquire a dependence on the later serial 35.
  released=8;birth(35,0,5,0,1);released=0;head=4;#1;
  check(fire==3&&issued_tag=={9'd5,9'd4},"old serial generation resurrected dependency");
  tick();#1;check(fire==1&&issued_tag[8:0]==6,"remaining old owner blocked by reused serial slot");
  tick();head=7;birth(36,0,0,0,1);#1;
  check(fire==0,"new owner failed to depend on new serial generation");
  kill=32'h18;released=32'h18;tick();kill=0;released=0;active=0;barrier_valid=0;#1;
  check(count==0&&fire==0,"killed serial and child retained ownership");
  head=3;birth(67,68,5,0,3);active=8;barrier_valid=1;barrier=3;#1;
  check(fire==0,"fresh same-bundle dependency missing after kill/reuse");
  serial_allow=1;#1;check(fire==1&&issued_tag[8:0]==67,"new serial generation head permission");
  tick();serial_allow=0;released=8;tick();released=0;active=0;barrier_valid=0;#1;
  check(fire==1&&issued_tag[8:0]==68,"new child lost release event");tick();
  flush=1;tick();flush=0;check(count==0,"serial dependency flush");
  $display("[PASS] tb_r64_issue_serial birth/release multiple-barriers slot-generation kill flush");
  $finish;
 end
endmodule
