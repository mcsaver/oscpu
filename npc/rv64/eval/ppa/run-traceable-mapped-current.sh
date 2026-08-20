#!/usr/bin/env bash

# Current-source 5 ns traceable mapped synthesis/OpenSTA runner.  Runtime
# netlists and Yosys intermediates are deleted after evidence is sealed.

set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
runner_path="$(realpath -e -- "${BASH_SOURCE[0]}")" || exit 2
task_run_root="${repo_root}/.github/task-runs"
runtime_root="${repo_root}/.github/runtime-artifacts"
lock_path="${runtime_root}/rv64-engineering-single-flight.lock"
parser="${repo_root}/npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"
sta_tcl="${repo_root}/npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"
trace_checker="${repo_root}/npc/rv64/eval/ppa/tools/traceable_path_inventory.py"
architecture_registry="${repo_root}/npc/rv64/eval/ppa/tools/architecture_registry.py"
architecture_catalog="${repo_root}/npc/rv64/design/arch/rv64-architecture-registry-v1.json"
opensta=
std_lib=
sdc_file=
macro_libs=()
blackbox_modules=
inline_modules=
keep_hierarchy_modules=

run_dir_arg=
evidence_id=
evidence_dir_canonical=
physical_configuration=
mapped_artifact_profile=
expected_rtl_design_id=
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
binding_rc=1
deleted_bytes=0
finalized=0

usage() {
  local stream=${1:-2}
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<new-run-id> --evidence-id <id> --physical-configuration <id> --expected-rtl-design-id sha256:<64hex>" \
    >&"${stream}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir_arg=$2
      shift 2
      ;;
    --evidence-id)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      evidence_id=$2
      shift 2
      ;;
    --physical-configuration)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      physical_configuration=$2
      shift 2
      ;;
    --expected-rtl-design-id)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      expected_rtl_design_id=$2
      shift 2
      ;;
    -h|--help)
      usage 1
      exit 0
      ;;
    *)
      printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][FAIL] unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ||
      ! "${evidence_id}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ||
      ! "${physical_configuration}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ||
      ! "${expected_rtl_design_id}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][FAIL] invalid run-dir, evidence-id, physical configuration, or expected RTL design-id" >&2
  exit 2
fi

task_run_root="$(realpath -e -- "${task_run_root}")" || exit 2
run_id="${run_dir_arg##*/}"
run_dir="${task_run_root}/${run_id}"
if [[ -e "${run_dir}" || -L "${run_dir}" ]]; then
  printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][FAIL] run directory exists: ${run_dir_arg}" >&2
  exit 2
fi

for input in "$0" "${parser}" "${sta_tcl}" "${trace_checker}" \
  "${architecture_registry}" "${architecture_catalog}"; do
  if [[ -L "${input}" || ! -f "${input}" || ! -s "${input}" ]]; then
    printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][FAIL] unsafe input: ${input}" >&2
    exit 2
  fi
done
for command_name in awk cmp cp du find flock grep head make nice python3 \
  realpath rg rm setsid sha256sum sort stat tail timeout xargs; do
  command -v "${command_name}" >/dev/null || exit 2
done

# The architecture registry is the sole manual owner of mapped macro
# boundaries.  This deterministic projection prevents a module from silently
# remaining blackboxed after its ownership/closure contract moves.
catalog_expected_rtl_design_id="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit expected-rtl-design-id \
    --physical-configuration "${physical_configuration}"
)" || exit 2
live_rtl_design_id="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit live-rtl-design-id \
    --physical-configuration "${physical_configuration}"
)" || exit 2
if [[ "${catalog_expected_rtl_design_id}" != "${expected_rtl_design_id}" ||
      "${live_rtl_design_id}" != "${expected_rtl_design_id}" ]]; then
  printf '%s\n' '[TRACEABLE-MAPPED-CURRENT][FAIL] expected RTL design-id differs from registry contract' >&2
  exit 2
fi
read -r -a macro_lib_rel <<<"$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit macro-lib-files \
    --physical-configuration "${physical_configuration}"
)" || exit 2
blackbox_modules="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit mapped-blackbox-modules \
    --physical-configuration "${physical_configuration}"
)" || exit 2
mapped_artifact_profile="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit mapped-artifact-profile \
    --physical-configuration "${physical_configuration}"
)" || exit 2
inline_modules="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit inline-modules \
    --physical-configuration "${physical_configuration}"
)" || exit 2
keep_hierarchy_modules="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit keep-hierarchy-modules \
    --physical-configuration "${physical_configuration}"
)" || exit 2
std_lib_rel="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit standard-cell-lib \
    --physical-configuration "${physical_configuration}"
)" || exit 2
sdc_file_rel="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit sdc-file \
    --physical-configuration "${physical_configuration}"
)" || exit 2
opensta="$(
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit opensta-binary \
    --physical-configuration "${physical_configuration}"
)" || exit 2
[[ "${#macro_lib_rel[@]}" -gt 0 && -n "${blackbox_modules}" &&
   -n "${keep_hierarchy_modules}" ]] || exit 2
