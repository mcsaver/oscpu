#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
LINUX_ROOT="${LINUX_ROOT:-$LINUX_HOME/env/src/linux}"
PATCH_FILE="${NPC_TTY_RX_TRACE_PATCH:-$LINUX_HOME/patches/linux-npc-tty-rx-trace.patch}"
MARKER="__NPC_TTY_RX_NTTY_POLL__"

usage() {
  cat <<'USAGE'
Usage: Linux/scripts/npc-tty-rx-trace-patch.sh <status|check|check-revert|apply|revert>

Applies or removes the explicit NPC tty RX diagnostic kernel patch from
Linux/env/src/linux. Normal Linux builds do not apply this patch automatically.
USAGE
}

require_tree() {
  if [[ ! -d "$LINUX_ROOT" ]]; then
    echo "Linux source tree not found: $LINUX_ROOT" >&2
    exit 2
  fi
  if [[ ! -f "$PATCH_FILE" ]]; then
    echo "Patch file not found: $PATCH_FILE" >&2
    exit 2
  fi
  if ! command -v patch >/dev/null 2>&1; then
    echo "Required command not found: patch" >&2
    exit 2
  fi
}

is_applied() {
  grep -q "$MARKER" "$LINUX_ROOT/drivers/tty/n_tty.c"
}

cmd="${1:-}"
case "$cmd" in
  status)
    require_tree
    if is_applied; then
      echo "npc tty rx trace patch: applied"
    else
      echo "npc tty rx trace patch: not applied"
    fi
    ;;
  check)
    require_tree
    if is_applied; then
      echo "npc tty rx trace patch: already applied"
      exit 0
    fi
    patch --dry-run -d "$LINUX_ROOT" -p1 < "$PATCH_FILE"
    ;;
  check-revert)
    require_tree
    if ! is_applied; then
      echo "npc tty rx trace patch: not applied"
      exit 0
    fi
    patch --dry-run -R -d "$LINUX_ROOT" -p1 < "$PATCH_FILE"
    ;;
  apply)
    require_tree
    if is_applied; then
      echo "npc tty rx trace patch: already applied"
      exit 0
    fi
    patch -d "$LINUX_ROOT" -p1 < "$PATCH_FILE"
    echo "npc tty rx trace patch: applied"
    ;;
  revert)
    require_tree
    if ! is_applied; then
      echo "npc tty rx trace patch: not applied"
      exit 0
    fi
    patch -R -d "$LINUX_ROOT" -p1 < "$PATCH_FILE"
    echo "npc tty rx trace patch: reverted"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
