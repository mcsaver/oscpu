#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_SLUG=2026-07-13-rv64-t3k-csr-probe-isolation
OUT_DIR="$ROOT_DIR/tmp/$TASK_SLUG/tmp-archive"
ARCHIVE="$OUT_DIR/t3k-related-tmp.tar.zst"
SOURCE_NUL="$OUT_DIR/source-list.nul"
PROTECTED_LOG=/tmp/ysyx-t3k-user-npc-linux.log
PROTECTED_SHA=3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15

die() {
  printf '[T3K-TMP-ARCHIVE] FAIL: %s\n' "$*" >&2
  exit 2
}

resolved_out=$(realpath -m -- "$OUT_DIR")
resolved_root=$(realpath -m -- "$ROOT_DIR/tmp/$TASK_SLUG")
case "$resolved_out" in
  "$resolved_root"/*) ;;
  *) die "output escapes task tmp root: $resolved_out" ;;
esac
[[ ! -e $OUT_DIR ]] || die "refusing stale output: $OUT_DIR"

mapfile -d '' -t sources < <(
  find /tmp -xdev -mindepth 1 -maxdepth 1 \
    \( -name 't3k-*' -o -name 'ysyx-t3k-*' \) -printf '%f\0' | sort -zu
)
((${#sources[@]} > 0)) || die 'no T3K-related /tmp roots found'

for name in "${sources[@]}"; do
  [[ -n $name && $name != */* && $name != . && $name != .. ]] \
    || die "unsafe source name: $name"
  [[ -e /tmp/$name || -L /tmp/$name ]] || die "source vanished: /tmp/$name"
done
[[ -f $PROTECTED_LOG && ! -L $PROTECTED_LOG ]] \
  || die 'protected log is not a regular file'
[[ $(sha256sum -- "$PROTECTED_LOG" | cut -d' ' -f1) == "$PROTECTED_SHA" ]] \
  || die 'protected log hash drifted'

mkdir -p -- "$OUT_DIR"
printf '%s\0' "${sources[@]}" >"$SOURCE_NUL"
printf '/tmp/%s\n' "${sources[@]}" >"$OUT_DIR/source-list.txt"

write_inventory() {
  local output=$1 name path rel
  printf 'type\tlogical_bytes\tsha256_or_target\tpath\n' >"$output"
  for name in "${sources[@]}"; do
    while IFS= read -r -d '' path; do
      rel=${path#/tmp/}
      if [[ -L $path ]]; then
        printf 'l\t%s\t%s\t/tmp/%s\n' \
          "$(readlink -- "$path" | wc -c)" "$(readlink -- "$path")" "$rel" >>"$output"
      elif [[ -f $path ]]; then
        printf 'f\t%s\t%s\t/tmp/%s\n' \
          "$(stat -c '%s' -- "$path")" \
          "$(sha256sum -- "$path" | cut -d' ' -f1)" "$rel" >>"$output"
      elif [[ -d $path ]]; then
        printf 'd\t0\t-\t/tmp/%s\n' "$rel" >>"$output"
      else
        die "unsupported source type: $path"
      fi
    done < <(find "/tmp/$name" -xdev -print0 | sort -z)
  done
}

write_inventory "$OUT_DIR/source-inventory.pre.tsv"
tar -C /tmp --one-file-system --null -T "$SOURCE_NUL" -cf - \
  | zstd -T1 -10 -o "$ARCHIVE"
zstd --test --quiet -- "$ARCHIVE"
zstd -dc -- "$ARCHIVE" | tar -tf - >"$OUT_DIR/archive-contents.txt"
write_inventory "$OUT_DIR/source-inventory.post.tsv"
cmp -s "$OUT_DIR/source-inventory.pre.tsv" "$OUT_DIR/source-inventory.post.tsv" \
  || die 'source changed while archiving'
zstd -dc -- "$ARCHIVE" | tar -C /tmp --compare -f - >/dev/null \
  || die 'archive differs from retained /tmp sources'
sha256sum -- "$ARCHIVE" >"$OUT_DIR/SHA256SUMS"

entries=$(awk 'NR > 1 { n++ } END { print n + 0 }' "$OUT_DIR/source-inventory.pre.tsv")
bytes=$(awk -F '\t' 'NR > 1 { n += $2 } END { printf "%.0f", n + 0 }' \
  "$OUT_DIR/source-inventory.pre.tsv")
{
  printf 'task_slug=%s\n' "$TASK_SLUG"
  printf 'selection=/tmp/{t3k-*,ysyx-t3k-*}\n'
  printf 'source_roots=%s\n' "${#sources[@]}"
  printf 'inventory_entries=%s\n' "$entries"
  printf 'logical_bytes=%s\n' "$bytes"
  printf 'sources_retained=true\n'
  printf 'archive_sha256=%s\n' "$(sha256sum -- "$ARCHIVE" | cut -d' ' -f1)"
} >"$OUT_DIR/archive-provenance.txt"

printf '[T3K-TMP-ARCHIVE] PASS: roots=%s entries=%s bytes=%s archive=%s\n' \
  "${#sources[@]}" "$entries" "$bytes" "$ARCHIVE"
