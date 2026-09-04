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
PROFILE=${OPENSBI_PROFILE:-$PLATFORM}
SBI_PLATFORM=${OPENSBI_PLATFORM:-generic}
FW_JUMP_ADDR=${FW_JUMP_ADDR:-0x80200000}
FW_JUMP_FDT_ADDR=${FW_JUMP_FDT_ADDR:-}
DISABLE_PMU=${OPENSBI_DISABLE_PMU:-0}
PLATFORM_DEFCONFIG=defconfig
PROFILE_STAMP=${OPENSBI_PROFILE_STAMP:-}
STAMP_ARCH=${OPENSBI_STAMP_ARCH:-$LINUX_MAKE_ARCH}
STAMP_LINUX_PLATFORM=${OPENSBI_STAMP_LINUX_PLATFORM:-$PLATFORM}
STAMP_PROFILE=${OPENSBI_STAMP_PROFILE:-$PROFILE}
STAMP_ROOT=${OPENSBI_STAMP_ROOT:-$ROOT}
STAMP_REF=${OPENSBI_STAMP_REF:-$REF}
STAMP_NPC_PATCH=${OPENSBI_STAMP_NPC_PATCH:-$NPC_PATCH}
STAMP_CROSS_COMPILE=${OPENSBI_STAMP_CROSS_COMPILE:-$CROSS_COMPILE}
STAMP_PLATFORM=${OPENSBI_STAMP_PLATFORM:-$SBI_PLATFORM}
STAMP_FW_JUMP_ADDR=${OPENSBI_STAMP_FW_JUMP_ADDR:-$FW_JUMP_ADDR}
STAMP_FW_JUMP_FDT_ADDR=${OPENSBI_STAMP_FW_JUMP_FDT_ADDR:-$FW_JUMP_FDT_ADDR}
STAMP_DTB=${OPENSBI_STAMP_DTB:-$DTB}
STAMP_DISABLE_PMU=${OPENSBI_STAMP_DISABLE_PMU:-$DISABLE_PMU}
STAMP_BUILD_DIR=${OPENSBI_STAMP_BUILD_DIR:-$BUILD_DIR}

for host_tool in awk cmp flock id mktemp realpath sha256sum sort stat sync; do
  command -v "$host_tool" >/dev/null 2>&1 || {
    echo "[opensbi] missing host tool: $host_tool" >&2
    exit 1
  }
done
mkdir -p "$ENV_ROOT/src" "$BUILD_DIR"

# O= is a single mutable graph.  Use a lock derived from the canonical build
# directory so path aliases cannot split the artifact/profile transaction.
BUILD_DIR_REQUESTED=$BUILD_DIR
BUILD_DIR=$(realpath -e -- "$BUILD_DIR")
if [[ $BUILD_DIR == / ]]; then
  echo "[opensbi] refusing filesystem root as build dir" >&2
  exit 1
fi
FIRMWARE="$BUILD_DIR/platform/$SBI_PLATFORM/firmware/fw_jump.bin"
EXPECTED_FIRMWARE=$(realpath -m -- "${OPENSBI_EXPECTED_FIRMWARE:-$FIRMWARE}")
if [[ $EXPECTED_FIRMWARE != "$FIRMWARE" ]]; then
  echo "[opensbi] Make target does not match canonical firmware output: $EXPECTED_FIRMWARE != $FIRMWARE" >&2
  exit 1
fi
OPENSBI_BUILD_LOCK="$BUILD_DIR/.ysyx-build.lock"
NOPMU_DEFCONFIG_OUTPUT="$BUILD_DIR/.ysyx-opensbi-nopmu-defconfig"

# Compute the shared-source identity without creating its state directory.  In
# particular, DTB alias validation below must run before either lock is opened:
# opening a lock through a DTB hardlink/symlink would corrupt the input first.
ROOT_CANONICAL=$(realpath -m -- "$ROOT")
ROOT_KEY=$(printf '%s\0' "$ROOT_CANONICAL" | sha256sum | awk '{print $1}')
SOURCE_STATE_BASE="$(dirname -- "$ROOT_CANONICAL")/.ysyx-source-state"
SOURCE_STATE_DIR="$SOURCE_STATE_BASE/$ROOT_KEY"
DERIVED_SOURCE_LOCK=$(realpath -m -- "$SOURCE_STATE_DIR/source.lock")
if [[ -n ${OPENSBI_SOURCE_LOCK:-} &&
      $(realpath -m -- "$OPENSBI_SOURCE_LOCK") != "$DERIVED_SOURCE_LOCK" ]]; then
  echo "[opensbi] OPENSBI_SOURCE_LOCK must be derived from canonical OPENSBI_ROOT: $DERIVED_SOURCE_LOCK" >&2
  exit 1
fi
OPENSBI_SOURCE_LOCK=$DERIVED_SOURCE_LOCK
DERIVED_PATCH_STATE=$(realpath -m -- "$SOURCE_STATE_DIR/opensbi-applied.patch")
if [[ -n ${OPENSBI_PATCH_STATE:-} &&
      $(realpath -m -- "$OPENSBI_PATCH_STATE") != "$DERIVED_PATCH_STATE" ]]; then
  echo "[opensbi] OPENSBI_PATCH_STATE must be derived from canonical OPENSBI_ROOT: $DERIVED_PATCH_STATE" >&2
  exit 1
