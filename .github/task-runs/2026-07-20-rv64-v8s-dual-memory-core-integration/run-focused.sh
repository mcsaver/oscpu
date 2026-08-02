#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
TB="$NPC_HOME/testbench/tests/tb_ooo_int_backend.sv"
CONTROL_GATE="$NPC_HOME/vsrc/control/OooCoreSliceControlGate.v"
GLUE_TB="$NPC_HOME/testbench/tests/tb_ooo_core_top_glue.sv"
SPEC="$NPC_HOME/design/specs/ooo-dual-memory-datapath.md"
CHECKER="$RUN_DIR/check-v8s-dual-memory-core.py"
CHECKER_TEST="$RUN_DIR/test_check_v8s_dual_memory_core.py"
MUTATOR="$RUN_DIR/mutate-v8s-dual-memory-core.py"
F1_RUN_DIR="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper"
F1_RUNNER="$F1_RUN_DIR/run-focused.sh"
F1_RESULT="$F1_RUN_DIR/evidence/focused/result.json"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_MANIFEST=${V8S_ARCH_MANIFEST:-"$NPC_HOME/eval/ppa/evidence/architecture-current.json"}
EVIDENCE_DIR=${V8S_EVIDENCE_DIR:-"$RUN_DIR/evidence/focused"}
SCOPED_REFRESH_MODE=${V8S_SCOPED_REFRESH_MODE:-0}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8s-dual-memory-core.XXXXXX")
RUN_ID="v8s-f2-$(date -u +%Y%m%dT%H%M%SZ)-$$"
IVERILOG=${IVERILOG:-iverilog}
IVERILOG_DIR=$(dirname -- "$(command -v "$IVERILOG")")
if [[ -x "$IVERILOG_DIR/vvp" ]]; then
  VVP=${VVP:-$IVERILOG_DIR/vvp}
else
  VVP=${VVP:-vvp}
fi

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8s-dual-memory-core.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8S-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

