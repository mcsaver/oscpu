#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families v11：唯一 build-free preflight；production/compile/execute bytes 全部只读。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-v11"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-v11.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
STAGING_ROOT="$COMPILER_ROOT/staging"
WORK_ROOT="$COMPILER_ROOT/work"
SEALED_ROOT="$COMPILER_ROOT/sealed"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v11.json"
BUILD_IDENTITY_TOOL="$NPU_ROOT/scripts/qwen_f32_alu_build_identity.py"
BUILD_IDENTITY_TEST="$NPU_ROOT/tests/test_qwen_f32_alu_build_identity.py"
CMAKE_FILE="$NPU_ROOT/runtime/llama-npu-backend/CMakeLists.txt"
PRODUCTION_CPP="$NPU_ROOT/runtime/llama-npu-backend/npu-verilator-runner.cpp"

RUN_STATUS="$LOG_ROOT/run.status"
RECEIPT="$LOG_ROOT/preflight.receipt.json"
RECEIPT_SIDECAR="$LOG_ROOT/preflight.receipt.sha256"
BOUND_MANIFEST="$LOG_ROOT/preflight.bound-artifacts.json"
EXPECTED_STATUS="$LOG_ROOT/preflight.expected-status"
FINAL_BINDING="$LOG_ROOT/preflight.final-binding.json"

BUILD_COUNT="$STAGING_ROOT/build.count"
TASK_STATUS_LOG="$STAGING_ROOT/task-run-status-test.log"
IDENTITY_TEST_LOG="$STAGING_ROOT/build-identity-test.log"
IDENTITY_LOG="$STAGING_ROOT/build-identity.log"
PRE_SNAPSHOT="$STAGING_ROOT/frozen-inputs.pre.json"
POST_SNAPSHOT="$STAGING_ROOT/frozen-inputs.post.json"
CMAKE_IDENTITY="$STAGING_ROOT/cmake-source-identity.json"
STATIC_AUDIT="$STAGING_ROOT/static-history-audit.json"
LATE_MUTATION_AUDIT="$STAGING_ROOT/late-replacement-mutations.json"
PROBE_AUDIT="$STAGING_ROOT/runner-probes.json"
CONTROL_AUDIT="$STAGING_ROOT/runner-control-regression.json"
COMPILE_PLAN="$STAGING_ROOT/future-compile-plan.json"
PROCESS_AUDIT="$STAGING_ROOT/active-process-audit.json"
CONTENT_SNAPSHOT=""

CONTRACT_SHA256="07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f"
V10_RUNNER_SHA256="3be7fd6af6ffb7077c7f94565d5ff061f03125fe907c52c7caad0157cda42343"
V10_RECEIPT_SHA256="1cfa3b714d4fa3b99621727b48b76f3fed1af3a46a9c8fe4e1a58ceb2d81e9a1"
V10_MANIFEST_SHA256="6c40085377a5066fa57585d639aa69f194a1dcfcef828ca7a4e47e64a30d789e"
V10_BINDING_SHA256="d83d712b9a317fba0796f86b0b1ee104cb5f9164c6a963422e0e05fe4ab198c4"
V10_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
V10_INPUT_SNAPSHOT_SHA256="56cc6dbf3a366e9ccdd4f295dcc2ae0472b1c0940fe440bf266e593b621eed0a"
PRODUCTION_CPP_SHA256="b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e"
CMAKE_SHA256="7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f"
IDENTITY_SET_SHA256="d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385"

FROZEN_INPUTS_REL=(
    .github/AGENTS.md
    .github/instructions/agent-lightweight-workflow.instructions.md
    .github/instructions/rtl-agent-task-contract.instructions.md
    .github/instructions/rtl-generation-workflow.instructions.md
    scripts/task-run-status.sh
    scripts/tests/test-task-run-status.sh
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v10.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v10-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v4.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v4-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v9.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v9-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v3.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v3-material.md
    npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
    npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
    npu/version_0820/rtl/tensor_npu_defs.vh
    npu/version_0820/rtl/TensorNpuCoprocessor.v
    npu/version_0820/rtl/TensorNpuVectorF32Adapter.v
    npu/version_0820/rtl/TensorNpuF32TensorAlu.v
    npu/version_0820/rtl/TensorNpuFp32AddMul.v
    npu/version_0820/rtl/TensorNpuCommandDecoder.v
    npu/version_0820/rtl/TensorNpuRegisterFile.v
    npu/version_0820/rtl/TensorNpuMm2Engine.v
    npu/version_0820/rtl/TensorNpuDmaEngine.v
    npu/version_0820/rtl/TensorNpuLocalMemory.v
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
    npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v9.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v10.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v11.sh
    npu/version_0820/tmp/build/llama.cpp/bin/libggml-base.so
    npu/version_0820/tmp/build/llama.cpp/bin/libggml.so
)

FROZEN_INPUT_DIRS_REL=(
    npu/version_0820/third_party/fpu-sp/verilog/src/float
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc
    npu/version_0820/third_party/llama.cpp/ggml/include
    npu/version_0820/third_party/llama.cpp/ggml/src
    npu/version_0820/tmp/logs/qwen-graph-manifest-v5
    npu/version_0820/tmp/logs/qwen-f32-add-owner-v11
    npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v6
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v6
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v7
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v8
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v9
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v9
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v10
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v10
)

export PYTHONDONTWRITEBYTECODE=1
export TMPDIR="$WORK_ROOT/tmp"

# shellcheck source=/dev/null
source "$STATUS_HELPER"

STATUS_INITIALIZED=0
FINAL_BINDING_VERIFIED=0
FINAL_PASS_VERIFIED=0
TERMINAL_SUCCESS=0
FORCED_CLEANUP_RC=0
ATOMIC_COUNTER=0

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-V11][FAIL] $*" >&2
    return 1
}

finish_on_exit() {
    local command_rc=$?
    local effective_rc=$command_rc
    local finalize_rc=0
    trap - EXIT HUP INT TERM
    set +e
    if [[ $STATUS_INITIALIZED -eq 1 ]] &&
       [[ $command_rc -ne 0 || $FORCED_CLEANUP_RC -ne 0 || $TERMINAL_SUCCESS -ne 1 ]]; then
        if [[ $effective_rc -eq 0 ]]; then
            if [[ $FORCED_CLEANUP_RC -ne 0 ]]; then
                effective_rc=$FORCED_CLEANUP_RC
            else
                effective_rc=1
            fi
        fi
        # 无 PASS_MARKER_EMITTED 旁路：status/marker 后的任意失败或 signal 都覆盖为 FAIL。
        task_run_status_finalize "$effective_rc" "$FORCED_CLEANUP_RC"
        finalize_rc=$?
        if [[ $command_rc -eq 0 ]]; then
            command_rc=$finalize_rc
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
    temporary="$WORK_ROOT/log.${BASHPID}.${ATOMIC_COUNTER}.tmp"
    ( set -o noclobber; : >"$temporary" ) || fail "temporary log collision=$temporary"
    if "$@" >"$temporary" 2>&1; then
        command_rc=0
    else
        command_rc=$?
    fi
    publish_temporary_file "$temporary" "$output"
    return "$command_rc"
}

file_sha() {
    local value
    value=$(sha256sum "$1")
    printf '%s\n' "${value%% *}"
}

