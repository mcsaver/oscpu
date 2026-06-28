#!/usr/bin/env bash
# RTL 写作规范风格检查器(可执行 gate)。
#
# 强制 .github/instructions/rtl-generation-workflow.instructions.md 中可机器检查的子集:
#   1. 可综合硬件文件必须是 .v(SystemVerilog .sv 仅用于验证,不进综合网表)。
#   2. 可综合 .v 不得使用 SV 关键字 always_comb / always_ff / logic 声明——本仓库
#      模块 testbench gate 用 Icarus iverilog 12.0,它对 always_comb 内变量常量位选
#      静默错仿真(见 known-issues.md 2026-06-29 条);可综合 RTL 统一用 Verilog-2001
#      always @(posedge clk) / always @(*) / wire+reg。
#
# 用法:
#   RTL_FILES="<空格分隔的可综合文件清单>" eval/check-rtl-style.sh
#   或在 npc/rv64 下: make check-rtl-style
# 退出码:0=全部合规;1=发现违规。
set -u

files="${RTL_FILES:-}"
if [[ -z "$files" ]]; then
  # 回退:自行从 Makefile 展开 RTL_CORE_SRCS
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  files="$(make -s -C "$here" print-synth-rtl 2>/dev/null)"
fi

violations=0
report() { echo "  [RTL-STYLE 违规] $*"; violations=$((violations+1)); }

for f in $files; do
  [[ -f "$f" ]] || continue
  case "$f" in
    *.sv)
      report ".sv 进入可综合集($f);可综合硬件必须用 .v,.sv 仅用于验证" ;;
  esac
  # 仅检查 .v 可综合文件的 SV 关键字。剥注释行后按词边界匹配。
  if [[ "$f" == *.v ]]; then
    # 去掉行注释(// ...)后扫描,避免文档注释误报。
    stripped="$(sed 's#//.*$##' "$f")"
    if grep -qE '(^|[^A-Za-z0-9_])always_comb([^A-Za-z0-9_]|$)' <<<"$stripped"; then
      report "可综合 .v 使用了 always_comb 关键字($f);改用 always @(*)"
    fi
    if grep -qE '(^|[^A-Za-z0-9_])always_ff([^A-Za-z0-9_]|$)' <<<"$stripped"; then
      report "可综合 .v 使用了 always_ff 关键字($f);改用 always @(posedge clk)"
    fi
    if grep -qE '(^|[^A-Za-z0-9_])logic([^A-Za-z0-9_]|$)' <<<"$stripped"; then
      report "可综合 .v 使用了 SV logic 类型($f);改用 wire/reg"
    fi
  fi
done

if [[ "$violations" -gt 0 ]]; then
  echo "[check-rtl-style] FAIL: $violations 处违规(见上)。规范见 .github/instructions/rtl-generation-workflow.instructions.md"
  exit 1
fi
echo "[check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字"
exit 0
