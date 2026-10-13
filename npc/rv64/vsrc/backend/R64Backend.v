`include "R64Uop.vh"
// Native 2-wide backend: one birth allocates ROB, rename, IQ and MEM LSQ owner.
// Only canonical ROB-accepted completion tuples write/wake the PRF. All
// external effects belong to tagged LSU/FP/serial owners beyond their ingress.
module R64Backend #(
  parameter TAG_W = 9,
  parameter ROB_W = 5,
  parameter PREDECODED = 0,
  parameter PREPARED_NPC = 0,
  parameter PRECONTROLLED = 0,
  parameter LSQ_W = 5,
  parameter DIRECT_MEM_BIND = 0,
  parameter EARLY_ALU_WAKE = 1,
  parameter LOAD_COMPLETION_PROMISE = 1,
  parameter LOAD_RESOLVED_VALUE = 0,
  parameter LOAD_VALUE_NOTICE_Q = 0,
  parameter WB_DEFER_REQUEST = 0,
  parameter WB_REQUEST_HINTS = 0,
  parameter RR_ALU_BYPASS = 1,
  parameter ALU_TOKEN_BYPASS = 0,
  parameter MEM_TERMINAL_CURRENT = 0,
  parameter RR_COMPLETE_ADMIT = 0,
  parameter ISSUE_SLOTS = 16,
  parameter RR_ADMIT_GPR_READ = 0,
  parameter INIT_CURRENT_READY = 0,
  parameter RR_COMPLETE_BRANCH_ADMIT = 0,
  parameter DUAL_RETIRE_STORE_LEASE = 0,
  parameter DIRECTION_COMMIT_TRAIN = 0,
  parameter BATCH_SUFFIX_ROLLBACK = 0
) (
  input                        clk,
  input                        rst,
  input                        flush_i,
  input                        stop_i,
  input [1:0] resolved_value_valid_i,
  input [2*TAG_W-1:0] resolved_value_tag_i,
  input [127:0] resolved_value_data_i,
  input  [          TAG_W+2:0] effect_i,
  input  [     (1<<ROB_W)-1:0] reuse_block_i,
  input  [                1:0] fetch_valid_i,
  output [                1:0] fetch_ready_o,
  input  [               65:0] fetch_canonical_i,
  input  [               69:0] fetch_control_i,
  input  [              127:0] fetch_sequential_npc_i,
  input  [              127:0] fetch_pc_i, fetch_raw_i, fetch_pred_npc_i,
  input  [                7:0] fetch_length_i,
  input  [                1:0] fetch_exception_i,
  input  [               11:0] fetch_cause_i,
  input  [              127:0] fetch_tval_i,
  // Consumer accepts an ordered prefix: lane 1 take requires lane 0 take.
  // Candidate VALID does not depend on READY; cancellation may revoke it.
  input  [                1:0] commit_ready_i,
  output [                1:0] commit_valid_o,
  output [                1:0] commit_serial_o,
  output [        2*TAG_W-1:0] commit_tag_o,
  output [  2*`R64_META_W-1:0] commit_meta_o,
  output [              127:0] commit_data_o,
  output [                1:0] commit_exception_o,
  output [               11:0] commit_cause_o,
  output [              127:0] commit_tval_o,
  output [                9:0] commit_fflags_o,
  output [                1:0] commit_rd_write_o, commit_rd_fp_o,
  output [                9:0] commit_rd_arch_o,
  output                       redirect_valid_o,
  output [               63:0] redirect_pc_o,
  output                       resolve_valid_o,
  output [          TAG_W-1:0] resolve_tag_o,
  output [               63:0] resolve_pc_o, resolve_npc_o,
  output                       resolve_conditional_o, resolve_indirect_o, resolve_taken_o,
  output [     (1<<ROB_W)-1:0] kill_mask_o, cancel_candidates_o,
  output                       cancel_active_o,
  output [          TAG_W-1:0] head_tag_o,
  output                       head_serial_o,
  output                       head_exception_o,
  output [            ROB_W:0] rob_count_o,
  output                       recover_o,
  // LSQ ownership is allocated atomically with ROB/rename/IQ birth.
  output [                1:0] lsu_reserve_want_o,
  output [                1:0] lsu_reserve_fire_o,
  output [        2*TAG_W-1:0] lsu_reserve_tag_o,
  output [               15:0] lsu_reserve_func_o,
  output [                9:0] lsu_reserve_amo_o,
  // Memory publishes first/second FREE-Q offers independently of request.
  // Backend chooses instruction-lane slots locally and sends them explicitly.
  input  [                1:0] lsu_reserve_ready_i,
  input  [        2*LSQ_W-1:0] lsu_reserve_slot_i,
  output [        2*LSQ_W-1:0] lsu_reserve_slot_o,
  input  [                1:0] lsu_ready_i,
  output [                1:0] lsu_fire_o,
  output [        2*TAG_W-1:0] lsu_tag_o,
  output [2*`R64_MEM_CMD_W-1:0] lsu_command_o,
  output [        2*LSQ_W-1:0] lsu_slot_o,
  input                        fp_ready_i,
  output                       fp_fire_o,
  output [          TAG_W-1:0] fp_tag_o,
  output [  `R64_FP_CMD_W-1:0] fp_command_o,
  output [              191:0] fp_operand_o,
  input                        serial_ready_i,
  output                       serial_fire_o,
  output [          TAG_W-1:0] serial_tag_o,
  output [`R64_SERIAL_CMD_W-1:0] serial_command_o,
  // Result lanes: LSU0, LSU1, FP, serial. VALID/payload remain stable until
  // READY, except an explicit kill/flush cancellation by the external owner.
  // Narrow precise terminal for the irrevocable ordinary store at ROB head.
  input                        store_done_valid_i,
  output                       store_done_ready_o,
  input  [          TAG_W-1:0] store_done_tag_i,
  input                        store_done_error_i,
  input  [               63:0] store_done_tval_i,
  input  [                3:0] external_valid_i, external_request_i,
  output [                3:0] external_ready_o,
  input  [        4*TAG_W-1:0] external_tag_i,
  input  [4*`R64_RESULT_W-1:0] external_result_i,
  output                       pair_store_candidate_valid_o,
  output [          TAG_W-1:0] pair_store_candidate_tag_o,
  // Non-owning, one-cycle direction observations. No READY or retirement credit.
  input                        direction_invalidate_i,
  output [                1:0] direction_train_valid_o,
  output [              127:0] direction_train_pc_o,
  output [                1:0] direction_train_taken_o,
  output                      serial_retire_candidate_o
