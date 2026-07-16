# 规范：取指 AXI 桥 OooFetchAxiBridge

> 模块：`vsrc/frontend/OooFetchAxiBridge.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：**主路径已实现**（含 fence.i 真 flush、Svnapot 64KiB、硬件 A update 与
> exact-halfword fetch）；IFU-AXI-G1、IFU-FETCH-G2 已于 2026-07-12 关闭，
> IFU-ACCESS-G1 于 2026-07-13 scoped 关闭。T3R 请求/响应非穿透边界、T3W
> ITLB/PMP registered authorization boundary、T3X derived-scratch 初始化边界与
> T4A fixed-role candidate→execution context、PTE READ authorization register boundary
> 已实现；IFU stalled-AR flush owner 与 T4F PTW PTE WRITE PMP 均已闭合。
> §9 的 IFU-TVAL-G1 已由 T4G 关闭；完整系统结论仍须结合 memory bridge 与最终回归。

## 1. 目的与范围
把前端取指请求(PC)落到 IFU AXI，返回一个 **fetch packet**（两条对齐的 32-bit 槽，支持 RVC）。
内含取指包 cache、Sv39 ITLB、PMP 检查、跨页拼接。单事务在飞。不负责分支预测/重定向(前端控制面)。
取指包 cache 的 lookup/fill/invalidate/clear 语义与 macro/OOC 前置合同见
`ooo-fetch-packet-cache.md`；本文只约束桥侧 PMP/ITLB/AXI/fence.i 事务语义。

## 2. 接口（要点）
| 信号 | 含义 |
| --- | --- |
| `fetch_req_valid_i/ready_o` + `fetch_req_pc_i` | 取指请求。只在 S_IDLE，或 S_RESP 旧响应同拍 fire 时 accept；candidate context 每拍无条件预装 raw live，fire 只取得标量 FSM owner。下一拍 S_CACHE_READ 用 candidate 发同步 SRAM/ITLB lookup，拍尾 candidate→exec，再下一拍 S_LOOKUP 判决。不得从 live request 组合穿透到 SRAM/response |
| `fetch_req_owner_pc_o` | frontend outstanding PC 唯一载荷真源。S_CACHE_READ 取 candidate PC，其余状态取 frozen exec PC；交接值保持。无 outstanding 时该 payload 可 stale，response stall/MMU flush 不得改变有效 owner |
| `fetch_rsp_*`（inst0/inst1/resp0/resp1） | 返回 raw packet。成功=`(OK,OK)`；fault 使用 successful-prefix/fault-suffix `(OK,cause)`，不是最终 per-slot response |
| `fetch_rsp_resp0_bytes_o` | 成功/cache=4；fault=首个失败 halfword offset `F∈{0,2,4,6}`。0 是合法 first-halfword fault。与 response 同 owner、同 stall 生命周期 |
| `ifu_axi_araddr/arsize/arprot` | instruction data=`translate(PC+offset),2B,exec`；PTE walk=`registered pte_addr,8B,data`。ARVALID 一经呈现，包含 flush 在内都必须保持 valid/payload 到 fire；被 flush 作废者进入对应 AR_DROP，fire 后在 S_DRAIN 吞 R |
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
  T3R 把 semantic accept 与物理读分成两个注册边界；T4A 把完整 context
  `{pc,paging,priv,satp,svpbmt}` 固定分成 candidate/exec 两种物理角色。candidate 每拍无条件
  跟踪 raw live，S_CACHE_READ 的 cache/ITLB lookup 只显式消费 candidate；该拍尾 exec 只按
  registered `state_q==S_CACHE_READ` 原子捕获旧 candidate。S_LOOKUP 及以后所有 transaction
  consumer 只显式消费 frozen exec。历史别名 `pc_q/paging_q/req_*_q` 仅供 owner output、XMR
  debug 与 assertion 使用，不得回流功能数据通路。T3X 的 `paddr*`、walk/cross-page flag、
  gather data/offset 和 response/split 等派生 scratch 仍只在 S_CACHE_READ 拍尾初始化。
  S_LOOKUP 消费同步 SRAM payload 并把结果写 response Q；只有 S_RESP 对外 valid。fill 只在
  最终成功的 S_R0，与 1RW read 严格互斥。
- **ITLB** `OooSv39Tlb`：paging 时翻译 PC→paddr；miss 触发 page table walk(S_WALK_*)。
  lookup 输入接 candidate。T3W/T4A 在 S_CACHE_READ 拍尾同时锁存
  `lookup_itlb_hit_q`、`lookup_itlb_perm_fault_q`、translated-or-bare
  `lookup_exec_paddr_q` 与 exec context；S_LOOKUP 的两个 4B fast PMP checker 只消费这些
  registered owner。这样 PC→ITLB 与 PMP 不再和 cache-hit/response payload 串在同一拍，
  同时不增加 T3R cadence。
- **PMP fast gate**：两个固定 4B checker 只提供 cache-hit 的保守充分条件，且在所有
  privilege/pmpcfg（包括全零配置）下都运行。任一 fixed-window 拒绝只降级 slow path，
  不直接形成架构 fault。
- **PMP exact owner**：slow path 的每个 instruction AR 前，以完全相同的 PA、2B、EXEC
  运行 checker；fault 抑制该 AR，并以当前 `fetch_offset_q` 形成 fault frontier。A=0 leaf
  在产生 PTE write side effect 前也先对当前 exact PA/2B 做同一 EXEC PMP 检查。
- **PTW READ authorization boundary**：所有初始 walk、non-leaf next-level、second-page walk
  与 A-update B=OK re-walk 都先进入 S_WALK_CHECK。该静默拍原子寄存当前 PTE 物理地址与
  8B implicit-data READ PMP fault；下一拍 S_WALK_AR 的 ARADDR/ARVALID 只读这两个 q。
  A-update AWADDR/debug 地址复用 registered address，但 READ 许可不等价于 WRITE 许可。
- **PTW WRITE authorization（T4F）**：A=0 leaf 在进入 `S_AD_UPDATE` 前，以 registered
  PTE physical address、8B、S-mode、WRITE 独立运行 checker。deny 返回当前 frontier 的
  instruction access fault，保留 successful prefix，且不发 AW/W、不填 ITLB、不续原取指；
  grant 才建立既有 write owner，随后 flush 仍按 IFU-AXI-G1 写必达/drain。
- **长度与 gather**：miss 从 offset0 开始，每次成功 R 只抽取 address-selected 2B lane，
  写入 `fetch_data_q`。offset0 成功后才知道 L0 prefix；随后按已经成功的 prefix 依次决定
  offset2/4/6，最终只访问 `0,2,...,N-2`，其中 `N=L0+L1∈{4,6,8}`。未访问 tail
  保持 reset 后的确定性 0。
- **跨页**：只有下一个实际需要的 halfword 跨 4KiB 页时才翻译第二页；`N<=B` 不得
  因固定 8B packet 尾部越页而 walk。已成功 prefix 在 second-page walk/PMP/RRESP/A-update
  期间保留。跨页包仍不缓存，避免 fast checker 用 `paddr0+4` 代替第二物理页。
- **Svnapot 64KiB**：page walk 只接受 level0 leaf 且 `PTE.N=1 && PTE.PPN[3:0]=4'b1000`；
  非 leaf、level1/2 leaf 或其它 NAPOT 编码均报 instruction page fault。合法 leaf 的 PA 拼接使用
  VA[15:12] 替代 PTE.PPN[3:0]，再进入 PMP 与 fetch cache fill。

