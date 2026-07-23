#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
WRAPPER="$NPC_HOME/vsrc/memory/OooDualMemBridgeWrapper.v"
BRIDGE="$NPC_HOME/vsrc/memory/OooMemAxiBridge.v"
DCACHE="$NPC_HOME/vsrc/cache/OooDataWordCache.v"
ARBITER="$NPC_HOME/vsrc/memory/OooDualMemAxiArbiter.v"
WRAPPER_TB="$NPC_HOME/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv"
DCACHE_TB="$NPC_HOME/testbench/tests/tb_ooo_data_word_cache.sv"
BRIDGE_TB="$NPC_HOME/testbench/tests/tb_ooo_mem_axi_bridge.sv"
SPEC="$NPC_HOME/design/specs/ooo-dual-memory-datapath.md"
CHECKER="$RUN_DIR/check-v8r-dual-mem-bridge.py"
CHECKER_TEST="$RUN_DIR/test_check_v8r_dual_mem_bridge.py"
MUTATOR="$RUN_DIR/mutate-v8r-dual-mem-bridge.py"
F0_RUNNER="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/run-focused.sh"
F2_CONTRACT="$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/contract.md"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8r-dual-mem-bridge.XXXXXX")
RUN_ID="v8r-f1-$(date -u +%Y%m%dT%H%M%SZ)-$$"
IVERILOG=${IVERILOG:-iverilog}
IVERILOG_DIR=$(dirname -- "$(command -v "$IVERILOG")")
if [[ -x "$IVERILOG_DIR/vvp" ]]; then
  VVP=${VVP:-$IVERILOG_DIR/vvp}
else
  VVP=${VVP:-vvp}
fi

cleanup() {
  if [[ -d "$TEMP_DIR" && "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8r-dual-mem-bridge.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8R-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static" "$EVIDENCE_DIR/profiles" \
  "$EVIDENCE_DIR/mutations"
printf '%s\n' "$RUN_ID" > "$EVIDENCE_DIR/run-id.txt"

common_bridge_sources=(
  "$NPC_HOME/vsrc/memory/PmpChecker.v"
  "$NPC_HOME/vsrc/memory/OooTypedPmaChecker.v"
  "$NPC_HOME/vsrc/memory/OooTypedMemoryClassifier.v"
  "$NPC_HOME/vsrc/memory/OooPmaChecker.v"
  "$NPC_HOME/vsrc/memory/OooPostTranslateMemoryClass.v"
  "$NPC_HOME/vsrc/sram/Sram4096x113.v"
  "$NPC_HOME/vsrc/memory/OooSv39Tlb.v"
)
wrapper_sources=(
  "${common_bridge_sources[@]}"
  "$DCACHE" "$BRIDGE" "$ARBITER" "$WRAPPER" "$WRAPPER_TB"
)
dcache_sources=(
  "$DCACHE" "$NPC_HOME/vsrc/sram/Sram4096x113.v"
  "$NPC_HOME/vsrc/debug/OooDataWordCacheChecker.sv" "$DCACHE_TB"
)
bridge_sources=(
  "${common_bridge_sources[@]}" "$DCACHE" "$BRIDGE" "$BRIDGE_TB"
)

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/contract-review-result.json"
  "$RUN_DIR/contract-review-resolution.md"
  "$RUN_DIR/contract-rereview-result.json"
  "$RUN_DIR/subagent-contracts/v8r-dual-memory-bridge-contract-review.json"
  "$RUN_DIR/subagent-contracts/v8r-dual-memory-bridge-contract-rereview.json"
  "$RUN_DIR/run-focused.sh"
  "$CHECKER"
  "$CHECKER_TEST"
  "$MUTATOR"
  "$SPEC"
  "$WRAPPER"
  "$BRIDGE"
  "$DCACHE"
  "$ARBITER"
  "$NPC_HOME/vsrc/common/OooDataWordCacheFacts.vh"
  "$NPC_HOME/vsrc/debug/OooDataWordCacheChecker.sv"
  "$NPC_HOME/vsrc/include/define.v"
  "${common_bridge_sources[@]}"
  "$WRAPPER_TB"
  "$DCACHE_TB"
  "$BRIDGE_TB"
  "$NPC_HOME/testbench/common/tb_common.svh"
  "$NPC_HOME/vsrc/core/NpcCoreTop.v"
  "$NPC_HOME/vsrc/core/NpcTop.v"
  "$NPC_HOME/Makefile"
  "$NPC_HOME/testbench/Makefile"
  "$NPC_HOME/vsrc/filelist.mk"
  "$NPC_HOME/eval/check-contract.sh"
  "$NPC_HOME/design/arch/producer-holder-census.json"
  "$NPC_HOME/eval/ppa/tools/producer_holder_census.py"
  "$NPC_HOME/eval/ppa/tests/test_producer_holder_census.py"
  "$F0_RUNNER"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/check-v8q-dual-mem-fabric.py"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/test_check_v8q_dual_mem_fabric.py"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/mutate-v8q-dual-mem-fabric.py"
  "$F2_CONTRACT"
  "$REPO_ROOT/npc/rv64/testbench/tests/tb_ooo_dual_mem_axi_arbiter.sv"
  "$ARCH_TOOL"
  "$ARCH_MANIFEST"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.pre.sha256"

python3 "$CHECKER_TEST" -v > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1 ||
  fail "fail-closed F1 checker unit suite failed"
python3 "$CHECKER" --repo-root "$REPO_ROOT" \
  --json-out "$EVIDENCE_DIR/static/leaf-checks.json" \
  > "$EVIDENCE_DIR/static/leaf-checks.log" 2>&1 ||
  fail "F1 source/claim checker rejected the baseline"
canonical_stage=$(python3 - "$EVIDENCE_DIR/static/leaf-checks.json" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
print(payload.get("canonical_stage", "INVALID"))
PY
)
case "$canonical_stage" in
  F1_UNINTEGRATED) canonical_core_integration=false ;;
  F2_PROMOTED) canonical_core_integration=true ;;
  *) fail "F1 checker returned an invalid canonical stage: $canonical_stage" ;;
