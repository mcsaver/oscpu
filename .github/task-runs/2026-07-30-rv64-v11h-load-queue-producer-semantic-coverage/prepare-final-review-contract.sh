#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
TOOL="$REPO_ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
CONTRACT="$RUN_DIR/subagent-contracts/v11h-load-queue-producer-final-review-v2.json"
RENDERED="$RUN_DIR/subagent-contracts/v11h-load-queue-producer-final-review-v2.rendered.txt"

cd "$REPO_ROOT"
python3 "$TOOL" create \
  --task-id v11h-load-queue-producer-final-review-v2 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OooLoadQueue valid_q/producer_id_q/terminal_seen_q 在 normal terminal、completion、selective/global recovery、killed drain 与 ROB release 周期中的合同，以及 V11H testbench/EDA 证据是否足以只闭合 load-queue-producers。优先寻找永久 live holder、重复 terminal、同沿优先级、raw-Q oracle 自证、旧 design-id 误重绑和证据发布假绿。' \
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
  --deliverable '按 RTL 对象/配置/TB-EDA 观测/PASS-GAP 范围给出独立 verdict；列出 blocker、反例、未知项、证据假绿入口和 scope extension request，并核对原 attempt-3 FAIL、独立 checker replay PASS、ordinary attempt-2 PASS、当前实例图与 architecture RED 边界。' \
  --success-criterion '只有在 production RTL 无永久 holder/重复 terminal/同沿优先级反例，4 个正向配置和 62 个 assertion-off RTL 变体由独立 raw-Q oracle 闭合，selected-source replay 不改写旧 design-id，所有失败 attempt 原样保留，且结论不外推 system/PPA 时才可对 load-queue-producers 给 bounded APPROVE；否则明确 GAP/blocker。' \
  --out "$CONTRACT"

python3 "$TOOL" validate "$CONTRACT"
python3 "$TOOL" render "$CONTRACT" >"$RENDERED"
sha256sum "$CONTRACT" "$RENDERED"
