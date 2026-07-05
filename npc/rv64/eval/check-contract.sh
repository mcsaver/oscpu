#!/usr/bin/env bash
# 契约立即断言 gate（architecture-first 的可执行牙齿）。
#
# 强制 .github/instructions/interface-contract-first.instructions.md 的机器可检子集，
# 专打"断言看着像覆盖、其实没被编译进去 / 被悄悄删"的模板死法：
#   1. 全核 sim 的 VERILATOR_FLAGS 含 --assert（SV assert 关键字才会 elaborate；
#      过程式 $error/$fatal 虽不依赖它，但保持一致并为未来 SV 断言解锁）。
#   2. 全核 sim 含 +define+OOO_ASSERT（否则 `ifdef OOO_ASSERT 立即断言全被剔除，
#      "断言看着像覆盖其实没编译进去"——治真空的第一刀）。
#   3. rv64 可综合 .v 里的契约立即断言（$error）计数不回退（防断言被悄悄删；
#      合法重构导致下降时，显式更新 eval/contract-assert-baseline.txt）。
#
# 用法：make -C npc/rv64 check-contract   （或直接 eval/check-contract.sh）
# 退出码：0=通过，1=违规。
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MK="$here/Makefile"
BASE_F="$here/eval/contract-assert-baseline.txt"
violations=0
report() { echo "  [CONTRACT-GATE 违规] $*"; violations=$((violations + 1)); }

# 1. --assert 存在且 --noassert 已移除（--assert 在 VERILATOR_FLAGS 续行，不要求与它同行）
if grep -q -- '--assert' "$MK" && ! grep -q -- '--noassert' "$MK"; then :; else
  report "Makefile 缺 --assert 或仍残留 --noassert（SV assert 关键字会被静默吞掉）"
fi

# 2. +define+OOO_ASSERT 存在
grep -qE '\+define\+OOO_ASSERT' "$MK" \
  || report "Makefile 缺 +define+OOO_ASSERT（立即断言不会编入全核 sim 回归，等于没护栏）"

# 3. 立即断言计数不回退
files="$(make -s -C "$here" print-synth-rtl 2>/dev/null | tr ' ' '\n' | sort -u || true)"
cur=0
for f in $files; do
  [[ -f "$f" ]] || continue
  n=$(grep -cE '\$error[[:space:]]*\(' "$f" 2>/dev/null || true)
  cur=$((cur + ${n:-0}))
done
base=0
[[ -f "$BASE_F" ]] && base=$(tr -dc '0-9' < "$BASE_F")
: "${base:=0}"
echo "  契约立即断言（\$error）计数：当前=$cur 基线=$base"
if ((cur < base)); then
  report "立即断言计数回退：$cur < 基线 $base（契约断言被删？若确为合法重构，更新 $BASE_F）"
fi

if ((violations == 0)); then
  echo "check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 ${cur}≥${base} ✓）"
  exit 0
else
  echo "check-contract: FAIL（${violations} 处违规）"
  exit 1
fi
