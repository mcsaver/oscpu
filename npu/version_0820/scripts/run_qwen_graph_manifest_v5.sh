#!/usr/bin/env bash
set -u -o pipefail
ulimit -c 0 || exit 2

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
repo_root="$(cd "$project_root/../.." && pwd -P)"
identity="qwen-graph-manifest-v5"
log_root="$project_root/tmp/logs/$identity"
status_helper="$repo_root/scripts/task-run-status.sh"
status_published=0
cleanup_rc=0

model="$project_root/models/Qwen3.5-0.8B-Q8_0.gguf"
build_root="$project_root/tmp/build/llama.cpp"
bin_root="$build_root/bin"
completion="$bin_root/llama-completion"
tokenize="$bin_root/llama-tokenize"
raw="$log_root/dispatch.raw.jsonl"
canonical_json="$log_root/dispatch.manifest.json"
canonical_jsonl="$log_root/dispatch.manifest.jsonl"
model_sha="37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"
source_commit="95c409c13625a23da2aa37270339ce9179215a18"
profile="qwen35-0.8b-b1t1-unfused-nonflash-v5"
numeric_profile="strict-f32-rne-canonical-nan-v1"

cd "$repo_root" || exit 2
[[ ! -e "$log_root" ]] || {
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V5][FAIL] immutable output root exists: $log_root" >&2
  exit 3
}
mkdir -p "$log_root" || exit 4
source "$status_helper"
task_run_status_init "$log_root/run.status" || exit 5

fail() {
  local rc
  local stage
  local message
  rc="${1:?rc}"
  stage="${2:?stage}"
  message="${3:?message}"
  task_run_status_stage "$stage"
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V5][FAIL] stage=$stage rc=$rc $message" >&2
  exit "$rc"
}

finish_exit() {
  local command_rc
  local final_rc
  command_rc=$?
  final_rc="$command_rc"
  trap - EXIT HUP INT TERM
  if [[ "$status_published" -eq 0 ]]; then
    task_run_status_finalize "$command_rc" "$cleanup_rc" >/dev/null 2>&1
    final_rc=$?
  fi
  exit "$final_rc"
}

signal_exit() {
  TASK_RUN_STATUS_SIGNAL="${1:?signal}"
  exit "${2:?rc}"
}

trap finish_exit EXIT
trap 'signal_exit HUP 129' HUP
trap 'signal_exit INT 130' INT
trap 'signal_exit TERM 143' TERM

task_run_status_stage static-identity
bash -n "$0" || fail 10 static-identity 'runner bash-n failed'
bash "$repo_root/scripts/tests/test-task-run-status.sh" \
  >"$log_root/task-status-selftest.log" 2>&1 ||
  fail 11 static-identity 'task-run-status self-test failed'
PYTHONDONTWRITEBYTECODE=1 python3 -B "$project_root/tests/test_qwen_graph_manifest.py" \
  >"$log_root/manifest-unittest.log" 2>&1 ||
  fail 12 static-identity 'manifest unit tests failed'
python3 "$project_root/scripts/verify_locked_inputs.py" \
  >"$log_root/locked-inputs.log" 2>&1 ||
  fail 13 static-identity 'locked source/model verification failed'
[[ -x "$completion" && -x "$tokenize" && -f "$model" ]] ||
  fail 14 static-identity 'completion/tokenizer/model missing'
"$completion" --version >"$log_root/llama-completion-version.log" 2>&1 ||
  fail 15 static-identity 'llama-completion version query failed'
grep -Fqx "version: 0.1.2-dev (build 10507, commit $source_commit)" \
  "$log_root/llama-completion-version.log" ||
  fail 16 static-identity 'llama-completion identity mismatch'
[[ "$(sha256sum "$model" | awk '{print $1}')" == "$model_sha" ]] ||
  fail 17 static-identity 'model digest mismatch'

for predecessor in qwen-graph-manifest-v1 qwen-graph-manifest-v2 qwen-graph-manifest-v3 qwen-graph-manifest-v4; do
  [[ "$(sed -n '1p' "$project_root/tmp/logs/$predecessor/run.status")" == \
     'FAIL rc=1 stage=collect-dispatch evidence_complete=0 cleanup_rc=0' ]] ||
    fail 18 static-identity "predecessor status drift: $predecessor"
