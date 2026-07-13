#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_SLUG=2026-07-13-rv64-t3i-drain-retire-redundancy
readonly TASK_TMP="$ROOT_DIR/tmp/$TASK_SLUG"
readonly OUT_DIR="$TASK_TMP/tmp-archive"
readonly SOURCE_NUL="$OUT_DIR/source-list.pre.nul"
readonly SOURCE_TXT="$OUT_DIR/source-list.pre.txt"
readonly SOURCE_POST_NUL="$OUT_DIR/source-list.post.nul"
readonly SOURCE_POST_TXT="$OUT_DIR/source-list.post.txt"
readonly INVENTORY_PRE="$OUT_DIR/source-inventory.pre.tsv"
readonly INVENTORY_POST="$OUT_DIR/source-inventory.post.tsv"
readonly ARCHIVE="$OUT_DIR/t3i-related-tmp.tar.zst"
readonly CONTENTS="$OUT_DIR/archive-contents.txt"
readonly ARCHIVE_ROOTS="$OUT_DIR/archive-top-level-paths.txt"
readonly PROVENANCE="$OUT_DIR/archive-provenance.txt"
readonly SUMS="$OUT_DIR/SHA256SUMS"
readonly PROTECTED_LOG=/tmp/ysyx-t3i-user-npc-linux.log
readonly PROTECTED_LOG_SHA256=3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15

usage() {
  cat <<'EOF'
Usage: archive-related-tmp.sh [--dry-run]

Archive every and only the current top-level /tmp/t3i-* and
/tmp/ysyx-t3i-* path into the workspace T3I tmp-archive directory.
Symlinks are archived as symlinks, nested filesystems are not crossed, source
paths are never removed, and a changing source snapshot fails closed.

--dry-run validates selection, path constraints, source types, and the
protected-log hash without creating or changing any file.
EOF
}

die() {
  printf '[T3I-TMP-ARCHIVE] FAIL: %s\n' "$*" >&2
  exit 2
}

assert_output_path() {
  local path=$1
  local resolved_path resolved_root
  resolved_path=$(realpath -m -- "$path")
  resolved_root=$(realpath -m -- "$TASK_TMP")
  case "$resolved_path" in
    "$resolved_root"/*) ;;
    *) die "output path escapes task tmp root: $path" ;;
  esac
}

discover_sources() {
  find /tmp -xdev -mindepth 1 -maxdepth 1 \
    \( -name 't3i-*' -o -name 'ysyx-t3i-*' \) \
    -printf '%f\0' | sort -z
}

validate_source_name() {
  local name=$1
  [[ -n $name && $name != */* && $name != '.' && $name != '..' ]] \
    || die "unsafe top-level /tmp source name: $name"
  case "$name" in
    t3i-*|ysyx-t3i-*) ;;
    *) die "source does not match the exact T3I selection: $name" ;;
  esac
  case "$name" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "control character in source name" ;;
  esac
  [[ -e /tmp/$name || -L /tmp/$name ]] \
    || die "selected source disappeared: /tmp/$name"
}

validate_protected_log() {
  local actual
  if [[ -e $PROTECTED_LOG || -L $PROTECTED_LOG ]]; then
    [[ -f $PROTECTED_LOG && ! -L $PROTECTED_LOG ]] \
      || die "protected log is not a regular non-symlink file"
    actual=$(sha256sum "$PROTECTED_LOG" | cut -d' ' -f1)
    [[ $actual == "$PROTECTED_LOG_SHA256" ]] \
      || die "protected log hash mismatch: $actual"
  fi
}

validate_tree_types() {
  local name path
  for name in "$@"; do
    validate_source_name "$name"
    while IFS= read -r -d '' path; do
      case "$path" in
        *$'\n'*|*$'\r'*|*$'\t'*) die "control character in source path" ;;
      esac
      if [[ -L $path || -f $path || -d $path ]]; then
        :
      else
        die "unsupported source type (only file/dir/symlink allowed): $path"
      fi
    done < <(find "/tmp/$name" -xdev -print0 | sort -z)
  done
}

write_inventory() {
  local output=$1
  shift
  local name path target target_sha

  printf 'type\tbytes\tsha256_or_link_sha256\tpath_or_link\n' >"$output"
  for name in "$@"; do
    while IFS= read -r -d '' path; do
      if [[ -L $path ]]; then
        target=$(readlink -- "$path")
        target_sha=$(printf '%s' "$target" | sha256sum | cut -d' ' -f1)
        printf 'l\t%s\t%s\t%s -> %s\n' \
          "$(stat -c '%s' -- "$path")" "$target_sha" "$path" "$target" \
          >>"$output"
      elif [[ -f $path ]]; then
        printf 'f\t%s\t%s\t%s\n' \
          "$(stat -c '%s' -- "$path")" \
          "$(sha256sum -- "$path" | cut -d' ' -f1)" "$path" >>"$output"
      elif [[ -d $path ]]; then
        printf 'd\t%s\t-\t%s\n' "$(stat -c '%s' -- "$path")" "$path" \
          >>"$output"
      else
        die "source type changed during inventory: $path"
      fi
    done < <(find "/tmp/$name" -xdev -print0 | sort -z)
  done
}

