#!/usr/bin/env bash
set -euo pipefail

readonly root=/home/lyg/PA/ysyx-workbench
readonly bundle_root="${root}/tmp/2026-07-13-rv64-ifu-access-g1"
readonly result_dir="${bundle_root}/sta-build/NpcTop-200MHz"
readonly archive="${bundle_root}/NpcTop-200MHz-fresh.tar.zst"
readonly archive_tmp="${archive}.tmp.$$"
readonly inventory="${bundle_root}/NpcTop-200MHz-fresh.inventory.tsv"
readonly checksum="${bundle_root}/SHA256SUMS"
readonly opensta_summary="${root}/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-summary.txt"

cleanup() {
  rm -f -- "${archive_tmp}"
}
trap cleanup EXIT

for required in \
  "${result_dir}/NpcTop.netlist.v" \
  "${result_dir}/yosys.log" \
  "${result_dir}/synth_check.txt" \
  "${bundle_root}/sta-provenance.md" \
  "${opensta_summary}"; do
  if [[ ! -s "${required}" ]]; then
    echo "error: missing or empty required artifact: ${required}" >&2
    exit 3
  fi
done

rg -q '^End of script\.' "${result_dir}/yosys.log"
rg -q 'Found and reported 0 problems\.' "${result_dir}/synth_check.txt"
rg -q '^status=PASS$' "${opensta_summary}"

{
  printf 'bytes\tsha256\tpath\n'
  find "${result_dir}" -maxdepth 1 -type f -print0 \
    | sort -z \
    | while IFS= read -r -d '' path; do
        printf '%s\t' "$(stat -c '%s' -- "${path}")"
        sha256sum -- "${path}" | awk '{printf "%s\t", $1}'
        printf '%s\n' "${path#${root}/}"
      done
  printf '%s\t' "$(stat -c '%s' -- "${bundle_root}/sta-provenance.md")"
  sha256sum -- "${bundle_root}/sta-provenance.md" | awk '{printf "%s\t", $1}'
  printf '%s\n' "tmp/2026-07-13-rv64-ifu-access-g1/sta-provenance.md"
} > "${inventory}"

rm -f -- "${archive_tmp}"
nice -n 10 tar \
  --create \
  --file="${archive_tmp}" \
  --directory="${bundle_root}" \
  --use-compress-program='zstd -T0 -10' \
  sta-build/NpcTop-200MHz \
  sta-provenance.md
mv -- "${archive_tmp}" "${archive}"

zstd --test --quiet -- "${archive}"
tar --list --file="${archive}" >/dev/null

(
  cd "${bundle_root}"
  sha256sum \
    "$(basename "${archive}")" \
    "$(basename "${inventory}")" \
    sta-provenance.md \
    > "$(basename "${checksum}")"
)

printf 'FRESH_STA_ARCHIVE_OK archive=%s bytes=%s\n' \
  "${archive}" "$(stat -c '%s' -- "${archive}")"
