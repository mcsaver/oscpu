 `timescale 1ns/1ps
module tb_r64_issue_mdu_pair;
 localparam U=218;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,flush=0;reg [31:0] km=0;
 reg [1:0] enq=0,ready=0;reg [17:0] tag=0;
 reg [2*U-1:0] payload=0;reg [5:0] cls=0,fp=0,used=0;
 wire [1:0] credit,fire;wire [17:0] outtag;wire [2*U-1:0] outpayload;wire [5:0] outclass;
 R64Issue #(.PAYLOAD_W(U),.MDU_RESOURCE_PAIR(1)) dut(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(km),
 .cancel_candidates_i(km),.cancel_active_i(|km),.rob_head_i(5'd0),
 .barrier_valid_i(1'b0),.barrier_slot_i(5'd0),.serial_active_i(32'd0),.serial_release_i(32'd0),
 .enq_valid_i(enq),.enq_ready_o(credit),.enq_tag_i(tag),.enq_mem_slot_i(10'd0),
 .enq_payload_i(payload),.enq_class_i(cls),.enq_gpr_dst_i(12'd0),
 .enq_src_preg_i(36'd0),.enq_src_fp_i(fp),.enq_src_used_i(used),.enq_src_ready_i(6'd63),
 .ready_query_ready_i(6'd63),.wake_valid_i(2'd0),.wake_fp_i(2'd0),.wake_preg_i(12'd0),
 .early_valid_i(2'd0),.early_preg_i(12'd0),.fu_allow_i(6'd63),.serial_allow_i(1'b1),
 .issue_ready_i(ready),.issue_fire_o(fire),.issue_tag_o(outtag),.issue_payload_o(outpayload),
 .issue_class_o(outclass));
 task tick;begin @(posedge clk);#1;end endtask
 task check;input c;input [511:0] msg;begin if(c!==1'b1)$fatal(1,"%0s",msg);end endtask
 task pair_case;
  input integer ca,cb,fa,fb;input want_pair;
  begin
   rst=1;ready=0;enq=0;km=0;tick();rst=0;
   tag={9'd33,9'd32};cls={3'(cb),3'(ca)};payload=0;
   payload[196+:8]=8'(fa);payload[U+196+:8]=8'(fb);enq=3;
   #1;check(credit==3,"pair allocation");tick();enq=0;ready=3;#1;
   check(fire==(want_pair?3:1),"resource pairing differs from independent expected case");
   check(outtag[8:0]==32&&outclass[2:0]==ca&&outpayload[196+:8]==fa,"first owner changed");
   if(want_pair)check(outtag[17:9]==33&&outclass[5:3]==cb&&outpayload[U+196+:8]==fb,"second owner changed");
   tick();ready=0;
  end
 endtask
 initial begin
  pair_case(2,2,0,4,1);pair_case(2,2,4,0,1);
  pair_case(2,2,0,8,1);pair_case(2,2,8,4,1);
  pair_case(2,2,0,0,0);pair_case(2,2,4,4,0);pair_case(2,2,8,8,0);
  pair_case(0,0,0,0,1);pair_case(4,4,0,0,1);pair_case(3,3,0,0,0);
  fp=6'b001111;used=fp;pair_case(3,4,0,0,0);
  fp=0;used=0;rst=1;tick();rst=0;ready=0;enq=3;
  tag={9'd33,9'd32};cls={3'd2,3'd2};payload=0;payload[U+196+:8]=4;
  tick();enq=0;km=2;ready=3;#1;
  check(fire==1&&outtag[8:0]==32,"partial kill published the second MDU owner");tick();
  $display("[PASS] tb_r64_issue_mdu_pair independent-subunits same-unit-conflict FP-budget partial-kill");
  $finish;
 end
endmodule
