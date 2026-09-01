#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families v9：只做 build-free source/evidence closure。
# 本 runner 不 edit/source/eval/execute v4/v5/v6/v7/v8；--compile/--execute 在当前授权中 fail closed。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-v9"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-v9.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v9.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-v9-material.md"
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
RUNNER_CONTROL_REGRESSION_AUDIT="$COMPILER_ROOT/runner-control-regression-audit.json"
COMPILE_PLAN="$COMPILER_ROOT/future-compile-plan.json"
PROCESS_AUDIT="$COMPILER_ROOT/preflight-active-process-audit.json"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_HASH="$LOG_ROOT/preflight.receipt.sha256"
BOUND_ARTIFACTS="$LOG_ROOT/preflight.bound-artifacts.json"
EXPECTED_STATUS="$LOG_ROOT/preflight.expected-status"
FINAL_BINDING="$LOG_ROOT/preflight.final-binding.json"

CONTRACT_SHA256="bfbe77a917d71654298457d782bd37692340561e01ec0b4bfe327590b459549b"
V8_CONTRACT_SHA256="5ec6e4f64b507f1e7c2765845162bbb6c5d83348b98d402ec3d73d30b7e2179a"
V7_CONTRACT_SHA256="03a8997eedaa976371b22b3c0e6477404c066dac069c537fcdce596793f044cf"
V6_CONTRACT_SHA256="a1542ef8276732158e6d25b5505182a3b4f8293b471bdde371530a9f26050e12"
PRODUCTION_CPP_SHA256="b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e"
BUILD_IDENTITY_TOOL_SHA256="b2dfa40a301da66a5a35f6a12d5f406d2b1eae538dc5dcd815e9414f9e14717e"
BUILD_IDENTITY_TEST_SHA256="bce7caa9d4d25c189643dab7b9d5a54baebd732ed8bb1e112993c63f34c6139c"
V8_RUNNER_SHA256="0b996f27077be3ca4974ba072375d8432e51151d597d7912a748da5abff3ae78"
V8_PREFLIGHT_STATUS_SHA256="95fd2225f03902858916e2005c5f62feea38ef98c87fd67e86b75ee8aa644176"
V8_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
V8_RUNNER_PROBE_AUDIT_SHA256="fadb38c094b75f6bb089bb2b1e68fc15b6ab32c3176aa21ca05a8dc85119fd74"
V8_RUNNER_CONTROL_REGRESSION_SHA256="f23d8b440b6337068f67fb62ce5d639bcb28cfc8b3fcaba47c18158942fdb682"
V8_BUILD_IDENTITY_TEST_LOG_SHA256="eac5230eb65138ac8ccfc548743303810f1d2d9f03a44960004b7337f94cd7bf"
V7_RUNNER_SHA256="14a9c13dde171993bf0ce46074b040e883b865fd7a9d62a766cabace347fc4b5"
V7_PREFLIGHT_STATUS_SHA256="56a8ebf401da6a507c24a8a7ab92249e3b10fe353f54fd9f7d8e24c739cbc4f6"
V7_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
V7_RUNNER_PROBE_AUDIT_SHA256="405571ad3d969ff6a1a9339a72c7246bec2b0debaeb1149477a6bfc718a36f3f"
V7_RUNNER_CONTROL_REGRESSION_SHA256="8ce0b4f1bd0639f8c1ff00cedc870bbd47756fcedf7da272aff53ed4b9d9bcf0"
V7_BUILD_IDENTITY_TEST_LOG_SHA256="a5e4f3755e1c379599035b58ea853f37bf993e475692c41e7980b1df027c4fd2"
V6_RUNNER_SHA256="56eab02a2ea7652cd583dbfee601c32e27090161e33fa37fe305d23a8e6e3f1f"
V6_PREFLIGHT_STATUS_SHA256="6d9156f1d993033907936814719c5debd82f6bdf16b490cfd2fda87eaa3fa6ab"
V6_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
V6_EARLY_EXIT_STATUS_SHA256="26e351cad173449c8de1decc6f57465f9f250e38c329414c50a499a73ecd2da0"
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
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v9.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v9-material.md
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
    npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v9.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/preflight.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v6/runner-probe-early-exit.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/preflight.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build.count
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build-identity-test.log
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/runner-probe-audit.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/runner-control-regression-audit.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/preflight.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build.count
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build-identity-test.log
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/runner-probe-audit.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/runner-control-regression-audit.json
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
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-V9][FAIL] $*" >&2
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
    # 以条件命令捕获预期负向 rc；不得在 helper 内改变调用者的 errexit 状态。
    if "$@" >"$temporary" 2>&1; then
        command_rc=0
    else
        command_rc=$?
    fi
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
    "schema": "qwen-f32-alu-v9-input-identity-v1",
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

# 该内部模式只为 regression mutation 构造 v6 的错误控制流；正常 helper 不含 set +/-e。
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
    mutant_atomic_log "$nested_log" bash "$RUNNER" \
        --internal-probe early-exit "$nested_status"
    local nested_rc=$?
    set -e
    # 正确的 mutation rejection 必须在抵达该分类收据前，以 rc=1 fail closed。
    atomic_write_text "$classifier_completion" "$nested_rc"$'\n'
}

