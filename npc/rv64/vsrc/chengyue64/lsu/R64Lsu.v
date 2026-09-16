`include "R64Uop.vh"
// Eighteen tagged memory owners cover the registered cache hit pipeline. Admission follows backend memory age order;
// address/permission preparation is speculative, physical side effects are not.
// Translation and physical request holders retain cancelled owners until their
// corresponding ordered/tagged response drains, preventing finite ROB-tag ABA.
module R64Lsu #(parameter EARLY_STORE=1,parameter HEAD_AUTHORIZED_QUERY=0,parameter PREPARED_CANCEL=0,parameter ENTRIES=18,parameter INDEX_W=5,parameter TAG_W=9,parameter ROB_W=5)(
 input clk_i,input rst_i,input flush_i,input [(1<<ROB_W)-1:0] kill_mask_i,
 input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
 input [2:0] trigger_enable_i,input [63:0] trigger_address_i,
 input head_valid_i,input [TAG_W-1:0] head_tag_i,input effect_allow_i,input fp_enable_i,input translate_active_i,
 output store_done_valid_o,input store_done_ready_i,
 output [TAG_W-1:0] store_done_tag_o,output store_done_error_o,output [63:0] store_done_tval_o,
 input mem_store_rsp_valid_i,output mem_store_rsp_ready_o,
 input [INDEX_W-1:0] mem_store_rsp_token_i,input mem_store_rsp_error_i,
 output [1:0] mem_fast_store_o,
 input [1:0] commit_fire_i,input [2*TAG_W-1:0] commit_tag_i,
 input [1:0] reserve_want_i,reserve_fire_i,output [1:0] reserve_ready_o,
 output [2*INDEX_W-1:0] reserve_slot_o,input [2*TAG_W-1:0] reserve_tag_i,
 input [15:0] reserve_func_i,input [9:0] reserve_amo_i,
 input [1:0] in_fire_i,output [1:0] in_ready_o,input [2*INDEX_W-1:0] in_slot_i,
 input [2*TAG_W-1:0] in_tag_i,input [2*`R64_UOP_W-1:0] in_uop_i,input [383:0] in_operand_i,
 output [1:0] out_valid_o,output [1:0] out_request_o,input [1:0] out_ready_i,
 output [2*TAG_W-1:0] out_tag_o,output [2*`R64_RESULT_W-1:0] out_result_o,
 output [(1<<ROB_W)-1:0] reuse_block_o,output irrevocable_o,output idle_o,output drain_idle_o,
 output [1:0] tr_valid_o,input [1:0] tr_ready_i,output [127:0] tr_vaddr_o,
 output [3:0] tr_access_o,output [1:0] tr_ad_update_o,
 input [1:0] tr_rsp_valid_i,output [1:0] tr_rsp_ready_o,
 input [127:0] tr_paddr_i,input [3:0] tr_class_i,
 input [1:0] tr_fault_i,tr_needs_ad_i,input [9:0] tr_cause_i,
 output [7:0] tr_request_protection_o,
 output [5:0] tr_owner_access_o,output [9:0] tr_owner_size_o,
 output [1:0] mem_valid_o,input [1:0] mem_ready_i,
 output [2*INDEX_W-1:0] mem_token_o,output [127:0] mem_addr_o,mem_data_o,
 output [3:0] mem_op_o,output [1:0] mem_cache_o,output [5:0] mem_size_o,
 output [15:0] mem_strb_o,output [9:0] mem_amo_o,
 input [1:0] mem_rsp_valid_i,output [1:0] mem_rsp_ready_o,
 input [2*INDEX_W-1:0] mem_rsp_token_i,input [127:0] mem_rsp_data_i,
 input [1:0] mem_rsp_error_i,input [5:0] mem_rsp_offset_i
);
 localparam FREE=0,NEW=1,TRANSLATING=2,READY=3,MEMORY=4,DONE=5,PINNED=6,RETIRE=7;
 localparam U=`R64_UOP_W,R=`R64_RESULT_W;
 localparam DESC_W=INDEX_W+152,DP=INDEX_W,DD=INDEX_W+64,DF=INDEX_W+128,
   DM=INDEX_W+136,DA=INDEX_W+144,DC=INDEX_W+149,DI=INDEX_W+151;
 reg [2:0] state_q[0:ENTRIES-1];
 reg [ENTRIES-1:0] bound_q;
 reg [ENTRIES-1:0] alive_q,tr_issued_q,mem_issued_q,needs_ad_q,effect_q,misaligned_q;
 reg [TAG_W-1:0] tag_q[0:ENTRIES-1];
 reg [63:0] va_q[0:ENTRIES-1],pa_q[0:ENTRIES-1],store_q[0:ENTRIES-1];
 reg [7:0] func_q[0:ENTRIES-1],mask_q[0:ENTRIES-1];
 reg [4:0] amo_q[0:ENTRIES-1];
 reg [1:0] class_q[0:ENTRIES-1];
 reg [5:0] cause_q[0:ENTRIES-1];
 reg [63:0] forward_q[0:ENTRIES-1];
 reg [7:0] forward_mask_q[0:ENTRIES-1];
 wire [ENTRIES-1:0] killed_w,live_entry_w,older_barrier_w,older_ordering_w,issue_barrier_ok_w;
 wire [ENTRIES-1:0] reserve_mask_w[0:1],bind_mask_w[0:1];
 wire [1:0] reserve_take_w,bind_take_w;
 wire [INDEX_W-1:0] bind_slot_w[0:1];
 assign reserve_ready_o[0]=!reserve_want_i[0]||allocation_valid_w[0];
 assign reserve_ready_o[1]=!reserve_want_i[1]||
   (reserve_want_i[0]?allocation_valid_w[1]:allocation_valid_w[0]);
 assign reserve_slot_o[0+:INDEX_W]=allocation_slots_w[0+:INDEX_W];
 assign reserve_slot_o[INDEX_W+:INDEX_W]=reserve_want_i[0]?
   allocation_slots_w[INDEX_W+:INDEX_W]:allocation_slots_w[0+:INDEX_W];
 assign reserve_take_w[0]=reserve_fire_i[0]&&reserve_want_i[0]&&reserve_ready_o[0]&&
   !rst_i&&!flush_i&&!kill_mask_i[reserve_tag_i[0+:ROB_W]];
 assign reserve_take_w[1]=reserve_fire_i[1]&&reserve_want_i[1]&&reserve_ready_o[1]&&
   !rst_i&&!flush_i&&!kill_mask_i[reserve_tag_i[TAG_W+:ROB_W]];
 assign reserve_mask_w[0]=allocation_first_mask_w&{ENTRIES{reserve_take_w[0]}};
 assign reserve_mask_w[1]=(reserve_want_i[0]?allocation_second_mask_w:allocation_first_mask_w)&
   {ENTRIES{reserve_take_w[1]}};
 assign bind_slot_w[0]=in_slot_i[0+:INDEX_W];
 assign bind_slot_w[1]=in_slot_i[INDEX_W+:INDEX_W];
 assign bind_take_w={|bind_mask_w[1],|bind_mask_w[0]};
 // Each row was reserved at dispatch. A cancelled old bind drains without
 // mutation; a live bind does not depend on FREE or downstream capacity.
 assign in_ready_o=2'b11;
 reg [ENTRIES-1:0] prior_barrier_q;
 always @(posedge clk_i)begin
   if(rst_i)prior_barrier_q<=0;
   else prior_barrier_q<=older_barrier_w;
 end
 reg [ENTRIES-1:0] older_q[0:ENTRIES-1];
 wire [ENTRIES*ENTRIES-1:0] older_relations_w,younger_relations_w;
`ifdef R64_ASSERT
 wire [ROB_W-1:0] age_w[0:ENTRIES-1];
`endif
 wire [ENTRIES-1:0] store_w,atomic_w,head_w,side_effect_w;
 genvar g,z,other;
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_entry
   assign live_entry_w[g]=alive_q[g]&&state_q[g]!=FREE;
   assign older_relations_w[g*ENTRIES+:ENTRIES]=older_q[g];
   for(other=0;other<ENTRIES;other=other+1)begin:gen_reverse_order
     assign younger_relations_w[g*ENTRIES+other]=older_q[other][g];
   end
   assign older_barrier_w[g]=|(older_q[g]&barrier_w);
   assign older_ordering_w[g]=|(older_q[g]&ordering_w);
   assign issue_barrier_ok_w[g]=side_effect_w[g]||misaligned_q[g]||!older_barrier_w[g];
   assign killed_w[g]=flush_i||kill_mask_i[tag_q[g][ROB_W-1:0]];
`ifdef R64_ASSERT
   assign age_w[g]=tag_q[g][ROB_W-1:0]-head_tag_i[ROB_W-1:0];
`endif
   assign atomic_w[g]=func_q[g][7];
   assign store_w[g]=atomic_w[g]?(amo_q[g]!=2):func_q[g][5];
   assign head_w[g]=head_valid_i&&tag_q[g]==head_tag_i;
   assign side_effect_w[g]=store_w[g]||atomic_w[g]||class_q[g]==2;
 end endgenerate
 function [7:0] byte_mask;
   input [1:0] size;input [2:0] offset;
   begin case(size)
     0:byte_mask=8'h01<<offset;1:byte_mask=8'h03<<offset;
     2:byte_mask=8'h0f<<offset;default:byte_mask=8'hff;
   endcase end
 endfunction
 function [63:0] load_value;
   input [63:0] data;input [4:0] fn;input [4:0] amo;input [2:0] offset;
   reg [63:0] shifted;
   begin
     shifted=data>>{offset,3'b0};
     if(fn[4]&&amo==3)load_value=data;
     else if(fn[3]&&!fn[4])load_value=fn[1:0]==2?{32'hffffffff,shifted[31:0]}:shifted;
     else case(fn[2:0])
       0:load_value={{56{shifted[7]}},shifted[7:0]};
       1:load_value={{48{shifted[15]}},shifted[15:0]};
       2:load_value={{32{shifted[31]}},shifted[31:0]};
       4:load_value={56'b0,shifted[7:0]};
       5:load_value={48'b0,shifted[15:0]};
       6:load_value={32'b0,shifted[31:0]};
       default:load_value=shifted;
     endcase
   end
 endfunction
 // Match saved VA/operation metadata in two fixed admission check lanes.
 // Disabled memory triggers bypass this check; active checks complete before
 // either NEW translation selection or local fault completion may proceed.
 wire unused_trigger_execute=trigger_enable_i[2];
 function trigger_match;
   input [63:0] address;input [1:0] fn;input [4:0] amo;
   begin trigger_match=address==trigger_address_i&&
     ((trigger_enable_i[0]&&(fn[1]?(amo!=3):!fn[0]))||
      (trigger_enable_i[1]&&(fn[1]?(amo!=2):fn[0])));end
 endfunction
 reg [ENTRIES-1:0] checked_q,admission_check_mask_q[0:1];
 wire trigger_active_w=|trigger_enable_i[1:0];
 wire [ENTRIES*77-1:0] check_rows_w;
 wire [153:0] check_data_w;
 wire [5:0] checked_cause_w[0:1];
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_check_row
   assign check_rows_w[g*77+:77]={va_q[g],func_q[g][7],func_q[g][5],amo_q[g],cause_q[g]};
 end
 for(g=0;g<2;g=g+1)begin:gen_check_read
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(77)) read_check(
     .select_i(admission_check_mask_q[g]),.data_i(check_rows_w),.data_o(check_data_w[g*77+:77]));
   assign checked_cause_w[g]=check_data_w[g*77+:6]==2?6'd2:
     (trigger_match(check_data_w[g*77+13+:64],check_data_w[g*77+11+:2],check_data_w[g*77+6+:5])?
       6'd3:check_data_w[g*77+:6]);
 end endgenerate
 always @(posedge clk_i)begin
   if(rst_i)begin admission_check_mask_q[0]<=0;admission_check_mask_q[1]<=0;end
   else begin
     admission_check_mask_q[0]<=bind_mask_w[0]&{ENTRIES{trigger_active_w}};
     admission_check_mask_q[1]<=bind_mask_w[1]&{ENTRIES{trigger_active_w}};
   end
 end
 reg [1:0] mvalid_q;
 wire [1:0] xvalid_q,xad_q;
 wire [TAG_W-1:0] xtag_q[0:1];reg [TAG_W-1:0] mtag_q[0:1];
 wire [1:0] xkilled_w,mkilled_w;
 wire prepared_killed_w=flush_i||kill_mask_i[prepared_tag_q[ROB_W-1:0]];
 reg prepared_valid_q,prepared_payload_valid_q;reg [DESC_W-1:0] prepared_payload_q;reg [INDEX_W-1:0] prepared_slot_q;reg [TAG_W-1:0] prepared_tag_q;
 wire unused_prepared_select_w,early_prepare_select_w;wire [INDEX_W-1:0] unused_prepared_choice_w,early_prepare_choice_w;
 reg store_done_q,store_error_q;reg [TAG_W-1:0] store_tag_q;reg [63:0] store_tval_q;
 wire [INDEX_W-1:0] physical_slot_w[0:1];
 // One physical descriptor per lane decouples winner capture from Service.
 // Empty storage is bypassed, preserving the no-backpressure request latency.
 reg [1:0] physical_hold_valid_q;
 reg [DESC_W-1:0] physical_hold_data_q[0:1];
 reg [TAG_W-1:0] physical_hold_tag_q[0:1];
 wire [DESC_W-1:0] physical_desc_w[0:1];
 wire [TAG_W-1:0] physical_tag_w[0:1];
 wire [1:0] physical_offer_w,physical_hold_killed_w;
 reg [(1<<ROB_W)-1:0] physical_hold_reuse_w;
 integer ph;
 always @*begin
   physical_hold_reuse_w=0;
   for(ph=0;ph<2;ph=ph+1)if(physical_hold_valid_q[ph])
     physical_hold_reuse_w[physical_hold_tag_q[ph][ROB_W-1:0]]=1;
 end

 wire prepared_offer_w=prepared_valid_q&&prepared_payload_valid_q&&!prepared_killed_w&&head_valid_i&&prepared_tag_q==head_tag_i&&effect_allow_i;
 wire [1:0] descriptor_credit_w,descriptor_valid_w,descriptor_pop_w,descriptor_s_take_w,descriptor_tr_take_w;
 wire [2*TAG_W-1:0] descriptor_in_tag_w;
 wire [2*DESC_W-1:0] descriptor_in_data_w;
 localparam LOAD_DESC_W=DESC_W-64;
 wire [2*LOAD_DESC_W-1:0] load_descriptor_in_w,load_descriptor_out_w;
 wire [2*TAG_W-1:0] descriptor_tag_w;
 wire [2*ENTRIES-1:0] descriptor_in_age_w;
 wire [2*ENTRIES-1:0] descriptor_age_w;
 wire [ENTRIES-1:0] source_birth_w,unused_descriptor_held_age_w;
 wire [2*DESC_W-1:0] descriptor_data_w;
 wire [(1<<ROB_W)-1:0] descriptor_reuse_w;
 wire descriptor_idle_w;
 wire [63:0] physical_pa_w[0:1];
 wire [7:0] physical_func_w[0:1],physical_mask_w[0:1];
 wire [4:0] physical_amo_w[0:1];
 wire [1:0] physical_class_w[0:1];
 wire [1:0] physical_misaligned_w,physical_atomic_w,physical_store_w,physical_side_effect_w;
 wire [INDEX_W-1:0] probe_slot_w[0:1];
 wire [63:0] probe_pa_w[0:1];
 wire [7:0] probe_func_w[0:1],probe_mask_w[0:1];
 wire [4:0] probe_amo_w[0:1];
 wire [1:0] probe_class_w[0:1];
 wire [1:0] probe_misaligned_w,probe_atomic_w,probe_store_w,probe_side_effect_w;
 wire [1:0] descriptor_queue_fire_w;
 assign descriptor_queue_fire_w=descriptor_s_take_w;
 wire prepared_take_w=prepared_offer_w&&query_credit_w[0]&&!rst_i&&!flush_i;
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.DATA_W(LOAD_DESC_W),.TAG_W(TAG_W),.ROB_W(ROB_W),.AGE_W(ENTRIES)) request_queue(
   .out_occupied_o(),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_fire_i(descriptor_queue_fire_w),.in_ready_o(descriptor_credit_w),
   .in_age_i(descriptor_in_age_w),.age_clear_i(source_birth_w),.out_age_o(descriptor_age_w),.held_age_o(unused_descriptor_held_age_w),
   .in_tag_i(descriptor_in_tag_w),.in_data_i(load_descriptor_in_w),
   .out_valid_o(descriptor_valid_w),.out_ready_i(descriptor_pop_w),
   .out_tag_o(descriptor_tag_w),.out_data_o(load_descriptor_out_w),
   .reuse_block_o(descriptor_reuse_w),.idle_o(descriptor_idle_w));
 assign store_done_valid_o=store_done_q&&!rst_i;
 assign store_done_tag_o=store_tag_q;assign store_done_error_o=store_error_q;assign store_done_tval_o=store_tval_q;
 // A second head store cannot reach B while this head terminal is live.
 // Q-only credit avoids an unnecessary ROB-ready to external-B path.
 assign mem_store_rsp_ready_o=!store_done_q&&!rst_i;
 wire store_response_fire_w=mem_store_rsp_valid_i&&mem_store_rsp_ready_o;
 wire store_response_live_w=alive_q[mem_store_rsp_token_i]&&!killed_w[mem_store_rsp_token_i];
 wire [INDEX_W-1:0] xslot_q[0:1];reg [INDEX_W-1:0] mslot_q[0:1];
 reg [INDEX_W-1:0] xfifo_q[0:1][0:3];
 // Four immutable operation bits follow exactly the translation holder/FIFO
 // owner. Dynamic privilege, FS, trigger and A/D authorization are unchanged.
 wire [3:0] xprotection_q[0:1];reg [3:0] xfifo_protection_q[0:1][0:3];
 reg [1:0] xhead_q[0:1],xtail_q[0:1];
 reg [2:0] xcount_q[0:1];
 wire [INDEX_W-1:0] response_slot_w[0:1];
 wire [1:0] xfire_w,mfire_w,xresponse_w;
 generate for(g=0;g<2;g=g+1)begin:gen_lane
   assign xkilled_w[g]=flush_i||kill_mask_i[xtag_q[g][ROB_W-1:0]];
   assign mkilled_w[g]=flush_i||kill_mask_i[mtag_q[g][ROB_W-1:0]];
   assign tr_valid_o[g]=xvalid_q[g]&&xcount_q[g]<4;
   assign tr_vaddr_o[g*64+:64]=va_q[xslot_q[g]];
   assign tr_request_protection_o[g*4+:4]=xprotection_q[g];
   assign tr_access_o[g*2+:2]=xprotection_q[g][3]?2'd2:2'd1;
   assign tr_ad_update_o[g]=xad_q[g];
   assign xfire_w[g]=tr_valid_o[g]&&tr_ready_i[g];
   assign response_slot_w[g]=xfifo_q[g][xhead_q[g]];
   assign tr_rsp_ready_o[g]=xcount_q[g]!=0&&!rst_i;
   assign xresponse_w[g]=tr_rsp_valid_i[g]&&tr_rsp_ready_o[g];
   assign tr_owner_size_o[g*5+:5]=5'b00001<<xfifo_protection_q[g][xhead_q[g]][1:0];
   assign tr_owner_access_o[g*3+:3]={1'b0,xfifo_protection_q[g][xhead_q[g]][3:2]};
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i&&xcount_q[g]!=0)begin
     if(tr_owner_size_o[g*5+:5]!==(5'b00001<<func_q[response_slot_w[g]][1:0])||
       tr_owner_access_o[g*3+:3]!=={1'b0,store_w[response_slot_w[g]],
         atomic_w[response_slot_w[g]]?(amo_q[response_slot_w[g]]!=3):!func_q[response_slot_w[g]][5]})
       $fatal(1,"R64Lsu translation protection metadata changed owner");
   end
`endif
   assign probe_slot_w[g]=descriptor_data_w[g*DESC_W+:INDEX_W];
   assign probe_pa_w[g]=descriptor_data_w[g*DESC_W+DP+:64];
   assign probe_func_w[g]=descriptor_data_w[g*DESC_W+DF+:8];
   assign probe_mask_w[g]=descriptor_data_w[g*DESC_W+DM+:8];
   assign probe_amo_w[g]=descriptor_data_w[g*DESC_W+DA+:5];
   assign probe_class_w[g]=descriptor_data_w[g*DESC_W+DC+:2];
   assign probe_misaligned_w[g]=descriptor_data_w[g*DESC_W+DI];
   assign probe_atomic_w[g]=probe_func_w[g][7];
   assign probe_store_w[g]=probe_atomic_w[g]?(probe_amo_w[g]!=2):probe_func_w[g][5];
   assign probe_side_effect_w[g]=probe_store_w[g]||probe_atomic_w[g]||probe_class_w[g]==2;
   assign physical_hold_killed_w[g]=flush_i||kill_mask_i[physical_hold_tag_q[g][ROB_W-1:0]];
   assign physical_desc_w[g]=physical_hold_valid_q[g]?physical_hold_data_q[g]:
     query_data_w[g*QUERY_W+QD+:DESC_W];
   assign physical_tag_w[g]=physical_hold_valid_q[g]?physical_hold_tag_q[g]:
     query_tag_w[g*TAG_W+:TAG_W];
   assign physical_offer_w[g]=physical_hold_valid_q[g]?!physical_hold_killed_w[g]:
     (query_valid_w[g]&&!query_full_w[g]);
   always @(posedge clk_i)begin
     if(rst_i)physical_hold_valid_q[g]<=0;
     else begin
       if(mfire_w[g]||physical_hold_killed_w[g])physical_hold_valid_q[g]<=0;
       if(query_take_w[g]&&!query_full_w[g]&&(physical_hold_valid_q[g]||!mfire_w[g]))begin
         physical_hold_valid_q[g]<=1;
         physical_hold_tag_q[g]<=query_tag_w[g*TAG_W+:TAG_W];
         physical_hold_data_q[g]<=query_data_w[g*QUERY_W+QD+:DESC_W];
       end
     end
   end
   assign physical_slot_w[g]=physical_desc_w[g][0+:INDEX_W];
   assign physical_pa_w[g]=physical_desc_w[g][DP+:64];
   assign physical_func_w[g]=physical_desc_w[g][DF+:8];
   assign physical_mask_w[g]=physical_desc_w[g][DM+:8];
   assign physical_amo_w[g]=physical_desc_w[g][DA+:5];
   assign physical_class_w[g]=physical_desc_w[g][DC+:2];
   assign physical_misaligned_w[g]=physical_desc_w[g][DI];
   assign physical_atomic_w[g]=physical_func_w[g][7];
   assign physical_store_w[g]=physical_atomic_w[g]?(physical_amo_w[g]!=2):physical_func_w[g][5];
   assign physical_side_effect_w[g]=physical_store_w[g]||physical_atomic_w[g]||physical_class_w[g]==2;
   // In the closed core a side effect enters this registered query only at
   // the ROB head with effect permission. That head cannot finish or retire
   // before this request is accepted and its response returns. The query owns
   // this authorization; canonical kill/flush still removes the query itself.
   // Standalone callers may revoke head permission, so the generic mode keeps
   // the original live qualification. No payload or handshake stage is added.
   assign mem_valid_o[g]=physical_offer_w[g]&&
     (HEAD_AUTHORIZED_QUERY||!physical_side_effect_w[g]|| (head_valid_i&&physical_tag_w[g]==head_tag_i&&effect_allow_i))&&!rst_i;
`ifdef R64_ASSERT
   if(HEAD_AUTHORIZED_QUERY)begin:g_head_authorization
     wire original_offer_w=physical_offer_w[g]&&
       (!physical_side_effect_w[g]||
        (head_valid_i&&physical_tag_w[g]==head_tag_i&&effect_allow_i))&&!rst_i;
     wire input_atomic_w=query_in_data_w[g*QUERY_W+QD+DF+7];
     wire [4:0] input_amo_w=query_in_data_w[g*QUERY_W+QD+DA+:5];
     wire input_store_w=input_atomic_w?(input_amo_w!=2):query_in_data_w[g*QUERY_W+QD+DF+5];
     wire input_side_effect_w=input_store_w||input_atomic_w||
       query_in_data_w[g*QUERY_W+QD+DC+:2]==2;
     always @(posedge clk_i)if(!rst_i)begin
       if(mem_valid_o[g]!==original_offer_w)
         $fatal(1,"R64Lsu retained query lost canonical head authorization");
       if(query_fire_w[g]&&input_side_effect_w&&
          !(head_valid_i&&query_in_tag_w[g*TAG_W+:TAG_W]==head_tag_i&&effect_allow_i))
         $fatal(1,"R64Lsu side-effect query entered without head authorization");
     end
   end
`endif
   assign mem_token_o[g*INDEX_W+:INDEX_W]=physical_slot_w[g];
   assign mem_addr_o[g*64+:64]=physical_pa_w[g];
   assign mem_data_o[g*64+:64]=physical_desc_w[g][DD+:64];
   assign mem_op_o[g*2+:2]=physical_atomic_w[g]?2'd3:(physical_store_w[g]?2'd1:2'd0);
   assign mem_cache_o[g]=physical_class_w[g]==0;
   assign mem_size_o[g*3+:3]={1'b0,physical_func_w[g][1:0]};
   assign mem_strb_o[g*8+:8]=physical_mask_w[g];
   assign mem_amo_o[g*5+:5]=physical_amo_w[g];
   assign mem_fast_store_o[g]=EARLY_STORE&&physical_store_w[g]&&!physical_atomic_w[g]&&!physical_misaligned_w[g]&&physical_class_w[g]!=2;
   assign descriptor_pop_w[g]=query_from_descriptor_w[g];
   assign mfire_w[g]=mem_valid_o[g]&&mem_ready_i[g];
 end endgenerate


 wire [ENTRIES-1:0] free_w,translation_candidate_w,ad_candidate_w,done_w;
 wire [ENTRIES-1:0] allocation_first_mask_w,allocation_second_mask_w;
 wire [ENTRIES-1:0] trans_owner_select_w[0:1],mem_owner_select_w[0:1];
 wire [ENTRIES*ENTRIES-1:0] allocation_order_w;
 wire [ENTRIES-1:0] barrier_w,ordering_w,load_candidate_w,special_candidate_w,prepare_candidate_w;
 wire [ENTRIES*INDEX_W-1:0] slot_indices_w;
 reg [1:0] trans_select_valid_w,mem_select_valid_w;
 reg [INDEX_W-1:0] trans_slot_w[0:1],memory_slot_w[0:1];
 wire [63:0] selected_forward_w[0:1];
 wire [16*ENTRIES-1:0] selected_winner_w;
 wire [7:0] selected_mask_w[0:1];
 wire [1:0] probe_allowed_w;
 integer i;
 genvar q,bk,by,stidx;
 generate for(q=0;q<ENTRIES;q=q+1)begin:gen_candidates
  localparam integer NUMBER=q;
  assign slot_indices_w[q*INDEX_W+:INDEX_W]=NUMBER[INDEX_W-1:0];
  assign free_w[q]=state_q[q]==FREE;
  assign source_birth_w[q]=reserve_mask_w[0][q]||reserve_mask_w[1][q];
  for(z=0;z<ENTRIES;z=z+1)begin:gen_allocation_order
    assign allocation_order_w[q*ENTRIES+z]=(z<q);
  end
  assign ordering_w[q]=state_q[q]!=FREE&&alive_q[q]&&(misaligned_q[q]||store_w[q]||atomic_w[q]||class_q[q]==2);
  assign translation_candidate_w[q]=alive_q[q]&&bound_q[q]&&checked_q[q]&&state_q[q]==NEW;
  assign ad_candidate_w[q]=alive_q[q]&&state_q[q]==READY&&needs_ad_q[q]&&head_w[q]&&effect_allow_i;
  assign done_w[q]=state_q[q]==DONE&&alive_q[q]&&bound_q[q]&&checked_q[q];
  // A pending D-bit rewalk can change the physical owner. Keep it a barrier
  // before the first load offer, so a stalled valid never needs withdrawal.
  wire ordinary_load_pending_w=!store_w[q]&&!atomic_w[q]&&
    (state_q[q]==NEW||state_q[q]==TRANSLATING);
  wire ordinary_ram_resolved_w=
    (translation_response_mask_w[0][q]&&!tr_fault_i[0]&&!tr_needs_ad_i[0]&&tr_class_i[1:0]<2)||
    (translation_response_mask_w[1][q]&&!tr_fault_i[1]&&!tr_needs_ad_i[1]&&tr_class_i[3:2]<2);
  // A bound ordinary load may still resolve as IO. Its unknown attributes
  // block younger publication, while a protected RAM response can release
  // that barrier on this edge (including two same-cycle RAM responses).
  assign barrier_w[q]=state_q[q]!=FREE&&alive_q[q]&&
    (!bound_q[q]||misaligned_q[q]||atomic_w[q]||class_q[q]==2||
      (ordinary_load_pending_w&&!ordinary_ram_resolved_w)||
      (store_w[q]&&(state_q[q]==NEW||state_q[q]==TRANSLATING||needs_ad_q[q])));
  // The prior-cycle barrier summary is a ranking hint only. A current
  // barrier must still pass at the per-owner issue event, before queue entry.
  assign load_candidate_w[q]=state_q[q]==READY&&alive_q[q]&&!needs_ad_q[q]&&
    !side_effect_w[q]&&!misaligned_q[q]&&!prior_barrier_q[q];
  assign special_candidate_w[q]=state_q[q]==READY&&alive_q[q]&&!needs_ad_q[q]&&
    (side_effect_w[q]||misaligned_q[q])&&head_w[q]&&effect_allow_i;
  assign prepare_candidate_w[q]=EARLY_STORE&&!prepared_valid_q&&state_q[q]==READY&&alive_q[q]&&
    store_w[q]&&!atomic_w[q]&&!misaligned_q[q]&&class_q[q]!=2&&!needs_ad_q[q]&&!head_w[q];
 end endgenerate
 wire [1:0] allocation_valid_w,translation_valid_w,load_valid_w,unused_fault_valid_w;
 wire [2*INDEX_W-1:0] allocation_slots_w,translation_slots_w,load_slots_w,unused_fault_slots_w;
 wire special_valid_w;wire [INDEX_W-1:0] special_slot_w;
 R64LsuOrderSelect #(.N(ENTRIES),.SLOT_W(INDEX_W)) allocation_select(
  .valid_i(free_w),.older_i(allocation_order_w),
  .first_valid_o(allocation_valid_w[0]),.second_valid_o(allocation_valid_w[1]),
  .first_slot_o(allocation_slots_w[0+:INDEX_W]),.second_slot_o(allocation_slots_w[INDEX_W+:INDEX_W]),
  .first_mask_o(allocation_first_mask_w),.second_mask_o(allocation_second_mask_w));
 wire [ENTRIES-1:0] unused_translation_first_mask_w,unused_translation_second_mask_w;
 wire [ENTRIES-1:0] new_first_mask_w,new_second_mask_w;
 wire [1:0] new_valid_w;wire [2*INDEX_W-1:0] new_slots_w;
 wire ad_valid_w=|ad_candidate_w;wire [INDEX_W-1:0] ad_slot_w;
 R64LsuOrderSelect #(.N(ENTRIES),.SLOT_W(INDEX_W)) translation_select(
  .first_mask_o(new_first_mask_w),.second_mask_o(new_second_mask_w),
  .valid_i(translation_candidate_w),.older_i(older_relations_w),
  .first_valid_o(new_valid_w[0]),.second_valid_o(new_valid_w[1]),
  .first_slot_o(new_slots_w[0+:INDEX_W]),.second_slot_o(new_slots_w[INDEX_W+:INDEX_W]));
 // A/D replay is the unique ROB head, older than every NEW owner. It does
 // not need to inject a head comparison into the ordinary translation tree.
 R64LsuMetaRead #(.N(ENTRIES),.DATA_W(INDEX_W)) ad_select(
  .select_i(ad_candidate_w),.data_i(slot_indices_w),.data_o(ad_slot_w));
 assign unused_translation_first_mask_w=ad_valid_w?ad_candidate_w:new_first_mask_w;
 assign unused_translation_second_mask_w=ad_valid_w?new_first_mask_w:new_second_mask_w;
 assign translation_valid_w={ad_valid_w?new_valid_w[0]:new_valid_w[1],ad_valid_w||new_valid_w[0]};
 assign translation_slots_w[0+:INDEX_W]=ad_valid_w?ad_slot_w:new_slots_w[0+:INDEX_W];
 assign translation_slots_w[INDEX_W+:INDEX_W]=ad_valid_w?new_slots_w[0+:INDEX_W]:new_slots_w[INDEX_W+:INDEX_W];
 wire [ENTRIES-1:0] unused_load_first_mask_w,unused_load_second_mask_w;
 R64LsuOrderSelect #(.N(ENTRIES),.SLOT_W(INDEX_W)) load_select(
  .first_mask_o(unused_load_first_mask_w),.second_mask_o(unused_load_second_mask_w),
  .valid_i(load_candidate_w),.older_i(older_relations_w),.first_valid_o(load_valid_w[0]),.second_valid_o(load_valid_w[1]),
  .first_slot_o(load_slots_w[0+:INDEX_W]),.second_slot_o(load_slots_w[INDEX_W+:INDEX_W]));
 // Side effects and split accesses are eligible only for the single ROB
 // head. Their candidate vector is inherently onehot; age arbitration would
 // duplicate the head proof and add an unnecessary N-way order cone.
 assign special_valid_w=|special_candidate_w;
 R64LsuMetaRead #(.N(ENTRIES),.DATA_W(INDEX_W)) special_select(
   .select_i(special_candidate_w),.data_i(slot_indices_w),.data_o(special_slot_w));
 wire [ENTRIES-1:0] unused_fault_first_mask_w,unused_fault_second_mask_w;
 R64LsuOrderSelect #(.N(ENTRIES),.SLOT_W(INDEX_W)) fault_select(
  .first_mask_o(unused_fault_first_mask_w),.second_mask_o(unused_fault_second_mask_w),
  .valid_i(done_w),.older_i(older_relations_w),.first_valid_o(unused_fault_valid_w[0]),.second_valid_o(unused_fault_valid_w[1]),
  .first_slot_o(unused_fault_slots_w[0+:INDEX_W]),.second_slot_o(unused_fault_slots_w[INDEX_W+:INDEX_W]));
 wire unused_prepare_second_valid_w;wire [INDEX_W-1:0] unused_prepare_second_slot_w;
 wire [ENTRIES-1:0] unused_prepare_first_mask_w,unused_prepare_second_mask_w;
 R64LsuOrderSelect #(.N(ENTRIES),.SLOT_W(INDEX_W)) prepare_select(
  .first_mask_o(unused_prepare_first_mask_w),.second_mask_o(unused_prepare_second_mask_w),
  .valid_i(prepare_candidate_w),.older_i(older_relations_w),.first_valid_o(early_prepare_select_w),.first_slot_o(early_prepare_choice_w),
  .second_valid_o(unused_prepare_second_valid_w),.second_slot_o(unused_prepare_second_slot_w));
 // The reserved descriptor is preparation only: its LSQ owner stays READY.
 // A newly resolved older head effect can replace a younger prepared store
 // without cancellation or externally visible action. Ordinary query queues
 // must never block the head descriptor which releases their ordering barrier.
 wire head_prepare_w=special_valid_w&&(!prepared_valid_q||prepared_tag_q!=head_tag_i);
 assign unused_prepared_select_w=head_prepare_w||early_prepare_select_w;
 assign unused_prepared_choice_w=head_prepare_w?special_slot_w:early_prepare_choice_w;
 // Preserve the selected physical owner through cancellation qualification.
 // Do not encode a slot only to re-read its kill bit and full tag.
 wire [ENTRIES-1:0] prepared_raw_mask_w,prepared_capture_mask_w;
 wire prepared_capture_w;wire [TAG_W-1:0] prepared_capture_tag_w;
 wire [INDEX_W-1:0] prepared_capture_slot_w;
 assign prepared_raw_mask_w=head_prepare_w?special_candidate_w:unused_prepare_first_mask_w;
 assign prepared_capture_mask_w=prepared_raw_mask_w&~killed_w;
 assign prepared_capture_w=|prepared_capture_mask_w;
 R64LsuMetaRead #(.N(ENTRIES),.DATA_W(TAG_W)) prepared_identity_read(
   .select_i(prepared_capture_mask_w),.data_i(holder_tag_rows_w),.data_o(prepared_capture_tag_w));
 R64LsuMetaRead #(.N(ENTRIES),.DATA_W(INDEX_W)) prepared_slot_read(
   .select_i(prepared_capture_mask_w),.data_i(slot_indices_w),.data_o(prepared_capture_slot_w));
 // Capture the complete prepared descriptor at the owner-selection edge.
 // Selection reads immutable READY rows in parallel; canonical cancellation
 // qualifies publication only and does not gate the wide payload reduction.
 // Holding or replacing this preparation never authorizes a physical effect.
 wire [ENTRIES*DESC_W-1:0] prepared_rows_w;
 wire [DESC_W-1:0] prepared_selected_payload_w;
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_prepared_rows
   assign prepared_rows_w[g*DESC_W+:DESC_W]=
     {misaligned_q[g],class_q[g],amo_q[g],mask_q[g],func_q[g],
      store_q[g],pa_q[g],INDEX_W'(g)};
 end endgenerate
 R64LsuMetaRead #(.N(ENTRIES),.DATA_W(DESC_W)) prepared_payload_read(
   .select_i(prepared_raw_mask_w),.data_i(prepared_rows_w),
   .data_o(prepared_selected_payload_w));
 // A selected translation owns one of two fixed ingress slots per lane.
 // Occupancy Q alone supplies scheduler credit; TLB/PMP ready cannot select
 // a new holder. The original four-entry accepted FIFO starts only on xfire.
 localparam XREQUEST_W=INDEX_W+5;
 wire [1:0] translation_credit_w,translation_pop_w;
 wire [2*TAG_W-1:0] translation_request_tag_w;
 wire [2*XREQUEST_W-1:0] translation_request_data_w,translation_request_input_w;
 wire [(1<<ROB_W)-1:0] translation_reuse_w;
 wire translation_idle_w;
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.DATA_W(XREQUEST_W),
   .TAG_W(TAG_W),.ROB_W(ROB_W),.AGE_W(1)) translation_queue(
   .out_occupied_o(),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_fire_i(trans_select_valid_w),.in_ready_o(translation_credit_w),
   .in_tag_i(selected_xtag_w),.in_data_i(translation_request_input_w),
   .in_age_i(2'b0),.age_clear_i(1'b0),.out_age_o(),.held_age_o(),
   .out_valid_o(xvalid_q),.out_ready_i(translation_pop_w),
   .out_tag_o(translation_request_tag_w),.out_data_o(translation_request_data_w),
   .reuse_block_o(translation_reuse_w),.idle_o(translation_idle_w));
 generate for(genvar xq=0;xq<2;xq=xq+1)begin:gen_translation_request
   assign translation_request_input_w[xq*XREQUEST_W+:XREQUEST_W]=
     {selected_ad_allowed_w[xq],selected_protection_w[xq*4+:4],trans_slot_w[xq]};
   assign {xad_q[xq],xprotection_q[xq],xslot_q[xq]}=
     translation_request_data_w[xq*XREQUEST_W+:XREQUEST_W];
   assign xtag_q[xq]=translation_request_tag_w[xq*TAG_W+:TAG_W];
   assign translation_pop_w[xq]=tr_ready_i[xq]&&xcount_q[xq]<4;
 end endgenerate
 wire [1:0] trans_available_w,memory_available_w;
 // Translation owns its FIFO slot until the actual response handshake.
 // Decode that owner once, then qualify each row locally. The query queue
 // receives the reduction, while row state never re-decodes that shared event.
 wire [ENTRIES-1:0] translation_response_mask_w[0:1],translation_query_mask_w[0:1];
 generate for(q=0;q<2;q=q+1)begin:gen_holder_credit
  assign trans_available_w[q]=translation_credit_w[q];
  // Scheduler credit stops at the descriptor queue occupancy registers.
  // Neither cache ready nor a forwarding comparison can reach new selection.
  assign descriptor_s_take_w[q]=mvalid_q[q]&&!mkilled_w[q]&&
    descriptor_credit_w[q];
  assign memory_available_w[q]=!mvalid_q[q]||descriptor_credit_w[q];
  assign probe_allowed_w[q]=(probe_side_effect_w[q]||probe_misaligned_w[q])?
    (head_valid_i&&descriptor_tag_w[q*TAG_W+:TAG_W]==head_tag_i&&effect_allow_i):
    !(|(descriptor_age_w[q*ENTRIES+:ENTRIES]&barrier_w));
  wire translation_query_allowed_w=!tr_fault_i[q]&&!tr_needs_ad_i[q]&&tr_class_i[q*2+:2]!=2&&
    !(q==0&&prepared_offer_w)&&!descriptor_valid_w[q]&&query_credit_w[q];
  // Only older ordering owners matter to this ordinary load. Known older
  // stores still require byte forwarding even after their barrier clears.
  // Keep this per-row reduction shared by both response lanes; LR is atomic
  // despite store_w=0 and must retain the head-authorized special path.
  for(z=0;z<ENTRIES;z=z+1)begin:gen_translation_owner_event
    localparam [INDEX_W-1:0] SLOT=z[INDEX_W-1:0];
    assign translation_response_mask_w[q][z]=xresponse_w[q]&&response_slot_w[q]==SLOT;
    assign translation_query_mask_w[q][z]=translation_response_mask_w[q][z]&&
      alive_q[z]&&!killed_w[z]&&!older_barrier_w[z]&&!older_ordering_w[z]&&
      !store_w[z]&&!atomic_w[z]&&!misaligned_q[z]&&translation_query_allowed_w;
  end
  assign descriptor_tr_take_w[q]=|translation_query_mask_w[q];
