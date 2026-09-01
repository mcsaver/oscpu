# Claude Code auto-memory 工作区镜像

## 这是什么

Claude Code（AI 编码工具）曾维护一份跨会话的私有 **auto-memory**，记录工程结论、方法学教训和用户
偏好。其历史源目录在工具私有位置：

```
~/.claude/projects/-home-lyg-PA-ysyx-workbench/memory/
```

该目录**不随 git 仓库走**。本目录是一个历史工作区镜像，用于检索仍可能有价值的稳定事实；它不是当前
agent operating contract，也不能凭旧会话描述创造授权、gate、branch、task-run 或 commit 要求。

## 结构

- `MEMORY.md` — recall 索引（标题 + 一句话钩子）；载入后仍需按当前 worktree 核实。
- `*.md` — 各条记忆，带 frontmatter（`type: user | feedback | project | reference`）；正文用 `[[name]]` 互链。

## 与 `.github/memory/`（上一级）的关系

| | 是什么 | 权威性 |
|---|---|---|
| `.github/AGENTS.md` + 当前相关 instruction | 当前跨 agent 行为合同和专项边界 | **规则真源** |
| `.github/memory/`（project-status / known-issues / decisions / modules） | 项目工程状态、决定与稳定事实 | 工程参考；流程条目可能被后续合同取代 |
| 本目录 `claude-auto-memory/` | Claude Code 私有 auto-memory 的历史镜像 | 只作 recall 线索；冲突或过期时不得采用 |

## 同步

- 快照生成于 **2026-07-05**。
- 刷新时逐条合并已经核实、稳定且跨会话有价值的工程事实；不得用整目录复制覆盖本目录，因为那会把
  已废弃的 BG setting、固定 branch、task-run、commit 或全量审计要求重新带回活跃索引。
- 反向导入其它工具前也要做同样筛选；历史工具配置只能留作带明确 superseded 标记的故障记录。
- 是否提交由用户的版本控制工作流决定；“写入镜像”不自动要求 commit。
