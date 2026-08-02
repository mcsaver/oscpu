#!/usr/bin/env bash
set -euo pipefail

# Local RV64 Verilog/SystemVerilog processor verification only.  This runner
# proves Bridge H1 and complete OooFrontend request/response/outstanding/FIFO
# initiation interval, PC identity, finite response backpressure recovery and
# final owner conservation using only the authorized repository and EDA tools.

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$RUN_DIR/../../.." && pwd)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
ARCH_BUILDER="$NPC_HOME/eval/ppa/tools/frontend_ii1_evidence.py"
IVFLAGS_BASE="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"
REUSE_CURRENT_PREDECESSORS="${RV64_ARCH_REUSE_CURRENT_PREDECESSORS:-0}"
PROOF_MODE="canonical-v8z"
TASK_RUN_ID="2026-07-21-rv64-v8z-frontend-ii1"
SCOPED_TASK_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scoped-task-run-id)
      [[ $# -ge 2 ]] || {
        printf '[V8Z-DI1-RUNNER][FAIL] missing scoped task-run id\n' >&2
        exit 1
      }
      SCOPED_TASK_RUN_ID=$2
      shift 2
      ;;
    *)
      printf '[V8Z-DI1-RUNNER][FAIL] unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$SCOPED_TASK_RUN_ID" ]]; then
  [[ "$SCOPED_TASK_RUN_ID" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-rv64-([a-z0-9][a-z0-9._-]*)$ ]] || {
    printf '[V8Z-DI1-RUNNER][FAIL] malformed scoped task-run id\n' >&2
    exit 1
  }
  TASK_RUN_ID="$SCOPED_TASK_RUN_ID"
  PROOF_MODE="task-run-v1"
  TASK_RUN_DIR="$REPO_ROOT/.github/task-runs/$TASK_RUN_ID"
  [[ -d "$TASK_RUN_DIR" ]] || {
    printf '[V8Z-DI1-RUNNER][FAIL] scoped task-run directory is absent\n' >&2
    exit 1
  }
  EVIDENCE_DIR="$TASK_RUN_DIR/evidence/di1-current"
  MUTATION_DIR="$TASK_RUN_DIR/evidence/di1-mutations"
  ARCH_MANIFEST="$TASK_RUN_DIR/evidence/architecture-current.json"
  ARCH_LOG="$TASK_RUN_DIR/evidence/frontend-ii1.log"
  SUITE_TAG=${TASK_RUN_ID#*-rv64-}
  SUITE_TAG=${SUITE_TAG%%-*}
else
  TASK_RUN_DIR="$RUN_DIR"
  EVIDENCE_DIR="$RUN_DIR/evidence/final-run"
  MUTATION_DIR="$RUN_DIR/evidence/mutations"
  ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
  ARCH_LOG="$NPC_HOME/eval/ppa/evidence/frontend-ii1.log"
  SUITE_TAG="v8z"
fi

TEMP_PREFIX="${TMPDIR:-/tmp}/${SUITE_TAG}-di1-focused."
TEMP_DIR=$(mktemp -d "${TEMP_PREFIX}XXXXXX")
SUITE_RUN_ID="${SUITE_TAG}-di1-$(date -u +%Y%m%dT%H%M%SZ)-$$"

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "$TEMP_PREFIX"* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8Z-DI1-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$REUSE_CURRENT_PREDECESSORS" in
  0|1) ;;
  *) fail "RV64_ARCH_REUSE_CURRENT_PREDECESSORS must be 0 or 1" ;;
esac

if [[ "$PROOF_MODE" == "task-run-v1" ]]; then
  case "$EVIDENCE_DIR" in
    "$TASK_RUN_DIR/evidence/di1-current") rm -rf -- "$EVIDENCE_DIR" ;;
    *) fail "unsafe scoped DI-1 evidence path: $EVIDENCE_DIR" ;;
  esac
  case "$MUTATION_DIR" in
    "$TASK_RUN_DIR/evidence/di1-mutations") rm -rf -- "$MUTATION_DIR" ;;
    *) fail "unsafe scoped mutation evidence path: $MUTATION_DIR" ;;
  esac
  case "$ARCH_MANIFEST:$ARCH_LOG" in
    "$TASK_RUN_DIR/evidence/architecture-current.json:$TASK_RUN_DIR/evidence/frontend-ii1.log")
      rm -f -- "$ARCH_MANIFEST" "$ARCH_LOG"
      ;;
    *) fail "unsafe scoped DI-1 manifest/log path" ;;
  esac
else
  case "$EVIDENCE_DIR" in
    "$RUN_DIR/evidence/final-run") rm -rf -- "$EVIDENCE_DIR" ;;
    *) fail "unsafe final evidence path: $EVIDENCE_DIR" ;;
  esac
  case "$MUTATION_DIR" in
    "$RUN_DIR/evidence/mutations") rm -rf -- "$MUTATION_DIR" ;;
    *) fail "unsafe mutation evidence path: $MUTATION_DIR" ;;
  esac
