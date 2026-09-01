#!/usr/bin/env bash
set -euo pipefail

# Qwen canonical F32 ADD/MUL/SUB/SCALE P00--P18 evidence runner.
#
# --preflight is intentionally build-free: it freezes source/tool/DSO identity,
# independently joins the canonical 367-node manifest, runs bounded mutation
# and status/EXIT/signal/cleanup probes, emits the later direct-build plan, and
# proves build_count=0 with no build root.  --execute is a separately authorized
# continuation and performs the only fresh generation/build and binary suite.
# This file never sources, evals, or executes a predecessor runner.

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-v3"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-v3.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
VERILATED_DIR="$BUILD_ROOT/verilated"
BACKEND_BUILD="$BUILD_ROOT/backend"
BACKEND_SOURCE="$NPU_ROOT/runtime/llama-npu-backend"
LLAMA_SOURCE="$NPU_ROOT/third_party/llama.cpp"
LLAMA_BIN="$NPU_ROOT/tmp/build/llama.cpp/bin"
STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v3.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v3-material.md"
MANIFEST="$NPU_ROOT/tmp/logs/qwen-graph-manifest-v5/dispatch.manifest.json"
PROFILE_TOOL="$NPU_ROOT/scripts/qwen_f32_alu_profiles.py"
PROFILE_TEST="$NPU_ROOT/tests/test_qwen_f32_alu_profiles.py"
PREDECESSOR_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-add-owner-v11.sh"
PREDECESSOR_LOG="$NPU_ROOT/tmp/logs/qwen-f32-add-owner-v11"
PREDECESSOR_COMPILER="$NPU_ROOT/tmp/compiler/qwen-f32-add-owner-v11"
PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
RUN_STATUS="$LOG_ROOT/run.status"
BUILD_COUNT="$LOG_ROOT/build.count"
SOURCE_IDENTITY="$COMPILER_ROOT/source-identity.json"
TOOL_IDENTITY="$COMPILER_ROOT/tool-identity.txt"
DSO_IDENTITY="$COMPILER_ROOT/dso-identity.json"
PROFILE_CENSUS="$COMPILER_ROOT/profile-census.json"
PROFILE_MUTATIONS="$COMPILER_ROOT/profile-mutations.json"
STATIC_AUDIT="$COMPILER_ROOT/static-source-audit.json"
COMPARATOR_AUDIT="$COMPILER_ROOT/comparator-self-test.json"
PROCESS_AUDIT="$COMPILER_ROOT/preflight-active-process-audit.json"
FINAL_PROCESS_AUDIT="$COMPILER_ROOT/final-active-process-audit.json"
BACKEND_MK="$COMPILER_ROOT/backend.mk"
EXPECTED_WARNINGS="$COMPILER_ROOT/expected-warning-census.tsv"
ACTUAL_WARNINGS="$COMPILER_ROOT/actual-warning-census.tsv"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"

CONTRACT_SHA256="3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2"
PREDECESSOR_RUNNER_SHA256="3260592a8bdbdd4c8b78d05c662cc97ff98c1e4af48fffd7598a0a31f8a56af8"

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

SOURCE_FILES_REL=(
    .github/AGENTS.md
    .github/instructions/agent-lightweight-workflow.instructions.md
    .github/instructions/rtl-agent-task-contract.instructions.md
    .github/instructions/rtl-generation-workflow.instructions.md
    scripts/task-run-status.sh
    scripts/tests/test-task-run-status.sh
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v1-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v3.json
    npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
    npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_F32_ADD_OWNER_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md
    npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt
    npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h
    npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h
    npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp
    npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp
    npu/version_0820/runtime/llama-npu-backend/test-backend.cpp
    npu/version_0820/scripts/qwen_f32_alu_profiles.py
    npu/version_0820/tests/test_qwen_f32_alu_profiles.py
    npu/version_0820/scripts/run-qwen-f32-alu-families-v3.sh
)
SOURCE_FILES_REL+=("${RTL_SOURCES_REL[@]}")

# shellcheck source=/dev/null
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

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-V3][FAIL] $*" >&2
    return 1
}

cleanup_owned_temp() {
    local cleanup_rc=0
    if [[ -n "$RUNTIME_TMP" && -e "$RUNTIME_TMP" ]]; then
        case "$RUNTIME_TMP" in
            "$COMPILER_ROOT"/probe-tmp.*)
                rm -rf -- "$RUNTIME_TMP" || cleanup_rc=$?
                ;;
            *)
                printf '%s\n' \
                    "[NPU-QWEN-F32-ALU-FAMILIES-V3][FAIL] unsafe cleanup=$RUNTIME_TMP" >&2
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
MODE="$1"

mkdir -p -- "$LOG_ROOT" "$COMPILER_ROOT"
if [[ "$MODE" == "--preflight" ]]; then
    task_run_status_init "$PREFLIGHT_STATUS"
else
    task_run_status_init "$RUN_STATUS"
fi
STATUS_INITIALIZED=1
install_runner_traps

