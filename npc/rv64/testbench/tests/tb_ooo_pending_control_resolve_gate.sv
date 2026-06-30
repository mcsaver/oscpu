`timescale 1ns/1ps
`include "include/define.v"

module tb_ooo_pending_control_resolve_gate;
  reg pending_branch;
  reg pending_branch_taken;
  reg [`XLEN-1:0] pending_branch_target;
  reg [`XLEN-1:0] pending_branch_next_pc_in;
  reg stop_pending;
  reg pending_jump;
  reg pending_jump_jalr;
  reg pending_jump_dispatched;
  reg backend_drained;
  reg [`XLEN-1:0] pending_jump_pc;
  reg [`XLEN-1:0] pending_jump_imm;
  reg [`XLEN-1:0] pending_jump_rs1_data;
  reg [`INST_W-1:0] pending_jump_inst;
  reg [`REG_ADDR_W-1:0] pending_jump_rs1;
  reg ras_empty;
  reg jump_dispatch_fire;
  reg commit_ready;

  wire [`XLEN-1:0] pending_branch_fallthrough;
  wire [`XLEN-1:0] pending_branch_next_pc;
  wire pending_branch_misaligned;
  wire pending_jump_jalr_sum_lsb;
  wire [`XLEN-1:0] pending_jump_resolved_target;
  wire pending_jump_misaligned;
  wire pending_jump_resolve_ready;
  wire pending_jump_return;
  wire pending_jump_return_fire;
  wire pending_jump_call;
  wire pending_jump_call_fire;
  wire pending_jump_nolink;
  wire pending_jump_nolink_commit;
  wire pending_jump_redirect_after_dispatch;
  wire pending_control_ready;

  integer errors;

  OooPendingControlResolveGate dut (
    .pending_branch_i(pending_branch),
    .pending_branch_taken_i(pending_branch_taken),
    .pending_branch_target_i(pending_branch_target),
    .pending_branch_next_pc_i(pending_branch_next_pc_in),
    .stop_pending_i(stop_pending),
    .pending_jump_i(pending_jump),
    .pending_jump_jalr_i(pending_jump_jalr),
    .pending_jump_dispatched_i(pending_jump_dispatched),
    .backend_drained_i(backend_drained),
    .pending_jump_pc_i(pending_jump_pc),
    .pending_jump_imm_i(pending_jump_imm),
    .pending_jump_rs1_data_i(pending_jump_rs1_data),
    .pending_jump_inst_i(pending_jump_inst),
    .pending_jump_rs1_i(pending_jump_rs1),
    .ras_empty_i(ras_empty),
    .jump_dispatch_fire_i(jump_dispatch_fire),
    .commit_ready_i(commit_ready),
    .pending_branch_fallthrough_o(pending_branch_fallthrough),
    .pending_branch_next_pc_o(pending_branch_next_pc),
    .pending_branch_misaligned_o(pending_branch_misaligned),
    .pending_jump_jalr_sum_lsb_o(pending_jump_jalr_sum_lsb),
    .pending_jump_resolved_target_o(pending_jump_resolved_target),
    .pending_jump_misaligned_o(pending_jump_misaligned),
    .pending_jump_resolve_ready_o(pending_jump_resolve_ready),
    .pending_jump_return_o(pending_jump_return),
    .pending_jump_return_fire_o(pending_jump_return_fire),
    .pending_jump_call_o(pending_jump_call),
    .pending_jump_call_fire_o(pending_jump_call_fire),
    .pending_jump_nolink_o(pending_jump_nolink),
    .pending_jump_nolink_commit_o(pending_jump_nolink_commit),
    .pending_jump_redirect_after_dispatch_o(
        pending_jump_redirect_after_dispatch),
    .pending_control_ready_o(pending_control_ready)
  );

  task check1;
    input [159:0] name;
    input got;
    input exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=%0b exp=%0b", name, got, exp);
      end
    end
  endtask

  task check64;
    input [159:0] name;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=0x%016x exp=0x%016x", name, got, exp);
      end
    end
  endtask

  task reset_inputs;
    begin
      pending_branch = 1'b0;
      pending_branch_taken = 1'b0;
      pending_branch_target = 64'h8000_0200;
      pending_branch_next_pc_in = 64'h8000_0104;
      stop_pending = 1'b0;
      pending_jump = 1'b0;
      pending_jump_jalr = 1'b0;
      pending_jump_dispatched = 1'b0;
      backend_drained = 1'b0;
      pending_jump_pc = 64'h8000_1000;
      pending_jump_imm = 64'h20;
      pending_jump_rs1_data = 64'h8000_2000;
      pending_jump_inst = 32'h0000_006f;
      pending_jump_rs1 = 5'd0;
      ras_empty = 1'b1;
      jump_dispatch_fire = 1'b0;
      commit_ready = 1'b0;
    end
  endtask

  initial begin
    errors = 0;

    reset_inputs();
    #1;
    check64("branch fallthrough", pending_branch_fallthrough, 64'h8000_0104);
    check64("branch not taken next", pending_branch_next_pc, 64'h8000_0104);
    check1("branch not taken aligned", pending_branch_misaligned, 1'b0);
    pending_branch_taken = 1'b1;
    pending_branch_target = 64'h8000_0201;
    #1;
    check64("branch taken target", pending_branch_next_pc, 64'h8000_0201);
    check1("branch taken misaligned", pending_branch_misaligned, 1'b1);

    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    backend_drained = 1'b1;
    #1;
    check1("jump resolve ready", pending_jump_resolve_ready, 1'b1);
    check64("jal target", pending_jump_resolved_target, 64'h8000_1020);
    pending_jump_dispatched = 1'b1;
    #1;
    check1("dispatched blocks resolve ready", pending_jump_resolve_ready, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    backend_drained = 1'b1;
    pending_jump_rs1_data = 64'h8000_2001;
    pending_jump_imm = 64'h2;
    #1;
    check1("jalr raw sum lsb", pending_jump_jalr_sum_lsb, 1'b1);
    check64("jalr clears target lsb",
            pending_jump_resolved_target, 64'h8000_2002);
    check1("resolved target aligned", pending_jump_misaligned, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd0;
    pending_jump_rs1 = 5'd1;
    pending_jump_imm = 64'h0;
    ras_empty = 1'b0;
    jump_dispatch_fire = 1'b1;
    #1;
    check1("return hint", pending_jump_return, 1'b1);
    check1("return fire", pending_jump_return_fire, 1'b1);
    check1("return is not nolink", pending_jump_nolink, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd0;
    pending_jump_rs1 = 5'd1;
    pending_jump_imm = 64'h0;
    ras_empty = 1'b1;
    commit_ready = 1'b1;
    #1;
    check1("ras empty blocks return", pending_jump_return, 1'b0);
    check1("nolink commit", pending_jump_nolink_commit, 1'b1);

    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd1;
    jump_dispatch_fire = 1'b1;
    #1;
    check1("call hint", pending_jump_call, 1'b1);
    check1("call fire", pending_jump_call_fire, 1'b1);
    check1("redirect after dispatch",
           pending_jump_redirect_after_dispatch, 1'b1);

    // ----------------------------------------------------------------------
    // De-pend (mode=1, `OOO_ROB_WALK_MODE`) turns branch/jump into pure
    // out-of-order speculative dispatch + backend forced-mispredict redirect.
    // The legacy pending+drain "misalign blocks the RAS call-fire / post-
    // dispatch redirect" gating only lives on the mode=0 pending path, which
    // is bypassed (dead) in the production build. define.v (included above)
    // defines OOO_ROB_WALK_MODE, so the `ifndef block is compiled out of the
    // production run and the `ifdef block validates the real mode=1 contract.
    // ----------------------------------------------------------------------
`ifndef OOO_ROB_WALK_MODE
    // mode=0 legacy pending+drain: a genuinely misaligned resolved target
    // (JAL with an odd immediate -> target LSB set) must block both the RAS
    // call push-fire and the post-dispatch redirect.
    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b0;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd1;
    pending_jump_imm = 64'h21;
    jump_dispatch_fire = 1'b1;
    #1;
    check1("mode0 misaligned jump target",
           pending_jump_misaligned, 1'b1);
    check1("misaligned jump blocks call fire",
           pending_jump_call_fire, 1'b0);
    check1("misaligned jump blocks redirect",
           pending_jump_redirect_after_dispatch, 1'b0);
`endif

`ifdef OOO_ROB_WALK_MODE
    // mode=1 de-pend contract (production): the JALR datapath force-clears the
    // target LSB ({sum[XLEN-1:1],1'b0}), so an ALIGNED JALR call resolves and
    // FIRES its RAS push + post-dispatch redirect -- this speculative-dispatch
    // fire REPLACES the old mode=0 "misalign blocks" expectation. The very
    // inputs that the legacy assertion expected to block (rs1+imm=0x8000_0001
    // -> resolved 0x8000_0000, aligned) now correctly fire.
    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd1;
    pending_jump_rs1_data = 64'h8000_0001;
    pending_jump_imm = 64'h0;
    jump_dispatch_fire = 1'b1;
    #1;
    check1("depend aligned jalr not misaligned",
           pending_jump_misaligned, 1'b0);
    check1("depend aligned jalr call fires",
           pending_jump_call_fire, 1'b1);
    check1("depend aligned jalr redirect fires",
           pending_jump_redirect_after_dispatch, 1'b1);
    // ...but a genuinely misaligned resolved target (odd JAL target -> LSB set)
    // still gates both the call-fire and the redirect, even in de-pend mode.
    reset_inputs();
    stop_pending = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b0;
    backend_drained = 1'b1;
    pending_jump_inst[11:7] = 5'd1;
    pending_jump_imm = 64'h21;
    jump_dispatch_fire = 1'b1;
    #1;
    check1("depend misaligned jump target",
           pending_jump_misaligned, 1'b1);
    check1("depend misaligned blocks call fire",
           pending_jump_call_fire, 1'b0);
    check1("depend misaligned blocks redirect",
           pending_jump_redirect_after_dispatch, 1'b0);
`endif

    reset_inputs();
    pending_branch = 1'b1;
    commit_ready = 1'b0;
    #1;
    check1("pending branch waits for commit", pending_control_ready, 1'b0);
    commit_ready = 1'b1;
    #1;
    check1("commit readies pending control", pending_control_ready, 1'b1);
    pending_branch = 1'b0;
    commit_ready = 1'b0;
    #1;
    check1("no pending branch is ready", pending_control_ready, 1'b1);

    if (errors == 0) begin
      $display("[PASS] tb_ooo_pending_control_resolve_gate");
      $finish;
    end
    $display("[FAIL] tb_ooo_pending_control_resolve_gate errors=%0d", errors);
    $finish;
  end
endmodule
