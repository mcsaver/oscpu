#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR=${V8M_EVIDENCE_DIR:-"$RUN_DIR/evidence/focused"}
MUTATOR="$RUN_DIR/mutate-v8m-selective-scheduling.py"
BUILDER="$NPC_HOME/eval/ppa/tools/selective_scheduling_evidence.py"
ARCH_MANIFEST=${V8M_ARCH_MANIFEST:-"$NPC_HOME/eval/ppa/evidence/architecture-current.json"}
ARCH_LOG=${V8M_ARCH_LOG:-"$NPC_HOME/eval/ppa/evidence/selective-scheduling.log"}
ARCH_REFRESH_MODE=${ARCH_REFRESH_MODE:-0}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8m-selective.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8m-selective.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8M-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

EVIDENCE_DIR=$(realpath -m -- "$EVIDENCE_DIR")
ARCH_MANIFEST=$(realpath -m -- "$ARCH_MANIFEST")
ARCH_LOG=$(realpath -m -- "$ARCH_LOG")
case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  "$REPO_ROOT"/.github/task-runs/*/evidence/focused)
    rm -rf -- "$EVIDENCE_DIR"
    ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
case "$ARCH_MANIFEST" in
  "$NPC_HOME"/eval/ppa/evidence/architecture-current.json) ;;
  "$REPO_ROOT"/.github/task-runs/*/evidence/*.json) ;;
  *) fail "unsafe architecture manifest path: $ARCH_MANIFEST" ;;
esac
case "$ARCH_LOG" in
  "$NPC_HOME"/eval/ppa/evidence/selective-scheduling.log) ;;
  "$REPO_ROOT"/.github/task-runs/*/evidence/gates/*.log) ;;
  *) fail "unsafe architecture gate log path: $ARCH_LOG" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"

BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
DISPATCH="$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
IQ="$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
SELECTOR="$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"

source_paths=(
  "$RUN_DIR/contract.md"
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
  "$TB_HOME/tests/tb_ooo_int_issue_queue.sv"
  "$BACKEND"
  "$DISPATCH"
  "$IQ"
  "$SELECTOR"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"

base_flags='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon'

run_make() {
  local label=$1
  local test=$2
  local flags=$3
  local kind=${4:-current}
  local source=${5:-}
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
    dispatch) overrides+=("RTL_OOO_DISPATCH_BACKEND=$source") ;;
    iq) overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$SELECTOR $source") ;;
    selector) overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$source $IQ") ;;
    *) fail "unknown source kind: $kind" ;;
  esac

  set +e
  make -C "$TB_HOME" \
    "TESTS=$test" \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$flags" \
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

  run_make "baseline-$profile-backend" tb_ooo_int_backend \
    "$flags -DV8M_SELECTIVE_SCHEDULING_FOCUSED" ||
    fail "backend focused baseline failed: $profile"
  backend_log="$EVIDENCE_DIR/baseline-$profile-backend/logs/tb_ooo_int_backend.log"
  require_marker '[V8M-OLDER-INDEPENDENT]' "$backend_log"
  require_marker '[V8M-SELECTIVE-METRICS] blocked_dependents_only=1 younger_independent_issued=1 different_resource_issued=1 global_freeze_cycles=0' "$backend_log"
  require_marker '[V8M-SELECTIVE-SCHEDULING] real owner/dependent/same-resource/independent identity PASS' "$backend_log"
  require_clean_pass "$backend_log"

  run_make "baseline-$profile-leaf" tb_ooo_int_issue_queue "$flags" ||
    fail "IQ leaf baseline failed: $profile"
  leaf_log="$EVIDENCE_DIR/baseline-$profile-leaf/logs/tb_ooo_int_issue_queue.log"
  require_marker '[R3P1-REGISTERED-OWNER-SOLE-ALU] PASS' "$leaf_log"
  require_clean_pass "$leaf_log"
  printf '[V8M-BASELINE][PASS] profile=%s backend=1/1 leaf=1/1\n' \
    "$profile" >> "$EVIDENCE_DIR/baseline-summary.log"
done

mutation_rows=(
  'backend_owner_binding|backend|OooIntBackend.v'
  'dispatch_owner_forwarding|dispatch|OooDispatchBackend.v'
  'selector_owner_to_alu|selector|OooIntIssueSelect8.v'
  'iq_issue1_owner_mask|iq|OooIntIssueQueue.v'
  'backend_issue1_ready_mask|backend|OooIntBackend.v'
)

source_for_kind() {
  case "$1" in
    backend) printf '%s\n' "$BACKEND" ;;
    dispatch) printf '%s\n' "$DISPATCH" ;;
    iq) printf '%s\n' "$IQ" ;;
    selector) printf '%s\n' "$SELECTOR" ;;
    *) return 1 ;;
  esac
}

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name kind basename <<< "$row"
  source=$(source_for_kind "$kind")
  mutant="$TEMP_DIR/mutants/$name/$basename"
  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    > "$EVIDENCE_DIR/mutation-$name.mutator.log" 2>&1

  if run_make "mutation-$name" tb_ooo_int_backend \
      "$base_flags -DV8M_SELECTIVE_SCHEDULING_FOCUSED" "$kind" "$mutant"; then
    fail "mutation survived focused test: $name"
  fi
  vvp="$TEMP_DIR/build-mutation-$name/tb_ooo_int_backend.vvp"
  [[ -s "$vvp" ]] || fail "mutation did not elaborate successfully: $name"
  log="$EVIDENCE_DIR/mutation-$name/logs/tb_ooo_int_backend.log"
  require_marker '[CHECK-FAIL] v8m' "$log"
  require_marker '[RESULT] FAIL' "$log"
  printf '[V8M-MUTATION][PASS] name=%s compile=PASS semantic_rejection=PASS\n' \
    "$name" >> "$EVIDENCE_DIR/mutation-summary.log"
done

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical proof sources changed while running mutations"

python3 "$BUILDER" \
  --repo-root "$REPO_ROOT" \
  --backend-release-log "$EVIDENCE_DIR/baseline-release-backend/logs/tb_ooo_int_backend.log" \
  --backend-assert-log "$EVIDENCE_DIR/baseline-assert-backend/logs/tb_ooo_int_backend.log" \
  --leaf-release-log "$EVIDENCE_DIR/baseline-release-leaf/logs/tb_ooo_int_issue_queue.log" \
  --leaf-assert-log "$EVIDENCE_DIR/baseline-assert-leaf/logs/tb_ooo_int_issue_queue.log" \
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
[[ "$arch_rc" -ne 0 ]] || fail "architecture inventory unexpectedly became overall GREEN"
require_marker 'OOO-2: GREEN (0 red checks)' \
  "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OVERALL: RED' "$EVIDENCE_DIR/static/architecture-gates.log"

if [[ "$ARCH_REFRESH_MODE" == 1 ]]; then
python3 - "$EVIDENCE_DIR/static/architecture-result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if result["gates"]["OOO-2"]["status"] != "GREEN":
    raise SystemExit("refresh did not establish OOO-2")
if result["overall_status"] != "RED":
    raise SystemExit("architecture inventory is not RED")
PY
ooo1_status=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["gates"]["OOO-1"]["status"])' \
  "$EVIDENCE_DIR/static/architecture-result.json")
printf '[V8M-RUNNER][PASS] refresh=1 baselines=4/4 mutations=%d/%d OOO-1=%s OOO-2=GREEN overall=RED\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" "$ooo1_status" |
  tee "$EVIDENCE_DIR/runner-summary.log"
else
require_marker 'DI-4: GREEN (0 red checks)' \
  "$EVIDENCE_DIR/static/architecture-gates.log"
python3 - "$EVIDENCE_DIR/static/architecture-result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if result["gates"]["OOO-2"]["status"] != "GREEN":
    raise SystemExit("OOO-2 is not GREEN")
if result["gates"]["DI-4"]["status"] != "GREEN":
    raise SystemExit("independently proven DI-4 is not GREEN")
if result["overall_status"] != "RED":
    raise SystemExit("architecture inventory is not RED")
if result["gates"]["OOO-1"]["status"] not in {"RED", "GREEN"}:
    raise SystemExit("OOO-1 has an invalid status")
if any(result["gates"][gate]["status"] != "RED"
       for gate in result["gates"]
       if gate not in {"DI-4", "OOO-1", "OOO-2"}):
    raise SystemExit("an unproven architecture gate was promoted")
PY

ooo1_status=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["gates"]["OOO-1"]["status"])' \
  "$EVIDENCE_DIR/static/architecture-result.json")
printf '[V8M-RUNNER][PASS] baselines=4/4 mutations=%d/%d DI-4=GREEN OOO-1=%s OOO-2=GREEN overall=RED\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" "$ooo1_status" |
  tee "$EVIDENCE_DIR/runner-summary.log"
fi
