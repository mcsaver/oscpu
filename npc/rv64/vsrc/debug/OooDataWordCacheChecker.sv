// OooDataWordCache 外部观测 checker。
// 只用于仿真/测试的 debug 层：读 ① 层真实信号，投影 common facts，并用立即断言审核接口语义。
// 【SRAM 同步读】单读口两拍协议下, hit 类断言以"判决拍针对上拍锁存地址"为参照系
// (checker 自带一份发射拍锁存), 原 DWC-HIT-GATE/DWC-WALK-HIT-GATE 两个同拍断言
// 随 req/walk 读口合并为单 lookup 口而合一为打拍版; 纯地址组合断言
// (REQ-CACHEABLE/WALK-CACHEABLE/LINE-CROSS)保持同拍不变。
// 【store RMW】真 store commit 走 2 拍 RMW: checker 自带 pend 模型审核
// rmw_busy 恰为 commit 次拍(DWC-RMW-BUSY), 且 RMW 两拍窗口内宏口不得被
// lookup/fill 抢占(DWC-RMW-PORT)、不得背靠背 RMW(DWC-RMW-B2B)。
`include "define.v"
`include "common/OooDataWordCacheFacts.vh"

module OooDataWordCacheChecker (
  input wire clk,
  input wire rst,
  input wire dma_invalidate_all_i,
  input wire peer_invalidate_valid_i,
  input wire [`XLEN-1:0] peer_invalidate_addr_i,
  input wire [`STRB_W-1:0] peer_invalidate_wstrb_i,

  input wire [`XLEN-1:0] req_lookup_addr_i,
  input wire [3:0] req_nbytes_i,
  input wire req_cacheable_i,
  input wire req_line_cross_i,

  input wire [`XLEN-1:0] walk_lookup_addr_i,
  input wire walk_cacheable_i,

  input wire lookup_en_i,
  input wire [`XLEN-1:0] lookup_addr_i,
  input wire lookup_hit_i,

  input wire fill_valid_i,
  input wire [`XLEN-1:0] fill_addr_i,

  input wire store_commit_i,
  input wire store_rmw_en_i,
  input wire store_cacheable_i,
  input wire [`XLEN-1:0] store_addr_i,
  input wire [`XLEN-1:0] store_wdata_i,
  input wire [`STRB_W-1:0] store_wstrb_i,
  input wire rmw_busy_i
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

  function normalized_wstrb_legal;
    input [`STRB_W-1:0] wstrb;
    begin
      case (wstrb)
        8'h01,
        8'h03,
        8'h0f,
        8'hff: normalized_wstrb_legal = 1'b1;
        default: normalized_wstrb_legal = 1'b0;
      endcase
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
  wire [3:0] peer_nbytes_w =
      nbytes_from_wstrb(peer_invalidate_wstrb_i);
  wire [4:0] peer_window_end_w =
      {1'b0, peer_invalidate_addr_i[2:0]} + {1'b0, peer_nbytes_w};
  wire peer_line_cross_w = peer_window_end_w > 5'd8;
  wire [`XLEN-1:0] peer_line0_w =
      {peer_invalidate_addr_i[`XLEN-1:3], 3'b000};
  wire [`XLEN-1:0] peer_line1_w =
      peer_line0_w + {{(`XLEN-4){1'b0}}, 4'd8};

  // 发射拍锁存(判决拍参照系): lookup_hit_i 对应上一拍的 lookup_addr_i。
  reg lookup_pend_q;
  reg [`XLEN-1:0] lookup_addr_q;
  always @(posedge clk) begin
    if (rst)
      lookup_pend_q <= 1'b0;
    else
      lookup_pend_q <= lookup_en_i;
    if (lookup_en_i)
      lookup_addr_q <= lookup_addr_i;
  end

  // store RMW pend 模型: rmw_busy 必须恰为"cacheable 真 store commit"的次拍。
  wire store_rmw_issue_w =
      store_commit_i && store_rmw_en_i && store_cacheable_i &&
      cacheable_addr(store_addr_i);
  reg rmw_pend_model_q;
  always @(posedge clk) begin
    if (rst)
      rmw_pend_model_q <= 1'b0;
    else
      rmw_pend_model_q <= store_rmw_issue_w;
  end

  wire [`OOO_DWC_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_DWC_REQ_UNCACHED] =
      !cacheable_addr(req_lookup_addr_i);
  assign facts_w[`OOO_DWC_REQ_LINE_CROSS] = req_line_cross_i;
  assign facts_w[`OOO_DWC_LOOKUP_ISSUE] = lookup_en_i;
  assign facts_w[`OOO_DWC_LOOKUP_HIT] = lookup_hit_i;
  assign facts_w[`OOO_DWC_LOOKUP_MISS] = lookup_pend_q && !lookup_hit_i;
  assign facts_w[`OOO_DWC_FILL] = fill_valid_i;
  assign facts_w[`OOO_DWC_STORE_COMMIT] = store_commit_i;
  assign facts_w[`OOO_DWC_STORE_LINE_CROSS] =
      store_commit_i && store_line_cross_w;
  assign facts_w[`OOO_DWC_STORE_RMW_ISSUE] = store_rmw_issue_w;
  assign facts_w[`OOO_DWC_STORE_RMW_BUSY] = rmw_busy_i;
  assign facts_w[`OOO_DWC_DMA_INVALIDATE_ALL] = dma_invalidate_all_i;
  assign facts_w[`OOO_DWC_PEER_INVALIDATE] = peer_invalidate_valid_i;
  assign facts_w[`OOO_DWC_PEER_LINE_CROSS] =
      peer_invalidate_valid_i && peer_line_cross_w;

  wire _unused_facts_w =
      |facts_w | (|walk_lookup_addr_i) | (|fill_addr_i) |
      (|store_addr_i) | (|store_wdata_i) | (|store_wstrb_i) |
      (|peer_invalidate_addr_i) | (|peer_invalidate_wstrb_i);

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

  // DWC-HIT-GATE(打拍版, 合并原 REQ/WALK 两同拍断言): hit 只允许出现在判决拍
  // (上拍有发射), 且锁存 lookup 地址必须 cacheable。跨线阻断已移至桥判决拍
  // (read_cross_q), 由 tb_ooo_mem_axi_bridge 的跨线读场景审核。
  always @(posedge clk) begin
    if (!rst && lookup_hit_i && !lookup_pend_q) begin
      $error("[DWC-HIT-GATE] hit outside decision cycle (no lookup issued last cycle) @%0t",
             $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && lookup_hit_i && !cacheable_addr(lookup_addr_q)) begin
      $error("[DWC-HIT-GATE] hit on uncacheable latched addr=%h @%0t",
             lookup_addr_q, $time);
      $fatal;
    end
  end

  // DMA invalidation is visible combinationally in the lookup decision cycle:
  // a previously valid/tag-matching SRAM result must never fuse as a hit.
  always @(posedge clk) begin
    if (!rst && dma_invalidate_all_i && lookup_hit_i) begin
      $error("[DWC-DMA-HIT] lookup hit survived invalidate-all @%0t", $time);
      $fatal;
    end
  end

  always @(posedge clk) begin
    if (!rst && peer_invalidate_valid_i &&
        !normalized_wstrb_legal(peer_invalidate_wstrb_i)) begin
      $error("[DWC-PEER-WSTRB] peer maintenance mask is not normalized: addr=%h wstrb=%h @%0t",
             peer_invalidate_addr_i, peer_invalidate_wstrb_i, $time);
      $fatal;
    end
  end

  // The exact decision address is the preceding issue address.  Compare full
  // 8B line addresses so same-index/different-tag aliases are not confused.
  always @(posedge clk) begin
    if (!rst && peer_invalidate_valid_i && lookup_hit_i &&
        ((({lookup_addr_q[`XLEN-1:3], 3'b000}) == peer_line0_w) ||
         (peer_line_cross_w &&
          (({lookup_addr_q[`XLEN-1:3], 3'b000}) == peer_line1_w)))) begin
      $error("[DWC-PEER-HIT-BLOCK] exact peer-invalidated lookup returned hit @%0t",
             $time);
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

  // DWC-RMW-BUSY: rmw_busy 恰为 RMW 发射(cacheable 真 store commit)的次拍,
  // 多一拍/少一拍都意味着桥的 1 bubble 门控与 DWC 两拍机构失配。
  always @(posedge clk) begin
    if (!rst && (rmw_busy_i !== rmw_pend_model_q)) begin
      $error("[DWC-RMW-BUSY] rmw_busy=%b 但模型=%b(应恰为 RMW 发射次拍) @%0t",
             rmw_busy_i, rmw_pend_model_q, $time);
      $fatal;
    end
  end

  // DWC-RMW-PORT: RMW 两拍窗口(发射拍占读口/判决拍占写口)内宏口不得被
  // lookup 发射或 fill 抢占(1RW 违约)。A/D 维护路(store_rmw_en=0)不占口,
  // 允许与 lookup 同拍。
  always @(posedge clk) begin
    if (!rst && (store_rmw_issue_w || rmw_busy_i) &&
        (lookup_en_i || fill_valid_i)) begin
      $error("[DWC-RMW-PORT] RMW 窗口宏口被抢: issue=%b busy=%b lookup=%b fill=%b @%0t",
             store_rmw_issue_w, rmw_busy_i, lookup_en_i, fill_valid_i, $time);
      $fatal;
    end
  end

  // DWC-RMW-B2B: RMW 判决拍不得再来一个 RMW 发射(桥 store commit 源状态上
  // 不可能背靠背; 出现即 store_decouple_commit 双提交类回归)。
  always @(posedge clk) begin
    if (!rst && store_rmw_issue_w && rmw_busy_i) begin
      $error("[DWC-RMW-B2B] RMW 判决拍出现新 RMW 发射(背靠背 commit) @%0t",
             $time);
      $fatal;
    end
  end
`endif

endmodule