require_file() {
    [[ -f "$1" ]] || fail "missing file=$1"
}

file_sha() {
    sha256sum "$1" | sed -n 's/[[:space:]].*//p'
}

require_exact_hash() {
    local expected="$1"
    local path="$2"
    local actual
    require_file "$path"
    actual=$(file_sha "$path")
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
    VERILATOR_ROOT=$($TOOL_VERILATOR --getenv VERILATOR_ROOT)
    [[ -d "$VERILATOR_ROOT" ]] || fail "invalid VERILATOR_ROOT"
    require_file "$VERILATOR_ROOT/include/verilated.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_threads.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_std.sv"
}

write_source_identity() {
    python3 - "$REPO_ROOT" "$SOURCE_IDENTITY" "${SOURCE_FILES_REL[@]}" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
output = pathlib.Path(sys.argv[2])
files = sys.argv[3:]
rows = {}
for relative in files:
    path = root / relative
    if not path.is_file():
        raise SystemExit("missing source identity input: " + relative)
    rows[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-source-identity-v1",
    "files": rows,
}, sort_keys=True, indent=2) + "\n")
PY
}

verify_source_identity() {
    python3 - "$REPO_ROOT" "$SOURCE_IDENTITY" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
identity = json.loads(pathlib.Path(sys.argv[2]).read_text())
for relative, expected in identity["files"].items():
    path = root / relative
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit("source drift: " + relative)
PY
}

write_tool_identity() {
    {
        printf 'bash=%s\n' "$TOOL_BASH"
        "$TOOL_BASH" --version | sed -n '1p'
        printf 'python=%s\n' "$TOOL_PYTHON"
        "$TOOL_PYTHON" --version
        printf 'make=%s\n' "$TOOL_MAKE"
        "$TOOL_MAKE" --version | sed -n '1p'
        printf 'cxx=%s\n' "$TOOL_CXX"
        "$TOOL_CXX" --version | sed -n '1p'
        printf 'ar=%s\n' "$TOOL_AR"
        "$TOOL_AR" --version | sed -n '1p'
        printf 'verilator=%s\n' "$TOOL_VERILATOR"
        "$TOOL_VERILATOR" --version
        printf 'verilator_bin=%s\n' "$TOOL_VERILATOR_BIN"
        printf 'verilator_root=%s\n' "$VERILATOR_ROOT"
    } >"$TOOL_IDENTITY"
}

write_dso_identity() {
    python3 - "$LLAMA_BIN" "$DSO_IDENTITY" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1])
files = ["libggml-base.so", "libggml.so"]
payload = {}
for name in files:
    path = root / name
    if not path.is_file():
        raise SystemExit("missing pinned DSO: " + str(path))
    payload[name] = hashlib.sha256(path.read_bytes()).hexdigest()
pathlib.Path(sys.argv[2]).write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-dso-identity-v1",
    "files": payload,
}, sort_keys=True, indent=2) + "\n")
PY
}

verify_dso_identity() {
    python3 - "$LLAMA_BIN" "$DSO_IDENTITY" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1])
payload = json.loads(pathlib.Path(sys.argv[2]).read_text())
for name, expected in payload["files"].items():
    path = root / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit("pinned DSO drift: " + name)
PY
}

write_backend_makefile() {
    python3 - \
        "$BACKEND_MK" "$TOOL_CXX" "$BACKEND_SOURCE" "$LLAMA_SOURCE" \
        "$LLAMA_BIN" "$VERILATED_DIR" "$VERILATOR_ROOT" \
        "$BACKEND_BUILD" <<'PY'
import pathlib
import sys
out, cxx, source, llama, llama_bin, verilated, vroot, build = sys.argv[1:]
obj = pathlib.Path(build) / "obj"
common = (
    "-std=c++17 -O3 -DNDEBUG -march=native -fPIC -Wall -Wextra -Wpedantic "
    f"-I{source} -I{llama}/ggml/include -I{llama}/ggml/src "
    f"-I{verilated} -I{vroot}/include -I{vroot}/include/vltstd"
)
defs = "-DGGML_BACKEND_DL -DGGML_BACKEND_BUILD -DGGML_BACKEND_SHARED -DGGML_SHARED"
lines = [
    f"CXX := {cxx}",
    f"COMMON := {common}",
    f"OBJ := {obj}",
    f"MODEL := {verilated}/VTensorNpuCoprocessor__ALL.a",
    "OBJS := $(OBJ)/runner.o $(OBJ)/verilated.o $(OBJ)/verilated_threads.o",
    "all: " + build + "/libggml-npu.so " + build + "/test-npu-backend",
    "$(OBJ):",
    "\tmkdir -p $(OBJ)",
    "$(OBJ)/runner.o: " + source + "/npu-verilator-runner.cpp | $(OBJ)",
    "\t$(CXX) $(COMMON) -c $< -o $@",
    "$(OBJ)/verilated.o: " + vroot + "/include/verilated.cpp | $(OBJ)",
    "\t$(CXX) $(COMMON) -w -c $< -o $@",
    "$(OBJ)/verilated_threads.o: " + vroot + "/include/verilated_threads.cpp | $(OBJ)",
    "\t$(CXX) $(COMMON) -w -c $< -o $@",
    "$(OBJ)/backend.o: " + source + "/ggml-npu.cpp | $(OBJ)",
    f"\t$(CXX) $(COMMON) {defs} -c $< -o $@",
    build + "/libggml-npu.so: $(OBJ)/backend.o $(OBJS) $(MODEL)",
    f"\t$(CXX) -shared -o $@ $(OBJ)/backend.o $(OBJS) $(MODEL) -L{llama_bin} -lggml-base -pthread -ldl -Wl,-rpath,{llama_bin}",
    "$(OBJ)/test.o: " + source + "/test-backend.cpp | $(OBJ)",
    "\t$(CXX) $(COMMON) -c $< -o $@",
    build + "/test-npu-backend: $(OBJ)/test.o",
    f"\t$(CXX) -o $@ $(OBJ)/test.o -L{llama_bin} -lggml -lggml-base -pthread -ldl -Wl,-rpath,{llama_bin}",
    ".PHONY: all",
]
pathlib.Path(out).write_text("\n".join(lines) + "\n")
PY
}

