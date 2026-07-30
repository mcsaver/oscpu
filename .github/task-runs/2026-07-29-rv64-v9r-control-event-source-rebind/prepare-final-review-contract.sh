#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
tool="$repo_root/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="$run_dir/subagent-contracts/v9r-control-event-source-rebind-final-review-v1.json"
rendered="$run_dir/subagent-contracts/v9r-control-event-source-rebind-final-review-v1.rendered.txt"
mkdir -p "$(dirname "$contract")"

python3 "$tool" create \
  --task-id v9r-control-event-source-rebind-final-review-v1 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OooIntBackend/OooMemAxiBridge SQ-query retry C0 transaction 的当前验证源重绑，以及 CONTROL-EVENT-G1 ledger publisher/currentness auditor 是否在不修改 production RTL 的前提下同时拒绝 stale source binding、非 canonical SERIALIZE-G1 review tuple 和未声明的非 JSON 证据。' \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemAxiBridge.v \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/design/arch/architecture-debt-ledger.json \
  --allow-path npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  --allow-path npc/rv64/eval/ppa/tools/arch_stable_freeze.py \
  --allow-path npc/rv64/eval/ppa/tools/historical_defect_backfill.py \
  --allow-path npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py \
  --allow-path npc/rv64/eval/ppa/tests/test_historical_defect_backfill.py \
  --allow-path .github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design \
  --allow-path .github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff \
  --allow-path .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay \
  --allow-path .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure \
  --allow-path .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop \
  --allow-path .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --allow-read-command sha256sum \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/contract.md \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/evidence/preflight.json \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/evidence/postflight.json \
  --required-context .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/evidence-index.json \
  --required-context .github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/evidence/summary.json \
  --required-context .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/closed-evidence-currentness.json \
  --required-context npc/rv64/design/arch/architecture-debt-ledger.json \
  --required-context npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  --deliverable '按“RTL/本地证据对象→周期或编译配置→testbench/EDA 观测→PASS/GAP 范围”给出独立 verdict；逐项核对 production RTL pre/post 哈希、V9R 2/2 与 3/3、V9O verification-id/index、16 个 CLOSED debt 的 32 个 canonical semantic checks、SERIALIZE-G1 canonical verifier、历史 VD0/VD1 清零，以及 publisher/auditor 12 个正负单测；优先寻找假绿、哈希自循环、广义豁免或越级 ARCH_STABLE/PPA 结论。' \
  --success-criterion '只有在 production OooIntBackend.v/OooMemAxiBridge.v 未变、V9R raw owner/holder oracle 当前有效、V9O index verify 当前有效、publisher/auditor 对负向 fixture fail closed、closed-debt currentness 为 16 entries/38 artifacts/32 semantic checks/0 failures、历史 ledger 为 VD0=VD1=0 selected=NONE 且全局 architecture_freeze 仍诚实 GAP/PPA UNQUALIFIED 时才可 PASS；任何反例必须给出真实文件、字段、周期/配置和证据 marker，信息不足则 GAP 或 inconclusive。' \
  --out "$contract"

python3 "$tool" validate "$contract"
python3 "$tool" render "$contract" > "$rendered"
sha256sum "$contract" "$rendered"
