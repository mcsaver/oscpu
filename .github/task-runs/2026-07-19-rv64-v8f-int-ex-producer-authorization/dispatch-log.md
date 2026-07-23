# RV64 v8f integer EX ProducerId 派发日志

- `task_id`: `2026-07-19-rv64-v8f-int-ex-producer-authorization`
- `design_state`: `intermediate_checkpoint`
- `parent_goal_state`: `active`
- `log_policy`: `append-only`

### [2026-07-19] `recall-current-state` - `completed`

- `owner_agent`: Codex。
- `inputs`: 当前 HEAD、retained project/npc memory、known-issues 入口、RV64 architecture/PPA contract、RTL/PPA/接口合同工作流。
- `action`: 首次复合关键词 bounded brief 因无独立 non-history focus 而 fail closed；改用真实模块标识 `OooRob` 后，`npc-dev` brief 为 `recall_status=complete`、`2311/2400`。
- `evidence`: 当前 HEAD=`ef967abae36dc9e8e2e8ad157466f525e543e354`，工作树开工时 clean；v8f 合同、RTL 推导、实现和四个 module TB 已存在，但 task-run 尚无 runner、mutation、evidence 或最终裁决。
- `next_step`: 独立审查后补齐验证闭环，禁止从已有 `.vvp` 生成物反推 PASS。

### [2026-07-19] `v8f-rtl-readonly-review` - `in-progress`

- `owner_agent`: 独立只读子 agent。
- `engineering_domain`: `local-rv64-rtl`，本地 Verilog/SystemVerilog 数字电路设计审查。
- `task_contract`: `subagent-contracts/v8f-rtl-readonly-review.json`。
- `contract_sha256`: `c9da91cd4eb9c0bdc4309dbcd404815c344ef55ad06a74fccea1586d35f52a9a`。
- `access_boundary`: 合同列出的 RTL/spec/task 文档；只读；禁止文件写入、网络、账号、凭据和外部服务。
- `output`: scoped 合同符合性、精确 file:line 与最多三个 P0/P1 反例。

### [2026-07-19] `v8f-test-design-readonly` - `in-progress`

- `owner_agent`: 独立只读子 agent。
- `engineering_domain`: `local-rv64-rtl`，本地 Verilog/SystemVerilog 验证审查。
- `task_contract`: `subagent-contracts/v8f-test-design-readonly.json`。
- `contract_sha256`: `344d5070db7057ef7d2517acb706dd2f6b200bcac06efc9971d42d43bfbcd244`。
- `access_boundary`: 合同列出的四个 TB、对应 RTL 与既有 runner 模式；只读；禁止文件写入和任何外部访问。
- `output`: 八条退出条件覆盖矩阵、compile-success mutation 与最多三个假绿缺口。

### [2026-07-19] `v8f-ppa-readonly-review` - `in-progress`

- `owner_agent`: 独立只读子 agent。
- `engineering_domain`: `local-rv64-rtl`，本地 RV64 RTL PPA 结构分析。
- `task_contract`: `subagent-contracts/v8f-ppa-readonly-review.json`。
- `contract_sha256`: `fe7f45ad7c330bdcc5ea11352d55633e82dfa63e7fb07946b98df42aae5f1714`。
- `access_boundary`: 合同列出的 RTL、PPA contract 与既有 OpenSTA 诊断脚本；只读；禁止写入和外部访问。
- `output`: 新状态位/组合弧、ready/select 隔离和 fresh 同 cohort 诊断计划；不作 PPA GREEN 声明。

### [2026-07-19] `v8f-ppa-readonly-review` - `completed`

- `task_contract`: `subagent-contracts/v8f-ppa-readonly-review.json`。
- `contract_sha256`: `fe7f45ad7c330bdcc5ea11352d55633e82dfa63e7fb07946b98df42aae5f1714`。
- `finding`: 原冻结合同中的两条陈述矛盾；`completion_exact_open -> exN_wb_valid ->
  shared-WB credit/source ready` 是真实组合链，不能同时声称 query 不进入 ready 且 stale EX
  当拍释放 lane。
- `admission`: 该反例只作为架构合同纠偏输入，不作为 physical timing/area/PPA 证据。
- `action`: 新增 `contract-amendment-v8f1.md`；原合同字节保留并加 supersession notice。

### [2026-07-19] `v8f-rtl/test-initial-review` - `review_pending/superseded`

- `contracts`: `subagent-contracts/v8f-rtl-readonly-review.json`、
  `subagent-contracts/v8f-test-design-readonly.json`。
- `reason`: 本 task-run 没有保留可与两份 JSON 精确绑定的最终 reviewer 产物，因此不把草稿或
  对话记忆作为硬证据；技术闭包由主 agent 的结构审计、定向 TB、mutation 和 aggregate
  独立重建。
- `parent_effect`: 无；只影响这两个子任务的证据资格，父目标保持 `active`。

### [2026-07-19] `v8f1-wb-credit-cut` - `completed`

- `implementation`: `exN_pre_auth_valid_w` 成为 physical WB slot owner；9 个 availability use
  与 exact completion side-effect fanout 分离，零新增状态。
