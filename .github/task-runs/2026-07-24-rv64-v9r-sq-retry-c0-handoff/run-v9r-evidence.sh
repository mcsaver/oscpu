#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
tb_dir="$repo_root/npc/rv64/testbench"
backend_rtl="$repo_root/npc/rv64/vsrc/execute/OooIntBackend.v"
bridge_rtl="$repo_root/npc/rv64/vsrc/memory/OooMemAxiBridge.v"
backend_tb="$repo_root/npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
bridge_tb="$repo_root/npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv"
mutator="$run_dir/mutate-v9r-sq-retry-c0.py"
evidence="$run_dir/evidence"
baseline="$evidence/baseline"

mkdir -p "$baseline"

rtl_design_sha() {
  python3 - "$repo_root" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

source_sha, _ = arch.rtl_binding(root)
print(source_sha)
PY
}

source_files=(
  "$run_dir/run-v9r-evidence.sh"
  "$run_dir/mutate-v9r-sq-retry-c0.py"
  "$run_dir/close-control-event-current-design.py"
  "$run_dir/contract.md"
  "$repo_root/npc/rv64/testbench/Makefile"
  "$backend_tb"
  "$bridge_tb"
  "$backend_rtl"
  "$bridge_rtl"
  "$repo_root/npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md"
  "$repo_root/npc/rv64/design/specs/ooo-memory-producer-lease.md"
  "$repo_root/npc/rv64/design/specs/ooo-dual-memory-datapath.md"
  "$repo_root/npc/rv64/eval/ppa/tools/producer_holder_census.py"
  "$repo_root/npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
)
# producer-holder-census.json is an outer evidence envelope: its
# freeze_evidence hashes are refreshed after dynamic evidence is generated.
# Binding that whole JSON here creates a cross-run hash cycle.  The live census
# checker and its mutation tests remain bound below and validate the envelope
# independently.

rtl_design_sha_pre=$(rtl_design_sha)
sha256sum "${source_files[@]}" > "$evidence/source-before.sha256"

make -B -C "$tb_dir" \
  TESTS='tb_ooo_int_backend_v9r_sq_retry_c0 tb_ooo_mem_axi_bridge_v9r_sq_retry_c0' \
  EXTRA_TESTS= \
  BUILD_DIR="$baseline/build" \
  RESULT_DIR="$baseline/result" \
  RTL_EVIDENCE_SHA="$rtl_design_sha_pre" \
  run

backend_baseline_log="$baseline/result/logs/tb_ooo_int_backend_v9r_sq_retry_c0.log"
bridge_baseline_log="$baseline/result/logs/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log"
grep -Fq '[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS' \
  "$backend_baseline_log"
grep -Fq '[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS' \
  "$backend_baseline_log"
grep -Fq '[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] state=S_SQ_QUERY held=1 release=1 PASS' \
  "$bridge_baseline_log"
grep -Fq '[RESULT] PASS' "$backend_baseline_log"
grep -Fq '[RESULT] PASS' "$bridge_baseline_log"
printf 'PASS\n' > "$baseline/status"

run_backend_variant() {
  local case_name=$1
  local variant_dir="$evidence/$case_name"
  local mutant="$variant_dir/OooIntBackend.v"
  local log="$variant_dir/result/logs/tb_ooo_int_backend_v9r_sq_retry_c0.log"
  local rc

  mkdir -p "$variant_dir"
  python3 "$mutator" \
    --case "$case_name" \
    --source "$backend_rtl" \
    --out "$mutant"

  set +e
  make -B -C "$tb_dir" \
    TESTS=tb_ooo_int_backend_v9r_sq_retry_c0 \
    EXTRA_TESTS= \
    RTL_OOO_INT_BACKEND="$mutant" \
    BUILD_DIR="$variant_dir/build" \
    RESULT_DIR="$variant_dir/result" \
    RTL_EVIDENCE_SHA="$rtl_design_sha_pre" \
    run
  rc=$?
  set -e

  if [[ "$rc" -eq 0 ]]; then
    printf '[V9R-EVIDENCE][FAIL] %s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  test -s "$variant_dir/build/tb_ooo_int_backend_v9r_sq_retry_c0.vvp"
  grep -Fq '[COMPILE]' "$log"
  grep -Fq '[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed during full-flush barrier' \
    "$log"
  grep -Fq '[RESULT] FAIL' "$log"
  printf 'REJECTED_COMPILE_SUCCESS_VARIANT rc=%s\n' "$rc" \
    > "$variant_dir/status"
}

