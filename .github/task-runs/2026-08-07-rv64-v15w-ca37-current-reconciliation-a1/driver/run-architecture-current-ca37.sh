#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
main_task=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-ca37-current-reconciliation-a1
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
status_path=${arch_task}/architecture-current.status
driver_log=${arch_task}/driver.log
child_pid=
finalized=0
temporary_runners=()
patched_runner_path=

source "${repo_root}/scripts/task-run-status.sh"
cd -- "${repo_root}"

for task_dir in "${arch_task}" "${di1_task}" "${di2_task}" "${di5_task}" "${ooo4_task}"; do
  if [[ -e "${task_dir}" ]]; then
    printf '[ARCH-CA37][FAIL] refusing existing task directory: %s\n' "${task_dir}" >&2
    exit 2
  fi
done
mkdir -p -- \
  "${arch_task}/evidence/manifests" \
  "${di1_task}/evidence" \
  "${di2_task}/evidence" \
  "${di5_task}/evidence" \
  "${ooo4_task}/evidence"
task_run_status_init "${status_path}"
: >"${driver_log}"

cleanup() {
  local runner
  for runner in "${temporary_runners[@]}"; do
    case "${runner}" in
      /tmp/v15w-arch-ca37-*.sh) rm -f -- "${runner}" ;;
    esac
  done
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
  printf '[ARCH-CA37][START] stage=%s log=%s\n' "${stage}" "${log}" | tee -a "${driver_log}"
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
    printf '[ARCH-CA37][FAIL] stage=%s rc=%s log=%s\n' "${stage}" "${rc}" "${log}" |
      tee -a "${driver_log}" >&2
    return "${rc}"
  fi
  printf '[ARCH-CA37][PASS] stage=%s\n' "${stage}" | tee -a "${driver_log}"
}

patched_runner() {
  local stem=$1
  local asset_dir=$2
  local adapter_patch=$3
  local output
  output=$(mktemp "/tmp/v15w-arch-ca37-${stem}.XXXXXX.sh")
  temporary_runners+=("${output}")
  (
    cd -- "${asset_dir}"
    patch --silent -p0 -o "${output}" < "${adapter_patch}"
  )
  patched_runner_path=${output}
}

run_step di1-current "${di1_task}/driver.log" \
  bash .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/run-focused.sh \
  --scoped-task-run-id "${di1_id}"

run_step di2-current "${di2_task}/driver.log" \
  bash .github/task-runs/2026-07-21-rv64-v9a-width-continuity/run-focused.sh \
  --scoped-task-run-id "${di2_id}"

v8p_asset=${repo_root}/.github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners
v8p_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8p-pair-matrix-current.patch
patched_runner v8p "${v8p_asset}" "${v8p_patch}"
v8p_runner=${patched_runner_path}
run_step di3-current "${arch_task}/evidence/di3.driver.log" \
  env \
  V8P_ASSET_DIR="${v8p_asset}" \
  V8P_CURRENT_ADAPTER_PATCH="${v8p_patch}" \
  V8P_TASK_RUN_ID="${arch_id}" \
  V8P_EVIDENCE_DIR="${arch_task}/evidence/di3-current" \
  V8P_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  V8P_ARCH_LOG="${arch_task}/evidence/pair-matrix.log" \
  bash "${v8p_runner}"
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/di3.json"

v8o_asset=${repo_root}/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics
v8o_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8o-no-static-lane-current.patch
patched_runner v8o "${v8o_asset}" "${v8o_patch}"
v8o_runner=${patched_runner_path}
run_step di4-current "${arch_task}/evidence/di4.driver.log" \
  env \
  V8O_ASSET_DIR="${v8o_asset}" \
  V8O_CURRENT_ADAPTER_PATCH="${v8o_patch}" \
  V8O_TASK_RUN_ID="${arch_id}" \
  V8O_EVIDENCE_DIR="${arch_task}/evidence/di4-current" \
  V8O_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  V8O_ARCH_LOG="${arch_task}/evidence/no-static-lane-semantics.log" \
  bash "${v8o_runner}"
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/di4.json"

v8s_asset=${repo_root}/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration
v8s_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8s-dual-memory-core-current.patch
patched_runner v8s "${v8s_asset}" "${v8s_patch}"
v8s_runner=${patched_runner_path}
run_step ooo1-ooo2-current "${arch_task}/evidence/ooo1-ooo2.driver.log" \
  env \
  V8S_ASSET_DIR="${v8s_asset}" \
  V8S_CURRENT_ADAPTER_PATCH="${v8s_patch}" \
  V8S_CURRENT_CHECKER="${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_current.py" \
  V8S_CURRENT_CHECKER_TEST="${repo_root}/npc/rv64/eval/ppa/tests/test_v8s_dual_memory_core_current.py" \
  V8S_CURRENT_MUTATOR="${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py" \
  V8S_SCOPED_REFRESH_MODE=1 \
  V8S_EVIDENCE_DIR="${arch_task}/evidence/f2-current" \
  V8S_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  bash "${v8s_runner}"
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/ooo1-ooo2.json"

