// Lossless terminal-event collector for exact memory-owner accounting.
//
// The collector does not authorize architectural or cache side effects.  It
// only retains exact {kind, token, epoch} terminal events until one of two
// registered dequeue ports consumes them.  fault_tval is provenance payload,
// not owner identity, so it is deliberately absent from this module.
module OooMemOwnerTerminalCollector #(
  parameter integer INGRESS_N = 6
) (
  input clk,
  input rst,

  input [INGRESS_N-1:0] ingress_valid_i,
  input [(INGRESS_N*2)-1:0] ingress_kind_i,
  input [(INGRESS_N*5)-1:0] ingress_token_i,
  input [(INGRESS_N*2)-1:0] ingress_epoch_i,

  // These three inputs are the edge-old truth from OooMemOwnerTracker.  A
  // terminal event is retained only when all nine identity bits match.
  input [31:0] live_mask_i,
  input [63:0] live_kind_table_i,
  input [63:0] live_epoch_table_i,

  // Combinational acceptance after exact live/tuple/duplicate/pending and
  // same-edge dequeue checks.  A caller may use this only as proof that the
  // corresponding holder has handed ownership to this collector on the
  // current edge; raw ingress_valid_i is not transfer authority.
  output [INGRESS_N-1:0] ingress_accept_o,

  output deq0_valid_o,
  output [1:0] deq0_kind_o,
  output [4:0] deq0_token_o,
  output [1:0] deq0_epoch_o,
  input deq0_ready_i,

  output deq1_valid_o,
  output [1:0] deq1_kind_o,
  output [4:0] deq1_token_o,
  output [1:0] deq1_epoch_o,
  input deq1_ready_i,

  // Includes queued and output-resident events.  Therefore every outstanding
  // terminal has exactly one token bit until its dequeue fire edge.
  output [31:0] pending_mask_o,
  output [5:0] pending_count_o
);

  localparam [1:0] OWNER_KIND_RESERVED = 2'b11;
  localparam PARAM_SHAPE_VALID = (INGRESS_N >= 6);

  reg [31:0] pending_q;
  reg [1:0] kind_q [0:31];
  reg [1:0] epoch_q [0:31];

  reg out0_valid_q;
  reg [1:0] out0_kind_q;
  reg [4:0] out0_token_q;
  reg [1:0] out0_epoch_q;
  reg out1_valid_q;
  reg [1:0] out1_kind_q;
  reg [4:0] out1_token_q;
  reg [1:0] out1_epoch_q;

  reg [INGRESS_N-1:0] ingress_reserved_violation_r;
  reg [INGRESS_N-1:0] ingress_nonlive_violation_r;
  reg [INGRESS_N-1:0] ingress_tuple_violation_r;
  reg [INGRESS_N-1:0] ingress_duplicate_violation_r;
  reg [INGRESS_N-1:0] ingress_pending_violation_r;
  reg [INGRESS_N-1:0] ingress_same_edge_violation_r;
  reg [INGRESS_N-1:0] ingress_accept_r;
  reg [31:0] pending_next_r;

  reg [31:0] refill_pool_r;
  reg refill0_found_r;
  reg [4:0] refill0_token_r;
  reg refill1_found_r;
  reg [4:0] refill1_token_r;

  integer ingress_i;
  integer duplicate_i;
  integer enqueue_i;
  integer state_i;
  integer select_i;

  wire deq0_fire_w = out0_valid_q && deq0_ready_i;
  wire deq1_fire_w = out1_valid_q && deq1_ready_i;
  wire [31:0] deq0_fire_mask_w = deq0_fire_w ?
      (32'b1 << out0_token_q) : 32'b0;
  wire [31:0] deq1_fire_mask_w = deq1_fire_w ?
      (32'b1 << out1_token_q) : 32'b0;
  wire [31:0] dequeue_fire_mask_w =
      deq0_fire_mask_w | deq1_fire_mask_w;
  wire [31:0] out0_hold_mask_w =
      (out0_valid_q && !deq0_ready_i) ?
      (32'b1 << out0_token_q) : 32'b0;
  wire [31:0] out1_hold_mask_w =
      (out1_valid_q && !deq1_ready_i) ?
      (32'b1 << out1_token_q) : 32'b0;

  function [1:0] ingress_kind_at;
    input [(INGRESS_N*2)-1:0] bus;
    input integer lane;
    begin
      ingress_kind_at = bus[(lane*2) +: 2];
    end
  endfunction

  function [4:0] ingress_token_at;
    input [(INGRESS_N*5)-1:0] bus;
    input integer lane;
    begin
      ingress_token_at = bus[(lane*5) +: 5];
    end
  endfunction

  function [1:0] ingress_epoch_at;
    input [(INGRESS_N*2)-1:0] bus;
    input integer lane;
    begin
      ingress_epoch_at = bus[(lane*2) +: 2];
    end
  endfunction

  function [1:0] owner_table_at;
    input [63:0] table_bits;
    input [4:0] token;
    begin
      owner_table_at = table_bits[(token*2) +: 2];
    end
  endfunction

  function [5:0] popcount_pending;
    input [31:0] bits;
    integer pop_i;
    begin
      popcount_pending = 6'd0;
      // Synthesis: 32 one-bit addends form the pending observability tree.
      for (pop_i = 0; pop_i < 32; pop_i = pop_i + 1)
        popcount_pending = popcount_pending + {5'b0, bits[pop_i]};
    end
  endfunction

  function [5:0] popcount_ingress;
    input [INGRESS_N-1:0] bits;
    integer pop_i;
    begin
      popcount_ingress = 6'd0;
      // Synthesis: INGRESS_N one-bit addends are assertion/accounting only.
      for (pop_i = 0; pop_i < INGRESS_N; pop_i = pop_i + 1)
        popcount_ingress = popcount_ingress + {5'b0, bits[pop_i]};
    end
  endfunction

  // Each outer lane expands into an exact tracker-table lookup and a complete
  // INGRESS_N-way duplicate comparator row.  Both lanes of an intra-batch
  // duplicate are rejected, while unrelated exact lanes remain admissible.
  always @(*) begin
    ingress_reserved_violation_r = {INGRESS_N{1'b0}};
    ingress_nonlive_violation_r = {INGRESS_N{1'b0}};
    ingress_tuple_violation_r = {INGRESS_N{1'b0}};
    ingress_duplicate_violation_r = {INGRESS_N{1'b0}};
    ingress_pending_violation_r = {INGRESS_N{1'b0}};
    ingress_same_edge_violation_r = {INGRESS_N{1'b0}};
    ingress_accept_r = {INGRESS_N{1'b0}};

    // Synthesis: INGRESS_N parallel validation lanes.
    for (ingress_i = 0; ingress_i < INGRESS_N;
         ingress_i = ingress_i + 1) begin
      if (ingress_valid_i[ingress_i]) begin
        ingress_reserved_violation_r[ingress_i] =
            (ingress_kind_at(ingress_kind_i, ingress_i) ==
             OWNER_KIND_RESERVED);
        ingress_nonlive_violation_r[ingress_i] =
            !live_mask_i[ingress_token_at(ingress_token_i, ingress_i)];
        ingress_tuple_violation_r[ingress_i] =
            live_mask_i[ingress_token_at(ingress_token_i, ingress_i)] &&
            ((owner_table_at(
                live_kind_table_i,
                ingress_token_at(ingress_token_i, ingress_i)) !=
              ingress_kind_at(ingress_kind_i, ingress_i)) ||
             (owner_table_at(
                live_epoch_table_i,
                ingress_token_at(ingress_token_i, ingress_i)) !=
              ingress_epoch_at(ingress_epoch_i, ingress_i)));
        ingress_pending_violation_r[ingress_i] =
            pending_q[ingress_token_at(ingress_token_i, ingress_i)];
        ingress_same_edge_violation_r[ingress_i] =
            dequeue_fire_mask_w[
                ingress_token_at(ingress_token_i, ingress_i)];

        // Synthesis: one token-equality comparator against every other lane.
        for (duplicate_i = 0; duplicate_i < INGRESS_N;
             duplicate_i = duplicate_i + 1) begin
          if ((duplicate_i != ingress_i) &&
              ingress_valid_i[duplicate_i] &&
              (ingress_token_at(ingress_token_i, duplicate_i) ==
               ingress_token_at(ingress_token_i, ingress_i))) begin
            ingress_duplicate_violation_r[ingress_i] = 1'b1;
          end
        end

        ingress_accept_r[ingress_i] = PARAM_SHAPE_VALID &&
            !ingress_reserved_violation_r[ingress_i] &&
            !ingress_nonlive_violation_r[ingress_i] &&
            !ingress_tuple_violation_r[ingress_i] &&
            !ingress_duplicate_violation_r[ingress_i] &&
            !ingress_pending_violation_r[ingress_i] &&
            !ingress_same_edge_violation_r[ingress_i];
      end
    end
  end

  // The dequeue fire is applied to edge-old state before accepted ingress is
  // inserted.  Because validation also sees edge-old pending_q, a token being
  // dequeued cannot be re-enqueued on this same edge.
  always @(*) begin
    pending_next_r = pending_q & ~dequeue_fire_mask_w;
    // Synthesis: INGRESS_N token decoders OR into the 32 write enables.
    for (enqueue_i = 0; enqueue_i < INGRESS_N;
         enqueue_i = enqueue_i + 1) begin
      if (ingress_accept_r[enqueue_i]) begin
        pending_next_r[
            ingress_token_at(ingress_token_i, enqueue_i)] = 1'b1;
      end
    end
  end

  // Two explicit priority encoders refill only free/firing registered slots.
  // Stalled slots are removed from the pool, and lane1 removes lane0's grant.
  always @(*) begin
    refill_pool_r = pending_q & ~dequeue_fire_mask_w &
        ~out0_hold_mask_w & ~out1_hold_mask_w;
    refill0_found_r = 1'b0;
    refill0_token_r = 5'd0;
    if (!out0_valid_q || deq0_ready_i) begin
      // Synthesis: first 32-way priority encoder, low token wins.
      for (select_i = 0; select_i < 32; select_i = select_i + 1) begin
        if (!refill0_found_r && refill_pool_r[select_i]) begin
          refill0_found_r = 1'b1;
          refill0_token_r = select_i[4:0];
        end
      end
    end
    if (refill0_found_r)
      refill_pool_r[refill0_token_r] = 1'b0;

    refill1_found_r = 1'b0;
    refill1_token_r = 5'd0;
    if (!out1_valid_q || deq1_ready_i) begin
      // Synthesis: second 32-way priority encoder after lane0 exclusion.
      for (select_i = 0; select_i < 32; select_i = select_i + 1) begin
        if (!refill1_found_r && refill_pool_r[select_i]) begin
          refill1_found_r = 1'b1;
          refill1_token_r = select_i[4:0];
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      pending_q <= 32'b0;
      out0_valid_q <= 1'b0;
      out0_kind_q <= 2'b00;
      out0_token_q <= 5'd0;
      out0_epoch_q <= 2'b00;
      out1_valid_q <= 1'b0;
      out1_kind_q <= 2'b00;
      out1_token_q <= 5'd0;
      out1_epoch_q <= 2'b00;
      // Synthesis: 32 parallel metadata registers, reset for determinism.
      for (state_i = 0; state_i < 32; state_i = state_i + 1) begin
        kind_q[state_i] <= 2'b00;
        epoch_q[state_i] <= 2'b00;
      end
    end else begin
      pending_q <= pending_next_r;

      // Synthesis: INGRESS_N decoded writes into the per-token metadata bank.
      for (state_i = 0; state_i < INGRESS_N; state_i = state_i + 1) begin
        if (ingress_accept_r[state_i]) begin
          kind_q[ingress_token_at(ingress_token_i, state_i)] <=
              ingress_kind_at(ingress_kind_i, state_i);
          epoch_q[ingress_token_at(ingress_token_i, state_i)] <=
              ingress_epoch_at(ingress_epoch_i, state_i);
        end
      end

      if (!out0_valid_q || deq0_ready_i) begin
        if (refill0_found_r) begin
          out0_valid_q <= 1'b1;
          out0_kind_q <= kind_q[refill0_token_r];
          out0_token_q <= refill0_token_r;
          out0_epoch_q <= epoch_q[refill0_token_r];
        end else begin
          out0_valid_q <= 1'b0;
          out0_kind_q <= 2'b00;
          out0_token_q <= 5'd0;
          out0_epoch_q <= 2'b00;
        end
      end

      if (!out1_valid_q || deq1_ready_i) begin
        if (refill1_found_r) begin
          out1_valid_q <= 1'b1;
          out1_kind_q <= kind_q[refill1_token_r];
          out1_token_q <= refill1_token_r;
          out1_epoch_q <= epoch_q[refill1_token_r];
        end else begin
          out1_valid_q <= 1'b0;
          out1_kind_q <= 2'b00;
          out1_token_q <= 5'd0;
          out1_epoch_q <= 2'b00;
        end
      end
    end
  end

  assign ingress_accept_o = ingress_accept_r;
  assign deq0_valid_o = out0_valid_q;
  assign deq0_kind_o = out0_kind_q;
  assign deq0_token_o = out0_token_q;
  assign deq0_epoch_o = out0_epoch_q;
  assign deq1_valid_o = out1_valid_q;
  assign deq1_kind_o = out1_kind_q;
  assign deq1_token_o = out1_token_q;
  assign deq1_epoch_o = out1_epoch_q;
  assign pending_mask_o = pending_q;
  assign pending_count_o = popcount_pending(pending_q);

`ifdef OOO_ASSERT
  initial begin
    if (!PARAM_SHAPE_VALID) begin
      $display("[S2-G1-TCOLL-PARAM] INGRESS_N must be at least six");
      $fatal;
    end
  end

  reg conservation_check_q;
  reg [5:0] conservation_expected_q;
  reg out0_hold_check_q;
  reg [8:0] out0_hold_tuple_q;
  reg out1_hold_check_q;
  reg [8:0] out1_hold_tuple_q;
  integer ingress_assert_i;

  always @(posedge clk) begin
    if (rst) begin
      conservation_check_q <= 1'b0;
      conservation_expected_q <= 6'd0;
      out0_hold_check_q <= 1'b0;
      out0_hold_tuple_q <= 9'd0;
      out1_hold_check_q <= 1'b0;
      out1_hold_tuple_q <= 9'd0;
    end else begin
      if (out0_valid_q && (^out0_token_q === 1'bx)) begin
        $display("[V8L-TCOLL-OUT0-TOKEN-KNOWN] valid output0 has unknown token");
        $fatal;
      end
      if (out1_valid_q && (^out1_token_q === 1'bx)) begin
        $display("[V8L-TCOLL-OUT1-TOKEN-KNOWN] valid output1 has unknown token");
        $fatal;
      end
      if (|ingress_reserved_violation_r) begin
        $display("[S2-G1-TCOLL-RESERVED] reserved owner kind ingress");
        $fatal;
      end else if (|ingress_nonlive_violation_r) begin
        $display("[S2-G1-TCOLL-NONLIVE] ingress token was not edge-old live");
        $fatal;
      end else if (|ingress_tuple_violation_r) begin
        $display("[S2-G1-TCOLL-TUPLE-MISMATCH] ingress kind/epoch mismatched tracker truth");
        $fatal;
      end else if (|ingress_duplicate_violation_r) begin
        $display("[S2-G1-TCOLL-INGRESS-DUP] same token arrived on multiple ingress lanes valid=%b duplicate=%b pending=%h live=%h",
                 ingress_valid_i, ingress_duplicate_violation_r,
                 pending_q, live_mask_i);
        for (ingress_assert_i = 0; ingress_assert_i < INGRESS_N;
             ingress_assert_i = ingress_assert_i + 1) begin
          if (ingress_valid_i[ingress_assert_i]) begin
            $display("[S2-G1-TCOLL-INGRESS] lane=%0d kind=%b token=%0d epoch=%b duplicate=%b pending=%b live=%b",
                     ingress_assert_i,
                     ingress_kind_at(ingress_kind_i, ingress_assert_i),
                     ingress_token_at(ingress_token_i, ingress_assert_i),
                     ingress_epoch_at(ingress_epoch_i, ingress_assert_i),
                     ingress_duplicate_violation_r[ingress_assert_i],
                     pending_q[
                         ingress_token_at(ingress_token_i,
                                          ingress_assert_i)],
                     live_mask_i[
                         ingress_token_at(ingress_token_i,
                                          ingress_assert_i)]);
          end
        end
        $fatal;
      end else if (|ingress_same_edge_violation_r) begin
        $display("[S2-G1-TCOLL-SAME-EDGE-REENQUEUE] dequeue token was re-enqueued on one edge");
        $fatal;
      end else if (|ingress_pending_violation_r) begin
        $display("[S2-G1-TCOLL-PENDING-DUP] ingress token was already pending");
        $fatal;
      end

      if (conservation_check_q &&
          (pending_count_o !== conservation_expected_q)) begin
        $display("[S2-G1-TCOLL-CONSERVATION] count=%0d expected=%0d",
                 pending_count_o, conservation_expected_q);
        $fatal;
      end
      conservation_check_q <= 1'b1;
      conservation_expected_q <= pending_count_o +
          popcount_ingress(ingress_accept_r) - deq0_fire_w - deq1_fire_w;

      if (out0_valid_q &&
          (!pending_q[out0_token_q] ||
           (out0_kind_q != kind_q[out0_token_q]) ||
           (out0_epoch_q != epoch_q[out0_token_q]))) begin
        $display("[S2-G1-TCOLL-OUT0-OWNER] output0 did not name exact pending metadata");
        $fatal;
      end
      if (out1_valid_q &&
          (!pending_q[out1_token_q] ||
           (out1_kind_q != kind_q[out1_token_q]) ||
           (out1_epoch_q != epoch_q[out1_token_q]))) begin
        $display("[S2-G1-TCOLL-OUT1-OWNER] output1 did not name exact pending metadata");
        $fatal;
      end
      if (out0_valid_q && out1_valid_q &&
          (out0_token_q == out1_token_q)) begin
        $display("[S2-G1-TCOLL-OUT-DUP] both dequeue ports named one token");
        $fatal;
      end

      if (out0_hold_check_q &&
          ({out0_valid_q, out0_kind_q, out0_token_q, out0_epoch_q} !==
           {1'b1, out0_hold_tuple_q})) begin
        $display("[S2-G1-TCOLL-OUT0-HOLD] stalled output0 tuple changed");
        $fatal;
      end
      if (out1_hold_check_q &&
          ({out1_valid_q, out1_kind_q, out1_token_q, out1_epoch_q} !==
           {1'b1, out1_hold_tuple_q})) begin
        $display("[S2-G1-TCOLL-OUT1-HOLD] stalled output1 tuple changed");
        $fatal;
      end
      out0_hold_check_q <= out0_valid_q && !deq0_ready_i;
      out0_hold_tuple_q <= {out0_kind_q, out0_token_q, out0_epoch_q};
      out1_hold_check_q <= out1_valid_q && !deq1_ready_i;
      out1_hold_tuple_q <= {out1_kind_q, out1_token_q, out1_epoch_q};
    end
  end
`endif

endmodule