write_active_process_audit() {
    local phase="$1"
    local output="$2"
    python3 - "$TASK_ID" "$BUILD_ROOT" "$phase" "$output" <<'PY'
import json
import pathlib
import sys
task_id, build_root, phase, output = sys.argv[1:]
owned = []
for entry in pathlib.Path("/proc").iterdir():
    if not entry.name.isdigit():
        continue
    try:
        cmd = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
    except OSError:
        continue
    if build_root in cmd and any(token in cmd for token in ("verilator", "make", "test-npu-backend")):
        owned.append({"pid": int(entry.name), "cmdline": cmd})
if owned:
    raise SystemExit("active owned engineering process found")
pathlib.Path(output).write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-active-process-v1",
    "task_id": task_id,
    "phase": phase,
    "owned_background_jobs": 0,
    "matches": owned,
}, sort_keys=True, indent=2) + "\n")
PY
}

run_runner_probes() {
    local early="$RUNTIME_TMP/early.status"
    local term="$RUNTIME_TMP/term.status"
    local cleanup="$RUNTIME_TMP/cleanup.status"
    local rc
    set +e
    bash "$RUNNER" --internal-probe early-exit "$early"
    rc=$?
    set -e
    [[ $rc -eq 1 ]] || fail "early-exit probe rc=$rc"
    set +e
    bash "$RUNNER" --internal-probe term-signal "$term"
    rc=$?
    set -e
    [[ $rc -eq 143 ]] || fail "TERM probe rc=$rc"
    set +e
    bash "$RUNNER" --internal-probe cleanup-failure "$cleanup"
    rc=$?
    set -e
    [[ $rc -eq 9 ]] || fail "cleanup probe rc=$rc"
    python3 - "$early" "$term" "$cleanup" \
        "$COMPILER_ROOT/runner-probe-audit.json" <<'PY'
import json
import pathlib
import sys
early, term, cleanup, output = map(pathlib.Path, sys.argv[1:])
rows = {"early": early.read_text().strip(), "term": term.read_text().strip(),
        "cleanup": cleanup.read_text().strip()}
if not rows["early"].startswith("FAIL rc=1 stage=probe-early-exit evidence_complete=0"):
    raise SystemExit("early status mismatch")
if "FAIL rc=143 stage=probe-term-signal" not in rows["term"] or "signal=TERM" not in rows["term"]:
    raise SystemExit("TERM status mismatch")
if not rows["cleanup"].startswith("FAIL rc=9 stage=probe-cleanup-failure evidence_complete=1 cleanup_rc=9"):
    raise SystemExit("cleanup status mismatch")
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-runner-probes-v1",
    "probes": rows,
    "passed": 3,
}, sort_keys=True, indent=2) + "\n")
PY
}

