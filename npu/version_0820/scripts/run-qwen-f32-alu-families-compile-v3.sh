#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families compile-v3：fresh O3/no-assert/no-trace compile-only
# provenance collector。--preflight 必须保持 build-free；--collect 只能在后续显式
# continuation 下执行，且永远不运行生成的 model、backend binary 或 Qwen workload。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-compile-v3"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v3.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
STAGING_ROOT="$COMPILER_ROOT/staging"
SEALED_ROOT="$COMPILER_ROOT/sealed"
WORK_ROOT="$COMPILER_ROOT/work"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v3.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v3-material.md"
BUILD_IDENTITY_TOOL="$NPU_ROOT/scripts/qwen_f32_alu_build_identity.py"
BUILD_IDENTITY_TEST="$NPU_ROOT/tests/test_qwen_f32_alu_build_identity.py"
CMAKE_SOURCE_DIR="$NPU_ROOT/runtime/llama-npu-backend"
CMAKE_FILE="$CMAKE_SOURCE_DIR/CMakeLists.txt"
PINNED_CMAKE_EXE="/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake"
CMAKE_TOOL_ROOT="$NPU_ROOT/tmp/tools/cmake-3.31.12"
CMAKE_V4_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json"
CMAKE_V4_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md"
CMAKE_V4_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-cmake-tool-v4.sh"
CMAKE_V4_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-cmake-tool-v4"
CMAKE_V3_TREE_MANIFEST="$NPU_ROOT/tmp/logs/qwen-f32-alu-cmake-tool-v3/installed-tree-manifest.json"

COMPILE_V2_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v2.json"
COMPILE_V2_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v2-material.md"
COMPILE_V2_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v2.sh"
COMPILE_V2_STATUS="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v2/preflight.status"
COMPILE_V2_BUILD_COUNT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v2/staging/preflight-build.count"

WARNING_SOURCE="$NPU_ROOT/tmp/compiler/qwen-f32-add-owner-v11/expected-warning-census.tsv"
WARNING_PARSER_PROVENANCE="$NPU_ROOT/tmp/compiler/qwen-f32-add-owner-v11/warning-parser-self-test.json"
WARNING_DIAGNOSTIC_PROVENANCE="$NPU_ROOT/tmp/compiler/qwen-f32-add-owner-v11/build-diagnostic-audit.json"
WARNING_RUNNER_PROVENANCE="$NPU_ROOT/scripts/run-qwen-f32-add-owner-v11.sh"

PREFLIGHT_STATUS="$LOG_ROOT/preflight.status"
PREFLIGHT_RECEIPT="$LOG_ROOT/preflight.receipt.json"
PREFLIGHT_RECEIPT_SIDECAR="$LOG_ROOT/preflight.receipt.sha256"
PREFLIGHT_MANIFEST="$LOG_ROOT/preflight.bound-artifacts.json"
PREFLIGHT_EXPECTED_STATUS="$LOG_ROOT/preflight.expected-status"
PREFLIGHT_BINDING="$LOG_ROOT/preflight.final-binding.json"
PREFLIGHT_BUILD_COUNT="$STAGING_ROOT/preflight-build.count"
TASK_STATUS_LOG="$STAGING_ROOT/task-run-status-test.log"
IDENTITY_TEST_LOG="$STAGING_ROOT/build-identity-test.log"
IDENTITY_LOG="$STAGING_ROOT/build-identity.log"
CMAKE_IDENTITY="$STAGING_ROOT/cmake-source-identity.json"
V11_CLOSURE_AUDIT="$STAGING_ROOT/v11-closure-audit.json"
CMAKE_TOOL_V4_AUDIT="$STAGING_ROOT/cmake-tool-v4-audit.json"
EXPECTED_WARNING_COPY="$STAGING_ROOT/expected-warning-census.tsv"
WARNING_ORACLE_AUDIT="$STAGING_ROOT/warning-oracle-audit.json"
COLLECT_POLICY_AUDIT="$STAGING_ROOT/collect-policy-audit.json"
PREFLIGHT_PROCESS_AUDIT="$STAGING_ROOT/preflight-process-audit.json"
PREFLIGHT_SNAPSHOT_PRE="$STAGING_ROOT/frozen-inputs.pre.json"
PREFLIGHT_SNAPSHOT_POST="$STAGING_ROOT/frozen-inputs.post.json"
PREFLIGHT_CONTENT_SNAPSHOT=""

COMPILE_STATUS="$LOG_ROOT/compile.status"
COMPILE_RECEIPT="$LOG_ROOT/compile.receipt.json"
COMPILE_RECEIPT_SIDECAR="$LOG_ROOT/compile.receipt.sha256"
COMPILE_MANIFEST="$LOG_ROOT/compile.bound-artifacts.json"
COMPILE_EXPECTED_STATUS="$LOG_ROOT/compile.expected-status"
COMPILE_BINDING="$LOG_ROOT/compile.final-binding.json"
COLLECT_BUILD_COUNT="$COMPILER_ROOT/collect-build.count"
COLLECT_ACTION_LEDGER="$COMPILER_ROOT/collect-action-ledger.json"
COLLECT_SNAPSHOT_PRE="$COMPILER_ROOT/collect-inputs.pre.json"
COLLECT_SNAPSHOT_POST="$COMPILER_ROOT/collect-inputs.post.json"
COLLECT_SNAPSHOT_PRESTATUS="$COMPILER_ROOT/collect-inputs.prestatus.json"
COLLECT_PROCESS_AUDIT="$COMPILER_ROOT/collect-process-audit.json"
COMMAND_LEDGER="$COMPILER_ROOT/actual-command-ledger.json"
WARNING_ACTUAL="$COMPILER_ROOT/actual-warning-census.tsv"
WARNING_BUILD_AUDIT="$COMPILER_ROOT/build-diagnostic-audit.json"
MEMBERSHIP_AUDIT="$COMPILER_ROOT/elaboration-membership.json"
OBJECT_DEPFILE_AUDIT="$COMPILER_ROOT/object-depfile-closure.json"
BUILD_ARTIFACT_MANIFEST="$COMPILER_ROOT/build-artifact-manifest.json"
NORMALIZED_DEPFILE_ROOT="$COMPILER_ROOT/normalized-depfiles"
CMAKE_BUILD_ROOT="$BUILD_ROOT/cmake"
VERILATED_ROOT="$BUILD_ROOT/verilated"

CONTRACT_SHA256="581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6"
MATERIAL_SHA256="6ff06cd9ca76a879735d7a3a1fe7eceb0765afb678cf73638f3d295e11036da2"
COMPILE_V2_CONTRACT_SHA256="e76c1b81191cf80eab84aeb9be432beabb6ed81750cff7322769fb8b8264a2ce"
COMPILE_V2_MATERIAL_SHA256="9c10941115ee6775380ed9992122349ac3ef4588fe6dd1ea819a9549f7c7a4de"
COMPILE_V2_RUNNER_SHA256="d13b483c6e6b20b20a00bb5ce0309c0d700434177f6f8d2c090de048127ba055"
COMPILE_V2_STATUS_SHA256="288d115afc3b200dc305d9cad2794d907fce96332a3cb44819c8471463539b84"
CMAKE_V4_CONTRACT_SHA256="57b509770958913cbbe7fe843f09688156f53d6726ff7d58937fc4a98b570f5f"
CMAKE_V4_MATERIAL_SHA256="527ed1b0b3fdeac18ef7a6e78f3f86a847cea3854d613f7779e825bdeeda4846"
CMAKE_V4_RUNNER_SHA256="c3320627c4772c172fd94c225a06e91c910b95c787dda429abe6c51ab94bb703"
CMAKE_V4_RECEIPT_SHA256="03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652"
CMAKE_V4_MANIFEST_SHA256="e0c3b4aa0bcff371c74eada88cfe84f9f0948048b086d9a7d259474586aff712"
CMAKE_V4_BINDING_SHA256="20ba4677fab027042e2967f979a25a53556a8cda4a797da757a9a9bbd855374a"
CMAKE_V4_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
CMAKE_V3_TREE_MANIFEST_SHA256="a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f"
PINNED_CMAKE_SHA256="d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
PINNED_CMAKE_TREE_SHA256="6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc"
PINNED_CMAKE_SIZE=17241856
STATUS_HELPER_SHA256="43977d9787cb41cc541eafa68f1c98f5e4504684b1104398274b07bc8155b7c6"
STATUS_HELPER_TEST_SHA256="35ba14c15c31a291e6a5db8b436d584d0535bd69d11db5495f00232e371a0640"
V1_CONTRACT_SHA256="54e9f9f365e67645b5d4f1472278ef35e3024de8a4081f20f6ef86a6cc8c8466"
V1_MATERIAL_SHA256="23a7c7de7ebc6338244ae13a99db66b457671e94801326d129492a54a8486c1f"
STATIC_REVIEW_V5_SHA256="973970757d0f01dad9d42f52d789215ece08db5d6962311d82d232229f842cb8"
STATIC_REVIEW_V5_MATERIAL_SHA256="fd434f5329a023370b613f739afa022f4ef884891cae07b5c9faf712d03a4e61"
V11_CONTRACT_SHA256="07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f"
V11_MATERIAL_SHA256="5e168011e635000636899cc950918963c5296205e642707f7ca9afef39eda307"
V11_RUNNER_SHA256="98e6f4107051d5c7e5d8d12e53c17dfe30fe2ab965d1403b0378c8e39174b44c"
V11_RECEIPT_SHA256="2a58111bb25be4abe3e9f28f0af9a103003ccde3d7d4b0cf75e33b0b9aa9d044"
V11_MANIFEST_SHA256="02328662478d6c9c211c24de2784abce09c32c361d9e5823af0334e002915fcf"
V11_BINDING_SHA256="1f58f12f99a89e4363d21d483f1bb66ecb5554813e112ccf163eab76cdaf12c2"
V11_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
V11_SNAPSHOT_SHA256="809c835467008e3b84080a52cccb3ccd0ecef6097d42b07d93e2a04a6778471b"
IDENTITY_TOOL_SHA256="865bd358dbde256496c0e213e3931098bded79b802413d65902c0d1c0a29ba2a"
IDENTITY_TEST_SHA256="0837ac7b3f0108e485969944421274b072e65c3100e7758152edd647166a2535"
PRODUCTION_CPP_SHA256="b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e"
CMAKE_SHA256="7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f"
WARNING_EXPECTED_SHA256="832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c"
WARNING_PARSER_SHA256="75c8a64a21fb9ef04f65adb140d1cce2f41abf392339877278f1095efa013f24"
WARNING_DIAGNOSTIC_SHA256="4f6323f8b53be4b42c110ed3c032185bbd6d1a49c86dd3666c72035c493b793c"
WARNING_RUNNER_SHA256="3260592a8bdbdd4c8b78d05c662cc97ff98c1e4af48fffd7598a0a31f8a56af8"
CANONICAL_IDENTITY_SET_SHA256="d0aceb30e2b9f0645887913434b80a104311b5dfe6dd0124749286745c19b385"

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

SNAPSHOT_FILES_REL=(
    .github/AGENTS.md
    .github/instructions/agent-lightweight-workflow.instructions.md
    .github/instructions/rtl-agent-task-contract.instructions.md
    .github/instructions/rtl-generation-workflow.instructions.md
    AI_ENVIRONMENT.md
    scripts/task-run-status.sh
    scripts/tests/test-task-run-status.sh
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v3.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v3-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v1.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v1-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v5.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v5-material.md
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11-material.md
    npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md
    npu/version_0820/docs/QWEN_NPU_COMMAND_ABI.md
    npu/version_0820/docs/F32_TENSOR_ALU_RTL_CONTRACT.md
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
    npu/version_0820/scripts/run-qwen-f32-add-owner-v11.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v9.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v10.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-v11.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v3.sh
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v2.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v2/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v2/staging/preflight-build.count
    npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v4.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v3/installed-tree-manifest.json
    npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake
    npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/expected-warning-census.tsv
    npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/warning-parser-self-test.json
    npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/build-diagnostic-audit.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.receipt.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.bound-artifacts.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.final-binding.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/run.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-v11/sealed/frozen-inputs.809c835467008e3b84080a52cccb3ccd0ecef6097d42b07d93e2a04a6778471b.json
    npu/version_0820/tmp/build/llama.cpp/bin/libggml-base.so
    npu/version_0820/tmp/build/llama.cpp/bin/libggml.so
    "${RTL_SOURCES_REL[@]}"
)

SNAPSHOT_DIRS_REL=(
    npu/version_0820/third_party/fpu-sp/verilog/src/float
    npu/version_0820/third_party/fpu-sp/verilog/src/lzc
    npu/version_0820/third_party/llama.cpp/ggml/include
    npu/version_0820/third_party/llama.cpp/ggml/src
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v2
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v2
    npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v4
    npu/version_0820/tmp/tools/cmake-3.31.12
)

export PYTHONDONTWRITEBYTECODE=1
export LC_ALL=C

STATUS_HELPER_OBSERVED=$(sha256sum "$STATUS_HELPER")
[[ "${STATUS_HELPER_OBSERVED%% *}" == "$STATUS_HELPER_SHA256" ]] || {
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V3][FAIL] status helper hash mismatch before source" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$STATUS_HELPER"

MODE="${1:-}"
STATUS_INITIALIZED=0
TERMINAL_SUCCESS=0
FORCED_CLEANUP_RC=0
CMAKE_EXE=""
MAKE_EXE=""
CXX_EXE=""
AR_EXE=""
RANLIB_EXE=""
VERILATOR_EXE=""
VERILATOR_BIN_EXE=""
VERILATOR_ROOT=""

fail() {
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V3][FAIL] $*" >&2
    return 1
}