取指 cache 1RW 端口所有权冻结如下：

| bridge 状态/事件 | `lookup_read_en_i` | semantic accept (`lookup_en_i`) | SRAM 写 | 可见语义 |
| --- | ---: | ---: | ---: | --- |
| S_IDLE | 0 | 0 | 0 | request fire 只取得 FSM owner；candidate 已在该沿预装完整 context，物理 SRAM 保持关闭 |
| S_RESP | 0 | 0 | 0 | response stall 保持 payload；旧响应 fire 可同拍锁存 replacement request |
| S_CACHE_READ | 1 | 1 | 0 | 只用 candidate 发 SRAM/ITLB lookup；拍尾同时捕获 ITLB/PA authorization 与 candidate→exec |
| S_LOOKUP | 0 | 0 | 0 | 消费上拍 SRAM payload与 registered ITLB/PMP owner，拍尾写 response Q 或进入 slow path |
| S_R0 final successful fill | 0 | 0 | 1 | fill PC/payload 写入；物理读写严格互斥 |
| 其它 walk/AR/R/drain/write 状态 | 0 | 0 | 0 | 不占 payload SRAM 端口 |

`mmu_flush_i` 组合压低 fetch ready，并同步 clear cache/TLB。candidate 在包括 flush 在内的所有
非 reset 拍继续采 live；exec 只在旧 state=S_CACHE_READ 时捕获旧 candidate，flush 不进入其
宽 D 门控，其余状态保持。S_CACHE_READ+flush 仍完成值保持交接，但事务随即作废；无有效
outstanding 时 owner payload 可 stale。普通非写态 flush 清逻辑 scratch，唯独已呈现且 stalled
的 AR 必须转 `S_WALK_AR_DROP/S_FETCH_AR_DROP` 并保留 payload 真源，直到 AR fire 后进
S_DRAIN 吞 R；已 fire 的读直接排水。S_AD_UPDATE 中则 exec、registered PTE address、AD payload
与 AW/W/B owner 保持到 B completion，仅 sticky-drop 架构语义。raw SRAM payload 在 semantic
hit=0 时是 don't-care，禁止被任何架构路径消费。

