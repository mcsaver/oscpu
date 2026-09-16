// Elastic virtual-to-physical pipeline. Bare accesses and TLB hits sustain
// one request/cycle; only a miss occupies the shared request stage for a walk.
// Context is captured at acceptance, including effective MPRV privilege.
// An invalidation poisons a concurrent walk's TLB fill but preserves response
// ownership, so the caller can drain a cancelled operation normally.
module R64Translation #(parameter DATA_PROTECTION=0,parameter RESERVED_TERMINAL=0) (
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

 generate if(DATA_PROTECTION)begin:g_data
  R64DataTranslation #(.RESERVED_TERMINAL(RESERVED_TERMINAL)) unit(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .req_valid_i(req_valid_i),
    .req_ready_o(req_ready_o),
    .req_protection_i(req_protection_i),
    .rsp_protection_o(rsp_protection_o),
    .rsp_last_o(rsp_last_o),
    .rsp_pma_class_o(rsp_pma_class_o),.rsp_pma_fault_o(rsp_pma_fault_o),
    .req_poison_i(req_poison_i),
    .req_vaddr_i(req_vaddr_i),
    .req_access_i(req_access_i),
    .req_priv_i(req_priv_i),
    .req_mstatus_i(req_mstatus_i),
    .req_satp_i(req_satp_i),
    .req_ad_update_i(req_ad_update_i),
    .req_pbmt_enable_i(req_pbmt_enable_i),
    .rsp_valid_o(rsp_valid_o),
    .rsp_ready_i(rsp_ready_i),
    .rsp_priv_o(rsp_priv_o),
    .rsp_paddr_o(rsp_paddr_o),
    .rsp_pbmt_o(rsp_pbmt_o),
    .rsp_needs_ad_o(rsp_needs_ad_o),
    .rsp_fault_o(rsp_fault_o),
    .rsp_cause_o(rsp_cause_o),
    .invalidate_i(invalidate_i),
    .invalidate_all_vaddr_i(invalidate_all_vaddr_i),
    .invalidate_all_asid_i(invalidate_all_asid_i),
    .invalidate_vpn_i(invalidate_vpn_i),
    .invalidate_asid_i(invalidate_asid_i),
    .mem_valid_o(mem_valid_o),
    .mem_ready_i(mem_ready_i),
    .mem_compare_or_o(mem_compare_or_o),
    .mem_addr_o(mem_addr_o),
    .mem_expected_o(mem_expected_o),
    .mem_or_mask_o(mem_or_mask_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rdata_i(mem_rdata_i),
    .mem_error_i(mem_error_i),
    .mem_compare_ok_i(mem_compare_ok_i)
  );
 end else begin:g_basic
  assign rsp_pma_class_o=2'b0;assign rsp_pma_fault_o=1'b0;
  localparam [1:0] LOOKUP=0,START_WALK=1,WAIT_WALK=2;
  reg [1:0] state_q;
  reg request_valid_q;
  reg [63:0] va_q;
  reg [43:0] root_q;
  reg [15:0] asid_q;
  reg [3:0] mode_q;
  reg [1:0] access_q,priv_q;
  reg sum_q,mxr_q,ad_update_q,poison_q,pbmt_enable_q;
  reg response_valid_q,response_fault_q,response_needs_ad_q;
  reg [63:0] response_pa_q;
  reg [1:0] response_pbmt_q,response_priv_q;
  reg [4:0] response_cause_q;
  reg [3:0] protection_q,response_protection_q;
  reg [64:0] response_last_q;
  // D-side legal translated accesses do not cross a 4KiB page: ordinary
  // cross-page misalignment and all atomic misalignment are rejected by LSU.
  // Bare accesses still retain full physical carry and 64-bit overflow.
  wire [11:0] byte_delta_w=(12'b1<<protection_q[1:0])-12'd1;
  wire [12:0] last_low_w={1'b0,va_q[11:0]}+{1'b0,byte_delta_w};
  wire [64:0] bare_last_w;
  assign bare_last_w[11:0]=last_low_w[11:0];
  genvar high_bit;
   for(high_bit=12;high_bit<64;high_bit=high_bit+1)begin:g_last
   if(high_bit==12)begin:g_first
    assign bare_last_w[high_bit]=va_q[high_bit]^last_low_w[12];
   end else begin:g_prefix
    assign bare_last_w[high_bit]=va_q[high_bit]^(last_low_w[12]&&(&va_q[high_bit-1:12]));
   end
  end 
  assign bare_last_w[64]=last_low_w[12]&&(&va_q[63:12]);
  assign rsp_protection_o=response_protection_q;
  assign rsp_last_o=response_last_q;

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
  wire output_free_w=!response_valid_q||rsp_ready_i;
  wire walk_take_w=state_q==WAIT_WALK&&walk_valid_w&&output_free_w;
  wire bare_w=priv_q==3||mode_q==0;
  wire canonical_w=va_q[63:39]=={25{va_q[38]}};
  wire address_fault_w=!bare_w&&(mode_q!=8||!canonical_w);
  wire user_ok_w=priv_q==0?tlb_flags_w[4]:
                 (!tlb_flags_w[4]||(access_q!=0&&sum_q));
  wire op_ok_w=access_q==0?tlb_flags_w[3]:
               (access_q==1?(tlb_flags_w[1]||(mxr_q&&tlb_flags_w[3])):tlb_flags_w[2]);
  wire permission_fault_w=!tlb_flags_w[0]||!user_ok_w||!op_ok_w||
                          (!pbmt_enable_q&&tlb_pbmt_w!=0);
  wire ad_needed_w=!tlb_flags_w[6]||(access_q==2&&!tlb_flags_w[7]);
  wire usable_hit_w=tlb_hit_w&&!invalidate_i;
  wire terminal_w=bare_w||address_fault_w||
    (usable_hit_w&&(permission_fault_w||!ad_needed_w||!ad_update_q));
  wire [4:0] page_cause_w=access_q==0?5'd12:(access_q==1?5'd13:5'd15);
  wire req_fire_w=req_valid_i&&req_ready_o;

  assign req_ready_o=!rst_i&&!invalidate_i&&state_q==LOOKUP&&
    (!request_valid_q||(terminal_w&&output_free_w));
  assign rsp_valid_o=response_valid_q&&!rst_i;
  assign rsp_priv_o=response_priv_q;
  assign rsp_paddr_o=response_pa_q;assign rsp_pbmt_o=response_pbmt_q;
  assign rsp_needs_ad_o=response_needs_ad_q;
  assign rsp_fault_o=response_fault_q;assign rsp_cause_o=response_cause_q;

  R64Tlb u_tlb (
    .clk_i(clk_i),.rst_i(rst_i),.vaddr_i(va_q),.asid_i(asid_q),
    .hit_o(tlb_hit_w),.paddr_o(tlb_pa_w),.flags_o(tlb_flags_w),.pbmt_o(tlb_pbmt_w),
    .fill_i(walk_take_w&&!walk_fault_w&&!poison_q&&!invalidate_i),
    .fill_vpn_i(va_q[38:12]),.fill_ppn_i(walk_pte_w[53:10]),.fill_asid_i(asid_q),
    .fill_global_i(walk_global_w),.fill_level_i(walk_level_w),.fill_napot_i(walk_napot_w),
    .fill_flags_i(walk_flags_w),.fill_pbmt_i(walk_pbmt_w),
    .invalidate_i(invalidate_i),.invalidate_all_vaddr_i(invalidate_all_vaddr_i),
    .invalidate_all_asid_i(invalidate_all_asid_i),.invalidate_vpn_i(invalidate_vpn_i),
    .invalidate_asid_i(invalidate_asid_i)
  );
  R64PageWalk u_walk (
    .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(state_q==START_WALK),.req_ready_o(walk_ready_w),
    .req_vaddr_i(va_q),.req_root_ppn_i(root_q),.req_access_i(access_q),.req_priv_i(priv_q),
    .req_sum_i(sum_q),.req_mxr_i(mxr_q),.req_ad_update_i(ad_update_q),.req_pbmt_enable_i(pbmt_enable_q),
    .rsp_valid_o(walk_valid_w),.rsp_ready_i(state_q==WAIT_WALK&&output_free_w),
    .rsp_paddr_o(walk_pa_w),.rsp_flags_o(walk_flags_w),.rsp_pbmt_o(walk_pbmt_w),
    .rsp_level_o(walk_level_w),.rsp_napot_o(walk_napot_w),.rsp_global_o(walk_global_w),
    .rsp_needs_ad_o(walk_ad_w),.rsp_fault_o(walk_fault_w),.rsp_cause_o(walk_cause_w),
    .rsp_pte_addr_o(walk_pte_addr_w),.rsp_pte_o(walk_pte_w),
    .mem_valid_o(mem_valid_o),.mem_ready_i(mem_ready_i),.mem_compare_or_o(mem_compare_or_o),
    .mem_addr_o(mem_addr_o),.mem_expected_o(mem_expected_o),.mem_or_mask_o(mem_or_mask_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),.mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rdata_i(mem_rdata_i),.mem_error_i(mem_error_i),.mem_compare_ok_i(mem_compare_ok_i)
  );
  // Walk PTE flags/PPN and level are consumed by fill. Its PTE address is
  // diagnostic at this boundary; coherent atomic updates occur inside walker.
  // Global matching is resolved inside TLB; permission checks need no G bit.
  wire unused_tlb_global_w=tlb_flags_w[5];
  wire unused_walk_pte_address_w=|walk_pte_addr_w;
  wire unused_walk_pte_attributes_w=|{walk_pte_w[63:54],walk_pte_w[9:0]};

  always @(posedge clk_i) begin
    if(rst_i) begin
      state_q<=LOOKUP;request_valid_q<=0;va_q<=0;root_q<=0;asid_q<=0;mode_q<=0;
      access_q<=0;priv_q<=3;sum_q<=0;mxr_q<=0;ad_update_q<=0;poison_q<=0;pbmt_enable_q<=0;
      response_valid_q<=0;
      if(!DATA_PROTECTION)begin
       response_fault_q<=0;response_needs_ad_q<=0;
       response_pa_q<=0;response_pbmt_q<=0;response_priv_q<=3;response_cause_q<=0;
      end
    end else begin
      if(response_valid_q&&rsp_ready_i) response_valid_q<=0;
      if(invalidate_i) poison_q<=1;
      case(state_q)
        LOOKUP: if(request_valid_q) begin
          if(terminal_w) begin
            if(output_free_w) begin
              response_valid_q<=1;request_valid_q<=0;
              if(!DATA_PROTECTION)begin
               response_priv_q<=priv_q;response_pa_q<=bare_w?va_q:{8'b0,tlb_pa_w};
               response_pbmt_q<=bare_w?2'b0:tlb_pbmt_w;
               response_fault_q<=!bare_w&&(address_fault_w||permission_fault_w);
               response_needs_ad_q<=!bare_w&&!address_fault_w&&!permission_fault_w&&ad_needed_w;
               response_cause_q<=page_cause_w;
              end
            end
          end else begin state_q<=START_WALK;poison_q<=poison_q||invalidate_i;end
        end
        START_WALK: if(walk_ready_w) state_q<=WAIT_WALK;
        WAIT_WALK: if(walk_take_w) begin
          response_valid_q<=1;request_valid_q<=0;state_q<=LOOKUP;
          if(!DATA_PROTECTION)begin
           response_priv_q<=priv_q;response_pa_q<={8'b0,walk_pa_w};
           response_pbmt_q<=walk_pbmt_w;response_fault_q<=walk_fault_w;
           response_needs_ad_q<=walk_ad_w&&!walk_fault_w;response_cause_q<=walk_cause_w;
          end
        end
        default: state_q<=LOOKUP;
      endcase
      if(req_fire_w) begin
        request_valid_q<=1;va_q<=req_vaddr_i;
        if(DATA_PROTECTION)protection_q<=req_protection_i;
        // New request replaces completed LOOKUP ownership, never WAIT_WALK.
        // Preserve pre-admission invalidation across the later miss decision.
        poison_q<=req_poison_i;
        root_q<=req_satp_i[43:0];asid_q<=req_satp_i[59:44];mode_q<=req_satp_i[63:60];
        access_q<=req_access_i;
        priv_q<=req_access_i!=0&&req_priv_i==3&&req_mstatus_i[17]?
          req_mstatus_i[12:11]:req_priv_i;
        sum_q<=req_mstatus_i[18];mxr_q<=req_mstatus_i[19];ad_update_q<=req_ad_update_i;pbmt_enable_q<=req_pbmt_enable_i;
      end
    end
  end
  // D-side response storage prepares the payload of the current Q owner.
  // Only the original terminal/walk_take event publishes VALID. This keeps
  // late permission/AD qualification off the full payload write-enable tree.
  // A live stalled output retains all fields; a free/consumed slot has no
  // obligation to retain an invalid payload. No new request or stage exists.
   if(DATA_PROTECTION)begin:g_data_response
   wire walk_source_w=state_q==WAIT_WALK;
   always @(posedge clk_i)if(output_free_w)begin
    response_priv_q<=priv_q;response_protection_q<=protection_q;
    response_pa_q<=walk_source_w?{8'b0,walk_pa_w}:(bare_w?va_q:{8'b0,tlb_pa_w});
    response_pbmt_q<=walk_source_w?walk_pbmt_w:(bare_w?2'b0:tlb_pbmt_w);
    response_fault_q<=walk_source_w?walk_fault_w:(!bare_w&&(address_fault_w||permission_fault_w));
    response_needs_ad_q<=walk_source_w?(walk_ad_w&&!walk_fault_w):
      (!bare_w&&!address_fault_w&&!permission_fault_w&&ad_needed_w);
    response_cause_q<=walk_source_w?walk_cause_w:page_cause_w;
    response_last_q<=walk_source_w?{9'b0,walk_pa_w[55:12],last_low_w[11:0]}:
      (bare_w?bare_last_w:{9'b0,tlb_pa_w[55:12],last_low_w[11:0]});
   end
  end else begin:g_no_data_response
   assign response_protection_q=4'b0;
   assign response_last_q=65'b0;
  end 
  wire unused_protection_w=DATA_PROTECTION?1'b0:(|req_protection_i);
  wire unused_mstatus_w=|{req_mstatus_i[63:20],req_mstatus_i[16:13],req_mstatus_i[10:0]};
`ifdef R64_ASSERT
  always @(posedge clk_i)if(!rst_i&&DATA_PROTECTION)begin
   if(request_valid_q&&state_q==LOOKUP&&terminal_w&&output_free_w&&
      !bare_w&&!address_fault_w&&!permission_fault_w&&last_low_w[12])
    $fatal(1,"R64Translation data owner crossed page without LSU rejection");
   if(walk_take_w&&!walk_fault_w&&last_low_w[12])
    $fatal(1,"R64Translation walked data owner crossed page without LSU rejection");
   if(rsp_valid_o&&!rsp_fault_o&&
      rsp_last_o!==({1'b0,rsp_paddr_o}+(65'b1<<rsp_protection_o[1:0])-65'd1))
    $fatal(1,"R64Translation prepared endpoint changed physical range");
  end
  always @(posedge clk_i) if(!rst_i&&req_fire_w&&req_access_i==3)
    $fatal(1,"invalid translation access");
`endif

 end endgenerate
endmodule
