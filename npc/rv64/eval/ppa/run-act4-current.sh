#!/usr/bin/env bash

# Current-design ACT4 execution for the L1 architectural-certification
# subcohort.  The runner reuses the exact assertion-enabled NpcSimTop binary
# from a verified L1 run and leaves only logs plus compact evidence.

set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd -P)"
task_run_root="${repo_root}/.github/task-runs"
tool="${repo_root}/npc/rv64/eval/ppa/tools/act4_current.py"
backend_runner="${repo_root}/am-kernels/arch-test/scripts/act4-npc-run.sh"
config_dir="${repo_root}/am-kernels/arch-test/config/npc-rv64-ooo-current-linux-gnu"
elf_root="${repo_root}/am-kernels/arch-test/work/npc-rv64-ooo-current/elfs"
xpack_dir="${repo_root}/am-kernels/arch-test/env/xpack-riscv-none-elf-gcc-15.2.0-1"
canonical_receipt="${repo_root}/npc/rv64/eval/ppa/evidence/act4-current.json"
python_bin="$(realpath -e -- /usr/bin/python3)" || exit 2
run_dir_arg=""
l1_result_arg=""
publish_current=0
finalized=0
cleanup_done=0
cleanup_rc=0

usage() {
  local stream=${1:-2}
  printf '%s\n' \
    "usage: $0 --run-dir .github/task-runs/<new-run-id> --l1-result <current-run-result.json> [--publish-current]" \
    >&"${stream}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      run_dir_arg=$2
      shift 2
      ;;
    --l1-result)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      l1_result_arg=$2
      shift 2
      ;;
    --publish-current)
      publish_current=1
      shift
      ;;
    -h|--help)
      usage 1
      exit 0
      ;;
    *)
      printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! "${run_dir_arg}" =~ ^\.github/task-runs/[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf '%s\n' \
    "[RV64-ACT4-CURRENT][FAIL] --run-dir must name one fresh task-run" >&2
  exit 2
fi
if [[ -z "${l1_result_arg}" ]]; then
  printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] --l1-result is required" >&2
  exit 2
fi

task_run_root="$(realpath -e -- "${task_run_root}")" || exit 2
run_dir="${task_run_root}/${run_dir_arg##*/}"
if [[ -e "${run_dir}" || -L "${run_dir}" ]]; then
  printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] run directory exists: ${run_dir_arg}" >&2
  exit 2
fi

for required in \
  "${tool}" "${backend_runner}" "${config_dir}" "${elf_root}" \
  "${xpack_dir}/bin/riscv-none-elf-nm" \
  "${xpack_dir}/bin/riscv-none-elf-objcopy"; do
  if [[ -L "${required}" || ! -e "${required}" ]]; then
    printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] unsafe required input: ${required}" >&2
    exit 2
  fi
done

