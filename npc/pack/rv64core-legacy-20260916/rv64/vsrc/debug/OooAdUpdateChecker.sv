// ┌─ Sv39 HW-managed A/D 更新(Svadu)的外部观测 checker ──────────────────────────────────────┐
// │ 归属: ooo-fetch-axi-bridge.md / ooo-mem-axi-bridge-fsm.md + debug observability 三层模型。 │
// │ 作用: XMR 读两桥(取指 OooFetchAxiBridge / 数据 OooMemAxiBridge)的 walker + PTE 写信号,       │
// │       断言 A/D 更新的结构不变量。挂 SIM_TOP_SRCS, DCE 零面积; ① 电路一行不动。               │
// │ 通用单桥模块, NpcSimTop 实例化两次(ALLOW_D 区分: 取指只置 A ⇒ 0; 数据可置 A/D ⇒ 1)。         │
// │ 不变量(state_q==S_AD_UPDATE 拍):                                                             │
// │   INV-A  写地址 == 本级 walk_pte_addr (A/D 写必落本 leaf PTE 物理地址)                        │
// │   INV-B  ad_pte ^ orig_leaf_pte 只可能是 bit6(A)/bit7(D) — 绝不动其它 PTE 位                  │
// │   INV-C  ad_pte 的 A 位(bit6)必置 — HW 更新的语义核心                                        │
// │   INV-D  (仅取指 ALLOW_D=0) 取指 A 更新绝不改 D 位                                            │
// │   INV-E  A/D 写 wstrb 全置(整 8B PTE 写, 对齐 NEMU 简单写)                                    │
// │ orig_leaf_pte 由观测: S_AD_UPDATE 直接从 S_WALK_R(leaf)进入, 故最后一拍 S_WALK_R 的读数据    │
// │ 即触发更新的原始 leaf PTE — 每 S_WALK_R+rvalid 拍锁存 rdata, 进 S_AD_UPDATE 时即为 leaf 值。  │
// │ ★A/D 更新稀有(A=0/D=0 页), 非常开 guard: 是"一旦发生必须结构正确"的 tripwire, 非真空不保证。 │
// └──────────────────────────────────────────────────────────────────────────────────────────┘
`include "define.v"

module OooAdUpdateChecker #(
  parameter ALLOW_D = 1'b1   // 数据桥可置 A/D ⇒ 1; 取指桥只置 A ⇒ 0
) (
  input wire clk,
  input wire rst,                                  // 高有效

  // ── ① 两桥真实信号(经 NpcSimTop XMR 从 u_top.u_core.u_ooo_{fetch,mem}_bridge.* 连入)──
  input wire [3:0] state_i,                        // 桥 FSM state_q(S_WALK_R=2, S_AD_UPDATE=8)
  input wire rvalid_i,                             // PTE 读通道 rvalid(walk 读回 PTE 拍)
  input wire [`XLEN-1:0] rdata_i,                  // PTE 读通道 rdata(S_WALK_R 拍=leaf PTE)
  input wire awvalid_i,                            // A/D 写 AW valid
  input wire [`XLEN-1:0] awaddr_i,                 // A/D 写 AW 地址
  input wire wvalid_i,                             // A/D 写 W valid
  input wire [`STRB_W-1:0] wstrb_i,                // A/D 写 wstrb
  input wire [`XLEN-1:0] walk_pte_addr_i,          // 本级 leaf PTE 物理地址(组合)
  input wire [`XLEN-1:0] ad_pte_i                  // 置位后的 PTE(ad_pte_q, 供写通道)
);

  localparam [3:0] S_WALK_R = 4'd2;
  localparam [3:0] S_AD_UPDATE = 4'd8;
  localparam [`XLEN-1:0] A_BIT = {{(`XLEN-7){1'b0}}, 7'h40};   // bit 6 (Accessed)
  localparam [`XLEN-1:0] D_BIT = {{(`XLEN-8){1'b0}}, 8'h80};   // bit 7 (Dirty)
  localparam [`XLEN-1:0] AD_MASK = A_BIT | D_BIT;

  wire in_ad_update_w = (state_i == S_AD_UPDATE);
  wire walk_pte_read_w = (state_i == S_WALK_R) && rvalid_i;

  // 观测锁存: 最后一拍 S_WALK_R 的读数据 = 触发本次更新的原始 leaf PTE。
  reg [`XLEN-1:0] orig_leaf_pte_q;
  always @(posedge clk) begin
    if (rst) begin
      orig_leaf_pte_q <= {`XLEN{1'b0}};
    end else if (walk_pte_read_w) begin
      orig_leaf_pte_q <= rdata_i;
    end
  end

  wire [`XLEN-1:0] ad_diff_w = ad_pte_i ^ orig_leaf_pte_q;
  // 非真空已验(2026-07-06, sv39-ad-bits): 两桥均观测到真实 A/D 更新且全不变量成立——
  //   取指桥 orig=..000f(A=0) → ad_pte=..004f(仅 +A, 不动 D), awaddr==walk_pte_addr=0x80001010;
  //   数据桥 orig=..004f(D=0) → ad_pte=..00cf(仅 +D), awaddr==walk_pte_addr=0x80001ff0。
  //   故本 checker 是 A/D 更新类的常触发 tripwire(非真空), 真实断言静默。

  // ── ② 粗粒度 tier 投影(observability; 波形可观测)。同时把全部 ① 输入下沉, 保证 OOO_ASSERT
  //    关闭时无 UNUSEDSIGNAL。──
  wire [2:0] facts_w;
  assign facts_w[0] = in_ad_update_w;                    // 处于 A/D 更新态
  assign facts_w[1] = in_ad_update_w && awvalid_i;       // 正发 PTE 写
  assign facts_w[2] = walk_pte_read_w;                   // walk 读回 PTE
  wire _unused_facts_w =
      |facts_w | (|rdata_i) | (|awaddr_i) | (|wstrb_i) | wvalid_i |
      (|walk_pte_addr_i) | (|ad_pte_i) | (|ad_diff_w) | (ALLOW_D != 1'b0);

`ifdef OOO_ASSERT
  // ── INV-A: A/D 写地址 == 本级 walk_pte_addr ──
  always @(posedge clk) begin
    if (!rst && in_ad_update_w && awvalid_i &&
        (awaddr_i !== walk_pte_addr_i)) begin
      $error("[ADUPD-ADDR] %m: A/D 写地址 %h != 本级 walk_pte_addr %h @%0t",
             awaddr_i, walk_pte_addr_i, $time);
      $fatal;
    end
  end

  // ── INV-B: ad_pte 相对 orig leaf PTE 只改 A/D 位 ──
  always @(posedge clk) begin
    if (!rst && in_ad_update_w &&
        ((ad_diff_w & ~AD_MASK) !== {`XLEN{1'b0}})) begin
      $error("[ADUPD-BITS] %m: A/D 写只应改 bit6/7, 但 ad_pte=%h orig=%h diff=%h @%0t",
             ad_pte_i, orig_leaf_pte_q, ad_diff_w, $time);
      $fatal;
    end
  end

  // ── INV-C: ad_pte 的 A 位必置 ──
  always @(posedge clk) begin
    if (!rst && in_ad_update_w && (ad_pte_i[6] !== 1'b1)) begin
      $error("[ADUPD-A] %m: A/D 更新未置 A 位, ad_pte=%h @%0t",
             ad_pte_i, $time);
      $fatal;
    end
  end

  // ── INV-E: A/D 写 wstrb 全置(整 8B PTE 写)──
  always @(posedge clk) begin
    if (!rst && in_ad_update_w && wvalid_i && ((&wstrb_i) !== 1'b1)) begin
      $error("[ADUPD-STRB] %m: A/D 写 wstrb 非全置 =%b @%0t",
             wstrb_i, $time);
      $fatal;
    end
  end
`endif

  // ── INV-D: 取指侧(ALLOW_D=0) A 更新绝不改 D 位 ──
  generate
    if (!ALLOW_D) begin : g_fetch_no_d
`ifdef OOO_ASSERT
      always @(posedge clk) begin
        if (!rst && in_ad_update_w &&
            ((ad_diff_w & D_BIT) !== {`XLEN{1'b0}})) begin
          $error("[ADUPD-FETCH-D] %m: 取指 A 更新不应改 D 位, ad_pte=%h orig=%h @%0t",
                 ad_pte_i, orig_leaf_pte_q, $time);
          $fatal;
        end
      end
`endif
    end
  endgenerate

endmodule
