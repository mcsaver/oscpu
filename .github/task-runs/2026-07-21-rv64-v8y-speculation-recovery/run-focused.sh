#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog processor verification only.  This runner
# checks control-flow pipeline ordering, oldest-branch mispredict recovery,
# strictly-younger RTL holder removal, full-ProducerId completion/retirement
# accounting, and already-fired AXI transaction drain.  It touches only the
# authorized local repository, EDA simulators and generated evidence files.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/speculation_recovery_evidence.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/speculation-recovery.log"
EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
MUTATION_DIR="$RUN_DIR/evidence/mutations"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8y-ooo4-focused.XXXXXX")
SUITE_RUN_ID="v8y-ooo4-$(date -u +%Y%m%dT%H%M%SZ)-$$"
IVFLAGS_BASE="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8y-ooo4-focused.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8Y-OOO4-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR/evidence/final-run") rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe final evidence path: $EVIDENCE_DIR" ;;
esac
case "$MUTATION_DIR" in
  "$RUN_DIR/evidence/mutations") rm -rf -- "$MUTATION_DIR" ;;
  *) fail "unsafe RTL verification mutation evidence path: $MUTATION_DIR" ;;
esac
mkdir -p \
  "$EVIDENCE_DIR/focused/assert" \
  "$EVIDENCE_DIR/focused/release" \
  "$EVIDENCE_DIR/regressions" \
  "$EVIDENCE_DIR/static"
printf '%s\n' "$SUITE_RUN_ID" > "$EVIDENCE_DIR/suite-run-id.txt"

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
    fail "local RV64 simulation emitted a failure marker: $path"
  fi
}

# Re-running the canonical flow starts from the predecessor stage.  Remove only
# the OOO-4 record that this runner will rebuild; otherwise the older pair-
# matrix stage correctly rejects an out-of-stage sibling inventory.
python3 - "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
tests = payload.get("tests")
if isinstance(tests, dict) and tests.pop("speculation_recovery", None) is not None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)
PY

# Refresh DI-3/DI-4/DI-5 and OOO-1/OOO-2/OOO-3 through their canonical local
# RV64 runner before publishing OOO-4.  This prevents reuse of evidence from an
# older complete RTL source digest.
make -C "$NPC_HOME" check-memory-ordering \
  > "$EVIDENCE_DIR/static/same-design-predecessors.log" 2>&1 ||
  fail "same-design architecture predecessor refresh failed"
require_marker '[V8V-OOO3-RUNNER][PASS]' \
  "$EVIDENCE_DIR/static/same-design-predecessors.log"

run_focused() {
  local profile=$1
  local ivflags=$2
  local result_dir="$EVIDENCE_DIR/focused/$profile"
  local build_dir="$TEMP_DIR/build-focused-$profile"
  local make_log="$EVIDENCE_DIR/static/focused-$profile.make.log"
  make -B -C "$TB_HOME" \
    BUILD_DIR="$build_dir" RESULT_DIR="$result_dir" IVFLAGS="$ivflags" \
    v8y-speculation-recovery > "$make_log" 2>&1 ||
    fail "$profile V8Y focused simulation failed"
  local log="$result_dir/logs/tb_ooo_int_backend_v8y_speculation_recovery.log"
  [[ -s "$build_dir/tb_ooo_int_backend_v8y_speculation_recovery.vvp" ]] ||
    fail "$profile V8Y focused image is missing"
  require_clean_pass "$log"
}

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.pre.sha256" \
  > "$EVIDENCE_DIR/static/source-snapshot-pre.log" 2>&1 ||
  fail "pre-run OOO-4 source snapshot failed"

run_focused assert "$IVFLAGS_BASE -DOOO_ASSERT"
run_focused release "$IVFLAGS_BASE"

python3 "$RUN_DIR/run-v8y-mutations.py" \
  --suite-run-id "$SUITE_RUN_ID" \
  > "$EVIDENCE_DIR/static/mutations.log" 2>&1 ||
  fail "compile-success RTL verification mutations failed"
require_marker \
  '[V8Y-MUTATIONS] compile_success=9/9 dynamic_rejected=9/9 PASS' \
  "$EVIDENCE_DIR/static/mutations.log"

regression_targets=(
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_int_backend.log"
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_core_top_glue.log"
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_redirect_arbiter.log"
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_branch_bpu_update_gate.log"
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_mem_axi_bridge.log"
  "$EVIDENCE_DIR/regressions/logs/tb_ooo_dual_mem_bridge_wrapper.log"
)
make -B -C "$TB_HOME" \
  BUILD_DIR="$TEMP_DIR/build-regressions" \
  RESULT_DIR="$EVIDENCE_DIR/regressions" \
  IVFLAGS="$IVFLAGS_BASE -DOOO_ASSERT" \
  "${regression_targets[@]}" \
  > "$EVIDENCE_DIR/static/regressions.make.log" 2>&1 ||
  fail "adjacent local RV64 RTL regressions failed"
for log in "${regression_targets[@]}"; do
  require_clean_pass "$log"
done

(cd "$REPO_ROOT" && python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_architecture_hard_gates \
  npc.rv64.eval.ppa.tests.test_directed_evidence_manifest \
  npc.rv64.eval.ppa.tests.test_speculation_recovery_evidence) \
  > "$EVIDENCE_DIR/static/architecture-unit.log" 2>&1 ||
  fail "architecture evidence unit suite failed"

