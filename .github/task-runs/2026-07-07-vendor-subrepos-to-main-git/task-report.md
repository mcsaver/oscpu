# 任务报告

## 基本信息

- `task_id`: `2026-07-07-vendor-subrepos-to-main-git`
- `task_slug`: `vendor-subrepos-to-main-git`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-07-07`
- `updated_at`: `2026-07-07`

## 任务目标

- `source_request`: 清理 `am-kernels/arch-test/src/riscv-arch-test` 与 `npc/rv64/testsuites/core-tests/src/riscv-tests` 的内部 Git，让外层仓库直接管理，同时继续使用目录内 `.gitignore` 忽略编译产物。
- `goal`: 两个路径不再作为 `160000` gitlink 或嵌套 Git 仓库存在；外层 Git 能接管普通文件；明显构建产物不进入索引。
- `scope`: Git 元数据、主仓库/子目录 ignore 规则、memory/task-run 记录；不修改测试语义，不运行 NPC/AM 功能回归。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `inspect` | `Codex` | `completed` | 两个嵌套仓库路径 | 确认主仓库索引为 `160000` gitlink，并记录原 HEAD | `git ls-files -s -- ...`; `rev-parse HEAD` |
| `convert` | `Codex` | `completed` | `.git/` 与 gitdir 文件 | 删除内部 Git 元数据，主仓库索引移除 gitlink | `find ... -name .git`; `git rm --cached -f -- ...` |
| `ignore` | `Codex` | `completed` | dry-run 发现的外层 ignore 冲突与产物误收 | 根 `.gitignore`、`am-kernels/.gitignore` allowlist；补充 `riscv-tests/.gitignore` 与 `riscv-arch-test/.gitignore` 产物规则 | `git check-ignore -v --no-index ...`; `git add -n -A -- ...` |
| `verify` | `Codex` | `completed` | 转换后的索引和工作树 | 无目标 gitlink、无内部 `.git`、无明显产物 staged | 见“收尾结论” |

## 关键产物

- `artifacts`: `.gitignore`、`am-kernels/.gitignore`、`am-kernels/arch-test/src/riscv-arch-test/.gitignore`、`npc/rv64/testsuites/core-tests/src/riscv-tests/.gitignore`
- `logs_or_traces`: 本报告内记录命令证据；无长日志。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/am-kernels.md`、`.github/memory/modules/npc.md`

## 收尾结论

- `final_result`: 两个测试套件目录已转为外层仓库可管理的普通 vendored 树，并已 staged。
- `evidence_summary`: `git ls-files -s -- <two paths> | awk '$1 == "160000" { print }'` 无输出；`find <two paths> -name .git -print` 无输出；`git ls-files -- <two paths> | rg '(^|/)\\.git($|/)'` 无输出；staged 文件名扫描未发现 `.git`、`build/`、`work/`、`*.elf`、`*.objdump`、`*.sig`、`*.results`、`*.dump`、`riscv-tests/isa/*-p-*` 等产物。
- `notes`: 原嵌套 HEAD 记录为 `riscv-arch-test=49cdd65f9497120e6484b0879bcb271e4842cbc5`、`riscv-tests=34e6b6d1e7936b526075432fb730d89148623484`、`riscv-tests/env=6de71edb142be36319e380ce782c3d1830c65d68`。
