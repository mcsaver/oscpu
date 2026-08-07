#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-06-rv64-v15p-adapter-final-b-fallthrough-f7a"
evidence_tag=${V15P_MAPPED_TAG:-mapped-sta-ab}
if [[ ! "${evidence_tag}" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  printf '%s\n' "[v15p-mapped-sta] invalid evidence tag: ${evidence_tag}" >&2
  exit 2
fi
evidence_dir="${run_dir}/evidence/${evidence_tag}"
status_path="${run_dir}/${evidence_tag}.status"
tool="${run_dir}/driver/v15p_mapped_sta.py"
sta_tcl="${run_dir}/driver/opensta-v15p-exact5ns.tcl"
performance_result=${V15P_PERFORMANCE_RESULT:-"${run_dir}/evidence/performance-ab/result.json"}
policy="${repo_root}/npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
parent_adapter="${run_dir}/evidence/ppa/parent/OooLsuAxiLaneAdapter.v"
candidate_adapter="${repo_root}/npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"

runtime_base="${repo_root}/.github/runtime-artifacts/v15p-${evidence_tag}"
lock_path="${repo_root}/.github/runtime-artifacts/rv64-engineering-single-flight.lock"
opensta="/home/lyg/tools/OpenSTA/build/sta"
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
active_pid=
cleanup_rc=0
finalized=0
parent_rc=1
parent_graph_rc=1
candidate_rc=1
compare_rc=1
verify_rc=1
manifest_rc=1
parent_deleted_bytes=0
candidate_deleted_bytes=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p -- "${evidence_dir}" "${runtime_base}" "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[v15p-mapped-sta] RV64 engineering lane is occupied' >&2
  exit 3
fi
runtime_dir=$(mktemp -d "${runtime_base}/run.XXXXXX") || exit 1
task_run_status_init "${status_path}" || exit 1

cleanup_path() {
  local target=$1
  local resolved
  if [[ ! -e "${target}" ]]; then
    return 0
  fi
  resolved=$(realpath -m -- "${target}") || return 1
  case "${resolved}" in
    "${runtime_dir}/parent"|"${runtime_dir}/candidate"|"${runtime_dir}") ;;
    *)
      printf '%s\n' "[v15p-mapped-sta] refusing cleanup target: ${resolved}" >&2
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
      printf '\n[v15p-mapped-sta] ... bounded log middle omitted ...\n'
      tail -c 131072 "${source_path}"
    } >"${destination_path}"
  fi
}

capture_verilog_error_context() {
  local console_path=$1
  local netlist_path=$2
  local output_path=$3
  local line_number
  local first_line
  local last_line
  line_number=$(grep -Eo 'line [0-9]+, syntax error' "${console_path}" 2>/dev/null |
    tail -n 1 | awk '{print $2}' | tr -d ',')
  [[ "${line_number}" =~ ^[0-9]+$ ]] || return 0
  first_line=$((line_number > 5 ? line_number - 5 : 1))
  last_line=$((line_number + 5))
  {
    printf 'reported_line=%s\nfirst_line=%s\nlast_line=%s\n' \
      "${line_number}" "${first_line}" "${last_line}"
    sed -n "${first_line},${last_line}p" "${netlist_path}" | nl -ba -v "${first_line}"
  } >"${output_path}"
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
    "${opensta}" "${std_lib}" "${macro_libs[@]}" "${tool}" "${sta_tcl}" \
    "${parent_adapter}" "${performance_result}" "${policy}"
}

write_source_manifest() {
  local mode=$1
  local output=$2
  local adapter_arg=()
  local rtl_line
  local -a rtl_files
  if [[ "${mode}" == parent ]]; then
    adapter_arg=("RTL_OOO_LSU_AXI_LANE_ADAPTER=${parent_adapter}")
  fi
  rtl_line=$(make -s -C "${repo_root}/npc/rv64" "${adapter_arg[@]}" print-synth-rtl) || return 1
  read -r -a rtl_files <<<"${rtl_line}"
  [[ "${#rtl_files[@]}" -ge 120 ]] || return 1
  sha256sum "${rtl_files[@]}" >"${output}"
}

