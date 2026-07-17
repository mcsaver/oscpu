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
  parameter [KIND_W-1:0] OWNER_KIND_STORE = 2'b01,
  parameter [KIND_W-1:0] OWNER_KIND_RESERVED = 2'b11
) (
  input clk,
  input rst,

  input alloc0_valid_i,
  input [KIND_W-1:0] alloc0_kind_i,
  input [EPOCH_W-1:0] alloc0_epoch_i,
  output alloc0_ready_o,
  output [TOKEN_W-1:0] alloc0_token_o,

  input alloc1_valid_i,
  input [KIND_W-1:0] alloc1_kind_i,
  input [EPOCH_W-1:0] alloc1_epoch_i,
  output alloc1_ready_o,
  output [TOKEN_W-1:0] alloc1_token_o,

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
  output [COUNT_W-1:0] live_count_o
);

  localparam integer PARAM_SHAPE_VALID =
      (TOKEN_COUNT == (1 << TOKEN_W)) && ((1 << COUNT_W) > TOKEN_COUNT);

  reg [TOKEN_COUNT-1:0] live_q;
  reg [KIND_W-1:0] kind_q [0:TOKEN_COUNT-1];
  reg [EPOCH_W-1:0] epoch_q [0:TOKEN_COUNT-1];
  reg [TOKEN_W-1:0] next_token_q;

  reg alloc0_found_r;
  reg [TOKEN_W-1:0] alloc0_token_r;
  reg alloc1_found_r;
  reg [TOKEN_W-1:0] alloc1_token_r;
  reg [TOKEN_COUNT-1:0] store_live_mask_r;
  reg [TOKEN_COUNT-1:0] live_next_r;
  reg [COUNT_W-1:0] live_count_r;
  integer scan_i;
  integer count_i;

  wire alloc0_fire_w = alloc0_valid_i && alloc0_ready_o;
  wire alloc1_fire_w = alloc1_valid_i && alloc1_ready_o;
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

  always @(*) begin
    alloc0_found_r = 1'b0;
    alloc0_token_r = next_token_q;
    for (scan_i = 0; scan_i < TOKEN_COUNT; scan_i = scan_i + 1) begin
      if (!alloc0_found_r && !live_q[token_at_offset(next_token_q, scan_i)]) begin
        alloc0_found_r = 1'b1;
        alloc0_token_r = token_at_offset(next_token_q, scan_i);
      end
    end

    alloc1_found_r = 1'b0;
    alloc1_token_r = next_token_q;
    for (scan_i = 0; scan_i < TOKEN_COUNT; scan_i = scan_i + 1) begin
      if (!alloc1_found_r && !live_q[token_at_offset(next_token_q, scan_i)] &&
          !(alloc0_fire_w &&
            (token_at_offset(next_token_q, scan_i) == alloc0_token_r))) begin
        alloc1_found_r = 1'b1;
        alloc1_token_r = token_at_offset(next_token_q, scan_i);
      end
    end

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
    live_next_r = live_q & ~release_effective_w;
    if (free0_fire_w)
      live_next_r[free0_token_i] = 1'b0;
    if (free1_fire_w)
      live_next_r[free1_token_i] = 1'b0;
    if (alloc0_fire_w)
      live_next_r[alloc0_token_o] = 1'b1;
    if (alloc1_fire_w)
      live_next_r[alloc1_token_o] = 1'b1;
  end

  assign alloc0_ready_o = PARAM_SHAPE_VALID && alloc0_found_r &&
      (alloc0_kind_i != OWNER_KIND_RESERVED);
  assign alloc0_token_o = alloc0_token_r;
  assign alloc1_ready_o = PARAM_SHAPE_VALID && alloc1_found_r &&
      (alloc1_kind_i != OWNER_KIND_RESERVED);
  assign alloc1_token_o = alloc1_token_r;
  assign free0_ready_o = free0_exact_w &&
      !release_effective_w[free0_token_i];
  assign free1_ready_o = free1_exact_w &&
      !release_effective_w[free1_token_i] && !free1_same_as_free0_w;
  assign live_mask_o = live_q;
  assign live_count_o = live_count_r;

  genvar metadata_i;
  generate
    for (metadata_i = 0; metadata_i < TOKEN_COUNT;
         metadata_i = metadata_i + 1) begin : gen_metadata_view
      assign kind_table_o[metadata_i*KIND_W +: KIND_W] = kind_q[metadata_i];
      assign epoch_table_o[metadata_i*EPOCH_W +: EPOCH_W] = epoch_q[metadata_i];
    end
  endgenerate

  integer state_i;
  always @(posedge clk) begin
    if (rst) begin
      live_q <= {TOKEN_COUNT{1'b0}};
      next_token_q <= {TOKEN_W{1'b0}};
      for (state_i = 0; state_i < TOKEN_COUNT; state_i = state_i + 1) begin
        kind_q[state_i] <= {KIND_W{1'b0}};
        epoch_q[state_i] <= {EPOCH_W{1'b0}};
      end
    end else begin
      live_q <= live_next_r;

      if (alloc0_fire_w) begin
        kind_q[alloc0_token_o] <= alloc0_kind_i;
        epoch_q[alloc0_token_o] <= alloc0_epoch_i;
      end
      if (alloc1_fire_w) begin
        kind_q[alloc1_token_o] <= alloc1_kind_i;
        epoch_q[alloc1_token_o] <= alloc1_epoch_i;
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
  wire [COUNT_W-1:0] release_count_w = popcount_live(release_effective_w);
  always @(posedge clk) begin
    if (rst) begin
      conservation_check_q <= 1'b0;
      conservation_expected_q <= {COUNT_W{1'b0}};
    end else begin
      if (conservation_check_q &&
          (live_count_o !== conservation_expected_q)) begin
        $display("[OOO-MEM-OWNER] event algebra count=%0d expected=%0d",
                 live_count_o, conservation_expected_q);
        $fatal;
      end
      conservation_check_q <= 1'b1;
      conservation_expected_q <= live_count_o + alloc0_fire_w + alloc1_fire_w -
          free0_fire_w - free1_fire_w - release_count_w;
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
    end
  end
`endif

endmodule
