#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
TOOL="$REPO_ROOT/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
OUT_REL=".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/subagent-contracts/v8v-ooo3-final-review-v2.json"

python3 "$TOOL" create \
  --task-id v8v-ooo3-final-review-v2 \
  --task-kind read-only-review \
  --goal '独立复核 RV64 双发射 OoO backend 的共享 16-entry retire-resident LQ：沿 dual dispatch、reservation、MIQ launch、final-PA/SQ disposition、response/WB/terminal、checkpoint/branch recovery、ROB lookup/commit 和 full ProducerId birth fence 查找微架构反例，并核对 OOO-3 same-design 证据闭包与 PPA 结论边界。' \
  --allow-path '.github/task-runs/2026-07-21-rv64-v8v-memory-ordering' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/run-focused.sh' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py' \
  --allow-path '.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused' \
  --allow-path 'npc/rv64/Makefile' \
  --allow-path 'npc/rv64/design/arch/rv64-architecture-ppa-contract.md' \
  --allow-path 'npc/rv64/design/specs/ooo-load-queue.md' \
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
  --allow-path 'npc/rv64/vsrc/memory/OooLoadQueue.v' \
  --allow-path 'npc/rv64/vsrc/memory/OooStoreQueue.v' \
  --allow-path 'npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v' \
  --allow-path 'npc/rv64/vsrc/writeback/OooRob.v' \
  --allow-read-command 'rg' \
  --allow-read-command 'sed' \
  --allow-read-command 'git diff' \
  --allow-read-command 'sha256sum' \
  --required-context 'npc/rv64/design/specs/ooo-load-queue.md' \
  --deliverable '给出 PASS、GAP 或 inconclusive；逐项列出影响结论的微架构反例、覆盖洞与置信依据。' \
  --deliverable '每个 GAP 给出精确 file:line、失效时序、最小定向 TB 或 compile-success mutation；若输入集合不足则给出 scope_extension_request。' \
  --deliverable '分别报告 OOO-3、overall architecture 与 PPA 状态，不从功能门外推频率、面积或功耗。' \
  --success-criterion '独立追踪 LQ 全生命周期、双端口同拍优先级、checkpoint/branch drain 和 ROB lookup/commit/free 耦合，不能只复述 task-run 结论。' \
  --success-criterion '核对 11 项 metric basis、9 项 LQ mutation、F2 的 13 项 integration mutation、固定 provenance inventory 与 live source hash replay 是否存在假绿路径。' \
  --success-criterion '不设置固定发现数量上限；所有仍影响 verdict 的反例均进入交付。' \
  --out "$OUT_REL"

python3 "$TOOL" validate "$OUT_REL"
python3 "$TOOL" render "$OUT_REL"
