#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly TMP_ROOT="$(realpath -m -- "${PROJECT_ROOT}/tmp")"
readonly VECTOR_ROOT="${PROJECT_ROOT}/tests/vectors/qwen35_08b_q8_0"
readonly MODEL="${PROJECT_ROOT}/models/Qwen3.5-0.8B-Q8_0.gguf"
readonly CLI="${TMP_ROOT}/build/llama.cpp/bin/llama-cli"
readonly EXPECTED_MODEL_SHA='37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f'
readonly EXPECTED_LLAMA_COMMIT='95c409c13625a23da2aa37270339ce9179215a18'
readonly RUN_ID="qwen35-08b-q8_0-cpu-oracle-$(date -u +%Y%m%dT%H%M%S)-${BASHPID}"
readonly RUN_ROOT="$(realpath -m -- "${TMP_ROOT}/acceptance/${RUN_ID}")"
readonly BUILD_ROOT="$(realpath -m -- "${TMP_ROOT}/build/${RUN_ID}")"
readonly RUNTIME_TMP="$(realpath -m -- "${TMP_ROOT}/runtime-tmp/${RUN_ID}")"
readonly CACHE_ROOT="$(realpath -m -- "${TMP_ROOT}/cache/${RUN_ID}")"
readonly HOOK="${BUILD_ROOT}/libqwen-token-capture.so"

fail() {
    printf '[QWEN-CPU-ORACLE][FAIL] %s\n' "$*" >&2
    exit 1
}

require_tmp_path() {
    case "$(realpath -m -- "$1")" in
        "${TMP_ROOT}"|"${TMP_ROOT}/"*) ;;
        *) fail "generated path escapes project tmp: $1" ;;
    esac
}

for generated_path in \
    "${RUN_ROOT}" "${BUILD_ROOT}" "${RUNTIME_TMP}" "${CACHE_ROOT}"; do
    require_tmp_path "${generated_path}"
    [[ ! -e "${generated_path}" ]] \
        || fail "fresh output path already exists: ${generated_path}"
done

for command_name in g++ jq nm sha256sum timeout /usr/bin/time; do
    command -v "${command_name}" >/dev/null 2>&1 \
        || fail "missing command: ${command_name}"
done
[[ -x "${CLI}" ]] || fail "pinned llama-cli is missing: ${CLI}"
[[ -f "${MODEL}" ]] || fail "Qwen model is missing: ${MODEL}"

mkdir -p -- "${RUN_ROOT}" "${BUILD_ROOT}" "${RUNTIME_TMP}" "${CACHE_ROOT}"
export TMPDIR="${RUNTIME_TMP}"
export TMP="${RUNTIME_TMP}"
export TEMP="${RUNTIME_TMP}"
export XDG_CACHE_HOME="${CACHE_ROOT}"
export PYTHONDONTWRITEBYTECODE=1

python3 "${PROJECT_ROOT}/scripts/verify_locked_inputs.py" \
    >"${RUN_ROOT}/locked-inputs.log" 2>&1 \
    || fail "locked source/model verification failed: ${RUN_ROOT}/locked-inputs.log"

readonly MODEL_SHA="$(sha256sum -- "${MODEL}" | awk '{ print $1 }')"
[[ "${MODEL_SHA}" == "${EXPECTED_MODEL_SHA}" ]] \
    || fail "model SHA-256 mismatch: ${MODEL_SHA}"

"${CLI}" --version >"${RUN_ROOT}/llama-version.log" 2>&1
grep -Fq "build 10507, commit ${EXPECTED_LLAMA_COMMIT}" \
    "${RUN_ROOT}/llama-version.log" \
    || fail "llama-cli identity mismatch"

env -u GGML_BACKEND_PATH -u LLAMA_NPU_REQUIRED \
    "${CLI}" --list-devices >"${RUN_ROOT}/devices.log" 2>&1
grep -Fxq '  (none)' "${RUN_ROOT}/devices.log" \
    || fail "CPU oracle unexpectedly discovered an offload device"

g++ -std=c++17 -O3 -DNDEBUG -fPIC -shared \
    "${PROJECT_ROOT}/tools/qwen_token_capture.cpp" -ldl -o "${HOOK}"
nm -D --defined-only "${HOOK}" | c++filt \
    | grep -Fq 'common_sampler_accept(common_sampler*, int, bool)' \
    || fail "token capture interposer symbol is missing"
readonly HOOK_SHA="$(sha256sum -- "${HOOK}" | awk '{ print $1 }')"

