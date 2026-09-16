`timescale 1ns/1ps

module tb_ooo_pending_system_admission_cancel_gate;
  reg rst_i;
  reg core_local_flush_i;
  reg csr_trap_mem_valid_i;
  reg branch_spec_resolve_valid_i;
  reg pending_branch_commit_resolve_i;
  reg pending_branch_match_clear_i;
  reg branch_resolve_untracked_i;
  reg pending_jump_resolve_ready_i;
  reg pending_jump_misaligned_i;
  reg pending_jump_nolink_commit_i;
  reg pending_jump_redirect_after_dispatch_i;
  reg pending_system_csr_commit_i;
  reg head0_csr_commit_i;
  wire system_csr_admission_clear_o;
  wire system_csr_dispatch_cancel_o;
  integer checks;

  OooPendingSystemAdmissionCancelGate dut (
    .rst_i(rst_i),
    .core_local_flush_i(core_local_flush_i),
    .csr_trap_mem_valid_i(csr_trap_mem_valid_i),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid_i),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_i),
    .pending_branch_match_clear_i(pending_branch_match_clear_i),
    .branch_resolve_untracked_i(branch_resolve_untracked_i),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_i),
    .pending_jump_misaligned_i(pending_jump_misaligned_i),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit_i),
    .pending_jump_redirect_after_dispatch_i(
        pending_jump_redirect_after_dispatch_i),
    .pending_system_csr_commit_i(pending_system_csr_commit_i),
    .head0_csr_commit_i(head0_csr_commit_i),
    .system_csr_admission_clear_o(system_csr_admission_clear_o),
    .system_csr_dispatch_cancel_o(system_csr_dispatch_cancel_o)
  );

  task expect_outputs;
    input expected_clear;
    input expected_cancel;
    input [511:0] label;
    begin
      #1;
      checks = checks + 1;
      if ((system_csr_admission_clear_o !== expected_clear) ||
          (system_csr_dispatch_cancel_o !== expected_cancel)) begin
        $display("FAIL %0s clear=%b/%b cancel=%b/%b", label,
                 system_csr_admission_clear_o, expected_clear,
                 system_csr_dispatch_cancel_o, expected_cancel);
        $fatal;
      end
    end
  endtask

  initial begin
    checks = 0;
    rst_i = 0;
    core_local_flush_i = 0;
    csr_trap_mem_valid_i = 0;
    branch_spec_resolve_valid_i = 0;
    pending_branch_commit_resolve_i = 0;
    pending_branch_match_clear_i = 0;
    branch_resolve_untracked_i = 0;
    pending_jump_resolve_ready_i = 0;
    pending_jump_misaligned_i = 0;
    pending_jump_nolink_commit_i = 0;
    pending_jump_redirect_after_dispatch_i = 0;
    pending_system_csr_commit_i = 0;
    head0_csr_commit_i = 0;
    expect_outputs(0, 0, "idle");

    // A level-ready without an actual jump clear outcome must not permanently
    // cancel an unrelated pending CSR replay.
    pending_jump_resolve_ready_i = 1;
    expect_outputs(0, 0, "stuck ready without clear qualification");

    pending_jump_resolve_ready_i = 0;
    pending_jump_misaligned_i = 1;
    expect_outputs(0, 0, "outcome without ready is not yet a clear");
    pending_jump_resolve_ready_i = 1;
    expect_outputs(1, 1, "held outcome becomes clear when ready arrives");
    pending_jump_misaligned_i = 0;
    pending_jump_nolink_commit_i = 1;
    expect_outputs(1, 1, "ready plus nolink commit is a real clear");
    pending_jump_nolink_commit_i = 0;
    pending_jump_redirect_after_dispatch_i = 1;
    expect_outputs(1, 1, "ready plus redirect is a real clear");
    pending_jump_redirect_after_dispatch_i = 0;
    pending_jump_resolve_ready_i = 0;

    csr_trap_mem_valid_i = 1;
    expect_outputs(1, 0,
                   "memory trap clears holder behind C0 dispatch closure");
    csr_trap_mem_valid_i = 0;
    branch_spec_resolve_valid_i = 1;
    expect_outputs(1, 1, "branch-spec resolve cancels admission");
    branch_spec_resolve_valid_i = 0;
    branch_resolve_untracked_i = 1;
    expect_outputs(1, 1, "untracked branch resolve cancels admission");
    branch_resolve_untracked_i = 0;
    pending_system_csr_commit_i = 1;
    expect_outputs(1, 0,
                   "exact pending CSR death clears holder without redispatch cancel");
    pending_system_csr_commit_i = 0;

    // 这两路是 direct-fire 后置优先级产生的 branch-owner terminal，保留在
    // full-clear 观测中，但不得重新取得 pending CSR admission 权限。
    pending_branch_commit_resolve_i = 1;
    expect_outputs(1, 0, "branch commit terminal is observation only");
    pending_branch_commit_resolve_i = 0;
    pending_branch_match_clear_i = 1;
    expect_outputs(1, 0, "branch match terminal is observation only");
    pending_branch_match_clear_i = 0;

    head0_csr_commit_i = 1;
    expect_outputs(1, 0,
                   "head0 CSR death clears holder outside dispatch cancel");
    head0_csr_commit_i = 0;
    core_local_flush_i = 1;
    expect_outputs(0, 1, "backend flush cancels without ordinary clear");
    core_local_flush_i = 0;
    rst_i = 1;
    expect_outputs(0, 1, "reset cancels without ordinary clear");

    $display("[INFO] admission-cancel checks=%0d", checks);
    $display("[V15P-PENDING-CSR-FEEDBACK-FREE] PASS");
    $display("[V15V-CSR-COMMIT-DISPATCH-DISJOINT] clear=1 cancel=0 PASS");
    $display("[V15W-HEAD0-CSR-ADMISSION-CLEAR] clear=1 cancel=0 PASS");
    $display("[V15X-TRAP-C0-DISPATCH-CLOSURE] clear=1 cancel=0 PASS");
    $display("PASS tb_ooo_pending_system_admission_cancel_gate");
    $finish;
  end
endmodule
