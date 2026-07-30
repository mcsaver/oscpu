#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract="${run_dir}/subagent-contracts/serialize-currentness-final-review-v2.json"
rendered="${run_dir}/subagent-contracts/serialize-currentness-final-review-v2.rendered.txt"

mkdir -p "$(dirname "${contract}")"

python3 "${tool}" create \
  --task-id serialize-currentness-final-review-v2 \
  --task-kind read-only-review \
  --goal '独立终审当前本地 RV64 product-default RTL 设计 sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897 的 SERIALIZE-G1：复核 legal non-FP lane0/head0 CSR 的 dispatch birth→C0 commit/CsrFile request/typed barrier→C1 typed apply/holder-stop clear→C2 raw quiet，lane1/FP CSR 与其余 SYSTEM/trap/simulation-exit 的 pending full-drain owner transaction，以及 SATP lane1/head0 位置分域。产品默认必须由 Makefile manifest 与 define.v fallback 同时给出 OOO_CSR_QUEUE_HEAD=1；显式 0 只作比较/恢复配置。依据 assert/release 原始周期计数、两个可编译 C2 负向 RTL 版本、3/3 baseline+14/14 SYSTEM 负向版本、26/26 current-design 回放、分层设计身份与 A3 冻结证据，裁定 SERIALIZE-G1 能否在当前设计上关闭。' \
  --allow-path npc/rv64/vsrc \
  --allow-path npc/rv64/testbench \
  --allow-path npc/rv64/Makefile \
  --allow-path npc/rv64/configs \
  --allow-path npc/rv64/design/arch \
  --allow-path .github/task-runs/2026-07-23-rv64-v9o-control-event-current-design \
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
  --required-context npc/rv64/design/arch/rv64-hardware-wording-profile.md \
  --required-context npc/rv64/design/arch/architecture-debt-ledger.json \
  --required-context npc/rv64/configs/product-rtl-defaults.mk \
  --required-context npc/rv64/Makefile \
  --required-context npc/rv64/vsrc/include/define.v \
  --required-context npc/rv64/vsrc/core/NpcCoreTop.v \
  --required-context npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv \
  --required-context npc/rv64/testbench/common/tb_ooo_core_top_glue_csr.svh \
  --required-context npc/rv64/testbench/tests/tb_ooo_priv_system.sv \
  --required-context npc/rv64/design/arch/ooo-core-architecture.md \
  --required-context npc/rv64/design/arch/ROADMAP.md \
  --required-context npc/rv64/design/arch/serialize-at-retire.md \
  --required-context npc/rv64/design/arch/serialize-at-retire-phase1.md \
  --required-context npc/rv64/design/arch/rtl-ground-truth-2026-07-11.md \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/serialize-g1-closure-candidate-v2.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-identity.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/semantic-delta-identity.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-qh-fallback-v1/summary.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/mutations/qh-csr-c2-replay-v5/summary.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/mutations/qh-csrfile-c2-replay-v2/summary.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/system-product-default-matrix-v2/summary.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-current-replay/launch-gate.json \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-current-replay/replay.status \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-current-replay/task-run.status \
  --required-context .github/task-runs/2026-07-28-rv64-v10g-serialize-currentness-closure/product-default-current-replay/driver.log \
  --required-context .github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/round-state.json \
  --required-context .github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/mutations/summary.json \
  --deliverable '按“RTL module/signal 或本地 evidence 文件 → 周期/编译配置 → testbench/EDA 观测 → PASS/GAP 范围”给出反例优先终审。分别裁定：(1) product-default manifest/fallback 与 current design-id；(2) queue-head CSR raw owner-bound C0/C1/C2、OOO_ASSERT on/off、3 条 committed 与 2 条 killed；(3) typed apply 和 CsrFile request 两个 C2 负向 RTL 版本的动态拒绝；(4) pending SYSTEM 及 SATP 位置分域；(5) architectural trap 与 simulation exit；(6) A3 publication/oracle 边界。最终只能给出 APPROVED_FOR_CURRENT_SCOPE 或 GAP，并明确建议 SERIALIZE-G1=CLOSED/OPEN、不可声称范围和最小后续动作。' \
  --success-criterion '只有在当前 design-id、产品默认定义、raw owner-bound C0/C1/C2、选择性恢复、两个可编译 C2 负向 RTL 版本、3/3 baseline+14/14 SYSTEM 负向版本、trap/exit 当前设计适用性和 26/26 分层回放均无未解反例时才可 APPROVED。GAP 必须指出具体 lane、周期、配置、owner/holder 或本地证据路径。不得以 sticky 输出或去重掩盖重复终端事务，不得削弱 RTL assertion，不得把 A3 原始 FAIL 改写成 PASS，不得把 A4 TERM 当作 PASS；即使关闭 SERIALIZE-G1，architecture freeze 仍为 GAP、PPA 仍为 UNQUALIFIED，须等待历史缺陷回填。' \
  --out "${contract}"

python3 "${tool}" validate "${contract}"
python3 "${tool}" render "${contract}" > "${rendered}"
sha256sum "${contract}" "${rendered}"
