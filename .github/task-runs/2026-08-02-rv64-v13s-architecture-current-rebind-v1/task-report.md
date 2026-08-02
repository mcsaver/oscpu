# V13S current-design architecture rebind

## 分类与完成定义

- 唯一分类：`architecture`。
- workflow class：`development`，因为本轮会生成当前设计绑定的架构证据；在定位出真实 RTL 违例前不修改 production RTL。
- parent checkpoint：V13P aggregate-B response fusion，V13Q/V13R backpressure、DECERR、owner 与 retirement-hold 定向验证。
- completion definition：以当前完整 RV64 RTL source set 为唯一 design-id，区分九项 DI/OOO gate 的“仅证据过期”“静态 checker 漂移”“真实架构回归”，然后以最小充分运行恢复可采信的架构状态；任何未重跑 gate 均保持 GAP。
- promotion boundary：本轮不授权 arch-stable、CPI baseline、综合、STA、Power、Area 或 PPA promotion。

## 可证伪假设

- H1：V13P 只改变 store aggregate-B terminal path；DI-1..DI-5、OOO-1..OOO-4 的动态微架构能力未回归，九门 RED 主要来自 design-id/provenance 过期。
- H2：当前 `OooIntIssueQueue`/backend 重构使 DI-3/DI-4 静态源码判据锚点过期，但动态 capability、双 memory terminal owner 与 swap/promotion 行为仍成立。
- H3：DI-3/DI-4 的静态 RED 揭示了真实 capability metadata/atomic pair 行为回归；若独立源码复核或定向 TB 支持该解释，则本轮转为 production RTL fix，并先补齐接口契约和 RTL 四段式推导。

最低成本判别顺序：当前完整 design-id 重算 → DI-3/DI-4 静态红项独立复核 → 选择最小定向运行 → 必要时才扩大为九门 current-design rebind。

## 首次诊断

- 旧 `architecture-current.json` design-id：`sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`。
- 当前 checker 重算 design-id：`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`。
- 九门均为 RED；共同红项是完整 RTL design binding 与 `npc/rv64/Makefile` provenance 漂移。
- DI-3 另有三个静态红项：pair formation、plain-memory capability resident、两路 memory terminal owner。
- DI-4 另有一个静态红项：entry capability metadata 的 dispatch/compaction capture 计数为零。

这些结果只证明现有架构证据不可直接复用，尚不能区分 checker 锚点漂移与 production RTL 回归。

## 根因与实现

- H2 得到支持，H3 被本轮证据否定：V13I 将 IQ entry 改为 `ENTRY_STATE_W` packed payload 后，旧 checker 仍只匹配 `*_next_r[write_i]` 的逐字段 capture/copy，因而产生静态假红；未发现 production RTL capability 或双 memory owner 回归。
- `architecture_hard_gates.py` 新增 fail-closed concatenation 解析与单字段 packed route 核对，要求同一字段经过 `dispatch0/1_state_w -> compact_source_state_w -> compact_survivor_state_w -> compact_next_state_w -> *_next_r -> *_q -> selector`。legacy 与 packed 路径是两个显式结构分支，任一路都不能靠缺省计数通过。
- DI-4 核对 ALU capability 的双入口 capture、resident field、survivor/append route、unpack、Q commit、selector 与 swap；DI-3 对 plain-memory capability 复用同一结构证明并保留 AMO/FP 排除。
- `test_architecture_hard_gates.py` 增加 dispatch0/1、resident pack、unpack、Q commit、FP exclusion 等断链反例；V8O mutation 生成器同时支持 legacy 与 V13I packed slot1 capture，零锚点或多锚点仍拒绝。
- 两个 evidence builder 新增可选 `--run-id`，默认行为不变；V13S task-run 证据因此记录真实当前 run-id，而不是冒用历史 V8O/V8P id。
- 本轮没有修改 `npc/rv64/vsrc/**` production RTL。

## 当前设计绑定与定向观测

- 完整 RTL design-id：`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`；初次诊断、checker 修复后诊断、两项 evidence builder 与最终架构结果一致。
- 静态 source facts：DI-3 的 11 项与 DI-4 的 2 项全部 GREEN；修复前的三个 DI-3 静态红项和一个 DI-4 静态红项均已消失。
- DI-4 release/assert：各 12/12 program-slot permutation、12 same-cycle pair fire、24/24 exact full-PID match、0 static-lane-role violation，两个 profile 各一份唯一 `[RESULT] PASS`。
- DI-3 release/assert：各 15/15 pair key、4/4 ordinary dual-memory pair、8 个 distinct nonzero-generation PID、4 次 dual reservation、8 次 captured AGU match、2 次 store-store exact bind、10/10 AMO/LR/SC/FP exclusion、12-ingress collector exact capture/drain，四个 TB × 两个 profile 共 8/8 PASS。
- compile-success sensitivity：DI-4 为 6/6；DI-3 为 14/14 simulation rejection，加 1 个 simulation-PASS/source-checker-RED vacuity mutation，共 15/15。每个行为变异均保留 activation 与目标 `[CHECK-FAIL]` 日志，summary 保存 mutant/image SHA；编译镜像已按工作区清理策略删除。
- checker 回归：`test_architecture_hard_gates` 与 `test_directed_evidence_manifest` 合计 33/33 PASS。

关键绑定产物：

- `evidence/current-architecture-manifest.json`：SHA-256 `e44eeecd30d54f072d448980af26a2847c576b48b6e30b4fd76feb98ac9a5dd6`，只含 `no_static_lane_semantics` 与 `pair_matrix` 两项当前设计记录。
- `evidence/architecture-di34-current-result.json`：SHA-256 `97a0cfda514a4ff682d4196390758fff76027579c98a3c88bc77b92158b0890a`。
- `evidence/checker-unit.log`：SHA-256 `3c5d691945524c12035e7868d0d0a4ea4b004622f09d1075146d85d060356a4f`。
- `evidence/gates/no-static-lane-semantics.log`：SHA-256 `a7efda8925e47f056c3841427806b475339b67ab089b3a9606a67a1593f3a9dd`。
- `evidence/gates/pair-matrix.log`：SHA-256 `6114cc4fb3fddd4b740128470a38b98f0a47c62caa7f753d0a0496395851a534`。

## 架构裁决边界

- task-run scoped hard-gate 结果：DI-3 GREEN、DI-4 GREEN；DI-1、DI-2、DI-5、OOO-1、OOO-2、OOO-3、OOO-4 均保持 RED，因为本轮没有为这些门生成当前设计动态记录。
- `npc/rv64/eval/ppa/evidence/architecture-current.json` 未作为输出目标，仍保留旧 design binding；本轮没有把两项局部证据提升为 canonical、arch-stable、PPA baseline 或 architecture-feasible seed。
- 未运行 full-system、CPI、综合、STA、area 或 power；这些范围全部保持 GAP/unpromoted。

## 空间与产物策略

- 所有 `/tmp/rv64-v13s-*` baseline/mutation build、mutant source 与临时 JSON 已删除，相关 `__pycache__` 也已清理。
- task-run evidence 约 992 KiB，只保留 JSON 结果、source SHA、gate/mutation/TB 日志与摘要；未保留 `.vvp`、object、archive 或临时 manifest。

## 本轮状态

`VERIFICATION_PASS_WITH_DECLARED_GAPS`：当前设计 DI-3/DI-4 已重新绑定并通过；其它七项架构门没有借用历史证据，明确留给后续最小切片重绑。本轮不发生 production RTL 语义或 PPA 变化。
