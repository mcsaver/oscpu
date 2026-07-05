---
name: workspace-artifacts-not-tool-dir
description: 有长期价值的分析产物/工具/记忆放 git 工作区，不只留在 ~/.claude/ 工具私有目录（跨平台/换工具即丢）
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4ec33c7a-397d-4c3b-bd57-9ff028f7f9bb
---

用户要求：凡有长期价值的东西——分析用的 workflow 脚本、量化数据、最终报告/artifact、以及 auto-memory 关键结论——都要放进 **git 工作区**（跟仓库走、跨平台/换机器/换 AI 工具可用），**不要只留在 `~/.claude/` 这个工具私有目录**（会随 job 删除或换环境而丢）。

**Why**：这些记忆/产物很关键，以后跨平台也要用；工具私有目录不跟 git 走，换机器就丢。用户 2026-07-05 明确纠正：不要把关键内容只放 claude 工具目录，要放工作区。

**How to apply**：
- 有长期价值的产物直接写工作区合适位置。已约定落点：
  - `.github/task-runs/<日期-任务名>/tools/`（脚本/数据）、`.../reports-html/`（网页报告）
  - `.github/memory/claude-auto-memory/`（auto-memory 工作区镜像，2026-07-05 建，含 README 说明与 `.github/memory/` 正式文档的权威关系）
- 一次性过程文件（append 片段、commit message、脚本迭代中间版）仍可用 `$CLAUDE_JOB_DIR/tmp`。
- auto-memory 有实质更新后，`cp ~/.claude/projects/-home-lyg-PA-ysyx-workbench/memory/*.md .github/memory/claude-auto-memory/` 刷新镜像并 commit。

关联 [[rv64-architecture-first-reflection]]。