### 3.1 IFU-AXI-G1 状态 / 子模式

`S_AD_UPDATE` 同时承担正常完成与 flush-drain，不新增另一个输出译码状态：

```text
enter(A=0 leaf) -> S_AD_UPDATE, ad_drop=0, aw_done=0, w_done=0
S_AD_UPDATE --AW/W independent fire--> accepted bit 单调置 1
S_AD_UPDATE --mmu_flush--> ad_drop=1，状态与 payload 保持
S_AD_UPDATE --AW+W accepted, B fire, effective_drop=1--> IDLE
S_AD_UPDATE --AW+W accepted, B fire, effective_drop=0, B OK--> S_WALK_CHECK
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
| candidate context | 下一次 S_CACHE_READ lookup | 每个非 reset 拍采 raw live | write/flush 期间仍可变化，但不是 transaction owner | 0/default |
| exec context | 整个有效 fetch transaction | S_CACHE_READ 拍尾从 candidate 捕获，其余保持 | 保持到 B completion；普通 flush 后只成为 invalid stale payload | 0/default |
| `walk_ppn_q/walk_level_q/walk_second_q` | walk/re-walk provenance | 按原 FSM 使用 | write owner 中保持到 B completion | 0 |
| `walk_pte_addr_q/walk_pte_pmp_fault_q` | 当前 PTE READ address + 8B READ-PMP verdict | S_WALK_CHECK 原子捕获；AR/AWADDR/debug 消费 | 普通 flush 不驱动有效 AR；write owner 保持 address provenance | 0 |
| `S_*_AR_DROP` + fetch scratch | 已呈现但被 flush 作废的 AR payload | AR fire 后进 S_DRAIN | 重复 flush 与反压期间完整保持 | IDLE/0 |

### 3.3 同拍竞争表

| 同拍事件 | channel 记账 | completion 后继 |
| --- | --- | --- |
| flush，无 fire/B | accepted 不变，drop=1 | 留写 owner |
| flush + AW fire 或 W fire | 对应 accepted_next=1，drop=1 | 未 complete 留写 owner |
| flush + 最后缺失 channel fire，B 未到 | 两 accepted=1，drop=1 | 留写 owner等 B |
| flush + B fire（两 channel 已 accepted） | B completion 有效，drop=1 | IDLE，忽略 BRESP |
| repeated flush | accepted/payload 不变，drop 保持 1 | 同上，幂等 |
| 无 flush + B OK | B completion 有效，drop=0 | S_WALK_CHECK |
| 无 flush + B error | B completion 有效，drop=0 | 按 first/second-page 归属 access fault |
| rst + 任意事件 | 不承认局部 fire（总线共同 reset） | IDLE，全清 |

## 4. PMP × 取指 cache 门控（IFU-ACCESS-G1 CLOSED）

历史上先后出现过两个方向相反的错误：任意 PMP active 就整体禁用 cache，和 pmpcfg 全零就
无条件允许 hit。后者会让 M-mode 填入的 same-PC packet 在切换到 S-mode 后绕过 default-deny。

当前 RTL 把“cache 资格”和“架构 fault owner”分开：

```text
fast_hit = raw_hit && fixed4_checker0_grant && fixed4_checker1_grant
           && (!paging || itlb_hit)