run_static_audits() {
    python3 "$PROFILE_TOOL" \
        --manifest "$MANIFEST" \
        --output "$PROFILE_CENSUS" \
        --self-test \
        --mutation-output "$PROFILE_MUTATIONS" \
        >"$LOG_ROOT/profile-oracle.log" 2>&1
    python3 "$PROFILE_TEST" --manifest "$MANIFEST" \
        >"$LOG_ROOT/profile-tests.log" 2>&1

    python3 - \
        "$NPU_ROOT" "$PROFILE_CENSUS" "$PROFILE_MUTATIONS" \
        "$STATIC_AUDIT" <<'PY'
import json
import pathlib
import re
import sys
npu = pathlib.Path(sys.argv[1])
census = json.loads(pathlib.Path(sys.argv[2]).read_text())
mutations = json.loads(pathlib.Path(sys.argv[3]).read_text())
adapter = (npu / "rtl/TensorNpuVectorF32Adapter.v").read_text()
top = (npu / "rtl/TensorNpuCoprocessor.v").read_text()
runner = (npu / "runtime/llama-npu-backend/npu-verilator-runner.cpp").read_text()
backend = (npu / "runtime/llama-npu-backend/ggml-npu.cpp").read_text()
test = (npu / "runtime/llama-npu-backend/test-backend.cpp").read_text()
if census["profile_count"] != 19 or census["eligible_identity_count"] != 367:
    raise SystemExit("profile census mismatch")
if census["profile_table_audit"]["op_counts"] != {"ADD": 84, "MUL": 211, "SUB": 18, "SCALE": 54}:
    raise SystemExit("op census mismatch")
if census["canonical_node_identities_completed"] != 1 or census["remaining_gap"] != 1078:
    raise SystemExit("completion separation mismatch")
if mutations["rejected_mutation_count"] != 12:
    raise SystemExit("mutation count mismatch")
profile_ids = {int(item) for item in re.findall(r"5'd(\d+)", adapter)}
if not set(range(19)).issubset(profile_ids):
    raise SystemExit("adapter profile table incomplete")
required_adapter = [
    "reg [1220:0] profile_row_r", "src0_logical_hi_ext_w",
    "profile_src1_present_w ? 2'b01 : 2'b00",
    "expected_gmem_read_bytes_o", "F32_COMMAND_TIMEOUT_CYCLES = 200000000",
]
for token in required_adapter:
    if token not in adapter:
        raise SystemExit("adapter structural token missing: " + token)
if "macro_adapter_read_bytes_w != 64'd256" in top or \
   "macro_adapter_write_bytes_w != 64'd64" in top:
    raise SystemExit("top retains fixed completion accounting")
for token in ("macro_adapter_expected_read_bytes_w",
              "macro_adapter_expected_write_bytes_w",
              "macro_adapter_expected_vector_elements_w"):
    if token not in top:
        raise SystemExit("top expected-counter wire missing")
for token in ("kF32AluMaxClockCycles = 220000000ULL",
              "prepare_identity_oracle", "descriptor_pattern_at_output",
              "npu_verilator_execute_f32_alu"):
    if token not in runner:
        raise SystemExit("runner raw/cycle token missing: " + token)
for token in ("npu_match_f32_alu_profile", "npu_source_allocation",
              "private_shadow", "GGML_NPU_F32_ALU_SELF_TEST_PROC"):
    if token not in backend:
        raise SystemExit("backend metadata/raw token missing: " + token)
for token in ("[NPU-BACKEND-F32-ALU-V3][PASS]",
              "[NPU-BACKEND-F32-ALU-GRAPH][PASS]",
              "--f32-alu-profile", "--f32-alu-negative"):
    if token not in test:
        raise SystemExit("test marker/CLI missing: " + token)
banned = ("reinterpret_cast<float", "static_cast<float", "ggml_compute_forward_",
          "cblas_", "cpu_fallback(")
for name, text in (("runner", runner), ("backend", backend), ("test", test)):
    for token in banned:
        if token in text:
            raise SystemExit(f"forbidden host arithmetic token {token} in {name}")
pathlib.Path(sys.argv[4]).write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-static-source-audit-v1",
    "profile_rows": 19,
    "eligible_identities": 367,
    "op_counts": {"ADD": 84, "MUL": 211, "SUB": 18, "SCALE": 54},
    "permission_rows_per_profile": 64,
    "binary_permission": [1, 1, 2],
    "scale_permission": [1, 0, 2],
    "p18_elements": 262144,
    "p18_cycle_upper_bound": 143654944,
    "child_timeout": 200000000,
    "harness_limit": 220000000,
    "host_float_arithmetic_tokens": 0,
    "canonical_completed": 1,
    "remaining_gap": 1078,
}, sort_keys=True, indent=2) + "\n")
PY

    python3 - \
        "$PREDECESSOR_COMPILER/expected-warning-census.tsv" \
        "$EXPECTED_WARNINGS" "$PROFILE_CENSUS" "$COMPARATOR_AUDIT" <<'PY'
import json
import pathlib
import sys
baseline = pathlib.Path(sys.argv[1]).read_text().splitlines()
if len(baseline) != 25 or len(set(baseline)) != 25:
    raise SystemExit("predecessor warning baseline mismatch")
pathlib.Path(sys.argv[2]).write_text("\n".join(baseline) + "\n")
census = json.loads(pathlib.Path(sys.argv[3]).read_text())
identities = [node["canonical_id"] for row in census["profiles"] for node in row["canonical_nodes"]]
if len(identities) != 367 or len(set(identities)) != 367:
    raise SystemExit("identity baseline mismatch")

def exact(expected, actual):
    return len(actual) == len(set(actual)) and set(expected) == set(actual)

