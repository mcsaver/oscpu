#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog processor verification only.  This runner
# checks control-flow pipeline ordering, oldest-branch mispredict recovery,
# strictly-younger RTL holder removal, full-ProducerId completion/retirement
# accounting, and already-fired AXI transaction drain.  It touches only the
# authorized local repository, EDA simulators and generated evidence files.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/speculation_recovery_evidence.py"
DEFAULT_ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
DEFAULT_ARCH_LOG="$NPC_HOME/eval/ppa/evidence/speculation-recovery.log"
DEFAULT_EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
DEFAULT_MUTATION_DIR="$RUN_DIR/evidence/mutations"
ARCH_MANIFEST=$(realpath -m -- "${V8Y_ARCH_MANIFEST:-$DEFAULT_ARCH_MANIFEST}")
ARCH_LOG=$(realpath -m -- "${V8Y_ARCH_LOG:-$DEFAULT_ARCH_LOG}")
EVIDENCE_DIR=$(realpath -m -- "${V8Y_EVIDENCE_DIR:-$DEFAULT_EVIDENCE_DIR}")
MUTATION_DIR=$(realpath -m -- "${V8Y_MUTATION_OUTPUT_DIR:-$DEFAULT_MUTATION_DIR}")
SCOPED_REFRESH_MODE=${V8Y_SCOPED_REFRESH_MODE:-0}
TASK_RUN_ID=${V8Y_TASK_RUN_ID:-2026-07-21-rv64-v8y-speculation-recovery}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8y-ooo4-focused.XXXXXX")
SUITE_RUN_ID="v8y-ooo4-$(date -u +%Y%m%dT%H%M%SZ)-$$"
IVFLAGS_BASE="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"
REUSE_CURRENT_PREDECESSORS="${RV64_ARCH_REUSE_CURRENT_PREDECESSORS:-0}"

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

case "$REUSE_CURRENT_PREDECESSORS" in
  0|1) ;;
  *) fail "RV64_ARCH_REUSE_CURRENT_PREDECESSORS must be 0 or 1" ;;
esac

