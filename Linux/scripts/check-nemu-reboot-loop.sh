#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHECK_SCRIPT="$SCRIPT_DIR/$(basename -- "${BASH_SOURCE[0]}")"
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$LINUX_HOME/.." && pwd)
NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
CROSS_COMPILE=${CROSS_COMPILE:-riscv64-linux-gnu-}
WRAPPER=${NEMU_REBOOT_WRAPPER:-"$SCRIPT_DIR/run-nemu-reboot-loop.sh"}
PAYLOAD=${NEMU_SYSCON_RESET_PAYLOAD:-"$LINUX_HOME/tools/nemu-syscon-reset-smoke.S"}
readonly REBOOT_EXIT_CODE=32

if [[ ${1:-} == --stdin-child ]]; then
  if (( $# != 2 )); then
    exit 2
  fi
  stdin_state=$2
  if mkdir "$stdin_state" 2>/dev/null; then
    stdin_expected=boot1
    stdin_status=$REBOOT_EXIT_CODE
  else
    stdin_expected=boot2
    stdin_status=0
  fi
  IFS= read -r stdin_actual || exit 74
  [[ $stdin_actual == "$stdin_expected" ]] || exit 75
  printf 'stdin-%s-ok\n' "$stdin_expected"
  exit "$stdin_status"
fi

if [[ ${1:-} == --loop-child ]]; then
  if (( $# != 4 )); then
    exit 2
  fi
  state_dir=$2
  reboot_bin=$3
  poweroff_bin=$4
  if mkdir "$state_dir" 2>/dev/null; then
    exec env NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b "$reboot_bin"
  fi
  exec env NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b "$poweroff_bin"
fi

if (( $# != 0 )); then
  printf 'Usage: %s\n' "$0" >&2
  exit 2
fi
if [[ ! -x $NEMU_SIM ]]; then
  printf 'NEMU binary is missing or not executable: %s\n' "$NEMU_SIM" >&2
  exit 2
fi
if [[ ! -x $WRAPPER ]]; then
  printf 'NEMU reboot wrapper is missing or not executable: %s\n' "$WRAPPER" >&2
  exit 2
fi

CC=${CROSS_COMPILE}gcc
OBJCOPY=${CROSS_COMPILE}objcopy
command -v "$CC" >/dev/null
command -v "$OBJCOPY" >/dev/null

temp_root=${TMPDIR:-/tmp}
temp_root=$(cd -- "$temp_root" && pwd -P)
work_dir=$(mktemp -d "$temp_root/nemu-reboot-smoke.XXXXXX")
cleanup() {
  if [[ -n ${work_dir:-} && -d $work_dir &&
        $work_dir == "$temp_root"/nemu-reboot-smoke.* ]]; then
    rm -rf -- "$work_dir"
  fi
}
trap cleanup EXIT

build_payload() {
  local value=$1
  local name=$2
  "$CC" -x assembler-with-cpp -nostdlib -nostartfiles \
    -march=rv64ima_zicsr_zifencei -mabi=lp64 -static -no-pie \
    -Wl,-Ttext=0x80000000 -Wl,-e,_start -Wl,--no-relax \
    -Wl,--build-id=none -DSYSCON_VALUE="$value" \
    "$PAYLOAD" -o "$work_dir/$name.elf"
  "$OBJCOPY" -O binary "$work_dir/$name.elf" "$work_dir/$name.bin"
}

run_and_capture() {
  local log=$1
  shift
  if "$@" >"$log" 2>&1; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi
}

build_payload 0x7777 reboot
build_payload 0x5555 poweroff

run_and_capture "$work_dir/reboot.log" \
  env NEMU_HOME="$NEMU_HOME" "$NEMU_SIM" -b "$work_dir/reboot.bin"
if (( RUN_STATUS != REBOOT_EXIT_CODE )); then
  cat "$work_dir/reboot.log" >&2
  printf 'expected guest reboot rc=%d, got rc=%d\n' \
    "$REBOOT_EXIT_CODE" "$RUN_STATUS" >&2
  exit 1
fi
grep -Fq 'syscon-reset: reboot requested value=0x00007777' "$work_dir/reboot.log"
grep -Fq 'GUEST REBOOT' "$work_dir/reboot.log"
if grep -Fq 'HIT GOOD TRAP' "$work_dir/reboot.log"; then
  printf 'guest reboot was incorrectly reported as a good trap\n' >&2
  exit 1
fi

run_and_capture "$work_dir/loop.log" \
  "$WRAPPER" --reboot-exit-code "$REBOOT_EXIT_CODE" --max-boots 2 -- \
    "$CHECK_SCRIPT" --loop-child "$work_dir/boot-state" \
    "$work_dir/reboot.bin" "$work_dir/poweroff.bin"
if (( RUN_STATUS != 0 )); then
  cat "$work_dir/loop.log" >&2
  printf 'reboot loop did not propagate final poweroff rc=0: rc=%d\n' \
    "$RUN_STATUS" >&2
  exit 1
fi
if [[ $(grep -Fc '[nemu-reboot-loop] reboot 1/1' "$work_dir/loop.log") != 1 ]]; then
  cat "$work_dir/loop.log" >&2
  printf 'reboot loop marker did not occur exactly once\n' >&2
  exit 1
fi
if [[ $(grep -Fc 'syscon-reset: reboot requested value=0x00007777' "$work_dir/loop.log") != 1 ]] ||
    [[ $(grep -Fc 'syscon-reset: poweroff requested value=0x00005555' "$work_dir/loop.log") != 1 ]]; then
  cat "$work_dir/loop.log" >&2
  printf 'expected exactly one guest reboot followed by one poweroff\n' >&2
  exit 1
fi
grep -Fq 'HIT GOOD TRAP' "$work_dir/loop.log"

# 同一个 pipe 在两次启动间保持打开；boot1、boot2 必须各消费一行。这个
# 回归会直接捕获非交互 bash 把后台 child stdin 偷换成 /dev/null 的行为。
set +e
printf 'boot1\nboot2\n' | \
  "$WRAPPER" --reboot-exit-code "$REBOOT_EXIT_CODE" --max-boots 2 -- \
    "$CHECK_SCRIPT" --stdin-child "$work_dir/stdin-state" \
    >"$work_dir/stdin.log" 2>&1
stdin_status=${PIPESTATUS[1]}
set -e
if (( stdin_status != 0 )) ||
   [[ $(grep -Fc 'stdin-boot1-ok' "$work_dir/stdin.log") != 1 ]] ||
   [[ $(grep -Fc 'stdin-boot2-ok' "$work_dir/stdin.log") != 1 ]]; then
  cat "$work_dir/stdin.log" >&2
  printf 'wrapper did not preserve stdin across both boots: rc=%d\n' \
    "$stdin_status" >&2
  exit 1
fi

run_and_capture "$work_dir/propagate.log" \
  "$WRAPPER" --reboot-exit-code "$REBOOT_EXIT_CODE" --max-boots 2 -- \
    sh -c 'exit 73'
if (( RUN_STATUS != 73 )); then
  printf 'wrapper changed non-reboot status 73 to %d\n' "$RUN_STATUS" >&2
  exit 1
fi

printf 'PASS guest syscon reboot exits rc=%d without GOOD TRAP\n' \
  "$REBOOT_EXIT_CODE"
printf 'PASS wrapper restarted once and propagated final poweroff rc=0\n'
printf 'PASS wrapper preserved stdin across boot1 and boot2\n'
printf 'PASS wrapper propagated non-reboot rc=73 unchanged\n'
printf '__NEMU_REBOOT_LOOP_SMOKE__:ok\n'
