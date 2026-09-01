#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "${SCRIPT_DIR}/..")"
cd "${ROOT_DIR}"

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BUILD_DIR="${ROOT_DIR}/tmp/build/q8-gemv-portal-adapter-${RUN_ID}"
LOG_DIR="${ROOT_DIR}/tmp/logs/q8-gemv-portal-adapter-${RUN_ID}"
OBJ_DIR="${BUILD_DIR}/obj_dir"
BUILD_LOG="${LOG_DIR}/build.log"
RUN_LOG="${LOG_DIR}/run.log"
RESULT_LOG="${LOG_DIR}/result.txt"
COMMAND_LOG="${LOG_DIR}/command.txt"
mkdir -p "${OBJ_DIR}" "${LOG_DIR}"

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
    rtl/TensorNpuQ8GemvPortalAdapter.v
    tests/tb_q8_gemv_portal_adapter.sv
)

VERILATOR_CMD=(
    verilator
    --binary
    --timing
    --sv
    -O3
    --no-assert
    -CFLAGS -O3
    -Wall
    -Wno-fatal
    -Wno-UNOPTFLAT
    -Wno-IMPORTSTAR
    -Wno-UNUSEDPARAM
    -Wno-UNUSEDSIGNAL
    -Wno-GENUNNAMED
    --top-module tb_q8_gemv_portal_adapter
    --Mdir "${OBJ_DIR}"
    "${SOURCES[@]}"
)

{
    printf 'cwd=%q\n' "${ROOT_DIR}"
    printf 'command='
    printf '%q ' "${VERILATOR_CMD[@]}"
    printf '\n'
    printf 'assertions=off\nwaveforms=off\noptimization=O3\n'
} >"${COMMAND_LOG}"

set +e
"${VERILATOR_CMD[@]}" >"${BUILD_LOG}" 2>&1
BUILD_EXIT=$?
set -e
WARNING_COUNT="$(grep -c '^%Warning' "${BUILD_LOG}" || true)"

if [[ "${BUILD_EXIT}" -ne 0 ]]; then
    cat "${BUILD_LOG}"
    {
        printf 'status=FAIL\nphase=build\nexit=%d\nwarnings=%s\n' \
            "${BUILD_EXIT}" "${WARNING_COUNT}"
        sha256sum \
            rtl/TensorNpuQ8GemvPortalAdapter.v \
            tests/tb_q8_gemv_portal_adapter.sv \
            scripts/run_q8_gemv_portal_adapter.sh \
            rtl/TensorNpuQ8RowSimdCore.v
    } >"${RESULT_LOG}"
    printf '[Q8-GEMV-PORTAL-ADAPTER][FAIL] phase=build exit=%d warnings=%s log=%s\n' \
        "${BUILD_EXIT}" "${WARNING_COUNT}" "${BUILD_LOG}"
    exit "${BUILD_EXIT}"
fi

set +e
timeout 120s "${OBJ_DIR}/Vtb_q8_gemv_portal_adapter" \
    >"${RUN_LOG}" 2>&1
RUN_EXIT=$?
set -e
cat "${RUN_LOG}"

PASS_COUNT="$(grep -Fc \
    '[NPU-Q8-GEMV-PORTAL][PASS] scenarios=7 row_lanes=4 mac_lanes=32' \
    "${RUN_LOG}" || true)"
FAIL_COUNT="$(grep -Ec '\[(NPU-Q8-GEMV-PORTAL|Q8-GEMV-PORTAL-ADAPTER)\]\[FAIL\]|%Error|%Fatal' \
    "${RUN_LOG}" || true)"

{
    printf 'schema=q8-gemv-portal-adapter-result-v1\n'
    printf 'build_exit=%d\nrun_exit=%d\n' "${BUILD_EXIT}" "${RUN_EXIT}"
    printf 'pass_markers=%s\nfailure_markers=%s\nwarnings=%s\n' \
        "${PASS_COUNT}" "${FAIL_COUNT}" "${WARNING_COUNT}"
    printf 'verilator_flags=--binary --timing --sv -O3 --no-assert -CFLAGS -O3 --no-trace\n'
    printf 'row_lanes=4\nmac_lanes=32\nscenarios=7\n'
    sha256sum \
        rtl/TensorNpuQ8GemvPortalAdapter.v \
        tests/tb_q8_gemv_portal_adapter.sv \
        scripts/run_q8_gemv_portal_adapter.sh \
        rtl/TensorNpuQ8RowSimdCore.v
} >"${RESULT_LOG}"

if [[ "${RUN_EXIT}" -ne 0 || "${PASS_COUNT}" -ne 1 \
      || "${FAIL_COUNT}" -ne 0 ]]; then
    printf '[Q8-GEMV-PORTAL-ADAPTER][FAIL] phase=run exit=%d pass=%s failures=%s warnings=%s log=%s\n' \
        "${RUN_EXIT}" "${PASS_COUNT}" "${FAIL_COUNT}" \
        "${WARNING_COUNT}" "${RUN_LOG}"
    exit 1
fi

printf '[Q8-GEMV-PORTAL-ADAPTER][PASS] build_exit=0 run_exit=0 pass=1 failures=0 warnings=%s assertions=off waveforms=off optimization=O3 build=%s log=%s result=%s\n' \
    "${WARNING_COUNT}" "${BUILD_DIR}" "${LOG_DIR}" "${RESULT_LOG}"
