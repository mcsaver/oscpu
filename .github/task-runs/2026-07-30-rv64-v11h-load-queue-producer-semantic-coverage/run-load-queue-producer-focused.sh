#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
rtl="${repo_root}/npc/rv64/vsrc/memory/OooLoadQueue.v"
tb="${repo_root}/npc/rv64/testbench/tests/tb_ooo_load_queue_producer_semantic.sv"
snapshot_tool="${repo_root}/.github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py"
evidence_tool="${repo_root}/npc/rv64/eval/ppa/tools/load_queue_producer_semantic_evidence.py"
pre_fix_dir="${run_dir}/evidence/pre-fix-prior-terminal-recovery"
attempt="${V11H_LOAD_QUEUE_ATTEMPT:-1}"
evidence_dir="${V11H_LOAD_QUEUE_EVIDENCE_DIR_OVERRIDE:-${run_dir}/evidence/load-queue-producer-attempt-${attempt}}"
status_path="${run_dir}/load-queue-producer-attempt-${attempt}.status"
test_name="tb_ooo_load_queue_producer_semantic"
base_flags=(
  -g2012
  -Wall
  "-I${repo_root}/npc/rv64/vsrc"
  "-I${repo_root}/npc/rv64/vsrc/include"
  "-I${repo_root}/npc/rv64/testbench/common"
)
iverilog_bin="$(command -v iverilog)"
vvp_bin="$(dirname "${iverilog_bin}")/vvp"
if [[ ! -x "${vvp_bin}" ]]; then
  vvp_bin="$(command -v vvp)"
fi

fail() {
  printf '[V11H-LQ-PRODUCER-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

if [[ ! "${attempt}" =~ ^[1-9][0-9]*$ ]]; then
  fail "V11H_LOAD_QUEUE_ATTEMPT must be a positive integer"
fi
if [[ -e "${evidence_dir}" ]]; then
  fail "evidence directory already exists: ${evidence_dir#${repo_root}/}"
fi
if [[ ! -d "${pre_fix_dir}" ]]; then
  fail "pre-fix reproducer evidence is missing"
fi
mkdir -p "${evidence_dir}"

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize() {
  local command_rc=$?
  local final_rc=0

  trap - EXIT
  set +e
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  exit "${final_rc}"
}
trap finalize EXIT

runner_stage() {
  task_run_status_stage "${1:?stage is required}"
}

source_paths=(
  "scripts/task-run-status.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/run-load-queue-producer-focused.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/run-current-instance-graph.sh"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/v11h-current-instance-graph-v2.status"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/runner-summary.log"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/holder-instance-graph.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/yosys-instance-graph-receipt.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/yosys-instance-graph.full.json.gz"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/yosys-instance-graph.ys"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/yosys-instance-graph.log"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/current-instance-graph-v2/producer-holder-census-audit.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/subagent-contracts/v11h-load-queue-producer-pre-review.json"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/pre-fix-prior-terminal-recovery/sources.sha256"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/pre-fix-prior-terminal-recovery/compile.log"
  ".github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/evidence/pre-fix-prior-terminal-recovery/sim.log"
  "npc/rv64/vsrc/memory/OooLoadQueue.v"
  "npc/rv64/vsrc/include/define.v"
  "npc/rv64/vsrc/filelist.mk"
  "npc/rv64/testbench/Makefile"
  "npc/rv64/testbench/common/tb_common.svh"
  "npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
  "npc/rv64/testbench/tests/tb_ooo_load_queue_producer_semantic.sv"
  "npc/rv64/eval/ppa/tools/load_queue_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tests/test_load_queue_producer_semantic_evidence.py"
  "npc/rv64/eval/ppa/tools/producer_holder_census.py"
  "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
  "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py"
  "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py"
  "npc/rv64/Makefile"
  "npc/rv64/configs/product-rtl-defaults.mk"
  "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
  "npc/rv64/design/arch/producer-holder-census.json"
  "npc/rv64/design/specs/ooo-load-queue.md"
  "npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md"
)

runner_stage "source-pre-hash"
(
  cd "${repo_root}"
  sha256sum "${source_paths[@]}"
) > "${evidence_dir}/sources.pre.sha256"
runner_stage "rtl-source-pre-binding"
python3 "${snapshot_tool}" \
  --snapshot-out "${evidence_dir}/rtl-source-binding.pre.json"
"${iverilog_bin}" -V > "${evidence_dir}/iverilog.version" 2>&1
"${vvp_bin}" -V > "${evidence_dir}/vvp.version" 2>&1

compile_image() {
  local run_path=$1
  local generation_width=$2
  local assertions=$3
  local rtl_source=$4
  local image="${run_path}/build/${test_name}.vvp"
  local flags=("${base_flags[@]}")
  local command
  mkdir -p "${run_path}/build"
  if [[ "${assertions}" == "on" ]]; then
    flags+=(-DOOO_ASSERT)
  fi
  flags+=("-DOOO_PRODUCER_GEN_W=${generation_width}")
  command=(
    "${iverilog_bin}"
    "${flags[@]}"
    -s "${test_name}"
    -o "${image}"
    "${tb}"
    "${rtl_source}"
  )
  {
    printf '[V11H-COMPILE]'
    printf ' %q' "${command[@]}"
    printf '\n'
  } > "${run_path}/compile.log"
  set +e
  "${command[@]}" >> "${run_path}/compile.log" 2>&1
  local compile_rc=$?
  set -e
  printf '%s\n' "${compile_rc}" > "${run_path}/compile.rc"
  return "${compile_rc}"
}

simulate_image() {
  local run_path=$1
  local mutation_mode=$2
  local image="${run_path}/build/${test_name}.vvp"
  local args=()
  case "${mutation_mode}" in
    off) ;;
    on) args+=(+V11H_MUTATION_NEGATIVE) ;;
    pid-known-assertion)
      args+=(+V11H_PID_KNOWN_ASSERTION_PROBE)
      ;;
    *) fail "unknown simulation mode: ${mutation_mode}" ;;
  esac
  set +e
  "${vvp_bin}" "${image}" "${args[@]}" \
    > "${run_path}/sim.log" 2>&1
  local sim_rc=$?
  set -e
  printf '%s\n' "${sim_rc}" > "${run_path}/sim.rc"
  return "${sim_rc}"
}

