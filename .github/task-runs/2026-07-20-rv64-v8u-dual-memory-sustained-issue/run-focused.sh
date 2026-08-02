#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/dual_memory_issue_evidence.py"
DEFAULT_ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
DEFAULT_ARCH_LOG="$NPC_HOME/eval/ppa/evidence/dual-memory-issue.log"
DEFAULT_EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
DEFAULT_MUTATION_DIR="$RUN_DIR/evidence/mutations-final"
ARCH_MANIFEST=$(realpath -m -- "${V8U_ARCH_MANIFEST:-$DEFAULT_ARCH_MANIFEST}")
ARCH_LOG=$(realpath -m -- "${V8U_ARCH_LOG:-$DEFAULT_ARCH_LOG}")
EVIDENCE_DIR=$(realpath -m -- "${V8U_EVIDENCE_DIR:-$DEFAULT_EVIDENCE_DIR}")
MUTATION_DIR=$(realpath -m -- "${V8U_MUTATION_DIR:-$DEFAULT_MUTATION_DIR}")
F0_DIR="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/evidence/focused"
F1_DIR="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused"
F2_DIR="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused"
SCOPED_REFRESH_MODE=${V8U_SCOPED_REFRESH_MODE:-0}
F2_REPLAY_SOURCE_ROOT=$(realpath -m -- "${V8U_F2_REPLAY_SOURCE_ROOT:-$RUN_DIR/evidence}")
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8u-f4-focused.XXXXXX")
RUN_ID=${V8U_RUN_ID:-"v8u-f4-$(date -u +%Y%m%dT%H%M%SZ)-$$"}

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8u-f4-focused.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8U-F4-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$SCOPED_REFRESH_MODE" in
  0)
    [[ "$EVIDENCE_DIR" == "$DEFAULT_EVIDENCE_DIR" ]] ||
      fail "canonical evidence path mismatch"
    [[ "$MUTATION_DIR" == "$DEFAULT_MUTATION_DIR" ]] ||
      fail "canonical mutation path mismatch"
    [[ "$ARCH_MANIFEST" == "$DEFAULT_ARCH_MANIFEST" ]] ||
      fail "canonical architecture manifest path mismatch"
    [[ "$ARCH_LOG" == "$DEFAULT_ARCH_LOG" ]] ||
      fail "canonical architecture log path mismatch"
    rm -rf -- "$EVIDENCE_DIR" "$MUTATION_DIR"
    TASK_RUN_ID="2026-07-20-rv64-v8u-dual-memory-sustained-issue"
    ;;
  1)
    case "$EVIDENCE_DIR" in
      "$REPO_ROOT"/.github/task-runs/*/evidence/di5-current) ;;
      *) fail "unsafe scoped DI-5 evidence path: $EVIDENCE_DIR" ;;
    esac
    EVIDENCE_ROOT=${EVIDENCE_DIR%/di5-current}
    [[ "$MUTATION_DIR" == "$EVIDENCE_ROOT/di5-mutations" ]] ||
      fail "scoped mutation evidence must share the task-run root"
    [[ "$ARCH_MANIFEST" == "$EVIDENCE_ROOT/architecture-current.json" ]] ||
      fail "scoped architecture manifest must share the task-run root"
    [[ "$ARCH_LOG" == "$EVIDENCE_ROOT/dual-memory-issue.log" ]] ||
      fail "scoped architecture log must share the task-run root"
    TASK_RUN_ID=$(basename -- "$(dirname -- "$EVIDENCE_ROOT")")
    case "$F2_REPLAY_SOURCE_ROOT" in
      "$REPO_ROOT"/.github/task-runs/*/evidence) ;;
      *) fail "unsafe frozen F2 replay root: $F2_REPLAY_SOURCE_ROOT" ;;
    esac
    rm -rf -- "$EVIDENCE_DIR" "$MUTATION_DIR" "$EVIDENCE_ROOT/f2-replay"
    rm -f -- "$ARCH_MANIFEST" "$ARCH_LOG"
    ;;
  *) fail "V8U_SCOPED_REFRESH_MODE must be 0 or 1" ;;
esac
mkdir -p "$EVIDENCE_DIR/predecessors" "$EVIDENCE_DIR/static"
printf '%s\n' "$RUN_ID" > "$EVIDENCE_DIR/run-id.txt"

require_marker() {
  local marker=$1
  local path=$2
  [[ "$(grep -F -c "$marker" "$path" || true)" -eq 1 ]] ||
    fail "expected unique marker '$marker' in $path"
}

