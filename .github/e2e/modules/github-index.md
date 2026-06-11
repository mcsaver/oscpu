# github-index E2E Contract

- **范围**: `.github/` 下 agent、instructions、memory、e2e profile/module、task-run 文本证据等开发环境产物的本地检索索引、目录式浏览和安全维护入口。
- **上游**: 文件系统中的 `.github/**` 原始文件、`software-flow` 软件开发闭环、`agent-system` e2e 规则发现。
- **下游**: agent 开工前 recall、规则/记忆检索、profile 选择、task-run 证据定位和状态巡检。
- **L0 gate**: `e2e_github_index_contract` 检查 `scripts/github_index_db.py`、本模块合约、profile、Git 跟踪状态、默认 `.github` 源目录、默认 `.github/cache/github-index.sqlite` 数据库路径、`.gitignore` 忽略边界，以及 Python 语法。
- **L1 gate**: 使用临时 SQLite 数据库实际执行 `rebuild -> stat -> ls/tree -> query/search software-flow -> doctor --fail-on-drift`，证明索引器能从 `.github` 文件系统构建目录视图和查询入口，且不会把默认数据库作为原始产物纳入 Git；再用临时 mini repo 执行 `add -> ls -> search -> refresh -> remove --delete-file --yes`，证明增删维护入口只在 `.github` 范围内操作真实文件并同步索引。
- **证据**: task-run report、dispatch-log、`github-index-contract.log` 中的 rebuild/stat/query/doctor 输出。
- **边界**: SQLite 只保存索引、元数据、哈希、状态和可检索文本；文件系统仍是原始产物事实源。`remove` 默认只移除索引行，只有显式 `--delete-file --yes` 才删除 `.github` 内真实文件。该索引不替代 Git 历史、人工审阅、模块 profile 或业务 gate。
- **升级路线**: 后续可增加增量 watch、更多结构化字段、query 子命令的 JSON 消费方，以及跨 task-run 的状态 dashboard。
