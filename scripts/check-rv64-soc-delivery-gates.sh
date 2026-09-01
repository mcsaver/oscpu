#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="${repo_root}/npc/rv64/design/arch/rv64-soc-delivery-gates.tsv"
maturity="${repo_root}/npc/rv64/design/arch/rv64-soc-maturity-stages.tsv"
workflow="${repo_root}/.github/instructions/rv64-ppa-optimization-workflow.instructions.md"
lightweight="${repo_root}/.github/instructions/agent-lightweight-workflow.instructions.md"
makefile="${repo_root}/npc/rv64/Makefile"
flow="${repo_root}/scripts/agent-flow.c"
layered_policy="${repo_root}/npc/rv64/design/arch/layered-system-signoff-policy-v1.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      config=$2
      shift 2
      ;;
    --workflow)
      workflow=$2
      shift 2
      ;;
    --maturity)
      maturity=$2
      shift 2
      ;;
    --lightweight)
      lightweight=$2
      shift 2
      ;;
    --makefile)
      makefile=$2
      shift 2
      ;;
    --flow)
      flow=$2
      shift 2
      ;;
    --layered-policy)
      layered_policy=$2
      shift 2
      ;;
    *)
      printf '[RV64-SOC-DELIVERY-GATES][FAIL] unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

for input in "$config" "$maturity" "$workflow" "$lightweight" "$makefile" "$flow" "$layered_policy"; do
  if [[ ! -r "$input" ]]; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] missing input: %s\n' "$input" >&2
    exit 1
  fi
done

expected_header=$'tier_id\ttrigger\teligible_classes\tactivation\trequired_evidence\texecution\tretention\tpromotion_authority\tevidence_reuse_contract'
if [[ "$(sed -n '1p' "$config")" != "$expected_header" ]]; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] TSV header/schema mismatch' >&2
  exit 1
fi

awk -F '\t' '
  NR == 1 { next }
  NF != 9 { printf "invalid column count at line %d\n", NR > "/dev/stderr"; failed = 1; next }
  $1 != "fast" && $1 != "scheduled" && $1 != "candidate" {
    printf "unknown tier at line %d: %s\n", NR, $1 > "/dev/stderr"; failed = 1
  }
  seen[$1]++
  $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || $9 == "" {
    printf "empty field at line %d\n", NR > "/dev/stderr"; failed = 1
  }
  END {
    if (NR != 4) { printf "expected three tier rows\n" > "/dev/stderr"; failed = 1 }
    for (tier in seen) if (seen[tier] != 1) {
      printf "duplicate tier: %s\n", tier > "/dev/stderr"; failed = 1
    }
    if (seen["fast"] != 1 || seen["scheduled"] != 1 || seen["candidate"] != 1) {
      printf "tier inventory incomplete\n" > "/dev/stderr"; failed = 1
    }
    exit failed
  }
' "$config" || {
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] tier inventory invalid' >&2
  exit 1
}

expected_rows=(
  $'fast\tdeterministic-delivery-point\tdevelopment|verification\taffected-supported-config-closure\tcompile-elaboration-semantic-diagnostics;directed-test;assertion;known-good-control-and-expected-fail-mutation-if-oracle-changed\ttask-selected-domain-command\tbounded-result-log-pointer-only\tnone\tsame-identity-reuse;checker-change-versioned-replay;original-result-immutable'
  $'scheduled\tcalendar-or-explicit-risk\tverification|longrun\texplicit-domain-or-physical-trigger\trandom-regression;coverage;formal-if-applicable;cdc-rdc-if-clock-reset-power-topology-change;fast-synthesis-if-pipeline-gating-memory-sdc-library-tool-change\texplicit-profile\tbounded-result-log-pointer-only\tnone\tsame-trigger-scope-reuse;trigger-or-identity-change-refresh;scoped-expiring-waiver-only'
  $'candidate\tcomplete-design-point-or-release\tdevelopment|longrun|release\tpromotion-request-or-post-signoff-rtl-change\tfrozen-commit-dirty-filelist-parameters-defines-tools-pdk-libs-macros-sdc-corners-activity-roi-workloads-elf;contract-checker-test-evidence-traceability;coverage-closure-or-explicit-gap;formal-if-applicable-or-explicit-na;full-functional;architecture;sta;ppa;waiver-audit;independent-review\texplicit-profile\tdurable-result-log-pointer-only\tcontract-governed\tsemantic-change-full-rerun;checker-only-complete-frozen-input-replay;missing-terminal-hash-post-binding-rerun;original-result-immutable'
)
for expected_row in "${expected_rows[@]}"; do
  tier=${expected_row%%$'\t'*}
  if ! grep -Fqx -- "$expected_row" "$config"; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] exact tier contract drifted: %s\n' \
      "$tier" >&2
    exit 1
  fi