path_absent() {
    [[ ! -e "$1" && ! -L "$1" ]]
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

file_sha() {
    local value
    value=$(sha256sum "$1")
    printf '%s\n' "${value%% *}"
}

require_file() {
    [[ -f "$1" && ! -L "$1" ]] || fail "required regular file missing/aliased=$1"
}

require_exact_hash() {
    local path="$1"
    local expected="$2"
    require_file "$path"
    [[ "$(file_sha "$path")" == "$expected" ]] ||
        fail "frozen hash mismatch path=$path expected=$expected"
}

resolve_tools() {
    CMAKE_EXE="$PINNED_CMAKE_EXE"
    require_file "$CMAKE_EXE"
    MAKE_EXE=$(command -v make) || fail "make executable missing"
    CXX_EXE=$(command -v c++) || fail "C++ compiler executable missing"
    AR_EXE=$(command -v ar) || fail "ar executable missing"
    RANLIB_EXE=$(command -v ranlib) || fail "ranlib executable missing"
    VERILATOR_EXE=$(command -v verilator) || fail "Verilator executable missing"
    VERILATOR_BIN_EXE=$(command -v verilator_bin) || fail "verilator_bin executable missing"
    [[ "$VERILATOR_EXE" == */bin/verilator ]] ||
        fail "Verilator path does not provide a non-executing root derivation=$VERILATOR_EXE"
    VERILATOR_ROOT="${VERILATOR_EXE%/bin/verilator}/share/verilator"
    require_file "$VERILATOR_ROOT/include/verilated.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_threads.cpp"
    require_file "$VERILATOR_ROOT/include/verilated_std.sv"
}

atomic_text() {
    local output="$1"
    local value="$2"
    python3 - "$NPU_ROOT/scripts" "$output" "$value" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes
atomic_write_bytes(pathlib.Path(sys.argv[2]), sys.argv[3].encode("utf-8"))
PY
}

run_atomic_log() {
    local output="$1"
    shift
    local temporary="$WORK_ROOT/log.${BASHPID}.$RANDOM.tmp"
    local rc=0
    ( set -o noclobber; : >"$temporary" ) || fail "temporary log collision=$temporary"
    if "$@" >"$temporary" 2>&1; then
        rc=0
    else
        rc=$?
    fi
    python3 - "$NPU_ROOT/scripts" "$temporary" "$output" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes, read_bytes_stable
temporary = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
atomic_write_bytes(output, read_bytes_stable(temporary))
temporary.unlink()
PY
    return "$rc"
}

snapshot_inputs() {
    local output="$1"
    resolve_tools
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$output" \
        "$CMAKE_EXE" "$MAKE_EXE" "$CXX_EXE" "$AR_EXE" "$RANLIB_EXE" \
        "$VERILATOR_EXE" "$VERILATOR_BIN_EXE" "$VERILATOR_ROOT" \
        "${SNAPSHOT_FILES_REL[@]}" --directory-roots "${SNAPSHOT_DIRS_REL[@]}" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable, sha256_bytes

output = pathlib.Path(sys.argv[3])
tool_paths = [pathlib.Path(value) for value in sys.argv[4:11]]
verilator_root = pathlib.Path(sys.argv[11]).resolve(strict=True)
remaining = sys.argv[12:]
separator = remaining.index("--directory-roots")
explicit = list(dict.fromkeys(remaining[:separator]))
directory_roots = list(dict.fromkeys(remaining[separator + 1:]))

def capture(path):
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        data = read_bytes_stable(resolved)
        return {
            "type": "symlink",
            "link_target": target,
            "link_sha256": sha256_bytes(target.encode("utf-8")),
            "resolved_path": str(resolved),
            "resolved_sha256": sha256_bytes(data),
            "resolved_size_bytes": len(data),
        }
    if stat.S_ISDIR(observed.st_mode):
        return {"type": "directory", "mode": f"{stat.S_IMODE(observed.st_mode):04o}"}
    if not stat.S_ISREG(observed.st_mode):
        raise SystemExit("frozen input is not regular/symlink: " + str(path))
    data = read_bytes_stable(path)
    if path.suffix == ".json":
        json.loads(data)
    return {"type": "regular", "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
            "sha256": sha256_bytes(data), "size_bytes": len(data)}

names = set(explicit)
for relative_root in directory_roots:
    directory = root / relative_root
    if not directory.is_dir() or directory.is_symlink():
        raise SystemExit("frozen directory invalid: " + relative_root)
    for path in sorted(directory.rglob("*")):
        names.add(path.relative_to(root).as_posix())
files = {relative: capture(root / relative) for relative in sorted(names)}

external_paths = [*tool_paths,
                  verilator_root / "include/verilated.cpp",
                  verilator_root / "include/verilated_threads.cpp",
                  verilator_root / "include/verilated.h",
                  verilator_root / "include/verilated_std.sv"]
external = {}
for path in external_paths:
    absolute = path.absolute()
    key = str(absolute)
    if key in external:
        continue
    external[key] = capture(absolute)

identity_material = json.dumps({"files": files, "external": external},
                               sort_keys=True, separators=(",", ":")).encode()
payload = {
    "schema": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "explicit_paths": explicit,
    "directory_roots": directory_roots,
    "files": files,
    "external": external,
    "file_count": len(files),
    "external_count": len(external),
    "identity_sha256": hashlib.sha256(identity_material).hexdigest(),
}
atomic_write_json(output, payload)
PY
}

audit_v11_closure() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$V11_CLOSURE_AUDIT" <<'PY'
import hashlib
import json
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
output = pathlib.Path(sys.argv[3])
expected = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2.json": "e76c1b81191cf80eab84aeb9be432beabb6ed81750cff7322769fb8b8264a2ce",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v2-material.md": "9c10941115ee6775380ed9992122349ac3ef4588fe6dd1ea819a9549f7c7a4de",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v2.sh": "d13b483c6e6b20b20a00bb5ce0309c0d700434177f6f8d2c090de048127ba055",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v1.json": "54e9f9f365e67645b5d4f1472278ef35e3024de8a4081f20f6ef86a6cc8c8466",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v1-material.md": "23a7c7de7ebc6338244ae13a99db66b457671e94801326d129492a54a8486c1f",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v5.json": "973970757d0f01dad9d42f52d789215ece08db5d6962311d82d232229f842cb8",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-static-review-v5-material.md": "fd434f5329a023370b613f739afa022f4ef884891cae07b5c9faf712d03a4e61",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11.json": "07864add3237ebb602512247e8f4ad0e3b1717438a062269a8ca70cfd20c479f",
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-v11-material.md": "5e168011e635000636899cc950918963c5296205e642707f7ca9afef39eda307",
    "npu/version_0820/scripts/run-qwen-f32-alu-families-v11.sh": "98e6f4107051d5c7e5d8d12e53c17dfe30fe2ab965d1403b0378c8e39174b44c",
    "npu/version_0820/scripts/qwen_f32_alu_build_identity.py": "865bd358dbde256496c0e213e3931098bded79b802413d65902c0d1c0a29ba2a",
    "npu/version_0820/tests/test_qwen_f32_alu_build_identity.py": "0837ac7b3f0108e485969944421274b072e65c3100e7758152edd647166a2535",
    "npu/version_0820/runtime/llama-npu-backend/CMakeLists.txt": "7e2c408c5d4c9b1837177f6e8b8638eb635ef5f736a225b52e9e2d95eb13254f",
    "npu/version_0820/runtime/llama-npu-backend/npu-verilator-runner.cpp": "b5581ad476afa265d351906c95e072fc6c9d0957114b29b170e03687473a348e",
    "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/expected-warning-census.tsv": "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c",
    "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/warning-parser-self-test.json": "75c8a64a21fb9ef04f65adb140d1cce2f41abf392339877278f1095efa013f24",
    "npu/version_0820/tmp/compiler/qwen-f32-add-owner-v11/build-diagnostic-audit.json": "4f6323f8b53be4b42c110ed3c032185bbd6d1a49c86dd3666c72035c493b793c",
    "npu/version_0820/scripts/run-qwen-f32-add-owner-v11.sh": "3260592a8bdbdd4c8b78d05c662cc97ff98c1e4af48fffd7598a0a31f8a56af8",
}
observed = {}
for relative, digest in expected.items():
    data = read_bytes_stable(root / relative)
    actual = hashlib.sha256(data).hexdigest()
    if actual != digest:
        raise SystemExit("frozen predecessor drift: " + relative)
    observed[relative] = actual

receipt_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.receipt.json"
manifest_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.bound-artifacts.json"
binding_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/preflight.final-binding.json"
status_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-v11/run.status"
snapshot_path = root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-v11/sealed/frozen-inputs.809c835467008e3b84080a52cccb3ccd0ecef6097d42b07d93e2a04a6778471b.json"
receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
binding, binding_sha, _ = read_json_same_bytes(binding_path)
snapshot, snapshot_sha, _ = read_json_same_bytes(snapshot_path)
status = read_bytes_stable(status_path)
if (receipt_sha != "2a58111bb25be4abe3e9f28f0af9a103003ccde3d7d4b0cf75e33b0b9aa9d044" or
        manifest_sha != "02328662478d6c9c211c24de2784abce09c32c361d9e5823af0334e002915fcf" or
        binding_sha != "1f58f12f99a89e4363d21d483f1bb66ecb5554813e112ccf163eab76cdaf12c2" or
        snapshot_sha != "809c835467008e3b84080a52cccb3ccd0ecef6097d42b07d93e2a04a6778471b" or
        hashlib.sha256(status).hexdigest() != "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431" or
        status != b"PASS\n"):
    raise SystemExit("v11 receipt/manifest/binding/status/snapshot identity mismatch")
if (receipt.get("build_count") != 0 or receipt.get("build_root_absent") is not True or
        receipt.get("compile_membership_status") != "GAP" or
        receipt.get("actual_configured_argv") != "GAP" or
        receipt.get("verified_canonical_node_identities_completed") != 0 or
        receipt.get("remaining_nonmetadata_gap") != 1079 or
        receipt.get("backend_concurrency_status") != "CONDITIONAL_UNKNOWN"):
    raise SystemExit("v11 semantic boundary mismatch")
if (manifest.get("receipt_sha256") != receipt_sha or
        binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != manifest_sha or
        binding.get("content_addressed_snapshot_sha256") != snapshot_sha):
    raise SystemExit("v11 closure binding mismatch")
reopened = revalidate_bound_artifacts(root, manifest["artifacts"])
if reopened.get("artifact_count") != manifest.get("artifact_count"):
    raise SystemExit("v11 bound artifact reopening mismatch")

compile_v2_status_path = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v2/preflight.status"
compile_v2_count_path = root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v2/staging/preflight-build.count"
compile_v2_status = read_bytes_stable(compile_v2_status_path)
compile_v2_count = read_bytes_stable(compile_v2_count_path)
if (hashlib.sha256(compile_v2_status).hexdigest() !=
        "288d115afc3b200dc305d9cad2794d907fce96332a3cb44819c8471463539b84" or
        compile_v2_status !=
        b"FAIL rc=1 stage=preflight-input-snapshot evidence_complete=0 cleanup_rc=0\n" or
        compile_v2_count != b"0\n" or
        (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v2").exists() or
        (root / "npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v2").is_symlink()):
    raise SystemExit("compile-v2 immutable build-free failure boundary mismatch")

from qwen_f32_alu_build_identity import atomic_write_json
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v3-v11-closure-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "pass": True,
    "frozen_hashes": observed,
    "compile_v2": {
        "runner_sha256": "d13b483c6e6b20b20a00bb5ce0309c0d700434177f6f8d2c090de048127ba055",
        "status_sha256": hashlib.sha256(compile_v2_status).hexdigest(),
        "status": compile_v2_status.decode().strip(),
        "build_count": 0,
        "build_root_absent": True,
        "cmake_configure": 0,
        "cmake_build": 0,
        "binary_runs": 0,
    },
    "v11": {
        "receipt_sha256": receipt_sha,
        "manifest_sha256": manifest_sha,
        "binding_sha256": binding_sha,
        "status_sha256": hashlib.sha256(status).hexdigest(),
        "snapshot_sha256": snapshot_sha,
        "bound_artifact_count": reopened["artifact_count"],
        "build_count": 0,
        "actual_configured_argv": "GAP",
        "compile_membership": "GAP",
    },
})
PY
}

audit_cmake_v4_closure() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$CMAKE_TOOL_V4_AUDIT" \
        "$PINNED_CMAKE_EXE" "$CMAKE_TOOL_ROOT" "$CMAKE_V4_LOG_ROOT" \
        "$CMAKE_V3_TREE_MANIFEST" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable

output = pathlib.Path(sys.argv[3])
cmake_path = pathlib.Path(sys.argv[4])
tool_root = pathlib.Path(sys.argv[5])
v4_root = pathlib.Path(sys.argv[6])
tree_manifest_path = pathlib.Path(sys.argv[7])

fixed = {
    root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json":
        "57b509770958913cbbe7fe843f09688156f53d6726ff7d58937fc4a98b570f5f",
    root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md":
        "527ed1b0b3fdeac18ef7a6e78f3f86a847cea3854d613f7779e825bdeeda4846",
    root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v4.sh":
        "c3320627c4772c172fd94c225a06e91c910b95c787dda429abe6c51ab94bb703",
    v4_root / "receipt.json":
        "03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652",
    v4_root / "bound-artifacts.json":
        "e0c3b4aa0bcff371c74eada88cfe84f9f0948048b086d9a7d259474586aff712",
    v4_root / "final-binding.json":
        "20ba4677fab027042e2967f979a25a53556a8cda4a797da757a9a9bbd855374a",
    v4_root / "run.status":
        "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    tree_manifest_path:
        "a37e0b13ee2c83ae6b12ca75b424109d038f700757f2cfb7fdf9b3e804383a1f",
}
for path, expected_digest in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("CMake-v4 frozen input missing/aliased: " + str(path))
    if hashlib.sha256(read_bytes_stable(path)).hexdigest() != expected_digest:
        raise SystemExit("CMake-v4 frozen input hash mismatch: " + str(path))

if read_bytes_stable(v4_root / "run.status") != b"PASS\n":
    raise SystemExit("CMake-v4 status is not exact PASS")
