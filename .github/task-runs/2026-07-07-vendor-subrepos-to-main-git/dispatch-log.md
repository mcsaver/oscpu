# 派发日志

## 基本信息

- `task_id`: `2026-07-07-vendor-subrepos-to-main-git`
- `task_slug`: `vendor-subrepos-to-main-git`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-07-07] `inspect` - `completed`

- `owner_agent`: `Codex`
- `trigger`: 用户要求清理两个子仓库 Git 元数据并由外层仓库管理。
- `depends_on`: 无
- `inputs`: `am-kernels/arch-test/src/riscv-arch-test`, `npc/rv64/testsuites/core-tests/src/riscv-tests`
- `action`: 检查主仓库索引、内部 `.git` 类型、嵌套仓库 HEAD。
- `outputs`: 两个目标路径为主仓库 `160000` gitlink；`riscv-tests/env/.git` 是 gitdir 文件。
- `evidence`: `git ls-files -s -- ...`; `rev-parse HEAD`
- `handoff_to`: `convert`
- `next_step`: 清理内部 Git 元数据并移除 gitlink。
- `notes`: 记录 HEAD 以便追溯。

### [2026-07-07] `convert` - `completed`

- `owner_agent`: `Codex`
- `trigger`: `inspect` 完成。
- `depends_on`: `inspect`
- `inputs`: 内部 `.git/` 目录与 `env/.git` gitdir 文件。
- `action`: 删除内部 Git 元数据；执行 `git rm --cached -f -- ...` 移除两个 gitlink。
- `outputs`: 外层索引不再包含目标 gitlink。
- `evidence`: `find ... -name .git -print` 无输出；`git ls-files -s ... | awk '$1 == "160000" { print }'` 无输出。
- `handoff_to`: `ignore`
- `next_step`: 处理外层 ignore 冲突和产物过滤。
- `notes`: 未删除源码文件。

### [2026-07-07] `ignore` - `completed`

- `owner_agent`: `Codex`
- `trigger`: dry-run 显示根 `.gitignore` 和 `am-kernels/.gitignore` 阻止外层 Git 进入目标源码树，且部分 extensionless ELF 会误收。
- `depends_on`: `convert`
- `inputs`: `git add -n -A -- ...` 与 `git check-ignore -v --no-index ...`
- `action`: 给 `npc/rv64/testsuites/core-tests/src/riscv-tests/**` 和 `am-kernels/arch-test/src/riscv-arch-test/**` 加精确 allowlist；补 `/isa/*-p-*`、`/isa/*-v-*`、`/npc/` 忽略规则。
- `outputs`: 外层 Git 可进入两个源码树，同时明显构建产物继续 ignored。
- `evidence`: `git check-ignore -v --no-index` 指向目标目录内 `.gitignore` 或精确 allowlist。
- `handoff_to`: `verify`
- `next_step`: 重新 stage 并最终验证。
- `notes`: 保持其它 `core-tests` 与 `am-kernels` 目录原忽略策略不变。

### [2026-07-07] `verify` - `completed`

- `owner_agent`: `Codex`
- `trigger`: ignore 规则修正并重新 `git add -A`。
- `depends_on`: `ignore`
- `inputs`: staged index
- `action`: 检查 gitlink、内部 `.git`、tracked `.git`、明显构建产物。
- `outputs`: 转换结果闭合。
- `evidence`: `git ls-files -s ...` 无 `160000`；`find ... -name .git` 无输出；`git diff --cached --name-only ... | rg <产物模式>` 无输出。
- `handoff_to`: 无
- `next_step`: 用户可直接 commit staged 变更。
- `notes`: 本任务未运行功能回归。
