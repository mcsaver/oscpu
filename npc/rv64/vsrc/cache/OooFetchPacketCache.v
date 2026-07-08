`include "define.v"

// 取指包 cache —— SRAM 宏版。
// 拓扑: payload/tag 全体(paging/priv/satp/pc/inst0/inst1/resp0/resp1)集中放进
// 1 个 Sram4096x199 1RW 同步读宏; valid 保持 ENTRY_COUNT bit FF(SRAM 内容无复位,
// 全清/失效语义由 valid FF 承担)。
// 两拍 lookup 协议: lookup_en_i(fire 拍)锁存请求上下文并发射 SRAM 读; 次拍(判决拍)
// lookup_*_o 针对 fire 拍锁存的请求有效, 其余拍输出恒 0(dec_en_q 门控)。
// fill 与 lookup 由使用方(OooFetchAxiBridge FSM)保证不同拍 —— SRAM 1RW 合同。
module OooFetchPacketCache #(
  parameter INDEX_W = `OOO_FETCH_PACKET_CACHE_INDEX_W,
  parameter ENTRY_COUNT = (1 << INDEX_W)
) (
  input clk,
  input rst,
  input clear_i,

  input lookup_en_i,
  input lookup_paging_i,
  input [1:0] lookup_priv_i,
  input [`XLEN-1:0] lookup_satp_i,
  input [`XLEN-1:0] lookup_pc_i,
  output lookup_context_hit_o,
  output lookup_hit_o,
  output [`INST_W-1:0] lookup_inst0_o,
  output [1:0] lookup_resp0_o,
  output [`INST_W-1:0] lookup_inst1_o,
  output [1:0] lookup_resp1_o,

  input fill_valid_i,
  input fill_paging_i,
  input [1:0] fill_priv_i,
  input [`XLEN-1:0] fill_satp_i,
  input [`XLEN-1:0] fill_pc_i,
  input [`INST_W-1:0] fill_inst0_i,
  input [1:0] fill_resp0_i,
  input [`INST_W-1:0] fill_inst1_i,
  input [1:0] fill_resp1_i,

  input invalidate_valid_i,
  input [`XLEN-1:0] invalidate_addr_i
);

  // SRAM 宏规格固定(4096x199); INDEX_W<12(focused TB 缩容)时地址高位补零。
  localparam SRAM_ADDR_W = 12;
  localparam SRAM_DATA_W = 199;

  reg [ENTRY_COUNT-1:0] valid_q;

  // fire 拍锁存的 lookup 请求(判决拍与 SRAM rdata_o 同参照系比较)。
  reg dec_en_q;                       // 上拍发射过 lookup → 本拍为判决拍
  reg lkp_paging_q;
  reg [1:0] lkp_priv_q;
  reg [`XLEN-1:0] lkp_satp_q;
  reg [`XLEN-1:0] lkp_pc_q;
  reg [INDEX_W-1:0] lkp_idx_q;
  reg lkp_inv_q;                      // fire 拍 store footprint 旁路(窗口①)锁存

  localparam [INDEX_W-1:0] INVALIDATE_DELTA_1 = 1;
  localparam [INDEX_W-1:0] INVALIDATE_DELTA_2 = 2;
  localparam [INDEX_W-1:0] INVALIDATE_DELTA_3 = 3;

  function [INDEX_W-1:0] entry_index;
    input [INDEX_W:1] pc_index_bits;
    begin
      entry_index = pc_index_bits;
    end
  endfunction

  function same_fetch_window;
    input [`XLEN-1:0] fetch_pc;
    input [`XLEN-1:0] store_addr;
    begin
      // 【正确性修复 2026-07-03: §3.1 #1 SMC 足迹】store 足迹高端 4→8B: 8B SD 改写区
      // [base, base+7] 跨两个 4B 块, 原 +3(4B)漏高 4B。取指窗仍 8B([pc,pc+7], 低端 +7)。
      same_fetch_window =
          ((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) <=
           (fetch_pc + {{(`XLEN-3){1'b0}}, 3'd7})) &&
          (((store_addr & {{(`XLEN-2){1'b1}}, 2'b00}) +
            {{(`XLEN-3){1'b0}}, 3'd7}) >= fetch_pc);
    end
  endfunction

  wire [INDEX_W-1:0] lookup_idx_w = entry_index(lookup_pc_i[INDEX_W:1]);
  wire [INDEX_W-1:0] fill_idx_w = entry_index(fill_pc_i[INDEX_W:1]);
  wire [INDEX_W-1:0] invalidate_base_idx_w =
      {invalidate_addr_i[INDEX_W:2], 1'b0};
  wire [INDEX_W-1:0] invalidate_idx_m6_w =
      invalidate_base_idx_w - INVALIDATE_DELTA_3;
  wire [INDEX_W-1:0] invalidate_idx_m4_w =
      invalidate_base_idx_w - INVALIDATE_DELTA_2;
  wire [INDEX_W-1:0] invalidate_idx_m2_w =
      invalidate_base_idx_w - INVALIDATE_DELTA_1;
  wire [INDEX_W-1:0] invalidate_idx_p0_w =
      invalidate_base_idx_w;
  wire [INDEX_W-1:0] invalidate_idx_p2_w =
      invalidate_base_idx_w + INVALIDATE_DELTA_1;
  // 【SMC 足迹】8B SD 高侧取指包 pc=base+4(idx base+2)/pc=base+6(idx base+3)漏, 补 p4/p6 邻域。
  wire [INDEX_W-1:0] invalidate_idx_p4_w =
      invalidate_base_idx_w + INVALIDATE_DELTA_2;
  wire [INDEX_W-1:0] invalidate_idx_p6_w =
      invalidate_base_idx_w + INVALIDATE_DELTA_3;
  wire lookup_invalidated_w =
      invalidate_valid_i && same_fetch_window(lookup_pc_i, invalidate_addr_i);
  wire fill_invalidated_w =
      invalidate_valid_i && same_fetch_window(fill_pc_i, invalidate_addr_i);

  // ── SRAM 宏(1RW 同步读): 读口=lookup fire 拍, 写口=未被 store footprint 阻止的
  //    fill 拍; 使用方 FSM 保证两者不同拍(见文末 OOO_ASSERT)。──
  wire sram_we_w = fill_valid_i && !fill_invalidated_w;
  wire sram_en_w = lookup_en_i || sram_we_w;
  // 用 | 零扩展补齐宏 12b 地址口, 避免 INDEX_W=12 时出现 0 次复制拼接(非法)。
  wire [SRAM_ADDR_W-1:0] sram_addr_w =
      {SRAM_ADDR_W{1'b0}} | (sram_we_w ? fill_idx_w : lookup_idx_w);
  // 位段布局(宏合同冻结): {paging[198], priv[197:196], satp[195:132], pc[131:68],
  //                       inst0[67:36], inst1[35:4], resp0[3:2], resp1[1:0]}
  wire [SRAM_DATA_W-1:0] sram_wdata_w =
      {fill_paging_i, fill_priv_i, fill_satp_i, fill_pc_i,
       fill_inst0_i, fill_inst1_i, fill_resp0_i, fill_resp1_i};
  wire [SRAM_DATA_W-1:0] sram_rdata_w;

  Sram4096x199 u_payload_sram (
    .clk(clk),
    .en_i(sram_en_w),
    .we_i(sram_we_w),
    .addr_i(sram_addr_w),
    .wdata_i(sram_wdata_w),
    .rdata_o(sram_rdata_w)
  );

  // 判决拍视图: SRAM 读出 entry 各字段(对应 fire 拍锁存的 index)。
  wire ent_paging_w = sram_rdata_w[198];
  wire [1:0] ent_priv_w = sram_rdata_w[197:196];
  wire [`XLEN-1:0] ent_satp_w = sram_rdata_w[195:132];
  wire [`XLEN-1:0] ent_pc_w = sram_rdata_w[131:68];
  wire [`INST_W-1:0] ent_inst0_w = sram_rdata_w[67:36];
  wire [`INST_W-1:0] ent_inst1_w = sram_rdata_w[35:4];
  wire [1:0] ent_resp0_w = sram_rdata_w[3:2];
  wire [1:0] ent_resp1_w = sram_rdata_w[1:0];

  // valid 必须在判决拍用锁存 idx 读 FF(不能 fire 拍随 SRAM 走): fire 拍同拍到达的
  // invalidate 在拍尾清 valid, 判决拍组合读才能看到新值(窗口①的 FF 侧封堵)。
  wire dec_valid_w = valid_q[lkp_idx_q];
  // 两拍窗口封堵: 窗口①=fire 拍 store(锁存旁路 lkp_inv_q, 与上述 FF 读双保险);
  // 窗口②=判决拍才到的 store(其盲失效拍尾才写 FF, 本拍必须用锁存 pc 旁路挡 hit)。
  wire dec_invalidated_w =
      lkp_inv_q ||
      (invalidate_valid_i && same_fetch_window(lkp_pc_q, invalidate_addr_i));

  assign lookup_context_hit_o =
      dec_en_q && dec_valid_w &&
      (ent_paging_w == lkp_paging_q) &&
      (!lkp_paging_q ||
       ((ent_priv_w == lkp_priv_q) && (ent_satp_w == lkp_satp_q)));
  assign lookup_hit_o =
      lookup_context_hit_o &&
      (ent_pc_w == lkp_pc_q) &&
      !dec_invalidated_w;
  assign lookup_inst0_o = ent_inst0_w;
  assign lookup_inst1_o = ent_inst1_w;
  assign lookup_resp0_o = ent_resp0_w;
  assign lookup_resp1_o = ent_resp1_w;

  always @(posedge clk) begin
    if (rst) begin
      dec_en_q <= 1'b0;
    end else begin
      dec_en_q <= lookup_en_i;
    end
    if (lookup_en_i) begin
      lkp_paging_q <= lookup_paging_i;
      lkp_priv_q <= lookup_priv_i;
      lkp_satp_q <= lookup_satp_i;
      lkp_pc_q <= lookup_pc_i;
      lkp_idx_q <= lookup_idx_w;
      lkp_inv_q <= lookup_invalidated_w;
    end
  end

  always @(posedge clk) begin
    if (rst || clear_i) begin
      valid_q <= {ENTRY_COUNT{1'b0}};
    end else begin
      // 盲失效: 7 邻域 index 无条件清 valid, 不再读 pc 比较(pc 的 7 个失效读口随
      // SRAM 化物理消灭)。与 store 足迹重叠的取指包 index 必落在 m6..p6 邻域(超集
      // 覆盖已证明), 多清的只是同 index 异 PC 的 entry —— 损 hit 率不损正确性。
      if (invalidate_valid_i) begin
        valid_q[invalidate_idx_m6_w] <= 1'b0;
        valid_q[invalidate_idx_m4_w] <= 1'b0;
        valid_q[invalidate_idx_m2_w] <= 1'b0;
        valid_q[invalidate_idx_p0_w] <= 1'b0;
        valid_q[invalidate_idx_p2_w] <= 1'b0;
        valid_q[invalidate_idx_p4_w] <= 1'b0;
        valid_q[invalidate_idx_p6_w] <= 1'b0;
      end
      // 后写胜出: 同拍未被阻止的 fill 覆盖同 index 盲失效(fill 内容与该 store 无
      // 足迹重叠, 是刚从内存取回的真值), 维持原"未被覆盖的同拍 fill 胜出"语义。
      if (fill_valid_i && !fill_invalidated_w) begin
        valid_q[fill_idx_w] <= 1'b1;
      end
    end
  end

`ifdef OOO_ASSERT
  // ── 契约: SRAM 1RW 读写不同拍(读写同拍=宏使用违约)。使用方 FSM 保证 lookup fire
  // 仅在 S_IDLE/S_RESP、fill 仅在 S_R0/S_R1, 状态互斥。立即断言, 仅 OOO_ASSERT 编入。
  always @(posedge clk) begin
    if (!rst && lookup_en_i && fill_valid_i) begin
      $error("[CONTRACT-FPC-1RW] lookup_en and fill in same cycle violates 1RW SRAM: lookup_pc=%h fill_pc=%h @%0t",
             lookup_pc_i, fill_pc_i, $time);
      $fatal;
    end
  end
`endif

endmodule
