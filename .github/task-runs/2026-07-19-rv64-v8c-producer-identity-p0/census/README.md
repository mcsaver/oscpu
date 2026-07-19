# v8c producer identity P0 census

本目录是 production source-tree 的 holder census 骨架，不修改 RTL，也不进入 canonical test。

运行：

```bash
.github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/census/run-holder-census.sh
```

机器产物：

- `holder-census.json`：分类与 RED/LOCAL_GREEN 状态账本；
- `check-holder-census.py`：production tree 扫描、manifest 审计和 mutation oracle；
- `run-holder-census.sh`：从任意工作目录可重跑的唯一入口；
- `contract.md`：分类、边界、fail-closed 条件和后续退出条件。

预期成功 marker：

```text
CENSUS_SCOPE=file-module
CENSUS_FIELD_LEVEL_COMPLETE=0
GLOBAL_NO_LIVE_REUSE=RED
GENERATION_SAFE_FULL_IDENTITY=RED
WRITEBACK_AUTHORIZATION=RED
Q1_CSR_LIVE_OWNER=RED
MEMORY_TOKEN_DOMAIN=LOCAL_GREEN
CENSUS_RESULT=PASS
```

`CENSUS_RESULT=PASS` 不能解释为 full identity 或 no-live-reuse GREEN。它只表示当前 lexical
file/module 扫描范围内没有未登记 carrier，且规定的 derived owner seed 未被漏掉。
file/module 单标签按 `strongest-live-authority` 保守分类；含 normal AUTH 与取消后 drain 子态的
混合模块必须标 `AUTH`，不能用 `TOMBSTONE` 隐去 live 权限。
