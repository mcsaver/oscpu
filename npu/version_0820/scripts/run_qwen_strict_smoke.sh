#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly TMP_ROOT="$(realpath -m -- "${PROJECT_ROOT}/tmp")"
readonly VECTOR_ROOT="${PROJECT_ROOT}/tests/vectors/qwen35_08b_q8_0"
readonly ORACLE="${VECTOR_ROOT}/strict-smoke-oracle.json"
readonly MULTITOKEN_VALIDATOR="${PROJECT_ROOT}/scripts/qwen_strict_multitoken.py"
readonly STRICT_LOG_VALIDATOR="${PROJECT_ROOT}/scripts/qwen_strict_log_validator.py"
readonly MODEL="${PROJECT_ROOT}/models/Qwen3.5-0.8B-Q8_0.gguf"
readonly EXPECTED_MODEL_SHA='37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f'
readonly EXPECTED_LLAMA_COMMIT='95c409c13625a23da2aa37270339ce9179215a18'
readonly MANIFEST_PROFILE='qwen35-0.8b-b1t1-unfused-nonflash-v5'
readonly EXPECTED_RAW_MANIFEST_SHA='a144ef45f25e8f7a754ddd16faea09422b175d443538bf884964b2ff3685f112'
readonly EXPECTED_MANIFEST_SHA='92d404d308cb9ca6a7741233ab05f8eb07be6659dc833fb99b7cd023958fe48e'
readonly EXPECTED_STEADY_RAW_MANIFEST_SHA='0338b4e64e3fb1d848ae2387cfbd8e7816d6e5b9cb4d5645759cbc3f0b5753f5'
readonly EXPECTED_STEADY_MANIFEST_SHA='9b0609f46b30267cfc43d1a7fb96eed0f654eb727d792f10d82b3b847578bf10'
readonly EXPECTED_MANIFEST_BUNDLE_SHA='433686dc48cd927ca930b80c8430beec459080cdfc813cd25d927c47e772695f'
declare -ar STEADY_REPEAT_DISPATCHES=(3 4 5 6 7 8)
declare -Ar EXPECTED_STEADY_REPEAT_RAW_SHA_BY_DISPATCH=(
    [3]='1131a4dedaf9430e545cea4516807cb0cac67c357b4c8340d4cf4b21ee877959'
    [4]='389e60d07ede153efadfc3724aaf8558275041003962c216fa6894bbb0e0929b'
    [5]='5bcfa951d47d0ee7c85b2519f9be82eea102b668cf4ec856f55ae804706fccf2'
    [6]='0b13c7cf1b333bcc3fb233a6e2cd1e129ef4ac34a9839853598a04c40e31b560'
    [7]='f5f55fc67d2454c7ddde86b13457500d4627961212dd01e6c31316bc39a6fb75'
    [8]='6e1493ae53b558bf0058dc5692ea906b50150bbe708f0f2b51fc0b463cb8d37b'
)
declare -Ar EXPECTED_STEADY_REPEAT_MANIFEST_SHA_BY_DISPATCH=(
    [3]='1309a6a176a5c1c5627dca7d28c5cf2578ff9c515d5ebc8ca60f1ff21ef766f2'
    [4]='1ce4f0735a8131a2198bbebdba8422bf4d86223f41a4b7d73b610bfc4c960259'
    [5]='1266d5f928f67e24244ede685acebdd500a54019a2804cd54b0e08aa476bec5e'
    [6]='59ccc88eeb7f258f189ced86dcc995bd85074cd021b152c44e5bdd7115c1edf8'
    [7]='1091cf6b1c48f11b360e86e804db6fc65c68dded747015753ff1e2f2f8cc0822'
    [8]='0d6a67f2dc30c9a759c3200cb267d3f0c3ab0d91863d68064031a7365b9bcce8'
)
# Every llama-completion subprocess starts by removing the full strict-mode
# environment surface.  A phase then opts back into exactly the variables it
# owns.  This makes a developer shell with exported LLAMA_NPU_* settings (or
# the upstream backend-sampling env alias) unable to silently change a run.
declare -ar HERMETIC_NPU_ENV_NAMES=(
    LLAMA_NPU_REQUIRED
    LLAMA_NPU_ADMISSION_ONLY
    LLAMA_NPU_GRAPH_COLLECT
    LLAMA_NPU_GRAPH_COLLECT_DISPATCH
    LLAMA_NPU_STRICT_SAMPLING
    LLAMA_NPU_GRAPH_PROFILE
    LLAMA_NPU_GRAPH_NUMERIC_PROFILE
    LLAMA_NPU_GRAPH_SOURCE_COMMIT
    LLAMA_NPU_GRAPH_MODEL_SHA256
    LLAMA_NPU_GRAPH_FUSED_OPS
    LLAMA_ARG_BACKEND_SAMPLING
)
declare -ar HERMETIC_NPU_ENV_UNSET_ARGS=(
    -u LLAMA_NPU_REQUIRED
    -u LLAMA_NPU_ADMISSION_ONLY
    -u LLAMA_NPU_GRAPH_COLLECT
    -u LLAMA_NPU_GRAPH_COLLECT_DISPATCH
    -u LLAMA_NPU_STRICT_SAMPLING
    -u LLAMA_NPU_GRAPH_PROFILE
    -u LLAMA_NPU_GRAPH_NUMERIC_PROFILE
    -u LLAMA_NPU_GRAPH_SOURCE_COMMIT
    -u LLAMA_NPU_GRAPH_MODEL_SHA256
    -u LLAMA_NPU_GRAPH_FUSED_OPS
    -u LLAMA_ARG_BACKEND_SAMPLING
)
readonly RUN_ID="qwen35-08b-q8_0-npu-strict-$(date -u +%Y%m%dT%H%M%S)-${BASHPID}"
readonly RUN_ROOT="$(realpath -m -- "${TMP_ROOT}/acceptance/${RUN_ID}")"
readonly BUILD_ROOT="$(realpath -m -- "${TMP_ROOT}/build/${RUN_ID}")"
readonly RUNTIME_TMP="$(realpath -m -- "${TMP_ROOT}/runtime-tmp/${RUN_ID}")"
readonly CACHE_ROOT="$(realpath -m -- "${TMP_ROOT}/cache/${RUN_ID}")"
readonly LLAMA_BUILD_ROOT="${BUILD_ROOT}/llama.cpp"
readonly BACKEND_BUILD_ROOT="${BUILD_ROOT}/npu-backend"
readonly DIRECT_VERILATED_ROOT="${BUILD_ROOT}/npu-backend-verilated"
readonly SYSTEM_VERILATED_ROOT="${BUILD_ROOT}/npu-backend-system-verilated"
readonly BACKEND_PRODUCT_LOG_ROOT="${RUN_ROOT}/backend-products"
readonly GRAPH_ROOT="${RUN_ROOT}/graph-manifest"
readonly RAW_MANIFEST="${GRAPH_ROOT}/dispatch.raw.jsonl"
readonly MANIFEST="${GRAPH_ROOT}/dispatch.manifest.json"
readonly MANIFEST_JSONL="${GRAPH_ROOT}/dispatch.manifest.jsonl"
readonly STEADY_RAW_MANIFEST="${GRAPH_ROOT}/steady.raw.jsonl"
readonly STEADY_MANIFEST="${GRAPH_ROOT}/steady.manifest.json"
readonly STEADY_MANIFEST_JSONL="${GRAPH_ROOT}/steady.manifest.jsonl"
readonly STEADY_REPEAT_ROOT="${GRAPH_ROOT}/steady-repeats"
readonly MANIFEST_BUNDLE="${GRAPH_ROOT}/dispatch.bundle.json"
readonly CLI="${LLAMA_BUILD_ROOT}/bin/llama-completion"
readonly ADMISSION_CLI="${LLAMA_BUILD_ROOT}/bin/llama-completion"
readonly BACKEND="${BACKEND_BUILD_ROOT}/libggml-npu.so"
readonly HOOK="${BUILD_ROOT}/libqwen-token-capture.so"

mode='scripted'
scripted_profile='extended-8'
scripted_tokens=8
case "${1:-}" in
    '') ;;
    --scripted) ;;
    --scripted-prefix-2)
        scripted_profile='prefix-2'
        scripted_tokens=2
        ;;
    --interactive) mode='interactive' ;;
    --admission-only) mode='admission-only' ;;
    -h|--help)
        printf 'usage: %s [--scripted|--scripted-prefix-2|--interactive|--admission-only]\n' "$0"
        exit 0
        ;;
    *)
        printf '[NPU-STRICT-SMOKE][FAIL] unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
esac
[[ "$#" -le 1 ]] || {
    printf '[NPU-STRICT-SMOKE][FAIL] too many arguments\n' >&2
    exit 2
}

fail() {
    printf '[NPU-STRICT-SMOKE][FAIL] %s\n' "$*" >&2
    exit 1
}

write_hermetic_env_prefix() {
    local output_path="${1:?command log path is required}"
    local env_name

    printf 'env' >"${output_path}"
    for env_name in "${HERMETIC_NPU_ENV_NAMES[@]}"; do
        printf ' -u %q' "${env_name}" >>"${output_path}"
    done
    printf ' ' >>"${output_path}"
}