publish_pass_marker() {
    local receipt_sha="$1"
    local binding_sha="$2"
    local manifest_sha="$3"
    local status_sha="$4"
    local snapshot_sha="$5"
    local runner_sha="$6"
    local tool_sha="$7"
    local test_sha="$8"
    [[ $FINAL_BINDING_VERIFIED -eq 1 ]] || fail "PASS marker denied before final binding verification"
    [[ $FINAL_PASS_VERIFIED -eq 1 ]] || fail "PASS marker denied before post-status full revalidation"
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V11][PREFLIGHT-PASS] build_count=0 build_root_absent=1 verilator=0 cmake=0 ninja=0 make=0 binary=0 execute=0 synthesis=0 sta=0 ppa=0 owned_background_jobs=0 sources=21 source_order=exact cpp_translation_phase2_phase3=PASS cpp_full_function_template=PASS cpp_class_identity=PASS cpp_mutations=26/26 frozen_cmake_template=PASS cmake_mutations=44/44 cmake_bare_consumers=PASS cmake_competing_producers=0 actual_configured_argv=GAP depfile_parser=PASS compile_membership=GAP late_json=reject late_nonjson=reject late_frozen_source=reject late_dso_symlink=reject late_dso_resolved=reject late_final_timing=reject runner_probes=12 after_status_failure=reject after_status_signal=reject after_marker_failure=reject after_marker_signal=reject representative_predecessor_passed=1 representative_planned=19 verified_canonical_completed=0 remaining=1079 deadline_edge=GAP event_time_ledger=GAP p00_p18_dynamic=GAP strict_backend=GAP backend_concurrency=CONDITIONAL_UNKNOWN qwen=GAP synthesis_sta_ppa=GAP threat_model=nonadversarial-private-namespace contract_sha256=$CONTRACT_SHA256 identity_set_sha256=$IDENTITY_SET_SHA256 production_cpp_sha256=$PRODUCTION_CPP_SHA256 cmake_sha256=$CMAKE_SHA256 runner_sha256=$runner_sha identity_tool_sha256=$tool_sha identity_test_sha256=$test_sha receipt_sha256=$receipt_sha bound_artifacts_sha256=$manifest_sha binding_sha256=$binding_sha status_sha256=$status_sha content_snapshot_sha256=$snapshot_sha"
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
            publish_pass_marker probe probe probe probe probe probe probe probe
            ;;
        status-mismatch)
            task_run_status_stage "probe-status-mismatch"
            task_run_status_mark_evidence_complete
            task_run_status_finalize 0 0
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
            return 1
            ;;
        after-status-command|after-status-term|after-marker-command|after-marker-term)
            task_run_status_stage "$kind"
            task_run_status_mark_evidence_complete
            task_run_status_finalize 0 0
            FINAL_BINDING_VERIFIED=1
            FINAL_PASS_VERIFIED=1
            if [[ "$kind" == after-marker-* ]]; then
                publish_pass_marker mutation mutation mutation mutation mutation mutation mutation mutation
            fi
            if [[ "$kind" == *-term ]]; then
                kill -s TERM "$BASHPID"
            fi
            return 12
            ;;
        *)
            return 2
            ;;
    esac
}

run_internal_errexit_mutation() {
    local nested_status="$1"
    local nested_log="$2"
    local classifier_completion="$3"

    mutant_atomic_log() {
        local output="$1"
        shift
        local command_rc=0
        set +e
        "$@" >"$output" 2>&1
        command_rc=$?
        set -e
        return "$command_rc"
    }

    set +e
    mutant_atomic_log "$nested_log" bash "$RUNNER" --internal-probe early-exit "$nested_status"
    local nested_rc=$?
    set -e
    atomic_write_text "$classifier_completion" "$nested_rc"$'\n'
}