case "$SCOPED_REFRESH_MODE" in
  0)
    PROOF_MODE=canonical-v8y
    [[ "$EVIDENCE_DIR" == "$DEFAULT_EVIDENCE_DIR" ]] ||
      fail "canonical mode requires the canonical evidence directory"
    [[ "$MUTATION_DIR" == "$DEFAULT_MUTATION_DIR" ]] ||
      fail "canonical mode requires the canonical mutation directory"
    [[ "$ARCH_MANIFEST" == "$DEFAULT_ARCH_MANIFEST" ]] ||
      fail "canonical mode requires the canonical architecture manifest"
    [[ "$ARCH_LOG" == "$DEFAULT_ARCH_LOG" ]] ||
      fail "canonical mode requires the canonical architecture log"
    rm -rf -- "$EVIDENCE_DIR" "$MUTATION_DIR"
    ;;
  1)
    PROOF_MODE=task-run-v1
    case "$EVIDENCE_DIR" in
      "$REPO_ROOT"/.github/task-runs/*/evidence/ooo4-current) ;;
      *) fail "unsafe scoped OOO-4 evidence path: $EVIDENCE_DIR" ;;
    esac
    SCOPED_EVIDENCE_ROOT=${EVIDENCE_DIR%/ooo4-current}
    [[ "$ARCH_MANIFEST" == "$SCOPED_EVIDENCE_ROOT/architecture-current.json" ]] ||
      fail "scoped manifest must share the selected task-run evidence root"
    [[ "$ARCH_LOG" == "$SCOPED_EVIDENCE_ROOT/speculation-recovery.log" ]] ||
      fail "scoped gate log must share the selected task-run evidence root"
    [[ "$MUTATION_DIR" == "$SCOPED_EVIDENCE_ROOT/ooo4-mutations" ]] ||
      fail "scoped mutation evidence must share the selected task-run evidence root"
    [[ "$EVIDENCE_DIR" == "$REPO_ROOT/.github/task-runs/$TASK_RUN_ID/evidence/ooo4-current" ]] ||
      fail "scoped task-run id does not match the selected evidence path"
    rm -rf -- "$EVIDENCE_DIR" "$MUTATION_DIR"
    rm -f -- "$ARCH_MANIFEST" "$ARCH_LOG"
    ;;
  *) fail "V8Y_SCOPED_REFRESH_MODE must be 0 or 1" ;;
esac
mkdir -p \
  "$EVIDENCE_DIR/focused/assert" \
  "$EVIDENCE_DIR/focused/release" \
  "$EVIDENCE_DIR/regressions" \
  "$EVIDENCE_DIR/static"
printf '%s\n' "$SUITE_RUN_ID" > "$EVIDENCE_DIR/suite-run-id.txt"
IVERILOG_BIN=$(command -v iverilog || true)
VVP_BIN=$(command -v vvp || true)
[[ -n "$IVERILOG_BIN" && -x "$IVERILOG_BIN" ]] ||
  fail "Icarus Verilog compiler is unavailable"
[[ -n "$VVP_BIN" && -x "$VVP_BIN" ]] ||
  fail "Icarus Verilog runtime is unavailable"
{
  printf 'schema=rv64-ooo4-simulator-config-v1\n'
  printf 'target=v8y-speculation-recovery\n'
  printf 'focused_assert_ivflags=%s\n' "$IVFLAGS_BASE -DOOO_ASSERT"
  printf 'focused_release_ivflags=%s\n' "$IVFLAGS_BASE"
  printf 'mutation_defines=-DOOO_ASSERT,-DV8X_BACKEND_BRIDGE_RECOVERY_FOCUSED,-DV8Y_SPECULATION_RECOVERY_FOCUSED\n'
  printf 'iverilog '
  sha256sum -- "$IVERILOG_BIN"
  printf 'vvp '
  sha256sum -- "$VVP_BIN"
} > "$EVIDENCE_DIR/static/simulator-config.txt"

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

verify_current_predecessors() {
  local result="$EVIDENCE_DIR/static/reused-predecessor-architecture.json"
  local log="$EVIDENCE_DIR/static/same-design-predecessors.log"
  local rc
  set +e
  make -C "$TB_HOME" \
    "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
    "ARCH_GATE_RESULT=$result" arch-gates > "$log" 2>&1
  rc=$?
  set -e
  [[ "$rc" -eq 2 ]] ||
    fail "reused predecessor make returned rc=$rc instead of partial RED"
  python3 -B - "$result" <<'PY' | tee -a "$log"
import json
import pathlib
import sys

value = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
expected_green = {"DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3"}
expected_red = {"DI-1", "DI-2", "OOO-4"}
gates = value.get("gates", {})
green = {name for name, item in gates.items() if item.get("status") == "GREEN"}
red = {name for name, item in gates.items() if item.get("status") == "RED"}
if green != expected_green or red != expected_red:
    raise SystemExit(
        f"reused predecessor inventory mismatch: green={sorted(green)} red={sorted(red)}"
    )
if value.get("overall_status") != "RED" or value.get("exit_code") != 1:
    raise SystemExit("reused predecessor aggregate is not the expected partial RED")
design_id = value.get("rtl_source_set", {}).get("design_id")
if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
    raise SystemExit("reused predecessor result lacks a complete RTL design id")
print(
    "[ARCH-CURRENT-PREDECESSORS][PASS] "
    f"design_id={design_id} green=6 red=3 next=OOO-4"
)
PY
}

# Re-running the canonical flow starts from the predecessor stage.  Scoped
# current-design refresh deliberately publishes only OOO-4 and does not replay
# or claim the six predecessor gates.
if [[ "$SCOPED_REFRESH_MODE" == 0 ]]; then
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
  # RV64 runner before publishing OOO-4.  This prevents reuse of evidence from
  # an older complete RTL source digest.
  if [[ "$REUSE_CURRENT_PREDECESSORS" -eq 1 ]]; then
    verify_current_predecessors
  else
    make -C "$NPC_HOME" check-memory-ordering \
      > "$EVIDENCE_DIR/static/same-design-predecessors.log" 2>&1 ||
      fail "same-design architecture predecessor refresh failed"
    require_marker '[V8V-OOO3-RUNNER][PASS]' \
      "$EVIDENCE_DIR/static/same-design-predecessors.log"
  fi
fi

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

V8Y_MUTATION_OUTPUT_DIR="$MUTATION_DIR" \
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

if [[ "$SCOPED_REFRESH_MODE" == 0 ]]; then
  make -C "$NPC_HOME" check-contract \
    > "$EVIDENCE_DIR/static/check-contract.log" 2>&1 ||
    fail "local RV64 RTL contract gate failed"
else
  bash "$NPC_HOME/eval/check-contract.sh" \
    > "$EVIDENCE_DIR/static/check-contract.log" 2>&1 ||
    fail "local RV64 RTL assertion contract gate failed"
fi
require_marker 'check-contract: PASS' \
  "$EVIDENCE_DIR/static/check-contract.log"

if [[ "$SCOPED_REFRESH_MODE" == 0 ]]; then
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
    fail "canonical scoped-path diff check failed"
else
  printf '[OOO4-SCOPED-SOURCE-BINDING] pre/post manifest replaces worktree enumeration PASS\n' \
    > "$EVIDENCE_DIR/static/diff-check.log"
fi

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.post.sha256" \
  > "$EVIDENCE_DIR/static/source-snapshot-post.log" 2>&1 ||
  fail "post-run OOO-4 source snapshot failed"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical OOO-4 proof sources changed during execution"

if [[ -f "$ARCH_MANIFEST" ]]; then
  cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-ooo4.json"
else
  printf '{"manifest_absent":true}\n' \
    > "$EVIDENCE_DIR/static/manifest-before-ooo4.json"
fi
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
  --simulator-config "$EVIDENCE_DIR/static/simulator-config.txt" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  --proof-mode "$PROOF_MODE" \
  --task-run-id "$TASK_RUN_ID" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "OOO-4 evidence publication failed"
require_marker '[V8Y-OOO4-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

python3 - "$EVIDENCE_DIR/static/manifest-before-ooo4.json" \
  "$ARCH_MANIFEST" "$SCOPED_REFRESH_MODE" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
scoped = sys.argv[3] == "1"
siblings = {
    "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
    "true_ooo_long_latency", "selective_scheduling", "memory_ordering",
}
if scoped:
    if before != {"manifest_absent": True}:
        raise SystemExit("scoped OOO-4 publication did not start from an empty manifest")
    if set(after.get("tests", {})) != {"speculation_recovery"}:
        raise SystemExit(
            f"scoped post-OOO4 inventory mismatch: {sorted(after.get('tests', {}))}")
    raise SystemExit(0)
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
if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  for marker in \
    'OOO-4: GREEN (0 red checks)' \
    'OVERALL: RED'; do
    require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
  done
else
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
fi

python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$EVIDENCE_DIR/result.json" "$SUITE_RUN_ID" "$SCOPED_REFRESH_MODE" <<'PY'
import datetime
import json
import pathlib
import sys

architecture_path, output_path, suite_run_id, scoped_mode = sys.argv[1:]
architecture = json.loads(pathlib.Path(architecture_path).read_text(encoding="utf-8"))
green = {
    gate for gate, value in architecture["gates"].items()
    if value["status"] == "GREEN"
}
red = set(architecture["gates"]) - green
expected_green = (
    {"OOO-4"}
    if scoped_mode == "1"
    else {"DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4"}
)
expected_red = set(architecture["gates"]) - expected_green
if (
    green != expected_green
    or red != expected_red
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
    "evidence_mode": (
        "task_run_scoped_current" if scoped_mode == "1" else "canonical_composed"
    ),
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

printf '[V8Y-OOO4-RUNNER][PASS] suite_run_id=%s mode=%s focused=2 mutations=9/9 regressions=6/6 OOO-4=GREEN overall=RED ppa=UNQUALIFIED\n' \
  "$SUITE_RUN_ID" "$SCOPED_REFRESH_MODE" | tee "$EVIDENCE_DIR/final.log"
