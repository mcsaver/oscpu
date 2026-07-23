#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
MUTATOR="$RUN_DIR/mutate-v8o-no-static-lane.py"
BUILDER="$NPC_HOME/eval/ppa/tools/no_static_lane_semantics_evidence.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
ARCH_LOG="$NPC_HOME/eval/ppa/evidence/no-static-lane-semantics.log"
ARCH_REFRESH_MODE=${ARCH_REFRESH_MODE:-0}
SELECTOR="$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"
QUEUE="$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8o-no-static-lane.XXXXXX")

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8o-no-static-lane.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8O-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-focused.sh"
  "$MUTATOR"
  "$RUN_DIR/subagent-contracts/v8o-no-static-lane-contract-review.json"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/design/arch/rv64-architecture-ppa-contract.md"
  "$NPC_HOME/eval/ppa/tests/test_architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tests/test_directed_evidence_manifest.py"
  "$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
  "$NPC_HOME/eval/ppa/tools/directed_evidence_manifest.py"
  "$BUILDER"
  "$TB_HOME/Makefile"
  "$TB_HOME/tests/tb_ooo_int_issue_queue.sv"
  "$SELECTOR"
  "$QUEUE"
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
  local issue_sources
  local -a overrides=()

  case "$result_dir" in
    "$EVIDENCE_DIR"/*) ;;
    *) fail "unsafe result path: $result_dir" ;;
  esac
  case "$kind" in
    current) ;;
    selector)
      issue_sources="$source $QUEUE"
      overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$issue_sources")
      ;;
    queue)
      issue_sources="$SELECTOR $source"
      overrides+=("RTL_OOO_INT_ISSUE_QUEUE=$issue_sources")
      ;;
    *) fail "unknown source kind: $kind" ;;
  esac

  set +e
  make -C "$TB_HOME" \
    TESTS=tb_ooo_int_issue_queue \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$flags -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED" \
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
    flags="$flags -DOOO_ASSERT -DV8O_MODE_ASSERT"
  fi
  run_make "baseline-$profile" current '' "$flags" ||
    fail "focused baseline failed: $profile"
  log="$EVIDENCE_DIR/baseline-$profile/logs/tb_ooo_int_issue_queue.log"
  require_marker '[V8O-SPLIT-ACCEPT-NEGATIVE] accepted_slot0=1 accepted_slot1=0 coverage_credit=0' "$log"
  require_marker "[V8O-NO-STATIC-LANE-METRICS] mode=$profile permutations=12 static_lane_role_violations=0 same_cycle_pair_fires=12 exact_full_pid_matches=24 accepted=24 fired=24" "$log"
  require_marker '[V8O-NO-STATIC-LANE-SEMANTICS] accepted-package/resident/capability/full-PID/canonical-fire PASS' "$log"
  [[ "$(grep -c '^\[V8O-SLOT-WITNESS\]' "$log")" -eq 12 ]] ||
    fail "$profile did not emit exactly twelve slot witnesses"
  require_clean_pass "$log"
  printf '[V8O-BASELINE][PASS] profile=%s permutations=12/12 pid=24/24\n' "$profile" \
    >> "$EVIDENCE_DIR/baseline-summary.log"
done

mutation_rows=(
  'disable_pair_swap|selector|OooIntIssueSelect8.v|class=0 slot=slot1|[CHECK-FAIL] V8O dynamic swap polarity'
  'static_entry_capability|queue|OooIntIssueQueue.v|class=0 slot=slot0|[CHECK-FAIL] V8O per-entry selector projection'
  'slot1_capability_capture|queue|OooIntIssueQueue.v|class=0 slot=slot1|[CHECK-FAIL] V8O slot1 resident capability'
  'muldiv_as_alu|queue|OooIntIssueQueue.v|class=5 slot=slot0|[CHECK-FAIL] V8O complex resident capability'
  'serialize_second_terminal|selector|OooIntIssueSelect8.v|class=0 slot=slot0|[CHECK-FAIL] V8O canonical same-edge dual fire'
  'corrupt_full_pid|queue|OooIntIssueQueue.v|class=0 slot=slot0|[CHECK-FAIL] V8O Universal exact full ProducerId'
)

source_for_kind() {
  case "$1" in
    selector) printf '%s\n' "$SELECTOR" ;;
    queue) printf '%s\n' "$QUEUE" ;;
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
  image="$TEMP_DIR/build-mutation-$name/tb_ooo_int_issue_queue.vvp"
  [[ -s "$image" ]] || fail "mutation did not elaborate successfully: $name"
  log="$EVIDENCE_DIR/mutation-$name/logs/tb_ooo_int_issue_queue.log"
  require_marker "[V8O-ACTIVATION] $activation" "$log"
  require_marker "$failure" "$log"
  require_marker '[RESULT] FAIL' "$log"
  fatal_count=$(grep -c '^FATAL:' "$log" || true)
  expected_fatal_count=$(grep -c '^FATAL: common/tb_common.svh:35:' "$log" || true)
  [[ "$fatal_count" -eq "$expected_fatal_count" ]] ||
    fail "mutation hit an unrelated fatal marker: $name"
  source_sha=$(sha256sum "$mutant" | awk '{print $1}')
  image_sha=$(sha256sum "$image" | awk '{print $1}')
  printf '[V8O-MUTATION][PASS] name=%s source_sha256=%s image_sha256=%s compile=PASS elaboration=PASS activation=PASS semantic_rejection=PASS\n' \
    "$name" "$source_sha" "$image_sha" >> "$EVIDENCE_DIR/mutation-summary.log"
done

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "canonical proof sources changed while running mutations"

if [[ -f "$ARCH_MANIFEST" ]]; then
  cp -- "$ARCH_MANIFEST" "$EVIDENCE_DIR/static/manifest-before.json"
else
  printf '{"tests":{}}\n' > "$EVIDENCE_DIR/static/manifest-before.json"
fi

python3 "$BUILDER" \
  --repo-root "$REPO_ROOT" \
  --release-log "$EVIDENCE_DIR/baseline-release/logs/tb_ooo_int_issue_queue.log" \
  --assert-log "$EVIDENCE_DIR/baseline-assert/logs/tb_ooo_int_issue_queue.log" \
  --mutation-summary "$EVIDENCE_DIR/mutation-summary.log" \
  --sources-pre "$EVIDENCE_DIR/sources.pre.sha256" \
  --sources-post "$EVIDENCE_DIR/sources.post.sha256" \
  --gate-log "$ARCH_LOG" \
  --manifest "$ARCH_MANIFEST" \
  > "$EVIDENCE_DIR/evidence-builder.log" 2>&1

python3 - "$EVIDENCE_DIR/static/manifest-before.json" "$ARCH_MANIFEST" "$ARCH_REFRESH_MODE" <<'PY'
import json
import pathlib
import sys

before = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
after = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
refresh = sys.argv[3] == "1"
before_tests = before.get("tests", {})
after_tests = after.get("tests", {})
target = "no_static_lane_semantics"
same_design = before.get("design_id") == after.get("design_id")
expected_before = set(before_tests) if same_design else set()
if set(after_tests) != expected_before | {target}:
    raise SystemExit("directed-test inventory changed outside DI-4")
for name, record in (before_tests.items() if same_design else ()):
    if name != target and after_tests.get(name) != record:
        raise SystemExit(f"sibling evidence changed: {name}")
if not refresh and not same_design:
    raise SystemExit("DI-4 publication changed complete RTL design binding")
PY

set +e
make -C "$TB_HOME" \
  "ARCH_GATE_EVIDENCE=$ARCH_MANIFEST" \
  "ARCH_GATE_RESULT=$EVIDENCE_DIR/static/architecture-result.json" \
  arch-gates > "$EVIDENCE_DIR/static/architecture-gates.log" 2>&1
arch_rc=$?
set -e
[[ "$arch_rc" -ne 0 ]] || fail "architecture inventory unexpectedly became overall GREEN"
require_marker 'DI-4: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OVERALL: RED' "$EVIDENCE_DIR/static/architecture-gates.log"

if [[ "$ARCH_REFRESH_MODE" == 1 ]]; then
require_marker 'OOO-1: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OOO-2: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
python3 - "$EVIDENCE_DIR/static/architecture-result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if result["gates"]["DI-4"]["status"] != "GREEN":
    raise SystemExit("refresh did not establish DI-4")
if result["overall_status"] != "RED":
    raise SystemExit("architecture inventory is not RED")
PY
printf '[V8O-RUNNER][PASS] refresh=1 profiles=2/2 permutations=12/12 mutations=%d/%d DI-4=GREEN OOO-1=GREEN OOO-2=GREEN overall=RED\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" |
  tee "$EVIDENCE_DIR/runner-summary.log"
else
require_marker 'OOO-1: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
require_marker 'OOO-2: GREEN (0 red checks)' "$EVIDENCE_DIR/static/architecture-gates.log"
python3 - "$EVIDENCE_DIR/static/architecture-result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
green = {gate for gate, value in result["gates"].items()
         if value["status"] == "GREEN"}
if green != {"DI-4", "OOO-1", "OOO-2"}:
    raise SystemExit(f"unexpected GREEN set: {sorted(green)}")
if result["overall_status"] != "RED":
    raise SystemExit("architecture inventory is not RED")
PY

printf '[V8O-RUNNER][PASS] profiles=2/2 permutations=12/12 mutations=%d/%d DI-4=GREEN OOO-1=GREEN OOO-2=GREEN overall=RED\n' \
  "${#mutation_rows[@]}" "${#mutation_rows[@]}" |
  tee "$EVIDENCE_DIR/runner-summary.log"
fi
