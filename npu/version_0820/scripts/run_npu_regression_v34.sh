#!/usr/bin/env bash

set -Eeuo pipefail

# v34-v6 是对 v4/v5 两个 fail-closed attempt 的复合恢复：decoder 的唯一
# Verilator build来自v4且TB PASS来自v5；mm2的唯一Verilator build来自v5，
# v6只首次运行mm2 binary；DMA/coprocessor各fresh build/run一次。其余29项
# 采用v33，tensor采用fixed-3。最终PASS只能在multi-attempt、transitive
# source、receipt、current-state post和final status binding全部闭合后输出。

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly WORKSPACE_ROOT="$(cd -- "${PROJECT_ROOT}/../.." && pwd -P)"
readonly TASK_RUN_STATUS_HELPER="${WORKSPACE_ROOT}/scripts/task-run-status.sh"
readonly TASK_RUN_STATUS_TEST="${WORKSPACE_ROOT}/scripts/tests/test-task-run-status.sh"
readonly V5_CONTRACT="${WORKSPACE_ROOT}/npu/version_0820/tmp/contracts/unary-glu-tensor-regression-v34-v5.json"
readonly V5_CONTRACT_SHA256=0774c352f3ec2ed949cae6924711e202043f1eb22202b7e9d19384b6578258b0
readonly V6_CONTRACT="${WORKSPACE_ROOT}/npu/version_0820/tmp/contracts/unary-glu-tensor-regression-v34-v6.json"
readonly V6_CONTRACT_SHA256=90ceae55dbc7afcc6b84fe2730916757d7629a1e011223d3c30399e3ea1aad02
readonly RUN_TIMEOUT_SECONDS="${NPU_REGRESSION_V34_TIMEOUT_SECONDS:-20}"
readonly FINAL_PASS_MARKER='[NPU-REGRESSION][PASS] tests=34 assertions=off waveform=off optimization=O3'

die() {
    printf '[NPU-REGRESSION-V34][FAIL] %s\n' "$*" >&2
    exit 1
}

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
readonly BUILD_CONTAINER="$(project_tmp_path "${TMP_ROOT}/build/npu-regression-v34")"
readonly LOG_CONTAINER="$(project_tmp_path "${TMP_ROOT}/logs/npu-regression-v34")"
readonly CACHE_CONTAINER="$(project_tmp_path "${TMP_ROOT}/cache/npu-regression-v34")"
readonly COMPILER_CONTAINER="$(project_tmp_path "${TMP_ROOT}/compiler/npu-regression-v34")"
readonly BUILD_ROOT="$(project_tmp_path "${BUILD_CONTAINER}/v6")"
readonly LOG_ROOT="$(project_tmp_path "${LOG_CONTAINER}/v6")"
readonly CACHE_ROOT="$(project_tmp_path "${CACHE_CONTAINER}/v6")"
readonly COMPILER_TMP_ROOT="$(project_tmp_path "${COMPILER_CONTAINER}/v6")"
readonly PREFLIGHT_LOG_ROOT="$(project_tmp_path "${LOG_CONTAINER}/v6-preflight")"
readonly PREFLIGHT_COMPILER_ROOT="$(project_tmp_path "${COMPILER_CONTAINER}/v6-preflight")"
readonly PREFLIGHT_SELF_TEST_AUDIT="$(project_tmp_path "${PREFLIGHT_LOG_ROOT}/self-test-audit.log")"
readonly PREFLIGHT_RUNNER_SHA="$(project_tmp_path "${PREFLIGHT_LOG_ROOT}/runner.sha256")"
readonly PREFLIGHT_RUNNER_SYNTAX="$(project_tmp_path "${PREFLIGHT_LOG_ROOT}/runner-bash-n.log")"
readonly PREFLIGHT_MANIFEST="$(project_tmp_path "${PREFLIGHT_LOG_ROOT}/preflight-artifacts.sha256")"
readonly PREFLIGHT_MANIFEST_CHECK="$(project_tmp_path "${PREFLIGHT_LOG_ROOT}/preflight-artifacts.check.log")"
readonly V4_ATTEMPT_ROOT="$(project_tmp_path "${LOG_CONTAINER}/attempt-v4-fail")"
readonly V4_ATTEMPT_MANIFEST="$(project_tmp_path "${V4_ATTEMPT_ROOT}/attempt-artifacts.sha256")"
readonly V4_ATTEMPT_MANIFEST_CHECK="$(project_tmp_path "${V4_ATTEMPT_ROOT}/attempt-artifacts.check.log")"
readonly V4_ATTEMPT_COMPOSITE_SEAL="$(project_tmp_path "${V4_ATTEMPT_ROOT}/attempt-composite-seal.sha256")"
readonly V4_ATTEMPT_COMPOSITE_CHECK="$(project_tmp_path "${V4_ATTEMPT_ROOT}/attempt-composite-seal.check.log")"
readonly V4_ATTEMPT_RUNNER="$(project_tmp_path "${V4_ATTEMPT_ROOT}/run_npu_regression_v34.v4.sh")"
readonly V4_STATUS="$(project_tmp_path "${LOG_CONTAINER}/task-run.status")"
readonly V4_CLEANUP_AUDIT="$(project_tmp_path "${LOG_CONTAINER}/cleanup-audit.log")"
readonly V4_FRESH_LOG_ROOT="$(project_tmp_path "${LOG_CONTAINER}/fresh")"
readonly V4_DECODER_BUILD_ROOT="$(project_tmp_path "${BUILD_CONTAINER}/tb_decoder_regfile")"
readonly V4_DECODER_BINARY="$(project_tmp_path "${V4_DECODER_BUILD_ROOT}/Vtb_decoder_regfile")"
readonly V4_DECODER_VERFILES="$(project_tmp_path "${V4_DECODER_BUILD_ROOT}/Vtb_decoder_regfile__verFiles.dat")"
readonly V4_DECODER_MAKEFILE="$(project_tmp_path "${V4_DECODER_BUILD_ROOT}/Vtb_decoder_regfile.mk")"
readonly V4_DECODER_BUILD_LOG="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.build.log")"
readonly V4_DECODER_BUILD_RC="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.build.rc")"
readonly V4_DECODER_COMPILE_FILELIST="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.compile-filelist")"
readonly V4_DECODER_CONFIG="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.config")"
readonly V4_DECODER_EXPECTED_ACTUAL="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.expected-actual-sources.list")"
readonly V4_DECODER_SOURCE_PRE="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.sources.pre.sha256")"
readonly V4_DECODER_SOURCE_POST_BUILD="$(project_tmp_path "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.sources.post-build.sha256")"
readonly V5_ATTEMPT_ROOT="$(project_tmp_path "${LOG_CONTAINER}/attempt-v5-fail")"
readonly V5_ATTEMPT_MANIFEST="$(project_tmp_path "${V5_ATTEMPT_ROOT}/attempt-artifacts.sha256")"
readonly V5_ATTEMPT_MANIFEST_CHECK="$(project_tmp_path "${V5_ATTEMPT_ROOT}/attempt-artifacts.check.log")"
readonly V5_ATTEMPT_SEAL="$(project_tmp_path "${V5_ATTEMPT_ROOT}/attempt-seal.sha256")"
readonly V5_ATTEMPT_SEAL_CHECK="$(project_tmp_path "${V5_ATTEMPT_ROOT}/attempt-seal.check.log")"
readonly V5_ATTEMPT_RUNNER="$(project_tmp_path "${V5_ATTEMPT_ROOT}/run_npu_regression_v34.v5.sh")"
readonly V5_LOG_ROOT="$(project_tmp_path "${LOG_CONTAINER}/v5")"
readonly V5_BUILD_ROOT="$(project_tmp_path "${BUILD_CONTAINER}/v5")"
readonly V5_STATUS="$(project_tmp_path "${V5_LOG_ROOT}/task-run.status")"
readonly V5_CLEANUP_AUDIT="$(project_tmp_path "${V5_LOG_ROOT}/cleanup-audit.log")"
readonly V5_CURRENT_SOURCE_CANDIDATES="$(project_tmp_path "${V5_LOG_ROOT}/current-source-candidates.sha256")"
readonly V5_DECODER_RUN_LOG="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_decoder_regfile.run.log")"
readonly V5_DECODER_RUN_RC="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_decoder_regfile.run.rc")"
readonly V5_DECODER_SOURCE_POST_RUN="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_decoder_regfile.sources.post-run.sha256")"
readonly V5_DECODER_BINARY_PRE="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_decoder_regfile.binary.pre-run.sha256")"
readonly V5_DECODER_BINARY_POST="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_decoder_regfile.binary.post-run.sha256")"
readonly V5_DECODER_RESUME_AUDIT="$(project_tmp_path "${V5_LOG_ROOT}/decoder-resume-audit.log")"
readonly V5_MM2_BUILD_ROOT="$(project_tmp_path "${V5_BUILD_ROOT}/tb_mm2_engine")"
readonly V5_MM2_BINARY="$(project_tmp_path "${V5_MM2_BUILD_ROOT}/Vtb_mm2_engine")"
readonly V5_MM2_VERFILES="$(project_tmp_path "${V5_MM2_BUILD_ROOT}/Vtb_mm2_engine__verFiles.dat")"
readonly V5_MM2_MAKEFILE="$(project_tmp_path "${V5_MM2_BUILD_ROOT}/Vtb_mm2_engine.mk")"
readonly V5_MM2_BUILD_LOG="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.build.log")"
readonly V5_MM2_BUILD_RC="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.build.rc")"
readonly V5_MM2_COMPILE_FILELIST="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.compile-filelist")"
readonly V5_MM2_CONFIG="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.config")"
readonly V5_MM2_ACTUAL_SOURCES="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.actual-sources.list")"
readonly V5_MM2_SOURCE_PRE="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.sources.pre.sha256")"
readonly V5_MM2_SOURCE_POST_BUILD="$(project_tmp_path "${V5_LOG_ROOT}/fresh/tb_mm2_engine.sources.post-build.sha256")"
readonly FRESH_LOG_ROOT="$(project_tmp_path "${LOG_ROOT}/fresh")"
readonly ADOPT_LOG_ROOT="$(project_tmp_path "${LOG_ROOT}/adopted")"
readonly STATUS_PATH="$(project_tmp_path "${LOG_ROOT}/task-run.status")"
readonly CLEANUP_AUDIT_PATH="$(project_tmp_path "${LOG_ROOT}/cleanup-audit.log")"
readonly TEST_PLAN_PATH="$(project_tmp_path "${LOG_ROOT}/test-plan.log")"
readonly SELF_TEST_AUDIT="$(project_tmp_path "${LOG_ROOT}/self-test-audit.log")"
readonly V4_ATTEMPT_ADOPTION_AUDIT="$(project_tmp_path "${LOG_ROOT}/v4-attempt-adoption-audit.log")"
readonly DECODER_ADOPTION_AUDIT="$(project_tmp_path "${LOG_ROOT}/decoder-adoption-audit.log")"
readonly V5_ATTEMPT_ADOPTION_AUDIT="$(project_tmp_path "${LOG_ROOT}/v5-attempt-adoption-audit.log")"
readonly MM2_BUILD_ADOPTION_AUDIT="$(project_tmp_path "${LOG_ROOT}/mm2-build-adoption-audit.log")"
readonly MM2_RESUME_AUDIT="$(project_tmp_path "${LOG_ROOT}/mm2-resume-audit.log")"
readonly MULTI_ATTEMPT_AUDIT="$(project_tmp_path "${LOG_ROOT}/multi-attempt-audit.log")"
readonly V4_ATTEMPT_FINAL_CHECK="$(project_tmp_path "${LOG_ROOT}/v4-attempt-artifacts-final-check.log")"
readonly V5_ATTEMPT_FINAL_CHECK="$(project_tmp_path "${LOG_ROOT}/v5-attempt-artifacts-final-check.log")"
readonly V33_AUDIT="$(project_tmp_path "${LOG_ROOT}/v33-audit.log")"
readonly FRESH_SOURCE_MODEL_AUDIT="$(project_tmp_path "${LOG_ROOT}/fresh-source-model-audit.log")"
readonly TENSOR_AUDIT="$(project_tmp_path "${LOG_ROOT}/tensor-audit.log")"
readonly MARKER_AUDIT="$(project_tmp_path "${LOG_ROOT}/marker-audit.log")"
readonly CONFIG_AUDIT="$(project_tmp_path "${LOG_ROOT}/config-audit.log")"
readonly SOURCE_AUDIT="$(project_tmp_path "${LOG_ROOT}/source-audit.log")"
readonly WAVE_CORE_AUDIT="$(project_tmp_path "${LOG_ROOT}/wave-core-audit.log")"
readonly CURRENT_SOURCE_CANDIDATES="$(project_tmp_path "${LOG_ROOT}/current-source-candidates.sha256")"
readonly CURRENT_SOURCE_MANIFEST="$(project_tmp_path "${LOG_ROOT}/current-source-manifest.sha256")"
readonly CURRENT_SOURCE_FINAL_CHECK="$(project_tmp_path "${LOG_ROOT}/current-source-final-check.log")"
readonly V33_CURRENT_STATE_PRE="$(project_tmp_path "${LOG_ROOT}/v33-current-state.pre.sha256")"
readonly V33_CURRENT_STATE_POST="$(project_tmp_path "${LOG_ROOT}/v33-current-state.post.sha256")"
readonly V33_CURRENT_STATE_AUDIT="$(project_tmp_path "${LOG_ROOT}/v33-current-state-audit.log")"
readonly BOUND_ARTIFACT_MANIFEST="$(project_tmp_path "${LOG_ROOT}/bound-artifacts.sha256")"
readonly RECEIPT_PATH="$(project_tmp_path "${LOG_ROOT}/immutable-receipt.txt")"
readonly RECEIPT_SHA256_PATH="$(project_tmp_path "${LOG_ROOT}/immutable-receipt.sha256")"
readonly RECEIPT_AUDIT="$(project_tmp_path "${LOG_ROOT}/receipt-audit.log")"
readonly FINAL_EVIDENCE="$(project_tmp_path "${LOG_ROOT}/final-evidence.log")"
readonly FINAL_EVIDENCE_AUDIT="$(project_tmp_path "${LOG_ROOT}/final-evidence-audit.log")"
readonly FINAL_STATUS_BINDING="$(project_tmp_path "${LOG_ROOT}/final-status-binding.sha256")"
readonly FINAL_STATUS_BINDING_CHECK="$(project_tmp_path "${LOG_ROOT}/final-status-binding-check.log")"
readonly TASK_RUN_STATUS_TEST_LOG="$(project_tmp_path "${LOG_ROOT}/task-run-status-test.log")"
readonly TASK_RUN_STATUS_TEST_RC="$(project_tmp_path "${LOG_ROOT}/task-run-status-test.native.rc")"
readonly RUNNER_BASH_N_LOG="$(project_tmp_path "${LOG_ROOT}/runner-bash-n.log")"

readonly V33_LOG_ROOT="${PROJECT_ROOT}/tmp/logs/npu-regression-v33"
readonly V33_BUILD_ROOT="${PROJECT_ROOT}/tmp/build/npu-regression-v33"
readonly V33_ATTEMPT02_NAME='attempt-02-literal-force-release-fail'
readonly V33_ATTEMPT03_NAME='attempt-03-source-path-audit-fail'
readonly V33_ATTEMPT02_LOG="${V33_LOG_ROOT}/${V33_ATTEMPT02_NAME}"
readonly V33_ATTEMPT02_BUILD="${V33_BUILD_ROOT}/${V33_ATTEMPT02_NAME}"
readonly V33_ATTEMPT03_LOG="${V33_LOG_ROOT}/${V33_ATTEMPT03_NAME}"
readonly V33_ATTEMPT03_BUILD="${V33_BUILD_ROOT}/${V33_ATTEMPT03_NAME}"
readonly V33_RECEIPT="${V33_LOG_ROOT}/unary-glu-element.receipt"
readonly V33_RECEIPT_SHA="${V33_LOG_ROOT}/unary-glu-element.receipt.sha256"
readonly V33_BOUND_MANIFEST="${V33_LOG_ROOT}/unary-glu-element.bound-artifacts.sha256"
readonly V33_TEST_PLAN="${V33_LOG_ROOT}/test-plan.log"
readonly V33_FINAL_EVIDENCE_AUDIT="${V33_LOG_ROOT}/final-evidence-audit.log"
readonly V33_STATUS="${V33_LOG_ROOT}/task-run.status"
readonly V33_CONSOLE="${V33_LOG_ROOT}/seal-existing.console.log"
readonly V33_LEGACY_SOURCE_PRE="${V33_ATTEMPT03_LOG}/repair-legacy-sources.pre.sha256"
readonly V33_LEGACY_SOURCE_POST="${V33_ATTEMPT03_LOG}/repair-legacy-sources.post.sha256"

readonly TENSOR_LOG_ROOT="${PROJECT_ROOT}/tmp/logs/unary-glu-tensor-engine/repair-v1/fixed-3"
readonly TENSOR_BUILD_ROOT="${PROJECT_ROOT}/tmp/build/unary-glu-tensor-engine/repair-v1/fixed-3"
readonly TENSOR_RECEIPT="${TENSOR_LOG_ROOT}/immutable-receipt.txt"
readonly TENSOR_RECEIPT_SHA="${TENSOR_LOG_ROOT}/immutable-receipt.sha256"
readonly TENSOR_ARTIFACT_MANIFEST="${TENSOR_LOG_ROOT}/artifact-manifest.sha256"
readonly TENSOR_RUNNER_INPUT_MANIFEST="${TENSOR_LOG_ROOT}/runner-input-hashes.pre.sha256"
readonly TENSOR_SOURCE_PRE="${TENSOR_LOG_ROOT}/source-hashes.pre.sha256"
readonly TENSOR_SOURCE_POST_BUILD="${TENSOR_LOG_ROOT}/source-hashes.post-build.sha256"
readonly TENSOR_SOURCE_POST_RUN="${TENSOR_LOG_ROOT}/source-hashes.post-run.sha256"
readonly TENSOR_BUILD_ARTIFACTS="${TENSOR_LOG_ROOT}/build-artifacts.sha256"
readonly TENSOR_BINARY_PRE="${TENSOR_LOG_ROOT}/binary.pre-run.sha256"
readonly TENSOR_BINARY_POST="${TENSOR_LOG_ROOT}/binary.post-run.sha256"
readonly TENSOR_FINAL_BINDING="${TENSOR_LOG_ROOT}/final-status-binding.sha256"
readonly TENSOR_BINARY="${TENSOR_BUILD_ROOT}/obj_dir/Vtb_unary_glu_tensor_engine"

