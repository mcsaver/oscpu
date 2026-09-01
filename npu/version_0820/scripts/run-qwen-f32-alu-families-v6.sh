#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families v6：只做 build-free source/evidence closure。
# 本 runner 不 source/eval/execute v4/v5；--compile/--execute 在当前授权中 fail closed。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-v6"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v6.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v6-material.md"
BUILD_IDENTITY_TOOL="$NPU_ROOT/scripts/qwen_f32_alu_build_identity.py"
BUILD_IDENTITY_TEST="$NPU_ROOT/tests/test_qwen_f32_alu_build_identity.py"
CMAKE_FILE="$NPU_ROOT/runtime/llama-npu-backend/CMakeLists.txt"

PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
BUILD_COUNT="$LOG_ROOT/build.count"
TASK_STATUS_LOG="$LOG_ROOT/task-run-status-test.log"
BUILD_IDENTITY_LOG="$LOG_ROOT/build-identity.log"
BUILD_IDENTITY_TEST_LOG="$LOG_ROOT/build-identity-test.log"
PRE_INPUT_IDENTITY="$COMPILER_ROOT/input-identity.pre.json"
POST_INPUT_IDENTITY="$COMPILER_ROOT/input-identity.post.json"
CMAKE_IDENTITY="$COMPILER_ROOT/cmake-source-identity.json"
STATIC_AUDIT="$COMPILER_ROOT/static-source-audit.json"
HISTORY_AUDIT="$COMPILER_ROOT/history-audit.json"
DSO_IDENTITY="$COMPILER_ROOT/dso-identity.json"
ATOMICITY_AUDIT="$COMPILER_ROOT/atomicity-probes.json"
RUNNER_PROBE_AUDIT="$COMPILER_ROOT/runner-probe-audit.json"
COMPILE_PLAN="$COMPILER_ROOT/future-compile-plan.json"
PROCESS_AUDIT="$COMPILER_ROOT/preflight-active-process-audit.json"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"
BOUND_ARTIFACTS="$LOG_ROOT/preflight.bound-artifacts.json"
EXPECTED_STATUS="$LOG_ROOT/preflight.expected-status"
FINAL_BINDING="$LOG_ROOT/preflight.final-binding.json"

CONTRACT_SHA256="a1542ef8276732158e6d25b5505182a3b4f8293b471bdde371530a9f26050e12"
RUNNER_SOURCE_SHA256="b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e"
V5_RUNNER_SHA256="1317fca7628af5d66aa655b1a65352842fbcc84240cd6b894e50a46c2312dce9"
V5_RECEIPT_SHA256="ba1aa3cf36db4fe174fe641253189cc4e66e7684c5bbbfd8303a0209d65b45c0"
V11_RECEIPT_SHA256="62dd6796f794639da7dac5d350729d41161d85b9412d6a14145e0333b0d3d35e"
IDENTITY_SET_SHA256="d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385"

FROZEN_INPUTS_REL=(
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
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v1.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v2.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v2-material.md
    npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
    npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
    npu/version_0820/rtl/TensorNpuCoprocessor.v
    npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
    npu/version_0820/rtl/TensorNpuF32TensorAlu.v
    npu/version_0820/rtl/TensorNpuFp32AddMul.v
    npu/version_0820/rtl/TensorNpuCommandDecoder.v
    npu/version_0820/rtl/TensorNpuRegisterFile.v
    npu/version_0820/rtl/TensorNpuMm2Engine.v
    npu/version_0820/rtl/TensorNpuDmaEngine.v
    npu/version_0820/rtl/TensorNpuLocalMemory.v
    npu/version_0820/rtl/tensor_npu_defs.vh
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
    npu/version_0820/scripts/qwen_f32_alu_build_identity.py
    npu/version_0820/tests/test_qwen_f32_alu_build_identity.py
    npu/version_0820/scripts/run-qwen-f32-alu-families-v4.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v5.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh
    npu/version_0820/tmp/build/llama.cpp/bin/libggml-base.so
    npu/version_0820/tmp/build/llama.cpp/bin/libggml.so
)

FROZEN_INPUT_DIRS_REL=(
    npu/version_0820/third_party/llama.cpp/ggml/include
    npu/version_0820/third_party/llama.cpp/ggml/src
    npu/version_0820/tmp/logs/qwen-graph-manifest-v5
    npu/version_0820/tmp/logs/qwen-f32-add-owner-v11
    npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v5
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5
)

export PYTHONDONTWRITEBYTECODE=1
export TMPDIR="$COMPILER_ROOT/test-tmp"

# shellcheck source=/dev/null
source "$STATUS_HELPER"

STATUS_INITIALIZED=0
PASS_MARKER_EMITTED=0
FINAL_PASS_VERIFIED=0
FINAL_BINDING_VERIFIED=0
FORCED_CLEANUP_RC=0
ATOMIC_COUNTER=0

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-V6][FAIL] $*" >&2
    return 1
}

