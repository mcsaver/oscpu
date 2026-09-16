#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --expect-red|--expect-green [--output-dir DIR] [--bridge-ref REF]" >&2
}

mode=""
output_dir=""
bridge_ref=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --expect-red)
      mode="red"
      shift
      ;;
    --expect-green)
      mode="green"
      shift
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      output_dir="$2"
      shift 2
      ;;
    --bridge-ref)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      bridge_ref="$2"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n "$mode" ]] || { usage; exit 2; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../../.." && pwd)"
if [[ -z "$output_dir" ]]; then
  output_dir="$repo_root/npc/rv64/testbench/build/ifu-access-footprint-run"
fi
mkdir -p "$output_dir"

# 使用仓库固定的同源 iverilog/vvp，避免 14.0 编译物被 12.0 runtime 拒跑。
source "$repo_root/scripts/agent-env.sh"
iverilog_bin="${IVERILOG:-iverilog}"
vvp_bin="${VVP:-$(dirname "$(command -v "$iverilog_bin")")/vvp}"
compile_log="$output_dir/compile.log"
sim_log="$output_dir/sim.log"
vvp_file="$output_dir/tb_ooo_fetch_access_footprint.vvp"
bridge_path="npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"

compile_cmd=("$iverilog_bin" -g2012 -Wall \
  -I"$repo_root/npc/rv64/vsrc" \
  -I"$repo_root/npc/rv64/vsrc/include" \
  -I"$repo_root/npc/rv64/testbench/common" \
  -DOOO_ASSERT \
  -s tb_ooo_fetch_access_footprint \
  -o "$vvp_file" \
  "$repo_root/npc/rv64/testbench/tests/tb_ooo_fetch_access_footprint.sv" \
  "$repo_root/npc/rv64/vsrc/memory/PmpChecker.v" \
  "$repo_root/npc/rv64/vsrc/decode/OooRvcDecompressor.v" \
  "$repo_root/npc/rv64/vsrc/frontend/OooFetchPacketDecode.v" \
  "$repo_root/npc/rv64/vsrc/cache/OooFetchPacketCache.v" \
  "$repo_root/npc/rv64/vsrc/sram/Sram4096x199.v" \
  "$repo_root/npc/rv64/vsrc/memory/OooSv39Tlb.v")

if [[ -n "$bridge_ref" ]]; then
  # 用 stdin 编译历史 bridge，避免 checkout/覆盖共享工作树；其余依赖沿用当前
  # 兼容接口。该入口专用于永久 RED 的可复现 A/B，不写 production source。
  git -C "$repo_root" show "${bridge_ref}:${bridge_path}" | \
    "${compile_cmd[@]}" /dev/stdin >"$compile_log" 2>&1
else
  "${compile_cmd[@]}" "$repo_root/$bridge_path" >"$compile_log" 2>&1
fi

set +e
"$vvp_bin" "$vvp_file" >"$sim_log" 2>&1
sim_rc=$?
set -e

require_line() {
  local expected="$1"
  if ! grep -Fqx "$expected" "$sim_log"; then
    echo "missing exact marker: $expected" >&2
    exit 1
  fi
}

if [[ "$mode" == "red" ]]; then
  [[ "$sim_rc" -ne 0 ]] || {
    echo "old-RTL RED expected nonzero simulation rc" >&2
    exit 1
  }
  require_line "[ACCESS-G1-SUMMARY] footprint rows=4 fail=4"
  require_line "[ACCESS-G1-SUMMARY] poison rows=4 fail=0"
  require_line "[ACCESS-G1-SUMMARY] rresp rows=12 fail=12"
  require_line "[ACCESS-G1-SUMMARY] walk rows=12 fail=12"
  require_line "[ACCESS-G1-SUMMARY] pmp rows=6 fail=6"
  require_line "[FAIL] tb_ooo_fetch_access_footprint errors=34"
  [[ "$(grep -c '^\[CHECK-FAIL\]' "$sim_log")" -eq 34 ]] || {
    echo "old-RTL RED expected exactly 34 CHECK-FAIL rows" >&2
    exit 1
  }
  [[ "$(grep -c '^\[ACCESS-G1-POISON-PASS\]' "$sim_log")" -eq 4 ]] || exit 1
  [[ "$(grep -c '^\[ACCESS-G1-RRESP-DECODE-CONTROL-PASS\]' "$sim_log")" -eq 4 ]] || exit 1
  [[ "$(grep -c '^\[ACCESS-G1-WALK-PRESENCE-CONTROL-PASS\]' "$sim_log")" -eq 8 ]] || exit 1
  [[ -n "$bridge_ref" ]] || {
    echo "--expect-red requires --bridge-ref so current GREEN RTL is not mistaken for old RED" >&2
    exit 1
  }
  echo "[EXPECTED-RED-PASS] ref=$bridge_ref compile=0 sim=$sim_rc errors=34 footprint=4 poison=0 rresp=12 walk=12 pmp=6 controls=4+4+8"
else
  [[ "$sim_rc" -eq 0 ]] || {
    echo "green run failed with simulation rc=$sim_rc" >&2
    exit 1
  }
  require_line "[ACCESS-G1-SUMMARY] footprint rows=4 fail=0"
  require_line "[ACCESS-G1-SUMMARY] poison rows=4 fail=0"
  require_line "[ACCESS-G1-SUMMARY] rresp rows=12 fail=0"
  require_line "[ACCESS-G1-SUMMARY] walk rows=12 fail=0"
  require_line "[ACCESS-G1-SUMMARY] pmp rows=6 fail=0"
  require_line "[PASS] tb_ooo_fetch_access_footprint"
  [[ "$(grep -c '^\[ACCESS-G1-PMP-PASS\]' "$sim_log")" -eq 6 ]] || exit 1
  echo "[GREEN-PASS] compile=0 sim=0 footprint=4 poison=4 rresp=12 walk=12 pmp=6"
fi

echo "compile_log=$compile_log"
echo "sim_log=$sim_log"