if (( $# >= 1 )) && [[ "$1" == "--internal-probe" ]]; then
    [[ $# -eq 3 ]] || exit 2
    run_internal_probe "$2" "$3"
    exit $?
fi

if (( $# >= 1 )) && [[ "$1" == "--internal-errexit-mutation" ]]; then
    [[ $# -eq 4 ]] || exit 2
    run_internal_errexit_mutation "$2" "$3" "$4"
    exit $?
fi

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--compile" && "$1" != "--execute" ]]; then
    printf '%s\n' "usage: bash $RUNNER_REL --preflight|--compile|--execute" >&2
    exit 2
fi

if [[ "$1" == "--compile" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V11][GAP] compile requires future actual depfile/__verFiles.dat/compiler-argv and new authorization" >&2
    exit 2
fi

if [[ "$1" == "--execute" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V11][GAP] execute requires compile-membership PASS and new authorization" >&2
    exit 2
fi

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
files = {}


def add_path(relative):
    relative = pathlib.PurePosixPath(relative).as_posix()
    if relative in files:
        return
    path = root / relative
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        resolved_data = read_bytes_stable(resolved)
        try:
            resolved_name = resolved.relative_to(root).as_posix()
        except ValueError:
            resolved_name = str(resolved)
        files[relative] = {
            "type": "symlink",
            "link_target": target,
            "sha256": sha256_bytes(target.encode("utf-8")),
            "resolved_path": resolved_name,
            "resolved_sha256": sha256_bytes(resolved_data),
            "resolved_size_bytes": len(resolved_data),
        }
        return
    data = read_bytes_stable(path)
    json_validated = False
    if path.suffix == ".json":
        json.loads(data)
        json_validated = True
    files[relative] = {
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
        raise IdentityError(f"frozen directory invalid: {relative_root}")
    for path in sorted(directory.rglob("*")):
        if path.is_dir() and not path.is_symlink():
            continue
        add_path(path.relative_to(root).as_posix())
aggregate = "".join(
    f"{name}\t{entry['type']}\t{entry['sha256']}\t"
    f"{entry.get('resolved_sha256', '')}\n"
    for name, entry in sorted(files.items())
).encode("utf-8")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-frozen-snapshot-v1",
    "file_count": len(files),
    "files": files,
    "explicit_paths": explicit,
    "directory_roots": directories,
    "identity_sha256": hashlib.sha256(aggregate).hexdigest(),
})
PY
}

publish_content_snapshot() {
    python3 - "$NPU_ROOT/scripts" "$PRE_SNAPSHOT" "$SEALED_ROOT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    atomic_write_bytes, read_bytes_stable, read_json_same_bytes, sha256_bytes,
)
source = pathlib.Path(sys.argv[2])
sealed_root = pathlib.Path(sys.argv[3])
value, digest, data = read_json_same_bytes(source)
if value.get("schema") != "qwen-f32-alu-v11-frozen-snapshot-v1":
    raise SystemExit("content snapshot source schema mismatch")
output = sealed_root / f"frozen-inputs.{digest}.json"
atomic_write_bytes(output, data, mode=0o444)
if read_bytes_stable(output) != data or sha256_bytes(data) != digest:
    raise SystemExit("content-addressed snapshot publication mismatch")
print(output)
PY
}

run_one_probe() {
    local kind="$1"
    local expected_rc="$2"
    local marker="$3"
    local status="$WORK_ROOT/probe-$kind.status"
    local log="$WORK_ROOT/probe-$kind.log"
    local rc_path="$WORK_ROOT/probe-$kind.rc"
    local probe_rc=0
    set +e
    run_atomic_log "$log" bash "$RUNNER" --internal-probe "$kind" "$status"
    probe_rc=$?
    set -e
    [[ $probe_rc -eq $expected_rc ]] ||
        fail "runner probe rc mismatch=$kind expected=$expected_rc actual=$probe_rc"
    [[ "$(sed -n '1p' "$status")" == FAIL* ]] ||
        fail "runner probe status not FAIL=$kind"
    [[ "$(sed -n '1p' "$status")" == *"$marker"* ]] ||
        fail "runner probe status marker mismatch=$kind marker=$marker"
    if [[ "$kind" == "premature-pass" ]]; then
        [[ "$(sed -n '/PREFLIGHT-PASS/p' "$log")" == "" ]] ||
            fail "premature PASS marker became visible"
    fi
    if [[ "$kind" == after-marker-* ]]; then
        [[ "$(sed -n '/PREFLIGHT-PASS/p' "$log" | sed -n '1p')" != "" ]] ||
            fail "after-marker mutation did not attempt marker=$kind"
    fi
    printf '%s\n' "$probe_rc" >"$rc_path"
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
    run_one_probe after-status-command 12 "stage=after-status-command"
    run_one_probe after-status-term 143 "signal=TERM"
    run_one_probe after-marker-command 12 "stage=after-marker-command"
    run_one_probe after-marker-term 143 "signal=TERM"
    python3 - "$NPU_ROOT/scripts" "$WORK_ROOT" "$PROBE_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable, sha256_bytes
root = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
expected = {
    "early-exit": 1,
    "command-failure": 7,
    "cleanup-failure": 9,
    "hup-signal": 129,
    "int-signal": 130,
    "term-signal": 143,
    "premature-pass": 1,
    "status-mismatch": 1,
    "after-status-command": 12,
    "after-status-term": 143,
    "after-marker-command": 12,
    "after-marker-term": 143,
}
records = {}
for name, expected_rc in expected.items():
    status = read_bytes_stable(root / f"probe-{name}.status").decode().strip()
    rc = int(read_bytes_stable(root / f"probe-{name}.rc"))
    log = read_bytes_stable(root / f"probe-{name}.log")
    marker_count = log.count(b"[PREFLIGHT-PASS]")
    if not status.startswith("FAIL ") or rc != expected_rc:
        raise SystemExit(f"runner probe mismatch: {name}: rc={rc}: {status}")
    if name == "premature-pass" and marker_count != 0:
        raise SystemExit("premature marker became visible")
    if name.startswith("after-marker-") and marker_count != 1:
        raise SystemExit(f"after-marker attempt count mismatch: {name}: {marker_count}")
    if (name.startswith("after-status-") or name.startswith("after-marker-")) and (
        "evidence_complete=1" not in status
    ):
        raise SystemExit(f"late failure did not overwrite published PASS: {name}")
    records[name] = {
        "return_code": rc,
        "status": status,
        "log_sha256": sha256_bytes(log),
        "pass_marker_attempt_count": marker_count,
    }
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-runner-probes-v1",
    "pass": True,
    "probe_count": len(records),
    "records": records,
    "after_status_command_failure_rejected": True,
    "after_status_signal_rejected": True,
    "after_marker_command_failure_rejected": True,
    "after_marker_signal_rejected": True,
})
PY
}

run_runner_control_regression() {
    local nested_status="$WORK_ROOT/control-nested.status"
    local nested_log="$WORK_ROOT/control-nested.log"
    local mutant_log="$WORK_ROOT/control-mutant.log"
    local classifier_completion="$WORK_ROOT/control-classified.rc"
    local mutation_rc=0
    set +e
    run_atomic_log "$mutant_log" bash "$RUNNER" --internal-errexit-mutation \
        "$nested_status" "$nested_log" "$classifier_completion"
    mutation_rc=$?
    set -e
    [[ $mutation_rc -eq 1 ]] ||
        fail "caller-errexit mutation rc mismatch expected=1 actual=$mutation_rc"
    [[ ! -e "$classifier_completion" ]] ||
        fail "caller-errexit mutation reached forbidden classifier"
    [[ "$(sed -n '1p' "$nested_status")" == \
       "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0" ]] ||
        fail "caller-errexit nested status mismatch"
    python3 - "$NPU_ROOT/scripts" "$nested_status" "$nested_log" "$mutant_log" \
        "$classifier_completion" "$mutation_rc" "$CONTROL_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable, sha256_bytes
status_path = pathlib.Path(sys.argv[2])
nested_log = pathlib.Path(sys.argv[3])
mutant_log = pathlib.Path(sys.argv[4])
classifier = pathlib.Path(sys.argv[5])
return_code = int(sys.argv[6])
output = pathlib.Path(sys.argv[7])
status = read_bytes_stable(status_path).decode().strip()
checks = {
    "mutant_return_code_is_one": return_code == 1,
    "nested_status_fail_closed": status == (
        "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0"
    ),
    "caller_classifier_not_reached": not classifier.exists(),
    "positive_marker_absent": (
        b"[PREFLIGHT-PASS]" not in read_bytes_stable(nested_log)
        and b"[PREFLIGHT-PASS]" not in read_bytes_stable(mutant_log)
    ),
}
if not all(checks.values()):
    raise SystemExit(f"caller-errexit regression mutation accepted: {checks}")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-runner-control-v1",
    "pass": True,
    "mutation_rejected": True,
    "return_code": return_code,
    "checks": checks,
    "nested_log_sha256": sha256_bytes(read_bytes_stable(nested_log)),
    "mutant_log_sha256": sha256_bytes(read_bytes_stable(mutant_log)),
})
PY
}

write_static_history_audit() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$PRE_SNAPSHOT" "$CMAKE_IDENTITY" \
        "$STATIC_AUDIT" <<'PY'
import json
import os
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json, audit_f32_constructor_bytes,
    f32_constructor_mutation_self_test, read_bytes_stable,
    read_json_same_bytes, sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
current, _, _ = read_json_same_bytes(pathlib.Path(sys.argv[3]))
cmake, _, _ = read_json_same_bytes(pathlib.Path(sys.argv[4]))
output = pathlib.Path(sys.argv[5])

fixed = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11.json":
        "07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v4.json":
        "5839954629c9cb77d8626d7ca3c090cc603fcbc92b391731a8f2f14a93f986b4",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v10.sh":
        "3be7fd6af6ffb7077c7f94565d5ff061f03125fe907c52c7caad0157cda42343",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.receipt.json":
        "1cfa3b714d4fa3b99621727b48b76f3fed1af3a46a9c8fe4e1a58ceb2d81e9a1",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.bound-artifacts.json":
        "6c40085377a5066fa57585d639aa69f194a1dcfcef828ca7a4e47e64a30d789e",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.final-binding.json":
        "d83d712b9a317fba0796f86b0b1ee104cb5f9164c6a963422e0e05fe4ab198c4",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/run.status":
        "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v10/staging/frozen-inputs.pre.json":
        "56cc6dbf3a366e9ccdd4f295dcc2ae0472b1c0940fe440bf266e593b621eed0a",
}
for relative, expected in fixed.items():
    data = read_bytes_stable(root / relative)
    if sha256_bytes(data) != expected:
        raise SystemExit(f"fixed admission/evidence drift: {relative}")

v10_manifest_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.bound-artifacts.json"
v10_manifest, v10_manifest_sha, _ = read_json_same_bytes(v10_manifest_path)
if (v10_manifest_sha != fixed[v10_manifest_path.relative_to(root).as_posix()] or
        v10_manifest.get("schema") != "qwen-f32-alu-v10-bound-artifacts-v1" or
        v10_manifest.get("artifact_count") != len(v10_manifest.get("artifacts", {}))):
    raise SystemExit("v10 bound manifest semantic mismatch")
for relative, record in v10_manifest["artifacts"].items():
    path = root / relative
    data = read_bytes_stable(path)
    if len(data) != record.get("size_bytes") or sha256_bytes(data) != record.get("sha256"):
        raise SystemExit(f"v10 manifest artifact late drift: {relative}")
    if path.suffix == ".json":
        json.loads(data)

receipt_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.receipt.json"
binding_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.final-binding.json"
receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
binding, binding_sha, _ = read_json_same_bytes(binding_path)
status = read_bytes_stable(
    root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/run.status"
)
sidecar = read_bytes_stable(
        root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v10/preflight.receipt.sha256"
)
if (receipt_sha != fixed[receipt_path.relative_to(root).as_posix()] or
        binding_sha != fixed[binding_path.relative_to(root).as_posix()] or
        status != b"PASS\n" or
        sidecar != f"{receipt_sha}  {receipt_path.name}\n".encode("utf-8") or
        receipt.get("task_id") != "qwen-f32-alu-families-v10" or
        receipt.get("build_count") != 0 or
        receipt.get("build_root_absent") is not True or
        receipt.get("verified_canonical_node_identities_completed") != 0 or
        receipt.get("remaining_nonmetadata_gap") != 1079 or
        binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != v10_manifest_sha):
    raise SystemExit("v10 receipt/binding/status closure mismatch")
if (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-v10").exists():
    raise SystemExit("v10 build root unexpectedly exists")

v10_snapshot_path = root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v10/staging/frozen-inputs.pre.json"
historical, historical_sha, _ = read_json_same_bytes(v10_snapshot_path)
if historical_sha != fixed[v10_snapshot_path.relative_to(root).as_posix()]:
    raise SystemExit("v10 frozen snapshot identity mismatch")

production_paths = {
    "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md",
    "npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md",
    "npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md",
    "npu/version_0820/rtl/tensor_npu_defs.vh",
    "npu/version_0820/rtl/TensorNpuCoprocessor.v",
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v",
    "npu/version_0820/rtl/TensorNpuF32TensorAlu.v",
    "npu/version_0820/rtl/TensorNpuFp32AddMul.v",
    "npu/version_0820/rtl/TensorNpuCommandDecoder.v",
    "npu/version_0820/rtl/TensorNpuRegisterFile.v",
    "npu/version_0820/rtl/TensorNpuMm2Engine.v",
    "npu/version_0820/rtl/TensorNpuDmaEngine.v",
    "npu/version_0820/rtl/TensorNpuLocalMemory.v",
    "npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt",
    "npu/version_0820/runtime/llama-npu-backend/npu-audit-api.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.h",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp",
    "npu/version_0820/runtime/llama-npu-backend/ggml-npu.cpp",
    "npu/version_0820/runtime/llama-npu-backend/test-backend.cpp",
    "npu/version_0820/scripts/qwen_graph_manifest.py",
    "npu/version_0820/tests/test_qwen_graph_manifest.py",
    "npu/version_0820/scripts/qwen_f32_alu_profiles.py",
    "npu/version_0820/tests/test_qwen_f32_alu_profiles.py",
}
production_prefixes = (
    "npu/version_0820/third_party/fpu-sp/verilog/src/float/",
    "npu/version_0820/third_party/fpu-sp/verilog/src/lzc/",
    "npu/version_0820/third_party/llama.cpp/ggml/include/",
    "npu/version_0820/third_party/llama.cpp/ggml/src/",
    "npu/version_0820/tmp/logs/qwen-graph-manifest-v5/",
)
history_prefixes = (
    "npu/version_0820/tmp/logs/qwen-f32-add-owner-v11/",
    "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v6/",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v9/",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v9/",
)


def comparable(entry):
    return {key: value for key, value in entry.items() if key != "resolved_path"}


selected = []
for relative, old_entry in historical.get("files", {}).items():
    # 显式历史选择避免把可演进 instruction/tool/test 误当 production freeze。
    selected_path = (
        relative in production_paths
        or relative.startswith(production_prefixes)
        or relative.startswith(history_prefixes)
        or relative.startswith("npu/version_0820/scripts/run-qwen-f32-alu-families-v")
        or any(
            relative.startswith(
                f"npu/version_0820/tmp/contracts/qwen-f32-alu-families-v{version}"
            )
            for version in range(6, 11)
        )
        or relative in {
            "npu/version_0820/tmp/build/llama.cpp/bin/libggml-base.so",
            "npu/version_0820/tmp/build/llama.cpp/bin/libggml.so",
        }
    )
    if not selected_path:
        continue
    new_entry = current.get("files", {}).get(relative)
    if new_entry is None or comparable(new_entry) != comparable(old_entry):
        raise SystemExit(f"v10-anchored production/history drift: {relative}")
    selected.append(relative)
if not production_paths.issubset(set(selected)):
    raise SystemExit("production freeze comparison omitted explicit path")

cpp_bytes = read_bytes_stable(
    root / "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"
)
constructor = audit_f32_constructor_bytes(cpp_bytes)
mutations = f32_constructor_mutation_self_test(cpp_bytes)
if (constructor.get("cpp_sha256") !=
        "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e" or
        constructor.get("frozen_complete_file_sha256_verified") is not True or
        constructor.get("translation_phase2_before_phase3") is not True or
        constructor.get("function_template_sha256") !=
        constructor.get("expected_function_template_sha256") or
        constructor.get("class_definition_count") != 1 or
        constructor.get("class_identity_bound_to_frozen_cpp_sha256") is not True or
        len(mutations.get("harmful_mutations_rejected", {})) != 26 or
        not all(mutations.get("harmful_mutations_rejected", {}).values()) or
        mutations.get("successor_rename_accepted") is not True or
        mutations.get("successor_template_observation_unchanged") is not True or
        mutations.get("successor_hash_check_intentionally_disabled") is not True):
    raise SystemExit("production C++ lexical mutation audit mismatch")
consumer = cmake.get("consumer_binding", {})
if (cmake.get("source_count") != 21 or
        cmake.get("ordered_source_identity_sha256") !=
        "d5d81392319f93290b019af53f47ca4097b9f6114f5a3e37f09ce013e59c7951" or
        consumer.get("unconditional_top_level_set") is not True or
        consumer.get("unconditional_top_level_custom_command") is not True or
        consumer.get("verilator_and_depends_bound") is not True or
        consumer.get("bare_unquoted_exact_consumers") is not True or
        consumer.get("producer_template_exact") is not True or
        consumer.get("canonical_token_spellings") is not True or
        consumer.get("downstream_target_template_exact") is not True or
        consumer.get("competing_producer_count") != 0 or
        consumer.get("active_structure_allowlist") is not True or
        cmake.get("frozen_complete_file_sha256_verified") is not True or
        cmake.get("frozen_cmake_template") != "PASS" or
        cmake.get("actual_configured_argv") != "GAP" or
        cmake.get("compile_membership_status") != "GAP"):
    raise SystemExit("restricted CMake exact-21 identity mismatch")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-static-history-v1",
    "pass": True,
    "production_constructor": constructor,
    "constructor_mutations": mutations,
    "cmake_source_count": 21,
    "cmake_directed_mutations_rejected": 44,
    "cmake_ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
    "cmake_consumer_binding": consumer,
    "v10_manifest_artifact_count_reopened": len(v10_manifest["artifacts"]),
    "v10_receipt_sha256": receipt_sha,
    "v10_manifest_sha256": v10_manifest_sha,
    "v10_binding_sha256": binding_sha,
    "v10_status_sha256": sha256_bytes(status),
    "v10_input_snapshot_sha256": historical_sha,
    "static_review_v4_contract_sha256":
        fixed["npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v4.json"],
    "v4_v10_history_and_production_entries_revalidated": len(selected),
    "production_bytes_unchanged": True,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
})
PY
}

