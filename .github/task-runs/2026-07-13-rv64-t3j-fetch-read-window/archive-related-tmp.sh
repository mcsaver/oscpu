#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

readonly ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
readonly TASK_SLUG=2026-07-13-rv64-t3j-fetch-read-window
readonly TASK_TMP="$ROOT_DIR/tmp/$TASK_SLUG"
readonly OUT_DIR="$TASK_TMP/tmp-archive"
readonly SOURCE_NUL="$OUT_DIR/source-list.pre.nul"
readonly SOURCE_TXT="$OUT_DIR/source-list.pre.txt"
readonly SOURCE_POST_NUL="$OUT_DIR/source-list.post.nul"
readonly SOURCE_POST_TXT="$OUT_DIR/source-list.post.txt"
readonly INVENTORY_PRE="$OUT_DIR/source-inventory.pre.tsv"
readonly INVENTORY_POST="$OUT_DIR/source-inventory.post.tsv"
readonly INVENTORY_ARCHIVE="$OUT_DIR/archive-inventory.tsv"
readonly INVENTORY_SUMMARY="$OUT_DIR/inventory-summary.tsv"
readonly ARCHIVE="$OUT_DIR/t3j-related-tmp.tar.zst"
readonly CONTENTS="$OUT_DIR/archive-contents.txt"
readonly ARCHIVE_ROOTS="$OUT_DIR/archive-top-level-paths.txt"
readonly PROVENANCE="$OUT_DIR/archive-provenance.txt"
readonly SUMS="$OUT_DIR/SHA256SUMS"
readonly VERIFY_DIR="$OUT_DIR/.verify-extract"
readonly OWNER_MARKER=.ysyx-t3j-owner
readonly PROTECTED_LOG=/tmp/ysyx-t3j-user-npc-linux.log
readonly PROTECTED_LOG_SHA256=3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15

archive_tmp=

usage() {
  cat <<'EOF'
Usage: archive-related-tmp.sh [--dry-run]

Archive every and only the current top-level /tmp/t3j-* and
/tmp/ysyx-t3j-* path into the workspace T3J tmp-archive directory.  A
standalone top-level yosys*/abc* directory is also selected only when its
regular, non-symlink .ysyx-t3j-owner file contains exactly:

  2026-07-13-rv64-t3j-fetch-read-window

Generic synthesis directories are deliberately not attributed by UID,
timestamp, or a transient PID.  Yosys/ABC files nested below an exact T3J
root are naturally included.  Symlinks are archived without dereferencing,
nested filesystems are not crossed, source paths are never removed, and a
changing source snapshot fails closed.

The resulting tar.zst is independently decompressed and extracted.  Its
path/type/logical-size/content-SHA inventory must exactly match both the
pre-archive and post-archive source inventories.

--dry-run validates selection, path constraints, source types, and the
protected-log hash without creating or changing any file.
EOF
}

die() {
  printf '[T3J-TMP-ARCHIVE] FAIL: %s\n' "$*" >&2
  exit 2
}

assert_task_root() {
  local resolved_root resolved_tmp resolved_task
  resolved_root=$(realpath -m -- "$ROOT_DIR")
  resolved_tmp=$(realpath -m -- "$ROOT_DIR/tmp")
  resolved_task=$(realpath -m -- "$TASK_TMP")
  case "$resolved_tmp" in
    "$resolved_root"/*) ;;
    *) die "workspace tmp root escapes the workspace: $resolved_tmp" ;;
  esac
  case "$resolved_task" in
    "$resolved_tmp"/*) ;;
    *) die "task tmp root escapes the workspace tmp root: $resolved_task" ;;
  esac
}

assert_output_path() {
  local path=$1
  local resolved_path resolved_task
  resolved_path=$(realpath -m -- "$path")
  resolved_task=$(realpath -m -- "$TASK_TMP")
  case "$resolved_path" in
    "$resolved_task"/*) ;;
    *) die "output path escapes task tmp root: $path" ;;
  esac
}

marker_matches() {
  local root=$1
  local marker="$root/$OWNER_MARKER"
  [[ -f $marker && ! -L $marker ]] || return 1
  cmp -s -- "$marker" <(printf '%s\n' "$TASK_SLUG")
}

is_marked_tool_root_name() {
  case $1 in
    yosys-*|yosys_*|abc-*|abc_*|.abc-*|.abc_*) return 0 ;;
    *) return 1 ;;
  esac
}

discover_sources() {
  local path
  {
    find /tmp -xdev -mindepth 1 -maxdepth 1 \
      \( -name 't3j-*' -o -name 'ysyx-t3j-*' \) \
      -printf '%f\0'
    while IFS= read -r -d '' path; do
      marker_matches "$path" && printf '%s\0' "${path#/tmp/}"
    done < <(
      find /tmp -xdev -mindepth 1 -maxdepth 1 -type d \
        \( -name 'yosys-*' -o -name 'yosys_*' \
           -o -name 'abc-*' -o -name 'abc_*' \
           -o -name '.abc-*' -o -name '.abc_*' \) -print0
    )
  } | sort -zu
}

validate_source_name() {
  local name=$1
  [[ -n $name && $name != */* && $name != '.' && $name != '..' ]] \
    || die "unsafe top-level /tmp source name: $name"
  case "$name" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "control character in source name" ;;
  esac
  [[ -e /tmp/$name || -L /tmp/$name ]] \
    || die "selected source disappeared: /tmp/$name"
  case "$name" in
    t3j-*|ysyx-t3j-*) ;;
    *)
      is_marked_tool_root_name "$name" \
        || die "source does not match the exact T3J selection: $name"
      [[ -d /tmp/$name && ! -L /tmp/$name ]] \
        || die "marked synthesis source is not a regular directory: /tmp/$name"
      marker_matches "/tmp/$name" \
        || die "marked synthesis source lost its exact owner marker: /tmp/$name"
      ;;
  esac
}

