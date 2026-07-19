# R4 架构恢复后的 PPA 对抗计划

> 状态：执行中。本文只规定本轮候选、共同起点和淘汰线；规范真源仍是
> `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` v2。本文不得降低九项
> DI/OOO hard gate，也不得把 S1 single-owner checkpoint 写成完整双发射。

## 1. 共同基线

本轮采用合取式基线，不允许候选挑选有利的单一历史点：

- 语义/时序实现底线：R4-P0A；必须保留 R4-S0 final-PA PMA/PBMT、SQ provenance、
  B-terminal cache maintenance，以及 P0A distributed WB-valid。
- 性能/logic-area 测量锚：R3.6；CoreMark `4,904,511 / 3,183,617`，Dhrystone10k
  `9,481,620 / 4,250,000`，logic area `1,605,803.92`。
- 5 ns 底线：worst slack `>= +0.10 ns`、TNS=`0`、violations=`0`、loops=`0`。
- 首个架构可行点：两个 benchmark 各自 throughput ratio `>=0.995`，logic area
  `<=1,766,384.312`；九项 architecture gate 与全部功能 gate 必须 GREEN。
- Power：activity coverage `<95%`、macro dynamic/leakage 不完整或 total area 不完整时，
  保持 `unqualified`。这种点最多是 `architecture_feasible_seed`，不得成为 front、canonical
  或 PPA champion。

R4-P0A 相对 R3.6 的 benchmark 上限为：CoreMark cycles `<=4,929,156`，Dhrystone10k
cycles `<=9,529,266`；retired instructions 必须与固定镜像锚点一致。

## 2. 先形成唯一 architecture seed

P/P/A 不能从当前 S1 partial 各自分叉。当前 bridge 仍只有一个 architectural memory owner；
在完整 S2 seed 前，任何 area 或 vectorless-power 数字都只能是诊断。

P0A 同镜像动态证据也把该结构缺口量化出来：

- CoreMark `evidence/r4-p0a-wb-valid/performance-abbaab/coremark/02-b/raw.log:85,89`：memory bucket `60.1%`、
  hazard `55.7%`，`mem req0/req1/rsp0/rsp1 = 829410/0/829410/0`；
- Dhrystone10k `evidence/r4-p0a-wb-valid/performance-abbaab/dhrystone_10000/02-b/raw.log:80,84`：memory bucket
  `86.5%`、hazard `69.8%`，`mem req0/req1/rsp0/rsp1 = 2214414/0/2214414/0`。

上述 bucket 可重叠，不能相加成 CPI 分解；但第二 request/response 计数恰为零是直接的结构证据，
因此首个 Performance 候选必须补齐真实第二 memory owner，而不是继续微调单 owner 仲裁。

seed 按可独立回退的切片形成：

1. `S1-TYPED`：CACHED/NC/IO typed class 从 final PA 贯通 bridge/backend/SQ，随后补
   owner token 与 MMU epoch；只有 CACHED 可以 lookup/fill/RMW，NC/IO 不允许 preview。
2. `P1-IFU-II1`：恢复 cache-hit steady-state frontend II=1；H1 fast response，`S_RESP`
   只作 skid/slow path，flush/AXI drain/owner hold 合同不变。
3. `P2-DUAL-MEM`：增加两路独立 AGU、translation admission、final-PA owner、物理
   byte-order query、banked cache admission、credit 与 tagged completion。不同 bank hit 可
   同拍接纳；同 bank/alias 只 replay younger。共享 PTW/AXI slow path可以仲裁，但不得串行
   无冲突 hit admission。
4. `ARCH-SEED`：同一 design id 上执行 DI-1..DI-5、OOO-1..OOO-4、module、official、AM、
   Difftest、固定镜像 benchmark、两次 fresh synth 与两次 exact-5ns STA；任一 RED 均不登记 seed。

store probe/drain 必须保持同一 owner identity；真实 store side effect 仍只有 ROB-head
`commit_authorized` owner 可以 exactly-once fire，并等 aggregate B terminal 后退休。第二
memory face 不能只是 IQ 外队列、单 reservation 或第二个端口外形。

