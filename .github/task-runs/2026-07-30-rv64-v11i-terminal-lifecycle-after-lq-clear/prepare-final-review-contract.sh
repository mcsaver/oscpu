#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
RUN_REL=".github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear"
RUN_DIR="$ROOT/$RUN_REL"
TOOL="$ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT="$RUN_DIR/subagent-contracts/v11i-terminal-lifecycle-final-review-v2.json"

python3 "$TOOL" create \
  --task-id v11i-terminal-lifecycle-final-review-v2 \
  --task-kind read-only-review \
  --goal '本地 RV64 OooIntBackend lane0 response terminal 经 OooMemOwnerTerminalCollector pending/dequeue、OooMemOwnerTracker edge-old token→ProducerId 与 OooLoadQueue terminal_seen 的 32-token 环回终审：独立核验 production assertions-on/off 静默、compile-success delayed-old-response tuple 在 assertions-on/off 的精确拒绝、普通模块/parent/bridge 回归、失败 attempt 保留、H1/H2/H3 裁决和 system/PPA claim 边界；不修改文件。' \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTracker.v \
  --allow-path npc/rv64/vsrc/memory/OooLoadQueue.v \
  --allow-path npc/rv64/vsrc/memory/OooMemAxiBridge.v \
  --allow-path npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker_semantic_checker.sv \
  --allow-path npc/rv64/testbench/scripts/run_v11i_terminal_lifecycle.py \
  --allow-path npc/rv64/testbench/scripts/test_run_v11i_terminal_lifecycle.py \
  --allow-path npc/rv64/eval/ppa/tools/v11i_terminal_lifecycle_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_v11i_terminal_lifecycle_evidence.py \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/design/specs/ooo-load-queue.md \
  --allow-path npc/rv64/design/specs/ooo-memory-producer-lease.md \
  --allow-path npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --allow-path npc/rv64/design/specs/ooo-dual-memory-terminal-owners.md \
  --allow-path .github/memory/project-status.md \
  --allow-path "$RUN_REL/contract.md" \
  --allow-path "$RUN_REL/pre-review-result.md" \
  --allow-path "$RUN_REL/implementation-review.md" \
  --allow-path "$RUN_REL/task-report.md" \
  --allow-path "$RUN_REL/attempt-ledger.md" \
  --allow-path "$RUN_REL/evidence-index.md" \
  --allow-path "$RUN_REL/build-layered-regression-receipt.py" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-1/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-2/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/summary.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/validation-receipt.json" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/sources.pre.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/sources.post.sha256" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/variant/OooIntBackend.v" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/profiles/production-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/profiles/production-release/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/profiles/stale-tuple-assert/sim.log" \
  --allow-path "$RUN_REL/evidence/terminal-lifecycle-attempt-9/profiles/stale-tuple-release/sim.log" \
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
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context "$RUN_REL/contract.md" \
  --required-context "$RUN_REL/implementation-review.md" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-9/summary.json" \
  --required-context "$RUN_REL/evidence/terminal-lifecycle-attempt-9/validation-receipt.json" \
  --required-context "$RUN_REL/evidence/layered-regression-attempt-2/summary.json" \
  --deliverable '按“RTL 对象或本地证据文件 → 周期/编译配置 → testbench/EDA 观测 → PASS/GAP 范围”输出；优先寻找 source one-shot 未覆盖入口、token/PID 自证、变体未真实编译激活、release oracle 读 DUT 反推、raw hash/设计身份漂移、失败证据改写、断言弱化、系统/PPA 越级结论，并明确 blocker、unknown 和 scope_extension_request。' \
  --success-criterion '只有 production assert/release 2/2 精确 PASS、delayed old lane0 response tuple 的 assert/release 2/2 均 compile-success 且分别被 holder-next 与独立 tracker/LQ raw-Q oracle 精确拒绝、7/7 分层回归 PASS、attempt-1/2 与 layered-attempt-1 原始 FAIL 保留、design-id/source/raw evidence 当前绑定、无 production RTL/dedup/assertion weakening，且结论不外推 system/architecture/PPA 时，才可对 V11I 本地 LOAD terminal one-shot/token-wrap 子范围给 bounded APPROVE。' \
  --out "$OUT"

python3 "$TOOL" validate "$OUT"
python3 "$TOOL" render "$OUT"
