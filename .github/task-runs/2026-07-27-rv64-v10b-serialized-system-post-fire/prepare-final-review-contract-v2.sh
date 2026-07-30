#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract_rel=".github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/final-reviewer-v2.json"
contract="${repo_root}/${contract_rel}"
rendered="${run_dir}/subagent-contracts/final-reviewer-v2.rendered.txt"

if [[ -e "${contract}" || -e "${rendered}" ]]; then
  printf 'refusing to overwrite existing final-review v2 artifacts\n' >&2
  exit 2
fi

python3 "${tool}" create \
  --task-id rv64-v10b-serialized-system-post-fire-final-review-v2 \
  --task-kind read-only-review \
  --goal '独立复审本地 RV64 V10B 八类 serialized SYSTEM/CSR/IRQ transaction 的三个终审 GAP：直接读取真实 `frontend/OooFetchAxiBridge.v`、`DecodeUnit.v` 与 `OooDualMemBridgeWrapper.v`，核对 FENCE.I/SFENCE MMU→FPC/双 memory bridge 拓扑；核对四个 cohort exclusion 及 WFI-G1 已绑定 live design-id 且 rationale 未改变；核对 V3 matrix 显式 `design_id`、四个 testbench SHA、每 case oracle SHA、3 baseline PASS、14 个 compile-success RTL version 动态拒绝，以及 typed-reason 版本的局部 marker 已从误导 PASS 变为 FAIL；核对 V3 module 113/113 日志均携带相同 design-id。保留 `fdg-arch-trap-current.json` 导致 full-core ledger currentness probe 失败的边界，不得把 V10B bounded PASS 外推为 full-core closure。' \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  --allow-path npc/rv64/vsrc/control/OooCsrAccessRequestMux.v \
  --allow-path npc/rv64/vsrc/control/OooCsrTrapRequestMux.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontend.v \
  --allow-path npc/rv64/vsrc/frontend/OooFetchAxiBridge.v \
  --allow-path npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v \
  --allow-path npc/rv64/vsrc/decode/DecodeUnit.v \
  --allow-path npc/rv64/vsrc/memory/OooMemoryAccess.v \
  --allow-path npc/rv64/vsrc/memory/OooMemoryRequestGate.v \
  --allow-path npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v \
  --allow-path npc/rv64/vsrc/core/CsrFile.v \
  --allow-path npc/rv64/vsrc/core/NpcCoreTop.v \
  --allow-path npc/rv64/vsrc/writeback/OooControlCommitSequencer.v \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_priv_system.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv \
  --allow-path npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path npc/rv64/design/arch/architecture-debt-ledger.json \
  --allow-path npc/rv64/design/arch/cohort \
  --allow-path npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json \
  --allow-path npc/rv64/eval/ppa/evidence/architecture-current.json \
  --allow-path npc/rv64/eval/ppa/evidence/functional-aggregate-result.json \
  --allow-path .github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/task-report.md \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire \
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
  --required-context npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --required-context npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --deliverable '按“RTL/证据对象 → C0/C1/C2 或 compile/config → raw TB/EDA observation → PASS/GAP 范围”输出 v2 独立复审。先逐项裁决 v1 的路径、WFI identity、oracle identity、marker 四个问题是否关闭；再裁决八类 bounded transaction 是否可签署 PASS。列出仍成立的最强反例、unknowns 与 scope_extension_request，并单列 full-core ledger、simulation exit、Linux、arch-stable 与 PPA 边界。' \
  --success-criterion '只读复核真实 RTL、TB 与当前证据，不运行仿真/综合/STA、不修改文件；必须确认 V3 case 的 compile rc、最终 result、每 case testbench SHA 与 current file SHA、113 个 module design marker、cohort contract hash/design-id；必须直接检查 FENCE.I cache clear 和 dual-memory flush consumer；局部 marker 不得替代最终 result。只有 v1 四个 GAP 都有直接证据时才允许 bounded PASS；full-core ledger 的 FDG stale evidence 必须保持 GAP；结束时显式归还 Windows→WSL 唯一工程命令 lane。' \
  --out "${contract_rel}"

python3 "${tool}" validate "${contract_rel}"
python3 "${tool}" render "${contract_rel}" | tee "${rendered}"
