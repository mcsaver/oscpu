#!/usr/bin/env bash

# Destructive recovery entry.  It is intentionally separate from --plan so
# the exact process/artifact/delete set can be reviewed before one apply.

set -uo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
run_id=2026-08-10-rv64-fp-arith-children-ppa-9d8b-a1
script="${repo_root}/.github/task-runs/${run_id}/host-timeout-recovery-v1.py"

if [[ "$#" -ne 1 || "$1" != "--apply" ]]; then
  printf '%s\n' 'usage: host-timeout-recovery-v1.sh --apply' >&2
  exit 2
fi
if [[ "$(pwd -P)" != "${repo_root}" || -L "${script}" || ! -s "${script}" ]]; then
  printf '%s\n' '[HOST-TIMEOUT-RECOVERY][FAIL] non-canonical repo/script' >&2
  exit 2
fi

exec python3 -B "${script}" --apply