`ifdef R64_ASSERT
  wire reference_translation_take_w=xresponse_w[q]&&alive_q[response_slot_w[q]]&&!killed_w[response_slot_w[q]]&&
    !tr_fault_i[q]&&!tr_needs_ad_i[q]&&tr_class_i[q*2+:2]!=2&&
    !(|(older_q[response_slot_w[q]]&ordering_w))&&!older_barrier_w[response_slot_w[q]]&&
    !store_w[response_slot_w[q]]&&!atomic_w[response_slot_w[q]]&&!misaligned_q[response_slot_w[q]]&&
    !(q==0&&prepared_offer_w)&&!descriptor_valid_w[q]&&query_credit_w[q];
  always @(posedge clk_i)if(!rst_i)begin
    if(descriptor_tr_take_w[q]!==reference_translation_take_w)
      $fatal(1,"R64Lsu local translation event changed query admission");
    if(translation_query_mask_w[q]!==(({ENTRIES{reference_translation_take_w}})&
      ({{(ENTRIES-1){1'b0}},1'b1}<<response_slot_w[q])))
      $fatal(1,"R64Lsu local translation event changed row ownership");
  end
`endif

 end endgenerate
 wire [ENTRIES*TAG_W-1:0] holder_tag_rows_w;
 wire [ENTRIES*4-1:0] protection_rows_w;wire [7:0] selected_protection_w;
 wire [2*TAG_W-1:0] selected_xtag_w,selected_mtag_w;
 wire [ENTRIES-1:0] ad_allowed_rows_w;
 wire [1:0] selected_ad_allowed_w,ranked_ad_allowed_w;
 wire [7:0] ranked_protection_w;wire [2*TAG_W-1:0] ranked_xtag_w;
 wire second_translation_rank_w=trans_available_w[0]&&translation_valid_w[0];
 assign selected_ad_allowed_w[0]=ranked_ad_allowed_w[0];
 assign selected_ad_allowed_w[1]=second_translation_rank_w?ranked_ad_allowed_w[1]:ranked_ad_allowed_w[0];
 assign selected_protection_w[0+:4]=ranked_protection_w[0+:4];
 assign selected_protection_w[4+:4]=second_translation_rank_w?ranked_protection_w[4+:4]:ranked_protection_w[0+:4];
 assign selected_xtag_w[0+:TAG_W]=ranked_xtag_w[0+:TAG_W];
 assign selected_xtag_w[TAG_W+:TAG_W]=second_translation_rank_w?ranked_xtag_w[TAG_W+:TAG_W]:ranked_xtag_w[0+:TAG_W];
 wire [ENTRIES-1:0] unused_raw_xmask_w[0:1],raw_mmask_w[0:1];
 assign unused_raw_xmask_w[0]=unused_translation_first_mask_w;
 assign unused_raw_xmask_w[1]=(trans_available_w[0]&&translation_valid_w[0])?
   unused_translation_second_mask_w:unused_translation_first_mask_w;
 assign raw_mmask_w[0]=unused_load_first_mask_w;
 assign raw_mmask_w[1]=(memory_available_w[0]&&load_valid_w[0])?
   unused_load_second_mask_w:unused_load_first_mask_w;
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_holder_tag_row
   assign holder_tag_rows_w[g*TAG_W+:TAG_W]=tag_q[g];
   assign protection_rows_w[g*4+:4]={store_w[g],
     atomic_w[g]?(amo_q[g]!=3):!func_q[g][5],func_q[g][1:0]};
   assign ad_allowed_rows_w[g]=!store_w[g]||(head_w[g]&&effect_allow_i);
 end
 for(g=0;g<2;g=g+1)begin:gen_holder_tag_read
   // Read both rank identities before the late lane-credit decision. This
   // keeps holder cancellation out of the N-row tag/access/AD reduction tree.
   wire [ENTRIES-1:0] rank_mask_w=g==0?unused_translation_first_mask_w:unused_translation_second_mask_w;
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(4)) protection_read(
     .select_i(rank_mask_w),.data_i(protection_rows_w),.data_o(ranked_protection_w[g*4+:4]));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(1)) adread(
     .select_i(rank_mask_w),.data_i(ad_allowed_rows_w),.data_o(ranked_ad_allowed_w[g]));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(TAG_W)) xread(
     .select_i(rank_mask_w),.data_i(holder_tag_rows_w),.data_o(ranked_xtag_w[g*TAG_W+:TAG_W]));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(TAG_W)) mread(
     .select_i(raw_mmask_w[g]),.data_i(holder_tag_rows_w),.data_o(selected_mtag_w[g*TAG_W+:TAG_W]));