finish_on_exit() {
    local command_rc=$?
    local status_rc=0
    trap - EXIT HUP INT TERM
    set +e
    if [[ $STATUS_INITIALIZED -eq 1 && $PASS_MARKER_EMITTED -eq 0 ]]; then
        # 即使 PASS 已短暂写入，只要 marker 前失败/收到 signal，EXIT 仍覆盖成 FAIL。
        if [[ $command_rc -eq 0 && $FORCED_CLEANUP_RC -eq 0 ]]; then
            command_rc=1
        fi
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

atomic_write_text() {
    local output="$1"
    local text_value="$2"
    python3 - "$NPU_ROOT/scripts" "$output" "$text_value" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes
atomic_write_bytes(pathlib.Path(sys.argv[2]), sys.argv[3].encode("utf-8"))
PY
}

publish_temporary_file() {
    local temporary="$1"
    local output="$2"
    python3 - "$NPU_ROOT/scripts" "$temporary" "$output" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes, read_bytes_stable
temporary = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
data = read_bytes_stable(temporary)
atomic_write_bytes(output, data)
temporary.unlink()
PY
}

run_atomic_log() {
    local output="$1"
    shift
    local temporary
    local command_rc=0
    ATOMIC_COUNTER=$((ATOMIC_COUNTER + 1))
    temporary="${output}.tmp.${BASHPID}.${ATOMIC_COUNTER}"
    ( set -o noclobber; : >"$temporary" ) || fail "temporary log collision=$temporary"
    set +e
    "$@" >"$temporary" 2>&1
    command_rc=$?
    set -e
    publish_temporary_file "$temporary" "$output"
    return "$command_rc"
}

file_sha() {
    local digest
    digest=$(sha256sum "$1")
    printf '%s\n' "${digest%% *}"
}

snapshot_inputs() {
    local output="$1"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$output" \
        "${FROZEN_INPUTS_REL[@]}" --directories "${FROZEN_INPUT_DIRS_REL[@]}" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    IdentityError, atomic_write_json, read_bytes_stable, sha256_bytes,
)
output = pathlib.Path(sys.argv[3])
separator = sys.argv.index("--directories")
explicit = sys.argv[4:separator]
directories = sys.argv[separator + 1:]
paths = {}


def add_path(relative):
    relative_path = pathlib.PurePosixPath(relative).as_posix()
    path = root / relative_path
    if relative_path in paths:
        return
    entry_stat = path.lstat()
    if stat.S_ISLNK(entry_stat.st_mode):
        target = os.readlink(path)
        data = target.encode("utf-8")
        resolved = path.resolve(strict=True)
        resolved_data = read_bytes_stable(resolved)
        paths[relative_path] = {
            "type": "symlink",
            "link_target": target,
            "sha256": sha256_bytes(data),
            "resolved_path": str(resolved),
            "resolved_sha256": sha256_bytes(resolved_data),
            "resolved_size_bytes": len(resolved_data),
        }
        return
    data = read_bytes_stable(path)
    json_validated = False
    if path.suffix == ".json":
        json.loads(data)
        json_validated = True
    paths[relative_path] = {
        "type": "regular",
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
        "json_validated_from_same_bytes": json_validated,
    }


for relative in explicit:
    add_path(relative)
for relative_root in directories:
    directory = root / relative_root
    if not directory.is_dir() or directory.is_symlink():
        raise IdentityError(f"frozen input directory invalid: {relative_root}")
    for path in sorted(directory.rglob("*")):
        if path.is_dir() and not path.is_symlink():
            continue
        add_path(path.relative_to(root).as_posix())
aggregate = "".join(
    f"{name}\t{entry['type']}\t{entry['sha256']}\n"
    for name, entry in sorted(paths.items())
).encode("utf-8")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-input-identity-v1",
    "file_count": len(paths),
    "files": paths,
    "directory_roots": directories,
    "identity_sha256": hashlib.sha256(aggregate).hexdigest(),
})
PY
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
        command-failure)
            task_run_status_stage "probe-command-failure"
            return 7
            ;;
        cleanup-failure)
            task_run_status_stage "probe-cleanup-failure"
            task_run_status_mark_evidence_complete
            FORCED_CLEANUP_RC=9
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
        premature-pass)
            task_run_status_stage "probe-premature-pass"
            publish_pass_marker "probe"
            ;;
        status-mismatch)
            task_run_status_stage "probe-status-mismatch"
            task_run_status_mark_evidence_complete
            task_run_status_finalize 0 0
            FINAL_PASS_VERIFIED=1
            python3 - "$NPU_ROOT/scripts" "$status" <<'PY'
import os
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes
status = pathlib.Path(sys.argv[2])
replacement = status.with_name(status.name + ".mismatch")
atomic_write_bytes(replacement, b"MISMATCH\n")
os.replace(replacement, status)
PY
            fail "bound expected/actual status mismatch"
            ;;
        *)
            return 2
            ;;
    esac
}

publish_pass_marker() {
    local receipt_sha="$1"
    [[ $FINAL_PASS_VERIFIED -eq 1 ]] || fail "PASS marker denied before final status verification"
    [[ $FINAL_BINDING_VERIFIED -eq 1 ]] || fail "PASS marker denied before final binding verification"
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V6][PREFLIGHT-PASS] build_count=0 build_root_absent=1 verilator=0 cmake=0 ninja=0 make=0 binary=0 execute=0 sources=21 source_order=exact cmake_command_binding=1 cmake_depends_binding=1 representative_predecessor_passed=1 representative_planned=19 verified_canonical_completed=0 remaining=1079 deadline_edge=GAP event_time_ledger=GAP rtl_dynamic=GAP compile_membership=GAP receipt_sha256=$receipt_sha"
}

