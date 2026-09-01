#!/usr/bin/env bash
set -euo pipefail

# Qwen canonical F32 ADD[16] production-owner v6 evidence runner.
#
# --preflight freezes source/header/DSO/tool identities, emits and audits the
# task-scoped backend.mk, exercises fail-closed status paths, and proves that
# the build root is absent. It performs no RTL generation, make, or test run.
# --execute consumes the immutable preflight receipt, performs one direct
# O3/no-assert/no-trace build, and runs four configurations with one binary.

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-add-owner-v8"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-add-owner-v8.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
VERILATED_DIR="$BUILD_ROOT/verilated"
BACKEND_BUILD="$BUILD_ROOT/backend"
BACKEND_SOURCE="$NPU_ROOT/runtime/llama-npu-backend"
LLAMA_SOURCE="$NPU_ROOT/third_party/llama.cpp"
LLAMA_BIN="$NPU_ROOT/tmp/build/llama.cpp/bin"
BACKEND_MK="$COMPILER_ROOT/backend.mk"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v8.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v8-material.md"
PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
RUN_STATUS="$LOG_ROOT/run.status"
BUILD_COUNT="$LOG_ROOT/build.count"
SOURCE_IDENTITY="$COMPILER_ROOT/source-identity.json"
TOOL_IDENTITY="$COMPILER_ROOT/tool-identity.txt"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"

RTL_SOURCES_REL=(
    npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_wire.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_4.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv
    npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv
    npu/version_0820/rtl/TensorNpuFp32AddMul.v
    npu/version_0820/rtl/TensorNpuF32TensorAlu.v
    npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
    npu/version_0820/rtl/TensorNpuCoprocessor.v
    npu/version_0820/rtl/TensorNpuCommandDecoder.v
    npu/version_0820/rtl/TensorNpuRegisterFile.v
    npu/version_0820/rtl/TensorNpuMm2Engine.v
    npu/version_0820/rtl/TensorNpuDmaEngine.v
    npu/version_0820/rtl/TensorNpuLocalMemory.v
    npu/version_0820/rtl/tensor_npu_defs.vh
)
RTL_SOURCES=()
for relative in "${RTL_SOURCES_REL[@]}"; do
    RTL_SOURCES+=("$REPO_ROOT/$relative")
done

source "$STATUS_HELPER"

STATUS_INITIALIZED=0
STATUS_FINALIZED=0
FORCED_CLEANUP_RC=0
RUNTIME_TMP=""
TOOL_BASH=""
TOOL_PYTHON=""
TOOL_MAKE=""
TOOL_CXX=""
TOOL_AR=""
TOOL_VERILATOR=""
TOOL_VERILATOR_BIN=""
VERILATOR_ROOT=""

cleanup_owned_temp() {
    local cleanup_rc=0
    if [[ -n "$RUNTIME_TMP" && -e "$RUNTIME_TMP" ]]; then
        case "$RUNTIME_TMP" in
            "$COMPILER_ROOT"/probe-tmp.*)
                rm -rf -- "$RUNTIME_TMP" || cleanup_rc=$?
                ;;
            *)
                printf '%s\n' \
                    "[NPU-QWEN-F32-ADD-V8][FAIL] unsafe cleanup target=$RUNTIME_TMP" >&2
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
            printf '%s\n' \
                "[NPU-QWEN-F32-ADD-V8][FAIL] unknown internal probe" >&2
            return 2
            ;;
    esac
}