run_positive() {
  local profile=$1
  local generation_width=$2
  local assertions=$3
  local profile_dir="${evidence_dir}/profiles/${profile}"
  mkdir -p "${profile_dir}"
  compile_image \
    "${profile_dir}" "${generation_width}" "${assertions}" "${rtl}" ||
    fail "positive profile did not compile: ${profile}"
  simulate_image "${profile_dir}" off ||
    fail "positive profile did not pass: ${profile}"
}

run_positive assert-g1 1 on
run_positive release-g1 1 off
run_positive assert-g4 4 on
run_positive release-g4 4 off

runner_stage "raw-q-pid-knownness-assertion"
assertion_probe_dir="${evidence_dir}/assertion-probes/producer-id-known-g4"
mkdir -p "${assertion_probe_dir}"
compile_image "${assertion_probe_dir}" 4 on "${rtl}" ||
  fail "raw-Q PID knownness assertion probe did not compile"
if simulate_image "${assertion_probe_dir}" pid-known-assertion; then
  fail "raw-Q PID knownness assertion probe unexpectedly passed"
fi
grep -q '\[V11H-LQ-PID-KNOWN\]' "${assertion_probe_dir}/sim.log" ||
  fail "raw-Q PID knownness assertion marker was not observed"
if grep -q '\[V11H-LQ-PID-KNOWN-PROBE\]\[FAIL\]' \
  "${assertion_probe_dir}/sim.log"; then
  fail "raw-Q PID knownness assertion probe fell through"
fi

