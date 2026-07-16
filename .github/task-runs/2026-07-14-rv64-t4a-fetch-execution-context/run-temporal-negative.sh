#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t4a-fetch-execution-context"
OUT_DIR="$TASK_DIR/evidence/temporal-negative-v1"
WORK_DIR="$ROOT_DIR/tmp/2026-07-14-rv64-t4a-temporal-negative"
TB_DIR="$ROOT_DIR/npc/rv64/testbench"
VSRCDIR="$ROOT_DIR/npc/rv64/vsrc"
BRIDGE_SRC="$VSRCDIR/frontend/OooFetchAxiBridge.v"

mkdir -p "$OUT_DIR/logs" "$WORK_DIR"

compile_bridge() {
  local bridge_src=$1
  local image=$2
  iverilog -g2012 -Wall \
    -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TB_DIR/common" \
    -DOOO_ASSERT -s tb_ooo_fetch_axi_bridge -o "$image" \
    "$VSRCDIR/memory/PmpChecker.v" \
    "$VSRCDIR/cache/OooFetchPacketCache.v" \
    "$VSRCDIR/sram/Sram4096x199.v" \
    "$VSRCDIR/memory/OooSv39Tlb.v" \
    "$bridge_src" \
    "$TB_DIR/tests/tb_ooo_fetch_axi_bridge.sv"
}

run_expect_clean() {
  local image=$1
  local log=$2
  vvp "$image" >"$log" 2>&1
  if grep -Eq '\[T4A-|ERROR:|FATAL:' "$log"; then
    echo "production baseline emitted an assertion/fatal marker" >&2
    return 1
  fi
  if ! grep -Fq "[PASS] tb_ooo_fetch_axi_bridge" "$log"; then
    echo "production baseline missed PASS marker" >&2
    return 1
  fi
}

run_expect_marker() {
  local image=$1
  local marker=$2
  local log=$3
  set +e
  vvp "$image" >"$log" 2>&1
  local sim_rc=$?
  set -e
  if ! grep -Fq "$marker" "$log"; then
    echo "missing expected marker $marker (sim_rc=$sim_rc)" >&2
    return 1
  fi
}

# First prove that the unmodified implementation and the same assertion-enabled
# harness are green.  Each following probe changes one local theorem only.
compile_bridge "$BRIDGE_SRC" "$WORK_DIR/baseline.vvp" \
  >"$OUT_DIR/logs/baseline-compile.log" 2>&1
run_expect_clean "$WORK_DIR/baseline.vvp" "$OUT_DIR/logs/baseline.log"

# Mutation 1: S_CACHE_READ captures a raw live PC rather than the candidate
# belonging to the accepted request.  The test intentionally poisons live
# inputs after fire; the independent owner shadow must reject the handoff.
EXEC_FROM_LIVE="$WORK_DIR/OooFetchAxiBridge-exec-from-live.v"
cp "$BRIDGE_SRC" "$EXEC_FROM_LIVE"
perl -0pi -e \
  's/fetch_ctx_exec_pc_q <= fetch_ctx_candidate_pc_q;/fetch_ctx_exec_pc_q <= fetch_req_pc_i; \/\* temporal mutation \*\//' \
  "$EXEC_FROM_LIVE"
compile_bridge "$EXEC_FROM_LIVE" "$WORK_DIR/exec-from-live.vvp" \
  >"$OUT_DIR/logs/exec-from-live-compile.log" 2>&1
run_expect_marker "$WORK_DIR/exec-from-live.vvp" \
  "[T4A-EXEC-HANDOFF]" "$OUT_DIR/logs/exec-from-live.log"

# Mutation 2: the architectural owner remains on old exec during
# S_CACHE_READ.  A request fire must expose the newly captured candidate.
OWNER_ALWAYS_EXEC="$WORK_DIR/OooFetchAxiBridge-owner-always-exec.v"
cp "$BRIDGE_SRC" "$OWNER_ALWAYS_EXEC"
perl -0pi -e \
  "s/wire fetch_ctx_owner_candidate_w = \(state_q == S_CACHE_READ\);/wire fetch_ctx_owner_candidate_w = 1'b0; \/\* temporal mutation \*\//" \
  "$OWNER_ALWAYS_EXEC"
