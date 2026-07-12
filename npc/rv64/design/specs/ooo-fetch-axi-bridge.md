# 规范：取指 AXI 桥 OooFetchAxiBridge

> 模块：`vsrc/frontend/OooFetchAxiBridge.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：**主路径已实现**（含 iter1 取指 cache PMP 门控、fence.i 真 flush、Svnapot
> 64KiB 与硬件 A update）；IFU-AXI-G1、IFU-FETCH-G2 已于 2026-07-12 关闭，§9 仍有
> IFU-ACCESS-G1、IFU-TVAL-G1 与 PTW-PMP-G1 等开放合同，不能写成无条件“已完整验证”。

## 1. 目的与范围
把前端取指请求(PC)落到 IFU AXI，返回一个 **fetch packet**（两条对齐的 32-bit 槽，支持 RVC）。
内含取指包 cache、Sv39 ITLB、PMP 检查、跨页拼接。单事务在飞。不负责分支预测/重定向(前端控制面)。
取指包 cache 的 lookup/fill/invalidate/clear 语义与 macro/OOC 前置合同见
`ooo-fetch-packet-cache.md`；本文只约束桥侧 PMP/ITLB/AXI/fence.i 事务语义。

## 2. 接口（要点）
| 信号 | 含义 |
| --- | --- |
| `fetch_req_valid_i/ready_o` + `fetch_req_pc_i` | 取指请求。fire 后在下一拍 S_LOOKUP 判决；hit 且 response 可接收时可同拍受理下一请求，命中稳态吞吐 1 packet/cycle |
| `fetch_rsp_*`（inst0/inst1/resp0/resp1） | 返回 raw packet。非跨页时 resp0/1 分别覆盖低/高 4B；跨页时分别覆盖第一页/第二页 byte segment；不是最终 per-slot response |
| `fetch_rsp_resp0_bytes_o` | resp0 从 packet 低地址起连续覆盖的字节数；非跨页/cache=4，跨页={2,4,6}。与 response 同 owner、同 stall 生命周期 |
| `priv_mode_i/satp_i/svpbmt_en_i` + `pmpcfg_i/pmpaddr_i` | 翻译/权限上下文 |
| `mmu_flush_i`（sfence/satp/fence.i commit） | ITLB/walk 与取指包 cache 整体失效（模块无独立 `flush_i` 端口） |
| `invalidate_*`（store fire 驱动） | 取指 cache 逐 store 盲失效：8B store footprint 直接清 m6/m4/m2/p0/p2/p4/p6 候选 index 的 valid(不读 pc 比较，超集覆盖)；lookup 两拍窗口由 cache 内旁路封堵 |
| `ifu_axi_aw*` / `ifu_axi_w*` | Svadu A-bit PTE 写回的两个独立 AXI channel；valid 从呈现到各自 fire 不撤回，payload 保持稳定，任一 channel 已 fire 后仍须补齐另一 channel |
| `ifu_axi_b*` | A-bit 写事务唯一 completion；桥从进入写 owner 起持续 `BREADY=1`，必须在 AW/W 都 accepted 后消费 B 才可释放 owner |

### 2.1 IFU-AXI-G1 写 owner 合同（CLOSED 2026-07-12）

| 条件 | 必须保持 | 允许清除/后继 |
| --- | --- | --- |
| `S_AD_UPDATE && !aw_done` | `AWVALID=1`，AWADDR/ID/LEN/SIZE/BURST 在 fire 前稳定 | AW fire 后只置 `aw_done`，不得重发 |
| `S_AD_UPDATE && !w_done` | `WVALID=1`，WDATA/WSTRB/WLAST 在 fire 前稳定 | W fire 后只置 `w_done`，不得重发 |
| `S_AD_UPDATE && mmu_flush_i` | 当前 PTE 地址/数据、AW/W accepted 位、`BREADY=1`；同拍 fire 仍记账 | sticky 标记旧取指语义 drop；不得回 IDLE，除非同拍已满足完整 B completion |
| sticky drop 且 B 延迟 | 写 owner、缺失 channel valid、payload、`BREADY=1` | 不接新 fetch、不发 AR、不交付 fetch response |
| sticky drop 且 B fire | 已发 AXI 写已完整排空 | 回 IDLE；忽略 BRESP，不 re-walk、不形成旧请求 fault |

`rst` 表示总线共同复位，可无条件清 owner；`mmu_flush_i` 不是 AXI reset，只能丢弃取指语义，
不能撤销已呈现 channel。AW/W/B 的事务 owner 与架构语义 owner 必须分离。

### 2.2 A-update 端口精确定义

| 信号 | 方向 | 宽度 | 有效拍 / reset | 握手与 owner |
| --- | --- | --- | --- | --- |
| `mmu_flush_i` | input | 1 | 同步控制；不属于 AXI reset | 只 sticky-drop fetch 语义；不得撤 write owner |
| `ifu_axi_awvalid_o` | output | 1 | `S_AD_UPDATE && !aw_done`; reset=0 | 与 AWREADY fire；stall 时 valid/address 稳定 |
| `ifu_axi_awready_i` | input | 1 | slave/xbar 当拍反压 | 只决定 AW fire，不得组合决定 AWVALID |
| `ifu_axi_awaddr_o` | output | XLEN | 当前 leaf PTE 物理地址 | 从 AWVALID 呈现到 fire 稳定；owner=当前 A-update |
| `ifu_axi_awid/len/size/burst_o` | output | 4/8/3/2 | 常量 `0/0/3/INCR` | 单 beat 8B 写，随 AW payload 稳定 |
| `ifu_axi_wvalid_o` | output | 1 | `S_AD_UPDATE && !w_done`; reset=0 | 与 WREADY fire；可早于/晚于 AW 独立完成 |
| `ifu_axi_wready_i` | input | 1 | slave/xbar 当拍反压 | 只决定 W fire，不得组合决定 WVALID |
| `ifu_axi_wdata_o` | output | XLEN | 锁存 leaf PTE `| A` | 从 WVALID 呈现到 fire 稳定 |
| `ifu_axi_wstrb_o/wlast_o` | output | STRB_W/1 | 全 1 / 1 | 与 WDATA 同 owner、同稳定期 |
| `ifu_axi_bvalid_i` | input | 1 | AW/W 均被下游接受后的 response | 只有桥 BREADY=1 才 fire；BRESP 属于当前 write owner |
| `ifu_axi_bready_o` | output | 1 | 整个 `S_AD_UPDATE` 恒 1；reset=0 | 允许 xbar/slave及时释放；flush 不撤 |
| `ifu_axi_bresp_i` | input | 2 | BVALID 有效拍 | non-drop 解释 OK/error；drop 只消费、不架构化 |

决定握手的状态全部属于桥：`state_q` 持有 write owner，`aw_done_q/w_done_q` 持有独立
channel accepted，sticky `ad_drop_q` 持有语义 drop。xbar 只保存/路由已 fire 的 channel，
不接管 bridge 的 flush 语义。

## 3. 主要数据通路
- **取指包 cache** `OooFetchPacketCache`：按 {PC, satp/priv 上下文} 命中，返回 inst0/1+resp0/1。
  SRAM 同步读协议：fire 拍(`fetch_req_fire_w`)发射 `lookup_en_i` 并锁存请求上下文
  (pc_q/paging_q/req_priv_q/req_satp_q)，判决在次拍 `S_LOOKUP` 完成；fill 只在 S_R0/S_R1，
  与 lookup fire 状态互斥(cache 内 1RW 断言把关)。S_LOOKUP hit 组合回包且
  `fetch_rsp_ready_i=1` 时可融合下一次 request accept，因此稳态不是 1/2。
- **ITLB** `OooSv39Tlb`：paging 时翻译 PC→paddr；miss 触发 page table walk(S_WALK_*)。
  lookup 输入接 fire 拍锁存值(pc_q/req_satp_q/paging_q)，使组合输出与 cache SRAM 读数在
  判决拍对齐；ITLB 本体保持 FF，不 SRAM 化。
- **PMP**：当前对 exec_paddr 与 `+4` 按两个固定 4B word 检查(判决拍，priv 用锁存
  req_priv_q，pmpcfg/pmpaddr 用当拍值——CSR 写经串行化无在飞取指交叠)；fault→
  resp=ACCESS_FAULT。这还不是按真实 C/32 指令范围收窄的 precise footprint，见 §9 IFU-ACCESS-G1。
- **跨页**：包尾跨 4KiB 页时，第二段需第二次翻译/取指并拼接(merge_cross_page)；bridge
  保留 first/second-page segment response 与 3-bit split，`OooFetchPacketDecode` 作为唯一 RVC
  长度 owner，再按实际 `[start,start+len)` 映射到 slot response。完整指令范围 fault 时输出
  NOP，防止 fault tail 垃圾进入 semihost peer 等旁路比较；
  **跨页包永不缓存**（fill 条件含 `!packet_cross_page_q`），每次命中该 PC 都重走两页翻译+两次读。
- **Svnapot 64KiB**：page walk 只接受 level0 leaf 且 `PTE.N=1 && PTE.PPN[3:0]=4'b1000`；
  非 leaf、level1/2 leaf 或其它 NAPOT 编码均报 instruction page fault。合法 leaf 的 PA 拼接使用
  VA[15:12] 替代 PTE.PPN[3:0]，再进入 PMP 与 fetch cache fill。

