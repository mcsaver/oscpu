#!/usr/bin/env bash
set -Eeuo pipefail

# Compile-only entry point for the current Qwen F32 ALU RTL/backend sources.
# Ordinary use is one continuous dependency-check -> configure -> build ->
# result-collection run. Historical outputs and earlier versioned runners are
# deliberately not inputs to this build.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
NPU_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
WORKSPACE_ROOT="$(cd -- "${NPU_ROOT}/../.." && pwd -P)"
CMAKE_SOURCE_DIR="${NPU_ROOT}/runtime/llama-npu-backend"
WARNING_BASELINE="${SCRIPT_DIR}/qwen_f32_alu_warning_baseline.tsv"
RESULT_COLLECTOR="${SCRIPT_DIR}/qwen_f32_alu_compile_result.py"

export LC_ALL=C
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH="${NPU_ROOT}/tools/cmake-python${PYTHONPATH:+:${PYTHONPATH}}"

MODE=collect
MODE_WAS_SET=0
BUILD_DIR=""
LOG_DIR=""
JOBS="${NPU_BUILD_JOBS:-}"
CMAKE_EXE="${NPU_CMAKE:-}"
MAKE_EXE=""
CXX_EXE=""
AR_EXE=""
RANLIB_EXE=""
VERILATOR_EXE=""
VERILATOR_BIN_EXE=""
VERILATOR_ROOT=""
CMAKE_VERSION=""
VERILATOR_VERSION=""

RTL_SOURCES=(
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
    third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    rtl/TensorNpuFp32AddMul.v
    rtl/TensorNpuF32TensorAlu.v
    rtl/TensorNpuVectorF32Adapter.v
    rtl/TensorNpuCoprocessor.v
    rtl/TensorNpuCommandDecoder.v
    rtl/TensorNpuRegisterFile.v
    rtl/TensorNpuMm2Engine.v
    rtl/TensorNpuDmaEngine.v
    rtl/TensorNpuLocalMemory.v
    rtl/tensor_npu_defs.vh
)

usage() {
    cat <<'EOF'
Usage:
  run-qwen-f32-alu-families-compile-v14.sh [--collect] [options]
  run-qwen-f32-alu-families-compile-v14.sh --preflight [options]

Modes:
  --collect             Check dependencies, configure, compile and collect the
                        real build result in one invocation (default).
  --preflight           Run only low-cost dependency/input diagnostics. It
                        creates no build/log directory and is not a build
                        prerequisite.

Options:
  --build-dir DIR       Use DIR for CMake and Verilator outputs. Without this
                        option, a new independent directory is created below
                        tmp/build/ for this invocation.
  --log-dir DIR         Create a fresh run directory below DIR for commands,
                        logs, rc files and result.json. The default parent is
                        BUILD_DIR/logs.
  --jobs N              Parallel CMake/Verilator jobs (default: NPU_BUILD_JOBS
                        or the host processor count).
  --cmake PATH          CMake executable (default: NPU_CMAKE, project-local
                        CMake, then PATH).
  -h, --help            Show this help.

The command is compile-only: it does not run the generated backend test, model,
Qwen workload, synthesis, STA or PPA. Build outputs are retained and their
locations are printed on success and failure.
EOF
}

fail() {
    printf '[QWEN-F32-ALU-COMPILE][FAIL] %s\n' "$*" >&2
    return 1
}

usage_error() {
    printf '[QWEN-F32-ALU-COMPILE][FAIL] %s\n' "$*" >&2
    exit 2
}

set_mode() {
    local requested="$1"
    if [[ "${MODE_WAS_SET}" -eq 1 && "${MODE}" != "${requested}" ]]; then
        usage_error "--preflight and --collect are mutually exclusive"
    fi
    MODE="${requested}"
    MODE_WAS_SET=1
}

