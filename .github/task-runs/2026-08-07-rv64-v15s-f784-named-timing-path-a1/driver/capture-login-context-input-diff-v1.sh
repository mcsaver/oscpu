#!/usr/bin/env bash
set -euo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_dir="${repo_root}/.github/task-runs/2026-08-07-rv64-v15s-f784-named-timing-path-a1"
output="${run_dir}/evidence/post-candidate-current-verify-replay-v2/login-context-input-diff.json"
driver="${run_dir}/driver/compare-live-functional-inputs-v1.py"

set +e
/bin/bash -lc "/usr/bin/python3 -B '${driver}'" >"${output}"
compare_rc=$?
set -e

if [[ "${compare_rc}" -ne 1 ]]; then
  printf '%s\n' "unexpected compare rc=${compare_rc}" >&2
  exit 1
fi

jq -e '
  .status == "DRIFT" and .difference_count == 1 and
  .differences[0].group == "toolchain" and
  .differences[0].key == "riscv64-unknown-elf-gcc" and
  .differences[0].frozen == null and
  .differences[0].live.path ==
    "/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf-gcc"
' "${output}" >/dev/null

printf '%s\n' \
  '[V15S-LOGIN-CONTEXT-DIFF][PASS] difference_count=1 key=riscv64-unknown-elf-gcc'