fixed checker reject -> exact 2B slow path
slow path checker reject at F -> no AR, raw response=(OK, ACCESS_FAULT, F)
```

- fixed checker 永远运行，不存在 `pmp_active==0` bypass；M-fill→S/no-PMP same-PC 动态用例
  必须 miss 到 slow path并在 F=0 fault。
- fixed 4B window 是 conservative sufficient condition。合法 C/C packet 即使 `PC+4` 被拒绝，
  仍可经 exact offset0/2 slow path成功；fixed reject 不是 fault。
- exact checker 与 instruction AR 共用 `fetch_current_paddr_w`、size=2B、EXEC，保证
  checker/side-effect owner 一致。PMP、page walk 或 RRESP 在 F 失败后都禁止 younger AR。
- fill 仅在完整 exact footprint 成功且非跨页时发生；未读 tail 维持 0。cache hit 稳态仍为
  1 packet/cycle，冷 miss 因精确半字事务有可量化的额外 latency。

## 5. 状态机（简）
```
 S_IDLE --req fire(candidate 已预装，取得 FSM owner)--> S_CACHE_READ
 S_RESP --旧 response fire + replacement req fire--> S_CACHE_READ
 S_CACHE_READ --candidate lookup；candidate→exec；锁存 ITLB owner；初始化 scratch--> S_LOOKUP
 S_LOOKUP --cache hit / first-frontier fault--> S_RESP
 S_LOOKUP --miss,no-trans/itlb-hit--> S_AR0(exact PMP+AR)/S_R0(2B gather)
 S_R0 --more,same-page--> S_AR0
 S_LOOKUP/S_WALK_R/S_R0/S_AD_UPDATE(B OK) --> S_WALK_CHECK --> S_WALK_AR/S_WALK_R
 S_R0 --more,next-page,paging--> S_WALK_CHECK/S_WALK_AR/S_WALK_R(三级) --> S_AR0
 S_R0 --N complete--> S_RESP
 任一 frontier PMP/page/RRESP fault --> S_RESP(OK,cause,F)
 S_WALK_R --leaf A=0--> S_AD_UPDATE(AW/W 独立握手,等 B) --> re-walk
 已呈现未 fire 的 AR --mmu_flush--> 对应 S_*_AR_DROP --AR fire--> S_DRAIN
 已 fire 读 --mmu_flush--> S_DRAIN(消费返回后回 IDLE)
 未呈现 AR/PMP fault/其它无总线 owner 状态 --mmu_flush--> S_IDLE
