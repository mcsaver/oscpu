---
description: "持久化记忆协议。当 agent 开始处理任何任务时加载，用于读取项目历史上下文、更新工作记录、记录设计决策和调试经验。所有模块 agent 都应遵循此协议。"
applyTo: "**"
---

# 持久化记忆协议

所有 agent 在工作时 **必须** 遵循以下记忆读写协议，确保项目知识跨会话持久化。

## 记忆文件位置

```
.github/memory/
├── project-status.md        — 项目进度总览
├── decisions.md             — 设计决策记录
├── known-issues.md          — 已知问题与调试历史
└── modules/                 — 各模块专属笔记
    ├── agent-system.md      — agent 架构与工作流环境
    ├── npc.md
    ├── nemu.md
    ├── abstract-machine.md
    ├── am-kernels.md
    ├── difftest.md
    ├── ysyx-soc.md
    └── yosys-sta.md
```

## 任务执行产物位置

```
.github/task-runs/
├── README.md                          — 任务级产物目录说明
└── templates/
    ├── task-report.template.md       — 图任务摘要模板
    └── dispatch-log.template.md      — 节点派发日志模板
```

- `memory/` 用于沉淀稳定结论、长期经验与设计决策
- `task-runs/` 用于保存单次图任务的执行产物、节点状态、证据链和派发历史
- 不要把长日志、逐节点状态变更、阶段性失败细节整段塞进 `memory/`；应优先写入 `task-runs/`

## 工作流程

### 1. 开始任务前 — 读取记忆与本地资料
- **必须** 先读取 `.github/memory/project-status.md` 了解当前项目状态
- **必须** 读取自己模块对应的 `.github/memory/modules/<模块>.md`
- 如果任务涉及 `.github/agents/`、`.github/instructions/`、`copilot-instructions.md` 或 AI 驱动硬件开发环境本身，**必须** 读取 `.github/memory/modules/agent-system.md` 与 `.github/agentic-hardware-blueprint.md`
- 如果任务涉及 AI 开发环境 e2e、自检、规则发现漂移或“降低 AI 不确定性”，**必须** 读取 `.github/instructions/agent-e2e-workflow.instructions.md`，并用 `scripts/agent-e2e.sh` 生成或复用 task-run 证据包
- 如果对应模块目录下存在已整理的本地学习资料（如 `study/README.md`、规范摘要、实现 checklist、设计笔记），**必须** 先读取索引/README，再按当前任务补读相关资料后再开始规划或编码
- 对 `tmp/`、提取文本等中间资料，只能作为快速检索入口；最终结论应以正式 Markdown 笔记、源码或规范为准
- 如果任务涉及调试，读取 `.github/memory/known-issues.md` 查看是否有历史经验

### 2. 工作过程中 — 记录决策
- 做出重要设计决策时，追加到 `.github/memory/decisions.md`
- 遇到非显而易见的问题时，记录到 `.github/memory/known-issues.md`

### 3. 完成判定前 — 语义核对钩子
- **必须** 回看用户原始请求、已粘贴/上传文档、PLAN/task-run checklist 和本轮实际证据，区分“整体目标完成”与“子任务/阶段完成”
- 如果原始请求是路线图、长期目标、包含多阶段建议，或用户明确要求“继续推进”，不得因某一个子项闭合就记录为整体完成；只能写“本子项完成”，并列出剩余条目
- 只有当原始目标中的全部硬性要求都有客观证据，且没有未处理的用户明确要求时，才能在 project-status、task-report 或回复中使用“完成目标/整体完成”
- 若发现本轮目标被 agent 自行缩小，必须在 RECORD 中写清缩小范围、已完成切片和未完成范围；必要时把误判沉淀为 known-issues 或 agent-system 经验

### 4. 完成任务后 — 更新记忆
- **必须** 更新 `.github/memory/project-status.md` 的相关条目
- **必须** 更新自己模块的 `.github/memory/modules/<模块>.md`
- 如果修复了 bug，将问题从"活跃问题"移到"已解决问题"
- 若任务属于跨模块、图任务或长链调试，**应当** 同时更新 `.github/task-runs/<日期-任务名>/task-report.md` 与 `dispatch-log.md`

## 记录格式规范

### 项目状态条目
```markdown
- [YYYY-MM-DD] 完成/修改了什么，影响哪些模块
```

### 设计决策条目
```markdown
### [编号] 决策标题
- **日期**: YYYY-MM-DD
- **状态**: 已决定
- **上下文**: 为什么需要做这个决策
- **决策**: 选择了什么方案
- **理由**: 为什么
```

### 问题记录条目
```markdown
### [编号] 问题标题
- **模块**: 出问题的模块
- **现象**: 具体表现
- **根因**: 根本原因
- **修复**: 如何修复
- **教训**: 学到了什么
```

## 约束
- 记忆文件使用中文
- 保持简洁，只记录关键信息，不要长篇大论
- 不要删除历史记录，只追加新内容
- 更新时保持文件结构不变