mutation_cases=(
  alloc0-generation-zero
  alloc1-uses-alloc0-pid
  alloc0-pid-x
  alloc1-pid-x
  slot-reuse-keeps-old-pid
  issue-full-pid-index-only
  launch-full-pid-index-only
  query-full-pid-index-only
  response-full-pid-index-only
  completion-full-pid-index-only
  terminal-full-pid-index-only
  release-full-pid-index-only
  terminal-not-recorded
  terminal-seen-x
  recovery-ignores-prior-terminal
  normal-terminal-clears-valid
  killed-terminal-keeps-valid
  release-keeps-valid
  launched-recovery-drops-entry
  recovery-keeps-cleared-entry
  selective-includes-boundary
  same-edge-launch-ignored
  same-edge-completion-ignored
  same-edge-terminal-ignored
  dual-alloc-same-slot
  dual-query-same-pid-bypass
  issue-terminal-gate-removed
  query-terminal-gate-removed
  response-terminal-gate-removed
  release-before-completion
  alloc-borrows-same-edge-release
)
for case in "${mutation_cases[@]}"; do
  runner_stage "mutation-${case}"
  case_dir="${evidence_dir}/mutations/${case}"
  mkdir -p "${case_dir}"
  python3 "${evidence_tool}" mutate \
    --case "${case}" \
    --input "${rtl}" \
    --output "${case_dir}/OooLoadQueue.v" \
    --receipt "${case_dir}/mutator.json" \
    > "${case_dir}/mutator.log"
  for generation_width in 1 4; do
    mutation_dir="${case_dir}/g${generation_width}"
    mkdir -p "${mutation_dir}"
    compile_image \
      "${mutation_dir}" \
      "${generation_width}" \
      off \
      "${case_dir}/OooLoadQueue.v" ||
      fail "RTL variant did not compile: ${case}/g${generation_width}"
    if simulate_image "${mutation_dir}" on; then
      fail "RTL variant unexpectedly passed: ${case}/g${generation_width}"
    fi
    grep -q '\[V11H-LQ-PRODUCER-ORACLE\]\[FAIL\]' \
      "${mutation_dir}/sim.log" ||
      fail "RTL variant lacked independent oracle marker: ${case}/g${generation_width}"
  done
done

runner_stage "evidence-tool-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_load_queue_producer_semantic_evidence \
  > "${evidence_dir}/evidence-tool-unit.log" 2>&1

runner_stage "source-post-hash"
(
  cd "${repo_root}"
  sha256sum "${source_paths[@]}"
) > "${evidence_dir}/sources.post.sha256"
cmp -s \
  "${evidence_dir}/sources.pre.sha256" \
  "${evidence_dir}/sources.post.sha256" ||
  fail "focused source set changed during execution"
python3 "${snapshot_tool}" \
  --snapshot-out "${evidence_dir}/rtl-source-binding.post.json"
cmp -s \
  "${evidence_dir}/rtl-source-binding.pre.json" \
  "${evidence_dir}/rtl-source-binding.post.json" ||
  fail "full RTL source set changed during execution"

runner_stage "summary-build"
python3 "${evidence_tool}" build \
  --root "${repo_root}" \
  --evidence-dir "${evidence_dir}" \
  --pre-fix-dir "${pre_fix_dir}" \
  --output "${evidence_dir}/summary.json"
runner_stage "semantic-ledger-unit"
python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_producer_holder_semantic_coverage \
  > "${evidence_dir}/semantic-ledger-unit.log" 2>&1

runner_stage "publish-summary"
printf '%s\n' \
  "[V11H-LQ-PRODUCER-RUNNER][PASS] attempt=${attempt} profiles=4 assertion_probe=1 mutations=31x2" \
  "[V11H-LQ-PRODUCER-RUNNER][PASS] current_instance_graph=PASS semantic_ledger_unit=PASS" \
  "[V11H-LQ-PRODUCER-RUNNER][BOUNDARY] load-queue producer semantics only; whole architecture remains RED and PPA remains UNPROMOTED" \
  >"${evidence_dir}/runner-summary.log"
task_run_status_mark_evidence_complete
cat "${evidence_dir}/runner-summary.log"
