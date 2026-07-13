#!/usr/bin/env bash
set -euo pipefail

readonly workspace_root="${WORKSPACE_ROOT:-/home/lyg/PA/ysyx-workbench}"
readonly task_dir="tmp/2026-07-13-rv64-t3g-mem-formal-only"
readonly build_dir="${task_dir}/sta-build/NpcTop-200MHz"
readonly archive_rel="${task_dir}/NpcTop-200MHz-t3g-mem-formal-only.tar.zst"
readonly inventory_rel="${task_dir}/NpcTop-200MHz-t3g-mem-formal-only.inventory.tsv"
readonly archive_tmp="${workspace_root}/${archive_rel}.tmp.$$"

cleanup() {
  rm -f -- "${archive_tmp}"
}
trap cleanup EXIT

cd -- "${workspace_root}"

files=(
  "${build_dir}/NpcTop.netlist.v"
  "${build_dir}/NpcTop.netlist.v.sim"
  "${build_dir}/abc.sdc"
  "${build_dir}/synth_check.txt"
  "${build_dir}/synth_stat.txt"
  "${build_dir}/yosys.log"
  "${task_dir}/sta-provenance.md"
)

for path in "${files[@]}"; do
  test -f "${path}"
done

{
  printf 'bytes\tsha256\tpath\n'
  for path in "${files[@]}"; do
    printf '%s\t%s\t%s\n' \
      "$(stat -c '%s' -- "${path}")" \
      "$(sha256sum -- "${path}" | cut -d' ' -f1)" \
      "${path}"
  done
} > "${inventory_rel}"

tar --create --file=- -- "${files[@]}" | zstd -T1 -10 -o "${archive_tmp}"
mv -- "${archive_tmp}" "${archive_rel}"

zstd --test --quiet -- "${archive_rel}"
tar --list --file="${archive_rel}" >/dev/null
sha256sum \
  "${archive_rel}" \
  "${inventory_rel}" \
  "${task_dir}/sta-provenance.md" \
  > "${task_dir}/SHA256SUMS"
sha256sum -c "${task_dir}/SHA256SUMS"

printf 'T3G_STA_ARCHIVE_OK archive=%s bytes=%s\n' \
  "${archive_rel}" "$(stat -c '%s' -- "${archive_rel}")"
