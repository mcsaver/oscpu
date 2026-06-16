# Dispatch Log

## 基本信息

- `task_id`: `2026-05-23-agent-config-refresh`
- `task_slug`: `agent-config-refresh`
- `graph_template`: `agent-env-refactor`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-23] `recall` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 用户要求阅读最近改动并重新配置相关 agent
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/agent-system.md`、`.github/agentic-hardware-blueprint.md`
- `action`: 读取跨 agent 规范、Copilot 补充规则、项目状态、已知问题、agent-system memory 和蓝图
- `outputs`: 确认本任务属于 `.github/` agent 环境重构，应使用 `agent-env-refactor`
- `evidence`: 必读链已读取
- `handoff_to`: `recent-change-audit`
- `next_step`: 审计近期新增路径和模块 memory
- `notes`: 重点关注 `npc/sim`、`npc/soc`、NEMU SoC reference 和 ysyxSoC

### [2026-05-23] `recent-change-audit` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 需要用最近工程事实驱动配置更新
- `depends_on`: `recall`
- `inputs`: `git status --short`、`.github/memory/modules/{npc,nemu,abstract-machine,difftest}.md`、`ysyxSoC/spec/cpu-interface.md`
- `action`: 审计近期未提交改动、模块记忆和 ysyxSoC CPU ABI 规范
- `outputs`: 识别出 `npc/sim` 统一入口、`npc/single`/`npc/soc` 后端分层、NEMU `CONFIG_SOC_SIM` reference、AM `NPC_SIM_BACKEND=soc` 覆盖、ysyxSoC/Mill/JDK 约束
- `evidence`: `find npc/sim`、`find npc/soc`、`find ysyxSoC`、`sed ysyxSoC/spec/cpu-interface.md`
- `handoff_to`: `file-edits`
- `next_step`: 更新全局规则和模块 agents
- `notes`: 原有多份 agent 仍把 NPC 写成未来接入点，需要刷新

### [2026-05-23] `file-edits` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 需要把审计结论写入 agent 配置
- `depends_on`: `recent-change-audit`
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/agentic-hardware-blueprint.md`、`.github/agents/*.agent.md`、`.github/instructions/*.instructions.md`
- `action`: 新增 `ysyx-soc` agent，更新 coordinator、hardware-flow、npc、nemu、abstract-machine、am-kernels、difftest、yosys-sta 等 agent；补充静态图和 memory-protocol 模块清单
- `outputs`: `.github/agents/ysyx-soc.agent.md`、`.github/memory/modules/ysyx-soc.md` 及多份更新后的配置文档
- `evidence`: `.github/` diff
- `handoff_to`: `stale-rule-scan`
- `next_step`: 扫描旧命令和旧阶段描述
- `notes`: 业务源码不在本轮修改范围内

### [2026-05-23] `stale-rule-scan` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 防止旧 agent 配置继续误导后续任务
- `depends_on`: `file-edits`
- `inputs`: 更新后的 `.github/` 文档
- `action`: 使用 `rg` 扫描 `riscv32e-npc`、`当前默认后端：`、`NPC 已实现后的`、`在目标实现后`、`未来 target 接入` 等旧描述
- `outputs`: 活动配置文件未发现关键旧命令和高风险阶段残留；历史 memory/decisions 保留当时记录，仅保留“未来节点不能作为硬依赖”这类图质量规则
- `evidence`: `rg -n "riscv32e-npc|当前默认后端：|NPC 已实现后的|在目标实现后|未来 target 接入|npc/single.*唯一后端" .github/...`
- `handoff_to`: `validate`
- `next_step`: 做 `.github` diff check
- `notes`: `ysyx-coordinator` 的“未来接入节点不能被错误写成硬前置”属于有效质量规则

### [2026-05-23] `validate` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 文档/配置落盘后需要基本格式验证
- `depends_on`: `stale-rule-scan`
- `inputs`: 更新后的 `.github/` diff
- `action`: 运行 `git diff --check -- .github`
- `outputs`: 格式检查通过
- `evidence`: `git diff --check -- .github` PASS
- `handoff_to`: `record`
- `next_step`: 写入长期 memory 和任务记录
- `notes`: 未运行业务构建，因为本轮不改 RTL/C/Scala

### [2026-05-23] `record` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 完成 agent 配置刷新
- `depends_on`: `validate`
- `inputs`: 更新结果与验证命令
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`、`.github/memory/modules/ysyx-soc.md` 并创建 task-run
- `outputs`: 本 `dispatch-log.md` 与 `task-report.md`
- `evidence`: 记录文件已落盘
- `handoff_to`: 无
- `next_step`: 用户可继续按新 agent 配置推进 SoC/NPC 后续任务
- `notes`: 完成