done

expected_maturity_header=$'stage_id\tsequence\tentry_condition\trequired_evidence\tallowed_claim\texit_authority\tinvalidation_contract'
if [[ "$(sed -n '1p' "$maturity")" != "$expected_maturity_header" ]]; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] maturity TSV header/schema mismatch' >&2
  exit 1
fi

awk -F '\t' '
  NR == 1 { next }
  NF != 7 { printf "invalid maturity column count at line %d\n", NR > "/dev/stderr"; failed = 1; next }
  $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" {
    printf "empty maturity field at line %d\n", NR > "/dev/stderr"; failed = 1
  }
  seen[$1]++
  sequence[$1] = $2
  END {
    if (NR != 8) { printf "expected seven maturity rows\n" > "/dev/stderr"; failed = 1 }
    expected["ARCH_DISCOVERY"] = 10
    expected["ARCH_CLOSED"] = 20
    expected["ARCH_STABLE"] = 30
    expected["PERF_BASELINE"] = 40
    expected["PPA_QUALIFIED"] = 50
    expected["SYSTEM_RECERTIFIED"] = 60
    expected["PROMOTABLE"] = 70
    for (stage in expected) {
      if (seen[stage] != 1 || sequence[stage] != expected[stage]) {
        printf "maturity inventory/order drifted: %s\n", stage > "/dev/stderr"
        failed = 1
      }
    }
    exit failed
  }
' "$maturity" || {
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] maturity inventory invalid' >&2
  exit 1
}

expected_maturity_rows=(
  $'ARCH_DISCOVERY\t10\tcohort-scoped-and-task-classified\tarchitecture-debt-census;falsifiable-hypotheses\tdevelopment-evidence-and-open-gaps-only\tnone\tscope-or-spec-change-refresh'
  $'ARCH_CLOSED\t20\tcurrent-design-debt-and-hard-gates-closed\tarchitecture-debt-current;historical-defect-current;di-ooo-gates;precise-recovery-memory-order\tarchitecture-contract-closed-current-design;whole-architecture-red-until-freeze-composition\tarchitecture-checkers\tproduction-or-elaboration-semantics-change-reopen'
  $'ARCH_STABLE\t30\tarch-closed-and-exact-cohort-frozen\tfull-functional;holder-static-census;semantic-coverage;dynamic-lifecycle;independent-review-receipt\tarch-stable-current-cohort;ppa-unqualified\tarch-stable-checker\tdesign-config-tool-input-or-workflow-binding-change-reopen'
  $'PERF_BASELINE\t40\tarch-stable-and-measurement-contract-frozen\tcycles;retired-instructions;cpi;ipc;instruction-count-binding;repeatability\tperformance-baseline-current-contract;no-ppa-promotion\tperformance-contract-checker\tworkload-compiler-roi-counter-or-design-change-refresh'
  $'PPA_QUALIFIED\t50\tperf-baseline-and-fresh-physical-evidence\ttiming-tier;fresh-netlist;qualified-area;qualified-power;repeatable-synth-sta\tqualified-pareto-candidate;not-promotable-before-system\tppa-promotion-checker\trtl-sdc-library-corner-activity-tool-or-seed-change-refresh'
  $'SYSTEM_RECERTIFIED\t60\tppa-qualified-and-current-layered-system-identity\tl0-directed-rtl;l1-full-core-difftest;l2-mini-system;l3-lightweight-linux;terminal-assertion-oracle-post-hash;workload-guardrail\tlayered-system-signoff-current-identity;ubuntu2204-optional-not-implied\tlayered-system-signoff-checker\tcore-device-harness-simulator-layer-input-or-execution-semantics-change-refresh'
  $'PROMOTABLE\t70\tall-prior-stages-current-and-independent-review-pass\tsame-identity-conjunction;waiver-audit;reviewer-approval\tcontract-governed-promotion\tnormative-promotion-checker\tany-upstream-identity-or-signoff-rtl-change-reopen'
)
for expected_row in "${expected_maturity_rows[@]}"; do
  stage=${expected_row%%$'\t'*}
  if ! grep -Fqx -- "$expected_row" "$maturity"; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] exact maturity contract drifted: %s\n' \
      "$stage" >&2
    exit 1
  fi