require_option_value() {
    local option="$1"
    local value="${2:-}"
    [[ -n "${value}" ]] || usage_error "${option} requires a value"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --preflight)
            set_mode preflight
            shift
            ;;
        --collect)
            set_mode collect
            shift
            ;;
        --build-dir)
            require_option_value "$1" "${2:-}"
            BUILD_DIR="$2"
            shift 2
            ;;
        --build-dir=*)
            BUILD_DIR="${1#*=}"
            require_option_value --build-dir "${BUILD_DIR}"
            shift
            ;;
        --log-dir)
            require_option_value "$1" "${2:-}"
            LOG_DIR="$2"
            shift 2
            ;;
        --log-dir=*)
            LOG_DIR="${1#*=}"
            require_option_value --log-dir "${LOG_DIR}"
            shift
            ;;
        --jobs)
            require_option_value "$1" "${2:-}"
            JOBS="$2"
            shift 2
            ;;
        --jobs=*)
            JOBS="${1#*=}"
            require_option_value --jobs "${JOBS}"
            shift
            ;;
        --cmake)
            require_option_value "$1" "${2:-}"
            CMAKE_EXE="$2"
            shift 2
            ;;
        --cmake=*)
            CMAKE_EXE="${1#*=}"
            require_option_value --cmake "${CMAKE_EXE}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf '[QWEN-F32-ALU-COMPILE][FAIL] unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "${JOBS}" ]]; then
    if command -v nproc >/dev/null 2>&1; then
        JOBS="$(nproc)"
    else
        JOBS=1
    fi
fi
[[ "${JOBS}" =~ ^[1-9][0-9]*$ ]] ||
    usage_error "--jobs must be a positive integer: ${JOBS}"

require_regular() {
    [[ -f "$1" ]] || fail "required file is missing: $1"
}

resolve_command() {
    local name="$1"
    local resolved
    resolved="$(command -v -- "${name}")" || fail "required command is missing: ${name}"
    realpath -- "${resolved}"
}

resolve_tools() {
    command -v realpath >/dev/null 2>&1 || fail "required command is missing: realpath"
    command -v python3 >/dev/null 2>&1 || fail "required command is missing: python3"

    if [[ -z "${CMAKE_EXE}" ]]; then
        if [[ -x "${NPU_ROOT}/tools/cmake-python/bin/cmake" ]]; then
            CMAKE_EXE="${NPU_ROOT}/tools/cmake-python/bin/cmake"
        elif [[ -x "${NPU_ROOT}/tmp/tools/cmake-3.31.12/bin/cmake" ]]; then
            CMAKE_EXE="${NPU_ROOT}/tmp/tools/cmake-3.31.12/bin/cmake"
        else
            CMAKE_EXE="$(resolve_command cmake)"
        fi
    fi
    [[ -x "${CMAKE_EXE}" ]] || fail "CMake is not executable: ${CMAKE_EXE}"
    CMAKE_EXE="$(realpath -- "${CMAKE_EXE}")"
    CMAKE_VERSION="$("${CMAKE_EXE}" --version | sed -n '1p')"

    MAKE_EXE="$(resolve_command make)"
    CXX_EXE="$(resolve_command c++)"
    AR_EXE="$(resolve_command ar)"
    RANLIB_EXE="$(resolve_command ranlib)"
    VERILATOR_EXE="$(resolve_command verilator)"
    VERILATOR_BIN_EXE="$(resolve_command verilator_bin)"
    VERILATOR_VERSION="$("${VERILATOR_EXE}" --version | sed -n '1p')"
    VERILATOR_ROOT="$("${VERILATOR_EXE}" --getenv VERILATOR_ROOT)"
    [[ -n "${VERILATOR_ROOT}" && -d "${VERILATOR_ROOT}" ]] ||
        fail "Verilator did not report a usable VERILATOR_ROOT"
    VERILATOR_ROOT="$(realpath -- "${VERILATOR_ROOT}")"
}

check_direct_inputs() {
    require_regular "${CMAKE_SOURCE_DIR}/CMakeLists.txt"
    require_regular "${CMAKE_SOURCE_DIR}/npu-verilator-runner.cpp"
    require_regular "${CMAKE_SOURCE_DIR}/npu-verilator-runner.h"
    require_regular "${CMAKE_SOURCE_DIR}/ggml-npu.cpp"
    require_regular "${CMAKE_SOURCE_DIR}/test-backend.cpp"
    require_regular "${NPU_ROOT}/third_party/llama.cpp/ggml/src/ggml-backend-impl.h"
    require_regular "${NPU_ROOT}/tmp/build/llama.cpp/bin/libggml-base.so"
    require_regular "${NPU_ROOT}/tmp/build/llama.cpp/bin/libggml.so"
    require_regular "${VERILATOR_ROOT}/include/verilated.cpp"
    require_regular "${VERILATOR_ROOT}/include/verilated_threads.cpp"
    require_regular "${VERILATOR_ROOT}/include/verilated_std.sv"
    require_regular "${WARNING_BASELINE}"
    require_regular "${RESULT_COLLECTOR}"
    local source
    for source in "${RTL_SOURCES[@]}"; do
        require_regular "${NPU_ROOT}/${source}"
    done
}

