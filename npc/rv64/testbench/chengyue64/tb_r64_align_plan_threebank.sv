`timescale 1ns/1ps
module tb_r64_align_plan_threebank;
 reg clk=0;always #5 clk=~clk;
 reg rst=1;wire ready;reg [63:0] packet_pc=64'h8000000e;
 reg [127:0] packet_data=0;wire [1:0] valid;
 wire [63:0] pc0,pc1,raw0,raw1,tval0,tval1,target,source;
 wire [3:0] len0,len1;wire fault0,fault1;wire [4:0] cause0,cause1;
 wire [1:0] at_plan,bad_plan;
 reg [1:0] consume=0;reg pv=0,plan=0,jump=0;reg [63:0] dest=64'h90000000;
 R64Align #(.EARLY_PREDICT(1),.RESET_PC(64'h8000000e)) dut(
 .clk_i(clk),.rst_i(rst),.redirect_i(1'b0),.redirect_pc_i(64'b0),
 .packet_valid_i(pv),.packet_ready_o(ready),.packet_pc_i(packet_pc),.packet_data_i(packet_data),
 .packet_fault_i(1'b0),.packet_cause_i(5'b0),.packet_access_mask_i(8'b0),
 .packet_plan_valid_i(plan),.packet_plan_offset_i(3'b0),.packet_plan_word_i(1'b1),.packet_plan_target_i(dest[63:1]),
 .jump_i(jump),.jump_pc_i(dest),.plan_at_o(at_plan),.plan_bad_o(bad_plan),.plan_target_o(target),.plan_source_o(source),
 .valid_o(valid),.consume_i(consume),.pc0_o(pc0),.pc1_o(pc1),.inst0_o(raw0),.inst1_o(raw1),
 .length0_o(len0),.length1_o(len1),.fault0_o(fault0),.fault1_o(fault1),.cause0_o(cause0),.cause1_o(cause1),
 .tval0_o(tval0),.tval1_o(tval1));
 integer cuts=0;reg [63:0] branch_source;
 task packet(input [63:0] address,input [127:0] data,input prediction);
 begin
  @(negedge clk);pv=1;packet_pc=address;packet_data=data;plan=prediction;
  do @(posedge clk);while(!ready);
  @(negedge clk);pv=0;plan=0;
 end endtask
 initial begin
  @(negedge clk);rst=0;
  packet(64'h8000000e,{8{16'h0001}},0);
  packet(64'h80000010,{4{32'h0000006f}},1);
  packet(dest,{4{32'h00108093}},0);
  repeat(1)@(negedge clk);
  if(dut.count_q!=3||valid!=3||at_plan!=2'b10||bad_plan!=0)
   $fatal(1,"full threebank next-sector branch unavailable");
  if(pc0!=64'h8000000e||raw0!=1||len0!=2||pc1!=64'h80000010||raw1!=32'h0000006f||len1!=4)
   $fatal(1,"next-sector branch instruction ownership");
  @(negedge clk);consume=2;jump=1;
  @(posedge clk);
  if(dut.pop_count_w!=2)$fatal(1,"next-sector plan failed to discard two source owners");
  #1;cuts=cuts+1;
  if(dut.count_q!=1||dut.head_q!=2||pc0!=dest||raw0!=32'h00108093||len0!=4)
   $fatal(1,"third-bank target not retained after two-owner cut");
  @(negedge clk);consume=0;jump=0;
  // Fill modulo3 slots0/1 behind retained slot2 then consume through wrap.
  packet(dest+16,{4{32'h00210113}},0);
  packet(dest+32,{4{32'h00318193}},0);
  repeat(1)@(negedge clk);
  if(dut.count_q!=3||dut.head_q!=2||dut.tail_q!=2)$fatal(1,"modulo3 refill owner");
  repeat(2)begin @(negedge clk);consume=2;@(posedge clk);#1;end
  if(dut.head_q!=0||dut.count_q!=2||pc0!=dest+16||raw0!=32'h00210113)
   $fatal(1,"modulo3 head wrap corrupted retained owner");
  @(negedge clk);consume=0;
  $display("[PASS] tb_r64_align_plan_threebank pop2_target_retained=%0d modulo3_refill_wrap=1",cuts);$finish;
 end
endmodule
