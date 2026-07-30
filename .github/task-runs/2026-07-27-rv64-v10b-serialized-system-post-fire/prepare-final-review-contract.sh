#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
tool="${repo_root}/.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py"
contract_rel=".github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/subagent-contracts/final-reviewer-v1.json"
contract="${repo_root}/${contract_rel}"
rendered="${run_dir}/subagent-contracts/final-reviewer-v1.rendered.txt"

if [[ -e "${contract}" || -e "${rendered}" ]]; then
  printf 'refusing to overwrite existing final-review contract artifacts\n' >&2
  exit 2
fi

python3 "${tool}" create \
  --task-id rv64-v10b-serialized-system-post-fire-final-review-v1 \
  --task-kind read-only-review \
  --goal '独立终审本地 RV64 `OooPendingSystemSequencer` 八类 canonical SYSTEM/CSR/IRQ transaction：核对 accepted owner、C0 raw fire、C1 registered side effect/holder/stop clear、C2 no-repeat，CSR enqueue 到 exact ProducerId/PC commit lease，SATP/SFENCE/FENCE.I MMU action、typed redirect、`OooControlCommitSequencer` action 与 `OooFetchAxiBridge` stale-instruction clear；复核 pre-change false-green、14 个 compile-success RTL version 动态拒绝、113 项 module、functional 与 9 项 architecture gate 是否同一 design-id。优先寻找去重掩盖、间接观测、未覆盖 encoding、错误外推或证据身份漂移。' \
  --allow-path npc/rv64/vsrc/control/OooPendingSystemSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDispatchArbiter.v \
  --allow-path npc/rv64/vsrc/control/OooPendingDrainResolveGate.v \
  --allow-path npc/rv64/vsrc/control/OooCsrAccessRequestMux.v \
  --allow-path npc/rv64/vsrc/control/OooCsrTrapRequestMux.v \
  --allow-path npc/rv64/vsrc/control/OooControlPlane.v \
  --allow-path npc/rv64/vsrc/control/OooStopPendingSequencer.v \
  --allow-path npc/rv64/vsrc/control/OooRedirectArbiter.v \
  --allow-path npc/rv64/vsrc/control/OooControlEventApplySequencer.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontend.v \
  --allow-path npc/rv64/vsrc/frontend/OooFrontendRunGate.v \
  --allow-path npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v \
  --allow-path npc/rv64/vsrc/memory/OooMemoryAccess.v \
  --allow-path npc/rv64/vsrc/memory/OooMemoryRequestGate.v \
  --allow-path npc/rv64/vsrc/memory/OooFetchAxiBridge.v \
  --allow-path npc/rv64/vsrc/core/CsrFile.v \
  --allow-path npc/rv64/vsrc/core/NpcCoreTop.v \
  --allow-path npc/rv64/vsrc/core/OooCoreTopGlue.v \
  --allow-path npc/rv64/vsrc/writeback/OooWriteback.v \
  --allow-path npc/rv64/vsrc/writeback/OooControlCommitSequencer.v \
  --allow-path npc/rv64/testbench/Makefile \
  --allow-path npc/rv64/testbench/tests/tb_ooo_priv_system.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv \
  --allow-path npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv \
  --allow-path npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py \
  --allow-path npc/rv64/design/specs/ooo-pending-system-sequencer.md \
  --allow-path npc/rv64/design/specs/ooo-flush-redirect-contract.md \
  --allow-path npc/rv64/design/specs/ooo-csr-trap-request-mux.md \
  --allow-path npc/rv64/design/specs/ooo-csrfile.md \
  --allow-path npc/rv64/design/specs/ooo-serialize-memory-owner-terminal.md \
  --allow-path npc/rv64/design/arch/cohort/wfi-g1-exclusion.json \
  --allow-path npc/rv64/eval/ppa/evidence/architecture-current.json \
  --allow-path .github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/task-report.md \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/task-report.md \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/completion-definition.md \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/reviewer-report-v1.md \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/layered-binding.txt \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/layered-current.status \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/layered-current.log \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/module-current \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/functional-current \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/architecture \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/current-assert \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/fencei-cache-consumer \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2 \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/run-prechange-mmu-gap-probe.py \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/run-v10b-focused-matrix-v2.py \
  --allow-path .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/run-v10b-focused-matrix.py \
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
  --deliverable '按“RTL 对象或本地证据文件 → C0/C1/C2 或 compile/config → testbench/EDA raw observation → PASS/GAP 范围”输出独立终审。逐类裁决 CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ；列出最强 reachable counterexample，判断 production glue MMU pulse 与独立 FPC consumer test 是否足以证明 FENCE.I stale-instruction clear，核对变异 compile rc/result、113 个 design-id marker、functional/architecture identity；显式区分 V10B bounded sub-slice 与 simulation exit/Linux/SERIALIZE-G1/full-core arch-stable/PPA。' \
  --success-criterion '只读复核真实 RTL、TB 与本地证据，不运行仿真/综合/STA、不修改文件；不得因已有 PASS marker 推定覆盖，必须检查 raw counter/negative variant/identity；不得用去重或断言降级；如证据不能排除反例则给出 GAP、unknowns 与 scope_extension_request，如 bounded contract 成立则给出可审计 PASS 及残余边界；结束时显式归还 Windows→WSL 唯一工程命令 lane。' \
  --out "${contract_rel}"

python3 "${tool}" validate "${contract_rel}"
python3 "${tool}" render "${contract_rel}" | tee "${rendered}"