run_turn() {
    local turn_id="${1:?turn id is required}"
    local max_tokens="${2:?max tokens is required}"
    local prompt="${VECTOR_ROOT}/${turn_id}.txt"
    local turn_root="${RUN_ROOT}/${turn_id}"
    local prompt_ids="${turn_root}/prompt.ids"
    local generated_ids="${turn_root}/generated.ids"
    local prompt_ids_json="${turn_root}/prompt.ids.json"
    local generated_ids_json="${turn_root}/generated.ids.json"
    local run_log="${turn_root}/run.log"
    local command_log="${turn_root}/command.argv"
    local wall_log="${turn_root}/wall-seconds.txt"
    local result_json="${turn_root}/result.json"
    local prompt_sha
    local prompt_count
    local generated_count
    local timing_summary
    local prompt_tps
    local generation_tps
    local wall_seconds
    local run_rc
    local -a command_line=(
        "${CLI}"
        -m "${MODEL}"
        -f "${prompt}"
        -n "${max_tokens}"
        -c 256
        -b 64
        -ub 1
        -t 1
        -tb 1
        -fa off
        --seed 1
        --temp 0
        --top-k 1
        --no-warmup
        --no-mmproj
        --no-display-prompt
        --perf
        --show-timings
        -cnv
        -st
        --jinja
        --reasoning off
        --reasoning-budget 0
        --simple-io
        -co off
    )

    [[ -f "${prompt}" ]] || fail "missing prompt: ${prompt}"
    mkdir -- "${turn_root}"
    prompt_sha="$(sha256sum -- "${prompt}" | awk '{ print $1 }')"

    printf 'GGML_BACKEND_PATH=<unset> LLAMA_NPU_REQUIRED=<unset> ' \
        >"${command_log}"
    printf 'LD_PRELOAD=%q QWEN_PROMPT_TOKEN_TRACE_PATH=%q QWEN_TOKEN_TRACE_PATH=%q' \
        "${HOOK}" "${prompt_ids}" "${generated_ids}" >>"${command_log}"
    printf ' %q' "${command_line[@]}" >>"${command_log}"
    printf '\n' >>"${command_log}"

    set +e
    /usr/bin/time -f '%e' -o "${wall_log}" \
        env -u GGML_BACKEND_PATH \
            -u LLAMA_NPU_REQUIRED \
            -u LLAMA_NPU_GRAPH_COLLECT \
            -u LLAMA_NPU_GRAPH_PROFILE \
            -u LLAMA_NPU_GRAPH_NUMERIC_PROFILE \
            LD_PRELOAD="${HOOK}" \
            QWEN_PROMPT_TOKEN_TRACE_PATH="${prompt_ids}" \
            QWEN_TOKEN_TRACE_PATH="${generated_ids}" \
            timeout --signal=TERM --kill-after=2s 180s \
            "${command_line[@]}" >"${run_log}" 2>&1
    run_rc=$?
    set -e
    [[ "${run_rc}" -eq 0 ]] \
        || fail "${turn_id} CPU reference failed with rc=${run_rc}: ${run_log}"

    [[ -s "${prompt_ids}" && -s "${generated_ids}" ]] \
        || fail "${turn_id} token trace is empty"
    if grep -Evq '^[0-9]+$' "${prompt_ids}" ||
       grep -Evq '^[0-9]+$' "${generated_ids}"; then
        fail "${turn_id} token trace contains a non-integer"
    fi

    prompt_count="$(wc -l <"${prompt_ids}")"
    generated_count="$(wc -l <"${generated_ids}")"
    (( prompt_count > 0 && prompt_count <= 64 )) \
        || fail "${turn_id} prompt token count is outside logical batch: ${prompt_count}"
    (( generated_count > 0 && generated_count <= max_tokens )) \
        || fail "${turn_id} generated token count is invalid: ${generated_count}"

    timing_summary="$(grep -E '^\[ Prompt: [0-9]+([.][0-9]+)? t/s \| Generation: [0-9]+([.][0-9]+)? t/s \]$' \
        "${run_log}" || true)"
    [[ "$(printf '%s\n' "${timing_summary}" | sed '/^$/d' | wc -l)" -eq 1 ]] \
        || fail "${turn_id} exact timing summary is missing or duplicated"
    prompt_tps="$(printf '%s\n' "${timing_summary}" \
        | sed -E 's/^\[ Prompt: ([0-9]+([.][0-9]+)?) t\/s \| Generation: ([0-9]+([.][0-9]+)?) t\/s \]$/\1/')"
    generation_tps="$(printf '%s\n' "${timing_summary}" \
        | sed -E 's/^\[ Prompt: ([0-9]+([.][0-9]+)?) t\/s \| Generation: ([0-9]+([.][0-9]+)?) t\/s \]$/\3/')"
    wall_seconds="$(tr -d '[:space:]' <"${wall_log}")"
    awk -v value="${prompt_tps}" 'BEGIN { exit !(value + 0 > 0) }' \
        || fail "${turn_id} prompt tokens/s is not positive: ${prompt_tps}"
    awk -v value="${generation_tps}" 'BEGIN { exit !(value + 0 > 0) }' \
        || fail "${turn_id} generation tokens/s is not positive: ${generation_tps}"
    awk -v value="${wall_seconds}" 'BEGIN { exit !(value + 0 > 0) }' \
        || fail "${turn_id} wall time is not positive: ${wall_seconds}"

    if grep -Eq '\[NPU-STRICT\]|\[NPU-BACKEND|\[NPU-GRAPH-COLLECT' \
        "${run_log}"; then
        fail "${turn_id} CPU oracle unexpectedly entered an NPU path"
    fi

    jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)' \
        "${prompt_ids}" >"${prompt_ids_json}"
    jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)' \
        "${generated_ids}" >"${generated_ids_json}"
    jq -n \
        --arg turn "${turn_id}" \
        --arg prompt_file "tests/vectors/qwen35_08b_q8_0/${turn_id}.txt" \
        --arg prompt_sha256 "${prompt_sha}" \
        --arg run_log "${run_log}" \
        --arg command_log "${command_log}" \
        --argjson max_generated_tokens "${max_tokens}" \
        --argjson prompt_tokens "${prompt_count}" \
        --argjson generated_tokens "${generated_count}" \
        --argjson prompt_tps "${prompt_tps}" \
        --argjson generation_tps "${generation_tps}" \
        --argjson elapsed_wall_seconds "${wall_seconds}" \
        --slurpfile prompt_token_ids "${prompt_ids_json}" \
        --slurpfile generated_token_ids "${generated_ids_json}" \
        '{
            turn: $turn,
            prompt_file: $prompt_file,
            prompt_sha256: $prompt_sha256,
            max_generated_tokens: $max_generated_tokens,
            prompt_tokens: $prompt_tokens,
            prompt_token_ids: $prompt_token_ids[0],
            generated_tokens: $generated_tokens,
            generated_token_ids: $generated_token_ids[0],
            prompt_tps: $prompt_tps,
            generation_tps: $generation_tps,
            elapsed_wall_seconds: $elapsed_wall_seconds,
            run_log: $run_log,
            command_log: $command_log
        }' >"${result_json}"

    printf '[QWEN-CPU-ORACLE][TURN-PASS] turn=%s prompt_tokens=%s generated_tokens=%s prompt_tps=%s generation_tps=%s elapsed_s=%s\n' \
        "${turn_id}" "${prompt_count}" "${generated_count}" \
        "${prompt_tps}" "${generation_tps}" "${wall_seconds}"
}

