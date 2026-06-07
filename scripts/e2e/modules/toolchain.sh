#!/usr/bin/env bash

e2e_toolchain_check() {
  e2e_print_tools bash git make python3 gcc g++ timeout
  echo
  e2e_print_optional_tools rg verilator riscv64-linux-gnu-gcc java mill dtc qemu-system-riscv64 yosys
  echo
  echo "[toolchain] key environment"
  printf 'ROOT_DIR=%s\n' "$E2E_ROOT_DIR"
  printf 'AM_HOME=%s\n' "${AM_HOME:-$E2E_ROOT_DIR/abstract-machine}"
  printf 'NEMU_HOME=%s\n' "${NEMU_HOME:-$E2E_ROOT_DIR/nemu}"
  printf 'NPC_HOME=%s\n' "${NPC_HOME:-$E2E_ROOT_DIR/npc}"
  printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-<unset>}"
}
