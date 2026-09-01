#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families v5 continuation provenance and source preflight.
#
# The first authorization is intentionally build-free.  This runner regenerates
# canonical JSON/JSONL from the frozen raw dispatch, independently re-audits all
# 367 F32 identities, binds the representative/canonical split, and exercises
# fail-closed status/mutation probes.  It never invokes Verilator, make, a
# backend binary, or an execution suite in --preflight mode.  --execute remains
# fail-closed until a later owner explicitly authorizes the dynamic phase.

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-v5"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-v5.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v5.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v5-material.md"
OWNER_CONTRACT="$NPU_ROOT/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md"
V3_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v3.json"
V3_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v3-material.md"
V4_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v4.json"
V4_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v4-material.md"
STATIC_REVIEW_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-static-review-v1.json"
V4_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-v4.sh"
V4_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-v4"
V4_PREFLIGHT_STATUS="$V4_LOG_ROOT/preflight.status"
V4_BUILD_COUNT="$V4_LOG_ROOT/build.count"
V4_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-v4"

GRAPH_ROOT="$NPU_ROOT/tmp/logs/qwen-graph-manifest-v5"
RAW_GRAPH="$GRAPH_ROOT/dispatch.raw.jsonl"
FROZEN_JSON="$GRAPH_ROOT/dispatch.manifest.json"
FROZEN_JSONL="$GRAPH_ROOT/dispatch.manifest.jsonl"
GRAPH_RECEIPT="$GRAPH_ROOT/final.receipt"
GRAPH_BINDING="$GRAPH_ROOT/final.binding.sha256"
GRAPH_BINDING_CHECK="$GRAPH_ROOT/final-binding.check"
GRAPH_RUN_STATUS="$GRAPH_ROOT/run.status"
GRAPH_TOOL="$NPU_ROOT/scripts/qwen_graph_manifest.py"
GRAPH_TEST="$NPU_ROOT/tests/test_qwen_graph_manifest.py"

PROFILE_TOOL="$NPU_ROOT/scripts/qwen_f32_alu_profiles.py"
PROFILE_TEST="$NPU_ROOT/tests/test_qwen_f32_alu_profiles.py"
PREDECESSOR_RECEIPT="$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v11/final.receipt.json"
PREDECESSOR_RECEIPT_HASH="$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v11/final.receipt.sha256"
PREDECESSOR_STATUS="$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v11/run.status"
PREDECESSOR_BUILD_COUNT="$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v11/build.count"

PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
BUILD_COUNT="$LOG_ROOT/build.count"
TASK_STATUS_LOG="$LOG_ROOT/task-run-status-test.log"
GRAPH_TEST_LOG="$LOG_ROOT/graph-validator-test.log"
VALIDATOR_LOG="$LOG_ROOT/graph-validator.log"
PROFILE_LOG="$LOG_ROOT/profile-audit.log"
PROFILE_TEST_LOG="$LOG_ROOT/profile-test.log"
FRESH_JSON="$COMPILER_ROOT/dispatch.manifest.fresh.json"
FRESH_JSONL="$COMPILER_ROOT/dispatch.manifest.fresh.jsonl"
FRESH_AUDIT="$COMPILER_ROOT/fresh-manifest-audit.json"
PROFILE_CENSUS="$COMPILER_ROOT/profile-census.json"
PROFILE_MUTATIONS="$COMPILER_ROOT/profile-mutations.json"
PROVENANCE_AUDIT="$COMPILER_ROOT/provenance-audit.json"
STATIC_AUDIT="$COMPILER_ROOT/static-source-audit.json"
SOURCE_IDENTITY="$COMPILER_ROOT/source-identity.json"
PROCESS_AUDIT="$COMPILER_ROOT/preflight-active-process-audit.json"
RUNNER_PROBE_AUDIT="$COMPILER_ROOT/runner-probe-audit.json"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"

CONTRACT_SHA256="402293dc9424124190bbfd87f6556222f071c05fc8bea7bf334afbfe8a75b054"
V3_CONTRACT_SHA256="3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2"
V3_MATERIAL_SHA256="9a801f79f2874160e4a6747f78694d3c4526645388f78bac68f43ac7a9782a40"
V4_CONTRACT_SHA256="ca00a021c6c1e17fdd7774990c07f2672b68600c5ce47d0c5a7f3afc91d69bc0"
V4_MATERIAL_SHA256="1f01810db39a1040482afcbc3ffa24bca9725feecbf3c3330d48121419f46fca"
V5_MATERIAL_SHA256="4a4d5201da1d5e00dd2b069c65a2d590f3aaf8358f31e73e93cd9218d91d6865"
STATIC_REVIEW_CONTRACT_SHA256="857c9bb881b3f1027330bae754c1139ca4d74a7b3419c7cc48e24ec4b1e7d430"
V4_RUNNER_SHA256="fd7c9a832fca7bfe12689f8dedc250d52227a1ffa5704aacb644cab301c74772"
V4_PREFLIGHT_STATUS_SHA256="8e972f9db5eec10d336d140f28d28aed44f1c2b50b83c4c84aafd55650e3fa4a"
V4_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
OWNER_CONTRACT_SHA256="1f1cd0a4971826f2ddcf939bd3f796c5986088bb66eac107e4937d396e14e376"
TOP_RTL_SHA256="2b61186f99039e0f0b05f5875210c3f43092f637e351c3ca12e98cb8a2c5565e"
ADAPTER_RTL_SHA256="3de215650ff39f6649b21e37864cfce102ba6de824cccdbb8be2b124b6246cff"
F32_ALU_RTL_SHA256="641476144342ca5fbe3e3ea220ae97e50790920b14d6b40fc34f33e38fa33577"
CMAKE_SHA256="7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f"
AUDIT_API_SHA256="a23121a913ad829d6537bd86c468531a55ccbb6e7f04b1b2221aac483b7c5265"
RUNNER_HEADER_SHA256="ad631b0562844a7b7a10a38ee47a48d0b703208af2f5ca68db751f1ced7adadf"
RUNNER_SOURCE_SHA256="f7bb26c91d97a3cc42c63cb52e4ce8c6f4f740a4304f27221f2b3c863a74878f"
BACKEND_SHA256="66fae6ae4076ff99ad7e7a8ce87ac47a6191643b47a468b10556fa36c8372cb2"
BACKEND_TEST_SHA256="867bda5defbed4cf8fd97118b847bdb79a74c1cfe282d2b97717dbd0c9b64027"
PROFILE_TOOL_SHA256="1226da435fd7b5dc955c0ef2fa24a337fe32b05fb893d9d2eab62cc6083628fa"
PROFILE_TEST_SHA256="ca74dd499692fecd79a87eab47aab2a6dd7ac3fce11bfdf4b285ef5cfa62567a"
RAW_SHA256="5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635"
MANIFEST_SHA256="49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474"
FROZEN_JSON_SHA256="f10572d03342295bfb54a9c88e33788de0a8cb400c69ace3cfb275031299d804"
FROZEN_JSONL_SHA256="a8e334b3c84a58721968a6b18cf21033eb91c51d682c9acb3992d1b43cd94610"
IDENTITY_SET_SHA256="d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385"
MODEL_SHA256="37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"
SOURCE_COMMIT="95c409c13625a23da2aa37270339ce9179215a18"
GRAPH_PROFILE="qwen35-0.8b-b1t1-unfused-nonflash-v5"
NUMERIC_PROFILE="strict-f32-rne-canonical-nan-v1"

