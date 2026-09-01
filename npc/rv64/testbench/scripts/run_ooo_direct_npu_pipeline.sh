#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE_DIR="$(cd "${NPC_RV64_DIR}/../.." && pwd)"
NPU_TMP_DIR="${WORKSPACE_DIR}/npu/version_0820/tmp/rv64-direct-npu-pipeline"
OBJ_DIR="${NPU_TMP_DIR}/obj"
COMPILER_TMP_DIR="${WORKSPACE_DIR}/npu/version_0820/tmp/compiler/rv64-direct-npu-pipeline"
LOG_FILE="${NPU_TMP_DIR}/run.log"

mkdir -p "${OBJ_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS
mapfile -t RTL_SRCS < <(rg --files "${NPC_RV64_DIR}/vsrc" -g '*.v')

{
  verilator --binary --timing -O3 --no-assert --no-trace \
    -CFLAGS "-O3 -DNDEBUG -march=native" \
    --top-module tb_ooo_alu_decode_backend \
    -Wno-fatal \
    -Wno-DECLFILENAME \
    -Wno-WIDTHEXPAND \
    -Wno-WIDTHTRUNC \
    -Wno-UNUSEDSIGNAL \
    -Wno-TIMESCALEMOD \
    -Wno-PINMISSING \
    -I"${NPC_RV64_DIR}/vsrc" \
    -I"${NPC_RV64_DIR}/vsrc/include" \
    -I"${NPC_RV64_DIR}/testbench/common" \
    --Mdir "${OBJ_DIR}" \
    "${NPC_RV64_DIR}/testbench/tests/tb_ooo_alu_decode_backend.sv" \
    "${RTL_SRCS[@]}"

  "${OBJ_DIR}/Vtb_ooo_alu_decode_backend"
} 2>&1 | tee "${LOG_FILE}"
