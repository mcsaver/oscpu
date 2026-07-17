`timescale 1ns/1ps

module tb_s2_g1_terminal_collector_failclosed;
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

  OooMemOwnerTerminalCollector #(
    .INGRESS_N(INGRESS_N)
  ) dut (
    .clk(clk), .rst(rst),
    .ingress_valid_i(ingress_valid),
    .ingress_kind_i(ingress_kind),
    .ingress_token_i(ingress_token),
    .ingress_epoch_i(ingress_epoch),
    .live_mask_i(live_mask),
    .live_kind_table_i(live_kind_table),
    .live_epoch_table_i(live_epoch_table),
    .deq0_valid_o(deq0_valid), .deq0_kind_o(deq0_kind),
    .deq0_token_o(deq0_token), .deq0_epoch_o(deq0_epoch),
    .deq0_ready_i(deq0_ready),
    .deq1_valid_o(deq1_valid), .deq1_kind_o(deq1_kind),
    .deq1_token_o(deq1_token), .deq1_epoch_o(deq1_epoch),
    .deq1_ready_i(deq1_ready),
    .pending_mask_o(pending_mask), .pending_count_o(pending_count)
  );

  always #5 clk = ~clk;

  task fail;
    input [8*160-1:0] msg;
    begin
      $display("[S2-G1-TCOLL-FAILCLOSED][FAIL] %0s", msg);
      $fatal(1);
    end
  endtask

  task clear_ingress;
    begin
      ingress_valid = 0;
      ingress_kind = 0;
      ingress_token = 0;
      ingress_epoch = 0;
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

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_ingress();
    live_mask = 0;
    live_kind_table = 0;
    live_epoch_table = 0;
    deq0_ready = 1'b0;
    deq1_ready = 1'b0;
    set_live_owner(20, 2'b00, 2'b01);
    set_live_owner(21, 2'b01, 2'b10);
    // token22 intentionally remains non-live.
    set_live_owner(23, 2'b10, 2'b11);
    set_live_owner(24, 2'b00, 2'b10);
    set_live_owner(25, 2'b01, 2'b01);

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    set_ingress(0, 2'b00, 5'd20, 2'b01);
    @(posedge clk);
    #1;
    if (pending_count != 1 || !pending_mask[20])
      fail("exact seed terminal did not enter pending state");

    // All six lanes below violate independently: pending duplicate, an
    // intra-batch duplicate pair, nonlive, wrong kind and wrong epoch.
    @(negedge clk);
    clear_ingress();
    set_ingress(0, 2'b00, 5'd20, 2'b01);
    set_ingress(1, 2'b01, 5'd21, 2'b10);
    set_ingress(2, 2'b01, 5'd21, 2'b10);
    set_ingress(3, 2'b00, 5'd22, 2'b00);
    set_ingress(4, 2'b01, 5'd23, 2'b11);
    set_ingress(5, 2'b00, 5'd24, 2'b11);
    @(posedge clk);
    #1;
    if (pending_count != 1 || pending_mask != (32'b1 << 20))
      fail("non-assert build admitted a duplicate/nonlive/mismatched terminal");
    if (!deq0_valid || deq0_token != 20)
      fail("seed terminal was not held while violations failed closed");

    // Re-enqueue token20 on its own dequeue edge while an unrelated exact
    // token25 arrives.  Token20 must remain rejected; token25 must survive.
    @(negedge clk);
    clear_ingress();
    deq0_ready = 1'b1;
    set_ingress(0, 2'b00, 5'd20, 2'b01);
    set_ingress(1, 2'b01, 5'd25, 2'b01);
    @(posedge clk);
    #1;
    if (pending_count != 1 || pending_mask != (32'b1 << 25) ||
        pending_mask[20])
      fail("same-edge no-reuse or unrelated-lane preservation failed");

    @(negedge clk);
    clear_ingress();
    deq0_ready = 1'b0;
    @(posedge clk);
    #1;
    if (!deq0_valid || deq0_token != 25 || deq0_kind != 2'b01 ||
        deq0_epoch != 2'b01)
      fail("unrelated exact token did not reach the registered output");

    @(negedge clk);
    deq0_ready = 1'b1;
    @(posedge clk);
    @(posedge clk);
    #1;
    if (pending_count != 0 || pending_mask != 0)
      fail("fail-closed test did not drain the surviving exact token");

    $display("[S2-G1-TCOLL-FAILCLOSED][PASS] duplicate/nonlive/mismatch/no-reuse rejected");
    $finish;
  end
endmodule
