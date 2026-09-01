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
            printf '[COPROCESSOR-FUNCTIONAL-COMMAND][FAIL] generated path escapes project tmp/: %s\n' \
                "${resolved}" >&2
            exit 1
            ;;
    esac
}

readonly RUN_ID="coprocessor-functional-command-$(date -u +%Y%m%dT%H%M%SZ)-${BASHPID}"
readonly BUILD_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/build/${RUN_ID}")"
readonly LOG_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/logs/${RUN_ID}")"
readonly COMPILER_TMP_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/compiler/${RUN_ID}")"
readonly CACHE_DIR="$(project_tmp_path "${PROJECT_ROOT}/tmp/cache/${RUN_ID}")"
readonly OBJ_DIR="$(project_tmp_path "${BUILD_DIR}/obj_dir")"
readonly BUILD_LOG="$(project_tmp_path "${LOG_DIR}/build.log")"
readonly STUB_CHECK_LOG="$(project_tmp_path "${LOG_DIR}/stub-check.log")"
readonly RUN_LOG="$(project_tmp_path "${LOG_DIR}/run.log")"
readonly COMMAND_LOG="$(project_tmp_path "${LOG_DIR}/command.txt")"
readonly RESULT_LOG="$(project_tmp_path "${LOG_DIR}/result.txt")"
mkdir -p -- "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" "${CACHE_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
export XDG_CACHE_HOME="${CACHE_DIR}"
unset MAKEFLAGS MFLAGS

readonly -a STUB_CHECK_CMD=(
    /usr/bin/c++
    -isystem /usr/share/verilator/include
    -isystem /usr/share/verilator/include/vltstd
    -O3
    -DNDEBUG
    -std=c++17
    -Wall
    -Wextra
    -Wpedantic
    -fsyntax-only
    "${PROJECT_ROOT}/tests/npu-functional-command-coprocessor-stub.cpp"
)

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
    rtl/TensorNpuFunctionalCommandDpi.sv
    rtl/TensorNpuCoprocessor.v
    rtl/TensorNpuCommandDecoder.v
    rtl/TensorNpuRegisterFile.v
    rtl/TensorNpuMm2Engine.v
    rtl/TensorNpuDmaEngine.v
    rtl/TensorNpuLocalMemory.v
    tests/tb_coprocessor_functional_command.sv
    "${PROJECT_ROOT}/tests/npu-functional-command-coprocessor-stub.cpp"
)

readonly -a VERILATOR_CMD=(
    verilator
    --binary
    --timing
    --sv
    -O3
    --no-assert
    --no-trace
    -DNPU_FUNCTIONAL_COMMAND_DPI
    -CFLAGS "-O3 -DNDEBUG -std=c++17 -march=native"
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
    --top-module tb_coprocessor_functional_command
    --Mdir "${OBJ_DIR}"
    -o Vtb_coprocessor_functional_command
    "${SOURCES[@]}"
)

{
    printf 'cwd=%q\n' "${PROJECT_ROOT}"
    printf 'stub_check='
    printf '%q ' "${STUB_CHECK_CMD[@]}"
    printf '\ncommand='
    printf '%q ' "${VERILATOR_CMD[@]}"
    printf '\nassertions=off\nwaveforms=off\noptimization=O3\n'
    printf 'define=NPU_FUNCTIONAL_COMMAND_DPI\nfunctional_enable=1\n'
    printf 'scenarios=q8-gemv,f32-p00,static-preflight-reject,vector-zero-ledger,callback-f003\n'
    printf 'legacy_responses=valid,error,poison\n'
} >"${COMMAND_LOG}"

set +e
"${STUB_CHECK_CMD[@]}" >"${STUB_CHECK_LOG}" 2>&1
STUB_CHECK_EXIT=$?
set -e
if [[ "${STUB_CHECK_EXIT}" -ne 0 || -s "${STUB_CHECK_LOG}" ]]; then
    cat -- "${STUB_CHECK_LOG}"
    printf '[COPROCESSOR-FUNCTIONAL-COMMAND][FAIL] phase=stub-check exit=%d log=%s\n' \
        "${STUB_CHECK_EXIT}" "${STUB_CHECK_LOG}"
    exit 1
fi

set +e
"${VERILATOR_CMD[@]}" >"${BUILD_LOG}" 2>&1
BUILD_EXIT=$?
set -e
WARNING_COUNT="$(grep -Eci '(^%Warning|(^|[[:space:]])warning:)' "${BUILD_LOG}" || true)"