[[ "${mapped_artifact_profile}" == none ||
   "${mapped_artifact_profile}" == bpu-local-pht-v1 ||
   "${mapped_artifact_profile}" == fp-arith-children-v1 ]] || exit 2
[[ "${std_lib_rel}" =~ ^yosys-sta/.+\.lib$ &&
   "${sdc_file_rel}" =~ ^yosys-sta/.+\.sdc$ &&
   "${opensta}" =~ ^/ ]] || exit 2
std_lib="${repo_root}/${std_lib_rel}"
sdc_file="${repo_root}/${sdc_file_rel}"
for relative in "${macro_lib_rel[@]}"; do
  [[ "${relative}" =~ ^npc/rv64/syn/macro-lib/[A-Za-z0-9_.-]+\.lib$ ]] || exit 2
  macro_libs+=("${repo_root}/${relative}")
done
for input in "${opensta}" "${std_lib}" "${sdc_file}" "${macro_libs[@]}"; do
  if [[ -L "${input}" || ! -f "${input}" || ! -s "${input}" ]]; then
    printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][FAIL] unsafe macro input: ${input}" >&2
    exit 2
  fi
done

mkdir -- "${run_dir}" || exit 1
evidence_dir="${run_dir}/evidence/${evidence_id}"
status_path="${run_dir}/${evidence_id}.status"
runtime_base="${runtime_root}/${run_id}"
bpu_negative_slack_artifact="${evidence_dir}/opensta-bpu-negative-slack.tsv"
bpu_update_fanout_artifact="${evidence_dir}/opensta-bpu-update-fanout.tsv"
fp_negative_slack_artifact="${evidence_dir}/opensta-fp-negative-slack.tsv"
fp_internal_paths_artifact="${evidence_dir}/opensta-fp-internal-paths.rpt"
mkdir -p -- "${run_dir}/evidence" "${runtime_base}" \
  "$(dirname -- "${lock_path}")" || exit 1
exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[TRACEABLE-MAPPED-CURRENT][FAIL] RV64 engineering lane occupied' >&2
  exit 3
