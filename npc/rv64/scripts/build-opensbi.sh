#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
RV64_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${NPC_RV64_ENV_ROOT:-"$RV64_DIR/env"}
LOCAL_ELF_PREFIX="$ENV_ROOT/toolchains/riscv/bin/riscv64-unknown-elf-"
if [ -x "${LOCAL_ELF_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_ELF_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi

ROOT=${OPENSBI_ROOT:-"$ENV_ROOT/src/opensbi"}
BUILD_DIR=${OPENSBI_BUILD_DIR:-"$ENV_ROOT/build/opensbi-npc"}
REF=${OPENSBI_REF:-v1.8}
NPC_PATCH=${OPENSBI_NPC_PATCH:-"$RV64_DIR/patches/opensbi-npc-no-pmp-hart-protection.patch"}
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
JOBS=${JOBS:-$(nproc)}
DTB=${OPENSBI_DTB:-"$RV64_DIR/tools/build/npc-rv64.dtb"}
FW_JUMP_ADDR=${FW_JUMP_ADDR:-0x80200000}

if [ ! -d "$ROOT/.git" ]; then
  git clone https://github.com/riscv-software-src/opensbi.git "$ROOT"
fi

git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
git -C "$ROOT" checkout -q "$REF"
if [ -f "$NPC_PATCH" ]; then
  if git -C "$ROOT" apply --reverse --check "$NPC_PATCH" >/dev/null 2>&1; then
    echo "[opensbi] npc patch already applied: $NPC_PATCH"
  else
    git -C "$ROOT" apply "$NPC_PATCH"
    echo "[opensbi] applied npc patch: $NPC_PATCH"
  fi
fi

case "$(basename -- "$DTB")" in
  npc-rv64-initramfs.dtb)
    make -C "$RV64_DIR/tools" initramfs-dtb
    ;;
  npc-rv64-ubuntu-initramfs.dtb)
    make -C "$RV64_DIR/tools" ubuntu-initramfs-dtb
    ;;
  npc-rv64-ubuntu-shell-initramfs.dtb)
    make -C "$RV64_DIR/tools" ubuntu-shell-initramfs-dtb
    ;;
  npc-rv64-rootfs.dtb)
    make -C "$RV64_DIR/tools" rootfs-dtb
    ;;
  *)
    make -C "$RV64_DIR/tools" dtb
    ;;
esac

make -C "$ROOT" O="$BUILD_DIR" PLATFORM=generic CROSS_COMPILE="$CROSS_COMPILE" \
  FW_FDT_PATH="$DTB" FW_JUMP_ADDR="$FW_JUMP_ADDR" -j"$JOBS"

echo "[opensbi] fw_jump.bin: $BUILD_DIR/platform/generic/firmware/fw_jump.bin"
echo "[opensbi] embedded dtb: $DTB"
