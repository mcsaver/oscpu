#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
main_task=${repo_root}/.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a
di1_task=${repo_root}/.github/task-runs/2026-08-06-rv64-v15j-di1-freeze-f7a
di2_task=${repo_root}/.github/task-runs/2026-08-06-rv64-v15j-di2-freeze-f7a
ooo3_task=${repo_root}/.github/task-runs/2026-08-06-rv64-v15j-ooo3-freeze-f7a
ooo4_id=2026-08-06-rv64-v15j-ooo4-freeze-f7a
ooo4_task=${repo_root}/.github/task-runs/${ooo4_id}
status_path=${main_task}/architecture-source-resume.status
driver_log=${main_task}/evidence/architecture-source-resume.driver.log
temporary_runner=
child_pid=
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
cd -- "${repo_root}"
task_run_status_init "${status_path}"
: >"${driver_log}"

cleanup() {
  if [[ -n "${temporary_runner}" ]]; then
    case "${temporary_runner}" in
      /tmp/v8v-freeze-resume.*.sh) rm -f -- "${temporary_runner}" ;;
    esac
  fi
}

finish_on_exit() {
  local rc=$?
  cleanup
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
  printf '[ARCH-SOURCE-RESUME][START] stage=%s log=%s\n' "${stage}" "${log}" |
    tee -a "${driver_log}"
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
    printf '[ARCH-SOURCE-RESUME][FAIL] stage=%s rc=%s log=%s\n' "${stage}" "${rc}" "${log}" |
      tee -a "${driver_log}" >&2
    return "${rc}"
  fi
  printf '[ARCH-SOURCE-RESUME][PASS] stage=%s\n' "${stage}" | tee -a "${driver_log}"
}

for manifest in \
  "${di1_task}/evidence/architecture-current.json" \
  "${di2_task}/evidence/architecture-current.json"; do
  [[ -s "${manifest}" ]] || {
    printf '[ARCH-SOURCE-RESUME][FAIL] prerequisite manifest missing: %s\n' "${manifest}" >&2
    exit 2
  }
done
[[ -d "${ooo3_task}/evidence" && -d "${ooo4_task}/evidence" ]] || {
  printf '%s\n' '[ARCH-SOURCE-RESUME][FAIL] scoped OOO task roots are missing' >&2
  exit 2
}

task_run_status_stage ooo3-f2-binding
cp -- \
  "${ooo3_task}/evidence/ooo3-current/static/evidence-builder.log" \
  "${ooo3_task}/evidence/publication-failure-v1.log"
[[ ! -e "${ooo3_task}/evidence/f2-current" ]] || {
  printf '%s\n' '[ARCH-SOURCE-RESUME][FAIL] refusing existing scoped F2 binding' >&2
  exit 2
}
cp -a --reflink=auto \
  "${main_task}/evidence/f2-current" \
  "${ooo3_task}/evidence/f2-current"

temporary_runner=$(mktemp /tmp/v8v-freeze-resume.XXXXXX.sh)
(
  cd -- .github/task-runs/2026-07-21-rv64-v8v-memory-ordering
  patch --silent -p0 -o "${temporary_runner}" \
    < "${repo_root}/npc/rv64/eval/ppa/patches/v8v-memory-ordering-current.patch"
)
run_step ooo3-current "${ooo3_task}/driver-resume.log" \
  env \
  V8V_ASSET_DIR="${repo_root}/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering" \
  V8V_CURRENT_ADAPTER_PATCH="${repo_root}/npc/rv64/eval/ppa/patches/v8v-memory-ordering-current.patch" \
  V8V_CURRENT_F2_MUTATOR="${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py" \
  V8V_SCOPED_REFRESH_MODE=1 \
  V8V_EVIDENCE_DIR="${ooo3_task}/evidence/ooo3-current" \
  V8V_MUTATION_OUTPUT_DIR="${ooo3_task}/evidence/lq-mutations" \
  V8V_ARCH_MANIFEST="${ooo3_task}/evidence/architecture-current.json" \
  V8V_ARCH_LOG="${ooo3_task}/evidence/memory-ordering.log" \
  V8V_F2_EVIDENCE_DIR="${ooo3_task}/evidence/f2-current" \
  bash "${temporary_runner}"

run_step ooo4-current "${ooo4_task}/driver.log" \
  env \
  V8Y_SCOPED_REFRESH_MODE=1 \
  V8Y_TASK_RUN_ID="${ooo4_id}" \
  V8Y_ARCH_MANIFEST="${ooo4_task}/evidence/architecture-current.json" \
  V8Y_ARCH_LOG="${ooo4_task}/evidence/speculation-recovery.log" \
  V8Y_EVIDENCE_DIR="${ooo4_task}/evidence/ooo4-current" \
  V8Y_MUTATION_OUTPUT_DIR="${ooo4_task}/evidence/ooo4-mutations" \
  bash .github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/run-focused.sh

aggregate=${main_task}/evidence/architecture-current.json
aggregate_receipt=${main_task}/evidence/architecture-current-aggregate-final.json
run_step architecture-aggregate "${main_task}/evidence/architecture-current-aggregate-final.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py build \
  --repo-root "${repo_root}" \
  --input "${di1_task}/evidence/architecture-current.json" \
  --input "${di2_task}/evidence/architecture-current.json" \
  --input "${main_task}/evidence/manifests/di3.json" \
  --input "${main_task}/evidence/manifests/di4.json" \
  --input "${main_task}/evidence/manifests/di5.json" \
  --input "${main_task}/evidence/manifests/ooo1-ooo2.json" \
  --input "${ooo3_task}/evidence/architecture-current.json" \
  --input "${ooo4_task}/evidence/architecture-current.json" \
  --output "${aggregate}" \
  --receipt "${aggregate_receipt}"

run_step architecture-aggregate-verify "${main_task}/evidence/architecture-current-aggregate-verify.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py verify \
  --repo-root "${repo_root}" \
  --receipt "${aggregate_receipt}"

run_step architecture-hard-gates "${main_task}/evidence/architecture-current-verification.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  --repo-root "${repo_root}" \
  --evidence-manifest "${aggregate}" \
  --output "${main_task}/evidence/architecture-current-verification.json"

task_run_status_stage evidence-complete
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
printf '[ARCH-SOURCE-RESUME][PASS] design=f7a gates=9 source_manifest=current\n' |
  tee -a "${driver_log}"
