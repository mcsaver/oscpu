// Directed response-path tests through the ordinary reserve/bind/translation/
// memory interfaces. No DUT force or assertion suppression is used.
integer rb_rsp_cycle[0:511], rb_cq_cycle[0:511];
integer rb_rsp_count[0:511], rb_cq_count[0:511], rb_wb_count[0:511], rb_raw_count[0:511];
reg [8:0] rb_slot_tag[0:DEPTH-1];
integer rb_epoch = 0, rb_dual_rsp = 0, rb_competition_lost = 0;
integer rb_l, rb_t, rb_k;
reg rb_same_capture;
always @(posedge clk) begin
  if (!rst && $test$plusargs("response-bypass")) begin
    rb_epoch = rb_epoch + 1;
    if ((mresp & mrespready) == 3) rb_dual_rsp = rb_dual_rsp + 1;
    for (rb_l = 0; rb_l < 2; rb_l = rb_l + 1) begin
      if (in_fire[rb_l]) rb_slot_tag[reserve_slot_w[rb_l*IW+:IW]] = in_tag[rb_l*9+:9];
      if (mresp[rb_l] && mrespready[rb_l]) begin
        rb_t = int'(rb_slot_tag[mresptoken[rb_l*IW+:IW]]);
        rb_rsp_count[rb_t] = rb_rsp_count[rb_t] + 1;
        rb_rsp_cycle[rb_t] = rb_epoch;
        if (rb_rsp_count[rb_t] != 1) $fatal(1, "duplicate physical response tag=%0d", rb_t);
        rb_same_capture = 0;
        for (rb_k = 0; rb_k < 2; rb_k = rb_k + 1)
          if (dut.completion_fire_w[rb_k] && dut.completion_tag_w[rb_k*9+:9] == 9'(rb_t))
            rb_same_capture = 1;
        if (!killed[rb_t%32] && !flush && !merror[rb_l] &&
            dut.response_queue.valid_q[rb_l] == 0 && dut.completion_credit_w != 0 &&
            (|dut.event_valid_w[3:2]) && (|dut.event_valid_w[5:4]) && !rb_same_capture)
          rb_competition_lost = rb_competition_lost + 1;
      end
      if (dut.raw_queue_fire_w[rb_l]) begin
        rb_t = int'(rb_slot_tag[mresptoken[rb_l*IW+:IW]]);
        rb_raw_count[rb_t] = rb_raw_count[rb_t] + 1;
      end
      if (out_valid[rb_l] && out_ready[rb_l]) begin
        rb_t = int'(out_tag[rb_l*9+:9]);
        if (out_tag[rb_l*9+:9] !== full_tag[rb_t%32])
          $fatal(1, "response bypass full generation mismatch actual=%0d expected=%0d",
                 rb_t, full_tag[rb_t%32]);
        rb_wb_count[rb_t] = rb_wb_count[rb_t] + 1;
        if (rb_wb_count[rb_t] != 1) $fatal(1, "duplicate WB tag=%0d", rb_t);
      end
    end
    // Process CQ after both response lanes, allowing same-edge captures.
    for (rb_l = 0; rb_l < 2; rb_l = rb_l + 1)
      if (dut.completion_fire_w[rb_l]) begin
        rb_t = int'(dut.completion_tag_w[rb_l*9+:9]);
        rb_cq_count[rb_t] = rb_cq_count[rb_t] + 1;
        rb_cq_cycle[rb_t] = rb_epoch;
        if (rb_cq_count[rb_t] != 1) $fatal(1, "duplicate CQ tag=%0d", rb_t);
        if (!active[rb_t%32] || killed[rb_t%32] ||
            dut.completion_tag_w[rb_l*9+:9] !== full_tag[rb_t%32])
          $fatal(1, "CQ accepted wrong owner tag=%0d", rb_t);
      end
  end
end

task rb_pair;
  input [8:0] t0, t1;
  input [63:0] a0, a1;
  reg saved_stall;
  integer pair_bound;
  begin
    // Pair fixture requires simultaneous issue into both physical lanes.
    // Pause randomized request-ready only for this arrangement, then restore it.
    saved_stall = random_stall;
    random_stall = 0;
    @(negedge clk);
    while (in_ready != 3) @(negedge clk);
    in_fire = 3;
    in_tag = {t1, t0};
    in_uop = 0;
    in_uop[196+:8] = 8'h03;
    in_uop[`R64_UOP_W+196+:8] = 8'h03;
    operand = 0;
    operand[63:0] = a0;
    operand[192+:64] = a1;
    full_tag[t0[4:0]] = t0; full_tag[t1[4:0]] = t1;
    active[t0[4:0]] = 1; active[t1[4:0]] = 1;
    received[t0[4:0]] = 0; received[t1[4:0]] = 0;
    killed[t0[4:0]] = 0; killed[t1[4:0]] = 0;
    expected[t0[4:0]] = memory[a0>>3]; expected[t1[4:0]] = memory[a1>>3];
    expectfault[t0[4:0]] = 0; expectfault[t1[4:0]] = 0;
    @(negedge clk);
    in_fire = 0;
    pair_bound = 0;
    while ((mn[0] == 0 || mn[1] == 0) && pair_bound < 100) begin
      @(negedge clk);
      pair_bound = pair_bound + 1;
    end
    if (mn[0] == 0 || mn[1] == 0)
      $fatal(1, "pair fixture failed to issue both lanes mn=%0d/%0d", mn[0], mn[1]);
    random_stall = saved_stall;
  end
endtask

task rb_check_latency;
  input [8:0] t;
  input integer latency;
  begin
    if (rb_rsp_count[t] != 1 || rb_cq_count[t] != 1 || rb_wb_count[t] != 1 ||
        rb_cq_cycle[t] - rb_rsp_cycle[t] != latency)
      $fatal(1, "response latency tag=%0d rsp=%0d cq=%0d wb=%0d delta=%0d expected=%0d",
             t, rb_rsp_count[t], rb_cq_count[t], rb_wb_count[t],
             rb_cq_cycle[t] - rb_rsp_cycle[t], latency);
  end
endtask

task rb_drain;
  integer bound;
  begin
    bound = 0;
    while (!idle && bound < 300) begin
      @(negedge clk);
      bound = bound + 1;
    end
    if (!idle || reuse != 0) $fatal(1, "response bypass owner leak reuse=%h", reuse);
  end
endtask

// Toggle only cancellation between clock edges while a real, held response
// is offered. Routing is speculative; a handshake/capture never occurs here.
task rb_check_cancel_route;
  reg [17:0] saved_masks;
  reg [17:0] saved_tags;
  reg [2*`R64_RESULT_W-1:0] saved_results;
  reg [31:0] saved_kill;
  reg saved_flush;
  begin
    saved_kill = kill;
    saved_flush = flush;
    response_hold = 0;
    #1;
    if (!(|mresp) || !(|mrespready) || !(|dut.response_bypass_candidate_w))
      $fatal(1, "cancel route fixture lacks a real eligible response");
    saved_masks = {dut.event_candidate_w, dut.event_first_w, dut.event_second_w};
    saved_tags = dut.completion_tag_w;
    saved_results = dut.completion_result_w;
    kill = 32'hffffffff;
    #1;
    if ({dut.event_candidate_w, dut.event_first_w, dut.event_second_w} !== saved_masks ||
        dut.completion_tag_w !== saved_tags || dut.completion_result_w !== saved_results ||
        dut.completion_fire_w !== 0 || dut.raw_queue_fire_w !== 0)
      $fatal(1, "partial kill changed response routing or published a dead owner");
    kill = saved_kill;
    flush = 1;
    #1;
    if ({dut.event_candidate_w, dut.event_first_w, dut.event_second_w} !== saved_masks ||
        dut.completion_tag_w !== saved_tags || dut.completion_result_w !== saved_results ||
        dut.completion_fire_w !== 0 || dut.raw_queue_fire_w !== 0 || (|mrespready))
      $fatal(1, "flush changed response routing or original ready/capture semantics");
    flush = saved_flush;
    #1;
  end
endtask

task run_response_bypass;
  integer q;
  integer rb_first_tag, rb_other_tag;
  begin
    for (q = 0; q < 512; q = q + 1) begin
      rb_rsp_cycle[q] = -1; rb_cq_cycle[q] = -1;
      rb_rsp_count[q] = 0; rb_cq_count[q] = 0;
      rb_wb_count[q] = 0; rb_raw_count[q] = 0;
    end
    for (q = 0; q < DEPTH; q = q + 1) rb_slot_tag[q] = 0;
    trigger_test = 1;
    random_stall = $test$plusargs("response-stalls");
    tr_delay = 1; mem_delay = 1;
    enqueue(0, 0, 0, 8'h03, 0, memory[0], 0, 0);
    wait_result(0);
    rb_check_latency(0, RESPONSE_BYPASS ? 0 : 1);
    rb_drain;
    $display("RESPONSE_BYPASS_CASE single_empty delta=%0d", rb_cq_cycle[0]-rb_rsp_cycle[0]);

    if (RESPONSE_BYPASS) begin
      response_hold = 3;
      enqueue(128, 0, 0, 8'h03, 0, memory[0], 0, 0);
      while (mn[0] + mn[1] == 0) @(negedge clk);
      repeat (4) @(negedge clk);
      rb_check_cancel_route;
      wait_result(0);
      rb_check_latency(128, 0);
      rb_drain;
      $display("RESPONSE_BYPASS_CASE cancel_route_invariant real_response_no_force");
    end

    response_hold = 3;
    rb_pair(1, 2, 8, 16);
    while (mn[0] == 0 || mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    response_hold = 0;
    wait_result(1); wait_result(2);
    rb_check_latency(1, RESPONSE_BYPASS ? 0 : 1);
    rb_check_latency(2, RESPONSE_BYPASS ? 0 : 1);
    if (rb_dual_rsp == 0) $fatal(1, "two-lane response case vacuous");
    rb_drain;
    $display("RESPONSE_BYPASS_CASE dual_empty dual_rsp=%0d", rb_dual_rsp);

    // CQ-full fallback must also complete normally, without using cancellation
    // to drain the retained response. Distinct generations reuse old ROB slots.
    out_ready = 0;
    for (q = 64; q < 68; q = q + 1)
      enqueue(9'(q), 64'((q-64)*8), 0, 8'h03, 0, memory[q-64], 0, 0);
    while (dut.completion_credit_w != 0) @(negedge clk);
    response_hold = 3;
    rb_pair(68, 69, 32, 40);
    while (mn[0] == 0 || mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    response_hold = 0;
    while (rb_rsp_count[68] == 0 || rb_rsp_count[69] == 0) @(negedge clk);
    if (rb_cq_count[68] != 0 || rb_cq_count[69] != 0 ||
        rb_raw_count[68] != 1 || rb_raw_count[69] != 1)
      $fatal(1, "CQ-full live fallback did not retain exactly one response");
    out_ready = 3;
    for (q = 64; q < 70; q = q + 1) begin
      wait_result(5'(q));
      if (rb_cq_count[q] != 1 || rb_wb_count[q] != 1)
        $fatal(1, "CQ-full live fallback lost or duplicated completion tag=%0d", q);
    end
    rb_drain;
    $display("RESPONSE_BYPASS_CASE cq_full_live_fallback exactly_once=6");

    // Four CQ owners block WB, then raw heads occupy both lanes.
    out_ready = 0;
    for (q = 3; q < 7; q = q + 1)
      enqueue(9'(q), 64'(q*8), 0, 8'h03, 0, memory[q], 0, 0);
    while (dut.completion_credit_w != 0) @(negedge clk);
    response_hold = 3;
    rb_pair(7, 8, 56, 64);
    while (mn[0] == 0 || mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    response_hold = 0;
    while (rb_rsp_count[7] == 0 || rb_rsp_count[8] == 0) @(negedge clk);
    if (rb_cq_count[7] != 0 || rb_cq_count[8] != 0 ||
        rb_raw_count[7] != 1 || rb_raw_count[8] != 1)
      $fatal(1, "CQ full did not retain exact raw fallback");
    $display("RESPONSE_BYPASS_CASE cq_full raw_fallback=2");
    // Next two real responses meet kill of old raw heads, while CQ is free.
    response_hold = 3;
    rb_pair(9, 10, 72, 80);
    while (mn[0] == 0 || mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    killed = killed | 32'h78; kill = 32'h78; // kill CQ tags 3..6
    @(negedge clk);
    killed = killed | 32'h180; kill = 32'h180; // raw tags 7,8
    if (dut.response_queue.valid_q[0] == 0 || dut.response_queue.valid_q[1] == 0 ||
        dut.completion_credit_w == 0) $fatal(1, "old raw kill fixture not occupied/credited");
    response_hold = 0;
    @(negedge clk);
    kill = 0;
    out_ready = 3;
    wait_result(9); wait_result(10);
    rb_check_latency(9, 1); rb_check_latency(10, 1);
    if (rb_raw_count[9] != 1 || rb_raw_count[10] != 1 ||
        rb_wb_count[7] != 0 || rb_wb_count[8] != 0)
      $fatal(1, "old killed raw head was treated as physically empty");
    rb_drain;
    $display("RESPONSE_BYPASS_CASE occupied_kill_new_response no_bypass=2");

    response_hold = 3;
    enqueue(11, 88, 0, 8'h03, 0, memory[11], 0, 0);
    while (mn[0] + mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    killed[11] = 1; kill = 32'h800; response_hold = 0;
    @(negedge clk); kill = 0;
    rb_drain;
    if (rb_cq_count[11] != 0 || rb_raw_count[11] != 0 || rb_wb_count[11] != 0)
      $fatal(1, "incoming killed response escaped");
    response_hold = 3;
    enqueue(12, 96, 0, 8'h03, 0, memory[12], 0, 0);
    while (mn[0] + mn[1] == 0) @(negedge clk);
    repeat (4) @(negedge clk);
    killed[12] = 1; flush = 1; response_hold = 0;
    @(negedge clk); flush = 0;
    rb_drain;
    if (rb_cq_count[12] != 0 || rb_raw_count[12] != 0 || rb_wb_count[12] != 0)
      $fatal(1, "incoming flushed response escaped");
    $display("RESPONSE_BYPASS_CASE incoming_kill_flush no_completion=2");

    // Hold results while LSQ entries are reused; cancel an old canonical tag
    // and reuse its physical ROB slot with a different generation and value.
    out_ready = 0;
    for (q = 13; q < 17; q = q + 1)
      enqueue(9'(q), 64'(q*8), 0, 8'h03, 0, memory[q], 0, 0);
    while (dut.completion_credit_w != 0) @(negedge clk);
    killed[13] = 1; kill = 32'h2000;
    @(negedge clk); kill = 0;
    while (reuse[13]) @(negedge clk);
    enqueue(45, 160, 0, 8'h03, 0, memory[20], 0, 0);
    while (rb_rsp_count[45] == 0) @(negedge clk);
    out_ready = 3;
    wait_result(14); wait_result(15); wait_result(16); wait_result(13);
    rb_drain;
    if (rb_wb_count[13] != 0 || rb_wb_count[45] != 1 || rb_cq_count[45] != 1)
      $fatal(1, "held metadata / full generation reuse failed");
    $display("RESPONSE_BYPASS_CASE held_metadata_generation old=13 new=45");

    error_read = 1;
    enqueue(17, 136, 0, 8'h03, 0, 0, 1, 5);
    wait_result(17); error_read = 0;
    rb_check_latency(17, 1);
    retire(17);
    head_tag = 18;
    enqueue(18, 64'he00, 0, 8'h03, 0, memory[448], 0, 0);
    wait_result(18); rb_check_latency(18, 1); retire(18);
    head_tag = 19;
    enqueue(19, 0, 0, 8'h83, 2, memory[0], 0, 0);
    wait_result(19); rb_check_latency(19, 1); retire(19);
    head_tag = 20;
    enqueue(20, 3, 0, 8'h03, 0, memory[0], 0, 0);
    wait_result(20); rb_check_latency(20, 1); retire(20);
    rb_drain;
    $display("RESPONSE_BYPASS_CASE excluded error_io_atomic_misaligned=4");

    // Competing fault and store-forward events are retained behind full CQ.
    // Release CQ and ordinary responses together. RR must arbitrate all six
    // original sources; an ungranted response must fall back exactly once.
    out_ready = 0;
    for (q = 21; q < 25; q = q + 1)
      enqueue(9'(q), 64'(q*8), 0, 8'h03, 0, memory[q], 0, 0);
    while (dut.completion_credit_w != 0) @(negedge clk);
    enqueue(25, 64'hf00, 0, 8'h03, 0, 0, 1, 13);
    head_tag = 31;
    enqueue(26, 0, 64'h55, 8'h23, 0, 0, 0, 0);
    enqueue(27, 0, 0, 8'h03, 0, 64'h55, 0, 0);
    response_hold = 3;
    rb_pair(28, 29, 224, 232);
    while (mn[0] == 0 || mn[1] == 0 ||
           !(|dut.event_valid_w[3:2]) || !(|dut.event_valid_w[5:4])) @(negedge clk);
    repeat (4) @(negedge clk);
    killed = killed | 32'h1e00000; kill = 32'h1e00000;
    @(negedge clk);
    kill = 0; response_hold = 0;
    @(negedge clk);
    if (rb_competition_lost == 0) $fatal(1, "fault/forward response arbitration case vacuous");
    out_ready = 3;
    wait_result(25); wait_result(27); wait_result(28); wait_result(29);
    if (rb_cq_count[28] != 1 || rb_cq_count[29] != 1 ||
        rb_wb_count[28] != 1 || rb_wb_count[29] != 1)
      $fatal(1, "arbitration fallback lost or duplicated response");
    head_tag = 26;
    wait_result(26); retire(26);
    rb_drain;
    $display("RESPONSE_BYPASS_CASE competing_fault_forward lost_grant=%0d", rb_competition_lost);
    // Two empty raw lanes compete for exactly one registered CQ credit.
    // The unselected physical response must retain its own raw fallback.
    out_ready = 0;
    for (q = 80; q < 83; q = q + 1)
      enqueue(9'(q), 64'((q-80)*8), 0, 8'h03, 0, memory[q-80], 0, 0);
    while (rb_cq_count[82] == 0) @(negedge clk);
    if (dut.completion_credit_w !== 2'b01)
      $fatal(1, "one-credit fixture lacks exactly one CQ slot");
    response_hold = 3;
    rb_pair(83, 84, 24, 32);
    repeat (4) @(negedge clk);
    response_hold = 0;
    while (rb_rsp_count[83] == 0 || rb_rsp_count[84] == 0) @(negedge clk);
    if (rb_cq_count[83] + rb_cq_count[84] != (RESPONSE_BYPASS ? 1 : 0) ||
        rb_raw_count[83] + rb_raw_count[84] != (RESPONSE_BYPASS ? 1 : 2))
      $fatal(1, "two responses consumed wrong CQ credit or lost fallback");
    out_ready = 3;
    for (q = 80; q < 85; q = q + 1) begin
      wait_result(5'(q));
      if (rb_cq_count[q] != 1 || rb_wb_count[q] != 1)
        $fatal(1, "one-credit case lost or duplicated owner tag=%0d", q);
    end
    rb_drain;
    $display("RESPONSE_BYPASS_CASE dual_one_credit exactly_once=5 raw_fallback=%0d",
             rb_raw_count[83] + rb_raw_count[84]);
    if (RESPONSE_BYPASS) begin
      // Kill exactly the first chosen real response while the second remains
      // live. Two credits must capture sparse rank1 without moving its data.
      out_ready = 0;
      response_hold = 3;
      rb_pair(160, 161, 0, 8);
      repeat (4) @(negedge clk);
      response_hold = 0;
      #1;
      if (mresp !== 3 || dut.completion_credit_w !== 3 ||
          dut.response_bypass_candidate_w !== 3)
        $fatal(1, "sparse response fixture is not a two-response/two-credit offer");
      rb_first_tag = int'(dut.completion_tag_w[0+:9]);
      rb_other_tag = int'(dut.completion_tag_w[9+:9]);
      if (!((rb_first_tag == 160 && rb_other_tag == 161) ||
            (rb_first_tag == 161 && rb_other_tag == 160)))
        $fatal(1, "sparse response fixture selected wrong identities");
      killed[rb_first_tag%32] = 1;
      kill = 32'b1 << (rb_first_tag%32);
      #1;
      if (dut.completion_fire_w !== 2'b10 ||
          dut.completion_tag_w[9+:9] !== 9'(rb_other_tag))
        $fatal(1, "live second response was compacted or lost after first kill");
      @(negedge clk);
      kill = 0;
      out_ready = 3;
      wait_result(5'(rb_other_tag));
      rb_drain;
      if (rb_rsp_count[rb_first_tag] != 1 || rb_cq_count[rb_first_tag] != 0 ||
          rb_raw_count[rb_first_tag] != 0 || rb_wb_count[rb_first_tag] != 0 ||
          rb_cq_count[rb_other_tag] != 1 || rb_raw_count[rb_other_tag] != 0 ||
          rb_wb_count[rb_other_tag] != 1)
        $fatal(1, "sparse response drain/capture identity conservation failed");
      rb_check_latency(9'(rb_other_tag), 0);
      $display("RESPONSE_BYPASS_CASE sparse_live_rank1 dead=%0d live=%0d",
               rb_first_tag, rb_other_tag);
    end
    $display("[PASS] tb_r64_lsu response-bypass parameter=%0d stalls=%0d full_tag_exactly_once",
             RESPONSE_BYPASS, random_stall);
    $finish;
  end
endtask