### 3.1 IFU-AXI-G1 状态 / 子模式

`S_AD_UPDATE` 同时承担正常完成与 flush-drain，不新增另一个输出译码状态：

```text
enter(A=0 leaf) -> S_AD_UPDATE, ad_drop=0, aw_done=0, w_done=0
S_AD_UPDATE --AW/W independent fire--> accepted bit 单调置 1
S_AD_UPDATE --mmu_flush--> ad_drop=1，状态与 payload 保持
S_AD_UPDATE --AW+W accepted, B fire, effective_drop=1--> IDLE
S_AD_UPDATE --AW+W accepted, B fire, effective_drop=0, B OK--> S_WALK_AR
S_AD_UPDATE --AW+W accepted, B fire, effective_drop=0, B error--> S_RESP/S_AR0
```

组合判据必须按下式实现，避免 flush 的 `if/else` 吞掉同拍 channel fire：

```text
aw_accepted_next = aw_done_q || aw_fire
w_accepted_next  = w_done_q  || w_fire
write_complete   = aw_accepted_next && w_accepted_next && BVALID && BREADY
effective_drop   = ad_drop_q || mmu_flush_i
```

除 `rst` 外，先承认当拍 AW/W/B fire，再用 `effective_drop` 选择 completion 后继。

### 3.2 IFU-AXI-G1 寄存器所有权