validate_protected_log() {
  local actual
  if [[ -e $PROTECTED_LOG || -L $PROTECTED_LOG ]]; then
    [[ -f $PROTECTED_LOG && ! -L $PROTECTED_LOG ]] \
      || die "protected log is not a regular non-symlink file"
    actual=$(sha256sum -- "$PROTECTED_LOG" | cut -d' ' -f1)
    [[ $actual == "$PROTECTED_LOG_SHA256" ]] \
      || die "protected log hash mismatch: $actual"
  fi
}

validate_tree_types() {
  local name path target
  for name in "$@"; do
    validate_source_name "$name"
    while IFS= read -r -d '' path; do
      case "$path" in
        *$'\n'*|*$'\r'*|*$'\t'*) die "control character in source path" ;;
      esac
      if [[ -L $path ]]; then
        target=$(readlink -- "$path")
        case "$target" in
          *$'\n'*|*$'\r'*|*$'\t'*) die "control character in symlink target: $path" ;;
        esac
      elif [[ -f $path || -d $path ]]; then
        :
      else
        die "unsupported source type (only file/dir/symlink allowed): $path"
      fi
    done < <(find "/tmp/$name" -xdev -print0 | sort -z)
  done
}

write_inventory() {
  local output=$1
  local base=$2
  shift 2
  local name path relative display target target_sha target_bytes

  printf 'type\tlogical_bytes\tsha256_or_link_sha256\tpath_or_link\n' >"$output"
  for name in "$@"; do
    [[ -e $base/$name || -L $base/$name ]] \
      || die "inventory root disappeared: $base/$name"
    while IFS= read -r -d '' path; do
      relative=${path#"$base"/}
      display="/tmp/$relative"
      case "$display" in
        *$'\n'*|*$'\r'*|*$'\t'*) die "control character in inventory path" ;;
      esac
      if [[ -L $path ]]; then
        target=$(readlink -- "$path")
        case "$target" in
          *$'\n'*|*$'\r'*|*$'\t'*) die "control character in symlink target: $display" ;;
        esac
        target_sha=$(printf '%s' "$target" | sha256sum | cut -d' ' -f1)
        target_bytes=$(printf '%s' "$target" | wc -c)
        printf 'l\t%s\t%s\t%s -> %s\n' \
          "$target_bytes" "$target_sha" "$display" "$target" >>"$output"
      elif [[ -f $path ]]; then
        printf 'f\t%s\t%s\t%s\n' \
          "$(stat -c '%s' -- "$path")" \
          "$(sha256sum -- "$path" | cut -d' ' -f1)" "$display" >>"$output"
      elif [[ -d $path ]]; then
        # Directory inode sizes vary across filesystems; zero is the canonical
        # logical content size, while every child is inventoried independently.
        printf 'd\t0\t-\t%s\n' "$display" >>"$output"
      else
        die "unsupported or changing inventory type: $display"
      fi
    done < <(find "$base/$name" -xdev -print0 | sort -z)
  done
}

inventory_entries() {
  awk 'NR > 1 { count++ } END { print count + 0 }' "$1"
}

inventory_bytes() {
  awk -F '\t' 'NR > 1 { bytes += $2 } END { printf "%.0f\n", bytes + 0 }' "$1"
}

