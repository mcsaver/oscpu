#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
tool="$repo_root/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="$run_dir/subagent-contracts/owner-residency-review-v2.json"
prompt="$run_dir/subagent-contracts/owner-residency-review-v2.prompt.md"

python3 "$tool" create \
  --task-id owner-residency-review-v2 \
  --task-kind read-only-review \
  --goal '独立复核本地 RV64 OoO STORE 与 AMO 物理写事务在请求发射后到精确终止响应前的次拍 owner 驻留属性，确认 verification wrapper、可编译 RTL 源码变体和 arch-stable 语义校验能检出 owner tuple 过早消失，且不越级形成 PPA 或全核闭合结论。' \
  --allow-path .github/AGENTS.md \
  --allow-path .github/instructions/rtl-agent-task-contract.instructions.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/contract.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/completion-definition.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/rtl-derivation.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/task-report.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/dispatch-log.md \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/tb_v9n_sq_owner_residency.sv \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/tb_v9n_amo_owner_residency.sv \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-focused.sh \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/run-owner-residency-rtl-variants.py \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/focused/logs/tb_v9n_sq_owner_residency.log \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/focused/logs/tb_v9n_amo_owner_residency.log \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/rtl-variants/summary.json \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/rtl-variants/logs/sq_clear_owner_valid_on_request_fire.log \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/rtl-variants/logs/amo_clear_kind_on_write_fire.log \
  --allow-path .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/evidence/post-refresh-arch-stable.json \
  --allow-path npc/rv64/design/specs/ooo-memory-producer-lease.md \
  --allow-path npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md \
  --allow-path npc/rv64/design/arch/architecture-debt-ledger.json \
  --allow-path npc/rv64/vsrc/memory/OooStoreQueue.v \
  --allow-path npc/rv64/vsrc/execute/OooIntBackend.v \
  --allow-path npc/rv64/vsrc/memory/OooMemOwnerTracker.v \
  --allow-path npc/rv64/vsrc/core/NpcCoreTop.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_store_queue.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/eval/ppa/tools/irrevocable_owner_residency_evidence.py \
  --allow-path npc/rv64/eval/ppa/tests/test_irrevocable_owner_residency_evidence.py \
  --allow-path npc/rv64/eval/ppa/tools/arch_stable_freeze.py \
  --allow-path npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py \
  --allow-path npc/rv64/eval/ppa/evidence/irrevocable-owner-residency-current.json \
  --allow-path npc/rv64/eval/ppa/evidence/irrevocable-owner-residency.log \
  --allow-path npc/rv64/eval/ppa/evidence/architecture-current.json \
  --allow-read-command rg \
  --allow-read-command sed \
  --required-context .github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/contract.md \
  --required-context npc/rv64/design/specs/ooo-memory-producer-lease.md \
  --required-context npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md \
  --deliverable '给出 PASS、GAP 或 inconclusive；逐项核对 STORE/AMO 次拍 owner tuple、精确终止条件、canonical NpcCoreTop flush 绑定、两个源码变体的唯一失败 oracle、证据重构与 ledger/arch-stable 结论边界，并列出反例、未知项、替代解释、范围扩展请求以及置信依据。' \
  --success-criterion '只有在生产 RTL、verification wrapper、两个可编译 RTL 源码变体、当前 design-id 证据和 arch-stable 独立重构全部相互一致时才可判定该局部属性 PASS；必须明确全核仍为 38 blockers、PPA UNQUALIFIED、promotion=false。' \
  --out "$contract"

python3 "$tool" validate "$contract"
python3 "$tool" render "$contract" > "$prompt"
printf '%s\n' "$prompt"
