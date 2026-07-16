#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3x-fetch-init-boundary"
TB_DIR="$ROOT_DIR/npc/rv64/testbench"
VSRCDIR="$ROOT_DIR/npc/rv64/vsrc"
OUT_TAG=${T3X_NEGATIVE_OUT_TAG:-scratch-init-assert-negative-v1}
OUT_DIR="$TASK_DIR/evidence/$OUT_TAG"
MUTATED="$OUT_DIR/mutated/OooFetchAxiBridge.v"
PRODUCTION="$VSRCDIR/frontend/OooFetchAxiBridge.v"
TB="$TB_DIR/tests/tb_ooo_fetch_axi_bridge.sv"
RUNNER="$TASK_DIR/run-scratch-init-assert-negative.sh"

[[ ! -e $OUT_DIR ]] || {
  printf '[T3X-SCRATCH-NEGATIVE] refusing stale output: %s\n' "$OUT_DIR" >&2
  exit 3
}
mkdir -p "$OUT_DIR/mutated" "$OUT_DIR/build"

inputs=(
  "$PRODUCTION"
  "$TB"
  "$VSRCDIR/cache/OooFetchPacketCache.v"
  "$VSRCDIR/memory/OooSv39Tlb.v"
  "$VSRCDIR/memory/PmpChecker.v"
  "$VSRCDIR/sram/Sram4096x199.v"
  "$RUNNER"
)
sha256sum "${inputs[@]}" >"$OUT_DIR/inputs.pre.sha256"
production_pre=$(sha256sum "$PRODUCTION" | cut -d' ' -f1)

python3 - "$PRODUCTION" "$MUTATED" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
anchor = "          fetch_data_q <= {`XLEN{1'b0}};\n          inst0_q"
replacement = (
    "          fetch_data_q <= fetch_data_q; // NEGATIVE: retain stale owner\n"
    "          inst0_q"
)
if source.count(anchor) != 1:
    raise SystemExit(f"expected one mutation anchor, got {source.count(anchor)}")
Path(sys.argv[2]).write_text(source.replace(anchor, replacement), encoding="utf-8")
PY

mutation_count=$(grep -c 'NEGATIVE: retain stale owner' "$MUTATED")
[[ $mutation_count -eq 1 ]]

iverilog_bin=$(command -v iverilog)
vvp_bin="$(dirname "$iverilog_bin")/vvp"
[[ -x $vvp_bin ]] || vvp_bin=$(command -v vvp)

set +e
(
  cd "$TB_DIR"
  "$iverilog_bin" -g2012 -Wall \
    -I"$VSRCDIR" -I"$VSRCDIR/include" -Icommon -DOOO_ASSERT \
    -s tb_ooo_fetch_axi_bridge \
    -o "$OUT_DIR/build/tb_ooo_fetch_axi_bridge.vvp" \
    "$VSRCDIR/cache/OooFetchPacketCache.v" \
    "$MUTATED" \
    "$VSRCDIR/memory/OooSv39Tlb.v" \
    "$VSRCDIR/memory/PmpChecker.v" \
    "$VSRCDIR/sram/Sram4096x199.v" \
    "$TB" \
    >"$OUT_DIR/compile.log" 2>&1
)
compile_rc=$?
if [[ $compile_rc -eq 0 ]]; then
  "$vvp_bin" "$OUT_DIR/build/tb_ooo_fetch_axi_bridge.vvp" \
    >"$OUT_DIR/sim.log" 2>&1
  sim_rc=$?
else
  sim_rc=125
fi
set -e

sha256sum "${inputs[@]}" >"$OUT_DIR/inputs.post.sha256"
cmp -s "$OUT_DIR/inputs.pre.sha256" "$OUT_DIR/inputs.post.sha256"
production_post=$(sha256sum "$PRODUCTION" | cut -d' ' -f1)
[[ $production_pre == "$production_post" ]]

assert_hits=$(grep -c '\[IFU-T3X-SCRATCH-INIT\]' "$OUT_DIR/sim.log" || true)
check_fail_hits=$(grep -c '^\[CHECK-FAIL\]' "$OUT_DIR/sim.log" || true)
[[ $compile_rc -eq 0 ]]
[[ $assert_hits -ge 1 ]]
[[ $check_fail_hits -ge 1 ]]

{
  printf 'status=PASS\n'
  printf 'compile_rc=%s\n' "$compile_rc"
  printf 'sim_rc=%s\n' "$sim_rc"
  printf 'mutation_count=%s\n' "$mutation_count"
  printf 'assert_marker=IFU-T3X-SCRATCH-INIT\n'
  printf 'assert_hits=%s\n' "$assert_hits"
  printf 'direct_check_fail_hits=%s\n' "$check_fail_hits"
  printf 'production_sha256_pre=%s\n' "$production_pre"
  printf 'production_sha256_post=%s\n' "$production_post"
  printf 'production_input_freeze=PASS\n'
} >"$OUT_DIR/summary.txt"

printf '[T3X-SCRATCH-NEGATIVE] PASS assertion_hits=%s direct_check_fail_hits=%s evidence=%s\n' \
  "$assert_hits" "$check_fail_hits" "$OUT_DIR"