| 寄存器/上下文 | owner | normal completion | `mmu_flush` during write | `rst` |
| --- | --- | --- | --- | --- |
| `state_q` | 整笔 fetch/read/write transaction | re-walk/fault | 未 complete 留 `S_AD_UPDATE`；complete 回 IDLE | IDLE |
| `aw_done_q` | 当前 write 的 AW accepted | complete 清 0 | 保持并吸收同拍 fire | 0 |
| `w_done_q` | 当前 write 的 W accepted | complete 清 0 | 保持并吸收同拍 fire | 0 |
| `ad_drop_q` | 当前 write 完成后的 fetch 语义 | 新 A-update/complete 清 0 | sticky 置 1 | 0 |
| `ad_pte_q` | WDATA payload | re-walk 后可覆写 | 保持 | 0 |
| `walk_ppn_q/walk_level_q/pc_q/walk_second_q` | AWADDR 与 fault/re-walk provenance | 按原 FSM 使用 | 保持到 B completion | 0/default |

### 3.3 同拍竞争表

| 同拍事件 | channel 记账 | completion 后继 |
| --- | --- | --- |
| flush，无 fire/B | accepted 不变，drop=1 | 留写 owner |
| flush + AW fire 或 W fire | 对应 accepted_next=1，drop=1 | 未 complete 留写 owner |
| flush + 最后缺失 channel fire，B 未到 | 两 accepted=1，drop=1 | 留写 owner等 B |
| flush + B fire（两 channel 已 accepted） | B completion 有效，drop=1 | IDLE，忽略 BRESP |
| repeated flush | accepted/payload 不变，drop 保持 1 | 同上，幂等 |
| 无 flush + B OK | B completion 有效，drop=0 | S_WALK_AR |
| 无 flush + B error | B completion 有效，drop=0 | 按 first/second-page 归属 access fault |
| rst + 任意事件 | 不承认局部 fire（总线共同 reset） | IDLE，全清 |

