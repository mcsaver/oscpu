#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ARCH_TEST_HOME=$(cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd -- "$ARCH_TEST_HOME/../.." && pwd)

NPC_RV64_HOME=${NPC_RV64_HOME:-"$REPO_ROOT/npc/rv64"}
NEMU_HOME=${NEMU_HOME:-"$REPO_ROOT/nemu"}
ARCH_TEST_HOME=${ARCH_TEST_HOME:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
ARTIFACT_ROOT=${ARTIFACT_ROOT:-"$ARCH_TEST_HOME"}
CONFIG_NAME=${CONFIG_NAME:-sail-rv64-max}
WORKDIR=${WORKDIR:-"$ARTIFACT_ROOT/work"}
ELF_ROOT=${ELF_ROOT:-"$WORKDIR/$CONFIG_NAME/elfs"}
ACT4_EXTENSIONS=${ACT4_EXTENSIONS:-rv64i}
ACT4_SUITES=${ACT4_SUITES:-rv64i/I}
ACT4_FILTER=${ACT4_FILTER:-}
ACT4_LIMIT=${ACT4_LIMIT:-0}
ACT4_TIMEOUT_SEC=${ACT4_TIMEOUT_SEC:-60}
ACT4_MAX_INSTS=${ACT4_MAX_INSTS:-20000000}
ACT4_MAX_CYCLES=${ACT4_MAX_CYCLES:-20000000}
ACT4_TARGET=${ARCH_TEST_TARGET:-${ACT4_TARGET:-nemu}}
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}

BUILD_DIR=${BUILD_DIR:-"$ARCH_TEST_HOME/build"}
BIN_DIR=${BIN_DIR:-"$BUILD_DIR/bin"}
LOG_DIR=${LOG_DIR:-"$BUILD_DIR/logs"}
SUMMARY_TSV=${SUMMARY_TSV:-"$BUILD_DIR/summary.tsv"}
NEMU_BIN=${NEMU_BIN:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
NPC_BIN=${NPC_BIN:-"$NPC_RV64_HOME/build/NpcSimTop"}
XPACK_GCC_DIR=${XPACK_GCC_DIR:-}

BUILD_FINAL=0
BUILD_NEMU=0
BUILD_NPC=0
LIST_SUITES=0

usage() {
  cat <<'USAGE'
Usage: act4-arch-run.sh [options]

Options:
  --target nemu|npc|both       backend to run, default: nemu
  --suites LIST                ACT4 suite list, comma/space separated, default: rv64i/I
  --filter TEXT                only run ELF basenames containing TEXT
  --limit N                    stop after N selected ELFs, 0 means no limit
  --build-final                rebuild final ACT4 ELFs through npc testsuites preflight
  --build-nemu                 build current NEMU before running
  --build-npc                  build current npc/rv64 before running
  --list-suites                list suites available under ELF_ROOT and exit
  --elf-root DIR               override generated ACT4 ELF root
  --workdir DIR                override ACT4 workdir
  --config-name NAME           ACT4 config name under workdir
  --artifact-root DIR          override npc testsuites/core-tests artifact root
  --max-insts N                NEMU retired-instruction budget
  --max-cycles N               NPC cycle budget
  --timeout-sec N              host timeout per case
  -h, --help                   show this help
USAGE
}

die() {
  echo "[act4-arch] error: $*" >&2
  exit 1
}

info() {
  echo "[act4-arch] $*"
}

while (($# > 0)); do
  case "$1" in
    --target) ACT4_TARGET=${2:?}; shift 2 ;;
    --suites) ACT4_SUITES=${2:?}; shift 2 ;;
    --filter) ACT4_FILTER=${2:?}; shift 2 ;;
    --limit) ACT4_LIMIT=${2:?}; shift 2 ;;
    --build-final) BUILD_FINAL=1; shift ;;
    --build-nemu) BUILD_NEMU=1; shift ;;
    --build-npc) BUILD_NPC=1; shift ;;
    --list-suites) LIST_SUITES=1; shift ;;
    --elf-root) ELF_ROOT=${2:?}; shift 2 ;;
    --workdir) WORKDIR=${2:?}; ELF_ROOT="$WORKDIR/$CONFIG_NAME/elfs"; shift 2 ;;
    --config-name) CONFIG_NAME=${2:?}; ELF_ROOT="$WORKDIR/$CONFIG_NAME/elfs"; shift 2 ;;
    --artifact-root) ARTIFACT_ROOT=${2:?}; WORKDIR="$ARTIFACT_ROOT/work"; ELF_ROOT="$WORKDIR/$CONFIG_NAME/elfs"; shift 2 ;;
    --max-insts) ACT4_MAX_INSTS=${2:?}; shift 2 ;;
    --max-cycles) ACT4_MAX_CYCLES=${2:?}; shift 2 ;;
    --timeout-sec) ACT4_TIMEOUT_SEC=${2:?}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