require_clean_pass() {
  local path=$1
  require_marker '[RESULT] PASS' "$path"
  if grep -Eq '\[RESULT\] FAIL|\[CHECK-FAIL\]|\[TIMEOUT\]|(^|[[:space:]])FATAL:' "$path"; then
    fail "simulation emitted a failure marker: $path"
  fi
}

run_tb() {
  local profile=$1
  local test=$2
  local defines=$3
  local result_dir="$EVIDENCE_DIR/$profile"
  local build_dir="$TEMP_DIR/build-$profile"
  local log="$result_dir/logs/$test.log"
  local ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon $defines"
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" RESULT_DIR="$result_dir" \
    IVFLAGS="$ivflags" "$log" > "$EVIDENCE_DIR/$profile.make.log" 2>&1 ||
    fail "$profile $test failed"
  [[ -s "$build_dir/$test.vvp" ]] || fail "$profile did not elaborate $test"
  require_clean_pass "$log"
}

if [[ "$SCOPED_REFRESH_MODE" == 0 ]]; then
  # Canonical composition retains the historical full predecessor refresh.
  make -C "$NPC_HOME" check-dual-memory-fabric-foundation \
    > "$EVIDENCE_DIR/predecessors/f0.log" 2>&1 || fail "F0 regressed"
  require_marker '[V8Q-F0][PASS]' "$EVIDENCE_DIR/predecessors/f0.log"
  make -C "$NPC_HOME" check-dual-memory-bridge-wrapper \
    > "$EVIDENCE_DIR/predecessors/f1.log" 2>&1 || fail "F1 regressed"
  require_marker '[V8R-F1][PASS]' "$EVIDENCE_DIR/predecessors/f1.log"
  make -C "$NPC_HOME" check-dual-memory-core-integration \
    > "$EVIDENCE_DIR/predecessors/f2.log" 2>&1 || fail "F2 regressed"
  require_marker '[V8S-F2][PASS]' "$EVIDENCE_DIR/predecessors/f2.log"

  DI5_PARENT_REFRESH_MODE=1 make -C "$NPC_HOME" check-pair-matrix \
    > "$EVIDENCE_DIR/static/same-design-pair-matrix.log" 2>&1 ||
    fail "same-design predecessor architecture refresh failed"
  require_marker '[V8P-RUNNER][PASS]' \
    "$EVIDENCE_DIR/static/same-design-pair-matrix.log"
else
  # F2 was already executed on this exact 146-file RTL design in the selected
  # task-run.  Copy only its compact result/manifests and retain immutable
  # origin hashes; the DI-5 builder permits only four enumerated non-DUT
  # evidence-orchestration drifts, never production RTL, TBs, simulator inputs
  # or F2 results.
  python3 - "$REPO_ROOT" "$F2_REPLAY_SOURCE_ROOT" \
    "$EVIDENCE_ROOT/f2-replay" <<'PY'
import hashlib
import json
import pathlib
import shutil
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
source_root = pathlib.Path(sys.argv[2]).resolve(strict=True)
output = pathlib.Path(sys.argv[3]).resolve()
if not source_root.is_relative_to(root / ".github/task-runs"):
    raise SystemExit("frozen F2 source is outside local task-runs")
relative_source = source_root.relative_to(root)
parts = relative_source.parts
if len(parts) < 4 or parts[:2] != (".github", "task-runs") or parts[-1] != "evidence":
    raise SystemExit("frozen F2 source root is malformed")
source_task_run_id = parts[2]
f1_current_task_run_id = "2026-07-20-rv64-v8r-dual-memory-bridge-wrapper"
f1_current_root = (
    root / ".github/task-runs" / f1_current_task_run_id / "evidence/focused"
)
sources = {
    "source_architecture_manifest": source_root / "architecture-current.json",
    "f1_current_result": f1_current_root / "result.json",
    "f1_current_sources_pre": f1_current_root / "sources.pre.sha256",
    "f1_current_sources_post": f1_current_root / "sources.post.sha256",
    "f1_current_mutation_summary": f1_current_root / "mutation-summary.log",
    "f1_current_profile_summary": f1_current_root / "profile-summary.log",
    "f1_current_final": f1_current_root / "final.log",
    "result": source_root / "f2-current/result.json",
    "sources_pre": source_root / "f2-current/sources.pre.sha256",
    "sources_post": source_root / "f2-current/sources.post.sha256",
    "mutation_summary": source_root / "f2-current/mutation-summary.log",
}
destinations = {
    "source_architecture_manifest": output / "source-architecture-current.json",
    "f1_current_result": output / "current-f1-result.json",
    "f1_current_sources_pre": output / "current-f1-sources.pre.sha256",
    "f1_current_sources_post": output / "current-f1-sources.post.sha256",
    "f1_current_mutation_summary": output / "current-f1-mutation-summary.log",
    "f1_current_profile_summary": output / "current-f1-profile-summary.log",
    "f1_current_final": output / "current-f1-final.log",
    "result": output / "result.json",
    "sources_pre": output / "sources.pre.sha256",
    "sources_post": output / "sources.post.sha256",
    "mutation_summary": output / "mutation-summary.log",
}
if any(not path.is_file() for path in sources.values()):
    raise SystemExit("frozen F2 replay input is incomplete")