receipt = json.loads(read_bytes_stable(v4_root / "receipt.json"))
bound = json.loads(read_bytes_stable(v4_root / "bound-artifacts.json"))
binding = json.loads(read_bytes_stable(v4_root / "final-binding.json"))
if (
    receipt.get("result") != "PASS"
    or receipt.get("contract_sha256")
       != "57b509770958913cbbe7fe843f09688156f53d6726ff7d58937fc4a98b570f5f"
    or receipt.get("runner_sha256")
       != "c3320627c4772c172fd94c225a06e91c910b95c787dda429abe6c51ab94bb703"
    or receipt.get("installed_cmake_path")
       != "npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake"
    or receipt.get("installed_cmake_sha256")
       != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
    or receipt.get("installed_cmake_size") != 17241856
    or receipt.get("tree_entry_count_per_window") != 8173
    or receipt.get("tree_rehash_windows") != 2
    or receipt.get("tree_entries_sha256")
       != "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc"
    or receipt.get("cmake_version_first_line") != "cmake version 3.31.12"
    or receipt.get("cmake_version_stdout_exact") is not True
    or receipt.get("compile_performed") is not False
    or receipt.get("cmake_configure_count") != 0
    or receipt.get("cmake_build_count") != 0
    or receipt.get("binary_run_count") != 0
    or receipt.get("model_run_count") != 0
    or receipt.get("qwen_run_count") != 0
    or receipt.get("synthesis_count") != 0
    or receipt.get("sta_count") != 0
    or receipt.get("ppa_count") != 0
):
    raise SystemExit("CMake-v4 receipt semantic mismatch")
counts = receipt.get("action_counts", {})
for key in (
    "cmake_configure", "cmake_build", "verilator", "make", "rtl_build",
    "binary_runs", "model_runs", "qwen_runs", "synthesis", "sta", "ppa",
    "installer_invocations", "archive_extract_count", "install_publication_count",
    "installed_tree_write_count", "network_download_count",
):
    if counts.get(key) != 0:
        raise SystemExit("CMake-v4 nonzero forbidden action: " + key)
if (
    bound.get("schema_version") != 1
    or bound.get("task_id") != "qwen-f32-alu-cmake-tool-v4"
    or bound.get("artifact_count") != 52
    or bound.get("receipt_sha256")
       != "03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652"
    or not isinstance(bound.get("artifacts"), list)
):
    raise SystemExit("CMake-v4 bound-artifact manifest semantic mismatch")
if (
    binding.get("result") != "PASS"
    or binding.get("receipt_sha256")
       != "03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652"
    or binding.get("bound_artifacts_sha256")
       != "e0c3b4aa0bcff371c74eada88cfe84f9f0948048b086d9a7d259474586aff712"
    or binding.get("installed_cmake_sha256")
       != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
    or binding.get("tree_entries_sha256")
       != "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc"
    or binding.get("status_publication_must_follow_binding") is not True
    or binding.get("pass_marker_is_final_successful_action") is not True
):
    raise SystemExit("CMake-v4 final binding semantic mismatch")

v4_prefix = "npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v4/"
manifest_root_records = {}
all_manifest_paths = set()
for record in bound["artifacts"]:
    relative = record.get("path")
    if (
        not isinstance(relative, str)
        or relative in all_manifest_paths
        or not isinstance(record.get("sha256"), str)
        or not isinstance(record.get("size"), int)
    ):
        raise SystemExit("CMake-v4 malformed/duplicate bound artifact")
    all_manifest_paths.add(relative)
    if relative.startswith(v4_prefix):
        manifest_root_records[relative] = record
for relative, record in manifest_root_records.items():
    path = root / relative
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("CMake-v4 root artifact missing/aliased: " + relative)
    data = read_bytes_stable(path)
    if len(data) != record["size"] or hashlib.sha256(data).hexdigest() != record["sha256"]:
        raise SystemExit("CMake-v4 root artifact byte drift: " + relative)
expected_root_paths = set(manifest_root_records)
expected_root_paths.update({
    v4_prefix + "bound-artifacts.json",
    v4_prefix + "final-binding.json",
    v4_prefix + "run.status",
})
actual_root_paths = set()
for path in v4_root.rglob("*"):
    observed = path.lstat()
    if stat.S_ISDIR(observed.st_mode) and not stat.S_ISLNK(observed.st_mode):
        raise SystemExit("CMake-v4 evidence root contains unexpected directory: " + str(path))
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("CMake-v4 evidence root contains alias/special: " + str(path))
    actual_root_paths.add(path.relative_to(root).as_posix())
if actual_root_paths != expected_root_paths:
    raise SystemExit("CMake-v4 complete evidence-root membership mismatch")

if (
    not cmake_path.is_absolute()
    or str(cmake_path) !=
       "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake"
    or cmake_path.resolve(strict=True) != cmake_path
    or tool_root.resolve(strict=True) != tool_root
):
    raise SystemExit("pinned CMake absolute/resolved path mismatch")
cmake_stat = cmake_path.lstat()
cmake_data = read_bytes_stable(cmake_path)
if (
    not stat.S_ISREG(cmake_stat.st_mode)
    or stat.S_ISLNK(cmake_stat.st_mode)
    or stat.S_IMODE(cmake_stat.st_mode) != 0o755
    or cmake_stat.st_size != 17241856
    or len(cmake_data) != 17241856
    or hashlib.sha256(cmake_data).hexdigest()
       != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
):
    raise SystemExit("pinned CMake executable identity mismatch")

manifest = json.loads(read_bytes_stable(tree_manifest_path))
expected_entries = manifest.get("entries")
if (
    manifest.get("schema_version") != 1
    or manifest.get("task_id") != "qwen-f32-alu-cmake-tool-v3"
    or manifest.get("entry_count") != 8173
    or manifest.get("regular_file_count") != 8035
    or manifest.get("directory_count") != 138
    or manifest.get("symlink_count") != 0
    or not isinstance(expected_entries, list)
    or len(expected_entries) != 8173
):
    raise SystemExit("CMake-v3 installed-tree manifest semantic mismatch")

observed_entries = []
def visit(path, relative):
    observed = path.lstat()
    mode = stat.S_IMODE(observed.st_mode)
    if stat.S_ISLNK(observed.st_mode):
        raise SystemExit("installed CMake tree contains symlink: " + str(path))
    if stat.S_ISDIR(observed.st_mode):
        observed_entries.append({
            "path": relative, "kind": "directory", "mode": f"{mode:04o}", "size": 0,
        })
        for name in sorted(os.listdir(path)):
            if name in {"", ".", ".."} or "/" in name:
                raise SystemExit("installed CMake tree has noncanonical member")
            child_relative = name if relative == "." else relative + "/" + name
            visit(path / name, child_relative)
        return
    if stat.S_ISREG(observed.st_mode):
        data = read_bytes_stable(path)
        observed_entries.append({
            "path": relative, "kind": "regular", "mode": f"{mode:04o}",
            "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
        })
        return
    raise SystemExit("installed CMake tree contains special object: " + str(path))

visit(tool_root, ".")
if observed_entries != expected_entries:
    raise SystemExit("installed CMake tree differs from frozen 8173-entry manifest")
tree_identity = hashlib.sha256(json.dumps(
    observed_entries, sort_keys=True, separators=(",", ":")
).encode()).hexdigest()
if tree_identity != "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc":
    raise SystemExit("installed CMake tree content digest mismatch")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v3-cmake-tool-v4-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "pass": True,
    "absolute_cmake_path": str(cmake_path),
    "resolved_cmake_path": str(cmake_path.resolve(strict=True)),
    "cmake_kind": "regular",
    "cmake_mode": "0755",
    "cmake_size": len(cmake_data),
    "cmake_sha256": hashlib.sha256(cmake_data).hexdigest(),
    "tree_entry_count": len(observed_entries),
    "tree_regular_file_count": 8035,
    "tree_directory_count": 138,
    "tree_entries_sha256": tree_identity,
    "v4_contract_sha256": fixed[root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4.json"],
    "v4_material_sha256": fixed[root / "npu/version_0820/tmp/contracts/qwen-f32-alu-cmake-tool-v4-material.md"],
    "v4_runner_sha256": fixed[root / "npu/version_0820/scripts/run-qwen-f32-alu-cmake-tool-v4.sh"],
    "v4_receipt_sha256": fixed[v4_root / "receipt.json"],
    "v4_bound_artifacts_sha256": fixed[v4_root / "bound-artifacts.json"],
    "v4_final_binding_sha256": fixed[v4_root / "final-binding.json"],
    "v4_status_sha256": fixed[v4_root / "run.status"],
    "v4_complete_evidence_file_count": len(actual_root_paths),
    "v4_executed_or_sourced": False,
    "cmake_version_rerun_count": 0,
    "cmake_configure_count": 0,
    "cmake_build_count": 0,
    "ninja_invocation_count": 0,
    "verilator_invocation_count": 0,
    "make_invocation_count": 0,
})
PY
}

audit_warning_oracle() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$WARNING_SOURCE" \
        "$WARNING_PARSER_PROVENANCE" "$WARNING_DIAGNOSTIC_PROVENANCE" \
        "$EXPECTED_WARNING_COPY" "$WARNING_ORACLE_AUDIT" <<'PY'
import collections
import hashlib
import json
import pathlib
import re
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_bytes, atomic_write_json, read_bytes_stable

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
source = pathlib.Path(sys.argv[3])
parser_provenance = pathlib.Path(sys.argv[4])
diagnostic_provenance = pathlib.Path(sys.argv[5])
copy = pathlib.Path(sys.argv[6])
output = pathlib.Path(sys.argv[7])
data = read_bytes_stable(source)
if hashlib.sha256(data).hexdigest() != "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c":
    raise SystemExit("frozen warning TSV hash mismatch")
atomic_write_bytes(copy, data)
if read_bytes_stable(copy) != data:
    raise SystemExit("warning TSV byte-copy drift")

rows = []
for raw in data.decode("utf-8").splitlines():
    fields = raw.split("\t")
    if len(fields) != 4 or not re.fullmatch(r"[A-Z0-9_]+", fields[0]):
        raise SystemExit("warning TSV row schema mismatch")
    relative = pathlib.PurePosixPath(fields[1])
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit("warning TSV path is not canonical relative")
    path = (root / relative).resolve(strict=True)
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise SystemExit("warning TSV path escapes repository") from exc
    line_no = int(fields[2])
    column = int(fields[3])
    if line_no <= 0 or column <= 0:
        raise SystemExit("warning TSV location is not positive")
    rows.append((fields[0], relative.as_posix(), line_no, column))
if len(rows) != 25 or len(set(rows)) != 25:
    raise SystemExit("warning TSV cardinality/uniqueness mismatch")

classes = {
    "legacy_fpu_sp": {row for row in rows if "/third_party/fpu-sp/" in row[1]},
    "legacy_fp32_addmul": {row for row in rows if row[1].endswith("/TensorNpuFp32AddMul.v")},
}
if ({name: len(value) for name, value in classes.items()} !=
        {"legacy_fpu_sp": 21, "legacy_fp32_addmul": 4} or
        classes["legacy_fpu_sp"] & classes["legacy_fp32_addmul"] or
        set().union(*classes.values()) != set(rows)):
    raise SystemExit("warning class partition mismatch")

def compare(actual, class_map=classes):
    values = list(class_map.values())
    if any(values[left] & values[right]
           for left in range(len(values)) for right in range(left + 1, len(values))):
        return False
    if set().union(*values) != set(rows):
        return False
    return collections.Counter(actual) == collections.Counter(rows)

mutations = {
    "missing": not compare(rows[:-1]),
    "extra": not compare(rows + [("WIDTH", "npu/version_0820/rtl/TensorNpuCoprocessor.v", 1, 1)]),
    "duplicate": not compare(rows + [rows[0]]),
    "path_substitution": not compare([(rows[0][0], rows[0][1] + ".substituted", rows[0][2], rows[0][3]), *rows[1:]]),
    "line_substitution": not compare([(rows[0][0], rows[0][1], rows[0][2] + 1, rows[0][3]), *rows[1:]]),
    "category_substitution": not compare([("WIDTH", rows[0][1], rows[0][2], rows[0][3]), *rows[1:]]),
}
collision = {name: set(value) for name, value in classes.items()}
collision["legacy_fp32_addmul"].add(rows[0])
mutations["class_collision"] = not compare(rows, collision)
if not all(mutations.values()):
    raise SystemExit("warning comparator mutation unexpectedly accepted")

parser_data = read_bytes_stable(parser_provenance)
diagnostic_data = read_bytes_stable(diagnostic_provenance)
if (hashlib.sha256(parser_data).hexdigest() != "75c8a64a21fb9ef04f65adb140d1cce2f41abf392339877278f1095efa013f24" or
        hashlib.sha256(diagnostic_data).hexdigest() != "4f6323f8b53be4b42c110ed3c032185bbd6d1a49c86dd3666c72035c493b793c"):
    raise SystemExit("warning parser/diagnostic provenance hash mismatch")
parser_value = json.loads(parser_data)
diagnostic_value = json.loads(diagnostic_data)
if (parser_value.get("expected_row_count") != 25 or
        parser_value.get("mutations_rejected") != mutations or
        parser_value.get("class_counts") != {name: len(value) for name, value in classes.items()} or
        diagnostic_value.get("actual_warning_rows") != 25 or
        diagnostic_value.get("error_count") != 0):
    raise SystemExit("warning provenance semantic mismatch")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v3-warning-oracle-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "expected_tsv_sha256": hashlib.sha256(data).hexdigest(),
    "copied_tsv_sha256": hashlib.sha256(read_bytes_stable(copy)).hexdigest(),
    "expected_row_count": len(rows),
    "unique_normalized_rows": len(set(rows)),
    "class_counts": {name: len(value) for name, value in classes.items()},
    "mutations_rejected": mutations,
    "provenance": {
        "parser_sha256": hashlib.sha256(parser_data).hexdigest(),
        "diagnostic_sha256": hashlib.sha256(diagnostic_data).hexdigest(),
        "runner_sha256": "3260592a8bdbdd4c8b78d05c662cc97ff98c1e4af48fffd7598a0a31f8a56af8",
        "executed_or_sourced": False,
    },
    "pass": True,
})
PY
}

