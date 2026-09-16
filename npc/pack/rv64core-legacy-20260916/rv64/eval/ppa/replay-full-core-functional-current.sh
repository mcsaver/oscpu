#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
runner=${repo_root}/npc/rv64/eval/ppa/replay-full-core-functional-current.sh
replay_tool=${repo_root}/npc/rv64/eval/ppa/tools/full_core_functional_replay.py
checker=${repo_root}/npc/rv64/eval/ppa/tools/functional_aggregate.py
replay_test=${repo_root}/npc/rv64/eval/ppa/tests/test_full_core_functional_replay.py
checker_test=${repo_root}/npc/rv64/eval/ppa/tests/test_functional_aggregate.py
policy=${repo_root}/npc/rv64/design/arch/full-core-functional-run-policy-v1.json
status_helper=${repo_root}/scripts/task-run-status.sh

validate_only=0
source_run_arg=
run_dir_arg=

usage() {
  cat <<'EOF'
usage:
  npc/rv64/eval/ppa/replay-full-core-functional-current.sh --validate-only
  npc/rv64/eval/ppa/replay-full-core-functional-current.sh \
    --source-run .github/task-runs/<immutable-fail-run> \
    --run-dir .github/task-runs/<new-replay-run>

Revalidates a completed current-design RV64 full-core cohort that was rejected
only because the benchmark GOOD TRAP line oracle did not accept the simulator's
module/PC-tagged terminal format.  It never starts a guest or publishes the
canonical execution binding, and it never changes the source FAIL status.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only)
      validate_only=1
      shift
      ;;
    --source-run)
      source_run_arg=${2:?--source-run requires a path}
      shift 2
      ;;
    --run-dir)
      run_dir_arg=${2:?--run-dir requires a path}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[FULL-CORE-ORACLE-REPLAY][FAIL] unknown option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

for input in "${runner}" "${replay_tool}" "${checker}" "${replay_test}" \
  "${checker_test}" "${policy}" "${status_helper}"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done

if [[ "${validate_only}" -eq 1 ]]; then
  [[ -z "${source_run_arg}" && -z "${run_dir_arg}" ]]
  bash -n "${runner}"
  python3 -B -m unittest -q \
    npc.rv64.eval.ppa.tests.test_full_core_functional_replay \
    npc.rv64.eval.ppa.tests.test_functional_aggregate
  printf '%s\n' \
    '[FULL-CORE-ORACLE-REPLAY-CONTRACT][PASS] exact-fail=1 checker-drift-only=1 guest-rerun=0 publication=0'
  exit 0
fi

