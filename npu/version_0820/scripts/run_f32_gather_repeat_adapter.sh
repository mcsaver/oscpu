#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_ID="f32-gather-repeat-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"

mkdir -p "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

verilator \
    --binary \
    --timing \
    -Wall \
    -Wno-fatal \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG -march=native" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_f32_gather_repeat_adapter \
    "${ROOT}/rtl/TensorNpuF32GatherRepeatAdapter.v" \
    "${ROOT}/tests/tb_f32_gather_repeat_adapter.sv" \
    >"${LOG_DIR}/build.log" 2>&1

set -o pipefail
"${OBJ_DIR}/Vtb_f32_gather_repeat_adapter" \
    | tee "${LOG_DIR}/run.log"

grep -Fq \
    '[NPU-F32-GATHER-REPEAT][PASS]' \
    "${LOG_DIR}/run.log"

printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
