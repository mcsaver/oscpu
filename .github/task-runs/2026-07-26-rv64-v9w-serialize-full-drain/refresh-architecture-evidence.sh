#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
log_dir="${run_dir}/architecture"
log_path="${log_dir}/architecture-evidence-refresh.log"
status_path="${run_dir}/architecture-current.status"
manifest_path="${repo_root}/npc/rv64/eval/ppa/evidence/architecture-current.json"
result_path="${log_dir}/final-architecture-hard-gates.json"

write_status() {
  local state="$1"
  local detail="$2"
  printf 'state=%s\nstage=architecture-current\ndetail=%s\n' \
    "${state}" "${detail}" > "${status_path}"
}

on_exit() {
  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    write_status "FAIL" "rc=${rc}"
  fi
}
trap on_exit EXIT

mkdir -p "${log_dir}"
exec > >(tee "${log_path}") 2>&1
write_status "RUNNING" "canonical-root-replay"

# Historical directed-gate runners reject out-of-stage sibling records.  A
# current-design replay therefore starts from an empty inventory, then the two
# canonical roots republish all nine gates under one live RTL identity.
python3 - "${repo_root}" "${manifest_path}" <<'PY'
import datetime
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
manifest_path = pathlib.Path(sys.argv[2]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

source_sha, _ = architecture.rtl_binding(root)
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
    "[V9W-ARCH-EVIDENCE] "
    f"manifest_reset prior={prior_design_id} live={live_design_id} "
    f"discarded_records={prior_records}"
)
PY

root_targets=(
  check-frontend-ii1
  check-width-continuity
)

for target in "${root_targets[@]}"; do
  printf '[V9W-ARCH-EVIDENCE] target=%s state=START\n' "${target}"
  make -C "${repo_root}/npc/rv64" "${target}"
  printf '[V9W-ARCH-EVIDENCE] target=%s state=PASS\n' "${target}"
done

make -C "${repo_root}/npc/rv64/testbench" \
  "ARCH_GATE_EVIDENCE=${manifest_path}" \
  "ARCH_GATE_RESULT=${result_path}" \
  arch-gates

design_id="$(
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
print(design_id)
PY
)"

printf '[V9W-ARCH-EVIDENCE] gates=9 design_id=%s aggregate=GREEN\n' \
  "${design_id}"
write_status "PASS" "design_id=${design_id}"
trap - EXIT
