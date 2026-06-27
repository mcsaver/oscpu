#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
NPC_HOME=${NPC_HOME:-$ROOT_DIR/npc/rv64}
AM_HOME=${AM_HOME:-$ROOT_DIR/abstract-machine}
NEMU_HOME=${NEMU_HOME:-$ROOT_DIR/nemu}
ARTIFACT_ROOT=${ARTIFACT_ROOT:-$NPC_HOME/testsuites/core-tests}
RISCV_TESTS_REPO=${RISCV_TESTS_REPO:-https://github.com/riscv-software-src/riscv-tests.git}
RISCV_TESTS_DIR=${RISCV_TESTS_DIR:-$ARTIFACT_ROOT/src/riscv-tests}
LOG_BASE=${LOG_BASE:-$NPC_HOME/perf/results/core-regress}
RISCV_PREFIX=${RISCV_PREFIX:-riscv64-linux-gnu-}
RISCV_GCC_OPTS=${RISCV_GCC_OPTS:--static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none}
RISCV_MAX_CYCLES=${RISCV_MAX_CYCLES:-2000000}
RISCV_LIMIT=${RISCV_LIMIT:-0}
RISCV_FILTER=${RISCV_FILTER:-}
RISCV_SUITES_DEFAULT=(rv64ui rv64um rv64uc rv64uzba rv64uzbb rv64uzbc rv64uzbs)
RISCV_PRIVILEGED_SUITES=(rv64mi rv64si)
RISCV_SUITES=("${RISCV_SUITES_DEFAULT[@]}")

RUN_MODULE=1
RUN_LINT=1
RUN_BUILD=1
RUN_AM=1
RUN_RISCV=auto
FETCH_RISCV=0
OVERALL_RC=0

usage() {
  cat <<'EOF'
Usage:
  npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh [options]

Options:
  --fetch-riscv-tests       shallow-clone riscv-tests into npc/rv64/testsuites/core-tests and run it
  --riscv-tests             run riscv-tests if RISCV_TESTS_DIR already exists
  --no-riscv-tests          skip external riscv-tests
  --riscv-tests-dir DIR     use an existing riscv-tests checkout
  --riscv-suites LIST       comma-separated suites, e.g. rv64ui,rv64um,rv64uc
  --riscv-privileged        append privileged/exception suites: rv64mi,rv64si
  --riscv-filter REGEX      only run tests whose case or target name matches REGEX
  --riscv-limit N           run at most N external tests after building suites (0=all)
  --riscv-max-cycles N      per-test NPC cycle budget
  --skip-module             skip npc/rv64/testbench module regression
  --skip-lint               skip Verilator lint
  --skip-build              skip NPC simulator build
  --skip-am                 skip AM cpu-tests
  --quick                   shorthand: rv64ui,rv64um with --riscv-limit 16
  --log-base DIR            write logs under DIR
  -h, --help                show this help
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

split_suites() {
  local list=$1
  IFS=',' read -r -a RISCV_SUITES <<< "$list"
}

append_suites() {
  local list=$1
  local extra=()
  IFS=',' read -r -a extra <<< "$list"
  RISCV_SUITES+=("${extra[@]}")
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fetch-riscv-tests)
        FETCH_RISCV=1
        RUN_RISCV=1
        shift
        ;;
      --riscv-tests)
        RUN_RISCV=1
        shift
        ;;
      --no-riscv-tests)
        RUN_RISCV=0
        shift
        ;;
      --riscv-tests-dir)
        [[ $# -ge 2 ]] || { echo "--riscv-tests-dir requires DIR" >&2; exit 2; }
        RISCV_TESTS_DIR=$(abspath_from_root "$2")
        RUN_RISCV=1
        shift 2
        ;;
      --riscv-suites)
        [[ $# -ge 2 ]] || { echo "--riscv-suites requires LIST" >&2; exit 2; }
        split_suites "$2"
        RUN_RISCV=1
        shift 2
        ;;
      --riscv-privileged)
        append_suites "$(IFS=','; echo "${RISCV_PRIVILEGED_SUITES[*]}")"
        RUN_RISCV=1
        shift
        ;;
      --riscv-filter)
        [[ $# -ge 2 ]] || { echo "--riscv-filter requires REGEX" >&2; exit 2; }
        RISCV_FILTER=$2
        RUN_RISCV=1
        shift 2
        ;;
      --riscv-limit)
        [[ $# -ge 2 ]] || { echo "--riscv-limit requires N" >&2; exit 2; }
        RISCV_LIMIT=$2
        shift 2
        ;;
      --riscv-max-cycles)
        [[ $# -ge 2 ]] || { echo "--riscv-max-cycles requires N" >&2; exit 2; }
        RISCV_MAX_CYCLES=$2
        shift 2
        ;;
      --skip-module)
        RUN_MODULE=0
        shift
        ;;
      --skip-lint)
        RUN_LINT=0
        shift
        ;;
      --skip-build)
        RUN_BUILD=0
        shift
        ;;
      --skip-am)
        RUN_AM=0
        shift
        ;;
      --quick)
        split_suites "rv64ui,rv64um"
        RISCV_LIMIT=16
        RUN_RISCV=1
        shift
        ;;
      --log-base)
        [[ $# -ge 2 ]] || { echo "--log-base requires DIR" >&2; exit 2; }
        LOG_BASE=$(abspath_from_root "$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done
}

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

prepare_run_dir() {
  local stamp
  stamp=$(date '+%Y%m%d-%H%M%S')-$$
  RUN_DIR="$LOG_BASE/$stamp"
  mkdir -p "$RUN_DIR"/riscv-bin "$RUN_DIR"/riscv-log
  ln -sfn "$RUN_DIR" "$LOG_BASE/latest"
  STATUS_FILE="$RUN_DIR/status.txt"
  SUMMARY_FILE="$RUN_DIR/summary.txt"
  : > "$STATUS_FILE"
  : > "$SUMMARY_FILE"
}

summary_line() {
  printf '%s\n' "$1" | tee -a "$SUMMARY_FILE"
}

status_line() {
  local name=$1
  local status=$2
  local note=${3:-}
  if [[ -n $note ]]; then
    printf '%-28s %-10s %s\n' "$name" "$status" "$note" >> "$STATUS_FILE"
  else
    printf '%-28s %s\n' "$name" "$status" >> "$STATUS_FILE"
  fi
}

run_case() {
  local name=$1
  shift
  local log_file="$RUN_DIR/${name}.log"
  local rc=0
  summary_line "[$(timestamp)] run $name"
  "$@" >"$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    status_line "$name" PASS
    summary_line "  PASS  $name"
    return 0
  fi

  status_line "$name" FAIL "exit=$rc log=$log_file"
  summary_line "  FAIL  $name (exit=$rc, log=$log_file)"
  OVERALL_RC=1
  return 0
}

ensure_riscv_tests() {
  mkdir -p "$ARTIFACT_ROOT/src"
  if [[ ! -d $RISCV_TESTS_DIR/.git ]]; then
    if [[ $FETCH_RISCV -ne 1 ]]; then
      summary_line "  SKIP  riscv-tests checkout not found: $RISCV_TESTS_DIR"
      status_line riscv-tests SKIP "use --fetch-riscv-tests"
      return 1
    fi
    summary_line "[$(timestamp)] clone riscv-tests"
    if ! git clone --depth 1 "$RISCV_TESTS_REPO" "$RISCV_TESTS_DIR" >"$RUN_DIR/riscv-tests-clone.log" 2>&1; then
      status_line riscv-tests-fetch FAIL "clone failed"
      OVERALL_RC=1
      return 1
    fi
  fi

  if [[ ! -f $RISCV_TESTS_DIR/env/p/link.ld ]]; then
    summary_line "[$(timestamp)] init riscv-tests env submodule"
    if ! git -C "$RISCV_TESTS_DIR" submodule update --init --depth 1 env >"$RUN_DIR/riscv-tests-env.log" 2>&1; then
      status_line riscv-tests-env FAIL "submodule init failed"
      OVERALL_RC=1
      return 1
    fi
  fi
  return 0
}

tool_path() {
  command -v "${RISCV_PREFIX}$1" 2>/dev/null || true
}

tohost_addr() {
  local elf=$1
  "${RISCV_PREFIX}nm" "$elf" | sed -n 's/^\([0-9A-Fa-f]\+\).* tohost$/0x\1/p' | tail -n 1
}

build_riscv_target() {
  local target=$1
  local log_file="$RUN_DIR/riscv-build-${target}.log"
  local rc=0
  summary_line "[$(timestamp)] build $target"
  make -C "$RISCV_TESTS_DIR/isa" XLEN=64 RISCV_PREFIX="$RISCV_PREFIX" \
    RISCV_GCC_OPTS="$RISCV_GCC_OPTS" "${target}.dump" >"$log_file" 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    status_line "build-$target" PASS
    summary_line "  PASS  build $target"
    return 0
  fi

  status_line "build-$target" FAIL "exit=$rc log=$log_file"
  summary_line "  FAIL  build $target (exit=$rc, log=$log_file)"
  OVERALL_RC=1
  return 1
}

run_riscv_test() {
  local elf=$1
  local name
  local bin
  local log
  local tohost
  name=$(basename "$elf")
  bin="$RUN_DIR/riscv-bin/${name}.bin"
  log="$RUN_DIR/riscv-log/${name}.log"
  tohost=$(tohost_addr "$elf")
  if [[ -z $tohost ]]; then
    status_line "$name" FAIL "missing tohost symbol"
    summary_line "  FAIL  $name (missing tohost symbol)"
    OVERALL_RC=1
    return 0
  fi

  if ! "${RISCV_PREFIX}objcopy" -O binary "$elf" "$bin" >"$log.objcopy" 2>&1; then
    status_line "$name" FAIL "objcopy failed"
    summary_line "  FAIL  $name (objcopy failed)"
    OVERALL_RC=1
    return 0
  fi

  if "$NPC_HOME/build/NpcSimTop" -b --no-diff --max-cycles "$RISCV_MAX_CYCLES" \
      --tohost="$tohost" "$bin" >"$log" 2>&1; then
    if grep -q 'TOHOST PASS' "$log"; then
      status_line "$name" PASS "tohost=$tohost"
      summary_line "  PASS  $name"
    elif grep -q 'HIT GOOD TRAP' "$log"; then
      status_line "$name" PASS "good-trap tohost=$tohost"
      summary_line "  PASS  $name (good trap)"
    else
      status_line "$name" FAIL "no TOHOST PASS marker"
      summary_line "  FAIL  $name (no TOHOST PASS marker)"
      OVERALL_RC=1
    fi
  else
    local rc=$?
    status_line "$name" FAIL "exit=$rc tohost=$tohost"
    summary_line "  FAIL  $name (exit=$rc)"
    OVERALL_RC=1
  fi
}

run_riscv_tests() {
  if [[ $RUN_RISCV == auto && ! -d $RISCV_TESTS_DIR/.git ]]; then
    status_line riscv-tests SKIP "checkout absent"
    summary_line "  SKIP  riscv-tests checkout absent; pass --fetch-riscv-tests to pull it"
    return 0
  fi
  [[ $RUN_RISCV == 0 ]] && return 0
  ensure_riscv_tests || return 0

  if [[ -z $(tool_path gcc) || -z $(tool_path objcopy) || -z $(tool_path nm) ]]; then
    status_line riscv-toolchain FAIL "missing ${RISCV_PREFIX}{gcc,objcopy,nm}"
    summary_line "  FAIL  missing RISC-V toolchain prefix: $RISCV_PREFIX"
    OVERALL_RC=1
    return 0
  fi

  run_case riscv-clean make -C "$RISCV_TESTS_DIR/isa" XLEN=64 RISCV_PREFIX="$RISCV_PREFIX" clean

  local count=0
  local elf
  local src
  local suite
  local case_name
  local target
  shopt -s nullglob
  for suite in "${RISCV_SUITES[@]}"; do
    for src in "$RISCV_TESTS_DIR"/isa/"$suite"/*.S; do
      [[ -f $src ]] || continue
      case_name=$(basename "$src" .S)
      target="$suite-p-$case_name"
      if [[ -n $RISCV_FILTER && ! $case_name =~ $RISCV_FILTER && ! $target =~ $RISCV_FILTER ]]; then
        continue
      fi
      build_riscv_target "$target" || continue
      elf="$RISCV_TESTS_DIR/isa/$target"
      run_riscv_test "$elf"
      count=$((count + 1))
      if [[ $RISCV_LIMIT -gt 0 && $count -ge $RISCV_LIMIT ]]; then
        shopt -u nullglob
        summary_line "  INFO  riscv-tests limit reached: $RISCV_LIMIT"
        status_line riscv-tests-count INFO "$count tests attempted"
        return 0
      fi
    done
  done
  shopt -u nullglob
  status_line riscv-tests-count INFO "$count tests attempted"
}

main() {
  parse_args "$@"
  export AM_HOME NEMU_HOME NPC_HOME
  prepare_run_dir
  summary_line "NPC RV64 core regression"
  summary_line "  run_dir: $RUN_DIR"
  summary_line "  riscv_suites: ${RISCV_SUITES[*]}"
  if [[ -n $RISCV_FILTER ]]; then
    summary_line "  riscv_filter: $RISCV_FILTER"
  fi

  if [[ $RUN_MODULE -eq 1 ]]; then
    run_case module-testbench make -C "$NPC_HOME/testbench" RESULT_DIR="$RUN_DIR/module-testbench" run
  fi
  if [[ $RUN_LINT -eq 1 ]]; then
    run_case verilator-lint make -C "$NPC_HOME" lint
  fi
  if [[ $RUN_BUILD -eq 1 ]]; then
    run_case npc-build make -C "$NPC_HOME" -j2
  fi
  if [[ $RUN_AM -eq 1 ]]; then
    run_case am-cpu-tests make -C "$ROOT_DIR/am-kernels/tests/cpu-tests" ARCH=riscv64-npc run
  fi
  run_riscv_tests

  summary_line "[$(timestamp)] done overall_rc=$OVERALL_RC"
  summary_line "  status: $STATUS_FILE"
  exit "$OVERALL_RC"
}

main "$@"