run_bridge_variant() {
  local case_name=bridge-retry-fire-open
  local variant_dir="$evidence/$case_name"
  local mutant="$variant_dir/OooMemAxiBridge.v"
  local log="$variant_dir/result/logs/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log"
  local rc

  mkdir -p "$variant_dir"
  python3 "$mutator" \
    --case "$case_name" \
    --source "$bridge_rtl" \
    --out "$mutant"

  set +e
  make -B -C "$tb_dir" \
    TESTS=tb_ooo_mem_axi_bridge_v9r_sq_retry_c0 \
    EXTRA_TESTS= \
    RTL_OOO_MEM_AXI_BRIDGE="$mutant" \
    BUILD_DIR="$variant_dir/build" \
    RESULT_DIR="$variant_dir/result" \
    RTL_EVIDENCE_SHA="$rtl_design_sha_pre" \
    run
  rc=$?
  set -e

  if [[ "$rc" -eq 0 ]]; then
    printf '[V9R-EVIDENCE][FAIL] %s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  test -s "$variant_dir/build/tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.vvp"
  grep -Fq '[COMPILE]' "$log"
  grep -Fq '[V9R-MEM-SQ-RETRY-C0-HANDOFF] bridge released SQ-query owner during full-flush barrier' \
    "$log"
  grep -Fq '[RESULT] FAIL' "$log"
  printf 'REJECTED_COMPILE_SUCCESS_VARIANT rc=%s\n' "$rc" \
    > "$variant_dir/status"
}

run_backend_variant backend-bank0-ready-open
run_backend_variant backend-bank1-ready-open
run_bridge_variant

rtl_design_sha_post=$(rtl_design_sha)
test "$rtl_design_sha_post" = "$rtl_design_sha_pre"
sha256sum "${source_files[@]}" > "$evidence/source-after.sha256"
cmp "$evidence/source-before.sha256" "$evidence/source-after.sha256"

sha256sum \
  "$backend_rtl" \
  "$bridge_rtl" \
  "$backend_tb" \
  "$bridge_tb" \
  "$mutator" \
  "$evidence/backend-bank0-ready-open/OooIntBackend.v" \
  "$evidence/backend-bank1-ready-open/OooIntBackend.v" \
  "$evidence/bridge-retry-fire-open/OooMemAxiBridge.v" \
  > "$evidence/binding.sha256"

python3 - \
  "$repo_root" \
  "$evidence/summary.json" \
  "$evidence/summary.md" \
  "$rtl_design_sha_pre" \
  "$rtl_design_sha_post" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
