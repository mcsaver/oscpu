#!/usr/bin/env bash
set -euo pipefail

# Rebuild all nine canonical directed-architecture records against the live
# RV64 RTL digest and the live fail-closed checker.  The dependency graph has
# two canonical roots: frontend II=1 recursively rebuilds DI-1 plus the
# DI-3..5/OOO-1..4 predecessor chain, then width continuity publishes DI-2
# while preserving those same-design siblings.  Running every historical
# leaf entry again is both redundant and incorrect after aggregate closure:
# several leaf runners intentionally encode the RED inventory that existed at
# their original milestone.

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
log_dir="${run_dir}/gates"
log_path="${log_dir}/architecture-evidence-refresh.log"
manifest_path="${repo_root}/npc/rv64/eval/ppa/evidence/architecture-current.json"
result_path="${log_dir}/final-architecture-hard-gates.json"

mkdir -p "${log_dir}"
exec > >(tee "${log_path}") 2>&1

# Historical directed-gate runners deliberately reject out-of-stage siblings:
# in particular, the OOO-4 publisher accepts the exact six predecessor records
# but not a retained DI-1/DI-2 record from an earlier complete aggregate.
# Therefore every full refresh starts from an empty directed inventory and the
# two canonical roots rebuild all nine records under one live RTL identity.
python3 - "${repo_root}" "${manifest_path}" <<'PY'
import datetime
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
manifest_path = pathlib.Path(sys.argv[2]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

source_sha, _ = arch.rtl_binding(root)
live_design_id = f"sha256:{source_sha}"
payload = json.loads(manifest_path.read_text(encoding="utf-8"))
tests = payload.get("tests")
if not isinstance(tests, dict):
    raise SystemExit("architecture manifest tests must be an object")
prior_design_id = payload.get("design_id")
prior_records = len(tests)
payload["design_id"] = live_design_id
payload["tests"] = {}
payload["generated_at_utc"] = datetime.datetime.now(
    datetime.timezone.utc
).isoformat()
temporary = manifest_path.with_suffix(manifest_path.suffix + ".tmp")
temporary.write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
temporary.replace(manifest_path)
print(
    "[V9O-ARCH-EVIDENCE] "
    f"manifest_reset prior={prior_design_id} live={live_design_id} "
    f"discarded_records={prior_records}"
)
PY

root_targets=(
  check-frontend-ii1
  check-width-continuity
)

for target in "${root_targets[@]}"; do
  printf '[V9O-ARCH-EVIDENCE] target=%s state=START\n' "${target}"
  make -C "${repo_root}/npc/rv64" "${target}"
  printf '[V9O-ARCH-EVIDENCE] target=%s state=PASS\n' "${target}"
done

make -C "${repo_root}/npc/rv64/testbench" \
  "ARCH_GATE_EVIDENCE=${manifest_path}" \
  "ARCH_GATE_RESULT=${result_path}" \
  arch-gates

python3 - "${result_path}" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
result = json.loads(path.read_text(encoding="utf-8"))
expected = {
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}
if set(result.get("gates", {})) != expected:
    raise SystemExit("final architecture gate inventory mismatch")
not_green = sorted(
    name for name, gate in result["gates"].items()
    if gate.get("status") != "GREEN"
)
if not_green:
    raise SystemExit(f"final architecture gates are not GREEN: {not_green}")
if result.get("overall_status") != "GREEN" or result.get("exit_code") != 0:
    raise SystemExit("final architecture aggregate is not GREEN")
rtl = result.get("rtl_source_set", {})
design_id = rtl.get("design_id")
if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
    raise SystemExit("final architecture result lacks a complete RTL design id")
print(
    "[V9O-ARCH-EVIDENCE] "
    f"gates={len(expected)} design_id={design_id} aggregate=GREEN"
)
PY

printf '%s\n' \
  "[V9O-ARCH-EVIDENCE] roots=${#root_targets[@]} refreshed=9 status=PASS"
