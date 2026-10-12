`timescale 1ns / 1ps
`include "R64Uop.vh"
// Real ROB + Commit + effect lease exercise the narrow store terminal at the
// architectural boundary, including same-edge dual retirement and precise trap.
module tb_r64_store_commit_overlap;
  localparam M = `R64_META_W;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, manual_flush = 0;
  wire commit_flush;
  wire flush = commit_flush || manual_flush;
  reg recovery_preview = 0, branch_kill = 0;
  reg [8:0] recovery_tag = 0, branch_tag = 0;
  wire [31:0] rob_kill;
  reg [1:0] av = 0, awr = 0, afp = 0, aser = 0, wv = 0, wx = 0;
  reg [2*M-1:0] am = 0;
  reg [17:0] wt = 0;
  wire [17:0] at;
  reg [127:0] wd = 0, wtval = 0;
  reg [11:0] wc = 0;
  reg [9:0] wf = 0;
  wire [1:0] ar, wa, cv, cr, cx, cwr, cfp;
  wire [17:0] ct;
  wire [2*M-1:0] cm;
  wire [127:0] cd, ctval;
  wire [11:0] cc;
  wire [9:0] cflags;
  wire recover, head_exception;
  wire [4:0] head;
  wire [5:0] count;
  reg [1:0] trace_ready = 3;
  reg irq = 0, serial_irrevocable = 0, force_recover = 0;
  reg [5:0] irq_cause = 7;
  reg [63:0] trap_target = 64'h80001000;
  wire [1:0] fire, retired;
  wire [127:0] npc;
  wire dirty, serial_commit, trap, interrupt, stop, redirect, effect_allow, serial_allow, trap_prepare;
  wire [4:0] flags;
  wire [8:0] serial_tag;
  wire [5:0] trap_cause;
  wire [63:0] epc, tval, redirect_target;
  reg sdv = 0, sde = 0;
  reg [8:0] sdt = 0;
  reg [63:0] sdval = 0;
  wire sdr, lease_valid;
  wire [8:0] lease_tag;
  reg [17:0] saved;
  reg [8:0] store_tag, alu_tag, old_store_tag;
  integer total = 0, pairs = 0, traps = 0, terminals = 0, cycles = 0;
  integer before_total, before_pairs, before_traps, before_terminals, j;
  wire resident_serial_candidate_rob;
  R64Rob rob (
    .serial_retire_candidate_o(resident_serial_candidate_rob),
    .batch_apply_o(),.batch_mask_o(),.batch_head_o(),.batch_desc_o(),

    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .store_done_valid_i(sdv),
    .store_done_ready_o(sdr),
    .store_done_tag_i(sdt),
    .store_done_error_i(sde),
    .store_done_tval_i(sdval),
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .recovery_preview_valid_i(recovery_preview),
    .recovery_preview_tag_i(recovery_tag),
    .kill_valid_i(branch_kill),
    .kill_tag_i(branch_tag),
    .reuse_block_i(32'b0),
    .resolve_valid_i(1'b0),
    .resolve_tag_i(9'b0),
    .resolve_npc_i(64'b0),
    .alloc_valid_i(av),
    .alloc_ready_o(ar),
    .alloc_tag_o(at),
    .alloc_meta_i(am),
    .alloc_rd_write_i(awr),
    .alloc_rd_fp_i(afp),
    .alloc_serial_i(aser),
    .alloc_rd_arch_i({5'd2, 5'd1}),
    .alloc_pnew_i({6'd34, 6'd33}),
    .alloc_pold_i({6'd2, 6'd1}),
    .wb_valid_i(wv),
    .wb_tag_i(wt),
    .wb_data_i(wd),
    .wb_exception_i(wx),
    .wb_cause_i(wc),
    .wb_tval_i(wtval),
    .wb_fflags_i(wf),
    .wb_accept_o(wa),
    .commit_ready_i(cr),
    .commit_valid_o(cv),
    .commit_tag_o(ct),
    .commit_meta_o(cm),
    .commit_data_o(cd),
    .commit_exception_o(cx),
    .commit_cause_o(cc),
    .commit_tval_o(ctval),
    .commit_fflags_o(cflags),
    .commit_rd_write_o(cwr),
    .commit_rd_fp_o(cfp),
    .recover_o(recover),
    .count_o(count),
    .kill_mask_o(rob_kill),
    .head_exception_o(head_exception), .head_slot_o(head)
  );
  R64Commit #(.HEAD_EXCEPTION_STOP(1)) dut (
    .serial_retire_candidate_i(resident_serial_candidate_rob),
    .trap_prepare_o(trap_prepare), .head_exception_i(head_exception),
    .clk_i(clk),
    .rst_i(rst),
    .rob_valid_i(cv),
    .rob_ready_o(cr),
    .rob_tag_i(ct),
    .rob_meta_i(cm),
    .rob_data_i(cd),
    .rob_exception_i(cx),
    .rob_cause_i(cc),
    .rob_tval_i(ctval),
    .rob_rd_write_i(cwr),
    .rob_rd_fp_i(cfp),
    .rob_fflags_i(cflags),
    .retire_ready_i(trace_ready),
    .rob_empty_i(count == 0),
    .recover_i(recover || force_recover),
    .lsu_irrevocable_i(lease_valid),
    .serial_irrevocable_i(serial_irrevocable),
    .irq_pending_i(irq),
    .irq_cause_i(irq_cause),
    .trap_target_i(trap_target),
    .retire_fire_o(fire),
    .retire_npc_o(npc),
    .retired_count_o(retired),
    .fp_dirty_o(dirty),
    .fp_flags_o(flags),
    .serial_commit_o(serial_commit),
    .serial_tag_o(serial_tag),
    .trap_o(trap),
    .trap_interrupt_o(interrupt),
    .trap_cause_o(trap_cause),
    .trap_pc_o(epc),
    .trap_tval_o(tval),
    .stop_birth_o(stop),
    .full_flush_o(commit_flush),
    .redirect_o(redirect),
    .redirect_target_o(redirect_target),
    .effect_allow_o(effect_allow),
    .serial_allow_o(serial_allow)
  );

  R64MemoryEffectLease lease (
    .clk_i(clk), .rst_i(rst), .head_present_i(count != 0),
    .successor_grant_i(1'b0), .successor_tag_i(9'b0),
    .head_tag_i(ct[8:0]), .head_kind_i(cm[196+:8]), .head_complete_i(cv[0]),
    .allow_i(effect_allow), .recover_i(recover), .flush_i(flush),
    .valid_o(lease_valid), .tag_o(lease_tag)
  );
  always @(posedge clk) if (!rst) begin
    cycles = cycles + 1;
    total = total + retired;
    if (fire == 3) pairs = pairs + 1;
    if (trap) traps = traps + 1;
    if (sdv && sdr) terminals = terminals + 1;
    if (cycles > 1500) $fatal(1, "store overlap timeout or combinational feedback");
  end
  task tick;
    begin @(posedge clk); #1; end
  endtask
  task check(input condition, input [767:0] message);
    begin if (condition !== 1'b1) $fatal(1, "%0s", message); end
  endtask
  function [M-1:0] meta(input [63:0] pc, input [7:0] kind);
    meta = {kind, 4'd4, pc+64'd4, 64'h13, pc};
  endfunction
  task birth(input [1:0] mask);
    begin
      av = mask; #1; check((ar & mask) == mask, "allocation credit");
      saved = at; tick; av = 0;
    end
  endtask
  task pair(input [63:0] pc);
    begin
      am = {meta(pc+4, 0), meta(pc, 3)}; awr = 2; aser = 0;
      birth(3); store_tag = saved[8:0]; alu_tag = saved[17:9];
      wt = {9'b0, alu_tag}; wv = 1; wd = 64'h123456789abcdef;
      #1; check(wa == 1, "younger ALU completion");
      tick; wv = 0;
      check(lease_valid && lease_tag == store_tag && cv == 0, "unfinished store lease");
    end
  endtask
  task success_terminal;
    begin
      sdt = store_tag; sdv = 1; sde = 0; sdval = 64'h80000018;
      #1;
      check(sdr && cv == 3 && fire == 3, "store terminal did not offer same-cycle dual retirement");
      check(ct == {alu_tag,store_tag} && cd[63:0] == 0 && cd[127:64] == 64'h123456789abcdef &&
            cx == 0 && cc[5:0] == 0 && ctval[63:0] == sdval && cflags[4:0] == 0 && !cwr[0],
            "forwarded terminal lost precise payload or resident identity");
      tick; sdv = 0;
    end
  endtask
  initial begin
    tick; rst = 0;
    before_total = total; before_pairs = pairs;
    pair(64'h80000000); success_terminal;
    check(count == 0 && !lease_valid && total-before_total == 2 && pairs-before_pairs == 1,
          "same-edge pair/lease/count result");

    // Array persistence keeps the same candidate when Trace holds retirement.
    pair(64'h80000020); trace_ready = 0;
    before_total = total; before_terminals = terminals;
    sdt = store_tag; sdv = 1; sde = 0; sdval = 64'h80000038;
    #1; check(sdr && cv == 3 && fire == 0, "Trace-held terminal not accepted");
    tick; sdv = 0;
    check(!lease_valid && !sdr && cv == 3, "terminal did not persist across lease release");
    repeat (4) begin
      tick;
      check(cv == 3 && ct[8:0] == store_tag && cd[63:0] == 0 && ctval[63:0] == 64'h80000038 &&
            cx == 0 && fire == 0, "Trace held terminal payload changed");
    end
    sdv = 1; sde = 1; sdval = 64'hdead;
    #1; check(!sdr && !cx[0], "duplicate terminal overwrote completed owner");
    tick; sdv = 0; trace_ready = 3; tick;
    check(count == 0 && total-before_total == 2 && terminals-before_terminals == 1,
          "backpressure duplicated completion or retirement");

    // Error is visible immediately but neither lane retires. The still-live
    // lease prevents early trap; it clears on the terminal edge before capture.
    pair(64'h80000040);
    before_total = total; before_traps = traps;
    sdt = store_tag; sdv = 1; sde = 1; sdval = 64'h80000ffd;
    #1;
    check(sdr && cv == 1 && cx == 1 && fire == 0 && cr == 0 && !head_exception,
          "error terminal prefix or resident exception certificate");
    check(cc[5:0] == 7 && ctval[63:0] == sdval && cd[63:0] == 0 && cflags[4:0] == 0 &&
          !cwr[0] && !trap_prepare && !flush, "error terminal precise payload");
    tick; sdv = 0; sde = 0; sdval = 0;
    check(!lease_valid && head_exception && cv == 1 && fire == 0 && !trap_prepare,
          "error edge did not preserve head and release lease");
    tick;
    check(trap_prepare && !flush && !trap && fire == 0, "exception event preparation");
    tick;
    check(trap && flush && epc == 64'h80000040 && tval == 64'h80000ffd &&
          trap_cause == 7 && !interrupt && fire == 0, "exact store access fault event");
    tick;
    check(count == 0 && total == before_total && traps-before_traps == 1,
          "faulting store or younger ALU retired");

    // Complete the older store during a younger branch recovery. Acceptance
    // persists in Q while candidates remain frozen through the undo walk.
    am = {meta(64'h80000064,0),meta(64'h80000060,3)}; awr = 2; birth(3);
    store_tag = saved[8:0]; alu_tag = saved[17:9];
    recovery_preview = 1; recovery_tag = alu_tag;
    wv = 1; wt = {9'b0,alu_tag}; wd = 64'h123456789abcdef;
    am = {meta(64'h8000006c,0),meta(64'h80000068,0)}; awr = 0; birth(3);
    recovery_preview = 0; wv = 0;
    branch_kill = 1; branch_tag = alu_tag; sdt = store_tag; sdv = 1; sde = 0; sdval = 64'h80000078;
    before_total = total; before_terminals = terminals;
    #1; check(sdr && cv == 0 && fire == 0, "recovery must freeze forwarded retirement");
    tick; sdv = 0; branch_kill = 0;
    check(recover && count == 2 && lease_valid, "recovery lost retained terminal lease");
    trace_ready = 0;
    while (recover) tick;
    check(cv == 3 && cd[63:0] == 0 && ctval[63:0] == 64'h80000078,
          "recovery lost stored completion");
    tick;
    check(!lease_valid, "completed recovered head did not release lease");
    trace_ready = 3; tick;
    check(count == 0 && total-before_total == 2 && terminals-before_terminals == 1,
          "recovery duplicated or lost retained retirement");

    // Wrong generation / slot / function / writer / serial certificates
    // cannot synthesize candidates before a real completion.
    pair(64'h80000080); trace_ready = 0;
    old_store_tag = store_tag;
    sdv = 1; sdt = store_tag ^ 9'h20; #1; check(!sdr && cv == 0, "wrong generation accepted"); tick;
    sdt = alu_tag; #1; check(!sdr && cv == 0, "wrong slot accepted"); tick;
    sdv = 0; trace_ready = 3; success_terminal;
    // A non-store resident head is not eligible, even with no destination.
    am = {meta(64'h80000094,0),meta(64'h80000090,0)}; awr = 0; birth(1);
    sdt = saved[8:0]; sdv = 1; #1; check(!sdr && cv == 0, "non-store accepted"); tick;
    sdv = 0; manual_flush = 1; tick; manual_flush = 0;
    am = {meta(64'h800000a4,0),meta(64'h800000a0,3)}; awr = 1; birth(1);
    sdt = saved[8:0]; sdv = 1; #1; check(!sdr && cv == 0, "writer store accepted");
    // Do not leave an artificial invalid store with an irrevocable lease.
    rst = 1; tick; rst = 0; sdv = 0;
    am = {meta(64'h800000b4,0),meta(64'h800000b0,3)}; awr = 0; aser = 1; birth(1);
    sdt = saved[8:0]; sdv = 1; #1; check(!sdr && cv == 0, "serial store accepted");
    rst = 1; tick; rst = 0; sdv = 0; aser = 0;

    // More than one ROB revolution proves count/head arithmetic and tag reuse.
    before_total = total; before_pairs = pairs;
    for (j = 0; j < 20; j = j + 1) begin
      pair(64'h80000100 + j*8); success_terminal;
      check(count == 0 && head == 5'((j+1)*2), "head wrap/count after forwarded pair");
    end
    check(total-before_total == 40 && pairs-before_pairs == 20, "wrap lost a retirement pair");
    check(store_tag[8:5] != old_store_tag[8:5], "generation did not advance on wrap");
    check(terminals >= 25 && traps == 1, "missing terminal/trap coverage");
    $display("[PASS] tb_r64_store_commit_overlap terminals=%0d retired=%0d dual_pairs=%0d traps=%0d same_edge_success_error_hold_recovery_wrap=1",
             terminals,total,pairs,traps);
    $finish;
  end
  initial begin #200000; $fatal(1, "store overlap timeout/combinational loop"); end
endmodule
