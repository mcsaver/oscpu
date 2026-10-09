`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_lsu_event_count;
  localparam TAG_W = 9;
  localparam R = `R64_RESULT_W;
  reg clk = 0, rst = 1;
  reg [5:0] candidate_mask = 0, live_mask = 0, before_mask = 0;
  reg [1:0] credit = 0;
  R64Lsu #(
    .ENTRIES(20),
    .INDEX_W(5),
    .HEAD_AUTHORIZED_QUERY(1),
    .PREPARED_CANCEL(1)
  ) dut (
    .clk_i(clk),
    .rst_i(rst),
    .flush_i(1'b0),
    .kill_mask_i(32'b0)
  );

  function [TAG_W-1:0] source_tag(input integer source);
    source_tag = TAG_W'(32 + source * 33);
  endfunction
  function [R-1:0] source_result(input integer source);
    source_result = {5'(source + 1), 64'h1234567887654321 ^ 64'(source * 257),
                     6'(source * 7), 1'(source), 64'hfedcba9801234567 ^ 64'(source * 65537)};
  endfunction
  // Unique full-width data makes wrong source selection observable even when
  // the selected candidate is killed and consequently has no semantic capture.
  generate
    for (genvar source = 0; source < 6; source = source + 1) begin : gen_source
      localparam [TAG_W-1:0] TAG = source_tag(source);
      localparam [R-1:0] RESULT = source_result(source);
      initial begin
        force dut.event_tag_w[source] = TAG;
        force dut.event_result_w[source] = RESULT;
      end
    end
  endgenerate

  integer cand, live, phase, credits, step, source_index, first, second, last;
  integer cases = 0, sparse_second = 0, blocked_second = 0, no_capture = 0;
  reg [5:0] first_mask, second_mask, expected_grant, expected_last, expected_before;
  reg [1:0] expected_fire;
  reg [2*TAG_W-1:0] expected_tags;
  reg [2*R-1:0] expected_results;
  initial begin
    // Reset once, then stop the clock: only the production combinational
    // arbiter is exercised here. Synthetic events never enter transaction state.
    #1; clk = 1;
    #1; clk = 0;
    #1; rst = 0;
    force dut.event_candidate_w = candidate_mask;
    force dut.event_valid_w = live_mask;
    force dut.event_before_q = before_mask;
    force dut.completion_credit_w = credit;
    for (phase = 0; phase < 6; phase = phase + 1)
    for (cand = 0; cand < 64; cand = cand + 1)
    for (live = 0; live < 64; live = live + 1)
    if ((live & ~cand) == 0)
    for (credits = 0; credits < 3; credits = credits + 1) begin
      candidate_mask = 6'(cand);
      live_mask = 6'(live);
      before_mask = 6'((1 << phase) - 1);
      credit = credits == 0 ? 2'b00 : (credits == 1 ? 2'b01 : 2'b11);
      // Independent cyclic scan, not the RTL pairwise-order/count equations.
      first = -1;
      second = -1;
      for (step = 0; step < 6; step = step + 1) begin
        source_index = (phase + step) % 6;
        if ((cand & (1 << source_index)) != 0) begin
          if (first < 0) first = source_index;
          else if (second < 0) second = source_index;
        end
      end
      first_mask = 0;
      second_mask = 0;
      expected_fire = 0;
      expected_tags = 0;
      expected_results = 0;
      if (first >= 0) begin
        first_mask[first] = 1;
        expected_tags[0+:TAG_W] = source_tag(first);
        expected_results[0+:R] = source_result(first);
        if (credits >= 1 && live_mask[first]) expected_fire[0] = 1;
      end
      if (second >= 0) begin
        second_mask[second] = 1;
        expected_tags[TAG_W+:TAG_W] = source_tag(second);
        expected_results[R+:R] = source_result(second);
        if (credits >= 2 && live_mask[second]) expected_fire[1] = 1;
      end
      expected_grant = 0;
      last = -1;
      if (expected_fire[0]) begin
        expected_grant[first] = 1;
        last = first;
      end
      if (expected_fire[1]) begin
        expected_grant[second] = 1;
        last = second;
      end
      expected_last = last < 0 ? 6'b0 : (6'b1 << last);
      expected_before = last < 0 ? before_mask : 6'((1 << ((last + 1) % 6)) - 1);
      #1;
      if (dut.event_first_w !== first_mask || dut.event_second_w !== second_mask ||
          dut.completion_tag_w !== expected_tags || dut.completion_result_w !== expected_results)
        $fatal(1, "candidate route changed phase=%0d candidates=%h live=%h credit=%b first=%h/%h second=%h/%h",
               phase, candidate_mask, live_mask, credit,
               dut.event_first_w, first_mask, dut.event_second_w, second_mask);
      if (dut.completion_fire_w !== expected_fire || dut.event_grant_w !== expected_grant)
        $fatal(1, "rank capture mismatch phase=%0d candidates=%h live=%h credit=%b capture=%b/%b grant=%h/%h",
               phase, candidate_mask, live_mask, credit,
               dut.completion_fire_w, expected_fire, dut.event_grant_w, expected_grant);
      if (dut.event_last_grant_w !== expected_last ||
          (last >= 0 && dut.event_before_next_w !== expected_before))
        $fatal(1, "RR advanced from a noncaptured rank phase=%0d candidates=%h live=%h credit=%b",
               phase, candidate_mask, live_mask, credit);
      if (expected_fire == 2'b10) sparse_second = sparse_second + 1;
      if (credits == 1 && first >= 0 && second >= 0 &&
          !live_mask[first] && live_mask[second]) blocked_second = blocked_second + 1;
      if (expected_fire == 0) no_capture = no_capture + 1;
      cases = cases + 1;
    end
    if (cases != 13122 || sparse_second == 0 || blocked_second == 0 || no_capture == 0)
      $fatal(1, "missing cancellation/rank coverage");
    $display("[PASS] tb_r64_lsu_event_count actual_rtl_exhaustive_cases=%0d sparse_10=%0d dead_first_one_credit=%0d no_capture=%0d",
             cases, sparse_second, blocked_second, no_capture);
    $finish;
  end
endmodule
