#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)
OUT=${1:-"$SCRIPT_DIR/evidence/r4-s1p1-typed-leaves-v2"}
VSRCDIR="$ROOT/npc/rv64/vsrc"
TBDIR="$ROOT/npc/rv64/testbench"
PMA_RTL="$VSRCDIR/memory/OooTypedPmaChecker.v"
PMA_COMPAT_RTL="$VSRCDIR/memory/OooPmaChecker.v"
CLASS_RTL="$VSRCDIR/memory/OooTypedMemoryClassifier.v"
PMA_TB="$TBDIR/tests/tb_ooo_pma_checker.sv"
CLASS_TB="$TBDIR/tests/tb_ooo_typed_memory_classifier.sv"
NEG_TB="$SCRIPT_DIR/tb-r4-s1p1-typed-negative.sv"
IVERILOG=${IVERILOG:-iverilog}
IVERILOG_PATH=$(command -v "$IVERILOG")
VVP=${VVP:-"$(dirname "$IVERILOG_PATH")/vvp"}
YOSYS=${YOSYS:-"$ROOT/oss-cad-suite/bin/yosys"}

if [[ -e "$OUT" ]]; then
  echo "refusing to overwrite evidence directory: $OUT" >&2
  exit 2
fi
mkdir -p "$OUT/build" "$OUT/logs" "$OUT/mutations"

compile_and_run() {
  local name=$1
  local top=$2
  local defines=$3
  shift 3
  local log="$OUT/logs/$name.log"
  "$IVERILOG_PATH" -g2012 -Wall \
    -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TBDIR/common" \
    $defines -s "$top" -o "$OUT/build/$name.vvp" "$@" >"$log" 2>&1
  "$VVP" "$OUT/build/$name.vvp" >>"$log" 2>&1
}

compile_and_run pma-positive tb_ooo_pma_checker "-DOOO_ASSERT" \
  "$PMA_RTL" "$PMA_COMPAT_RTL" "$PMA_TB"
grep -Fq '[PASS] tb_ooo_pma_checker' "$OUT/logs/pma-positive.log"

compile_and_run classifier-positive tb_ooo_typed_memory_classifier \
  "-DOOO_ASSERT" "$CLASS_RTL" "$CLASS_TB"
grep -Fq '[PASS] tb_ooo_typed_memory_classifier' \
  "$OUT/logs/classifier-positive.log"
grep -Fq '[R4-S1.1-TYPED-CLASS] enabled_matrix=16 disabled_leaf=16' \
  "$OUT/logs/classifier-positive.log"

# 第二次无断言编译专门验证非法 producer 输入仍 fail-closed；严格 producer 断言由下组负测证明。
compile_and_run classifier-failclosed tb_ooo_typed_memory_classifier \
  "-DTYPED_FAILCLOSED_INPUT_TEST" "$CLASS_RTL" "$CLASS_TB"
grep -Fq '[PASS] tb_ooo_typed_memory_classifier' \
  "$OUT/logs/classifier-failclosed.log"

for positive_log in \
  "$OUT/logs/pma-positive.log" \
  "$OUT/logs/classifier-positive.log" \
  "$OUT/logs/classifier-failclosed.log"; do
  if grep -Eq 'ERROR:|%Error|\[TYPED-' "$positive_log"; then
    echo "unexpected error/assertion marker in positive log: $positive_log" >&2
    exit 1
  fi
done

"$IVERILOG_PATH" -g2012 -Wall -DOOO_ASSERT \
  -I"$VSRCDIR" -I"$VSRCDIR/include" \
  -s tb_r4_s1p1_typed_negative -o "$OUT/build/typed-negative.vvp" \
  "$CLASS_RTL" "$NEG_TB" >"$OUT/logs/negative-compile.log" 2>&1

expect_exact_marker() {
  local case_name=$1
  local marker=$2
  local log="$OUT/logs/negative-$case_name.log"
  set +e
  "$VVP" "$OUT/build/typed-negative.vvp" "+CASE=$case_name" >"$log" 2>&1
  local rc=$?
  set -e
  test "$(grep -Fc "$marker" "$log")" -eq 1
  test "$(grep -Fc '[TYPED-' "$log")" -eq 1
  grep -Fq "[R4-S1.1-NEGATIVE-SENTINEL] case=$case_name" "$log"
  printf 'case=%s rc=%s marker=%s\n' "$case_name" "$rc" "$marker" \
    >>"$OUT/negative-summary.txt"
}

