#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
NEMU_HOME=${NEMU_HOME:-"$(cd -- "$SCRIPT_DIR/.." && pwd)"}
NEMU_SIM=${NEMU_SIM:-"$NEMU_HOME/build/riscv64-nemu-interpreter"}
CROSS_COMPILE=${CROSS_COMPILE:-riscv64-linux-gnu-}
PAYLOAD=${NEMU_RV64_RETIRE_PAYLOAD:-"$SCRIPT_DIR/rv64-retirement-sdtrig-smoke.S"}
TIMEOUT_SECONDS=${NEMU_RV64_RETIRE_TIMEOUT:-20}

if (( $# != 0 )); then
  printf 'Usage: %s\n' "$0" >&2
  exit 2
fi
if [[ ! -x $NEMU_SIM ]]; then
  printf 'NEMU binary is missing or not executable: %s\n' "$NEMU_SIM" >&2
  exit 2
fi
if [[ ! -f $PAYLOAD ]]; then
  printf 'RV64 retirement payload is missing: %s\n' "$PAYLOAD" >&2
  exit 2
fi
CC=${CROSS_COMPILE}gcc
OBJCOPY=${CROSS_COMPILE}objcopy
NM=${CROSS_COMPILE}nm
command -v "$CC" >/dev/null
command -v "$OBJCOPY" >/dev/null
command -v "$NM" >/dev/null
command -v timeout >/dev/null

temp_root=${TMPDIR:-/tmp}
temp_root=$(cd -- "$temp_root" && pwd -P)
work_dir=$(mktemp -d "$temp_root/nemu-rv64-retire.XXXXXX")
cleanup() {
  if [[ -n ${work_dir:-} && -d $work_dir &&
        $work_dir == "$temp_root"/nemu-rv64-retire.* ]]; then
    rm -rf -- "$work_dir"
  fi
}
trap cleanup EXIT

"$CC" -x assembler-with-cpp -nostdlib -nostartfiles \
  -march=rv64ima_zicsr_zifencei -mabi=lp64 -static -no-pie \
  -Wl,-Ttext=0x80000000 -Wl,-e,_start -Wl,--no-relax \
  -Wl,--build-id=none "$PAYLOAD" -o "$work_dir/payload.elf"
"$OBJCOPY" -O binary "$work_dir/payload.elf" "$work_dir/payload.bin"
tohost_addr=$("$NM" -n "$work_dir/payload.elf" |
  awk '$3 == "tohost" { print "0x" $1; exit }')
if [[ -z $tohost_addr ]]; then
  printf 'RV64 retirement payload does not define tohost\n' >&2
  exit 2
fi

# Ask the executable itself for its compiled/runtime contract.  Looking at an
# externally supplied .config can produce a false PASS when NEMU_SIM points at
# a binary from another build directory or an older configuration.
machine_info=$work_dir/machine-info.txt
machine_info_log=$work_dir/machine-info.log
if ! timeout "$TIMEOUT_SECONDS" env \
    NEMU_INTERPRETER_BASIC_BLOCK=1 \
    NEMU_INTERPRETER_TB_MAX_INST=64 \
    "$NEMU_SIM" --machine-info="$machine_info" \
    "$work_dir/payload.bin" >"$machine_info_log" 2>&1; then
  cat "$machine_info_log" >&2
  printf 'Could not read the selected NEMU binary machine contract: %s\n' \
    "$NEMU_SIM" >&2
  exit 2
fi
if [[ ! -f $machine_info ]]; then
  cat "$machine_info_log" >&2
  printf 'Selected executable did not produce NEMU machine-info: %s\n' \
    "$NEMU_SIM" >&2
  exit 2
fi
for expected in \
    'config.engine=interpreter' \
    'config.interpreter_basic_block=1' \
    'runtime.interpreter_basic_block.enabled=1' \
    'runtime.interpreter_tb_max_inst=64'; do
  if ! grep -Fxq "$expected" "$machine_info"; then
    cat "$machine_info" >&2
    printf 'Selected NEMU binary lacks required TB contract: %s (%s)\n' \
      "$expected" "$NEMU_SIM" >&2
    exit 2
  fi
done
printf 'PASS binary-contract interpreter/basic-block/tb-max-inst=64\n'

run_case() {
  local name=$1
  local basic_block=$2
  local log=$work_dir/$name.log
  local status=0

  if timeout "$TIMEOUT_SECONDS" env \
      NEMU_HOME="$NEMU_HOME" \
      NEMU_INTERPRETER_BASIC_BLOCK="$basic_block" \
      NEMU_INTERPRETER_TB_MAX_INST=64 \
      "$NEMU_SIM" -b --tohost="$tohost_addr" \
      "$work_dir/payload.bin" >"$log" 2>&1; then
    status=0
  else
    status=$?
  fi

  if (( status != 0 )) || ! grep -Fq 'TOHOST PASS' "$log"; then
    cat "$log" >&2
    printf 'RV64 retirement/Sdtrig smoke failed: mode=%s rc=%d\n' \
      "$name" "$status" >&2
    exit 1
  fi
  if grep -Fq 'TOHOST FAIL' "$log"; then
    cat "$log" >&2
    printf 'RV64 retirement/Sdtrig smoke reported a bad trap: mode=%s\n' \
      "$name" >&2
    exit 1
  fi
  printf 'PASS mode=%s normal/write-wins/sync-trap/async-irq/xRET/WFI/ifetch/Sdtrig\n' \
    "$name"
}

run_case interpreter-tb 1
run_case interpreter-single-step 0
printf '__NEMU_RV64_RETIREMENT_SDTRIG_SMOKE__:ok\n'
