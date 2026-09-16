`include "R64Uop.vh"
// Native 2-wide backend: one birth allocates ROB, rename, IQ and MEM LSQ owner.
// Only canonical ROB-accepted completion tuples write/wake the PRF. All
// external effects belong to tagged LSU/FP/serial owners beyond their ingress.
module R64Backend #(parameter TAG_W=9,parameter ROB_W=5,parameter PREDECODED=0,parameter PREPARED_NPC=0,parameter PRECONTROLLED=0,parameter LSQ_W=5,parameter DIRECT_MEM_BIND=0,parameter EARLY_ALU_WAKE=1,parameter WB_DEFER_REQUEST=0,parameter WB_REQUEST_HINTS=0,parameter RR_ALU_BYPASS=1,parameter ISSUE_SLOTS=16)(
  input clk,input rst,input flush_i,input stop_i,input serial_allow_i,
  input [(1<<ROB_W)-1:0] reuse_block_i,
  input [1:0] fetch_valid_i,output [1:0] fetch_ready_o,
  input [65:0] fetch_canonical_i,input [69:0] fetch_control_i,input [127:0] fetch_sequential_npc_i,
  input [127:0] fetch_pc_i,fetch_raw_i,fetch_pred_npc_i,
  input [7:0] fetch_length_i,
  input [1:0] fetch_exception_i,input [11:0] fetch_cause_i,input [127:0] fetch_tval_i,
  input [1:0] commit_ready_i,input commit1_allow_i,
  output [1:0] commit_valid_o,output [1:0] commit_serial_o,output [2*TAG_W-1:0] commit_tag_o,
  output [2*`R64_META_W-1:0] commit_meta_o,
  output [127:0] commit_data_o,output [1:0] commit_exception_o,
  output [11:0] commit_cause_o,output [127:0] commit_tval_o,output [9:0] commit_fflags_o,
  output [1:0] commit_rd_write_o,commit_rd_fp_o,output [9:0] commit_rd_arch_o,
  output redirect_valid_o,output [63:0] redirect_pc_o,
  output resolve_valid_o,output [TAG_W-1:0] resolve_tag_o,
  output [63:0] resolve_pc_o,resolve_npc_o,
  output resolve_conditional_o,resolve_indirect_o,resolve_taken_o,
  output [(1<<ROB_W)-1:0] kill_mask_o,cancel_candidates_o,output cancel_active_o,
  output [TAG_W-1:0] head_tag_o,output head_serial_o,output head_exception_o,output [ROB_W:0] rob_count_o,output recover_o,
  // LSQ ownership is allocated atomically with ROB/rename/IQ birth.
  output [1:0] lsu_reserve_want_o,output [1:0] lsu_reserve_fire_o,
  output [2*TAG_W-1:0] lsu_reserve_tag_o,
  output [15:0] lsu_reserve_func_o,output [9:0] lsu_reserve_amo_o,
  input [1:0] lsu_reserve_ready_i,input [2*LSQ_W-1:0] lsu_reserve_slot_i,
  input [1:0] lsu_ready_i,output [1:0] lsu_fire_o,
  output [2*TAG_W-1:0] lsu_tag_o,output [2*`R64_UOP_W-1:0] lsu_uop_o,
  output [383:0] lsu_operand_o,output [2*LSQ_W-1:0] lsu_slot_o,
  input fp_ready_i,output fp_fire_o,output [TAG_W-1:0] fp_tag_o,
  output [`R64_UOP_W-1:0] fp_uop_o,output [191:0] fp_operand_o,
  input serial_ready_i,output serial_fire_o,output [TAG_W-1:0] serial_tag_o,
  output [`R64_UOP_W-1:0] serial_uop_o,output [191:0] serial_operand_o,
  // Result lanes: LSU0, LSU1, FP, serial. VALID/payload remain stable until
  // READY, except an explicit kill/flush cancellation by the external owner.
  // Narrow precise terminal for the irrevocable ordinary store at ROB head.
  input store_done_valid_i,output store_done_ready_o,
  input [TAG_W-1:0] store_done_tag_i,input store_done_error_i,input [63:0] store_done_tval_i,
  input [3:0] external_valid_i,external_request_i,output [3:0] external_ready_o,
  input [4*TAG_W-1:0] external_tag_i,
  input [4*`R64_RESULT_W-1:0] external_result_i
);
  localparam P=6,U=`R64_UOP_W,M=`R64_META_W,R=`R64_RESULT_W;
  wire [2*U-1:0] decode_uop_w;
  wire [2*M-1:0] decode_meta_w;
  wire [5:0] decode_class_w,src_fp_w,src_used_w;
  wire [1:0] rd_write_w,rd_fp_w,serial_w;
  wire [9:0] rd_arch_w;
  wire [29:0] src_arch_w;
  genvar l;
  wire [1:0] decode_valid_w,decode_query_valid_w;
  wire [1:0] rob_credit_w,rename_credit_w,issue_credit_w;
  wire birth0_w=decode_valid_w[0]&&!stop_i&&rob_credit_w[0]&&rename_credit_w[0]&&issue_credit_w[0]&&(!lsu_reserve_want_o[0]||lsu_reserve_ready_i[0]);
  wire birth1_w=decode_valid_w[1]&&birth0_w&&rob_credit_w[1]&&rename_credit_w[1]&&issue_credit_w[1]&&(!lsu_reserve_want_o[1]||lsu_reserve_ready_i[1]);
  wire [1:0] birth_w={birth1_w,birth0_w};
  // Capacity is a read-only query about the Q-owned decode prefix.
  // Reset/clear/stop qualify the canonical birth, never this FREE query.
  // A cancelled raw want cannot reserve a slot or create an instruction.
  assign lsu_reserve_want_o=decode_query_valid_w&{decode_class_w[3+:3]==`R64_C_MEM,decode_class_w[0+:3]==`R64_C_MEM};
  assign lsu_reserve_fire_o=birth_w&lsu_reserve_want_o;
  assign lsu_reserve_tag_o=birth_tag_w;
  assign lsu_reserve_func_o={decode_uop_w[U+196+:8],decode_uop_w[196+:8]};
  assign lsu_reserve_amo_o={decode_uop_w[U+155+:5],decode_uop_w[155+:5]};
  // The queue owns decoded, unborn instructions. Physical destinations and
  // full ROB tags are still allocated together on the actual birth edge.
  R64DecodeStage #(.PREDECODED(PREDECODED),.PREPARED_NPC(PREPARED_NPC),.PRECONTROLLED(PRECONTROLLED)) decode_stage(
    .canonical_i(fetch_canonical_i),.control_i(fetch_control_i),.sequential_npc_i(fetch_sequential_npc_i),
    .clk(clk),.rst(rst),.clear_i(flush_i||redirect_valid_o),.stop_i(stop_i),
    .in_valid_i(fetch_valid_i),.in_ready_o(fetch_ready_o),
    .pc_i(fetch_pc_i),.raw_i(fetch_raw_i),.pred_npc_i(fetch_pred_npc_i),
    .length_i(fetch_length_i),.exception_i(fetch_exception_i),
    .cause_i(fetch_cause_i),.tval_i(fetch_tval_i),
    .out_valid_o(decode_valid_w),.query_valid_o(decode_query_valid_w),.out_take_i(birth_w),
    .uop_o(decode_uop_w),.meta_o(decode_meta_w),.class_o(decode_class_w),
    .rd_write_o(rd_write_w),.rd_fp_o(rd_fp_w),.rd_arch_o(rd_arch_w),
    .src_arch_o(src_arch_w),.src_fp_o(src_fp_w),.src_used_o(src_used_w),
    .serial_o(serial_w));
  wire [2*TAG_W-1:0] birth_tag_w;
  wire [2*P-1:0] pnew_w,pold_w;
  wire [6*P-1:0] src_preg_w;
  wire [5:0] src_ready_w;
  localparam WB_OWNER_BANKS=1<<((ROB_W>2)?2:0),WB_CERT_W=P+3;
  wire [2*TAG_W-1:0] wb_owner_query_tag_w;
  wire [2*WB_OWNER_BANKS*WB_CERT_W-1:0] wb_owner_query_cert_w;
  wire [2*WB_CERT_W-1:0] wb_owner_cert_w;
  wire [1:0] wb_valid_w,wb_accept_w,wb_write_w,wb_fp_w;
  wire [2*TAG_W-1:0] wb_tag_w;
  wire [2*R-1:0] wb_result_w;
  wire [2*P-1:0] wb_preg_w;
  wire [127:0] wb_data_w,wb_tval_w;
  wire [1:0] wb_exception_w;
  wire [11:0] wb_cause_w;
  wire [9:0] wb_fflags_w;
  generate for(l=0;l<2;l=l+1)begin:gen_wb_fields
    assign wb_data_w[l*64+:64]=wb_result_w[l*R+:64];
    assign wb_exception_w[l]=wb_result_w[l*R+64];
    assign wb_cause_w[l*6+:6]=wb_result_w[l*R+65+:6];
    assign wb_tval_w[l*64+:64]=wb_result_w[l*R+71+:64];
    assign wb_fflags_w[l*5+:5]=wb_result_w[l*R+135+:5];
  end endgenerate
  wire [1:0] commit_fire_w=commit_valid_o&commit_ready_i;
  wire [2*P-1:0] commit_pnew_w,commit_pold_w;
  wire [1:0] undo_valid_w,undo_write_w,undo_fp_w;
  wire [9:0] undo_arch_w;
  wire [2*P-1:0] undo_pnew_w,undo_pold_w;
  wire [ROB_W-1:0] head_slot_w,barrier_slot_w;
  wire [(1<<ROB_W)-1:0] serial_active_w,serial_release_w;
  wire barrier_valid_w;
  wire [(1<<ROB_W)-1:0] cancel_candidates_w;wire cancel_active_w;
  assign cancel_candidates_o=cancel_candidates_w;assign cancel_active_o=cancel_active_w;
  wire redirect_pending_w;
  wire recovery_preview_valid_w;wire [TAG_W-1:0] recovery_preview_tag_w;
  R64Rob #(.OWNER_CERTIFICATE(1),.SERIAL_PAYLOAD(1),.HEAD_SERIAL_CACHE(1),.LOCAL_KILL_FREEZE(1),.INDEX_W(ROB_W),.GEN_W(TAG_W-ROB_W),.META_W(M)) rob(
    .owner_query_tag_i(wb_owner_query_tag_w),.owner_query_cert_o(wb_owner_query_cert_w),
    .wb_owner_cert_i(wb_owner_cert_w),
    .recovery_preview_valid_i(recovery_preview_valid_w),.recovery_preview_tag_i(recovery_preview_tag_w),
    .store_done_valid_i(store_done_valid_i),.store_done_ready_o(store_done_ready_o),
    .store_done_tag_i(store_done_tag_i),.store_done_error_i(store_done_error_i),.store_done_tval_i(store_done_tval_i),
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_pending_i(redirect_pending_w),.kill_valid_i(redirect_valid_o),.kill_tag_i(resolve_tag_o),
    .reuse_block_i(reuse_block_i),.resolve_valid_i(resolve_valid_o),
    .resolve_tag_i(resolve_tag_o),.resolve_npc_i(resolve_npc_o),
    .alloc_valid_i(birth_w),.alloc_ready_o(rob_credit_w),.alloc_tag_o(birth_tag_w),
    .alloc_meta_i(decode_meta_w),.alloc_rd_write_i(rd_write_w),.alloc_rd_fp_i(rd_fp_w),
    .alloc_serial_i(serial_w),.alloc_rd_arch_i(rd_arch_w),.alloc_pnew_i(pnew_w),.alloc_pold_i(pold_w),
    .wb_valid_i(wb_valid_w),.wb_tag_i(wb_tag_w),.wb_data_i(wb_data_w),
    .wb_exception_i(wb_exception_w),.wb_cause_i(wb_cause_w),.wb_tval_i(wb_tval_w),
    .wb_fflags_i(wb_fflags_w),.short_valid_i({raw_alu_bypass_valid_w,raw_early_valid_w}),
    .short_tag_i({local_tag_w[0+:2*TAG_W],early_tag_w}),
    .short_preg_i({alu_bypass_preg_w,early_preg_w}),.short_accept_o({alu_bypass_valid_w,early_valid_w}),
    .wb_accept_o(wb_accept_w),.wb_rd_write_o(wb_write_w),
    .wb_rd_fp_o(wb_fp_w),.wb_preg_o(wb_preg_w),
    .commit_ready_i(commit_ready_i),.commit1_allow_i(commit1_allow_i),
    .commit_valid_o(commit_valid_o),.commit_serial_o(commit_serial_o),.commit_tag_o(commit_tag_o),.commit_meta_o(commit_meta_o),
    .commit_data_o(commit_data_o),.commit_exception_o(commit_exception_o),
    .commit_cause_o(commit_cause_o),.commit_tval_o(commit_tval_o),.commit_fflags_o(commit_fflags_o),
    .commit_rd_write_o(commit_rd_write_o),.commit_rd_fp_o(commit_rd_fp_o),.commit_rd_arch_o(commit_rd_arch_o),
    .commit_pnew_o(commit_pnew_w),.commit_pold_o(commit_pold_w),
    .undo_valid_o(undo_valid_w),.undo_rd_write_o(undo_write_w),.undo_rd_fp_o(undo_fp_w),
    .undo_rd_arch_o(undo_arch_w),.undo_pnew_o(undo_pnew_w),.undo_pold_o(undo_pold_w),
    .cancel_candidates_o(cancel_candidates_w),.cancel_active_o(cancel_active_w),
    .kill_mask_o(kill_mask_o),.recover_o(recover_o),.head_exception_o(head_exception_o),.count_o(rob_count_o),.head_slot_o(head_slot_w),
    .serial_valid_o(barrier_valid_w),.serial_slot_o(barrier_slot_w),
    .serial_active_o(serial_active_w),.serial_release_o(serial_release_w));
  assign head_tag_o=commit_tag_o[0+:TAG_W];
  // Resident ROB state, independent of completion, retirement and recovery.
  // Commit uses this only to stop younger births behind a serial head.
  assign head_serial_o=serial_active_w[head_slot_w];
  wire [6*P-1:0] ready_query_preg_w;
  wire [5:0] ready_query_fp_w,ready_query_canonical_w,ready_query_complete_w;
  R64Rename rename(
    .ready_query_preg_i(ready_query_preg_w),.ready_query_fp_i(ready_query_fp_w),
    .ready_query_ready_o(ready_query_canonical_w),.clk(clk),.rst(rst),.restore_i(flush_i),
    .request_valid_i(decode_query_valid_w),.rd_write_i(rd_write_w),.rd_fp_i(rd_fp_w),.rd_arch_i(rd_arch_w),
    .src_arch_i(src_arch_w),.src_fp_i(src_fp_w),.src_used_i(src_used_w),
    .alloc_ready_o(rename_credit_w),.pnew_o(pnew_w),.pold_o(pold_w),
    .src_preg_o(src_preg_w),.src_ready_o(src_ready_w),.alloc_fire_i(birth_w),
    .wb_accept_i(wb_write_w),.wb_fp_i(wb_fp_w),.wb_preg_i(wb_preg_w),
    .commit_fire_i(commit_fire_w),.commit_rd_write_i(commit_rd_write_o),.commit_rd_fp_i(commit_rd_fp_o),
    .commit_rd_arch_i(commit_rd_arch_o),.commit_pnew_i(commit_pnew_w),.commit_pold_i(commit_pold_w),
    .undo_valid_i(undo_valid_w),.undo_rd_write_i(undo_write_w),.undo_rd_fp_i(undo_fp_w),
    .undo_rd_arch_i(undo_arch_w),.undo_pnew_i(undo_pnew_w),.undo_pold_i(undo_pold_w));
  wire [1:0] issue_fire_w,read_credit_w,read_valid_w,execute_ready_w;
  wire [2*TAG_W-1:0] issue_tag_w,read_tag_w;
  wire [2*LSQ_W-1:0] issue_mem_slot_w,read_mem_slot_w;
  wire [2*U-1:0] issue_uop_w,read_uop_w;
  wire [5:0] issue_class_w,issue_fp_w,issue_used_w,read_class_w;
  wire [6*P-1:0] issue_src_w;
  wire [2*(3*P+8)-1:0] issue_fp_plan_w;
  wire [383:0] read_operand_w;
  wire [5:0] read_fu_credit_w;
  wire [2*P-1:0] short_dst_w,issue_dst_w,read_dst_w,early_preg_w,alu_bypass_preg_w;
  wire [1:0] early_valid_w,alu_bypass_valid_w,raw_early_valid_w,raw_alu_bypass_valid_w;
  wire [2*TAG_W-1:0] early_tag_w;
  wire [73:0] read_alu_control_w;wire [9:0] read_add_source_w;wire [11:0] read_shift_amount_w;
  wire [41:0] read_branch_imm_w;wire [9:0] read_branch_control_w;
  wire [127:0] alu_bypass_data_w;
  wire [5:0] birth_src_ready_w;
  generate for(l=0;l<2;l=l+1)begin:gen_short_destination
    assign short_dst_w[l*P+:P]=rd_write_w[l]&&!rd_fp_w[l]&&
        (decode_class_w[l*3+:3]==`R64_C_ALU||decode_class_w[l*3+:3]==`R64_C_BRANCH) ?
        pnew_w[l*P+:P]:{P{1'b0}};
  end
  for(l=0;l<6;l=l+1)begin:gen_birth_early_ready
    // Existing IQ entries saw the producer's fire pulse. New entries born
    // after that pulse can see its held result until canonical WB arrives.
    assign birth_src_ready_w[l]=src_ready_w[l];
    assign ready_query_complete_w[l]=ready_query_canonical_w[l]||(!ready_query_fp_w[l]&&
        ((alu_bypass_valid_w[0]&&ready_query_preg_w[l*P+:P]==alu_bypass_preg_w[0+:P])||
         (alu_bypass_valid_w[1]&&ready_query_preg_w[l*P+:P]==alu_bypass_preg_w[P+:P])));
  end endgenerate
`ifdef R64_ASSERT
  integer early_check;
  always @(posedge clk) if(!rst&&!flush_i)begin
    for(early_check=0;early_check<2;early_check=early_check+1)
      if(early_valid_w[early_check])begin
        if(!rob.valid_q[early_tag_w[early_check*TAG_W+:ROB_W]]||
            rob.generation_q[early_tag_w[early_check*TAG_W+:ROB_W]]!=
              early_tag_w[early_check*TAG_W+ROB_W+:TAG_W-ROB_W]||
            rob.pnew_q[early_tag_w[early_check*TAG_W+:ROB_W]]!=early_preg_w[early_check*P+:P]||
            !rob.rd_write_q[early_tag_w[early_check*TAG_W+:ROB_W]]||
            rob.rd_fp_q[early_tag_w[early_check*TAG_W+:ROB_W]])
          $fatal(1,"R64 early ALU destination disagrees with live canonical owner");
      end
    if(early_valid_w==3&&early_preg_w[0+:P]==early_preg_w[P+:P])
      $fatal(1,"R64 two live early ALUs own the same physical destination");
  end
  always @(posedge clk)if(!rst)begin
    if((lsu_reserve_fire_o&~lsu_reserve_ready_i)!=0)
      $fatal(1,"R64 LSQ reserve without Q credit");
    if(flush_i&&lsu_reserve_fire_o!=0)
      $fatal(1,"R64 LSQ birth survived flush");
    if(lsu_reserve_fire_o==3&&lsu_reserve_slot_i[0+:LSQ_W]==lsu_reserve_slot_i[LSQ_W+:LSQ_W])
      $fatal(1,"R64 dual MEM birth shares LSQ slot");
  end