warning_rejects = {
    "missing": not exact(baseline, baseline[:-1]),
    "extra": not exact(baseline, baseline + ["EXTRA\tx\t1\t1"]),
    "duplicate": not exact(baseline, baseline + [baseline[0]]),
}
identity_rejects = {
    "missing": not exact(identities, identities[:-1]),
    "extra": not exact(identities, identities + ["f" * 64]),
    "duplicate": not exact(identities, identities + [identities[0]]),
    "noncanonical": not all(len(value) == 64 for value in identities + ["bad"]),
}
membership = ["design"] * 21 + ["control", "tool"]
membership_rejects = {
    "missing": len(membership[:-1]) != 23,
    "extra": len(membership + ["design"]) != 23,
    "class": membership.count("design") == 21 and membership.count("control") == 1 and membership.count("tool") == 1,
}
if not all(warning_rejects.values()) or not all(identity_rejects.values()) or not all(membership_rejects.values()):
    raise SystemExit("comparator mutation self-test failed")
pathlib.Path(sys.argv[4]).write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-comparator-self-test-v1",
    "warning_rows": 25,
    "warning_rejects": warning_rejects,
    "identity_rows": 367,
    "identity_rejects": identity_rejects,
    "membership": {"design": 21, "control": 1, "tool": 1},
    "membership_rejects": membership_rejects,
}, sort_keys=True, indent=2) + "\n")
PY
}

verify_predecessor() {
    require_exact_hash "$PREDECESSOR_RUNNER_SHA256" "$PREDECESSOR_RUNNER"
    require_file "$PREDECESSOR_LOG/final.receipt.json"
    require_file "$PREDECESSOR_LOG/final.receipt.sha256"
    require_file "$PREDECESSOR_LOG/run.status"
    require_file "$PREDECESSOR_LOG/build.count"
    require_file "$PREDECESSOR_COMPILER/expected-warning-census.tsv"
    python3 - \
        "$PREDECESSOR_LOG/final.receipt.json" \
        "$PREDECESSOR_LOG/final.receipt.sha256" \
        "$PREDECESSOR_LOG/run.status" "$PREDECESSOR_LOG/build.count" <<'PY'
import hashlib
import json
import pathlib
import sys
receipt_path = pathlib.Path(sys.argv[1])
expected = pathlib.Path(sys.argv[2]).read_text().split()[0]
if hashlib.sha256(receipt_path.read_bytes()).hexdigest() != expected:
    raise SystemExit("predecessor receipt hash mismatch")
receipt = json.loads(receipt_path.read_text())
if receipt.get("task_id") != "qwen-f32-add-owner-v11" or receipt.get("build_count") != 1:
    raise SystemExit("predecessor receipt identity mismatch")
if receipt.get("warning_census", {}).get("legacy_exact_rows") != 25:
    raise SystemExit("predecessor warning census mismatch")
if pathlib.Path(sys.argv[3]).read_text() != "PASS\n" or pathlib.Path(sys.argv[4]).read_text() != "1\n":
    raise SystemExit("predecessor terminal status mismatch")
PY
}

