# RV64 SQ current-head allow-only lookup：本地 retained 结果

保留 `sq-current-head-allow-lookup-fusion-v1` 作为 local exploratory candidate。它把严格 full-exact
SQ allow 的 cached load D-cache lookup 前移到 bridge `S_IDLE` station admission 同拍，同时在同一
边沿锁存 active owner/final PA 并更新 LQ PA/class/strb/ordered；forward、replay、inexact 与 X/
非 onehot decision仍走原 registered `S_SQ_QUERY` 路径。

## 冻结 A/B

| workload | baseline ROI cycles | candidate ROI cycles | delta | cycle reduction | speedup | ROI retired |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 5,141,086 | 4,785,064 | -356,022 | 6.9250% | 7.4403% | 3,183,617 / 3,183,617 |
| Dhrystone | 9,151,522 | 8,481,505 | -670,017 | 7.3214% | 7.8997% | 4,250,000 / 4,250,000 |

两项 speedup 的几何平均为 **7.6698%**。全程 cycles 分别为：

- CoreMark：5,226,858 → 4,868,641，减少 358,217；
- Dhrystone：9,184,130 → 8,512,990，减少 671,140。

两项均为 GOOD TRAP、DiffTest ON、终止码 0，SQ receipt 均为 complete/available/conservation=1、
overflow/malformed/invalid=0。

CoreMark 的 full commits 为 3,218,532 → 3,218,519。差异全部位于 ROI 之后：ROI start/end retired、
ROI retired、seed、iterations 和所有 CRC 均完全相同。CoreMark 在 ROI 后读取 cycle-derived RTC，
优化使报告从 `5141 ms / 5 Marks / 1.945` 变为 `4786 ms / 6 Marks / 2.089`，整数除法与格式化
路径因此少 13 条动态指令。该差异已按 contract 的显式口径精化记录；Dhrystone full commits
保持 4,260,624 完全相同。

## 因果归因

qualification baseline 的 ROI allow 机会为 CoreMark 470,188、Dhrystone 800,015。实际全局周期
减少分别兑现其 75.72% 与 83.75%；candidate 自身实际 strict allow/fire 为 497,125 与 810,015，
对应兑现 71.62% 与 82.72%。差距符合双 bank同拍只减少一个全局周期、OoO覆盖和后续 cache/AXI
延迟吸收。

performance-counter-v4 的直接归因也吻合：`cycle_memory_translation_order` 从 CoreMark 302,806、
Dhrystone 430,031 基本降为 0；Dhrystone memory latency 5,950,383 → 5,280,354，CoreMark
2,284,636 → 1,941,069。该候选删掉了目标 SQ query bubble，而不是靠退休口径或 workload 漂移
制造收益。

## Correctness evidence

- focused bridge：current allow lookup、旧 station PA、同拍 replacement、current→station-next 连续
  lookup、同步 owner/pending、lookup-result flush exact drop；forward/replay/inexact 三种 fallback；
  9 个安全域反例与 malformed production no-lookup。
- focused backend：双 bank current allow/LQ update、allow/replay 混合、X/非 onehot fail-closed、
  forward/replay不更新、malformed production双 bank、production-next update保持。
- V8S dual-memory、V9R SQ retry handoff、V11L retry-holder direct、LoadQueue、bridge/backend/wrapper
  regression 全部 PASS。
- 第一轮 focused 由旧 V8T assertion 漏列新合法 current lookup source而失败；修复其 source/class/PA
  authorization后，当前源码的 focused、stats-enabled Verilator lint 与 non-stats 全量 lint 均
  PASS；stats-enabled lint 无 `UNOPTFLAT`。
- 独立最终审计：RTL must-fix=0。

## 声明边界

候选 design ID 为
`sha256:78108874864cbfe2bb9a9c9753e3e7ae6dcf8f865aeb0d891c6cf4a566bb6cec`，candidate
binary SHA-256 为 `e461627031f31147d18cc9e32e5ac0a0f5994001293d0303ffbbe61d60316f26`。

本结果只建立功能与本地 CPI retained-point。新的功能组合锥包含
`station/final PA → MIQ/tracker/LQ exact → SQ CAM → D-cache SRAM enable`；尚未运行同身份、非 stats
mapped synthesis/STA/area/power，所以固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`，不
宣称 5 ns timing、面积或功耗合格。