fi
mkdir -- "${evidence_dir}" || exit 1
evidence_dir_canonical="$(realpath -e -- "${evidence_dir}")" || exit 1
if [[ "${evidence_dir}" != /* || "${evidence_dir}" != "${evidence_dir_canonical}" ||
      -L "${evidence_dir}" ]]; then
  printf '%s\n' '[TRACEABLE-MAPPED-CURRENT][FAIL] evidence_dir is not absolute canonical non-alias' >&2
  exit 2
fi
runtime_dir="$(mktemp -d "${runtime_base}/run.XXXXXX")" || exit 1
trace_runtime="${runtime_dir}/traceable"
mkdir -- "${trace_runtime}" || exit 1

# shellcheck source=../../../../scripts/task-run-status.sh
source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1

cleanup_path() {
  local target=$1
  local resolved
  [[ -e "${target}" ]] || return 0
  resolved="$(realpath -m -- "${target}")" || return 1
  case "${resolved}" in
    "${trace_runtime}"|"${runtime_dir}") ;;
    *)
      printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][CLEANUP-REFUSED] ${resolved}" >&2
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
  size="$(stat -c '%s' "${source_path}")" || return 1
  if [[ "${size}" -le 262144 ]]; then
    cp -- "${source_path}" "${destination_path}"
  else
    {
      head -c 131072 "${source_path}"
      printf '\n[TRACEABLE-MAPPED-CURRENT] ... bounded middle omitted ...\n'
      tail -c 131072 "${source_path}"
    } >"${destination_path}"
  fi
}

production_manifest() {
  # filelist.mk 由后面的显式输入统一收录，避免目录枚举与固定清单产生重复身份。
  find "${repo_root}/npc/rv64/vsrc" "${repo_root}/npc/rv64/csrc" \
    -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o \
      -name '*.svh' -o -name '*.cpp' -o -name '*.cc' -o -name '*.c' -o \
      -name '*.h' -o -name '*.hpp' -o -name '*.mk' \) \
    ! -path "${repo_root}/npc/rv64/vsrc/filelist.mk" -print0 |
    sort -z | xargs -0 sha256sum
  sha256sum "${repo_root}/npc/rv64/.config" \
    "${repo_root}/npc/rv64/include/generated/autoconf.h" \
    "${repo_root}/npc/rv64/include/config/auto.conf" \
    "${repo_root}/npc/rv64/Makefile" "${repo_root}/npc/rv64/vsrc/filelist.mk" \
    "${repo_root}/yosys-sta/Makefile" "${repo_root}/yosys-sta/scripts/yosys.tcl" \
    "${repo_root}/yosys-sta/scripts/common.tcl" \
    "${repo_root}/yosys-sta/scripts/pdk/icsprout55.tcl" \
    "${repo_root}/oss-cad-suite/bin/yosys" \
    "${repo_root}/oss-cad-suite/bin/yosys-abc" \
    "${opensta}" "${std_lib}" "${sdc_file}" "${macro_libs[@]}" "${parser}" \
    "${sta_tcl}" "${trace_checker}" "${architecture_registry}" "${runner_path}"
  # architecture_catalog 由去除 evidence pointer 的 policy/configuration 哈希绑定。
}

write_source_manifest() {
  local output=$1
  local rtl_line
  local -a rtl_files
  rtl_line="$(make -s -C "${repo_root}/npc/rv64" print-synth-rtl)" || return 1
  read -r -a rtl_files <<<"${rtl_line}"
  [[ "${#rtl_files[@]}" -ge 120 ]] || return 1
  sha256sum "${rtl_files[@]}" >"${output}"
}

write_parameters() {
  local output=$1
  local result_root=$2
  python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
    emit run-parameters \
    --physical-configuration "${physical_configuration}" \
    --expected-rtl-design-id "${expected_rtl_design_id}" \
    --result-root "${result_root}" >"${output}"
}

task_run_status_stage preflight
preflight_rc=0
task_run_status_stage production-manifest-before
production_manifest >"${evidence_dir}/production-manifest-before.sha256"
manifest_rc=$?

result_root="${trace_runtime}/sta"
mapped_dir="${result_root}/NpcTop-200MHz"
netlist="${mapped_dir}/NpcTop.netlist.v"
synth_console="${trace_runtime}/synth-console.full.log"
source_manifest="${evidence_dir}/synthesis-sources.sha256"
parameters="${evidence_dir}/parameters.txt"
input_manifest="${evidence_dir}/sta-inputs.sha256"

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
      STA_SDC_FILE="${sdc_file}" \
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

if [[ "${synth_rc}" -eq 0 && -s "${netlist}" &&
      -s "${mapped_dir}/synth_check.txt" && -s "${mapped_dir}/synth_stat.txt" &&
      -s "${mapped_dir}/sta_export_check.txt" ]] &&
   grep -Fq 'Found and reported 0 problems.' "${mapped_dir}/synth_check.txt" &&
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
  macro_joined="$(IFS=:; printf '%s' "${macro_libs[*]}")"
  sha256sum "${netlist}" "${source_manifest}" "${parameters}" "${std_lib}" \
    "${sdc_file}" \
    "${macro_libs[@]}" "${opensta}" "${sta_tcl}" "${parser}" \
    "${trace_checker}" \
    >"${input_manifest}"
  task_run_status_stage traceable-opensta-exact5ns
  opensta_rc=0
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s 1200s \
    /usr/bin/env V15P_STA_NETLIST="${netlist}" \
      V15P_STA_OUT_DIR="${evidence_dir}" V15P_STA_STD_LIB="${std_lib}" \
      V15P_STA_MACRO_LIBS="${macro_joined}" V15P_STA_PERIOD_NS=5.0 \
      V15P_STA_EXPECTED_MACRO_LIB_COUNT="${#macro_libs[@]}" \
      V15P_STA_MAPPED_ARTIFACT_PROFILE="${mapped_artifact_profile}" \
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
  if [[ "${opensta_rc}" -eq 0 &&
        -s "${evidence_dir}/opensta-complete.txt" ]]; then
    case "${mapped_artifact_profile}" in
      none)
        [[ ! -e "${bpu_negative_slack_artifact}" &&
           ! -L "${bpu_negative_slack_artifact}" &&
           ! -e "${bpu_update_fanout_artifact}" &&
           ! -L "${bpu_update_fanout_artifact}" &&
           ! -e "${fp_negative_slack_artifact}" &&
           ! -L "${fp_negative_slack_artifact}" &&
           ! -e "${fp_internal_paths_artifact}" &&
           ! -L "${fp_internal_paths_artifact}" ]] || opensta_rc=1
        ;;
      bpu-local-pht-v1)
        [[ -s "${bpu_negative_slack_artifact}" &&
           ! -L "${bpu_negative_slack_artifact}" &&
           -s "${bpu_update_fanout_artifact}" &&
           ! -L "${bpu_update_fanout_artifact}" &&
           ! -e "${fp_negative_slack_artifact}" &&
           ! -L "${fp_negative_slack_artifact}" &&
           ! -e "${fp_internal_paths_artifact}" &&
           ! -L "${fp_internal_paths_artifact}" ]] || opensta_rc=1
        ;;
      fp-arith-children-v1)
        [[ -s "${fp_negative_slack_artifact}" &&
           ! -L "${fp_negative_slack_artifact}" &&
           -s "${fp_internal_paths_artifact}" &&
           ! -L "${fp_internal_paths_artifact}" &&
           ! -e "${bpu_negative_slack_artifact}" &&
           ! -L "${bpu_negative_slack_artifact}" &&
           ! -e "${bpu_update_fanout_artifact}" &&
           ! -L "${bpu_update_fanout_artifact}" ]] || opensta_rc=1
        ;;
      *) opensta_rc=1 ;;
    esac
  else
    opensta_rc=1
  fi
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
    --expected-macro-lib-count "${#macro_libs[@]}" \
    --expected-unknown-macro-modules "${blackbox_modules}" \
    --mapped-artifact-profile "${mapped_artifact_profile}" \
    --output "${evidence_dir}/summary.json" \
    >"${evidence_dir}/parser.log" 2>&1
  parser_rc=$?
fi

if [[ "${parser_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-name-check
  python3 -B "${trace_checker}" \
    --report "${evidence_dir}/opensta-top40.rpt" \
    --output "${evidence_dir}/traceability.txt" \
    --expected-paths 40 >"${evidence_dir}/traceability-check.log" 2>&1
  trace_rc=$?
fi

if [[ "${trace_rc}" -eq 0 ]]; then
  task_run_status_stage traceable-runtime-cleanup
  deleted_bytes="$(du -sb "${trace_runtime}" | awk '{print $1}')"
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

if [[ "${manifest_rc}" -eq 0 ]]; then
  task_run_status_stage architecture-registry-binding
  python3 -B "${architecture_registry}" --catalog "${architecture_catalog}" \
    stamp-mapped-summary \
    --physical-configuration "${physical_configuration}" \
    --expected-rtl-design-id "${expected_rtl_design_id}" \
    --summary "${evidence_dir}/summary.json" \
    --source-manifest "${source_manifest}" \
    --parameters "${parameters}" \
    --sta-input-manifest "${input_manifest}" \
    --synth-stat "${evidence_dir}/synth_stat.txt" \
    --production-manifest-before \
      "${evidence_dir}/production-manifest-before.sha256" \
    --production-manifest-after \
      "${evidence_dir}/production-manifest-after.sha256" \
    --mapped-artifact-profile "${mapped_artifact_profile}" \
    --blackbox-modules "${blackbox_modules}" \
    --inline-modules "${inline_modules}" \
    --macro-lib-files "${macro_lib_rel[*]}" \
    >"${evidence_dir}/architecture-registry-binding.log" 2>&1
  binding_rc=$?
fi

cleanup_runtime || cleanup_rc=$?
[[ ! -e "${runtime_dir}" ]] || cleanup_rc=1
rmdir --ignore-fail-on-non-empty "${runtime_base}" 2>/dev/null || true
if [[ "${preflight_rc}" -eq 0 && "${manifest_rc}" -eq 0 &&
      "${synth_rc}" -eq 0 && "${opensta_rc}" -eq 0 &&
      "${parser_rc}" -eq 0 && "${trace_rc}" -eq 0 &&
      "${binding_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
      "${deleted_bytes}" -gt 0 &&
      -s "${evidence_dir}/summary.json" ]]; then
  command_rc=0
fi
printf '%s\n' \
  "preflight_rc=${preflight_rc}" "manifest_rc=${manifest_rc}" \
  "synth_rc=${synth_rc}" "opensta_rc=${opensta_rc}" \
  "parser_rc=${parser_rc}" "trace_rc=${trace_rc}" \
  "binding_rc=${binding_rc}" "cleanup_rc=${cleanup_rc}" \
  "runtime_bytes_deleted=${deleted_bytes}" \
  >"${evidence_dir}/command-status.txt"

task_run_status_stage evidence-complete
if [[ "${command_rc}" -eq 0 && ! -e "${runtime_dir}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
set +e
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
final_rc=$?
set -e
if [[ "${final_rc}" -eq 0 ]]; then
  printf '%s\n' "[TRACEABLE-MAPPED-CURRENT][PASS] run=${run_id} evidence=${evidence_id}"
  exit 0
fi
exit "${final_rc}"