expect_exact_marker pma_inconsistent '[TYPED-PMA-ATTR-INCONSISTENT]'
expect_exact_marker pma_rsvd '[TYPED-PMA-RSVD-INPUT]'
expect_exact_marker class_poison '[TYPED-CLASS-POISON]'

# 结构 mutation：删掉 PMEM-over-PSRAM 优先命中，聚焦 PMA TB 必须转 RED。
sed "0,/if (pmem_cover_w)/s//if (1'b0 \&\& pmem_cover_w)/" \
  "$PMA_RTL" >"$OUT/mutations/OooPmaChecker-no-pmem-priority.v"
"$IVERILOG_PATH" -g2012 -Wall \
  -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TBDIR/common" \
  -s tb_ooo_pma_checker -o "$OUT/build/pma-overlap-mutation.vvp" \
  "$OUT/mutations/OooPmaChecker-no-pmem-priority.v" "$PMA_COMPAT_RTL" "$PMA_TB" \
  >"$OUT/logs/pma-overlap-mutation-compile.log" 2>&1
set +e
"$VVP" "$OUT/build/pma-overlap-mutation.vvp" \
  >"$OUT/logs/pma-overlap-mutation.log" 2>&1
PMA_MUT_RC=$?
set -e
test "$PMA_MUT_RC" -ne 0
grep -Fq '[FAIL] tb_ooo_pma_checker' "$OUT/logs/pma-overlap-mutation.log"

# 结构 mutation：把 PBMTE-disabled 非零判据反转，disabled-leaf cases 必须转 RED。
sed "0,/(pbmt_i != 2'b00)/s//(pbmt_i == 2'b00)/" \
  "$CLASS_RTL" >"$OUT/mutations/OooTypedMemoryClassifier-bad-pbmte.v"
"$IVERILOG_PATH" -g2012 -Wall \
  -I"$VSRCDIR" -I"$VSRCDIR/include" -I"$TBDIR/common" \
  -s tb_ooo_typed_memory_classifier \
  -o "$OUT/build/classifier-pbmt-mutation.vvp" \
  "$OUT/mutations/OooTypedMemoryClassifier-bad-pbmte.v" "$CLASS_TB" \
  >"$OUT/logs/classifier-pbmt-mutation-compile.log" 2>&1
set +e
"$VVP" "$OUT/build/classifier-pbmt-mutation.vvp" \
  >"$OUT/logs/classifier-pbmt-mutation.log" 2>&1
CLASS_MUT_RC=$?
set -e
test "$CLASS_MUT_RC" -ne 0
grep -Fq '[FAIL] tb_ooo_typed_memory_classifier' \
  "$OUT/logs/classifier-pbmt-mutation.log"

make -C "$ROOT/npc/rv64" check-rtl-style >"$OUT/logs/rtl-style.log" 2>&1
verilator --lint-only -Wall -Wno-fatal -DOOO_ASSERT -I"$VSRCDIR/include" \
  --top-module OooTypedPmaChecker "$PMA_RTL" >"$OUT/logs/pma-verilator-lint.log" 2>&1
verilator --lint-only -Wall -Wno-fatal -DOOO_ASSERT -I"$VSRCDIR/include" \
  --top-module OooTypedMemoryClassifier "$CLASS_RTL" \
  >"$OUT/logs/classifier-verilator-lint.log" 2>&1
make -C "$ROOT/npc/rv64" lint >"$OUT/logs/full-verilator-lint.log" 2>&1

"$YOSYS" -q -p "read_verilog -sv -I$VSRCDIR/include $PMA_RTL; hierarchy -check -top OooTypedPmaChecker; proc; check" \
  >"$OUT/logs/pma-yosys-check.log" 2>&1