SOURCE_FILES_REL=(
    .github/AGENTS.md
    .github/instructions/agent-lightweight-workflow.instructions.md
    .github/instructions/rtl-agent-task-contract.instructions.md
    .github/instructions/rtl-generation-workflow.instructions.md
    scripts/task-run-status.sh
    scripts/tests/test-task-run-status.sh
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v4.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v4-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v5.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v5-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v1.json
    npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
    npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md
    npu/version_0820/rtl/TensorNpuCoprocessor.v
    npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
    npu/version_0820/rtl/TensorNpuF32TensorAlu.v
    npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt
    npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h
    npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h
    npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp
    npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp
    npu/version_0820/runtime/llama-npu-backend/test-backend.cpp
    npu/version_0820/scripts/qwen_graph_manifest.py
    npu/version_0820/tests/test_qwen_graph_manifest.py
    npu/version_0820/scripts/qwen_f32_alu_profiles.py
    npu/version_0820/tests/test_qwen_f32_alu_profiles.py
    npu/version_0820/scripts/run-qwen-f32-alu-families-v4.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v5.sh
)

export PYTHONDONTWRITEBYTECODE=1

# shellcheck source=/dev/null
source "$STATUS_HELPER"

STATUS_INITIALIZED=0
STATUS_FINALIZED=0
FORCED_CLEANUP_RC=0

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-V5][FAIL] $*" >&2
    return 1
}

finish_on_exit() {
    local command_rc=$?
    local status_rc=0
    trap - EXIT HUP INT TERM
    set +e
    if [[ $STATUS_INITIALIZED -eq 1 && $STATUS_FINALIZED -eq 0 ]]; then
        task_run_status_finalize "$command_rc" "$FORCED_CLEANUP_RC"
        status_rc=$?
        if [[ $command_rc -eq 0 ]]; then
            command_rc=$status_rc
        fi
    elif [[ $command_rc -eq 0 && $FORCED_CLEANUP_RC -ne 0 ]]; then
        command_rc=$FORCED_CLEANUP_RC
    fi
    exit "$command_rc"
}

install_runner_traps() {
    trap finish_on_exit EXIT
    task_run_status_install_signal_traps
}

finalize_success() {
    local status_rc=0
    task_run_status_mark_evidence_complete
    set +e
    task_run_status_finalize 0 0
    status_rc=$?
    set -e
    STATUS_FINALIZED=1
    return "$status_rc"
}

run_internal_probe() {
    local kind="$1"
    local status="$2"
    task_run_status_init "$status"
    STATUS_INITIALIZED=1
    install_runner_traps
    case "$kind" in
        early-exit)
            task_run_status_stage "probe-early-exit"
            return 0
            ;;
        hup-signal)
            task_run_status_stage "probe-hup-signal"
            kill -s HUP "$BASHPID"
            ;;
        int-signal)
            task_run_status_stage "probe-int-signal"
            kill -s INT "$BASHPID"
            ;;
        term-signal)
            task_run_status_stage "probe-term-signal"
            kill -s TERM "$BASHPID"
            ;;
        cleanup-failure)
            task_run_status_stage "probe-cleanup-failure"
            task_run_status_mark_evidence_complete
            FORCED_CLEANUP_RC=9
            return 0
            ;;
        *)
            return 2
            ;;
    esac
}