v8u_asset=${repo_root}/.github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue
v8u_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8u-dual-memory-sustained-current.patch
patched_runner v8u "${v8u_asset}" "${v8u_patch}"
v8u_runner=${patched_runner_path}
run_step di5-current "${di5_task}/driver.log" \
  env \
  V8U_ASSET_DIR="${v8u_asset}" \
  V8U_CURRENT_ADAPTER_PATCH="${v8u_patch}" \
  V8U_SCOPED_REFRESH_MODE=1 \
  V8U_F2_REPLAY_SOURCE_ROOT="${arch_task}/evidence" \
  V8U_EVIDENCE_DIR="${di5_task}/evidence/di5-current" \
  V8U_MUTATION_DIR="${di5_task}/evidence/di5-mutations" \
  V8U_ARCH_MANIFEST="${di5_task}/evidence/architecture-current.json" \
  V8U_ARCH_LOG="${di5_task}/evidence/dual-memory-issue.log" \
  bash "${v8u_runner}"

v8v_asset=${repo_root}/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering
v8v_patch=${repo_root}/npc/rv64/eval/ppa/patches/v8v-memory-ordering-current.patch
patched_runner v8v "${v8v_asset}" "${v8v_patch}"
v8v_runner=${patched_runner_path}
run_step ooo3-current "${arch_task}/evidence/ooo3.driver.log" \
  env \
  V8V_ASSET_DIR="${v8v_asset}" \
  V8V_CURRENT_ADAPTER_PATCH="${v8v_patch}" \
  V8V_CURRENT_F2_MUTATOR="${repo_root}/npc/rv64/eval/ppa/tools/v8s_dual_memory_core_mutator_current.py" \
  V8V_SCOPED_REFRESH_MODE=1 \
  V8V_EVIDENCE_DIR="${arch_task}/evidence/ooo3-current" \
  V8V_MUTATION_OUTPUT_DIR="${arch_task}/evidence/lq-mutations" \
  V8V_ARCH_MANIFEST="${arch_task}/evidence/architecture-current.json" \
  V8V_ARCH_LOG="${arch_task}/evidence/memory-ordering.log" \
  V8V_F2_EVIDENCE_DIR="${arch_task}/evidence/f2-current" \
  bash "${v8v_runner}"
cp -- "${arch_task}/evidence/architecture-current.json" "${arch_task}/evidence/manifests/ooo3.json"

run_step ooo4-current "${ooo4_task}/driver.log" \
  env \
  V8Y_SCOPED_REFRESH_MODE=1 \
  V8Y_TASK_RUN_ID="${ooo4_id}" \
  V8Y_ARCH_MANIFEST="${ooo4_task}/evidence/architecture-current.json" \
  V8Y_ARCH_LOG="${ooo4_task}/evidence/speculation-recovery.log" \
  V8Y_EVIDENCE_DIR="${ooo4_task}/evidence/ooo4-current" \
  V8Y_MUTATION_OUTPUT_DIR="${ooo4_task}/evidence/ooo4-mutations" \
  bash .github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/run-focused.sh

aggregate=${arch_task}/evidence/architecture-current-ca37.json
aggregate_receipt=${arch_task}/evidence/architecture-current-aggregate-receipt.json
run_step architecture-aggregate "${arch_task}/evidence/architecture-current-aggregate.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py build \
  --repo-root "${repo_root}" \
  --input "${di1_task}/evidence/architecture-current.json" \
  --input "${di2_task}/evidence/architecture-current.json" \
  --input "${arch_task}/evidence/manifests/di3.json" \
  --input "${arch_task}/evidence/manifests/di4.json" \
  --input "${di5_task}/evidence/architecture-current.json" \
  --input "${arch_task}/evidence/manifests/ooo1-ooo2.json" \
  --input "${arch_task}/evidence/manifests/ooo3.json" \
  --input "${ooo4_task}/evidence/architecture-current.json" \
  --output "${aggregate}" \
  --receipt "${aggregate_receipt}"

run_step architecture-aggregate-verify "${arch_task}/evidence/architecture-current-aggregate-verify.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_current_aggregate.py verify \
  --repo-root "${repo_root}" \
  --receipt "${aggregate_receipt}"

run_step architecture-hard-gates "${arch_task}/evidence/architecture-current-verification.log" \
  python3 -B npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  --repo-root "${repo_root}" \
  --evidence-manifest "${aggregate}" \
  --output "${arch_task}/evidence/architecture-current-verification.json"

task_run_status_stage evidence-complete
task_run_status_mark_evidence_complete
task_run_status_finalize 0 0
finalized=1
cleanup
trap - EXIT
printf '[ARCH-CA37][PASS] design=ca37 gates=9 current_manifests=9\n' | tee -a "${driver_log}"
