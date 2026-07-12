#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
source "$ROOT/scripts/agent-env.sh"

RV64="$ROOT/npc/rv64"
BUILD_DIR=${AXI_DPI_SIZED_BUILD_DIR:-"$RV64/testbench/build/axi-dpi-sized"}
mkdir -p "$BUILD_DIR/obj_axi" "$BUILD_DIR/obj_guard"

echo "[axi-dpi-sized] build real AxiDpiSlave with instrumented DPI callbacks"
verilator --cc --exe --build --top-module AxiDpiSlave \
  -Wall -Wno-UNUSEDSIGNAL \
  -I"$RV64/vsrc/include" \
  --Mdir "$BUILD_DIR/obj_axi" \
  -CFLAGS "-std=c++17 -Wall -Wextra -Werror" \
  "$RV64/vsrc/sim/AxiDpiSlave.sv" \
  "$RV64/testbench/cpp/axi_dpi_slave_sized_tb.cpp"

echo "[axi-dpi-sized] run AXI lane/low-window protocol test"
"$BUILD_DIR/obj_axi/VAxiDpiSlave"

echo "[axi-dpi-sized] build end-to-end AxiDpiSlave + real dpi.c/paddr.c guard test"
verilator --cc --exe --build --top-module AxiDpiSlave \
  -Wall -Wno-UNUSEDSIGNAL \
  -I"$RV64/vsrc/include" \
  --Mdir "$BUILD_DIR/obj_guard" \
  -CFLAGS "-std=c++17 -O2 -Wall -Wextra -Werror -ffunction-sections -fdata-sections -I$RV64/csrc/include -I$RV64/include/generated" \
  -LDFLAGS "-Wl,--gc-sections" \
  "$RV64/vsrc/sim/AxiDpiSlave.sv" \
  "$RV64/testbench/cpp/sized_dpi_guard_tb.cpp" \
  "$RV64/csrc/dpi.c"

echo "[axi-dpi-sized] run PMEM tail guard-page test"
"$BUILD_DIR/obj_guard/VAxiDpiSlave"

echo "AXI_DPI_SIZED_SUITE_PASS"
