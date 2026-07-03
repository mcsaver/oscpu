#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
NPC_HOME=${NPC_HOME:-$ROOT_DIR/npc/rv64}
ARCH_TEST_HOME=${ARCH_TEST_HOME:-$ROOT_DIR/am-kernels/arch-test}
ARTIFACT_ROOT=${ARTIFACT_ROOT:-$ARCH_TEST_HOME}
WORKDIR=${WORKDIR:-$ARTIFACT_ROOT/work}
CONFIG_NAME=${CONFIG_NAME:-sail-rv64-max}
ELF_ROOT=${ELF_ROOT:-$WORKDIR/$CONFIG_NAME/elfs}
ACT4_CONFIG_SRC_DIR=${ACT4_CONFIG_SRC_DIR:-}
LOG_BASE=${LOG_BASE:-$NPC_HOME/perf/results/act4-run}
XPACK_GCC_VERSION=${XPACK_GCC_VERSION:-15.2.0-1}
XPACK_GCC_DIR=${XPACK_GCC_DIR:-$ARTIFACT_ROOT/env/xpack-riscv-none-elf-gcc-$XPACK_GCC_VERSION}
RISCV_NM=${RISCV_NM:-$XPACK_GCC_DIR/bin/riscv-none-elf-nm}
RISCV_OBJCOPY=${RISCV_OBJCOPY:-$XPACK_GCC_DIR/bin/riscv-none-elf-objcopy}
NPC_BIN=${NPC_BIN:-$NPC_HOME/build/NpcSimTop}
ACT4_PREFLIGHT=${ACT4_PREFLIGHT:-$ARCH_TEST_HOME/scripts/act4-preflight.sh}
ACT4_EXTENSIONS=${ACT4_EXTENSIONS:-I}
ACT4_SUITES=${ACT4_SUITES:-rv64i/I}
ACT4_FILTER=${ACT4_FILTER:-}
ACT4_LIMIT=${ACT4_LIMIT:-0}
ACT4_MAX_CYCLES=${ACT4_MAX_CYCLES:-20000000}
ACT4_TIMEOUT_SEC=${ACT4_TIMEOUT_SEC:-60}

RUN_BUILD_FINAL=0
RUN_BUILD_NPC=0
ELF_ROOT_EXPLICIT=0
RUN_LIST_SUITES=0
OVERALL_RC=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
ATTEMPT_COUNT=0

