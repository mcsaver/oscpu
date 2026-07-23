#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
RTL="$NPC_HOME/vsrc/memory/OooDualMemAxiArbiter.v"
TB="$NPC_HOME/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv"
SPEC="$NPC_HOME/design/specs/ooo-dual-memory-datapath.md"
CHECKER="$RUN_DIR/check-v8q-dual-mem-fabric.py"
CHECKER_TEST="$RUN_DIR/test_check_v8q_dual_mem_fabric.py"
MUTATOR="$RUN_DIR/mutate-v8q-dual-mem-fabric.py"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8q-dual-mem-fabric.XXXXXX")
RUN_ID="v8q-f0-$(date -u +%Y%m%dT%H%M%SZ)-$$"

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8q-dual-mem-fabric.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8Q-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static" "$EVIDENCE_DIR/profiles" \
  "$EVIDENCE_DIR/mutations"
printf '%s\n' "$RUN_ID" > "$EVIDENCE_DIR/run-id.txt"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/contract-review-result.json"
  "$RUN_DIR/contract-review-resolution.md"
  "$RUN_DIR/run-focused.sh"
  "$CHECKER"
  "$CHECKER_TEST"
  "$MUTATOR"
  "$SPEC"
  "$RTL"
  "$TB"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/vsrc/filelist.mk"
  "$ARCH_TOOL"
  "$ARCH_MANIFEST"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.pre.sha256"

python3 "$CHECKER_TEST" -v > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1 ||
  fail "fail-closed checker unit suite failed"
python3 "$CHECKER" \
  --rtl "$RTL" \
  --vsrc "$NPC_HOME/vsrc" \
  --spec "$SPEC" \
  --json-out "$EVIDENCE_DIR/static/leaf-checks.json" \
  > "$EVIDENCE_DIR/static/leaf-checks.log" 2>&1 ||
  fail "leaf source/claim checker rejected the baseline"

make -C "$NPC_HOME" check-rtl-style \
  > "$EVIDENCE_DIR/static/rtl-style.log" 2>&1 ||
  fail "RTL style gate failed"
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
  -I"$NPC_HOME/vsrc" -I"$NPC_HOME/vsrc/include" \
  --top-module OooDualMemAxiArbiter "$RTL" \
  > "$EVIDENCE_DIR/static/verilator-release.log" 2>&1 ||
  fail "release Verilator lint failed"
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
  -DOOO_ASSERT -I"$NPC_HOME/vsrc" -I"$NPC_HOME/vsrc/include" \
  --top-module OooDualMemAxiArbiter "$RTL" \
  > "$EVIDENCE_DIR/static/verilator-assert.log" 2>&1 ||
  fail "assert Verilator lint failed"