`ifdef R64_ASSERT
   wire [3:0] previous_protection_w;wire previous_ad_allowed_w;wire [TAG_W-1:0] previous_xtag_w;
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(4)) previous_protection(
     .select_i(unused_raw_xmask_w[g]),.data_i(protection_rows_w),.data_o(previous_protection_w));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(1)) previous_ad(
     .select_i(unused_raw_xmask_w[g]),.data_i(ad_allowed_rows_w),.data_o(previous_ad_allowed_w));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(TAG_W)) previous_tag(
     .select_i(unused_raw_xmask_w[g]),.data_i(holder_tag_rows_w),.data_o(previous_xtag_w));
   always @(posedge clk_i)if(!rst_i)begin
     if({selected_ad_allowed_w[g],selected_protection_w[g*4+:4],selected_xtag_w[g*TAG_W+:TAG_W]}!==
        {previous_ad_allowed_w,previous_protection_w,previous_xtag_w})
       $fatal(1,"R64Lsu ranked translation metadata changed owner");
   end
`endif
 end endgenerate
 // Preserve onehot identity into per-entry state control. Encoding the
 // chosen slot is only for holder payload reads, never for select->kill->decode
 // feedback into the LSQ state array.
 assign trans_owner_select_w[0]=unused_translation_first_mask_w&~killed_w&{ENTRIES{trans_available_w[0]}};
 assign trans_owner_select_w[1]=
   ((trans_available_w[0]&&translation_valid_w[0])?unused_translation_second_mask_w:unused_translation_first_mask_w)&
   ~killed_w&{ENTRIES{trans_available_w[1]}};
 assign mem_owner_select_w[0]=unused_load_first_mask_w&
   ~killed_w&issue_barrier_ok_w&{ENTRIES{memory_available_w[0]}};
 assign mem_owner_select_w[1]=
   ((memory_available_w[0]&&load_valid_w[0])?unused_load_second_mask_w:unused_load_first_mask_w)&
   ~killed_w&issue_barrier_ok_w&{ENTRIES{memory_available_w[1]}};
 always @*begin


  trans_select_valid_w[0]=trans_available_w[0]&&translation_valid_w[0];
  trans_slot_w[0]=translation_slots_w[0+:INDEX_W];
  trans_select_valid_w[1]=trans_available_w[1]&&(trans_select_valid_w[0]?translation_valid_w[1]:translation_valid_w[0]);
  trans_slot_w[1]=trans_select_valid_w[0]?translation_slots_w[INDEX_W+:INDEX_W]:translation_slots_w[0+:INDEX_W];
  mem_select_valid_w[0]=memory_available_w[0]&&load_valid_w[0];
  memory_slot_w[0]=load_slots_w[0+:INDEX_W];
  mem_select_valid_w[1]=memory_available_w[1]&&
    ((mem_select_valid_w[0])?load_valid_w[1]:load_valid_w[0]);
  memory_slot_w[1]=(mem_select_valid_w[0])?load_slots_w[INDEX_W+:INDEX_W]:load_slots_w[0+:INDEX_W];
  trans_select_valid_w[0]=|trans_owner_select_w[0];
  trans_select_valid_w[1]=|trans_owner_select_w[1];
  mem_select_valid_w[0]=|mem_owner_select_w[0];
  mem_select_valid_w[1]=|mem_owner_select_w[1];
 end
 // Decode only the registered holder identity. Payload and age are prepared
 // without take/kill/credit; only descriptor_s_take publishes an owner.
 // Share the onehot decode across balanced metadata reads.
 wire [ENTRIES*88-1:0] descriptor_payload_rows_w;
 wire [ENTRIES*ENTRIES-1:0] descriptor_age_rows_w;
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_descriptor_rows
   assign descriptor_payload_rows_w[g*88+:88]=
     {misaligned_q[g],class_q[g],amo_q[g],mask_q[g],func_q[g],pa_q[g]};
   assign descriptor_age_rows_w[g*ENTRIES+:ENTRIES]=older_q[g];
 end
 for(g=0;g<2;g=g+1)begin:gen_descriptor_payload
   wire [ENTRIES-1:0] owner_w;
   wire [87:0] payload_w;
   for(z=0;z<ENTRIES;z=z+1)begin:gen_owner
     localparam [INDEX_W-1:0] SLOT=z[INDEX_W-1:0];
     assign owner_w[z]=mslot_q[g]==SLOT;
   end
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(88)) read_payload(
     .select_i(owner_w),.data_i(descriptor_payload_rows_w),.data_o(payload_w));
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(ENTRIES)) read_age(
     .select_i(owner_w),.data_i(descriptor_age_rows_w),.data_o(descriptor_in_age_w[g*ENTRIES+:ENTRIES]));
   assign descriptor_in_data_w[g*DESC_W+:DESC_W]={payload_w[87:64],64'b0,payload_w[63:0],mslot_q[g]};
   assign load_descriptor_in_w[g*LOAD_DESC_W+:LOAD_DESC_W]={payload_w,mslot_q[g]};
   assign descriptor_data_w[g*DESC_W+:DESC_W]={
     load_descriptor_out_w[g*LOAD_DESC_W+DD+:24],64'b0,
     load_descriptor_out_w[g*LOAD_DESC_W+:DD]};
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i&&descriptor_queue_fire_w[g]&&
     (side_effect_w[mslot_q[g]]||misaligned_q[mslot_q[g]]))
     $fatal(1,"R64Lsu load-only descriptor received special owner");