json_out = Path(sys.argv[2])
markdown_out = Path(sys.argv[3])
design_sha_pre = sys.argv[4]
design_sha_post = sys.argv[5]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def artifact(relative: str) -> dict[str, object]:
    path = (root / relative).resolve(strict=True)
    path.relative_to(root)
    if path.is_symlink() or not path.is_file():
        raise SystemExit(f"non-regular evidence artifact: {relative}")
    return {
        "path": relative,
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


source_paths = (
    ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/"
    "run-v9r-evidence.sh",
    ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/"
    "mutate-v9r-sq-retry-c0.py",
    ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/"
    "close-control-event-current-design.py",
    ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/contract.md",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-memory-producer-lease.md",
    "npc/rv64/design/specs/ooo-dual-memory-datapath.md",
    "npc/rv64/eval/ppa/tools/producer_holder_census.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
)
source_records = {
    relative: artifact(relative) for relative in source_paths
}
source_sha = hashlib.sha256(
    json.dumps(
        source_records,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
).hexdigest()


def variant(
    case_id: str,
    production_source: str,
    test_name: str,
    mutant_name: str,
    marker: str,
) -> dict[str, object]:
    prefix = (
        ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/"
        f"evidence/{case_id}"
    )
    status_path = root / f"{prefix}/status"
    status_text = status_path.read_text(encoding="utf-8")
    match = re.fullmatch(
        r"REJECTED_COMPILE_SUCCESS_VARIANT rc=([0-9]+)\n",
        status_text,
    )
    if match is None:
        raise SystemExit(f"{case_id}: malformed status")
    return {
        "id": case_id,
        "production_source": production_source,
        "test_name": test_name,
        "result": "REJECTED",
        "make_returncode": int(match.group(1)),
        "assertion_marker": marker,
        "mutated_rtl": artifact(f"{prefix}/{mutant_name}"),
        "compiled_image": artifact(f"{prefix}/build/{test_name}.vvp"),
        "log": artifact(f"{prefix}/result/logs/{test_name}.log"),
        "status": artifact(f"{prefix}/status"),
    }


baseline_prefix = (
    ".github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/"
    "evidence/baseline"
)
payload = {
    "schema": "npc-rv64-v9r-sq-retry-c0-evidence-v2",
    "result": "PASS",
    "design_id": f"sha256:{design_sha_pre}",
    "full_rtl_source_unchanged": design_sha_pre == design_sha_post,
    "rtl_design_id_before": f"sha256:{design_sha_pre}",
    "rtl_design_id_after": f"sha256:{design_sha_post}",
    "source_binding": {
        "sha256": source_sha,
        "file_count": len(source_records),
        "files": source_records,
    },
    "positive": {
        "backend_banks": 2,
        "forced_barrier_cases": 2,
        "natural_trap_head_cases": 1,
        "bridge_query_hold_cases": 1,
        "barrier_release_cases": 1,
    },
    "baseline": {
        "required": 2,
        "passed": 2,
        "tests": {
            "tb_ooo_int_backend_v9r_sq_retry_c0": {
                "compiled_image": artifact(
                    f"{baseline_prefix}/build/"
                    "tb_ooo_int_backend_v9r_sq_retry_c0.vvp"
                ),
                "log": artifact(
                    f"{baseline_prefix}/result/logs/"
                    "tb_ooo_int_backend_v9r_sq_retry_c0.log"
                ),
            },
            "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0": {
                "compiled_image": artifact(
                    f"{baseline_prefix}/build/"
                    "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.vvp"
                ),
                "log": artifact(
                    f"{baseline_prefix}/result/logs/"
                    "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0.log"
                ),
            },
        },
        "status": artifact(f"{baseline_prefix}/status"),
    },
    "compile_success_rtl_variants": [
        variant(
            "backend-bank0-ready-open",
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "tb_ooo_int_backend_v9r_sq_retry_c0",
            "OooIntBackend.v",
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier",
        ),
        variant(
            "backend-bank1-ready-open",
            "npc/rv64/vsrc/execute/OooIntBackend.v",
            "tb_ooo_int_backend_v9r_sq_retry_c0",
            "OooIntBackend.v",
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier",
        ),
        variant(
            "bridge-retry-fire-open",
            "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
            "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0",
            "OooMemAxiBridge.v",
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF] bridge released SQ-query "
            "owner during full-flush barrier",
        ),
    ],
    "promotion_eligible": False,
    "ppa_status": "diagnostic_unqualified",
}
json_out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
markdown_out.write_text(
    "\n".join(
        [
            "# V9R SQ-query retry C0 handoff evidence",
            "",
            f"- RTL design id: `sha256:{design_sha_pre}`",
            f"- source binding: `sha256:{source_sha}` ({len(source_records)} files)",
            "- backend baseline: PASS (bank0 + bank1 forced C0; real ROB trap-head C0)",
            "- bridge baseline: PASS (`S_SQ_QUERY` owner held, then released after barrier)",
            "- backend bank0 READY-open variant: compile-success, rejected by V9R assertion",
            "- backend bank1 READY-open variant: compile-success, rejected by V9R assertion",
            "- bridge retry-fire-open variant: compile-success, rejected by V9R assertion",
            "- promotion/PPA: not eligible; architecture remains diagnostic and unqualified",
            "",
        ]
    ),
    encoding="utf-8",
)
PY

printf '[V9R-SQ-RETRY-C0-EVIDENCE] baseline=PASS variants=3/3-rejected PASS\n'
