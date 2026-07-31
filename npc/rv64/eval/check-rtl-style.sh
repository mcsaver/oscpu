#!/usr/bin/env bash
# RTL 写作规范风格检查器(可执行 gate)。
#
# 强制 .github/instructions/rtl-generation-workflow.instructions.md 中可机器检查的子集:
#   1. 可综合硬件文件必须是 .v(SystemVerilog .sv 仅用于验证,不进综合网表)。
#   2. 可综合 .v 不得使用 SV 关键字 always_comb / always_ff / logic 声明——本仓库
#      模块 testbench gate 用 Icarus iverilog 12.0,它对 always_comb 内变量常量位选
#      静默错仿真(见 known-issues.md 2026-06-29 条);可综合 RTL 统一用 Verilog-2001
#      always @(posedge clk) / always @(*) / wire+reg。
#   3. 每个可综合主 module 的文件名必须与 module 名一致，并拒绝已经退役的
#      精确 module 标识 AxiXbar；其它合法 crossbar module 与 AXI4-Lite、
#      CLINT/PLIC/UART/DPI 等协议标准名不在此列。
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

    module_names="$(sed -nE \
      's/^[[:space:]]*module[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/p' \
      "$f")"
    module_count="$(grep -c . <<<"$module_names")"
    if [[ "$module_count" -gt 1 ]]; then
      report "可综合源文件包含多个 module($f);保持一个 module 一个源文件"
    elif [[ "$module_count" -eq 1 ]]; then
      module_name="$module_names"
      file_module_name="$(basename "$f" .v)"
      if [[ "$module_name" != "$file_module_name" ]]; then
        report "文件名与主 module 不一致($f: module $module_name)"
      fi
      if [[ "$module_name" == "AxiXbar" ]]; then
        report "生产 module 使用退役命名($module_name);使用当前 AXI4 全称"
      fi
    fi
  fi
done

if [[ "$violations" -gt 0 ]]; then
  echo "[check-rtl-style] FAIL: $violations 处违规(见上)。规范见 .github/instructions/rtl-generation-workflow.instructions.md"
  exit 1
fi
echo "[check-rtl-style] PASS: 可综合 RTL 扩展名、Verilog-2001 关键字和 module 命名均合规"
exit 0
