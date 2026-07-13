#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation"
PROTECTED_LOG="$ROOT_DIR/build/linux-logs/npc-linux.log"
BACKUP_LOG=/tmp/ysyx-t3k-user-npc-linux.log
EXPECTED_LOG_SHA256=3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15

usage() {
  printf 'Usage: %s {core-regress|coremark}\n' "$0" >&2
  exit 2
}

sha256_of() {
  sha256sum "$1" | awk '{print $1}'
}

restore_protected_log() {
  local rc=$?
  local restored_sha
  trap - EXIT
  cp --preserve=all "$BACKUP_LOG" "$PROTECTED_LOG"
  restored_sha=$(sha256_of "$PROTECTED_LOG")
  printf 'protected-log-postcheck expected=%s actual=%s\n' \
    "$EXPECTED_LOG_SHA256" "$restored_sha"
  if [[ $restored_sha != "$EXPECTED_LOG_SHA256" ]]; then
    exit 91
  fi
  exit "$rc"
}

mode=${1:-}
[[ $mode == core-regress || $mode == coremark ]] || usage

cd "$ROOT_DIR"
pre_sha=$(sha256_of "$PROTECTED_LOG")
printf 'protected-log-precheck expected=%s actual=%s\n' \
  "$EXPECTED_LOG_SHA256" "$pre_sha"
if [[ $pre_sha != "$EXPECTED_LOG_SHA256" ]]; then
  exit 90
fi
cp --preserve=all "$PROTECTED_LOG" "$BACKUP_LOG"
[[ $(sha256_of "$BACKUP_LOG") == "$EXPECTED_LOG_SHA256" ]] || exit 92
trap restore_protected_log EXIT

source scripts/agent-env.sh
export PATH="$ROOT_DIR/oss-cad-suite/bin:$PATH"
verilator_version=$(verilator --version)
printf 'verilator=%s\n' "$verilator_version"
if [[ $verilator_version != 'Verilator 5.051 '* ]]; then
  exit 93
fi

mkdir -p "$TASK_DIR/evidence"
case "$mode" in
  core-regress)
    mkdir -p "$TASK_DIR/evidence/core-regress"
    npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh \
      --riscv-tests \
      --riscv-privileged \
      --log-base "$TASK_DIR/evidence/core-regress"
    ;;
  coremark)
    make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc clean \
      >"$TASK_DIR/evidence/coremark-clean.log" 2>&1
    make -C am-kernels/benchmarks/coremark \
      ARCH=riscv64-npc \
      ITERATIONS=10 \
      run 2>&1 | tee "$TASK_DIR/evidence/coremark-iter10.log"
    ;;
esac
