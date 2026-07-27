#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
MUTATOR="$RUN_DIR/mutate-v8n-true-ooo-long-latency.py"
BUILDER="$NPC_HOME/eval/ppa/tools/true_ooo_long_latency_evidence.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/true-ooo-long-latency.log"
ARCH_REFRESH_MODE=${ARCH_REFRESH_MODE:-0}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8n-true-ooo.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8n-true-ooo.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8N-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"

BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
MULDIV="$NPC_HOME/vsrc/execute/OooMulDivUnit.v"
ROB="$NPC_HOME/vsrc/writeback/OooRob.v"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-focused.sh"
  "$MUTATOR"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/design/arch/rv64-architecture-ppa-contract.md"
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py"
  "$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tools/directed_evidence_manifest.py"
  "$BUILDER"
  "$TB_HOME/Makefile"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$BACKEND"
  "$MULDIV"
  "$ROB"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon'

run_make() {
  local label=$1
  local kind=${2:-current}
  local source=${3:-}
  local flags=${4:-$base_flags}
  local result_dir="$EVIDENCE_DIR/$label"
  local build_dir="$TEMP_DIR/build-$label"
  local make_log="$EVIDENCE_DIR/$label.make.log"
  local -a overrides=()

  case "$result_dir" in
    "$EVIDENCE_DIR"/*) ;;
    *) fail "unsafe result path: $result_dir" ;;
  esac
  case "$kind" in
    current) ;;
    backend) overrides+=("RTL_OOO_INT_BACKEND=$source") ;;
    muldiv) overrides+=("RTL_OOO_MULDIV_UNIT=$source") ;;
    rob) overrides+=("RTL_OOO_ROB=$source") ;;
    *) fail "unknown source kind: $kind" ;;
  esac

  set +e
  make -C "$TB_HOME" \
    TESTS=tb_ooo_int_backend \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$flags -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED" \
    "${overrides[@]}" run > "$make_log" 2>&1
  local rc=$?
  set -e
  printf '[MAKE-RC] %d\n' "$rc" >> "$make_log"
  return "$rc"
}

require_marker() {
  local marker=$1
  local log=$2
  grep -Fq "$marker" "$log" ||
    fail "missing marker in ${log#$REPO_ROOT/}: $marker"
}

require_clean_pass() {
  local log=$1
  require_marker '[RESULT] PASS' "$log"
  if grep -Eq '\[CHECK-FAIL\]|\[RESULT\] FAIL|(^|[[:space:]])FATAL:' "$log"; then
    fail "unexpected failure marker in ${log#$REPO_ROOT/}"
  fi
}

python3 -m unittest \
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py" \
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py" -v \
  > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1

for profile in release assert; do
  flags="$base_flags"
  if [[ "$profile" == assert ]]; then
    flags="$flags -DOOO_ASSERT"
  fi
  run_make "baseline-$profile" current '' "$flags" ||
    fail "focused baseline failed: $profile"
  log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_int_backend.log"
  require_marker '[V8N-ACTIVATION] scenario=load_miss' "$log"
  require_marker '[V8N-ACTIVATION] scenario=v8n MUL' "$log"
  require_marker '[V8N-ACTIVATION] scenario=v8n DIVU' "$log"
  require_marker '[V8N-TRUE-OOO-METRICS] load_miss=8 mul=8 div=8 rob_peak=9 retire_order_violations=0' "$log"
  require_marker '[V8N-TRUE-OOO-BINDING] load_issue=8 mul_issue=8 div_issue=8 load_dual=4 mul_dual=4 div_dual=4 load_owner_live_wb=8 mul_owner_live_wb=8 div_owner_live_wb=8 rob_valid_peak=9' "$log"
  require_marker '[V8N-TRUE-OOO-LONG-LATENCY] load-miss/mul/div exact-PID completion and ordered-retire PASS' "$log"
  require_clean_pass "$log"
  printf '[V8N-BASELINE][PASS] profile=%s scenarios=3/3\n' "$profile" \
    >> "$EVIDENCE_DIR/baseline-summary.log"
done

mutation_rows=(
  'serial_issue1|backend|OooIntBackend.v|load_miss|v8n load four dual-issue accept cycles'
  'miq_issue1_freeze|backend|OooIntBackend.v|load_miss|v8n load four dual-issue accept cycles'
  'muldiv_issue1_freeze|backend|OooIntBackend.v|v8n MUL|v8n MUL four dual-issue accept cycles'
  'retire_before_head_done|rob|OooRob.v|load_miss|v8n load no retirement before old completion'
  'load_owner_pid_truncate|backend|OooIntBackend.v|load_miss|v8n load completion identity prepared'
  'muldiv_owner_pid_truncate|muldiv|OooMulDivUnit.v|v8n MUL|v8n MUL buffered owner exact ProducerId'
  'muldiv_resp_pid_truncate|muldiv|OooMulDivUnit.v|v8n MUL|v8n MUL old WB exactly once'
)

source_for_kind() {
  case "$1" in
    backend) printf '%s\n' "$BACKEND" ;;
    muldiv) printf '%s\n' "$MULDIV" ;;
    rob) printf '%s\n' "$ROB" ;;
    *) return 1 ;;
  esac
}

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name kind basename activation failure <<< "$row"
  source=$(source_for_kind "$kind")
  mutant="$TEMP_DIR/mutants/$name/$basename"
  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    > "$EVIDENCE_DIR/mutation-$name.mutator.log" 2>&1

  if run_make "mutation-$name" "$kind" "$mutant"; then
    fail "mutation survived focused test: $name"
  fi
  vvp="$TEMP_DIR/build-mutation-$name/tb_ooo_int_backend.vvp"
  [[ -s "$vvp" ]] || fail "mutation did not elaborate successfully: $name"
  log="$EVIDENCE_DIR/mutation-$name/logs/tb_ooo_int_backend.log"
  require_marker "[V8N-ACTIVATION] scenario=$activation" "$log"
  require_marker "[CHECK-FAIL] $failure" "$log"
  require_marker '[RESULT] FAIL' "$log"
  if [[ "$name" == muldiv_issue1_freeze ]]; then
    require_marker '[V8N-ACTIVATION] scenario=v8n DIVU' "$log"
    require_marker '[CHECK-FAIL] v8n DIVU four dual-issue accept cycles' "$log"
  fi
  printf '[V8N-MUTATION][PASS] name=%s compile=PASS activation=PASS semantic_rejection=PASS\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
done

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical proof sources changed while running mutations"

python3 "$BUILDER" \
  --repo-root "$REPO_ROOT" \
  --release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_int_backend.log" \
  --assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_int_backend.log" \
  --mutation-summary "$EVIDENCE_DIR/mutation-summary.log" \
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256" \
  --sources-post "$EVIDENCE_DIR/sources.post.sha256" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/evidence-builder.log" 2>&1

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
arch_rc=$?
set -e
require_marker 'OOO-1: GREEN (0 red checks)' \
  "$EVIDENCE_DIR/static/architecture-gates.log"

if [[ "$ARCH_REFRESH_MODE" == 1 ]]; then
overall_status=$(python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$arch_rc" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
observed_rc = int(sys.argv[2])
if result["gates"]["OOO-1"]["status"] != "GREEN":
    raise SystemExit("refresh did not establish OOO-1")
if result["overall_status"] not in {"RED", "GREEN"}:
    raise SystemExit("architecture inventory has an invalid aggregate status")
expected_rc = 0 if result["overall_status"] == "GREEN" else 1
make_rc_ok = observed_rc == 0 if expected_rc == 0 else observed_rc != 0
if result["exit_code"] != expected_rc or not make_rc_ok:
    raise SystemExit("architecture aggregate exit code/status mismatch")
print(result["overall_status"])
PY
)
printf '[V8N-RUNNER][PASS] refresh=1 baselines=6/6 mutations=%d/%d OOO-1=GREEN overall=%s\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" "$overall_status" |
  tee "$EVIDENCE_DIR/runner-summary.log"
else
require_marker 'OOO-2: GREEN (0 red checks)' \
  "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'DI-4: GREEN (0 red checks)' \
  "$EVIDENCE_DIR/static/architecture-gates.log"
overall_status=$(python3 - "$EVIDENCE_DIR/static/architecture-result.json" \
  "$arch_rc" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
observed_rc = int(sys.argv[2])
for gate in ("OOO-1", "OOO-2"):
    if result["gates"][gate]["status"] != "GREEN":
        raise SystemExit(f"{gate} is not GREEN")
if result["gates"]["DI-4"]["status"] != "GREEN":
    raise SystemExit("independently proven DI-4 is not GREEN")
if result["overall_status"] not in {"RED", "GREEN"}:
    raise SystemExit("architecture inventory has an invalid aggregate status")
expected_rc = 0 if result["overall_status"] == "GREEN" else 1
make_rc_ok = observed_rc == 0 if expected_rc == 0 else observed_rc != 0
if result["exit_code"] != expected_rc or not make_rc_ok:
    raise SystemExit("architecture aggregate exit code/status mismatch")
print(result["overall_status"])
PY
)

printf '[V8N-RUNNER][PASS] baselines=6/6 mutations=%d/%d DI-4=GREEN OOO-1=GREEN OOO-2=GREEN overall=%s\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" "$overall_status" |
  tee "$EVIDENCE_DIR/runner-summary.log"
fi