write_late_replacement_mutations() {
    python3 - "$NPU_ROOT/scripts" "$WORK_ROOT" "$LATE_MUTATION_AUDIT" <<'PY'
import os
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    IdentityError, atomic_write_bytes, atomic_write_json, build_artifact_record,
    read_bytes_stable, revalidate_bound_artifacts, sha256_bytes,
)
work = pathlib.Path(sys.argv[2]) / "late-mutations"
work.mkdir(mode=0o700)
output = pathlib.Path(sys.argv[3])
checks = {}


def replacement_rejected(name, suffix, schema=None):
    root = work / name
    root.mkdir(mode=0o700)
    target = root / f"artifact{suffix}"
    replacement = root / f"replacement{suffix}"
    if schema:
        atomic_write_json(target, {"schema": schema, "generation": 1})
        atomic_write_json(replacement, {"schema": schema, "generation": 2})
    else:
        atomic_write_bytes(target, b"trusted\n")
        atomic_write_bytes(replacement, b"substituted\n")
    manifest = {target.name: build_artifact_record(root, target, schema)}
    revalidate_bound_artifacts(root, manifest)
    os.replace(replacement, target)
    try:
        revalidate_bound_artifacts(root, manifest)
    except IdentityError:
        checks[name] = True
    else:
        checks[name] = False