make -C "$NPC_HOME" check-contract \
  > "$EVIDENCE_DIR/static/check-contract.log" 2>&1 ||
  fail "local RV64 RTL contract gate failed"
require_marker 'check-contract: PASS' \
  "$EVIDENCE_DIR/static/check-contract.log"

git -C "$REPO_ROOT" diff --check -- \
  npc/rv64/Makefile \
  npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  npc/rv64/eval/ppa/tools/speculation_recovery_evidence.py \
  npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py \
  npc/rv64/eval/ppa/tests/test_speculation_recovery_evidence.py \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_int_backend.sv \
  .github/task-runs/2026-07-21-rv64-v8y-speculation-recovery \
  > "$EVIDENCE_DIR/static/diff-check.log" 2>&1 ||
  fail "scoped diff check failed"

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.post.sha256" \
  > "$EVIDENCE_DIR/static/source-snapshot-post.log" 2>&1 ||
  fail "post-run OOO-4 source snapshot failed"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical OOO-4 proof sources changed during execution"

cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-ooo4.json"
python3 "$ARCH_BUILDER" build \
  --repo-root "$REPO_ROOT" \
  --assert-log "$EVIDENCE_DIR/focused/assert/logs/tb_ooo_int_backend_v8y_speculation_recovery.log" \
  --release-log "$EVIDENCE_DIR/focused/release/logs/tb_ooo_int_backend_v8y_speculation_recovery.log" \
  --mutation-summary "$MUTATION_DIR/summary.json" \
  --suite-run-id-file "$EVIDENCE_DIR/suite-run-id.txt" \
  --backend-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_int_backend.log" \
  --glue-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_core_top_glue.log" \
  --redirect-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_redirect_arbiter.log" \
  --bpu-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_branch_bpu_update_gate.log" \
  --bridge-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_mem_axi_bridge.log" \
  --wrapper-regression-log "$EVIDENCE_DIR/regressions/logs/tb_ooo_dual_mem_bridge_wrapper.log" \
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256" \
  --sources-post "$EVIDENCE_DIR/sources.post.sha256" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "OOO-4 evidence publication failed"
require_marker '[V8Y-OOO4-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

python3 - "$EVIDENCE_DIR/static/manifest-before-ooo4.json" \
  "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
siblings = {
    "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
    "true_ooo_long_latency", "selective_scheduling", "memory_ordering",
}
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("OOO-4 publication changed the complete RTL design binding")
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
if set(before_tests) not in (siblings, siblings | {"speculation_recovery"}):
    raise SystemExit(f"pre-OOO4 sibling inventory mismatch: {sorted(before_tests)}")
if set(after_tests) != siblings | {"speculation_recovery"}:
    raise SystemExit(f"post-OOO4 inventory mismatch: {sorted(after_tests)}")
for name in siblings:
    if after_tests.get(name) != before_tests[name]:
        raise SystemExit(f"OOO-4 publication changed sibling evidence: {name}")
PY

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
architecture_rc=$?
set -e
[[ "$architecture_rc" -ne 0 ]] ||
  fail "architecture aggregate unexpectedly reported full closure"
for marker in \
  'DI-1: RED' \
  'DI-2: RED' \
  'DI-3: GREEN (0 red checks)' \
  'DI-4: GREEN (0 red checks)' \
  'DI-5: GREEN (0 red checks)' \
  'OOO-1: GREEN (0 red checks)' \
  'OOO-2: GREEN (0 red checks)' \
  'OOO-3: GREEN (0 red checks)' \
  'OOO-4: GREEN (0 red checks)' \
  'OVERALL: RED'; do
  require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
done

python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$EVIDENCE_DIR/result.json" "$SUITE_RUN_ID" <<'PY'
import datetime
import json
import pathlib
import sys

architecture_path, output_path, suite_run_id = sys.argv[1:]
architecture = json.loads(pathlib.Path(architecture_path).read_text(encoding="utf-8"))
green = {
    gate for gate, value in architecture["gates"].items()
    if value["status"] == "GREEN"
}
red = set(architecture["gates"]) - green
expected_green = {
    "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}
if (
    green != expected_green
    or red != {"DI-1", "DI-2"}
    or architecture["overall_status"] != "RED"
    or architecture["exit_code"] != 1
):
    raise SystemExit(
        f"unexpected architecture closure: green={sorted(green)} "
        f"red={sorted(red)} overall={architecture['overall_status']}"
    )
payload = {
    "schema": "v8y-speculation-recovery-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "suite_run_id": suite_run_id,
    "status": "PASS",
    "claim": "ooo4_speculation_recovery",
    "design_id": architecture["rtl_source_set"]["design_id"],
    "focused_profiles": {"assert": "PASS", "release": "PASS"},
    "metrics": {"required": 7, "passed": 7},
    "mutations": {"required": 9, "compile_success": 9, "detected": 9},
    "regressions": {"required": 6, "passed": 6},
    "architecture": {
        "green": sorted(green),
        "red": sorted(red),
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

printf '[V8Y-OOO4-RUNNER][PASS] suite_run_id=%s focused=2 mutations=9/9 regressions=6/6 OOO-4=GREEN DI-1/DI-2/overall=RED ppa=UNQUALIFIED\n' \
  "$SUITE_RUN_ID" | tee "$EVIDENCE_DIR/final.log"