publish_pass_marker() {
    local receipt_sha="$1"
    local binding_sha="${2:-unset}"
    local status_sha="${3:-unset}"
    local bound_artifacts_sha="${4:-unset}"
    local expected_status_sha="${5:-unset}"
    [[ $FINAL_PASS_VERIFIED -eq 1 ]] || fail "PASS marker denied before final status verification"
    [[ $FINAL_BINDING_VERIFIED -eq 1 ]] || fail "PASS marker denied before final binding verification"
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V9][PREFLIGHT-PASS] build_count=0 build_root_absent=1 verilator=0 cmake=0 ninja=0 make=0 binary=0 execute=0 owned_background_jobs=0 sources=21 source_order=exact cmake_command_binding=1 cmake_depends_binding=1 identity_tests=15 declared_category_collision=reject production_definition=unique production_body=balanced production_call_count=1 production_arg_count=11 production_arg_tail=nullptr,0,result structural_mutations=6/6 successor_rename_independent=1 runner_probes=8 runner_probe_rcs=1,7,9,129,130,143,1,1 regression_mutation_rejected=1 representative_predecessor_passed=1 representative_planned=19 verified_canonical_completed=0 remaining=1079 deadline_edge=GAP event_time_ledger=GAP p00_p18_dynamic=GAP rtl_dynamic=GAP compile_membership=GAP tool_build_identity=GAP synthesis_sta_ppa=GAP contract_sha256=$CONTRACT_SHA256 production_cpp_sha256=$PRODUCTION_CPP_SHA256 identity_tool_sha256=$BUILD_IDENTITY_TOOL_SHA256 identity_test_sha256=$BUILD_IDENTITY_TEST_SHA256 v8_contract_sha256=$V8_CONTRACT_SHA256 v8_runner_sha256=$V8_RUNNER_SHA256 v8_preflight_status_sha256=$V8_PREFLIGHT_STATUS_SHA256 v8_build_count_sha256=$V8_BUILD_COUNT_SHA256 v8_probe_audit_sha256=$V8_RUNNER_PROBE_AUDIT_SHA256 v8_control_regression_sha256=$V8_RUNNER_CONTROL_REGRESSION_SHA256 v8_test_log_sha256=$V8_BUILD_IDENTITY_TEST_LOG_SHA256 v7_contract_sha256=$V7_CONTRACT_SHA256 v7_runner_sha256=$V7_RUNNER_SHA256 v7_preflight_status_sha256=$V7_PREFLIGHT_STATUS_SHA256 v7_build_count_sha256=$V7_BUILD_COUNT_SHA256 v7_probe_audit_sha256=$V7_RUNNER_PROBE_AUDIT_SHA256 v7_control_regression_sha256=$V7_RUNNER_CONTROL_REGRESSION_SHA256 v7_test_log_sha256=$V7_BUILD_IDENTITY_TEST_LOG_SHA256 v6_runner_sha256=$V6_RUNNER_SHA256 v6_preflight_status_sha256=$V6_PREFLIGHT_STATUS_SHA256 v6_build_count_sha256=$V6_BUILD_COUNT_SHA256 v6_early_exit_status_sha256=$V6_EARLY_EXIT_STATUS_SHA256 receipt_sha256=$receipt_sha bound_artifacts_sha256=$bound_artifacts_sha expected_status_sha256=$expected_status_sha binding_sha256=$binding_sha status_sha256=$status_sha"
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
        "[NPU-QWEN-F32-ALU-FAMILIES-V9][GAP] compile mode is structurally planned but requires a new explicit build authorization; preserved verFiles/depfile audit is not executed" >&2
    exit 2
fi

if [[ "$1" == "--execute" ]]; then
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V9][GAP] execute requires later compile membership PASS and explicit shell ownership authorization" >&2
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
    "schema": "qwen-f32-alu-v9-runner-probes-v1",
    "pass": True,
    "probe_count": len(records),
    "records": records,
})
PY
}

run_runner_control_regression() {
    local nested_status="$COMPILER_ROOT/runner-control-regression-nested.status"
    local nested_log="$COMPILER_ROOT/runner-control-regression-nested.log"
    local mutant_log="$COMPILER_ROOT/runner-control-regression-mutant.log"
    local classifier_completion="$COMPILER_ROOT/runner-control-regression-classified.rc"
    local rc_path="$COMPILER_ROOT/runner-control-regression-mutant.rc"
    local mutation_rc=0

    set +e
    run_atomic_log "$mutant_log" bash "$RUNNER" --internal-errexit-mutation \
        "$nested_status" "$nested_log" "$classifier_completion"
    mutation_rc=$?
    set -e
    [[ $mutation_rc -eq 1 ]] ||
        fail "errexit regression mutation rc mismatch expected=1 actual=$mutation_rc"
    [[ ! -e "$classifier_completion" ]] ||
        fail "errexit regression mutation reached forbidden classifier receipt"
    [[ "$(sed -n '1p' "$nested_status")" == \
       "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0" ]] ||
        fail "errexit regression mutation nested status mismatch"
    [[ "$(sed -n '/PREFLIGHT-PASS/p' "$nested_log")" == "" ]] ||
        fail "errexit regression mutation exposed PASS marker"
    atomic_write_text "$rc_path" "$mutation_rc"$'\n'

    python3 - "$NPU_ROOT/scripts" "$nested_status" "$nested_log" \
        "$mutant_log" "$classifier_completion" "$rc_path" \
        "$RUNNER_CONTROL_REGRESSION_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable
nested_status = pathlib.Path(sys.argv[2])
nested_log = pathlib.Path(sys.argv[3])
mutant_log = pathlib.Path(sys.argv[4])
classifier_completion = pathlib.Path(sys.argv[5])
rc_path = pathlib.Path(sys.argv[6])
output = pathlib.Path(sys.argv[7])
status = read_bytes_stable(nested_status).decode().strip()
mutation_rc = int(read_bytes_stable(rc_path))
checks = {
    "mutant_return_code_is_one": mutation_rc == 1,
    "nested_probe_status_is_expected_fail": status == (
        "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0"
    ),
    "caller_classifier_not_reached": not classifier_completion.exists(),
    "nested_positive_marker_absent": b"[PREFLIGHT-PASS]" not in read_bytes_stable(nested_log),
    "mutant_outer_positive_marker_absent": b"[PREFLIGHT-PASS]" not in read_bytes_stable(mutant_log),
}
if not all(checks.values()):
    raise SystemExit(f"runner control regression mutation unexpectedly accepted: {checks}")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-v9-runner-control-regression-v1",
    "pass": True,
    "mutation": "helper_reenables_errexit_before_returning_expected_negative_rc",
    "mutation_rejected": True,
    "return_code": mutation_rc,
    "checks": checks,
})
PY
}

