#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tb_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$tb_dir/../../.." && pwd)"
output_dir="${1:-$repo_root/npc/rv64/testbench/build/int-issue-queue-packed-hole-negative}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

log="$output_dir/int-issue-queue-packed-hole-negative.log"
vvp_image="$output_dir/tb_ooo_int_issue_queue-packed-hole-negative.vvp"
source_manifest="$output_dir/source-manifest.sha256"
iverilog_bin="${IVERILOG:-iverilog}"
iverilog_path="$(command -v "$iverilog_bin")"
vvp_bin="${VVP:-$(dirname "$iverilog_path")/vvp}"
if [[ ! -x "$vvp_bin" ]]; then
  vvp_bin="$(command -v vvp)"
fi

mapfile -t sources < <(
  cd "$tb_dir"
  make --no-print-directory -s -f - print-iq-sources <<'MAKE_EOF'
include Makefile
.PHONY: print-iq-sources
print-iq-sources:
	@for source in $(sort $(TB_SRCS_tb_ooo_int_issue_queue)); do printf '%s\n' "$$source"; done
MAKE_EOF
)

if [[ "${#sources[@]}" -eq 0 ]]; then
  echo "packed-hole probe source discovery returned no files" >&2
  exit 2
fi

(
  cd "$tb_dir"
  sha256sum "${sources[@]}" \
    "$script_dir/run_int_issue_queue_packed_hole_negative.sh"
) >"$source_manifest"

set +e
(
  cd "$tb_dir"
  "$iverilog_path" -g2012 -Wall \
    -I"$repo_root/npc/rv64/vsrc" \
    -I"$repo_root/npc/rv64/vsrc/include" \
    -I"$tb_dir/common" \
    -DOOO_ASSERT -DR3P3_PACKED_HOLE_NEGATIVE \
    -s tb_ooo_int_issue_queue -o "$vvp_image" "${sources[@]}"
) >"$log" 2>&1
compile_rc=$?
if [[ "$compile_rc" -eq 0 ]]; then
  "$vvp_bin" "$vvp_image" >>"$log" 2>&1
  run_rc=$?
else
  run_rc=125
fi
set -e

target_count="$(grep -F -c '[IQ-R3P3-PACKED-AGE] valid hole before idx=1' "$log" || true)"
error_count="$(grep -E -c '^(ERROR:|%Error[-:])' "$log" || true)"
quiet_count="$(grep -F -c '[R3P3-HOLE-QUIET] outputs quiet before assertion edge' "$log" || true)"
done_count="$(grep -F -c '[R3P3-PACKED-HOLE-NEGATIVE-DONE]' "$log" || true)"
check_fail_count="$(grep -F -c '[CHECK-FAIL]' "$log" || true)"
fatal_count="$(grep -E -c '(^|[^A-Z])FATAL:' "$log" || true)"

result=PASS
if [[ "$compile_rc" -ne 0 || "$run_rc" -ne 0 ||
      "$target_count" -ne 1 || "$error_count" -ne 1 ||
      "$quiet_count" -ne 1 || "$done_count" -ne 1 ||
      "$check_fail_count" -ne 0 || "$fatal_count" -ne 0 ]]; then
  result=FAIL
fi

{
  echo "[INT-ISSUE-QUEUE-PACKED-HOLE-NEGATIVE-RESULT] $result"
  echo "compile_rc=$compile_rc run_rc=$run_rc target_count=$target_count error_count=$error_count quiet_count=$quiet_count done_count=$done_count check_fail_count=$check_fail_count fatal_count=$fatal_count"
  echo "log=$log"
} | tee "$output_dir/result.txt"

if [[ "$result" != PASS ]]; then
  tail -n 100 "$log" >&2
  exit 1
fi
