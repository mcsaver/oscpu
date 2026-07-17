`timescale 1ns/1ps

module tb_s2_g1_owner_tracker_green;
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
  reg [4:0] saved_token [0:31];
  reg [1:0] saved_kind [0:31];
  reg [1:0] saved_epoch [0:31];
  integer i;
  reg [4:0] concurrent_token0;
  reg [4:0] concurrent_token1;
  reg [4:0] survivor_token0;
  reg [4:0] survivor_token1;

  OooMemOwnerTracker dut (
    .clk(clk), .rst(rst),
    .alloc0_valid_i(alloc0_valid), .alloc0_kind_i(alloc0_kind),
    .alloc0_epoch_i(alloc0_epoch), .alloc0_ready_o(alloc0_ready),
    .alloc0_token_o(alloc0_token),
    .alloc1_valid_i(alloc1_valid), .alloc1_kind_i(alloc1_kind),
    .alloc1_epoch_i(alloc1_epoch), .alloc1_ready_o(alloc1_ready),
    .alloc1_token_o(alloc1_token),
    .free0_valid_i(free0_valid), .free0_kind_i(free0_kind),
    .free0_token_i(free0_token), .free0_epoch_i(free0_epoch),
    .free0_ready_o(free0_ready),
    .free1_valid_i(free1_valid), .free1_kind_i(free1_kind),
    .free1_token_i(free1_token), .free1_epoch_i(free1_epoch),
    .free1_ready_o(free1_ready),
    .release_mask_i(release_mask),
    .live_mask_o(live_mask), .live_count_o(live_count)
  );

  always #5 clk = ~clk;

  task fail;
    input [8*112-1:0] msg;
    begin
      $display("[S2-G1-OWNER-GREEN][FAIL] %0s", msg);
      $fatal(1);
    end
  endtask

  task clear_inputs;
    begin
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
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    alloc0_valid = 1'b1;
    alloc0_kind = 2'b11;
    #1;
    if (alloc0_ready)
      fail("RESERVED owner kind was admitted without assertion support");
    alloc0_valid = 1'b0;
    alloc0_kind = 2'b00;

    // Fill all 32 tokens in dual-allocation pairs.  Capture grants before fire.
    for (i = 0; i < 16; i = i + 1) begin
      alloc0_valid = 1'b1;
      alloc0_kind = (i == 0) ? 2'b00 : 2'b01;
      alloc0_epoch = i[1:0];
      alloc1_valid = 1'b1;
      alloc1_kind = (i == 0) ? 2'b10 : 2'b01;
      alloc1_epoch = (i + 1) & 2'b11;
      #1;
      if (!alloc0_ready || !alloc1_ready || alloc0_token == alloc1_token)
        fail("dual fill failed before tracker became full");
      saved_token[i*2] = alloc0_token;
      saved_kind[i*2] = alloc0_kind;
      saved_epoch[i*2] = alloc0_epoch;
      saved_token[i*2+1] = alloc1_token;
      saved_kind[i*2+1] = alloc1_kind;
      saved_epoch[i*2+1] = alloc1_epoch;
      @(posedge clk);
      #1;
      if (live_count != (i + 1) * 2)
        fail("live_count diverged from bitmap popcount during fill");
      @(negedge clk);
    end
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    #1;
    if (alloc0_ready || alloc1_ready || live_count != 6'd32 || live_mask != 32'hffff_ffff)
      fail("full tracker admitted an allocation or lost a live bit");

    // Make next=6, then free token2.  Allocation must scan 6..31 and wrap to 2;
    // this catches an untruncated integer index in the circular scan.
    free0_valid = 1'b1;
    free0_kind = saved_kind[5];
    free0_token = saved_token[5];
    free0_epoch = saved_epoch[5];
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b11;
    #1;
    if (!free0_ready || alloc0_ready)
      fail("same-edge free incorrectly reopened a token for allocation");
    @(posedge clk);
    @(negedge clk);
    free0_valid = 1'b0;
    alloc0_kind = 2'b11;
    alloc1_valid = 1'b1;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b11;
    #1;
    if (alloc0_ready || !alloc1_ready || alloc1_token != saved_token[5])
      fail("RESERVED lane0 consumed the sole credit needed by legal lane1");
    alloc0_valid = 1'b0;
    saved_token[5] = alloc1_token;
    saved_kind[5] = alloc1_kind;
    saved_epoch[5] = alloc1_epoch;
    @(posedge clk);
    @(negedge clk);
    alloc1_valid = 1'b0;
    alloc0_kind = 2'b01;

    free0_valid = 1'b1;
    free0_kind = saved_kind[2];
    free0_token = saved_token[2];
    free0_epoch = saved_epoch[2];
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b10;
    #1;
    if (!free0_ready || alloc0_ready)
      fail("wrap probe reused token2 on its free edge");
    @(posedge clk);
    @(negedge clk);
    free0_valid = 1'b0;
    #1;
    if (!alloc0_ready || alloc0_token != saved_token[2])
      fail("circular scan did not wrap from next=6 to the sole low free token2");
    saved_token[2] = alloc0_token;
    saved_kind[2] = alloc0_kind;
    saved_epoch[2] = alloc0_epoch;
    @(posedge clk);
    @(negedge clk);
    alloc0_valid = 1'b0;

    // Wrong kind, wrong epoch, and non-live token are all rejected.
    free0_valid = 1'b1;
    free0_token = saved_token[4];
    free0_kind = saved_kind[4] ^ 2'b01;
    free0_epoch = saved_epoch[4];
    #1;
    if (free0_ready)
      fail("wrong-kind tagged free was accepted");
    free0_kind = saved_kind[4];
    free0_epoch = saved_epoch[4] ^ 2'b01;
    #1;
    if (free0_ready)
      fail("wrong-epoch tagged free was accepted");
    free0_epoch = saved_epoch[4];
    #1;
    if (!free0_ready)
      fail("exact tagged free was rejected");
    @(posedge clk);
    @(negedge clk);
    #1;
    if (free0_ready)
      fail("non-live tagged free was accepted");

    // Duplicate dual free has exactly one winner.
    free0_token = saved_token[3];
    free0_kind = saved_kind[3];
    free0_epoch = saved_epoch[3];
    free1_valid = 1'b1;
    free1_token = saved_token[3];
    free1_kind = saved_kind[3];
    free1_epoch = saved_epoch[3];
    #1;
    if (!free0_ready || free1_ready)
      fail("duplicate dual free did not select exactly one terminal");
    free1_valid = 1'b0;
    @(posedge clk);
    @(negedge clk);
    free0_valid = 1'b0;
    free1_valid = 1'b0;

    // release_mask is STORE-only: LOAD/ATOMIC bits remain live, STORE bits clear.
    release_mask = live_mask;
    release_mask[saved_token[0]] = 1'b0;
    release_mask[saved_token[1]] = 1'b0;
    @(posedge clk);
    @(negedge clk);
    release_mask = 32'b0;
    #1;
    if (!live_mask[saved_token[0]])
      fail("LOAD owner was incorrectly released by STORE-only mask");
    if (!live_mask[saved_token[1]])
      fail("ATOMIC owner was incorrectly released by STORE-only mask");
    if (live_count != 6'd2)
      fail("STORE-only release mask did not leave exactly LOAD+ATOMIC owners");

    // Free the remaining non-STORE owners through exact tagged ports.
    free0_valid = 1'b1;
    free0_token = saved_token[0];
    free0_kind = saved_kind[0];
    free0_epoch = saved_epoch[0];
    free1_valid = 1'b1;
    free1_token = saved_token[1];
    free1_kind = saved_kind[1];
    free1_epoch = saved_epoch[1];
    #1;
    if (!free0_ready || !free1_ready)
      fail("independent exact dual free was rejected");
    @(posedge clk);
    #1;
    if (live_count != 6'd0 || live_mask != 32'b0)
      fail("tracker did not return to empty after exact terminal frees");

    // With ordinary free slots available, dual exact free and dual allocation
    // may fire together.  The new grants must not reuse either pre-edge live token.
    @(negedge clk);
    free0_valid = 1'b0;
    free1_valid = 1'b0;
    alloc0_valid = 1'b1;
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b00;
    alloc1_valid = 1'b1;
    alloc1_kind = 2'b10;
    alloc1_epoch = 2'b01;
    #1;
    saved_token[0] = alloc0_token;
    saved_kind[0] = alloc0_kind;
    saved_epoch[0] = alloc0_epoch;
    saved_token[1] = alloc1_token;
    saved_kind[1] = alloc1_kind;
    saved_epoch[1] = alloc1_epoch;
    @(posedge clk);
    @(negedge clk);
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b10;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b11;
    #1;
    saved_token[2] = alloc0_token;
    saved_kind[2] = alloc0_kind;
    saved_epoch[2] = alloc0_epoch;
    saved_token[3] = alloc1_token;
    saved_kind[3] = alloc1_kind;
    saved_epoch[3] = alloc1_epoch;
    @(posedge clk);
    @(negedge clk);
    free0_valid = 1'b1;
    free0_token = saved_token[0];
    free0_kind = saved_kind[0];
    free0_epoch = saved_epoch[0];
    free1_valid = 1'b1;
    free1_token = saved_token[1];
    free1_kind = saved_kind[1];
    free1_epoch = saved_epoch[1];
    alloc0_kind = 2'b00;
    alloc0_epoch = 2'b01;
    alloc1_kind = 2'b10;
    alloc1_epoch = 2'b10;
    #1;
    if (!free0_ready || !free1_ready || !alloc0_ready || !alloc1_ready)
      fail("dual free plus dual allocation did not fire with independent empty tokens");
    if (alloc0_token == saved_token[0] || alloc0_token == saved_token[1] ||
        alloc1_token == saved_token[0] || alloc1_token == saved_token[1])
      fail("dual allocation reused a token freed on the same edge");
    concurrent_token0 = alloc0_token;
    concurrent_token1 = alloc1_token;
    @(posedge clk);
    #1;
    if (live_count != 6'd4 || live_mask[saved_token[0]] ||
        live_mask[saved_token[1]] || !live_mask[concurrent_token0] ||
        !live_mask[concurrent_token1])
      fail("dual alloc/free same-edge bitmap or count was not conserved");

    // Combine tagged frees, a STORE-only release mask and dual allocation.
    @(negedge clk);
    free0_token = concurrent_token0;
    free0_kind = 2'b00;
    free0_epoch = 2'b01;
    free1_token = concurrent_token1;
    free1_kind = 2'b10;
    free1_epoch = 2'b10;
    release_mask = 32'b0;
    release_mask[saved_token[2]] = 1'b1;
    release_mask[saved_token[3]] = 1'b1;
    alloc0_kind = 2'b01;
    alloc0_epoch = 2'b00;
    alloc1_kind = 2'b01;
    alloc1_epoch = 2'b01;
    #1;
    if (!free0_ready || !free1_ready || !alloc0_ready || !alloc1_ready)
      fail("alloc/free/STORE-release combined edge was not admitted");
    survivor_token0 = alloc0_token;
    survivor_token1 = alloc1_token;
    if (live_mask[survivor_token0] || live_mask[survivor_token1])
      fail("combined-edge allocation selected a pre-edge live token");
    @(posedge clk);
    #1;
    if (live_count != 6'd2 || !live_mask[survivor_token0] ||
        !live_mask[survivor_token1])
      fail("alloc/free/STORE-release combined edge broke bitmap/count conservation");
    @(negedge clk);
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    free0_valid = 1'b0;
    free1_valid = 1'b0;
    release_mask = live_mask;
    @(posedge clk);
    #1;
    if (live_count != 6'd0 || live_mask != 32'b0)
      fail("combined-edge survivors did not release cleanly");

    $display("[S2-G1-OWNER-GREEN][PASS] full/wrap/exact-free/no-ABA/popcount/STORE-mask");
    $finish;
  end
endmodule
