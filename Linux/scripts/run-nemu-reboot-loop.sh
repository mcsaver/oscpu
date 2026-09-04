#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_REBOOT_EXIT_CODE=32
readonly DEFAULT_MAX_BOOTS=2

usage() {
  cat >&2 <<'USAGE'
Usage: run-nemu-reboot-loop.sh [OPTIONS] -- COMMAND [ARG...]

Run the exact same NEMU command again when it exits with the dedicated guest
reboot status.  A normal poweroff (0) and every other status are returned
unchanged.

Options:
  --reboot-exit-code CODE  Guest reboot status (default: 32)
  --max-boots COUNT        Maximum total command invocations (default: 2)
  -h, --help               Show this help

Example:
  run-nemu-reboot-loop.sh --reboot-exit-code 32 --max-boots 2 -- \
    /path/to/riscv64-nemu-interpreter -b [NEMU options]
USAGE
}

reboot_exit_code=$DEFAULT_REBOOT_EXIT_CODE
max_boots=$DEFAULT_MAX_BOOTS

while (( $# > 0 )); do
  case $1 in
    --reboot-exit-code)
      if (( $# < 2 )); then
        usage
        exit 2
      fi
      reboot_exit_code=$2
      shift 2
      ;;
    --reboot-exit-code=*)
      reboot_exit_code=${1#*=}
      shift
      ;;
    --max-boots)
      if (( $# < 2 )); then
        usage
        exit 2
      fi
      max_boots=$2
      shift 2
      ;;
    --max-boots=*)
      max_boots=${1#*=}
      shift
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '[nemu-reboot-loop] unknown option: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! $reboot_exit_code =~ ^[0-9]+$ ]] ||
    (( reboot_exit_code < 1 || reboot_exit_code > 125 )); then
  printf '[nemu-reboot-loop] reboot exit code must be in [1, 125]: %s\n' \
    "$reboot_exit_code" >&2
  exit 2
fi
if [[ ! $max_boots =~ ^[0-9]+$ ]] || (( max_boots < 1 )); then
  printf '[nemu-reboot-loop] max boots must be a positive integer: %s\n' \
    "$max_boots" >&2
  exit 2
fi
if (( $# == 0 )); then
  printf '[nemu-reboot-loop] missing command after --\n' >&2
  usage
  exit 2
fi

command=("$@")
child_pid=

forward_signal() {
  local signal=$1
  local status=$2
  local pid=${child_pid:-}

  trap '' HUP INT TERM
  if [[ -n $pid ]]; then
    kill -s "$signal" "$pid" 2>/dev/null || true
    # NEMU normally terminates immediately.  Keep cleanup bounded even if a
    # wrapper target masks the forwarded signal, so timeout cannot orphan it.
    for ((attempt = 0; attempt < 50; attempt++)); do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 0.02
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
  fi
  exit "$status"
}

trap 'forward_signal HUP 129' HUP
trap 'forward_signal INT 130' INT
trap 'forward_signal TERM 143' TERM

boot=1
max_reboots=$((max_boots - 1))
while :; do
  # 非交互 bash 会默认把异步命令的 stdin 接到 /dev/null；显式继承 fd 0，
  # 保持 make run 的 ttyS0 交互输入，并让 reboot 后的新进程继续读同一输入流。
  "${command[@]}" <&0 &
  child_pid=$!
  if wait "$child_pid"; then
    status=0
  else
    status=$?
  fi
  child_pid=

  if (( status != reboot_exit_code )); then
    exit "$status"
  fi
  if (( boot >= max_boots )); then
    printf '[nemu-reboot-loop] reboot limit reached after %d boot(s)\n' \
      "$boot" >&2
    exit "$status"
  fi

  printf '[nemu-reboot-loop] reboot %d/%d\n' "$boot" "$max_reboots" >&2
  boot=$((boot + 1))
done
