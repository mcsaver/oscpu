`timescale 1ns/1ps

module tb_ooo_mem_owner_tracker;
  localparam TOKEN_COUNT = 4;
  localparam TOKEN_W = 2;
  localparam COUNT_W = 3;
  localparam PRODUCER_ID_W = 4;
  localparam PRODUCER_COUNT = 16;

  reg clk;
  reg rst;
  reg alloc0_valid;
  reg [1:0] alloc0_kind;
  reg [1:0] alloc0_epoch;
  reg [PRODUCER_ID_W-1:0] alloc0_producer_id;
  wire alloc0_ready;
  wire [TOKEN_W-1:0] alloc0_token;
  reg alloc1_valid;
  reg alloc_pair_atomic;
  reg [1:0] alloc1_kind;
  reg [1:0] alloc1_epoch;
  reg [PRODUCER_ID_W-1:0] alloc1_producer_id;
  wire alloc1_ready;
  wire [TOKEN_W-1:0] alloc1_token;
  reg free0_valid;
  reg [1:0] free0_kind;
  reg [TOKEN_W-1:0] free0_token;
  reg [1:0] free0_epoch;
  wire free0_ready;
  reg free1_valid;
  reg [1:0] free1_kind;
  reg [TOKEN_W-1:0] free1_token;
  reg [1:0] free1_epoch;
  wire free1_ready;
  reg [TOKEN_COUNT-1:0] release_mask;
  wire [TOKEN_COUNT-1:0] live_mask;
  wire [TOKEN_COUNT*2-1:0] kind_table;
  wire [TOKEN_COUNT*2-1:0] epoch_table;
  wire [TOKEN_COUNT*PRODUCER_ID_W-1:0] producer_id_table;
  wire [PRODUCER_COUNT-1:0] producer_live_mask;
  wire [COUNT_W-1:0] live_count;

  reg [TOKEN_W-1:0] load_token;
  reg [TOKEN_W-1:0] store_token;
  reg [TOKEN_W-1:0] amo_token;
  reg [TOKEN_W-1:0] load_reauth_token;
  reg [TOKEN_W-1:0] unique_token;
  reg [TOKEN_W-1:0] store_reauth_token;
  reg [TOKEN_W-1:0] fill_token;

  reg [TOKEN_COUNT-1:0] expected_live_mask;
  reg [PRODUCER_COUNT-1:0] expected_producer_live_mask;
  reg [1:0] expected_kind [0:TOKEN_COUNT-1];
  reg [1:0] expected_epoch [0:TOKEN_COUNT-1];
  reg [PRODUCER_ID_W-1:0] expected_producer_id [0:TOKEN_COUNT-1];
  integer model_i;

  OooMemOwnerTracker #(
    .TOKEN_COUNT(TOKEN_COUNT),
    .TOKEN_W(TOKEN_W),
    .COUNT_W(COUNT_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .PRODUCER_COUNT(PRODUCER_COUNT)
  ) dut (
    .clk(clk),
    .rst(rst),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_kind_i(alloc0_kind),
    .alloc0_epoch_i(alloc0_epoch),
    .alloc0_producer_id_i(alloc0_producer_id),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_token_o(alloc0_token),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_kind_i(alloc1_kind),
    .alloc1_epoch_i(alloc1_epoch),
    .alloc1_producer_id_i(alloc1_producer_id),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_token_o(alloc1_token),
    .alloc_pair_atomic_i(alloc_pair_atomic),
    .free0_valid_i(free0_valid),
    .free0_kind_i(free0_kind),
    .free0_token_i(free0_token),
    .free0_epoch_i(free0_epoch),
    .free0_ready_o(free0_ready),
    .free1_valid_i(free1_valid),
    .free1_kind_i(free1_kind),
    .free1_token_i(free1_token),
    .free1_epoch_i(free1_epoch),
    .free1_ready_o(free1_ready),
    .release_mask_i(release_mask),
    .live_mask_o(live_mask),
    .kind_table_o(kind_table),
    .epoch_table_o(epoch_table),
    .producer_id_table_o(producer_id_table),
    .producer_live_mask_o(producer_live_mask),
    .live_count_o(live_count)
  );

`ifndef V11C_DISABLE_SEMANTIC_CHECKER
  OooMemOwnerTrackerSemanticChecker #(
    .TOKEN_COUNT(TOKEN_COUNT),
    .TOKEN_W(TOKEN_W),
    .COUNT_W(COUNT_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .PRODUCER_COUNT(PRODUCER_COUNT)
  ) semantic_checker (
    .clk(clk),
    .rst(rst),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_kind_i(alloc0_kind),
    .alloc0_epoch_i(alloc0_epoch),
    .alloc0_producer_id_i(alloc0_producer_id),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_kind_i(alloc1_kind),
    .alloc1_epoch_i(alloc1_epoch),
    .alloc1_producer_id_i(alloc1_producer_id),
    .free0_valid_i(free0_valid),
    .free0_kind_i(free0_kind),
    .free0_token_i(free0_token),
    .free0_epoch_i(free0_epoch),
    .free1_valid_i(free1_valid),
    .free1_kind_i(free1_kind),
    .free1_token_i(free1_token),
    .free1_epoch_i(free1_epoch),
    .release_mask_i(release_mask),
    .live_mask_i(live_mask),
    .kind_table_i(kind_table),
    .epoch_table_i(epoch_table),
    .producer_id_table_i(producer_id_table),
    .producer_live_mask_i(producer_live_mask),
    .live_count_i(live_count)
  );