print_context() {
    printf 'mode=%s\n' "${MODE}"
    printf 'cmake=%s\n' "${CMAKE_EXE}"
    printf 'cmake_version=%s\n' "${CMAKE_VERSION}"
    printf 'make=%s\n' "${MAKE_EXE}"
    printf 'cxx=%s\n' "${CXX_EXE}"
    printf 'verilator=%s\n' "${VERILATOR_EXE}"
    printf 'verilator_version=%s\n' "${VERILATOR_VERSION}"
    printf 'verilator_root=%s\n' "${VERILATOR_ROOT}"
    printf 'source_dir=%s\n' "${CMAKE_SOURCE_DIR}"
    printf 'rtl_source_count=%d\n' "${#RTL_SOURCES[@]}"
    printf 'warning_baseline=%s\n' "${WARNING_BASELINE}"
    printf 'jobs=%s\n' "${JOBS}"
    printf 'build_dir=%s\n' "${BUILD_DIR:-<automatic-independent-directory>}"
    printf 'log_dir=%s\n' "${LOG_DIR:-<fresh-directory-under-build-dir>}"
    printf 'compile_scope=binary-build-only\n'
    printf 'generated_binary_runs=0\n'
    printf 'model_runs=0\n'
}

resolve_tools
check_direct_inputs

if [[ "${MODE}" == preflight ]]; then
    print_context
    printf '[QWEN-F32-ALU-COMPILE][PREFLIGHT-PASS] build_started=0 scope=dependency-diagnostics\n'
    exit 0
fi

if [[ -z "${BUILD_DIR}" ]]; then
    mkdir -p -- "${NPU_ROOT}/tmp/build"
    BUILD_DIR="$(mktemp -d "${NPU_ROOT}/tmp/build/qwen-f32-alu-compile.XXXXXX")"
else
    BUILD_DIR="$(realpath -m -- "${BUILD_DIR}")"
    mkdir -p -- "${BUILD_DIR}"
fi
CMAKE_BUILD_DIR="${BUILD_DIR}/cmake"
VERILATED_DIR="${BUILD_DIR}/verilated"

if [[ -z "${LOG_DIR}" ]]; then
    LOG_PARENT="${BUILD_DIR}/logs"
else
    LOG_PARENT="$(realpath -m -- "${LOG_DIR}")"
fi
mkdir -p -- "${LOG_PARENT}"
LOG_DIR="$(mktemp -d "${LOG_PARENT}/run.XXXXXX")"

CONFIGURE_LOG="${LOG_DIR}/cmake-configure.log"
CONFIGURE_RC="${LOG_DIR}/cmake-configure.rc"
BUILD_LOG="${LOG_DIR}/cmake-build.log"
BUILD_RC="${LOG_DIR}/cmake-build.rc"
RESULT_LOG="${LOG_DIR}/result-collector.log"
RESULT_RC="${LOG_DIR}/result-collector.rc"
RESULT_JSON="${LOG_DIR}/result.json"
ACTUAL_WARNINGS="${LOG_DIR}/actual-warning-census.tsv"

CONFIGURE_COMMAND=(
    "${CMAKE_EXE}" -S "${CMAKE_SOURCE_DIR}" -B "${CMAKE_BUILD_DIR}"
    -G "Unix Makefiles"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DCMAKE_VERBOSE_MAKEFILE=ON
    "-DCMAKE_CXX_COMPILER=${CXX_EXE}"
    "-DCMAKE_AR=${AR_EXE}"
    "-DCMAKE_RANLIB=${RANLIB_EXE}"
    "-DCMAKE_MAKE_PROGRAM=${MAKE_EXE}"
    "-DVERILATOR_EXECUTABLE=${VERILATOR_EXE}"
    "-DNPU_VERILATED_MDIR=${VERILATED_DIR}"
    "-DNPU_VERILATOR_JOBS=${JOBS}"
    "-DLLAMA_SOURCE_DIR=${NPU_ROOT}/third_party/llama.cpp"
    "-DLLAMA_BUILD_BIN=${NPU_ROOT}/tmp/build/llama.cpp/bin"
    "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG"
)
BUILD_COMMAND=(
    "${CMAKE_EXE}" --build "${CMAKE_BUILD_DIR}" --config Release
    --target all --parallel "${JOBS}" --verbose
)

