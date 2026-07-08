`include "define.v"

// 【LSQ Phase2+3 → SRAM 宏化】数据 cache: 对齐 8B line 直映 + 1RW 同步读宏。
//
// line 模型动机(Phase2+3 保留): entry = 对齐 8B line(index=addr[3+IW-1:3],
// tag=高位)。旧 byte-window 模型按访问起始地址匹配, 短步进访问互踢,
// CoreMark 实测 dcache load miss 47.6% 且容量加大零收益。
//
// SRAM 化(2026-07-08):
// - {tag,data} 拼宽存进 1RW 同步读宏 Sram4096x113, 位段 {tag[112:64], data[63:0]};
//   valid 保留 4096b 平铺 FF——宏内容无复位, 全清/失效语义由 FF 承担。
// - 读口协议(单口两拍): lookup_en_i+lookup_addr_i 发射拍读宏, 次拍
//   lookup_hit_o/lookup_line_o 针对锁存请求有效。原 req/walk 两个组合读视图
//   由桥按 FSM 状态互斥合并到该口({S_IDLE,S_RESP}∩{S_WALK_R,S_AD_UPDATE}=∅,
//   证明见 design/specs/ooo-mem-axi-bridge-fsm.md)。
// - 窗口移位与跨线阻断移到桥判决拍(统一用锁存 paddr 低 3 位), 本模块只回
//   原始 line; req_cacheable_o/req_line_cross_o/walk_cacheable_o 保持纯地址
//   0-cycle 组合(不查存储阵列)。
// - store 维护一期改为无条件失效(清 valid, 不读 tag 不写宏, 0 额外拍):
//   Phase2+3 的 write-update 保热是刻意丢弃的一期取舍——1RW 同步读下
//   byte-merge RMW 需 2 拍并与读口抢 1R, perf 回归后二期再评估。
// - fill 是唯一写宏路径, 桥保证 fill(S_READ_DATA)与 lookup 发射拍状态互斥,
//   读写同拍视为 1RW 违约(OOO_ASSERT 把关)。
module OooDataWordCache #(
  // 深度/宽度与 Sram4096x113 定死(4096 项=INDEX_W 12, tag 49b+data 64b=113b),
  // 参数仅作文档化, 改值必须换宏(OOO_ASSERT 有 elaboration 检查)。
  parameter INDEX_W = `OOO_DATA_WORD_CACHE_INDEX_W,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,

  // ---- 纯地址 0-cycle 组合视图(桥 accept 拍决策用, 不查存储阵列) ----
  input [`XLEN-1:0] req_lookup_addr_i,
  // 本访问的字节窗口宽度(桥侧 wstrb popcount)
  input [3:0] req_nbytes_i,
  output req_cacheable_o,
  output req_line_cross_o,

  input [`XLEN-1:0] walk_lookup_addr_i,
  output walk_cacheable_o,

  // ---- 单读口两拍协议 ----
  input lookup_en_i,
  input [`XLEN-1:0] lookup_addr_i,
  output lookup_hit_o,               // 次拍有效: 锁存地址 cacheable+valid+tag 命中
  output [`XLEN-1:0] lookup_line_o,  // 次拍有效: 原始 line(窗口移位归桥判决拍)

  input fill_valid_i,
  input [`XLEN-1:0] fill_addr_i,   // 须 8B 对齐(桥保证)
  input [`XLEN-1:0] fill_data_i,   // 对齐 line 数据

  input store_commit_i,
  input [`XLEN-1:0] store_addr_i,
  input [`STRB_W-1:0] store_wstrb_i
);

  localparam TAG_W = `XLEN - 3 - INDEX_W;

  reg [ENTRY_COUNT-1:0] valid_q;

  function [INDEX_W-1:0] line_index;
    input [`XLEN-1:0] addr;
    begin
      line_index = addr[INDEX_W+2:3];
    end
  endfunction

  function [TAG_W-1:0] line_tag;
    input [`XLEN-1:0] addr;
    begin
      line_tag = addr[`XLEN-1:INDEX_W+3];
    end
  endfunction

  function cacheable_addr;
    input [`XLEN-1:0] addr;
    begin
      cacheable_addr = ((addr & `NPC_AXI_PMEM_MASK) == `NPC_AXI_PMEM_BASE);
    end
  endfunction

  function [3:0] nbytes_from_wstrb;
    input [`STRB_W-1:0] wstrb;
    integer nb_i;
    begin
      nbytes_from_wstrb = 4'd0;
      for (nb_i = 0; nb_i < `STRB_W; nb_i = nb_i + 1)
        if (wstrb[nb_i])
          nbytes_from_wstrb = nbytes_from_wstrb + 4'd1;
      if (nbytes_from_wstrb == 4'd0)
        nbytes_from_wstrb = 4'd1;
    end
  endfunction

  // ---- 纯地址组合视图 ----
  assign req_cacheable_o = cacheable_addr(req_lookup_addr_i);
  assign req_line_cross_o =
      ({1'b0, req_lookup_addr_i[2:0]} + req_nbytes_i) > 5'd8;
  assign walk_cacheable_o = cacheable_addr(walk_lookup_addr_i);

  // ---- 1RW 同步读宏: fill 写 / lookup 读(桥保证不同拍) ----
  wire fill_we_w = fill_valid_i && cacheable_addr(fill_addr_i);
  wire [INDEX_W-1:0] fill_idx_w = line_index(fill_addr_i);
  wire [INDEX_W-1:0] lookup_idx_w = line_index(lookup_addr_i);
  wire [TAG_W+`XLEN-1:0] sram_rdata_w;

  Sram4096x113 u_sram (
    .clk(clk),
    .en_i(lookup_en_i || fill_we_w),
    .we_i(fill_we_w),
    .addr_i(fill_we_w ? fill_idx_w : lookup_idx_w),
    .wdata_i({line_tag(fill_addr_i), fill_data_i}),
    .rdata_o(sram_rdata_w)
  );

  // 判决拍上下文(发射拍锁存)。valid 用判决拍的 FF 值: 发射拍同沿的 store
  // 失效在判决拍已可见, 只会把 hit 保守判成 miss(走 AXI 取新值), 无正确性洞。
  reg lookup_pend_q;
  reg [INDEX_W-1:0] lookup_idx_q;
  reg [TAG_W-1:0] lookup_tag_q;
  reg lookup_cacheable_q;

  always @(posedge clk) begin
    if (rst) begin
      lookup_pend_q <= 1'b0;
    end else begin
      lookup_pend_q <= lookup_en_i;
    end
    if (lookup_en_i) begin
      lookup_idx_q <= lookup_idx_w;
      lookup_tag_q <= line_tag(lookup_addr_i);
      lookup_cacheable_q <= cacheable_addr(lookup_addr_i);
    end
  end

  assign lookup_hit_o =
      lookup_pend_q && lookup_cacheable_q && valid_q[lookup_idx_q] &&
      (sram_rdata_w[TAG_W+`XLEN-1:`XLEN] == lookup_tag_q);
  assign lookup_line_o = sram_rdata_w[`XLEN-1:0];

  // ---- valid FF 维护: fill 置位 / store 无条件失效 ----
  wire [3:0] st_nbytes_w = nbytes_from_wstrb(store_wstrb_i);
  wire st_cross_w = ({1'b0, store_addr_i[2:0]} + st_nbytes_w) > 5'd8;
  wire [INDEX_W-1:0] st_idx_w = line_index(store_addr_i);
  wire [INDEX_W-1:0] st_idx_p1_w = st_idx_w + {{(INDEX_W-1){1'b0}}, 1'b1};
  wire st_cacheable_w = cacheable_addr(store_addr_i);

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (fill_we_w)
        valid_q[fill_idx_w] <= 1'b1;
      // store 无条件失效: 不比 tag(同 index 异 tag 行被误清只损性能, 过失效
      // 安全), 跨线加清下一行。同拍 fill+store 由桥状态互斥排除; 写法上
      // store 失效后写, 即便发生也是保守方向。
      if (store_commit_i && st_cacheable_w) begin
        valid_q[st_idx_w] <= 1'b0;
        if (st_cross_w)
          valid_q[st_idx_p1_w] <= 1'b0;
      end
    end
  end

`ifdef OOO_ASSERT
  initial begin
    if (INDEX_W != 12) begin
      $error("[DWC-SRAM-GEOM] INDEX_W=%0d 与 Sram4096x113(4096x113)宏不匹配",
             INDEX_W);
      $fatal;
    end
  end

  // 1RW 合同: lookup 发射与 fill 写不得同拍(桥 FSM 读/写消费状态互斥保证)。
  always @(posedge clk) begin
    if (!rst && lookup_en_i && fill_we_w) begin
      $error("[DWC-SRAM-1RW] lookup 与 fill 同拍(1RW 读写违约) @%0t", $time);
      $fatal;
    end
  end
`endif

endmodule
