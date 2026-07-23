`include "define.v"

module tb_ooo_pending_drain_resolve_gate;
  `include "tb_common.svh"

  localparam ROB_COUNT_W = 5;
  localparam ISSUE_COUNT_W = 4;

  reg [ROB_COUNT_W-1:0] rob_count;
  reg [ISSUE_COUNT_W-1:0] issue_count;
  reg synth_lane1_ret_pending;
  reg synth_lane1_branch_drop_pending;
  reg direct_frontend_flush;
  reg stop_pending;
  reg backend_drained_q;
  reg pending_control_ready;
  reg dispatch0_ready;
  reg branch_resolve_pending_match;
  reg branch_spec_active;
  reg branch_spec_checkpoint_pending;
  reg pending_arch_trap;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg pending_jump;
  reg pending_jump_dispatched;
  reg pending_jump_resolve_ready;
  reg pending_jump_nolink;
  reg pending_jump_misaligned;
  reg mem_retire_quiet;
  reg mem_idle;
  reg pending_system;
  reg pending_system_fence;
  reg pending_system_csr;
  reg pending_system_dispatched;
  reg system_csr_dispatch_cancel;

  wire backend_drained;
  wire jump_dispatch_valid;
  wire system_csr_dispatch_valid;
  wire system_csr_dispatch_fire;
  wire pending_branch_commit_resolve;
  wire pending_branch_match_clear;
  wire pending_replay_wait;
  wire drain_complete;

  integer rob_v;
  integer issue_v;
  integer mask;
  reg expected_drained;

  OooPendingDrainResolveGate #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) dut (
    .rob_count_i(rob_count),
    .issue_count_i(issue_count),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending),
    .direct_frontend_flush_i(direct_frontend_flush),
    .stop_pending_i(stop_pending),
    .backend_drained_q_i(backend_drained_q),
    .pending_control_ready_i(pending_control_ready),
    .dispatch0_ready_i(dispatch0_ready),
    .branch_resolve_pending_match_i(branch_resolve_pending_match),
    .branch_spec_active_i(branch_spec_active),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .pending_jump_i(pending_jump),
    .pending_jump_dispatched_i(pending_jump_dispatched),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready),
    .pending_jump_nolink_i(pending_jump_nolink),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .mem_retire_quiet_i(mem_retire_quiet),
    .mem_idle_i(mem_idle),
    .pending_system_i(pending_system),
    .pending_system_fence_i(pending_system_fence),
    .pending_system_csr_i(pending_system_csr),
    .pending_system_dispatched_i(pending_system_dispatched),
    .system_csr_dispatch_cancel_i(system_csr_dispatch_cancel),
    .backend_drained_o(backend_drained),
    .jump_dispatch_valid_o(jump_dispatch_valid),
    .system_csr_dispatch_valid_o(system_csr_dispatch_valid),
    .system_csr_dispatch_fire_o(system_csr_dispatch_fire),
    .pending_branch_commit_resolve_o(pending_branch_commit_resolve),
    .pending_branch_match_clear_o(pending_branch_match_clear),
    .pending_replay_wait_o(pending_replay_wait),
    .drain_complete_o(drain_complete)
  );

  task automatic clear_inputs;
    begin
      rob_count = {ROB_COUNT_W{1'b0}};
      issue_count = {ISSUE_COUNT_W{1'b0}};
      synth_lane1_ret_pending = 1'b0;
      synth_lane1_branch_drop_pending = 1'b0;
      direct_frontend_flush = 1'b0;
      stop_pending = 1'b0;
      backend_drained_q = 1'b0;
      pending_control_ready = 1'b0;
      dispatch0_ready = 1'b0;
      branch_resolve_pending_match = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      pending_arch_trap = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      pending_jump = 1'b0;
      pending_jump_dispatched = 1'b0;
      pending_jump_resolve_ready = 1'b0;
      pending_jump_nolink = 1'b0;
      pending_jump_misaligned = 1'b0;
      mem_retire_quiet = 1'b1;
      mem_idle = 1'b1;
      pending_system = 1'b0;
      pending_system_fence = 1'b0;
      pending_system_csr = 1'b0;
      pending_system_dispatched = 1'b0;
      system_csr_dispatch_cancel = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clear_inputs();
    #1;
    tb_check1("empty and quiet backend drains", backend_drained, 1'b1);

    // Exhaust every drain predicate over representative zero/non-zero counts.
    for (rob_v = 0; rob_v < 3; rob_v = rob_v + 1) begin
      for (issue_v = 0; issue_v < 3; issue_v = issue_v + 1) begin
        for (mask = 0; mask < 8; mask = mask + 1) begin
          rob_count = rob_v[ROB_COUNT_W-1:0];
          issue_count = issue_v[ISSUE_COUNT_W-1:0];
          synth_lane1_ret_pending = mask[0];
          synth_lane1_branch_drop_pending = mask[1];
          mem_retire_quiet = mask[2];
          expected_drained = (rob_v == 0) && (issue_v == 0) &&
                             !mask[0] && !mask[1] && mask[2];
          #1;
          tb_check1("exhaustive backend drain predicate",
                    backend_drained, expected_drained);
        end
      end
    end

    clear_inputs();
    pending_jump_resolve_ready = 1'b1;
    #1;
    tb_check1("link jump dispatch valid", jump_dispatch_valid, 1'b1);
    pending_jump_nolink = 1'b1;
    #1;
    tb_check1("nolink jump blocked", jump_dispatch_valid, 1'b0);
    pending_jump_nolink = 1'b0;
    pending_jump_misaligned = 1'b1;
    #1;
    tb_check1("misaligned jump blocked", jump_dispatch_valid, 1'b0);

    clear_inputs();
    stop_pending = 1'b1;
    pending_system = 1'b1;
    pending_system_csr = 1'b1;
    backend_drained_q = 1'b1;
    dispatch0_ready = 1'b1;
    #1;
    tb_check1("system CSR dispatch valid", system_csr_dispatch_valid, 1'b1);
    tb_check1("system CSR dispatch fire", system_csr_dispatch_fire, 1'b1);
    tb_check1("system CSR replay waits", pending_replay_wait, 1'b1);
    system_csr_dispatch_cancel = 1'b1;
    #1;
    tb_check1("cancel suppresses system CSR dispatch valid",
              system_csr_dispatch_valid, 1'b0);
    tb_check1("cancel suppresses system CSR dispatch fire",
              system_csr_dispatch_fire, 1'b0);

    clear_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    pending_control_ready = 1'b1;
    #1;
    tb_check1("drained branch commit resolves",
              pending_branch_commit_resolve, 1'b1);
    tb_check1("resolved branch no replay wait", pending_replay_wait, 1'b0);
    tb_check1("resolved branch drain complete", drain_complete, 1'b1);
    direct_frontend_flush = 1'b1;
    #1;
    tb_check1("direct flush blocks commit resolve",
              pending_branch_commit_resolve, 1'b0);

    clear_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_resolve_pending_match = 1'b1;
    #1;
    tb_check1("matching branch clears", pending_branch_match_clear, 1'b1);

    clear_inputs();
    pending_jump = 1'b1;
    #1;
    tb_check1("undispatched jump replay waits", pending_replay_wait, 1'b1);

    // T4L: SQ quiet alone is insufficient for ordinary FENCE.  A resident
    // MIQ entry, bridge transaction/buffer, or memory reservation keeps
    // mem_idle low and must block the control retirement edge.
    clear_inputs();
    stop_pending = 1'b1;
    pending_control_ready = 1'b1;
    pending_system = 1'b1;
    pending_system_fence = 1'b1;
    mem_idle = 1'b0;
    #1;
    tb_check1("fence backend base predicate is drained",
              backend_drained, 1'b1);
    tb_check1("fence waits for MIQ bridge reservation idle",
              drain_complete, 1'b0);
    mem_idle = 1'b1;
    #1;
    tb_check1("fence completes after full memory idle",
              drain_complete, 1'b1);

    // Preserve existing system behavior: the stronger mem_idle term is
    // scoped to ordinary FENCE only; WFI/SFENCE/FENCE.I/ECALL priority and
    // drain contracts do not gain an accidental extra dependency.
    clear_inputs();
    stop_pending = 1'b1;
    pending_control_ready = 1'b1;
    pending_system = 1'b1;
    mem_idle = 1'b0;
    #1;
    tb_check1("non-fence system keeps established drain contract",
              drain_complete, 1'b1);

    tb_finish("tb_ooo_pending_drain_resolve_gate");
  end
endmodule
