#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
npc_home="${repo_root}/npc/rv64"
attempt="${V10C_ATTEMPT:-1}"
start_stage="${V10C_START_STAGE:-fdg-arch-trap}"
status_path="${V10C_REPLAY_STATUS_PATH_OVERRIDE:-${run_dir}/replay.status}"
task_status_path="${V10C_TASK_STATUS_PATH_OVERRIDE:-${run_dir}/task-run.status}"
status_test_signal="${V10C_STATUS_TEST_SIGNAL:-}"
status_test_point="${V10C_STATUS_TEST_POINT:-}"
v9o_dir="${repo_root}/.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design"
v9r_dir="${repo_root}/.github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff"
v9l_dir="${repo_root}/.github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design"

write_status() {
  local state="$1"
  local stage="$2"
  local detail="$3"
  local status_tmp="${status_path}.tmp.$$"
  printf 'state=%s\nstage=%s\ndetail=%s\n' \
    "${state}" "${stage}" "${detail}" > "${status_tmp}"
  mv -f -- "${status_tmp}" "${status_path}"
}

on_exit() {
  local rc=$?
  local cleanup_rc=0
  local final_rc
  local signal_detail=""

  trap - EXIT HUP INT TERM
  set +e
  if [[ "${TASK_RUN_STATUS_SIGNAL}" != "none" ]]; then
    signal_detail=";signal=${TASK_RUN_STATUS_SIGNAL}"
  fi
  if [[ ${rc} -ne 0 ]]; then
    write_status "FAIL" "${active_stage:-initialization}" \
      "rc=${rc};evidence_complete=${TASK_RUN_STATUS_EVIDENCE_COMPLETE};cleanup_rc=${cleanup_rc}${signal_detail}"
  fi
  task_run_status_finalize "${rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}

status_test_maybe_signal() {
  local point="${1:?status test point is required}"

  [[ -n "${status_test_signal}" ]] || return 0
  if [[ ! "${status_test_signal}" =~ ^(HUP|INT|TERM)$ ]] ||
     [[ ! "${status_test_point}" =~ ^(pre-init|post-init|active-stage)$ ]]; then
    printf '[V10C-REPLAY][FAIL] invalid status self-test signal=%s point=%s\n' \
      "${status_test_signal}" "${status_test_point}" >&2
    exit 2
  fi
  [[ "${status_test_point}" == "${point}" ]] || return 0

  active_stage="status-test-${point}"
  task_run_status_stage "${active_stage}"
  printf '[V10C-STATUS-SELFTEST][SIGNAL] point=%s signal=%s\n' \
    "${point}" "${status_test_signal}"
  kill -s "${status_test_signal}" "$$"
  printf '[V10C-STATUS-SELFTEST][FAIL] signal handler returned\n' >&2
  exit 99
}

# Long-running replay status is fail-closed: an explicit evidence-complete bit
# is the only path to PASS, and every asynchronous stop records its signal.
source "${repo_root}/scripts/task-run-status.sh"
active_stage="initialization"
# Seed the helper state before installing traps so a signal immediately after
# trap installation can already publish both standard and detailed FAIL.
TASK_RUN_STATUS_PATH="${task_status_path}"
TASK_RUN_STATUS_STAGE="${active_stage}"
TASK_RUN_STATUS_SIGNAL="none"
TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
trap on_exit EXIT
task_run_status_install_signal_traps
status_test_maybe_signal "pre-init"
task_run_status_init "${task_status_path}"
write_status "RUNNING" "${active_stage}" "runner-initialized"
status_test_maybe_signal "post-init"

if [[ ! "${attempt}" =~ ^[1-9][0-9]*$ ]]; then
  printf '[V10C-REPLAY][FAIL] invalid V10C_ATTEMPT=%s\n' "${attempt}" >&2
  exit 2
fi
if [[ "${attempt}" == "1" ]]; then
  default_evidence_dir="${run_dir}/stage-logs"
  default_driver_log="${run_dir}/replay-driver.log"
else
  default_evidence_dir="${run_dir}/stage-logs/attempt-${attempt}"
  default_driver_log="${run_dir}/replay-attempt-${attempt}.log"
fi
evidence_dir="${V10C_EVIDENCE_DIR_OVERRIDE:-${default_evidence_dir}}"
driver_log="${V10C_DRIVER_LOG_OVERRIDE:-${default_driver_log}}"

mkdir -p "${evidence_dir}"
start_seen=0

rtl_design_id() {
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

print(f"sha256:{architecture.rtl_binding(root)[0]}")
PY
}

run_stage() {
  active_stage="$1"
  shift
  if [[ ${start_seen} -eq 0 ]]; then
    if [[ "${active_stage}" != "${start_stage}" ]]; then
      printf '[V10C-REPLAY][SKIP] stage=%s resume_before=%s\n' \
        "${active_stage}" "${start_stage}"
      return 0
    fi
    start_seen=1
  fi
  task_run_status_stage "${active_stage}"
  write_status "RUNNING" "${active_stage}" "command-start"
  status_test_maybe_signal "active-stage"
  printf '[V10C-REPLAY][START] stage=%s\n' "${active_stage}"
  if "$@" > "${evidence_dir}/${active_stage}.log" 2>&1; then
    printf '[V10C-REPLAY][PASS] stage=%s\n' "${active_stage}"
  else
    local rc=$?
    tail -n 120 "${evidence_dir}/${active_stage}.log" || true
    printf '[V10C-REPLAY][FAIL] stage=%s rc=%s\n' \
      "${active_stage}" "${rc}" >&2
    return "${rc}"
  fi
}

exec > >(tee "${driver_log}") 2>&1

# Publication order is a fail-closed preflight for every full or resumed
# attempt.  It intentionally bypasses start_stage so a resume cannot publish
# currentness from a runner whose index verification moved or disappeared.
active_stage="replay-stage-order-contract"
task_run_status_stage "${active_stage}"
write_status "RUNNING" "${active_stage}" "command-start"
printf '[V10C-REPLAY][START] stage=%s\n' "${active_stage}"
if python3 "${run_dir}/test-runner-stage-order.py" \
    > "${evidence_dir}/${active_stage}.log" 2>&1; then
  cat "${evidence_dir}/${active_stage}.log"
  printf '[V10C-REPLAY][PASS] stage=%s\n' "${active_stage}"
else
  rc=$?
  tail -n 120 "${evidence_dir}/${active_stage}.log" || true
  printf '[V10C-REPLAY][FAIL] stage=%s rc=%s\n' \
    "${active_stage}" "${rc}" >&2
  exit "${rc}"
fi

design_id_before="$(rtl_design_id)"
printf '[V10C-REPLAY][START] attempt=%s start_stage=%s design_id=%s\n' \
  "${attempt}" "${start_stage}" "${design_id_before}"

# P0 closed-contract evidence.
run_stage fdg-arch-trap \
  make -C "${npc_home}" check-fdg-arch-trap
run_stage xret-current-mode \
  make -C "${npc_home}" check-xret-current-mode
run_stage memory-issue-lifecycle \
  make -C "${npc_home}" check-memory-issue-lifecycle
run_stage ifu-axi-flush-drain \
  make -C "${npc_home}" check-ifu-axi-flush-drain
run_stage ifu-fetch-provenance \
  make -C "${npc_home}" check-ifu-fetch-provenance
run_stage ifu-access \
  make -C "${npc_home}" check-ifu-access
run_stage ifu-tval \
  make -C "${npc_home}" check-ifu-tval
run_stage ptw-pmp \
  make -C "${npc_home}" check-ptw-pmp
run_stage instret-retirement \
  make -C "${npc_home}" check-instret-retirement

# Remaining stale P1 closed-contract evidence.
run_stage fence-ordering \
  make -C "${npc_home}" check-fence-ordering
run_stage vectored-trap \
  make -C "${npc_home}" check-vectored-trap
run_stage holder-lifecycle-current \
  make -C "${npc_home}" check-global-producer-no-live-reuse
run_stage control-event-focused \
  bash "${v9o_dir}/run-focused.sh"
run_stage control-event-config \
  bash "${v9o_dir}/run-v9o-config-variants.sh"
run_stage control-event-mutations \
  python3 "${v9o_dir}/run-control-event-rtl-mutations.py" \
    --root "${repo_root}" \
    --output "${v9o_dir}/mutations/summary.json"
run_stage control-event-module-aggregate \
  bash "${v9o_dir}/run-module-aggregate.sh"
run_stage functional-aggregate-current \
  bash "${v9l_dir}/run-focused.sh"
run_stage control-event-architecture \
  bash "${v9o_dir}/refresh-architecture-evidence.sh"
# A production RTL change makes the prior architecture manifest stale.
# Publish the nine-gate current-design result before the candidate updater
# verifies it, while still refreshing the candidate before its GAP audit.
run_stage candidate-and-census-current \
  python3 "${v9l_dir}/update-current-arch-stable-candidate.py"
# The candidate updater publishes the final current-design holder census.
# V9R binds that source by hash, so its evidence must be regenerated after
# the census write and before the control-event evidence index is built.
run_stage control-event-sq-retry \
  bash "${v9r_dir}/run-v9r-evidence.sh"
run_stage control-event-gap-boundary \
  bash "${v9o_dir}/run-arch-stable-boundary.sh"
run_stage control-event-index \
  python3 "${v9o_dir}/build-evidence-index.py"
run_stage control-event-index-verify \
  python3 "${v9o_dir}/build-evidence-index.py" --verify

run_stage debt-ledger-current \
  python3 "${v9l_dir}/update-current-debt-ledger.py"
run_stage closed-evidence-currentness \
  python3 "${run_dir}/audit-current-debt-evidence.py"

if [[ ${start_seen} -ne 1 ]]; then
  active_stage="resume-validation"
  task_run_status_stage "${active_stage}"
  printf '[V10C-REPLAY][FAIL] unknown V10C_START_STAGE=%s\n' \
    "${start_stage}" >&2
  exit 2
fi

design_id_after="$(rtl_design_id)"
if [[ "${design_id_after}" != "${design_id_before}" ]]; then
  printf '[V10C-REPLAY][FAIL] RTL design-id changed before=%s after=%s\n' \
    "${design_id_before}" "${design_id_after}" >&2
  exit 1
fi
serialize_status="$(
  python3 - "${repo_root}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
ledger = json.loads(
    (root / "npc/rv64/design/arch/architecture-debt-ledger.json").read_text(
        encoding="utf-8"
    )
)
matches = [
    entry.get("status")
    for entry in ledger.get("entries", [])
    if isinstance(entry, dict) and entry.get("id") == "SERIALIZE-G1"
]
if len(matches) != 1 or not isinstance(matches[0], str):
    raise SystemExit("SERIALIZE-G1 ledger status is not unique")
print(matches[0])
PY
)"

active_stage="complete"
task_run_status_stage "${active_stage}"
task_run_status_mark_evidence_complete
write_status "PASS" "complete" \
  "design_id=${design_id_after};closed_evidence=current;SERIALIZE-G1=${serialize_status}"
printf '[V10C-REPLAY][PASS] design_id=%s closed_evidence=current SERIALIZE-G1=%s\n' \
  "${design_id_after}" "${serialize_status}"