if (( $# >= 1 )) && [[ "$1" == "--internal-probe" ]]; then
    [[ $# -eq 3 ]] || exit 2
    run_internal_probe "$2" "$3"
    exit $?
fi

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--compile" && "$1" != "--execute" ]]; then
    printf '%s\n' "usage: bash $RUNNER_REL --preflight|--compile|--execute" >&2
    exit 2
fi

if [[ "$1" == "--compile" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V6][GAP] compile mode is structurally planned but requires a new explicit build authorization; preserved verFiles/depfile audit is not executed" >&2
    exit 2
fi

if [[ "$1" == "--execute" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V6][GAP] execute requires later compile membership PASS and explicit shell ownership authorization" >&2
    exit 2
fi

run_one_probe() {
    local kind="$1"
    local expected_rc="$2"
    local marker="$3"
    local status="$COMPILER_ROOT/runner-probe-$kind.status"
    local log="$COMPILER_ROOT/runner-probe-$kind.log"
    local rc_path="$COMPILER_ROOT/runner-probe-$kind.rc"
    local probe_rc=0
    set +e
    run_atomic_log "$log" bash "$RUNNER" --internal-probe "$kind" "$status"
    probe_rc=$?
    set -e
    [[ $probe_rc -eq $expected_rc ]] ||
        fail "runner probe rc mismatch=$kind expected=$expected_rc actual=$probe_rc"
    [[ "$(sed -n '1p' "$status")" == FAIL* ]] ||
        fail "runner probe did not publish FAIL=$kind"
    [[ "$(sed -n '1p' "$status")" == *"$marker"* ]] ||
        fail "runner probe marker mismatch=$kind marker=$marker"
    if [[ "$kind" == "premature-pass" ]]; then
        [[ "$(sed -n '/PREFLIGHT-PASS/p' "$log")" == "" ]] ||
            fail "premature PASS marker became visible"
    fi
    atomic_write_text "$rc_path" "$probe_rc"$'\n'
}

run_runner_probes() {
    run_one_probe early-exit 1 "evidence_complete=0"
    run_one_probe command-failure 7 "rc=7"
    run_one_probe cleanup-failure 9 "cleanup_rc=9"
    run_one_probe hup-signal 129 "signal=HUP"
    run_one_probe int-signal 130 "signal=INT"
    run_one_probe term-signal 143 "signal=TERM"
    run_one_probe premature-pass 1 "evidence_complete=0"
    run_one_probe status-mismatch 1 "rc=1"
    python3 - "$NPU_ROOT/scripts" "$COMPILER_ROOT" "$RUNNER_PROBE_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable
root = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
expected = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
records = {}
for name, expected_rc in expected.items():
    status = read_bytes_stable(root / f"runner-probe-{name}.status").decode().strip()
    rc = int(read_bytes_stable(root / f"runner-probe-{name}.rc"))
    log = read_bytes_stable(root / f"runner-probe-{name}.log")
    if not status.startswith("FAIL ") or rc != expected_rc:
        raise SystemExit(f"runner probe mismatch: {name}: rc={rc}: {status}")
    if name == "premature-pass" and b"[PREFLIGHT-PASS]" in log:
        raise SystemExit("premature PASS marker visible")
    records[name] = {"return_code": rc, "status": status}
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-runner-probes-v1",
    "pass": True,
    "probe_count": len(records),
    "records": records,
})
PY
}

write_history_audit() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$PRE_INPUT_IDENTITY" \
        "$HISTORY_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_json, read_json_same_bytes

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
snapshot, _, _ = read_json_same_bytes(pathlib.Path(sys.argv[3]))
output = pathlib.Path(sys.argv[4])
files = snapshot["files"]


def digest(relative):
    return files[relative]["sha256"]


fixed = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6.json": "a1542ef8276732158e6d25b5505182a3b4f8293b471bdde371530a9f26050e12",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp": "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v5.sh": "1317fca7628af5d66aa655b1a65352842fbcc84240cd6b894e50a46c2312dce9",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/preflight.receipt.json": "ba1aa3cf36db4fe174fe641253189cc4e66e7684c5bbbfd8303a0209d65b45c0",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/preflight.receipt.sha256": "d90b0f8afbf5e19d38c2de4591bc28a3067c1b0953cf9f5d98a1795b8e287799",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/preflight.status": "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/build.count": "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/final.receipt.json": "62dd6796f794639da7dac5d350729d41161d85b9412d6a14145e0333b0d3d35e",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/final.receipt.sha256": "61d220ed9cc22098d04ac75709638b424c4da9c7294e78e994cbc75dace3b14b",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/run.status": "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/build.count": "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
}
for relative, expected in fixed.items():
    if digest(relative) != expected:
        raise SystemExit(f"fixed predecessor/input hash mismatch: {relative}")

v11_compiler = {
    "actual-warning-census.tsv": "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c",
    "backend.mk": "c3be45187f1aa62f4433734cab188cac206f135aa7577a386d3a03cb0626fba2",
    "build-artifacts.sha256": "7da9e3b004839000fe33c50f6a3bd1be7fb41fea97085dae137b975b893db2b1",
    "build-diagnostic-audit.json": "4f6323f8b53be4b42c110ed3c032185bbd6d1a49c86dd3666c72035c493b793c",
    "direct-build-argv.json": "b60ee2b2c2e07d99a53c364c748e4e2e716c17658e1bf7524029ccbf970939e6",
    "dso-identity.json": "9be7769d40c6b4dc45a245f12889164f5df3614f3c997ca0532684518298ff71",
    "elaboration-membership.json": "f5f1e7ee9793b751c5da4f3901ae4b5d2ff5cfa4f8e602ef0a67a88787a41d3b",
    "expected-warning-census.tsv": "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c",
    "final-active-process-audit.json": "1655ac1db8eddd0c636d4d99be2e51333db1285a5361b08c27c25bd0fb64619c",
    "history-audit.json": "8e6df8defbdaf73f32c6f98b60eb34ce7aa9c509a15f3aea8a5d6071268d9c92",
    "manifest-audit.json": "782e7df7c70266576bd691b939a3fc26b64f5c5e6c6ef7bcfe93693c8cb0ccfb",
    "membership-comparator-self-test.json": "5d95eef5334090d515edf78101fbcab022cbe2df25aeba9d096268bdfea51c79",
    "permission-runtime-audit.json": "42580e5b228933664dc7185d62beec176665352554988126c86cdc5e5f5983f8",
    "post-execute-identity.json": "5a63feab7f01f40f3b86502467e9535e20de140c3bff1f84f5b6d97bff2591a2",
    "preflight-active-process-audit.json": "ac565db2aded41a0cf26e26efa9df238b2ca4cff768f7e49f9a2700ca11575ae",
    "run-log-audit.json": "d8755c8fd81e3408e056372556c22f9fa80047b791203572ebe35bd831dcc323",
    "runner-probe-audit.json": "6afec3d3aa608185ff1e1077d8788319dd4b6a181174735f35b3aa59ae0074b1",
    "source-identity.json": "943084c6cda44cc130610102b6ef021b0a1d5507cc902c847a340fec3371a4ba",
    "static-source-audit.json": "3a1578097f30a640ca811210aba8c2e833a2be7f8b93d88876c46a3b43eba57a",
    "tool-identity.txt": "bbf64a821afe7a314c048ea79e8b52633195eb29d81a2cdca35380cca518604a",
    "warning-parser-self-test.json": "75c8a64a21fb9ef04f65adb140d1cce2f41abf392339877278f1095efa013f24",
}
prefix = "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/"
actual_names = {name[len(prefix):] for name in files if name.startswith(prefix)}
if actual_names != set(v11_compiler):
    raise SystemExit("v11 compiler evidence exact membership mismatch")
for name, expected in v11_compiler.items():
    if digest(prefix + name) != expected:
        raise SystemExit(f"v11 compiler evidence hash mismatch: {name}")

v11_path = root / "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/final.receipt.json"
v11, v11_sha, _ = read_json_same_bytes(v11_path)
if v11_sha != fixed[v11_path.relative_to(root).as_posix()]:
    raise SystemExit("v11 receipt same-bytes hash mismatch")
if (v11.get("task_id") != "qwen-f32-add-owner-v11" or
        v11.get("build_count") != 1 or
        v11.get("actual_membership") != {"control": 1, "design": 21, "raw_s_rows": 23, "tool": 1} or
        v11.get("expected_final_status") != "PASS"):
    raise SystemExit("v11 receipt semantic boundary mismatch")
for name, expected in v11_compiler.items():
    relative = prefix + name
    if v11.get("artifacts", {}).get(relative) != expected:
        raise SystemExit(f"v11 receipt/compiler binding mismatch: {name}")
v11_source_path = root / "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/source-identity.json"
v11_source, v11_source_sha, _ = read_json_same_bytes(v11_source_path)
if v11_source_sha != v11_compiler["source-identity.json"]:
    raise SystemExit("v11 source identity same-bytes hash mismatch")
v11_unchanged_elaboration_sources = [
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
    "npu/version_0820/rtl/TensorNpuCommandDecoder.v",
    "npu/version_0820/rtl/TensorNpuRegisterFile.v",
    "npu/version_0820/rtl/TensorNpuMm2Engine.v",
    "npu/version_0820/rtl/TensorNpuDmaEngine.v",
    "npu/version_0820/rtl/TensorNpuLocalMemory.v",
    "npu/version_0820/rtl/tensor_npu_defs.vh",
]
v11_source_files = v11_source.get("files", {})
for relative in v11_unchanged_elaboration_sources:
    expected = v11_source_files.get(relative)
    if expected is None or digest(relative) != expected:
        raise SystemExit(f"v11-anchored elaboration source drift: {relative}")

v5_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/preflight.receipt.json"
v5, v5_sha, _ = read_json_same_bytes(v5_path)
if v5_sha != fixed[v5_path.relative_to(root).as_posix()]:
    raise SystemExit("v5 receipt same-bytes hash mismatch")
if (v5.get("task_id") != "qwen-f32-alu-families-v5" or
        v5.get("build_count") != 0 or
        v5.get("build_root_absent") is not True or
        v5.get("verified_canonical_node_identities_completed") != 0 or
        v5.get("remaining_nonmetadata_gap") != 1079):
    raise SystemExit("v5 limited predecessor boundary mismatch")
v5_frozen = v5.get("frozen_source_sha256", {})
cpp_relative = "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"
if v5_frozen.get(cpp_relative) != "f7bb26c91d97a3cc42c63cb52e4ce8c6f4f740a4304f27221f2b3c863a74878f":
    raise SystemExit("v5 historical C++ source anchor mismatch")
unchanged_count = 0
for relative, expected in v5_frozen.items():
    if relative == cpp_relative:
        continue
    if digest(relative) != expected:
        raise SystemExit(f"v5 frozen non-C++ source drift: {relative}")
    unchanged_count += 1
for relative, expected in v5.get("artifacts", {}).items():
    if relative.startswith((
        "npu/version_0820/tmp/logs/qwen-f32-alu-families-v5/",
        "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v5/",
        "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/",
    )) and digest(relative) != expected:
        raise SystemExit(f"v5 evidence artifact drift: {relative}")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-history-audit-v1",
    "pass": True,
    "v5": {
        "runner_sha256": fixed["npu/version_0820/scripts/run-qwen-f32-alu-families-v5.sh"],
        "receipt_sha256": v5_sha,
        "build_count": 0,
        "build_root_absent": True,
        "representative_transactions_passed": 1,
        "verified_canonical_node_identities_completed": 0,
        "remaining_nonmetadata_gap": 1079,
        "dynamic_relabel_forbidden": True,
        "unchanged_frozen_source_count": unchanged_count,
        "historical_cpp_sha256": v5_frozen[cpp_relative],
    },
    "v11": {
        "receipt_sha256": v11_sha,
        "compiler_evidence_count": len(v11_compiler),
        "compiler_evidence_exact_membership": True,
        "compiler_evidence_fixed_hashes": v11_compiler,
        "unchanged_elaboration_source_count": len(v11_unchanged_elaboration_sources),
    },
    "production_runner_cpp_sha256": fixed[
        "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"
    ],
})
PY
}

