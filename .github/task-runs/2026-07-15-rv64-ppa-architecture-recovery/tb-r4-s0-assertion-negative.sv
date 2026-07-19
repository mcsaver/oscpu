`timescale 1ns/1ps
`include "define.v"

// Deliberate-violation drivers for the R4-S0 assertions.  These are not
// reachable-state claims: each force emulates precisely the stale/incorrect
// implementation that the production assertion is intended to reject.
module tb_r4_s0_posttranslate_assert_negative;
  reg clk;
  reg rst;
  reg access_valid;
  reg pma_fault;
  reg address_cacheable;
  reg pbmt_valid;
  reg [1:0] pbmt;
  wire pbmt_fault;
  wire cacheable;
  wire serialized;
  integer case_id;

  OooPostTranslateMemoryClass dut (
    .clk(clk),
    .rst(rst),
    .access_valid_i(access_valid),
    .pma_fault_i(pma_fault),
    .address_cacheable_i(address_cacheable),
    .pbmt_valid_i(pbmt_valid),
    .pbmt_i(pbmt),
    .pbmt_fault_o(pbmt_fault),
    .cacheable_o(cacheable),
    .serialized_o(serialized)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    if (!$value$plusargs("CASE=%d", case_id)) begin
      $display("[R4-S0-NEGATIVE-CONFIG] missing +CASE=<1|2|3>");
      $fatal;
    end

    rst = 1'b1;
    access_valid = 1'b0;
    pma_fault = 1'b0;
    address_cacheable = 1'b0;
    pbmt_valid = 1'b0;
    pbmt = 2'b00;
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    access_valid = 1'b1;

    case (case_id)
      1: begin
        // A stale independent serialized bit overlaps a legal cached result.
        address_cacheable = 1'b1;
        force dut.serialized_o = 1'b1;
        $display("[R4-S0-NEGATIVE-SETUP] case=EXCLUSIVE");
      end
      2: begin
        // A PBMT NC mapping is incorrectly admitted to D-cache.
        address_cacheable = 1'b1;
        pbmt_valid = 1'b1;
        pbmt = 2'b01;
        force dut.cacheable_o = 1'b1;
        $display("[R4-S0-NEGATIVE-SETUP] case=PBMT");
      end
      3: begin
        // A faulting access incorrectly retains a routing class.
        pma_fault = 1'b1;
        force dut.serialized_o = 1'b1;
        $display("[R4-S0-NEGATIVE-SETUP] case=FAULT");
      end
      default: begin
        $display("[R4-S0-NEGATIVE-CONFIG] unsupported case=%0d", case_id);
        $fatal;
      end
    endcase

    @(posedge clk);
    #1;
    release dut.cacheable_o;
    release dut.serialized_o;
    $display("[R4-S0-NEGATIVE-DONE] classifier_case=%0d", case_id);
    $finish;
  end
endmodule

module tb_r4_s0_dcache_invalidate_assert_negative;
  reg clk;
  reg rst;
  reg dma_invalidate_all;
  reg [`XLEN-1:0] req_lookup_addr;
  reg [3:0] req_nbytes;
  wire req_cacheable;
  wire req_line_cross;
  reg [`XLEN-1:0] walk_lookup_addr;
  wire walk_cacheable;
  reg lookup_en;
  reg [`XLEN-1:0] lookup_addr;
  wire lookup_hit;
  wire [`XLEN-1:0] lookup_line;
  reg fill_valid;
  reg [`XLEN-1:0] fill_addr;
  reg [`XLEN-1:0] fill_data;
  reg store_commit;
  reg store_rmw_en;
  reg store_cacheable;
  reg [`XLEN-1:0] store_addr;
  reg [`XLEN-1:0] store_wdata;
  reg [`STRB_W-1:0] store_wstrb;
  wire rmw_busy;

  OooDataWordCache dut (
    .clk(clk),
    .rst(rst),
    .dma_invalidate_all_i(dma_invalidate_all),
    .req_lookup_addr_i(req_lookup_addr),
    .req_nbytes_i(req_nbytes),
    .req_cacheable_o(req_cacheable),
    .req_line_cross_o(req_line_cross),
    .walk_lookup_addr_i(walk_lookup_addr),
    .walk_cacheable_o(walk_cacheable),
    .lookup_en_i(lookup_en),
    .lookup_addr_i(lookup_addr),
    .lookup_hit_o(lookup_hit),
    .lookup_line_o(lookup_line),
    .fill_valid_i(fill_valid),
    .fill_addr_i(fill_addr),
    .fill_data_i(fill_data),
    .store_commit_i(store_commit),
    .store_rmw_en_i(store_rmw_en),
    .store_cacheable_i(store_cacheable),
    .store_addr_i(store_addr),
    .store_wdata_i(store_wdata),
    .store_wstrb_i(store_wstrb),
    .rmw_busy_o(rmw_busy)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1'b1;
    dma_invalidate_all = 1'b0;
    req_lookup_addr = 64'h0000_0000_8000_0000;
    req_nbytes = 4'd8;
    walk_lookup_addr = 64'h0000_0000_8000_0000;
    lookup_en = 1'b0;
    lookup_addr = 64'h0000_0000_8000_0000;
    fill_valid = 1'b0;
    fill_addr = 64'h0000_0000_8000_0000;
    fill_data = 64'h0;
    store_commit = 1'b0;
    store_rmw_en = 1'b0;
    store_cacheable = 1'b0;
    store_addr = 64'h0000_0000_8000_0000;
    store_wdata = 64'h0;
    store_wstrb = 8'hff;

    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    store_commit = 1'b1;
    $display("[R4-S0-NEGATIVE-SETUP] case=DWC_INVALIDATE index=0");
    @(posedge clk);
    #1;
    store_commit = 1'b0;
    // Emulate a broken valid-bit update after an invalidate-class terminal.
    force dut.valid_q[0] = 1'b1;
    @(posedge clk);
    #1;
    // A correct assertion must have terminated the simulation before here.
    $display("[R4-S0-NEGATIVE-MISSED] DWC assertion did not fire");
    release dut.valid_q[0];
    $finish;
  end
endmodule