replacement_rejected("late_json", ".json", "late-json-v1")
replacement_rejected("late_nonjson", ".log")
replacement_rejected("late_frozen_source", ".cpp")
replacement_rejected("late_final_verification_timing", ".sealed")

dso_root = work / "late_dso_resolved"
dso_root.mkdir(mode=0o700)
resolved = dso_root / "libggml.so.1"
replacement = dso_root / "libggml.so.2"
atomic_write_bytes(resolved, b"resolved-v1\n")
atomic_write_bytes(replacement, b"resolved-v2\n")
logical = dso_root / "libggml.so"
logical.symlink_to(resolved.name)
baseline_link = os.readlink(logical)
baseline_resolved = sha256_bytes(read_bytes_stable(logical.resolve(strict=True)))
os.replace(replacement, resolved)
checks["late_dso_resolved"] = (
    sha256_bytes(read_bytes_stable(logical.resolve(strict=True))) != baseline_resolved
)

link_root = work / "late_dso_symlink"
link_root.mkdir(mode=0o700)
first = link_root / "libggml.so.1"
second = link_root / "libggml.so.2"
atomic_write_bytes(first, b"same-bytes\n")
atomic_write_bytes(second, b"same-bytes\n")
logical = link_root / "libggml.so"
logical.symlink_to(first.name)
baseline_target = os.readlink(logical)
replacement_link = link_root / "replacement-link"
replacement_link.symlink_to(second.name)
os.replace(replacement_link, logical)
checks["late_dso_symlink"] = (
    os.readlink(logical) != baseline_target
    and sha256_bytes(read_bytes_stable(logical.resolve(strict=True))) ==
    sha256_bytes(read_bytes_stable(first))
)

if not all(checks.values()):
    raise SystemExit(f"late replacement mutation unexpectedly accepted: {checks}")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-late-replacement-v1",
    "pass": True,
    "checks": checks,
    "mutation_count": len(checks),
    "path_rehash_threat_model": (
        "private fresh namespace plus stable reopen detects tested replacement windows; "
        "root/kernel adversarial replacement after the last lstat remains GAP"
    ),
})
PY
}

write_compile_gap_plan() {
    python3 - "$NPU_ROOT/scripts" "$COMPILE_PLAN" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json
atomic_write_json(pathlib.Path(sys.argv[2]), {
    "schema": "qwen-f32-alu-v11-future-compile-plan-v1",
    "pass": True,
    "authorization": "GAP",
    "current_task_must_not_build": True,
    "strict_depfile_parser_unit_mutations_passed": True,
    "future_required_inputs": [
        "expected_build_root", "actual_object_targets", "actual_compiler_argv_sha256",
        "exact_depfile_target_prerequisite_closure", "actual___verFiles.dat",
        "declared_design_transitive_control_tool_roots",
    ],
    "future_build_admission_must_compare_content_snapshot": True,
    "frozen_cmake_template": "PASS",
    "actual_configured_argv": "GAP",
    "compile_membership_status": "GAP",
    "tool_build_identity_status": "GAP",
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
    raise SystemExit(f"owned process/build residue detected: {matches}")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v11-active-process-v1",
    "pass": True,
    "owned_background_jobs": 0,
    "matches": matches,
    "build_root_absent": True,
    "invocations": {
        "verilator": 0, "cmake": 0, "ninja": 0, "make": 0,
        "binary": 0, "execute": 0, "synthesis": 0, "sta": 0, "ppa": 0,
    },
})
PY
}

seal_preflight() {
    local artifacts=(
        "$BUILD_COUNT" "$TASK_STATUS_LOG" "$IDENTITY_TEST_LOG" "$IDENTITY_LOG"
        "$PRE_SNAPSHOT" "$POST_SNAPSHOT" "$CONTENT_SNAPSHOT" "$CMAKE_IDENTITY"
        "$STATIC_AUDIT" "$LATE_MUTATION_AUDIT" "$PROBE_AUDIT" "$CONTROL_AUDIT"
        "$COMPILE_PLAN" "$PROCESS_AUDIT"
    )
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$RUN_STATUS" \
        "$RECEIPT" "$RECEIPT_SIDECAR" "$BOUND_MANIFEST" "$EXPECTED_STATUS" \
        "$FINAL_BINDING" "${artifacts[@]}" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_bytes, atomic_write_json, build_artifact_record,
    read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts,
    sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3])
