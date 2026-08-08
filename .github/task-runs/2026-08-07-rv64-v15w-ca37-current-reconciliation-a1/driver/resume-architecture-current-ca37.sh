#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
arch_id=2026-08-07-rv64-v15w-arch9-ca37-a1
di1_id=2026-08-07-rv64-v15w-di1-ca37-a1
di2_id=2026-08-07-rv64-v15w-di2-ca37-a1
di5_id=2026-08-07-rv64-v15w-di5-ca37-a1
ooo4_id=2026-08-07-rv64-v15w-ooo4-ca37-a1
arch_task=${repo_root}/.github/task-runs/${arch_id}
di1_task=${repo_root}/.github/task-runs/${di1_id}
di2_task=${repo_root}/.github/task-runs/${di2_id}
di5_task=${repo_root}/.github/task-runs/${di5_id}
ooo4_task=${repo_root}/.github/task-runs/${ooo4_id}
status_path=${arch_task}/architecture-current-resume-a1.status
driver_log=${arch_task}/resume-a1.driver.log
child_pid=
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
cd -- "${repo_root}"

for path in \
  "${di1_task}/evidence/architecture-current.json" \
  "${di2_task}/evidence/architecture-current.json" \
  "${arch_task}/evidence/manifests/di3.json" \
  "${arch_task}/evidence/manifests/di4.json" \
  "${di5_task}/evidence/architecture-current.json" \
  "${arch_task}/evidence/manifests/ooo3.json" \
  "${ooo4_task}/evidence/architecture-current.json"; do
  [[ -s "${path}" ]] || {
    printf '[ARCH-CA37-RESUME][FAIL] prerequisite manifest missing: %s\n' "${path}" >&2
    exit 2
  }
done
for path in \
  "${arch_task}/evidence/ooo1-current" \
  "${arch_task}/evidence/focused" \
  "${arch_task}/evidence/manifests/ooo1.json" \
  "${arch_task}/evidence/manifests/ooo1-ooo2-v2.json"; do
  [[ ! -e "${path}" ]] || {
    printf '[ARCH-CA37-RESUME][FAIL] refusing existing resume output: %s\n' "${path}" >&2
    exit 2
  }
done

task_run_status_init "${status_path}"
: >"${driver_log}"

finish_on_exit() {
  local rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_finalize "${rc}" 0 || true
  fi
}
trap finish_on_exit EXIT

signal_finalize() {
  local signal_name=$1
  local signal_rc=$2
  if [[ -n "${child_pid}" ]] && kill -0 "${child_pid}" 2>/dev/null; then
    kill -s "${signal_name}" -- "-${child_pid}" 2>/dev/null ||
      kill -s "${signal_name}" "${child_pid}" 2>/dev/null || true
    wait "${child_pid}" 2>/dev/null || true
  fi
  TASK_RUN_STATUS_SIGNAL=${signal_name}
  task_run_status_stage "signal-${signal_name}"
  task_run_status_finalize "${signal_rc}" 0 || true
  finalized=1
  trap - HUP INT TERM
  exit "${signal_rc}"
}
trap 'signal_finalize HUP 129' HUP
trap 'signal_finalize INT 130' INT
trap 'signal_finalize TERM 143' TERM

run_step() {
  local stage=$1
  local log=$2
  shift 2
  local rc=0
  task_run_status_stage "${stage}"
  printf '[ARCH-CA37-RESUME][START] stage=%s log=%s\n' "${stage}" "${log}" | tee -a "${driver_log}"
  mkdir -p -- "$(dirname -- "${log}")"
  setsid "$@" >"${log}" 2>&1 &
  child_pid=$!
  if wait "${child_pid}"; then
    rc=0
  else
    rc=$?
  fi
  child_pid=
  if [[ "${rc}" -ne 0 ]]; then
    printf '[ARCH-CA37-RESUME][FAIL] stage=%s rc=%s log=%s\n' "${stage}" "${rc}" "${log}" |
      tee -a "${driver_log}" >&2
    return "${rc}"
  fi
  printf '[ARCH-CA37-RESUME][PASS] stage=%s\n' "${stage}" | tee -a "${driver_log}"
}

run_step ooo1-current "${arch_task}/evidence/ooo1.driver.log" \
  env \
  V8N_SCOPED_REFRESH_MODE=1 \
  V8N_TASK_RUN_ID="${arch_id}" \
  V8N_EVIDENCE_DIR="${arch_task}/evidence/ooo1-current" \
  V8N_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  V8N_ARCH_LOG="${arch_task}/evidence/true-ooo-long-latency.log" \
  bash .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/run-focused.sh
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/ooo1.json"

run_step ooo2-current "${arch_task}/evidence/ooo2.driver.log" \
  env \
  ARCH_REFRESH_MODE=1 \
  V8M_EVIDENCE_DIR="${arch_task}/evidence/focused" \
  V8M_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  V8M_ARCH_LOG="${arch_task}/evidence/gates/selective-scheduling.log" \
  bash .github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/run-focused.sh
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/ooo1-ooo2-v2.json"

aggregate=${arch_task}/evidence/architecture-current-ca37-v2.json
aggregate_receipt=${arch_task}/evidence/architecture-current-aggregate-receipt-v2.json
run_step architecture-aggregate-v2 "${arch_task}/evidence/architecture-current-aggregate-v2.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py build \
  --repo-root "${repo_root}" \
  --input "${di1_task}/evidence/architecture-current.json" \
  --input "${di2_task}/evidence/architecture-current.json" \
  --input "${arch_task}/evidence/manifests/di3.json" \
  --input "${arch_task}/evidence/manifests/di4.json" \
  --input "${di5_task}/evidence/architecture-current.json" \
  --input "${arch_task}/evidence/manifests/ooo1-ooo2-v2.json" \
  --input "${arch_task}/evidence/manifests/ooo3.json" \
  --input "${ooo4_task}/evidence/architecture-current.json" \
  --output "${aggregate}" \
  --receipt "${aggregate_receipt}"

run_step architecture-aggregate-verify-v2 "${arch_task}/evidence/architecture-current-aggregate-verify-v2.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py verify \
  --repo-root "${repo_root}" \
  --receipt "${aggregate_receipt}"

run_step architecture-hard-gates-v2 "${arch_task}/evidence/architecture-current-verification-v2.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  --repo-root "${repo_root}" \
  --evidence-manifest "${aggregate}" \
  --output "${arch_task}/evidence/architecture-current-verification-v2.json"

task_run_status_stage evidence-complete
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
trap - EXIT
printf '[ARCH-CA37-RESUME][PASS] design=ca37 gates=9 current_manifests=9\n' | tee -a "${driver_log}"
