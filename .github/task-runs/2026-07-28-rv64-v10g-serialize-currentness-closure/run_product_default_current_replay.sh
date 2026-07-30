#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
npc_home="${repo_root}/npc/rv64"
v10c_runner="${repo_root}/.github/task-runs/"\
"2026-07-27-rv64-v10c-current-design-evidence-replay/"\
"run-current-design-evidence-replay.sh"
product_identity="${run_dir}/product-default-identity.json"
system_matrix="${run_dir}/system-product-default-matrix-v2/summary.json"
qh_mutation="${run_dir}/mutations/qh-csrfile-c2-replay-v1/summary.json"
replay_root="${run_dir}/product-default-current-replay"
evidence_dir="${replay_root}/stage-logs"
driver_log="${replay_root}/driver.log"
replay_status="${replay_root}/replay.status"
task_status="${replay_root}/task-run.status"
config_receipt="${replay_root}/product-config-receipt.txt"
launch_gate="${replay_root}/launch-gate.json"

mkdir -p "${replay_root}"

make -s -C "${npc_home}" print-product-rtl-config > "${config_receipt}"

python3 - "${repo_root}" "${product_identity}" "${system_matrix}" \
  "${qh_mutation}" "${config_receipt}" "${launch_gate}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
identity_path = pathlib.Path(sys.argv[2])
matrix_path = pathlib.Path(sys.argv[3])
mutation_path = pathlib.Path(sys.argv[4])
receipt_path = pathlib.Path(sys.argv[5])
gate_path = pathlib.Path(sys.argv[6])
expected = (
    "sha256:"
    "04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897"
)

identity = json.loads(identity_path.read_text(encoding="utf-8"))
matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
mutation = json.loads(mutation_path.read_text(encoding="utf-8"))
receipt = {}
for line in receipt_path.read_text(encoding="utf-8").splitlines():
    if "=" in line:
        key, value = line.split("=", 1)
        receipt[key] = value

sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

live_id = f"sha256:{architecture.rtl_binding(root)[0]}"
checks = {
    "product_identity_pass": identity.get("status") == "PASS",
    "product_identity_current": identity.get("current_design_id") == expected,
    "live_design_id_match": live_id == expected,
    "active_a3_elaboration_unchanged":
        not identity["semantic_delta"]["active_queue_head_logic_changed_relative_to_a4"],
    "full_system_rerun_not_required":
        identity["system_recert_decision"]["full_system_rerun_required"] == "NO",
    "system_matrix_pass": bool(matrix.get("all_pass")),
    "system_matrix_design_id_match": matrix.get("design_id") == expected,
    "system_matrix_product_binding":
        matrix.get("product_default_binding", {}).get("status") == "PASS",
    "system_matrix_baselines": sum(
        bool(case["passed"]) for case in matrix["cases"][:3]
    ) == 3,
    "system_matrix_mutations": (
        matrix.get("compile_success_mutations") == 14
        and matrix.get("dynamically_rejected_mutations") == 14
    ),
    "csrfile_c2_mutation_pass": mutation.get("status") == "PASS",
    "csrfile_c2_mutation_design_id":
        mutation.get("design_id") == expected,
    "product_config_schema":
        receipt.get("schema") == "npc-rv64-product-rtl-config-v1",
    "product_config_queue_head": receipt.get("OOO_CSR_QUEUE_HEAD") == "1",
    "product_config_holder_assert":
        receipt.get("OOO_TERMINAL_HOLDER_ASSERT") == "1",
}
gate = {
    "schema": "npc-rv64-v10g-product-default-current-replay-launch/v1",
    "status": "PASS" if all(checks.values()) else "GAP",
    "design_id": live_id,
    "expected_duration": "approximately 35 minutes",
    "over_30_minute_gate": {
        "necessity": (
            "bind module, functional, architecture, trap/exit and mutation "
            "evidence to the normative queue-head=1 product configuration"
        ),
        "information_gain": (
            "replace the prior default-off aggregate with a current-design "
            "product-default aggregate and detect any flag-on regression"
        ),
        "single_flight": True,
        "stop_condition": (
            "stop on the first failed stage or RTL design-id drift"
        ),
    },
    "over_4_hour_user_authorization": "NOT_REQUIRED",
    "full_system_recertification": "NOT_REQUIRED",
    "checks": checks,
}
gate_path.write_text(
    json.dumps(gate, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
if gate["status"] != "PASS":
    failed = [name for name, value in checks.items() if not value]
    raise SystemExit(f"product-default replay preflight GAP: {failed}")
print(
    "[V10G-PRODUCT-DEFAULT-REPLAY][PREFLIGHT] "
    f"design_id={live_id} qh=1 matrix=3+14 "
    "cost_gate=PASS single_flight=1 user_auth=NOT_REQUIRED PASS"
)
PY

mkdir -p "${evidence_dir}"
V10C_EVIDENCE_DIR_OVERRIDE="${evidence_dir}" \
V10C_DRIVER_LOG_OVERRIDE="${driver_log}" \
V10C_REPLAY_STATUS_PATH_OVERRIDE="${replay_status}" \
V10C_TASK_STATUS_PATH_OVERRIDE="${task_status}" \
  bash "${v10c_runner}"
