`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_resolved_memory_notice;
  parameter DEPTH = 18;
  parameter EARLY_STORE = 0;
  parameter PREPARED_CANCEL = 0;
  localparam IW = $clog2(DEPTH);
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0;
  reg [31:0] kill = 0;
  reg [ 2:0] trigger_enable = 0;
  reg [63:0] trigger_address = 0;
  reg trigger_test = 0, no_external = 0;
  reg [8:0] full_tag[0:31];
  reg head_valid = 1, effect_allow = 1, fp_enable = 1;
  reg [8:0] head_tag = 0;
  reg [1:0] commit_fire = 0;
  reg [17:0] commit_tag = 0;
  reg [1:0] in_fire = 0;
  wire [1:0] in_ready;
  reg [17:0] in_tag = 0;
  reg [2*`R64_UOP_W-1:0] in_uop = 0;
  reg [383:0] operand = 0;
  wire [1:0] out_valid, resolved_valid;
  wire [17:0] resolved_tag;
  wire [127:0] resolved_data;
  reg [1:0] out_ready = 3;
  wire [17:0] out_tag;
  wire [2*`R64_RESULT_W-1:0] out_result;
  wire [31:0] reuse;
  wire irreversible, idle;
  wire [1:0] tv, tr, tad, tresp, trespready;
  wire [2*IW-1:0] ttoken, trtoken;
  R64TranslationTokenEcho #(.TOKEN_W(IW)) translation_model_tokens (
    .clk_i(clk), .rst_i(rst), .req_fire_i(tv & tr), .req_token_i(ttoken),
    .rsp_fire_i(tresp & trespready), .rsp_token_o(trtoken)
  );
  wire [127:0] tva, tpa;
  wire [3:0] ta, tc;
  wire [1:0] tfault, tneeds;
  wire [9:0] tcause;
  wire [1:0] mv, mr, mcache, mresp, mrespready, merror;
  wire [2*IW-1:0] mtoken, mresptoken;
  wire [127:0] ma, md, mrd;
  wire [3:0] mop;
  wire [5:0] msize;
  wire [15:0] mstrb;
  wire [9:0] mamo;
  // TB-only front-end: previous stimuli reserve in program order, then
  // bind the captured payload one edge later to the real dispatch-owned LSU.
  reg [1:0] bind_fire_q = 0;
  reg [17:0] bind_tag_q = 0;
  reg [2*`R64_UOP_W-1:0] bind_uop_q = 0;
  reg [383:0] bind_operand_q = 0;
  reg [2*IW-1:0] bind_slot_q = 0;
  wire [2*IW-1:0] reserve_slot_w;
  always @(posedge clk) begin
    if (rst || flush) bind_fire_q <= 0;
    else bind_fire_q <= in_fire;
    if (|in_fire) begin
      bind_tag_q <= in_tag;
      bind_uop_q <= in_uop;
      bind_operand_q <= operand;
      bind_slot_q <= reserve_slot_w;
    end
  end
  R64Lsu #(
    .EARLY_STORE(EARLY_STORE),
    .PREPARED_CANCEL(PREPARED_CANCEL),
    .ENTRIES(DEPTH),
    .INDEX_W(IW)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(flush),
    .kill_mask_i(kill),
    .cancel_candidates_i(kill),
    .cancel_active_i(|kill),
    .head_valid_i(head_valid),
    .head_tag_i(head_tag),
    .effect_allow_i(effect_allow),
    .trigger_enable_i(trigger_enable),
    .trigger_address_i(trigger_address),
    .fp_enable_i(fp_enable),
    .translate_active_i(1'b0),
    .store_done_valid_o(),
    .store_done_ready_i(1'b1),
    .store_done_tag_o(),
    .store_done_error_o(),
    .store_done_tval_o(),
    .mem_fast_store_o(),
    .mem_store_rsp_valid_i(1'b0),
    .mem_store_rsp_ready_o(),
    .mem_store_rsp_token_i({IW{1'b0}}),
    .mem_store_rsp_error_i(1'b0),
    .commit_fire_i(commit_fire),
    .commit_tag_i(commit_tag),
    .reserve_want_i(2'b11),
    .reserve_fire_i(in_fire),
    .reserve_ready_o(in_ready),
    .reserve_slot_o(reserve_slot_w),
    .reserve_tag_i(in_tag),
    .reserve_func_i({in_uop[`R64_UOP_W+196+:8], in_uop[196+:8]}),
    .reserve_amo_i({in_uop[`R64_UOP_W+155+:5], in_uop[155+:5]}),
    .in_fire_i(bind_fire_q),
    .in_ready_o(),
    .in_tag_i(bind_tag_q),
    .in_slot_i(bind_slot_q),
    .in_command_i({bind_uop_q[1*`R64_UOP_W+155+:5], bind_uop_q[1*`R64_UOP_W+196+:8], bind_operand_q[1*192+64+:64], bind_uop_q[1*`R64_UOP_W+64+:64], bind_operand_q[1*192+:64], bind_uop_q[0*`R64_UOP_W+155+:5], bind_uop_q[0*`R64_UOP_W+196+:8], bind_operand_q[0*192+64+:64], bind_uop_q[0*`R64_UOP_W+64+:64], bind_operand_q[0*192+:64]}),
    .out_valid_o(out_valid),
    .out_ready_i(out_ready),
    .out_tag_o(out_tag),
    .out_result_o(out_result),
    .resolved_value_valid_o(resolved_valid),
    .resolved_value_tag_o(resolved_tag),
    .resolved_value_data_o(resolved_data),
    .reuse_block_o(reuse),
    .irrevocable_o(irreversible),
    .idle_o(idle),
    .tr_token_o(ttoken),
    .tr_rsp_token_i(trtoken),
    .tr_valid_o(tv),
    .tr_ready_i(tr),
    .tr_vaddr_o(tva),
    .tr_access_o(ta),
    .tr_ad_update_o(tad),
    .tr_rsp_valid_i(tresp),
    .tr_rsp_ready_o(trespready),
    .tr_paddr_i(tpa),
    .tr_class_i(tc),
    .tr_fault_i(tfault),
    .tr_needs_ad_i(tneeds),
    .tr_cause_i(tcause),
    .mem_valid_o(mv),
    .mem_ready_i(mr),
    .mem_token_o(mtoken),
    .mem_addr_o(ma),
    .mem_data_o(md),
    .mem_op_o(mop),
    .mem_cache_o(mcache),
    .mem_size_o(msize),
    .mem_strb_o(mstrb),
    .mem_amo_o(mamo),
    .mem_rsp_valid_i(mresp),
    .mem_rsp_ready_o(mrespready),
    .mem_rsp_token_i(mresptoken),
    .mem_rsp_data_i(mrd),
    .mem_rsp_error_i(merror),
    .mem_rsp_offset_i(6'b0)
  );
  reg [63:0] memory[0:1023], expected[0:31];
  reg [31:0] active = 0, killed = 0, received = 0;
  reg [31:0] expectfault = 0;
  reg [5:0] expectcause[0:31];
  reg [63:0] expecttval[0:31];
  reg [63:0] tqueue[0:15];
  reg [1:0] taqueue[0:15];
  reg adqueue[0:15];
  integer tdue[0:15], th[0:1], tt[0:1], tn[0:1];
  reg [IW-1:0] mqtoken[0:15];
  reg [63:0] mqdata[0:15];
  reg mqerror[0:15];
  integer mdue[0:15], mh[0:1], mt[0:1], mn[0:1];
  integer cycles = 0, trcount = 0, memcount = 0, wbcount = 0, dual = 0, adupdates = 0;
  integer tr_delay = 2, mem_delay = 3;
  reg head_preparation_seen = 0;
  reg late_io_observe = 0;
  integer late_io_ready_cycles = 0;
  reg delay_owner = 0;
  reg [63:0] delayed_addr = 0;
  reg tr_hold = 0, mem_hold = 0, error_write = 0, bad_response = 0;
  reg [31:0] rng = 32'h947312bd;
  reg random_stall = 0;
  reg [1:0] response_hold = 0;
  reg error_read = 0;
  genvar g;
  generate
    for (g = 0; g < 2; g = g + 1) begin : gen_model
      assign tr[g] = tn[g] < 7 && !tr_hold && (!random_stall || rng[g]);
      assign tresp[g] = tn[g] != 0 && tdue[g*8+th[g]] <= cycles && !tr_hold;
      assign tpa[g*64+:64] = tqueue[g*8+th[g]] & ~64'h1000;
      assign tc[g*2+:2] = tqueue[g*8+th[g]][11:8] == 4'he ? 2'd2 : 2'd0;
      assign tfault[g] = tqueue[g*8+th[g]][11:8] == 4'hf;
      assign tneeds[g] = tqueue[g*8+th[g]][11:8] == 4'hd && taqueue[g*8+th[g]] == 2 &&
          !adqueue[g*8+th[g]];
      assign tcause[g*5+:5] = taqueue[g*8+th[g]] == 2 ? 5'd15 : 5'd13;
      assign mr[g] = mn[g] < 7 && !mem_hold && (!random_stall || rng[g+2]);
      assign mresp[g] = (bad_response && g == 0) ||
          (mn[g] != 0 && mdue[g*8+mh[g]] <= cycles && !mem_hold && !response_hold[g]);
      assign mresptoken[g*IW+:IW] = bad_response ? {IW{1'b0}} : mqtoken[g*8+mh[g]];
      assign mrd[g*64+:64] = mqdata[g*8+mh[g]];
      assign merror[g] = mqerror[g*8+mh[g]];
    end
  endgenerate
  integer a, b, tag, index, j, slot;
  reg [63:0] response_data;
  always @(posedge clk)
    if (!rst) begin
      if (delay_owner && dut.prepared_valid_q && dut.prepared_tag_q == 0) head_preparation_seen = 1;
      if (no_external && (tv != 0 || mv != 0))
        $fatal(1, "trigger escaped into translation/physical request");
      if (late_io_observe) begin
        for (integer lio = 0; lio < 2; lio = lio + 1) begin
          if (dut.query_fire_w[lio] && dut.query_in_tag_w[lio*9+:9] != 0)
            $fatal(1, "younger query published across unresolved/IO owner");
          if (mv[lio] && dut.tag_q[mtoken[lio*IW+:IW]] != 0)
            $fatal(1, "younger physical request passed pending IO");
        end
        for (integer lor = 1; lor < DEPTH; lor = lor + 1)
        if (dut.state_q[0] == 2 && dut.state_q[lor] == 3)
          late_io_ready_cycles = late_io_ready_cycles + 1;
      end
      cycles = cycles + 1;
      rng = {rng[30:0], rng[31] ^ rng[21] ^ rng[1] ^ rng[0]};
      for (a = 0; a < 2; a = a + 1) begin
        // Queue outputs must remain the accepted owner through the sampling edge.
        tn[a] <= tn[a] + ((tv[a] && tr[a]) ? 1 : 0) - ((tresp[a] && trespready[a]) ? 1 : 0);
        if (tresp[a] && trespready[a]) th[a] <= (th[a] + 1) % 8;
        if (tv[a] && tr[a]) begin
          tqueue[a*8+tt[a]] = tva[a*64+:64];
          taqueue[a*8+tt[a]] = ta[a*2+:2];
          adqueue[a*8+tt[a]] = tad[a];
          tdue[a*8+tt[a]] = cycles +
              ((delay_owner && tva[a*64+:64] == delayed_addr) ? 80 : tr_delay);
          tt[a] <= (tt[a] + 1) % 8;
          trcount = trcount + 1;
          if (tad[a] && ta[a*2+:2] == 2) adupdates = adupdates + 1;
        end
        mn[a] <= mn[a] + ((mv[a] && mr[a]) ? 1 : 0) - ((mresp[a] && mrespready[a]) ? 1 : 0);
        if (mresp[a] && mrespready[a]) mh[a] <= (mh[a] + 1) % 8;
        if (mv[a] && mr[a]) begin
          index = ma[a*64+:64] >> 3;
          response_data = memory[index];
          if (mop[a*2+:2] == 1 && !error_write)
            for (j = 0; j < 8; j = j + 1) if (mstrb[a*8+j]) memory[index][j*8+:8] = md[a*64+j*8+:8];
          mqtoken[a*8+mt[a]] = mtoken[a*IW+:IW];
          mqdata[a*8+mt[a]] = response_data;
          mqerror[a*8+mt[a]] = (mop[a*2+:2] != 0 && error_write) ||
              (mop[a*2+:2] == 0 && error_read);
          mdue[a*8+mt[a]] = cycles + mem_delay;
          mt[a] <= (mt[a] + 1) % 8;
          memcount = memcount + 1;
        end
        if (out_valid[a] && out_ready[a]) begin
          tag = out_tag[a*9+:5];
          if (trigger_test && out_tag[a*9+:9] !== full_tag[tag])
            $fatal(1, "trigger generation mismatch");
          if (!active[tag] || killed[tag] || received[tag])
            $fatal(
                1,
                "invalid completion tag %0d active%h killed%h received%h",
                tag,
                active,
                killed,
                received
            );
          if (out_result[a*`R64_RESULT_W+64] !== expectfault[tag] ||
              (!expectfault[tag] && out_result[a*`R64_RESULT_W+:64] !== expected[tag]) ||
              (expectfault[tag] && (out_result[a*`R64_RESULT_W+65+:6] !== expectcause[tag] ||
                                    out_result[a*`R64_RESULT_W+71+:64] !== expecttval[tag])))
            $fatal(
                1,
                "bad result tag%0d value%h expected%h exception%b",
                tag,
                out_result[a*`R64_RESULT_W+:64],
                expected[tag],
                out_result[a*`R64_RESULT_W+64]
            );
          received[tag] = 1;
          wbcount = wbcount + 1;
        end
      end
      if (out_valid == 3 && out_ready == 3) dual = dual + 1;
    end
  integer notice_observations = 0, notice_blocked = 0, notice_dual = 0;
  integer notice_lane, notice_slot;
  always @(posedge clk) if (!rst) begin
    if (resolved_valid == 3) notice_dual = notice_dual + 1;
    if (flush && resolved_valid != 0)
      $fatal(1, "resolved memory notice escaped flush");
    for (notice_lane = 0; notice_lane < 2; notice_lane = notice_lane + 1)
      if (resolved_valid[notice_lane]) begin
        notice_slot = int'(resolved_tag[notice_lane*9+:5]);
        if (!active[notice_slot] || killed[notice_slot] || kill[notice_slot] ||
            expectfault[notice_slot] ||
            resolved_data[notice_lane*64+:64] !== expected[notice_slot])
          $fatal(1, "resolved memory notice wrong/cancelled/faulted payload tag=%0d data=%h expected=%h",
                 resolved_tag[notice_lane*9+:9], resolved_data[notice_lane*64+:64],
                 expected[notice_slot]);
        notice_observations = notice_observations + 1;
        if (out_ready == 0) notice_blocked = notice_blocked + 1;
      end
  end
  task enqueue;
    input [8:0] tagno;
    input [63:0] addr, data;
    input [7:0] fn;
    input [4:0] amo;
    input [63:0] answer;
    input fault;
    input [5:0] cause;
    begin
      @(negedge clk);
      while (!in_ready[0]) @(negedge clk);
      in_fire = 1;
      in_tag = {9'b0, tagno};
      in_uop = 0;
      operand = 0;
      in_uop[196+:8] = fn;
      in_uop[155+:5] = amo;
      operand[63:0] = addr;
      operand[64+:64] = data;
      full_tag[tagno[4:0]] = tagno;
      active[tagno[4:0]] = 1;
      received[tagno[4:0]] = 0;
      killed[tagno[4:0]] = 0;
      expected[tagno[4:0]] = answer;
      expectfault[tagno[4:0]] = fault;
      expectcause[tagno[4:0]] = cause;
      expecttval[tagno[4:0]] = addr;
      @(negedge clk);
      in_fire = 0;
    end
  endtask
  task wait_result;
    input [4:0] tagno;
    begin
      while (!received[tagno]) @(negedge clk);
    end
  endtask
  task retire;
    input [8:0] tagno;
    begin
      @(negedge clk);
      commit_fire = 1;
      commit_tag  = {9'b0, tagno};
      @(negedge clk);
      commit_fire = 0;
      active[tagno[4:0]] = 0;
    end
  endtask

  integer notice_count[0:511], cq_count[0:511], wb_count[0:511];
  integer first_notice[0:511], capture_cycle[0:511];
  reg [63:0] notice_value[0:511];
  reg [31:0] noticed_slots = 0;
  integer blocked_dual = 0, raw_notices = 0, forward_notices = 0;
  integer lane_check, owner_check;
  always @(posedge clk) if (!rst) begin
    if (resolved_valid == 3 && dut.completion_credit_w == 0)
      blocked_dual = blocked_dual + 1;
    for (lane_check = 0; lane_check < 2; lane_check = lane_check + 1) begin
      if (resolved_valid[lane_check]) begin
        owner_check = int'(resolved_tag[lane_check*9+:9]);
        if (resolved_tag[lane_check*9+:9] !== full_tag[owner_check%32])
          $fatal(1, "notice full-tag generation mismatch");
        if (notice_count[owner_check] != 0 &&
            resolved_data[lane_check*64+:64] !== notice_value[owner_check])
          $fatal(1, "notice changed a resident owner's final value");
        if (notice_count[owner_check] == 0) first_notice[owner_check] = cycles;
        notice_count[owner_check] = notice_count[owner_check] + 1;
        notice_value[owner_check] = resolved_data[lane_check*64+:64];
        noticed_slots[owner_check%32] = 1;
        for (integer source_check = 0; source_check < 6; source_check = source_check + 1)
          if (dut.event_occupied_w[source_check] &&
              dut.event_tag_w[source_check] == resolved_tag[lane_check*9+:9]) begin
            if (source_check < 2) raw_notices = raw_notices + 1;
            if (source_check >= 4) forward_notices = forward_notices + 1;
          end
      end
      if (dut.completion_fire_w[lane_check]) begin
        owner_check = int'(dut.completion_tag_w[lane_check*9+:9]);
        cq_count[owner_check] = cq_count[owner_check] + 1;
        capture_cycle[owner_check] = cycles;
        if (cq_count[owner_check] != 1)
          $fatal(1, "notice duplicated canonical CQ completion");
        if (!dut.completion_result_w[lane_check*140+64] &&
            (!resolved_valid[lane_check] ||
             resolved_tag[lane_check*9+:9] !== dut.completion_tag_w[lane_check*9+:9] ||
             resolved_data[lane_check*64+:64] !== dut.completion_result_w[lane_check*140+:64]))
          $fatal(1, "actual CQ take differs from same-age successful notice");
        if (dut.completion_result_w[lane_check*140+64] && resolved_valid[lane_check])
          $fatal(1, "exception completion announced a numeric result");
      end
      if (out_valid[lane_check] && out_ready[lane_check]) begin
        owner_check = int'(out_tag[lane_check*9+:9]);
        wb_count[owner_check] = wb_count[owner_check] + 1;
        if (wb_count[owner_check] != 1)
          $fatal(1, "notice duplicated architectural completion");
        if (!out_result[lane_check*140+64] &&
            (notice_count[owner_check] == 0 ||
             out_result[lane_check*140+:64] !== notice_value[owner_check]))
          $fatal(1, "successful WB did not preserve announced value");
      end
    end
  end
  task pair;
    input [8:0] t0, t1;
    input [63:0] a0, a1;
    begin
      @(negedge clk);
      while (in_ready != 3) @(negedge clk);
      in_fire = 3; in_tag = {t1,t0}; in_uop = 0; operand = 0;
      in_uop[196+:8] = 8'h03;
      in_uop[`R64_UOP_W+196+:8] = 8'h03;
      operand[63:0] = a0; operand[192+:64] = a1;
      full_tag[t0%32] = t0; full_tag[t1%32] = t1;
      active[t0%32] = 1; active[t1%32] = 1;
      received[t0%32] = 0; received[t1%32] = 0;
      killed[t0%32] = 0; killed[t1%32] = 0;
      expected[t0%32] = memory[a0>>3]; expected[t1%32] = memory[a1>>3];
      expectfault[t0%32] = 0; expectfault[t1%32] = 0;
      @(negedge clk); in_fire = 0;
    end
  endtask
  task drain;
    integer limit;
    begin
      limit=0;
      while (!idle && limit<200) begin @(negedge clk); limit=limit+1; end
      if (!idle || reuse != 0) $fatal(1, "notice changed owner drain/reuse");
    end
  endtask
  integer n;
  reg [5:0] held_before;
  reg [17:0] held_tags;
  reg [127:0] held_values;
  initial begin
    for (n=0;n<1024;n=n+1) memory[n]=64'h1234567880000000+n;
    for (n=0;n<512;n=n+1) begin
      notice_count[n]=0;cq_count[n]=0;wb_count[n]=0;
      first_notice[n]=-1;capture_cycle[n]=-1;notice_value[n]=0;
    end
    for (n=0;n<2;n=n+1) begin th[n]=0;tt[n]=0;tn[n]=0;mh[n]=0;mt[n]=0;mn[n]=0;end
    repeat(4) @(negedge clk);
    if (resolved_valid != 0) $fatal(1,"notice escaped reset");
    rst=0;tr_delay=1;mem_delay=1;trigger_test=1;
    // Four canonical CQ owners stop further acceptance. Both later raw
    // resident results must still publish their own full tag and final value.
    out_ready=0;
    for(n=0;n<4;n=n+1)
      enqueue(9'(n),64'(n*8),0,8'h03,0,memory[n],0,0);
    while(dut.completion_credit_w != 0) @(negedge clk);
    response_hold=3;
    pair(4,5,32,40);
    while(mn[0]==0 || mn[1]==0) @(negedge clk);
    repeat(3) @(negedge clk);response_hold=0;
    while(resolved_valid!=3) @(negedge clk);
    held_tags=resolved_tag;held_values=resolved_data;held_before=dut.completion_arbiter.before_q;
    repeat(5) begin
      @(negedge clk);
      if (resolved_valid!=3 || resolved_tag!==held_tags ||
          resolved_data!==held_values || dut.completion_credit_w!=0 ||
          dut.event_grant_w!=0 || cq_count[4]!=0 || cq_count[5]!=0 ||
          !reuse[4] || !reuse[5] || dut.completion_arbiter.before_q!==held_before)
        $fatal(1,"credit-free repeated notice changed payload/owner/completion");
    end
    if(blocked_dual<4) $fatal(1,"blocked dual notice coverage vacuous");
    out_ready=3;
    for(n=0;n<6;n=n+1) wait_result(5'(n));
    drain;
    if(capture_cycle[4]-first_notice[4]<4 || capture_cycle[5]-first_notice[5]<4)
      $fatal(1,"notice did not precede CQ availability");
    $display("NOTICE_CASE credit_independent repeated_dual=%0d",blocked_dual);

    // A second blocked pair exercises same-cycle killed-first selection.
    out_ready=0;
    for(n=6;n<10;n=n+1)
      enqueue(9'(n),64'(n*8),0,8'h03,0,memory[n],0,0);
    while(dut.completion_credit_w != 0) @(negedge clk);
    response_hold=3;pair(10,11,80,88);
    while(mn[0]==0 || mn[1]==0) @(negedge clk);
    repeat(3) @(negedge clk);response_hold=0;
    while(resolved_valid!=3) @(negedge clk);
    kill=32'b1<<10;killed[10]=1;
    #1;
    if((resolved_valid[0] && resolved_tag[0+:9]==10) ||
       (resolved_valid[1] && resolved_tag[9+:9]==10) || resolved_valid==0)
      $fatal(1,"same-cycle kill failed to suppress only dead notice");
    @(negedge clk);kill=0;
    flush=1;killed=killed|32'hfc0;
    #1;if(resolved_valid!=0) $fatal(1,"flush failed to suppress resident notices");
    @(negedge clk);flush=0;out_ready=3;
    drain;
    if(cq_count[10]!=0 || cq_count[11]!=0 || wb_count[10]!=0 || wb_count[11]!=0)
      $fatal(1,"cancelled notice manufactured architectural completion");
    // Reuse the cancelled physical ROB index under a different generation.
    enqueue(42,104,0,8'h03,0,memory[13],0,0);wait_result(10);drain;
    if(notice_count[42]==0 || wb_count[42]!=1) $fatal(1,"new generation notice absent");
    $display("NOTICE_CASE cancel_flush_generation old=10 new=42");

    // Signed/unsigned formatting is published after final LSU transformation.
    enqueue(12,0,0,8'h02,0,64'hffffffff80000000,0,0);
    wait_result(12);drain;
    enqueue(13,0,0,8'h06,0,64'h0000000080000000,0,0);
    wait_result(13);drain;
    // Full store forwarding uses a different completion source; the store is
    // still speculative and cannot reach the physical endpoint before head.
    head_tag=14;
    enqueue(15,128,64'h00000000aabbccdd,8'h22,0,0,0,0);
    enqueue(16,128,0,8'h02,0,64'hffffffffaabbccdd,0,0);
    wait_result(16);
    if(forward_notices==0) $fatal(1,"forward source notice coverage vacuous");
    head_tag=15;wait_result(15);retire(15);retire(16);drain;
    // Partial forwarding must publish merged memory and store bytes, not
    // raw external memory data or the forwarding word alone.
    head_tag=17;
    enqueue(18,129,64'h77,8'h20,0,0,0,0);
    enqueue(19,128,0,8'h03,0,64'h12345678aabb77dd,0,0);
    wait_result(19);
    head_tag=18;wait_result(18);retire(18);retire(19);drain;
    $display("NOTICE_CASE formatted_forward_merge raw=%0d forward=%0d",raw_notices,forward_notices);

    error_read=1;head_tag=20;
    enqueue(20,160,0,8'h03,0,0,1,5);
    wait_result(20);error_read=0;retire(20);drain;
    enqueue(21,64'hf00,0,8'h03,0,0,1,13);
    wait_result(21);retire(21);drain;
    if(notice_count[20]!=0 || notice_count[21]!=0 ||
       cq_count[20]!=1 || cq_count[21]!=1)
      $fatal(1,"physical/local exception published numeric value or lost completion");
    $display("[PASS] tb_r64_resolved_memory_notice prepared_cancel=%0d observations=%0d blocked_dual=%0d raw=%0d forward=%0d",
             PREPARED_CANCEL,notice_observations,blocked_dual,raw_notices,forward_notices);
    $finish;
  end
  initial begin #100000;$fatal(1,"notice timeout cycles=%0d reuse=%h received=%h",cycles,reuse,received);end
endmodule
