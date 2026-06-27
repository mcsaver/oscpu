`timescale 1ns/1ps
`include "include/define.v"

module tb_ooo_branch_resolve_recovery_gate;
  reg stop_pending;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg [`XLEN-1:0] pending_branch_pc;
  reg branch_prefetch_match;
  reg core_branch_resolve_valid;
  reg [`XLEN-1:0] core_branch_resolve_pc;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;
  reg core_branch_resolve_misaligned;
  reg trap_redirect_squash;
  reg execute0_valid;
  reg execute1_valid;
  reg mem_rsp_ready;
  reg mem1_rsp_ready;
  reg branch_spec_checkpoint_pending;
  reg branch_spec_active;
  reg [`XLEN-1:0] branch_spec_pred_pc;
  reg core_mem_idle;
  reg core_pending_load_branch_dep;
  reg direct_branch_wait_pending;
  reg [`XLEN-1:0] direct_branch_wait_pc;
  reg direct_branch_resolve_valid;

  wire branch_resolve_pending_pc_match;
  wire branch_resolve_pending_match;
  wire branch_resolve_redirect;
  wire backend_execute_quiet;
  wire branch_spec_checkpoint_capture;
  wire branch_spec_resolve_valid;
  wire branch_spec_pred_match;
  wire branch_spec_restore;
  wire branch_spec_redirect;
  wire direct_branch_wait_resolve_match;
  wire direct_branch_wait_untracked;
  wire branch_resolve_untracked;
  wire branch_resolve_untracked_redirect;

  integer errors;

  OooBranchResolveRecoveryGate dut (
    .stop_pending_i(stop_pending),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .pending_branch_pc_i(pending_branch_pc),
    .branch_prefetch_match_i(branch_prefetch_match),
    .core_branch_resolve_valid_i(core_branch_resolve_valid),
    .core_branch_resolve_pc_i(core_branch_resolve_pc),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned),
    .trap_redirect_squash_i(trap_redirect_squash),
    .execute0_valid_i(execute0_valid),
    .execute1_valid_i(execute1_valid),
    .mem_rsp_ready_i(mem_rsp_ready),
    .mem1_rsp_ready_i(mem1_rsp_ready),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .branch_spec_active_i(branch_spec_active),
    .branch_spec_pred_pc_i(branch_spec_pred_pc),
    .core_mem_idle_i(core_mem_idle),
    .core_pending_load_branch_dep_i(core_pending_load_branch_dep),
    .direct_branch_wait_pending_i(direct_branch_wait_pending),
    .direct_branch_wait_pc_i(direct_branch_wait_pc),
    .direct_branch_resolve_valid_i(direct_branch_resolve_valid),
    .branch_resolve_pending_pc_match_o(branch_resolve_pending_pc_match),
    .branch_resolve_pending_match_o(branch_resolve_pending_match),
    .branch_resolve_redirect_o(branch_resolve_redirect),
    .backend_execute_quiet_o(backend_execute_quiet),
    .branch_spec_checkpoint_capture_o(branch_spec_checkpoint_capture),
    .branch_spec_resolve_valid_o(branch_spec_resolve_valid),
    .branch_spec_pred_match_o(branch_spec_pred_match),
    .branch_spec_restore_o(branch_spec_restore),
    .branch_spec_redirect_o(branch_spec_redirect),
    .direct_branch_wait_resolve_match_o(direct_branch_wait_resolve_match),
    .direct_branch_wait_untracked_o(direct_branch_wait_untracked),
    .branch_resolve_untracked_o(branch_resolve_untracked),
    .branch_resolve_untracked_redirect_o(branch_resolve_untracked_redirect)
  );

  task check1;
    input [127:0] name;
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
      stop_pending = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      pending_branch_pc = 64'h8000_0100;
      branch_prefetch_match = 1'b0;
      core_branch_resolve_valid = 1'b0;
      core_branch_resolve_pc = 64'h8000_0100;
      core_branch_resolve_next_pc = 64'h8000_0200;
      core_branch_resolve_misaligned = 1'b0;
      trap_redirect_squash = 1'b0;
      execute0_valid = 1'b0;
      execute1_valid = 1'b0;
      mem_rsp_ready = 1'b0;
      mem1_rsp_ready = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_pred_pc = 64'h8000_0200;
      core_mem_idle = 1'b0;
      core_pending_load_branch_dep = 1'b0;
      direct_branch_wait_pending = 1'b0;
      direct_branch_wait_pc = 64'h8000_0300;
      direct_branch_resolve_valid = 1'b0;
    end
  endtask

  initial begin
    errors = 0;

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    core_branch_resolve_valid = 1'b1;
    #1;
    check1("pending pc match", branch_resolve_pending_pc_match, 1'b1);
    check1("pending owner match", branch_resolve_pending_match, 1'b1);
    check1("tracked redirect", branch_resolve_redirect, 1'b1);

    branch_prefetch_match = 1'b1;
    #1;
    check1("prefetch hit blocks tracked redirect",
           branch_resolve_redirect, 1'b0);
    branch_prefetch_match = 1'b0;
    core_branch_resolve_misaligned = 1'b1;
    #1;
    check1("misaligned blocks tracked redirect",
           branch_resolve_redirect, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    core_branch_resolve_valid = 1'b1;
    trap_redirect_squash = 1'b1;
    #1;
    check1("trap squash masks tracked redirect",
           branch_resolve_redirect, 1'b0);
    check1("trap squash keeps pending match",
           branch_resolve_pending_match, 1'b1);

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_spec_checkpoint_pending = 1'b1;
    core_mem_idle = 1'b1;
    #1;
    check1("quiet backend", backend_execute_quiet, 1'b1);
    check1("checkpoint capture", branch_spec_checkpoint_capture, 1'b1);
    execute0_valid = 1'b1;
    #1;
    check1("execute busy blocks checkpoint",
           branch_spec_checkpoint_capture, 1'b0);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_spec_active = 1'b1;
    core_branch_resolve_valid = 1'b1;
    core_branch_resolve_next_pc = 64'h8000_0400;
    branch_spec_pred_pc = 64'h8000_0200;
    #1;
    check1("branch spec resolve valid", branch_spec_resolve_valid, 1'b1);
    check1("branch spec restore", branch_spec_restore, 1'b1);
    check1("branch spec redirect", branch_spec_redirect, 1'b1);
    core_branch_resolve_next_pc = branch_spec_pred_pc;
    #1;
    check1("branch spec prediction match", branch_spec_pred_match, 1'b1);
    check1("prediction match blocks restore", branch_spec_restore, 1'b0);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_spec_active = 1'b1;
    core_branch_resolve_valid = 1'b1;
    core_branch_resolve_misaligned = 1'b1;
    core_branch_resolve_next_pc = 64'h8000_0400;
    branch_spec_pred_pc = 64'h8000_0200;
    #1;
    check1("misaligned spec restore remains visible",
           branch_spec_restore, 1'b1);
    check1("misaligned spec redirect blocked", branch_spec_redirect, 1'b0);

    reset_inputs();
    direct_branch_wait_pending = 1'b1;
    direct_branch_wait_pc = 64'h8000_0300;
    core_branch_resolve_valid = 1'b1;
    core_branch_resolve_pc = 64'h8000_0300;
    #1;
    check1("direct wait resolve match",
           direct_branch_wait_resolve_match, 1'b1);
    check1("direct wait untracked", direct_branch_wait_untracked, 1'b1);
    check1("untracked redirect", branch_resolve_untracked_redirect, 1'b1);
    direct_branch_resolve_valid = 1'b1;
    #1;
    check1("direct resolve suppresses wait untracked",
           direct_branch_wait_untracked, 1'b0);

    reset_inputs();
    core_branch_resolve_valid = 1'b1;
    core_branch_resolve_pc = 64'h8000_0500;
    core_branch_resolve_misaligned = 1'b1;
    #1;
    check1("non-stop untracked resolve", branch_resolve_untracked, 1'b1);
    check1("misaligned untracked redirect blocked",
           branch_resolve_untracked_redirect, 1'b0);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_spec_active = 1'b1;
    direct_branch_wait_pending = 1'b1;
    direct_branch_wait_pc = 64'h8000_0100;
    core_branch_resolve_valid = 1'b1;
    core_branch_resolve_pc = 64'h8000_0100;
    core_branch_resolve_next_pc = 64'h8000_0400;
    branch_spec_pred_pc = 64'h8000_0200;
    #1;
    check1("branch spec suppresses untracked",
           branch_resolve_untracked, 1'b0);

    if (errors == 0) begin
      $display("[PASS] tb_ooo_branch_resolve_recovery_gate");
      $finish;
    end
    $display("[FAIL] tb_ooo_branch_resolve_recovery_gate errors=%0d", errors);
    $finish;
  end
endmodule
