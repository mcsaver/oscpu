`timescale 1ns/1ps

module tb_ooo_mem_owner_terminal_collector;
  localparam integer INGRESS_N = 12;

  reg clk;
  reg rst;
  reg [INGRESS_N-1:0] ingress_valid;
  reg [(INGRESS_N*2)-1:0] ingress_kind;
  reg [(INGRESS_N*5)-1:0] ingress_token;
  reg [(INGRESS_N*2)-1:0] ingress_epoch;
  reg [31:0] live_mask;
  reg [63:0] live_kind_table;
  reg [63:0] live_epoch_table;
  wire [INGRESS_N-1:0] ingress_accept;
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

  reg [31:0] expected_mask;
  reg [31:0] seen_mask;
  integer seen_count;
  integer lane_i;
  integer drain_i;
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
    .ingress_accept_o(ingress_accept),
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

  task automatic fail;
    input [8*160-1:0] message;
    begin
      $display("[V8P-TCOLL-12INGRESS][FAIL] %0s", message);
      $fatal(1);
    end
  endtask

  task automatic configure_lane;
    input integer lane;
    input [4:0] token;
    input [1:0] kind;
    input [1:0] epoch;
    begin
      ingress_token[(lane*5) +: 5] = token;
      ingress_kind[(lane*2) +: 2] = kind;
      ingress_epoch[(lane*2) +: 2] = epoch;
      live_mask[token] = 1'b1;
      live_kind_table[(token*2) +: 2] = kind;
      live_epoch_table[(token*2) +: 2] = epoch;
      expected_mask[token] = 1'b1;
    end
  endtask

  task automatic record_terminal;
    input [4:0] token;
    input [1:0] kind;
    input [1:0] epoch;
    begin
      if (!expected_mask[token])
        fail("dequeue named a token outside the twelve-ingress batch");
      if (seen_mask[token])
        fail("one terminal token dequeued more than once");
      if ((kind !== live_kind_table[(token*2) +: 2]) ||
          (epoch !== live_epoch_table[(token*2) +: 2]))
        fail("dequeue metadata did not preserve the exact ingress tuple");
      seen_mask[token] = 1'b1;
      seen_count = seen_count + 1;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    ingress_valid = {INGRESS_N{1'b0}};
    ingress_kind = {(INGRESS_N*2){1'b0}};
    ingress_token = {(INGRESS_N*5){1'b0}};
    ingress_epoch = {(INGRESS_N*2){1'b0}};
    live_mask = 32'b0;
    live_kind_table = 64'b0;
    live_epoch_table = 64'b0;
    deq0_ready = 1'b0;
    deq1_ready = 1'b0;
    expected_mask = 32'b0;
    seen_mask = 32'b0;
    seen_count = 0;

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    // Acceptance is the transfer authority exported to OooIntBackend.  Probe
    // malformed and duplicate raw ingress only combinationally so the
    // fail-loud assertion configuration is never weakened or bypassed.
    configure_lane(0, 5'd2, 2'b00, 2'b01);
    ingress_valid[0] = 1'b1;
    ingress_epoch[1:0] = 2'b10;
    #1;
    if (ingress_accept[0])
      fail("tuple-mismatched raw ingress was marked accepted");
    ingress_epoch[1:0] = 2'b01;
    #1;
    if (!ingress_accept[0])
      fail("exact single ingress was not marked accepted");
    ingress_valid = {INGRESS_N{1'b0}};
    expected_mask = 32'b0;
    live_mask = 32'b0;
    live_kind_table = 64'b0;
    live_epoch_table = 64'b0;

    configure_lane(0, 5'd2, 2'b00, 2'b01);
    configure_lane(1, 5'd2, 2'b00, 2'b01);
    ingress_valid[1:0] = 2'b11;
    #1;
    if (ingress_accept[1:0] != 2'b00)
      fail("same-token duplicate raw ingress was marked accepted");
    ingress_valid = {INGRESS_N{1'b0}};
    expected_mask = 32'b0;
    live_mask = 32'b0;
    live_kind_table = 64'b0;
    live_epoch_table = 64'b0;
    $display("[V9Y-TCOLL-ACCEPT-NEGATIVE] tuple=0 duplicate=0 PASS");

    // All twelve production terminal sources arrive on one edge while both
    // registered dequeue lanes are stalled.  Sparse token numbers prevent a
    // counter-only implementation from satisfying the mask check.
    configure_lane(0, 5'd3,  2'b00, 2'b01);
    configure_lane(1, 5'd5,  2'b01, 2'b10);
    configure_lane(2, 5'd7,  2'b10, 2'b11);
    configure_lane(3, 5'd11, 2'b00, 2'b10);
    configure_lane(4, 5'd13, 2'b01, 2'b11);
    configure_lane(5, 5'd17, 2'b10, 2'b01);
    configure_lane(6, 5'd19, 2'b00, 2'b11);
    configure_lane(7, 5'd23, 2'b01, 2'b00);
    configure_lane(8, 5'd25, 2'b10, 2'b10);
    configure_lane(9, 5'd27, 2'b00, 2'b01);
    configure_lane(10, 5'd29, 2'b01, 2'b11);
    configure_lane(11, 5'd31, 2'b10, 2'b00);
    ingress_valid = {INGRESS_N{1'b1}};
    #1;
    if (ingress_accept !== {INGRESS_N{1'b1}})
      fail("exact twelve-lane batch was not accepted in full");
    @(posedge clk);
    #1;
    if ((pending_count !== 6'd12) || (pending_mask !== expected_mask))
      fail("stalled collector did not retain all twelve exact terminals");
    $display("[V8P-TCOLL-12INGRESS-CAPTURE] pending=%0d mask=%h PASS",
             pending_count, pending_mask);

    @(negedge clk);
    ingress_valid = {INGRESS_N{1'b0}};
    @(posedge clk);
    #1;
    if (!deq0_valid || !deq1_valid || (deq0_token == deq1_token))
      fail("two registered outputs did not select distinct pending terminals");
    held0_tuple = {deq0_kind, deq0_token, deq0_epoch};
    held1_tuple = {deq1_kind, deq1_token, deq1_epoch};

    // Hold both output tuples for a complete edge before permitting drain.
    @(posedge clk);
    #1;
    if ({deq0_kind, deq0_token, deq0_epoch} !== held0_tuple ||
        {deq1_kind, deq1_token, deq1_epoch} !== held1_tuple ||
        (pending_count !== 6'd12))
      fail("stalled dequeue tuple or pending count changed");

    @(negedge clk);
    deq0_ready = 1'b1;
    deq1_ready = 1'b1;
    ingress_valid[0] = 1'b1;
    ingress_kind[1:0] = deq0_kind;
    ingress_token[4:0] = deq0_token;
    ingress_epoch[1:0] = deq0_epoch;
    #1;
    if (ingress_accept[0])
      fail("same-edge dequeue/re-enqueue raw ingress was marked accepted");
    ingress_valid[0] = 1'b0;
    #1;
    $display("[V9Y-TCOLL-SAME-EDGE-REENQUEUE] accept=0 PASS");
    for (drain_i = 0; drain_i < 14; drain_i = drain_i + 1) begin
      #1;
      if (deq0_valid)
        record_terminal(deq0_token, deq0_kind, deq0_epoch);
      if (deq1_valid)
        record_terminal(deq1_token, deq1_kind, deq1_epoch);
      @(posedge clk);
      #1;
      if ((pending_count == 0) && !deq0_valid && !deq1_valid)
        drain_i = 14;
      else
        @(negedge clk);
    end

    if ((seen_count != 12) || (seen_mask !== expected_mask))
      fail("drain did not return all twelve tokens exactly once");
    if ((pending_count != 0) || (pending_mask != 0) ||
        deq0_valid || deq1_valid)
      fail("collector retained a ghost terminal after complete drain");
    $display("[V8P-TCOLL-12INGRESS-DRAIN] seen=%0d mask=%h PASS",
             seen_count, seen_mask);
    $display("[PASS] tb_ooo_mem_owner_terminal_collector");
    $finish;
  end
endmodule
