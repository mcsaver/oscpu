`timescale 1ns/1ps

module tb_s2_g1_terminal_collector_green;
  localparam integer INGRESS_N = 6;

  reg clk;
  reg rst;
  reg [INGRESS_N-1:0] ingress_valid;
  reg [(INGRESS_N*2)-1:0] ingress_kind;
  reg [(INGRESS_N*5)-1:0] ingress_token;
  reg [(INGRESS_N*2)-1:0] ingress_epoch;
  reg [31:0] live_mask;
  reg [63:0] live_kind_table;
  reg [63:0] live_epoch_table;
  wire deq0_valid;
  wire [1:0] deq0_kind;
  wire [4:0] deq0_token;
  wire [1:0] deq0_epoch;
  reg deq0_ready;
  wire deq1_valid;
  wire [1:0] deq1_kind;
  wire [4:0] deq1_token;
  wire [1:0] deq1_epoch;
  reg deq1_ready;
  wire [31:0] pending_mask;
  wire [5:0] pending_count;

  reg [31:0] seen_mask;
  integer seen_count;
  integer i;
  integer timeout_i;
  reg [8:0] held0_tuple;
  reg [8:0] held1_tuple;

  OooMemOwnerTerminalCollector #(
    .INGRESS_N(INGRESS_N)
  ) dut (
    .clk(clk),
    .rst(rst),
    .ingress_valid_i(ingress_valid),
    .ingress_kind_i(ingress_kind),
    .ingress_token_i(ingress_token),
    .ingress_epoch_i(ingress_epoch),
    .live_mask_i(live_mask),
    .live_kind_table_i(live_kind_table),
    .live_epoch_table_i(live_epoch_table),
    .deq0_valid_o(deq0_valid),
    .deq0_kind_o(deq0_kind),
    .deq0_token_o(deq0_token),
    .deq0_epoch_o(deq0_epoch),
    .deq0_ready_i(deq0_ready),
    .deq1_valid_o(deq1_valid),
    .deq1_kind_o(deq1_kind),
    .deq1_token_o(deq1_token),
    .deq1_epoch_o(deq1_epoch),
    .deq1_ready_i(deq1_ready),
    .pending_mask_o(pending_mask),
    .pending_count_o(pending_count)
  );

  always #5 clk = ~clk;

  task fail;
    input [8*160-1:0] msg;
    begin
      $display("[S2-G1-TCOLL-GREEN][FAIL] %0s", msg);
      $fatal(1);
    end
  endtask

  task clear_ingress;
    begin
      ingress_valid = {INGRESS_N{1'b0}};
      ingress_kind = {(INGRESS_N*2){1'b0}};
      ingress_token = {(INGRESS_N*5){1'b0}};
      ingress_epoch = {(INGRESS_N*2){1'b0}};
    end
  endtask

  task set_live_owner;
    input integer token;
    input [1:0] kind;
    input [1:0] epoch;
    begin
      live_mask[token] = 1'b1;
      live_kind_table[(token*2) +: 2] = kind;
      live_epoch_table[(token*2) +: 2] = epoch;
    end
  endtask

  task set_ingress;
    input integer lane;
    input [1:0] kind;
    input [4:0] token;
    input [1:0] epoch;
    begin
      ingress_valid[lane] = 1'b1;
      ingress_kind[(lane*2) +: 2] = kind;
      ingress_token[(lane*5) +: 5] = token;
      ingress_epoch[(lane*2) +: 2] = epoch;
    end
  endtask

  task set_six_token_batch;
    input integer first_token;
    integer lane;
    integer token;
    begin
      clear_ingress();
      for (lane = 0; lane < INGRESS_N; lane = lane + 1) begin
        token = first_token + lane;
        set_ingress(lane,
                    live_kind_table[(token*2) +: 2],
                    token[4:0],
                    live_epoch_table[(token*2) +: 2]);
      end
    end
  endtask

  // Independent scoreboard: every dequeue must echo the external owner truth
  // and each of the 18 injected tokens must appear exactly once.
  always @(posedge clk) begin
    if (!rst) begin
      if (deq0_valid && deq0_ready) begin
        if (seen_mask[deq0_token])
          fail("output0 duplicated a terminal token");
        if ((deq0_kind !== live_kind_table[(deq0_token*2) +: 2]) ||
            (deq0_epoch !== live_epoch_table[(deq0_token*2) +: 2]))
          fail("output0 tuple did not echo tracker truth");
        seen_mask[deq0_token] = 1'b1;
        seen_count = seen_count + 1;
      end
      if (deq1_valid && deq1_ready) begin
        if (seen_mask[deq1_token])
          fail("output1 duplicated a terminal token");
        if ((deq1_kind !== live_kind_table[(deq1_token*2) +: 2]) ||
            (deq1_epoch !== live_epoch_table[(deq1_token*2) +: 2]))
          fail("output1 tuple did not echo tracker truth");
        seen_mask[deq1_token] = 1'b1;
        seen_count = seen_count + 1;
      end
      if (deq0_valid && deq0_ready && deq1_valid && deq1_ready &&
          (deq0_token == deq1_token))
        fail("both dequeue ports consumed the same token");
    end
  end

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_ingress();
    live_mask = 32'b0;
    live_kind_table = 64'b0;
    live_epoch_table = 64'b0;
    deq0_ready = 1'b0;
    deq1_ready = 1'b0;
    seen_mask = 32'b0;
    seen_count = 0;

    // Give every tested token independent kind/epoch metadata.  Kind cycles
    // LOAD/STORE/ATOMIC but never uses RESERVED.
    for (i = 0; i < 18; i = i + 1)
      set_live_owner(i, i % 3, i % 4);

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    // Six distinct terminal sources arrive on the same edge.  This is stronger
    // than the required 4+ real-source concurrency check.
    set_six_token_batch(0);
    @(posedge clk);
    #1;
    if (pending_count != 6 || pending_mask[5:0] != 6'b11_1111)
      fail("six-way ingress did not enter the token-indexed pending bitmap");
    if (deq0_valid || deq1_valid)
      fail("new ingress bypassed the registered dequeue boundary");

    @(negedge clk);
    clear_ingress();
    @(posedge clk);
    #1;
    if (!deq0_valid || !deq1_valid || deq0_token != 0 || deq1_token != 1)
      fail("registered dual dequeue did not select two distinct pending tokens");
    held0_tuple = {deq0_kind, deq0_token, deq0_epoch};
    held1_tuple = {deq1_kind, deq1_token, deq1_epoch};

    // Continuous 6+6 bursts arrive while both registered outputs are stalled.
    // The output tuples must not move, and all 18 events must remain pending.
    @(negedge clk);
    set_six_token_batch(6);
    @(posedge clk);
    #1;
    if (pending_count != 12 ||
        {deq0_kind, deq0_token, deq0_epoch} !== held0_tuple ||
        {deq1_kind, deq1_token, deq1_epoch} !== held1_tuple)
      fail("first stalled burst lost an event or changed an output tuple");

    @(negedge clk);
    set_six_token_batch(12);
    @(posedge clk);
    #1;
    if (pending_count != 18 || pending_mask[17:0] != 18'h3ffff ||
        {deq0_kind, deq0_token, deq0_epoch} !== held0_tuple ||
        {deq1_kind, deq1_token, deq1_epoch} !== held1_tuple)
      fail("second stalled burst was not retained losslessly");

    @(negedge clk);
    clear_ingress();
    repeat (2) begin
      @(posedge clk);
      #1;
      if ({deq0_kind, deq0_token, deq0_epoch} !== held0_tuple ||
          {deq1_kind, deq1_token, deq1_epoch} !== held1_tuple)
        fail("dual-output backpressure did not hold registered tuples");
    end

    // Let output0 run while output1 remains stalled.  Output1 must keep token1
    // while output0 refills every edge from the backlog.
    @(negedge clk);
    deq0_ready = 1'b1;
    deq1_ready = 1'b0;
    repeat (4) begin
      @(posedge clk);
      #1;
      if (!deq1_valid ||
          {deq1_kind, deq1_token, deq1_epoch} !== held1_tuple)
        fail("independent output1 stall was disturbed by output0 progress");
    end
    if (seen_count != 4 || seen_mask[1])
      fail("asymmetric ready did not consume exactly four output0 events");

    // Drain both outputs and prove exact once-only conservation for all tokens.
    @(negedge clk);
    deq1_ready = 1'b1;
    timeout_i = 0;
    while (((pending_count != 0) || deq0_valid || deq1_valid) &&
           (timeout_i < 64)) begin
      @(posedge clk);
      #1;
      timeout_i = timeout_i + 1;
    end
    if (timeout_i >= 64)
      fail("dual dequeue did not drain the retained burst");
    if (seen_count != 18 || seen_mask[17:0] != 18'h3ffff ||
        seen_mask[31:18] != 0)
      fail("terminal accounting was not lossless and exactly once");

    // Allow the delayed conservation checker to observe the final empty state.
    @(posedge clk);
    #1;
    if (pending_count != 0 || pending_mask != 0)
      fail("collector did not return to empty");

    $display("[S2-G1-TCOLL-GREEN][PASS] six-way+bursts+dual-backpressure+exact-once");
    $finish;
  end
endmodule
