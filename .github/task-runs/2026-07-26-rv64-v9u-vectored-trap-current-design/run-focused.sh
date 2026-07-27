#!/usr/bin/env bash
set -euo pipefail

root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
task_dir="$root/.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design"
current_dir="$task_dir/evidence/current"
mutation_dir="$task_dir/evidence/mutations"
build_dir="$root/npc/rv64/testbench/build-v9u-vectored-trap-current"
result_json="$root/npc/rv64/eval/ppa/evidence/vectored-trap-current.json"
raw_log="$root/npc/rv64/eval/ppa/evidence/vectored-trap.log"

design_sha="$(
  python3 - "$root" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
import architecture_hard_gates as gates

print(gates.rtl_binding(root)[0])
PY
)"

mkdir -p "$current_dir"
make -B -C "$root/npc/rv64/testbench" \
  "BUILD_DIR=$build_dir" \
  "RESULT_DIR=$current_dir" \
  "RTL_EVIDENCE_SHA=$design_sha" \
  "$current_dir/logs/tb_csr_file.log" \
  "$current_dir/logs/tb_csr_file_vectored_trap.log" \
  "$current_dir/logs/tb_ooo_priv_system.log"

python3 \
  "$root/npc/rv64/testbench/scripts/run_csr_vectored_trap_mutations.py" \
  --repo-root "$root" \
  --result-dir "$mutation_dir" \
  --reuse-result-dir

python3 "$root/npc/rv64/eval/ppa/tools/vectored_trap_evidence.py" \
  --root "$root" \
  --focused-log "$current_dir/logs/tb_csr_file_vectored_trap.log" \
  --program-log "$current_dir/logs/tb_ooo_priv_system.log" \
  --regression-log "$current_dir/logs/tb_csr_file.log" \
  --mutation-manifest "$mutation_dir/mutation-evidence.json" \
  --output "$result_json" \
  --raw-log "$raw_log"

grep -E \
  '^\[VECTORED-TRAP-G[1-5]-|^\[PASS\]|^\[RTL-DESIGN-ID\]|^\[RESULT\]' \
  "$current_dir/logs/tb_csr_file_vectored_trap.log" \
  "$current_dir/logs/tb_ooo_priv_system.log"
cat "$raw_log"
