#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog processor verification only.  This runner
# measures fetch/decode/rename/dispatch/issue/execute/retire width, full
# ProducerId and payload lifecycle, independent RTL sink acceptance, fixed
# window behavior and natural holder drain with repository-local EDA tools.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/width_continuity_evidence.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/width-continuity.log"
EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
MUTATION_DIR="$RUN_DIR/evidence/mutations"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v9a-di2-focused.XXXXXX")
SUITE_RUN_ID="v9a-di2-$(date -u +%Y%m%dT%H%M%SZ)-$$"
IVFLAGS_BASE="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v9a-di2-focused.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V9A-DI2-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR/evidence/final-run") rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe final evidence path: $EVIDENCE_DIR" ;;
esac
case "$MUTATION_DIR" in
  "$RUN_DIR/evidence/mutations") rm -rf -- "$MUTATION_DIR" ;;
  *) fail "unsafe mutation evidence path: $MUTATION_DIR" ;;
esac
mkdir -p \
  "$EVIDENCE_DIR/focused/assert" \
  "$EVIDENCE_DIR/focused/release" \
  "$EVIDENCE_DIR/stall-probe" \
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

# Remove only the DI-2 record, then rebuild the other eight architecture
# records against the current complete RTL design and current proof tooling.
python3 "$ARCH_BUILDER" reset-record --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/static/reset-record.log" 2>&1 ||
  fail "failed to remove the prior DI-2 record"
make -C "$NPC_HOME" check-frontend-ii1 \
  > "$EVIDENCE_DIR/static/same-design-predecessors.log" 2>&1 ||
  fail "same-design architecture predecessor refresh failed"
require_marker '[V8Z-DI1-RUNNER][PASS]' \
  "$EVIDENCE_DIR/static/same-design-predecessors.log"

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.pre.sha256" \
  > "$EVIDENCE_DIR/static/source-snapshot-pre.log" 2>&1 ||
  fail "pre-run DI-2 source snapshot failed"

run_profile() {
  local profile=$1
  local ivflags=$2
  local result="$EVIDENCE_DIR/focused/$profile"
  local build="$TEMP_DIR/build-$profile"
  make -B -C "$TB_HOME" \
    BUILD_DIR="$build" RESULT_DIR="$result" IVFLAGS="$ivflags" \
    v9a-width-continuity \
    > "$EVIDENCE_DIR/static/focused-$profile.make.log" 2>&1 ||
    fail "$profile width-continuity simulation failed"
  local log="$result/logs/tb_ooo_core_top_glue_v9a_width_continuity.log"
  require_clean_pass "$log"
  require_marker '[V9A-DI2-ANCHOR]' "$log"
  require_marker '[V9A-DI2-METRIC]' "$log"
  require_marker '[V9A-DI2-IDENTITY]' "$log"
  require_marker '[V9A-DI2-DRAIN]' "$log"
  [[ "$(grep -F -c '[V9A-DI2-TRACE]' "$log" || true)" -eq 64 ]] ||
    fail "$profile trace does not contain exactly 64 cycles"
}

run_profile assert "$IVFLAGS_BASE -DOOO_ASSERT"
run_profile release "$IVFLAGS_BASE"

# The probe perturbs only testbench request admission on measurement beat 17.
# Compile must succeed and the unchanged fixed window must reject dynamically.
STALL_LOG="$EVIDENCE_DIR/stall-probe/logs/tb_ooo_core_top_glue_v9a_width_stall_probe.log"
set +e
make -B -C "$TB_HOME" \
  BUILD_DIR="$TEMP_DIR/build-stall" \
  RESULT_DIR="$EVIDENCE_DIR/stall-probe" \
  IVFLAGS="$IVFLAGS_BASE" \
  "$STALL_LOG" \
  > "$EVIDENCE_DIR/static/stall-probe.make.log" 2>&1
stall_rc=$?
set -e
[[ "$stall_rc" -ne 0 ]] || fail "fixed-window stall probe unexpectedly passed"
[[ -f "$STALL_LOG" ]] || fail "fixed-window stall probe log is missing"
require_marker '[RESULT] FAIL status=1' "$STALL_LOG"
require_marker \
  '[V9A-WIDTH][FAIL] cycle=17 boundary=0 width=0 expected=2' \
  "$STALL_LOG"
if grep -Fq 'compile returned nonzero' "$STALL_LOG"; then
  fail "fixed-window stall probe failed to compile"
fi

python3 "$RUN_DIR/run-v9a-mutations.py" \
  --suite-run-id "$SUITE_RUN_ID" \
  > "$EVIDENCE_DIR/static/mutations.log" 2>&1 ||
  fail "compile-success local RV64 RTL mutations failed"
require_marker \
  '[V9A-MUTATIONS] compile_success=11/11 dynamic_rejected=11/11 PASS' \
  "$EVIDENCE_DIR/static/mutations.log"

regression_names=(
  tb_ooo_core_top_glue
  tb_ooo_fetch_packet_fifo
  tb_ooo_alu_decode_backend
  tb_ooo_dispatch_backend
  tb_ooo_int_issue_queue
  tb_ooo_int_backend
  tb_ooo_rob
  tb_pipe_stage_reg
)
regression_targets=()
for name in "${regression_names[@]}"; do
  regression_targets+=("$EVIDENCE_DIR/regressions/logs/$name.log")
done
make -B -C "$TB_HOME" \
  BUILD_DIR="$TEMP_DIR/build-regressions" \
  RESULT_DIR="$EVIDENCE_DIR/regressions" \
  IVFLAGS="$IVFLAGS_BASE -DOOO_ASSERT" \
  "${regression_targets[@]}" \
  > "$EVIDENCE_DIR/static/regressions.make.log" 2>&1 ||
  fail "adjacent local RV64 pipeline regressions failed"
