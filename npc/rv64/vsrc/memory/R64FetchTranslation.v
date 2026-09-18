// IF integration: fixed lookup, reserved walk descriptor, two response owners.
module R64FetchTranslation #(parameter DATA_PROTECTION=0) (
  input clk_i,input rst_i,
  input req_valid_i,output req_ready_o,
  input [3:0] req_protection_i,
  output [3:0] rsp_protection_o,output [64:0] rsp_last_o,
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

  // Fixed lookup owner. Its wide data enable depends only on Q reservation,
  // never on TLB classification or the consumer's same-cycle READY.
  reg lookup_valid_q,lookup_poison_q;
  reg [63:0] va_q;
  reg [43:0] root_q;
  reg [15:0] asid_q;
  reg [3:0] mode_q;
  reg [1:0] access_q,priv_q;
  reg sum_q,mxr_q,ad_update_q,pbmt_enable_q;
  localparam [1:0] W_IDLE=0,W_START=1,W_WAIT=2;
  reg [1:0] walk_state_q;
  // Payload is prepared whenever a lookup advances; only a miss owns it.
  reg [63:0] walk_va_q;
  reg [43:0] walk_root_q;
  reg [15:0] walk_asid_q;
  reg [1:0] walk_access_q,walk_priv_q;
  reg walk_sum_q,walk_mxr_q,walk_ad_update_q,walk_pbmt_enable_q,walk_poison_q;
  reg [74:0] response_q[0:1];
  reg response_head_q,response_tail_q;
  reg [1:0] response_count_q,reserved_q;
  wire walk_busy_w=walk_state_q!=W_IDLE;
  wire response_room_w=response_count_q<2;
  wire lookup_advance_w=lookup_valid_q&&!walk_busy_w&&response_room_w;
  wire input_room_w=reserved_q<3&&(!lookup_valid_q||(!walk_busy_w&&response_room_w));
  assign req_ready_o=!rst_i&&!invalidate_i&&input_room_w;
  wire req_fire_w=req_valid_i&&req_ready_o;
  assign rsp_valid_o=response_count_q!=0&&!rst_i;
  wire response_pop_w=rsp_valid_o&&rsp_ready_i;
  assign {rsp_priv_o,rsp_paddr_o,rsp_pbmt_o,rsp_needs_ad_o,rsp_fault_o,rsp_cause_o}=
    response_q[response_head_q];
  assign rsp_protection_o=4'b0;
  assign rsp_last_o=65'b0;

  wire tlb_hit_w;
  wire [55:0] tlb_pa_w;
  wire [7:0] tlb_flags_w;
  wire [1:0] tlb_pbmt_w;
  wire walk_ready_w,walk_valid_w,walk_fault_w,walk_napot_w,walk_global_w,walk_ad_w;
  wire [55:0] walk_pa_w,walk_pte_addr_w;
  wire [63:0] walk_pte_w;
  wire [7:0] walk_flags_w;
  wire [1:0] walk_pbmt_w,walk_level_w;
  wire [4:0] walk_cause_w;
  wire bare_w=priv_q==3||mode_q==0;
  wire canonical_w=va_q[63:39]=={25{va_q[38]}};
  wire address_fault_w=!bare_w&&(mode_q!=8||!canonical_w);
  wire user_ok_w=priv_q==0?tlb_flags_w[4]:(!tlb_flags_w[4]||(access_q!=0&&sum_q));
  wire op_ok_w=access_q==0?tlb_flags_w[3]:
    (access_q==1?(tlb_flags_w[1]||(mxr_q&&tlb_flags_w[3])):tlb_flags_w[2]);
  wire permission_fault_w=!tlb_flags_w[0]||!user_ok_w||!op_ok_w||
    (!pbmt_enable_q&&tlb_pbmt_w!=0);
  wire ad_needed_w=!tlb_flags_w[6]||(access_q==2&&!tlb_flags_w[7]);
  wire usable_hit_w=tlb_hit_w&&!invalidate_i;
  wire terminal_w=bare_w||address_fault_w||
    (usable_hit_w&&(permission_fault_w||!ad_needed_w||!ad_update_q));
  wire [4:0] page_cause_w=access_q==0?5'd12:(access_q==1?5'd13:5'd15);
  wire walk_take_w=walk_state_q==W_WAIT&&walk_valid_w&&response_room_w;
  wire terminal_take_w=lookup_advance_w&&terminal_w;
  wire response_push_w=terminal_take_w||walk_take_w;
  wire [74:0] lookup_response_w={priv_q,bare_w?va_q:{8'b0,tlb_pa_w},
    bare_w?2'b0:tlb_pbmt_w,!bare_w&&!address_fault_w&&!permission_fault_w&&ad_needed_w,
    !bare_w&&(address_fault_w||permission_fault_w),page_cause_w};
  wire [74:0] walk_response_w={walk_priv_q,8'b0,walk_pa_w,walk_pbmt_w,
    walk_ad_w&&!walk_fault_w,walk_fault_w,walk_cause_w};
  wire response_prewrite_w=response_room_w&&(lookup_advance_w||walk_state_q==W_WAIT);
  wire [74:0] response_payload_w=walk_state_q==W_WAIT?walk_response_w:lookup_response_w;
  R64Tlb u_tlb(
    .clk_i(clk_i),.rst_i(rst_i),.vaddr_i(va_q),.asid_i(asid_q),
    .hit_o(tlb_hit_w),.paddr_o(tlb_pa_w),.flags_o(tlb_flags_w),.pbmt_o(tlb_pbmt_w),
    .fill_i(walk_take_w&&!walk_fault_w&&!walk_poison_q&&!invalidate_i),
    .fill_vpn_i(walk_va_q[38:12]),.fill_ppn_i(walk_pte_w[53:10]),.fill_asid_i(walk_asid_q),
    .fill_global_i(walk_global_w),.fill_level_i(walk_level_w),.fill_napot_i(walk_napot_w),
    .fill_flags_i(walk_flags_w),.fill_pbmt_i(walk_pbmt_w),
    .invalidate_i(invalidate_i),.invalidate_all_vaddr_i(invalidate_all_vaddr_i),
    .invalidate_all_asid_i(invalidate_all_asid_i),.invalidate_vpn_i(invalidate_vpn_i),
    .invalidate_asid_i(invalidate_asid_i));
  R64PageWalk u_walk(
    .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(walk_state_q==W_START),.req_ready_o(walk_ready_w),
    .req_vaddr_i(walk_va_q),.req_root_ppn_i(walk_root_q),.req_access_i(walk_access_q),
    .req_priv_i(walk_priv_q),.req_sum_i(walk_sum_q),.req_mxr_i(walk_mxr_q),
    .req_ad_update_i(walk_ad_update_q),.req_pbmt_enable_i(walk_pbmt_enable_q),
    .rsp_valid_o(walk_valid_w),.rsp_ready_i(walk_state_q==W_WAIT&&response_room_w),
    .rsp_paddr_o(walk_pa_w),.rsp_flags_o(walk_flags_w),.rsp_pbmt_o(walk_pbmt_w),
    .rsp_level_o(walk_level_w),.rsp_napot_o(walk_napot_w),.rsp_global_o(walk_global_w),
    .rsp_needs_ad_o(walk_ad_w),.rsp_fault_o(walk_fault_w),.rsp_cause_o(walk_cause_w),
    .rsp_pte_addr_o(walk_pte_addr_w),.rsp_pte_o(walk_pte_w),
    .mem_valid_o(mem_valid_o),.mem_ready_i(mem_ready_i),.mem_compare_or_o(mem_compare_or_o),
    .mem_addr_o(mem_addr_o),.mem_expected_o(mem_expected_o),.mem_or_mask_o(mem_or_mask_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),.mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rdata_i(mem_rdata_i),.mem_error_i(mem_error_i),.mem_compare_ok_i(mem_compare_ok_i));
  always @(posedge clk_i)begin
    if(rst_i)begin
      lookup_valid_q<=0;lookup_poison_q<=0;
      va_q<=0;root_q<=0;asid_q<=0;mode_q<=0;access_q<=0;priv_q<=3;
      sum_q<=0;mxr_q<=0;ad_update_q<=0;pbmt_enable_q<=0;
      walk_state_q<=W_IDLE;walk_va_q<=0;walk_root_q<=0;walk_asid_q<=0;
      walk_access_q<=0;walk_priv_q<=3;walk_sum_q<=0;walk_mxr_q<=0;
      walk_ad_update_q<=0;walk_pbmt_enable_q<=0;walk_poison_q<=0;
      response_head_q<=0;response_tail_q<=0;response_count_q<=0;reserved_q<=0;
    end else begin
      case({req_fire_w,response_pop_w})
        2'b10:reserved_q<=reserved_q+1'b1;
        2'b01:reserved_q<=reserved_q-1'b1;
        default:begin end
      endcase
      case({response_push_w,response_pop_w})
        2'b10:response_count_q<=response_count_q+1'b1;
        2'b01:response_count_q<=response_count_q-1'b1;
        default:begin end
      endcase
      if(response_pop_w)response_head_q<=!response_head_q;
      if(response_push_w)response_tail_q<=!response_tail_q;
      if(invalidate_i)begin lookup_poison_q<=1;walk_poison_q<=1;end
      if(lookup_advance_w)begin
        lookup_valid_q<=0;
        // This wide prewrite has Q-only permission. Miss classification
        // selects ownership in walk_state, never the descriptor payload D.
        walk_va_q<=va_q;walk_root_q<=root_q;walk_asid_q<=asid_q;
        walk_access_q<=access_q;walk_priv_q<=priv_q;walk_sum_q<=sum_q;walk_mxr_q<=mxr_q;
        walk_ad_update_q<=ad_update_q;walk_pbmt_enable_q<=pbmt_enable_q;
        walk_poison_q<=lookup_poison_q||invalidate_i;
        if(!terminal_w)walk_state_q<=W_START;
      end
      if(walk_state_q==W_START&&walk_ready_w)walk_state_q<=W_WAIT;
      if(walk_take_w)walk_state_q<=W_IDLE;
      if(req_fire_w)begin
        lookup_valid_q<=1;lookup_poison_q<=req_poison_i;
        va_q<=req_vaddr_i;root_q<=req_satp_i[43:0];asid_q<=req_satp_i[59:44];mode_q<=req_satp_i[63:60];
        access_q<=req_access_i;
        priv_q<=req_access_i!=0&&req_priv_i==3&&req_mstatus_i[17]?req_mstatus_i[12:11]:req_priv_i;
        sum_q<=req_mstatus_i[18];mxr_q<=req_mstatus_i[19];
        ad_update_q<=req_ad_update_i;pbmt_enable_q<=req_pbmt_enable_i;
      end
    end
  end
  genvar row;
  generate for(row=0;row<2;row=row+1)begin:g_response_owner
    always @(posedge clk_i)begin
      if(rst_i)response_q[row]<=0;
      else if(response_prewrite_w&&response_tail_q==row[0])response_q[row]<=response_payload_w;
    end
  end endgenerate
  wire unused_inputs_w=|{req_protection_i,req_mstatus_i[63:20],req_mstatus_i[16:13],req_mstatus_i[10:0]};
  wire unused_attributes_w=|{tlb_flags_w[5],walk_pte_addr_w,walk_pte_w[63:54],walk_pte_w[9:0]};
`ifdef R64_ASSERT
  initial if(DATA_PROTECTION!=0)$fatal(1,"FetchTranslation cannot serve DATA_PROTECTION");
  always @(posedge clk_i)if(!rst_i)begin
    if({1'b0,reserved_q}!={2'b0,lookup_valid_q}+{2'b0,walk_busy_w}+{1'b0,response_count_q})
      $fatal(1,"translation reservation lost owner");
    if(({2'b0,lookup_valid_q}+{2'b0,walk_busy_w}+{1'b0,response_count_q})>3||response_count_q>2)$fatal(1,"translation capacity");
    if(req_fire_w&&lookup_valid_q&&!lookup_advance_w)$fatal(1,"lookup overwrite");
    if(response_push_w&&!response_room_w)$fatal(1,"response owner overwrite");
    if(walk_busy_w&&response_count_q==2)$fatal(1,"walk terminal reservation lost");
    if(terminal_take_w&&walk_take_w)$fatal(1,"two translation terminal owners");
    if(req_fire_w&&req_access_i==3)$fatal(1,"invalid translation access");
  end
`endif
endmodule