readonly -a EXPECTED_TESTS=(
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
    tb_unary_glu_tensor_engine
)

readonly -a EXPECTED_MARKERS=(
    '[NPU-DECODER-REGFILE][PASS]'
    '[NPU-LMEM][PASS]'
    '[NPU-MM2][PASS]'
    '[NPU-DMA][PASS]'
    '[NPU-COPROCESSOR][PASS]'
    '[NPU-Q8-DOT][PASS]'
    '[NPU-FP16-EXPAND][PASS]'
    '[NPU-I32-FP32][PASS]'
    '[NPU-FP32-ADDMUL][PASS]'
    '[NPU-FP32-DIV][PASS]'
    '[NPU-FP32-FP16][PASS]'
    '[NPU-FP32-I32-RMM][PASS]'
    '[NPU-Q8-SCALE-ACC][PASS]'
    '[NPU-Q8-QUANT][PASS]'
    '[NPU-Q8-GEMV][PASS]'
    '[NPU-Q8-DEQUANT][PASS]'
    '[NPU-Q8-GET-ROWS][PASS]'
    '[NPU-TENSOR-MOVER][PASS]'
    '[NPU-SET-ROWS][PASS]'
    '[NPU-FP32-SQRT][PASS]'
    '[NPU-FP32-FP64][PASS]'
    '[NPU-FP64-ADD][PASS]'
    '[NPU-FP64-FP32][PASS]'
    '[NPU-FP64-I32-RMM][PASS]'
    '[NPU-I32-FP64][PASS]'
    '[NPU-FP64-FMA][PASS]'
    '[NPU-FP32-SQUARE-SUM64][PASS]'
    '[NPU-FP64-POW2-SCALE][PASS]'
    '[NPU-NORM][PASS]'
    '[NPU-FP64-FP32-FINITE][PASS]'
    '[NPU-AOR-EXP32][PASS]'
    '[NPU-AOR-LOG32][PASS]'
    '[NPU-UNARY-GLU-ELEMENT][PASS]'
    '[NPU-UNARY-GLU-TENSOR][PASS]'
)

file_sha256() {
    local hash_line
    hash_line="$(sha256sum -- "$1")"
    printf '%s\n' "${hash_line%% *}"
}

require_exact_line() {
    local path="${1:?path is required}"
    local expected="${2:?expected line is required}"
    local count
    count="$(awk -v expected="${expected}" '$0 == expected { count++ } END { print count + 0 }' "${path}")"
    [[ "${count}" -eq 1 ]] || die "${path}: expected exact-one line: ${expected}; count=${count}"
}

count_pass_marker() {
    local test_name="${1:?test name is required}"
    local marker="${2:?marker is required}"
    local run_log="${3:?run log is required}"

    case "${test_name}" in
        tb_unary_glu_element|tb_unary_glu_tensor_engine)
            awk -v marker="${marker}" '$0 == marker { count++ } END { print count + 0 }' "${run_log}"
            ;;
        *)
            awk -v marker="${marker}" 'index($0, marker) == 1 { count++ } END { print count + 0 }' "${run_log}"
            ;;
    esac
}

read_single_rc() {
    local path="${1:?rc path is required}"
    local first
    local second
    [[ -f "${path}" ]] || die "missing rc file: ${path}"
    first="$(sed -n '1p' "${path}")"
    second="$(sed -n '2p' "${path}")"
    [[ "${first}" =~ ^[0-9]+$ && -z "${second}" ]] || die "invalid native rc file: ${path}"
    printf '%s\n' "${first}"
}

is_affected_index() {
    case "$1" in
        0|2|3|4) return 0 ;;
        *) return 1 ;;
    esac
}

is_new_fresh_index() {
    case "$1" in
        3|4) return 0 ;;
        *) return 1 ;;
    esac
}