write_parameters() {
  local mode=$1
  local output=$2
  local result_root=$3
  {
    printf 'mode=%s\n' "${mode}"
    printf 'design=NpcTop\nperiod_ns=5.0\nclock_port=clk\nclock_name=core_clock\n'
    printf 'result_root=%s\n' "${result_root}"
    printf 'synth_flatten=0\nsynth_share=0\nsynth_public_autoname=0\nsynth_dff_autoname=0\n'
    printf 'sta_flatten_export=1\n'
    printf 'stage_scc=0\n'
    printf 'blackbox_modules=%s\n' "${blackbox_modules}"
    printf 'keep_hierarchy_modules=%s\n' "${keep_hierarchy_modules}"
    printf 'opensta=%s\nstd_lib=%s\n' "${opensta}" "${std_lib}"
    printf 'macro_libs=%s\n' "$(IFS=:; printf '%s' "${macro_libs[*]}")"
  } >"${output}"
}

run_variant() {
  local mode=$1
  local variant_runtime="${runtime_dir}/${mode}"
  local result_root="${variant_runtime}/sta"
  local mapped_dir="${result_root}/NpcTop-200MHz"
  local netlist="${mapped_dir}/NpcTop.netlist.v"
  local variant_evidence="${evidence_dir}/${mode}"
  local synth_console="${variant_runtime}/synth-console.full.log"
  local source_manifest="${variant_evidence}/synthesis-sources.sha256"
  local parameters="${variant_evidence}/parameters.txt"
  local input_manifest="${variant_evidence}/sta-inputs.sha256"
  local adapter_arg=()
  local macro_joined
  local synth_rc=0
  local opensta_rc=1
  local parser_rc=1
  local localizer_rc=0
  local loop_localization=NOT_NEEDED
  local netlist_bytes=0
  local deleted_bytes=0

  mkdir -p -- "${variant_runtime}" "${variant_evidence}"
  rm -f -- "${variant_evidence}/opensta-verilog-error-context.txt"
  if [[ "${mode}" == parent ]]; then
    adapter_arg=("RTL_OOO_LSU_AXI_LANE_ADAPTER=${parent_adapter}")
  fi
  write_source_manifest "${mode}" "${source_manifest}" || return 1
  write_parameters "${mode}" "${parameters}" "${result_root}" || return 1

  task_run_status_stage "${mode}-mapped-synthesis"
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 5400s \
    nice -n 10 make -C "${repo_root}/npc/rv64" syn \
      STA_RESULT_ROOT="${result_root}" STA_DESIGN=NpcTop STA_PDK=icsprout55 \
      STA_CLK_PORT_NAME=clk STA_CLK_FREQ_MHZ=200 \
      STA_SDC_FILE="${repo_root}/yosys-sta/scripts/default.sdc" \
      STA_VERILOG_INCLUDE_DIRS="${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" \
      STA_VERILOG_DEFINES= STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 \
      STA_SYNTH_STOP_AFTER_COARSE=0 STA_SYNTH_PUBLIC_AUTONAME=0 \
      STA_SYNTH_DFF_AUTONAME=0 STA_SYNTH_STA_FLATTEN_EXPORT=1 \
      STA_SYNTH_BLACKBOX_MODULES="${blackbox_modules}" \
      STA_KEEP_HIERARCHY_MODULES="${keep_hierarchy_modules}" \
      STA_EXTRA_LIB_FILES="${macro_libs[*]}" \
      YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= "${adapter_arg[@]}" \
      >"${synth_console}" 2>&1 &
  active_pid=$!
  wait "${active_pid}" || synth_rc=$?
  active_pid=
  bounded_log "${synth_console}" "${variant_evidence}/synth-console.log" || synth_rc=1
  if [[ "${synth_rc}" -ne 0 || ! -s "${netlist}" ||
        ! -s "${mapped_dir}/synth_check.txt" || ! -s "${mapped_dir}/synth_stat.txt" ||
        ! -s "${mapped_dir}/sta_export_check.txt" ]]; then
    return 1
  fi
  if ! grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/synth_check.txt"; then
    return 1
  fi
  cp -- "${mapped_dir}/synth_check.txt" "${variant_evidence}/synth_check.txt" || return 1
  cp -- "${mapped_dir}/synth_stat.txt" "${variant_evidence}/synth_stat.txt" || return 1
  cp -- "${mapped_dir}/sta_export_check.txt" \
    "${variant_evidence}/sta_export_check.txt" || return 1
  if ! grep -Fq 'Found and reported 0 problems.' \
      "${mapped_dir}/sta_export_check.txt"; then
    return 1
  fi
  if rg -n '\$paramod|wire signed|#[[:space:]]*\(' "${netlist}" \
      >"${variant_evidence}/sta-netlist-unsupported-syntax.txt"; then
    return 1
  fi
  printf 'status=PASS\nforbidden_patterns=paramod,wire_signed,instance_parameter_override\n' \
    >"${variant_evidence}/sta-netlist-compatibility.txt"
  if [[ -s "${mapped_dir}/yosys.log" ]]; then
    bounded_log "${mapped_dir}/yosys.log" "${variant_evidence}/yosys.log" || return 1
  fi
  sha256sum "${netlist}" >"${variant_evidence}/netlist.sha256"
  netlist_bytes=$(stat -c '%s' "${netlist}")
  printf 'NETLIST_SIZE_BYTES=%s\n' "${netlist_bytes}" >"${variant_evidence}/netlist.size"

  macro_joined=$(IFS=:; printf '%s' "${macro_libs[*]}")
  sha256sum "${netlist}" "${source_manifest}" "${parameters}" "${std_lib}" \
    "${macro_libs[@]}" "${opensta}" "${sta_tcl}" "${tool}" \
    >"${input_manifest}"
  task_run_status_stage "${mode}-opensta-exact5ns"
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    /usr/bin/env V15P_STA_NETLIST="${netlist}" \
      V15P_STA_OUT_DIR="${variant_evidence}" V15P_STA_STD_LIB="${std_lib}" \
      V15P_STA_MACRO_LIBS="${macro_joined}" V15P_STA_PERIOD_NS=5.0 \
      V15P_STA_MODE="${mode}" \
      V15P_STA_NETLIST_SHA256="$(sha256sum "${netlist}" | awk '{print $1}')" \
      V15P_STA_INPUT_MANIFEST_SHA256="$(sha256sum "${input_manifest}" | awk '{print $1}')" \
      V15P_STA_PARAMETERS_SHA256="$(sha256sum "${parameters}" | awk '{print $1}')" \
      V15P_STA_OPENSTA_BINARY="${opensta}" \
      V15P_STA_OPENSTA_BINARY_SHA256="$(sha256sum "${opensta}" | awk '{print $1}')" \
      "${opensta}" "${sta_tcl}" >"${variant_evidence}/opensta-console.log" 2>&1 &
  active_pid=$!
  opensta_rc=0
  wait "${active_pid}" || opensta_rc=$?
  active_pid=
  if [[ "${opensta_rc}" -ne 0 ||
        ! -s "${variant_evidence}/opensta-complete.txt" ]]; then
    capture_verilog_error_context "${variant_evidence}/opensta-console.log" \
      "${netlist}" "${variant_evidence}/opensta-verilog-error-context.txt"
    return 1
  fi

  task_run_status_stage "${mode}-evidence-parse"
  python3 -B "${tool}" variant --mode "${mode}" \
    --out-dir "${variant_evidence}" --netlist "${netlist}" \
    --input-manifest "${input_manifest}" --parameters "${parameters}" \
    --source-manifest "${source_manifest}" \
    --synth-check "${variant_evidence}/synth_check.txt" \
    --synth-stat "${variant_evidence}/synth_stat.txt" \
    --std-lib "${std_lib}" --opensta-binary "${opensta}" \
    --output "${variant_evidence}/summary.json" \
    >"${variant_evidence}/parser.log" 2>&1
  parser_rc=$?
  [[ "${parser_rc}" -eq 0 ]] || return 1

  if ! rg -q '"combinational_loops": 0' "${variant_evidence}/summary.json"; then
    task_run_status_stage "${mode}-mapped-loop-localize"
    python3 -B "${tool}" loop-localize \
      --setup "${variant_evidence}/opensta-check-setup.txt" \
      --top40 "${variant_evidence}/opensta-top40.rpt" \
      --netlist "${netlist}" --std-lib "${std_lib}" \
      --output "${variant_evidence}/mapped-loop-localization.json" \
      >"${variant_evidence}/mapped-loop-localization.log" 2>&1
    localizer_rc=$?
    [[ "${localizer_rc}" -eq 0 ]] || return 1
    loop_localization=PASS
  fi

  task_run_status_stage "${mode}-runtime-cleanup"
  deleted_bytes=$(du -sb "${variant_runtime}" | awk '{print $1}')
  cleanup_path "${variant_runtime}" || return 1
  [[ ! -e "${variant_runtime}" ]] || return 1
  printf 'runtime_deleted=PASS\nruntime_bytes_deleted=%s\nnetlist_retained=NO\nnetlist_sha256_retained=YES\nloop_localization=%s\n' \
    "${deleted_bytes}" "${loop_localization}" >"${variant_evidence}/cleanup.txt"
  if [[ "${mode}" == parent ]]; then
    parent_deleted_bytes=${deleted_bytes}
  else
    candidate_deleted_bytes=${deleted_bytes}
  fi
  return 0
}

