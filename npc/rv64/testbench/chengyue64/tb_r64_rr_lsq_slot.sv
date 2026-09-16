`timescale 1ns/1ps
module tb_r64_rr_lsq_slot;
reg clk=0;always #5 clk=~clk;
reg rst=1,flush=0;reg[31:0] kill=0;
reg[1:0] fire=0,ready=0;wire[1:0] credit,valid;
reg[17:0] tags=0;reg[9:0] slots=0;
wire[17:0] out_tags;wire[9:0] out_slots;wire[5:0] out_class;
reg[511:0] pending=0;reg[4:0] expected_slot[0:511];
integer accepted=0,completed=0,cancelled=0,cycles=0,duals=0,phase=0,steadi=0,steady_dual=0;
R64RegRead #(.PAYLOAD_W(128)) rr(
 .clk(clk),.rst(rst),.flush_i(flush),.kill_mask_i(kill),
 .in_fire_i(fire),.in_ready_o(credit),.in_tag_i(tags),.in_mem_slot_i(slots),
 .in_payload_i(256'b0),.in_class_i({3'd4,3'd4}),.in_gpr_dst_i(12'b0),
 .in_src_preg_i(36'b0),.in_src_fp_i(6'b0),.in_src_used_i(6'b0),
 .wb_write_i(2'b0),.wb_fp_i(2'b0),.wb_preg_i(12'b0),.wb_data_i(128'b0),
 .alu_bypass_valid_i(2'b0),.alu_bypass_preg_i(12'b0),.alu_bypass_data_i(128'b0),
 .out_valid_o(valid),.out_ready_i(ready),.out_tag_o(out_tags),.out_mem_slot_o(out_slots),
 .out_payload_o(),.out_class_o(out_class),.out_operand_o(),.out_gpr_dst_o(),
 .out_alu_control_o(),.out_add_source_o(),.out_shift_amount_o(),.out_branch_imm_o(),.out_branch_control_o());
integer i,tag;
always @(posedge clk)begin
 if(rst)pending=0;
 else begin
  for(i=0;i<512;i=i+1)if(pending[i]&&(flush||kill[i%32]))begin pending[i]=0;cancelled=cancelled+1;end
  for(i=0;i<2;i=i+1)if(valid[i]&&ready[i]&&!flush&&!kill[out_tags[i*9+:5]])begin
   tag=out_tags[i*9+:9];
   if(!pending[tag]||expected_slot[tag]!==out_slots[i*5+:5]||out_class[i*3+:3]!=4)
    $fatal(1,"RR canonical slot/fulltag lost or duplicated phase%0d tag%h slot%h",phase,tag,out_slots[i*5+:5]);
   pending[tag]=0;completed=completed+1;
  end
  for(i=0;i<2;i=i+1)if(fire[i])begin
   tag=tags[i*9+:9];
   if(!credit[i]||pending[tag])$fatal(1,"TB injects illegal RR birth");
   pending[tag]=1;expected_slot[tag]=slots[i*5+:5];accepted=accepted+1;
  end
  if(valid==3&&ready==3&&!flush)duals=duals+1;
  if(phase==4&&steadi>=8&&valid==3&&ready==3)steady_dual=steady_dual+1;
 end
 cycles=cycles+1;
end
task tick;begin @(posedge clk);#1;end endtask
task push;input[8:0] a,b;input[4:0] x,y;begin
 @(negedge clk);fire=3;tags={b,a};slots={y,x};tick;
end endtask
integer before_count;
initial begin
 tick;tick;@(negedge clk);rst=0;
 phase=1;ready=0;
 push(1,2,5,12);push(3,4,6,13);push(5,6,7,14);
 @(negedge clk);fire=0;tick;#1;
 if(credit!=0||rr.terminal_count_q[0]!=2||rr.terminal_count_q[1]!=2)
  $fatal(1,"RR exact six-owner Q capacity changed");
 phase=2;before_count=completed;
 @(negedge clk);ready=2;
 repeat(8)tick;
 if(completed-before_count!=3||!pending[1]||!pending[3]||!pending[5])
  $fatal(1,"younger lane MEM blocked behind independent old ingress");
 // Current kill plus held output must disappear without corrupting the
 // following generation's LSQ slot on the same ROB index.
 @(negedge clk);kill[3]=1;tick;
 @(negedge clk);kill=0;ready=3;repeat(8)tick;
 if(pending!=0)$fatal(1,"RR initial owners did not drain");
 phase=3;ready=0;push(35,36,17,0);
 @(negedge clk);fire=0;repeat(3)tick;
 if(out_tags[0+:9]!=35||out_slots[0+:5]!=17)$fatal(1,"new generation slot mismatch");
 @(negedge clk);flush=1;tick;
 @(negedge clk);flush=0;ready=3;repeat(3)tick;
 if(valid!=0||pending!=0)$fatal(1,"RR flush revived pending MEM");
 phase=4;
 for(steadi=0;steadi<208;steadi=steadi+1)begin
  push(9'(64+2*steadi),9'(65+2*steadi),5'((2*steadi)%18),5'((2*steadi+1)%18));
 end
 @(negedge clk);phase=5;fire=0;repeat(8)tick;
 if(steady_dual!=200||pending!=0||accepted!=completed+cancelled)
  $fatal(1,"RR steady II1/conservation failed dual%0d accepted%0d complete%0d cancelled%0d",steady_dual,accepted,completed,cancelled);
 $display("[PASS] tb_r64_rr_lsq_slot accepted=%0d completed=%0d cancelled=%0d steady200dual=%0d",accepted,completed,cancelled,steady_dual);$finish;
end
endmodule