write_preflight_receipt() {
    python3 - \
        "$REPO_ROOT" "$BUILD_ROOT" "$BUILD_COUNT" "$PREFLIGHT_RECEIPT" \
        "$SOURCE_IDENTITY" "$TOOL_IDENTITY" "$DSO_IDENTITY" \
        "$PROFILE_CENSUS" "$PROFILE_MUTATIONS" "$STATIC_AUDIT" \
        "$COMPARATOR_AUDIT" "$COMPILER_ROOT/runner-probe-audit.json" \
        "$PROCESS_AUDIT" "$BACKEND_MK" "$EXPECTED_WARNINGS" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
build_root = pathlib.Path(sys.argv[2])
build_count = pathlib.Path(sys.argv[3])
output = pathlib.Path(sys.argv[4])
paths = [pathlib.Path(item) for item in sys.argv[5:]]
if build_root.exists() or build_count.read_text() != "0\n":
    raise SystemExit("preflight build boundary violated")
for path in paths:
    if not path.is_file():
        raise SystemExit("missing receipt artifact: " + str(path))
payload = {
    "schema": "qwen-f32-alu-families-v3-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-v3",
    "contract_sha256": "3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2",
    "artifacts": {
        str(path.resolve().relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in paths
    },
    "build_count": 0,
    "build_root_absent": True,
    "profile_count": 19,
    "eligible_identity_count": 367,
    "op_counts": {"ADD": 84, "MUL": 211, "SUB": 18, "SCALE": 54},
    "permission_truth_table_rows_per_profile": 64,
    "accepted_binary_permission": [1, 1, 2],
    "accepted_scale_permission": [1, 0, 2],
    "representative_transactions_planned": 19,
    "canonical_node_identities_completed": 1,
    "remaining_gap": 1078,
    "p18_elements": 262144,
    "maximum_binary_cycle_upper_bound": 148111392,
    "p18_cycle_upper_bound": 143654944,
    "child_timeout": 200000000,
    "harness_limit": 220000000,
    "direct_build_plan": {
        "verilator_generations": 1,
        "model_make_j1": 1,
        "backend_make_j1": 1,
        "profile_positive_configs": 19,
        "negative_configs": 9,
        "synthetic_graph_profiles": 19,
    },
    "expected_warning_rows": 25,
    "expected_membership": {"design": 21, "control": 1, "tool": 1},
    "owned_background_jobs": 0,
    "expected_final_status": "PASS",
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
    sha256sum "$PREFLIGHT_RECEIPT" >"$PREFLIGHT_RECEIPT_HASH"
}

run_preflight() {
    task_run_status_stage "preflight-input-boundary"
    require_exact_hash "$CONTRACT_SHA256" "$CONTRACT"
    require_file "$MATERIAL"
    require_file "$MANIFEST"
    require_file "$PROFILE_TOOL"
    require_file "$PROFILE_TEST"
    verify_predecessor
    resolve_tools

    task_run_status_stage "preflight-fresh-build"
    [[ ! -e "$BUILD_ROOT" ]] || fail "fresh build root exists=$BUILD_ROOT"
    [[ ! -e "$PREFLIGHT_RECEIPT" ]] || fail "preflight receipt already exists"
    printf '0\n' >"$BUILD_COUNT"

    task_run_status_stage "preflight-task-status-helper"
    bash "$STATUS_HELPER_TEST" >"$LOG_ROOT/task-run-status-test.log" 2>&1
    [[ "$(sed -n '1p' "$LOG_ROOT/task-run-status-test.log")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper marker mismatch"

    task_run_status_stage "preflight-profile-and-static-audits"
    run_static_audits
    write_backend_makefile
    write_source_identity
    write_tool_identity
    write_dso_identity

    task_run_status_stage "preflight-runner-probes"
    RUNTIME_TMP=$(mktemp -d "$COMPILER_ROOT/probe-tmp.XXXXXX")
    run_runner_probes
    cleanup_owned_temp
    RUNTIME_TMP=""

    task_run_status_stage "preflight-process-and-identity"
    write_active_process_audit "preflight" "$PROCESS_AUDIT"
    verify_source_identity
    verify_dso_identity

    task_run_status_stage "preflight-receipt"
    write_preflight_receipt
    local runner_sha receipt_sha identity_sha census_sha
    runner_sha=$(file_sha "$RUNNER")
    receipt_sha=$(file_sha "$PREFLIGHT_RECEIPT")
    identity_sha=$(file_sha "$SOURCE_IDENTITY")
    census_sha=$(file_sha "$PROFILE_CENSUS")
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V3][PREFLIGHT-CANDIDATE] build_count=0 build_root_absent=1 profiles=19 eligible=367 ops=84+211+18+54 permissions=binary-01/01/10,scale-01/00/10 span=allocation-relative scale_raw=exact p18_elements=262144 max_binary_bound=148111392 p18_bound=143654944 child_timeout=200000000 harness_limit=220000000 canonical_completed=1 remaining=1078 mutations=12 comparator=warning+membership+identity signal_exit_cleanup=pass source_tool_dso=bound predecessor=v11-immutable owned_jobs=0 runner_sha256=$runner_sha source_identity_sha256=$identity_sha census_sha256=$census_sha preflight_receipt_sha256=$receipt_sha"
    finalize_success
}

verify_preflight_receipt() {
    require_file "$PREFLIGHT_STATUS"
    require_file "$PREFLIGHT_RECEIPT"
    require_file "$PREFLIGHT_RECEIPT_HASH"
    [[ "$(sed -n '1p' "$PREFLIGHT_STATUS")" == "PASS" ]] ||
        fail "preflight status not PASS"
    python3 - \
        "$REPO_ROOT" "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_HASH" \
        "$BUILD_COUNT" "$BUILD_ROOT" "$CONTRACT_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
receipt_path = pathlib.Path(sys.argv[2])
expected_hash = pathlib.Path(sys.argv[3]).read_text().split()[0]
build_count = pathlib.Path(sys.argv[4])
build_root = pathlib.Path(sys.argv[5])
if hashlib.sha256(receipt_path.read_bytes()).hexdigest() != expected_hash:
    raise SystemExit("preflight receipt hash mismatch")
receipt = json.loads(receipt_path.read_text())
if receipt.get("contract_sha256") != sys.argv[6]:
    raise SystemExit("contract binding mismatch")
for relative, expected in receipt["artifacts"].items():
    path = root / relative
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise SystemExit("preflight artifact drift: " + relative)
if build_count.read_text() != "0\n" or build_root.exists():
    raise SystemExit("execute freshness mismatch")
PY
}

record_argv() {
    local output="$1"
    shift
    python3 - "$output" "$@" <<'PY'
import json
import pathlib
import sys
pathlib.Path(sys.argv[1]).write_text(json.dumps(sys.argv[2:]) + "\n")
PY
}

audit_build_evidence() {
    python3 - \
        "$REPO_ROOT" "$LOG_ROOT/verilator.log" \
        "$LOG_ROOT/model-make.log" "$LOG_ROOT/backend-make.log" \
        "$EXPECTED_WARNINGS" "$ACTUAL_WARNINGS" \
        "$VERILATED_DIR/VTensorNpuCoprocessor__verFiles.dat" \
        "$COMPILER_ROOT/build-audit.json" "${RTL_SOURCES_REL[@]}" <<'PY'
import json
import pathlib
import re
import sys
root = pathlib.Path(sys.argv[1]).resolve()
verilator_log = pathlib.Path(sys.argv[2]).read_text(errors="replace")
model_log = pathlib.Path(sys.argv[3]).read_text(errors="replace")
backend_log = pathlib.Path(sys.argv[4]).read_text(errors="replace")
expected_path = pathlib.Path(sys.argv[5])
actual_path = pathlib.Path(sys.argv[6])
verfiles = pathlib.Path(sys.argv[7]).read_text(errors="replace")
output = pathlib.Path(sys.argv[8])
sources = sys.argv[9:]
if "%Error" in verilator_log or re.search(r"(^|\n)[^\n]*error:", model_log + "\n" + backend_log, re.I):
    raise SystemExit("new build error diagnostic")
if re.search(r"(^|\n)[^\n]*warning:", model_log + "\n" + backend_log, re.I):
    raise SystemExit("new generated/backend make warning")
rows = []
pattern = re.compile(r"^%Warning-([A-Z0-9_]+): (.*?):(\d+):(\d+):", re.M)
for kind, raw_path, line, column in pattern.findall(verilator_log):
    path = pathlib.Path(raw_path)
    try:
        normalized = str(path.resolve().relative_to(root))
    except (OSError, ValueError):
        normalized = raw_path
    rows.append(f"{kind}\t{normalized}\t{line}\t{column}")
rows = sorted(rows)
expected = sorted(expected_path.read_text().splitlines())
if len(rows) != len(set(rows)) or rows != expected:
    raise SystemExit("warning membership drift")
actual_path.write_text("\n".join(rows) + "\n")
missing = [relative for relative in sources if relative not in verfiles]
if missing:
    raise SystemExit("elaboration source missing: " + ",".join(missing))
if "verilated_std.sv" not in verfiles or "verilator_bin" not in verfiles:
    raise SystemExit("control/tool membership missing")
output.write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-build-audit-v1",
    "errors": 0,
    "warning_rows": len(rows),
    "new_source_generated_make_warnings": 0,
    "membership": {"design": len(sources), "control": 1, "tool": 1},
}, sort_keys=True, indent=2) + "\n")
PY
}

