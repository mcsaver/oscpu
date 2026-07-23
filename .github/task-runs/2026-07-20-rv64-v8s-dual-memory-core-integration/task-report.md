# v8s/F2 canonical 双 memory core integration 任务报告

## 基本信息

- `task_id`: `rv64-v8s-dual-memory-core-integration`
- `task_slug`: `rv64-dual-memory-canonical-integration-revtag-v8s`
- `graph_template`: `architecture-first + executable-counterexample + bounded-review`
- `graph_mode`: `static+dynamic`
- `status`: `completed`（仅指 F2 architecture checkpoint）
- `owner`: `primary Codex agent`
- `started_at`: `2026-07-20T05:45:00+00:00`
- `updated_at`: `2026-07-20T08:06:48+00:00`

## 任务目标与范围

- `source_request`: 在既定硬门下持续优化 RV64 双发射完整 OoO/PPA，同时把架构、验证、证据和
  子 agent 协作规则固化为可发现、可执行、可审计且能在实战中纠偏的工作流。
- `goal`: 将 v8r 双 bridge leaf 接入 canonical core，建立两个 ordinary memory bank 的独立
  admission/MIQ/response/ROB-open 路径和一次性全局 WB/SQ/terminal 分配，并用 focused/assert/
  mutation/full-top/predecessor/reviewer 证据关闭 F2 合同。
- `out_of_scope`: final-PA SQ query/forward/replay、64-cycle sustained IPC/system workload、
  equal-capacity banking、synthesis/STA/power/Pareto 晋级和 architecture GREEN。

## 节点概览

| node_id | owner | status | output/evidence |
| --- | --- | --- | --- |
| `contract-review` | bounded no-tools reviewers | completed | 三轮 contract review；singleton launch/release 条款最终 PASS |
| `rtl-implementation` | primary | completed | 双 MIQ/response/global sinks/hierarchy/wrapper/sim observability |
| `focused-verify` | primary | completed | 3 simulations + 3 full-top lints + 11 semantic mutations |
| `predecessor-handoff` | primary | completed | F1 stage-aware target + F0 fresh dependency |
| `implementation-review-v1` | bounded no-tools reviewer | gap | hierarchy evidence omission + two coverage holes |
| `counterexample-closure` | primary | completed | real ROB wrap age + dual-EX full-WB hold/recovery |
| `implementation-review-v2` | bounded no-tools reviewer | completed | PASS for `architecture_checkpoint` only |
| `workflow-solidification` | primary | completed | canonical dispatch pipeline and forward-compatible phase gates |

## RTL 推导与接口契约

完整推导在 `rtl-derivation.md`，冻结合同在 `contract.md`。关键结论：

- `ENABLE_DUAL_MEM` 在 reusable chain 默认 0，canonical `NpcCoreTop` 逐层且恰好置 1。
- captured `addr[3]` 决定 bank；不同 bank 双 grant，同 bank 用 edge-old ROB distance；consume
  只属于各自 local terminal/request fire。
- 两 bank 各自 MIQ/expected/ROB-open/response/drop/residency；WB、SQ ports 和 terminal pending
  set 统一分配。
- ordinary store 是 probe，物理写只来自 SQ/LEGACY；singleton launch/release 不允许 ordinary
  look-through；kill 先切副作用，identity 保留到 exact terminal。

## Fresh aggregate

- `run_id`: `v8s-f2-20260720T080613Z-1010841`
- `source_closure_sha256`: `2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2`
- `result`: `evidence/focused/result.json`
- `profiles`: focused release/assert、legacy assert、NpcCoreTop release/assert lint、NpcSimTop
  assert+stats lint 全 PASS。
- `mutations`: 11/11 compile-success、elaborated、activated、target-rejected。
- `predecessor`: F1 fresh run `v8r-f1-20260720T080639Z-1012033` PASS，
  `canonical_stage=F2_PROMOTED`；F0 由 F1 target fresh 调用。
- `architecture`: DI-5 RED、OOO-3 RED、overall RED、PPA UNQUALIFIED、promotion=false；canonical
  architecture manifest 未改写。

## 实现者 / 审查者对抗

- `实现者初始陈述`: focused 行为、11 mutation 和 full-top lint 足以支持 checkpoint。
- `审查者 v1 反例`: bounded prompt 没给 hierarchy checker 的有效参数/实例 census/负向自测，
  所以不能从 `F2_PROMOTED` 元数据自证 canonical；普通 age 和单 EX credit 场景还留下 wrap/full-WB 洞。
- `处理`: 不降低 reviewer 标准；补真实 ROB head=15/raw 15→0 场景和 EX0/EX1 双占槽场景；重新
  fresh aggregate；用 versioned v2 contract 提供同 closure 的17项 hierarchy/source checks与13项
  checker negative tests。
- `审查者 v2`: hierarchy、wrap-age、dual-EX-WB 三项均关闭，PASS 仅授权
  `architecture_checkpoint`；不声称 raw repository audit、hash 复算或形式完备。

## 工作流实战纠偏

- 首个手写 reviewer JSON 未通过 canonical validator；其看似合理的回答被标为 `candidate-only`，
  没有追认为正式证据。
- 首次正式 `agent-system` forward profile 保留为 blocked：前七节点 PASS，`rtl-task-contract`
  因 e2e 把路径/SHA/绑定边界绑定成不可换行的单一散文字符串而假失败。根因修复为分别核对
  “JSON 仓库相对路径”“该文件 SHA-256”“哈希只绑定该 JSON”三项语义；不手改失败报告造绿。
- `prepare-rtl-task-contract` 现在把 `create -> validate -> render`、verbatim prompt、validation/
  boundary drift 的 candidate-only、versioned scope extension 和父目标状态隔离写入机器合同、Skill、
  instruction、render prompt 与 e2e 自测。
- F1 永久门不再把“wrapper 未接 canonical”当永久不变量；它精确接受互斥的
  `F1_UNINTEGRATED` 或 `F2_PROMOTED`，后者还必须核对 F2 contract/spec handoff。F2 target fresh
  调用 F1，避免阶段晋级后前置门自毁或被删除。

## 当前剩余项

- `F3`: final-PA SQ byte query/forward/replay 和相关 stale-load/replay 证明。
- `F4`: sustained 64-cycle IPC、system workload、equal-capacity physical banking 与同源 design-id
  synthesis/STA/power/Pareto。
- `risk`: directed/mutation 仍非形式穷尽；full-top 目前是 elaboration/lint，不是动态系统验证。

## 收尾结论

- `final_result`: `architecture_checkpoint`
- `promotion_eligible`: `false`
- `architecture`: `RED`
- `ppa`: `UNQUALIFIED`
- `parent_goal`: `active`

本 F2 切片已完成，长期目标未完成也未受阻；下一轮从 F3/F4 中按证据依赖选择一个 bounded 节点继续。