extract_wall_seconds() {
    local wall_log="${1:?wall-time log is required}"

    # GNU time prepends a diagnostic when the measured command exits nonzero.
    # Admission-only intentionally exits 1 at the pre-allocation boundary, so
    # extract one named record instead of concatenating every line in the file.
    awk '
        /^elapsed_seconds=[0-9]+([.][0-9]+)?$/ {
            count += 1
            sub(/^elapsed_seconds=/, "")
            value = $0
        }
        END {
            if (count != 1 || value + 0 <= 0) {
                exit 1
            }
            print value
        }
    ' "${wall_log}"
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

for command_name in g++ jq nm python3 realpath sha256sum timeout /usr/bin/time; do
    command -v "${command_name}" >/dev/null 2>&1 \
        || fail "missing command: ${command_name}"
done

mkdir -p -- "${RUN_ROOT}" "${BUILD_ROOT}" "${RUNTIME_TMP}" "${CACHE_ROOT}"
export TMPDIR="${RUNTIME_TMP}"
export TMP="${RUNTIME_TMP}"
export TEMP="${RUNTIME_TMP}"
export XDG_CACHE_HOME="${CACHE_ROOT}"
export PYTHONPATH="${PROJECT_ROOT}/tools/cmake-python"
export PYTHONDONTWRITEBYTECODE=1

python3 "${PROJECT_ROOT}/scripts/verify_locked_inputs.py" \
    >"${RUN_ROOT}/locked-inputs.log" 2>&1 \
    || fail "locked source/model verification failed: ${RUN_ROOT}/locked-inputs.log"

LLAMA_BUILD_DIR="${LLAMA_BUILD_ROOT}" \
LLAMA_LOG_DIR="${RUN_ROOT}/llama-products" \
bash "${PROJECT_ROOT}/scripts/build_llama.sh" \
    >"${RUN_ROOT}/llama-build.log" 2>&1 \
    || fail "pinned llama-completion build failed: ${RUN_ROOT}/llama-build.log"
grep -Fq "build 10507, commit ${EXPECTED_LLAMA_COMMIT}" \
    "${RUN_ROOT}/llama-build.log" \
    || fail "pinned llama.cpp identity is missing from build log"

[[ -x "${CLI}" ]] || fail "llama-completion is not executable: ${CLI}"
[[ -x "${ADMISSION_CLI}" ]] \
    || fail "llama-completion is not executable: ${ADMISSION_CLI}"
[[ -f "${MODEL}" ]] || fail "Qwen model is missing: ${MODEL}"
[[ -f "${ORACLE}" ]] || fail "token oracle is missing: ${ORACLE}"
[[ -f "${MULTITOKEN_VALIDATOR}" ]] \
    || fail "multi-token validator is missing: ${MULTITOKEN_VALIDATOR}"
[[ -f "${STRICT_LOG_VALIDATOR}" ]] \
    || fail "strict log validator is missing: ${STRICT_LOG_VALIDATOR}"

readonly MODEL_SHA="$(sha256sum -- "${MODEL}" | awk '{ print $1 }')"
[[ "${MODEL_SHA}" == "${EXPECTED_MODEL_SHA}" ]] \
    || fail "model SHA-256 mismatch: ${MODEL_SHA}"
python3 -B "${MULTITOKEN_VALIDATOR}" oracle "${ORACLE}" \
    --model-sha256 "${MODEL_SHA}" \
    --llama-commit "${EXPECTED_LLAMA_COMMIT}" \
    >"${RUN_ROOT}/multitoken-oracle.log" 2>&1 \
    || fail "frozen token oracle identity/configuration mismatch"

# Freeze both graph phases before building the backend.  Dispatch 1 is the
# recurrent-cache bootstrap graph; dispatch 2 and all later tokens use one
# steady graph in which exactly 36 P17/P18 SCALE owners have zero cardinality.
# A target-8 collection independently proves that dispatches 3..8 do not drift.
mkdir -- "${GRAPH_ROOT}"
collect_timeout_seconds="${NPU_STRICT_COLLECT_TIMEOUT_SECONDS:-300}"
[[ "${collect_timeout_seconds}" =~ ^[1-9][0-9]*$ ]] \
    || fail "NPU_STRICT_COLLECT_TIMEOUT_SECONDS must be a positive integer"

collect_graph_phase() {
    local label="${1:?collection label is required}"
    local target_dispatch="${2:?target dispatch is required}"
    local n_predict="${3:?n_predict is required}"
    local raw_manifest="${4:?raw manifest is required}"
    local manifest="${5:?manifest is required}"
    local manifest_jsonl="${6:?manifest JSONL is required}"
    local expected_raw_sha="${7:?expected raw SHA is required}"
    local expected_manifest_sha="${8:?expected manifest SHA is required}"
    local collect_log="${GRAPH_ROOT}/${label}.collect.log"
    local collect_argv="${GRAPH_ROOT}/${label}.collect.argv"
    local collect_rc_log="${GRAPH_ROOT}/${label}.collect.rc"
    local validator_log="${GRAPH_ROOT}/${label}.validator.log"
    local collect_rc
    local raw_sha
    local -a target_env=()
    local -a collect_command=(
        "${ADMISSION_CLI}"
        -m "${MODEL}"
        -p x
        -n "${n_predict}"
        -c 256
        -b 1
        -ub 1
        -t 1
        -tb 1
        -fa off
        -fit off
        --seed 1
        --temp 0
        --top-k 1
        --backend-sampling
        --no-warmup
        --no-display-prompt
        --no-conversation
        --no-perf
        --reasoning off
    )

    if (( target_dispatch != 1 )); then
        target_env=("LLAMA_NPU_GRAPH_COLLECT_DISPATCH=${target_dispatch}")
    fi

    write_hermetic_env_prefix "${collect_argv}"
    printf '%s ' '-u GGML_BACKEND_PATH' >>"${collect_argv}"
    printf 'LLAMA_NPU_STRICT_SAMPLING=1 ' >>"${collect_argv}"
    printf 'LLAMA_NPU_GRAPH_COLLECT=%q LLAMA_NPU_GRAPH_PROFILE=%q ' \
        "${raw_manifest}" "${MANIFEST_PROFILE}" >>"${collect_argv}"
    if (( target_dispatch != 1 )); then
        printf 'LLAMA_NPU_GRAPH_COLLECT_DISPATCH=%q ' "${target_dispatch}" \
            >>"${collect_argv}"
    fi
    printf 'LLAMA_NPU_GRAPH_NUMERIC_PROFILE=%q LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q ' \
        'strict-f32-rne-canonical-nan-v1' "${EXPECTED_LLAMA_COMMIT}" \
        >>"${collect_argv}"
    printf 'LLAMA_NPU_GRAPH_MODEL_SHA256=%q LLAMA_NPU_GRAPH_FUSED_OPS=0' \
        "${MODEL_SHA}" >>"${collect_argv}"
    printf ' %q' "${collect_command[@]}" >>"${collect_argv}"
    printf ' </dev/null\n' >>"${collect_argv}"

    set +e
    env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" -u GGML_BACKEND_PATH \
        LLAMA_NPU_STRICT_SAMPLING=1 \
        LLAMA_NPU_GRAPH_COLLECT="${raw_manifest}" \
        LLAMA_NPU_GRAPH_PROFILE="${MANIFEST_PROFILE}" \
        LLAMA_NPU_GRAPH_NUMERIC_PROFILE='strict-f32-rne-canonical-nan-v1' \
        LLAMA_NPU_GRAPH_SOURCE_COMMIT="${EXPECTED_LLAMA_COMMIT}" \
        LLAMA_NPU_GRAPH_MODEL_SHA256="${MODEL_SHA}" \
        LLAMA_NPU_GRAPH_FUSED_OPS=0 \
        "${target_env[@]}" \
        timeout --signal=TERM --kill-after=5s "${collect_timeout_seconds}s" \
        "${collect_command[@]}" </dev/null >"${collect_log}" 2>&1
    collect_rc=$?
    set -e
    printf '%s\n' "${collect_rc}" >"${collect_rc_log}"
    [[ "${collect_rc}" -eq 1 ]] \
        || fail "${label} graph collector did not stop at its controlled boundary rc=${collect_rc}: ${collect_log}"
    [[ -s "${raw_manifest}" && ! -e "${raw_manifest}.tmp" ]] \
        || fail "complete fresh ${label} raw graph artifact is missing"

    python3 -B - "${collect_log}" "${raw_manifest}" "${target_dispatch}" <<'PY'
import pathlib
import re
import sys

log_path = pathlib.Path(sys.argv[1])
raw_path = pathlib.Path(sys.argv[2])
target = int(sys.argv[3])
lines = log_path.read_text(encoding="utf-8", errors="strict").splitlines()

def die(message: str) -> None:
    raise SystemExit(f"graph collect log validation failed: {message}")

sampler_suffix = (
    "[NPU-STRICT-SAMPLER][READY] mode=backend-greedy "
    "full_vocab_host_export=0 cpu_candidate_scan=0"
)
sampler = [line for line in lines if line.endswith(sampler_suffix)]
if len(sampler) != 1:
    die(f"strict sampler marker count is {len(sampler)}, expected 1")

pass_re = re.compile(
    r"^\[NPU-GRAPH-COLLECT\]\[PASS\] "
    r"phase=post-build-pre-scheduler nodes=1714 compute_started=0 "
    r"path=(\S+) dispatch=([0-9]+) target_dispatch=([0-9]+) "
    r"observed_dispatch=([0-9]+)$"
)
passes = [match for line in lines if (match := pass_re.fullmatch(line))]
if len(passes) != 1:
    die(f"PASS marker count is {len(passes)}, expected 1")
path, dispatch, target_field, observed = passes[0].groups()
if (pathlib.Path(path) != raw_path or
        (int(dispatch), int(target_field), int(observed)) != (target, target, target)):
    die(f"PASS marker target/path mismatch: {passes[0].group(0)}")

skip_re = re.compile(
    r"^\[NPU-GRAPH-COLLECT\]\[SKIP\] "
    r"phase=post-scheduler-compute dispatch=([0-9]+) "
    r"target_dispatch=([0-9]+) observed_dispatch=([0-9]+) "
    r"scheduler_allocated=1 compute_dispatched=1$"
)
skips = [match for line in lines if (match := skip_re.fullmatch(line))]
observed_skips = [
    (int(match.group(1)), int(match.group(2)), int(match.group(3)))
    for match in skips
]
expected_skips = [(dispatch, target, dispatch) for dispatch in range(1, target)]
if observed_skips != expected_skips:
    die(f"SKIP sequence mismatch: {observed_skips} != {expected_skips}")

for forbidden in (
    "[NPU-STRICT][READY]", "[NPU-STRICT][PASS]", "[NPU-STRICT][FAIL]",
    "[NPU-SYSTEM-LEDGER]", "[NPU-RAW32-PORTAL-LEDGER]",
    "[NPU-SAMPLER-ARGMAX-LEDGER]", "prompt eval time =", " eval time =",
):
    if any(forbidden in line for line in lines):
        die(f"required-execution/timing evidence appeared in collector: {forbidden}")
PY

    raw_sha="$(sha256sum -- "${raw_manifest}" | awk '{ print $1 }')"
    [[ "${raw_sha}" == "${expected_raw_sha}" ]] \
        || fail "${label} raw graph identity mismatch: ${raw_sha}"

    python3 -B "${PROJECT_ROOT}/scripts/qwen_graph_manifest.py" validate \
        "${raw_manifest}" \
        --json-out "${manifest}" \
        --jsonl-out "${manifest_jsonl}" \
        --expect-raw-sha256 "${expected_raw_sha}" \
        --expect-model-sha256 "${MODEL_SHA}" \
        --expect-source-commit "${EXPECTED_LLAMA_COMMIT}" \
        --expect-profile "${MANIFEST_PROFILE}" \
        --expect-numeric-profile strict-f32-rne-canonical-nan-v1 \
        --expect-graph-scope decoder-main \
        --expect-graph-type-name default \
        --expect-flash-attn false \
        --expect-fused-gdn-ar false \
        --expect-fused-gdn-ch false \
        --expect-fused-lid false \
        --expect-fused-dsv4-hc-pre false \
        --expect-fused-dsv4-hc-comb false \
        --expect-fused-dsv4-hc-post false \
        --expect-auto-fa false \
        --expect-auto-fgdn false \
        --expect-auto-flid false \
        --expect-auto-fhc false \
        --expect-n-batch 1 \
        --expect-n-ubatch 1 \
        --expect-n-rs-seq 0 \
        --expect-ubatch-tokens 1 \
        --expect-node-count 1714 \
        --expect-compute-count 960 \
        --expect-mover-count 120 \
        --expect-metadata-count 634 \
        --expect-target-dispatch "${target_dispatch}" \
        >"${validator_log}" 2>&1 \
        || fail "fresh ${label} graph manifest validation failed: ${validator_log}"
    grep -Fxq \
        "[NPU-GRAPH-MANIFEST][PASS] nodes=1714 compute=960 mover=120 metadata=634 raw_sha256=${expected_raw_sha} manifest_sha256=${expected_manifest_sha}" \
        "${validator_log}" \
        || fail "exact fresh ${label} graph manifest marker is missing"
    jq -e --arg sha "${expected_manifest_sha}" \
        '.manifest_sha256 == $sha' "${manifest}" >/dev/null \
        || fail "fresh ${label} canonical manifest identity mismatch"
}

collect_graph_phase bootstrap 1 1 \
    "${RAW_MANIFEST}" "${MANIFEST}" "${MANIFEST_JSONL}" \
    "${EXPECTED_RAW_MANIFEST_SHA}" "${EXPECTED_MANIFEST_SHA}"
collect_graph_phase steady 2 2 \
    "${STEADY_RAW_MANIFEST}" "${STEADY_MANIFEST}" "${STEADY_MANIFEST_JSONL}" \
    "${EXPECTED_STEADY_RAW_MANIFEST_SHA}" "${EXPECTED_STEADY_MANIFEST_SHA}"
mkdir -- "${STEADY_REPEAT_ROOT}"
declare -a manifest_bundle_repeat_args=()
declare -a steady_repeat_manifest_paths=()
for repeat_dispatch in "${STEADY_REPEAT_DISPATCHES[@]}"; do
    repeat_raw_manifest="${STEADY_REPEAT_ROOT}/dispatch-${repeat_dispatch}.raw.jsonl"
    repeat_manifest="${STEADY_REPEAT_ROOT}/dispatch-${repeat_dispatch}.manifest.json"
    repeat_manifest_jsonl="${STEADY_REPEAT_ROOT}/dispatch-${repeat_dispatch}.manifest.jsonl"
    collect_graph_phase "steady-repeat-${repeat_dispatch}" \
        "${repeat_dispatch}" "${repeat_dispatch}" \
        "${repeat_raw_manifest}" "${repeat_manifest}" \
        "${repeat_manifest_jsonl}" \
        "${EXPECTED_STEADY_REPEAT_RAW_SHA_BY_DISPATCH[${repeat_dispatch}]}" \
        "${EXPECTED_STEADY_REPEAT_MANIFEST_SHA_BY_DISPATCH[${repeat_dispatch}]}"
    manifest_bundle_repeat_args+=(--steady-repeat-manifest "${repeat_manifest}")
    steady_repeat_manifest_paths+=("${repeat_manifest}")
done

python3 -B "${PROJECT_ROOT}/scripts/qwen_graph_manifest.py" bundle \
    "${MANIFEST}" "${STEADY_MANIFEST}" \
    "${manifest_bundle_repeat_args[@]}" \
    --expect-bundle-sha256 "${EXPECTED_MANIFEST_BUNDLE_SHA}" \
    --json-out "${MANIFEST_BUNDLE}" \
    >"${GRAPH_ROOT}/bundle-validator.log" 2>&1 \
    || fail "bootstrap/steady graph bundle validation failed: ${GRAPH_ROOT}/bundle-validator.log"
[[ -s "${MANIFEST_BUNDLE}" ]] \
    || fail "validated bootstrap/steady graph bundle is missing"
grep -Fxq \
    "[NPU-GRAPH-MANIFEST-BUNDLE][PASS] nodes=1714 unchanged=1642 descriptor_deltas=72 zero_scale=36 p17=18 p18=18 steady_repeats=6 bundle_sha256=${EXPECTED_MANIFEST_BUNDLE_SHA}" \
    "${GRAPH_ROOT}/bundle-validator.log" \
    || fail 'exact six-repeat graph bundle PASS marker is missing'

steady_repeat_manifest_env="$(
    IFS=:
    printf '%s' "${steady_repeat_manifest_paths[*]}"
)"
NPU_MANIFEST="${MANIFEST}" \
NPU_STEADY_MANIFEST="${STEADY_MANIFEST}" \
NPU_STEADY_REPEAT_MANIFESTS="${steady_repeat_manifest_env}" \
python3 -B "${PROJECT_ROOT}/tests/test_qwen_graph_manifest.py" \
    >"${GRAPH_ROOT}/manifest-tests.log" 2>&1 \
    || fail "fresh graph manifest/bundle tests failed: ${GRAPH_ROOT}/manifest-tests.log"
