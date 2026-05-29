# Task Report

## 基本信息

- `task_id`: `2026-05-29-ooo-core-cache-bridge`
- `task_slug`: `ooo-core-cache-bridge`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-29`
- `updated_at`: `2026-05-29`

## 本轮补充

- `source_request`: 用户补充“最好一个 module 一个源文件”。
- `source_impact`: `NpcCoreTop.v` 不再继续承载 bridge 子模块，`OooFetchAxiBridge` 与 `OooMemAxiBridge` 已拆为独立源文件并加入 `vsrc/filelist.mk`。
- `capacity_ab`: 128-entry bridge cache 的全量 CPI 为 `0.973575`；1024-entry 保留版为 `0.912113`；2048-entry 仅为 `0.912050`，收益不足以承担面积/仿真状态增长；`pc+4` packet 预填版 miss 更少但 CPI 退到 `0.929679`，已撤回。
- `final_kept_result`: 1024-entry packet I-cache + 1024-entry word D-cache，CPU-test 全量 `40/40 PASS`，`cycles=71766/commits=78681/weighted CPI=0.912113`。

## 流程固化补充

- `source_request`: 用户指出 `add` 测试能力太弱，优化不能只看 `add`；每次必须跑 CPU-test 全量，并从全量中同时选择 CPI 最高、CPI 最低、最接近平均 CPI 的测试项目分析；还要求把全量优先、三样本分析、一个 module 一个源文件固化到本地流程。
- `local_rules_added`: 新增 `.github/instructions/npc-optimization-workflow.instructions.md`，并在 `.github/copilot-instructions.md`、`.github/AGENTS.md` 中挂接。
- `current_full_tsv`: `/tmp/ysyx-ooo-full-cputests-split-1024cache.tsv`
- `weighted_cpi`: `0.912113`

| sample_kind | test | cycles | commits | CPI | ic_miss | dload_miss | note |
| ----------- | ---- | ------ | ------- | --- | ------- | ---------- | ---- |
| `highest_cpi` | `dummy` | 59 | 12 | 4.916667 | 7 | 0 | 极短程序，暴露启动/固定开销 |
| `lowest_cpi` | `prime` | 2796 | 5158 | 0.542071 | 28 | 10 | 高吞吐负载，接近目标 CPI |
| `near_average_cpi` | `leap-year` | 1601 | 1692 | 0.946217 | 29 | 125 | 最接近当前全量加权平均 |

- `extra_weight_reference`: 按 `cycles - 0.5 * commits` 排序的高权重样本为 `recursion`, `hello-str`, `mersenne`, `pascal`, `bubble-sort`, `quick-sort`, `matrix-mul`, `crc32`；后续若三类必选样本之一过短，应额外并列观察这组 high-excess 样本，但不能替换掉三类必选样本。

## 同周期 demand miss AR 补充

- `source_request`: 用户要求每次优化都以 CPU-test 全量为正确性门槛，并从全量结果中选择三类代表样本共同分析。
- `kept_change`: `OooFetchAxiBridge` 与 `OooMemAxiBridge` 在 request fire 且 miss 的同一拍，如果 AXI `arready` 已经为高，直接以当前请求地址发起 demand miss `AR`；该路径只提前已有 demand read，不新增预取事务。
- `reverted_change`: D-cache 后台 next-word prefetch 曾让 `dummy/prime/leap-year/recursion/bubble-sort` 样本短跑变快，但 CPU-test 全量在 `bubble-sort` BAD TRAP，已撤回。
- `current_full_tsv`: `/tmp/ysyx-ooo-full-cputests-samecycle-ar.tsv`
- `weighted_cpi`: `0.870428`

| sample_kind | test | cycles | commits | CPI | ic_miss | dload_miss | note |
| ----------- | ---- | ------ | ------- | --- | ------- | ---------- | ---- |
| `highest_cpi` | `dummy` | 52 | 12 | 4.333333 | 7 | 0 | 极短程序，仍主要暴露固定启动/退出成本 |
| `lowest_cpi` | `prime` | 2760 | 5158 | 0.535091 | 28 | 10 | 当前最接近目标 CPI 的高吞吐样本 |
| `near_average_cpi` | `leap-year` | 1449 | 1692 | 0.856383 | 29 | 125 | 最接近最新全量加权平均 |

- `high_excess_reference`: 最新全量中按 `cycles - 0.5 * commits` 排序，权重靠前样本为 `recursion`, `hello-str`, `mersenne`, `pascal`, `bubble-sort`, `quick-sort`, `crc32`, `matrix-mul`。其中 `recursion` 仍是主要高额外周期样本 (`6744/4513/CPI=1.494350`)，下一轮不应只盯 `dummy` 这类短程序。

## 任务目标

- `source_request`: 用户要求先保证 CPU-test 全量正确，再基于每个测试 CPI 做优化；当前 OoO 已接入 `NpcCoreTop`，需要在真实 core 边界继续降 CPI。
- `goal`: 不回退到仿真顶层私有直连 PMEM，在 core 内给 OoO fetch/memory bridge 增加低风险缓存路径，并用全量 CPU-test 验证正确性。
- `scope`: `npc/single/vsrc/core/NpcCoreTop.v` 的 OoO fetch/memory bridge，`npc/single/vsrc/sim/NpcSimTop.sv` 的仿真统计观察，以及 CPU-test 全量 CPI 表。

## RTL 推导摘要

- `需求`: core-top 分离后，OoO 每个 fetch packet 需要经 IFU AXI-like bus 串行读 `PC` 和 `PC+4`，每个 load miss 都经 LSU bus，导致全量加权 CPI `4.690321`；优化必须仍从 `NpcCoreTop` 内部发起，不能恢复 `NpcSimTop` 私有直连。
- `协议`: 保留原 OoO fetch request/response 和 mem0/mem1 request/response ready-valid ABI；缓存 hit 也走 `S_RESP`，且允许 `S_RESP && response_ready` 同拍接下一 request，避免引入组合 response。
- `状态`: fetch bridge 最终保留 1024-entry direct-mapped packet I-cache，valid/tag 使用精确 fetch PC，payload 保存两个 word 与 response；mem bridge 最终保留 1024-entry PMEM word D-cache，valid/tag 使用 word address，payload 保存 32-bit word。
- `不变量`: 只缓存 OKAY PMEM 数据；store write-through 不被缓存吞掉；I-cache 在 store word 与 cached packet 范围重叠时失效并屏蔽同拍 hit/fill；reset 只清 valid，payload array 由 valid gate 保护。
- `数据通路`: fetch miss 仍串行 `AR0/R0/AR1/R1`，hit 直接装载 response 寄存器；load hit 直接装载 memory response 寄存器，miss 填 D-cache；store hit 按 `wstrb` merge，full-word store miss 可分配，所有 store 仍发 LSU write-through。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `baseline` | Codex | completed | core-top split result | CPI 瓶颈确认 | `add` `4012/839/CPI=4.782`, full weighted `4.690321` |
| `packet-icache` | Codex | completed | `OooFetchAxiBridge` | 128-entry packet I-cache + store overlap invalidate | `add` 降到 `1259/839/CPI=1.501`, `fence-i` PASS |
| `word-dcache` | Codex | completed | `OooMemAxiBridge` | 128-entry PMEM word D-cache + write-through merge | `add` 降到 `998/839/CPI=1.190` |
| `sim-stats` | Codex | completed | `NpcSimTop.sv` | OoO bridge cache event 统计 | `icache access=511 hit=471 miss=40`, `dcache load access=146 hit=64 miss=82` |
| `capacity-sweep` | Codex | completed | 128-entry bridge cache | 1024-entry 保留，2048-entry/pc+4 prefill 否决 | 1024-entry weighted CPI `0.912113`; prefill weighted CPI `0.929679` |
| `module-split` | Codex | completed | `NpcCoreTop.v` | 一个 module 一个源文件 | `OooFetchAxiBridge.v`, `OooMemAxiBridge.v`, `filelist.mk` |
| `same-cycle-ar` | Codex | completed | 1024-entry bridge cache | demand miss request 同拍发 `AR`，D-side prefetch 撤回 | CPU-test 全量 `40/40 PASS`, weighted CPI `0.870428`; prefetch 版 `bubble-sort` BAD TRAP |
| `regression` | Codex | completed | CPU-test binaries | 全量 CPI 表 | `/tmp/ysyx-ooo-full-cputests-split-1024cache.tsv`, `40/40 PASS`, weighted CPI `0.912113` |

## 关键产物

- `artifacts`: `npc/single/vsrc/core/NpcCoreTop.v`, `npc/single/vsrc/core/OooFetchAxiBridge.v`, `npc/single/vsrc/core/OooMemAxiBridge.v`, `npc/single/vsrc/filelist.mk`, `npc/single/vsrc/sim/NpcSimTop.sv`
- `logs_or_traces`: `/tmp/ysyx-ooo-full-cputests-idcache-final.tsv`, `/tmp/ysyx-ooo-full-cputests-split-1024cache.tsv`, `/tmp/ysyx-ooo-full-cputests-fetch-prefill.tsv`, `/tmp/ysyx-ooo-full-cputests-samecycle-ar.tsv`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/known-issues.md`

