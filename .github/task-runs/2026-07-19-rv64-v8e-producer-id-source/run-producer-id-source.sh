#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${RUN_DIR}/../../.." && pwd)"
EVIDENCE_DIR="${RUN_DIR}/evidence/source"
NPC_HOME="${REPO_ROOT}/npc/rv64"
TB="${NPC_HOME}/testbench/tests/tb_ooo_rob.sv"
ROB="${NPC_HOME}/vsrc/writeback/OooRob.v"
ARCH_RF="${NPC_HOME}/vsrc/writeback/OooArchRegFile.v"
TRAP_MUX="${NPC_HOME}/vsrc/control/OooCsrTrapRequestMux.v"
DISPATCH="${NPC_HOME}/vsrc/rename_allocate/OooDispatchBackend.v"
DISPATCH_TB="${NPC_HOME}/testbench/tests/tb_ooo_dispatch_backend.sv"
RENAME_MAP="${NPC_HOME}/vsrc/rename_allocate/OooRenameMap.v"
FREE_LIST="${NPC_HOME}/vsrc/rename_allocate/OooFreeList.v"
BUSY_TABLE="${NPC_HOME}/vsrc/rename_allocate/OooBusyTable.v"
INT_ISSUE_SELECT="${NPC_HOME}/vsrc/scheduling/OooIntIssueSelect8.v"
INT_ISSUE_QUEUE="${NPC_HOME}/vsrc/scheduling/OooIntIssueQueue.v"
MUTATOR="${RUN_DIR}/mutate-rob-producer-id.py"
COMPLETE_MARKER="${EVIDENCE_DIR}/complete.marker"
TB_COMMON="${NPC_HOME}/testbench/common/tb_common.svh"
ROB_REUSE_RED_DIR="${REPO_ROOT}/.github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red"
ROB_REUSE_RED_RUNNER="${ROB_REUSE_RED_DIR}/run-rob-reuse-red.sh"
ROB_REUSE_RED_TB="${ROB_REUSE_RED_DIR}/tb_ooo_rob_reuse_red.sv"
ROB_REUSE_RED_README="${ROB_REUSE_RED_DIR}/README.md"
ROB_REUSE_RED_EVIDENCE="${ROB_REUSE_RED_DIR}/evidence"

mkdir -p "${EVIDENCE_DIR}"
rm -f -- "${COMPLETE_MARKER}"
work_dir="$(mktemp -d /tmp/ysyx-v8e-producer-id.XXXXXX)"
cleanup() {
  if [[ -n "${work_dir:-}" && -d "${work_dir}" &&
        "${work_dir}" == /tmp/ysyx-v8e-producer-id.* ]]; then
    rm -rf -- "${work_dir}"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8E-PRODUCER-ID-SOURCE][FAIL] %s\n' "$*" >&2
  exit 1
}

require_exact_marker() {
  local marker="$1"
  local log="$2"
  local count
  count="$(grep -Fxc "${marker}" "${log}" || true)"
  [[ "${count}" -eq 1 ]] ||
    fail "expected exactly one marker in ${log#${REPO_ROOT}/}: ${marker}"
}

reject_unexpected_failures() {
  local log="$1"
  if grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|\[TB-FAIL\]|(^|[[:space:]])ERROR:|(^|[[:space:]])FATAL:' \
      "${log}"; then
    fail "unexpected failure marker in ${log#${REPO_ROOT}/}"
  fi
}

iverilog_bin="$(command -v iverilog)"
iverilog_bin_dir="$(dirname "${iverilog_bin}")"
if [[ -x "${iverilog_bin_dir}/vvp" ]]; then
  vvp_bin="${iverilog_bin_dir}/vvp"
else
  vvp_bin="$(command -v vvp)"
fi

source_paths=(
  "${RUN_DIR}/contract.md"
  "${RUN_DIR}/run-producer-id-source.sh"
  "${MUTATOR}"
  "${NPC_HOME}/vsrc/include/define.v"
  "${NPC_HOME}/design/specs/ooo-rob.md"
  "${ROB}"
  "${DISPATCH}"
  "${TB}"
  "${DISPATCH_TB}"
  "${TB_COMMON}"
  "${ARCH_RF}"
  "${TRAP_MUX}"
  "${RENAME_MAP}"
  "${FREE_LIST}"
  "${BUSY_TABLE}"
  "${INT_ISSUE_SELECT}"
  "${INT_ISSUE_QUEUE}"
  "${ROB_REUSE_RED_RUNNER}"
  "${ROB_REUSE_RED_TB}"
  "${ROB_REUSE_RED_README}"
)
sha256sum "${source_paths[@]}" > "${EVIDENCE_DIR}/sources.pre.sha256"

