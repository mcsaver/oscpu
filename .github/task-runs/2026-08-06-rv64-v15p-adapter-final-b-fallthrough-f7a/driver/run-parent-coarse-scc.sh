#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
scc_mode=${V15P_COARSE_SCC_MODE:-hierarchical}
case "${scc_mode}" in
  hierarchical)
    synth_flatten=0
    evidence_name=parent-coarse-scc
    ;;
  flat)
    synth_flatten=1
    evidence_name=parent-coarse-flat-scc
    ;;
  *)
    printf '%s\n' "[v15p-parent-coarse-scc] invalid mode: ${scc_mode}" >&2
    exit 2
    ;;
esac
evidence_dir="${run_dir}/evidence/mapped-sta-ab/${evidence_name}"
status_path="${run_dir}/${evidence_name}.status"
parent_adapter="${run_dir}/evidence/ppa/parent/OooLsuAxiLaneAdapter.v"
runtime_base="${repo_root}/.github/runtime-artifacts/v15p-parent-coarse-scc"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
blackbox_modules="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"
macro_libs=(
  "${repo_root}/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
runtime_dir=
active_pid=
cleanup_rc=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[v15p-parent-coarse-scc] RV64 engineering lane is occupied' >&2
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

result_root="${runtime_dir}/sta"
mapped_dir="${result_root}/NpcTop-200MHz"
netlist="${mapped_dir}/NpcTop.netlist.v"
synth_console="${runtime_dir}/synth-console.log"
source_manifest_before="${evidence_dir}/synthesis-sources-before.sha256"
source_manifest_after="${evidence_dir}/synthesis-sources-after.sha256"
rtl_line=
declare -a rtl_files
preflight_rc=0
synth_rc=1
evidence_rc=1
cleanup_bytes=0

task_run_status_stage preflight
for path in "${parent_adapter}" "${macro_libs[@]}"; do
  [[ -f "${path}" && ! -L "${path}" && -s "${path}" ]] || preflight_rc=1
done
for command_name in awk cmp cp du flock grep make nice realpath rm rmdir setsid \
  sha256sum stat timeout; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done
[[ $(sha256sum "${parent_adapter}" | awk '{print $1}') == \
  3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6 ]] || preflight_rc=1
if [[ "${preflight_rc}" -eq 0 ]]; then
  rtl_line=$(make -s -C "${repo_root}/npc/rv64" \
    RTL_OOO_LSU_AXI_LANE_ADAPTER="${parent_adapter}" print-synth-rtl) || preflight_rc=1
  read -r -a rtl_files <<<"${rtl_line}"
  [[ "${#rtl_files[@]}" -ge 120 ]] || preflight_rc=1
fi
if [[ "${preflight_rc}" -eq 0 ]]; then
  sha256sum "${rtl_files[@]}" >"${source_manifest_before}" || preflight_rc=1
fi

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage "parent-coarse-${scc_mode}-scc"
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 1800s \
    nice -n 10 make -C "${repo_root}/npc/rv64" syn \
      RTL_OOO_LSU_AXI_LANE_ADAPTER="${parent_adapter}" \
      STA_RESULT_ROOT="${result_root}" STA_DESIGN=NpcTop STA_PDK=icsprout55 \
      STA_CLK_PORT_NAME=clk STA_CLK_FREQ_MHZ=200 \
      STA_SDC_FILE="${repo_root}/yosys-sta/scripts/default.sdc" \
      STA_VERILOG_INCLUDE_DIRS="${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" \
      STA_VERILOG_DEFINES= STA_SYNTH_FLATTEN="${synth_flatten}" STA_SYNTH_SHARE=0 \
      STA_SYNTH_STOP_AFTER_COARSE=1 STA_SYNTH_PUBLIC_AUTONAME=0 \
      STA_SYNTH_DFF_AUTONAME=0 STA_SYNTH_STA_FLATTEN_EXPORT=0 \
      STA_SYNTH_BLACKBOX_MODULES="${blackbox_modules}" \
      STA_KEEP_HIERARCHY_MODULES= STA_EXTRA_LIB_FILES="${macro_libs[*]}" \
      YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= >"${synth_console}" 2>&1 &
  active_pid=$!
  synth_rc=0
  wait "${active_pid}" || synth_rc=$?
  active_pid=
fi

if [[ "${synth_rc}" -eq 0 ]]; then
  task_run_status_stage evidence-capture
  cp -- "${synth_console}" "${evidence_dir}/synth-console.log"
  if [[ -s "${netlist}" && -s "${mapped_dir}/synth_scc.txt" &&
        -e "${mapped_dir}/synth_scc_dump.txt" &&
        -s "${mapped_dir}/synth_check.txt" && -s "${mapped_dir}/synth_stat.txt" ]]; then
    cp -- "${mapped_dir}/synth_scc.txt" "${evidence_dir}/synth_scc.txt"
    cp -- "${mapped_dir}/synth_scc_dump.txt" "${evidence_dir}/synth_scc_dump.txt"
    cp -- "${mapped_dir}/synth_check.txt" "${evidence_dir}/synth_check.txt"
    cp -- "${mapped_dir}/synth_stat.txt" "${evidence_dir}/synth_stat.txt"
    sha256sum "${netlist}" >"${evidence_dir}/netlist.sha256"
    stat -c 'netlist_size_bytes=%s' "${netlist}" >"${evidence_dir}/netlist.size"
    sha256sum "${rtl_files[@]}" >"${source_manifest_after}"
    if cmp -s "${source_manifest_before}" "${source_manifest_after}" &&
        grep -Fq 'Found and reported 0 problems.' "${evidence_dir}/synth_check.txt"; then
      evidence_rc=0
    fi
  fi
fi

task_run_status_stage runtime-cleanup
if [[ -e "${runtime_dir}" ]]; then
  cleanup_bytes=$(du -sb "${runtime_dir}" | awk '{print $1}')
fi
cleanup_runtime || cleanup_rc=$?
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
printf 'scc_mode=%s\nsynth_flatten=%s\npreflight_rc=%s\nsynth_rc=%s\nevidence_rc=%s\ncleanup_rc=%s\nruntime_bytes_deleted=%s\n' \
  "${scc_mode}" "${synth_flatten}" "${preflight_rc}" "${synth_rc}" \
  "${evidence_rc}" "${cleanup_rc}" "${cleanup_bytes}" \
  >"${evidence_dir}/command-status.txt"

command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${synth_rc}" -eq 0 &&
      "${evidence_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
      "${cleanup_bytes}" -gt 0 && ! -e "${runtime_dir}" ]]; then
  command_rc=0
fi
task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