status_path = pathlib.Path(sys.argv[4])
receipt_path = pathlib.Path(sys.argv[5])
sidecar_path = pathlib.Path(sys.argv[6])
manifest_path = pathlib.Path(sys.argv[7])
expected_status_path = pathlib.Path(sys.argv[8])
binding_path = pathlib.Path(sys.argv[9])
artifact_paths = [pathlib.Path(value) for value in sys.argv[10:]]
schemas = {
    "frozen-inputs.pre.json": "qwen-f32-alu-v11-frozen-snapshot-v1",
    "frozen-inputs.post.json": "qwen-f32-alu-v11-frozen-snapshot-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "static-history-audit.json": "qwen-f32-alu-v11-static-history-v1",
    "late-replacement-mutations.json": "qwen-f32-alu-v11-late-replacement-v1",
    "runner-probes.json": "qwen-f32-alu-v11-runner-probes-v1",
    "runner-control-regression.json": "qwen-f32-alu-v11-runner-control-v1",
    "future-compile-plan.json": "qwen-f32-alu-v11-future-compile-plan-v1",
    "active-process-audit.json": "qwen-f32-alu-v11-active-process-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    expected_schema = schemas.get(path.name)
    if path.name.startswith("frozen-inputs.") and path.parent.name == "sealed":
        expected_schema = "qwen-f32-alu-v11-frozen-snapshot-v1"
    record = build_artifact_record(root, path, expected_schema)
    relative = path.resolve(strict=True).relative_to(root).as_posix()
    if relative in artifacts:
        raise SystemExit(f"duplicate staged artifact: {relative}")
    artifacts[relative] = record
    if expected_schema:
        value, _, _ = read_json_same_bytes(path)
        parsed[path.name] = value

pre = parsed["frozen-inputs.pre.json"]
post = parsed["frozen-inputs.post.json"]
contract_relative = "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11.json"
static_review_relative = (
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v4.json"
)
if (pre.get("files", {}).get(contract_relative, {}).get("sha256") !=
        "07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f" or
        pre.get("files", {}).get(static_review_relative, {}).get("sha256") !=
        "5839954629c9cb77d8626d7ca3c090cc603fcbc92b391731a8f2f14a93f986b4"):
    raise SystemExit("v11/static-review-v4 contract binding mismatch")
content_path = next(path for path in artifact_paths if path.parent.name == "sealed")
content, content_sha, content_bytes = read_json_same_bytes(content_path)
pre_bytes = read_bytes_stable(next(path for path in artifact_paths if path.name == "frozen-inputs.pre.json"))
if (pre != post or pre.get("files") != post.get("files") or
        content != pre or content_bytes != pre_bytes or
        content_path.name != f"frozen-inputs.{content_sha}.json"):
    raise SystemExit("frozen pre/post/content-addressed snapshot mismatch")
cmake = parsed["cmake-source-identity.json"]
static = parsed["static-history-audit.json"]
late = parsed["late-replacement-mutations.json"]
probes = parsed["runner-probes.json"]
control = parsed["runner-control-regression.json"]
compile_plan = parsed["future-compile-plan.json"]
process = parsed["active-process-audit.json"]
if (cmake.get("source_count") != 21 or cmake.get("compile_membership_status") != "GAP" or
        cmake.get("frozen_complete_file_sha256_verified") is not True or
        cmake.get("frozen_cmake_template") != "PASS" or
        cmake.get("actual_configured_argv") != "GAP" or
        cmake.get("consumer_binding", {}).get("unconditional_top_level_set") is not True or
        cmake.get("consumer_binding", {}).get("unconditional_top_level_custom_command") is not True or
        cmake.get("consumer_binding", {}).get("bare_unquoted_exact_consumers") is not True or
        cmake.get("consumer_binding", {}).get("producer_template_exact") is not True or
        cmake.get("consumer_binding", {}).get("canonical_token_spellings") is not True or
        cmake.get("consumer_binding", {}).get("downstream_target_template_exact") is not True or
        cmake.get("consumer_binding", {}).get("competing_producer_count") != 0):
    raise SystemExit("seal CMake structural identity mismatch")
if (static.get("pass") is not True or
        static.get("cmake_directed_mutations_rejected") != 44 or
        len(static.get("constructor_mutations", {}).get("harmful_mutations_rejected", {})) != 26 or
        not all(static.get("constructor_mutations", {}).get("harmful_mutations_rejected", {}).values()) or
        late.get("pass") is not True or not all(late.get("checks", {}).values()) or
        probes.get("pass") is not True or probes.get("probe_count") != 12 or
        control.get("pass") is not True or control.get("mutation_rejected") is not True or
        compile_plan.get("compile_membership_status") != "GAP" or
        process.get("pass") is not True or process.get("owned_background_jobs") != 0):
    raise SystemExit("seal audit PASS/GAP boundary mismatch")
if read_bytes_stable(next(path for path in artifact_paths if path.name == "build.count")) != b"0\n":
    raise SystemExit("build count is not zero")
if build_root.exists():
    raise SystemExit("unauthorized build root exists")
task_log = read_bytes_stable(next(path for path in artifact_paths if path.name == "task-run-status-test.log"))
test_log = read_bytes_stable(next(path for path in artifact_paths if path.name == "build-identity-test.log"))
if b"[task-run-status-test] PASS" not in task_log:
    raise SystemExit("task status directed-test marker missing")
if (b"[qwen-f32-alu-build-identity-test] PASS exact=21" not in test_log or
        b"cpp-lexical=pass" not in test_log or b"cmake-mutations=44/44" not in test_log or
        b"depfile-strict=pass" not in test_log or
        b"FAILED (" in test_log):
    raise SystemExit("identity directed-test marker mismatch")

tool_relative = "npu/version_0820/scripts/qwen_f32_alu_build_identity.py"
test_relative = "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py"
runner_relative = "npu/version_0820/scripts/run-qwen-f32-alu-families-v11.sh"
receipt = {
    "schema": "qwen-f32-alu-v11-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-v11",
    "contract_sha256": "07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f",
    "static_review_v4_contract_sha256":
        "5839954629c9cb77d8626d7ca3c090cc603fcbc92b391731a8f2f14a93f986b4",
    "artifacts": artifacts,
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "content_addressed_snapshot": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "production_constructor": static["production_constructor"],
    "constructor_mutations": static["constructor_mutations"],
    "cmake_directed_mutations_rejected":
        static["cmake_directed_mutations_rejected"],
    "cmake_source_identity": {
        "source_count": 21,
        "ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
        "consumer_binding": cmake["consumer_binding"],
        "frozen_complete_file_sha256": cmake["frozen_complete_file_sha256"],
        "frozen_cmake_template": cmake["frozen_cmake_template"],
        "actual_configured_argv": cmake["actual_configured_argv"],
    },
    "late_replacement_checks": late["checks"],
    "runner_probe_records": probes["records"],
    "runner_control_regression": control,
    "v10_receipt_sha256": static["v10_receipt_sha256"],
    "v10_manifest_sha256": static["v10_manifest_sha256"],
    "v10_binding_sha256": static["v10_binding_sha256"],
    "v10_status_sha256": static["v10_status_sha256"],
    "v4_v10_history_and_production_entries_revalidated":
        static["v4_v10_history_and_production_entries_revalidated"],
    "production_bytes_unchanged": True,
    "predecessor_representative_transactions_passed": 1,
    "representative_transactions_planned": 19,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "canonical_identity_set_sha256":
        "d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385",
    "build_count": 0,
    "build_root_absent": True,
    "invocations": process["invocations"],
    "owned_background_jobs": 0,
    "compile_membership_status": "GAP",
    "frozen_cmake_template": "PASS",
    "actual_configured_argv": "GAP",
    "tool_build_identity_status": "GAP",
    "deadline_edge_dynamic_status": "GAP",
    "event_time_five_stage_ledger_status": "GAP",
    "p00_p18_dynamic_status": "GAP",
    "strict_backend_status": "GAP",
    "backend_concurrency_status": "CONDITIONAL_UNKNOWN",
    "canonical_rollout_status": "GAP",
    "qwen_status": "GAP",
    "synthesis_sta_ppa_status": "GAP",
    "future_build_admission": {
        "must_compare_current_inputs_to_content_snapshot": True,
        "snapshot_path": content_path.relative_to(root).as_posix(),
        "snapshot_sha256": content_sha,
    },
    "threat_model": {
        "private_fresh_namespace": True,
        "stable_reopen_before_and_after_status": True,
        "root_or_kernel_replacement_after_last_lstat": "GAP",
    },
    "source_sha256": {
        runner_relative: pre["files"][runner_relative]["sha256"],
        tool_relative: pre["files"][tool_relative]["sha256"],
        test_relative: pre["files"][test_relative]["sha256"],
    },
    "publication_order": [
        "private-staging-artifacts", "content-addressed-frozen-snapshot",
        "receipt", "receipt-sidecar", "bound-manifest", "expected-status",
        "final-binding", "full-late-revalidation-before-status", "PASS-status",
        "full-late-revalidation-after-status", "single-final-PASS-marker",
    ],
}
atomic_write_json(receipt_path, receipt)
receipt_value, receipt_sha, receipt_bytes = read_json_same_bytes(receipt_path)
if receipt_value.get("task_id") != "qwen-f32-alu-families-v11":
    raise SystemExit("published receipt validation failed")
sidecar_bytes = f"{receipt_sha}  {receipt_path.name}\n".encode("utf-8")
atomic_write_bytes(sidecar_path, sidecar_bytes)
sidecar_observed = read_bytes_stable(sidecar_path)
if sidecar_observed != sidecar_bytes:
    raise SystemExit("receipt sidecar validation failed")

bound = dict(artifacts)
bound[receipt_path.relative_to(root).as_posix()] = build_artifact_record(
    root, receipt_path, "qwen-f32-alu-v11-preflight-receipt-v1"
)
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(
    root, sidecar_path, None
)
manifest = {
    "schema": "qwen-f32-alu-v11-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-v11",
    "artifact_count": len(bound),
    "artifacts": bound,
    "artifact_identity": revalidate_bound_artifacts(root, bound),
    "receipt_sha256": receipt_sha,
}
atomic_write_json(manifest_path, manifest)
manifest_value, manifest_sha, _ = read_json_same_bytes(manifest_path)
if manifest_value.get("artifact_count") != len(bound):
    raise SystemExit("bound manifest count mismatch")
revalidate_bound_artifacts(root, manifest_value["artifacts"])

expected_bytes = b"PASS\n"
atomic_write_bytes(expected_status_path, expected_bytes)
expected_observed = read_bytes_stable(expected_status_path)
binding = {
    "schema": "qwen-f32-alu-v11-final-binding-v1",
    "task_id": "qwen-f32-alu-families-v11",
    "receipt_sha256": receipt_sha,
    "receipt_sidecar_sha256": sha256_bytes(sidecar_observed),
    "bound_artifacts_sha256": manifest_sha,
    "artifact_identity_sha256": manifest["artifact_identity"]["artifact_identity_sha256"],
    "content_addressed_snapshot_path": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "expected_final_status_sha256": sha256_bytes(expected_observed),
    "actual_status_path": status_path.relative_to(root).as_posix(),
    "full_revalidation_before_and_after_status": True,
    "late_failure_must_overwrite_status": True,
    "pass_marker_is_final_successful_action": True,
}
atomic_write_json(binding_path, binding)
binding_value, binding_sha, _ = read_json_same_bytes(binding_path)
if (binding_value.get("receipt_sha256") != receipt_sha or
        binding_value.get("bound_artifacts_sha256") != manifest_sha or
        binding_value.get("content_addressed_snapshot_sha256") != content_sha or
        binding_value.get("expected_final_status_sha256") != sha256_bytes(expected_observed)):
    raise SystemExit("final binding recheck failed")
print(
    receipt_sha,
    binding_sha,
    manifest_sha,
    sha256_bytes(expected_observed),
    content_sha,
    pre["files"][runner_relative]["sha256"],
    pre["files"][tool_relative]["sha256"],
    pre["files"][test_relative]["sha256"],
)
PY
}