write_history_audit() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$PRE_INPUT_IDENTITY" \
        "$HISTORY_AUDIT" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json, read_bytes_stable, read_json_same_bytes,
)

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
snapshot, _, _ = read_json_same_bytes(pathlib.Path(sys.argv[3]))
output = pathlib.Path(sys.argv[4])
files = snapshot["files"]


def digest(relative):
    return files[relative]["sha256"]


fixed = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v9.json": "bfbe77a917d71654298457d782bd37692340561e01ec0b4bfe327590b459549b",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8.json": "5ec6e4f64b507f1e7c2765845162bbb6c5d83348b98d402ec3d73d30b7e2179a",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7.json": "03a8997eedaa976371b22b3c0e6477404c066dac069c537fcdce596793f044cf",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6.json": "a1542ef8276732158e6d25b5505182a3b4f8293b471bdde371530a9f26050e12",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp": "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e",
    "npu/version_0820/scripts/qwen_f32_alu_build_identity.py": "b2dfa40a301da66a5a35f6a12d5f406d2b1eae538dc5dcd815e9414f9e14717e",
    "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py": "bce7caa9d4d25c189643dab7b9d5a54baebd732ed8bb1e112993c63f34c6139c",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh": "0b996f27077be3ca4974ba072375d8432e51151d597d7912a748da5abff3ae78",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/preflight.status": "95fd2225f03902858916e2005c5f62feea38ef98c87fd67e86b75ee8aa644176",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build.count": "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build-identity-test.log": "eac5230eb65138ac8ccfc548743303810f1d2d9f03a44960004b7337f94cd7bf",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/runner-probe-audit.json": "fadb38c094b75f6bb089bb2b1e68fc15b6ab32c3176aa21ca05a8dc85119fd74",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/runner-control-regression-audit.json": "f23d8b440b6337068f67fb62ce5d639bcb28cfc8b3fcaba47c18158942fdb682",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh": "14a9c13dde171993bf0ce46074b040e883b865fd7a9d62a766cabace347fc4b5",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/preflight.status": "56a8ebf401da6a507c24a8a7ab92249e3b10fe353f54fd9f7d8e24c739cbc4f6",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build.count": "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build-identity-test.log": "a5e4f3755e1c379599035b58ea853f37bf993e475692c41e7980b1df027c4fd2",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/runner-probe-audit.json": "405571ad3d969ff6a1a9339a72c7246bec2b0debaeb1149477a6bfc718a36f3f",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/runner-control-regression-audit.json": "8ce0b4f1bd0639f8c1ff00cedc870bbd47756fcedf7da272aff53ed4b9d9bcf0",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh": "56eab02a2ea7652cd583dbfee601c32e27090161e33fa37fe305d23a8e6e3f1f",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/preflight.status": "6d9156f1d993033907936814719c5debd82f6bdf16b490cfd2fda87eaa3fa6ab",
    "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/build.count": "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v6/runner-probe-early-exit.status": "26e351cad173449c8de1decc6f57465f9f250e38c329414c50a499a73ecd2da0",
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

v6_status_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/preflight.status"
v6_build_count_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v6/build.count"
v6_early_status_relative = (
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v6/"
    "runner-probe-early-exit.status"
)
v6_status = read_bytes_stable(root / v6_status_relative)
v6_build_count = read_bytes_stable(root / v6_build_count_relative)
v6_early_status = read_bytes_stable(root / v6_early_status_relative)
if v6_status != b"FAIL rc=1 stage=runner-fail-closed-probes evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("v6 preflight FAIL status semantic mismatch")
if v6_build_count != b"0\n":
    raise SystemExit("v6 build count semantic mismatch")
