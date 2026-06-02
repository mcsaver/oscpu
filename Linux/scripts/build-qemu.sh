#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}

REF=${QEMU_REF:-v9.2.4}
ROOT=${QEMU_ROOT:-"$ENV_ROOT/src/qemu"}
BUILD_DIR=${QEMU_BUILD_DIR:-"$ENV_ROOT/build/qemu-riscv64-softmmu"}
PREFIX=${QEMU_PREFIX:-"$ENV_ROOT/tools/qemu"}
JOBS=${JOBS:-$(nproc)}

if [ ! -d "$ROOT/.git" ]; then
  mkdir -p "$(dirname "$ROOT")"
  git clone --depth=1 --branch "$REF" https://gitlab.com/qemu-project/qemu.git "$ROOT"
else
  git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
  git -C "$ROOT" checkout -q "$REF"
fi

mkdir -p "$BUILD_DIR" "$PREFIX"
cd "$BUILD_DIR"

"$ROOT/configure" \
  --prefix="$PREFIX" \
  --target-list=riscv64-softmmu \
  --disable-docs \
  --disable-gtk \
  --disable-sdl \
  --disable-vnc \
  --disable-curses \
  --disable-opengl \
  --disable-spice \
  --disable-virglrenderer \
  --disable-werror

make -j"$JOBS"
make install

echo "[qemu] qemu-system-riscv64: $PREFIX/bin/qemu-system-riscv64"
