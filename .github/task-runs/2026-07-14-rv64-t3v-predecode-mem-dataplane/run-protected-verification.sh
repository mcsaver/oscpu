#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane"
PROTECTED_LOG="$ROOT_DIR/build/linux-logs/npc-linux.log"
BACKUP_LOG="$ROOT_DIR/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/protected-user-npc-linux.log"
EXPECTED_LOG_SHA256=4b0a3561369b7719fc22c6e6a03f6ae4b3f07b096e9590f5518570ae2c1f23a7

usage() {
  printf 'Usage: %s {lrsc|core-regress|coremark}\n' "$0" >&2
  exit 2
}

sha256_of() { sha256sum "$1" | awk '{print $1}'; }

restore_protected_log() {
  local rc=$?
  local restored_sha
  trap - EXIT
  cp --preserve=all "$BACKUP_LOG" "$PROTECTED_LOG"
  restored_sha=$(sha256_of "$PROTECTED_LOG")
  printf 'protected-log-postcheck expected=%s actual=%s\n' \
    "$EXPECTED_LOG_SHA256" "$restored_sha"
  [[ $restored_sha == "$EXPECTED_LOG_SHA256" ]] || exit 91
  exit "$rc"
}

mode=${1:-}
[[ $mode == lrsc || $mode == core-regress || $mode == coremark ]] || usage

cd "$ROOT_DIR"
pre_sha=$(sha256_of "$PROTECTED_LOG")
printf 'protected-log-precheck expected=%s actual=%s\n' \
  "$EXPECTED_LOG_SHA256" "$pre_sha"
[[ $pre_sha == "$EXPECTED_LOG_SHA256" ]] || exit 90
mkdir -p "$(dirname "$BACKUP_LOG")" "$TASK_DIR/evidence"
cp --preserve=all "$PROTECTED_LOG" "$BACKUP_LOG"
[[ $(sha256_of "$BACKUP_LOG") == "$EXPECTED_LOG_SHA256" ]] || exit 92
trap restore_protected_log EXIT

source scripts/agent-env.sh
export PATH="$ROOT_DIR/oss-cad-suite/bin:$PATH"
verilator_version=$(verilator --version)
printf 'verilator=%s\n' "$verilator_version"
[[ $verilator_version == 'Verilator 5.051 '* ]] || exit 93

case "$mode" in
  lrsc)
    mkdir -p "$TASK_DIR/evidence/lrsc"
    npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh \
      --riscv-tests --riscv-suites rv64ua --riscv-filter '(^|-)lrsc$' \
      --skip-module --skip-lint --skip-am \
      --log-base "$TASK_DIR/evidence/lrsc"
    ;;
  core-regress)
    mkdir -p "$TASK_DIR/evidence/core-regress"
    npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh \
      --riscv-tests --riscv-privileged \
      --log-base "$TASK_DIR/evidence/core-regress"
    ;;
  coremark)
    make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc clean \
      >"$TASK_DIR/evidence/coremark-clean.log" 2>&1
    make -C am-kernels/benchmarks/coremark \
      ARCH=riscv64-npc ITERATIONS=10 run 2>&1 \
      | tee "$TASK_DIR/evidence/coremark-iter10.log"
    ;;
esac