grep -Eq '^Ran 39 tests in [0-9]+([.][0-9]+)?s$' \
    "${GRAPH_ROOT}/manifest-tests.log" \
    || fail 'graph manifest test count is not exactly 39'
grep -Fxq 'OK' "${GRAPH_ROOT}/manifest-tests.log" \
    || fail 'graph manifest tests did not finish without skip/expected-failure decoration'
if grep -Eq 'skipped=|expected failures=|unexpected successes=' \
        "${GRAPH_ROOT}/manifest-tests.log"; then
    fail 'graph manifest test suite skipped or softened a case'
fi

LLAMA_BUILD_DIR="${LLAMA_BUILD_ROOT}" \
NPU_BACKEND_BUILD_DIR="${BACKEND_BUILD_ROOT}" \
NPU_BACKEND_LOG_DIR="${BACKEND_PRODUCT_LOG_ROOT}" \
NPU_VERILATED_MDIR="${DIRECT_VERILATED_ROOT}" \
NPU_SYSTEM_VERILATED_MDIR="${SYSTEM_VERILATED_ROOT}" \
NPU_MANIFEST="${MANIFEST}" \
NPU_STEADY_MANIFEST="${STEADY_MANIFEST}" \
bash "${PROJECT_ROOT}/scripts/build_npu_backend.sh" \
    >"${RUN_ROOT}/backend-build.log" 2>&1 \
    || fail "production NPU backend build/tests failed: ${RUN_ROOT}/backend-build.log"

[[ -f "${BACKEND}" ]] || fail "NPU backend is missing: ${BACKEND}"

"${CLI}" --version >"${RUN_ROOT}/llama-version.log" 2>&1
grep -Fq "build 10507, commit ${EXPECTED_LLAMA_COMMIT}" \
    "${RUN_ROOT}/llama-version.log" \
    || fail "llama-completion identity mismatch"

g++ -std=c++17 -O3 -DNDEBUG -fPIC -shared \
    "${PROJECT_ROOT}/tools/qwen_token_capture.cpp" -ldl -o "${HOOK}"
nm -D --defined-only "${HOOK}" | c++filt \
    | grep -Fq 'common_sampler_accept(common_sampler*, int, bool)' \
    || fail "token capture interposer symbol is missing"
readonly HOOK_SHA="$(sha256sum -- "${HOOK}" | awk '{ print $1 }')"

# Parse markers by dispatch ID rather than by line adjacency: stdout and stderr
# may be block-buffered independently when the CLI is redirected.  This parser
# proves every successful strict graph has exactly one matching SystemTop and
# sampler-ARGMAX ledger, and every required node crossed the public completion
# edge.
validate_strict_log() {
    local run_log="${1:?run log is required}"
    local summary_json="${2:?summary path is required}"
    local expected_dispatches="${3:?expected dispatch count is required}"
    python3 -B "${STRICT_LOG_VALIDATOR}" \
        "${run_log}" "${summary_json}" "${expected_dispatches}"
}

project_phase_ledger() {
    local ledger_json="${1:?system ledger JSON is required}"
    local phase_json="${2:?phase ledger JSON is required}"

    # Close the phase projection back against every aggregate emitted by the
    # strict log validator.  This prevents the readable bootstrap/steady view
    # from becoming an independently maintained estimate.
    jq -e '
        .bootstrap_dispatches == 1 and
        .steady_dispatches == (.dispatches - 1) and
        .f32_alu_owner_transactions ==
            (367 * (.bootstrap_dispatches + .steady_dispatches)) and
        .f32_alu_zero_cardinality_transactions ==
            (36 * .steady_dispatches) and
        .f32_alu_nonempty_portal_commands ==
            (367 * .bootstrap_dispatches + 331 * .steady_dispatches) and
        .f32_alu_portal_raw_read_copy_bytes ==
            (211292672 * .bootstrap_dispatches +
             191091200 * .steady_dispatches) and
        .f32_alu_portal_raw_write_copy_bytes ==
            (115820800 * .bootstrap_dispatches +
             95619328 * .steady_dispatches) and
        .f32_alu_bootstrap_owner_transactions ==
            (367 * .bootstrap_dispatches) and
        .f32_alu_bootstrap_zero_cardinality_transactions == 0 and
        .f32_alu_bootstrap_nonempty_portal_commands ==
            (367 * .bootstrap_dispatches) and
        .f32_alu_bootstrap_portal_raw_read_copy_bytes ==
            (211292672 * .bootstrap_dispatches) and
        .f32_alu_bootstrap_portal_raw_write_copy_bytes ==
            (115820800 * .bootstrap_dispatches) and
        .f32_alu_steady_owner_transactions ==
            (367 * .steady_dispatches) and
        .f32_alu_steady_zero_cardinality_transactions ==
            (36 * .steady_dispatches) and
        .f32_alu_steady_nonempty_portal_commands ==
            (331 * .steady_dispatches) and
        .f32_alu_steady_portal_raw_read_copy_bytes ==
            (191091200 * .steady_dispatches) and
        .f32_alu_steady_portal_raw_write_copy_bytes ==
            (95619328 * .steady_dispatches) and
        .f32_alu_owner_transactions ==
            (.f32_alu_bootstrap_owner_transactions +
             .f32_alu_steady_owner_transactions) and
        .f32_alu_zero_cardinality_transactions ==
            (.f32_alu_bootstrap_zero_cardinality_transactions +
             .f32_alu_steady_zero_cardinality_transactions) and
        .f32_alu_nonempty_portal_commands ==
            (.f32_alu_bootstrap_nonempty_portal_commands +
             .f32_alu_steady_nonempty_portal_commands) and
        .f32_alu_portal_raw_read_copy_bytes ==
            (.f32_alu_bootstrap_portal_raw_read_copy_bytes +
             .f32_alu_steady_portal_raw_read_copy_bytes) and
        .f32_alu_portal_raw_write_copy_bytes ==
            (.f32_alu_bootstrap_portal_raw_write_copy_bytes +
             .f32_alu_steady_portal_raw_write_copy_bytes)
    ' "${ledger_json}" >/dev/null \
        || fail "bootstrap/steady phase projection does not close: ${ledger_json}"

    jq '
        . as $ledger |
        {
            schema: "qwen35-08b-q8_0-npu-strict-phase-ledger-v1",
            bootstrap: {
                dispatches: $ledger.bootstrap_dispatches,
                f32_alu_owner_transactions:
                    $ledger.f32_alu_bootstrap_owner_transactions,
                f32_alu_zero_cardinality_transactions:
                    $ledger.f32_alu_bootstrap_zero_cardinality_transactions,
                f32_alu_nonempty_portal_commands:
                    $ledger.f32_alu_bootstrap_nonempty_portal_commands,
                f32_alu_portal_raw_read_copy_bytes:
                    $ledger.f32_alu_bootstrap_portal_raw_read_copy_bytes,
                f32_alu_portal_raw_write_copy_bytes:
                    $ledger.f32_alu_bootstrap_portal_raw_write_copy_bytes
            },
            steady: {
                dispatches: $ledger.steady_dispatches,
                f32_alu_owner_transactions:
                    $ledger.f32_alu_steady_owner_transactions,
                f32_alu_zero_cardinality_transactions:
                    $ledger.f32_alu_steady_zero_cardinality_transactions,
                f32_alu_nonempty_portal_commands:
                    $ledger.f32_alu_steady_nonempty_portal_commands,
                f32_alu_portal_raw_read_copy_bytes:
                    $ledger.f32_alu_steady_portal_raw_read_copy_bytes,
                f32_alu_portal_raw_write_copy_bytes:
                    $ledger.f32_alu_steady_portal_raw_write_copy_bytes
            },
            total: {
                dispatches: $ledger.dispatches,
                f32_alu_owner_transactions:
                    $ledger.f32_alu_owner_transactions,
                f32_alu_zero_cardinality_transactions:
                    $ledger.f32_alu_zero_cardinality_transactions,
                f32_alu_nonempty_portal_commands:
                    $ledger.f32_alu_nonempty_portal_commands,
                f32_alu_portal_raw_read_copy_bytes:
                    $ledger.f32_alu_portal_raw_read_copy_bytes,
                f32_alu_portal_raw_write_copy_bytes:
                    $ledger.f32_alu_portal_raw_write_copy_bytes
            }
        }
    ' "${ledger_json}" >"${phase_json}"
}
# This mode proves only the real-model admission stage.  It deliberately
# rejects compute/ledger/timing markers so its PASS cannot be mistaken for the
# later dispatch, oracle, interactive-shell, or tokens/s acceptance stages.
validate_admission_only_log() {
    local run_log="${1:?run log is required}"
    local summary_json="${2:?summary path is required}"
    local expected_phase="${3:?expected graph phase is required}"
    python3 - "${run_log}" "${summary_json}" \
        "${MODEL_SHA}" "${EXPECTED_LLAMA_COMMIT}" "${MANIFEST_PROFILE}" \
        "${expected_phase}" "${PROJECT_ROOT}/scripts" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

log_path = pathlib.Path(sys.argv[1])
summary_path = pathlib.Path(sys.argv[2])
model_sha256, source_commit, profile, expected_phase = sys.argv[3:7]
sys.path.insert(0, str(pathlib.Path(sys.argv[7])))
from qwen_graph_manifest import QWEN_RECURRENT_LAYERS
lines = log_path.read_text(encoding="utf-8", errors="strict").splitlines()

if expected_phase not in {"bootstrap", "steady"}:
    raise SystemExit(f"invalid expected admission phase: {expected_phase}")

EXPECTED_NODES = 1714
EXPECTED_REQUIRED = 1080

def die(message: str) -> None:
    raise SystemExit(f"strict admission-only validation failed: {message}")

ready = [line for line in lines if line.startswith("[NPU-STRICT][READY]")]
if ready != [
    "[NPU-STRICT][READY] backend=NPU candidates=1 audit_abi=v2 "
    "canonical_binding_abi=v1"
]:
    die(f"READY marker count/content mismatch: {ready}")

sampler_ready = [
    line for line in lines if "[NPU-STRICT-SAMPLER][READY]" in line
]
sampler_ready_suffix = (
    "[NPU-STRICT-SAMPLER][READY] mode=backend-greedy "
    "full_vocab_host_export=0 cpu_candidate_scan=0"
)
if len(sampler_ready) != 1 or not sampler_ready[0].endswith(
        sampler_ready_suffix):
    die(f"strict sampler READY marker count/content mismatch: {sampler_ready}")

failure_prefixes = (
    "[NPU-STRICT][FAIL]",
    "[NPU-SYSTEM-LEDGER][FAIL]",
    "[NPU-FUNCTIONAL-COMMAND-LEDGER][FAIL]",
    "[NPU-RAW32-PORTAL-LEDGER][FAIL]",
    "[NPU-SAMPLER-ARGMAX-LEDGER][FAIL]",
)
failures = [line for line in lines if line.startswith(failure_prefixes)]
if failures:
    die(f"failure marker observed: {failures[:2]}")

admission_marker = (
    "[NPU-STRICT-ADMISSION-ONLY][PASS] graph=dispatch "
    "phase=post-binding-pre-scheduler compute_started=0 "
    "dispatch_graph_scheduler_allocated=0 compute_dispatched=0"
)
if [line for line in lines if line.startswith(
        "[NPU-STRICT-ADMISSION-ONLY]")] != [admission_marker]:
    die("exact admission-only PASS marker is missing or duplicated")

for forbidden in (
    "[NPU-STRICT][PASS]",
    "[NPU-SYSTEM-LEDGER]",
    "[NPU-FUNCTIONAL-COMMAND-LEDGER]",
    "[NPU-RAW32-PORTAL-LEDGER]",
    "[NPU-SAMPLER-ARGMAX-LEDGER]",
    "prompt eval time =",
    " eval time =",
):
    if any(forbidden in line for line in lines):
        die(f"post-admission compute evidence appeared: {forbidden}")

begin_re = re.compile(
    r"^\[NPU-STRICT\]\[PREFLIGHT-BEGIN\] graph=dispatch "
    r"cohort=([0-9]+) nodes=([0-9]+)$"
)
end_re = re.compile(
    r"^\[NPU-STRICT\]\[PREFLIGHT-END\] graph=dispatch "
    r"cohort=([0-9]+) nodes=([0-9]+) required_seen=([0-9]+) "
    r"supported=([0-9]+) unsupported=([0-9]+) canonical_errors=([0-9]+)$"
)
manifest_re = re.compile(
    r"^\[NPU-STRICT\]\[MANIFEST\] graph=dispatch cohort=([0-9]+) "
    r"node=([0-9]+) canonical_id=([0-9a-f]{64}).* supported=([01])$"
)
preflight_re = re.compile(
    r"^\[NPU-STRICT\]\[PREFLIGHT\] graph=dispatch binding=([0-9]+) "
    r"compute_started=0 required_seen=([0-9]+) assigned=([0-9]+) "
    r"unsupported=0$"
)

begins = [begin_re.fullmatch(line) for line in lines]
begins = [match for match in begins if match]
ends = [end_re.fullmatch(line) for line in lines]
ends = [match for match in ends if match]
preflights = [preflight_re.fullmatch(line) for line in lines]
preflights = [match for match in preflights if match]
if len(begins) != 1 or len(ends) != 1 or len(preflights) != 1:
    die(
        "dispatch admission cohort count mismatch: "
        f"begin={len(begins)} end={len(ends)} preflight={len(preflights)}"
    )

cohort = int(begins[0].group(1))
node_count = int(begins[0].group(2))
end_values = tuple(int(ends[0].group(index)) for index in range(1, 7))
if end_values != (
    cohort, EXPECTED_NODES, EXPECTED_REQUIRED, EXPECTED_REQUIRED, 0, 0
) or node_count != EXPECTED_NODES:
    die(f"1714-node/1080-required admission mismatch: {end_values}")

binding, required_seen, assigned = (
    int(preflights[0].group(index)) for index in range(1, 4)
)
if binding == 0 or required_seen != EXPECTED_REQUIRED or assigned != EXPECTED_REQUIRED:
    die(
        f"canonical binding/assignment mismatch: binding={binding} "
        f"required={required_seen} assigned={assigned}"
    )

manifest = []
manifest_descriptors = []
for line in lines:
    match = manifest_re.fullmatch(line)
    if match and int(match.group(1)) == cohort:
        manifest.append((
            int(match.group(2)), match.group(3), int(match.group(4))
        ))
        manifest_descriptors.append(line)
if len(manifest) != EXPECTED_REQUIRED:
    die(f"required manifest cardinality mismatch: {len(manifest)}")
node_indices = {node for node, _, _ in manifest}
canonical_ids = {canonical_id for _, canonical_id, _ in manifest}
if len(node_indices) != EXPECTED_REQUIRED:
    die("required graph-node indices are not unique")
if len(canonical_ids) != EXPECTED_REQUIRED:
    die("required canonical IDs are not unique")
if any(supported != 1 for _, _, supported in manifest):
    die("a required node is not supported by the NPU backend")

cache_scale_re = re.compile(
    r"^\[NPU-STRICT\]\[MANIFEST\] graph=dispatch cohort=[0-9]+ node=[0-9]+ "
    r"canonical_id=[0-9a-f]{64} name=cache_(?P<kind>[rs])_l(?P<layer>[0-9]+) "
    r"\(reshaped\) \(view\) \(view\) op=SCALE "
    r"dst_type=f32 dst_ne=(?P<dst_ne0>[0-9]+),1,1,1 "
    r"dst_nb=4,(?P<dst_nb1>[0-9]+),(?P<dst_nb2>[0-9]+),(?P<dst_nb3>[0-9]+) "
    r"src0_type=f32 src0_ne=(?P<src_ne0>[0-9]+),1,1,1 "
    r"src0_nb=4,(?P<src_nb1>[0-9]+),(?P<src_nb2>[0-9]+),(?P<src_nb3>[0-9]+) "
    r"supported=1$"
)
seen_cache = set()
for line in manifest_descriptors:
    match = cache_scale_re.fullmatch(line)
    if match is None:
        continue
    kind = match.group("kind")
    layer = int(match.group("layer"))
    full_ne0 = 18432 if kind == "r" else 262144
    full_nb = 73728 if kind == "r" else 1048576
    expected_ne0 = full_ne0 if expected_phase == "bootstrap" else 0
    expected_nb = full_nb if expected_phase == "bootstrap" else 0
    actual = tuple(int(match.group(field)) for field in (
        "dst_ne0", "src_ne0", "dst_nb1", "dst_nb2", "dst_nb3",
        "src_nb1", "src_nb2", "src_nb3",
    ))
    expected = (expected_ne0, expected_ne0) + (expected_nb,) * 6
    if actual != expected:
        die(f"{expected_phase} cache SCALE descriptor mismatch: {line}")
    seen_cache.add((kind, layer))
expected_cache = {
    (kind, layer)
    for kind in ("r", "s")
    for layer in QWEN_RECURRENT_LAYERS
}
if seen_cache != expected_cache:
    die(
        f"{expected_phase} cache SCALE census mismatch: "
        f"seen={len(seen_cache)} expected=36"
    )

canonical_set_sha256 = hashlib.sha256(
    ("\n".join(sorted(canonical_ids)) + "\n").encode("ascii")
).hexdigest()
summary = {
    "schema": "qwen35-08b-q8_0-npu-strict-admission-v1",
    "graph_phase": expected_phase,
    "model_sha256": model_sha256,
    "llama_commit": source_commit,
    "manifest_profile": profile,
    "graph_nodes": node_count,
    "required_seen": required_seen,
    "supported": EXPECTED_REQUIRED,
    "assigned": assigned,
    "unsupported": 0,
    "canonical_binding": binding,
    "canonical_set_sha256": canonical_set_sha256,
    "compute_started": 0,
    "dispatch_graph_scheduler_allocated": 0,
    "compute_dispatched": 0,
    "sampler_argmax_ledger_records": 0,
    "run_log": str(log_path),
}
summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(
    "[NPU-STRICT-ADMISSION-VALIDATOR][PASS] "
    f"nodes={node_count} required_seen={required_seen} "
    f"supported={EXPECTED_REQUIRED} assigned={assigned} unsupported=0 "
    f"binding={binding} canonical_set_sha256={canonical_set_sha256} "
    "compute_started=0 dispatch_graph_scheduler_allocated=0 "
    "compute_dispatched=0 sampler_argmax_ledger_records=0"
)
PY
}