compile_tb() {
  local name="$1"
  local rob_source="$2"
  shift 2
  "${iverilog_bin}" -g2012 -Wall \
    -I"${NPC_HOME}/vsrc" \
    -I"${NPC_HOME}/vsrc/include" \
    -I"${NPC_HOME}/testbench/common" \
    "$@" -s tb_ooo_rob -o "${work_dir}/${name}.vvp" \
    "${TB}" "${rob_source}" "${ARCH_RF}" "${TRAP_MUX}" \
    > "${EVIDENCE_DIR}/${name}.compile.log" 2>&1
}

compile_dispatch_tb() {
  local name="$1"
  local dispatch_source="$2"
  shift 2
  "${iverilog_bin}" -g2012 -Wall \
    -I"${NPC_HOME}/vsrc" \
    -I"${NPC_HOME}/vsrc/include" \
    -I"${NPC_HOME}/testbench/common" \
    "$@" -s tb_ooo_dispatch_backend -o "${work_dir}/${name}.vvp" \
    "${DISPATCH_TB}" "${dispatch_source}" "${RENAME_MAP}" \
    "${FREE_LIST}" "${BUSY_TABLE}" "${ROB}" \
    "${INT_ISSUE_SELECT}" "${INT_ISSUE_QUEUE}" \
    > "${EVIDENCE_DIR}/${name}.compile.log" 2>&1
}

run_positive() {
  local name="$1"
  shift
  compile_tb "${name}" "${ROB}" "$@"
  "${vvp_bin}" "${work_dir}/${name}.vvp" +V8E_SOURCE_ONLY \
    > "${EVIDENCE_DIR}/${name}.sim.log" 2>&1
  require_exact_marker \
    '[V8E-PRODUCER-ID-SOURCE-PASS] dual allocation/reset-flush handshake/stall/commit/ring-walk carriers covered' \
    "${EVIDENCE_DIR}/${name}.sim.log"
  require_exact_marker '[PASS] tb_ooo_rob_v8e_source_only' \
    "${EVIDENCE_DIR}/${name}.sim.log"
  reject_unexpected_failures "${EVIDENCE_DIR}/${name}.sim.log"
  if grep -Fq 'dangling input port' "${EVIDENCE_DIR}/${name}.compile.log"; then
    fail "${name}: focused compile has a dangling input"
  fi
}

run_positive release
run_positive ooo_assert -DOOO_ASSERT

for variant in release ooo_assert; do
  dispatch_flags=()
  if [[ "${variant}" == ooo_assert ]]; then
    dispatch_flags=(-DOOO_ASSERT)
  fi
  compile_dispatch_tb "dispatch_${variant}" "${DISPATCH}" \
    "${dispatch_flags[@]}"
  "${vvp_bin}" "${work_dir}/dispatch_${variant}.vvp" \
    > "${EVIDENCE_DIR}/dispatch_${variant}.sim.log" 2>&1
  require_exact_marker \
    '[V8E-DISPATCH-RESET-FLUSH-PASS] parent ready is fail-closed on reset and flush with presented valid' \
    "${EVIDENCE_DIR}/dispatch_${variant}.sim.log"
  require_exact_marker '[PASS] tb_ooo_dispatch_backend' \
    "${EVIDENCE_DIR}/dispatch_${variant}.sim.log"
  reject_unexpected_failures "${EVIDENCE_DIR}/dispatch_${variant}.sim.log"
  if grep -Fq 'dangling input port' \
      "${EVIDENCE_DIR}/dispatch_${variant}.compile.log"; then
    fail "dispatch_${variant}: focused compile has a dangling input"
  fi
done

compile_tb finite_wrap "${ROB}" -DOOO_ASSERT -DOOO_PRODUCER_GEN_W=1
"${vvp_bin}" "${work_dir}/finite_wrap.vvp" +V8E_FINITE_WRAP_RED \
  > "${EVIDENCE_DIR}/finite-wrap.sim.log" 2>&1
require_exact_marker \
  '[V8E-FINITE-WRAP-RED] GEN_W=1 full identity repeats while allocation remains ready; global collision fence is still absent' \
  "${EVIDENCE_DIR}/finite-wrap.sim.log"
require_exact_marker '[PASS] tb_ooo_rob_v8e_finite_wrap_red' \
  "${EVIDENCE_DIR}/finite-wrap.sim.log"
reject_unexpected_failures "${EVIDENCE_DIR}/finite-wrap.sim.log"
if grep -Fq 'dangling input port' "${EVIDENCE_DIR}/finite_wrap.compile.log"; then
  fail "finite-width compile has a dangling input"
fi

ROB_REUSE_RED_BUILD_DIR="${work_dir}/rob-reuse-red" \
  bash "${ROB_REUSE_RED_RUNNER}" \
  > "${EVIDENCE_DIR}/raw-index-reuse-expected-red.log" 2>&1
