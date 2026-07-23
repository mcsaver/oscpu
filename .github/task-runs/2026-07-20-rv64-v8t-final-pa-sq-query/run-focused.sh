#!/usr/bin/env bash
set -euo pipefail

RUN_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(git -C "$RUN_DIR" rev-parse --show-toplevel)
NPC_HOME="$REPO_ROOT/npc/rv64"
TB_HOME="$NPC_HOME/testbench"
SQ="$NPC_HOME/vsrc/memory/OooStoreQueue.v"
BRIDGE="$NPC_HOME/vsrc/memory/OooMemAxiBridge.v"
BACKEND="$NPC_HOME/vsrc/execute/OooIntBackend.v"
SPEC="$NPC_HOME/design/specs/ooo-dual-memory-datapath.md"
CHECKER="$RUN_DIR/check-v8t-final-pa-sq-query.py"
CHECKER_TEST="$RUN_DIR/test_check_v8t_final_pa_sq_query.py"
MUTATOR="$RUN_DIR/mutate-v8t-final-pa-sq-query.py"
MUTATOR_TEST="$RUN_DIR/test_mutate_v8t_final_pa_sq_query.py"
RETRY_PROOF="$RUN_DIR/prove-v8t-retry-holder-conservation.py"
RETRY_PROOF_TEST="$RUN_DIR/test_prove_v8t_retry_holder_conservation.py"
FINALIZER="$RUN_DIR/finalize-v8t-final-pa-sq-query.py"
FINALIZER_TEST="$RUN_DIR/test_finalize_v8t_final_pa_sq_query.py"
ARCH_TOOL="$NPC_HOME/eval/ppa/tools/architecture_hard_gates.py"
ARCH_MANIFEST="$NPC_HOME/eval/ppa/evidence/architecture-current.json"
EVIDENCE_DIR="$RUN_DIR/evidence/focused"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v8t-final-pa-sq-query.XXXXXX")
RUN_ID="v8t-f3-$(date -u +%Y%m%dT%H%M%SZ)-$$"

cleanup() {
  if [[ -d "$TEMP_DIR" &&
        "$TEMP_DIR" == "${TMPDIR:-/tmp}"/v8t-final-pa-sq-query.* ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf '[V8T-RUNNER][FAIL] %s\n' "$*" >&2
  exit 1
}

case "$EVIDENCE_DIR" in
  "$RUN_DIR"/evidence/focused) rm -rf -- "$EVIDENCE_DIR" ;;
  *) fail "unsafe evidence path: $EVIDENCE_DIR" ;;
esac
mkdir -p "$EVIDENCE_DIR/static" "$EVIDENCE_DIR/profiles" \
  "$EVIDENCE_DIR/mutations" "$EVIDENCE_DIR/predecessors"
printf '%s\n' "$RUN_ID" > "$EVIDENCE_DIR/run-id.txt"
: > "$EVIDENCE_DIR/commands.log"

source_paths=(
  "$RUN_DIR/contract.md"
  "$RUN_DIR/rtl-derivation.md"
  "$RUN_DIR/run-focused.sh"
  "$CHECKER"
  "$CHECKER_TEST"
  "$MUTATOR"
  "$MUTATOR_TEST"
  "$RETRY_PROOF"
  "$RETRY_PROOF_TEST"
  "$FINALIZER"
  "$FINALIZER_TEST"
  "$SPEC"
  "$SQ"
  "$BRIDGE"
  "$BACKEND"
  "$NPC_HOME/vsrc/memory/OooDualMemBridgeWrapper.v"
  "$NPC_HOME/vsrc/decode/OooAluDecodeBackend.v"
  "$NPC_HOME/vsrc/execute/OooAluCoreSlice.v"
  "$NPC_HOME/vsrc/execute/OooExecuteBackend.v"
  "$NPC_HOME/vsrc/core/OooCoreTopGlue.v"
  "$NPC_HOME/vsrc/core/NpcCoreTop.v"
  "$TB_HOME/tests/tb_ooo_store_queue.sv"
  "$TB_HOME/tests/tb_ooo_mem_axi_bridge.sv"
  "$TB_HOME/tests/tb_ooo_dual_mem_bridge_wrapper.sv"
  "$TB_HOME/tests/tb_ooo_int_backend.sv"
  "$TB_HOME/tests/tb_ooo_core_top_glue.sv"
  "$TB_HOME/tests/tb_ooo_priv_system.sv"
  "$TB_HOME/tests/tb_ooo_sv39_boot.sv"
  "$NPC_HOME/vsrc/filelist.mk"
  "$NPC_HOME/Makefile"
  "$TB_HOME/Makefile"
  "$NPC_HOME/eval/check-contract.sh"
  "$NPC_HOME/design/arch/producer-holder-census.json"
  "$NPC_HOME/eval/ppa/tools/producer_holder_census.py"
  "$NPC_HOME/eval/ppa/tests/test_producer_holder_census.py"
  "$ARCH_TOOL"
  "$ARCH_MANIFEST"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/check-v8s-dual-memory-core.py"
  "$REPO_ROOT/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/test_check_v8s_dual_memory_core.py"
)
sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.pre.sha256"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.pre.sha256"