if (( $# >= 1 )) && [[ "$1" == "--internal-probe" ]]; then
    [[ $# -eq 3 ]] || exit 2
    run_internal_probe "$2" "$3"
    exit 0
fi

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--execute" ]]; then
    printf '%s\n' "usage: bash $RUNNER_REL --preflight|--execute" >&2
    exit 2
fi

if [[ "$1" == "--execute" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V5][GAP] execute requires a later explicit shell-ownership authorization" >&2
    exit 2
fi

require_file() {
    [[ -f "$1" ]] || fail "missing file=$1"
}

file_sha() {
    local digest
    digest=$(sha256sum "$1")
    printf '%s\n' "${digest%% *}"
}

require_exact_hash() {
    local expected="$1"
    local path="$2"
    require_file "$path"
    [[ "$(file_sha "$path")" == "$expected" ]] ||
        fail "sha256 mismatch=$path"
}

run_one_probe() {
    local kind="$1"
    local status="$COMPILER_ROOT/runner-probe-$kind.status"
    local log="$COMPILER_ROOT/runner-probe-$kind.log"
    local rc_path="$COMPILER_ROOT/runner-probe-$kind.rc"
    local probe_rc=0
    set +e
    bash "$RUNNER" --internal-probe "$kind" "$status" >"$log" 2>&1
    probe_rc=$?
    set -e
    [[ $probe_rc -ne 0 ]] || fail "runner probe unexpectedly passed=$kind"
    printf '%s\n' "$probe_rc" >"$rc_path"
}

run_runner_probes() {
    local kind
    for kind in early-exit hup-signal int-signal term-signal cleanup-failure; do
        run_one_probe "$kind"
    done
    python3 - "$COMPILER_ROOT" "$RUNNER_PROBE_AUDIT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
expected = {
    "early-exit": ("evidence_complete=0", None),
    "hup-signal": ("signal=HUP", None),
    "int-signal": ("signal=INT", None),
    "term-signal": ("signal=TERM", None),
    "cleanup-failure": ("cleanup_rc=9", 9),
}
records = {}
for name, (marker, expected_rc) in expected.items():
    status = (root / f"runner-probe-{name}.status").read_text().strip()
    rc = int((root / f"runner-probe-{name}.rc").read_text())
    if not status.startswith("FAIL ") or marker not in status or rc == 0:
        raise SystemExit(f"runner probe did not fail closed: {name}: {status}: rc={rc}")
    if expected_rc is not None and rc != expected_rc:
        raise SystemExit(f"runner probe rc mismatch: {name}: {rc}")
    records[name] = {"return_code": rc, "status": status}
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-runner-probes-v1",
    "pass": True,
    "records": records,
}, sort_keys=True, indent=2) + "\n")
PY
}

write_provenance_audit() {
    python3 - \
        "$PREDECESSOR_RECEIPT" "$PREDECESSOR_RECEIPT_HASH" \
        "$PREDECESSOR_STATUS" "$PREDECESSOR_BUILD_COUNT" \
        "$GRAPH_RECEIPT" "$GRAPH_BINDING" "$GRAPH_BINDING_CHECK" \
        "$GRAPH_RUN_STATUS" "$RAW_GRAPH" "$FROZEN_JSON" "$FROZEN_JSONL" \
        "$V4_RUNNER" "$V4_PREFLIGHT_STATUS" "$V4_BUILD_COUNT" \
        "$V4_BUILD_ROOT" \
        "$PROVENANCE_AUDIT" <<'PY'
import hashlib
import json
import pathlib
import sys

(
    predecessor_receipt, predecessor_hash, predecessor_status,
    predecessor_build_count, graph_receipt, graph_binding,
    graph_binding_check, graph_status, raw_graph, frozen_json,
    frozen_jsonl, v4_runner, v4_status, v4_build_count, v4_build_root,
    output,
) = map(pathlib.Path, sys.argv[1:])

v4_expected = {
    v4_runner: "fd7c9a832fca7bfe12689f8dedc250d52227a1ffa5704aacb644cab301c74772",
    v4_status: "8e972f9db5eec10d336d140f28d28aed44f1c2b50b83c4c84aafd55650e3fa4a",
    v4_build_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
}
for path, expected in v4_expected.items():
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"v4 predecessor hash mismatch: {path}")
expected_v4_status = (
    "FAIL rc=1 stage=source-topology-audit "
    "evidence_complete=0 cleanup_rc=0\n"
)
if (v4_status.read_text() != expected_v4_status or
        v4_build_count.read_text() != "0\n" or v4_build_root.exists()):
    raise SystemExit("v4 rc1/build0 predecessor boundary mismatch")

expected_receipt_hash = predecessor_hash.read_text().split()[0]
actual_receipt_hash = hashlib.sha256(predecessor_receipt.read_bytes()).hexdigest()
if actual_receipt_hash != expected_receipt_hash:
    raise SystemExit("v11 receipt hash mismatch")
predecessor = json.loads(predecessor_receipt.read_text())
positive = predecessor.get("positive", {})
if (predecessor.get("task_id") != "qwen-f32-add-owner-v11" or
        predecessor.get("build_count") != 1 or
        positive.get("completion_identity_match") != 1 or
        predecessor_status.read_text() != "PASS\n" or
        predecessor_build_count.read_text() != "1\n"):
    raise SystemExit("v11 representative predecessor mismatch")

receipt_text = graph_receipt.read_text()
receipt_markers = (
    "nodes=1711", "compute=959", "mover=120", "metadata=632",
    "raw_sha256=5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635",
    "manifest_sha256=49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474",
    "compute_started=0", "evidence_complete=1",
)
if any(marker not in receipt_text for marker in receipt_markers):
    raise SystemExit("graph final receipt marker mismatch")
if graph_status.read_text() != "PASS\n":
    raise SystemExit("graph run status mismatch")

binding = {}
for line in graph_binding.read_text().splitlines():
    digest, path = line.split(maxsplit=1)
    binding[pathlib.Path(path).name] = digest
expected_files = {
    raw_graph: "5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635",
    frozen_json: "f10572d03342295bfb54a9c88e33788de0a8cb400c69ace3cfb275031299d804",
    frozen_jsonl: "a8e334b3c84a58721968a6b18cf21033eb91c51d682c9acb3992d1b43cd94610",
    graph_receipt: hashlib.sha256(graph_receipt.read_bytes()).hexdigest(),
}
for path, expected in expected_files.items():
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected or binding.get(path.name) != expected:
        raise SystemExit(f"graph binding mismatch: {path}")
check_lines = [line for line in graph_binding_check.read_text().splitlines() if line]
if not check_lines or any(not line.endswith(": OK") for line in check_lines):
    raise SystemExit("graph final-binding historical check mismatch")

output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-provenance-v1",
    "predecessor_task": "qwen-f32-add-owner-v11",
    "predecessor_representative_transactions_passed": 1,
    "v4_predecessor": {
        "task_id": "qwen-f32-alu-families-v4",
        "runner_sha256": v4_expected[v4_runner],
        "preflight_status_sha256": v4_expected[v4_status],
        "preflight_return_code": 1,
        "failed_stage": "source-topology-audit",
        "evidence_complete": 0,
        "build_count_sha256": v4_expected[v4_build_count],
        "build_count": 0,
        "build_root_absent": True,
    },
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "graph_final_receipt_sha256": hashlib.sha256(graph_receipt.read_bytes()).hexdigest(),
    "graph_final_binding_sha256": hashlib.sha256(graph_binding.read_bytes()).hexdigest(),
    "raw_sha256": expected_files[raw_graph],
    "frozen_json_sha256": expected_files[frozen_json],
    "frozen_jsonl_sha256": expected_files[frozen_jsonl],
}, sort_keys=True, indent=2) + "\n")
PY
}