`endif

  always #5 clk = ~clk;

  task automatic fail;
    input [8*128-1:0] message;
    begin
      $display("[V8G-TRACKER-LEASE][FAIL] %0s", message);
      $fatal(1);
    end
  endtask

  task automatic clear_inputs;
    begin
      alloc0_valid = 1'b0;
      alloc0_kind = 2'b00;
      alloc0_epoch = 2'b00;
      alloc0_producer_id = '0;
      alloc1_valid = 1'b0;
      alloc_pair_atomic = 1'b0;
      alloc1_kind = 2'b00;
      alloc1_epoch = 2'b00;
      alloc1_producer_id = '0;
      free0_valid = 1'b0;
      free0_kind = 2'b00;
      free0_token = '0;
      free0_epoch = 2'b00;
      free1_valid = 1'b0;
      free1_kind = 2'b00;
      free1_token = '0;
      free1_epoch = 2'b00;
      release_mask = '0;
    end
  endtask

  function automatic [COUNT_W-1:0] count_expected_live;
    input [TOKEN_COUNT-1:0] bits;
    integer count_i;
    begin
      count_expected_live = {COUNT_W{1'b0}};
      for (count_i = 0; count_i < TOKEN_COUNT; count_i = count_i + 1)
        count_expected_live =
            count_expected_live + bits[count_i];
    end
  endfunction

  task automatic check_exact_state;
    input [8*128-1:0] phase;
    integer check_i;
    begin
      if (live_mask !== expected_live_mask) begin
        $display("[V11C-TRACKER-LIVE-SET][FAIL] phase=%0s got=%b expected=%b",
                 phase, live_mask, expected_live_mask);
        fail("exact live_mask mismatch");
      end
      if (producer_live_mask !== expected_producer_live_mask) begin
        $display("[V11C-TRACKER-MAP-LIFECYCLE][FAIL] phase=%0s got=%h expected=%h",
                 phase, producer_live_mask, expected_producer_live_mask);
        fail("exact ProducerId live mask mismatch");
      end
      if (live_count !== count_expected_live(expected_live_mask)) begin
        $display("[V11C-TRACKER-LIVE-SET][FAIL] phase=%0s count=%0d expected=%0d",
                 phase, live_count,
                 count_expected_live(expected_live_mask));
        fail("live_count disagrees with independent model");
      end
      for (check_i = 0; check_i < TOKEN_COUNT;
           check_i = check_i + 1) begin
        if (expected_live_mask[check_i] &&
            ((kind_table[check_i*2 +: 2] !== expected_kind[check_i]) ||
             (epoch_table[check_i*2 +: 2] !== expected_epoch[check_i]) ||
             (producer_id_table[
                check_i*PRODUCER_ID_W +: PRODUCER_ID_W] !==
              expected_producer_id[check_i]))) begin
          $display("[V11C-TRACKER-MAP-LIFECYCLE][FAIL] phase=%0s token=%0d kind=%b/%b epoch=%b/%b pid=%h/%h",
                   phase, check_i,
                   kind_table[check_i*2 +: 2], expected_kind[check_i],
                   epoch_table[check_i*2 +: 2], expected_epoch[check_i],
                   producer_id_table[
                     check_i*PRODUCER_ID_W +: PRODUCER_ID_W],
                   expected_producer_id[check_i]);
          fail("live token metadata differs from independent model");
        end
      end
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    expected_live_mask = '0;
    expected_producer_live_mask = '0;
    for (model_i = 0; model_i < TOKEN_COUNT; model_i = model_i + 1) begin
      expected_kind[model_i] = '0;
      expected_epoch[model_i] = '0;
      expected_producer_id[model_i] = '0;
    end
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

`ifdef V11C_ALLOC_PID_UNKNOWN_NEGATIVE
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc0_producer_id = {PRODUCER_ID_W{1'bx}};
    @(posedge clk);
    #1;
    fail("[V11C-TRACKER-ALLOC-PID-UNKNOWN-ESCAPED]");
`endif

`ifdef V11C_RELEASE_MASK_UNKNOWN_NEGATIVE
    release_mask = {TOKEN_COUNT{1'bx}};
    @(posedge clk);
    #1;
    fail("[V11C-TRACKER-RELEASE-MASK-UNKNOWN-ESCAPED]");
`endif

    // Establish two distinct leases and verify every registered query face.
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc0_producer_id = 4'h3;
    alloc1_valid = 1'b1;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b10;
    alloc1_producer_id = 4'ha;
    #1;
    if (!alloc0_ready || !alloc1_ready ||
        (alloc0_token == alloc1_token))
      fail("distinct dual allocation was not admitted exactly once");
    load_token = alloc0_token;
    store_token = alloc1_token;
    expected_live_mask[load_token] = 1'b1;
    expected_kind[load_token] = 2'b00;
    expected_epoch[load_token] = 2'b01;
    expected_producer_id[load_token] = 4'h3;
    expected_producer_live_mask[4'h3] = 1'b1;
    expected_live_mask[store_token] = 1'b1;
    expected_kind[store_token] = 2'b01;
    expected_epoch[store_token] = 2'b10;
    expected_producer_id[store_token] = 4'ha;
    expected_producer_live_mask[4'ha] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("dual allocation");
    if ((live_count != 3'd2) || !producer_live_mask[4'h3] ||
        !producer_live_mask[4'ha])
      fail("registered producer lease mask/count missed dual allocation");
    if ((producer_id_table[load_token*PRODUCER_ID_W +: PRODUCER_ID_W]
         != 4'h3) ||
        (kind_table[load_token*2 +: 2] != 2'b00) ||
        (epoch_table[load_token*2 +: 2] != 2'b01))
      fail("token metadata table did not preserve exact allocation tuple");

`ifdef V11C_LIVE_MAP_UNKNOWN_NEGATIVE
    case (load_token)
      2'd0: dut.producer_id_q[0] = {PRODUCER_ID_W{1'bx}};
      2'd1: dut.producer_id_q[1] = {PRODUCER_ID_W{1'bx}};
      2'd2: dut.producer_id_q[2] = {PRODUCER_ID_W{1'bx}};
      2'd3: dut.producer_id_q[3] = {PRODUCER_ID_W{1'bx}};
    endcase
    @(posedge clk);
    #1;
    fail("[V11C-TRACKER-LIVE-MAP-UNKNOWN-ESCAPED]");