write_static_audit() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$CMAKE_IDENTITY" \
        "$STATIC_AUDIT" <<'PY'
import pathlib
import re
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    IdentityError, atomic_write_json, read_bytes_stable, read_json_same_bytes,
    sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
cmake, _, _ = read_json_same_bytes(pathlib.Path(sys.argv[3]))
output = pathlib.Path(sys.argv[4])
cpp_path = root / "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"
cpp_bytes = read_bytes_stable(cpp_path)
cpp = cpp_bytes.decode("utf-8")


def strip_comments(text):
    result = []
    index = 0
    state = "code"
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        if state == "code":
            if char == "/" and nxt == "/":
                state = "line"
                result.append(" ")
                index += 2
                continue
            if char == "/" and nxt == "*":
                state = "block"
                result.append(" ")
                index += 2
                continue
            result.append(char)
            if char in {'"', "'"}:
                state = char
            index += 1
            continue
        if state == "line":
            if char == "\n":
                result.append("\n")
                state = "code"
            index += 1
            continue
        if state == "block":
            if char == "*" and nxt == "/":
                result.append(" ")
                state = "code"
                index += 2
                continue
            if char == "\n":
                result.append("\n")
            index += 1
            continue
        result.append(char)
        if char == "\\" and index + 1 < len(text):
            result.append(text[index + 1])
            index += 2
            continue
        if char == state:
            state = "code"
        index += 1
    if state in {"block", '"', "'"}:
        raise IdentityError(f"unterminated C++ lexical state: {state}")
    return "".join(result)


