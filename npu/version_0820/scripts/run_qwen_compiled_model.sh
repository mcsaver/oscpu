#!/usr/bin/env bash
# Real Qwen bootstrap -> steady acceptance through the compiled model backend.
set -Eeuo pipefail
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(realpath -- "${SCRIPT_DIR}/..")"
readonly WORKBENCH_ROOT="$(realpath -- "${PROJECT_ROOT}/../..")"
cd -- "${PROJECT_ROOT}"
if [[ "${1:-}" == --help ]]; then
    printf '%s\n' 'Usage: scripts/run_qwen_compiled_model.sh [NEW_RUN_DIRECTORY]' \
        'Uses the configured tmp/build/npu-compiled-backend-cmake tree.' \
        'Overrides: NPU_COMPILED_BUILD_DIR, NPU_COMPILED_CMAKE, NPU_LLAMA_BUILD_BIN.' \
        'A fresh build tree also needs NPU_BOOTSTRAP_MANIFEST and NPU_STEADY_MANIFEST.'
    exit 0
fi
readonly run_root="$(realpath -m -- "${1:-tmp/acceptance/qwen-compiled-$(date -u +%Y%m%dT%H%M%SZ)-${BASHPID}}")"
[[ ! -e "$run_root" ]] || { printf 'Output directory already exists: %s\n' "$run_root" >&2; exit 2; }
mkdir -p -- "$run_root"
source "${WORKBENCH_ROOT}/scripts/task-run-status.sh"
task_run_status_init "$run_root/STATUS"
trap 'rc=$?; trap - EXIT; task_run_status_finalize "$rc" 0; exit $?' EXIT
task_run_status_install_signal_traps
cp -- "${BASH_SOURCE[0]}" "$run_root/runner.sh"
readonly build_dir="$(realpath -m -- "${NPU_COMPILED_BUILD_DIR:-tmp/build/npu-compiled-backend-cmake}")"
readonly llama_bin="$(realpath -m -- "${NPU_LLAMA_BUILD_BIN:-tmp/build/llama.cpp/bin}")"
readonly cmake="${NPU_COMPILED_CMAKE:-${PROJECT_ROOT}/tools/cmake-python/cmake/data/bin/cmake}"
readonly model="${PROJECT_ROOT}/models/Qwen3.5-0.8B-Q8_0.gguf"
readonly oracle="${PROJECT_ROOT}/tests/vectors/qwen35_08b_q8_0/strict-smoke-oracle.json"

task_run_status_stage verify-inputs
python3 - "$model" "$oracle" <<'PY' > "$run_root/model-identity.json"
import hashlib,json,pathlib,sys
model,oracle=map(pathlib.Path,sys.argv[1:])
digest=hashlib.sha256()
with model.open("rb") as stream:
    for block in iter(lambda:stream.read(1<<20),b""):digest.update(block)
expected=json.loads(oracle.read_text())["model_sha256"]
if digest.hexdigest()!=expected:raise SystemExit("model SHA-256 does not match frozen token oracle")
print(json.dumps({"model_sha256":digest.hexdigest(),"model_path":str(model),"model_bytes":model.stat().st_size},indent=2))
PY
task_run_status_stage build-backend
if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
    "$cmake" -S runtime/llama-npu-backend -B "$build_dir" \
        -DLLAMA_BUILD_BIN="$llama_bin" \
        -DNPU_Q8_GEMV_MANIFEST="${NPU_BOOTSTRAP_MANIFEST:?canonical bootstrap manifest required}" \
        -DNPU_QWEN_STEADY_MANIFEST="${NPU_STEADY_MANIFEST:?canonical steady manifest required}" \
        > "$run_root/configure.log" 2>&1
fi
"$cmake" --build "$build_dir" --target ggml-npu-model -j 8 > "$run_root/build.log" 2>&1
task_run_status_stage build-token-capture
g++ -std=c++17 -O2 -fPIC -shared \
    -Ithird_party/llama.cpp/include -Ithird_party/llama.cpp/ggml/include \
    tools/qwen_token_capture.cpp -ldl -o "$run_root/libqwen-token-capture.so"
sha256sum "$build_dir/libggml-npu-model.so" "$build_dir/CMakeCache.txt" \
    "$build_dir/rv64-service-firmware/npu-service-firmware.bin" \
    "$llama_bin/llama-completion" "$run_root/libqwen-token-capture.so" \
    "$oracle" "$run_root/runner.sh" scripts/qwen_compiled_model_validate.py \
    > "$run_root/inputs.sha256"

task_run_status_stage model-generation
declare -a clean_env=()
for name in LLAMA_NPU_REQUIRED LLAMA_NPU_ADMISSION_ONLY LLAMA_NPU_GRAPH_COLLECT \
    LLAMA_NPU_GRAPH_COLLECT_DISPATCH LLAMA_NPU_STRICT_SAMPLING LLAMA_NPU_GRAPH_PROFILE \
    LLAMA_NPU_GRAPH_NUMERIC_PROFILE LLAMA_NPU_GRAPH_SOURCE_COMMIT \
    LLAMA_NPU_GRAPH_MODEL_SHA256 LLAMA_NPU_GRAPH_FUSED_OPS LLAMA_ARG_BACKEND_SAMPLING; do
    clean_env+=(-u "$name")
done
declare -a model_command=(
    env "${clean_env[@]}"
    LLAMA_NPU_REQUIRED=1 LLAMA_NPU_GRAPH_PROFILE=qwen35-0.8b-b1t1-unfused-nonflash-v5
    LLAMA_NPU_GRAPH_SOURCE_COMMIT=95c409c13625a23da2aa37270339ce9179215a18 LLAMA_NPU_GRAPH_FUSED_OPS=0
    "LLAMA_NPU_COMPILED_ARTIFACT_DIR=$run_root/artifacts"
    "GGML_BACKEND_PATH=$build_dir/libggml-npu-model.so"
    "LD_PRELOAD=$run_root/libqwen-token-capture.so"
    "QWEN_PROMPT_TOKEN_TRACE_PATH=$run_root/prompt.ids"
    "QWEN_TOKEN_TRACE_PATH=$run_root/generated.ids" "QWEN_TIMING_TRACE_PATH=$run_root/timing.jsonl"
    "$llama_bin/llama-completion" -m "$model"
    -c 256 -b 1 -ub 1 -t 1 -tb 1 -fa off -fit off --seed 1 --temp 0 --top-k 1
    --no-warmup --no-display-prompt --perf --no-conversation --reasoning off
    --simple-io --backend-sampling -p x -n 2
)
printf '%q ' "${model_command[@]}" > "$run_root/command.sh"
printf '\n' >> "$run_root/command.sh"
"${model_command[@]}" </dev/null > "$run_root/run.log" 2>&1
task_run_status_stage validate-real-tokens
python3 scripts/qwen_compiled_model_validate.py "$run_root" --oracle "$oracle" \
    | tee "$run_root/validation.log"
task_run_status_mark_evidence_complete