write_fresh_audit() {
    python3 - "$FRESH_JSON" "$FRESH_JSONL" "$FROZEN_JSON" \
        "$FROZEN_JSONL" "$FRESH_AUDIT" <<'PY'
import hashlib
import json
import pathlib
import sys

fresh_json, fresh_jsonl, frozen_json, frozen_jsonl, output = map(
    pathlib.Path, sys.argv[1:]
)
expected = {
    fresh_json: "f10572d03342295bfb54a9c88e33788de0a8cb400c69ace3cfb275031299d804",
    fresh_jsonl: "a8e334b3c84a58721968a6b18cf21033eb91c51d682c9acb3992d1b43cd94610",
}
for path, digest in expected.items():
    if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        raise SystemExit(f"fresh canonical file hash mismatch: {path}")
if fresh_json.read_bytes() != frozen_json.read_bytes():
    raise SystemExit("fresh/frozen canonical JSON byte mismatch")
if fresh_jsonl.read_bytes() != frozen_jsonl.read_bytes():
    raise SystemExit("fresh/frozen canonical JSONL byte mismatch")
envelope = json.loads(fresh_json.read_text())
if (envelope.get("manifest_sha256") !=
        "49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474" or
        envelope.get("manifest", {}).get("raw_sha256") !=
        "5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635"):
    raise SystemExit("fresh canonical payload identity mismatch")
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-fresh-manifest-v1",
    "raw_sha256": envelope["manifest"]["raw_sha256"],
    "manifest_payload_sha256": envelope["manifest_sha256"],
    "fresh_json_sha256": expected[fresh_json],
    "fresh_jsonl_sha256": expected[fresh_jsonl],
    "frozen_byte_match": True,
}, sort_keys=True, indent=2) + "\n")
PY
}