audit_collect_policy() {
    python3 - "$RUNNER" "$COLLECT_POLICY_AUDIT" "$NPU_ROOT/scripts" <<'PY'
import pathlib
import re
import sys
sys.path.insert(0, sys.argv[3])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable

runner = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
source = read_bytes_stable(runner).decode("utf-8")
lifecycle = re.findall(
    r'(?ms)^[ \t]*\# COLLECT_LIFECYCLE_BEGIN[ \t]*$\n(.*?)'
    r'^[ \t]*\# COLLECT_LIFECYCLE_END[ \t]*$', source)
if len(lifecycle) != 1:
    raise SystemExit("collect lifecycle sentinel cardinality mismatch")
block = lifecycle[0]
actions = re.findall(r'^\s*run_collect_action\s+"([a-z-]+)"', block, re.MULTILINE)
if actions != ["cmake-configure", "cmake-build"]:
    raise SystemExit("collect action lifecycle mismatch: " + repr(actions))
if re.search(r'^\s*(?:"?\$\{?LINKED_BINARY|"?\$\{?MODEL_BINARY)', source, re.MULTILINE):
    raise SystemExit("linked binary/model invocation found")
mode_admission = re.findall(
    r'(?m)^[ \t]*\[\[ "\$1" != "--preflight" && '
    r'"\$1" != "--collect" \]\]; then$', source)
if len(mode_admission) != 1:
    raise SystemExit("public mode admission predicate mismatch")
if source.count(
    'PINNED_CMAKE_EXE="/home/lyg/PA/ysyx-workbench/npu/version_0820/'
    'tmp/tools/cmake-3.31.12/bin/cmake"'
) != 1:
    raise SystemExit("pinned absolute CMake assignment cardinality mismatch")
if (
    ("command -v " + "cmake") in source
    or ("cmake" + ".exe") in source.lower()
    or ('VERILATOR_ROOT=$(' + '"$VERILATOR_EXE"') in source
    or ('CMAKE_EXE=$(' + 'command') in source
):
    raise SystemExit("ambient/executing preflight tool resolution found")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v3-collect-policy-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "public_modes": ["--preflight", "--collect"],
    "lifecycle_actions": actions,
    "configure_count": 1,
    "build_count": 1,
    "binary_invocations": 0,
    "model_invocations": 0,
    "qwen_invocations": 0,
    "synthesis_invocations": 0,
    "sta_invocations": 0,
    "ppa_invocations": 0,
    "foreground_j1_required": True,
    "pinned_cmake_path": "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake",
    "ambient_cmake_resolution": False,
    "preflight_cmake_invocations": 0,
    "preflight_ninja_invocations": 0,
    "preflight_verilator_invocations": 0,
    "preflight_make_invocations": 0,
    "pass": True,
})
PY
}

write_process_audit() {
    local phase="$1"
    local output="$2"
    python3 - "$NPU_ROOT/scripts" "$TASK_ID" "$phase" "$output" <<'PY'
import os
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json

task_id = sys.argv[2]
phase = sys.argv[3]
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
        command = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", errors="replace")
    except OSError:
        continue
    if task_id in command:
        matches.append({"pid": int(entry.name), "command": command})
if matches:
    raise SystemExit("owned process still active: " + repr(matches))
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v3-process-audit-v1",
    "task_id": task_id,
    "phase": phase,
    "owned_background_jobs": 0,
    "matches": [],
    "pass": True,
})
PY
}

publish_content_snapshot() {
    local source="$1"
    local digest
    digest=$(file_sha "$source")
    local output="$SEALED_ROOT/frozen-inputs.$digest.json"
    python3 - "$NPU_ROOT/scripts" "$source" "$output" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_bytes, read_bytes_stable
source = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])
atomic_write_bytes(output, read_bytes_stable(source))
PY
    [[ "$(file_sha "$output")" == "$digest" ]] || fail "content snapshot copy mismatch"
    printf '%s\n' "$output"
}

seal_preflight() {
    local artifacts=(
        "$PREFLIGHT_BUILD_COUNT" "$TASK_STATUS_LOG" "$IDENTITY_TEST_LOG"
        "$IDENTITY_LOG" "$CMAKE_IDENTITY" "$V11_CLOSURE_AUDIT"
        "$CMAKE_TOOL_V4_AUDIT"
        "$EXPECTED_WARNING_COPY" "$WARNING_ORACLE_AUDIT" "$COLLECT_POLICY_AUDIT"
        "$PREFLIGHT_PROCESS_AUDIT" "$PREFLIGHT_SNAPSHOT_PRE"
        "$PREFLIGHT_SNAPSHOT_POST" "$PREFLIGHT_CONTENT_SNAPSHOT"
    )
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$PREFLIGHT_STATUS" \
        "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_SIDECAR" "$PREFLIGHT_MANIFEST" \
        "$PREFLIGHT_EXPECTED_STATUS" "$PREFLIGHT_BINDING" "${artifacts[@]}" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_bytes, atomic_write_json, build_artifact_record,
    read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes,
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
    "frozen-inputs.pre.json": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "frozen-inputs.post.json": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "v11-closure-audit.json": "qwen-f32-alu-families-compile-v3-v11-closure-v1",
    "cmake-tool-v4-audit.json": "qwen-f32-alu-families-compile-v3-cmake-tool-v4-audit-v1",
    "warning-oracle-audit.json": "qwen-f32-alu-families-compile-v3-warning-oracle-v1",
    "collect-policy-audit.json": "qwen-f32-alu-families-compile-v3-collect-policy-v1",
    "preflight-process-audit.json": "qwen-f32-alu-families-compile-v3-process-audit-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    schema = schemas.get(path.name)
    if path.parent.name == "sealed":
        schema = "qwen-f32-alu-families-compile-v3-frozen-inputs-v1"
    relative = path.resolve(strict=True).relative_to(root).as_posix()
    if relative in artifacts:
        raise SystemExit("duplicate preflight artifact: " + relative)
    artifacts[relative] = build_artifact_record(root, path, schema)
    if schema:
        parsed[path.name] = read_json_same_bytes(path)[0]

pre = parsed["frozen-inputs.pre.json"]
post = parsed["frozen-inputs.post.json"]
content_path = next(path for path in artifact_paths if path.parent.name == "sealed")
content, content_sha, content_bytes = read_json_same_bytes(content_path)
if (pre != post or pre != content or
        read_bytes_stable(next(path for path in artifact_paths if path.name == "frozen-inputs.pre.json")) != content_bytes or
        content_path.name != f"frozen-inputs.{content_sha}.json"):
    raise SystemExit("pre/post/content frozen input mismatch")
if read_bytes_stable(next(path for path in artifact_paths if path.name == "preflight-build.count")) != b"0\n":
    raise SystemExit("preflight build count is not zero")
if build_root.exists() or build_root.is_symlink():
    raise SystemExit("build root was created during preflight")
warning = parsed["warning-oracle-audit.json"]
policy = parsed["collect-policy-audit.json"]
closure = parsed["v11-closure-audit.json"]
cmake_tool = parsed["cmake-tool-v4-audit.json"]
cmake = parsed["cmake-source-identity.json"]
process = parsed["preflight-process-audit.json"]
if (warning.get("pass") is not True or warning.get("expected_row_count") != 25 or
        warning.get("expected_tsv_sha256") != "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c" or
        not all(warning.get("mutations_rejected", {}).values()) or
        policy.get("pass") is not True or policy.get("lifecycle_actions") != ["cmake-configure", "cmake-build"] or
        closure.get("pass") is not True or
        closure.get("compile_v2", {}).get("build_count") != 0 or
        cmake_tool.get("pass") is not True or
        cmake_tool.get("absolute_cmake_path") !=
        "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake" or
        cmake_tool.get("cmake_sha256") !=
        "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863" or
        cmake_tool.get("tree_entry_count") != 8173 or
        cmake_tool.get("tree_entries_sha256") !=
        "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc" or
        cmake_tool.get("cmake_version_rerun_count") != 0 or
        cmake.get("source_count") != 21 or
        cmake.get("frozen_cmake_template") != "PASS" or process.get("owned_background_jobs") != 0):
    raise SystemExit("preflight audit semantics mismatch")
task_log = read_bytes_stable(next(path for path in artifact_paths if path.name == "task-run-status-test.log"))
identity_log = read_bytes_stable(next(path for path in artifact_paths if path.name == "build-identity-test.log"))
if b"[task-run-status-test] PASS" not in task_log or b"[qwen-f32-alu-build-identity-test] PASS" not in identity_log:
    raise SystemExit("directed test marker missing")

runner_relative = "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v3.sh"
receipt = {
    "schema": "qwen-f32-alu-families-compile-v3-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "contract_sha256": "581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6",
    "material_sha256": "6ff06cd9ca76a879735d7a3a1fe7eceb0765afb678cf73638f3d295e11036da2",
    "runner_sha256": pre["files"][runner_relative]["sha256"],
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "content_addressed_snapshot": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "warning_expected_sha256": warning["expected_tsv_sha256"],
    "warning_expected_rows": 25,
    "warning_mutations_rejected": warning["mutations_rejected"],
    "v11_closure": closure["v11"],
    "compile_v2_closure": closure["compile_v2"],
    "cmake_tool_v4": {
        "contract_sha256": cmake_tool["v4_contract_sha256"],
        "material_sha256": cmake_tool["v4_material_sha256"],
        "runner_sha256": cmake_tool["v4_runner_sha256"],
        "receipt_sha256": cmake_tool["v4_receipt_sha256"],
        "bound_artifacts_sha256": cmake_tool["v4_bound_artifacts_sha256"],
        "final_binding_sha256": cmake_tool["v4_final_binding_sha256"],
        "status_sha256": cmake_tool["v4_status_sha256"],
        "complete_evidence_file_count": cmake_tool["v4_complete_evidence_file_count"],
        "executed_or_sourced": False,
    },
    "cmake_tool_identity": {
        "absolute_path": cmake_tool["absolute_cmake_path"],
        "resolved_path": cmake_tool["resolved_cmake_path"],
        "kind": cmake_tool["cmake_kind"],
        "mode": cmake_tool["cmake_mode"],
        "size": cmake_tool["cmake_size"],
        "sha256": cmake_tool["cmake_sha256"],
        "tree_entry_count": cmake_tool["tree_entry_count"],
        "tree_entries_sha256": cmake_tool["tree_entries_sha256"],
    },
    "cmake_source_count": 21,
    "frozen_cmake_template": "PASS",
    "actual_configured_argv": "GAP",
    "compile_membership_status": "GAP",
    "build_count": 0,
    "build_root_absent": True,
    "invocations": {
        "cmake_version": 0, "cmake_configure": 0, "cmake_build": 0, "ninja": 0,
        "verilator": 0, "verilator_generation": 0, "make": 0,
        "model_make": 0, "binary": 0, "model": 0, "qwen": 0,
        "synthesis": 0, "sta": 0, "ppa": 0,
    },
    "owned_background_jobs": 0,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "dynamic_status": "GAP",
    "qwen_status": "GAP",
    "deadline_edge_status": "GAP",
    "backend_concurrency_status": "CONDITIONAL_UNKNOWN",
    "artifacts": artifacts,
    "expected_final_status": "PASS",
    "expected_final_status_sha256": sha256_bytes(b"PASS\n"),
    "evidence_complete": 1,
}
atomic_write_json(receipt_path, receipt)
receipt_value, receipt_sha, _ = read_json_same_bytes(receipt_path)
if receipt_value.get("build_count") != 0:
    raise SystemExit("published preflight receipt mismatch")
sidecar = f"{receipt_sha}  {receipt_path.name}\n".encode()
atomic_write_bytes(sidecar_path, sidecar)

bound = dict(artifacts)
bound[receipt_path.relative_to(root).as_posix()] = build_artifact_record(
    root, receipt_path, "qwen-f32-alu-families-compile-v3-preflight-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {
    "schema": "qwen-f32-alu-families-compile-v3-preflight-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "artifact_count": len(bound),
    "artifacts": bound,
    "artifact_identity": revalidate_bound_artifacts(root, bound),
    "receipt_sha256": receipt_sha,
}
atomic_write_json(manifest_path, manifest)
manifest_value, manifest_sha, _ = read_json_same_bytes(manifest_path)
revalidate_bound_artifacts(root, manifest_value["artifacts"])
atomic_write_bytes(expected_status_path, b"PASS\n")
binding = {
    "schema": "qwen-f32-alu-families-compile-v3-preflight-final-binding-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "receipt_sha256": receipt_sha,
    "receipt_sidecar_sha256": sha256_bytes(sidecar),
    "bound_artifacts_sha256": manifest_sha,
    "content_addressed_snapshot_path": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "expected_final_status_sha256": sha256_bytes(b"PASS\n"),
    "actual_status_path": status_path.relative_to(root).as_posix(),
    "full_revalidation_before_and_after_status": True,
    "late_failure_must_overwrite_status": True,
    "pass_marker_is_final_successful_action": True,
}
atomic_write_json(binding_path, binding)
_, binding_sha, _ = read_json_same_bytes(binding_path)
print(receipt_sha, manifest_sha, binding_sha, content_sha,
      pre["files"][runner_relative]["sha256"])
PY
}

