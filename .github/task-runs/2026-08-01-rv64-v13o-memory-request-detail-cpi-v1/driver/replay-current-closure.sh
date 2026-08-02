#!/usr/bin/env bash

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-01-rv64-v13o-memory-request-detail-cpi-v1"
source_dir="${run_dir}/evidence/coremark-current"
evidence_dir="${run_dir}/evidence/checker-replay-current-closure"
status_path="${run_dir}/checker-replay-current-closure.status"
raw_log="${source_dir}/coremark-v8.raw.log"
build_log="${source_dir}/build.log"
identity_path="${source_dir}/pre-run-identity.json"
original_result_path="${source_dir}/counter-check-result.json"
binding_path="${source_dir}/post-run-binding.json"
result_path="${evidence_dir}/replay-result.json"
command_status_path="${evidence_dir}/command-status.txt"
finalized=0

source "${repo_root}/scripts/task-run-status.sh"
mkdir -p "${evidence_dir}"
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

task_run_status_stage "frozen-input-binding"
replay_rc=1
if [[ -s "${raw_log}" && -s "${build_log}" &&
      -s "${identity_path}" && -s "${original_result_path}" &&
      -s "${binding_path}" ]]; then
  task_run_status_stage "current-closure-replay"
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONPATH="${repo_root}/npc/rv64/eval/ppa/tools" \
  python3 - "${repo_root}" "${raw_log}" "${build_log}" \
      "${identity_path}" "${original_result_path}" "${binding_path}" \
      "${result_path}" <<'PY'
import hashlib
import json
import pathlib
import sys

import check

(
    root_arg,
    raw_arg,
    build_arg,
    identity_arg,
    original_arg,
    binding_arg,
    result_arg,
) = sys.argv[1:]
root = pathlib.Path(root_arg)
raw_path = pathlib.Path(raw_arg)
build_path = pathlib.Path(build_arg)
identity_path = pathlib.Path(identity_arg)
original_path = pathlib.Path(original_arg)
binding_path = pathlib.Path(binding_arg)
result_path = pathlib.Path(result_arg)


def sha(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


closure_paths = {
    "measurement_contract_sha256": root
    / "npc/rv64/design/arch/performance-measurement-contract-v1.json",
    "policy_sha256": root
    / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json",
    "counter_schema_sha256": root
    / "npc/rv64/design/arch/performance-counter-schema-v4.json",
    "checker_sha256": root / "npc/rv64/eval/ppa/tools/check.py",
    "checker_tests_sha256": root
    / "npc/rv64/eval/ppa/tests/test_policy_tools.py",
}
current_closure = {key: sha(path) for key, path in closure_paths.items()}

identity = json.loads(identity_path.read_text(encoding="utf-8"))
original = json.loads(original_path.read_text(encoding="utf-8"))
binding = json.loads(binding_path.read_text(encoding="utf-8"))
if sha(raw_path) != binding["artifacts"]["raw_log_sha256"]:
    raise ValueError("frozen raw-log SHA drift")
if sha(identity_path) != binding["artifacts"]["pre_run_identity_sha256"]:
    raise ValueError("pre-run identity SHA drift")
if sha(original_path) != binding["artifacts"]["counter_result_sha256"]:
    raise ValueError("original counter result SHA drift")
# Compare only the five hash fields; `basis` is explanatory metadata.
bound_hashes = {
    key: binding["closure_binding"][key] for key in current_closure
}
if current_closure != bound_hashes:
    raise ValueError(
        f"post-run closure hash drift: bound={bound_hashes} "
        f"current={current_closure}"
    )

policy = json.loads(
    closure_paths["policy_sha256"].read_text(encoding="utf-8")
)
counter_contract = json.loads(
    closure_paths["counter_schema_sha256"].read_text(encoding="utf-8")
)
benchmark_contract = policy["performance_evidence"]["benchmark_contracts"][
    "coremark"
]
parsed = check.parse_raw_benchmark_log(
    raw_path,
    "coremark",
    "pc_bounded_region_v1",
    benchmark_contract,
    "npc-rv64-performance-evidence-v8",
    counter_contract,
)

expected = {
    "cycles": original["cycles"],
    "retired_instructions": original["retired_instructions"],
    "semantic": original["semantic"],
    "region": original["region"],
    "cpi_stack": original["cpi_stack"],
    "retire_slots": original["retire_slots"],
}
observed = {
    "cycles": parsed["cycles"],
    "retired_instructions": parsed["retired_instructions"],
    "semantic": {
        "good_trap_count": parsed["good_trap_count"],
        "exit_code": parsed["exit_code"],
        "iterations": parsed["iterations"],
        "crc": parsed["crc"],
    },
    "region": parsed["region"],
    "cpi_stack": parsed["cpi_stack"],
    "retire_slots": parsed["retire_slots"],
}
if observed != expected:
    raise ValueError("current closure did not reproduce the frozen V13O result")

build_text = build_path.read_text(encoding="utf-8", errors="replace")
assertion_flags = {
    "verilator_assert": "--assert" in build_text,
    "ooo_assert_define": "+define+OOO_ASSERT" in build_text,
    "terminal_holder_assert_define": "+define+OOO_TERMINAL_HOLDER_ASSERT"
    in build_text,
}
if not all(assertion_flags.values()):
    raise ValueError(f"assertion compile flags incomplete: {assertion_flags}")

result = {
    "schema": "npc-rv64-v13o-current-closure-replay-v1",
    "status": "PASS",
    "mode": "frozen_raw_log_replay",
    "dut_rerun": False,
    "source": {
        "raw_log_sha256": sha(raw_path),
        "build_log_sha256": sha(build_path),
        "pre_run_identity_sha256": sha(identity_path),
        "original_counter_result_sha256": sha(original_path),
        "simulator_executable_sha256": identity[
            "simulator_executable_sha256"
        ],
    },
    "current_closure": current_closure,
    "assertion_compile_evidence": {
        "saved_build_log_observation": assertion_flags,
        "binding_state": "GAP_POSTHOC_LOG_ONLY",
        "limitation": (
            "the build-log SHA was not frozen in pre-run identity or the "
            "original post-run binding, so it is not cryptographic proof that "
            "the bound simulator executable was produced by this log"
        ),
    },
    "exact_result_equivalence": {
        "fields": list(expected),
        "cycles": observed["cycles"],
        "retired_instructions": observed["retired_instructions"],
        "request_outstanding": observed["cpi_stack"]["memory_lifecycle"][
            "request_outstanding"
        ],
        "axi_write_response": observed["cpi_stack"][
            "memory_request_detail"
        ]["axi_write_response"],
    },
    "proven_scope": [
        "current closure reproduces the frozen V13O semantic and counter result",
        "the currently saved build log contains the expected assertion flags",
    ],
    "unproven_scope": [
        "production or elaborated RTL semantic identity",
        "V13N independent aggregate recomputation",
        "build-log to simulator-executable cryptographic binding",
        "late-B focused dynamic mutation sensitivity",
        "causal CPI attribution or CPI/PPA promotion",
    ],
}
result_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
PY
  replay_rc=$?
fi

printf '%s\n' \
  "replay_rc=${replay_rc}" \
  "dut_rerun=0" \
  >"${command_status_path}"

task_run_status_stage "evidence-complete"
if [[ "${replay_rc}" -eq 0 && -s "${result_path}" ]]; then
  task_run_status_mark_evidence_complete
fi
finalized=1
task_run_status_finalize "${replay_rc}" 0