for log in "${regression_targets[@]}"; do
  require_clean_pass "$log"
done

(cd "$REPO_ROOT" && python3 -m unittest -v \
  npc.rv64.eval.ppa.tests.test_architecture_hard_gates \
  npc.rv64.eval.ppa.tests.test_directed_evidence_manifest \
  npc.rv64.eval.ppa.tests.test_frontend_ii1_evidence \
  npc.rv64.eval.ppa.tests.test_width_continuity_evidence) \
  > "$EVIDENCE_DIR/static/architecture-unit.log" 2>&1 ||
  fail "architecture evidence unit suite failed"

make -C "$NPC_HOME" check-contract \
  > "$EVIDENCE_DIR/static/check-contract.log" 2>&1 ||
  fail "local RV64 RTL contract gate failed"
require_marker 'check-contract: PASS' "$EVIDENCE_DIR/static/check-contract.log"

git -C "$REPO_ROOT" diff --check -- \
  npc/rv64/Makefile \
  npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
  npc/rv64/eval/ppa/tools/width_continuity_evidence.py \
  npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py \
  npc/rv64/eval/ppa/tests/test_width_continuity_evidence.py \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv \
  .github/task-runs/2026-07-21-rv64-v9a-width-continuity \
  > "$EVIDENCE_DIR/static/diff-check.log" 2>&1 ||
  fail "scoped diff check failed"

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.post.sha256" \
  > "$EVIDENCE_DIR/static/source-snapshot-post.log" 2>&1 ||
  fail "post-run DI-2 source snapshot failed"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical DI-2 proof sources changed during execution"

cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-di2.json"
builder_args=(
  --repo-root "$REPO_ROOT"
  --suite-run-id-file "$EVIDENCE_DIR/suite-run-id.txt"
  --width-assert-log "$EVIDENCE_DIR/focused/assert/logs/tb_ooo_core_top_glue_v9a_width_continuity.log"
  --width-release-log "$EVIDENCE_DIR/focused/release/logs/tb_ooo_core_top_glue_v9a_width_continuity.log"
  --stall-log "$STALL_LOG"
)
for log in "${regression_targets[@]}"; do
  builder_args+=(--regression-log "$log")
done
builder_args+=(
  --mutation-summary "$MUTATION_DIR/summary.json"
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256"
  --sources-post "$EVIDENCE_DIR/sources.post.sha256"
  --gate-log "$ARCH_LOG"
  --manifest "$ARCH_MANIFEST"
)
python3 "$ARCH_BUILDER" build "${builder_args[@]}" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "DI-2 evidence publication failed"
require_marker '[V9A-DI2-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

python3 - "$EVIDENCE_DIR/static/manifest-before-di2.json" \
  "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
siblings = {
    "frontend_ii1", "pair_matrix", "no_static_lane_semantics",
    "dual_memory_issue", "true_ooo_long_latency", "selective_scheduling",
    "memory_ordering", "speculation_recovery",
}
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("DI-2 publication changed the complete RTL design binding")
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
if set(before_tests) not in (siblings, siblings | {"width_continuity"}):
    raise SystemExit(f"pre-DI2 sibling inventory mismatch: {sorted(before_tests)}")
if set(after_tests) != siblings | {"width_continuity"}:
    raise SystemExit(f"post-DI2 inventory mismatch: {sorted(after_tests)}")
for name in siblings:
    if after_tests.get(name) != before_tests[name]:
        raise SystemExit(f"DI-2 publication changed sibling evidence: {name}")
PY

make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1 ||
  fail "nine-gate architecture aggregate remained RED"
for marker in \
  'DI-1: GREEN (0 red checks)' \
  'DI-2: GREEN (0 red checks)' \
  'DI-3: GREEN (0 red checks)' \
  'DI-4: GREEN (0 red checks)' \
  'DI-5: GREEN (0 red checks)' \
  'OOO-1: GREEN (0 red checks)' \
  'OOO-2: GREEN (0 red checks)' \
  'OOO-3: GREEN (0 red checks)' \
  'OOO-4: GREEN (0 red checks)' \
  'OVERALL: GREEN'; do
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
expected = {
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}
if (
    green != expected or architecture["overall_status"] != "GREEN"
    or architecture["exit_code"] != 0
):
    raise SystemExit(
        f"unexpected architecture result: green={sorted(green)} "
        f"overall={architecture['overall_status']}"
    )
payload = {
    "schema": "v9a-width-continuity-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "suite_run_id": suite_run_id,
    "status": "PASS",
    "claim": "di2_width_continuity",
    "design_id": architecture["rtl_source_set"]["design_id"],
    "focused_profiles": {"assert": "PASS", "release": "PASS"},
    "fixed_window_stall_probe": "DYNAMIC_REJECT",
    "metrics": {"boundaries": 7, "cycles": 64, "uops_per_boundary": 128,
                "independent_alu_ipc": 2.0},
    "mutations": {"required": 11, "compile_success": 11, "detected": 11},
    "regressions": {"required": 8, "passed": 8},
    "architecture": {"green": sorted(green), "overall": "GREEN"},
    "ppa": "UNQUALIFIED",
    "promotion_eligible": False,
}
pathlib.Path(output_path).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

printf '[V9A-DI2-RUNNER][PASS] suite_run_id=%s focused=2 stall=1 mutations=11/11 regressions=8/8 DI-2=GREEN architecture=GREEN ppa=UNQUALIFIED\n' \
  "$SUITE_RUN_ID" | tee "$EVIDENCE_DIR/final.log"