late_revalidate_preflight() {
    local phase="$1"
    local receipt_sha="$2"
    local manifest_sha="$3"
    local binding_sha="$4"
    local snapshot_sha="$5"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$TASK_ID" "$BUILD_ROOT" "$phase" \
        "$PREFLIGHT_STATUS" "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_SIDECAR" \
        "$PREFLIGHT_MANIFEST" "$PREFLIGHT_EXPECTED_STATUS" "$PREFLIGHT_BINDING" \
        "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha" <<'PY'
import json
import os
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes

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
expected_receipt_sha, expected_manifest_sha, expected_binding_sha, expected_snapshot_sha = sys.argv[12:16]

receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
binding, binding_sha, _ = read_json_same_bytes(binding_path)
sidecar = read_bytes_stable(sidecar_path)
expected_status = read_bytes_stable(expected_path)
actual_status = read_bytes_stable(status_path)
if (receipt_sha != expected_receipt_sha or manifest_sha != expected_manifest_sha or
        binding_sha != expected_binding_sha or expected_status != b"PASS\n" or
        sidecar != f"{receipt_sha}  {receipt_path.name}\n".encode()):
    raise SystemExit("preflight final document identity drift")
if (manifest.get("receipt_sha256") != receipt_sha or binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != manifest_sha or
        binding.get("content_addressed_snapshot_sha256") != expected_snapshot_sha):
    raise SystemExit("preflight binding semantic drift")
revalidate_bound_artifacts(root, manifest["artifacts"])

snapshot_path = root / binding["content_addressed_snapshot_path"]
snapshot, snapshot_sha, _ = read_json_same_bytes(snapshot_path)
if snapshot_sha != expected_snapshot_sha:
    raise SystemExit("preflight content snapshot drift")

def capture(path):
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        data = read_bytes_stable(resolved)
        return {"type": "symlink", "link_target": target,
                "link_sha256": sha256_bytes(target.encode()),
                "resolved_path": str(resolved), "resolved_sha256": sha256_bytes(data),
                "resolved_size_bytes": len(data)}
    if stat.S_ISDIR(observed.st_mode):
        return {"type": "directory", "mode": f"{stat.S_IMODE(observed.st_mode):04o}"}
    data = read_bytes_stable(path)
    if path.suffix == ".json":
        json.loads(data)
    return {"type": "regular", "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
            "sha256": sha256_bytes(data), "size_bytes": len(data)}

names = set(snapshot["explicit_paths"])
for relative_root in snapshot["directory_roots"]:
    directory = root / relative_root
    if not directory.is_dir() or directory.is_symlink():
        raise SystemExit("late frozen directory invalid: " + relative_root)
    for path in sorted(directory.rglob("*")):
        names.add(path.relative_to(root).as_posix())
if names != set(snapshot["files"]):
    raise SystemExit("late frozen workspace membership drift")
for relative, record in snapshot["files"].items():
    if capture(root / relative) != record:
        raise SystemExit("late frozen workspace byte drift: " + relative)
for absolute, record in snapshot["external"].items():
    if capture(pathlib.Path(absolute)) != record:
        raise SystemExit("late frozen external tool byte drift: " + absolute)
if build_root.exists() or build_root.is_symlink():
    raise SystemExit("build root created during preflight")
if read_bytes_stable(root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v3/staging/preflight-build.count") != b"0\n":
    raise SystemExit("preflight build count drift")

excluded = set()
pid = os.getpid()
while pid > 0 and pid not in excluded:
    excluded.add(pid)
    try:
        pid = int(pathlib.Path(f"/proc/{pid}/stat").read_text().split()[3])
    except (OSError, ValueError, IndexError):
        break
for entry in pathlib.Path("/proc").iterdir():
    if not entry.name.isdigit() or int(entry.name) in excluded:
        continue
    try:
        command = (entry / "cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace")
    except OSError:
        continue
    if task_id in command:
        raise SystemExit("late owned process detected pid=" + entry.name)
if phase == "before-status":
    if actual_status != b"RUNNING\n":
        raise SystemExit("preflight PASS visible before binding completion")
elif phase == "after-status":
    if actual_status != expected_status:
        raise SystemExit("preflight final PASS status mismatch")
else:
    raise SystemExit("unknown preflight revalidation phase")
print(sha256_bytes(actual_status))
PY
}

publish_preflight_marker() {
    local receipt_sha="$1"
    local manifest_sha="$2"
    local binding_sha="$3"
    local snapshot_sha="$4"
    local runner_sha="$5"
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V3][PREFLIGHT-PASS] build_count=0 build_root_absent=1 cmake_version=0 cmake_configure=0 cmake_build=0 ninja=0 verilator=0 verilator_generation=0 make=0 model_make=0 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 owned_background_jobs=0 cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 cmake_size=$PINNED_CMAKE_SIZE cmake_mode=0755 cmake_tree_entries=8173 cmake_tree_sha256=$PINNED_CMAKE_TREE_SHA256 cmake_v4_receipt_sha256=$CMAKE_V4_RECEIPT_SHA256 cmake_v4_manifest_sha256=$CMAKE_V4_MANIFEST_SHA256 cmake_v4_binding_sha256=$CMAKE_V4_BINDING_SHA256 cmake_v4_status_sha256=$CMAKE_V4_STATUS_SHA256 compile_v2_status_sha256=$COMPILE_V2_STATUS_SHA256 warning_expected_sha256=$WARNING_EXPECTED_SHA256 warning_rows=25-exact warning_mutations=7/7 cmake_source_count=21 frozen_cmake_template=PASS actual_configured_argv=GAP compile_membership=GAP verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN contract_sha256=$CONTRACT_SHA256 runner_sha256=$runner_sha receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha snapshot_sha256=$snapshot_sha"
}

run_preflight() {
    path_absent "$LOG_ROOT" || fail "fresh log root already exists=$LOG_ROOT"
    path_absent "$COMPILER_ROOT" || fail "fresh compiler root already exists=$COMPILER_ROOT"
    path_absent "$BUILD_ROOT" || fail "fresh build root already exists=$BUILD_ROOT"
    mkdir -m 700 -- "$LOG_ROOT" "$COMPILER_ROOT"
    mkdir -m 700 -- "$STAGING_ROOT" "$SEALED_ROOT" "$WORK_ROOT"

    task_run_status_init "$PREFLIGHT_STATUS"
    STATUS_INITIALIZED=1
    install_runner_traps
    atomic_text "$PREFLIGHT_BUILD_COUNT" $'0\n'

    task_run_status_stage "preflight-frozen-hash-admission"
    require_exact_hash "$CONTRACT" "$CONTRACT_SHA256"
    require_exact_hash "$MATERIAL" "$MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V2_CONTRACT" "$COMPILE_V2_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V2_MATERIAL" "$COMPILE_V2_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V2_RUNNER" "$COMPILE_V2_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V2_STATUS" "$COMPILE_V2_STATUS_SHA256"
    require_exact_hash "$CMAKE_V4_CONTRACT" "$CMAKE_V4_CONTRACT_SHA256"
    require_exact_hash "$CMAKE_V4_MATERIAL" "$CMAKE_V4_MATERIAL_SHA256"
    require_exact_hash "$CMAKE_V4_RUNNER" "$CMAKE_V4_RUNNER_SHA256"
    require_exact_hash "$CMAKE_V4_LOG_ROOT/receipt.json" "$CMAKE_V4_RECEIPT_SHA256"
    require_exact_hash "$CMAKE_V4_LOG_ROOT/bound-artifacts.json" "$CMAKE_V4_MANIFEST_SHA256"
    require_exact_hash "$CMAKE_V4_LOG_ROOT/final-binding.json" "$CMAKE_V4_BINDING_SHA256"
    require_exact_hash "$CMAKE_V4_LOG_ROOT/run.status" "$CMAKE_V4_STATUS_SHA256"
    require_exact_hash "$CMAKE_V3_TREE_MANIFEST" "$CMAKE_V3_TREE_MANIFEST_SHA256"
    require_exact_hash "$PINNED_CMAKE_EXE" "$PINNED_CMAKE_SHA256"
    require_exact_hash "$STATUS_HELPER" "$STATUS_HELPER_SHA256"
    require_exact_hash "$STATUS_HELPER_TEST" "$STATUS_HELPER_TEST_SHA256"
    require_exact_hash "$BUILD_IDENTITY_TOOL" "$IDENTITY_TOOL_SHA256"
    require_exact_hash "$BUILD_IDENTITY_TEST" "$IDENTITY_TEST_SHA256"
    require_exact_hash "$CMAKE_FILE" "$CMAKE_SHA256"
    require_exact_hash "$NPU_ROOT/runtime/llama-npu-backend/npu-verilator-runner.cpp" "$PRODUCTION_CPP_SHA256"
    require_exact_hash "$WARNING_SOURCE" "$WARNING_EXPECTED_SHA256"
    require_exact_hash "$WARNING_PARSER_PROVENANCE" "$WARNING_PARSER_SHA256"
    require_exact_hash "$WARNING_DIAGNOSTIC_PROVENANCE" "$WARNING_DIAGNOSTIC_SHA256"
    require_exact_hash "$WARNING_RUNNER_PROVENANCE" "$WARNING_RUNNER_SHA256"
    path_absent "$BUILD_ROOT" || fail "build root created during frozen admission"

    task_run_status_stage "preflight-input-snapshot"
    snapshot_inputs "$PREFLIGHT_SNAPSHOT_PRE"

    task_run_status_stage "preflight-cmake-v4-closure"
    audit_cmake_v4_closure

    task_run_status_stage "preflight-task-status-test"
    run_atomic_log "$TASK_STATUS_LOG" bash "$STATUS_HELPER_TEST"
    [[ "$(sed -n '1p' "$TASK_STATUS_LOG")" == \
       "[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM" ]] ||
        fail "task status helper directed-test marker mismatch"

    task_run_status_stage "preflight-identity-directed-tests"
    QWEN_F32_ALU_REPO_ROOT="$REPO_ROOT" \
        run_atomic_log "$IDENTITY_TEST_LOG" python3 "$BUILD_IDENTITY_TEST"
    [[ "$(sed -n '/\[qwen-f32-alu-build-identity-test\] PASS/p' "$IDENTITY_TEST_LOG")" != "" ]] ||
        fail "identity directed-test marker mismatch"

    task_run_status_stage "preflight-cmake-identity"
    run_atomic_log "$IDENTITY_LOG" python3 "$BUILD_IDENTITY_TOOL" \
        audit-cmake --repo-root "$REPO_ROOT" --cmake "$CMAKE_FILE" --output "$CMAKE_IDENTITY"

    task_run_status_stage "preflight-v11-closure"
    audit_v11_closure

    task_run_status_stage "preflight-warning-oracle"
    audit_warning_oracle

    task_run_status_stage "preflight-collect-policy"
    audit_collect_policy

    task_run_status_stage "preflight-zero-action-boundary"
    [[ "$(<"$PREFLIGHT_BUILD_COUNT")" == "0" ]] || fail "preflight build count changed"
    path_absent "$BUILD_ROOT" || fail "build root created during preflight"
    write_process_audit "preflight" "$PREFLIGHT_PROCESS_AUDIT"

    task_run_status_stage "preflight-input-post-snapshot"
    snapshot_inputs "$PREFLIGHT_SNAPSHOT_POST"
    [[ "$(file_sha "$PREFLIGHT_SNAPSHOT_PRE")" == "$(file_sha "$PREFLIGHT_SNAPSHOT_POST")" ]] ||
        fail "preflight source/tool/DSO snapshot drift"

    task_run_status_stage "preflight-content-snapshot"
    PREFLIGHT_CONTENT_SNAPSHOT=$(publish_content_snapshot "$PREFLIGHT_SNAPSHOT_PRE")

    task_run_status_stage "preflight-receipt-binding"
    local seal_result
    local receipt_sha manifest_sha binding_sha snapshot_sha runner_sha
    seal_result=$(seal_preflight)
    read -r receipt_sha manifest_sha binding_sha snapshot_sha runner_sha <<<"$seal_result"
    for value in "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha" "$runner_sha"; do
        [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "invalid seal hash=$value"
    done

    task_run_status_stage "preflight-late-revalidation-before-status"
    late_revalidate_preflight before-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha" >/dev/null

    task_run_status_stage "preflight-status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0

    task_run_status_stage "preflight-late-revalidation-after-status"
    local status_sha
    status_sha=$(late_revalidate_preflight after-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha")
    [[ "$status_sha" == "$(file_sha "$PREFLIGHT_EXPECTED_STATUS")" ]] ||
        fail "preflight post-status hash mismatch"

    task_run_status_stage "preflight-single-terminal-marker"
    publish_preflight_marker "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha" "$runner_sha"
}

verify_preflight_for_collect() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$PREFLIGHT_STATUS" \
        "$PREFLIGHT_RECEIPT" "$PREFLIGHT_RECEIPT_SIDECAR" "$PREFLIGHT_MANIFEST" \
        "$PREFLIGHT_EXPECTED_STATUS" "$PREFLIGHT_BINDING" <<'PY'
import json
import os
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3])
status = pathlib.Path(sys.argv[4])
receipt_path = pathlib.Path(sys.argv[5])
sidecar_path = pathlib.Path(sys.argv[6])
manifest_path = pathlib.Path(sys.argv[7])
expected_path = pathlib.Path(sys.argv[8])
binding_path = pathlib.Path(sys.argv[9])
receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
binding, _, _ = read_json_same_bytes(binding_path)
if (read_bytes_stable(status) != b"PASS\n" or read_bytes_stable(expected_path) != b"PASS\n" or
        read_bytes_stable(sidecar_path) != f"{receipt_sha}  {receipt_path.name}\n".encode() or
        manifest.get("receipt_sha256") != receipt_sha or binding.get("receipt_sha256") != receipt_sha or
        binding.get("bound_artifacts_sha256") != manifest_sha or receipt.get("build_count") != 0 or
        receipt.get("contract_sha256") !=
        "581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6" or
        receipt.get("cmake_tool_identity", {}).get("absolute_path") !=
        "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake" or
        receipt.get("cmake_tool_identity", {}).get("sha256") !=
        "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863" or
        receipt.get("cmake_tool_identity", {}).get("tree_entries_sha256") !=
        "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc" or
        receipt.get("cmake_tool_v4", {}).get("receipt_sha256") !=
        "03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652" or
        receipt.get("compile_v2_closure", {}).get("build_count") != 0 or
        receipt.get("warning_expected_sha256") != "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c"):
    raise SystemExit("preflight admission closure mismatch")
revalidate_bound_artifacts(root, manifest["artifacts"])
if build_root.exists() or build_root.is_symlink():
    raise SystemExit("collect build root is not fresh")
snapshot_path = root / binding["content_addressed_snapshot_path"]
snapshot, snapshot_sha, _ = read_json_same_bytes(snapshot_path)
if snapshot_sha != binding.get("content_addressed_snapshot_sha256"):
    raise SystemExit("preflight snapshot hash mismatch")

def capture(path):
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        data = read_bytes_stable(resolved)
        return {"type": "symlink", "link_target": target,
                "link_sha256": sha256_bytes(target.encode()), "resolved_path": str(resolved),
                "resolved_sha256": sha256_bytes(data), "resolved_size_bytes": len(data)}
    if stat.S_ISDIR(observed.st_mode):
        return {"type": "directory", "mode": f"{stat.S_IMODE(observed.st_mode):04o}"}
    data = read_bytes_stable(path)
    if path.suffix == ".json":
        json.loads(data)
    return {"type": "regular", "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
            "sha256": sha256_bytes(data), "size_bytes": len(data)}