for value in "${source_run_arg}" "${run_dir_arg}"; do
  if [[ ! "${value}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf '[FULL-CORE-ORACLE-REPLAY][FAIL] not a direct task-run child: %s\n' \
      "${value}" >&2
    exit 2
  fi
done
[[ "${source_run_arg}" != "${run_dir_arg}" ]]

task_runs_root=${repo_root}/.github/task-runs
source_run=${repo_root}/${source_run_arg}
run_dir=${repo_root}/${run_dir_arg}
source_functional=${source_run}/evidence/functional
source_module_result=${source_run}/evidence/module/result.json
source_execution_status=${source_run}/full-core-current.status
result_dir=${run_dir}/evidence/functional
status_path=${run_dir}/full-core-checker-replay.status

[[ -d "${task_runs_root}" && ! -L "${task_runs_root}" ]]
[[ -d "${source_run}" && ! -L "${source_run}" ]]
[[ "$(dirname -- "$(realpath -e -- "${source_run}")")" == \
   "$(realpath -e -- "${task_runs_root}")" ]]
[[ ! -e "${run_dir}" && ! -L "${run_dir}" ]]
for input in "${source_execution_status}" "${source_module_result}" \
  "${source_functional}/status.json" \
  "${source_functional}/functional-run-descriptor.json" \
  "${source_functional}/inputs.pre.json" \
  "${source_functional}/inputs.post.json"; do
  [[ -s "${input}" && ! -L "${input}" ]]
done
grep -Eq '^FAIL rc=[0-9]+ stage=evidence-complete evidence_complete=0 cleanup_rc=0$' \
  "${source_execution_status}"

mkdir -p -- "${run_dir}/evidence"
source "${status_helper}"
task_run_status_init "${status_path}"

seal_evidence() {
  local path relative manifest_sha verify_sha
  local -a files=()
  [[ -s "${result_dir}/replay-result.json" ]]
  [[ -s "${result_dir}/status.json" ]]
  while IFS= read -r -d '' path; do
    relative=${path#"${run_dir}/"}
    case "${relative}" in
      full-core-checker-replay.status|evidence-files.sha256|evidence-files.verify.log|evidence-seal.txt)
        continue
        ;;
    esac
    [[ -f "${path}" && ! -L "${path}" ]] || return 1
    files+=("${relative}")
  done < <(find "${run_dir}" -mindepth 1 -type f -print0 | LC_ALL=C sort -z)
  (( ${#files[@]} >= 10 ))
  (
    cd -- "${run_dir}"
    sha256sum -- "${files[@]}" >evidence-files.sha256
    sha256sum -c -- evidence-files.sha256 >evidence-files.verify.log
  )
  manifest_sha=$(sha256sum "${run_dir}/evidence-files.sha256" | awk '{print $1}')
  verify_sha=$(sha256sum "${run_dir}/evidence-files.verify.log" | awk '{print $1}')
  {
    printf '%s\n' 'schema=npc-rv64-final-evidence-seal-v1'
    printf 'file_count=%s\n' "${#files[@]}"
    printf 'manifest_sha256=%s\n' "${manifest_sha}"
    printf 'verification_log_sha256=%s\n' "${verify_sha}"
    printf '%s\n' 'verification=PASS'
  } >"${run_dir}/evidence-seal.txt"
  (cd -- "${run_dir}" && sha256sum -c -- evidence-files.sha256 >/dev/null)
}

finish() {
  local command_rc=$?
  local seal_rc=0
  local final_rc=0
  trap - EXIT
  set +e
  if [[ "${command_rc}" -eq 0 ]]; then
    task_run_status_stage evidence-seal
    seal_evidence
    seal_rc=$?
    if [[ "${seal_rc}" -eq 0 ]]; then
      task_run_status_mark_evidence_complete
    else
      command_rc=${seal_rc}
    fi
  fi
  task_run_status_finalize "${command_rc}" 0
  final_rc=$?
  if [[ "${final_rc}" -eq 0 ]]; then
    printf '[FULL-CORE-ORACLE-REPLAY][PASS] source=%s guest-rerun=0 publication=0\n' \
      "${source_run_arg}"
  fi
  set -e
  exit "${final_rc}"
}
trap finish EXIT
task_run_status_install_signal_traps

hash_inputs() {
  (
    cd -- "${repo_root}"
    find "${source_run_arg}/evidence/module" \
      "${source_run_arg}/evidence/functional" -type f -print0 | \
      LC_ALL=C sort -z | xargs -0 sha256sum
    sha256sum -- "${source_run_arg}/full-core-current.status" \
      npc/rv64/eval/ppa/replay-full-core-functional-current.sh \
      npc/rv64/eval/ppa/tools/full_core_functional_replay.py \
      npc/rv64/eval/ppa/tools/functional_aggregate.py \
      npc/rv64/eval/ppa/tests/test_full_core_functional_replay.py \
      npc/rv64/eval/ppa/tests/test_functional_aggregate.py \
      npc/rv64/design/arch/full-core-functional-run-policy-v1.json \
      scripts/task-run-status.sh
  )
}

task_run_status_stage source-input-binding
hash_inputs >"${run_dir}/input-hashes-before.sha256"

task_run_status_stage checker-tests
python3 -B -m unittest -q \
  npc.rv64.eval.ppa.tests.test_full_core_functional_replay \
  npc.rv64.eval.ppa.tests.test_functional_aggregate \
  >"${run_dir}/checker-tests.log" 2>&1

task_run_status_stage checker-replay
python3 -B "${replay_tool}" \
  --attempt-dir "${source_functional}" \
  --module-result "${source_module_result}" \
  --output-dir "${result_dir}" \
  >"${run_dir}/replay.log" 2>&1
[[ "$(grep -Ec '^\[FULL-CORE-FUNCTIONAL-REPLAY\]\[PASS\] design_id=sha256:[0-9a-f]{64} module=[0-9]+/[0-9]+ official=177/177 am=[0-9]+/[0-9]+ checker_drift=1 guest_rerun=0$' "${run_dir}/replay.log")" == 1 ]]
[[ "$(grep -Ec '^\[FULL-CORE-FUNCTIONAL-REPLAY\]\[FAIL\] ' "${run_dir}/replay.log" || :)" == 0 ]]

python3 -B - "${result_dir}/replay-result.json" <<'PY'
import json
import sys

value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["status"] == "PASS"
assert value["claim"] == "L1_FULL_CORE_DIFFTEST_PASS_CURRENT_IDENTITY"
assert value["signoff_scope"] == "full-l1-checker-replay"
assert value["source_inputs_unchanged"] is True
assert value["live_drift_is_checker_only"] is True
assert value["original_status_unchanged"] is True
assert value["guest_rerun"] is False
assert value["published_current"] is False
assert value["counts"]["module_required"] > 0
assert value["counts"]["module_passed"] == value["counts"]["module_required"]
assert value["counts"]["official_required"] == 177
assert value["counts"]["official_passed"] == 177
assert value["counts"]["am_required"] > 0
assert value["counts"]["am_passed"] == value["counts"]["am_required"]
assert value["counts"]["difftest_mismatches"] == 0
PY

task_run_status_stage source-post-hash
hash_inputs >"${run_dir}/input-hashes-after.sha256"
cmp -s "${run_dir}/input-hashes-before.sha256" \
  "${run_dir}/input-hashes-after.sha256"

task_run_status_stage evidence-ready
