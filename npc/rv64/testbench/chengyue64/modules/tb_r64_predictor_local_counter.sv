`timescale 1ns/1ps
module tb_r64_predictor_local_counter;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,invalidate=0,recover=0;
 reg [1:0] consume=0,fault=0;
 reg [127:0] pc=0;reg [63:0] inst=0;reg [7:0] length=8'h44;
 wire [127:0] predicted;wire [1:0] taken,divert;
 reg update=0,conditional=0,indirect=0,update_taken=0;
 reg [63:0] upc=0,target=0;
 // Direct numerical/RAS oracle: lookup preparation and confirmation are
 // connected at the same request boundary. The production FE separately tests
 // delayed journal/rollback ownership; this preserves all original 12000 cases.
 wire [341:0] preparation;
 wire [125:0] target_snapshot;
 wire [1:0] target_hit,direction_valid,direction;
 wire [5:0] write_index,post_pointer;
 wire [7:0] post_count;
 wire [1:0] ras_push;
 wire [127:0] return_pc;
 genvar prep_lane;
 generate for(prep_lane=0;prep_lane<2;prep_lane=prep_lane+1)begin:g_prepare
 R64PredictionPrepare prepare(.pc_i(pc[prep_lane*64+:64]),
 .inst_i(inst[prep_lane*32+:32]),.length_i(length[prep_lane*4+:4]),
 .fault_i(fault[prep_lane]),.planned_target_i(64'b0),
 .previous_pc_i(pc[63:0]),.previous_length_i(length[3:0]),
 .preparation_o(preparation[prep_lane*171+:171]));
 end endgenerate
 R64Predictor dut(.clk_i(clk),.rst_i(rst),.invalidate_i(invalidate),.recover_i(recover),
 .rollback_i(1'b0),.confirm_i(consume),.confirm_state_valid_i(2'b11),
 .confirm_push_i(ras_push),.confirm_index_i(write_index),
 .confirm_pointer_i(post_pointer),.confirm_count_i(post_count),
 .confirm_data_i({return_pc[127:65],return_pc[63:1]}),
 .journal_valid_i(4'b0),.journal_index_i(12'b0),.journal_data_i(252'b0),
 .write_index_o(write_index),.post_pointer_o(post_pointer),.post_count_o(post_count),
 .push_o(ras_push),.return_pc_o(return_pc),.planned_match_o(),
 .lookup_pc_i(pc),.lookup_target_o(target_snapshot),.lookup_target_hit_o(target_hit),
 .lookup_direction_valid_o(direction_valid),.lookup_direction_o(direction),
 .target_snapshot_i(target_snapshot),.target_hit_snapshot_i(target_hit),
 .direction_valid_snapshot_i(direction_valid),.direction_snapshot_i(direction),
 .preparation_i(preparation),.planned_target_i(64'b0),
 .consume_i(consume),.pc_i(pc),.inst_i(inst),.length_i(length),.fault_i(fault),
 .next_pc_o(predicted),.taken_o(taken),.divert_o(divert),.update_i(update),.update_pc_i(upc),
 .update_conditional_i(conditional),.update_indirect_i(indirect),.update_taken_i(update_taken),.update_target_i(target));
 wire [5:0] ref_write_index;
 wire [5:0] ref_post_pointer;
 wire [7:0] ref_post_count;
 wire [1:0] ref_ras_push;
 wire [127:0] ref_return_pc;
 wire [125:0] ref_target_snapshot;
 wire [1:0] ref_target_hit;
 wire [1:0] ref_direction_valid;
 wire [1:0] ref_direction;
 wire [127:0] ref_predicted;
 wire [1:0] ref_taken;
 wire [1:0] ref_divert;
 R64PredictorReference reference(.clk_i(clk),.rst_i(rst),.invalidate_i(invalidate),.recover_i(recover),
 .rollback_i(1'b0),.confirm_i(consume),.confirm_state_valid_i(2'b11),
 .confirm_push_i(ras_push),.confirm_index_i(write_index),
 .confirm_pointer_i(post_pointer),.confirm_count_i(post_count),
 .confirm_data_i({return_pc[127:65],return_pc[63:1]}),
 .journal_valid_i(4'b0),.journal_index_i(12'b0),.journal_data_i(252'b0),
 .write_index_o(ref_write_index),.post_pointer_o(ref_post_pointer),.post_count_o(ref_post_count),
 .push_o(ref_ras_push),.return_pc_o(ref_return_pc),.planned_match_o(),
 .lookup_pc_i(pc),.lookup_target_o(ref_target_snapshot),.lookup_target_hit_o(ref_target_hit),
 .lookup_direction_valid_o(ref_direction_valid),.lookup_direction_o(ref_direction),
 .target_snapshot_i(target_snapshot),.target_hit_snapshot_i(target_hit),
 .direction_valid_snapshot_i(direction_valid),.direction_snapshot_i(direction),
 .preparation_i(preparation),.planned_target_i(64'b0),
 .consume_i(consume),.pc_i(pc),.inst_i(inst),.length_i(length),.fault_i(fault),
 .next_pc_o(ref_predicted),.taken_o(ref_taken),.divert_o(ref_divert),.update_i(update),.update_pc_i(upc),
 .update_conditional_i(conditional),.update_indirect_i(indirect),.update_taken_i(update_taken),.update_target_i(target));

 integer cycles=0,checks=0,i,j,k,same_edge=0,clears=0;
 reg [31:0] random_q=32'h615abe21;
 reg [1:0] model[0:255];reg [255:0] model_valid=0;
 reg [1:0] old_direction,old_valid;reg [125:0] old_target;
 reg [1:0] old_hit;
 function [31:0] rng(input [31:0] x);rng={x[30:0],x[31]^x[21]^x[1]^x[0]};endfunction
 task compare;
 begin
  if(write_index!==ref_write_index||post_pointer!==ref_post_pointer||post_count!==ref_post_count||ras_push!==ref_ras_push||return_pc!==ref_return_pc||target_snapshot!==ref_target_snapshot||target_hit!==ref_target_hit||direction_valid!==ref_direction_valid||direction!==ref_direction||predicted!==ref_predicted||taken!==ref_taken||divert!==ref_divert)$fatal(1,"visible A/B cycles %0d",cycles);
  if(dut.direction_valid_q!==reference.direction_valid_q||dut.direction_valid_q!==model_valid||
     dut.target_valid_q!==reference.target_valid_q)$fatal(1,"valid state");
  for(i=0;i<256;i=i+1)begin
   if(dut.direction_q[i]!==reference.direction_q[i])$fatal(1,"all table A/B row %0d cycle %0d",i,cycles);
   if(model_valid[i]&&dut.direction_q[i]!==model[i])$fatal(1,"independent saturation row %0d cycle %0d",i,cycles);
  end
  for(i=0;i<64;i=i+1)
   if(dut.target_q[i]!==reference.target_q[i]||dut.target_tag_q[i]!==reference.target_tag_q[i])$fatal(1,"indirect state");
  checks=checks+1;
 end endtask
 task tick;
 begin
  #1;if(cycles!=0)compare();old_direction=direction;old_valid=direction_valid;old_target=target_snapshot;old_hit=target_hit;
  @(posedge clk);
  if(direction!==old_direction||direction_valid!==old_valid||target_snapshot!==old_target||target_hit!==old_hit)
    $fatal(1,"same-edge lookup must sample old Q");
  if(update&&conditional&&pc[8:1]==upc[8:1])same_edge=same_edge+1;
  if(rst||invalidate)begin model_valid=0;clears=clears+1;end
  else if(update&&conditional)begin
   if(!model_valid[upc[8:1]])model[upc[8:1]]=update_taken?2'b10:2'b01;
   else if(update_taken&&model[upc[8:1]]!=3)model[upc[8:1]]=model[upc[8:1]]+1'b1;
   else if(!update_taken&&model[upc[8:1]]!=0)model[upc[8:1]]=model[upc[8:1]]-1'b1;
   model_valid[upc[8:1]]=1;
  end
  #1;cycles=cycles+1;compare();@(negedge clk);
 end endtask
 initial begin
  inst={32'h00001463,32'h00001463};tick();rst=0;
  // Every physical row sees invalid initialization, both saturation bounds,
  // all 2-bit transitions, and simultaneous indirect training/colliding reads.
  for(j=0;j<256;j=j+1)begin
   upc=64'h80000000+64'(j*2);pc={upc,upc};update=1;conditional=1;indirect=1;
   target=64'hffff123400000000+64'(j*64);
   for(k=0;k<5;k=k+1)begin update_taken=0;tick();end
   for(k=0;k<5;k=k+1)begin update_taken=1;tick();end
  end
  for(j=0;j<8192;j=j+1)begin
   random_q=rng(random_q);update=random_q[0];conditional=random_q[1];indirect=random_q[2];update_taken=random_q[3];
   upc={32'h80000000,random_q};target={random_q,~random_q};
   pc={upc^64'h10080,upc};invalidate=j%257==256;rst=j%1023==1022;
   recover=random_q[10];fault=random_q[12:11];tick();
  end
  if(same_edge<2560||clears<20)$fatal(1,"coverage");
  $display("[PASS] tb_r64_predictor_local_counter cycles%0d all-table-checks%0d old-Q-collisions%0d clears%0d",cycles,checks,same_edge,clears);
  $finish;
 end
endmodule