normalize_workspace_path() {
    local input_path="${1:?input path is required}"
    local base_root="${2:?base root is required}"
    local canonical
    if [[ "${input_path}" == /* ]]; then
        canonical="$(realpath -m -- "${input_path}")"
    else
        canonical="$(realpath -m -- "${base_root}/${input_path}")"
    fi
    [[ "${canonical}" != "${WORKSPACE_ROOT}" && "${canonical}" == "${WORKSPACE_ROOT}/"* ]] \
        || die "path escapes workspace: ${input_path} -> ${canonical}"
    printf '%s\n' "${canonical}"
}

record_current_source() {
    local expected_hash="${1:?source hash is required}"
    local source_path="${2:?source path is required}"
    local base_root="${3:?base root is required}"
    local canonical
    local actual_hash
    canonical="$(normalize_workspace_path "${source_path}" "${base_root}")"
    [[ -f "${canonical}" ]] || die "current source missing: ${canonical}"
    actual_hash="$(file_sha256 "${canonical}")"
    [[ "${actual_hash}" == "${expected_hash}" ]] \
        || die "current source hash mismatch: ${canonical} expected=${expected_hash} actual=${actual_hash}"
    printf '%s  %s\n' "${actual_hash}" "${canonical}" >>"${CURRENT_SOURCE_CANDIDATES}"
}

append_bound_path() {
    local input_path="${1:?bound path is required}"
    local base_root="${2:-${WORKSPACE_ROOT}}"
    local canonical
    canonical="$(normalize_workspace_path "${input_path}" "${base_root}")"
    [[ -f "${canonical}" ]] || die "bound artifact missing: ${canonical}"
    BOUND_PATHS+=("${canonical}")
}

extract_command_sources() {
    local verfiles="${1:?verFiles path is required}"
    local output="${2:?output path is required}"
    local command_count
    command_count="$(awk '$1 == "C" { count++ } END { print count + 0 }' "${verfiles}")"
    [[ "${command_count}" -eq 1 ]] || return 1
    awk '
        $1 == "C" {
            line = $0
            sub(/^C "/, "", line)
            sub(/"$/, "", line)
            count = split(line, token, /[[:space:]]+/)
            for (field_i = 1; field_i <= count; field_i++) {
                if (token[field_i] ~ /^(rtl|tests|third_party)\/.*\.(v|sv)$/) {
                    print token[field_i]
                }
            }
        }
    ' "${verfiles}" >"${output}"
    [[ -s "${output}" ]]
}

extract_actual_project_sources() {
    local verfiles="${1:?verFiles path is required}"
    local output="${2:?output path is required}"
    local line
    local raw_path
    local canonical
    local relative_path
    local external_key
    local source_count=0
    declare -A seen_sources=()
    declare -A seen_external=()

    [[ -s "${verfiles}" ]] || return 1
    : >"${output}"
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" == S\ * ]] || continue
        [[ "${line}" == *\" ]] || return 1
        raw_path="${line%\"}"
        raw_path="${raw_path##*\"}"
        [[ -n "${raw_path}" ]] || return 1
        case "${raw_path}" in
            /usr/bin/verilator_bin|/usr/share/verilator/include/verilated_std.sv)
                external_key="${raw_path}"
                [[ -f "${external_key}" ]] || return 1
                [[ -z "${seen_external[${external_key}]+present}" ]] || return 1
                seen_external["${external_key}"]=1
                ;;
            "${PROJECT_ROOT}")
                return 1
                ;;
            "${PROJECT_ROOT}/"*)
                canonical="$(realpath -m -- "${raw_path}")" || return 1
                [[ "${canonical}" == "${PROJECT_ROOT}/"* && -f "${canonical}" ]] || return 1
                relative_path="${canonical#"${PROJECT_ROOT}/"}"
                case "${relative_path}" in
                    rtl/*|tests/*|third_party/*) ;;
                    *) return 1 ;;
                esac
                [[ -z "${seen_sources[${relative_path}]+present}" ]] || return 1
                seen_sources["${relative_path}"]=1
                printf '%s\n' "${relative_path}" >>"${output}"
                source_count=$((source_count + 1))
                ;;
            rtl/*|tests/*|third_party/*)
                canonical="$(realpath -m -- "${PROJECT_ROOT}/${raw_path}")" || return 1
                [[ "${canonical}" == "${PROJECT_ROOT}/"* && -f "${canonical}" ]] || return 1
                [[ -z "${seen_sources[${raw_path}]+present}" ]] || return 1
                seen_sources["${raw_path}"]=1
                printf '%s\n' "${raw_path}" >>"${output}"
                source_count=$((source_count + 1))
                ;;
            *)
                return 1
                ;;
        esac
    done <"${verfiles}"
    [[ "${source_count}" -gt 0 && "${#seen_external[@]}" -eq 2 ]] || return 1
    LC_ALL=C sort -u -o "${output}" "${output}"
}

compare_exact_set() {
    local expected="${1:?expected list is required}"
    local actual="${2:?actual list is required}"
    cmp -s \
        <(LC_ALL=C sort -u -- "${expected}") \
        <(LC_ALL=C sort -u -- "${actual}")
}

validate_generated_config() {
    local verfiles="${1:?verFiles path is required}"
    local makefile="${2:?makefile path is required}"
    local command_line
    command_line="$(awk '$1 == "C" { print; exit }' "${verfiles}")"
    [[ "${command_line}" == *'--binary --timing --sv -O3 -Wall -Wno-fatal'* ]] || return 1
    [[ "${command_line}" == *'-O3 -DNDEBUG -march=native'* ]] || return 1
    [[ "${command_line}" != *'--assert'* &&
       "${command_line}" != *'--trace'* &&
       "${command_line}" != *'--coverage'* ]] || return 1
    grep -Fq -- '-O3 -DNDEBUG -march=native' "${makefile}"
}

run_self_tests() {
    local audit_path="${1:-${SELF_TEST_AUDIT}}"
    local fixture_parent="${2:-${COMPILER_TMP_ROOT}}"
    local fixture="${fixture_parent}/self-tests"
    local marker='[NPU-V34-SELFTEST][PASS]'
    local marker_good
    local marker_suffix
    local marker_duplicate
    local marker_midline
    local parser_rc=0
    local command_parser_rc=0
    local current_state_rejected=0
    local adopted_build_rejected=0
    local omitted_transitive_rejected=0
    local complete_transitive_accepted=0
    local fresh_target_model_rc=0

    [[ ! -e "${fixture}" ]] || return 1
    mkdir -- "${fixture}"
    printf '%s\n' "${marker}" >"${fixture}/marker-good.log"
    printf '%s suffix\n' "${marker}" >"${fixture}/marker-suffix.log"
    printf '%s one\n%s two\n' "${marker}" "${marker}" >"${fixture}/marker-duplicate.log"
    printf 'prefix %s\n' "${marker}" >"${fixture}/marker-midline.log"
    marker_good="$(count_pass_marker tb_unary_glu_tensor_engine "${marker}" "${fixture}/marker-good.log")"
    marker_suffix="$(count_pass_marker tb_unary_glu_tensor_engine "${marker}" "${fixture}/marker-suffix.log")"
    marker_duplicate="$(count_pass_marker legacy "${marker}" "${fixture}/marker-duplicate.log")"
    marker_midline="$(count_pass_marker legacy "${marker}" "${fixture}/marker-midline.log")"
    [[ "${marker_good}" -eq 1 && "${marker_suffix}" -eq 0 &&
       "${marker_duplicate}" -eq 2 && "${marker_midline}" -eq 0 ]] || return 1

    {
        printf 'C "--binary --timing --sv -O3 -Wall -Wno-fatal -CFLAGS -O3 -DNDEBUG -march=native tests/tb_local_memory.sv rtl/TensorNpuLocalMemory.v"\n'
        printf 'S 1 1 1 1 1 1 "/usr/bin/verilator_bin"\n'
        printf 'S 1 1 1 1 1 1 "/usr/share/verilator/include/verilated_std.sv"\n'
        printf 'S 1 1 1 1 1 1 "tests/tb_local_memory.sv"\n'
        printf 'S 1 1 1 1 1 1 "%s/rtl/TensorNpuLocalMemory.v"\n' "${PROJECT_ROOT}"
    } >"${fixture}/parser-good.dat"
    printf '%s\n' tests/tb_local_memory.sv rtl/TensorNpuLocalMemory.v \
        >"${fixture}/parser-command.expected"
    if ! extract_command_sources \
        "${fixture}/parser-good.dat" "${fixture}/parser-command.actual" ||
       ! cmp -s -- "${fixture}/parser-command.expected" "${fixture}/parser-command.actual"; then
        command_parser_rc=1
    fi
    extract_actual_project_sources "${fixture}/parser-good.dat" "${fixture}/parser-good.list" || parser_rc=1
    printf '%s\n' rtl/TensorNpuLocalMemory.v tests/tb_local_memory.sv \
        >"${fixture}/parser-good.expected"
    cmp -s -- "${fixture}/parser-good.expected" "${fixture}/parser-good.list" || parser_rc=1

    sed -n '1,99999p' "${fixture}/parser-good.dat" >"${fixture}/parser-duplicate.dat"
    printf 'S 1 1 1 1 1 1 "%s/tests/tb_local_memory.sv"\n' "${PROJECT_ROOT}" \
        >>"${fixture}/parser-duplicate.dat"
    if extract_actual_project_sources \
        "${fixture}/parser-duplicate.dat" "${fixture}/parser-duplicate.list"; then
        parser_rc=1
    fi

    for rejection_case in missing unknown project-root outside-root; do
        {
            printf 'S 1 1 1 1 1 1 "/usr/bin/verilator_bin"\n'
            printf 'S 1 1 1 1 1 1 "/usr/share/verilator/include/verilated_std.sv"\n'
            case "${rejection_case}" in
                missing)
                    printf 'S 1 1 1 1 1 1 "tests/__npu_v34_missing__.sv"\n'
                    ;;
                unknown)
                    printf 'S 1 1 1 1 1 1 "docs/UNARY_GLU_TENSOR_RTL_CONTRACT.md"\n'
                    ;;
                project-root)
                    printf 'S 1 1 1 1 1 1 "%s"\n' "${PROJECT_ROOT}"
                    ;;
                outside-root)
                    printf 'S 1 1 1 1 1 1 "/tmp/npu-v34-outside-root.sv"\n'
                    ;;
            esac
        } >"${fixture}/parser-${rejection_case}.dat"
        if extract_actual_project_sources \
            "${fixture}/parser-${rejection_case}.dat" \
            "${fixture}/parser-${rejection_case}.list"; then
            parser_rc=1
        fi
    done
    [[ "${parser_rc}" -eq 0 && "${command_parser_rc}" -eq 0 ]] || return 1

    printf 'stable\n' >"${fixture}/current-state.txt"
    sha256sum "${fixture}/current-state.txt" >"${fixture}/current-state.sha256"
    printf 'mutated\n' >"${fixture}/current-state.txt"
    if ! sha256sum -c -- "${fixture}/current-state.sha256" >/dev/null 2>&1; then
        current_state_rejected=1
    fi
    [[ "${current_state_rejected}" -eq 1 ]] || return 1

    printf 'adopted-build-stable\n' >"${fixture}/adopted-build.bin"
    sha256sum "${fixture}/adopted-build.bin" >"${fixture}/adopted-build.sha256"
    printf 'adopted-build-mutated\n' >"${fixture}/adopted-build.bin"
    if ! sha256sum -c -- "${fixture}/adopted-build.sha256" >/dev/null 2>&1; then
        adopted_build_rejected=1
    fi
    [[ "${adopted_build_rejected}" -eq 1 ]] || return 1

    printf '%s\n' \
        rtl/TensorNpuMm2Engine.v \
        rtl/tensor_npu_defs.vh \
        tests/tb_mm2_engine.sv \
        >"${fixture}/transitive-incomplete.expected"
    printf '%s\n' \
        rtl/TensorNpuLocalMemory.v \
        rtl/TensorNpuMm2Engine.v \
        rtl/tensor_npu_defs.vh \
        tests/tb_mm2_engine.sv \
        >"${fixture}/transitive-complete.expected"
    sed -n '1,99999p' "${fixture}/transitive-complete.expected" \
        >"${fixture}/transitive-actual.list"
    if ! compare_exact_set \
        "${fixture}/transitive-incomplete.expected" "${fixture}/transitive-actual.list"; then
        omitted_transitive_rejected=1
    fi
    if compare_exact_set \
        "${fixture}/transitive-complete.expected" "${fixture}/transitive-actual.list" &&
       rg -Fxq -- 'rtl/TensorNpuLocalMemory.v' "${fixture}/transitive-actual.list"; then
        complete_transitive_accepted=1
    fi
    [[ "${omitted_transitive_rejected}" -eq 1 &&
       "${complete_transitive_accepted}" -eq 1 ]] || return 1

    {
        printf 'C "--binary --timing --sv -O3 -Wall -Wno-fatal -CFLAGS -O3 -DNDEBUG -march=native tests/tb_dma_engine.sv rtl/TensorNpuDmaEngine.v"\n'
        printf 'S 1 1 1 1 1 1 "/usr/bin/verilator_bin"\n'
        printf 'S 1 1 1 1 1 1 "/usr/share/verilator/include/verilated_std.sv"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuDmaEngine.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuLocalMemory.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/tensor_npu_defs.vh"\n'
        printf 'S 1 1 1 1 1 1 "tests/tb_dma_engine.sv"\n'
    } >"${fixture}/fresh-dma.dat"
    printf '%s\n' tests/tb_dma_engine.sv rtl/TensorNpuDmaEngine.v \
        >"${fixture}/fresh-dma.command.expected"
    printf '%s\n' \
        rtl/TensorNpuDmaEngine.v rtl/TensorNpuLocalMemory.v \
        rtl/tensor_npu_defs.vh tests/tb_dma_engine.sv | LC_ALL=C sort \
        >"${fixture}/fresh-dma.actual.expected"
    extract_command_sources "${fixture}/fresh-dma.dat" \
        "${fixture}/fresh-dma.command.actual" || fresh_target_model_rc=1
    extract_actual_project_sources "${fixture}/fresh-dma.dat" \
        "${fixture}/fresh-dma.actual.actual" || fresh_target_model_rc=1
    cmp -s -- "${fixture}/fresh-dma.command.expected" \
        "${fixture}/fresh-dma.command.actual" || fresh_target_model_rc=1
    compare_exact_set "${fixture}/fresh-dma.actual.expected" \
        "${fixture}/fresh-dma.actual.actual" || fresh_target_model_rc=1
    if compare_exact_set "${fixture}/fresh-dma.command.expected" \
        "${fixture}/fresh-dma.actual.actual"; then
        fresh_target_model_rc=1
    fi

    {
        printf 'C "--binary --timing --sv -O3 -Wall -Wno-fatal -CFLAGS -O3 -DNDEBUG -march=native tests/tb_coprocessor.sv rtl/TensorNpuCoprocessor.v rtl/TensorNpuCommandDecoder.v rtl/TensorNpuRegisterFile.v rtl/TensorNpuMm2Engine.v rtl/TensorNpuDmaEngine.v rtl/TensorNpuLocalMemory.v"\n'
        printf 'S 1 1 1 1 1 1 "/usr/bin/verilator_bin"\n'
        printf 'S 1 1 1 1 1 1 "/usr/share/verilator/include/verilated_std.sv"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuCommandDecoder.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuCoprocessor.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuDmaEngine.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuLocalMemory.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuMm2Engine.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/TensorNpuRegisterFile.v"\n'
        printf 'S 1 1 1 1 1 1 "rtl/tensor_npu_defs.vh"\n'
        printf 'S 1 1 1 1 1 1 "tests/tb_coprocessor.sv"\n'
    } >"${fixture}/fresh-coprocessor.dat"
    printf '%s\n' \
        tests/tb_coprocessor.sv rtl/TensorNpuCoprocessor.v \
        rtl/TensorNpuCommandDecoder.v rtl/TensorNpuRegisterFile.v \
        rtl/TensorNpuMm2Engine.v rtl/TensorNpuDmaEngine.v \
        rtl/TensorNpuLocalMemory.v \
        >"${fixture}/fresh-coprocessor.command.expected"
    printf '%s\n' \
        tests/tb_coprocessor.sv rtl/TensorNpuCoprocessor.v \
        rtl/TensorNpuCommandDecoder.v rtl/TensorNpuRegisterFile.v \
        rtl/TensorNpuMm2Engine.v rtl/TensorNpuDmaEngine.v \
        rtl/TensorNpuLocalMemory.v rtl/tensor_npu_defs.vh | LC_ALL=C sort \
        >"${fixture}/fresh-coprocessor.actual.expected"
    extract_command_sources "${fixture}/fresh-coprocessor.dat" \
        "${fixture}/fresh-coprocessor.command.actual" || fresh_target_model_rc=1
    extract_actual_project_sources "${fixture}/fresh-coprocessor.dat" \
        "${fixture}/fresh-coprocessor.actual.actual" || fresh_target_model_rc=1
    cmp -s -- "${fixture}/fresh-coprocessor.command.expected" \
        "${fixture}/fresh-coprocessor.command.actual" || fresh_target_model_rc=1
    compare_exact_set "${fixture}/fresh-coprocessor.actual.expected" \
        "${fixture}/fresh-coprocessor.actual.actual" || fresh_target_model_rc=1
    if compare_exact_set "${fixture}/fresh-coprocessor.command.expected" \
        "${fixture}/fresh-coprocessor.actual.actual"; then
        fresh_target_model_rc=1
    fi
    [[ "${fresh_target_model_rc}" -eq 0 ]] || return 1

    {
        printf 'marker_good_count=%s\n' "${marker_good}"
        printf 'marker_suffix_count=%s expected=0\n' "${marker_suffix}"
        printf 'marker_duplicate_count=%s expected=2\n' "${marker_duplicate}"
        printf 'marker_midline_count=%s expected=0\n' "${marker_midline}"
        printf 'command_source_parser_local_awk=PASS\n'
        printf 'source_parser_relative_s_accepted=1\n'
        printf 'source_parser_absolute_s_accepted=1\n'
        printf 'source_parser_duplicate_rejected=1\n'
        printf 'source_parser_missing_rejected=1\n'
        printf 'source_parser_unknown_rejected=1\n'
        printf 'source_parser_project_root_rejected=1\n'
        printf 'source_parser_outside_root_rejected=1\n'
        printf 'current_state_mutation_rejected=1\n'
        printf 'adopted_build_mutation_rejected=1\n'
        printf 'omitted_transitive_source_rejected=1\n'
        printf 'complete_transitive_source_set_accepted=1\n'
        printf 'fresh_dma_command_actual_model=PASS\n'
        printf 'fresh_coprocessor_command_actual_model=PASS\n'
        printf 'self_test=PASS\n'
    } >"${audit_path}"
    rm -rf -- "${fixture}"
}

run_preflight_only() {
    local compiler_entry=''

    [[ ! -e "${PREFLIGHT_LOG_ROOT}" && ! -e "${PREFLIGHT_COMPILER_ROOT}" ]] \
        || die "stale v6 preflight output exists"
    [[ "$(file_sha256 "${V6_CONTRACT}")" == "${V6_CONTRACT_SHA256}" ]] \
        || die "v6 contract identity mismatch"
    mkdir -p -- "${PREFLIGHT_LOG_ROOT}" "${PREFLIGHT_COMPILER_ROOT}"
    bash -n -- "${SCRIPT_DIR}/run_npu_regression_v34.sh" \
        >"${PREFLIGHT_RUNNER_SYNTAX}" 2>&1 \
        || die "v6 preflight runner syntax failed"
    sha256sum -- "${SCRIPT_DIR}/run_npu_regression_v34.sh" >"${PREFLIGHT_RUNNER_SHA}"
    run_self_tests "${PREFLIGHT_SELF_TEST_AUDIT}" "${PREFLIGHT_COMPILER_ROOT}" \
        || die "v6 preflight parser/marker/current-state/adopted-build/transitive self-test failed"
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'command_source_parser_local_awk=PASS'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_relative_s_accepted=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_absolute_s_accepted=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_duplicate_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_missing_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_unknown_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_project_root_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'source_parser_outside_root_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'adopted_build_mutation_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'omitted_transitive_source_rejected=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'complete_transitive_source_set_accepted=1'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'fresh_dma_command_actual_model=PASS'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'fresh_coprocessor_command_actual_model=PASS'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'self_test=PASS'
    compiler_entry="$(find "${PREFLIGHT_COMPILER_ROOT}" -mindepth 1 -print -quit)"
    [[ -z "${compiler_entry}" ]] || die "v6 preflight compiler cleanup failed"
    {
        printf 'compiler_entries_after_cleanup=0\n'
        printf 'cleanup_rc=0\n'
        printf 'cleanup_result=PASS\n'
    } >"${PREFLIGHT_LOG_ROOT}/cleanup-audit.log"
    printf 'PASS\n' >"${PREFLIGHT_LOG_ROOT}/preflight.status"
    sha256sum -- \
        "${V6_CONTRACT}" \
        "${SCRIPT_DIR}/run_npu_regression_v34.sh" \
        "${PREFLIGHT_RUNNER_SHA}" \
        "${PREFLIGHT_RUNNER_SYNTAX}" \
        "${PREFLIGHT_SELF_TEST_AUDIT}" \
        "${PREFLIGHT_LOG_ROOT}/cleanup-audit.log" \
        "${PREFLIGHT_LOG_ROOT}/preflight.status" \
        >"${PREFLIGHT_MANIFEST}"
    sha256sum -c -- "${PREFLIGHT_MANIFEST}" >"${PREFLIGHT_MANIFEST_CHECK}" 2>&1 \
        || die "v6 preflight artifact binding failed"
    printf '[NPU-REGRESSION-V34-V6][PREFLIGHT-PASS] runner_sha256=%s verilator=2 tb=1 fresh_complete=1 adopted_v33=1 tensor=0\n' \
        "$(file_sha256 "${SCRIPT_DIR}/run_npu_regression_v34.sh")"
}

validate_preflight_binding() {
    [[ "$(file_sha256 "${V6_CONTRACT}")" == "${V6_CONTRACT_SHA256}" ]] \
        || die "v6 contract identity drift"
    sha256sum -c -- "${PREFLIGHT_MANIFEST}" \
        >"${LOG_ROOT}/preflight-live-check.log" 2>&1 \
        || die "v6 preflight artifact drift"
    sha256sum -c -- "${PREFLIGHT_RUNNER_SHA}" \
        >"${LOG_ROOT}/preflight-runner-live-check.log" 2>&1 \
        || die "v6 runner differs from preflight identity"
    require_exact_line "${PREFLIGHT_LOG_ROOT}/preflight.status" 'PASS'
    require_exact_line "${PREFLIGHT_SELF_TEST_AUDIT}" 'self_test=PASS'
    for preflight_path in \
        "${PREFLIGHT_RUNNER_SHA}" "${PREFLIGHT_RUNNER_SYNTAX}" \
        "${PREFLIGHT_SELF_TEST_AUDIT}" "${PREFLIGHT_MANIFEST}" \
        "${PREFLIGHT_MANIFEST_CHECK}" "${PREFLIGHT_LOG_ROOT}/cleanup-audit.log" \
        "${PREFLIGHT_LOG_ROOT}/preflight.status" "${LOG_ROOT}/preflight-live-check.log" \
        "${LOG_ROOT}/preflight-runner-live-check.log"; do
        append_bound_path "${preflight_path}"
    done
}

ACTIVE_PID=''
RUNNER_MAIN_COMPLETE=0
RUNNER_CLEANUP_DONE=0
VERILATOR_EXECUTION_COUNT=0
TB_BINARY_EXECUTION_COUNT=0
FRESH_V33_COUNT=0
ADOPTED_V33_COUNT=0
ADOPTED_TENSOR_COUNT=0
ADOPTED_DECODER_BUILD_COUNT=0
ADOPTED_DECODER_TB_COUNT=0
ADOPTED_MM2_BUILD_COUNT=0
RESUMED_MM2_TB_COUNT=0
NEW_VERILATOR_EXECUTION_COUNT=0
NEW_TB_BINARY_EXECUTION_COUNT=0
FINISH_CLEANUP_RC=0
BOUND_PATHS=()

run_logged() {
    local output_path="${1:?output path is required}"
    shift
    local command_rc
    set -m
    "$@" >"${output_path}" 2>&1 &
    ACTIVE_PID=$!
    if wait "${ACTIVE_PID}"; then
        command_rc=0
    else
        command_rc=$?
    fi
    ACTIVE_PID=''
    set +m
    return "${command_rc}"
}

stop_active_process_group() {
    local cleanup_rc=0
    if [[ -n "${ACTIVE_PID}" ]] && kill -0 "${ACTIVE_PID}" 2>/dev/null; then
        kill -TERM -- "-${ACTIVE_PID}" 2>/dev/null || \
            kill -TERM "${ACTIVE_PID}" 2>/dev/null || cleanup_rc=91
        wait "${ACTIVE_PID}" 2>/dev/null || true
        if kill -0 "${ACTIVE_PID}" 2>/dev/null; then
            cleanup_rc=92
        fi
    fi
    ACTIVE_PID=''
    return "${cleanup_rc}"
}

cleanup_transients() {
    local cleanup_rc=0
    local cache_entry=''
    local compiler_entry=''
    if [[ "${CACHE_ROOT}" != "${PROJECT_ROOT}/tmp/cache/npu-regression-v34/v6" ||
          "${COMPILER_TMP_ROOT}" != "${PROJECT_ROOT}/tmp/compiler/npu-regression-v34/v6" ]]; then
        printf 'cleanup_result=FAIL reason=canonical-path-mismatch\n' >"${CLEANUP_AUDIT_PATH}"
        return 1
    fi
    stop_active_process_group || cleanup_rc=$?
    if [[ "${cleanup_rc}" -eq 0 ]]; then
        rm -rf -- "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" || cleanup_rc=$?
    fi
    if [[ "${cleanup_rc}" -eq 0 ]]; then
        mkdir -p -- "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" || cleanup_rc=$?
    fi
    if [[ "${cleanup_rc}" -eq 0 ]]; then
        cache_entry="$(find "${CACHE_ROOT}" -mindepth 1 -print -quit)"
        compiler_entry="$(find "${COMPILER_TMP_ROOT}" -mindepth 1 -print -quit)"
        [[ -z "${cache_entry}" && -z "${compiler_entry}" ]] || cleanup_rc=1
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

runner_note_signal() {
    local signal_name="${1:?signal name is required}"
    local signal_rc="${2:?signal return code is required}"
    TASK_RUN_STATUS_SIGNAL="${signal_name}"
    TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
    stop_active_process_group || true
    exit "${signal_rc}"
}

finish_signal() {
    local signal_name="${1:?signal name is required}"
    local signal_rc="${2:?signal return code is required}"
    trap - HUP INT TERM
    TASK_RUN_STATUS_SIGNAL="${signal_name}"
    TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
    task_run_status_stage "finalize-signal-${signal_name}"
    task_run_status_finalize "${signal_rc}" "${FINISH_CLEANUP_RC}" || true
    exit "${signal_rc}"
}

write_v33_current_state_post() {
    sha256sum -- \
        "${V33_FINAL_EVIDENCE_AUDIT}" \
        "${V33_STATUS}" \
        "${V33_CONSOLE}" \
        >"${V33_CURRENT_STATE_POST}"
    if cmp -s -- "${V33_CURRENT_STATE_PRE}" "${V33_CURRENT_STATE_POST}" &&
       sha256sum -c -- "${V33_CURRENT_STATE_PRE}" >"${V33_CURRENT_STATE_AUDIT}" 2>&1; then
        printf 'v33_current_state_equal=1\ncurrent_state_audit=PASS\n' >>"${V33_CURRENT_STATE_AUDIT}"
        return 0
    fi
    printf 'v33_current_state_equal=0\ncurrent_state_audit=FAIL\n' >>"${V33_CURRENT_STATE_AUDIT}"
    return 1
}

write_final_status_binding() {
    sha256sum -- \
        "${STATUS_PATH}" \
        "${CLEANUP_AUDIT_PATH}" \
        "${RECEIPT_PATH}" \
        "${RECEIPT_SHA256_PATH}" \
        "${RECEIPT_AUDIT}" \
        "${FINAL_EVIDENCE}" \
        "${FINAL_EVIDENCE_AUDIT}" \
        "${BOUND_ARTIFACT_MANIFEST}" \
        "${CURRENT_SOURCE_MANIFEST}" \
        "${CURRENT_SOURCE_FINAL_CHECK}" \
        "${V4_ATTEMPT_FINAL_CHECK}" \
        "${V5_ATTEMPT_FINAL_CHECK}" \
        "${V4_ATTEMPT_ADOPTION_AUDIT}" \
        "${V5_ATTEMPT_ADOPTION_AUDIT}" \
        "${DECODER_ADOPTION_AUDIT}" \
        "${MM2_BUILD_ADOPTION_AUDIT}" \
        "${MM2_RESUME_AUDIT}" \
        "${MULTI_ATTEMPT_AUDIT}" \
        "${FRESH_SOURCE_MODEL_AUDIT}" \
        "${V33_CURRENT_STATE_PRE}" \
        "${V33_CURRENT_STATE_POST}" \
        "${V33_CURRENT_STATE_AUDIT}" \
        >"${FINAL_STATUS_BINDING}" || return 1
    sha256sum -c -- "${FINAL_STATUS_BINDING}" >"${FINAL_STATUS_BINDING_CHECK}" 2>&1 || return 1
    printf 'final_status_binding=PASS\n' >>"${FINAL_STATUS_BINDING_CHECK}"
}

finish_runner() {
    local command_rc=$?
    local final_rc=0
    trap - EXIT
    trap 'finish_signal HUP 129' HUP
    trap 'finish_signal INT 130' INT
    trap 'finish_signal TERM 143' TERM
    set +e

    if [[ "${RUNNER_CLEANUP_DONE}" -ne 1 ]]; then
        FINISH_CLEANUP_RC=122
        cleanup_transients
        FINISH_CLEANUP_RC=$?
    fi

    if [[ "${command_rc}" -eq 0 && "${FINISH_CLEANUP_RC}" -eq 0 &&
          "${RUNNER_MAIN_COMPLETE}" -eq 1 ]]; then
        task_run_status_stage current-state-post
        if write_v33_current_state_post &&
           sha256sum -c -- "${CURRENT_SOURCE_MANIFEST}" \
               >"${CURRENT_SOURCE_FINAL_CHECK}" 2>&1 &&
           (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V4_ATTEMPT_MANIFEST}") \
               >"${V4_ATTEMPT_FINAL_CHECK}" 2>&1 &&
           (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V5_ATTEMPT_MANIFEST}") \
               >"${V5_ATTEMPT_FINAL_CHECK}" 2>&1; then
            printf 'current_source_final_check=PASS\n' >>"${CURRENT_SOURCE_FINAL_CHECK}"
            printf 'v4_attempt_final_check=PASS\n' >>"${V4_ATTEMPT_FINAL_CHECK}"
            printf 'v5_attempt_final_check=PASS\n' >>"${V5_ATTEMPT_FINAL_CHECK}"
            task_run_status_stage evidence-complete
            task_run_status_mark_evidence_complete
        else
            command_rc=120
            TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
        fi
    fi

    task_run_status_finalize "${command_rc}" "${FINISH_CLEANUP_RC}"
    final_rc=$?
    if [[ "${final_rc}" -eq 0 ]]; then
        task_run_status_stage final-status-binding
        if [[ "$(sed -n '1p' "${STATUS_PATH}")" != PASS ]] ||
           ! write_final_status_binding; then
            TASK_RUN_STATUS_EVIDENCE_COMPLETE=0
            task_run_status_finalize 121 "${FINISH_CLEANUP_RC}" >/dev/null 2>&1 || true
            final_rc=121
        else
            printf '[NPU-REGRESSION-V34] execution verilator=4 tb_binary=4 fresh_v33=4 adopted_v33=29 adopted_tensor=1 adopted_decoder_build=1 adopted_decoder_tb=1 adopted_mm2_build=1 resumed_mm2_tb=1 new_verilator=2 new_tb=3\n'
            printf '%s\n' "${FINAL_PASS_MARKER}"
        fi
    fi
    trap - HUP INT TERM
    exit "${final_rc}"
}

validate_v4_attempt() {
    local live_artifact_check="${LOG_ROOT}/attempt-artifacts-live-check.pre.log"
    local live_composite_check="${LOG_ROOT}/attempt-composite-live-check.pre.log"
    local command_list="${ADOPT_LOG_ROOT}/tb_decoder_regfile.command-sources.list"
    local actual_list="${ADOPT_LOG_ROOT}/tb_decoder_regfile.actual-sources.list"
    local membership_audit="${ADOPT_LOG_ROOT}/tb_decoder_regfile.source-membership-audit.log"
    local warning_audit="${ADOPT_LOG_ROOT}/tb_decoder_regfile.warning-audit.log"
    local adopted_build_pre="${ADOPT_LOG_ROOT}/tb_decoder_regfile.adopted-build.pre.sha256"
    local source_hash
    local source_path
    local bound_hash
    local bound_path

    task_run_status_stage v4-attempt-adoption-preflight
    [[ "$(file_sha256 "${WORKSPACE_ROOT}/npu/version_0820/tmp/contracts/unary-glu-tensor-regression-v34-v4.json")" == \
       365d2c06831adfe549637a6bac5bda5c57fa9ea949fad0069f8a6cc164e6a522 ]] \
        || die "v4 contract identity mismatch"
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V4_ATTEMPT_MANIFEST}") \
        >"${live_artifact_check}" 2>&1 \
        || die "v4 attempt artifact manifest drift before adoption"
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V4_ATTEMPT_COMPOSITE_SEAL}") \
        >"${live_composite_check}" 2>&1 \
        || die "v4 attempt composite seal drift before adoption"
    [[ "$(file_sha256 "${V4_ATTEMPT_RUNNER}")" == \
       45fd0cefa5f559f0c399f52679050b98ee730caccb32633e99bf259f6e8e5adb ]] \
        || die "v4 archived runner identity mismatch"
    [[ "$(sed -n '1p' "${V4_STATUS}")" == \
       'FAIL rc=1 stage=fresh-build-tb_decoder_regfile evidence_complete=0 cleanup_rc=0' ]] \
        || die "v4 fail-closed status identity mismatch"
    [[ "$(read_single_rc "${V4_DECODER_BUILD_RC}")" -eq 0 ]] \
        || die "v4 decoder build native rc is not zero"
    [[ -x "${V4_DECODER_BINARY}" && -s "${V4_DECODER_VERFILES}" &&
       -s "${V4_DECODER_MAKEFILE}" ]] \
        || die "v4 decoder adopted build artifacts missing"
    [[ ! -e "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.run.log" &&
       ! -e "${V4_FRESH_LOG_ROOT}/tb_decoder_regfile.run.rc" ]] \
        || die "v4 decoder binary already has a run artifact"
    cmp -s -- "${V4_DECODER_SOURCE_PRE}" "${V4_DECODER_SOURCE_POST_BUILD}" \
        || die "v4 decoder source pre/post-build manifests differ"
    (cd -- "${PROJECT_ROOT}" && sha256sum -c -- "${V4_DECODER_SOURCE_PRE}") \
        >"${ADOPT_LOG_ROOT}/tb_decoder_regfile.source-live-check.pre.log" 2>&1 \
        || die "v4 decoder source identity drift before resume"
    require_exact_line "${V4_CLEANUP_AUDIT}" 'cleanup_rc=0'
    require_exact_line "${V4_CLEANUP_AUDIT}" 'cleanup_result=PASS'
    require_exact_line "${V4_ATTEMPT_ROOT}/seal.console.log" \
        '[NPU-REGRESSION-V34][FAIL] tb_decoder_regfile: cannot parse fresh generated command filelist'
    require_exact_line "${V4_ATTEMPT_ROOT}/attempt.provenance.correction" \
        'adopted_v33_before_failure=0'

    extract_command_sources "${V4_DECODER_VERFILES}" "${command_list}" \
        || die "v4 decoder adopted generated command filelist parser failed"
    cmp -s -- "${V4_DECODER_COMPILE_FILELIST}" "${command_list}" \
        || die "v4 decoder adopted command filelist mismatch"
    extract_actual_project_sources "${V4_DECODER_VERFILES}" "${actual_list}" \
        || die "v4 decoder adopted actual source membership parser failed"
    compare_exact_set "${V4_DECODER_EXPECTED_ACTUAL}" "${actual_list}" \
        || die "v4 decoder adopted actual source membership mismatch"
    grep -Fxq -- 'rtl/tensor_npu_defs.vh' "${actual_list}" \
        || die "v4 decoder adopted membership omits tensor_npu_defs.vh"
    validate_generated_config "${V4_DECODER_VERFILES}" "${V4_DECODER_MAKEFILE}" \
        || die "v4 decoder adopted generated config mismatch"
    if rg -n '%Warning|%Error|(^|[[:space:]])warning:|(^|[[:space:]])error:' \
        "${V4_DECODER_BUILD_LOG}" >"${warning_audit}" 2>&1; then
        die "v4 decoder adopted project build warning/error found"
    fi
    printf 'warning_count=0\nerror_count=0\nwarning_audit=PASS\n' >"${warning_audit}"
    printf 'tensor_npu_defs_vh_present=1\nactual_source_membership=PASS\n' \
        >"${membership_audit}"

    while read -r source_hash source_path; do
        record_current_source "${source_hash}" "${source_path}" "${PROJECT_ROOT}"
    done <"${V4_DECODER_SOURCE_PRE}"
    sha256sum -- \
        "${V4_DECODER_BUILD_RC}" \
        "${V4_DECODER_BUILD_LOG}" \
        "${V4_DECODER_BINARY}" \
        "${V4_DECODER_VERFILES}" \
        "${V4_DECODER_MAKEFILE}" \
        "${V4_DECODER_COMPILE_FILELIST}" \
        "${V4_DECODER_CONFIG}" \
        "${V4_DECODER_EXPECTED_ACTUAL}" \
        "${V4_DECODER_SOURCE_PRE}" \
        "${V4_DECODER_SOURCE_POST_BUILD}" \
        >"${adopted_build_pre}"

    {
        printf 'schema=npu-regression-v34-v6-v4-attempt-adoption-v1\n'
        printf 'v4_runner_sha256=%s\n' "$(file_sha256 "${V4_ATTEMPT_RUNNER}")"
        printf 'v4_status=FAIL\n'
        printf 'v4_evidence_complete=0\n'
        printf 'decoder_build_native_rc=0\n'
        printf 'decoder_verilator_execution_adopted=1\n'
        printf 'decoder_tb_execution_before_resume=0\n'
        printf 'decoder_actual_source_membership=PASS\n'
        printf 'tensor_npu_defs_vh_present=1\n'
        printf 'verilator_execution_count_before_resume=1\n'
        printf 'tb_binary_execution_count_before_resume=0\n'
        printf 'fresh_v33_completed_before_resume=0\n'
        printf 'adopted_v33_before_resume=0\n'
        printf 'adopted_tensor_before_resume=0\n'
        printf 'attempt_adoption_audit=PASS\n'
    } >"${V4_ATTEMPT_ADOPTION_AUDIT}"

    for bound_path in \
        "${V4_ATTEMPT_MANIFEST}" \
        "${V4_ATTEMPT_MANIFEST_CHECK}" \
        "${V4_ATTEMPT_ROOT}/attempt-seal.sha256" \
        "${V4_ATTEMPT_ROOT}/attempt-seal.check.log" \
        "${V4_ATTEMPT_COMPOSITE_SEAL}" \
        "${V4_ATTEMPT_COMPOSITE_CHECK}" \
        "${V4_ATTEMPT_ROOT}/attempt.provenance.correction" \
        "${live_artifact_check}" \
        "${live_composite_check}" \
        "${command_list}" \
        "${actual_list}" \
        "${membership_audit}" \
        "${warning_audit}" \
        "${adopted_build_pre}" \
        "${V4_ATTEMPT_ADOPTION_AUDIT}"; do
        append_bound_path "${bound_path}"
    done
    while read -r bound_hash bound_path _rest; do
        [[ "${bound_hash}" =~ ^[0-9a-f]{64}$ && -n "${bound_path}" ]] \
            || die "invalid v4 attempt manifest target"
        append_bound_path "${bound_path}" "${WORKSPACE_ROOT}"
    done <"${V4_ATTEMPT_MANIFEST}"

    VERILATOR_EXECUTION_COUNT=1
    ADOPTED_DECODER_BUILD_COUNT=1
}

validate_v5_attempt() {
    local live_artifact_check="${LOG_ROOT}/v5-attempt-artifacts-live-check.pre.log"
    local live_seal_check="${LOG_ROOT}/v5-attempt-seal-live-check.pre.log"
    local expected_actual="${ADOPT_LOG_ROOT}/tb_mm2_engine.expected-actual-sources.list"
    local command_list="${ADOPT_LOG_ROOT}/tb_mm2_engine.command-sources.list"
    local actual_list="${ADOPT_LOG_ROOT}/tb_mm2_engine.actual-sources.list"
    local global_pre="${ADOPT_LOG_ROOT}/tb_mm2_engine.full-sources.global-pre.sha256"
    local live_pre="${ADOPT_LOG_ROOT}/tb_mm2_engine.full-sources.live-pre.sha256"
    local warning_audit="${ADOPT_LOG_ROOT}/tb_mm2_engine.warning-audit.log"
    local adopted_build_pre="${ADOPT_LOG_ROOT}/tb_mm2_engine.adopted-build.pre.sha256"
    local source_path
    local canonical
    local candidate_hash
    local source_hash
    local bound_hash
    local bound_path

    task_run_status_stage v5-attempt-adoption-preflight
    [[ "$(file_sha256 "${V5_CONTRACT}")" == "${V5_CONTRACT_SHA256}" ]] \
        || die "v5 contract identity mismatch"
    [[ "$(file_sha256 "${V5_ATTEMPT_RUNNER}")" == \
       ecf96b7ef4d0ae1d4a0ea467384926d3c96d21db6e4e0ea8ad55446f558d24ca ]] \
        || die "v5 archived runner identity mismatch"
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V5_ATTEMPT_MANIFEST}") \
        >"${live_artifact_check}" 2>&1 \
        || die "v5 attempt artifact manifest drift"
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V5_ATTEMPT_SEAL}") \
        >"${live_seal_check}" 2>&1 \
        || die "v5 attempt seal drift"
    [[ "$(sed -n '1p' "${V5_STATUS}")" == \
       'FAIL rc=1 stage=fresh-build-tb_mm2_engine evidence_complete=0 cleanup_rc=0' ]] \
        || die "v5 fail-closed status identity mismatch"
    require_exact_line "${V5_CLEANUP_AUDIT}" 'cleanup_rc=0'
    require_exact_line "${V5_CLEANUP_AUDIT}" 'cleanup_result=PASS'
    require_exact_line "${V5_ATTEMPT_ROOT}/seal.console.log" \
        '[NPU-REGRESSION-V34][FAIL] tb_mm2_engine: fresh actual source membership mismatch'
    require_exact_line "${V5_ATTEMPT_ROOT}/attempt.provenance" \
        'mm2_local_memory_global_prehash_before_build=1'

    [[ "$(read_single_rc "${V5_DECODER_RUN_RC}")" -eq 0 ]] \
        || die "v5 decoder TB native rc is not zero"
    [[ "$(count_pass_marker tb_decoder_regfile "${EXPECTED_MARKERS[0]}" \
        "${V5_DECODER_RUN_LOG}")" -eq 1 ]] \
        || die "v5 decoder TB marker cardinality mismatch"
    [[ "$(grep -Fc -- '[FAIL]' "${V5_DECODER_RUN_LOG}" || true)" -eq 0 ]] \
        || die "v5 decoder TB contains FAIL marker"
    cmp -s -- "${V4_DECODER_SOURCE_PRE}" "${V5_DECODER_SOURCE_POST_RUN}" \
        || die "v5 decoder source post-run differs from v4 build pre"
    cmp -s -- "${V5_DECODER_BINARY_PRE}" "${V5_DECODER_BINARY_POST}" \
        || die "v5 decoder binary pre/post differs"
    sha256sum -c -- "${V5_DECODER_BINARY_PRE}" \
        >"${ADOPT_LOG_ROOT}/tb_decoder_regfile.binary-live-check.log" 2>&1 \
        || die "v5 decoder adopted binary identity drift"
    require_exact_line "${V5_DECODER_RESUME_AUDIT}" 'decoder_resume_audit=PASS'

    [[ "$(read_single_rc "${V5_MM2_BUILD_RC}")" -eq 0 ]] \
        || die "v5 mm2 build native rc is not zero"
    [[ -x "${V5_MM2_BINARY}" && -s "${V5_MM2_VERFILES}" && -s "${V5_MM2_MAKEFILE}" ]] \
        || die "v5 mm2 adopted build artifacts missing"
    [[ ! -e "${V5_LOG_ROOT}/fresh/tb_mm2_engine.run.log" &&
       ! -e "${V5_LOG_ROOT}/fresh/tb_mm2_engine.run.rc" ]] \
        || die "v5 mm2 binary already has run artifacts"
    cmp -s -- "${V5_MM2_SOURCE_PRE}" "${V5_MM2_SOURCE_POST_BUILD}" \
        || die "v5 mm2 explicit source pre/post-build differs"
    extract_command_sources "${V5_MM2_VERFILES}" "${command_list}" \
        || die "v5 mm2 command parser failed"
    cmp -s -- "${V5_MM2_COMPILE_FILELIST}" "${command_list}" \
        || die "v5 mm2 command filelist mismatch"
    extract_actual_project_sources "${V5_MM2_VERFILES}" "${actual_list}" \
        || die "v5 mm2 actual source parser failed"
    printf '%s\n' \
        rtl/TensorNpuLocalMemory.v \
        rtl/TensorNpuMm2Engine.v \
        rtl/tensor_npu_defs.vh \
        tests/tb_mm2_engine.sv \
        >"${expected_actual}"
    compare_exact_set "${expected_actual}" "${actual_list}" \
        || die "v5 mm2 complete actual source membership mismatch"
    validate_generated_config "${V5_MM2_VERFILES}" "${V5_MM2_MAKEFILE}" \
        || die "v5 mm2 adopted generated config mismatch"
    if rg -n '%Warning|%Error|(^|[[:space:]])warning:|(^|[[:space:]])error:' \
        "${V5_MM2_BUILD_LOG}" >"${warning_audit}" 2>&1; then
        die "v5 mm2 adopted project build warning/error found"
    fi
    printf 'warning_count=0\nerror_count=0\nwarning_audit=PASS\n' >"${warning_audit}"

    : >"${global_pre}"
    while read -r source_path; do
        canonical="${PROJECT_ROOT}/${source_path}"
        candidate_hash="$(awk -v target="${canonical}" \
            '$2 == target { print $1 }' "${V5_CURRENT_SOURCE_CANDIDATES}" | LC_ALL=C sort -u)"
        [[ "${candidate_hash}" =~ ^[0-9a-f]{64}$ ]] \
            || die "v5 mm2 actual source lacks unique global prehash: ${source_path}"
        printf '%s  %s\n' "${candidate_hash}" "${canonical}" >>"${global_pre}"
        record_current_source "${candidate_hash}" "${source_path}" "${PROJECT_ROOT}"
    done <"${actual_list}"
    LC_ALL=C sort -k2,2 -o "${global_pre}" "${global_pre}"
    while read -r source_hash canonical; do
        sha256sum -- "${canonical}"
    done <"${global_pre}" >"${live_pre}"
    cmp -s -- "${global_pre}" "${live_pre}" \
        || die "v5 mm2 full global prehash differs from current source"
    grep -Fxq -- \
        'fd16e30bc57dad9128c723caa7e1c3fbb8e4f5436cd4402c5c3a375a9198ed12  /home/lyg/PA/ysyx-workbench/npu/version_0820/rtl/TensorNpuLocalMemory.v' \
        "${global_pre}" \
        || die "v5 mm2 LocalMemory global prehash missing"
    sha256sum -- \
        "${V5_MM2_BUILD_RC}" "${V5_MM2_BUILD_LOG}" "${V5_MM2_BINARY}" \
        "${V5_MM2_VERFILES}" "${V5_MM2_MAKEFILE}" "${V5_MM2_COMPILE_FILELIST}" \
        "${V5_MM2_CONFIG}" "${V5_MM2_ACTUAL_SOURCES}" "${V5_MM2_SOURCE_PRE}" \
        "${V5_MM2_SOURCE_POST_BUILD}" "${global_pre}" \
        >"${adopted_build_pre}"

    {
        printf 'schema=npu-regression-v34-v6-v5-attempt-adoption-v1\n'
        printf 'v5_runner_sha256=%s\n' "$(file_sha256 "${V5_ATTEMPT_RUNNER}")"
        printf 'v5_status=FAIL\n'
        printf 'v5_evidence_complete=0\n'
        printf 'decoder_tb_native_rc=0\n'
        printf 'mm2_build_native_rc=0\n'
        printf 'mm2_tb_execution_before_resume=0\n'
        printf 'mm2_actual_source_count=4\n'
        printf 'mm2_local_memory_global_prehash=PASS\n'
        printf 'v5_attempt_adoption_audit=PASS\n'
    } >"${V5_ATTEMPT_ADOPTION_AUDIT}"
    {
        printf 'v4_attempt_binding=PASS\n'
        printf 'v5_attempt_binding=PASS\n'
        printf 'decoder_build_origin=v4\n'
        printf 'decoder_tb_origin=v5\n'
        printf 'mm2_build_origin=v5\n'
        printf 'multi_attempt_audit=PASS\n'
    } >"${MULTI_ATTEMPT_AUDIT}"

    for bound_path in \
        "${V5_ATTEMPT_MANIFEST}" "${V5_ATTEMPT_MANIFEST_CHECK}" \
        "${V5_ATTEMPT_SEAL}" "${V5_ATTEMPT_SEAL_CHECK}" \
        "${live_artifact_check}" "${live_seal_check}" \
        "${expected_actual}" "${command_list}" "${actual_list}" \
        "${global_pre}" "${live_pre}" "${warning_audit}" "${adopted_build_pre}" \
        "${ADOPT_LOG_ROOT}/tb_decoder_regfile.binary-live-check.log" \
        "${V5_ATTEMPT_ADOPTION_AUDIT}" "${MULTI_ATTEMPT_AUDIT}"; do
        append_bound_path "${bound_path}"
    done
    while read -r bound_hash bound_path _rest; do
        [[ "${bound_hash}" =~ ^[0-9a-f]{64}$ && -n "${bound_path}" ]] \
            || die "invalid v5 attempt manifest target"
        append_bound_path "${bound_path}" "${WORKSPACE_ROOT}"
    done <"${V5_ATTEMPT_MANIFEST}"
}

adopt_decoder_test_from_v5() {
    local pass_count
    local fail_count

    [[ "${VERILATOR_EXECUTION_COUNT}" -eq 1 &&
       "${TB_BINARY_EXECUTION_COUNT}" -eq 0 &&
       "${FRESH_V33_COUNT}" -eq 0 &&
       "${ADOPTED_DECODER_BUILD_COUNT}" -eq 1 ]] \
        || die "decoder adoption pre-counter mismatch"
    pass_count="$(count_pass_marker tb_decoder_regfile "${EXPECTED_MARKERS[0]}" \
        "${V5_DECODER_RUN_LOG}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${V5_DECODER_RUN_LOG}" || true)"
    [[ "$(read_single_rc "${V5_DECODER_RUN_RC}")" -eq 0 &&
       "${pass_count}" -eq 1 && "${fail_count}" -eq 0 ]] \
        || die "v5 decoder TB adoption is not a clean PASS"
    sha256sum -c -- "${V5_DECODER_BINARY_PRE}" \
        >"${ADOPT_LOG_ROOT}/tb_decoder_regfile.binary-adoption-check.log" 2>&1 \
        || die "v5 decoder binary drift at v6 adoption"
    (cd -- "${PROJECT_ROOT}" && sha256sum -c -- "${V5_DECODER_SOURCE_POST_RUN}") \
        >"${ADOPT_LOG_ROOT}/tb_decoder_regfile.source-adoption-check.log" 2>&1 \
        || die "v5 decoder source drift at v6 adoption"
    {
        printf 'schema=npu-regression-v34-v6-decoder-adoption-v1\n'
        printf 'adopted_decoder_build=1\n'
        printf 'adopted_decoder_tb=1\n'
        printf 'decoder_build_native_rc=0\n'
        printf 'decoder_run_native_rc=0\n'
        printf 'decoder_marker_count=%d\n' "${pass_count}"
        printf 'new_decoder_verilator=0\n'
        printf 'new_decoder_tb=0\n'
        printf 'decoder_adoption_audit=PASS\n'
    } >"${DECODER_ADOPTION_AUDIT}"
    for bound_path in \
        "${V5_DECODER_RUN_LOG}" "${V5_DECODER_RUN_RC}" \
        "${V5_DECODER_SOURCE_POST_RUN}" "${V5_DECODER_BINARY_PRE}" \
        "${V5_DECODER_BINARY_POST}" "${V5_DECODER_RESUME_AUDIT}" \
        "${ADOPT_LOG_ROOT}/tb_decoder_regfile.binary-adoption-check.log" \
        "${ADOPT_LOG_ROOT}/tb_decoder_regfile.source-adoption-check.log" \
        "${DECODER_ADOPTION_AUDIT}"; do
        append_bound_path "${bound_path}"
    done
    TB_BINARY_EXECUTION_COUNT=1
    FRESH_V33_COUNT=1
    ADOPTED_DECODER_TB_COUNT=1
    printf '[NPU-REGRESSION-V34][ADOPTED-PASS] index=1 test=tb_decoder_regfile marker=%s build=v4 tb=v5\n' \
        "${EXPECTED_MARKERS[0]}"
}

adopt_mm2_build_from_v5() {
    local adopted_build_pre="${ADOPT_LOG_ROOT}/tb_mm2_engine.adopted-build.pre.sha256"
    local global_pre="${ADOPT_LOG_ROOT}/tb_mm2_engine.full-sources.global-pre.sha256"

    [[ "${VERILATOR_EXECUTION_COUNT}" -eq 1 &&
       "${TB_BINARY_EXECUTION_COUNT}" -eq 1 &&
       "${FRESH_V33_COUNT}" -eq 1 &&
       "${ADOPTED_V33_COUNT}" -eq 1 &&
       "${NEW_VERILATOR_EXECUTION_COUNT}" -eq 0 &&
       "${NEW_TB_BINARY_EXECUTION_COUNT}" -eq 0 ]] \
        || die "mm2 build adoption pre-counter mismatch"
    sha256sum -c -- "${adopted_build_pre}" \
        >"${ADOPT_LOG_ROOT}/tb_mm2_engine.adopted-build.live-check.log" 2>&1 \
        || die "v5 mm2 adopted build drift"
    sha256sum -c -- "${global_pre}" \
        >"${ADOPT_LOG_ROOT}/tb_mm2_engine.full-sources.live-check.log" 2>&1 \
        || die "v5 mm2 full source drift at build adoption"
    {
        printf 'schema=npu-regression-v34-v6-mm2-build-adoption-v1\n'
        printf 'adopted_mm2_build=1\n'
        printf 'mm2_build_native_rc=0\n'
        printf 'mm2_actual_source_count=4\n'
        printf 'tensor_npu_defs_vh_present=1\n'
        printf 'TensorNpuLocalMemory_v_transitive_present=1\n'
        printf 'new_mm2_verilator=0\n'
        printf 'mm2_build_adoption_audit=PASS\n'
    } >"${MM2_BUILD_ADOPTION_AUDIT}"
    append_bound_path "${ADOPT_LOG_ROOT}/tb_mm2_engine.adopted-build.live-check.log"
    append_bound_path "${ADOPT_LOG_ROOT}/tb_mm2_engine.full-sources.live-check.log"
    append_bound_path "${MM2_BUILD_ADOPTION_AUDIT}"
    VERILATOR_EXECUTION_COUNT=2
    ADOPTED_MM2_BUILD_COUNT=1
    printf '[NPU-REGRESSION-V34][ADOPTED-BUILD] index=3 test=tb_mm2_engine build=v5 native_rc=0 actual_sources=4\n'
}

resume_mm2_test() {
    local test_name=tb_mm2_engine
    local marker="${EXPECTED_MARKERS[2]}"
    local run_log="${FRESH_LOG_ROOT}/${test_name}.run.log"
    local run_rc_path="${FRESH_LOG_ROOT}/${test_name}.run.rc"
    local global_pre="${ADOPT_LOG_ROOT}/${test_name}.full-sources.global-pre.sha256"
    local source_post="${FRESH_LOG_ROOT}/${test_name}.full-sources.post-run.sha256"
    local binary_pre="${FRESH_LOG_ROOT}/${test_name}.binary.pre-run.sha256"
    local binary_post="${FRESH_LOG_ROOT}/${test_name}.binary.post-run.sha256"
    local adopted_build_pre="${ADOPT_LOG_ROOT}/${test_name}.adopted-build.pre.sha256"
    local terminal_audit="${FRESH_LOG_ROOT}/${test_name}.terminal-audit.log"
    local run_rc
    local pass_count
    local fail_count
    local _source_hash
    local source_path

    [[ "${VERILATOR_EXECUTION_COUNT}" -eq 2 &&
       "${TB_BINARY_EXECUTION_COUNT}" -eq 1 &&
       "${ADOPTED_MM2_BUILD_COUNT}" -eq 1 &&
       "${NEW_VERILATOR_EXECUTION_COUNT}" -eq 0 &&
       "${NEW_TB_BINARY_EXECUTION_COUNT}" -eq 0 ]] \
        || die "mm2 resume pre-counter mismatch"
    [[ ! -e "${run_log}" && ! -e "${run_rc_path}" ]] \
        || die "v6 mm2 resume run artifact already exists"
    sha256sum -c -- "${global_pre}" \
        >"${FRESH_LOG_ROOT}/${test_name}.full-sources.pre-run-check.log" 2>&1 \
        || die "mm2 full source drift immediately before first TB"
    sha256sum -c -- "${adopted_build_pre}" \
        >"${FRESH_LOG_ROOT}/${test_name}.adopted-build.pre-run-check.log" 2>&1 \
        || die "mm2 adopted build drift immediately before first TB"
    sha256sum -- "${V5_MM2_BINARY}" >"${binary_pre}"

    task_run_status_stage fresh-run-resumed-tb_mm2_engine
    ulimit -c 0
    TB_BINARY_EXECUTION_COUNT=$((TB_BINARY_EXECUTION_COUNT + 1))
    NEW_TB_BINARY_EXECUTION_COUNT=$((NEW_TB_BINARY_EXECUTION_COUNT + 1))
    if run_logged "${run_log}" timeout --signal=TERM --kill-after=2s \
        "${RUN_TIMEOUT_SECONDS}s" "${V5_MM2_BINARY}"; then
        run_rc=0
    else
        run_rc=$?
    fi
    printf '%d\n' "${run_rc}" >"${run_rc_path}"
    [[ "${run_rc}" -eq 0 ]] \
        || die "mm2 resumed TB native rc=${run_rc} log=${run_log}"

    while read -r _source_hash source_path; do
        sha256sum -- "${source_path}"
    done <"${global_pre}" >"${source_post}"
    cmp -s -- "${global_pre}" "${source_post}" \
        || die "mm2 full source drift during first TB"
    sha256sum -- "${V5_MM2_BINARY}" >"${binary_post}"
    cmp -s -- "${binary_pre}" "${binary_post}" \
        || die "mm2 adopted binary drift during first TB"
    sha256sum -c -- "${adopted_build_pre}" \
        >"${FRESH_LOG_ROOT}/${test_name}.adopted-build.post-run-check.log" 2>&1 \
        || die "mm2 adopted build drift during first TB"
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${V5_ATTEMPT_MANIFEST}") \
        >"${FRESH_LOG_ROOT}/${test_name}.v5-attempt.post-run-check.log" 2>&1 \
        || die "v5 attempt drift during mm2 first TB"
    pass_count="$(count_pass_marker "${test_name}" "${marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    if [[ "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ]] ||
       rg -n '%Error|Assertion failed|core dumped' "${run_log}" \
           >"${terminal_audit}" 2>&1; then
        die "mm2 resumed TB terminal oracle failed pass_count=${pass_count} fail_count=${fail_count}"
    fi
    {
        printf 'build_origin=v5-adopted\n'
        printf 'build_native_rc=0\n'
        printf 'run_origin=v6-first-mm2-binary-run\n'
        printf 'run_native_rc=%d\n' "${run_rc}"
        printf 'pass_marker_count=%d\n' "${pass_count}"
        printf 'fail_marker_count=%d\n' "${fail_count}"
        printf 'terminal_audit=PASS\n'
    } >"${terminal_audit}"
    {
        printf 'schema=npu-regression-v34-v6-mm2-resume-v1\n'
        printf 'adopted_mm2_build=1\n'
        printf 'resumed_mm2_tb=1\n'
        printf 'new_mm2_verilator=0\n'
        printf 'new_mm2_tb=1\n'
        printf 'mm2_run_native_rc=0\n'
        printf 'mm2_full_source_pre_post=PASS\n'
        printf 'mm2_binary_pre_post=PASS\n'
        printf 'mm2_resume_audit=PASS\n'
    } >"${MM2_RESUME_AUDIT}"
    for bound_path in \
        "${run_log}" "${run_rc_path}" "${source_post}" "${binary_pre}" "${binary_post}" \
        "${FRESH_LOG_ROOT}/${test_name}.full-sources.pre-run-check.log" \
        "${FRESH_LOG_ROOT}/${test_name}.adopted-build.pre-run-check.log" \
        "${FRESH_LOG_ROOT}/${test_name}.adopted-build.post-run-check.log" \
        "${FRESH_LOG_ROOT}/${test_name}.v5-attempt.post-run-check.log" \
        "${terminal_audit}" "${MM2_RESUME_AUDIT}"; do
        append_bound_path "${bound_path}"
    done
    FRESH_V33_COUNT=$((FRESH_V33_COUNT + 1))
    RESUMED_MM2_TB_COUNT=1
    printf '[NPU-REGRESSION-V34][RESUMED-PASS] index=3 test=%s marker=%s build=v5-adopted tb=v6-first-run\n' \
        "${test_name}" "${marker}"
}

validate_v33_roots() {
    local receipt_bound_hash
    local actual_bound_hash
    local bound_count
    local console_marker_count
    local console_adopted_count
    local receipt_hash_rc=0
    local bound_hash_rc=0

    task_run_status_stage v33-current-state-pre
    sha256sum -- \
        "${V33_FINAL_EVIDENCE_AUDIT}" \
        "${V33_STATUS}" \
        "${V33_CONSOLE}" \
        >"${V33_CURRENT_STATE_PRE}"

    task_run_status_stage v33-bound-manifest
    if ! sha256sum -c -- "${V33_RECEIPT_SHA}" >"${LOG_ROOT}/v33-receipt-check.log" 2>&1; then
        receipt_hash_rc=1
    fi
    if ! (cd -- "${PROJECT_ROOT}" && sha256sum -c -- "${V33_BOUND_MANIFEST}") \
        >"${LOG_ROOT}/v33-bound-check.log" 2>&1; then
        bound_hash_rc=1
    fi
    [[ "${receipt_hash_rc}" -eq 0 && "${bound_hash_rc}" -eq 0 ]] \
        || die "v33 receipt/bound manifest hash verification failed"

    bound_count="$(awk 'NF { count++ } END { print count + 0 }' "${V33_BOUND_MANIFEST}")"
    [[ "${bound_count}" -eq 318 ]] || die "v33 bound artifact count=${bound_count}, expected 318"
    receipt_bound_hash="$(sed -n 's/^bound_manifest_sha256=//p' "${V33_RECEIPT}")"
    actual_bound_hash="$(file_sha256 "${V33_BOUND_MANIFEST}")"
    [[ "${receipt_bound_hash}" == "${actual_bound_hash}" ]] \
        || die "v33 receipt does not bind current 318-target manifest"
    require_exact_line "${V33_RECEIPT}" 'schema=npu-unary-glu-element-regression-receipt-v1'
    require_exact_line "${V33_RECEIPT}" 'tests_total=33'
    require_exact_line "${V33_RECEIPT}" 'execution_mode=seal-existing-attempt-03'
    require_exact_line "${V33_RECEIPT}" 'legacy_adopted_test_count=32'
    require_exact_line "${V33_RECEIPT}" 'attempt03_unary_adopted_test_count=1'
    require_exact_line "${V33_RECEIPT}" 'seal_verilator_execution_count=0'
    require_exact_line "${V33_RECEIPT}" 'seal_tb_binary_execution_count=0'
    require_exact_line "${V33_RECEIPT}" 'assertions=off'
    require_exact_line "${V33_RECEIPT}" 'waveform=off'
    require_exact_line "${V33_RECEIPT}" 'optimization=O3'
    require_exact_line "${V33_FINAL_EVIDENCE_AUDIT}" 'final_evidence_rc=0'
    require_exact_line "${V33_FINAL_EVIDENCE_AUDIT}" 'final_evidence=PASS'
    require_exact_line "${V33_STATUS}" 'PASS'
    console_marker_count="$(awk '$0 == "[NPU-REGRESSION][PASS] tests=33 assertions=off waveform=off optimization=O3" { count++ } END { print count + 0 }' "${V33_CONSOLE}")"
    console_adopted_count="$(awk 'index($0, "[NPU-REGRESSION][ADOPTED-PASS]") == 1 { count++ } END { print count + 0 }' "${V33_CONSOLE}")"
    [[ "${console_marker_count}" -eq 1 && "${console_adopted_count}" -eq 33 ]] \
        || die "v33 current console cardinality mismatch"
    require_exact_line "${V33_CONSOLE}" '[NPU-REGRESSION] seal execution verilator=0 tb_binary=0 adopted_legacy=32 adopted_unary=1 source_set=36'
    cmp -s -- "${V33_LEGACY_SOURCE_PRE}" "${V33_LEGACY_SOURCE_POST}" \
        || die "v33 legacy explicit-source pre/post manifests differ"

    {
        printf 'receipt_check_rc=%d\n' "${receipt_hash_rc}"
        printf 'bound_check_rc=%d\n' "${bound_hash_rc}"
        printf 'bound_artifact_count=%d\n' "${bound_count}"
        printf 'receipt_bound_manifest_equal=1\n'
        printf 'console_terminal_marker_count=%d\n' "${console_marker_count}"
        printf 'console_adopted_marker_count=%d\n' "${console_adopted_count}"
        printf 'v33_root_audit=PASS\n'
    } >"${V33_AUDIT}"

    append_bound_path "${V33_RECEIPT}"
    append_bound_path "${V33_RECEIPT_SHA}"
    append_bound_path "${V33_BOUND_MANIFEST}"
    append_bound_path "${V33_TEST_PLAN}"
    append_bound_path "${V33_FINAL_EVIDENCE_AUDIT}"
    append_bound_path "${V33_STATUS}"
    append_bound_path "${V33_CONSOLE}"
    append_bound_path "${V33_LEGACY_SOURCE_PRE}"
    append_bound_path "${V33_LEGACY_SOURCE_POST}"
    while read -r _hash bound_path _rest; do
        [[ -n "${bound_path}" ]] || die "blank v33 bound target"
        append_bound_path "${bound_path}" "${PROJECT_ROOT}"
    done <"${V33_BOUND_MANIFEST}"
}

validate_v33_test_plan() {
    local index
    local expected_origin
    require_exact_line "${V33_TEST_PLAN}" 'schema=npu-regression-test-plan-v1'
    require_exact_line "${V33_TEST_PLAN}" 'execution_mode=seal-existing-attempt-03'
    require_exact_line "${V33_TEST_PLAN}" 'test_count=33'
    for ((index = 0; index < 33; index++)); do
        if [[ "${index}" -lt 32 ]]; then
            expected_origin='attempt-02-archive'
        else
            expected_origin='attempt-03-unary'
        fi
        require_exact_line "${V33_TEST_PLAN}" \
            "test[$((index + 1))]=${EXPECTED_TESTS[index]} origin=${expected_origin}"
    done
}

freeze_fresh_source_models() {
    local test_name
    local verfiles
    local makefile
    local frozen_command
    local frozen_actual
    local expected_command
    local expected_actual
    local command_count
    local actual_count

    for test_name in tb_dma_engine tb_coprocessor; do
        verfiles="${V33_ATTEMPT02_BUILD}/${test_name}/V${test_name}__verFiles.dat"
        makefile="${V33_ATTEMPT02_BUILD}/${test_name}/V${test_name}.mk"
        frozen_command="${ADOPT_LOG_ROOT}/${test_name}.source-model.command.list"
        frozen_actual="${ADOPT_LOG_ROOT}/${test_name}.source-model.actual.list"
        expected_command="${ADOPT_LOG_ROOT}/${test_name}.source-model.expected-command.list"
        expected_actual="${ADOPT_LOG_ROOT}/${test_name}.source-model.expected-actual.list"

        extract_command_sources "${verfiles}" "${frozen_command}" \
            || die "${test_name}: cannot freeze v33 command-source model"
        extract_actual_project_sources "${verfiles}" "${frozen_actual}" \
            || die "${test_name}: cannot freeze v33 actual-S source model"
        case "${test_name}" in
            tb_dma_engine)
                printf '%s\n' \
                    tests/tb_dma_engine.sv \
                    rtl/TensorNpuDmaEngine.v \
                    >"${expected_command}"
                printf '%s\n' \
                    rtl/TensorNpuDmaEngine.v \
                    rtl/TensorNpuLocalMemory.v \
                    rtl/tensor_npu_defs.vh \
                    tests/tb_dma_engine.sv \
                    | LC_ALL=C sort >"${expected_actual}"
                ;;
            tb_coprocessor)
                printf '%s\n' \
                    tests/tb_coprocessor.sv \
                    rtl/TensorNpuCoprocessor.v \
                    rtl/TensorNpuCommandDecoder.v \
                    rtl/TensorNpuRegisterFile.v \
                    rtl/TensorNpuMm2Engine.v \
                    rtl/TensorNpuDmaEngine.v \
                    rtl/TensorNpuLocalMemory.v \
                    >"${expected_command}"
                printf '%s\n' \
                    rtl/TensorNpuCommandDecoder.v \
                    rtl/TensorNpuCoprocessor.v \
                    rtl/TensorNpuDmaEngine.v \
                    rtl/TensorNpuLocalMemory.v \
                    rtl/TensorNpuMm2Engine.v \
                    rtl/TensorNpuRegisterFile.v \
                    rtl/tensor_npu_defs.vh \
                    tests/tb_coprocessor.sv \
                    | LC_ALL=C sort >"${expected_actual}"
                ;;
        esac
        cmp -s -- "${expected_command}" "${frozen_command}" \
            || die "${test_name}: frozen v33 command-source model mismatch"
        compare_exact_set "${expected_actual}" "${frozen_actual}" \
            || die "${test_name}: frozen v33 actual-S model mismatch"
        if compare_exact_set "${frozen_command}" "${frozen_actual}"; then
            die "${test_name}: command and actual source models were incorrectly conflated"
        fi
        grep -Fxq -- 'rtl/tensor_npu_defs.vh' "${frozen_actual}" \
            || die "${test_name}: frozen actual-S model omits tensor_npu_defs.vh"
        validate_generated_config "${verfiles}" "${makefile}" \
            || die "${test_name}: frozen v33 generated config mismatch"
        command_count="$(awk 'NF { count++ } END { print count + 0 }' "${frozen_command}")"
        actual_count="$(awk 'NF { count++ } END { print count + 0 }' "${frozen_actual}")"
        case "${test_name}:${command_count}:${actual_count}" in
            tb_dma_engine:2:4|tb_coprocessor:7:8) ;;
            *) die "${test_name}: frozen source model count mismatch command=${command_count} actual=${actual_count}" ;;
        esac
        for bound_path in \
            "${verfiles}" "${makefile}" "${frozen_command}" "${frozen_actual}" \
            "${expected_command}" "${expected_actual}"; do
            append_bound_path "${bound_path}"
        done
    done
    {
        printf 'schema=npu-regression-v34-v6-fresh-source-model-v1\n'
        printf 'model_origin=v33-attempt-02-verFiles-actual-S\n'
        printf 'identity_role=source-model-only-not-test-adoption\n'
        printf 'tb_dma_engine_command_source_count=2\n'
        printf 'tb_dma_engine_actual_source_count=4\n'
        printf 'tb_dma_engine_command_actual_separated=1\n'
        printf 'tb_coprocessor_command_source_count=7\n'
        printf 'tb_coprocessor_actual_source_count=8\n'
        printf 'tb_coprocessor_command_actual_separated=1\n'
        printf 'fresh_source_model_audit=PASS\n'
    } >"${FRESH_SOURCE_MODEL_AUDIT}"
    append_bound_path "${FRESH_SOURCE_MODEL_AUDIT}"
}

extract_legacy_expected_sources() {
    local test_name="${1:?test name is required}"
    local output="${2:?output path is required}"
    local hash_value
    local source_path
    local test_tag
    : >"${output}"
    while read -r hash_value source_path test_tag; do
        [[ "${test_tag}" == "test=${test_name}" ]] || continue
        [[ "${hash_value}" =~ ^[0-9a-f]{64}$ && -n "${source_path}" ]] || return 1
        printf '%s\n' "${source_path}" >>"${output}"
    done <"${V33_LEGACY_SOURCE_PRE}"
    [[ -s "${output}" ]]
}

legacy_recorded_hash() {
    local test_name="${1:?test name is required}"
    local source_path="${2:?source path is required}"
    awk -v test_tag="test=${test_name}" -v source_path="${source_path}" \
        '$2 == source_path && $3 == test_tag { print $1 }' "${V33_LEGACY_SOURCE_PRE}"
}

unary_recorded_hash() {
    local source_path="${1:?source path is required}"
    awk -v target="path=${source_path}" \
        '$2 == target && index($1, "source_sha256=") == 1 {
            hash = substr($1, 15)
            if (length(hash) == 64 && hash ~ /^[0-9a-f]+$/) print hash
        }' \
        "${V33_RECEIPT}"
}

validate_adopted_v33_test() {
    local index="${1:?test index is required}"
    local test_name="${EXPECTED_TESTS[index]}"
    local marker="${EXPECTED_MARKERS[index]}"
    local evidence_log_root
    local evidence_build_root
    local build_log
    local build_rc_path
    local run_log
    local run_rc_path
    local binary
    local verfiles
    local makefile
    local explicit_list="${ADOPT_LOG_ROOT}/${test_name}.explicit-sources.list"
    local command_list="${ADOPT_LOG_ROOT}/${test_name}.command-sources.list"
    local actual_list="${ADOPT_LOG_ROOT}/${test_name}.actual-sources.list"
    local actual_hash_manifest="${ADOPT_LOG_ROOT}/${test_name}.actual-sources.sha256"
    local source_path
    local recorded_hash
    local pass_count
    local fail_count
    local build_rc
    local run_rc
    declare -A explicit_set=()

    is_affected_index "${index}" && die "affected v33 test was routed to v33 adoption: ${test_name}"
    if [[ "${index}" -eq 32 ]]; then
        evidence_log_root="${V33_ATTEMPT03_LOG}"
        evidence_build_root="${V33_ATTEMPT03_BUILD}"
    else
        evidence_log_root="${V33_ATTEMPT02_LOG}"
        evidence_build_root="${V33_ATTEMPT02_BUILD}"
    fi
    build_log="${evidence_log_root}/${test_name}.build.log"
    build_rc_path="${evidence_log_root}/${test_name}.build.rc"
    run_log="${evidence_log_root}/${test_name}.run.log"
    run_rc_path="${evidence_log_root}/${test_name}.run.rc"
    binary="${evidence_build_root}/${test_name}/V${test_name}"
    verfiles="${evidence_build_root}/${test_name}/V${test_name}__verFiles.dat"
    makefile="${evidence_build_root}/${test_name}/V${test_name}.mk"

    for source_path in "${build_log}" "${build_rc_path}" "${run_log}" "${run_rc_path}" \
        "${binary}" "${verfiles}" "${makefile}"; do
        [[ -f "${source_path}" ]] || die "${test_name}: missing adopted artifact ${source_path}"
    done
    [[ -x "${binary}" ]] || die "${test_name}: adopted binary is not executable"
    build_rc="$(read_single_rc "${build_rc_path}")"
    run_rc="$(read_single_rc "${run_rc_path}")"
    pass_count="$(count_pass_marker "${test_name}" "${marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    [[ "${build_rc}" -eq 0 && "${run_rc}" -eq 0 &&
       "${pass_count}" -eq 1 && "${fail_count}" -eq 0 ]] \
        || die "${test_name}: adopted rc/marker evidence is not a clean PASS"
    validate_generated_config "${verfiles}" "${makefile}" \
        || die "${test_name}: adopted generated config mismatch"

    if [[ "${index}" -eq 32 ]]; then
        sed -n 'p' "${V33_ATTEMPT03_LOG}/${test_name}.compile-filelist" >"${explicit_list}"
        while read -r source_path; do
            [[ -n "${source_path}" ]] || die "${test_name}: blank unary explicit source"
            explicit_set["${source_path}"]=1
        done <"${explicit_list}"
    else
        extract_legacy_expected_sources "${test_name}" "${explicit_list}" \
            || die "${test_name}: missing legacy explicit source membership"
        while read -r source_path; do
            [[ -z "${explicit_set[${source_path}]+present}" ]] \
                || die "${test_name}: duplicate explicit source ${source_path}"
            explicit_set["${source_path}"]=1
        done <"${explicit_list}"
    fi
    extract_command_sources "${verfiles}" "${command_list}" \
        || die "${test_name}: cannot parse generated command filelist"
    cmp -s -- "${explicit_list}" "${command_list}" \
        || die "${test_name}: generated command filelist differs from frozen explicit list"
    extract_actual_project_sources "${verfiles}" "${actual_list}" \
        || die "${test_name}: invalid generated actual source membership"
    if grep -Fxq -- 'rtl/tensor_npu_defs.vh' "${actual_list}"; then
        die "${test_name}: test with unbound tensor_npu_defs.vh was incorrectly adopted"
    fi

    : >"${actual_hash_manifest}"
    while read -r source_path; do
        if [[ -n "${explicit_set[${source_path}]+present}" ]]; then
            if [[ "${index}" -eq 32 ]]; then
                recorded_hash="$(unary_recorded_hash "${source_path}")"
            else
                recorded_hash="$(legacy_recorded_hash "${test_name}" "${source_path}")"
            fi
        else
            recorded_hash="$(unary_recorded_hash "${source_path}")"
        fi
        [[ "${recorded_hash}" =~ ^[0-9a-f]{64}$ ]] \
            || die "${test_name}: actual source lacks executed SHA ${source_path}"
        record_current_source "${recorded_hash}" "${source_path}" "${PROJECT_ROOT}"
        printf '%s  %s\n' "${recorded_hash}" "${source_path}" >>"${actual_hash_manifest}"
    done <"${actual_list}"
    while read -r source_path; do
        grep -Fxq -- "${source_path}" "${actual_list}" \
            || die "${test_name}: explicit source absent from actual membership ${source_path}"
    done <"${explicit_list}"

    append_bound_path "${build_log}"
    append_bound_path "${build_rc_path}"
    append_bound_path "${run_log}"
    append_bound_path "${run_rc_path}"
    append_bound_path "${binary}"
    append_bound_path "${verfiles}"
    append_bound_path "${makefile}"
    append_bound_path "${explicit_list}"
    append_bound_path "${command_list}"
    append_bound_path "${actual_list}"
    append_bound_path "${actual_hash_manifest}"
    ADOPTED_V33_COUNT=$((ADOPTED_V33_COUNT + 1))
    printf '[NPU-REGRESSION-V34][ADOPTED-PASS] index=%d test=%s marker=%s\n' \
        "$((index + 1))" "${test_name}" "${marker}"
}

fresh_build_run() {
    local index="${1:?test index is required}"
    shift
    local -a explicit_sources=("$@")
    local test_name="${EXPECTED_TESTS[index]}"
    local marker="${EXPECTED_MARKERS[index]}"
    local build_dir="${BUILD_ROOT}/${test_name}"
    local binary="${build_dir}/V${test_name}"
    local verfiles="${build_dir}/V${test_name}__verFiles.dat"
    local makefile="${build_dir}/V${test_name}.mk"
    local build_log="${FRESH_LOG_ROOT}/${test_name}.build.log"
    local build_rc_path="${FRESH_LOG_ROOT}/${test_name}.build.rc"
    local run_log="${FRESH_LOG_ROOT}/${test_name}.run.log"
    local run_rc_path="${FRESH_LOG_ROOT}/${test_name}.run.rc"
    local filelist="${FRESH_LOG_ROOT}/${test_name}.compile-filelist"
    local command_list="${FRESH_LOG_ROOT}/${test_name}.command-sources.list"
    local expected_actual="${FRESH_LOG_ROOT}/${test_name}.expected-actual-sources.list"
    local actual_sources="${FRESH_LOG_ROOT}/${test_name}.actual-sources.list"
    local source_pre="${FRESH_LOG_ROOT}/${test_name}.sources.pre.sha256"
    local source_post_build="${FRESH_LOG_ROOT}/${test_name}.sources.post-build.sha256"
    local source_post_run="${FRESH_LOG_ROOT}/${test_name}.sources.post-run.sha256"
    local build_artifacts="${FRESH_LOG_ROOT}/${test_name}.build-artifacts.sha256"
    local binary_pre="${FRESH_LOG_ROOT}/${test_name}.binary.pre-run.sha256"
    local binary_post="${FRESH_LOG_ROOT}/${test_name}.binary.post-run.sha256"
    local membership_audit="${FRESH_LOG_ROOT}/${test_name}.source-membership-audit.log"
    local config_path="${FRESH_LOG_ROOT}/${test_name}.config"
    local warning_audit="${FRESH_LOG_ROOT}/${test_name}.warning-audit.log"
    local terminal_audit="${FRESH_LOG_ROOT}/${test_name}.terminal-audit.log"
    local frozen_command="${ADOPT_LOG_ROOT}/${test_name}.source-model.command.list"
    local frozen_actual="${ADOPT_LOG_ROOT}/${test_name}.source-model.actual.list"
    local build_rc
    local run_rc
    local pass_count
    local fail_count
    local source_path
    local source_hash
    local config_index
    local -a transitive_sources=()
    local -a expected_actual_sources=()
    local -a verilator_args=(
        --binary
        --timing
        --sv
        -O3
        -Wall
        -Wno-fatal
        -CFLAGS "-O3 -DNDEBUG -march=native"
        -Irtl
        --Mdir "${build_dir}"
        --top-module "${test_name}"
        "${explicit_sources[@]}"
        -o "V${test_name}"
    )

    case "${index}" in
        3)
            transitive_sources=(rtl/TensorNpuLocalMemory.v)
            ;;
        4)
            transitive_sources=()
            ;;
        *)
            die "fresh transitive source model missing for index=${index}"
            ;;
    esac
    expected_actual_sources=(
        "${explicit_sources[@]}"
        "${transitive_sources[@]}"
        rtl/tensor_npu_defs.vh
    )

    is_new_fresh_index "${index}" || die "non-new-fresh test routed to Verilator execution: ${test_name}"
    [[ ! -e "${build_dir}" ]] || die "${test_name}: stale v34 fresh build directory"
    mkdir -- "${build_dir}"
    printf '%s\n' "${explicit_sources[@]}" >"${filelist}"
    printf '%s\n' "${expected_actual_sources[@]}" | LC_ALL=C sort -u >"${expected_actual}"
    cmp -s -- "${frozen_command}" "${filelist}" \
        || die "${test_name}: current command-source model differs from frozen v33 model"
    compare_exact_set "${frozen_actual}" "${expected_actual}" \
        || die "${test_name}: current expected actual-S model differs from frozen v33 model"
    for source_path in "${expected_actual_sources[@]}"; do
        [[ -f "${PROJECT_ROOT}/${source_path}" ]] || die "${test_name}: missing fresh source ${source_path}"
    done
    (cd -- "${PROJECT_ROOT}" && sha256sum -- "${expected_actual_sources[@]}") >"${source_pre}"
    while read -r source_hash source_path; do
        record_current_source "${source_hash}" "${source_path}" "${PROJECT_ROOT}"
    done <"${source_pre}"
    grep -Fxq -- 'rtl/tensor_npu_defs.vh' "${expected_actual}" \
        || die "${test_name}: tensor_npu_defs.vh absent from fresh expected membership"

    {
        printf 'schema=npu-regression-v34-fresh-config-v1\n'
        printf 'test=%s\n' "${test_name}"
        printf 'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal\n'
        printf 'cflags=-O3 -DNDEBUG -march=native\n'
        printf 'assertions=off\ntrace=off\nwaveform=off\ncoverage=off\noptimization=O3\n'
        printf 'arg_count=%d\n' "${#verilator_args[@]}"
        for ((config_index = 0; config_index < ${#verilator_args[@]}; config_index++)); do
            printf 'arg[%d]=%s\n' "${config_index}" "${verilator_args[config_index]}"
        done
    } >"${config_path}"

    task_run_status_stage "fresh-build-${test_name}"
    VERILATOR_EXECUTION_COUNT=$((VERILATOR_EXECUTION_COUNT + 1))
    NEW_VERILATOR_EXECUTION_COUNT=$((NEW_VERILATOR_EXECUTION_COUNT + 1))
    if run_logged "${build_log}" verilator "${verilator_args[@]}"; then
        build_rc=0
    else
        build_rc=$?
    fi
    printf '%d\n' "${build_rc}" >"${build_rc_path}"
    [[ "${build_rc}" -eq 0 ]] || die "${test_name}: fresh Verilator build rc=${build_rc} log=${build_log}"
    [[ -x "${binary}" && -s "${verfiles}" && -s "${makefile}" ]] \
        || die "${test_name}: fresh build artifacts missing"

    (cd -- "${PROJECT_ROOT}" && sha256sum -- "${expected_actual_sources[@]}") >"${source_post_build}"
    cmp -s -- "${source_pre}" "${source_post_build}" \
        || die "${test_name}: source drift during fresh build"
    extract_command_sources "${verfiles}" "${command_list}" \
        || die "${test_name}: cannot parse fresh generated command filelist"
    cmp -s -- "${filelist}" "${command_list}" \
        || die "${test_name}: fresh generated command filelist mismatch"
    extract_actual_project_sources "${verfiles}" "${actual_sources}" \
        || die "${test_name}: invalid fresh actual source membership"
    if compare_exact_set "${expected_actual}" "${actual_sources}"; then
        printf 'tensor_npu_defs_vh_present=1\nactual_source_membership=PASS\n' >"${membership_audit}"
    else
        printf 'tensor_npu_defs_vh_present=0\nactual_source_membership=FAIL\n' >"${membership_audit}"
        die "${test_name}: fresh actual source membership mismatch"
    fi
    validate_generated_config "${verfiles}" "${makefile}" \
        || die "${test_name}: fresh generated config mismatch"
    if rg -n '%Warning|%Error|(^|[[:space:]])warning:|(^|[[:space:]])error:' \
        "${build_log}" >"${warning_audit}" 2>&1; then
        die "${test_name}: project fresh build warning/error found"
    fi
    printf 'warning_count=0\nerror_count=0\nwarning_audit=PASS\n' >"${warning_audit}"
    sha256sum -- "${binary}" "${verfiles}" "${makefile}" >"${build_artifacts}"
    sha256sum -- "${binary}" >"${binary_pre}"

    task_run_status_stage "fresh-run-${test_name}"
    ulimit -c 0
    TB_BINARY_EXECUTION_COUNT=$((TB_BINARY_EXECUTION_COUNT + 1))
    NEW_TB_BINARY_EXECUTION_COUNT=$((NEW_TB_BINARY_EXECUTION_COUNT + 1))
    if run_logged "${run_log}" timeout --signal=TERM --kill-after=2s \
        "${RUN_TIMEOUT_SECONDS}s" "${binary}"; then
        run_rc=0
    else
        run_rc=$?
    fi
    printf '%d\n' "${run_rc}" >"${run_rc_path}"
    [[ "${run_rc}" -eq 0 ]] || die "${test_name}: fresh TB run rc=${run_rc} log=${run_log}"

    (cd -- "${PROJECT_ROOT}" && sha256sum -- "${expected_actual_sources[@]}") >"${source_post_run}"
    cmp -s -- "${source_pre}" "${source_post_run}" \
        || die "${test_name}: source drift during fresh run"
    sha256sum -- "${binary}" >"${binary_post}"
    cmp -s -- "${binary_pre}" "${binary_post}" \
        || die "${test_name}: binary drift during fresh run"
    sha256sum -c -- "${build_artifacts}" >"${FRESH_LOG_ROOT}/${test_name}.build-artifact-check.log" 2>&1 \
        || die "${test_name}: build artifact drift during fresh run"
    pass_count="$(count_pass_marker "${test_name}" "${marker}" "${run_log}")"
    fail_count="$(grep -Fc -- '[FAIL]' "${run_log}" || true)"
    if [[ "${pass_count}" -ne 1 || "${fail_count}" -ne 0 ]] ||
       rg -n '%Error|Assertion failed|core dumped' "${run_log}" >"${terminal_audit}" 2>&1; then
        die "${test_name}: fresh terminal oracle failed pass_count=${pass_count} fail_count=${fail_count}"
    fi
    {
        printf 'build_native_rc=%d\n' "${build_rc}"
        printf 'run_native_rc=%d\n' "${run_rc}"
        printf 'pass_marker_count=%d\n' "${pass_count}"
        printf 'fail_marker_count=%d\n' "${fail_count}"
        printf 'terminal_audit=PASS\n'
    } >"${terminal_audit}"

    for source_path in \
        "${build_log}" "${build_rc_path}" "${run_log}" "${run_rc_path}" \
        "${binary}" "${verfiles}" "${makefile}" "${filelist}" "${command_list}" \
        "${expected_actual}" "${actual_sources}" "${source_pre}" "${source_post_build}" \
        "${source_post_run}" "${build_artifacts}" "${binary_pre}" "${binary_post}" \
        "${membership_audit}" "${config_path}" "${warning_audit}" "${terminal_audit}" \
        "${FRESH_LOG_ROOT}/${test_name}.build-artifact-check.log"; do
        append_bound_path "${source_path}"
    done
    FRESH_V33_COUNT=$((FRESH_V33_COUNT + 1))
    printf '[NPU-REGRESSION-V34][FRESH-PASS] index=%d test=%s marker=%s\n' \
        "$((index + 1))" "${test_name}" "${marker}"
}

run_fresh_test_by_index() {
    local index="${1:?test index is required}"
    case "${index}" in
        3)
            fresh_build_run "${index}" \
                tests/tb_dma_engine.sv \
                rtl/TensorNpuDmaEngine.v
            ;;
        4)
            fresh_build_run "${index}" \
                tests/tb_coprocessor.sv \
                rtl/TensorNpuCoprocessor.v \
                rtl/TensorNpuCommandDecoder.v \
                rtl/TensorNpuRegisterFile.v \
                rtl/TensorNpuMm2Engine.v \
                rtl/TensorNpuDmaEngine.v \
                rtl/TensorNpuLocalMemory.v
            ;;
        *)
            die "unsupported fresh test index=${index}"
            ;;
    esac
}

validate_tensor_adoption() {
    local receipt_artifact_hash
    local receipt_source_hash
    local receipt_runner_input_hash
    local actual_hash
    local source_hash
    local source_path
    local marker_count
    local fail_count
    local build_rc
    local run_rc
    local manifest_path
    local bound_path
    local _rest

    task_run_status_stage tensor-fixed3-binding
    (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${TENSOR_RECEIPT_SHA}") \
        >"${LOG_ROOT}/tensor-receipt-check.log" 2>&1 \
        || die "tensor fixed-3 immutable receipt hash mismatch"
    for manifest_path in \
        "${TENSOR_ARTIFACT_MANIFEST}" \
        "${TENSOR_RUNNER_INPUT_MANIFEST}" \
        "${TENSOR_SOURCE_PRE}" \
        "${TENSOR_BUILD_ARTIFACTS}" \
        "${TENSOR_FINAL_BINDING}"; do
        (cd -- "${WORKSPACE_ROOT}" && sha256sum -c -- "${manifest_path}") \
            >"${LOG_ROOT}/tensor-${manifest_path##*/}.check.log" 2>&1 \
            || die "tensor fixed-3 referenced target mismatch: ${manifest_path}"
    done
    cmp -s -- "${TENSOR_SOURCE_PRE}" "${TENSOR_SOURCE_POST_BUILD}" \
        || die "tensor fixed-3 source pre/post-build manifests differ"
    cmp -s -- "${TENSOR_SOURCE_PRE}" "${TENSOR_SOURCE_POST_RUN}" \
        || die "tensor fixed-3 source pre/post-run manifests differ"
    cmp -s -- "${TENSOR_BINARY_PRE}" "${TENSOR_BINARY_POST}" \
        || die "tensor fixed-3 binary pre/post manifests differ"
    compare_exact_set \
        "${WORKSPACE_ROOT}/npu/version_0820/tmp/logs/unary-glu-tensor-engine/repair-v1/workspace-source-membership.txt" \
        "${TENSOR_LOG_ROOT}/actual-workspace-source-membership.txt" \
        || die "tensor fixed-3 actual workspace source membership mismatch"
    compare_exact_set \
        "${TENSOR_LOG_ROOT}/verilator-transitive-membership.txt" \
        "${TENSOR_LOG_ROOT}/actual-verilator-transitive-membership.txt" \
        || die "tensor fixed-3 actual tool transitive membership mismatch"

    require_exact_line "${TENSOR_RECEIPT}" 'receipt_schema=unary-glu-tensor-repair-v1'
    require_exact_line "${TENSOR_RECEIPT}" 'attempt_namespace=fixed-3'
    require_exact_line "${TENSOR_RECEIPT}" 'build_native_rc=0'
    require_exact_line "${TENSOR_RECEIPT}" 'run_native_rc=0'
    require_exact_line "${TENSOR_RECEIPT}" 'terminal_marker_count=1'
    require_exact_line "${TENSOR_RECEIPT}" 'expected_final_status=PASS'
    require_exact_line "${TENSOR_RECEIPT}" 'evidence_complete_required=1'
    require_exact_line "${TENSOR_RECEIPT}" 'cleanup_rc_required=0'
    require_exact_line "${TENSOR_RECEIPT}" 'legacy_evidence_role=historical-only-not-reused-for-repair-binary'
    require_exact_line "${TENSOR_LOG_ROOT}/final-task.status" 'PASS'
    require_exact_line "${TENSOR_LOG_ROOT}/audit-summary.log" '[REPAIR-V1-AUDIT][PASS] source_binary_run_immutable=1 warning=0 forbidden=0 wave_core=0'
    require_exact_line "${TENSOR_LOG_ROOT}/config-audit.log" '[CONFIG-AUDIT][PASS] binary_timing_sv_O3_Wall=1 cxx_O3_native=1 assert_trace_coverage=0'
    require_exact_line "${TENSOR_LOG_ROOT}/warning-audit.log" '[WARNING-AUDIT][PASS] warning=0 error=0'
    require_exact_line "${TENSOR_LOG_ROOT}/wave-core-audit.log" '[WAVE-CORE-AUDIT][PASS] ignored_tmp_scanned=1 wave=0 core=0'
    require_exact_line "${TENSOR_LOG_ROOT}/cleanup-audit.log" '[CLEANUP][PASS] active_engine_process=0 cleanup_rc=0'
    require_exact_line "${TENSOR_LOG_ROOT}/terminal-audit.log" '[TERMINAL-AUDIT][PASS] marker_count=1 runtime_failure=0'
    require_exact_line "${TENSOR_LOG_ROOT}/source-membership-audit.log" '[SOURCE-MEMBERSHIP][PASS] exact_membership=37'
    require_exact_line "${TENSOR_LOG_ROOT}/tool-membership-audit.log" '[TOOL-MEMBERSHIP][PASS] exact_membership=2'
    require_exact_line "${TENSOR_LOG_ROOT}/verfiles-command-audit.log" '[VERFILES-COMMAND][PASS] exact_explicit_files=33 O3=1 assert=0 trace=0 coverage=0'

    receipt_artifact_hash="$(sed -n 's/^artifact_manifest_sha256=//p' "${TENSOR_RECEIPT}")"
    receipt_source_hash="$(sed -n 's/^source_hash_manifest_sha256=//p' "${TENSOR_RECEIPT}")"
    receipt_runner_input_hash="$(sed -n 's/^runner_input_manifest_sha256=//p' "${TENSOR_RECEIPT}")"
    [[ "${receipt_artifact_hash}" == "$(file_sha256 "${TENSOR_ARTIFACT_MANIFEST}")" &&
       "${receipt_source_hash}" == "$(file_sha256 "${TENSOR_SOURCE_PRE}")" &&
       "${receipt_runner_input_hash}" == "$(file_sha256 "${TENSOR_RUNNER_INPUT_MANIFEST}")" ]] \
        || die "tensor fixed-3 receipt manifest binding mismatch"
    build_rc="$(read_single_rc "${TENSOR_LOG_ROOT}/first-build.native.rc")"
    run_rc="$(read_single_rc "${TENSOR_LOG_ROOT}/first-run.native.rc")"
    marker_count="$(count_pass_marker tb_unary_glu_tensor_engine \
        '[NPU-UNARY-GLU-TENSOR][PASS]' "${TENSOR_LOG_ROOT}/first-run.log")"
    fail_count="$(grep -Fc -- '[FAIL]' "${TENSOR_LOG_ROOT}/first-run.log" || true)"
    [[ "${build_rc}" -eq 0 && "${run_rc}" -eq 0 &&
       "${marker_count}" -eq 1 && "${fail_count}" -eq 0 && -x "${TENSOR_BINARY}" ]] \
        || die "tensor fixed-3 native rc/marker/binary is not a clean PASS"

    while read -r source_hash source_path; do
        record_current_source "${source_hash}" "${source_path}" "${WORKSPACE_ROOT}"
    done <"${TENSOR_SOURCE_PRE}"

    for manifest_path in \
        "${TENSOR_RECEIPT}" "${TENSOR_RECEIPT_SHA}" "${TENSOR_ARTIFACT_MANIFEST}" \
        "${TENSOR_RUNNER_INPUT_MANIFEST}" "${TENSOR_SOURCE_PRE}" "${TENSOR_SOURCE_POST_BUILD}" \
        "${TENSOR_SOURCE_POST_RUN}" "${TENSOR_BUILD_ARTIFACTS}" "${TENSOR_BINARY_PRE}" \
        "${TENSOR_BINARY_POST}" "${TENSOR_FINAL_BINDING}" "${TENSOR_BINARY}" \
        "${TENSOR_LOG_ROOT}/final-task.status" "${TENSOR_LOG_ROOT}/first-run.log" \
        "${TENSOR_LOG_ROOT}/first-build.native.rc" "${TENSOR_LOG_ROOT}/first-run.native.rc"; do
        append_bound_path "${manifest_path}"
    done
    for manifest_path in "${TENSOR_ARTIFACT_MANIFEST}" "${TENSOR_RUNNER_INPUT_MANIFEST}" \
        "${TENSOR_SOURCE_PRE}" "${TENSOR_BUILD_ARTIFACTS}" "${TENSOR_FINAL_BINDING}"; do
        while read -r _rest bound_path; do
            [[ -n "${bound_path}" ]] || die "tensor manifest has blank target: ${manifest_path}"
            append_bound_path "${bound_path}" "${WORKSPACE_ROOT}"
        done <"${manifest_path}"
    done

    {
        printf 'receipt_artifact_manifest_equal=1\n'
        printf 'receipt_source_manifest_equal=1\n'
        printf 'receipt_runner_input_manifest_equal=1\n'
        printf 'source_pre_post_build_equal=1\n'
        printf 'source_pre_post_run_equal=1\n'
        printf 'binary_pre_post_equal=1\n'
        printf 'build_native_rc=%d\n' "${build_rc}"
        printf 'run_native_rc=%d\n' "${run_rc}"
        printf 'terminal_marker_count=%d\n' "${marker_count}"
        printf 'tensor_adoption_audit=PASS\n'
    } >"${TENSOR_AUDIT}"
    ADOPTED_TENSOR_COUNT=$((ADOPTED_TENSOR_COUNT + 1))
    printf '[NPU-REGRESSION-V34][ADOPTED-PASS] index=34 test=tb_unary_glu_tensor_engine marker=[NPU-UNARY-GLU-TENSOR][PASS]\n'
}

write_v34_test_plan() {
    local index
    local origin
    [[ "${#EXPECTED_TESTS[@]}" -eq 34 && "${#EXPECTED_MARKERS[@]}" -eq 34 ]] \
        || die "v34 expected test/marker array count mismatch"
    {
        printf 'schema=npu-regression-test-plan-v34-v6\n'
        printf 'test_count=34\n'
        printf 'execution_policy=adopt-decoder-build-tb-adopt-mm2-build-resume-mm2-fresh2-adopt-v33-29-adopt-tensor-1\n'
        printf 'assertions=off\ntrace=off\nwaveform=off\ncoverage=off\noptimization=O3\n'
        for ((index = 0; index < 34; index++)); do
            if [[ "${index}" -eq 33 ]]; then
                origin='repair-v1/fixed-3-adopted'
            elif [[ "${index}" -eq 0 ]]; then
                origin='v4-decoder-build-v5-decoder-tb-adopted'
            elif [[ "${index}" -eq 2 ]]; then
                origin='v5-mm2-build-adopted-v6-tb-resumed'
            elif is_new_fresh_index "${index}"; then
                origin='v6-fresh'
            else
                origin='v33-adopted'
            fi
            printf 'test[%d]=%s marker=%s origin=%s\n' \
                "$((index + 1))" "${EXPECTED_TESTS[index]}" "${EXPECTED_MARKERS[index]}" "${origin}"
        done
    } >"${TEST_PLAN_PATH}"
}

generate_current_source_manifest() {
    local source_hash
    local source_path
    local source_count=0
    local temp_manifest="${COMPILER_TMP_ROOT}/current-source-manifest.unsorted"
    declare -A source_hashes=()
    : >"${temp_manifest}"
    while read -r source_hash source_path; do
        [[ "${source_hash}" =~ ^[0-9a-f]{64}$ && "${source_path}" == "${WORKSPACE_ROOT}/"* ]] \
            || die "invalid v34 current source candidate: ${source_hash} ${source_path}"
        if [[ -n "${source_hashes[${source_path}]+present}" &&
              "${source_hashes[${source_path}]}" != "${source_hash}" ]]; then
            die "conflicting current source hashes for ${source_path}"
        fi
        source_hashes["${source_path}"]="${source_hash}"
    done <"${CURRENT_SOURCE_CANDIDATES}"
    for source_path in "${!source_hashes[@]}"; do
        printf '%s  %s\n' "${source_hashes[${source_path}]}" "${source_path}" >>"${temp_manifest}"
        source_count=$((source_count + 1))
    done
    LC_ALL=C sort -k2,2 -- "${temp_manifest}" >"${CURRENT_SOURCE_MANIFEST}"
    sha256sum -c -- "${CURRENT_SOURCE_MANIFEST}" >"${SOURCE_AUDIT}" 2>&1 \
        || die "v34 current source manifest does not match current workspace"
    {
        printf 'current_source_count=%d\n' "${source_count}"
        printf 'tensor_npu_defs_vh_hash=%s\n' "$(file_sha256 "${PROJECT_ROOT}/rtl/tensor_npu_defs.vh")"
        printf 'current_source_audit=PASS\n'
    } >>"${SOURCE_AUDIT}"
    append_bound_path "${CURRENT_SOURCE_CANDIDATES}"
    append_bound_path "${CURRENT_SOURCE_MANIFEST}"
    while read -r _hash source_path; do
        append_bound_path "${source_path}"
    done <"${CURRENT_SOURCE_MANIFEST}"
}

generate_bound_artifact_manifest() {
    local bound_path
    local bound_count=0
    local temp_manifest="${COMPILER_TMP_ROOT}/bound-artifacts.unsorted"
    declare -A seen_paths=()

    append_bound_path "${SCRIPT_DIR}/run_npu_regression_v34.sh"
    append_bound_path "${V6_CONTRACT}"
    append_bound_path "${V5_CONTRACT}"
    append_bound_path "${WORKSPACE_ROOT}/npu/version_0820/tmp/contracts/unary-glu-tensor-regression-v34-v4.json"
    append_bound_path "${TASK_RUN_STATUS_HELPER}"
    append_bound_path "${TASK_RUN_STATUS_TEST}"
    append_bound_path "${TASK_RUN_STATUS_TEST_LOG}"
    append_bound_path "${TASK_RUN_STATUS_TEST_RC}"
    append_bound_path "${RUNNER_BASH_N_LOG}"
    append_bound_path "${SELF_TEST_AUDIT}"
    append_bound_path "${PREFLIGHT_RUNNER_SHA}"
    append_bound_path "${PREFLIGHT_RUNNER_SYNTAX}"
    append_bound_path "${PREFLIGHT_SELF_TEST_AUDIT}"
    append_bound_path "${PREFLIGHT_LOG_ROOT}/preflight.status"
    append_bound_path "${PREFLIGHT_LOG_ROOT}/cleanup-audit.log"
    append_bound_path "${V4_ATTEMPT_ADOPTION_AUDIT}"
    append_bound_path "${V5_ATTEMPT_ADOPTION_AUDIT}"
    append_bound_path "${DECODER_ADOPTION_AUDIT}"
    append_bound_path "${MM2_BUILD_ADOPTION_AUDIT}"
    append_bound_path "${MM2_RESUME_AUDIT}"
    append_bound_path "${MULTI_ATTEMPT_AUDIT}"
    append_bound_path "${TEST_PLAN_PATH}"
    append_bound_path "${V33_AUDIT}"
    append_bound_path "${FRESH_SOURCE_MODEL_AUDIT}"
    append_bound_path "${TENSOR_AUDIT}"
    append_bound_path "${MARKER_AUDIT}"
    append_bound_path "${CONFIG_AUDIT}"
    append_bound_path "${SOURCE_AUDIT}"
    append_bound_path "${WAVE_CORE_AUDIT}"
    append_bound_path "${V33_CURRENT_STATE_PRE}"

    : >"${temp_manifest}"
    for bound_path in "${BOUND_PATHS[@]}"; do
        [[ -z "${seen_paths[${bound_path}]+present}" ]] || continue
        seen_paths["${bound_path}"]=1
        printf '%s\n' "${bound_path}" >>"${temp_manifest}"
        bound_count=$((bound_count + 1))
    done
    LC_ALL=C sort -u -- "${temp_manifest}" | while IFS= read -r bound_path; do
        sha256sum -- "${bound_path}"
    done >"${BOUND_ARTIFACT_MANIFEST}"
    [[ "$(awk 'NF { count++ } END { print count + 0 }' "${BOUND_ARTIFACT_MANIFEST}")" -eq "${bound_count}" ]] \
        || die "v34 bound artifact manifest count mismatch"
    sha256sum -c -- "${BOUND_ARTIFACT_MANIFEST}" >"${LOG_ROOT}/bound-artifact-check.log" 2>&1 \
        || die "v34 bound artifact manifest verification failed"
}

write_receipt_and_evidence() {
    local bound_count
    local source_count
    local receipt_rc=0
    bound_count="$(awk 'NF { count++ } END { print count + 0 }' "${BOUND_ARTIFACT_MANIFEST}")"
    source_count="$(awk 'NF { count++ } END { print count + 0 }' "${CURRENT_SOURCE_MANIFEST}")"
    {
        printf 'receipt_schema=npu-regression-v34-v6-receipt-v1\n'
        printf 'contract_json=npu/version_0820/tmp/contracts/unary-glu-tensor-regression-v34-v6.json\n'
        printf 'contract_json_sha256=%s\n' "${V6_CONTRACT_SHA256}"
        printf 'test_count=34\n'
        printf 'fresh_v33_test_count=%d\n' "${FRESH_V33_COUNT}"
        printf 'adopted_v33_test_count=%d\n' "${ADOPTED_V33_COUNT}"
        printf 'adopted_tensor_test_count=%d\n' "${ADOPTED_TENSOR_COUNT}"
        printf 'adopted_decoder_build_count=%d\n' "${ADOPTED_DECODER_BUILD_COUNT}"
        printf 'adopted_decoder_tb_count=%d\n' "${ADOPTED_DECODER_TB_COUNT}"
        printf 'adopted_mm2_build_count=%d\n' "${ADOPTED_MM2_BUILD_COUNT}"
        printf 'resumed_mm2_tb_count=%d\n' "${RESUMED_MM2_TB_COUNT}"
        printf 'new_verilator_execution_count=%d\n' "${NEW_VERILATOR_EXECUTION_COUNT}"
        printf 'new_tb_binary_execution_count=%d\n' "${NEW_TB_BINARY_EXECUTION_COUNT}"
        printf 'verilator_execution_count=%d\n' "${VERILATOR_EXECUTION_COUNT}"
        printf 'tb_binary_execution_count=%d\n' "${TB_BINARY_EXECUTION_COUNT}"
        printf 'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal\n'
        printf 'cflags=-O3 -DNDEBUG -march=native\n'
        printf 'assertions=off\ntrace=off\nwaveform=off\ncoverage=off\noptimization=O3\n'
        printf 'current_source_count=%d\n' "${source_count}"
        printf 'current_source_manifest_sha256=%s\n' "$(file_sha256 "${CURRENT_SOURCE_MANIFEST}")"
        printf 'bound_artifact_count=%d\n' "${bound_count}"
        printf 'bound_artifact_manifest_sha256=%s\n' "$(file_sha256 "${BOUND_ARTIFACT_MANIFEST}")"
        printf 'v33_receipt_sha256=%s\n' "$(file_sha256 "${V33_RECEIPT}")"
        printf 'v33_bound_manifest_sha256=%s\n' "$(file_sha256 "${V33_BOUND_MANIFEST}")"
        printf 'v33_current_state_pre_sha256=%s\n' "$(file_sha256 "${V33_CURRENT_STATE_PRE}")"
        printf 'tensor_receipt_sha256=%s\n' "$(file_sha256 "${TENSOR_RECEIPT}")"
        printf 'tensor_final_binding_sha256=%s\n' "$(file_sha256 "${TENSOR_FINAL_BINDING}")"
        printf 'v4_attempt_manifest_sha256=%s\n' "$(file_sha256 "${V4_ATTEMPT_MANIFEST}")"
        printf 'v4_attempt_runner_sha256=%s\n' "$(file_sha256 "${V4_ATTEMPT_RUNNER}")"
        printf 'v5_attempt_manifest_sha256=%s\n' "$(file_sha256 "${V5_ATTEMPT_MANIFEST}")"
        printf 'v5_attempt_runner_sha256=%s\n' "$(file_sha256 "${V5_ATTEMPT_RUNNER}")"
        printf 'v6_runner_sha256=%s\n' "$(file_sha256 "${SCRIPT_DIR}/run_npu_regression_v34.sh")"
        printf 'fresh_source_model_audit=PASS\n'
        printf 'task_run_status_before_finalize=RUNNING\n'
        printf 'final_status_expected=PASS\n'
        printf 'evidence_complete_required=1\n'
        printf 'cleanup_rc_required=0\n'
        printf 'final_marker_tests=34\n'
    } >"${RECEIPT_PATH}"
    sha256sum -- "${RECEIPT_PATH}" >"${RECEIPT_SHA256_PATH}"

    {
        sha256sum -c -- "${RECEIPT_SHA256_PATH}" || receipt_rc=1
        for expected_line in \
            'receipt_schema=npu-regression-v34-v6-receipt-v1' \
            'test_count=34' \
            'fresh_v33_test_count=4' \
            'adopted_v33_test_count=29' \
            'adopted_tensor_test_count=1' \
            'adopted_decoder_build_count=1' \
            'adopted_decoder_tb_count=1' \
            'adopted_mm2_build_count=1' \
            'resumed_mm2_tb_count=1' \
            'new_verilator_execution_count=2' \
            'new_tb_binary_execution_count=3' \
            'verilator_execution_count=4' \
            'tb_binary_execution_count=4' \
            'fresh_source_model_audit=PASS' \
            'assertions=off' \
            'trace=off' \
            'waveform=off' \
            'coverage=off' \
            'optimization=O3' \
            'task_run_status_before_finalize=RUNNING' \
            'final_status_expected=PASS' \
            'evidence_complete_required=1' \
            'cleanup_rc_required=0'; do
            if ! grep -Fxq -- "${expected_line}" "${RECEIPT_PATH}"; then
                printf 'missing_receipt_line=%s\n' "${expected_line}"
                receipt_rc=1
            fi
        done
        printf 'receipt_audit_rc=%d\n' "${receipt_rc}"
        if [[ "${receipt_rc}" -eq 0 ]]; then
            printf 'receipt_audit=PASS\n'
        else
            printf 'receipt_audit=FAIL\n'
        fi
    } >"${RECEIPT_AUDIT}" 2>&1
    [[ "${receipt_rc}" -eq 0 ]] || die "v34 receipt audit failed"

    {
        printf 'schema=npu-regression-v34-v6-final-evidence-v1\n'
        printf 'tests=34\n'
        printf 'fresh_v33=4\nadopted_v33=29\nadopted_tensor=1\n'
        printf 'verilator_execution_count=4\ntb_binary_execution_count=4\n'
        printf 'adopted_decoder_build=1\nadopted_decoder_tb=1\n'
        printf 'adopted_mm2_build=1\nresumed_mm2_tb=1\n'
        printf 'new_verilator_execution_count=2\nnew_tb_binary_execution_count=3\n'
        printf 'v4_attempt_adoption_audit=PASS\n'
        printf 'v5_attempt_adoption_audit=PASS\n'
        printf 'decoder_adoption_audit=PASS\n'
        printf 'mm2_build_adoption_audit=PASS\n'
        printf 'mm2_resume_audit=PASS\n'
        printf 'multi_attempt_audit=PASS\n'
        printf 'v33_root_audit=PASS\n'
        printf 'fresh_source_model_audit=PASS\n'
        printf 'tensor_adoption_audit=PASS\n'
        printf 'marker_audit=PASS\nconfig_audit=PASS\ncurrent_source_audit=PASS\n'
        printf 'wave_core_audit=PASS\nself_test=PASS\n'
        printf 'receipt_audit=PASS\n'
        printf 'current_state_post_required=1\n'
        printf 'cleanup_required=1\n'
        printf 'status_before_finalize=RUNNING\n'
        printf 'final_evidence_pre_finalize=PASS\n'
    } >"${FINAL_EVIDENCE}"
    {
        sha256sum -c -- "${RECEIPT_SHA256_PATH}" || receipt_rc=1
        for evidence_check in \
            "${SELF_TEST_AUDIT}:self_test=PASS" \
            "${V4_ATTEMPT_ADOPTION_AUDIT}:attempt_adoption_audit=PASS" \
            "${V5_ATTEMPT_ADOPTION_AUDIT}:v5_attempt_adoption_audit=PASS" \
            "${DECODER_ADOPTION_AUDIT}:decoder_adoption_audit=PASS" \
            "${MM2_BUILD_ADOPTION_AUDIT}:mm2_build_adoption_audit=PASS" \
            "${MM2_RESUME_AUDIT}:mm2_resume_audit=PASS" \
            "${MULTI_ATTEMPT_AUDIT}:multi_attempt_audit=PASS" \
            "${V33_AUDIT}:v33_root_audit=PASS" \
            "${FRESH_SOURCE_MODEL_AUDIT}:fresh_source_model_audit=PASS" \
            "${TENSOR_AUDIT}:tensor_adoption_audit=PASS" \
            "${MARKER_AUDIT}:marker_audit=PASS" \
            "${CONFIG_AUDIT}:config_audit=PASS" \
            "${SOURCE_AUDIT}:current_source_audit=PASS" \
            "${WAVE_CORE_AUDIT}:wave_core_audit=PASS" \
            "${RECEIPT_AUDIT}:receipt_audit=PASS"; do
            evidence_path="${evidence_check%%:*}"
            evidence_marker="${evidence_check#*:}"
            if ! grep -Fxq -- "${evidence_marker}" "${evidence_path}"; then
                printf 'missing_evidence_marker=%s path=%s\n' "${evidence_marker}" "${evidence_path}"
                receipt_rc=1
            fi
        done
        if [[ "$(sed -n '1p' "${STATUS_PATH}")" != RUNNING ]]; then
            printf 'status_before_finalize_not_running=1\n'
            receipt_rc=1
        fi
        printf 'final_evidence_audit_rc=%d\n' "${receipt_rc}"
        if [[ "${receipt_rc}" -eq 0 ]]; then
            printf 'final_evidence_audit=PASS\n'
        else
            printf 'final_evidence_audit=FAIL\n'
        fi
    } >"${FINAL_EVIDENCE_AUDIT}" 2>&1
    [[ "${receipt_rc}" -eq 0 ]] || die "v34 final evidence audit failed"
}

if [[ "$#" -eq 1 && "$1" == --self-test-only ]]; then
    run_preflight_only
    exit 0
fi
[[ "$#" -eq 0 ]] || die 'run_npu_regression_v34.sh accepts only --self-test-only or no arguments'
[[ "${RUN_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]] \
    || die 'NPU_REGRESSION_V34_TIMEOUT_SECONDS must be a positive integer'

for output_root in "${BUILD_ROOT}" "${LOG_ROOT}" "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}"; do
    [[ ! -e "${output_root}" ]] || die "stale v34 output root exists: ${output_root}"
done
mkdir -p -- \
    "${BUILD_ROOT}" "${LOG_ROOT}" "${CACHE_ROOT}" "${COMPILER_TMP_ROOT}" \
    "${FRESH_LOG_ROOT}" "${ADOPT_LOG_ROOT}"

[[ -f "${TASK_RUN_STATUS_HELPER}" ]] || die "missing task-run status helper"
# shellcheck source=/dev/null
source "${TASK_RUN_STATUS_HELPER}"
task_run_status_init "${STATUS_PATH}"
trap finish_runner EXIT
trap 'runner_note_signal HUP 129' HUP
trap 'runner_note_signal INT 130' INT
trap 'runner_note_signal TERM 143' TERM

task_run_status_stage environment-check
for required_tool in \
    realpath mkdir sed verilator timeout grep sha256sum cmp sort find rm awk bash rg; do
    command -v "${required_tool}" >/dev/null 2>&1 \
        || die "required tool not found: ${required_tool}"
done
export TMPDIR="${COMPILER_TMP_ROOT}"
export XDG_CACHE_HOME="${CACHE_ROOT}"
export CCACHE_DISABLE=1
cd -- "${PROJECT_ROOT}"
: >"${CURRENT_SOURCE_CANDIDATES}"

task_run_status_stage runner-syntax
bash -n -- "${SCRIPT_DIR}/run_npu_regression_v34.sh" >"${RUNNER_BASH_N_LOG}" 2>&1 \
    || die "v34 runner syntax check failed"

task_run_status_stage v6-preflight-binding
validate_preflight_binding

task_run_status_stage task-run-status-test
if run_logged "${TASK_RUN_STATUS_TEST_LOG}" bash "${TASK_RUN_STATUS_TEST}"; then
    helper_rc=0
else
    helper_rc=$?
fi
printf '%d\n' "${helper_rc}" >"${TASK_RUN_STATUS_TEST_RC}"
[[ "${helper_rc}" -eq 0 ]] || die "task-run-status directed test rc=${helper_rc}"
require_exact_line "${TASK_RUN_STATUS_TEST_LOG}" \
    '[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM'

task_run_status_stage self-negative-probes
run_self_tests || die "v34 marker/source-parser/current-state/adopted-build/transitive negative probe failed"
require_exact_line "${SELF_TEST_AUDIT}" 'command_source_parser_local_awk=PASS'
require_exact_line "${SELF_TEST_AUDIT}" 'omitted_transitive_source_rejected=1'
require_exact_line "${SELF_TEST_AUDIT}" 'complete_transitive_source_set_accepted=1'
require_exact_line "${SELF_TEST_AUDIT}" 'fresh_dma_command_actual_model=PASS'
require_exact_line "${SELF_TEST_AUDIT}" 'fresh_coprocessor_command_actual_model=PASS'
require_exact_line "${SELF_TEST_AUDIT}" 'self_test=PASS'

task_run_status_stage v4-attempt-adoption
validate_v4_attempt
task_run_status_stage v5-attempt-adoption
validate_v5_attempt
printf '[NPU-REGRESSION-V34-V6] resume-pre historical_aggregate_verilator=2 historical_aggregate_tb=1 historical_fresh_complete=1 historical_adopted_v33=1 historical_tensor=0 runtime_verilator=1 runtime_tb=0 runtime_fresh_complete=0 runtime_adopted_v33=0 runtime_tensor=0 new_verilator=0 new_tb=0 mm2_tb_executed=0\n'

task_run_status_stage v33-root-validation
validate_v33_roots
validate_v33_test_plan
task_run_status_stage fresh-source-model-freeze
freeze_fresh_source_models
write_v34_test_plan
printf '[NPU-REGRESSION-V34] plan tests=34 policy=adopt-decoder-build-tb-adopt-mm2-build-resume-mm2-fresh2-adopt-v33-29-adopt-tensor-1 status=%s\n' "${STATUS_PATH}"

for ((test_index = 0; test_index < 33; test_index++)); do
    if [[ "${test_index}" -eq 0 ]]; then
        adopt_decoder_test_from_v5
    elif [[ "${test_index}" -eq 2 ]]; then
        adopt_mm2_build_from_v5
        resume_mm2_test
    elif is_new_fresh_index "${test_index}"; then
        run_fresh_test_by_index "${test_index}"
    else
        validate_adopted_v33_test "${test_index}"
    fi
done
validate_tensor_adoption

[[ "${VERILATOR_EXECUTION_COUNT}" -eq 4 &&
   "${TB_BINARY_EXECUTION_COUNT}" -eq 4 &&
   "${FRESH_V33_COUNT}" -eq 4 &&
   "${ADOPTED_V33_COUNT}" -eq 29 &&
   "${ADOPTED_TENSOR_COUNT}" -eq 1 &&
   "${ADOPTED_DECODER_BUILD_COUNT}" -eq 1 &&
   "${ADOPTED_DECODER_TB_COUNT}" -eq 1 &&
   "${ADOPTED_MM2_BUILD_COUNT}" -eq 1 &&
   "${RESUMED_MM2_TB_COUNT}" -eq 1 &&
   "${NEW_VERILATOR_EXECUTION_COUNT}" -eq 2 &&
   "${NEW_TB_BINARY_EXECUTION_COUNT}" -eq 3 ]] \
    || die "execution/adoption count mismatch verilator=${VERILATOR_EXECUTION_COUNT} tb=${TB_BINARY_EXECUTION_COUNT} fresh=${FRESH_V33_COUNT} adopted_v33=${ADOPTED_V33_COUNT} tensor=${ADOPTED_TENSOR_COUNT} adopted_decoder_build=${ADOPTED_DECODER_BUILD_COUNT} adopted_decoder_tb=${ADOPTED_DECODER_TB_COUNT} adopted_mm2_build=${ADOPTED_MM2_BUILD_COUNT} resumed_mm2_tb=${RESUMED_MM2_TB_COUNT} new_verilator=${NEW_VERILATOR_EXECUTION_COUNT} new_tb=${NEW_TB_BINARY_EXECUTION_COUNT}"

task_run_status_stage aggregate-audits
{
    printf 'tests_total=34\n'
    printf 'adopted_decoder_marker_count=1\n'
    printf 'resumed_mm2_marker_count=1\n'
    printf 'new_fresh_marker_count=2\n'
    printf 'adopted_v33_marker_count=29\n'
    printf 'adopted_tensor_marker_count=1\n'
    printf 'missing_marker_count=0\n'
    printf 'duplicate_marker_count=0\n'
    printf 'marker_audit=PASS\n'
} >"${MARKER_AUDIT}"
{
    printf 'adopted_decoder_generated_config_count=1\n'
    printf 'adopted_mm2_generated_config_count=1\n'
    printf 'new_fresh_generated_config_count=2\n'
    printf 'adopted_generated_config_count=29\n'
    printf 'tensor_fixed_config_count=1\n'
    printf 'verilator_flags=--binary --timing --sv -O3 -Wall -Wno-fatal\n'
    printf 'cflags=-O3 -DNDEBUG -march=native\n'
    printf 'assertions=off\ntrace=off\nwaveform=off\ncoverage=off\noptimization=O3\n'
    printf 'config_audit=PASS\n'
} >"${CONFIG_AUDIT}"
if rg --files --hidden --no-ignore \
    "${BUILD_CONTAINER}" "${LOG_CONTAINER}" "${CACHE_CONTAINER}" "${COMPILER_CONTAINER}" \
    -g '*.vcd' -g '*.fst' -g '*.lxt' -g '*.lxt2' -g '*.ghw' \
    -g 'core' -g 'core.*' >"${WAVE_CORE_AUDIT}" 2>&1; then
    die "v34 waveform/core artifact found"
fi
{
    printf 'waveform_artifact_count=0\n'
    printf 'core_artifact_count=0\n'
    printf 'wave_core_audit=PASS\n'
} >"${WAVE_CORE_AUDIT}"

task_run_status_stage source-manifest-seal
generate_current_source_manifest
task_run_status_stage bound-artifact-seal
generate_bound_artifact_manifest
task_run_status_stage receipt-seal
write_receipt_and_evidence

RUNNER_MAIN_COMPLETE=1
task_run_status_stage ready-to-finalize
exit 0