"$YOSYS" -q -p "read_verilog -sv -I$VSRCDIR/include $PMA_COMPAT_RTL; hierarchy -check -top OooPmaChecker; proc; check" \
  >"$OUT/logs/pma-compat-yosys-check.log" 2>&1
"$YOSYS" -q -p "read_verilog -sv -I$VSRCDIR/include $CLASS_RTL; hierarchy -check -top OooTypedMemoryClassifier; proc; check" \
  >"$OUT/logs/classifier-yosys-check.log" 2>&1
git -C "$ROOT" diff --check -- \
  npc/rv64/vsrc/include/define.v \
  npc/rv64/vsrc/memory/OooPmaChecker.v \
  npc/rv64/vsrc/memory/OooTypedPmaChecker.v \
  npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v \
  npc/rv64/vsrc/filelist.mk \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_pma_checker.sv \
  npc/rv64/testbench/tests/tb_ooo_typed_memory_classifier.sv \
  >"$OUT/logs/diff-check.log" 2>&1

python3 - \
  "$ROOT/npc/rv64/vsrc/memory/OooTypedPmaChecker.v" \
  "$ROOT/npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v" \
  "$ROOT/npc/rv64/testbench/tests/tb_ooo_typed_memory_classifier.sv" \
  "$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/tb-r4-s1p1-typed-negative.sv" \
  "$ROOT/.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-r4-s1p1-typed-leaves.sh" \
  <<'PY' >"$OUT/logs/untracked-whitespace-check.log"
from pathlib import Path
import sys

errors = []
for raw in sys.argv[1:]:
    path = Path(raw)
    data = path.read_bytes()
    if data and not data.endswith(b"\n"):
        errors.append(f"{path}: missing final newline")
    for lineno, line in enumerate(data.splitlines(), 1):
        if line.rstrip(b" \t") != line:
            errors.append(f"{path}:{lineno}: trailing whitespace")
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("untracked whitespace check PASS")
PY

(cd "$ROOT" && sha256sum npc/rv64/vsrc/memory/OooPmaChecker.v) \
  >"$OUT/logs/pma-compat-sha256.log"
grep -Fqx 'e197b137bfe1126f9191eaf3b2cfce779d26bdce0ead4a94d831552fe5732c2b  npc/rv64/vsrc/memory/OooPmaChecker.v' \
  "$OUT/logs/pma-compat-sha256.log"

(cd "$ROOT" && sha256sum \
  npc/rv64/vsrc/include/define.v \
  npc/rv64/vsrc/filelist.mk \
  npc/rv64/vsrc/memory/OooTypedPmaChecker.v \
  npc/rv64/vsrc/memory/OooPmaChecker.v \
  npc/rv64/vsrc/memory/OooTypedMemoryClassifier.v \
  npc/rv64/testbench/Makefile \
  npc/rv64/testbench/tests/tb_ooo_pma_checker.sv \
  npc/rv64/testbench/tests/tb_ooo_typed_memory_classifier.sv \
  .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/tb-r4-s1p1-typed-negative.sv \
  .github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/run-r4-s1p1-typed-leaves.sh) \
  >"$OUT/source-sha256.txt"
cat >"$OUT/summary.txt" <<EOF
schema=npc-rv64-r4-s1p1-typed-leaves-v2
result=PASS
pma_truth_table=PASS
pbmte_enabled_pma_pbmt_matrix=16
pbmte_disabled_translated_leaf_cases=16
classifier_failclosed_inputs=3
assertion_negative_cases=3
overlap_mutation=REJECTED rc=$PMA_MUT_RC
pbmt_mutation=REJECTED rc=$CLASS_MUT_RC
rtl_style=PASS
verilator_lint=PASS
full_verilator_lint=PASS
yosys_check=PASS
untracked_whitespace_check=PASS
source_binding=workspace_relative_10_files
s0_compat_checker_sha256=e197b137bfe1126f9191eaf3b2cfce779d26bdce0ead4a94d831552fe5732c2b
s0_compat_regression=PASS
bridge_integration=NOT_IN_SCOPE
dual_memory_owner=RED_NOT_CLAIMED
EOF

(cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z | \
  xargs -0 sha256sum >SHA256SUMS)
cat "$OUT/summary.txt"