```
`S_AR1/S_R1` 仅保留历史 debug state 编码，exact fetch 不再进入。RDATA 只在 S_R0 决定
下一拍 offset/state，不存在 RDATA→下一 ARVALID/ARADDR 的同拍链；hit 快速路径
固定经过 request fire→S_CACHE_READ→S_LOOKUP→S_RESP，不允许 response 或下一个 request
穿透 cache 判决拍。S_RESP 仍可在旧响应 fire 同拍锁存 replacement request，随后按相同
两拍 read/decision cadence 前进。
A/D：leaf PTE 的 A=0 进入 `S_AD_UPDATE`，AW/W 可独立握手；两通道完成并收到 B 后，
若该请求未被 flush 则重新 page walk，再填 ITLB；若 flush 已把旧取指语义标为 drop，则仍
补齐 AW/W、消费 B，随后直接回 IDLE。reserved 扩展位检查在 Svpbmt/Svnapot 规则之后完成；ITLB
命中复核也必须带 leaf level，避免把合法 NAPOT hit 当成保留位 fault。

### 5.1 reset / flush / completion 优先级全序

1. `rst`：全总线共同复位，清 candidate/exec、PTW q、scratch 与全部 owner，回 IDLE。
2. `mmu_flush_i`：已呈现 stalled AR 保持 payload 并转 AR_DROP，已 fire read 进 S_DRAIN；
   无 read owner 时清 semantic scratch。写态只置 sticky drop 并保持事务。
3. AW/W/B completion：flush/drop 同拍或既有 sticky drop 时，完成后回 IDLE；否则 B=OK
   re-walk，B error 按当前 first/second-page 归属返回 instruction access fault。
4. 普通 FSM 转移。

重复 flush 幂等；flush 与 ARREADY 同拍时 AR fire 有效并进入 S_DRAIN；flush 与最后 AW/W
或 B 同拍时 channel fire/completion 也有效，但 drop 在语义后继上胜出。AR_DROP 只保持当前
AR，S_DRAIN 只拉 RREADY；两种排水期都禁止 fetch request/response、fill 与其它 AXI channel。

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
- IFU-ACCESS-G1 permanent historical runner 对 `b1b1156db` 得到 34 个精确 RED；current
  footprint4/poison4/RRESP12/walk12/PMP6 全绿。second-page A=0 normal/flush-drop、xbar
  slave-stall payload、UART firewall/LSU control、lane1 branch-resolve owner 与真实 DPI
  guard-page 全绿；module 93/93、assertion non-vacuity 4/4、contract current=60。
- Difftest-ON AM 59/59 与 official 177/177（含 rv64mi/rv64si）通过。CoreMark 10 iter
  为 2,913,259 cycles/CPI 0.905/CoreMark/MHz 3.503；相对 G2 baseline +2.14%，记录为
  exact cold-fetch transaction 的 correctness cost，不宣称 cycle-exact。
- IFU-AXI-G1 切片新鲜回归：module 88/88、Verilator 5.051 lint、RTL style、clean NPC build、AM 59/59、
  official p-mode 153/153。当前 `.config` 为 Difftest OFF，且本轮 core-regress 未包含
  privileged rv64mi/rv64si；这些证据关闭 IFU owner 合同，不越级证明全部 ISA/特权范围。
- T4A 当前新鲜证据：Bridge candidate/exec、PTW deny/register、WALK/Data stalled-AR flush、
  repeated flush、flush+READY 与 dropped-R 全部通过；focused frontend/core/xbar 8/8、module
  98/98、lint/style/contract(current immediate assertions=166)、source mutation 10/10 与动态
  mutation 5/5 全绿。fresh frozen netlist `0f1e7b22…928b` 的 exact 5.000ns STA 为
  `WNS=-0.130ns/TNS=-7.45ns/loops=0/power=0.117W`：相对 T3Z 明显改善但仍未闭合；top40
  已全部迁出 Bridge，下一瓶颈属于 FIFO-head classify→dispatch/outstanding，不能宣称 200MHz。

## 7. 关键路径
T3R 后 SRAM `en_i` 只依赖 registered `S_CACHE_READ`，S_IDLE/S_RESP/S_LOOKUP 均关闭读窗。
T3W 把 PC→ITLB 结果打拍，使 S_LOOKUP 的两个固定 4B PMP checker 只消费 registered PA。
T3X 再把 `paddr0_q/fetch_data_q` 等宽派生 scratch 从 request-fire D mux 移到
S_CACHE_READ state owner；fire 拍仅锁 immutable context，不增加状态或可见 latency。
T4A 物理删除 T3Z 的双 bank 与高扇出 active selector，改成固定角色 candidate→exec：
S_CACHE_READ lookup 只读 candidate，拍尾 exec 本地捕获，后续 PMP/walk/AXI/fill 只读 exec。
同时在 page walk 增加 S_WALK_CHECK，把 exec→PTE address/PMP cone 截止在 q，下一拍
registered address/fault 才进入 AXI/xbar。T3Z fresh exact-5ns 的 `WNS=-0.850ns` 是本刀输入
基线，不是 T4A 收敛结论；T4A 必须使用新鲜冻结网表复测。
每一刀是否改善 5ns WNS 只由新鲜同源综合/STA 判定，不能凭 RTL 结构宣称 200MHz。
exact miss 不再有 RDATA→下一 AR 的组合链；但最终 S_R0 仍存在
`RDATA -> address-lane shift -> halfword insert -> length判定 -> fetch-cache fill` 同拍锥。
fresh STA 若把该锥排进 leading family，下一刀应把 lane 抽取改为固定四路 case，并增加
FINISH 寄存拍后再 fill；在报告命中前不能只凭 RTL 观感宣称 200MHz 收敛。
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
- 2026-07-13：关闭 IFU-ACCESS-G1。miss 改为 registered exact-2B gather；raw response
  统一 success `(OK,OK,4)` / fault `(OK,cause,F)`；fixed 4B PMP 只作 fast gate；ARSIZE/
  ARPROT 贯穿 xbar/slave，DPI 使用标准 instruction lane 和 exact host range；device execute
  请求进 default-error；pred-NT branch 后 lane1 PF/AF 保留到 branch resolve。
- 2026-07-13(T3J)：把 fetch-cache 物理读窗与 semantic accept 拆分：读窗固定覆盖
  S_IDLE/S_RESP/S_LOOKUP，`fetch_req_fire_w` 仅锁存请求与置判决资格，S_R0 fill 物理写与读窗
  互斥。focused TB 新增 S_IDLE/S_LOOKUP/S_RESP 连续读、dummy read、S_RESP accept 与 final-fill
  动态承重；时序结论等待冻结网表的 5ns STA。
- 2026-07-14(T4A)：删除 T3Z 双 context bank/selector，改为 unconditional candidate preload
  与 S_CACHE_READ 本地 candidate→exec 交接；lookup/transaction consumer 物理分域。新增
  S_WALK_CHECK，寄存 PTE READ address/PMP verdict 后才进入 AXI。审查同时修复 IFU stalled
  AR 被 `mmu_flush_i` 撤回的问题：WALK/FETCH 各有 AR_DROP owner，保持 valid/payload 到 fire，
  再进 S_DRAIN 吞 R；新增独立端口 shadow、deny/flush/READY/poison 动态矩阵。

## 已知隐患(2026-06-28 bug-hunt)
- **[已修复]** 跨页已缓存包槽1 PMP 复检用错物理地址(`req_exec1_paddr_w=paddr0+4` 对跨页是错页);PMP 运行期 allow→deny 第二页且无取指 cache 失效时可绕过槽1 PMP。详见 `.github/memory/known-issues.md`(隐患B)。根因修复:**跨页取指包不缓存**(fill 条件含 `!packet_cross_page_q`,每次重取经 walk-leaf checker 用正确物理地址重查两页 PMP,`OooFetchAxiBridge.v:279-296` 注释自证);非跨页包内 `paddr0+4` 恒同页,复检恒正确。

## 9. 合同状态（2026-07-14）

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

### IFU-AR-G1：读地址 channel 的 flush owner（CLOSED 2026-07-14）

**目标合同**：`mmu_flush_i` 不是 AXI reset。ARVALID 一旦呈现，即使尚未 fire、随后发生
flush，也必须保持完整 payload 到 ARREADY；语义已 drop 的 read 在 AR fire 后必须消费 R，
且不得形成 fetch response、cache/TLB fill 或新请求进展。

**当前 RTL 与验收**：普通 WALK/FETCH AR 在 flush+stall 时分别转
`S_WALK_AR_DROP/S_FETCH_AR_DROP`，继续从冻结的 PTW q 或 exec/scratch 驱动原 payload；
flush+READY 同拍直接进 S_DRAIN。DROP owner 只发当前 AR，S_DRAIN 只收 R。独立端口 shadow
对上拍 stalled 的 addr/id/len/size/burst/prot 无 flush 豁免；WALK/Data、重复 flush、live poison、
READY 同拍及错误 R 均有动态牙齿。该 CLOSED 只覆盖 IFU bridge；LSU memory bridge 同型风险
仍须独立修复，不能越级称“全局 AXI read owner 已关闭”。

### IFU-FETCH-G2：page-end 压缩指令的 page-fault 归属（CLOSED 2026-07-12）

**目标合同**：bridge 不猜指令长度，只保存低地址连续 segment 的 response 与 split；decoder
按真实 C/32 长度把 response 映射给 slot。若 PC=page+0xFFE 且 inst0 为 16-bit，下一页只属于
下一条指令，下一页 page fault 不得覆盖当前 inst0；若 32-bit 指令跨 segment，fault 必须胜出。

**当前 RTL 与验收**：bridge 输出 `fetch_rsp_resp0_bytes_o`，跨页 resp0/resp1 分别保留
first/second-page provenance；decoder 用半开 byte range 映射并在完整 range fault 时净化 inst。
旧 RTL 的真实 Sv39 12 行矩阵精确 4 RED；当前 12/12、focused 5/5、module 89/89、lint/style/
contract/build 全绿，独立 reviewer 复跑 8 项无 G2 blocker。本合同只关闭 second-page page fault
归属；不得把它扩写成物理 access 语义完整。

### IFU-ACCESS-G1：精确物理取指 footprint 与 fetch-fault owner（CLOSED 2026-07-13）

**目标合同**：成功长度 `N=L0+L1` 只允许访问 offsets `0,2,...,N-2`；每个 instruction
AR 必须是同地址 exact EXEC-PMP 后的 2B transaction，首个失败 frontier F 停止 younger
translation/PMP/AR。raw ABI 为 success `(OK,OK,4)` / fault `(OK,cause,F)`。pred-NT branch
后的 lane1 PF/AF 必须保留到 branch resolve，actual-taken squash，actual-not-taken 精确 trap。

**当前 RTL**：bridge 用 registered offset/data loop；第二页只在 `N>B` 时 walk；fixed 4B
checker 仅作 cache fast gate且无全零 PMP bypass；xbar 锁存 size/prot 并用 execute allowlist
拦 device；sized DPI 只读取 nbytes。PairGate 不再按 branch 类型销毁 lane1 fault，DispatchGate
把该情形送入 barrier，PendingDispatchArbiter 只过滤无 provenance 的 pseudo ACCESS。

**动态牙齿**：旧 `b1b1156db` footprint runner 精确 34 RED，当前 footprint/poison/RRESP/
walk/PMP 全绿；F=0/2/4/6、M-fill→S default-deny、fixed reject→exact C/C、fault 后无
younger AR、slave stall payload、UART side-effect firewall、LSU offset5,size4 control 均为
permanent tests。真实 AxiDpiSlave→dpi.c→paddr.c guard-page test 证明 PMEM 尾端 2B 不做
隐含 8B host read；second-page A=0 normal/re-walk 与 flush-drop owner 也端到端覆盖。

faulting-portion TVAL 已由 T4G 关闭，LSU cross-lane AXI 标准化已由 T4I 关闭；
physical 200MHz 仍是独立于当前 gate-level proxy 的签核阶段。

### IFU-TVAL-G1：跨 segment faulting portion 地址（CLOSED 2026-07-14）

T4G 将 bridge 的首个失败 halfword offset 转成 packet-level fault address，并随 packet/FIFO
metadata 保存；lane0/lane1 page/access fault 都使用 faulting portion 地址作为 `mtval/stval`，
`xepc` 仍保持 instruction start。真实 page-end 32-bit 反例覆盖 offset 2/4/6，16-bit control
保持 slot PC，flush/branch owner 不改变该 payload。G2 只提供 response provenance，T4G 才关闭
trap-value 语义；证据见 `.github/task-runs/2026-07-14-rv64-t4g-fetch-fault-tval/`。

### PTW-PMP-G1：A-update PTE 写回独立 PMP WRITE 判定（CLOSED 2026-07-14）

**目标合同**：walker 对 PTE 地址的 READ 许可不能替代后续 A 位写回许可。进入
`S_AD_UPDATE` 前，必须按 PTE 物理地址、写宽度和 PTW 有效特权执行独立 PMP WRITE
检查；拒绝时不得发 AW/W，并按冻结的平台合同返回 access fault。

**当前 RTL 与验收**：`u_walk_pte_write_pmp_checker` 对 registered PTE address 执行
8B/S-mode/WRITE 检查；leaf 决策优先处理 deny，形成 `(OK,ACCESS_FAULT,F)` 并跳过
`S_AD_UPDATE`。`IFU-PTW-PMP-WRITE` shadow 断言证明真实 deny event 次拍只形成
access-fault response，且 deny 拍不呈现 AW/W；不以可被 XMR/CSR live 值污染的
`S_AD_UPDATE -> current checker grant` 作伪前提。
定向测试以 TOR R-only 页表区 + 后续 NAPOT RWX data 区证明三级 PTE READ 均允许、最终
EXEC 允许，但 A-bit WRITE 被拒绝且 AW/W 计数为零；RW allow 的原 A-update/re-walk
control 继续通过。数据桥的同一合同见 `ooo-mem-axi-bridge-fsm.md`。
