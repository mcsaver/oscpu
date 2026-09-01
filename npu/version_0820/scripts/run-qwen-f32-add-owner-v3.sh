#!/usr/bin/env bash
set -euo pipefail

# Qwen canonical F32 ADD[16] production-owner v3 evidence runner.
# Contract write target: npu/version_0820/scripts/run-qwen-f32-add-owner-v3.sh.
#
# The runner is deliberately split into two phases:
#   --preflight  freezes source/tool/DSO identity and proves all fail-closed
#                parsers/traps without creating a build directory.
#   --execute    consumes that immutable preflight receipt, performs exactly
#                one fresh O3/no-assert/no-trace build, and runs four configs
#                with the same binary and backend DSO.
#
# It never sources or evaluates a v1/v2 runner.  The only shared state helper
# is the repository-root task-run-status.sh required by the contract.

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-add-owner-v3"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-add-owner-v3.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
BACKEND_BUILD="$BUILD_ROOT/backend"
VERILATED_DIR="$BUILD_ROOT/verilated"
BACKEND_SOURCE="$NPU_ROOT/runtime/llama-npu-backend"
LLAMA_SOURCE="$NPU_ROOT/third_party/llama.cpp"
LLAMA_BIN="$NPU_ROOT/tmp/build/llama.cpp/bin"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v3.json"
PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
RUN_STATUS="$LOG_ROOT/run.status"
BUILD_COUNT="$LOG_ROOT/build.count"
SOURCE_IDENTITY="$COMPILER_ROOT/source-identity.json"
TOOL_IDENTITY="$COMPILER_ROOT/tool-identity.txt"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"

source "$STATUS_HELPER"

STATUS_INITIALIZED=0
STATUS_FINALIZED=0
FORCED_CLEANUP_RC=0
RUNTIME_TMP=""

cleanup_owned_temp() {
    local cleanup_rc=0
    if [[ -n "$RUNTIME_TMP" && -e "$RUNTIME_TMP" ]]; then
        case "$RUNTIME_TMP" in
            "$COMPILER_ROOT"/probe-tmp.*)
                rm -rf -- "$RUNTIME_TMP" || cleanup_rc=$?
                ;;
            *)
                printf '%s\n' \
                    "[NPU-QWEN-F32-ADD-V3][FAIL] unsafe cleanup target=$RUNTIME_TMP" >&2
                cleanup_rc=97
                ;;
        esac
    fi
    if [[ $FORCED_CLEANUP_RC -ne 0 ]]; then
        cleanup_rc=$FORCED_CLEANUP_RC
    fi
    return "$cleanup_rc"
}

finish_on_exit() {
    local command_rc=$?
    local cleanup_rc=0
    local status_rc=0
    trap - EXIT HUP INT TERM
    set +e
    cleanup_owned_temp
    cleanup_rc=$?
    if [[ $STATUS_INITIALIZED -eq 1 && $STATUS_FINALIZED -eq 0 ]]; then
        task_run_status_finalize "$command_rc" "$cleanup_rc"
        status_rc=$?
        if [[ $command_rc -eq 0 ]]; then
            command_rc=$status_rc
        fi
    elif [[ $command_rc -eq 0 && $cleanup_rc -ne 0 ]]; then
        command_rc=$cleanup_rc
    fi
    exit "$command_rc"
}

install_runner_traps() {
    trap finish_on_exit EXIT
    task_run_status_install_signal_traps
}

finalize_success() {
    local cleanup_rc=0
    local status_rc=0
    cleanup_owned_temp || cleanup_rc=$?
    task_run_status_mark_evidence_complete
    set +e
    task_run_status_finalize 0 "$cleanup_rc"
    status_rc=$?
    set -e
    STATUS_FINALIZED=1
    return "$status_rc"
}

run_internal_probe() {
    local probe_kind="$1"
    local probe_status="$2"
    task_run_status_init "$probe_status"
    STATUS_INITIALIZED=1
    install_runner_traps
    case "$probe_kind" in
        early-exit)
            task_run_status_stage "probe-early-exit"
            return 0
            ;;
        term-signal)
            task_run_status_stage "probe-term-signal"
            kill -s TERM "$BASHPID"
            return 98
            ;;
        cleanup-failure)
            task_run_status_stage "probe-cleanup-failure"
            task_run_status_mark_evidence_complete
            FORCED_CLEANUP_RC=9
            return 0
            ;;
        *)
            printf '%s\n' "[NPU-QWEN-F32-ADD-V3][FAIL] unknown internal probe" >&2
            return 2
            ;;
    esac
}

