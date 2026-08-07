#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
evidence_dir="${run_dir}/evidence/mapped-sta-ab/parent-verilator-unoptflat"
status_path="${run_dir}/parent-verilator-unoptflat.status"
parent_adapter="${run_dir}/evidence/ppa/parent/OooLsuAxiLaneAdapter.v"
runtime_base="${repo_root}/.github/runtime-artifacts/v15p-parent-verilator-unoptflat"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
runtime_dir=
active_pid=
cleanup_rc=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[v15p-parent-verilator-unoptflat] RV64 engineering lane is occupied' >&2
  exit 3
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
task_run_status_init "${status_path}" || exit 1

cleanup_runtime() {
  local resolved
  if [[ -z "${runtime_dir}" || ! -e "${runtime_dir}" ]]; then
    return 0
  fi
  resolved=$(realpath -m -- "${runtime_dir}") || return 1
  case "${resolved}" in
    "${runtime_base}"/run.*) rm -r -- "${resolved}" ;;
    *) return 2 ;;
  esac
}

forward_signal() {
  local signal_name=$1
  local signal_rc=$2
  if [[ -n "${active_pid}" ]] && kill -0 "${active_pid}" 2>/dev/null; then
    kill -s "${signal_name}" -- "-${active_pid}" 2>/dev/null ||
      kill -s "${signal_name}" "${active_pid}" 2>/dev/null || true
    wait "${active_pid}" 2>/dev/null || true
  fi
  cleanup_runtime || cleanup_rc=$?
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  finalized=1
  task_run_status_finalize "${signal_rc}" "${cleanup_rc}" || true
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

finish_on_exit() {
  local command_rc=$?
  cleanup_runtime || cleanup_rc=$?
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finish_on_exit EXIT

rtl_line=
declare -a rtl_files
declare -a dot_files
preflight_rc=0
lint_rc=1
evidence_rc=1
cleanup_bytes=0
unoptflat_count=0

task_run_status_stage preflight
for command_name in awk cmp cp du flock make mkdir realpath rg rm rmdir setsid sha256sum timeout verilator; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done
[[ -f "${parent_adapter}" && ! -L "${parent_adapter}" && -s "${parent_adapter}" ]] || preflight_rc=1
[[ $(sha256sum "${parent_adapter}" | awk '{print $1}') == \
  3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6 ]] || preflight_rc=1
if [[ "${preflight_rc}" -eq 0 ]]; then
  rtl_line=$(make -s -C "${repo_root}/npc/rv64" \
    RTL_OOO_LSU_AXI_LANE_ADAPTER="${parent_adapter}" print-synth-rtl) || preflight_rc=1
  read -r -a rtl_files <<<"${rtl_line}"
  [[ "${#rtl_files[@]}" -ge 120 ]] || preflight_rc=1
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  sha256sum "${rtl_files[@]}" >"${evidence_dir}/rtl-sources.sha256" || preflight_rc=1
  verilator --version >"${evidence_dir}/verilator-version.txt" || preflight_rc=1
fi

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage parent-verilator-unoptflat
  setsid /usr/bin/timeout --signal=TERM --kill-after=15s 900s \
    verilator --lint-only --timing --report-unoptflat -Wno-fatal -Wall \
      -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL \
      -I"${repo_root}/npc/rv64/vsrc" -I"${repo_root}/npc/rv64/vsrc/include" \
      --top-module NpcTop --Mdir "${runtime_dir}/obj" "${rtl_files[@]}" \
      >"${evidence_dir}/verilator-lint.log" 2>&1 &
  active_pid=$!
  lint_rc=0
  wait "${active_pid}" || lint_rc=$?
  active_pid=
fi

if [[ "${lint_rc}" -eq 0 && -s "${evidence_dir}/verilator-lint.log" ]]; then
  task_run_status_stage evidence-capture
  rg -n '%Warning-UNOPTFLAT' "${evidence_dir}/verilator-lint.log" \
    >"${evidence_dir}/unoptflat-markers.txt" || true
  unoptflat_count=$(rg -c '%Warning-UNOPTFLAT' \
    "${evidence_dir}/verilator-lint.log" || true)
  [[ -n "${unoptflat_count}" ]] || unoptflat_count=0
  shopt -s nullglob
  dot_files=("${runtime_dir}/obj"/*.dot)
  if [[ "${#dot_files[@]}" -gt 0 ]]; then
    mkdir -p -- "${evidence_dir}/dot"
    cp -- "${dot_files[@]}" "${evidence_dir}/dot/"
    sha256sum "${evidence_dir}/dot/"*.dot >"${evidence_dir}/dot.sha256"
  fi
  printf 'lint_rc=0\nunoptflat_warning_count=%s\ndot_file_count=%s\n' \
    "${unoptflat_count}" \
    "${#dot_files[@]}" >"${evidence_dir}/result.txt"
  sha256sum "${rtl_files[@]}" >"${evidence_dir}/rtl-sources-after.sha256"
  if cmp -s "${evidence_dir}/rtl-sources.sha256" \
      "${evidence_dir}/rtl-sources-after.sha256"; then
    evidence_rc=0
  fi
fi

task_run_status_stage runtime-cleanup
if [[ -e "${runtime_dir}" ]]; then
  cleanup_bytes=$(du -sb "${runtime_dir}" | awk '{print $1}')
fi
cleanup_runtime || cleanup_rc=$?
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
printf 'preflight_rc=%s\nlint_rc=%s\nevidence_rc=%s\ncleanup_rc=%s\nruntime_bytes_deleted=%s\n' \
  "${preflight_rc}" "${lint_rc}" "${evidence_rc}" "${cleanup_rc}" "${cleanup_bytes}" \
  >"${evidence_dir}/command-status.txt"

command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${lint_rc}" -eq 0 &&
      "${evidence_rc}" -eq 0 && "${cleanup_rc}" -eq 0 && ! -e "${runtime_dir}" ]]; then
  command_rc=0
fi
task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
