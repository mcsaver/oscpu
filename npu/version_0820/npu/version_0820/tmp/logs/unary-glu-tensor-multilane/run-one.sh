#!/usr/bin/env bash

set -uo pipefail

repo_root="/home/lyg/PA/ysyx-workbench"
evidence_root="${repo_root}/npu/version_0820/tmp/logs/unary-glu-tensor-multilane"
build_root="${repo_root}/npu/version_0820/tmp/build/unary-glu-tensor-multilane"
compiler_root="${repo_root}/npu/version_0820/tmp/compiler/unary-glu-tensor-multilane"
cache_root="${repo_root}/npu/version_0820/tmp/cache/unary-glu-tensor-multilane"
filelist="${evidence_root}/sources.f"
waiver_file="${evidence_root}/locked-third-party.vlt"
status_lib="${repo_root}/scripts/task-run-status.sh"

if [[ "$#" -ne 1 || ( "$1" != "4" && "$1" != "8" ) ]]; then
  printf '%s\n' "usage: $0 {4|8}" >&2
  exit 2
fi
lanes="$1"
config_name="L${lanes}"
config_root="${evidence_root}/${config_name}"
build_dir="${build_root}/${config_name}"
compiler_dir="${compiler_root}/${config_name}"
cache_dir="${cache_root}/${config_name}"
status_path="${config_root}/status.txt"
build_log="${config_root}/verilator-build.log"
run_log="${config_root}/tb-run.log"
binary="${build_dir}/tb_unary_glu_tensor_multilane_L${lanes}"
command_rc=0
cleanup_rc=0

if [[ "$(pwd -P)" != "${repo_root}" ]]; then
  printf '%s\n' "[multilane-runner] repository root mismatch: $(pwd -P)" >&2
  exit 2
fi

mkdir -p "${config_root}" "${build_dir}" "${compiler_dir}" "${cache_dir}"

# shellcheck source=/dev/null
source "${status_lib}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

runner_finish() {
  local shell_rc="$?"
  local final_rc
  trap - EXIT
  if [[ "${command_rc}" -eq 0 && "${shell_rc}" -ne 0 ]]; then
    command_rc="${shell_rc}"
  fi
  task_run_status_stage cleanup
  if [[ -d "${compiler_dir}" ]]; then
    case "$(realpath -m -- "${compiler_dir}")" in
      "${compiler_root}"/L4|"${compiler_root}"/L8)
        rm -rf -- "${compiler_dir}" || cleanup_rc=$?
        ;;
      *)
        printf '%s\n' "[multilane-runner] refusing unsafe cleanup: ${compiler_dir}" >&2
        cleanup_rc=97
        ;;
    esac
  fi
  printf '%s\n' "${cleanup_rc}" >"${config_root}/cleanup.rc"
  task_run_status_finalize "${command_rc}" "${cleanup_rc}"
  final_rc=$?
  exit "${final_rc}"
}
trap runner_finish EXIT

fail_stage() {
  local rc="$1"
  local stage="$2"
  shift 2
  command_rc="${rc}"
  task_run_status_stage "${stage}"
  printf '%s\n' "[multilane-runner][${config_name}][FAIL] $*" >&2
  exit "${rc}"
}

task_run_status_stage identity
if [[ -e "${config_root}/sealed-receipt.txt" || -e "${binary}" ]]; then
  fail_stage 20 identity-drift "fresh identity already has a sealed receipt or binary"
fi

config_file="${config_root}/verilator-config.txt"
{
  printf '%s\n' "top=tb_unary_glu_tensor_multilane"
  printf '%s\n' "lanes=${lanes}"
  printf '%s\n' "verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal"
  printf '%s\n' "cflags=-O3 -DNDEBUG -march=native"
  printf '%s\n' "assertions=off"
  printf '%s\n' "trace=off"
  printf '%s\n' "coverage=off"
  printf '%s\n' "waveform=off"
  printf '%s\n' "third_party_waiver=${waiver_file}"
} >"${config_file}"