fi

if [[ -n $PROFILE_STAMP ]]; then
  if [[ -L $PROFILE_STAMP ]]; then
    echo "[opensbi] unsafe profile stamp symlink: $PROFILE_STAMP" >&2
    exit 1
  fi
  PROFILE_STAMP_REAL=$(realpath -m -- "$PROFILE_STAMP")
  EXPECTED_PROFILE_STAMP="$BUILD_DIR/.ysyx-build-profile"
  case "$PROFILE_STAMP_REAL" in
    "$BUILD_DIR"/*) ;;
    *)
      echo "[opensbi] profile stamp must stay inside canonical build dir: $PROFILE_STAMP" >&2
      exit 1
      ;;
  esac
  if [[ $PROFILE_STAMP_REAL != "$EXPECTED_PROFILE_STAMP" ]]; then
    echo "[opensbi] profile stamp must be the canonical build-dir stamp: $EXPECTED_PROFILE_STAMP" >&2
    exit 1
  fi
  PROFILE_STAMP=$PROFILE_STAMP_REAL
  if [[ -e $PROFILE_STAMP && ! -f $PROFILE_STAMP ]]; then
    echo "[opensbi] unsafe profile stamp: $PROFILE_STAMP" >&2
    exit 1
  fi
  if [[ $PROFILE_STAMP == "$FIRMWARE" ||
        $PROFILE_STAMP == "$OPENSBI_BUILD_LOCK" ||
        ( -e $PROFILE_STAMP && -e $FIRMWARE && $PROFILE_STAMP -ef $FIRMWARE ) ||
        ( -e $PROFILE_STAMP && -e $OPENSBI_BUILD_LOCK &&
          $PROFILE_STAMP -ef $OPENSBI_BUILD_LOCK ) ]]; then
    echo "[opensbi] profile stamp aliases a build artifact/lock: $PROFILE_STAMP" >&2
    exit 1
  fi
fi

paths_alias() {
  local left=$1 right=$2
  if [[ $(realpath -m -- "$left") == $(realpath -m -- "$right") ]]; then
    return 0
  fi
  [[ -e $left && -e $right && $left -ef $right ]]
}

reject_dtb_alias() {
  local label=$1 target=$2
  if paths_alias "$DTB" "$target"; then
    echo "[opensbi] DTB input aliases $label: $target" >&2
    exit 1
  fi
}

guard_dtb_aliases() {
  reject_dtb_alias "firmware output" "$FIRMWARE"
  reject_dtb_alias "build lock" "$OPENSBI_BUILD_LOCK"
  reject_dtb_alias "source lock" "$OPENSBI_SOURCE_LOCK"
  reject_dtb_alias "patch input" "$NPC_PATCH"
  reject_dtb_alias "recorded patch state" "$DERIVED_PATCH_STATE"
  reject_dtb_alias "generated no-PMU defconfig" "$NOPMU_DEFCONFIG_OUTPUT"
  reject_dtb_alias "source-state directory" "$SOURCE_STATE_BASE"
  reject_dtb_alias "source-state identity directory" "$SOURCE_STATE_DIR"
  if [[ -n $PROFILE_STAMP ]]; then
    reject_dtb_alias "profile stamp" "$PROFILE_STAMP"
  fi
}

# This is deliberately before exec redirections and before source-state mkdirs.
guard_dtb_aliases

if [[ -L $OPENSBI_BUILD_LOCK ||
      ( -e $OPENSBI_BUILD_LOCK && ! -f $OPENSBI_BUILD_LOCK ) ]]; then
  echo "[opensbi] unsafe build lock: $OPENSBI_BUILD_LOCK" >&2
  exit 1
fi
if [[ -e $OPENSBI_BUILD_LOCK && -e $FIRMWARE &&
      $OPENSBI_BUILD_LOCK -ef $FIRMWARE ]]; then
  echo "[opensbi] build lock aliases firmware: $OPENSBI_BUILD_LOCK" >&2
  exit 1
fi
if [[ -L $FIRMWARE || ( -e $FIRMWARE && ! -f $FIRMWARE ) ]]; then
  echo "[opensbi] unsafe firmware output: $FIRMWARE" >&2
  exit 1
fi
exec 8>>"$OPENSBI_BUILD_LOCK"
flock 8

# OpenSBI 的 checkout/patch/no-PMU defconfig 都位于共享 source tree；锁必须
# 覆盖到 firmware 链接完成，不能让另一 profile 在编译期间改写这些输入。
if [[ -L $SOURCE_STATE_BASE ||
      ( -e $SOURCE_STATE_BASE && ! -d $SOURCE_STATE_BASE ) ]]; then
  echo "[opensbi] unsafe source-state directory: $SOURCE_STATE_BASE" >&2
  exit 1
fi
mkdir -p "$SOURCE_STATE_BASE"
SOURCE_STATE_DIR="$SOURCE_STATE_BASE/$ROOT_KEY"
if [[ -L $SOURCE_STATE_DIR ||
      ( -e $SOURCE_STATE_DIR && ! -d $SOURCE_STATE_DIR ) ]]; then
  echo "[opensbi] unsafe source-state identity directory: $SOURCE_STATE_DIR" >&2
  exit 1
fi
mkdir -p "$SOURCE_STATE_DIR"
SOURCE_STATE_DIR=$(realpath -e -- "$SOURCE_STATE_DIR")
OPENSBI_SOURCE_LOCK="$SOURCE_STATE_DIR/source.lock"
DERIVED_PATCH_STATE="$SOURCE_STATE_DIR/opensbi-applied.patch"
# Recheck after directory creation, still before opening the source lock.
guard_dtb_aliases
if [[ -L $OPENSBI_SOURCE_LOCK ||
      ( -e $OPENSBI_SOURCE_LOCK && ! -f $OPENSBI_SOURCE_LOCK ) ]]; then
  echo "[opensbi] unsafe source lock: $OPENSBI_SOURCE_LOCK" >&2
  exit 1
fi
OPENSBI_SOURCE_LOCK=$(realpath -m -- "$OPENSBI_SOURCE_LOCK")
if [[ $OPENSBI_SOURCE_LOCK == "$OPENSBI_BUILD_LOCK" ||
      $OPENSBI_SOURCE_LOCK == "$FIRMWARE" ||
      ( -n $PROFILE_STAMP && $OPENSBI_SOURCE_LOCK == "$PROFILE_STAMP" ) ||
      ( -e $OPENSBI_SOURCE_LOCK && -e $OPENSBI_BUILD_LOCK &&
        $OPENSBI_SOURCE_LOCK -ef $OPENSBI_BUILD_LOCK ) ||
      ( -e $OPENSBI_SOURCE_LOCK && -e $FIRMWARE && $OPENSBI_SOURCE_LOCK -ef $FIRMWARE ) ||
      ( -n $PROFILE_STAMP && -e $OPENSBI_SOURCE_LOCK && -e $PROFILE_STAMP &&
        $OPENSBI_SOURCE_LOCK -ef $PROFILE_STAMP ) ]]; then
  echo "[opensbi] source lock aliases a build artifact/profile lock" >&2
  exit 1
fi
exec 9>>"$OPENSBI_SOURCE_LOCK"
flock 9

require_stamp_match() {
  local field=$1 stamped=$2 actual=$3
  if [[ $stamped != "$actual" ]]; then
    echo "[opensbi] inconsistent Make/script profile field $field: '$stamped' != '$actual'" >&2
    exit 1
  fi
}

require_stamp_match ARCH "$STAMP_ARCH" "$LINUX_MAKE_ARCH"
require_stamp_match LINUX_PLATFORM "$STAMP_LINUX_PLATFORM" "$PLATFORM"
require_stamp_match OPENSBI_PROFILE "$STAMP_PROFILE" "$PROFILE"
require_stamp_match OPENSBI_ROOT "$STAMP_ROOT" "$ROOT"
require_stamp_match OPENSBI_REF "$STAMP_REF" "$REF"
require_stamp_match OPENSBI_NPC_PATCH "$STAMP_NPC_PATCH" "$NPC_PATCH"
require_stamp_match CROSS_COMPILE "$STAMP_CROSS_COMPILE" "$CROSS_COMPILE"
require_stamp_match PLATFORM "$STAMP_PLATFORM" "$SBI_PLATFORM"
require_stamp_match FW_JUMP_ADDR "$STAMP_FW_JUMP_ADDR" "$FW_JUMP_ADDR"
require_stamp_match FW_JUMP_FDT_ADDR "$STAMP_FW_JUMP_FDT_ADDR" "$FW_JUMP_FDT_ADDR"
require_stamp_match OPENSBI_DTB "$STAMP_DTB" "$DTB"
require_stamp_match OPENSBI_DISABLE_PMU "$STAMP_DISABLE_PMU" "$DISABLE_PMU"
require_stamp_match OPENSBI_BUILD_DIR "$STAMP_BUILD_DIR" "$BUILD_DIR_REQUESTED"

SCRIPT_SHA256=$(sha256sum -- "${BASH_SOURCE[0]}" | awk '{print $1}')
PATCH_SHA256=absent
DTB_SHA256=
PATCH_SNAPSHOT=
DTB_SNAPSHOT=
PATCH_STATE=
PATCH_REQUESTED=0
PATCH_EXPECTED=
profile_tmp=
source_expected_index=
source_actual_index=
legacy_defconfig_tmp=
nopmu_defconfig_tmp=
python_cache_tmp=
SOURCE_BASE_COMMIT=
SOURCE_EXPECTED_TREE=
cleanup_transaction_temps() {
  local status=$?
  trap - EXIT HUP INT TERM
  rm -f -- "${PATCH_SNAPSHOT:-}" "${DTB_SNAPSHOT:-}" "${profile_tmp:-}"
  rm -f -- "${legacy_defconfig_tmp:-}" "${nopmu_defconfig_tmp:-}"
  if [[ -n ${python_cache_tmp:-} ]]; then
    case "$python_cache_tmp" in
      "$BUILD_DIR"/.opensbi-python-cache.*)
        rm -rf -- "$python_cache_tmp"
        ;;
      *)
        echo "[opensbi] refusing unsafe Python cache cleanup path: $python_cache_tmp" >&2
        ;;
    esac
  fi
  if [[ -n ${source_expected_index:-} ]]; then
    rm -f -- "$source_expected_index" "$source_expected_index.lock"
  fi
  if [[ -n ${source_actual_index:-} ]]; then
    rm -f -- "$source_actual_index" "$source_actual_index.lock"
  fi
  exit "$status"
}
trap cleanup_transaction_temps EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

PATCH_STATE=$DERIVED_PATCH_STATE
PATCH_STATE_DIR=$SOURCE_STATE_DIR
if [[ -L $PATCH_STATE || ( -e $PATCH_STATE && ! -f $PATCH_STATE ) ]]; then
  echo "[opensbi] unsafe recorded patch state: $PATCH_STATE" >&2
  exit 1
fi
if [[ -e $NPC_PATCH && ! -f $NPC_PATCH ]]; then
  echo "[opensbi] patch input is not a regular file: $NPC_PATCH" >&2
  exit 1
fi
if [[ -f $NPC_PATCH ]]; then
  PATCH_REQUESTED=1
  PATCH_SNAPSHOT=$(mktemp "$PATCH_STATE_DIR/.opensbi-patch-input.tmp.XXXXXX")
  cp -- "$NPC_PATCH" "$PATCH_SNAPSHOT"
  PATCH_EXPECTED=$PATCH_SNAPSHOT
  sync -f "$PATCH_SNAPSHOT"
  PATCH_SHA256=$(sha256sum -- "$PATCH_SNAPSHOT" | awk '{print $1}')
fi

make_linux_dtb() {
  local make_args=()
  if [ -n "$LINUX_MAKE_ARCH" ]; then
    make_args+=(ARCH="$LINUX_MAKE_ARCH")
  fi
  env -u OPENSBI_DTB -u OPENSBI_BUILD_DIR make -C "$LINUX_HOME" \
    "${make_args[@]}" "$@"
}

if [[ ! -s $DTB ]]; then
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
fi
if [[ ! -f $DTB || ! -s $DTB ]]; then
  echo "[opensbi] missing or empty DTB input: $DTB" >&2
  exit 1
fi

# build-dtb.sh publishes by atomic rename.  Lock the same canonical path and
# existing inode identities before taking the firmware snapshot, and retain the
# locks until firmware/profile publication.  A raw inode lock alone would not
# serialize a path replacement.
if [[ -L $DTB || ! -f $DTB ]]; then
  echo "[opensbi] DTB input is not a regular non-symlink file: $DTB" >&2
  exit 1
fi
DTB_PARENT=$(realpath -e -- "$(dirname -- "$DTB")")
DTB_CANONICAL="$DTB_PARENT/$(basename -- "$DTB")"
[[ $(realpath -e -- "$DTB") == "$DTB_CANONICAL" ]] || {
  echo "[opensbi] DTB canonical path changed before locking: $DTB" >&2
  exit 1
}
DTB_ORIGINAL_DEV_INO=$(stat -Lc '%d:%i' -- "$DTB_CANONICAL")

DTB_LOCK_ROOT="/tmp/ysyx-linux-dtb-locks-$(id -u)"
if [[ -L $DTB_LOCK_ROOT ||
      ( -e $DTB_LOCK_ROOT && ! -d $DTB_LOCK_ROOT ) ]]; then
  echo "[opensbi] unsafe global DTB lock directory: $DTB_LOCK_ROOT" >&2
  exit 1
fi
if [[ ! -d $DTB_LOCK_ROOT ]]; then
  old_umask=$(umask)
  umask 077
  mkdir "$DTB_LOCK_ROOT" 2>/dev/null || true
  umask "$old_umask"
fi
[[ -d $DTB_LOCK_ROOT && ! -L $DTB_LOCK_ROOT ]] || {
  echo "[opensbi] cannot create safe global DTB lock directory: $DTB_LOCK_ROOT" >&2
  exit 1
}
[[ $(stat -Lc '%u' -- "$DTB_LOCK_ROOT") == $(id -u) ]] || {
  echo "[opensbi] global DTB lock directory is not owned by current uid" >&2
  exit 1
}
DTB_LOCK_ROOT=$(realpath -e -- "$DTB_LOCK_ROOT")

declare -a DTB_LOCK_PATHS=()
mapfile -t DTB_LOCK_PATHS < <(
  for identity in \
      "path:$DTB_CANONICAL" "inode:$DTB_ORIGINAL_DEV_INO"; do
    key=$(printf '%s\0' "$identity" | sha256sum | awk '{print $1}')
    printf '%s/%s.lock\n' "$DTB_LOCK_ROOT" "$key"
  done | LC_ALL=C sort -u
)
for lock_path in "${DTB_LOCK_PATHS[@]}"; do
  if [[ -L $lock_path || ( -e $lock_path && ! -f $lock_path ) ||
        ( -e $lock_path && $lock_path -ef $DTB_CANONICAL ) ]]; then
    echo "[opensbi] unsafe DTB transaction lock: $lock_path" >&2
    exit 1
  fi
done
declare -a DTB_LOCK_FDS=()
for lock_path in "${DTB_LOCK_PATHS[@]}"; do
  exec {dtb_lock_fd}>>"$lock_path"
  flock "$dtb_lock_fd"
  DTB_LOCK_FDS+=("$dtb_lock_fd")
done

dtb_input_still_matches() {
  [[ ! -L $DTB && -f $DTB && -s $DTB ]] &&
    [[ $(realpath -e -- "$DTB") == "$DTB_CANONICAL" ]] &&
    [[ $(stat -Lc '%d:%i' -- "$DTB") == "$DTB_ORIGINAL_DEV_INO" ]] &&
    [[ $(sha256sum -- "$DTB" | awk '{print $1}') == "$DTB_SHA256" ]]
}

# Paths may have changed while this transaction waited for another publisher.
[[ ! -L $DTB && -f $DTB && -s $DTB ]] &&
  [[ $(realpath -e -- "$DTB") == "$DTB_CANONICAL" ]] &&
  [[ $(stat -Lc '%d:%i' -- "$DTB") == "$DTB_ORIGINAL_DEV_INO" ]] || {
    echo "[opensbi] DTB input changed while waiting for its transaction lock" >&2
    exit 1
  }
DTB_SNAPSHOT=$(mktemp "$BUILD_DIR/.ysyx-opensbi-dtb.tmp.XXXXXX")
cp -- "$DTB" "$DTB_SNAPSHOT"
sync -f "$DTB_SNAPSHOT"
DTB_SHA256=$(sha256sum -- "$DTB_SNAPSHOT" | awk '{print $1}')
dtb_input_still_matches || {
  echo "[opensbi] DTB changed while creating firmware snapshot" >&2
  exit 1
}

write_profile_payload() {
  local output=$1 firmware_sha256=$2
  printf '%s\n' \
    "ARCH=$STAMP_ARCH" \
    "LINUX_PLATFORM=$STAMP_LINUX_PLATFORM" \
    "OPENSBI_PROFILE=$STAMP_PROFILE" \
    "OPENSBI_ROOT=$STAMP_ROOT" \
    "OPENSBI_REF=$STAMP_REF" \
    "OPENSBI_NPC_PATCH=$STAMP_NPC_PATCH" \
    "OPENSBI_NPC_PATCH_SHA256=$PATCH_SHA256" \
    "OPENSBI_SOURCE_COMMIT=$SOURCE_BASE_COMMIT" \
    "OPENSBI_SOURCE_TREE=$SOURCE_EXPECTED_TREE" \
    "CROSS_COMPILE=$STAMP_CROSS_COMPILE" \
    "PLATFORM=$STAMP_PLATFORM" \
    "FW_JUMP_ADDR=$STAMP_FW_JUMP_ADDR" \
    "FW_JUMP_FDT_ADDR=$STAMP_FW_JUMP_FDT_ADDR" \
    "OPENSBI_DTB=$STAMP_DTB" \
    "OPENSBI_DTB_SHA256=$DTB_SHA256" \
    "OPENSBI_DISABLE_PMU=$STAMP_DISABLE_PMU" \
    "OPENSBI_BUILD_DIR=$STAMP_BUILD_DIR" \
    "OPENSBI_BUILD_SCRIPT_SHA256=$SCRIPT_SHA256" \
    "OPENSBI_FIRMWARE_SHA256=$firmware_sha256" > "$output"
}

cleanup_source_indexes() {
  if [[ -n ${source_expected_index:-} ]]; then
    rm -f -- "$source_expected_index" "$source_expected_index.lock"
    source_expected_index=
  fi
  if [[ -n ${source_actual_index:-} ]]; then
    rm -f -- "$source_actual_index" "$source_actual_index.lock"
    source_actual_index=
  fi
}

SOURCE_MISMATCH_REASON=
source_matches_target() {
  local source_top desired_commit head_commit expected_tree actual_tree untracked_path
  SOURCE_MISMATCH_REASON=
  SOURCE_BASE_COMMIT=
  SOURCE_EXPECTED_TREE=
  if [[ ! -d $ROOT/.git ]]; then
    SOURCE_MISMATCH_REASON="source is not a root-owned git checkout"
    return 1
  fi
  source_top=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null) || {
    SOURCE_MISMATCH_REASON="source git metadata is unreadable"
    return 1
  }
  if [[ $(realpath -e -- "$source_top") != "$ROOT_CANONICAL" ]]; then
    SOURCE_MISMATCH_REASON="source is nested inside a different git checkout"
    return 1
  fi
  desired_commit=$(git -C "$ROOT" rev-parse --verify "$REF^{commit}" 2>/dev/null) || {
    SOURCE_MISMATCH_REASON="requested ref is not available locally"
    return 1
  }
  head_commit=$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null) || {
    SOURCE_MISMATCH_REASON="source HEAD is unreadable"
    return 1
  }
  if [[ $head_commit != "$desired_commit" ]]; then
    SOURCE_MISMATCH_REASON="source HEAD does not match OPENSBI_REF=$REF"
    return 1
  fi
  if (( PATCH_REQUESTED )); then
    if [[ ! -s $PATCH_STATE ]] || ! cmp -s "$PATCH_EXPECTED" "$PATCH_STATE"; then
      SOURCE_MISMATCH_REASON="recorded patch bytes do not match requested patch"
      return 1
    fi
  elif [[ -e $PATCH_STATE ]]; then
    SOURCE_MISMATCH_REASON="recorded patch state exists but no patch is requested"
    return 1
  fi
  if ! git -C "$ROOT" diff --cached --quiet "$desired_commit" --; then
    SOURCE_MISMATCH_REASON="source index contains staged changes"
    return 1
  fi

  source_expected_index=$(mktemp "$SOURCE_STATE_DIR/.opensbi-expected-index.tmp.XXXXXX")
  source_actual_index=$(mktemp "$SOURCE_STATE_DIR/.opensbi-actual-index.tmp.XXXXXX")
  rm -f -- "$source_expected_index" "$source_actual_index"
  if ! GIT_INDEX_FILE="$source_expected_index" git -C "$ROOT" read-tree "$desired_commit"; then
    SOURCE_MISMATCH_REASON="cannot construct expected source index"
    cleanup_source_indexes
    return 1
  fi
  if (( PATCH_REQUESTED )); then
    if ! GIT_INDEX_FILE="$source_expected_index" git -C "$ROOT" \
        apply --cached --check "$PATCH_STATE" >/dev/null 2>&1 ||
       ! GIT_INDEX_FILE="$source_expected_index" git -C "$ROOT" \
        apply --cached "$PATCH_STATE" >/dev/null 2>&1; then
      SOURCE_MISMATCH_REASON="recorded patch does not describe the requested ref"
      cleanup_source_indexes
      return 1
    fi
  fi
  expected_tree=$(GIT_INDEX_FILE="$source_expected_index" \
    git -C "$ROOT" write-tree 2>/dev/null) || {
    SOURCE_MISMATCH_REASON="cannot hash expected source tree"
    cleanup_source_indexes
    return 1
  }
  if ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" read-tree "$desired_commit" ||
     ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" add -A -- .; then
    SOURCE_MISMATCH_REASON="cannot hash current source worktree"
    cleanup_source_indexes
    return 1
  fi
  # OpenSBI's Python Kconfig helper historically left bytecode next to its
  # sources.  It is neither a build input nor part of the requested tree; only
  # untracked .pyc files in this exact cache directory are excluded.
  while IFS= read -r -d '' untracked_path; do
    case "$untracked_path" in
      scripts/Kconfiglib/__pycache__/*.pyc)
        if ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" \
            update-index --force-remove -- "$untracked_path"; then
          SOURCE_MISMATCH_REASON="cannot exclude generated Python bytecode"
          cleanup_source_indexes
          return 1
        fi
        ;;
    esac
  done < <(git -C "$ROOT" ls-files --others --exclude-standard -z)
  actual_tree=$(GIT_INDEX_FILE="$source_actual_index" \
    git -C "$ROOT" write-tree 2>/dev/null) || {
    SOURCE_MISMATCH_REASON="cannot hash current source tree"
    cleanup_source_indexes
    return 1
  }
  cleanup_source_indexes
  if [[ $actual_tree != "$expected_tree" ]]; then
    SOURCE_MISMATCH_REASON="source worktree has unexpected tracked or untracked changes"
    return 1
  fi
  SOURCE_BASE_COMMIT=$desired_commit
  SOURCE_EXPECTED_TREE=$expected_tree
  return 0
}

profile_stamp_has_one_firmware_hash() {
  [[ -f $PROFILE_STAMP ]] &&
    [[ $(grep -Ec '^OPENSBI_FIRMWARE_SHA256=[0-9a-f]{64}$' "$PROFILE_STAMP") -eq 1 ]] &&
    [[ $(grep -Ec '^OPENSBI_SOURCE_COMMIT=[0-9a-f]{40,64}$' "$PROFILE_STAMP") -eq 1 ]] &&
    [[ $(grep -Ec '^OPENSBI_SOURCE_TREE=[0-9a-f]{40,64}$' "$PROFILE_STAMP") -eq 1 ]]
}

FORCE_ARTIFACT_REBUILD=0
if [[ -n $PROFILE_STAMP ]]; then
  mkdir -p "$(dirname -- "$PROFILE_STAMP")"
  profile_tmp=$(mktemp "$(dirname -- "$PROFILE_STAMP")/.$(basename -- "$PROFILE_STAMP").tmp.XXXXXX")
  if [[ -s $FIRMWARE ]]; then
    if source_matches_target; then
      FIRMWARE_SHA256=$(sha256sum -- "$FIRMWARE" | awk '{print $1}')
      write_profile_payload "$profile_tmp" "$FIRMWARE_SHA256"
      sync -f "$profile_tmp"
      if profile_stamp_has_one_firmware_hash &&
         cmp -s "$profile_tmp" "$PROFILE_STAMP" && dtb_input_still_matches; then
        echo "[opensbi] profile, source and firmware are current: $FIRMWARE"
        exit 0
      fi
    else
      echo "[opensbi] cached firmware is not reusable: $SOURCE_MISMATCH_REASON"
    fi
  fi
  FORCE_ARTIFACT_REBUILD=1
fi

if [ ! -d "$ROOT/.git" ]; then
  git clone https://github.com/riscv-software-src/opensbi.git "$ROOT"
fi

render_nopmu_defconfig() {
  local input=$1 output=$2
  cp -- "$input" "$output"
  sed -i 's/^CONFIG_SBI_ECALL_PMU=y/# CONFIG_SBI_ECALL_PMU is not set/' "$output"
  if ! grep -q '^# CONFIG_SBI_ECALL_PMU is not set$' "$output"; then
    printf '\n# CONFIG_SBI_ECALL_PMU is not set\n' >> "$output"
  fi
}

cleanup_legacy_nopmu_defconfig() {
  local legacy_rel="platform/$SBI_PLATFORM/configs/ysyx_nopmu_defconfig"
  local legacy_path="$ROOT/$legacy_rel"
  [[ -e $legacy_path || -L $legacy_path ]] || return 0
  # Never remove a path owned by the requested OpenSBI revision.  For the
  # legacy untracked file, remove it only when its bytes exactly equal what the
  # older version of this script generated; any user-modified file stays and
  # is rejected by the source-tree proof below.
  if git -C "$ROOT" ls-files --error-unmatch -- "$legacy_rel" >/dev/null 2>&1 ||
     [[ -L $legacy_path || ! -f $legacy_path ]]; then
    return 0
  fi
  legacy_defconfig_tmp=$(mktemp "$SOURCE_STATE_DIR/.opensbi-legacy-defconfig.tmp.XXXXXX")
  render_nopmu_defconfig "$ROOT/platform/$SBI_PLATFORM/configs/defconfig" \
    "$legacy_defconfig_tmp"
  if cmp -s "$legacy_defconfig_tmp" "$legacy_path"; then
    rm -f -- "$legacy_path"
  fi
  rm -f -- "$legacy_defconfig_tmp"
  legacy_defconfig_tmp=
}

restore_recorded_patch() {
  local recorded_patch=$1
  if git -C "$ROOT" apply --reverse --check "$recorded_patch" >/dev/null 2>&1; then
    git -C "$ROOT" apply --reverse "$recorded_patch"
    echo "[opensbi] removed previously recorded patch before source refresh"
  elif git -C "$ROOT" apply --check "$recorded_patch" >/dev/null 2>&1; then
    :
  else
    echo "[opensbi] source matches neither baseline nor recorded patch; refusing to overwrite local changes" >&2
    exit 1
  fi
}

if [[ -s $PATCH_STATE ]]; then
  restore_recorded_patch "$PATCH_STATE"
elif [[ -n $PATCH_SNAPSHOT ]] &&
     git -C "$ROOT" apply --reverse --check "$PATCH_SNAPSHOT" >/dev/null 2>&1; then
  git -C "$ROOT" apply --reverse "$PATCH_SNAPSHOT"
  echo "[opensbi] removed legacy untracked patch before source refresh"
fi

if git -C "$ROOT" rev-parse --verify -q "$REF^{commit}" >/dev/null; then
  echo "[opensbi] using local ref: $REF"
else
  git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
fi
git -C "$ROOT" checkout -q "$REF"

if [[ -n $PATCH_SNAPSHOT ]]; then
  if ! git -C "$ROOT" apply --check "$PATCH_SNAPSHOT" >/dev/null 2>&1; then
    echo "[opensbi] requested patch does not apply cleanly to OPENSBI_REF=$REF" >&2
    exit 1
  fi
  # Publish the exact desired patch bytes while the source is at baseline,
  # then apply only from that durable state.  If interrupted on either side
  # of apply, the next transaction can classify source as baseline (forward
  # applies) or patched (reverse applies) using the matching recorded bytes.
  mv -fT -- "$PATCH_SNAPSHOT" "$PATCH_STATE"
  PATCH_EXPECTED=$PATCH_STATE
  PATCH_SNAPSHOT=
  sync -f "$PATCH_STATE_DIR"
  if ! git -C "$ROOT" apply --check "$PATCH_STATE" >/dev/null 2>&1; then
    echo "[opensbi] published patch state no longer matches the source baseline" >&2
    exit 1
  fi
  git -C "$ROOT" apply "$PATCH_STATE"
  echo "[opensbi] applied npc patch: $NPC_PATCH ($PATCH_SHA256)"
else
  rm -f -- "$PATCH_STATE"
  sync -f "$PATCH_STATE_DIR"
fi

cleanup_legacy_nopmu_defconfig
if ! source_matches_target; then
  echo "[opensbi] normalized source does not match target profile: $SOURCE_MISMATCH_REASON" >&2
  exit 1
fi
if (( FORCE_ARTIFACT_REBUILD )); then
  rm -f -- "$FIRMWARE"
fi

if [ "$DISABLE_PMU" = "1" ]; then
  # OpenSBI 的 make 会从 PLATFORM_DEFCONFIG 重新生成 .config；
  # 因此 no-PMU 必须改输入 defconfig，不能只在生成后的 .config 上 sed。
  # 生成文件放在 canonical O= 下，并通过相对路径交给 OpenSBI Makefile，
  # 避免一次成功构建把共享源码永久留在 dirty 状态。
  if [[ -L $NOPMU_DEFCONFIG_OUTPUT ||
        ( -e $NOPMU_DEFCONFIG_OUTPUT && ! -f $NOPMU_DEFCONFIG_OUTPUT ) ]]; then
    echo "[opensbi] unsafe generated no-PMU defconfig: $NOPMU_DEFCONFIG_OUTPUT" >&2
    exit 1
  fi
  nopmu_defconfig_tmp=$(mktemp "$BUILD_DIR/.ysyx-opensbi-nopmu-defconfig.tmp.XXXXXX")
  render_nopmu_defconfig "$ROOT/platform/$SBI_PLATFORM/configs/defconfig" \
    "$nopmu_defconfig_tmp"
  sync -f "$nopmu_defconfig_tmp"
  mv -fT -- "$nopmu_defconfig_tmp" "$NOPMU_DEFCONFIG_OUTPUT"
  nopmu_defconfig_tmp=
  sync -f "$BUILD_DIR"
  PLATFORM_DEFCONFIG=$(realpath --relative-to="$ROOT/platform/$SBI_PLATFORM/configs" \
    -- "$NOPMU_DEFCONFIG_OUTPUT")
  echo "[opensbi] CONFIG_SBI_ECALL_PMU disabled via $PLATFORM_DEFCONFIG"
fi

make_args=(
  -C "$ROOT"
  O="$BUILD_DIR"
  PLATFORM="$SBI_PLATFORM"
  CROSS_COMPILE="$CROSS_COMPILE"
  PLATFORM_DEFCONFIG="$PLATFORM_DEFCONFIG"
  FW_FDT_PATH="$DTB_SNAPSHOT"
  FW_JUMP_ADDR="$FW_JUMP_ADDR"
)
if [ -n "$FW_JUMP_FDT_ADDR" ]; then
  make_args+=(FW_JUMP_FDT_ADDR="$FW_JUMP_FDT_ADDR")
fi
# A profile mismatch may be caused by DTB contents or command-line-only build
# inputs whose path/mtime does not change.  OpenSBI is small enough to force
# this transaction, ensuring the firmware really consumes the stamped bytes.
# PYTHONDONTWRITEBYTECODE only prevents writes; Python would still load a stale
# or replaced source-adjacent .pyc.  Redirect cache lookup to a fresh private
# directory so excluded Kconfiglib bytecode can never influence the firmware.
python_cache_tmp=$(mktemp -d "$BUILD_DIR/.opensbi-python-cache.XXXXXX")
PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="$python_cache_tmp" \
  make "${make_args[@]}" -B -j"$JOBS"
rm -rf -- "$python_cache_tmp"
python_cache_tmp=

if [[ -L $FIRMWARE || ! -f $FIRMWARE || ! -s $FIRMWARE ]]; then
  echo "[opensbi] build completed without non-empty firmware: $FIRMWARE" >&2
  exit 1
fi
if ! source_matches_target; then
  echo "[opensbi] source changed during build; refusing success stamp: $SOURCE_MISMATCH_REASON" >&2
  exit 1
fi
if ! dtb_input_still_matches; then
  echo "[opensbi] DTB changed during firmware build; refusing success stamp" >&2
  exit 1
fi
# Keep target freshness and the profile claim in the same critical section.
touch -- "$FIRMWARE"
sync -f "$FIRMWARE"
FIRMWARE_SHA256=$(sha256sum -- "$FIRMWARE" | awk '{print $1}')
if [[ -n $PROFILE_STAMP ]]; then
  write_profile_payload "$profile_tmp" "$FIRMWARE_SHA256"
  sync -f "$profile_tmp"
  if cmp -s "$profile_tmp" "$PROFILE_STAMP"; then
    rm -f -- "$profile_tmp"
  else
    mv -fT -- "$profile_tmp" "$PROFILE_STAMP"
    sync -f "$(dirname -- "$PROFILE_STAMP")"
  fi
  profile_tmp=
fi
trap - EXIT HUP INT TERM

echo "[opensbi] build dir: $BUILD_DIR (requested $BUILD_DIR_REQUESTED)"
echo "[opensbi] fw_jump.bin: $FIRMWARE"
echo "[opensbi] embedded dtb: $DTB"
if [ -n "$FW_JUMP_FDT_ADDR" ]; then
  echo "[opensbi] next-stage dtb address: $FW_JUMP_FDT_ADDR"
fi
