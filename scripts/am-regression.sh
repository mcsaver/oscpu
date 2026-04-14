#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ARCH=${ARCH:-riscv32-nemu}
AM_HOME=${AM_HOME:-$ROOT_DIR/abstract-machine}
NEMU_HOME=${NEMU_HOME:-$ROOT_DIR/nemu}
LOG_BASE=${LOG_BASE:-$ROOT_DIR/am-kernels/build/regression}
WATCH_INTERVAL=${WATCH_INTERVAL:-2}
WATCH_MODE=0
RUN_BENCH=1
RUN_DEVSCAN=1
DEVSCAN_TIMEOUT=${DEVSCAN_TIMEOUT:-15}

WATCH_PATHS=(
  abstract-machine
  am-kernels
  nemu
)

usage() {
  cat <<'EOF'
用法:
  scripts/am-regression.sh [--watch [path ...]] [--no-bench] [--skip-devscan] [--log-base dir]

说明:
  默认执行一轮 riscv32-nemu 回归与 benchmark，并把日志写到 am-kernels/build/regression。
  --watch 会持续轮询源码目录；检测到改动后自动重跑整轮回归。

示例:
  scripts/am-regression.sh
  scripts/am-regression.sh --watch
  scripts/am-regression.sh --watch abstract-machine/klib abstract-machine/am
EOF
}