names = set(snapshot["explicit_paths"])
for relative_root in snapshot["directory_roots"]:
    for path in sorted((root / relative_root).rglob("*")):
        names.add(path.relative_to(root).as_posix())
if names != set(snapshot["files"]):
    raise SystemExit("collect input membership drift")
for relative, record in snapshot["files"].items():
    if capture(root / relative) != record:
        raise SystemExit("collect input byte drift: " + relative)
for absolute, record in snapshot["external"].items():
    if capture(pathlib.Path(absolute)) != record:
        raise SystemExit("collect external tool byte drift: " + absolute)
PY
}

initialize_collect_ledger() {
    python3 - "$NPU_ROOT/scripts" "$COLLECT_ACTION_LEDGER" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json
atomic_write_json(pathlib.Path(sys.argv[2]), {
    "schema": "qwen-f32-alu-families-compile-v3-action-ledger-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "counts": {"cmake-configure": 0, "cmake-build": 0, "binary": 0,
               "model": 0, "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0},
    "ordered_actions": [],
})
PY
}

run_collect_action() {
    local kind="$1"
    local log="$2"
    local argv_json="$3"
    local rc_path="$4"
    shift 4
    case "$kind" in
        cmake-configure|cmake-build) ;;
        *) fail "forbidden collect action=$kind" ;;
    esac
    python3 - "$NPU_ROOT/scripts" "$COLLECT_ACTION_LEDGER" "$kind" "$REPO_ROOT" "$argv_json" "$@" <<'PY'
import hashlib
import json
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable, read_json_same_bytes
ledger_path = pathlib.Path(sys.argv[2])
kind = sys.argv[3]
cwd = pathlib.Path(sys.argv[4]).resolve(strict=True)
argv_path = pathlib.Path(sys.argv[5])
argv = sys.argv[6:]
ledger, _, _ = read_json_same_bytes(ledger_path)
expected = "cmake-configure" if not ledger["ordered_actions"] else "cmake-build"
if kind != expected or ledger["counts"][kind] != 0 or len(ledger["ordered_actions"]) >= 2:
    raise SystemExit("collect action order/count violation")
pinned = pathlib.Path(
    "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake"
)
raw_executable = pathlib.Path(argv[0])
if (
    not raw_executable.is_absolute()
    or raw_executable != pinned
    or raw_executable.resolve(strict=True) != pinned
):
    raise SystemExit("collect action did not use pinned absolute CMake")
observed = raw_executable.lstat()
data = read_bytes_stable(raw_executable)
if (
    not stat.S_ISREG(observed.st_mode)
    or stat.S_ISLNK(observed.st_mode)
    or stat.S_IMODE(observed.st_mode) != 0o755
    or len(data) != 17241856
    or hashlib.sha256(data).hexdigest()
       != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
):
    raise SystemExit("collect pinned CMake byte identity mismatch")
executable = raw_executable
atomic_write_json(argv_path, {
    "schema": "qwen-f32-alu-families-compile-v3-actual-argv-v1",
    "kind": kind, "cwd": str(cwd), "argv": argv,
    "executable": str(executable), "executable_sha256": hashlib.sha256(data).hexdigest(),
    "executable_mode": "0755", "executable_size": len(data),
    "environment": {"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
})
ledger["counts"][kind] = 1
ledger["ordered_actions"].append(kind)
atomic_write_json(ledger_path, ledger)
PY
    local rc=0
    ( set -o noclobber; : >"$log" ) || fail "action log already exists=$log"
    set +e
    (cd "$REPO_ROOT" && "$@") >"$log" 2>&1
    rc=$?
    set -e
    atomic_text "$rc_path" "$rc"$'\n'
    return "$rc"
}

audit_collect_evidence() {
    resolve_tools
    mkdir -m 700 -- "$NORMALIZED_DEPFILE_ROOT"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$CMAKE_BUILD_ROOT" \
        "$VERILATED_ROOT" "$VERILATOR_ROOT" "$VERILATOR_BIN_EXE" \
        "$EXPECTED_WARNING_COPY" "$LOG_ROOT/cmake-build.log" "$COLLECT_ACTION_LEDGER" \
        "$LOG_ROOT/cmake-configure.argv.json" "$LOG_ROOT/cmake-build.argv.json" \
        "$LOG_ROOT/cmake-configure.rc" "$LOG_ROOT/cmake-build.rc" \
        "$NORMALIZED_DEPFILE_ROOT" "$COMMAND_LEDGER" "$WARNING_ACTUAL" \
        "$WARNING_BUILD_AUDIT" "$MEMBERSHIP_AUDIT" "$OBJECT_DEPFILE_AUDIT" \
        "$BUILD_ARTIFACT_MANIFEST" "${RTL_SOURCES_REL[@]}" <<'PY'
import collections
import hashlib
import json
import os
import pathlib
import re
import shlex
import shutil
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_bytes, atomic_write_json, parse_make_depfile_bytes,
    parse_verfiles_s_rows, read_bytes_stable, read_json_same_bytes, sha256_bytes,
)

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3]).resolve(strict=True)
cmake_root = pathlib.Path(sys.argv[4]).resolve(strict=True)
verilated_root = pathlib.Path(sys.argv[5]).resolve(strict=True)
verilator_root = pathlib.Path(sys.argv[6]).resolve(strict=True)
verilator_bin = pathlib.Path(sys.argv[7]).resolve(strict=True)
expected_warning = pathlib.Path(sys.argv[8])
build_log = pathlib.Path(sys.argv[9])
ledger_path = pathlib.Path(sys.argv[10])
configure_argv_path = pathlib.Path(sys.argv[11])
build_argv_path = pathlib.Path(sys.argv[12])
configure_rc = pathlib.Path(sys.argv[13])
build_rc = pathlib.Path(sys.argv[14])
normalized_root = pathlib.Path(sys.argv[15])
command_output = pathlib.Path(sys.argv[16])
actual_warning_output = pathlib.Path(sys.argv[17])
warning_output = pathlib.Path(sys.argv[18])
membership_output = pathlib.Path(sys.argv[19])
depfile_output = pathlib.Path(sys.argv[20])
artifact_output = pathlib.Path(sys.argv[21])
design_rel = sys.argv[22:]

ledger, _, _ = read_json_same_bytes(ledger_path)
if (ledger.get("ordered_actions") != ["cmake-configure", "cmake-build"] or
        ledger.get("counts") != {"cmake-configure": 1, "cmake-build": 1,
                                  "binary": 0, "model": 0, "qwen": 0,
                                  "synthesis": 0, "sta": 0, "ppa": 0} or
        read_bytes_stable(configure_rc) != b"0\n" or read_bytes_stable(build_rc) != b"0\n"):
    raise SystemExit("collect action ledger/return-code mismatch")
configure_argv = read_json_same_bytes(configure_argv_path)[0]
build_argv = read_json_same_bytes(build_argv_path)[0]
pinned_cmake = "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake"
for action in (configure_argv, build_argv):
    if (action.get("argv", [None])[0] != pinned_cmake or
            action.get("executable") != pinned_cmake or
            action.get("executable_sha256") !=
            "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863" or
            action.get("executable_mode") != "0755" or
            action.get("executable_size") != 17241856 or
            action.get("cwd") != str(root)):
        raise SystemExit("actual action did not bind pinned absolute CMake")
if ("-DCMAKE_BUILD_TYPE=Release" not in configure_argv["argv"] or
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" not in configure_argv["argv"] or
        "-DNPU_VERILATOR_JOBS=1" not in configure_argv["argv"] or
        "--parallel" not in build_argv["argv"] or "1" not in build_argv["argv"] or
        "--verbose" not in build_argv["argv"]):
    raise SystemExit("actual configured O3/j1/verbose argv mismatch")

expected = []
for raw in read_bytes_stable(expected_warning).decode().splitlines():
    category, path, line_no, column = raw.split("\t")
    expected.append((category, path, int(line_no), int(column)))
text = read_bytes_stable(build_log).decode("utf-8", errors="replace")
primary = re.compile(r"^%Warning-([A-Z0-9_]+):\s+(.+?):([0-9]+):([0-9]+):")
actual = []
diagnostic_extras = []
for raw in text.splitlines():
    match = primary.match(raw)
    if match:
        path = pathlib.Path(match.group(2)).resolve()
        actual.append((match.group(1), path.relative_to(root).as_posix(),
                       int(match.group(3)), int(match.group(4))))
        continue
    if re.search(r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
                 raw, re.IGNORECASE):
        diagnostic_extras.append(raw)
if collections.Counter(actual) != collections.Counter(expected) or diagnostic_extras:
    missing = list((collections.Counter(expected) - collections.Counter(actual)).elements())
    extra = list((collections.Counter(actual) - collections.Counter(expected)).elements())
    raise SystemExit("exact warning diagnostic mismatch missing=" + repr(missing) +
                     " extra=" + repr(extra) + " other=" + repr(diagnostic_extras))
atomic_write_bytes(actual_warning_output, "".join(
    f"{a}\t{b}\t{c}\t{d}\n" for a, b, c, d in actual).encode())
atomic_write_json(warning_output, {
    "schema": "qwen-f32-alu-families-compile-v3-build-diagnostics-v1",
    "expected_warning_rows": 25, "actual_warning_rows": 25,
    "warning_classes": {"legacy_fpu_sp": 21, "legacy_fp32_addmul": 4},
    "new_source_warning_count": 0, "compiler_make_warning_count": 0,
    "error_count": 0, "expected_tsv_sha256": sha256_bytes(read_bytes_stable(expected_warning)),
})

verfiles = verilated_root / "VTensorNpuCoprocessor__verFiles.dat"
archive = verilated_root / "VTensorNpuCoprocessor__ALL.a"
linked_binary = cmake_root / "test-npu-backend"
module_dso = cmake_root / "libggml-npu.so"
for path in (verfiles, archive, linked_binary, module_dso):
    if not path.is_file() or path.is_symlink():
        raise SystemExit("required linked/generated artifact missing/aliased: " + str(path))
expected_groups = {
    "design": [str((root / item).resolve(strict=True)) for item in design_rel],
    "control": [str((verilator_root / "include/verilated_std.sv").resolve(strict=True))],
    "tool": [str(verilator_bin)],
}
rows = [str(pathlib.Path(value).resolve(strict=True)) for value in parse_verfiles_s_rows(read_bytes_stable(verfiles))]
owners = {path: name for name, values in expected_groups.items() for path in values}
if len(owners) != 23 or len(rows) != 23 or len(set(rows)) != 23 or set(rows) != set(owners):
    raise SystemExit("actual __verFiles.dat 21+1+1 membership mismatch")
ordered_design = [row for row in rows if owners[row] == "design"]
if ordered_design != expected_groups["design"]:
    raise SystemExit("actual __verFiles.dat design order mismatch")
atomic_write_json(membership_output, {
    "schema": "qwen-f32-alu-families-compile-v3-elaboration-membership-v1",
    "verfiles_path": str(verfiles), "verfiles_sha256": sha256_bytes(read_bytes_stable(verfiles)),
    "raw_s_row_count": len(rows), "raw_s_rows": rows,
    "classes": expected_groups, "class_counts": {"design": 21, "control": 1, "tool": 1},
    "compile_membership_status": "PASS", "ordered_design_membership": True,
})

def command_tokens(raw):
    line = raw.strip()
    cwd = None
    if line.startswith("cd ") and " && " in line:
        prefix, line = line.split(" && ", 1)
        prefix_tokens = shlex.split(prefix)
        if len(prefix_tokens) == 2:
            cwd = pathlib.Path(prefix_tokens[1]).resolve()
    try:
        tokens = shlex.split(line)
    except ValueError:
        return None
    if not tokens:
        return None
    while tokens and tokens[0] in {"env", "/usr/bin/env"}:
        tokens.pop(0)
        while tokens and "=" in tokens[0] and not tokens[0].startswith("-"):
            tokens.pop(0)
    return cwd, tokens

raw_commands = []
for raw in text.splitlines():
    parsed = command_tokens(raw)
    if parsed is None:
        continue
    cwd, tokens = parsed
    executable = pathlib.Path(shutil.which(tokens[0]) or tokens[0])
    try:
        executable = executable.resolve(strict=True)
    except OSError:
        continue
    base = executable.name
    if ("--cc" in tokens and "--top-module" in tokens) or base in {"c++", "g++", "gcc", "clang++", "ar", "ranlib", "gmake", "make"}:
        raw_commands.append({"raw": raw, "cwd": str(cwd) if cwd else None,
                             "argv": tokens, "executable": str(executable),
                             "executable_sha256": sha256_bytes(read_bytes_stable(executable))})
verilator_rows = [row for row in raw_commands if "--cc" in row["argv"] and "--top-module" in row["argv"]]
if len(verilator_rows) != 1:
    raise SystemExit("actual Verilator command cardinality mismatch")
verilator_argv = verilator_rows[0]["argv"]
for token in ("--cc", "-O3", "-Wall", "-Wno-fatal", "--no-assert", "--no-trace",
              "--top-module", "TensorNpuCoprocessor"):
    if verilator_argv.count(token) != 1:
        raise SystemExit("actual Verilator option cardinality mismatch: " + token)
actual_design = [str(pathlib.Path(token).resolve(strict=True)) for token in verilator_argv if token.endswith((".v", ".sv", ".vh"))]
if actual_design[-21:] != expected_groups["design"]:
    raise SystemExit("actual Verilator argv ordered design mismatch")
model_make_rows = [row for row in raw_commands if row["executable"].endswith(("/make", "/gmake")) and
                   "VTensorNpuCoprocessor__ALL.a" in row["argv"] and "-j1" in row["argv"]]
if len(model_make_rows) != 1:
    raise SystemExit("actual generated-model make -j1 cardinality mismatch")

objects = sorted(path.resolve(strict=True) for path in build_root.rglob("*.o") if path.is_file() and not path.is_symlink())
depfiles = sorted(path.resolve(strict=True) for path in build_root.rglob("*.d") if path.is_file() and not path.is_symlink())
if not objects or not depfiles or len(objects) != len(depfiles):
    raise SystemExit("object/depfile cardinality mismatch")