`endif
   assign descriptor_in_tag_w[g*TAG_W+:TAG_W]=mtag_q[g];
 end endgenerate
 // Match/youngest selection and source-data read occupy different cycles.
 // Pin source slots until the registered winner has captured its data; a
 // committed source is coherent and no longer irrevocable, but cannot be reused.
 localparam QD=8*ENTRIES,QUERY_W=QD+DESC_W+1,QS=QD,QH=QD+DESC_W;
 localparam QF=QD+DF,QA=QD+DA,QO=QD+DP;
 wire [1:0] query_raw_fast_w;
 wire [1:0] query_fast_w,query_from_descriptor_w,query_needed_w,query_credit_w,query_fire_w,query_valid_w,query_ready_w,query_take_w;
 wire [2*QUERY_W-1:0] query_in_data_w,query_data_w;
 wire [2*DESC_W-1:0] query_fast_data_w;
 wire [2*TAG_W-1:0] query_tag_w,query_in_tag_w;
 wire [2*ENTRIES-1:0] query_in_pin_w,query_front_pin_w;
 wire [ENTRIES-1:0] query_held_pin_w,source_pin_w,eligible_source_w;
 wire [(1<<ROB_W)-1:0] query_reuse_w;
 wire query_idle_w;
 wire [INDEX_W-1:0] query_slot_w[0:1];
 wire [7:0] query_mask_w[0:1];
 wire [1:0] query_full_w,query_occupied_w;
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.DATA_W(QUERY_W),.TAG_W(TAG_W),.ROB_W(ROB_W),.AGE_W(ENTRIES)) forward_query(
   .out_occupied_o(query_occupied_w),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_fire_i(query_fire_w),.in_ready_o(query_credit_w),.in_tag_i(query_in_tag_w),.in_data_i(query_in_data_w),
   .in_age_i(query_in_pin_w),.age_clear_i({ENTRIES{1'b0}}),.out_age_o(query_front_pin_w),.held_age_o(query_held_pin_w),
   .out_valid_o(query_valid_w),.out_ready_i(query_ready_w),.out_tag_o(query_tag_w),.out_data_o(query_data_w),
   .reuse_block_o(query_reuse_w),.idle_o(query_idle_w));
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_source_pin
   assign eligible_source_w[g]=state_q[g]!=FREE&&alive_q[g]&&store_w[g]&&!atomic_w[g]&&
     !misaligned_q[g]&&state_q[g]!=NEW&&state_q[g]!=TRANSLATING;
   assign source_pin_w[g]=query_held_pin_w[g]||
     (descriptor_valid_w[0]&&!probe_side_effect_w[0]&&!probe_misaligned_w[0]&&
       descriptor_age_w[g]&&eligible_source_w[g])||
     (descriptor_valid_w[1]&&!probe_side_effect_w[1]&&!probe_misaligned_w[1]&&
       descriptor_age_w[ENTRIES+g]&&eligible_source_w[g]);
 end
 for(g=0;g<2;g=g+1)begin:gen_query_owner
   assign query_needed_w[g]=!probe_side_effect_w[g]&&!probe_misaligned_w[g]&&
     (|(descriptor_age_w[g*ENTRIES+:ENTRIES]&eligible_source_w));
   // Select the prepared/descriptor/translation payload independently of
   // late translation fault and credit. Publication still uses query_fire.
   // Unowned free storage may prewrite; only query_fire publishes an owner.
   assign query_raw_fast_w[g]=!descriptor_valid_w[g]||(g==0&&prepared_offer_w);
   // The query reads only accessed bytes. Save those winners and pin exactly
   // their union; descriptor-stage protection above remains conservative until
   // this capture edge, including a simultaneous source commit.
   wire [QD-1:0] used_winners_w;
   wire [ENTRIES-1:0] winner_pair_w[0:3];
   wire [ENTRIES-1:0] winner_pin_w;
   for(z=0;z<8;z=z+1)begin:gen_used_winner
     assign used_winners_w[z*ENTRIES+:ENTRIES]=
       selected_winner_w[(g*8+z)*ENTRIES+:ENTRIES]&{ENTRIES{query_needed_w[g]&&probe_mask_w[g][z]}};
   end
   for(z=0;z<4;z=z+1)begin:gen_pin_pair
     assign winner_pair_w[z]=used_winners_w[(2*z)*ENTRIES+:ENTRIES]|
       used_winners_w[(2*z+1)*ENTRIES+:ENTRIES];
   end
   assign winner_pin_w=(winner_pair_w[0]|winner_pair_w[1])|(winner_pair_w[2]|winner_pair_w[3]);
   assign query_in_pin_w[g*ENTRIES+:ENTRIES]=query_raw_fast_w[g]?{ENTRIES{1'b0}}:winner_pin_w;
   // An ordering-free translation and the reserved head descriptor need no
   // store match. The head has ingress priority over ordinary descriptors;
   // Q-only credit guarantees no already-held output is ever replaced.
   assign query_fast_w[g]=descriptor_tr_take_w[g]||(g==0&&prepared_take_w);
   assign query_from_descriptor_w[g]=descriptor_valid_w[g]&&probe_allowed_w[g]&&query_credit_w[g]&&!(g==0&&prepared_offer_w);
   assign query_fire_w[g]=query_fast_w[g]||query_from_descriptor_w[g];
   assign query_in_tag_w[g*TAG_W+:TAG_W]=query_raw_fast_w[g]?
     (g==0&&prepared_offer_w?prepared_tag_q:tag_q[response_slot_w[g]]):descriptor_tag_w[g*TAG_W+:TAG_W];
   assign query_fast_data_w[g*DESC_W+:DESC_W]=(g==0&&prepared_offer_w)?prepared_payload_q:
     {misaligned_q[response_slot_w[g]],tr_class_i[g*2+:2],amo_q[response_slot_w[g]],
      mask_q[response_slot_w[g]],func_q[response_slot_w[g]],store_q[response_slot_w[g]],
      tr_paddr_i[g*64+:64],response_slot_w[g]};
   assign query_in_data_w[g*QUERY_W+:QUERY_W]=query_raw_fast_w[g]?
     {1'b0,query_fast_data_w[g*DESC_W+:DESC_W],{8*ENTRIES{1'b0}}}:
     {full_forward_w[g],
     descriptor_data_w[g*DESC_W+:DESC_W],
     used_winners_w};
`ifdef R64_ASSERT
   wire [TAG_W-1:0] original_query_tag_w=query_fast_w[g]?
     (g==0&&prepared_take_w?prepared_tag_q:tag_q[response_slot_w[g]]):descriptor_tag_w[g*TAG_W+:TAG_W];
   wire [DESC_W-1:0] original_fast_data_w=(g==0&&prepared_take_w)?prepared_payload_q:
     {misaligned_q[response_slot_w[g]],tr_class_i[g*2+:2],amo_q[response_slot_w[g]],
      mask_q[response_slot_w[g]],func_q[response_slot_w[g]],store_q[response_slot_w[g]],
      tr_paddr_i[g*64+:64],response_slot_w[g]};
   wire [QUERY_W-1:0] original_query_data_w=query_fast_w[g]?
     {1'b0,original_fast_data_w,{8*ENTRIES{1'b0}}}:
     {full_forward_w[g],descriptor_data_w[g*DESC_W+:DESC_W],
      selected_winner_w[g*8*ENTRIES+:8*ENTRIES]&{8*ENTRIES{query_needed_w[g]}}};
   // The old descriptor/tag selection is still the reference. Only unused
   // winner bytes and their pins intentionally change.
   reg [QD-1:0] reference_winners_w;
   reg [ENTRIES-1:0] reference_pin_w,held_winner_union_w;
   integer check_byte;
   always @*begin
     reference_winners_w=0;reference_pin_w=0;held_winner_union_w=0;
     for(check_byte=0;check_byte<8;check_byte=check_byte+1)begin
       if(!query_fast_w[g]&&probe_mask_w[g][check_byte])begin
         reference_winners_w[check_byte*ENTRIES+:ENTRIES]=
           original_query_data_w[check_byte*ENTRIES+:ENTRIES];
         reference_pin_w=reference_pin_w|original_query_data_w[check_byte*ENTRIES+:ENTRIES];
       end
       held_winner_union_w=held_winner_union_w|query_data_w[g*QUERY_W+check_byte*ENTRIES+:ENTRIES];
     end
   end
   always @(posedge clk_i)if(!rst_i)begin
     if(query_fire_w[g]&&
        {query_in_tag_w[g*TAG_W+:TAG_W],query_in_data_w[g*QUERY_W+:QUERY_W],query_in_pin_w[g*ENTRIES+:ENTRIES]}!==
        {original_query_tag_w,original_query_data_w[QD+:DESC_W+1],reference_winners_w,reference_pin_w})
       $fatal(1,"R64Lsu raw query selection changed accepted owner payload");
     if(query_valid_w[g]&&query_front_pin_w[g*ENTRIES+:ENTRIES]!==held_winner_union_w)
       $fatal(1,"R64Lsu query pin differs from saved byte references");
     if(query_valid_w[g]&&(held_winner_union_w&~source_pin_w)!=0)
       $fatal(1,"R64Lsu query reads an unprotected store source");
   end