## 3. 三个对抗候选

只有 `ARCH-SEED` 冻结后，下列候选才能从它的同一 hash 独立分叉。

### Performance 候选：`P-DUAL-HIT-THROUGHPUT`

- 主锥：双 AGU/双 TLB hit、双物理 SQ CAM、两 bank D-cache admission、双 tagged completion，
  以及 frontend II=1。
- 目标：64-cycle alternating-bank memory-hit trace issue IPC `>=1.90`；simple-ALU trace
  IPC `>=1.90`；CoreMark 先恢复至 CPI `<=0.90`，随后以 `<=0.65`、`<=0.60` 为里程碑。
- 淘汰：九门任一 RED、无冲突 memory IPC `<1.90`、任一 benchmark ratio `<0.995`、
  slack `<+0.10 ns` 或首 seed area 超限。相对 seed 的 weighted throughput 改善 `<1%`
  时只保留架构 seed，不称 Performance winner。

### Power 候选：`PW-SHARED-PMP-DECODE-ISOLATION`

- 主锥：把多份 PMP region bound/config decode 拆成一个不可变 descriptor 真源和多个 exact
  query；每个 owner 保留独立 paddr/size/RWX/priv/first-match，PTE read/write 权限 query 不合并。
- operand isolation：idle query 不翻动 range compare；两个 cache bank 的 enable/tag/data 只由
  已锁存 bank owner 且 `attr_valid && class==CACHED` 授权。
- 淘汰：PMP lowest-index priority、TOR/NAPOT/partial-cover/wrap/M/L/RWX mutation 任一漏杀，
  或 benchmark/area/timing 低于共同门槛。只有同 workload activity、coverage `>=95%`、
  macro-inclusive total power 的 ratio `>=1.005` 才能称 Power 改善；vectorless 下降不晋级。

### Area/timing 候选：`A-BALANCED-PMP-FOOTPRINT`

- 主锥：保留 16 路 exact overlap/full-cover；用 balanced prefix-OR 产生最低编号 winner one-hot，
  用 balanced AND/OR 选择 full/config；每 owner 只计算一次 `{wrap,last_addr}` footprint，供 PMP
  与 typed PMA 共同消费。
- 不允许：新增 translation/cache latency、跳过第一个 overlap-but-not-full fault、用 false path
  或删能力换 slack。
- 保留阈值：logic area 至少下降 `0.1%` 且 slack 不退；或 slack 至少改善 `50 ps` 且
  area ratio `>=0.999`（后一种只能叫 timing checkpoint）。功能、每 benchmark `>=0.995`
  与 exact-5ns hard gate 始终同时满足。

## 4. 对抗和最优裁决

1. Power 与 Area/timing 候选必须分别从原始 `ARCH-SEED` 分叉，不能先叠加后把收益归错轴。
2. 两个独立候选都通过后，再建立第三个组合候选并重跑全部证据；组合结果不能继承父候选绿点。
3. Performance、Area、Power 三轴使用同 workload、同频率、同 PVT/lib、同 macro inventory、
   同 image 与同 power window。每轴都用 A-B-B-A-A-B，综合/STA 每设计至少两次 fresh run。
4. 只在完整 feasible cohort 内求 Pareto front；三轴均不劣且至少一轴超过 epsilon 才支配。
   同一 front 内才使用等权几何平均排序。
5. 若真实 macro area/power 模型仍缺失，终局输出只能是“architecture seed / P-A proxy 最优”；
   `final PPA champion` 必须保持空，不能把 placeholder macro 的 0 W/0 area 当作胜利。

## 5. 当前启动点

- 架构/PPA policy 回归：`61/61 PASS`。
- S1.1 typed PMA/classifier leaves：已闭合。
- S1.2 bridge：已到独立可编译边界；正在原子贯通 wrappers/backend/SQ，尚未形成可交付 design id。
- 当前 Power readiness：`9` 个静态 blocker，`qualified_for_promotion=false`；复核输出归档于
  `tmp/2026-07-15-rv64-ppa-architecture-recovery/power-qualification/`。
