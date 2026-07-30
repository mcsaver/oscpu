#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="${run_dir}/subagent-contracts/xret-lane1-marker-review-v1.json"
rendered="${run_dir}/subagent-contracts/xret-lane1-marker-review-v1.rendered.txt"

mkdir -p "$(dirname "${contract}")"

python3 "${tool}" create \
  --task-id xret-lane1-marker-review-v1 \
  --task-kind read-only-review \
  --goal '独立复核编译成功的 lane1_arch_trap_system_exclusion_removed RTL 变体：该变体删除 OooPendingLane1CaptureGate 的 lane1 架构异常排除项后，tb_ooo_priv_system 在周期 1717 由 [V10A-SERIAL-OWNER-ONEHOT] 检出 arch/system holder 重叠，但旧 XRET marker 未出现；确定 run-xret-mutations.py 的最小精确 marker 绑定，使此变体按真实 RTL 不变量计为动态检出，同时仍拒绝任意无关非零仿真结果。' \
  --allow-path .github/task-runs/2026-07-21-rv64-v9e-xret-current-design/run-xret-mutations.py \
  --allow-path .github/task-runs/2026-07-21-rv64-v9e-xret-current-design/evidence/mutations/summary.json \
  --allow-path .github/task-runs/2026-07-21-rv64-v9e-xret-current-design/evidence/mutations/logs/lane1_arch_trap_system_exclusion_removed.log \
  --allow-path .github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/task-report.md \
  --allow-path npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/testbench/tests/tb_ooo_priv_system.sv \
  --allow-path npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --allow-path npc/rv64/design/arch/serialize-at-retire-phase1.md \
  --allow-read-command rg \
  --allow-read-command sed \
  --allow-read-command git\ diff \
  --allow-read-command sha256sum \
  --required-context .github/instructions/rtl-agent-task-contract.instructions.md \
  --required-context .github/instructions/interface-contract-first.instructions.md \
  --required-context npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --required-context npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --deliverable '给出 RTL 变体源行、lane1 capture/arch-holder/system-holder 周期关系、实际断言 marker、旧 marker 未出现的原因、最小证据驱动器修改建议、会导致假绿的反例、未知项与 scope_extension_request。' \
  --success-criterion '结论必须区分生产 RTL 功能缺陷与证据 marker 漂移；只认可与 lane1 arch/system holder 重叠直接对应的精确断言或定向 testbench marker，不得把任意 make_returncode 非零当作动态检出，并说明基线 PASS 与变体 FAIL 的必要验证。' \
  --out "${contract}"

python3 "${tool}" validate "${contract}"
python3 "${tool}" render "${contract}" > "${rendered}"
sha256sum "${contract}" "${rendered}"
