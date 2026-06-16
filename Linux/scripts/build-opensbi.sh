#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
LOCAL_ELF_PREFIX="$ENV_ROOT/toolchains/riscv/bin/riscv64-unknown-elf-"
if [ -x "${LOCAL_ELF_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_ELF_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi

PLATFORM=${LINUX_PLATFORM:-npc}
ROOT=${OPENSBI_ROOT:-"$ENV_ROOT/src/opensbi"}
BUILD_DIR=${OPENSBI_BUILD_DIR:-"$ENV_ROOT/platforms/$PLATFORM/build/opensbi/kernel"}
REF=${OPENSBI_REF:-v1.8}
NPC_PATCH=${OPENSBI_NPC_PATCH:-"$LINUX_HOME/patches/opensbi-npc-no-pmp-hart-protection.patch"}
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
JOBS=${JOBS:-$(nproc)}
DTB=${OPENSBI_DTB:-"$LINUX_HOME/build/riscv64-$PLATFORM/npc-rv64.dtb"}
LINUX_MAKE_ARCH=${LINUX_MAKE_ARCH:-}
FW_JUMP_ADDR=${FW_JUMP_ADDR:-0x80200000}
DISABLE_PMU=${OPENSBI_DISABLE_PMU:-0}
PLATFORM_DEFCONFIG=defconfig

make_linux_dtb() {
  local make_args=()
  if [ -n "$LINUX_MAKE_ARCH" ]; then
    make_args+=(ARCH="$LINUX_MAKE_ARCH")
  fi
  env -u OPENSBI_DTB -u OPENSBI_BUILD_DIR make -C "$LINUX_HOME" \
    "${make_args[@]}" "$@"
}

if [ ! -d "$ROOT/.git" ]; then
  git clone https://github.com/riscv-software-src/opensbi.git "$ROOT"
fi

if git -C "$ROOT" rev-parse --verify -q "$REF^{commit}" >/dev/null; then
  echo "[opensbi] using local ref: $REF"
else
  git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
fi
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
    make_linux_dtb initramfs-dtb
    ;;
  npc-rv64-ubuntu-initramfs.dtb)
    make_linux_dtb ubuntu-initramfs-dtb
    ;;
  npc-rv64-ubuntu-shell-initramfs.dtb)
    make_linux_dtb ubuntu-shell-initramfs-dtb
    ;;
  npc-rv64-rootfs.dtb)
    make_linux_dtb rootfs-dtb
    ;;
  npc-rv64-nemu-rootfs.dtb)
    make_linux_dtb ARCH=riscv64-nemu rootfs-dtb
    ;;
  *)
    make_linux_dtb dtb
    ;;
esac

if [ "$DISABLE_PMU" = "1" ]; then
  # OpenSBI 的 make 会从 PLATFORM_DEFCONFIG 重新生成 .config；
  # 因此 no-PMU 必须改输入 defconfig，不能只在生成后的 .config 上 sed。
  PLATFORM_DEFCONFIG=ysyx_nopmu_defconfig
  cp "$ROOT/platform/generic/configs/defconfig" \
    "$ROOT/platform/generic/configs/$PLATFORM_DEFCONFIG"
  sed -i 's/^CONFIG_SBI_ECALL_PMU=y/# CONFIG_SBI_ECALL_PMU is not set/' \
    "$ROOT/platform/generic/configs/$PLATFORM_DEFCONFIG"
  if ! grep -q '^# CONFIG_SBI_ECALL_PMU is not set$' \
      "$ROOT/platform/generic/configs/$PLATFORM_DEFCONFIG"; then
    printf '\n# CONFIG_SBI_ECALL_PMU is not set\n' >> \
      "$ROOT/platform/generic/configs/$PLATFORM_DEFCONFIG"
  fi
  echo "[opensbi] CONFIG_SBI_ECALL_PMU disabled via $PLATFORM_DEFCONFIG"
fi

mkdir -p "$BUILD_DIR"
make -C "$ROOT" O="$BUILD_DIR" PLATFORM=generic CROSS_COMPILE="$CROSS_COMPILE" \
  PLATFORM_DEFCONFIG="$PLATFORM_DEFCONFIG" \
  FW_FDT_PATH="$DTB" FW_JUMP_ADDR="$FW_JUMP_ADDR" -j"$JOBS"

echo "[opensbi] fw_jump.bin: $BUILD_DIR/platform/generic/firmware/fw_jump.bin"
echo "[opensbi] embedded dtb: $DTB"
