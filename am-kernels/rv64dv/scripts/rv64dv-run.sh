#!/usr/bin/env bash
# rv64dv —— 用 chipsalliance/riscv-dv 约束随机指令流压测 NEMU 的 RV64 准确性。
#
# 定位：平台无关的重型压力测试，"仅 NEMU"（暂不接 NPC —— NPC 自身有 bug，
# 先用 riscv-dv 死磕 NEMU 的准确性，确定 NEMU 是可信金标准后，再做 NPC difftest）。
#
# 判定方式（比 tohost 自检更强）：NEMU 自带 difftest，DUT=NEMU、REF=spike-diff，
# 每条指令后逐寄存器 + PC 比对。任何 NEMU 与 Spike 的行为差异都会被 difftest 立即
# 报 mismatch。一个测试 PASS 的充要条件 = 干净 HIT GOOD TRAP 且全程零 mismatch。
#
# 流程：riscv-dv pyflow 生成随机 .S → riscv-none-elf-gcc 编译 → NEMU difftest(-d spike)。
#
# 环境变量（均有默认值）：
#   RV64DV_TEST   riscv-dv 测试名（默认 riscv_arithmetic_basic_test）
#   RV64DV_ITER   每个测试的随机迭代数（默认 2）
#   RV64DV_TARGET riscv-dv target（默认 rv64imafdc —— pyflow 仅提供此 RV64 target）
#   RV64DV_MAXI   NEMU --max-insts 上限（默认 20000000）
#   RV64DV_OUT    生成物输出目录（默认 am-kernels/rv64dv/out）
#   RV64DV_NODIFF 置 1 则关 difftest，只跑 NEMU 单机（robustness，不比对 Spike）
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RV64DV_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"                 # am-kernels/rv64dv
REPO_ROOT="$(cd "$RV64DV_HOME/../.." && pwd)"               # ysyx-workbench
RISCV_DV="$RV64DV_HOME/riscv-dv"
VENV="$RV64DV_HOME/venv"
NEMU="$REPO_ROOT/nemu/build/riscv64-nemu-interpreter"
REF="$REPO_ROOT/nemu/tools/spike-diff/build/riscv64-spike-so"
XPACK="$REPO_ROOT/am-kernels/arch-test/env/xpack-riscv-none-elf-gcc-15.2.0-1"
SPIKE_DIR="$REPO_ROOT/nemu/tools/spike-diff/repo/build"

TEST="${RV64DV_TEST:-riscv_arithmetic_basic_test}"
ITER="${RV64DV_ITER:-2}"
TARGET="${RV64DV_TARGET:-rv64imafdc}"
MAXI="${RV64DV_MAXI:-20000000}"
OUT="${RV64DV_OUT:-$RV64DV_HOME/out}"
NODIFF="${RV64DV_NODIFF:-0}"

NM="$XPACK/bin/riscv-none-elf-nm"
OBJCOPY="$XPACK/bin/riscv-none-elf-objcopy"

# ---- 前置检查 ----
fail_pre() { echo "[rv64dv] 前置缺失: $1" >&2; exit 2; }
[ -x "$NEMU" ] || fail_pre "NEMU 未编译: $NEMU (先 make -C nemu)"
[ "$NODIFF" = 1 ] || [ -f "$REF" ] || fail_pre "spike-diff ref 未编译: $REF (make -C nemu/tools/spike-diff GUEST_ISA=riscv64)"
[ -d "$RISCV_DV" ] || fail_pre "riscv-dv 生成器缺失: $RISCV_DV"
[ -d "$VENV" ]     || fail_pre "python venv 缺失: $VENV"
[ -x "$XPACK/bin/riscv-none-elf-gcc" ] || fail_pre "riscv 工具链缺失: $XPACK"

export PATH="$VENV/bin:$XPACK/bin:$SPIKE_DIR:$PATH"
export RISCV_GCC="$XPACK/bin/riscv-none-elf-gcc"
export RISCV_OBJCOPY="$OBJCOPY"
export SPIKE_PATH="$SPIKE_DIR"

echo "[rv64dv] test=$TEST iter=$ITER target=$TARGET difftest=$([ "$NODIFF" = 1 ] && echo off || echo on)"
rm -rf "$OUT"; mkdir -p "$OUT"

# ---- 1. 生成 + 编译（riscv-dv pyflow）----
echo "[rv64dv] === gen + gcc_compile ==="
( cd "$RISCV_DV" && python run.py --target "$TARGET" -tn "$TEST" -i "$ITER" \
    -si pyflow --isa "$TARGET" -s gen,gcc_compile -o "$OUT" ) 2>&1 \
  | grep -iE "ERROR|passed|generat|compil" | tail -5
shopt -s nullglob
OBJS=("$OUT"/asm_test/*.o)
[ "${#OBJS[@]}" -gt 0 ] || { echo "[rv64dv] 生成 0 个测试，失败"; exit 1; }

# ---- 2. NEMU difftest 逐个 ----
echo "[rv64dv] === NEMU $([ "$NODIFF" = 1 ] && echo run || echo difftest-vs-spike) ==="
pass=0; fail=0
for O in "${OBJS[@]}"; do
  BIN="${O%.o}.bin"
  [ -f "$BIN" ] || "$OBJCOPY" -O binary "$O" "$BIN" 2>/dev/null
  TH=$("$NM" "$O" 2>/dev/null | awk '$NF=="tohost"{print "0x"$1}')
  name="$(basename "$O")"
  [ -n "$TH" ] || { echo "  SKIP $name (无 tohost 符号)"; continue; }
  if [ "$NODIFF" = 1 ]; then
    r=$(timeout 150 "$NEMU" -b -e "$O" --tohost="$TH" --max-insts="$MAXI" "$BIN" 2>&1)
  else
    r=$(timeout 150 "$NEMU" -b -d "$REF" -e "$O" --tohost="$TH" --max-insts="$MAXI" "$BIN" 2>&1)
  fi
  if echo "$r" | grep -q "HIT GOOD TRAP" && ! echo "$r" | grep -qiE "mismatch|different|HIT BAD|Assertion"; then
    ic=$(echo "$r" | grep -oE "guest instructions = [0-9]+" | grep -oE "[0-9]+" | tail -1)
    echo "  PASS $name (insts=${ic:-?})"; pass=$((pass+1))
  else
    echo "  FAIL $name"; echo "$r" | grep -iE "mismatch|different|HIT BAD|Assertion|abort" | head -3 | sed 's/^/    /'
    fail=$((fail+1))
  fi
done

echo "[rv64dv] ==================================="
echo "[rv64dv]  结果: $pass PASS, $fail FAIL"
echo "[rv64dv] ==================================="
[ "$fail" -eq 0 ]