if (( $# >= 1 )) && [[ "$1" == "--internal-probe" ]]; then
    if [[ $# -ne 3 ]]; then
        exit 2
    fi
    run_internal_probe "$2" "$3"
    exit 0
fi

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--execute" ]]; then
    printf '%s\n' "usage: bash $RUNNER_REL --preflight|--execute" >&2
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
    printf '%s\n' "[NPU-QWEN-F32-ADD-V8][FAIL] $*" >&2
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

resolve_tools() {
    TOOL_BASH=$(command -v bash) || fail "bash not found"
    TOOL_PYTHON=$(command -v python3) || fail "python3 not found"
    TOOL_MAKE=$(command -v make) || fail "make not found"
    TOOL_CXX=$(command -v g++) || fail "g++ not found"
    TOOL_AR=$(command -v ar) || fail "ar not found"
    TOOL_VERILATOR=$(command -v verilator) || fail "verilator not found"
    TOOL_VERILATOR_BIN=$(command -v verilator_bin) ||
        fail "verilator_bin not found"
    VERILATOR_ROOT=$("$TOOL_VERILATOR" --getenv VERILATOR_ROOT)
    [[ -d "$VERILATOR_ROOT" ]] || fail "missing Verilator root"
    require_file "$VERILATOR_ROOT/include/verilated.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_threads.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_std.sv"
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
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v6.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v6-material.md",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v7.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v8.json",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v8-material.md",
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
    "npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp",
    "npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp",
    "npu/version_0820/runtime/llama-npu-backend/test-backend.cpp",
    "npu/version_0820/scripts/run-qwen-f32-add-owner-v6.sh",
    "npu/version_0820/scripts/run-qwen-f32-add-owner-v8.sh",
    "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json",
    "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/final.receipt",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v6/build.count",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v6/run.status",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v6/verilator.log",
    "npu/version_0820/tmp/build/qwen-f32-add-owner-v6/verilated/VTensorNpuCoprocessor__verFiles.dat",
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
    "schema": "qwen-f32-add-owner-v8-source-identity-v1",
    "task_id": "qwen-f32-add-owner-v8",
    "history": {
        "v6_runner": "npu/version_0820/scripts/run-qwen-f32-add-owner-v6.sh",
        "runner_sha256":
            "1434e50e3de99b22f32a9f16cc34451c1693f9ce007babd2389dec06f95b1d70",
        "v6_contract_sha256":
            "86767679b08371fef83479fc21dc9200e0f4431835d3abfab57ba218aa7c5945",
        "v6_material_sha256":
            "1a691bac99b4d8c1dba7cd20df25d2463aac83d48bb4f3dada00561c90cb121a",
        "v6_verilator_log_sha256":
            "8e6627fc29a38368dcfcb44b1fdb5607e9a8ff05da63ab5c6704ed94093aca43",
        "v6_raw_verfiles_sha256":
            "797280ecd00772586392cae7f8d6ce260aaec29b14497ad5e45890864646752c",
        "v6_run_status_sha256":
            "1edbc5331002f76fdbb85eccdc8c5c5e010c027ef8920e9d77f0d04be761d240",
        "v7_contract_sha256":
            "805a429bdc777e74f08c2c7ed9e250bb56ffefeeca112c37cfd8f68d3400f026",
        "v7_state": "immutable-zero-action-material-enoent-gap",
    },
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
    resolve_tools
    {
        printf 'bash_path=%s\n' "$TOOL_BASH"
        printf 'python_path=%s\n' "$TOOL_PYTHON"
        printf 'make_path=%s\n' "$TOOL_MAKE"
        printf 'cxx_path=%s\n' "$TOOL_CXX"
        printf 'ar_path=%s\n' "$TOOL_AR"
        printf 'verilator_path=%s\n' "$TOOL_VERILATOR"
        printf 'verilator_bin_path=%s\n' "$TOOL_VERILATOR_BIN"
        printf 'verilator_root=%s\n' "$VERILATOR_ROOT"
        sha256sum "$TOOL_BASH" "$TOOL_PYTHON" "$TOOL_MAKE" \
            "$TOOL_CXX" "$TOOL_AR" "$TOOL_VERILATOR" \
            "$TOOL_VERILATOR_BIN"
        "$TOOL_BASH" --version
        "$TOOL_PYTHON" --version
        "$TOOL_MAKE" --version
        "$TOOL_CXX" --version
        "$TOOL_AR" --version
        "$TOOL_VERILATOR" --version
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

write_backend_makefile() {
    local output="$1"
    resolve_tools
    python3 - \
        "$output" "$TOOL_CXX" "$TOOL_AR" "$VERILATOR_ROOT" \
        "$BACKEND_SOURCE" "$LLAMA_SOURCE" "$LLAMA_BIN" \
        "$VERILATED_DIR" "$BACKEND_BUILD" <<'PY'
import pathlib
import sys

output, cxx, ar, verilator_root, backend_source, llama_source, llama_bin, \
    verilated_dir, backend_build = sys.argv[1:]
text = f"""SHELL := /bin/bash
.DELETE_ON_ERROR:

CXX := {cxx}
AR := {ar}
VERILATOR_ROOT := {verilator_root}
BACKEND_SOURCE := {backend_source}
LLAMA_SOURCE := {llama_source}
LLAMA_BIN := {llama_bin}
VERILATED_DIR := {verilated_dir}
BACKEND_BUILD := {backend_build}
OBJ_DIR := $(BACKEND_BUILD)/obj

MODEL_ARCHIVE := $(VERILATED_DIR)/VTensorNpuCoprocessor__ALL.a
RUNNER_OBJ := $(OBJ_DIR)/npu-verilator-runner.o
VERILATED_OBJ := $(OBJ_DIR)/verilated.o
VERILATED_THREADS_OBJ := $(OBJ_DIR)/verilated_threads.o
MODULE_OBJ := $(OBJ_DIR)/ggml-npu.o
TEST_OBJ := $(OBJ_DIR)/test-backend.o
MODULE := $(BACKEND_BUILD)/libggml-npu.so
TEST := $(BACKEND_BUILD)/test-npu-backend

COMMON_FLAGS := -std=c++17 -O3 -DNDEBUG -march=native -fPIC
WARN_FLAGS := -Wall -Wextra -Wpedantic
VERILATED_INCLUDES := -isystem $(VERILATED_DIR) -isystem $(VERILATOR_ROOT)/include -isystem $(VERILATOR_ROOT)/include/vltstd
GGML_INCLUDES := -I$(LLAMA_SOURCE)/ggml/include -I$(LLAMA_SOURCE)/ggml/src
RPATH_FLAG := -Wl,-rpath,$(LLAMA_BIN)

.PHONY: all
all: $(MODULE) $(TEST)

$(RUNNER_OBJ): $(BACKEND_SOURCE)/npu-verilator-runner.cpp $(BACKEND_SOURCE)/npu-verilator-runner.h $(VERILATED_DIR)/VTensorNpuCoprocessor.h
\t$(CXX) $(COMMON_FLAGS) $(WARN_FLAGS) $(VERILATED_INCLUDES) -I$(BACKEND_SOURCE) -c $(BACKEND_SOURCE)/npu-verilator-runner.cpp -o $(RUNNER_OBJ)

$(VERILATED_OBJ): $(VERILATOR_ROOT)/include/verilated.cpp
\t$(CXX) $(COMMON_FLAGS) -w $(VERILATED_INCLUDES) -c $(VERILATOR_ROOT)/include/verilated.cpp -o $(VERILATED_OBJ)

$(VERILATED_THREADS_OBJ): $(VERILATOR_ROOT)/include/verilated_threads.cpp
\t$(CXX) $(COMMON_FLAGS) -w $(VERILATED_INCLUDES) -c $(VERILATOR_ROOT)/include/verilated_threads.cpp -o $(VERILATED_THREADS_OBJ)

$(MODULE_OBJ): $(BACKEND_SOURCE)/ggml-npu.cpp $(BACKEND_SOURCE)/npu-audit-api.h $(BACKEND_SOURCE)/npu-verilator-runner.h
\t$(CXX) $(COMMON_FLAGS) $(WARN_FLAGS) -DGGML_BACKEND_DL -DGGML_BACKEND_BUILD -DGGML_BACKEND_SHARED -DGGML_SHARED $(GGML_INCLUDES) -I$(BACKEND_SOURCE) -c $(BACKEND_SOURCE)/ggml-npu.cpp -o $(MODULE_OBJ)

$(TEST_OBJ): $(BACKEND_SOURCE)/test-backend.cpp $(BACKEND_SOURCE)/npu-audit-api.h
\t$(CXX) $(COMMON_FLAGS) $(WARN_FLAGS) -I$(LLAMA_SOURCE)/ggml/include -I$(BACKEND_SOURCE) -c $(BACKEND_SOURCE)/test-backend.cpp -o $(TEST_OBJ)

$(MODULE): $(MODULE_OBJ) $(RUNNER_OBJ) $(VERILATED_OBJ) $(VERILATED_THREADS_OBJ) $(MODEL_ARCHIVE)
\t$(CXX) -shared -o $(MODULE) $(MODULE_OBJ) $(RUNNER_OBJ) $(VERILATED_OBJ) $(VERILATED_THREADS_OBJ) $(MODEL_ARCHIVE) -L$(LLAMA_BIN) -lggml-base -pthread -ldl $(RPATH_FLAG)

$(TEST): $(TEST_OBJ)
\t$(CXX) -o $(TEST) $(TEST_OBJ) -L$(LLAMA_BIN) -lggml -lggml-base -pthread -ldl $(RPATH_FLAG)
"""
pathlib.Path(output).write_text(text)
PY
}

run_static_source_audit() {
    local output="$COMPILER_ROOT/static-source-audit.json"
    python3 - "$REPO_ROOT" "$BACKEND_MK" "$output" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
backend_mk = pathlib.Path(sys.argv[2]).read_text()
output = pathlib.Path(sys.argv[3])
npu = root / "npu/version_0820"
runner = npu / "scripts/run-qwen-f32-add-owner-v8.sh"
runner_text = runner.read_text()

expected = [
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
for relative in expected:
    if not (root / relative).is_file():
        raise SystemExit("missing frozen RTL source: " + relative)

array_match = re.search(r"RTL_SOURCES_REL=\((.*?)\n\)", runner_text, re.S)
if array_match is None:
    raise SystemExit("missing frozen runner RTL array")
actual = [line.strip() for line in array_match.group(1).splitlines()
          if line.strip()]
if actual != expected or len(set(actual)) != 21:
    raise SystemExit("runner RTL membership mismatch")

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
runner_cpp = (npu / "runtime/llama-npu-backend/npu-verilator-runner.cpp").read_text()
markers = [
    (top, "u_vector_f32_adapter", 1),
    (top, "macro_cmd_ready_o", 3),
    (adapter, "u_f32_tensor_alu", 1),
    (adapter, "COMMAND_FLAGS_V1", 2),
    (backend, "npu_is_exact_f32_add", 3),
    (backend, "npu_backend_graph_compute", 2),
    (backend, "required_successfully_covered", 6),
    (test, "[NPU-BACKEND-F32-ADD][PASS]", 1),
    (test, "snapshot.required_seen == 1", 1),
    (test, "snapshot.assigned_to_npu == 1", 1),
    (test, "snapshot.required_enqueued == 1", 1),
    (test, "snapshot.required_successfully_covered == 1", 1),
    (test, "result.commands_terminal_success == 0", 1),
    (runner_cpp, "kCompletionBackpressureCycles = 4", 1),
    (runner_cpp, "result_->completion_stable = false", 2),
    (api, "GGML_NPU_F32_ADD_SELF_TEST_ABI_VERSION 2u", 1),
]
for text, marker, minimum in markers:
    if text.count(marker) < minimum:
        raise SystemExit("source marker missing: " + marker)

for stale in ("src0_window_perm_q", "src1_window_perm_q",
              "dst_window_perm_q"):
    if stale in adapter:
        raise SystemExit("stale two-bit resident permission: " + stale)
semantic_permission_counts = {
    "src0_window_readable_q": 4,
    "src1_window_readable_q": 4,
    "dst_window_writable_q": 4,
}
for marker, expected_count in semantic_permission_counts.items():
    if adapter.count(marker) != expected_count:
        raise SystemExit("semantic permission cardinality mismatch: " + marker)
for capture in (
    "src0_window_readable_q <= src0_window_perm_i[0];",
    "src1_window_readable_q <= src1_window_perm_i[0];",
    "dst_window_writable_q <= dst_window_perm_i[1];",
):
    if adapter.count(capture) != 1:
        raise SystemExit("semantic permission capture mismatch: " + capture)
owner_contract = (npu / "docs/QWEN_F32_ADD_OWNER_RTL_CONTRACT.md").read_text()
for marker in (
    "## 8. v8 semantic-permission repair",
    "### 8.7 阶段 2e：RTL/evidence topology（九项）",
    "immutable 25-row legacy warning census",
):
    if owner_contract.count(marker) != 1:
        raise SystemExit("v8 owner contract freeze missing: " + marker)

for path in [
    npu / "runtime/llama-npu-backend/npu-verilator-runner.cpp",
    npu / "runtime/llama-npu-backend/ggml-npu.cpp",
    npu / "runtime/llama-npu-backend/test-backend.cpp",
]:
    text = path.read_text()
    for pattern in [r"\bfloat\s+[A-Za-z_]", r"\bdouble\s+[A-Za-z_]",
                    r"ggml_compute_forward_", r"\bcblas_", r"\bBLAS\b"]:
        if re.search(pattern, text):
            raise SystemExit("forbidden host arithmetic marker: " +
                             path.name + ":" + pattern)

for framework in ("cm" + "ake", "nin" + "ja"):
    if framework in runner_text.lower() or framework in backend_mk.lower():
        raise SystemExit("forbidden build framework dependency: " + framework)

required_mk = [
    "COMMON_FLAGS := -std=c++17 -O3 -DNDEBUG -march=native -fPIC",
    "-DGGML_BACKEND_DL -DGGML_BACKEND_BUILD -DGGML_BACKEND_SHARED -DGGML_SHARED",
    "npu-verilator-runner.cpp",
    "verilated.cpp",
    "verilated_threads.cpp",
    "ggml-npu.cpp",
    "test-backend.cpp",
    "VTensorNpuCoprocessor__ALL.a",
    "libggml-npu.so",
    "test-npu-backend",
    "-lggml-base",
    "-lggml -lggml-base",
]
for token in required_mk:
    if token not in backend_mk:
        raise SystemExit("backend.mk token missing: " + token)

payload = {
    "schema": "qwen-f32-add-owner-v8-static-source-audit-v1",
    "rtl_sources": expected,
    "rtl_source_count": 21,
    "f32_membership_count": 13,
    "adapter_count": 1,
    "top_count": 1,
    "legacy_membership_count": 6,
    "macro_capability_epoch": 1,
    "semantic_permission_registers": semantic_permission_counts,
    "two_bit_resident_permission_registers": 0,
    "host_tensor_arithmetic_markers": 0,
    "direct_build_only": True,
    "backend_makefile": "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v8/backend.mk",
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
for marker in [
    "nodes=1711", "compute=959", "mover=120", "metadata=632",
    "manifest_sha256=49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474",
    "cleanup_rc=0", "evidence_complete=1",
]:
    if receipt.count(marker) != 1:
        raise SystemExit("manifest receipt marker mismatch: " + marker)

payload = {
    "schema": "qwen-f32-add-owner-v8-manifest-audit-v1",
    "manifest_sha256": envelope["manifest_sha256"],
    "counts": counts,
    "canonical_f32_add_16_count": len(matching),
    "canonical_ids": sorted(matching),
    "remaining_compute_mover_gap": 1078,
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_history_audit() {
    local output="$COMPILER_ROOT/history-audit.json"
    python3 - "$NPU_ROOT" "$output" <<'PY'
import hashlib
import json
import pathlib
import sys

npu = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
records = {
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v6.json":
        "86767679b08371fef83479fc21dc9200e0f4431835d3abfab57ba218aa7c5945",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v6-material.md":
        "1a691bac99b4d8c1dba7cd20df25d2463aac83d48bb4f3dada00561c90cb121a",
    "npu/version_0820/scripts/run-qwen-f32-add-owner-v6.sh":
        "1434e50e3de99b22f32a9f16cc34451c1693f9ce007babd2389dec06f95b1d70",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v6/verilator.log":
        "8e6627fc29a38368dcfcb44b1fdb5607e9a8ff05da63ab5c6704ed94093aca43",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v6/run.status":
        "1edbc5331002f76fdbb85eccdc8c5c5e010c027ef8920e9d77f0d04be761d240",
    "npu/version_0820/tmp/build/qwen-f32-add-owner-v6/verilated/VTensorNpuCoprocessor__verFiles.dat":
        "797280ecd00772586392cae7f8d6ce260aaec29b14497ad5e45890864646752c",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v7.json":
        "805a429bdc777e74f08c2c7ed9e250bb56ffefeeca112c37cfd8f68d3400f026",
    "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v8-material.md":
        "70d0a445604d5373ebb11020316872397de5a081076103def5cc2d463a109cbc",
}
root = npu.parents[1]
for relative, expected in records.items():
    path = root / relative
    if not path.is_file():
        raise SystemExit("missing historical binding: " + relative)
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit("historical hash drift: " + relative)
status = npu / "tmp/logs/qwen-f32-add-owner-v6/run.status"
if status.read_text() != \
        "FAIL rc=1 stage=direct-build-evidence-audit evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("v6 final status drift")
if (npu / "tmp/logs/qwen-f32-add-owner-v6/build.count").read_text() != "1\n":
    raise SystemExit("v6 build identity count drift")
for name in ("positive.log", "unknown-kernel.log",
             "out-of-range-4mod8.log", "req-ready-low.log"):
    if (npu / "tmp/logs/qwen-f32-add-owner-v6" / name).exists():
        raise SystemExit("v6 unexpectedly invoked binary: " + name)
material = (npu / "tmp/contracts/qwen-f32-add-owner-v8-material.md").read_text()
material_normalized = " ".join(material.split())
for marker in (
    "v7 performed no RTL/doc/runner write, no preflight, and no build",
    "it is an immutable coordination GAP and must not be resumed",
):
    if material_normalized.count(marker) != 1:
        raise SystemExit("v7 zero-action GAP material drift")
output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-history-audit-v1",
    "v6": {
        "build_count": 1,
        "status": status.read_text().strip(),
        "binary_invocations": 0,
        "immutable_hashes": records,
    },
    "v7": {
        "contract_sha256": records[
            "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v7.json"],
        "state": "immutable-zero-action-material-enoent-gap",
        "writes": 0,
        "preflights": 0,
        "builds": 0,
    },
}, sort_keys=True, indent=2) + "\n")
PY
}

write_expected_warning_census() {
    local output="$COMPILER_ROOT/expected-warning-census.tsv"
    python3 - "$output" <<'PY'
import pathlib
import sys

rows = [
    ("IMPORTSTAR", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv", 1, 16),
    ("IMPORTSTAR", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv", 2, 15),
    ("IMPORTSTAR", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv", 1, 16),
    ("IMPORTSTAR", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv", 2, 15),
    ("IMPORTSTAR", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv", 1, 15),
    ("UNUSEDPARAM", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv", 25, 31),
    ("UNUSEDPARAM", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv", 130, 28),
    ("UNUSEDPARAM", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv", 373, 41),
    ("UNUSEDPARAM", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv", 458, 36),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv", 27, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv", 28, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv", 7, 28),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv", 9, 28),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv", 25, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv", 26, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv", 23, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv", 24, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv", 21, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv", 22, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv", 19, 9),
    ("UNUSEDSIGNAL", "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv", 20, 9),
    ("UNOPTFLAT", "npu/version_0820/rtl/TensorNpuFp32AddMul.v", 41, 31),
    ("UNOPTFLAT", "npu/version_0820/rtl/TensorNpuFp32AddMul.v", 43, 31),
    ("UNOPTFLAT", "npu/version_0820/rtl/TensorNpuFp32AddMul.v", 45, 31),
    ("UNOPTFLAT", "npu/version_0820/rtl/TensorNpuFp32AddMul.v", 47, 32),
]
pathlib.Path(sys.argv[1]).write_text("".join(
    f"{category}\t{path}\t{line}\t{column}\n"
    for category, path, line, column in rows))
PY
}

run_warning_parser_self_test() {
    local expected="$COMPILER_ROOT/expected-warning-census.tsv"
    local output="$COMPILER_ROOT/warning-parser-self-test.json"
    python3 - "$REPO_ROOT" "$expected" "$output" <<'PY'
import collections
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
expected_path = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
expected = []
for line in expected_path.read_text().splitlines():
    category, path, line_no, column = line.split("\t")
    expected.append((category, path, int(line_no), int(column)))
if len(expected) != 25 or len(set(expected)) != 25:
    raise SystemExit("expected warning census cardinality mismatch")

classes = {
    "legacy_fpu_sp": set(expected[:21]),
    "legacy_fp32_addmul": set(expected[21:]),
}

def compare(actual, class_map=classes):
    class_sets = list(class_map.values())
    if any(class_sets[left] & class_sets[right]
           for left in range(len(class_sets))
           for right in range(left + 1, len(class_sets))):
        return False
    if set().union(*class_sets) != set(expected):
        return False
    return collections.Counter(actual) == collections.Counter(expected)

primary = re.compile(
    r"^%Warning-([A-Z0-9_]+):\s+(.+?):([0-9]+):([0-9]+):")

def parse(text):
    rows = []
    for raw in text.splitlines():
        match = primary.match(raw)
        if match is None:
            continue
        path = pathlib.Path(match.group(2)).resolve()
        try:
            relative = path.relative_to(root).as_posix()
        except ValueError as exc:
            raise SystemExit("warning path outside repository") from exc
        rows.append((match.group(1), relative,
                     int(match.group(3)), int(match.group(4))))
    return rows

baseline_text = "".join(
    f"%Warning-{category}: {root / path}:{line}:{column}: fixture\n"
    for category, path, line, column in expected)
baseline = parse(baseline_text)
if not compare(baseline):
    raise SystemExit("baseline warning census rejected")

fixtures = {}
mutations = {
    "missing": baseline[:-1],
    "extra": baseline + [("WIDTH", "npu/version_0820/rtl/TensorNpuCoprocessor.v", 1, 1)],
    "duplicate": baseline + [baseline[0]],
    "path_substitution": [(baseline[0][0],
                           "npu/version_0820/third_party/fpu-sp/verilog/src/float/substituted.sv",
                           baseline[0][2], baseline[0][3])] + baseline[1:],
    "line_substitution": [(baseline[0][0], baseline[0][1],
                           baseline[0][2] + 1, baseline[0][3])] + baseline[1:],
    "category_substitution": [("WIDTH", baseline[0][1],
                               baseline[0][2], baseline[0][3])] + baseline[1:],
}
for name, rows in mutations.items():
    fixtures[name] = not compare(rows)
collision = {name: set(rows) for name, rows in classes.items()}
collision["legacy_fp32_addmul"].add(expected[0])
fixtures["class_collision"] = not compare(baseline, collision)
if not all(fixtures.values()):
    raise SystemExit("warning comparator mutation was not rejected")

output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-warning-parser-self-test-v2",
    "baseline_accepted": True,
    "expected_row_count": len(expected),
    "class_counts": {name: len(rows) for name, rows in classes.items()},
    "mutations_rejected": fixtures,
}, sort_keys=True, indent=2) + "\n")
PY
}

run_membership_comparator_self_test() {
    local output="$COMPILER_ROOT/membership-comparator-self-test.json"
    resolve_tools
    python3 - \
        "$REPO_ROOT" "$RUNNER" "$VERILATOR_ROOT" \
        "$TOOL_VERILATOR_BIN" "$output" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
runner = pathlib.Path(sys.argv[2])
verilator_root = pathlib.Path(sys.argv[3]).resolve()
verilator_bin = pathlib.Path(sys.argv[4]).resolve()
output = pathlib.Path(sys.argv[5])
if (verilator_root / "include/verilated_std.sv").resolve() != \
        pathlib.Path("/usr/share/verilator/include/verilated_std.sv"):
    raise SystemExit("preflight control source identity mismatch")
if verilator_bin != pathlib.Path("/usr/bin/verilator_bin"):
    raise SystemExit("preflight tool identity mismatch")
match = re.search(r"RTL_SOURCES_REL=\((.*?)\n\)", runner.read_text(), re.S)
if match is None:
    raise SystemExit("missing runner RTL source array")
design_rel = [line.strip() for line in match.group(1).splitlines()
              if line.strip()]
if len(design_rel) != 21 or len(set(design_rel)) != 21:
    raise SystemExit("ordered design membership cardinality mismatch")
classes = {
    "design": {str((root / item).resolve()) for item in design_rel},
    "control": {str((verilator_root /
                     "include/verilated_std.sv").resolve())},
    "tool": {str(verilator_bin)},
}
baseline = (sorted(classes["design"]) + sorted(classes["control"]) +
            sorted(classes["tool"]))

def compare(actual, class_map=classes):
    if len(actual) != len(set(actual)):
        return False
    sets = list(class_map.values())
    if any(sets[left] & sets[right]
           for left in range(len(sets))
           for right in range(left + 1, len(sets))):
        return False
    return set(actual) == set().union(*sets)

if not compare(baseline):
    raise SystemExit("baseline membership rejected")
mutations = {
    "missing": not compare(baseline[:-1]),
    "extra": not compare(baseline + [str(root / "npu/version_0820/rtl/extra.v")]),
}
substitution = list(baseline)
substitution[0] = str(root / "npu/version_0820/rtl/substituted.v")
mutations["substitution"] = not compare(substitution)
collision = {name: set(rows) for name, rows in classes.items()}
collision["control"].add(next(iter(classes["design"])))
mutations["class_collision"] = not compare(baseline, collision)
if not all(mutations.values()):
    raise SystemExit("membership comparator mutation was not rejected")
output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-membership-comparator-self-test-v1",
    "baseline_accepted": True,
    "ordered_design_rows": design_rel,
    "class_counts": {name: len(rows) for name, rows in classes.items()},
    "mutations_rejected": mutations,
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
    [[ $rc -eq 1 ]] || fail "early EXIT probe rc=$rc expected=1"
    [[ "$(sed -n '1p' "$early_status")" == \
       "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0" ]] ||
        fail "early EXIT probe status mismatch"

    set +e
    bash "$RUNNER" --internal-probe term-signal "$signal_status"
    rc=$?
    set -e
    [[ $rc -eq 143 ]] || fail "TERM probe rc=$rc expected=143"
    [[ "$(sed -n '1p' "$signal_status")" == \
       "FAIL rc=143 stage=probe-term-signal evidence_complete=0 cleanup_rc=0 signal=TERM" ]] ||
        fail "TERM probe status mismatch"

    set +e
    bash "$RUNNER" --internal-probe cleanup-failure "$cleanup_status"
    rc=$?
    set -e
    [[ $rc -eq 9 ]] || fail "cleanup probe rc=$rc expected=9"
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
    "schema": "qwen-f32-add-owner-v8-runner-probes-v1",
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
        "f91a471770142dbcd7207e500808eade9bf8cb50dc388cf34efe7d7cd0a23e00" \
        "$CONTRACT"
    require_exact_hash \
        "70d0a445604d5373ebb11020316872397de5a081076103def5cc2d463a109cbc" \
        "$MATERIAL"
    require_exact_hash \
        "1434e50e3de99b22f32a9f16cc34451c1693f9ce007babd2389dec06f95b1d70" \
        "$NPU_ROOT/scripts/run-qwen-f32-add-owner-v6.sh"
    require_exact_hash \
        "86767679b08371fef83479fc21dc9200e0f4431835d3abfab57ba218aa7c5945" \
        "$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v6.json"
    require_exact_hash \
        "1a691bac99b4d8c1dba7cd20df25d2463aac83d48bb4f3dada00561c90cb121a" \
        "$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v6-material.md"
    require_exact_hash \
        "805a429bdc777e74f08c2c7ed9e250bb56ffefeeca112c37cfd8f68d3400f026" \
        "$NPU_ROOT/tmp/contracts/qwen-f32-add-owner-v7.json"
    require_exact_hash \
        "8e6627fc29a38368dcfcb44b1fdb5607e9a8ff05da63ab5c6704ed94093aca43" \
        "$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v6/verilator.log"
    require_exact_hash \
        "1edbc5331002f76fdbb85eccdc8c5c5e010c027ef8920e9d77f0d04be761d240" \
        "$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v6/run.status"
    require_exact_hash \
        "797280ecd00772586392cae7f8d6ce260aaec29b14497ad5e45890864646752c" \
        "$NPU_ROOT/tmp/build/qwen-f32-add-owner-v6/verilated/VTensorNpuCoprocessor__verFiles.dat"
    require_exact_hash \
        "43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6" \
        "$STATUS_HELPER"
    require_exact_hash \
        "35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640" \
        "$STATUS_HELPER_TEST"

    while read -r expected relative; do
        require_exact_hash "$expected" "$REPO_ROOT/$relative"
done <<'HASHES'
f4db447eec7305a801d8c15d92fe28f4f580dde1ad3601433eb4690ce52803ef npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h
388d10582253069eab8a703bb8166b1a066abf27b78281278d1bc496c431bf62 npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h
394a09e33d9063a5208479da580ce041ffbbc5b5ea52a74903707785b37df381 npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp
9719c15518e0ae83e45bf0e788802ccb148761e1e5619b5b5cb30eadac4ac2a1 npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp
e14a3f759f81a17e1f05be60e0c670ba869f4263e89771a6d13391b143529f64 npu/version_0820/runtime/llama-npu-backend/test-backend.cpp
83b65127cb9257d0681c5220248a673827e29b0df9a9ff1ff75e1ae7c56e5360 npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
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
906e9c52692e8f902b2dd80d48416b1a5e5b52660b4b4d1911e3cca43b0272f7 npu/version_0820/docs/QWEN_F32_ADD_OWNER_RTL_CONTRACT.md
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
    bash "$STATUS_HELPER_TEST" >"$LOG_ROOT/task-run-status-test.log" 2>&1
    [[ "$(sed -n '1p' "$LOG_ROOT/task-run-status-test.log")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper marker mismatch"

    task_run_status_stage "preflight-direct-template"
    write_backend_makefile "$BACKEND_MK"
    run_static_source_audit
    run_manifest_audit
    run_history_audit
    write_expected_warning_census
    run_warning_parser_self_test
    run_membership_comparator_self_test
    write_source_identity "$SOURCE_IDENTITY"
    write_tool_identity "$TOOL_IDENTITY"

    task_run_status_stage "preflight-runner-probes"
    RUNTIME_TMP=$(mktemp -d "$COMPILER_ROOT/probe-tmp.XXXXXX")
    run_runner_probe_tests
    cleanup_owned_temp
    RUNTIME_TMP=""

    task_run_status_stage "preflight-receipt"
    python3 - \
        "$REPO_ROOT" "$BUILD_ROOT" "$BUILD_COUNT" "$PREFLIGHT_RECEIPT" \
        "$SOURCE_IDENTITY" "$TOOL_IDENTITY" "$BACKEND_MK" \
        "$COMPILER_ROOT/static-source-audit.json" \
        "$COMPILER_ROOT/manifest-audit.json" \
        "$COMPILER_ROOT/history-audit.json" \
        "$COMPILER_ROOT/expected-warning-census.tsv" \
        "$COMPILER_ROOT/warning-parser-self-test.json" \
        "$COMPILER_ROOT/membership-comparator-self-test.json" \
        "$COMPILER_ROOT/runner-probe-audit.json" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
build_root = pathlib.Path(sys.argv[2])
build_count = pathlib.Path(sys.argv[3])
output = pathlib.Path(sys.argv[4])
paths = [pathlib.Path(item) for item in sys.argv[5:]]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if build_root.exists():
    raise SystemExit("preflight created build root")
if build_count.read_text() != "0\n":
    raise SystemExit("preflight build count changed")
payload = {
    "schema": "qwen-f32-add-owner-v8-preflight-receipt-v1",
    "task_id": "qwen-f32-add-owner-v8",
    "contract_json": "npu/version_0820/tmp/contracts/qwen-f32-add-owner-v8.json",
    "contract_sha256":
        "f91a471770142dbcd7207e500808eade9bf8cb50dc388cf34efe7d7cd0a23e00",
    "history": {
        "v6_state": "immutable-fail-after-one-build-before-binary",
        "v6_runner_sha256":
            "1434e50e3de99b22f32a9f16cc34451c1693f9ce007babd2389dec06f95b1d70",
        "v6_contract_sha256":
            "86767679b08371fef83479fc21dc9200e0f4431835d3abfab57ba218aa7c5945",
        "v6_verilator_log_sha256":
            "8e6627fc29a38368dcfcb44b1fdb5607e9a8ff05da63ab5c6704ed94093aca43",
        "v6_raw_verfiles_sha256":
            "797280ecd00772586392cae7f8d6ce260aaec29b14497ad5e45890864646752c",
        "v6_run_status_sha256":
            "1edbc5331002f76fdbb85eccdc8c5c5e010c027ef8920e9d77f0d04be761d240",
        "v7_contract_sha256":
            "805a429bdc777e74f08c2c7ed9e250bb56ffefeeca112c37cfd8f68d3400f026",
        "v7_state": "immutable-zero-action-material-enoent-gap",
    },
    "artifacts": {
        str(path.resolve().relative_to(root)): digest(path) for path in paths
    },
    "build_count": 0,
    "build_root_absent": True,
    "direct_build_plan": {
        "verilator_generations": 1,
        "model_make_j1": 1,
        "backend_make_j1": 1,
        "config_runs": 4,
    },
    "expected_warning_rows": 25,
    "warning_comparator_mutations": 7,
    "membership_comparator_mutations": 4,
    "expected_actual_membership": {
        "design": 21,
        "control": 1,
        "tool": 1,
    },
    "expected_final_status": "PASS",
    "expected_final_status_sha256": hashlib.sha256(b"PASS\n").hexdigest(),
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
    local runner_sha source_sha tool_sha backend_sha dso_base_sha dso_sha
    runner_sha=$(sha256sum "$RUNNER" | sed -n 's/[[:space:]].*//p')
    source_sha=$(sha256sum "$SOURCE_IDENTITY" | sed -n 's/[[:space:]].*//p')
    tool_sha=$(sha256sum "$TOOL_IDENTITY" | sed -n 's/[[:space:]].*//p')
    backend_sha=$(sha256sum "$BACKEND_MK" | sed -n 's/[[:space:]].*//p')
    dso_base_sha=$(sha256sum "$LLAMA_BIN/libggml-base.so" | sed -n 's/[[:space:]].*//p')
    dso_sha=$(sha256sum "$LLAMA_BIN/libggml.so" | sed -n 's/[[:space:]].*//p')
    printf '%s\n' \
        "[NPU-QWEN-F32-ADD-V8][PREFLIGHT-CANDIDATE] build_count=0 build_root_absent=1 v6=immutable-fail v7=immutable-zero-action-gap direct_build=verilator+model_make_j1+backend_make_j1 source_tool_dso=bound membership=21+1+1 warning_census=25-exact warning_mutations=7 membership_mutations=4 probes=pass runner_sha256=$runner_sha source_identity_sha256=$source_sha tool_identity_sha256=$tool_sha backend_mk_sha256=$backend_sha libggml_base_sha256=$dso_base_sha libggml_sha256=$dso_sha"
    finalize_success
}

verify_preflight_receipt() {
    require_file "$PREFLIGHT_STATUS"
    require_file "$PREFLIGHT_RECEIPT"
    require_file "$PREFLIGHT_RECEIPT_HASH"
    [[ "$(sed -n '1p' "$PREFLIGHT_STATUS")" == "PASS" ]] ||
        fail "preflight status is not PASS"
    python3 - \
        "$REPO_ROOT" "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_HASH" \
        "$BUILD_COUNT" "$BUILD_ROOT" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
receipt_path = pathlib.Path(sys.argv[2])
hash_record = pathlib.Path(sys.argv[3]).read_text().split()[0]
build_count = pathlib.Path(sys.argv[4])
build_root = pathlib.Path(sys.argv[5])
if hashlib.sha256(receipt_path.read_bytes()).hexdigest() != hash_record:
    raise SystemExit("preflight receipt hash mismatch")
receipt = json.loads(receipt_path.read_text())
if receipt.get("contract_sha256") != \
        "f91a471770142dbcd7207e500808eade9bf8cb50dc388cf34efe7d7cd0a23e00":
    raise SystemExit("preflight contract binding mismatch")
for relative, expected in receipt.get("artifacts", {}).items():
    path = root / relative
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit("preflight artifact drift: " + relative)
if build_count.read_text() != "0\n":
    raise SystemExit("build count is not zero")
if build_root.exists():
    raise SystemExit("build root is not fresh")
PY
}

record_argv() {
    local output="$1"
    shift
    {
        printf '%q ' "$@"
        printf '\n'
    } >"$output"
}

audit_build_diagnostics() {
    python3 - \
        "$REPO_ROOT" "$COMPILER_ROOT/expected-warning-census.tsv" \
        "$LOG_ROOT/verilator.log" "$LOG_ROOT/model-make.log" \
        "$LOG_ROOT/backend-make.log" \
        "$COMPILER_ROOT/actual-warning-census.tsv" \
        "$COMPILER_ROOT/build-diagnostic-audit.json" <<'PY'
import collections
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
expected_path = pathlib.Path(sys.argv[2])
verilator_log = pathlib.Path(sys.argv[3])
make_logs = [pathlib.Path(sys.argv[4]), pathlib.Path(sys.argv[5])]
actual_path = pathlib.Path(sys.argv[6])
output = pathlib.Path(sys.argv[7])

expected = []
for row in expected_path.read_text().splitlines():
    category, path, line_no, column = row.split("\t")
    expected.append((category, path, int(line_no), int(column)))
if len(expected) != 25 or len(set(expected)) != 25:
    raise SystemExit("expected warning census invalid")

primary_warning = re.compile(
    r"^%Warning-([A-Z0-9_]+):\s+(.+?):([0-9]+):([0-9]+):")
primary_error = re.compile(r"^%Error(?:-[A-Z0-9_]+)?:")
actual = []
verilator_errors = []
for raw in verilator_log.read_text(errors="replace").splitlines():
    warning = primary_warning.match(raw)
    if warning is not None:
        path = pathlib.Path(warning.group(2)).resolve()
        try:
            relative = path.relative_to(root).as_posix()
        except ValueError as exc:
            raise SystemExit("Verilator warning path outside repository") from exc
        actual.append((warning.group(1), relative,
                       int(warning.group(3)), int(warning.group(4))))
    if primary_error.match(raw):
        verilator_errors.append(raw)

if verilator_errors:
    raise SystemExit("Verilator error diagnostic detected")
if collections.Counter(actual) != collections.Counter(expected):
    missing = list((collections.Counter(expected) -
                    collections.Counter(actual)).elements())
    extra = list((collections.Counter(actual) -
                  collections.Counter(expected)).elements())
    raise SystemExit("exact warning census mismatch missing=" + repr(missing) +
                     " extra=" + repr(extra))

legacy_fpu_sp = set(expected[:21])
legacy_fp32_addmul = set(expected[21:])
if legacy_fpu_sp & legacy_fp32_addmul or \
   (legacy_fpu_sp | legacy_fp32_addmul) != set(expected):
    raise SystemExit("warning class collision")

make_pattern = re.compile(
    r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|"
    r"%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
    re.IGNORECASE | re.MULTILINE,
)
make_findings = {}
for path in make_logs:
    matches = [match.group(2) for match in make_pattern.finditer(
        path.read_text(errors="replace"))]
    make_findings[path.name] = matches
if any(make_findings.values()):
    raise SystemExit("generated C++/make/backend diagnostic detected")

actual_path.write_text("".join(
    f"{category}\t{path}\t{line}\t{column}\n"
    for category, path, line, column in actual))
output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-build-diagnostics-v2",
    "expected_warning_rows": len(expected),
    "actual_warning_rows": len(actual),
    "warning_classes": {
        "legacy_fpu_sp": len(legacy_fpu_sp),
        "legacy_fp32_addmul": len(legacy_fp32_addmul),
    },
    "new_source_warning_count": 0,
    "generated_cpp_make_warning_count": 0,
    "error_count": 0,
    "make_files": make_findings,
}, sort_keys=True, indent=2) + "\n")
PY
}

audit_elaboration_membership() {
    local ver_files="$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat"
    require_file "$ver_files"
    resolve_tools
    python3 - \
        "$REPO_ROOT" "$ver_files" "$VERILATOR_ROOT" \
        "$TOOL_VERILATOR_BIN" \
        "$COMPILER_ROOT/elaboration-membership.json" <<'PY'
import json
import pathlib
import shlex
import sys

root = pathlib.Path(sys.argv[1]).resolve()
ver_files = pathlib.Path(sys.argv[2])
verilator_root = pathlib.Path(sys.argv[3]).resolve()
verilator_bin = pathlib.Path(sys.argv[4]).resolve()
output = pathlib.Path(sys.argv[5])
if (verilator_root / "include/verilated_std.sv").resolve() != \
        pathlib.Path("/usr/share/verilator/include/verilated_std.sv"):
    raise SystemExit("Verilator control source identity mismatch")
if verilator_bin != pathlib.Path("/usr/bin/verilator_bin"):
    raise SystemExit("Verilator tool identity mismatch")
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
groups = {
    "design": {str((root / item).resolve()) for item in design_rel},
    "control": {
        str((verilator_root / "include/verilated_std.sv").resolve())},
    "tool": {str(verilator_bin)},
}
raw = []
for line in ver_files.read_text(errors="replace").splitlines():
    fields = shlex.split(line)
    if fields and fields[0] == "S":
        raw.append(str(pathlib.Path(fields[-1]).resolve()))

def compare(actual_rows, classes):
    if len(actual_rows) != len(set(actual_rows)):
        return False
    sets = list(classes.values())
    for left in range(len(sets)):
        for right in range(left + 1, len(sets)):
            if sets[left] & sets[right]:
                return False
    return set(actual_rows) == set().union(*sets)

if not compare(raw, groups):
    expected = set().union(*groups.values())
    raise SystemExit("actual elaboration membership mismatch missing=" +
                     repr(sorted(expected - set(raw))) + " extra=" +
                     repr(sorted(set(raw) - expected)))
if len(raw) != 23 or {name: len(items) for name, items in groups.items()} != {
        "design": 21, "control": 1, "tool": 1}:
    raise SystemExit("actual membership class cardinality mismatch")

mutations = {
    "missing": not compare(raw[:-1], groups),
    "extra": not compare(raw + [str(root / "npu/version_0820/rtl/extra.v")],
                         groups),
}
substitution = list(raw)
substitution[0] = str(root / "npu/version_0820/rtl/substituted.v")
mutations["substitution"] = not compare(substitution, groups)
collision = {name: set(items) for name, items in groups.items()}
collision["control"].add(next(iter(groups["design"])))
mutations["class_collision"] = not compare(raw, collision)
if not all(mutations.values()):
    raise SystemExit("membership mutation was not rejected")

classified = {name: sorted(items) for name, items in groups.items()}
output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-elaboration-membership-v1",
    "raw_s_row_count": len(raw),
    "raw_s_rows": raw,
    "classes": classified,
    "class_counts": {name: len(items) for name, items in classified.items()},
    "f32_membership_count": 13,
    "top_exact_count": 1,
    "adapter_exact_count": 1,
    "legacy_membership_count": 6,
    "mutations_rejected": mutations,
}, sort_keys=True, indent=2) + "\n")
PY
}

audit_direct_build_argv() {
    python3 - \
        "$REPO_ROOT" "$LOG_ROOT/verilator.argv" \
        "$LOG_ROOT/model-make.argv" "$LOG_ROOT/backend-make.argv" \
        "$LOG_ROOT/backend-make.log" \
        "$COMPILER_ROOT/direct-build-argv.json" <<'PY'
import json
import pathlib
import shlex
import sys

root = pathlib.Path(sys.argv[1]).resolve()
verilator_argv_path = pathlib.Path(sys.argv[2])
model_argv_path = pathlib.Path(sys.argv[3])
backend_argv_path = pathlib.Path(sys.argv[4])
backend_log_path = pathlib.Path(sys.argv[5])
output = pathlib.Path(sys.argv[6])
verilator_argv = shlex.split(verilator_argv_path.read_text())
model_argv = shlex.split(model_argv_path.read_text())
backend_argv = shlex.split(backend_argv_path.read_text())

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
design = [str((root / item).resolve()) for item in design_rel]
if verilator_argv[-21:] != design:
    raise SystemExit("Verilator argv RTL order/membership mismatch")
for flag in ["--cc", "-O3", "-Wall", "-Wno-fatal", "--no-assert",
             "--no-trace", "--top-module", "TensorNpuCoprocessor"]:
    if verilator_argv.count(flag) != 1:
        raise SystemExit("Verilator argv flag cardinality mismatch: " + flag)
if "-j1" not in model_argv or model_argv[-1] != \
        "VTensorNpuCoprocessor__ALL.a":
    raise SystemExit("model make argv mismatch")
if "-j1" not in backend_argv or backend_argv[-1] != "all":
    raise SystemExit("backend make argv mismatch")

backend_log = backend_log_path.read_text(errors="replace")
translation_units = [
    str(root / "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"),
    str(root / "npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp"),
    str(root / "npu/version_0820/runtime/llama-npu-backend/test-backend.cpp"),
]
for source in translation_units:
    if backend_log.count(source) != 1:
        raise SystemExit("backend translation unit cardinality mismatch: " + source)
for generated in ("/include/verilated.cpp", "/include/verilated_threads.cpp"):
    if backend_log.count(generated) != 1:
        raise SystemExit("Verilator runtime translation unit mismatch: " + generated)

compiler_rows = [line for line in backend_log.splitlines()
                 if " -c " in line or " -shared " in line]
if len(compiler_rows) != 6:
    raise SystemExit("backend compiler/link argv row count mismatch")
output.write_text(json.dumps({
    "schema": "qwen-f32-add-owner-v8-direct-build-argv-v1",
    "verilator_argv": verilator_argv,
    "model_make_argv": model_argv,
    "backend_make_argv": backend_argv,
    "backend_compiler_argv_rows": compiler_rows,
    "verilator_generation_count": 1,
    "model_make_count": 1,
    "backend_make_count": 1,
}, sort_keys=True, indent=2) + "\n")
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
        printf '%q ' "$binary" "$dso" "$@"
        printf '\n'
    } >"$argv_file"
    printf '%s\n' "$name" >>"$LOG_ROOT/config.sequence"
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
        "$LOG_ROOT/positive.log" "$LOG_ROOT/unknown-kernel.log" \
        "$LOG_ROOT/out-of-range-4mod8.log" \
        "$LOG_ROOT/req-ready-low.log" \
        "$LOG_ROOT/config.sequence" \
        "$COMPILER_ROOT/run-log-audit.json" <<'PY'
import json
import pathlib
import re
import sys

positive, unknown, out_range, timeout = [
    pathlib.Path(item).read_text(errors="replace") for item in sys.argv[1:5]
]
sequence = pathlib.Path(sys.argv[5]).read_text().splitlines()
if sequence != ["unknown-kernel", "out-of-range-4mod8",
                "req-ready-low", "positive"]:
    raise SystemExit("four-config execution order mismatch")
if "[FAIL]" in "".join((positive, unknown, out_range, timeout)):
    raise SystemExit("FAIL marker present in config log")
if positive.count("[NPU-BACKEND-F32-ADD][PASS]") != 1 or \
   positive.count("[NPU-BACKEND-ABI][PASS]") != 1:
    raise SystemExit("positive marker cardinality mismatch")
for key, value in {
    "executed_by_verilator": 1,
    "covered": 1,
    "cpu_fallback": 0,
    "host_tensor_ops": 0,
    "read_bytes": 256,
    "write_bytes": 64,
    "elements": 16,
}.items():
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
    "schema": "qwen-f32-add-owner-v8-run-log-audit-v1",
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
    "negative": negative_result,
    "same_binary_four_configs": True,
    "config_order": sequence,
    "remaining_compute_mover_gap": 1078,
}
pathlib.Path(sys.argv[6]).write_text(
    json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
}

run_execute() {
    task_run_status_stage "execute-preflight-binding"
    verify_preflight_receipt
    verify_source_identity
    verify_tool_identity
    resolve_tools
    [[ "$(sed -n '1p' "$BUILD_COUNT")" == "0" ]] ||
        fail "build count changed before execute"
    [[ ! -e "$BUILD_ROOT" ]] || fail "build root is not fresh"

    task_run_status_stage "execute-build-admission"
    mkdir -p -- "$VERILATED_DIR" "$BACKEND_BUILD/obj"
    printf '1\n' >"$BUILD_COUNT"

    local verilator_command=(
        "$TOOL_VERILATOR"
        --cc -O3 -Wall -Wno-fatal --no-assert --no-trace
        "-I$NPU_ROOT/rtl"
        --Mdir "$VERILATED_DIR"
        --top-module TensorNpuCoprocessor
        -CFLAGS "-O3 -DNDEBUG -march=native -fPIC"
        "${RTL_SOURCES[@]}"
    )
    task_run_status_stage "direct-verilator-generation"
    record_argv "$LOG_ROOT/verilator.argv" "${verilator_command[@]}"
    "${verilator_command[@]}" >"$LOG_ROOT/verilator.log" 2>&1

    local model_make_command=(
        "$TOOL_MAKE" -C "$VERILATED_DIR"
        -f VTensorNpuCoprocessor.mk -j1
        "CXX=$TOOL_CXX" "AR=$TOOL_AR"
        VTensorNpuCoprocessor__ALL.a
    )
    task_run_status_stage "direct-model-make-j1"
    record_argv "$LOG_ROOT/model-make.argv" "${model_make_command[@]}"
    "${model_make_command[@]}" >"$LOG_ROOT/model-make.log" 2>&1

    local backend_make_command=(
        "$TOOL_MAKE" --no-builtin-rules --no-builtin-variables
        -f "$BACKEND_MK" -j1 all
    )
    task_run_status_stage "direct-backend-make-j1"
    record_argv "$LOG_ROOT/backend-make.argv" "${backend_make_command[@]}"
    "${backend_make_command[@]}" >"$LOG_ROOT/backend-make.log" 2>&1
    [[ "$(sed -n '1p' "$BUILD_COUNT")" == "1" ]] ||
        fail "unique build count mismatch"

    task_run_status_stage "direct-build-evidence-audit"
    audit_build_diagnostics
    audit_elaboration_membership
    audit_direct_build_argv
    verify_source_identity
    verify_tool_identity
    require_file "$BACKEND_BUILD/test-npu-backend"
    require_file "$BACKEND_BUILD/libggml-npu.so"
    require_file "$VERILATED_DIR/VTensorNpuCoprocessor__ALL.a"
    require_file "$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat"
    sha256sum \
        "$BACKEND_BUILD/test-npu-backend" \
        "$BACKEND_BUILD/libggml-npu.so" \
        "$VERILATED_DIR/VTensorNpuCoprocessor__ALL.a" \
        "$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat" \
        >"$COMPILER_ROOT/build-artifacts.sha256"

    [[ ! -e "$LOG_ROOT/config.sequence" ]] ||
        fail "configuration sequence already exists"
    task_run_status_stage "config-unknown-kernel"
    run_one_config unknown-kernel --f32-add-unknown-kernel
    task_run_status_stage "config-out-of-range-4mod8"
    run_one_config out-of-range-4mod8 --f32-add-out-of-range
    task_run_status_stage "config-req-ready-low"
    run_one_config req-ready-low --f32-add-req-ready-low
    task_run_status_stage "config-production-graph-compute"
    run_one_config positive

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

identity = {"binary_sha256": digest(binary), "dso_sha256": digest(dso)}
for name in ("positive", "unknown-kernel", "out-of-range-4mod8",
             "req-ready-low"):
    (log_root / (name + ".identity.json")).write_text(json.dumps({
        "schema": "qwen-f32-add-owner-v8-config-identity-v1",
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

root = pathlib.Path(sys.argv[1]).resolve()
logs = pathlib.Path(sys.argv[2])
compiler = pathlib.Path(sys.argv[3])
build_count = pathlib.Path(sys.argv[4])
output = pathlib.Path(sys.argv[5])

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

required = [
    logs / "preflight.status",
    logs / "preflight.receipt.json",
    logs / "preflight.receipt.sha256",
    logs / "task-run-status-test.log",
    logs / "verilator.argv",
    logs / "verilator.log",
    logs / "model-make.argv",
    logs / "model-make.log",
    logs / "backend-make.argv",
    logs / "backend-make.log",
    logs / "config.sequence",
    compiler / "backend.mk",
    compiler / "source-identity.json",
    compiler / "tool-identity.txt",
    compiler / "static-source-audit.json",
    compiler / "manifest-audit.json",
    compiler / "history-audit.json",
    compiler / "expected-warning-census.tsv",
    compiler / "warning-parser-self-test.json",
    compiler / "membership-comparator-self-test.json",
    compiler / "runner-probe-audit.json",
    compiler / "build-diagnostic-audit.json",
    compiler / "actual-warning-census.tsv",
    compiler / "elaboration-membership.json",
    compiler / "direct-build-argv.json",
    compiler / "build-artifacts.sha256",
    compiler / "run-log-audit.json",
]
for name in ("positive", "unknown-kernel", "out-of-range-4mod8",
             "req-ready-low"):
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
    "schema": "qwen-f32-add-owner-v8-final-receipt-v1",
    "task_id": "qwen-f32-add-owner-v8",
    "contract_sha256":
        "f91a471770142dbcd7207e500808eade9bf8cb50dc388cf34efe7d7cd0a23e00",
    "build_count": 1,
    "build_config": "direct-cxx17-O3-NDEBUG-native-PIC/no-assert/no-trace",
    "build_actions": {
        "verilator_generations": 1,
        "model_make_j1": 1,
        "backend_make_j1": 1,
    },
    "warning_census": {
        "legacy_exact_rows": 25,
        "new_source_generated_make_warnings": 0,
        "errors": 0,
    },
    "actual_membership": {
        "design": 21,
        "control": 1,
        "tool": 1,
        "raw_s_rows": 23,
    },
    "config_order": [
        "unknown-kernel", "out-of-range-4mod8",
        "req-ready-low", "positive",
    ],
    "artifacts": {
        str(path.resolve().relative_to(root)): digest(path) for path in required
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
    "expected_final_status_sha256": hashlib.sha256(b"PASS\n").hexdigest(),
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
        "[NPU-QWEN-F32-ADD-V8][PASS-CANDIDATE] build_count=1 configs=4 read=256 write=64 elements=16 remaining_gap=1078"
    finalize_success
}

if [[ "$MODE" == "--preflight" ]]; then
    run_preflight
else
    run_execute
fi
