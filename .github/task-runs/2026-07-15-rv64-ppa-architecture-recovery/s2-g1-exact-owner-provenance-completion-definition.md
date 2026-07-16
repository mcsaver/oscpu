# S2-G1 / R4-S1-ID exact-owner-provenance completion definition

> 状态：`definition_frozen / implementation_RED`
>
> 本文件是 R4-S1-ID 的伴随实施定义，不修改也不替代 hash-bound 架构/PPA 合同、
> R4-P0A 时序/语义底线、R3.6 性能/logic-area 锚或 typed ABI 原文。
>
> 本 checkpoint 仍沿用当前一宽 bridge/translation/cache compatibility path；它不是
> architecture seed，不解除 DI-3/DI-5/OOO-3 RED，也不宣称 LQ4、双 AGU、双 translation、
> 双 cache admission、双 memory completion 或完整双 memory datapath。

## 1. 输入与范围裁决

已完整读取：

- `npc/rv64/design/specs/ooo-memory-typed-abi.md`；
- `evidence/ppa-r4-memory-order-design/README.md`；
- `tmp/r4-true-dual-mem-path-audit/{audit.md,integration-dag.md,SHA256SUMS}`。

本轮采用审计后的首 checkpoint：`R4-S1-ID exact-owner-provenance`。与早期 G1 草案相比，
本轮明确**不新增 LQ4**，也不把 ROB tag、MIQ FIFO head、SQ index、request lane 或 bridge
物理端口号当成 token。真实 LQ4、双 owner/双 datapath 属于后续 S2 原子阶段。

## 2. 完成态必须同时成立的事实

### 2.1 唯一创建与 live-token 守恒

1. memory issue reservation 第一次 capture 一个真实 memory uop 时，恰好分配一次
   `owner_token[4:0]`，并捕获 `owner_kind[1:0]`、`mmu_epoch[1:0]`、原始
   `fault_tval[63:0]`。
2. token 由 modulo-32 allocator 与 32-bit live bitmap 管理；allocator 不得选择本拍开始时
   已 live 的 token，即使该 token 本拍 terminal/free，也不得同沿复用。
3. allocator 单元必须具备两路 allocation 与两路 tagged terminal/free 的守恒能力，覆盖
   双 alloc、双 terminal、alloc+terminal 同拍；当前 canonical compatibility adapter 只接活
   capture lane0，不能据此声称双 memory。
4. `alloc_count - free_count == popcount(live_bitmap)`；重复 free、free 非 live token、双 alloc
   同 token、分配 live token 均为契约错误。

### 2.2 tuple 端到端不重建

逻辑 owner tuple 固定为：

```text
{owner_kind[1:0], owner_token[4:0], mmu_epoch[1:0], fault_tval[63:0]}
```

tuple 必须从 backend capture 原样贯通：

```text
backend capture
 -> bridge request station
 -> bridge active owner / PTW phase / target phase
 -> bridge response skid
 -> MIQ exact owner
 -> architectural response consumer
```

STORE 额外必须保持同一逻辑 owner：

```text
STORE capture
 -> probe MIQ / bridge response
 -> SQ fill 保存 tuple
 -> SQ physical drain 输出同 tuple
 -> drain MIQ / bridge B terminal echo
 -> SQ exact terminal / release
```

probe、PTW、retry、pretranslated drain 和 B 都是同一 STORE 的 phase，禁止重新分配 token。
`fault_tval` 始终是 capture 时的原始 faulting VA；pretranslated drain 不得从 PA、live VA、
ROB tag 或 SQ head重建。

### 2.3 exact-match、kill/drop 与 ABA

1. MIQ 保存完整 tuple；response 只有在
   `{kind,token,epoch}` 与目标 live owner 精确相等时，才允许 WB、SQ fill、SQ terminal、cache
   fill/maintenance 或 architectural fault。FIFO head 只能提供候选位置，不能替代比较。