esac
python3 "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8q-dual-memory-datapath/test_check_v8q_dual_mem_fabric.py" -v \
  > "$EVIDENCE_DIR/static/f0-checker-unit.log" 2>&1 ||
  fail "F0 checker compatibility unit suite failed"

make -C "$NPC_HOME" check-rtl-style \
  > "$EVIDENCE_DIR/static/rtl-style.log" 2>&1 ||
  fail "RTL style gate failed"
make -C "$NPC_HOME" check-contract \
  > "$EVIDENCE_DIR/static/contract.log" 2>&1 ||
  fail "interface contract gate failed"

verilator_sources=(
  "${common_bridge_sources[@]}" "$DCACHE" "$BRIDGE" "$ARBITER" "$WRAPPER"
)
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
  -Wno-VARHIDDEN -I"$NPC_HOME/vsrc" -I"$NPC_HOME/vsrc/include" \
  --top-module OooDualMemBridgeWrapper "${verilator_sources[@]}" \
  > "$EVIDENCE_DIR/static/verilator-release.log" 2>&1 ||
  fail "release Verilator lint failed"
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
  -Wno-VARHIDDEN -DOOO_ASSERT -I"$NPC_HOME/vsrc" \
  -I"$NPC_HOME/vsrc/include" --top-module OooDualMemBridgeWrapper \
  "${verilator_sources[@]}" \
  > "$EVIDENCE_DIR/static/verilator-assert.log" 2>&1 ||
  fail "assert Verilator lint failed"

