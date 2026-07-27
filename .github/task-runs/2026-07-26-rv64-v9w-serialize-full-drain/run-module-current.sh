#!/usr/bin/env bash
set -euo pipefail

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
status_path="${run_dir}/module-current.status"
driver_log="${run_dir}/module-current.driver.log"
result_dir="${run_dir}/module-current"
build_dir="${run_dir}/build-module-current"

write_status() {
  local state="$1"
  local detail="$2"
  printf 'state=%s\nstage=module-current\ndetail=%s\n' \
    "${state}" "${detail}" > "${status_path}"
}

on_exit() {
  local rc=$?
  if [[ ${rc} -ne 0 ]]; then
    write_status "FAIL" "rc=${rc}"
  fi
}
trap on_exit EXIT

exec > >(tee "${driver_log}") 2>&1
write_status "RUNNING" "compile-and-simulate"

rtl_sha="$(
  python3 - "${repo_root}" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as architecture

digest, _ = architecture.rtl_binding(root)
print(digest)
PY
)"
printf '[V9W-MODULE-CURRENT] design_id=sha256:%s state=START\n' "${rtl_sha}"

make -B -C "${repo_root}/npc/rv64/testbench" \
  "RTL_EVIDENCE_SHA=${rtl_sha}" \
  "BUILD_DIR=${build_dir}" \
  "RESULT_DIR=${result_dir}" \
  run

python3 - "${result_dir}/summary.txt" <<'PY'
import pathlib
import re
import sys

summary = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
fields = {
    key: int(value)
    for key, value in re.findall(
        r"^- (total|passed|failed): ([0-9]+)$", summary, re.MULTILINE
    )
}
if fields.get("total", 0) < 100:
    raise SystemExit(f"module inventory unexpectedly small: {fields}")
if fields.get("passed") != fields.get("total") or fields.get("failed") != 0:
    raise SystemExit(f"module aggregate is not all PASS: {fields}")
print(
    "[V9W-MODULE-CURRENT] "
    f"total={fields['total']} passed={fields['passed']} "
    f"failed={fields['failed']} status=PASS"
)
PY

write_status "PASS" "design_id=sha256:${rtl_sha}"
trap - EXIT
