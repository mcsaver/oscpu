#!/usr/bin/env bash
set -u -o pipefail
ulimit -c 0 || exit 2

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
repo_root="$(cd "$project_root/../.." && pwd -P)"
identity="qwen-graph-manifest-v4"
log_root="$project_root/tmp/logs/$identity"
v1_root="$project_root/tmp/logs/qwen-graph-manifest-v1"
v2_root="$project_root/tmp/logs/qwen-graph-manifest-v2"
v3_root="$project_root/tmp/logs/qwen-graph-manifest-v3"
status_helper="$repo_root/scripts/task-run-status.sh"
status_published=0
cleanup_rc=0

model="$project_root/models/Qwen3.5-0.8B-Q8_0.gguf"
completion="$project_root/tmp/build/llama.cpp/bin/llama-completion"
tokenize="$project_root/tmp/build/llama.cpp/bin/llama-tokenize"
raw="$log_root/dispatch.raw.jsonl"
canonical_json="$log_root/dispatch.manifest.json"
canonical_jsonl="$log_root/dispatch.manifest.jsonl"
model_sha="37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"
source_commit="95c409c13625a23da2aa37270339ce9179215a18"
profile="qwen35-0.8b-b1t1-default-v4"
numeric_profile="strict-f32-rne-canonical-nan-v1"

cd "$repo_root" || exit 2
[[ ! -e "$log_root" ]] || {
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V4][FAIL] immutable output root exists: $log_root" >&2
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
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V4][FAIL] stage=$stage rc=$rc $message" >&2
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

[[ "$(sed -n '1p' "$v1_root/run.status")" == \
   'FAIL rc=1 stage=collect-dispatch evidence_complete=0 cleanup_rc=0' ]] ||
  fail 18 static-identity 'v1 FAIL status drift'
[[ "$(sed -n '1p' "$v2_root/run.status")" == \
   'FAIL rc=1 stage=collect-dispatch evidence_complete=0 cleanup_rc=0' ]] ||
  fail 19 static-identity 'v2 FAIL status drift'
[[ "$(sed -n '1p' "$v3_root/run.status")" == \
   'FAIL rc=1 stage=collect-dispatch evidence_complete=0 cleanup_rc=0' ]] ||
  fail 20 static-identity 'v3 FAIL status drift'
[[ "$(sha256sum "$v3_root/collect.log" | awk '{print $1}')" == \
   '3bb1cddde17d133183d4bb6b50f1794eb6697f8445669a520ef569cf5009aff4' ]] ||
  fail 21 static-identity 'v3 invalid-option diagnostic drift'
[[ "$(sed -n '1p' "$v3_root/collect.rc")" == '1' && ! -e "$v3_root/dispatch.raw.jsonl" ]] ||
  fail 22 static-identity 'v3 zero-raw failure drift'

"$tokenize" -m "$model" -p x --ids --show-count --offline \
  >"$log_root/tokenizer.log" 2>&1 ||
  fail 23 tokenizer-preflight 'tokenizer command failed'
[[ "$(grep -Fxc '[87]' "$log_root/tokenizer.log")" -eq 1 ]] ||
  fail 24 tokenizer-preflight 'raw prompt token id is not uniquely [87]'
[[ "$(grep -Fxc 'Total number of tokens: 1' "$log_root/tokenizer.log")" -eq 1 ]] ||
  fail 25 tokenizer-preflight 'raw prompt is not exactly one token'

sha256sum \
  "$project_root/third_party/SOURCES.lock.json" \
  "$project_root/models/MODELS.lock.json" \
  "$model" \
  "$completion" \
  "$tokenize" \
  "$project_root/third_party/llama.cpp/src/llama-context.cpp" \
  "$project_root/third_party/llama.cpp/src/llama-context.h" \
  "$project_root/scripts/qwen_graph_manifest.py" \
  "$project_root/tests/test_qwen_graph_manifest.py" \
  "$repo_root/scripts/task-run-status.sh" \
  "$repo_root/scripts/tests/test-task-run-status.sh" \
  "$v1_root/run.status" \
  "$v1_root/collect.log" \
  "$v1_root/collect.rc" \
  "$v1_root/dispatch.raw.jsonl" \
  "$v2_root/run.status" \
  "$v2_root/collect.log" \
  "$v2_root/collect.rc" \
  "$v2_root/dispatch.raw.jsonl" \
  "$v3_root/run.status" \
  "$v3_root/collect.log" \
  "$v3_root/collect.rc" \
  "$v3_root/collect.argv" \
  "$0" >"$log_root/inputs.sha256" ||
  fail 26 static-identity 'cannot freeze inputs'
sha256sum -c "$log_root/inputs.sha256" >"$log_root/inputs.check" 2>&1 ||
  fail 27 static-identity 'input hash check failed'