token_file_to_json() {
    local token_file="${1:?token file is required}"
    local json_file="${2:?json file is required}"
    [[ -s "${token_file}" ]] || fail "token trace is empty: ${token_file}"
    if grep -Evq '^[0-9]+$' "${token_file}"; then
        fail "token trace contains a non-integer: ${token_file}"
    fi
    jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)' \
        "${token_file}" >"${json_file}"
}

extract_perf_metrics() {
    local run_log="${1:?run log is required}"
    local timing_trace="${2:?timing trace is required}"
    local prompt_count="${3:?prompt count is required}"
    local generated_count="${4:?generated count is required}"
    local output_json="${5:?metrics output is required}"
    python3 - "${run_log}" "${timing_trace}" \
        "${prompt_count}" "${generated_count}" "${output_json}" <<'PY'
import json
import math
import pathlib
import re
import sys

run_path = pathlib.Path(sys.argv[1])
timing_path = pathlib.Path(sys.argv[2])
prompt_count = int(sys.argv[3])
generated_count = int(sys.argv[4])
output_path = pathlib.Path(sys.argv[5])

def die(message: str) -> None:
    raise SystemExit(f"strict performance validation failed: {message}")

text = run_path.read_text(encoding="utf-8", errors="strict")
number = r"[0-9]+(?:\.[0-9]+)?"
rate = rf"(?:{number}|inf)"
prompt_re = re.compile(
    rf"prompt eval time\s*=\s*(?P<ms>{number})"
    rf"\s*ms\s*/\s*(?P<tokens>[0-9]+) tokens\s*\(\s*"
    rf"(?P<ms_per_token>{number})\s*ms per token,\s*"
    rf"(?P<tps>{rate})\s*tokens per second\s*\)"
)
generation_re = re.compile(
    rf"(?<!prompt )eval time\s*=\s*(?P<ms>{number})"
    rf"\s*ms\s*/\s*(?P<runs>[0-9]+) runs\s*\(\s*"
    rf"(?P<ms_per_token>{number})\s*ms per token,\s*"
    rf"(?P<tps>{rate})\s*tokens per second\s*\)"
)
prompt_matches = list(prompt_re.finditer(text))
generation_matches = list(generation_re.finditer(text))
if len(prompt_matches) != 1 or len(generation_matches) != 1:
    die(
        f"expected one prompt/eval timing record, got "
        f"prompt={len(prompt_matches)} generation={len(generation_matches)}"
    )

prompt_match = prompt_matches[0]
generation_match = generation_matches[0]
prompt_ms = float(prompt_match.group("ms"))
prompt_eval_tokens = int(prompt_match.group("tokens"))
prompt_cli_tps_text = prompt_match.group("tps")
prompt_cli_tps = (
    None if prompt_cli_tps_text == "inf" else float(prompt_cli_tps_text)
)
generation_ms = float(generation_match.group("ms"))
generation_runs = int(generation_match.group("runs"))
generation_cli_tps_text = generation_match.group("tps")
generation_cli_tps = (
    None if generation_cli_tps_text == "inf" else float(generation_cli_tps_text)
)
if prompt_count <= 0 or prompt_ms < 0 or prompt_eval_tokens != prompt_count:
    die("prompt timing fields are invalid")
expected_generation_runs = (
    generated_count if prompt_count == 1 else max(1, generated_count - 1)
)
if generation_ms < 0 or generation_runs != expected_generation_runs:
    die(
        f"generation eval runs {generation_runs} differ from expected "
        f"{expected_generation_runs} for prompt={prompt_count} "
        f"generated={generated_count}"
    )

if not timing_path.is_file():
    die("timing trace is missing")
events = []
for line in timing_path.read_text(encoding="ascii", errors="strict").splitlines():
    match = re.fullmatch(r"(prompt_start_ns|generated_ns)=([0-9]+)", line)
    if match is None:
        die(f"malformed timing event: {line!r}")
    events.append((match.group(1), int(match.group(2))))
prompt_starts = [value for kind, value in events if kind == "prompt_start_ns"]
generated = [value for kind, value in events if kind == "generated_ns"]
if len(prompt_starts) != 1:
    die(f"prompt-start event count is {len(prompt_starts)}, expected 1")
if len(generated) != generated_count:
    die(
        f"generated timing event count {len(generated)} differs from "
        f"token trace count {generated_count}"
    )
if generated_count <= 0 or generated[0] <= prompt_starts[0]:
    die("time-to-first-token interval is not positive")
if any(rhs <= lhs for lhs, rhs in zip(generated, generated[1:])):
    die("generated token timestamps are not strictly increasing")

ttft_seconds = (generated[0] - prompt_starts[0]) / 1_000_000_000.0
generation_seconds = generation_ms / 1000.0
if generation_seconds > 0:
    generation_tps = generation_runs / generation_seconds
    generation_throughput_basis = "eval-runs-per-printed-eval-seconds"
else:
    # With a multi-token prompt and n_predict=1, pinned llama-completion emits
    # one bookkeeping eval run at 0 ms because no generated token is fed back
    # into another decode.  Retain a finite observable rate without pretending
    # that the zero-duration CLI field is a measured decode interval.
    if prompt_count <= 1 or generated_count != 1 or generation_cli_tps is not None:
        die("zero generation eval time occurred outside frozen raw semantics")
    generation_seconds = ttft_seconds
    generation_tps = generation_runs / generation_seconds
    generation_throughput_basis = "prompt-start-to-first-generated-no-followup-eval"

# In pinned llama-completion raw mode, the first full forward dispatch is
# accounted under "eval time" while "prompt eval time" is printed as 0 ms and
# its rate as inf. The prompt-start to first-token interval is the unrounded
# prompt-throughput denominator for both scripted multi-token profiles.
if prompt_ms == 0:
    if (prompt_eval_tokens != 1 or generated_count <= 0 or
            generation_runs != generated_count or prompt_cli_tps is not None):
        die("zero prompt-eval time occurred outside frozen raw semantics")
    prompt_throughput_seconds = ttft_seconds
    prompt_throughput_basis = "raw-prompt-start-to-first-generated"
else:
    prompt_throughput_seconds = prompt_ms / 1000.0
    prompt_throughput_basis = "llama-prompt-eval"
prompt_tps = prompt_eval_tokens / prompt_throughput_seconds
if (not math.isfinite(prompt_tps) or prompt_tps <= 0 or
        not math.isfinite(generation_tps) or generation_tps <= 0):
    die("calculated prompt/generation throughput is not finite-positive")

result = {
    "prompt_eval_tokens": prompt_eval_tokens,
    "prompt_eval_seconds": prompt_ms / 1000.0,
    "prompt_throughput_seconds": prompt_throughput_seconds,
    "prompt_throughput_basis": prompt_throughput_basis,
    "prompt_tokens_per_second": prompt_tps,
    "prompt_cli_tokens_per_second": prompt_cli_tps,
    "generation_eval_runs": generation_runs,
    "generation_eval_seconds": generation_seconds,
    "generation_tokens_per_second": generation_tps,
    "generation_cli_tokens_per_second": generation_cli_tps,
    "generation_throughput_basis": generation_throughput_basis,
    "time_to_first_token_seconds": ttft_seconds,
    "generated_timestamp_count": len(generated),
}
output_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(
    "[NPU-STRICT-PERF][PASS] "
    f"prompt_eval_tokens={prompt_eval_tokens} prompt_tps={prompt_tps:.6f} "
    f"generation_eval_runs={generation_runs} generation_tps={generation_tps:.6f} "
    f"ttft_s={ttft_seconds:.6f} generated_timestamps={len(generated)}"
)
PY
}

base_cli_flags=(
    -m "${MODEL}"
    -c 256
    -b 1
    -ub 1
    -t 1
    -tb 1
    -fa off
    -fit off
    --seed 1
    --temp 0
    --top-k 1
    --no-warmup
    --no-display-prompt
    --perf
    --no-conversation
    --reasoning off
    --simple-io
)
strict_cli_flags=("${base_cli_flags[@]}" --backend-sampling)