## 4. PMP × 取指 cache 门控（iter1 性能修复；IFU-ACCESS-G1 仍有缺口）
**问题**：原实现 `cache_hit = cache_hit_raw && !pmp_active`、`fill = !pmp_active && ...`——
只要任何 PMP entry 激活就**整体禁用取指 cache**。真实 Linux/OpenSBI 永远配 PMP，导致取指永远
miss→走慢速 AXI，CPI 近 2x。
**当前 RTL**：命中在 `pmp_active=1` 时按 **PMP-grant 逐访问门控**、fill 恒开：
```
cache_hit_w = cache_hit_raw_w &&
    (pmp_active ? (!req_exec_pmp_fault && !req_exec1_pmp_fault &&
                   (!paging || itlb_hit))
                : 1'b1);
fetch_cache_fill_valid_w = (fill_r0 || fill_r1);   // 不再被 pmp_active 门控
```
- **FB-I1 当前只在 `pmp_active=1` 成立**：命中供给的包通过判决拍两个固定 4B checker；
  请求上下文用 fire 拍锁存值、pmpcfg 用判决拍当拍值。
- **FB-I2 的历史“不激活即允许”假设无效**：PMP 对 S/U 无匹配默认拒绝。M-mode bare 填 cache
  后切 S-mode、`pmpcfg=0`，cache context 又不比较 privilege，当前 `1'b1` 分支可绕过本应产生的
  instruction access fault。该 M-fill→S/no-PMP same-PC 用例归 IFU-ACCESS-G1 permanent RED。
- 下一合同：cache eligibility 无条件要求当前 privilege 的 PMP grant；固定 4B checker 若只提供
  conservative fast-hit 资格，过拒绝必须降级 exact slow path，不能直接形成 architecture fault。
- 经验：把“任意 PMP active”当成全局 cache-disable 是性能杀手；把“无 active entry”当成所有
  privilege 无条件允许同样错误。grant 必须来自当前权限与真实 footprint。

## 5. 状态机（简）
```
 S_IDLE/S_RESP --req fire(锁存+lookup_en)--> S_LOOKUP
 S_LOOKUP --hit+rsp_ready--> S_LOOKUP(同拍接受下一请求) / S_RESP
 S_LOOKUP --miss,no-trans--> S_AR0/S_R0[/S_AR1/S_R1 跨页] --> S_RESP
 S_LOOKUP --need-trans,itlb-miss--> S_WALK_AR/S_WALK_R(三级) --> 取指/RESP
 S_WALK_R --leaf A=0--> S_AD_UPDATE(AW/W 独立握手,等 B) --> re-walk
 S_LOOKUP --pmp/page fault--> S_RESP(resp=ACCESS_FAULT/PAGE_FAULT)
 已发读 --mmu_flush--> S_DRAIN(消费返回后回 IDLE)
 其它无已发事务状态 --mmu_flush--> S_IDLE
```
direct miss 的 AR 在 S_LOOKUP 判决拍发起(`lookup_direct_miss_w`)；hit 快速路径
fire→S_LOOKUP 判决，命中稳态可 1 packet/cycle。
A/D：leaf PTE 的 A=0 进入 `S_AD_UPDATE`，AW/W 可独立握手；两通道完成并收到 B 后，
若该请求未被 flush 则重新 page walk，再填 ITLB；若 flush 已把旧取指语义标为 drop，则仍
补齐 AW/W、消费 B，随后直接回 IDLE。reserved 扩展位检查在 Svpbmt/Svnapot 规则之后完成；ITLB
命中复核也必须带 leaf level，避免把合法 NAPOT hit 当成保留位 fault。

