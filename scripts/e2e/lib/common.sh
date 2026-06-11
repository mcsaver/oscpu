#!/usr/bin/env bash

# e2e 公共层只放跨 profile/模块复用的能力；具体模块 gate 放在 scripts/e2e/modules/。

if [[ -z ${E2E_ROOT_DIR:-} ]]; then
  E2E_ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
fi

e2e_now() {
  date '+%Y-%m-%d %H:%M:%S %z'
}

e2e_relpath() {
  realpath --relative-to "$E2E_ROOT_DIR" "$1" 2>/dev/null || printf '%s\n' "$1"
}

e2e_abspath_from_root() {
  local path=$1
  if [[ $path = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s/%s\n' "$E2E_ROOT_DIR" "$path"
  fi
}

e2e_has_tool() {
  command -v "$1" >/dev/null 2>&1
}

e2e_print_required_files() {
  local missing=0 file
  for file in "$@"; do
    if [[ -f "$E2E_ROOT_DIR/$file" ]]; then
      printf 'PASS %s\n' "$file"
    else
      printf 'FAIL %s\n' "$file"
      missing=1
    fi
  done
  return "$missing"
}

e2e_file_text() {
  local file=$1
  local abs="$E2E_ROOT_DIR/$file"
  if [[ ! -f $abs ]]; then
    return 1
  fi
  if grep -Fq -- "DB-backed $file" "$abs" 2>/dev/null; then
    python3 "$E2E_ROOT_DIR/scripts/github_index_db.py" load \
      --repo-root "$E2E_ROOT_DIR" \
      --source stored \
      --path "$file" \
      --limit 10000 \
      --max-tokens 10000000 \
      --json |
      python3 -c 'import json, sys; print("\n".join(item.get("text", "") for item in json.load(sys.stdin)))'
  else
    cat "$abs"
  fi
}

e2e_file_contains() {
  local file=$1 pattern=$2
  e2e_file_text "$file" | grep -Fq -- "$pattern"
}

e2e_print_required_paths() {
  local missing=0 path
  for path in "$@"; do
    if [[ -e "$E2E_ROOT_DIR/$path" ]]; then
      printf 'PASS %s\n' "$path"
    else
      printf 'FAIL %s\n' "$path"
      missing=1
    fi
  done
  return "$missing"
}

e2e_print_tools() {
  local missing=0 tool
  echo "[e2e] required tools"
  for tool in "$@"; do
    if e2e_has_tool "$tool"; then
      printf 'PASS %-28s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf 'FAIL %-28s <missing>\n' "$tool"
      missing=1
    fi
  done
  return "$missing"
}

e2e_print_optional_tools() {
  local tool
  echo "[e2e] optional tools"
  for tool in "$@"; do
    if e2e_has_tool "$tool"; then
      printf 'PASS %-28s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf 'WARN %-28s <missing>\n' "$tool"
    fi
  done
}

e2e_nemu_config_summary() {
  local config="$E2E_ROOT_DIR/nemu/.config"
  if [[ ! -f $config ]]; then
    printf 'nemu/.config=<missing>'
    return 0
  fi
  local isa target
  isa=$(sed -n 's/^CONFIG_ISA="\([^"]*\)"/\1/p' "$config")
  if grep -q '^CONFIG_TARGET_AM=y' "$config"; then
    target=AM
  elif grep -q '^CONFIG_TARGET_NATIVE_ELF=y' "$config"; then
    target=NATIVE_ELF
  elif grep -q '^CONFIG_TARGET_SHARE=y' "$config"; then
    target=SHARE
  else
    target=UNKNOWN
  fi
  printf 'nemu/.config isa=%s target=%s' "${isa:-unknown}" "$target"
}

e2e_nemu_am_compatible() {
  if [[ ${AGENT_E2E_FORCE_SMOKE:-0} = 1 ]]; then
    return 0
  fi
  grep -q '^CONFIG_TARGET_AM=y' "$E2E_ROOT_DIR/nemu/.config" 2>/dev/null
}

e2e_default_nemu_arch() {
  if [[ -n ${AGENT_E2E_NEMU_ARCH:-} ]]; then
    printf '%s\n' "$AGENT_E2E_NEMU_ARCH"
    return 0
  fi
  local isa
  isa=$(sed -n 's/^CONFIG_ISA="\([^"]*\)"/\1/p' "$E2E_ROOT_DIR/nemu/.config" 2>/dev/null)
  case "$isa" in
    riscv64) printf 'riscv64-nemu\n' ;;
    riscv32) printf 'riscv32-nemu\n' ;;
    *) printf 'riscv32-nemu\n' ;;
  esac
}

e2e_validate_cpu_test_log() {
  local log_file=$1
  if grep -Eq '\*\*\*FAIL\*\*\*|HIT BAD TRAP|Assertion .*failed|address .*out of bound' "$log_file"; then
    return 1
  fi
  grep -Eq 'PASS' "$log_file"
}
