`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_head_serial_class;
  localparam U = `R64_UOP_W, M = `R64_META_W, R = `R64_RESULT_W, T = 9;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0, stop = 0, serial_hold = 0;
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
  wire [ 65:0] prepared_canonical;
  wire [ 69:0] prepared_control;
  wire [127:0] prepared_npc;
  for (genvar p = 0; p < 2; p = p + 1) begin : prepared
    wire [31:0] expanded;
    wire illegal;
    R64Rvc expand (
      .c_i(raw[p*64+:16]),
      .inst_o(expanded),
      .illegal_o(illegal)
    );
    assign prepared_canonical[p*33+:33] = lengths[p*4+:4] == 2 ?
        {illegal, expanded} : {1'b0, raw[p*64+:32]};
    assign prepared_npc[p*64+:64] = fpc[p*64+:64] + {60'b0, lengths[p*4+:4]};
    R64DecodeControl control (
      .canonical_i(prepared_canonical[p*33+:33]),
      .raw_i(raw[p*64+:64]),
      .length_i(lengths[p*4+:4]),
      .control_o(prepared_control[p*35+:35])
    );
  end
  wire control_flush, control_stop, control_redirect, trap_event, trap_irq, effect_allow,
      serial_allow;
  wire [63:0] control_target, trap_pc, trap_tval;
  wire [5:0] trap_cause;
  wire [1:0] retire_fire;
  wire serial_commit;
  wire [8:0] serial_commit_tag;
  reg irq_pending = 0;
  R64BackendCommitActual wrapper (
    .irq_pending_i(irq_pending),
    .irq_cause_i(6'd7),
    .trap_target_i(64'h1000),
    .lsu_irrevocable_i(1'b0),
    .serial_irrevocable_i(1'b0),
    .control_full_flush_o(control_flush),
    .control_stop_o(control_stop),
    .control_redirect_o(control_redirect),
    .control_target_o(control_target),
    .retire_fire_o(retire_fire),
    .retired_count_o(),
    .retire_npc_o(),
    .fp_dirty_o(),
    .fp_flags_o(),
    .serial_commit_o(serial_commit),
    .serial_commit_tag_o(serial_commit_tag),
    .trap_o(trap_event),
    .trap_interrupt_o(trap_irq),
    .trap_cause_o(trap_cause),
    .trap_pc_o(trap_pc),
    .trap_tval_o(trap_tval),
    .effect_allow_o(effect_allow),
    .serial_issue_allow_o(serial_allow),
    .trap_prepare_o(),
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
    .fetch_canonical_i(prepared_canonical),
    .fetch_control_i(prepared_control),
    .fetch_sequential_npc_i(prepared_npc),
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .stop_i(stop),
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
    .serial_ready_i(!ev[3] && !serial_hold),
    .serial_fire_o(sf),
    .serial_tag_o(st),
    .serial_command_o(su),
    .external_valid_i(ev),
    .external_ready_o(er),
    .external_tag_i(et),
    .external_result_i(ed)
  );
  // The old frozen Backend copy compared cycle-by-cycle delivery, including
  // invalid payload. Recovery now crosses local registered inboxes, so the
  // oracle is the architectural sequence below plus independent transaction
  // invariants, with retained head-class projection checked against metadata.
  wire [1:0] metadata_serial={
      cm[M+196+:8]>=`R64_K_CSR && cm[M+196+:8]<=`R64_K_TENSOR,
      cm[196+:8]>=`R64_K_CSR && cm[196+:8]<=`R64_K_TENSOR};
  reg recovery_previous=0;
  integer prefix_checks=0, dual_retire_checks=0, fence_checks=0;
  always @(posedge clk)
    if(rst) recovery_previous<=0;
    else recovery_previous<=flush || control_flush || redir || wrapper.dut.cancel_active_o;
  always @(posedge clk)
    if(!rst) begin
      prefix_checks=prefix_checks+1;
      if(wrapper.serial_class_w!==metadata_serial)
        $fatal(1,"head class lost retained metadata projection");
      if((retire_fire & ~(cv & cr & ~cx))!=0 ||
          (retire_fire[1] && (!retire_fire[0] || |metadata_serial)))
        $fatal(1,"closed retirement violated ordered nonexceptional serial-free prefix");
      if(wrapper.retired_count_o != ({1'b0,retire_fire[0]}+{1'b0,retire_fire[1]}))
        $fatal(1,"closed retirement count differs from accepted instruction prefix");
      if(retire_fire==3) dual_retire_checks=dual_retire_checks+1;
      if(serial_commit && (retire_fire!=1 || !metadata_serial[0] || serial_commit_tag!=ct[0+:T]))
        $fatal(1,"serial retirement lost unique head identity");
      if((flush || control_flush || redir || recovery_previous || stop || control_stop) &&
          (wrapper.dut.birth_w!=0 || rfire!=0))
        $fatal(1,"closed recovery/head stop admitted a younger owner");
      if(recovery_previous) fence_checks=fence_checks+1;
      if((rfire & ~lane_credit)!=0 || (rfire & ~rwant)!=0)
        $fatal(1,"closed memory reservation lacked ranked credit");
      for(integer rank_lane=0;rank_lane<2;rank_lane=rank_lane+1)
        if(rfire[rank_lane] && selected_slots[rank_lane*5+:5] !=
            5'((rank_lane==1 && rwant[0])?free1:free0))
          $fatal(1,"closed reservation chose an unoffered FREE-Q slot");
      if(trap_event && (retire_fire!=0 || !control_flush || !control_redirect))
        $fatal(1,"trap side effect overlapped retirement or lost recovery");
    end

  // Minimal owner models test command/terminal boundaries, not cache/FP numeric
  // implementation. Stores remain speculative until architectural commit;
  // loads forward the most recent admitted older store, including a same-pair store.
  always @(posedge clk) begin
    if (rst || flush || control_flush) begin
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
        ed[3*R+:64] <= su[95:64] == 32'h30200073 ? 64'd40 : csr_value;
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

  integer round_index, total_retired = 0, total_serial = 0, total_return = 0, total_traps = 0;
  integer elapsed_total = 0, canonical_windows = 0, early_stop_cycles = 0;
  integer held_cycles = 0, pending_cycles = 0, exception_windows = 0, branch_count = 0;
  integer expected_order[0:6];
  reg [15:0] generation_seen = 0;
  reg [8:0] bad_tag;
  integer serial_in_round;
  integer generation_wraps = 0;
  reg [31:0] serial_slot_seen = 0;
  reg [3:0] last_generation[0:31];
  initial begin
    expected_order[0] = 0;
    expected_order[1] = 4;
    expected_order[2] = 8;
    expected_order[3] = 12;
    expected_order[4] = 24;
    expected_order[5] = 28;
    expected_order[6] = 40;
    tick();
    rst = 0;
    for (round_index = 0; round_index < 20; round_index = round_index + 1) begin
      @(negedge clk);
      flush = 1;
      fv = 0;
      tick();
      @(negedge clk);
      flush = 0;
      for (idx = 0; idx < 256; idx = idx + 1) program_mem[idx] = 0;
      program_mem[0] = addi(1, 0, 1);
      program_mem[1] = 32'h34009073;
      program_mem[2] = addi(2, 1, 1);
      program_mem[3] = branch(0, 0, 0, 12);
      program_mem[4] = 32'h34001073;
      program_mem[5] = 32'h30200073;
      program_mem[6] = 32'h340021f3;
      program_mem[7] = 32'h30200073;
      program_mem[8] = addi(4, 0, 99);
      program_mem[9] = 32'h34001073;
      program_mem[10] = addi(4, 0, 4);
      fetch_pc = 0;
      committed = 0;
      cycles = 0;
      halted = 0;
      serial_in_round = 0;
      while (!halted && cycles < 500) begin
        if (control_redirect) fetch_pc = control_target;
        else if (redir) fetch_pc = target;
        serial_hold = (cycles + round_index) % 19 < 8;
        cr = (cycles + 2 * round_index) % 17 < 5 ? 0 : 3;
        fv = fetch_pc < 48 ? 3 : 0;
        fpc = {fetch_pc + 64'd4, fetch_pc};
        pred = {fetch_pc + 64'd8, fetch_pc + 64'd4};
        raw = fetch_pc < 48 ?
            {32'b0, program_mem[(fetch_pc>>2)+1], 32'b0, program_mem[fetch_pc>>2]} : 128'b0;
        #1;
        for (integer row = 0; row < 16; row = row + 1) begin
          if (wrapper.dut.execution.issue.valid_q[row] && wrapper.dut.execution.issue.class_q[row] == 5 &&
              wrapper.dut.execution.issue.tag_q[row][4:0] == htag[4:0]) begin
            canonical_windows = canonical_windows + 1;
            check(
                wrapper.dut.rob.valid_q[htag[4:0]] && !wrapper.dut.rob.done_q[htag[4:0]] &&
                    wrapper.dut.execution.issue.tag_q[row] == htag,
                "resident Serial lacks canonical unfinished head");
          end
          if (wrapper.dut.execution.issue.common_w[row] && wrapper.dut.execution.issue.class_q[row] == 5)
            check(effect_allow, "new Serial permission changed reachable IQ grant");
        end
        if (wrapper.dut.serial_active_w[htag[4:0]] && !serial_commit && !rst &&
            !wrapper.commit.event_valid_q && !recover && !irq_pending && !(cv[0] && cx[0])) begin
          if ($test$plusargs("head-stop")) begin
            early_stop_cycles = early_stop_cycles + 1;
            check(control_stop && wrapper.dut.birth_w == 0,
                  "resident head did not stop younger births");
          end
        end
        if ($test$plusargs(
                "bad-raw-freeze"
            ) && wrapper.dut.rob_count_o != 0 && !wrapper.dut.flush_i) begin
          force wrapper.dut.redirect_pending_w = ~wrapper.dut.rob.kill_w;
          tick();
          $fatal(1, "missing local redirect freeze check");
        end
        if ($test$plusargs("bad-serial-class") && wrapper.commit.event_valid_q) begin
          force wrapper.serial_class_w =
              ~{wrapper.commit.metadata_serial1, wrapper.commit.metadata_serial0};
          tick();
          $fatal(1, "missing retained Serial category check");
        end
        if ($test$plusargs("bad-head-stop") && serial_commit) begin
          force wrapper.head_serial_w = 0;
          tick();
          $fatal(1, "missing resident head stop assertion");
        end
        if (wrapper.dut.execution.registers.serial_owner_count != 0 && serial_hold)
          held_cycles = held_cycles + 1;
        if (wrapper.commit.event_valid_q) begin
          pending_cycles = pending_cycles + 1;
          check(!serial_allow && !sf, "pending recovery permitted new Serial");
        end
        if (!effect_allow && !wrapper.commit.event_valid_q && !rst) begin
          exception_windows = exception_windows + 1;
          check(!sf, "completed fault head produced Serial command");
        end
        if ($test$plusargs(
                "bad-canonical"
            ) && ((wrapper.dut.execution.read_valid_w[0] && wrapper.dut.execution.read_class_w[2:0] == 5) ||
                  (wrapper.dut.execution.read_valid_w[1] && wrapper.dut.execution.read_class_w[5:3] == 5))) begin
          bad_tag = htag ^ 9'h020;
          force wrapper.dut.serial_tag_o = bad_tag;
          force wrapper.dut.head_tag_o = bad_tag;
          serial_hold = 0;
          #1;
          check(sf, "negative injection did not target actual Serial fire");
          tick();
          $fatal(1, "missing canonical unfinished fulltag assertion");
        end
        if (sf) begin
          check(effect_allow && st == htag && !wrapper.dut.rob.done_q[st[4:0]],
                "original authority or unfinished head violated");
          serial_in_round = serial_in_round + 1;
          total_serial = total_serial + 1;
          generation_seen[st[8:5]] = 1;
          if (serial_slot_seen[st[4:0]] && last_generation[st[4:0]] > st[8:5])
            generation_wraps = generation_wraps + 1;
          last_generation[st[4:0]]  = st[8:5];
          serial_slot_seen[st[4:0]] = 1;
          if (su[95:64] == 32'h30200073) total_return = total_return + 1;
        end
        if (redir) branch_count = branch_count + 1;
        for (lane = 0; lane < 2; lane = lane + 1)
        if (retire_fire[lane]) begin
          check(committed < 7, "extra retired instruction");
          meta = cm[lane*M+:M];
          check(meta[`R64_M_PC] == 64'(expected_order[committed]) && !cx[lane],
                "wrong path or exceptional retirement");
          if (meta[`R64_M_PC] == 40) check(cd[lane*64+:64] == 4, "post-return arithmetic mismatch");
          committed = committed + 1;
          total_retired = total_retired + 1;
        end
        if (trap_event) begin
          check(!trap_irq && trap_cause == 2 && trap_pc == 44, "precise terminal trap");
          halted = 1;
          total_traps = total_traps + 1;
        end
        if (fv[0] && fr[0]) fetch_pc = fetch_pc + 4;
        if (fv[1] && fr[1]) fetch_pc = fetch_pc + 4;
        tick();
        @(negedge clk);
        cycles = cycles + 1;
      end
      check(halted && committed == 7 && serial_in_round == 3, "closed Serial progress");
      elapsed_total = elapsed_total + cycles;
    end
    fv = 0;
    cr = 3;
    serial_hold = 0;
    irq_pending = 1;
    cycles = 0;
    halted = 0;
    while (!halted && cycles < 20) begin
      #1;
      if (trap_event) begin
        check(trap_irq && trap_cause == 7, "empty IRQ drain");
        halted = 1;
      end
      tick();
      @(negedge clk);
      cycles = cycles + 1;
    end
    check(halted, "IRQ failed to take after complete drain");
    check(total_retired == 140 && total_serial == 60 && total_return == 20 && total_traps == 20,
          "closed coverage counts");
    check(held_cycles > 20 && pending_cycles >= 60 && exception_windows >= 20 && branch_count == 20,
          "closed boundary coverage");
    if ($test$plusargs("head-stop"))
      check(early_stop_cycles > 20, "early resident stop not exercised");
    check(prefix_checks>100 && dual_retire_checks>0 && fence_checks>=60,
          "transaction oracle missed retirement prefix or recovery delivery");
    $display("TRANSACTION_ORACLE prefix=%0d dual=%0d fence=%0d",
             prefix_checks,dual_retire_checks,fence_checks);
    $display("EARLY_STOP %0d", early_stop_cycles);
    $display("GEN %h elapsed %0d canonical %0d", generation_seen, elapsed_total, canonical_windows);
    check(canonical_windows >= 60, "resident canonical premise was not exercised");
    check(generation_wraps >= 2, "same-slot Serial generation wrap missing");
    $display("same-slot generation wraps=%0d", generation_wraps);
    $display(
        "[PASS] tb_r64_head_serial_class commits=%0d serial=%0d xret=%0d traps=%0d branch=%0d held=%0d pending=%0d exwin=%0d gen=%h",
        total_retired, total_serial, total_return, total_traps, branch_count, held_cycles,
        pending_cycles, exception_windows, generation_seen);
    $finish;
  end
endmodule