### 5.1 reset / flush / completion 优先级全序

1. `rst`：全总线共同复位，清所有 owner/context，回 IDLE。
2. `mmu_flush_i`：非写态沿用 read-drain/semantic clear；写态只置 sticky drop 并保持事务。
3. AW/W/B completion：flush/drop 同拍或既有 sticky drop 时，完成后回 IDLE；否则 B=OK
   re-walk，B error 按当前 first/second-page 归属返回 instruction access fault。
4. 普通 FSM 转移。

重复 flush 幂等；flush 与最后 AW/W 或 B 同拍时，channel fire/completion 仍有效，但 drop 在
语义后继上胜出。排水期间 fetch request/response 与新 AR 均禁止。

## 6. 验证
- riscv-tests `rv64ui`(取指正确性)、`rv64mi/si`(特权/翻译)、ACT4 Sv39/PMP。
- iter1 A/B(同配 PMP)：add 2052→1086、matrix-mul 22094→8508；riscv-tests 271/0 不变。
- 自修改代码：`invalidate_*` 逐 store 失效路径覆盖 8B store footprint；fence.i 作为 stop/drain 系统指令在
  commit 拍拉 `mmu_flush_i`，整块清 ITLB 与取指包 cache，并配合 redirect 保证后续重新取指。
  历史缺口见 `../arch/history/rtl-ground-truth-2026-07-03.md` §3.1（已归档）；当前 RTL 已由 `CTRL_FENCEI_BIT`
  与 `OooFetchPacketCache.same_fetch_window` 的 8B footprint 修复。
- IFU-AXI-G1 先以旧 RTL 得到 bridge 22 个精确合同 RED 与 bridge+xbar 3 个进展 RED；修复后
  AW-first、W-first、stall/repeated-flush、`flush+last-W+B`、drop BRESP error、normal B error
  与后一 master slave-side progress 全绿。12 个新增 `` `OOO_ASSERT `` 条件均由独立端口
  shadow 构造，并逐条故意违约命中唯一 marker；ratchet 为 50/50。
- IFU-FETCH-G2 先在旧 RTL 上以真实 Sv39 两页三级 walk 得到 12 行 B=2/4/6 × C/32
  矩阵中的 4 个精确 RED；当前 source 的 focused 5/5 与 module 89/89 全绿。额外 poison
  用 fault tail 拼成 `32'h40705013`，证明 faulted slot 净化为 NOP，不能伪造 semihost peer。
  9 个 provenance/assertion marker 均需独立故意违约证据，ratchet 为 59/59。
- IFU-AXI-G1 切片新鲜回归：module 88/88、Verilator 5.051 lint、RTL style、clean NPC build、AM 59/59、
  official p-mode 153/153。当前 `.config` 为 Difftest OFF，且本轮 core-regress 未包含
  privileged rv64mi/rv64si；这些证据关闭 IFU owner 合同，不越级证明全部 ISA/特权范围。