usage() {
  cat <<'EOF'
Usage:
  npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh [options]

Options:
  --build-final          Build ACT4 final self-checking ELFs before running NPC
  --build-npc            Build npc/rv64 Verilator simulator before running ELFs
  --list-suites          List available final ELF suite dirs and exit
  --workdir DIR          ACT4 workdir, default: npc/rv64/testsuites/core-tests/act4-npc-final-work-script
  --elf-root DIR         Root containing ACT4 elfs/<suite> directories
  --config-name NAME     ACT config name/output dir, default: sail-rv64-max
  --config-src DIR       Source config dir for --build-final, default: preflight auto-resolves by config name
  --suites LIST          Comma-separated final ELF suite dirs, default: rv64i/I
  --extensions LIST      ACT4 extension list for --build-final, default: I
  --filter REGEX         Run only ELF basenames matching REGEX
  --limit N              Run at most N matching ELFs, default: 0 means all
  --max-cycles N         NPC max cycles per ELF, default: 20000000
  --timeout-sec N        Host timeout per ELF, default: 60
  --log-base DIR         Result root, default: npc/rv64/perf/results/act4-run
  -h, --help             Show this help

Notes:
  - This runner executes ACT4 final self-checking elfs/.../*.elf.
  - Do not feed build/.../*.sig.elf into NPC; those are reference signature intermediates.
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

set_config_name() {
  CONFIG_NAME=$1
  if [[ $ELF_ROOT_EXPLICIT -eq 0 ]]; then
    ELF_ROOT="$WORKDIR/$CONFIG_NAME/elfs"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-final)
        RUN_BUILD_FINAL=1
        shift
        ;;
      --build-npc)
        RUN_BUILD_NPC=1
        shift
        ;;
      --list-suites)
        RUN_LIST_SUITES=1
        shift
        ;;
      --workdir)
        [[ $# -ge 2 ]] || { echo "--workdir requires DIR" >&2; exit 2; }
        WORKDIR=$(abspath_from_root "$2")
        if [[ $ELF_ROOT_EXPLICIT -eq 0 ]]; then
          ELF_ROOT="$WORKDIR/$CONFIG_NAME/elfs"
        fi
        shift 2
        ;;
      --elf-root)
        [[ $# -ge 2 ]] || { echo "--elf-root requires DIR" >&2; exit 2; }
        ELF_ROOT=$(abspath_from_root "$2")
        ELF_ROOT_EXPLICIT=1
        shift 2
        ;;
      --config-name)
        [[ $# -ge 2 ]] || { echo "--config-name requires NAME" >&2; exit 2; }
        set_config_name "$2"
        shift 2
        ;;
      --config-src)
        [[ $# -ge 2 ]] || { echo "--config-src requires DIR" >&2; exit 2; }
        ACT4_CONFIG_SRC_DIR=$(abspath_from_root "$2")
        shift 2
        ;;
      --suites)
        [[ $# -ge 2 ]] || { echo "--suites requires LIST" >&2; exit 2; }
        ACT4_SUITES=$2
        shift 2
        ;;
      --extensions)
        [[ $# -ge 2 ]] || { echo "--extensions requires LIST" >&2; exit 2; }
        ACT4_EXTENSIONS=$2
        shift 2
        ;;
      --filter)
        [[ $# -ge 2 ]] || { echo "--filter requires REGEX" >&2; exit 2; }
        ACT4_FILTER=$2
        shift 2
        ;;
      --limit)
        [[ $# -ge 2 ]] || { echo "--limit requires N" >&2; exit 2; }
        ACT4_LIMIT=$2
        shift 2
        ;;
      --max-cycles)
        [[ $# -ge 2 ]] || { echo "--max-cycles requires N" >&2; exit 2; }
        ACT4_MAX_CYCLES=$2
        shift 2
        ;;
      --timeout-sec)
        [[ $# -ge 2 ]] || { echo "--timeout-sec requires N" >&2; exit 2; }
        ACT4_TIMEOUT_SEC=$2
        shift 2
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
  mkdir -p "$RUN_DIR"/act4-bin "$RUN_DIR"/act4-log
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
    printf '%-32s %-10s %s\n' "$name" "$status" "$note" >> "$STATUS_FILE"
  else
    printf '%-32s %s\n' "$name" "$status" >> "$STATUS_FILE"
  fi
}

fail_global() {
  summary_line "  FAIL  $*"
  OVERALL_RC=1
}

check_tools() {
  local rc=0
  if [[ ! -x $RISCV_NM ]]; then
    fail_global "missing nm: $RISCV_NM"
    rc=1
  fi
  if [[ ! -x $RISCV_OBJCOPY ]]; then
    fail_global "missing objcopy: $RISCV_OBJCOPY"
    rc=1
  fi
  if [[ ! -x $NPC_BIN ]]; then
    fail_global "missing NPC simulator: $NPC_BIN (use --build-npc or make -C npc/rv64)"
    rc=1
  fi
  return "$rc"
}

available_suites() {
  if [[ ! -d $ELF_ROOT ]]; then
    return 0
  fi
  find "$ELF_ROOT" -mindepth 2 -maxdepth 2 -type d \
    | sed "s#^$ELF_ROOT/##" \
    | sort \
    | paste -sd, -
}

build_final_elfs() {
  summary_line "[$(timestamp)] build ACT4 final ELFs extensions=$ACT4_EXTENSIONS"
  if [[ -n $ACT4_CONFIG_SRC_DIR ]]; then
    CONFIG_NAME="$CONFIG_NAME" ACT4_CONFIG_SRC_DIR="$ACT4_CONFIG_SRC_DIR" \
      "$ACT4_PREFLIGHT" --final-elfs --extensions "$ACT4_EXTENSIONS" --workdir "$WORKDIR" \
      >"$RUN_DIR/act4-final-build.log" 2>&1
  else
    CONFIG_NAME="$CONFIG_NAME" \
      "$ACT4_PREFLIGHT" --final-elfs --extensions "$ACT4_EXTENSIONS" --workdir "$WORKDIR" \
      >"$RUN_DIR/act4-final-build.log" 2>&1
  fi
}

build_npc() {
  summary_line "[$(timestamp)] build NPC simulator"
  make -C "$NPC_HOME" -j2 >"$RUN_DIR/npc-build.log" 2>&1
}

collect_elfs() {
  local suite
  local suite_dir
  local found=0
  IFS=',' read -r -a SUITE_LIST <<< "$ACT4_SUITES"
  : > "$RUN_DIR/elf-list.txt"
  for suite in "${SUITE_LIST[@]}"; do
    suite_dir="$ELF_ROOT/$suite"
    if [[ ! -d $suite_dir ]]; then
      local available
      available=$(available_suites)
      status_line "$suite" SKIP "missing suite dir: $suite_dir available=${available:-<none>}"
      SKIP_COUNT=$((SKIP_COUNT + 1))
      continue
    fi
    find "$suite_dir" -maxdepth 1 -type f -name '*.elf' | sort >> "$RUN_DIR/elf-list.txt"
    found=1
  done
  if [[ $found -eq 0 || ! -s $RUN_DIR/elf-list.txt ]]; then
    fail_global "no ACT4 final ELF found under $ELF_ROOT for suites=$ACT4_SUITES"
    return 1
  fi
}

tohost_addr() {
  local elf=$1
  "$RISCV_NM" "$elf" | sed -n 's/^\([0-9A-Fa-f]\+\).* tohost$/0x\1/p' | tail -n 1
}

run_one_elf() {
  local elf=$1
  local name
  local bin
  local log
  local objcopy_log
  local tohost
  local rc

  name=$(basename "$elf" .elf)
  if [[ -n $ACT4_FILTER && ! $name =~ $ACT4_FILTER ]]; then
    return 0
  fi
  if [[ $ACT4_LIMIT -gt 0 && $ATTEMPT_COUNT -ge $ACT4_LIMIT ]]; then
    return 0
  fi

  ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
  bin="$RUN_DIR/act4-bin/$name.bin"
  log="$RUN_DIR/act4-log/$name.log"
  objcopy_log="$RUN_DIR/act4-log/$name.objcopy.log"

  summary_line "[$(timestamp)] run $name"
  tohost=$(tohost_addr "$elf")
  if [[ -z $tohost ]]; then
    status_line "$name" FAIL "missing tohost symbol"
    summary_line "  FAIL  $name (missing tohost symbol)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    OVERALL_RC=1
    return 0
  fi

  if ! "$RISCV_OBJCOPY" -O binary "$elf" "$bin" >"$objcopy_log" 2>&1; then
    status_line "$name" FAIL "objcopy failed log=$objcopy_log"
    summary_line "  FAIL  $name (objcopy failed)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    OVERALL_RC=1
    return 0
  fi

  timeout "${ACT4_TIMEOUT_SEC}s" "$NPC_BIN" -b --no-diff \
    --max-cycles "$ACT4_MAX_CYCLES" --tohost="$tohost" "$bin" >"$log" 2>&1
  rc=$?

  if [[ $rc -eq 0 && $(grep -c 'TOHOST PASS' "$log") -gt 0 ]]; then
    status_line "$name" PASS "tohost=$tohost"
    summary_line "  PASS  $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    return 0
  fi

  if [[ $rc -eq 124 ]]; then
    status_line "$name" FAIL "timeout=${ACT4_TIMEOUT_SEC}s tohost=$tohost log=$log"
    summary_line "  FAIL  $name (host timeout)"
  elif grep -q 'TOHOST FAIL' "$log"; then
    status_line "$name" FAIL "tohost fail tohost=$tohost log=$log"
    summary_line "  FAIL  $name (tohost fail)"
  else
    status_line "$name" FAIL "exit=$rc no TOHOST PASS log=$log"
    summary_line "  FAIL  $name (exit=$rc, no TOHOST PASS)"
  fi
  FAIL_COUNT=$((FAIL_COUNT + 1))
  OVERALL_RC=1
}

run_elfs() {
  local elf
  while IFS= read -r elf; do
    [[ -n $elf ]] || continue
    run_one_elf "$elf"
  done < "$RUN_DIR/elf-list.txt"
  if [[ $ATTEMPT_COUNT -eq 0 ]]; then
    status_line act4-count FAIL "no matching ELF executed filter=${ACT4_FILTER:-<none>}"
    summary_line "  FAIL  no matching ACT4 ELF executed"
    OVERALL_RC=1
  fi
  status_line act4-count INFO "attempted=$ATTEMPT_COUNT pass=$PASS_COUNT fail=$FAIL_COUNT skip=$SKIP_COUNT"
  summary_line "  attempted=$ATTEMPT_COUNT pass=$PASS_COUNT fail=$FAIL_COUNT skip=$SKIP_COUNT"
}

main() {
  parse_args "$@"

  if [[ $RUN_LIST_SUITES -eq 1 && $RUN_BUILD_FINAL -eq 0 && $RUN_BUILD_NPC -eq 0 ]]; then
    available_suites
    exit 0
  fi

  prepare_run_dir
  summary_line "NPC RV64 ACT4 final ELF runner"
  summary_line "  run_dir: $RUN_DIR"
  summary_line "  workdir: $WORKDIR"
  summary_line "  config_name: $CONFIG_NAME"
  if [[ -n $ACT4_CONFIG_SRC_DIR ]]; then
    summary_line "  config_src: $ACT4_CONFIG_SRC_DIR"
  fi
  summary_line "  elf_root: $ELF_ROOT"
  summary_line "  suites: $ACT4_SUITES"
  if [[ -n $ACT4_FILTER ]]; then
    summary_line "  filter: $ACT4_FILTER"
  fi

  if [[ $RUN_BUILD_NPC -eq 1 ]]; then
    if build_npc; then
      status_line npc-build PASS
    else
      status_line npc-build FAIL "log=$RUN_DIR/npc-build.log"
      OVERALL_RC=1
    fi
  fi

  if [[ $RUN_BUILD_FINAL -eq 1 ]]; then
    if build_final_elfs; then
      status_line act4-final-build PASS
    else
      status_line act4-final-build FAIL "log=$RUN_DIR/act4-final-build.log"
      OVERALL_RC=1
    fi
  fi

  if [[ $RUN_LIST_SUITES -eq 1 ]]; then
    available_suites
    exit 0
  fi

  check_tools || exit "$OVERALL_RC"
  collect_elfs || exit "$OVERALL_RC"
  run_elfs

  summary_line "[$(timestamp)] done overall_rc=$OVERALL_RC"
  summary_line "  status: $STATUS_FILE"
  exit "$OVERALL_RC"
}

main "$@"
