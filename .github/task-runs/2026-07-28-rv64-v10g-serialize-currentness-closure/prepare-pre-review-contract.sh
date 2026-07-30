#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="${run_dir}/subagent-contracts/serialize-currentness-pre-review-v1.json"
rendered="${run_dir}/subagent-contracts/serialize-currentness-pre-review-v1.rendered.txt"

mkdir -p "$(dirname "${contract}")"

python3 "${tool}" create \
  --task-id serialize-currentness-pre-review-v1 \
  --task-kind read-only-review \
  --goal '独立复核 live 5f9dd 本地 RV64 queue-head SYSTEM、architectural-trap 与 simulation-exit transaction：追踪 owner capture、older-owner drain、exact memory terminal、C0 raw apply、C1 holder/stop clear、C2 no-repeat，并判定现有 current-design evidence 是否足以把 SERIALIZE-G1 从 P1 OPEN 关闭；若不足，给出精确 module/signal/cycle/config 反例和最小定向 TB 或 compile-success RTL variant。' \
  --allow-path npc/rv64/vsrc \
  --allow-path npc/rv64/testbench \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/configs \
  --allow-path npc/rv64/design/arch \
  --allow-path npc/rv64/eval/ppa/evidence \
  --allow-path npc/rv64/eval/ppa/arch-stable \
  --allow-path .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal \
  --allow-path .github/task-runs/2026-07-27-rv64-v9z-serialize-arch-trap-terminal \
  --allow-path .github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire \
  --allow-path .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay \
  --allow-path .github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once \
  --allow-path .github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert \
  --allow-path .github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2 \
  --allow-path .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command 'git status' \
  --allow-read-command 'git diff' \
  --allow-read-command 'git show' \
  --allow-read-command sha256sum \
  --required-context .github/AGENTS.md \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context npc/rv64/design/arch/architecture-debt-ledger.json \
  --required-context npc/rv64/design/arch/rv64-hardware-wording-profile.md \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/contract.md \
  --deliverable '按 production module/signal/cycle/config 给出闭环矩阵：SYSTEM、architectural trap、simulation exit 的 owner birth、drain、exact terminal、raw apply、clear/no-repeat；逐项绑定 testbench、assertion-on/off、负向 RTL variant 与 evidence 文件，并明确 PASS、GAP、unknowns、替代假设和范围扩展请求。' \
  --success-criterion '结论必须独立识别任何 sticky-output 掩盖 raw duplicate、OOO_ASSERT 条件编译、非 exact terminal、lane priority、local flush 或 current-design binding 假绿；只有三条 transaction 的 C0/C1/C2 和 release 配置均有可追溯证据时才建议 CLOSED，否则保持 P1 OPEN 并给出可证伪的下一实验。' \
  --out "${contract}"

python3 "${tool}" validate "${contract}"
python3 "${tool}" render "${contract}" > "${rendered}"
sha256sum "${contract}" "${rendered}"