write_command() {
    local output="$1"
    shift
    printf '%q ' "$@" >"${output}"
    printf '\n' >>"${output}"
}

write_command "${LOG_DIR}/cmake-configure.command" "${CONFIGURE_COMMAND[@]}"
write_command "${LOG_DIR}/cmake-build.command" "${BUILD_COMMAND[@]}"
print_context >"${LOG_DIR}/build-context.txt"
{
    printf 'rtl_source_order:\n'
    printf '  %s\n' "${RTL_SOURCES[@]}"
    printf 'verilator_flags=--cc -O3 -Wall -Wno-fatal --no-assert --no-trace\n'
    printf 'model_cflags=-O3 -DNDEBUG -march=native -fPIC\n'
} >>"${LOG_DIR}/build-context.txt"

run_logged() {
    local stage="$1"
    local log="$2"
    local rc_path="$3"
    shift 3
    local rc
    printf '[QWEN-F32-ALU-COMPILE][RUN] stage=%s log=%s\n' "${stage}" "${log}"
    set +e
    (cd -- "${WORKSPACE_ROOT}" && "$@") >"${log}" 2>&1
    rc=$?
    set -e
    printf '%d\n' "${rc}" >"${rc_path}"
    if [[ "${rc}" -ne 0 ]]; then
        tail -n 160 -- "${log}" >&2
    fi
    return "${rc}"
}

write_failure() {
    local stage="$1"
    local rc="$2"
    {
        printf 'status=FAIL\n'
        printf 'stage=%s\n' "${stage}"
        printf 'rc=%s\n' "${rc}"
        printf 'build_dir=%s\n' "${BUILD_DIR}"
        printf 'log_dir=%s\n' "${LOG_DIR}"
    } >"${LOG_DIR}/result.txt"
    printf '[QWEN-F32-ALU-COMPILE][FAIL] stage=%s rc=%s build_dir=%s log_dir=%s\n' \
        "${stage}" "${rc}" "${BUILD_DIR}" "${LOG_DIR}" >&2
}

if ! run_logged configure "${CONFIGURE_LOG}" "${CONFIGURE_RC}" \
        "${CONFIGURE_COMMAND[@]}"; then
    rc="$(<"${CONFIGURE_RC}")"
    write_failure configure "${rc}"
    exit "${rc}"
fi

if ! run_logged build "${BUILD_LOG}" "${BUILD_RC}" "${BUILD_COMMAND[@]}"; then
    rc="$(<"${BUILD_RC}")"
    write_failure build "${rc}"
    exit "${rc}"
fi

COLLECT_COMMAND=(
    python3 "${RESULT_COLLECTOR}"
    --workspace-root "${WORKSPACE_ROOT}"
    --npu-root "${NPU_ROOT}"
    --cmake-build-dir "${CMAKE_BUILD_DIR}"
    --verilated-dir "${VERILATED_DIR}"
    --verilator-bin "${VERILATOR_BIN_EXE}"
    --verilator-std "${VERILATOR_ROOT}/include/verilated_std.sv"
    --warning-baseline "${WARNING_BASELINE}"
    --log "${CONFIGURE_LOG}"
    --log "${BUILD_LOG}"
    --actual-warnings "${ACTUAL_WARNINGS}"
    --summary "${RESULT_JSON}"
)
for source in "${RTL_SOURCES[@]}"; do
    COLLECT_COMMAND+=(--source "${source}")
done
write_command "${LOG_DIR}/result-collector.command" "${COLLECT_COMMAND[@]}"

set +e
"${COLLECT_COMMAND[@]}" >"${RESULT_LOG}" 2>&1
rc=$?
set -e
printf '%d\n' "${rc}" >"${RESULT_RC}"
if [[ "${rc}" -ne 0 ]]; then
    tail -n 160 -- "${RESULT_LOG}" >&2
    write_failure result-collection "${rc}"
    exit "${rc}"
fi

printf '[QWEN-F32-ALU-COMPILE][PASS] source_count=%d warning_count=%d compile_only=1 binary_runs=0 model_runs=0 build_dir=%s log_dir=%s result=%s\n' \
    "${#RTL_SOURCES[@]}" "$(wc -l <"${ACTUAL_WARNINGS}")" \
    "${BUILD_DIR}" "${LOG_DIR}" "${RESULT_JSON}"