cleanup() {
  local rc=$?
  local resolved_verify expected_verify
  trap - EXIT
  if [[ -n $archive_tmp && ( -e $archive_tmp || -L $archive_tmp ) ]]; then
    rm -f -- "$archive_tmp"
  fi
  if [[ -e $VERIFY_DIR || -L $VERIFY_DIR ]]; then
    resolved_verify=$(realpath -m -- "$VERIFY_DIR")
    expected_verify=$(realpath -m -- "$OUT_DIR/.verify-extract")
    if [[ $resolved_verify == "$expected_verify" ]]; then
      rm -rf --one-file-system -- "$VERIFY_DIR"
    else
      printf '[T3J-TMP-ARCHIVE] FAIL: refusing unsafe verification cleanup: %s\n' \
        "$resolved_verify" >&2
      rc=2
    fi
  fi
  exit "$rc"
}

mode=archive
case ${1:-} in
  '') ;;
  --dry-run) mode=dry-run ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 64 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 64; }

for tool in find sort realpath sha256sum stat readlink tar zstd cmp awk wc \
  date mkdir mv rm cut head; do
  command -v "$tool" >/dev/null || die "required tool not found: $tool"
done
assert_task_root
assert_output_path "$OUT_DIR"
assert_output_path "$VERIFY_DIR"
[[ ! -e $OUT_DIR && ! -L $OUT_DIR ]] \
  || die "refusing stale archive output: $OUT_DIR"

