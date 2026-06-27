`timescale 1ns/1ps
`include "include/define.v"

module tb_ooo_branch_append_dispatch_gate;
  localparam ROB_COUNT_W = 5;

  reg dispatch0_branch;
  reg return_cont_match;
  reg direct_branch0_lane1_ret;
  reg ctrl_commit_valid;
  reg commit_ready;
  reg core_commit0_valid;
  reg core_commit1_valid;
  reg [ROB_COUNT_W-1:0] rob_count;
  reg outstanding_valid;
  reg [`XLEN-1:0] outstanding_pc;
  reg [`XLEN-1:0] head_next_pc1;
  reg fetch_rsp_dispatch_bypass;
  reg branch_fallthrough_safe;
  reg branch_target_cache_hit;
  reg direct_branch0_fire;
  reg direct_branch_resolve_redirect;
  reg direct_branch_resolve_taken;
  reg dispatch1_ready;
  reg fetch_rsp_fire;
  reg branch_prefetch_active;
  reg branch_prefetch_buffer_valid;
  reg stop_pending;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg fetch_rsp_valid;
  reg [`XLEN-1:0] branch_prefetch_pc;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;
  reg direct_frontend_flush;
  reg branch_resolve_pending_match;
  reg branch_spec_active;
  reg core_branch_resolve_misaligned;
  reg branch_prefetch_buffer_match;
  reg branch_prefetch_dispatch0_safe;
  reg branch_prefetch_dispatch1_safe;
  reg branch_prefetch_rsp_dispatch0_safe;
  reg branch_prefetch_rsp_dispatch1_safe;
  reg branch_prefetch_hit_available;

  wire return_cont_optional;
  wire return_cont_attempt_ready;
  wire return_cont_attempt;
  wire branch_fallthrough_outstanding_match;
  wire branch_target_append_candidate;
  wire branch_fallthrough_append_safe;
  wire branch_fallthrough_append_candidate;
  wire branch_target_append_attempt;
  wire branch_fallthrough_append_attempt;
  wire synth_lane1_branch_append;
  wire branch_target_append;
  wire branch_fallthrough_append;
  wire return_cont_dispatch;
  wire branch_target_dispatch;
  wire branch_fallthrough_dispatch;
  wire branch_fallthrough_keep_outstanding;
  wire branch_fallthrough_capture_rsp;
  wire branch_prefetch_rsp_raw_match;
  wire branch_prefetch_dispatch_buffer;
  wire branch_prefetch_dispatch_rsp;
  wire branch_prefetch_dispatch_attempt;
  wire branch_prefetch_dispatch_fire;
  wire branch_prefetch_hit_to_fifo;
  wire dispatch1_optional;

  integer errors;

  OooBranchAppendDispatchGate #(
    .ROB_COUNT_W(ROB_COUNT_W)
  ) dut (
    .dispatch0_branch_i(dispatch0_branch),
    .return_cont_match_i(return_cont_match),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret),
    .ctrl_commit_valid_i(ctrl_commit_valid),
    .commit_ready_i(commit_ready),
    .core_commit0_valid_i(core_commit0_valid),
    .core_commit1_valid_i(core_commit1_valid),
    .rob_count_i(rob_count),
    .outstanding_valid_i(outstanding_valid),
    .outstanding_pc_i(outstanding_pc),
    .head_next_pc1_i(head_next_pc1),
    .fetch_rsp_dispatch_bypass_i(fetch_rsp_dispatch_bypass),
    .branch_fallthrough_safe_i(branch_fallthrough_safe),
    .branch_target_cache_hit_i(branch_target_cache_hit),
    .direct_branch0_fire_i(direct_branch0_fire),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken),
    .dispatch1_ready_i(dispatch1_ready),
    .fetch_rsp_fire_i(fetch_rsp_fire),
    .branch_prefetch_active_i(branch_prefetch_active),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid),
    .stop_pending_i(stop_pending),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .branch_prefetch_pc_i(branch_prefetch_pc),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .direct_frontend_flush_i(direct_frontend_flush),
    .branch_resolve_pending_match_i(branch_resolve_pending_match),
    .branch_spec_active_i(branch_spec_active),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned),
    .branch_prefetch_buffer_match_i(branch_prefetch_buffer_match),
    .branch_prefetch_dispatch0_safe_i(branch_prefetch_dispatch0_safe),
    .branch_prefetch_dispatch1_safe_i(branch_prefetch_dispatch1_safe),
    .branch_prefetch_rsp_dispatch0_safe_i(branch_prefetch_rsp_dispatch0_safe),
    .branch_prefetch_rsp_dispatch1_safe_i(branch_prefetch_rsp_dispatch1_safe),
    .branch_prefetch_hit_available_i(branch_prefetch_hit_available),
    .return_cont_optional_o(return_cont_optional),
    .return_cont_attempt_ready_o(return_cont_attempt_ready),
    .return_cont_attempt_o(return_cont_attempt),
    .branch_fallthrough_outstanding_match_o(
        branch_fallthrough_outstanding_match),
    .branch_target_append_candidate_o(branch_target_append_candidate),
    .branch_fallthrough_append_safe_o(branch_fallthrough_append_safe),
    .branch_fallthrough_append_candidate_o(
        branch_fallthrough_append_candidate),
    .branch_target_append_attempt_o(branch_target_append_attempt),
    .branch_fallthrough_append_attempt_o(branch_fallthrough_append_attempt),
    .synth_lane1_branch_append_o(synth_lane1_branch_append),
    .branch_target_append_o(branch_target_append),
    .branch_fallthrough_append_o(branch_fallthrough_append),
    .return_cont_dispatch_o(return_cont_dispatch),
    .branch_target_dispatch_o(branch_target_dispatch),
    .branch_fallthrough_dispatch_o(branch_fallthrough_dispatch),
    .branch_fallthrough_keep_outstanding_o(
        branch_fallthrough_keep_outstanding),
    .branch_fallthrough_capture_rsp_o(branch_fallthrough_capture_rsp),
    .branch_prefetch_rsp_raw_match_o(branch_prefetch_rsp_raw_match),
    .branch_prefetch_dispatch_buffer_o(branch_prefetch_dispatch_buffer),
    .branch_prefetch_dispatch_rsp_o(branch_prefetch_dispatch_rsp),
    .branch_prefetch_dispatch_attempt_o(branch_prefetch_dispatch_attempt),
    .branch_prefetch_dispatch_fire_o(branch_prefetch_dispatch_fire),
    .branch_prefetch_hit_to_fifo_o(branch_prefetch_hit_to_fifo),
    .dispatch1_optional_o(dispatch1_optional)
  );

  task check1;
    input [191:0] name;
    input got;
    input exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=%0b exp=%0b", name, got, exp);
      end
    end
  endtask

  task reset_inputs;
    begin
      dispatch0_branch = 1'b0;
      return_cont_match = 1'b0;
      direct_branch0_lane1_ret = 1'b0;
      ctrl_commit_valid = 1'b0;
      commit_ready = 1'b0;
      core_commit0_valid = 1'b0;
      core_commit1_valid = 1'b0;
      rob_count = {ROB_COUNT_W{1'b0}};
      outstanding_valid = 1'b0;
      outstanding_pc = 64'h8000_0008;
      head_next_pc1 = 64'h8000_0008;
      fetch_rsp_dispatch_bypass = 1'b0;
      branch_fallthrough_safe = 1'b0;
      branch_target_cache_hit = 1'b0;
      direct_branch0_fire = 1'b0;
      direct_branch_resolve_redirect = 1'b0;
      direct_branch_resolve_taken = 1'b0;
      dispatch1_ready = 1'b0;
      fetch_rsp_fire = 1'b0;
      branch_prefetch_active = 1'b0;
      branch_prefetch_buffer_valid = 1'b0;
      stop_pending = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      fetch_rsp_valid = 1'b0;
      branch_prefetch_pc = 64'h8000_1000;
      core_branch_resolve_next_pc = 64'h8000_1000;
      direct_frontend_flush = 1'b0;
      branch_resolve_pending_match = 1'b0;
      branch_spec_active = 1'b0;
      core_branch_resolve_misaligned = 1'b0;
      branch_prefetch_buffer_match = 1'b0;
      branch_prefetch_dispatch0_safe = 1'b0;
      branch_prefetch_dispatch1_safe = 1'b0;
      branch_prefetch_rsp_dispatch0_safe = 1'b0;
      branch_prefetch_rsp_dispatch1_safe = 1'b0;
      branch_prefetch_hit_available = 1'b0;
    end
  endtask

  initial begin
    errors = 0;

    reset_inputs();
    dispatch0_branch = 1'b1;
    return_cont_match = 1'b1;
    direct_branch0_lane1_ret = 1'b1;
    commit_ready = 1'b1;
    core_commit0_valid = 1'b1;
    core_commit1_valid = 1'b0;
    rob_count = {{(ROB_COUNT_W-1){1'b0}}, 1'b1};
    dispatch1_ready = 1'b1;
    #1;
    check1("return-cont optional", return_cont_optional, 1'b1);
    check1("return-cont attempt ready", return_cont_attempt_ready, 1'b1);
    check1("return-cont attempt disabled", return_cont_attempt, 1'b0);
    check1("synthetic append disabled", synth_lane1_branch_append, 1'b0);
    check1("return-cont dispatch disabled", return_cont_dispatch, 1'b0);
    check1("dispatch1 optional from return-cont", dispatch1_optional, 1'b1);

    reset_inputs();
    dispatch0_branch = 1'b1;
    branch_target_cache_hit = 1'b1;
    branch_fallthrough_safe = 1'b1;
    outstanding_valid = 1'b1;
    outstanding_pc = 64'h8000_0008;
    head_next_pc1 = 64'h8000_0008;
    direct_branch0_fire = 1'b1;
    direct_branch_resolve_redirect = 1'b1;
    direct_branch_resolve_taken = 1'b1;
    dispatch1_ready = 1'b1;
    #1;
    check1("fallthrough outstanding match",
           branch_fallthrough_outstanding_match, 1'b1);
    check1("target candidate", branch_target_append_candidate, 1'b1);
    check1("fallthrough safe with matching outstanding",
           branch_fallthrough_append_safe, 1'b1);
    check1("fallthrough candidate",
           branch_fallthrough_append_candidate, 1'b1);
    check1("target attempt disabled", branch_target_append_attempt, 1'b0);
    check1("target dispatch disabled", branch_target_dispatch, 1'b0);
    check1("dispatch1 optional from branch candidates",
           dispatch1_optional, 1'b1);

    reset_inputs();
    dispatch0_branch = 1'b1;
    branch_fallthrough_safe = 1'b1;
    outstanding_valid = 1'b1;
    outstanding_pc = 64'h8000_0010;
    head_next_pc1 = 64'h8000_0008;
    #1;
    check1("mismatched outstanding blocks fallthrough safe",
           branch_fallthrough_append_safe, 1'b0);
    fetch_rsp_dispatch_bypass = 1'b1;
    #1;
    check1("bypass response allows fallthrough safe",
           branch_fallthrough_append_safe, 1'b1);

    reset_inputs();
    branch_prefetch_active = 1'b1;
    branch_prefetch_buffer_valid = 1'b0;
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    fetch_rsp_valid = 1'b1;
    branch_prefetch_pc = 64'h8000_3000;
    core_branch_resolve_next_pc = 64'h8000_3000;
    #1;
    check1("branch prefetch rsp raw match",
           branch_prefetch_rsp_raw_match, 1'b1);
    branch_prefetch_buffer_valid = 1'b1;
    #1;
    check1("buffer valid blocks raw rsp match",
           branch_prefetch_rsp_raw_match, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_resolve_pending_match = 1'b1;
    branch_prefetch_buffer_match = 1'b1;
    branch_prefetch_dispatch0_safe = 1'b1;
    branch_prefetch_dispatch1_safe = 1'b1;
    branch_prefetch_rsp_dispatch0_safe = 1'b1;
    branch_prefetch_rsp_dispatch1_safe = 1'b1;
    branch_prefetch_active = 1'b1;
    fetch_rsp_valid = 1'b1;
    branch_prefetch_pc = 64'h8000_4000;
    core_branch_resolve_next_pc = 64'h8000_4000;
    branch_prefetch_hit_available = 1'b1;
    #1;
    check1("branch prefetch buffer dispatch disabled",
           branch_prefetch_dispatch_buffer, 1'b0);
    check1("branch prefetch rsp dispatch disabled",
           branch_prefetch_dispatch_rsp, 1'b0);
    check1("branch prefetch attempt disabled",
           branch_prefetch_dispatch_attempt, 1'b0);
    check1("branch prefetch fire disabled",
           branch_prefetch_dispatch_fire, 1'b0);
    check1("branch prefetch hit goes to fifo",
           branch_prefetch_hit_to_fifo, 1'b1);

    if (errors == 0) begin
      $display("[PASS] tb_ooo_branch_append_dispatch_gate");
      $finish;
    end
    $display("[FAIL] tb_ooo_branch_append_dispatch_gate errors=%0d", errors);
    $finish;
  end
endmodule
