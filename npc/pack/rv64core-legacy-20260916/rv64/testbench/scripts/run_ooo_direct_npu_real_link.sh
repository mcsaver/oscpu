#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPC_RV64_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WORKSPACE_DIR="$(cd "${NPC_RV64_DIR}/../.." && pwd)"
NPU_ROOT="${WORKSPACE_DIR}/npu/version_0820"
NPU_TMP_DIR="${NPU_ROOT}/tmp/rv64-direct-npu-real-link"
OBJ_DIR="${NPU_TMP_DIR}/obj"
COMPILER_TMP_DIR="${NPU_ROOT}/tmp/compiler/rv64-direct-npu-real-link"
LOG_FILE="${NPU_TMP_DIR}/run.log"

mkdir -p "${OBJ_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS
mapfile -t NPC_RTL_SRCS < <(rg --files "${NPC_RV64_DIR}/vsrc" -g '*.v')
mapfile -t NPU_RTL_SRCS < <(rg --files "${NPU_ROOT}/rtl" -g '*.v' -g '*.sv')
mapfile -t LZC_SRCS < <(
  rg --files "${NPU_ROOT}/third_party/fpu-sp/verilog/src/lzc" -g '*.sv' |
    rg -v 'lzc_wire.sv$'
)
mapfile -t FP_SRCS < <(
  rg --files "${NPU_ROOT}/third_party/fpu-sp/verilog/src/float" -g '*.sv' |
    rg -v 'fp_wire.sv$'
)
HARD_FLOAT_SRCS=(
  "${NPU_ROOT}/third_party/hardfloat/source/RISCV/HardFloat_specialize.v"
  "${NPU_ROOT}/third_party/hardfloat/source/HardFloat_primitives.v"
  "${NPU_ROOT}/third_party/hardfloat/source/HardFloat_rawFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/isSigNaNRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/fNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/recFNToIN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/iNToRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/mulAddRecFN.v"
  "${NPU_ROOT}/third_party/hardfloat/source/addRecFN.v"
)

{
  verilator --binary --timing -O3 --no-assert --no-trace \
    -CFLAGS "-O3 -DNDEBUG -march=native" \
    +define+RV64_REAL_NPU_LINK \
    --top-module tb_ooo_alu_decode_backend \
    -Wno-fatal \
    -Wno-DECLFILENAME \
    -Wno-WIDTHEXPAND \
    -Wno-WIDTHTRUNC \
    -Wno-UNUSEDSIGNAL \
    -Wno-TIMESCALEMOD \
    -Wno-PINMISSING \
    -Wno-UNOPTFLAT \
    -I"${NPC_RV64_DIR}/vsrc" \
    -I"${NPC_RV64_DIR}/vsrc/include" \
    -I"${NPC_RV64_DIR}/testbench/common" \
    -I"${NPU_ROOT}/rtl" \
    -I"${NPU_ROOT}/third_party/hardfloat/source/RISCV" \
    -I"${NPU_ROOT}/third_party/hardfloat/source" \
    --Mdir "${OBJ_DIR}" \
    "${NPU_ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv" \
    "${NPU_ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv" \
    "${LZC_SRCS[@]}" \
    "${FP_SRCS[@]}" \
    "${HARD_FLOAT_SRCS[@]}" \
    "${NPC_RV64_DIR}/testbench/tests/tb_ooo_alu_decode_backend.sv" \
    "${NPC_RTL_SRCS[@]}" \
    "${NPU_RTL_SRCS[@]}"

  "${OBJ_DIR}/Vtb_ooo_alu_decode_backend"
} 2>&1 | tee "${LOG_FILE}"
