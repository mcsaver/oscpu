#!/usr/bin/env bash
set -euo pipefail

run_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$run_dir" rev-parse --show-toplevel)
tb_dir="$repo_root/npc/rv64/testbench"
rtl="$repo_root/npc/rv64/vsrc/execute/OooIntBackend.v"
tb="$repo_root/npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
mutator="$run_dir/mutate-v9p-replay-capacity.py"
evidence="$run_dir/rtl-verification/v9p-replay-capacity-evidence"
baseline="$evidence/baseline"
mutation="$evidence/fence-open-mutation"
mutant="$mutation/OooIntBackend.v"

mkdir -p "$baseline" "$mutation"

python3 "$mutator" --source "$rtl" --out "$mutant"

make -B -C "$tb_dir" \
  TESTS=tb_ooo_int_backend \
  TB_IVFLAGS_tb_ooo_int_backend='-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' \
  BUILD_DIR="$baseline/build" \
  RESULT_DIR="$baseline/result" \
  run

baseline_log="$baseline/result/logs/tb_ooo_int_backend.log"
grep -Fq '[V9P-REPLAY-CAPACITY-ADMISSION] banks=2 active=2 station=2 older_sq=4 PASS' \
  "$baseline_log"
grep -Fq '[V8U-F4-BACKEND-NEXT]' "$baseline_log"
grep -Fq '[RESULT] PASS' "$baseline_log"

set +e
make -B -C "$tb_dir" \
  TESTS=tb_ooo_int_backend \
  RTL_OOO_INT_BACKEND="$mutant" \
  TB_IVFLAGS_tb_ooo_int_backend='-DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED' \
  BUILD_DIR="$mutation/build" \
  RESULT_DIR="$mutation/result" \
  run
mutation_rc=$?
set -e

mutation_log="$mutation/result/logs/tb_ooo_int_backend.log"
if [[ "$mutation_rc" -eq 0 ]]; then
  printf '[V9P-EVIDENCE][FAIL] fence-open mutation unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq '[COMPILE]' "$mutation_log"
grep -Fq '[V9P-REPLAY-CAPACITY-ADMISSION] load with older SQ owner crossed same-bank active/station fence' \
  "$mutation_log"
grep -Fq '[RESULT] FAIL' "$mutation_log"

sha256sum "$rtl" "$tb" "$mutator" "$mutant" > "$evidence/binding.sha256"
printf 'PASS\n' > "$baseline/status"
printf 'REJECTED_COMPILE_SUCCESS_MUTATION rc=%s\n' "$mutation_rc" \
  > "$mutation/status"
printf '%s\n' \
  '# V9P replay-capacity evidence' \
  '' \
  '- baseline: PASS' \
  '- directed marker: banks=2, active=2, station=2, older_sq=4' \
  '- SQ-empty F4 control: PASS' \
  "- fence-open compile-success mutation: REJECTED (make rc=$mutation_rc)" \
  '- PPA status: architecture correction; synthesis/STA not yet run' \
  > "$evidence/summary.md"

printf '[V9P-REPLAY-CAPACITY-EVIDENCE] baseline=PASS mutation=REJECTED PASS\n'
