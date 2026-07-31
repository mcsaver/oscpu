#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
RUN_REL=".github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear"
RUN_DIR="$ROOT/$RUN_REL"
TOOL="$ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT="$RUN_DIR/subagent-contracts/v11i-test-disposition-final-review-v3.json"

python3 "$TOOL" create \
  --task-id v11i-test-disposition-final-review-v3 \
  --task-kind read-only-review \
  --goal '本地 RV64 OooIntBackend lane0 terminal 生命周期 V11I 的既有 testbench 处置终审：逐项核验 collector/tracker/LoadQueue/IntBackend/AXI bridge/dual wrapper/V8X recovery 的 tested contract、implementation dependency、old/new test SHA、KEEP/REBIND 分类与 preserved evidence；确认 tracker 项仅修复 semantic-checker 源文件绑定，IntBackend 既有模式未因 plusarg 隔离的新 lane0 场景而改变 expected result；不修改文件。' \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker_semantic_checker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv \
  --allow-path "$RUN_REL/contract.md" \
  --allow-path "$RUN_REL/test-disposition.md" \
  --allow-path "$RUN_REL/task-report.md" \
  --allow-path "$RUN_REL/attempt-ledger.md" \
  --allow-path "$RUN_REL/final-review-v2-result.md" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/summary.json" \
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
  --required-context "$RUN_REL/contract.md" \
  --required-context "$RUN_REL/test-disposition.md" \
  --required-context "$RUN_REL/evidence/layered-regression-attempt-2/summary.json" \
  --deliverable '按“RTL testbench/本地证据文件 → 周期/编译配置 → TB/EDA 观测 → PASS/GAP 范围”输出。逐项判断 KEEP、REBIND、UPDATE_CONTRACT、OBSOLETE_WITH_EVIDENCE、RTL_REGRESSION 或 UNKNOWN_PENDING_REVIEW；优先寻找把旧层次路径误固化为合同、REBIND 偷改 checker 接受集合、旧/新 SHA 错绑、未保留 FAIL、plusarg 隔离失效、真实 RTL regression 被误归类、局部结果外推。给出 blocker、unknown、scope_extension_request。' \
  --success-criterion '只有 production RTL semantic delta 为 none；六个现有 regression mode 的合同、checker 与 expected result 保持不变并可分类 KEEP；tracker 测试仅补齐既有 semantic-checker 的 compile/source binding、checker 语义不变并可分类 REBIND；所有 old/new SHA、attempt-1 FAIL 与 attempt-2 PASS、7/7 layered logs 绑定正确；不存在 UPDATE_CONTRACT、OBSOLETE_WITH_EVIDENCE、RTL_REGRESSION 或 UNKNOWN_PENDING_REVIEW，才可给 test-disposition bounded APPROVE。' \
  --out "$OUT"

python3 "$TOOL" validate "$OUT"
python3 "$TOOL" render "$OUT"
