#!/usr/bin/env bash
set -euo pipefail

# This task-run owns a current-design CONTROL-EVENT slice, not a full-core
# freeze refresh.  Re-evaluate and cryptographically verify the canonical
# full-core candidate while preserving an honest GAP/UNQUALIFIED boundary.

run_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "${run_dir}" rev-parse --show-toplevel)"
candidate="${repo_root}/npc/rv64/eval/ppa/arch-stable/full-core-current.json"
checker="${repo_root}/npc/rv64/eval/ppa/tools/arch_stable_freeze.py"
architecture="${run_dir}/gates/final-architecture-hard-gates.json"
result="${run_dir}/gates/arch-stable-audit.json"
log="${run_dir}/gates/arch-stable-boundary.log"

mkdir -p "${run_dir}/gates"
exec > >(tee "${log}") 2>&1

python3 "${checker}" audit "${candidate}" --output "${result}"
python3 "${checker}" verify "${result}"

python3 - "${architecture}" "${result}" <<'PY'
import json
import pathlib
import sys

architecture = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
result = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
current_design_id = architecture["rtl_source_set"]["design_id"]
candidate_design_id = result["design_id"]
if result.get("architecture_freeze") != "GAP":
    raise SystemExit("full-core architecture freeze unexpectedly changed")
if result.get("ppa") != "UNQUALIFIED":
    raise SystemExit("full-core PPA claim unexpectedly changed")
if result.get("promotion_eligible") is not False:
    raise SystemExit("full-core promotion must remain false")
blockers = result.get("blockers")
if not isinstance(blockers, list) or not blockers:
    raise SystemExit("full-core GAP must retain an explicit blocker list")
print(
    "[V9O-ARCH-STABLE-BOUNDARY] "
    f"current_design_id={current_design_id} "
    f"candidate_design_id={candidate_design_id} "
    f"same_design={str(current_design_id == candidate_design_id).lower()} "
    f"blockers={len(blockers)} status=GAP ppa=UNQUALIFIED "
    "promotion_eligible=false"
)
PY