preflight_rc=0
task_run_status_stage preflight
for input in "${tool}" "${sta_tcl}" "${performance_result}" "${policy}" \
  "${parent_adapter}" "${candidate_adapter}" "${opensta}" "${std_lib}" \
  "${macro_libs[@]}"; do
  [[ -f "${input}" && ! -L "${input}" && -s "${input}" ]] || preflight_rc=1
done
for command_name in awk cmp du find flock grep head make nice nl python3 \
  realpath rg sed setsid sha256sum sort stat tail timeout tr xargs; do
  command -v "${command_name}" >/dev/null || preflight_rc=1
done
[[ $(sha256sum "${parent_adapter}" | awk '{print $1}') == \
  3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6 ]] || preflight_rc=1
[[ $(sha256sum "${candidate_adapter}" | awk '{print $1}') == \
  6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22 ]] || preflight_rc=1

if [[ "${preflight_rc}" -eq 0 ]]; then
  task_run_status_stage production-manifest-before
  production_manifest >"${evidence_dir}/production-manifest-before.sha256"
  manifest_rc=$?
fi
if [[ "${manifest_rc}" -eq 0 ]]; then
  run_variant parent
  parent_rc=$?
fi
if [[ "${parent_rc}" -eq 0 ]]; then
  task_run_status_stage parent-timing-graph-qualify
  python3 -B "${tool}" qualify \
    --input "${evidence_dir}/parent/summary.json" --mode parent \
    >"${evidence_dir}/parent/graph-qualify.log" 2>&1
  parent_graph_rc=$?