done

required_config_text=(
  'affected-supported-config-closure'
  'compile-elaboration-semantic-diagnostics'
  'known-good-control-and-expected-fail-mutation-if-oracle-changed'
  'cdc-rdc-if-clock-reset-power-topology-change'
  'fast-synthesis-if-pipeline-gating-memory-sdc-library-tool-change'
  'frozen-commit-dirty-filelist-parameters-defines-tools-pdk-libs-macros-sdc-corners-activity-roi-workloads-elf'
  'contract-checker-test-evidence-traceability'
  'coverage-closure-or-explicit-gap'
  'formal-if-applicable-or-explicit-na'
  'same-identity-reuse;checker-change-versioned-replay;original-result-immutable'
  'same-trigger-scope-reuse;trigger-or-identity-change-refresh;scoped-expiring-waiver-only'
  'semantic-change-full-rerun;checker-only-complete-frozen-input-replay;missing-terminal-hash-post-binding-rerun;original-result-immutable'
)
for marker in "${required_config_text[@]}"; do
  if ! grep -Fq -- "$marker" "$config"; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] config contract marker missing: %s\n' "$marker" >&2
    exit 1
  fi
done

required_workflow_anchors=(
  'npc/rv64/design/arch/rv64-soc-delivery-gates.tsv'
  'npc/rv64/design/arch/rv64-soc-maturity-stages.tsv'
  '任务分类（task class）'
  '执行层级（execution tier）'
  '设计成熟度（design maturity）'
  '`ARCH_DISCOVERY -> ARCH_CLOSED -> ARCH_STABLE -> PERF_BASELINE -> PPA_QUALIFIED -> SYSTEM_RECERTIFIED -> PROMOTABLE`'
  '`fast`'
  '`scheduled`'
  '`candidate`'
  'https://docs.riscv.org/reference/home/index.html'
  '版本化架构/接口合同'
  '本地明确裁掉常驻全量回归'
  '每个不可变 design/config identity'
  'clock/reset topology'
  'compile-success 负向版本触发预期 checker FAIL'
  'commit 与 dirty-state'
  'activity/ROI'
  'execution_state / terminal_state / artifact_state / assertion_state / oracle_state / replay_state'
  '原始 PASS/FAIL 状态不可改写'
  'owner、scope、rationale、expiry、compensating evidence 与 reopen trigger'
  'run-lightweight-linux-current.sh'
  '--user-authorized-full-ubuntu'
  'SYSTEM_RECERTIFIED` 保持 GAP'
)
for anchor in "${required_workflow_anchors[@]}"; do
  if ! grep -Fq -- "$anchor" "$workflow"; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] workflow invariant missing: %s\n' "$anchor" >&2
    exit 1
  fi
done

if ! grep -Fq '任务标签和工具用于帮助选择动作，不是权限系统' "$lightweight" ||
   ! grep -Fq '只读 review/analysis 可以直接读取并交付结论' "$lightweight" ||
   ! grep -Fq '不存在 workspace-wide unique shell ownership' "$lightweight" ||
   ! grep -Fq '以上全部默认 opt-in' "$lightweight"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] outcome-first lightweight contract drifted' >&2
  exit 1
fi

if ! grep -Fq '"rv64-arch-stable-current"' "$flow" ||
   ! grep -Fq '"/usr/bin/python3 -B npc/rv64/eval/ppa/tools/arch_stable_freeze.py verify "' "$flow" ||
   ! grep -Fq '"npc/rv64/eval/ppa/evidence/arch-stable-current.json --require-stable"' "$flow"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C ARCH_STABLE current-result pointer drifted' >&2
  exit 1
fi
if ! grep -Fq '"rv64-arch-stable-checker-contract"' "$flow" ||
   ! grep -Fq '"npc.rv64.eval.ppa.tests.test_arch_stable_freeze "' "$flow"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C ARCH_STABLE checker-contract pointer drifted' >&2
  exit 1
fi
if ! grep -Fq '"rv64-terminal-collector-lane-contract"' "$flow" ||
   ! grep -Fq 'npc.rv64.eval.ppa.tests.test_terminal_collector_lane_contract -v' "$flow"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C terminal lane-pair pointer drifted' >&2
  exit 1
fi
if ! grep -Fq '"rv64-historical-defect-ledger-audit"' "$flow" ||
   ! grep -Fq 'npc.rv64.eval.ppa.tests.test_historical_defect_backfill -v' "$flow" ||
   ! grep -Fq 'npc/rv64/eval/ppa/tools/historical_defect_backfill.py' "$flow"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C historical ledger-audit pointer drifted' >&2
  exit 1