compiler_rows = []
for row in raw_commands:
    argv = row["argv"]
    if "-c" not in argv or "-o" not in argv:
        continue
    object_token = argv[argv.index("-o") + 1]
    candidates = []
    if pathlib.Path(object_token).is_absolute():
        candidates = [pathlib.Path(object_token).resolve()]
    else:
        for cwd in ([pathlib.Path(row["cwd"])] if row["cwd"] else []) + [verilated_root, cmake_root, root]:
            candidate = (cwd / object_token).resolve()
            if candidate in objects and candidate not in candidates:
                candidates.append(candidate)
    if len(candidates) != 1:
        continue
    object_path = candidates[0]
    source_token = argv[argv.index("-c") + 1]
    source_candidates = []
    source_raw = pathlib.Path(source_token)
    if source_raw.is_absolute():
        source_candidates = [source_raw.resolve(strict=True)]
    else:
        for cwd in ([pathlib.Path(row["cwd"])] if row["cwd"] else []) + [verilated_root, cmake_root, root]:
            candidate = (cwd / source_raw).resolve()
            if candidate.exists() and candidate not in source_candidates:
                source_candidates.append(candidate)
    if len(source_candidates) != 1:
        raise SystemExit("compiler source path is ambiguous: " + source_token)
    source_path = source_candidates[0]
    explicit_dep = None
    if "-MF" in argv:
        explicit_dep = pathlib.Path(argv[argv.index("-MF") + 1])
        if not explicit_dep.is_absolute():
            explicit_dep = ((pathlib.Path(row["cwd"]) if row["cwd"] else cmake_root) / explicit_dep)
        explicit_dep = explicit_dep.resolve()
    else:
        explicit_dep = object_path.with_suffix(".d")
    category = "generated-model" if source_path.is_relative_to(verilated_root) else (
        "verilator-runtime" if source_path.is_relative_to(verilator_root) else "backend-runtime")
    compiler_rows.append({**row, "object": str(object_path), "source": str(source_path),
                          "depfile": str(explicit_dep), "category": category})
if {pathlib.Path(row["object"]) for row in compiler_rows} != set(objects):
    raise SystemExit("actual compiler argv/object closure mismatch")
if {pathlib.Path(row["depfile"]) for row in compiler_rows} != set(depfiles):
    raise SystemExit("actual compiler argv/depfile closure mismatch")

def make_tokens(value):
    tokens = []
    current = []
    escaped = False
    for char in value:
        if escaped:
            if char == "\n":
                escaped = False
                continue
            current.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char.isspace():
            if current:
                tokens.append("".join(current)); current = []
        else:
            current.append(char)
    if escaped:
        raise SystemExit("dangling depfile escape")
    if current:
        tokens.append("".join(current))
    return tokens

dep_records = []
for index, row in enumerate(sorted(compiler_rows, key=lambda item: item["object"])):
    depfile = pathlib.Path(row["depfile"])
    data = read_bytes_stable(depfile)
    text_dep = data.decode("utf-8")
    logical = text_dep.replace("\\\r\n", "").replace("\\\n", "").splitlines()
    rules = []
    for line in logical:
        if not line.strip():
            continue
        colon = None
        escaped = False
        for position, char in enumerate(line):
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == ":":
                colon = position; break
        if colon is None:
            raise SystemExit("depfile rule lacks colon: " + str(depfile))
        targets = make_tokens(line[:colon])
        prerequisites = make_tokens(line[colon + 1:])
        if not targets:
            raise SystemExit("depfile rule lacks target: " + str(depfile))
        rules.append((targets, prerequisites))
    object_path = pathlib.Path(row["object"])
    primary = []
    for targets, prerequisites in rules:
        resolved_targets = [str((depfile.parent / target).resolve()) if not pathlib.Path(target).is_absolute()
                            else str(pathlib.Path(target).resolve()) for target in targets]
        if str(object_path) in resolved_targets and prerequisites:
            primary.append((resolved_targets, prerequisites))
    if len(primary) != 1:
        raise SystemExit("depfile primary object rule mismatch: " + str(depfile))
    prerequisites = []
    for token in primary[0][1]:
        path = pathlib.Path(token)
        if not path.is_absolute():
            candidates = [(depfile.parent / path).resolve(), (pathlib.Path(row["cwd"]) / path).resolve() if row["cwd"] else None,
                          (verilated_root / path).resolve(), (cmake_root / path).resolve(), (root / path).resolve()]
            existing = [candidate for candidate in candidates if candidate is not None and candidate.exists()]
            if not existing:
                raise SystemExit("depfile prerequisite missing: " + token)
            path = existing[0]
        else:
            path = path.resolve(strict=True)
        prerequisites.append(str(path))
    if len(prerequisites) != len(set(prerequisites)):
        raise SystemExit("duplicate primary prerequisite: " + str(depfile))
    normalized = normalized_root / f"{index:04d}.d"
    def escape(value):
        return value.replace("\\", "\\\\").replace(" ", "\\ ")
    normalized_bytes = (escape(str(object_path)) + ": " + " ".join(escape(item) for item in prerequisites) + "\n").encode()
    atomic_write_bytes(normalized, normalized_bytes)
    parsed = parse_make_depfile_bytes(read_bytes_stable(normalized))
    if len(parsed) != 1:
        raise SystemExit("normalized strict depfile parser mismatch")
    dep_records.append({"path": str(depfile), "sha256": sha256_bytes(data),
                        "size_bytes": len(data), "primary_target": str(object_path),
                        "prerequisites": prerequisites, "normalized_path": str(normalized),
                        "normalized_sha256": sha256_bytes(normalized_bytes)})

object_records = [{"path": str(path), "sha256": sha256_bytes(read_bytes_stable(path)),
                   "size_bytes": len(read_bytes_stable(path)),
                   "category": next(row["category"] for row in compiler_rows if row["object"] == str(path))}
                  for path in objects]
atomic_write_json(depfile_output, {
    "schema": "qwen-f32-alu-families-compile-v3-object-depfile-closure-v1",
    "object_count": len(object_records), "depfile_count": len(dep_records),
    "objects": object_records, "depfiles": dep_records,
    "object_paths_exact": True, "depfile_paths_exact": True,
    "compiler_argv_exact": True, "normalized_strict_parser": "PASS",
})

link_rows = [row for row in raw_commands if "-o" in row["argv"] and "-c" not in row["argv"]]
backend_link_rows = []
for row in link_rows:
    output_token = pathlib.Path(row["argv"][row["argv"].index("-o") + 1])
    if output_token.name != "test-npu-backend":
        continue
    output_path = output_token if output_token.is_absolute() else (
        pathlib.Path(row["cwd"] or cmake_root) / output_token
    )
    if output_path.resolve(strict=True) != linked_binary:
        raise SystemExit("final backend link output identity mismatch")
    backend_link_rows.append(row)
if len(backend_link_rows) != 1:
    raise SystemExit("final backend binary link argv cardinality mismatch")
atomic_write_json(command_output, {
    "schema": "qwen-f32-alu-families-compile-v3-actual-command-ledger-v1",
    "cmake_configure": configure_argv, "cmake_build": build_argv,
    "verilator": verilator_rows[0], "model_make": model_make_rows[0],
    "compiler_rows": compiler_rows, "link_rows": link_rows,
    "backend_link": backend_link_rows[0],
    "counts": {"cmake_configure": 1, "cmake_build": 1, "verilator": 1,
               "model_make": 1, "compiler": len(compiler_rows), "link": len(link_rows),
               "binary_runs": 0, "model_runs": 0},
})

artifacts = {}
for path in sorted(build_root.rglob("*")):
    if path.is_dir() and not path.is_symlink():
        continue
    relative = path.relative_to(root).as_posix()
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path)
        resolved = path.resolve(strict=True)
        data = read_bytes_stable(resolved)
        artifacts[relative] = {"type": "symlink", "link_target": target,
                               "link_sha256": sha256_bytes(target.encode()),
                               "resolved_path": str(resolved), "resolved_sha256": sha256_bytes(data),
                               "resolved_size_bytes": len(data)}
    elif stat.S_ISREG(observed.st_mode):
        data = read_bytes_stable(path)
        artifacts[relative] = {"type": "regular", "sha256": sha256_bytes(data),
                               "size_bytes": len(data)}
    else:
        raise SystemExit("unsupported build artifact type: " + str(path))
runtime_only_suffixes = {
    ".vcd", ".fst", ".lxt", ".lxt2", ".wlf", ".vpd", ".saif", ".ucis",
    ".gcda", ".gcno",
}
runtime_only = [
    relative for relative in artifacts
    if pathlib.PurePosixPath(relative).suffix.lower() in runtime_only_suffixes
    or pathlib.PurePosixPath(relative).name.lower() in {"coverage.dat", "coverage.info"}
]
if runtime_only:
    raise SystemExit("wave/trace/coverage runtime artifact found: " + repr(runtime_only))
public_headers = sorted(str(path) for path in verilated_root.glob("VTensorNpuCoprocessor*.h") if path.is_file())
if not public_headers:
    raise SystemExit("generated public headers missing")
atomic_write_json(artifact_output, {
    "schema": "qwen-f32-alu-families-compile-v3-build-artifact-manifest-v1",
    "artifact_count": len(artifacts), "artifacts": artifacts,
    "generated_archive": str(archive), "generated_public_headers": public_headers,
    "verfiles": str(verfiles), "linked_binary": str(linked_binary),
    "linked_binary_sha256": sha256_bytes(read_bytes_stable(linked_binary)),
    "linked_module": str(module_dso), "linked_module_sha256": sha256_bytes(read_bytes_stable(module_dso)),
    "binary_execution_count": 0, "model_execution_count": 0,
    "wave_trace_coverage_file_count": 0,
})
PY
}

seal_compile() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$COMPILE_STATUS" \
        "$COMPILE_RECEIPT" "$COMPILE_RECEIPT_SIDECAR" "$COMPILE_MANIFEST" \
        "$COMPILE_EXPECTED_STATUS" "$COMPILE_BINDING" "$COLLECT_BUILD_COUNT" \
        "$COLLECT_ACTION_LEDGER" "$COLLECT_SNAPSHOT_PRE" "$COLLECT_SNAPSHOT_POST" \
        "$COLLECT_SNAPSHOT_PRESTATUS" "$COLLECT_PROCESS_AUDIT" "$COMMAND_LEDGER" \
        "$WARNING_ACTUAL" "$WARNING_BUILD_AUDIT" "$MEMBERSHIP_AUDIT" \
        "$OBJECT_DEPFILE_AUDIT" "$BUILD_ARTIFACT_MANIFEST" \
        "$LOG_ROOT/cmake-configure.argv.json" "$LOG_ROOT/cmake-configure.log" \
        "$LOG_ROOT/cmake-configure.rc" "$LOG_ROOT/cmake-build.argv.json" \
        "$LOG_ROOT/cmake-build.log" "$LOG_ROOT/cmake-build.rc" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_bytes, atomic_write_json, build_artifact_record,
    read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes,
)
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3]).resolve(strict=True)
status_path = pathlib.Path(sys.argv[4])
receipt_path, sidecar_path, manifest_path = map(pathlib.Path, sys.argv[5:8])
expected_path, binding_path = map(pathlib.Path, sys.argv[8:10])
artifact_paths = [pathlib.Path(value) for value in sys.argv[10:]]
schemas = {
    "collect-action-ledger.json": "qwen-f32-alu-families-compile-v3-action-ledger-v1",
    "collect-inputs.pre.json": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "collect-inputs.post.json": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "collect-inputs.prestatus.json": "qwen-f32-alu-families-compile-v3-frozen-inputs-v1",
    "collect-process-audit.json": "qwen-f32-alu-families-compile-v3-process-audit-v1",
    "actual-command-ledger.json": "qwen-f32-alu-families-compile-v3-actual-command-ledger-v1",
    "build-diagnostic-audit.json": "qwen-f32-alu-families-compile-v3-build-diagnostics-v1",
    "elaboration-membership.json": "qwen-f32-alu-families-compile-v3-elaboration-membership-v1",
    "object-depfile-closure.json": "qwen-f32-alu-families-compile-v3-object-depfile-closure-v1",
    "build-artifact-manifest.json": "qwen-f32-alu-families-compile-v3-build-artifact-manifest-v1",
    "cmake-configure.argv.json": "qwen-f32-alu-families-compile-v3-actual-argv-v1",
    "cmake-build.argv.json": "qwen-f32-alu-families-compile-v3-actual-argv-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    schema = schemas.get(path.name)
    relative = path.resolve(strict=True).relative_to(root).as_posix()
    artifacts[relative] = build_artifact_record(root, path, schema)
    if schema:
        parsed[path.name] = read_json_same_bytes(path)[0]
for record in parsed["object-depfile-closure.json"]["depfiles"]:
    normalized = pathlib.Path(record["normalized_path"])
    relative = normalized.resolve(strict=True).relative_to(root).as_posix()
    if relative in artifacts:
        raise SystemExit("duplicate normalized depfile artifact: " + relative)
    artifacts[relative] = build_artifact_record(root, normalized, None)
if read_bytes_stable(next(path for path in artifact_paths if path.name == "collect-build.count")) != b"1\n":
    raise SystemExit("compile build count mismatch")
if not (parsed["collect-inputs.pre.json"] == parsed["collect-inputs.post.json"] ==
        parsed["collect-inputs.prestatus.json"]):
    raise SystemExit("compile source/tool/DSO pre/post/prestatus drift")
commands = parsed["actual-command-ledger.json"]
membership = parsed["elaboration-membership.json"]
warnings = parsed["build-diagnostic-audit.json"]
closure = parsed["object-depfile-closure.json"]
build_manifest = parsed["build-artifact-manifest.json"]
process = parsed["collect-process-audit.json"]
if (commands["counts"]["cmake_configure"] != 1 or commands["counts"]["cmake_build"] != 1 or
        commands["counts"]["binary_runs"] != 0 or commands["counts"]["model_runs"] != 0 or
        commands["cmake_configure"].get("executable") !=
        "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake" or
        commands["cmake_build"].get("executable") !=
        "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake" or
        commands["cmake_configure"].get("executable_sha256") !=
        "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863" or
        commands["cmake_build"].get("executable_sha256") !=
        "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863" or
        not isinstance(commands.get("backend_link"), dict) or
        membership.get("class_counts") != {"design": 21, "control": 1, "tool": 1} or
        warnings.get("actual_warning_rows") != 25 or warnings.get("error_count") != 0 or
        closure.get("compiler_argv_exact") is not True or closure.get("normalized_strict_parser") != "PASS" or
        build_manifest.get("binary_execution_count") != 0 or
        build_manifest.get("wave_trace_coverage_file_count") != 0 or
        process.get("owned_background_jobs") != 0):
    raise SystemExit("compile evidence semantic mismatch")

receipt = {
    "schema": "qwen-f32-alu-families-compile-v3-compile-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v3",
    "contract_sha256": "581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6",
    "build_count": 1,
    "build_config": "CMake-Release-O3/no-assert/no-trace/j1",
    "actual_configured_argv": True,
    "cmake_tool": {
        "absolute_path": commands["cmake_configure"]["executable"],
        "sha256": commands["cmake_configure"]["executable_sha256"],
        "size": commands["cmake_configure"]["executable_size"],
        "mode": commands["cmake_configure"]["executable_mode"],
        "qualified_v4_receipt_sha256":
            "03408df26f5828bf8036969628c0633ed67d5151010f5138b53f779f4a302652",
        "qualified_v4_binding_sha256":
            "20ba4677fab027042e2967f979a25a53556a8cda4a797da757a9a9bbd855374a",
        "installed_tree_sha256":
            "6684ebb569e01ab49311f053bf3e7a7b6243f8edfa5311ef855b378ef71f20dc",
    },
    "actual_membership": {"design": 21, "control": 1, "tool": 1},
    "object_count": closure["object_count"], "depfile_count": closure["depfile_count"],
    "objects_depfiles_exact": True,
    "warning_expected_sha256": "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c",
    "warning_census": "25-exact", "errors": 0,
    "linked_binary": build_manifest["linked_binary"],
    "linked_binary_sha256": build_manifest["linked_binary_sha256"],
    "binary_runs": 0, "model_runs": 0, "qwen_runs": 0,
    "synthesis": 0, "sta": 0, "ppa": 0,
    "wave_trace_coverage_files": 0, "owned_background_jobs": 0,
    "verified_canonical_node_identities_completed": 0,
    "remaining_nonmetadata_gap": 1079,
    "dynamic_status": "GAP", "qwen_status": "GAP", "deadline_edge_status": "GAP",
    "backend_concurrency_status": "CONDITIONAL_UNKNOWN",
    "artifacts": artifacts,
    "build_artifact_manifest_sha256": sha256_bytes(read_bytes_stable(
        next(path for path in artifact_paths if path.name == "build-artifact-manifest.json"))),
    "expected_final_status": "PASS", "expected_final_status_sha256": sha256_bytes(b"PASS\n"),
    "evidence_complete": 1,
}
atomic_write_json(receipt_path, receipt)
_, receipt_sha, _ = read_json_same_bytes(receipt_path)
sidecar = f"{receipt_sha}  {receipt_path.name}\n".encode()
atomic_write_bytes(sidecar_path, sidecar)
bound = dict(artifacts)
bound[receipt_path.relative_to(root).as_posix()] = build_artifact_record(
    root, receipt_path, "qwen-f32-alu-families-compile-v3-compile-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {"schema": "qwen-f32-alu-families-compile-v3-compile-bound-artifacts-v1",
            "task_id": "qwen-f32-alu-families-compile-v3", "artifact_count": len(bound),
            "artifacts": bound, "artifact_identity": revalidate_bound_artifacts(root, bound),
            "receipt_sha256": receipt_sha}
atomic_write_json(manifest_path, manifest)
_, manifest_sha, _ = read_json_same_bytes(manifest_path)
atomic_write_bytes(expected_path, b"PASS\n")
binding = {"schema": "qwen-f32-alu-families-compile-v3-compile-final-binding-v1",
           "task_id": "qwen-f32-alu-families-compile-v3", "receipt_sha256": receipt_sha,
           "receipt_sidecar_sha256": sha256_bytes(sidecar), "bound_artifacts_sha256": manifest_sha,
           "build_artifact_manifest_sha256": receipt["build_artifact_manifest_sha256"],
           "linked_binary_sha256": receipt["linked_binary_sha256"],
           "expected_final_status_sha256": sha256_bytes(b"PASS\n"),
           "actual_status_path": status_path.relative_to(root).as_posix(),
           "full_revalidation_before_and_after_status": True,
           "late_failure_must_overwrite_status": True,
           "pass_marker_is_final_successful_action": True}
atomic_write_json(binding_path, binding)
_, binding_sha, _ = read_json_same_bytes(binding_path)
print(receipt_sha, manifest_sha, binding_sha, receipt["linked_binary_sha256"])
PY
}

