# Claude Code auto-memory 工作区镜像

## 这是什么

Claude Code（AI 编码工具）维护一份跨会话的私有 **auto-memory**，记录"如何更好地服务本项目"的稳定结论、方法学教训、用户偏好。其**源目录**在工具私有位置：

```
~/.claude/projects/-home-lyg-PA-ysyx-workbench/memory/
```

该目录**不随 git 仓库走**——换机器 / 换 AI 工具就丢失。**本目录是它的工作区快照镜像**，使这些关键记忆跟随 git 仓库、跨平台可查、可版本追溯。

## 结构

- `MEMORY.md` — 索引（每条一行：标题 + 一句话钩子），Claude 每次会话开头载入。
- `*.md` — 各条记忆，带 frontmatter（`type: user | feedback | project | reference`）；正文用 `[[name]]` 互链。

## 与 `.github/memory/`（上一级）的关系

| | 是什么 | 权威性 |
|---|---|---|
| `.github/memory/`（project-status / known-issues / decisions / modules） | **项目正式工程文档**，人和所有 agent 读 | **权威真源** |
| 本目录 `claude-auto-memory/` | **Claude Code 私有 auto-memory 的镜像**，措辞偏"给 AI 的操作提示"，与项目文档有浓缩/指针式重叠 | 辅助；**冲突时以 `.github/memory/` 正式文档为准** |

## 同步

- 快照生成于 **2026-07-05**。
- auto-memory 后续更新发生在源目录；需要刷新镜像时：
  ```bash
  cp ~/.claude/projects/-home-lyg-PA-ysyx-workbench/memory/*.md \
     .github/memory/claude-auto-memory/
  ```
- 反向（别的平台想让 Claude Code 用这些记忆）：把本目录内容拷回上述源目录即可。