printf '%s\n' 'python3 checker unit tests' >> "$EVIDENCE_DIR/commands.log"
python3 "$CHECKER_TEST" -v \
  > "$EVIDENCE_DIR/static/checker-unit.log" 2>&1 ||
  fail "fail-closed F3 checker unit suite failed"
printf '%s\n' 'python3 mutator anchor unit tests' >> "$EVIDENCE_DIR/commands.log"
python3 "$MUTATOR_TEST" -v \
  > "$EVIDENCE_DIR/static/mutator-unit.log" 2>&1 ||
  fail "F3 mutator anchor suite failed"
printf '%s\n' 'python3 retry-holder proof binding unit tests' >> "$EVIDENCE_DIR/commands.log"
python3 "$RETRY_PROOF_TEST" -v \
  > "$EVIDENCE_DIR/static/retry-holder-proof-unit.log" 2>&1 ||
  fail "F3 retry-holder proof binding suite failed"
printf '%s\n' 'python3 checkpoint finalizer unit tests' >> "$EVIDENCE_DIR/commands.log"
python3 "$FINALIZER_TEST" -v \
  > "$EVIDENCE_DIR/static/checkpoint-finalizer-unit.log" 2>&1 ||
  fail "F3 checkpoint finalizer suite failed"
printf '%s\n' 'python3 retry-holder exhaustive proof' >> "$EVIDENCE_DIR/commands.log"
python3 "$RETRY_PROOF" --source "$BACKEND" \
  --json-out "$EVIDENCE_DIR/static/retry-holder-proof.json" \
  > "$EVIDENCE_DIR/static/retry-holder-proof.log" 2>&1 ||
  fail "F3 retry-holder exhaustive control proof failed"
printf '%s\n' 'python3 baseline source checker' >> "$EVIDENCE_DIR/commands.log"
python3 "$CHECKER" --repo-root "$REPO_ROOT" \
  --json-out "$EVIDENCE_DIR/static/source-checks.json" \
  > "$EVIDENCE_DIR/static/source-checks.log" 2>&1 ||
  fail "F3 source/claim checker rejected the baseline"

printf '%s\n' 'make check-rtl-style' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" check-rtl-style \
  > "$EVIDENCE_DIR/static/rtl-style.log" 2>&1 ||
  fail "RTL style gate failed"
printf '%s\n' 'make check-contract' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" check-contract \
  > "$EVIDENCE_DIR/static/contract.log" 2>&1 ||
  fail "interface contract/holder census gate failed"

printf '%s\n' 'NpcCoreTop release lint' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" SIM_TOP=NpcCoreTop \
  VERILATOR='verilator -Wno-fatal' RTL_VERILATOR_DEFINES='' lint \
  > "$EVIDENCE_DIR/static/npc-core-release-lint.log" 2>&1 ||
  fail "canonical NpcCoreTop release lint failed"
printf '%s\n' 'NpcCoreTop OOO_ASSERT lint' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" SIM_TOP=NpcCoreTop \
  VERILATOR='verilator -Wno-fatal' \
  RTL_VERILATOR_DEFINES='+define+OOO_ASSERT' lint \
  > "$EVIDENCE_DIR/static/npc-core-assert-lint.log" 2>&1 ||
  fail "canonical NpcCoreTop assert lint failed"

