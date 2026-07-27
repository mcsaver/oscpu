#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
status_path="${run_dir}/layered-current.status"
log_path="${run_dir}/layered-current.log"
module_dir="${run_dir}/module-current"
module_build_dir="${run_dir}/module-current-build"
functional_dir="${run_dir}/functional-current"
expected_design_id="sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951"

write_status() {
  local state="$1"
  local stage="$2"
  local detail="$3"
  printf 'state=%s\nstage=%s\ndetail=%s\n' \
    "${state}" "${stage}" "${detail}" > "${status_path}"
}

on_exit() {
  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    write_status "FAIL" "layered-current" "rc=${rc}"
  fi
}
trap on_exit EXIT

if [[ -e "${module_dir}/summary.txt" || -e "${functional_dir}" ]]; then
  printf 'refusing to overwrite existing layered evidence\n' >&2
  exit 2
fi

mkdir -p "${run_dir}"
exec > >(tee "${log_path}") 2>&1

design_sha="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

source_sha, _ = architecture.rtl_binding(root)
print(source_sha)
PY
)"
design_id="sha256:${design_sha}"
if [[ "${design_id}" != "${expected_design_id}" ]]; then
  printf 'live design identity mismatch: expected=%s actual=%s\n' \
    "${expected_design_id}" "${design_id}" >&2
  exit 3
fi
printf 'rtl_design_id=%s\n' "${design_id}" > "${run_dir}/layered-binding.txt"

write_status "RUNNING" "module-current" "design_id=${design_id}"
make -C "${repo_root}/npc/rv64/testbench" \
  "RESULT_DIR=${module_dir}" \
  "BUILD_DIR=${module_build_dir}" \
  "RTL_EVIDENCE_SHA=${design_sha}" \
  run

python3 - "${module_dir}" "${design_id}" <<'PY'
import pathlib
import sys

module_dir = pathlib.Path(sys.argv[1])
design_id = sys.argv[2]
summary = (module_dir / "summary.txt").read_text(encoding="utf-8")
if "- total: 113" not in summary:
    raise SystemExit("module inventory is not exactly 113 tests")
if "- passed: 113" not in summary or "- failed: 0" not in summary:
    raise SystemExit("module aggregate is not 113/113 PASS")
logs = sorted((module_dir / "logs").glob("*.log"))
if len(logs) != 113:
    raise SystemExit(f"module log inventory mismatch: {len(logs)}")
for path in logs:
    text = path.read_text(encoding="utf-8", errors="replace")
    if "[RESULT] PASS" not in text:
        raise SystemExit(f"missing PASS result: {path.name}")
    if f"[RTL-DESIGN-ID] {design_id}" not in text:
        raise SystemExit(f"missing design binding: {path.name}")
print(
    "[V10B-MODULE-FINAL] "
    f"tests=113 passed=113 failed=0 design_id={design_id}"
)
PY

write_status "RUNNING" "functional-current" "module=113/113"
make -C "${repo_root}/npc/rv64" check-functional-aggregate
mkdir -p "${functional_dir}"
cp \
  "${repo_root}/npc/rv64/eval/ppa/evidence/functional-aggregate-current.json" \
  "${repo_root}/npc/rv64/eval/ppa/evidence/functional-aggregate-result.json" \
  "${repo_root}/npc/rv64/eval/ppa/evidence/functional-aggregate.log" \
  "${functional_dir}/"

python3 - "${functional_dir}/functional-aggregate-result.json" "${design_id}" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
design_id = sys.argv[2]
if result.get("status") != "PASS" or result.get("exit_code") != 0:
    raise SystemExit("functional aggregate is not PASS")
if result.get("design_id") != design_id:
    raise SystemExit("functional aggregate design identity mismatch")
print(
    "[V10B-FUNCTIONAL-FINAL] "
    f"status=PASS exit_code=0 design_id={design_id}"
)
PY

write_status "RUNNING" "architecture-current" "functional=PASS"
bash "${run_dir}/run_architecture_current.sh"

python3 - \
  "${run_dir}/architecture/final-architecture-hard-gates.json" \
  "${design_id}" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
design_id = sys.argv[2]
if result.get("overall_status") != "GREEN" or result.get("exit_code") != 0:
    raise SystemExit("architecture aggregate is not GREEN")
if result.get("rtl_source_set", {}).get("design_id") != design_id:
    raise SystemExit("architecture aggregate design identity mismatch")
print(
    "[V10B-LAYERED-FINAL] "
    f"module=113/113 functional=PASS architecture=GREEN design_id={design_id}"
)
PY

write_status \
  "PASS" \
  "layered-current" \
  "module=113/113;functional=PASS;architecture=GREEN;design_id=${design_id}"
trap - EXIT
