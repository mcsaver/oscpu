#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly WORKSPACE_ROOT="$(cd -- "${PROJECT_ROOT}/../.." && pwd -P)"
readonly RUN_TIMEOUT_SECONDS="${NPU_REGRESSION_TIMEOUT_SECONDS:-20}"
readonly FIRST_BATCH_RUN_TIMEOUT_SECONDS="${NPU_FIRST_BATCH_REGRESSION_TIMEOUT_SECONDS:-300}"
readonly BATCH2_RUN_TIMEOUT_SECONDS="${NPU_BATCH2_REGRESSION_TIMEOUT_SECONDS:-3600}"
readonly TASK_RUN_STATUS_HELPER="${WORKSPACE_ROOT}/scripts/task-run-status.sh"
# Ordinary regression runs are fresh, self-contained engineering runs.  The
# former receipt/seal recovery workflow remains available only behind the
# explicit --legacy-forensic compatibility boundary.
LEGACY_FORENSIC=0
if [[ "${1:-}" == --legacy-forensic ]]; then
    LEGACY_FORENSIC=1
    shift
fi

die() {
    printf '[NPU-REGRESSION][FAIL] %s\n' "$*" >&2
    exit 1
}

# Canonicalize every generated path before it is used.  The stricter tmp-only
# check also proves that build products, logs, caches, and compiler temporaries
# cannot escape the project root.
project_tmp_path() {
    local canonical_path
    canonical_path="$(realpath -m -- "$1")"
    case "${canonical_path}" in
        "${PROJECT_ROOT}/tmp"|"${PROJECT_ROOT}/tmp/"*)
            printf '%s\n' "${canonical_path}"
            ;;
        *)
            die "generated path escapes project tmp/: ${canonical_path}"
            ;;
    esac
}

readonly TMP_ROOT="$(project_tmp_path "${PROJECT_ROOT}/tmp")"
if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
    RUN_INSTANCE=npu-regression-v33
else
    RUN_INSTANCE="npu-regression-$(date -u +%Y%m%dT%H%M%S)-${BASHPID}"
fi
readonly RUN_INSTANCE
readonly BUILD_ROOT="$(project_tmp_path "${TMP_ROOT}/build/${RUN_INSTANCE}")"
readonly LOG_ROOT="$(project_tmp_path "${TMP_ROOT}/logs/${RUN_INSTANCE}")"
readonly CACHE_ROOT="$(project_tmp_path "${TMP_ROOT}/cache/${RUN_INSTANCE}")"
readonly COMPILER_TMP_ROOT="$(project_tmp_path "${TMP_ROOT}/compiler/${RUN_INSTANCE}")"
readonly STATUS_PATH="$(project_tmp_path "${LOG_ROOT}/task-run.status")"
readonly CLEANUP_AUDIT_PATH="$(project_tmp_path "${LOG_ROOT}/cleanup-audit.log")"
readonly ATTEMPT02_NAME='attempt-02-literal-force-release-fail'
readonly ATTEMPT02_BUILD_ROOT="$(project_tmp_path "${BUILD_ROOT}/${ATTEMPT02_NAME}")"
readonly ATTEMPT02_LOG_ROOT="$(project_tmp_path "${LOG_ROOT}/${ATTEMPT02_NAME}")"
readonly ATTEMPT03_NAME='attempt-03-source-path-audit-fail'
readonly ATTEMPT03_BUILD_ROOT="$(project_tmp_path "${BUILD_ROOT}/${ATTEMPT03_NAME}")"
readonly ATTEMPT03_LOG_ROOT="$(project_tmp_path "${LOG_ROOT}/${ATTEMPT03_NAME}")"
readonly ATTEMPT04_NAME='attempt-04-forbidden-self-match-fail'
readonly ATTEMPT04_BUILD_ROOT="$(project_tmp_path "${BUILD_ROOT}/${ATTEMPT04_NAME}")"
readonly ATTEMPT04_LOG_ROOT="$(project_tmp_path "${LOG_ROOT}/${ATTEMPT04_NAME}")"

readonly SOURCE_LOCK_PATH="${PROJECT_ROOT}/third_party/SOURCES.lock.json"
readonly PREBUILD_LOCK_LOG="${PROJECT_ROOT}/tmp/logs/locked-inputs/fp64-fma-prebuild.log"
readonly RUNNER_PATH="${PROJECT_ROOT}/scripts/run_npu_regression.sh"
readonly UNARY_FILELIST_PATH="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.compile-filelist")"
readonly UNARY_CONFIG_PATH="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.config")"
readonly SOURCE_MANIFEST_PRE="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.sources.pre.sha256")"
readonly SOURCE_MANIFEST_POST="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.sources.post.sha256")"
readonly EXPECTED_PROJECT_SOURCES="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.expected-project-sources.list")"
readonly GENERATED_PROJECT_SOURCES="$(project_tmp_path "${LOG_ROOT}/tb_unary_glu_element.generated-project-sources.list")"
readonly MARKER_ORACLE_SELF_TEST_LOG="$(project_tmp_path "${LOG_ROOT}/marker-oracle-self-test.log")"
readonly SOURCE_PARSER_SELF_TEST_LOG="$(project_tmp_path "${LOG_ROOT}/source-parser-self-test.log")"
readonly FORBIDDEN_AUDIT_SELF_TEST_LOG="$(project_tmp_path "${LOG_ROOT}/forbidden-audit-self-test.log")"
readonly FORBIDDEN_OBJECTS_PATH="$(project_tmp_path "${LOG_ROOT}/forbidden-audit-objects.list")"
readonly TEST_PLAN_PATH="$(project_tmp_path "${LOG_ROOT}/test-plan.log")"
readonly REPAIR_LEGACY_SOURCE_PRE="$(project_tmp_path "${LOG_ROOT}/repair-legacy-sources.pre.sha256")"
readonly REPAIR_LEGACY_SOURCE_POST="$(project_tmp_path "${LOG_ROOT}/repair-legacy-sources.post.sha256")"
readonly REPAIR_COMPOSITE_AUDIT="$(project_tmp_path "${LOG_ROOT}/repair-composite-audit.log")"
readonly SEAL_SOURCE_CHECK="$(project_tmp_path "${LOG_ROOT}/seal-source-check.log")"

# The coprocessor now contains the production VECTOR_F32 macro path.  Keep its
# directed legacy-command test on the same ordered arithmetic source closure
# as the dynamic backend so elaboration cannot silently omit the macro child.
readonly -a COPROCESSOR_RTL_SOURCES=(
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
    rtl/TensorNpuF32TensorAlu.v
    rtl/TensorNpuVectorF32Adapter.v
    rtl/TensorNpuF32AluSimdCore.v
    rtl/TensorNpuF32AluPortalAdapter.v
    rtl/TensorNpuF32GatherRepeatPortalAdapter.v
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
)

RUN_MODE='full-from-zero'
REPAIR_COMPOSITE=0
SEAL_EXISTING=0

# 第33项的显式Verilator filelist。三项被HardFloat `include的.vi文件
# 另列入manifest，确保source-to-binary身份覆盖实际elaboration输入。
readonly -a UNARY_GLU_COMPILE_SOURCES=(
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
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
    rtl/TensorNpuFp32ToFp64.v
    rtl/TensorNpuFp64Fma.v
    rtl/TensorNpuFp64ToInt32Rmm.v
    rtl/TensorNpuInt32ToFp64.v
    rtl/TensorNpuFp64ToFp32Finite.v
    rtl/TensorNpuAorExp32.v
    rtl/TensorNpuAorLog32.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Div.v
    rtl/TensorNpuUnaryGluElement.v
    tests/tb_unary_glu_element.sv
)
# Reuse the audited arithmetic/element closure without also elaborating the
# legacy element TB as a second top.  The first 32 entries above are RTL/vendor
# sources; entry 33 is deliberately the legacy TB and remains frozen for the
# historical source-to-binary audit below.
readonly -a UNARY_GLU_ADAPTER_COMPILE_SOURCES=(
    "${UNARY_GLU_COMPILE_SOURCES[@]:0:32}"
    rtl/TensorNpuUnaryGluWritebackAdapter.v
    tests/tb_unary_glu_writeback_adapter.sv
)
readonly -a NORM_WRITEBACK_COMPILE_SOURCES=(
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
    third_party/hardfloat/source/HardFloat_primitives.v
    third_party/hardfloat/source/isSigNaNRecFN.v
    third_party/hardfloat/source/HardFloat_rawFN.v
    third_party/hardfloat/source/fNToRecFN.v
    third_party/hardfloat/source/recFNToFN.v
    third_party/hardfloat/source/recFNToRecFN.v
    third_party/hardfloat/source/addRecFN.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Div.v
    rtl/TensorNpuFp32Sqrt.v
    rtl/TensorNpuFp32ToFp64.v
    rtl/TensorNpuFp64Add.v
    rtl/TensorNpuFp64ToFp32.v
    rtl/TensorNpuFp32SquareSum64.v
    rtl/TensorNpuFp64Pow2Scale.v
    rtl/TensorNpuNormEngine.v
    rtl/TensorNpuNormWritebackAdapter.v
    tests/tb_norm_writeback_adapter.sv
)
readonly -a SUM_ROWS_WRITEBACK_COMPILE_SOURCES=(
    third_party/hardfloat/source/HardFloat_primitives.v
    third_party/hardfloat/source/HardFloat_rawFN.v
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v
    third_party/hardfloat/source/fNToRecFN.v
    third_party/hardfloat/source/recFNToFN.v
    third_party/hardfloat/source/recFNToRecFN.v
    third_party/hardfloat/source/addRecFN.v
    rtl/TensorNpuFp32ToFp64Ieee.v
    rtl/TensorNpuFp64AddIeee.v
    rtl/TensorNpuFp64ToFp32Ieee.v
    rtl/TensorNpuOrderedSumRows.v
    rtl/TensorNpuSumRowsWritebackAdapter.v
    tests/tb_sum_rows_writeback_adapter.sv
)
readonly -a MOVER_SET_ROWS_WRITEBACK_COMPILE_SOURCES=(
    rtl/TensorNpuFp32ToFp16.v
    rtl/TensorNpuTensorMover.v
    rtl/TensorNpuSetRowsEngine.v
    rtl/TensorNpuMoverSetRowsWritebackAdapter.v
    tests/tb_mover_set_rows_writeback_adapter.sv
)
readonly -a SSM_CONV_WRITEBACK_COMPILE_SOURCES=(
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
    third_party/fpu-sp/verilog/src/float/fp_ext.sv
    third_party/fpu-sp/verilog/src/float/fp_fma.sv
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuSsmConvWritebackAdapter.v
    tests/tb_ssm_conv_writeback_adapter.sv
)
readonly -a F16_ATTENTION_MATMUL_COMPILE_SOURCES=(
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
    third_party/fpu-sp/verilog/src/float/fp_ext.sv
    third_party/fpu-sp/verilog/src/float/fp_fma.sv
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    rtl/TensorNpuFp16ToFp32.v
    rtl/TensorNpuFp32ToFp16.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Fma.v
    rtl/TensorNpuF16AttentionMatmulWritebackAdapter.v
    tests/tb_f16_attention_matmul_writeback_adapter.sv
)
readonly -a SOFTMAX_WRITEBACK_COMPILE_SOURCES=(
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
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
    rtl/TensorNpuFp32ToFp64.v
    rtl/TensorNpuFp64Fma.v
    rtl/TensorNpuFp64ToInt32Rmm.v
    rtl/TensorNpuInt32ToFp64.v
    rtl/TensorNpuFp64ToFp32Finite.v
    rtl/TensorNpuAorExp32.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Div.v
    rtl/TensorNpuSoftmaxWritebackAdapter.v
    tests/tb_softmax_writeback_adapter.sv
)
readonly -a ROPE_WRITEBACK_COMPILE_SOURCES=(
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    third_party/fpu-sp/verilog/src/float/fp_wire.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
    third_party/fpu-sp/verilog/src/float/fp_ext.sv
    third_party/fpu-sp/verilog/src/float/fp_fma.sv
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    rtl/TensorNpuInt32ToFp32.v
    rtl/TensorNpuFp32SincosCordic.v
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuFp32Fma.v
    rtl/TensorNpuRopeWritebackAdapter.v
    tests/tb_rope_writeback_adapter.sv
)
readonly -a UNARY_GLU_TRANSITIVE_SOURCES=(
    third_party/hardfloat/source/HardFloat_consts.vi
    third_party/hardfloat/source/HardFloat_localFuncs.vi
    third_party/hardfloat/source/RISCV/HardFloat_specialize.vi
)
UNARY_GLU_MANIFEST_SOURCES=(
    "${UNARY_GLU_COMPILE_SOURCES[@]}"
    "${UNARY_GLU_TRANSITIVE_SOURCES[@]}"
)
readonly -a UNARY_GLU_MANIFEST_SOURCES

EXPECTED_TESTS=(
    tb_decoder_regfile
    tb_local_memory
    tb_mm2_engine
    tb_dma_engine
    tb_coprocessor
    tb_q8_dot_engine
    tb_fp16_to_fp32
    tb_int32_to_fp32
    tb_fp32_addmul
    tb_fp32_div
    tb_fp32_to_fp16
    tb_fp32_to_int32_rmm
    tb_q8_scale_accumulator
    tb_q8_reference_quantizer
    tb_q8_stream_gemv
    tb_q8_dequant_block
    tb_q8_get_rows_engine
    tb_tensor_mover
    tb_set_rows_engine
    tb_fp32_sqrt
    tb_fp32_to_fp64
    tb_fp64_add
    tb_fp64_to_fp32
    tb_fp64_to_int32_rmm
    tb_int32_to_fp64
    tb_fp64_fma
    tb_fp32_square_sum64
    tb_fp64_pow2_scale
    tb_norm_engine
    tb_fp64_to_fp32_finite
    tb_aor_exp32
    tb_aor_log32
    tb_unary_glu_element
)
if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    EXPECTED_TESTS+=(
        tb_q8_row_simd_core
        tb_q8_gemv_portal_adapter
        tb_f32_alu_simd_core
        tb_q8_gemv_writeback_adapter
        tb_q8_get_rows_writeback_adapter
        tb_coprocessor_q8_get_rows
        tb_coprocessor_q8_gemv
        tb_coprocessor_q8_gemv_portal
        tb_f32_gather_repeat_adapter
        tb_coprocessor_f32_gather_repeat
        tb_coprocessor_unary_norm_sum_ssm
        tb_coprocessor_mover_attention_softmax_rope
        tb_unary_glu_writeback_adapter
        tb_norm_writeback_adapter
        tb_sum_rows_writeback_adapter
        tb_mover_set_rows_writeback_adapter
        tb_ssm_conv_writeback_adapter
        tb_f16_attention_matmul_writeback_adapter
        tb_softmax_writeback_adapter
        tb_rope_writeback_adapter
    )
fi
readonly -a EXPECTED_TESTS
readonly EXPECTED_TEST_COUNT="${#EXPECTED_TESTS[@]}"
readonly FINAL_PASS_MARKER="[NPU-REGRESSION][PASS] tests=${EXPECTED_TEST_COUNT} assertions=off waveform=off optimization=O3"

count_pass_marker() {
    local test_name="${1:?test name is required}"
    local pass_marker="${2:?pass marker is required}"
    local run_log="${3:?run log is required}"

    if [[ "${test_name}" == tb_unary_glu_element ]]; then
        awk -v marker="${pass_marker}" \
            '$0 == marker { count++ } END { print count + 0 }' \
            "${run_log}"
    else
        # 历史32项允许marker后的既有checks/transactions摘要，但marker必须
        # 从行首开始；行中子串、缺失和重复行均不能满足exact-one gate。
        awk -v marker="${pass_marker}" \
            'index($0, marker) == 1 { count++ } END { print count + 0 }' \
            "${run_log}"
    fi
}

run_marker_oracle_self_test() {
    local fixture_dir="${COMPILER_TMP_ROOT}/marker-oracle-self-test"
    local legacy_marker='[NPU-MARKER-SELFTEST][PASS]'
    local suffix_count
    local midline_count
    local duplicate_count
    local missing_count
    local unary_exact_count
    local unary_suffix_count
    local self_test_rc=0

    command -v awk >/dev/null 2>&1 || die 'marker oracle self-test requires awk'
    [[ ! -e "${fixture_dir}" ]] \
        || die "marker oracle fixture already exists: ${fixture_dir}"
    mkdir -- "${fixture_dir}"
    printf '%s checks=61\n' "${legacy_marker}" >"${fixture_dir}/suffix.log"
    printf 'prefix %s checks=61\n' "${legacy_marker}" >"${fixture_dir}/midline.log"
    printf '%s first\n%s second\n' "${legacy_marker}" "${legacy_marker}" \
        >"${fixture_dir}/duplicate.log"
    printf '[NPU-MARKER-SELFTEST][OTHER]\n' >"${fixture_dir}/missing.log"
    printf '[NPU-UNARY-GLU-ELEMENT][PASS]\n' >"${fixture_dir}/unary-exact.log"
    printf '[NPU-UNARY-GLU-ELEMENT][PASS] checks=1\n' \
        >"${fixture_dir}/unary-suffix.log"

    suffix_count="$(count_pass_marker legacy "${legacy_marker}" \
        "${fixture_dir}/suffix.log")"
    midline_count="$(count_pass_marker legacy "${legacy_marker}" \
        "${fixture_dir}/midline.log")"
    duplicate_count="$(count_pass_marker legacy "${legacy_marker}" \
        "${fixture_dir}/duplicate.log")"
    missing_count="$(count_pass_marker legacy "${legacy_marker}" \
        "${fixture_dir}/missing.log")"
    unary_exact_count="$(count_pass_marker tb_unary_glu_element \
        '[NPU-UNARY-GLU-ELEMENT][PASS]' "${fixture_dir}/unary-exact.log")"
    unary_suffix_count="$(count_pass_marker tb_unary_glu_element \
        '[NPU-UNARY-GLU-ELEMENT][PASS]' "${fixture_dir}/unary-suffix.log")"

    if [[ "${suffix_count}" -ne 1 || "${midline_count}" -ne 0 ||
          "${duplicate_count}" -ne 2 || "${missing_count}" -ne 0 ||
          "${unary_exact_count}" -ne 1 || "${unary_suffix_count}" -ne 0 ]]; then
        self_test_rc=1
    fi
    if ! rm -rf -- "${fixture_dir}"; then
        self_test_rc=1
    fi
    {
        printf 'legacy_suffix_count=%s expected=1 gate=accept\n' "${suffix_count}"
        printf 'legacy_midline_count=%s expected=0 gate=reject\n' "${midline_count}"
        printf 'legacy_duplicate_count=%s expected=2 gate=reject\n' "${duplicate_count}"
        printf 'legacy_missing_count=%s expected=0 gate=reject\n' "${missing_count}"
        printf 'unary_exact_count=%s expected=1 gate=accept\n' "${unary_exact_count}"
        printf 'unary_suffix_count=%s expected=0 gate=reject\n' "${unary_suffix_count}"
        printf 'marker_oracle_self_test_rc=%d\n' "${self_test_rc}"
        if [[ "${self_test_rc}" -eq 0 ]]; then
            printf 'marker_oracle_self_test=PASS\n'
        else
            printf 'marker_oracle_self_test=FAIL\n'
        fi
    } >"${MARKER_ORACLE_SELF_TEST_LOG}"
    return "${self_test_rc}"
}

