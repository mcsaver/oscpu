// OooDataWordCache 外部观测 checker。
// 只用于仿真/测试的 debug 层：读 ① 层真实信号，投影 common facts，并用立即断言审核接口语义。
`include "define.v"
`include "common/OooDataWordCacheFacts.vh"

module OooDataWordCacheChecker (
  input wire clk,
  input wire rst,

  input wire [`XLEN-1:0] req_lookup_addr_i,
  input wire [3:0] req_nbytes_i,
  input wire req_cacheable_i,
  input wire req_hit_i,
  input wire req_line_cross_i,

  input wire [`XLEN-1:0] walk_lookup_addr_i,
  input wire walk_cacheable_i,
  input wire walk_hit_i,

  input wire fill_valid_i,
  input wire [`XLEN-1:0] fill_addr_i,

  input wire store_commit_i,
  input wire store_invalidate_all_i,
  input wire [`XLEN-1:0] store_addr_i,
  input wire [`STRB_W-1:0] store_wstrb_i
);

  function cacheable_addr;
    input [`XLEN-1:0] addr;
    begin
      cacheable_addr = ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
    end
  endfunction

  function [3:0] nbytes_from_wstrb;
    input [`STRB_W-1:0] wstrb;
    integer i;
    begin
      nbytes_from_wstrb = 4'd0;
      for (i = 0; i < `STRB_W; i = i + 1) begin
        if (wstrb[i])
          nbytes_from_wstrb = nbytes_from_wstrb + 4'd1;
      end
      if (nbytes_from_wstrb == 4'd0)
        nbytes_from_wstrb = 4'd1;
    end
  endfunction

  wire req_nbytes_legal_w =
      (req_nbytes_i >= 4'd1) && (req_nbytes_i <= 4'd8);
  wire [4:0] req_window_end_w =
      {1'b0, req_lookup_addr_i[2:0]} + {1'b0, req_nbytes_i};
  wire req_line_cross_expect_w = req_window_end_w > 5'd8;

  wire [3:0] store_nbytes_w = nbytes_from_wstrb(store_wstrb_i);
  wire [4:0] store_window_end_w =
      {1'b0, store_addr_i[2:0]} + {1'b0, store_nbytes_w};
  wire store_line_cross_w = store_window_end_w > 5'd8;

  wire [`OOO_DWC_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_DWC_REQ_UNCACHED] =
      !cacheable_addr(req_lookup_addr_i);
  assign facts_w[`OOO_DWC_REQ_LINE_CROSS] = req_line_cross_i;
  assign facts_w[`OOO_DWC_REQ_HIT] = req_hit_i;
  assign facts_w[`OOO_DWC_REQ_MISS] =
      req_cacheable_i && (!req_hit_i || req_line_cross_i);
  assign facts_w[`OOO_DWC_WALK_HIT] = walk_hit_i;
  assign facts_w[`OOO_DWC_WALK_MISS] = walk_cacheable_i && !walk_hit_i;
  assign facts_w[`OOO_DWC_FILL] = fill_valid_i;
  assign facts_w[`OOO_DWC_STORE_COMMIT] = store_commit_i;
  assign facts_w[`OOO_DWC_STORE_LINE_CROSS] =
      store_commit_i && !store_invalidate_all_i && store_line_cross_w;
  assign facts_w[`OOO_DWC_INVALIDATE_ALL] = store_invalidate_all_i;

  wire _unused_facts_w =
      |facts_w | (|walk_lookup_addr_i) | (|fill_addr_i) |
      (|store_addr_i) | (|store_wstrb_i);

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst && !req_nbytes_legal_w) begin
      $error("[DWC-NBYTES] req_nbytes_i must be 1..8, got %0d @%0t",
             req_nbytes_i, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && (req_cacheable_i !== cacheable_addr(req_lookup_addr_i))) begin
      $error("[DWC-REQ-CACHEABLE] req_cacheable_o drift: addr=%h got=%b expect=%b @%0t",
             req_lookup_addr_i, req_cacheable_i,
             cacheable_addr(req_lookup_addr_i), $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && (walk_cacheable_i !== cacheable_addr(walk_lookup_addr_i))) begin
      $error("[DWC-WALK-CACHEABLE] walk_cacheable_o drift: addr=%h got=%b expect=%b @%0t",
             walk_lookup_addr_i, walk_cacheable_i,
             cacheable_addr(walk_lookup_addr_i), $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && (req_line_cross_i !== req_line_cross_expect_w)) begin
      $error("[DWC-LINE-CROSS] line-cross mismatch: addr=%h nbytes=%0d got=%b expect=%b @%0t",
             req_lookup_addr_i, req_nbytes_i, req_line_cross_i,
             req_line_cross_expect_w, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && req_hit_i && (!req_cacheable_i || req_line_cross_i)) begin
      $error("[DWC-HIT-GATE] hit requires cacheable and non-cross: addr=%h cacheable=%b cross=%b @%0t",
             req_lookup_addr_i, req_cacheable_i, req_line_cross_i, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && walk_hit_i && !walk_cacheable_i) begin
      $error("[DWC-WALK-HIT-GATE] PTW hit on uncacheable addr=%h @%0t",
             walk_lookup_addr_i, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && fill_valid_i &&
        (!cacheable_addr(fill_addr_i) || (fill_addr_i[2:0] != 3'b000))) begin
      $error("[DWC-FILL-ADDR] fill must be PMEM cacheable and 8B aligned: addr=%h @%0t",
             fill_addr_i, $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && store_invalidate_all_i && !store_commit_i) begin
      $error("[DWC-INVALL] invalidate_all must be attached to store_commit @%0t",
             $time);
      $fatal;
    end
  end
`endif

endmodule