identity_files="${config_root}/identity-files.txt"
{
  sed '/^[[:space:]]*$/d' "${filelist}"
  printf '%s\n' \
    "npu/version_0820/third_party/hardfloat/source/HardFloat_consts.vi" \
    "npu/version_0820/third_party/hardfloat/source/HardFloat_localFuncs.vi" \
    "npu/version_0820/third_party/hardfloat/source/RISCV/HardFloat_specialize.vi" \
    "npu/version_0820/docs/UNARY_GLU_TENSOR_MULTILANE_RTL_CONTRACT.md" \
    "npu/version_0820/tmp/contracts/unary-glu-tensor-multilane-v1.json" \
    "npu/version_0820/tmp/contracts/unary-glu-tensor-multilane-architecture-v1.md" \
    "npu/version_0820/tmp/logs/unary-glu-tensor-multilane/sources.f" \
    "npu/version_0820/tmp/logs/unary-glu-tensor-multilane/locked-third-party.vlt" \
    "npu/version_0820/tmp/logs/unary-glu-tensor-multilane/run-one.sh"
} >"${identity_files}"

source_manifest="${config_root}/source-manifest.sha256"
: >"${source_manifest}"
while IFS= read -r source_path; do
  [[ -n "${source_path}" ]] || continue
  [[ -f "${repo_root}/${source_path}" ]] ||
    fail_stage 21 missing-source "missing source ${source_path}"
  sha256sum "${repo_root}/${source_path}" >>"${source_manifest}" ||
    fail_stage 22 source-hash "cannot hash ${source_path}"
done <"${identity_files}"
sha256sum "${filelist}" >"${config_root}/filelist.sha256" ||
  fail_stage 23 filelist-hash "filelist hash failed"
sha256sum "${waiver_file}" >"${config_root}/waiver.sha256" ||
  fail_stage 24 waiver-hash "waiver hash failed"
sha256sum "${config_file}" >"${config_root}/config.sha256" ||
  fail_stage 25 config-hash "config hash failed"
{
  sha256sum "${source_manifest}"
  sha256sum "${config_file}"
  sha256sum "${filelist}"
  sha256sum "${waiver_file}"
} >"${config_root}/design-binding-inputs.sha256"
sha256sum "${config_root}/design-binding-inputs.sha256" \
  >"${config_root}/design-id.sha256" ||
  fail_stage 26 design-id "design identity hash failed"

task_run_status_stage verilator-build
verilator --binary --timing --sv -O3 -Wall -Wno-fatal \
  -CFLAGS "-O3 -DNDEBUG -march=native" \
  --top-module tb_unary_glu_tensor_multilane \
  "-GLANES=${lanes}" \
  -I"${repo_root}/npu/version_0820/third_party/hardfloat/source" \
  -I"${repo_root}/npu/version_0820/third_party/hardfloat/source/RISCV" \
  --Mdir "${compiler_dir}" \
  -o "${binary}" \
  "${waiver_file}" \
  -f "${filelist}" \
  >"${build_log}" 2>&1
build_rc=$?
printf '%s\n' "${build_rc}" >"${config_root}/verilator-build.rc"
if [[ "${build_rc}" -ne 0 ]]; then
  fail_stage "${build_rc}" verilator-build "native Verilator build rc=${build_rc}; see ${build_log}"
fi
[[ -x "${binary}" ]] || fail_stage 27 binary-missing "built binary is missing or not executable"

task_run_status_stage warning-audit
if rg -n '^%Warning' "${build_log}" >"${config_root}/warnings.txt"; then
  fail_stage 28 warning-audit "unwaived Verilator warning found"
fi
: >"${config_root}/warnings.txt"
if rg -n '^%Error' "${build_log}" >"${config_root}/errors.txt"; then
  fail_stage 29 error-audit "Verilator error found despite rc=0"
