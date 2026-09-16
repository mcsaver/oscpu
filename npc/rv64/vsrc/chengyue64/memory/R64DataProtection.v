// D-side range-owner stage. Last byte was prepared at Translation's existing
// response edge. This stage captures parallel range facts; only the short
// lowest-overlap decision remains between this Q boundary and LSU acceptance.
module R64DataProtection #(parameter PMA_PREPARED=0)(
 input clk_i,input rst_i,
 input req_valid_i,output req_ready_o,
 input [63:0] req_paddr_i,input [64:0] req_last_i,
 input [3:0] req_protection_i,input [1:0] req_priv_i,req_pbmt_i,
 input [1:0] req_pma_class_i,input req_pma_fault_i,
 input req_fault_i,req_needs_ad_i,input [4:0] req_cause_i,
 input [15:0] pmp_active_i,input [895:0] pmp_lower_i,pmp_upper_i,
 input [63:0] pmp_permission_i,
 output rsp_valid_o,input rsp_ready_i,output [63:0] rsp_paddr_o,
 output [1:0] rsp_class_o,output rsp_fault_o,rsp_needs_ad_o,
 output [4:0] rsp_cause_o,output [3:0] rsp_protection_o
);
 wire [4:0] size_w=5'b1<<req_protection_i[1:0];
 wire [2:0] access_w={1'b0,req_protection_i[3:2]};
 wire pma_fault_w;wire [1:0] pma_class_w;
 wire [15:0] overlap_w,deny_w;
 generate if(PMA_PREPARED)begin:g_prepared_pma
  assign pma_class_w=req_pma_class_i;assign pma_fault_w=req_pma_fault_i;
 end else begin:g_local_pma
 R64PmaRange attributes(.address_i(req_paddr_i),.last_i(req_last_i),.size_i(size_w),
  .fault_o(pma_fault_w),.class_o(pma_class_w));
 end endgenerate
 genvar entry;
 generate for(entry=0;entry<16;entry=entry+1)begin:g_range
  wire [63:0] lo_w={8'b0,pmp_lower_i[entry*56+:56]};
  wire [63:0] hi_w={8'b0,pmp_upper_i[entry*56+:56]};
  wire [3:0] permission_w=pmp_permission_i[entry*4+:4];
  assign overlap_w[entry]=pmp_active_i[entry]&&req_paddr_i<=hi_w&&req_last_i[63:0]>=lo_w;
  assign deny_w[entry]=req_paddr_i<lo_w||req_last_i[63:0]>hi_w||
   ((req_priv_i!=3||permission_w[3])&&(|(access_w&~permission_w[2:0])));
 end endgenerate
 reg valid_q;
 reg [63:0] pa_q;reg [1:0] class_q;reg [4:0] cause_q;reg [3:0] protection_q;
 reg base_fault_q,needs_ad_q,pmp_enabled_q,no_match_fault_q;
 reg [15:0] overlap_q,deny_q;
 wire [15:0] selected_deny_w;
 generate for(entry=0;entry<16;entry=entry+1)begin:g_priority
  if(entry==0)begin:g_first assign selected_deny_w[entry]=overlap_q[entry]&&deny_q[entry];end
  else begin:g_later assign selected_deny_w[entry]=overlap_q[entry]&&deny_q[entry]&&!(|overlap_q[entry-1:0]);end
 end endgenerate
 // In R64Memory the downstream credit is LSU xcount!=0, a pure Q owner
 // fact. It cannot depend on PMP result, kill, CQ or cache-ready.
 assign req_ready_o=!rst_i&&(!valid_q||rsp_ready_i);
 assign rsp_valid_o=valid_q&&!rst_i;
 assign rsp_paddr_o=pa_q;assign rsp_class_o=class_q;
 assign rsp_cause_o=cause_q;assign rsp_needs_ad_o=needs_ad_q;
 assign rsp_protection_o=protection_q;
 assign rsp_fault_o=base_fault_q||(pmp_enabled_q&&
  ((|selected_deny_w)||(!( |overlap_q)&&no_match_fault_q)));
 // Payload belongs to a valid token only. A Q-free/consumed slot can
 // prepare its next payload without waiting for input VALID or reset.
 // A held valid owner freezes every payload bit, independently of inputs.
 wire payload_credit_w=!valid_q||rsp_ready_i;
 always @(posedge clk_i)begin
  if(rst_i)valid_q<=0;
  else begin
   if(rsp_valid_o&&rsp_ready_i)valid_q<=0;
   if(req_valid_i&&req_ready_o)valid_q<=1;
  end
  if(payload_credit_w)begin
   pa_q<=req_paddr_i;protection_q<=req_protection_i;
   class_q<=(pma_class_w==2||req_pbmt_i==2)?2'd2:
     ((pma_class_w==1||req_pbmt_i==1)?2'd1:2'd0);
   cause_q<=req_fault_i?req_cause_i:(req_protection_i[3]?5'd7:5'd5);
   base_fault_q<=req_fault_i||pma_fault_w||((|access_w)&&req_last_i[64]);
   needs_ad_q<=req_needs_ad_i;pmp_enabled_q<=|access_w;no_match_fault_q<=req_priv_i!=3;
   overlap_q<=overlap_w;deny_q<=deny_w;
  end
 end
endmodule