verify_cpu_reference() {
    local cpu_root="${RUN_ROOT}/cpu-reference-8"
    local prompt_ids="${cpu_root}/prompt.ids"
    local generated_ids="${cpu_root}/generated.ids"
    local run_log="${cpu_root}/run.log"
    local wall_log="${cpu_root}/wall-seconds.txt"
    local command_log="${cpu_root}/command.argv"
    local validator_log="${cpu_root}/validator.log"
    local run_rc
    local -a command_line=(
        "${CLI}"
        "${base_cli_flags[@]}"
        -p x
        -n 8
    )

    mkdir -- "${cpu_root}"
    write_hermetic_env_prefix "${command_log}"
    printf '%s ' '-u GGML_BACKEND_PATH' >>"${command_log}"
    printf 'LD_PRELOAD=%q QWEN_PROMPT_TOKEN_TRACE_PATH=%q QWEN_TOKEN_TRACE_PATH=%q' \
        "${HOOK}" "${prompt_ids}" "${generated_ids}" >>"${command_log}"
    printf ' %q' "${command_line[@]}" >>"${command_log}"
    printf ' </dev/null\n' >>"${command_log}"

    set +e
    /usr/bin/time -f 'elapsed_seconds=%e' -o "${wall_log}" \
        env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" \
            -u GGML_BACKEND_PATH \
            LD_PRELOAD="${HOOK}" \
            QWEN_PROMPT_TOKEN_TRACE_PATH="${prompt_ids}" \
            QWEN_TOKEN_TRACE_PATH="${generated_ids}" \
            timeout --signal=TERM --kill-after=2s 180s \
            "${command_line[@]}" </dev/null >"${run_log}" 2>&1
    run_rc=$?
    set -e
    [[ "${run_rc}" -eq 0 ]] \
        || fail "8-token CPU reference failed rc=${run_rc}: ${run_log}"
    if grep -Eq '\[NPU-(STRICT|BACKEND|GRAPH-COLLECT)' "${run_log}"; then
        fail "8-token CPU reference unexpectedly entered an NPU path"
    fi
    python3 -B "${MULTITOKEN_VALIDATOR}" tokens "${ORACLE}" \
        --model-sha256 "${MODEL_SHA}" \
        --llama-commit "${EXPECTED_LLAMA_COMMIT}" \
        --max-tokens 8 \
        --prompt-ids "${prompt_ids}" \
        --generated-ids "${generated_ids}" \
        >"${validator_log}" 2>&1 \
        || fail "fresh 8-token CPU reference differs from frozen oracle: ${validator_log}"
    printf '[NPU-STRICT-CPU-ORACLE][PASS] prompt_tokens=1 generated_tokens=8 prompt_ids=[87] generated_ids=[283,220,16,15,198,88,283,220] elapsed_s=%s output=%s\n' \
        "$(extract_wall_seconds "${wall_log}")" "${validator_log}"
}

run_scripted_turn() {
    local turn_id="${1:?turn id is required}"
    local max_tokens="${2:?max tokens is required}"
    local prompt="${VECTOR_ROOT}/${turn_id}.txt"
    local turn_root="${RUN_ROOT}/${turn_id}"
    local prompt_ids="${turn_root}/prompt.ids"
    local generated_ids="${turn_root}/generated.ids"
    local prompt_json="${turn_root}/prompt.ids.json"
    local generated_json="${turn_root}/generated.ids.json"
    local timing_trace="${turn_root}/timing.trace"
    local perf_json="${turn_root}/performance.json"
    local run_log="${turn_root}/run.log"
    local wall_log="${turn_root}/wall-seconds.txt"
    local command_log="${turn_root}/command.argv"
    local ledger_json="${turn_root}/system-ledger.json"
    local phase_ledger_json="${turn_root}/phase-ledger.json"
    local validator_log="${turn_root}/multitoken-validator.log"
    local result_json="${turn_root}/result.json"
    local timeout_seconds="${NPU_STRICT_TURN_TIMEOUT_SECONDS:-86400}"
    local prompt_text
    local run_rc
    local wall_seconds
    local prompt_count
    local generated_count
    local expected_dispatches
    local tokens_per_second
    local -a command_line=()

    [[ -f "${prompt}" ]] || fail "missing prompt: ${prompt}"
    prompt_text="$(<"${prompt}")"
    [[ -n "${prompt_text}" ]] || fail "empty prompt: ${prompt}"
    [[ "${prompt_text}" != *$'\n'* ]] \
        || fail "strict smoke prompt must be exactly one raw input line: ${prompt}"
    jq -e \
        --arg turn "${turn_id}" \
        --arg prompt_text "${prompt_text}" \
        --argjson max_tokens "${max_tokens}" \
        '(.turns[] | select(.turn == $turn)) as $expected |
         $expected.prompt_text == $prompt_text and
         ($max_tokens == 2 or $max_tokens == $expected.max_tokens) and
         $expected.max_tokens == 8' \
        "${ORACLE}" >/dev/null \
        || fail "${turn_id} prompt text/generation limit differ from frozen oracle"
    [[ "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]] \
        || fail "NPU_STRICT_TURN_TIMEOUT_SECONDS must be a positive integer"
    command_line=(
        "${CLI}"
        "${strict_cli_flags[@]}"
        -p "${prompt_text}"
        -n "${max_tokens}"
    )
    mkdir -- "${turn_root}"

    write_hermetic_env_prefix "${command_log}"
    printf 'LD_PRELOAD=%q QWEN_PROMPT_TOKEN_TRACE_PATH=%q QWEN_TOKEN_TRACE_PATH=%q QWEN_TIMING_TRACE_PATH=%q ' \
        "${HOOK}" "${prompt_ids}" "${generated_ids}" "${timing_trace}" \
        >>"${command_log}"
    printf 'LLAMA_NPU_REQUIRED=1 LLAMA_NPU_GRAPH_PROFILE=%q ' \
        "${MANIFEST_PROFILE}" >>"${command_log}"
    printf 'LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q LLAMA_NPU_GRAPH_FUSED_OPS=0 ' \
        "${EXPECTED_LLAMA_COMMIT}" >>"${command_log}"
    printf 'GGML_BACKEND_PATH=%q' "${BACKEND}" >>"${command_log}"
    printf ' %q' "${command_line[@]}" >>"${command_log}"
    printf ' </dev/null\n' >>"${command_log}"

    set +e
    /usr/bin/time -f 'elapsed_seconds=%e' -o "${wall_log}" \
        env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" \
            LD_PRELOAD="${HOOK}" \
            QWEN_PROMPT_TOKEN_TRACE_PATH="${prompt_ids}" \
            QWEN_TOKEN_TRACE_PATH="${generated_ids}" \
            QWEN_TIMING_TRACE_PATH="${timing_trace}" \
            LLAMA_NPU_REQUIRED=1 \
            LLAMA_NPU_GRAPH_PROFILE="${MANIFEST_PROFILE}" \
            LLAMA_NPU_GRAPH_SOURCE_COMMIT="${EXPECTED_LLAMA_COMMIT}" \
            LLAMA_NPU_GRAPH_FUSED_OPS=0 \
            GGML_BACKEND_PATH="${BACKEND}" \
            timeout --signal=TERM --kill-after=5s "${timeout_seconds}s" \
            "${command_line[@]}" </dev/null >"${run_log}" 2>&1
    run_rc=$?
    set -e
    [[ "${run_rc}" -eq 0 ]] \
        || fail "${turn_id} strict NPU run failed rc=${run_rc}: ${run_log}"

    token_file_to_json "${prompt_ids}" "${prompt_json}"
    token_file_to_json "${generated_ids}" "${generated_json}"
    prompt_count="$(jq 'length' "${prompt_json}")"
    generated_count="$(jq 'length' "${generated_json}")"
    expected_dispatches="$((prompt_count + generated_count - 1))"
    validate_strict_log "${run_log}" "${ledger_json}" "${expected_dispatches}" \
        || fail "${turn_id} strict/System/sampler ledger validation failed"
    project_phase_ledger "${ledger_json}" "${phase_ledger_json}"
    python3 -B "${MULTITOKEN_VALIDATOR}" result "${ORACLE}" \
        --model-sha256 "${MODEL_SHA}" \
        --llama-commit "${EXPECTED_LLAMA_COMMIT}" \
        --max-tokens "${max_tokens}" \
        --prompt-ids "${prompt_ids}" \
        --generated-ids "${generated_ids}" \
        --ledger "${ledger_json}" \
        >"${validator_log}" 2>&1 \
        || fail "${turn_id} multi-token token/dispatch/ledger contract failed: ${validator_log}"

    jq -e \
        --arg turn "${turn_id}" \
        --argjson max_tokens "${max_tokens}" \
        --slurpfile actual_prompt "${prompt_json}" \
        --slurpfile actual_generated "${generated_json}" \
        '(.turns[] | select(.turn == $turn)) as $expected |
         $expected.prompt_token_ids == $actual_prompt[0] and
         $expected.generated_token_ids[0:$max_tokens] == $actual_generated[0]' \
        "${ORACLE}" >/dev/null \
        || fail "${turn_id} prompt/generated token IDs differ from CPU oracle"

    extract_perf_metrics "${run_log}" "${timing_trace}" \
        "${prompt_count}" "${generated_count}" "${perf_json}" \
        || fail "${turn_id} prompt/generation/TTFT metrics validation failed"
    wall_seconds="$(extract_wall_seconds "${wall_log}")" \
        || fail "${turn_id} wall-time record is missing, duplicated, or nonpositive: ${wall_log}"
    jq -e --arg turn "${turn_id}" \
        --argjson prompt_count "${prompt_count}" \
        --argjson generated_count "${generated_count}" \
        --argjson max_tokens "${max_tokens}" \
        '(.turns[] | select(.turn == $turn)) as $expected |
         $expected.prompt_tokens == $prompt_count and
         $generated_count == $max_tokens' \
        "${ORACLE}" >/dev/null \
        || fail "${turn_id} token counts differ from oracle"
    awk -v value="${wall_seconds}" 'BEGIN { exit !(value + 0 > 0) }' \
        || fail "${turn_id} wall time is not positive: ${wall_seconds}"
    tokens_per_second="$(awk \
        -v tokens="${generated_count}" -v seconds="${wall_seconds}" \
        'BEGIN { if (seconds + 0 <= 0) exit 1; printf "%.6f", tokens / seconds }')" \
        || fail "${turn_id} tokens/s calculation failed"
    awk -v value="${tokens_per_second}" \
        'BEGIN { exit !(value + 0 > 0) }' \
        || fail "${turn_id} tokens/s is not positive: ${tokens_per_second}"

    jq -n \
        --arg turn "${turn_id}" \
        --arg profile "${scripted_profile}" \
        --arg prompt_text "${prompt_text}" \
        --arg prompt_file "${prompt}" \
        --arg run_log "${run_log}" \
        --arg command_log "${command_log}" \
        --argjson prompt_tokens "${prompt_count}" \
        --argjson max_generated_tokens "${max_tokens}" \
        --argjson generated_tokens "${generated_count}" \
        --argjson expected_dispatches "${expected_dispatches}" \
        --argjson elapsed_wall_seconds "${wall_seconds}" \
        --argjson tokens_per_second "${tokens_per_second}" \
        --slurpfile prompt_token_ids "${prompt_json}" \
        --slurpfile generated_token_ids "${generated_json}" \
        --slurpfile performance "${perf_json}" \
        --slurpfile system_ledger "${ledger_json}" \
        --slurpfile ledger_phases "${phase_ledger_json}" \
        '{
            turn: $turn,
            profile: $profile,
            prompt_text: $prompt_text,
            prompt_file: $prompt_file,
            prompt_tokens: $prompt_tokens,
            max_generated_tokens: $max_generated_tokens,
            generated_tokens: $generated_tokens,
            expected_dispatches: $expected_dispatches,
            prompt_token_ids: $prompt_token_ids[0],
            generated_token_ids: $generated_token_ids[0],
            elapsed_wall_seconds: $elapsed_wall_seconds,
            tokens_per_second: $tokens_per_second,
            performance: $performance[0],
            system_ledger: $system_ledger[0],
            ledger_phases: $ledger_phases[0],
            run_log: $run_log,
            command_log: $command_log
        }' >"${result_json}"

    printf '[NPU-STRICT-SCRIPTED][TURN-PASS] turn=%s prompt_tokens=%s generated_tokens=%s elapsed_s=%s tokens_per_second=%s prompt_tps=%s generation_tps=%s ttft_s=%s prompt_ids=%s generated_ids=%s\n' \
        "${turn_id}" "${prompt_count}" "${generated_count}" \
        "${wall_seconds}" "${tokens_per_second}" \
        "$(jq -r .prompt_tokens_per_second "${perf_json}")" \
        "$(jq -r .generation_tokens_per_second "${perf_json}")" \
        "$(jq -r .time_to_first_token_seconds "${perf_json}")" \
        "$(jq -c . "${prompt_json}")" \
        "$(jq -c . "${generated_json}")"
}

run_interactive() {
    local interactive_root="${RUN_ROOT}/interactive"
    local prompt_text_file="${interactive_root}/prompt.txt"
    local prompt_ids="${interactive_root}/prompt.ids"
    local generated_ids="${interactive_root}/generated.ids"
    local prompt_json="${interactive_root}/prompt.ids.json"
    local generated_json="${interactive_root}/generated.ids.json"
    local timing_trace="${interactive_root}/timing.trace"
    local perf_json="${interactive_root}/performance.json"
    local run_log="${interactive_root}/run.log"
    local wall_log="${interactive_root}/wall-seconds.txt"
    local command_log="${interactive_root}/command.argv"
    local ledger_json="${interactive_root}/system-ledger.json"
    local phase_ledger_json="${interactive_root}/phase-ledger.json"
    local result_json="${interactive_root}/result.json"
    local max_tokens="${NPU_STRICT_INTERACTIVE_MAX_TOKENS:-2}"
    local timeout_seconds="${NPU_STRICT_INTERACTIVE_TIMEOUT_SECONDS:-86400}"
    local interactive_prompt
    local run_rc
    local wall_seconds
    local prompt_count
    local generated_count
    local expected_dispatches
    local tokens_per_second
    local -a timeout_prefix=()
    local -a command_line=()

    [[ -t 0 && -t 1 ]] \
        || fail '--interactive requires an attached terminal'
    [[ "${max_tokens}" =~ ^[1-9][0-9]*$ ]] \
        || fail "NPU_STRICT_INTERACTIVE_MAX_TOKENS must be positive"
    [[ "${timeout_seconds}" =~ ^[0-9]+$ ]] \
        || fail "NPU_STRICT_INTERACTIVE_TIMEOUT_SECONDS must be nonnegative"
    if (( timeout_seconds > 0 )); then
        timeout_prefix=(timeout --signal=TERM --kill-after=5s "${timeout_seconds}s")
    fi
    mkdir -- "${interactive_root}"

    printf '[NPU-STRICT-INTERACTIVE][READY] prompt_mode=raw-shell max_tokens=%s timeout_s=%s hint=each-generated-token-runs-one-b1t1-rtl-dispatch\n' \
        "${max_tokens}" "${timeout_seconds}"
    printf 'npu> '
    IFS= read -r interactive_prompt \
        || fail 'interactive shell reached EOF before a prompt was entered'
    [[ -n "${interactive_prompt}" ]] \
        || fail 'interactive shell prompt must not be empty'
    printf '%s\n' "${interactive_prompt}" >"${prompt_text_file}"
    command_line=(
        "${CLI}"
        "${strict_cli_flags[@]}"
        -p "${interactive_prompt}"
        -n "${max_tokens}"
    )

    write_hermetic_env_prefix "${command_log}"
    printf 'LD_PRELOAD=%q QWEN_PROMPT_TOKEN_TRACE_PATH=%q QWEN_TOKEN_TRACE_PATH=%q QWEN_TIMING_TRACE_PATH=%q ' \
        "${HOOK}" "${prompt_ids}" "${generated_ids}" "${timing_trace}" \
        >>"${command_log}"
    printf 'LLAMA_NPU_REQUIRED=1 LLAMA_NPU_GRAPH_PROFILE=%q ' \
        "${MANIFEST_PROFILE}" >>"${command_log}"
    printf 'LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q LLAMA_NPU_GRAPH_FUSED_OPS=0 ' \
        "${EXPECTED_LLAMA_COMMIT}" >>"${command_log}"
    printf 'GGML_BACKEND_PATH=%q' "${BACKEND}" >>"${command_log}"
    printf ' %q' "${timeout_prefix[@]}" "${command_line[@]}" >>"${command_log}"
    printf ' </dev/null\n' >>"${command_log}"

    set +e
    /usr/bin/time -f 'elapsed_seconds=%e' -o "${wall_log}" \
        env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" \
            LD_PRELOAD="${HOOK}" \
            QWEN_PROMPT_TOKEN_TRACE_PATH="${prompt_ids}" \
            QWEN_TOKEN_TRACE_PATH="${generated_ids}" \
            QWEN_TIMING_TRACE_PATH="${timing_trace}" \
            LLAMA_NPU_REQUIRED=1 \
            LLAMA_NPU_GRAPH_PROFILE="${MANIFEST_PROFILE}" \
            LLAMA_NPU_GRAPH_SOURCE_COMMIT="${EXPECTED_LLAMA_COMMIT}" \
            LLAMA_NPU_GRAPH_FUSED_OPS=0 \
            GGML_BACKEND_PATH="${BACKEND}" \
            "${timeout_prefix[@]}" "${command_line[@]}" \
            </dev/null 2>&1 | tee "${run_log}"
    run_rc=${PIPESTATUS[0]}
    set -e
    [[ "${run_rc}" -eq 0 ]] \
        || fail "interactive strict NPU run failed rc=${run_rc}: ${run_log}"

    token_file_to_json "${prompt_ids}" "${prompt_json}"
    token_file_to_json "${generated_ids}" "${generated_json}"
    prompt_count="$(jq 'length' "${prompt_json}")"
    generated_count="$(jq 'length' "${generated_json}")"
    expected_dispatches="$((prompt_count + generated_count - 1))"
    validate_strict_log "${run_log}" "${ledger_json}" "${expected_dispatches}" \
        || fail "interactive strict/System/sampler ledger validation failed"
    project_phase_ledger "${ledger_json}" "${phase_ledger_json}"
    extract_perf_metrics "${run_log}" "${timing_trace}" \
        "${prompt_count}" "${generated_count}" "${perf_json}" \
        || fail "interactive prompt/generation/TTFT metrics validation failed"
    wall_seconds="$(extract_wall_seconds "${wall_log}")" \
        || fail "interactive wall-time record is missing, duplicated, or nonpositive: ${wall_log}"
    awk -v value="${wall_seconds}" 'BEGIN { exit !(value + 0 > 0) }' \
        || fail "interactive wall time is not positive: ${wall_seconds}"
    tokens_per_second="$(awk \
        -v tokens="${generated_count}" -v seconds="${wall_seconds}" \
        'BEGIN { if (seconds + 0 <= 0) exit 1; printf "%.6f", tokens / seconds }')" \
        || fail "interactive tokens/s calculation failed"
    awk -v value="${tokens_per_second}" \
        'BEGIN { exit !(value + 0 > 0) }' \
        || fail "interactive tokens/s is not positive: ${tokens_per_second}"

    jq -n \
        --arg mode 'raw-shell' \
        --arg prompt_text "${interactive_prompt}" \
        --arg prompt_file "${prompt_text_file}" \
        --arg run_log "${run_log}" \
        --arg command_log "${command_log}" \
        --argjson prompt_tokens "${prompt_count}" \
        --argjson max_generated_tokens "${max_tokens}" \
        --argjson generated_tokens "${generated_count}" \
        --argjson expected_dispatches "${expected_dispatches}" \
        --argjson elapsed_wall_seconds "${wall_seconds}" \
        --argjson tokens_per_second "${tokens_per_second}" \
        --slurpfile prompt_token_ids "${prompt_json}" \
        --slurpfile generated_token_ids "${generated_json}" \
        --slurpfile performance "${perf_json}" \
        --slurpfile system_ledger "${ledger_json}" \
        --slurpfile ledger_phases "${phase_ledger_json}" \
        '{
            prompt_mode: $mode,
            prompt_text: $prompt_text,
            prompt_file: $prompt_file,
            prompt_tokens: $prompt_tokens,
            max_generated_tokens: $max_generated_tokens,
            generated_tokens: $generated_tokens,
            expected_dispatches: $expected_dispatches,
            prompt_token_ids: $prompt_token_ids[0],
            generated_token_ids: $generated_token_ids[0],
            elapsed_wall_seconds: $elapsed_wall_seconds,
            tokens_per_second: $tokens_per_second,
            performance: $performance[0],
            system_ledger: $system_ledger[0],
            ledger_phases: $ledger_phases[0],
            run_log: $run_log,
            command_log: $command_log
        }' >"${result_json}"

    printf '[NPU-STRICT-INTERACTIVE][TOKENS] prompt_ids=%s generated_ids=%s\n' \
        "$(jq -c . "${prompt_json}")" "$(jq -c . "${generated_json}")"
    printf '[NPU-STRICT-INTERACTIVE][PASS] prompt_mode=raw-shell prompt_tokens=%s generated_tokens=%s elapsed_s=%s tokens_per_second=%s prompt_tps=%s generation_tps=%s ttft_s=%s ledger=%s result=%s\n' \
        "${prompt_count}" "${generated_count}" "${wall_seconds}" \
        "${tokens_per_second}" \
        "$(jq -r .prompt_tokens_per_second "${perf_json}")" \
        "$(jq -r .generation_tokens_per_second "${perf_json}")" \
        "$(jq -r .time_to_first_token_seconds "${perf_json}")" \
        "${ledger_json}" "${result_json}"
}

