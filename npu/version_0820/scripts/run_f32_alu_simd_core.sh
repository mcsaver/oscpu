#!/usr/bin/env bash
set -euo pipefail

ROOT=/home/lyg/PA/ysyx-workbench/npu/version_0820
RUN_ID="f32-alu-simd-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="${ROOT}/tmp/build/${RUN_ID}"
LOG_DIR="${ROOT}/tmp/logs/${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
COMPILER_TMP_DIR="${ROOT}/tmp/compiler/${RUN_ID}"
CORE="${ROOT}/rtl/TensorNpuF32AluSimdCore.v"
TB="${ROOT}/tests/tb_f32_alu_simd_core.sv"
RUNNER="${ROOT}/scripts/run_f32_alu_simd_core.sh"

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
    "${ROOT}/third_party/fpu-sp/verilog/src/float/fp_rnd.sv"
    "${ROOT}/rtl/TensorNpuFp32AddMul.v"
    "${CORE}"
    "${TB}"
)

printf '%s\n' "${SOURCES[@]}" >"${LOG_DIR}/sources.f"

# The directed TB must observe only public ready/valid ports and use the
# independent RTL child as its raw-bit oracle.
if rg -n --pcre2 \
    '(^|[^[:alnum:]_])(force|release|shortreal|real)([^[:alnum:]_]|$)|DPI-C|DPI|\$bitstoshortreal|\$shortrealtobits|\$itor|\$rtoi|\$(sqrt|ln|log10|exp|pow)|[[:space:]]dut_lane[18][[:space:]]*\.' \
    "${TB}" >"${LOG_DIR}/host-hierarchy-audit.log"; then
    printf '[FAIL] forbidden host arithmetic or hierarchy construct\n' \
        >>"${LOG_DIR}/host-hierarchy-audit.log"
    exit 1
fi
printf '[PASS] raw-bit public-port RTL oracle only\n' \
    >>"${LOG_DIR}/host-hierarchy-audit.log"

if rg -n --pcre2 \
    '\$(dumpfile|dumpvars|dumpon|dumpoff|dumpall|dumpflush)|traceEverOn|\.(vcd|fst|lxt|lxt2)([^[:alnum:]_]|$)' \
    "${CORE}" "${TB}" >"${LOG_DIR}/waveform-static-audit.log"; then
    printf '[FAIL] waveform construct found\n' \
        >>"${LOG_DIR}/waveform-static-audit.log"
    exit 1
fi
printf '[PASS] no waveform construct; --no-trace build\n' \
    >>"${LOG_DIR}/waveform-static-audit.log"

if [[ "$(grep -Ec '^[[:space:]]*TensorNpuFp32AddMul[[:space:]]+u_addmul' "${CORE}")" != 1 \
      || "$(grep -Ec '^[[:space:]]*TensorNpuFp32AddMul[[:space:]]+u_oracle_addmul' "${TB}")" != 1 ]]; then
    printf '[FAIL] expected one generated child declaration and one independent oracle declaration\n' \
        >"${LOG_DIR}/topology-audit.log"
    exit 1
fi
printf '[PASS] LANES generated children; one independent public RTL oracle\n' \
    >"${LOG_DIR}/topology-audit.log"

verilator \
    --binary \
    --build-jobs 2 \
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
    -Wno-VARHIDDEN \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_f32_alu_simd_core \
    "${SOURCES[@]}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
        "${LOG_DIR}/build.log"; then
    printf 'unexpected compiler diagnostic; see %s\n' "${LOG_DIR}/build.log" >&2
    exit 1
fi
printf 'diagnostic_count=0\n' >"${LOG_DIR}/diagnostic-count.log"

set -o pipefail
"${OBJ_DIR}/Vtb_f32_alu_simd_core" | tee "${LOG_DIR}/run.log"

grep -Fq '[NPU-F32-ALU-SIMD][PASS]' "${LOG_DIR}/run.log"

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) -print \
    >"${LOG_DIR}/waveform-find.log"
if [[ -s "${LOG_DIR}/waveform-find.log" ]]; then
    printf 'waveform artifact found in fresh-run paths\n' >&2
    exit 1
fi

sha256sum "${CORE}" "${TB}" "${RUNNER}" >"${LOG_DIR}/sha256.log"

printf '[NPU-F32-ALU-SIMD-RUNNER][PASS] build=O3 assertions=off trace=off diagnostic_count=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\nsha256=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" \
    "${LOG_DIR}/sha256.log"
