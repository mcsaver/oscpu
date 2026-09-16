#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tb_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$tb_dir/../../.." && pwd)"
output_dir="${1:-$repo_root/npc/rv64/testbench/build/int-alu-terminal-capability-negative}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

log="$output_dir/int-alu-terminal-capability-negative.log"
vvp_image="$output_dir/tb_ooo_int_backend-alu-terminal-negative.vvp"
source_manifest="$output_dir/source-manifest.sha256"
iverilog_bin="${IVERILOG:-iverilog}"
iverilog_path="$(command -v "$iverilog_bin")"
vvp_bin="${VVP:-$(dirname "$iverilog_path")/vvp}"
if [[ ! -x "$vvp_bin" ]]; then
  vvp_bin="$(command -v vvp)"
fi

mapfile -t sources < <(
  cd "$tb_dir"
  make --no-print-directory -s -f - print-int-backend-sources <<'MAKE_EOF'
include Makefile
.PHONY: print-int-backend-sources
print-int-backend-sources:
	@for source in $(sort $(TB_SRCS_tb_ooo_int_backend)); do printf '%s\n' "$$source"; done
MAKE_EOF
)

if [[ "${#sources[@]}" -eq 0 ]]; then
  echo "negative probe source discovery returned no files" >&2
  exit 2
fi

(
  cd "$tb_dir"
  sha256sum "${sources[@]}" \
    "$script_dir/run_int_alu_terminal_capability_negative.sh"
) >"$source_manifest"

set +e
(
  cd "$tb_dir"
  "$iverilog_path" -g2012 -Wall \
    -I"$repo_root/npc/rv64/vsrc" \
    -I"$repo_root/npc/rv64/vsrc/include" \
    -I"$tb_dir/common" \
    -DOOO_ASSERT -DINT_ALU_TERMINAL_CAPABILITY_NEGATIVE \
    -s tb_ooo_int_backend -o "$vvp_image" "${sources[@]}"
) >"$log" 2>&1
compile_rc=$?
if [[ "$compile_rc" -eq 0 ]]; then
  "$vvp_bin" "$vvp_image" >>"$log" 2>&1
  run_rc=$?
else
  run_rc=125
fi
set -e

target_count="$(grep -F -c '[INT-ALU-TERMINAL-CAPABILITY] ALU terminal selected non-simple uop' "$log" || true)"
iq_target_count="$(grep -F -c '[IQ-ALU-TERMINAL-CAPABILITY] issue1 selected non-simple uop' "$log" || true)"
error_count="$(grep -E -c '^(ERROR:|%Error[-:])' "$log" || true)"
bitmanip_count="$(grep -F -c '[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-BITMANIP]' "$log" || true)"
wbsel_count="$(grep -F -c '[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-WBSEL]' "$log" || true)"
done_count="$(grep -F -c '[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-DONE]' "$log" || true)"
fatal_count="$(grep -E -c '(^|[^A-Z])FATAL:' "$log" || true)"

result=PASS
if [[ "$compile_rc" -ne 0 || "$run_rc" -ne 0 ||
      "$target_count" -ne 2 || "$iq_target_count" -ne 2 ||
      "$error_count" -ne 4 ||
      "$bitmanip_count" -ne 1 || "$wbsel_count" -ne 1 ||
      "$done_count" -ne 1 || "$fatal_count" -ne 0 ]]; then
  result=FAIL
fi

{
  echo "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-RESULT] $result"
  echo "compile_rc=$compile_rc run_rc=$run_rc target_count=$target_count iq_target_count=$iq_target_count error_count=$error_count bitmanip_count=$bitmanip_count wbsel_count=$wbsel_count done_count=$done_count fatal_count=$fatal_count"
  echo "log=$log"
} | tee "$output_dir/result.txt"

if [[ "$result" != PASS ]]; then
  tail -n 100 "$log" >&2
  exit 1
fi