collect_command=(
  "$completion"
  -m "$model"
  -p x
  -n 1
  -c 256
  -b 8
  -ub 8
  -t 1
  -tb 1
  --seed 1
  --temp 0
  --top-k 1
  --no-warmup
  --no-display-prompt
  --no-conversation
  --no-perf
)
printf 'LLAMA_NPU_GRAPH_COLLECT=%q LLAMA_NPU_GRAPH_PROFILE=%q LLAMA_NPU_GRAPH_NUMERIC_PROFILE=%q LLAMA_NPU_GRAPH_SOURCE_COMMIT=%q LLAMA_NPU_GRAPH_MODEL_SHA256=%q' \
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
timeout --signal=TERM --kill-after=2s 60s \
  "${collect_command[@]}" >"$log_root/collect.log" 2>&1
collect_rc=$?
printf '%s\n' "$collect_rc" >"$log_root/collect.rc" ||
  fail 30 collect-dispatch 'cannot record collect rc'
[[ "$collect_rc" -eq 1 ]] ||
  fail 31 collect-dispatch "llama-completion did not propagate controlled decode failure as rc=1, got $collect_rc"
[[ -s "$raw" && ! -e "$raw.tmp" ]] ||
  fail 32 collect-dispatch 'complete exclusive raw artifact missing'
[[ "$(grep -Ec '^\[NPU-GRAPH-COLLECT\]\[PASS\] phase=post-build-pre-scheduler nodes=1711 compute_started=0 path=' "$log_root/collect.log")" -eq 1 ]] ||
  fail 33 collect-dispatch 'exact T=1 collect PASS marker missing'
[[ "$(grep -Fc '[NPU-GRAPH-COLLECT][STOP]' "$log_root/collect.log")" -eq 0 ]] ||
  fail 34 collect-dispatch 'unexpected repeat dispatch reached collector'
[[ "$(grep -Fc '[NPU-GRAPH-COLLECT][FAIL]' "$log_root/collect.log")" -eq 0 ]] ||
  fail 35 collect-dispatch 'collector FAIL marker present'
if grep -Eq '\[NPU-STRICT\]|prompt eval time =|[[:space:]]eval time =|\[ Prompt: .* t/s \| Generation: .* t/s \]' \
     "$log_root/collect.log"; then
  fail 36 collect-dispatch 'strict/compute/timing marker appeared in collect-only run'
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
  --expect-ubatch-tokens 1 \
  --expect-node-count 1711 \
  --expect-compute-count 959 \
  --expect-mover-count 120 \
  --expect-metadata-count 632 \
  >"$log_root/validator.log" 2>&1 ||
  fail 40 validate-manifest 'canonical validator rejected dispatch graph'
[[ "$(grep -Ec '^\[NPU-GRAPH-MANIFEST\]\[PASS\] nodes=1711 compute=959 mover=120 metadata=632 raw_sha256=[0-9a-f]{64} manifest_sha256=[0-9a-f]{64}$' "$log_root/validator.log")" -eq 1 ]] ||
  fail 41 validate-manifest 'exact validator PASS marker missing'
[[ -s "$canonical_json" && -s "$canonical_jsonl" ]] ||
  fail 42 validate-manifest 'canonical outputs missing'

task_run_status_stage prepublish
manifest_sha="$(sed -n 's/.* manifest_sha256=\([0-9a-f]\{64\}\)$/\1/p' "$log_root/validator.log")"
[[ "$manifest_sha" =~ ^[0-9a-f]{64}$ ]] || fail 50 prepublish 'cannot parse manifest SHA'
if ps -eo pid=,args= | grep -E '[l]lama-(cli|completion).*Qwen3\.5-0\.8B|[V]tb_|[v]erilator' \
     >"$log_root/residual-processes.txt"; then
  fail 51 prepublish 'active model/RTL process remains'
fi
printf '%s\n' 0 >"$log_root/cleanup.rc" || fail 52 prepublish 'cannot record cleanup rc'
printf '%s\n' PASS >"$log_root/final-status.expected" || fail 53 prepublish 'cannot write expected status'
printf '%s\n' \
  "[NPU-GRAPH-MANIFEST][RECEIPT] identity=$identity nodes=1711 compute=959 mover=120 metadata=632 ubatch_tokens=1 collect_rc=$collect_rc collect_pass=1 collect_stop=0 collect_fail=0 compute_started=0 raw_sha256=$raw_sha manifest_sha256=$manifest_sha cleanup_rc=0 evidence_complete=1" \
  >"$log_root/final.receipt" || fail 54 prepublish 'cannot write receipt'
sha256sum \
  "$log_root/inputs.sha256" \
  "$log_root/inputs.check" \
  "$log_root/task-status-selftest.log" \
  "$log_root/manifest-unittest.log" \
  "$log_root/locked-inputs.log" \
  "$log_root/llama-completion-version.log" \
  "$log_root/tokenizer.log" \
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
  >"$log_root/final.binding.sha256" || fail 55 prepublish 'cannot write final binding'
sha256sum -c "$log_root/final.binding.sha256" >"$log_root/final-binding.check" 2>&1 ||
  fail 56 prepublish 'final binding check failed'

task_run_status_mark_evidence_complete
trap - EXIT HUP INT TERM
task_run_status_finalize 0 0 && {
  status_published=1
  printf '%s\n' "[NPU-GRAPH-MANIFEST-V4][PASS] identity=$identity nodes=1711 compute=959 mover=120 metadata=632"
  exit 0
}
exit $?
