---
name: workspace-artifacts-not-tool-dir
description: 有长期价值的分析产物/工具/记忆放 git 工作区，不只留在 ~/.claude/ 工具私有目录（跨平台/换工具即丢）
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4ec33c7a-397d-4c3b-bd57-9ff028f7f9bb
---

真正有长期复用价值且适合入库的脚本、量化数据、规范和稳定工程结论，应放在 **git 工作区**的自然 owner
位置，不应只留在某个 AI 工具私有目录。这个持久性原则不等于每个过程产物都要保存、创建 task-run 或
立即 commit。

**Why**：这些记忆/产物很关键，以后跨平台也要用；工具私有目录不跟 git 走，换机器就丢。用户 2026-07-05 明确纠正：不要把关键内容只放 claude 工具目录，要放工作区。

**How to apply**：
- 代码、可复用脚本和规范放到所属模块；稳定跨模块事实可进入 `.github/memory/`。
- `.github/task-runs/` 只用于显式 persistent/published 长跑、release/migration/security/forensic、真实跨
  会话交接或用户要求，不是普通分析产物的固定落点。
- 一次性日志、脚本草稿和中间数据可留在任务临时目录或不保存；不得把 secret 或无价值大产物搬入仓库。
- 更新 auto-memory 镜像时逐条审查稳定性和现行合同兼容性，不整目录覆盖，也不自动创建 commit。

关联 [[rv64-architecture-first-reflection]]。