write_static_audit() {
    python3 - "$NPU_ROOT" "$STATIC_AUDIT" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
top = (root / "rtl/TensorNpuCoprocessor.v").read_text()
adapter = (root / "rtl/TensorNpuVectorF32Adapter.v").read_text()
runner = (root / "runtime/llama-npu-backend/npu-verilator-runner.cpp").read_text()
runner_h = (root / "runtime/llama-npu-backend/npu-verilator-runner.h").read_text()
audit_h = (root / "runtime/llama-npu-backend/npu-audit-api.h").read_text()
backend = (root / "runtime/llama-npu-backend/ggml-npu.cpp").read_text()
test = (root / "runtime/llama-npu-backend/test-backend.cpp").read_text()
profile = (root / "scripts/qwen_f32_alu_profiles.py").read_text()
profile_test = (root / "tests/test_qwen_f32_alu_profiles.py").read_text()
execute_slice = backend[
    backend.index("static bool npu_execute_exact_f32_alu"):
    backend.index('extern "C" bool ggml_backend_npu_audit_begin_v1')
]


def strip_verilog_comments(text):
    """Remove // and /* */ comments without joining surrounding tokens."""
    output_chars = []
    index = 0
    state = "code"
    while index < len(text):
        char = text[index]
        next_char = text[index + 1] if index + 1 < len(text) else ""
        if state == "code":
            if char == "/" and next_char == "/":
                output_chars.append(" ")
                state = "line-comment"
                index += 2
                continue
            if char == "/" and next_char == "*":
                output_chars.append(" ")
                state = "block-comment"
                index += 2
                continue
            output_chars.append(char)
            if char == '"':
                state = "string"
            index += 1
            continue
        if state == "line-comment":
            if char == "\n":
                output_chars.append("\n")
                state = "code"
            index += 1
            continue
        if state == "block-comment":
            if char == "*" and next_char == "/":
                output_chars.append(" ")
                state = "code"
                index += 2
                continue
            if char == "\n":
                output_chars.append("\n")
            index += 1
            continue
        output_chars.append(char)
        if char == "\\" and index + 1 < len(text):
            output_chars.append(text[index + 1])
            index += 2
            continue
        if char == '"':
            state = "code"
        index += 1
    if state in {"block-comment", "string"}:
        raise ValueError(f"unterminated Verilog lexical state: {state}")
    return "".join(output_chars)


def audit_adapter_source(text):
    code = strip_verilog_comments(text)
    declaration_specs = {
        "representative": ("COMMAND_FLAGS_REPRESENTATIVE", "00000010"),
        "canonical": ("COMMAND_FLAGS_CANONICAL", "00000011"),
    }
    declaration_counts = {}
    named_declaration_counts = {}
    parser_checks = {}
    for label, (name, value) in declaration_specs.items():
        declaration = re.compile(
            rf"(?m)^[ \t]*localparam[ \t]+\[[ \t]*31[ \t]*:[ \t]*0[ \t]*\]"
            rf"[ \t]+{re.escape(name)}[ \t]*=[ \t]*32'[hH]{value}"
            rf"[ \t]*;[ \t]*$"
        )
        declaration_counts[label] = len(declaration.findall(code))
        named_declaration = re.compile(
            rf"(?m)^[ \t]*localparam[ \t]+\[[ \t]*31[ \t]*:[ \t]*0[ \t]*\]"
            rf"[ \t]+{re.escape(name)}[ \t]*=[^;\n]+;[ \t]*$"
        )
        named_declaration_counts[label] = len(named_declaration.findall(code))
        parser_checks[f"{label}_declaration_exactly_once"] = (
            declaration_counts[label] == 1
        )
        parser_checks[f"{label}_name_has_no_extra_declaration"] = (
            named_declaration_counts[label] == 1
        )

    admission_pattern = re.compile(
        r"(?ms)^[ \t]*assign[ \t]+capability_reject_w[ \t]*=[ \t]*"
        r"(.*?);[ \t]*(?:\n|$)"
    )
    admission_matches = list(admission_pattern.finditer(code))
    admission_expression = (
        admission_matches[0].group(1) if len(admission_matches) == 1 else ""
    )
    command_flag_uses = re.findall(
        r"\bcommand_flags_q[ \t]*!=[ \t]*"
        r"([A-Za-z_][A-Za-z0-9_]*|[0-9]+'[hHdD][0-9A-Fa-f_xXzZ]+)",
        admission_expression,
    )
    exact_pair = re.compile(
        r"\(\s*\(\s*command_flags_q\s*!=\s*"
        r"COMMAND_FLAGS_REPRESENTATIVE\s*\)\s*&&\s*"
        r"\(\s*command_flags_q\s*!=\s*"
        r"COMMAND_FLAGS_CANONICAL\s*\)\s*\)"
    )
    pair_count = len(exact_pair.findall(admission_expression))
    parser_checks["capability_admission_statement_exactly_once"] = (
        len(admission_matches) == 1
    )
    parser_checks["capability_admission_exact_named_pair_once"] = pair_count == 1
    parser_checks["capability_admission_use_sequence_exact"] = (
        command_flag_uses == [
            "COMMAND_FLAGS_REPRESENTATIVE",
            "COMMAND_FLAGS_CANONICAL",
        ]
    )
    failures = sorted(
        name for name, passed in parser_checks.items() if not passed
    )
    return {
        "pass": not failures,
        "checks": parser_checks,
        "declaration_counts": declaration_counts,
        "named_declaration_counts": named_declaration_counts,
        "admission_statement_count": len(admission_matches),
        "admission_exact_pair_count": pair_count,
        "admission_command_flag_uses": command_flag_uses,
        "failures": failures,
    }


representative_decl = (
    "    localparam [31:0] COMMAND_FLAGS_REPRESENTATIVE = 32'h00000010;"
)
canonical_decl = (
    "    localparam [31:0] COMMAND_FLAGS_CANONICAL      = 32'h00000011;"
)
canonical_use = "         (command_flags_q != COMMAND_FLAGS_CANONICAL)) ||"
for mutation_anchor in (representative_decl, canonical_decl, canonical_use):
    if adapter.count(mutation_anchor) != 1:
        raise SystemExit("adapter mutation anchor mismatch: " + mutation_anchor)

mutants = {
    "missing": adapter.replace(canonical_decl + "\n", "", 1),
    "duplicate": adapter.replace(
        representative_decl,
        representative_decl + "\n" + representative_decl,
        1,
    ),
    "wrong_value": adapter.replace(
        canonical_decl,
        canonical_decl.replace("00000011", "00000012"),
        1,
    ),
    "renamed_use": adapter.replace(
        canonical_use,
        canonical_use.replace(
            "COMMAND_FLAGS_CANONICAL", "COMMAND_FLAGS_CANONICAL_RENAMED"
        ),
        1,
    ),
    "class_collision": adapter.replace(
        canonical_decl,
        canonical_decl.replace("00000011", "00000010"),
        1,
    ),
    "comment_only": adapter.replace(
        canonical_decl,
        "    // localparam [31:0] COMMAND_FLAGS_CANONICAL = 32'h00000011;",
        1,
    ).replace(
        canonical_use,
        canonical_use.replace(
            "COMMAND_FLAGS_CANONICAL", "COMMAND_FLAGS_CANONICAL_RENAMED"
        ) + "\n    // (command_flags_q != COMMAND_FLAGS_CANONICAL)) ||",
        1,
    ),
}
adapter_audit = audit_adapter_source(adapter)
if not adapter_audit["pass"]:
    raise SystemExit(
        "static source audit failed: adapter exact parser: "
        + ",".join(adapter_audit["failures"])
    )
mutation_results = {}
for name, mutant in mutants.items():
    result = audit_adapter_source(mutant)
    if result["pass"]:
        raise SystemExit("adapter source mutation unexpectedly accepted: " + name)
    mutation_results[name] = {
        "rejected": True,
        "failed_checks": result["failures"],
    }

checks = {
    "rtl_profile_output_port": "completion_macro_vector_flags_o" in top,
    "rtl_profile_resident_source": (
        "assign completion_macro_vector_flags_o = macro_completion_active_w ?" in top and
        "macro_vector_flags_q : 32'd0;" in top
    ),
    "adapter_exact_parser": adapter_audit["pass"],
    "adapter_six_mutations_rejected": (
        len(mutation_results) == 6 and
        all(item["rejected"] for item in mutation_results.values())
    ),
    "completion_record_128": (
        "kCompletionSize = 128" in runner and
        "completion v1/v4 framing must remain exactly 128 bytes" in runner
    ),
    "completion_minor_compatibility": (
        "kCompletionAbiMinorV1 = 0" in runner and
        "kRepresentativeCompletionAbiMinor = 1" in runner and
        "serialize_representative_completion" in runner
    ),
    "rtl_observed_profile": (
        "snapshot.vector_flags = top.completion_macro_vector_flags_o" in runner and
        "result_->observed_profile_id = snapshot.vector_flags" in runner
    ),
    "completion_events_split": (
        "result_->completion_emitted = true" in runner and
        "result_->completion_accepted = true" in runner and
        "result_->private_shadow_committed = true" in runner
    ),
    "required_counter_delta": (
        "top_->npu_required_issued_o - required_issued_before_" in runner and
        "top_->npu_required_completed_o - required_completed_before_" in runner
    ),
    "representative_identity_api": (
        "npu_f32_alu_representative_identity_by_profile" in runner and
        "npu_f32_alu_representative_identity_by_profile" in runner_h
    ),
    "five_stage_masks": all(name in audit_h for name in (
        "command_accepted_mask", "completion_emitted_mask",
        "completion_accepted_mask", "raw_dst_committed_mask",
        "representative_covered_mask",
    )),
    "raw_commit_unique_memcpy": execute_slice.count(
        "std::memcpy(node->data, private_shadow.data(), private_shadow.size());"
    ) == 1,
    "raw_commit_after_accepted": (
        execute_slice.index("npu_prepare_raw_publication") <
        execute_slice.index("std::memcpy(node->data") <
        execute_slice.rindex("representative_stage::raw_dst_committed") <
        execute_slice.rindex("representative_stage::representative_covered")
    ),
    "representative_canonical_split": (
        "predecessor_representative_transactions_passed = 1" in backend and
        "verified_canonical_completed = 0" in backend and
        "verified_canonical_remaining = 1079" in backend
    ),
    "stage_mutation_validator": all(name in test for name in (
        "duplicate replay mutation was accepted",
        "wrong-profile mutation was accepted",
        "missing identity mutation was accepted",
        "extra identity mutation was accepted",
        "identity substitution mutation was accepted",
        "reordered-profile collision was accepted",
    )),
    "fixed_identity_set_digest": (
        "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385" in profile
    ),
    "canonical_mutation_count_19": (
        'result["rejected_mutation_count"], 19' in profile_test
    ),
}
if not all(checks.values()):
    failed = sorted(name for name, passed in checks.items() if not passed)
    raise SystemExit("static source audit failed: " + ",".join(failed))
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-static-source-audit-v1",
    "checks": checks,
    "adapter_source_parser": adapter_audit,
    "adapter_source_mutations": {
        "expected_mutation_count": 6,
        "rejected_mutation_count": len(mutation_results),
        "results": mutation_results,
    },
    "completion_record_bytes": 128,
    "generic_completion_minor": 0,
    "representative_completion_minor": 1,
    "representative_command_flags": "0x00000010",
    "canonical_command_flags": "0x00000011",
    "deadline_edge_dynamic_status": "GAP",
    "verilator_make_binary_execute_count": 0,
}, sort_keys=True, indent=2) + "\n")
PY
}

write_source_identity() {
    python3 - "$REPO_ROOT" "$SOURCE_IDENTITY" "${SOURCE_FILES_REL[@]}" <<'PY'
import hashlib
import json
import pathlib
import platform
import sys

root = pathlib.Path(sys.argv[1]).resolve()
output = pathlib.Path(sys.argv[2])
files = {}
for relative in sys.argv[3:]:
    path = root / relative
    if not path.is_file():
        raise SystemExit("source identity missing: " + relative)
    files[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-source-identity-v1",
    "files": files,
    "python": platform.python_version(),
}, sort_keys=True, indent=2) + "\n")
PY
}