2. mismatch response 必须被 transport drain，但不得产生 architectural completion 或新的
   target side effect；nonkill STORE mismatch 是 fatal contract violation，不能静默 drop。
3. request/response backpressure 时 tuple、fault/class 和 operation payload 全部稳定；token
   equality 只能在寄存 response consumer 端检查，不得进入 request-ready、bridge-ready 或
   MIQ-head→bridge 的组合回路。
4. selective/global kill 对尚未 external-fire 的 LOAD/PROBE/ATOMIC owner可取消并释放；已经
   fire 的 owner保留 live token到唯一 response drain，响应按 effective-kill drop，禁止 WB/SQ fill。
5. STORE probe 已成功填入 SQ 后，token 由 SQ 生命周期拥有；未 fire physical write 的 killed
   STORE 在 SQ 真正 squash 时释放。`request_sent` STORE 在 aggregate B terminal 前不得释放，
   flush 后仍按 T4N nokill 语义 drain；B terminal 后仅在现有精确 release 边界释放。
6. `response + kill` 同拍按 `effective_kill` 优先于 architectural completion，但 response
   仍 terminal/free 恰一次。迟到旧 token、reuse 后旧 response、同拍 kill+response均不得污染
   新 owner（ABA 防护）。

### 2.4 epoch 不是占位符

`mmu_epoch` 不得常 0，也不得把通用 `mmu_flush` 脉冲直接冒充 effective context change。
完成态必须有唯一 epoch owner：

- 只对 typed ABI §6 列出的**有效值改变**或 privilege transition 产生窄
  `effective_context_change`；no-op/locked CSR write 不推进；
- change 只可在 `mem_context_quiet` 时提交并令 2-bit epoch +1；
- capture 采样当时 epoch，所有 phase原样 echo；
- epoch mismatch 不 WB、不 SQ fill、不 cache fill、不 architectural fault，并有 non-vacuous
  negative；nonkill STORE mismatch 报 fatal；
- wrap 只能发生在没有旧 owner 的 quiet 边界，不能用 2-bit wrap容忍 stale response。

若这一事实尚未实现，则 token/tuple 子阶段只能记录为 intermediate GREEN，整个
`R4-S1-ID` 仍保持 RED；不得以常量 epoch 把 checkpoint 标记完成。

## 3. RED -> GREEN focused 门禁

### 3.1 必须先在旧 RTL 观察到的 RED

| ID | 旧实现失败点 | 非真空证据 |
| --- | --- | --- |
| ID-R01 | token reuse 后注入旧 response，旧 RTL无真实 token/exact match | old response会命中 FIFO head/ROB候选，或静态证明字段缺失 |
| ID-R02 | response `{kind,token,epoch}` 任一位 mismatch | 旧 RTL仍按 MIQ head消费/完成，或接口根本无字段 |
| ID-R03 | response 与 selective/global kill 同拍 | 证明旧 owner可能提前消失、完成顺序不由 effective-kill统一控制 |
| ID-R04 | STORE probe→SQ→drain→B | 旧 RTL只保 ROB/head，无法证明同 token且 tval/epoch不变 |
| ID-R05 | 双 alloc、双 tagged terminal与 alloc+terminal 同拍 | 旧 RTL没有 live-token allocator/守恒单元 |
| ID-R06 | effective context change / no-op change / nonquiet change | 旧 RTL没有真实 epoch owner，或 epoch为常量/错误 pulse |

RED 不能只写“缺端口”；至少一个动态 old-RTL test 或编译期 contract-negative 必须对每类承重
事实产生唯一 marker，且 mutation 移除 exact match/live-bit/effective-kill/quiet gate 后必须重新 RED。

### 3.2 GREEN focused

1. owner allocator unit：32-token wrap、双 alloc、双 free、alloc+free、no-same-edge-reuse、
   duplicate/free-nonlive negative、守恒计数。
