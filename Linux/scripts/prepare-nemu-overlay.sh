#!/usr/bin/env bash
set -euo pipefail

backing=
overlay=
reset=0

usage() {
  echo "usage: $0 --backing=PATH --overlay=PATH [--reset=0|1]" >&2
  exit 2
}

fail() {
  echo "[nemu-overlay] FAIL: $*" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --backing=*) backing=${arg#*=} ;;
    --overlay=*) overlay=${arg#*=} ;;
    --reset=*) reset=${arg#*=} ;;
    *) usage ;;
  esac
done

[ -n "$backing" ] || fail "backing path is empty"
[ -n "$overlay" ] || fail "overlay path is empty"
case "$reset" in
  0|1) ;;
  *) fail "reset must be 0 or 1: $reset" ;;
esac
for host_tool in flock realpath; do
  command -v "$host_tool" >/dev/null 2>&1 || fail "missing host $host_tool"
done
[ -f "$backing" ] || fail "backing image is not a regular file: $backing"

backing_real=$(realpath -e -- "$backing") || fail "cannot resolve backing image: $backing"
overlay_real=$(realpath -m -- "$overlay") || fail "cannot resolve overlay path: $overlay"
overlay_meta_real=$(realpath -m -- "$overlay.meta") || fail "cannot resolve overlay metadata path"
overlay_meta_tmp_real=$(realpath -m -- "$overlay.meta.tmp") || fail "cannot resolve temporary overlay metadata path"
overlay_lock_real=$(realpath -m -- "$overlay.lock") || fail "cannot resolve stable overlay lock path"

for resolved in \
    "$overlay_real" "$overlay_meta_real" "$overlay_meta_tmp_real" \
    "$overlay_lock_real"; do
  case "$resolved" in
    /|'') fail "unsafe overlay artifact path: $resolved" ;;
  esac
  [ "$resolved" != "$backing_real" ] || \
    fail "overlay artifact aliases the immutable backing image: $backing_real"
done
for path in "$overlay" "$overlay.meta" "$overlay.meta.tmp" "$overlay.lock"; do
  [ ! -d "$path" ] || fail "overlay artifact path is a directory: $path"
  if { [ -e "$path" ] || [ -L "$path" ]; } && [ "$path" -ef "$backing" ]; then
    fail "overlay artifact is a hardlink/symlink to the immutable backing image: $backing_real"
  fi
done

mkdir -p -- "$(dirname -- "$overlay")"

# The raw file itself is atomically replaceable, so its inode lock cannot
# serialize a reset against a running emulator.  Keep this path-stable lock for
# the complete inspection/reset transaction; NEMU holds the same lock from
# before opening the raw overlay until after its final metadata commit.
if [ -L "$overlay.lock" ] || { [ -e "$overlay.lock" ] && [ ! -f "$overlay.lock" ]; }; then
  fail "stable overlay lock is not a regular file: $overlay.lock"
fi
exec {overlay_lock_fd}>>"$overlay.lock"
flock -n "$overlay_lock_fd" || fail "overlay is already in use: $overlay_real"

# Revalidate after acquiring the lock because another process may have changed
# the paths while this helper was starting.
for path in "$overlay" "$overlay.meta" "$overlay.meta.tmp" "$overlay.lock"; do
  [ ! -d "$path" ] || fail "overlay artifact path is a directory: $path"
  if { [ -e "$path" ] || [ -L "$path" ]; } && [ "$path" -ef "$backing" ]; then
    fail "overlay artifact is a hardlink/symlink to the immutable backing image: $backing_real"
  fi
done
for path in "$overlay" "$overlay.meta" "$overlay.meta.tmp"; do
  if [ -e "$path" ] && [ "$path" -ef "$overlay.lock" ]; then
    fail "stable overlay lock aliases mutable artifact: $path"
  fi
done

if [ "$reset" = 1 ]; then
  # realpath 只用于识别与 backing 的别名；删除必须针对用户给出的词法路径，
  # 否则既存 symlink 会让 rm 误删其目标而留下链接本身。
  rm -f -- "$overlay" "$overlay.meta" "$overlay.meta.tmp"
fi
printf '[nemu-overlay] backing=%s overlay=%s reset=%s\n' \
  "$backing_real" "$overlay_real" "$reset"