compile_profile() {
  local profile=$1
  local define_flag=$2
  local image="$TEMP_DIR/$profile.vvp"
  local compile_log="$EVIDENCE_DIR/profiles/$profile.compile.log"
  local run_log="$EVIDENCE_DIR/profiles/$profile.run.log"
  iverilog -g2012 -Wall $define_flag \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -s tb_ooo_dual_mem_axi_arbiter -o "$image" "$RTL" "$TB" \
    > "$compile_log" 2>&1 || fail "$profile did not compile"
  [[ -s "$image" ]] || fail "$profile did not elaborate a non-empty image"
  vvp "$image" > "$run_log" 2>&1 || fail "$profile directed simulation failed"
  grep -Fq '[V8Q-F0-TB][PASS]' "$run_log" ||
    fail "$profile missed the directed PASS marker"
  if grep -Eq '\[V8Q-.*FAIL|(^|[[:space:]])FATAL:|(^|[[:space:]])ERROR:' "$run_log"; then
    fail "$profile emitted a failure/fatal marker"
  fi
  printf '[V8Q-PROFILE][PASS] run_id=%s profile=%s image_sha256=%s\n' \
    "$RUN_ID" "$profile" "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

: > "$EVIDENCE_DIR/profile-summary.log"
compile_profile release ""
compile_profile assert "-DOOO_ASSERT"

negative_image="$TEMP_DIR/assert-negative.vvp"
iverilog -g2012 -Wall -DOOO_ASSERT -DNEGATIVE_CLASS \
  -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
  -s tb_ooo_dual_mem_axi_arbiter -o "$negative_image" "$RTL" "$TB" \
  > "$EVIDENCE_DIR/profiles/assert-negative.compile.log" 2>&1 ||
  fail "assert-negative profile did not compile"
[[ -s "$negative_image" ]] || fail "assert-negative image is empty"
set +e
vvp "$negative_image" > "$EVIDENCE_DIR/profiles/assert-negative.run.log" 2>&1
negative_rc=$?
set -e
[[ "$negative_rc" -ne 0 ]] || fail "illegal dual-type request escaped assertion"
grep -Fq '[ARB-REQ-CLASS-ONEHOT]' \
  "$EVIDENCE_DIR/profiles/assert-negative.run.log" ||
  fail "assert-negative missed ARB-REQ-CLASS-ONEHOT"
[[ "$(grep -c '^FATAL:' "$EVIDENCE_DIR/profiles/assert-negative.run.log" || true)" -eq 1 ]] ||
  fail "assert-negative emitted an unexpected fatal count"
printf '[V8Q-PROFILE][PASS] run_id=%s profile=assert-negative target=ARB-REQ-CLASS-ONEHOT\n' \
  "$RUN_ID" >> "$EVIDENCE_DIR/profile-summary.log"

mutation_rows=(
  'read_release_on_ar|1|V8Q-MUT-READ-RELEASE-ON-AR'
  'write_release_on_aw|2|V8Q-MUT-WRITE-RELEASE-ON-AW'
  'write_release_on_w|3|V8Q-MUT-WRITE-RELEASE-ON-W'
  'aw_seen_tieoff|4|V8Q-MUT-AW-SEEN-TIEOFF'
  'w_seen_tieoff|5|V8Q-MUT-W-SEEN-TIEOFF'
  'broadcast_rvalid|6|V8Q-MUT-BROADCAST-RVALID'
  'swap_rready|7|V8Q-MUT-SWAP-RREADY'
  'broadcast_bvalid|8|V8Q-MUT-BROADCAST-BVALID'
  'fixed_lane0_priority|9|V8Q-MUT-FIXED-LANE0-PRIORITY'
  'rr_update_on_capture|10|V8Q-MUT-RR-UPDATE-ON-CAPTURE'
  'idle_fallthrough|11|V8Q-MUT-IDLE-FALLTHROUGH'
  'reset_owner_residue|12|V8Q-MUT-RESET-OWNER-RESIDUE'
)

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name case_id expected_marker <<< "$row"
  mutant="$TEMP_DIR/mutants/$name/OooDualMemAxiArbiter.v"
  image="$TEMP_DIR/mutants/$name/test.vvp"
  mutator_log="$EVIDENCE_DIR/mutations/$name.mutator.log"
  compile_log="$EVIDENCE_DIR/mutations/$name.compile.log"
  run_log="$EVIDENCE_DIR/mutations/$name.run.log"
  python3 "$MUTATOR" "$name" "$RTL" "$mutant" > "$mutator_log" 2>&1 ||
    fail "mutator anchor rejected baseline: $name"
  iverilog -g2012 -Wall \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -s tb_ooo_dual_mem_axi_arbiter -o "$image" "$mutant" "$TB" \
    > "$compile_log" 2>&1 || fail "mutation did not compile: $name"
  [[ -s "$image" ]] || fail "mutation did not elaborate: $name"
  set +e
  vvp "$image" "+MUTATION_CASE=$case_id" > "$run_log" 2>&1
  mutation_rc=$?
  set -e
  [[ "$mutation_rc" -ne 0 ]] || fail "mutation survived its target: $name"
  grep -Fq "[V8Q-MUT-ACTIVE:$name]" "$run_log" ||
    fail "mutation activation marker missing: $name"
  grep -Fq "[$expected_marker]" "$run_log" ||
    fail "target rejection marker missing: $name"
  [[ "$(grep -F -c "[$expected_marker]" "$run_log" || true)" -eq 1 ]] ||
    fail "target rejection marker was not unique: $name"
  target_lines=$(grep -E '^\[V8Q-MUT-' "$run_log" | grep -v '^\[V8Q-MUT-ACTIVE:' | wc -l)
  [[ "$target_lines" -eq 1 ]] || fail "mutation hit an unrelated V8Q target: $name"
  [[ "$(grep -c '^FATAL:' "$run_log" || true)" -eq 1 ]] ||
    fail "mutation hit an unrelated fatal: $name"
  if grep -Fq '[V8Q-MUT-NOT-REJECTED]' "$run_log" || grep -Fq '[ARB-' "$run_log"; then
    fail "mutation escaped target isolation: $name"
  fi
  printf '[V8Q-MUTATION][PASS] run_id=%s name=%s compile_success=true elaborated=true activated=true target_rejected=true source_sha256=%s image_sha256=%s\n' \
    "$RUN_ID" "$name" \
    "$(sha256sum "$mutant" | awk '{print $1}')" \
    "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/mutation-summary.log"
done
[[ "$(grep -c '^\[V8Q-MUTATION\]\[PASS\]' "$EVIDENCE_DIR/mutation-summary.log")" -eq 12 ]] ||
  fail "mutation summary does not contain exactly twelve detected mutants"

# The architecture checker is expected to remain RED.  Its output is local to
# this task-run; architecture-current.json must not be rewritten by an F0 leaf.
set +e
python3 "$ARCH_TOOL" \
  --repo-root "$REPO_ROOT" \
  --evidence-manifest "$ARCH_MANIFEST" \
  --output "$EVIDENCE_DIR/static/architecture-hard-gates.json" \
  > "$EVIDENCE_DIR/static/architecture-hard-gates.log" 2>&1
architecture_rc=$?
set -e
[[ "$architecture_rc" -eq 1 ]] ||
  fail "architecture hard gate was not the expected fail-closed RED result"
python3 - "$EVIDENCE_DIR/static/architecture-hard-gates.json" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
required = {
    "DI-5": payload["gates"]["DI-5"]["status"],
    "OOO-3": payload["gates"]["OOO-3"]["status"],
    "overall": payload["overall_status"],
}
if required != {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"}:
    raise SystemExit(f"F0 architecture boundary violated: {required}")
PY

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "source closure changed during focused run"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.post.sha256"
cmp -s "$EVIDENCE_DIR/architecture-manifest.pre.sha256" \
  "$EVIDENCE_DIR/architecture-manifest.post.sha256" ||
  fail "F0 runner rewrote canonical architecture evidence"

rtl_sha=$(sha256sum "$RTL" | awk '{print $1}')
closure_sha=$(sha256sum "$EVIDENCE_DIR/sources.pre.sha256" | awk '{print $1}')
python3 - "$EVIDENCE_DIR/result.json" "$RUN_ID" "$rtl_sha" "$closure_sha" <<'PY'
import datetime
import json
import pathlib
import sys

output, run_id, rtl_sha, closure_sha = sys.argv[1:]
payload = {
    "schema": "v8q-dual-mem-fabric-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "run_id": run_id,
    "status": "PASS",
    "claim": "dual_axi_miss_fabric_leaf_verified",
    "rtl_sha256": rtl_sha,
    "source_closure_sha256": closure_sha,
    "profiles": {"release": "PASS", "assert": "PASS", "assert_negative": "PASS"},
    "mutations": {"required": 12, "detected": 12, "compile_success": 12},
    "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
    "ppa": "UNQUALIFIED",
    "canonical_architecture_manifest_modified": False,
}
pathlib.Path(output).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

printf '[V8Q-F0][PASS] run_id=%s claim=dual_axi_miss_fabric_leaf_verified mutations=12 architecture=RED ppa=UNQUALIFIED\n' \
  "$RUN_ID" > "$EVIDENCE_DIR/final.log"
cat "$EVIDENCE_DIR/final.log"