2. MIQ unit：tuple push/hold/head、exact response match、mismatch drain/drop、kill+response、
   flush保留 DRAIN tuple、双 tagged terminal不覆盖。
3. SQ unit：fill保存 tuple、probe→drain echo、flush/squash release token、request_sent flush survival、
   B terminal exact match、B error与success、same-cycle terminal/release，T4N原测试不退化。
4. bridge unit：station/active/rsp tuple hold/echo，DTLB hit/PTW/pre-target fault/post-target R/B
   error、pretranslated STORE drain，不从 PA/ROB重建 tval/token；现有 typed class/fault测试保持绿。
5. backend focused：capture唯一 alloc，LOAD/ATOMIC terminal free，STORE ownership handoff到 SQ，
   stale/mismatch无 WB/SQ side effect，response+kill同拍无 ghost，token equality不进入 ready。
6. wrapper focused：typed tuple逐层连线完整，无悬空/常量 token/epoch，不改变当前单宽外部行为。
7. epoch unit/integration：effective-change、no-op/locked write、quiet gate、四次 wrap、mismatch negative。

所有承重 assertion 都必须有 mutation-negative 或显式违约探针证明非真空；只跑最终 PASS 不足。

## 4. 六类跨模块契约冻结

| 类别 | 本 checkpoint 冻结语义 |
| --- | --- |
| 握手 | request/response valid 到 fire 前不撤回，完整 tuple+payload 稳定；canonical 仍一宽 |
| stall | allocator credit只来自注册 live bitmap；exact equality不参与 ready；bridge/MIQ backpressure不改 owner |
| flush/kill | `reset > response terminal/effective kill accounting > flush/squash > normal capture`；fired transport drain/drop，nokill STORE保留 |
| 异常 | exact tuple命中后才可写原 ROB；年轻 owner完成不改变 ROB head精确异常序 |
| 访存序 | T4N ROB-head physical STORE、exactly-once request、aggregate B terminal、B后release保持不变 |
| 恢复真源 | owner身份唯一真源是 capture分配 tuple；ROB/SQ/MIQ/lane/head都只是关联元数据，不能重建 token |

## 5. RTL 拓扑前置约束

- 新 allocator/epoch owner若新增 module，必须一 module 一 `.v` 文件并纳入 filelist；testbench使用 `.sv`。
- allocator状态：`next_token_q[4:0]`、`live_q[31:0]`，组合候选为从 next开始的环形空位
  选择；两路选择互斥，free只影响 next-state，不让本沿 alloc复用旧 live token。
- canonical adapter：capture lane0接 allocator alloc0；alloc1 tie-off只能在明确命名的 compatibility
  边界，且有静态/动态证据说明未宣称双 memory。
- MIQ/SQ/bridge每个 entry/station/active/rsp均显式寄存 tuple，不允许大 function隐藏仲裁/FSM。
- critical path预算：token grant来自32-bit bitmap的分层优先选择但只到 capture register；tuple exact
  compare位于 response寄存 consumer，不接 request-ready；epoch effective-change先打成窄 pulse。
- 不新增 LQ，不改变 cache/translation吞吐，不删除 legacy一宽路径，不运行 Linux/PPA/full regression。

## 6. 完成/未完成声明

只有 §2 全部事实和 §3 focused门禁同时 GREEN，才可称
`R4-S1-ID exact-owner-provenance checkpoint complete`。即使完成，合法 claim 也仅为：

> 当前一宽 compatibility memory path 已具备真实 owner token、epoch、fault provenance、exact
> response matching、kill/drop/ABA防护和STORE probe→B同 owner生命周期基础。

仍必须显式保持 RED：LQ4、双 IQ memory terminal、双 AGU、双 xlate/final-PA、双 physical SQ
query、双 bank cache、双 tagged memory completion、DI-3/DI-5/OOO-3、architecture seed、200 MHz
以及 qualified power/PPA winner。