done
[[ "$(sha256sum "$project_root/tmp/logs/qwen-graph-manifest-v1/dispatch.raw.jsonl" | awk '{print $1}')" == \
   '26e17c78d7b24471823c842d719aafcd6d93a52b9ef1669da002738864d6d882' ]] ||
  fail 19 static-identity 'v1 T=2 raw drift'
[[ "$(sha256sum "$project_root/tmp/logs/qwen-graph-manifest-v2/dispatch.raw.jsonl" | awk '{print $1}')" == \
   'b29ad94a026a5992b5ec6c4300b1fdaef8dee4bb82b8d37e40dfab0edaf9c531' ]] ||
  fail 20 static-identity 'v2 server raw drift'
[[ ! -e "$project_root/tmp/logs/qwen-graph-manifest-v3/dispatch.raw.jsonl" ]] ||
  fail 21 static-identity 'v3 invalid-option attempt unexpectedly has raw'
[[ "$(sha256sum "$project_root/tmp/logs/qwen-graph-manifest-v4/dispatch.raw.jsonl" | awk '{print $1}')" == \
   '19b01a3d19d8071814e2e49ff400b9d2b4490ebeb951982aad136a849dfd3922' ]] ||
  fail 22 static-identity 'v4 fused/flash raw drift'

"$tokenize" -m "$model" -p x --ids --show-count --offline \
  >"$log_root/tokenizer.log" 2>&1 ||
  fail 23 tokenizer-preflight 'tokenizer command failed'
[[ "$(grep -Fxc '[87]' "$log_root/tokenizer.log")" -eq 1 ]] ||
  fail 24 tokenizer-preflight 'raw prompt token id is not uniquely [87]'
[[ "$(grep -Fxc 'Total number of tokens: 1' "$log_root/tokenizer.log")" -eq 1 ]] ||
  fail 25 tokenizer-preflight 'raw prompt is not exactly one token'

find "$bin_root" -maxdepth 1 -type f -name 'lib*.so*' -print0 | sort -z | \
  xargs -0 sha256sum >"$log_root/runtime-libs.sha256" ||
  fail 26 static-identity 'cannot freeze runtime libraries'
[[ "$(wc -l < "$log_root/runtime-libs.sha256")" -ge 6 ]] ||
  fail 27 static-identity 'runtime library census unexpectedly small'
sha256sum -c "$log_root/runtime-libs.sha256" >"$log_root/runtime-libs.check" 2>&1 ||
  fail 28 static-identity 'runtime library hash check failed'
ldd "$completion" >"$log_root/runtime-ldd.log" 2>&1 ||
  fail 29 static-identity 'cannot record runtime dependency closure'

sha256sum \
  "$project_root/third_party/SOURCES.lock.json" \
  "$project_root/models/MODELS.lock.json" \
  "$model" \
  "$completion" \
  "$tokenize" \
  "$build_root/CMakeCache.txt" \
  "$build_root/build.ninja" \
  "$project_root/third_party/llama.cpp/src/llama-context.cpp" \
  "$project_root/third_party/llama.cpp/src/llama-context.h" \
  "$project_root/scripts/qwen_graph_manifest.py" \
  "$project_root/tests/test_qwen_graph_manifest.py" \
  "$repo_root/scripts/task-run-status.sh" \
  "$repo_root/scripts/tests/test-task-run-status.sh" \
  "$log_root/runtime-libs.sha256" \
  "$log_root/runtime-libs.check" \
  "$log_root/runtime-ldd.log" \
  "$project_root/tmp/logs/qwen-graph-manifest-v1/run.status" \
  "$project_root/tmp/logs/qwen-graph-manifest-v1/collect.log" \
  "$project_root/tmp/logs/qwen-graph-manifest-v1/collect.rc" \
  "$project_root/tmp/logs/qwen-graph-manifest-v1/dispatch.raw.jsonl" \
  "$project_root/tmp/logs/qwen-graph-manifest-v2/run.status" \
  "$project_root/tmp/logs/qwen-graph-manifest-v2/collect.log" \
  "$project_root/tmp/logs/qwen-graph-manifest-v2/collect.rc" \
  "$project_root/tmp/logs/qwen-graph-manifest-v2/dispatch.raw.jsonl" \
  "$project_root/tmp/logs/qwen-graph-manifest-v3/run.status" \
  "$project_root/tmp/logs/qwen-graph-manifest-v3/collect.log" \
  "$project_root/tmp/logs/qwen-graph-manifest-v3/collect.rc" \
  "$project_root/tmp/logs/qwen-graph-manifest-v3/collect.argv" \
  "$project_root/tmp/logs/qwen-graph-manifest-v4/run.status" \
  "$project_root/tmp/logs/qwen-graph-manifest-v4/collect.log" \
  "$project_root/tmp/logs/qwen-graph-manifest-v4/collect.rc" \
  "$project_root/tmp/logs/qwen-graph-manifest-v4/dispatch.raw.jsonl" \
  "$0" >"$log_root/inputs.sha256" ||
  fail 30 static-identity 'cannot freeze inputs'