def extract_balanced(text, opening, open_char, close_char):
    depth = 0
    for index in range(opening, len(text)):
        if text[index] == open_char:
            depth += 1
        elif text[index] == close_char:
            depth -= 1
            if depth == 0:
                return text[opening + 1:index]
    raise IdentityError("unbalanced C++ source")


def split_args(text):
    result = []
    start = 0
    depths = {"(": 0, "[": 0, "{": 0, "<": 0}
    pairs = {")": "(", "]": "[", "}": "{", ">": "<"}
    for index, char in enumerate(text):
        if char in depths:
            depths[char] += 1
        elif char in pairs and depths[pairs[char]] > 0:
            depths[pairs[char]] -= 1
        elif char == "," and all(value == 0 for value in depths.values()):
            result.append(" ".join(text[start:index].split()))
            start = index + 1
    result.append(" ".join(text[start:].split()))
    return result


def production_args(source):
    code = strip_comments(source)
    signature = "bool npu_verilator_execute_f32_alu("
    if code.count(signature) != 1:
        raise IdentityError("production execute definition count mismatch")
    start = code.index(signature)
    end_marker = "bool npu_verilator_run_f32_alu_profile("
    end = code.index(end_marker, start)
    body = code[start:end]
    call = "f32_alu_harness harness("
    if body.count(call) != 1:
        raise IdentityError("production f32_alu_harness call count mismatch")
    opening = body.index("(", body.index(call))
    return split_args(extract_balanced(body, opening, "(", ")"))


expected_args = [
    "profile", "npu_f32_alu_mode::positive", "src0_allocation",
    "src0_allocation_bytes", "src1_allocation", "src1_allocation_bytes",
    "dst_shadow", "dst_shadow_bytes", "nullptr", "0", "result",
]
observed = production_args(cpp)
if observed != expected_args:
    raise SystemExit(f"production constructor args mismatch: {observed}")
if sha256_bytes(cpp_bytes) != "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e":
    raise SystemExit("production C++ byte identity mismatch")
old_mutant = cpp.replace("            nullptr,\n            0,\n            result);",
                         "            false,\n            result);", 1)
missing_mutant = cpp.replace("            0,\n            result);",
                             "            0);", 1)
mutation_results = {}
for name, mutant in {"old_ten_argument_form": old_mutant,
                     "missing_final_result": missing_mutant}.items():
    try:
        accepted = production_args(mutant) == expected_args
    except (IdentityError, ValueError):
        accepted = False
    if accepted:
        raise SystemExit(f"constructor mutation unexpectedly accepted: {name}")
    mutation_results[name] = True

consumer = cmake.get("consumer_binding", {})
if (cmake.get("source_count") != 21 or cmake.get("exact_order") is not True or
        consumer.get("verilator_command_expansion_count") != 1 or
        consumer.get("depends_expansion_count") != 1 or
        consumer.get("verilator_and_depends_bound") is not True):
    raise SystemExit("CMake exact source/consumer binding mismatch")
runner_text = read_bytes_stable(root / "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh").decode()
# 只审计实际 shell 控制面；避免 embedded checker 的反例 regex 自匹配。
runner_shell = runner_text[:runner_text.index("write_static_audit() {")]
forbidden_patterns = {
    "source_predecessor": r"(?m)^\s*(?:source|\.)\s+[^\n]*run-qwen-f32-alu-families-v[45]",
    "eval_predecessor": r"\beval\b[^\n]*run-qwen-f32-alu-families-v[45]",
    "execute_predecessor": r"\bbash\b[^\n]*run-qwen-f32-alu-families-v[45]",
}
for name, pattern in forbidden_patterns.items():
    if re.search(pattern, runner_shell):
        raise SystemExit(f"v6 predecessor execution forbidden: {name}")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-static-source-audit-v1",
    "pass": True,
    "production_constructor": {
        "definition_count": 1,
        "call_count": 1,
        "argument_count": len(observed),
        "arguments": observed,
        "cpp_sha256": sha256_bytes(cpp_bytes),
        "mutations_rejected": mutation_results,
    },
    "cmake": {
        "source_count": cmake["source_count"],
        "exact_order": cmake["exact_order"],
        "ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
        "consumer_binding": consumer,
    },
    "predecessor_source_eval_execute_count": 0,
    "numeric_rtl_modified": False,
})
PY
}

write_dso_identity() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$DSO_IDENTITY" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json, read_bytes_stable, read_json_same_bytes, sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
output = pathlib.Path(sys.argv[3])
historical_path = root / "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/dso-identity.json"
historical, historical_sha, _ = read_json_same_bytes(historical_path)
if historical_sha != "9be7769d40c6b4dc45a245f12889164f5df3614f3c997ca0532684518298ff71":
    raise SystemExit("pinned v11 DSO identity hash mismatch")
expected = {
    "libggml-base.so": "34b636a5639e5e78f1ebf3b196080e5a3db1007710e0773601fe70cd0501904d",
    "libggml.so": "78ca0b0f0be8d8bae4467a617d0f60195451e57cf6b3b1efef4b827e1af1c312",
}
records = {}
bin_root = root / "npu/version_0820/tmp/build/llama.cpp/bin"
for name, expected_sha in expected.items():
    logical = bin_root / name
    resolved = logical.resolve(strict=True)
    data = read_bytes_stable(resolved)
    digest = sha256_bytes(data)
    historical_record = historical.get("dsos", {}).get(name, {})
    if digest != expected_sha or historical_record.get("sha256") != expected_sha:
        raise SystemExit(f"pinned DSO bytes mismatch: {name}")
    records[name] = {
        "logical_path": logical.relative_to(root).as_posix(),
        "resolved_path": resolved.relative_to(root).as_posix(),
        "sha256": digest,
        "size_bytes": len(data),
    }
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-dso-identity-v1",
    "pass": True,
    "historical_identity_sha256": historical_sha,
    "dsos": records,
})
PY
}

