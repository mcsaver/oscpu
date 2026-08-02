#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1"
evidence_dir="${run_dir}/evidence/coremark-current"
raw_log="${evidence_dir}/coremark-v6.raw.log"
result_path="${evidence_dir}/checker-replay-result.json"
status_path="${run_dir}/checker-replay.status"
original_status_path="${run_dir}/coremark-head-lifecycle-smoke.status"
original_command_path="${evidence_dir}/command-status.txt"
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
task_run_status_init "${status_path}"
task_run_status_install_signal_traps

finalize_on_exit() {
  local command_rc=$?
  if [[ "${finalized}" -eq 0 ]]; then
    task_run_status_stage "exit-trap"
    task_run_status_finalize "${command_rc}" 0 || true
  fi
}
trap finalize_on_exit EXIT

task_run_status_stage "frozen-log-v6-replay"
PYTHONDONTWRITEBYTECODE=1 \
PYTHONPATH="${repo_root}/npc/rv64/eval/ppa/tools" \
python3 - "${repo_root}" "${raw_log}" "${result_path}" \
    "${original_status_path}" "${original_command_path}" <<'PY'
import hashlib
import json
import pathlib
import sys

import check

root = pathlib.Path(sys.argv[1])
raw_log = pathlib.Path(sys.argv[2])
result_path = pathlib.Path(sys.argv[3])
original_status_path = pathlib.Path(sys.argv[4])
original_command_path = pathlib.Path(sys.argv[5])

original_status = original_status_path.read_text(encoding="utf-8").strip()
original_command = original_command_path.read_text(encoding="utf-8")
if not original_status.startswith("FAIL rc=1"):
    raise ValueError("original FAIL status was not preserved")
for required_line in (
        "input_rc=0", "build_rc=0", "run_rc=0", "parser_rc=1",
        "cleanup_rc=0"):
    if required_line not in original_command.splitlines():
        raise ValueError(f"original command status lost {required_line}")

policy_path = root / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json"
measurement_path = (
    root / "npc/rv64/design/arch/performance-measurement-contract-v1.json")
counter_path = (
    root / "npc/rv64/design/arch/performance-counter-schema-v2.json")
policy = json.loads(policy_path.read_text(encoding="utf-8"))
measurement_contract = json.loads(measurement_path.read_text(encoding="utf-8"))
counter_contract = json.loads(counter_path.read_text(encoding="utf-8"))
performance_policy = policy["performance_evidence"]
if performance_policy["schema"] != "npc-rv64-performance-evidence-v6":
    raise ValueError("policy does not select v6 evidence")
measurement_binding = performance_policy["measurement_contract"]
counter_binding = performance_policy["counter_schema"]
if (measurement_binding["id"] !=
        measurement_contract["performance_measurement_contract_id"] or
        measurement_binding["sha256"] !=
        hashlib.sha256(measurement_path.read_bytes()).hexdigest()):
    raise ValueError("measurement contract binding drifted")
if (counter_binding["id"] !=
        counter_contract["performance_counter_schema_id"] or
        counter_binding["sha256"] !=
        hashlib.sha256(counter_path.read_bytes()).hexdigest()):
    raise ValueError("counter contract binding drifted")

parsed = check.parse_raw_benchmark_log(
    raw_log,
    "coremark",
    "pc_bounded_region_v1",
    performance_policy["benchmark_contracts"]["coremark"],
    "npc-rv64-performance-evidence-v6",
    counter_contract,
)
expected = (5395310, 3183617, 3172886)
observed = (
    parsed["cycles"], parsed["retired_instructions"],
    parsed["cpi_stack"]["head_not_complete_aggregate"])
if observed != expected:
    raise ValueError(f"frozen CoreMark counters drifted: {observed!r}")
if parsed["cpi_stack"]["dependency"] != 0:
    raise ValueError("frozen zero-dependency observation unexpectedly changed")
if parsed["cpi_stack"]["head_lifecycle_unknown"] != 0:
    raise ValueError("frozen lifecycle classification is incomplete")
if parsed["cpi_stack"]["unknown"] != 0:
    raise ValueError("frozen retirement classification is incomplete")

result = {
    "schema": "npc-rv64-v13m-checker-replay-result-v1",
    "status": "PASS",
    "original_task_status_preserved": original_status,
    "classification": "SYSTEM_TRANSACTION_COMPLETE_OLD_NONVACUITY_ORACLE_FALSE_NEGATIVE",
    "hardware_transaction": {
        "coremark_pass": parsed["pass"],
        "good_trap_count": parsed["good_trap_count"],
        "exit_code": parsed["exit_code"],
        "cycles": parsed["cycles"],
        "retired_instructions": parsed["retired_instructions"],
        "region": parsed["region"],
    },
    "cpi_stack": parsed["cpi_stack"],
    "retire_slots": parsed["retire_slots"],
    "oracle_correction": {
        "removed_invalid_rule": "each named lifecycle bucket must be nonzero",
        "retained_rules": [
            "unique FINAL and COUNTERS_FINAL",
            "exact boundary and retired binding",
            "head lifecycle aggregate binding",
            "cycle and retire-slot conservation",
            "zero overflow and invalid events",
            "unknown plus head-lifecycle-unknown ratio at most 1 percent"
        ],
        "zero_dependency_is_legal": True,
    },
    "identity": {
        "simulator_sha256": None,
        "simulator_sha256_qualification": (
            "GAP_ORIGINAL_DRIVER_DID_NOT_PERSIST_DIGEST_BEFORE_ORACLE_FAILURE"),
        "coremark_image_sha256": (
            "a7117f7490f6ff0e23008f631f2f0977b9d0e269380931e2079ae5c1e0cb238b"),
        "config_sha256": (
            "63ecfda4b377430c468116a77efb77345705c3fcf9aca499b641b287cc6da5ce"),
        "raw_log_sha256": hashlib.sha256(raw_log.read_bytes()).hexdigest(),
        "build_log_sha256": hashlib.sha256(
            (raw_log.parent / "build.log").read_bytes()).hexdigest(),
        "npc_sim_top_sha256": hashlib.sha256(
            (root / "npc/rv64/vsrc/sim/NpcSimTop.sv").read_bytes()).hexdigest(),
        "cpu_exec_sha256": hashlib.sha256(
            (root / "npc/rv64/csrc/cpu/cpu-exec.cpp").read_bytes()).hexdigest(),
        "counter_schema_sha256": hashlib.sha256(
            counter_path.read_bytes()).hexdigest(),
        "measurement_contract_sha256": hashlib.sha256(
            measurement_path.read_bytes()).hexdigest(),
        "policy_sha256": hashlib.sha256(policy_path.read_bytes()).hexdigest(),
    },
}
result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
PY
replay_rc=$?

task_run_status_stage "evidence-complete"
if [[ "${replay_rc}" -eq 0 && -s "${result_path}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${replay_rc}" 0
