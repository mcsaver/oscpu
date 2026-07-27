#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/memory_ordering_evidence.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/memory-ordering.log"
EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8v-ooo3-focused.XXXXXX")
RUN_ID="v8v-ooo3-$(date -u +%Y%m%dT%H%M%SZ)-$$"

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8v-ooo3-focused.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8V-OOO3-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/final-run) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe final evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"
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
  local extra_defines=${3:-}
  local result_dir="$EVIDENCE_DIR/$profile"
  local build_dir="$TEMP_DIR/build-$profile"
  local log="$result_dir/logs/$test.log"
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" RESULT_DIR="$result_dir" \
    IVFLAGS="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT $extra_defines" \
    "$log" > "$EVIDENCE_DIR/$profile.make.log" 2>&1 ||
    fail "$profile $test failed"
  [[ -s "$build_dir/$test.vvp" ]] || fail "$profile did not elaborate $test"
  require_clean_pass "$log"
}

# The predecessor runners replay the historical partial-closure sequence and
# therefore require an empty directed-test inventory.  Preserve only the three
# independent current-design records that this command does not rebuild, clear
# the working inventory, and restore them after OOO-3 has passed its own scoped
# aggregate.  This keeps the canonical command composable without accepting an
# unknown test id or overwriting a freshly rebuilt record.
PRESERVED_TESTS="$EVIDENCE_DIR/static/preserved-current-design-tests.json"
python3 - "$ARCH_MANIFEST" "$PRESERVED_TESTS" "$REPO_ROOT" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
preserved_path = pathlib.Path(sys.argv[2])
repo_root = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(repo_root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as arch

source_sha, _ = arch.rtl_binding(repo_root)
current_design_id = f"sha256:{source_sha}"
preserved = {
    "design_id": current_design_id,
    "tests": {},
    "discarded_stale_tests": [],
}
if path.is_file():
    payload = json.loads(path.read_text(encoding="utf-8"))
    tests = payload.get("tests", {})
    if not isinstance(tests, dict):
        raise SystemExit("architecture directed tests are not an object")
    rebuilt = {
        "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
        "true_ooo_long_latency", "selective_scheduling", "memory_ordering",
    }
    independent = {
        "frontend_ii1", "width_continuity", "speculation_recovery",
    }
    unknown = set(tests) - rebuilt - independent
    if unknown:
        raise SystemExit(
            f"memory-ordering composition found unknown tests: {sorted(unknown)}"
        )
    independent_tests = {
        name: tests[name] for name in sorted(set(tests) & independent)
    }
    if payload.get("design_id") == current_design_id:
        preserved["tests"] = independent_tests
    else:
        preserved["discarded_stale_tests"] = sorted(independent_tests)
    payload["tests"] = {}
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
preserved_path.write_text(
    json.dumps(preserved, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

# Rebuild DI-3/DI-4/DI-5/OOO-1/OOO-2 under the exact live RTL digest.  This is
# the predecessor closure, not cached evidence reuse.
make -C "$NPC_HOME" check-dual-memory-sustained-issue \
  > "$EVIDENCE_DIR/static/same-design-predecessors.log" 2>&1 ||
  fail "same-design DI-3/DI-4/DI-5/OOO-1/OOO-2 refresh failed"
require_marker '[V8U-F4-RUNNER][PASS]' \
  "$EVIDENCE_DIR/static/same-design-predecessors.log"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/dispatch-log.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-lq-mutations.py"
  "$RUN_DIR/run-focused.sh"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/mutate-v8s-dual-memory-core.py"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/run-focused.sh"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/design/arch/rv64-architecture-ppa-contract.md"
  "$NPC_HOME/design/arch/producer-holder-census.json"
  "$NPC_HOME/design/specs/ooo-load-queue.md"
  "$NPC_HOME/design/specs/ooo-store-bresp-precise-terminal.md"
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py"
  "$NPC_HOME/eval/ppa/tests/test_memory_ordering_evidence.py"
  "$NPC_HOME/eval/ppa/tests/test_producer_holder_census.py"
  "$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tools/directed_evidence_manifest.py"
  "$NPC_HOME/eval/ppa/tools/dual_memory_issue_evidence.py"
  "$ARCH_BUILDER"
  "$NPC_HOME/eval/ppa/tools/producer_holder_census.py"
  "$TB_HOME/Makefile"
  "$TB_HOME/common/tb_common.svh"
  "$TB_HOME/tests/tb_ooo_load_queue.sv"
  "$TB_HOME/tests/tb_ooo_store_queue.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_core_top_glue.sv"
  "$TB_HOME/tests/tb_ooo_dual_memory_sustained_issue.sv"
  "$NPC_HOME/vsrc/memory/OooLoadQueue.v"
  "$NPC_HOME/vsrc/control/OooCoreSliceControlGate.v"
  "$NPC_HOME/vsrc/control/OooControlFlushSequencer.v"
  "$NPC_HOME/vsrc/control/OooControlPlane.v"
  "$NPC_HOME/vsrc/core/NpcCoreTop.v"
  "$NPC_HOME/vsrc/core/OooCoreTopGlue.v"
  "$NPC_HOME/vsrc/decode/OooAluDecodeBackend.v"
  "$NPC_HOME/vsrc/execute/OooAluCoreSlice.v"
  "$NPC_HOME/vsrc/execute/OooExecuteBackend.v"
  "$NPC_HOME/vsrc/memory/OooMemoryAccess.v"
  "$NPC_HOME/vsrc/memory/OooMemInflightQueue.v"
  "$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
  "$NPC_HOME/vsrc/memory/OooMemoryRequestGate.v"
  "$NPC_HOME/vsrc/memory/OooStoreQueue.v"
  "$NPC_HOME/vsrc/include/define.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/writeback/OooRob.v"
  "$NPC_HOME/vsrc/execute/OooIntBackend.v"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

(cd "$REPO_ROOT" && python3 -m unittest \
  npc.rv64.eval.ppa.tests.test_architecture_hard_gates \
  npc.rv64.eval.ppa.tests.test_directed_evidence_manifest \
  npc.rv64.eval.ppa.tests.test_memory_ordering_evidence -v) \
  > "$EVIDENCE_DIR/static/architecture-unit.log" 2>&1 ||
  fail "architecture evidence unit suite failed"

run_tb lq tb_ooo_load_queue
run_tb sq tb_ooo_store_queue
run_tb backend tb_ooo_int_backend
run_tb backend-dual tb_ooo_int_backend '-DV8S_DUAL_MEMORY_FOCUSED'
run_tb glue tb_ooo_core_top_glue
run_tb sustained tb_ooo_dual_memory_sustained_issue

require_marker \
  '[V8V-LQ-DUAL-LIFECYCLE] alloc/issue/query/replay/completion/retire PASS' \
  "$EVIDENCE_DIR/lq/logs/tb_ooo_load_queue.log"
require_marker \
  '[V8V-LQ-WRAP-RECOVERY] wrap-age/unlaunched-drop/fired-drain PASS' \
  "$EVIDENCE_DIR/lq/logs/tb_ooo_load_queue.log"
require_marker \
  '[V8T-F3-SQ-QUERY] allow/forward/merge/youngest/partial/poison/terminal/dual PASS' \
  "$EVIDENCE_DIR/sq/logs/tb_ooo_store_queue.log"
require_marker \
  '[T4N-B-ERROR-PRECISE] va=0x0000000040001040 pa=0x0000000080001240 cause=7' \
  "$EVIDENCE_DIR/backend/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8S-DUAL-MEMORY-CORE] diff_bank_dual_req=1' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8V-CHECKPOINT-LQ-DRAIN] launched=2 tombstones=2 exact_terminals=2 ghosts=0 PASS' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8V-CHECKPOINT-OWNER-RECOVERY] load_unlaunched_clear=1 sq_unlaunched_clear=1 launched_rob_clear=2 tombstones=2 exact_terminals=2 redispatch_retire=1 ghosts=0 PASS' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8V-CHECKPOINT-IRREVOCABLE-WRITE] delayed_store_okay=1 same_edge_store_error=1 amo_write=1 request_exact=3 response_exact=3 commit_exact=3 sq_free_exact=2 apply_exact=3 redispatch_retire=2 PASS' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8V-CHECKPOINT-APPLY-GATE] raw_request=1 apply=0 local_flush=0 mem_flush=0,0 PASS' \
  "$EVIDENCE_DIR/glue/logs/tb_ooo_core_top_glue.log"
require_marker \
  '[V8V-LQ-RETIRE-AUTHORITY] lookup_ready_gates_commit=1 commit_free_coincident=1 PASS' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8T-F3-BACKEND-RETRY] bank0/bank1 capture-hold-reissue-kill + age arbitration + retry fence/F4 real-capacity admission + int/FP sinks + ready/cancel races PASS' \
  "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log"
require_marker \
  '[V8U-DI5-METRIC] trace_cycles=64 memory_issue_ipc_milli=2000 dual_issue_cycles=64 agu_accepts=64,64 translation_accepts=64,64 physical_lsq_queries=64,64 cache_admissions=64,64 completions=64,64' \
  "$EVIDENCE_DIR/sustained/logs/tb_ooo_dual_memory_sustained_issue.log"

python3 "$RUN_DIR/run-lq-mutations.py" \
  > "$EVIDENCE_DIR/static/mutations.log" 2>&1 ||
  fail "LQ compile-success mutations failed"
require_marker '"all_passed": true' "$EVIDENCE_DIR/static/mutations.log"

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical OOO-3 proof sources changed during execution"

cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-ooo3.json"
python3 "$ARCH_BUILDER" \
  --repo-root "$REPO_ROOT" \
  --lq-log "$EVIDENCE_DIR/lq/logs/tb_ooo_load_queue.log" \
  --sq-log "$EVIDENCE_DIR/sq/logs/tb_ooo_store_queue.log" \
  --backend-log "$EVIDENCE_DIR/backend/logs/tb_ooo_int_backend.log" \
  --backend-dual-log "$EVIDENCE_DIR/backend-dual/logs/tb_ooo_int_backend.log" \
  --glue-log "$EVIDENCE_DIR/glue/logs/tb_ooo_core_top_glue.log" \
  --sustained-log "$EVIDENCE_DIR/sustained/logs/tb_ooo_dual_memory_sustained_issue.log" \
  --mutation-results "$RUN_DIR/mutation-results.json" \
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256" \
  --sources-post "$EVIDENCE_DIR/sources.post.sha256" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "OOO-3 evidence publication failed"
require_marker '[V8V-OOO3-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

python3 - "$EVIDENCE_DIR/static/manifest-before-ooo3.json" \
  "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("OOO-3 publication changed the same-design binding")
siblings = {
    "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
    "true_ooo_long_latency", "selective_scheduling",
}
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
if set(before_tests) != siblings:
    raise SystemExit(f"pre-OOO3 sibling inventory mismatch: {sorted(before_tests)}")
if set(after_tests) != siblings | {"memory_ordering"}:
    raise SystemExit(f"post-OOO3 inventory mismatch: {sorted(after_tests)}")
for name in siblings:
    if after_tests.get(name) != before_tests[name]:
        raise SystemExit(f"OOO-3 publication changed sibling evidence: {name}")
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
for marker in \
  'DI-3: GREEN (0 red checks)' \
  'DI-4: GREEN (0 red checks)' \
  'DI-5: GREEN (0 red checks)' \
  'OOO-1: GREEN (0 red checks)' \
  'OOO-2: GREEN (0 red checks)' \
  'OOO-3: GREEN (0 red checks)' \
  'OOO-4: RED' \
  'OVERALL: RED'; do
  require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
done

python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$EVIDENCE_DIR/result.json" "$RUN_ID" <<'PY'
import datetime
import json
import pathlib
import sys

architecture_path, output_path, run_id = sys.argv[1:]
architecture = json.loads(pathlib.Path(architecture_path).read_text(encoding="utf-8"))
green = {
    gate for gate, value in architecture["gates"].items()
    if value["status"] == "GREEN"
}
expected_green = {"DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3"}
if green != expected_green or architecture["overall_status"] != "RED":
    raise SystemExit(
        f"unexpected architecture closure: green={sorted(green)} "
        f"overall={architecture['overall_status']}"
    )
payload = {
    "schema": "v8v-memory-ordering-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "run_id": run_id,
    "status": "PASS",
    "claim": "ooo3_memory_ordering",
    "design_id": architecture["rtl_source_set"]["design_id"],
    "metrics": {"required": 11, "passed": 11},
    "mutations": {"required": 9, "compile_success": 9, "detected": 9},
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

python3 - "$ARCH_MANIFEST" "$PRESERVED_TESTS" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
preserved_path = pathlib.Path(sys.argv[2])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
preserved = json.loads(preserved_path.read_text(encoding="utf-8"))
preserved_tests = preserved.get("tests", {})
tests = manifest.get("tests")
if not isinstance(tests, dict) or not isinstance(preserved_tests, dict):
    raise SystemExit("memory-ordering composition inventory is malformed")
if preserved_tests and preserved.get("design_id") != manifest.get("design_id"):
    raise SystemExit("preserved independent tests belong to another design_id")
collision = set(tests) & set(preserved_tests)
if collision:
    raise SystemExit(
        f"memory-ordering composition would overwrite tests: {sorted(collision)}"
    )
tests.update(preserved_tests)
manifest_path.write_text(
    json.dumps(manifest, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
print(
    "[V9N-MEMORY-ORDERING-COMPOSE] restored_tests="
    + ",".join(sorted(preserved_tests))
    + " PASS"
)
PY

printf '[V8V-OOO3-RUNNER][PASS] run_id=%s metrics=11 mutations=9 OOO-3=GREEN overall=RED ppa=UNQUALIFIED\n' \
  "$RUN_ID" | tee "$EVIDENCE_DIR/final.log"