write_atomicity_audit() {
    python3 - "$NPU_ROOT/scripts" "$COMPILER_ROOT" "$ATOMICITY_AUDIT" <<'PY'
import json
import os
import pathlib
import tempfile
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    IdentityError, atomic_write_json, read_json_same_bytes,
)
compiler_root = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
checks = {}
with tempfile.TemporaryDirectory(dir=compiler_root) as directory:
    root = pathlib.Path(directory)
    target = root / "late.json"
    replacement = root / "replacement.json"
    atomic_write_json(target, {"generation": 1, "status": "trusted"})
    value, digest, immutable = read_json_same_bytes(target)
    atomic_write_json(replacement, {"generation": 2, "status": "substituted"})
    os.replace(replacement, target)
    post, post_digest, _ = read_json_same_bytes(target)
    checks["same_bytes_hash_parse"] = (
        value == json.loads(immutable) == {"generation": 1, "status": "trusted"}
    )
    checks["hash_parse_substitution_rejected_by_post_closure"] = (
        post["generation"] == 2 and post_digest != digest
    )
    try:
        atomic_write_json(target, {"generation": 3})
    except IdentityError:
        checks["fresh_atomic_no_replace"] = True
    else:
        checks["fresh_atomic_no_replace"] = False
    malformed = root / "malformed.json"
    from qwen_f32_alu_build_identity import atomic_write_bytes
    atomic_write_bytes(malformed, b'{"unterminated":')
    try:
        read_json_same_bytes(malformed)
    except IdentityError:
        checks["malformed_json_rejected"] = True
    else:
        checks["malformed_json_rejected"] = False
if not all(checks.values()):
    raise SystemExit(f"atomicity probe failure: {checks}")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-atomicity-probes-v1",
    "pass": True,
    "checks": checks,
})
PY
}

write_compile_plan() {
    python3 - "$NPU_ROOT/scripts" "$COMPILE_PLAN" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json
atomic_write_json(pathlib.Path(sys.argv[2]), {
    "schema": "qwen-f32-alu-v6-future-compile-plan-v1",
    "authorization": "GAP",
    "current_task_must_not_build": True,
    "mode_present": "--compile",
    "preserve_raw_verfiles": "VTensorNpuCoprocessor__verFiles.dat",
    "membership_tool_mode": "audit-verfiles",
    "expected_design_sources": 21,
    "explicit_closure_classes": ["design", "transitive", "control", "tool"],
    "required_mutation_rejections": ["missing", "extra", "substitution", "class_collision"],
    "seal_compiler_dependency_files": True,
    "compile_membership_status": "GAP",
})
PY
}

write_process_audit() {
    python3 - "$NPU_ROOT/scripts" "$TASK_ID" "$BUILD_ROOT" "$PROCESS_AUDIT" <<'PY'
import os
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json
task_id = sys.argv[2]
build_root = pathlib.Path(sys.argv[3])
output = pathlib.Path(sys.argv[4])
excluded = set()
pid = os.getpid()
while pid > 0 and pid not in excluded:
    excluded.add(pid)
    try:
        pid = int(pathlib.Path(f"/proc/{pid}/stat").read_text().split()[3])
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
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v6-active-process-v1",
    "pass": True,
    "owned_background_jobs": 0,
    "matches": matches,
    "build_root_absent": True,
    "invocations": {
        "verilator": 0, "cmake": 0, "ninja": 0, "make": 0,
        "binary": 0, "execute": 0,
    },
})
PY
}

seal_preflight() {
    local artifacts=(
        "$BUILD_COUNT" "$TASK_STATUS_LOG" "$BUILD_IDENTITY_LOG"
        "$BUILD_IDENTITY_TEST_LOG" "$PRE_INPUT_IDENTITY"
        "$POST_INPUT_IDENTITY" "$CMAKE_IDENTITY" "$STATIC_AUDIT"
        "$HISTORY_AUDIT" "$DSO_IDENTITY" "$ATOMICITY_AUDIT"
        "$RUNNER_PROBE_AUDIT" "$COMPILE_PLAN" "$PROCESS_AUDIT"
    )
    local kind
    for kind in early-exit command-failure cleanup-failure hup-signal \
        int-signal term-signal premature-pass status-mismatch; do
        artifacts+=(
            "$COMPILER_ROOT/runner-probe-$kind.status"
            "$COMPILER_ROOT/runner-probe-$kind.rc"
            "$COMPILER_ROOT/runner-probe-$kind.log"
        )
    done
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" \
        "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_HASH" \
        "$BOUND_ARTIFACTS" "$EXPECTED_STATUS" "$FINAL_BINDING" \
        "$PREFLIGHT_STATUS" "${artifacts[@]}" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    IdentityError, atomic_write_bytes, atomic_write_json, read_bytes_stable,
    read_json_same_bytes, sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3])
receipt_path = pathlib.Path(sys.argv[4])
receipt_hash_path = pathlib.Path(sys.argv[5])
manifest_path = pathlib.Path(sys.argv[6])
expected_status_path = pathlib.Path(sys.argv[7])
binding_path = pathlib.Path(sys.argv[8])
actual_status_path = pathlib.Path(sys.argv[9])
artifact_paths = [pathlib.Path(item) for item in sys.argv[10:]]

