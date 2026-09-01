#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_ID="q8-row-tile-functional-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
CORE="${ROOT}/rtl/TensorNpuQ8RowTileFunctionalCore.sv"
DPI="${ROOT}/runtime/llama-npu-backend/npu-q8-row-tile-dpi.cpp"
TB="${ROOT}/tests/tb_q8_row_tile_functional_core.sv"
RUNNER="${ROOT}/scripts/run_q8_row_tile_functional_core.sh"

mkdir -p "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

SOURCES=(
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_wire.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_ext.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_fma.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_fdiv.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_cvt.sv"
    "${ROOT}/rtl/TensorNpuFp16ToFp32.v"
    "${ROOT}/rtl/TensorNpuInt32ToFp32.v"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${ROOT}/rtl/TensorNpuFp32Div.v"
    "${ROOT}/rtl/TensorNpuFp32ToFp16.v"
    "${ROOT}/rtl/TensorNpuFp32ToInt32Rmm.v"
    "${ROOT}/rtl/TensorNpuQ8DotEngine.v"
    "${ROOT}/rtl/TensorNpuQ8ScaleAccumulator.v"
    "${ROOT}/rtl/TensorNpuQ8ReferenceQuantizer.v"
    "${ROOT}/rtl/TensorNpuQ8RowSimdCore.v"
    "${CORE}"
    "${TB}"
    "${DPI}"
)

printf '%s\n' "${SOURCES[@]}" >"${LOG_DIR}/sources.f"

if rg -n --pcre2 \
    '\$(dumpfile|dumpvars|dumpon|dumpoff|dumpall|dumpflush)|traceEverOn|\.(vcd|fst|lxt|lxt2)([^[:alnum:]_]|$)' \
    "${CORE}" "${TB}" "${DPI}" >"${LOG_DIR}/waveform-static-audit.log"; then
    printf '[FAIL] waveform construct found\n' \
        >>"${LOG_DIR}/waveform-static-audit.log"
    exit 1
fi
printf '[PASS] no waveform construct; --no-trace build\n' \
    >>"${LOG_DIR}/waveform-static-audit.log"

if rg -n --pcre2 'std::fma|(^|[^[:alnum:]_])fmaf?[[:space:]]*\(|__builtin_fma' \
        "${DPI}" >"${LOG_DIR}/fma-static-audit.log"; then
    printf '[FAIL] DPI contains an FMA entry point\n' \
        >>"${LOG_DIR}/fma-static-audit.log"
    exit 1
fi
printf '[PASS] separate RN32 multiply/multiply/add; no FMA entry point\n' \
    >>"${LOG_DIR}/fma-static-audit.log"

if [[ "$(grep -Ec '^[[:space:]]*TensorNpuQ8ReferenceQuantizer[[:space:]]+u_activation_quantizer' "${CORE}")" != 1 \
      || "$(grep -Ec 'import[[:space:]]+"DPI-C"[[:space:]]+function[[:space:]]+int[[:space:]]+npu_q8_row_tile_compute' "${CORE}")" != 1 ]]; then
    printf '[FAIL] core topology must be one reference quantizer plus one DPI tile unit\n' \
        >"${LOG_DIR}/topology-audit.log"
    exit 1
fi
printf '[PASS] one shared reference quantizer; one packed-raw DPI tile unit\n' \
    >"${LOG_DIR}/topology-audit.log"

verilator \
    --binary \
    --build-jobs 2 \
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
    --timing \
    --sv \
    -Wall \
    -Wno-fatal \
    -Wno-UNOPTFLAT \
    -Wno-IMPORTSTAR \
    -Wno-UNUSEDPARAM \
    -Wno-UNUSEDSIGNAL \
    -Wno-GENUNNAMED \
    -Wno-DECLFILENAME \
    -Wno-TIMESCALEMOD \
    -Wno-WIDTH \
    -Wno-WIDTHCONCAT \
    -Wno-VARHIDDEN \
    -Wno-BLKSEQ \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG -std=c++17 -fno-fast-math -ffp-contract=off -frounding-math" \
    -LDFLAGS "-lm" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_q8_row_tile_functional_core \
    "${SOURCES[@]}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
        "${LOG_DIR}/build.log"; then
    printf 'unexpected compiler diagnostic; see %s\n' "${LOG_DIR}/build.log" >&2
    exit 1
fi

set -o pipefail
/usr/bin/time -f 'wall_seconds=%e user_seconds=%U sys_seconds=%S max_rss_kb=%M' \
    -o "${LOG_DIR}/run-time.log" \
    "${OBJ_DIR}/Vtb_q8_row_tile_functional_core" \
    | tee "${LOG_DIR}/run.log"

grep -Fq '[NPU-Q8-ROW-TILE][PASS]' "${LOG_DIR}/run.log"
grep -Fq 'B=1,2,32,112 tails=1,4,5' "${LOG_DIR}/run.log"
grep -Fq 'wrong_mask=1 nonfinite_scale=1 backpressure=1' \
    "${LOG_DIR}/run.log"

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) -print \
    >"${LOG_DIR}/waveform-find.log"
if [[ -s "${LOG_DIR}/waveform-find.log" ]]; then
    printf 'waveform artifact found in fresh-run paths\n' >&2
    exit 1
fi

sha256sum "${CORE}" "${DPI}" "${TB}" "${RUNNER}" \
    >"${LOG_DIR}/sha256.log"

printf '[NPU-Q8-ROW-TILE-RUNNER][PASS] build=O3 assertions=off trace=off fast_math=off fma=off warnings=0 errors=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\nsha256=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" \
    "${LOG_DIR}/sha256.log"
