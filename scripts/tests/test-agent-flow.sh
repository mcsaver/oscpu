#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
runner="${repo_root}/scripts/agent-flow.sh"
test_root=$(mktemp -d)

cleanup() {
  local rc=$?
  case "${test_root}" in
    /tmp/*) rm -rf -- "${test_root}" ;;
    *) printf '[agent-flow-test] refuse cleanup outside /tmp: %s\n' "${test_root}" >&2 ;;
  esac
  exit "${rc}"
}
trap cleanup EXIT

export AGENT_FLOW_STATE_ROOT="${test_root}/state"
export AGENT_FLOW_BIN_DIR="${test_root}/bin"

"${runner}" begin --task review-ok --class review
"${runner}" finish --task review-ok >"${test_root}/review.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/review.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/review.summary"

"${runner}" begin --task review-gate --class review
set +e
"${runner}" record --task review-gate --gate maintain-release \
  >"${test_root}/review-gate.out" 2>&1
review_gate_rc=$?
set -e
[[ "${review_gate_rc}" -eq 2 ]]
"${runner}" finish --task review-gate >"${test_root}/review-gate.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/review-gate.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/review-gate.summary"

"${runner}" begin --task analysis-gate --class analysis
set +e
"${runner}" record --task analysis-gate --gate flow-observation-smoke \
  >"${test_root}/analysis-gate.out" 2>&1
analysis_gate_rc=$?
set -e
[[ "${analysis_gate_rc}" -eq 2 ]]
"${runner}" finish --task analysis-gate >"${test_root}/analysis-gate.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/analysis-gate.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/analysis-gate.summary"

"${runner}" begin --task docs-record --class docs --archive none
"${runner}" record --task docs-record \
  --path .github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/delivery-summary.md
"${runner}" finish --task docs-record --plan >"${test_root}/docs-record.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/docs-record.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/docs-record.summary"

"${runner}" begin --task docs-roadmap-mirror --class docs --archive none
"${runner}" record --task docs-roadmap-mirror \
  --path npc/rv64/design/arch/ROADMAP.md
"${runner}" finish --task docs-roadmap-mirror --plan \
  >"${test_root}/docs-roadmap-mirror.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/docs-roadmap-mirror.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/docs-roadmap-mirror.summary"

"${runner}" begin --task docs-retained-evidence --class docs --archive none
"${runner}" record --task docs-retained-evidence \
  --path .github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/rootfs-093c2380-systemd-strict-6b-v14e-a2/terminal-markers.txt
"${runner}" finish --task docs-retained-evidence --plan \
  >"${test_root}/docs-retained-evidence.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/docs-retained-evidence.summary"
grep -Fqx 'GATE_COUNT=2' "${test_root}/docs-retained-evidence.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-architecture-debt-current' \
  "${test_root}/docs-retained-evidence.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-historical-defect-current' \
  "${test_root}/docs-retained-evidence.summary"

"${runner}" begin --task docs-explicit-gate --class docs --archive none
"${runner}" record --task docs-explicit-gate --gate flow-observation-smoke
"${runner}" finish --task docs-explicit-gate --plan \
  >"${test_root}/docs-explicit-gate.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/docs-explicit-gate.summary"
grep -Fqx 'GATE_COUNT=1' "${test_root}/docs-explicit-gate.summary"
grep -Fqx 'PLANNED_GATE_0=flow-observation-smoke' \
  "${test_root}/docs-explicit-gate.summary"

"${runner}" begin --task docs-environment-surface --class docs --archive none
"${runner}" record --task docs-environment-surface \
  --path .github/instructions/agent-lightweight-workflow.instructions.md
set +e
"${runner}" finish --task docs-environment-surface \
  >"${test_root}/docs-environment-surface.summary"
docs_environment_surface_rc=$?
set -e
[[ "${docs_environment_surface_rc}" -eq 1 ]]
grep -Fqx 'RESULT=BLOCKED' "${test_root}/docs-environment-surface.summary"
grep -Fq 'requires class=environment or release' \
  "${test_root}/docs-environment-surface.summary"

"${runner}" begin --task review-write --class review
"${runner}" record --task review-write --path npc/rv64/vsrc/example.sv
set +e
"${runner}" finish --task review-write >"${test_root}/review-write.summary"
review_write_rc=$?
set -e
[[ "${review_write_rc}" -eq 1 ]]
grep -Fqx 'RESULT=BLOCKED' "${test_root}/review-write.summary"

"${runner}" begin --task development-evidence --class development --archive none
"${runner}" record --task development-evidence --path src/example.c
set +e
"${runner}" finish --task development-evidence >"${test_root}/development-missing.summary"
development_missing_rc=$?
set -e
[[ "${development_missing_rc}" -eq 1 ]]
grep -Fq 'require one PASS evidence' "${test_root}/development-missing.summary"
"${runner}" evidence --task development-evidence --name rtl-focused-test --status PASS
"${runner}" decision --task development-evidence --kind decision \
  --text 'focused RTL evidence closes the modified transaction path'
"${runner}" finish --task development-evidence >"${test_root}/development.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/development.summary"
grep -Fqx 'GATE_COUNT=0' "${test_root}/development.summary"
grep -Fq $'\tdecision\tfocused RTL evidence closes the modified transaction path\t-' \
  "${AGENT_FLOW_STATE_ROOT}/development-evidence/decisions.tsv"

"${runner}" begin --task scope-expanded --class development --archive none
"${runner}" record --task scope-expanded \
  --path .github/instructions/rv64-ppa-optimization-workflow.instructions.md
set +e
"${runner}" finish --task scope-expanded >"${test_root}/scope-expanded-blocked.summary"
scope_expanded_rc=$?
set -e
[[ "${scope_expanded_rc}" -eq 1 ]]
grep -Fq 'requires class=environment or release' \
  "${test_root}/scope-expanded-blocked.summary"
"${runner}" reclassify --task scope-expanded --class environment \
  --reason 'the user added an AI workflow contract change'
"${runner}" status --task scope-expanded >"${test_root}/scope-expanded-active.summary"
grep -Fqx 'TASK_CLASS=environment' "${test_root}/scope-expanded-active.summary"
grep -Fqx 'GENERATION=3' "${test_root}/scope-expanded-active.summary"
grep -Fq $'\tdecision\ttask class changed development -> environment: the user added an AI workflow contract change\t-' \
  "${AGENT_FLOW_STATE_ROOT}/scope-expanded/decisions.tsv"
"${runner}" finish --task scope-expanded --plan >"${test_root}/scope-expanded-plan.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/scope-expanded-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-soc-delivery-gates' \
  "${test_root}/scope-expanded-plan.summary"

"${runner}" begin --task environment-plan --class environment --archive none \
  --initial-work-seconds 10
"${runner}" record --task environment-plan \
  --path scripts/agent-flow.c \
  --path scripts/agent-e2e.sh \
  --path .github/ai-env/contracts/agent-env-policy.json
"${runner}" status --task environment-plan >"${test_root}/environment-generation-2.summary"
grep -Fqx 'GENERATION=2' "${test_root}/environment-generation-2.summary"
"${runner}" record --task environment-plan --path scripts/agent-flow.c
"${runner}" status --task environment-plan >"${test_root}/environment-generation-3.summary"
grep -Fqx 'GENERATION=3' "${test_root}/environment-generation-3.summary"
"${runner}" finish --task environment-plan --plan >"${test_root}/environment-plan.summary"
grep -Fqx 'RESULT=PLAN' "${test_root}/environment-plan.summary"
grep -Fqx 'GATE_COUNT=3' "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_0=flow-self-test' \
  "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_1=profile-bindings' \
  "${test_root}/environment-plan.summary"
grep -Fqx 'PLANNED_GATE_2=policy-audit' \
  "${test_root}/environment-plan.summary"

"${runner}" begin --task source-artifact-hygiene-plan --class cleanup --archive none
"${runner}" record --task source-artifact-hygiene-plan \
  --path .gitignore \
  --path scripts/check-source-tree-artifact-hygiene.sh \
  --path scripts/tests/test-source-tree-artifact-hygiene.sh
"${runner}" finish --task source-artifact-hygiene-plan --plan \
  >"${test_root}/source-artifact-hygiene-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/source-artifact-hygiene-plan.summary"
grep -Fqx 'PLANNED_GATE_0=source-artifact-hygiene' \
  "${test_root}/source-artifact-hygiene-plan.summary"

"${runner}" begin --task historical-pycache-cleanup-plan \
  --class cleanup --archive none
"${runner}" record --task historical-pycache-cleanup-plan \
  --path .github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/__pycache__/checker.pyc
"${runner}" finish --task historical-pycache-cleanup-plan --plan \
  >"${test_root}/historical-pycache-cleanup-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/historical-pycache-cleanup-plan.summary"
grep -Fqx 'PLANNED_GATE_0=source-artifact-hygiene' \
  "${test_root}/historical-pycache-cleanup-plan.summary"
if grep -Fq 'rv64-architecture-debt-current' \
     "${test_root}/historical-pycache-cleanup-plan.summary" ||
   grep -Fq 'rv64-historical-defect-current' \
     "${test_root}/historical-pycache-cleanup-plan.summary"; then
  printf '%s\n' \
    '[agent-flow-test] generated task-run artifact selected architecture receipt' >&2
  exit 1
fi

"${runner}" begin --task generated-doc-cleanup-plan \
  --class docs --archive none
"${runner}" record --task generated-doc-cleanup-plan \
  --path npc/rv64/build-report/generated-report.md
"${runner}" finish --task generated-doc-cleanup-plan --plan \
  >"${test_root}/generated-doc-cleanup-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/generated-doc-cleanup-plan.summary"
grep -Fqx 'PLANNED_GATE_0=source-artifact-hygiene' \
  "${test_root}/generated-doc-cleanup-plan.summary"

"${runner}" begin --task github-pyd-cleanup-plan \
  --class cleanup --archive none
"${runner}" record --task github-pyd-cleanup-plan \
  --path .github/task-runs/probe/extension.pyd
"${runner}" finish --task github-pyd-cleanup-plan --plan \
  >"${test_root}/github-pyd-cleanup-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/github-pyd-cleanup-plan.summary"
grep -Fqx 'PLANNED_GATE_0=source-artifact-hygiene' \
  "${test_root}/github-pyd-cleanup-plan.summary"

"${runner}" begin --task historical-retained-evidence-plan \
  --class environment --archive none
"${runner}" record --task historical-retained-evidence-plan \
  --path .github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/system-current-summary.json
"${runner}" finish --task historical-retained-evidence-plan --plan \
  >"${test_root}/historical-retained-evidence-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/historical-retained-evidence-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-architecture-debt-current' \
  "${test_root}/historical-retained-evidence-plan.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-historical-defect-current' \
  "${test_root}/historical-retained-evidence-plan.summary"

"${runner}" begin --task rv64-methodology-plan --class environment --archive none
"${runner}" record --task rv64-methodology-plan \
  --path npc/rv64/design/arch/rv64-soc-delivery-gates.tsv \
  --path npc/rv64/design/arch/rv64-soc-maturity-stages.tsv
"${runner}" finish --task rv64-methodology-plan --plan \
  >"${test_root}/rv64-methodology-plan.summary"
grep -Fqx 'GATE_COUNT=2' "${test_root}/rv64-methodology-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-soc-delivery-gates' \
  "${test_root}/rv64-methodology-plan.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-optimization-slice-selector' \
  "${test_root}/rv64-methodology-plan.summary"

"${runner}" begin --task rv64-full-core-runner-plan --class environment --archive none
"${runner}" record --task rv64-full-core-runner-plan \
  --path npc/rv64/design/arch/full-core-functional-run-policy-v1.json \
  --path npc/rv64/eval/ppa/run-full-core-current.sh \
  --path npc/rv64/eval/ppa/replay-full-core-functional-current.sh \
  --path npc/rv64/eval/ppa/tools/full_core_functional_replay.py \
  --path npc/rv64/eval/ppa/tests/test_full_core_functional_replay.py \
  --path npc/rv64/eval/ppa/tests/test_full_core_runner_entry.py \
  --path npc/rv64/eval/ppa/tests/test_functional_aggregate.py \
  --path npc/rv64/eval/ppa/tools/functional_aggregate.py \
  --path abstract-machine/am/Makefile \
  --path abstract-machine/klib/Makefile \
  --path am-kernels/benchmarks/coremark/Makefile \
  --path am-kernels/benchmarks/dhrystone/Makefile
"${runner}" finish --task rv64-full-core-runner-plan --plan \
  >"${test_root}/rv64-full-core-runner-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-full-core-runner-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
  "${test_root}/rv64-full-core-runner-plan.summary"

"${runner}" begin --task rv64-system-recert-runner-plan \
  --class environment --archive none
"${runner}" record --task rv64-system-recert-runner-plan \
  --path npc/rv64/design/arch/system-recertification-run-policy-v1.json \
  --path npc/rv64/eval/ppa/run-system-recertification-current.sh \
  --path npc/rv64/eval/ppa/tools/system_recertification_run.py \
  --path npc/rv64/eval/ppa/tests/test_system_recertification_runner.py \
  --path Linux/scripts/check-npc-systemd-guest.sh \
  --path Linux/scripts/npc_systemd_transaction_evidence.py
"${runner}" finish --task rv64-system-recert-runner-plan --plan \
  >"${test_root}/rv64-system-recert-runner-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-system-recert-runner-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-system-recertification-runner-contract' \
  "${test_root}/rv64-system-recert-runner-plan.summary"

"${runner}" begin --task rv64-mini-system-runner-plan \
  --class environment --archive none
"${runner}" record --task rv64-mini-system-runner-plan \
  --path npc/rv64/eval/ppa/run-mini-system-current.sh \
  --path npc/rv64/eval/ppa/tools/mini_system_run.py \
  --path npc/rv64/eval/ppa/tests/test_mini_system_run.py \
  --path Linux/mini-system/rv64-l2-payload.S \
  --path Linux/mini-system/rv64-l2-payload.ld \
  --path Linux/scripts/build-rv64-mini-system.sh
"${runner}" finish --task rv64-mini-system-runner-plan --plan \
  >"${test_root}/rv64-mini-system-runner-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-mini-system-runner-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-mini-system-runner-plan.summary"

"${runner}" begin --task rv64-current-simulator-cache-plan \
  --class environment --archive none
"${runner}" record --task rv64-current-simulator-cache-plan \
  --path npc/rv64/eval/ppa/build-current-simulator-cache.sh \
  --path npc/rv64/eval/ppa/rv64-simulator-source-id.sh \
  --path npc/rv64/vsrc/sim/NpcSimTop.sv \
  --path npc/rv64/csrc/dpi.c
"${runner}" finish --task rv64-current-simulator-cache-plan --plan \
  >"${test_root}/rv64-current-simulator-cache-plan.summary"
grep -Fqx 'GATE_COUNT=3' \
  "${test_root}/rv64-current-simulator-cache-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-current-simulator-cache-contract' \
  "${test_root}/rv64-current-simulator-cache-plan.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-current-simulator-cache-plan.summary"
grep -Fqx \
  'PLANNED_GATE_2=rv64-lightweight-linux-runner-contract' \
  "${test_root}/rv64-current-simulator-cache-plan.summary"

"${runner}" begin --task rv64-layer-checker-replay-plan \
  --class environment --archive none
"${runner}" record --task rv64-layer-checker-replay-plan \
  --path npc/rv64/eval/ppa/replay-layer-checker-current.sh
"${runner}" finish --task rv64-layer-checker-replay-plan --plan \
  >"${test_root}/rv64-layer-checker-replay-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/rv64-layer-checker-replay-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-layer-checker-replay-plan.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-lightweight-linux-runner-contract' \
  "${test_root}/rv64-layer-checker-replay-plan.summary"

"${runner}" begin --task rv64-layer-source-id-plan \
  --class environment --archive none
"${runner}" record --task rv64-layer-source-id-plan \
  --path npc/rv64/eval/ppa/rv64-layer-source-id.sh
"${runner}" finish --task rv64-layer-source-id-plan --plan \
  >"${test_root}/rv64-layer-source-id-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/rv64-layer-source-id-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-layer-source-id-plan.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-lightweight-linux-runner-contract' \
  "${test_root}/rv64-layer-source-id-plan.summary"

"${runner}" begin --task rv64-lightweight-linux-runner-plan \
  --class environment --archive none
"${runner}" record --task rv64-lightweight-linux-runner-plan \
  --path npc/rv64/design/arch/layered-system-signoff-policy-v1.json \
  --path npc/rv64/eval/ppa/run-lightweight-linux-current.sh \
  --path npc/rv64/eval/ppa/rv64-layer-source-id.sh \
  --path npc/rv64/eval/ppa/tools/lightweight_linux_run.py \
  --path npc/rv64/eval/ppa/tests/test_lightweight_linux_run.py \
  --path Linux/lightweight/rv64-l3-kernel.config \
  --path Linux/lightweight/rv64-l3-init.c \
  --path Linux/scripts/build-rv64-lightweight-linux.sh
"${runner}" finish --task rv64-lightweight-linux-runner-plan --plan \
  >"${test_root}/rv64-lightweight-linux-runner-plan.summary"
grep -Fqx 'GATE_COUNT=3' \
  "${test_root}/rv64-lightweight-linux-runner-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-lightweight-linux-runner-plan.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-lightweight-linux-runner-contract' \
  "${test_root}/rv64-lightweight-linux-runner-plan.summary"
grep -Fqx \
  'PLANNED_GATE_2=rv64-layered-system-signoff-current' \
  "${test_root}/rv64-lightweight-linux-runner-plan.summary"

"${runner}" begin --task rv64-layered-system-signoff-plan \
  --class environment --archive none
"${runner}" record --task rv64-layered-system-signoff-plan \
  --path npc/rv64/eval/ppa/tools/layered_system_signoff.py \
  --path npc/rv64/eval/ppa/tests/test_layered_system_signoff.py \
  --path npc/rv64/eval/ppa/schemas/layered-system-signoff-current-v1.schema.json \
  --path npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json
"${runner}" finish --task rv64-layered-system-signoff-plan --plan \
  >"${test_root}/rv64-layered-system-signoff-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/rv64-layered-system-signoff-plan.summary"
grep -Fqx \
  'PLANNED_GATE_0=rv64-layered-system-signoff-current' \
  "${test_root}/rv64-layered-system-signoff-plan.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-optimization-slice-selector' \
  "${test_root}/rv64-layered-system-signoff-plan.summary"

full_core_dependency_paths=(
  abstract-machine/Makefile
  abstract-machine/am/Makefile
  abstract-machine/klib/Makefile
  abstract-machine/scripts/riscv64-npc.mk
  abstract-machine/scripts/platform/npc.mk
  am-kernels/benchmarks/coremark/Makefile
  am-kernels/benchmarks/dhrystone/Makefile
  am-kernels/tests/cpu-tests/Makefile
  nemu/Makefile
  npc/rv64/Makefile
)
full_core_dependency_index=0
for full_core_dependency_path in "${full_core_dependency_paths[@]}"; do
  full_core_dependency_task="rv64-full-core-dependency-${full_core_dependency_index}"
  "${runner}" begin --task "${full_core_dependency_task}" \
    --class environment --archive none
  "${runner}" record --task "${full_core_dependency_task}" \
    --path "${full_core_dependency_path}"
  "${runner}" finish --task "${full_core_dependency_task}" --plan \
    >"${test_root}/${full_core_dependency_task}.summary"
  grep -Fqx 'GATE_COUNT=1' \
    "${test_root}/${full_core_dependency_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
    "${test_root}/${full_core_dependency_task}.summary"
  full_core_dependency_index=$((full_core_dependency_index + 1))
done

"${runner}" begin --task rv64-arch-stable-plan --class environment --archive none
"${runner}" record --task rv64-arch-stable-plan \
  --path npc/rv64/eval/ppa/tools/arch_stable_freeze.py \
  --path npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py \
  --path npc/rv64/eval/ppa/schemas/arch-stable-independent-review-v1.schema.json
"${runner}" finish --task rv64-arch-stable-plan --plan \
  >"${test_root}/rv64-arch-stable-plan.summary"
grep -Fqx 'GATE_COUNT=2' "${test_root}/rv64-arch-stable-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
  "${test_root}/rv64-arch-stable-plan.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-arch-stable-checker-contract' \
  "${test_root}/rv64-arch-stable-plan.summary"

"${runner}" begin --task rv64-arch-stable-current-plan \
  --class environment --archive none
"${runner}" record --task rv64-arch-stable-current-plan \
  --path npc/rv64/eval/ppa/evidence/arch-stable-independent-review-current.json
"${runner}" finish --task rv64-arch-stable-current-plan --plan \
  >"${test_root}/rv64-arch-stable-current-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-arch-stable-current-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-arch-stable-current' \
  "${test_root}/rv64-arch-stable-current-plan.summary"

"${runner}" begin --task rv64-owner-timing-fast-plan --class development --archive none
"${runner}" record --task rv64-owner-timing-fast-plan \
  --path npc/rv64/eval/ppa/instrumentation/owner_timing_collector.cpp \
  --path npc/rv64/eval/ppa/replay-owner-timing-link.sh \
  --path npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh \
  --path npc/rv64/eval/ppa/replay-owner-timing-invalid-probe.sh \
  --path npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py \
  --path npc/rv64/eval/ppa/tests/test_owner_timing_workload_ab.py
"${runner}" finish --task rv64-owner-timing-fast-plan --plan \
  >"${test_root}/rv64-owner-timing-fast-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/rv64-owner-timing-fast-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-owner-timing-fast' \
  "${test_root}/rv64-owner-timing-fast-plan.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-optimization-slice-selector' \
  "${test_root}/rv64-owner-timing-fast-plan.summary"

"${runner}" begin --task rv64-owner-timing-link-plan --class development --archive none
"${runner}" record --task rv64-owner-timing-link-plan \
  --path npc/rv64/eval/ppa/instrumentation/NpcOooOwnerTimingProbe.sv \
  --gate rv64-owner-timing-link
"${runner}" finish --task rv64-owner-timing-link-plan --plan \
  >"${test_root}/rv64-owner-timing-link-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-owner-timing-link-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-owner-timing-link' \
  "${test_root}/rv64-owner-timing-link-plan.summary"

"${runner}" begin --task rv64-optimization-selector-plan \
  --class environment --archive none
"${runner}" record --task rv64-optimization-selector-plan \
  --path npc/rv64/eval/ppa/tools/optimization_slice_selector.py \
  --path npc/rv64/eval/ppa/evidence/performance-baseline-current.json \
  --path npc/rv64/eval/ppa/evidence/optimization-slice-current.json
"${runner}" finish --task rv64-optimization-selector-plan --plan \
  >"${test_root}/rv64-optimization-selector-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-optimization-selector-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-optimization-slice-selector' \
  "${test_root}/rv64-optimization-selector-plan.summary"

"${runner}" begin --task rv64-memory-request-hold-fast-plan --class development --archive none
"${runner}" record --task rv64-memory-request-hold-fast-plan \
  --path npc/rv64/design/specs/ooo-memory-request-admission-hold.md \
  --path npc/rv64/testbench/scripts/run_v14r_memory_request_hold_mutation.sh \
  --path npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh
"${runner}" finish --task rv64-memory-request-hold-fast-plan --plan \
  >"${test_root}/rv64-memory-request-hold-fast-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-memory-request-hold-fast-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-memory-request-hold-fast' \
  "${test_root}/rv64-memory-request-hold-fast-plan.summary"

"${runner}" begin --task rv64-memory-request-hold-link-plan --class development --archive none
"${runner}" record --task rv64-memory-request-hold-link-plan \
  --path npc/rv64/design/specs/ooo-memory-request-admission-hold.md \
  --gate rv64-memory-request-hold-link
"${runner}" finish --task rv64-memory-request-hold-link-plan --plan \
  >"${test_root}/rv64-memory-request-hold-link-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-memory-request-hold-link-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-memory-request-hold-link' \
  "${test_root}/rv64-memory-request-hold-link-plan.summary"

"${runner}" begin --task rv64-rtl-domain-only-plan --class development --archive none
"${runner}" record --task rv64-rtl-domain-only-plan \
  --path npc/rv64/vsrc/execute/OooIntBackend.v \
  --path npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  --path npc/rv64/testbench/Makefile
"${runner}" finish --task rv64-rtl-domain-only-plan --plan \
  >"${test_root}/rv64-rtl-domain-only-plan.summary"
grep -Fqx 'GATE_COUNT=2' \
  "${test_root}/rv64-rtl-domain-only-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-terminal-collector-lane-contract' \
  "${test_root}/rv64-rtl-domain-only-plan.summary"
grep -Fqx 'PLANNED_GATE_1=rv64-memory-request-hold-fast' \
  "${test_root}/rv64-rtl-domain-only-plan.summary"
if grep -Eq 'rv64-architecture-debt-current|rv64-historical-defect-current' \
    "${test_root}/rv64-rtl-domain-only-plan.summary"; then
  printf '%s\n' '[agent-flow-test] ordinary RTL selected stale current-result gates' >&2
  exit 1
fi

debt_dependency_paths=(
  npc/rv64/design/arch/full-core-cohort-scope-v1.md
  npc/rv64/design/arch/producer-holder-semantic-coverage.json
  .github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/evidence/p0-final-2/receipt.json
  .github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/evidence/p1-direct-1/receipt.json
  .github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/rootfs-093c2380-systemd-strict-6b-v14e-a2/terminal-markers.txt
  npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json
  npc/rv64/eval/ppa/evidence/system-recertification-checker-replay-current.json
  npc/rv64/eval/ppa/evidence/system-recertification-checker-tests.log
  npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json
  npc/rv64/eval/ppa/schemas/architecture-debt-current-v2.schema.json
  npc/rv64/eval/ppa/tests/test_architecture_debt_delta_rebind.py
  npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py
  npc/rv64/eval/ppa/tools/architecture_hard_gates.py
  npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py
  npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py
  npc/rv64/testbench/scripts/run_architecture_delta_mutations.py
  npc/rv64/testbench/scripts/test_run_architecture_delta_mutations.py
  npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py
)
debt_dependency_index=0
for debt_dependency_path in "${debt_dependency_paths[@]}"; do
  debt_task="rv64-debt-dependency-${debt_dependency_index}"
  "${runner}" begin --task "${debt_task}" --class environment --archive none
  "${runner}" record --task "${debt_task}" --path "${debt_dependency_path}"
  "${runner}" finish --task "${debt_task}" --plan \
    >"${test_root}/${debt_task}.summary"
  if [[ "${debt_dependency_path}" == \
      npc/rv64/eval/ppa/tools/architecture_hard_gates.py ]]; then
    grep -Fqx 'GATE_COUNT=6' "${test_root}/${debt_task}.summary"
    grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx \
      'PLANNED_GATE_1=rv64-system-recertification-runner-contract' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx \
      'PLANNED_GATE_2=rv64-mini-system-runner-contract' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx \
      'PLANNED_GATE_3=rv64-lightweight-linux-runner-contract' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx 'PLANNED_GATE_4=rv64-architecture-debt-current' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx 'PLANNED_GATE_5=rv64-historical-defect-current' \
      "${test_root}/${debt_task}.summary"
    debt_dependency_index=$((debt_dependency_index + 1))
    continue
  fi
  if [[ "${debt_dependency_path}" == \
      npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py ]]; then
    grep -Fqx 'GATE_COUNT=2' "${test_root}/${debt_task}.summary"
    grep -Fqx \
      'PLANNED_GATE_0=rv64-system-recertification-runner-contract' \
      "${test_root}/${debt_task}.summary"
    grep -Fqx 'PLANNED_GATE_1=rv64-architecture-debt-current' \
      "${test_root}/${debt_task}.summary"
    debt_dependency_index=$((debt_dependency_index + 1))
    continue
  fi
  grep -Fqx 'PLANNED_GATE_0=rv64-architecture-debt-current' \
    "${test_root}/${debt_task}.summary"
  case "${debt_dependency_path}" in
    .github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/*|\
    npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json|\
    npc/rv64/eval/ppa/tools/architecture_hard_gates.py|\
    npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py)
      grep -Fqx 'GATE_COUNT=2' "${test_root}/${debt_task}.summary"
      grep -Fqx 'PLANNED_GATE_1=rv64-historical-defect-current' \
        "${test_root}/${debt_task}.summary"
      ;;
    *)
      grep -Fqx 'GATE_COUNT=1' "${test_root}/${debt_task}.summary"
      ;;
  esac
  debt_dependency_index=$((debt_dependency_index + 1))
done

layered_current_paths=(
  npc/rv64/eval/ppa/evidence/system-recertification-current.json
  npc/rv64/eval/ppa/tools/system_recertification_current.py
  npc/rv64/eval/ppa/tests/test_system_recertification_current.py
)
layered_current_index=0
for layered_current_path in "${layered_current_paths[@]}"; do
  layered_task="rv64-layered-current-${layered_current_index}"
  "${runner}" begin --task "${layered_task}" --class environment --archive none
  "${runner}" record --task "${layered_task}" --path "${layered_current_path}"
  "${runner}" finish --task "${layered_task}" --plan \
    >"${test_root}/${layered_task}.summary"
  grep -Fqx 'GATE_COUNT=1' "${test_root}/${layered_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-layered-system-signoff-current' \
    "${test_root}/${layered_task}.summary"
  if grep -Eq 'rv64-architecture-debt-current|rv64-historical-defect-current' \
      "${test_root}/${layered_task}.summary"; then
    printf '%s\n' '[agent-flow-test] layered current selected independent current-result gates' >&2
    exit 1
  fi
  layered_current_index=$((layered_current_index + 1))
done

historical_ledger_paths=(
  npc/rv64/design/arch/historical-defect-backfill-ledger.json
  npc/rv64/eval/ppa/schemas/historical-defect-backfill-ledger-v1.schema.json
  npc/rv64/eval/ppa/tests/test_historical_defect_backfill.py
  npc/rv64/eval/ppa/tools/historical_defect_backfill.py
)
historical_ledger_index=0
for historical_ledger_path in "${historical_ledger_paths[@]}"; do
  ledger_task="rv64-historical-ledger-${historical_ledger_index}"
  "${runner}" begin --task "${ledger_task}" --class environment --archive none
  "${runner}" record --task "${ledger_task}" --path "${historical_ledger_path}"
  "${runner}" finish --task "${ledger_task}" --plan \
    >"${test_root}/${ledger_task}.summary"
  grep -Fqx 'GATE_COUNT=1' "${test_root}/${ledger_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-historical-defect-ledger-audit' \
    "${test_root}/${ledger_task}.summary"
  historical_ledger_index=$((historical_ledger_index + 1))
done

"${runner}" begin --task rv64-terminal-lane-contract-plan --class verification --archive none
"${runner}" record --task rv64-terminal-lane-contract-plan \
  --path npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py
"${runner}" finish --task rv64-terminal-lane-contract-plan --plan \
  >"${test_root}/rv64-terminal-lane-contract-plan.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-terminal-lane-contract-plan.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-terminal-collector-lane-contract' \
  "${test_root}/rv64-terminal-lane-contract-plan.summary"

historical_current_contract_paths=(
  npc/rv64/eval/ppa/schemas/historical-defect-current-v1.schema.json
  npc/rv64/eval/ppa/tests/test_historical_defect_current.py
  npc/rv64/eval/ppa/tools/historical_defect_current.py
)
historical_current_contract_index=0
for historical_current_contract_path in "${historical_current_contract_paths[@]}"; do
  contract_task="rv64-historical-current-contract-${historical_current_contract_index}"
  "${runner}" begin --task "${contract_task}" --class environment --archive none
  "${runner}" record --task "${contract_task}" \
    --path "${historical_current_contract_path}"
  "${runner}" finish --task "${contract_task}" --plan \
    >"${test_root}/${contract_task}.summary"
  grep -Fqx 'GATE_COUNT=1' "${test_root}/${contract_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-historical-defect-current-contract' \
    "${test_root}/${contract_task}.summary"
  historical_current_contract_index=$((historical_current_contract_index + 1))
done

historical_dependency_paths=(
  .github/task-runs/2026-07-29-rv64-hist-ser-qh-younger-store-cycle/evidence/historical-reconstruction/summary.json
  .github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/evidence/stop-hold-matrix/summary.json
  .github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/checker-replay-v2-evidence.json
  .github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/evidence/focused/mutation-summary.json
  .github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/evidence/historical-exit-current/summary.json
  .github/runtime-artifacts/agent-flow/rv64-v14g-producer-owner-global-gate/v14g-delivery-current-20260803/logs/gen1-production-assert.log
  npc/rv64/eval/ppa/historical-defect-current-evidence.mk
  npc/rv64/testbench/scripts/run_historical_exit_current.py
)
historical_dependency_index=0
for historical_dependency_path in "${historical_dependency_paths[@]}"; do
  historical_task="rv64-historical-dependency-${historical_dependency_index}"
  "${runner}" begin --task "${historical_task}" --class environment --archive none
  "${runner}" record --task "${historical_task}" --path "${historical_dependency_path}"
  "${runner}" finish --task "${historical_task}" --plan \
    >"${test_root}/${historical_task}.summary"
  grep -Fqx 'GATE_COUNT=1' "${test_root}/${historical_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-historical-defect-current' \
    "${test_root}/${historical_task}.summary"
  historical_dependency_index=$((historical_dependency_index + 1))
done

"${runner}" begin --task rv64-historical-explicit --class environment --archive none
"${runner}" record --task rv64-historical-explicit \
  --gate rv64-historical-defect-current
"${runner}" finish --task rv64-historical-explicit --plan \
  >"${test_root}/rv64-historical-explicit.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-historical-explicit.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-historical-defect-current' \
  "${test_root}/rv64-historical-explicit.summary"

"${runner}" begin --task rv64-layered-system-input --class environment --archive none
"${runner}" record --task rv64-layered-system-input \
  --path npc/rv64/eval/ppa/evidence/system-recertification-current.json
"${runner}" finish --task rv64-layered-system-input --plan \
  >"${test_root}/rv64-layered-system-input.summary"
grep -Fqx 'GATE_COUNT=1' \
  "${test_root}/rv64-layered-system-input.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-layered-system-signoff-current' \
  "${test_root}/rv64-layered-system-input.summary"

"${runner}" begin --task rv64-debt-status-helper --class environment --archive none
"${runner}" record --task rv64-debt-status-helper --path scripts/task-run-status.sh
"${runner}" finish --task rv64-debt-status-helper --plan \
  >"${test_root}/rv64-debt-status-helper.summary"
grep -Fqx 'GATE_COUNT=5' "${test_root}/rv64-debt-status-helper.summary"
grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
  "${test_root}/rv64-debt-status-helper.summary"
grep -Fqx \
  'PLANNED_GATE_1=rv64-system-recertification-runner-contract' \
  "${test_root}/rv64-debt-status-helper.summary"
grep -Fqx \
  'PLANNED_GATE_2=rv64-mini-system-runner-contract' \
  "${test_root}/rv64-debt-status-helper.summary"
grep -Fqx \
  'PLANNED_GATE_3=rv64-lightweight-linux-runner-contract' \
  "${test_root}/rv64-debt-status-helper.summary"
grep -Fqx 'PLANNED_GATE_4=task-run-status-test' \
  "${test_root}/rv64-debt-status-helper.summary"

full_core_control_paths=(
  npc/rv64/eval/ppa/schemas/difftest-reference-profile-v1.schema.json
  npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh
  am-kernels/tests/cpu-tests/scripts/check_results.py
)
full_core_control_index=0
for full_core_control_path in "${full_core_control_paths[@]}"; do
  full_core_task="rv64-full-core-control-${full_core_control_index}"
  "${runner}" begin --task "${full_core_task}" --class environment --archive none
  "${runner}" record --task "${full_core_task}" --path "${full_core_control_path}"
  "${runner}" finish --task "${full_core_task}" --plan \
    >"${test_root}/${full_core_task}.summary"
  grep -Fqx 'GATE_COUNT=1' "${test_root}/${full_core_task}.summary"
  grep -Fqx 'PLANNED_GATE_0=rv64-full-core-runner-contract' \
    "${test_root}/${full_core_task}.summary"
  full_core_control_index=$((full_core_control_index + 1))
done

"${runner}" begin --task environment-advisory-target --class environment --archive none \
  --overhead-target 1
"${runner}" record --task environment-advisory-target --gate flow-observation-smoke
"${runner}" finish --task environment-advisory-target --candidate \
  >"${test_root}/environment-advisory-target-candidate.summary"
grep -Fqx 'RESULT=CANDIDATE_PASS' \
  "${test_root}/environment-advisory-target-candidate.summary"
grep -Fqx 'OVERHEAD_TARGET_PERCENT=1' \
  "${test_root}/environment-advisory-target-candidate.summary"
"${runner}" finish --task environment-advisory-target \
  >"${test_root}/environment-advisory-target-final.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/environment-advisory-target-final.summary"
grep -Fq ':reused' "${test_root}/environment-advisory-target-final.summary"

"${runner}" begin --task candidate-invalidated --class environment --archive none
"${runner}" record --task candidate-invalidated --gate flow-observation-smoke
"${runner}" finish --task candidate-invalidated --candidate \
  >"${test_root}/candidate-invalidated-candidate.summary"
grep -Fqx 'RESULT=CANDIDATE_PASS' \
  "${test_root}/candidate-invalidated-candidate.summary"
"${runner}" record --task candidate-invalidated --gate flow-observation-smoke
"${runner}" finish --task candidate-invalidated \
  >"${test_root}/candidate-invalidated-final.summary"
grep -Fqx 'RESULT=PASS' "${test_root}/candidate-invalidated-final.summary"
grep -Fqx 'GENERATION=3' "${test_root}/candidate-invalidated-final.summary"
if grep -Fq ':reused' "${test_root}/candidate-invalidated-final.summary"; then
  printf '%s\n' '[agent-flow-test] stale candidate gate result was reused' >&2
  exit 1
fi

"${runner}" begin --task invalid-path --class development --archive none
set +e
"${runner}" record --task invalid-path --path ../outside >"${test_root}/invalid-path.out" 2>&1
invalid_path_rc=$?
set -e
[[ "${invalid_path_rc}" -eq 2 ]]

test_repo="${test_root}/repo"
mkdir -p "${test_repo}"
binary="${AGENT_FLOW_BIN_DIR}/agent-flow"
"${binary}" --repo "${test_repo}" begin --task compact-archive \
  --class development --archive compact
"${binary}" --repo "${test_repo}" record --task compact-archive --path src/core.c
"${binary}" --repo "${test_repo}" evidence --task compact-archive \
  --name focused-test --status PASS
"${binary}" --repo "${test_repo}" decision --task compact-archive \
  --kind hypothesis --text 'the focused test exercises the modified data path'
"${binary}" --repo "${test_repo}" finish --task compact-archive \
  >"${test_root}/compact.summary"
compact_run=$(sed -n 's/^TASK_RUN=//p' "${test_root}/compact.summary")
[[ -f "${test_repo}/${compact_run}/agent-flow-result.md" ]]
[[ -f "${test_repo}/${compact_run}/agent-flow-changed-directories.tsv" ]]
[[ -f "${test_repo}/${compact_run}/agent-flow-decision-trace.tsv" ]]
grep -Fq 'private token-by-token reasoning' \
  "${test_repo}/${compact_run}/agent-flow-result.md"

printf '%s\n' \
  '[agent-flow-test] PASS review/analysis and ordinary docs zero gates, ROADMAP mirror stays zero-gate, explicit docs gates remain available, retained-evidence docs keep their pointers, environment-surface class protection, audited reclassification, development evidence, decision trace, compact task-run, environment and RV64 methodology/full-core/current-simulator/mini-system/lightweight-linux/system-runner/debt/historical-ledger/current-contract/current-receipt/terminal-lane gate pointers, repeated-path and candidate invalidation, advisory overhead target, and path confinement'
