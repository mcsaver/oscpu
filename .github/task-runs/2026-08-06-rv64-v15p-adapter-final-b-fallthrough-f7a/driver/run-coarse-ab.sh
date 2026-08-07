#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
run_root="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
evidence_root="${run_root}/evidence/ppa/coarse-ab"
runtime_root="${repo_root}/.github/runtime-artifacts/rv64-v15p-adapter-final-b-fallthrough-f7a/coarse-ab"
status_path="${run_root}/coarse-ab.status"
parent_adapter="${run_root}/evidence/ppa/parent/OooLsuAxiLaneAdapter.v"
expected_parent_sha=3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps
cleanup_rc=0
finalize_status() {
  local command_rc=$?
  local final_rc
  trap - EXIT
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap finalize_status EXIT

mkdir -p "${evidence_root}"
if [[ "$(sha256sum "${parent_adapter}" | awk '{print $1}')" != "${expected_parent_sha}" ]]; then
  echo "[V15P-COARSE-AB][FAIL] parent adapter identity mismatch" >&2
  exit 1
fi

run_variant() {
  local variant=$1
  local adapter=$2
  local runtime_variant="${runtime_root}/${variant}"
  local evidence_variant="${evidence_root}/${variant}"
  local result_dir="${runtime_variant}/NpcTop-200MHz"
  local netlist="${result_dir}/NpcTop.netlist.v"
  local -a adapter_arg=()
  if [[ -n "${adapter}" ]]; then
    adapter_arg+=("RTL_OOO_LSU_AXI_LANE_ADAPTER=${adapter}")
  fi

  mkdir -p "${runtime_variant}" "${evidence_variant}"
  task_run_status_stage "${variant}-full-core-coarse"
  /usr/bin/time -p -o "${evidence_variant}/time.txt" \
    make -C "${repo_root}/npc/rv64" syn \
      STA_DESIGN=NpcTop \
      STA_CLK_FREQ_MHZ=200 \
      STA_RESULT_ROOT="${runtime_variant}" \
      STA_SYNTH_FLATTEN=0 \
      STA_SYNTH_SHARE=0 \
      STA_SYNTH_STOP_AFTER_COARSE=1 \
      YOSYS_ARGS="-q -Q -T" \
      YOSYS_LOG_ARGS= \
      "${adapter_arg[@]}" >"${evidence_variant}/console.log" 2>&1

  if [[ ! -s "${result_dir}/synth_check.txt" ||
        ! -s "${result_dir}/synth_stat.txt" || ! -s "${netlist}" ]]; then
    echo "[V15P-COARSE-AB][FAIL] ${variant} evidence missing" >&2
    exit 1
  fi
  if ! grep -Fq 'Found and reported 0 problems.' "${result_dir}/synth_check.txt"; then
    echo "[V15P-COARSE-AB][FAIL] ${variant} synthesis check" >&2
    exit 1
  fi
  cp -- "${result_dir}/synth_check.txt" "${evidence_variant}/"
  cp -- "${result_dir}/synth_stat.txt" "${evidence_variant}/"
  sha256sum "${netlist}" >"${evidence_variant}/netlist.sha256"
  stat -c 'NETLIST_SIZE_BYTES=%s' "${netlist}" >"${evidence_variant}/netlist.size"
  sha256sum "${adapter:-${repo_root}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v}" \
    >"${evidence_variant}/adapter.sha256"

  case "${runtime_variant}" in
    "${repo_root}"/.github/runtime-artifacts/rv64-v15p-adapter-final-b-fallthrough-f7a/coarse-ab/*)
      rm -rf -- "${runtime_variant}" || cleanup_rc=1
      ;;
    *)
      echo "[V15P-COARSE-AB][CLEANUP-REFUSED] ${runtime_variant}" >&2
      cleanup_rc=1
      ;;
  esac
  if [[ ${cleanup_rc} -ne 0 ]]; then
    exit 1
  fi
}

run_variant parent "${parent_adapter}"
run_variant candidate ""

task_run_status_stage coarse-ab-evidence-complete
task_run_status_mark_evidence_complete
echo '[V15P-COARSE-AB][PASS] parent=1 candidate=1 synth_check=0 runtime_clean=1'
