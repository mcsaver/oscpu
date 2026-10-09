`timescale 1ns / 1ps
`include "R64Uop.vh"
module tb_r64_completion_fixed_slots;
  localparam R = `R64_RESULT_W;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, flush = 0, probe_flush = 0;
  reg [31:0] kill = 0, probe_kill = 0;
  reg [1:0] fire = 0, consume = 0, probe_consume = 0;
  reg [17:0] tags = 0;
  reg [2*R-1:0] packets = 0;
  wire [1:0] ready, valid, request;
  wire [17:0] output_tag;
  wire [2*R-1:0] output_packet;
  wire [31:0] reuse;
  wire idle;
  R64LsuCompletion dut (
    .clk_i(clk), .rst_i(rst), .flush_i(flush), .kill_mask_i(kill),
    .in_fire_i(fire), .in_ready_o(ready), .in_tag_i(tags), .in_result_i(packets),
    .out_valid_o(valid), .out_request_o(request), .out_ready_i(consume),
    .out_tag_o(output_tag), .out_result_o(output_packet), .reuse_block_o(reuse), .idle_o(idle)
  );
  R64LsuCompletion probe (
    .clk_i(clk), .rst_i(rst), .flush_i(probe_flush), .kill_mask_i(probe_kill),
    .in_fire_i(fire), .in_ready_o(), .in_tag_i(tags), .in_result_i(packets),
    .out_valid_o(), .out_request_o(), .out_ready_i(probe_consume),
    .out_tag_o(), .out_result_o(), .reuse_block_o(), .idle_o()
  );
  // Optional exact frozen previous-round RTL, renamed only at compile time.
  // Default regression uses the independent FIFO scoreboard below.
  reg compare_baseline = 0;
`ifdef R64_CQ_BASELINE_EQ
  wire [1:0] base_ready, base_valid, base_request;
  wire [17:0] base_tag;
  wire [2*R-1:0] base_packet;
  wire [31:0] base_reuse;
  wire base_idle;
  R64LsuCompletionBaseline baseline (
    .clk_i(clk), .rst_i(rst || !compare_baseline), .flush_i(1'b0), .kill_mask_i(32'b0),
    .in_fire_i(compare_baseline ? fire : 2'b0), .in_ready_o(base_ready),
    .in_tag_i(tags), .in_result_i(packets), .out_valid_o(base_valid),
    .out_request_o(base_request), .out_ready_i(consume), .out_tag_o(base_tag),
    .out_result_o(base_packet), .reuse_block_o(base_reuse), .idle_o(base_idle)
  );
`endif
  // Abstract ordered owner queues: deliberately no physical slot/head model.
  integer count[0:1];
  reg [8:0] owner[0:1][0:1];
  reg [R-1:0] payload[0:1][0:1];
  reg turn = 0;
  reg [3:0] generation[0:31];
  reg [31:0] rng = 32'hcb401af7;
  integer cycle = 0, serial = 0, allocated = 0, retired = 0, cancelled = 0;
  integer sparse = 0, no_credit = 0, one_credit = 0, two_credit = 0;
  integer head_kill = 0, tail_kill = 0, pop_capture = 0, kill_capture = 0;
  integer reused = 0, held_tail_kill = 0, prep_checks = 0, baseline_cycles = 0;
  integer reset_checks = 0;
  integer i, j;
  function [31:0] step;
    input [31:0] x;
    reg [31:0] y;
    begin y = x ^ (x << 13); y = y ^ (y >> 17); step = y ^ (y << 5); end
  endfunction
  function [31:0] owners_mask;
    integer a, b;
    begin
      owners_mask = 0;
      for (a = 0; a < 2; a = a + 1)
        for (b = 0; b < count[a]; b = b + 1) owners_mask[owner[a][b][4:0]] = 1;
    end
  endfunction
  task check_outputs;
    integer lane, first;
    reg [1:0] free_lane, credits, expected_valid, expected_request;
    begin
      free_lane = {count[1] < 2, count[0] < 2};
      credits = {&free_lane, |free_lane} & {2{!rst && !flush}};
      first = free_lane[turn] ? turn : !turn;
      expected_valid = 0;
      expected_request = 0;
      for (lane = 0; lane < 2; lane = lane + 1) begin
        expected_valid[lane] = count[lane] != 0 && !rst && !flush && !kill[owner[lane][0][4:0]];
        expected_request[lane] = count[lane] != 0 || fire[first != lane];
        if (expected_valid[lane] &&
            {output_tag[lane*9+:9], output_packet[lane*R+:R]} !== {owner[lane][0], payload[lane][0]})
          $fatal(1, "fixed-slot owner/payload/order mismatch cycle=%0d lane=%0d", cycle, lane);
      end
      if ({ready, valid, request, reuse, idle} !==
          {credits, expected_valid, expected_request, owners_mask(), (count[0] + count[1] == 0)})
        $fatal(1, "fixed-slot control mismatch cycle=%0d ready=%b valid=%b request=%b", cycle, ready, valid, request);
`ifdef R64_CQ_BASELINE_EQ
      if (compare_baseline) begin
        if ({base_ready, base_valid, base_request, base_reuse, base_idle} !==
            {ready, valid, request, reuse, idle})
          $fatal(1, "frozen CQ cycle/control/request mismatch cycle=%0d", cycle);
        for (lane = 0; lane < 2; lane = lane + 1)
          if (valid[lane] && {output_tag[lane*9+:9], output_packet[lane*R+:R]} !==
              {base_tag[lane*9+:9], base_packet[lane*R+:R]})
            $fatal(1, "frozen CQ owner/payload/timing mismatch cycle=%0d lane=%0d", cycle, lane);
        baseline_cycles = baseline_cycles + 1;
      end
`endif
    end
  endtask
`define CQ_PREP(D,G) {D.gen_lane[G].input_lane, D.gen_lane[G].target_slot, \
 D.gen_lane[G].gen_slot[0].payload_write, D.gen_lane[G].gen_slot[1].payload_write, \
 D.gen_lane[G].input_tag, D.gen_lane[G].input_result}
  task check_preparation;
    begin
      // The revised noninterference property holds at rst=0 only.
      if (rst) $fatal(1, "cancellation noninterference tested outside rst=0 boundary");
      // Both instances have identical registered state. Change only current
      // cancellation and WB acceptance between edges, then restore before edge.
      probe_flush = !flush;
      probe_kill = ~kill;
      probe_consume = ~consume;
      #1;
      if (dut.first_w !== probe.first_w || `CQ_PREP(dut,0) !== `CQ_PREP(probe,0) ||
          `CQ_PREP(dut,1) !== `CQ_PREP(probe,1))
        $fatal(1, "cancel/pop reached fixed-slot payload preparation cycle=%0d", cycle);
      prep_checks = prep_checks + 1;
      probe_flush = flush;
      probe_kill = kill;
      probe_consume = consume;
      #1;
    end
  endtask
`undef CQ_PREP
  task model_edge;
    integer lane, first, n, old_count, rank, idx;
    reg [1:0] free_lane;
    begin
      free_lane = {count[1] < 2, count[0] < 2};
      first = free_lane[turn] ? turn : !turn;
      if (fire == 2) sparse = sparse + 1;
      case (ready)
        0: no_credit = no_credit + 1;
        1: one_credit = one_credit + 1;
        3: two_credit = two_credit + 1;
      endcase
      for (lane = 0; lane < 2; lane = lane + 1) begin
        rank = first != lane;
        old_count = count[lane];
        if (old_count && kill[owner[lane][0][4:0]]) head_kill = head_kill + 1;
        if (old_count == 2 && kill[owner[lane][1][4:0]]) begin
          tail_kill = tail_kill + 1;
          if (!consume[lane] && !kill[owner[lane][0][4:0]]) held_tail_kill = held_tail_kill + 1;
        end
        if (fire[rank] && old_count && consume[lane] && !kill[owner[lane][0][4:0]])
          pop_capture = pop_capture + 1;
        if (fire[rank] && old_count && kill[owner[lane][0][4:0]]) kill_capture = kill_capture + 1;
        n = 0;
        for (idx = 0; idx < old_count; idx = idx + 1) begin
          if (flush || kill[owner[lane][idx][4:0]]) cancelled = cancelled + 1;
          else if (idx == 0 && consume[lane]) retired = retired + 1;
          else begin
            owner[lane][n] = owner[lane][idx];
            payload[lane][n] = payload[lane][idx];
            n = n + 1;
          end
        end
        if (fire[rank]) begin
          owner[lane][n] = tags[rank*9+:9];
          payload[lane][n] = packets[rank*R+:R];
          n = n + 1;
          allocated = allocated + 1;
        end
        count[lane] = n;
      end
      if (fire[0]) turn = !first;
      else if (fire[1]) turn = first;
      if (allocated != retired + cancelled + count[0] + count[1])
        $fatal(1, "owner conservation mismatch");
    end
  endtask
  task tick;
    input [1:0] wanted, pop;
    input [31:0] killed;
    input do_flush;
    integer rank, slot, scan;
    reg [31:0] unavailable;
    begin
      fire = 0;
      consume = pop;
      kill = killed;
      flush = do_flush;
      probe_consume = consume;
      probe_kill = kill;
      probe_flush = flush;
      rng = step(rng);
      tags = rng[17:0];
      for (scan = 0; scan < 2; scan = scan + 1) begin
        rng = step(rng);
        packets[scan*R+:R] = {12'hace, rng, ~rng, serial[31:0], (rng ^ serial)};
      end
      #1;
      unavailable = owners_mask() | kill;
      for (rank = 0; rank < 2; rank = rank + 1)
        if (wanted[rank] && ready[rank]) begin
          slot = -1;
          for (scan = 0; scan < 32; scan = scan + 1)
            if (slot < 0 && !unavailable[scan]) slot = scan;
          if (slot >= 0) begin
            tags[rank*9+:9] = {generation[slot], slot[4:0]};
            generation[slot] = generation[slot] + 1'b1;
            if (serial > 32) reused = reused + 1;
            unavailable[slot] = 1;
            serial = serial + 1;
            fire[rank] = 1;
          end
        end
      #1;
      check_outputs();
      check_preparation();
      @(posedge clk);
      model_edge();
      @(negedge clk);
      cycle = cycle + 1;
    end
  endtask
  task reset_boundary;
    integer slot, beat;
    reg [8:0] saved_tag[0:3];
    reg [R-1:0] saved_data[0:3];
    begin
      // Capture live owners, then prewrite the other two slots without capture.
      tick(3, 0, 0, 0);
      tick(0, 0, 0, 0);
      for (slot = 0; slot < 4; slot = slot + 1) begin
        saved_tag[slot] = dut.slot_tag_q[slot];
        saved_data[slot] = dut.slot_result_q[slot];
      end
      rst = 1;
      fire = 0;
      consume = 0;
      probe_consume = 0;
      cancelled = cancelled + count[0] + count[1];
      count[0] = 0; count[1] = 0; turn = 0;
      for (beat = 0; beat < 3; beat = beat + 1) begin
        tags = ~tags;
        packets = ~packets;
        #1;
        if ({dut.gen_lane[0].gen_slot[0].payload_write,
             dut.gen_lane[0].gen_slot[1].payload_write,
             dut.gen_lane[1].gen_slot[0].payload_write,
             dut.gen_lane[1].gen_slot[1].payload_write} !== 4'b0 || ready != 0 || valid != 0)
          $fatal(1, "reset permits payload prewrite or completion");
        @(posedge clk);
        @(negedge clk);
        if (!idle || reuse != 0 || request != 0 || dut.turn_q != 0)
          $fatal(1, "reset retained owner, hint, reuse or arbitration state");
        for (slot = 0; slot < 4; slot = slot + 1)
          if ({dut.slot_tag_q[slot], dut.slot_result_q[slot]} !== {saved_tag[slot], saved_data[slot]})
            $fatal(1, "reset changed stored payload without prewrite permission");
        reset_checks = reset_checks + 1;
      end
      rst = 0;
      // New payload can be prepared after reset; it must never revive an owner.
      tick(0, 0, 0, 0); tick(0, 0, 0, 0);
      if (!idle || valid || reuse || request) $fatal(1, "pre-reset/prewrite owner revived");
      // Only this new real capture establishes owner with its current payload.
      tick(2, 0, 0, 0); tick(0, 3, 0, 0); tick(0, 3, 0, 0);
    end
  endtask
  reg [1:0] wanted;
  reg [31:0] killed;
  initial begin
    count[0] = 0; count[1] = 0;
    for (i = 0; i < 32; i = i + 1) generation[i] = 0;
    compare_baseline = 1;
    repeat (3) @(negedge clk);
    rst = 0;
    // Exact previous-round baseline comparison: no kill, original prefix fire.
    for (i = 0; i < 6000; i = i + 1) begin
      rng = step(rng);
      wanted = rng[1:0] == 2 ? 1 : rng[1:0];
      tick(wanted, (i % 113 < 12) ? 0 : rng[3:2], 0, 0);
    end
    tick(0, 3, 0, 0); tick(0, 3, 0, 0); tick(0, 3, 0, 0);
    compare_baseline = 0;
    reset_boundary();
    // Explicit sparse rank, no-credit, head/back kill and replacement cases.
    tick(2, 0, 0, 0); tick(3, 0, 0, 0); tick(3, 0, 0, 0);
    if (ready != 0) $fatal(1, "directed case did not fill all four slots");
    killed = (32'b1 << owner[0][1][4:0]) | (32'b1 << owner[1][0][4:0]);
    tick(3, 0, killed, 0);
    tick(3, 0, 0, 0);
    tick(0, 3, 0, 0);
    tick(3, 3, 0, 0);
    killed = (32'b1 << owner[0][0][4:0]) | (32'b1 << owner[1][0][4:0]);
    tick(2, 0, killed, 0);
    tick(0, 0, 0, 1);
    // Deterministic randomized cancellation, independent stall and sparse fire.
    for (i = 0; i < 24000; i = i + 1) begin
      rng = step(rng);
      killed = rng[6:3] == 0 ? (32'b1 << rng[11:7]) : 0;
      if (i % 19 == 5 && count[0]) killed = killed | (32'b1 << owner[0][0][4:0]);
      if (i % 29 == 7 && count[1] == 2) killed = killed | (32'b1 << owner[1][1][4:0]);
      wanted = rng[1:0];
      tick(wanted, (i % 131 < 15) ? 0 : rng[15:14], killed, i % 277 == 276);
    end
    tick(0, 3, 0, 0); tick(0, 3, 0, 0); tick(0, 3, 0, 0);
    fire = 0;
    if (!idle || allocated != retired + cancelled || sparse < 1000 || no_credit < 100 ||
        one_credit < 100 || two_credit < 100 || head_kill < 20 || tail_kill < 20 ||
        pop_capture < 100 || kill_capture < 10 || held_tail_kill < 10 || reused < 1000 || reset_checks != 3)
      $fatal(1, "fixed-slot coverage missing allocated=%0d sparse=%0d credits=%0d/%0d/%0d headkill=%0d tailkill=%0d popcap=%0d killcap=%0d heldtailkill=%0d reused=%0d",
        allocated, sparse, no_credit, one_credit, two_credit, head_kill, tail_kill, pop_capture, kill_capture, held_tail_kill, reused);
    $display("[PASS] tb_r64_completion_fixed_slots cycles=%0d allocated=%0d retired=%0d cancelled=%0d sparse10=%0d credits0/1/2=%0d/%0d/%0d headkill=%0d tailkill=%0d pop_capture=%0d kill_capture=%0d held_tail_kill=%0d reused=%0d preparation_checks=%0d baseline_cycles=%0d reset_checks=%0d",
      cycle, allocated, retired, cancelled, sparse, no_credit, one_credit, two_credit,
      head_kill, tail_kill, pop_capture, kill_capture, held_tail_kill, reused, prep_checks, baseline_cycles, reset_checks);
    $finish;
  end
  initial begin #500000; $fatal(1, "timeout"); end
endmodule
