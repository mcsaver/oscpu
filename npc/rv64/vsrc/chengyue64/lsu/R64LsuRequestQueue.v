// Fixed physical lanes, each with a front descriptor and one skid descriptor.
// Credit is registered occupancy only; output computation cannot reach upstream
// selection through ready. Kill owns its full canonical tag until removal.
module R64LsuRequestQueue #(parameter DATA_W=157,parameter PREPARED_CANCEL=0,parameter TAG_W=9,parameter ROB_W=5,parameter AGE_W=1)(
 input clk_i,rst_i,flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
 input [1:0] in_fire_i,output [1:0] in_ready_o,
 input [2*TAG_W-1:0] in_tag_i,input [2*DATA_W-1:0] in_data_i,
 input [2*AGE_W-1:0] in_age_i,input [AGE_W-1:0] age_clear_i,output [2*AGE_W-1:0] out_age_o,output reg [AGE_W-1:0] held_age_o,
 output [1:0] out_valid_o,output [1:0] out_occupied_o,input [1:0] out_ready_i,
 output [2*TAG_W-1:0] out_tag_o,output [2*DATA_W-1:0] out_data_o,
 output reg [(1<<ROB_W)-1:0] reuse_block_o,output idle_o
);
 // Select the resident slot before the late cancellation enable. The
 // complete canonical mask remains an independent public/checker input.
 function cancel_selected;
  input [ROB_W-1:0] slot;
  input [(1<<ROB_W)-1:0] candidates,mask;
  input active;
  begin cancel_selected=PREPARED_CANCEL?(active&&candidates[slot]):mask[slot];end
 endfunction
 // Two fixed storage slots per physical lane. New payload writes only a
 // slot which is FREE in Q state, independent of downstream ready or kill.
 // Valid publication still requires the actual in_fire; speculative writes
 // into invalid storage cannot replace a retained transaction.
 reg [1:0] valid_q[0:1],valid_d[0:1];
 reg [1:0] head_q,head_d;
 reg [TAG_W-1:0] tag_q[0:1][0:1];
 // A held descriptor's physical ROB slot is decoded at its data capture edge.
 // Valid masks this unowned projection; no late tag decoder reaches ROB birth.
 reg [(1<<ROB_W)-1:0] rob_slot_q[0:1][0:1];
 reg [DATA_W-1:0] data_q[0:1][0:1];
 reg [AGE_W-1:0] age_q[0:1][0:1];
 wire [1:0] write_slot_w;
 genvar lane,slot;
 generate for(lane=0;lane<2;lane=lane+1)begin:g_lane
  assign write_slot_w[lane]=valid_q[lane][0];
  assign in_ready_o[lane]=!(&valid_q[lane])&&!rst_i&&!flush_i;
  // Q occupancy permits payload preparation only; acceptance still uses out_valid.
  assign out_occupied_o[lane]=valid_q[lane][head_q[lane]];
  assign out_valid_o[lane]=valid_q[lane][head_q[lane]]&&!rst_i&&!flush_i&&
    !cancel_selected(tag_q[lane][head_q[lane]][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i);
  assign out_tag_o[lane*TAG_W+:TAG_W]=tag_q[lane][head_q[lane]];
  assign out_data_o[lane*DATA_W+:DATA_W]=data_q[lane][head_q[lane]];
  assign out_age_o[lane*AGE_W+:AGE_W]=age_q[lane][head_q[lane]];
  for(slot=0;slot<2;slot=slot+1)begin:g_storage
   wire write_w=!valid_q[lane][slot]&&(write_slot_w[lane]==slot);
   always @(posedge clk_i)if(!rst_i)begin
    if(write_w)begin
     tag_q[lane][slot]<=in_tag_i[lane*TAG_W+:TAG_W];
     rob_slot_q[lane][slot]<={{((1<<ROB_W)-1){1'b0}},1'b1}<<
         in_tag_i[lane*TAG_W+:ROB_W];
     data_q[lane][slot]<=in_data_i[lane*DATA_W+:DATA_W];
     age_q[lane][slot]<=in_age_i[lane*AGE_W+:AGE_W]&~age_clear_i;
    end else age_q[lane][slot]<=age_q[lane][slot]&~age_clear_i;
   end
  end
 end endgenerate
 assign idle_o=!(|valid_q[0])&&!(|valid_q[1]);
 integer n,j;
 always @*begin
  reuse_block_o=0;held_age_o=0;head_d=head_q;
  for(n=0;n<2;n=n+1)begin
   valid_d[n]=valid_q[n];
   for(j=0;j<2;j=j+1)begin
    if(valid_q[n][j])begin
     reuse_block_o=reuse_block_o|rob_slot_q[n][j];
     held_age_o=held_age_o|age_q[n][j];
    end
    if(flush_i||cancel_selected(tag_q[n][j][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i))valid_d[n][j]=0;
   end
   if(out_valid_o[n]&&out_ready_i[n])valid_d[n][head_q[n]]=0;
   if(in_fire_i[n])valid_d[n][write_slot_w[n]]=1;
   // New publication cannot influence the next head. Empty Q always writes
   // slot0. Otherwise the surviving old head remains oldest; if it departs,
   // the other physical slot is next, even when that slot is still invalid.
   // A later empty cycle normalizes the head before its new slot0 is visible.
   if(!( |valid_q[n]))head_d[n]=1'b0;
   else if(flush_i||cancel_selected(tag_q[n][head_q[n]][ROB_W-1:0],cancel_candidates_i,kill_mask_i,cancel_active_i)||
           (out_valid_o[n]&&out_ready_i[n]))head_d[n]=!head_q[n];
  end
 end
 always @(posedge clk_i)begin
  if(rst_i)begin valid_q[0]<=0;valid_q[1]<=0;head_q<=0;end
  else begin valid_q[0]<=valid_d[0];valid_q[1]<=valid_d[1];head_q<=head_d;end
 end
`ifdef R64_ASSERT
 generate if(PREPARED_CANCEL)begin:g_cancel_contract
  always @(posedge clk_i)if(!rst_i)
   if(kill_mask_i!==({(1<<ROB_W){cancel_active_i}}&cancel_candidates_i))
    $fatal(1,"LSU request queue prepared cancel differs from canonical mask");
 end endgenerate
 genvar check_lane;
 generate for(check_lane=0;check_lane<2;check_lane=check_lane+1)begin:g_head_equivalence
  wire old_next_head_w=(!valid_d[check_lane][head_q[check_lane]]&&
      valid_d[check_lane][!head_q[check_lane]])?!head_q[check_lane]:head_q[check_lane];
  always @(posedge clk_i)if(!rst_i&&(|valid_d[check_lane])&&head_d[check_lane]!=old_next_head_w)
    $fatal(1,"R64LsuRequestQueue Q-head changed occupied owner order");
 end endgenerate
 reg [(1<<ROB_W)-1:0] reference_reuse_r;
 integer lease_lane,lease_slot;
 always @*begin
  reference_reuse_r=0;
  for(lease_lane=0;lease_lane<2;lease_lane=lease_lane+1)
   for(lease_slot=0;lease_slot<2;lease_slot=lease_slot+1)
    if(valid_q[lease_lane][lease_slot])
     reference_reuse_r[tag_q[lease_lane][lease_slot][ROB_W-1:0]]=1'b1;
 end
 always @(posedge clk_i)if(!rst_i)begin
  if(reuse_block_o!==reference_reuse_r)
   $fatal(1,"LSU descriptor reuse projection changed a held ROB lease");
  if((in_fire_i&~in_ready_o)!=0)$fatal(1,"R64LsuRequestQueue credit violation");
  if(((|valid_q[0])&&!valid_q[0][head_q[0]])||((|valid_q[1])&&!valid_q[1][head_q[1]]))
   $fatal(1,"R64LsuRequestQueue oldest slot is not occupied");
 end
`endif
endmodule