compile_profile() {
  local profile=$1
  local top=$2
  local define_flags=$3
  local pass_marker=$4
  shift 4
  local image="$TEMP_DIR/$profile.vvp"
  local compile_log="$EVIDENCE_DIR/profiles/$profile.compile.log"
  local run_log="$EVIDENCE_DIR/profiles/$profile.run.log"
  # define_flags 来自本脚本固定调用点，只包含受控 -D 参数。
  "$IVERILOG" -g2012 -Wall $define_flags \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -I "$NPC_HOME/testbench/common" -s "$top" -o "$image" "$@" \
    > "$compile_log" 2>&1 || fail "$profile did not compile"
  [[ -s "$image" ]] || fail "$profile did not elaborate a non-empty image"
  "$VVP" "$image" > "$run_log" 2>&1 ||
    fail "$profile directed simulation failed"
  grep -Fq "$pass_marker" "$run_log" ||
    fail "$profile missed its directed PASS marker"
  if grep -Eq '\[FAIL\]|\[TIMEOUT\]|\[NEGATIVE-FAIL\]|(^|[[:space:]])FATAL:|(^|[[:space:]])ERROR:' "$run_log"; then
    fail "$profile emitted a failure/fatal marker"
  fi
  printf '[V8R-PROFILE][PASS] run_id=%s profile=%s image_sha256=%s\n' \
    "$RUN_ID" "$profile" "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

: > "$EVIDENCE_DIR/profile-summary.log"
compile_profile wrapper-release tb_ooo_dual_mem_bridge_wrapper "" \
  "[PASS] tb_ooo_dual_mem_bridge_wrapper" "${wrapper_sources[@]}"
compile_profile wrapper-assert tb_ooo_dual_mem_bridge_wrapper "-DOOO_ASSERT" \
  "[PASS] tb_ooo_dual_mem_bridge_wrapper" "${wrapper_sources[@]}"
compile_profile dcache-release tb_ooo_data_word_cache "" \
  "[PASS] tb_ooo_data_word_cache" "${dcache_sources[@]}"
compile_profile dcache-assert tb_ooo_data_word_cache "-DOOO_ASSERT" \
  "[PASS] tb_ooo_data_word_cache" "${dcache_sources[@]}"
compile_profile bridge-release tb_ooo_mem_axi_bridge "" \
  "[PASS] tb_ooo_mem_axi_bridge" "${bridge_sources[@]}"
compile_profile bridge-assert tb_ooo_mem_axi_bridge "-DOOO_ASSERT" \
  "[PASS] tb_ooo_mem_axi_bridge" "${bridge_sources[@]}"

run_negative() {
  local profile=$1
  local top=$2
  local define_flag=$3
  local expected_marker=$4
  shift 4
  local image="$TEMP_DIR/$profile.vvp"
  local compile_log="$EVIDENCE_DIR/profiles/$profile.compile.log"
  local run_log="$EVIDENCE_DIR/profiles/$profile.run.log"
  "$IVERILOG" -g2012 -Wall -DOOO_ASSERT "$define_flag" \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -I "$NPC_HOME/testbench/common" -s "$top" -o "$image" "$@" \
    > "$compile_log" 2>&1 || fail "$profile did not compile"
  [[ -s "$image" ]] || fail "$profile did not elaborate a non-empty image"
  set +e
  "$VVP" "$image" > "$run_log" 2>&1
  local negative_rc=$?
  set -e
  [[ "$negative_rc" -ne 0 ]] || fail "$profile escaped its assertion"
  grep -Fq "[$expected_marker]" "$run_log" ||
    fail "$profile missed $expected_marker"
  [[ "$(grep -c '^FATAL:' "$run_log" || true)" -eq 1 ]] ||
    fail "$profile emitted an unexpected fatal count"
  if grep -E '\[(DWC|BRG|DMBW|ARB)-' "$run_log" | \
     grep -Fv "[$expected_marker]" > /dev/null; then
    fail "$profile activated an unrelated contract assertion"
  fi
  if grep -Fq '[NEGATIVE-FAIL]' "$run_log"; then
    fail "$profile reached the negative escape marker"
  fi
  printf '[V8R-PROFILE][PASS] run_id=%s profile=%s target=%s marker_count=%s\n' \
    "$RUN_ID" "$profile" "$expected_marker" \
    "$(grep -F -c "[$expected_marker]" "$run_log")" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

run_negative dcache-invalid-mask tb_ooo_data_word_cache \
  -DOOO_DWC_PEER_INVALID_MASK_NEGATIVE DWC-PEER-WSTRB \
  "${dcache_sources[@]}"
run_negative wrapper-mmu-nonidle tb_ooo_dual_mem_bridge_wrapper \
  -DOOO_DMBW_MMU_FLUSH_NONIDLE_NEGATIVE DMBW-MMU-FLUSH-NONIDLE \
  "${wrapper_sources[@]}"

mutation_rows=(
  'disconnect_peer_valid|1|V8R-MUT-DISCONNECT-PEER-VALID|wrapper|wrapper'
  'self_only_peer|2|V8R-MUT-SELF-ONLY-PEER|wrapper|wrapper'
  'swap_peer_addr|3|V8R-MUT-SWAP-PEER-ADDR|wrapper|wrapper'
  'request_time_maintenance|4|V8R-MUT-REQUEST-TIME-MAINTENANCE|bridge|wrapper'
  'b_ok_only_peer|5|V8R-MUT-B-OK-ONLY-PEER|bridge|wrapper'
  'drop_cross_line_peer|6|V8R-MUT-DROP-CROSS-LINE-PEER|dcache|wrapper'
  'remove_same_cycle_hit_block|7|V8R-MUT-REMOVE-SAME-CYCLE-HIT-BLOCK|dcache|wrapper'
  'fill_wins_peer|8|V8R-MUT-FILL-WINS-PEER|dcache|dcache'
  'gate_lane1_ready_on_arbiter_idle|9|V8R-MUT-GATE-LANE1-READY|wrapper|wrapper'
  'merge_dual_response|10|V8R-MUT-MERGE-DUAL-RESPONSE|wrapper|wrapper'
)

: > "$EVIDENCE_DIR/mutation-summary.log"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name case_id expected_marker target_kind tb_kind <<< "$row"
  case "$target_kind" in
    wrapper) target_base=OooDualMemBridgeWrapper.v ;;
    bridge) target_base=OooMemAxiBridge.v ;;
    dcache) target_base=OooDataWordCache.v ;;
    *) fail "unknown mutation target kind: $target_kind" ;;
  esac
  mutant="$TEMP_DIR/mutants/$name/$target_base"
  image="$TEMP_DIR/mutants/$name/test.vvp"
  mutator_log="$EVIDENCE_DIR/mutations/$name.mutator.log"
  compile_log="$EVIDENCE_DIR/mutations/$name.compile.log"
  run_log="$EVIDENCE_DIR/mutations/$name.run.log"
  python3 "$MUTATOR" "$name" "$REPO_ROOT" "$mutant" \
    > "$mutator_log" 2>&1 || fail "mutator anchor rejected baseline: $name"

  dcache_src=$DCACHE
  bridge_src=$BRIDGE
  wrapper_src=$WRAPPER
  case "$target_kind" in
    wrapper) wrapper_src=$mutant ;;
    bridge) bridge_src=$mutant ;;
    dcache) dcache_src=$mutant ;;
  esac
  if [[ "$tb_kind" == wrapper ]]; then
    mutation_sources=(
      "${common_bridge_sources[@]}" "$dcache_src" "$bridge_src"
      "$ARBITER" "$wrapper_src" "$WRAPPER_TB"
    )
    mutation_top=tb_ooo_dual_mem_bridge_wrapper
    plusarg="+MUTATION_CASE=$case_id"
  else
    mutation_sources=(
      "$dcache_src" "$NPC_HOME/vsrc/sram/Sram4096x113.v"
      "$NPC_HOME/vsrc/debug/OooDataWordCacheChecker.sv" "$DCACHE_TB"
    )
    mutation_top=tb_ooo_data_word_cache
    plusarg="+DWC_MUTATION_CASE=$case_id"
  fi
  "$IVERILOG" -g2012 -Wall \
    -I "$NPC_HOME/vsrc" -I "$NPC_HOME/vsrc/include" \
    -I "$NPC_HOME/testbench/common" -s "$mutation_top" -o "$image" \
    "${mutation_sources[@]}" > "$compile_log" 2>&1 ||
    fail "mutation did not compile: $name"
  [[ -s "$image" ]] || fail "mutation did not elaborate: $name"
  set +e
  "$VVP" "$image" "$plusarg" > "$run_log" 2>&1
  mutation_rc=$?
  set -e
  [[ "$mutation_rc" -ne 0 ]] || fail "mutation survived its target: $name"
  grep -Fq "[V8R-MUT-ACTIVE:$name]" "$run_log" ||
    fail "mutation activation marker missing: $name"
  grep -Fq "[$expected_marker]" "$run_log" ||
    fail "target rejection marker missing: $name"
  [[ "$(grep -F -c "[$expected_marker]" "$run_log" || true)" -eq 1 ]] ||
    fail "target rejection marker was not unique: $name"
  target_lines=$(grep -E '^\[V8R-MUT-' "$run_log" | \
    grep -v '^\[V8R-MUT-ACTIVE:' | wc -l)
  [[ "$target_lines" -eq 1 ]] || fail "mutation hit an unrelated V8R target: $name"
  [[ "$(grep -c '^FATAL:' "$run_log" || true)" -eq 1 ]] ||
    fail "mutation hit an unrelated fatal: $name"
  if grep -Fq '[V8R-MUT-NOT-REJECTED]' "$run_log" ||
     grep -Eq '\[(DWC|BRG|DMBW|ARB)-' "$run_log"; then
    fail "mutation escaped target isolation: $name"
  fi
  printf '[V8R-MUTATION][PASS] run_id=%s name=%s compile_success=true elaborated=true activated=true target_rejected=true source_sha256=%s image_sha256=%s\n' \
    "$RUN_ID" "$name" "$(sha256sum "$mutant" | awk '{print $1}')" \
    "$(sha256sum "$image" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/mutation-summary.log"
