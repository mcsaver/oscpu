`timescale 1ns/1ps

module tb_s2_g1_owner_tracker_contract;
  reg clk;
  reg rst;
  reg alloc0_valid;
  reg [1:0] alloc0_kind;
  reg [1:0] alloc0_epoch;
  wire alloc0_ready;
  wire [4:0] alloc0_token;
  reg alloc1_valid;
  reg [1:0] alloc1_kind;
  reg [1:0] alloc1_epoch;
  wire alloc1_ready;
  wire [4:0] alloc1_token;
  reg free0_valid;
  reg [1:0] free0_kind;
  reg [4:0] free0_token;
  reg [1:0] free0_epoch;
  wire free0_ready;
  reg free1_valid;
  reg [1:0] free1_kind;
  reg [4:0] free1_token;
  reg [1:0] free1_epoch;
  wire free1_ready;
  reg [31:0] release_mask;
  wire [31:0] live_mask;
  wire [5:0] live_count;
  reg [4:0] token0_saved;
  reg [4:0] token1_saved;

  OooMemOwnerTracker dut (
    .clk(clk),
    .rst(rst),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_kind_i(alloc0_kind),
    .alloc0_epoch_i(alloc0_epoch),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_token_o(alloc0_token),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_kind_i(alloc1_kind),
    .alloc1_epoch_i(alloc1_epoch),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_token_o(alloc1_token),
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
    .live_count_o(live_count)
  );

  always #5 clk = ~clk;

  task fail;
    input [8*96-1:0] msg;
    begin
      $display("[S2-G1-OWNER][FAIL] %0s", msg);
      $fatal(1);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    alloc0_valid = 1'b0;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b00;
    alloc1_valid = 1'b0;
    alloc1_kind = 2'b00;
    alloc1_epoch = 2'b00;
    free0_valid = 1'b0;
    free0_kind = 2'b00;
    free0_token = 5'd0;
    free0_epoch = 2'b00;
    free1_valid = 1'b0;
    free1_kind = 2'b00;
    free1_token = 5'd0;
    free1_epoch = 2'b00;
    release_mask = 32'b0;

    repeat (2) @(posedge clk);
    rst = 1'b0;
    @(negedge clk);
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b10;
    alloc1_valid = 1'b1;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b11;
    #1;
    if (!alloc0_ready || !alloc1_ready)
      fail("dual allocation was not accepted from an empty tracker");
    if (alloc0_token == alloc1_token)
      fail("dual allocation returned the same live token");
    token0_saved = alloc0_token;
    token1_saved = alloc1_token;
    @(posedge clk);
    #1;
    if (live_count != 6'd2)
      fail("dual allocation did not create two live owners");

    @(negedge clk);
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    free0_valid = 1'b1;
    free0_kind = 2'b01;
    free0_token = token0_saved;
    free0_epoch = 2'b01;
    #1;
    if (free0_ready)
      fail("wrong epoch was accepted as an exact owner free");
    free0_epoch = 2'b10;
    #1;
    if (!free0_ready)
      fail("exact owner free was rejected");
    @(posedge clk);
    #1;
    if (live_count != 6'd1)
      fail("exact owner free did not release exactly one token");

    @(negedge clk);
    free0_valid = 1'b0;
    release_mask = live_mask;
    @(posedge clk);
    #1;
    if (live_count != 6'd0 || live_mask != 32'b0)
      fail("release mask did not clear the remaining exact owner");

    $display("[S2-G1-OWNER][PASS] exact allocator contract");
    $finish;
  end
endmodule
