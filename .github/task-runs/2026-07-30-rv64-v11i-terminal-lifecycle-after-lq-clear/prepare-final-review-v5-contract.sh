#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
RUN_REL=".github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear"
RUN_DIR="$ROOT/$RUN_REL"
TOOL="$ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT="$RUN_DIR/subagent-contracts/v11i-terminal-lifecycle-final-review-v5.json"

python3 "$TOOL" create \
  --task-id v11i-terminal-lifecycle-final-review-v5 \
  --task-kind read-only-review \
  --goal '本地 RV64 OooIntBackend lane0 response terminal V11I attempt-11 终审：独立核验缺 focused compile define 的负向样例保留 canonical commands.json 后缀并精确命中目标错误，attempt-9/10 原始 GAP 未改写，attempt-11 lane0 contract、4-profile commands/raw logs/current checker identity、6×KEEP+tracker REBIND 与 claim boundary 一致；不修改文件。' \
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
  --allow-path "$RUN_REL/attempt-11-validation.md" \
  --allow-path "$RUN_REL/final-review-v3-test-disposition-gap.md" \
  --allow-path "$RUN_REL/final-review-v4-checker-test-gap.md" \
  --allow-path "$RUN_REL/terminal-lifecycle-attempt-9.status" \
  --allow-path "$RUN_REL/terminal-lifecycle-attempt-10.status" \
  --allow-path "$RUN_REL/terminal-lifecycle-attempt-11.status" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-10/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/validation-receipt.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/sources.pre.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/sources.post.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/variant/OooIntBackend.v" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/production-assert/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/production-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/production-release/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/production-release/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/stale-tuple-assert/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/stale-tuple-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/stale-tuple-release/commands.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-11/profiles/stale-tuple-release/sim.log" \
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
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context "$RUN_REL/test-disposition.md" \
  --required-context "$RUN_REL/final-review-v4-checker-test-gap.md" \
  --required-context "$RUN_REL/attempt-11-validation.md" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-11/summary.json" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-11/validation-receipt.json" \
  --deliverable '按“RTL testbench/本地证据文件 → 周期/编译配置 → TB/EDA 观测 → PASS/GAP 范围”输出。优先复核 v4 假绿是否真正消失：temporary raw path 仍以 /commands.json 结尾、删 focused define 后先通过路径/hash binding、assertRaisesRegex 只接受精确 focused-define 错误。再核验 attempt-11 source/RTL/raw binding、4-profile marker、attempt-9/10 保留与 6×KEEP+tracker REBIND；寻找其它假绿、production semantic delta、断言弱化或越级结论，并给出 blocker、unknown、scope_extension_request。' \
  --success-criterion '只有 v4 负向测试使用 canonical /commands.json 路径并锁定 exact focused-define error，删除 validator focused-define 检查会使该测试失败；attempt-11 summary/receipt/source/raw hashes 一致且 contract/commands/markers 精确；attempt-9/10 状态和 summary 未改写并明确 superseded；七个既有 regression mode 为 6×KEEP+tracker REBIND且无 UPDATE_CONTRACT、OBSOLETE_WITH_EVIDENCE、RTL_REGRESSION、UNKNOWN_PENDING_REVIEW；无 production RTL/dedup/assertion weakening且不外推 system/architecture/PPA，才可 bounded APPROVE。' \
  --out "$OUT"

python3 "$TOOL" validate "$OUT"
python3 "$TOOL" render "$OUT"
