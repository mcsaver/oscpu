#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
TOOL="$REPO_ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
CONTRACT="$RUN_DIR/subagent-contracts/v11h-load-queue-producer-final-review-v3.json"
RENDERED="$RUN_DIR/subagent-contracts/v11h-load-queue-producer-final-review-v3.rendered.txt"

cd "$REPO_ROOT"
python3 "$TOOL" create \
  --task-id v11h-load-queue-producer-final-review-v3 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OooLoadQueue valid_q/producer_id_q/terminal_seen_q 的 production 周期合同，以及 final-review-v2 的 raw-Q knownness assertion 与 system-rerun schema 两个 blocker 是否已由当前设计和冻结 EDA 证据闭合。优先寻找 assertion 假绿、attempt-4 replay 越权、scope 字段弱化、旧 graph/design-id 重绑、永久 live holder、重复 terminal 与同沿优先级反例。' \
  --allow-path npc/rv64/vsrc/memory/OooLoadQueue.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_load_queue_producer_semantic.sv \
  --allow-path npc/rv64/eval/ppa/tools/load_queue_producer_semantic_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_load_queue_producer_semantic_evidence.py \
  --allow-path npc/rv64/eval/ppa/tools/load_queue_producer_checker_replay.py \
  --allow-path npc/rv64/eval/ppa/tests/test_load_queue_producer_checker_replay.py \
  --allow-path npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py \
  --allow-path npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py \
  --allow-path npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py \
  --allow-path npc/rv64/design/arch/producer-holder-census.json \
  --allow-path npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json \
  --allow-path npc/rv64/design/specs/ooo-load-queue.md \
  --allow-path npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --allow-path npc/rv64/Makefile \
  --allow-path .github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command sha256sum \
  --required-context npc/rv64/design/specs/ooo-load-queue.md \
  --required-context npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md \
  --required-context .github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/contract.md \
  --required-context .github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/implementation-report.md \
  --required-context .github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence-index.md \
  --required-context .github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/final-review-v2-result.md \
  --deliverable '按 RTL 对象/配置/TB-EDA 观测/PASS-GAP 范围给出独立 verdict；逐项判定 v2 的 raw-Q knownness assertion 与 system-rerun schema blocker，核对 attempt-4 原 FAIL、无 RTL 重执行 checker replay、graph v2、ordinary attempt-3、11/33 ledger 与 architecture RED 边界；列出 blocker、反例、未知项、假绿入口和 scope extension request。' \
  --success-criterion '只有在 production RTL 对每个 valid_q entry 直接断言完整 producer_id_q known，定向 probe 命中真实 RTL marker 而合法回归不误触发，精确 system-rerun schema 及其负向单测 fail-closed，attempt-4 原 FAIL 保留且 replay 绑定同一 current design/graph/checker 并明确未重跑 RTL，4 个正向配置和 62 个 assertion-off 变体仍闭合，且结论不外推 system/architecture/PPA 时才可对 load-queue-producers 给 bounded APPROVE；否则明确 GAP/blocker。' \
  --out "$CONTRACT"

python3 "$TOOL" validate "$CONTRACT"
python3 "$TOOL" render "$CONTRACT" >"$RENDERED"
sha256sum "$CONTRACT" "$RENDERED"
