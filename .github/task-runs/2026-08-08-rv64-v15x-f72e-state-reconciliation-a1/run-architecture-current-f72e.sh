#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=/home/lyg/PA/ysyx-workbench
source_runner=${repo_root}/.github/task-runs/2026-08-07-rv64-v15w-ca37-current-reconciliation-a1/driver/run-architecture-current-ca37.sh
temporary_runner=$(mktemp /tmp/v15x-architecture-current-f72e.XXXXXX.sh)

cleanup() {
  case "${temporary_runner}" in
    /tmp/v15x-architecture-current-f72e.*.sh) rm -f -- "${temporary_runner}" ;;
  esac
}
trap cleanup EXIT

sed \
  -e 's/2026-08-07-rv64-v15w-ca37-current-reconciliation-a1/2026-08-08-rv64-v15x-f72e-state-reconciliation-a1/g' \
  -e 's/2026-08-07-rv64-v15w-arch9-ca37-a1/2026-08-08-rv64-v15x-arch9-f72e-a1/g' \
  -e 's/2026-08-07-rv64-v15w-di1-ca37-a1/2026-08-08-rv64-v15x-di1-f72e-a1/g' \
  -e 's/2026-08-07-rv64-v15w-di2-ca37-a1/2026-08-08-rv64-v15x-di2-f72e-a1/g' \
  -e 's/2026-08-07-rv64-v15w-di5-ca37-a1/2026-08-08-rv64-v15x-di5-f72e-a1/g' \
  -e 's/2026-08-07-rv64-v15w-ooo4-ca37-a1/2026-08-08-rv64-v15x-ooo4-f72e-a1/g' \
  -e 's/ARCH-CA37/ARCH-F72E/g' \
  -e 's/design=ca37/design=f72e/g' \
  "${source_runner}" >"${temporary_runner}"

bash "${temporary_runner}"
