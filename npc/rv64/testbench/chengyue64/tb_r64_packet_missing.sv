`timescale 1ns/1ps
module tb_r64_packet_missing;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,redirect=0;reg [63:0] redirect_pc=64'ha000000e;reg [7:0] mask=0;wire ready;reg [63:0] packet_pc=64'h8000000e;
 reg [127:0] packet_data=0;wire [1:0] valid;
 wire [63:0] pc0,pc1,raw0,raw1,tval0,tval1,target,source;
 wire [3:0] len0,len1;wire fault0,fault1;wire [4:0] cause0,cause1;
 wire [1:0] at_plan,bad_plan;
 reg [1:0] consume=0;reg pv=0,plan=0,jump=0;reg [63:0] dest=64'h90000000;
 R64Align #(.EARLY_PREDICT(1),.RESET_PC(64'h8000000e)) dut(
 .clk_i(clk),.rst_i(rst),.redirect_i(redirect),.redirect_pc_i(redirect_pc),
 .packet_valid_i(pv),.packet_ready_o(ready),.packet_pc_i(packet_pc),.packet_data_i(packet_data),
 .packet_fault_i(1'b0),.packet_cause_i(5'b0),.packet_access_mask_i(mask),
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
 reg [127:0] first_packet,next_packet;
 integer wait_checks=0,hold_checks=0;
 initial begin
  first_packet={8{16'h0001}};first_packet[127:112]=16'h305b;
  next_packet={8{16'h0001}};next_packet[47:0]=48'h89abcdef0200;
  @(negedge clk);rst=0;
  packet(64'h8000000e,first_packet,0);
  repeat(8)begin
   @(negedge clk);
   if(valid[0]||bad_plan!=0)$fatal(1,"missing true successor supplied speculative header");
   wait_checks=wait_checks+1;
  end
  packet(64'h80000010,next_packet,0);
  // Source was captured, but the P1 owner has not yet completed.
  if(valid[0])$fatal(1,"completion bypassed its registered parse boundary");
  @(posedge clk);#1;
  if(!valid[0]||pc0!=64'h8000000e||len0!=8||raw0!=64'h89abcdef0200305b||fault0)
   $fatal(1,"actual successor did not complete the original eight-byte owner");
  repeat(6)begin
   @(negedge clk);
   if(!valid[0]||pc0!=64'h8000000e||raw0!=64'h89abcdef0200305b)
    $fatal(1,"completed held instruction changed");
   hold_checks=hold_checks+1;
  end
  consume=1;@(posedge clk);#1;
  if(pc0!=64'h80000016||len0!=2||raw0!=1)
   $fatal(1,"partial cross-packet consume duplicated borrowed prefix");
  @(negedge clk);consume=0;redirect=1;
  @(negedge clk);redirect=0;
  if(valid!=0||dut.work_count_q!=0||dut.count_q!=0)$fatal(1,"cancelled parse owner resurrected");
  packet(64'ha000000e,first_packet,0);
  repeat(4)@(negedge clk);
  mask=8'b10;
  packet(64'ha0000010,next_packet,0);
  @(posedge clk);#1;
  if(!valid[0]||!fault0||valid[1]||raw0!=0||len0!=8||cause0!=1||tval0!=64'ha0000012)
   $fatal(1,"successor fault lost exact first bad halfword ownership");
  $display("[PASS] tb_r64_packet_missing no_successor=%0d held=%0d cross_partial=1 redirect_generation=1 exact_tval=1",wait_checks,hold_checks);
  $finish;
 end
endmodule