## 7. 关键路径
PMP(16 entry) × 两槽 + ITLB + cache 命中比较并行，全部移到 S_LOOKUP 判决拍(以锁存请求为源)，
fire 拍只剩锁存；原 fire 拍长组合链被同步读切断。
取指包 cache 默认 `OOO_FETCH_PACKET_CACHE_INDEX_W=12`（4096 项）；综合/面积实验可通过同名
define 显式缩小，但这只能改变容量/性能，不应作为语义修复手段。
cache 模块级 1-cycle 同步读两拍协议、盲失效与 819200 state-bit lower bound
由 `ooo-fetch-packet-cache.md` 的 Macro/OOC Contract v1 维护。

## 8. 变更记录
- iter1(2026-06-28)：取指 cache 从"PMP 全禁"改为 PMP-grant 逐访问门控 + fill 恒开。
- 本规范(2026-06-28)：文档化 fetch 桥与该修复。
- 2026-07-07：补齐 Svnapot 64KiB leaf 判定、PA 拼接与 ITLB hit 复核 level 约束。
- 2026-07-08：校正文档生命周期：fence.i 已是真 flush，store invalidate footprint 已覆盖 8B；
  记录 `OOO_FETCH_PACKET_CACHE_INDEX_W` 综合实验开关。
- 2026-07-08(SRAM 化)：新增 `S_LOOKUP` 判决拍状态(取指包 cache 1-cycle SRAM 同步读)：
  fire 拍(S_IDLE/S_RESP accept)只锁存请求+发射 lookup_en，hit/fault/walk 判决整体搬进
  S_LOOKUP(ITLB/PMP 用锁存值)；direct-miss AR 移到判决拍；hit 延迟 1→2 拍、吞吐 1→1/2
  (一期接受，重叠流水列二期；该吞吐限制已被 2026-07-11 hit fusion 超越)；FB-I1 的
  PMP 检查拍参照系改判决拍。
- 2026-07-11：同步 hit fusion、硬件 A update、read S_DRAIN，并把 IFU partial-write flush
  与 page-end C fault 归属登记为开放合同。
- 2026-07-12：关闭 IFU-AXI-G1。reset 与 mmu_flush 分离，`S_AD_UPDATE` 增加 sticky
  `ad_drop_q`；flush 后保持 payload/accepted 位、补齐 AW/W 并消费 B，再无声回 IDLE。
  新增独立端口 shadow 立即断言、bridge 矩阵与 bridge+xbar 后一 master 进展回归。
- 2026-07-12：关闭 IFU-FETCH-G2 的 second-page **page-fault provenance**。bridge 删除
  `first_bytes<4` 的伪长度判断，以 `fetch_rsp_resp0_bytes_o` 保留 byte-segment 边界；decoder
  单点解释 C/32 长度并做 fault-dominates-length/range。物理读 footprint、PMP/RRESP、branch
  后 lane1 page/access-fault capture 与 faulting-portion `mtval` 明确拆入 IFU-ACCESS-G1
  （含 IFU-LANE1-OWNER）/IFU-TVAL-G1。

## 已知隐患(2026-06-28 bug-hunt)
- **[已修复]** 跨页已缓存包槽1 PMP 复检用错物理地址(`req_exec1_paddr_w=paddr0+4` 对跨页是错页);PMP 运行期 allow→deny 第二页且无取指 cache 失效时可绕过槽1 PMP。详见 `.github/memory/known-issues.md`(隐患B)。根因修复:**跨页取指包不缓存**(fill 条件含 `!packet_cross_page_q`,每次重取经 walk-leaf checker 用正确物理地址重查两页 PMP,`OooFetchAxiBridge.v:279-296` 注释自证);非跨页包内 `paddr0+4` 恒同页,复检恒正确。

## 9. 合同状态（2026-07-12）

### IFU-AXI-G1：A-update 写通道的 flush-drain（CLOSED 2026-07-12）

**目标合同**：AW/W valid 一经呈现，flush 只能作废旧 fetch 语义，不能撤回 channel；
必须保持 payload、补齐剩余 channel 并消费 B 后才能释放事务 owner。