extract_generated_project_sources() {
    local verfiles_path="${1:?generated __verFiles.dat is required}"
    local expected_path="${2:?expected source list is required}"
    local output_path="${3:?normalized source output is required}"
    local line
    local without_closing_quote
    local raw_path
    local candidate_path
    local canonical_path
    local expected_source
    local expected_canonical
    local external_key
    local expected_count=0
    local generated_count=0
    local -A expected_sources=()
    local -A generated_sources=()
    local -A known_external_sources=()

    [[ -s "${verfiles_path}" ]] || {
        printf 'source-parser: empty/missing verFiles path=%s\n' \
            "${verfiles_path}" >&2
        return 1
    }
    [[ -s "${expected_path}" ]] || {
        printf 'source-parser: empty/missing expected list path=%s\n' \
            "${expected_path}" >&2
        return 1
    }

    while IFS= read -r expected_source || [[ -n "${expected_source}" ]]; do
        [[ -n "${expected_source}" ]] || {
            printf 'source-parser: blank expected source\n' >&2
            return 1
        }
        expected_canonical="$(realpath -m -- "${expected_source}")" || return 1
        [[ "${expected_canonical}" == "${expected_source}" &&
           "${expected_canonical}" != "${PROJECT_ROOT}" &&
           "${expected_canonical}" == "${PROJECT_ROOT}/"* &&
           -f "${expected_canonical}" ]] || {
            printf 'source-parser: invalid expected source=%s canonical=%s\n' \
                "${expected_source}" "${expected_canonical}" >&2
            return 1
        }
        [[ -z "${expected_sources[${expected_canonical}]+present}" ]] || {
            printf 'source-parser: duplicate expected source=%s\n' \
                "${expected_canonical}" >&2
            return 1
        }
        expected_sources["${expected_canonical}"]=1
        expected_count=$((expected_count + 1))
    done <"${expected_path}"

    : >"${output_path}"
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" == S\ * ]] || continue
        [[ "${line}" == *\" ]] || {
            printf 'source-parser: malformed S row=%s\n' "${line}" >&2
            return 1
        }
        without_closing_quote="${line%\"}"
        [[ "${without_closing_quote}" == *\"* ]] || {
            printf 'source-parser: missing opening quote row=%s\n' "${line}" >&2
            return 1
        }
        raw_path="${without_closing_quote##*\"}"
        [[ -n "${raw_path}" ]] || {
            printf 'source-parser: empty S path\n' >&2
            return 1
        }

        # Verilator 5.020 records these two tool dependencies as S rows. They
        # are not RTL/filelist sources; recognize exactly once and reject any
        # other absolute dependency outside the project as unknown.
        case "${raw_path}" in
            /usr/bin/verilator_bin|/usr/share/verilator/include/verilated_std.sv)
                external_key="${raw_path}"
                [[ -z "${known_external_sources[${external_key}]+present}" ]] || {
                    printf 'source-parser: duplicate known tool row=%s\n' \
                        "${raw_path}" >&2
                    return 1
                }
                known_external_sources["${external_key}"]=1
                continue
                ;;
        esac

        if [[ "${raw_path}" == /* ]]; then
            candidate_path="${raw_path}"
        else
            candidate_path="${PROJECT_ROOT}/${raw_path}"
        fi
        canonical_path="$(realpath -m -- "${candidate_path}")" || return 1
        [[ "${canonical_path}" != "${PROJECT_ROOT}" &&
           "${canonical_path}" == "${PROJECT_ROOT}/"* ]] || {
            printf 'source-parser: project escape/root raw=%s canonical=%s\n' \
                "${raw_path}" "${canonical_path}" >&2
            return 1
        }
        [[ -f "${canonical_path}" ]] || {
            printf 'source-parser: source is not a file raw=%s canonical=%s\n' \
                "${raw_path}" "${canonical_path}" >&2
            return 1
        }
        [[ -n "${expected_sources[${canonical_path}]+present}" ]] || {
            printf 'source-parser: unknown project source=%s\n' \
                "${canonical_path}" >&2
            return 1
        }
        [[ -z "${generated_sources[${canonical_path}]+present}" ]] || {
            printf 'source-parser: duplicate generated source=%s\n' \
                "${canonical_path}" >&2
            return 1
        }
        generated_sources["${canonical_path}"]=1
        generated_count=$((generated_count + 1))
        printf '%s\n' "${canonical_path}" >>"${output_path}"
    done <"${verfiles_path}"

    [[ "${generated_count}" -eq "${expected_count}" ]] || {
        printf 'source-parser: count mismatch generated=%d expected=%d\n' \
            "${generated_count}" "${expected_count}" >&2
        return 1
    }
    LC_ALL=C sort -o "${output_path}" "${output_path}"
    cmp -s -- "${expected_path}" "${output_path}" || {
        printf 'source-parser: normalized set mismatch\n' >&2
        return 1
    }
}

run_source_parser_self_test() {
    local fixture_dir="${COMPILER_TMP_ROOT}/source-parser-self-test"
    local rel_expected="${PROJECT_ROOT}/rtl/TensorNpuUnaryGluElement.v"
    local abs_expected="${PROJECT_ROOT}/tests/tb_unary_glu_element.sv"
    local unknown_source="${PROJECT_ROOT}/rtl/TensorNpuAorExp32.v"
    local relative_accept=0
    local absolute_accept=0
    local parent_escape_reject=0
    local project_root_reject=0
    local duplicate_reject=0
    local missing_reject=0
    local unknown_reject=0
    local self_test_rc=0

    [[ ! -e "${fixture_dir}" ]] \
        || die "source parser fixture already exists: ${fixture_dir}"
    mkdir -- "${fixture_dir}"

    printf '%s\n' "${rel_expected}" >"${fixture_dir}/relative.expected"
    printf 'S 0 0 "rtl/TensorNpuUnaryGluElement.v"\n' \
        >"${fixture_dir}/relative.verFiles"
    if extract_generated_project_sources \
            "${fixture_dir}/relative.verFiles" \
            "${fixture_dir}/relative.expected" \
            "${fixture_dir}/relative.output" \
            >"${fixture_dir}/relative.stdout" \
            2>"${fixture_dir}/relative.stderr"; then
        relative_accept=1
    fi

    printf '%s\n' "${abs_expected}" >"${fixture_dir}/absolute.expected"
    printf 'S 0 0 "%s"\n' "${abs_expected}" \
        >"${fixture_dir}/absolute.verFiles"
    if extract_generated_project_sources \
            "${fixture_dir}/absolute.verFiles" \
            "${fixture_dir}/absolute.expected" \
            "${fixture_dir}/absolute.output" \
            >"${fixture_dir}/absolute.stdout" \
            2>"${fixture_dir}/absolute.stderr"; then
        absolute_accept=1
    fi

    printf '%s\n' "${rel_expected}" >"${fixture_dir}/negative.expected"
    printf 'S 0 0 "../../../../../../etc/passwd"\n' \
        >"${fixture_dir}/parent-escape.verFiles"
    if ! extract_generated_project_sources \
            "${fixture_dir}/parent-escape.verFiles" \
            "${fixture_dir}/negative.expected" \
            "${fixture_dir}/parent-escape.output" \
            >"${fixture_dir}/parent-escape.stdout" \
            2>"${fixture_dir}/parent-escape.stderr"; then
        parent_escape_reject=1
    fi

    printf 'S 0 0 "."\n' >"${fixture_dir}/project-root.verFiles"
    if ! extract_generated_project_sources \
            "${fixture_dir}/project-root.verFiles" \
            "${fixture_dir}/negative.expected" \
            "${fixture_dir}/project-root.output" \
            >"${fixture_dir}/project-root.stdout" \
            2>"${fixture_dir}/project-root.stderr"; then
        project_root_reject=1
    fi

    printf 'S 0 0 "rtl/TensorNpuUnaryGluElement.v"\nS 0 0 "rtl/TensorNpuUnaryGluElement.v"\n' \
        >"${fixture_dir}/duplicate.verFiles"
    if ! extract_generated_project_sources \
            "${fixture_dir}/duplicate.verFiles" \
            "${fixture_dir}/negative.expected" \
            "${fixture_dir}/duplicate.output" \
            >"${fixture_dir}/duplicate.stdout" \
            2>"${fixture_dir}/duplicate.stderr"; then
        duplicate_reject=1
    fi

    printf '%s\n%s\n' "${rel_expected}" "${abs_expected}" \
        | LC_ALL=C sort >"${fixture_dir}/missing.expected"
    printf 'S 0 0 "rtl/TensorNpuUnaryGluElement.v"\n' \
        >"${fixture_dir}/missing.verFiles"
    if ! extract_generated_project_sources \
            "${fixture_dir}/missing.verFiles" \
            "${fixture_dir}/missing.expected" \
            "${fixture_dir}/missing.output" \
            >"${fixture_dir}/missing.stdout" \
            2>"${fixture_dir}/missing.stderr"; then
        missing_reject=1
    fi

    printf 'S 0 0 "%s"\n' "${unknown_source}" \
        >"${fixture_dir}/unknown.verFiles"
    if ! extract_generated_project_sources \
            "${fixture_dir}/unknown.verFiles" \
            "${fixture_dir}/negative.expected" \
            "${fixture_dir}/unknown.output" \
            >"${fixture_dir}/unknown.stdout" \
            2>"${fixture_dir}/unknown.stderr"; then
        unknown_reject=1
    fi

    if [[ "${relative_accept}" -ne 1 || "${absolute_accept}" -ne 1 ||
          "${parent_escape_reject}" -ne 1 || "${project_root_reject}" -ne 1 ||
          "${duplicate_reject}" -ne 1 || "${missing_reject}" -ne 1 ||
          "${unknown_reject}" -ne 1 ]]; then
        self_test_rc=1
    fi
    if ! rm -rf -- "${fixture_dir}"; then
        self_test_rc=1
    fi
    {
        printf 'relative_path_accept=%d expected=1\n' "${relative_accept}"
        printf 'absolute_path_accept=%d expected=1\n' "${absolute_accept}"
        printf 'parent_escape_reject=%d expected=1\n' "${parent_escape_reject}"
        printf 'project_root_reject=%d expected=1\n' "${project_root_reject}"
        printf 'duplicate_reject=%d expected=1\n' "${duplicate_reject}"
        printf 'missing_reject=%d expected=1\n' "${missing_reject}"
        printf 'unknown_reject=%d expected=1\n' "${unknown_reject}"
        printf 'source_parser_self_test_rc=%d\n' "${self_test_rc}"
        if [[ "${self_test_rc}" -eq 0 ]]; then
            printf 'source_parser_self_test=PASS\n'
        else
            printf 'source_parser_self_test=FAIL\n'
        fi
    } >"${SOURCE_PARSER_SELF_TEST_LOG}"
    return "${self_test_rc}"
}

forbidden_audit_pattern() {
    local option_assert='--'"assert"'([[:space:]]|$)'
    local option_trace='--'"trace([[:space:]]|$)"
    local option_trace_fst='--'"trace-fst([[:space:]]|$)"
    local option_coverage='--'"coverage([[:space:]]|$)"
    local macro_trace='VM_'"TRACE[[:space:]]*=[[:space:]]*1"
    local hdl_dump='\$'"dump(file|vars)"
    local hdl_assert='\b'"assert[[:space:]]*\("
    printf '%s|%s|%s|%s|%s|%s|%s\n' \
        "${option_assert}" "${option_trace}" "${option_trace_fst}" \
        "${option_coverage}" "${macro_trace}" "${hdl_dump}" \
        "${hdl_assert}"
}

forbidden_audit_scan() {
    local scan_pattern
    scan_pattern="$(forbidden_audit_pattern)"
    grep -En -- "${scan_pattern}" "$@"
}

run_forbidden_audit_self_test() {
    local fixture_dir="${COMPILER_TMP_ROOT}/forbidden-audit-self-test"
    local attempt03_config="${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.config"
    local attempt03_verfiles="${ATTEMPT03_BUILD_ROOT}/tb_unary_glu_element/Vtb_unary_glu_element__verFiles.dat"
    local clean_accept=0
    local option_assert_reject=0
    local option_trace_reject=0
    local option_coverage_reject=0
    local macro_trace_reject=0
    local runner_zero_match=0
    local real_object_set_zero_match=0
    local scan_rc=0
    local self_test_rc=0
    local dirty_assert='--'"assert"
    local dirty_trace='--'"trace"
    local dirty_coverage='--'"coverage"
    local dirty_macro='VM_'"TRACE=1"
    local -a real_objects=(
        "${RUNNER_PATH}"
        "${PROJECT_ROOT}/rtl/TensorNpuUnaryGluElement.v"
        "${PROJECT_ROOT}/tests/tb_unary_glu_element.sv"
        "${attempt03_config}"
        "${attempt03_verfiles}"
    )

    [[ ! -e "${fixture_dir}" ]] \
        || die "forbidden audit fixture already exists: ${fixture_dir}"
    for real_object in "${real_objects[@]}"; do
        [[ -f "${real_object}" ]] \
            || die "forbidden audit self-test object missing: ${real_object}"
    done
    mkdir -- "${fixture_dir}"
    printf 'assertions=off\nVM_TRACE=0\n--timing\n' >"${fixture_dir}/clean.txt"
    if forbidden_audit_scan "${fixture_dir}/clean.txt" \
            >"${fixture_dir}/clean.scan" 2>&1; then
        clean_accept=0
    else
        scan_rc=$?
        [[ "${scan_rc}" -eq 1 ]] && clean_accept=1
    fi

    printf '%s\n' "${dirty_assert}" >"${fixture_dir}/option-assert.txt"
    if forbidden_audit_scan "${fixture_dir}/option-assert.txt" \
            >"${fixture_dir}/option-assert.scan" 2>&1; then
        option_assert_reject=1
    fi
    printf '%s\n' "${dirty_trace}" >"${fixture_dir}/option-trace.txt"
    if forbidden_audit_scan "${fixture_dir}/option-trace.txt" \
            >"${fixture_dir}/option-trace.scan" 2>&1; then
        option_trace_reject=1
    fi
    printf '%s\n' "${dirty_coverage}" >"${fixture_dir}/option-coverage.txt"
    if forbidden_audit_scan "${fixture_dir}/option-coverage.txt" \
            >"${fixture_dir}/option-coverage.scan" 2>&1; then
        option_coverage_reject=1
    fi
    printf '%s\n' "${dirty_macro}" >"${fixture_dir}/macro-trace.txt"
    if forbidden_audit_scan "${fixture_dir}/macro-trace.txt" \
            >"${fixture_dir}/macro-trace.scan" 2>&1; then
        macro_trace_reject=1
    fi

    if forbidden_audit_scan "${RUNNER_PATH}" \
            >"${fixture_dir}/runner.scan" 2>&1; then
        runner_zero_match=0
    else
        scan_rc=$?
        [[ "${scan_rc}" -eq 1 ]] && runner_zero_match=1
    fi
    if forbidden_audit_scan "${real_objects[@]}" \
            >"${fixture_dir}/real-objects.scan" 2>&1; then
        real_object_set_zero_match=0
    else
        scan_rc=$?
        [[ "${scan_rc}" -eq 1 ]] && real_object_set_zero_match=1
    fi

    if [[ "${clean_accept}" -ne 1 || "${option_assert_reject}" -ne 1 ||
          "${option_trace_reject}" -ne 1 ||
          "${option_coverage_reject}" -ne 1 ||
          "${macro_trace_reject}" -ne 1 || "${runner_zero_match}" -ne 1 ||
          "${real_object_set_zero_match}" -ne 1 ]]; then
        self_test_rc=1
    fi
    if ! rm -rf -- "${fixture_dir}"; then
        self_test_rc=1
    fi
    {
        printf 'clean_accept=%d expected=1\n' "${clean_accept}"
        printf 'option_assert_reject=%d expected=1\n' "${option_assert_reject}"
        printf 'option_trace_reject=%d expected=1\n' "${option_trace_reject}"
        printf 'option_coverage_reject=%d expected=1\n' \
            "${option_coverage_reject}"
        printf 'macro_trace_reject=%d expected=1\n' "${macro_trace_reject}"
        printf 'runner_zero_match=%d expected=1\n' "${runner_zero_match}"
        printf 'real_object_set_zero_match=%d expected=1\n' \
            "${real_object_set_zero_match}"
        printf 'forbidden_audit_self_test_rc=%d\n' "${self_test_rc}"
        if [[ "${self_test_rc}" -eq 0 ]]; then
            printf 'forbidden_audit_self_test=PASS\n'
        else
            printf 'forbidden_audit_self_test=FAIL\n'
        fi
    } >"${FORBIDDEN_AUDIT_SELF_TEST_LOG}"
    return "${self_test_rc}"
}

if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
    mkdir -p -- \
        "${BUILD_ROOT}" \
        "${LOG_ROOT}" \
        "${CACHE_ROOT}" \
        "${COMPILER_TMP_ROOT}"
fi

if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    case "${1:-}" in
        -h|--help)
            cat <<'EOF'
Usage:
  run_npu_regression.sh
  run_npu_regression.sh --legacy-forensic [legacy-option]

The default runs the complete current RTL test plan from source once, using a
fresh build/log/cache directory. Native Verilator and test-binary return codes plus
the tests' PASS/FAIL markers decide the result. It does not replay verifier
self-tests, adopt historical binaries, publish receipts, or seal hashes.

--legacy-forensic exposes the former recovery/self-test modes for an explicit
historical investigation; those modes are not ordinary regression gates.
EOF
            exit 0
            ;;
        '') ;;
        *)
            die "unsupported argument: $1 (legacy modes require --legacy-forensic)"
            ;;
    esac
else
case "${1:-}" in
    --marker-oracle-self-test)
        [[ "$#" -eq 1 ]] || die 'marker oracle self-test accepts no extra arguments'
        run_marker_oracle_self_test \
            || die "marker oracle self-test failed: ${MARKER_ORACLE_SELF_TEST_LOG}"
        printf '[NPU-REGRESSION-MARKER-ORACLE-SELFTEST][PASS]\n'
        exit 0
        ;;
    --source-parser-self-test)
        [[ "$#" -eq 1 ]] || die 'source parser self-test accepts no extra arguments'
        run_source_parser_self_test \
            || die "source parser self-test failed: ${SOURCE_PARSER_SELF_TEST_LOG}"
        printf '[NPU-REGRESSION-SOURCE-PARSER-SELFTEST][PASS]\n'
        exit 0
        ;;
    --forbidden-audit-self-test)
        [[ "$#" -eq 1 ]] || die 'forbidden audit self-test accepts no extra arguments'
        run_forbidden_audit_self_test \
            || die "forbidden audit self-test failed: ${FORBIDDEN_AUDIT_SELF_TEST_LOG}"
        printf '[NPU-REGRESSION-FORBIDDEN-AUDIT-SELFTEST][PASS]\n'
        exit 0
        ;;
    --repair-composite-attempt-02)
        [[ "$#" -eq 1 ]] || die 'repair composite accepts no extra arguments'
        RUN_MODE='repair-composite-attempt-02'
        REPAIR_COMPOSITE=1
        ;;
    --seal-existing-attempt-03)
        [[ "$#" -eq 1 ]] || die 'seal existing accepts no extra arguments'
        RUN_MODE='seal-existing-attempt-03'
        REPAIR_COMPOSITE=1
        SEAL_EXISTING=1
        ;;
    '')
        ;;
    *)
        die "unsupported argument: $1"
        ;;
esac
fi

if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    mkdir -p -- \
        "${BUILD_ROOT}" \
        "${LOG_ROOT}" \
        "${CACHE_ROOT}" \
        "${COMPILER_TMP_ROOT}"
fi

if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
    [[ -f "${TASK_RUN_STATUS_HELPER}" ]] \
        || die "missing task-run status helper: ${TASK_RUN_STATUS_HELPER}"
    # shellcheck source=/dev/null
    source "${TASK_RUN_STATUS_HELPER}"
else
    # run_test uses stage labels for the opt-in forensic implementation.  In
    # the ordinary path they are informational no-ops, not permission gates.
    task_run_status_stage() { :; }
fi

RUNNER_CLEANUP_DONE=0

cleanup_transients() {
    local cleanup_rc=0
    local cache_entry=""
    local compiler_entry=""

    if [[ "${CACHE_ROOT}" != "${PROJECT_ROOT}/tmp/cache/npu-regression-v33" ||
          "${COMPILER_TMP_ROOT}" != "${PROJECT_ROOT}/tmp/compiler/npu-regression-v33" ]]; then
        printf 'cleanup_result=FAIL reason=canonical-path-mismatch\n' \
            >"${CLEANUP_AUDIT_PATH}"
        return 1
    fi

    rm -rf -- "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" || cleanup_rc=$?
    if [[ "${cleanup_rc}" -eq 0 ]]; then
        mkdir -p -- "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" || cleanup_rc=$?
    fi
    if [[ "${cleanup_rc}" -eq 0 ]]; then
        cache_entry="$(find "${CACHE_ROOT}" -mindepth 1 -print -quit)"
        compiler_entry="$(find "${COMPILER_TMP_ROOT}" -mindepth 1 -print -quit)"
        if [[ -n "${cache_entry}" || -n "${compiler_entry}" ]]; then
            cleanup_rc=1
        fi
    fi

    {
        printf 'cache_root=%s\n' "${CACHE_ROOT}"
        printf 'compiler_tmp_root=%s\n' "${COMPILER_TMP_ROOT}"
        printf 'cache_entries_after_cleanup=%s\n' "$([[ -z "${cache_entry}" ]] && printf 0 || printf 1)"
        printf 'compiler_entries_after_cleanup=%s\n' "$([[ -z "${compiler_entry}" ]] && printf 0 || printf 1)"
        printf 'cleanup_rc=%d\n' "${cleanup_rc}"
        if [[ "${cleanup_rc}" -eq 0 ]]; then
            printf 'cleanup_result=PASS\n'
        else
            printf 'cleanup_result=FAIL\n'
        fi
    } >"${CLEANUP_AUDIT_PATH}"

    if [[ "${cleanup_rc}" -eq 0 ]]; then
        RUNNER_CLEANUP_DONE=1
    fi
    return "${cleanup_rc}"
}

finish_runner() {
    local command_rc=$?
    local cleanup_rc=0
    local final_rc=0

    trap - EXIT HUP INT TERM
    set +e
    if [[ "${RUNNER_CLEANUP_DONE}" -ne 1 ]]; then
        cleanup_transients
        cleanup_rc=$?
    fi
    task_run_status_finalize "${command_rc}" "${cleanup_rc}"
    final_rc=$?
    exit "${final_rc}"
}

if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
    task_run_status_init "${STATUS_PATH}"
    trap finish_runner EXIT
    task_run_status_install_signal_traps
    task_run_status_stage environment-check
fi

required_tools=(realpath mkdir sed verilator timeout grep awk)
if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
    required_tools+=(sha256sum cmp sort find rm bash)
fi
for required_tool in "${required_tools[@]}"; do
    command -v "${required_tool}" >/dev/null 2>&1 \
        || die "required tool not found: ${required_tool}"
done

[[ "${RUN_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]] \
    || die 'NPU_REGRESSION_TIMEOUT_SECONDS must be a positive integer'
[[ "${FIRST_BATCH_RUN_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]] \
    || die 'NPU_FIRST_BATCH_REGRESSION_TIMEOUT_SECONDS must be a positive integer'
[[ "${BATCH2_RUN_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]] \
    || die 'NPU_BATCH2_REGRESSION_TIMEOUT_SECONDS must be a positive integer'

export TMPDIR="${COMPILER_TMP_ROOT}"
export TMP="${COMPILER_TMP_ROOT}"
export TEMP="${COMPILER_TMP_ROOT}"
export XDG_CACHE_HOME="${CACHE_ROOT}"
export CCACHE_DISABLE=1

cd -- "${PROJECT_ROOT}"

file_sha256() {
    local hash_line
    hash_line="$(sha256sum -- "$1")"
    printf '%s\n' "${hash_line%% *}"
}

adopt_attempt02_legacy_test() {
    local test_name="$1"
    local pass_marker="$2"
    shift 2
    local -a sources=("$@")
    local source_file
    local build_dir="${ATTEMPT02_BUILD_ROOT}/${test_name}"
    local build_log="${ATTEMPT02_LOG_ROOT}/${test_name}.build.log"
    local build_rc_path="${ATTEMPT02_LOG_ROOT}/${test_name}.build.rc"
    local run_log="${ATTEMPT02_LOG_ROOT}/${test_name}.run.log"
    local run_rc_path="${ATTEMPT02_LOG_ROOT}/${test_name}.run.rc"
    local binary_path="${build_dir}/V${test_name}"
    local verfiles_path="${build_dir}/V${test_name}__verFiles.dat"
    local makefile_path="${build_dir}/V${test_name}.mk"
    local pass_count
    local fail_count
    local build_rc_value
    local run_rc_value
    local required_artifact

    [[ "$(realpath -m -- "${build_dir}")" == "${ATTEMPT02_BUILD_ROOT}/"* ]] \
        || die "${test_name}: archived build path escaped attempt-02"
    [[ "$(realpath -m -- "${run_log}")" == "${ATTEMPT02_LOG_ROOT}/"* ]] \
        || die "${test_name}: archived log path escaped attempt-02"
    for required_artifact in \
        "${build_log}" "${build_rc_path}" "${run_log}" "${run_rc_path}" \
        "${binary_path}" "${verfiles_path}" "${makefile_path}"; do
        [[ -f "${required_artifact}" ]] \
            || die "${test_name}: missing attempt-02 artifact ${required_artifact}"
    done
    [[ -x "${binary_path}" ]] \
        || die "${test_name}: attempt-02 binary is not executable"

    build_rc_value="$(sed -n '1p' "${build_rc_path}")"
    run_rc_value="$(sed -n '1p' "${run_rc_path}")"
    pass_count="$(count_pass_marker \
        "${test_name}" "${pass_marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    if [[ "${build_rc_value}" != 0 || "${run_rc_value}" != 0 ||
          "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ]]; then
        die "${test_name}: attempt-02 legacy evidence is not a clean PASS"
    fi
    if ! grep -Fq -- '--binary --timing --sv -O3 -Wall -Wno-fatal' \
            "${verfiles_path}" ||
       ! grep -Fq -- '-O3 -DNDEBUG -march=native' "${verfiles_path}" ||
       ! grep -Fq -- '-O3 -DNDEBUG -march=native' "${makefile_path}"; then
        die "${test_name}: attempt-02 generated configuration identity mismatch"
    fi

    for source_file in "${sources[@]}"; do
        [[ "${source_file}" != tests/tb_unary_glu_element.sv ]] \
            || die "${test_name}: repair legacy filelist unexpectedly uses Unary TB"
        if [[ "${SEAL_EXISTING}" -ne 1 ]]; then
            printf '%s  %s test=%s\n' \
                "$(file_sha256 "${source_file}")" \
                "${source_file}" "${test_name}" \
                >>"${REPAIR_LEGACY_SOURCE_PRE}"
        elif ! grep -Fxq -- \
                "$(file_sha256 "${source_file}")  ${source_file} test=${test_name}" \
                "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}" ||
             ! grep -Fxq -- \
                "$(file_sha256 "${source_file}")  ${source_file} test=${test_name}" \
                "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}"; then
            die "${test_name}: current legacy source hash differs ${source_file}"
        fi
        REPAIR_LEGACY_SOURCE_PATHS+=("${source_file}")
        REPAIR_LEGACY_SOURCE_TESTS+=("${test_name}")
    done

    LEGACY_BOUND_ARTIFACTS+=(
        "${build_log}"
        "${build_rc_path}"
        "${run_log}"
        "${run_rc_path}"
        "${binary_path}"
        "${verfiles_path}"
        "${makefile_path}"
    )
    EXECUTED_TESTS+=("${test_name}")
    EXECUTED_MARKERS+=("${pass_marker}")
    EXECUTED_BUILD_RCS+=("${build_rc_path}")
    EXECUTED_RUN_LOGS+=("${run_log}")
    EXECUTED_RUN_RCS+=("${run_rc_path}")
    EXECUTED_ORIGINS+=("attempt-02-archive")
    LEGACY_ADOPTED_COUNT=$((LEGACY_ADOPTED_COUNT + 1))
    printf '[NPU-REGRESSION][ADOPTED-PASS] %s origin=%s marker=%s\n' \
        "${test_name}" "${ATTEMPT02_NAME}" "${pass_marker}"
}

adopt_attempt03_unary_test() {
    local test_name="$1"
    local pass_marker="$2"
    shift 2
    local -a sources=("$@")
    local source_file
    local build_dir="${ATTEMPT03_BUILD_ROOT}/${test_name}"
    local build_log="${ATTEMPT03_LOG_ROOT}/${test_name}.build.log"
    local build_rc_path="${ATTEMPT03_LOG_ROOT}/${test_name}.build.rc"
    local run_log="${ATTEMPT03_LOG_ROOT}/${test_name}.run.log"
    local run_rc_path="${ATTEMPT03_LOG_ROOT}/${test_name}.run.rc"
    local binary_path="${build_dir}/V${test_name}"
    local verfiles_path="${build_dir}/V${test_name}__verFiles.dat"
    local makefile_path="${build_dir}/V${test_name}.mk"
    local config_path="${ATTEMPT03_LOG_ROOT}/${test_name}.config"
    local filelist_path="${ATTEMPT03_LOG_ROOT}/${test_name}.compile-filelist"
    local required_artifact
    local pass_count
    local fail_count
    local build_rc_value
    local run_rc_value

    [[ "${test_name}" == tb_unary_glu_element ]] \
        || die "attempt-03 adoption is restricted to tb_unary_glu_element"
    for required_artifact in \
        "${build_log}" "${build_rc_path}" "${run_log}" "${run_rc_path}" \
        "${binary_path}" "${verfiles_path}" "${makefile_path}" \
        "${config_path}" "${filelist_path}"; do
        [[ -f "${required_artifact}" ]] \
            || die "${test_name}: missing attempt-03 artifact ${required_artifact}"
    done
    [[ -x "${binary_path}" ]] \
        || die "${test_name}: attempt-03 binary is not executable"
    build_rc_value="$(sed -n '1p' "${build_rc_path}")"
    run_rc_value="$(sed -n '1p' "${run_rc_path}")"
    pass_count="$(count_pass_marker \
        "${test_name}" "${pass_marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    if [[ "${build_rc_value}" != 0 || "${run_rc_value}" != 0 ||
          "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ]]; then
        die "${test_name}: attempt-03 Unary evidence is not a clean PASS"
    fi
    if ! cmp -s -- "${filelist_path}" <(printf '%s\n' "${sources[@]}"); then
        die "${test_name}: attempt-03 compile filelist identity mismatch"
    fi
    for source_file in "${sources[@]}"; do
        [[ -f "${source_file}" ]] \
            || die "${test_name}: current source missing ${source_file}"
    done

    EXECUTED_TESTS+=("${test_name}")
    EXECUTED_MARKERS+=("${pass_marker}")
    EXECUTED_BUILD_RCS+=("${build_rc_path}")
    EXECUTED_RUN_LOGS+=("${run_log}")
    EXECUTED_RUN_RCS+=("${run_rc_path}")
    EXECUTED_ORIGINS+=("attempt-03-unary")
    ATTEMPT03_ADOPTED_COUNT=$((ATTEMPT03_ADOPTED_COUNT + 1))
    printf '[NPU-REGRESSION][ADOPTED-PASS] %s origin=%s marker=%s\n' \
        "${test_name}" "${ATTEMPT03_NAME}" "${pass_marker}"
}

run_test() {
    local test_name="$1"
    local pass_marker="$2"
    shift 2
    local -a sources=("$@")
    local source_file
    local build_dir
    local build_log
    local run_log
    local config_path
    local filelist_path
    local warning_count_path
    local binary_name
    local binary_path
    local build_rc
    local run_rc
    local pass_count
    local fail_count
    local warning_count
    local config_index
    local run_timeout_seconds="${RUN_TIMEOUT_SECONDS}"
    local -a warning_flags=()
    local -a include_flags=(-Irtl)
    local -a verilator_args=()

    # The pinned fpu-sp sources are linted by their upstream Verilator flow
    # with these four warning classes disabled.  Keep the exception scoped to
    # test binaries that actually elaborate the vendored FPU.  Every test that
    # uses only project-owned RTL still receives the unsuppressed -Wall set.
    case "${test_name}" in
        tb_coprocessor|tb_coprocessor_q8_get_rows|tb_coprocessor_q8_gemv|tb_coprocessor_q8_gemv_portal|tb_coprocessor_f32_gather_repeat|tb_coprocessor_unary_norm_sum_ssm|tb_coprocessor_mover_attention_softmax_rope|tb_fp32_addmul|tb_fp32_div|tb_fp32_sqrt|tb_fp32_to_int32_rmm|tb_f32_alu_simd_core|tb_q8_scale_accumulator|tb_q8_reference_quantizer|tb_q8_stream_gemv|tb_q8_row_simd_core|tb_q8_gemv_portal_adapter|tb_q8_dequant_block|tb_q8_get_rows_engine|tb_q8_get_rows_writeback_adapter|tb_q8_gemv_writeback_adapter|tb_ssm_conv_writeback_adapter|tb_f16_attention_matmul_writeback_adapter|tb_rope_writeback_adapter)
            warning_flags=(
                -Wno-UNOPTFLAT
                -Wno-IMPORTSTAR
                -Wno-UNUSEDPARAM
                -Wno-UNUSEDSIGNAL
                -Wno-GENUNNAMED
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-WIDTH
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_fp32_to_fp64|tb_fp64_add|tb_fp64_to_fp32|tb_fp64_to_int32_rmm|tb_int32_to_fp64|tb_sum_rows_writeback_adapter)
            # Berkeley HardFloat Release 1 is a pinned, unmodified Verilog-2001
            # vendor source.  Its project-wrapper directed builds retain -Wall
            # and prove the six new RTL/TB files warning-clean.  Suppress only
            # the six audited upstream categories in the aggregate regression
            # so the canonical logs remain machine-clean.
            warning_flags=(
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-GENUNNAMED
                -Wno-WIDTH
                -Wno-UNUSEDSIGNAL
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_fp64_fma)
            # The FMA slice adds HardFloat mulAddRecFN.  Its directed build
            # proves the project wrapper/TB warning-clean and retains the two
            # upstream HardFloat_localFuncs.vi VARHIDDEN diagnostics.  Keep
            # that audited vendor-only category out of the aggregate log.
            warning_flags=(
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-GENUNNAMED
                -Wno-WIDTH
                -Wno-UNUSEDSIGNAL
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_fp64_to_fp32_finite|tb_aor_exp32|tb_aor_log32)
            # The AOR directed v2 receipt proves every project-owned RTL/TB
            # warning-clean under unsuppressed -Wall and retains only pinned
            # HardFloat Release 1 diagnostics.  Keep those audited vendor
            # categories out of the aggregate machine-clean regression log.
            warning_flags=(
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-GENUNNAMED
                -Wno-WIDTH
                -Wno-UNUSEDSIGNAL
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_fp32_square_sum64)
            # This integration slice elaborates both pinned arithmetic
            # libraries.  Unsuppressed directed builds already prove the new
            # parent RTL/TB warning-clean; keep only audited vendor/legacy
            # adapter categories out of the aggregate machine-clean log.
            warning_flags=(
                -Wno-UNOPTFLAT
                -Wno-IMPORTSTAR
                -Wno-UNUSEDPARAM
                -Wno-UNUSEDSIGNAL
                -Wno-GENUNNAMED
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-WIDTH
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_norm_engine|tb_norm_writeback_adapter)
            # The norm parent elaborates both pinned arithmetic libraries.
            # Directed source-scoped builds prove project RTL/TB warning-clean;
            # keep only audited vendor/legacy diagnostics out of this aggregate
            # machine-clean log.
            warning_flags=(
                -Wno-UNOPTFLAT
                -Wno-IMPORTSTAR
                -Wno-UNUSEDPARAM
                -Wno-UNUSEDSIGNAL
                -Wno-GENUNNAMED
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-WIDTH
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
        tb_unary_glu_element|tb_unary_glu_writeback_adapter|tb_softmax_writeback_adapter)
            # 完整Unary/GLU层级同时elaborate pinned fpu-sp与HardFloat。
            # project-owned TB/parent warning由末尾的路径定向审计单独拒绝。
            warning_flags=(
                -Wno-UNOPTFLAT
                -Wno-IMPORTSTAR
                -Wno-UNUSEDPARAM
                -Wno-UNUSEDSIGNAL
                -Wno-GENUNNAMED
                -Wno-DECLFILENAME
                -Wno-TIMESCALEMOD
                -Wno-WIDTH
                -Wno-VARHIDDEN
            )
            include_flags+=(
                -Ithird_party/hardfloat/source/RISCV
                -Ithird_party/hardfloat/source
            )
            ;;
    esac

    for source_file in "${sources[@]}"; do
        [[ -f "${PROJECT_ROOT}/${source_file}" ]] \
            || die "${test_name}: missing source ${source_file}"
    done

    if [[ "${REPAIR_COMPOSITE}" -eq 1 &&
          "${test_name}" != tb_unary_glu_element ]]; then
        adopt_attempt02_legacy_test \
            "${test_name}" "${pass_marker}" "${sources[@]}"
        return
    fi
    if [[ "${SEAL_EXISTING}" -eq 1 &&
          "${test_name}" == tb_unary_glu_element ]]; then
        adopt_attempt03_unary_test \
            "${test_name}" "${pass_marker}" "${sources[@]}"
        return
    fi

    build_dir="$(project_tmp_path "${BUILD_ROOT}/${test_name}")"
    build_log="$(project_tmp_path "${LOG_ROOT}/${test_name}.build.log")"
    run_log="$(project_tmp_path "${LOG_ROOT}/${test_name}.run.log")"
    config_path="$(project_tmp_path "${LOG_ROOT}/${test_name}.command")"
    filelist_path="$(project_tmp_path "${LOG_ROOT}/${test_name}.compile-filelist")"
    warning_count_path="$(project_tmp_path "${LOG_ROOT}/${test_name}.warnings.count")"
    binary_name="V${test_name}"
    binary_path="$(project_tmp_path "${build_dir}/${binary_name}")"
    if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
        [[ ! -e "${build_dir}" ]] \
            || die "${test_name}: stale build directory exists: ${build_dir}"
        [[ ! -e "${build_log}" && ! -e "${run_log}" ]] \
            || die "${test_name}: stale build/run log exists"
        mkdir -- "${build_dir}"
    else
        mkdir -p -- "${build_dir}"
    fi

    verilator_args=(
        --binary
        --timing
        --sv
        -O3
        -Wall
        -Wno-fatal
        --no-assert
        --no-trace
        "${warning_flags[@]}"
        -CFLAGS "-O3 -DNDEBUG -march=native"
        "${include_flags[@]}"
        --Mdir "${build_dir}"
        --top-module "${test_name}"
        "${sources[@]}"
        -o "${binary_name}"
    )

    if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
        printf '%s\n' "${sources[@]}" >"${filelist_path}"
        printf '%q ' verilator "${verilator_args[@]}" >"${config_path}"
        printf '\n' >>"${config_path}"
    fi

    if [[ "${test_name}" == tb_unary_glu_element ]]; then
        {
            printf 'schema=npu-regression-verilator-config-v1\n'
            printf 'test=%s\n' "${test_name}"
            printf 'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal\n'
            printf 'cflags=-O3 -DNDEBUG -march=native\n'
            printf 'assertions=off\n'
            printf 'waveform=off\n'
            printf 'optimization=O3\n'
            printf 'arg_count=%d\n' "${#verilator_args[@]}"
            for ((config_index = 0;
                  config_index < ${#verilator_args[@]};
                  config_index = config_index + 1)); do
                printf 'arg[%d]=%s\n' \
                    "${config_index}" "${verilator_args[config_index]}"
            done
        } >"${UNARY_CONFIG_PATH}"
    fi

    printf '[NPU-REGRESSION] build %s\n' "${test_name}"
    task_run_status_stage "build-${test_name}"
    VERILATOR_EXECUTION_COUNT=$((VERILATOR_EXECUTION_COUNT + 1))
    if verilator "${verilator_args[@]}" >"${build_log}" 2>&1; then
        build_rc=0
    else
        build_rc=$?
    fi
    printf '%d\n' "${build_rc}" >"${LOG_ROOT}/${test_name}.build.rc"
    if [[ "${build_rc}" -ne 0 ]]; then
        printf '[NPU-REGRESSION][FAIL] %s build rc=%d log=%s\n' \
            "${test_name}" "${build_rc}" "${build_log}" >&2
        sed -n '1,240p' "${build_log}" >&2
        exit "${build_rc}"
    fi

    if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
        warning_count="$(grep -Eic -- \
            '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
            "${build_log}" || true)"
        printf '%s\n' "${warning_count}" >"${warning_count_path}"
        if [[ "${warning_count}" -ne 0 ]]; then
            printf '[NPU-REGRESSION][FAIL] %s unexpected_diagnostics=%s log=%s\n' \
                "${test_name}" "${warning_count}" "${build_log}" >&2
            sed -n '1,240p' "${build_log}" >&2
            exit 1
        fi
    fi

    [[ -x "${binary_path}" ]] \
        || die "${test_name}: build succeeded but binary is missing: ${binary_path}"

    if [[ "${test_name}" == tb_coprocessor_unary_norm_sum_ssm ]]; then
        run_timeout_seconds="${FIRST_BATCH_RUN_TIMEOUT_SECONDS}"
    fi
    if [[ "${test_name}" == tb_coprocessor_mover_attention_softmax_rope ]]; then
        printf '[NPU-REGRESSION] run %s groups=4 timeout_each=%ss\n' \
            "${test_name}" "${BATCH2_RUN_TIMEOUT_SECONDS}"
    else
        printf '[NPU-REGRESSION] run %s timeout=%ss\n' \
            "${test_name}" "${run_timeout_seconds}"
    fi
    task_run_status_stage "run-${test_name}"
    ulimit -c 0
    TB_BINARY_EXECUTION_COUNT=$((TB_BINARY_EXECUTION_COUNT + 1))
    if [[ "${test_name}" == tb_coprocessor_mover_attention_softmax_rope ]]; then
        local batch2_group batch2_status batch2_marker_count
        local batch2_profile_count batch2_failure_count batch2_bitmap
        local batch2_failed=0 batch2_aggregate=0
        local -a batch2_expected_bitmap=(01ff 0200 0400 3800)
        local -a batch2_expected_profiles=(9 1 1 3)
        local -a batch2_pids=()
        local -a batch2_logs=()

        for batch2_group in 0 1 2 3; do
            batch2_logs[batch2_group]="$(project_tmp_path \
                "${LOG_ROOT}/${test_name}.group${batch2_group}.run.log")"
            timeout \
                --signal=TERM \
                --kill-after=2s \
                "${BATCH2_RUN_TIMEOUT_SECONDS}s" \
                "${binary_path}" "+GROUP=${batch2_group}" \
                >"${batch2_logs[batch2_group]}" 2>&1 &
            batch2_pids[batch2_group]=$!
        done

        : >"${run_log}"
        printf 'group\texit\tmarker\tprofiles\tfailure_text\n' \
            >"${LOG_ROOT}/${test_name}.groups.tsv"
        for batch2_group in 0 1 2 3; do
            if wait "${batch2_pids[batch2_group]}"; then
                batch2_status=0
            else
                batch2_status=$?
            fi
            batch2_marker_count="$(grep -Fc -- \
                "[NPU-COPROC-BATCH2][GROUP-PASS] group=${batch2_group} profile_bitmap=${batch2_expected_bitmap[batch2_group]}" \
                "${batch2_logs[batch2_group]}" || true)"
            batch2_profile_count="$(grep -Fc -- \
                '[NPU-COPROC-BATCH2][PROFILE-PASS]' \
                "${batch2_logs[batch2_group]}" || true)"
            batch2_failure_count="$(grep -Ec -- \
                '\[FAIL\]|%Error|%Fatal' \
                "${batch2_logs[batch2_group]}" || true)"
            printf '%s\t%s\t%s\t%s\t%s\n' \
                "${batch2_group}" "${batch2_status}" \
                "${batch2_marker_count}" "${batch2_profile_count}" \
                "${batch2_failure_count}" \
                >>"${LOG_ROOT}/${test_name}.groups.tsv"
            printf '[NPU-REGRESSION][BATCH2-GROUP] group=%s exit=%s marker=%s profiles=%s failures=%s\n' \
                "${batch2_group}" "${batch2_status}" \
                "${batch2_marker_count}" "${batch2_profile_count}" \
                "${batch2_failure_count}" >>"${run_log}"
            cat -- "${batch2_logs[batch2_group]}" >>"${run_log}"
            if [[ "${batch2_status}" -ne 0 ||
                  "${batch2_marker_count}" -ne 1 ||
                  "${batch2_profile_count}" -ne \
                      "${batch2_expected_profiles[batch2_group]}" ||
                  "${batch2_failure_count}" -ne 0 ]]; then
                batch2_failed=1
            else
                batch2_bitmap="${batch2_expected_bitmap[batch2_group]}"
                batch2_aggregate=$((batch2_aggregate | 16#${batch2_bitmap}))
            fi
        done
        if [[ "${batch2_failed}" -eq 0 &&
              "${batch2_aggregate}" -eq 16383 ]]; then
            printf '[NPU-COPROC-BATCH2][PASS] frozen_nodes=144 exact_profiles=14 mover=7 set_rows=2 attention=2 softmax=1 rope=2 static=8 late=2 timeout_drain=1 identity_backpressure=2 single_outstanding=1 host_float=0\n' \
                >>"${run_log}"
            run_rc=0
        else
            printf '[NPU-REGRESSION][FAIL] %s aggregate_bitmap=%04x\n' \
                "${test_name}" "${batch2_aggregate}" >>"${run_log}"
            run_rc=1
        fi
    elif timeout \
        --signal=TERM \
        --kill-after=2s \
        "${run_timeout_seconds}s" \
        "${binary_path}" \
        >"${run_log}" 2>&1; then
        run_rc=0
    else
        run_rc=$?
    fi
    printf '%d\n' "${run_rc}" >"${LOG_ROOT}/${test_name}.run.rc"
    if [[ "${run_rc}" -ne 0 ]]; then
        printf '[NPU-REGRESSION][FAIL] %s run rc=%d log=%s\n' \
            "${test_name}" "${run_rc}" "${run_log}" >&2
        sed -n '1,240p' "${run_log}" >&2
        exit "${run_rc}"
    fi

    pass_count="$(count_pass_marker "${test_name}" "${pass_marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    if [[ "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ]]; then
        printf '[NPU-REGRESSION][FAIL] %s marker_count=%s fail_count=%s marker=%s log=%s\n' \
            "${test_name}" "${pass_count}" "${fail_count}" \
            "${pass_marker}" "${run_log}" >&2
        sed -n '1,240p' "${run_log}" >&2
        exit 1
    fi

    EXECUTED_TESTS+=("${test_name}")
    EXECUTED_MARKERS+=("${pass_marker}")
    EXECUTED_BUILD_RCS+=("${LOG_ROOT}/${test_name}.build.rc")
    EXECUTED_RUN_LOGS+=("${run_log}")
    EXECUTED_RUN_RCS+=("${LOG_ROOT}/${test_name}.run.rc")
    EXECUTED_ORIGINS+=("current-run")
    printf '[NPU-REGRESSION][PASS] %s marker=%s\n' \
        "${test_name}" "${pass_marker}"
}

EXECUTED_TESTS=()
EXECUTED_MARKERS=()
EXECUTED_BUILD_RCS=()
EXECUTED_RUN_LOGS=()
EXECUTED_RUN_RCS=()
EXECUTED_ORIGINS=()
LEGACY_BOUND_ARTIFACTS=()
REPAIR_LEGACY_SOURCE_PATHS=()
REPAIR_LEGACY_SOURCE_TESTS=()
LEGACY_ADOPTED_COUNT=0
ATTEMPT03_ADOPTED_COUNT=0
VERILATOR_EXECUTION_COUNT=0
TB_BINARY_EXECUTION_COUNT=0

if [[ "${LEGACY_FORENSIC}" -eq 1 ]]; then
task_run_status_stage source-freeze-pre
if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
    for required_archive_artifact in \
        "${ATTEMPT02_LOG_ROOT}/failure-summary.txt" \
        "${ATTEMPT02_LOG_ROOT}/task-run.status" \
        "${ATTEMPT02_LOG_ROOT}/run_npu_regression.sh.snapshot" \
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.sources.pre.sha256" \
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.log" \
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.rc"; do
        [[ -f "${required_archive_artifact}" ]] \
            || die "repair composite archive is incomplete: ${required_archive_artifact}"
    done
    if [[ "${SEAL_EXISTING}" -ne 1 ]]; then
        : >"${REPAIR_LEGACY_SOURCE_PRE}"
        : >"${REPAIR_LEGACY_SOURCE_POST}"
    fi
fi
for source_file in "${UNARY_GLU_MANIFEST_SOURCES[@]}"; do
    [[ -f "${source_file}" ]] || die "unary manifest source missing: ${source_file}"
done
[[ -f "${SOURCE_LOCK_PATH}" ]] || die "source lock is missing"
[[ -f "${PREBUILD_LOCK_LOG}" ]] || die "locked-input prebuild log is missing"

RUNNER_PRE_SHA256="$(file_sha256 "${RUNNER_PATH}")"
SOURCE_LOCK_PRE_SHA256="$(file_sha256 "${SOURCE_LOCK_PATH}")"
PREBUILD_LOG_PRE_SHA256="$(file_sha256 "${PREBUILD_LOCK_LOG}")"
ACTIVE_UNARY_FILELIST="${UNARY_FILELIST_PATH}"
ACTIVE_SOURCE_MANIFEST_PRE="${SOURCE_MANIFEST_PRE}"
ACTIVE_SOURCE_MANIFEST_POST="${SOURCE_MANIFEST_POST}"
ACTIVE_EXPECTED_PROJECT_SOURCES="${EXPECTED_PROJECT_SOURCES}"
ACTIVE_REPAIR_LEGACY_SOURCE_PRE="${REPAIR_LEGACY_SOURCE_PRE}"
ACTIVE_REPAIR_LEGACY_SOURCE_POST="${REPAIR_LEGACY_SOURCE_POST}"
EXECUTION_TEST_PLAN="${TEST_PLAN_PATH}"
EXECUTION_RUNNER_SHA256="${RUNNER_PRE_SHA256}"

if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
    ACTIVE_UNARY_FILELIST="${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.compile-filelist"
    ACTIVE_SOURCE_MANIFEST_PRE="${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.sources.pre.sha256"
    ACTIVE_SOURCE_MANIFEST_POST="${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.sources.post.sha256"
    ACTIVE_EXPECTED_PROJECT_SOURCES="${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.expected-project-sources.list"
    ACTIVE_REPAIR_LEGACY_SOURCE_PRE="${ATTEMPT03_LOG_ROOT}/repair-legacy-sources.pre.sha256"
    ACTIVE_REPAIR_LEGACY_SOURCE_POST="${ATTEMPT03_LOG_ROOT}/repair-legacy-sources.post.sha256"
    EXECUTION_TEST_PLAN="${ATTEMPT03_LOG_ROOT}/test-plan.log"
    for required_attempt03_artifact in \
        "${ATTEMPT03_LOG_ROOT}/failure-summary.txt" \
        "${ATTEMPT03_LOG_ROOT}/task-run.status" \
        "${ATTEMPT03_LOG_ROOT}/repair-composite.console.log" \
        "${ATTEMPT03_LOG_ROOT}/run_npu_regression.sh.snapshot" \
        "${ACTIVE_UNARY_FILELIST}" \
        "${ACTIVE_SOURCE_MANIFEST_PRE}" \
        "${ACTIVE_SOURCE_MANIFEST_POST}" \
        "${ACTIVE_EXPECTED_PROJECT_SOURCES}" \
        "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}" \
        "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}" \
        "${EXECUTION_TEST_PLAN}" \
        "${ATTEMPT04_LOG_ROOT}/failure-summary.txt" \
        "${ATTEMPT04_LOG_ROOT}/task-run.status" \
        "${ATTEMPT04_LOG_ROOT}/seal-existing.console.log" \
        "${ATTEMPT04_LOG_ROOT}/run_npu_regression.sh.snapshot" \
        "${ATTEMPT04_LOG_ROOT}/source-hash-audit.log" \
        "${ATTEMPT04_LOG_ROOT}/marker-audit.log" \
        "${ATTEMPT04_LOG_ROOT}/warning-audit.log" \
        "${ATTEMPT04_LOG_ROOT}/forbidden-audit.log"; do
        [[ -f "${required_attempt03_artifact}" ]] \
            || die "attempt-03 seal input is incomplete: ${required_attempt03_artifact}"
    done
    EXECUTION_RUNNER_SHA256="$(file_sha256 \
        "${ATTEMPT03_LOG_ROOT}/run_npu_regression.sh.snapshot")"
    if [[ "${EXECUTION_RUNNER_SHA256}" != \
          ec524d789375454d70c9c2e4bdf7e4cb804bb728230200af60371a086dba44e0 ]]; then
        die "attempt-03 execution runner identity mismatch"
    fi
    if ! cmp -s -- "${ACTIVE_SOURCE_MANIFEST_PRE}" \
            "${ACTIVE_SOURCE_MANIFEST_POST}"; then
        die "attempt-03 Unary source pre/post manifests differ"
    fi
    if ! cmp -s -- "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}" \
            "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}"; then
        die "attempt-03 legacy source pre/post manifests differ"
    fi
    if ! cmp -s -- "${ACTIVE_UNARY_FILELIST}" \
            <(printf '%s\n' "${UNARY_GLU_COMPILE_SOURCES[@]}"); then
        die "attempt-03 Unary compile filelist differs from current runner"
    fi
    if ! {
        sha256sum -c -- "${ACTIVE_SOURCE_MANIFEST_PRE}"
        sha256sum -c -- "${ACTIVE_SOURCE_MANIFEST_POST}"
    } >"${SEAL_SOURCE_CHECK}" 2>&1; then
        die "attempt-03 current Unary source hash check failed: ${SEAL_SOURCE_CHECK}"
    fi
    printf 'seal_source_check=PASS\n' >>"${SEAL_SOURCE_CHECK}"
else
    printf '%s\n' "${UNARY_GLU_COMPILE_SOURCES[@]}" >"${UNARY_FILELIST_PATH}"
    sha256sum -- "${UNARY_GLU_MANIFEST_SOURCES[@]}" >"${SOURCE_MANIFEST_PRE}"
    for source_file in "${UNARY_GLU_MANIFEST_SOURCES[@]}"; do
        realpath -- "${source_file}"
    done | LC_ALL=C sort -u >"${EXPECTED_PROJECT_SOURCES}"
fi

if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    [[ "${EXPECTED_TEST_COUNT}" -ge 35 ]] \
        || die "direct test plan count is ${EXPECTED_TEST_COUNT}, expected at least 35"
else
    [[ "${EXPECTED_TEST_COUNT}" -eq 33 ]] \
        || die "legacy test plan count is ${EXPECTED_TEST_COUNT}, expected 33"
fi
{
    printf 'schema=npu-regression-test-plan-v1\n'
    printf 'execution_mode=%s\n' "${RUN_MODE}"
    printf 'test_count=%d\n' "${#EXPECTED_TESTS[@]}"
    printf 'source_manifest_pre_sha256=%s\n' \
        "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_PRE}")"
    printf 'execution_runner_sha256=%s\n' "${EXECUTION_RUNNER_SHA256}"
    printf 'seal_runner_pre_sha256=%s\n' "${RUNNER_PRE_SHA256}"
    printf 'task_run_status_path=%s\n' "${STATUS_PATH}"
    for ((plan_index = 0;
          plan_index < ${#EXPECTED_TESTS[@]};
          plan_index = plan_index + 1)); do
        if [[ "${REPAIR_COMPOSITE}" -eq 1 && "${plan_index}" -lt 32 ]]; then
            plan_origin='attempt-02-archive'
        elif [[ "${SEAL_EXISTING}" -eq 1 ]]; then
            plan_origin='attempt-03-unary'
        else
            plan_origin='current-run'
        fi
        printf 'test[%d]=%s origin=%s\n' \
            "$((plan_index + 1))" "${EXPECTED_TESTS[plan_index]}" "${plan_origin}"
    done
} >"${TEST_PLAN_PATH}"
printf '[NPU-REGRESSION] plan tests=%d mode=%s source_pre_sha256=%s status=%s\n' \
    "${#EXPECTED_TESTS[@]}" "${RUN_MODE}" \
    "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_PRE}")" "${STATUS_PATH}"
else
    printf '[NPU-REGRESSION] plan tests=%d mode=direct build_root=%s log_root=%s timeout=%ss\n' \
        "${#EXPECTED_TESTS[@]}" "${BUILD_ROOT}" "${LOG_ROOT}" \
        "${RUN_TIMEOUT_SECONDS}"
fi

run_test \
    tb_decoder_regfile \
    '[NPU-DECODER-REGFILE][PASS]' \
    tests/tb_decoder_regfile.sv \
    rtl/TensorNpuCommandDecoder.v \
    rtl/TensorNpuRegisterFile.v

run_test \
    tb_local_memory \
    '[NPU-LMEM][PASS]' \
    tests/tb_local_memory.sv \
    rtl/TensorNpuLocalMemory.v

run_test \
    tb_mm2_engine \
    '[NPU-MM2][PASS]' \
    tests/tb_mm2_engine.sv \
    rtl/TensorNpuMm2Engine.v

run_test \
    tb_dma_engine \
    '[NPU-DMA][PASS]' \
    tests/tb_dma_engine.sv \
    rtl/TensorNpuDmaEngine.v

run_test \
    tb_coprocessor \
    '[NPU-COPROCESSOR][PASS]' \
    "${COPROCESSOR_RTL_SOURCES[@]}" \
    tests/tb_coprocessor.sv

run_test \
    tb_q8_dot_engine \
    '[NPU-Q8-DOT][PASS]' \
    tests/tb_q8_dot_engine.sv \
    rtl/TensorNpuQ8DotEngine.v

run_test \
    tb_fp16_to_fp32 \
    '[NPU-FP16-EXPAND][PASS]' \
    rtl/TensorNpuFp16ToFp32.v \
    tests/tb_fp16_to_fp32.sv

run_test \
    tb_int32_to_fp32 \
    '[NPU-I32-FP32][PASS]' \
    rtl/TensorNpuInt32ToFp32.v \
    tests/tb_int32_to_fp32.sv

run_test \
    tb_fp32_addmul \
    '[NPU-FP32-ADDMUL][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp32AddMul.v \
    tests/tb_fp32_addmul.sv

run_test \
    tb_fp32_div \
    '[NPU-FP32-DIV][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp32Div.v \
    tests/tb_fp32_div.sv

run_test \
    tb_fp32_to_fp16 \
    '[NPU-FP32-FP16][PASS]' \
    rtl/TensorNpuFp32ToFp16.v \
    tests/tb_fp32_to_fp16.sv

run_test \
    tb_fp32_to_int32_rmm \
    '[NPU-FP32-I32-RMM][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
    rtl/TensorNpuFp32ToInt32Rmm.v \
    tests/tb_fp32_to_int32_rmm.sv

run_test \
    tb_q8_scale_accumulator \
    '[NPU-Q8-SCALE-ACC][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp16ToFp32.v \
    rtl/TensorNpuInt32ToFp32.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuQ8DotEngine.v \
    rtl/TensorNpuQ8ScaleAccumulator.v \
    tests/tb_q8_scale_accumulator.sv

run_test \
    tb_q8_reference_quantizer \
    '[NPU-Q8-QUANT][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
    rtl/TensorNpuFp32Div.v \
    rtl/TensorNpuFp32ToFp16.v \
    rtl/TensorNpuFp32ToInt32Rmm.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuQ8ReferenceQuantizer.v \
    tests/tb_q8_reference_quantizer.sv

run_test \
    tb_q8_stream_gemv \
    '[NPU-Q8-GEMV][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
    rtl/TensorNpuFp16ToFp32.v \
    rtl/TensorNpuInt32ToFp32.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuFp32Div.v \
    rtl/TensorNpuFp32ToFp16.v \
    rtl/TensorNpuFp32ToInt32Rmm.v \
    rtl/TensorNpuQ8DotEngine.v \
    rtl/TensorNpuQ8ScaleAccumulator.v \
    rtl/TensorNpuQ8ReferenceQuantizer.v \
    rtl/TensorNpuQ8StreamGemv.v \
    tests/tb_q8_stream_gemv.sv

run_test \
    tb_q8_dequant_block \
    '[NPU-Q8-DEQUANT][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp16ToFp32.v \
    rtl/TensorNpuInt32ToFp32.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuQ8DequantBlock.v \
    tests/tb_q8_dequant_block.sv

run_test \
    tb_q8_get_rows_engine \
    '[NPU-Q8-GET-ROWS][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp16ToFp32.v \
    rtl/TensorNpuInt32ToFp32.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuQ8DequantBlock.v \
    rtl/TensorNpuQ8GetRowsEngine.v \
    tests/tb_q8_get_rows_engine.sv

run_test \
    tb_tensor_mover \
    '[NPU-TENSOR-MOVER][PASS]' \
    rtl/TensorNpuTensorMover.v \
    tests/tb_tensor_mover.sv

run_test \
    tb_set_rows_engine \
    '[NPU-SET-ROWS][PASS]' \
    rtl/TensorNpuFp32ToFp16.v \
    rtl/TensorNpuSetRowsEngine.v \
    tests/tb_set_rows_engine.sv

run_test \
    tb_fp32_sqrt \
    '[NPU-FP32-SQRT][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    rtl/TensorNpuFp32Sqrt.v \
    tests/tb_fp32_sqrt.sv

run_test \
    tb_fp32_to_fp64 \
    '[NPU-FP32-FP64][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    rtl/TensorNpuFp32ToFp64.v \
    tests/tb_fp32_to_fp64.sv

run_test \
    tb_fp64_add \
    '[NPU-FP64-ADD][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/addRecFN.v \
    rtl/TensorNpuFp64Add.v \
    tests/tb_fp64_add.sv

run_test \
    tb_fp64_to_fp32 \
    '[NPU-FP64-FP32][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    rtl/TensorNpuFp64ToFp32.v \
    tests/tb_fp64_to_fp32.sv

run_test \
    tb_fp64_to_int32_rmm \
    '[NPU-FP64-I32-RMM][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToIN.v \
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v \
    rtl/TensorNpuFp64ToInt32Rmm.v \
    tests/tb_fp64_to_int32_rmm.sv

run_test \
    tb_int32_to_fp64 \
    '[NPU-I32-FP64][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/iNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    rtl/TensorNpuInt32ToFp64.v \
    tests/tb_int32_to_fp64.sv

run_test \
    tb_fp64_fma \
    '[NPU-FP64-FMA][PASS]' \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/mulAddRecFN.v \
    rtl/TensorNpuFp64Fma.v \
    tests/tb_fp64_fma.sv

run_test \
    tb_fp32_square_sum64 \
    '[NPU-FP32-SQUARE-SUM64][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    third_party/hardfloat/source/addRecFN.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuFp32ToFp64.v \
    rtl/TensorNpuFp64Add.v \
    rtl/TensorNpuFp32SquareSum64.v \
    tests/tb_fp32_square_sum64.sv

run_test \
    tb_fp64_pow2_scale \
    '[NPU-FP64-POW2-SCALE][PASS]' \
    rtl/TensorNpuFp64Pow2Scale.v \
    tests/tb_fp64_pow2_scale.sv

run_test \
    tb_norm_engine \
    '[NPU-NORM][PASS]' \
    third_party/fpu-sp/verilog/src/float/fp_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
    third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
    third_party/fpu-sp/verilog/src/float/fp_ext.sv \
    third_party/fpu-sp/verilog/src/float/fp_fma.sv \
    third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/isSigNaNRecFN.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    third_party/hardfloat/source/addRecFN.v \
    rtl/TensorNpuFp32AddMul.v \
    rtl/TensorNpuFp32Div.v \
    rtl/TensorNpuFp32Sqrt.v \
    rtl/TensorNpuFp32ToFp64.v \
    rtl/TensorNpuFp64Add.v \
    rtl/TensorNpuFp64ToFp32.v \
    rtl/TensorNpuFp32SquareSum64.v \
    rtl/TensorNpuFp64Pow2Scale.v \
    rtl/TensorNpuNormEngine.v \
    tests/tb_norm_engine.sv

run_test \
    tb_fp64_to_fp32_finite \
    '[NPU-FP64-FP32-FINITE][PASS]' \
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    rtl/TensorNpuFp64ToFp32Finite.v \
    tests/tb_fp64_to_fp32_finite.sv

run_test \
    tb_aor_exp32 \
    '[NPU-AOR-EXP32][PASS]' \
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/mulAddRecFN.v \
    third_party/hardfloat/source/recFNToIN.v \
    third_party/hardfloat/source/iNToRecFN.v \
    rtl/TensorNpuFp32ToFp64.v \
    rtl/TensorNpuFp64Fma.v \
    rtl/TensorNpuFp64ToInt32Rmm.v \
    rtl/TensorNpuInt32ToFp64.v \
    rtl/TensorNpuFp64ToFp32Finite.v \
    rtl/TensorNpuAorExp32.v \
    tests/tb_aor_exp32.sv

run_test \
    tb_aor_log32 \
    '[NPU-AOR-LOG32][PASS]' \
    third_party/hardfloat/source/RISCV/HardFloat_specialize.v \
    third_party/hardfloat/source/HardFloat_primitives.v \
    third_party/hardfloat/source/HardFloat_rawFN.v \
    third_party/hardfloat/source/fNToRecFN.v \
    third_party/hardfloat/source/recFNToRecFN.v \
    third_party/hardfloat/source/recFNToFN.v \
    third_party/hardfloat/source/mulAddRecFN.v \
    third_party/hardfloat/source/iNToRecFN.v \
    rtl/TensorNpuFp32ToFp64.v \
    rtl/TensorNpuFp64Fma.v \
    rtl/TensorNpuInt32ToFp64.v \
    rtl/TensorNpuFp64ToFp32Finite.v \
    rtl/TensorNpuAorLog32.v \
    tests/tb_aor_log32.sv

run_test \
    tb_unary_glu_element \
    '[NPU-UNARY-GLU-ELEMENT][PASS]' \
    "${UNARY_GLU_COMPILE_SOURCES[@]}"

if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    run_test \
        tb_q8_row_simd_core \
        '[NPU-Q8-ROW-SIMD][PASS]' \
        third_party/fpu-sp/verilog/src/float/fp_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
        third_party/fpu-sp/verilog/src/float/fp_ext.sv \
        third_party/fpu-sp/verilog/src/float/fp_fma.sv \
        third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
        third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
        third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
        rtl/TensorNpuFp16ToFp32.v \
        rtl/TensorNpuInt32ToFp32.v \
        rtl/TensorNpuFp32AddMul.v \
        rtl/TensorNpuFp32Div.v \
        rtl/TensorNpuFp32ToFp16.v \
        rtl/TensorNpuFp32ToInt32Rmm.v \
        rtl/TensorNpuQ8DotEngine.v \
        rtl/TensorNpuQ8ScaleAccumulator.v \
        rtl/TensorNpuQ8ReferenceQuantizer.v \
        rtl/TensorNpuQ8RowSimdCore.v \
        tests/tb_q8_row_simd_core.sv

    run_test \
        tb_q8_gemv_portal_adapter \
        '[NPU-Q8-GEMV-PORTAL][PASS]' \
        third_party/fpu-sp/verilog/src/float/fp_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
        third_party/fpu-sp/verilog/src/float/fp_ext.sv \
        third_party/fpu-sp/verilog/src/float/fp_fma.sv \
        third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
        third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
        third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
        rtl/TensorNpuFp16ToFp32.v \
        rtl/TensorNpuInt32ToFp32.v \
        rtl/TensorNpuFp32AddMul.v \
        rtl/TensorNpuFp32Div.v \
        rtl/TensorNpuFp32ToFp16.v \
        rtl/TensorNpuFp32ToInt32Rmm.v \
        rtl/TensorNpuQ8DotEngine.v \
        rtl/TensorNpuQ8ScaleAccumulator.v \
        rtl/TensorNpuQ8ReferenceQuantizer.v \
        rtl/TensorNpuQ8RowSimdCore.v \
        rtl/TensorNpuQ8GemvPortalAdapter.v \
        tests/tb_q8_gemv_portal_adapter.sv

    run_test \
        tb_f32_alu_simd_core \
        '[NPU-F32-ALU-SIMD][PASS]' \
        third_party/fpu-sp/verilog/src/float/fp_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
        third_party/fpu-sp/verilog/src/float/fp_ext.sv \
        third_party/fpu-sp/verilog/src/float/fp_fma.sv \
        third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
        rtl/TensorNpuFp32AddMul.v \
        rtl/TensorNpuF32AluSimdCore.v \
        tests/tb_f32_alu_simd_core.sv

    run_test \
        tb_q8_gemv_writeback_adapter \
        '[NPU-Q8-GEMV-WRITEBACK][PASS]' \
        third_party/fpu-sp/verilog/src/float/fp_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
        third_party/fpu-sp/verilog/src/float/fp_ext.sv \
        third_party/fpu-sp/verilog/src/float/fp_fma.sv \
        third_party/fpu-sp/verilog/src/float/fp_fdiv.sv \
        third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
        third_party/fpu-sp/verilog/src/float/fp_cvt.sv \
        rtl/TensorNpuFp16ToFp32.v \
        rtl/TensorNpuInt32ToFp32.v \
        rtl/TensorNpuFp32AddMul.v \
        rtl/TensorNpuFp32Div.v \
        rtl/TensorNpuFp32ToFp16.v \
        rtl/TensorNpuFp32ToInt32Rmm.v \
        rtl/TensorNpuQ8DotEngine.v \
        rtl/TensorNpuQ8ScaleAccumulator.v \
        rtl/TensorNpuQ8ReferenceQuantizer.v \
        rtl/TensorNpuQ8StreamGemv.v \
        rtl/TensorNpuQ8GemvWritebackAdapter.v \
        tests/tb_q8_gemv_writeback_adapter.sv

    run_test \
        tb_q8_get_rows_writeback_adapter \
        '[NPU-Q8-GET-ROWS-WRITEBACK][PASS]' \
        third_party/fpu-sp/verilog/src/float/fp_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_4.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_8.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_16.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_32.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_64.sv \
        third_party/fpu-sp/verilog/src/lzc/lzc_128.sv \
        third_party/fpu-sp/verilog/src/float/fp_ext.sv \
        third_party/fpu-sp/verilog/src/float/fp_fma.sv \
        third_party/fpu-sp/verilog/src/float/fp_rnd.sv \
        rtl/TensorNpuFp16ToFp32.v \
        rtl/TensorNpuInt32ToFp32.v \
        rtl/TensorNpuFp32AddMul.v \
        rtl/TensorNpuQ8DequantBlock.v \
        rtl/TensorNpuQ8GetRowsEngine.v \
        rtl/TensorNpuQ8GetRowsWritebackAdapter.v \
        tests/tb_q8_get_rows_writeback_adapter.sv

    run_test \
        tb_coprocessor_q8_get_rows \
        '[NPU-COPROCESSOR-Q8-GET-ROWS][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_q8_get_rows.sv

    run_test \
        tb_coprocessor_q8_gemv \
        '[NPU-COPROCESSOR-Q8-GEMV][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_q8_gemv.sv

    run_test \
        tb_coprocessor_q8_gemv_portal \
        '[NPU-COPROCESSOR-Q8-GEMV-PORTAL][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_q8_gemv_portal.sv

    run_test \
        tb_f32_gather_repeat_adapter \
        '[NPU-F32-GATHER-REPEAT][PASS]' \
        rtl/TensorNpuF32GatherRepeatAdapter.v \
        tests/tb_f32_gather_repeat_adapter.sv

    run_test \
        tb_coprocessor_f32_gather_repeat \
        '[NPU-COPROCESSOR-F32-GATHER-REPEAT][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_f32_gather_repeat.sv

    run_test \
        tb_coprocessor_unary_norm_sum_ssm \
        '[NPU-COPROCESSOR-UNARY-NORM-SUM-SSM][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_unary_norm_sum_ssm.sv

    run_test \
        tb_coprocessor_mover_attention_softmax_rope \
        '[NPU-COPROC-BATCH2][PASS]' \
        "${COPROCESSOR_RTL_SOURCES[@]}" \
        tests/tb_coprocessor_mover_attention_softmax_rope.sv

    run_test \
        tb_unary_glu_writeback_adapter \
        '[NPU-UNARY-GLU-WRITEBACK][PASS]' \
        "${UNARY_GLU_ADAPTER_COMPILE_SOURCES[@]}"

    run_test \
        tb_norm_writeback_adapter \
        '[NPU-NORM-WRITEBACK][PASS]' \
        "${NORM_WRITEBACK_COMPILE_SOURCES[@]}"

    run_test \
        tb_sum_rows_writeback_adapter \
        '[NPU-SUM-ROWS-WRITEBACK][PASS]' \
        "${SUM_ROWS_WRITEBACK_COMPILE_SOURCES[@]}"

    run_test \
        tb_mover_set_rows_writeback_adapter \
        '[NPU-MOVER-SET-ROWS][PASS]' \
        "${MOVER_SET_ROWS_WRITEBACK_COMPILE_SOURCES[@]}"

    run_test \
        tb_ssm_conv_writeback_adapter \
        '[NPU-SSM-CONV-WRITEBACK][PASS]' \
        "${SSM_CONV_WRITEBACK_COMPILE_SOURCES[@]}"

    run_test \
        tb_f16_attention_matmul_writeback_adapter \
        '[NPU-F16-ATTENTION][PASS]' \
        "${F16_ATTENTION_MATMUL_COMPILE_SOURCES[@]}"

    run_test \
        tb_softmax_writeback_adapter \
        '[NPU-SOFTMAX-WRITEBACK][PASS]' \
        "${SOFTMAX_WRITEBACK_COMPILE_SOURCES[@]}"

    run_test \
        tb_rope_writeback_adapter \
        '[NPU-ROPE-WRITEBACK][PASS]' \
        "${ROPE_WRITEBACK_COMPILE_SOURCES[@]}"
fi

if [[ "${LEGACY_FORENSIC}" -eq 0 ]]; then
    [[ "${#EXECUTED_TESTS[@]}" -eq "${EXPECTED_TEST_COUNT}" &&
       "${VERILATOR_EXECUTION_COUNT}" -eq "${EXPECTED_TEST_COUNT}" &&
       "${TB_BINARY_EXECUTION_COUNT}" -eq "${EXPECTED_TEST_COUNT}" ]] ||
        die "direct regression result count mismatch"
    {
        printf 'status=PASS\n'
        printf 'mode=direct\n'
        printf 'tests=%d\n' "${EXPECTED_TEST_COUNT}"
        printf 'verilator_builds=%d\n' "${EXPECTED_TEST_COUNT}"
        printf 'test_binary_runs=%d\n' "${EXPECTED_TEST_COUNT}"
        printf 'assertions=off\n'
        printf 'waveform=off\n'
        printf 'optimization=O3\n'
        printf 'build_root=%s\n' "${BUILD_ROOT}"
        printf 'log_root=%s\n' "${LOG_ROOT}"
    } >"${LOG_ROOT}/result.txt"
    printf '[NPU-REGRESSION][RESULT] build_root=%s log_root=%s result=%s\n' \
        "${BUILD_ROOT}" "${LOG_ROOT}" "${LOG_ROOT}/result.txt"
    printf '%s\n' "${FINAL_PASS_MARKER}"
    exit 0
fi

UNARY_EVIDENCE_BUILD_ROOT="${BUILD_ROOT}"
UNARY_EVIDENCE_LOG_ROOT="${LOG_ROOT}"
if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
    UNARY_EVIDENCE_BUILD_ROOT="${ATTEMPT03_BUILD_ROOT}"
    UNARY_EVIDENCE_LOG_ROOT="${ATTEMPT03_LOG_ROOT}"
fi
readonly UNARY_BUILD_DIR="$(project_tmp_path "${UNARY_EVIDENCE_BUILD_ROOT}/tb_unary_glu_element")"
readonly UNARY_BINARY="$(project_tmp_path "${UNARY_BUILD_DIR}/Vtb_unary_glu_element")"
readonly UNARY_VERFILES="$(project_tmp_path "${UNARY_BUILD_DIR}/Vtb_unary_glu_element__verFiles.dat")"
readonly UNARY_MAKEFILE="$(project_tmp_path "${UNARY_BUILD_DIR}/Vtb_unary_glu_element.mk")"
readonly UNARY_CONFIG_EVIDENCE="$(project_tmp_path "${UNARY_EVIDENCE_LOG_ROOT}/tb_unary_glu_element.config")"
readonly UNARY_BUILD_LOG="$(project_tmp_path "${UNARY_EVIDENCE_LOG_ROOT}/tb_unary_glu_element.build.log")"
readonly UNARY_BUILD_RC="$(project_tmp_path "${UNARY_EVIDENCE_LOG_ROOT}/tb_unary_glu_element.build.rc")"
readonly UNARY_RUN_LOG="$(project_tmp_path "${UNARY_EVIDENCE_LOG_ROOT}/tb_unary_glu_element.run.log")"
readonly UNARY_RUN_RC="$(project_tmp_path "${UNARY_EVIDENCE_LOG_ROOT}/tb_unary_glu_element.run.rc")"
readonly SOURCE_HASH_AUDIT="$(project_tmp_path "${LOG_ROOT}/source-hash-audit.log")"
readonly MARKER_AUDIT="$(project_tmp_path "${LOG_ROOT}/marker-audit.log")"
readonly CONFIG_AUDIT="$(project_tmp_path "${LOG_ROOT}/config-audit.log")"
readonly WARNING_AUDIT="$(project_tmp_path "${LOG_ROOT}/warning-audit.log")"
readonly FORBIDDEN_AUDIT="$(project_tmp_path "${LOG_ROOT}/forbidden-audit.log")"
readonly WAVE_AUDIT="$(project_tmp_path "${LOG_ROOT}/wave-core-audit.log")"
readonly BOUND_MANIFEST="$(project_tmp_path "${LOG_ROOT}/unary-glu-element.bound-artifacts.sha256")"
readonly RECEIPT_PATH="$(project_tmp_path "${LOG_ROOT}/unary-glu-element.receipt")"
readonly RECEIPT_SHA256_PATH="$(project_tmp_path "${LOG_ROOT}/unary-glu-element.receipt.sha256")"
readonly RECEIPT_AUDIT="$(project_tmp_path "${LOG_ROOT}/receipt-audit.log")"
readonly FINAL_EVIDENCE_AUDIT="$(project_tmp_path "${LOG_ROOT}/final-evidence-audit.log")"

task_run_status_stage source-freeze-post
if [[ "${SEAL_EXISTING}" -ne 1 ]]; then
    sha256sum -- "${UNARY_GLU_MANIFEST_SOURCES[@]}" >"${SOURCE_MANIFEST_POST}"
fi
repair_legacy_source_equal=1
if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
    if [[ "${SEAL_EXISTING}" -ne 1 ]]; then
        for ((repair_source_index = 0;
              repair_source_index < ${#REPAIR_LEGACY_SOURCE_PATHS[@]};
              repair_source_index = repair_source_index + 1)); do
            source_file="${REPAIR_LEGACY_SOURCE_PATHS[repair_source_index]}"
            test_name="${REPAIR_LEGACY_SOURCE_TESTS[repair_source_index]}"
            printf '%s  %s test=%s\n' \
                "$(file_sha256 "${source_file}")" \
                "${source_file}" "${test_name}" \
                >>"${REPAIR_LEGACY_SOURCE_POST}"
        done
    fi
    if ! cmp -s -- \
            "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}" \
            "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}"; then
        repair_legacy_source_equal=0
    fi
fi
RUNNER_POST_SHA256="$(file_sha256 "${RUNNER_PATH}")"
SOURCE_LOCK_POST_SHA256="$(file_sha256 "${SOURCE_LOCK_PATH}")"
PREBUILD_LOG_POST_SHA256="$(file_sha256 "${PREBUILD_LOCK_LOG}")"

source_manifest_equal=0
runner_equal=0
source_lock_equal=0
prebuild_log_equal=0
if cmp -s -- "${ACTIVE_SOURCE_MANIFEST_PRE}" \
        "${ACTIVE_SOURCE_MANIFEST_POST}"; then
    source_manifest_equal=1
fi
if [[ "${RUNNER_PRE_SHA256}" == "${RUNNER_POST_SHA256}" ]]; then
    runner_equal=1
fi
if [[ "${SOURCE_LOCK_PRE_SHA256}" == "${SOURCE_LOCK_POST_SHA256}" ]]; then
    source_lock_equal=1
fi
if [[ "${PREBUILD_LOG_PRE_SHA256}" == "${PREBUILD_LOG_POST_SHA256}" ]]; then
    prebuild_log_equal=1
fi

[[ -f "${UNARY_VERFILES}" && -f "${UNARY_MAKEFILE}" && -x "${UNARY_BINARY}" ]] \
    || die 'unary generated config/makefile/binary is incomplete'
generated_source_set_equal=0
if extract_generated_project_sources \
        "${UNARY_VERFILES}" \
        "${ACTIVE_EXPECTED_PROJECT_SOURCES}" \
        "${GENERATED_PROJECT_SOURCES}"; then
    generated_source_set_equal=1
fi
expected_project_source_count=0
generated_project_source_count=0
legacy_manifest_entry_count=0
while IFS= read -r counted_source || [[ -n "${counted_source}" ]]; do
    expected_project_source_count=$((expected_project_source_count + 1))
done <"${ACTIVE_EXPECTED_PROJECT_SOURCES}"
while IFS= read -r counted_source || [[ -n "${counted_source}" ]]; do
    generated_project_source_count=$((generated_project_source_count + 1))
done <"${GENERATED_PROJECT_SOURCES}"
if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
    while IFS= read -r legacy_manifest_line ||
          [[ -n "${legacy_manifest_line}" ]]; do
        legacy_manifest_entry_count=$((legacy_manifest_entry_count + 1))
    done <"${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}"
fi
seal_current_identity_equal=1
if [[ "${SEAL_EXISTING}" -eq 1 ]] &&
   ! grep -Fxq -- 'seal_source_check=PASS' "${SEAL_SOURCE_CHECK}"; then
    seal_current_identity_equal=0
fi

{
    printf 'manifest_source_count=%d\n' "${#UNARY_GLU_MANIFEST_SOURCES[@]}"
    printf 'compile_source_count=%d\n' "${#UNARY_GLU_COMPILE_SOURCES[@]}"
    printf 'transitive_source_count=%d\n' "${#UNARY_GLU_TRANSITIVE_SOURCES[@]}"
    printf 'source_manifest_pre_sha256=%s\n' \
        "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_PRE}")"
    printf 'source_manifest_post_sha256=%s\n' \
        "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_POST}")"
    printf 'source_manifest_equal=%d\n' "${source_manifest_equal}"
    printf 'generated_source_set_equal=%d\n' "${generated_source_set_equal}"
    printf 'expected_project_source_count=%d\n' \
        "${expected_project_source_count}"
    printf 'generated_project_source_count=%d\n' \
        "${generated_project_source_count}"
    printf 'runner_pre_sha256=%s\n' "${RUNNER_PRE_SHA256}"
    printf 'runner_post_sha256=%s\n' "${RUNNER_POST_SHA256}"
    printf 'runner_equal=%d\n' "${runner_equal}"
    printf 'execution_runner_sha256=%s\n' "${EXECUTION_RUNNER_SHA256}"
    printf 'source_lock_pre_sha256=%s\n' "${SOURCE_LOCK_PRE_SHA256}"
    printf 'source_lock_post_sha256=%s\n' "${SOURCE_LOCK_POST_SHA256}"
    printf 'source_lock_equal=%d\n' "${source_lock_equal}"
    printf 'prebuild_log_pre_sha256=%s\n' "${PREBUILD_LOG_PRE_SHA256}"
    printf 'prebuild_log_post_sha256=%s\n' "${PREBUILD_LOG_POST_SHA256}"
    printf 'prebuild_log_equal=%d\n' "${prebuild_log_equal}"
    printf 'execution_mode=%s\n' "${RUN_MODE}"
    printf 'repair_legacy_test_count=%d\n' "${LEGACY_ADOPTED_COUNT}"
    printf 'repair_legacy_source_entry_count=%d\n' \
        "${#REPAIR_LEGACY_SOURCE_PATHS[@]}"
    printf 'repair_legacy_source_equal=%d\n' \
        "${repair_legacy_source_equal}"
    printf 'repair_legacy_manifest_entry_count=%d\n' \
        "${legacy_manifest_entry_count}"
    printf 'seal_current_identity_equal=%d\n' \
        "${seal_current_identity_equal}"
    printf 'seal_verilator_execution_count=%d\n' \
        "${VERILATOR_EXECUTION_COUNT}"
    printf 'seal_tb_binary_execution_count=%d\n' \
        "${TB_BINARY_EXECUTION_COUNT}"
} >"${SOURCE_HASH_AUDIT}"

if [[ "${source_manifest_equal}" -ne 1 ||
      "${generated_source_set_equal}" -ne 1 ||
      "${expected_project_source_count}" -ne \
          "${#UNARY_GLU_MANIFEST_SOURCES[@]}" ||
      "${generated_project_source_count}" -ne \
          "${#UNARY_GLU_MANIFEST_SOURCES[@]}" ||
      "${runner_equal}" -ne 1 ||
      "${source_lock_equal}" -ne 1 ||
      "${prebuild_log_equal}" -ne 1 ||
      "${repair_legacy_source_equal}" -ne 1 ||
      "${seal_current_identity_equal}" -ne 1 ]]; then
    die "source/input identity audit failed: ${SOURCE_HASH_AUDIT}"
fi
if [[ "${REPAIR_COMPOSITE}" -eq 1 &&
      "${legacy_manifest_entry_count}" -ne \
          "${#REPAIR_LEGACY_SOURCE_PATHS[@]}" ]]; then
    die "legacy source manifest shape failed: ${SOURCE_HASH_AUDIT}"
fi
if [[ "${SEAL_EXISTING}" -eq 1 &&
      ( "${VERILATOR_EXECUTION_COUNT}" -ne 0 ||
        "${TB_BINARY_EXECUTION_COUNT}" -ne 0 ) ]]; then
    die "seal unexpectedly executed Verilator/TB: ${SOURCE_HASH_AUDIT}"
fi

task_run_status_stage marker-audit
marker_audit_rc=0
declare -A seen_tests=()
{
    printf 'executed_test_count=%d\n' "${#EXECUTED_TESTS[@]}"
    if [[ "${#EXECUTED_TESTS[@]}" -ne 33 ||
          "${#EXECUTED_MARKERS[@]}" -ne 33 ||
          "${#EXECUTED_BUILD_RCS[@]}" -ne 33 ||
          "${#EXECUTED_RUN_LOGS[@]}" -ne 33 ||
          "${#EXECUTED_RUN_RCS[@]}" -ne 33 ||
          "${#EXECUTED_ORIGINS[@]}" -ne 33 ]]; then
        marker_audit_rc=1
    fi
    for ((test_index = 0;
          test_index < ${#EXECUTED_TESTS[@]};
          test_index = test_index + 1)); do
        test_name="${EXECUTED_TESTS[test_index]}"
        pass_marker="${EXECUTED_MARKERS[test_index]}"
        test_run_log="${EXECUTED_RUN_LOGS[test_index]}"
        pass_count="$(count_pass_marker \
            "${test_name}" "${pass_marker}" "${test_run_log}")"
        fail_count="$(grep -Fc -- '[FAIL]' "${test_run_log}" || true)"
        build_rc_value="$(sed -n '1p' "${EXECUTED_BUILD_RCS[test_index]}")"
        run_rc_value="$(sed -n '1p' "${EXECUTED_RUN_RCS[test_index]}")"
        if [[ -n "${seen_tests[${test_name}]+present}" ]]; then
            marker_audit_rc=1
        fi
        seen_tests["${test_name}"]=1
        if [[ "${test_name}" != "${EXPECTED_TESTS[test_index]}" ]]; then
            marker_audit_rc=1
        fi
        if [[ "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ||
              "${build_rc_value}" != 0 || "${run_rc_value}" != 0 ]]; then
            marker_audit_rc=1
        fi
        printf 'test=%s origin=%s pass_count=%s fail_count=%s build_rc=%s run_rc=%s marker=%s\n' \
            "${test_name}" "${EXECUTED_ORIGINS[test_index]}" \
            "${pass_count}" "${fail_count}" "${build_rc_value}" \
            "${run_rc_value}" "${pass_marker}"
    done
    printf 'marker_audit_rc=%d\n' "${marker_audit_rc}"
} >"${MARKER_AUDIT}"
[[ "${marker_audit_rc}" -eq 0 ]] \
    || die "33-test marker/native-rc audit failed: ${MARKER_AUDIT}"

task_run_status_stage config-audit
config_audit_rc=0
{
    if grep -Fxq -- \
           'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal' \
           "${UNARY_CONFIG_EVIDENCE}" &&
       grep -Fxq -- 'cflags=-O3 -DNDEBUG -march=native' \
           "${UNARY_CONFIG_EVIDENCE}" &&
       grep -Fq -- '--binary --timing --sv -O3 -Wall -Wno-fatal' \
           "${UNARY_VERFILES}" &&
       grep -Fq -- '-O3 -DNDEBUG -march=native' "${UNARY_VERFILES}" &&
       grep -Fq -- '-O3 -DNDEBUG -march=native' "${UNARY_MAKEFILE}"; then
        printf 'config_match=1\n'
    else
        config_audit_rc=1
        printf 'config_match=0\n'
    fi
    printf 'config_audit_rc=%d\n' "${config_audit_rc}"
} >"${CONFIG_AUDIT}"
[[ "${config_audit_rc}" -eq 0 ]] \
    || die "unary generated config audit failed: ${CONFIG_AUDIT}"

task_run_status_stage warning-audit
warning_audit_rc=0
{
    if grep -En -- \
           '^%Warning[^:]*: .*\/(TensorNpuUnaryGluElement\.v|tb_unary_glu_element\.sv):' \
           "${UNARY_BUILD_LOG}"; then
        printf 'project_warning_count=nonzero\n'
        warning_audit_rc=1
    else
        warning_scan_rc=$?
        if [[ "${warning_scan_rc}" -eq 1 ]]; then
            printf 'project_warning_count=0\n'
        else
            printf 'project_warning_scan_rc=%d\n' "${warning_scan_rc}"
            warning_audit_rc=1
        fi
    fi
    if grep -En -- '^%Error' "${UNARY_BUILD_LOG}"; then
        printf 'build_error_count=nonzero\n'
        warning_audit_rc=1
    else
        error_scan_rc=$?
        if [[ "${error_scan_rc}" -eq 1 ]]; then
            printf 'build_error_count=0\n'
        else
            printf 'build_error_scan_rc=%d\n' "${error_scan_rc}"
            warning_audit_rc=1
        fi
    fi
    if bash -n -- "${RUNNER_PATH}"; then
        printf 'runner_bash_syntax=PASS\n'
    else
        printf 'runner_bash_syntax=FAIL\n'
        warning_audit_rc=1
    fi
    printf 'warning_audit_rc=%d\n' "${warning_audit_rc}"
} >"${WARNING_AUDIT}" 2>&1
[[ "${warning_audit_rc}" -eq 0 ]] \
    || die "unary project warning/syntax audit failed: ${WARNING_AUDIT}"

task_run_status_stage forbidden-audit
forbidden_audit_rc=0
FORBIDDEN_AUDIT_OBJECTS=(
    "${RUNNER_PATH}"
    "${PROJECT_ROOT}/rtl/TensorNpuUnaryGluElement.v"
    "${PROJECT_ROOT}/tests/tb_unary_glu_element.sv"
    "${UNARY_CONFIG_EVIDENCE}"
    "${UNARY_VERFILES}"
)
printf '%s\n' "${FORBIDDEN_AUDIT_OBJECTS[@]}" >"${FORBIDDEN_OBJECTS_PATH}"
{
    printf 'audited_object_count=%d\n' "${#FORBIDDEN_AUDIT_OBJECTS[@]}"
    for ((forbidden_object_index = 0;
          forbidden_object_index < ${#FORBIDDEN_AUDIT_OBJECTS[@]};
          forbidden_object_index = forbidden_object_index + 1)); do
        printf 'audited_object[%d]=%s\n' \
            "${forbidden_object_index}" \
            "${FORBIDDEN_AUDIT_OBJECTS[forbidden_object_index]}"
    done
    if ! grep -Fxq -- 'forbidden_audit_self_test=PASS' \
            "${FORBIDDEN_AUDIT_SELF_TEST_LOG}"; then
        printf 'forbidden_predicate_self_test=FAIL\n'
        forbidden_audit_rc=1
    else
        printf 'forbidden_predicate_self_test=PASS\n'
    fi
    if forbidden_audit_scan "${FORBIDDEN_AUDIT_OBJECTS[@]}"; then
        printf 'forbidden_construct_count=nonzero\n'
        forbidden_audit_rc=1
    else
        forbidden_scan_rc=$?
        if [[ "${forbidden_scan_rc}" -eq 1 ]]; then
            printf 'forbidden_construct_count=0\n'
        else
            printf 'forbidden_scan_rc=%d\n' "${forbidden_scan_rc}"
            forbidden_audit_rc=1
        fi
    fi
    printf 'forbidden_audit_rc=%d\n' "${forbidden_audit_rc}"
} >"${FORBIDDEN_AUDIT}"
[[ "${forbidden_audit_rc}" -eq 0 ]] \
    || die "assert/waveform option audit failed: ${FORBIDDEN_AUDIT}"

task_run_status_stage cleanup-audit
if ! cleanup_transients; then
    die "compiler/cache cleanup failed: ${CLEANUP_AUDIT_PATH}"
fi

task_run_status_stage wave-core-audit
wave_audit_rc=0
wave_or_core_path="$(find \
    "${BUILD_ROOT}" "${LOG_ROOT}" "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" \
    -type f \
    \( -name 'core' -o -name 'core.*' -o -name '*.vcd' -o -name '*.fst' \
       -o -name '*.lxt' -o -name '*.lxt2' -o -name '*.ghw' -o -name '*.wlf' \) \
    -print -quit)"
{
    if [[ -z "${wave_or_core_path}" ]]; then
        printf 'wave_or_core_artifact_count=0\n'
    else
        printf 'wave_or_core_artifact_count=nonzero path=%s\n' \
            "${wave_or_core_path}"
        wave_audit_rc=1
    fi
    printf 'wave_audit_rc=%d\n' "${wave_audit_rc}"
} >"${WAVE_AUDIT}"
[[ "${wave_audit_rc}" -eq 0 ]] \
    || die "wave/core artifact audit failed: ${WAVE_AUDIT}"

if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
    task_run_status_stage repair-composite-audit
    repair_audit_rc=0
    attempt02_summary="${ATTEMPT02_LOG_ROOT}/failure-summary.txt"
    attempt02_status="${ATTEMPT02_LOG_ROOT}/task-run.status"
    attempt02_runner_snapshot="${ATTEMPT02_LOG_ROOT}/run_npu_regression.sh.snapshot"
    attempt02_source_pre="${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.sources.pre.sha256"
    attempt02_unary_run_log="${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.log"
    attempt02_unary_run_rc="${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.rc"
    attempt02_runner_expected="$(sed -n 's/^runner_sha256=//p' \
        "${attempt02_summary}")"
    attempt02_source_expected="$(sed -n 's/^source_manifest_pre_sha256=//p' \
        "${attempt02_summary}")"
    if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
        attempt03_summary="${ATTEMPT03_LOG_ROOT}/failure-summary.txt"
        attempt03_status="${ATTEMPT03_LOG_ROOT}/task-run.status"
        attempt03_runner_snapshot="${ATTEMPT03_LOG_ROOT}/run_npu_regression.sh.snapshot"
        attempt03_source_expected="$(sed -n 's/^source_manifest_pre_sha256=//p' \
            "${attempt03_summary}")"
        attempt04_summary="${ATTEMPT04_LOG_ROOT}/failure-summary.txt"
        attempt04_status="${ATTEMPT04_LOG_ROOT}/task-run.status"
        attempt04_runner_snapshot="${ATTEMPT04_LOG_ROOT}/run_npu_regression.sh.snapshot"
        attempt04_source_audit="${ATTEMPT04_LOG_ROOT}/source-hash-audit.log"
    fi
    {
        printf 'execution_mode=%s\n' "${RUN_MODE}"
        printf 'legacy_adopted_count=%d\n' "${LEGACY_ADOPTED_COUNT}"
        printf 'legacy_bound_artifact_count=%d\n' \
            "${#LEGACY_BOUND_ARTIFACTS[@]}"
        printf 'legacy_source_entry_count=%d\n' \
            "${#REPAIR_LEGACY_SOURCE_PATHS[@]}"
        printf 'legacy_source_manifest_equal=%d\n' \
            "${repair_legacy_source_equal}"
        printf 'attempt03_unary_adopted_count=%d\n' \
            "${ATTEMPT03_ADOPTED_COUNT}"
        printf 'seal_verilator_execution_count=%d\n' \
            "${VERILATOR_EXECUTION_COUNT}"
        printf 'seal_tb_binary_execution_count=%d\n' \
            "${TB_BINARY_EXECUTION_COUNT}"
        if [[ "${LEGACY_ADOPTED_COUNT}" -ne 32 ||
              "${#LEGACY_BOUND_ARTIFACTS[@]}" -ne 224 ||
              "${#REPAIR_LEGACY_SOURCE_PATHS[@]}" -ne \
                  "${legacy_manifest_entry_count}" ||
              "${repair_legacy_source_equal}" -ne 1 ]]; then
            printf 'legacy_evidence_shape=FAIL\n'
            repair_audit_rc=1
        else
            printf 'legacy_evidence_shape=PASS\n'
        fi
        if grep -Fxq -- \
               'FAIL rc=134 stage=run-tb_unary_glu_element evidence_complete=0 cleanup_rc=0' \
               "${attempt02_status}" &&
           grep -Fxq -- 'completed_legacy_tests=32' "${attempt02_summary}" &&
           grep -Fxq -- 'legacy_marker_gate=PASS' "${attempt02_summary}" &&
           grep -Fxq -- 'unary_build_rc=0' "${attempt02_summary}" &&
           grep -Fxq -- 'unary_run_rc=134' "${attempt02_summary}" &&
           [[ "$(sed -n '1p' "${attempt02_unary_run_rc}")" == 134 ]] &&
           grep -Fq -- \
               '[NPU-UNARY-GLU-ELEMENT][FAIL] case=illegal-state-literal-14' \
               "${attempt02_unary_run_log}"; then
            printf 'attempt02_failure_preserved=PASS\n'
        else
            printf 'attempt02_failure_preserved=FAIL\n'
            repair_audit_rc=1
        fi
        if [[ -n "${attempt02_runner_expected}" &&
              "$(file_sha256 "${attempt02_runner_snapshot}")" == \
                  "${attempt02_runner_expected}" &&
              -n "${attempt02_source_expected}" &&
              "$(file_sha256 "${attempt02_source_pre}")" == \
                  "${attempt02_source_expected}" ]]; then
            printf 'attempt02_identity_preserved=PASS\n'
        else
            printf 'attempt02_identity_preserved=FAIL\n'
            repair_audit_rc=1
        fi
        if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
            if [[ "${ATTEMPT03_ADOPTED_COUNT}" -eq 1 &&
                  "${VERILATOR_EXECUTION_COUNT}" -eq 0 &&
                  "${TB_BINARY_EXECUTION_COUNT}" -eq 0 ]]; then
                printf 'seal_execution_shape=PASS\n'
            else
                printf 'seal_execution_shape=FAIL\n'
                repair_audit_rc=1
            fi
            if grep -Fxq -- \
                   'FAIL rc=1 stage=source-freeze-post evidence_complete=0 cleanup_rc=0' \
                   "${attempt03_status}" &&
               grep -Fxq -- 'unary_build_rc=0' "${attempt03_summary}" &&
               grep -Fxq -- 'unary_run_rc=0' "${attempt03_summary}" &&
               grep -Fxq -- 'unary_pass_marker_count=1' "${attempt03_summary}" &&
               [[ "$(sed -n '1p' "${UNARY_BUILD_RC}")" == 0 ]] &&
               [[ "$(sed -n '1p' "${UNARY_RUN_RC}")" == 0 ]] &&
               [[ "$(count_pass_marker tb_unary_glu_element \
                    '[NPU-UNARY-GLU-ELEMENT][PASS]' "${UNARY_RUN_LOG}")" -eq 1 ]] &&
               [[ "$(grep -Fc -- '[FAIL]' "${UNARY_RUN_LOG}" || true)" -eq 0 ]] &&
               ! grep -Eq -- '^%Warning|^%Error' "${UNARY_BUILD_LOG}"; then
                printf 'attempt03_unary_pass_preserved=PASS\n'
            else
                printf 'attempt03_unary_pass_preserved=FAIL\n'
                repair_audit_rc=1
            fi
            if [[ "$(file_sha256 "${attempt03_runner_snapshot}")" == \
                      "${EXECUTION_RUNNER_SHA256}" &&
                  -n "${attempt03_source_expected}" &&
                  "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_PRE}")" == \
                      "${attempt03_source_expected}" ]] &&
               grep -Fxq -- \
                   "execution_runner_sha256=${EXECUTION_RUNNER_SHA256}" \
                   "${TEST_PLAN_PATH}" &&
               grep -Fxq -- 'source_parser_self_test=PASS' \
                   "${SOURCE_PARSER_SELF_TEST_LOG}"; then
                printf 'attempt03_identity_preserved=PASS\n'
            else
                printf 'attempt03_identity_preserved=FAIL\n'
                repair_audit_rc=1
            fi
            if grep -Fxq -- \
                   'FAIL rc=1 stage=forbidden-audit evidence_complete=0 cleanup_rc=0' \
                   "${attempt04_status}" &&
               grep -Fxq -- 'seal_verilator_execution_count=0' \
                   "${attempt04_source_audit}" &&
               grep -Fxq -- 'seal_tb_binary_execution_count=0' \
                   "${attempt04_source_audit}" &&
               grep -Fxq -- 'generated_project_source_count=36' \
                   "${attempt04_source_audit}" &&
               grep -Fxq -- 'marker_audit_rc=0' \
                   "${ATTEMPT04_LOG_ROOT}/marker-audit.log" &&
               grep -Fxq -- 'warning_audit_rc=0' \
                   "${ATTEMPT04_LOG_ROOT}/warning-audit.log" &&
               [[ "$(file_sha256 "${attempt04_runner_snapshot}")" == \
                   e17645eef27598ee7174bf2e7e39c036f822718d80f038e5840fb74e629562a2 ]]; then
                printf 'attempt04_failure_preserved=PASS\n'
            else
                printf 'attempt04_failure_preserved=FAIL\n'
                repair_audit_rc=1
            fi
        fi
        printf 'repair_composite_audit_rc=%d\n' "${repair_audit_rc}"
        if [[ "${repair_audit_rc}" -eq 0 ]]; then
            printf 'repair_composite_audit=PASS\n'
        else
            printf 'repair_composite_audit=FAIL\n'
        fi
    } >"${REPAIR_COMPOSITE_AUDIT}"
    [[ "${repair_audit_rc}" -eq 0 ]] \
        || die "repair composite audit failed: ${REPAIR_COMPOSITE_AUDIT}"
fi

task_run_status_stage receipt-seal
BOUND_ARTIFACTS=(
    "${UNARY_GLU_MANIFEST_SOURCES[@]}"
    "${SOURCE_LOCK_PATH}"
    "${PREBUILD_LOCK_LOG}"
    "${RUNNER_PATH}"
    "${TASK_RUN_STATUS_HELPER}"
    "${MARKER_ORACLE_SELF_TEST_LOG}"
    "${SOURCE_PARSER_SELF_TEST_LOG}"
    "${FORBIDDEN_AUDIT_SELF_TEST_LOG}"
    "${FORBIDDEN_OBJECTS_PATH}"
    "${TEST_PLAN_PATH}"
    "${ACTIVE_UNARY_FILELIST}"
    "${UNARY_CONFIG_EVIDENCE}"
    "${ACTIVE_SOURCE_MANIFEST_PRE}"
    "${ACTIVE_SOURCE_MANIFEST_POST}"
    "${ACTIVE_EXPECTED_PROJECT_SOURCES}"
    "${GENERATED_PROJECT_SOURCES}"
    "${UNARY_VERFILES}"
    "${UNARY_MAKEFILE}"
    "${UNARY_BINARY}"
    "${UNARY_BUILD_LOG}"
    "${UNARY_BUILD_RC}"
    "${UNARY_RUN_LOG}"
    "${UNARY_RUN_RC}"
    "${SOURCE_HASH_AUDIT}"
    "${MARKER_AUDIT}"
    "${CONFIG_AUDIT}"
    "${WARNING_AUDIT}"
    "${FORBIDDEN_AUDIT}"
    "${CLEANUP_AUDIT_PATH}"
    "${WAVE_AUDIT}"
)
if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
    BOUND_ARTIFACTS+=(
        "${ATTEMPT02_LOG_ROOT}/failure-summary.txt"
        "${ATTEMPT02_LOG_ROOT}/task-run.status"
        "${ATTEMPT02_LOG_ROOT}/run_npu_regression.sh.snapshot"
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.sources.pre.sha256"
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.build.log"
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.build.rc"
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.log"
        "${ATTEMPT02_LOG_ROOT}/tb_unary_glu_element.run.rc"
        "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}"
        "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}"
        "${REPAIR_COMPOSITE_AUDIT}"
        "${LEGACY_BOUND_ARTIFACTS[@]}"
    )
fi
if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
    BOUND_ARTIFACTS+=(
        "${SEAL_SOURCE_CHECK}"
        "${EXECUTION_TEST_PLAN}"
        "${ATTEMPT03_LOG_ROOT}/failure-summary.txt"
        "${ATTEMPT03_LOG_ROOT}/task-run.status"
        "${ATTEMPT03_LOG_ROOT}/repair-composite.console.log"
        "${ATTEMPT03_LOG_ROOT}/run_npu_regression.sh.snapshot"
        "${ATTEMPT03_LOG_ROOT}/cleanup-audit.log"
        "${ATTEMPT03_LOG_ROOT}/runner-bash-n.log"
        "${ATTEMPT03_LOG_ROOT}/marker-oracle-self-test.log"
        "${ATTEMPT03_LOG_ROOT}/tb_unary_glu_element.generated-project-sources.list"
        "${ATTEMPT04_LOG_ROOT}/failure-summary.txt"
        "${ATTEMPT04_LOG_ROOT}/task-run.status"
        "${ATTEMPT04_LOG_ROOT}/seal-existing.console.log"
        "${ATTEMPT04_LOG_ROOT}/run_npu_regression.sh.snapshot"
        "${ATTEMPT04_LOG_ROOT}/source-hash-audit.log"
        "${ATTEMPT04_LOG_ROOT}/marker-audit.log"
        "${ATTEMPT04_LOG_ROOT}/warning-audit.log"
        "${ATTEMPT04_LOG_ROOT}/forbidden-audit.log"
    )
fi
sha256sum -- "${BOUND_ARTIFACTS[@]}" >"${BOUND_MANIFEST}"
BOUND_MANIFEST_SHA256="$(file_sha256 "${BOUND_MANIFEST}")"
UNARY_PASS_COUNT="$(grep -Fxc -- '[NPU-UNARY-GLU-ELEMENT][PASS]' "${UNARY_RUN_LOG}" || true)"
UNARY_FAIL_COUNT="$(grep -Fc -- '[FAIL]' "${UNARY_RUN_LOG}" || true)"

{
    printf 'schema=npu-unary-glu-element-regression-receipt-v1\n'
    printf 'test=tb_unary_glu_element\n'
    printf 'test_index=33\n'
    printf 'tests_total=33\n'
    printf 'execution_mode=%s\n' "${RUN_MODE}"
    printf 'legacy_adopted_test_count=%d\n' "${LEGACY_ADOPTED_COUNT}"
    printf 'attempt03_unary_adopted_test_count=%d\n' \
        "${ATTEMPT03_ADOPTED_COUNT}"
    printf 'seal_verilator_execution_count=%d\n' \
        "${VERILATOR_EXECUTION_COUNT}"
    printf 'seal_tb_binary_execution_count=%d\n' \
        "${TB_BINARY_EXECUTION_COUNT}"
    printf 'compile_source_count=%d\n' "${#UNARY_GLU_COMPILE_SOURCES[@]}"
    printf 'transitive_source_count=%d\n' "${#UNARY_GLU_TRANSITIVE_SOURCES[@]}"
    printf 'manifest_source_count=%d\n' "${#UNARY_GLU_MANIFEST_SOURCES[@]}"
    while read -r source_hash source_path; do
        printf 'source_sha256=%s path=%s\n' "${source_hash}" "${source_path}"
    done <"${ACTIVE_SOURCE_MANIFEST_PRE}"
    printf 'source_manifest_pre_sha256=%s\n' \
        "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_PRE}")"
    printf 'source_manifest_post_sha256=%s\n' \
        "$(file_sha256 "${ACTIVE_SOURCE_MANIFEST_POST}")"
    printf 'source_manifest_equal=1\n'
    printf 'generated_source_set_equal=1\n'
    printf 'expected_project_source_count=%d\n' \
        "${expected_project_source_count}"
    printf 'generated_project_source_count=%d\n' \
        "${generated_project_source_count}"
    printf 'sources_lock_sha256=%s\n' "${SOURCE_LOCK_POST_SHA256}"
    printf 'prebuild_lock_log_sha256=%s\n' "${PREBUILD_LOG_POST_SHA256}"
    printf 'runner_sha256=%s\n' "${RUNNER_POST_SHA256}"
    printf 'execution_runner_sha256=%s\n' "${EXECUTION_RUNNER_SHA256}"
    printf 'test_plan_sha256=%s\n' "$(file_sha256 "${TEST_PLAN_PATH}")"
    printf 'config_sha256=%s\n' "$(file_sha256 "${UNARY_CONFIG_EVIDENCE}")"
    printf 'verfiles_sha256=%s\n' "$(file_sha256 "${UNARY_VERFILES}")"
    printf 'makefile_sha256=%s\n' "$(file_sha256 "${UNARY_MAKEFILE}")"
    printf 'binary_sha256=%s\n' "$(file_sha256 "${UNARY_BINARY}")"
    printf 'build_log_sha256=%s\n' "$(file_sha256 "${UNARY_BUILD_LOG}")"
    printf 'build_rc=0\n'
    printf 'run_log_sha256=%s\n' "$(file_sha256 "${UNARY_RUN_LOG}")"
    printf 'run_rc=0\n'
    printf 'pass_marker=[NPU-UNARY-GLU-ELEMENT][PASS]\n'
    printf 'pass_marker_count=%s\n' "${UNARY_PASS_COUNT}"
    printf 'fail_marker_count=%s\n' "${UNARY_FAIL_COUNT}"
    printf 'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal\n'
    printf 'cflags=-O3 -DNDEBUG -march=native\n'
    printf 'assertions=off\n'
    printf 'waveform=off\n'
    printf 'optimization=O3\n'
    printf 'source_hash_audit_sha256=%s\n' "$(file_sha256 "${SOURCE_HASH_AUDIT}")"
    printf 'marker_audit_sha256=%s\n' "$(file_sha256 "${MARKER_AUDIT}")"
    printf 'config_audit_sha256=%s\n' "$(file_sha256 "${CONFIG_AUDIT}")"
    printf 'warning_audit_sha256=%s\n' "$(file_sha256 "${WARNING_AUDIT}")"
    printf 'forbidden_audit_sha256=%s\n' "$(file_sha256 "${FORBIDDEN_AUDIT}")"
    printf 'cleanup_audit_sha256=%s\n' "$(file_sha256 "${CLEANUP_AUDIT_PATH}")"
    printf 'wave_core_audit_sha256=%s\n' "$(file_sha256 "${WAVE_AUDIT}")"
    if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
        printf 'repair_origin=%s\n' "${ATTEMPT02_NAME}"
        printf 'repair_legacy_source_pre_sha256=%s\n' \
            "$(file_sha256 "${ACTIVE_REPAIR_LEGACY_SOURCE_PRE}")"
        printf 'repair_legacy_source_post_sha256=%s\n' \
            "$(file_sha256 "${ACTIVE_REPAIR_LEGACY_SOURCE_POST}")"
        printf 'repair_legacy_source_equal=1\n'
        printf 'repair_attempt02_runner_sha256=%s\n' \
            "$(file_sha256 "${ATTEMPT02_LOG_ROOT}/run_npu_regression.sh.snapshot")"
        printf 'repair_attempt02_status_sha256=%s\n' \
            "$(file_sha256 "${ATTEMPT02_LOG_ROOT}/task-run.status")"
        printf 'repair_composite_audit_sha256=%s\n' \
            "$(file_sha256 "${REPAIR_COMPOSITE_AUDIT}")"
    fi
    if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
        printf 'unary_evidence_origin=%s\n' "${ATTEMPT03_NAME}"
        printf 'attempt03_status_sha256=%s\n' \
            "$(file_sha256 "${ATTEMPT03_LOG_ROOT}/task-run.status")"
        printf 'execution_test_plan_sha256=%s\n' \
            "$(file_sha256 "${EXECUTION_TEST_PLAN}")"
        printf 'source_parser_self_test_sha256=%s\n' \
            "$(file_sha256 "${SOURCE_PARSER_SELF_TEST_LOG}")"
        printf 'forbidden_audit_self_test_sha256=%s\n' \
            "$(file_sha256 "${FORBIDDEN_AUDIT_SELF_TEST_LOG}")"
        printf 'forbidden_audit_objects_sha256=%s\n' \
            "$(file_sha256 "${FORBIDDEN_OBJECTS_PATH}")"
        printf 'forbidden_audit_object_count=%d\n' \
            "${#FORBIDDEN_AUDIT_OBJECTS[@]}"
        printf 'seal_source_check_sha256=%s\n' \
            "$(file_sha256 "${SEAL_SOURCE_CHECK}")"
        printf 'attempt04_status_sha256=%s\n' \
            "$(file_sha256 "${ATTEMPT04_LOG_ROOT}/task-run.status")"
    fi
    printf 'bound_artifact_count=%d\n' "${#BOUND_ARTIFACTS[@]}"
    printf 'bound_manifest_sha256=%s\n' "${BOUND_MANIFEST_SHA256}"
    printf 'task_run_status_path=tmp/logs/npu-regression-v33/task-run.status\n'
    printf 'task_run_status_before_finalize=RUNNING\n'
} >"${RECEIPT_PATH}"

task_run_status_stage receipt-audit
receipt_audit_rc=0
{
    if sha256sum -c -- "${BOUND_MANIFEST}"; then
        printf 'bound_manifest_check=PASS\n'
    else
        printf 'bound_manifest_check=FAIL\n'
        receipt_audit_rc=1
    fi
    for required_receipt_line in \
        'schema=npu-unary-glu-element-regression-receipt-v1' \
        'test_index=33' \
        'tests_total=33' \
        'source_manifest_equal=1' \
        'generated_source_set_equal=1' \
        'build_rc=0' \
        'run_rc=0' \
        'pass_marker=[NPU-UNARY-GLU-ELEMENT][PASS]' \
        'pass_marker_count=1' \
        'fail_marker_count=0' \
        'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal' \
        'cflags=-O3 -DNDEBUG -march=native' \
        'assertions=off' \
        'waveform=off' \
        'optimization=O3' \
        'task_run_status_before_finalize=RUNNING'; do
        if ! grep -Fxq -- "${required_receipt_line}" "${RECEIPT_PATH}"; then
            printf 'missing_receipt_line=%s\n' "${required_receipt_line}"
            receipt_audit_rc=1
        fi
    done
    for required_mode_line in \
        "execution_mode=${RUN_MODE}" \
        "legacy_adopted_test_count=${LEGACY_ADOPTED_COUNT}"; do
        if ! grep -Fxq -- "${required_mode_line}" "${RECEIPT_PATH}"; then
            printf 'missing_receipt_mode_line=%s\n' "${required_mode_line}"
            receipt_audit_rc=1
        fi
    done
    if [[ "${REPAIR_COMPOSITE}" -eq 1 ]]; then
        for required_repair_line in \
            "repair_origin=${ATTEMPT02_NAME}" \
            'repair_legacy_source_equal=1'; do
            if ! grep -Fxq -- "${required_repair_line}" "${RECEIPT_PATH}"; then
                printf 'missing_repair_receipt_line=%s\n' \
                    "${required_repair_line}"
                receipt_audit_rc=1
            fi
        done
    fi
    if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
        for required_seal_line in \
            "execution_runner_sha256=${EXECUTION_RUNNER_SHA256}" \
            "unary_evidence_origin=${ATTEMPT03_NAME}" \
            'attempt03_unary_adopted_test_count=1' \
            'seal_verilator_execution_count=0' \
            'seal_tb_binary_execution_count=0' \
            'expected_project_source_count=36' \
            'generated_project_source_count=36' \
            'forbidden_audit_object_count=5'; do
            if ! grep -Fxq -- "${required_seal_line}" "${RECEIPT_PATH}"; then
                printf 'missing_seal_receipt_line=%s\n' "${required_seal_line}"
                receipt_audit_rc=1
            fi
        done
    fi
    while read -r source_hash source_path; do
        if ! grep -Fxq -- "source_sha256=${source_hash} path=${source_path}" \
             "${RECEIPT_PATH}"; then
            printf 'missing_source_binding=%s %s\n' \
                "${source_hash}" "${source_path}"
            receipt_audit_rc=1
        fi
    done <"${ACTIVE_SOURCE_MANIFEST_PRE}"
    printf 'receipt_audit_rc=%d\n' "${receipt_audit_rc}"
    if [[ "${receipt_audit_rc}" -eq 0 ]]; then
        printf 'receipt_audit=PASS\n'
    else
        printf 'receipt_audit=FAIL\n'
    fi
} >"${RECEIPT_AUDIT}" 2>&1
[[ "${receipt_audit_rc}" -eq 0 ]] \
    || die "unary final receipt audit failed: ${RECEIPT_AUDIT}"

sha256sum -- "${RECEIPT_PATH}" >"${RECEIPT_SHA256_PATH}"
task_run_status_stage final-evidence-audit
final_evidence_rc=0
{
    if ! sha256sum -c -- "${RECEIPT_SHA256_PATH}"; then
        final_evidence_rc=1
    fi
    for evidence_check in \
        "${SOURCE_HASH_AUDIT}:source_manifest_equal=1" \
        "${SOURCE_HASH_AUDIT}:generated_source_set_equal=1" \
        "${MARKER_AUDIT}:marker_audit_rc=0" \
        "${CONFIG_AUDIT}:config_audit_rc=0" \
        "${WARNING_AUDIT}:warning_audit_rc=0" \
        "${FORBIDDEN_AUDIT}:forbidden_audit_rc=0" \
        "${CLEANUP_AUDIT_PATH}:cleanup_result=PASS" \
        "${WAVE_AUDIT}:wave_audit_rc=0" \
        "${RECEIPT_AUDIT}:receipt_audit=PASS"; do
        evidence_path="${evidence_check%%:*}"
        evidence_marker="${evidence_check#*:}"
        if ! grep -Fxq -- "${evidence_marker}" "${evidence_path}"; then
            printf 'missing_evidence_marker=%s path=%s\n' \
                "${evidence_marker}" "${evidence_path}"
            final_evidence_rc=1
        fi
    done
    if [[ "${REPAIR_COMPOSITE}" -eq 1 ]] &&
       ! grep -Fxq -- 'repair_composite_audit=PASS' \
            "${REPAIR_COMPOSITE_AUDIT}"; then
        printf 'missing_evidence_marker=repair_composite_audit=PASS path=%s\n' \
            "${REPAIR_COMPOSITE_AUDIT}"
        final_evidence_rc=1
    fi
    if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
        for seal_evidence_check in \
            "${SOURCE_PARSER_SELF_TEST_LOG}:source_parser_self_test=PASS" \
            "${FORBIDDEN_AUDIT_SELF_TEST_LOG}:forbidden_audit_self_test=PASS" \
            "${SEAL_SOURCE_CHECK}:seal_source_check=PASS" \
            "${REPAIR_COMPOSITE_AUDIT}:seal_execution_shape=PASS" \
            "${REPAIR_COMPOSITE_AUDIT}:attempt03_unary_pass_preserved=PASS" \
            "${REPAIR_COMPOSITE_AUDIT}:attempt03_identity_preserved=PASS" \
            "${REPAIR_COMPOSITE_AUDIT}:attempt04_failure_preserved=PASS"; do
            seal_evidence_path="${seal_evidence_check%%:*}"
            seal_evidence_marker="${seal_evidence_check#*:}"
            if ! grep -Fxq -- "${seal_evidence_marker}" \
                    "${seal_evidence_path}"; then
                printf 'missing_seal_evidence_marker=%s path=%s\n' \
                    "${seal_evidence_marker}" "${seal_evidence_path}"
                final_evidence_rc=1
            fi
        done
    fi
    if ! grep -Fxq -- RUNNING "${STATUS_PATH}"; then
        printf 'status_before_finalize_not_running=1\n'
        final_evidence_rc=1
    fi
    printf 'final_evidence_rc=%d\n' "${final_evidence_rc}"
    if [[ "${final_evidence_rc}" -eq 0 ]]; then
        printf 'final_evidence=PASS\n'
    else
        printf 'final_evidence=FAIL\n'
    fi
} >"${FINAL_EVIDENCE_AUDIT}" 2>&1
[[ "${final_evidence_rc}" -eq 0 ]] \
    || die "final evidence closure failed: ${FINAL_EVIDENCE_AUDIT}"

if [[ "${SEAL_EXISTING}" -eq 1 ]]; then
    printf '[NPU-REGRESSION] seal execution verilator=0 tb_binary=0 adopted_legacy=32 adopted_unary=1 source_set=36\n'
fi
task_run_status_stage evidence-complete
task_run_status_mark_evidence_complete
printf '%s\n' "${FINAL_PASS_MARKER}"
