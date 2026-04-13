# Agent System 模块笔记

## 当前状态

- 2026-04-13：根据用户确认，当前默认主闭环收敛为 `am-kernels -> abstract-machine -> NEMU(reference)`；`NPC/Verilator` 改为未来接入节点，不再作为当前调度前置。
- 2026-04-13：继续吸收 NVIDIA Marco 的图任务思想后，工作区新增“静态图优先、动态图补洞、稳定后模板化”的规则，并补上 `regression-debug-loop`、动态图扩图规则和图质量门槛。
- 2026-04-13：新增 `.github/task-runs/` 作为任务级结构化产物目录，把单次图任务的 `task-report` 和 `dispatch-log` 与长期记忆分层保存。
- 2026-04-13：工作区 agent 体系已从“模块专家集合”推进到“图任务调度 + 工作流 agent + 模块专家执行”的第一阶段骨架；新增 `agent-system` 与 `hardware-flow` 两个工作流层 agent，并新增 `.github/agentic-hardware-blueprint.md` 作为稳定入口。
- 当前默认主闭环固定为 `am-kernels -> abstract-machine -> NEMU(reference)`；`NPC/Verilator(target)` 仍是未来接入点，真实 EDA 工具后续再作为新节点接入。
- `ysyx-coordinator` 现在应优先选择静态图 `rv32-reference-loop`、`am-device-loop`、`agent-env-refactor`、`regression-debug-loop`，只有模板不足时才动态扩图。

## 设计笔记

- 图任务节点至少写清 `node_id`、`owner_agent`、`depends_on`、`inputs`、`outputs`、`success_criteria`、`fallback`。
- `hardware-flow` 负责跨 `am-kernels + abstract-machine + nemu + npc` 的闭环，模块专家继续负责本模块内部实现与调试。
- `.github/agentic-hardware-blueprint.md` 是当前 agent 环境的稳定入口；处理 `.github/agents/`、`.github/instructions/`、`.github/copilot-instructions.md` 相关任务时先读它。
- 当前工程里真正可执行的参考后端是 NEMU + AM；NPC/Verilator 仍处于 bring-up 期，遇到 `npc/single/Makefile` 与 `platform/npc.mk` 的占位逻辑时要把它识别为基础设施任务，而不是伪造“已完成闭环”。
- 当前默认调度应优先命中 `rv32-reference-loop`；只有在 NPC/Verilator 目标真正实现后，才升级到 `rv32-bringup`。
- 动态图的职责是给失败节点补证据、补定位、补边界澄清；如果同类动态子图频繁复现，就应把它沉淀成新的静态图模板。
- `memory/` 与 `task-runs/` 已分层：前者沉淀长期知识，后者保存单次图执行过程，避免记忆文件被日志污染。

## 踩坑记录

- 只堆模块专家不等于可编排环境；如果没有静态图模板和节点交付契约，多 agent 很容易退化成散乱的多轮问答。
- `applyTo: "**"` 会持续吞上下文，除非确实是全局规则，否则优先放到 coordinator、专用 agent 或蓝图文档中。
