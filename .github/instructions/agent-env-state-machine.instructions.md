# Agent Env State Machine

本文件定义 AI 开发环境重做任务的 Agent 层状态机。它把报告中提到的 FSM、state traceback、reviewer/inspector 和验证器要求，收敛成当前仓库可执行的最小规则。

## 状态

1. `recall_context`：读取 AGENTS、copilot instructions、memory、known issues、相关 instructions/skills 和当前 task-run 历史。
2. `classify_layer`：把任务归类到 Database、Skill、Agent 或 cross-layer，不允许直接改快照目录当作 active config。
3. `plan_graph`：选择 e2e profile 或定义本轮节点；跨层任务默认以 `agent-system` profile 留证。
4. `implement`：按层落地修改。Database 只写入 retained memory/log stored document 与 backup；Skill 保持 live `SKILL.md`；Agent 修改 profile/script/policy/workflow 等活文件。
5. `verify`：运行 `scripts/agent-maintain.sh --mode check`；触及 profile/e2e 时运行对应 `scripts/agent-e2e.sh --profile ...`。
6. `inspect`：由 `agent-system` 视角复核报告追踪矩阵、policy、retention、task-run report、profile resolve、关键 evidence 和 FAIL marker。
7. `persist`：更新 `.github/memory/project-status.md` 和相关 module memory，刷新 retained DB backup/snapshot，并 stage 本轮产物。

## 回退

- `verify` 失败时回退到 `implement`，并把失败 evidence 作为下一轮输入。
- `inspect` 发现证据不足时回退到 `plan_graph` 或 `verify`，不能把弱证据写成完成。
- `persist` 发现 retained DB、markdown coverage 或 backup 不一致时回退到 `implement`，优先修复长期记忆一致性。

## state_traceback

每个 `agent-system` task-run 必须在 `task-report.md` 和 `run-manifest.json` 中写出 `state_traceback`，至少包含：

- `state_sequence`：`recall_context -> classify_layer -> plan_graph -> implement -> verify -> inspect -> persist`
- `current_state`：成功 run 必须为 `persist`；失败 run 通常停在 `verify` 或 `inspect`。
- `failure_state`：失败时记录触发回退的状态；成功时为 `无` 或空字符串。
- `rollback_target`：失败时记录下一轮应回退到的状态，例如 `implement` 或 `plan_graph`。
- `failure_reason`：失败证据摘要；不能只写泛化结论。
- `reviewer`：默认 `ysyx-coordinator`。
- `inspector`：默认 `agent-system`。
- `evidence_policy`：说明本次状态判断依赖 task-report、dispatch-log、run-manifest 和 evidence-index。

## Reviewer / Inspector

- `ysyx-coordinator` 负责把用户目标映射到图任务和 domain agent。
- `agent-system` 负责 inspector 职责：检查三层边界、policy、report matrix、e2e profile、task-run 证据和 memory 写回。
- 每次交付前都要执行实现者/审查者双角色复核：实现者角色给出改动、证据、完成边界和豁免理由；审查者角色优先找反例、覆盖洞、假绿、未读上下文、未跑 profile、验证不匹配和越级完成声明。冲突必须在最终回复、task-run 或 memory 中记录为“已由证据关闭”或“剩余风险/下一步”，不得静默吞掉。
- domain agents 只负责各自模块执行，不负责关闭整个 AI 环境重做目标。
- `agent-system` profile 必须执行 `state-machine-traceback` 节点，验证状态机和 `state_traceback` 字段进入 task-run 证据。
- `agent-system` profile 必须执行 `reviewer-inspector-gate` 节点，验证 R7 被 review routing 映射到 `agent-layer`，且 `ysyx-coordinator`/`agent-system` 的 reviewer/inspector 关系不是只停留在文档。
- `python3 scripts/github_index_db.py state-audit` 是本机制的最小自动审计入口。

## 完成门槛

- 报告矩阵中的每个 requirement 必须至少有 `status`、`evidence`、`verification` 和 `next_action`。
- `implemented` 只能用于当前仓库已有自动 gate 或 task-run evidence 支撑的项目。
- `partial` 和 `planned` 必须保留下一步，不能被最终回复扩写成整体完成。
- 长期目标完成前，必须对照 `.github/ai-env/contracts/agent-env-rebuild-matrix.json` 逐项审计，而不是只看本轮命令是否为 0。
