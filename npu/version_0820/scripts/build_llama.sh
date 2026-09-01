#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cmake_bin="${project_root}/tools/cmake-python/bin/cmake"
source_dir="${project_root}/third_party/llama.cpp"

mkdir -p -- "${project_root}/tmp"
project_tmp="$(realpath -e -- "${project_root}/tmp")"

fail_path() {
    printf '%s path must resolve inside project tmp (%s): %s\n' \
        "$1" "${project_tmp}" "$2" >&2
    exit 2
}

resolve_tmp_path() {
    local label="$1"
    local raw_path="$2"
    local candidate
    local resolved

    [[ -n "${raw_path}" ]] || fail_path "${label}" "<empty>"
    case "${raw_path}" in
        /*) candidate="${raw_path}" ;;
        *) candidate="${project_root}/${raw_path}" ;;
    esac
    resolved="$(realpath -m -- "${candidate}")"
    case "${resolved}" in
        "${project_tmp}"|"${project_tmp}/"*) ;;
        *) fail_path "${label}" "${raw_path}" ;;
    esac
    printf '%s\n' "${resolved}"
}

prepare_tmp_dir() {
    local label="$1"
    local resolved

    resolved="$(resolve_tmp_path "${label}" "$2")"
    mkdir -p -- "${resolved}"
    resolved="$(realpath -e -- "${resolved}")"
    case "${resolved}" in
        "${project_tmp}"|"${project_tmp}/"*) ;;
        *) fail_path "${label}" "$2" ;;
    esac
    printf '%s\n' "${resolved}"
}

build_dir="$(prepare_tmp_dir LLAMA_BUILD_DIR \
    "${LLAMA_BUILD_DIR:-${project_tmp}/build/llama.cpp}")"
runtime_tmp="$(prepare_tmp_dir TMPDIR \
    "${TMPDIR:-${project_tmp}/runtime-tmp}")"
tmp_dir="$(prepare_tmp_dir TMP "${TMP:-${runtime_tmp}}")"
temp_dir="$(prepare_tmp_dir TEMP "${TEMP:-${runtime_tmp}}")"
cache_dir="$(prepare_tmp_dir XDG_CACHE_HOME \
    "${XDG_CACHE_HOME:-${project_tmp}/cache}")"

llama_log_dir=''
if [[ -n "${LLAMA_LOG_DIR:-}" ]]; then
    llama_log_dir="$(prepare_tmp_dir LLAMA_LOG_DIR "${LLAMA_LOG_DIR}")"
fi

if [[ ! -x "${cmake_bin}" ]]; then
    printf 'missing project-local CMake: %s\n' "${cmake_bin}" >&2
    exit 2
fi

export TMPDIR="${runtime_tmp}"
export TMP="${tmp_dir}"
export TEMP="${temp_dir}"
export XDG_CACHE_HOME="${cache_dir}"
export PYTHONPATH="${project_root}/tools/cmake-python"

"${cmake_bin}" --fresh -S "${source_dir}" -B "${build_dir}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_BACKEND_DL=ON \
    -DGGML_NATIVE=OFF \
    -DGGML_CPU_ALL_VARIANTS=ON \
    -DGGML_LLAMAFILE=OFF \
    -DGGML_CCACHE=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TOOLS=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_BUILD_APP=OFF \
    -DLLAMA_BUILD_UI=OFF \
    -DLLAMA_USE_PREBUILT_UI=OFF \
    -DLLAMA_BUILD_NUMBER=10507 \
    -DLLAMA_BUILD_COMMIT=95c409c13625a23da2aa37270339ce9179215a18 \
    -DGIT_EXE:FILEPATH=OFF

parallelism="${NPU_BUILD_JOBS:-$(nproc)}"
"${cmake_bin}" --build "${build_dir}" --clean-first \
    --target llama-cli llama-completion llama-bench \
    --parallel "${parallelism}"

if [[ -n "${llama_log_dir}" ]]; then
    "${build_dir}/bin/llama-cli" --version 2>&1 \
        | tee "${llama_log_dir}/llama-version.log"
else
    "${build_dir}/bin/llama-cli" --version
fi
