# Dispatch Log

## 基本信息

- `task_id`: `2026-05-31-rv64-ubuntu-agent-env`
- `task_slug`: `rv64-ubuntu-agent-env`
- `graph_template`: `agent-env-refactor`
- `log_policy`: `append-only`

---

### [2026-05-31 21:30] `recall` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 用户要求结合上传文档配置 agent 环境，避免未来开发错判。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/{npc,agent-system}.md`、上传文档
- `action`: 读取现有规则和 RV64 Ubuntu 22.04 bring-up 记忆，提炼 Verilator 优先、暂不 Vivado、完整 Ubuntu 分层 gate 和流片边界。
- `outputs`: 配置任务范围与专用 agent/instruction 清单。
- `evidence`: 本轮编辑只触碰 `.github/` 和记忆文件。
- `handoff_to`: `add-agents`
- `next_step`: 新增专用 agents。
- `notes`: 上传文档中的 `rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`linux-display-loop` 已作为静态图输入。

### [2026-05-31 21:40] `add-agents` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 旧 agent 体系主要围绕 RV32/NPC/SoC，缺少 RV64 Linux/Ubuntu 专用角色。
- `depends_on`: `recall`
- `inputs`: 上传文档建议、当前 `npc/rv64` 目录结构和 memory 状态。
- `action`: 新增 `rv64-linux`、`linux-device`、`display-vga`、`verilator-tapeout` 四个 agent。
- `outputs`: `.github/agents/rv64-linux.agent.md`、`.github/agents/linux-device.agent.md`、`.github/agents/display-vga.agent.md`、`.github/agents/verilator-tapeout.agent.md`
- `evidence`: 文件已落盘。
- `handoff_to`: `add-instructions`
- `next_step`: 新增按目录/主题生效的 instructions。
- `notes`: `display-vga` 明确 AM legacy VGA 不能当作 Linux 屏幕，`verilator-tapeout` 明确 Vivado 暂不作为前置。

### [2026-05-31 21:50] `add-instructions` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 需要把具体判断规则从 agent 角色中拆出来，避免全局提示词过长。
- `depends_on`: `add-agents`
- `inputs`: RV64 Linux bring-up、virtio rootfs、Linux framebuffer、RV64GC 用户态、Verilator 流片约束。
- `action`: 新增 5 份 instructions。
- `outputs`: `rv64-linux-bringup`、`linux-framebuffer-vga`、`virtio-rootfs`、`rv64gc-userland`、`verilator-tapeout-realism`
- `evidence`: 每份文件均包含 gate、禁止误判和验证要求。
- `handoff_to`: `wire-blueprint`
- `next_step`: 将新图接入蓝图与 coordinator。
- `notes`: instructions 的 `applyTo` 先收敛到 `npc/rv64/**`，避免污染 RV32 任务。

### [2026-05-31 22:00] `wire-blueprint` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 新 agent/instructions 若不接入蓝图和总调度，后续仍可能被忽略。
- `depends_on`: `add-instructions`
- `inputs`: `.github/agentic-hardware-blueprint.md`、`hardware-flow.agent.md`、`ysyx-coordinator.agent.md`、`npc.agent.md`、全局规则。
- `action`: 新增 RV64/Ubuntu/Verilator 静态图，更新 agent 分层、必读链、总调度 agents 列表和 NPC agent 边界。
- `outputs`: 5 张新静态图：`rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`linux-display-loop`、`rv64gc-userland-loop`、`verilator-tapeout-readiness-loop`
- `evidence`: 相关关键词可在蓝图、coordinator、hardware-flow、AGENTS 和 copilot instructions 中搜索到。
- `handoff_to`: `record`
- `next_step`: 写入 memory 和 decisions。
- `notes`: 本节点只配置环境，不修改业务代码。

### [2026-05-31 22:10] `record` - `completed`

- `owner_agent`: `agent-system`
- `trigger`: 任务完成后按记忆协议落盘。
- `depends_on`: `wire-blueprint`
- `inputs`: 本轮配置改动。
- `action`: 更新 project-status、agent-system/npc memory、decisions 和 task-run。
- `outputs`: 本 task-run 与 memory 条目。
- `evidence`: `.github/task-runs/2026-05-31-rv64-ubuntu-agent-env/`
- `handoff_to`: 无
- `next_step`: 后续功能任务按新图推进。
- `notes`: 本轮没有运行 Verilator/QEMU，验证范围是文本配置一致性。
