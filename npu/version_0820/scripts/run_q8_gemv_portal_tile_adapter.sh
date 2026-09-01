#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_ID="q8-gemv-portal-tile-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
mkdir -p "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS
cd "${ROOT}"

SOURCES=(
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
    third_party/fpu-sp/verilog/src/float/fp_ext.sv
    third_party/fpu-sp/verilog/src/float/fp_fma.sv
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    third_party/fpu-sp/verilog/src/float/fp_cvt.sv
    rtl/TensorNpuFp16ToFp32.v
    rtl/TensorNpuInt32ToFp32.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Div.v
    rtl/TensorNpuFp32ToFp16.v
    rtl/TensorNpuFp32ToInt32Rmm.v
    rtl/TensorNpuQ8DotEngine.v
    rtl/TensorNpuQ8ScaleAccumulator.v
    rtl/TensorNpuQ8ReferenceQuantizer.v
    rtl/TensorNpuQ8RowSimdCore.v
    rtl/TensorNpuQ8RowTileFunctionalCore.sv
    rtl/TensorNpuQ8GemvPortalAdapter.v
    tests/tb_q8_gemv_portal_adapter.sv
    "${ROOT}/runtime/llama-npu-backend/npu-q8-row-tile-dpi.cpp"
)

printf '%s\n' "${SOURCES[@]}" >"${LOG_DIR}/sources.f"
printf '%s\n' \
    'verilator --binary --timing --sv -O3 --no-assert --no-trace' \
    '-GTILE_FUNCTIONAL_ENABLE=1' \
    'CXX=-O3 -fno-fast-math -ffp-contract=off -frounding-math' \
    >"${LOG_DIR}/command.txt"

verilator \
    --binary --timing --sv -O3 --no-assert --no-trace \
    --build-jobs 2 \
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
    -CFLAGS "-O3 -DNDEBUG -std=c++17 -fno-fast-math -ffp-contract=off -frounding-math" \
    -LDFLAGS "-lm" \
    -Wall -Wno-fatal -Wno-UNOPTFLAT -Wno-IMPORTSTAR \
    -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-GENUNNAMED \
    -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-WIDTH \
    -Wno-WIDTHCONCAT -Wno-VARHIDDEN -Wno-BLKSEQ \
    -GTILE_FUNCTIONAL_ENABLE=1 \
    --top-module tb_q8_gemv_portal_adapter \
    --Mdir "${OBJ_DIR}" \
    "${SOURCES[@]}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
        "${LOG_DIR}/build.log"; then
    printf 'unexpected build diagnostic; see %s\n' "${LOG_DIR}/build.log" >&2
    exit 1
fi

/usr/bin/time \
    -f 'wall_seconds=%e user_seconds=%U sys_seconds=%S max_rss_kb=%M' \
    -o "${LOG_DIR}/run-time.log" \
    timeout 120s "${OBJ_DIR}/Vtb_q8_gemv_portal_adapter" \
    | tee "${LOG_DIR}/run.log"

grep -Fq '[NPU-Q8-GEMV-PORTAL][POSITIVE] rows=5 blocks=2' \
    "${LOG_DIR}/run.log"
grep -Fq '[NPU-Q8-GEMV-PORTAL][PASS] scenarios=7 row_lanes=4 mac_lanes=32' \
    "${LOG_DIR}/run.log"
if grep -Eq '\[FAIL\]|%Error|%Fatal' "${LOG_DIR}/run.log"; then
    exit 1
fi

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) -print \
    >"${LOG_DIR}/waveform-find.log"
test ! -s "${LOG_DIR}/waveform-find.log"

sha256sum \
    rtl/TensorNpuQ8GemvPortalAdapter.v \
    rtl/TensorNpuQ8RowTileFunctionalCore.sv \
    runtime/llama-npu-backend/npu-q8-row-tile-dpi.cpp \
    tests/tb_q8_gemv_portal_adapter.sv \
    scripts/run_q8_gemv_portal_tile_adapter.sh \
    >"${LOG_DIR}/sha256.log"

printf '[Q8-GEMV-PORTAL-TILE][PASS] O3=1 assertions=off trace=off fast_math=off fma=off warnings=0 errors=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
