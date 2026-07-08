# CLAUDE.md

> Claude Code / Claude 模型完整规范见 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 若当前运行环境只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`，以及相关 `modules/*.md` / `instructions/*.instructions.md`。注意 `.github/memory/**` 多为 DB-backed shim（8 行指针），读原文用 `python3 scripts/github_index_db.py load --source stored --path <路径>`。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`（DB-backed shim 禁止直接编辑本体：先 `load` 出全文改好，再 `python3 scripts/github_index_db.py update-stored <路径> --from-file <改后文件>` 写回）；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。同时按 `.github/instructions/doc-lifecycle.instructions.md` 推进受影响文档的生命周期（删模块→spec 归档、机制判死→⚠️ 注记、计划落地→归档、悬空引用清零）；全量重审用命名工作流 `doc-lifecycle-audit`。
6. 本仓库当前不通过 plugin / marketplace 传播工程规则；若要增强 Codex 的通用能力，应单独走 skills，而不是把工程约束混进插件入口。

请继续读取 [`.github/AGENTS.md`](./.github/AGENTS.md)。