if v6_early_status != b"FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("v6 early-exit probe status semantic mismatch")
if (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-v6").exists():
    raise SystemExit("v6 build root unexpectedly exists")
v6_failed_predecessor = {
    "contract_sha256": fixed[
        "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v6.json"
    ],
    "runner_sha256": fixed[
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh"
    ],
    "preflight_status_sha256": fixed[v6_status_relative],
    "preflight_status": v6_status.decode().strip(),
    "preflight_return_code": 1,
    "build_count_sha256": fixed[v6_build_count_relative],
    "build_count": 0,
    "build_root_absent": True,
    "early_exit_status_sha256": fixed[v6_early_status_relative],
    "early_exit_status": v6_early_status.decode().strip(),
    "root_cause": "run_atomic_log_reenabled_caller_errexit_before_negative_return",
    "rerun_forbidden": True,
}

v8_status_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/preflight.status"
v8_build_count_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build.count"
v8_test_log_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v8/build-identity-test.log"
v8_probe_relative = (
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/runner-probe-audit.json"
)
v8_control_relative = (
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v8/"
    "runner-control-regression-audit.json"
)
v8_status = read_bytes_stable(root / v8_status_relative)
v8_build_count = read_bytes_stable(root / v8_build_count_relative)
v8_test_log = read_bytes_stable(root / v8_test_log_relative)
v8_probes, v8_probe_sha, _ = read_json_same_bytes(root / v8_probe_relative)
v8_control, v8_control_sha, _ = read_json_same_bytes(root / v8_control_relative)
if v8_status != b"FAIL rc=1 stage=static-source-audit evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("v8 preflight FAIL status semantic mismatch")
if v8_build_count != b"0\n":
    raise SystemExit("v8 build count semantic mismatch")
if (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-v8").exists():
    raise SystemExit("v8 build root unexpectedly exists")
expected_v8_probe_rcs = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
if (v8_probe_sha != fixed[v8_probe_relative] or
        v8_probes.get("schema") != "qwen-f32-alu-v8-runner-probes-v1" or
        v8_probes.get("pass") is not True or
        v8_probes.get("probe_count") != 8 or
        {name: item.get("return_code")
         for name, item in v8_probes.get("records", {}).items()} != expected_v8_probe_rcs):
    raise SystemExit("v8 runner probe audit semantic mismatch")
if (v8_control_sha != fixed[v8_control_relative] or
        v8_control.get("schema") != "qwen-f32-alu-v8-runner-control-regression-v1" or
        v8_control.get("pass") is not True or
        v8_control.get("mutation_rejected") is not True or
        v8_control.get("return_code") != 1 or
        not all(v8_control.get("checks", {}).values())):
    raise SystemExit("v8 runner control regression semantic mismatch")
if (b"Ran 15 tests" not in v8_test_log or
        b"\nOK\n" not in v8_test_log or
        b"[qwen-f32-alu-build-identity-test] PASS exact=21" not in v8_test_log or
        b"FAILED (" in v8_test_log):
    raise SystemExit("v8 build-identity PASS log semantic mismatch")
v8_failed_predecessor = {
    "contract_sha256": fixed[
        "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v8.json"
    ],
    "runner_sha256": fixed[
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh"
    ],
    "bash_n_return_code": 0,
    "preflight_status_sha256": fixed[v8_status_relative],
    "preflight_status": v8_status.decode().strip(),
    "preflight_return_code": 1,
    "build_count_sha256": fixed[v8_build_count_relative],
    "build_count": 0,
    "build_root_absent": True,
    "runner_probe_audit_sha256": v8_probe_sha,
    "runner_probe_count": 8,
    "runner_probe_return_codes": expected_v8_probe_rcs,
    "runner_control_regression_audit_sha256": v8_control_sha,
    "runner_control_regression_mutation_rejected": True,
    "build_identity_test_source_sha256": fixed[
        "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py"
    ],
    "build_identity_test_log_sha256": fixed[v8_test_log_relative],
    "build_identity_tests_run": 15,
    "build_identity_test_failures": 0,
    "root_cause": "stale_successor_function_name_slice_raised_before_11_argument_audit",
    "rerun_forbidden": True,
}

v7_status_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/preflight.status"
v7_build_count_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build.count"
v7_test_log_relative = "npu/version_0820/tmp/logs/qwen-f32-alu-families-v7/build-identity-test.log"
v7_probe_relative = (
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/runner-probe-audit.json"
)
v7_control_relative = (
    "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v7/"
    "runner-control-regression-audit.json"
)
v7_status = read_bytes_stable(root / v7_status_relative)
v7_build_count = read_bytes_stable(root / v7_build_count_relative)
v7_test_log = read_bytes_stable(root / v7_test_log_relative)
v7_probes, v7_probe_sha, _ = read_json_same_bytes(root / v7_probe_relative)
v7_control, v7_control_sha, _ = read_json_same_bytes(root / v7_control_relative)
if v7_status != b"FAIL rc=1 stage=cmake-source-identity-test evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("v7 preflight FAIL status semantic mismatch")
if v7_build_count != b"0\n":
    raise SystemExit("v7 build count semantic mismatch")
if (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-v7").exists():
    raise SystemExit("v7 build root unexpectedly exists")
expected_v7_probe_rcs = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
if (v7_probe_sha != fixed[v7_probe_relative] or
        v7_probes.get("schema") != "qwen-f32-alu-v7-runner-probes-v1" or
        v7_probes.get("pass") is not True or
        v7_probes.get("probe_count") != 8 or
        {name: item.get("return_code")
         for name, item in v7_probes.get("records", {}).items()} != expected_v7_probe_rcs):
    raise SystemExit("v7 runner probe audit semantic mismatch")
if (v7_control_sha != fixed[v7_control_relative] or
        v7_control.get("schema") != "qwen-f32-alu-v7-runner-control-regression-v1" or
        v7_control.get("pass") is not True or
        v7_control.get("mutation_rejected") is not True or
        v7_control.get("return_code") != 1 or
        not all(v7_control.get("checks", {}).values())):
    raise SystemExit("v7 runner control regression semantic mismatch")
if (b"test_declared_verfiles_category_collision_rejected" not in v7_test_log or
        b"actual compiler dependency files must be sealed" not in v7_test_log or
        b"Ran 15 tests" not in v7_test_log or
        b"FAILED (failures=1)" not in v7_test_log or
        b"[qwen-f32-alu-build-identity-test] PASS" in v7_test_log):
    raise SystemExit("v7 build-identity failure log semantic mismatch")
v7_failed_predecessor = {
    "contract_sha256": fixed[
        "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v7.json"
    ],
    "runner_sha256": fixed[
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh"
    ],
    "preflight_status_sha256": fixed[v7_status_relative],
    "preflight_status": v7_status.decode().strip(),
    "preflight_return_code": 1,
    "build_count_sha256": fixed[v7_build_count_relative],
    "build_count": 0,
    "build_root_absent": True,
    "runner_probe_audit_sha256": v7_probe_sha,
    "runner_probe_count": 8,
    "runner_probe_return_codes": expected_v7_probe_rcs,
    "runner_control_regression_audit_sha256": v7_control_sha,
    "runner_control_regression_mutation_rejected": True,
    "build_identity_test_log_sha256": fixed[v7_test_log_relative],
    "build_identity_tests_run": 15,
    "build_identity_test_failures": 1,
    "root_cause": "declared_category_collision_fixture_omitted_compiler_depfile_prerequisite",
    "rerun_forbidden": True,
}

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
    "schema": "qwen-f32-alu-v9-history-audit-v1",
    "pass": True,
    "v8_failed_predecessor": v8_failed_predecessor,
    "v7_failed_predecessor": v7_failed_predecessor,
    "v6_failed_predecessor": v6_failed_predecessor,
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
    "frozen_source_sha256": {
        "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp": fixed[
            "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp"
        ],
        "npu/version_0820/scripts/qwen_f32_alu_build_identity.py": fixed[
            "npu/version_0820/scripts/qwen_f32_alu_build_identity.py"
        ],
        "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py": fixed[
            "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py"
        ],
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh": fixed[
            "npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh"
        ],
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh": fixed[
            "npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh"
        ],
        "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh": fixed[
            "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh"
        ],
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
    # 保留字节位置，便于把结构边界映射回冻结的 production source。
    result = []
    index = 0
    state = "code"
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        if state == "code":
            if char == "/" and nxt == "/":
                state = "line"
                result.append("  ")
                index += 2
                continue
            if char == "/" and nxt == "*":
                state = "block"
                result.append("  ")
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
            else:
                result.append(" ")
            index += 1
            continue
        if state == "block":
            if char == "*" and nxt == "/":
                result.append("  ")
                state = "code"
                index += 2
                continue
            if char == "\n":
                result.append("\n")
            else:
                result.append(" ")
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
    stripped = "".join(result)
    if len(stripped) != len(text):
        raise IdentityError("comment stripping changed source offsets")
    return stripped


def extract_balanced(text, opening, open_char, close_char):
    if opening >= len(text) or text[opening] != open_char:
        raise IdentityError(f"balanced extractor opening mismatch: {open_char}")
    depth = 0
    state = "code"
    for index in range(opening, len(text)):
        char = text[index]
        if state != "code":
            if char == "\\" and index + 1 < len(text):
                # 下一字符在本次平衡中只属于 literal；主循环随后仍会看到它，
                # 但 state 保持 literal，故不会把 delimiter 当成结构。
                continue
            if char == state and (index == 0 or text[index - 1] != "\\"):
                state = "code"
            continue
        if char in {'"', "'"}:
            state = char
        elif char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return text[opening + 1:index], index
            if depth < 0:
                break
    raise IdentityError(f"unbalanced C++ {open_char}{close_char} structure")


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


def production_observation(source):
    code = strip_comments(source)
    signature = "bool npu_verilator_execute_f32_alu("
    if code.count(signature) != 1:
        raise IdentityError("production execute definition count mismatch")
    start = code.index(signature)
    signature_open = start + len(signature) - 1
    _, signature_close = extract_balanced(code, signature_open, "(", ")")
    body_open = signature_close + 1
    while body_open < len(code) and code[body_open].isspace():
        body_open += 1
    if body_open >= len(code) or code[body_open] != "{":
        raise IdentityError("production execute opening brace missing")
    body, body_close = extract_balanced(code, body_open, "{", "}")
    call = "f32_alu_harness harness("
    if body.count(call) != 1:
        raise IdentityError("production f32_alu_harness call count mismatch")
    call_start = body_open + 1 + body.index(call)
    call_open = call_start + len(call) - 1
    call_arguments, call_close = extract_balanced(code, call_open, "(", ")")
    return {
        "arguments": split_args(call_arguments),
        "definition_start": start,
        "definition_close": body_close,
        "body_open": body_open,
        "body_close": body_close,
        "call_start": call_start,
        "call_close": call_close,
    }


expected_args = [
    "profile", "npu_f32_alu_mode::positive", "src0_allocation",
    "src0_allocation_bytes", "src1_allocation", "src1_allocation_bytes",
    "dst_shadow", "dst_shadow_bytes", "nullptr", "0", "result",
]
production = production_observation(cpp)
observed = production["arguments"]
if observed != expected_args:
    raise SystemExit(f"production constructor args mismatch: {observed}")
if sha256_bytes(cpp_bytes) != "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e":
    raise SystemExit("production C++ byte identity mismatch")

signature = "bool npu_verilator_execute_f32_alu("
missing_definition_mutant = (
    cpp[:production["definition_start"]] +
    cpp[production["definition_start"]:].replace(
        signature, "bool npu_verilator_execute_f32_alx(", 1
    )
)
definition_text = cpp[
    production["definition_start"]:production["definition_close"] + 1
]
duplicate_definition_mutant = cpp + "\n" + definition_text + "\n"
unbalanced_body_mutant = cpp[:production["definition_close"]]
call_text = cpp[production["call_start"]:production["call_close"] + 1]
duplicate_call_mutant = (
    cpp[:production["call_start"]] + call_text + ";\n        " +
    cpp[production["call_start"]:]
)
tail = "            nullptr,\n            0,\n            result"
if call_text.count(tail) != 1:
    raise SystemExit("production constructor tail fixture mismatch")
old_call = call_text.replace(
    tail, "            false,\n            result", 1
)
missing_result_call = call_text.replace(
    ",\n            result", "", 1
)
if old_call == call_text or missing_result_call == call_text:
    raise SystemExit("production constructor argument mutation not constructed")
old_mutant = (
    cpp[:production["call_start"]] + old_call +
    cpp[production["call_close"] + 1:]
)
missing_mutant = (
    cpp[:production["call_start"]] + missing_result_call +
    cpp[production["call_close"] + 1:]
)
mutation_results = {}
mutation_observations = {}
mutants = {
    "missing_production_definition": missing_definition_mutant,
    "duplicate_production_definition": duplicate_definition_mutant,
    "unbalanced_production_body": unbalanced_body_mutant,
    "duplicate_harness_call": duplicate_call_mutant,
    "old_ten_argument_form": old_mutant,
    "missing_final_result": missing_mutant,
}
for name, mutant in mutants.items():
    try:
        mutant_observation = production_observation(mutant)
        accepted = mutant_observation["arguments"] == expected_args
        rejection = {
            "reason": "argument_mismatch",
            "argument_count": len(mutant_observation["arguments"]),
            "argument_tail": mutant_observation["arguments"][-3:],
        }
    except IdentityError as error:
        accepted = False
        rejection = {"reason": str(error)}
    if accepted:
        raise SystemExit(f"constructor mutation unexpectedly accepted: {name}")
    mutation_results[name] = True
    mutation_observations[name] = rejection

successor = "bool npu_verilator_run_f32_alu_self_test("
if cpp.count(successor) != 1:
    raise SystemExit("successor rename fixture count mismatch")
successor_renamed = cpp.replace(
    successor, "bool npu_verilator_run_f32_alu_self_test_renamed(", 1
)
successor_observation = production_observation(successor_renamed)
if successor_observation["arguments"] != expected_args:
    raise SystemExit("successor rename changed production constructor observation")
successor_rename_result = {
    "accepted": True,
    "production_arguments_unchanged": True,
    "successor_name_dependency": False,
}

consumer = cmake.get("consumer_binding", {})
if (cmake.get("source_count") != 21 or cmake.get("exact_order") is not True or
        consumer.get("verilator_command_expansion_count") != 1 or
        consumer.get("depends_expansion_count") != 1 or
        consumer.get("verilator_and_depends_bound") is not True):
    raise SystemExit("CMake exact source/consumer binding mismatch")
runner_text = read_bytes_stable(root / "npu/version_0820/scripts/run-qwen-f32-alu-families-v9.sh").decode()
# 只审计实际 shell 控制面；避免 embedded checker 的反例 regex 自匹配。
runner_shell = runner_text[:runner_text.index("write_static_audit() {")]
forbidden_patterns = {
    "source_predecessor": r"(?m)^\s*(?:source|\.)\s+[^\n]*run-qwen-f32-alu-families-v[45678]",
    "eval_predecessor": r"\beval\b[^\n]*run-qwen-f32-alu-families-v[45678]",
    "execute_predecessor": r"\bbash\b[^\n]*run-qwen-f32-alu-families-v[45678]",
}
for name, pattern in forbidden_patterns.items():
    if re.search(pattern, runner_shell):
        raise SystemExit(f"v9 predecessor execution forbidden: {name}")


def extract_shell_function(source, name):
    marker = f"{name}() {{\n"
    if source.count(marker) != 1:
        raise IdentityError(f"shell function count mismatch: {name}")
    start = source.index(marker)
    end = source.index("\n}\n", start) + len("\n}\n")
    return source[start:end]


def atomic_log_control_is_safe(block):
    required = [
        'if "$@" >"$temporary" 2>&1; then',
        "command_rc=0",
        "else",
        "command_rc=$?",
        'publish_temporary_file "$temporary" "$output"',
        'return "$command_rc"',
    ]
    return (
        all(fragment in block for fragment in required)
        and "set +e" not in block
        and "set -e" not in block
    )


atomic_log_block = extract_shell_function(runner_shell, "run_atomic_log")
if not atomic_log_control_is_safe(atomic_log_block):
    raise SystemExit("run_atomic_log caller-errexit preservation audit failed")
fixed_capture = '''    if "$@" >"$temporary" 2>&1; then
        command_rc=0
    else
        command_rc=$?
    fi'''
v6_regression = '''    set +e
    "$@" >"$temporary" 2>&1
    command_rc=$?
    set -e'''
atomic_log_mutant = atomic_log_block.replace(fixed_capture, v6_regression, 1)
if atomic_log_mutant == atomic_log_block:
    raise SystemExit("run_atomic_log regression mutation was not constructed")
if atomic_log_control_is_safe(atomic_log_mutant):
    raise SystemExit("run_atomic_log regression mutation unexpectedly accepted")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-v9-static-source-audit-v1",
    "pass": True,
    "production_constructor": {
        "definition_count": 1,
        "definition_body_balanced": True,
        "definition_extractor": "comment-stripped-balanced-braces",
        "call_count": 1,
        "call_parentheses_balanced": True,
        "argument_count": len(observed),
        "arguments": observed,
        "cpp_sha256": sha256_bytes(cpp_bytes),
        "mutations_rejected": mutation_results,
        "mutation_observations": mutation_observations,
        "successor_rename": successor_rename_result,
    },
    "cmake": {
        "source_count": cmake["source_count"],
        "exact_order": cmake["exact_order"],
        "ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
        "consumer_binding": consumer,
    },
    "run_atomic_log_control": {
        "caller_errexit_state_preserved": True,
        "conditional_rc_capture": True,
        "set_toggle_count": 0,
        "v6_reenable_errexit_mutation_rejected": True,
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
    "schema": "qwen-f32-alu-v9-dso-identity-v1",
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
    "schema": "qwen-f32-alu-v9-atomicity-probes-v1",
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
    "schema": "qwen-f32-alu-v9-future-compile-plan-v1",
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
    "schema": "qwen-f32-alu-v9-active-process-v1",
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
        "$RUNNER_PROBE_AUDIT" "$RUNNER_CONTROL_REGRESSION_AUDIT"
        "$COMPILE_PLAN" "$PROCESS_AUDIT"
        "$COMPILER_ROOT/runner-control-regression-nested.status"
        "$COMPILER_ROOT/runner-control-regression-nested.log"
        "$COMPILER_ROOT/runner-control-regression-mutant.log"
        "$COMPILER_ROOT/runner-control-regression-mutant.rc"
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
    "input-identity.pre.json": "qwen-f32-alu-v9-input-identity-v1",
    "input-identity.post.json": "qwen-f32-alu-v9-input-identity-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "static-source-audit.json": "qwen-f32-alu-v9-static-source-audit-v1",
    "history-audit.json": "qwen-f32-alu-v9-history-audit-v1",
    "dso-identity.json": "qwen-f32-alu-v9-dso-identity-v1",
    "atomicity-probes.json": "qwen-f32-alu-v9-atomicity-probes-v1",
    "runner-probe-audit.json": "qwen-f32-alu-v9-runner-probes-v1",
    "runner-control-regression-audit.json": "qwen-f32-alu-v9-runner-control-regression-v1",
    "future-compile-plan.json": "qwen-f32-alu-v9-future-compile-plan-v1",
    "preflight-active-process-audit.json": "qwen-f32-alu-v9-active-process-v1",
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
control_regression = parsed["runner-control-regression-audit.json"]
compile_plan = parsed["future-compile-plan.json"]
process = parsed["preflight-active-process-audit.json"]
if (cmake.get("source_count") != 21 or cmake.get("exact_order") is not True or
        cmake.get("consumer_binding", {}).get("verilator_and_depends_bound") is not True):
    raise SystemExit("receipt CMake identity validation failed")
constructor = static.get("production_constructor", {})
required_constructor_mutations = {
    "missing_production_definition", "duplicate_production_definition",
    "unbalanced_production_body", "duplicate_harness_call",
    "old_ten_argument_form", "missing_final_result",
}
if (constructor.get("definition_count") != 1 or
        constructor.get("definition_body_balanced") is not True or
        constructor.get("definition_extractor") !=
        "comment-stripped-balanced-braces" or
        constructor.get("call_count") != 1 or
        constructor.get("call_parentheses_balanced") is not True or
        constructor.get("argument_count") != 11 or
        constructor.get("arguments", [])[-3:] != ["nullptr", "0", "result"] or
        set(constructor.get("mutations_rejected", {})) !=
        required_constructor_mutations or
        not all(constructor.get("mutations_rejected", {}).values())):
    raise SystemExit("receipt production constructor validation failed")
successor_rename = constructor.get("successor_rename", {})
if (successor_rename.get("accepted") is not True or
        successor_rename.get("production_arguments_unchanged") is not True or
        successor_rename.get("successor_name_dependency") is not False):
    raise SystemExit("receipt successor rename independence validation failed")
atomic_log_control = static.get("run_atomic_log_control", {})
if (atomic_log_control.get("caller_errexit_state_preserved") is not True or
        atomic_log_control.get("conditional_rc_capture") is not True or
        atomic_log_control.get("set_toggle_count") != 0 or
        atomic_log_control.get("v6_reenable_errexit_mutation_rejected") is not True):
    raise SystemExit("receipt run_atomic_log control validation failed")
if (history.get("pass") is not True or dso.get("pass") is not True or
        atomicity.get("pass") is not True or probes.get("pass") is not True or
        control_regression.get("pass") is not True or process.get("pass") is not True):
    raise SystemExit("receipt audit PASS boundary failed")
expected_probe_rcs = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
if (probes.get("probe_count") != 8 or
        {name: item.get("return_code") for name, item in probes.get("records", {}).items()}
        != expected_probe_rcs):
    raise SystemExit("receipt runner probe rc set mismatch")
if (control_regression.get("mutation_rejected") is not True or
        control_regression.get("return_code") != 1):
    raise SystemExit("receipt runner control regression mutation mismatch")
expected_frozen_sources = {
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp":
        "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e",
    "npu/version_0820/scripts/qwen_f32_alu_build_identity.py":
        "b2dfa40a301da66a5a35f6a12d5f406d2b1eae538dc5dcd815e9414f9e14717e",
    "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py":
        "bce7caa9d4d25c189643dab7b9d5a54baebd732ed8bb1e112993c63f34c6139c",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v8.sh":
        "0b996f27077be3ca4974ba072375d8432e51151d597d7912a748da5abff3ae78",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v7.sh":
        "14a9c13dde171993bf0ce46074b040e883b865fd7a9d62a766cabace347fc4b5",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v6.sh":
        "56eab02a2ea7652cd583dbfee601c32e27090161e33fa37fe305d23a8e6e3f1f",
}
if history.get("frozen_source_sha256") != expected_frozen_sources:
    raise SystemExit("receipt frozen source/tool identity mismatch")
v8_failed = history.get("v8_failed_predecessor", {})
expected_v8_probe_rcs = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
if (v8_failed.get("bash_n_return_code") != 0 or
        v8_failed.get("preflight_return_code") != 1 or
        v8_failed.get("preflight_status") !=
        "FAIL rc=1 stage=static-source-audit evidence_complete=0 cleanup_rc=0" or
        v8_failed.get("build_count") != 0 or
        v8_failed.get("build_root_absent") is not True or
        v8_failed.get("runner_probe_count") != 8 or
        v8_failed.get("runner_probe_return_codes") != expected_v8_probe_rcs or
        v8_failed.get("runner_control_regression_mutation_rejected") is not True or
        v8_failed.get("build_identity_tests_run") != 15 or
        v8_failed.get("build_identity_test_failures") != 0 or
        v8_failed.get("root_cause") !=
        "stale_successor_function_name_slice_raised_before_11_argument_audit" or
        v8_failed.get("rerun_forbidden") is not True):
    raise SystemExit("receipt v8 failed predecessor boundary mismatch")
v7_failed = history.get("v7_failed_predecessor", {})
expected_v7_probe_rcs = {
    "early-exit": 1, "command-failure": 7, "cleanup-failure": 9,
    "hup-signal": 129, "int-signal": 130, "term-signal": 143,
    "premature-pass": 1, "status-mismatch": 1,
}
if (v7_failed.get("preflight_return_code") != 1 or
        v7_failed.get("preflight_status") !=
        "FAIL rc=1 stage=cmake-source-identity-test evidence_complete=0 cleanup_rc=0" or
        v7_failed.get("build_count") != 0 or
        v7_failed.get("build_root_absent") is not True or
        v7_failed.get("runner_probe_count") != 8 or
        v7_failed.get("runner_probe_return_codes") != expected_v7_probe_rcs or
        v7_failed.get("runner_control_regression_mutation_rejected") is not True or
        v7_failed.get("build_identity_tests_run") != 15 or
        v7_failed.get("build_identity_test_failures") != 1 or
        v7_failed.get("root_cause") !=
        "declared_category_collision_fixture_omitted_compiler_depfile_prerequisite" or
        v7_failed.get("rerun_forbidden") is not True):
    raise SystemExit("receipt v7 failed predecessor boundary mismatch")
v6_failed = history.get("v6_failed_predecessor", {})
if (v6_failed.get("preflight_return_code") != 1 or
        v6_failed.get("preflight_status") !=
        "FAIL rc=1 stage=runner-fail-closed-probes evidence_complete=0 cleanup_rc=0" or
        v6_failed.get("build_count") != 0 or
        v6_failed.get("build_root_absent") is not True or
        v6_failed.get("early_exit_status") !=
        "FAIL rc=1 stage=probe-early-exit evidence_complete=0 cleanup_rc=0" or
        v6_failed.get("rerun_forbidden") is not True):
    raise SystemExit("receipt v6 failed predecessor boundary mismatch")
if compile_plan.get("compile_membership_status") != "GAP":
    raise SystemExit("unauthorized compile membership relabeled")
if build_root.exists() or read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v9/build.count") != b"0\n":
    raise SystemExit("build-free boundary violated")
if b"[task-run-status-test] PASS" not in read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v9/task-run-status-test.log"):
    raise SystemExit("task status helper marker missing")
if b"[qwen-f32-alu-build-identity-test] PASS exact=21" not in read_bytes_stable(root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v9/build-identity-test.log"):
    raise SystemExit("build identity test marker missing")

receipt = {
    "schema": "qwen-f32-alu-v9-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-v9",
    "contract_sha256": "bfbe77a917d71654298457d782bd37692340561e01ec0b4bfe327590b459549b",
    "artifacts": artifacts,
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "production_constructor": constructor,
    "run_atomic_log_control": atomic_log_control,
    "cmake_source_identity": {
        "source_count": 21,
        "exact_order": True,
        "ordered_sources": cmake["ordered_sources"],
        "ordered_source_identity_sha256": cmake["ordered_source_identity_sha256"],
        "consumer_binding": cmake["consumer_binding"],
    },
    "v8_failed_predecessor": v8_failed,
    "v7_failed_predecessor": v7_failed,
    "v6_failed_predecessor": v6_failed,
    "v5_limited_predecessor": history["v5"],
    "v11_fixed_predecessor": history["v11"],
    "frozen_source_sha256": expected_frozen_sources,
    "runner_probe_records": probes["records"],
    "runner_control_regression": control_regression,
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
if receipt_value.get("task_id") != "qwen-f32-alu-families-v9":
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
    "schema": "qwen-f32-alu-v9-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-v9",
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
    "schema": "qwen-f32-alu-v9-final-binding-v1",
    "task_id": "qwen-f32-alu-families-v9",
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
print(
    f"{receipt_sha} {binding_sha} {manifest_sha} "
    f"{sha256_bytes(expected_observed)}"
)
PY
}

verify_final_status() {
    python3 - "$NPU_ROOT/scripts" "$EXPECTED_STATUS" "$PREFLIGHT_STATUS" \
        "$FINAL_BINDING" "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_HASH" \
        "$BOUND_ARTIFACTS" "$1" "$2" "$3" "$4" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, sha256_bytes
expected_path = pathlib.Path(sys.argv[2])
actual_path = pathlib.Path(sys.argv[3])
binding_path = pathlib.Path(sys.argv[4])
receipt_path = pathlib.Path(sys.argv[5])
receipt_sidecar_path = pathlib.Path(sys.argv[6])
manifest_path = pathlib.Path(sys.argv[7])
expected_receipt_sha = sys.argv[8]
expected_binding_sha = sys.argv[9]
expected_manifest_sha = sys.argv[10]
expected_status_sha = sys.argv[11]
binding, binding_sha, _ = read_json_same_bytes(binding_path)
receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
receipt_sidecar = read_bytes_stable(receipt_sidecar_path)
expected = read_bytes_stable(expected_path)
actual = read_bytes_stable(actual_path)
if expected != b"PASS\n" or actual != expected:
    raise SystemExit("final actual status differs from bound expected status")
if (receipt_sha != expected_receipt_sha or binding_sha != expected_binding_sha or
        manifest_sha != expected_manifest_sha or
        sha256_bytes(expected) != expected_status_sha):
    raise SystemExit("final receipt/binding/status identity drift")
if receipt_sidecar != f"{receipt_sha}  {receipt_path.name}\n".encode("utf-8"):
    raise SystemExit("final receipt sidecar mismatch")
if (receipt.get("task_id") != "qwen-f32-alu-families-v9" or
        manifest.get("receipt_sha256") != receipt_sha or
        binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != manifest_sha or
        binding.get("expected_final_status_sha256") != sha256_bytes(expected)):
    raise SystemExit("final actual status binding mismatch")
print(sha256_bytes(actual))
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

    task_run_status_stage "runner-errexit-regression-mutation"
    run_runner_control_regression

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
    local receipt_sha=""
    local binding_sha=""
    local bound_artifacts_sha=""
    local expected_status_sha=""
    read -r receipt_sha binding_sha bound_artifacts_sha expected_status_sha <<<"$seal_result"
    [[ ${#receipt_sha} -eq 64 ]] || fail "receipt seal did not return SHA-256"
    [[ ${#binding_sha} -eq 64 ]] || fail "binding seal did not return SHA-256"
    [[ ${#bound_artifacts_sha} -eq 64 ]] || fail "manifest seal did not return SHA-256"
    [[ ${#expected_status_sha} -eq 64 ]] || fail "expected status seal did not return SHA-256"
    FINAL_BINDING_VERIFIED=1

    task_run_status_stage "final-status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0
    local status_sha
    status_sha=$(verify_final_status "$receipt_sha" "$binding_sha" \
        "$bound_artifacts_sha" "$expected_status_sha")
    [[ ${#status_sha} -eq 64 ]] || fail "actual status verification did not return SHA-256"
    FINAL_PASS_VERIFIED=1

    task_run_status_stage "pass-marker-publication"
    publish_pass_marker "$receipt_sha" "$binding_sha" "$status_sha" \
        "$bound_artifacts_sha" "$expected_status_sha"
    PASS_MARKER_EMITTED=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-V9][STATUS] $(<"$PREFLIGHT_STATUS")"
}

run_preflight