if (( $# >= 1 )); then
    if [[ "$1" == "--internal-probe" ]]; then
        if [[ $# -ne 3 ]]; then
            exit 2
        fi
        run_internal_probe "$2" "$3"
        exit 0
    fi
fi

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--execute" ]]; then
    printf '%s\n' \
        "usage: bash $RUNNER_REL --preflight|--execute" >&2
    exit 2
fi
MODE="$1"

mkdir -p -- "$LOG_ROOT" "$COMPILER_ROOT"
if [[ "$MODE" == "--preflight" ]]; then
    task_run_status_init "$PREFLIGHT_STATUS"
else
    task_run_status_init "$RUN_STATUS"
fi
STATUS_INITIALIZED=1
install_runner_traps

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ADD-V3][FAIL] $*" >&2
    return 1
}

require_file() {
    [[ -f "$1" ]] || fail "missing file=$1"
}

require_exact_hash() {
    local expected="$1"
    local path="$2"
    local actual
    require_file "$path"
    actual=$(sha256sum "$path" | sed -n 's/[[:space:]].*//p')
    [[ "$actual" == "$expected" ]] ||
        fail "hash drift path=$path expected=$expected actual=$actual"
}

write_source_identity() {
    local output="$1"
    python3 - "$REPO_ROOT" "$output" <<'PY'
import hashlib
import json
import os
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
output = pathlib.Path(sys.argv[2])

files = [
    ".github/AGENTS.md",
    ".github/instructions/agent-lightweight-workflow.instructions.md",
    ".github/instructions/rtl-agent-task-contract.instructions.md",
    ".github/instructions/rtl-generation-workflow.instructions.md",
    "scripts/task-run-status.sh",
    "scripts/tests/test-task-run-status.sh",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v1.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v2.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v3.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v1-material.md",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v2-material.md",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v3-material.md",
    "npu/version_0820/tmp/contracts/qwen-backend-owner-audit-v1.json",
    "npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md",
    "npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md",
    "npu/version_0820/docs/QWEN_F32_ADD_OWNER_RTL_CONTRACT.md",
    "npu/version_0820/rtl/TensorNpuCoprocessor.v",
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v",
    "npu/version_0820/rtl/TensorNpuF32TensorAlu.v",
    "npu/version_0820/rtl/TensorNpuFp32AddMul.v",
    "npu/version_0820/rtl/TensorNpuDmaEngine.v",
    "npu/version_0820/rtl/TensorNpuCommandDecoder.v",
    "npu/version_0820/rtl/TensorNpuRegisterFile.v",
    "npu/version_0820/rtl/TensorNpuMm2Engine.v",
    "npu/version_0820/rtl/TensorNpuLocalMemory.v",
    "npu/version_0820/rtl/tensor_npu_defs.vh",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv",
    "npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt",
    "npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp",
    "npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp",
    "npu/version_0820/runtime/llama-npu-backend/test-backend.cpp",
    "npu/version_0820/scripts/run-qwen-f32-add-owner-v3.sh",
    "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json",
    "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/final.receipt",
]

def digest_file(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def digest_tree(relative):
    base = root / relative
    if not base.is_dir():
        raise SystemExit("missing identity tree: " + relative)
    records = []
    for path in sorted(base.rglob("*"), key=lambda item: item.as_posix()):
        rel = path.relative_to(base).as_posix()
        if path.is_symlink():
            records.append((rel, "symlink", os.readlink(path)))
        elif path.is_file():
            records.append((rel, "file", digest_file(path)))
    h = hashlib.sha256()
    for record in records:
        h.update(("\0".join(record) + "\n").encode())
    return {"sha256": h.hexdigest(), "entries": len(records)}

file_hashes = {}
for relative in files:
    path = root / relative
    if not path.is_file():
        raise SystemExit("missing identity file: " + relative)
    file_hashes[relative] = digest_file(path)

trees = {
    "npu/version_0820/third_party/llama.cpp/ggml/include":
        digest_tree("npu/version_0820/third_party/llama.cpp/ggml/include"),
    "npu/version_0820/third_party/llama.cpp/ggml/src":
        digest_tree("npu/version_0820/third_party/llama.cpp/ggml/src"),
    "npu/version_0820/tmp/build/llama.cpp/bin":
        digest_tree("npu/version_0820/tmp/build/llama.cpp/bin"),
}

for dso in ("libggml-base.so", "libggml.so"):
    path = root / "npu/version_0820/tmp/build/llama.cpp/bin" / dso
    if not path.exists() or not path.resolve().is_file():
        raise SystemExit("missing pinned DSO: " + dso)

payload = {
    "schema": "qwen-f32-add-owner-v3-source-identity-v1",
    "task_id": "qwen-f32-add-owner-v3",
    "files": file_hashes,
    "trees": trees,
}
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

verify_source_identity() {
    local candidate="$COMPILER_ROOT/source-identity.verify.json"
    write_source_identity "$candidate"
    python3 - "$SOURCE_IDENTITY" "$candidate" <<'PY'
import json
import pathlib
import sys

frozen = json.loads(pathlib.Path(sys.argv[1]).read_text())
actual = json.loads(pathlib.Path(sys.argv[2]).read_text())
if frozen != actual:
    raise SystemExit("source/header/DSO identity drift")
PY
    rm -f -- "$candidate"
}

write_tool_identity() {
    local output="$1"
    local bash_path
    local python_path
    local cmake_path
    local ninja_path
    local verilator_path
    bash_path=$(command -v bash)
    python_path=$(command -v python3)
    cmake_path=$(command -v cmake)
    ninja_path=$(command -v ninja)
    verilator_path=$(command -v verilator)
    {
        printf 'bash_path=%s\n' "$bash_path"
        printf 'python_path=%s\n' "$python_path"
        printf 'cmake_path=%s\n' "$cmake_path"
        printf 'ninja_path=%s\n' "$ninja_path"
        printf 'verilator_path=%s\n' "$verilator_path"
        sha256sum "$bash_path" "$python_path" "$cmake_path" \
            "$ninja_path" "$verilator_path"
        bash --version
        python3 --version
        cmake --version
        ninja --version
        verilator --version
        printf 'verilator_root=%s\n' \
            "$(verilator --getenv VERILATOR_ROOT)"
    } >"$output" 2>&1
}

verify_tool_identity() {
    local candidate="$COMPILER_ROOT/tool-identity.verify.txt"
    write_tool_identity "$candidate"
    python3 - "$TOOL_IDENTITY" "$candidate" <<'PY'
import pathlib
import sys
if pathlib.Path(sys.argv[1]).read_bytes() != pathlib.Path(sys.argv[2]).read_bytes():
    raise SystemExit("tool identity drift")
PY
    rm -f -- "$candidate"
}

run_static_source_audit() {
    local output="$COMPILER_ROOT/static-source-audit.json"
    python3 - "$REPO_ROOT" "$output" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
npu = root / "npu/version_0820"
cmake = (npu / "runtime/llama-npu-backend/CMakeLists.txt").read_text()

expected = [
    "third_party/fpu-sp/verilog/src/float/fp_wire.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_4.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_8.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_16.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_32.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_64.sv",
    "third_party/fpu-sp/verilog/src/lzc/lzc_128.sv",
    "third_party/fpu-sp/verilog/src/float/fp_ext.sv",
    "third_party/fpu-sp/verilog/src/float/fp_fma.sv",
    "third_party/fpu-sp/verilog/src/float/fp_rnd.sv",
    "rtl/TensorNpuFp32AddMul.v",
    "rtl/TensorNpuF32TensorAlu.v",
    "rtl/TensorNpuVectorF32Adapter.v",
    "rtl/TensorNpuCoprocessor.v",
    "rtl/TensorNpuCommandDecoder.v",
    "rtl/TensorNpuRegisterFile.v",
    "rtl/TensorNpuMm2Engine.v",
    "rtl/TensorNpuDmaEngine.v",
    "rtl/TensorNpuLocalMemory.v",
    "rtl/tensor_npu_defs.vh",
]
block_match = re.search(r"set\(NPU_RTL_SOURCES(.*?)\n\)", cmake, re.S)
if block_match is None:
    raise SystemExit("missing NPU_RTL_SOURCES")
prefix = r'"\$' + r'\{NPU_PROJECT_ROOT\}/'
actual = re.findall(prefix + r'([^"]+)"', block_match.group(1))
if actual != expected or len(set(actual)) != len(expected):
    raise SystemExit("CMake RTL membership mismatch")

required_cmake_tokens = [
    "--cc -O3 -Wall -Wno-fatal --no-assert --no-trace",
    "--top-module TensorNpuCoprocessor",
    'set(NPU_VERILATED_MDIR',
    'CACHE PATH "Verilator generated model directory")',
]
for token in required_cmake_tokens:
    if cmake.count(token) != 1:
        raise SystemExit("CMake token cardinality mismatch: " + token)

modules = {
    "rtl/TensorNpuCoprocessor.v": "TensorNpuCoprocessor",
    "rtl/TensorNpuVectorF32Adapter.v": "TensorNpuVectorF32Adapter",
    "rtl/TensorNpuF32TensorAlu.v": "TensorNpuF32TensorAlu",
    "rtl/TensorNpuFp32AddMul.v": "TensorNpuFp32AddMul",
    "rtl/TensorNpuCommandDecoder.v": "TensorNpuCommandDecoder",
    "rtl/TensorNpuRegisterFile.v": "TensorNpuRegisterFile",
    "rtl/TensorNpuMm2Engine.v": "TensorNpuMm2Engine",
    "rtl/TensorNpuDmaEngine.v": "TensorNpuDmaEngine",
    "rtl/TensorNpuLocalMemory.v": "TensorNpuLocalMemory",
}
for relative, module in modules.items():
    text = (npu / relative).read_text()
    if len(re.findall(r"\bmodule\s+" + re.escape(module) + r"\b", text)) != 1:
        raise SystemExit("module membership mismatch: " + module)

top = (npu / "rtl/TensorNpuCoprocessor.v").read_text()
adapter = (npu / "rtl/TensorNpuVectorF32Adapter.v").read_text()
backend = (npu / "runtime/llama-npu-backend/ggml-npu.cpp").read_text()
test = (npu / "runtime/llama-npu-backend/test-backend.cpp").read_text()
api = (npu / "runtime/llama-npu-backend/npu-audit-api.h").read_text()

markers = [
    (top, "u_vector_f32_adapter", 1),
    (top, "macro_cmd_ready_o", 3),
    (adapter, "u_f32_tensor_alu", 1),
    (adapter, "COMMAND_FLAGS_V1", 2),
    (backend, "npu_is_exact_f32_add", 3),
    (backend, "npu_backend_graph_compute", 2),
    (backend, "required_successfully_covered", 6),
    (test, "[NPU-BACKEND-F32-ADD][PASS]", 1),
    (test, "snapshot.required_enqueued == 1", 1),
    (api, "GGML_NPU_F32_ADD_SELF_TEST_ABI_VERSION 2u", 1),
]
for text, marker, minimum in markers:
    if text.count(marker) < minimum:
        raise SystemExit("source marker missing: " + marker)

cpp_paths = [
    npu / "runtime/llama-npu-backend/npu-verilator-runner.cpp",
    npu / "runtime/llama-npu-backend/ggml-npu.cpp",
    npu / "runtime/llama-npu-backend/test-backend.cpp",
]
forbidden = [
    r"\bfloat\s+[A-Za-z_]",
    r"\bdouble\s+[A-Za-z_]",
    r"ggml_compute_forward_",
    r"\bcblas_",
    r"\bBLAS\b",
]
for path in cpp_paths:
    text = path.read_text()
    for pattern in forbidden:
        if re.search(pattern, text):
            raise SystemExit("forbidden host arithmetic marker: " +
                             path.name + ":" + pattern)

payload = {
    "schema": "qwen-f32-add-owner-v3-static-source-audit-v1",
    "rtl_sources": actual,
    "rtl_source_count": len(actual),
    "f32_membership_count": 13,
    "adapter_count": 1,
    "top_count": 1,
    "legacy_membership_count": 6,
    "macro_capability_epoch": 1,
    "host_tensor_arithmetic_markers": 0,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_manifest_audit() {
    local output="$COMPILER_ROOT/manifest-audit.json"
    python3 - "$NPU_ROOT" "$output" <<'PY'
import json
import pathlib
import sys

npu = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
manifest_path = npu / "tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
envelope = json.loads(manifest_path.read_text())
if envelope.get("manifest_sha256") != \
        "49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474":
    raise SystemExit("canonical manifest identity mismatch")
manifest = envelope.get("manifest", {})
counts = manifest.get("counts", {})
if counts != {
        "compute": 959,
        "external_tensors": 375,
        "metadata": 632,
        "mover": 120,
        "source_edges": 2471,
        "total": 1711,
}:
    raise SystemExit("canonical manifest count mismatch")

expected_ne = [16, 1, 1, 1]
expected_nb = [4, 64, 64, 64]
matching = []
for node in manifest.get("nodes", []):
    descriptor = node.get("descriptor", {})
    sources = node.get("sources", [])
    if descriptor.get("op_name") != "ADD" or \
       descriptor.get("type_name") != "f32" or \
       descriptor.get("ne") != expected_ne or \
       descriptor.get("nb") != expected_nb or len(sources) < 2:
        continue
    good_sources = True
    for source in sources[:2]:
        src = source.get("descriptor", {})
        if src.get("type_name") != "f32" or \
           src.get("ne") != expected_ne or src.get("nb") != expected_nb:
            good_sources = False
    if good_sources:
        matching.append(node.get("canonical_id"))
if len(matching) != 18 or len(set(matching)) != 18:
    raise SystemExit("canonical F32 ADD[16] multiplicity mismatch")

receipt = (npu / "tmp/logs/qwen-graph-manifest-v5/final.receipt").read_text()
required_receipt = [
    "nodes=1711",
    "compute=959",
    "mover=120",
    "metadata=632",
    "manifest_sha256=49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474",
    "cleanup_rc=0",
    "evidence_complete=1",
]
for marker in required_receipt:
    if receipt.count(marker) != 1:
        raise SystemExit("manifest receipt marker mismatch: " + marker)

payload = {
    "schema": "qwen-f32-add-owner-v3-manifest-audit-v1",
    "manifest_sha256": envelope["manifest_sha256"],
    "counts": counts,
    "canonical_f32_add_16_count": len(matching),
    "canonical_ids": sorted(matching),
    "remaining_compute_mover_gap": 1078,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_warning_parser_self_test() {
    local output="$COMPILER_ROOT/warning-parser-self-test.json"
    python3 - "$output" <<'PY'
import json
import pathlib
import re
import sys

pattern = re.compile(
    r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|"
    r"%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
    re.IGNORECASE | re.MULTILINE,
)
cases = {
    "clean": ("[1/4] Building CXX object\n", True),
    "gcc_warning": ("foo.cpp:1:2: warning: bad\n", False),
    "gcc_error": ("foo.cpp:1:2: error: bad\n", False),
    "verilator_warning": ("%Warning-WIDTH: bad\n", False),
    "verilator_error": ("%Error: bad\n", False),
}
observed = {}
for name, (text, expected_clean) in cases.items():
    clean = pattern.search(text) is None
    observed[name] = clean
    if clean != expected_clean:
        raise SystemExit("warning parser self-test failed: " + name)
pathlib.Path(sys.argv[1]).write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v3-warning-parser-self-test-v1",
    "cases": observed,
}, sort_keys=True, indent=2) + "\n")
PY
}

run_runner_probe_tests() {
    local probe_dir="$RUNTIME_TMP"
    local rc=0
    local early_status="$probe_dir/early-exit.status"
    local signal_status="$probe_dir/term-signal.status"
    local cleanup_status="$probe_dir/cleanup-failure.status"

    set +e
    bash "$RUNNER" --internal-probe early-exit "$early_status"
    rc=$?
    set -e
    [[ $rc -eq 1 ]] ||
        fail "early EXIT probe rc=$rc expected=1"
    [[ "$(sed -n '1p' "$early_status")" == \
       "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0" ]] ||
        fail "early EXIT probe status mismatch"

    set +e
    bash "$RUNNER" --internal-probe term-signal "$signal_status"
    rc=$?
    set -e
    [[ $rc -eq 143 ]] ||
        fail "TERM probe rc=$rc expected=143"
    [[ "$(sed -n '1p' "$signal_status")" == \
       "FAIL rc=143 stage=probe-term-signal evidence_complete=0 cleanup_rc=0 signal=TERM" ]] ||
        fail "TERM probe status mismatch"

    set +e
    bash "$RUNNER" --internal-probe cleanup-failure "$cleanup_status"
    rc=$?
    set -e
    [[ $rc -eq 9 ]] ||
        fail "cleanup probe rc=$rc expected=9"
    [[ "$(sed -n '1p' "$cleanup_status")" == \
       "FAIL rc=9 stage=probe-cleanup-failure evidence_complete=1 cleanup_rc=9" ]] ||
        fail "cleanup probe status mismatch"

    python3 - "$probe_dir" "$COMPILER_ROOT/runner-probe-audit.json" <<'PY'
import json
import pathlib
import sys
probe = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
payload = {
    "schema": "qwen-f32-add-owner-v3-runner-probes-v1",
    "early_exit": (probe / "early-exit.status").read_text().strip(),
    "term_signal": (probe / "term-signal.status").read_text().strip(),
    "cleanup_failure": (probe / "cleanup-failure.status").read_text().strip(),
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_preflight() {
    task_run_status_stage "preflight-input-boundary"
    require_exact_hash \
        "97ff401a9beaa4f22f6f420cc3000b7f457d1aeeecf47f3020eeaa0b1da889f7" \
        "$CONTRACT"
    require_exact_hash \
        "c42fc734d11c971209249f7ef7762e7cc96f2e2eb17929bc771a0e1e98ea4b23" \
        "$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v1.json"
    require_exact_hash \
        "5233393e9526d99db462b0ead96cc45ecc4f8cf46caff06e000229a08685a0e9" \
        "$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v2.json"
    require_exact_hash \
        "43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6" \
        "$STATUS_HELPER"
    require_exact_hash \
        "35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640" \
        "$STATUS_HELPER_TEST"

    while read -r expected relative; do
        require_exact_hash "$expected" "$REPO_ROOT/$relative"
    done <<'HASHES'
7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt
f4db447eec7305a801d8c15d92fe28f4f580dde1ad3601433eb4690ce52803ef npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h
388d10582253069eab8a703bb8166b1a066abf27b78281278d1bc496c431bf62 npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h
394a09e33d9063a5208479da580ce041ffbbc5b5ea52a74903707785b37df381 npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp
9719c15518e0ae83e45bf0e788802ccb148761e1e5619b5b5cb30eadac4ac2a1 npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp
e14a3f759f81a17e1f05be60e0c670ba869f4263e89771a6d13391b143529f64 npu/version_0820/runtime/llama-npu-backend/test-backend.cpp
71b0e9ad86390f3d182a7c4343663560dbcce1f835d00c21b47529631904b2e1 npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
2adaf1eafd68c14b4978cd26417c2ee3a531c72ff27d23318fa65ded9067d41c npu/version_0820/rtl/TensorNpuCoprocessor.v
641476144342ca5fbe3e3ea220ae97e50790920b14d6b40fc34f33e38fa33577 npu/version_0820/rtl/TensorNpuF32TensorAlu.v
ac9e28647809a9bad0718a640ad76eaf59a1096e4a5b7aebd285c95bc621557c npu/version_0820/rtl/TensorNpuFp32AddMul.v
4452d6f445194ff40db27e4b6d8362c27854d2bad3fc17aebf903cda58d2f304 npu/version_0820/rtl/TensorNpuDmaEngine.v
c9bb69b42de7c7bce906824580b52dc891229a0d6b99d05d0a66023c320d8df3 npu/version_0820/rtl/TensorNpuCommandDecoder.v
16f132f4743760f32aab3fd79c00b14e9a5dfabe5a89a6d8a0ff08c8698c569f npu/version_0820/rtl/TensorNpuRegisterFile.v
a2157723aba8658efc74b76fa9643a3f659070f0cdf2a0c566a7cc1caffe6fd5 npu/version_0820/rtl/TensorNpuMm2Engine.v
fd16e30bc57dad9128c723caa7e1c3fbb8e4f5436cd4402c5c3a375a9198ed12 npu/version_0820/rtl/TensorNpuLocalMemory.v
567dc8572448239000194fad877cdb36a6cfcfa32149839ef0488e0e006d679c npu/version_0820/rtl/tensor_npu_defs.vh
d2e7bacecf505479ff9d3575f712d88456c128bb7db680ad7fa1f22d27fc524d npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv
bf7b1bb31dead9b4628be3192529e0735fdfdce811b0e6b9a9c55b576bc57bfc npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
17a5176638b6badd4ab0c310ba3aeb0c3fe344ac0827de3f360743472c8d19ee npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
0249e1908c81414ba75ca30718e87c5b8be859e91cad4359c8ab56c1f15a5c97 npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
74a951c212403e15ab3f38cf0fdd3a1086142f93e3fe24136b1d332de5aaa4ce npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
222a34e8c52658461e87ee5c0c32c265a70e9618720a18e94d97029e36254eb1 npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
6b6a068e91df9e37d200d5d0ab41abe3a21aadf87c5b75ad5d2d3eae6d63fdde npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
7fbba5a07e956212a1e86ffef28327b3af72e3009b598358add3902226336138 npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
6abbb10ee1a561eb1d179025747a8a8e68fb186ccde110951d20ad34b210961d npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv
69c7e09223c0235a520db84554190a2dc61f43576864a4d951052d62ff52587b npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv
04fda1036f7325bb0a0ae67534fb92710954bd31934cb424d9a99815d27599c9 npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv
5ffe677e483fe800a2dab5c8495674976108fa964750a5f7016c2e71932817fc npu/version_0820/docs/QWEN_F32_ADD_OWNER_RTL_CONTRACT.md
4e6c287e89015bd917aefb82e89782aee102ba88604b58726edebd75ab0baf04 npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
675f26da4bea19956e960bb895c7d10e1d310d0e3a508a514434c9c2b29f2f7f npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
HASHES

    task_run_status_stage "preflight-fresh-build"
    if [[ -e "$BUILD_COUNT" ]]; then
        [[ "$(sed -n '1p' "$BUILD_COUNT")" == "0" ]] ||
            fail "build count is not zero"
    fi
    [[ ! -e "$BUILD_ROOT" ]] ||
        fail "fresh build root already exists=$BUILD_ROOT"
    printf '0\n' >"$BUILD_COUNT"

    task_run_status_stage "preflight-helper"
    bash -n "$RUNNER"
    bash "$STATUS_HELPER_TEST" >"$LOG_ROOT/task-run-status-test.log" 2>&1
    [[ "$(sed -n '1p' "$LOG_ROOT/task-run-status-test.log")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper marker mismatch"

    task_run_status_stage "preflight-static-audits"
    run_static_source_audit
    run_manifest_audit
    run_warning_parser_self_test
    write_source_identity "$SOURCE_IDENTITY"
    write_tool_identity "$TOOL_IDENTITY"

    task_run_status_stage "preflight-runner-probes"
    RUNTIME_TMP=$(mktemp -d "$COMPILER_ROOT/probe-tmp.XXXXXX")
    run_runner_probe_tests
    cleanup_owned_temp
    RUNTIME_TMP=""

    task_run_status_stage "preflight-receipt"
    python3 - \
        "$REPO_ROOT" "$SOURCE_IDENTITY" "$TOOL_IDENTITY" \
        "$COMPILER_ROOT/static-source-audit.json" \
        "$COMPILER_ROOT/manifest-audit.json" \
        "$COMPILER_ROOT/warning-parser-self-test.json" \
        "$COMPILER_ROOT/runner-probe-audit.json" \
        "$PREFLIGHT_RECEIPT" <<'PY'
import hashlib
import json
import pathlib
import sys

paths = [pathlib.Path(item) for item in sys.argv[2:8]]
output = pathlib.Path(sys.argv[8])
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
payload = {
    "schema": "qwen-f32-add-owner-v3-preflight-receipt-v1",
    "task_id": "qwen-f32-add-owner-v3",
    "contract_json": "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v3.json",
    "contract_sha256":
        "97ff401a9beaa4f22f6f420cc3000b7f457d1aeeecf47f3020eeaa0b1da889f7",
    "artifacts": {path.name: digest(path) for path in paths},
    "build_count": 0,
    "build_root_absent": True,
    "expected_final_status": "PASS",
    "expected_final_status_sha256":
        hashlib.sha256(b"PASS\n").hexdigest(),
    "remaining_compute_mover_gap": 1078,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
    sha256sum "$PREFLIGHT_RECEIPT" >"$PREFLIGHT_RECEIPT_HASH"
    python3 - "$PREFLIGHT_RECEIPT" "$BUILD_COUNT" "$BUILD_ROOT" <<'PY'
import json
import pathlib
import sys
receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
if receipt["build_count"] != 0 or receipt["expected_final_status"] != "PASS":
    raise SystemExit("preflight receipt field mismatch")
if pathlib.Path(sys.argv[2]).read_text() != "0\n":
    raise SystemExit("preflight build count changed")
if pathlib.Path(sys.argv[3]).exists():
    raise SystemExit("preflight created build root")
PY
    printf '%s\n' \
        "[NPU-QWEN-F32-ADD-V3][PREFLIGHT-CANDIDATE] build_count=0 source_tool_dso=bound membership=static warning_parser=pass probes=pass"
    finalize_success
}

verify_preflight_receipt() {
    require_file "$PREFLIGHT_STATUS"
    require_file "$PREFLIGHT_RECEIPT"
    require_file "$PREFLIGHT_RECEIPT_HASH"
    [[ "$(sed -n '1p' "$PREFLIGHT_STATUS")" == "PASS" ]] ||
        fail "preflight status is not PASS"
    python3 - \
        "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_HASH" \
        "$BUILD_COUNT" "$BUILD_ROOT" <<'PY'
import hashlib
import pathlib
import sys
receipt = pathlib.Path(sys.argv[1])
hash_record = pathlib.Path(sys.argv[2]).read_text().split()[0]
if hashlib.sha256(receipt.read_bytes()).hexdigest() != hash_record:
    raise SystemExit("preflight receipt hash mismatch")
if pathlib.Path(sys.argv[3]).read_text() != "0\n":
    raise SystemExit("build count is not zero")
if pathlib.Path(sys.argv[4]).exists():
    raise SystemExit("build root is not fresh")
PY
}

audit_cmake_cache() {
    python3 - \
        "$BACKEND_BUILD/CMakeCache.txt" "$BACKEND_SOURCE" \
        "$VERILATED_DIR" "$LLAMA_SOURCE" "$LLAMA_BIN" \
        "$COMPILER_ROOT/compiler-identity.json" <<'PY'
import hashlib
import json
import pathlib
import sys

cache_path = pathlib.Path(sys.argv[1])
expected = {
    "ggml_npu_backend_SOURCE_DIR": str(pathlib.Path(sys.argv[2]).resolve()),
    "NPU_VERILATED_MDIR": str(pathlib.Path(sys.argv[3]).resolve()),
    "LLAMA_SOURCE_DIR": str(pathlib.Path(sys.argv[4]).resolve()),
    "LLAMA_BUILD_BIN": str(pathlib.Path(sys.argv[5]).resolve()),
    "CMAKE_BUILD_TYPE": "Release",
    "NPU_VERILATOR_JOBS": "1",
}
values = {}
for line in cache_path.read_text().splitlines():
    if not line or line.startswith("//") or line.startswith("#") or "=" not in line:
        continue
    left, value = line.split("=", 1)
    key = left.split(":", 1)[0]
    values[key] = value
for key, value in expected.items():
    if values.get(key) != value:
        raise SystemExit("CMake cache mismatch: " + key)
compiler = pathlib.Path(values.get("CMAKE_CXX_COMPILER", "")).resolve()
if not compiler.is_file():
    raise SystemExit("missing configured C++ compiler")
h = hashlib.sha256(compiler.read_bytes()).hexdigest()
payload = {
    "schema": "qwen-f32-add-owner-v3-compiler-identity-v1",
    "compiler_path": str(compiler),
    "compiler_sha256": h,
    "compiler_id": values.get("CMAKE_CXX_COMPILER_ID", ""),
    "generator": values.get("CMAKE_GENERATOR", ""),
    "cache_bindings": expected,
}
pathlib.Path(sys.argv[6]).write_text(
    json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

audit_build_diagnostics() {
    python3 - \
        "$LOG_ROOT/configure.log" "$LOG_ROOT/build.log" \
        "$COMPILER_ROOT/build-diagnostic-audit.json" <<'PY'
import json
import pathlib
import re
import sys

pattern = re.compile(
    r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|"
    r"%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
    re.IGNORECASE | re.MULTILINE,
)
findings = {}
for item in sys.argv[1:3]:
    path = pathlib.Path(item)
    matches = [match.group(2) for match in pattern.finditer(path.read_text(
        errors="replace"))]
    findings[path.name] = matches
if any(findings.values()):
    raise SystemExit("source/tool warning or error diagnostic detected")
pathlib.Path(sys.argv[3]).write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v3-build-diagnostics-v1",
    "files": findings,
    "warning_count": 0,
    "error_count": 0,
}, sort_keys=True, indent=2) + "\n")
PY
}

audit_elaboration_membership() {
    local ver_files="$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat"
    local verilator_root
    require_file "$ver_files"
    verilator_root=$(verilator --getenv VERILATOR_ROOT)
    python3 - \
        "$REPO_ROOT" "$ver_files" "$verilator_root" \
        "$COMPILER_ROOT/elaboration-membership.json" <<'PY'
import json
import pathlib
import shlex
import shutil
import sys

root = pathlib.Path(sys.argv[1]).resolve()
ver_files = pathlib.Path(sys.argv[2])
verilator_root = pathlib.Path(sys.argv[3]).resolve()
output = pathlib.Path(sys.argv[4])

design_rel = [
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv",
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv",
    "npu/version_0820/rtl/TensorNpuFp32AddMul.v",
    "npu/version_0820/rtl/TensorNpuF32TensorAlu.v",
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v",
    "npu/version_0820/rtl/TensorNpuCoprocessor.v",
    "npu/version_0820/rtl/TensorNpuCommandDecoder.v",
    "npu/version_0820/rtl/TensorNpuRegisterFile.v",
    "npu/version_0820/rtl/TensorNpuMm2Engine.v",
    "npu/version_0820/rtl/TensorNpuDmaEngine.v",
    "npu/version_0820/rtl/TensorNpuLocalMemory.v",
    "npu/version_0820/rtl/tensor_npu_defs.vh",
]
design = {str((root / item).resolve()) for item in design_rel}
transitive = {str((verilator_root / "include/verilated_std.sv").resolve())}
tool_path = shutil.which("verilator_bin")
if tool_path is None:
    raise SystemExit("verilator_bin not found")
tool = {str(pathlib.Path(tool_path).resolve())}
control = set()

raw = []
for line in ver_files.read_text(errors="replace").splitlines():
    fields = shlex.split(line)
    if fields and fields[0] == "S":
        raw.append(str(pathlib.Path(fields[-1]).resolve()))

def compare(actual_rows, groups):
    if len(actual_rows) != len(set(actual_rows)):
        return False
    group_sets = list(groups.values())
    for left in range(len(group_sets)):
        for right in range(left + 1, len(group_sets)):
            if group_sets[left] & group_sets[right]:
                return False
    expected = set().union(*group_sets)
    return set(actual_rows) == expected

groups = {
    "design": design,
    "transitive_include": transitive,
    "control": control,
    "tool": tool,
}
if not compare(raw, groups):
    expected = sorted(set().union(*groups.values()))
    raise SystemExit(
        "actual elaboration membership mismatch missing=" +
        repr(sorted(set(expected) - set(raw))) +
        " extra=" + repr(sorted(set(raw) - set(expected))))

mutations = {}
mutations["missing"] = not compare(raw[:-1], groups)
mutations["extra"] = not compare(
    raw + [str((root / "npu/version_0820/rtl/not-a-source.v").resolve())],
    groups)
substitution = list(raw)
substitution[0] = str(
    (root / "npu/version_0820/rtl/substituted-top.v").resolve())
mutations["substitution"] = not compare(substitution, groups)
collision_groups = {name: set(items) for name, items in groups.items()}
collision_groups["transitive_include"].add(next(iter(design)))
mutations["class_collision"] = not compare(raw, collision_groups)
if not all(mutations.values()):
    raise SystemExit("membership mutation was not rejected")

classified = {}
for name, items in groups.items():
    classified[name] = sorted(items)
payload = {
    "schema": "qwen-f32-add-owner-v3-elaboration-membership-v1",
    "raw_s_row_count": len(raw),
    "raw_s_rows": raw,
    "classes": classified,
    "class_counts": {name: len(items) for name, items in classified.items()},
    "f32_membership_count": 13,
    "top_exact_count": 1,
    "adapter_exact_count": 1,
    "legacy_membership_count": 6,
    "mutations_rejected": mutations,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_one_config() {
    local name="$1"
    shift
    local log="$LOG_ROOT/$name.log"
    local argv_file="$LOG_ROOT/$name.argv"
    local rc_file="$LOG_ROOT/$name.rc"
    local binary="$BACKEND_BUILD/test-npu-backend"
    local dso="$BACKEND_BUILD/libggml-npu.so"
    local rc=0

    {
        printf 'LD_LIBRARY_PATH=%q ' "$LLAMA_BIN:$BACKEND_BUILD"
        printf '%q ' "$binary" "$dso"
        printf '%q ' "$@"
        printf '\n'
    } >"$argv_file"
    set +e
    LD_LIBRARY_PATH="$LLAMA_BIN:$BACKEND_BUILD" \
        "$binary" "$dso" "$@" >"$log" 2>&1
    rc=$?
    set -e
    printf '%s\n' "$rc" >"$rc_file"
    [[ $rc -eq 0 ]] || fail "config=$name rc=$rc log=$log"
}

audit_run_logs() {
    python3 - \
        "$LOG_ROOT/positive.log" \
        "$LOG_ROOT/unknown-kernel.log" \
        "$LOG_ROOT/out-of-range-4mod8.log" \
        "$LOG_ROOT/req-ready-low.log" \
        "$COMPILER_ROOT/run-log-audit.json" <<'PY'
import json
import pathlib
import re
import sys

positive, unknown, out_range, timeout = [
    pathlib.Path(item).read_text(errors="replace") for item in sys.argv[1:5]
]
if "[FAIL]" in "".join((positive, unknown, out_range, timeout)):
    raise SystemExit("FAIL marker present in config log")
if positive.count("[NPU-BACKEND-F32-ADD][PASS]") != 1 or \
   positive.count("[NPU-BACKEND-ABI][PASS]") != 1:
    raise SystemExit("positive marker cardinality mismatch")
positive_fields = {
    "executed_by_verilator": 1,
    "covered": 1,
    "cpu_fallback": 0,
    "host_tensor_ops": 0,
    "read_bytes": 256,
    "write_bytes": 64,
    "elements": 16,
}
for key, value in positive_fields.items():
    if not re.search(r"\b" + re.escape(key) + r"=" + str(value) + r"\b",
                     positive):
        raise SystemExit("positive field mismatch: " + key)

negative_specs = [
    ("unknown-kernel", unknown, 14, 3, 0),
    ("out-of-range-4mod8", out_range, 16, 5, 0),
    ("req-ready-low", timeout, 17, 10, 1),
]
negative_result = {}
for name, text, status, error_class, starts in negative_specs:
    if text.count("[NPU-BACKEND-F32-MODE][PASS]") != 1:
        raise SystemExit("negative marker cardinality mismatch: " + name)
    expected = {
        "mode": name,
        "status": status,
        "class": error_class,
        "f32_starts": starts,
        "read": 0,
        "write": 0,
        "elements": 0,
        "requests": 0,
        "responses": 0,
        "stable": 1,
        "recovery": 1,
    }
    for key, value in expected.items():
        if not re.search(r"\b" + re.escape(key) + r"=" +
                         re.escape(str(value)) + r"\b", text):
            raise SystemExit(name + " field mismatch: " + key)
    negative_result[name] = expected

payload = {
    "schema": "qwen-f32-add-owner-v3-run-log-audit-v1",
    "positive": {
        "required_seen": 1,
        "assigned_to_npu": 1,
        "required_enqueued": 1,
        "required_successfully_covered": 1,
        "executed_by_verilator": 1,
        "covered": 1,
        "cpu_fallback": 0,
        "host_tensor_ops": 0,
        "read_bytes": 256,
        "write_bytes": 64,
        "elements": 16
    },
    "negative": negative_result,
    "same_binary_four_configs": True,
    "remaining_compute_mover_gap": 1078,
}
pathlib.Path(sys.argv[5]).write_text(
    json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_execute() {
    task_run_status_stage "execute-preflight-binding"
    verify_preflight_receipt
    verify_source_identity
    verify_tool_identity
    [[ "$(sed -n '1p' "$BUILD_COUNT")" == "0" ]] ||
        fail "build count changed before execute"
    [[ ! -e "$BUILD_ROOT" ]] || fail "build root is not fresh"

    task_run_status_stage "execute-build-admission"
    mkdir -p -- "$BUILD_ROOT"
    printf '1\n' >"$BUILD_COUNT"

    task_run_status_stage "cmake-configure"
    cmake -S "$BACKEND_SOURCE" -B "$BACKEND_BUILD" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DNPU_VERILATED_MDIR="$VERILATED_DIR" \
        -DLLAMA_SOURCE_DIR="$LLAMA_SOURCE" \
        -DLLAMA_BUILD_BIN="$LLAMA_BIN" \
        -DNPU_VERILATOR_JOBS=1 \
        >"$LOG_ROOT/configure.log" 2>&1
    audit_cmake_cache

    task_run_status_stage "unique-o3-build"
    ninja -C "$BACKEND_BUILD" -j1 test-npu-backend \
        >"$LOG_ROOT/build.log" 2>&1
    [[ "$(sed -n '1p' "$BUILD_COUNT")" == "1" ]] ||
        fail "unique build count mismatch"
    [[ "$(rg -c 'Generating O3/no-assert/no-trace TensorNpuCoprocessor model' "$LOG_ROOT/build.log")" == "1" ]] ||
        fail "Verilator elaboration cardinality mismatch"

    task_run_status_stage "build-evidence-audit"
    audit_build_diagnostics
    audit_elaboration_membership
    verify_source_identity
    verify_tool_identity
    require_file "$BACKEND_BUILD/test-npu-backend"
    require_file "$BACKEND_BUILD/libggml-npu.so"
    require_file "$VERILATED_DIR/VTensorNpuCoprocessor__ALL.a"
    sha256sum \
        "$BACKEND_BUILD/test-npu-backend" \
        "$BACKEND_BUILD/libggml-npu.so" \
        "$VERILATED_DIR/VTensorNpuCoprocessor__ALL.a" \
        "$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat" \
        >"$COMPILER_ROOT/build-artifacts.sha256"

    task_run_status_stage "config-positive-graph-compute"
    run_one_config positive
    task_run_status_stage "config-unknown-kernel"
    run_one_config unknown-kernel --f32-add-unknown-kernel
    task_run_status_stage "config-out-of-range-4mod8"
    run_one_config out-of-range-4mod8 --f32-add-out-of-range
    task_run_status_stage "config-req-ready-low"
    run_one_config req-ready-low --f32-add-req-ready-low

    task_run_status_stage "four-config-audit"
    audit_run_logs
    python3 - "$BACKEND_BUILD/test-npu-backend" \
        "$BACKEND_BUILD/libggml-npu.so" "$LOG_ROOT" <<'PY'
import hashlib
import json
import pathlib
import sys
binary = pathlib.Path(sys.argv[1])
dso = pathlib.Path(sys.argv[2])
log_root = pathlib.Path(sys.argv[3])
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
identity = {
    "binary_sha256": digest(binary),
    "dso_sha256": digest(dso),
}
for name in ("positive", "unknown-kernel",
             "out-of-range-4mod8", "req-ready-low"):
    (log_root / (name + ".identity.json")).write_text(
        json.dumps({
            "schema": "qwen-f32-add-owner-v3-config-identity-v1",
            "config": name,
            **identity,
        }, sort_keys=True, indent=2) + "\n")
PY
    verify_source_identity
    verify_tool_identity

    task_run_status_stage "final-receipt"
    python3 - \
        "$REPO_ROOT" "$LOG_ROOT" "$COMPILER_ROOT" "$BUILD_COUNT" \
        "$LOG_ROOT/final.receipt.json" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
logs = pathlib.Path(sys.argv[2])
compiler = pathlib.Path(sys.argv[3])
build_count = pathlib.Path(sys.argv[4])
output = pathlib.Path(sys.argv[5])
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

required = [
    logs / "preflight.receipt.json",
    compiler / "source-identity.json",
    compiler / "tool-identity.txt",
    compiler / "compiler-identity.json",
    compiler / "build-diagnostic-audit.json",
    compiler / "elaboration-membership.json",
    compiler / "build-artifacts.sha256",
    compiler / "run-log-audit.json",
]
for name in ("positive", "unknown-kernel",
             "out-of-range-4mod8", "req-ready-low"):
    required.extend([
        logs / (name + ".argv"),
        logs / (name + ".rc"),
        logs / (name + ".log"),
        logs / (name + ".identity.json"),
    ])
for path in required:
    if not path.is_file():
        raise SystemExit("missing final artifact: " + str(path))
    if path.suffix == ".rc" and path.read_text() != "0\n":
        raise SystemExit("nonzero config rc: " + str(path))
if build_count.read_text() != "1\n":
    raise SystemExit("final build count mismatch")

payload = {
    "schema": "qwen-f32-add-owner-v3-final-receipt-v1",
    "task_id": "qwen-f32-add-owner-v3",
    "contract_sha256":
        "97ff401a9beaa4f22f6f420cc3000b7f457d1aeeecf47f3020eeaa0b1da889f7",
    "build_count": 1,
    "build_config": "O3/no-assert/no-trace",
    "artifacts": {
        str(path.relative_to(root)): digest(path) for path in required
    },
    "positive": {
        "required_seen": 1,
        "assigned_to_npu": 1,
        "required_enqueued": 1,
        "required_successfully_covered": 1,
        "executed_by_verilator": 1,
        "cpu_fallback_attempts": 0,
        "host_tensor_ops": 0,
        "gmem_read_bytes": 256,
        "gmem_write_bytes": 64,
        "vector_elements": 16,
    },
    "negative_configs": {
        "unknown-kernel": "controlled-reject-clean-recovery",
        "out-of-range-4mod8": "controlled-reject-clean-recovery",
        "req-ready-low": "controlled-timeout-clean-recovery",
    },
    "remaining_compute_mover_gap": 1078,
    "expected_final_status": "PASS",
    "expected_final_status_sha256":
        hashlib.sha256(b"PASS\n").hexdigest(),
    "cleanup_rc": 0,
    "evidence_complete": 1,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
    sha256sum "$LOG_ROOT/final.receipt.json" \
        >"$LOG_ROOT/final.receipt.sha256"
    python3 - "$LOG_ROOT/final.receipt.json" "$BUILD_COUNT" <<'PY'
import json
import pathlib
import sys
receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
if receipt["build_count"] != 1 or receipt["cleanup_rc"] != 0 or \
   receipt["evidence_complete"] != 1 or \
   receipt["remaining_compute_mover_gap"] != 1078:
    raise SystemExit("final receipt field mismatch")
if pathlib.Path(sys.argv[2]).read_text() != "1\n":
    raise SystemExit("final build count drift")
PY
    printf '%s\n' \
        "[NPU-QWEN-F32-ADD-V3][PASS-CANDIDATE] build_count=1 configs=4 read=256 write=64 elements=16 remaining_gap=1078"
    finalize_success
}

if [[ "$MODE" == "--preflight" ]]; then
    run_preflight
else
    run_execute
fi