write_process_audit() {
    python3 - "$TASK_ID" "$BUILD_ROOT" "$PROCESS_AUDIT" <<'PY'
import json
import os
import pathlib
import sys

task_id = sys.argv[1]
build_root = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
excluded = set()
pid = os.getpid()
while pid > 0 and pid not in excluded:
    excluded.add(pid)
    try:
        fields = pathlib.Path(f"/proc/{pid}/stat").read_text().split()
        pid = int(fields[3])
    except (OSError, ValueError, IndexError):
        break
matches = []
for entry in pathlib.Path("/proc").iterdir():
    if not entry.name.isdigit() or int(entry.name) in excluded:
        continue
    try:
        command = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(
            "utf-8", errors="replace"
        ).strip()
    except OSError:
        continue
    if task_id in command:
        matches.append({"pid": int(entry.name), "command": command})
if matches or build_root.exists():
    raise SystemExit("owned process/build residue detected")
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v5-active-process-v1",
    "owned_background_jobs": 0,
    "matches": matches,
    "build_root_absent": True,
}, sort_keys=True, indent=2) + "\n")
PY
}

write_receipt() {
    local artifacts=(
        "$CONTRACT" "$MATERIAL" "$OWNER_CONTRACT" "$RUNNER"
        "$V3_CONTRACT" "$V3_MATERIAL" "$V4_CONTRACT" "$V4_MATERIAL"
        "$STATIC_REVIEW_CONTRACT" "$V4_RUNNER" "$V4_PREFLIGHT_STATUS"
        "$V4_BUILD_COUNT"
        "$RAW_GRAPH" "$FROZEN_JSON" "$FROZEN_JSONL"
        "$GRAPH_RECEIPT" "$GRAPH_BINDING" "$GRAPH_BINDING_CHECK"
        "$GRAPH_RUN_STATUS" "$GRAPH_TOOL" "$GRAPH_TEST"
        "$FRESH_JSON" "$FRESH_JSONL" "$FRESH_AUDIT"
        "$VALIDATOR_LOG" "$GRAPH_TEST_LOG"
        "$PROFILE_TOOL" "$PROFILE_TEST" "$PROFILE_CENSUS"
        "$PROFILE_MUTATIONS" "$PROFILE_LOG" "$PROFILE_TEST_LOG"
        "$PROVENANCE_AUDIT" "$STATIC_AUDIT" "$SOURCE_IDENTITY"
        "$PROCESS_AUDIT" "$RUNNER_PROBE_AUDIT" "$TASK_STATUS_LOG"
        "$BUILD_COUNT"
    )
    local kind relative
    for relative in "${SOURCE_FILES_REL[@]}"; do
        artifacts+=("$REPO_ROOT/$relative")
    done
    for kind in early-exit hup-signal int-signal term-signal cleanup-failure; do
        artifacts+=(
            "$COMPILER_ROOT/runner-probe-$kind.status"
            "$COMPILER_ROOT/runner-probe-$kind.rc"
            "$COMPILER_ROOT/runner-probe-$kind.log"
        )
    done
    python3 - "$REPO_ROOT" "$BUILD_ROOT" "$BUILD_COUNT" \
        "$PREFLIGHT_RECEIPT" "${artifacts[@]}" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
build_root = pathlib.Path(sys.argv[2])
build_count = pathlib.Path(sys.argv[3])
output = pathlib.Path(sys.argv[4])
artifacts = [pathlib.Path(item) for item in sys.argv[5:]]
if build_root.exists() or build_count.read_text() != "0\n":
    raise SystemExit("preflight build boundary violated")
for path in artifacts:
    if not path.is_file():
        raise SystemExit("receipt artifact missing: " + str(path))
artifact_hashes = {
    str(path.resolve().relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
    for path in artifacts
}
census = json.loads((root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/profile-census.json").read_text())
mutations = json.loads((root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/profile-mutations.json").read_text())
static_audit = json.loads((root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/static-source-audit.json").read_text())
source_identity = json.loads((root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/source-identity.json").read_text())
provenance = json.loads((root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/provenance-audit.json").read_text())
if (census.get("canonical_identity_set_sha256") !=
        "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385" or
        census.get("eligible_identity_count") != 367 or
        mutations.get("rejected_mutation_count") != 19 or
        mutations.get("representative_stage_mutations", {}).get(
            "rejected_mutation_count") != 7):
    raise SystemExit("receipt census/mutation boundary mismatch")
adapter_parser = static_audit.get("adapter_source_parser", {})
adapter_mutations = static_audit.get("adapter_source_mutations", {})
adapter_mutation_results = adapter_mutations.get("results", {})
expected_adapter_mutations = {
    "missing", "duplicate", "wrong_value", "renamed_use",
    "class_collision", "comment_only",
}
if (not all(static_audit.get("checks", {}).values()) or
        adapter_parser.get("pass") is not True or
        adapter_mutations.get("expected_mutation_count") != 6 or
        adapter_mutations.get("rejected_mutation_count") != 6 or
        set(adapter_mutation_results) != expected_adapter_mutations or
        any(item.get("rejected") is not True
            for item in adapter_mutation_results.values())):
    raise SystemExit("receipt adapter source parser/mutation boundary mismatch")
v4_predecessor = provenance.get("v4_predecessor", {})
if (v4_predecessor.get("preflight_return_code") != 1 or
        v4_predecessor.get("failed_stage") != "source-topology-audit" or
        v4_predecessor.get("evidence_complete") != 0 or
        v4_predecessor.get("build_count") != 0 or
        v4_predecessor.get("build_root_absent") is not True):
    raise SystemExit("receipt v4 rc1/build0 provenance mismatch")
fixed_sources = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3.json": "3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3-material.md": "9a801f79f2874160e4a6747f78694d3c4526645388f78bac68f43ac7a9782a40",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v4.json": "ca00a021c6c1e17fdd7774990c07f2672b68600c5ce47d0c5a7f3afc91d69bc0",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v4-material.md": "1f01810db39a1040482afcbc3ffa24bca9725feecbf3c3330d48121419f46fca",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v5.json": "402293dc9424124190bbfd87f6556222f071c05fc8bea7bf334afbfe8a75b054",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v5-material.md": "4a4d5201da1d5e00dd2b069c65a2d590f3aaf8358f31e73e93cd9218d91d6865",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v1.json": "857c9bb881b3f1027330bae754c1139ca4d74a7b3419c7cc48e24ec4b1e7d430",
    "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md": "1f1cd0a4971826f2ddcf939bd3f796c5986088bb66eac107e4937d396e14e376",
    "npu/version_0820/rtl/TensorNpuCoprocessor.v": "2b61186f99039e0f0b05f5875210c3f43092f637e351c3ca12e98cb8a2c5565e",
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v": "3de215650ff39f6649b21e37864cfce102ba6de824cccdbb8be2b124b6246cff",
    "npu/version_0820/rtl/TensorNpuF32TensorAlu.v": "641476144342ca5fbe3e3ea220ae97e50790920b14d6b40fc34f33e38fa33577",
    "npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt": "7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f",
    "npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h": "a23121a913ad829d6537bd86c468531a55ccbb6e7f04b1b2221aac483b7c5265",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h": "ad631b0562844a7b7a10a38ee47a48d0b703208af2f5ca68db751f1ced7adadf",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp": "f7bb26c91d97a3cc42c63cb52e4ce8c6f4f740a4304f27221f2b3c863a74878f",
    "npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp": "66fae6ae4076ff99ad7e7a8ce87ac47a6191643b47a468b10556fa36c8372cb2",
    "npu/version_0820/runtime/llama-npu-backend/test-backend.cpp": "867bda5defbed4cf8fd97118b847bdb79a74c1cfe282d2b97717dbd0c9b64027",
    "npu/version_0820/scripts/qwen_f32_alu_profiles.py": "1226da435fd7b5dc955c0ef2fa24a337fe32b05fb893d9d2eab62cc6083628fa",
    "npu/version_0820/tests/test_qwen_f32_alu_profiles.py": "ca74dd499692fecd79a87eab47aab2a6dd7ac3fce11bfdf4b285ef5cfa62567a",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v4.sh": "fd7c9a832fca7bfe12689f8dedc250d52227a1ffa5704aacb644cab301c74772",
}
identity_files = source_identity.get("files", {})
for relative, expected in fixed_sources.items():
    if (identity_files.get(relative) != expected or
            artifact_hashes.get(relative) != expected):
        raise SystemExit("receipt frozen source mismatch: " + relative)
for relative, digest in identity_files.items():
    if artifact_hashes.get(relative) != digest:
        raise SystemExit("receipt source identity/artifact mismatch: " + relative)
payload = {
    "schema": "qwen-f32-alu-families-v5-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-v5",
    "contract_sha256": "402293dc9424124190bbfd87f6556222f071c05fc8bea7bf334afbfe8a75b054",
    "artifacts": artifact_hashes,
    "frozen_source_sha256": fixed_sources,
    "v4_predecessor": v4_predecessor,
    "graph": {
        "raw_sha256": "5b7356312f1e97adaa22ce101793588afaa7192a576d46b68ae68d9949890635",
        "manifest_payload_sha256": "49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474",
        "frozen_json_sha256": "f10572d03342295bfb54a9c88e33788de0a8cb400c69ace3cfb275031299d804",
        "fresh_json_sha256": "f10572d03342295bfb54a9c88e33788de0a8cb400c69ace3cfb275031299d804",
        "frozen_jsonl_sha256": "a8e334b3c84a58721968a6b18cf21033eb91c51d682c9acb3992d1b43cd94610",
        "fresh_jsonl_sha256": "a8e334b3c84a58721968a6b18cf21033eb91c51d682c9acb3992d1b43cd94610",
        "model_sha256": "37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f",
        "source_commit": "95c409c13625a23da2aa37270339ce9179215a18",
        "profile": "qwen35-0.8b-b1t1-unfused-nonflash-v5",
        "numeric_profile": "strict-f32-rne-canonical-nan-v1",
        "counts": {"total": 1711, "compute": 959, "mover": 120, "metadata": 632},
    },
    "canonical_identity_set_sha256": "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385",
    "eligible_f32_alu_canonical_identities": 367,
    "representative_profile_count": 19,
    "representative_exact_profile_mask": "0x7ffff",
    "representative_command_flags": "0x00000010",
    "canonical_command_flags": "0x00000011",
    "completion_record_bytes": 128,
    "generic_completion_minor": 0,
    "representative_completion_minor": 1,
    "predecessor_representative_transactions_passed": 1,
    "representative_transactions_planned": 19,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "canonical_mutation_rejections": 19,
    "representative_stage_mutation_rejections": 7,
    "adapter_source_parser": {
        "anchored_whitespace_tolerant_exact": True,
        "comment_stripped_before_match": True,
        "declaration_counts": adapter_parser["declaration_counts"],
        "named_declaration_counts": adapter_parser[
            "named_declaration_counts"
        ],
        "admission_command_flag_uses": adapter_parser[
            "admission_command_flag_uses"
        ],
        "mutation_rejections": 6,
        "mutation_names": sorted(adapter_mutation_results),
    },
    "build_count": 0,
    "build_root_absent": True,
    "verilator_invocations": 0,
    "make_invocations": 0,
    "binary_invocations": 0,
    "execute_invocations": 0,
    "owned_background_jobs": 0,
    "deadline_edge_dynamic_status": "GAP",
    "rtl_dynamic_status": "GAP",
    "synthesis_sta_ppa_status": "GAP",
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
    sha256sum "$PREFLIGHT_RECEIPT" >"$PREFLIGHT_RECEIPT_HASH"
}

run_preflight() {
    [[ ! -e "$LOG_ROOT" ]] || fail "fresh log root exists=$LOG_ROOT"
    [[ ! -e "$COMPILER_ROOT" ]] || fail "fresh compiler root exists=$COMPILER_ROOT"
    [[ ! -e "$BUILD_ROOT" ]] || fail "fresh build root exists=$BUILD_ROOT"
    mkdir -p -- "$LOG_ROOT" "$COMPILER_ROOT"
    task_run_status_init "$PREFLIGHT_STATUS"
    STATUS_INITIALIZED=1
    install_runner_traps

    task_run_status_stage "input-boundary"
    require_exact_hash "$CONTRACT_SHA256" "$CONTRACT"
    require_exact_hash "$V3_CONTRACT_SHA256" "$V3_CONTRACT"
    require_exact_hash "$V3_MATERIAL_SHA256" "$V3_MATERIAL"
    require_exact_hash "$V4_CONTRACT_SHA256" "$V4_CONTRACT"
    require_exact_hash "$V4_MATERIAL_SHA256" "$V4_MATERIAL"
    require_exact_hash "$V5_MATERIAL_SHA256" "$MATERIAL"
    require_exact_hash "$STATIC_REVIEW_CONTRACT_SHA256" "$STATIC_REVIEW_CONTRACT"
    require_exact_hash "$V4_RUNNER_SHA256" "$V4_RUNNER"
    require_exact_hash "$V4_PREFLIGHT_STATUS_SHA256" "$V4_PREFLIGHT_STATUS"
    require_exact_hash "$V4_BUILD_COUNT_SHA256" "$V4_BUILD_COUNT"
    [[ ! -e "$V4_BUILD_ROOT" ]] || fail "v4 build root unexpectedly exists=$V4_BUILD_ROOT"
    require_exact_hash "$OWNER_CONTRACT_SHA256" "$OWNER_CONTRACT"
    require_exact_hash "$TOP_RTL_SHA256" "$NPU_ROOT/rtl/TensorNpuCoprocessor.v"
    require_exact_hash "$ADAPTER_RTL_SHA256" "$NPU_ROOT/rtl/TensorNpuVectorF32Adapter.v"
    require_exact_hash "$F32_ALU_RTL_SHA256" "$NPU_ROOT/rtl/TensorNpuF32TensorAlu.v"
    require_exact_hash "$CMAKE_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/CMakeLists.txt"
    require_exact_hash "$AUDIT_API_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/npu-audit-api.h"
    require_exact_hash "$RUNNER_HEADER_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/npu-verilator-runner.h"
    require_exact_hash "$RUNNER_SOURCE_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/npu-verilator-runner.cpp"
    require_exact_hash "$BACKEND_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/ggml-npu.cpp"
    require_exact_hash "$BACKEND_TEST_SHA256" "$NPU_ROOT/runtime/llama-npu-backend/test-backend.cpp"
    require_exact_hash "$PROFILE_TOOL_SHA256" "$PROFILE_TOOL"
    require_exact_hash "$PROFILE_TEST_SHA256" "$PROFILE_TEST"
    for path in "$STATUS_HELPER_TEST" \
        "$RAW_GRAPH" "$FROZEN_JSON" "$FROZEN_JSONL" "$GRAPH_RECEIPT" \
        "$GRAPH_BINDING" "$GRAPH_BINDING_CHECK" "$GRAPH_RUN_STATUS" \
        "$GRAPH_TOOL" "$GRAPH_TEST" "$PROFILE_TOOL" "$PROFILE_TEST" \
        "$PREDECESSOR_RECEIPT" "$PREDECESSOR_RECEIPT_HASH" \
        "$PREDECESSOR_STATUS" "$PREDECESSOR_BUILD_COUNT" "$V4_RUNNER" \
        "$V4_PREFLIGHT_STATUS" "$V4_BUILD_COUNT"; do
        require_file "$path"
    done
    require_exact_hash "$RAW_SHA256" "$RAW_GRAPH"
    require_exact_hash "$FROZEN_JSON_SHA256" "$FROZEN_JSON"
    require_exact_hash "$FROZEN_JSONL_SHA256" "$FROZEN_JSONL"
    printf '0\n' >"$BUILD_COUNT"

    task_run_status_stage "task-status-helper"
    bash "$STATUS_HELPER_TEST" >"$TASK_STATUS_LOG" 2>&1
    [[ "$(sed -n '1p' "$TASK_STATUS_LOG")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper marker mismatch"

    task_run_status_stage "runner-fail-closed-probes"
    run_runner_probes

    task_run_status_stage "graph-provenance"
    write_provenance_audit

    task_run_status_stage "graph-validator-unit"
    python3 "$GRAPH_TEST" >"$GRAPH_TEST_LOG" 2>&1

    task_run_status_stage "raw-to-fresh-canonical"
    python3 "$GRAPH_TOOL" validate "$RAW_GRAPH" \
        --json-out "$FRESH_JSON" \
        --jsonl-out "$FRESH_JSONL" \
        --expect-raw-sha256 "$RAW_SHA256" \
        --expect-manifest-sha256 "$MANIFEST_SHA256" \
        --expect-model-sha256 "$MODEL_SHA256" \
        --expect-source-commit "$SOURCE_COMMIT" \
        --expect-profile "$GRAPH_PROFILE" \
        --expect-numeric-profile "$NUMERIC_PROFILE" \
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
        >"$VALIDATOR_LOG" 2>&1
    write_fresh_audit

    task_run_status_stage "profile-canonical-audit"
    python3 "$PROFILE_TOOL" \
        --manifest "$FRESH_JSON" \
        --output "$PROFILE_CENSUS" \
        --mutation-output "$PROFILE_MUTATIONS" \
        --self-test >"$PROFILE_LOG" 2>&1
    python3 "$PROFILE_TEST" --manifest "$FRESH_JSON" \
        >"$PROFILE_TEST_LOG" 2>&1

    task_run_status_stage "source-topology-audit"
    write_static_audit
    write_source_identity

    task_run_status_stage "process-build-boundary"
    [[ "$(<"$BUILD_COUNT")" == "0" ]] || fail "build count changed"
    [[ ! -e "$BUILD_ROOT" ]] || fail "build root was created"
    write_process_audit

    task_run_status_stage "preflight-receipt"
    write_receipt
    local receipt_sha
    receipt_sha=$(file_sha "$PREFLIGHT_RECEIPT")
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V5][PREFLIGHT-PASS] build_count=0 build_root_absent=1 verilator=0 make=0 binary=0 execute=0 profiles=19 stage_mask=0x7ffff representative_predecessor_passed=1 representative_planned=19 verified_canonical_completed=0 remaining=1079 eligible=367 identity_set_sha256=$IDENTITY_SET_SHA256 raw_sha256=$RAW_SHA256 manifest_sha256=$MANIFEST_SHA256 fresh_json_sha256=$FROZEN_JSON_SHA256 fresh_jsonl_sha256=$FROZEN_JSONL_SHA256 canonical_mutations=19 representative_mutations=7 adapter_source_mutations=6 v4_preflight_rc=1 v4_build_count=0 owned_jobs=0 deadline_edge=GAP rtl_dynamic=GAP receipt_sha256=$receipt_sha"
    finalize_success
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V5][STATUS] $(<"$PREFLIGHT_STATUS")"
}

run_preflight