run_config() {
    local name="$1"
    shift
    local binary="$BACKEND_BUILD/test-npu-backend"
    local dso="$BACKEND_BUILD/libggml-npu.so"
    local rc
    record_argv "$LOG_ROOT/$name.argv" "$binary" "$dso" "$@"
    set +e
    LD_LIBRARY_PATH="$LLAMA_BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        "$binary" "$dso" "$@" >"$LOG_ROOT/$name.log" 2>&1
    rc=$?
    set -e
    printf '%s\n' "$rc" >"$LOG_ROOT/$name.rc"
    [[ $rc -eq 0 ]] || fail "config=$name rc=$rc"
    printf '%s\n' "$name" >>"$LOG_ROOT/config.sequence"
}

audit_run_logs() {
    python3 - "$LOG_ROOT" "$COMPILER_ROOT/run-log-audit.json" <<'PY'
import json
import pathlib
import sys
logs = pathlib.Path(sys.argv[1])
sequence = (logs / "config.sequence").read_text().splitlines()
expected = [f"profile-{index:02d}" for index in range(19)]
expected += [f"negative-{mode}" for mode in range(1, 10)]
expected += ["synthetic-graph", "legacy-rtl"]
if sequence != expected or len(sequence) != len(set(sequence)):
    raise SystemExit("configuration sequence mismatch")
for name in sequence:
    if (logs / f"{name}.rc").read_text() != "0\n":
        raise SystemExit("nonzero config rc: " + name)
    text = (logs / f"{name}.log").read_text(errors="replace")
    if name.startswith("profile-") or name.startswith("negative-"):
        marker = "[NPU-BACKEND-F32-ALU-V3][PASS]"
    elif name == "synthetic-graph":
        marker = "[NPU-BACKEND-F32-ALU-GRAPH][PASS]"
    else:
        marker = "[NPU-BACKEND-RTL][PASS]"
    if marker not in text or "[FAIL]" in text:
        raise SystemExit("config marker mismatch: " + name)
pathlib.Path(sys.argv[2]).write_text(json.dumps({
    "schema": "qwen-f32-alu-families-v3-run-log-audit-v1",
    "same_binary_configs": len(sequence),
    "profile_positive": 19,
    "negative": 9,
    "synthetic_graph_profiles": 19,
    "cpu_fallback_attempts": 0,
    "host_tensor_ops": 0,
    "canonical_node_identities_completed": 1,
    "remaining_gap": 1078,
}, sort_keys=True, indent=2) + "\n")
PY
}

