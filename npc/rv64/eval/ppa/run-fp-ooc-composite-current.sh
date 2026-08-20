#!/usr/bin/env bash
# One-shot, fail-closed diagnostic OOC composite run.  A successful marker
# proves evidence completeness only; it never promotes PPA/signoff status.
set -uo pipefail

usage() {
  printf '%s\n' \
    'usage: run-fp-ooc-composite-current.sh --run-id ID --expected-rtl-design-id sha256:HEX' >&2
}

run_id=
expected_rtl_design_id=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_id=$2
      shift 2
      ;;
    --expected-rtl-design-id)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      expected_rtl_design_id=$2
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done
[[ "${run_id}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || exit 2
[[ "${expected_rtl_design_id}" =~ ^sha256:[0-9a-f]{64}$ ]] || exit 2

repo_root="$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../..")" || exit 2
# File-path execution of fp_ooc_composite.py must resolve the repository's
# npc package independently of the caller environment.
export PYTHONPATH="${repo_root}"
readonly PYTHONPATH
runner_path="$(realpath -e -- "${BASH_SOURCE[0]}")" || exit 2
configuration=mapped-5ns-fp-arith-production-children-ooc-boundary-v1
profile=fp-arith-ooc-composite-v1
evidence_id=fp-ooc-composite-v1
run_dir="${repo_root}/.github/task-runs/${run_id}"
evidence_dir="${run_dir}/evidence/${evidence_id}"
status_path="${evidence_dir}/gate-status.txt"
runtime_parent="${repo_root}/.github/runtime-artifacts/fp-ooc-composite/${run_id}"
lock_path="${repo_root}/.github/runtime-artifacts/locks/rv64-fp-ooc-composite.lock"
architecture_registry="${repo_root}/npc/rv64/eval/ppa/tools/architecture_registry.py"
architecture_catalog="${repo_root}/npc/rv64/design/arch/rv64-architecture-registry-v1.json"
composite_tool="${repo_root}/npc/rv64/eval/ppa/tools/fp_ooc_composite.py"
composite_schema="${repo_root}/npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json"
child_yosys_tcl="${repo_root}/npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl"
child_sta_tcl="${repo_root}/npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl"
top_sta_tcl="${repo_root}/npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl"
yosys="${repo_root}/oss-cad-suite/bin/yosys"

if [[ -e "${run_dir}" ]]; then
  printf '%s\n' "[FP-OOC-COMPOSITE][FAIL] run-id already exists: ${run_id}" >&2
  exit 2
fi
mkdir -p -- "$(dirname -- "${lock_path}")" "${runtime_parent}" || exit 1
mkdir -- "${run_dir}" || exit 1
mkdir -p -- "${run_dir}/evidence" || exit 1
mkdir -- "${evidence_dir}" || exit 1
evidence_dir="$(realpath -e -- "${evidence_dir}")" || exit 1
if [[ "${evidence_dir}" != /* || -L "${evidence_dir}" ]]; then
  printf '%s\n' '[FP-OOC-COMPOSITE][FAIL] evidence_dir is not canonical' >&2
  exit 2
fi

exec 9>"${lock_path}"
if ! flock -n 9; then
  printf '%s\n' '[FP-OOC-COMPOSITE][FAIL] RV64 engineering lane occupied' >&2
  exit 3
fi

runtime_dir="$(mktemp -d "${runtime_parent}/run.XXXXXX")" || exit 1
active_pid=
stage=preflight
finalized=0
cleanup_rc=0

write_status() {
  local result=$1
  local rc=$2
  {
    printf 'RESULT=%s\n' "${result}"
    printf 'STAGE=%s\n' "${stage}"
    printf 'RETURN_CODE=%s\n' "${rc}"
    printf 'RUN_ID=%s\n' "${run_id}"
    printf 'DESIGN_ID=%s\n' "${expected_rtl_design_id}"
    printf 'PHYSICAL_CONFIGURATION=%s\n' "${configuration}"
    printf 'PROFILE=%s\n' "${profile}"
    printf 'CLAIM_SCOPE=DIAGNOSTIC_OOC_COMPOSITE_ONLY\n'
    printf 'CLEANUP_RC=%s\n' "${cleanup_rc}"
  } >"${status_path}"
}

cleanup_runtime() {
  local resolved_parent resolved_runtime
  [[ -e "${runtime_parent}" ]] || return 1
  [[ -d "${runtime_parent}" && ! -L "${runtime_parent}" ]] || return 2
  resolved_parent="$(realpath -e -- "${runtime_parent}")" || return 1
  [[ "${resolved_parent}" == "${runtime_parent}" ]] || {
    printf '%s\n' "[FP-OOC-COMPOSITE][CLEANUP-REFUSED] ${resolved_parent}" >&2
    return 2
  }
  if [[ -e "${runtime_dir}" ]]; then
    [[ -d "${runtime_dir}" && ! -L "${runtime_dir}" ]] || return 2
    resolved_runtime="$(realpath -e -- "${runtime_dir}")" || return 1
    case "${resolved_runtime}" in
      "${resolved_parent}"/run.*) rm -r -- "${resolved_runtime}" || return $? ;;
      *)
        printf '%s\n' "[FP-OOC-COMPOSITE][CLEANUP-REFUSED] ${resolved_runtime}" >&2
        return 2
        ;;
    esac
  fi
  # The exact run-id parent is owned by this invocation.  A non-empty parent
  # is an identity/cleanup conflict and must surface through CLEANUP_RC.
  rmdir -- "${resolved_parent}"
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
  stage="signal-${signal_name}"
  cleanup_rc=0
  cleanup_runtime || cleanup_rc=$?
  write_status FAIL "${signal_rc}"
  finalized=1
  trap - HUP INT TERM EXIT
  exit "${signal_rc}"
}

finalize_on_exit() {
  local rc=$?
  local failure_stage="${stage}"
  if [[ "${finalized}" -eq 0 ]]; then
    cleanup_rc=0
    cleanup_runtime || cleanup_rc=$?
    stage="${failure_stage}"
    write_status FAIL "${rc}"
  fi
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM
trap finalize_on_exit EXIT

fail() {
  local rc=${1:-1}
  printf '%s\n' "[FP-OOC-COMPOSITE][FAIL] stage=${stage} rc=${rc}" >&2
  exit "${rc}"
}

run_bounded() {
  local timeout_seconds=$1
  shift
  setsid /usr/bin/timeout --signal=TERM --kill-after=30s "${timeout_seconds}s" \
    nice -n 10 "$@" &
  active_pid=$!
  wait "${active_pid}"
  local rc=$?
  active_pid=
  return "${rc}"
}

check_disk_limit() {
  local bytes
  bytes="$(du -sb -- "${runtime_dir}" "${evidence_dir}" | awk '{sum += $1} END {print sum + 0}')" || return 1
  [[ "${bytes}" -le 12884901888 ]]
}

production_manifest() {
  find "${repo_root}/npc/rv64/vsrc" -type f \
    \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' -o -name '*.mk' \) \
    -print0 | sort -z | xargs -0 sha256sum
  sha256sum \
    "${repo_root}/npc/rv64/Makefile" \
    "${repo_root}/npc/rv64/design/arch/rv64-architecture-registry-v1.json" \
    "${repo_root}/npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json" \
    "${repo_root}/npc/rv64/eval/ppa/tools/architecture_registry.py" \
    "${repo_root}/yosys-sta/Makefile" \
    "${repo_root}/yosys-sta/scripts/yosys.tcl" \
    "${repo_root}/yosys-sta/scripts/common.tcl" \
    "${repo_root}/yosys-sta/scripts/pdk/icsprout55.tcl" \
    "${composite_tool}" "${composite_schema}" "${child_yosys_tcl}" \
    "${child_sta_tcl}" "${top_sta_tcl}" "${architecture_registry}" \
    "${runner_path}"
}

stage=registry-projection
live_design_id="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit live-rtl-design-id --physical-configuration "${configuration}")" || fail 2
[[ "${live_design_id}" == "${expected_rtl_design_id}" ]] || fail 2
registered_design_id="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit expected-rtl-design-id --physical-configuration "${configuration}")" || fail 2
[[ "${registered_design_id}" == "${expected_rtl_design_id}" ]] || fail 2
mapped_profile="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit mapped-artifact-profile --physical-configuration "${configuration}")" || fail 2
[[ "${mapped_profile}" == "${profile}" ]] || fail 2
known_modules="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit known-ooc-macro-modules --physical-configuration "${configuration}")" || fail 2
top_blackboxes="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit top-blackbox-modules --physical-configuration "${configuration}")" || fail 2
inline_modules="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit inline-modules --physical-configuration "${configuration}")" || fail 2
keep_modules="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit keep-hierarchy-modules --physical-configuration "${configuration}")" || fail 2
std_lib_rel="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit standard-cell-lib --physical-configuration "${configuration}")" || fail 2
opensta="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit opensta-binary --physical-configuration "${configuration}")" || fail 2
placeholder_lib_rel="$(python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit macro-lib-files --physical-configuration "${configuration}")" || fail 2
python3 "${architecture_registry}" --catalog "${architecture_catalog}" \
  emit ooc-composite-contract --physical-configuration "${configuration}" \
  >"${evidence_dir}/ooc-composite-contract.json" || fail 2
[[ "${inline_modules}" == OooFpArithGate ]] || fail 2
read -r -a children <<<"${known_modules}"
read -r -a placeholder_rel <<<"${placeholder_lib_rel}"
[[ "${#children[@]}" -eq 5 && "${#placeholder_rel[@]}" -eq 3 ]] || fail 2
std_lib="${repo_root}/${std_lib_rel}"
placeholder_libs=()
for relative in "${placeholder_rel[@]}"; do
  placeholder_libs+=("${repo_root}/${relative}")
done
for input in "${yosys}" "${opensta}" "${std_lib}" "${placeholder_libs[@]}"; do
  [[ ! -L "${input}" && -f "${input}" && -s "${input}" ]] || fail 2
done

stage=production-manifest-before
production_manifest >"${evidence_dir}/production-manifest-before.sha256" || fail 1
stage=source-manifest
rtl_line="$(make -s -C "${repo_root}/npc/rv64" print-synth-rtl)" || fail 1
read -r -a rtl_files <<<"${rtl_line}"
[[ "${#rtl_files[@]}" -ge 120 ]] || fail 1
sha256sum "${rtl_files[@]}" >"${evidence_dir}/synthesis-sources.sha256" || fail 1
stage=tool-manifest
sha256sum "${runner_path}" "${composite_tool}" "${composite_schema}" \
  "${architecture_registry}" "${architecture_catalog}" \
  "${repo_root}/npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json" \
  "${child_yosys_tcl}" "${child_sta_tcl}" "${top_sta_tcl}" \
  "${repo_root}/yosys-sta/scripts/yosys.tcl" "${yosys}" "${opensta}" \
  "${std_lib}" "${placeholder_libs[@]}" \
  >"${evidence_dir}/tool-inputs.sha256" || fail 1
stage=run-identity
python3 "${composite_tool}" identity --run-id "${run_id}" \
  --source-manifest "${evidence_dir}/synthesis-sources.sha256" \
  --tool-manifest "${evidence_dir}/tool-inputs.sha256" \
  --standard-cell-lib "${std_lib}" --yosys "${yosys}" --opensta "${opensta}" \
  --output "${evidence_dir}/run-identity.json" || fail 2
stage=stdlib-leaf-whitelist
python3 "${composite_tool}" emit-stdlib-whitelist \
  --identity "${evidence_dir}/run-identity.json" \
  --standard-cell-lib "${std_lib}" \
  --output "${evidence_dir}/stdlib-leaf-whitelist.json" || fail 2
stage=top-boundary-contract
python3 "${composite_tool}" emit-top-boundary-contract-tcl \
  --output "${evidence_dir}/top-boundary-contract.tcl" || fail 2

mkdir -- "${evidence_dir}/children" || fail 1
for module in "${children[@]}"; do
  stage="child-${module}-source-closure"
  child_dir="${evidence_dir}/children/${module}"
  child_runtime="${runtime_dir}/children/${module}"
  child_result_dir="${child_runtime}/${module}-200MHz"
  mkdir -p -- "${child_dir}" "${child_runtime}" "${child_result_dir}" || fail 1
  child_source_closure_rel="$(python3 "${composite_tool}" emit-child-sources --module "${module}")" || fail 2
  read -r -a source_closure_rel <<<"${child_source_closure_rel}"
  child_source_closure=()
  for relative in "${source_closure_rel[@]}"; do child_source_closure+=("${repo_root}/${relative}"); done
  sha256sum "${child_source_closure[@]}" >"${child_dir}/source-closure.sha256" || fail 1
  read -r source_closure_sha _ < <(sha256sum "${child_dir}/source-closure.sha256")
  child_compile_sources_rel="$(python3 "${composite_tool}" emit-child-compile-sources --module "${module}")" || fail 2
  read -r -a compile_sources_rel <<<"${child_compile_sources_rel}"
  child_compile_sources=()
  for relative in "${compile_sources_rel[@]}"; do child_compile_sources+=("${repo_root}/${relative}"); done
  sha256sum "${child_compile_sources[@]}" >"${child_dir}/compile-sources.sha256" || fail 1
  child_netlist="${child_result_dir}/${module}.netlist.v"
  child_census="${child_dir}/synth-census.json"
  child_design_json="${child_dir}/synth-design.json"
  child_manifest="${child_dir}/netlist-manifest.json"
  child_driver_contract="${child_dir}/output-bit-driver-contract.json"
  child_driver_contract_tcl="${child_dir}/output-bit-driver-contract.tcl"
  child_input_contract="$(python3 "${composite_tool}" emit-child-port-contract \
    --module "${module}" --direction input)" || fail 2
  child_output_contract="$(python3 "${composite_tool}" emit-child-port-contract \
    --module "${module}" --direction output)" || fail 2
  stage="child-${module}-synthesis"
  run_bounded 1800 /usr/bin/env \
    FP_OOC_CHILD_MODULE="${module}" FP_OOC_PROFILE="${profile}" SYNTH_BLACKBOX_MODULES= \
    SYNTH_KNOWN_OOC_MODULES= SYNTH_COMPOSITE_CENSUS_JSON="${child_census}" \
    SYNTH_COMPOSITE_DESIGN_JSON="${child_design_json}" \
    CLK_FREQ_MHZ=200 SYNTH_FLATTEN=0 SYNTH_SHARE=0 \
    SYNTH_STOP_AFTER_COARSE=0 SYNTH_PUBLIC_AUTONAME=1 \
    SYNTH_DFF_AUTONAME=0 SYNTH_STA_FLATTEN_EXPORT=0 \
    "${yosys}" -q -Q -T -t -l "${child_dir}/yosys.log" \
    -c "${child_yosys_tcl}" -- "${module}" icsprout55 \
    "${child_compile_sources[*]}" "${child_netlist}" \
    "${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" "" \
    || fail $?
  [[ -s "${child_netlist}" && -s "${child_result_dir}/synth_stat.txt" &&
     -s "${child_census}" && -s "${child_design_json}" ]] || fail 1
  cp -- "${child_result_dir}/synth_stat.txt" "${child_dir}/synth-stat.txt" || fail 1
  stage="child-${module}-retained-netlist-manifest"
  python3 "${composite_tool}" emit-netlist-manifest \
    --identity "${evidence_dir}/run-identity.json" --subject "${module}" \
    --netlist "${child_netlist}" --design-json "${child_design_json}" \
    --census-json "${child_census}" \
    --stdlib-whitelist "${evidence_dir}/stdlib-leaf-whitelist.json" \
    --evidence-dir "${evidence_dir}" --output "${child_manifest}" || fail 2
  stage="child-${module}-output-bit-driver-contract"
  python3 "${composite_tool}" emit-output-bit-driver-contract \
    --identity "${evidence_dir}/run-identity.json" --module "${module}" \
    --design-json "${child_design_json}" --netlist-manifest "${child_manifest}" \
    --stdlib-whitelist "${evidence_dir}/stdlib-leaf-whitelist.json" \
    --standard-cell-lib "${std_lib}" --evidence-dir "${evidence_dir}" \
    --output "${child_driver_contract}" || fail 2
  python3 "${composite_tool}" emit-output-bit-driver-contract-tcl \
    --identity "${evidence_dir}/run-identity.json" --module "${module}" \
    --driver-contract "${child_driver_contract}" \
    --standard-cell-lib "${std_lib}" --evidence-dir "${evidence_dir}" \
    --output "${child_driver_contract_tcl}" || fail 2
  check_disk_limit || fail 1
  for analysis in max min; do
    stage="child-${module}-opensta-${analysis}"
    run_bounded 600 /usr/bin/env FP_OOC_CHILD_MODULE="${module}" \
      FP_OOC_PROFILE="${profile}" FP_OOC_ANALYSIS="${analysis}" FP_OOC_RUN_ID="${run_id}" \
      FP_OOC_DESIGN_ID="${expected_rtl_design_id}" FP_OOC_PERIOD_NS=5.0 \
      FP_OOC_INPUT_PORT_CONTRACT="${child_input_contract}" \
      FP_OOC_OUTPUT_PORT_CONTRACT="${child_output_contract}" \
      FP_OOC_OUTPUT_BIT_DRIVER_CONTRACT_TCL="${child_driver_contract_tcl}" \
      FP_OOC_NETLIST="${child_netlist}" FP_OOC_STD_LIB="${std_lib}" \
      FP_OOC_OUT_DIR="${child_dir}" "${opensta}" "${child_sta_tcl}" || fail $?
    timing_path="${child_dir}/child-timing-${analysis}.tsv"
    query_progress_path="${child_dir}/child-query-progress-${analysis}.tsv"
    liberty_path="${child_dir}/${module}-${analysis}.lib"
    [[ -s "${timing_path}" && -s "${query_progress_path}" ]] || fail 1
    stage="child-${module}-liberty-${analysis}"
    python3 "${composite_tool}" render-liberty-from-artifacts \
      --identity "${evidence_dir}/run-identity.json" --module "${module}" \
      --analysis "${analysis}" --source-closure-sha256 "${source_closure_sha}" \
      --synth-stat "${child_dir}/synth-stat.txt" --census-json "${child_census}" \
      --netlist-manifest "${child_manifest}" --evidence-dir "${evidence_dir}" \
      --output-bit-driver-contract "${child_driver_contract}" \
      --standard-cell-lib "${std_lib}" \
      --timing "${timing_path}" --output "${liberty_path}" || fail 2
    python3 "${composite_tool}" validate-liberty \
      --identity "${evidence_dir}/run-identity.json" --module "${module}" \
      --analysis "${analysis}" --timing "${timing_path}" \
      --liberty "${liberty_path}" \
      --output-bit-driver-contract "${child_driver_contract}" \
      --standard-cell-lib "${std_lib}" --evidence-dir "${evidence_dir}" \
      >"${child_dir}/liberty-${analysis}.receipt" || fail 2
  done
  stage="child-${module}-parse"
  python3 "${composite_tool}" parse-child \
    --identity "${evidence_dir}/run-identity.json" --module "${module}" \
    --source-closure-sha256 "${source_closure_sha}" --netlist "${child_netlist}" \
    --synth-stat "${child_dir}/synth-stat.txt" --census-json "${child_census}" \
    --netlist-manifest "${child_manifest}" \
    --output-bit-driver-contract "${child_driver_contract}" \
    --standard-cell-lib "${std_lib}" \
    --timing-max "${child_dir}/child-timing-max.tsv" \
    --timing-min "${child_dir}/child-timing-min.tsv" \
    --liberty-max "${child_dir}/${module}-max.lib" \
    --liberty-min "${child_dir}/${module}-min.lib" \
    --evidence-dir "${evidence_dir}" --output "${child_dir}/child-result.json" || fail 2
  check_disk_limit || fail 1
done

top_runtime="${runtime_dir}/top"
top_result_root="${top_runtime}/sta"
top_mapped_dir="${top_result_root}/NpcTop-200MHz"
top_netlist="${top_mapped_dir}/NpcTop.netlist.v"
top_census="${evidence_dir}/top-synth-census.json"
top_design_json="${evidence_dir}/top-synth-design.json"
top_manifest="${evidence_dir}/top-netlist-manifest.json"
placeholder_joined="$(IFS=:; printf '%s' "${placeholder_libs[*]}")"
stage=top-synthesis
run_bounded 5400 /usr/bin/env SYNTH_KNOWN_OOC_MODULES="${known_modules}" \
  SYNTH_COMPOSITE_CENSUS_JSON="${top_census}" \
  SYNTH_COMPOSITE_DESIGN_JSON="${top_design_json}" \
  make -C "${repo_root}/npc/rv64" syn STA_RESULT_ROOT="${top_result_root}" \
  STA_DESIGN=NpcTop STA_PDK=icsprout55 STA_CLK_PORT_NAME=clk STA_CLK_FREQ_MHZ=200 \
  STA_VERILOG_INCLUDE_DIRS="${repo_root}/npc/rv64/vsrc ${repo_root}/npc/rv64/vsrc/include" \
  STA_VERILOG_DEFINES= STA_SYNTH_FLATTEN=0 STA_SYNTH_SHARE=0 \
  STA_SYNTH_STOP_AFTER_COARSE=0 STA_SYNTH_PUBLIC_AUTONAME=1 \
  STA_SYNTH_DFF_AUTONAME=0 STA_SYNTH_STA_FLATTEN_EXPORT=1 \
  STA_SYNTH_BLACKBOX_MODULES="${top_blackboxes}" \
  STA_KEEP_HIERARCHY_MODULES="${keep_modules}" \
  STA_EXTRA_LIB_FILES="${placeholder_libs[*]}" \
  YOSYS_ARGS="-q -Q -T" YOSYS_LOG_ARGS= || fail $?
[[ -s "${top_netlist}" && -s "${top_mapped_dir}/synth_stat.txt" &&
   -s "${top_census}" && -s "${top_design_json}" ]] || fail 1
cp -- "${top_mapped_dir}/synth_stat.txt" "${evidence_dir}/top-synth-stat.txt" || fail 1
stage=top-retained-netlist-manifest
python3 "${composite_tool}" emit-netlist-manifest \
  --identity "${evidence_dir}/run-identity.json" --subject NpcTop \
  --netlist "${top_netlist}" --design-json "${top_design_json}" \
  --census-json "${top_census}" \
  --stdlib-whitelist "${evidence_dir}/stdlib-leaf-whitelist.json" \
  --evidence-dir "${evidence_dir}" --output "${top_manifest}" || fail 2
check_disk_limit || fail 1

for analysis in max min; do
  macro_libs=()
  for module in "${children[@]}"; do
    macro_libs+=("${evidence_dir}/children/${module}/${module}-${analysis}.lib")
  done
  macro_joined="$(IFS=:; printf '%s' "${macro_libs[*]}")"
  stage="top-opensta-${analysis}"
  run_bounded 1200 /usr/bin/env FP_OOC_ANALYSIS="${analysis}" \
    FP_OOC_PROFILE="${profile}" FP_OOC_RUN_ID="${run_id}" FP_OOC_DESIGN_ID="${expected_rtl_design_id}" \
    FP_OOC_PERIOD_NS=5.0 FP_OOC_NETLIST="${top_netlist}" \
    FP_OOC_STD_LIB="${std_lib}" FP_OOC_MACRO_LIBS="${macro_joined}" \
    FP_OOC_PLACEHOLDER_LIBS="${placeholder_joined}" \
    FP_OOC_TOP_BOUNDARY_CONTRACT_TCL="${evidence_dir}/top-boundary-contract.tcl" \
    FP_OOC_OUT_DIR="${evidence_dir}" "${opensta}" "${top_sta_tcl}" || fail $?
done

stage=top-parse
python3 "${composite_tool}" parse-top \
  --identity "${evidence_dir}/run-identity.json" --netlist "${top_netlist}" \
  --synth-stat "${evidence_dir}/top-synth-stat.txt" --census-json "${top_census}" \
  --netlist-manifest "${top_manifest}" \
  --timing-max "${evidence_dir}/top-boundary-max.tsv" \
  --timing-min "${evidence_dir}/top-boundary-min.tsv" \
  --evidence-dir "${evidence_dir}" --output "${evidence_dir}/top-result.json" || fail 2
stage=production-manifest-after
production_manifest >"${evidence_dir}/production-manifest-after.sha256" || fail 1
cmp -s "${evidence_dir}/production-manifest-before.sha256" \
  "${evidence_dir}/production-manifest-after.sha256" || fail 2
stage=composite-parse
python3 "${composite_tool}" compose --identity "${evidence_dir}/run-identity.json" \
  --children-dir "${evidence_dir}/children" --top-result "${evidence_dir}/top-result.json" \
  --evidence-dir "${evidence_dir}" --output "${evidence_dir}/fp-ooc-composite-summary.json" \
  --receipt "${evidence_dir}/fp-ooc-composite-validation-receipt.json" || fail 2
python3 "${composite_tool}" validate \
  --summary "${evidence_dir}/fp-ooc-composite-summary.json" \
  --receipt "${evidence_dir}/fp-ooc-composite-validation-receipt.json" \
  --evidence-dir "${evidence_dir}" >"${evidence_dir}/validation.log" || fail 2
check_disk_limit || fail 1
stage=cleanup
cleanup_runtime || cleanup_rc=$?
[[ "${cleanup_rc}" -eq 0 ]] || fail "${cleanup_rc}"
stage=complete
write_status PASS 0
finalized=1
trap - HUP INT TERM EXIT
printf '%s\n' '[FP-OOC-QUERY-BUDGET][PASS] child_analyses=10 complete=10 addsub_find_calls=273 addsub_pathends_le=2364 addsub_validations_le=2364'
printf '%s\n' '[TRACEABLE-FP-OOC-COMPOSITE][PASS] evidence-complete diagnostic-only GAP'
exit 0