schema_expectations = {
    "input-identity.pre.json": "qwen-f32-alu-v6-input-identity-v1",
    "input-identity.post.json": "qwen-f32-alu-v6-input-identity-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "static-source-audit.json": "qwen-f32-alu-v6-static-source-audit-v1",
    "history-audit.json": "qwen-f32-alu-v6-history-audit-v1",
    "dso-identity.json": "qwen-f32-alu-v6-dso-identity-v1",
    "atomicity-probes.json": "qwen-f32-alu-v6-atomicity-probes-v1",
    "runner-probe-audit.json": "qwen-f32-alu-v6-runner-probes-v1",
    "future-compile-plan.json": "qwen-f32-alu-v6-future-compile-plan-v1",
    "preflight-active-process-audit.json": "qwen-f32-alu-v6-active-process-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    relative = path.resolve(strict=True).relative_to(root).as_posix()
    if relative in artifacts:
        raise SystemExit(f"duplicate seal artifact: {relative}")
    if path.suffix == ".json":
        value, digest, data = read_json_same_bytes(path)
        expected_schema = schema_expectations.get(path.name)
        if expected_schema is not None and value.get("schema") != expected_schema:
            raise SystemExit(f"artifact schema mismatch: {relative}")
        if expected_schema is not None and value.get("pass") is False:
            raise SystemExit(f"artifact explicit FAIL: {relative}")
        parsed[path.name] = value
    else:
        data = read_bytes_stable(path)
        digest = sha256_bytes(data)
    artifacts[relative] = {"sha256": digest, "size_bytes": len(data)}

pre = parsed["input-identity.pre.json"]
post = parsed["input-identity.post.json"]
if pre["files"] != post["files"] or pre["identity_sha256"] != post["identity_sha256"]:
    raise SystemExit("frozen input pre/post drift")
cmake = parsed["cmake-source-identity.json"]
static = parsed["static-source-audit.json"]
history = parsed["history-audit.json"]
dso = parsed["dso-identity.json"]
atomicity = parsed["atomicity-probes.json"]
probes = parsed["runner-probe-audit.json"]
compile_plan = parsed["future-compile-plan.json"]
process = parsed["preflight-active-process-audit.json"]
if (cmake.get("source_count") != 21 or cmake.get("exact_order") is not True or
        cmake.get("consumer_binding", {}).get("verilator_and_depends_bound") is not True):
    raise SystemExit("receipt CMake identity validation failed")
constructor = static.get("production_constructor", {})
if (constructor.get("argument_count") != 11 or
        constructor.get("arguments", [])[-3:] != ["nullptr", "0", "result"] or
        not all(constructor.get("mutations_rejected", {}).values())):
    raise SystemExit("receipt production constructor validation failed")
if (history.get("pass") is not True or dso.get("pass") is not True or
        atomicity.get("pass") is not True or probes.get("pass") is not True or
        process.get("pass") is not True):
    raise SystemExit("receipt audit PASS boundary failed")
if compile_plan.get("compile_membership_status") != "GAP":
    raise SystemExit("unauthorized compile membership relabeled")
if build_root.exists() or read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/build.count") != b"0\n":
    raise SystemExit("build-free boundary violated")
if b"[task-run-status-test] PASS" not in read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/task-run-status-test.log"):
    raise SystemExit("task status helper marker missing")
if b"[qwen-f32-alu-build-identity-test] PASS exact=21" not in read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/build-identity-test.log"):
    raise SystemExit("build identity test marker missing")

receipt = {
    "schema": "qwen-f32-alu-v6-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-v6",
    "contract_sha256": "a1542ef8276732158e6d25b5505182a3b4f8293b471bdde371530a9f26050e12",
    "artifacts": artifacts,
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "production_constructor": constructor,
    "cmake_source_identity": {
        "source_count": 21,
        "exact_order": True,
        "ordered_sources": cmake["ordered_sources"],
        "ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
        "consumer_binding": cmake["consumer_binding"],
    },
    "v5_limited_predecessor": history["v5"],
    "v11_fixed_predecessor": history["v11"],
    "pinned_dso_identity": dso,
    "representative_profile_count": 19,
    "representative_command_flags": "0x00000010",
    "canonical_command_flags": "0x00000011",
    "completion_record_bytes": 128,
    "generic_completion_minor": 0,
    "representative_completion_minor": 1,
    "predecessor_representative_transactions_passed": 1,
    "representative_transactions_planned": 19,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "canonical_identity_set_sha256": "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385",
    "build_count": 0,
    "build_root_absent": True,
    "invocations": process["invocations"],
    "owned_background_jobs": 0,
    "compile_membership_status": "GAP",
    "tool_build_identity_status": "GAP",
    "git_lineage_status": "GAP",
    "deadline_edge_dynamic_status": "GAP",
    "event_time_five_stage_ledger_status": "GAP",
    "p00_p18_dynamic_status": "GAP",
    "rtl_dynamic_status": "GAP",
    "synthesis_sta_ppa_status": "GAP",
    "publication_order": [
        "receipt", "receipt-sidecar", "bound-artifact-manifest",
        "expected-final-status", "final-binding", "binding-recheck",
        "actual-final-status", "pass-marker",
    ],
}
atomic_write_json(receipt_path, receipt)
receipt_value, receipt_sha, receipt_bytes = read_json_same_bytes(receipt_path)
if receipt_value.get("task_id") != "qwen-f32-alu-families-v6":
    raise SystemExit("published receipt validation failed")
sidecar_bytes = f"{receipt_sha}  {receipt_path.name}\n".encode("utf-8")
atomic_write_bytes(receipt_hash_path, sidecar_bytes)
sidecar_observed = read_bytes_stable(receipt_hash_path)
if sidecar_observed != sidecar_bytes or sha256_bytes(receipt_bytes) != receipt_sha:
    raise SystemExit("receipt sidecar validation failed")

bound_inputs = dict(artifacts)
# receipt 与 sidecar 继续使用刚才已 hash/parse/validate 的同一 bytes，禁止二次读取窗口。
bound_inputs[receipt_path.relative_to(root).as_posix()] = {
    "sha256": receipt_sha, "size_bytes": len(receipt_bytes),
}
bound_inputs[receipt_hash_path.relative_to(root).as_posix()] = {
    "sha256": sha256_bytes(sidecar_observed),
    "size_bytes": len(sidecar_observed),
}
manifest = {
    "schema": "qwen-f32-alu-v6-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-v6",
    "artifact_count": len(bound_inputs),
    "artifacts": bound_inputs,
    "receipt_sha256": receipt_sha,
}
atomic_write_json(manifest_path, manifest)
manifest_value, manifest_sha, _ = read_json_same_bytes(manifest_path)
if manifest_value.get("receipt_sha256") != receipt_sha:
    raise SystemExit("bound manifest validation failed")

expected_bytes = b"PASS\n"
atomic_write_bytes(expected_status_path, expected_bytes)
expected_observed = read_bytes_stable(expected_status_path)
if expected_observed != expected_bytes:
    raise SystemExit("expected final status validation failed")
binding = {
    "schema": "qwen-f32-alu-v6-final-binding-v1",
    "task_id": "qwen-f32-alu-families-v6",
    "receipt_sha256": receipt_sha,
    "receipt_sidecar_sha256": sha256_bytes(sidecar_observed),
    "bound_artifacts_sha256": manifest_sha,
    "expected_final_status_sha256": sha256_bytes(expected_observed),
    "actual_status_path": actual_status_path.relative_to(root).as_posix(),
    "actual_status_must_equal_expected": True,
    "pass_marker_after_actual_status_check": True,
}
atomic_write_json(binding_path, binding)
binding_value, binding_sha, _ = read_json_same_bytes(binding_path)
if (binding_value.get("receipt_sha256") != receipt_sha or
        binding_value.get("bound_artifacts_sha256") != manifest_sha or
        binding_value.get("expected_final_status_sha256") != sha256_bytes(expected_observed) or
        binding_value.get("pass_marker_after_actual_status_check") is not True):
    raise SystemExit("final binding recheck failed")
print(f"{receipt_sha} {binding_sha}")
PY
}