validate_prompt_cache_creation_log() {
    local run_log="${1:?cache creation log is required}"
    local session="${2:?cache session path is required}"
    local evidence_json="${3:?cache evidence JSON is required}"
    python3 -B - "${run_log}" "${session}" "${evidence_json}" <<'PY'
import hashlib
import json
import pathlib
import sys

log_path = pathlib.Path(sys.argv[1])
session_path = pathlib.Path(sys.argv[2])
evidence_path = pathlib.Path(sys.argv[3])
lines = log_path.read_text(encoding="utf-8", errors="strict").splitlines()

def die(message: str) -> None:
    raise SystemExit(f"prompt-cache creation validation failed: {message}")

def unique_suffix(label: str, suffix: str) -> int:
    indices = [index for index, line in enumerate(lines) if line.endswith(suffix)]
    if len(indices) != 1:
        die(f"{label} marker count is {len(indices)}, expected 1")
    return indices[0]

attempt = unique_suffix(
    "load-attempt",
    f"llama_completion: attempting to load saved session from '{session_path}'",
)
missing = unique_suffix(
    "new-session",
    "llama_completion: session file does not exist, will create.",
)
saved = unique_suffix(
    "pre-last-token-save",
    f"common_promp: saved session before last token to {session_path}, n_new = 2",
)
if not attempt < missing < saved:
    die("load-attempt/create/save markers are out of order")
for forbidden in (
    "loaded a session with prompt size of",
    "session file has exact match for prompt!",
    "replayed last token from session",
    "common_replay_last_token: failed to replay last token",
):
    if any(forbidden in line for line in lines):
        die(f"reuse/replay evidence appeared during fresh creation: {forbidden}")
if not session_path.is_file() or session_path.stat().st_size <= 0:
    die("saved session is absent or empty")

session_bytes = session_path.read_bytes()
evidence = {
    "schema": "qwen35-08b-q8_0-prompt-cache-creation-v1",
    "session": str(session_path),
    "session_bytes": len(session_bytes),
    "session_sha256": hashlib.sha256(session_bytes).hexdigest(),
    "prompt_tokens_saved": 2,
    "fresh_session_observed": 1,
    "saved_before_last_token": 1,
    "replay_attempted": 0,
    "run_log": str(log_path),
}
evidence_path.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
print(
    "[NPU-STRICT-STEADY-CACHE-CREATE-VALIDATOR][PASS] "
    f"prompt_tokens_saved=2 saved_before_last_token=1 "
    f"session_bytes={len(session_bytes)} "
    f"session_sha256={evidence['session_sha256']}"
)
PY
}

validate_prompt_cache_replay_log() {
    local run_log="${1:?steady replay log is required}"
    local session="${2:?cache session path is required}"
    local evidence_json="${3:?replay evidence JSON is required}"
    python3 -B - "${run_log}" "${session}" "${evidence_json}" <<'PY'
import hashlib
import json
import pathlib
import sys

log_path = pathlib.Path(sys.argv[1])
session_path = pathlib.Path(sys.argv[2])
evidence_path = pathlib.Path(sys.argv[3])
lines = log_path.read_text(encoding="utf-8", errors="strict").splitlines()

def die(message: str) -> None:
    raise SystemExit(f"steady prompt-cache replay validation failed: {message}")

def unique_suffix(label: str, suffix: str) -> int:
    indices = [index for index, line in enumerate(lines) if line.endswith(suffix)]
    if len(indices) != 1:
        die(f"{label} marker count is {len(indices)}, expected 1")
    return indices[0]

attempt = unique_suffix(
    "load-attempt",
    f"llama_completion: attempting to load saved session from '{session_path}'",
)
loaded = unique_suffix(
    "two-token-load",
    "llama_completion: loaded a session with prompt size of 2 tokens",
)
exact = unique_suffix(
    "exact-match",
    "llama_completion: session file has exact match for prompt!",
)
admission = unique_suffix(
    "controlled-admission-stop",
    "[NPU-STRICT-ADMISSION-ONLY][PASS] graph=dispatch "
    "phase=post-binding-pre-scheduler compute_started=0 "
    "dispatch_graph_scheduler_allocated=0 compute_dispatched=0",
)
replay_stop = unique_suffix(
    "replay-controlled-stop",
    "common_replay_last_token: failed to replay last token",
)
if not attempt < loaded < exact < admission < replay_stop:
    die("load/exact-match/admission/replay-stop markers are out of order")
if any(line.endswith("llama_completion: replayed last token from session") for line in lines):
    die("replay unexpectedly completed beyond the admission-only boundary")
if not session_path.is_file() or session_path.stat().st_size <= 0:
    die("read-only replay session is absent or empty")

session_bytes = session_path.read_bytes()
evidence = {
    "schema": "qwen35-08b-q8_0-prompt-cache-replay-v1",
    "session": str(session_path),
    "session_bytes": len(session_bytes),
    "session_sha256": hashlib.sha256(session_bytes).hexdigest(),
    "loaded_prompt_tokens": 2,
    "exact_prompt_match": 1,
    "replay_attempted_controlled_stop": 1,
    "replay_completed": 0,
    "compute_started": 0,
    "dispatch_graph_scheduler_allocated": 0,
    "compute_dispatched": 0,
    "run_log": str(log_path),
}
evidence_path.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
print(
    "[NPU-STRICT-STEADY-CACHE-REPLAY-VALIDATOR][PASS] "
    "loaded_prompt_tokens=2 exact_prompt_match=1 "
    "replay_attempted_controlled_stop=1 replay_completed=0 "
    "compute_started=0 dispatch_graph_scheduler_allocated=0 compute_dispatched=0"
)
PY
}