fi
if ! grep -Fq '"rv64-historical-defect-current-contract"' "$flow" ||
   ! grep -Fq 'npc.rv64.eval.ppa.tests.test_historical_defect_current -v' "$flow"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C historical current-contract pointer drifted' >&2
  exit 1
fi

for marker in \
  '"current_highest_priority_layer": "L3_LIGHTWEIGHT_LINUX"' \
  '"launch_policy": "explicit-user-request-only"' \
  '"absence_blocks_default_signoff": false' \
  '"required_default_claim": "LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY"'; do
  if ! grep -Fq -- "$marker" "$layered_policy"; then
    printf '[RV64-SOC-DELIVERY-GATES][FAIL] layered system policy marker missing: %s\n' \
      "$marker" >&2
    exit 1
  fi
done
gate_initializer_block() {
  local gate_id=$1
  awk -v gate_id="${gate_id}" '
    index($0, "\"" gate_id "\"") { capture = 1 }
    capture { print }
    capture && $0 ~ /^[[:space:]]*},[[:space:]]*$/ { exit }
  ' "$flow"
}

mini_system_gate_block=$(gate_initializer_block rv64-mini-system-runner-contract)
if [[ -z "${mini_system_gate_block}" ]] ||
   ! grep -Fq 'run-mini-system-current.sh --validate-only' \
     <<<"${mini_system_gate_block}"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C mini-system runner pointer drifted' >&2
  exit 1
fi
simulator_cache_gate_block=$(
  gate_initializer_block rv64-current-simulator-cache-contract
)
if [[ -z "${simulator_cache_gate_block}" ]] ||
   ! grep -Fq 'build-current-simulator-cache.sh --validate-only' \
     <<<"${simulator_cache_gate_block}"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C simulator cache pointer drifted' >&2
  exit 1
fi
lightweight_linux_gate_block=$(
  gate_initializer_block rv64-lightweight-linux-runner-contract
)
if [[ -z "${lightweight_linux_gate_block}" ]] ||
   ! grep -Fq 'run-lightweight-linux-current.sh "' \
     <<<"${lightweight_linux_gate_block}" ||
   ! grep -Fq '"--validate-only"' <<<"${lightweight_linux_gate_block}"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C lightweight Linux runner pointer drifted' >&2
  exit 1
fi
layered_signoff_gate_block=$(
  gate_initializer_block rv64-layered-system-signoff-current
)
if [[ -z "${layered_signoff_gate_block}" ]] ||
   ! grep -Fq 'test_layered_system_signoff ' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq 'test_system_recertification_current -v' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq 'layered_system_signoff.py verify ' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq 'layered-system-signoff-current.json' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq 'system_recertification_current.py ' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq -- '--root . verify --input ' \
     <<<"${layered_signoff_gate_block}" ||
   ! grep -Fq 'system-recertification-current.json' \
     <<<"${layered_signoff_gate_block}"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] C layered system current pointer drifted' >&2
  exit 1
fi

if ! grep -Fq 'V14G_GLOBAL_OWNER_FENCE_RUNNER := $(abspath testbench/scripts/run_v14g_global_producer_owner_fence.py)' "$makefile" ||
   ! grep -Fq 'check-global-producer-no-live-reuse:' "$makefile"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] current V14G entry pointer is absent' >&2
  exit 1
fi
v14g_block=$(sed -n '/^check-global-producer-no-live-reuse:/,/^$/p' "$makefile")
if grep -Fq '.github/task-runs/' <<<"$v14g_block"; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] V14G entry points at historical task-run code' >&2
  exit 1
fi
if [[ ! -r "${repo_root}/npc/rv64/testbench/scripts/run_v14g_global_producer_owner_fence.py" ||
      ! -r "${repo_root}/npc/rv64/testbench/tests/tb_ooo_int_backend_v14g_global_owner_fence.svh" ]]; then
  printf '%s\n' '[RV64-SOC-DELIVERY-GATES][FAIL] stable V14G runner/overlay is absent' >&2
  exit 1
fi

printf '%s\n' '[RV64-SOC-DELIVERY-GATES][PASS] tiers=3 maturity=7 axes=orthogonal row_semantics=exact review=zero-gate ledger=current-split lane_pairs=static-wheel reuse=identity-and-semantics-bound v14g=current-runner retention=result-log-pointers'