done
[[ "$(grep -c '^\[V8R-MUTATION\]\[PASS\]' "$EVIDENCE_DIR/mutation-summary.log")" -eq 10 ]] ||
  fail "mutation summary does not contain exactly ten detected mutants"

make -C "$NPC_HOME" check-dual-memory-fabric-foundation \
  > "$EVIDENCE_DIR/static/f0-permanent-target.log" 2>&1 ||
  fail "F0 permanent target regressed under the F1 wrapper"

# F1 leaf capability remains independently closed after an F2 topology handoff;
# the architecture checker must still fail closed because F3/F4 are absent.
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
    raise SystemExit(f"F1 architecture boundary violated: {required}")
PY

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "source closure changed during focused run"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.post.sha256"
cmp -s "$EVIDENCE_DIR/architecture-manifest.pre.sha256" \
  "$EVIDENCE_DIR/architecture-manifest.post.sha256" ||
  fail "F1 runner rewrote canonical architecture evidence"

wrapper_sha=$(sha256sum "$WRAPPER" | awk '{print $1}')
bridge_sha=$(sha256sum "$BRIDGE" | awk '{print $1}')
dcache_sha=$(sha256sum "$DCACHE" | awk '{print $1}')
closure_sha=$(sha256sum "$EVIDENCE_DIR/sources.pre.sha256" | awk '{print $1}')
python3 - "$EVIDENCE_DIR/result.json" "$RUN_ID" "$wrapper_sha" \
  "$bridge_sha" "$dcache_sha" "$closure_sha" "$canonical_stage" <<'PY'
