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

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

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
    @(posedge clk);
    #1;
    if ((live_count != 3'd2) || !producer_live_mask[4'h3] ||
        !producer_live_mask[4'ha])
      fail("registered producer lease mask/count missed dual allocation");
    if ((producer_id_table[load_token*PRODUCER_ID_W +: PRODUCER_ID_W]
         != 4'h3) ||
        (kind_table[load_token*2 +: 2] != 2'b00) ||
        (epoch_table[load_token*2 +: 2] != 2'b01))
      fail("token metadata table did not preserve exact allocation tuple");

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
    @(posedge clk);
    #1;
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
    @(posedge clk);
    #1;
    if ((live_count != 3'd2) || producer_live_mask[4'h3])
      fail("tagged free did not clear token and ProducerId together");
    @(negedge clk);
    free0_valid = 1'b0;
    #1;
    if (!alloc0_ready)
      fail("ProducerId was not reusable on the cycle after exact death");
    load_reauth_token = alloc0_token;
    @(posedge clk);
    #1;
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
    @(posedge clk);

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
    @(posedge clk);
    #1;
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
    @(posedge clk);
    #1;
    if ((live_count != 3'd2) || producer_live_mask[4'ha])
      fail("STORE release did not clear its full ProducerId lease");
    @(negedge clk);
    release_mask = '0;
    #1;
    if (!alloc0_ready)
      fail("STORE ProducerId was not reusable on the following cycle");
    store_reauth_token = alloc0_token;
    @(posedge clk);
    #1;
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
    @(posedge clk);
    #1;
    if ((live_count != TOKEN_COUNT[COUNT_W-1:0]) ||
        !producer_live_mask[4'h7])
      fail("tracker did not become exactly full");
    @(negedge clk);
    alloc0_producer_id = 4'h8;
    #1;
    if (alloc0_ready || producer_live_mask[4'h8])
      fail("full tracker admitted a distinct ProducerId");
    $display("[V8L-TRACKER-BACKPRESSURE] full token set blocks a distinct legal ProducerId PASS");

    // Leave exactly one physical token free, then present an atomic two-owner
    // package.  Lane0 may identify the sole credit, but neither owner may be
    // born unless lane1 can identify a second distinct token on the same
    // edge.  This is the non-vacuous scarcity case used by the DI-3 contract.
    @(negedge clk);
    alloc0_valid = 1'b0;
    free0_valid = 1'b1;
    free0_kind = 2'b00;
    free0_token = unique_token;
    free0_epoch = 2'b01;
    #1;
    if (!free0_ready)
      fail("atomic-pair setup could not free the unique load token");
    @(posedge clk);
    #1;
    if ((live_count != 3'd3) || producer_live_mask[4'h6])
      fail("atomic-pair setup did not leave exactly one free token");

    @(negedge clk);
    free0_valid = 1'b0;
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
    if ((live_count != 3'd3) || producer_live_mask[4'h8] ||
        producer_live_mask[4'h9])
      fail("atomic pair changed the lease set without two credits");
    $display("[V8P-TRACKER-ATOMIC-SCARCITY] split ready causes zero owner births PASS");

    $display("[V8G-TRACKER-LEASE][PASS] Q-only PID mask/table, unique birth, edge-old death, next-cycle reuse");
    $display("[PASS] tb_ooo_mem_owner_tracker");
    $finish;
  end
endmodule
