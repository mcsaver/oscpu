#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
checker="${repo_root}/scripts/check-rv64-soc-delivery-gates.sh"
config="${repo_root}/npc/rv64/design/arch/rv64-soc-delivery-gates.tsv"
maturity="${repo_root}/npc/rv64/design/arch/rv64-soc-maturity-stages.tsv"
workflow="${repo_root}/.github/instructions/rv64-ppa-optimization-workflow.instructions.md"
makefile="${repo_root}/npc/rv64/Makefile"
flow="${repo_root}/scripts/agent-flow.c"
layered_policy="${repo_root}/npc/rv64/design/arch/layered-system-signoff-policy-v1.json"
test_root=$(mktemp -d)

cleanup() {
  local rc=$?
  case "$test_root" in
    /tmp/*) rm -rf -- "$test_root" ;;
    *) printf '[RV64-SOC-DELIVERY-GATES-TEST][FAIL] refuse cleanup outside /tmp: %s\n' "$test_root" >&2 ;;
  esac
  exit "$rc"
}
trap cleanup EXIT

expect_fail() {
  local name=$1
  shift
  if "$@" >"${test_root}/${name}.log" 2>&1; then
    printf '[RV64-SOC-DELIVERY-GATES-TEST][FAIL] negative case accepted: %s\n' "$name" >&2
    exit 1
  fi
}

require_three_tier_shape() {
  awk -F '\t' '
    NF != 9 { exit 1 }
    END { if (NR != 4) exit 1 }
  ' "$1"
}

require_seven_stage_shape() {
  awk -F '\t' '
    NF != 7 { exit 1 }
    END { if (NR != 8) exit 1 }
  ' "$1"
}

"$checker" >"${test_root}/positive.log"

awk -F '\t' '$1 != "scheduled"' "$config" >"${test_root}/missing-scheduled.tsv"
expect_fail missing-scheduled "$checker" --config "${test_root}/missing-scheduled.tsv"

cp "$config" "${test_root}/duplicate-fast.tsv"
sed -n '2p' "$config" >>"${test_root}/duplicate-fast.tsv"
expect_fail duplicate-fast "$checker" --config "${test_root}/duplicate-fast.tsv"

grep -Fv 'https://docs.riscv.org/reference/home/index.html' "$workflow" >"${test_root}/missing-riscv-source.md"
expect_fail missing-source "$checker" --workflow "${test_root}/missing-riscv-source.md"

sed 's#testbench/scripts/run_v14g_global_producer_owner_fence.py#../../.github/task-runs/history/run-focused.sh#' "$makefile" >"${test_root}/historical-v14g.mk"
expect_fail historical-v14g "$checker" --makefile "${test_root}/historical-v14g.mk"

sed 's/affected-supported-config-closure/affected-rtl-only/' "$config" >"${test_root}/missing-config-closure.tsv"
expect_fail missing-config-closure "$checker" --config "${test_root}/missing-config-closure.tsv"

sed 's/cdc-rdc-if-clock-reset-power-topology-change/cdc-rdc-if-applicable/' "$config" >"${test_root}/subjective-cdc-trigger.tsv"
expect_fail subjective-cdc-trigger "$checker" --config "${test_root}/subjective-cdc-trigger.tsv"

sed 's/frozen-commit-dirty-filelist-parameters-defines-tools-pdk-libs-macros-sdc-corners-activity-roi-workloads-elf/frozen-design-config-tools-workloads/' "$config" >"${test_root}/incomplete-candidate-identity.tsv"
expect_fail incomplete-candidate-identity "$checker" --config "${test_root}/incomplete-candidate-identity.tsv"

sed 's/checker-only-complete-frozen-input-replay/checker-replay/' "$config" >"${test_root}/weak-replay-contract.tsv"
expect_fail weak-replay-contract "$checker" --config "${test_root}/weak-replay-contract.tsv"

sed 's/contract-checker-test-evidence-traceability/contract-test-list/' "$config" \
  >"${test_root}/missing-traceability-closure.tsv"
expect_fail missing-traceability-closure "$checker" --config "${test_root}/missing-traceability-closure.tsv"

sed 's/formal-if-applicable-or-explicit-na/formal-optional/' "$config" \
  >"${test_root}/subjective-formal-scope.tsv"
expect_fail subjective-formal-scope "$checker" --config "${test_root}/subjective-formal-scope.tsv"

sed 's/\tcontract-governed\t/\tnone\t/' "$config" >"${test_root}/candidate-no-promotion-authority.tsv"
require_three_tier_shape "${test_root}/candidate-no-promotion-authority.tsv"
expect_fail candidate-no-promotion-authority "$checker" --config "${test_root}/candidate-no-promotion-authority.tsv"

sed 's/verification|longrun/verification/' "$config" >"${test_root}/scheduled-missing-longrun-class.tsv"
require_three_tier_shape "${test_root}/scheduled-missing-longrun-class.tsv"
expect_fail scheduled-missing-longrun-class "$checker" --config "${test_root}/scheduled-missing-longrun-class.tsv"

awk -F '\t' 'BEGIN { OFS = "\t" }
  $1 == "candidate" { $6 = "task-selected-domain-command" }
  { print }
' "$config" >"${test_root}/candidate-task-selected-execution.tsv"
require_three_tier_shape "${test_root}/candidate-task-selected-execution.tsv"
expect_fail candidate-task-selected-execution "$checker" --config "${test_root}/candidate-task-selected-execution.tsv"

awk -F '\t' 'BEGIN { OFS = "\t" }
  $1 == "fast" { $7 = "durable-result-log-pointer-only" }
  { print }
' "$config" >"${test_root}/fast-durable-retention.tsv"
require_three_tier_shape "${test_root}/fast-durable-retention.tsv"
expect_fail fast-durable-retention "$checker" --config "${test_root}/fast-durable-retention.tsv"

awk -F '\t' 'BEGIN { OFS = "\t" }
  $1 == "fast" {
    $9 = "same-trigger-scope-reuse;trigger-or-identity-change-refresh;scoped-expiring-waiver-only"
  }
  $1 == "scheduled" {
    $9 = "same-identity-reuse;checker-change-versioned-replay;original-result-immutable"
  }
  { print }
' "$config" >"${test_root}/cross-tier-reuse.tsv"
require_three_tier_shape "${test_root}/cross-tier-reuse.tsv"
expect_fail cross-tier-reuse "$checker" --config "${test_root}/cross-tier-reuse.tsv"

awk -F '\t' '$1 != "ARCH_STABLE"' "$maturity" >"${test_root}/missing-arch-stable.tsv"
expect_fail missing-arch-stable "$checker" --maturity "${test_root}/missing-arch-stable.tsv"

sed $'s/ARCH_STABLE\t30/ARCH_STABLE\t35/' "$maturity" \
  >"${test_root}/wrong-stage-order.tsv"
require_seven_stage_shape "${test_root}/wrong-stage-order.tsv"
expect_fail wrong-stage-order "$checker" --maturity "${test_root}/wrong-stage-order.tsv"

sed 's/arch-stable-current-cohort;ppa-unqualified/arch-stable-current-cohort;ppa-qualified/' \
  "$maturity" >"${test_root}/premature-ppa.tsv"
require_seven_stage_shape "${test_root}/premature-ppa.tsv"
expect_fail premature-ppa "$checker" --maturity "${test_root}/premature-ppa.tsv"

sed 's/design-config-tool-input-or-workflow-binding-change-reopen/design-change-reopen/' \
  "$maturity" >"${test_root}/weak-arch-stable-reopen.tsv"
require_seven_stage_shape "${test_root}/weak-arch-stable-reopen.tsv"
expect_fail weak-arch-stable-reopen "$checker" --maturity "${test_root}/weak-arch-stable-reopen.tsv"

sed 's/"current_highest_priority_layer": "L3_LIGHTWEIGHT_LINUX"/"current_highest_priority_layer": "L2_MINI_SYSTEM"/' \
  "$layered_policy" >"${test_root}/wrong-system-priority.json"
expect_fail wrong-system-priority "$checker" \
  --layered-policy "${test_root}/wrong-system-priority.json"

grep -Fv '任务分类（task class）' "$workflow" >"${test_root}/missing-orthogonal-axis.md"
expect_fail missing-orthogonal-axis "$checker" --workflow "${test_root}/missing-orthogonal-axis.md"

sed 's/arch_stable_freeze.py verify/arch_stable_freeze.py audit/' "$flow" \
  >"${test_root}/arch-stable-rerun-pointer.c"
expect_fail arch-stable-rerun-pointer "$checker" --flow "${test_root}/arch-stable-rerun-pointer.c"

sed 's/rv64-arch-stable-checker-contract/rv64-arch-stable-checker-contract-drift/' \
  "$flow" >"${test_root}/arch-stable-checker-pointer.c"
expect_fail arch-stable-checker-pointer "$checker" \
  --flow "${test_root}/arch-stable-checker-pointer.c"

sed 's/rv64-terminal-collector-lane-contract/rv64-terminal-lane-pointer-drift/' \
  "$flow" >"${test_root}/terminal-lane-pointer.c"
expect_fail terminal-lane-pointer "$checker" \
  --flow "${test_root}/terminal-lane-pointer.c"

sed 's/rv64-historical-defect-ledger-audit/rv64-historical-ledger-pointer-drift/' \
  "$flow" >"${test_root}/historical-ledger-pointer.c"
expect_fail historical-ledger-pointer "$checker" \
  --flow "${test_root}/historical-ledger-pointer.c"

sed 's/rv64-historical-defect-current-contract/rv64-historical-current-contract-drift/' \
  "$flow" >"${test_root}/historical-current-contract-pointer.c"
expect_fail historical-current-contract-pointer "$checker" \
  --flow "${test_root}/historical-current-contract-pointer.c"

sed 's/rv64-lightweight-linux-runner-contract/rv64-lightweight-linux-runner-drift/' \
  "$flow" >"${test_root}/lightweight-linux-pointer.c"
expect_fail lightweight-linux-pointer "$checker" \
  --flow "${test_root}/lightweight-linux-pointer.c"

sed 's/rv64-mini-system-runner-contract/rv64-mini-system-runner-drift/' \
  "$flow" >"${test_root}/mini-system-pointer.c"
expect_fail mini-system-pointer "$checker" \
  --flow "${test_root}/mini-system-pointer.c"

sed 's/rv64-layered-system-signoff-current/rv64-layered-system-signoff-drift/' \
  "$flow" >"${test_root}/layered-system-pointer.c"
expect_fail layered-system-pointer "$checker" \
  --flow "${test_root}/layered-system-pointer.c"

sed '/"rv64-layered-system-signoff-current"/,/^[[:space:]]*},/ s/test_system_recertification_current/test_system_recertification_disabled/' \
  "$flow" >"${test_root}/layered-system-member.c"
expect_fail layered-system-member "$checker" \
  --flow "${test_root}/layered-system-member.c"

sed '/"rv64-lightweight-linux-runner-contract"/,/^[[:space:]]*},/ s/"--validate-only"/"--validate-disabled"/' \
  "$flow" >"${test_root}/lightweight-linux-block-mode.c"
expect_fail lightweight-linux-block-mode "$checker" \
  --flow "${test_root}/lightweight-linux-block-mode.c"

sed '/"rv64-mini-system-runner-contract"/,/^[[:space:]]*},/ s/--validate-only/--validate-disabled/' \
  "$flow" >"${test_root}/mini-system-block-mode.c"
expect_fail mini-system-block-mode "$checker" \
  --flow "${test_root}/mini-system-block-mode.c"

sed '/"rv64-current-simulator-cache-contract"/,/^[[:space:]]*},/ s/--validate-only/--validate-disabled/' \
  "$flow" >"${test_root}/simulator-cache-block-mode.c"
expect_fail simulator-cache-block-mode "$checker" \
  --flow "${test_root}/simulator-cache-block-mode.c"

printf '%s\n' '[RV64-SOC-DELIVERY-GATES-TEST][PASS] positive=1 negative=33'
