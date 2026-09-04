#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
NEMU_HOME=${NEMU_HOME:-"$(cd -- "$SCRIPT_DIR/.." && pwd)"}
NEMU_CONFIG_DIR=${NEMU_CONFIG_DIR:-"$NEMU_HOME/build/config-riscv64-linux-gui"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-linux-gui/riscv64-nemu-interpreter"}
CROSS_COMPILE=${CROSS_COMPILE:-riscv64-linux-gnu-}
HOST_CC=${HOST_CC:-cc}
PAYLOAD=${NEMU_VIRTIO_INPUT_PAYLOAD:-"$SCRIPT_DIR/virtio-input-smoke.S"}
SDL_SHIM=${NEMU_VIRTIO_INPUT_SDL_SHIM:-"$SCRIPT_DIR/virtio-input-sdl-inject.c"}
TIMEOUT_SECONDS=${NEMU_VIRTIO_INPUT_TIMEOUT:-20}

if (( $# != 0 )); then
  printf 'Usage: %s\n' "$0" >&2
  exit 2
fi
if [[ ! -x $NEMU_SIM ]]; then
  printf 'GUI NEMU binary is missing or not executable: %s\n' "$NEMU_SIM" >&2
  exit 2
fi
if [[ ! -f $NEMU_CONFIG_DIR/.config ]] ||
    ! grep -q '^CONFIG_HAS_VIRTIO_INPUT=y$' "$NEMU_CONFIG_DIR/.config"; then
  printf 'Isolated GUI config does not enable CONFIG_HAS_VIRTIO_INPUT: %s\n' \
    "$NEMU_CONFIG_DIR/.config" >&2
  exit 2
fi
if [[ ! -f $PAYLOAD || ! -f $SDL_SHIM ]]; then
  printf 'virtio-input smoke sources are incomplete\n' >&2
  exit 2
fi

CC=${CROSS_COMPILE}gcc
OBJCOPY=${CROSS_COMPILE}objcopy
NM=${CROSS_COMPILE}nm
command -v "$CC" >/dev/null
command -v "$OBJCOPY" >/dev/null
command -v "$NM" >/dev/null
command -v "$HOST_CC" >/dev/null
command -v pkg-config >/dev/null
command -v timeout >/dev/null
pkg-config --exists sdl2

temp_root=${TMPDIR:-/tmp}
temp_root=$(cd -- "$temp_root" && pwd -P)
work_dir=$(mktemp -d "$temp_root/nemu-virtio-input.XXXXXX")
cleanup() {
  if [[ -n ${work_dir:-} && -d $work_dir &&
        $work_dir == "$temp_root"/nemu-virtio-input.* ]]; then
    rm -rf -- "$work_dir"
  fi
}
trap cleanup EXIT

"$CC" -x assembler-with-cpp -nostdlib -nostartfiles \
  -march=rv64ima_zicsr_zifencei -mabi=lp64 -static -no-pie \
  -Wl,-Ttext=0x80000000 -Wl,-e,_start -Wl,--no-relax \
  -Wl,--build-id=none "$PAYLOAD" -o "$work_dir/payload.elf"
"$OBJCOPY" -O binary "$work_dir/payload.elf" "$work_dir/payload.bin"
tohost_addr=$("$NM" -n "$work_dir/payload.elf" |
  awk '$3 == "tohost" { print "0x" $1; exit }')
if [[ -z $tohost_addr ]]; then
  printf 'virtio-input payload does not define tohost\n' >&2
  exit 2
fi

read -r -a sdl_cflags <<<"$(pkg-config --cflags sdl2)"
"$HOST_CC" -std=c11 -O2 -Wall -Wextra -Werror -fPIC -shared \
  "${sdl_cflags[@]}" "$SDL_SHIM" -ldl -o "$work_dir/sdl-inject.so"

log=$work_dir/nemu.log
status=0
preload=$work_dir/sdl-inject.so
if [[ -n ${LD_PRELOAD:-} ]]; then
  preload=$preload:$LD_PRELOAD
fi
if timeout "$TIMEOUT_SECONDS" env \
    SDL_VIDEODRIVER=dummy \
    SDL_AUDIODRIVER=dummy \
    LD_PRELOAD="$preload" \
    NEMU_HOME="$NEMU_HOME" \
    "$NEMU_SIM" -b --tohost="$tohost_addr" \
    "$work_dir/payload.bin" >"$log" 2>&1; then
  status=0
else
  status=$?
fi

if (( status != 0 )) || ! grep -Fq 'TOHOST PASS' "$log"; then
  cat "$log" >&2
  printf 'virtio-input protocol/queue smoke failed: rc=%d\n' "$status" >&2
  exit 1
fi
if grep -Fq 'TOHOST FAIL' "$log"; then
  cat "$log" >&2
  printf 'virtio-input protocol/queue smoke reported guest failure\n' >&2
  exit 1
fi

printf 'PASS config/features/eventq/statusq/bad-descriptor/repeat/IRQ7\n'
printf '__NEMU_VIRTIO_INPUT_SMOKE__:ok\n'