late_revalidate_compile() {
    local phase="$1"
    local receipt_sha="$2"
    local manifest_sha="$3"
    local binding_sha="$4"
    local binary_sha="$5"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$phase" "$COMPILE_STATUS" \
        "$COMPILE_RECEIPT" "$COMPILE_RECEIPT_SIDECAR" "$COMPILE_MANIFEST" \
        "$COMPILE_EXPECTED_STATUS" "$COMPILE_BINDING" "$BUILD_ARTIFACT_MANIFEST" \
        "$receipt_sha" "$manifest_sha" "$binding_sha" "$binary_sha" <<'PY'
import json
import os
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import read_bytes_stable, read_json_same_bytes, revalidate_bound_artifacts, sha256_bytes
root = pathlib.Path(sys.argv[1]).resolve(strict=True)
build_root = pathlib.Path(sys.argv[3]).resolve(strict=True)
phase = sys.argv[4]
status_path = pathlib.Path(sys.argv[5])
receipt_path, sidecar_path, manifest_path = map(pathlib.Path, sys.argv[6:9])
expected_path, binding_path, build_manifest_path = map(pathlib.Path, sys.argv[9:12])
expected_receipt_sha, expected_manifest_sha, expected_binding_sha, expected_binary_sha = sys.argv[12:16]
receipt, receipt_sha, _ = read_json_same_bytes(receipt_path)
manifest, manifest_sha, _ = read_json_same_bytes(manifest_path)
binding, binding_sha, _ = read_json_same_bytes(binding_path)
build_manifest, build_manifest_sha, _ = read_json_same_bytes(build_manifest_path)
if (receipt_sha != expected_receipt_sha or manifest_sha != expected_manifest_sha or
        binding_sha != expected_binding_sha or receipt.get("linked_binary_sha256") != expected_binary_sha or
        binding.get("linked_binary_sha256") != expected_binary_sha or
        read_bytes_stable(sidecar_path) != f"{receipt_sha}  {receipt_path.name}\n".encode()):
    raise SystemExit("compile final document identity drift")
revalidate_bound_artifacts(root, manifest["artifacts"])
if sha256_bytes(read_bytes_stable(root / pathlib.Path(build_manifest["linked_binary"]).relative_to(root))) != expected_binary_sha:
    raise SystemExit("linked binary byte drift")

def capture(path):
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode):
        target = os.readlink(path); resolved = path.resolve(strict=True); data = read_bytes_stable(resolved)
        return {"type": "symlink", "link_target": target, "link_sha256": sha256_bytes(target.encode()),
                "resolved_path": str(resolved), "resolved_sha256": sha256_bytes(data),
                "resolved_size_bytes": len(data)}
    data = read_bytes_stable(path)
    return {"type": "regular", "sha256": sha256_bytes(data), "size_bytes": len(data)}

current = {}
for path in sorted(build_root.rglob("*")):
    if path.is_dir() and not path.is_symlink():
        continue
    current[path.relative_to(root).as_posix()] = capture(path)
if current != build_manifest["artifacts"]:
    raise SystemExit("late build artifact membership/byte drift")
actual_status = read_bytes_stable(status_path)
expected_status = read_bytes_stable(expected_path)
if phase == "before-status":
    if actual_status != b"RUNNING\n":
        raise SystemExit("compile PASS visible before evidence binding")
elif phase == "after-status":
    if actual_status != expected_status or expected_status != b"PASS\n":
        raise SystemExit("compile final PASS status mismatch")
else:
    raise SystemExit("unknown compile revalidation phase")
print(sha256_bytes(actual_status))
PY
}

publish_compile_marker() {
    local receipt_sha="$1"
    local manifest_sha="$2"
    local binding_sha="$3"
    local binary_sha="$4"
    local object_count depfile_count
    object_count=$(python3 - "$OBJECT_DEPFILE_AUDIT" <<'PY'
import json, pathlib, sys
print(json.loads(pathlib.Path(sys.argv[1]).read_text())["object_count"])
PY
)
    depfile_count=$(python3 - "$OBJECT_DEPFILE_AUDIT" <<'PY'
import json, pathlib, sys
print(json.loads(pathlib.Path(sys.argv[1]).read_text())["depfile_count"])
PY
)
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V3][COMPILE-PASS-CANDIDATE] build_count=1 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 wave_trace_coverage_files=0 actual_configured_argv=1 cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 compile_membership=21+1+1 objects=$object_count depfiles=$depfile_count objects_depfiles=exact warning_census=25-exact warning_expected_sha256=$WARNING_EXPECTED_SHA256 linked_binary_sha256=$binary_sha verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha"
}

run_collect() {
    [[ -d "$LOG_ROOT" && ! -L "$LOG_ROOT" ]] || fail "preflight log root missing/aliased"
    [[ -d "$COMPILER_ROOT" && ! -L "$COMPILER_ROOT" ]] || fail "preflight compiler root missing/aliased"
    path_absent "$BUILD_ROOT" || fail "fresh build root already exists=$BUILD_ROOT"
    path_absent "$COMPILE_STATUS" || fail "compile status already exists"
    path_absent "$COLLECT_BUILD_COUNT" || fail "collect build count already exists"
    path_absent "$COLLECT_ACTION_LEDGER" || fail "collect action ledger already exists"

    task_run_status_init "$COMPILE_STATUS"
    STATUS_INITIALIZED=1
    install_runner_traps
    task_run_status_stage "collect-preflight-binding"
    verify_preflight_for_collect
    resolve_tools
    snapshot_inputs "$COLLECT_SNAPSHOT_PRE"

    task_run_status_stage "collect-fresh-build-root"
    mkdir -m 700 -- "$BUILD_ROOT"
    atomic_text "$COLLECT_BUILD_COUNT" $'1\n'
    initialize_collect_ledger

    local configure_command=(
        "$CMAKE_EXE" -S "$CMAKE_SOURCE_DIR" -B "$CMAKE_BUILD_ROOT"
        -G "Unix Makefiles"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DCMAKE_VERBOSE_MAKEFILE=ON
        "-DCMAKE_CXX_COMPILER=$CXX_EXE"
        "-DCMAKE_AR=$AR_EXE"
        "-DCMAKE_RANLIB=$RANLIB_EXE"
        "-DCMAKE_MAKE_PROGRAM=$MAKE_EXE"
        "-DVERILATOR_EXECUTABLE=$VERILATOR_EXE"
        "-DNPU_VERILATED_MDIR=$VERILATED_ROOT"
        -DNPU_VERILATOR_JOBS=1
        "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG"
    )
    local build_command=(
        "$CMAKE_EXE" --build "$CMAKE_BUILD_ROOT" --config Release
        --target all --parallel 1 --verbose
    )

    # COLLECT_LIFECYCLE_BEGIN
    task_run_status_stage "collect-cmake-configure"
    run_collect_action "cmake-configure" "$LOG_ROOT/cmake-configure.log" \
        "$LOG_ROOT/cmake-configure.argv.json" "$LOG_ROOT/cmake-configure.rc" \
        "${configure_command[@]}"
    task_run_status_stage "collect-cmake-build"
    run_collect_action "cmake-build" "$LOG_ROOT/cmake-build.log" \
        "$LOG_ROOT/cmake-build.argv.json" "$LOG_ROOT/cmake-build.rc" \
        "${build_command[@]}"
    # COLLECT_LIFECYCLE_END

    task_run_status_stage "collect-build-evidence-audit"
    audit_collect_evidence
    [[ "$(<"$COLLECT_BUILD_COUNT")" == "1" ]] || fail "collect build count mismatch"

    task_run_status_stage "collect-source-post-snapshot"
    snapshot_inputs "$COLLECT_SNAPSHOT_POST"
    [[ "$(file_sha "$COLLECT_SNAPSHOT_PRE")" == "$(file_sha "$COLLECT_SNAPSHOT_POST")" ]] ||
        fail "collect source/tool/DSO post-build drift"
    write_process_audit "collect-final" "$COLLECT_PROCESS_AUDIT"
    snapshot_inputs "$COLLECT_SNAPSHOT_PRESTATUS"
    [[ "$(file_sha "$COLLECT_SNAPSHOT_PRE")" == "$(file_sha "$COLLECT_SNAPSHOT_PRESTATUS")" ]] ||
        fail "collect source/tool/DSO prestatus drift"

    task_run_status_stage "collect-receipt-binding"
    local seal_result receipt_sha manifest_sha binding_sha binary_sha
    seal_result=$(seal_compile)
    read -r receipt_sha manifest_sha binding_sha binary_sha <<<"$seal_result"
    for value in "$receipt_sha" "$manifest_sha" "$binding_sha" "$binary_sha"; do
        [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "invalid compile seal hash=$value"
    done

    task_run_status_stage "collect-late-revalidation-before-status"
    late_revalidate_compile before-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$binary_sha" >/dev/null
    task_run_status_stage "collect-status-publication"
    task_run_status_mark_evidence_complete
    task_run_status_finalize 0 0
    task_run_status_stage "collect-late-revalidation-after-status"
    late_revalidate_compile after-status "$receipt_sha" "$manifest_sha" "$binding_sha" "$binary_sha" >/dev/null
    task_run_status_stage "collect-single-terminal-marker"
    publish_compile_marker "$receipt_sha" "$manifest_sha" "$binding_sha" "$binary_sha"
}

if [[ $# -ne 1 ]] ||
   [[ "$1" != "--preflight" && "$1" != "--collect" ]]; then
    printf '%s\n' "usage: bash $RUNNER_REL --preflight|--collect" >&2
    exit 2
fi

if [[ "$MODE" == "--preflight" ]]; then
    run_preflight
else
    run_collect
fi