EVIDENCE_DIR=$(realpath -m -- "$EVIDENCE_DIR")
ARCH_MANIFEST=$(realpath -m -- "$ARCH_MANIFEST")
case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  "$REPO_ROOT"/.github/task-runs/*/evidence/f2-current)
    rm -rf -- "$EVIDENCE_DIR"
    ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
case "$ARCH_MANIFEST" in
  "$NPC_HOME"/eval/ppa/evidence/architecture-current.json) ;;
  "$REPO_ROOT"/.github/task-runs/*/evidence/*.json) ;;
  *) fail "unsafe architecture manifest path: $ARCH_MANIFEST" ;;
esac
mkdir -p "$EVIDENCE_DIR/static" "$EVIDENCE_DIR/profiles" \
  "$EVIDENCE_DIR/mutations"
printf '%s\n' "$RUN_ID" > "$EVIDENCE_DIR/run-id.txt"

backend_sources_without_backend=(
  "$NPC_HOME/vsrc/execute/ALU.v"
  "$NPC_HOME/vsrc/execute/CompareUnit.v"
  "$NPC_HOME/vsrc/execute/OooAmoGate.v"
  "$NPC_HOME/vsrc/execute/OooBitmanipGate.v"
  "$NPC_HOME/vsrc/execute/OooClmulUnit.v"
  "$NPC_HOME/vsrc/execute/OooFpArithGate.v"
  "$NPC_HOME/vsrc/execute/OooFpBackend.v"
  "$NPC_HOME/vsrc/execute/OooFpClassifyGate.v"
  "$NPC_HOME/vsrc/execute/OooFpCompareGate.v"
  "$NPC_HOME/vsrc/execute/OooFpConvertGate.v"
  "$NPC_HOME/vsrc/execute/OooFpDivIter.v"
  "$NPC_HOME/vsrc/execute/OooFpLongOpGate.v"
  "$NPC_HOME/vsrc/execute/OooFpSgnjGate.v"
  "$NPC_HOME/vsrc/execute/OooFpSqrtIter.v"
  "$NPC_HOME/vsrc/execute/OooMulDivUnit.v"
  "$NPC_HOME/vsrc/memory/LSU.v"
  "$NPC_HOME/vsrc/memory/LSUControl.v"
  "$NPC_HOME/vsrc/memory/LSUDataPath.v"
  "$NPC_HOME/vsrc/memory/OooMemInflightQueue.v"
  "$NPC_HOME/vsrc/memory/OooMemOwnerTerminalCollector.v"
  "$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
  "$NPC_HOME/vsrc/memory/OooLoadQueue.v"
  "$NPC_HOME/vsrc/memory/OooStoreQueue.v"
  "$NPC_HOME/vsrc/pipeline/PipeStageReg.v"
  "$NPC_HOME/vsrc/regread_bypass/OooFpPhysRegFile.v"
  "$NPC_HOME/vsrc/regread_bypass/OooFpRegFile.v"
  "$NPC_HOME/vsrc/regread_bypass/OooPhysRegFile.v"
  "$NPC_HOME/vsrc/rename_allocate/OooBusyTable.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/rename_allocate/OooFreeList.v"
  "$NPC_HOME/vsrc/rename_allocate/OooRenameMap.v"
  "$NPC_HOME/vsrc/scheduling/OooFpIssueQueue.v"
  "$NPC_HOME/vsrc/scheduling/OooIntIssueQueue.v"
  "$NPC_HOME/vsrc/scheduling/OooIntIssueSelect8.v"
  "$NPC_HOME/vsrc/writeback/OooRob.v"
  "$NPC_HOME/vsrc/writeback/WBU.v"
)

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/dispatch-log.md"
  "$RUN_DIR/run-focused.sh"
  "$CHECKER"
  "$CHECKER_TEST"
  "$MUTATOR"
  "$SPEC"
  "$TB"
  "$GLUE_TB"
  "$BACKEND"
  "$CONTROL_GATE"
  "$NPC_HOME/vsrc/writeback/OooRob.v"
  "$NPC_HOME/vsrc/rename_allocate/OooDispatchBackend.v"
  "$NPC_HOME/vsrc/decode/OooAluDecodeBackend.v"
  "$NPC_HOME/vsrc/execute/OooAluCoreSlice.v"
  "$NPC_HOME/vsrc/execute/OooExecuteBackend.v"
  "$NPC_HOME/vsrc/core/OooCoreTopGlue.v"
  "$NPC_HOME/vsrc/core/NpcCoreTop.v"
  "$NPC_HOME/vsrc/sim/NpcSimTop.sv"
  "$NPC_HOME/vsrc/memory/OooDualMemBridgeWrapper.v"
  "$NPC_HOME/vsrc/memory/OooMemOwnerTracker.v"
  "$NPC_HOME/vsrc/memory/OooMemOwnerTerminalCollector.v"
  "$NPC_HOME/vsrc/memory/OooMemInflightQueue.v"
  "$NPC_HOME/vsrc/memory/OooStoreQueue.v"
  "$NPC_HOME/vsrc/include/define.v"
  "$NPC_HOME/vsrc/filelist.mk"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/testbench/Makefile"
  "$NPC_HOME/testbench/common/tb_common.svh"
  "$NPC_HOME/eval/check-contract.sh"
  "$NPC_HOME/design/arch/producer-holder-census.json"
  "$NPC_HOME/eval/ppa/tools/producer_holder_census.py"
  "$NPC_HOME/eval/ppa/tests/test_producer_holder_census.py"
  "$ARCH_TOOL"
  "$ARCH_MANIFEST"
  "$RUN_DIR/subagent-contracts/v8s-f2-architecture-contract-review.json"
  "$RUN_DIR/subagent-contracts/v8s-f2-architecture-contract-rereview.json"
  "$RUN_DIR/subagent-contracts/v8s-f2-final-architecture-contract-review.json"
  "$F1_RUN_DIR/contract.md"
  "$F1_RUNNER"
  "$F1_RESULT"
  "$F1_RUN_DIR/check-v8r-dual-mem-bridge.py"
  "$F1_RUN_DIR/test_check_v8r_dual_mem_bridge.py"
  "$F1_RUN_DIR/mutate-v8r-dual-mem-bridge.py"
  "${backend_sources_without_backend[@]}"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.pre.sha256"

python3 "$CHECKER_TEST" -v \
  > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1 ||
  fail "fail-closed F2 checker unit suite failed"
python3 "$CHECKER" --repo-root "$REPO_ROOT" \
  --json-out "$EVIDENCE_DIR/static/source-checks.json" \
  > "$EVIDENCE_DIR/static/source-checks.log" 2>&1 ||
  fail "F2 source/claim checker rejected the baseline"

make -C "$NPC_HOME" check-rtl-style \
  > "$EVIDENCE_DIR/static/rtl-style.log" 2>&1 ||
  fail "RTL style gate failed"
if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  set +e
  (cd "$REPO_ROOT" && python3 -m unittest \
    npc.rv64.eval.ppa.tests.test_producer_holder_census -v) \
    > "$EVIDENCE_DIR/static/contract.log" 2>&1
  census_rc=$?
  set -e
  printf '[V8S-SCOPED-GAP] global producer-holder census/instance graph rc=%d not selected for F2 semantic result\n' \
    "$census_rc" \
    >> "$EVIDENCE_DIR/static/contract.log"
else
  make -C "$NPC_HOME" check-contract \
    > "$EVIDENCE_DIR/static/contract.log" 2>&1 ||
    fail "interface contract/holder census gate failed"
fi

make -C "$NPC_HOME" SIM_TOP=NpcCoreTop \
  VERILATOR='verilator -Wno-fatal' RTL_VERILATOR_DEFINES='' lint \
  > "$EVIDENCE_DIR/static/npc-core-release-lint.log" 2>&1 ||
  fail "canonical NpcCoreTop release lint failed"
make -C "$NPC_HOME" SIM_TOP=NpcCoreTop \
  VERILATOR='verilator -Wno-fatal' \
  RTL_VERILATOR_DEFINES='+define+OOO_ASSERT' lint \
  > "$EVIDENCE_DIR/static/npc-core-assert-lint.log" 2>&1 ||
  fail "canonical NpcCoreTop assert lint failed"
make -C "$NPC_HOME" SIM_TOP=NpcSimTop \
  VERILATOR='verilator -Wno-fatal' \
  RTL_VERILATOR_DEFINES='+define+OOO_ASSERT +define+CONFIG_NPC_SIM_STATS +define+CONFIG_NPC_CACHE_STATS +define+CONFIG_NPC_OOO_STATS' lint \
  > "$EVIDENCE_DIR/static/npc-sim-assert-stats-lint.log" 2>&1 ||
  fail "NpcSimTop assert/stats lint failed"

compile_and_run() {
  local profile=$1
  local backend_source=$2
  local define_flags=$3
  local pass_marker=$4
  local image="$TEMP_DIR/$profile.vvp"
  local compile_log="$EVIDENCE_DIR/profiles/$profile.compile.log"
  local run_log="$EVIDENCE_DIR/profiles/$profile.run.log"
  # define_flags are fixed literals from this runner; no user input reaches it.
  "$IVERILOG" -g2012 -Wall $define_flags \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -I "$NPC_HOME/testbench" -I "$NPC_HOME/testbench/common" \
    -s tb_ooo_int_backend \
    -o "$image" "${backend_sources_without_backend[@]}" \
    "$backend_source" "$TB" > "$compile_log" 2>&1 ||
    fail "$profile did not compile"
  [[ -s "$image" ]] || fail "$profile did not elaborate a non-empty image"
  "$VVP" "$image" > "$run_log" 2>&1 ||
    fail "$profile directed simulation failed"
  grep -Fq "$pass_marker" "$run_log" ||
    fail "$profile missed its directed PASS marker"
  if grep -Eq '\[CHECK-FAIL\]|\[FAIL\]|\[TIMEOUT\]|(^|[[:space:]])FATAL:|(^|[[:space:]])ERROR:' "$run_log"; then
    fail "$profile emitted a failure/fatal marker"
  fi
  printf '[V8S-PROFILE][PASS] run_id=%s profile=%s image_sha256=%s\n' \
    "$RUN_ID" "$profile" "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

: > "$EVIDENCE_DIR/profile-summary.log"
compile_and_run focused-release "$BACKEND" \
  '-DV8S_DUAL_MEMORY_FOCUSED' '[V8S-DUAL-MEMORY-CORE]'
compile_and_run focused-assert "$BACKEND" \
  '-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' '[V8S-DUAL-MEMORY-CORE]'
compile_and_run legacy-assert "$BACKEND" \
  '-DOOO_ASSERT' '[V8P-PAIR-MATRIX]'

mutation_rows=(
  'bank1_tieoff|V8S bank1 valid independent of ready'
  'swap_bank_mapping|V8S bank0 captured address'
  'invert_same_bank_age|V8S same-bank older selected'
  'alias_miq1_completion_head|V8S bank1 PID reaches MIQ'
  'double_claim_wb0|V8S bank1 owns WB1'
  'tieoff_sq_terminal1|V8S dual-store fault terminal1'
  'duplicate_bridge_drop_token|S2-G1-TCOLL-INGRESS-DUP'
  'allow_killed_mem1_wb|V8S selective-kill bank1 no WB'
  'ordinary_store_direct_write|V8S dual-store bank1 is probe'
  'singleton_priority_bypass|V8S singleton blocks ordinary grant1'
  'legacy_release_lookthrough|V8S singleton release edge blocks bank1'
  'omit_checkpoint_lq_recovery|V8V checkpoint exact terminals drain LQ'
  'omit_checkpoint_dispatch_recovery|V8V checkpoint clears unlaunched ROB'
  'omit_checkpoint_sq_recovery|V8V checkpoint clears unlaunched SQ owner'
  'bypass_lq_retire_permit|V8V LQ retire authority blocks ROB commit'
  'bypass_checkpoint_irrevocable_guard|V8V delayed-B raw request does not apply'
  'bypass_checkpoint_commit1_block|V8V delayed-B blocks commit1'
  'raw_checkpoint_local_flush_bypass|raw checkpoint restore does not assert core local flush'
)

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name expected_marker <<< "$row"
  if [[ "$name" == raw_checkpoint_local_flush_bypass ]]; then
    mutation_source="$CONTROL_GATE"
    mutant="$TEMP_DIR/mutants/$name/OooCoreSliceControlGate.v"
    image="$TEMP_DIR/mutants/$name/build/tb_ooo_core_top_glue.vvp"
    run_log="$TEMP_DIR/mutants/$name/result/logs/tb_ooo_core_top_glue.log"
  else
    mutation_source="$BACKEND"
    mutant="$TEMP_DIR/mutants/$name/OooIntBackend.v"
    image="$TEMP_DIR/mutants/$name/test.vvp"
    run_log="$EVIDENCE_DIR/mutations/$name.run.log"
  fi
  mutator_log="$EVIDENCE_DIR/mutations/$name.mutator.log"
  compile_log="$EVIDENCE_DIR/mutations/$name.compile.log"
  python3 "$MUTATOR" "$name" "$mutation_source" "$mutant" \
    > "$mutator_log" 2>&1 || fail "$name mutator failed"
  if [[ "$name" == raw_checkpoint_local_flush_bypass ]]; then
    set +e
    make -B -C "$NPC_HOME/testbench" \
      BUILD_DIR="$TEMP_DIR/mutants/$name/build" \
      RESULT_DIR="$TEMP_DIR/mutants/$name/result" \
      RTL_OOO_CORE_SLICE_CONTROL_GATE="$mutant" \
      IVFLAGS='-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT' \
      "$run_log" > "$compile_log" 2>&1
    mutation_rc=$?
    set -e
    [[ -f "$run_log" ]] || fail "$name did not produce an integration log"
    cp -- "$run_log" "$EVIDENCE_DIR/mutations/$name.run.log"
    run_log="$EVIDENCE_DIR/mutations/$name.run.log"
  else
    "$IVERILOG" -g2012 -Wall -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED \
      -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
      -I "$NPC_HOME/testbench" -I "$NPC_HOME/testbench/common" \
      -s tb_ooo_int_backend \
      -o "$image" "${backend_sources_without_backend[@]}" \
      "$mutant" "$TB" > "$compile_log" 2>&1 ||
      fail "$name did not compile"
    set +e
    "$VVP" "$image" > "$run_log" 2>&1
    mutation_rc=$?
    set -e
  fi
  [[ -s "$image" ]] || fail "$name did not elaborate a non-empty image"
  [[ "$mutation_rc" -ne 0 ]] || fail "$name escaped its semantic oracle"
  grep -Fq "$expected_marker" "$run_log" ||
    fail "$name missed target oracle: $expected_marker"
  grep -Fq '[V8S-MUTATOR][PASS]' "$mutator_log" ||
    fail "$name missed mutator activation proof"
  printf '[V8S-MUTATION][PASS] run_id=%s name=%s compile_success=true elaborated=true activated=true target_rejected=true oracle=%s mutant_sha256=%s image_sha256=%s\n' \
    "$RUN_ID" "$name" "$expected_marker" \
    "$(sha256sum "$mutant" | awk '{print $1}')" \
    "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/mutation-summary.log"
done
[[ "$(grep -c '^\[V8S-MUTATION\]\[PASS\]' "$EVIDENCE_DIR/mutation-summary.log")" -eq 18 ]] ||
  fail "mutation summary does not contain exactly eighteen detected mutants"

if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  printf '[V8S-F1-REPLAY] scoped refresh consumes frozen F1 result; no F1 runner invoked\n' \
    > "$EVIDENCE_DIR/static/f1-permanent-target.log"
else
  make -C "$NPC_HOME" check-dual-memory-bridge-wrapper \
    > "$EVIDENCE_DIR/static/f1-permanent-target.log" 2>&1 ||
    fail "stage-aware F1 predecessor target regressed under canonical F2"
fi
python3 - "$F1_RESULT" "$EVIDENCE_DIR/static/f1-handoff.json" <<'PY'
import json
import pathlib
import sys

source = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
payload = json.loads(source.read_text(encoding="utf-8"))
required = {
    "status": payload.get("status"),
    "claim": payload.get("claim"),
    "canonical_stage": payload.get("canonical_stage"),
    "canonical_core_integration": payload.get("canonical_core_integration"),
    "architecture": payload.get("architecture"),
    "ppa": payload.get("ppa"),
}
expected = {
    "status": "PASS",
    "claim": "dual_bridge_cache_hit_leaf_verified",
    "canonical_stage": "F2_PROMOTED",
    "canonical_core_integration": True,
    "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
    "ppa": "UNQUALIFIED",
}
if required != expected:
    raise SystemExit(f"invalid F1-to-F2 handoff evidence: {required}")
snapshot = {
    **required,
    "run_id": payload.get("run_id"),
    "source_closure_sha256": payload.get("source_closure_sha256"),
}
if not snapshot["run_id"] or not snapshot["source_closure_sha256"]:
    raise SystemExit(f"incomplete F1 handoff identity: {snapshot}")
output.write_text(
    json.dumps(snapshot, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

# The canonical architecture manifest deliberately predates F2.  The aggregate
# must remain fail-closed until F3/F4 and a fresh design-id closure exist.
set +e
python3 "$ARCH_TOOL" --repo-root "$REPO_ROOT" \
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
    raise SystemExit(f"F2 architecture boundary violated: {required}")
PY

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "source closure changed during focused run"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.post.sha256"
cmp -s "$EVIDENCE_DIR/architecture-manifest.pre.sha256" \
  "$EVIDENCE_DIR/architecture-manifest.post.sha256" ||
  fail "F2 runner rewrote canonical architecture evidence"

backend_sha=$(sha256sum "$BACKEND" | awk '{print $1}')
core_sha=$(sha256sum "$NPC_HOME/vsrc/core/NpcCoreTop.v" | awk '{print $1}')
tb_sha=$(sha256sum "$TB" | awk '{print $1}')
control_gate_sha=$(sha256sum "$CONTROL_GATE" | awk '{print $1}')
glue_tb_sha=$(sha256sum "$GLUE_TB" | awk '{print $1}')
closure_sha=$(sha256sum "$EVIDENCE_DIR/sources.pre.sha256" | awk '{print $1}')
python3 - "$EVIDENCE_DIR/result.json" "$RUN_ID" "$backend_sha" \
  "$core_sha" "$tb_sha" "$control_gate_sha" "$glue_tb_sha" \
  "$closure_sha" "$SCOPED_REFRESH_MODE" \
  "$EVIDENCE_DIR/static/f1-handoff.json" \
  "$EVIDENCE_DIR/static/source-checks.json" <<'PY'
import datetime
import json
import pathlib
import sys

(
    output, run_id, backend_sha, core_sha, tb_sha, control_gate_sha,
    glue_tb_sha, closure_sha, scoped_refresh_mode, f1_path, source_checks_path,
) = sys.argv[1:]
f1_handoff = json.loads(pathlib.Path(f1_path).read_text(encoding="utf-8"))
source_checks = json.loads(
    pathlib.Path(source_checks_path).read_text(encoding="utf-8")
)
extension_stage = source_checks.get("detected_extension_stage")
if extension_stage not in {"F2_BASE", "F3_EXTENDED"}:
    raise SystemExit(f"invalid F2/F3 terminal topology: {extension_stage}")
payload = {
    "schema": "v8s-dual-memory-core-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "run_id": run_id,
    "status": "PASS",
    "claim": "architecture_checkpoint",
    "rtl_sha256": {
        "backend": backend_sha,
        "canonical_core": core_sha,
        "core_slice_control_gate": control_gate_sha,
    },
    "tb_sha256": tb_sha,
    "core_glue_tb_sha256": glue_tb_sha,
    "source_closure_sha256": closure_sha,
    "profiles": {
        "focused_release": "PASS",
        "focused_assert": "PASS",
        "legacy_assert": "PASS",
        "npc_core_release_lint": "PASS",
        "npc_core_assert_lint": "PASS",
        "npc_sim_assert_stats_lint": "PASS",
    },
    "mutations": {
        "required": 18,
        "detected": 18,
        "compile_success": 18,
        "elaborated": 18,
        "activated": 18,
    },
    "f1_permanent_target": {
        "status": "PASS",
        "evidence_mode": (
            "FROZEN_REPLAY" if scoped_refresh_mode == "1" else "FRESH_RUN"
        ),
        "run_id": f1_handoff["run_id"],
        "claim": f1_handoff["claim"],
        "canonical_stage": f1_handoff["canonical_stage"],
        "source_closure_sha256": f1_handoff["source_closure_sha256"],
    },
    "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
    "ppa": "UNQUALIFIED",
    "promotion_eligible": False,
    "f3_final_pa_sq_query": (
        "ABSENT" if extension_stage == "F2_BASE" else "PRESENT_UNQUALIFIED"
    ),
    "detected_extension_stage": extension_stage,
    "f4_system_ipc_gate": "ABSENT",
    "canonical_architecture_manifest_modified": False,
}
pathlib.Path(output).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

if [[ "$SCOPED_REFRESH_MODE" == 1 ]]; then
  predecessor_status=F1_FROZEN_REPLAY
else
  predecessor_status=F1_FRESH_PASS
fi
printf '[V8S-F2][PASS] run_id=%s claim=architecture_checkpoint profiles=6 mutations=18 predecessor=%s architecture=RED ppa=UNQUALIFIED promotion_eligible=false\n' \
  "$RUN_ID" "$predecessor_status" > "$EVIDENCE_DIR/final.log"
cat "$EVIDENCE_DIR/final.log"