run_baseline_tb() {
  local profile=$1
  local test=$2
  local defines=$3
  local marker=$4
  local result_dir="$EVIDENCE_DIR/profiles/$profile"
  local build_dir="$TEMP_DIR/builds/$profile"
  local target="$result_dir/logs/$test.log"
  local ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon $defines"
  printf 'baseline profile=%s test=%s defines=%s\n' \
    "$profile" "$test" "$defines" >> "$EVIDENCE_DIR/commands.log"
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" \
    RESULT_DIR="$result_dir" IVFLAGS="$ivflags" "$target" \
    > "$result_dir.make.log" 2>&1 || fail "$profile directed simulation failed"
  [[ -s "$build_dir/$test.vvp" ]] ||
    fail "$profile did not elaborate a non-empty image"
  grep -Fq '[RESULT] PASS' "$target" || fail "$profile missed PASS"
  grep -Fq "$marker" "$target" || fail "$profile missed marker: $marker"
  printf '[V8T-PROFILE][PASS] run_id=%s profile=%s image_sha256=%s\n' \
    "$RUN_ID" "$profile" \
    "$(sha256sum "$build_dir/$test.vvp" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

run_expected_assertion_tb() {
  local profile=$1
  local test=$2
  local defines=$3
  local marker=$4
  local result_dir="$EVIDENCE_DIR/profiles/$profile"
  local build_dir="$TEMP_DIR/builds/$profile"
  local target="$result_dir/logs/$test.log"
  local ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon $defines"
  printf 'negative-nonvacuity profile=%s test=%s defines=%s\n' \
    "$profile" "$test" "$defines" >> "$EVIDENCE_DIR/commands.log"
  set +e
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" \
    RESULT_DIR="$result_dir" IVFLAGS="$ivflags" "$target" \
    > "$result_dir.make.log" 2>&1
  local rc=$?
  set -e
  [[ -s "$build_dir/$test.vvp" ]] ||
    fail "$profile did not compile/elaborate"
  [[ "$rc" -ne 0 ]] || fail "$profile did not activate its assertion"
  grep -Fq "$marker" "$target" ||
    fail "$profile missed assertion marker: $marker"
  printf '[V8T-PROFILE][PASS] run_id=%s profile=%s expected_assertion=%s image_sha256=%s\n' \
    "$RUN_ID" "$profile" "$marker" \
    "$(sha256sum "$build_dir/$test.vvp" | awk '{print $1}')" \
    >> "$EVIDENCE_DIR/profile-summary.log"
}

: > "$EVIDENCE_DIR/profile-summary.log"
run_baseline_tb sq-release tb_ooo_store_queue '' '[V8T-F3-SQ-QUERY]'
run_baseline_tb sq-assert tb_ooo_store_queue '-DOOO_ASSERT' '[V8T-F3-SQ-QUERY]'
run_expected_assertion_tb sq-x-metadata-assert tb_ooo_store_queue \
  '-DOOO_ASSERT -DV8T_X_FAULT_INJECTION' '[V8T-SQ-QUERY0-KNOWN]'
run_baseline_tb bridge-release tb_ooo_mem_axi_bridge '' '[V8T-F3-BRIDGE-QUERY]'
run_baseline_tb bridge-assert tb_ooo_mem_axi_bridge '-DOOO_ASSERT' '[V8T-F3-BRIDGE-QUERY]'
run_baseline_tb backend-dual-release tb_ooo_int_backend \
  '-DV8S_DUAL_MEMORY_FOCUSED' '[V8T-F3-BACKEND-RETRY]'
run_baseline_tb backend-dual-assert tb_ooo_int_backend \
  '-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' '[V8T-F3-BACKEND-RETRY]'
run_baseline_tb backend-legacy-assert tb_ooo_int_backend \
  '-DOOO_ASSERT' '[V8P-PAIR-MATRIX]'
run_baseline_tb core-glue-assert tb_ooo_core_top_glue \
  '-DOOO_ASSERT' '[RESULT] PASS'
run_baseline_tb priv-system-assert tb_ooo_priv_system \
  '-DOOO_ASSERT' '[RESULT] PASS'
run_baseline_tb sv39-boot-assert tb_ooo_sv39_boot \
  '-DOOO_ASSERT' '[RESULT] PASS'

mutation_rows=(
  'sq_compare_va|sq|tb_ooo_store_queue|sq.final_physical_byte_compare_only|F3 shifted full cover is onehot forward'
  'sq_partial_allow|sq|tb_ooo_store_queue|sq.fail_closed_youngest_merge_semantics|F3 partial overlap is onehot replay'
  'sq_include_terminal|sq|tb_ooo_store_queue|sq.fail_closed_youngest_merge_semantics|F3 terminal older store is excluded'
  'sq_oldest_byte_wins|sq|tb_ooo_store_queue|sq.fail_closed_youngest_merge_semantics|F3 merged youngest bytes win'
  'sq_io_allow|sq|tb_ooo_store_queue|sq.fail_closed_youngest_merge_semantics|F3 older IO store replays'
  'sq_unfilled_allow|sq|tb_ooo_store_queue|sq.fail_closed_youngest_merge_semantics|F3 unfilled older store replays'
  'sq_invalid_metadata_allow|sq|tb_ooo_store_queue|sq.invalid_and_unknown_metadata_fail_closed|F3 invalid query attr replays'
  'sq_age_linear0|sq|tb_ooo_store_queue|sq.edge_old_full_pid_age|F3 ROB-wrap older store forwards'
  'sq_age_equal0|sq|tb_ooo_store_queue|sq.edge_old_full_pid_age|F3 same-age different-generation store is excluded'
  'sq_query1_paddr_cross|sq|tb_ooo_store_queue|sq.bank_local_query_payloads_not_crossed|F3 dual forward bank1 data'
  'sq_query1_poison_allow|sq|tb_ooo_store_queue|sq.invalid_and_unknown_metadata_fail_closed|F3 dual retry bank1 onehot'
  'bridge_hold_replay|bridge|tb_ooo_mem_axi_bridge|bridge.exact_forward_retry_state_transitions|V8T-SQ-QUERY-RETRY-HANDOFF'
  'bridge_release_without_credit|bridge|tb_ooo_mem_axi_bridge|bridge.exact_forward_retry_state_transitions|F3 replay query held valid'
  'bridge_route_bare_bypass|bridge|tb_ooo_mem_axi_bridge|bridge.bare_ptw_ad_paths_converge_on_query|mem0 read final-PA query valid'
  'bridge_route_ptw_bypass|bridge|tb_ooo_mem_axi_bridge|bridge.bare_ptw_ad_paths_converge_on_query|sv39 translated load reaches SQ query'
  'bridge_route_ad_bypass|bridge|tb_ooo_mem_axi_bridge|bridge.bare_ptw_ad_paths_converge_on_query|sv39 A/D update load reaches SQ query'
  'bridge_forward_lookup|bridge|tb_ooo_mem_axi_bridge|bridge.exact_forward_retry_state_transitions|V8T-SQ-QUERY-FORWARD-CAPTURE'
  'bridge_dtlb_fault_query|bridge|tb_ooo_mem_axi_bridge|bridge.prequery_fault_and_late_response_quiet|F3 DTLB fault response stays out of SQ query'
  'bridge_pmp_fault_query|bridge|tb_ooo_mem_axi_bridge|bridge.prequery_fault_and_late_response_quiet|F3 PMP fault response stays out of SQ query'
  'bridge_late_ad_dtlb_fill|bridge|tb_ooo_mem_axi_bridge|bridge.prequery_fault_and_late_response_quiet|S2-G1 killed A/D late B forbids DTLB fill'
  'retry_no_pop0|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T retry0 capture pops bank0 MIQ'
  'retry_no_pop1|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T-RETRY1-HANDOFF-NEXT-Q'
  'retry_wrong_token0|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T retry0 request preserves token'
  'retry_wrong_token1|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T retry request preserves token'
  'retry_silent_kill0|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T killed retry0 owns terminal lane10'
  'retry_silent_kill1|backend|tb_ooo_int_backend|backend.retry_pop_repush_and_kill_terminal|V8T killed retry owns terminal lane11'
  'retry_priority_invert0|backend|tb_ooo_int_backend|backend.edge_old_store_priority_and_slot_backing|V8T retry0 request valid under backpressure'
  'retry_priority_invert1|backend|tb_ooo_int_backend|backend.edge_old_store_priority_and_slot_backing|V8T retry request valid under backpressure'
  'retry_load_fence_delete0|backend|tb_ooo_int_backend|backend.one_retry_slot_load_admission_fence|V8T retry0 holder fence blocks load admission'
  'retry_load_fence_delete1|backend|tb_ooo_int_backend|backend.one_retry_slot_load_admission_fence|V8T retry1 holder fence blocks load admission'
  'retry_active_fence_delete1|backend|tb_ooo_int_backend|backend.one_retry_slot_load_admission_fence|V8T bridge-active fence blocks load admission'
  'retry_station_fence_delete1|backend|tb_ooo_int_backend|backend.one_retry_slot_load_admission_fence|V8T bridge-station fence blocks load admission'
  'retry_cancel_priority_delete1|backend|tb_ooo_int_backend|backend.retry_control_order_and_symmetric_directed|V8T killed retry holder clears'
  'retry_fp_capture_drop1|backend|tb_ooo_int_backend|backend.forwarded_integer_fp_sink_equivalence|V8T retry capture preserves destination domain'
  'retry_fp_repush_drop1|backend|tb_ooo_int_backend|backend.forwarded_integer_fp_sink_equivalence|V8T FP retry re-push preserves FP destination'
  'dual_slot_valid_bypass|backend|tb_ooo_int_backend|backend.edge_old_store_priority_and_slot_backing|V8S live LEGACY blocks bank1 ordinary'
  'legacy_all_load_block|backend|tb_ooo_int_backend|backend.canonical_dual_disables_legacy_va_blind_gate|-'
  'cross_bank_query_pid|backend|tb_ooo_int_backend|backend.bank_local_exact_query_mapping|V8T retry query exact'
)

: > "$EVIDENCE_DIR/mutation-summary.tsv"
for row in "${mutation_rows[@]}"; do
  IFS='|' read -r name role test static_check dynamic_oracle <<< "$row"
  mutation_dir="$EVIDENCE_DIR/mutations/$name"
  build_dir="$TEMP_DIR/mutant-builds/$name"
  case "$role" in
    sq)
      source="$SQ"
      mutant="$TEMP_DIR/mutants/$name/OooStoreQueue.v"
      checker_override=(--sq "$mutant")
      make_override=(RTL_OOO_STORE_QUEUE="$mutant")
      defines='-DOOO_ASSERT'
      ;;
    bridge)
      source="$BRIDGE"
      mutant="$TEMP_DIR/mutants/$name/OooMemAxiBridge.v"
      checker_override=(--bridge "$mutant")
      make_override=(RTL_OOO_MEM_AXI_BRIDGE="$mutant")
      defines='-DOOO_ASSERT'
      ;;
    backend)
      source="$BACKEND"
      mutant="$TEMP_DIR/mutants/$name/OooIntBackend.v"
      checker_override=(--backend "$mutant")
      make_override=(RTL_OOO_INT_BACKEND="$mutant")
      defines='-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED'
      ;;
    *) fail "unknown mutation role: $role" ;;
  esac
  mkdir -p "$mutation_dir"
  python3 "$MUTATOR" "$name" "$source" "$mutant" \
    --json-out "$mutation_dir/activation.json" \
    > "$mutation_dir/mutator.log" 2>&1 || fail "$name mutator failed"
  set +e
  python3 "$CHECKER" --repo-root "$REPO_ROOT" \
    "${checker_override[@]}" --json-out "$mutation_dir/source-checks.json" \
    > "$mutation_dir/source-checks.log" 2>&1
  checker_rc=$?
  set -e
  [[ "$checker_rc" -eq 1 ]] ||
    fail "$name escaped its fail-closed source oracle"
  grep -Fq "[V8T-CHECK][FAIL] $static_check:" \
    "$mutation_dir/source-checks.log" ||
    fail "$name missed targeted static oracle: $static_check"

  target="$mutation_dir/logs/$test.log"
  ivflags="-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon $defines"
  set +e
  make -B -C "$TB_HOME" BUILD_DIR="$build_dir" \
    RESULT_DIR="$mutation_dir" IVFLAGS="$ivflags" \
    "${make_override[@]}" "$target" > "$mutation_dir/make.log" 2>&1
  dynamic_rc=$?
  set -e
  [[ -s "$build_dir/$test.vvp" ]] || fail "$name did not compile/elaborate"
  dynamic_status=not_required
  if [[ "$dynamic_oracle" != '-' ]]; then
    [[ "$dynamic_rc" -ne 0 ]] || fail "$name escaped dynamic oracle"
    grep -Fq "$dynamic_oracle" "$target" ||
      fail "$name missed targeted dynamic oracle: $dynamic_oracle"
    dynamic_status=target_rejected
  fi
  printf '%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$role" "$static_check" "$dynamic_status" \
    "$(sha256sum "$mutant" | awk '{print $1}')" \
    "$(sha256sum "$build_dir/$test.vvp" | awk '{print $1}')" \
    "$dynamic_rc" >> "$EVIDENCE_DIR/mutation-summary.tsv"
