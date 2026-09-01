#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_ID="fp32-sincos-cordic-$(date -u +%Y%m%dT%H%M%S)-$$"
RUN_DIR="${ROOT}/tmp/${RUN_ID}"
OBJ_DIR="${RUN_DIR}/obj"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
LOG_FILE="${RUN_DIR}/run.log"

mkdir -p "${OBJ_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

verilator --cc --exe --build -j 0 -O3 --no-assert --no-trace \
  -Wall --Wno-fatal \
  -CFLAGS "-O3 -DNDEBUG -march=native" \
  -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
  --top-module TensorNpuFp32SincosCordic \
  --Mdir "${OBJ_DIR}" \
  "${ROOT}/rtl/TensorNpuInt32ToFp32.v" \
  "${ROOT}/rtl/TensorNpuFp32SincosCordic.v" \
  "${ROOT}/tests/tb_fp32_sincos_cordic.cpp" \
  >"${RUN_DIR}/build.log" 2>&1

"${OBJ_DIR}/VTensorNpuFp32SincosCordic" 2>&1 | tee "${LOG_FILE}"
printf 'run_dir=%s\ncompiler_tmp_dir=%s\nlog=%s\n' \
  "${RUN_DIR}" "${COMPILER_TMP_DIR}" "${LOG_FILE}"