late_revalidate() {
    local phase="$1"
    local receipt_sha="$2"
    local binding_sha="$3"
    local manifest_sha="$4"
    local expected_sha="$5"
    local snapshot_sha="$6"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$TASK_ID" "$BUILD_ROOT" "$phase" \
        "$RUN_STATUS" "$RECEIPT" "$RECEIPT_SIDECAR" "$BOUND_MANIFEST" \
        "$EXPECTED_STATUS" "$FINAL_BINDING" "$receipt_sha" "$binding_sha" \
        "$manifest_sha" "$expected_sha" "$snapshot_sha" <<'PY'
import json
import os
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
task_id = sys.argv[3]
build_root = pathlib.Path(sys.argv[4])
phase = sys.argv[5]
status_path = pathlib.Path(sys.argv[6])
receipt_path = pathlib.Path(sys.argv[7])
sidecar_path = pathlib.Path(sys.argv[8])
manifest_path = pathlib.Path(sys.argv[9])
expected_path = pathlib.Path(sys.argv[10])
binding_path = pathlib.Path(sys.argv[11])
expected_receipt_sha = sys.argv[12]
expected_binding_sha = sys.argv[13]
expected_manifest_sha = sys.argv[14]
expected_status_sha = sys.argv[15]
expected_snapshot_sha = sys.argv[16]

receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
binding, binding_sha, _ = read_json_same_bytes(binding_path)
sidecar = read_bytes_stable(sidecar_path)
expected = read_bytes_stable(expected_path)
actual = read_bytes_stable(status_path)
if (receipt_sha != expected_receipt_sha or binding_sha != expected_binding_sha or
        manifest_sha != expected_manifest_sha or sha256_bytes(expected) != expected_status_sha or
        expected != b"PASS\n"):
    raise SystemExit("late final document identity drift")
if sidecar != f"{receipt_sha}  {receipt_path.name}\n".encode("utf-8"):
    raise SystemExit("late receipt sidecar drift")
if (manifest.get("receipt_sha256") != receipt_sha or
        binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != manifest_sha or
        binding.get("expected_final_status_sha256") != expected_status_sha or
        binding.get("content_addressed_snapshot_sha256") != expected_snapshot_sha):
    raise SystemExit("late receipt/manifest/binding semantic drift")
reopened = revalidate_bound_artifacts(root, manifest["artifacts"])
if reopened.get("artifact_count") != manifest.get("artifact_count"):
    raise SystemExit("late bound artifact count drift")

snapshot_relative = binding["content_addressed_snapshot_path"]
snapshot_path = root / snapshot_relative
snapshot, snapshot_sha, snapshot_bytes = read_json_same_bytes(snapshot_path)
if (snapshot_sha != expected_snapshot_sha or
        snapshot_path.name != f"frozen-inputs.{snapshot_sha}.json"):
    raise SystemExit("content-addressed snapshot identity drift")


def capture(relative):
    path = root / relative
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        data = read_bytes_stable(resolved)
        try:
            resolved_name = resolved.relative_to(root).as_posix()
        except ValueError:
            resolved_name = str(resolved)
        return {
            "type": "symlink",
            "link_target": target,
            "sha256": sha256_bytes(target.encode("utf-8")),
            "resolved_path": resolved_name,
            "resolved_sha256": sha256_bytes(data),
            "resolved_size_bytes": len(data),
        }
    data = read_bytes_stable(path)
    json_validated = False
    if path.suffix == ".json":
        json.loads(data)
        json_validated = True
    return {
        "type": "regular",
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
        "json_validated_from_same_bytes": json_validated,
    }


current_names = set(snapshot["explicit_paths"])
for relative_root in snapshot["directory_roots"]:
    directory = root / relative_root
    if not directory.is_dir() or directory.is_symlink():
        raise SystemExit(f"late frozen directory invalid: {relative_root}")
    for path in sorted(directory.rglob("*")):
        if path.is_dir() and not path.is_symlink():
            continue
        current_names.add(path.relative_to(root).as_posix())
if current_names != set(snapshot["files"]):
    raise SystemExit("late frozen source directory membership drift")
for relative, expected_entry in snapshot["files"].items():
    if capture(relative) != expected_entry:
        raise SystemExit(f"late frozen source/DSO drift: {relative}")
if receipt.get("frozen_input_identity_sha256") != snapshot.get("identity_sha256"):
    raise SystemExit("late frozen snapshot/receipt identity mismatch")
if read_bytes_stable(root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v11/staging/build.count") != b"0\n":
    raise SystemExit("late build count drift")
if build_root.exists():
    raise SystemExit("late unauthorized build root exists")

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
        )
    except OSError:
        continue
    if task_id in command:
        matches.append(int(entry.name))
if matches:
    raise SystemExit(f"late active owned process detected: {matches}")
if phase == "before-status":
    if actual != b"RUNNING\n":
        raise SystemExit("status became PASS before full late revalidation")
elif phase == "after-status":
    if actual != expected:
        raise SystemExit("actual PASS status differs from bound expected status")
else:
    raise SystemExit(f"unknown late revalidation phase: {phase}")
print(sha256_bytes(actual))
PY
}

