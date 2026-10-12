`timescale 1ns / 1ps
`include "R64Uop.vh"
// Native issue/rename/ROB/RegRead/execute with a finite, commit-authorized
// LSQ model. Young stores cannot complete until they are the actual ROB head.
// No force, invented wakeup or relaxed progress assertion is used.
module tb_r64_mem_admission;
  localparam U = `R64_UOP_W, M = `R64_META_W, R = `R64_RESULT_W, T = 9, N = 20;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0, stop = 0;
  reg [1:0] fv = 0, cr = 3;
  wire [1:0] fr, cv, cwr, cfp, cx;
  reg [127:0] fpc = 0, raw = 0, pred = 0;
  reg [7:0] lengths = 8'h44;
  wire [2*T-1:0] ct;
  wire [2*M-1:0] cm;
  wire [127:0] cd, ctval;
  wire [9:0] ca, cflags;
  wire [11:0] cc;
  wire redir, resolve, conditional, indirect, taken, recover;
  wire [63:0] target, rpc, rnpc;
  wire [T-1:0] rtag, htag;
  wire [31:0] km;
  // Model Memory's independently registered recovery delivery. Architectural
  // WB/admission is revoked now; an already-issued speculative bind may reach
  // the local LSQ on publication and is cancelled on the following edge.
  reg [31:0] memory_kill_q=0;
  reg memory_flush_q=0;
  always @(posedge clk) begin
    if(rst)begin memory_kill_q<=0;memory_flush_q<=0;end
    else begin memory_kill_q<=km;memory_flush_q<=flush;end
  end
  integer bind_at_revoke=0;
  reg [511:0] revoked_full_tag_q=0;
  always @(posedge clk) begin
    if(rst)revoked_full_tag_q<=0;
    else for(integer rt=0;rt<32;rt=rt+1)
      if(owners[rt]&&(km[rt]||flush))revoked_full_tag_q[tags[rt]]<=1;
  end
  reg [31:0] revoke_bind_q=0;
  always @(posedge clk) begin
    if(rst)revoke_bind_q<=0;
    else begin
      // At the edge after local cancellation, no revoked LSQ binding remains.
      if((owners & revoke_bind_q)!=0)$fatal(1,"revoked speculative bind retained LSQ owner");
      revoke_bind_q<=memory_kill_q;
      for(integer bl=0;bl<2;bl=bl+1)
        if(lf[bl]&&km[lt[bl*T+:5]])bind_at_revoke=bind_at_revoke+1;
    end
  end
  wire [5:0] rob_count;
  wire [1:0] lf;
  wire [2*T-1:0] lt;
  wire [2*`R64_MEM_CMD_W-1:0] lu;
  wire ff, sf;
  wire [T-1:0] ft, st;
  wire [`R64_FP_CMD_W-1:0] fu;
  wire [`R64_SERIAL_CMD_W-1:0] su;
  wire [191:0] fop;
  reg [3:0] ev = 0;
  wire [3:0] er;
  reg [4*T-1:0] et = 0;
  reg [4*R-1:0] ed = 0;
  reg [31:0] owners = 0, stores = 0, bound = 0;
  reg [4:0] owner_lsq_slot[0:31];
  wire [1:0] rwant, rfire;
  reg  [ 1:0] rready;
  reg  [ 9:0] rslot;
  wire [17:0] reserve_tag;
  wire [15:0] rfunc;
  wire [9:0] ramo, bslot, selected_slots;
  wire [1:0] lane_credit={rwant[0]?rready[1]:rready[0],rready[0]};
  reg [N-1:0] free_slots;
  integer free0, free1, rr_owned, bindings = 0;
  always @(*)
    rr_owned = integer'(backend.execution.registers.ingress_valid_q[0]) + integer
        '(backend.execution.registers.ingress_valid_q[1]) + integer'(backend.execution.registers.terminal_count_q[0]) +
        integer'(backend.execution.registers.terminal_count_q[1]);
  reg [T-1:0] tags[0:31];
  reg [31:0] program_mem[0:255];
  integer cycle = 0, sent = 0, retired = 0, total = 26, mode = 0, free_count, occupied;
  integer a, j, slot, expected = 0, dual_mem = 0, window_mem = 0, max_occupied = 0;
  integer commands = 0, completions = 0, canceled = 0, resolves = 0, redirects = 0;
  integer first_resolve = -1, stall_mask = 0, credit_cap = 6;
  reg [2:0] credit;
  reg [1:0] lready;
  reg [1:0] terminal_valid = 0, refill_valid;
  reg [2*T-1:0] terminal_tag = 0, refill_tag;
  reg [31:0] claimed;
  integer candidate_slot;
  reg [1:0] held = 0;
  reg [2*T-1:0] held_tag = 0;
  reg [2*R-1:0] held_data = 0;
  integer held_cycles = 0, wrap_choices = 0, peak_reserved = 0;
  reg [63:0] pc;
  always @(posedge clk)
    if(!rst)
      for(integer rank_lane=0;rank_lane<2;rank_lane=rank_lane+1)
        if(rfire[rank_lane] &&
            selected_slots[rank_lane*5+:5] !=
              5'((rank_lane==1 && rwant[0]) ? free1 : free0))
          $fatal(1,"Backend selected a slot outside its ranked FREE-Q offer");

  R64Backend backend (
    .serial_retire_candidate_o(),
    .direction_invalidate_i(1'b0),.direction_train_valid_o(),.direction_train_pc_o(),.direction_train_taken_o(),
    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .resolved_value_valid_i(2'b0), .resolved_value_tag_i(18'b0), .resolved_value_data_i(128'b0),
    .store_done_valid_i(1'b0),
    .store_done_ready_o(),
    .store_done_tag_i(9'b0),
    .store_done_error_i(1'b0),
    .store_done_tval_i(64'b0),
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .stop_i(stop),
    .effect_i({1'b1, 1'b0, 1'b1, htag}),
    .reuse_block_i(32'b0),
    .fetch_valid_i(fv),
    .fetch_ready_o(fr),
    .fetch_pc_i(fpc),
    .fetch_raw_i(raw),
    .fetch_pred_npc_i(pred),
    .fetch_length_i(lengths),
    .fetch_exception_i(2'b0),
    .fetch_cause_i(12'b0),
    .fetch_tval_i(128'b0),
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
    .commit_rd_arch_o(ca),
    .redirect_valid_o(redir),
    .redirect_pc_o(target),
    .resolve_valid_o(resolve),
    .resolve_tag_o(rtag),
    .resolve_pc_o(rpc),
    .resolve_npc_o(rnpc),
    .resolve_conditional_o(conditional),
    .resolve_indirect_o(indirect),
    .resolve_taken_o(taken),
    .kill_mask_o(km),
    .head_tag_o(htag),
    .rob_count_o(rob_count),
    .recover_o(recover),
    .fetch_canonical_i(66'b0),
    .lsu_reserve_want_o(rwant),
    .lsu_reserve_fire_o(rfire),
    .lsu_reserve_ready_i(rready),
    .lsu_reserve_slot_i(rslot),
    .lsu_reserve_slot_o(selected_slots),
    .lsu_reserve_tag_o(reserve_tag),
    .lsu_reserve_func_o(rfunc),
    .lsu_reserve_amo_o(ramo),
    .lsu_slot_o(bslot),
    .lsu_ready_i(lready),
    .lsu_fire_o(lf),
    .lsu_tag_o(lt),
    .lsu_command_o(lu),
    .fp_ready_i(!ev[2]),
    .fp_fire_o(ff),
    .fp_tag_o(ft),
    .fp_command_o(fu),
    .fp_operand_o(fop),
    .serial_ready_i(!ev[3]),
    .serial_fire_o(sf),
    .serial_tag_o(st),
    .serial_command_o(su),
    .external_valid_i(ev),
    .external_ready_o(er),
    .external_tag_i(et),
    .external_result_i(ed)
  );

  // Dispatch owns finite LSQ slots before bind. Capacity uses only FREE Q
  // state, never a same-edge completion/cancel. The historical cap4/cap6 query
  // choices both cover the two requested slots; neither reserves RR state.
  always @(*) begin
    occupied = 0;
    for (integer q = 0; q < 32; q = q + 1) if (owners[q]) occupied = occupied + 1;
    free_count = N - occupied;
    credit = free_count >= credit_cap ? 3'(credit_cap) : 3'(free_count);
    free_slots = {N{1'b1}};
    for (integer q = 0; q < 32; q = q + 1) if (owners[q]) free_slots[owner_lsq_slot[q]] = 0;
    free0 = -1;
    free1 = -1;
    for (integer q = 0; q < N; q = q + 1)
    if (free_slots[q]) begin
      if (free0 < 0) free0 = q;
      else if (free1 < 0) free1 = q;
    end
    rready={credit>=2,credit>=1};
    rslot={5'(free1),5'(free0)};
    lready = 3;
    ev = 0;
    et = 0;
    ed = 0;
    for (integer l = 0; l < 2; l = l + 1) begin
      ev[l] = terminal_valid[l] && !km[terminal_tag[l*T+:5]];
      et[l*T+:T] = terminal_tag[l*T+:T];
      ed[l*R+:64] = (mode == 1 ? 64'd0 : 64'd1);
    end
    // An advertised result stays in its physical terminal until accepted.
    // Exclude both terminals, including accepted ones, from refill candidates:
    // their owners disappear only at the upcoming edge.
    claimed = 0;
    for (integer l = 0; l < 2; l = l + 1) if (terminal_valid[l]) claimed[terminal_tag[l*T+:5]] = 1;
    refill_valid = 0;
    refill_tag = 0;
    candidate_slot = 0;
    for (integer l = 0; l < 2; l = l + 1) begin
      if (!terminal_valid[l] || er[l] || km[terminal_tag[l*T+:5]]) begin
        // Registered ROB head establishes age across physical slot wrap.
        // Scanning slot zero first starves old slots 28..31 behind new births.
        for (integer age = 0; age < 32; age = age + 1) begin
          candidate_slot = (integer'(htag[4:0]) + age) % 32;
          if (!refill_valid[l] && owners[candidate_slot] && bound[candidate_slot] &&
              !claimed[candidate_slot] && !km[candidate_slot] &&
              (stores[candidate_slot] ?
               tags[candidate_slot] == htag : (mode == 2 || cycle >= 80))) begin
            refill_valid[l] = 1;
            refill_tag[l*T+:T] = tags[candidate_slot];
            claimed[candidate_slot] = 1;
          end
        end
      end
    end
  end
  always @(posedge clk) begin
    if (rst || flush) begin
      terminal_valid <= 0;
      held <= 0;
    end else begin
      for (integer l = 0; l < 2; l = l + 1) begin
        if (held[l] && !km[held_tag[l*T+:5]] &&
            (!ev[l] || et[l*T+:T] !== held_tag[l*T+:T] || ed[l*R+:R] !== held_data[l*R+:R]))
          $fatal(1, "LSQ model replaced a held terminal owner");
        if (terminal_valid[l] && (er[l] || km[terminal_tag[l*T+:5]])) terminal_valid[l] <= 0;
        if (refill_valid[l]) begin
          terminal_valid[l] <= 1;
          terminal_tag[l*T+:T] <= refill_tag[l*T+:T];
          if (refill_tag[l*T+:5] < htag[4:0]) wrap_choices = wrap_choices + 1;
        end
        held[l] <= ev[l] && !er[l];
        held_tag[l*T+:T] <= et[l*T+:T];
        held_data[l*R+:R] <= ed[l*R+:R];
        if (ev[l] && !er[l]) held_cycles = held_cycles + 1;
      end
    end
  end
  always @(posedge clk) begin
    if (rst || memory_flush_q) begin
      if (memory_flush_q) for (integer q = 0; q < 32; q = q + 1) if (owners[q]) canceled = canceled + 1;
      owners <= 0;
      stores <= 0;
      bound  <= 0;
    end else begin
      for (integer q = 0; q < 32; q = q + 1)
      if (owners[q] && memory_kill_q[q]) begin
        owners[q] <= 0;
        bound[q]  <= 0;
        canceled = canceled + 1;
      end
      for (integer l = 0; l < 2; l = l + 1) begin
        if (ev[l] && er[l]) begin
          slot = et[l*T+:5];
          if (!owners[slot] || tags[slot] != et[l*T+:T]) $fatal(1, "terminal has no owner");
          if(revoked_full_tag_q[et[l*T+:T]] || km[slot] || flush)
            $fatal(1,"revoked full-tag completed or effected after publication");
          owners[slot] <= 0;
          bound[slot]  <= 0;
          completions = completions + 1;
        end
        if (lf[l]) begin
          slot = lt[l*T+:5];
          if (!owners[slot] || bound[slot] || memory_kill_q[slot] || tags[slot] != lt[l*T+:T] ||
              owner_lsq_slot[slot] != bslot[l*5+:5])
            $fatal(1, "bind without unique live reserved fulltag/LSQslot");
          bound[slot] <= 1;
          bindings = bindings + 1;
        end
        if (rfire[l]) begin
          slot = reserve_tag[l*T+:5];
          if (owners[slot] || km[slot] || !lane_credit[l] || integer'(selected_slots[l*5+:5]) >= N ||
              !free_slots[selected_slots[l*5+:5]])
            $fatal(1, "LSQ duplicate/dead/overbooked reserve");
          owners[slot] <= 1;
          bound[slot] <= 0;
          tags[slot] <= reserve_tag[l*T+:T];
          owner_lsq_slot[slot] <= selected_slots[l*5+:5];
          stores[slot] <= rfunc[l*8+5];
          commands = commands + 1;
        end
      end
    end
  end
  function [31:0] branch;
    input integer imm;
    reg [12:0] off;
    begin
      off = 13'(imm);
      branch = {off[12], off[10:5], 5'd0, 5'd1, 3'b000, off[4:1], off[11], 7'h63};
    end
  endfunction
  initial begin
    if ($value$plusargs("mode=%d", mode)) begin
    end
    if ($test$plusargs("stalls")) stall_mask = 1;
    if ($value$plusargs("credit-cap=%d", credit_cap)) begin
    end
    if (credit_cap != 4 && credit_cap != 6)
      $fatal(1, "supported LSQ credit advertisement is four or six");
    total = mode == 2 ? 240 : 26;
    for (j = 0; j < 256; j = j + 1) program_mem[j] = mode == 2 ? 32'h00003003 : 32'h00003023;
    if (mode != 2) begin
      program_mem[0] = 32'h00003083;  // ld x1,0(x0), deliberately delayed
      program_mem[1] = branch(mode == 1 ? 36 : 4);
    end
    repeat (3) begin
      @(posedge clk);
      #1;
    end
    @(negedge clk);
    rst = 0;
    while (cycle < 600 && retired < (mode == 1 ? total - 8 : total)) begin
      @(negedge clk);
      flush = (mode == 3 && cycle == 6);
      if (flush) begin
        sent = 0;
        expected = 0;
      end
      fv = 0;
      cr = (stall_mask && cycle % 7 == 3) ? 2'b00 : 2'b11;
      if (sent < total && !flush) begin
        fv[0] = 1;
        fv[1] = (sent + 1 < total);
        for (a = 0; a < 2; a = a + 1) begin
          pc = 64'h80000000 + 64'(4 * (sent + a));
          fpc[a*64+:64] = pc;
          pred[a*64+:64] = pc + 4;
          raw[a*64+:64] = {32'b0, program_mem[sent+a]};
        end
      end
      #1;
      if (resolve) begin
        resolves = resolves + 1;
        if (first_resolve < 0) first_resolve = cycle;
      end
      if (redir) begin
        redirects = redirects + 1;
        sent = integer'((target - 64'h80000000) >> 2);
      end else begin
        if (fv[0] && fr[0]) sent = sent + 1;
        if (fv[1] && fr[1]) sent = sent + 1;
      end
      for (a = 0; a < 2; a = a + 1)
      if (cv[a] && cr[a]) begin
        if (cx[a]) $fatal(1, "unexpected exception");
        if (cm[a*M+:64] !== 64'h80000000 + 64'(expected * 4))
          $fatal(1, "retirement order expected instruction=%0d got PC=%h", expected, cm[a*M+:64]);
        if (expected == 1 && mode == 1) expected = 10;
        else expected = expected + 1;
        retired = retired + 1;
      end
      if (occupied > max_occupied) max_occupied = occupied;
      if (rr_owned > peak_reserved) peak_reserved = rr_owned;
      if (rr_owned > credit_cap)
        $fatal(1, "real RR owner occupancy exceeded fixture coverage budget");
      if (lf == 3) dual_mem = dual_mem + 1;
      if (mode == 2 && cycle >= 30 && cycle < 100)
        window_mem = window_mem + integer'(lf[0]) + integer'(lf[1]);
      if (occupied > N) $fatal(1, "LSQ overbooked");
      @(posedge clk);
      #1;
      cycle = cycle + 1;
    end
    if (retired != (mode == 1 ? total - 8 : total))
      $fatal(
          1,
          "progress cycle=%0d retired=%0d head=%h occupied=%0d RR=%b class=%h",
          cycle,
          retired,
          htag,
          occupied,
          backend.execution.read_valid_w,
          backend.execution.read_class_w
      );
    if (mode != 2 && (first_resolve < 80 || first_resolve > 95 || max_occupied < 17))
      $fatal(1, "fixture did not exercise delayed branch / saturated LSQ");
    if (mode == 1 && (redirects != 1 || canceled < 8))
      $fatal(1, "recovery did not cancel wrong-path stores");
    if (mode == 2 && !stall_mask && credit_cap == 6 && window_mem != 140)
      $fatal(1, "dual MEM steady throughput lost: %0d/140", window_mem);
    if (mode == 2 && (wrap_choices == 0 || held_cycles == 0 || peak_reserved != 4))
      $fatal(1, "dual MEM fixture missed wrap, terminal hold or both RR stages");
    $display("RECOVERY_DELIVERY speculative_bind_at_publication=%0d",bind_at_revoke);
    if (commands != completions + canceled)
      $fatal(1, "owner conservation %0d != %0d+%0d", commands, completions, canceled);
    $display("[LSQ-MODEL] credit-cap=%0d max-real-RR=%0d held=%0d wrapped-age-selections=%0d",
             credit_cap, peak_reserved, held_cycles, wrap_choices);
    $display(
        "[PASS] tb_r64_mem_admission mode=%0d stalls=%0d cycle=%0d retired=%0d maxLSQ=%0d branchCycle=%0d dualMEM=%0d steadyMEM=%0d/140 commands=%0d canceled=%0d",
        mode, stall_mask, cycle, retired, max_occupied, first_resolve, dual_mem, window_mem,
        commands, canceled);
    $finish;
  end
endmodule
