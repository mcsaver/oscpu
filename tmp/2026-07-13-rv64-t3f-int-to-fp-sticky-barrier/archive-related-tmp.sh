#!/usr/bin/env bash
set -euo pipefail

readonly workspace_root="${WORKSPACE_ROOT:-/home/lyg/PA/ysyx-workbench}"
readonly out_dir="${workspace_root}/tmp/2026-07-13-rv64-t3f-int-to-fp-sticky-barrier/tmp-archive"
readonly paths0="${out_dir}/top-level-paths.nul"
readonly paths_txt="${out_dir}/top-level-paths.txt"
readonly archive="${out_dir}/t3b-t3f-related-tmp.tar.zst"
readonly archive_tmp="${archive}.tmp.$$"

cleanup() {
  rm -f -- "${archive_tmp}"
}
trap cleanup EXIT

mkdir -p -- "${out_dir}"

# 只归档本轮 200 MHz T3B–T3F 调试产物，不把无关 F0/旧任务一并复制。
find /tmp -mindepth 1 -maxdepth 1 \
  \( -name 'ysyx-t3b*' -o -name 't3b*' \
     -o -name 'ysyx-t3c*' \
     -o -name 'ysyx-t3d*' -o -name 't3d*' \
     -o -name 'ysyx-t3e*' -o -name 't3e*' \
     -o -name 'ysyx-t3f*' -o -name 't3f*' \) \
  -printf '%f\0' | sort -z > "${paths0}"

if [[ ! -s "${paths0}" ]]; then
  echo "error: no related /tmp paths found" >&2
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

printf 'T3B_T3F_TMP_ARCHIVE_OK archive=%s bytes=%s entries=%s\n' \
  "${archive}" "$(stat -c '%s' -- "${archive}")" \
  "$(wc -l < "${out_dir}/archive-inventory.txt")"
