#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../../../.." && pwd)
checker="$repo_root/npc/rv64/eval/check-rtl-style.sh"
temp_dir=$(mktemp -d /tmp/rv64-rtl-style-naming.XXXXXXXX)

cleanup() {
  case "$temp_dir" in
    /tmp/rv64-rtl-style-naming.*) rm -rf -- "$temp_dir" ;;
    *) return 1 ;;
  esac
}
trap cleanup EXIT

mkdir -p "$temp_dir/legacy" "$temp_dir/legal"
printf '%s\n' \
  'module AxiXbar;' \
  'endmodule' \
  > "$temp_dir/legacy/AxiXbar.v"
printf '%s\n' \
  'module L2XbarAdapter;' \
  'endmodule' \
  > "$temp_dir/legal/L2XbarAdapter.v"

if RTL_FILES="$temp_dir/legacy/AxiXbar.v" "$checker" \
    > "$temp_dir/legacy.log" 2>&1; then
  printf '%s\n' \
    '[RTL-STYLE-NAMING][FAIL] retired AxiXbar module was accepted' >&2
  exit 1
fi
grep -q '生产 module 使用退役命名(AxiXbar)' "$temp_dir/legacy.log"

RTL_FILES="$temp_dir/legal/L2XbarAdapter.v" "$checker" \
  > "$temp_dir/legal.log" 2>&1
grep -q '\[check-rtl-style\] PASS' "$temp_dir/legal.log"

printf '%s\n' \
  '[RTL-STYLE-NAMING][PASS] retired=AxiXbar rejected legal=L2XbarAdapter accepted'