`endif
   assign query_slot_w[g]=query_data_w[g*QUERY_W+QS+:INDEX_W];
   assign query_full_w[g]=query_data_w[g*QUERY_W+QH];
   // Only an occupied physical holder needs same-cycle downstream credit.
   // Its offer depends on its own saved descriptor/tag, never the query that
   // may replace it. Factor that case before the downstream-ready feedback.
   wire held_atomic_w=physical_hold_data_q[g][DF+7];
   wire held_store_w=held_atomic_w?(physical_hold_data_q[g][DA+:5]!=2):physical_hold_data_q[g][DF+5];
   wire held_effect_w=held_store_w||held_atomic_w||physical_hold_data_q[g][DC+:2]==2;
   wire held_offer_w=!physical_hold_killed_w[g]&&!rst_i&&
     (HEAD_AUTHORIZED_QUERY||!held_effect_w||
       (head_valid_i&&physical_hold_tag_q[g]==head_tag_i&&effect_allow_i));
   assign query_ready_w[g]=query_full_w[g]?forward_credit_w[g]:
     (!physical_hold_valid_q[g]||(held_offer_w&&mem_ready_i[g]));
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i)
     if(query_ready_w[g]!==(query_full_w[g]?forward_credit_w[g]:(!physical_hold_valid_q[g]||mfire_w[g])))
       $fatal(1,"R64Lsu held-only ready changed query acceptance");
`endif
   assign query_take_w[g]=query_valid_w[g]&&query_ready_w[g];
   for(z=0;z<8;z=z+1)begin:gen_query_byte
     wire [ENTRIES*8-1:0] byte_rows_w;
     for(other=0;other<ENTRIES;other=other+1)begin:gen_rows
       assign byte_rows_w[other*8+:8]=store_q[other][z*8+:8];
     end
     assign query_mask_w[g][z]=|query_data_w[g*QUERY_W+z*ENTRIES+:ENTRIES];
     R64LsuMetaRead #(.N(ENTRIES),.DATA_W(8)) read_byte(
       .select_i(query_data_w[g*QUERY_W+z*ENTRIES+:ENTRIES]),.data_i(byte_rows_w),
       .data_o(selected_forward_w[g][z*8+:8]));
   end
 end endgenerate
 // A resident query still owns its pinned source bytes. Prepare the row's
 // wide snapshot from Q occupancy; final take only publishes the byte mask and
 // transfers ownership. Once the query departs, no stale head may rewrite it.
 genvar forward_row;
 generate for(forward_row=0;forward_row<ENTRIES;forward_row=forward_row+1)begin:gen_forward_snapshot
   localparam [INDEX_W-1:0] SLOT=forward_row[INDEX_W-1:0];
   wire [1:0] prepare_w={
     query_occupied_w[1]&&!query_full_w[1]&&query_slot_w[1]==SLOT,
     query_occupied_w[0]&&!query_full_w[0]&&query_slot_w[0]==SLOT};
   always @(posedge clk_i)begin
     if(prepare_w[1])forward_q[forward_row]<=selected_forward_w[1];
     else if(prepare_w[0])forward_q[forward_row]<=selected_forward_w[0];
   end
