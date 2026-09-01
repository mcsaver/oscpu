#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(realpath -- "${SCRIPT_DIR}/..")"
cd -- "${PROJECT_ROOT}"

project_tmp_path() {
    local resolved
    resolved="$(realpath -m -- "$1")"
    case "${resolved}" in
        "${PROJECT_ROOT}/tmp"|"${PROJECT_ROOT}/tmp/"*)
            printf '%s\n' "${resolved}"
            ;;
        *)
            printf '[COPROCESSOR-F32-ALU-PORTAL][FAIL] generated path escapes project tmp/: %s\n' \
                "${resolved}" >&2
            exit 1
            ;;
    esac
}

readonly RUN_ID="coprocessor-f32-alu-portal-$(date -u +%Y%m%dT%H%M%SZ)-${BASHPID}"
readonly BUILD_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/build/${RUN_ID}")"
readonly LOG_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/logs/${RUN_ID}")"
readonly COMPILER_TMP_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/compiler/${RUN_ID}")"
readonly OBJ_DIR="$(project_tmp_path "${BUILD_DIR}/obj_dir")"
readonly BUILD_LOG="$(project_tmp_path "${LOG_DIR}/build.log")"
readonly RUN_LOG="$(project_tmp_path "${LOG_DIR}/run.log")"
readonly COMMAND_LOG="$(project_tmp_path "${LOG_DIR}/command.txt")"
readonly RESULT_LOG="$(project_tmp_path "${LOG_DIR}/result.txt")"
mkdir -p -- "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
unset MAKEFLAGS MFLAGS

readonly -a SOURCES=(
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
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v
    third_party/hardfloat/source/HardFloat_primitives.v
    third_party/hardfloat/source/HardFloat_rawFN.v
    third_party/hardfloat/source/isSigNaNRecFN.v
    third_party/hardfloat/source/fNToRecFN.v
    third_party/hardfloat/source/recFNToFN.v
    third_party/hardfloat/source/recFNToRecFN.v
    third_party/hardfloat/source/recFNToIN.v
    third_party/hardfloat/source/iNToRecFN.v
    third_party/hardfloat/source/mulAddRecFN.v
    third_party/hardfloat/source/addRecFN.v
    rtl/TensorNpuFp16ToFp32.v
    rtl/TensorNpuInt32ToFp32.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Div.v
    rtl/TensorNpuFp32ToFp16.v
    rtl/TensorNpuFp32ToInt32Rmm.v
    rtl/TensorNpuQ8DequantBlock.v
    rtl/TensorNpuQ8GetRowsEngine.v
    rtl/TensorNpuQ8GetRowsWritebackAdapter.v
    rtl/TensorNpuQ8DotEngine.v
    rtl/TensorNpuQ8ScaleAccumulator.v
    rtl/TensorNpuQ8ReferenceQuantizer.v
    rtl/TensorNpuQ8StreamGemv.v
    rtl/TensorNpuQ8GemvWritebackAdapter.v
    rtl/TensorNpuQ8RowSimdCore.v
    rtl/TensorNpuQ8GemvPortalAdapter.v
    rtl/TensorNpuF32GatherRepeatAdapter.v
    rtl/TensorNpuF32GatherRepeatPortalAdapter.v
    rtl/TensorNpuF32TensorAlu.v
    rtl/TensorNpuVectorF32Adapter.v
    rtl/TensorNpuF32AluSimdCore.v
    rtl/TensorNpuF32AluPortalAdapter.v
    rtl/TensorNpuFp32ToFp64.v
    rtl/TensorNpuFp64Fma.v
    rtl/TensorNpuFp64ToInt32Rmm.v
    rtl/TensorNpuInt32ToFp64.v
    rtl/TensorNpuFp64ToFp32Finite.v
    rtl/TensorNpuAorExp32.v
    rtl/TensorNpuAorLog32.v
    rtl/TensorNpuUnaryGluElement.v
    rtl/TensorNpuUnaryGluWritebackAdapter.v
    rtl/TensorNpuFp32Sqrt.v
    rtl/TensorNpuFp64Add.v
    rtl/TensorNpuFp64ToFp32.v
    rtl/TensorNpuFp32SquareSum64.v
    rtl/TensorNpuFp64Pow2Scale.v
    rtl/TensorNpuNormEngine.v
    rtl/TensorNpuNormWritebackAdapter.v
    rtl/TensorNpuFp32ToFp64Ieee.v
    rtl/TensorNpuFp64AddIeee.v
    rtl/TensorNpuFp64ToFp32Ieee.v
    rtl/TensorNpuOrderedSumRows.v
    rtl/TensorNpuSumRowsWritebackAdapter.v
    rtl/TensorNpuSsmConvWritebackAdapter.v
    rtl/TensorNpuTensorMover.v
    rtl/TensorNpuSetRowsEngine.v
    rtl/TensorNpuMoverSetRowsWritebackAdapter.v
    rtl/TensorNpuFp32Fma.v
    rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v
    rtl/TensorNpuSoftmaxWritebackAdapter.v
    rtl/TensorNpuFp32SincosCordic.v
    rtl/TensorNpuRopeWritebackAdapter.v
    rtl/TensorNpuCoprocessor.v
    rtl/TensorNpuCommandDecoder.v
    rtl/TensorNpuRegisterFile.v
    rtl/TensorNpuMm2Engine.v
    rtl/TensorNpuDmaEngine.v
    rtl/TensorNpuLocalMemory.v
    tests/tb_coprocessor_f32_alu_portal.sv
)

