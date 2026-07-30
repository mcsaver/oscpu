#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
v10c_runner="${repo_root}/.github/task-runs/"\
"2026-07-27-rv64-v10c-current-design-evidence-replay/"\
"run-current-design-evidence-replay.sh"
semantic_identity="${run_dir}/semantic-delta-identity.json"
evidence_dir="${run_dir}/current-replay/stage-logs"
driver_log="${run_dir}/current-replay/driver.log"
replay_status="${run_dir}/current-replay/replay.status"
task_status="${run_dir}/current-replay/task-run.status"

python3 - "${semantic_identity}" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
value = json.loads(path.read_text(encoding="utf-8"))
expected = (
    "sha256:"
    "5f9dd06860a91dfc5461357c731fa2d4c34b91cb3b3cdedc754f0972f8bf4c5a"
)
if value.get("status") != "PASS":
    raise SystemExit("semantic-delta identity is not PASS")
if value["identity"]["aggregate_rtl_source_set"]["current_design_id"] != expected:
    raise SystemExit("semantic-delta identity is not bound to current RTL")
if value["evidence_state"]["full_system_rerun_required"] != "NO":
    raise SystemExit("unexpected full-system rerun decision")
print(
    "[V10G-CURRENT-REPLAY][PREFLIGHT] "
    f"design_id={expected} cost=minute-scale single_flight=1 PASS"
)
PY

mkdir -p "${evidence_dir}"
V10C_EVIDENCE_DIR_OVERRIDE="${evidence_dir}" \
V10C_DRIVER_LOG_OVERRIDE="${driver_log}" \
V10C_REPLAY_STATUS_PATH_OVERRIDE="${replay_status}" \
V10C_TASK_STATUS_PATH_OVERRIDE="${task_status}" \
  bash "${v10c_runner}"
