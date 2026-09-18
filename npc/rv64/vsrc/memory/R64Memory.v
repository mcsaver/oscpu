`include "R64Uop.vh"
// Data translation and physical memory subsystem. The two translation response
// lanes use LSU-owned access/size metadata; PTW traffic joins the same coherent
// cache as CPU memory operations after independent S-mode physical protection.
module R64Memory #(parameter HEAD_AUTHORIZED_QUERY=0,parameter PREPARED_CANCEL=0)(
 input clk_i,input rst_i,input flush_i,input invalidate_i,input [31:0] kill_mask_i,
 input [31:0] cancel_candidates_i,input cancel_active_i,
 input [2:0] trigger_enable_i,input [63:0] trigger_address_i,
 input head_valid_i,input [8:0] head_tag_i,input effect_allow_i,
 output store_done_valid_o,input store_done_ready_i,
 output [8:0] store_done_tag_o,output store_done_error_o,output [63:0] store_done_tval_o,
 input [1:0] commit_fire_i,input [17:0] commit_tag_i,
 input [1:0] reserve_want_i,reserve_fire_i,output [1:0] reserve_ready_o,
 output [9:0] reserve_slot_o,input [17:0] reserve_tag_i,
 input [15:0] reserve_func_i,input [9:0] reserve_amo_i,
 input [1:0] in_fire_i,output [1:0] in_ready_o,input [9:0] in_slot_i,
 input [17:0] in_tag_i,input [2*`R64_UOP_W-1:0] in_uop_i,input [383:0] in_operand_i,
 output [1:0] out_valid_o,output [1:0] out_request_o,input [1:0] out_ready_i,
 output [17:0] out_tag_o,output [2*`R64_RESULT_W-1:0] out_result_o,
 output [31:0] reuse_block_o,output irrevocable_o,output idle_o,output drain_idle_o,
 input [1:0] privilege_i,input [63:0] mstatus_i,satp_i,input pbmt_enable_i,
 input [15:0] pmp_active_i,input [895:0] pmp_lower_i,pmp_upper_i,input [63:0] pmp_permission_i,
 input tlb_invalidate_i,input tlb_all_vaddr_i,tlb_all_asid_i,
 input [26:0] tlb_vpn_i,input [15:0] tlb_asid_i,
 input pte_valid_i,output pte_ready_o,input pte_compare_or_i,
 input [55:0] pte_addr_i,input [63:0] pte_expected_i,pte_or_mask_i,
 output pte_rsp_valid_o,input pte_rsp_ready_i,output [63:0] pte_data_o,
 output pte_error_o,pte_compare_o,
 output read_valid_o,input read_ready_i,output [63:0] read_addr_o,
 output [7:0] read_len_o,output [2:0] read_size_o,
 input beat_valid_i,output beat_ready_o,input [63:0] beat_data_i,
 input [1:0] beat_resp_i,input beat_last_i,
 output write_valid_o,input write_ready_i,output [63:0] write_addr_o,
 output [2:0] write_size_o,output write_data_valid_o,input write_data_ready_i,
 output [63:0] write_data_o,output [7:0] write_strb_o,
 input write_rsp_valid_i,output write_rsp_ready_o,input [1:0] write_resp_i
);
 wire [1:0] effective_data_priv=(privilege_i==3&&mstatus_i[17])?mstatus_i[12:11]:privilege_i;
 wire translate_active=satp_i[63:60]==8&&effective_data_priv!=3;
 wire [1:0] tv,tr,rr,ad,needs_ad,tf,final_fault;
 wire [127:0] va,pa;wire [3:0] access_type,pbmt,effective_priv,final_class;
 wire [9:0] cause,final_cause,owner_size;wire [5:0] owner_access;
 wire [2:0] pv,pr,pcas,prv,prr,pe,pc,port_idle;
 wire [167:0] paddr;wire [191:0] pexpected,pmask,pdata;
 wire [2:0] av,ar,ac,arv,arr,ae,acompare;
 wire [191:0] aa,adta,ax,ardata;wire [5:0] aop;
 wire subsystem_idle,subsystem_drain_idle;
 assign idle_o=subsystem_idle&&(&port_idle);
 assign drain_idle_o=subsystem_drain_idle&&(&port_idle);
 assign pv[0]=pte_valid_i;assign pte_ready_o=pr[0];assign pcas[0]=pte_compare_or_i;
 assign paddr[55:0]=pte_addr_i;assign pexpected[63:0]=pte_expected_i;assign pmask[63:0]=pte_or_mask_i;
 assign pte_rsp_valid_o=prv[0];assign prr[0]=pte_rsp_ready_i;
 assign pte_data_o=pdata[63:0];assign pte_error_o=pe[0];assign pte_compare_o=pc[0];
 wire [7:0] request_protection,raw_protection,unused_final_protection;
 wire [3:0] raw_pma_class;wire [1:0] raw_pma_fault;
 wire [129:0] raw_last;wire [1:0] raw_valid,raw_ready;
 wire [127:0] final_pa;wire [1:0] protected_valid,protected_needs_ad;
 genvar g;
 generate for(g=0;g<2;g=g+1)begin:g_translation
  R64Translation #(.DATA_PROTECTION(1),.RESERVED_TERMINAL(1)) translation(
   .req_protection_i(request_protection[g*4+:4]),.rsp_protection_o(raw_protection[g*4+:4]),
   .rsp_last_o(raw_last[g*65+:65]),
   .rsp_pma_class_o(raw_pma_class[g*2+:2]),.rsp_pma_fault_o(raw_pma_fault[g]),
   .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(tv[g]),.req_ready_o(tr[g]),.req_poison_i(1'b0),
   .req_vaddr_i(va[g*64+:64]),.req_access_i(access_type[g*2+:2]),
   .req_priv_i(privilege_i),.req_mstatus_i(mstatus_i),.req_satp_i(satp_i),
   .req_ad_update_i(ad[g]),.req_pbmt_enable_i(pbmt_enable_i),
   .rsp_valid_o(raw_valid[g]),.rsp_ready_i(raw_ready[g]),.rsp_priv_o(effective_priv[g*2+:2]),
   .rsp_paddr_o(pa[g*64+:64]),.rsp_pbmt_o(pbmt[g*2+:2]),
   .rsp_needs_ad_o(needs_ad[g]),.rsp_fault_o(tf[g]),.rsp_cause_o(cause[g*5+:5]),
   .invalidate_i(tlb_invalidate_i),.invalidate_all_vaddr_i(tlb_all_vaddr_i),
   .invalidate_all_asid_i(tlb_all_asid_i),.invalidate_vpn_i(tlb_vpn_i),.invalidate_asid_i(tlb_asid_i),
   .mem_valid_o(pv[g+1]),.mem_ready_i(pr[g+1]),.mem_compare_or_o(pcas[g+1]),
   .mem_addr_o(paddr[(g+1)*56+:56]),.mem_expected_o(pexpected[(g+1)*64+:64]),
   .mem_or_mask_o(pmask[(g+1)*64+:64]),.mem_rsp_valid_i(prv[g+1]),
   .mem_rsp_ready_o(prr[g+1]),.mem_rdata_i(pdata[(g+1)*64+:64]),
   .mem_error_i(pe[g+1]),.mem_compare_ok_i(pc[g+1]));
  // LSU reserves terminal ownership at the actual translation request fire.
  // Every protected VALID still has its counted owner, so the existing
  // assertion below proves the downstream has unconditional reserved credit.
  // Only this native instantiation reserves its terminal; generic helpers retain backpressure.
  R64DataProtection #(.PMA_PREPARED(1)) protection(
   .req_pma_class_i(raw_pma_class[g*2+:2]),.req_pma_fault_i(raw_pma_fault[g]),
   .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(raw_valid[g]),.req_ready_o(raw_ready[g]),
   .req_paddr_i(pa[g*64+:64]),.req_last_i(raw_last[g*65+:65]),
   .req_protection_i(raw_protection[g*4+:4]),.req_priv_i(effective_priv[g*2+:2]),.req_pbmt_i(pbmt[g*2+:2]),
   .req_fault_i(tf[g]),.req_needs_ad_i(needs_ad[g]),.req_cause_i(cause[g*5+:5]),
   .pmp_active_i(pmp_active_i),.pmp_lower_i(pmp_lower_i),.pmp_upper_i(pmp_upper_i),
   .pmp_permission_i(pmp_permission_i),.rsp_valid_o(protected_valid[g]),.rsp_ready_i(1'b1),
   .rsp_paddr_o(final_pa[g*64+:64]),.rsp_class_o(final_class[g*2+:2]),
   .rsp_fault_o(final_fault[g]),.rsp_needs_ad_o(protected_needs_ad[g]),.rsp_cause_o(final_cause[g*5+:5]),
   .rsp_protection_o(unused_final_protection[g*4+:4]));
`ifdef R64_ASSERT
  always @(posedge clk_i)if(!rst_i&&protected_valid[g])begin
   if(!rr[g])$fatal(1,"R64Memory protected response lost canonical LSU owner credit");
   if(owner_size[g*5+:5]!=(5'b1<<unused_final_protection[g*4+:2])||
      owner_access[g*3+:3]!={1'b0,unused_final_protection[g*4+2+:2]})
    $fatal(1,"R64Memory protected response crossed translation owner attributes");
  end
`endif
 end
 for(g=0;g<3;g=g+1)begin:g_pte
  R64PtePort port(
   .clk_i(clk_i),.rst_i(rst_i),.req_valid_i(pv[g]),.req_ready_o(pr[g]),
   .req_compare_or_i(pcas[g]),.req_addr_i(paddr[g*56+:56]),
   .req_expected_i(pexpected[g*64+:64]),.req_or_mask_i(pmask[g*64+:64]),
   .rsp_valid_o(prv[g]),.rsp_ready_i(prr[g]),.rsp_data_o(pdata[g*64+:64]),
   .rsp_error_o(pe[g]),.rsp_compare_o(pc[g]),.pmp_active_i(pmp_active_i),
   .pmp_lower_i(pmp_lower_i),.pmp_upper_i(pmp_upper_i),.pmp_permission_i(pmp_permission_i),
   .service_valid_o(av[g]),.service_ready_i(ar[g]),.service_addr_o(aa[g*64+:64]),
   .service_data_o(adta[g*64+:64]),.service_expected_o(ax[g*64+:64]),
   .service_op_o(aop[g*2+:2]),.service_cache_o(ac[g]),
   .service_rsp_valid_i(arv[g]),.service_rsp_ready_o(arr[g]),
   .service_rsp_data_i(ardata[g*64+:64]),.service_rsp_error_i(ae[g]),
   .service_rsp_compare_i(acompare[g]),.idle_o(port_idle[g]));
 end endgenerate
 R64LoadStore #(.ENTRIES(20),.HEAD_AUTHORIZED_QUERY(HEAD_AUTHORIZED_QUERY),.PREPARED_CANCEL(PREPARED_CANCEL),.AUX(3),.SRC_W(2)) unit(
  .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.invalidate_i(invalidate_i),.kill_mask_i(kill_mask_i),
  .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
  .trigger_enable_i(trigger_enable_i),.trigger_address_i(trigger_address_i),.fp_enable_i(mstatus_i[14:13]!=0),.translate_active_i(translate_active),
  .head_valid_i(head_valid_i),.head_tag_i(head_tag_i),.effect_allow_i(effect_allow_i),
  .store_done_valid_o(store_done_valid_o),.store_done_ready_i(store_done_ready_i),
  .store_done_tag_o(store_done_tag_o),.store_done_error_o(store_done_error_o),.store_done_tval_o(store_done_tval_o),
  .commit_fire_i(commit_fire_i),.commit_tag_i(commit_tag_i),
  .in_fire_i(in_fire_i),.in_ready_o(in_ready_o),.in_slot_i(in_slot_i),
  .reserve_want_i(reserve_want_i),.reserve_fire_i(reserve_fire_i),
  .reserve_ready_o(reserve_ready_o),.reserve_slot_o(reserve_slot_o),
  .reserve_tag_i(reserve_tag_i),.reserve_func_i(reserve_func_i),
  .reserve_amo_i(reserve_amo_i),
  .in_tag_i(in_tag_i),.in_uop_i(in_uop_i),.in_operand_i(in_operand_i),
  .out_valid_o(out_valid_o),.out_request_o(out_request_o),.out_ready_i(out_ready_i),.out_tag_o(out_tag_o),.out_result_o(out_result_o),
  .reuse_block_o(reuse_block_o),.irrevocable_o(irrevocable_o),.idle_o(subsystem_idle),.drain_idle_o(subsystem_drain_idle),
  .tr_valid_o(tv),.tr_ready_i(tr),.tr_vaddr_o(va),.tr_access_o(access_type),.tr_ad_update_o(ad),
  .tr_rsp_valid_i(protected_valid),.tr_rsp_ready_o(rr),.tr_paddr_i(final_pa),.tr_class_i(final_class),
  .tr_fault_i(final_fault),.tr_needs_ad_i(protected_needs_ad),.tr_cause_i(final_cause),
  .tr_request_protection_o(request_protection),.tr_owner_access_o(owner_access),.tr_owner_size_o(owner_size),
  .aux_valid_i(av),.aux_ready_o(ar),.aux_addr_i(aa),.aux_data_i(adta),.aux_expected_i(ax),
  .aux_op_i(aop),.aux_cache_i(ac),.aux_size_i({3{3'd3}}),.aux_strb_i(24'hffffff),
  .aux_rsp_valid_o(arv),.aux_rsp_ready_i(arr),.aux_rsp_data_o(ardata),.aux_rsp_error_o(ae),
  .aux_rsp_compare_o(acompare),.read_valid_o(read_valid_o),.read_ready_i(read_ready_i),
  .read_addr_o(read_addr_o),.read_len_o(read_len_o),.read_size_o(read_size_o),
  .beat_valid_i(beat_valid_i),.beat_ready_o(beat_ready_o),.beat_data_i(beat_data_i),
  .beat_resp_i(beat_resp_i),.beat_last_i(beat_last_i),
  .write_valid_o(write_valid_o),.write_ready_i(write_ready_i),.write_addr_o(write_addr_o),
  .write_size_o(write_size_o),.write_data_valid_o(write_data_valid_o),.write_data_ready_i(write_data_ready_i),
  .write_data_o(write_data_o),.write_strb_o(write_strb_o),
  .write_rsp_valid_i(write_rsp_valid_i),.write_rsp_ready_o(write_rsp_ready_o),.write_resp_i(write_resp_i));
endmodule
