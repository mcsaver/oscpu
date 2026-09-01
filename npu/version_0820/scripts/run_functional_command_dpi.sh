#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_ROOT="$(realpath -e -- "${ROOT}/tmp")"
RUN_ID="functional-command-dpi-$(date -u +%Y%m%dT%H%M%S)-$$"
BUILD_DIR="$(realpath -m -- "${TMP_ROOT}/build/${RUN_ID}")"
LOG_DIR="$(realpath -m -- "${TMP_ROOT}/logs/${RUN_ID}")"
OBJ_DIR="$(realpath -m -- "${BUILD_DIR}/obj_dir")"
COMPILER_TMP_DIR="$(realpath -m -- "${TMP_ROOT}/compiler/${RUN_ID}")"
CACHE_DIR="$(realpath -m -- "${TMP_ROOT}/cache/${RUN_ID}")"
CORE="${ROOT}/rtl/TensorNpuFunctionalCommandDpi.sv"
TB="${ROOT}/tests/tb_functional_command_dpi.sv"
STUB="${ROOT}/tests/npu-functional-command-dpi-stub.cpp"
RUNNER="${ROOT}/scripts/run_functional_command_dpi.sh"

for generated_path in \
    "${BUILD_DIR}" "${LOG_DIR}" "${OBJ_DIR}" \
    "${COMPILER_TMP_DIR}" "${CACHE_DIR}"; do
    case "${generated_path}" in
        "${TMP_ROOT}"|"${TMP_ROOT}/"*) ;;
        *)
            printf 'generated path escapes project tmp: %s\n' \
                "${generated_path}" >&2
            exit 2
            ;;
    esac
done

mkdir -p -- \
    "${OBJ_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" "${CACHE_DIR}"
export TMPDIR="${COMPILER_TMP_DIR}"
export TMP="${COMPILER_TMP_DIR}"
export TEMP="${COMPILER_TMP_DIR}"
export XDG_CACHE_HOME="${CACHE_DIR}"
unset MAKEFLAGS MFLAGS

printf '%s\n' "${CORE}" "${TB}" "${STUB}" >"${LOG_DIR}/sources.f"

/usr/bin/c++ \
    -isystem /usr/share/verilator/include \
    -isystem /usr/share/verilator/include/vltstd \
    -O3 -DNDEBUG -std=c++17 \
    -Wall -Wextra -Wpedantic \
    -fsyntax-only "${STUB}" \
    >"${LOG_DIR}/stub-warning-audit.log" 2>&1
if [[ -s "${LOG_DIR}/stub-warning-audit.log" ]]; then
    sed -n '1,200p' "${LOG_DIR}/stub-warning-audit.log" >&2
    printf 'test DPI stub emitted a compiler diagnostic\n' >&2
    exit 1
fi

verilator \
    --binary \
    --build-jobs 2 \
    -MAKEFLAGS "OPT_FAST=-O3 OPT_SLOW=-O3 OPT_GLOBAL=-O3" \
    --timing \
    --sv \
    -Wall \
    -Wno-fatal \
    --no-assert \
    --no-trace \
    -O3 \
    -CFLAGS "-O3 -DNDEBUG -std=c++17" \
    --Mdir "${OBJ_DIR}" \
    --top-module tb_functional_command_dpi \
    "${CORE}" \
    "${TB}" \
    "${STUB}" \
    >"${LOG_DIR}/build.log" 2>&1

if grep -Eq \
    '^%Warning|^%Error|(^|[[:space:]:])(warning:|error:|fatal error:)' \
    "${LOG_DIR}/build.log"; then
    sed -n '1,240p' "${LOG_DIR}/build.log" >&2
    printf 'unexpected compiler diagnostic; see %s\n' \
        "${LOG_DIR}/build.log" >&2
    exit 1
fi

set -o pipefail
/usr/bin/time \
    -f 'wall_seconds=%e user_seconds=%U sys_seconds=%S max_rss_kb=%M' \
    -o "${LOG_DIR}/run-time.log" \
    "${OBJ_DIR}/Vtb_functional_command_dpi" \
    | tee "${LOG_DIR}/run.log"

grep -Fq \
    '[NPU-FUNCTIONAL-COMMAND-DPI][PASS] positive=1 dpi_error=1 closure_error=1 callback_error=1 status_error=1 reset_no_call=1 disable_no_call=1 busy_single_dispatch=1 terminal_stable=1 calls=5 dispatch=5 completion=5' \
    "${LOG_DIR}/run.log"

find "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" \
    -type f \
    \( -iname '*.vcd' -o -iname '*.fst' -o -iname '*.lxt' \
       -o -iname '*.lxt2' -o -iname '*.ghw' \) \
    -print >"${LOG_DIR}/waveform-find.log"
if [[ -s "${LOG_DIR}/waveform-find.log" ]]; then
    printf 'waveform artifact found in fresh-run paths\n' >&2
    exit 1
fi

sha256sum "${CORE}" "${TB}" "${STUB}" "${RUNNER}" \
    >"${LOG_DIR}/sha256.log"

printf '[NPU-FUNCTIONAL-COMMAND-DPI-RUNNER][PASS] build=O3 assertions=off trace=off warnings=0 errors=0\n'
printf 'build_dir=%s\nlog_dir=%s\ncompiler_tmp_dir=%s\nsha256=%s\n' \
    "${BUILD_DIR}" "${LOG_DIR}" "${COMPILER_TMP_DIR}" \
    "${LOG_DIR}/sha256.log"
