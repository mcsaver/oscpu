# RV64 OoO 文档权威刷新实施计划

> **For agentic workers:** 本任务在用户指定的现有工作区内执行；不创建分支、不提交、不修改 DUT 逻辑。逐项完成后必须使用 `superpowers:verification-before-completion` 运行新鲜验证。

**Goal:** 把代码优先架构审计结论落实为当前权威快照、活跃规范、历史归档和可追溯勘误。

**Architecture:** 以 2026-07-11 RTL 快照为 current authority；旧时点快照通过 `git mv` 保留原文并由 history index 登记；活跃规范只记录当前事实与开放合同；不可变旧 task-run 不回写，使用新 task-run 和勘误纠正其解释。

**Tech Stack:** Markdown、纯文本审计产物、Git、`rg`、仓库 `github_index_db.py` 与 `agent-e2e.sh`。

## Global Constraints

- 使用中文，所有当前结论必须能追到 RTL、原始日志或明确的历史文件。
- 不修改 DUT 行为；允许三处 RTL 注释仅更新文档指针。
- 保留开工前的 dirty tree，不覆盖无关修改。
- 历史 task-run 不可变；旧快照正文不重写。
- 177 项 riscv-tests 可称逐项 PASS；AM 只能称 58/59；module 只能称摘要 86/86 且至少三份原始日志冲突。

---

### Task 1: 建立当前权威快照

**Files:**
- Create: `npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md`
- Modify: `npc/rv64/README.md`
- Modify: `npc/rv64/design/README.md`

- [x] 写入当前拓扑、容量、实现边界、开放合同、PPA 和验证范围。
- [x] 把两级 README 的 current authority 指向 2026-07-11 快照。
- [x] 用引用闭包扫描证明 active 入口不再把 2026-07-03 快照当 current truth。

### Task 2: 校正架构总览与活跃规范

**Files:**
- Modify: `npc/rv64/design/arch/ooo-core-architecture.md`
- Modify: `npc/rv64/design/arch/ROADMAP.md`
- Modify: `npc/rv64/design/arch/topology-analysis-2026-07-11.md`
- Modify: `npc/rv64/design/specs/ooo-frontend-dispatch-gate.md`
- Modify: `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`
- Modify: `npc/rv64/design/specs/ooo-fetch-axi-bridge.md`
- Modify: `npc/rv64/design/specs/ooo-csrfile.md`
- Modify: `npc/rv64/design/specs/ooo-commit-output-mux.md`
- Modify: `npc/rv64/design/specs/ooo-flush-redirect-contract.md`

- [x] 删除或标注已过时的 pending、synthetic lane、PRF 端口、redirect 与 fetch 吞吐描述。
- [x] 登记 FDG-G1、XRET-G1、IFU-AXI-G1、IFU-FETCH-G2、MIQ-G1、INSTRET-G1 等当前开放合同。
- [x] 把 ROADMAP 收敛为当前未完成项，历史完成项只作摘要。
- [x] 运行关键词反查，确认遗留命中均为显式历史语境。

### Task 3: 归档旧快照并闭合索引

**Files:**
- Move: `npc/rv64/design/arch/rtl-ground-truth-2026-07-03.md` -> `npc/rv64/design/arch/history/rtl-ground-truth-2026-07-03.md`
- Modify: `npc/rv64/design/arch/history/README.md`
- Modify: `npc/rv64/design/specs/history/README.md`
- Modify: `npc/rv64/design/specs/README.md`
- Modify: `.github/instructions/doc-lifecycle.instructions.md`

- [x] 使用 `git mv` 保留旧快照历史。
- [x] 在 history index 登记旧快照和已归档 HW A/D 实施计划。
- [x] 更新活跃索引、owner README 与注释指针。
- [x] 扫描所有旧路径引用并记录 immutable/history 例外。

### Task 4: 修正验证摘要假绿

**Files:**
- Create: `audit-results/2026-07-11-rv64-ooo-blind/VALIDATION_ERRATUM.txt`
- Modify: `audit-results/2026-07-11-rv64-ooo-blind/INDEX.txt`
- Modify: `audit-results/2026-07-11-rv64-ooo-blind/PHASE1_FROZEN.txt`
- Modify: `audit-results/2026-07-11-rv64-ooo-blind/04_DOCUMENT_COMPARISON.txt`
- Modify: `audit-results/2026-07-11-rv64-ooo-blind/05_FINAL_ARCHITECTURE_ASSESSMENT.txt`

- [x] 从 AM 原始日志确认 59 项中 58 PASS、1 FAIL。
- [x] 从三份 module 原始日志确认 FAIL / `$finish(1)` 后仍输出 `[RESULT] PASS`。
- [x] 保留 177 项 riscv-tests 逐项 PASS 的结论，并撤回 module/AM 全绿表述。

### Task 5: 持久化证据与 DB memory

**Files:**
- Create: `.github/task-runs/2026-07-11-rv64-doc-authority-refresh/*`
- Modify through DB workflow: `.github/memory/project-status.md`
- Modify through DB workflow: `.github/memory/modules/npc.md`
- Modify through DB workflow: `.github/memory/known-issues.md`

- [x] 记录上下文、审查派发、引用闭包、验证勘误与最终命令结果。
- [x] materialize、更新、stored 回写并 bounded readback 三份 memory。
- [x] 运行 DB-first audit。

### Task 6: 实现者与审查者双重验收

**Files:**
- Modify: `.github/task-runs/2026-07-11-rv64-doc-authority-refresh/evidence/*`
- Modify: `.github/task-runs/2026-07-11-rv64-doc-authority-refresh/task-report.md`

- [x] 运行 `git diff --check`。
- [x] 运行 Markdown 本地链接与旧引用闭包检查。
- [x] 运行仓库 strict guard：npc-dev fresh completed；agent-system 因既存超限证据阻断，按仓库规则记录显式豁免。
- [x] 审查者复核：寻找当前/历史混用、验证越级、未闭合引用和无意 RTL 行为变化。
- [x] 新鲜证据支持文档交付；task-report 以 completed + guard exemption 如实收口。
