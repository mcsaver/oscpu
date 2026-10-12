`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_batch_backend;
  parameter BATCH=1;
  localparam U = `R64_UOP_W, M = `R64_META_W, R = `R64_RESULT_W, T = 9;
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
  reg [31:0] program_mem[0:255];
  reg [63:0] regs[0:31];
  reg [63:0] memory_value = 0, csr_value = 0;
  reg [31:0] sq_valid = 0;
  reg [T-1:0] sq_tag[0:31];
  reg [63:0] sq_addr[0:31], sq_data[0:31];
  integer sq_seq[0:31], sq_sequence = 0;
  integer ml, ms, latest;
  reg [63:0] addr, value;
  // Test-only LSQ owner model: capacity is reserved at real dispatch;
  // operand bind order does not define memory order.
  wire [1:0] rwant, rfire;
  wire [17:0] rtag_pair;
  wire [15:0] rfunc;
  wire [9:0] ramo, bslot, selected_slots;
  wire [1:0] lane_credit={rwant[0]?rready[1]:rready[0],rready[0]};
  reg [1:0] rready;
  reg [9:0] rslot;
  reg [17:0] reserved = 0, bound = 0, responded = 0;
  reg [ 8:0] owner_tag [0:17];
  reg [ 7:0] owner_func[0:17];
  reg [63:0] owner_addr[0:17];
  integer free0, free1, qslot, zslot, choice, best_age, current_age;
  reg blocked;
  integer reserves = 0, binds = 0, reverse_binds = 0;
  // Q offers must be initialized even before the first MEM request.
  always_comb begin
    free0 = -1;
    free1 = -1;
    for (integer f = 0; f < 18; f = f + 1)
    if (!reserved[f]) begin
      if (free0 < 0) free0 = f;
      else if (free1 < 0) free1 = f;
    end
    rready={free1>=0,free0>=0};
    rslot={5'(free1),5'(free0)};
  end
  always @(posedge clk)
    if(!rst)
      for(integer rank_lane=0;rank_lane<2;rank_lane=rank_lane+1)
        if(rfire[rank_lane] &&
            selected_slots[rank_lane*5+:5] !=
              5'((rank_lane==1 && rwant[0]) ? free1 : free0))
          $fatal(1,"Backend selected a slot outside its ranked FREE-Q offer");

  R64Backend #(.BATCH_SUFFIX_ROLLBACK(BATCH)) backend (
    .serial_retire_candidate_o(),
    .direction_invalidate_i(1'b0),.direction_train_valid_o(),.direction_train_pc_o(),.direction_train_taken_o(),
    .pair_store_candidate_valid_o(),.pair_store_candidate_tag_o(),
    .resolved_value_valid_i(2'b0), .resolved_value_tag_i(18'b0), .resolved_value_data_i(128'b0),
    .store_done_valid_i(1'b0),
    .store_done_ready_o(),
    .store_done_tag_i(9'b0),
    .store_done_error_i(1'b0),
    .store_done_tval_i(64'b0),
    .lsu_reserve_want_o(rwant),
    .lsu_reserve_fire_o(rfire),
    .lsu_reserve_tag_o(rtag_pair),
    .lsu_reserve_func_o(rfunc),
    .lsu_reserve_amo_o(ramo),
    .lsu_reserve_ready_i(rready),
    .lsu_reserve_slot_i(rslot),
    .lsu_reserve_slot_o(selected_slots),
    .lsu_slot_o(bslot),
    .fetch_canonical_i(66'b0),
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
    .lsu_ready_i(~ev[1:0]),
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
  // Minimal owner models test command/terminal boundaries, not cache/FP numeric
  // implementation. Stores remain speculative until architectural commit;
  // loads forward the most recent admitted older store, including a same-pair store.
  always @(posedge clk) begin
    if (rst || flush) begin
      ev <= 0;
      sq_valid = 0;
      sq_sequence = 0;
      reserved = 0;
      bound = 0;
      responded = 0;
    end else begin
      for (ml = 0; ml < 4; ml = ml + 1) if ((ev[ml] && er[ml]) || km[et[ml*T+:5]]) ev[ml] <= 0;
      for (ms = 0; ms < 32; ms = ms + 1) if (km[ms]) sq_valid[ms] = 0;
      for (qslot = 0; qslot < 18; qslot = qslot + 1)
      if (reserved[qslot]) begin
        if (km[owner_tag[qslot][4:0]]) begin
          reserved[qslot] = 0;
          bound[qslot] = 0;
        end
        for (ml = 0; ml < 2; ml = ml + 1)
        if (cv[ml] && cr[ml] && ct[ml*T+:T] == owner_tag[qslot]) reserved[qslot] = 0;
      end
      for (ml = 0; ml < 2; ml = ml + 1)
      if (lf[ml]) begin
        qslot = bslot[ml*5+:5];
        if (qslot >= 18 || !reserved[qslot] || bound[qslot] || owner_tag[qslot] != lt[ml*T+:T])
          $fatal(1, "dispatch LSQ slot/fulltag bound without unique reserve");
        if (owner_func[qslot] != lu[ml*`R64_MEM_CMD_W+192+:8]) $fatal(1, "reserve/bind function mismatch");
        for (zslot = 0; zslot < 18; zslot = zslot + 1)
        if (reserved[zslot] && !bound[zslot] && zslot != qslot &&
            ((owner_tag[zslot][4:0] - htag[4:0]) & 31) < ((owner_tag[qslot][4:0] - htag[4:0]) & 31))
          reverse_binds = reverse_binds + 1;
        bound[qslot] = 1;
        binds = binds + 1;
        addr = lu[ml*`R64_MEM_CMD_W+:64] + lu[ml*`R64_MEM_CMD_W+64+:64];
        owner_addr[qslot] = addr;
        if (lu[ml*`R64_MEM_CMD_W+197]) begin
          ms = lt[ml*T+:5];
          sq_valid[ms] = 1;
          sq_tag[ms] = lt[ml*T+:T];
          sq_addr[ms] = addr;
          sq_data[ms] = lu[ml*`R64_MEM_CMD_W+128+:64];
        end
      end
      for (ml = 0; ml < 2; ml = ml + 1)
      if (!ev[ml]) begin
        choice   = -1;
        best_age = 32;
        for (qslot = 0; qslot < 18; qslot = qslot + 1)
        if (reserved[qslot] && bound[qslot] && !responded[qslot]) begin
          blocked = 0;
          current_age = (owner_tag[qslot][4:0] - htag[4:0]) & 31;
          for (zslot = 0; zslot < 18; zslot = zslot + 1)
          if (reserved[zslot] && owner_func[zslot][5] && !bound[zslot] &&
              ((owner_tag[zslot][4:0] - htag[4:0]) & 31) < current_age)
            blocked = 1;
          if (!blocked && current_age < best_age) begin
            choice   = qslot;
            best_age = current_age;
          end
        end
        if (choice >= 0) begin
          responded[choice] = 1;
          ev[ml] <= 1;
          et[ml*T+:T] <= owner_tag[choice];
          ed[ml*R+:R] <= 0;
          if (!owner_func[choice][5]) begin
            value  = memory_value;
            latest = -1;
            for (ms = 0; ms < 32; ms = ms + 1)
            if (sq_valid[ms] && sq_addr[ms] == owner_addr[choice] &&
                ((sq_tag[ms][4:0] - htag[4:0]) & 31) < best_age &&
                (latest < 0 || ((sq_tag[ms][4:0] - htag[4:0]) & 31) > latest)) begin
              value  = sq_data[ms];
              latest = (sq_tag[ms][4:0] - htag[4:0]) & 31;
            end
            ed[ml*R+:64] <= value;
          end
        end
      end
      for (ml = 0; ml < 2; ml = ml + 1)
      if (rfire[ml]) begin
        qslot = selected_slots[ml*5+:5];
        if (qslot >= 18 || reserved[qslot] || !lane_credit[ml]) $fatal(1, "LSQ reserve overbooked");
        reserved[qslot] = 1;
        bound[qslot] = 0;
        responded[qslot] = 0;
        owner_tag[qslot] = rtag_pair[ml*T+:T];
        owner_func[qslot] = rfunc[ml*8+:8];
        reserves = reserves + 1;
      end
      if (ff) begin
        ev[2] <= 1;
        et[2*T+:T] <= ft;
        ed[2*R+:R] <= 0;
      end
      if (sf) begin
        if (st != htag) $fatal(1, "serial command issued before ROB head");
        ev[3] <= 1;
        et[3*T+:T] <= st;
        ed[3*R+:R] <= 0;
        ed[3*R+:64] <= csr_value;
        csr_value = su[`R64_SERIAL_OPERAND];
      end
    end
  end
  task tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask
  task check;
    input condition;
    input [511:0] msg;
    begin
      if (condition !== 1'b1) $fatal(1, "%0s", msg);
    end
  endtask
  function [31:0] addi;
    input integer rd, rs, imm;
    addi = {12'(imm), 5'(rs), 3'b0, 5'(rd), 7'h13};
  endfunction
  function [31:0] op;
    input integer f7, rs2, rs1, f3, rd;
    op = {7'(f7), 5'(rs2), 5'(rs1), 3'(f3), 5'(rd), 7'h33};
  endfunction
  function [31:0] branch;
    input integer rs2, rs1, f3, imm;
    reg [12:0] off;
    begin
      off = 13'(imm);
      branch = {off[12], off[10:5], 5'(rs2), 5'(rs1), 3'(f3), off[4:1], off[11], 7'h63};
    end
  endfunction
  function [31:0] jal;
    input integer rd, imm;
    reg [20:0] off;
    begin
      off = 21'(imm);
      jal = {off[20], off[10:1], off[11], off[19:12], 5'(rd), 7'h6f};
    end
  endfunction
  integer
      sent,
      committed,
      cycles,
      pairs,
      lane,
      idx,
      redirects,
      resolves,
      mem_commands,
      fp_commands,
      serial_commands;
  reg [63:0] fetch_pc, expected_pc;
  reg [M-1:0] meta;
  reg [ 31:0] inst;
  reg [63:0] expect_data, next_pc, imm, srca, srcb;
  reg expect_write, expect_fp, halted;
  reg [4:0] rdidx;
  task inspect_commit;
    begin
      for (lane = 0; lane < 2; lane = lane + 1)
      if (cv[lane] && cr[lane]) begin
        meta  = cm[lane*M+:M];
        inst  = meta[95:64];
        rdidx = inst[11:7];
        check(meta[`R64_M_PC] == expected_pc, "retired wrong-path or out-of-order PC");
        srca = regs[inst[19:15]];
        srcb = regs[inst[24:20]];
        expect_data = 0;
        expect_write = 0;
        expect_fp = 0;
        next_pc = expected_pc + 4;
        case (inst[6:0])
          7'h13: begin
            expect_data  = srca + {{52{inst[31]}}, inst[31:20]};
            expect_write = rdidx != 0;
          end
          7'h33: begin
            expect_write = rdidx != 0;
            if (inst[31:25] == 1 && inst[14:12] == 0) expect_data = srca * srcb;
            else if (inst[31:25] == 1 && inst[14:12] == 4)
              expect_data = $signed(srca) / $signed(srcb);
            else expect_data = srca + srcb;
          end
          7'h63: begin
            imm = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            if ((inst[14:12] == 0 && srca == srcb) || (inst[14:12] == 1 && srca != srcb))
              next_pc = expected_pc + imm;
          end
          7'h6f: begin
            imm = {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            expect_data = expected_pc + 4;
            expect_write = rdidx != 0;
            next_pc = expected_pc + imm;
          end
          7'h67: begin
            expect_data = expected_pc + 4;
            expect_write = rdidx != 0;
            next_pc = (srca + {{52{inst[31]}}, inst[31:20]}) & -64'd2;
          end
          7'h23: begin
            memory_value = srcb;
            sq_valid[ct[lane*T+:5]] = 0;
          end
          7'h03: begin
            expect_data  = memory_value;
            expect_write = rdidx != 0;
          end
          7'h73: begin
            expect_data  = 0;
            expect_write = rdidx != 0;
          end
          7'h53: begin
            expect_data = 0;
            expect_write = 1;
            expect_fp = inst[31:25] != 7'h71;
          end
          default: begin
            check(cx[lane] && cc[lane*6+:6] == 2 && !cwr[lane],
                  "illegal instruction did not retire precise fault");
            halted = 1;
          end
        endcase
        if (!halted) begin
          check(!cx[lane], "unexpected exception");
          check(cwr[lane] == expect_write && (!expect_write || cfp[lane] == expect_fp),
                "commit destination metadata");
          if (expect_write) begin
            if (cd[lane*64+:64] !== expect_data)
              $fatal(
                  1,
                  "result PC=%h inst=%h actual=%h expected=%h",
                  expected_pc,
                  inst,
                  cd[lane*64+:64],
                  expect_data
              );
            if (!expect_fp) regs[rdidx] = expect_data;
          end
          check(meta[`R64_M_NPC] == next_pc, "actual branch/retire NPC mismatch");
          expected_pc = next_pc;
        end
        committed = committed + 1;
      end
    end
  endtask
  integer dep_pattern, dep_chains;
  integer fence_events, fence_deliveries;
  reg fence_previous;
  reg [63:0] fence_target;
  integer authority_mode, authority_limit, authority_raw, authority_accepted;
  integer authority_stale, authority_flush_delivery;
  reg authority_flushed;
  reg [1:0] authority_seen, branch_lane_coverage=0;
  reg [63:0] authority_base, authority_pc;
  reg branch_previous_valid=0, branch_previous_lane=0;
  integer branch_alternations=0;
  always @(posedge clk) begin
    if(rst) branch_previous_valid=0;
    else begin
      if(backend.raw_resolve_valid_w) begin
        branch_lane_coverage = branch_lane_coverage | backend.execution.execute.branch_resolve_w;
        if(branch_previous_valid &&
            branch_previous_lane!=backend.execution.execute.resolve_lane_q)
          branch_alternations=branch_alternations+1;
        branch_previous_lane=backend.execution.execute.resolve_lane_q;
      end
      branch_previous_valid=backend.raw_resolve_valid_w;
    end
  end
  integer batch_cycles=0,batch_applies=0,batch_kills=0,batch_recover=0;
  always @(posedge clk)if(!rst)begin
    batch_cycles+=1;
    if(backend.batch_rollback_apply_w)batch_applies+=1;
    if(backend.rob.kill_w)batch_kills+=1;
    if(recover)batch_recover+=1;
  end
  initial begin
    tick();
    rst = 0;
    sent = 0;
    committed = 0;
    pairs = 0;
    cycles = 0;
    // End-to-end steady CPI target, with real decode/rename/PRF/IQ/ALU/WB/ROB.
    while (committed < 200 && cycles < 160) begin
      fv   = sent < 200 ? 3 : 0;
      fpc  = {64'(4 * sent + 4), 64'(4 * sent)};
      pred = {64'(4 * sent + 8), 64'(4 * sent + 4)};
      raw  = {32'b0, addi((sent + 1) % 31 + 1, 0, sent + 1), 32'b0, addi(sent % 31 + 1, 0, sent)};
      #1;
      if (cv == 3) pairs = pairs + 1;
      for (lane = 0; lane < 2; lane = lane + 1)
      if (cv[lane]) begin
        meta = cm[lane*M+:M];
        check(meta[`R64_M_PC] == 4 * committed, "steady commit PC order");
        check(cwr[lane] && !cfp[lane] && !cx[lane] && cd[lane*64+:64] == committed,
              "steady ALU result");
        committed = committed + 1;
      end
      if (fv[0] && fr[0]) sent = sent + 1;
      if (fv[1] && fr[1]) sent = sent + 1;
      tick();
      cycles = cycles + 1;
    end
    check(committed == 200 && sent == 200 && pairs == 100, "end-to-end dual IPC target");
    $display(
        "[R64-BACKEND-IDEAL] committed=200 dual_commit_cycles=100 steady_cpi=0.5 elapsed_with_fill=%0d",
        cycles);
    // Full native recurrence tests include rename reuse, early wakeup,
    // operand bypass and canonical completion. Address/read admission plus two
    // compute phases imply four-cycle recurrence; eight independent chains
    // additionally verify the two-result-per-cycle throughput at this latency.
    for (dep_pattern = 0; dep_pattern < 4; dep_pattern = dep_pattern + 1) begin
      fv  = 0;
      rst = 1;
      tick();
      rst = 0;
      dep_chains = 1 << dep_pattern;
      sent = 0;
      committed = 0;
      pairs = 0;
      cycles = 0;
      while (committed < 240 && cycles < 1500) begin
        fv = sent < 240 ? 3 : 0;
        fpc = {64'(4 * sent + 4), 64'(4 * sent)};
        pred = {64'(4 * sent + 8), 64'(4 * sent + 4)};
        raw = {
          32'b0,
          addi((sent + 1) % dep_chains + 1, (sent + 1) % dep_chains + 1, 1),
          32'b0,
          addi(sent % dep_chains + 1, sent % dep_chains + 1, 1)
        };
        #1;
        if (cv == 3) pairs = pairs + 1;
        for (lane = 0; lane < 2; lane = lane + 1)
        if (cv[lane]) begin
          meta = cm[lane*M+:M];
          check(meta[`R64_M_PC] == 4 * committed, "recurrence commit order");
          check(
              cwr[lane] && !cfp[lane] && !cx[lane] &&
                  cd[lane*64+:64] == 64'(committed / dep_chains + 1),
              "recurrence value / physical reuse");
          committed = committed + 1;
        end
        if (fv[0] && fr[0]) sent = sent + 1;
        if (fv[1] && fr[1]) sent = sent + 1;
        tick();
        cycles = cycles + 1;
      end
      check(committed == 240 && cycles <= 960 / dep_chains + 10,
            "registered-read/two-phase ALU four-cycle recurrence target");
      $display("[R64-BACKEND-DEPENDENCE] chains=%0d committed=%0d cycles=%0d dual=%0d", dep_chains,
               committed, cycles, pairs);
    end
    // Variable/immediate shifts consume a freshly produced amount through
    // the real Issue -> RR snapshot -> ALU path, including commit pressure.
    fv  = 0;
    rst = 1;
    tick();
    rst = 0;
    sent = 0;
    committed = 0;
    cycles = 0;
    while (committed < 256 && cycles < 1800) begin
      fv   = sent >= 256 ? 0 : sent == 255 ? 1 : 3;
      cr   = cycles % 7 == 0 ? 0 : 3;
      fpc  = {64'(4 * sent + 4), 64'(4 * sent)};
      pred = {64'(4 * sent + 8), 64'(4 * sent + 4)};
      for (idx = 0; idx < 2; idx = idx + 1) begin
        case ((sent + idx) % 4)
          0: raw[idx*64+:64] = {32'b0, addi(1, 0, 1)};
          1: raw[idx*64+:64] = {32'b0, addi(2, 0, (sent + idx) / 4)};
          2: raw[idx*64+:64] = {32'b0, op(0, 2, 1, 1, 3)};
          3: raw[idx*64+:64] = {32'b0, 6'b0, 6'((sent + idx) / 4), 5'd3, 3'd5, 5'd4, 7'h13};
        endcase
      end
      #1;
      for (lane = 0; lane < 2; lane = lane + 1)
      if (cv[lane] && cr[lane]) begin
        meta = cm[lane*M+:M];
        check(meta[`R64_M_PC] == 4 * committed, "shift snapshot retirement order");
        case (committed % 4)
          0, 3: expect_data = 1;
          1: expect_data = 64'(committed / 4);
          2: expect_data = 64'b1 << (committed / 4);
        endcase
        check(cwr[lane] && !cfp[lane] && !cx[lane] && cd[lane*64+:64] == expect_data,
              "variable/immediate shift snapshot or physical reuse");
        committed = committed + 1;
      end
      if (fv[0] && fr[0]) sent = sent + 1;
      if (fv[1] && fr[1]) sent = sent + 1;
      tick();
      cycles = cycles + 1;
    end
    check(committed == 256, "shift snapshot forward progress");
    $display(
        "[R64-BACKEND-SHIFT] variable/immediate 0..63 snapshot/pressure/reuse committed=256 cycles=%0d",
        cycles);
    cr  = 3;
    fv  = 0;
    rst = 1;
    tick();
    rst = 0;
    for (idx = 0; idx < 32; idx = idx + 1) regs[idx] = 0;
    memory_value = 0;
    csr_value = 0;
    for (idx = 0; idx < 256; idx = idx + 1) program_mem[idx] = 0;
    program_mem[0] = addi(1, 0, 3);
    program_mem[1] = addi(2, 0, 7);
    program_mem[2] = op(1, 2, 1, 0, 3);
    program_mem[3] = addi(4, 0, 100);
    program_mem[4] = op(1, 3, 4, 4, 5);
    program_mem[5] = branch(0, 5, 0, 12);
    program_mem[6] = op(0, 3, 5, 0, 6);
    program_mem[7] = jal(7, 12);
    program_mem[8] = addi(8, 0, 99);
    program_mem[9] = 32'h00803023;
    program_mem[10] = addi(8, 0, 5);
    program_mem[11] = 32'h00603023;
    program_mem[12] = 32'h00003483;
    program_mem[13] = 32'h34049573;
    program_mem[14] = 32'h020000d3;
    program_mem[15] = 32'he20085d3;
    program_mem[16] = addi(12, 0, 2);
    program_mem[17] = addi(12, 12, -1);
    program_mem[18] = branch(0, 12, 1, -4);
    program_mem[19] = addi(13, 0, 84);
    program_mem[20] = 32'h00068767;
    program_mem[21] = addi(15, 0, 1);
    program_mem[22] = 0;
    program_mem[23] = 32'h00803023;
    fetch_pc = 0;
    expected_pc = 0;
    committed = 0;
    cycles = 0;
    redirects = 0;
    resolves = 0;
    halted = 0;
    mem_commands = 0;
    fp_commands = 0;
    serial_commands = 0;
    while (!halted && cycles < 2000) begin
      if (redir) begin
        fetch_pc  = target;
        redirects = redirects + 1;
      end
      if (resolve) begin
        resolves = resolves + 1;
        if (rpc == 28)
          check(!conditional && !indirect && taken && rnpc == 40, "JAL training tuple");
        if (rpc == 80)
          check(!conditional && indirect && taken && rnpc == 84, "JALR training tuple");
      end
      fv   = fetch_pc < 100 ? 3 : 0;
      fpc  = {fetch_pc + 64'd4, fetch_pc};
      pred = {fetch_pc + 64'd8, fetch_pc + 64'd4};
      raw  = {32'b0, program_mem[(fetch_pc>>2)+1], 32'b0, program_mem[fetch_pc>>2]};
      #1;
      inspect_commit();
      if (lf[0]) mem_commands = mem_commands + 1;
      if (lf[1]) mem_commands = mem_commands + 1;
      if (ff) fp_commands = fp_commands + 1;
      if (sf) serial_commands = serial_commands + 1;
      if (fv[0] && fr[0]) fetch_pc = fetch_pc + 4;
      if (fv[1] && fr[1]) fetch_pc = fetch_pc + 4;
      tick();
      cycles = cycles + 1;
    end
    check(halted && cycles < 2000, "mixed backend program made no progress");
    check(
        regs[3] == 21 && regs[5] == 4 && regs[6] == 25 && regs[8] == 5 && regs[9] == 25 &&
            regs[12] == 0 && regs[15] == 1,
        "mixed architectural state");
    check(memory_value == 25 && csr_value == 25 && serial_commands == 1 && fp_commands == 2,
          "external owner command/commit conservation");
    check(redirects >= 2 && resolves >= 4, "branch paths were not exercised");
    fv = 0;
    flush = 1;
    tick();
    flush = 0;
    #1;
    check(rob_count == 0 && !recover, "post-trap flush");
    $display(
        "[R64-BACKEND-MIXED] commits=%0d redirects=%0d resolves=%0d memory=%0d fp=%0d serial=%0d cycles=%0d PASS",
        committed, redirects, resolves, mem_commands, fp_commands, serial_commands, cycles);
    // An empty victim mask is still an event: a newly fetched target must
    // not allocate a namespace until every execution owner consumed it.
    fv=0;rst=1;tick();rst=0;flush=0;stop=0;cr=3;
    sent=0;committed=0;cycles=0;fence_events=0;fence_deliveries=0;
    fence_previous=0;fence_target=64'h80004010;
    while(committed<2 && cycles<60) begin
      fv=0;
      if(sent==0) begin
        fv=1;fpc=128'h80004000;pred=128'h80004004;raw={96'b0,jal(0,16)};
      end else if(sent==1 && fence_events!=0) begin
        fv=1;fpc={64'b0,fence_target};pred={64'b0,fence_target+64'd4};
        raw={96'b0,addi(5,0,57)};
      end
      #1;
      if(redir) begin
        check(km==0,"zero-victim recovery fixture unexpectedly killed an owner");
        check(backend.birth_w==0 && fr==0,"source recovery admitted a target birth");
        fence_events=fence_events+1;
      end
      if(fence_previous) begin
        check(backend.birth_w==0 && fr==0,"local recovery delivery admitted a target birth");
        fence_deliveries=fence_deliveries+1;
      end
      fence_previous=redir;
      for(lane=0;lane<2;lane=lane+1)
        if(cv[lane] && cr[lane]) begin
          check(cm[lane*M+:64]==(committed==0?64'h80004000:fence_target),
                "zero-victim redirect changed architectural commit order");
          if(committed==1) check(cwr[lane] && cd[lane*64+:64]==57,
                                  "target instruction lost its newly allocated value");
          committed=committed+1;
        end
      if(fv[0] && fr[0]) sent=sent+1;
      tick();cycles=cycles+1;
    end
    check(committed==2 && sent==2 && fence_events==1 && fence_deliveries==1,
          "zero-victim recovery failed bounded progress or two-edge fence coverage");
    // Empty full flush has the identical two-edge admission obligation.
    fv=0;tick();flush=1;#1;
    check(rob_count==0 && backend.birth_w==0,"empty flush fixture was not empty");
    tick();flush=0;fv=1;raw={96'b0,addi(6,0,61)};fpc=128'h80005000;
    pred=128'h80005004;#1;
    check(fr==0 && backend.birth_w==0,"empty full flush lost its local delivery fence");
    tick();#1;check(fr[0],"birth admission did not reopen after empty recovery");
    fv=0;
    $display("[R64-BACKEND-RECOVERY] zero-victim redirect and empty flush source/local fence PASS");
    // Real Decode/Rename/Execution/ROB/RecoveryInbox connection. Two adjacent
    // branch tokens overlap the older event's source and local delivery cycles.
    for(authority_mode=0;authority_mode<4;authority_mode=authority_mode+1) begin
      fv=0;rst=1;flush=0;tick();rst=0;cr=3;
      authority_base=64'h80006000+64'(authority_mode*256);
      authority_limit=authority_mode>=2?3:2;
      sent=0;committed=0;authority_raw=0;authority_accepted=0;
      authority_stale=0;authority_flush_delivery=0;authority_flushed=0;
      authority_seen=0;
      for(cycles=0;cycles<40;cycles=cycles+1) begin
        fv=sent>=authority_limit?0:sent+1==authority_limit?1:3;
        fpc={authority_base+64'(sent*4+4),authority_base+64'(sent*4)};
        pred={authority_base+64'(sent*4+8),authority_base+64'(sent*4+4)};
        for(idx=0;idx<2;idx=idx+1) begin
          if(authority_mode>=2) begin
            case(sent+idx)
              // The nested-recovery case needs a real delayed producer.
              // ALU RAW latency is an implementation choice; MUL retains the
              // x1 dependence while ensuring the independent younger JAL wins.
              0: raw[idx*64+:64]={32'b0,authority_mode==2?32'h020000b3:addi(1,0,1)};
              1: raw[idx*64+:64]={32'b0,authority_mode==2?branch(1,1,0,64):jal(0,64)};
              default: raw[idx*64+:64]={32'b0,jal(0,96)};
            endcase
          end else raw[idx*64+:64]={32'b0,jal(0,(sent+idx)==0?64:96)};
        end
        #1;
        if(authority_mode==1 && backend.raw_resolve_valid_w && !authority_flushed) begin
          authority_flushed=1;flush=1;#1;
          check(backend.raw_resolve_valid_w && !resolve && !redir,
                "source full flush changed candidate or accepted its event");
        end
        if(backend.raw_resolve_valid_w) begin
          authority_raw=authority_raw+1;
          authority_pc=rpc-authority_base-(authority_mode==3?64'd4:64'd0);
          if(authority_mode==2) begin
            check(authority_pc==(authority_raw==1?64'd8:64'd4),
                  "fixture did not resolve the younger branch before the older branch");
            check(!authority_seen[authority_pc==8],"nested branch candidate duplicated");
            authority_seen[authority_pc==8]=1;
            check(resolve && redir,"older nested branch was not accepted");
            check(rnpc==authority_base+(authority_pc==4?64'd68:64'd104),
                  "nested branch candidate target");
          end else begin
            check(authority_pc==0 || authority_pc==4,"adjacent branch candidate PC");
            check(!authority_seen[authority_pc==4],"adjacent branch candidate duplicated");
            authority_seen[authority_pc==4]=1;
            check(rnpc==authority_base+(authority_mode==3?64'd4:64'd0)+
                      (authority_pc==0?64'd64:64'd100),
                  "registered branch candidate target changed during Recovery");
            if((authority_mode==0 || authority_mode==3) && authority_pc==4) begin
              check(!resolve && !redir && km==0 &&
                    backend.execution.kill_mask_i[rtag[4:0]],
                    "young candidate survived ROB authority or missed local inbox");
              authority_stale=authority_stale+1;
            end
            if(authority_mode==1) begin
              check(!resolve && !redir && (flush || km==0),
                    "full-flush candidate escaped ROB authority");
              if(backend.execution.flush_i) authority_flush_delivery=authority_flush_delivery+1;
            end
          end
        end
        if(resolve || redir) begin
          check(resolve && redir,"accepted branch tuple lost resolve/redirect pairing");
          authority_accepted=authority_accepted+1;
        end
        for(lane=0;lane<2;lane=lane+1)
          if(cv[lane] && cr[lane]) begin
            check(authority_mode!=1 && cm[lane*M+:64]==authority_base+64'(committed*4),
                  "cancelled branch retired or changed retained PC order");
            check(!cx[lane],"branch authority fixture unexpected exception");
            committed=committed+1;
          end
        if(fv[0] && fr[0]) sent=sent+1;
        if(fv[1] && fr[1]) sent=sent+1;
        tick();
        flush=0;
      end
      check(sent==authority_limit && authority_raw==2 && authority_seen==3,
            "branch authority fixture missed or duplicated a candidate");
      if(authority_mode==0 || authority_mode==3)
        check(authority_accepted==1 && committed==(authority_mode==3?2:1) && authority_stale==1,
              "late younger candidate/accepted event conservation");
      else if(authority_mode==1)
        check(authority_accepted==0 && committed==0 && authority_flush_delivery==1,
              "full-flush adjacent capture/local delivery conservation");
      else
        check(authority_accepted==2 && committed==2,
              "older nested redirect or retained retirement was lost");
      $display("[R64-BACKEND-BRANCH-AUTHORITY] mode=%0d raw=%0d accepted=%0d commits=%0d late=%0d local_flush=%0d",
               authority_mode,authority_raw,authority_accepted,committed,
               authority_stale,authority_flush_delivery);
    end
    check(branch_lane_coverage==3 && branch_alternations>0,
          "branch candidates did not alternate ALU lanes on adjacent cycles");
    $display("[R64-BACKEND-BRANCH-LANES] mask=%0d adjacent_alternations=%0d",
             branch_lane_coverage,branch_alternations);
    $display("BATCH_BACKEND mode=%0d cycles=%0d kill=%0d apply=%0d recover=%0d",
      BATCH,batch_cycles,batch_kills,batch_applies,batch_recover);
    check(BATCH?batch_applies>0:batch_applies==0,"batch actual Backend coverage");
    $display("[PASS] tb_r64_batch_backend");
    $finish;
  end
endmodule