**修复前 RED 基线**：读通道有 `S_DRAIN`；`S_AD_UPDATE` 的 AW/W 独立 fire 后，
`mmu_flush_i` 会回 IDLE、清 `aw_done/w_done` 并撤 `BREADY`。AW-only + flush 已在 bridge
局部动态复现；bridge+xbar 进一步证明 IFU B owner 不释放、后一 master 到不了 slave。

**当前 RTL 与验收**：`ad_drop_q` 把语义 drop 与事务 owner 分离；AW-first、W-first、双 channel
accepted+B delayed、flush 与最后 channel/B 同拍、重复 flush、valid/payload stall stability、
B error drop，以及 xbar owner release/后一 master 精确地址+数据+B 全部动态闭合。独立 shadow
断言已进入 `` `OOO_ASSERT `` ratchet 50/50。本合同 CLOSED；PTW WRITE PMP 仍归下一条独立合同。

### IFU-FETCH-G2：page-end 压缩指令的 page-fault 归属（CLOSED 2026-07-12）

**目标合同**：bridge 不猜指令长度，只保存低地址连续 segment 的 response 与 split；decoder
按真实 C/32 长度把 response 映射给 slot。若 PC=page+0xFFE 且 inst0 为 16-bit，下一页只属于
下一条指令，下一页 page fault 不得覆盖当前 inst0；若 32-bit 指令跨 segment，fault 必须胜出。

**当前 RTL 与验收**：bridge 输出 `fetch_rsp_resp0_bytes_o`，跨页 resp0/resp1 分别保留
first/second-page provenance；decoder 用半开 byte range 映射并在完整 range fault 时净化 inst。
旧 RTL 的真实 Sv39 12 行矩阵精确 4 RED；当前 12/12、focused 5/5、module 89/89、lint/style/
contract/build 全绿，独立 reviewer 复跑 8 项无 G2 blocker。本合同只关闭 second-page page fault
归属；不得把它扩写成物理 access 语义完整。

### IFU-ACCESS-G1：精确物理取指 footprint 与 fetch-fault owner（OPEN）

当前 IFU 固定 `ARSIZE=8B`，xbar/slave 没有完整保留 size 语义，PMP 仍按两个固定 4B word
检查；跨页实际所需字节由 L0+L1 决定，不能用 B/(8-B) 简化。`IFU-LANE1-OWNER` 子节点另有
两个下游缺口：PairGate 会在 head0 branch 后无条件压掉 lane1 page/access fault，ROB-walk mode
对 instruction access fault 又有 cause filter。下一刀必须同时冻结增量/窄读、PMP/RRESP precise
footprint，以及 pred-NT branch 后 fault 保留 / actual-taken squash；G2 的 response remap 不能替代
下游 trap owner。

### IFU-TVAL-G1：跨 segment faulting portion 地址（OPEN）

当前 lane1/fetch fault payload 使用 slot 起始 PC。变长 32-bit 指令若只有后半段所在 segment
fault，`mtval/stval` 是否必须指向 faulting instruction portion 仍需按 ISA/platform 合同冻结并做
端到端回归；G2 只证明 response owner，不关闭 trap-value 语义。

### PTW-PMP-G1：A-update PTE 写回必须独立做 PMP WRITE 判定

**目标合同**：walker 对 PTE 地址的 READ 许可不能替代后续 A 位写回许可。进入
`S_AD_UPDATE` 前，必须按 PTE 物理地址、写宽度和 PTW 有效特权执行独立 PMP WRITE
检查；拒绝时不得发 AW/W，并按冻结的平台合同返回 access fault。

**当前 RTL**：walker 读 PTE 时有 read-side PMP 判定，但 A-update 发 AW/W 前未见独立
WRITE checker。该合同同时适用于数据桥，配套 owner 见 `ooo-mem-axi-bridge-fsm.md`。
