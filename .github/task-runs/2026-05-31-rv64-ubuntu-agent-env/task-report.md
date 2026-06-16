# Task Report

## 基本信息

- `task_id`: `2026-05-31-rv64-ubuntu-agent-env`
- `task_slug`: `rv64-ubuntu-agent-env`
- `graph_template`: `agent-env-refactor + rv64-ubuntu-probe-loop/static-template-update`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `agent-system`
- `started_at`: `2026-05-31`
- `updated_at`: `2026-05-31`

## 任务目标

- `source_request`: 用户要求先按上传文档配置对应 agent 环境，目标是完整 Ubuntu 22.04、暂不 Vivado、Verilator 真实性能仿真、core 后续面向流片水准，避免未来开发错判。
- `goal`: 将 RV64 Linux/Ubuntu bring-up、Linux 设备、Linux 显示、RV64GC 用户态、Verilator/流片约束固化进 `.github/agents`、`.github/instructions`、蓝图、总调度和记忆体系。
- `scope`: 仅修改 `.github/` 与 `.github/memory/`，不改 RTL/C/C++ 业务实现。

## 选图说明

- `selected_template`: `agent-env-refactor`
- `why_this_graph`: 本轮是 agent 环境配置，不是业务 bug 修复；需要更新 agents、instructions、blueprint、memory 与 task-run。
- `dynamic_nodes_added`: `rv64-template-promote`
- `why_dynamic_nodes_were_needed`: 旧蓝图只有 RV32/NPC/SoC 常见图，无法表达 Ubuntu 22.04、rootfs、Linux framebuffer、RV64GC 用户态和 Verilator 流片约束。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | agent-system | completed | `.github/AGENTS.md`、`copilot-instructions.md`、memory、上传文档 | 需求边界：Verilator 优先、暂不 Vivado、完整 Ubuntu 分层 gate | 已读取并提取为新 agents/instructions |
| add-agents | agent-system | completed | 上传文档建议和当前 `npc/rv64` 状态 | 新增 `rv64-linux`、`linux-device`、`display-vga`、`verilator-tapeout` agents | `.github/agents/*.agent.md` |
| add-instructions | agent-system | completed | RV64/Linux/Ubuntu、virtio、framebuffer、RV64GC、Verilator 流片约束 | 新增 5 份 `.github/instructions/*.instructions.md` | 文件存在且可搜索到关键 gate |
| wire-blueprint | agent-system | completed | 蓝图、hardware-flow、coordinator、NPC agent | 新增 RV64 专用静态图和调度入口 | `.github/agentic-hardware-blueprint.md` 等 |
| record | agent-system | completed | 本轮改动 | 更新 memory、decisions、task-run | 本文件和 `dispatch-log.md` |

## 关键产物

- `artifacts`: `.github/agents/rv64-linux.agent.md`、`linux-device.agent.md`、`display-vga.agent.md`、`verilator-tapeout.agent.md`
- `artifacts`: `.github/instructions/rv64-linux-bringup.instructions.md`、`linux-framebuffer-vga.instructions.md`、`virtio-rootfs.instructions.md`、`rv64gc-userland.instructions.md`、`verilator-tapeout-realism.instructions.md`
- `artifacts`: `.github/agentic-hardware-blueprint.md`、`.github/agents/hardware-flow.agent.md`、`.github/agents/ysyx-coordinator.agent.md`、`.github/agents/npc.agent.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`、`.github/memory/modules/npc.md`、`.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: 无配置阻塞。
- `missing_dependencies`: WSL 当前仍可能出现 `Wsl/Service/E_UNEXPECTED`，本轮没有跑 Verilator/Linux 长验证。
- `risk_assessment`: 本轮只配置 agent 环境；后续真实功能进展仍需在 `npc/rv64` 按新图跑 QEMU/NPC 证据。

## 下一步建议

1. 继续按 `rv64-ubuntu-probe-loop` 处理 NPC 用户态输出可见性，先闭合 Ubuntu probe `/etc/os-release` 在 NPC 日志完整出现。
2. 并行准备 `rv64-ubuntu-rootfs-loop` 的 virtio-mmio + 多源 PLIC 设计契约。
3. 若要做“屏幕里的 Ubuntu 文本”，启动 `linux-display-loop`，先做 simple framebuffer/fbcon，不追完整桌面。

## 模板升级候选

- `repeated_dynamic_subgraph`: RV64 Ubuntu/Verilator bring-up 已多次出现。
- `should_promote_to_static_template`: 是。
- `reason`: 该任务已经有稳定输入输出、证据 gate 和模块边界，继续靠旧 RV32 图会导致错判。

## 收尾结论

- `final_result`: 已完成 RV64 Ubuntu/Verilator/tapeout 相关 agent 环境配置。
- `evidence_summary`: 新增 4 个 agent、5 个 instruction，并把 5 张 RV64/Ubuntu/Verilator 静态图接入蓝图和总调度。
- `notes`: 本轮没有宣称 Ubuntu 功能进度变化，只改变未来 agent 的判断入口和执行纪律。
