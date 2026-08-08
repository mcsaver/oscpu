#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15t-e7da-named-timing-path-a1"
evidence_dir="${run_dir}/evidence/traceable-e7da-a1"
status_path="${run_dir}/traceable-e7da-a1.status"
runtime_base="${repo_root}/.github/runtime-artifacts/v15t-e7da-named-timing-path-a1"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
parser="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/driver/v15p_mapped_sta.py"
sta_tcl="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a/driver/opensta-v15p-exact5ns.tcl"
policy="${repo_root}/npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
reference="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/ppa-owner-any-live-e7da-a1/summary.json"
path_analysis="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1/evidence/independent-review-v4/result.json"
opensta=/home/lyg/tools/OpenSTA/build/sta
std_lib="${repo_root}/yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
macro_libs=(
  "${repo_root}/npc/rv64/syn/macro-lib/Sram4096x199.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/Sram4096x113.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/OooFpArithGate.lib"
  "${repo_root}/npc/rv64/syn/macro-lib/OooBranchDirectionPredictor.lib"
)
blackbox_modules="Sram4096x199 Sram4096x113 OooFpArithGate OooBranchDirectionPredictor"
keep_hierarchy_modules="OooIntBackend OooFpBackend OooFrontend OooFetchAxiBridge OooMemAxiBridge OooRob OooIntIssueQueue"

runtime_dir=
trace_runtime=
active_pid=
cleanup_rc=0
command_rc=1
preflight_rc=1
manifest_rc=1
synth_rc=1
opensta_rc=1
parser_rc=1
trace_rc=1
deleted_bytes=0
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${run_dir}/evidence" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[v15t-e7da-timing-trace] RV64 engineering lane is occupied' >&2
  exit 3
fi
if ! mkdir -- "${evidence_dir}"; then
  printf '%s\n' "[v15t-e7da-timing-trace] evidence directory already exists: ${evidence_dir}" >&2
  exit 2
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
trace_runtime="${runtime_dir}/traceable"
mkdir -p -- "${trace_runtime}"
task_run_status_init "${status_path}" || exit 1

cleanup_path() {
  local target=$1
  local resolved
  [[ -e "${target}" ]] || return 0
  resolved=$(realpath -m -- "${target}") || return 1
  case "${resolved}" in
    "${trace_runtime}"|"${runtime_dir}") ;;
    *)
      printf '%s\n' "[v15t-e7da-timing-trace] refusing cleanup target: ${resolved}" >&2
      return 2
      ;;
  esac
  rm -r -- "${resolved}"
}

cleanup_runtime() {
  if [[ -n "${runtime_dir}" && -e "${runtime_dir}" ]]; then
    cleanup_path "${runtime_dir}"
  fi
}

