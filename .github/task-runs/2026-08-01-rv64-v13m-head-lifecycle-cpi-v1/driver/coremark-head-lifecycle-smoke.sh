#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1"
evidence_dir="${run_dir}/evidence/coremark-current"
build_dir="${repo_root}/npc/rv64/build-v13m-head-lifecycle-smoke"
binary_path="${build_dir}/NpcSimTop"
image_path="${repo_root}/.github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map/evidence/full-core-functional-attempt1/images/benchmarks/coremark.bin"
status_path="${run_dir}/coremark-head-lifecycle-smoke.status"
build_log="${evidence_dir}/build.log"
raw_log="${evidence_dir}/coremark-v6.raw.log"
result_path="${evidence_dir}/counter-check-result.json"
finalized=0
cleanup_rc=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

cleanup_build() {
  local resolved_build
  resolved_build=$(realpath -m -- "${build_dir}") || return 1
  if [[ "${resolved_build}" != "/home/lyg/PA/ysyx-workbench/npc/rv64/build-v13m-head-lifecycle-smoke" ]]; then
    printf '%s\n' "[v13m-coremark] refusing unexpected cleanup target: ${resolved_build}" >&2
    return 2
  fi
  rm -rf -- "${resolved_build}"
}

finalize_on_exit() {
  local command_rc=$?
  if [[ -d "${build_dir}" ]]; then
    cleanup_build || cleanup_rc=$?
  fi
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" "${cleanup_rc}" || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage "input-binding"
input_rc=0
if [[ ! -f "${image_path}" ]]; then
  input_rc=1
else
  image_sha256=$(sha256sum "${image_path}" | awk '{print $1}')
  config_sha256=$(sha256sum "${repo_root}/npc/rv64/.config" | awk '{print $1}')
  if [[ "${image_sha256}" != "a7117f7490f6ff0e23008f631f2f0977b9d0e269380931e2079ae5c1e0cb238b" ||
        "${config_sha256}" != "63ecfda4b377430c468116a77efb77345705c3fcf9aca499b641b287cc6da5ce" ]]; then
    input_rc=1
  fi
fi

build_rc=1
run_rc=1
parser_rc=1
build_bytes=0
if [[ "${input_rc}" -eq 0 ]]; then
  task_run_status_stage "verilator-full-build"
  mkdir -p "${build_dir}"
  make -C "${repo_root}/npc/rv64" \
    BUILD_DIR="${build_dir}" \
    VERILATOR_BUILD_JOBS=1 \
    "${binary_path}" >"${build_log}" 2>&1
  build_rc=$?
fi

if [[ "${build_rc}" -eq 0 && -x "${binary_path}" ]]; then
  binary_sha256=$(sha256sum "${binary_path}" | awk '{print $1}')
  build_bytes=$(du -sb "${build_dir}" | awk '{print $1}')
  task_run_status_stage "coremark-current-config"
  NPC_REGION_START_PC=0x00000000800017a8 \
  NPC_REGION_END_PC=0x00000000800017b0 \
  timeout --signal=TERM 240s "${binary_path}" "${image_path}" \
    --batch --no-vga --max-cycles=6000000 >"${raw_log}" 2>&1
  run_rc=$?
fi

if [[ "${run_rc}" -eq 0 ]]; then
  task_run_status_stage "v6-counter-parser"
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONPATH="${repo_root}/npc/rv64/eval/ppa/tools" \
  python3 - "${repo_root}" "${raw_log}" "${result_path}" \
      "${binary_sha256}" "${image_sha256}" "${config_sha256}" <<'PY'
import hashlib
import json
import pathlib
import sys

import check

root = pathlib.Path(sys.argv[1])
raw_log = pathlib.Path(sys.argv[2])
result_path = pathlib.Path(sys.argv[3])
binary_sha256, image_sha256, config_sha256 = sys.argv[4:7]
policy = json.loads(
    (root / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json").read_text(
        encoding="utf-8"))
counter_contract = json.loads(
    (root / "npc/rv64/design/arch/performance-counter-schema-v2.json").read_text(
        encoding="utf-8"))
benchmark_contract = policy["performance_evidence"]["benchmark_contracts"][
    "coremark"]
parsed = check.parse_raw_benchmark_log(
    raw_log,
    "coremark",
    "pc_bounded_region_v1",
    benchmark_contract,
    "npc-rv64-performance-evidence-v6",
    counter_contract,
)
expected_cycles = 5395310
expected_retired = 3183617
expected_head_not_complete = 3172886
if (parsed["cycles"], parsed["retired_instructions"]) != (
        expected_cycles, expected_retired):
    raise ValueError("current CoreMark counters drifted from V13L observation")
if parsed["cpi_stack"]["head_not_complete_aggregate"] != \
        expected_head_not_complete:
    raise ValueError("V13M head lifecycle aggregate drifted from V13L bucket")
for required_reason in (
        "dependency", "issue_terminal", "execution_latency",
        "memory_latency"):
    if parsed["cpi_stack"][required_reason] <= 0:
        raise ValueError(
            f"V13M CoreMark did not exercise {required_reason}")
result = {
    "schema": "npc-rv64-v13m-head-lifecycle-smoke-result-v1",
    "status": "PASS",
    "claim_scope": (
        "current-config CoreMark v6 conserving ROB-head lifecycle only"),
    "production_semantics_identity": (
        "GAP_TYPED_PRODUCTION_ONLY_CLOSURE_NOT_BOUND"),
    "full_causal_cpi_stack": False,
    "cycles": parsed["cycles"],
    "retired_instructions": parsed["retired_instructions"],
    "region": parsed["region"],
    "cpi_stack": parsed["cpi_stack"],
    "retire_slots": parsed["retire_slots"],
    "identity": {
        "simulator_sha256": binary_sha256,
        "coremark_image_sha256": image_sha256,
        "config_sha256": config_sha256,
        "npc_sim_top_sha256": hashlib.sha256(
            (root / "npc/rv64/vsrc/sim/NpcSimTop.sv").read_bytes()).hexdigest(),
        "cpu_exec_sha256": hashlib.sha256(
            (root / "npc/rv64/csrc/cpu/cpu-exec.cpp").read_bytes()).hexdigest(),
        "counter_schema_sha256": hashlib.sha256(
            (root / "npc/rv64/design/arch/performance-counter-schema-v2.json").read_bytes()).hexdigest(),
    },
}
result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
PY
  parser_rc=$?
fi

task_run_status_stage "cleanup-build-products"
if [[ -d "${build_dir}" ]]; then
  cleanup_build || cleanup_rc=$?
fi
if [[ -e "${build_dir}" ]]; then
  cleanup_rc=1
fi

command_rc=1
if [[ "${input_rc}" -eq 0 && "${build_rc}" -eq 0 &&
      "${run_rc}" -eq 0 && "${parser_rc}" -eq 0 ]]; then
  command_rc=0
fi

printf '%s\n' \
  "input_rc=${input_rc}" \
  "build_rc=${build_rc}" \
  "run_rc=${run_rc}" \
  "parser_rc=${parser_rc}" \
  "cleanup_rc=${cleanup_rc}" \
  "build_bytes_deleted=${build_bytes}" \
  >"${evidence_dir}/command-status.txt"

task_run_status_stage "evidence-complete"
if [[ "${command_rc}" -eq 0 && "${cleanup_rc}" -eq 0 &&
      -s "${result_path}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${command_rc}" "${cleanup_rc}"