require_exact_marker \
  '[ROB-REUSE-EXPECTED-RED][PASS] release/assert=2/2 real-recovery wrap witness + positive control' \
  "${EVIDENCE_DIR}/raw-index-reuse-expected-red.log"
cp -- "${ROB_REUSE_RED_EVIDENCE}/release.sim.log" \
  "${EVIDENCE_DIR}/raw-index-release.sim.log"
cp -- "${ROB_REUSE_RED_EVIDENCE}/assert.sim.log" \
  "${EVIDENCE_DIR}/raw-index-assert.sim.log"
cp -- "${ROB_REUSE_RED_EVIDENCE}/summary.txt" \
  "${EVIDENCE_DIR}/raw-index-summary.txt"
cp -- "${ROB_REUSE_RED_EVIDENCE}/source.sha256" \
  "${EVIDENCE_DIR}/raw-index-source.sha256"
cp -- "${ROB_REUSE_RED_EVIDENCE}/expected-red.complete" \
  "${EVIDENCE_DIR}/raw-index-expected-red.complete"
for variant in release assert; do
  raw_log="${EVIDENCE_DIR}/raw-index-${variant}.sim.log"
  require_exact_marker \
    '[ROB-REUSE-RED][PASS] expected_current_red=1 positive_control=1 branch_recovery=1 slot_wrap=1' \
    "${raw_log}"
  [[ "$(grep -Fc '[ROB-REUSE-RED][WITNESS]' "${raw_log}" || true)" -eq 1 ]] ||
    fail "${variant}: raw-index witness count drift"
  [[ "$(grep -Fc '[ROB-REUSE-RED][POSITIVE]' "${raw_log}" || true)" -eq 1 ]] ||
    fail "${variant}: raw-index positive-control count drift"
  reject_unexpected_failures "${raw_log}"
done

mutations=(
  'dispatch0_no_store|v8e live head producer id'
  'flush_resets_generation|v8e flush preserves generation source'
  'lane1_alias_lane0|v8e first lane1 producer id'
  'dispatch0_drop_generation|v8e flush preserves generation source'
  'dispatch0_swapped_fields|v8e third allocation producer id'
  'valid_without_fire|v8e rejected valid does not advance generation'
  'reset_generation_zero|v8e first lane0 producer id'
  'commit1_alias_commit0|v8e commit1 carrier matches second live slot'
  'walk1_alias_walk0|v8e walk1 carrier matches next-youngest slot'
  'ready_ignores_flush|v8e flush blocks presented lane0 allocation'
  'commit_clears_generation|v8e real-walk old slot generation preserved by commit'
  'recovery_clears_generation|v8e real-walk new slot generation preserved by recovery'
)
: > "${EVIDENCE_DIR}/mutation-summary.log"
for item in "${mutations[@]}"; do
  mutation="${item%%|*}"
  target="${item#*|}"
  mutated_rob="${work_dir}/OooRob-${mutation}.v"
  python3 "${MUTATOR}" "${mutation}" "${ROB}" "${mutated_rob}" \
    > "${EVIDENCE_DIR}/mutation-${mutation}.mutator.log"
  compile_tb "mutation-${mutation}" "${mutated_rob}" -DOOO_ASSERT
  set +e
  "${vvp_bin}" "${work_dir}/mutation-${mutation}.vvp" +V8E_SOURCE_ONLY \
    > "${EVIDENCE_DIR}/mutation-${mutation}.sim.log" 2>&1
  sim_rc=$?
  set -e
  [[ "${sim_rc}" -ne 0 ]] ||
    fail "mutation ${mutation}: simulation unexpectedly succeeded"
  grep -Fq "[CHECK-FAIL] ${target}" \
    "${EVIDENCE_DIR}/mutation-${mutation}.sim.log" ||
    fail "mutation ${mutation}: target consequence was not observed"
  printf '[V8E-MUTATION][PASS] %s target=%s\n' "${mutation}" "${target}" \
    >> "${EVIDENCE_DIR}/mutation-summary.log"
done

parent_mutation='parent_ready_ignores_reset_flush'
mutated_dispatch="${work_dir}/OooDispatchBackend-${parent_mutation}.v"
python3 "${MUTATOR}" "${parent_mutation}" "${DISPATCH}" \
  "${mutated_dispatch}" \
  > "${EVIDENCE_DIR}/mutation-${parent_mutation}.mutator.log"
compile_dispatch_tb "mutation-${parent_mutation}" "${mutated_dispatch}" \
  -DOOO_ASSERT