forward_signal() {
  local signal_name=$1
  local signal_rc=$2
  if [[ -n "${active_pid}" ]] && kill -0 "${active_pid}" 2>/dev/null; then
    kill -s "${signal_name}" -- "-${active_pid}" 2>/dev/null ||
      kill -s "${signal_name}" "${active_pid}" 2>/dev/null || true
    wait "${active_pid}" 2>/dev/null || true
  fi
  active_pid=
  cleanup_runtime || cleanup_rc=$?
  TASK_RUN_STATUS_SIGNAL="${signal_name}"
  task_run_status_stage "signal-${signal_name}"
  finalized=1
  task_run_status_finalize "${signal_rc}" "${cleanup_rc}" || true
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

finalize_on_exit() {
  local exit_rc=$?
  cleanup_runtime || cleanup_rc=$?
  rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage exit-trap
    task_run_status_finalize "${exit_rc}" "${cleanup_rc}" || true
  fi
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finalize_on_exit EXIT

bounded_log() {
  local source_path=$1
  local destination_path=$2
  local size
  size=$(stat -c '%s' "${source_path}") || return 1
  if [[ "${size}" -le 262144 ]]; then
    cp -- "${source_path}" "${destination_path}"
  else
    {
      head -c 131072 "${source_path}"
      printf '\n[v15t-e7da-timing-trace] ... bounded log middle omitted ...\n'
      tail -c 131072 "${source_path}"
    } >"${destination_path}"
  fi
}

production_manifest() {
  find "${repo_root}/npc/rv64/vsrc" "${repo_root}/npc/rv64/csrc" \
    -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o \
      -name '*.svh' -o -name '*.cpp' -o -name '*.cc' -o -name '*.c' -o \
      -name '*.h' -o -name '*.hpp' -o -name '*.mk' \) -print0 |
    sort -z | xargs -0 sha256sum
  sha256sum "${repo_root}/npc/rv64/.config" \
    "${repo_root}/npc/rv64/include/generated/autoconf.h" \
    "${repo_root}/npc/rv64/include/config/auto.conf" \
    "${repo_root}/npc/rv64/Makefile" "${repo_root}/npc/rv64/vsrc/filelist.mk" \
    "${repo_root}/yosys-sta/Makefile" "${repo_root}/yosys-sta/scripts/yosys.tcl" \
    "${repo_root}/yosys-sta/scripts/common.tcl" \
    "${repo_root}/yosys-sta/scripts/pdk/icsprout55.tcl" \
    "${repo_root}/oss-cad-suite/bin/yosys" "${repo_root}/oss-cad-suite/bin/yosys-abc" \
    "${opensta}" "${std_lib}" "${macro_libs[@]}" "${parser}" "${sta_tcl}" \
    "${policy}" "${reference}" "${path_analysis}" "$0"
}

write_source_manifest() {
  local output=$1
  local rtl_line
  local -a rtl_files
  rtl_line=$(make -s -C "${repo_root}/npc/rv64" print-synth-rtl) || return 1
  read -r -a rtl_files <<<"${rtl_line}"
  [[ "${#rtl_files[@]}" -ge 120 ]] || return 1
  sha256sum "${rtl_files[@]}" >"${output}"
}

write_parameters() {
  local output=$1
  local result_root=$2
  {
    printf 'mode=candidate\n'
    printf 'diagnostic=traceable-public-autoname\n'
    printf 'design=NpcTop\nperiod_ns=5.0\nclock_port=clk\nclock_name=core_clock\n'
    printf 'result_root=%s\n' "${result_root}"
    printf 'synth_flatten=0\nsynth_share=0\nsynth_public_autoname=1\nsynth_dff_autoname=0\n'
    printf 'sta_flatten_export=1\nstage_scc=0\n'
    printf 'blackbox_modules=%s\n' "${blackbox_modules}"
    printf 'keep_hierarchy_modules=%s\n' "${keep_hierarchy_modules}"
    printf 'opensta=%s\nstd_lib=%s\n' "${opensta}" "${std_lib}"
    printf 'macro_libs=%s\n' "$(IFS=:; printf '%s' "${macro_libs[*]}")"
  } >"${output}"
}

task_run_status_stage preflight
preflight_rc=0
for input in "$0" "${parser}" "${sta_tcl}" "${policy}" "${reference}" \
  "${path_analysis}" "${opensta}" "${std_lib}" "${macro_libs[@]}"; do
  [[ -f "${input}" && ! -L "${input}" && -s "${input}" ]] || preflight_rc=1
done
for command_name in awk cmp cp du find flock grep head make nice python3 realpath \
  rg rm setsid sha256sum sort stat tail timeout xargs; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done
[[ $(sha256sum "${repo_root}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v" | awk '{print $1}') == \
  6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22 ]] || preflight_rc=1

result_root="${trace_runtime}/sta"
mapped_dir="${result_root}/NpcTop-200MHz"
netlist="${mapped_dir}/NpcTop.netlist.v"
synth_console="${trace_runtime}/synth-console.full.log"
source_manifest="${evidence_dir}/synthesis-sources.sha256"
parameters="${evidence_dir}/parameters.txt"
input_manifest="${evidence_dir}/sta-inputs.sha256"

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-before
  production_manifest >"${evidence_dir}/production-manifest-before.sha256"
  manifest_rc=$?
fi
if [[ "${manifest_rc}" -eq 0 ]]; then
  synth_rc=0
  write_source_manifest "${source_manifest}" || synth_rc=1
  write_parameters "${parameters}" "${result_root}" || synth_rc=1
fi
if [[ "${synth_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-mapped-synthesis
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 5400s \
    nice -n 10 make -C "${repo_root}/npc/rv64" syn \
      STA_RESULT_ROOT="${result_root}" STA_DESIGN=NpcTop STA_PDK=icsprout55 \
      STA_CLK_PORT_NAME=clk STA_CLK_FREQ_MHZ=200 \
      STA_SDC_FILE="${repo_root}/yosys-sta/scripts/default.sdc" \
      STA_VERILOG_INCLUDE_DIRS="${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" \
      STA_VERILOG_DEFINES= STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 \
      STA_SYNTH_STOP_AFTER_COARSE=0 STA_SYNTH_PUBLIC_AUTONAME=1 \
      STA_SYNTH_DFF_AUTONAME=0 STA_SYNTH_STA_FLATTEN_EXPORT=1 \
      STA_SYNTH_BLACKBOX_MODULES="${blackbox_modules}" \
      STA_KEEP_HIERARCHY_MODULES="${keep_hierarchy_modules}" \
      STA_EXTRA_LIB_FILES="${macro_libs[*]}" \
      YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= \
      >"${synth_console}" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || synth_rc=$?
  active_pid=
  bounded_log "${synth_console}" "${evidence_dir}/synth-console.log" || synth_rc=1
fi
if [[ "${synth_rc}" -eq 0 && -s "${netlist}" && \
      -s "${mapped_dir}/synth_check.txt" && -s "${mapped_dir}/synth_stat.txt" && \
      -s "${mapped_dir}/sta_export_check.txt" ]] && \
    grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/synth_check.txt" && \
    grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/sta_export_check.txt"; then
  cp -- "${mapped_dir}/synth_check.txt" "${evidence_dir}/synth_check.txt" || synth_rc=1
  cp -- "${mapped_dir}/synth_stat.txt" "${evidence_dir}/synth_stat.txt" || synth_rc=1
  cp -- "${mapped_dir}/sta_export_check.txt" "${evidence_dir}/sta_export_check.txt" || synth_rc=1
else
  synth_rc=1
fi
if [[ "${synth_rc}" -eq 0 ]]; then
  if rg -n '\$paramod|wire signed|#[[:space:]]*\(' "${netlist}" \
      >"${evidence_dir}/sta-netlist-unsupported-syntax.txt"; then
    synth_rc=1
  else
    printf 'status=PASS\nforbidden_patterns=paramod,wire_signed,instance_parameter_override\n' \
      >"${evidence_dir}/sta-netlist-compatibility.txt"
  fi
fi
if [[ "${synth_rc}" -eq 0 && -s "${mapped_dir}/yosys.log" ]]; then
  bounded_log "${mapped_dir}/yosys.log" "${evidence_dir}/yosys.log" || synth_rc=1
fi

if [[ "${synth_rc}" -eq 0 ]]; then
  sha256sum "${netlist}" >"${evidence_dir}/netlist.sha256"
  printf 'NETLIST_SIZE_BYTES=%s\n' "$(stat -c '%s' "${netlist}")" \
    >"${evidence_dir}/netlist.size"
  macro_joined=$(IFS=:; printf '%s' "${macro_libs[*]}")
  sha256sum "${netlist}" "${source_manifest}" "${parameters}" "${std_lib}" \
    "${macro_libs[@]}" "${opensta}" "${sta_tcl}" "${parser}" \
    >"${input_manifest}"
  task_run_status_stage traceable-opensta-exact5ns
  opensta_rc=0
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    /usr/bin/env V15P_STA_NETLIST="${netlist}" \
      V15P_STA_OUT_DIR="${evidence_dir}" V15P_STA_STD_LIB="${std_lib}" \
      V15P_STA_MACRO_LIBS="${macro_joined}" V15P_STA_PERIOD_NS=5.0 \
      V15P_STA_MODE=candidate \
      V15P_STA_NETLIST_SHA256="$(sha256sum "${netlist}" | awk '{print $1}')" \
      V15P_STA_INPUT_MANIFEST_SHA256="$(sha256sum "${input_manifest}" | awk '{print $1}')" \
      V15P_STA_PARAMETERS_SHA256="$(sha256sum "${parameters}" | awk '{print $1}')" \
      V15P_STA_OPENSTA_BINARY="${opensta}" \
      V15P_STA_OPENSTA_BINARY_SHA256="$(sha256sum "${opensta}" | awk '{print $1}')" \
      "${opensta}" "${sta_tcl}" >"${evidence_dir}/opensta-console.log" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || opensta_rc=$?
  active_pid=
  [[ "${opensta_rc}" -eq 0 && -s "${evidence_dir}/opensta-complete.txt" ]] || opensta_rc=1
fi

if [[ "${opensta_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-evidence-parse
  python3 -B "${parser}" variant --mode candidate \
    --out-dir "${evidence_dir}" --netlist "${netlist}" \
    --input-manifest "${input_manifest}" --parameters "${parameters}" \
    --source-manifest "${source_manifest}" \
    --synth-check "${evidence_dir}/synth_check.txt" \
    --synth-stat "${evidence_dir}/synth_stat.txt" \
    --std-lib "${std_lib}" --opensta-binary "${opensta}" \
    --output "${evidence_dir}/summary.json" \
    >"${evidence_dir}/parser.log" 2>&1
  parser_rc=$?
fi

if [[ "${parser_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-name-check
  trace_rc=0
  start_count=$(grep -c '^Startpoint:' "${evidence_dir}/opensta-top40.rpt") || trace_rc=1
  endpoint_count=$(grep -c '^Endpoint:' "${evidence_dir}/opensta-top40.rpt") || trace_rc=1
  public_flat_starts=$(grep -Ec '^Startpoint: u_core_u_ooo_core_.*_DFF.*_D$'     "${evidence_dir}/opensta-top40.rpt") || true
  public_flat_endpoints=$(grep -Ec '^Endpoint: u_core_u_ooo_core_.*_DFF.*_D$'     "${evidence_dir}/opensta-top40.rpt") || true
  opaque_starts=$(grep -Ec '^Startpoint: _[0-9]+_'     "${evidence_dir}/opensta-top40.rpt") || true
  opaque_endpoints=$(grep -Ec '^Endpoint: _[0-9]+_'     "${evidence_dir}/opensta-top40.rpt") || true
  [[ "${start_count}" -eq 40 && "${endpoint_count}" -eq 40 &&       "${public_flat_starts}" -eq 40 && "${public_flat_endpoints}" -eq 40 &&       "${opaque_starts}" -eq 0 && "${opaque_endpoints}" -eq 0 ]] || trace_rc=1
  printf 'status=%s\nstartpoints=%s\nendpoints=%s\npublic_flat_startpoints=%s\npublic_flat_endpoints=%s\nopaque_startpoints=%s\nopaque_endpoints=%s\n'     "$([[ "${trace_rc}" -eq 0 ]] && printf PASS || printf FAIL)"     "${start_count}" "${endpoint_count}" "${public_flat_starts}"     "${public_flat_endpoints}" "${opaque_starts}" "${opaque_endpoints}"     >"${evidence_dir}/traceability.txt"
fi

if [[ "${trace_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-runtime-cleanup
  deleted_bytes=$(du -sb "${trace_runtime}" | awk '{print $1}')
  cleanup_path "${trace_runtime}" || cleanup_rc=$?
  [[ ! -e "${trace_runtime}" ]] || cleanup_rc=1
  printf 'runtime_deleted=PASS\nruntime_bytes_deleted=%s\nnetlist_retained=NO\nnetlist_sha256_retained=YES\n' \
    "${deleted_bytes}" >"${evidence_dir}/cleanup.txt"
fi

if [[ "${trace_rc}" -eq 0 && "${cleanup_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-after
  production_manifest >"${evidence_dir}/production-manifest-after.sha256" || manifest_rc=$?
  if [[ "${manifest_rc}" -eq 0 ]] && ! cmp -s \
      "${evidence_dir}/production-manifest-before.sha256" \
      "${evidence_dir}/production-manifest-after.sha256"; then
    manifest_rc=1
  fi
fi

cleanup_runtime || cleanup_rc=$?
[[ ! -e "${runtime_dir}" ]] || cleanup_rc=1
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
if [[ "${preflight_rc}" -eq 0 && "${manifest_rc}" -eq 0 && \
      "${synth_rc}" -eq 0 && "${opensta_rc}" -eq 0 && \
      "${parser_rc}" -eq 0 && "${trace_rc}" -eq 0 && \
      "${cleanup_rc}" -eq 0 && "${deleted_bytes}" -gt 0 && \
      -s "${evidence_dir}/summary.json" ]]; then
  command_rc=0
fi
printf '%s\n' "preflight_rc=${preflight_rc}" "manifest_rc=${manifest_rc}" \
  "synth_rc=${synth_rc}" "opensta_rc=${opensta_rc}" "parser_rc=${parser_rc}" \
  "trace_rc=${trace_rc}" "cleanup_rc=${cleanup_rc}" \
  "runtime_bytes_deleted=${deleted_bytes}" >"${evidence_dir}/command-status.txt"

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 && ! -e "${runtime_dir}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