case "$ACT4_TARGET" in
  nemu|npc|both) ;;
  *) die "--target must be nemu, npc, or both" ;;
esac

find_xpack_dir() {
  if [[ -n "$XPACK_GCC_DIR" ]]; then
    echo "$XPACK_GCC_DIR"
    return
  fi
  find "$ARTIFACT_ROOT/env" -maxdepth 1 -type d -name 'xpack-riscv-none-elf-gcc-*' \
    | sort | tail -n 1
}

resolve_riscv_tool() {
  local tool=$1
  local xpack_dir
  xpack_dir=$(find_xpack_dir || true)
  if [[ -n "$xpack_dir" && -x "$xpack_dir/bin/riscv-none-elf-$tool" ]]; then
    echo "$xpack_dir/bin/riscv-none-elf-$tool"
    return
  fi

  local prefix
  for prefix in riscv-none-elf- riscv64-unknown-elf- riscv64-linux-gnu-; do
    if command -v "${prefix}${tool}" >/dev/null 2>&1; then
      command -v "${prefix}${tool}"
      return
    fi
  done
  die "can not find RISC-V tool: $tool"
}

list_suites() {
  [[ -d "$ELF_ROOT" ]] || die "ELF_ROOT not found: $ELF_ROOT"
  find "$ELF_ROOT" -mindepth 2 -maxdepth 2 -type d \
    | sed "s#^$ELF_ROOT/##" | sort
}

build_final_elfs() {
  local preflight="$ARCH_TEST_HOME/scripts/act4-preflight.sh"
  [[ -f "$preflight" ]] || die "ACT4 preflight not found: $preflight"
  info "building ACT4 final ELFs: extensions=$ACT4_EXTENSIONS config=$CONFIG_NAME"
  ARTIFACT_ROOT="$ARTIFACT_ROOT" bash "$preflight" \
    --final-elfs \
    --extensions "$ACT4_EXTENSIONS" \
    --workdir "$WORKDIR" \
    --config-name "$CONFIG_NAME"
}

build_backends() {
  if [[ "$BUILD_NEMU" == 1 ]]; then
    info "building NEMU"
    make -C "$NEMU_HOME" NEMU_HOME="$NEMU_HOME" -j"$JOBS"
  fi
  if [[ "$BUILD_NPC" == 1 ]]; then
    info "building npc/rv64"
    make -C "$NPC_RV64_HOME" -j"$JOBS"
  fi
}

selected_elfs=()