output.mkdir(parents=True, exist_ok=True)
for role, source in sources.items():
    shutil.copyfile(source, destinations[role])

def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = json.loads(sources["source_architecture_manifest"].read_text(
    encoding="utf-8"))
design_id = manifest.get("design_id")
if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
    raise SystemExit("frozen F2 architecture design-id is missing")
origin = {
    "schema": "rv64-di5-f2-frozen-replay-v1",
    "source_task_run_id": source_task_run_id,
    "f1_current_task_run_id": f1_current_task_run_id,
    "source_design_id": design_id,
    "allowed_drift_paths": [
        ".github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/result.json",
        "npc/rv64/Makefile",
        "npc/rv64/design/arch/producer-holder-census.json",
        "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
        "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    ],
    "artifacts": {
        role: {
            "path": source.relative_to(root).as_posix(),
            "sha256": digest(source),
        }
        for role, source in sources.items()
    },
}
(output / "origin.json").write_text(
    json.dumps(origin, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
fi

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/mutate-v8u-f4.py"
  "$RUN_DIR/run-mutations.sh"
  "$RUN_DIR/run-focused.sh"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/design/arch/rv64-architecture-ppa-contract.md"
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tests/test_dual_memory_issue_evidence.py"
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py"
  "$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tools/directed_evidence_manifest.py"
  "$ARCH_BUILDER"
  "$TB_HOME/Makefile"
  "$TB_HOME/common/tb_common.svh"
  "$TB_HOME/scripts/check_ifu_icache_coherence_contract.py"
  "$TB_HOME/tests/tb_ooo_mem_inflight_queue.sv"
  "$TB_HOME/tests/tb_ooo_int_issue_queue.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_mem_axi_bridge.sv"
  "$TB_HOME/tests/tb_ooo_dual_memory_sustained_issue.sv"
  "$NPC_HOME/vsrc/memory/OooMemInflightQueue.v"
  "$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"
  "$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/execute/OooIntBackend.v"
  "$NPC_HOME/vsrc/memory/OooMemAxiBridge.v"
  "$NPC_HOME/vsrc/memory/OooDualMemBridgeWrapper.v"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

iverilog_path=$(realpath -- "$(command -v iverilog)")
vvp_path=$(realpath -- "$(command -v vvp)")
verilator_path=$(realpath -- "$(command -v verilator)")
{
  printf 'schema=rv64-di5-simulator-config-v1\n'
  printf 'target=v8u-dual-memory-sustained-issue\n'
  printf 'tb_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT\n'
  printf 'mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT\n'
  printf 'verilator_flags=--lint-only --timing -Wall -Wno-fatal -DOOO_ASSERT\n'
  printf 'iverilog %s %s\n' "$(sha256sum "$iverilog_path" | awk '{print $1}')" "$iverilog_path"
  printf 'vvp %s %s\n' "$(sha256sum "$vvp_path" | awk '{print $1}')" "$vvp_path"
  printf 'verilator %s %s\n' "$(sha256sum "$verilator_path" | awk '{print $1}')" "$verilator_path"
} > "$EVIDENCE_DIR/static/simulator-config.txt"

(cd "$REPO_ROOT" && python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_architecture_hard_gates \
  npc.rv64.eval.ppa.tests.test_dual_memory_issue_evidence \
  npc.rv64.eval.ppa.tests.test_directed_evidence_manifest -v) \
  > "$EVIDENCE_DIR/static/architecture-unit.log" 2>&1 ||
  fail "architecture evidence unit suite failed"

run_tb leaf-miq tb_ooo_mem_inflight_queue '-DOOO_ASSERT'
run_tb leaf-iq tb_ooo_int_issue_queue '-DOOO_ASSERT'
run_tb leaf-backend tb_ooo_int_backend '-DOOO_ASSERT'
run_tb leaf-bridge tb_ooo_mem_axi_bridge '-DOOO_ASSERT'
run_tb backend-partial tb_ooo_int_backend \
  '-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED'
run_tb system tb_ooo_dual_memory_sustained_issue '-DOOO_ASSERT'

require_marker \
  '[V8U-MIQ-NEXT-HEAD] exact current/next, wrap and effective-kill PASS' \
  "$EVIDENCE_DIR/leaf-miq/logs/tb_ooo_mem_inflight_queue.log"
require_marker \
  '[V8U-IQ-PAIR-PEEK] q_only_payload/ready_hold/atomic_pop2/full_pid PASS' \
  "$EVIDENCE_DIR/leaf-iq/logs/tb_ooo_int_issue_queue.log"
require_marker \
  '[V8U-F4-BRIDGE-STREAM] A/B/C consecutive hot responses and lookups PASS' \
  "$EVIDENCE_DIR/leaf-bridge/logs/tb_ooo_mem_axi_bridge.log"
require_marker \
  '[V8U-F4-PARTIAL-CONSUME] no_singleton_turnover=1 iq_pop2=0 old_pair_drains=2 new_pair_capture=1 PASS' \
  "$EVIDENCE_DIR/backend-partial/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8U-F4-BACKEND-NEXT] no-pop/killed-current fail-closed + exact A-pop/B-allow PASS' \
  "$EVIDENCE_DIR/backend-partial/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8U-DI5-METRIC] trace_cycles=64 memory_issue_ipc_milli=2000 dual_issue_cycles=64 agu_accepts=64,64 translation_accepts=64,64 physical_lsq_queries=64,64 cache_admissions=64,64 completions=64,64' \
  "$EVIDENCE_DIR/system/logs/tb_ooo_dual_memory_sustained_issue.log"

V8U_SCOPED_REFRESH_MODE="$SCOPED_REFRESH_MODE" \
V8U_MUTATION_DIR="$MUTATION_DIR" \
bash "$RUN_DIR/run-mutations.sh" \
  > "$EVIDENCE_DIR/static/mutations.log" 2>&1 ||
  fail "F4 compile-success mutations failed"
require_marker \
  '[V8U-F4-MUTATION][PASS] compile_success=7 dynamic_rejections=7 feedback_scc_recreated=1 baseline_unoptflat=0' \
  "$EVIDENCE_DIR/static/mutations.log"

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical F4 proof sources changed during execution"

if [[ -f "$ARCH_MANIFEST" ]]; then
  cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-di5.json"
else
  printf '{"manifest_absent":true}\n' \
    > "$EVIDENCE_DIR/static/manifest-before-di5.json"
fi
builder_args=(
  --repo-root "$REPO_ROOT"
  --system-log "$EVIDENCE_DIR/system/logs/tb_ooo_dual_memory_sustained_issue.log"
  --miq-log "$EVIDENCE_DIR/leaf-miq/logs/tb_ooo_mem_inflight_queue.log"
  --iq-log "$EVIDENCE_DIR/leaf-iq/logs/tb_ooo_int_issue_queue.log"
  --bridge-log "$EVIDENCE_DIR/leaf-bridge/logs/tb_ooo_mem_axi_bridge.log"
  --backend-log "$EVIDENCE_DIR/leaf-backend/logs/tb_ooo_int_backend.log"
  --backend-partial-log "$EVIDENCE_DIR/backend-partial/logs/tb_ooo_int_backend.log"
  --mutation-result "$MUTATION_DIR/result.log"
  --mutation-summary "$MUTATION_DIR/mutation-summary.tsv"
  --baseline-cone-result "$MUTATION_DIR/baseline/result.log"
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256"
  --sources-post "$EVIDENCE_DIR/sources.post.sha256"
  --gate-log "$ARCH_LOG"
  --manifest "$ARCH_MANIFEST"
  --task-run-id "$TASK_RUN_ID"
)
if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  builder_args+=(
    --proof-mode task-run-v1
    --simulator-config "$EVIDENCE_DIR/static/simulator-config.txt"
    --f2-replay-origin "$EVIDENCE_ROOT/f2-replay/origin.json"
    --f2-source-architecture-manifest \
      "$EVIDENCE_ROOT/f2-replay/source-architecture-current.json"
    --f2-result "$EVIDENCE_ROOT/f2-replay/result.json"
    --f2-sources-pre "$EVIDENCE_ROOT/f2-replay/sources.pre.sha256"
    --f2-sources-post "$EVIDENCE_ROOT/f2-replay/sources.post.sha256"
    --f2-mutation-summary "$EVIDENCE_ROOT/f2-replay/mutation-summary.log"
  )
else
  builder_args+=(
    --f0-result "$F0_DIR/result.json"
    --f1-result "$F1_DIR/result.json"
    --f2-result "$F2_DIR/result.json"
  )
fi
python3 "$ARCH_BUILDER" "${builder_args[@]}" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "DI-5 evidence publication failed"
require_marker '[V8U-F4-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

python3 - "$EVIDENCE_DIR/static/manifest-before-di5.json" \
  "$ARCH_MANIFEST" "$SCOPED_REFRESH_MODE" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
scoped = sys.argv[3] == "1"
if scoped:
    if before != {"manifest_absent": True}:
        raise SystemExit("scoped DI-5 publication did not start absent")
    if set(after.get("tests", {})) != {"dual_memory_issue"}:
        raise SystemExit("scoped DI-5 publication claimed sibling gates")
    raise SystemExit(0)
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("DI-5 publication changed the same-design binding")
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
siblings = {
    "pair_matrix", "no_static_lane_semantics",
    "true_ooo_long_latency", "selective_scheduling",
}
allowed_before = {frozenset(siblings), frozenset(siblings | {"dual_memory_issue"})}
if frozenset(before_tests) not in allowed_before:
    raise SystemExit(f"pre-DI5 sibling inventory mismatch: {sorted(before_tests)}")
if set(after_tests) != siblings | {"dual_memory_issue"}:
    raise SystemExit(f"post-DI5 inventory mismatch: {sorted(after_tests)}")
for name in siblings:
    record = before_tests[name]
    if after_tests.get(name) != record:
        raise SystemExit(f"DI-5 publication changed sibling evidence: {name}")
PY

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
architecture_rc=$?
set -e
[[ "$architecture_rc" -ne 0 ]] ||
  fail "architecture aggregate did not return the expected partial-closure RED"
if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  for marker in \
    'DI-5: GREEN (0 red checks)' \
    'OVERALL: RED'; do
    require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
  done
else
  for marker in \
    'DI-3: GREEN (0 red checks)' \
    'DI-4: GREEN (0 red checks)' \
    'DI-5: GREEN (0 red checks)' \
    'OOO-1: GREEN (0 red checks)' \
    'OOO-2: GREEN (0 red checks)' \
    'OOO-3: RED' \
    'OVERALL: RED'; do
    require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
  done
fi

python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$EVIDENCE_DIR/result.json" "$RUN_ID" "$SCOPED_REFRESH_MODE" <<'PY'
import datetime
import json
import pathlib
import sys

architecture_path, output_path, run_id, scoped_mode = sys.argv[1:]
architecture = json.loads(
    pathlib.Path(architecture_path).read_text(encoding="utf-8"))
green = {
    gate for gate, value in architecture["gates"].items()
    if value["status"] == "GREEN"
}
expected_green = (
    {"DI-5"}
    if scoped_mode == "1"
    else {"DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2"}
)
if green != expected_green or architecture["overall_status"] != "RED":
    raise SystemExit(
        f"unexpected architecture closure: green={sorted(green)} "
        f"overall={architecture['overall_status']}"
    )
payload = {
    "schema": "v8u-dual-memory-sustained-issue-evidence/v1",
    "generated_at_utc": datetime.datetime.now(
        datetime.timezone.utc).isoformat(),
    "run_id": run_id,
    "status": "PASS",
    "claim": "di5_sustained_dual_memory_issue",
    "evidence_mode": (
        "task_run_scoped_current"
        if scoped_mode == "1" else "canonical_composed"
    ),
    "design_id": architecture["rtl_source_set"]["design_id"],
    "metrics": {
        "trace_cycles": 64,
        "memory_issue_ipc": 2.0,
        "dual_issue_cycles": 64,
        "per_bank_faces": [64, 64],
    },
    "predecessors": (
        {"F2": "FROZEN_REPLAY_PASS", "F1": "EMBEDDED_PASS"}
        if scoped_mode == "1"
        else {"F0": "PASS", "F1": "PASS", "F2": "PASS"}
    ),
    "mutations": {
        "required": 7,
        "detected": 7,
        "compile_success": 7,
        "feedback_scc_recreated": 1,
        "baseline_unoptflat": 0,
    },
    "architecture": {
        "green": sorted(green),
        "red": sorted(set(architecture["gates"]) - green),
        "overall": "RED",
    },
    "ppa": "UNQUALIFIED",
    "promotion_eligible": False,
}
pathlib.Path(output_path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

printf '[V8U-F4-RUNNER][PASS] run_id=%s mode=%s trace=64 ipc=2.000 dual_cycles=64 per_bank_faces=64,64 mutations=7 DI-5=GREEN overall=RED ppa=UNQUALIFIED\n' \
  "$RUN_ID" "$SCOPED_REFRESH_MODE" | tee "$EVIDENCE_DIR/final.log"