## 验证结果

| test | result | cycles | commits | CPI |
| ---- | ------ | ------ | ------- | --- |
| `add` | PASS | 968 | 839 | 1.154 |
| `recursion` | PASS | 6836 | 4513 | 1.515 |
| `hello-str` | PASS | 3436 | 2008 | 1.711 |
| `matrix-mul` | PASS | 6017 | 8960 | 0.672 |
| `string` | PASS | 1798 | 1641 | 1.096 |
| `cpu-tests all (1024-cache)` | PASS | 71766 | 78681 | 0.912113 |
| `cpu-tests all (same-cycle AR)` | PASS | 68487 | 78682 | 0.870428 |

## 当前阻塞点

- `blockers`: 无正确性阻塞；目标 CPI 尚未达成。
- `missing_dependencies`: Difftest 当前配置未启用，`--diff=default` 会提示 `CONFIG_NPC_DIFFTEST` disabled；本轮以 CPU-test 全量 GOOD TRAP 闭合。
- `risk_assessment`: 新 cache 是 direct-mapped 小缓存，不是完整 I-cache/D-cache 子系统；store/invalidate/PMEM-only 规则已经回归，但后续扩成 line-based cache 或多 outstanding 时必须重新证明自修改代码、unalign、store/load ordering。

## 下一步建议

1. 先补 OoO 路径的 issue/retire/control/memory stall 统计，再按全量结果同时看 `dummy/prime/leap-year` 与 high-excess 样本；不要只用 `add` 做 A/B。
2. 为 LSU 增加 response queue、多 outstanding 或最小 LSQ/store commit，避免 load miss 独占整条 memory bridge。
3. 回到控制流瓶颈：实现不引入 ready 组合环的 branch/ret checkpoint 投机或 ROB-age selective squash。

## 收尾结论

- `final_result`: 已在 core 内完成 packet I-cache + word D-cache bridge 优化、1024-entry 容量 A/B、一个 module 一个源文件拆分，并保留同周期 demand miss AR 优化。
- `evidence_summary`: OoO build PASS；1024-cache 全量 weighted CPI `0.912113`；same-cycle AR 全量 `40/40 PASS`，weighted CPI `0.870428`。
- `notes`: 这轮正确性优先，性能仍未达到 `CPI=0.5`，goal 继续保持 active。