import datetime
import json
import pathlib
import sys

(
    output, run_id, wrapper_sha, bridge_sha, dcache_sha, closure_sha,
    canonical_stage,
) = sys.argv[1:]
payload = {
    "schema": "v8r-dual-mem-bridge-evidence/v1",
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "run_id": run_id,
    "status": "PASS",
    "claim": "dual_bridge_cache_hit_leaf_verified",
    "rtl_sha256": {
        "wrapper": wrapper_sha,
        "bridge": bridge_sha,
        "dcache": dcache_sha,
    },
    "source_closure_sha256": closure_sha,
    "profiles": {
        "wrapper_release": "PASS", "wrapper_assert": "PASS",
        "dcache_release": "PASS", "dcache_assert": "PASS",
        "bridge_release": "PASS", "bridge_assert": "PASS",
        "dcache_invalid_mask": "PASS",
        "wrapper_mmu_nonidle": "PASS",
    },
    "mutations": {"required": 10, "detected": 10, "compile_success": 10},
    "f0_permanent_target": "PASS",
    "architecture": {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"},
    "ppa": "UNQUALIFIED",
    "canonical_stage": canonical_stage,
    "canonical_core_integration": canonical_stage == "F2_PROMOTED",
    "canonical_architecture_manifest_modified": False,
}
pathlib.Path(output).write_text(
    json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
PY

printf '[V8R-F1][PASS] run_id=%s claim=dual_bridge_cache_hit_leaf_verified mutations=10 architecture=RED ppa=UNQUALIFIED canonical_stage=%s canonical_core_integration=%s\n' \
  "$RUN_ID" "$canonical_stage" "$canonical_core_integration" \
  > "$EVIDENCE_DIR/final.log"
cat "$EVIDENCE_DIR/final.log"
