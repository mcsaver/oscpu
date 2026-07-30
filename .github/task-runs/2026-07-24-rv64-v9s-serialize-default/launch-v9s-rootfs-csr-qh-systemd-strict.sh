#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_run_dir="${repo_root}/.github/task-runs/2026-07-24-rv64-v9s-serialize-default"
runner="${task_run_dir}/run-v9s-rootfs-csr-qh-systemd-strict.sh"
run_label="${V9S_ROOTFS_RUN_LABEL:-rootfs-csr-qh-on-current-systemd-strict-rerun3}"
result_dir="${task_run_dir}/${run_label}"
status_path="${task_run_dir}/${run_label}.status"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
status_helper="${repo_root}/scripts/task-run-status.sh"
validate_only="${V9S_ROOTFS_LAUNCH_VALIDATE_ONLY:-0}"

case "${run_label}" in
  *[!A-Za-z0-9._-]*|"")
    printf '%s\n' \
      "[V9S-SYSTEMD-STRICT-LAUNCH] invalid run label: ${run_label}" >&2
    exit 2
    ;;
esac

command -v flock >/dev/null
command -v setsid >/dev/null
test -x "${runner}"
test -f "${status_helper}"
[[ "${validate_only}" == "0" || "${validate_only}" == "1" ]]
mkdir -p "$(dirname -- "${lock_path}")"

publish_launcher_failure() {
  local launcher_rc="${1:?launcher return code is required}"
  local launcher_stage="${2:?launcher stage is required}"
  local finalize_rc=0

  source "${status_helper}"
  task_run_status_init "${status_path}"
  task_run_status_stage "${launcher_stage}"
  set +e
  task_run_status_finalize "${launcher_rc}" 0
  finalize_rc=$?
  set -e
  return "${finalize_rc}"
}

if [[ -e "${status_path}" || -e "${result_dir}" ]]; then
  printf '%s\n' \
    "[V9S-SYSTEMD-STRICT-LAUNCH] result label already exists: ${run_label}" >&2
  exit 2
fi

if [[ "${validate_only}" == "1" ]]; then
  if ! flock -n "${lock_path}" true; then
    printf '%s\n' \
      "[V9S-SYSTEMD-STRICT-LAUNCH] another RV64 engineering run owns ${lock_path}" >&2
    exit 3
  fi
  printf '%s\n' \
    "[V9S-SYSTEMD-STRICT-LAUNCH] validation PASS label=${run_label}"
  exit 0
fi

mkdir -p "${result_dir}"
{
  printf 'run_label=%s\n' "${run_label}"
  printf 'runner=%s\n' "${runner}"
  printf 'lock_path=%s\n' "${lock_path}"
  printf '%s\n' "session_mode=setsid-no-tty"
  printf '%s\n' "stdin=/dev/null"
} >"${result_dir}/launch-binding.txt"
date -Ins >"${result_dir}/launched-at.txt"

# 新 session 与空 stdin 防止调用端关闭时把终端 HUP 传播给数小时的 NPC 回放。
nohup setsid env \
  V9S_ROOTFS_RUN_LABEL="${run_label}" \
  flock -n -E 73 "${lock_path}" "${runner}" \
  >"${result_dir}/launcher.log" 2>&1 </dev/null &
launcher_pid=$!
printf '%s\n' "${launcher_pid}" >"${result_dir}/launcher.pid"

for _ in $(seq 1 300); do
  if [[ -s "${status_path}" ]]; then
    break
  fi
  if ! kill -0 "${launcher_pid}" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ ! -s "${status_path}" ]]; then
  launcher_rc=0
  if kill -0 "${launcher_pid}" 2>/dev/null; then
    kill -TERM -- "-${launcher_pid}" 2>/dev/null ||
      kill -TERM "${launcher_pid}" 2>/dev/null || true
    set +e
    wait "${launcher_pid}"
    set -e
    launcher_rc=124
  else
    set +e
    wait "${launcher_pid}"
    launcher_rc=$?
    set -e
    if [[ "${launcher_rc}" -eq 0 ]]; then
      launcher_rc=4
    fi
  fi
  set +e
  publish_launcher_failure "${launcher_rc}" "launcher-lock-or-init"
  publish_rc=$?
  set -e
  printf '%s\n' \
    "[V9S-SYSTEMD-STRICT-LAUNCH] runner did not publish status; " \
    "recorded FAIL rc=${publish_rc}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit "${publish_rc}"
fi

status_text="$(sed -n '1p' "${status_path}")"
if [[ "${status_text}" != "RUNNING" ]]; then
  printf '%s\n' \
    "[V9S-SYSTEMD-STRICT-LAUNCH] unexpected initial status: ${status_text}" >&2
  sed -n '1,80p' "${result_dir}/launcher.log" >&2 || true
  exit 5
fi

printf '%s\n' \
  "[V9S-SYSTEMD-STRICT-LAUNCH] RUNNING label=${run_label} launcher_pid=${launcher_pid}"