l1_result="${l1_result_arg}"
if [[ "${l1_result}" != /* ]]; then
  l1_result="${repo_root}/${l1_result}"
fi
if [[ -L "${l1_result}" || ! -f "${l1_result}" ]]; then
  printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] unsafe L1 result: ${l1_result_arg}" >&2
  exit 2
fi
case "$(realpath -m -- "${l1_result}")" in
  "${repo_root}"/*) ;;
  *)
    printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] L1 result leaves workspace" >&2
    exit 2
    ;;
esac

mkdir -- "${run_dir}" || exit 1
evidence_dir="${run_dir}/evidence/act4"
raw_dir="${evidence_dir}/raw"
before_path="${evidence_dir}/inputs.before.json"
after_path="${evidence_dir}/inputs.after.json"
cleanup_path="${evidence_dir}/runtime-cleanup.json"
execution_manifest_path="${evidence_dir}/elf-manifest.txt"
result_path="${evidence_dir}/result.json"
status_path="${run_dir}/act4-current.status"
mkdir -p -- "${evidence_dir}" || exit 1

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}" || exit 1
task_run_status_install_signal_traps

cleanup_runtime() {
  local deleted_bytes=0
  local path_bytes=0
  local raw_expected="${run_dir}/evidence/act4/raw"

  [[ "${raw_dir}" == "${raw_expected}" ]] || return 2
  if [[ -d "${raw_dir}/act4-bin" && ! -L "${raw_dir}/act4-bin" ]]; then
    path_bytes="$(find "${raw_dir}/act4-bin" -type f -printf '%s\n' 2>/dev/null \
      | awk '{sum += $1} END {print sum + 0}')" || return 1
    deleted_bytes=$((deleted_bytes + path_bytes))
    rm -rf -- "${raw_dir}/act4-bin" || return 1
  fi
  if [[ -d "${raw_dir}/act4-log" && ! -L "${raw_dir}/act4-log" ]]; then
    path_bytes="$(find "${raw_dir}/act4-log" -maxdepth 1 -type f \
      -name '*.objcopy.log' -printf '%s\n' 2>/dev/null \
      | awk '{sum += $1} END {print sum + 0}')" || return 1
    deleted_bytes=$((deleted_bytes + path_bytes))
    find "${raw_dir}/act4-log" -maxdepth 1 -type f \
      -name '*.objcopy.log' -delete || return 1
  fi
  [[ ! -e "${raw_dir}/act4-bin" ]] || return 1
  if [[ -d "${raw_dir}/act4-log" ]] && \
     find "${raw_dir}/act4-log" -maxdepth 1 -type f \
       -name '*.objcopy.log' -print -quit | grep -q .; then
    return 1
  fi
  printf '%s\n' \
    '{' \
    '  "binary_tree_removed": true,' \
    "  \"deleted_bytes\": ${deleted_bytes}," \
    '  "objcopy_logs_removed": true,' \
    '  "schema": "npc-rv64-act4-runtime-cleanup-v1",' \
    '  "status": "PASS"' \
    '}' >"${cleanup_path}" || return 1
  cleanup_done=1
  return 0
}

finalize_on_exit() {
  local command_rc=$?
  local final_rc
  trap - EXIT HUP INT TERM
  if [[ "${cleanup_done}" -eq 0 ]]; then
    set +e
    cleanup_runtime
    cleanup_rc=$?
    set -e
  fi
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    set +e
    task_run_status_finalize "${command_rc}" "${cleanup_rc}"
    final_rc=$?
    set -e
    if [[ "${command_rc}" -eq 0 ]]; then
      command_rc=${final_rc}
    fi
  fi
  exit "${command_rc}"
}
trap finalize_on_exit EXIT

task_run_status_stage "input-snapshot-before"
"${python_bin}" -B "${tool}" snapshot \
  --l1-result "${l1_result}" \
  --config-dir "${config_dir}" \
  --elf-root "${elf_root}" \
  --output "${before_path}" \
  >"${run_dir}/snapshot-before.log" 2>&1 || exit $?

"${python_bin}" -B "${tool}" manifest \
  --snapshot "${before_path}" \
  --output "${execution_manifest_path}" \
  >"${run_dir}/manifest-build.log" 2>&1 || exit $?

simulator_rel="$("${python_bin}" -B -c \
  'import json,sys; print(json.load(open(sys.argv[1]))["l1"]["simulator"]["path"])' \
  "${before_path}")" || exit $?
simulator="${repo_root}/${simulator_rel}"
if [[ -L "${simulator}" || ! -x "${simulator}" ]]; then
  printf '%s\n' "[RV64-ACT4-CURRENT][FAIL] frozen simulator is unsafe" >&2
  exit 2
fi

task_run_status_stage "act4-execution"
NPC_BIN="${simulator}" \
RISCV_NM="${xpack_dir}/bin/riscv-none-elf-nm" \
RISCV_OBJCOPY="${xpack_dir}/bin/riscv-none-elf-objcopy" \
bash "${backend_runner}" \
  --run-dir "${raw_dir}" \
  --elf-root "${elf_root}" \
  --elf-manifest "${execution_manifest_path}" \
  --config-name npc-rv64-ooo-current \
  --suites rv64i/I,rv64i/M,priv/Sv,priv/Svnapot \
  --max-cycles 20000000 \
  --timeout-sec 60 \
  >"${run_dir}/act4-driver.log" 2>&1
execution_rc=$?
if [[ "${execution_rc}" -ne 0 ]]; then
  exit "${execution_rc}"
fi
if [[ ! -f "${raw_dir}/overall.status" ]] || \
   [[ "$(tr -d '\r\n' <"${raw_dir}/overall.status")" != PASS ]]; then
  exit 1
fi

task_run_status_stage "input-snapshot-after"
"${python_bin}" -B "${tool}" snapshot \
  --l1-result "${l1_result}" \
  --config-dir "${config_dir}" \
  --elf-root "${elf_root}" \
  --output "${after_path}" \
  >"${run_dir}/snapshot-after.log" 2>&1 || exit $?
cmp -s -- "${before_path}" "${after_path}" || exit 1

task_run_status_stage "runtime-cleanup"
cleanup_runtime
cleanup_rc=$?
[[ "${cleanup_rc}" -eq 0 ]] || exit "${cleanup_rc}"

task_run_status_stage "receipt-build"
"${python_bin}" -B "${tool}" build \
  --run-dir "${raw_dir}" \
  --input-before "${before_path}" \
  --input-after "${after_path}" \
  --cleanup "${cleanup_path}" \
  --execution-manifest "${execution_manifest_path}" \
  --output "${result_path}" \
  >"${run_dir}/receipt-build.log" 2>&1 || exit $?

task_run_status_stage "receipt-verify"
"${python_bin}" -B "${tool}" verify --receipt "${result_path}" \
  >"${run_dir}/receipt-verify.log" 2>&1 || exit $?
if [[ "$(grep -c '^\[RV64-ACT4-CURRENT\]\[PASS\] ' \
      "${run_dir}/receipt-verify.log" || :)" != 1 ]]; then
  exit 1
fi

if [[ "${publish_current}" -eq 1 ]]; then
  task_run_status_stage "current-publication"
  "${python_bin}" -B "${tool}" publish \
    --receipt "${result_path}" --output "${canonical_receipt}" \
    >"${run_dir}/publication.log" 2>&1 || exit $?
  if [[ "$(grep -c '^\[RV64-ACT4-CURRENT\]\[PUBLISH_PASS\] ' \
        "${run_dir}/publication.log" || :)" != 1 ]]; then
    exit 1
  fi
fi

task_run_status_stage "complete"
task_run_status_mark_evidence_complete
task_run_status_finalize 0 "${cleanup_rc}" || exit $?
finalized=1
printf '%s\n' \
  "[RV64-ACT4-CURRENT][PASS] design=f72e-bound cases=100 assertions=0 publish=${publish_current}"