readonly -a VERILATOR_CMD=(
    verilator
    --binary
    --timing
    --sv
    -O3
    --no-assert
    --no-trace
    -CFLAGS "-O3 -DNDEBUG -march=native"
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3"
    -Wall
    -Wno-fatal
    -Wno-UNOPTFLAT
    -Wno-IMPORTSTAR
    -Wno-UNUSEDPARAM
    -Wno-UNUSEDSIGNAL
    -Wno-GENUNNAMED
    -Wno-PINCONNECTEMPTY
    -Wno-DECLFILENAME
    -Wno-TIMESCALEMOD
    -Wno-VARHIDDEN
    -Wno-WIDTHTRUNC
    -Wno-WIDTHEXPAND
    -Irtl
    -Ithird_party/hardfloat/source/RISCV
    -Ithird_party/hardfloat/source
    --top-module tb_coprocessor_f32_alu_portal
    --Mdir "${OBJ_DIR}"
    -o Vtb_coprocessor_f32_alu_portal
    "${SOURCES[@]}"
)

{
    printf 'cwd=%q\n' "${PROJECT_ROOT}"
    printf 'command='
    printf '%q ' "${VERILATOR_CMD[@]}"
    printf '\nassertions=off\nwaveforms=off\noptimization=O3\n'
    printf 'portal_enable=1\nlanes=8\npublic_gmem_byte_contract=zero\n'
    printf 'numeric_oracle=independent-public-TensorNpuFp32AddMul\n'
} >"${COMMAND_LOG}"

set +e
"${VERILATOR_CMD[@]}" >"${BUILD_LOG}" 2>&1
BUILD_EXIT=$?
set -e
WARNING_COUNT="$(grep -c '^%Warning' "${BUILD_LOG}" || true)"

