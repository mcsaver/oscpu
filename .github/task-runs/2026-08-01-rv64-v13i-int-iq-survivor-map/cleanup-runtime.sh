#!/usr/bin/env bash
set -euo pipefail

readonly expected_target="/home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13i-int-iq-survivor-map"
resolved_target="$(realpath -- "${expected_target}")"
if [[ "${resolved_target}" != "${expected_target}" ]]; then
  printf 'CLEANUP_FAIL resolved=%s expected=%s\n' "${resolved_target}" "${expected_target}" >&2
  exit 2
fi

file_count="$(find "${expected_target}" -type f | wc -l)"
byte_count="$(du -sb "${expected_target}" | cut -f1)"
rm -rf -- /home/lyg/PA/ysyx-workbench/.github/runtime-artifacts/rv64-v13i-int-iq-survivor-map

if [[ -e "${expected_target}" ]]; then
  printf 'CLEANUP_FAIL target_still_exists=%s\n' "${expected_target}" >&2
  exit 3
fi

printf 'CLEANUP_PASS target=%s files=%s bytes=%s\n' "${expected_target}" "${file_count}" "${byte_count}"