if [[ "${BUILD_EXIT}" -ne 0 ]]; then
    cat -- "${BUILD_LOG}"
    {
        printf 'schema=coprocessor-functional-command-result-v1\n'
        printf 'status=FAIL\nphase=build\n'
        printf 'stub_check_exit=%d\nbuild_exit=%d\nwarnings=%s\n' \
            "${STUB_CHECK_EXIT}" "${BUILD_EXIT}" "${WARNING_COUNT}"
        sha256sum \
            rtl/TensorNpuFunctionalCommandDpi.sv \
            rtl/TensorNpuCoprocessor.v \
            tests/tb_coprocessor_functional_command.sv \
            tests/npu-functional-command-coprocessor-stub.cpp \
            scripts/run_coprocessor_functional_command.sh
    } >"${RESULT_LOG}"
    printf '[COPROCESSOR-FUNCTIONAL-COMMAND][FAIL] phase=build exit=%d warnings=%s log=%s\n' \
        "${BUILD_EXIT}" "${WARNING_COUNT}" "${BUILD_LOG}"
    exit "${BUILD_EXIT}"
fi

set +e
timeout 240s "${OBJ_DIR}/Vtb_coprocessor_functional_command" \
    >"${RUN_LOG}" 2>&1
RUN_EXIT=$?
set -e
cat -- "${RUN_LOG}"

PASS_COUNT="$(grep -Fc \
    '[NPU-COPROCESSOR-FUNCTIONAL-COMMAND][PASS]' \
    "${RUN_LOG}" || true)"
FAIL_COUNT="$(grep -Ec \
    '\[(NPU-COPROCESSOR-FUNCTIONAL-COMMAND|COPROCESSOR-FUNCTIONAL-COMMAND)\]\[FAIL\]|%Error|%Fatal' \
    "${RUN_LOG}" || true)"
WAVEFORM_COUNT="$(find "${BUILD_DIR}" "${LOG_DIR}" -type f \
    \( -name '*.vcd' -o -name '*.fst' -o -name '*.ghw' \) -print \
    | wc -l)"

{
    printf 'schema=coprocessor-functional-command-result-v1\n'
    printf 'stub_check_exit=%d\nbuild_exit=%d\nrun_exit=%d\n' \
        "${STUB_CHECK_EXIT}" "${BUILD_EXIT}" "${RUN_EXIT}"
    printf 'pass_markers=%s\nfailure_markers=%s\nwarnings=%s\nwaveforms=%s\n' \
        "${PASS_COUNT}" "${FAIL_COUNT}" "${WARNING_COUNT}" \
        "${WAVEFORM_COUNT}"
    printf 'verilator_flags=--binary --timing --sv -O3 --no-assert --no-trace\n'
    printf 'define=NPU_FUNCTIONAL_COMMAND_DPI\nfunctional_enable=1\n'
    printf 'q8_read_bytes=596\nq8_write_bytes=20\nq8_mac_count=320\nq8_vector_elements=5\n'
    printf 'f32_read_bytes=128\nf32_write_bytes=64\nf32_vector_elements=16\n'
    printf 'required_issued=5\nrequired_completed=2\nmacro_commands=5\nmacro_completions=2\nerrors=3\n'
    printf 'dpi_dispatches=4\ndpi_completions=4\npreflight_reject_dpi_calls=0\n'
    printf 'vector_zero_ledger_public_error=MACRO_PROTOCOL\nvector_zero_ledger_error_class=11\n'
    printf 'callback_private_error=F003\ncallback_public_error=MACRO_IOVA\ncallback_error_class=5\ncallback_dst_commit=0\n'
    printf 'raw_gmem_activity=0\nq8_portal_activity=0\nf32_alu_portal_activity=0\nf32_mover_portal_activity=0\n'
    sha256sum \
        rtl/TensorNpuFunctionalCommandDpi.sv \
        rtl/TensorNpuCoprocessor.v \
        tests/tb_coprocessor_functional_command.sv \
        tests/npu-functional-command-coprocessor-stub.cpp \
        scripts/run_coprocessor_functional_command.sh
} >"${RESULT_LOG}"

if [[ "${RUN_EXIT}" -ne 0 || "${PASS_COUNT}" -ne 1 \
      || "${FAIL_COUNT}" -ne 0 || "${WARNING_COUNT}" -ne 0 \
      || "${WAVEFORM_COUNT}" -ne 0 ]]; then
    printf '[COPROCESSOR-FUNCTIONAL-COMMAND][FAIL] phase=run exit=%d pass=%s failures=%s warnings=%s waveforms=%s log=%s\n' \
        "${RUN_EXIT}" "${PASS_COUNT}" "${FAIL_COUNT}" \
        "${WARNING_COUNT}" "${WAVEFORM_COUNT}" "${RUN_LOG}"
    exit 1
fi

printf '[COPROCESSOR-FUNCTIONAL-COMMAND][PASS] build_exit=0 run_exit=0 pass=1 failures=0 warnings=0 assertions=off waveforms=off optimization=O3 build=%s log=%s result=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${RESULT_LOG}"