`ifdef R64_ASSERT
  , output [31:0] audit_serial_owner_count_o
`endif
);
  wire serial_allow_i = effect_i[TAG_W+2] && effect_i[TAG_W] &&
      effect_i[0+:TAG_W] == head_tag_o;
  localparam P = 6, U = `R64_UOP_W, M = `R64_META_W, R = `R64_RESULT_W;
  wire [2*U-1:0] decode_uop_w;
  wire [2*M-1:0] decode_meta_w;
  wire [5:0] decode_class_w, src_fp_w, src_used_w;
  wire [1:0] rd_write_w, rd_fp_w, serial_w;
  wire [ 9:0] rd_arch_w;
  wire [29:0] src_arch_w;
  genvar l, event_lane;
  wire [1:0] decode_valid_w, decode_query_valid_w;
  wire [1:0] rob_credit_w, rename_credit_w, issue_credit_w;
  // Source recovery is authoritative at t0 and consumed by Execution at t1.
  // Freeze namespace allocation across both edges, including zero-victim
  // redirects, so the prior event cannot cancel a newly reused slot.
  reg recovery_fence_q;
  wire recovery_source_w=flush_i || cancel_active_w || redirect_valid_o;
  wire birth_stop_w=stop_i || recovery_source_w || recovery_fence_q;
  always @(posedge clk)
    if (rst) recovery_fence_q<=0;
    else recovery_fence_q<=recovery_source_w;
  wire birth0_w = decode_valid_w[0] && !birth_stop_w && rob_credit_w[0] && rename_credit_w[0] &&
      issue_credit_w[0] && (!lsu_reserve_want_o[0] || reserve_lane_ready_w[0]);
  wire birth1_w = decode_valid_w[1] && birth0_w && rob_credit_w[1] && rename_credit_w[1] &&
      issue_credit_w[1] && (!lsu_reserve_want_o[1] || reserve_lane_ready_w[1]);
  wire [1:0] birth_w = {birth1_w, birth0_w};
  // Capacity is a read-only query about the Q-owned decode prefix.
  // Reset/clear/stop qualify the canonical birth, never this FREE query.
  // A cancelled raw want cannot reserve a slot or create an instruction.
  assign lsu_reserve_want_o = decode_query_valid_w &
      {decode_class_w[3+:3] == `R64_C_MEM, decode_class_w[0+:3] == `R64_C_MEM};
  wire [1:0] reserve_lane_ready_w={
      lsu_reserve_want_o[0] ? lsu_reserve_ready_i[1] : lsu_reserve_ready_i[0],
      lsu_reserve_ready_i[0]};
  assign lsu_reserve_slot_o={
      lsu_reserve_want_o[0] ? lsu_reserve_slot_i[LSQ_W+:LSQ_W] :
          lsu_reserve_slot_i[0+:LSQ_W], lsu_reserve_slot_i[0+:LSQ_W]};
  assign lsu_reserve_fire_o = birth_w & lsu_reserve_want_o;
  assign lsu_reserve_tag_o = birth_tag_w;
  assign lsu_reserve_func_o = {decode_uop_w[U+196+:8], decode_uop_w[196+:8]};
  assign lsu_reserve_amo_o = {decode_uop_w[U+155+:5], decode_uop_w[155+:5]};
  // The queue owns decoded, unborn instructions. Physical destinations and
  // full ROB tags are still allocated together on the actual birth edge.
  R64DecodeStage #(
    .PREDECODED(PREDECODED),
    .PREPARED_NPC(PREPARED_NPC),
    .PRECONTROLLED(PRECONTROLLED)
  ) decode_stage (
    .canonical_i(fetch_canonical_i),
    .control_i(fetch_control_i),
    .sequential_npc_i(fetch_sequential_npc_i),
    .clk(clk),
    .rst(rst),
    .clear_i(flush_i || redirect_valid_o),
    .stop_i(birth_stop_w),
    .in_valid_i(fetch_valid_i),
    .in_ready_o(fetch_ready_o),
    .pc_i(fetch_pc_i),
    .raw_i(fetch_raw_i),
    .pred_npc_i(fetch_pred_npc_i),
    .length_i(fetch_length_i),
    .exception_i(fetch_exception_i),
    .cause_i(fetch_cause_i),
    .tval_i(fetch_tval_i),
    .out_valid_o(decode_valid_w),
    .query_valid_o(decode_query_valid_w),
    .out_take_i(birth_w),
    .uop_o(decode_uop_w),
    .meta_o(decode_meta_w),
    .class_o(decode_class_w),
    .rd_write_o(rd_write_w),
    .rd_fp_o(rd_fp_w),
    .rd_arch_o(rd_arch_w),
    .src_arch_o(src_arch_w),
    .src_fp_o(src_fp_w),
    .src_used_o(src_used_w),
    .serial_o(serial_w)
  );
  wire [2*TAG_W-1:0] birth_tag_w;
  wire [2*P-1:0] pnew_w, pold_w;
  wire [6*P-1:0] src_preg_w;
  localparam WB_OWNER_BANKS = 1 << ((ROB_W > 2) ? 2 : 0), WB_CERT_W = P + 3;
  wire [2*TAG_W-1:0] wb_owner_query_tag_w;
  wire [2*WB_OWNER_BANKS*WB_CERT_W-1:0] wb_owner_query_cert_w;
  wire [2*WB_CERT_W-1:0] wb_owner_cert_w;
  wire [1:0] wb_valid_w, wb_accept_w, wb_write_w, wb_fp_w;
  wire [2*TAG_W-1:0] wb_tag_w;
  wire [2*R-1:0] wb_result_w;
  wire [2*P-1:0] wb_preg_w;
  wire [127:0] wb_data_w, wb_tval_w;
  wire [ 1:0] wb_exception_w;
  wire [11:0] wb_cause_w;
  wire [ 9:0] wb_fflags_w;
  generate
    for (l = 0; l < 2; l = l + 1) begin : gen_wb_fields
      assign wb_data_w[l*64+:64] = wb_result_w[l*R+:64];
      assign wb_exception_w[l]   = wb_result_w[l*R+64];
      assign wb_cause_w[l*6+:6]  = wb_result_w[l*R+65+:6];
      assign wb_tval_w[l*64+:64] = wb_result_w[l*R+71+:64];
      assign wb_fflags_w[l*5+:5] = wb_result_w[l*R+135+:5];
    end
  endgenerate
  wire [1:0] commit_fire_w = commit_valid_o & commit_ready_i;

  // Advisory resolve facts share the canonical ROB slot lifetime. They never
  // hold retirement, reuse or recovery: only an exact actual retirement emits.
  generate
    if (DIRECTION_COMMIT_TRAIN != 0) begin : gen_direction_commit
      localparam N=1<<ROB_W, GEN_W=TAG_W-ROB_W;
      reg [N-1:0] valid_q, conditional_q, taken_q;
      reg [GEN_W-1:0] generation_q[0:N-1];
      wire [1:0] emit_w, emit_taken_w;
      reg [1:0] event_valid_q, event_taken_q;
      reg [127:0] event_pc_q;
      assign direction_train_valid_o=event_valid_q;
      assign direction_train_pc_o=event_pc_q;
      assign direction_train_taken_o=event_taken_q;
      genvar direction_slot, direction_lane;
      for (direction_slot=0;direction_slot<N;direction_slot=direction_slot+1) begin : g_record
        localparam [ROB_W-1:0] SLOT=ROB_W'(direction_slot);
        wire birth_w_slot=(birth_w[0]&&birth_tag_w[0+:ROB_W]==SLOT)||
                         (birth_w[1]&&birth_tag_w[TAG_W+:ROB_W]==SLOT);
        wire retire_w=(commit_fire_w[0]&&commit_tag_o[0+:ROB_W]==SLOT)||
                      (commit_fire_w[1]&&commit_tag_o[TAG_W+:ROB_W]==SLOT);
        wire resolve_w=resolve_valid_o&&resolve_tag_o[0+:ROB_W]==SLOT;
        always @(posedge clk) begin
          if(rst||flush_i||kill_mask_o[direction_slot]||birth_w_slot||retire_w)
            valid_q[direction_slot]<=0;
          else if(resolve_w)valid_q[direction_slot]<=1;
          if(resolve_w)begin
            generation_q[direction_slot]<=resolve_tag_o[ROB_W+:GEN_W];
            conditional_q[direction_slot]<=resolve_conditional_o;
            taken_q[direction_slot]<=resolve_taken_o;
          end
        end
`ifdef R64_ASSERT
        always @(posedge clk)if(!rst)begin
          if(resolve_w&&(birth_w_slot||kill_mask_o[direction_slot]||flush_i))
            $fatal(1,"direction journal accepted resolve conflicts with canonical lifetime");
          if(resolve_w&&retire_w&&
             !((commit_fire_w[0]&&commit_tag_o[0+:TAG_W]==resolve_tag_o)||
               (commit_fire_w[1]&&commit_tag_o[TAG_W+:TAG_W]==resolve_tag_o)))
            $fatal(1,"direction journal same-slot resolve/retire generation mismatch");
        end
