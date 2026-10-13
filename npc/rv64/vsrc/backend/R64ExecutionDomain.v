`include "R64Dispatch.vh"
// Independent scheduling/execution owner. Birth is the allocation event;
// authorized completion and undo update physical readiness. IQ queries, PRF,
// FPR read plans, ALU predecode, FU credits and fast-value delivery stay local.
module R64ExecutionDomain #(
  parameter TAG_W=9, ROB_W=5, LSQ_W=5,
  parameter DIRECT_MEM_BIND=0, EARLY_ALU_WAKE=1, LOAD_COMPLETION_PROMISE=1,
  parameter LOAD_RESOLVED_VALUE=0, LOAD_VALUE_NOTICE_Q=0,
  parameter MEM_TERMINAL_CURRENT=0, RR_COMPLETE_ADMIT=0,
  parameter RR_ALU_BYPASS=1, ALU_TOKEN_BYPASS=0, ISSUE_SLOTS=16,
  parameter RR_ADMIT_GPR_READ=0, INIT_CURRENT_READY=0, RR_COMPLETE_BRANCH_ADMIT=0,
  parameter BATCH_SUFFIX_ROLLBACK=0
) (
  input clk, rst,
  input [`R64_RECOVERY_W(1<<ROB_W)-1:0] recovery_i,
  input serial_allow_i,
  input [ROB_W-1:0] head_slot_i, barrier_slot_i,
  input [TAG_W-1:0] head_tag_i,
  input barrier_valid_i,
  input [(1<<ROB_W)-1:0] serial_active_i, serial_release_i,
  input [1:0] birth_i, birth_rd_write_i, birth_rd_fp_i,
  output [1:0] birth_ready_o,
  input [2*TAG_W-1:0] birth_tag_i,
  input [2*LSQ_W-1:0] birth_mem_slot_i,
  input [2*`R64_UOP_W-1:0] birth_uop_i,
  input [5:0] birth_class_i,
  input [11:0] birth_preg_i,
  input [35:0] birth_src_preg_i,
  input [5:0] birth_src_fp_i, birth_src_used_i,
  // Successful memory result observations and actual CQ -> WB capture
  // notices never update canonical readiness or architectural completion.
  input [1:0] resolved_value_valid_i,
  input [2*TAG_W-1:0] resolved_value_tag_i,
  input [127:0] resolved_value_data_i,
  input [1:0] load_capture_i,
  input [2*TAG_W-1:0] load_capture_tag_i,
  input [1:0] wb_accept_i, wb_write_i, wb_fp_i,
  input [2*TAG_W-1:0] wb_tag_i,
  input [11:0] wb_preg_i,
  input [127:0] wb_data_i,
  input [1:0] reclaim_write_i, reclaim_fp_i,
  input [11:0] reclaim_preg_i,
  output [4:0] result_valid_o,
  input [4:0] result_ready_i,
  output [5*TAG_W-1:0] result_tag_o,
  output [5*`R64_RESULT_W-1:0] result_o,
  output recovery_preview_valid_o,
  output [TAG_W-1:0] recovery_preview_tag_o,
  output resolve_valid_o, redirect_valid_o, redirect_pending_o,
  output [TAG_W-1:0] resolve_tag_o,
  output [63:0] resolve_npc_o, resolve_pc_o,
  output resolve_conditional_o, resolve_indirect_o, resolve_taken_o,
  input [1:0] lsu_ready_i,
  output [1:0] lsu_fire_o,
  output [2*TAG_W-1:0] lsu_tag_o,
  output [2*LSQ_W-1:0] lsu_slot_o,
  output [2*`R64_MEM_CMD_W-1:0] lsu_command_o,
  input fp_ready_i,
  output fp_fire_o,
  output [TAG_W-1:0] fp_tag_o,
  output [`R64_FP_CMD_W-1:0] fp_command_o,
  output [191:0] fp_operand_o,
  input serial_ready_i,
  output serial_fire_o,
  output [TAG_W-1:0] serial_tag_o,
  output [`R64_SERIAL_CMD_W-1:0] serial_command_o
`ifdef R64_ASSERT
  , output [3:0] audit_fast_valid_o,
  output [4*TAG_W-1:0] audit_fast_tag_o,
  output [23:0] audit_fast_preg_o,
  output [1:0] audit_read_valid_o, audit_issue_fire_o,
  output [2*TAG_W-1:0] audit_read_tag_o, audit_issue_tag_o,
  output [5:0] audit_read_class_o, audit_issue_class_o,
  output [31:0] audit_serial_owner_count_o
`endif
  , input batch_apply_i,
  input [63:0] batch_greclaim_i,batch_freclaim_i
);
  localparam P=6, U=`R64_UOP_W, R=`R64_RESULT_W, N=(1<<ROB_W);
  wire [`R64_RECOVERY_W(N)-1:0] recovery_local_w;
  wire recovery_pending_w;
  R64RecoveryInbox #(.N(N)) recovery_inbox (
    .clk_i(clk), .rst_i(rst), .event_i(recovery_i),
    .event_o(recovery_local_w), .pending_o(recovery_pending_w)
  );
  wire flush_i=recovery_local_w[N+1];
  wire cancel_active_i=recovery_local_w[N];
  wire [N-1:0] cancel_candidates_i=recovery_local_w[N-1:0];
  wire [N-1:0] kill_mask_i=cancel_candidates_i & {N{cancel_active_i}};
  // This boundary targets the ICS55/ECOS TT 25 C, 500 MHz experiment.
  // Non-owning load-value announcements cross this boundary as one packet.
  // Sampling never waits for IQ/RR/CQ/WB credit. The current full-tag lease is
  // checked by owners after Q; a missed or expired notice uses canonical WB/PRF.
  // Payload is sampled even when invalid, so no current raw payload can bypass Q.
  wire [1:0] load_notice_valid_w;
  wire [2*TAG_W-1:0] load_notice_tag_w;
  wire [127:0] load_notice_data_w;
  generate
    if (LOAD_VALUE_NOTICE_Q != 0) begin : gen_load_notice_q
      reg [1:0] valid_q;
      reg [2*TAG_W-1:0] tag_q;
      reg [127:0] data_q;
      always @(posedge clk) begin
        tag_q <= resolved_value_tag_i;
        data_q <= resolved_value_data_i;
        if (rst || flush_i) valid_q <= 0;
        else valid_q <= resolved_value_valid_i;
      end
      assign load_notice_valid_w=valid_q;
      assign load_notice_tag_w=tag_q;
      assign load_notice_data_w=data_q;
    end else begin : gen_load_notice_current
      assign load_notice_valid_w=resolved_value_valid_i;
      assign load_notice_tag_w=resolved_value_tag_i;
      assign load_notice_data_w=resolved_value_data_i;
    end
  endgenerate
  genvar l, service_lane;
  wire [2*U-1:0] lsu_uop_w;
  wire [383:0] lsu_operand_w;
  wire [U-1:0] fp_uop_w, serial_uop_w;
  wire [191:0] serial_operand_w;
  wire [1:0] issue_fire_w, read_credit_w, read_valid_w, read_local_alu_valid_w, execute_ready_w;
  wire [2*TAG_W-1:0] issue_tag_w, read_tag_w;
  wire [2*LSQ_W-1:0] issue_mem_slot_w, read_mem_slot_w;
  wire [2*U-1:0] issue_uop_w, read_uop_w;
  wire [5:0] issue_class_w, issue_fp_w, issue_used_w, read_class_w;
  wire [6*P-1:0] issue_src_w;
  wire [5:0] issue_pending_w;
  wire [1:0] load_promise_w, birth_load_w;
  wire [2*P-1:0] load_preg_w, resolved_preg_w;
  wire [1:0] resolved_valid_w;
  wire [2*(3*P+8)-1:0] issue_fp_plan_w;
  wire [383:0] read_operand_w;
  wire [5:0] read_fu_credit_w;
  wire [2*P-1:0] short_dst_w, issue_dst_w, read_dst_w, early_preg_w, alu_bypass_preg_w;
  wire [1:0] early_valid_w, alu_bypass_valid_w, raw_early_valid_w, raw_alu_bypass_valid_w;
  wire [2*TAG_W-1:0] early_tag_w;
  wire [73:0] read_alu_control_w;
  wire [9:0] read_add_source_w;
  wire [11:0] read_shift_amount_w;
  wire [41:0] read_branch_imm_w;
  wire [9:0] read_branch_control_w;
  wire [127:0] alu_bypass_data_w;
  wire [1:0] raw_alu_token_resident_w, alu_token_valid_w;
  wire [2*TAG_W-1:0] alu_token_tag_w;
  wire [2*P-1:0] alu_token_preg_w;
  wire [127:0] alu_token_data_w;
  wire [6*P-1:0] ready_query_preg_w;
  wire [5:0] ready_query_fp_w, ready_query_canonical_w, ready_query_complete_w;
  generate
    for (l = 0; l < 2; l = l + 1) begin : gen_short_destination
      wire [U-1:0] uop_w=birth_uop_i[l*U+:U];
      wire [7:0] func_w=uop_w[`R64_U_FUNC];
      assign birth_load_w[l]=(LOAD_COMPLETION_PROMISE != 0 || LOAD_RESOLVED_VALUE != 0) &&
          birth_class_i[l*3+:3] == `R64_C_MEM &&
          birth_rd_write_i[l] && !birth_rd_fp_i[l] && birth_preg_i[l*P+:P]!=0 &&
          !uop_w[`R64_U_EXCEPTION] && !func_w[`R64_MEM_FUNC_STORE] &&
          !func_w[`R64_MEM_FUNC_ATOMIC] && !func_w[`R64_MEM_FUNC_FP];
      assign short_dst_w[l*P+:P] = birth_rd_write_i[l] && !birth_rd_fp_i[l] &&
          (birth_class_i[l*3+:3] == `R64_C_ALU || birth_class_i[l*3+:3] == `R64_C_BRANCH) ?
          birth_preg_i[l*P+:P] : {P{1'b0}};
    end
    for (l = 0; l < 6; l = l + 1) begin : gen_birth_early_ready
      // Existing IQ entries saw the producer's fire pulse. New entries born
      // after that pulse can see its held result until canonical WB arrives.
      assign ready_query_complete_w[l] = ready_query_canonical_w[l] ||
          (!ready_query_fp_w[l] &&
           ((alu_bypass_valid_w[0] && ready_query_preg_w[l*P+:P] == alu_bypass_preg_w[0+:P]) ||
            (alu_bypass_valid_w[1] && ready_query_preg_w[l*P+:P] == alu_bypass_preg_w[P+:P])));
    end
  endgenerate
  R64Issue #(
    .N(ISSUE_SLOTS),
    .SLOT_W($clog2(ISSUE_SLOTS)),
    .MDU_RESOURCE_PAIR(1),
    .DEFER_READY(1),
    .INIT_CURRENT_READY(INIT_CURRENT_READY),
    .ALU_ISSUE_PROMISE(EARLY_ALU_WAKE),
    .LOAD_COMPLETION_PROMISE(LOAD_COMPLETION_PROMISE),
    .LOAD_RESOLVED_VALUE(LOAD_RESOLVED_VALUE),
    .PREPARED_CANCEL(1),
    .ROB_W(ROB_W),
    .TAG_W(TAG_W),
    .PAYLOAD_W(U),
    .LSQ_W(LSQ_W)
  ) issue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_mask_i(kill_mask_i),
    .cancel_candidates_i(cancel_candidates_i),
    .cancel_active_i(cancel_active_i),
    .rob_head_i(head_slot_i),
    .barrier_valid_i(barrier_valid_i),
    .barrier_slot_i(barrier_slot_i),
    .serial_active_i(serial_active_i),
    .serial_release_i(serial_release_i),
    .enq_valid_i(birth_i),
    .enq_ready_o(birth_ready_o),
    .enq_tag_i(birth_tag_i),
    .enq_mem_slot_i(birth_mem_slot_i),
    .enq_payload_i(birth_uop_i),
    .enq_class_i(birth_class_i),
    .enq_gpr_dst_i(short_dst_w),
    .enq_src_preg_i(birth_src_preg_i),
    .enq_src_fp_i(birth_src_fp_i),
    .enq_src_used_i(birth_src_used_i),
    .enq_src_ready_i(6'b0),
    .ready_query_preg_o(ready_query_preg_w),
    .ready_query_fp_o(ready_query_fp_w),
    .ready_query_ready_i(ready_query_complete_w),
    .wake_valid_i(wb_write_i),
    .wake_fp_i(wb_fp_i),
    .wake_preg_i(wb_preg_i),
    .early_valid_i(early_valid_w),
    .early_preg_i(early_preg_w),
    .load_promise_i(load_promise_w), .load_preg_i(load_preg_w),
    .resolved_value_valid_i(resolved_valid_w), .resolved_value_preg_i(resolved_preg_w),
    .fu_allow_i(6'b111111),
    .serial_allow_i(serial_allow_i),
    .issue_ready_i(read_credit_w),
    .issue_mem_slot_o(issue_mem_slot_w),
    .issue_fire_o(issue_fire_w),
    .issue_tag_o(issue_tag_w),
    .issue_payload_o(issue_uop_w),
    .issue_class_o(issue_class_w),
    .issue_gpr_dst_o(issue_dst_w),
    .issue_src_preg_o(issue_src_w),
    .issue_fp_plan_o(issue_fp_plan_w),
    .issue_src_fp_o(issue_fp_w),
    .issue_src_used_o(issue_used_w),
    .issue_src_pending_o(issue_pending_w),
    .count_o()
  );
  R64RegRead #(
    .ALU_TERMINAL_BYPASS(RR_ALU_BYPASS),
    .ALU_TOKEN_BYPASS(ALU_TOKEN_BYPASS),
    .MEM_TERMINAL_CURRENT(MEM_TERMINAL_CURRENT),
    .RR_COMPLETE_ADMIT(RR_COMPLETE_ADMIT),
    .RR_COMPLETE_BRANCH_ADMIT(RR_COMPLETE_BRANCH_ADMIT),
    .RR_ADMIT_GPR_READ(RR_ADMIT_GPR_READ),
    .LATE_OPERANDS((EARLY_ALU_WAKE != 0) || (LOAD_COMPLETION_PROMISE != 0) ||
                   (LOAD_RESOLVED_VALUE != 0)),
    .LOAD_RESOLVED_VALUE(LOAD_RESOLVED_VALUE),
    .SPLIT_VALUE_VALID(1),
    .PREQUALIFIED_ISSUE(1),
    .Q_ONLY_TERMINAL(1),
    .PREPARED_CANCEL(1),
    .COMPACT_FP(1),
    .RAW_FP_ALLOCATION(1),
    .UNIQUE_SERIAL(1),
    .ROB_W(ROB_W),
    .TAG_W(TAG_W),
    .PAYLOAD_W(U),
    .LSQ_W(LSQ_W)
  ) registers (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_mask_i(kill_mask_i),
    .cancel_candidates_i(cancel_candidates_i),
    .cancel_active_i(cancel_active_i),
    .fu_credit_i(read_fu_credit_w),
    .in_mem_slot_i(issue_mem_slot_w),
    .out_mem_slot_o(read_mem_slot_w),
    .in_fire_i(issue_fire_w),
    .in_ready_o(read_credit_w),
    .in_tag_i(issue_tag_w),
    .in_payload_i(issue_uop_w),
    .in_fp_plan_i(issue_fp_plan_w),
    .in_class_i(issue_class_w),
    .in_gpr_dst_i(issue_dst_w),
    .in_src_preg_i(issue_src_w),
    .in_src_fp_i(issue_fp_w),
    .in_src_used_i(issue_used_w),
    .in_src_pending_i(issue_pending_w),
    .wb_write_i(wb_write_i),
    .wb_fp_i(wb_fp_i),
    .wb_preg_i(wb_preg_i),
    .wb_data_i(wb_data_i),
    .out_valid_o(read_valid_w),
    .out_local_alu_valid_o(read_local_alu_valid_w),
    .out_ready_i(execute_ready_w),
    .out_tag_o(read_tag_w),
    .out_payload_o(read_uop_w),
    .out_alu_control_o(read_alu_control_w),
    .out_add_source_o(read_add_source_w),
    .out_shift_amount_o(read_shift_amount_w),
    .out_branch_imm_o(read_branch_imm_w),
    .out_branch_control_o(read_branch_control_w),
    .out_class_o(read_class_w),
    .out_operand_o(read_operand_w),
    .out_gpr_dst_o(read_dst_w),
    .resolved_value_valid_i(resolved_valid_w), .resolved_value_preg_i(resolved_preg_w),
    .resolved_value_data_i(load_notice_data_w),
    .alu_bypass_resident_i(raw_alu_bypass_valid_w),
    .alu_bypass_valid_i(alu_bypass_valid_w),
    .alu_bypass_preg_i(alu_bypass_preg_w),
    .alu_bypass_data_i(alu_bypass_data_w),
    .alu_token_resident_i(raw_alu_token_resident_w),
    .alu_token_valid_i(alu_token_valid_w),
    .alu_token_preg_i(alu_token_preg_w),
    .alu_token_data_i(alu_token_data_w)
  );
  R64Execute #(
    // IQ issue promises already schedule dependent ALUs ahead of their values.
    // Disable only accept-time wake: RR late-ready must not select a new early
    // tag and re-enter owner certification. Registered token/head wakes remain.
    .EARLY_ALU_WAKE(0),
    .SPLIT_VALUE_VALID(1),
    .DIRECT_MEM_BIND(DIRECT_MEM_BIND),
    .PREPARED_CANCEL(1),
    .RAW_MEM(1),
    .RAW_FP(1),
    .RAW_SERIAL(1),
    .TAG_W(TAG_W),
    .ROB_W(ROB_W),
    .LSQ_W(LSQ_W)
  ) execute (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .kill_mask_i(kill_mask_i),
    .cancel_candidates_i(cancel_candidates_i),
    .cancel_active_i(cancel_active_i),
    .rob_head_i(head_slot_i),
    .in_valid_i(read_valid_w),
    .in_local_alu_valid_i(read_local_alu_valid_w),
    .in_ready_o(execute_ready_w),
    .in_tag_i(read_tag_w),
    .in_mem_slot_i(read_mem_slot_w),
    .in_uop_i(read_uop_w),
    .in_alu_control_i(read_alu_control_w),
    .in_add_source_i(read_add_source_w),
    .in_shift_amount_i(read_shift_amount_w),
    .in_branch_imm_i(read_branch_imm_w),
    .in_branch_control_i(read_branch_control_w),
    .in_class_i(read_class_w),
    .in_operand_i(read_operand_w),
    .in_gpr_dst_i(read_dst_w),
    .early_valid_o(raw_early_valid_w),
    .early_preg_o(early_preg_w),
    .rr_fu_credit_o(read_fu_credit_w),
    .early_tag_o(early_tag_w),
    .alu_bypass_valid_o(raw_alu_bypass_valid_w),
    .alu_bypass_preg_o(alu_bypass_preg_w),
    .alu_bypass_data_o(alu_bypass_data_w),
    .alu_token_resident_o(raw_alu_token_resident_w),
    .alu_token_tag_o(alu_token_tag_w),
    .alu_token_preg_o(alu_token_preg_w),
    .alu_token_data_o(alu_token_data_w),
    .result_valid_o(result_valid_o),
    .result_ready_i(result_ready_i),
    .result_tag_o(result_tag_o),
    .result_o(result_o),
    .recovery_preview_valid_o(recovery_preview_valid_o),
    .recovery_preview_tag_o(recovery_preview_tag_o),
    .resolve_valid_o(resolve_valid_o),
    .resolve_tag_o(resolve_tag_o),
    .resolve_npc_o(resolve_npc_o),
    .redirect_valid_o(redirect_valid_o),
    .redirect_pending_o(redirect_pending_o),
    .resolve_pc_o(resolve_pc_o),
    .resolve_conditional_o(resolve_conditional_o),
    .resolve_indirect_o(resolve_indirect_o),
    .resolve_taken_o(resolve_taken_o),
    .lsu_slot_o(lsu_slot_o),
    .lsu_ready_i(lsu_ready_i),
    .lsu_fire_o(lsu_fire_o),
    .lsu_tag_o(lsu_tag_o),
    .lsu_uop_o(lsu_uop_w),
    .lsu_operand_o(lsu_operand_w),
    .fp_ready_i(fp_ready_i),
    .fp_fire_o(fp_fire_o),
    .fp_tag_o(fp_tag_o),
    .fp_uop_o(fp_uop_w),
    .fp_operand_o(fp_operand_o),
    .serial_ready_i(serial_ready_i),
    .serial_fire_o(serial_fire_o),
    .serial_tag_o(serial_tag_o),
    .serial_uop_o(serial_uop_w),
    .serial_operand_o(serial_operand_w)
  );

  R64Scoreboard #(.BATCH_SUFFIX_ROLLBACK(BATCH_SUFFIX_ROLLBACK)) scoreboard (
    .batch_apply_i(batch_apply_i),.batch_greclaim_i(batch_greclaim_i),.batch_freclaim_i(batch_freclaim_i),
    .clk(clk), .rst(rst), .flush_i(flush_i),
    .birth_write_i(birth_i & birth_rd_write_i), .birth_fp_i(birth_rd_fp_i),
    .birth_preg_i(birth_preg_i),
    .wb_write_i(wb_write_i), .wb_fp_i(wb_fp_i), .wb_preg_i(wb_preg_i),
    .reclaim_write_i(reclaim_write_i), .reclaim_fp_i(reclaim_fp_i),
    .reclaim_preg_i(reclaim_preg_i),
    .query_preg_i(ready_query_preg_w), .query_fp_i(ready_query_fp_w),
    .query_ready_o(ready_query_canonical_w)
  );
  wire [5:0] fast_query_valid_w={
      raw_alu_token_resident_w & {2{ALU_TOKEN_BYPASS != 0}}, raw_alu_bypass_valid_w, raw_early_valid_w};
  wire [6*TAG_W-1:0] fast_query_tag_w={alu_token_tag_w, result_tag_o[0+:2*TAG_W], early_tag_w};
  wire [35:0] fast_query_preg_w={alu_token_preg_w, alu_bypass_preg_w, early_preg_w};
  wire [5:0] fast_accept_w;
  R64ExecutionOwners #(.TAG_W(TAG_W),.ROB_W(ROB_W),.QUERIES(6),.LOAD_QUERIES(4)) owners (
    .clk(clk),.rst(rst),.flush_i(flush_i),.kill_mask_i(kill_mask_i),
    .birth_i(birth_i),.birth_write_i(birth_rd_write_i),.birth_fp_i(birth_rd_fp_i),
    .birth_tag_i(birth_tag_i),.birth_preg_i(birth_preg_i),.birth_load_i(birth_load_w),
    .wb_accept_i(wb_accept_i),.wb_tag_i(wb_tag_i),
    .query_valid_i(fast_query_valid_w),.query_tag_i(fast_query_tag_w),
    .query_preg_i(fast_query_preg_w),.query_accept_o(fast_accept_w),
    .load_capture_i({load_notice_valid_w & {2{LOAD_RESOLVED_VALUE != 0}},
                     load_capture_i & {2{LOAD_COMPLETION_PROMISE != 0}}}),
    .load_tag_i({load_notice_tag_w,load_capture_tag_i}),
    .load_promise_o({resolved_valid_w,load_promise_w}),
    .load_preg_o({resolved_preg_w,load_preg_w})
  );
  assign {alu_token_valid_w, alu_bypass_valid_w, early_valid_w} = fast_accept_w;
  generate
    for (service_lane=0; service_lane<2; service_lane=service_lane+1) begin : gen_mem_command
      wire [U-1:0] uop_w=lsu_uop_w[service_lane*U+:U];
      wire [191:0] operand_w=lsu_operand_w[service_lane*192+:192];
      assign lsu_command_o[service_lane*`R64_MEM_CMD_W+:`R64_MEM_CMD_W] =
          {uop_w[155+:5], uop_w[`R64_U_FUNC], operand_w[64+:64],
           uop_w[`R64_U_ARG], operand_w[0+:64]};
    end
  endgenerate
  assign fp_command_o=fp_uop_w[`R64_UOP_CMD_LO+:`R64_FP_CMD_W];
  assign serial_command_o={(serial_uop_w[`R64_U_LEN] == 8), serial_uop_w[`R64_U_FUNC],
      serial_operand_w[64+:16], serial_operand_w[0+:64], serial_uop_w[`R64_U_CMD],
      serial_uop_w[`R64_U_PC]};
`ifdef R64_ASSERT
  assign audit_fast_valid_o=fast_accept_w[3:0];
  assign audit_fast_tag_o=fast_query_tag_w[0+:4*TAG_W];
  assign audit_fast_preg_o=fast_query_preg_w[23:0];
  assign audit_read_valid_o=read_valid_w;
  assign audit_read_tag_o=read_tag_w;
  assign audit_read_class_o=read_class_w;
  assign audit_issue_fire_o=issue_fire_w;
  assign audit_issue_tag_o=issue_tag_w;
  assign audit_issue_class_o=issue_class_w;
  assign audit_serial_owner_count_o=registers.serial_owner_count;
  always @(posedge clk)
    if (!rst && !flush_i) begin
      if (recovery_pending_w && birth_i!=0)
        $fatal(1, "Execution birth crossed its registered recovery inbox");
      if (early_valid_w == 3 && early_preg_w[0+:P] == early_preg_w[P+:P])
        $fatal(1, "R64 two live early ALUs own the same physical destination");
      if ((fast_accept_w & ~fast_query_valid_w) != 0)
        $fatal(1, "R64 execution accepted an absent fast-value query");
      for (integer lane=0; lane<2; lane=lane+1)
        if (issue_fire_w[lane] && issue_class_w[lane*3+:3] == `R64_C_SERIAL &&
            (issue_tag_w[lane*TAG_W+:TAG_W] != head_tag_i || registers.serial_owner_count != 0))
          $fatal(1, "Serial issue lacks unique execution-domain head ownership");
      if (serial_fire_o && registers.serial_owner_count != 1)
        $fatal(1, "Serial fire lacks unique execution-domain owner");
    end
`endif
endmodule
