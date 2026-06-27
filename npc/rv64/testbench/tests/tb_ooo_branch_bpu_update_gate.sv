`timescale 1ns/1ps
`include "include/define.v"

module tb_ooo_branch_bpu_update_gate;
  reg direct_frontend_flush;
  reg can_run;
  reg fifo_has_packet;
  reg dispatch0_branch;
  reg direct_branch0_dispatch_valid;
  reg dispatch1_barrier_fire;
  reg head1_branch_raw;
  reg direct_branch_fire;
  reg direct_branch_bht_valid;
  reg head0_branch_bht_valid;
  reg head1_branch_bht_valid;
  reg direct_branch_resolve_valid;
  reg stop_pending;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg branch_resolve_pending_match;
  reg drain_complete;
  reg pending_branch_commit_resolve;
  reg core_branch_resolve_misaligned;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;
  reg [`XLEN-1:0] pending_branch_target;
  reg pending_branch_taken;
  reg direct_branch_resolve_taken;
  reg pending_branch_pred_taken;
  reg direct_branch_predict_taken;
  reg [`XLEN-1:0] pending_branch_pc;
  reg [`XLEN-1:0] direct_branch_pc;
  reg [`BPU_BHT_INDEX_W-1:0] pending_branch_bht_idx;
  reg [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx;

  wire branch_bpu_pending0_capture;
  wire branch_bpu_pending1_capture;
  wire branch_bpu_lookup_event;
  wire branch_bpu_lookup_bht_valid;
  wire branch_bpu_direct_update;
  wire branch_bpu_pending_update;
  wire branch_bpu_drained_update;
  wire branch_bpu_commit_update;
  wire branch_bpu_update_valid;
  wire branch_bpu_pending_like_update;
  wire branch_bpu_update_taken;
  wire branch_bpu_update_pred_taken;
  wire branch_bpu_update_correct;
  wire [`XLEN-1:0] branch_bpu_update_pc;
  wire [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx;

  integer errors;

  OooBranchBpuUpdateGate dut (
    .direct_frontend_flush_i(direct_frontend_flush),
    .can_run_i(can_run),
    .fifo_has_packet_i(fifo_has_packet),
    .dispatch0_branch_i(dispatch0_branch),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head1_branch_raw_i(head1_branch_raw),
    .direct_branch_fire_i(direct_branch_fire),
    .direct_branch_bht_valid_i(direct_branch_bht_valid),
    .head0_branch_bht_valid_i(head0_branch_bht_valid),
    .head1_branch_bht_valid_i(head1_branch_bht_valid),
    .direct_branch_resolve_valid_i(direct_branch_resolve_valid),
    .stop_pending_i(stop_pending),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .branch_resolve_pending_match_i(branch_resolve_pending_match),
    .drain_complete_i(drain_complete),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .pending_branch_target_i(pending_branch_target),
    .pending_branch_taken_i(pending_branch_taken),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken),
    .pending_branch_pred_taken_i(pending_branch_pred_taken),
    .direct_branch_predict_taken_i(direct_branch_predict_taken),
    .pending_branch_pc_i(pending_branch_pc),
    .direct_branch_pc_i(direct_branch_pc),
    .pending_branch_bht_idx_i(pending_branch_bht_idx),
    .direct_branch_bht_idx_i(direct_branch_bht_idx),
    .branch_bpu_pending0_capture_o(branch_bpu_pending0_capture),
    .branch_bpu_pending1_capture_o(branch_bpu_pending1_capture),
    .branch_bpu_lookup_event_o(branch_bpu_lookup_event),
    .branch_bpu_lookup_bht_valid_o(branch_bpu_lookup_bht_valid),
    .branch_bpu_direct_update_o(branch_bpu_direct_update),
    .branch_bpu_pending_update_o(branch_bpu_pending_update),
    .branch_bpu_drained_update_o(branch_bpu_drained_update),
    .branch_bpu_commit_update_o(branch_bpu_commit_update),
    .branch_bpu_update_valid_o(branch_bpu_update_valid),
    .branch_bpu_pending_like_update_o(branch_bpu_pending_like_update),
    .branch_bpu_update_taken_o(branch_bpu_update_taken),
    .branch_bpu_update_pred_taken_o(branch_bpu_update_pred_taken),
    .branch_bpu_update_correct_o(branch_bpu_update_correct),
    .branch_bpu_update_pc_o(branch_bpu_update_pc),
    .branch_bpu_update_bht_idx_o(branch_bpu_update_bht_idx)
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

  task check64;
    input [191:0] name;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=0x%016x exp=0x%016x", name, got, exp);
      end
    end
  endtask

  task check_bht;
    input [191:0] name;
    input [`BPU_BHT_INDEX_W-1:0] got;
    input [`BPU_BHT_INDEX_W-1:0] exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=0x%0x exp=0x%0x", name, got, exp);
      end
    end
  endtask

  task reset_inputs;
    begin
      direct_frontend_flush = 1'b0;
      can_run = 1'b0;
      fifo_has_packet = 1'b0;
      dispatch0_branch = 1'b0;
      direct_branch0_dispatch_valid = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      head1_branch_raw = 1'b0;
      direct_branch_fire = 1'b0;
      direct_branch_bht_valid = 1'b0;
      head0_branch_bht_valid = 1'b0;
      head1_branch_bht_valid = 1'b0;
      direct_branch_resolve_valid = 1'b0;
      stop_pending = 1'b0;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      branch_resolve_pending_match = 1'b0;
      drain_complete = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      core_branch_resolve_misaligned = 1'b0;
      core_branch_resolve_next_pc = 64'h8000_0200;
      pending_branch_target = 64'h8000_0200;
      pending_branch_taken = 1'b0;
      direct_branch_resolve_taken = 1'b0;
      pending_branch_pred_taken = 1'b0;
      direct_branch_predict_taken = 1'b0;
      pending_branch_pc = 64'h8000_0100;
      direct_branch_pc = 64'h8000_1000;
      pending_branch_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      direct_branch_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
    end
  endtask

  initial begin
    errors = 0;

    reset_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch0_branch = 1'b1;
    head0_branch_bht_valid = 1'b1;
    #1;
    check1("lane0 pending capture", branch_bpu_pending0_capture, 1'b1);
    check1("lookup event lane0", branch_bpu_lookup_event, 1'b1);
    check1("lookup bht valid lane0", branch_bpu_lookup_bht_valid, 1'b1);
    direct_branch0_dispatch_valid = 1'b1;
    #1;
    check1("direct dispatch blocks pending0",
           branch_bpu_pending0_capture, 1'b0);

    reset_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch1_barrier_fire = 1'b1;
    head1_branch_raw = 1'b1;
    head1_branch_bht_valid = 1'b1;
    #1;
    check1("lane1 pending capture", branch_bpu_pending1_capture, 1'b1);
    check1("lookup bht valid lane1", branch_bpu_lookup_bht_valid, 1'b1);
    direct_frontend_flush = 1'b1;
    #1;
    check1("flush blocks lane1 capture", branch_bpu_pending1_capture, 1'b0);

    reset_inputs();
    direct_branch_fire = 1'b1;
    direct_branch_bht_valid = 1'b1;
    #1;
    check1("direct lookup event", branch_bpu_lookup_event, 1'b1);
    check1("direct lookup bht valid", branch_bpu_lookup_bht_valid, 1'b1);

    reset_inputs();
    direct_branch_resolve_valid = 1'b1;
    direct_branch_resolve_taken = 1'b1;
    direct_branch_predict_taken = 1'b1;
    direct_branch_pc = 64'h8000_1004;
    direct_branch_bht_idx = 12'h123;
    #1;
    check1("direct update class", branch_bpu_direct_update, 1'b1);
    check1("direct update valid", branch_bpu_update_valid, 1'b1);
    check1("direct update taken", branch_bpu_update_taken, 1'b1);
    check1("direct pred selected", branch_bpu_update_pred_taken, 1'b1);
    check1("direct update correct", branch_bpu_update_correct, 1'b1);
    check64("direct update pc", branch_bpu_update_pc, 64'h8000_1004);
    check_bht("direct update bht", branch_bpu_update_bht_idx, 12'h123);

    reset_inputs();
    direct_branch_resolve_valid = 1'b1;
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_resolve_pending_match = 1'b1;
    core_branch_resolve_next_pc = 64'h8000_2200;
    pending_branch_target = 64'h8000_2200;
    pending_branch_pred_taken = 1'b0;
    direct_branch_predict_taken = 1'b1;
    pending_branch_pc = 64'h8000_2000;
    direct_branch_pc = 64'h8000_3000;
    pending_branch_bht_idx = 12'h456;
    direct_branch_bht_idx = 12'h789;
    #1;
    check1("pending update class", branch_bpu_pending_update, 1'b1);
    check1("pending-like update", branch_bpu_pending_like_update, 1'b1);
    check1("pending target match taken", branch_bpu_update_taken, 1'b1);
    check1("pending pred selected", branch_bpu_update_pred_taken, 1'b0);
    check1("pending update incorrect", branch_bpu_update_correct, 1'b0);
    check64("pending update pc wins", branch_bpu_update_pc, 64'h8000_2000);
    check_bht("pending update bht wins", branch_bpu_update_bht_idx, 12'h456);
    core_branch_resolve_misaligned = 1'b1;
    #1;
    check1("misaligned pending update not taken",
           branch_bpu_update_taken, 1'b0);

    reset_inputs();
    stop_pending = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b0;
    drain_complete = 1'b1;
    pending_branch_taken = 1'b1;
    pending_branch_pred_taken = 1'b1;
    pending_branch_pc = 64'h8000_4000;
    pending_branch_bht_idx = 12'habc;
    #1;
    check1("drained update class", branch_bpu_drained_update, 1'b1);
    check1("drained update taken", branch_bpu_update_taken, 1'b1);
    check1("drained update correct", branch_bpu_update_correct, 1'b1);
    check64("drained update pc", branch_bpu_update_pc, 64'h8000_4000);
    check_bht("drained update bht", branch_bpu_update_bht_idx, 12'habc);

    reset_inputs();
    pending_branch_commit_resolve = 1'b1;
    pending_branch_taken = 1'b0;
    pending_branch_pred_taken = 1'b1;
    pending_branch_pc = 64'h8000_5000;
    pending_branch_bht_idx = 12'hdef;
    #1;
    check1("commit update class", branch_bpu_commit_update, 1'b1);
    check1("commit update valid", branch_bpu_update_valid, 1'b1);
    check1("commit update uses pending taken", branch_bpu_update_taken, 1'b0);
    check1("commit update incorrect", branch_bpu_update_correct, 1'b0);
    check64("commit update pc", branch_bpu_update_pc, 64'h8000_5000);
    check_bht("commit update bht", branch_bpu_update_bht_idx, 12'hdef);

    if (errors == 0) begin
      $display("[PASS] tb_ooo_branch_bpu_update_gate");
      $finish;
    end
    $display("[FAIL] tb_ooo_branch_bpu_update_gate errors=%0d", errors);
    $finish;
  end
endmodule