`endif
      end
      for(direction_lane=0;direction_lane<2;direction_lane=direction_lane+1)begin : g_emit
        wire [TAG_W-1:0] tag_w=commit_tag_o[direction_lane*TAG_W+:TAG_W];
        wire [ROB_W-1:0] slot_w=tag_w[0+:ROB_W];
        wire record_match_w=valid_q[slot_w]&&generation_q[slot_w]==tag_w[ROB_W+:GEN_W];
        wire current_match_w=resolve_valid_o&&resolve_tag_o==tag_w;
        assign emit_w[direction_lane]=commit_fire_w[direction_lane]&&
            (current_match_w?resolve_conditional_o:(record_match_w&&conditional_q[slot_w]));
        assign emit_taken_w[direction_lane]=current_match_w?resolve_taken_o:taken_q[slot_w];
`ifdef R64_ASSERT
        if(M>=204)begin : g_metadata_assert
        wire [63:0] raw_w=commit_meta_o[direction_lane*M+64+:64];
        wire [3:0] length_w=commit_meta_o[direction_lane*M+192+:4];
        wire conditional_retire_w=commit_fire_w[direction_lane]&&
            commit_meta_o[direction_lane*M+196+:8]==`R64_K_BRANCH&&
            ((length_w==4&&raw_w[6:0]==7'h63)||
             (length_w==2&&raw_w[1:0]==2'b01&&
              (raw_w[15:13]==3'b110||raw_w[15:13]==3'b111)));
        always @(posedge clk)if(!rst)begin
          if(conditional_retire_w!==emit_w[direction_lane])
            $fatal(1,"direction journal lost or fabricated conditional retirement tag=%h",tag_w);
        end
        end
`endif
      end
      // A committed event survives younger recovery. Invalidate discards both
      // the event already at Predictor and this edge's new event, preserving
      // the shared clear-table boundary without discarding unretired facts.
      always @(posedge clk)begin
        if(rst||direction_invalidate_i)event_valid_q<=0;
        else event_valid_q<=emit_w;
        event_pc_q<={commit_meta_o[M+:64],commit_meta_o[0+:64]};
        event_taken_q<=emit_taken_w;
      end
    end else begin : gen_direction_resolve
      assign direction_train_valid_o=0;
      assign direction_train_pc_o=0;
      assign direction_train_taken_o=0;
    end
  endgenerate

  wire [2*P-1:0] commit_pnew_w, commit_pold_w;
  wire batch_rollback_apply_w;
  wire [(1<<ROB_W)-1:0] batch_rollback_mask_w;
  wire [ROB_W-1:0] batch_rollback_head_w;
  wire [(1<<ROB_W)*(7+2*P)-1:0] batch_rollback_desc_w;
  wire [63:0] batch_greclaim_w,batch_freclaim_w;
  wire [1:0] undo_valid_w, undo_write_w, undo_fp_w;
  wire [9:0] undo_arch_w;
  wire [2*P-1:0] undo_pnew_w, undo_pold_w;
  wire [ROB_W-1:0] head_slot_w, barrier_slot_w;
  wire [(1<<ROB_W)-1:0] serial_active_w, serial_release_w;
  wire barrier_valid_w;
  wire [(1<<ROB_W)-1:0] cancel_candidates_w;
  wire cancel_active_w;
  assign cancel_candidates_o = cancel_candidates_w;
  assign cancel_active_o = cancel_active_w;
  wire redirect_pending_w;
  wire raw_resolve_valid_w, raw_redirect_valid_w;
  wire recovery_preview_valid_w;
  wire [TAG_W-1:0] recovery_preview_tag_w;
  R64Rob #(
    .OWNER_CERTIFICATE(1),
    .SERIAL_PAYLOAD(1),
    .HEAD_SERIAL_CACHE(1),
    .LOCAL_KILL_FREEZE(1),
    .INDEX_W(ROB_W),
    .GEN_W(TAG_W - ROB_W),
    .META_W(M),
    .DUAL_RETIRE_STORE_LEASE(DUAL_RETIRE_STORE_LEASE),
    .BATCH_SUFFIX_ROLLBACK(BATCH_SUFFIX_ROLLBACK)
  ) rob (
    .batch_apply_o(batch_rollback_apply_w),.batch_mask_o(batch_rollback_mask_w),
    .batch_head_o(batch_rollback_head_w),.batch_desc_o(batch_rollback_desc_w),
    .owner_query_tag_i(wb_owner_query_tag_w),
    .owner_query_cert_o(wb_owner_query_cert_w),
    .wb_owner_cert_i(wb_owner_cert_w),
    .recovery_preview_valid_i(recovery_preview_valid_w),
    .recovery_preview_tag_i(recovery_preview_tag_w),
    .store_done_valid_i(store_done_valid_i),
    .store_done_ready_o(store_done_ready_o),
    .store_done_tag_i(store_done_tag_i),
    .store_done_error_i(store_done_error_i),
    .store_done_tval_i(store_done_tval_i),
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_pending_i(redirect_pending_w),
    .kill_valid_i(raw_redirect_valid_w),
    .kill_tag_i(resolve_tag_o),
    .reuse_block_i(reuse_block_i),
    .resolve_valid_i(raw_resolve_valid_w),
    .resolve_tag_i(resolve_tag_o),
    .resolve_npc_i(resolve_npc_o),
    .resolve_accept_o(resolve_valid_o), .redirect_accept_o(redirect_valid_o),
    .alloc_valid_i(birth_w),
    .alloc_ready_o(rob_credit_w),
    .alloc_tag_o(birth_tag_w),
    .alloc_meta_i(decode_meta_w),
    .alloc_rd_write_i(rd_write_w),
    .alloc_rd_fp_i(rd_fp_w),
    .alloc_serial_i(serial_w),
    .alloc_rd_arch_i(rd_arch_w),
    .alloc_pnew_i(pnew_w),
    .alloc_pold_i(pold_w),
    .wb_valid_i(wb_valid_w),
    .wb_tag_i(wb_tag_w),
    .wb_data_i(wb_data_w),
    .wb_exception_i(wb_exception_w),
    .wb_cause_i(wb_cause_w),
    .wb_tval_i(wb_tval_w),
    .wb_fflags_i(wb_fflags_w),
    .short_valid_i(4'b0),
    .short_tag_i({(4*TAG_W){1'b0}}),
    .short_preg_i(24'b0),
    .short_accept_o(),
    .wb_accept_o(wb_accept_w),
    .wb_rd_write_o(wb_write_w),
    .wb_rd_fp_o(wb_fp_w),
    .wb_preg_o(wb_preg_w),
    .commit_ready_i(commit_ready_i),
    .commit_valid_o(commit_valid_o),
    .commit_serial_o(commit_serial_o),
    .serial_retire_candidate_o(serial_retire_candidate_o),
    .commit_tag_o(commit_tag_o),
    .commit_meta_o(commit_meta_o),
    .commit_data_o(commit_data_o),
    .commit_exception_o(commit_exception_o),
    .commit_cause_o(commit_cause_o),
    .commit_tval_o(commit_tval_o),
    .commit_fflags_o(commit_fflags_o),
    .commit_rd_write_o(commit_rd_write_o),
    .commit_rd_fp_o(commit_rd_fp_o),
    .commit_rd_arch_o(commit_rd_arch_o),
    .commit_pnew_o(commit_pnew_w),
    .commit_pold_o(commit_pold_w),
    .undo_valid_o(undo_valid_w),
    .undo_rd_write_o(undo_write_w),
    .undo_rd_fp_o(undo_fp_w),
    .undo_rd_arch_o(undo_arch_w),
    .undo_pnew_o(undo_pnew_w),
    .undo_pold_o(undo_pold_w),
    .cancel_candidates_o(cancel_candidates_w),
    .cancel_active_o(cancel_active_w),
    .kill_mask_o(kill_mask_o),
    .recover_o(recover_o),
    .head_exception_o(head_exception_o),
    .count_o(rob_count_o),
    .head_slot_o(head_slot_w),
    .pair_store_candidate_valid_o(pair_store_candidate_valid_o),
    .pair_store_candidate_tag_o(pair_store_candidate_tag_o),
    .serial_valid_o(barrier_valid_w),
    .serial_slot_o(barrier_slot_w),
    .serial_active_o(serial_active_w),
    .serial_release_o(serial_release_w)
  );
  assign head_tag_o = commit_tag_o[0+:TAG_W];
  // Resident ROB state, independent of completion, retirement and recovery.
  // Commit uses this only to stop younger births behind a serial head.
  assign head_serial_o = serial_active_w[head_slot_w];
  R64Rename #(.ROB_W(ROB_W),.BATCH_SUFFIX_ROLLBACK(BATCH_SUFFIX_ROLLBACK)) rename (
    .batch_apply_i(batch_rollback_apply_w),.batch_mask_i(batch_rollback_mask_w),
    .batch_head_i(batch_rollback_head_w),.batch_desc_i(batch_rollback_desc_w),
    .batch_greclaim_o(batch_greclaim_w),.batch_freclaim_o(batch_freclaim_w),
    .clk(clk),
    .rst(rst),
    .restore_i(flush_i),
    .request_valid_i(decode_query_valid_w),
    .rd_write_i(rd_write_w),
    .rd_fp_i(rd_fp_w),
    .rd_arch_i(rd_arch_w),
    .src_arch_i(src_arch_w),
    .src_fp_i(src_fp_w),
    .src_used_i(src_used_w),
    .alloc_ready_o(rename_credit_w),
    .pnew_o(pnew_w),
    .pold_o(pold_w),
    .src_preg_o(src_preg_w),
    .alloc_fire_i(birth_w),
    .commit_fire_i(commit_fire_w),
    .commit_rd_write_i(commit_rd_write_o),
    .commit_rd_fp_i(commit_rd_fp_o),
    .commit_rd_arch_i(commit_rd_arch_o),
    .commit_pnew_i(commit_pnew_w),
    .commit_pold_i(commit_pold_w),
    .undo_valid_i(undo_valid_w),
    .undo_rd_write_i(undo_write_w),
    .undo_rd_fp_i(undo_fp_w),
    .undo_rd_arch_i(undo_arch_w),
    .undo_pnew_i(undo_pnew_w),
    .undo_pold_i(undo_pold_w)
  );
  wire [4:0] local_valid_w, local_ready_w;
  wire [8:0] wb_source_capture_w;
  wire [1:0] load_capture_w;
  // Sources 5/6 are fixed LSU CQ ports. Faults complete canonically but
  // cannot announce numerical availability to dependent instructions.
  assign load_capture_w={
      wb_source_capture_w[6] && !external_result_i[R+`R64_R_EXCEPTION],
      wb_source_capture_w[5] && !external_result_i[`R64_R_EXCEPTION]};
  wire [5*TAG_W-1:0] local_tag_w;
  wire [5*R-1:0] local_result_w;
  wire [1:0] birth_write_w, reclaim_write_w;
  generate
    for (event_lane=0; event_lane<2; event_lane=event_lane+1) begin : gen_destination_event
      assign birth_write_w[event_lane]=rd_write_w[event_lane] &&
          (rd_fp_w[event_lane] || rd_arch_w[event_lane*5+:5] != 0);
      assign reclaim_write_w[event_lane]=undo_valid_w[event_lane] && undo_write_w[event_lane] &&
          (undo_fp_w[event_lane] || undo_arch_w[event_lane*5+:5] != 0);
    end
  endgenerate
`ifdef R64_ASSERT
  wire [3:0] audit_fast_valid_w;
  wire [4*TAG_W-1:0] audit_fast_tag_w;
  wire [23:0] audit_fast_preg_w;
  wire [1:0] audit_read_valid_w, audit_issue_fire_w;
  wire [2*TAG_W-1:0] audit_read_tag_w, audit_issue_tag_w;
  wire [5:0] audit_read_class_w, audit_issue_class_w;
`endif
  R64ExecutionDomain #(
    .TAG_W(TAG_W), .ROB_W(ROB_W), .LSQ_W(LSQ_W),
    .BATCH_SUFFIX_ROLLBACK(BATCH_SUFFIX_ROLLBACK),
    .DIRECT_MEM_BIND(DIRECT_MEM_BIND), .EARLY_ALU_WAKE(EARLY_ALU_WAKE),
    .ALU_TOKEN_BYPASS(ALU_TOKEN_BYPASS),
    .MEM_TERMINAL_CURRENT(MEM_TERMINAL_CURRENT),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),
    .RR_COMPLETE_BRANCH_ADMIT(RR_COMPLETE_BRANCH_ADMIT),
    .RR_ADMIT_GPR_READ(RR_ADMIT_GPR_READ),
    .INIT_CURRENT_READY(INIT_CURRENT_READY),
    .RR_ALU_BYPASS(RR_ALU_BYPASS), .ISSUE_SLOTS(ISSUE_SLOTS),
    .LOAD_COMPLETION_PROMISE(LOAD_COMPLETION_PROMISE),
    .LOAD_RESOLVED_VALUE(LOAD_RESOLVED_VALUE),
    .LOAD_VALUE_NOTICE_Q(LOAD_VALUE_NOTICE_Q)
  ) execution (
    .batch_apply_i(batch_rollback_apply_w),.batch_greclaim_i(batch_greclaim_w),
    .batch_freclaim_i(batch_freclaim_w),
    .clk(clk), .rst(rst),
    .recovery_i({65'b0, flush_i, cancel_active_w, cancel_candidates_w}),
    .serial_allow_i(serial_allow_i),
    .head_slot_i(head_slot_w), .head_tag_i(head_tag_o),
    .barrier_valid_i(barrier_valid_w), .barrier_slot_i(barrier_slot_w),
    .serial_active_i(serial_active_w), .serial_release_i(serial_release_w),
    .birth_i(birth_w), .birth_ready_o(issue_credit_w),
    .birth_rd_write_i(birth_write_w), .birth_rd_fp_i(rd_fp_w),
    .birth_tag_i(birth_tag_w), .birth_mem_slot_i(lsu_reserve_slot_o),
    .birth_uop_i(decode_uop_w), .birth_class_i(decode_class_w),
    .birth_preg_i(pnew_w), .birth_src_preg_i(src_preg_w),
    .birth_src_fp_i(src_fp_w), .birth_src_used_i(src_used_w),
    .resolved_value_valid_i(resolved_value_valid_i),
    .resolved_value_tag_i(resolved_value_tag_i), .resolved_value_data_i(resolved_value_data_i),
    .load_capture_i(load_capture_w), .load_capture_tag_i(external_tag_i[0+:2*TAG_W]),
    .wb_accept_i(wb_accept_w), .wb_tag_i(wb_tag_w),
    .wb_write_i(wb_write_w), .wb_fp_i(wb_fp_w), .wb_preg_i(wb_preg_w), .wb_data_i(wb_data_w),
    .reclaim_write_i(reclaim_write_w), .reclaim_fp_i(undo_fp_w), .reclaim_preg_i(undo_pnew_w),
    .result_valid_o(local_valid_w), .result_ready_i(local_ready_w),
    .result_tag_o(local_tag_w), .result_o(local_result_w),
    .recovery_preview_valid_o(recovery_preview_valid_w),
    .recovery_preview_tag_o(recovery_preview_tag_w),
    .resolve_valid_o(raw_resolve_valid_w), .resolve_tag_o(resolve_tag_o),
    .resolve_npc_o(resolve_npc_o), .resolve_pc_o(resolve_pc_o),
    .resolve_conditional_o(resolve_conditional_o), .resolve_indirect_o(resolve_indirect_o),
    .resolve_taken_o(resolve_taken_o), .redirect_valid_o(raw_redirect_valid_w),
    .redirect_pending_o(redirect_pending_w),
    .lsu_ready_i(lsu_ready_i), .lsu_fire_o(lsu_fire_o), .lsu_tag_o(lsu_tag_o),
    .lsu_slot_o(lsu_slot_o), .lsu_command_o(lsu_command_o),
    .fp_ready_i(fp_ready_i), .fp_fire_o(fp_fire_o), .fp_tag_o(fp_tag_o),
    .fp_command_o(fp_command_o), .fp_operand_o(fp_operand_o),
    .serial_ready_i(serial_ready_i), .serial_fire_o(serial_fire_o), .serial_tag_o(serial_tag_o),
    .serial_command_o(serial_command_o)
`ifdef R64_ASSERT
    , .audit_fast_valid_o(audit_fast_valid_w), .audit_fast_tag_o(audit_fast_tag_w),
    .audit_fast_preg_o(audit_fast_preg_w), .audit_read_valid_o(audit_read_valid_w), .audit_read_tag_o(audit_read_tag_w),
    .audit_read_class_o(audit_read_class_w), .audit_issue_fire_o(audit_issue_fire_w),
    .audit_issue_tag_o(audit_issue_tag_w), .audit_issue_class_o(audit_issue_class_w),
    .audit_serial_owner_count_o(audit_serial_owner_count_o)
`endif
  );
`ifdef R64_ASSERT
  // Audit the speculative lease against the authoritative lifecycle identity.
  // t0/t1 are a deliberate revocation-delivery window: cancelled values may
  // circulate locally, but ROB certification forbids their architectural WB.
  // Namespace allocation remains fenced until local cancellation is consumed.
  always @(posedge clk)
    if (!rst && !recovery_source_w && !recovery_fence_q) begin
      for (integer f=0;f<4;f=f+1)
        if (audit_fast_valid_w[f] &&
            (!rob.valid_q[audit_fast_tag_w[f*TAG_W+:ROB_W]] ||
             rob.generation_q[audit_fast_tag_w[f*TAG_W+:ROB_W]] !=
                 audit_fast_tag_w[f*TAG_W+ROB_W+:TAG_W-ROB_W] ||
             rob.pnew_q[audit_fast_tag_w[f*TAG_W+:ROB_W]] != audit_fast_preg_w[f*P+:P] ||
             !rob.rd_write_q[audit_fast_tag_w[f*TAG_W+:ROB_W]] ||
             rob.rd_fp_q[audit_fast_tag_w[f*TAG_W+:ROB_W]]))
          $fatal(1,"Execution local fast lease disagrees with canonical full-tag destination");
      for (integer f=0; f<2; f=f+1)
        if (audit_read_valid_w[f] &&
            (audit_read_class_w[f*3+:3] == `R64_C_FP || audit_read_class_w[f*3+:3] == `R64_C_MEM)) begin
          if (!rob.valid_q[audit_read_tag_w[f*TAG_W+:ROB_W]] ||
              rob.generation_q[audit_read_tag_w[f*TAG_W+:ROB_W]] !=
                  audit_read_tag_w[f*TAG_W+ROB_W+:TAG_W-ROB_W] ||
              rob.done_q[audit_read_tag_w[f*TAG_W+:ROB_W]])
            $fatal(1, "Backend raw data owner left its unfinished ROB generation");
        end
      if (audit_read_valid_w == 3 && audit_read_class_w[0+:3] == `R64_C_MEM &&
          audit_read_class_w[3+:3] == `R64_C_MEM &&
          audit_read_tag_w[0+:ROB_W] == audit_read_tag_w[TAG_W+:ROB_W])
        $fatal(1, "Backend raw MEM owners share a ROB slot");
      if (audit_read_valid_w == 3 && audit_read_class_w[0+:3] == `R64_C_FP &&
          audit_read_class_w[3+:3] == `R64_C_FP &&
          audit_read_tag_w[0+:ROB_W] == audit_read_tag_w[TAG_W+:ROB_W])
        $fatal(1, "Backend raw FP owners share a ROB slot");
    end
  always @(posedge clk)
    if (!rst) begin
      if ((lsu_reserve_fire_o & ~reserve_lane_ready_w) != 0)
        $fatal(1, "R64 LSQ reserve without Q credit");
      if (flush_i && lsu_reserve_fire_o != 0) $fatal(1, "R64 LSQ birth survived flush");
      if (lsu_reserve_fire_o == 3 &&
          lsu_reserve_slot_o[0+:LSQ_W] == lsu_reserve_slot_o[LSQ_W+:LSQ_W])
        $fatal(1, "R64 dual MEM birth shares LSQ slot");
    end
`endif
  assign redirect_pc_o = resolve_npc_o;
  R64Writeback #(
    .REQUEST_HINTS(WB_REQUEST_HINTS),
    .DEFER_REQUEST(WB_DEFER_REQUEST),
    .OWNER_CERTIFICATE(1),
    .PREG_W(P),
    .SOURCES(9),
    .SOURCE_W(4),
    .ROB_W(ROB_W),
    .TAG_W(TAG_W),
    .RESULT_W(R)
  ) writeback (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_mask_i(kill_mask_o),
    .owner_query_tag_o(wb_owner_query_tag_w),
    .owner_query_cert_i(wb_owner_query_cert_w),
    .wb_owner_cert_o(wb_owner_cert_w),
    .source_request_i({external_request_i, 5'b0}),
    .source_valid_i({external_valid_i, local_valid_w}),
    .source_ready_o({external_ready_o, local_ready_w}),
    .source_capture_o(wb_source_capture_w),
    .source_tag_i({external_tag_i, local_tag_w}),
    .source_result_i({external_result_i, local_result_w}),
    .wb_valid_o(wb_valid_w),
    .wb_tag_o(wb_tag_w),
    .wb_result_o(wb_result_w)
  );
`ifdef R64_ASSERT
  integer serial_issue_lane;
  always @(posedge clk)
    if (!rst && !flush_i)
      for (serial_issue_lane = 0; serial_issue_lane < 2; serial_issue_lane = serial_issue_lane + 1)
        if (audit_issue_fire_w[serial_issue_lane] && audit_issue_class_w[serial_issue_lane*3+:3] == 3'd5) begin
          if (audit_issue_tag_w[serial_issue_lane*TAG_W+:TAG_W] != head_tag_o ||
              audit_serial_owner_count_o != 0 ||
              !rob.valid_q[audit_issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]] ||
              rob.generation_q[audit_issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]] !=
              audit_issue_tag_w[serial_issue_lane*TAG_W+ROB_W+:TAG_W-ROB_W] ||
              rob.done_q[audit_issue_tag_w[serial_issue_lane*TAG_W+:ROB_W]])
            $fatal(1, "Serial issue lacks unique canonical head ownership");
        end
  always @(posedge clk)
    if (serial_fire_o) begin
      if (rst || flush_i || serial_tag_o != head_tag_o || kill_mask_o[serial_tag_o[ROB_W-1:0]] ||
          !rob.valid_q[serial_tag_o[ROB_W-1:0]] ||
          rob.generation_q[serial_tag_o[ROB_W-1:0]] != serial_tag_o[TAG_W-1:ROB_W] ||
          rob.done_q[serial_tag_o[ROB_W-1:0]] || audit_serial_owner_count_o != 1)
        $fatal(1, "Serial fire lacks an unfinished unique canonical head");
    end
  // Query occupancy is not an allocation permit. Every state-holding
  // consumer still uses the same qualified birth pulse.
  always @(posedge clk) begin
    if ((rst || birth_stop_w || recover_o) && birth_w != 0)
      $fatal(1, "R64 resource query caused forbidden birth");
    if ((lsu_reserve_fire_o & ~birth_w) != 0) $fatal(1, "R64 LSQ reservation without common birth");
  end
  always @(posedge clk)
    if (!rst) begin
      if (fetch_valid_i[1] && !fetch_valid_i[0]) $fatal(1, "R64 fetch packet must be dense");
      if (birth_w[1] && !birth_w[0]) $fatal(1, "R64 backend partial birth");
    end
`endif
`ifdef R64_ASSERT
  wire [1:0] qualified_mem_want_w = decode_valid_w &
      {decode_class_w[3+:3] == `R64_C_MEM, decode_class_w[0+:3] == `R64_C_MEM};
  wire reference_birth0_w = decode_valid_w[0] && !birth_stop_w && rob_credit_w[0] && rename_credit_w[0] &&
      issue_credit_w[0] && (!qualified_mem_want_w[0] || reserve_lane_ready_w[0]);
  wire reference_birth1_w = decode_valid_w[1] && reference_birth0_w && rob_credit_w[1] &&
      rename_credit_w[1] && issue_credit_w[1] &&
      (!qualified_mem_want_w[1] || reserve_lane_ready_w[1]);
  always @(posedge clk)
    if (!rst) begin
      if (birth_w !== {reference_birth1_w, reference_birth0_w} ||
          lsu_reserve_fire_o !== (birth_w & qualified_mem_want_w))
        $fatal(1, "Raw MEM capacity query changed canonical instruction birth");
      if ((birth_stop_w || recover_o) && (|birth_w))
        $fatal(1, "Raw MEM capacity query created a frozen or cancelled owner");
    end
`endif
endmodule