`endif
  R64Issue #(.N(ISSUE_SLOTS),.SLOT_W($clog2(ISSUE_SLOTS)),.MDU_RESOURCE_PAIR(1),.DEFER_READY(1),.PREPARED_CANCEL(1),.ROB_W(ROB_W),.TAG_W(TAG_W),.PAYLOAD_W(U),.LSQ_W(LSQ_W)) issue(
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_o),.cancel_candidates_i(cancel_candidates_w),.cancel_active_i(cancel_active_w),.rob_head_i(head_slot_w),
    .barrier_valid_i(barrier_valid_w),.barrier_slot_i(barrier_slot_w),
    .serial_active_i(serial_active_w),.serial_release_i(serial_release_w),
    .enq_valid_i(birth_w),.enq_ready_o(issue_credit_w),.enq_tag_i(birth_tag_w),
    .enq_mem_slot_i(lsu_reserve_slot_i),.enq_payload_i(decode_uop_w),.enq_class_i(decode_class_w),.enq_gpr_dst_i(short_dst_w),.enq_src_preg_i(src_preg_w),
    .enq_src_fp_i(src_fp_w),.enq_src_used_i(src_used_w),.enq_src_ready_i(6'b0),
    .ready_query_preg_o(ready_query_preg_w),.ready_query_fp_o(ready_query_fp_w),
    .ready_query_ready_i(ready_query_complete_w),
    .wake_valid_i(wb_write_w),.wake_fp_i(wb_fp_w),.wake_preg_i(wb_preg_w),
    .early_valid_i(early_valid_w),.early_preg_i(early_preg_w),
    .fu_allow_i(6'b111111),.serial_allow_i(serial_allow_i),.issue_ready_i(read_credit_w),
    .issue_mem_slot_o(issue_mem_slot_w),.issue_fire_o(issue_fire_w),.issue_tag_o(issue_tag_w),.issue_payload_o(issue_uop_w),
    .issue_class_o(issue_class_w),.issue_gpr_dst_o(issue_dst_w),.issue_src_preg_o(issue_src_w),
    .issue_fp_plan_o(issue_fp_plan_w),.issue_src_fp_o(issue_fp_w),.issue_src_used_o(issue_used_w),.count_o());
  R64RegRead #(.ALU_TERMINAL_BYPASS(RR_ALU_BYPASS),.PREQUALIFIED_ISSUE(1),.Q_ONLY_TERMINAL(1),.PREPARED_CANCEL(1),.COMPACT_FP(1),.RAW_FP_ALLOCATION(1),.UNIQUE_SERIAL(1),.ROB_W(ROB_W),.TAG_W(TAG_W),.PAYLOAD_W(U),.LSQ_W(LSQ_W)) registers(
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_o),.cancel_candidates_i(cancel_candidates_w),.cancel_active_i(cancel_active_w),
    .fu_credit_i(read_fu_credit_w),.in_mem_slot_i(issue_mem_slot_w),.out_mem_slot_o(read_mem_slot_w),.in_fire_i(issue_fire_w),.in_ready_o(read_credit_w),.in_tag_i(issue_tag_w),.in_payload_i(issue_uop_w),
    .in_fp_plan_i(issue_fp_plan_w),.in_class_i(issue_class_w),.in_gpr_dst_i(issue_dst_w),.in_src_preg_i(issue_src_w),.in_src_fp_i(issue_fp_w),.in_src_used_i(issue_used_w),
    .wb_write_i(wb_write_w),.wb_fp_i(wb_fp_w),.wb_preg_i(wb_preg_w),.wb_data_i(wb_data_w),
    .out_valid_o(read_valid_w),.out_ready_i(execute_ready_w),.out_tag_o(read_tag_w),
    .out_payload_o(read_uop_w),.out_alu_control_o(read_alu_control_w),.out_add_source_o(read_add_source_w),.out_shift_amount_o(read_shift_amount_w),.out_branch_imm_o(read_branch_imm_w),.out_branch_control_o(read_branch_control_w),.out_class_o(read_class_w),.out_operand_o(read_operand_w),.out_gpr_dst_o(read_dst_w),
    .alu_bypass_valid_i(alu_bypass_valid_w),.alu_bypass_preg_i(alu_bypass_preg_w),.alu_bypass_data_i(alu_bypass_data_w));
  wire [4:0] local_valid_w,local_ready_w;
  wire [5*TAG_W-1:0] local_tag_w;
  wire [5*R-1:0] local_result_w;
`ifdef R64_ASSERT
  // Raw FP/MEM projection is valid only inside the same live ROB age window.
  always @(posedge clk)if(!rst&&!flush_i)begin
    for(integer f=0;f<2;f=f+1)if(read_valid_w[f]&&(read_class_w[f*3+:3]==`R64_C_FP||read_class_w[f*3+:3]==`R64_C_MEM))begin
      if(!rob.valid_q[read_tag_w[f*TAG_W+:ROB_W]]||
         rob.generation_q[read_tag_w[f*TAG_W+:ROB_W]]!=read_tag_w[f*TAG_W+ROB_W+:TAG_W-ROB_W]||
         rob.done_q[read_tag_w[f*TAG_W+:ROB_W]])
        $fatal(1,"Backend raw data owner left its unfinished ROB generation");
    end
    if(read_valid_w==3&&read_class_w[0+:3]==`R64_C_MEM&&read_class_w[3+:3]==`R64_C_MEM&&
       read_tag_w[0+:ROB_W]==read_tag_w[TAG_W+:ROB_W])
      $fatal(1,"Backend raw MEM owners share a ROB slot");
    if(read_valid_w==3&&read_class_w[0+:3]==`R64_C_FP&&read_class_w[3+:3]==`R64_C_FP&&
       read_tag_w[0+:ROB_W]==read_tag_w[TAG_W+:ROB_W])
      $fatal(1,"Backend raw FP owners share a ROB slot");
  end