fi
mkdir -p \
  "$EVIDENCE_DIR/focused/assert/frontend" \
  "$EVIDENCE_DIR/focused/assert/bridge" \
  "$EVIDENCE_DIR/focused/release/frontend" \
  "$EVIDENCE_DIR/focused/release/bridge" \
  "$EVIDENCE_DIR/regressions" \
  "$EVIDENCE_DIR/static"
printf '%s\n' "$SUITE_RUN_ID" > "$EVIDENCE_DIR/suite-run-id.txt"

if [[ "$PROOF_MODE" == "task-run-v1" ]]; then
  printf '%s\n' \
    'schema=rv64-di1-scoped-run-v1' \
    'mode=scoped' \
    "task_run_id=$TASK_RUN_ID" \
    "evidence_root=.github/task-runs/$TASK_RUN_ID/evidence" \
    'canonical_manifest_write=0' \
    'historical_evidence_write=0' \
    > "$EVIDENCE_DIR/static/scoped-run.txt"
  IVERILOG_PATH=$(readlink -f -- "$(command -v iverilog)")
  VVP_PATH=$(readlink -f -- "$(command -v vvp)")
  printf '%s\n' \
    'schema=rv64-di1-simulator-config-v1' \
    'target=v8z-frontend-ii1' \
    "assert_ivflags=$IVFLAGS_BASE -DOOO_ASSERT" \
    "release_ivflags=$IVFLAGS_BASE" \
    "mutation_ivflags=$IVFLAGS_BASE -DOOO_ASSERT" \
    "iverilog $(sha256sum "$IVERILOG_PATH" | cut -d' ' -f1) $IVERILOG_PATH" \
    "vvp $(sha256sum "$VVP_PATH" | cut -d' ' -f1) $VVP_PATH" \
    > "$EVIDENCE_DIR/static/simulator-config.txt"
fi

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
expected_green = {
    "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4"
}
expected_red = {"DI-1", "DI-2"}
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
    f"design_id={design_id} green=7 red=2 next=DI-1"
)
PY
}

# Canonical publication preserves the predecessor chain.  Scoped current-
# design publication intentionally carries only DI-1 and never writes either
# the canonical manifest or historical V8Z evidence.
if [[ "$PROOF_MODE" == "canonical-v8z" ]]; then
  python3 "$ARCH_BUILDER" reset-record --manifest "$ARCH_MANIFEST" \
    > "$EVIDENCE_DIR/static/reset-record.log" 2>&1 ||
    fail "failed to remove the prior DI-1 record"
  if [[ "$REUSE_CURRENT_PREDECESSORS" -eq 1 ]]; then
    verify_current_predecessors
  else
    make -C "$NPC_HOME" check-speculation-recovery \
      > "$EVIDENCE_DIR/static/same-design-predecessors.log" 2>&1 ||
      fail "same-design architecture predecessor refresh failed"
    require_marker '[V8Y-OOO4-RUNNER][PASS]' \
      "$EVIDENCE_DIR/static/same-design-predecessors.log"
  fi
fi

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.pre.sha256" \
  --proof-mode "$PROOF_MODE" \
  --task-run-id "$TASK_RUN_ID" \
  > "$EVIDENCE_DIR/static/source-snapshot-pre.log" 2>&1 ||
  fail "pre-run DI-1 source snapshot failed"

run_profile() {
  local profile=$1
  local ivflags=$2
  local frontend_result="$EVIDENCE_DIR/focused/$profile/frontend"
  local bridge_result="$EVIDENCE_DIR/focused/$profile/bridge"
  local frontend_build="$TEMP_DIR/build-$profile-frontend"
  local bridge_build="$TEMP_DIR/build-$profile-bridge"

  make -B -C "$TB_HOME" \
    BUILD_DIR="$frontend_build" RESULT_DIR="$frontend_result" \
    IVFLAGS="$ivflags" v8z-frontend-ii1 \
    > "$EVIDENCE_DIR/static/focused-$profile-frontend.make.log" 2>&1 ||
    fail "$profile complete frontend focused simulation failed"
  local frontend_log="$frontend_result/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log"
  require_clean_pass "$frontend_log"
  require_marker '[V8Z-FRONTEND-II1-INTEGRATION]' "$frontend_log"
  require_marker '[V8Z-FRONTEND-II1-BACKPRESSURE]' "$frontend_log"
  require_marker '[V8Z-FRONTEND-II1-DRAIN]' "$frontend_log"

  local bridge_log="$bridge_result/logs/tb_ooo_fetch_axi_bridge.log"
  make -B -C "$TB_HOME" \
    BUILD_DIR="$bridge_build" RESULT_DIR="$bridge_result" \
    IVFLAGS="$ivflags" "$bridge_log" \
    > "$EVIDENCE_DIR/static/focused-$profile-bridge.make.log" 2>&1 ||
    fail "$profile Bridge H1 focused simulation failed"
  require_clean_pass "$bridge_log"
  require_marker '[II1-IFU-HIT-TURNOVER]' "$bridge_log"
  require_marker '[II1-PAGING-CONTEXT]' "$bridge_log"
  require_marker '[II1-IFU-ELASTIC-SKID]' "$bridge_log"
}