run_turn turn1 8
run_turn turn2 12
run_turn turn3 24

jq -s \
    --arg schema 'qwen35-08b-q8_0-cpu-oracle-v1' \
    --arg model 'models/Qwen3.5-0.8B-Q8_0.gguf' \
    --arg model_sha256 "${MODEL_SHA}" \
    --arg llama_commit "${EXPECTED_LLAMA_COMMIT}" \
    --arg hook_sha256 "${HOOK_SHA}" \
    --arg run_root "${RUN_ROOT}" \
    '{
        schema: $schema,
        oracle: "pinned llama.cpp portable host reference",
        model: $model,
        model_sha256: $model_sha256,
        llama_build: 10507,
        llama_commit: $llama_commit,
        seed: 1,
        temperature: 0,
        top_k: 1,
        ctx_size: 256,
        logical_batch: 64,
        physical_ubatch: 1,
        threads: 1,
        threads_batch: 1,
        flash_attention: false,
        warmup: false,
        conversation: true,
        single_turn: true,
        jinja: true,
        reasoning: false,
        token_capture_sha256: $hook_sha256,
        run_root: $run_root,
        turns: .
    }' \
    "${RUN_ROOT}/turn1/result.json" \
    "${RUN_ROOT}/turn2/result.json" \
    "${RUN_ROOT}/turn3/result.json" \
    >"${RUN_ROOT}/oracle.json"

printf '[QWEN-CPU-ORACLE][PASS] turns=3 model_sha256=%s output=%s\n' \
    "${MODEL_SHA}" "${RUN_ROOT}/oracle.json"