compile_bridge "$OWNER_ALWAYS_EXEC" "$WORK_DIR/owner-always-exec.vvp" \
  >"$OUT_DIR/logs/owner-always-exec-compile.log" 2>&1
run_expect_marker "$WORK_DIR/owner-always-exec.vvp" \
  "[T4A-FIRE-CANDIDATE]" "$OUT_DIR/logs/owner-always-exec.log"

# Mutation 3: a walk enters AXI AR without the registered authorization
# state.  The predecessor checker is deliberately independent of ARVALID.
BYPASS_WALK_CHECK="$WORK_DIR/OooFetchAxiBridge-bypass-walk-check.v"
cp "$BRIDGE_SRC" "$BYPASS_WALK_CHECK"
perl -0pi -e \
  's/state_q <= S_WALK_CHECK;/state_q <= S_WALK_AR; \/\* temporal mutation \*\//g' \
  "$BYPASS_WALK_CHECK"
compile_bridge "$BYPASS_WALK_CHECK" "$WORK_DIR/bypass-walk-check.vvp" \
  >"$OUT_DIR/logs/bypass-walk-check-compile.log" 2>&1
run_expect_marker "$WORK_DIR/bypass-walk-check.vvp" \
  "[T4A-PTW-AR-PREDECESSOR]" "$OUT_DIR/logs/bypass-walk-check.log"

# Mutation 4: corrupt the address at the CHECK->AR boundary.  The expected
# address is sampled directly from the pre-boundary combinational result and
# therefore does not share the corrupted production register.
CORRUPT_PTW_ADDR="$WORK_DIR/OooFetchAxiBridge-corrupt-ptw-addr.v"
cp "$BRIDGE_SRC" "$CORRUPT_PTW_ADDR"
perl -0pi -e \
  "s/walk_pte_addr_q <= walk_pte_addr_w;/walk_pte_addr_q <= walk_pte_addr_w ^ 64'd8; \/\* temporal mutation \*\//" \
  "$CORRUPT_PTW_ADDR"
compile_bridge "$CORRUPT_PTW_ADDR" "$WORK_DIR/corrupt-ptw-addr.vvp" \
  >"$OUT_DIR/logs/corrupt-ptw-addr-compile.log" 2>&1
run_expect_marker "$WORK_DIR/corrupt-ptw-addr.vvp" \
  "[T4A-PTW-AUTH-CAPTURE]" "$OUT_DIR/logs/corrupt-ptw-addr.log"

# Mutation 5: restore the old combinational flush gate on the complete ARVALID
# expression.  The directed stalled-WALK case must see VALID disappear while
# the independent port shadow still owns the prior payload.
FLUSH_GATES_AR="$WORK_DIR/OooFetchAxiBridge-flush-gates-ar.v"
cp "$BRIDGE_SRC" "$FLUSH_GATES_AR"
perl -0pi -e \
  "s/\(state_q == S_FETCH_AR_DROP\)\);/(state_q == S_FETCH_AR_DROP)) \&\& !mmu_flush_i;/" \
  "$FLUSH_GATES_AR"
compile_bridge "$FLUSH_GATES_AR" "$WORK_DIR/flush-gates-ar.vvp" \
  >"$OUT_DIR/logs/flush-gates-ar-compile.log" 2>&1
run_expect_marker "$WORK_DIR/flush-gates-ar.vvp" \
  "[IFU-AR-HOLD]" "$OUT_DIR/logs/flush-gates-ar.log"

{
  echo "status=PASS"
  echo "production_baseline=PASS"
  echo "exec_from_live=REJECTED:[T4A-EXEC-HANDOFF]"
  echo "owner_always_exec=REJECTED:[T4A-FIRE-CANDIDATE]"
  echo "bypass_walk_check=REJECTED:[T4A-PTW-AR-PREDECESSOR]"
  echo "corrupt_ptw_address=REJECTED:[T4A-PTW-AUTH-CAPTURE]"
  echo "flush_gates_arvalid=REJECTED:[IFU-AR-HOLD]"
} >"$OUT_DIR/summary.txt"

echo "[T4A-TEMPORAL-NEGATIVE] PASS"
