#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
TOOL="$REPO_ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT_REL=".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v3.json"

python3 "$TOOL" create \
  --task-id v8v-ooo3-final-review-v3 \
  --task-kind read-only-review \
  --goal '独立复核 RV64 双发射 OoO backend 的 OOO-3 候选：重点追踪 checkpoint_restore_i 在 Dispatch/ROB/IQ/rename、PRF、FP、SQ、LQ、MIQ、reservation、retry 与 bridge terminal 间的逐拍 owner 守恒，并复核双 bank load/store ordering、ROB retirement authority、full ProducerId birth fence、same-design evidence 与 PPA 结论边界。' \
  --allow-path '.github/task-runs/2026-07-21-rv64-v8v-memory-ordering' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/run-focused.sh' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused' \
  --allow-path 'npc/rv64/Makefile' \
  --allow-path 'npc/rv64/design/arch/rv64-architecture-ppa-contract.md' \
  --allow-path 'npc/rv64/design/specs/ooo-load-queue.md' \
  --allow-path 'npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md' \
  --allow-path 'npc/rv64/eval/ppa/evidence/architecture-current.json' \
  --allow-path 'npc/rv64/eval/ppa/evidence/memory-ordering.log' \
  --allow-path 'npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py' \
  --allow-path 'npc/rv64/eval/ppa/tools/architecture_hard_gates.py' \
  --allow-path 'npc/rv64/eval/ppa/tools/memory_ordering_evidence.py' \
  --allow-path 'npc/rv64/eval/ppa/tools/dual_memory_issue_evidence.py' \
  --allow-path 'npc/rv64/testbench/Makefile' \
  --allow-path 'npc/rv64/testbench/tests/tb_ooo_load_queue.sv' \
  --allow-path 'npc/rv64/testbench/tests/tb_ooo_store_queue.sv' \
  --allow-path 'npc/rv64/testbench/tests/tb_ooo_int_backend.sv' \
  --allow-path 'npc/rv64/vsrc/execute/OooIntBackend.v' \
  --allow-path 'npc/rv64/vsrc/execute/OooFpBackend.v' \
  --allow-path 'npc/rv64/vsrc/memory/OooLoadQueue.v' \
  --allow-path 'npc/rv64/vsrc/memory/OooStoreQueue.v' \
  --allow-path 'npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v' \
  --allow-path 'npc/rv64/vsrc/writeback/OooRob.v' \
  --allow-read-command 'rg' \
  --allow-read-command 'sed' \
  --allow-read-command 'git diff' \
  --allow-read-command 'sha256sum' \
  --required-context 'npc/rv64/design/specs/ooo-load-queue.md' \
  --required-context '.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/review-v2-gap.md' \
  --deliverable '给出 PASS、GAP 或 inconclusive；逐项列出影响裁决的微架构反例、coverage hole 与置信依据。' \
  --deliverable '每个 GAP 给出精确 file:line、逐拍 owner/state 时序、最小定向 TB 或 compile-success mutation；输入不足时给出 scope_extension_request。' \
  --deliverable '分别报告 OOO-3、overall architecture 与 PPA 状态；功能 evidence 不外推 frequency、area 或 power。' \
  --success-criterion '独立追踪未 launch load/store、已 launch load/store、response/terminal 同拍 restore、恢复后 redispatch/retire，以及 ROB lookup/commit/free 耦合。' \
  --success-criterion '核对 11 项 metric basis、9 项 LQ mutation、15 项 F2 parent mutation、28-file source manifest、41-file provenance inventory 与 live hash replay 的 oracle sensitivity。' \
  --success-criterion '不设置固定发现数量上限；所有仍影响 verdict 的反例均进入交付。' \
  --out "$OUT_REL"

python3 "$TOOL" validate "$OUT_REL"
python3 "$TOOL" render "$OUT_REL"
