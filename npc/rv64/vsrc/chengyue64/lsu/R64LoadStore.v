`include "R64Uop.vh"
// Native load/store subsystem. Translation policy and PMP/PMA are external:
// each response still belongs to the LSU's ordered translation-owner FIFO.
// Auxiliary requests have already passed their own physical protection check.
module R64LoadStore #(
 parameter EARLY_STORE=1,parameter HEAD_AUTHORIZED_QUERY=0,parameter PREPARED_CANCEL=0,parameter ENTRIES=18,parameter INDEX_W=5,parameter TAG_W=9,parameter ROB_W=5,
 parameter CACHE_SET_W=6,parameter AUX=4,parameter SRC_W=3
)(
 input clk_i,input rst_i,input flush_i,input invalidate_i,
 input [(1<<ROB_W)-1:0] kill_mask_i,
 input [(1<<ROB_W)-1:0] cancel_candidates_i,input cancel_active_i,
 input [2:0] trigger_enable_i,input [63:0] trigger_address_i,
 input head_valid_i,input [TAG_W-1:0] head_tag_i,input effect_allow_i,input fp_enable_i,input translate_active_i,
 output store_done_valid_o,input store_done_ready_i,
 output [TAG_W-1:0] store_done_tag_o,output store_done_error_o,output [63:0] store_done_tval_o,
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
 input [AUX-1:0] aux_valid_i,output [AUX-1:0] aux_ready_o,
 input [AUX*64-1:0] aux_addr_i,aux_data_i,aux_expected_i,
 input [AUX*2-1:0] aux_op_i,input [AUX-1:0] aux_cache_i,
 input [AUX*3-1:0] aux_size_i,input [AUX*8-1:0] aux_strb_i,
 output [AUX-1:0] aux_rsp_valid_o,input [AUX-1:0] aux_rsp_ready_i,
 output [AUX*64-1:0] aux_rsp_data_o,output [AUX-1:0] aux_rsp_error_o,aux_rsp_compare_o,
 output read_valid_o,input read_ready_i,output [63:0] read_addr_o,
 output [7:0] read_len_o,output [2:0] read_size_o,
 input beat_valid_i,output beat_ready_o,input [63:0] beat_data_i,
 input [1:0] beat_resp_i,input beat_last_i,
 output write_valid_o,input write_ready_i,output [63:0] write_addr_o,
 output [2:0] write_size_o,output write_data_valid_o,input write_data_ready_i,
 output [63:0] write_data_o,output [7:0] write_strb_o,
 input write_rsp_valid_i,output write_rsp_ready_o,input [1:0] write_resp_i
);
 localparam CT=INDEX_W+SRC_W;
 wire [1:0] mfast,sfast,kfast;
 wire store_response_valid_w,store_response_ready_w,store_response_error_w;
 wire [CT-1:0] store_response_token_w;
 wire [1:0] mv,mr,mcv,mcr,me,mcached;
 wire [2*INDEX_W-1:0] mt,mct;
 wire [127:0] ma,md,mcd;wire [3:0] mo;wire [5:0] mz;wire [15:0] ms;wire [9:0] mm;
 wire [1:0] sv,sr,scv,scr,se,scached;
 wire [2*INDEX_W-1:0] st,sct;wire [127:0] sa,sd,scd;
 wire [3:0] so;wire [5:0] sz,moffset;wire [15:0] ss;wire [9:0] sm;
 wire split_idle_w;wire [1:0] service_request_w;
 wire [1:0] kv,kr,kcv,kcr,ke,kcompare,kcached;
 wire [2*CT-1:0] kt,kct;
 wire [127:0] ka,kd,kexpected,kcd;wire [3:0] ko;wire [5:0] kz;wire [15:0] ks;wire [9:0] km;
 wire lsu_idle_w,lsu_drained_w,service_idle_w,cache_idle_w;
 wire unused_mutation_w;wire [60:0] unused_mutation_word_w;
 assign idle_o=lsu_idle_w&&split_idle_w&&service_idle_w&&cache_idle_w;
 assign drain_idle_o=lsu_drained_w&&split_idle_w&&service_idle_w&&cache_idle_w;
 R64Lsu #(.EARLY_STORE(EARLY_STORE),.HEAD_AUTHORIZED_QUERY(HEAD_AUTHORIZED_QUERY),.PREPARED_CANCEL(PREPARED_CANCEL),.ENTRIES(ENTRIES),.INDEX_W(INDEX_W),.TAG_W(TAG_W),.ROB_W(ROB_W)) lsu(
 .clk_i(clk_i),.rst_i(rst_i),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
 .cancel_candidates_i(cancel_candidates_i),.cancel_active_i(cancel_active_i),
 .head_valid_i(head_valid_i),.head_tag_i(head_tag_i),.effect_allow_i(effect_allow_i),.trigger_enable_i(trigger_enable_i),.trigger_address_i(trigger_address_i),.fp_enable_i(fp_enable_i),.translate_active_i(translate_active_i),
 .store_done_valid_o(store_done_valid_o),.store_done_ready_i(store_done_ready_i),
 .store_done_tag_o(store_done_tag_o),.store_done_error_o(store_done_error_o),.store_done_tval_o(store_done_tval_o),
 .mem_fast_store_o(mfast),.mem_store_rsp_valid_i(store_response_valid_w),.mem_store_rsp_ready_o(store_response_ready_w),
 .mem_store_rsp_token_i(store_response_token_w[INDEX_W-1:0]),.mem_store_rsp_error_i(store_response_error_w),
 .commit_fire_i(commit_fire_i),.commit_tag_i(commit_tag_i),
 .reserve_want_i(reserve_want_i),.reserve_fire_i(reserve_fire_i),.reserve_ready_o(reserve_ready_o),
 .reserve_slot_o(reserve_slot_o),.reserve_tag_i(reserve_tag_i),.reserve_func_i(reserve_func_i),.reserve_amo_i(reserve_amo_i),
 .in_fire_i(in_fire_i),.in_ready_o(in_ready_o),.in_slot_i(in_slot_i),.in_tag_i(in_tag_i),.in_uop_i(in_uop_i),.in_operand_i(in_operand_i),
 .out_valid_o(out_valid_o),.out_request_o(out_request_o),.out_ready_i(out_ready_i),.out_tag_o(out_tag_o),.out_result_o(out_result_o),
 .reuse_block_o(reuse_block_o),.irrevocable_o(irrevocable_o),.idle_o(lsu_idle_w),.drain_idle_o(lsu_drained_w),
 .tr_valid_o(tr_valid_o),.tr_ready_i(tr_ready_i),.tr_vaddr_o(tr_vaddr_o),.tr_access_o(tr_access_o),
 .tr_ad_update_o(tr_ad_update_o),.tr_rsp_valid_i(tr_rsp_valid_i),.tr_rsp_ready_o(tr_rsp_ready_o),
 .tr_paddr_i(tr_paddr_i),.tr_class_i(tr_class_i),.tr_fault_i(tr_fault_i),.tr_needs_ad_i(tr_needs_ad_i),
 .tr_cause_i(tr_cause_i),.tr_request_protection_o(tr_request_protection_o),.tr_owner_access_o(tr_owner_access_o),.tr_owner_size_o(tr_owner_size_o),
 .mem_valid_o(mv),.mem_ready_i(mr),.mem_token_o(mt),.mem_addr_o(ma),.mem_data_o(md),.mem_op_o(mo),
 .mem_cache_o(mcached),.mem_size_o(mz),.mem_strb_o(ms),.mem_amo_o(mm),
 .mem_rsp_valid_i(mcv),.mem_rsp_ready_o(mcr),.mem_rsp_token_i(mct),.mem_rsp_data_i(mcd),.mem_rsp_error_i(me),.mem_rsp_offset_i(moffset));
 R64MemorySplit #(.TOKEN_W(INDEX_W)) split(
 .clk_i(clk_i),.rst_i(rst_i),.physical_idle_i(service_idle_w&&cache_idle_w),.idle_o(split_idle_w),
 .in_fast_store_i(mfast),.out_fast_store_o(sfast),
 .in_valid_i(mv),.in_ready_o(mr),.in_token_i(mt),.in_addr_i(ma),.in_data_i(md),
 .in_op_i(mo),.in_cache_i(mcached),.in_size_i(mz),.in_strb_i(ms),.in_amo_i(mm),
 .rsp_valid_o(mcv),.rsp_ready_i(mcr),.rsp_token_o(mct),.rsp_data_o(mcd),.rsp_error_o(me),.rsp_offset_o(moffset),
 .out_valid_o(sv),.out_request_o(service_request_w),.out_ready_i(sr),.out_token_o(st),.out_addr_o(sa),.out_data_o(sd),
 .out_op_o(so),.out_cache_o(scached),.out_size_o(sz),.out_strb_o(ss),.out_amo_o(sm),
 .mem_rsp_valid_i(scv),.mem_rsp_ready_o(scr),.mem_rsp_token_i(sct),.mem_rsp_data_i(scd),.mem_rsp_error_i(se));
 R64MemoryService #(.TOKEN_W(INDEX_W),.AUX(AUX),.SRC_W(SRC_W),.CPU_REQUEST_HINTS(1)) service(
 .cpu_fast_store_i(sfast),.cache_fast_store_o(kfast),
 .clk_i(clk_i),.rst_i(rst_i),.cpu_valid_i(sv),.cpu_request_i(service_request_w),.cpu_ready_o(sr),.cpu_token_i(st),
 .cpu_addr_i(sa),.cpu_data_i(sd),.cpu_op_i(so),.cpu_cache_i(scached),.cpu_size_i(sz),.cpu_strb_i(ss),.cpu_amo_i(sm),
 .cpu_rsp_valid_o(scv),.cpu_rsp_ready_i(scr),.cpu_rsp_token_o(sct),.cpu_rsp_data_o(scd),.cpu_rsp_error_o(se),
 .aux_valid_i(aux_valid_i),.aux_ready_o(aux_ready_o),.aux_addr_i(aux_addr_i),.aux_data_i(aux_data_i),
 .aux_expected_i(aux_expected_i),.aux_op_i(aux_op_i),.aux_cache_i(aux_cache_i),.aux_size_i(aux_size_i),
 .aux_strb_i(aux_strb_i),.aux_rsp_valid_o(aux_rsp_valid_o),.aux_rsp_ready_i(aux_rsp_ready_i),
 .aux_rsp_data_o(aux_rsp_data_o),.aux_rsp_error_o(aux_rsp_error_o),.aux_rsp_compare_o(aux_rsp_compare_o),
 .cache_valid_o(kv),.cache_ready_i(kr),.cache_token_o(kt),.cache_addr_o(ka),.cache_data_o(kd),
 .cache_expected_o(kexpected),.cache_op_o(ko),.cache_cache_o(kcached),.cache_size_o(kz),.cache_strb_o(ks),.cache_amo_o(km),
 .cache_rsp_valid_i(kcv),.cache_rsp_ready_o(kcr),.cache_rsp_token_i(kct),.cache_rsp_data_i(kcd),
 .cache_rsp_error_i(ke),.cache_rsp_compare_i(kcompare),.idle_o(service_idle_w));
 R64Dcache #(.SET_W(CACHE_SET_W),.TOKEN_W(CT)) cache(
 .clk_i(clk_i),.rst_i(rst_i),.invalidate_i(invalidate_i),.reservation_clear_i(flush_i),
 .req_fast_store_i(kfast),.store_rsp_valid_o(store_response_valid_w),.store_rsp_ready_i(store_response_ready_w),
 .store_rsp_token_o(store_response_token_w),.store_rsp_error_o(store_response_error_w),
 .req_valid_i(kv),.req_ready_o(kr),.req_token_i(kt),.req_addr_i(ka),.req_data_i(kd),.req_expected_i(kexpected),
 .req_op_i(ko),.req_cache_i(kcached),.req_size_i(kz),.req_strb_i(ks),.req_amo_i(km),
 .rsp_valid_o(kcv),.rsp_ready_i(kcr),.rsp_token_o(kct),.rsp_data_o(kcd),.rsp_error_o(ke),.rsp_compare_o(kcompare),
 .read_valid_o(read_valid_o),.read_ready_i(read_ready_i),.read_addr_o(read_addr_o),.read_len_o(read_len_o),.read_size_o(read_size_o),
 .beat_valid_i(beat_valid_i),.beat_ready_o(beat_ready_o),.beat_data_i(beat_data_i),.beat_resp_i(beat_resp_i),.beat_last_i(beat_last_i),
 .write_valid_o(write_valid_o),.write_ready_i(write_ready_i),.write_addr_o(write_addr_o),.write_size_o(write_size_o),
 .write_data_valid_o(write_data_valid_o),.write_data_ready_i(write_data_ready_i),.write_data_o(write_data_o),.write_strb_o(write_strb_o),
 .write_rsp_valid_i(write_rsp_valid_i),.write_rsp_ready_o(write_rsp_ready_o),.write_resp_i(write_resp_i),
 .idle_o(cache_idle_w),.mutation_o(unused_mutation_w),.mutation_word_o(unused_mutation_word_w));
`ifdef R64_ASSERT
 always @(posedge clk_i)if(!rst_i&&store_response_valid_w&&store_response_token_w[CT-1:INDEX_W]!=0)
  $fatal(1,"R64LoadStore auxiliary escaped CPU store completion");
`endif
endmodule
