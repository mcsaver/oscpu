#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
tool="$repo_root/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="$run_dir/subagent-contracts/v9r-control-event-source-rebind-final-review-v2.json"
rendered="$run_dir/subagent-contracts/v9r-control-event-source-rebind-final-review-v2.rendered.txt"
mkdir -p "$(dirname "$contract")"

python3 "$tool" create \
  --task-id v9r-control-event-source-rebind-final-review-v2 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OooIntBackend/OooMemAxiBridge SQ-query retry C0 transaction 的当前验证源重绑，并检查 CONTROL-EVENT-G1 ledger publisher、currentness auditor 与 postflight receipt 是否精确绑定 SERIALIZE-G1 candidate/contract/review 三元组、V9R baseline/变异观测、V9O index、48 项 architecture currentness、4 项 historical backfill 和 20 项工作流定向单测。' \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemAxiBridge.v \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv \
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
  --allow-path .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/contract.md \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/evidence/preflight.json \
  --required-context .github/task-runs/2026-07-29-rv64-v9r-control-event-source-rebind/evidence/postflight.json \
  --required-context .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/closed-evidence-currentness.json \
  --required-context npc/rv64/design/arch/architecture-debt-ledger.json \
  --required-context npc/rv64/design/arch/historical-defect-backfill-ledger.json \
  --deliverable '按 RTL/本地证据对象、周期或编译配置、testbench/EDA 观测、PASS/GAP 范围给出独立 verdict；核对 production RTL 哈希、bridge TB raw oracle、V9R 2/2 与 3/3、V9O 167 项 index、16/38/32/0 currentness、SERIALIZE exact tuple、48/48、4/4、20/20 receipt，并优先寻找假绿、哈希自循环、遗漏输入或 ARCH_STABLE/PPA 越级结论。' \
  --success-criterion '只有 production OooIntBackend.v/OooMemAxiBridge.v 未变、SQ-query retry C0 raw assertion 由两个 testbench 当前源码支持、SERIALIZE ledger evidence 与 canonical candidate/contract/review 三元组逐项相等、所有 receipt 返回码与 marker 精确通过、A3 原始 FAIL 未改写且 frozen-input checker replay 为 PASS、全局 architecture freeze 仍为 GAP 且 PPA UNQUALIFIED 时才可 PASS；任何反例须给出真实文件、字段、周期/配置和 marker。' \
  --out "$contract"

python3 "$tool" validate "$contract"
python3 "$tool" render "$contract" > "$rendered"
sha256sum "$contract" "$rendered"
