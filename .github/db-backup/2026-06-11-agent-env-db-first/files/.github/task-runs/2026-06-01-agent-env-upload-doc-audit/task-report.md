# RV64 Ubuntu Agent Env Upload-Doc Audit

- `date`: 2026-06-01
- `graph_template`: `agent-env-refactor`
- `source_request`: 用户提示可以结合上传文档继续配置 agent 环境，避免未来开发误判完整 Ubuntu 22.04、VGA、rootfs、Vivado/Verilator 和流片边界。
- `goal`: 复核上传文档中的工程判断是否已经落到 `.github/agents`、`.github/instructions`、蓝图和 memory，并修补仍偏旧的调度入口。

## 节点状态

| node_id | owner_agent | status | outputs | evidence |
| --- | --- | --- | --- | --- |
| `recall` | `agent-system` | completed | 读取上传文本、`.github/AGENTS.md`、Copilot 规则、agent-system memory、蓝图和 RV64 专用 agents/instructions | 上传文档与现有规则均确认：完整 Ubuntu 必须分层 gate，AM legacy VGA/rootfs 文件/QEMU PASS 不能越级 |
| `audit` | `agent-system` | completed | 确认四个专用 agent 与五份 instructions 已存在 | `rv64-linux`、`linux-device`、`display-vga`、`verilator-tapeout` 已覆盖上传文档中的核心边界 |
| `file-edits` | `agent-system` | completed | 补强 `ysyx-coordinator`、`hardware-flow`、蓝图路线图和 memory | PLAN 列表新增 RV64 专用静态图；frontmatter 触发词纳入 Ubuntu/rootfs/display/Verilator-first |
| `validate-discovery` | `agent-system` | completed | 用 `rg` 和 `git diff --check` 做轻量验证 | 新图名与 gate 口径可检索；diff whitespace 检查通过 |
| `record` | `agent-system` | completed | 更新 project-status 与 agent-system memory | 本 task-run |

## 关键结论

- 上传文档的主体要求已在 2026-05-31 落成专用 agent/instructions，本轮不是重做体系，而是把总调度入口和蓝图阶段补齐到同一口径。
- 后续涉及 `npc/rv64`、Ubuntu 22.04、官方 `/bin/sh`、rootfs、Linux framebuffer 或 Verilator 性能仿真时，应优先走 `rv64-ubuntu-probe-loop`、`rv64-ubuntu-rootfs-loop`、`linux-display-loop`、`rv64gc-userland-loop`、`verilator-tapeout-readiness-loop`。
- 仍不能把 probe `/init`、QEMU `/bin/sh`、AM legacy VGA 或 rootfs 文件存在解释成 NPC 完整 Ubuntu/rootfs/display 通过。

## 修改文件

- `.github/agents/ysyx-coordinator.agent.md`
- `.github/agents/hardware-flow.agent.md`
- `.github/agentic-hardware-blueprint.md`
- `.github/memory/project-status.md`
- `.github/memory/modules/agent-system.md`
- `.github/task-runs/2026-06-01-agent-env-upload-doc-audit/task-report.md`
- `.github/task-runs/2026-06-01-agent-env-upload-doc-audit/dispatch-log.md`

## 验证

- `rg`：确认 coordinator/hardware-flow/blueprint/memory 中可检索到 RV64 Ubuntu、rootfs/display、Verilator-first 和新静态图入口。
- `git diff --check`：PASS。

## 下一步

- 继续按 `rv64gc-userland-loop` 推进官方 Ubuntu `/bin/sh` 所需的 FCSR/fflags/dynamic frm、dynamic linker/libc gate。
- rootfs/display 方向进入实现前，先分别产出 virtio-mmio + 多源 PLIC 设备契约和 simple-framebuffer + SDL scanout 显示契约。