set +e
"${vvp_bin}" "${work_dir}/mutation-${parent_mutation}.vvp" \
  > "${EVIDENCE_DIR}/mutation-${parent_mutation}.sim.log" 2>&1
parent_mutation_rc=$?
set -e
[[ "${parent_mutation_rc}" -ne 0 ]] ||
  fail "mutation ${parent_mutation}: simulation unexpectedly succeeded"
grep -Fq '[CHECK-FAIL] v8e dispatch parent reset blocks lane0' \
  "${EVIDENCE_DIR}/mutation-${parent_mutation}.sim.log" ||
  fail "mutation ${parent_mutation}: target consequence was not observed"
printf '[V8E-MUTATION][PASS] %s target=%s\n' "${parent_mutation}" \
  'v8e dispatch parent reset blocks lane0' \
  >> "${EVIDENCE_DIR}/mutation-summary.log"

[[ "$(grep -c '^\[V8E-MUTATION\]\[PASS\]' \
    "${EVIDENCE_DIR}/mutation-summary.log")" -eq 13 ]] ||
  fail "mutation inventory is incomplete"

sha256sum "${source_paths[@]}" > "${EVIDENCE_DIR}/sources.post.sha256"
cmp -s "${EVIDENCE_DIR}/sources.pre.sha256" \
       "${EVIDENCE_DIR}/sources.post.sha256" ||
  fail "workspace source drifted during runner"

{
  printf 'PRODUCER_ID_ALLOCATION_SHADOW=LOCAL_GREEN\n'
  printf 'RELEASE_SOURCE_TEST=PASS\n'
  printf 'ASSERT_SOURCE_TEST=PASS\n'
  printf 'COMPILE_SUCCESS_MUTATIONS=13/13\n'
  printf 'FINITE_WIDTH_WRAP=EXPECTED_RED\n'
  printf 'RAW_INDEX_LATE_WB=EXPECTED_RED\n'
  printf 'GLOBAL_NO_LIVE_REUSE=RED\n'
  printf 'GENERATION_SAFE_FULL_IDENTITY=RED\n'
  printf 'WRITEBACK_AUTHORIZATION=RED\n'
} > "${EVIDENCE_DIR}/summary.txt"
evidence_files=(
  "${EVIDENCE_DIR}/sources.pre.sha256"
  "${EVIDENCE_DIR}/sources.post.sha256"
  "${EVIDENCE_DIR}/release.compile.log"
  "${EVIDENCE_DIR}/release.sim.log"
  "${EVIDENCE_DIR}/ooo_assert.compile.log"
  "${EVIDENCE_DIR}/ooo_assert.sim.log"
  "${EVIDENCE_DIR}/dispatch_release.compile.log"
  "${EVIDENCE_DIR}/dispatch_release.sim.log"
  "${EVIDENCE_DIR}/dispatch_ooo_assert.compile.log"
  "${EVIDENCE_DIR}/dispatch_ooo_assert.sim.log"
  "${EVIDENCE_DIR}/finite_wrap.compile.log"
  "${EVIDENCE_DIR}/finite-wrap.sim.log"
  "${EVIDENCE_DIR}/raw-index-reuse-expected-red.log"
  "${EVIDENCE_DIR}/raw-index-release.sim.log"
  "${EVIDENCE_DIR}/raw-index-assert.sim.log"
  "${EVIDENCE_DIR}/raw-index-summary.txt"
  "${EVIDENCE_DIR}/raw-index-source.sha256"
  "${EVIDENCE_DIR}/raw-index-expected-red.complete"
  "${EVIDENCE_DIR}/mutation-summary.log"
  "${EVIDENCE_DIR}/summary.txt"
)
for item in "${mutations[@]}"; do
  mutation="${item%%|*}"
  evidence_files+=(
    "${EVIDENCE_DIR}/mutation-${mutation}.mutator.log"
    "${EVIDENCE_DIR}/mutation-${mutation}.compile.log"
    "${EVIDENCE_DIR}/mutation-${mutation}.sim.log"
  )
done
evidence_files+=(
  "${EVIDENCE_DIR}/mutation-${parent_mutation}.mutator.log"
  "${EVIDENCE_DIR}/mutation-${parent_mutation}.compile.log"
  "${EVIDENCE_DIR}/mutation-${parent_mutation}.sim.log"
)
sha256sum "${evidence_files[@]}" > "${COMPLETE_MARKER}"
printf '# [V8E-PRODUCER-ID-SOURCE][PASS] local_green=1 mutations=13/13 finite_wrap=EXPECTED_RED global_no_live_reuse=RED\n' \
  >> "${COMPLETE_MARKER}"
printf '[V8E-PRODUCER-ID-SOURCE][PASS] evidence=%s\n' \
  "${EVIDENCE_DIR#${REPO_ROOT}/}"
