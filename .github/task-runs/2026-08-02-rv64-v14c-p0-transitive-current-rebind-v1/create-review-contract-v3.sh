#!/usr/bin/env bash

set -euo pipefail

python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py create \
  --task-id v14c-p0-current-review-v3 \
  --task-kind read-only-review \
  --goal '复核当前 RV64 design-id 下 P0 九门 current-dynamic 收据的逐项债务归属，检查 121 条 P0 负向观测、118 次 RTL mutation 执行、3 次 oracle probe、114 个唯一 RTL 变体指纹、4 组跨 gate 同变体别名，以及未计入 P0 的 MIQ-FLUSH-G1 三条 P1 观测。' \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/build-counterexample-inventory.py \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/build-p0-final-receipt.py \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/build-section13-current-audit.py \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/counterexample-inventory-1 \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/p0-final-2 \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/section13-current-3 \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/current-bind-checker-replay-2 \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/current-bind-1/dynamic/mutations \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/p0-replay-elimination-checker-replay-1 \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/p0-replay-elimination-1/mutations \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/current-bind-1.status \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/current-bind-checker-replay-1.status \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/p0-replay-elimination-1.status \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/p0-final-1.status \
  --allow-path .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/p0-final-2.status \
  --allow-path .github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-1/mem/mutations \
  --allow-path .github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-1/ptw/mutations \
  --allow-path .github/task-runs/2026-08-02-rv64-v14b-architecture-current-freeze-audit-v1/evidence/p0-direct-rebind-checker-replay-1/rebind-receipt.json \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/counterexample-inventory-1/inventory.json \
  --required-context .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/p0-final-2/receipt.json \
  --required-context .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/section13-current-3/section13-current-audit.json \
  --deliverable '按 P0 gate、当前 design-id、testbench/EDA 负向观测与 PASS/GAP 范围给出独立结论；逐项复核债务计数、同变体别名、P0/P1 分界、日志哈希、源状态、历史状态、IFU 动态执行、warning 解释集合及 Section13/PPA 边界，并列出反例、unknowns、替代假设、scope_extension_request 和 confidence_and_basis。' \
  --success-criterion '仅当九门为当前动态正向 PASS，121 条 P0 负向观测精确分解为 118 次 RTL mutation 与 3 次 oracle probe、114 个唯一 RTL 变体及 4 组显式别名，MIQ-FLUSH-G1 三条 P1 观测未混入 P0，逐项日志与源哈希闭合，历史 FAIL/PASS 未原位改写，IFU 不依赖冻结重放，warning 只命中已声明行号与数组名且无 assertion failure，并且 Section13 保持 architecture RED、arch-stable=false、PPA BLOCKED 时，才可给出 APPROVED_CURRENT_SCOPE；否则按具体 gate、字段或 marker 给出 GAP 或 inconclusive。' \
  --out .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/subagent-contracts/v14c-p0-current-review-v3.json