run_preflight() {
    [[ ! -e "$LOG_ROOT" ]] || fail "fresh log root exists=$LOG_ROOT"
    [[ ! -e "$COMPILER_ROOT" ]] || fail "fresh compiler root exists=$COMPILER_ROOT"
    [[ ! -e "$BUILD_ROOT" ]] || fail "fresh build root exists=$BUILD_ROOT"
    mkdir -m 700 -- "$LOG_ROOT" "$COMPILER_ROOT"
    mkdir -m 700 -- "$STAGING_ROOT" "$WORK_ROOT" "$SEALED_ROOT"
    mkdir -m 700 -- "$TMPDIR"

    task_run_status_init "$RUN_STATUS"
    STATUS_INITIALIZED=1
    install_runner_traps
    atomic_write_text "$BUILD_COUNT" $'0\n'

    task_run_status_stage "frozen-input-pre-snapshot"
    snapshot_inputs "$PRE_SNAPSHOT"

    task_run_status_stage "task-status-helper-tests"
    run_atomic_log "$TASK_STATUS_LOG" bash "$STATUS_HELPER_TEST"
    [[ "$(sed -n '1p' "$TASK_STATUS_LOG")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper directed-test marker mismatch"

    task_run_status_stage "runner-fail-closed-probes"
    run_runner_probes

    task_run_status_stage "caller-errexit-regression"
    run_runner_control_regression

    task_run_status_stage "identity-directed-tests"
    QWEN_F32_ALU_REPO_ROOT="$REPO_ROOT" \
        run_atomic_log "$IDENTITY_TEST_LOG" python3 "$BUILD_IDENTITY_TEST"
    [[ "$(sed -n '/\[qwen-f32-alu-build-identity-test\] PASS/p' "$IDENTITY_TEST_LOG")" != "" ]] ||
        fail "build identity directed-test marker mismatch"

    task_run_status_stage "restricted-cmake-identity"
    run_atomic_log "$IDENTITY_LOG" python3 "$BUILD_IDENTITY_TOOL" \
        audit-cmake --repo-root "$REPO_ROOT" --cmake "$CMAKE_FILE" \
        --output "$CMAKE_IDENTITY"

    task_run_status_stage "cpp-cmake-history-static-audit"
    write_static_history_audit

    task_run_status_stage "late-replacement-mutations"
    write_late_replacement_mutations

    task_run_status_stage "future-compile-gap-plan"
    write_compile_gap_plan

    task_run_status_stage "process-build-boundary"
    [[ "$(<"$BUILD_COUNT")" == "0" ]] || fail "build count changed"
    [[ ! -e "$BUILD_ROOT" ]] || fail "build root was created"
    write_process_audit

    task_run_status_stage "frozen-input-post-snapshot"
    snapshot_inputs "$POST_SNAPSHOT"

    task_run_status_stage "content-addressed-snapshot-publication"
    CONTENT_SNAPSHOT=$(publish_content_snapshot)
    [[ "$CONTENT_SNAPSHOT" == "$SEALED_ROOT"/frozen-inputs.*.json ]] ||
        fail "content-addressed snapshot path malformed"

    task_run_status_stage "receipt-manifest-binding-publication"
    local seal_result
    seal_result=$(seal_preflight)
    local receipt_sha=""
    local binding_sha=""
    local manifest_sha=""
    local expected_status_sha=""
    local snapshot_sha=""
    local runner_sha=""
    local tool_sha=""
    local test_sha=""
    read -r receipt_sha binding_sha manifest_sha expected_status_sha snapshot_sha \
        runner_sha tool_sha test_sha <<<"$seal_result"
    for value in "$receipt_sha" "$binding_sha" "$manifest_sha" "$expected_status_sha" \
        "$snapshot_sha" "$runner_sha" "$tool_sha" "$test_sha"; do
        [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "seal returned invalid SHA-256=$value"
    done

    task_run_status_stage "full-late-revalidation-before-status"
    local before_status_sha
    before_status_sha=$(late_revalidate before-status "$receipt_sha" "$binding_sha" \
        "$manifest_sha" "$expected_status_sha" "$snapshot_sha")
    [[ "$before_status_sha" =~ ^[0-9a-f]{64}$ ]] ||
        fail "before-status revalidation did not return status SHA-256"
    FINAL_BINDING_VERIFIED=1

    task_run_status_stage "final-status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0

    task_run_status_stage "full-late-revalidation-after-status"
    local status_sha
    status_sha=$(late_revalidate after-status "$receipt_sha" "$binding_sha" \
        "$manifest_sha" "$expected_status_sha" "$snapshot_sha")
    [[ "$status_sha" == "$expected_status_sha" ]] ||
        fail "post-status revalidation hash mismatch"
    FINAL_PASS_VERIFIED=1

    task_run_status_stage "single-final-pass-marker"
    # 必须保持本函数和脚本的最后一个成功动作；EXIT 仅在 rc0 且该动作完成后保留 PASS。
    publish_pass_marker "$receipt_sha" "$binding_sha" "$manifest_sha" "$status_sha" \
        "$snapshot_sha" "$runner_sha" "$tool_sha" "$test_sha"
}

run_preflight