split_suites() {
  local raw=${ACT4_SUITES//,/ }
  # shellcheck disable=SC2206
  echo ${raw}
}

collect_elfs() {
  [[ -d "$ELF_ROOT" ]] || die "ELF_ROOT not found: $ELF_ROOT"

  local count=0
  local suite
  for suite in $(split_suites); do
    local suite_dir="$ELF_ROOT/$suite"
    [[ -d "$suite_dir" ]] || die "suite not found: $suite (under $ELF_ROOT)"
    while IFS= read -r elf; do
      local base
      base=$(basename "$elf" .elf)
      if [[ -n "$ACT4_FILTER" && "$base" != *"$ACT4_FILTER"* ]]; then
        continue
      fi
      selected_elfs+=("$elf")
      count=$((count + 1))
      if [[ "$ACT4_LIMIT" != 0 && "$count" -ge "$ACT4_LIMIT" ]]; then
        return
      fi
    done < <(find "$suite_dir" -maxdepth 1 -type f -name '*.elf' | sort)
  done
}

tohost_addr_of() {
  local elf=$1
  "$RISCV_NM" -g "$elf" | awk '$NF == "tohost" { print "0x" $1; exit }'
}

bin_of() {
  local elf=$1
  local rel=${elf#"$ELF_ROOT"/}
  rel=${rel%.elf}
  rel=${rel//\//__}
  echo "$BIN_DIR/$rel.bin"
}

log_of() {
  local target=$1
  local elf=$2
  local rel=${elf#"$ELF_ROOT"/}
  rel=${rel%.elf}
  rel=${rel//\//__}
  echo "$LOG_DIR/$rel.$target.log"
}

case_suite_of() {
  local elf=$1
  local rel=${elf#"$ELF_ROOT"/}
  dirname "$rel"
}

case_name_of() {
  basename "$1" .elf
}

make_bin() {
  local elf=$1
  local bin=$2
  mkdir -p "$(dirname "$bin")"
  "$RISCV_OBJCOPY" -O binary "$elf" "$bin"
}

run_nemu_case() {
  local elf=$1
  local bin=$2
  local tohost=$3
  local log=$4

  [[ -x "$NEMU_BIN" ]] || die "NEMU binary not found or not executable: $NEMU_BIN"
  set +e
  timeout "${ACT4_TIMEOUT_SEC}s" "$NEMU_BIN" \
    -b \
    -l "$log.nemu.txt" \
    -e "$elf" \
    --tohost="$tohost" \
    --max-insts="$ACT4_MAX_INSTS" \
    "$bin" >"$log" 2>&1
  local rc=$?
  set -e
  if [[ "$rc" == 0 ]]; then
    if grep -Eq 'TOHOST PASS|HIT GOOD TRAP' "$log"; then
      return 0
    fi
    return 1
  fi
  return "$rc"
}

run_npc_case() {
  local elf=$1
  local bin=$2
  local tohost=$3
  local log=$4

  [[ -x "$NPC_BIN" ]] || die "NPC binary not found or not executable: $NPC_BIN"
  set +e
  timeout "${ACT4_TIMEOUT_SEC}s" "$NPC_BIN" \
    -b \
    --no-diff \
    --max-cycles "$ACT4_MAX_CYCLES" \
    --tohost="$tohost" \
    "$bin" >"$log" 2>&1
  local rc=$?
  set -e
  if [[ "$rc" == 0 ]]; then
    if grep -Eq 'TOHOST PASS|HIT GOOD TRAP' "$log"; then
      return 0
    fi
    return 1
  fi
  return "$rc"
}

run_one_target() {
  local target=$1
  local elf=$2
  local suite
  local name
  local bin
  local log
  local tohost
  suite=$(case_suite_of "$elf")
  name=$(case_name_of "$elf")
  bin=$(bin_of "$elf")
  log=$(log_of "$target" "$elf")
  mkdir -p "$(dirname "$log")"

  tohost=$(tohost_addr_of "$elf")
  [[ -n "$tohost" ]] || die "ELF has no tohost symbol: $elf"
  make_bin "$elf" "$bin"

  local rc=0
  if [[ "$target" == nemu ]]; then
    run_nemu_case "$elf" "$bin" "$tohost" "$log" || rc=$?
  else
    run_npc_case "$elf" "$bin" "$tohost" "$log" || rc=$?
  fi

  if [[ "$rc" == 0 ]]; then
    printf '%s\t%s\t%s\tPASS\t0\t%s\n' "$target" "$suite" "$name" "$log" >>"$SUMMARY_TSV"
    echo "[PASS] $target $suite/$name"
    return 0
  fi

  printf '%s\t%s\t%s\tFAIL\t%s\t%s\n' "$target" "$suite" "$name" "$rc" "$log" >>"$SUMMARY_TSV"
  echo "[FAIL] $target $suite/$name rc=$rc log=$log"
  return 1
}

main() {
  if [[ "$BUILD_FINAL" == 1 ]]; then
    build_final_elfs
  fi
  if [[ "$LIST_SUITES" == 1 ]]; then
    list_suites
    exit 0
  fi

  build_backends
  RISCV_NM=$(resolve_riscv_tool nm)
  RISCV_OBJCOPY=$(resolve_riscv_tool objcopy)
  mkdir -p "$BIN_DIR" "$LOG_DIR"
  printf 'target\tsuite\tcase\tstatus\trc\tlog\n' >"$SUMMARY_TSV"

  collect_elfs
  [[ "${#selected_elfs[@]}" -gt 0 ]] || die "no ACT4 ELF selected"

  info "ELF_ROOT=$ELF_ROOT"
  info "target=$ACT4_TARGET suites=$ACT4_SUITES filter=${ACT4_FILTER:-<none>} count=${#selected_elfs[@]}"

  local pass=0
  local fail=0
  local elf
  local target
  for elf in "${selected_elfs[@]}"; do
    if [[ "$ACT4_TARGET" == both ]]; then
      for target in nemu npc; do
        if run_one_target "$target" "$elf"; then
          pass=$((pass + 1))
        else
          fail=$((fail + 1))
        fi
      done
    else
      if run_one_target "$ACT4_TARGET" "$elf"; then
        pass=$((pass + 1))
      else
        fail=$((fail + 1))
      fi
    fi
  done

  info "summary: pass=$pass fail=$fail file=$SUMMARY_TSV"
  [[ "$fail" == 0 ]]
}

main "$@"
