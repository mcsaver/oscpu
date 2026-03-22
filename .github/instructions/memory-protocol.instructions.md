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
    ├── npc.md
    ├── nemu.md
    ├── abstract-machine.md
    ├── am-kernels.md
    ├── difftest.md
    └── yosys-sta.md
```

## 工作流程

### 1. 开始任务前 — 读取记忆
- **必须** 先读取 `.github/memory/project-status.md` 了解当前项目状态
- **必须** 读取自己模块对应的 `.github/memory/modules/<模块>.md`
- 如果任务涉及调试，读取 `.github/memory/known-issues.md` 查看是否有历史经验

### 2. 工作过程中 — 记录决策
- 做出重要设计决策时，追加到 `.github/memory/decisions.md`
- 遇到非显而易见的问题时，记录到 `.github/memory/known-issues.md`

### 3. 完成任务后 — 更新记忆
- **必须** 更新 `.github/memory/project-status.md` 的相关条目
- **必须** 更新自己模块的 `.github/memory/modules/<模块>.md`
- 如果修复了 bug，将问题从"活跃问题"移到"已解决问题"

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