fi
if [[ "${parent_graph_rc}" -eq 0 ]]; then
  run_variant candidate
  candidate_rc=$?
fi
if [[ "${candidate_rc}" -eq 0 ]]; then
  task_run_status_stage mapped-sta-ab-compare
  python3 -B "${tool}" compare \
    --parent "${evidence_dir}/parent/summary.json" \
    --candidate "${evidence_dir}/candidate/summary.json" \
    --performance "${performance_result}" --policy "${policy}" \
    --output "${evidence_dir}/result.json" >"${evidence_dir}/compare.log" 2>&1
  compare_rc=$?
fi
if [[ "${compare_rc}" -eq 0 ]]; then
  task_run_status_stage mapped-sta-ab-verify
  python3 -B "${tool}" verify --input "${evidence_dir}/result.json" \
    >"${evidence_dir}/verify.log" 2>&1
  verify_rc=$?
fi
if [[ "${verify_rc}" -eq 0 ]]; then
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
command_rc=1
if [[ "${preflight_rc}" -eq 0 && "${manifest_rc}" -eq 0 &&
      "${parent_rc}" -eq 0 && "${candidate_rc}" -eq 0 &&
      "${parent_graph_rc}" -eq 0 &&
      "${compare_rc}" -eq 0 && "${verify_rc}" -eq 0 &&
      "${cleanup_rc}" -eq 0 && "${parent_deleted_bytes}" -gt 0 &&
      "${candidate_deleted_bytes}" -gt 0 ]]; then
  command_rc=0
fi
printf '%s\n' "preflight_rc=${preflight_rc}" "manifest_rc=${manifest_rc}" \
  "parent_rc=${parent_rc}" "candidate_rc=${candidate_rc}" \
  "parent_graph_rc=${parent_graph_rc}" \
  "compare_rc=${compare_rc}" "verify_rc=${verify_rc}" \
  "cleanup_rc=${cleanup_rc}" "parent_runtime_bytes_deleted=${parent_deleted_bytes}" \
  "candidate_runtime_bytes_deleted=${candidate_deleted_bytes}" \
  >"${evidence_dir}/command-status.txt"

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 && -s "${evidence_dir}/result.json" &&
      ! -e "${runtime_dir}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
