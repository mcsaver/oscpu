`include "define.v"

// V11K focused evidence for the two production OooMemInflightQueue instances
// in OooIntBackend.  Expected tuples and masks are fixed by the stimulus
// schedule; no DUT holder or query signal is used to construct expectations.
module tb_ooo_dual_mem_inflight_queue_semantic;
  localparam ENTRY_N = 4;
  localparam ENTRY_W = 2;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W;
  localparam [1:0] KIND_LOAD = 2'd0;
  localparam [1:0] KIND_PROBE = 2'd1;
  localparam [1:0] KIND_DRAIN = 2'd2;

  reg clk;
  reg rst;
  reg flush_i;
  reg kill_valid_i;
  reg [ROB_INDEX_W-1:0] kill_rob_idx_i;
  reg [ROB_INDEX_W-1:0] rob_head_idx_i;

  reg lane0_push_valid_i;
  reg [1:0] lane0_push_kind_i;
  reg [1:0] lane0_push_owner_kind_i;
  reg [4:0] lane0_push_owner_token_i;
  reg [1:0] lane0_push_mmu_epoch_i;
  reg [`XLEN-1:0] lane0_push_fault_tval_i;
  reg [ROB_INDEX_W-1:0] lane0_push_rob_idx_i;
  reg lane0_pop_valid_i;
  reg [1:0] lane0_pop_owner_kind_i;
  reg [4:0] lane0_pop_owner_token_i;
  reg [1:0] lane0_pop_mmu_epoch_i;
  reg [`XLEN-1:0] lane0_pop_fault_tval_i;
  wire lane0_pop_owner_match_o;
  wire lane0_head_valid_o;
  wire [1:0] lane0_head_kind_o;
  wire [1:0] lane0_head_owner_kind_o;
  wire [4:0] lane0_head_owner_token_o;
  wire [1:0] lane0_head_mmu_epoch_o;
  wire [`XLEN-1:0] lane0_head_fault_tval_o;
  wire lane0_head_killed_o;
  wire [ENTRY_W:0] lane0_count_o;
  wire [31:0] lane0_occupancy_token_mask_o;

  reg lane1_push_valid_i;
  reg [1:0] lane1_push_kind_i;
  reg [1:0] lane1_push_owner_kind_i;
  reg [4:0] lane1_push_owner_token_i;
  reg [1:0] lane1_push_mmu_epoch_i;
  reg [`XLEN-1:0] lane1_push_fault_tval_i;
  reg [ROB_INDEX_W-1:0] lane1_push_rob_idx_i;
  reg lane1_pop_valid_i;
  reg [1:0] lane1_pop_owner_kind_i;
  reg [4:0] lane1_pop_owner_token_i;
  reg [1:0] lane1_pop_mmu_epoch_i;
  reg [`XLEN-1:0] lane1_pop_fault_tval_i;
  wire lane1_pop_owner_match_o;
  wire lane1_head_valid_o;
  wire [1:0] lane1_head_kind_o;
  wire [1:0] lane1_head_owner_kind_o;
  wire [4:0] lane1_head_owner_token_o;
  wire [1:0] lane1_head_mmu_epoch_o;
  wire [`XLEN-1:0] lane1_head_fault_tval_o;
  wire lane1_head_killed_o;
  wire [ENTRY_W:0] lane1_count_o;
  wire [31:0] lane1_occupancy_token_mask_o;

  OooMemInflightQueue #(
    .ENTRY_N(ENTRY_N),
    .ENTRY_W(ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_mem_inflight_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .push_valid_i(lane0_push_valid_i),
    .push_kind_i(lane0_push_kind_i),
    .push_owner_kind_i(lane0_push_owner_kind_i),
    .push_owner_token_i(lane0_push_owner_token_i),
    .push_mmu_epoch_i(lane0_push_mmu_epoch_i),
    .push_fault_tval_i(lane0_push_fault_tval_i),
    .push_rob_idx_i(lane0_push_rob_idx_i),
    .push_pdest_i({PHY_REG_ADDR_W{1'b0}}),
    .push_pdest_fp_i(1'b0),
    .push_size_i(2'b11),
    .push_unsigned_i(1'b0),
    .push_eff_addr_i(64'h0000_0000_8000_1000),
    .push_wdata_i({`XLEN{1'b0}}),
    .push_wstrb_i({`STRB_W{1'b0}}),
    .pop_valid_i(lane0_pop_valid_i),
    .pop_owner_kind_i(lane0_pop_owner_kind_i),
    .pop_owner_token_i(lane0_pop_owner_token_i),
    .pop_mmu_epoch_i(lane0_pop_mmu_epoch_i),
    .pop_fault_tval_i(lane0_pop_fault_tval_i),
    .pop_owner_match_o(lane0_pop_owner_match_o),
    .pop_tval_echo_match_o(),
    .kill_valid_i(kill_valid_i),
    .kill_rob_idx_i(kill_rob_idx_i),
    .rob_head_idx_i(rob_head_idx_i),
    .head_valid_o(lane0_head_valid_o),
    .head_kind_o(lane0_head_kind_o),
    .head_owner_kind_o(lane0_head_owner_kind_o),
    .head_owner_token_o(lane0_head_owner_token_o),
    .head_mmu_epoch_o(lane0_head_mmu_epoch_o),
    .head_fault_tval_o(lane0_head_fault_tval_o),
    .head_killed_o(lane0_head_killed_o),
    .head_effective_killed_o(),
    .head_rob_idx_o(),
    .head_pdest_o(),
    .head_pdest_fp_o(),
    .head_size_o(),
    .head_unsigned_o(),
    .head_eff_addr_o(),
    .head_wdata_o(),
    .head_wstrb_o(),
    .next_head_valid_o(),
    .next_head_kind_o(),
    .next_head_owner_kind_o(),
    .next_head_owner_token_o(),
    .next_head_mmu_epoch_o(),
    .next_head_fault_tval_o(),
    .next_head_killed_o(),
    .next_head_effective_killed_o(),
    .next_head_rob_idx_o(),
    .count_o(lane0_count_o),
    .empty_o(),
    .full_o(),
    .occupancy_token_mask_o(lane0_occupancy_token_mask_o),
    .entry_valid_o(),
    .entry_kind_o(),
    .entry_rob_idx_o(),
    .entry_addr_o()
  );

  OooMemInflightQueue #(
    .ENTRY_N(ENTRY_N),
    .ENTRY_W(ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_mem1_inflight_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .push_valid_i(lane1_push_valid_i),
    .push_kind_i(lane1_push_kind_i),
    .push_owner_kind_i(lane1_push_owner_kind_i),
    .push_owner_token_i(lane1_push_owner_token_i),
    .push_mmu_epoch_i(lane1_push_mmu_epoch_i),
    .push_fault_tval_i(lane1_push_fault_tval_i),
    .push_rob_idx_i(lane1_push_rob_idx_i),
    .push_pdest_i({PHY_REG_ADDR_W{1'b0}}),
    .push_pdest_fp_i(1'b0),
    .push_size_i(2'b11),
    .push_unsigned_i(1'b0),
    .push_eff_addr_i(64'h0000_0000_8000_2000),
    .push_wdata_i({`XLEN{1'b0}}),
    .push_wstrb_i({`STRB_W{1'b0}}),
    .pop_valid_i(lane1_pop_valid_i),
    .pop_owner_kind_i(lane1_pop_owner_kind_i),
    .pop_owner_token_i(lane1_pop_owner_token_i),
    .pop_mmu_epoch_i(lane1_pop_mmu_epoch_i),
    .pop_fault_tval_i(lane1_pop_fault_tval_i),
    .pop_owner_match_o(lane1_pop_owner_match_o),
    .pop_tval_echo_match_o(),
    .kill_valid_i(kill_valid_i),
    .kill_rob_idx_i(kill_rob_idx_i),
    .rob_head_idx_i(rob_head_idx_i),
    .head_valid_o(lane1_head_valid_o),
    .head_kind_o(lane1_head_kind_o),
    .head_owner_kind_o(lane1_head_owner_kind_o),
    .head_owner_token_o(lane1_head_owner_token_o),
    .head_mmu_epoch_o(lane1_head_mmu_epoch_o),
    .head_fault_tval_o(lane1_head_fault_tval_o),
    .head_killed_o(lane1_head_killed_o),
    .head_effective_killed_o(),
    .head_rob_idx_o(),
    .head_pdest_o(),
    .head_pdest_fp_o(),
    .head_size_o(),
    .head_unsigned_o(),
    .head_eff_addr_o(),
    .head_wdata_o(),
    .head_wstrb_o(),
    .next_head_valid_o(),
    .next_head_kind_o(),
    .next_head_owner_kind_o(),
    .next_head_owner_token_o(),
    .next_head_mmu_epoch_o(),
    .next_head_fault_tval_o(),
    .next_head_killed_o(),
    .next_head_effective_killed_o(),
    .next_head_rob_idx_o(),
    .count_o(lane1_count_o),
    .empty_o(),
    .full_o(),
    .occupancy_token_mask_o(lane1_occupancy_token_mask_o),
    .entry_valid_o(),
    .entry_kind_o(),
    .entry_rob_idx_o(),
    .entry_addr_o()
  );

  always #5 clk = ~clk;

  task automatic oracle_fail(input string message);
    begin
      $display("[V11K-MIQ-HOLDER-ORACLE][FAIL] %s @%0t", message, $time);
      $fatal(1);
    end
  endtask

  task automatic apply_edge;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic clear_events;
    begin
      flush_i = 1'b0;
      kill_valid_i = 1'b0;
      lane0_push_valid_i = 1'b0;
      lane0_pop_valid_i = 1'b0;
      lane1_push_valid_i = 1'b0;
      lane1_pop_valid_i = 1'b0;
    end
  endtask

  task automatic check_lane0(
    input [ENTRY_W:0] expected_count,
    input expected_valid,
    input [1:0] expected_kind,
    input [1:0] expected_owner_kind,
    input [4:0] expected_owner_token,
    input [1:0] expected_epoch,
    input [`XLEN-1:0] expected_tval,
    input expected_killed,
    input [31:0] expected_mask
  );
    begin
      if (lane0_count_o !== expected_count)
        oracle_fail("lane0 count");
`ifdef V11K_TUPLE_MARKER_PROBE
      // Let the production assertion observe an injected X/Z tuple.
`elsif V11K_STABLE_MARKER_PROBE
      // Let the production assertion observe an injected stall drift.
`else
      if (lane0_head_valid_o !== expected_valid)
        oracle_fail("lane0 head valid");
      if (expected_valid &&
          ({lane0_head_kind_o, lane0_head_owner_kind_o,
            lane0_head_owner_token_o, lane0_head_mmu_epoch_o,
            lane0_head_fault_tval_o, lane0_head_killed_o} !==
           {expected_kind, expected_owner_kind, expected_owner_token,
            expected_epoch, expected_tval, expected_killed}))
        oracle_fail("lane0 head tuple");
      if (lane0_occupancy_token_mask_o !== expected_mask)
        oracle_fail("lane0 occupancy token set");
`endif
    end
  endtask

  task automatic check_lane1(
    input [ENTRY_W:0] expected_count,
    input expected_valid,
    input [1:0] expected_kind,
    input [1:0] expected_owner_kind,
    input [4:0] expected_owner_token,
    input [1:0] expected_epoch,
    input [`XLEN-1:0] expected_tval,
    input expected_killed,
    input [31:0] expected_mask
  );
    begin
      if (lane1_count_o !== expected_count)
        oracle_fail("lane1 count");
`ifdef V11K_TUPLE_MARKER_PROBE
      // Let the production assertion observe an injected X/Z tuple.
`elsif V11K_STABLE_MARKER_PROBE
      // Let the production assertion observe an injected stall drift.
`else
      if (lane1_head_valid_o !== expected_valid)
        oracle_fail("lane1 head valid");
      if (expected_valid &&
          ({lane1_head_kind_o, lane1_head_owner_kind_o,
            lane1_head_owner_token_o, lane1_head_mmu_epoch_o,
            lane1_head_fault_tval_o, lane1_head_killed_o} !==
           {expected_kind, expected_owner_kind, expected_owner_token,
            expected_epoch, expected_tval, expected_killed}))
        oracle_fail("lane1 head tuple");
      if (lane1_occupancy_token_mask_o !== expected_mask)
        oracle_fail("lane1 occupancy token set");
`endif
    end
  endtask

  task automatic run_push_tuple_probe(input drive_z);
    begin
      lane0_push_valid_i = 1'b1;
      lane0_push_kind_i = KIND_LOAD;
      lane0_push_fault_tval_i = 64'h0000_0000_8000_7008;
      lane0_push_rob_idx_i = 5'd7;
      if (drive_z) begin
        lane0_push_owner_kind_i = 2'bzz;
        lane0_push_owner_token_i = {5{1'bz}};
        lane0_push_mmu_epoch_i = 2'bzz;
      end else begin
        lane0_push_owner_kind_i = 2'bxx;
        lane0_push_owner_token_i = {5{1'bx}};
        lane0_push_mmu_epoch_i = 2'bxx;
      end
      apply_edge();
`ifdef OOO_ASSERT
      oracle_fail("accepted push X/Z tuple did not trigger assertion");
`else
      clear_events();
      if (lane0_count_o !== 3'd0 ||
          lane0_head_valid_o !== 1'b0 ||
          lane0_occupancy_token_mask_o !== 32'b0)
        oracle_fail("release accepted an X/Z push owner tuple");
      $display("[V11K-MIQ-PUSH-TUPLE-FAIL-CLOSED][PASS]");
      $finish;
`endif
    end
  endtask

  task automatic run_pop_tuple_probe(input drive_z);
    begin
      lane0_push_valid_i = 1'b1;
      lane0_push_kind_i = KIND_LOAD;
      lane0_push_owner_kind_i = 2'b00;
      lane0_push_owner_token_i = 5'd3;
      lane0_push_mmu_epoch_i = 2'b01;
      lane0_push_fault_tval_i = 64'h0000_0000_8000_3008;
      lane0_push_rob_idx_i = 5'd3;
      apply_edge();
      clear_events();
      check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd3, 2'b01,
                  64'h0000_0000_8000_3008, 1'b0, 32'h0000_0008);

      lane0_pop_valid_i = 1'b1;
      lane0_pop_fault_tval_i = 64'h0000_0000_8000_3008;
      if (drive_z) begin
        lane0_pop_owner_kind_i = 2'bzz;
        lane0_pop_owner_token_i = {5{1'bz}};
        lane0_pop_mmu_epoch_i = 2'bzz;
      end else begin
        lane0_pop_owner_kind_i = 2'bxx;
        lane0_pop_owner_token_i = {5{1'bx}};
        lane0_pop_mmu_epoch_i = 2'bxx;
      end
      apply_edge();
`ifdef OOO_ASSERT
      oracle_fail("valid-head pop X/Z tuple did not trigger assertion");
`else
      clear_events();
      check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd3, 2'b01,
                  64'h0000_0000_8000_3008, 1'b0, 32'h0000_0008);
      $display("[V11K-MIQ-POP-TUPLE-FAIL-CLOSED][PASS]");
      $finish;
`endif
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    flush_i = 1'b0;
    kill_valid_i = 1'b0;
    kill_rob_idx_i = {ROB_INDEX_W{1'b0}};
    rob_head_idx_i = {ROB_INDEX_W{1'b0}};
    lane0_push_valid_i = 1'b0;
    lane0_push_kind_i = KIND_LOAD;
    lane0_push_owner_kind_i = 2'b00;
    lane0_push_owner_token_i = 5'd0;
    lane0_push_mmu_epoch_i = 2'b00;
    lane0_push_fault_tval_i = {`XLEN{1'b0}};
    lane0_push_rob_idx_i = {ROB_INDEX_W{1'b0}};
    lane0_pop_valid_i = 1'b0;
    lane0_pop_owner_kind_i = 2'b00;
    lane0_pop_owner_token_i = 5'd0;
    lane0_pop_mmu_epoch_i = 2'b00;
    lane0_pop_fault_tval_i = {`XLEN{1'b0}};
    lane1_push_valid_i = 1'b0;
    lane1_push_kind_i = KIND_LOAD;
    lane1_push_owner_kind_i = 2'b00;
    lane1_push_owner_token_i = 5'd0;
    lane1_push_mmu_epoch_i = 2'b00;
    lane1_push_fault_tval_i = {`XLEN{1'b0}};
    lane1_push_rob_idx_i = {ROB_INDEX_W{1'b0}};
    lane1_pop_valid_i = 1'b0;
    lane1_pop_owner_kind_i = 2'b00;
    lane1_pop_owner_token_i = 5'd0;
    lane1_pop_mmu_epoch_i = 2'b00;
    lane1_pop_fault_tval_i = {`XLEN{1'b0}};

    repeat (3) apply_edge();
    rst = 1'b0;
    apply_edge();

`ifdef V11K_PUSH_TUPLE_X_PROBE
    run_push_tuple_probe(1'b0);
`elsif V11K_PUSH_TUPLE_Z_PROBE
    run_push_tuple_probe(1'b1);
`elsif V11K_POP_TUPLE_X_PROBE
    run_pop_tuple_probe(1'b0);
`elsif V11K_POP_TUPLE_Z_PROBE
    run_pop_tuple_probe(1'b1);
`endif

    // Same ROB index, distinct owner tuples, one entry in each product lane.
    lane0_push_valid_i = 1'b1;
    lane0_push_kind_i = KIND_LOAD;
    lane0_push_owner_kind_i = 2'b00;
    lane0_push_owner_token_i = 5'd5;
    lane0_push_mmu_epoch_i = 2'b01;
    lane0_push_fault_tval_i = 64'h0000_0000_8000_1008;
    lane0_push_rob_idx_i = 5'd6;
    lane1_push_valid_i = 1'b1;
    lane1_push_kind_i = KIND_PROBE;
    lane1_push_owner_kind_i = 2'b01;
    lane1_push_owner_token_i = 5'd9;
    lane1_push_mmu_epoch_i = 2'b10;
    lane1_push_fault_tval_i = 64'h0000_0000_8000_2008;
    lane1_push_rob_idx_i = 5'd6;
    apply_edge();
    clear_events();
    check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd5, 2'b01,
                64'h0000_0000_8000_1008, 1'b0, 32'h0000_0020);
    check_lane1(3'd1, 1'b1, KIND_PROBE, 2'b01, 5'd9, 2'b10,
                64'h0000_0000_8000_2008, 1'b0, 32'h0000_0200);

    repeat (3) begin
      apply_edge();
      check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd5, 2'b01,
                  64'h0000_0000_8000_1008, 1'b0, 32'h0000_0020);
      check_lane1(3'd1, 1'b1, KIND_PROBE, 2'b01, 5'd9, 2'b10,
                  64'h0000_0000_8000_2008, 1'b0, 32'h0000_0200);
    end
    $display("[V11K-MIQ-DUAL-CAPTURE-HOLD] same-ROB distinct tuples stable PASS");

    // Swap the complete tuples.  Neither FIFO head may identify the other
    // lane's response.
    lane0_pop_owner_kind_i = 2'b01;
    lane0_pop_owner_token_i = 5'd9;
    lane0_pop_mmu_epoch_i = 2'b10;
    lane0_pop_fault_tval_i = 64'h0000_0000_8000_2008;
    lane1_pop_owner_kind_i = 2'b00;
    lane1_pop_owner_token_i = 5'd5;
    lane1_pop_mmu_epoch_i = 2'b01;
    lane1_pop_fault_tval_i = 64'h0000_0000_8000_1008;
    #1;
    if (lane0_pop_owner_match_o !== 1'b0 ||
        lane1_pop_owner_match_o !== 1'b0)
      oracle_fail("cross-lane tuple matched");
    $display("[V11K-MIQ-DUAL-CROSS-REJECT] swapped tuples rejected PASS");

`ifdef V11K_ASSERT_CROSS_POP
    lane0_pop_valid_i = 1'b1;
    lane1_pop_valid_i = 1'b1;
    apply_edge();
    oracle_fail("assert configuration accepted swapped tuple");
`else
`ifndef OOO_ASSERT
    lane0_pop_valid_i = 1'b1;
    lane1_pop_valid_i = 1'b1;
    apply_edge();
    clear_events();
    check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd5, 2'b01,
                64'h0000_0000_8000_1008, 1'b0, 32'h0000_0020);
    check_lane1(3'd1, 1'b1, KIND_PROBE, 2'b01, 5'd9, 2'b10,
                64'h0000_0000_8000_2008, 1'b0, 32'h0000_0200);
`endif
`endif

    lane0_pop_owner_kind_i = 2'b00;
    lane0_pop_owner_token_i = 5'd5;
    lane0_pop_mmu_epoch_i = 2'b01;
    lane0_pop_fault_tval_i = 64'h0000_0000_8000_1008;
    lane1_pop_owner_kind_i = 2'b01;
    lane1_pop_owner_token_i = 5'd9;
    lane1_pop_mmu_epoch_i = 2'b10;
    lane1_pop_fault_tval_i = 64'h0000_0000_8000_2008;
    lane0_pop_valid_i = 1'b1;
    lane1_pop_valid_i = 1'b1;
    apply_edge();
    clear_events();
    check_lane0(3'd0, 1'b0, 2'b00, 2'b00, 5'd0, 2'b00,
                64'b0, 1'b0, 32'b0);
    check_lane1(3'd0, 1'b0, 2'b00, 2'b00, 5'd0, 2'b00,
                64'b0, 1'b0, 32'b0);

    // Opposite queue order: lane0 load→drain, lane1 drain→load.  Global
    // flush must retain only each lane's own DRAIN and preserve its tuple.
    lane0_push_valid_i = 1'b1;
    lane0_push_kind_i = KIND_LOAD;
    lane0_push_owner_kind_i = 2'b00;
    lane0_push_owner_token_i = 5'd6;
    lane0_push_mmu_epoch_i = 2'b00;
    lane0_push_fault_tval_i = 64'h1010;
    lane0_push_rob_idx_i = 5'd7;
    lane1_push_valid_i = 1'b1;
    lane1_push_kind_i = KIND_DRAIN;
    lane1_push_owner_kind_i = 2'b01;
    lane1_push_owner_token_i = 5'd10;
    lane1_push_mmu_epoch_i = 2'b10;
    lane1_push_fault_tval_i = 64'h2020;
    lane1_push_rob_idx_i = 5'd7;
    apply_edge();

    lane0_push_kind_i = KIND_DRAIN;
    lane0_push_owner_kind_i = 2'b01;
    lane0_push_owner_token_i = 5'd7;
    lane0_push_mmu_epoch_i = 2'b01;
    lane0_push_fault_tval_i = 64'h3030;
    lane0_push_rob_idx_i = 5'd8;
    lane1_push_kind_i = KIND_LOAD;
    lane1_push_owner_kind_i = 2'b00;
    lane1_push_owner_token_i = 5'd11;
    lane1_push_mmu_epoch_i = 2'b11;
    lane1_push_fault_tval_i = 64'h4040;
    lane1_push_rob_idx_i = 5'd8;
    apply_edge();
    clear_events();
    check_lane0(3'd2, 1'b1, KIND_LOAD, 2'b00, 5'd6, 2'b00,
                64'h1010, 1'b0, 32'h0000_00c0);
    check_lane1(3'd2, 1'b1, KIND_DRAIN, 2'b01, 5'd10, 2'b10,
                64'h2020, 1'b0, 32'h0000_0c00);

    flush_i = 1'b1;
    apply_edge();
    clear_events();
    check_lane0(3'd1, 1'b1, KIND_DRAIN, 2'b01, 5'd7, 2'b01,
                64'h3030, 1'b0, 32'h0000_0080);
    check_lane1(3'd1, 1'b1, KIND_DRAIN, 2'b01, 5'd10, 2'b10,
                64'h2020, 1'b0, 32'h0000_0400);
    repeat (2) begin
      apply_edge();
      check_lane0(3'd1, 1'b1, KIND_DRAIN, 2'b01, 5'd7, 2'b01,
                  64'h3030, 1'b0, 32'h0000_0080);
      check_lane1(3'd1, 1'b1, KIND_DRAIN, 2'b01, 5'd10, 2'b10,
                  64'h2020, 1'b0, 32'h0000_0400);
    end

    lane0_pop_owner_kind_i = 2'b01;
    lane0_pop_owner_token_i = 5'd7;
    lane0_pop_mmu_epoch_i = 2'b01;
    lane0_pop_fault_tval_i = 64'h3030;
    lane1_pop_owner_kind_i = 2'b01;
    lane1_pop_owner_token_i = 5'd10;
    lane1_pop_mmu_epoch_i = 2'b10;
    lane1_pop_fault_tval_i = 64'h2020;
    lane0_pop_valid_i = 1'b1;
    lane1_pop_valid_i = 1'b1;
    apply_edge();
    clear_events();

    // One shared ROB-walk boundary must classify the two lane heads
    // independently: ROB6 survives while ROB10 is marked killed.
    lane0_push_valid_i = 1'b1;
    lane0_push_kind_i = KIND_LOAD;
    lane0_push_owner_kind_i = 2'b00;
    lane0_push_owner_token_i = 5'd12;
    lane0_push_mmu_epoch_i = 2'b00;
    lane0_push_fault_tval_i = 64'h5050;
    lane0_push_rob_idx_i = 5'd6;
    lane1_push_valid_i = 1'b1;
    lane1_push_kind_i = KIND_PROBE;
    lane1_push_owner_kind_i = 2'b01;
    lane1_push_owner_token_i = 5'd13;
    lane1_push_mmu_epoch_i = 2'b11;
    lane1_push_fault_tval_i = 64'h6060;
    lane1_push_rob_idx_i = 5'd10;
    apply_edge();
    clear_events();
    kill_valid_i = 1'b1;
    kill_rob_idx_i = 5'd8;
    rob_head_idx_i = 5'd0;
    apply_edge();
    clear_events();
    check_lane0(3'd1, 1'b1, KIND_LOAD, 2'b00, 5'd12, 2'b00,
                64'h5050, 1'b0, 32'h0000_1000);
    check_lane1(3'd1, 1'b1, KIND_PROBE, 2'b01, 5'd13, 2'b11,
                64'h6060, 1'b1, 32'h0000_2000);

    lane0_pop_owner_kind_i = 2'b00;
    lane0_pop_owner_token_i = 5'd12;
    lane0_pop_mmu_epoch_i = 2'b00;
    lane0_pop_fault_tval_i = 64'h5050;
    lane1_pop_owner_kind_i = 2'b01;
    lane1_pop_owner_token_i = 5'd13;
    lane1_pop_mmu_epoch_i = 2'b11;
    lane1_pop_fault_tval_i = 64'h6060;
    lane0_pop_valid_i = 1'b1;
    lane1_pop_valid_i = 1'b1;
    apply_edge();
    clear_events();
    check_lane0(3'd0, 1'b0, 2'b00, 2'b00, 5'd0, 2'b00,
                64'b0, 1'b0, 32'b0);
    check_lane1(3'd0, 1'b0, 2'b00, 2'b00, 5'd0, 2'b00,
                64'b0, 1'b0, 32'b0);

    $display("[V11K-MIQ-DUAL-FLUSH-KILL] per-lane survivor and kill identity PASS");
    $display("[V11K-MIQ-EXACTLY-ONCE] exact tuple consumes each owner once PASS");
`ifdef V11K_NEGATIVE_PROFILE
    $display("[V11K-MIQ-NEGATIVE-ESCAPED][FAIL] injected holder defect reached PASS");
    $fatal(1);
`else
    $display("[V11K-MIQ-HOLDER-MATRIX][PASS]");
    $display("[PASS] tb_ooo_dual_mem_inflight_queue_semantic");
    $finish;
`endif
  end
endmodule
