// D-side fixed lookup and outcome owners.
module R64DataTranslation #(parameter RESERVED_TERMINAL=0) (
  input clk_i,input rst_i,
  input req_valid_i,output req_ready_o,
  input [3:0] req_protection_i,
  output [3:0] rsp_protection_o,output [64:0] rsp_last_o,
  output[1:0] rsp_pma_class_o,output rsp_pma_fault_o,
  input req_poison_i, // caller ties zero unless ownership predates an invalidation
  input [63:0] req_vaddr_i,input [1:0] req_access_i,
  input [1:0] req_priv_i,input [63:0] req_mstatus_i,input [63:0] req_satp_i,
  input req_ad_update_i,input req_pbmt_enable_i,
  output rsp_valid_o,input rsp_ready_i,
  output [1:0] rsp_priv_o,output [63:0] rsp_paddr_o,output [1:0] rsp_pbmt_o,
  output rsp_needs_ad_o,output rsp_fault_o,output [4:0] rsp_cause_o,
  input invalidate_i,input invalidate_all_vaddr_i,input invalidate_all_asid_i,
  input [26:0] invalidate_vpn_i,input [15:0] invalidate_asid_i,
  output mem_valid_o,input mem_ready_i,
  output mem_compare_or_o,output [55:0] mem_addr_o,
  output [63:0] mem_expected_o,output [63:0] mem_or_mask_o,
  input mem_rsp_valid_i,output mem_rsp_ready_o,
  input [63:0] mem_rdata_i,input mem_error_i,input mem_compare_ok_i
);

 // A fixed lookup context drives TLB. The outcome owns permission resolution,
 // page walking and fill identity independently from the younger lookup.
 localparam [1:0] FACTS=0,WAIT_WALK=1,RETURN=2;
 reg lookup_valid_q,outcome_valid_q;reg[1:0] outcome_state_q;
 reg[63:0] lookup_va_q;reg[43:0] lookup_root_q;reg[15:0] lookup_asid_q;
 reg[3:0] lookup_mode_q,lookup_protection_q;
 reg[1:0] lookup_access_q,lookup_priv_q;
 reg lookup_sum_q,lookup_mxr_q,lookup_ad_q,lookup_pbmt_enable_q,lookup_poison_q;
 reg[63:0] owner_va_q;reg[43:0] owner_root_q;reg[15:0] owner_asid_q;
 reg[3:0] owner_protection_q;reg[1:0] owner_access_q,owner_priv_q;
 reg owner_sum_q,owner_mxr_q,owner_ad_q,owner_pbmt_enable_q,owner_poison_q;
 reg[63:0] outcome_pa_q;reg[64:0] outcome_last_q;
 reg[7:0] outcome_flags_q;reg[1:0] outcome_pbmt_q;
 reg outcome_bare_q,outcome_address_fault_q,outcome_hit_q;
 reg return_fault_q,return_ad_q;reg[4:0] return_cause_q;
 wire tlb_hit_w;wire[55:0]tlb_pa_w;wire[7:0]tlb_flags_w;wire[1:0]tlb_pbmt_w;
 wire walk_ready_w,walk_valid_w,walk_fault_w,walk_ad_w,walk_napot_w,walk_global_w;
 wire[55:0]walk_pa_w,walk_pte_addr_w;wire[63:0]walk_pte_w;
 wire[7:0]walk_flags_w;wire[1:0]walk_pbmt_w,walk_level_w;wire[4:0]walk_cause_w;
 wire lookup_bare_w=lookup_priv_q==3||lookup_mode_q==0;
 wire lookup_address_fault_w=!lookup_bare_w&&
   (lookup_mode_q!=8||lookup_va_q[63:39]!={25{lookup_va_q[38]}});
 wire owner_user_ok_w=owner_priv_q==0?outcome_flags_q[4]:
   (!outcome_flags_q[4]||(owner_access_q!=0&&owner_sum_q));
 wire owner_op_ok_w=owner_access_q==0?outcome_flags_q[3]:
   (owner_access_q==1?(outcome_flags_q[1]||(owner_mxr_q&&outcome_flags_q[3])):outcome_flags_q[2]);
 wire owner_permission_fault_w=!outcome_flags_q[0]||!owner_user_ok_w||!owner_op_ok_w||
   (!owner_pbmt_enable_q&&outcome_pbmt_q!=0);
 wire owner_needs_ad_w=!outcome_flags_q[6]||(owner_access_q==2&&!outcome_flags_q[7]);
 wire owner_terminal_w=outcome_bare_q||outcome_address_fault_q||
   (outcome_hit_q&&(owner_permission_fault_w||!owner_needs_ad_w||!owner_ad_q));
 wire return_state_w=outcome_state_q==RETURN;
 wire outcome_terminal_fact_w=outcome_valid_q&&
   (return_state_w||(outcome_state_q==FACTS&&owner_terminal_w));
 wire outcome_response_valid_w=outcome_terminal_fact_w&&!rst_i;
 wire outcome_fault_w=return_state_w?return_fault_q:
   (!outcome_bare_q&&(outcome_address_fault_q||owner_permission_fault_w));
 wire outcome_needs_ad_w=return_state_w?(return_ad_q&&!return_fault_q):
   (!outcome_bare_q&&!outcome_address_fault_q&&!owner_permission_fault_w&&owner_needs_ad_w);
 wire[4:0] outcome_cause_w=return_state_w?return_cause_q:
   (owner_access_q==0?5'd12:(owner_access_q==1?5'd13:5'd15));
 wire[1:0] outcome_pma_class_w;wire outcome_pma_fault_w;
 wire[4:0] outcome_size_w=5'b1<<owner_protection_q[1:0];
 R64PmaRange outcome_attributes(.address_i(outcome_pa_q),.last_i(outcome_last_q),
  .size_i(outcome_size_w),.fault_o(outcome_pma_fault_w),.class_o(outcome_pma_class_w));
 wire[146:0] outcome_packet_w={outcome_pma_class_w,outcome_pma_fault_w,outcome_pa_q,outcome_last_q,owner_protection_q,
   owner_priv_q,outcome_pbmt_q,outcome_fault_w,outcome_needs_ad_w,outcome_cause_w};
 wire overflow_valid_q;
 wire[146:0] overflow_packet_q;
 assign rsp_valid_o=!rst_i&&(overflow_valid_q||outcome_response_valid_w);
 assign {rsp_pma_class_o,rsp_pma_fault_o,rsp_paddr_o,rsp_last_o,rsp_protection_o,rsp_priv_o,rsp_pbmt_o,
   rsp_fault_o,rsp_needs_ad_o,rsp_cause_o}=overflow_valid_q?overflow_packet_q:outcome_packet_w;
 // One reserved packet accepts a completed outcome even when range is held.
 // Never borrow its same-cycle dequeue credit: state and payload preparation
 // depend only on Q occupancy. A direct response keeps the hot path unchanged.
 wire outcome_release_w=outcome_response_valid_w&&!overflow_valid_q;
 // Payload may prepare across reset; only original fire/VALID publish owners.
 // Stored terminal facts free the write port without a late reset dependency.
 wire outcome_credit_w=!outcome_valid_q||(outcome_terminal_fact_w&&!overflow_valid_q);
 generate if(RESERVED_TERMINAL)begin:g_reserved_terminal
  // The integrated LSU retains a terminal credit until protected response
  // consumption. Completed outcomes therefore never need overflow storage.
  assign overflow_valid_q=1'b0;
  assign overflow_packet_q=147'b0;
`ifdef R64_ASSERT
  always @(posedge clk_i) if(!rst_i&&rsp_valid_o&&!rsp_ready_i)
   $fatal(1,"R64DataTranslation reserved terminal response backpressured");
`endif
 end else begin:g_backpressured_terminal
  reg valid_q;reg[146:0] packet_q;
  assign overflow_valid_q=valid_q;
  assign overflow_packet_q=packet_q;
  always @(posedge clk_i)begin
   if(rst_i)valid_q<=0;
   else begin
    if(valid_q&&rsp_ready_i)valid_q<=0;
    if(outcome_release_w&&!rsp_ready_i)valid_q<=1;
   end
   if(!valid_q)packet_q<=outcome_packet_w;
  end
 end endgenerate
 wire lookup_credit_w=!lookup_valid_q||outcome_credit_w;
 assign req_ready_o=lookup_credit_w&&!rst_i&&!invalidate_i;
 wire req_fire_w=req_valid_i&&req_ready_o;
 wire lookup_fire_w=lookup_valid_q&&outcome_credit_w&&!rst_i;
 wire walk_request_w=outcome_valid_q&&outcome_state_q==FACTS&&!owner_terminal_w&&!rst_i;
 wire walk_fire_w=walk_request_w&&walk_ready_w;
 wire walk_take_w=outcome_valid_q&&outcome_state_q==WAIT_WALK&&walk_valid_w&&!rst_i;
 wire[11:0] lookup_delta_w=(12'b1<<lookup_protection_q[1:0])-12'd1;
 wire[12:0] lookup_last_low_w={1'b0,lookup_va_q[11:0]}+{1'b0,lookup_delta_w};
 wire[64:0] lookup_bare_last_w;
 assign lookup_bare_last_w[11:0]=lookup_last_low_w[11:0];
 genvar h;
 generate for(h=12;h<64;h=h+1)begin:g_last
  if(h==12)assign lookup_bare_last_w[h]=lookup_va_q[h]^lookup_last_low_w[12];
  else assign lookup_bare_last_w[h]=lookup_va_q[h]^(lookup_last_low_w[12]&&(&lookup_va_q[h-1:12]));
 end endgenerate
 assign lookup_bare_last_w[64]=lookup_last_low_w[12]&&(&lookup_va_q[63:12]);
 wire[12:0] owner_last_low_w={1'b0,owner_va_q[11:0]}+
   ((13'b1<<owner_protection_q[1:0])-13'd1);

 R64Tlb u_tlb(
  .clk_i(clk_i),.rst_i(rst_i),.vaddr_i(lookup_va_q),.asid_i(lookup_asid_q),
  .hit_o(tlb_hit_w),.paddr_o(tlb_pa_w),.flags_o(tlb_flags_w),.pbmt_o(tlb_pbmt_w),
  .fill_i(walk_take_w&&!walk_fault_w&&!owner_poison_q&&!invalidate_i),
  .fill_vpn_i(owner_va_q[38:12]),.fill_ppn_i(walk_pte_w[53:10]),.fill_asid_i(owner_asid_q),
  .fill_global_i(walk_global_w),.fill_level_i(walk_level_w),.fill_napot_i(walk_napot_w),
  .fill_flags_i(walk_flags_w),.fill_pbmt_i(walk_pbmt_w),
  .invalidate_i(invalidate_i),.invalidate_all_vaddr_i(invalidate_all_vaddr_i),
  .invalidate_all_asid_i(invalidate_all_asid_i),.invalidate_vpn_i(invalidate_vpn_i),
  .invalidate_asid_i(invalidate_asid_i));
 R64PageWalk u_walk(
  .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(walk_request_w),.req_ready_o(walk_ready_w),
  .req_vaddr_i(owner_va_q),.req_root_ppn_i(owner_root_q),.req_access_i(owner_access_q),
  .req_priv_i(owner_priv_q),.req_sum_i(owner_sum_q),.req_mxr_i(owner_mxr_q),
  .req_ad_update_i(owner_ad_q),.req_pbmt_enable_i(owner_pbmt_enable_q),
  .rsp_valid_o(walk_valid_w),.rsp_ready_i(outcome_valid_q&&outcome_state_q==WAIT_WALK&&!rst_i),
  .rsp_paddr_o(walk_pa_w),.rsp_flags_o(walk_flags_w),.rsp_pbmt_o(walk_pbmt_w),
  .rsp_level_o(walk_level_w),.rsp_napot_o(walk_napot_w),.rsp_global_o(walk_global_w),
  .rsp_needs_ad_o(walk_ad_w),.rsp_fault_o(walk_fault_w),.rsp_cause_o(walk_cause_w),
  .rsp_pte_addr_o(walk_pte_addr_w),.rsp_pte_o(walk_pte_w),
  .mem_valid_o(mem_valid_o),.mem_ready_i(mem_ready_i),.mem_compare_or_o(mem_compare_or_o),
  .mem_addr_o(mem_addr_o),.mem_expected_o(mem_expected_o),.mem_or_mask_o(mem_or_mask_o),
  .mem_rsp_valid_i(mem_rsp_valid_i),.mem_rsp_ready_o(mem_rsp_ready_o),.mem_rdata_i(mem_rdata_i),
  .mem_error_i(mem_error_i),.mem_compare_ok_i(mem_compare_ok_i));

 always @(posedge clk_i)begin
  if(rst_i)begin lookup_valid_q<=0;outcome_valid_q<=0;outcome_state_q<=FACTS;end
  else begin
   if(lookup_fire_w)lookup_valid_q<=0;
   if(req_fire_w)lookup_valid_q<=1;
   if(outcome_release_w)begin outcome_valid_q<=0;outcome_state_q<=FACTS;end
   if(walk_fire_w)outcome_state_q<=WAIT_WALK;
   if(walk_take_w)outcome_state_q<=RETURN;
   if(lookup_fire_w)begin outcome_valid_q<=1;outcome_state_q<=FACTS;end
  end
  // Input preparation depends on the next stage's stored facts, never on
  // the current TLB matching or terminal decision.
  if(lookup_credit_w)begin
   lookup_va_q<=req_vaddr_i;lookup_root_q<=req_satp_i[43:0];
   lookup_asid_q<=req_satp_i[59:44];lookup_mode_q<=req_satp_i[63:60];
   lookup_access_q<=req_access_i;lookup_priv_q<=req_access_i!=0&&req_priv_i==3&&req_mstatus_i[17]?
     req_mstatus_i[12:11]:req_priv_i;
   lookup_sum_q<=req_mstatus_i[18];lookup_mxr_q<=req_mstatus_i[19];
   lookup_ad_q<=req_ad_update_i;lookup_pbmt_enable_q<=req_pbmt_enable_i;
   lookup_protection_q<=req_protection_i;lookup_poison_q<=req_poison_i;
  end else if(invalidate_i)lookup_poison_q<=1;
  // A free/consumed outcome prepares one complete source snapshot. VALID is
  // published only by lookup_fire. A simultaneous invalidate follows that owner.
  if(outcome_credit_w)begin
   owner_va_q<=lookup_va_q;owner_root_q<=lookup_root_q;owner_asid_q<=lookup_asid_q;
   owner_access_q<=lookup_access_q;owner_priv_q<=lookup_priv_q;
   owner_sum_q<=lookup_sum_q;owner_mxr_q<=lookup_mxr_q;owner_ad_q<=lookup_ad_q;
   owner_pbmt_enable_q<=lookup_pbmt_enable_q;owner_protection_q<=lookup_protection_q;
   owner_poison_q<=lookup_poison_q||invalidate_i;
   outcome_pa_q<=lookup_bare_w?lookup_va_q:{8'b0,tlb_pa_w};
   outcome_last_q<=lookup_bare_w?lookup_bare_last_w:{9'b0,tlb_pa_w[55:12],lookup_last_low_w[11:0]};
   outcome_flags_q<=tlb_flags_w;outcome_pbmt_q<=lookup_bare_w?2'b0:tlb_pbmt_w;
   outcome_bare_q<=lookup_bare_w;outcome_address_fault_q<=lookup_address_fault_w;
   outcome_hit_q<=tlb_hit_w&&!invalidate_i;
  end else if(invalidate_i)owner_poison_q<=1;
  // Walker return updates this same outcome owner. It cannot overlap a
  // younger lookup transfer, and does not allocate another response owner.
  // WAIT owns no valid response. Prepare its final data while waiting, but
  // publish RETURN only on the unchanged actual walk_take handshake above.
  if(outcome_valid_q&&outcome_state_q==WAIT_WALK)begin
   outcome_pa_q<={8'b0,walk_pa_w};outcome_last_q<={9'b0,walk_pa_w[55:12],owner_last_low_w[11:0]};
   outcome_pbmt_q<=walk_pbmt_w;return_fault_q<=walk_fault_w;
   return_ad_q<=walk_ad_w;return_cause_q<=walk_cause_w;
  end
 end
 wire unused_status_w=|{req_mstatus_i[63:20],req_mstatus_i[16:13],req_mstatus_i[10:0]};
 wire unused_walk_w=|{walk_pte_addr_w,walk_pte_w[63:54],walk_pte_w[9:0]};
 wire unused_global_w=outcome_flags_q[5];
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i)begin
  if(req_fire_w&&req_access_i==3)$fatal(1,"invalid translation access");
  if((walk_fire_w||walk_take_w)&&(!outcome_valid_q||lookup_fire_w||outcome_release_w))
   $fatal(1,"R64DataTranslation walker owner overlapped release");
  if(outcome_state_q!=FACTS&&!outcome_valid_q)$fatal(1,"R64DataTranslation outcome state lacks owner");
  if(rsp_valid_o&&!rsp_fault_o&&rsp_last_o!==({1'b0,rsp_paddr_o}+(65'b1<<rsp_protection_o[1:0])-65'd1))
   $fatal(1,"R64DataTranslation crossed page without LSU rejection");
 end
`endif
endmodule
