#!/usr/bin/env bash

# Resume an ACT4 run whose 100 cases completed but whose receipt build failed
# because the checker/schema changed.  The original FAIL remains immutable;
# this creates a separate fail-closed replay status and never launches a guest.

set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
tool="${repo_root}/npc/rv64/eval/ppa/tools/act4_current.py"
canonical_receipt="${repo_root}/npc/rv64/eval/ppa/evidence/act4-current.json"
run_dir_arg=""
replay_input_arg=""
publish_current=0
finalized=0

usage() {
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<failed-run-id> " \
    "[--replay-input <run-dir>/evidence/act4/inputs.replay[-vN].json] " \
    "[--publish-current]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir_arg=$2
      shift 2
      ;;
    --publish-current)
      publish_current=1
      shift
      ;;
    --replay-input)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      replay_input_arg=$2
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  usage
  exit 2
fi

run_dir="${repo_root}/${run_dir_arg}"
original_status="${run_dir}/act4-current.status"
evidence_dir="${run_dir}/evidence/act4"
raw_dir="${evidence_dir}/raw"
result_path="${evidence_dir}/result.json"
before_path="${evidence_dir}/inputs.before.json"
after_path="${evidence_dir}/inputs.after.json"
replay_input_path="${evidence_dir}/inputs.replay.json"
if [[ -n "${replay_input_arg}" ]]; then
  replay_input_prefix="${run_dir_arg}/evidence/act4/"
  [[ "${replay_input_arg}" == "${replay_input_prefix}"* ]] || {
    usage
    exit 2
  }
  replay_input_basename="${replay_input_arg#"${replay_input_prefix}"}"
  [[ "${replay_input_basename}" =~ ^inputs\.replay(-v[1-9][0-9]*)?\.json$ ]] || {
    usage
    exit 2
  }
  replay_input_path="${repo_root}/${replay_input_arg}"
fi
cleanup_path="${evidence_dir}/runtime-cleanup.json"
manifest_path="${evidence_dir}/elf-manifest.txt"

[[ -d "${run_dir}" && ! -L "${run_dir}" ]] || exit 2
replay_index=1
while :; do
  replay_suffix=""
  [[ "${replay_index}" -eq 1 ]] || replay_suffix="-v${replay_index}"
  replay_status="${run_dir}/act4-current-replay${replay_suffix}.status"
  [[ -e "${replay_status}" || -L "${replay_status}" ]] || break
  replay_index=$((replay_index + 1))
done
log_prefix="${run_dir}/receipt-replay${replay_suffix}"

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${replay_status}" || exit 1
task_run_status_install_signal_traps

finalize_on_exit() {
  local command_rc=$?
  local final_rc
  trap - EXIT HUP INT TERM
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    set +e
    task_run_status_finalize "${command_rc}" 0
    final_rc=$?
    set -e
    if [[ "${command_rc}" -eq 0 ]]; then
      command_rc=${final_rc}
    fi
  fi
  exit "${command_rc}"
}
trap finalize_on_exit EXIT

task_run_status_stage "original-receipt-failure-binding"
[[ "$(<"${original_status}")" == \
   "FAIL rc=2 stage=exit-trap evidence_complete=0 cleanup_rc=0" ]] || exit 2
[[ "$(<"${raw_dir}/overall.status")" == "PASS" ]] || exit 2
[[ "$(grep -c 'done overall_rc=0$' "${run_dir}/act4-driver.log" || :)" == 1 ]] || exit 2
grep -q '^\[RV64-ACT4-CURRENT\]\[FAIL\] ACT4 receipt violates schema: 146 was expected$' \
  "${run_dir}/receipt-build.log" || exit 2
cmp -s -- "${before_path}" "${after_path}" || exit 2

build_input="${before_path}"
if [[ -f "${replay_input_path}" && ! -L "${replay_input_path}" ]]; then
  python3 -B - "${before_path}" "${replay_input_path}" <<'PY' || exit $?
import json
import pathlib
import sys

recorded = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
current = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
allowed = ("checker", "schema")
recorded_allowed = {
    key: recorded["workflow_artifacts"].pop(key) for key in allowed
}
current_allowed = {
    key: current["workflow_artifacts"].pop(key) for key in allowed
}
if recorded != current:
    raise SystemExit("ACT4 replay input drift exceeds checker/schema artifacts")
for key in allowed:
    if recorded_allowed[key]["path"] != current_allowed[key]["path"]:
        raise SystemExit(f"ACT4 replay {key} path drifted")
if recorded_allowed == current_allowed:
    raise SystemExit("ACT4 replay checker/schema did not change")
PY
  build_input="${replay_input_path}"
fi

task_run_status_stage "receipt-build-replay"
python3 -B "${tool}" build \
  --run-dir "${raw_dir}" \
  --input-before "${build_input}" \
  --input-after "${build_input}" \
  --cleanup "${cleanup_path}" \
  --execution-manifest "${manifest_path}" \
  --output "${result_path}" \
  >"${log_prefix}-build.log" 2>&1 || exit $?

task_run_status_stage "receipt-verify-replay"
python3 -B "${tool}" verify --receipt "${result_path}" \
  >"${log_prefix}-verify.log" 2>&1 || exit $?

if [[ "${publish_current}" -eq 1 ]]; then
  task_run_status_stage "current-publication-replay"
  python3 -B "${tool}" publish \
    --receipt "${result_path}" --output "${canonical_receipt}" \
    >"${log_prefix}-publication.log" 2>&1 || exit $?
fi

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0 || exit $?
finalized=1
printf '%s\n' \
  "[RV64-ACT4-RECEIPT-REPLAY][PASS] guest_rerun=0 publish=${publish_current}"