`endif
  R64Execute #(.EARLY_ALU_WAKE(EARLY_ALU_WAKE),.DIRECT_MEM_BIND(DIRECT_MEM_BIND),.PREPARED_CANCEL(1),.RAW_MEM(1),.RAW_FP(1),.RAW_SERIAL(1),.TAG_W(TAG_W),.ROB_W(ROB_W),.LSQ_W(LSQ_W)) execute(
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_o),.cancel_candidates_i(cancel_candidates_w),.cancel_active_i(cancel_active_w),.rob_head_i(head_slot_w),
    .in_valid_i(read_valid_w),.in_ready_o(execute_ready_w),.in_tag_i(read_tag_w),
    .in_mem_slot_i(read_mem_slot_w),.in_uop_i(read_uop_w),.in_alu_control_i(read_alu_control_w),.in_add_source_i(read_add_source_w),.in_shift_amount_i(read_shift_amount_w),.in_branch_imm_i(read_branch_imm_w),.in_branch_control_i(read_branch_control_w),.in_class_i(read_class_w),.in_operand_i(read_operand_w),.in_gpr_dst_i(read_dst_w),
    .early_valid_o(raw_early_valid_w),.early_preg_o(early_preg_w),.rr_fu_credit_o(read_fu_credit_w),.early_tag_o(early_tag_w),
    .alu_bypass_valid_o(raw_alu_bypass_valid_w),.alu_bypass_preg_o(alu_bypass_preg_w),.alu_bypass_data_o(alu_bypass_data_w),
    .result_valid_o(local_valid_w),.result_ready_i(local_ready_w),
    .result_tag_o(local_tag_w),.result_o(local_result_w),
    .recovery_preview_valid_o(recovery_preview_valid_w),.recovery_preview_tag_o(recovery_preview_tag_w),
    .resolve_valid_o(resolve_valid_o),.resolve_tag_o(resolve_tag_o),.resolve_npc_o(resolve_npc_o),
    .redirect_valid_o(redirect_valid_o),.redirect_pending_o(redirect_pending_w),.resolve_pc_o(resolve_pc_o),
    .resolve_conditional_o(resolve_conditional_o),.resolve_indirect_o(resolve_indirect_o),.resolve_taken_o(resolve_taken_o),
    .lsu_slot_o(lsu_slot_o),.lsu_ready_i(lsu_ready_i),.lsu_fire_o(lsu_fire_o),.lsu_tag_o(lsu_tag_o),.lsu_uop_o(lsu_uop_o),.lsu_operand_o(lsu_operand_o),
    .fp_ready_i(fp_ready_i),.fp_fire_o(fp_fire_o),.fp_tag_o(fp_tag_o),.fp_uop_o(fp_uop_o),.fp_operand_o(fp_operand_o),
    .serial_ready_i(serial_ready_i),.serial_fire_o(serial_fire_o),.serial_tag_o(serial_tag_o),
    .serial_uop_o(serial_uop_o),.serial_operand_o(serial_operand_o));
  assign redirect_pc_o=resolve_npc_o;
  R64Writeback #(.REQUEST_HINTS(WB_REQUEST_HINTS),.DEFER_REQUEST(WB_DEFER_REQUEST),.OWNER_CERTIFICATE(1),.PREG_W(P),.SOURCES(9),.SOURCE_W(4),.ROB_W(ROB_W),.TAG_W(TAG_W),.RESULT_W(R)) writeback(
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_o),
    .owner_query_tag_o(wb_owner_query_tag_w),.owner_query_cert_i(wb_owner_query_cert_w),
    .wb_owner_cert_o(wb_owner_cert_w),
    .source_request_i({external_request_i,5'b0}),.source_valid_i({external_valid_i,local_valid_w}),.source_ready_o({external_ready_o,local_ready_w}),
    .source_tag_i({external_tag_i,local_tag_w}),.source_result_i({external_result_i,local_result_w}),
    .wb_valid_o(wb_valid_w),.wb_tag_o(wb_tag_w),.wb_result_o(wb_result_w));
`ifdef R64_ASSERT
  integer serial_issue_lane;
  always @(posedge clk)if(!rst&&!flush_i)
    for(serial_issue_lane=0;serial_issue_lane<2;serial_issue_lane=serial_issue_lane+1)
      if(issue_fire_w[serial_issue_lane]&&issue_class_w[serial_issue_lane*3+:3]==3'd5)begin
        if(issue_tag_w[serial_issue_lane*TAG_W+:TAG_W]!=head_tag_o||
           registers.serial_owner_count!=0||
           !rob.valid_q[issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]]||
           rob.generation_q[issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]]!=
             issue_tag_w[serial_issue_lane*TAG_W+ROB_W+:TAG_W-ROB_W]||
           rob.done_q[issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]])
          $fatal(1,"Serial issue lacks unique canonical head ownership");
      end
  always @(posedge clk)if(serial_fire_o)begin
    if(rst||flush_i||serial_tag_o!=head_tag_o||kill_mask_o[serial_tag_o[ROB_W-1:0]]||
       !rob.valid_q[serial_tag_o[ROB_W-1:0]]||
       rob.generation_q[serial_tag_o[ROB_W-1:0]]!=serial_tag_o[TAG_W-1:ROB_W]||
       rob.done_q[serial_tag_o[ROB_W-1:0]]||registers.serial_owner_count!=1)
      $fatal(1,"Serial fire lacks an unfinished unique canonical head");
  end
  // Query occupancy is not an allocation permit. Every state-holding
  // consumer still uses the same qualified birth pulse.
  always @(posedge clk)begin
    if((rst||flush_i||redirect_valid_o||recover_o||stop_i)&&birth_w!=0)
      $fatal(1,"R64 resource query caused forbidden birth");
    if((lsu_reserve_fire_o&~birth_w)!=0)
      $fatal(1,"R64 LSQ reservation without common birth");
  end
  always @(posedge clk)if(!rst)begin
    if(fetch_valid_i[1]&&!fetch_valid_i[0])$fatal(1,"R64 fetch packet must be dense");
    if(birth_w[1]&&!birth_w[0])$fatal(1,"R64 backend partial birth");
  end
`endif
`ifdef R64_ASSERT
  wire [1:0] qualified_mem_want_w=decode_valid_w&
      {decode_class_w[3+:3]==`R64_C_MEM,decode_class_w[0+:3]==`R64_C_MEM};
  wire reference_birth0_w=decode_valid_w[0]&&!stop_i&&rob_credit_w[0]&&
      rename_credit_w[0]&&issue_credit_w[0]&&(!qualified_mem_want_w[0]||lsu_reserve_ready_i[0]);
  wire reference_birth1_w=decode_valid_w[1]&&reference_birth0_w&&rob_credit_w[1]&&
      rename_credit_w[1]&&issue_credit_w[1]&&(!qualified_mem_want_w[1]||lsu_reserve_ready_i[1]);
  always @(posedge clk)if(!rst)begin
    if(birth_w!=={reference_birth1_w,reference_birth0_w} ||
       lsu_reserve_fire_o!==(birth_w&qualified_mem_want_w))
      $fatal(1,"Raw MEM capacity query changed canonical instruction birth");
    if((flush_i||stop_i||redirect_valid_o||recover_o)&&(|birth_w))
      $fatal(1,"Raw MEM capacity query created a frozen or cancelled owner");
  end
`endif
endmodule