write_final_receipt() {
    python3 - \
        "$REPO_ROOT" "$LOG_ROOT" "$COMPILER_ROOT" "$BUILD_COUNT" \
        "$BACKEND_BUILD/test-npu-backend" "$BACKEND_BUILD/libggml-npu.so" \
        "$LOG_ROOT/final.receipt.json" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve()
logs = pathlib.Path(sys.argv[2])
compiler = pathlib.Path(sys.argv[3])
build_count = pathlib.Path(sys.argv[4])
binary = pathlib.Path(sys.argv[5])
dso = pathlib.Path(sys.argv[6])
output = pathlib.Path(sys.argv[7])
if build_count.read_text() != "1\n":
    raise SystemExit("final build count mismatch")
required = [
    logs / "preflight.status", logs / "preflight.receipt.json",
    logs / "preflight.receipt.sha256", logs / "verilator.log",
    logs / "model-make.log", logs / "backend-make.log",
    logs / "config.sequence", compiler / "source-identity.json",
    compiler / "tool-identity.txt", compiler / "dso-identity.json",
    compiler / "profile-census.json", compiler / "profile-mutations.json",
    compiler / "static-source-audit.json", compiler / "comparator-self-test.json",
    compiler / "build-audit.json", compiler / "run-log-audit.json",
    compiler / "final-active-process-audit.json", binary, dso,
]
for path in required:
    if not path.is_file():
        raise SystemExit("missing final artifact: " + str(path))
payload = {
    "schema": "qwen-f32-alu-families-v3-final-receipt-v1",
    "task_id": "qwen-f32-alu-families-v3",
    "contract_sha256": "3d2820f3c2be87891421c804f523e88c880358fe1915b310267d58585dc023d2",
    "build_count": 1,
    "build_actions": {"verilator_generations": 1, "model_make_j1": 1, "backend_make_j1": 1},
    "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
    "dso_sha256": hashlib.sha256(dso.read_bytes()).hexdigest(),
    "profile_positive_transactions": 19,
    "negative_transactions": 9,
    "synthetic_graph_transactions": 19,
    "eligible_identity_count": 367,
    "canonical_node_identities_completed": 1,
    "remaining_gap": 1078,
    "cpu_fallback_attempts": 0,
    "host_tensor_ops": 0,
    "warning_census": {"legacy_exact_rows": 25, "new_warnings": 0, "errors": 0},
    "owned_background_jobs": 0,
    "cleanup_rc": 0,
    "expected_final_status": "PASS",
    "artifacts": {
        str(path.resolve().relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in required
    },
}
output.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
PY
    sha256sum "$LOG_ROOT/final.receipt.json" >"$LOG_ROOT/final.receipt.sha256"
}

run_execute() {
    task_run_status_stage "execute-preflight-binding"
    verify_preflight_receipt
    verify_source_identity
    verify_dso_identity
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

    task_run_status_stage "execute-build-audit"
    audit_build_evidence
    require_file "$BACKEND_BUILD/test-npu-backend"
    require_file "$BACKEND_BUILD/libggml-npu.so"
    : >"$LOG_ROOT/config.sequence"

    local profile_id
    for profile_id in $(seq 0 18); do
        task_run_status_stage "profile-positive-$profile_id"
        run_config "$(printf 'profile-%02d' "$profile_id")" \
            --f32-alu-profile "$profile_id"
    done
    local mode
    for mode in $(seq 1 9); do
        task_run_status_stage "negative-mode-$mode"
        case "$mode" in
            3) profile_id=4 ;;
            4) profile_id=15 ;;
            5) profile_id=16 ;;
            6) profile_id=15 ;;
            7|8) profile_id=18 ;;
            *) profile_id=0 ;;
        esac
        run_config "negative-$mode" --f32-alu-negative "$profile_id" "$mode"
    done
    task_run_status_stage "synthetic-19-profile-graph"
    run_config synthetic-graph --f32-alu-graph
    task_run_status_stage "legacy-rtl-smoke"
    run_config legacy-rtl --rtl-self-test

    task_run_status_stage "execute-run-log-audit"
    audit_run_logs
    verify_source_identity
    verify_dso_identity
    write_active_process_audit "execute-final" "$FINAL_PROCESS_AUDIT"
    write_final_receipt
    local receipt_sha binary_sha dso_sha
    receipt_sha=$(file_sha "$LOG_ROOT/final.receipt.json")
    binary_sha=$(file_sha "$BACKEND_BUILD/test-npu-backend")
    dso_sha=$(file_sha "$BACKEND_BUILD/libggml-npu.so")
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V3][PASS-CANDIDATE] build_count=1 profiles=19 negative=9 synthetic_graph=19 eligible=367 canonical_completed=1 remaining=1078 cpu_fallback=0 host_tensor_ops=0 warnings_new=0 errors=0 membership=21+1+1 p18_elements=262144 full_qwen=GAP synthesis_sta_ppa=GAP binary_sha256=$binary_sha dso_sha256=$dso_sha final_receipt_sha256=$receipt_sha"
    finalize_success
}

if [[ "$MODE" == "--preflight" ]]; then
    run_preflight
else
    run_execute
fi
