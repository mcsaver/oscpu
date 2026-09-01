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
            printf '[F32-GATHER-REPEAT-PORTAL][FAIL] generated path escapes project tmp/: %s\n' \
                "${resolved}" >&2
            exit 1
            ;;
    esac
}

readonly RUN_ID="f32-gather-repeat-portal-$(date -u +%Y%m%dT%H%M%SZ)-${BASHPID}"
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
    rtl/TensorNpuF32GatherRepeatPortalAdapter.v
    tests/tb_f32_gather_repeat_portal_adapter.sv
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
    -Wno-UNUSEDSIGNAL
    -Wno-UNUSEDPARAM
    -Wno-WIDTHTRUNC
    -Wno-WIDTHEXPAND
    --top-module tb_f32_gather_repeat_portal_adapter
    --Mdir "${OBJ_DIR}"
    -o Vtb_f32_gather_repeat_portal_adapter
    "${SOURCES[@]}"
)

{
    printf 'cwd=%q\n' "${PROJECT_ROOT}"
    printf 'command='
    printf '%q ' "${VERILATOR_CMD[@]}"
    printf '\nassertions=off\nwaveforms=off\noptimization=O3\n'
    printf 'portal_contract=raw32-memcpy-only\n'
    printf 'gmem_contract=all-ledgers-and-requests-zero\n'
} >"${COMMAND_LOG}"

set +e
"${VERILATOR_CMD[@]}" >"${BUILD_LOG}" 2>&1
BUILD_EXIT=$?
set -e
WARNING_COUNT="$(grep -c '^%Warning' "${BUILD_LOG}" || true)"

if [[ "${BUILD_EXIT}" -ne 0 ]]; then
    cat -- "${BUILD_LOG}"
    {
        printf 'schema=f32-gather-repeat-portal-result-v1\n'
        printf 'status=FAIL\nphase=build\nbuild_exit=%d\nwarnings=%s\n' \
            "${BUILD_EXIT}" "${WARNING_COUNT}"
        sha256sum \
            rtl/TensorNpuF32GatherRepeatPortalAdapter.v \
            tests/tb_f32_gather_repeat_portal_adapter.sv \
            scripts/run_f32_gather_repeat_portal_adapter.sh \
            rtl/TensorNpuF32GatherRepeatAdapter.v
    } >"${RESULT_LOG}"
    printf '[F32-GATHER-REPEAT-PORTAL][FAIL] phase=build exit=%d warnings=%s log=%s\n' \
        "${BUILD_EXIT}" "${WARNING_COUNT}" "${BUILD_LOG}"
    exit "${BUILD_EXIT}"
fi

set +e
timeout 120s "${OBJ_DIR}/Vtb_f32_gather_repeat_portal_adapter" \
    >"${RUN_LOG}" 2>&1
RUN_EXIT=$?
set -e
cat -- "${RUN_LOG}"

PASS_COUNT="$(grep -Fc \
    '[NPU-F32-GATHER-REPEAT-PORTAL][PASS] scenarios=5 lanes=16 assertions=off waveform=off' \
    "${RUN_LOG}" || true)"
FAIL_COUNT="$(grep -Ec \
    '\[(NPU-F32-GATHER-REPEAT-PORTAL|F32-GATHER-REPEAT-PORTAL)\]\[FAIL\]|%Error|%Fatal' \
    "${RUN_LOG}" || true)"

{
    printf 'schema=f32-gather-repeat-portal-result-v1\n'
    printf 'build_exit=%d\nrun_exit=%d\n' "${BUILD_EXIT}" "${RUN_EXIT}"
    printf 'pass_markers=%s\nfailure_markers=%s\nwarnings=%s\n' \
        "${PASS_COUNT}" "${FAIL_COUNT}" "${WARNING_COUNT}"
    printf 'verilator_flags=--binary --timing --sv -O3 --no-assert --no-trace -CFLAGS=-O3\n'
    printf 'lanes=16\nscenarios=5\nraw_gmem_bytes=0\n'
    printf 'get_rows_shape=N5xD19\nget_rows_groups=21\n'
    printf 'get_rows_read_words=100\nget_rows_write_words=95\n'
    printf 'repeat_shape=O3xR4xD18\nrepeat_groups=30\n'
    printf 'repeat_read_words=54\nrepeat_write_words=216\n'
    sha256sum \
        rtl/TensorNpuF32GatherRepeatPortalAdapter.v \
        tests/tb_f32_gather_repeat_portal_adapter.sv \
        scripts/run_f32_gather_repeat_portal_adapter.sh \
        rtl/TensorNpuF32GatherRepeatAdapter.v
} >"${RESULT_LOG}"

if [[ "${RUN_EXIT}" -ne 0 || "${PASS_COUNT}" -ne 1 || \
      "${FAIL_COUNT}" -ne 0 || "${WARNING_COUNT}" -ne 0 ]]; then
    printf '[F32-GATHER-REPEAT-PORTAL][FAIL] phase=run exit=%d pass=%s failures=%s warnings=%s log=%s\n' \
        "${RUN_EXIT}" "${PASS_COUNT}" "${FAIL_COUNT}" \
        "${WARNING_COUNT}" "${RUN_LOG}"
    exit 1
fi

printf '[F32-GATHER-REPEAT-PORTAL][PASS] build_exit=0 run_exit=0 pass=1 failures=0 warnings=0 assertions=off waveforms=off optimization=O3 build=%s log=%s result=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${RESULT_LOG}"
