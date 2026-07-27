#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
architecture_dir="${run_dir}/architecture"
manifest_path="${repo_root}/npc/rv64/eval/ppa/evidence/architecture-current.json"
result_path="${architecture_dir}/final-architecture-hard-gates.json"
functional_path="${repo_root}/npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
log_path="${architecture_dir}/final-aggregate.log"
status_path="${run_dir}/architecture-current.status"

mkdir -p "${architecture_dir}"
exec > >(tee "${log_path}") 2>&1

make -C "${repo_root}/npc/rv64/testbench" \
  "ARCH_GATE_EVIDENCE=${manifest_path}" \
  "ARCH_GATE_RESULT=${result_path}" \
  arch-gates

design_id="$(
  python3 - "${manifest_path}" "${result_path}" "${functional_path}" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
result_path = pathlib.Path(sys.argv[2])
functional_path = pathlib.Path(sys.argv[3])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
result = json.loads(result_path.read_text(encoding="utf-8"))
functional = json.loads(functional_path.read_text(encoding="utf-8"))

expected = {
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}
tests = manifest.get("tests", {})
if len(tests) != 9 or any(
    not isinstance(record, dict) or record.get("status") != "PASS"
    for record in tests.values()
):
    raise SystemExit("current architecture manifest is not a nine-record PASS set")
if set(result.get("gates", {})) != expected:
    raise SystemExit("final architecture gate inventory mismatch")
if any(gate.get("status") != "GREEN" for gate in result["gates"].values()):
    raise SystemExit("one or more final architecture gates are not GREEN")
if result.get("overall_status") != "GREEN" or result.get("exit_code") != 0:
    raise SystemExit("final architecture aggregate is not GREEN")

design_id = result.get("rtl_source_set", {}).get("design_id")
if design_id != manifest.get("design_id"):
    raise SystemExit("architecture manifest/result design identity mismatch")
if design_id != functional.get("design_id"):
    raise SystemExit("functional/architecture design identity mismatch")
if functional.get("status") != "PASS" or functional.get("exit_code") != 0:
    raise SystemExit("current functional aggregate is not PASS")
print(design_id)
PY
)"

printf '[V9Y-ARCH-FINAL] gates=9 aggregate=GREEN functional=PASS design_id=%s\n' \
  "${design_id}"
printf 'state=PASS\nstage=architecture-current\ndetail=design_id=%s;root-replay=PASS;final-aggregate=GREEN\n' \
  "${design_id}" > "${status_path}"