run_profile assert "$IVFLAGS_BASE -DOOO_ASSERT"
run_profile release "$IVFLAGS_BASE"

python3 "$RUN_DIR/run-v8z-mutations.py" \
  --suite-run-id "$SUITE_RUN_ID" \
  --work-dir "$TEMP_DIR/mutations" \
  --evidence-dir "$MUTATION_DIR" \
  > "$EVIDENCE_DIR/static/mutations.log" 2>&1 ||
  fail "compile-success RTL source mutations failed"
require_marker \
  '[V8Z-MUTATIONS] compile_success=9/9 dynamic_rejected=9/9 PASS' \
  "$EVIDENCE_DIR/static/mutations.log"

regression_names=(
  tb_ooo_core_top_glue
  tb_ooo_fetch_flow_control
  tb_ooo_fetch_pc_outstanding_sequencer
  tb_ooo_fetch_packet_fifo
  tb_ooo_fetch_request_mux
  tb_ooo_frontend_action_gate
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
  fail "adjacent local RV64 frontend regressions failed"
for log in "${regression_targets[@]}"; do
  require_clean_pass "$log"
done

unit_modules=(
  npc.rv64.eval.ppa.tests.test_architecture_hard_gates
  npc.rv64.eval.ppa.tests.test_directed_evidence_manifest
  npc.rv64.eval.ppa.tests.test_frontend_ii1_evidence
)
if [[ "$PROOF_MODE" == "canonical-v8z" ]]; then
  unit_modules+=(npc.rv64.eval.ppa.tests.test_speculation_recovery_evidence)
fi
(cd "$REPO_ROOT" && python3 -B -m unittest -v "${unit_modules[@]}") \
  > "$EVIDENCE_DIR/static/architecture-unit.log" 2>&1 ||
  fail "architecture evidence unit suite failed"

if [[ "$PROOF_MODE" == "canonical-v8z" ]]; then
  make -C "$NPC_HOME" check-contract \
    > "$EVIDENCE_DIR/static/check-contract.log" 2>&1 ||
    fail "local RV64 RTL contract gate failed"
  require_marker 'check-contract: PASS' "$EVIDENCE_DIR/static/check-contract.log"

  git -C "$REPO_ROOT" diff --check -- \
    npc/rv64/Makefile \
    npc/rv64/eval/ppa/tools/architecture_hard_gates.py \
    npc/rv64/eval/ppa/tools/frontend_ii1_evidence.py \
    npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py \
    npc/rv64/eval/ppa/tests/test_frontend_ii1_evidence.py \
    npc/rv64/testbench/Makefile \
    npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv \
    .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1 \
    > "$EVIDENCE_DIR/static/diff-check.log" 2>&1 ||
    fail "scoped diff check failed"
fi

python3 "$ARCH_BUILDER" snapshot \
  --repo-root "$REPO_ROOT" \
  --output "$EVIDENCE_DIR/sources.post.sha256" \
  --proof-mode "$PROOF_MODE" \
  --task-run-id "$TASK_RUN_ID" \
  > "$EVIDENCE_DIR/static/source-snapshot-post.log" 2>&1 ||
  fail "post-run DI-1 source snapshot failed"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" \
  "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical DI-1 proof sources changed during execution"

if [[ "$PROOF_MODE" == "canonical-v8z" ]]; then
  cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before-di1.json"
fi
builder_args=(
  --repo-root "$REPO_ROOT"
  --suite-run-id-file "$EVIDENCE_DIR/suite-run-id.txt"
  --frontend-assert-log "$EVIDENCE_DIR/focused/assert/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log"
  --frontend-release-log "$EVIDENCE_DIR/focused/release/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log"
  --bridge-assert-log "$EVIDENCE_DIR/focused/assert/bridge/logs/tb_ooo_fetch_axi_bridge.log"
  --bridge-release-log "$EVIDENCE_DIR/focused/release/bridge/logs/tb_ooo_fetch_axi_bridge.log"
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
  --proof-mode "$PROOF_MODE"
  --task-run-id "$TASK_RUN_ID"
)
if [[ "$PROOF_MODE" == "task-run-v1" ]]; then
  builder_args+=(
    --scope-receipt "$EVIDENCE_DIR/static/scoped-run.txt"
    --simulator-config "$EVIDENCE_DIR/static/simulator-config.txt"
  )
fi
python3 "$ARCH_BUILDER" build "${builder_args[@]}" \
  > "$EVIDENCE_DIR/static/evidence-builder.log" 2>&1 ||
  fail "DI-1 evidence publication failed"
require_marker '[V8Z-DI1-EVIDENCE][PASS]' \
  "$EVIDENCE_DIR/static/evidence-builder.log"

if [[ "$PROOF_MODE" == "canonical-v8z" ]]; then
  python3 - "$EVIDENCE_DIR/static/manifest-before-di1.json" \
    "$ARCH_MANIFEST" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
siblings = {
    "pair_matrix", "no_static_lane_semantics", "dual_memory_issue",
    "true_ooo_long_latency", "selective_scheduling", "memory_ordering",
    "speculation_recovery",
}
if before.get("design_id") != after.get("design_id"):
    raise SystemExit("DI-1 publication changed the complete RTL design binding")
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
if set(before_tests) not in (siblings, siblings | {"frontend_ii1"}):
    raise SystemExit(f"pre-DI1 sibling inventory mismatch: {sorted(before_tests)}")
if set(after_tests) != siblings | {"frontend_ii1"}:
    raise SystemExit(f"post-DI1 inventory mismatch: {sorted(after_tests)}")
for name in siblings:
    if after_tests.get(name) != before_tests[name]:
        raise SystemExit(f"DI-1 publication changed sibling evidence: {name}")
PY
fi

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
architecture_rc=$?
set -e
[[ "$architecture_rc" -ne 0 ]] ||
  fail "architecture aggregate unexpectedly reported full closure"
if [[ "$PROOF_MODE" == "task-run-v1" ]]; then
  architecture_markers=(
    'DI-1: GREEN (0 red checks)'
    'DI-2: RED'
    'DI-3: RED'
    'DI-4: RED'
    'DI-5: RED'
    'OOO-1: RED'
    'OOO-2: RED'
    'OOO-3: RED'
    'OOO-4: RED'
    'OVERALL: RED'
  )
else
  architecture_markers=(
    'DI-1: GREEN (0 red checks)'
    'DI-2: RED'
    'DI-3: GREEN (0 red checks)'
    'DI-4: GREEN (0 red checks)'
    'DI-5: GREEN (0 red checks)'
    'OOO-1: GREEN (0 red checks)'
    'OOO-2: GREEN (0 red checks)'
    'OOO-3: GREEN (0 red checks)'
    'OOO-4: GREEN (0 red checks)'
    'OVERALL: RED'
  )
fi
for marker in "${architecture_markers[@]}"; do
  require_marker "$marker" "$EVIDENCE_DIR/static/architecture-gates.log"
done

python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$EVIDENCE_DIR/result.json" "$SUITE_RUN_ID" "$PROOF_MODE" \
  "$TASK_RUN_ID" <<'PY'
import datetime
import json
import pathlib
import sys

architecture_path, output_path, suite_run_id, proof_mode, task_run_id = sys.argv[1:]
architecture = json.loads(pathlib.Path(architecture_path).read_text(encoding="utf-8"))
green = {
    gate for gate, value in architecture["gates"].items()
    if value["status"] == "GREEN"
}
red = set(architecture["gates"]) - green
expected_green = (
    {"DI-1"}
    if proof_mode == "task-run-v1"
    else {
        "DI-1", "DI-3", "DI-4", "DI-5",
        "OOO-1", "OOO-2", "OOO-3", "OOO-4",
    }
)
expected_red = set(architecture["gates"]) - expected_green
if (
    green != expected_green or red != expected_red
    or architecture["overall_status"] != "RED"
    or architecture["exit_code"] != 1
):
    raise SystemExit(
        f"unexpected architecture closure: green={sorted(green)} "
        f"red={sorted(red)} overall={architecture['overall_status']}"
    )
payload = {
    "schema": "rv64-di1-current-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "task_run_id": task_run_id,
    "suite_run_id": suite_run_id,
    "proof_mode": proof_mode,
    "status": "PASS",
    "claim": "di1_frontend_ii1",
    "design_id": architecture["rtl_source_set"]["design_id"],
    "focused_profiles": {"assert": "PASS", "release": "PASS"},
    "metrics": {"required": 5, "passed": 5},
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

printf '[V8Z-DI1-RUNNER][PASS] mode=%s task_run_id=%s suite_run_id=%s focused=4 mutations=9/9 regressions=6/6 DI-1=GREEN overall=RED ppa=UNQUALIFIED\n' \
  "$PROOF_MODE" "$TASK_RUN_ID" "$SUITE_RUN_ID" | tee "$EVIDENCE_DIR/final.log"
