# R4 一次性 architecture-feasible seed 裁决

## 根因与角色边界

R3.6 (`r3p6-onehot-prf-recovery-20260715`) 是本轮固定的 performance/area/exact-5ns
测量锚，但只有一路完整 memory issue owner、AGU、translation、order check 和 cache
admission；九项 DI/OOO hard gate 均未闭合。它是
`architecture_infeasible_measurement_anchor`，永远不能成为 canonical、front accepted 或
champion。

常规 `area_efficiency>=0.999` 相对 R3.6 只允许总增量约 `1607.41`。R4 S0 已从
`1605803.92` 增至 `1606423.28`，后续完整双 memory 架构只剩约 `988.05`，与用户要求的
完整双发射/真 OoO 产品约束冲突。因此建立一次性、不可复用的
`r3p6-infeasible-anchor-to-first-feasible-seed-v1` 过渡。

## 一次性门槛

首个 seed 必须同时满足：

1. 常规 `check.py --require-promotable --target proxy_champion` 全量通过；这包含同设计绑定、
   required functional evidence、可执行 architecture hard-gate evaluator 的九项 GREEN；
2. CoreMark、Dhrystone10k 各自 throughput ratio 均 `>=0.995`，且固定镜像选定 PC 区间的
   retired instructions 与 R3.6 相等；
3. exact 5ns `worst_slack>=+0.10ns`、`WNS>=0`、`TNS=0`、`violations=0`、`loops=0`；
4. 同口径 logic area `<=1605803.92*1.10=1766384.312`；
5. 仅本次不要求相对 architecture-infeasible R3.6 dominance，也不应用
   `area_efficiency>=0.999`。

机器入口：

```bash
python3 npc/rv64/eval/ppa/tools/architecture_seed.py \
  npc/rv64/eval/ppa/baselines/r3p6-recovery-baseline.json \
  <candidate-manifest.json>
```

baseline index 的 `architecture_feasible_seed` 由 `null` 变为首个 seed 后，任何第二次 seed
过渡必须失败。此后立即恢复常规 global Pareto、candidate dominance、
`area_efficiency>=0.999` 和 per-benchmark `>=0.995`。若首 seed 的 power/total area 仍未
qualified，后续只有 engineering comparison 资格，formal front 等待同一 seed 补齐资格；
不得再选第二个 seed 绕过。

## Power fail-closed

qualified power 仍要求同 workload activity、coverage>=95% 以及 macro-inclusive 完整模型。
若候选 power unqualified，过渡工具可以确认 `architecture_feasible_seed_eligible=true`，但必须
同时输出：

- `eligible_for_front_accepted_baseline=false`
- `eligible_for_canonical=false`
- `eligible_for_ppa_champion=false`
- `unqualified_power_claim_scope=architecture_feasible_seed_only`

`--require-front-baseline` 对这类候选必须非零退出。只有 power 与 macro-inclusive total area
均 qualified 的 seed 才可作为初始 feasible front 的比较基线/canonical measurement
reference；seed 本身仍不因例外过渡获得 champion 称号。

## 当前 R4 S0 裁决

R4 S0 仅是 `correctness_checkpoint`：九项 architecture hard gate 尚未全绿，timing preview
reserve 也低于 `+0.10ns`，且 power unqualified。因此它既不是 architecture-feasible seed，
也不是 proxy/final champion；本策略没有把 S0 的 checkpoint 结果升级为任何 promotion claim。

## Workflow guard 边界

本切片收尾执行 `scripts/agent-e2e.sh --guard --guard-mode strict`，guard 因开工前继承的整个
工作树/索引共 `2857` 个 changed paths 推导出 `rv64-linux`、`abstract-machine`、`am-kernels`、
`nemu-dev`、`npc-dev` 五个 profile，并以缺少全仓 profile evidence 返回 FAIL。该结果不是本
policy-only 切片的测试失败，也不能被 59/59 policy unit tests 洗成 PASS；父任务收口时须按
完整改动集补齐对应 profile evidence，或显式保留该 inherited-worktree 豁免与风险。