mapfile -d '' -t source_names < <(discover_sources)
((${#source_names[@]} > 0)) || die "no related /tmp sources found"
validate_tree_types "${source_names[@]}"
validate_protected_log

if [[ $mode == dry-run ]]; then
  printf '[T3J-TMP-ARCHIVE] DRY-RUN PASS: sources=%s output=%s\n' \
    "${#source_names[@]}" "$ARCHIVE"
  printf '  /tmp/%s\n' "${source_names[@]}"
  exit 0
fi

mkdir -p -- "$TASK_TMP"
mkdir -- "$OUT_DIR"
trap cleanup EXIT

printf '%s\0' "${source_names[@]}" >"$SOURCE_NUL"
printf '/tmp/%s\n' "${source_names[@]}" >"$SOURCE_TXT"
write_inventory "$INVENTORY_PRE" /tmp "${source_names[@]}"

archive_tmp="$OUT_DIR/.t3j-related-tmp.tar.zst.tmp.$$"
assert_output_path "$archive_tmp"
# SOURCE_NUL contains only validated top-level roots.  GNU tar recursively
# captures their full trees without dereferencing symlinks or crossing mounts.
tar --create --file=- --directory=/tmp --one-file-system \
  --null --files-from="$SOURCE_NUL" \
  | zstd -T1 -10 -o "$archive_tmp"
mv -- "$archive_tmp" "$ARCHIVE"
archive_tmp=

zstd --test --quiet -- "$ARCHIVE"
zstd -dc -- "$ARCHIVE" \
  | tar --list --file=- --quoting-style=literal >"$CONTENTS"
awk -F/ 'NF { print $1 }' "$CONTENTS" | sort -u >"$ARCHIVE_ROOTS"
sed_source_roots="$OUT_DIR/.source-roots.expected.txt"
assert_output_path "$sed_source_roots"
printf '%s\n' "${source_names[@]}" >"$sed_source_roots"
cmp -s -- "$sed_source_roots" "$ARCHIVE_ROOTS" \
  || die "archive top-level roots differ from the exact source selection"
rm -f -- "$sed_source_roots"

mkdir -- "$VERIFY_DIR"
zstd -dc -- "$ARCHIVE" \
  | tar --extract --file=- --directory="$VERIFY_DIR" \
      --no-same-owner --no-same-permissions
write_inventory "$INVENTORY_ARCHIVE" "$VERIFY_DIR" "${source_names[@]}"
cmp -s -- "$INVENTORY_PRE" "$INVENTORY_ARCHIVE" \
  || die "unpacked archive path/size/SHA inventory differs from the source"

mapfile -d '' -t source_names_post < <(discover_sources)
printf '%s\0' "${source_names_post[@]}" >"$SOURCE_POST_NUL"
printf '/tmp/%s\n' "${source_names_post[@]}" >"$SOURCE_POST_TXT"
cmp -s -- "$SOURCE_NUL" "$SOURCE_POST_NUL" \
  || die "related top-level /tmp source set changed during archiving"
write_inventory "$INVENTORY_POST" /tmp "${source_names_post[@]}"
cmp -s -- "$INVENTORY_PRE" "$INVENTORY_POST" \
  || die "related /tmp source path/size/SHA inventory changed during archiving"
validate_protected_log

readonly PRE_ENTRIES=$(inventory_entries "$INVENTORY_PRE")
readonly POST_ENTRIES=$(inventory_entries "$INVENTORY_POST")
readonly ARCHIVE_ENTRIES=$(inventory_entries "$INVENTORY_ARCHIVE")
readonly TAR_ENTRIES=$(wc -l <"$CONTENTS")
[[ $PRE_ENTRIES == "$POST_ENTRIES" && $PRE_ENTRIES == "$ARCHIVE_ENTRIES" \
   && $PRE_ENTRIES == "$TAR_ENTRIES" ]] \
  || die "entry-count mismatch: pre=$PRE_ENTRIES post=$POST_ENTRIES unpacked=$ARCHIVE_ENTRIES tar=$TAR_ENTRIES"

printf 'phase\troot_count\tentry_count\tlogical_bytes\tinventory_sha256\n' \
  >"$INVENTORY_SUMMARY"
for phase_and_file in \
  "pre:$INVENTORY_PRE" "post:$INVENTORY_POST" "unpacked:$INVENTORY_ARCHIVE"; do
  phase=${phase_and_file%%:*}
  inventory=${phase_and_file#*:}
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$phase" "${#source_names[@]}" "$(inventory_entries "$inventory")" \
    "$(inventory_bytes "$inventory")" \
    "$(sha256sum -- "$inventory" | cut -d' ' -f1)" >>"$INVENTORY_SUMMARY"
done

{
  printf 'format=T3J_RELATED_TMP_ARCHIVE_V1\n'
  printf 'created_at=%s\n' "$(date --iso-8601=seconds)"
  printf 'task_slug=%s\n' "$TASK_SLUG"
  printf 'selection=/tmp/t3j-* OR /tmp/ysyx-t3j-*; marked standalone yosys*/abc* only\n'
  printf 'generic_owner_marker=%s with exact task slug plus newline\n' "$OWNER_MARKER"
  printf 'source_count=%s\n' "${#source_names[@]}"
  printf 'entry_count=%s\n' "$PRE_ENTRIES"
  printf 'logical_bytes=%s\n' "$(inventory_bytes "$INVENTORY_PRE")"
  printf 'source_list_sha256=%s\n' \
    "$(sha256sum -- "$SOURCE_NUL" | cut -d' ' -f1)"
  printf 'pre_inventory_sha256=%s\n' \
    "$(sha256sum -- "$INVENTORY_PRE" | cut -d' ' -f1)"
  printf 'post_inventory_sha256=%s\n' \
    "$(sha256sum -- "$INVENTORY_POST" | cut -d' ' -f1)"
  printf 'unpacked_inventory_sha256=%s\n' \
    "$(sha256sum -- "$INVENTORY_ARCHIVE" | cut -d' ' -f1)"
  printf 'archive_sha256=%s\n' "$(sha256sum -- "$ARCHIVE" | cut -d' ' -f1)"
  printf 'archive_bytes=%s\n' "$(stat -c '%s' -- "$ARCHIVE")"
  printf 'symlink_policy=no-dereference\n'
  printf 'filesystem_policy=one-file-system\n'
  printf 'source_policy=preserve; never remove or mutate selected sources\n'
  printf 'verification=zstd-test plus independent unpacked inventory equality\n'
  printf 'script_sha256=%s\n' "$(sha256sum -- "${BASH_SOURCE[0]}" | cut -d' ' -f1)"
  printf 'zstd=%s\n' "$(zstd --version | head -1)"
} >"$PROVENANCE"

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
    "${INVENTORY_ARCHIVE#"$ROOT_DIR/"}" \
    "${INVENTORY_SUMMARY#"$ROOT_DIR/"}" \
    "${CONTENTS#"$ROOT_DIR/"}" \
    "${ARCHIVE_ROOTS#"$ROOT_DIR/"}" \
    "${PROVENANCE#"$ROOT_DIR/"}" \
    >"${SUMS#"$ROOT_DIR/"}"
  sha256sum --strict -c "${SUMS#"$ROOT_DIR/"}"
)

rm -rf --one-file-system -- "$VERIFY_DIR"
trap - EXIT

printf '[T3J-TMP-ARCHIVE] PASS: sources=%s entries=%s logical_bytes=%s archive_bytes=%s archive=%s\n' \
  "${#source_names[@]}" "$PRE_ENTRIES" "$(inventory_bytes "$INVENTORY_PRE")" \
  "$(stat -c '%s' -- "$ARCHIVE")" "$ARCHIVE"