prepare_steady_prompt_cache() {
    local cache_root="${RUN_ROOT}/steady-prompt-cache"
    local session="${cache_root}/token2.session"
    local prompt_ids="${cache_root}/prompt.ids"
    local generated_ids="${cache_root}/generated.ids"
    local run_log="${cache_root}/run.log"
    local command_log="${cache_root}/command.argv"
    local evidence_json="${cache_root}/creation-evidence.json"
    local run_rc
    local -a command_line=(
        "${ADMISSION_CLI}"
        -m "${MODEL}"
        -p 'x ='
        -n 1
        -c 256
        -b 2
        -ub 2
        -t 1
        -tb 1
        -fa off
        -fit off
        --seed 1
        --temp 0
        --top-k 1
        --no-warmup
        --no-display-prompt
        --no-conversation
        --no-perf
        --reasoning off
        --prompt-cache "${session}"
    )

    mkdir -- "${cache_root}"
    write_hermetic_env_prefix "${command_log}"
    printf '%s ' '-u GGML_BACKEND_PATH' >>"${command_log}"
    printf 'LD_PRELOAD=%q QWEN_PROMPT_TOKEN_TRACE_PATH=%q QWEN_TOKEN_TRACE_PATH=%q' \
        "${HOOK}" "${prompt_ids}" "${generated_ids}" >>"${command_log}"
    printf ' %q' "${command_line[@]}" >>"${command_log}"
    printf ' </dev/null\n' >>"${command_log}"

    set +e
    env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" \
        -u GGML_BACKEND_PATH \
        LD_PRELOAD="${HOOK}" \
        QWEN_PROMPT_TOKEN_TRACE_PATH="${prompt_ids}" \
        QWEN_TOKEN_TRACE_PATH="${generated_ids}" \
        timeout --signal=TERM --kill-after=2s 180s \
        "${command_line[@]}" </dev/null >"${run_log}" 2>&1
    run_rc=$?
    set -e
    [[ "${run_rc}" -eq 0 && -s "${session}" ]] \
        || fail "steady prompt-cache creation failed rc=${run_rc}: ${run_log}"
    [[ "$(<"${prompt_ids}")" == $'87\n283' ]] \
        || fail "steady prompt-cache prompt IDs are not [87,283]: ${prompt_ids}"
    [[ "$(<"${generated_ids}")" == '220' ]] \
        || fail "steady prompt-cache generated token is not 220: ${generated_ids}"
    if grep -Eq '\[NPU-(STRICT|BACKEND|GRAPH-COLLECT)' "${run_log}"; then
        fail "steady prompt-cache creation unexpectedly entered an NPU path"
    fi
    validate_prompt_cache_creation_log \
        "${run_log}" "${session}" "${evidence_json}" \
        || fail "steady prompt-cache creation log semantics are invalid"
    printf '[NPU-STRICT-STEADY-CACHE][PASS] prompt_ids=[87,283] generated_ids=[220] saved_before_last_token=1 session_sha256=%s session=%s evidence=%s\n' \
        "$(jq -r .session_sha256 "${evidence_json}")" \
        "${session}" "${evidence_json}"
}

run_admission_phase() {
    local phase="${1:?admission phase is required}"
    local prompt_text="${2:?admission prompt is required}"
    shift 2
    local admission_root="${RUN_ROOT}/admission-only/${phase}"
    local run_log="${admission_root}/run.log"
    local wall_log="${admission_root}/wall-seconds.txt"
    local command_log="${admission_root}/command.argv"
    local result_json="${admission_root}/result.json"
    local result_tmp="${admission_root}/result.json.tmp"
    local replay_evidence_json="${admission_root}/prompt-cache-replay.json"
    local steady_session="${RUN_ROOT}/steady-prompt-cache/token2.session"
    local timeout_seconds="${NPU_STRICT_ADMISSION_TIMEOUT_SECONDS:-300}"
    local run_rc
    local wall_seconds
    local session_sha_before=''
    local session_sha_after=''
    local -a phase_flags=("$@")
    local -a command_line=(
        "${ADMISSION_CLI}"
        -m "${MODEL}"
        -p "${prompt_text}"
        -n 1
        -c 256
        -b 1
        -ub 1
        -t 1
        -tb 1
        -fa off
        -fit off
        --seed 1
        --temp 0
        --top-k 1
        --backend-sampling
        --no-warmup
        --no-display-prompt
        --no-conversation
        --no-perf
        --reasoning off
        "${phase_flags[@]}"
    )

    [[ "${phase}" == 'bootstrap' || "${phase}" == 'steady' ]] \
        || fail "invalid admission phase: ${phase}"
    if [[ "${phase}" == 'bootstrap' ]]; then
        [[ "${#phase_flags[@]}" -eq 0 ]] \
            || fail 'bootstrap admission must not receive prompt-cache flags'
    else
        [[ "${#phase_flags[@]}" -eq 3 && \
           "${phase_flags[0]}" == '--prompt-cache' && \
           "${phase_flags[1]}" == "${steady_session}" && \
           "${phase_flags[2]}" == '--prompt-cache-ro' ]] \
            || fail 'steady admission must use the frozen read-only token2 prompt cache'
        [[ -s "${steady_session}" ]] \
            || fail "steady admission prompt cache is absent: ${steady_session}"
        session_sha_before="$(sha256sum -- "${steady_session}" | awk '{ print $1 }')"
    fi
    [[ "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]] \
        || fail "NPU_STRICT_ADMISSION_TIMEOUT_SECONDS must be a positive integer"
    mkdir -p -- "${admission_root}"

    write_hermetic_env_prefix "${command_log}"
    printf 'LLAMA_NPU_REQUIRED=1 LLAMA_NPU_ADMISSION_ONLY=1 ' \
        >>"${command_log}"
    printf 'LLAMA_NPU_GRAPH_PROFILE=%q ' "${MANIFEST_PROFILE}" \
        >>"${command_log}"
    printf 'LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q LLAMA_NPU_GRAPH_FUSED_OPS=0 ' \
        "${EXPECTED_LLAMA_COMMIT}" >>"${command_log}"
    printf 'GGML_BACKEND_PATH=%q' "${BACKEND}" >>"${command_log}"
    printf ' %q' "${command_line[@]}" >>"${command_log}"
    printf ' </dev/null\n' >>"${command_log}"

    set +e
    /usr/bin/time -f 'elapsed_seconds=%e' -o "${wall_log}" \
        env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}" \
            LLAMA_NPU_REQUIRED=1 \
            LLAMA_NPU_ADMISSION_ONLY=1 \
            LLAMA_NPU_GRAPH_PROFILE="${MANIFEST_PROFILE}" \
            LLAMA_NPU_GRAPH_SOURCE_COMMIT="${EXPECTED_LLAMA_COMMIT}" \
            LLAMA_NPU_GRAPH_FUSED_OPS=0 \
            GGML_BACKEND_PATH="${BACKEND}" \
            timeout --signal=TERM --kill-after=5s "${timeout_seconds}s" \
            "${command_line[@]}" </dev/null >"${run_log}" 2>&1
    run_rc=$?
    set -e
    [[ "${run_rc}" -eq 1 ]] \
        || fail "${phase} admission did not stop at the controlled decode boundary rc=${run_rc}: ${run_log}"

    validate_admission_only_log "${run_log}" "${result_json}" "${phase}" \
        || fail "real Qwen ${phase} strict admission validation failed"
    if [[ "${phase}" == 'steady' ]]; then
        session_sha_after="$(sha256sum -- "${steady_session}" | awk '{ print $1 }')"
        [[ "${session_sha_after}" == "${session_sha_before}" ]] \
            || fail 'read-only steady replay mutated the prompt-cache session'
        validate_prompt_cache_replay_log \
            "${run_log}" "${steady_session}" "${replay_evidence_json}" \
            || fail 'steady prompt-cache replay log semantics are invalid'
    fi
    wall_seconds="$(extract_wall_seconds "${wall_log}")" \
        || fail "${phase} admission wall-time record is invalid: ${wall_log}"
    if [[ "${phase}" == 'steady' ]]; then
        jq --argjson elapsed_wall_seconds "${wall_seconds}" \
            --slurpfile prompt_cache_replay "${replay_evidence_json}" \
            '. + {
                elapsed_wall_seconds: $elapsed_wall_seconds,
                prompt_cache_replay: $prompt_cache_replay[0]
            }' "${result_json}" >"${result_tmp}"
    else
        jq --argjson elapsed_wall_seconds "${wall_seconds}" \
            '. + {elapsed_wall_seconds: $elapsed_wall_seconds}' \
            "${result_json}" >"${result_tmp}"
    fi
    mv -- "${result_tmp}" "${result_json}"

    printf '[NPU-STRICT-ADMISSION-ONLY][RESULT] graph_phase=%s nodes=1714 required_seen=1080 supported=1080 assigned=1080 unsupported=0 compute_started=0 sampler_argmax_ledger_records=0 elapsed_s=%s output=%s\n' \
        "${phase}" "${wall_seconds}" "${result_json}"
}

run_admission_matrix() {
    local session="${RUN_ROOT}/steady-prompt-cache/token2.session"
    prepare_steady_prompt_cache
    mkdir -p -- "${RUN_ROOT}/admission-only"
    run_admission_phase bootstrap x
    run_admission_phase steady 'x =' --prompt-cache "${session}" --prompt-cache-ro
    jq -n \
        --arg schema 'qwen35-08b-q8_0-npu-strict-admission-matrix-v1' \
        --slurpfile cache_creation \
            "${RUN_ROOT}/steady-prompt-cache/creation-evidence.json" \
        --slurpfile bootstrap \
            "${RUN_ROOT}/admission-only/bootstrap/result.json" \
        --slurpfile steady \
            "${RUN_ROOT}/admission-only/steady/result.json" \
        '{
            schema: $schema,
            prompt_cache_creation: $cache_creation[0],
            phases: [$bootstrap[0], $steady[0]]
        }' \
        >"${RUN_ROOT}/admission-only/result.json"
    printf '[NPU-STRICT-ADMISSION-MATRIX][PASS] phases=bootstrap,steady required_per_phase=1080 supported_per_phase=1080 unsupported_per_phase=0 steady_replay_attempted_controlled_stop=1 compute_started=0 output=%s\n' \
        "${RUN_ROOT}/admission-only/result.json"
}
run_admission_matrix

if [[ "${mode}" == 'admission-only' ]]; then
    exit 0
fi

if [[ "${mode}" == 'interactive' ]]; then
    run_interactive
    exit 0
fi

verify_cpu_reference
run_scripted_turn smoke "${scripted_tokens}"

bootstrap_manifest_artifact_sha="$(sha256sum -- "${MANIFEST}" | awk '{ print $1 }')"
steady_manifest_artifact_sha="$(sha256sum -- "${STEADY_MANIFEST}" | awk '{ print $1 }')"
manifest_bundle_artifact_sha="$(sha256sum -- "${MANIFEST_BUNDLE}" | awk '{ print $1 }')"
admission_matrix_artifact_sha="$(sha256sum -- "${RUN_ROOT}/admission-only/result.json" | awk '{ print $1 }')"