- `focused_evidence`: release 4/4、assert 4/4、compile-success mutations 29/29。
- `broad_evidence`: module aggregate 104/104；style/contract/credit audit PASS；strict lint
  仍为继承 115 warnings，normalized signature byte-equal。
- `claim_boundary`: scoped architecture closure；async/long/FP/branch/global reuse 保持 RED。

### [2026-07-19] `diagnostic-ppa-run1-run2` - `completed`

- `cohort`: identical tool/lib/macro/top/period/parameters；独立 result roots；唯一 RTL hash delta
  为 `OooIntBackend.v`。
- `result`: logic-area proxy `-807.80` (`-0.04945%`)；sequential area `0`；WNS
  `+0.624819755 ns`；TNS `+5088.510559082 ns`；40/40 paths 仍 violated。
- `credit_cone_v4`: run1 对 5 个 ready target 各 1 hit，run2 各 0；ROB WB authority 两侧各 1。
- `method_correction`: v1-v3 错把 sequential semantic `Q` 当作
  `get_fanin -startpoints_only` 返回对象；v4 同时记录 semantic `Q` 与 OpenSTA structural `CK`。
- `claim_tier`: `diagnostic_rtl_proxy_partial_constraints`；`promotion_eligible=false`；
  `target_200mhz_met=false`；Power unqualified。

### [2026-07-19] `wsl-parallel-shell-counterexample` - `contained`

- `event`: 两个只读辅助子任务曾与主 agent 同时启动 Windows/Codex→WSL 工程命令，WSL
  返回 `Wsl/Service/E_UNEXPECTED`；这属于本地执行调度失败，不是 RTL 功能失败，也不是
  platform review 结论。
- `containment`: 中断相关 shell 子任务，不接纳其输出；由主 agent single-flight 串行重跑。
- `rule_promoted`: 根 `AGENTS.md`、RTL task-contract instruction/skill 与
  `AI_ENVIRONMENT.md` 明确禁止并发 `wsl.exe` 工程 shell；复杂管道/变量写入仓库脚本后调用。

### [2026-07-19] `contract-json-binding-forward-test` - `completed`

- `task_contract`: `subagent-contracts/v8f-contract-render-forward-test.json`。
- `contract_sha256`: `ffb7ffffaf8d78007126526b7c48206f37a41d3732616c3ae39d2a533677072d`。
- `execution`: 子 agent 只消费 `render` 的自包含提示，无 shell、无文件写入、无网络/账号/凭据/
  外部服务访问。
- `result`: 精确回报 JSON 路径与 SHA，明确该 SHA 不绑定设计 `contract.md`，理解 WSL
  single-flight、`review_pending` 与父目标 `active`；无越界动作。
- `tool_gates`: skill audit、14-case self-test、14-case CLI self-test PASS。

### [2026-07-19] `agent-system-real-e2e` - `completed-after-counterexample`

- `blocked_run`: `.github/task-runs/2026-07-19-v8f-contract-binding-hardening/`；10 个业务节点
  均 PASS，但 slug `v8f contract binding hardening` 无 independent non-history primary，
  recall fail closed，run 保留为命名反例。
- `completed_run`: `.github/task-runs/2026-07-19-rtl-task-contract-agent-system/`；改用可召回主词
  后 `agent-system` 10/10 completed，含 context brief/profile resolve/evidence index/publication。
- `lesson`: task slug 是 bounded-recall 的可执行输入，必须使用当前 retained primary 支持的
  领域主词；不能用失败历史 task-run 自证。

### [2026-07-19] `scoped-slice-closeout` - `completed-parent-active`

- `implementer`: v8f scoped carrier/authorization、v8f.1 credit/authority 分权及其功能/结构证据
  已闭合。
- `reviewer`: strict lint、完整 Domain-A holder、global no-live-reuse、DiffTest/Linux、完整物理
  条件、Power/200 MHz/Pareto 仍为 RED/UNKNOWN/unqualified。
- `parent_goal_state`: `active`；单个子任务的 `review_pending` 或本地 WSL 调度失败不传播为
  global blocked。

### [2026-07-19] `final-profile-and-strict-guard` - `completed`

- `agent-system`: `.github/task-runs/2026-07-19-rtl-task-contract-single-flight-3/`，10/10 nodes
  PASS，completed publication/evidence bundle。
- `npc-dev`: `.github/task-runs/2026-07-19-rv64-producer-completion-authorization/`，5/5 nodes
  PASS，completed publication/evidence bundle。
- `strict_guard`: changed paths 自动映射 `agent-system+npc-dev`，两项新鲜 evidence 均 PASS；
  无 profile 豁免。

### [2026-07-19] `agent-system-negative-fixture-cleanup` - `completed`

- `counterexample`: successful agent-system runs 留下
  `.agent-system-guard-tmp.*-evidence-context-history-primary`；根因是 fixture 创建后漏进 cleanup
  allowlist。
- `fix`: 把 `guard_context_history_primary` 加入既有 prefix-checked exact cleanup loop。
- `cleanup`: realpath 验证后删除本轮生成的 3 个临时目录；不可恢复但仅含生成的
  `context-brief.md` fixture。历史 ignored temp 未批量删除。
- `forward_test`: fresh agent-system 10/10 completed，运行时间之后无新增 guard temp directory。
