#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
nemu_home=$(realpath "$repo_root/nemu")
expected_nemu="$repo_root/nemu"
if [[ "$nemu_home" != "$expected_nemu" || ! -f "$nemu_home/Makefile" ]]; then
  printf '[V9L-DIFFTEST-E2E][FAIL] unexpected NEMU root: %s\n' "$nemu_home" >&2
  exit 1
fi

backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/v9l-nemu-config-preserve.XXXXXX")
paths=(
  .config
  .config.old
  include/config
  include/generated
)

snapshot() {
  local rel state_file
  mkdir -p "$backup_dir/state"
  for rel in "${paths[@]}"; do
    state_file="$backup_dir/state/${rel//\//__}"
    if [[ -e "$nemu_home/$rel" ]]; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      cp -a "$nemu_home/$rel" "$backup_dir/$rel"
      printf 'present\n' > "$state_file"
    else
      printf 'absent\n' > "$state_file"
    fi
  done
}

restore() {
  local rel state_file state target parent
  for rel in "${paths[@]}"; do
    state_file="$backup_dir/state/${rel//\//__}"
    state=$(<"$state_file")
    target=$(realpath -m "$nemu_home/$rel")
    case "$target" in
      "$nemu_home"/*) ;;
      *) printf '[V9L-DIFFTEST-E2E][FAIL] unsafe restore target: %s\n' "$target" >&2; return 1 ;;
    esac
    if [[ "$state" == present ]]; then
      parent=$(dirname "$target")
      mkdir -p "$parent"
      rm -rf -- "$target"
      cp -a "$backup_dir/$rel" "$target"
    else
      rm -rf -- "$target"
    fi
  done
}

cleanup() {
  local rc=$?
  set +e
  restore
  local restore_rc=$?
  if [[ -f "$nemu_home/.config" ]]; then
    sha256sum "$nemu_home/.config"
  fi
  rm -rf -- "$backup_dir"
  if [[ $restore_rc -ne 0 ]]; then
    exit "$restore_rc"
  fi
  exit "$rc"
}

snapshot
trap cleanup EXIT INT TERM

if [[ -f "$nemu_home/.config" ]]; then
  sha256sum "$nemu_home/.config"
fi
if ! grep -q '^CONFIG_TARGET_NATIVE_ELF=y' "$nemu_home/.config" ||
   ! grep -Eq '^CONFIG_ISA="riscv(32|64)"$' "$nemu_home/.config"; then
  printf '[V9L-DIFFTEST-E2E][FAIL] expected host-native RISC-V NEMU reference config\n' >&2
  exit 1
fi
if [[ ${1:-} == --smoke-only ]]; then
  env AM_HOME="$repo_root/abstract-machine" NEMU_HOME="$nemu_home" \
    make -C "$repo_root/am-kernels/tests/cpu-tests" \
      ARCH=riscv64-nemu ALL=add run NEMUFLAGS=-b
  exit 0
fi
scripts/agent-e2e.sh \
  --profile difftest \
  --task-slug ownership-rv64-memory-functional-aggregate-revtag-v9l \
  --stop-on-fail
