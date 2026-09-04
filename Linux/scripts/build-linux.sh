#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LINUX_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
ENV_ROOT=${YSYX_LINUX_ENV_ROOT:-"$LINUX_HOME/env"}
LOCAL_LINUX_PREFIX="$ENV_ROOT/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-"
if [ -x "${LOCAL_LINUX_PREFIX}gcc" ]; then
  DEFAULT_CROSS_COMPILE="$LOCAL_LINUX_PREFIX"
else
  DEFAULT_CROSS_COMPILE="riscv64-linux-gnu-"
fi

ROOT=${LINUX_ROOT:-"$ENV_ROOT/src/linux"}
PLATFORM=${LINUX_PLATFORM:-shared}
BUILD_DIR=${LINUX_BUILD_DIR:-"$ENV_ROOT/platforms/$PLATFORM/build/linux"}
REF=${LINUX_REF:-v6.6}
LINUX_PATCH=${LINUX_PATCH:-"$LINUX_HOME/patches/linux-skip-riscv-unaligned-benchmark.patch"}
CROSS_COMPILE=${CROSS_COMPILE:-$DEFAULT_CROSS_COMPILE}
JOBS=${JOBS:-$(nproc)}
FEATURE_PROFILE=${LINUX_FEATURE_PROFILE:-headless}
PROFILE_STAMP=${LINUX_FEATURE_PROFILE_STAMP:-}
STAMP_PLATFORM=${LINUX_STAMP_PLATFORM:-$PLATFORM}
STAMP_FEATURE_PROFILE=${LINUX_STAMP_FEATURE_PROFILE:-$FEATURE_PROFILE}
STAMP_ROOT=${LINUX_STAMP_ROOT:-$ROOT}
STAMP_REF=${LINUX_STAMP_REF:-$REF}
STAMP_PATCH=${LINUX_STAMP_PATCH:-$LINUX_PATCH}
STAMP_CROSS_COMPILE=${LINUX_STAMP_CROSS_COMPILE:-$CROSS_COMPILE}
STAMP_BUILD_DIR=${LINUX_STAMP_BUILD_DIR:-$BUILD_DIR}
VERSION=${REF#v}
TARBALL=${LINUX_TARBALL:-"$ENV_ROOT/downloads/linux-$VERSION.tar.xz"}
TARBALL_URL=${LINUX_TARBALL_URL:-https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$VERSION.tar.xz}
TREE_ID_HELPER="$SCRIPT_DIR/source-tree-id.py"

for host_tool in cmp curl flock git id mktemp patch python3 realpath sha256sum sort stat sync tar; do
  command -v "$host_tool" >/dev/null 2>&1 || {
    echo "[linux] missing host tool: $host_tool" >&2
    exit 1
  }
done
[[ -f $TREE_ID_HELPER && ! -L $TREE_ID_HELPER ]] || {
  echo "[linux] missing or unsafe source-tree identity helper: $TREE_ID_HELPER" >&2
  exit 1
}
mkdir -p "$ENV_ROOT/src" "$BUILD_DIR"

# The O= directory is a single mutable object graph.  Serialize every writer
# using a lock selected from its canonical path, so symlink aliases cannot
# bypass the profile/build transaction.
BUILD_DIR_REQUESTED=$BUILD_DIR
BUILD_DIR=$(realpath -e -- "$BUILD_DIR")
if [[ $BUILD_DIR == / ]]; then
  echo "[linux] refusing filesystem root as build dir" >&2
  exit 1
fi
LINUX_IMAGE="$BUILD_DIR/arch/riscv/boot/Image"
EXPECTED_IMAGE=$(realpath -m -- "${LINUX_EXPECTED_IMAGE:-$LINUX_IMAGE}")
if [[ $EXPECTED_IMAGE != "$LINUX_IMAGE" ]]; then
  echo "[linux] Make target does not match canonical Image output: $EXPECTED_IMAGE != $LINUX_IMAGE" >&2
  exit 1
fi
LINUX_BUILD_LOCK="$BUILD_DIR/.ysyx-build.lock"
if [[ -L $LINUX_BUILD_LOCK ||
      ( -e $LINUX_BUILD_LOCK && ! -f $LINUX_BUILD_LOCK ) ]]; then
  echo "[linux] unsafe build lock: $LINUX_BUILD_LOCK" >&2
  exit 1
fi
if [[ -e $LINUX_BUILD_LOCK && -e $LINUX_IMAGE &&
      $LINUX_BUILD_LOCK -ef $LINUX_IMAGE ]]; then
  echo "[linux] build lock aliases Image: $LINUX_BUILD_LOCK" >&2
  exit 1
fi
exec 8>>"$LINUX_BUILD_LOCK"
flock 8

if [[ -n $PROFILE_STAMP ]]; then
  if [[ -L $PROFILE_STAMP ]]; then
    echo "[linux] unsafe profile stamp symlink: $PROFILE_STAMP" >&2
    exit 1
  fi
  PROFILE_STAMP_REAL=$(realpath -m -- "$PROFILE_STAMP")
  EXPECTED_PROFILE_STAMP="$BUILD_DIR/.ysyx-feature-profile"
  case "$PROFILE_STAMP_REAL" in
    "$BUILD_DIR"/*) ;;
    *)
      echo "[linux] profile stamp must stay inside canonical build dir: $PROFILE_STAMP" >&2
      exit 1
      ;;
  esac
  if [[ $PROFILE_STAMP_REAL != "$EXPECTED_PROFILE_STAMP" ]]; then
    echo "[linux] profile stamp must be the canonical build-dir stamp: $EXPECTED_PROFILE_STAMP" >&2
    exit 1
  fi
  PROFILE_STAMP=$PROFILE_STAMP_REAL
  if [[ -e $PROFILE_STAMP && ! -f $PROFILE_STAMP ]]; then
    echo "[linux] unsafe profile stamp: $PROFILE_STAMP" >&2
    exit 1
  fi
  if [[ $PROFILE_STAMP == "$LINUX_IMAGE" ||
        $PROFILE_STAMP == "$LINUX_BUILD_LOCK" ||
        ( -e $PROFILE_STAMP && -e $LINUX_IMAGE && $PROFILE_STAMP -ef $LINUX_IMAGE ) ||
        ( -e $PROFILE_STAMP && -e $LINUX_BUILD_LOCK && $PROFILE_STAMP -ef $LINUX_BUILD_LOCK ) ]]; then
    echo "[linux] profile stamp aliases a build artifact/lock: $PROFILE_STAMP" >&2
    exit 1
  fi
fi
if [[ -L $LINUX_IMAGE || ( -e $LINUX_IMAGE && ! -f $LINUX_IMAGE ) ]]; then
  echo "[linux] unsafe Image output: $LINUX_IMAGE" >&2
  exit 1
fi

# clone/fetch/checkout/patch 都会改共享 source。锁覆盖完整 O= build 生命周期，
# 防止另一个 profile 在编译器读取源码时 checkout 或 patch 同一棵树。
ROOT_CANONICAL=$(realpath -m -- "$ROOT")
if [[ -L $ROOT ]]; then
  echo "[linux] source root must not be a symbolic link: $ROOT" >&2
  exit 1
fi
ROOT_KEY=$(printf '%s\0' "$ROOT_CANONICAL" | sha256sum | awk '{print $1}')
SOURCE_STATE_BASE="$(dirname -- "$ROOT_CANONICAL")/.ysyx-source-state"
if [[ -L $SOURCE_STATE_BASE ||
      ( -e $SOURCE_STATE_BASE && ! -d $SOURCE_STATE_BASE ) ]]; then
  echo "[linux] unsafe source-state directory: $SOURCE_STATE_BASE" >&2
  exit 1
fi
mkdir -p "$SOURCE_STATE_BASE"
SOURCE_STATE_DIR="$SOURCE_STATE_BASE/$ROOT_KEY"
if [[ -L $SOURCE_STATE_DIR ||
      ( -e $SOURCE_STATE_DIR && ! -d $SOURCE_STATE_DIR ) ]]; then
  echo "[linux] unsafe source-state identity directory: $SOURCE_STATE_DIR" >&2
  exit 1
fi
mkdir -p "$SOURCE_STATE_DIR"
SOURCE_STATE_DIR=$(realpath -e -- "$SOURCE_STATE_DIR")
TARBALL_SOURCE_STATE="$SOURCE_STATE_DIR/linux-tarball-source.profile"
DERIVED_SOURCE_LOCK="$SOURCE_STATE_DIR/source.lock"
if [[ -n ${LINUX_SOURCE_LOCK:-} &&
      $(realpath -m -- "$LINUX_SOURCE_LOCK") != "$DERIVED_SOURCE_LOCK" ]]; then
  echo "[linux] LINUX_SOURCE_LOCK must be derived from canonical LINUX_ROOT: $DERIVED_SOURCE_LOCK" >&2
  exit 1
fi
LINUX_SOURCE_LOCK=$DERIVED_SOURCE_LOCK
if [[ -L $LINUX_SOURCE_LOCK ||
      ( -e $LINUX_SOURCE_LOCK && ! -f $LINUX_SOURCE_LOCK ) ]]; then
  echo "[linux] unsafe source lock: $LINUX_SOURCE_LOCK" >&2
  exit 1
fi
LINUX_SOURCE_LOCK=$(realpath -m -- "$LINUX_SOURCE_LOCK")
if [[ $LINUX_SOURCE_LOCK == "$LINUX_BUILD_LOCK" ||
      $LINUX_SOURCE_LOCK == "$LINUX_IMAGE" ||
      ( -n $PROFILE_STAMP && $LINUX_SOURCE_LOCK == "$PROFILE_STAMP" ) ||
      ( -e $LINUX_SOURCE_LOCK && -e $LINUX_BUILD_LOCK && $LINUX_SOURCE_LOCK -ef $LINUX_BUILD_LOCK ) ||
      ( -e $LINUX_SOURCE_LOCK && -e $LINUX_IMAGE && $LINUX_SOURCE_LOCK -ef $LINUX_IMAGE ) ||
      ( -n $PROFILE_STAMP && -e $LINUX_SOURCE_LOCK && -e $PROFILE_STAMP &&
        $LINUX_SOURCE_LOCK -ef $PROFILE_STAMP ) ]]; then
  echo "[linux] source lock aliases a build artifact/profile lock" >&2
  exit 1
fi
exec 9>>"$LINUX_SOURCE_LOCK"
flock 9

# A caller may intentionally share LINUX_TARBALL between otherwise independent
# source/build roots.  Serialize by both canonical path and the current inode:
# the path identity covers atomic replacement, while the inode identity closes
# hard-link aliases that spell the same existing archive differently.
TARBALL_PARENT_REQUESTED=$(dirname -- "$TARBALL")
TARBALL_BASENAME=$(basename -- "$TARBALL")
if [[ $TARBALL_BASENAME == . || $TARBALL_BASENAME == .. ]]; then
  echo "[linux] unsafe source tarball name: $TARBALL" >&2
  exit 1
fi
mkdir -p -- "$TARBALL_PARENT_REQUESTED"
TARBALL_PARENT=$(realpath -e -- "$TARBALL_PARENT_REQUESTED")
TARBALL="$TARBALL_PARENT/$TARBALL_BASENAME"
if [[ -L $TARBALL || ( -e $TARBALL && ! -f $TARBALL ) ]]; then
  echo "[linux] unsafe source tarball: $TARBALL" >&2
  exit 1
fi
case "$TARBALL" in
  "$ROOT_CANONICAL"|"$ROOT_CANONICAL"/*)
    echo "[linux] source tarball must stay outside the source root: $TARBALL" >&2
    exit 1
    ;;
esac
for protected_path in \
    "$LINUX_IMAGE" "$LINUX_BUILD_LOCK" "$LINUX_SOURCE_LOCK" \
    "$TREE_ID_HELPER" "$LINUX_PATCH" ${PROFILE_STAMP:+"$PROFILE_STAMP"}; do
  if [[ $(realpath -m -- "$protected_path") == "$TARBALL" ||
        ( -e $protected_path && -e $TARBALL && $protected_path -ef $TARBALL ) ]]; then
    echo "[linux] source tarball aliases a protected input/output: $protected_path" >&2
    exit 1
  fi
done

TARBALL_LOCK_ROOT="/tmp/ysyx-linux-tarball-locks-$(id -u)"
if [[ -L $TARBALL_LOCK_ROOT ||
      ( -e $TARBALL_LOCK_ROOT && ! -d $TARBALL_LOCK_ROOT ) ]]; then
  echo "[linux] unsafe global tarball lock directory: $TARBALL_LOCK_ROOT" >&2
  exit 1
fi
if [[ ! -d $TARBALL_LOCK_ROOT ]]; then
  old_umask=$(umask)
  umask 077
  mkdir "$TARBALL_LOCK_ROOT" 2>/dev/null || true
  umask "$old_umask"
fi
if [[ ! -d $TARBALL_LOCK_ROOT || -L $TARBALL_LOCK_ROOT ||
      $(stat -Lc '%u' -- "$TARBALL_LOCK_ROOT") != $(id -u) ||
      $(stat -Lc '%a' -- "$TARBALL_LOCK_ROOT") != 700 ]]; then
  echo "[linux] global tarball lock directory must be a uid-owned mode-0700 directory: $TARBALL_LOCK_ROOT" >&2
  exit 1
fi
TARBALL_LOCK_ROOT=$(realpath -e -- "$TARBALL_LOCK_ROOT")

declare -a TARBALL_RESOURCE_IDENTITIES=("path:$TARBALL")
TARBALL_INITIAL_INODE=
if [[ -e $TARBALL ]]; then
  TARBALL_INITIAL_INODE=$(stat -Lc '%d:%i' -- "$TARBALL")
  TARBALL_RESOURCE_IDENTITIES+=("inode:$TARBALL_INITIAL_INODE")
fi
declare -a TARBALL_LOCK_PATHS=()
mapfile -t TARBALL_LOCK_PATHS < <(
  for identity in "${TARBALL_RESOURCE_IDENTITIES[@]}"; do
    key=$(printf '%s\0' "$identity" | sha256sum | awk '{print $1}')
    printf '%s/%s.lock\n' "$TARBALL_LOCK_ROOT" "$key"
  done | LC_ALL=C sort -u
)

guard_tarball_locks() {
  local lock_path fd_path
  for lock_path in "${TARBALL_LOCK_PATHS[@]}"; do
    if [[ -L $lock_path || ( -e $lock_path && ! -f $lock_path ) ]]; then
      echo "[linux] unsafe tarball transaction lock: $lock_path" >&2
      exit 1
    fi
    if [[ -e $lock_path &&
          ( $(stat -Lc '%u' -- "$lock_path") != $(id -u) ||
            $(stat -Lc '%h' -- "$lock_path") != 1 ) ]]; then
      echo "[linux] tarball transaction lock must be uid-owned with one link: $lock_path" >&2
      exit 1
    fi
    for protected_path in "$TARBALL" "$LINUX_IMAGE" "$LINUX_BUILD_LOCK" \
        "$LINUX_SOURCE_LOCK" "$TREE_ID_HELPER" "$LINUX_PATCH" \
        ${PROFILE_STAMP:+"$PROFILE_STAMP"}; do
      if [[ -e $lock_path && -e $protected_path && $lock_path -ef $protected_path ]]; then
        echo "[linux] tarball transaction lock aliases protected path: $protected_path" >&2
        exit 1
      fi
    done
  done
}

guard_tarball_locks
declare -a TARBALL_LOCK_FDS=()
for lock_path in "${TARBALL_LOCK_PATHS[@]}"; do
  exec {tarball_lock_fd}>>"$lock_path"
  flock "$tarball_lock_fd"
  TARBALL_LOCK_FDS+=("$tarball_lock_fd")
done
guard_tarball_locks
for i in "${!TARBALL_LOCK_PATHS[@]}"; do
  fd_path="/proc/$$/fd/${TARBALL_LOCK_FDS[i]}"
  if [[ ! -e $fd_path || ! $fd_path -ef ${TARBALL_LOCK_PATHS[i]} ]]; then
    echo "[linux] tarball transaction lock path changed while waiting: ${TARBALL_LOCK_PATHS[i]}" >&2
    exit 1
  fi
done
if [[ -n $TARBALL_INITIAL_INODE ]]; then
  if [[ ! -f $TARBALL || -L $TARBALL ||
        $(stat -Lc '%d:%i' -- "$TARBALL") != "$TARBALL_INITIAL_INODE" ]]; then
    echo "[linux] source tarball changed while waiting for its transaction lock: $TARBALL" >&2
    exit 1
  fi
elif [[ -L $TARBALL || ( -e $TARBALL && ! -f $TARBALL ) ]]; then
  echo "[linux] unsafe source tarball appeared while waiting: $TARBALL" >&2
  exit 1
fi

release_tarball_locks() {
  local lock_fd
  for lock_fd in "${TARBALL_LOCK_FDS[@]}"; do
    flock -u "$lock_fd"
  done
  TARBALL_LOCK_FDS=()
}

case "$FEATURE_PROFILE" in
  headless|display) ;;
  *)
    echo "[linux] unsupported LINUX_FEATURE_PROFILE=$FEATURE_PROFILE (expect headless or display)" >&2
    exit 1
    ;;
esac

require_stamp_match() {
  local field=$1 stamped=$2 actual=$3
  if [[ $stamped != "$actual" ]]; then
    echo "[linux] inconsistent Make/script profile field $field: '$stamped' != '$actual'" >&2
    exit 1
  fi
}

require_stamp_match LINUX_PLATFORM "$STAMP_PLATFORM" "$PLATFORM"
require_stamp_match LINUX_FEATURE_PROFILE "$STAMP_FEATURE_PROFILE" "$FEATURE_PROFILE"
require_stamp_match LINUX_ROOT "$STAMP_ROOT" "$ROOT"
require_stamp_match LINUX_REF "$STAMP_REF" "$REF"
require_stamp_match LINUX_PATCH "$STAMP_PATCH" "$LINUX_PATCH"
require_stamp_match CROSS_COMPILE "$STAMP_CROSS_COMPILE" "$CROSS_COMPILE"
require_stamp_match LINUX_BUILD_DIR "$STAMP_BUILD_DIR" "$BUILD_DIR_REQUESTED"

SCRIPT_SHA256=$(sha256sum -- "${BASH_SOURCE[0]}" | awk '{print $1}')
TREE_ID_HELPER_SHA256=$(sha256sum -- "$TREE_ID_HELPER" | awk '{print $1}')
PATCH_SHA256=absent
PATCH_SNAPSHOT=
PATCH_STATE=
PATCH_REQUESTED=0
PATCH_EXPECTED=
profile_tmp=
source_expected_index=
source_actual_index=
source_unexpected_paths=
tarball_state_tmp=
tarball_download_tmp=
source_extract_tmp=
cleanup_transaction_temps() {
  local status=$?
  trap - EXIT HUP INT TERM
  rm -f -- "${PATCH_SNAPSHOT:-}" "${profile_tmp:-}"
  rm -f -- "${tarball_state_tmp:-}"
  rm -f -- "${tarball_download_tmp:-}"
  if [[ -n ${source_extract_tmp:-} ]]; then
    case "$source_extract_tmp" in
      "$(dirname -- "$ROOT_CANONICAL")"/.linux-extract.*)
        rm -rf -- "$source_extract_tmp"
        ;;
      *)
        echo "[linux] refusing unsafe extraction cleanup path: $source_extract_tmp" >&2
        ;;
    esac
  fi
  if [[ -n ${source_expected_index:-} ]]; then
    rm -f -- "$source_expected_index" "$source_expected_index.lock"
  fi
  if [[ -n ${source_actual_index:-} ]]; then
    rm -f -- "$source_actual_index" "$source_actual_index.lock"
  fi
  rm -f -- "${source_unexpected_paths:-}"
  exit "$status"
}
trap cleanup_transaction_temps EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

DERIVED_PATCH_STATE="$SOURCE_STATE_DIR/linux-applied.patch"
if [[ -n ${LINUX_PATCH_STATE:-} &&
      $(realpath -m -- "$LINUX_PATCH_STATE") != "$DERIVED_PATCH_STATE" ]]; then
  echo "[linux] LINUX_PATCH_STATE must be derived from canonical LINUX_ROOT: $DERIVED_PATCH_STATE" >&2
  exit 1
fi
PATCH_STATE=$DERIVED_PATCH_STATE
PATCH_STATE_DIR=$SOURCE_STATE_DIR
if [[ -L $PATCH_STATE || ( -e $PATCH_STATE && ! -f $PATCH_STATE ) ]]; then
  echo "[linux] unsafe recorded patch state: $PATCH_STATE" >&2
  exit 1
fi
if [[ -e $LINUX_PATCH && ! -f $LINUX_PATCH ]]; then
  echo "[linux] patch input is not a regular file: $LINUX_PATCH" >&2
  exit 1
fi
if [[ -f $LINUX_PATCH ]]; then
  PATCH_REQUESTED=1
  PATCH_SNAPSHOT=$(mktemp "$PATCH_STATE_DIR/.linux-patch-input.tmp.XXXXXX")
  cp -- "$LINUX_PATCH" "$PATCH_SNAPSHOT"
  PATCH_EXPECTED=$PATCH_SNAPSHOT
  sync -f "$PATCH_SNAPSHOT"
  PATCH_SHA256=$(sha256sum -- "$PATCH_SNAPSHOT" | awk '{print $1}')
fi

write_profile_payload() {
  local output=$1 image_sha256=$2
  printf '%s\n' \
    "LINUX_PLATFORM=$STAMP_PLATFORM" \
    "LINUX_FEATURE_PROFILE=$STAMP_FEATURE_PROFILE" \
    "LINUX_ROOT=$STAMP_ROOT" \
    "LINUX_REF=$STAMP_REF" \
    "LINUX_PATCH=$STAMP_PATCH" \
    "LINUX_PATCH_SHA256=$PATCH_SHA256" \
    "LINUX_SOURCE_KIND=$SOURCE_KIND" \
    "LINUX_SOURCE_REVISION=$SOURCE_REVISION" \
    "LINUX_SOURCE_TREE=$SOURCE_EXPECTED_TREE" \
    "CROSS_COMPILE=$STAMP_CROSS_COMPILE" \
    "LINUX_BUILD_DIR=$STAMP_BUILD_DIR" \
    "LINUX_BUILD_SCRIPT_SHA256=$SCRIPT_SHA256" \
    "LINUX_SOURCE_TREE_HELPER_SHA256=$TREE_ID_HELPER_SHA256" \
    "LINUX_IMAGE_SHA256=$image_sha256" > "$output"
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
  if [[ -n ${source_unexpected_paths:-} ]]; then
    rm -f -- "$source_unexpected_paths"
    source_unexpected_paths=
  fi
}

read_state_field() {
  local file=$1 key=$2 count value
  count=$(grep -c "^${key}=" "$file" 2>/dev/null || true)
  [[ $count == 1 ]] || return 1
  value=$(grep "^${key}=" "$file")
  printf '%s\n' "${value#*=}"
}

directory_tree_id() {
  python3 -B "$TREE_ID_HELPER" --directory "$ROOT"
}

tarball_tree_id() {
  python3 -B "$TREE_ID_HELPER" --tar "$TARBALL" \
    --strip-prefix "linux-$VERSION"
}

SOURCE_MISMATCH_REASON=
SOURCE_KIND=
SOURCE_REVISION=
SOURCE_EXPECTED_TREE=
source_matches_target() {
  local source_top desired_commit head_commit expected_tree actual_tree
  local state_ref state_tarball_sha state_patch_sha
  SOURCE_MISMATCH_REASON=
  SOURCE_KIND=
  SOURCE_REVISION=
  SOURCE_EXPECTED_TREE=
  if [[ ! -d $ROOT/.git ]]; then
    if (( PATCH_REQUESTED )); then
      if [[ ! -s $PATCH_STATE ]] || ! cmp -s "$PATCH_EXPECTED" "$PATCH_STATE"; then
        SOURCE_MISMATCH_REASON="recorded patch bytes do not match requested patch"
        return 1
      fi
    elif [[ -e $PATCH_STATE ]]; then
      SOURCE_MISMATCH_REASON="recorded patch state exists but no patch is requested"
      return 1
    fi
    [[ -f $ROOT/Makefile ]] || {
      SOURCE_MISMATCH_REASON="non-git source has no Makefile"
      return 1
    }
    if [[ -L $TARBALL_SOURCE_STATE || ! -f $TARBALL_SOURCE_STATE ]]; then
      SOURCE_MISMATCH_REASON="trusted tarball source state is absent"
      return 1
    fi
    if [[ -L $TARBALL || ! -f $TARBALL ]]; then
      SOURCE_MISMATCH_REASON="recorded source tarball is absent or unsafe"
      return 1
    fi
    state_ref=$(read_state_field "$TARBALL_SOURCE_STATE" LINUX_REF) || {
      SOURCE_MISMATCH_REASON="tarball source state has invalid LINUX_REF"
      return 1
    }
    state_tarball_sha=$(read_state_field "$TARBALL_SOURCE_STATE" TARBALL_SHA256) || {
      SOURCE_MISMATCH_REASON="tarball source state has invalid TARBALL_SHA256"
      return 1
    }
    state_patch_sha=$(read_state_field "$TARBALL_SOURCE_STATE" PATCH_SHA256) || {
      SOURCE_MISMATCH_REASON="tarball source state has invalid PATCH_SHA256"
      return 1
    }
    expected_tree=$(read_state_field "$TARBALL_SOURCE_STATE" PATCHED_TREE_SHA256) || {
      SOURCE_MISMATCH_REASON="tarball source state has invalid PATCHED_TREE_SHA256"
      return 1
    }
    if [[ $state_ref != "$REF" || $state_patch_sha != "$PATCH_SHA256" ]]; then
      SOURCE_MISMATCH_REASON="tarball source state does not match requested ref/patch"
      return 1
    fi
    desired_commit=$(sha256sum -- "$TARBALL" | awk '{print $1}')
    if [[ $state_tarball_sha != "$desired_commit" ]]; then
      SOURCE_MISMATCH_REASON="source tarball bytes changed"
      return 1
    fi
    actual_tree=$(directory_tree_id) || {
      SOURCE_MISMATCH_REASON="cannot hash non-git source tree"
      return 1
    }
    if [[ $actual_tree != "$expected_tree" ]]; then
      SOURCE_MISMATCH_REASON="non-git source tree differs from trusted tarball state"
      return 1
    fi
    SOURCE_KIND=tarball
    SOURCE_REVISION=$desired_commit
    SOURCE_EXPECTED_TREE=$expected_tree
    return 0
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
    SOURCE_MISMATCH_REASON="source HEAD does not match LINUX_REF=$REF"
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

  source_expected_index=$(mktemp "$SOURCE_STATE_DIR/.linux-expected-index.tmp.XXXXXX")
  source_actual_index=$(mktemp "$SOURCE_STATE_DIR/.linux-actual-index.tmp.XXXXXX")
  source_unexpected_paths=$(mktemp "$SOURCE_STATE_DIR/.linux-unexpected-paths.tmp.XXXXXX")
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
  # Start from the exact expected (possibly patched) tree.  List *all* other
  # paths without standard excludes: ignored Kbuild inputs such as
  # .scmversion and nested repositories must invalidate the cache too.  Using
  # `git add -f` here would hash entire ignored build trees into the real object
  # database merely to reject them, so reject unexpected paths first and only
  # refresh entries that belong to the expected tree.
  if ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" read-tree "$expected_tree" ||
     ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" \
       ls-files --others --directory --no-empty-directory -z -- . \
       > "$source_unexpected_paths"; then
    SOURCE_MISMATCH_REASON="cannot hash current source worktree"
    cleanup_source_indexes
    return 1
  fi
  if [[ -s $source_unexpected_paths ]]; then
    SOURCE_MISMATCH_REASON="source worktree has unexpected untracked or ignored paths"
    cleanup_source_indexes
    return 1
  fi
  if ! GIT_INDEX_FILE="$source_actual_index" git -C "$ROOT" add -u -- .; then
    SOURCE_MISMATCH_REASON="cannot hash current source worktree"
    cleanup_source_indexes
    return 1
  fi
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
  SOURCE_KIND=git
  SOURCE_REVISION=$desired_commit
  SOURCE_EXPECTED_TREE=$expected_tree
  return 0
}

profile_stamp_has_one_image_hash() {
  [[ -f $PROFILE_STAMP ]] &&
    [[ $(grep -Ec '^LINUX_IMAGE_SHA256=[0-9a-f]{64}$' "$PROFILE_STAMP") -eq 1 ]] &&
    [[ $(grep -Ec '^LINUX_SOURCE_KIND=(git|tarball)$' "$PROFILE_STAMP") -eq 1 ]] &&
    [[ $(grep -Ec '^LINUX_SOURCE_REVISION=[0-9a-f]{40,64}$' "$PROFILE_STAMP") -eq 1 ]] &&
    [[ $(grep -Ec '^LINUX_SOURCE_TREE=[0-9a-f]{40,64}$' "$PROFILE_STAMP") -eq 1 ]]
}

FORCE_ARTIFACT_REBUILD=0
if [[ -n $PROFILE_STAMP ]]; then
  mkdir -p "$(dirname -- "$PROFILE_STAMP")"
  profile_tmp=$(mktemp "$(dirname -- "$PROFILE_STAMP")/.$(basename -- "$PROFILE_STAMP").tmp.XXXXXX")
  if [[ -s $LINUX_IMAGE ]]; then
    if source_matches_target; then
      IMAGE_SHA256=$(sha256sum -- "$LINUX_IMAGE" | awk '{print $1}')
      write_profile_payload "$profile_tmp" "$IMAGE_SHA256"
      sync -f "$profile_tmp"
      if profile_stamp_has_one_image_hash && cmp -s "$profile_tmp" "$PROFILE_STAMP"; then
        echo "[linux] profile, source and Image are current: $LINUX_IMAGE"
        exit 0
      fi
    else
      echo "[linux] cached Image is not reusable: $SOURCE_MISMATCH_REASON"
    fi
  fi
  FORCE_ARTIFACT_REBUILD=1
fi

ensure_clean_default_root() {
  local resolved
  resolved=$(realpath -m "$ROOT")
  case "$resolved" in
    "$(realpath -m "$ENV_ROOT/src/linux")")
      rm -rf "$ROOT"
      ;;
    *)
      echo "[linux] $ROOT 不是 git 仓库且不在默认 $ENV_ROOT/src/linux，拒绝自动删除。" >&2
      exit 1
      ;;
  esac
}

ensure_tarball_available() {
  if [[ -L $TARBALL || ( -e $TARBALL && ! -f $TARBALL ) ]]; then
    echo "[linux] unsafe source tarball: $TARBALL" >&2
    exit 1
  fi
  if [[ -s $TARBALL ]] &&
     python3 -B "$TREE_ID_HELPER" --tar "$TARBALL" \
       --strip-prefix "linux-$VERSION" >/dev/null; then
    return 0
  fi
  if [[ -e $TARBALL ]]; then
    echo "[linux] replacing incomplete or invalid source tarball atomically: $TARBALL"
  fi
  tarball_download_tmp=$(mktemp "$TARBALL_PARENT/.$TARBALL_BASENAME.tmp.XXXXXX")
  curl -fL --retry 5 --retry-delay 2 "$TARBALL_URL" -o "$tarball_download_tmp"
  [[ -s $tarball_download_tmp && -f $tarball_download_tmp &&
     ! -L $tarball_download_tmp ]] || {
    echo "[linux] downloaded source tarball is absent or unsafe: $TARBALL" >&2
    exit 1
  }
  python3 -B "$TREE_ID_HELPER" --tar "$tarball_download_tmp" \
    --strip-prefix "linux-$VERSION" >/dev/null || {
    echo "[linux] downloaded source tarball failed archive validation: $TARBALL_URL" >&2
    exit 1
  }
  sync -f "$tarball_download_tmp"
  if [[ -L $TARBALL || ( -e $TARBALL && ! -f $TARBALL ) ]]; then
    echo "[linux] unsafe source tarball appeared before publish: $TARBALL" >&2
    exit 1
  fi
  mv -fT -- "$tarball_download_tmp" "$TARBALL"
  tarball_download_tmp=
  sync -f "$TARBALL_PARENT"
}

if [ ! -d "$ROOT/.git" ] && [ ! -f "$ROOT/Makefile" ]; then
  if ! git clone --depth=1 --branch "$REF" https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git "$ROOT"; then
    echo "[linux] git clone 失败，回退到官方 tarball: $TARBALL_URL"
    ensure_clean_default_root
    ensure_tarball_available
    mkdir -p "$(dirname -- "$ROOT_CANONICAL")"
    source_extract_tmp=$(mktemp -d \
      "$(dirname -- "$ROOT_CANONICAL")/.linux-extract.$VERSION.XXXXXXXX")
    tar -xf "$TARBALL" -C "$source_extract_tmp" --strip-components=1
    [[ -f $source_extract_tmp/Makefile ]] || {
      echo "[linux] extracted source archive has no top-level Makefile" >&2
      exit 1
    }
    if [[ -e $ROOT_CANONICAL || -L $ROOT_CANONICAL ]]; then
      echo "[linux] source root appeared before atomic publish: $ROOT_CANONICAL" >&2
      exit 1
    fi
    sync -f "$source_extract_tmp"
    mv -T -- "$source_extract_tmp" "$ROOT_CANONICAL"
    source_extract_tmp=
    sync -f "$(dirname -- "$ROOT_CANONICAL")"
  fi
fi

if [[ ! -d $ROOT/.git ]]; then
  ensure_tarball_available
fi

patch_can_apply() {
  local patch_file=$1
  shift
  # --force keeps the explicitly requested direction.  --batch would
  # auto-detect a reversed patch and can turn a reverse probe on baseline
  # source into a successful forward probe, breaking state recovery.
  patch --force --silent --no-backup-if-mismatch -d "$ROOT" -p1 \
    "$@" --dry-run < "$patch_file" >/dev/null 2>&1
}

patch_apply() {
  local patch_file=$1
  shift
  patch --force --silent --no-backup-if-mismatch -d "$ROOT" -p1 \
    "$@" < "$patch_file"
}

restore_recorded_patch() {
  local recorded_patch=$1
  if patch_can_apply "$recorded_patch" --reverse; then
    patch_apply "$recorded_patch" --reverse
    echo "[linux] removed previously recorded patch before source refresh"
  elif patch_can_apply "$recorded_patch" --forward; then
    # Source is already at the unpatched baseline (for example after a fresh
    # clone); no mutation is needed.
    :
  else
    echo "[linux] source matches neither baseline nor recorded patch; refusing to overwrite local changes" >&2
    exit 1
  fi
}

# Restore exactly the bytes used by the preceding successful source
# transaction.  This makes a changed patch replayable; a source-code marker
# cannot distinguish an old patch revision from the requested one.
if [[ -s $PATCH_STATE ]]; then
  restore_recorded_patch "$PATCH_STATE"
elif [[ -n $PATCH_SNAPSHOT ]] && patch_can_apply "$PATCH_SNAPSHOT" --reverse; then
  # Compatibility with source trees patched before patch-state tracking.
  patch_apply "$PATCH_SNAPSHOT" --reverse
  echo "[linux] removed legacy untracked patch before source refresh"
fi

TARBALL_SHA256_CURRENT=
TARBALL_BASE_TREE=
if [[ ! -d $ROOT/.git ]]; then
  # A pre-existing extracted tree is reusable only when its complete content
  # equals the requested official tarball after the recorded patch is removed.
  # A changed REF therefore fails closed instead of silently stamping the old
  # source; deleting the generated default tree explicitly re-enters acquisition.
  TARBALL_SHA256_CURRENT=$(sha256sum -- "$TARBALL" | awk '{print $1}')
  TARBALL_BASE_TREE=$(tarball_tree_id)
  CURRENT_BASE_TREE=$(directory_tree_id)
  if [[ $CURRENT_BASE_TREE != "$TARBALL_BASE_TREE" ]]; then
    echo "[linux] non-git source does not match LINUX_REF=$REF tarball; refusing to overwrite or stamp it" >&2
    exit 1
  fi
fi

if [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" fetch --tags --depth=1 origin "$REF"
  git -C "$ROOT" checkout -q "$REF"
fi

if [[ -n $PATCH_SNAPSHOT ]]; then
  if ! patch_can_apply "$PATCH_SNAPSHOT" --forward; then
    echo "[linux] requested patch does not apply cleanly to LINUX_REF=$REF" >&2
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
  if ! patch_can_apply "$PATCH_STATE" --forward; then
    echo "[linux] published patch state no longer matches the source baseline" >&2
    exit 1
  fi
  patch_apply "$PATCH_STATE" --forward
  echo "[linux] applied patch: $LINUX_PATCH ($PATCH_SHA256)"
else
  rm -f -- "$PATCH_STATE"
  sync -f "$PATCH_STATE_DIR"
fi

if [[ ! -d $ROOT/.git ]]; then
  PATCHED_TREE_SHA256=$(directory_tree_id)
  if [[ -L $TARBALL_SOURCE_STATE ||
        ( -e $TARBALL_SOURCE_STATE && ! -f $TARBALL_SOURCE_STATE ) ]]; then
    echo "[linux] unsafe tarball source state: $TARBALL_SOURCE_STATE" >&2
    exit 1
  fi
  tarball_state_tmp=$(mktemp "$SOURCE_STATE_DIR/.linux-tarball-source.tmp.XXXXXX")
  printf '%s\n' \
    'LINUX_TARBALL_SOURCE_FORMAT=1' \
    "LINUX_REF=$REF" \
    "TARBALL_URL=$TARBALL_URL" \
    "TARBALL_SHA256=$TARBALL_SHA256_CURRENT" \
    "BASE_TREE_SHA256=$TARBALL_BASE_TREE" \
    "PATCH_SHA256=$PATCH_SHA256" \
    "PATCHED_TREE_SHA256=$PATCHED_TREE_SHA256" \
    "TREE_ID_HELPER_SHA256=$TREE_ID_HELPER_SHA256" > "$tarball_state_tmp"
  sync -f "$tarball_state_tmp"
  mv -fT -- "$tarball_state_tmp" "$TARBALL_SOURCE_STATE"
  tarball_state_tmp=
  sync -f "$SOURCE_STATE_DIR"
fi

if ! source_matches_target; then
  echo "[linux] normalized source does not match target profile: $SOURCE_MISMATCH_REASON" >&2
  exit 1
fi
release_tarball_locks
if (( FORCE_ARTIFACT_REBUILD )); then
  # A non-empty Image with a missing/mismatched stamp is untrusted.  Removing
  # only this final derived output forces Kbuild to regenerate it without
  # discarding the reusable O= object graph.
  rm -f -- "$LINUX_IMAGE"
fi

CONFIG_TOOL="$ROOT/scripts/config"
kconfig() {
  "$CONFIG_TOOL" --file "$BUILD_DIR/.config" "$@"
}

require_config_enabled() {
  local symbol=$1
  if ! grep -qx "${symbol}=y" "$BUILD_DIR/.config"; then
    echo "[linux] $FEATURE_PROFILE profile requires ${symbol}=y after olddefconfig" >&2
    return 1
  fi
}

require_config_disabled() {
  local symbol=$1
  if grep -qx "# ${symbol} is not set" "$BUILD_DIR/.config"; then
    return 0
  fi
  # Kconfig omits symbols whose dependencies are invisible (for example
  # VIRTIO_INPUT when INPUT=n). Absence is therefore also a real disabled state.
  if ! grep -q "^${symbol}=" "$BUILD_DIR/.config"; then
    return 0
  fi
  echo "[linux] $FEATURE_PROFILE profile requires ${symbol}=n after olddefconfig" >&2
  return 1
}

# .config、对象文件和 Image 按平台写入 O= 目录，不会互相覆盖；共享源码的
# checkout/patch 与 reader 则由上面的 source lock 串行，保证冷构建也一致。
make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" defconfig

# NPC 当前是单 hart bring-up；裁掉 PCI/USB/模块/调试面，避免仿真把大量周期
# 花在通用发行版探测路径上。systemd rootfs 仍需要 AF_UNIX、netlink 和 notify socket；
# NEMU rootfs 额外打开最小 virtio-net，用于枚举接口，不代表已有 host 转发后端。
kconfig --disable CONFIG_SMP
kconfig --set-val CONFIG_NR_CPUS 1
kconfig --disable CONFIG_MODULES
kconfig --enable CONFIG_NET
kconfig --enable CONFIG_UNIX
kconfig --enable CONFIG_PACKET
kconfig --enable CONFIG_NETLINK_DIAG
kconfig --enable CONFIG_INET
# systemd 需要本地 socket/netlink，但不需要 IPsec；关掉 XFRM/ESP 可以避免
# CRYPTO_GENIV -> DRBG -> jitterentropy 在慢速 NEMU 上消耗十几秒 guest time。
kconfig --disable CONFIG_XFRM
kconfig --disable CONFIG_XFRM_ALGO
kconfig --disable CONFIG_XFRM_AH
kconfig --disable CONFIG_XFRM_ESP
kconfig --disable CONFIG_XFRM_IPCOMP
kconfig --disable CONFIG_INET_AH
kconfig --disable CONFIG_INET_ESP
kconfig --disable CONFIG_INET_IPCOMP
kconfig --disable CONFIG_AUDIT
kconfig --disable CONFIG_AUDITSYSCALL
# systemd/journald 的单位沙箱会探测 cgroup-BPF firewalling；打开最小内核
# BPF syscall 与 cgroup-BPF，避免完整 Ubuntu 用户态把该能力报告为缺失。
kconfig --enable CONFIG_BPF_SYSCALL
kconfig --enable CONFIG_CGROUP_BPF
# full Ubuntu 的 systemd/resource-control 路线需要 PSI 作为压力反馈接口，
# 同时保持默认启用，避免只靠启动参数才出现 /proc/pressure。
kconfig --enable CONFIG_PSI
kconfig --disable CONFIG_PSI_DEFAULT_DISABLED
kconfig --disable CONFIG_IKCONFIG
kconfig --disable CONFIG_IKCONFIG_PROC
kconfig --disable CONFIG_IO_URING
kconfig --disable CONFIG_PERF_EVENTS
kconfig --disable CONFIG_CGROUP_PERF
kconfig --disable CONFIG_ARCH_MICROCHIP_POLARFIRE
kconfig --disable CONFIG_SOC_MICROCHIP_POLARFIRE
kconfig --disable CONFIG_ARCH_RENESAS
kconfig --disable CONFIG_ARCH_SIFIVE
kconfig --disable CONFIG_SOC_SIFIVE
kconfig --disable CONFIG_ARCH_STARFIVE
kconfig --disable CONFIG_SOC_STARFIVE
kconfig --disable CONFIG_ARCH_SUNXI
kconfig --disable CONFIG_ARCH_THEAD
kconfig --disable CONFIG_EFI
kconfig --disable CONFIG_EFI_STUB
kconfig --disable CONFIG_EFI_PARTITION
kconfig --disable CONFIG_EFIVAR_FS
kconfig --disable CONFIG_IPV6
kconfig --disable CONFIG_XFRM_USER
kconfig --disable CONFIG_NETFILTER
kconfig --disable CONFIG_IP_VS
kconfig --disable CONFIG_BRIDGE
kconfig --disable CONFIG_VLAN_8021Q
kconfig --disable CONFIG_NET_SCHED
kconfig --disable CONFIG_NET_CLS
kconfig --disable CONFIG_NET_ACT
kconfig --enable CONFIG_NETDEVICES
kconfig --enable CONFIG_VIRTIO_NET
# 只保留 virtio-net 这条 Linux-visible 设备路径；其它虚拟/以太网
# 厂商驱动会增加 probe 面和构建体积，当前 NEMU 没有对应 MMIO 设备。
kconfig --disable CONFIG_DUMMY
kconfig --disable CONFIG_MACVLAN
kconfig --disable CONFIG_IPVLAN
kconfig --disable CONFIG_VXLAN
kconfig --disable CONFIG_VETH
kconfig --disable CONFIG_NET_FAILOVER
kconfig --disable CONFIG_FAILOVER
kconfig --disable CONFIG_ETHERNET
kconfig --disable CONFIG_NET_VENDOR_CADENCE
kconfig --disable CONFIG_NET_VENDOR_STMICRO
kconfig --disable CONFIG_MACB
kconfig --disable CONFIG_STMMAC_ETH
kconfig --disable CONFIG_PHYLIB
kconfig --disable CONFIG_MII
kconfig --disable CONFIG_WIRELESS
kconfig --disable CONFIG_CFG80211
kconfig --disable CONFIG_MAC80211
kconfig --disable CONFIG_PCI
kconfig --disable CONFIG_USB_SUPPORT
kconfig --disable CONFIG_SOUND
kconfig --disable CONFIG_MEDIA_SUPPORT
kconfig --disable CONFIG_DRM
if [ "$FEATURE_PROFILE" = "display" ]; then
  # 当前 NEMU 已有一块固定 800x600 XRGB8888 host framebuffer；先通过
  # 标准 simple-framebuffer + fbcon 接通 Linux 文本控制台。virtio-gpu
  # 属于后续可替换的 DRM transport，不是这个最短显示闭环的前置。
  kconfig --enable CONFIG_FB
  kconfig --enable CONFIG_FB_SIMPLE
  kconfig --enable CONFIG_FRAMEBUFFER_CONSOLE
  kconfig --enable CONFIG_FRAMEBUFFER_CONSOLE_DETECT_PRIMARY
else
  kconfig --disable CONFIG_FB
fi
kconfig --disable CONFIG_MMC
kconfig --disable CONFIG_COMMON_CLK
kconfig --disable CONFIG_I2C
kconfig --disable CONFIG_SPI
kconfig --disable CONFIG_PINCTRL
kconfig --disable CONFIG_GPIOLIB
kconfig --disable CONFIG_POWER_SUPPLY
kconfig --disable CONFIG_HWMON
kconfig --disable CONFIG_THERMAL
kconfig --disable CONFIG_REGULATOR
# NEMU rootfs DTB 暴露 google,goldfish-rtc；打开 RTC class/driver，
# 让 Ubuntu 用户态拥有 wall-clock 设备，而不是只依赖 CLINT mtime。
kconfig --enable CONFIG_RTC_CLASS
kconfig --enable CONFIG_RTC_DRV_GOLDFISH
kconfig --disable CONFIG_RPMSG
kconfig --disable CONFIG_EXTCON
kconfig --disable CONFIG_RESET_CONTROLLER
kconfig --disable CONFIG_GENERIC_PHY
kconfig --disable CONFIG_RISCV_PMU
# Ubuntu 的 e2scrub/systemd 维护任务会通过 loop-control 清理在线 ext4 快照；
# 这是发行版用户态的正常路径，不能为了提速关掉。
kconfig --enable CONFIG_BLK_DEV_LOOP
kconfig --disable CONFIG_VIRTIO_CONSOLE
kconfig --disable CONFIG_VIRTIO_BALLOON
kconfig --disable CONFIG_SERIAL_SH_SCI
kconfig --disable CONFIG_VT
kconfig --disable CONFIG_ACPI
kconfig --disable CONFIG_PNP
if [ "$FEATURE_PROFILE" = "display" ]; then
  kconfig --enable CONFIG_INPUT
  kconfig --enable CONFIG_INPUT_EVDEV
  kconfig --enable CONFIG_VIRTIO_INPUT
  # SDL 事件只通过 virtio-input 注入；PS/2、HID 和其它输入类别在当前
  # NEMU 设备树里没有生产者，关掉它们可缩小 Image 与启动探测面。
  kconfig --disable CONFIG_INPUT_KEYBOARD
  kconfig --disable CONFIG_INPUT_MOUSE
  kconfig --disable CONFIG_INPUT_JOYSTICK
  kconfig --disable CONFIG_INPUT_TABLET
  kconfig --disable CONFIG_INPUT_TOUCHSCREEN
  kconfig --disable CONFIG_INPUT_MISC
  kconfig --disable CONFIG_SERIO
  kconfig --disable CONFIG_HID_SUPPORT
  kconfig --enable CONFIG_VT
  kconfig --enable CONFIG_VT_CONSOLE
  kconfig --enable CONFIG_VT_HW_CONSOLE_BINDING
else
  kconfig --disable CONFIG_INPUT
fi
kconfig --disable CONFIG_KVM
kconfig --disable CONFIG_IOMMU_SUPPORT
kconfig --disable CONFIG_SCSI
kconfig --disable CONFIG_ATA
kconfig --disable CONFIG_MD
kconfig --disable CONFIG_BLK_DEV_DM
kconfig --disable CONFIG_BTRFS_FS
# systemd 会用 autofs 管理部分 automount 条件；直接内建 autofs，避免
# 无模块内核下查找 autofs4 alias 时返回 ENOSYS 噪声。
kconfig --enable CONFIG_AUTOFS_FS
kconfig --disable CONFIG_OVERLAY_FS
kconfig --disable CONFIG_ISO9660_FS
kconfig --disable CONFIG_FAT_FS
kconfig --disable CONFIG_NETWORK_FILESYSTEMS
kconfig --disable CONFIG_NFS_FS
kconfig --disable CONFIG_NFS_V4
kconfig --disable CONFIG_SUNRPC
kconfig --disable CONFIG_NET_9P
kconfig --disable CONFIG_9P_FS
kconfig --disable CONFIG_RAID6_PQ
kconfig --disable CONFIG_RAID6_PQ_BENCHMARK
kconfig --disable CONFIG_XOR_BLOCKS
kconfig --disable CONFIG_HUGETLBFS
kconfig --disable CONFIG_HUGETLB_PAGE
kconfig --disable CONFIG_DEBUG_VM
kconfig --disable CONFIG_DEBUG_VM_IRQSOFF
kconfig --disable CONFIG_DEBUG_VM_PGFLAGS
kconfig --disable CONFIG_DEBUG_VM_PGTABLE
kconfig --disable CONFIG_DEBUG_KERNEL
kconfig --disable CONFIG_DEBUG_PLIST
kconfig --disable CONFIG_DEBUG_FS
kconfig --disable CONFIG_DEBUG_INFO
kconfig --disable CONFIG_FTRACE
kconfig --disable CONFIG_TRACING
kconfig --disable CONFIG_PROFILING
kconfig --disable CONFIG_KALLSYMS
kconfig --disable CONFIG_KALLSYMS_ALL
kconfig --disable CONFIG_MQ_IOSCHED_KYBER
kconfig --disable CONFIG_IOSCHED_BFQ
kconfig --disable CONFIG_INIT_STACK_ALL_PATTERN
kconfig --disable CONFIG_INIT_STACK_ALL_ZERO
kconfig --enable CONFIG_INIT_STACK_NONE
kconfig --disable CONFIG_LOCKUP_DETECTOR
kconfig --disable CONFIG_SOFTLOCKUP_DETECTOR
kconfig --disable CONFIG_WQ_WATCHDOG
kconfig --disable CONFIG_WATCHDOG
# 单 hart RTL 仿真里先走最朴素的周期 tick，避开 SBI cpuidle/NO_HZ idle
# 在 OpenSBI trap handler 中反复空转，影响 initramfs bring-up 的可观测性。
kconfig --disable CONFIG_CPU_IDLE
kconfig --disable CONFIG_RISCV_SBI_CPUIDLE
kconfig --disable CONFIG_NO_HZ_IDLE
kconfig --enable CONFIG_HZ_PERIODIC
kconfig --disable CONFIG_CRYPTO_DRBG_MENU
kconfig --disable CONFIG_CRYPTO_DRBG
kconfig --disable CONFIG_CRYPTO_JITTERENTROPY
kconfig --disable CONFIG_CRYPTO_SHA3
kconfig --disable CONFIG_CRYPTO_DEV_VIRTIO
kconfig --disable CONFIG_CRYPTO_HW
kconfig --disable CONFIG_CRYPTO_GCM
kconfig --disable CONFIG_CRYPTO_GENIV
kconfig --disable CONFIG_CRYPTO_SEQIV
kconfig --disable CONFIG_CRYPTO_ECHAINIV
kconfig --disable CONFIG_CRYPTO_AUTHENC
kconfig --disable CONFIG_CRYPTO_USER_API
kconfig --disable CONFIG_CRYPTO_USER_API_HASH
kconfig --disable CONFIG_CRYPTO_USER_API_SKCIPHER
kconfig --disable CONFIG_CRYPTO_USER_API_RNG
kconfig --disable CONFIG_CRYPTO_USER_API_AEAD
# NEMU rootfs DTB 现在提供 virtio-rng；打开最小 hwrng/virtio_rng，
# 让 systemd/ssh/apt 后续能走真实设备熵源，而不是只吃 bootloader rng-seed。
kconfig --enable CONFIG_HW_RANDOM
kconfig --enable CONFIG_HW_RANDOM_VIRTIO
kconfig --disable CONFIG_SECURITY_SELINUX
kconfig --disable CONFIG_SECURITY_APPARMOR

kconfig --enable CONFIG_SERIAL_8250
kconfig --enable CONFIG_SERIAL_8250_CONSOLE
kconfig --enable CONFIG_SERIAL_8250_DW
kconfig --enable CONFIG_SERIAL_OF_PLATFORM
kconfig --enable CONFIG_SERIAL_EARLYCON
# v6.6 的 SBI early console/HVC 依赖 legacy v0.1 console 配置；
# OpenSBI v1.8 仍提供该 legacy console，打开后 earlycon=sbi 才会真正生效。
kconfig --enable CONFIG_RISCV_SBI_V01
kconfig --enable CONFIG_SERIAL_EARLYCON_RISCV_SBI
kconfig --enable CONFIG_HVC_RISCV_SBI
kconfig --enable CONFIG_PRINTK
kconfig --enable CONFIG_EARLY_PRINTK
kconfig --enable CONFIG_BLK_DEV_INITRD
kconfig --enable CONFIG_DEVTMPFS
kconfig --enable CONFIG_DEVTMPFS_MOUNT
kconfig --enable CONFIG_PROC_FS
kconfig --enable CONFIG_SYSFS
kconfig --enable CONFIG_TMPFS
kconfig --enable CONFIG_VIRTIO
kconfig --enable CONFIG_VIRTIO_MMIO
kconfig --enable CONFIG_VIRTIO_BLK
kconfig --enable CONFIG_EXT4_FS

make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
if [ "$FEATURE_PROFILE" = "display" ]; then
  for symbol in \
    CONFIG_FB CONFIG_FB_SIMPLE CONFIG_FRAMEBUFFER_CONSOLE \
    CONFIG_FRAMEBUFFER_CONSOLE_DETECT_PRIMARY CONFIG_INPUT CONFIG_INPUT_EVDEV \
    CONFIG_VIRTIO_INPUT CONFIG_VT CONFIG_VT_CONSOLE CONFIG_VT_HW_CONSOLE_BINDING; do
    require_config_enabled "$symbol"
  done
  require_config_disabled CONFIG_DRM
else
  for symbol in CONFIG_FB CONFIG_INPUT CONFIG_VIRTIO_INPUT CONFIG_VT; do
    require_config_disabled "$symbol"
  done
fi
make -C "$ROOT" O="$BUILD_DIR" ARCH=riscv CROSS_COMPILE="$CROSS_COMPILE" -j"$JOBS" Image

if [[ -L $LINUX_IMAGE || ! -f $LINUX_IMAGE || ! -s $LINUX_IMAGE ]]; then
  echo "[linux] build completed without a non-empty Image: $LINUX_IMAGE" >&2
  exit 1
fi
if ! source_matches_target; then
  echo "[linux] source changed during build; refusing success stamp: $SOURCE_MISMATCH_REASON" >&2
  exit 1
fi
# Record that this invocation consumed its inputs while the canonical build
# lock is still held.  Publish the matching profile stamp only after success.
touch -- "$LINUX_IMAGE"
sync -f "$LINUX_IMAGE"
IMAGE_SHA256=$(sha256sum -- "$LINUX_IMAGE" | awk '{print $1}')
if [[ -n $PROFILE_STAMP ]]; then
  write_profile_payload "$profile_tmp" "$IMAGE_SHA256"
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

echo "[linux] platform: $PLATFORM"
echo "[linux] feature profile: $FEATURE_PROFILE"
echo "[linux] build dir: $BUILD_DIR (requested $BUILD_DIR_REQUESTED)"
echo "[linux] Image: $LINUX_IMAGE"
