// Exact memory-owner token allocator.
//
// A token is allocated once, at backend memory-reservation capture.  The
// tracker retains kind+epoch metadata until the exact terminal event frees the
// token.  Allocation scans the pre-edge live bitmap: a token released on this
// edge cannot be reused on the same edge, which closes the shortest ABA window.
module OooMemOwnerTracker #(
  parameter TOKEN_COUNT = 32,
  parameter TOKEN_W = 5,
  parameter KIND_W = 2,
  parameter EPOCH_W = 2,
  parameter COUNT_W = 6,
  parameter PRODUCER_ID_W = 8,
  parameter PRODUCER_COUNT = (1 << PRODUCER_ID_W),
  parameter [KIND_W-1:0] OWNER_KIND_STORE = 2'b01,
  parameter [KIND_W-1:0] OWNER_KIND_RESERVED = 2'b11
) (
  input clk,
  input rst,

  input alloc0_valid_i,
  input [KIND_W-1:0] alloc0_kind_i,
  input [EPOCH_W-1:0] alloc0_epoch_i,
  input [PRODUCER_ID_W-1:0] alloc0_producer_id_i,
  output alloc0_ready_o,
  output [TOKEN_W-1:0] alloc0_token_o,

  input alloc1_valid_i,
  input [KIND_W-1:0] alloc1_kind_i,
  input [EPOCH_W-1:0] alloc1_epoch_i,
  input [PRODUCER_ID_W-1:0] alloc1_producer_id_i,
  output alloc1_ready_o,
  output [TOKEN_W-1:0] alloc1_token_o,

  // When asserted, alloc0/alloc1 are one atomic issue package.  The two ready
  // signals remain independently computed from edge-old state, but neither
  // birth commits unless both lanes are valid and ready.  Standalone alloc0
  // keeps the legacy behavior; standalone alloc1 is illegal in atomic mode.
  input alloc_pair_atomic_i,

  input free0_valid_i,
  input [KIND_W-1:0] free0_kind_i,
  input [TOKEN_W-1:0] free0_token_i,
  input [EPOCH_W-1:0] free0_epoch_i,
  output free0_ready_o,

  input free1_valid_i,
  input [KIND_W-1:0] free1_kind_i,
  input [TOKEN_W-1:0] free1_token_i,
  input [EPOCH_W-1:0] free1_epoch_i,
  output free1_ready_o,

  // Bulk release is deliberately restricted to STORE owners.  It exists for
  // SQ squash/precise-release masks; LOAD/ATOMIC and bridge drain terminals
  // must use the exact tagged free ports above.
  input [TOKEN_COUNT-1:0] release_mask_i,

  output [TOKEN_COUNT-1:0] live_mask_o,
  // Edge-old metadata query tables.  Consumers must qualify an indexed value
  // with live_mask_o[token]; these views are observational only and never
  // authorize allocation or release by themselves.
  output [TOKEN_COUNT*KIND_W-1:0] kind_table_o,
  output [TOKEN_COUNT*EPOCH_W-1:0] epoch_table_o,
  output [TOKEN_COUNT*PRODUCER_ID_W-1:0] producer_id_table_o,
  // Registered memory-owner lease set.  Dispatch may index this Q-only mask;
  // it must never reconstruct the set from holder CAMs.
  output [PRODUCER_COUNT-1:0] producer_live_mask_o,
  output [COUNT_W-1:0] live_count_o
);

  localparam integer PARAM_SHAPE_VALID =
      (TOKEN_COUNT == (1 << TOKEN_W)) && ((1 << COUNT_W) > TOKEN_COUNT) &&
      (PRODUCER_COUNT == (1 << PRODUCER_ID_W));

  reg [TOKEN_COUNT-1:0] live_q;
  reg [KIND_W-1:0] kind_q [0:TOKEN_COUNT-1];
  reg [EPOCH_W-1:0] epoch_q [0:TOKEN_COUNT-1];
  reg [PRODUCER_ID_W-1:0] producer_id_q [0:TOKEN_COUNT-1];
  reg [PRODUCER_COUNT-1:0] producer_live_q;
  reg [TOKEN_W-1:0] next_token_q;

  reg alloc0_found_r;
  reg [TOKEN_W-1:0] alloc0_token_r;
  reg alloc1_found_r;
  reg [TOKEN_W-1:0] alloc1_token_r;
  reg [TOKEN_COUNT-1:0] store_live_mask_r;
  reg [TOKEN_COUNT-1:0] death_mask_r;
  reg [TOKEN_COUNT-1:0] birth_mask_r;
  reg [TOKEN_COUNT-1:0] live_next_r;
  reg [PRODUCER_COUNT-1:0] producer_clear_mask_r;
  reg [PRODUCER_COUNT-1:0] producer_set_mask_r;
  reg [PRODUCER_COUNT-1:0] producer_live_next_r;
  reg [COUNT_W-1:0] live_count_r;
  integer scan0_i;
  integer scan1_i;
  integer count_i;
  integer event_i;

  wire alloc_pair_present_w = alloc_pair_atomic_i &&
      alloc0_valid_i && alloc1_valid_i;
  wire alloc_pair_commit_w = alloc_pair_present_w &&
      alloc0_ready_o && alloc1_ready_o;
  wire alloc0_fire_w = alloc_pair_present_w ? alloc_pair_commit_w :
      (alloc0_valid_i && alloc0_ready_o &&
       !(alloc_pair_atomic_i && alloc1_valid_i));
  wire alloc1_fire_w = alloc_pair_present_w ? alloc_pair_commit_w :
      (!alloc_pair_atomic_i && alloc1_valid_i && alloc1_ready_o);
  wire [TOKEN_COUNT-1:0] release_effective_w =
      release_mask_i & store_live_mask_r;
  wire free0_exact_w = live_q[free0_token_i] &&
      (kind_q[free0_token_i] == free0_kind_i) &&
      (epoch_q[free0_token_i] == free0_epoch_i);
  wire free0_fire_w = free0_valid_i && free0_ready_o;
  wire free1_exact_w = live_q[free1_token_i] &&
      (kind_q[free1_token_i] == free1_kind_i) &&
      (epoch_q[free1_token_i] == free1_epoch_i);
  wire free1_same_as_free0_w = free0_fire_w &&
      (free1_token_i == free0_token_i);
  wire free1_fire_w = free1_valid_i && free1_ready_o;
  wire alloc0_pid_clear_w =
      !producer_live_q[alloc0_producer_id_i];
  // This claim is deliberately independent of alloc1.  The lane1 token scan
  // may exclude lane0 without feeding lane1 ready back into lane0's encoder.
  wire alloc0_claim_w = alloc0_valid_i && PARAM_SHAPE_VALID &&
      alloc0_found_r && (alloc0_kind_i != OWNER_KIND_RESERVED) &&
      alloc0_pid_clear_w;
  wire alloc1_pid_clear_w =
      !producer_live_q[alloc1_producer_id_i];

  function [TOKEN_W-1:0] token_at_offset;
    input [TOKEN_W-1:0] base;
    input integer offset;
    begin
      token_at_offset = base + offset[TOKEN_W-1:0];
    end
  endfunction

  function [COUNT_W-1:0] popcount_live;
    input [TOKEN_COUNT-1:0] bits;
    integer pop_i;
    begin
      popcount_live = {COUNT_W{1'b0}};
      for (pop_i = 0; pop_i < TOKEN_COUNT; pop_i = pop_i + 1)
        popcount_live = popcount_live + bits[pop_i];
    end
  endfunction

  // Keep the two priority encoders in separate combinational processes.  The
  // lane1 scan intentionally reads lane0's claim/token, while lane0 never
  // reads lane1; one monolithic process obscures that DAG and is diagnosed as
  // a false combinational cycle by Verilator after canonical dual-bank wiring.
  always @(*) begin
    alloc0_found_r = 1'b0;
    alloc0_token_r = next_token_q;
    for (scan0_i = 0; scan0_i < TOKEN_COUNT; scan0_i = scan0_i + 1) begin
      if (!alloc0_found_r &&
          !live_q[token_at_offset(next_token_q, scan0_i)]) begin
        alloc0_found_r = 1'b1;
        alloc0_token_r = token_at_offset(next_token_q, scan0_i);
      end
    end
  end

  always @(*) begin
    alloc1_found_r = 1'b0;
    alloc1_token_r = next_token_q;
    for (scan1_i = 0; scan1_i < TOKEN_COUNT; scan1_i = scan1_i + 1) begin
      if (!alloc1_found_r &&
          !live_q[token_at_offset(next_token_q, scan1_i)] &&
          !(alloc0_claim_w &&
            (token_at_offset(next_token_q, scan1_i) == alloc0_token_r))) begin
        alloc1_found_r = 1'b1;
        alloc1_token_r = token_at_offset(next_token_q, scan1_i);
      end
    end
  end

  always @(*) begin
    store_live_mask_r = {TOKEN_COUNT{1'b0}};
    live_count_r = {COUNT_W{1'b0}};
    for (count_i = 0; count_i < TOKEN_COUNT; count_i = count_i + 1) begin
      if (live_q[count_i]) begin
        live_count_r = live_count_r + {{(COUNT_W-1){1'b0}}, 1'b1};
        if (kind_q[count_i] == OWNER_KIND_STORE)
          store_live_mask_r[count_i] = 1'b1;
      end
    end
  end

  always @(*) begin
    // v8g edge-old event algebra.  A death and a birth cannot name one token:
    // allocation scans old FREE tokens while every death names an old LIVE one.
    death_mask_r = release_effective_w;
    if (free0_fire_w)
      death_mask_r[free0_token_i] = 1'b1;
    if (free1_fire_w)
      death_mask_r[free1_token_i] = 1'b1;

    birth_mask_r = {TOKEN_COUNT{1'b0}};
    if (alloc0_fire_w)
      birth_mask_r[alloc0_token_o] = 1'b1;
    if (alloc1_fire_w)
      birth_mask_r[alloc1_token_o] = 1'b1;

    producer_clear_mask_r = {PRODUCER_COUNT{1'b0}};
    for (event_i = 0; event_i < TOKEN_COUNT; event_i = event_i + 1) begin
      if (death_mask_r[event_i])
        producer_clear_mask_r[producer_id_q[event_i]] = 1'b1;
    end
    producer_set_mask_r = {PRODUCER_COUNT{1'b0}};
    if (alloc0_fire_w)
      producer_set_mask_r[alloc0_producer_id_i] = 1'b1;
    if (alloc1_fire_w)
      producer_set_mask_r[alloc1_producer_id_i] = 1'b1;

    live_next_r = (live_q & ~death_mask_r) | birth_mask_r;
    producer_live_next_r =
        (producer_live_q & ~producer_clear_mask_r) |
        producer_set_mask_r;
  end

  assign alloc0_ready_o = PARAM_SHAPE_VALID && alloc0_found_r &&
      (alloc0_kind_i != OWNER_KIND_RESERVED) && alloc0_pid_clear_w;
  assign alloc0_token_o = alloc0_token_r;
  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&
      (alloc1_kind_i != OWNER_KIND_RESERVED) && alloc1_pid_clear_w &&
      !(alloc0_claim_w &&
        (alloc1_producer_id_i == alloc0_producer_id_i));
  assign alloc1_token_o = alloc1_token_r;
  assign free0_ready_o = free0_exact_w &&
      !release_effective_w[free0_token_i];
  assign free1_ready_o = free1_exact_w &&
      !release_effective_w[free1_token_i] && !free1_same_as_free0_w;
  assign live_mask_o = live_q;
  assign producer_live_mask_o = producer_live_q;
  assign live_count_o = live_count_r;

  genvar metadata_i;
  generate
    for (metadata_i = 0; metadata_i < TOKEN_COUNT;
         metadata_i = metadata_i + 1) begin : gen_metadata_view
      assign kind_table_o[metadata_i*KIND_W +: KIND_W] = kind_q[metadata_i];
      assign epoch_table_o[metadata_i*EPOCH_W +: EPOCH_W] = epoch_q[metadata_i];
      assign producer_id_table_o[
          metadata_i*PRODUCER_ID_W +: PRODUCER_ID_W] =
          producer_id_q[metadata_i];
    end
  endgenerate

  integer state_i;
  always @(posedge clk) begin
    if (rst) begin
      live_q <= {TOKEN_COUNT{1'b0}};
      producer_live_q <= {PRODUCER_COUNT{1'b0}};
      next_token_q <= {TOKEN_W{1'b0}};
      for (state_i = 0; state_i < TOKEN_COUNT; state_i = state_i + 1) begin
        kind_q[state_i] <= {KIND_W{1'b0}};
        epoch_q[state_i] <= {EPOCH_W{1'b0}};
        producer_id_q[state_i] <= {PRODUCER_ID_W{1'b0}};
      end
    end else begin
      live_q <= live_next_r;
      producer_live_q <= producer_live_next_r;

      if (alloc0_fire_w) begin
        kind_q[alloc0_token_o] <= alloc0_kind_i;
        epoch_q[alloc0_token_o] <= alloc0_epoch_i;
        producer_id_q[alloc0_token_o] <= alloc0_producer_id_i;
      end
      if (alloc1_fire_w) begin
        kind_q[alloc1_token_o] <= alloc1_kind_i;
        epoch_q[alloc1_token_o] <= alloc1_epoch_i;
        producer_id_q[alloc1_token_o] <= alloc1_producer_id_i;
      end

      if (alloc1_fire_w)
        next_token_q <= alloc1_token_o + {{(TOKEN_W-1){1'b0}}, 1'b1};
      else if (alloc0_fire_w)
        next_token_q <= alloc0_token_o + {{(TOKEN_W-1){1'b0}}, 1'b1};
    end
  end

`ifdef OOO_ASSERT
  initial begin
    if (!PARAM_SHAPE_VALID) begin
      $display("[OOO-MEM-OWNER] TOKEN_COUNT/TOKEN_W/COUNT_W parameter shape is invalid");
      $fatal;
    end
  end

  reg conservation_check_q;
  reg [COUNT_W-1:0] conservation_expected_q;
  reg [TOKEN_COUNT-1:0] assert_live_prev_q;
  reg [KIND_W-1:0] assert_kind_prev_q [0:TOKEN_COUNT-1];
  reg [EPOCH_W-1:0] assert_epoch_prev_q [0:TOKEN_COUNT-1];
  reg [PRODUCER_ID_W-1:0] assert_producer_prev_q [0:TOKEN_COUNT-1];
  integer assert_token_i;
  integer assert_token_j;
  integer assert_pid_i;
  integer assert_pid_matches_r;
  integer assert_producer_popcount_r;
  wire [COUNT_W-1:0] death_count_w = popcount_live(death_mask_r);
  always @(posedge clk) begin
    if (rst) begin
      conservation_check_q <= 1'b0;
      conservation_expected_q <= {COUNT_W{1'b0}};
      assert_live_prev_q <= {TOKEN_COUNT{1'b0}};
      for (assert_token_i = 0; assert_token_i < TOKEN_COUNT;
           assert_token_i = assert_token_i + 1) begin
        assert_kind_prev_q[assert_token_i] <= {KIND_W{1'b0}};
        assert_epoch_prev_q[assert_token_i] <= {EPOCH_W{1'b0}};
        assert_producer_prev_q[assert_token_i] <=
            {PRODUCER_ID_W{1'b0}};
      end
    end else begin
      if (conservation_check_q &&
          (live_count_o !== conservation_expected_q)) begin
        $display("[OOO-MEM-OWNER] event algebra count=%0d expected=%0d",
                 live_count_o, conservation_expected_q);
        $fatal;
      end
      conservation_check_q <= 1'b1;
      conservation_expected_q <= live_count_o + alloc0_fire_w + alloc1_fire_w -
          death_count_w;
      if ((death_mask_r & birth_mask_r) != {TOKEN_COUNT{1'b0}}) begin
        $display("[V8G-MEM-OWNER-EVENT] one token had birth and death on one edge");
        $fatal;
      end
      if ((producer_clear_mask_r & producer_set_mask_r) !=
          {PRODUCER_COUNT{1'b0}}) begin
        $display("[V8G-MEM-OWNER-PID-EVENT] one PID had clear and set on one edge");
        $fatal;
      end
      if (alloc0_fire_w && live_q[alloc0_token_o]) begin
        $display("[OOO-MEM-OWNER] alloc0 selected a live token");
        $fatal;
      end
      if (alloc1_fire_w && live_q[alloc1_token_o]) begin
        $display("[OOO-MEM-OWNER] alloc1 selected a live token");
        $fatal;
      end
      if (alloc0_fire_w && alloc1_fire_w &&
          (alloc0_token_o == alloc1_token_o)) begin
        $display("[OOO-MEM-OWNER] dual allocation returned one token twice");
        $fatal;
      end
      if (alloc_pair_atomic_i && alloc1_valid_i && !alloc0_valid_i) begin
        $display("[V8P-MEM-OWNER-ATOMIC-SHAPE] alloc1 valid without alloc0");
        $fatal;
      end
      if (alloc_pair_present_w &&
          (alloc0_fire_w !== alloc1_fire_w)) begin
        $display("[V8P-MEM-OWNER-ATOMIC-FIRE] split dual allocation");
        $fatal;
      end
      if (alloc0_fire_w && producer_live_q[alloc0_producer_id_i]) begin
        $display("[V8G-MEM-OWNER-PID0] alloc selected a live PID=%h",
                 alloc0_producer_id_i);
        $fatal;
      end
      if (alloc1_fire_w && producer_live_q[alloc1_producer_id_i]) begin
        $display("[V8G-MEM-OWNER-PID1] alloc selected a live PID=%h",
                 alloc1_producer_id_i);
        $fatal;
      end
      if (alloc0_fire_w && alloc1_fire_w &&
          (alloc0_producer_id_i == alloc1_producer_id_i)) begin
        $display("[V8G-MEM-OWNER-DUAL-PID] dual allocation returned one PID twice");
        $fatal;
      end
      if ((alloc0_valid_i && (alloc0_kind_i == OWNER_KIND_RESERVED)) ||
          (alloc1_valid_i && (alloc1_kind_i == OWNER_KIND_RESERVED))) begin
        $display("[OOO-MEM-OWNER] reserved owner kind was allocated");
        $fatal;
      end
      if ((release_mask_i & ~store_live_mask_r) != {TOKEN_COUNT{1'b0}}) begin
        $display("[OOO-MEM-OWNER] release_mask named a non-live/non-STORE token");
        $fatal;
      end
      if ((free0_valid_i && release_effective_w[free0_token_i]) ||
          (free1_valid_i && release_effective_w[free1_token_i])) begin
        $display("[OOO-MEM-OWNER] tagged free overlapped STORE release mask");
        $fatal;
      end
      if (free0_valid_i && free1_valid_i &&
          (free0_token_i == free1_token_i)) begin
        $display("[OOO-MEM-OWNER] duplicate dual free named one token twice");
        $fatal;
      end
      if (free0_valid_i && !free0_exact_w) begin
        $display("[OOO-MEM-OWNER] free0 owner tuple did not match live metadata");
        $fatal;
      end
      if (free1_valid_i && !free1_exact_w) begin
        $display("[OOO-MEM-OWNER] free1 owner tuple did not match live metadata");
        $fatal;
      end
      if (live_count_o != popcount_live(live_mask_o)) begin
        $display("[OOO-MEM-OWNER] live_count disagrees with live bitmap popcount");
        $fatal;
      end

      assert_producer_popcount_r = 0;
      for (assert_pid_i = 0; assert_pid_i < PRODUCER_COUNT;
           assert_pid_i = assert_pid_i + 1) begin
        if (producer_live_q[assert_pid_i])
          assert_producer_popcount_r = assert_producer_popcount_r + 1;
        assert_pid_matches_r = 0;
        for (assert_token_i = 0; assert_token_i < TOKEN_COUNT;
             assert_token_i = assert_token_i + 1) begin
          if (live_q[assert_token_i] &&
              (producer_id_q[assert_token_i] ==
               assert_pid_i[PRODUCER_ID_W-1:0]))
            assert_pid_matches_r = assert_pid_matches_r + 1;
        end
        if (assert_pid_matches_r > 1) begin
          $display("[V8G-MEM-OWNER-PID-ONEHOT] pid=%h matches=%0d",
                   assert_pid_i[PRODUCER_ID_W-1:0],
                   assert_pid_matches_r);
          $fatal;
        end
        if (producer_live_q[assert_pid_i] !==
            (assert_pid_matches_r == 1)) begin
          $display("[V8G-MEM-OWNER-PID-EXISTS] pid=%h live=%b matches=%0d",
                   assert_pid_i[PRODUCER_ID_W-1:0],
                   producer_live_q[assert_pid_i], assert_pid_matches_r);
          $fatal;
        end
      end
      if (assert_producer_popcount_r != live_count_o) begin
        $display("[V8G-MEM-OWNER-PID-COUNT] pid_count=%0d token_count=%0d",
                 assert_producer_popcount_r, live_count_o);
        $fatal;
      end

      for (assert_token_i = 0; assert_token_i < TOKEN_COUNT;
           assert_token_i = assert_token_i + 1) begin
        if (live_q[assert_token_i] &&
            (^producer_id_q[assert_token_i] === 1'bx)) begin
          $display("[V8L-MEM-OWNER-PID-KNOWN] live token=%0d has unknown PID",
                   assert_token_i);
          $fatal;
        end
        if (live_q[assert_token_i] &&
            !producer_live_q[producer_id_q[assert_token_i]]) begin
          $display("[V8G-MEM-OWNER-TOKEN-PID] token=%0d pid=%h is not live",
                   assert_token_i, producer_id_q[assert_token_i]);
          $fatal;
        end
        if (assert_live_prev_q[assert_token_i] &&
            live_q[assert_token_i] &&
            ((kind_q[assert_token_i] !==
              assert_kind_prev_q[assert_token_i]) ||
             (epoch_q[assert_token_i] !==
              assert_epoch_prev_q[assert_token_i]) ||
             (producer_id_q[assert_token_i] !==
              assert_producer_prev_q[assert_token_i]))) begin
          $display("[V8G-MEM-OWNER-METADATA-HOLD] token=%0d metadata changed while live",
                   assert_token_i);
          $fatal;
        end
        for (assert_token_j = assert_token_i + 1;
             assert_token_j < TOKEN_COUNT;
             assert_token_j = assert_token_j + 1) begin
          if (live_q[assert_token_i] && live_q[assert_token_j] &&
              (producer_id_q[assert_token_i] ==
               producer_id_q[assert_token_j])) begin
            $display("[V8G-MEM-OWNER-PID-DUP] tokens=%0d,%0d pid=%h",
                     assert_token_i, assert_token_j,
                     producer_id_q[assert_token_i]);
            $fatal;
          end
        end
        assert_kind_prev_q[assert_token_i] <= kind_q[assert_token_i];
        assert_epoch_prev_q[assert_token_i] <= epoch_q[assert_token_i];
        assert_producer_prev_q[assert_token_i] <=
            producer_id_q[assert_token_i];
      end
      assert_live_prev_q <= live_q;
    end
  end
`endif

endmodule
