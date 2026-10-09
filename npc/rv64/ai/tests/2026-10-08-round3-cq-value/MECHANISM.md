# R3：四配置消融与真实供值机制

冻结后的完整 R3 用四个独立 SystemTop 可执行文件验证；每个执行 7 个程序的普通/背压两种模式，共 **56 项完整 NEMU + R64_ASSERT 短测全部通过**。所有配置使用 host threads=1、同一 reference 与固定镜像。冻结 RTL 和 probe 在构建与测量期间没有更改。

## 对照准确性

- **双关 = 原 B**：14 项的 cycles/commits/dual/traps/reads/writes、全部 CPI_PROFILE、原 LOAD_PROFILE 均逐字段相同。复用原 retained baseline exe 与已有结果；缺少旧日志的 8 项已用该旧 exe 和本轮同一镜像补测通过，load_shift 的旧 B 普通/背压也已单独执行。
- **只开取消发布 = 双关**：上述全部共有计数、周期及 profile 相同。该控制变换在这些动态场景中保持周期合同。
- **只开值旁路 = 两项全开**：14 项上述结果完全相同，因此短测的周期变化来自值旁路。
- **profile 全开 = 无 CQ profile 的主候选**：14 项上述结果完全相同。CQ 关闭时，观测构建只保留目的 ticket 以独立识别 front；没有授权 early wake。这一观测方式在本组短测中没有改变行为。

完整逐字段对照、旧日志来源、实例和直方图见 [结构化矩阵](../../../results/ai-r3-20261008/MECHANISM-COMPARISON.json) 与 [详细矩阵报告](../../../results/ai-r3-20261008/MECHANISM-COMPARISON.md)。

## 程序周期

| 程序 | 原 B / 双关 | 仅取消发布 | 仅值旁路 | 联合 R3 |
|---|---:|---:|---:|---:|
| program | 1074 | 1074 | 1074 | 1074 |
| program-stalls | 1133 | 1133 | 1133 | 1133 |
| sv39 | 993 | 993 | 991 | 991 |
| sv39-stalls | 1079 | 1079 | 1078 | 1078 |
| sdtrig | 4075 | 4075 | 4074 | 4074 |
| sdtrig-stalls | 4207 | 4207 | 4207 | 4207 |
| lsu_contention | 29426 | 29426 | 29415 | 29415 |
| lsu_contention-stalls | 36006 | 36006 | 36006 | 36006 |
| backend_network | 4354 | 4354 | 4354 | 4354 |
| backend_network-stalls | 4439 | 4439 | 4439 | 4439 |
| load_chain | 114849 | 114849 | 106656 | 106656 |
| load_chain-stalls | 114893 | 114893 | 106702 | 106702 |
| load_shift | 14797 | 14797 | 13967 | 13967 |
| load_shift-stalls | 15099 | 15099 | 14726 | 14726 |

load_chain 普通减少 8,193 周期（7.1337%），背压减少 8,191 周期（7.1292%）；load_shift 普通减少 830 周期（5.6092%），背压减少 373 周期（2.4704%）。这些是该定向程序的周期变化，不能替代完整 CoreMark/Dhrystone 结果。

## 消费者确实提前，而非只增加 early 计数

probe 在每个 consumer birth 时保存其 source preg 对应的 producer **完整 tag**。producer 的首次 CQ front 独立核对 ticket、ROB generation、live、未完成、GPR/pnew 与取消资格；随后关联 consumer issue 和 RR 真正保存操作数的边沿，检查真实选择的来源和数值。tag/preg 重用时建立新生命周期。

front 时间戳是 CQ 捕获后第一次合资格 front 的预边沿采样；因此它与旧 response→CQ profile 的捕获时间相差一个边沿。两配置使用同一口径。

| load_chain 依赖读群体（普通及背压均相同） | 原 B / 双关 | 联合 R3 |
|---|---|---|
| 8,193 次主要依赖：front→issue | 2 拍 | 1 拍 |
| 8,193 次主要依赖：front→RR 实际 read | 3 拍 | 2 拍 |
| 另外 1 次依赖：front→issue/read | 5 / 6 拍 | 4 / 5 拍 |
| first_front / first_early | 8,194 / 0 | 8,194 / 8,194 |
| 实际读源：PRF | 8,194 次 | 8,194 次 |

同一首条 fulltag 实例 consumer=0x023、producer=0x021、preg=33、PC=0x8000000c：

| 配置 | front | early | WB 接受 | issue | RR read | 实际来源 |
|---|---:|---:|---:|---:|---:|---|
| 双关 | 91 | 无 | 92 | 93 | 94 | PRF |
| 联合 R3 | 91 | 91 | 92 | 92 | 93 | PRF |

**实际来源为 PRF 与提前一拍并不矛盾**：CQ 先使 IQ ready，随后原 WB 正常完成，消费者在更早的 RR read 边沿已经能从 PRF 读到该值。仅在“早醒后 WB 尚未完成”的场景中才需要直接 CQ 供值，下面的程序覆盖了该场景。

## 完整系统中的 CQ 直接供值

| 程序 / 配置 | 关联依赖读 | 实际 PRF | 实际 WB | 实际 CQ | early 次数 |
|---|---:|---:|---:|---:|---:|
| load_shift / both-off | 8232 | 8232 | 0 | 0 | 0 |
| load_shift / both-on | 8232 | 7873 | 327 | 32 | 2056 |
| load_shift-stalls / both-off | 8232 | 8232 | 0 | 0 | 0 |
| load_shift-stalls / both-on | 8232 | 7457 | 603 | 172 | 2056 |

普通 load_shift 的真实实例：consumer=0x0b7、producer=0x0b6、preg=46，front/early=318、issue=319、read=320；read 时尚未观察到正式 WB 接受（wb_seen=0），实际 CQ lane 0 提供 0x8765432187654321。另一实例使用 CQ lane 1。因此不仅验证了早唤醒，也在完整 NEMU 流程中实际执行了 CQ→RR 供值与移位相关依赖。

所有 56 项的 `identity_mismatch=0`、`value_mismatch=0`；probe 对真实读值不一致会 fatal。全部打印的 RR read 都在相应 issue 后一拍。

## 边界与解释

- 定向程序覆盖 64 种移位量、RV64/word 左移和两种右移、两个 load 的双源依赖、符号扩展、普通/背压以及重复 tag/preg 使用；长 WB 背压、blocked ingress、两 CQ lane、交接和 DEFER_READY 的精确时间反例另由模块 TB 提供。
- 每条 histogram 统计一个 source 的读取，一条指令可以出现多个 source；它们是重叠事件，不能相加为整核节省周期。32 桶包含全部 ≥32 拍。
- waiting cohort 只要求 consumer birth 不晚于首次 front；其他源、FU、信用和仲裁仍可能限制发射。load_shift 的跨运行部分样本存在调度推迟，不代表每条指令必然提前。
- trace 只打印每程序前 128 条，完整运行仍累计所有 histogram 并做值检查；跨运行按 fulltag/PC/preg 匹配的样本用于说明，不能冒称完成所有动态指令的一对一对齐。
- 本文只裁决机制及短测对照；完整基准、面积、setup/hold 与 1 ns 是否满足，由本轮完整结果单独裁决。