jq -n \
    --arg schema 'qwen35-08b-q8_0-npu-strict-system-v4' \
    --arg profile "${scripted_profile}" \
    --argjson requested_tokens "${scripted_tokens}" \
    --arg model_sha256 "${MODEL_SHA}" \
    --arg llama_commit "${EXPECTED_LLAMA_COMMIT}" \
    --arg hook_sha256 "${HOOK_SHA}" \
    --arg run_root "${RUN_ROOT}" \
    --arg bootstrap_manifest_path "${MANIFEST}" \
    --arg bootstrap_manifest_artifact_sha "${bootstrap_manifest_artifact_sha}" \
    --arg steady_manifest_path "${STEADY_MANIFEST}" \
    --arg steady_manifest_artifact_sha "${steady_manifest_artifact_sha}" \
    --arg manifest_bundle_path "${MANIFEST_BUNDLE}" \
    --arg manifest_bundle_artifact_sha "${manifest_bundle_artifact_sha}" \
    --arg admission_matrix_path "${RUN_ROOT}/admission-only/result.json" \
    --arg admission_matrix_artifact_sha "${admission_matrix_artifact_sha}" \
    --slurpfile bootstrap_manifest "${MANIFEST}" \
    --slurpfile steady_manifest "${STEADY_MANIFEST}" \
    --slurpfile manifest_bundle "${MANIFEST_BUNDLE}" \
    --slurpfile admission_matrix "${RUN_ROOT}/admission-only/result.json" \
    --slurpfile turn "${RUN_ROOT}/smoke/result.json" \
    '{
        schema: $schema,
        profile: $profile,
        requested_tokens: $requested_tokens,
        model_sha256: $model_sha256,
        llama_commit: $llama_commit,
        token_capture_sha256: $hook_sha256,
        run_root: $run_root,
        bootstrap_manifest_identity: {
            path: $bootstrap_manifest_path,
            target_dispatch: 1,
            raw_sha256: $bootstrap_manifest[0].manifest.raw_sha256,
            manifest_sha256: $bootstrap_manifest[0].manifest_sha256,
            artifact_sha256: $bootstrap_manifest_artifact_sha
        },
        steady_manifest_identity: {
            path: $steady_manifest_path,
            target_dispatch:
                $steady_manifest[0].manifest.header.target_dispatch,
            raw_sha256: $steady_manifest[0].manifest.raw_sha256,
            manifest_sha256: $steady_manifest[0].manifest_sha256,
            artifact_sha256: $steady_manifest_artifact_sha
        },
        manifest_bundle_identity: {
            path: $manifest_bundle_path,
            schema: $manifest_bundle[0].schema,
            bundle_sha256: $manifest_bundle[0].bundle_sha256,
            artifact_sha256: $manifest_bundle_artifact_sha,
            counts: $manifest_bundle[0].bundle.counts,
            steady_repeats: $manifest_bundle[0].bundle.steady_repeats
        },
        admission_identity: {
            path: $admission_matrix_path,
            schema: $admission_matrix[0].schema,
            artifact_sha256: $admission_matrix_artifact_sha,
            prompt_cache: {
                creation: {
                    session_sha256:
                        $admission_matrix[0].prompt_cache_creation.session_sha256,
                    session_bytes:
                        $admission_matrix[0].prompt_cache_creation.session_bytes,
                    saved_before_last_token:
                        $admission_matrix[0].prompt_cache_creation.saved_before_last_token
                },
                steady_replay: {
                    session_sha256:
                        $admission_matrix[0].phases[1].prompt_cache_replay.session_sha256,
                    loaded_prompt_tokens:
                        $admission_matrix[0].phases[1].prompt_cache_replay.loaded_prompt_tokens,
                    exact_prompt_match:
                        $admission_matrix[0].phases[1].prompt_cache_replay.exact_prompt_match,
                    replay_attempted_controlled_stop:
                        $admission_matrix[0].phases[1].prompt_cache_replay.replay_attempted_controlled_stop
                }
            },
            phases: [
                $admission_matrix[0].phases[] | {
                    graph_phase,
                    canonical_set_sha256,
                    graph_nodes,
                    required_seen,
                    supported,
                    assigned,
                    unsupported,
                    compute_started,
                    dispatch_graph_scheduler_allocated,
                    compute_dispatched
                }
            ]
        },
        ledger_phases: $turn[0].ledger_phases,
        turns: [$turn[0]]
    }' \
    >"${RUN_ROOT}/result.json"

jq -e \
    --arg bootstrap_raw_sha "${EXPECTED_RAW_MANIFEST_SHA}" \
    --arg bootstrap_manifest_sha "${EXPECTED_MANIFEST_SHA}" \
    --arg steady_raw_sha "${EXPECTED_STEADY_RAW_MANIFEST_SHA}" \
    --arg steady_manifest_sha "${EXPECTED_STEADY_MANIFEST_SHA}" \
    --arg bundle_sha "${EXPECTED_MANIFEST_BUNDLE_SHA}" '
        .schema == "qwen35-08b-q8_0-npu-strict-system-v4" and
        .bootstrap_manifest_identity.target_dispatch == 1 and
        .bootstrap_manifest_identity.raw_sha256 == $bootstrap_raw_sha and
        .bootstrap_manifest_identity.manifest_sha256 == $bootstrap_manifest_sha and
        (.bootstrap_manifest_identity.artifact_sha256 | test("^[0-9a-f]{64}$")) and
        .steady_manifest_identity.target_dispatch == 2 and
        .steady_manifest_identity.raw_sha256 == $steady_raw_sha and
        .steady_manifest_identity.manifest_sha256 == $steady_manifest_sha and
        (.steady_manifest_identity.artifact_sha256 | test("^[0-9a-f]{64}$")) and
        .manifest_bundle_identity.schema ==
            "qwen-npu-graph-manifest-bundle-envelope-v1" and
        .manifest_bundle_identity.bundle_sha256 == $bundle_sha and
        (.manifest_bundle_identity.artifact_sha256 | test("^[0-9a-f]{64}$")) and
        .manifest_bundle_identity.counts.steady_repeat_manifests == 6 and
        [.manifest_bundle_identity.steady_repeats[].dispatch] == [3,4,5,6,7,8] and
        .admission_identity.schema ==
            "qwen35-08b-q8_0-npu-strict-admission-matrix-v1" and
        (.admission_identity.artifact_sha256 | test("^[0-9a-f]{64}$")) and
        [.admission_identity.phases[].graph_phase] == ["bootstrap", "steady"] and
        .admission_identity.phases[0].canonical_set_sha256 ==
            .admission_identity.phases[1].canonical_set_sha256 and
        all(.admission_identity.phases[];
            .required_seen == 1080 and .supported == 1080 and
            .assigned == 1080 and .unsupported == 0 and
            .compute_started == 0 and
            .dispatch_graph_scheduler_allocated == 0 and
            .compute_dispatched == 0) and
        .admission_identity.prompt_cache.creation.saved_before_last_token == 1 and
        .admission_identity.prompt_cache.creation.session_bytes > 0 and
        (.admission_identity.prompt_cache.creation.session_sha256 |
            test("^[0-9a-f]{64}$")) and
        .admission_identity.prompt_cache.steady_replay.loaded_prompt_tokens == 2 and
        .admission_identity.prompt_cache.steady_replay.exact_prompt_match == 1 and
        .admission_identity.prompt_cache.steady_replay.replay_attempted_controlled_stop == 1 and
        .admission_identity.prompt_cache.creation.session_sha256 ==
            .admission_identity.prompt_cache.steady_replay.session_sha256 and
        .ledger_phases == .turns[0].ledger_phases
    ' "${RUN_ROOT}/result.json" >/dev/null \
    || fail "final v4 identity/phase envelope validation failed: ${RUN_ROOT}/result.json"

scripted_dispatches="$(jq -r '.turns[0].system_ledger.dispatches' "${RUN_ROOT}/result.json")"
scripted_required="$(jq -r '.turns[0].system_ledger.required_completed' "${RUN_ROOT}/result.json")"
scripted_sampler_elements="$(jq -r '.turns[0].system_ledger.sampler_argmax_elements' "${RUN_ROOT}/result.json")"
scripted_sampler_tokens="$(jq -r '.turns[0].system_ledger.sampler_argmax_sampled_tokens' "${RUN_ROOT}/result.json")"
scripted_bootstrap_dispatches="$(jq -r '.ledger_phases.bootstrap.dispatches' "${RUN_ROOT}/result.json")"
scripted_steady_dispatches="$(jq -r '.ledger_phases.steady.dispatches' "${RUN_ROOT}/result.json")"
scripted_f32_bootstrap_owner="$(jq -r '.ledger_phases.bootstrap.f32_alu_owner_transactions' "${RUN_ROOT}/result.json")"
scripted_f32_bootstrap_zero="$(jq -r '.ledger_phases.bootstrap.f32_alu_zero_cardinality_transactions' "${RUN_ROOT}/result.json")"
scripted_f32_bootstrap_nonempty="$(jq -r '.ledger_phases.bootstrap.f32_alu_nonempty_portal_commands' "${RUN_ROOT}/result.json")"
scripted_f32_steady_owner="$(jq -r '.ledger_phases.steady.f32_alu_owner_transactions' "${RUN_ROOT}/result.json")"
scripted_f32_steady_zero="$(jq -r '.ledger_phases.steady.f32_alu_zero_cardinality_transactions' "${RUN_ROOT}/result.json")"
scripted_f32_steady_nonempty="$(jq -r '.ledger_phases.steady.f32_alu_nonempty_portal_commands' "${RUN_ROOT}/result.json")"
scripted_f32_zero="$(jq -r '.ledger_phases.total.f32_alu_zero_cardinality_transactions' "${RUN_ROOT}/result.json")"
scripted_f32_nonempty="$(jq -r '.ledger_phases.total.f32_alu_nonempty_portal_commands' "${RUN_ROOT}/result.json")"
scripted_f32_bootstrap_read="$(jq -r '.ledger_phases.bootstrap.f32_alu_portal_raw_read_copy_bytes' "${RUN_ROOT}/result.json")"
scripted_f32_bootstrap_write="$(jq -r '.ledger_phases.bootstrap.f32_alu_portal_raw_write_copy_bytes' "${RUN_ROOT}/result.json")"
scripted_f32_steady_read="$(jq -r '.ledger_phases.steady.f32_alu_portal_raw_read_copy_bytes' "${RUN_ROOT}/result.json")"
scripted_f32_steady_write="$(jq -r '.ledger_phases.steady.f32_alu_portal_raw_write_copy_bytes' "${RUN_ROOT}/result.json")"
printf '[NPU-STRICT-SCRIPTED][PASS] schema=qwen35-08b-q8_0-npu-strict-system-v4 profile=%s turns=1 prompt_mode=raw-no-conversation prompt=x generated_tokens=%s dispatches=%s bootstrap_dispatches=%s steady_dispatches=%s required_completed=%s admission_required_per_dispatch=1080 admission_supported_per_dispatch=1080 admission_unsupported_per_dispatch=0 system_transport=all-required f32_alu_bootstrap_owner_transactions=%s f32_alu_bootstrap_zero_cardinality_transactions=%s f32_alu_bootstrap_nonempty_portal_commands=%s f32_alu_bootstrap_portal_raw_read_copy_bytes=%s f32_alu_bootstrap_portal_raw_write_copy_bytes=%s f32_alu_steady_owner_transactions=%s f32_alu_steady_zero_cardinality_transactions=%s f32_alu_steady_nonempty_portal_commands=%s f32_alu_steady_portal_raw_read_copy_bytes=%s f32_alu_steady_portal_raw_write_copy_bytes=%s f32_alu_zero_cardinality_transactions=%s f32_alu_nonempty_portal_commands=%s bootstrap_manifest_sha256=%s steady_manifest_sha256=%s manifest_bundle_sha256=%s admission_matrix_artifact_sha256=%s sampler_argmax=dispatch-closed-exact sampler_argmax_elements=%s sampler_argmax_sampled_tokens=%s sampler_argmax_transactions_per_dispatch=1 sampler_argmax_elements_per_dispatch=248320 sampler_argmax_read_bytes_per_dispatch=993288 sampler_argmax_scalar_write_bytes_per_dispatch=4 sampler_argmax_sampled_tokens_per_dispatch=1 sampler_argmax_host_scalar_copy_bytes_per_dispatch=4 sampler_argmax_full_vocab_host_exports_per_dispatch=0 sampler_argmax_full_vocab_host_export_bytes_per_dispatch=0 sampler_argmax_cpu_candidate_scans_per_dispatch=0 sampler_argmax_invalid_tokens_per_dispatch=0 cpu_fallback_attempts=0 host_tensor_arithmetic=0 token_ids=exact-cpu-oracle-prefix output=%s\n' \
    "${scripted_profile}" "${scripted_tokens}" "${scripted_dispatches}" \
    "${scripted_bootstrap_dispatches}" "${scripted_steady_dispatches}" \
    "${scripted_required}" "${scripted_f32_bootstrap_owner}" \
    "${scripted_f32_bootstrap_zero}" "${scripted_f32_bootstrap_nonempty}" \
    "${scripted_f32_bootstrap_read}" "${scripted_f32_bootstrap_write}" \
    "${scripted_f32_steady_owner}" "${scripted_f32_steady_zero}" \
    "${scripted_f32_steady_nonempty}" "${scripted_f32_steady_read}" \
    "${scripted_f32_steady_write}" "${scripted_f32_zero}" \
    "${scripted_f32_nonempty}" "${EXPECTED_MANIFEST_SHA}" \
    "${EXPECTED_STEADY_MANIFEST_SHA}" "${EXPECTED_MANIFEST_BUNDLE_SHA}" \
    "${admission_matrix_artifact_sha}" "${scripted_sampler_elements}" \
    "${scripted_sampler_tokens}" "${RUN_ROOT}/result.json"