done
[[ "$(wc -l < "$EVIDENCE_DIR/mutation-summary.tsv")" -eq 38 ]] ||
  fail "mutation summary does not contain exactly thirty-eight activated mutants"
[[ "$(grep -c 'target_rejected' "$EVIDENCE_DIR/mutation-summary.tsv")" -eq 37 ]] ||
  fail "mutation summary does not contain thirty-seven targeted dynamic rejections"

printf '%s\n' 'make F0 predecessor' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" check-dual-memory-fabric-foundation \
  > "$EVIDENCE_DIR/predecessors/f0.log" 2>&1 ||
  fail "F0 predecessor regressed"
printf '%s\n' 'make F1 predecessor' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" check-dual-memory-bridge-wrapper \
  > "$EVIDENCE_DIR/predecessors/f1.log" 2>&1 ||
  fail "F1 predecessor regressed"
printf '%s\n' 'make F2 predecessor' >> "$EVIDENCE_DIR/commands.log"
make -C "$NPC_HOME" check-dual-memory-core-integration \
  > "$EVIDENCE_DIR/predecessors/f2.log" 2>&1 ||
  fail "F2 predecessor regressed"

set +e
python3 "$ARCH_TOOL" --repo-root "$REPO_ROOT" \
  --evidence-manifest "$ARCH_MANIFEST" \
  --output "$EVIDENCE_DIR/static/architecture-hard-gates.json" \
  > "$EVIDENCE_DIR/static/architecture-hard-gates.log" 2>&1