sha256sum -c "$log_root/inputs.sha256" >"$log_root/inputs.check" 2>&1 ||
  fail 31 static-identity 'input hash check failed'

collect_command=(
  "$completion"
  -m "$model"
  -p x
  -n 1
  -c 256
  -b 1
  -ub 1
  -t 1
  -tb 1
  -fa off
  --seed 1
  --temp 0
  --top-k 1
  --no-warmup
  --no-display-prompt
  --no-conversation
  --no-perf
)
printf 'LLAMA_NPU_GRAPH_COLLECT=%q LLAMA_NPU_GRAPH_PROFILE=%q LLAMA_NPU_GRAPH_NUMERIC_PROFILE=%q LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q LLAMA_NPU_GRAPH_MODEL_SHA256=%q LLAMA_NPU_GRAPH_FUSED_OPS=0' \
  "$raw" "$profile" "$numeric_profile" "$source_commit" "$model_sha" \
  >"$log_root/collect.argv"
printf ' %q' "${collect_command[@]}" >>"$log_root/collect.argv"
printf '\n' >>"$log_root/collect.argv"

task_run_status_stage collect-dispatch
LLAMA_NPU_GRAPH_COLLECT="$raw" \
LLAMA_NPU_GRAPH_PROFILE="$profile" \
LLAMA_NPU_GRAPH_NUMERIC_PROFILE="$numeric_profile" \
LLAMA_NPU_GRAPH_SOURCE_COMMIT="$source_commit" \
LLAMA_NPU_GRAPH_MODEL_SHA256="$model_sha" \
LLAMA_NPU_GRAPH_FUSED_OPS=0 \
timeout --signal=TERM --kill-after=2s 60s \
  "${collect_command[@]}" >"$log_root/collect.log" 2>&1
collect_rc=$?
printf '%s\n' "$collect_rc" >"$log_root/collect.rc" ||
  fail 40 collect-dispatch 'cannot record collect rc'
[[ "$collect_rc" -eq 1 ]] ||
  fail 41 collect-dispatch "llama-completion did not propagate controlled decode failure as rc=1, got $collect_rc"
[[ -s "$raw" && ! -e "$raw.tmp" ]] ||
  fail 42 collect-dispatch 'complete exclusive raw artifact missing'
[[ "$(grep -Ec '^\[NPU-GRAPH-COLLECT\]\[PASS\] phase=post-build-pre-scheduler nodes=1711 compute_started=0 path=' "$log_root/collect.log")" -eq 1 ]] ||
  fail 43 collect-dispatch 'exact unfused non-Flash T=1 collect PASS marker missing'
[[ "$(grep -Fc '[NPU-GRAPH-COLLECT][STOP]' "$log_root/collect.log")" -eq 0 ]] ||
  fail 44 collect-dispatch 'unexpected repeat dispatch reached collector'
[[ "$(grep -Fc '[NPU-GRAPH-COLLECT][FAIL]' "$log_root/collect.log")" -eq 0 ]] ||
  fail 45 collect-dispatch 'collector FAIL marker present'
if grep -Eq '\[NPU-STRICT\]|prompt eval time =|[[:space:]]eval time =|\[ Prompt: .* t/s \| Generation: .* t/s \]' \
     "$log_root/collect.log"; then
  fail 46 collect-dispatch 'strict/compute/timing marker appeared in collect-only run'
fi

