#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
task_dir="$repo_root/.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal"
build_dir="$task_dir/evidence/red/build"
log_dir="$task_dir/evidence/red/logs"
mkdir -p "$build_dir" "$log_dir"

compile_log="$log_dir/tb_v9y_pending_memory_terminal_red.compile.log"
run_log="$log_dir/tb_v9y_pending_memory_terminal_red.log"

iverilog -g2012 -Wall -DOOO_ASSERT \
  -I"$repo_root/npc/rv64/vsrc" \
  -I"$repo_root/npc/rv64/vsrc/include" \
  -I"$repo_root/npc/rv64/testbench/common" \
  -s tb_v9y_pending_memory_terminal_red \
  -o "$build_dir/tb_v9y_pending_memory_terminal_red.vvp" \
  "$task_dir/tb_v9y_pending_memory_terminal_red.sv" \
  "$repo_root/npc/rv64/vsrc/control/OooPendingDrainResolveGate.v" \
  >"$compile_log" 2>&1

set +e
vvp "$build_dir/tb_v9y_pending_memory_terminal_red.vvp" \
  >"$run_log" 2>&1
run_rc=$?
set -e

printf 'compile_rc=0\nrun_rc=%s\n' "$run_rc" \
  >"$task_dir/evidence/red/status.txt"
test "$run_rc" -ne 0
grep -q '\[CHECK-FAIL\] V9Y non-CSR active memory owner blocks drain' \
  "$run_log"
grep -q '\[CHECK-FAIL\] V9Y CSR active memory owner blocks dispatch' \
  "$run_log"
grep -q '\[CHECK-FAIL\] V9Y CSR active memory owner blocks fire' \
  "$run_log"
grep -q '\[FAIL\] tb_v9y_pending_memory_terminal_red errors=3' \
  "$run_log"
printf '[V9Y-PREFX-RED] noncsr-drain=EARLY csr-dispatch=EARLY errors=3 PASS\n'