`endif

`ifdef V11C_LIVE_SET_UNKNOWN_NEGATIVE
    case (load_token)
      2'd0: dut.live_q[0] = 1'bx;
      2'd1: dut.live_q[1] = 1'bx;
      2'd2: dut.live_q[2] = 1'bx;
      2'd3: dut.live_q[3] = 1'bx;
    endcase
    @(posedge clk);
    #1;
    fail("[V11C-TRACKER-LIVE-SET-UNKNOWN-ESCAPED]");
`endif

    // A blocked lane0 PID must not consume lane1's independent token/credit.
    @(negedge clk);
    alloc0_producer_id = 4'h3;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b11;
    alloc1_producer_id = 4'h5;
    alloc1_kind = 2'b10;
    alloc1_epoch = 2'b11;
    #1;
    if (alloc0_ready || !alloc1_ready)
      fail("live lane0 PID either reallocated or blocked independent lane1");
    amo_token = alloc1_token;
    expected_live_mask[amo_token] = 1'b1;
    expected_kind[amo_token] = 2'b10;
    expected_epoch[amo_token] = 2'b11;
    expected_producer_id[amo_token] = 4'h5;
    expected_producer_live_mask[4'h5] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("lane1 independent allocation");
    if ((live_count != 3'd3) || !producer_live_mask[4'h5])
      fail("lane1-only legal lease was not registered");

    // Exact terminal clears on the edge, but the edge-old PID cannot be born
    // again on that same edge even though another token is already free.
    @(negedge clk);
    alloc1_valid = 1'b0;
    free0_valid = 1'b1;
    free0_kind = 2'b00;
    free0_token = load_token;
    free0_epoch = 2'b01;
    alloc0_producer_id = 4'h3;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b00;
    #1;
    if (!free0_ready || alloc0_ready || !producer_live_mask[4'h3])
      fail("tagged-free edge exposed an edge-old ProducerId for reuse");
    expected_live_mask[load_token] = 1'b0;
    expected_producer_live_mask[4'h3] = 1'b0;
    @(posedge clk);
    #1;
    check_exact_state("exact death");
    if ((live_count != 3'd2) || producer_live_mask[4'h3])
      fail("tagged free did not clear token and ProducerId together");
    @(negedge clk);
    free0_valid = 1'b0;
    #1;
    if (!alloc0_ready)
      fail("ProducerId was not reusable on the cycle after exact death");
    load_reauth_token = alloc0_token;
    expected_live_mask[load_reauth_token] = 1'b1;
    expected_kind[load_reauth_token] = 2'b00;
    expected_epoch[load_reauth_token] = 2'b00;
    expected_producer_id[load_reauth_token] = 4'h3;
    expected_producer_live_mask[4'h3] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("exact death next-cycle reuse");
    if ((live_count != 3'd3) || !producer_live_mask[4'h3] ||
        (producer_id_table[
          load_reauth_token*PRODUCER_ID_W +: PRODUCER_ID_W] != 4'h3))
      fail("next-cycle ProducerId reauthorization was not exact");

    // Free the AMO first so two physical tokens are available; the next check
    // therefore isolates duplicate-PID exclusion from token scarcity.
    @(negedge clk);
    alloc0_valid = 1'b0;
    free1_valid = 1'b1;
    free1_kind = 2'b10;
    free1_token = amo_token;
    free1_epoch = 2'b11;
    #1;
    if (!free1_ready)
      fail("exact AMO tagged free was rejected");
    expected_live_mask[amo_token] = 1'b0;
    expected_producer_live_mask[4'h5] = 1'b0;
    @(posedge clk);
    #1;
    check_exact_state("free1 exact death");

    // Dual requests for one PID have one winner even with two free tokens.
    @(negedge clk);
    free1_valid = 1'b0;
    alloc0_valid = 1'b1;
    alloc0_producer_id = 4'h6;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc1_valid = 1'b1;
    alloc1_producer_id = 4'h6;
    alloc1_kind = 2'b10;
    alloc1_epoch = 2'b10;
    #1;
    if (!alloc0_ready || alloc1_ready)
      fail("duplicate dual ProducerId did not select exactly one birth");
    unique_token = alloc0_token;
    expected_live_mask[unique_token] = 1'b1;
    expected_kind[unique_token] = 2'b00;
    expected_epoch[unique_token] = 2'b01;
    expected_producer_id[unique_token] = 4'h6;
    expected_producer_live_mask[4'h6] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("duplicate PID single winner");
    if ((live_count != 3'd3) || !producer_live_mask[4'h6] ||
        (producer_id_table[unique_token*PRODUCER_ID_W +:
                           PRODUCER_ID_W] != 4'h6))
      fail("single winner of duplicate-PID request was not registered");

    // A spare token already exists.  Prove STORE bulk death obeys the same
    // edge-old no-rebirth rule for the full PID, not merely for its ROB low bits.
    @(negedge clk);
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    release_mask[store_token] = 1'b1;
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b00;
    alloc0_producer_id = 4'ha;
    #1;
    if (alloc0_ready || !producer_live_mask[4'ha])
      fail("STORE release edge exposed an edge-old ProducerId for reuse");
    expected_live_mask[store_token] = 1'b0;
    expected_producer_live_mask[4'ha] = 1'b0;
    @(posedge clk);
    #1;
    check_exact_state("STORE bulk death");
    if ((live_count != 3'd2) || producer_live_mask[4'ha])
      fail("STORE release did not clear its full ProducerId lease");
    @(negedge clk);
    release_mask = '0;
    #1;
    if (!alloc0_ready)
      fail("STORE ProducerId was not reusable on the following cycle");
    store_reauth_token = alloc0_token;
    expected_live_mask[store_reauth_token] = 1'b1;
    expected_kind[store_reauth_token] = 2'b01;
    expected_epoch[store_reauth_token] = 2'b00;
    expected_producer_id[store_reauth_token] = 4'ha;
    expected_producer_live_mask[4'ha] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("STORE death next-cycle reuse");
    if ((live_count != 3'd3) || !producer_live_mask[4'ha] ||
        (producer_id_table[
          store_reauth_token*PRODUCER_ID_W +: PRODUCER_ID_W] != 4'ha))
      fail("STORE next-cycle full-PID reauthorization failed");

    // Consume the last physical token, then present a distinct, otherwise
    // legal ProducerId.  This is a non-vacuous full-tracker backpressure case:
    // duplicate-P exclusion is false, so only token scarcity may close ready.
    @(negedge clk);
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc0_producer_id = 4'h7;
    #1;
    if (!alloc0_ready)
      fail("last physical owner token was not available");
    fill_token = alloc0_token;
    expected_live_mask[fill_token] = 1'b1;
    expected_kind[fill_token] = 2'b00;
    expected_epoch[fill_token] = 2'b01;
    expected_producer_id[fill_token] = 4'h7;
    expected_producer_live_mask[4'h7] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("full tracker");
    if ((live_count != TOKEN_COUNT[COUNT_W-1:0]) ||
        !producer_live_mask[4'h7])
      fail("tracker did not become exactly full");
    @(negedge clk);
    alloc0_producer_id = 4'h8;
    #1;
    if (alloc0_ready || producer_live_mask[4'h8])
      fail("full tracker admitted a distinct ProducerId");
    $display("[V8L-TRACKER-BACKPRESSURE] full token set blocks a distinct legal ProducerId PASS");

    // An exact death at a full tracker must not make that edge-old live token
    // visible to a distinct PID on the same edge.  This isolates token-set
    // edge-old semantics from the ProducerId no-rebirth guard.
    @(negedge clk);
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc0_producer_id = 4'h8;
    free0_valid = 1'b1;
    free0_kind = 2'b00;
    free0_token = unique_token;
    free0_epoch = 2'b01;
    #1;
    if (!free0_ready || alloc0_ready)
      fail("exact death exposed an edge-old live token to a distinct PID");
    expected_live_mask[unique_token] = 1'b0;
    expected_producer_live_mask[4'h6] = 1'b0;
    @(posedge clk);
    #1;
    check_exact_state("full exact death blocks same-edge reuse");
    if ((live_count != 3'd3) || producer_live_mask[4'h6])
      fail("atomic-pair setup did not leave exactly one free token");

    // Lane0 may identify the sole next-cycle credit, but neither owner may be
    // born atomically unless lane1 identifies a second distinct token.
    @(negedge clk);
    free0_valid = 1'b0;
    #1;
    if (!alloc0_ready || (alloc0_token != unique_token))
      fail("exactly freed token was not reusable on the next cycle");
    alloc_pair_atomic = 1'b1;
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc0_producer_id = 4'h8;
    alloc1_valid = 1'b1;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b10;
    alloc1_producer_id = 4'h9;
    #1;
    if (!alloc0_ready || alloc1_ready)
      fail("one-token setup did not expose the intended split-ready pressure");
`ifdef V8P_MUTATE_ALLOC0_ONLY_BIRTH
    if (dut.alloc0_fire_w && !dut.alloc1_fire_w)
      $display("[V8P-MUTATION-ACTIVATED] alloc0_only_birth");