task_run_status_stage validate-manifest
raw_sha="$(sha256sum "$raw" | awk '{print $1}')"
PYTHONDONTWRITEBYTECODE=1 python3 -B "$project_root/scripts/qwen_graph_manifest.py" validate "$raw" \
  --json-out "$canonical_json" \
  --jsonl-out "$canonical_jsonl" \
  --expect-raw-sha256 "$raw_sha" \
  --expect-model-sha256 "$model_sha" \
  --expect-source-commit "$source_commit" \
  --expect-profile "$profile" \
  --expect-numeric-profile "$numeric_profile" \
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
  --expect-node-count 1711 \
  --expect-compute-count 959 \
  --expect-mover-count 120 \
  --expect-metadata-count 632 \
  >"$log_root/validator.log" 2>&1 ||
  fail 50 validate-manifest 'canonical validator rejected dispatch graph'
[[ "$(grep -Ec '^\[NPU-GRAPH-MANIFEST\]\[PASS\] nodes=1711 compute=959 mover=120 metadata=632 raw_sha256=[0-9a-f]{64} manifest_sha256=[0-9a-f]{64}$' "$log_root/validator.log")" -eq 1 ]] ||
  fail 51 validate-manifest 'exact validator PASS marker missing'
[[ -s "$canonical_json" && -s "$canonical_jsonl" ]] ||
  fail 52 validate-manifest 'canonical outputs missing'

task_run_status_stage prepublish
manifest_sha="$(sed -n 's/.* manifest_sha256=\([0-9a-f]\{64\}\)$/\1/p' "$log_root/validator.log")"
[[ "$manifest_sha" =~ ^[0-9a-f]{64}$ ]] || fail 60 prepublish 'cannot parse manifest SHA'
if ps -eo pid=,args= | grep -E '[l]lama-(cli|completion).*Qwen3\.5-0\.8B|[V]tb_|[v]erilator' \
     >"$log_root/residual-processes.txt"; then
  fail 61 prepublish 'active model/RTL process remains'
fi
printf '%s\n' 0 >"$log_root/cleanup.rc" || fail 62 prepublish 'cannot record cleanup rc'
printf '%s\n' PASS >"$log_root/final-status.expected" || fail 63 prepublish 'cannot write expected status'
printf '%s\n' \
  "[NPU-GRAPH-MANIFEST][RECEIPT] identity=$identity nodes=1711 compute=959 mover=120 metadata=632 ubatch_tokens=1 n_batch=1 n_ubatch=1 n_rs_seq=0 flash_attn=0 fused_ops=0 collect_rc=$collect_rc collect_pass=1 collect_stop=0 collect_fail=0 compute_started=0 raw_sha256=$raw_sha manifest_sha256=$manifest_sha cleanup_rc=0 evidence_complete=1" \
  >"$log_root/final.receipt" || fail 64 prepublish 'cannot write receipt'
sha256sum \
  "$log_root/inputs.sha256" \
  "$log_root/inputs.check" \
  "$log_root/task-status-selftest.log" \
  "$log_root/manifest-unittest.log" \
  "$log_root/locked-inputs.log" \
  "$log_root/llama-completion-version.log" \
  "$log_root/tokenizer.log" \
  "$log_root/runtime-libs.sha256" \
  "$log_root/runtime-libs.check" \
  "$log_root/runtime-ldd.log" \
  "$log_root/collect.argv" \
  "$log_root/collect.log" \
  "$log_root/collect.rc" \
  "$raw" \
  "$canonical_json" \
  "$canonical_jsonl" \
  "$log_root/validator.log" \
  "$log_root/residual-processes.txt" \
  "$log_root/cleanup.rc" \
  "$log_root/final-status.expected" \
  "$log_root/final.receipt" \
  >"$log_root/final.binding.sha256" || fail 65 prepublish 'cannot write final binding'
sha256sum -c "$log_root/final.binding.sha256" >"$log_root/final-binding.check" 2>&1 ||
  fail 66 prepublish 'final binding check failed'

task_run_status_mark_evidence_complete
trap - EXIT HUP INT TERM
task_run_status_finalize 0 0 && {
  status_published=1
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V5][PASS] identity=$identity nodes=1711 compute=959 mover=120 metadata=632"
  exit 0
}
exit $?
