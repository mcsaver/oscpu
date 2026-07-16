`include "define.v"

// 【LSQ Phase2+3 → SRAM 宏化】数据 cache: 对齐 8B line 直映 + 1RW 同步读宏。
//
// line 模型动机(Phase2+3 保留): entry = 对齐 8B line(index=addr[3+IW-1:3],
// tag=高位)。旧 byte-window 模型按访问起始地址匹配, 短步进访问互踢,
// CoreMark 实测 dcache load miss 47.6% 且容量加大零收益。
//
// SRAM 化(2026-07-08):
// - {tag,data} 拼宽存进 1RW 同步读宏 Sram4096x113(bit-write-mask 变体), 位段
//   {tag[112:64], data[63:0]}; valid 保留 4096b 平铺 FF——宏内容无复位,
//   全清/失效语义由 FF 承担。
// - 读口协议(单口两拍): lookup_en_i+lookup_addr_i 发射拍读宏, 次拍
//   lookup_hit_o/lookup_line_o 针对锁存请求有效。原 req/walk 两个组合读视图
//   由桥按 FSM 状态互斥合并到该口({S_IDLE,S_RESP}∩{S_WALK_R,S_AD_UPDATE}=∅,
//   证明见 design/specs/ooo-mem-axi-bridge-fsm.md)。
// - 窗口移位与跨线阻断移到桥判决拍(统一用锁存 paddr 低 3 位), 本模块只回
//   原始 line; req_cacheable_o/req_line_cross_o/walk_cacheable_o 保持纯地址
//   0-cycle 组合(不查存储阵列)。
//
// store 维护(2026-07-09 二期赎回 write-update, 一期无条件失效废止):
// - store_rmw_en_i=1(真 store commit): 2 拍 RMW 线内字节合并——
//   commit 拍(桥 S_WRITE_REQ 解耦/S_WRITE_RESP b-ok, 该拍宏读口空闲)占宏口
//   发读 st_idx 并锁存 store 上下文(idx/tag/line 掩码/line 数据);
//   次拍(判决拍, rmw_busy_o=1, 桥压 req_ready 产生 store 后 1 bubble)判
//   valid && tag match: 命中则以 wmask 写 line 内被 store 覆盖的 data 字节，
//   同时用全 1 tag mask 幂等写回锁存 tag；miss 无动作
//   (write-no-allocate)。跨线 store 的下一行(p1)仍无条件清 valid(跨线 RMW
//   不做, 保守失效); 本行照常线内合并(line 掩码=wstrb<<off 截断即线内字节)。
// - store_rmw_en_i=0(HW A/D PTE 写回维护路): 保持无条件失效(清 valid, 不读
//   不写宏, 0 额外拍)——该拍 S_AD_UPDATE 的 read 续访问可能同拍发 lookup,
//   宏读口不空闲, 且 PTE 行保热无收益。
// - fill 是全行写(全 1 掩码), 桥保证 fill(S_READ_DATA)与 lookup 发射拍/RMW
//   两拍窗口状态互斥; 宏口占用者两两同拍视为 1RW 违约(OOO_ASSERT 把关)。
module OooDataWordCache #(
  // 深度/宽度与 Sram4096x113 定死(4096 项=INDEX_W 12, tag 49b+data 64b=113b),
  // 参数仅作文档化, 改值必须换宏(OOO_ASSERT 有 elaboration 检查)。
  parameter INDEX_W = `OOO_DATA_WORD_CACHE_INDEX_W,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,
  // Full invalidate after the synchronous virtio DMA batch has completed.
  // This is not a SRAM-port owner: only valid visibility changes.
  input dma_invalidate_all_i,

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

  // ---- store 维护 ----
  input store_commit_i,
  // 1=真 store commit(2 拍 RMW write-update); 0=A/D PTE 写回维护(无条件失效)
  input store_rmw_en_i,
  input [`XLEN-1:0] store_addr_i,
  input [`XLEN-1:0] store_wdata_i,   // 窗口数据(低位起, 与 wstrb 位对齐)
  input [`STRB_W-1:0] store_wstrb_i,
  // RMW 判决拍占用宏口: 桥须在该拍压 req_ready/不发 lookup(store 后 1 bubble)
  output rmw_busy_o
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

  // 字节使能 → 位掩码展开(RMW 判决拍的 data 段 wmask)
  function [`XLEN-1:0] expand_bytemask;
    input [`STRB_W-1:0] mask;
    begin
      expand_bytemask = {
          {8{mask[7]}}, {8{mask[6]}}, {8{mask[5]}}, {8{mask[4]}},
          {8{mask[3]}}, {8{mask[2]}}, {8{mask[1]}}, {8{mask[0]}}
      };
    end
  endfunction

  // ---- 纯地址组合视图 ----
  assign req_cacheable_o = cacheable_addr(req_lookup_addr_i);
  assign req_line_cross_o =
      ({1'b0, req_lookup_addr_i[2:0]} + req_nbytes_i) > 5'd8;
  assign walk_cacheable_o = cacheable_addr(walk_lookup_addr_i);

  // ---- store 地址派生(RMW/失效共用) ----
  wire [2:0] st_off_w = store_addr_i[2:0];
  wire [3:0] st_nbytes_w = nbytes_from_wstrb(store_wstrb_i);
  wire st_cross_w = ({1'b0, st_off_w} + st_nbytes_w) > 5'd8;
  wire [INDEX_W-1:0] st_idx_w = line_index(store_addr_i);
  wire [INDEX_W-1:0] st_idx_p1_w = st_idx_w + {{(INDEX_W-1){1'b0}}, 1'b1};
  wire st_cacheable_w = cacheable_addr(store_addr_i);
  // line 视角的合并掩码/数据(窗口左移 off 字节; 8b 截断天然只留线内字节,
  // 跨线溢出部分由 p1 保守失效兜底)
  wire [`STRB_W-1:0] st_line_mask_w = store_wstrb_i << st_off_w;
  wire [`XLEN-1:0] st_line_data_w = store_wdata_i << {st_off_w, 3'b000};

  // ---- store RMW 2 拍机构 ----
  // commit 拍(发射): 占宏口读 st_idx, 同拍锁存 store 上下文。
  wire rmw_start_w = store_commit_i && store_rmw_en_i && st_cacheable_w;

  reg rmw_pending_q;
  reg [INDEX_W-1:0] rmw_idx_q;
  reg [TAG_W-1:0] rmw_tag_q;
  reg [`STRB_W-1:0] rmw_line_mask_q;
  reg [`XLEN-1:0] rmw_line_data_q;

  always @(posedge clk) begin
    if (rst) begin
      rmw_pending_q <= 1'b0;
    end else begin
      rmw_pending_q <= rmw_start_w;
    end
    if (rmw_start_w) begin
      rmw_idx_q <= st_idx_w;
      rmw_tag_q <= line_tag(store_addr_i);
      rmw_line_mask_q <= st_line_mask_w;
      rmw_line_data_q <= st_line_data_w;
    end
  end

  assign rmw_busy_o = rmw_pending_q;

  // ---- 1RW 同步读宏(bit-write-mask): 四占用者状态互斥(桥 FSM 保证) ----
  //   lookup 读(发射拍) / fill 全行写 / RMW 读(store commit 拍) / RMW 写(判决拍)
  wire fill_we_w = fill_valid_i && cacheable_addr(fill_addr_i);
  wire [INDEX_W-1:0] fill_idx_w = line_index(fill_addr_i);
  wire [INDEX_W-1:0] lookup_idx_w = line_index(lookup_addr_i);
  wire [TAG_W+`XLEN-1:0] sram_rdata_w;

  // RMW 判决: 锁存 tag 与宏读出 tag 段比较, valid 用判决拍 FF 值。
  // 命中才写; miss(同 index 异 tag/invalid)无动作=write-no-allocate。
  wire rmw_hit_w =
      rmw_pending_q && valid_q[rmw_idx_q] &&
      (sram_rdata_w[TAG_W+`XLEN-1:`XLEN] == rmw_tag_q);

  wire sram_en_w = lookup_en_i || fill_we_w || rmw_start_w || rmw_hit_w;
  wire sram_we_w = fill_we_w || rmw_hit_w;
  // T4S timing boundary：地址 owner 只需知道本拍有 fill 请求；真正 SRAM
  // en/we/wmask 与 valid 更新仍由 fill_we_w 的 cacheable 重判保护。集成合同
  // 要求 fill_valid 必为 cacheable+8B aligned，故合法域内两者等价；这里避免
  // 把 cacheability reduction/高扇出写控串进 SRAM addr setup，且不改变
  // DMA>fill valid 优先级。
  wire [INDEX_W-1:0] sram_addr_w =
      fill_valid_i ? fill_idx_w :
      rmw_hit_w   ? rmw_idx_q :
      rmw_start_w ? st_idx_w : lookup_idx_w;
  wire [TAG_W+`XLEN-1:0] sram_wdata_w =
      fill_we_w ? {line_tag(fill_addr_i), fill_data_i}
                : {rmw_tag_q, rmw_line_data_q};
  // fill 全行写=全 1 掩码。RMW hit 已证明宏内 tag==rmw_tag_q，因此 tag
  // 段也置写并幂等写回锁存 tag；data 段仍只覆盖 store 命中的字节。
  // 这避免用 fill_we_w 直驱 49 个高电容 tag-wmask 宏引脚，否则该共享
  // net 的慢 slew 会同时污染 valid bitmap 与 SRAM setup 路径。
  wire [TAG_W+`XLEN-1:0] sram_wmask_w =
      {{TAG_W{1'b1}},
       fill_we_w ? {`XLEN{1'b1}} : expand_bytemask(rmw_line_mask_q)};

  Sram4096x113 u_sram (
    .clk(clk),
    .en_i(sram_en_w),
    .we_i(sram_we_w),
    .addr_i(sram_addr_w),
    .wdata_i(sram_wdata_w),
    .wmask_i(sram_wmask_w),
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
      (sram_rdata_w[TAG_W+`XLEN-1:`XLEN] == lookup_tag_q) &&
      !dma_invalidate_all_i;
  assign lookup_line_o = sram_rdata_w[`XLEN-1:0];

  // ---- valid FF 维护 ----
  //   fill 置位;
  //   store(RMW 路)本行不失效(命中判决拍原地合并, miss 原行继续有效——
  //     同 index 异 tag 行不再被误清, 这是 write-update 赎回的主收益);
  //   跨线 store 的 p1 行无条件清(跨线 RMW 不做, 保守失效);
  //   A/D 维护路(store_rmw_en_i=0)保持一期无条件失效(含跨线 p1)。
  always @(posedge clk) begin
    if (rst) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else if (dma_invalidate_all_i) begin
      // Highest runtime maintenance priority.  SRAM tag/data may retain old
      // bits, but no fill/store action in this edge may make them visible.
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      if (fill_we_w)
        valid_q[fill_idx_w] <= 1'b1;
      if (store_commit_i && st_cacheable_w) begin
        if (!store_rmw_en_i) begin
          valid_q[st_idx_w] <= 1'b0;
          if (st_cross_w)
            valid_q[st_idx_p1_w] <= 1'b0;
        end else if (st_cross_w) begin
          valid_q[st_idx_p1_w] <= 1'b0;
        end
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

  // fill_valid 是 SRAM 地址 owner，因此必须在模块本地承重 cacheable/aligned
  // 合同；不能只依赖 direct-TB 才实例化的外部 checker。
  always @(posedge clk) begin
    if (!rst && fill_valid_i &&
        (!cacheable_addr(fill_addr_i) || (fill_addr_i[2:0] != 3'b000))) begin
      $error("[DWC-FILL-ADDR] fill must be PMEM cacheable and 8B aligned: addr=%h @%0t",
             fill_addr_i, $time);
      $fatal;
    end
  end

  // 1RW 合同: 宏口四占用者(lookup 发射/fill 写/RMW 读/RMW 判决拍)两两不得
  // 同拍(桥 FSM 状态互斥+req_ready 压制保证)。RMW 判决拍即便 miss 不写,
  // 口也已保留(busy), 同拍其他占用一律违约。fill owner 按 fill_valid 计数，
  // 与上面的地址 mux owner 完全一致，而不是等 cacheability 重判后的 fill_we。
  always @(posedge clk) begin
    if (!rst && (({2'b00, lookup_en_i} + {2'b00, fill_valid_i} +
                  {2'b00, rmw_start_w} + {2'b00, rmw_pending_q}) > 3'd1)) begin
      $error("[DWC-SRAM-1RW] 宏口冲突: lookup=%b fill=%b rmw_rd=%b rmw_wr=%b @%0t",
             lookup_en_i, fill_valid_i, rmw_start_w, rmw_pending_q, $time);
      $fatal;
    end
  end
`endif

endmodule
