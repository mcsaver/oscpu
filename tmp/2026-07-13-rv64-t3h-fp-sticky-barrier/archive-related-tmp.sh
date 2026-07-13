#!/usr/bin/env bash
set -euo pipefail

readonly workspace_root="${WORKSPACE_ROOT:-/home/lyg/PA/ysyx-workbench}"
readonly out_root="${workspace_root}/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/tmp-archive"

archive_group() {
  local label="$1"
  shift
  local out_dir="${out_root}/${label}"
  local paths0="${out_dir}/top-level-paths.nul"
  local paths_txt="${out_dir}/top-level-paths.txt"
  local inventory="${out_dir}/archive-inventory.txt"
  local archive="${out_dir}/${label}-related-tmp.tar.zst"
  local archive_tmp="${archive}.tmp.$$"

  mkdir -p -- "${out_dir}"
  find /tmp -xdev -mindepth 1 -maxdepth 1 "$@" -printf '%f\0' \
    | sort -z > "${paths0}"
  if [[ ! -s "${paths0}" ]]; then
    printf 'error: no /tmp paths found for %s\n' "${label}" >&2
    return 3
  fi
  tr '\0' '\n' < "${paths0}" > "${paths_txt}"

  trap 'rm -f -- "${archive_tmp}"' RETURN
  tar --create --file=- --directory=/tmp --null --files-from="${paths0}" \
    | zstd -T1 -10 -o "${archive_tmp}"
  mv -- "${archive_tmp}" "${archive}"
  trap - RETURN

  zstd --test --quiet -- "${archive}"
  tar --list --file="${archive}" > "${inventory}"
  sha256sum "${archive}" "${paths0}" "${paths_txt}" "${inventory}" \
    > "${out_dir}/SHA256SUMS"
  sha256sum -c "${out_dir}/SHA256SUMS" >/dev/null
  printf '%s\t%s\t%s\t%s\n' "${label}" \
    "$(wc -l < "${paths_txt}")" \
    "$(wc -l < "${inventory}")" \
    "$(stat -c '%s' -- "${archive}")"
}

mkdir -p -- "${out_root}"
printf 'group\ttop_level_paths\ttar_entries\tarchive_bytes\n' \
  > "${out_root}/archive-summary.tsv"

for stage in b c d e f g h; do
  archive_group "t3${stage}" \
    \( -iname "ysyx-t3${stage}*" \
       -o -iname "t3${stage}*" \
       -o -iname "rv64-t3${stage}*" \
       -o -iname "2026-07-13-rv64-t3${stage}*" \) \
    | tee -a "${out_root}/archive-summary.tsv"
done

archive_group "t3-baseline" \( -name 'OooIntBackend-A.v' \) \
  | tee -a "${out_root}/archive-summary.tsv"

test -f "${workspace_root}/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/tmp-archive-provenance.md"
{
  find "${out_root}" -mindepth 2 -maxdepth 2 -type f \
    \( -name '*.tar.zst' -o -name 'top-level-paths.nul' \
       -o -name 'top-level-paths.txt' -o -name 'archive-inventory.txt' \
       -o -name 'SHA256SUMS' \) -print0
  printf '%s\0' \
    "${out_root}/archive-summary.tsv" \
    "${workspace_root}/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/archive-related-tmp.sh" \
    "${workspace_root}/tmp/2026-07-13-rv64-t3h-fp-sticky-barrier/tmp-archive-provenance.md"
} | sort -z | xargs -0 sha256sum > "${out_root}/SHA256SUMS"
sha256sum -c "${out_root}/SHA256SUMS" >/dev/null
printf 'T3B_H_TMP_ARCHIVE_OK groups=8\n'
