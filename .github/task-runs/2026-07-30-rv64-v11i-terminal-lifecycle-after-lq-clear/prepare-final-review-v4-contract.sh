#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
RUN_REL=".github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear"
RUN_DIR="$ROOT/$RUN_REL"
TOOL="$ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT="$RUN_DIR/subagent-contracts/v11i-terminal-lifecycle-final-review-v4.json"

python3 "$TOOL" create \
  --task-id v11i-terminal-lifecycle-final-review-v4 \
  --task-kind read-only-review \
  --goal '本地 RV64 OooIntBackend lane0 response terminal V11I 证据绑定与既有测试处置终审：独立复核不可变 attempt-9 的 lane6 metadata GAP 已保留，新 attempt-10 的 lane0 contract、focused/assert/mutation compile define、4-profile raw log、current checker identity 与 6×KEEP+tracker REBIND 分类一致；确认无 production RTL、expected architectural result、checker accepted-set、event dedup 或 assertion 语义变化；不修改文件。' \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker_semantic_checker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv \
  --allow-path npc/rv64/testbench/scripts/run_v11i_terminal_lifecycle.py \
  --allow-path npc/rv64/testbench/scripts/test_run_v11i_terminal_lifecycle.py \
  --allow-path npc/rv64/eval/ppa/tools/v11i_terminal_lifecycle_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_v11i_terminal_lifecycle_evidence.py \
  --allow-path "$RUN_REL/contract.md" \
  --allow-path "$RUN_REL/test-disposition.md" \
  --allow-path "$RUN_REL/task-report.md" \
  --allow-path "$RUN_REL/attempt-ledger.md" \
  --allow-path "$RUN_REL/evidence-index.md" \
  --allow-path "$RUN_REL/attempt-10-validation.md" \
  --allow-path "$RUN_REL/final-review-v2-result.md" \
  --allow-path "$RUN_REL/final-review-v3-test-disposition-gap.md" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/validation-receipt.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/sources.pre.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/sources.post.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/variant/OooIntBackend.v" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/production-assert/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/production-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/production-release/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/production-release/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/stale-tuple-assert/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/stale-tuple-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/stale-tuple-release/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/profiles/stale-tuple-release/sim.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-1/result/logs/tb_ooo_mem_owner_tracker.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/summary.json" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_mem_owner_terminal_collector.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_mem_owner_tracker.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_load_queue.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_int_backend.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_mem_axi_bridge.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_dual_mem_bridge_wrapper.log" \
  --allow-path "$RUN_REL/evidence/layered-regression-attempt-2/result/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log" \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context "$RUN_REL/test-disposition.md" \
  --required-context "$RUN_REL/final-review-v3-test-disposition-gap.md" \
  --required-context "$RUN_REL/attempt-10-validation.md" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-10/summary.json" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-10/validation-receipt.json" \
  --deliverable '按“RTL testbench/本地证据文件 → 周期/编译配置 → TB/EDA 观测 → PASS/GAP 范围”输出。独立核验 v3 两个 blocker：attempt-9 不可变保留且不再被选定；attempt-10 exact lane0 contract 与四份 commands.json 的 compile define、raw logs、runner/validator source binding 一致。逐项复核 6×KEEP+tracker REBIND，优先寻找 plusarg/define 混淆、旧层次依赖固化、validator 接受 lane6、REBIND 偷改 checker、失败 evidence 改写、production semantic delta、局部结论外推，并给出 blocker、unknown、scope_extension_request。' \
  --success-criterion '只有 attempt-9 原始 summary/status 未改写并明确 superseded；attempt-10 summary/receipt/source/raw hashes 一致、contract 精确写 lane0 response-terminal、四个 profile 都含 focused define 且 assert/mutation define 与配置精确匹配；validator 源码和负向单测对 lane6 与缺 focused define fail closed；七个既有 regression mode 可独立判为 6×KEEP+tracker REBIND；不存在 UPDATE_CONTRACT、OBSOLETE_WITH_EVIDENCE、RTL_REGRESSION 或 UNKNOWN_PENDING_REVIEW；无 production RTL/dedup/assertion weakening 且 system/architecture/PPA 不越级，才可 bounded APPROVE。' \
  --out "$OUT"

python3 "$TOOL" validate "$OUT"
python3 "$TOOL" render "$OUT"