mode=archive
case ${1:-} in
  '') ;;
  --dry-run) mode=dry-run ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 64 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 64; }

for tool in find sort realpath sha256sum stat readlink tar zstd cmp awk; do
  command -v "$tool" >/dev/null || die "required tool not found: $tool"
done
assert_output_path "$OUT_DIR"
[[ ! -e $OUT_DIR ]] || die "refusing stale archive output: $OUT_DIR"

mapfile -d '' -t source_names < <(discover_sources)
((${#source_names[@]} > 0)) || die "no related /tmp sources found"
validate_tree_types "${source_names[@]}"
validate_protected_log

if [[ $mode == dry-run ]]; then
  printf '[T3I-TMP-ARCHIVE] DRY-RUN PASS: sources=%s output=%s\n' \
    "${#source_names[@]}" "$ARCHIVE"
  printf '  /tmp/%s\n' "${source_names[@]}"
  exit 0
fi

mkdir -- "$OUT_DIR"
printf '%s\0' "${source_names[@]}" >"$SOURCE_NUL"
printf '%s\n' "${source_names[@]}" >"$SOURCE_TXT"
write_inventory "$INVENTORY_PRE" "${source_names[@]}"

{
  printf 'format=T3I_RELATED_TMP_ARCHIVE_V1\n'
  printf 'created_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'task_slug=%s\n' "$TASK_SLUG"
  printf 'selection=/tmp/t3i-* OR /tmp/ysyx-t3i-* (top-level, case-sensitive)\n'
  printf 'source_count=%s\n' "${#source_names[@]}"
  printf 'source_list_sha256=%s\n' \
    "$(sha256sum "$SOURCE_NUL" | cut -d' ' -f1)"
  printf 'pre_inventory_sha256=%s\n' \
    "$(sha256sum "$INVENTORY_PRE" | cut -d' ' -f1)"
  printf 'symlink_policy=no-dereference\n'
  printf 'filesystem_policy=one-file-system\n'
  printf 'script_sha256=%s\n' "$(sha256sum "${BASH_SOURCE[0]}" | cut -d' ' -f1)"
  printf 'zstd=%s\n' "$(zstd --version | head -1)"
} >"$PROVENANCE"

archive_tmp="$ARCHIVE.tmp.$$"
trap 'rm -f -- "$archive_tmp"' EXIT
# The source list contains only the validated top-level roots.  GNU tar retains
# their complete trees and does not dereference symlinks unless requested.
tar --create --file=- --directory=/tmp --one-file-system \
  --null --files-from="$SOURCE_NUL" \
  | zstd -T1 -10 -o "$archive_tmp"
mv -- "$archive_tmp" "$ARCHIVE"
trap - EXIT

zstd --test --quiet -- "$ARCHIVE"
zstd -dc -- "$ARCHIVE" | tar --list --file=- >"$CONTENTS"
awk -F/ 'NF {print $1}' "$CONTENTS" | sort -u >"$ARCHIVE_ROOTS"
cmp -s "$SOURCE_TXT" "$ARCHIVE_ROOTS" \
  || die "archive top-level roots differ from the exact source selection"

mapfile -d '' -t source_names_post < <(discover_sources)
printf '%s\0' "${source_names_post[@]}" >"$SOURCE_POST_NUL"
printf '%s\n' "${source_names_post[@]}" >"$SOURCE_POST_TXT"
cmp -s "$SOURCE_NUL" "$SOURCE_POST_NUL" \
  || die "related top-level /tmp source set changed during archiving"
write_inventory "$INVENTORY_POST" "${source_names_post[@]}"
cmp -s "$INVENTORY_PRE" "$INVENTORY_POST" \
  || die "related /tmp source content changed during archiving"
validate_protected_log

(
  cd "$ROOT_DIR"
  sha256sum -- \
    "${ARCHIVE#"$ROOT_DIR/"}" \
    "${SOURCE_NUL#"$ROOT_DIR/"}" \
    "${SOURCE_TXT#"$ROOT_DIR/"}" \
    "${SOURCE_POST_NUL#"$ROOT_DIR/"}" \
    "${SOURCE_POST_TXT#"$ROOT_DIR/"}" \
    "${INVENTORY_PRE#"$ROOT_DIR/"}" \
    "${INVENTORY_POST#"$ROOT_DIR/"}" \
    "${CONTENTS#"$ROOT_DIR/"}" \
    "${ARCHIVE_ROOTS#"$ROOT_DIR/"}" \
    "${PROVENANCE#"$ROOT_DIR/"}" \
    >"${SUMS#"$ROOT_DIR/"}"
  sha256sum --strict -c "${SUMS#"$ROOT_DIR/"}"
)

printf '[T3I-TMP-ARCHIVE] PASS: sources=%s entries=%s bytes=%s archive=%s\n' \
  "${#source_names[@]}" "$(wc -l <"$CONTENTS")" \
  "$(stat -c '%s' "$ARCHIVE")" "$ARCHIVE"
