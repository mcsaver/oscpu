# Strict Guard Artifact Lifecycle Fix Implementation Plan

> **For agentic workers:** 用户已授权在当前工作区直接修复。按 `superpowers:systematic-debugging` 与 `superpowers:test-driven-development` 执行；现有 `artifact-audit` 是 RED/GREEN 测试，不调高阈值、不增加忽略规则。

**Goal:** 将唯一超限且被 Git 跟踪的 `topo40.rpt` 外部化，同时保留可追溯索引，使 `artifact-audit`、agent-system profile 与 strict guard 通过。

**Architecture:** 先用仓库 `index-evidence` 把 raw evidence 的 hash、size、摘要写入 `evidence_assets`，并只增补派生的 `evidence-index.md`；原历史 task-report 与 raw 内容均不改。该 legacy/manual run 没有原始 e2e manifest，不人工伪造。随后用 `git rm --cached` 只解除 1.65 MiB raw report 的 Git 跟踪；文件继续留在已忽略的 task-run `evidence/` runtime root。

**Tech Stack:** Git、Python `github_index_db.py`、Bash、agent-e2e profiles。

## Global Constraints

- 不改变 `max_tracked_evidence_bytes=1048576`。
- 不增加 `.gitignore` 豁免，不使用 assume-unchanged。
- 不删除或搬移 raw report；解除跟踪前后 SHA-256 必须一致。
- 不重写历史 `task-report.md` 或 raw evidence；只增补合同要求的派生 index。
- 不为 legacy/manual run 人工补造 e2e manifest；完整 manifest/trace 由本轮 fresh profile run 产生。
- 不触碰 DUT RTL。

---

### Task 1: RED 与根因冻结

**Files:**
- Create: `.github/task-runs/2026-07-11-strict-guard-artifact-lifecycle-fix/evidence/red.md`

- [x] 运行 `python3 scripts/github_index_db.py artifact-audit`。
- [x] 确认唯一错误为 `topo40.rpt` 1650168 bytes > 1048576 bytes。
- [x] 运行 strict guard，确认 npc-dev PASS、agent-system 缺 completed evidence。

### Task 2: 建立 DB raw-evidence 索引

**Files:**
- Preserve unchanged: `.github/task-runs/2026-07-11-knife-b2-s2s3/task-report.md`
- Create: `.github/task-runs/2026-07-11-knife-b2-s2s3/evidence-index.md`

- [x] 运行 `index-evidence <evidence-dir> --write-index --yes`，记录三份 raw evidence 的 hash/size并生成 pointer。
- [x] 确认 DB/index 包含 `topo40.rpt` 原路径、1650168 bytes 与原始 SHA-256。
- [x] 用 DB evidence readback 验证 `topo40.rpt` 元数据可召回。

### Task 3: 解除唯一超限文件的 source tracking

**Files:**
- Untrack only: `.github/task-runs/2026-07-11-knife-b2-s2s3/evidence/topo40.rpt`

- [x] 用 `git rm -n --cached` 预览只移除该路径。
- [x] 用 `git rm --cached` 从 index 解除跟踪；工作树 raw 文件必须仍存在且被 `.gitignore` 命中。
- [x] 比较解除跟踪前后 SHA-256，必须等于 `f2b292686adef90056a7fe0ea7977d6a0085d98a7d5aa9cf0c3b346ffe10d512`。

### Task 4: GREEN 与全链回归

**Files:**
- Create: `.github/task-runs/2026-07-11-strict-guard-artifact-lifecycle-fix/evidence/green.md`

- [x] `artifact-audit` exit 0。
- [x] DB evidence readback 能召回三份 raw evidence；旧 run 无 run-manifest，故不使用 run-scoped artifact-audit。
- [x] fresh agent-system run 的 run-scoped artifact/trace audit 通过。
- [x] `agent-system` profile fresh completed。
- [x] strict guard exit 0，required profiles 全部 PASS。
- [x] `audit-db-first`、markdown coverage 与 `git diff --check` PASS。