`ifdef R64_ASSERT
   reg [63:0] published_reference_q;
   reg [7:0] published_mask_reference_q;
   integer ref_lane,ref_byte;
   always @(posedge clk_i)begin
     if(!rst_i)begin
       for(ref_lane=0;ref_lane<2;ref_lane=ref_lane+1)
         if(query_take_w[ref_lane]&&!query_full_w[ref_lane]&&query_slot_w[ref_lane]==SLOT)begin
           published_reference_q<=selected_forward_w[ref_lane];
           published_mask_reference_q<=query_mask_w[ref_lane];
         end
       if(prepare_w==2'b11)$fatal(1,"LSU two query heads claim one forwarding row");
       if((|prepare_w)&&(mem_issued_q[forward_row]||
          (physical_hold_valid_q[0]&&physical_slot_w[0]==SLOT)||
          (physical_hold_valid_q[1]&&physical_slot_w[1]==SLOT)))
         $fatal(1,"LSU query preparation overwrites a published physical snapshot");
       if(mem_issued_q[forward_row])
         for(ref_byte=0;ref_byte<8;ref_byte=ref_byte+1)
           if(forward_mask_q[forward_row][ref_byte]&&
              forward_q[forward_row][ref_byte*8+:8]!==published_reference_q[ref_byte*8+:8])
             $fatal(1,"LSU issued forwarding bytes differ from query-take capture");
       if(mem_issued_q[forward_row]&&forward_mask_q[forward_row]!==published_mask_reference_q)
         $fatal(1,"LSU issued forwarding mask differs from query-take capture");
     end
   end
`endif
 end endgenerate
 // The registered physical descriptor, not new arbitration, is the forwarding
 // owner. Store commit means its successful B already updated coherent memory.
 generate for(bk=0;bk<2;bk=bk+1)begin:gen_forward
  wire [ENTRIES-1:0] match_w;
  for(stidx=0;stidx<ENTRIES;stidx=stidx+1)begin:gen_match
   assign match_w[stidx]=eligible_source_w[stidx]&&
     descriptor_age_w[bk*ENTRIES+stidx]&&pa_q[stidx][63:3]==probe_pa_w[bk][63:3];
  end
  for(by=0;by<8;by=by+1)begin:gen_byte
   wire [ENTRIES-1:0] byte_valid_w;wire [ENTRIES*8-1:0] byte_data_w;
   for(stidx=0;stidx<ENTRIES;stidx=stidx+1)begin:gen_store
    assign byte_valid_w[stidx]=match_w[stidx]&&mask_q[stidx][by];
    assign byte_data_w[stidx*8+:8]=store_q[stidx][by*8+:8];
   end
   wire [7:0] unused_query_byte_w;
   R64LsuForwardByte #(.N(ENTRIES),.SLOT_W(INDEX_W)) youngest(
    .valid_i(byte_valid_w),.younger_i(younger_relations_w),.data_i(byte_data_w),
    .winner_mask_o(selected_winner_w[(bk*8+by)*ENTRIES+:ENTRIES]),.valid_o(selected_mask_w[bk][by]),.data_o(unused_query_byte_w));
  end
 end endgenerate

 reg [(1<<ROB_W)-1:0] reuse_w;
 reg irreversible_w,empty_w,drained_w;
 always @*begin
   reuse_w=0;irreversible_w=0;empty_w=1;drained_w=1;
   for(i=0;i<ENTRIES;i=i+1)if(state_q[i]!=FREE)begin
     reuse_w[tag_q[i][ROB_W-1:0]]=1;empty_w=0;
     if(bound_q[i])drained_w=0;
     if(alive_q[i]&&side_effect_w[i]&&
       (effect_q[i]||(state_q[i]==TRANSLATING&&tr_issued_q[i]&&head_w[i]&&store_w[i])))
       irreversible_w=1;
   end
 end
 assign reuse_block_o=physical_hold_reuse_w|reuse_w|completion_reuse_w|fault_reuse_w|forward_reuse_w|descriptor_reuse_w|raw_reuse_w|query_reuse_w|translation_reuse_w|
   (store_done_q?({{((1<<ROB_W)-1){1'b0}},1'b1}<<store_tag_q[ROB_W-1:0]):{(1<<ROB_W){1'b0}});
 // Full owner idle includes future dispatch reservations. A head-authorized
 // serial operation instead drains actual bound work; its younger unbound
 // reservations cannot bind across the existing IQ serial barrier.
 wire terminal_idle_w=completion_idle_w&&fault_idle_w&&descriptor_idle_w&&
   raw_idle_w&&query_idle_w&&translation_idle_w&&forward_idle_w&&physical_hold_valid_q==0&&!store_done_q;
 assign irrevocable_o=irreversible_w;
 assign idle_o=empty_w&&terminal_idle_w;
 assign drain_idle_o=drained_w&&terminal_idle_w;

 localparam RAW_W=152,META_W=TAG_W+153;
 wire [1:0] raw_credit_w,raw_valid_w,raw_fire_w,input_response_live_w;
 wire [2*TAG_W-1:0] raw_tag_w,raw_in_tag_w;
 wire [2*RAW_W-1:0] raw_data_w,raw_in_data_w;
 wire [(1<<ROB_W)-1:0] raw_reuse_w;
 wire raw_idle_w;
 wire [1:0] unused_response_age_w;wire unused_response_held_age_w;
 wire [INDEX_W-1:0] input_response_slot_w[0:1];
 wire [127:0] response_data_w,response_va_w;
 wire [5:0] response_load_offset_w;
 wire [9:0] response_func_w,response_amo_w;
 wire [11:0] response_cause_w;
 wire [1:0] response_zero_w;
 wire [META_W-1:0] input_meta_w[0:1];
 wire [ENTRIES*META_W-1:0] response_meta_rows_w;
 wire [1:0] response_error_w;
 wire [5:0] response_offset_w;
 generate for(g=0;g<ENTRIES;g=g+1)begin:gen_response_metadata
   assign response_meta_rows_w[g*META_W+:META_W]={tag_q[g],atomic_w[g],store_w[g],side_effect_w[g],
     misaligned_q[g],amo_q[g],func_q[g],va_q[g],forward_mask_q[g],forward_q[g]};
 end endgenerate
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.DATA_W(RAW_W),.TAG_W(TAG_W),.ROB_W(ROB_W)) response_queue(
   .out_occupied_o(),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_age_i(2'b0),.age_clear_i(1'b0),.out_age_o(unused_response_age_w),.held_age_o(unused_response_held_age_w),
   .in_fire_i(raw_fire_w),.in_ready_o(raw_credit_w),.in_tag_i(raw_in_tag_w),.in_data_i(raw_in_data_w),
   .out_valid_o(raw_valid_w),.out_ready_i(event_grant_w[1:0]),.out_tag_o(raw_tag_w),.out_data_o(raw_data_w),
   .reuse_block_o(raw_reuse_w),.idle_o(raw_idle_w));
 generate for(g=0;g<2;g=g+1)begin:gen_response_capture
   assign input_response_slot_w[g]=mem_rsp_token_i[g*INDEX_W+:INDEX_W];
   assign input_response_live_w[g]=alive_q[input_response_slot_w[g]]&&!killed_w[input_response_slot_w[g]];
   // Only a registered-dead, issued, aligned ordinary RAM load may drain
   // without raw storage. The slot remains owned until this response fires;
   // current kill/flush does not feed this ready bypass.
   wire [ENTRIES-1:0] dead_load_match_w;
   for(z=0;z<ENTRIES;z=z+1)begin:gen_dead_load
     assign dead_load_match_w[z]=input_response_slot_w[g]==INDEX_W'(z)&&
       state_q[z]==MEMORY&&mem_issued_q[z]&&!alive_q[z]&&
       !store_w[z]&&!atomic_w[z]&&!misaligned_q[z]&&class_q[z]<2;
   end
   assign mem_rsp_ready_o[g]=!rst_i&&(raw_credit_w[g]||(|dead_load_match_w));
   assign raw_fire_w[g]=mem_rsp_valid_i[g]&&mem_rsp_ready_o[g]&&input_response_live_w[g];
   wire [ENTRIES-1:0] select_meta_w;
   for(z=0;z<ENTRIES;z=z+1)begin:gen_meta_decode
     localparam [INDEX_W-1:0] SLOT=z[INDEX_W-1:0];
     assign select_meta_w[z]=input_response_slot_w[g]==SLOT;
   end
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(META_W)) metadata(
     .select_i(select_meta_w),.data_i(response_meta_rows_w),.data_o(input_meta_w[g]));
   wire [63:0] merged_input_w;
   for(z=0;z<8;z=z+1)begin:gen_input_merge
     assign merged_input_w[z*8+:8]=input_meta_w[g][64+z]?
       input_meta_w[g][z*8+:8]:mem_rsp_data_i[g*64+z*8+:8];
   end
   assign raw_in_tag_w[g*TAG_W+:TAG_W]=input_meta_w[g][153+:TAG_W];
   assign raw_in_data_w[g*RAW_W+:RAW_W]={
     mem_rsp_offset_i[g*3+:3],mem_rsp_error_i[g],
     mem_rsp_error_i[g]?(input_meta_w[g][151]?6'd7:6'd5):6'b0,
     input_meta_w[g][72+:64],{input_meta_w[g][143:142],input_meta_w[g][138:136]},
     input_meta_w[g][144+:5],input_meta_w[g][149]?3'b0:input_meta_w[g][74:72],
     input_meta_w[g][151]&&!input_meta_w[g][152],merged_input_w};
   assign response_data_w[g*64+:64]=raw_data_w[g*RAW_W+:64];
   assign response_zero_w[g]=raw_data_w[g*RAW_W+64];
   assign response_load_offset_w[g*3+:3]=raw_data_w[g*RAW_W+65+:3];
   assign response_amo_w[g*5+:5]=raw_data_w[g*RAW_W+68+:5];
   assign response_func_w[g*5+:5]=raw_data_w[g*RAW_W+73+:5];
   assign response_va_w[g*64+:64]=raw_data_w[g*RAW_W+78+:64];
   assign response_cause_w[g*6+:6]=raw_data_w[g*RAW_W+142+:6];
   assign response_error_w[g]=raw_data_w[g*RAW_W+148];
   assign response_offset_w[g*3+:3]=raw_data_w[g*RAW_W+149+:3];

 end endgenerate
 wire [63:0] input_address_w[0:1];
 wire [7:0] input_func_w[0:1];
 wire [4:0] input_amo_w[0:1];
 wire [1:0] input_misaligned_w,input_cross_page_w;
 wire [127:0] input_store_pair_w[0:1];wire [5:0] input_rotate_start_w[0:1];
 wire [63:0] formatted_response_w[0:1];
 wire unused_payload_w=|in_uop_i;
 wire unused_third_operand_w=|{in_operand_i[383:320],in_operand_i[191:128]};
 generate for(g=0;g<2;g=g+1)begin:gen_input
   assign input_func_w[g]=in_uop_i[g*U+196+:8];
   assign input_amo_w[g]=in_uop_i[g*U+128+27+:5];
   assign input_misaligned_w[g]=|(input_address_w[g][2:0]&((3'b1<<input_func_w[g][1:0])-1'b1));
   assign input_cross_page_w[g]=({1'b0,input_address_w[g][11:0]}+(13'd1<<input_func_w[g][1:0]))>13'd4096;
   assign input_store_pair_w[g]={in_operand_i[g*192+64+:64],in_operand_i[g*192+64+:64]};
   assign input_rotate_start_w[g]=6'b0-{input_address_w[g][2:0],3'b0};
   wire unused_address_carry_w;wire [63:0] address_sum_w;
   R64WideAdd #(.WIDTH(64),.BLOCK(4)) address_add(
     .a_i(in_operand_i[g*192+:64]),.b_i(in_uop_i[g*U+64+:64]),
     .carry_i(1'b0),.sum_o(address_sum_w),.carry_o(unused_address_carry_w));
   assign input_address_w[g]=input_func_w[g][7]?in_operand_i[g*192+:64]:address_sum_w;
   assign formatted_response_w[g]=load_value(response_data_w[g*64+:64],
     response_func_w[g*5+:5],response_amo_w[g*5+:5],response_load_offset_w[g*3+:3]);

 end endgenerate
 wire [1:0] completion_credit_w;
 reg [1:0] completion_fire_w;
 reg [2*TAG_W-1:0] completion_tag_w;
 reg [2*R-1:0] completion_result_w;
 wire [(1<<ROB_W)-1:0] completion_reuse_w,fault_reuse_w;
 wire fault_idle_w;
 wire completion_idle_w;
 wire [1:0] full_forward_w,forward_take_w,forward_credit_w;
 wire [1:0] forward_valid_q;
 wire [TAG_W-1:0] forward_tag_q[0:1];
 wire [63:0] forward_data_q[0:1];
 wire [4:0] forward_func_q[0:1],forward_amo_q[0:1];
 wire [2:0] forward_offset_q[0:1];
 wire [1:0] forward_killed_w;
 wire [(1<<ROB_W)-1:0] forward_reuse_w;
 wire forward_idle_w;
 wire [153:0] forward_payload_w,forward_input_w;
 wire [2*TAG_W-1:0] forward_tags_w;
 wire [1:0] unused_forward_age_w;
 wire unused_forward_held_age_w;
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.DATA_W(77),.TAG_W(TAG_W),.ROB_W(ROB_W)) forwarding_results(
   .out_occupied_o(),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_fire_i(forward_take_w),.in_ready_o(forward_credit_w),
   .in_tag_i(query_tag_w),.in_data_i(forward_input_w),
   .in_age_i(2'b0),.age_clear_i(1'b0),.out_age_o(unused_forward_age_w),.held_age_o(unused_forward_held_age_w),
   .out_valid_o(forward_valid_q),.out_ready_i(event_grant_w[5:4]),
   .out_tag_o(forward_tags_w),.out_data_o(forward_payload_w),
   .reuse_block_o(forward_reuse_w),.idle_o(forward_idle_w));
 generate for(g=0;g<2;g=g+1)begin:gen_forward_result
   assign forward_input_w[g*77+:77]={query_data_w[g*QUERY_W+QO+:3],
     query_data_w[g*QUERY_W+QA+:5],
     query_data_w[g*QUERY_W+QF+6+:2],query_data_w[g*QUERY_W+QF+:3],selected_forward_w[g]};
   assign forward_tag_q[g]=forward_tags_w[g*TAG_W+:TAG_W];
   assign {forward_offset_q[g],forward_amo_q[g],forward_func_q[g],forward_data_q[g]}=
     forward_payload_w[g*77+:77];
 end endgenerate
 wire [1:0] unused_fault_age_w;wire unused_fault_held_age_w;
 wire [1:0] fault_credit_w,fault_queue_valid_w,fault_capture_w;
 wire [2*TAG_W-1:0] fault_tag_w;
 wire [139:0] fault_data_w;
 wire [ENTRIES-1:0] fault_capture_mask_w[0:1];
 wire [ENTRIES*(TAG_W+70)-1:0] fault_metadata_w;
 wire [2*(TAG_W+70)-1:0] fault_selected_w;
 genvar fl;
 generate for(fl=0;fl<ENTRIES;fl=fl+1)begin:gen_fault_row
   assign fault_metadata_w[fl*(TAG_W+70)+:TAG_W+70]={tag_q[fl],va_q[fl],cause_q[fl]};
 end
 for(fl=0;fl<2;fl=fl+1)begin:gen_fault_capture
   wire [ENTRIES-1:0] selected=fl==0?unused_fault_first_mask_w:unused_fault_second_mask_w;
   assign fault_capture_mask_w[fl]=selected&~killed_w&{ENTRIES{fault_credit_w[fl]&&!rst_i}};
   assign fault_capture_w[fl]=|fault_capture_mask_w[fl];
   R64LsuMetaRead #(.N(ENTRIES),.DATA_W(TAG_W+70)) read_fault(
     .select_i(selected),.data_i(fault_metadata_w),.data_o(fault_selected_w[fl*(TAG_W+70)+:TAG_W+70]));
 end endgenerate
 R64LsuRequestQueue #(.PREPARED_CANCEL(PREPARED_CANCEL),.TAG_W(TAG_W),.ROB_W(ROB_W),.DATA_W(70)) faults(
   .out_occupied_o(),
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
   .in_fire_i(fault_capture_w),.in_ready_o(fault_credit_w),
   .in_tag_i({fault_selected_w[(TAG_W+70)+70+:TAG_W],fault_selected_w[70+:TAG_W]}),
   .in_data_i({fault_selected_w[TAG_W+70+:70],fault_selected_w[0+:70]}),
   .in_age_i(2'b0),.age_clear_i(1'b0),.out_age_o(unused_fault_age_w),.held_age_o(unused_fault_held_age_w),
   .out_valid_o(fault_queue_valid_w),.out_ready_i(event_grant_w[3:2]),
   .out_tag_o(fault_tag_w),.out_data_o(fault_data_w),.reuse_block_o(fault_reuse_w),.idle_o(fault_idle_w));
 wire [5:0] event_valid_w;
 wire [TAG_W-1:0] event_tag_w[0:5];
 wire [R-1:0] event_result_w[0:5];
 reg [5:0] event_grant_w;
 genvar e;
 generate for(e=0;e<2;e=e+1)begin:gen_events
   assign event_valid_w[e]=raw_valid_w[e];
   assign event_tag_w[e]=raw_tag_w[e*TAG_W+:TAG_W];
   assign event_result_w[e]={5'b0,(response_va_w[e*64+:64]+{61'b0,response_error_w[e]?response_offset_w[e*3+:3]:3'b0}),
     response_cause_w[e*6+:6],response_error_w[e],
     response_zero_w[e]?64'b0:formatted_response_w[e]};
   assign event_valid_w[2+e]=fault_queue_valid_w[e];
   assign event_tag_w[2+e]=fault_tag_w[e*TAG_W+:TAG_W];
   assign event_result_w[2+e]={5'b0,fault_data_w[e*70+6+:64],fault_data_w[e*70+:6],1'b1,64'b0};
   assign full_forward_w[e]=descriptor_valid_w[e]&&probe_allowed_w[e]&&
     !probe_side_effect_w[e]&&!probe_misaligned_w[e]&&
     (selected_mask_w[e]&probe_mask_w[e])==probe_mask_w[e];
   assign forward_killed_w[e]=flush_i||kill_mask_i[forward_tag_q[e][ROB_W-1:0]];
   assign forward_take_w[e]=query_take_w[e]&&query_full_w[e];
   assign event_valid_w[4+e]=forward_valid_q[e]&&!forward_killed_w[e];
   assign event_tag_w[4+e]=forward_tag_q[e];
   assign event_result_w[4+e]={5'b0,64'b0,6'b0,1'b0,
     load_value(forward_data_q[e],forward_func_q[e],forward_amo_q[e],forward_offset_q[e])};
 end endgenerate
 wire [5:0] event_first_w,event_second_w;
 wire [35:0] event_order_w;
 wire unused_event_first_valid_w,unused_event_second_valid_w;
 wire [2:0] unused_event_first_slot_w,unused_event_second_slot_w;
 // Cyclic priority advances only after an actual completion capture.
 // This thermometer marks sources before the next priority position.
 reg [5:0] event_before_q;
 wire [5:0] event_last_grant_w=completion_credit_w[1]&&(|event_second_w)?
   event_second_w:(event_first_w&{6{completion_credit_w[0]}});
 reg [5:0] event_before_next_w;
 integer rr_source;
 always @*begin
   event_before_next_w=0;
   for(rr_source=0;rr_source<5;rr_source=rr_source+1)
     event_before_next_w=event_before_next_w|
       ({6{event_last_grant_w[rr_source]}}&((6'b1<<(rr_source+1))-1'b1));
 end
 always @(posedge clk_i)begin
   if(rst_i)event_before_q<=0;
   else if(|event_grant_w)event_before_q<=event_before_next_w;
 end
 generate for(e=0;e<6;e=e+1)begin:gen_event_order
   for(z=0;z<6;z=z+1)begin:gen_precedence
     assign event_order_w[e*6+z]=(event_before_q[e]&&!event_before_q[z])||
       ((event_before_q[e]==event_before_q[z])&&(z<e));
   end
 end endgenerate
 R64LsuOrderSelect #(.N(6),.SLOT_W(3)) event_select(
   .valid_i(event_valid_w),.older_i(event_order_w),
   .first_mask_o(event_first_w),.second_mask_o(event_second_w),
   .first_valid_o(unused_event_first_valid_w),.second_valid_o(unused_event_second_valid_w),
   .first_slot_o(unused_event_first_slot_w),.second_slot_o(unused_event_second_slot_w));
 // The cyclic order is a total order for every event_before_q bitmap.
 // Therefore the number of winners depends only on live source count.
 // Count in parallel with owner arbitration; CQ/WB demand need not wait for
 // winner selection, while payload and source pop retain canonical winners.
 wire [2:0] event_pair_any_w={|event_valid_w[5:4],|event_valid_w[3:2],|event_valid_w[1:0]};
 wire event_two_w=(|{&event_valid_w[5:4],&event_valid_w[3:2],&event_valid_w[1:0]})||
     (event_pair_any_w[0]&&event_pair_any_w[1])||
     (event_pair_any_w[0]&&event_pair_any_w[2])||
     (event_pair_any_w[1]&&event_pair_any_w[2]);
 integer ev;
 always @*begin
   completion_fire_w={event_two_w,|event_valid_w}&completion_credit_w;
   completion_tag_w=0;completion_result_w=0;
   event_grant_w=(event_first_w&{6{completion_credit_w[0]}})|
     (event_second_w&{6{completion_credit_w[1]}});
   for(ev=0;ev<6;ev=ev+1)begin
     completion_tag_w[0+:TAG_W]=completion_tag_w[0+:TAG_W]|
       ({TAG_W{event_first_w[ev]}}&event_tag_w[ev]);
     completion_tag_w[TAG_W+:TAG_W]=completion_tag_w[TAG_W+:TAG_W]|
       ({TAG_W{event_second_w[ev]}}&event_tag_w[ev]);
     completion_result_w[0+:R]=completion_result_w[0+:R]|({R{event_first_w[ev]}}&event_result_w[ev]);
     completion_result_w[R+:R]=completion_result_w[R+:R]|({R{event_second_w[ev]}}&event_result_w[ev]);
   end
 end
 R64LsuCompletion #(.TAG_W(TAG_W),.ROB_W(ROB_W)) completion(
   .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
   .in_fire_i(completion_fire_w),.in_ready_o(completion_credit_w),
   .in_tag_i(completion_tag_w),.in_result_i(completion_result_w),
   .out_valid_o(out_valid_o),.out_request_o(out_request_o),.out_ready_i(out_ready_i),.out_tag_o(out_tag_o),.out_result_o(out_result_o),
   .reuse_block_o(completion_reuse_w),.idle_o(completion_idle_w));
 // Program age belongs to dispatch reserve, not operand bind.
 integer row;
 always @(posedge clk_i)begin
   if(rst_i)for(row=0;row<ENTRIES;row=row+1)older_q[row]<=0;
   else for(row=0;row<ENTRIES;row=row+1)begin
     if(reserve_take_w[0])older_q[row][reserve_slot_o[0+:INDEX_W]]<=0;
     if(reserve_take_w[1])older_q[row][reserve_slot_o[INDEX_W+:INDEX_W]]<=0;
     if(reserve_mask_w[0][row])older_q[row]<=live_entry_w;
     if(reserve_mask_w[1][row])older_q[row]<=live_entry_w|reserve_mask_w[0];
   end
 end
 // Each physical entry has a bounded local state controller. Events are
 // mutually exclusive before explicit cancellation; no inferred multiwrite RAM.
 genvar owner;
 generate for(owner=0;owner<ENTRIES;owner=owner+1)begin:gen_owner_state
   localparam [INDEX_W-1:0] SLOT=owner[INDEX_W-1:0];
   wire [1:0] admit_w,reserve_w,trans_start_w,trans_end_w,mem_start_w,mem_end_w,forward_end_w,select_mem_w,fault_end_w,drain_w,local_fault_w;
   wire [2:0] admission_state_w[0:1],translation_state_w[0:1],response_state_w[0:1];
   for(z=0;z<2;z=z+1)begin:gen_event
     assign reserve_w[z]=reserve_mask_w[z][owner];
     assign bind_mask_w[z][owner]=in_fire_i[z]&&!rst_i&&!killed_w[owner]&&
       in_slot_i[z*INDEX_W+:INDEX_W]==SLOT&&alive_q[owner]&&state_q[owner]==NEW&&
       !bound_q[owner]&&tag_q[owner]==in_tag_i[z*TAG_W+:TAG_W];
     assign admit_w[z]=bind_mask_w[z][owner];
     assign trans_start_w[z]=trans_owner_select_w[z][owner];
     assign trans_end_w[z]=translation_response_mask_w[z][owner];
     assign mem_start_w[z]=mfire_w[z]&&physical_slot_w[z]==SLOT;
     assign mem_end_w[z]=mem_rsp_valid_i[z]&&mem_rsp_ready_o[z]&&input_response_live_w[z]&&input_response_slot_w[z]==SLOT;
     assign drain_w[z]=mem_rsp_valid_i[z]&&mem_rsp_ready_o[z]&&!input_response_live_w[z]&&input_response_slot_w[z]==SLOT;
     assign forward_end_w[z]=forward_take_w[z]&&query_slot_w[z]==SLOT;
     assign select_mem_w[z]=mem_owner_select_w[z][owner];
     assign local_fault_w[z]=admission_check_mask_q[z][owner];
     assign fault_end_w[z]=fault_capture_mask_w[z][owner];
     assign admission_state_w[z]=
       ((input_misaligned_w[z]&&(input_func_w[z][7]||(translate_active_i&&input_cross_page_w[z])))||
        (input_func_w[z][6]&&!input_func_w[z][7]&&!fp_enable_i))?3'd5:3'd1;
     assign translation_state_w[z]=(!alive_q[owner]||killed_w[owner])?3'd0:
       ((tr_fault_i[z]||(misaligned_q[owner]&&tr_class_i[z*2+:2]==2))?3'd5:
        (translation_query_mask_w[z][owner]?3'd4:3'd3));
     assign response_state_w[z]=(alive_q[owner]&&!killed_w[owner]&&
       side_effect_w[owner]&&!mem_rsp_error_i[z])?3'd7:3'd0;
   end
   wire prepared_event_w=prepared_take_w&&prepared_slot_q==SLOT;
   wire store_event_w=store_response_fire_w&&mem_store_rsp_token_i==SLOT;
   wire commit_event_w=state_q[owner]==RETIRE&&
     ((commit_fire_i[0]&&tag_q[owner]==commit_tag_i[0+:TAG_W])||
      (commit_fire_i[1]&&tag_q[owner]==commit_tag_i[TAG_W+:TAG_W]));
   wire release_alive_w=(|fault_end_w)||(|forward_end_w)||commit_event_w||(|drain_w)||
     (mem_end_w[0]&&(!side_effect_w[owner]||mem_rsp_error_i[0]))||
     (mem_end_w[1]&&(!side_effect_w[owner]||mem_rsp_error_i[1]))||
     (store_event_w&&(!store_response_live_w||mem_store_rsp_error_i));
   always @(posedge clk_i)begin
     if(rst_i)alive_q[owner]<=0;
     else if((state_q[owner]!=FREE&&killed_w[owner])||release_alive_w)alive_q[owner]<=0;
     else if(|reserve_w)alive_q[owner]<=1;
   end
   wire pin_release_w=state_q[owner]==PINNED&&!source_pin_w[owner];
   wire [25:0] events_w={reserve_w,local_fault_w,pin_release_w,drain_w,commit_event_w,store_event_w,prepared_event_w,
     admit_w,trans_start_w,trans_end_w,mem_start_w,mem_end_w,forward_end_w,select_mem_w,fault_end_w};
   // A physical issue already owns MEMORY; its handshake only sets issued/effect state.
   // Do not feed downstream ready back into a MEMORY-to-MEMORY state rewrite.
   wire [25:0] state_events_w=events_w&~(26'b11<<8);
   wire [2:0] next_state_w=
     ({3{|reserve_w}}&3'd1)|
     ({3{local_fault_w[0]}}&(checked_cause_w[0]!=0?3'd5:3'd1))|
     ({3{local_fault_w[1]}}&(checked_cause_w[1]!=0?3'd5:3'd1))|
     ({3{admit_w[0]}}&admission_state_w[0])|({3{admit_w[1]}}&admission_state_w[1])|
     ({3{|trans_start_w}}&3'd2)|({3{trans_end_w[0]}}&translation_state_w[0])|
     ({3{trans_end_w[1]}}&translation_state_w[1])|
     ({3{(|select_mem_w)||prepared_event_w}}&3'd4)|
     ({3{mem_end_w[0]}}&response_state_w[0])|({3{mem_end_w[1]}}&response_state_w[1])|
     ({3{store_event_w&&store_response_live_w&&!mem_store_rsp_error_i}}&3'd7)|
     ({3{commit_event_w&&source_pin_w[owner]}}&3'd6);
   wire cancel_free_w=state_q[owner]!=FREE&&killed_w[owner]&&
     !((state_q[owner]==TRANSLATING&&tr_issued_q[owner])||(state_q[owner]==MEMORY&&mem_issued_q[owner]));
   always @(posedge clk_i)begin
     if(rst_i)begin state_q[owner]<=FREE;tag_q[owner]<=0;checked_q[owner]<=0;bound_q[owner]<=0;end
     else begin
       if(|reserve_w)begin bound_q[owner]<=0;checked_q[owner]<=0;end
       else if(|admit_w)begin bound_q[owner]<=1;checked_q[owner]<=!trigger_active_w;end
       else if(killed_w[owner])checked_q[owner]<=0;
       else if(|local_fault_w)checked_q[owner]<=1;
       if(cancel_free_w)state_q[owner]<=FREE;
       else if(|state_events_w)state_q[owner]<=next_state_w;
       if(|reserve_w)tag_q[owner]<=({TAG_W{reserve_w[0]}}&reserve_tag_i[0+:TAG_W])|
         ({TAG_W{reserve_w[1]}}&reserve_tag_i[TAG_W+:TAG_W]);
     end
   end
   // Bind already proves a unique canonical row. Keep that one-hot proof
   // local instead of reducing all rows to bind_take and decoding the slot
   // again for wide VA/store/mask writes. Preserve lane1's original priority.
   integer bind_lane;
   always @(posedge clk_i)begin
     if(rst_i)misaligned_q[owner]<=0;
     else for(bind_lane=0;bind_lane<2;bind_lane=bind_lane+1)begin
       if(reserve_w[bind_lane])misaligned_q[owner]<=0;
       if(admit_w[bind_lane])begin
         va_q[owner]<=input_address_w[bind_lane];
         store_q[owner]<=input_store_pair_w[bind_lane][{1'b0,input_rotate_start_w[bind_lane]}+:64];
         misaligned_q[owner]<=input_misaligned_w[bind_lane];
         mask_q[owner]<=byte_mask(input_func_w[bind_lane][1:0],input_address_w[bind_lane][2:0]);
         if(input_func_w[bind_lane][6]&&!input_func_w[bind_lane][7]&&!fp_enable_i)
           va_q[owner]<=0;
       end
     end
   end
   integer row_lane;
   always @(posedge clk_i)begin
     if(rst_i)begin class_q[owner]<=0;needs_ad_q[owner]<=0;tr_issued_q[owner]<=0;end
     else begin
       for(row_lane=0;row_lane<2;row_lane=row_lane+1)begin
         if(xfire_w[row_lane]&&xslot_q[row_lane]==SLOT)tr_issued_q[owner]<=1;
         if(trans_end_w[row_lane])begin
           // The accepted owner drains even after canonical cancellation.
           tr_issued_q[owner]<=0;
           if(alive_q[owner]&&!killed_w[owner])begin
             pa_q[owner]<=tr_paddr_i[row_lane*64+:64];
             class_q[owner]<=tr_class_i[row_lane*2+:2];
             needs_ad_q[owner]<=tr_needs_ad_i[row_lane];
             if(!tr_fault_i[row_lane]&&misaligned_q[owner]&&tr_class_i[row_lane*2+:2]==2)
               cause_q[owner]<=store_w[owner]?6'd6:6'd4;
             if(tr_fault_i[row_lane])cause_q[owner]<={1'b0,tr_cause_i[row_lane*5+:5]};
           end
         end
         // The byte mask belongs to the same immutable query payload as
         // forward_q. Capture it while the head is resident, rather than
         // coupling its D input to the final ready/take round trip. A stale
         // snapshot is not observable: publication remains query_take, and
         // a snapshot may not be overwritten after physical ownership wins.
         if(query_occupied_w[row_lane]&&!query_full_w[row_lane]&&query_slot_w[row_lane]==SLOT)
           forward_mask_q[owner]<=query_mask_w[row_lane];
         if(reserve_w[row_lane])begin
           class_q[owner]<=0;needs_ad_q[owner]<=0;tr_issued_q[owner]<=0;
         end
         if(admit_w[row_lane])begin
           class_q[owner]<=0;needs_ad_q[owner]<=0;tr_issued_q[owner]<=0;
           cause_q[owner]<=0;
           if(input_misaligned_w[row_lane]&&(input_func_w[row_lane][7]||
              (translate_active_i&&input_cross_page_w[row_lane])))
             cause_q[owner]<=(input_func_w[row_lane][7]?(input_amo_w[row_lane]!=2):input_func_w[row_lane][5])?6'd6:6'd4;
           if(input_func_w[row_lane][6]&&!input_func_w[row_lane][7]&&!fp_enable_i)cause_q[owner]<=6'd2;
         end
       end
       if(local_fault_w[0]&&alive_q[owner]&&!killed_w[owner])cause_q[owner]<=checked_cause_w[0];
       if(local_fault_w[1]&&alive_q[owner]&&!killed_w[owner])cause_q[owner]<=checked_cause_w[1];
     end
   end
`ifdef R64_ASSERT
   always @(posedge clk_i)if(!rst_i&&(|mem_start_w)&&state_q[owner]!==MEMORY)
     $fatal(1,"LSU physical issue must already own MEMORY state");
   always @(posedge clk_i)if(!rst_i&&(events_w&(events_w-1'b1))!=0)
     $fatal(1,"R64Lsu conflicting local owner state events");
`endif
 end endgenerate
 integer n;
 always @(posedge clk_i)begin
   if(rst_i)begin
     prepared_valid_q<=0;prepared_payload_valid_q<=0;prepared_payload_q<=0;prepared_slot_q<=0;prepared_tag_q<=0;store_done_q<=0;store_error_q<=0;store_tag_q<=0;store_tval_q<=0;
     effect_q<=0;mem_issued_q<=0;mvalid_q<=0;
     for(n=0;n<ENTRIES;n=n+1)begin func_q[n]<=0;end
     for(n=0;n<2;n=n+1)begin mslot_q[n]<=0;mtag_q[n]<=0;xhead_q[n]<=0;xtail_q[n]<=0;xcount_q[n]<=0;end
   end else begin
     if(prepared_valid_q&&(prepared_killed_w||prepared_take_w))begin prepared_valid_q<=0;prepared_payload_valid_q<=0;end
     // Cancellation qualifies the capture enable, not the payload mux.
     // A rejected replacement must preserve an existing prepared owner.
     if(prepared_capture_w)begin
       prepared_payload_q<=prepared_selected_payload_w;
       prepared_valid_q<=1;prepared_payload_valid_q<=1;
       prepared_slot_q<=prepared_capture_slot_w;prepared_tag_q<=prepared_capture_tag_w;
     end
     if(store_done_q&&store_done_ready_i)store_done_q<=0;
     // Error terminals have drained all external ownership and may be removed
     // by synchronous trap; successful visible effects retain the retire owner.
     if(store_done_q&&(flush_i||kill_mask_i[store_tag_q[ROB_W-1:0]]))store_done_q<=0;
     if(store_response_fire_w)begin
       mem_issued_q[mem_store_rsp_token_i]<=0;
       if(store_response_live_w)begin
         store_done_q<=1;store_tag_q<=tag_q[mem_store_rsp_token_i];
         store_error_q<=mem_store_rsp_error_i;store_tval_q<=va_q[mem_store_rsp_token_i];
       end
       if(!store_response_live_w||mem_store_rsp_error_i)begin
         effect_q[mem_store_rsp_token_i]<=0;
       end
     end
     for(n=0;n<2;n=n+1)begin
       if(descriptor_s_take_w[n]||mkilled_w[n])mvalid_q[n]<=0;
       case({xfire_w[n],xresponse_w[n]})
         2'b10:xcount_q[n]<=xcount_q[n]+1'b1;
         2'b01:xcount_q[n]<=xcount_q[n]-1'b1;
         default:begin end
       endcase
       if(xfire_w[n])begin
         xfifo_q[n][xtail_q[n]]<=xslot_q[n];xfifo_protection_q[n][xtail_q[n]]<=xprotection_q[n];xtail_q[n]<=xtail_q[n]+1'b1;
       end
       if(xresponse_w[n])xhead_q[n]<=xhead_q[n]+1'b1;
       if(mfire_w[n])begin
         mem_issued_q[physical_slot_w[n]]<=1;effect_q[physical_slot_w[n]]<=side_effect_w[physical_slot_w[n]];
         
         

       end

       if(mem_rsp_valid_i[n]&&mem_rsp_ready_o[n])begin
         mem_issued_q[input_response_slot_w[n]]<=0;
         if(mem_rsp_error_i[n])effect_q[input_response_slot_w[n]]<=0;
       end
       if(memory_available_w[n])begin
         mslot_q[n]<=memory_slot_w[n];mtag_q[n]<=selected_mtag_w[n*TAG_W+:TAG_W];
       end
       if(mem_select_valid_w[n])mvalid_q[n]<=1;
       if(reserve_take_w[n])begin
         func_q[reserve_slot_o[n*INDEX_W+:INDEX_W]]<=reserve_func_i[n*8+:8];
         amo_q[reserve_slot_o[n*INDEX_W+:INDEX_W]]<=reserve_amo_i[n*5+:5];
         effect_q[reserve_slot_o[n*INDEX_W+:INDEX_W]]<=0;
         mem_issued_q[reserve_slot_o[n*INDEX_W+:INDEX_W]]<=0;
       end
       if(bind_take_w[n])begin
         effect_q[bind_slot_w[n]]<=0;mem_issued_q[bind_slot_w[n]]<=0;
       end
     end
     for(n=0;n<ENTRIES;n=n+1)begin
       if((commit_fire_i[0]&&tag_q[n]==commit_tag_i[0+:TAG_W])||
          (commit_fire_i[1]&&tag_q[n]==commit_tag_i[TAG_W+:TAG_W]))begin
         if(state_q[n]==RETIRE)begin effect_q[n]<=0;end
       end
     end
     for(n=0;n<ENTRIES;n=n+1)if(state_q[n]!=FREE&&killed_w[n])begin
       
     end
   end
 end
`ifdef R64_ASSERT
 // Reference the original variable-index write process, including reset,
 // reserve/bind and lane ordering, for every row (even currently invalid).
 reg [63:0] bind_reference_va_q[0:ENTRIES-1],bind_reference_store_q[0:ENTRIES-1];
 reg [7:0] bind_reference_mask_q[0:ENTRIES-1];
 reg [ENTRIES-1:0] bind_reference_misaligned_q;
 integer br_lane,br_row;
 always @(posedge clk_i)begin
   if(rst_i)bind_reference_misaligned_q<=0;
   else for(br_lane=0;br_lane<2;br_lane=br_lane+1)begin
     if(reserve_take_w[br_lane])bind_reference_misaligned_q[reserve_slot_o[br_lane*INDEX_W+:INDEX_W]]<=0;
     if(bind_take_w[br_lane])begin
       bind_reference_va_q[bind_slot_w[br_lane]]<=input_address_w[br_lane];
       bind_reference_store_q[bind_slot_w[br_lane]]<=input_store_pair_w[br_lane][{1'b0,input_rotate_start_w[br_lane]}+:64];
       bind_reference_misaligned_q[bind_slot_w[br_lane]]<=input_misaligned_w[br_lane];
       bind_reference_mask_q[bind_slot_w[br_lane]]<=byte_mask(input_func_w[br_lane][1:0],input_address_w[br_lane][2:0]);
       if(input_func_w[br_lane][6]&&!input_func_w[br_lane][7]&&!fp_enable_i)
         bind_reference_va_q[bind_slot_w[br_lane]]<=0;
     end
   end
 end
 always @(negedge clk_i)if(!rst_i)
   for(br_row=0;br_row<ENTRIES;br_row=br_row+1)
     if({va_q[br_row],store_q[br_row],mask_q[br_row],misaligned_q[br_row]}!==
        {bind_reference_va_q[br_row],bind_reference_store_q[br_row],bind_reference_mask_q[br_row],bind_reference_misaligned_q[br_row]})
       $fatal(1,"R64Lsu fixed-row bind changed original metadata write row=%0d",br_row);
 reg [63:0] previous_pa_q[0:ENTRIES-1];
 reg [1:0] previous_class_q[0:ENTRIES-1];
 reg [ENTRIES-1:0] previous_needs_ad_q,previous_tr_issued_q;
 reg [5:0] previous_cause_q[0:ENTRIES-1];
 reg [7:0] previous_forward_mask_q[0:ENTRIES-1];
 integer previous_row,previous_lane;
 always @(posedge clk_i)begin
   for(previous_row=0;previous_row<ENTRIES;previous_row=previous_row+1)begin
     previous_pa_q[previous_row]<=pa_q[previous_row];
     previous_class_q[previous_row]<=class_q[previous_row];
     previous_cause_q[previous_row]<=cause_q[previous_row];
     previous_forward_mask_q[previous_row]<=forward_mask_q[previous_row];
   end
   previous_needs_ad_q<=needs_ad_q;previous_tr_issued_q<=tr_issued_q;
   if(rst_i)begin
     for(previous_row=0;previous_row<ENTRIES;previous_row=previous_row+1)previous_class_q[previous_row]<=0;
     previous_needs_ad_q<=0;previous_tr_issued_q<=0;
   end else begin
     for(previous_lane=0;previous_lane<2;previous_lane=previous_lane+1)begin
       if(xfire_w[previous_lane])previous_tr_issued_q[xslot_q[previous_lane]]<=1;
       if(xresponse_w[previous_lane])begin
         previous_tr_issued_q[response_slot_w[previous_lane]]<=0;
         if(alive_q[response_slot_w[previous_lane]]&&!killed_w[response_slot_w[previous_lane]])begin
           previous_pa_q[response_slot_w[previous_lane]]<=tr_paddr_i[previous_lane*64+:64];
           previous_class_q[response_slot_w[previous_lane]]<=tr_class_i[previous_lane*2+:2];
           previous_needs_ad_q[response_slot_w[previous_lane]]<=tr_needs_ad_i[previous_lane];
           if(!tr_fault_i[previous_lane]&&misaligned_q[response_slot_w[previous_lane]]&&tr_class_i[previous_lane*2+:2]==2)
             previous_cause_q[response_slot_w[previous_lane]]<=store_w[response_slot_w[previous_lane]]?6'd6:6'd4;
           if(tr_fault_i[previous_lane])previous_cause_q[response_slot_w[previous_lane]]<={1'b0,tr_cause_i[previous_lane*5+:5]};
         end
       end
       if(query_occupied_w[previous_lane]&&!query_full_w[previous_lane])
         previous_forward_mask_q[query_slot_w[previous_lane]]<=query_mask_w[previous_lane];
       if(reserve_take_w[previous_lane])begin
         previous_class_q[reserve_slot_o[previous_lane*INDEX_W+:INDEX_W]]<=0;
         previous_needs_ad_q[reserve_slot_o[previous_lane*INDEX_W+:INDEX_W]]<=0;
         previous_tr_issued_q[reserve_slot_o[previous_lane*INDEX_W+:INDEX_W]]<=0;
       end
       if(bind_take_w[previous_lane])begin
         previous_class_q[bind_slot_w[previous_lane]]<=0;previous_needs_ad_q[bind_slot_w[previous_lane]]<=0;
         previous_tr_issued_q[bind_slot_w[previous_lane]]<=0;
         previous_cause_q[bind_slot_w[previous_lane]]<=0;
         if(input_misaligned_w[previous_lane]&&(input_func_w[previous_lane][7]||
            (translate_active_i&&input_cross_page_w[previous_lane])))
           previous_cause_q[bind_slot_w[previous_lane]]<=(input_func_w[previous_lane][7]?(input_amo_w[previous_lane]!=2):input_func_w[previous_lane][5])?6'd6:6'd4;
         if(input_func_w[previous_lane][6]&&!input_func_w[previous_lane][7]&&!fp_enable_i)
           previous_cause_q[bind_slot_w[previous_lane]]<=6'd2;
       end
     end
     for(previous_row=0;previous_row<ENTRIES;previous_row=previous_row+1)begin
       if(admission_check_mask_q[0][previous_row]&&alive_q[previous_row]&&!killed_w[previous_row])
         previous_cause_q[previous_row]<=checked_cause_w[0];
       if(admission_check_mask_q[1][previous_row]&&alive_q[previous_row]&&!killed_w[previous_row])
         previous_cause_q[previous_row]<=checked_cause_w[1];
     end
   end
 end
 integer compare_row;
 always @(negedge clk_i)if(!rst_i)begin
   for(compare_row=0;compare_row<ENTRIES;compare_row=compare_row+1)
     if({pa_q[compare_row],class_q[compare_row],needs_ad_q[compare_row],tr_issued_q[compare_row],
         cause_q[compare_row],forward_mask_q[compare_row]}!==
        {previous_pa_q[compare_row],previous_class_q[compare_row],previous_needs_ad_q[compare_row],previous_tr_issued_q[compare_row],
         previous_cause_q[compare_row],previous_forward_mask_q[compare_row]})
       $fatal(1,"R64Lsu fixed-row translation data changed old write result row=%0d",compare_row);
 end
 integer a,order_row,order_col;
 always @(posedge clk_i)if(!rst_i)begin
   // Compare the count cone itself: arbitration-only fixtures suppress the
   // CQ transfer with force, while independently exercising these selectors.
   if(({event_two_w,|event_valid_w}&completion_credit_w)!==({|event_second_w,|event_first_w}&completion_credit_w))
     $fatal(1,"R64Lsu event count changed completion acceptance");
   if(prepared_capture_w!==(unused_prepared_select_w&&!killed_w[unused_prepared_choice_w]))
     $fatal(1,"R64Lsu prepared onehot changed capture event");
   if(prepared_capture_w&&(prepared_capture_slot_w!==unused_prepared_choice_w||
      prepared_capture_tag_w!==tag_q[unused_prepared_choice_w]))
     $fatal(1,"R64Lsu prepared onehot changed canonical identity");
 end
 always @(posedge clk_i)if(!rst_i&&(special_candidate_w&(special_candidate_w-1'b1))!=0)
   $fatal(1,"R64Lsu multiple authorized side-effect owners");
 // A selected but unissued holder owns a live entry exclusively. It has
 // no accepted response, CQ terminal, or commit event that could end its life;
 // only its own handoff or canonical kill can remove it.
 integer ad_check;
 always @(posedge clk_i)if(!rst_i)begin
   if((ad_candidate_w&(ad_candidate_w-1'b1))!=0)
     $fatal(1,"R64Lsu multiple head A/D replay owners");
   for(ad_check=0;ad_check<ENTRIES;ad_check=ad_check+1)
     if(ad_candidate_w[ad_check]&&|(older_q[ad_check]&translation_candidate_w))
       $fatal(1,"R64Lsu head A/D replay younger than NEW translation");
 end
 generate for(genvar qc=0;qc<2;qc=qc+1)begin:gen_translation_owner_check
   for(genvar qs=0;qs<2;qs=qs+1)begin:gen_slot
     wire [TAG_W-1:0] owner_tag_w=translation_queue.tag_q[qc][qs];
     wire [INDEX_W-1:0] owner_slot_w=translation_queue.data_q[qc][qs][0+:INDEX_W];
     always @(posedge clk_i)if(!rst_i&&!flush_i&&translation_queue.valid_q[qc][qs]&&
         !kill_mask_i[owner_tag_w[ROB_W-1:0]])begin
       if(owner_slot_w>=ENTRIES||!alive_q[owner_slot_w]||state_q[owner_slot_w]!=TRANSLATING||
          tr_issued_q[owner_slot_w]||tag_q[owner_slot_w]!=owner_tag_w)
         $fatal(1,"R64Lsu translation queued slot lost unissued full-tag owner");
     end
   end
   always @(posedge clk_i)if(!rst_i)begin
     if(xcount_q[qc]>4||(xfire_w[qc]&&xcount_q[qc]==4))
       $fatal(1,"R64Lsu translation accepted FIFO capacity violation");
   end
 end endgenerate
 integer holder_check;
 always @(posedge clk_i)if(!rst_i)begin
   for(holder_check=0;holder_check<2;holder_check=holder_check+1)begin
     if(xvalid_q[holder_check]&&!xkilled_w[holder_check]&&
       (!alive_q[xslot_q[holder_check]]||state_q[xslot_q[holder_check]]!=TRANSLATING||
        tr_issued_q[xslot_q[holder_check]]||tag_q[xslot_q[holder_check]]!=xtag_q[holder_check]))
       $fatal(1,"R64Lsu translation holder lost canonical unissued owner");
     if(mvalid_q[holder_check]&&!mkilled_w[holder_check]&&
       (!alive_q[mslot_q[holder_check]]||state_q[mslot_q[holder_check]]!=MEMORY||
        mem_issued_q[mslot_q[holder_check]]||tag_q[mslot_q[holder_check]]!=mtag_q[holder_check]))
       $fatal(1,"R64Lsu memory holder lost canonical unissued owner");
   end
   if(head_prepare_w&&prepared_valid_q&&!prepared_killed_w&&
     (state_q[prepared_slot_q]!=READY||mem_issued_q[prepared_slot_q]||effect_q[prepared_slot_q]))
     $fatal(1,"R64Lsu replaced prepared descriptor after side effect issue");
   if(prepared_valid_q&&!prepared_killed_w&&
     (!alive_q[prepared_slot_q]||state_q[prepared_slot_q]!=READY||
      tag_q[prepared_slot_q]!=prepared_tag_q))
     $fatal(1,"R64Lsu prepared holder lost canonical ready owner");
 end
 reg [1:0] held_physical_q;
 reg [TAG_W-1:0] held_physical_tag_q[0:1];
 reg [INDEX_W+147:0] held_physical_payload_q[0:1];
 wire [INDEX_W+147:0] physical_payload_w[0:1];
 generate for(g=0;g<2;g=g+1)begin:gen_held_check
   assign physical_payload_w[g]={mem_token_o[g*INDEX_W+:INDEX_W],mem_addr_o[g*64+:64],
     mem_data_o[g*64+:64],mem_op_o[g*2+:2],mem_cache_o[g],mem_size_o[g*3+:3],
     mem_strb_o[g*8+:8],mem_amo_o[g*5+:5],mem_fast_store_o[g]};
 end endgenerate
 integer hp;
 always @(posedge clk_i)begin
   if(rst_i)held_physical_q<=0;
   else for(hp=0;hp<2;hp=hp+1)begin
     if(held_physical_q[hp]&&!flush_i&&!kill_mask_i[held_physical_tag_q[hp][ROB_W-1:0]]&&
       (!mem_valid_o[hp]||physical_payload_w[hp]!==held_physical_payload_q[hp]))
       $fatal(1,"R64Lsu physical offer changed while stalled");
     held_physical_q[hp]<=mem_valid_o[hp]&&!mem_ready_i[hp];
     held_physical_tag_q[hp]<=tag_q[physical_slot_w[hp]];
     held_physical_payload_q[hp]<=physical_payload_w[hp];
   end
 end
 always @(posedge clk_i)if(!rst_i)begin
   // Native ROB cancellation is a younger suffix. Independent load kills
   // are supported, but cancelling an older store cannot keep its consumers.
   for(order_row=0;order_row<ENTRIES;order_row=order_row+1)
     if(alive_q[order_row]&&!killed_w[order_row]&&
       (|(older_q[order_row]&alive_q&store_w&killed_w)))
       $fatal(1,"R64Lsu cancelled older store retained younger memory owner");
   if(head_valid_i)for(order_row=0;order_row<ENTRIES;order_row=order_row+1)
     for(order_col=0;order_col<ENTRIES;order_col=order_col+1)
       if(live_entry_w[order_row]&&live_entry_w[order_col]&&
          older_q[order_row][order_col]!=(age_w[order_col]<age_w[order_row]))
         $fatal(1,"R64Lsu admission order relation disagrees with live ROB age");
   for(a=0;a<ENTRIES;a=a+1)
     if(!bound_q[a]&&(tr_issued_q[a]||mem_issued_q[a]||effect_q[a]||
       (state_q[a]!=FREE&&state_q[a]!=NEW)))
       $fatal(1,"R64Lsu unbound reservation acquired execution ownership");
   if((reserve_fire_i&~reserve_want_i)!=0||(reserve_fire_i&~reserve_ready_o)!=0||
      (flush_i&&|reserve_fire_i)||reserve_fire_i!=reserve_take_w)
     $fatal(1,"R64Lsu invalid dispatch reservation");
   if(reserve_fire_i==3&&reserve_slot_o[0+:INDEX_W]==reserve_slot_o[INDEX_W+:INDEX_W])
     $fatal(1,"R64Lsu duplicate reserve slot");
   if(reserve_fire_i[1]&&reserve_want_i[0]&&!reserve_fire_i[0])
     $fatal(1,"R64Lsu memory reservation skipped older birth");
   if(in_fire_i==3&&in_slot_i[0+:INDEX_W]==in_slot_i[INDEX_W+:INDEX_W])
     $fatal(1,"R64Lsu duplicate bind slot");
   for(a=0;a<2;a=a+1)begin
     if(in_fire_i[a])for(integer own=0;own<ENTRIES;own=own+1)begin
       if(in_slot_i[a*INDEX_W+:INDEX_W]==INDEX_W'(own)&&alive_q[own]&&
          tag_q[own]==in_tag_i[a*TAG_W+:TAG_W]&&!killed_w[own]&&bound_q[own])
         $fatal(1,"R64Lsu duplicate live bind");
       if(bind_mask_w[a][own]&&(func_q[own]!=input_func_w[a]||amo_q[own]!=input_amo_w[a]))
         $fatal(1,"R64Lsu bind changed reserved classification");
       if(in_slot_i[a*INDEX_W+:INDEX_W]==INDEX_W'(own)&&
          ((reserve_mask_w[0][own]&&in_tag_i[a*TAG_W+:TAG_W]==reserve_tag_i[0+:TAG_W])||
           (reserve_mask_w[1][own]&&in_tag_i[a*TAG_W+:TAG_W]==reserve_tag_i[TAG_W+:TAG_W])))
         $fatal(1,"R64Lsu bind arrived at same edge as reserve");
     end
   end
   if(mem_store_rsp_valid_i&&(!mem_issued_q[mem_store_rsp_token_i]||state_q[mem_store_rsp_token_i]!=MEMORY||
     !store_w[mem_store_rsp_token_i]||atomic_w[mem_store_rsp_token_i]||misaligned_q[mem_store_rsp_token_i]||class_q[mem_store_rsp_token_i]==2))
     $fatal(1,"R64Lsu fast store response without qualified owner");
   if(store_done_q&&!store_error_q&&(flush_i||kill_mask_i[store_tag_q[ROB_W-1:0]]))
     $fatal(1,"R64Lsu visible store cancelled before retirement");
   for(a=0;a<ENTRIES;a=a+1)if(state_q[a]==PINNED&&(alive_q[a]||effect_q[a]))
     $fatal(1,"R64Lsu committed forwarding source remained architectural owner");
   for(a=0;a<ENTRIES;a=a+1)if(killed_w[a]&&effect_q[a]&&
     !(commit_fire_i[0]&&tag_q[a]==commit_tag_i[0+:TAG_W])&&
     !(commit_fire_i[1]&&tag_q[a]==commit_tag_i[TAG_W+:TAG_W]))
     $fatal(1,"R64Lsu irrevocable external owner cancelled");
   for(a=0;a<2;a=a+1)begin
     if(query_valid_w[a]&&(!alive_q[query_slot_w[a]]||
       tag_q[query_slot_w[a]]!=query_tag_w[a*TAG_W+:TAG_W]||state_q[query_slot_w[a]]!=MEMORY))
       $fatal(1,"R64Lsu forwarding query lost canonical owner");
     if(descriptor_valid_w[a]&&
       ((descriptor_age_w[a*ENTRIES+:ENTRIES]&live_entry_w)!=(older_q[probe_slot_w[a]]&live_entry_w)))
       $fatal(1,"R64Lsu descriptor older-source relation changed on slot reuse");
     if(descriptor_valid_w[a]&&(!alive_q[probe_slot_w[a]]||
       tag_q[probe_slot_w[a]]!=descriptor_tag_w[a*TAG_W+:TAG_W]||state_q[probe_slot_w[a]]!=MEMORY))
       $fatal(1,"R64Lsu descriptor lost canonical owner");
     if(mem_rsp_valid_i[a]&&(!mem_issued_q[input_response_slot_w[a]]||state_q[input_response_slot_w[a]]!=MEMORY))
       $fatal(1,"R64Lsu physical response without owner");
     if(mfire_w[a]&&side_effect_w[physical_slot_w[a]]&&(!head_w[physical_slot_w[a]]||!effect_allow_i))
       $fatal(1,"R64Lsu unauthorized physical side effect");
   end
 end
`endif
endmodule
