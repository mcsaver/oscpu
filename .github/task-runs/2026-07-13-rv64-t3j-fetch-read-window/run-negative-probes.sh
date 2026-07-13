#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
TASK_DIR="$ROOT_DIR/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window"
TB_DIR="$ROOT_DIR/npc/rv64/testbench"
CHECKER="$TASK_DIR/check-t3j-negative-probe-log.py"
CALLER_CWD=$(pwd -P)
OUT_DIR_RAW=${1:-"$TASK_DIR/evidence/negative-probes"}
# make -C 会切到 testbench；若把相对 RESULT_DIR 原样透传，产物会落到错误目录，
# 外层随后看不到 global-runner log。必须在任何 mkdir/make 前按调用 cwd 绝对化。
OUT_DIR=$(realpath -m -- "$OUT_DIR_RAW")
if [[ "$OUT_DIR_RAW" != /* ]]; then
  EXPECTED_OUT_DIR=$(realpath -m -- "$CALLER_CWD/$OUT_DIR_RAW")
  if [[ "$OUT_DIR" != "$EXPECTED_OUT_DIR" ]]; then
    printf '[T3J-NEGATIVE-PROBES] FAIL: relative output resolution drift raw=%s got=%s expected=%s\n' \
      "$OUT_DIR_RAW" "$OUT_DIR" "$EXPECTED_OUT_DIR" >&2
    exit 1
  fi
fi

if [[ -e "$OUT_DIR" ]]; then
  printf '[T3J-NEGATIVE-PROBES] FAIL: output already exists; refusing stale evidence: %s\n' \
    "$OUT_DIR" >&2
  exit 1
fi
mkdir -p "$OUT_DIR"

run_probe() {
  local case_name=$1
  local probe_define=$2
  local other_define=$3
  local expected_marker=$4
  local forbidden_marker=$5
  local case_dir="$OUT_DIR/$case_name"
  local result_dir="$case_dir/result"
  local build_dir="$case_dir/build"
  local result_log="$result_dir/logs/tb_ooo_fetch_packet_cache.log"
  local console_log="$case_dir/make-console.log"
  local audit_log="$case_dir/audit.log"
  local status_file="$case_dir/status.txt"
  local ivflags make_rc

  mkdir -p "$case_dir"
  ivflags="-g2012 -Wall -I$ROOT_DIR/npc/rv64/vsrc -I$ROOT_DIR/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -D$probe_define"
  set +e
  make -C "$TB_DIR" \
    "BUILD_DIR=$build_dir" \
    "RESULT_DIR=$result_dir" \
    "IVFLAGS=$ivflags" \
    "$result_log" >"$console_log" 2>&1
  make_rc=$?
  set -e

  if [[ ! -f "$result_log" ]]; then
    printf '[T3J-NEGATIVE-PROBES] FAIL: %s produced no global-runner log (make_rc=%s)\n' \
      "$case_name" "$make_rc" >&2
    return 1
  fi
  python3 "$CHECKER" \
    --log "$result_log" \
    --expected-marker "$expected_marker" \
    --forbidden-marker "$forbidden_marker" \
    --expected-define "$probe_define" \
    --forbidden-define "$other_define" \
    --make-rc "$make_rc" \
    --exercise-fail-closed >"$audit_log" 2>&1

  {
    printf 'case=%s\n' "$case_name"
    printf 'define=%s\n' "$probe_define"
    printf 'expected_marker=%s\n' "$expected_marker"
    printf 'forbidden_marker=%s\n' "$forbidden_marker"
    printf 'make_rc=%s\n' "$make_rc"
    printf 'global_result=EXPECTED_FAIL\n'
    printf 'marker_audit=PASS\n'
    printf 'missing_duplicate_forbidden_selftest=PASS\n'
  } >"$status_file"
  printf '[T3J-NEGATIVE-PROBE] PASS case=%s make_rc=%s exact_marker=1 result_fail=1\n' \
    "$case_name" "$make_rc"
}

run_probe \
  accept-without-read \
  OOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ \
  OOO_NEGATIVE_FPC_READ_WRITE_CONFLICT \
  '[FPC-ACCEPT-REQUIRES-READ]' \
  '[CONTRACT-FPC-1RW]'

run_probe \
  read-write-conflict \
  OOO_NEGATIVE_FPC_READ_WRITE_CONFLICT \
  OOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ \
  '[CONTRACT-FPC-1RW]' \
  '[FPC-ACCEPT-REQUIRES-READ]'

printf '[T3J-NEGATIVE-PROBES] PASS cases=2 output=%s\n' "$OUT_DIR"