`endif
    if (dut.alloc0_fire_w || dut.alloc1_fire_w) begin
      $display("[CHECK-FAIL] V8P tracker atomic scarcity zero births");
      fail("atomic pair committed a partial owner birth under one-token pressure");
    end
    @(posedge clk);
    #1;
    check_exact_state("atomic scarcity zero births");
    if ((live_count != 3'd3) || producer_live_mask[4'h8] ||
        producer_live_mask[4'h9])
      fail("atomic pair changed the lease set without two credits");
    $display("[V8P-TRACKER-ATOMIC-SCARCITY] split ready causes zero owner births PASS");

    // Refill the exact-death credit, then repeat the full-table edge-old check
    // through the STORE bulk-release path with a different legal PID.
    @(negedge clk);
    alloc_pair_atomic = 1'b0;
    alloc1_valid = 1'b0;
    #1;
    if (!alloc0_ready || (alloc0_token != unique_token))
      fail("standalone refill did not select the exact-death credit");
    expected_live_mask[unique_token] = 1'b1;
    expected_kind[unique_token] = 2'b00;
    expected_epoch[unique_token] = 2'b01;
    expected_producer_id[unique_token] = 4'h8;
    expected_producer_live_mask[4'h8] = 1'b1;
    @(posedge clk);
    #1;
    check_exact_state("exact-death credit refill");

    @(negedge clk);
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b10;
    alloc0_producer_id = 4'h9;
    release_mask[store_reauth_token] = 1'b1;
    #1;
    if (alloc0_ready)
      fail("STORE bulk death exposed an edge-old live token to a distinct PID");
    expected_live_mask[store_reauth_token] = 1'b0;
    expected_producer_live_mask[4'ha] = 1'b0;
    @(posedge clk);
    #1;
    check_exact_state("full STORE bulk death blocks same-edge reuse");
    if (producer_live_mask[4'h9])
      fail("blocked bulk-death allocation created a ProducerId lease");
    @(negedge clk);
    release_mask = '0;
    #1;
    if (!alloc0_ready || (alloc0_token != store_reauth_token))
      fail("STORE bulk-death token was not reusable on the next cycle");

    $display("[V11C-TRACKER-MAP-LIFECYCLE] exact token-to-ProducerId/kind/epoch scoreboard PASS");
    $display("[V11C-TRACKER-LIVE-SET] exact birth/hold/exact+bulk death/edge-old reuse PASS");
    $display("[V8G-TRACKER-LEASE][PASS] Q-only PID mask/table, unique birth, edge-old death, next-cycle reuse");
    $display("[PASS] tb_ooo_mem_owner_tracker");
    $finish;
  end
endmodule
