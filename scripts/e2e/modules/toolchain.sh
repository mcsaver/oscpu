#!/usr/bin/env bash

e2e_toolchain_expect_env() {
  local name=$1
  local expected=$2
  local actual=${!name-}
  if [[ $actual = "$expected" ]]; then
    printf 'PASS %-28s %s\n' "$name" "$actual"
    return 0
  fi
  printf 'FAIL %-28s expected=%s actual=%s\n' "$name" "$expected" "${actual:-<unset>}"
  return 1
}

e2e_toolchain_expect_tool_from_dir_if_present() {
  local label=$1
  local dir=$2
  local tool=$3
  local resolved resolved_real dir_real
  if [[ ! -d $dir ]]; then
    printf 'WARN %-28s %s not present\n' "$label" "$dir"
    return 0
  fi
  resolved=$(command -v "$tool" 2>/dev/null || true)
  case "$resolved" in
	    "$dir"/*)
	      printf 'PASS %-28s %s\n' "$label" "$resolved"
	      ;;
	    "")
	      printf 'FAIL %-28s %s not in PATH\n' "$label" "$tool"
	      return 1
	      ;;
	    *)
	      resolved_real=$(readlink -f "$resolved" 2>/dev/null || printf '%s\n' "$resolved")
	      dir_real=$(readlink -f "$dir" 2>/dev/null || printf '%s\n' "$dir")
	      case "$resolved_real" in
	        "$dir_real"/*)
	          printf 'PASS %-28s %s -> %s\n' "$label" "$resolved" "$resolved_real"
	          ;;
	        *)
	          printf 'FAIL %-28s expected under %s actual=%s\n' "$label" "$dir" "$resolved"
	          return 1
	          ;;
	      esac
	      ;;
	  esac
	}

e2e_toolchain_check() {
  local rc=0
  e2e_print_tools bash git make python3 gcc g++ timeout || rc=1
  echo
  e2e_print_optional_tools rg verilator riscv64-linux-gnu-gcc riscv64-unknown-elf-gcc java javac mill dtc qemu-system-riscv64 yosys
  echo
  echo "[toolchain] agent soft environment"
  if [[ ${YSYX_AGENT_ENV_SOURCED:-0} = 1 ]]; then
    printf 'PASS %-28s %s\n' "YSYX_AGENT_ENV_SOURCED" "${YSYX_AGENT_ENV_SOURCE:-<unknown>}"
  else
    printf 'FAIL %-28s <unset>\n' "YSYX_AGENT_ENV_SOURCED"
    rc=1
  fi
  e2e_toolchain_expect_env YSYX_HOME "$E2E_ROOT_DIR" || rc=1
  e2e_toolchain_expect_env AM_HOME "$E2E_ROOT_DIR/abstract-machine" || rc=1
  e2e_toolchain_expect_env NEMU_HOME "$E2E_ROOT_DIR/nemu" || rc=1
  e2e_toolchain_expect_env NPC_HOME "$E2E_ROOT_DIR/npc" || rc=1
  e2e_toolchain_expect_env NVBOARD_HOME "$E2E_ROOT_DIR/nvboard" || rc=1
  e2e_toolchain_expect_tool_from_dir_if_present "local mill/java wrappers" "${HOME:-}/.local/bin" mill || rc=1
  e2e_toolchain_expect_tool_from_dir_if_present "riscv baremetal toolchain" "${RISCV_TOOLCHAIN_HOME:-${HOME:-}/riscv-toolchain/riscv}/bin" riscv64-unknown-elf-gcc || rc=1
  e2e_toolchain_expect_tool_from_dir_if_present "oss-cad-suite yosys" "${HOME:-}/oss-cad-suite/bin" yosys || rc=1
  if [[ -n ${JAVA_HOME:-} ]]; then
    e2e_toolchain_expect_tool_from_dir_if_present "JAVA_HOME java" "$JAVA_HOME/bin" java || rc=1
  else
    printf 'WARN %-28s <unset>\n' "JAVA_HOME java"
  fi
  echo
  echo "[toolchain] key environment"
  printf 'ROOT_DIR=%s\n' "$E2E_ROOT_DIR"
  printf 'YSYX_HOME=%s\n' "${YSYX_HOME:-<unset>}"
  printf 'AM_HOME=%s\n' "${AM_HOME:-<unset>}"
  printf 'NEMU_HOME=%s\n' "${NEMU_HOME:-<unset>}"
  printf 'NPC_HOME=%s\n' "${NPC_HOME:-<unset>}"
  printf 'RISCV_TOOLCHAIN_HOME=%s\n' "${RISCV_TOOLCHAIN_HOME:-<unset>}"
  printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-<unset>}"
  return "$rc"
}