fi
: >"${config_root}/errors.txt"

task_run_status_stage tb-run
"${binary}" >"${run_log}" 2>&1
run_rc=$?
printf '%s\n' "${run_rc}" >"${config_root}/tb-run.rc"
if [[ "${run_rc}" -ne 0 ]]; then
  fail_stage "${run_rc}" tb-run "native TB run rc=${run_rc}; see ${run_log}"
fi

task_run_status_stage marker-audit
marker="[NPU-UNARY-GLU-TENSOR-MULTILANE][LANES=${lanes}][PASS]"
marker_count=$(rg -F -x -c "${marker}" "${run_log}" || true)
printf '%s\n' "${marker_count}" >"${config_root}/pass-marker.count"
[[ "${marker_count}" == "1" ]] ||
  fail_stage 30 marker-audit "exact PASS marker count is ${marker_count}, expected 1"
perf_count=$(rg -F -c "[NPU-UNARY-GLU-TENSOR-MULTILANE][PERF] LANES=${lanes} N=32" "${run_log}" || true)
printf '%s\n' "${perf_count}" >"${config_root}/perf-marker.count"
[[ "${perf_count}" == "1" ]] ||
  fail_stage 31 marker-audit "exact PERF marker count is ${perf_count}, expected 1"

task_run_status_stage artifact-audit
sha256sum "${binary}" >"${config_root}/binary.sha256" ||
  fail_stage 32 binary-hash "binary hash failed"
sha256sum --check "${source_manifest}" >"${config_root}/source-recheck.log" 2>&1 ||
  fail_stage 33 source-drift "source identity changed during build/run"
if rg --files "${build_dir}" "${config_root}" | \
   rg -i '(^|/)(core([.][0-9]+)?|.*[.](vcd|fst|lxt|lxt2|ucdb|cov|coverage|trace))$' \
   >"${config_root}/forbidden-artifacts.txt"; then
  fail_stage 34 artifact-audit "trace/coverage/wave/core artifact found"
fi
: >"${config_root}/forbidden-artifacts.txt"

task_run_status_stage receipt
{
  printf '%s\n' "receipt_schema=unary-glu-tensor-multilane-native-v1"
  printf '%s\n' "config=${config_name}"
  printf '%s\n' "lanes=${lanes}"
  printf '%s\n' "verilator_build_rc=${build_rc}"
  printf '%s\n' "tb_run_rc=${run_rc}"
  printf '%s\n' "pass_marker_count=${marker_count}"
  printf '%s\n' "perf_marker_count=${perf_count}"
  printf '%s\n' "warnings=0"
  printf '%s\n' "errors=0"
  printf '%s\n' "assertions=off"
  printf '%s\n' "trace=off"
  printf '%s\n' "coverage=off"
  printf '%s\n' "waveform=off"
  printf '%s\n' "source_recheck=PASS"
  printf '%s\n' "forbidden_artifact_count=0"
  printf '%s\n' "cleanup_required=compiler-dir"
  printf '%s\n' "evidence_complete_required=1"
} >"${config_root}/sealed-receipt.txt"
sha256sum \
  "${config_root}/sealed-receipt.txt" \
  "${config_root}/source-manifest.sha256" \
  "${config_root}/filelist.sha256" \
  "${config_root}/waiver.sha256" \
  "${config_root}/config.sha256" \
  "${config_root}/design-id.sha256" \
  "${config_root}/binary.sha256" \
  "${config_root}/verilator-build.rc" \
  "${config_root}/tb-run.rc" \
  "${config_root}/pass-marker.count" \
  "${config_root}/perf-marker.count" \
  "${build_log}" "${run_log}" \
  >"${config_root}/final-binding.sha256" ||
  fail_stage 35 final-binding "final binding hash failed"

task_run_status_stage complete
task_run_status_mark_evidence_complete
command_rc=0
exit 0