if [[ "${BUILD_EXIT}" -ne 0 ]]; then
    cat -- "${BUILD_LOG}"
    {
        printf 'schema=coprocessor-f32-alu-portal-result-v1\n'
        printf 'status=FAIL\nphase=build\nbuild_exit=%d\nwarnings=%s\n' \
            "${BUILD_EXIT}" "${WARNING_COUNT}"
        sha256sum \
            rtl/TensorNpuCoprocessor.v \
            sim/NpcTensorNpuSystemTop.sv \
            rtl/TensorNpuF32AluPortalAdapter.v \
            rtl/TensorNpuF32AluSimdCore.v \
            tests/tb_coprocessor_f32_alu_portal.sv \
            scripts/run_coprocessor_f32_alu_portal.sh
    } >"${RESULT_LOG}"
    printf '[COPROCESSOR-F32-ALU-PORTAL][FAIL] phase=build exit=%d warnings=%s log=%s\n' \
        "${BUILD_EXIT}" "${WARNING_COUNT}" "${BUILD_LOG}"
    exit "${BUILD_EXIT}"
fi

set +e
timeout 240s "${OBJ_DIR}/Vtb_coprocessor_f32_alu_portal" \
    >"${RUN_LOG}" 2>&1
RUN_EXIT=$?
set -e
cat -- "${RUN_LOG}"

PASS_COUNT="$(grep -Fc \
    '[NPU-COPROCESSOR-F32-ALU-PORTAL][PASS] portal=1 lanes=8 profiles=P00,P16,P17-empty,P18-empty scenarios=17 warnings=0 assertions=off waveform=off' \
    "${RUN_LOG}" || true)"
FAIL_COUNT="$(grep -Ec \
    '\[(NPU-COPROCESSOR-F32-ALU-PORTAL|COPROCESSOR-F32-ALU-PORTAL)\]\[FAIL\]|%Error|%Fatal' \
    "${RUN_LOG}" || true)"

{
    printf 'schema=coprocessor-f32-alu-portal-result-v1\n'
    printf 'build_exit=%d\nrun_exit=%d\n' "${BUILD_EXIT}" "${RUN_EXIT}"
    printf 'pass_markers=%s\nfailure_markers=%s\nwarnings=%s\n' \
        "${PASS_COUNT}" "${FAIL_COUNT}" "${WARNING_COUNT}"
    printf 'verilator_flags=--binary --timing --sv -O3 --no-assert --no-trace -CFLAGS=-O3\n'
    printf 'portal_enable=1\nlanes=8\nprofiles=P00,P16,P17-empty,P18-empty\nscenarios=17\n'
    printf 'p00_elements=16\np00_groups=2\np00_input_words=32\np00_output_words=16\n'
    printf 'p16_elements=2048\np16_groups=256\np16_input_words=2048\np16_output_words=2048\n'
    printf 'p17_empty_elements=0\np18_empty_elements=0\nempty_child_starts=0\nempty_portal_groups=0\n'
    printf 'completion_gmem_read_bytes=0\ncompletion_gmem_write_bytes=0\n'
    printf 'negative_cases=malformed-empty-matrix,wrong-mask,response-error\ncommit_suppressed=1\n'
    sha256sum \
        rtl/TensorNpuCoprocessor.v \
        sim/NpcTensorNpuSystemTop.sv \
        rtl/TensorNpuF32AluPortalAdapter.v \
        rtl/TensorNpuF32AluSimdCore.v \
        tests/tb_coprocessor_f32_alu_portal.sv \
        scripts/run_coprocessor_f32_alu_portal.sh
} >"${RESULT_LOG}"

if [[ "${RUN_EXIT}" -ne 0 || "${PASS_COUNT}" -ne 1 || \
      "${FAIL_COUNT}" -ne 0 || "${WARNING_COUNT}" -ne 0 ]]; then
    printf '[COPROCESSOR-F32-ALU-PORTAL][FAIL] phase=run exit=%d pass=%s failures=%s warnings=%s log=%s\n' \
        "${RUN_EXIT}" "${PASS_COUNT}" "${FAIL_COUNT}" \
        "${WARNING_COUNT}" "${RUN_LOG}"
    exit 1
fi

printf '[COPROCESSOR-F32-ALU-PORTAL][PASS] build_exit=0 run_exit=0 pass=1 failures=0 warnings=0 assertions=off waveforms=off optimization=O3 build=%s log=%s result=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${RESULT_LOG}"
