# RV64 current-head SQ 同拍资格化结果

结论：资格化通过，允许进入 **allow-only** 功能实现；`forward` 与 `replay` 不在本次融合范围。

功能冻结对照为 `adapter-input-aw-w-fall-through-v1`。修复后的 stats build 在两个 workload 上均保持
GOOD TRAP、DiffTest ON、终止码 0，并且 ROI cycles/retired 与全程 cycles/commits 都和功能前驱逐项
完全相同。

| workload | ROI cycles | ROI retired | exact | allow | allow / exact | allow / ROI cycle |
|---|---:|---:|---:|---:|---:|---:|
| CoreMark | 5,141,086 | 3,183,617 | 504,088 | 470,188 | 93.2750% | 9.1457% |
| Dhrystone | 9,151,522 | 4,250,000 | 840,012 | 800,015 | 95.2385% | 8.7419% |

CoreMark 全程为 5,226,858 cycles / 3,218,532 commits；Dhrystone 全程为 9,184,130 cycles /
4,260,624 commits。两份 receipt 均为 `complete=1`、`available=1`、`overflow=0`、
`malformed=0`、`invalid=0`、`conservation=1`。

动态 allow 次数只是可删除 query bubble 的事件上界，不等于端到端必然减少的周期数：部分 bubble
可能与 ROB 头部无关、被其他长延迟遮蔽，且前端/执行/内存并发会重排临界路径。资格化计数因此只
授权功能 A/B，不作为 CPI、综合、STA、面积或功耗结论。

证据绑定：

- RTL design ID：`sha256:769a81eb256c21112a76e9c46eb57f8a98a637fba7c0a04687a132bfb1dea1ab`
- production RTL：155 files
- executable SHA-256：`f08709fb16a6d2cd98bcb8b2acf4ea1da13469ea81d37c800330a3b0ef608e64`
- parser 的 bare/truncated duplicate marker 缺口已修复，15/15 单测通过
- focused bridge/backend、V8S dual-memory、V9R retry handoff、bridge regression 与 Verilator
  lint 全部通过；lint 无 `UNOPTFLAT`
- 独立 RTL 审计最终 must-fix：0

本 task-run 仍固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`；这些状态只表示测量切片
本身不进入生产 promotion，不阻止后续独立的 allow-only 功能候选接受验证。