verify_final_status() {
    python3 - "$NPU_ROOT/scripts" "$EXPECTED_STATUS" "$PREFLIGHT_STATUS" \
        "$FINAL_BINDING" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, sha256_bytes
expected_path = pathlib.Path(sys.argv[2])
actual_path = pathlib.Path(sys.argv[3])
binding_path = pathlib.Path(sys.argv[4])
binding, _, _ = read_json_same_bytes(binding_path)
expected = read_bytes_stable(expected_path)
actual = read_bytes_stable(actual_path)
if expected != b"PASS\n" or actual != expected:
    raise SystemExit("final actual status differs from bound expected status")
if binding.get("expected_final_status_sha256") != sha256_bytes(expected):
    raise SystemExit("final actual status binding mismatch")
PY
}

run_preflight() {
    [[ ! -e "$LOG_ROOT" ]] || fail "fresh log root exists=$LOG_ROOT"
    [[ ! -e "$COMPILER_ROOT" ]] || fail "fresh compiler root exists=$COMPILER_ROOT"
    [[ ! -e "$BUILD_ROOT" ]] || fail "fresh build root exists=$BUILD_ROOT"
    mkdir -p -- "$LOG_ROOT" "$COMPILER_ROOT" "$TMPDIR"
    task_run_status_init "$PREFLIGHT_STATUS"
    STATUS_INITIALIZED=1
    install_runner_traps
    atomic_write_text "$BUILD_COUNT" $'0\n'

    task_run_status_stage "frozen-input-pre-snapshot"
    snapshot_inputs "$PRE_INPUT_IDENTITY"

    task_run_status_stage "fixed-history-audit"
    write_history_audit

    task_run_status_stage "task-status-helper"
    run_atomic_log "$TASK_STATUS_LOG" bash "$STATUS_HELPER_TEST"
    [[ "$(sed -n '1p' "$TASK_STATUS_LOG")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper marker mismatch"

    task_run_status_stage "runner-fail-closed-probes"
    run_runner_probes

    task_run_status_stage "cmake-source-identity-test"
    QWEN_F32_ALU_REPO_ROOT="$REPO_ROOT" \
        run_atomic_log "$BUILD_IDENTITY_TEST_LOG" python3 "$BUILD_IDENTITY_TEST"
    [[ "$(sed -n '/\[qwen-f32-alu-build-identity-test\] PASS/p' "$BUILD_IDENTITY_TEST_LOG")" != "" ]] ||
        fail "build identity directed-test marker mismatch"

    task_run_status_stage "cmake-source-identity"
    run_atomic_log "$BUILD_IDENTITY_LOG" python3 "$BUILD_IDENTITY_TOOL" \
        audit-cmake --repo-root "$REPO_ROOT" --cmake "$CMAKE_FILE" \
        --output "$CMAKE_IDENTITY"

    task_run_status_stage "static-source-audit"
    write_static_audit

    task_run_status_stage "pinned-dso-identity"
    write_dso_identity

    task_run_status_stage "atomicity-probes"
    write_atomicity_audit

    task_run_status_stage "future-compile-gap-plan"
    write_compile_plan

    task_run_status_stage "process-build-boundary"
    [[ "$(<"$BUILD_COUNT")" == "0" ]] || fail "build count changed"
    [[ ! -e "$BUILD_ROOT" ]] || fail "build root was created"
    write_process_audit

    task_run_status_stage "frozen-input-post-snapshot"
    snapshot_inputs "$POST_INPUT_IDENTITY"

    task_run_status_stage "receipt-binding-publication"
    local seal_result
    seal_result=$(seal_preflight)
    local receipt_sha="${seal_result%% *}"
    [[ ${#receipt_sha} -eq 64 ]] || fail "receipt seal did not return SHA-256"
    FINAL_BINDING_VERIFIED=1

    task_run_status_stage "final-status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0
    verify_final_status
    FINAL_PASS_VERIFIED=1

    task_run_status_stage "pass-marker-publication"
    publish_pass_marker "$receipt_sha"
    PASS_MARKER_EMITTED=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V6][STATUS] $(<"$PREFLIGHT_STATUS")"
}

run_preflight