architecture_rc=$?
set -e
[[ "$architecture_rc" -eq 1 ]] ||
  fail "architecture hard gate was not expected fail-closed RED"
python3 - "$EVIDENCE_DIR/static/architecture-hard-gates.json" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
actual = {
    "DI-5": payload["gates"]["DI-5"]["status"],
    "OOO-3": payload["gates"]["OOO-3"]["status"],
    "overall": payload["overall_status"],
}
expected = {"DI-5": "RED", "OOO-3": "RED", "overall": "RED"}
if actual != expected:
    raise SystemExit(f"v8t claim boundary violated: {actual}")
PY

sha256sum "${source_paths[@]}" > "$EVIDENCE_DIR/sources.post.sha256"
cmp -s "$EVIDENCE_DIR/sources.pre.sha256" "$EVIDENCE_DIR/sources.post.sha256" ||
  fail "source closure changed during focused run"
sha256sum "$ARCH_MANIFEST" > "$EVIDENCE_DIR/architecture-manifest.post.sha256"
cmp -s "$EVIDENCE_DIR/architecture-manifest.pre.sha256" \
  "$EVIDENCE_DIR/architecture-manifest.post.sha256" ||
  fail "runner rewrote canonical architecture evidence"

closure_sha=$(sha256sum "$EVIDENCE_DIR/sources.pre.sha256" | awk '{print $1}')
python3 "$FINALIZER" \
  --output "$EVIDENCE_DIR/result.json" \
  --final-log "$EVIDENCE_DIR/final.log" \
  --run-id "$RUN_ID" \
  --source-closure-sha256 "$closure_sha" \
  --mutation-summary "$EVIDENCE_DIR/mutation-summary.tsv" \
  --repo-root "$REPO_ROOT" || fail "F3 candidate/checkpoint finalization failed"
cat "$EVIDENCE_DIR/final.log"
