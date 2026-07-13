#!/usr/bin/env bash
set -euo pipefail

readonly workspace_root="${WORKSPACE_ROOT:-/home/lyg/PA/ysyx-workbench}"
readonly out_dir="${workspace_root}/tmp/2026-07-13-rv64-t3g-mem-formal-only/tmp-archive"
readonly paths0="${out_dir}/top-level-paths.nul"
readonly paths_txt="${out_dir}/top-level-paths.txt"
readonly archive="${out_dir}/t3g-related-tmp.tar.zst"
readonly archive_tmp="${archive}.tmp.$$"

cleanup() {
  rm -f -- "${archive_tmp}"
}
trap cleanup EXIT

mkdir -p -- "${out_dir}"

# 只归档本轮 T3G RED/GREEN/module/Verilator 的 /tmp 产物。
find /tmp -mindepth 1 -maxdepth 1 \
  \( -name 'ysyx-t3g*' -o -name 't3g*' \) \
  -printf '%f\0' | sort -z > "${paths0}"

if [[ ! -s "${paths0}" ]]; then
  echo "error: no T3G-related /tmp paths found" >&2
  exit 3
fi

tr '\0' '\n' < "${paths0}" > "${paths_txt}"

tar --create --file=- --directory=/tmp --null --files-from="${paths0}" \
  | zstd -T1 -10 -o "${archive_tmp}"
mv -- "${archive_tmp}" "${archive}"

zstd --test --quiet -- "${archive}"
tar --list --file="${archive}" > "${out_dir}/archive-inventory.txt"
sha256sum \
  "${archive}" \
  "${paths_txt}" \
  "${out_dir}/archive-inventory.txt" \
  > "${out_dir}/SHA256SUMS"

printf 'T3G_TMP_ARCHIVE_OK archive=%s bytes=%s entries=%s\n' \
  "${archive}" "$(stat -c '%s' -- "${archive}")" \
  "$(wc -l < "${out_dir}/archive-inventory.txt")"