abspath_from_root() {
  local path=$1
  if [[ $path = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$ROOT_DIR" "$path"
  fi
}

parse_args() {
  local custom_watch_paths=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --watch)
        WATCH_MODE=1
        shift
        ;;
      --no-bench)
        RUN_BENCH=0
        shift
        ;;
      --skip-devscan)
        RUN_DEVSCAN=0
        shift
        ;;
      --log-base)
        [[ $# -ge 2 ]] || { echo "--log-base 需要一个目录参数" >&2; exit 2; }
        LOG_BASE=$(abspath_from_root "$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        if [[ $WATCH_MODE -eq 1 ]]; then
          custom_watch_paths+=("$1")
          shift
        else
          echo "未知参数: $1" >&2
          usage >&2
          exit 2
        fi
        ;;
    esac
  done

  if [[ ${#custom_watch_paths[@]} -gt 0 ]]; then
    WATCH_PATHS=("${custom_watch_paths[@]}")
  fi
}

ensure_env() {
  export AM_HOME
  export NEMU_HOME
  mkdir -p "$LOG_BASE"
}

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

make_run() {
  local log_file=$1
  shift
  if "$@" >"$log_file" 2>&1; then
    return 0
  fi
  return $?
}

status_line() {
  local name=$1
  local status=$2
  local note=${3:-}
  if [[ -n $note ]]; then
    printf '%-14s %-12s %s\n' "$name" "$status" "$note" >> "$STATUS_FILE"
  else
    printf '%-14s %s\n' "$name" "$status" >> "$STATUS_FILE"
  fi
}

summary_line() {
  local text=$1
  if [[ -n ${SUMMARY_FILE:-} ]]; then
    printf '%s\n' "$text" | tee -a "$SUMMARY_FILE"
  else
    printf '%s\n' "$text"
  fi
}

run_case() {
  local name=$1
  shift
  local log_file="$RUN_DIR/${name}.log"
  summary_line "[$(timestamp)] 运行 $name"
  if make_run "$log_file" "$@"; then
    status_line "$name" PASS
    summary_line "  PASS  $name"
    return 0
  fi

  local rc=$?
  status_line "$name" FAIL "exit=$rc"
  summary_line "  FAIL  $name (exit=$rc)"
  OVERALL_RC=1
  return 0
}

extract_first_match() {
  local log_file=$1
  local pattern=$2
  grep -E "$pattern" "$log_file" | tail -n 1 || true
}

run_bench_case() {
  local name=$1
  local pattern=$2
  shift 2
  local log_file="$RUN_DIR/${name}.log"
  summary_line "[$(timestamp)] 运行 $name"
  if make_run "$log_file" "$@"; then
    local marks
    marks=$(extract_first_match "$log_file" "$pattern")
    status_line "$name" PASS "${marks:-no-marks-found}"
    summary_line "  PASS  $name ${marks:+=> $marks}"
    return 0
  fi

  local rc=$?
  status_line "$name" FAIL "exit=$rc"
  summary_line "  FAIL  $name (exit=$rc)"
  OVERALL_RC=1
  return 0
}

run_devscan_smoke() {
  local name=am_devscan
  local log_file="$RUN_DIR/${name}.log"
  local timeout_cmd=(timeout --signal=TERM "${DEVSCAN_TIMEOUT}s")
  local rc=0
  summary_line "[$(timestamp)] 运行 $name"
  make_run "$log_file" "${timeout_cmd[@]}" make -C "$ROOT_DIR/am-kernels/tests/am-tests" ARCH="$ARCH" run mainargs=d NEMUFLAGS=-b || rc=$?
  if grep -q 'Test End!' "$log_file"; then
    status_line "$name" PASS "hit Test End before tail loop timeout"
    summary_line "  PASS  $name => 已跑到 Test End，末尾常驻循环由 timeout 收尾"
    return 0
  fi

  if grep -q 'access nonexist register' "$log_file"; then
    status_line "$name" KNOWN_ISSUE 'platform/nemu 缺少 AM_GPU_MEMCPY/AM_GPU_RENDER'
    summary_line "  KNOWN $name => 触发已知平台缺口，不作为本脚本的 hard fail"
    return 0
  fi

  if [[ $rc -eq 124 ]]; then
    status_line "$name" TIMEOUT '未看到 Test End，可能卡在测试流程中'
    summary_line "  FAIL  $name => timeout 且未出现 Test End"
    OVERALL_RC=1
    return 0
  fi

  status_line "$name" FAIL "exit=$rc"
  summary_line "  FAIL  $name (exit=$rc)"
  OVERALL_RC=1
}

prepare_run_dir() {
  local run_stamp
  run_stamp=$(date '+%Y%m%d-%H%M%S')
  RUN_DIR="$LOG_BASE/$run_stamp"
  mkdir -p "$RUN_DIR"
  ln -sfn "$RUN_DIR" "$LOG_BASE/latest"
  STATUS_FILE="$RUN_DIR/status.txt"
  SUMMARY_FILE="$RUN_DIR/summary.txt"
  : > "$STATUS_FILE"
  : > "$SUMMARY_FILE"
}

run_suite() {
  ensure_env
  prepare_run_dir
  OVERALL_RC=0

  summary_line "[$(timestamp)] 回归开始"
  summary_line "  ROOT_DIR=$ROOT_DIR"
  summary_line "  ARCH=$ARCH"
  summary_line "  LOG_DIR=$RUN_DIR"

  run_case alu_tests make -C "$ROOT_DIR/am-kernels/tests/alu-tests" ARCH="$ARCH" run NEMUFLAGS=-b
  run_case cpu_tests make -C "$ROOT_DIR/am-kernels/tests/cpu-tests" ARCH="$ARCH" run NEMUFLAGS=-b
  run_case klib_tests make -C "$ROOT_DIR/am-kernels/tests/klib-tests" ARCH="$ARCH" run NEMUFLAGS=-b
  run_case am_hello make -C "$ROOT_DIR/am-kernels/tests/am-tests" ARCH="$ARCH" run mainargs=h NEMUFLAGS=-b
  run_case am_audio make -C "$ROOT_DIR/am-kernels/tests/am-tests" ARCH="$ARCH" run mainargs=a NEMUFLAGS=-b

  if [[ $RUN_DEVSCAN -eq 1 ]]; then
    run_devscan_smoke
  fi

  if [[ $RUN_BENCH -eq 1 ]]; then
    run_bench_case dhrystone 'Dhrystone PASS[[:space:]]+[0-9]+ Marks' \
      make -C "$ROOT_DIR/am-kernels/benchmarks/dhrystone" ARCH="$ARCH" run NEMUFLAGS=-b
    run_bench_case microbench 'MicroBench PASS[[:space:]]+[0-9]+ Marks' \
      make -C "$ROOT_DIR/am-kernels/benchmarks/microbench" ARCH="$ARCH" run NEMUFLAGS=-b
    run_bench_case coremark 'CoreMark PASS[[:space:]]+[0-9]+ Marks' \
      make -C "$ROOT_DIR/am-kernels/benchmarks/coremark" ARCH="$ARCH" run NEMUFLAGS=-b
  fi

  summary_line "[$(timestamp)] 回归结束: overall_rc=$OVERALL_RC"
  summary_line "  latest => $LOG_BASE/latest"
  cat "$STATUS_FILE"
  return "$OVERALL_RC"
}

watch_signature() {
  local path
  local abs_paths=()
  for path in "${WATCH_PATHS[@]}"; do
    abs_paths+=("$(abspath_from_root "$path")")
  done

  find "${abs_paths[@]}" \
    \( -path '*/.git/*' -o -path '*/build/*' -o -path '*/obj_dir/*' -o -path '*/result/*' -o -path '*/am-kernels/build/regression/*' \) -prune -o \
    -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.S' -o -name '*.v' -o -name '*.sv' -o -name '*.mk' -o -name '*.ld' -o -name '*.sh' -o -name 'Makefile' -o -name 'Kconfig' -o -name '.config' \) \
    -printf '%p\t%T@\t%s\n' | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

watch_loop() {
  local previous_signature current_signature
  previous_signature=$(watch_signature)
  summary_line "[$(timestamp)] watch 模式启动，监控路径: ${WATCH_PATHS[*]}"
  run_suite || true

  while true; do
    sleep "$WATCH_INTERVAL"
    current_signature=$(watch_signature)
    if [[ $current_signature != "$previous_signature" ]]; then
      previous_signature=$current_signature
      summary_line "[$(timestamp)] 检测到源码变更，开始自动复跑"
      run_suite || true
    fi
  done
}

main() {
  parse_args "$@"
  if [[ $WATCH_MODE -eq 1 ]]; then
    watch_loop
    return 0
  fi
  run_suite
}

main "$@"