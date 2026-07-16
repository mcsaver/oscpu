#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tb_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$tb_dir/../../.." && pwd)"
output_dir="${1:-$repo_root/npc/rv64/testbench/build/int-dispatch-packet-packed-negative}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

log="$output_dir/int-dispatch-packet-packed-negative.log"
vvp_image="$output_dir/tb_ooo_int_backend-packed-negative.vvp"
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
  sha256sum "${sources[@]}" "$script_dir/run_int_dispatch_packet_packed_assert_negative.sh"
) >"$source_manifest"

{
  printf '[INT-DISPATCH-PACKET-PACKED NEGATIVE PROBE]\n'
  printf '[CONFIG] OOO_ASSERT=1 INT_DISPATCH_PACKET_PACKED_NEGATIVE=1 source_count=%s\n' \
    "${#sources[@]}"
  printf '[COMPILE] %s -g2012 -Wall -DOOO_ASSERT -DINT_DISPATCH_PACKET_PACKED_NEGATIVE -s tb_ooo_int_backend -o %s <manifest:%s>\n' \
    "$iverilog_path" "$vvp_image" "$source_manifest"
} >"$log"

set +e
(
  cd "$tb_dir"
  "$iverilog_path" -g2012 -Wall \
    -I"$repo_root/npc/rv64/vsrc" \
    -I"$repo_root/npc/rv64/vsrc/include" \
    -I"$tb_dir/common" \
    -DOOO_ASSERT -DINT_DISPATCH_PACKET_PACKED_NEGATIVE \
    -s tb_ooo_int_backend -o "$vvp_image" "${sources[@]}"
) >>"$log" 2>&1
compile_rc=$?
printf '[COMPILE_RC] %s\n' "$compile_rc" >>"$log"
if [[ "$compile_rc" -eq 0 ]]; then
  printf '[RUN] %s %s\n' "$vvp_bin" "$vvp_image" >>"$log"
  "$vvp_bin" "$vvp_image" >>"$log" 2>&1
  run_rc=$?
else
  run_rc=125
fi
printf '[RUN_RC] %s\n' "$run_rc" >>"$log"
set -e

target_count="$(grep -F -c '[INT-DISPATCH-PACKET-PACKED] lane1 valid without lane0' "$log" || true)"
error_count="$(grep -E -c '^(ERROR:|%Error[-:])' "$log" || true)"
setup_count="$(grep -F -c '[INT-DISPATCH-PACKET-PACKED-NEGATIVE] presenting valid={0,1} fire={0,0}' "$log" || true)"
done_count="$(grep -F -c '[INT-DISPATCH-PACKET-PACKED-NEGATIVE-DONE] completed one assertion edge' "$log" || true)"
check_fail_count="$(grep -F -c '[CHECK-FAIL]' "$log" || true)"

result=PASS
if [[ "$compile_rc" -ne 0 || "$run_rc" -ne 0 ||
      "$target_count" -ne 1 || "$error_count" -ne 1 ||
      "$setup_count" -ne 1 || "$done_count" -ne 1 ||
      "$check_fail_count" -ne 0 ]]; then
  result=FAIL
fi

{
  printf '[INT-DISPATCH-PACKET-PACKED-NEGATIVE-RESULT] %s\n' "$result"
  printf 'compile_rc=%s run_rc=%s target_count=%s error_count=%s setup_count=%s done_count=%s check_fail_count=%s\n' \
    "$compile_rc" "$run_rc" "$target_count" "$error_count" \
    "$setup_count" "$done_count" "$check_fail_count"
  printf 'log=%s\n' "$log"
} | tee "$output_dir/result.txt"

if [[ "$result" != PASS ]]; then
  tail -n 80 "$log" >&2
  exit 1
fi
