# github-index E2E Contract

- **范围**: `.github/` 下 agent、instructions、memory、e2e profile/module、task-run 文本证据，以及根目录/多 AI 入口 shim（`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`CONVENTIONS.md`、`.windsurfrules`、`.cursor/rules/agents.mdc`）的本地检索索引、目录式浏览、摘要压缩、按需 chunk 加载、DB-owned stored documents、备份/迁移/物化/恢复和安全维护入口。
- **上游**: 文件系统中的 `.github/**` 原始文件、根目录/多 AI 入口 shim、`software-flow` 软件开发闭环、`agent-system` e2e 规则发现。
- **下游**: agent 开工前 recall、规则/记忆检索、profile 选择、task-run 证据定位和状态巡检。
- **L0 gate**: `e2e_github_index_contract` 检查 `scripts/github_index_db.py`、本模块合约、profile、Git 跟踪状态、默认 `.github` 源目录、默认额外 agent shim 源、默认 `.github/cache/github-index.sqlite` 数据库路径、`.gitignore` 忽略边界、`file_chunks/chunk_fts` 片段表、`db_documents/db_document_chunks` stored document 表、`summary/compact`、`load`、`promote`、`backup`、`migrate`、`materialize` 与 `restore` CLI，以及 Python 语法。
- **L1 gate**: 使用临时 SQLite 数据库实际执行 `rebuild -> stat -> ls/tree -> show AGENTS.md -> query/search software-flow -> summary .github/memory -> load software-flow -> load --path AGENTS.md -> doctor --fail-on-drift`，证明索引器能从 `.github` 文件系统和根目录/多 AI 入口 shim 构建目录视图、查询入口、chunk/token 压缩概览和有 token budget 的按需加载入口，且不会把默认数据库作为原始产物纳入 Git；再用临时 mini repo 执行 `add -> ls -> search -> load -> refresh -> remove --delete-file --yes`，证明增删维护入口只在 `.github` 范围内操作真实文件并同步索引与 chunk；最后在临时 mini repo 中执行 `migrate --yes -> load --source stored -> materialize -> restore --yes`，证明 DB-first shim、备份和恢复链路可逆。
- **证据**: task-run report、dispatch-log、`github-index-contract.log` 中的 rebuild/stat/query/doctor 输出。
- **边界**: SQLite 保存索引、元数据、哈希、状态、可检索文本、派生 chunk/summary 和经 `promote` 固化的 stored documents；文件系统仍是当前原始产物事实源，除非显式运行 `migrate --yes` 并通过恢复 gate。`summary` 是压缩视图，`load` 是按需上下文加载，不替代必读规则、Git 历史、人工审阅、模块 profile 或业务 gate。`remove` 默认只移除索引行，只有显式 `--delete-file --yes` 才删除 `.github` 内真实文件。全仓 DB-first 迁移必须保留备份目录和 restore 证据，不能只看 shim 存在。
- **升级路线**: 后续可增加增量 watch、更多结构化字段、JSON 消费方、跨 task-run 的状态 dashboard，以及按模块/日期压缩 task-run 历史的二级摘要。
