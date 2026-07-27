#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
architecture_dir="${run_dir}/architecture"
manifest_path="${repo_root}/npc/rv64/eval/ppa/evidence/architecture-current.json"
functional_path="${repo_root}/npc/rv64/eval/ppa/evidence/functional-aggregate-result.json"
result_path="${architecture_dir}/final-architecture-hard-gates.json"
log_path="${architecture_dir}/architecture-current.log"
status_path="${run_dir}/architecture-current.status"

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

mkdir -p "${architecture_dir}"
exec > >(tee "${log_path}") 2>&1
write_status "RUNNING" "canonical-root-replay"

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
    "[V10B-ARCH-EVIDENCE] "
    f"manifest_reset prior={prior_design_id} live={live_design_id} "
    f"discarded_records={prior_records}"
)
PY

for target in check-frontend-ii1 check-width-continuity; do
  printf '[V10B-ARCH-EVIDENCE] target=%s state=START\n' "${target}"
  make -C "${repo_root}/npc/rv64" "${target}"
  printf '[V10B-ARCH-EVIDENCE] target=%s state=PASS\n' "${target}"
done

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
    raise SystemExit(
        "current architecture manifest is not a nine-record PASS set"
    )
if set(result.get("gates", {})) != expected:
    raise SystemExit("final architecture gate inventory mismatch")
if any(
    gate.get("status") != "GREEN"
    for gate in result["gates"].values()
):
    raise SystemExit("one or more final architecture gates are not GREEN")
if result.get("overall_status") != "GREEN" or result.get("exit_code") != 0:
    raise SystemExit("final architecture aggregate is not GREEN")

design_id = result.get("rtl_source_set", {}).get("design_id")
if design_id != manifest.get("design_id"):
    raise SystemExit(
        "architecture manifest/result design identity mismatch"
    )
if design_id != functional.get("design_id"):
    raise SystemExit(
        "functional/architecture design identity mismatch"
    )
if functional.get("status") != "PASS" or functional.get("exit_code") != 0:
    raise SystemExit("current functional aggregate is not PASS")
print(design_id)
PY
)"

printf '[V10B-ARCH-FINAL] gates=9 aggregate=GREEN functional=PASS design_id=%s\n' \
  "${design_id}"
write_status \
  "PASS" \
  "design_id=${design_id};root-replay=PASS;final-aggregate=GREEN"
trap - EXIT
