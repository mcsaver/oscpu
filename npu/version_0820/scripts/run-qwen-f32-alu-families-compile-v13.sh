#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families compile-v13：fresh O3/no-assert/no-trace compile-only
# provenance collector。--preflight 必须保持 build-free；--collect 只能在后续显式
# continuation 下执行，且永远不运行生成的 model、backend binary 或 Qwen workload。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-compile-v13"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v13.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
STAGING_ROOT="$COMPILER_ROOT/staging"
SEALED_ROOT="$COMPILER_ROOT/sealed"
WORK_ROOT="$COMPILER_ROOT/work"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v13.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v13-material.md"
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

# compile-v12 是不可变的成功 configure/build + post-build order-oracle 假拒绝。
# v13 分别冻结 S row 的字典序与唯一 C row 的 21-source CMake 声明顺序。
COMPILE_V12_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v12.json"
COMPILE_V12_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v12-material.md"
COMPILE_V12_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v12.sh"
COMPILE_V12_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v12"
COMPILE_V12_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v12"
COMPILE_V12_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v12"
COMPILE_V12_VERFILES="$COMPILE_V12_BUILD_ROOT/verilated/VTensorNpuCoprocessor__verFiles.dat"

# compile-v11 是不可变的 evidence classifier 反例：它正确冻结了 compile-v10
# 的 61/64 字符串，但用首差位置手写了错误 insertion `e6e`。v12 必须从
# 最长公共前/后缀推导两侧 middle slice；该轮未发布 audit、未 collect/build。
COMPILE_V11_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v11.json"
COMPILE_V11_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v11-material.md"
COMPILE_V11_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v11.sh"
COMPILE_V11_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v11"
COMPILE_V11_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v11"
COMPILE_V11_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v11"

# compile-v10 是不可变的 Python evidence admission 反例：live compile-v8
# count bytes 正确，但 fixed 字典中的 expected SHA 字面量仅 61 字符。
# 该轮未进入 V8 structure/7+7 mutation，也没有 collect 或外部 build action。
COMPILE_V10_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v10.json"
COMPILE_V10_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v10-material.md"
COMPILE_V10_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v10.sh"
COMPILE_V10_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v10"
COMPILE_V10_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v10"
COMPILE_V10_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v10"

# compile-v9 是不可变的 shell admission 反例：同一 compile-v8 count 文件的
# 当前 bytes/hash 与 expected 常量相等，但早期 shell require_exact_hash 仍误拒绝；
# 该轮未进入结构/mutation audit，也没有 collect 或外部 build action。
COMPILE_V9_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v9.json"
COMPILE_V9_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v9-material.md"
COMPILE_V9_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v9.sh"
COMPILE_V9_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v9"
COMPILE_V9_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v9"
COMPILE_V9_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v9"

# compile-v8 是不可变的 doc-evidence parser 反例：whole-file SHA、live
# overflow admission 和前置历史闭包均未漂移，但自然语言整句 cardinality
# 在发布 root-fix audit 前误拒绝；该轮没有 collect 或外部 build action。
COMPILE_V8_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v8.json"
COMPILE_V8_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v8-material.md"
COMPILE_V8_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v8.sh"
COMPILE_V8_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v8"
COMPILE_V8_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v8"
COMPILE_V8_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v8"

# compile-v7 是不可变的真实 build 反例：configure/build 均 rc0，但 26 行
# actual warning 比冻结 25 行多出 adapter terminal-stride upper half 的唯一
# UNUSEDSIGNAL；生成 binary 未执行。
COMPILE_V7_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v7.json"
COMPILE_V7_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v7-material.md"
COMPILE_V7_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v7.sh"
COMPILE_V7_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v7"
COMPILE_V7_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v7"
COMPILE_V7_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v7"

# compile-v6 是不可变的 meta-evidence parser 反例：whole-runner identity 正确，
# 但跨 Python heredoc 的 Bash function regex 在列首 `}` 处提前截断。
COMPILE_V6_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v6.json"
COMPILE_V6_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v6-material.md"
COMPILE_V6_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v6.sh"
COMPILE_V6_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v6"
COMPILE_V6_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v6"
COMPILE_V6_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v6"

# compile-v5 是不可变 admission 反例：它把 compile-v4 的普通文件
# staging/preflight-build.count 与 sealed/staging/work 目录 census 混为一类。
COMPILE_V5_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v5.json"
COMPILE_V5_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v5-material.md"
COMPILE_V5_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v5.sh"
COMPILE_V5_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v5"
COMPILE_V5_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v5"
COMPILE_V5_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v5"

# compile-v4 是需要独立冻结目录与普通文件集合的不可变 predecessor。
COMPILE_V4_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v4.json"
COMPILE_V4_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v4-material.md"
COMPILE_V4_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v4.sh"
COMPILE_V4_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v4"
COMPILE_V4_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v4"
COMPILE_V4_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v4"

# compile-v3 是不可变反例：其唯一 collect 在真正 CMake 子进程前因复写 fresh ledger 失败。
COMPILE_V3_CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v3.json"
COMPILE_V3_MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v3-material.md"
COMPILE_V3_RUNNER="$NPU_ROOT/scripts/run-qwen-f32-alu-families-compile-v3.sh"
COMPILE_V3_LOG_ROOT="$NPU_ROOT/tmp/logs/qwen-f32-alu-families-compile-v3"
COMPILE_V3_COMPILER_ROOT="$NPU_ROOT/tmp/compiler/qwen-f32-alu-families-compile-v3"
COMPILE_V3_BUILD_ROOT="$NPU_ROOT/tmp/build/qwen-f32-alu-families-compile-v3"

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
COMPILE_V12_ORDER_AUDIT="$STAGING_ROOT/compile-v12-order-audit.json"
COMPILE_V11_FAILURE_AUDIT="$STAGING_ROOT/compile-v11-failure-audit.json"
COMPILE_V10_FAILURE_AUDIT="$STAGING_ROOT/compile-v10-failure-audit.json"
COMPILE_V9_FAILURE_AUDIT="$STAGING_ROOT/compile-v9-failure-audit.json"
COMPILE_V8_FAILURE_AUDIT="$STAGING_ROOT/compile-v8-failure-audit.json"
COMPILE_V7_ROOT_FIX_AUDIT="$STAGING_ROOT/compile-v7-root-fix-audit.json"
COMPILE_V6_FAILURE_AUDIT="$STAGING_ROOT/compile-v6-failure-audit.json"
COMPILE_V4_CLASSIFIER_AUDIT="$STAGING_ROOT/compile-v4-classifier-audit.json"
COMPILE_V3_FAILURE_AUDIT="$STAGING_ROOT/compile-v3-failure-audit.json"
EXPECTED_WARNING_COPY="$STAGING_ROOT/expected-warning-census.tsv"
WARNING_ORACLE_AUDIT="$STAGING_ROOT/warning-oracle-audit.json"
COLLECT_POLICY_AUDIT="$STAGING_ROOT/collect-policy-audit.json"
LEDGER_REGRESSION_ROOT="$STAGING_ROOT/ledger-regression"
LEDGER_REGRESSION_OLD="$LEDGER_REGRESSION_ROOT/mutable-ledger.json"
LEDGER_REGRESSION_0="$LEDGER_REGRESSION_ROOT/collect-action-ledger.0.json"
LEDGER_REGRESSION_1="$LEDGER_REGRESSION_ROOT/collect-action-ledger.1.json"
LEDGER_REGRESSION_2="$LEDGER_REGRESSION_ROOT/collect-action-ledger.2.json"
LEDGER_REGRESSION_AUDIT="$STAGING_ROOT/collect-ledger-regression.json"
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
# 每个 admission 只发布一个 fresh snapshot；任何快照都没有第二 writer。
COLLECT_ACTION_LEDGER_0="$COMPILER_ROOT/collect-action-ledger.0.json"
COLLECT_ACTION_LEDGER_1="$COMPILER_ROOT/collect-action-ledger.1.json"
COLLECT_ACTION_LEDGER_2="$COMPILER_ROOT/collect-action-ledger.2.json"
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

CONTRACT_SHA256="80e3f66d119949b2142b2a3f5f3ec56eea656bac27c6d2c4734f2016eee841ed"
MATERIAL_SHA256="797e46c6f34ae05bb52d2f62662e142d3c2440290377af012cf62a6dbc43b005"
OWNER_CONTRACT_SHA256="4c31de3670df477e8b8a08d7c5d7873d43c73a3748b20cb96a18af43283555a4"
ADAPTER_SHA256="11e75f704c1eb2894c1aa97a6ea23bada931cc752eff8953b54bebdee83166e5"
V8_STRUCTURE_ID_SHA256="b9d4366c26b281bea20b8f3c459a4128e150be157afdbb7e1857580f7d81b0c3"
COMPILE_V12_CONTRACT_SHA256="edb102614531a31f57395f54fb8b2ddfdda36d832b49ec3ad9c9ae4f8aecc930"
COMPILE_V12_MATERIAL_SHA256="8c16d6bdb96789650706d4ecc1f7815a55efcb11550f4dcba8edc7f7cd32b3eb"
COMPILE_V12_RUNNER_SHA256="a5eee002ccbecb1855b75d0d28d4f780c4b8e1588fa5ae33c0773c165ea76bc5"
COMPILE_V12_PREFLIGHT_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
COMPILE_V12_PREFLIGHT_RECEIPT_SHA256="ab07f5a6ae8c379487e97412a6344ee0c7d780e517f310ca5a2c2ece37087f8a"
COMPILE_V12_PREFLIGHT_MANIFEST_SHA256="5d8d328dac105a0adfd4946324d943ba53e20f29ef31747b4378378f4d5e60e7"
COMPILE_V12_PREFLIGHT_BINDING_SHA256="2e66e61370ad360f5402596fd8cc00e58c3a42cecb5021b1b49ea1958ad77a39"
COMPILE_V12_PREFLIGHT_SNAPSHOT_SHA256="3c5fec80469d07baf861f1a49f95cb9c36f758b548722dc30b8904ccfee90e20"
COMPILE_V12_COMPILE_STATUS_SHA256="aa335af767b126c3151f774b24dbb74fb99f1127edc1ccfba9dd7910baad9c3d"
COMPILE_V12_COMMAND_RC_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V12_BUILD_COUNT_SHA256="4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865"
COMPILE_V12_CONFIGURE_LOG_SHA256="931cf6be27894eec51add7c53dfed4238c5048d1f58e4d45d6df5fcf0ed9e403"
COMPILE_V12_BUILD_LOG_SHA256="7d6432e41e9a4bb84892b586842143499341ee02896a952880b206928caa4417"
COMPILE_V12_CONFIGURE_ARGV_SHA256="e36ae0aba3515f9a3ed4859a36f42a48e8c137619a4e2c685c44f4f54fda9383"
COMPILE_V12_BUILD_ARGV_SHA256="36f5bb01ae574405aef7cd1bf02dc788bca71b394be45635497ca8adff8f0f7e"
COMPILE_V12_LEDGER_0_SHA256="4e02ad7fc9b529ad5cfe2af54786eea6b50a110914b76b055161f55709af99ab"
COMPILE_V12_LEDGER_1_SHA256="5730de719058eb8d3fc01a9b6e196feb93cc21664d47563e6f3d747fd340ea8a"
COMPILE_V12_LEDGER_2_SHA256="c699bdf01deb5cd17b29e0d7d9da1d5b44c789fc0953ebb4959592f2eff02abd"
COMPILE_V12_CMAKE_IDENTITY_SHA256="0941a4c73e332cb391f43c64a77a37fe50ec9589a968b832ff04bac770b6e96c"
COMPILE_V12_WARNING_SHA256="832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c"
COMPILE_V12_DIAGNOSTIC_SHA256="589cfe8324cdcea4727f3a9967c35c40d66cedba79033402ba70af74ffdc83b2"
COMPILE_V12_VERFILES_SHA256="1716cdaf24b8de17b842b61ff817cc7cd93e4cde6a45105b728612c4cb8acfd5"
COMPILE_V12_ARCHIVE_SHA256="178afd6e125bad913a9b4fbf0c84cf076b5c434967f19b252637851e57ba2b33"
COMPILE_V12_BINARY_SHA256="b6aa49d366ee4e0c36d250c01c470b51e5bcf1bd6fd714296458a1f47b8bf59b"
COMPILE_V12_DSO_SHA256="4eed2e1e905b9fc66b7b38eb059986746dfa59d6d58a109c5667191eea03db88"
COMPILE_V11_CONTRACT_SHA256="9a0d01a4dd4fb6c3e86f74c99ae46353ba1790de528ac16a0bde151e31723845"
COMPILE_V11_MATERIAL_SHA256="273ab3965e29c80fdbef88c7bf8cc6d80f93e87608f6085e2f78a5e78656953e"
COMPILE_V11_RUNNER_SHA256="6428042d5c33bbf6323fd720a4e9fb741b07c2c8e5040bce495d9fef575d8675"
COMPILE_V11_PREFLIGHT_STATUS_SHA256="0868e62dc3bd073d3af46c92d4071ac91858e52fe3854d099d6acb7f4582a1d8"
COMPILE_V11_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V11_PREFLIGHT_SNAPSHOT_SHA256="4219908d70287527105209788a80ed6ccc8da36f52b865fc425b8714308755b0"
COMPILE_V10_CONTRACT_SHA256="3211ddf78b637e442465e573293c2cfca09ab2c42be818a7013aee391ebd64a1"
COMPILE_V10_MATERIAL_SHA256="83134968933c87dc9d5770a8afa12ce2d1f28c1744af26168bec54b8909f9bcd"
COMPILE_V10_RUNNER_SHA256="498913a752f0c7c2c7da9292cb353f47254a486459b5e7053da1665d8b602d47"
COMPILE_V10_PREFLIGHT_STATUS_SHA256="9b01b2d6e6d27adecfdd3563b57b4ac02bd0fa7ce5492fe87f0f79fc5bb0e873"
COMPILE_V10_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V10_PREFLIGHT_SNAPSHOT_SHA256="2c5c72621c6fd4df084bf5e90245926721d59d5e5c0fc39508003e98ec5c2a5a"
COMPILE_V10_COMPILE_V9_AUDIT_SHA256="85cb9470c5aabdde4d5b997c7091b1cb5f989a7ed381708570e6c96ebfc1f474"
COMPILE_V9_CONTRACT_SHA256="aa902bb23dd3de23720b70b13af17332465cf0fc88300e3daeeb6d853b58f1c5"
COMPILE_V9_MATERIAL_SHA256="56058ee96af83adecbb6c5a7f4d9e69cda5389ab0d420773e6d54914a5288853"
COMPILE_V9_RUNNER_SHA256="d9648f9de7227e2020e7ab67622cac4a26cd6351ddd8c82f783b7a47cbf85bc4"
COMPILE_V9_PREFLIGHT_STATUS_SHA256="e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51"
COMPILE_V9_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V8_CONTRACT_SHA256="bc2b3378affd5c85d42d37968e74db6494822763a5c79d5063f8ec2deecf8de3"
COMPILE_V8_MATERIAL_SHA256="80c3d1c1b5d8e849118435d8b60d92c4e990d883f1212b0c9f62494d75b07c6c"
COMPILE_V8_RUNNER_SHA256="2ecdc8c905dc28697f6ef067ed227fe42ad5ab49567a201c5cbb7f514d642fef"
COMPILE_V8_PREFLIGHT_STATUS_SHA256="79184a20fea5d869495b2837d43f99b0334d69f785c14ae678b15180dca4d789"
COMPILE_V8_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V8_PREFLIGHT_SNAPSHOT_SHA256="e8eac94ac0810b896b7d27af7e6a6d53971e038fece3fb11c6d27ec1f8df41d6"
COMPILE_V7_CONTRACT_SHA256="3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9"
COMPILE_V7_MATERIAL_SHA256="5f11f4d2adfa8f05d8ed0fe94cc112f2a838e8dac05d78a6826bfb31a21fe9d0"
COMPILE_V7_RUNNER_SHA256="b525f6a0a60866593380a27d3f0103c72edd447e8b9faf736a65e88463225405"
COMPILE_V7_PREFLIGHT_RECEIPT_SHA256="952979818b58fee40f5a37fb2b802fae3e1985cfe3fdcf68d8042d094b7a6c10"
COMPILE_V7_PREFLIGHT_MANIFEST_SHA256="b9dfca7c0c51392870b25b41b0bcb782d04acbc5d1e8cae414ceceb5b7673af1"
COMPILE_V7_PREFLIGHT_BINDING_SHA256="76ac9fcf37a8e513dd68e6b23c55bf2ad2a269bf4a4b3c491637cdd0f8d9f695"
COMPILE_V7_PREFLIGHT_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
COMPILE_V7_PREFLIGHT_SNAPSHOT_SHA256="6f80fe9f25fa07a453ad4f00d91c248777dc6f6a662c0a99328a7e9e538db982"
COMPILE_V7_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V7_COMPILE_STATUS_SHA256="aa335af767b126c3151f774b24dbb74fb99f1127edc1ccfba9dd7910baad9c3d"
COMPILE_V7_CONFIGURE_ARGV_SHA256="6f839a530c4acbb70009391d9e625c0a0d34f0b5a7e099049a1f01dc5ac40ab5"
COMPILE_V7_BUILD_ARGV_SHA256="d6140dfc79145c29540c2bb09d6f869705dfdb4afe07a87e3c1eca95224d5e00"
COMPILE_V7_COMMAND_RC_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V7_BUILD_LOG_SHA256="b1fc1d39e6e7b2dda13f68677978ef5f51ee1ab0787add97a6e24ac87a593708"
COMPILE_V7_LEDGER_0_SHA256="08ffb3f625cd2d5ba4ef74f718e755276bd5dcf965a3ad2c1ccdde3b22a38194"
COMPILE_V7_LEDGER_1_SHA256="37208f0e5ad6584421672cbc6a9b2d5acef89a0936c6b52fde57c9a629b3172a"
COMPILE_V7_LEDGER_2_SHA256="02535cc21816318d4bf899f490de0300a12ed4df36d4f8caaa936709d0b77322"
COMPILE_V7_BUILD_COUNT_SHA256="4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865"
COMPILE_V7_COLLECT_SNAPSHOT_SHA256="6f80fe9f25fa07a453ad4f00d91c248777dc6f6a662c0a99328a7e9e538db982"
COMPILE_V7_OWNER_CONTRACT_SHA256="1f1cd0a4971826f2ddcf939bd3f796c5986088bb66eac107e4937d396e14e376"
COMPILE_V7_ADAPTER_SHA256="3de215650ff39f6649b21e37864cfce102ba6de824cccdbb8be2b124b6246cff"
COMPILE_V6_CONTRACT_SHA256="8737f230d7e0716717c9b4600e73c4dfe901bdce8c51b01e6d05fd1230ce09c3"
COMPILE_V6_MATERIAL_SHA256="63a00b5f172c964362a08d60b4fb098a30287e5a6a2267d95c93837d0e6005c3"
COMPILE_V6_RUNNER_SHA256="a42e48ca6f05037c06d54e000953306ab959a57d8945ab3f63ece8ca612c830a"
COMPILE_V6_PREFLIGHT_STATUS_SHA256="be169b5dd1b5fd8f6f617470b21b9c4782cc49c69db6b6d2e9c83e707a76eeb5"
COMPILE_V6_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V6_PREFLIGHT_SNAPSHOT_SHA256="ca26791ab50b19bc6d1bda8d0422f82a6431fd89d6afcd5872fc6336d81f3308"
COMPILE_V5_CONTRACT_SHA256="4dd365fc4858f9ecb0838a3f978321283ba378a2cb481f3715f6aaa2eb1b00f7"
COMPILE_V5_MATERIAL_SHA256="a47349d1bedf3c26f9fffad84a1eef2084b1ef019abb3663c75aa70235410f31"
COMPILE_V5_RUNNER_SHA256="c4c84db3e17d1bfa29fd31448b0d4f7df0c2d159ef88ea5b701a76f7b1de816c"
COMPILE_V5_PREFLIGHT_STATUS_SHA256="e5b67181496437a35668c3bd1025b3e9e21e939d2f71ca29d5a03858bb8c5046"
COMPILE_V5_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V5_PREFLIGHT_SNAPSHOT_SHA256="a0cbf76a8a5d392e436ae3852fc95cbe5193a93afdb04e742ad989cc846254cf"
COMPILE_V4_CONTRACT_SHA256="bafa967a2f92be4a412fada106ee5b3fb7343ccf5d3ef24953c4bb87c6584a62"
COMPILE_V4_MATERIAL_SHA256="b778196d1e3d7a22164f164bd9a6a278640bfd87b9c20d38ce7ea3c9ee0b898c"
COMPILE_V4_RUNNER_SHA256="83a859278c4a4976e8704707d331e424695b8f1c894be30c3b34fe453f42cbc7"
COMPILE_V4_PREFLIGHT_STATUS_SHA256="e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51"
COMPILE_V4_PREFLIGHT_BUILD_COUNT_SHA256="9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
COMPILE_V3_CONTRACT_SHA256="581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6"
COMPILE_V3_MATERIAL_SHA256="6ff06cd9ca76a879735d7a3a1fe7eceb0765afb678cf73638f3d295e11036da2"
COMPILE_V3_RUNNER_SHA256="537bdef17dd05e8b572b889c2694943385b442ba55ce3422d562284808531c74"
COMPILE_V3_PREFLIGHT_RECEIPT_SHA256="6b98f0fcbccd47d461225672a7e578c9f6f89ced8e5155412e3f6717a6bff5d6"
COMPILE_V3_PREFLIGHT_MANIFEST_SHA256="ddac7e7d0dc47e566d6939bd1a8281da1327c11786e3e154e0a3b9120d2665d7"
COMPILE_V3_PREFLIGHT_BINDING_SHA256="c3940df9a218d3ac1b93b82467fa7f9411c7863d6cc17f35bde87b0cc03561d3"
COMPILE_V3_PREFLIGHT_SNAPSHOT_SHA256="022195ce62b7f4044437030bac025d9443dd312c5bd63c431c5cd31829930f12"
COMPILE_V3_PREFLIGHT_STATUS_SHA256="c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431"
COMPILE_V3_COMPILE_STATUS_SHA256="2856e07c603ed85e496181f60f17540d1f3cf89687752ff5ea50dc7fcf26e663"
COMPILE_V3_CONFIGURE_ARGV_SHA256="d2079ae5d3a9fa818efd87e7ea7c7b95b47a6e79d4afc14db7536d7cea5e4516"
COMPILE_V3_COLLECT_SNAPSHOT_SHA256="022195ce62b7f4044437030bac025d9443dd312c5bd63c431c5cd31829930f12"
COMPILE_V3_BUILD_COUNT_SHA256="4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865"
COMPILE_V3_INITIAL_LEDGER_SHA256="d1fffeac1a381827fd6aefe4c54752b0226ba4f3cbf8deea85e3f986db09c59c"
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
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v13.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v13-material.md
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
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v13.sh
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v12.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v12-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v12.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/preflight.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/preflight.receipt.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/preflight.bound-artifacts.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/preflight.final-binding.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/compile.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-configure.rc
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-build.rc
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-configure.log
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-build.log
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-configure.argv.json
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12/cmake-build.argv.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/collect-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/collect-action-ledger.0.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/collect-action-ledger.1.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/collect-action-ledger.2.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/staging/cmake-source-identity.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/actual-warning-census.tsv
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/build-diagnostic-audit.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12/sealed/frozen-inputs.3c5fec80469d07baf861f1a49f95cb9c36f758b548722dc30b8904ccfee90e20.json
    npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v12/verilated/VTensorNpuCoprocessor__verFiles.dat
    npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v12/verilated/VTensorNpuCoprocessor__ALL.a
    npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v12/cmake/test-npu-backend
    npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v12/cmake/libggml-npu.so
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v11.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v11-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v11.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v11/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v11/staging/preflight-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v11/staging/frozen-inputs.pre.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v10.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v10-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v10.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v10/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v10/staging/preflight-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v10/staging/frozen-inputs.pre.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v10/staging/compile-v9-failure-audit.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v9.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v9-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v9.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v9/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v9/staging/preflight-build.count
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v8.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v8-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v8.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v8/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v8/staging/preflight-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v8/staging/frozen-inputs.pre.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v7.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v7-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v7.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v7/preflight.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v7/compile.status
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v7/cmake-build.log
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v7/collect-action-ledger.0.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v7/collect-action-ledger.1.json
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v7/collect-action-ledger.2.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v6.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v6-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v6.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v6/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v6/staging/preflight-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v6/staging/frozen-inputs.pre.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v5.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v5-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v5.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v5/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v5/staging/preflight-build.count
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v5/staging/frozen-inputs.pre.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v4.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v4-material.md
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v4.sh
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v4/preflight.status
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v4/staging/preflight-build.count
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
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v3
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v3
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v4
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v4
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v5
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v5
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v6
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v6
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v11
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v11
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v10
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v10
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v9
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v9
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v8
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v8
    npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v7
    npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v7
    npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v7
    npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v4
    npu/version_0820/tmp/tools/cmake-3.31.12
)

export PYTHONDONTWRITEBYTECODE=1
export LC_ALL=C

STATUS_HELPER_OBSERVED=$(sha256sum "$STATUS_HELPER")
[[ "${STATUS_HELPER_OBSERVED%% *}" == "$STATUS_HELPER_SHA256" ]] || {
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V13][FAIL] status helper hash mismatch before source" >&2
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
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V13][FAIL] $*" >&2
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
    "schema": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
    "schema": "qwen-f32-alu-families-compile-v13-v11-closure-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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

audit_compile_v12_order() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V12_ORDER_AUDIT" \
        "$COMPILE_V12_VERFILES" "${RTL_SOURCES_REL[@]}" <<'PY'
import hashlib
import json
import pathlib
import shlex
import sys
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable, read_json_same_bytes, sha256_bytes

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
output = pathlib.Path(sys.argv[3])
verfiles = pathlib.Path(sys.argv[4])
design = [str((root / value).resolve(strict=True)) for value in sys.argv[5:]]
log_root = root / "npu/version_0820/tmp/logs/qwen-f32-alu-families-compile-v12"
compiler_root = root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v12"
build_root = root / "npu/version_0820/tmp/build/qwen-f32-alu-families-compile-v12"
verilated_root = build_root / "verilated"
control = str(pathlib.Path("/usr/share/verilator/include/verilated_std.sv").resolve(strict=True))
tool = str(pathlib.Path("/usr/bin/verilator_bin").resolve(strict=True))
expected_s = sorted([*design, control, tool])
header = "# DESCRIPTION: Verilator output: Timestamp data for --skip-identical.  Delete at will."
prefix = [
    "--cc", "-O3", "-Wall", "-Wno-fatal", "--no-assert", "--no-trace",
    "-I" + str(root / "npu/version_0820/rtl"),
    "--Mdir", str(verilated_root), "--top-module", "TensorNpuCoprocessor",
    "-CFLAGS", "-O3", "-DNDEBUG", "-march=native", "-fPIC",
]

def parse(data):
    text = data.decode("utf-8")
    if "\0" in text:
        raise ValueError("NUL rejected")
    lines = text.splitlines()
    if not lines or lines[0] != header:
        raise ValueError("description header mismatch")
    c_payloads = []
    s_rows = []
    comment_count = 0
    for index, line in enumerate(lines):
        if line.startswith("#"):
            comment_count += 1
            if index != 0 or line != header:
                raise ValueError("comment/decoy row rejected")
            continue
        if not line:
            raise ValueError("blank row rejected")
        fields = shlex.split(line, comments=False, posix=True)
        if not fields or fields[0] not in {"C", "S", "T"}:
            raise ValueError("unknown/decoy row rejected")
        if fields[0] == "C":
            if len(fields) != 2:
                raise ValueError("C row shape mismatch")
            c_payloads.append(fields[1])
            continue
        if len(fields) != 8 or any(not value.isdigit() for value in fields[1:7]):
            raise ValueError(fields[0] + " row shape mismatch")
        path = pathlib.Path(fields[-1])
        if not path.is_absolute() or str(path.resolve(strict=True)) != fields[-1]:
            raise ValueError(fields[0] + " row path is not canonical")
        if fields[0] == "S":
            s_rows.append(fields[-1])
        elif not path.is_relative_to(verilated_root):
            raise ValueError("T row escaped expected generated root")
    if comment_count != 1 or len(c_payloads) != 1:
        raise ValueError("description/C row cardinality mismatch")
    if len(s_rows) != 23 or len(set(s_rows)) != 23 or set(s_rows) != set(expected_s):
        raise ValueError("S row exact 21+1+1 membership mismatch")
    if s_rows != expected_s:
        raise ValueError("S row lexicographic order mismatch")
    command = shlex.split(c_payloads[0], comments=False, posix=True)
    if command != prefix + design:
        raise ValueError("C row pinned argv or 21-source CMake order mismatch")
    return {"lines": lines, "s_rows": s_rows, "c_payload": c_payloads[0], "c_argv": command}

raw = read_bytes_stable(verfiles)
parsed = parse(raw)
lines = parsed["lines"]
s_indices = [index for index, line in enumerate(lines) if shlex.split(line, comments=False, posix=True)[0] == "S"]
c_index = next(index for index, line in enumerate(lines) if shlex.split(line, comments=False, posix=True)[0] == "C")

def encoded(values):
    return ("\n".join(values) + "\n").encode("utf-8")

def rejected(values):
    try:
        parse(encoded(values))
    except (OSError, UnicodeError, ValueError):
        return True
    return False

mutations = {}
value = list(lines); del value[s_indices[0]]
mutations["missing_s_row"] = rejected(value)
extra_path = root / "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md"
value = list(lines); value.insert(s_indices[-1] + 1, f'S 0 0 0 0 0 0 "{extra_path}"')
mutations["extra_s_row"] = rejected(value)
value = list(lines); value.insert(s_indices[0], value[s_indices[0]])
mutations["duplicate_s_row"] = rejected(value)
value = list(lines); fields = shlex.split(value[s_indices[0]], comments=False, posix=True); fields[-1] = control
value[s_indices[0]] = " ".join(fields[:-1]) + " " + shlex.quote(fields[-1])
mutations["class_collision_or_substitution"] = rejected(value)
value = list(lines); value[s_indices[0]], value[s_indices[1]] = value[s_indices[1]], value[s_indices[0]]
mutations["reordered_s_rows"] = rejected(value)
value = list(lines); command = list(parsed["c_argv"]); command[len(prefix)], command[len(prefix) + 1] = command[len(prefix) + 1], command[len(prefix)]
value[c_index] = "C " + shlex.quote(shlex.join(command))
mutations["reordered_c_design_arguments"] = rejected(value)
value = list(lines); value.insert(c_index + 1, value[c_index])
mutations["duplicate_c_row"] = rejected(value)
value = list(lines); del value[c_index]
mutations["missing_c_row"] = rejected(value)
value = list(lines); value.append("# C " + shlex.quote(parsed["c_payload"]))
mutations["comment_or_decoy_text"] = rejected(value)
if set(mutations) != {
    "missing_s_row", "extra_s_row", "duplicate_s_row", "class_collision_or_substitution",
    "reordered_s_rows", "reordered_c_design_arguments", "duplicate_c_row", "missing_c_row",
    "comment_or_decoy_text",
} or not all(mutations.values()):
    raise SystemExit("S/C dual-order directed mutation unexpectedly accepted")

old_ordered_design = [value for value in parsed["s_rows"] if value in set(design)]
if old_ordered_design == design:
    raise SystemExit("old conflated S/C order oracle unexpectedly accepts raw v12")

status = read_bytes_stable(log_root / "compile.status")
if status != b"FAIL rc=1 stage=collect-build-evidence-audit evidence_complete=0 cleanup_rc=0\n":
    raise SystemExit("compile-v12 status mismatch")
if read_bytes_stable(log_root / "preflight.status") != b"PASS\n":
    raise SystemExit("compile-v12 preflight status mismatch")
for path in (log_root / "cmake-configure.rc", log_root / "cmake-build.rc"):
    if read_bytes_stable(path) != b"0\n":
        raise SystemExit("compile-v12 command rc mismatch")
if read_bytes_stable(compiler_root / "collect-build.count") != b"1\n":
    raise SystemExit("compile-v12 build count mismatch")
ledgers = [read_json_same_bytes(compiler_root / f"collect-action-ledger.{index}.json")[0] for index in range(3)]
if ([value.get("snapshot_index") for value in ledgers] != [0, 1, 2] or
        [value.get("ordered_actions") for value in ledgers] !=
        [[], ["cmake-configure"], ["cmake-configure", "cmake-build"]] or
        ledgers[2].get("counts") != {"cmake-configure": 1, "cmake-build": 1, "binary": 0,
                                    "model": 0, "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0}):
    raise SystemExit("compile-v12 append-only action ledger mismatch")
diagnostic = read_json_same_bytes(compiler_root / "build-diagnostic-audit.json")[0]
if (diagnostic.get("expected_warning_rows") != 25 or diagnostic.get("actual_warning_rows") != 25 or
        diagnostic.get("new_source_warning_count") != 0 or diagnostic.get("error_count") != 0):
    raise SystemExit("compile-v12 warning closure mismatch")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v12-order-audit-v1",
    "pass": True,
    "compile_v12": {
        "runner_sha256": "a5eee002ccbecb1855b75d0d28d4f780c4b8e1588fa5ae33c0773c165ea76bc5",
        "preflight_status": "PASS", "configure_rc": 0, "build_rc": 0, "build_count": 1,
        "compile_status": status.decode().strip(), "warning_rows": 25,
        "binary_runs": 0, "model_runs": 0, "qwen_runs": 0,
        "synthesis": 0, "sta": 0, "ppa": 0,
    },
    "verfiles": {
        "path": str(verfiles), "sha256": sha256_bytes(raw),
        "c_row_count": 1, "s_row_count": 23, "s_unique_count": 23,
        "s_membership": {"design": 21, "control": 1, "tool": 1},
        "s_rows": parsed["s_rows"], "s_rows_lexicographic": True,
        "c_design_sources": design, "c_design_order": "cmake-declaration-order",
        "c_pinned_argv": True,
    },
    "old_compile_v12_oracle": {
        "accepted": False,
        "reject_reason": "lexicographic-s-order-compared-to-cmake-c-design-order",
        "membership_was_correct": True, "s_lexicographic_was_correct": True,
        "c_design_order_was_correct": True,
    },
    "mutations_rejected": mutations,
    "mutations_rejected_count": len(mutations),
})
PY
}

audit_compile_v11_failure() {
    python3 - "$NPU_ROOT/scripts" "$COMPILE_V11_FAILURE_AUDIT" \
        "$COMPILE_V11_CONTRACT" "$COMPILE_V11_MATERIAL" "$COMPILE_V11_RUNNER" \
        "$COMPILE_V11_LOG_ROOT" "$COMPILE_V11_COMPILER_ROOT" \
        "$COMPILE_V11_BUILD_ROOT" \
        "$COMPILE_V8_COMPILER_ROOT/staging/preflight-build.count" <<'PY'
import hashlib
import json
import pathlib
import re
import stat
import sys

sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable

(
    output,
    v11_contract,
    v11_material,
    v11_runner,
    v11_log_root,
    v11_compiler_root,
    v11_build_root,
    live_v8_count,
) = map(pathlib.Path, sys.argv[2:10])
v11_status = v11_log_root / "preflight.status"
v11_count = v11_compiler_root / "staging/preflight-build.count"
v11_snapshot = v11_compiler_root / "staging/frozen-inputs.pre.json"
fixed = {
    v11_contract: "9a0d01a4dd4fb6c3e86f74c99ae46353ba1790de528ac16a0bde151e31723845",
    v11_material: "273ab3965e29c80fdbef88c7bf8cc6d80f93e87608f6085e2f78a5e78656953e",
    v11_runner: "6428042d5c33bbf6323fd720a4e9fb741b07c2c8e5040bce495d9fef575d8675",
    v11_status: "0868e62dc3bd073d3af46c92d4071ac91858e52fe3854d099d6acb7f4582a1d8",
    v11_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v11_snapshot: "4219908d70287527105209788a80ed6ccc8da36f52b865fc425b8714308755b0",
}
for path, expected in fixed.items():
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode) or not stat.S_ISREG(observed.st_mode):
        raise SystemExit("compile-v11 frozen file missing or aliased: " + str(path))
    actual = hashlib.sha256(read_bytes_stable(path)).hexdigest()
    if actual != expected:
        raise SystemExit("compile-v11 frozen byte drift path=" + str(path))

def exact_census(directory):
    observed = directory.lstat()
    if stat.S_ISLNK(observed.st_mode) or not stat.S_ISDIR(observed.st_mode):
        raise SystemExit("compile-v11 evidence root missing or aliased: " + str(directory))
    directories = []
    regular_files = []
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise SystemExit("compile-v11 evidence member is symlink: " + relative)
        if stat.S_ISDIR(mode):
            directories.append(relative)
        elif stat.S_ISREG(mode):
            regular_files.append(relative)
        else:
            raise SystemExit("compile-v11 evidence member is special: " + relative)
    return directories, regular_files

log_directories, log_files = exact_census(v11_log_root)
compiler_directories, compiler_files = exact_census(v11_compiler_root)
if (
    log_directories != []
    or log_files != ["preflight.status"]
    or compiler_directories != ["sealed", "staging", "work"]
    or compiler_files != [
        "staging/frozen-inputs.pre.json",
        "staging/preflight-build.count",
    ]
):
    raise SystemExit("compile-v11 frozen evidence census mismatch")
if v11_build_root.exists() or v11_build_root.is_symlink():
    raise SystemExit("compile-v11 build root unexpectedly exists")

expected_status = (
    b"FAIL rc=1 stage=preflight-compile-v10-failure-closure "
    b"evidence_complete=0 cleanup_rc=0\n"
)
contract_value = json.loads(read_bytes_stable(v11_contract))
snapshot_value = json.loads(read_bytes_stable(v11_snapshot))
if (
    contract_value.get("schema_version") != 2
    or contract_value.get("task_id") != "qwen-f32-alu-families-compile-v11"
    or read_bytes_stable(v11_status) != expected_status
    or read_bytes_stable(v11_count) != b"0\n"
    or snapshot_value.get("schema")
    != "qwen-f32-alu-families-compile-v11-frozen-inputs-v1"
    or snapshot_value.get("task_id") != "qwen-f32-alu-families-compile-v11"
):
    raise SystemExit("compile-v11 status/count/snapshot semantic mismatch")

runner_text = read_bytes_stable(v11_runner).decode("utf-8")
pair_matches = re.findall(
    r'^expected_malformed = "([0-9a-f]+)"\n'
    r'^expected_correct = "([0-9a-f]+)"$',
    runner_text,
    flags=re.MULTILINE,
)
manual_matches = re.findall(
    r'^    or omitted != "([0-9a-f]+)"$', runner_text, flags=re.MULTILINE
)
if len(pair_matches) != 1 or len(manual_matches) != 1:
    raise SystemExit("compile-v11 frozen SHA literals extraction cardinality mismatch")
malformed, correct = pair_matches[0]
manual_middle = manual_matches[0]
live_bytes = read_bytes_stable(live_v8_count)
if hashlib.sha256(live_bytes).hexdigest() != correct or live_bytes != b"0\n":
    raise SystemExit("compile-v11 correct SHA is not bound to live compile-v8 count bytes")

prefix_length = 0
for left, right in zip(malformed, correct):
    if left != right:
        break
    prefix_length += 1
suffix_length = 0
suffix_limit = min(len(malformed), len(correct)) - prefix_length
while (
    suffix_length < suffix_limit
    and malformed[len(malformed) - 1 - suffix_length]
    == correct[len(correct) - 1 - suffix_length]
):
    suffix_length += 1
malformed_end = len(malformed) - suffix_length if suffix_length else len(malformed)
correct_end = len(correct) - suffix_length if suffix_length else len(correct)
malformed_middle = malformed[prefix_length:malformed_end]
correct_middle = correct[prefix_length:correct_end]
common_prefix = malformed[:prefix_length]
common_suffix = malformed[malformed_end:]
if (
    type(malformed) is not str
    or type(correct) is not str
    or not malformed.isascii()
    or not correct.isascii()
    or re.fullmatch(r"[0-9a-f]+", malformed) is None
    or re.fullmatch(r"[0-9a-f]+", correct) is None
    or len(malformed) != 61
    or len(correct) != 64
    or prefix_length != 15
    or suffix_length != 46
    or malformed_middle != ""
    or manual_middle == correct_middle
    or common_prefix + malformed_middle + common_suffix != malformed
    or common_prefix + correct_middle + common_suffix != correct
):
    raise SystemExit("compile-v11 longest-common-prefix/suffix classification mismatch")

unpublished = [
    v11_compiler_root / "staging/compile-v10-failure-audit.json",
    v11_log_root / "preflight.receipt.json",
    v11_log_root / "preflight.bound-artifacts.json",
    v11_log_root / "preflight.final-binding.json",
    v11_log_root / "compile.status",
    v11_compiler_root / "collect-action-ledger.0.json",
    v11_compiler_root / "collect-build.count",
]
if any(path.exists() or path.is_symlink() for path in unpublished):
    raise SystemExit("compile-v11 unexpectedly published post-failure evidence")

zero_actions = {
    "collect": 0,
    "cmake_configure": 0,
    "cmake_build": 0,
    "verilator": 0,
    "make": 0,
    "binary_runs": 0,
    "model_runs": 0,
    "qwen_runs": 0,
    "synthesis": 0,
    "sta": 0,
    "ppa": 0,
}
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v11-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "compile_v11": {
        "contract_sha256": fixed[v11_contract],
        "material_sha256": fixed[v11_material],
        "runner_sha256": fixed[v11_runner],
        "preflight_status_sha256": fixed[v11_status],
        "preflight_status": expected_status.decode().strip(),
        "preflight_build_count_sha256": fixed[v11_count],
        "preflight_build_count_bytes": "0\\n",
        "preflight_snapshot_sha256": fixed[v11_snapshot],
        "bash_n_count": 1,
        "bash_n_rc": 0,
        "preflight_count": 1,
        "preflight_rc": 1,
        "build_root_absent": True,
        "compile_v10_audit_published": False,
        "structure_checker_executed": False,
        "document_mutations_executed": 0,
        "rtl_mutations_executed": 0,
        "zero_actions": zero_actions,
    },
    "root_cause": {
        "class": "predecessor-manual-middle-slice-mismatch",
        "failing_stage": "preflight-compile-v10-failure-closure",
        "algorithm": "longest-common-prefix-and-nonoverlapping-longest-common-suffix",
        "malformed_literal": malformed,
        "malformed_type": type(malformed).__name__,
        "malformed_length": len(malformed),
        "malformed_repr": repr(malformed),
        "malformed_ascii_only_lower_hex": True,
        "malformed_ascii_code_points": [ord(character) for character in malformed],
        "correct_literal": correct,
        "correct_type": type(correct).__name__,
        "correct_length": len(correct),
        "correct_repr": repr(correct),
        "correct_ascii_only_lower_hex": True,
        "correct_ascii_code_points": [ord(character) for character in correct],
        "common_prefix_length": prefix_length,
        "common_suffix_length": suffix_length,
        "common_prefix": common_prefix,
        "common_suffix": common_suffix,
        "malformed_middle_slice": malformed_middle,
        "malformed_middle_slice_type": type(malformed_middle).__name__,
        "malformed_middle_slice_repr": repr(malformed_middle),
        "malformed_middle_slice_ascii_code_points": [
            ord(character) for character in malformed_middle
        ],
        "malformed_middle_slice_classification": "empty",
        "correct_middle_slice": correct_middle,
        "correct_middle_slice_type": type(correct_middle).__name__,
        "correct_middle_slice_repr": repr(correct_middle),
        "correct_middle_slice_ascii_code_points": [
            ord(character) for character in correct_middle
        ],
        "correct_middle_slice_ascii_only_lower_hex": (
            correct_middle.isascii()
            and re.fullmatch(r"[0-9a-f]+", correct_middle) is not None
        ),
        "predecessor_manual_middle_slice": manual_middle,
        "predecessor_manual_middle_slice_repr": repr(manual_middle),
        "standard_library_hashlib_sha256": True,
        "rtl_or_compile_failure": False,
    },
    "frozen_inputs": {
        "log_directories": log_directories,
        "log_regular_files": log_files,
        "compiler_directories": compiler_directories,
        "compiler_regular_files": compiler_files,
    },
})
PY
}

audit_compile_v10_failure() {
    python3 - "$NPU_ROOT/scripts" "$COMPILE_V10_FAILURE_AUDIT" \
        "$COMPILE_V10_CONTRACT" "$COMPILE_V10_MATERIAL" "$COMPILE_V10_RUNNER" \
        "$COMPILE_V10_LOG_ROOT" "$COMPILE_V10_COMPILER_ROOT" \
        "$COMPILE_V10_BUILD_ROOT" \
        "$COMPILE_V8_COMPILER_ROOT/staging/preflight-build.count" <<'PY'
import hashlib
import json
import pathlib
import re
import stat
import sys

sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable

(
    output,
    v10_contract,
    v10_material,
    v10_runner,
    v10_log_root,
    v10_compiler_root,
    v10_build_root,
    live_v8_count,
) = map(pathlib.Path, sys.argv[2:10])
v10_status = v10_log_root / "preflight.status"
v10_count = v10_compiler_root / "staging/preflight-build.count"
v10_snapshot = v10_compiler_root / "staging/frozen-inputs.pre.json"
v10_v9_audit = v10_compiler_root / "staging/compile-v9-failure-audit.json"
fixed = {
    v10_contract: "3211ddf78b637e442465e573293c2cfca09ab2c42be818a7013aee391ebd64a1",
    v10_material: "83134968933c87dc9d5770a8afa12ce2d1f28c1744af26168bec54b8909f9bcd",
    v10_runner: "498913a752f0c7c2c7da9292cb353f47254a486459b5e7053da1665d8b602d47",
    v10_status: "9b01b2d6e6d27adecfdd3563b57b4ac02bd0fa7ce5492fe87f0f79fc5bb0e873",
    v10_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v10_snapshot: "2c5c72621c6fd4df084bf5e90245926721d59d5e5c0fc39508003e98ec5c2a5a",
    v10_v9_audit: "85cb9470c5aabdde4d5b997c7091b1cb5f989a7ed381708570e6c96ebfc1f474",
}
for path, expected in fixed.items():
    observed = path.lstat()
    if stat.S_ISLNK(observed.st_mode) or not stat.S_ISREG(observed.st_mode):
        raise SystemExit("compile-v10 frozen file missing or aliased: " + str(path))
    actual = hashlib.sha256(read_bytes_stable(path)).hexdigest()
    if actual != expected:
        raise SystemExit(
            "compile-v10 frozen byte drift path=" + str(path)
            + " observed=" + actual + " expected=" + expected
        )

def exact_census(directory):
    root_stat = directory.lstat()
    if stat.S_ISLNK(root_stat.st_mode) or not stat.S_ISDIR(root_stat.st_mode):
        raise SystemExit("compile-v10 evidence root missing or aliased: " + str(directory))
    directories = []
    regular_files = []
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise SystemExit("compile-v10 evidence member is symlink: " + relative)
        if stat.S_ISDIR(mode):
            directories.append(relative)
        elif stat.S_ISREG(mode):
            regular_files.append(relative)
        else:
            raise SystemExit("compile-v10 evidence member is special: " + relative)
    return directories, regular_files

log_directories, log_files = exact_census(v10_log_root)
compiler_directories, compiler_files = exact_census(v10_compiler_root)
if (
    log_directories != []
    or log_files != ["preflight.status"]
    or compiler_directories != ["sealed", "staging", "work"]
    or compiler_files != [
        "staging/compile-v9-failure-audit.json",
        "staging/frozen-inputs.pre.json",
        "staging/preflight-build.count",
    ]
):
    raise SystemExit("compile-v10 frozen evidence census mismatch")
if v10_build_root.exists() or v10_build_root.is_symlink():
    raise SystemExit("compile-v10 build root unexpectedly exists")

expected_status = (
    b"FAIL rc=1 stage=preflight-compile-v8-failure-closure "
    b"evidence_complete=0 cleanup_rc=0\n"
)
contract_value = json.loads(read_bytes_stable(v10_contract))
snapshot_value = json.loads(read_bytes_stable(v10_snapshot))
v9_audit_value = json.loads(read_bytes_stable(v10_v9_audit))
if (
    contract_value.get("schema_version") != 2
    or contract_value.get("task_id") != "qwen-f32-alu-families-compile-v10"
    or read_bytes_stable(v10_status) != expected_status
    or read_bytes_stable(v10_count) != b"0\n"
    or snapshot_value.get("schema")
    != "qwen-f32-alu-families-compile-v10-frozen-inputs-v1"
    or snapshot_value.get("task_id") != "qwen-f32-alu-families-compile-v10"
    or v9_audit_value.get("schema")
    != "qwen-f32-alu-families-compile-v10-compile-v9-failure-audit-v1"
    or v9_audit_value.get("pass") is not True
):
    raise SystemExit("compile-v10 status/count/snapshot semantic mismatch")

runner_text = read_bytes_stable(v10_runner).decode("utf-8")
literal_matches = re.findall(
    r'^\s{4}v8_count: "([0-9a-f]+)",$', runner_text, flags=re.MULTILINE
)
if len(literal_matches) != 1:
    raise SystemExit("compile-v10 malformed literal extraction cardinality mismatch")
malformed = literal_matches[0]
live_bytes = read_bytes_stable(live_v8_count)
correct = hashlib.sha256(live_bytes).hexdigest()
expected_malformed = "9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
expected_correct = "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
prefix_length = 0
for left, right in zip(malformed, correct):
    if left != right:
        break
    prefix_length += 1
suffix_length = 0
suffix_limit = min(len(malformed), len(correct)) - prefix_length
while (
    suffix_length < suffix_limit
    and malformed[len(malformed) - 1 - suffix_length]
    == correct[len(correct) - 1 - suffix_length]
):
    suffix_length += 1
malformed_end = len(malformed) - suffix_length if suffix_length else len(malformed)
correct_end = len(correct) - suffix_length if suffix_length else len(correct)
malformed_middle = malformed[prefix_length:malformed_end]
correct_middle = correct[prefix_length:correct_end]
common_prefix = malformed[:prefix_length]
common_suffix = malformed[malformed_end:]
if (
    type(malformed) is not str
    or type(correct) is not str
    or not malformed.isascii()
    or not correct.isascii()
    or re.fullmatch(r"[0-9a-f]+", malformed) is None
    or re.fullmatch(r"[0-9a-f]+", correct) is None
    or malformed != expected_malformed
    or correct != expected_correct
    or len(malformed) != 61
    or len(correct) != 64
    or prefix_length != 15
    or suffix_length != 46
    or malformed_middle != ""
    or common_prefix + malformed_middle + common_suffix != malformed
    or common_prefix + correct_middle + common_suffix != correct
    or live_bytes != b"0\n"
):
    raise SystemExit("compile-v10 malformed SHA literal classification mismatch")

unpublished = [
    v10_compiler_root / "staging/compile-v8-failure-audit.json",
    v10_log_root / "preflight.receipt.json",
    v10_log_root / "preflight.bound-artifacts.json",
    v10_log_root / "preflight.final-binding.json",
    v10_log_root / "compile.status",
    v10_log_root / "cmake-configure.argv.json",
    v10_log_root / "cmake-build.argv.json",
    v10_compiler_root / "collect-action-ledger.0.json",
    v10_compiler_root / "collect-build.count",
]
if any(path.exists() or path.is_symlink() for path in unpublished):
    raise SystemExit("compile-v10 unexpectedly published post-failure evidence")

zero_actions = {
    "collect": 0,
    "cmake_configure": 0,
    "cmake_build": 0,
    "verilator": 0,
    "make": 0,
    "binary_runs": 0,
    "model_runs": 0,
    "qwen_runs": 0,
    "synthesis": 0,
    "sta": 0,
    "ppa": 0,
}
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v10-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "compile_v10": {
        "contract_sha256": fixed[v10_contract],
        "material_sha256": fixed[v10_material],
        "runner_sha256": fixed[v10_runner],
        "preflight_status_sha256": fixed[v10_status],
        "preflight_status": expected_status.decode().strip(),
        "preflight_build_count_sha256": fixed[v10_count],
        "preflight_build_count_bytes": "0\\n",
        "preflight_snapshot_sha256": fixed[v10_snapshot],
        "compile_v9_failure_audit_sha256": fixed[v10_v9_audit],
        "bash_n_count": 1,
        "bash_n_rc": 0,
        "preflight_count": 1,
        "preflight_rc": 1,
        "build_root_absent": True,
        "structure_checker_executed": False,
        "document_mutations_executed": 0,
        "rtl_mutations_executed": 0,
        "zero_actions": zero_actions,
    },
    "root_cause": {
        "class": "python-expected-sha-literal-typo",
        "failing_stage": "preflight-compile-v8-failure-closure",
        "malformed_literal": malformed,
        "malformed_type": type(malformed).__name__,
        "malformed_length": len(malformed),
        "malformed_repr": repr(malformed),
        "malformed_ascii_only_lower_hex": True,
        "malformed_ascii_code_points": [ord(character) for character in malformed],
        "correct_literal": correct,
        "correct_type": type(correct).__name__,
        "correct_length": len(correct),
        "correct_repr": repr(correct),
        "correct_ascii_only_lower_hex": True,
        "correct_ascii_code_points": [ord(character) for character in correct],
        "algorithm": "longest-common-prefix-and-nonoverlapping-longest-common-suffix",
        "common_prefix_length": prefix_length,
        "common_suffix_length": suffix_length,
        "common_prefix": common_prefix,
        "common_suffix": common_suffix,
        "malformed_middle_slice": malformed_middle,
        "malformed_middle_slice_type": type(malformed_middle).__name__,
        "malformed_middle_slice_repr": repr(malformed_middle),
        "malformed_middle_slice_ascii_code_points": [
            ord(character) for character in malformed_middle
        ],
        "malformed_middle_slice_classification": "empty",
        "correct_middle_slice": correct_middle,
        "correct_middle_slice_type": type(correct_middle).__name__,
        "correct_middle_slice_repr": repr(correct_middle),
        "correct_middle_slice_ascii_code_points": [
            ord(character) for character in correct_middle
        ],
        "correct_middle_slice_ascii_only_lower_hex": (
            correct_middle.isascii()
            and re.fullmatch(r"[0-9a-f]+", correct_middle) is not None
        ),
        "standard_library_hashlib_sha256": True,
        "python_type_or_equality_issue": False,
        "rtl_or_compile_failure": False,
    },
    "frozen_inputs": {
        "log_directories": log_directories,
        "log_regular_files": log_files,
        "compiler_directories": compiler_directories,
        "compiler_regular_files": compiler_files,
    },
})
PY
}

audit_compile_v9_failure() {
    python3 - "$NPU_ROOT/scripts" "$COMPILE_V9_FAILURE_AUDIT" \
        "$COMPILE_V9_CONTRACT" "$COMPILE_V9_MATERIAL" "$COMPILE_V9_RUNNER" \
        "$COMPILE_V9_LOG_ROOT" "$COMPILE_V9_COMPILER_ROOT" \
        "$COMPILE_V9_BUILD_ROOT" <<'PY'
import json
import pathlib
import stat
import sys

sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    atomic_write_json,
    read_bytes_stable,
    sha256_bytes,
)

(
    output,
    v9_contract,
    v9_material,
    v9_runner,
    v9_log_root,
    v9_compiler_root,
    v9_build_root,
) = map(pathlib.Path, sys.argv[2:9])
v9_status = v9_log_root / "preflight.status"
v9_count = v9_compiler_root / "staging/preflight-build.count"
fixed = {
    v9_contract: "aa902bb23dd3de23720b70b13af17332465cf0fc88300e3daeeb6d853b58f1c5",
    v9_material: "56058ee96af83adecbb6c5a7f4d9e69cda5389ab0d420773e6d54914a5288853",
    v9_runner: "d9648f9de7227e2020e7ab67622cac4a26cd6351ddd8c82f783b7a47cbf85bc4",
    v9_status: "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51",
    v9_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
}

for path, expected in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("compile-v9 frozen file missing or aliased: " + str(path))
    data = read_bytes_stable(path)
    observed_hash = sha256_bytes(data)
    if observed_hash != expected:
        raise SystemExit(
            "compile-v9 frozen byte drift path=" + str(path)
            + " observed=" + observed_hash + " expected=" + expected
        )

if v9_build_root.exists() or v9_build_root.is_symlink():
    raise SystemExit("compile-v9 build root unexpectedly exists")

def exact_census(directory):
    root_stat = directory.lstat()
    if not stat.S_ISDIR(root_stat.st_mode) or stat.S_ISLNK(root_stat.st_mode):
        raise SystemExit("compile-v9 evidence root missing or aliased: " + str(directory))
    directories = []
    regular_files = []
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise SystemExit("compile-v9 evidence member is symlink: " + relative)
        if stat.S_ISDIR(mode):
            directories.append(relative)
        elif stat.S_ISREG(mode):
            regular_files.append(relative)
        else:
            raise SystemExit("compile-v9 evidence member is special: " + relative)
    return directories, regular_files

log_directories, log_files = exact_census(v9_log_root)
compiler_directories, compiler_files = exact_census(v9_compiler_root)
if (
    log_directories != []
    or log_files != ["preflight.status"]
    or compiler_directories != ["sealed", "staging", "work"]
    or compiler_files != ["staging/preflight-build.count"]
):
    raise SystemExit("compile-v9 frozen evidence census mismatch")

expected_status = (
    b"FAIL rc=1 stage=preflight-frozen-hash-admission "
    b"evidence_complete=0 cleanup_rc=0\n"
)
contract_value = json.loads(read_bytes_stable(v9_contract))
count_bytes = read_bytes_stable(v9_count)
if (
    contract_value.get("schema_version") != 2
    or contract_value.get("task_id") != "qwen-f32-alu-families-compile-v9"
    or read_bytes_stable(v9_status) != expected_status
    or count_bytes != b"0\n"
):
    raise SystemExit("compile-v9 status/count semantic mismatch")

unpublished = [
    v9_compiler_root / "staging/frozen-inputs.pre.json",
    v9_compiler_root / "staging/compile-v8-failure-audit.json",
    v9_compiler_root / "staging/compile-v7-root-fix-audit.json",
    v9_log_root / "preflight.receipt.json",
    v9_log_root / "preflight.bound-artifacts.json",
    v9_log_root / "preflight.final-binding.json",
    v9_log_root / "compile.status",
    v9_log_root / "cmake-configure.argv.json",
    v9_log_root / "cmake-build.argv.json",
    v9_compiler_root / "collect-action-ledger.0.json",
    v9_compiler_root / "collect-build.count",
]
if any(path.exists() or path.is_symlink() for path in unpublished):
    raise SystemExit("compile-v9 unexpectedly published post-failure evidence")

runner_text = read_bytes_stable(v9_runner).decode("utf-8")
early_hash_literal = (
    'require_exact_hash "$COMPILE_V8_COMPILER_ROOT/staging/preflight-build.count" '
    '\\\n        "$COMPILE_V8_PREFLIGHT_BUILD_COUNT_SHA256"'
)
if runner_text.count(early_hash_literal) != 1:
    raise SystemExit("compile-v9 early shell hash site identity mismatch")

atomic_write_json(
    output,
    {
        "schema": "qwen-f32-alu-families-compile-v13-compile-v9-failure-audit-v1",
        "task_id": "qwen-f32-alu-families-compile-v13",
        "pass": True,
        "compile_v9": {
            "contract_sha256": fixed[v9_contract],
            "material_sha256": fixed[v9_material],
            "runner_sha256": fixed[v9_runner],
            "preflight_status_sha256": fixed[v9_status],
            "preflight_status": expected_status.decode().strip(),
            "preflight_build_count_sha256": fixed[v9_count],
            "preflight_build_count_bytes": "0\\n",
            "build_root_absent": True,
            "input_snapshot_published": False,
            "structure_checker_executed": False,
            "document_mutations_executed": 0,
            "rtl_mutations_executed": 0,
            "collect_executed": False,
            "cmake_configure": 0,
            "cmake_build": 0,
            "verilator": 0,
            "make": 0,
            "binary_runs": 0,
            "model_runs": 0,
            "qwen_runs": 0,
            "synthesis": 0,
            "sta": 0,
            "ppa": 0,
        },
        "root_cause": {
            "class": "unexplained-shell-hash-false-negative",
            "failing_stage": "preflight-frozen-hash-admission",
            "failing_object": (
                "npu/version_0820/tmp/compiler/"
                "qwen-f32-alu-families-compile-v8/staging/preflight-build.count"
            ),
            "shell_observed_mismatch_frozen": True,
            "direct_post_failure_observation_bound_by_compile_v8_closure": True,
            "predecessor_drift_proven": False,
            "rtl_or_compile_failure": False,
        },
        "frozen_inputs": {
            "log_directories": log_directories,
            "log_regular_files": log_files,
            "compiler_directories": compiler_directories,
            "compiler_regular_files": compiler_files,
        },
    },
)
PY
}

audit_compile_v8_failure() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V8_FAILURE_AUDIT" \
        "$COMPILE_V8_CONTRACT" "$COMPILE_V8_MATERIAL" "$COMPILE_V8_RUNNER" \
        "$COMPILE_V8_LOG_ROOT" "$COMPILE_V8_COMPILER_ROOT" \
        "$COMPILE_V8_BUILD_ROOT" \
        "$NPU_ROOT/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md" \
        "$NPU_ROOT/rtl/TensorNpuVectorF32Adapter.v" <<'PY'
import hashlib
import json
import os
import pathlib
import re
import stat
import sys
import tempfile

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json,
    read_bytes_stable,
    read_json_same_bytes,
    sha256_bytes,
)

(
    output,
    v8_contract,
    v8_material,
    v8_runner,
    v8_log_root,
    v8_compiler_root,
    v8_build_root,
    owner_contract,
    adapter,
) = map(pathlib.Path, sys.argv[3:12])

v8_status = v8_log_root / "preflight.status"
v8_count = v8_compiler_root / "staging/preflight-build.count"
v8_snapshot = v8_compiler_root / "staging/frozen-inputs.pre.json"
fixed = {
    v8_contract: "bc2b3378affd5c85d42d37968e74db6494822763a5c79d5063f8ec2deecf8de3",
    v8_material: "80c3d1c1b5d8e849118435d8b60d92c4e990d883f1212b0c9f62494d75b07c6c",
    v8_runner: "2ecdc8c905dc28697f6ef067ed227fe42ad5ab49567a201c5cbb7f514d642fef",
    v8_status: "79184a20fea5d869495b2837d43f99b0334d69f785c14ae678b15180dca4d789",
    v8_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v8_snapshot: "e8eac94ac0810b896b7d27af7e6a6d53971e038fece3fb11c6d27ec1f8df41d6",
    owner_contract: "4c31de3670df477e8b8a08d7c5d7873d43c73a3748b20cb96a18af43283555a4",
    adapter: "11e75f704c1eb2894c1aa97a6ea23bada931cc752eff8953b54bebdee83166e5",
}

for path, expected in fixed.items():
    if path == v8_count:
        continue
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("compile-v8 frozen file missing or aliased: " + str(path))
    if sha256_bytes(read_bytes_stable(path)) != expected:
        raise SystemExit("compile-v8 frozen byte drift: " + str(path))

def stat_fingerprint(observed):
    return {
        "dev": observed.st_dev,
        "ino": observed.st_ino,
        "mode": observed.st_mode,
        "nlink": observed.st_nlink,
        "uid": observed.st_uid,
        "gid": observed.st_gid,
        "size": observed.st_size,
        "mtime_ns": observed.st_mtime_ns,
        "ctime_ns": observed.st_ctime_ns,
    }

def read_regular_window(path):
    before = path.lstat()
    if stat.S_ISLNK(before.st_mode) or not stat.S_ISREG(before.st_mode):
        raise ValueError("not a regular non-symlink file")
    flags = os.O_RDONLY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(path, flags)
    try:
        opened = os.fstat(descriptor)
        if not stat.S_ISREG(opened.st_mode):
            raise ValueError("opened object is not regular")
        chunks = []
        while True:
            chunk = os.read(descriptor, 65536)
            if not chunk:
                break
            chunks.append(chunk)
        opened_after = os.fstat(descriptor)
    finally:
        os.close(descriptor)
    after = path.lstat()
    fingerprints = [
        stat_fingerprint(before),
        stat_fingerprint(opened),
        stat_fingerprint(opened_after),
        stat_fingerprint(after),
    ]
    if any(value != fingerprints[0] for value in fingerprints[1:]):
        raise ValueError("stat fingerprint changed inside read window")
    return b"".join(chunks), fingerprints[0]

def audit_count(path, expected_hash, between_windows=None):
    observed_hash = "<unavailable>"
    try:
        if (
            type(expected_hash) is not str
            or not expected_hash.isascii()
            or re.fullmatch(r"[0-9a-f]{64}", expected_hash) is None
        ):
            raise ValueError("expected sha256 is not a 64-character ASCII lower-hex str")
        first_bytes, first_fingerprint = read_regular_window(path)
        if between_windows is not None:
            between_windows()
        second_bytes, second_fingerprint = read_regular_window(path)
        observed_hash = hashlib.sha256(second_bytes).hexdigest()
        if first_fingerprint != second_fingerprint:
            raise ValueError("stat fingerprint changed between windows")
        if first_bytes != second_bytes:
            raise ValueError("bytes changed between windows")
        if first_bytes != b"0\n":
            raise ValueError("content is not exact zero-line")
        if observed_hash != expected_hash:
            raise ValueError("sha256 mismatch")
    except (OSError, ValueError) as error:
        raise ValueError(
            "compile-v8 count audit failed path=" + str(path)
            + " observed=" + observed_hash
            + " expected=" + expected_hash
            + " detail=" + str(error)
        ) from error
    return {
        "path": str(path),
        "file_type": "regular-non-symlink",
        "byte_length": len(second_bytes),
        "content_classification": "exact-zero-line",
        "escaped_content": "0\\n",
        "expected_sha256": expected_hash,
        "observed_sha256": observed_hash,
        "expected_sha256_type": type(expected_hash).__name__,
        "expected_sha256_length": len(expected_hash),
        "expected_sha256_repr": repr(expected_hash),
        "expected_sha256_ascii_code_points": [ord(character) for character in expected_hash],
        "observed_sha256_type": type(observed_hash).__name__,
        "observed_sha256_length": len(observed_hash),
        "observed_sha256_repr": repr(observed_hash),
        "observed_sha256_ascii_code_points": [ord(character) for character in observed_hash],
        "hash_implementation": "python-stdlib-hashlib.sha256(bytes).hexdigest",
        "window_count": 2,
        "window_byte_sha256": [
            hashlib.sha256(first_bytes).hexdigest(),
            hashlib.sha256(second_bytes).hexdigest(),
        ],
        "before_stat_fingerprint": first_fingerprint,
        "after_stat_fingerprint": second_fingerprint,
        "fingerprint_stable": True,
    }

count_audit = audit_count(v8_count, fixed[v8_count])

def mutation_rejected(path, expected_hash, hook=None):
    try:
        audit_count(path, expected_hash, hook)
    except ValueError:
        return True
    return False

work_root = output.parent.parent / "work"
mutation_results = {}
with tempfile.TemporaryDirectory(prefix="v8-count-mutations.", dir=work_root) as temporary:
    temporary = pathlib.Path(temporary)

    changed = temporary / "changed-bytes.count"
    changed.write_bytes(b"1\n")
    mutation_results["changed_bytes"] = mutation_rejected(
        changed, fixed[v8_count]
    )

    target = temporary / "symlink-target.count"
    target.write_bytes(b"0\n")
    symlink = temporary / "symlink.count"
    symlink.symlink_to(target.name)
    mutation_results["symlink"] = mutation_rejected(
        symlink, fixed[v8_count]
    )

    special = temporary / "special-non-file.count"
    os.mkfifo(special, 0o600)
    mutation_results["special_non_file"] = mutation_rejected(
        special, fixed[v8_count]
    )

    substituted = temporary / "replacement-between-windows.count"
    substituted.write_bytes(b"0\n")
    replacement = temporary / "replacement-source.count"
    replacement.write_bytes(b"0\n")
    mutation_results["replacement_between_windows"] = mutation_rejected(
        substituted,
        fixed[v8_count],
        lambda: os.replace(replacement, substituted),
    )

    correct = temporary / "malformed-61-character-expected-literal.count"
    correct.write_bytes(b"0\n")
    mutation_results["malformed_61_character_expected_literal"] = mutation_rejected(
        correct, "9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"
    )

if set(mutation_results) != {
    "changed_bytes", "symlink", "special_non_file",
    "replacement_between_windows", "malformed_61_character_expected_literal",
} or not all(mutation_results.values()):
    raise SystemExit("compile-v8 count directed mutation unexpectedly accepted")

if v8_build_root.exists() or v8_build_root.is_symlink():
    raise SystemExit("compile-v8 build root unexpectedly exists")

def exact_census(directory):
    observed = directory.lstat()
    if not stat.S_ISDIR(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("compile-v8 evidence root missing or aliased: " + str(directory))
    directories = []
    regular_files = []
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise SystemExit("compile-v8 evidence member is symlink: " + relative)
        if stat.S_ISDIR(mode):
            directories.append(relative)
        elif stat.S_ISREG(mode):
            regular_files.append(relative)
        else:
            raise SystemExit("compile-v8 evidence member is special: " + relative)
    return directories, regular_files

log_directories, log_files = exact_census(v8_log_root)
compiler_directories, compiler_files = exact_census(v8_compiler_root)
if (
    log_directories != []
    or log_files != ["preflight.status"]
    or compiler_directories != ["sealed", "staging", "work"]
    or compiler_files
    != ["staging/frozen-inputs.pre.json", "staging/preflight-build.count"]
):
    raise SystemExit("compile-v8 frozen evidence census mismatch")

contract_value = json.loads(read_bytes_stable(v8_contract))
snapshot, snapshot_sha, _ = read_json_same_bytes(v8_snapshot)
expected_status = (
    b"FAIL rc=1 stage=preflight-compile-v7-root-fix "
    b"evidence_complete=0 cleanup_rc=0\n"
)
if (
    contract_value.get("schema_version") != 2
    or contract_value.get("task_id") != "qwen-f32-alu-families-compile-v8"
    or read_bytes_stable(v8_status) != expected_status
    or read_bytes_stable(v8_count) != b"0\n"
    or snapshot_sha != fixed[v8_snapshot]
    or snapshot.get("schema")
    != "qwen-f32-alu-families-compile-v8-frozen-inputs-v1"
    or snapshot.get("task_id") != "qwen-f32-alu-families-compile-v8"
    or snapshot.get("file_count") != 9839
    or snapshot.get("external_count") != 11
    or snapshot.get("identity_sha256")
    != "af843c734ef7b63d5f2e1c9e5fb9024e3554e1b60b13b635ea4ab945d8615055"
):
    raise SystemExit("compile-v8 status/snapshot semantic mismatch")

snapshot_expected = {
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v8.json":
        fixed[v8_contract],
    "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v8-material.md":
        fixed[v8_material],
    "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v8.sh":
        fixed[v8_runner],
    "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md":
        fixed[owner_contract],
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v": fixed[adapter],
}
for relative, expected in snapshot_expected.items():
    record = snapshot.get("files", {}).get(relative, {})
    if record.get("type") != "regular" or record.get("sha256") != expected:
        raise SystemExit("compile-v8 snapshot frozen record mismatch: " + relative)

unpublished = [
    v8_compiler_root / "staging/compile-v7-root-fix-audit.json",
    v8_log_root / "preflight.receipt.json",
    v8_log_root / "preflight.bound-artifacts.json",
    v8_log_root / "preflight.final-binding.json",
    v8_log_root / "compile.status",
    v8_log_root / "cmake-configure.argv.json",
    v8_log_root / "cmake-build.argv.json",
    v8_compiler_root / "collect-action-ledger.0.json",
    v8_compiler_root / "collect-build.count",
]
if any(path.exists() or path.is_symlink() for path in unpublished):
    raise SystemExit("compile-v8 unexpectedly published post-failure evidence")

runner_text = read_bytes_stable(v8_runner).decode("utf-8")
owner_text = read_bytes_stable(owner_contract).decode("utf-8")
brittle_prose = "expected warning census仍精确为冻结 25 行，不得更新为 26"
parenthesized_term = "(dst_nb3_ext_w[127:64] != 64'd0)"
required_headings = [
    "## V8.1 阶段 1：需求冻结",
    "## V8.2a 阶段 2a：协议规则",
    "## V8.2b 阶段 2b：状态机",
    "## V8.2c 阶段 2c：不变量",
    "## V8.2d 阶段 2d：数据通路约束",
    "## V8.2e 阶段 2e：RTL 级 topology（九项冻结）",
]
heading_counts = {heading: owner_text.count(heading) for heading in required_headings}
v8_i5_semantic = "冻结 warning oracle仍为 25 行，禁止新增第 26 行 waiver"
if (
    runner_text.count(brittle_prose) != 1
    or runner_text.count('owner_text.count("(dst_nb3_ext_w[127:64] != 64\'d0)") < 2')
    != 1
    or any(count != 1 for count in heading_counts.values())
    or owner_text.count(brittle_prose) != 1
    or owner_text.count(parenthesized_term) != 1
    or owner_text.count(v8_i5_semantic) != 1
):
    raise SystemExit("compile-v8 brittle doc-parser root-cause mismatch")

atomic_write_json(
    output,
    {
        "schema": "qwen-f32-alu-families-compile-v13-compile-v8-failure-audit-v1",
        "task_id": "qwen-f32-alu-families-compile-v13",
        "pass": True,
        "compile_v8": {
            "contract_sha256": fixed[v8_contract],
            "material_sha256": fixed[v8_material],
            "runner_sha256": fixed[v8_runner],
            "preflight_status_sha256": fixed[v8_status],
            "preflight_status": expected_status.decode().strip(),
            "preflight_snapshot_sha256": snapshot_sha,
            "preflight_build_count": 0,
            "preflight_build_count_audit": count_audit,
            "preflight_build_count_mutations_rejected": mutation_results,
            "build_root_absent": True,
            "root_fix_audit_published": False,
            "collect_executed": False,
            "cmake_configure": 0,
            "cmake_build": 0,
            "verilator": 0,
            "make": 0,
            "binary_runs": 0,
            "model_runs": 0,
            "qwen_runs": 0,
            "synthesis": 0,
            "sta": 0,
            "ppa": 0,
        },
        "root_cause": {
            "class": "doc-evidence-parser-false-negative",
            "failing_stage": "preflight-compile-v7-root-fix",
            "whole_file_hashes_valid": True,
            "required_heading_counts": heading_counts,
            "brittle_prose_literal_count_in_doc": owner_text.count(brittle_prose),
            "parenthesized_live_term_count_in_doc": owner_text.count(parenthesized_term),
            "parenthesized_live_term_required_minimum": 2,
            "v8_i5_semantic_row_count": owner_text.count(v8_i5_semantic),
            "unsealed_pre_root_checks_must_not_be_called_pass": True,
        },
        "frozen_inputs": {
            "owner_contract_sha256": fixed[owner_contract],
            "adapter_sha256": fixed[adapter],
            "snapshot_identity_sha256": snapshot["identity_sha256"],
            "log_regular_files": log_files,
            "compiler_directories": compiler_directories,
            "compiler_regular_files": compiler_files,
        },
    },
)
PY
}

audit_compile_v7_root_fix() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V7_ROOT_FIX_AUDIT" \
        "$COMPILE_V7_CONTRACT" "$COMPILE_V7_MATERIAL" "$COMPILE_V7_RUNNER" \
        "$COMPILE_V7_LOG_ROOT" "$COMPILE_V7_COMPILER_ROOT" \
        "$COMPILE_V7_BUILD_ROOT" "$WARNING_SOURCE" \
        "$NPU_ROOT/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md" \
        "$NPU_ROOT/rtl/TensorNpuVectorF32Adapter.v" <<'PY'
import collections
import hashlib
import json
import os
import pathlib
import re
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json,
    read_bytes_stable,
    read_json_same_bytes,
    revalidate_bound_artifacts,
    sha256_bytes,
)

(
    output,
    v7_contract,
    v7_material,
    v7_runner,
    v7_log_root,
    v7_compiler_root,
    v7_build_root,
    warning_source,
    owner_contract,
    adapter,
) = map(pathlib.Path, sys.argv[3:13])

v7_receipt = v7_log_root / "preflight.receipt.json"
v7_manifest = v7_log_root / "preflight.bound-artifacts.json"
v7_binding = v7_log_root / "preflight.final-binding.json"
v7_preflight_status = v7_log_root / "preflight.status"
v7_compile_status = v7_log_root / "compile.status"
v7_configure_argv = v7_log_root / "cmake-configure.argv.json"
v7_build_argv = v7_log_root / "cmake-build.argv.json"
v7_configure_rc = v7_log_root / "cmake-configure.rc"
v7_build_rc = v7_log_root / "cmake-build.rc"
v7_build_log = v7_log_root / "cmake-build.log"
v7_snapshot = v7_compiler_root / (
    "sealed/frozen-inputs."
    "6f80fe9f25fa07a453ad4f00d91c248777dc6f6a662c0a99328a7e9e538db982.json"
)
v7_preflight_count = v7_compiler_root / "staging/preflight-build.count"
v7_collect_snapshot = v7_compiler_root / "collect-inputs.pre.json"
v7_collect_count = v7_compiler_root / "collect-build.count"
v7_ledger0 = v7_compiler_root / "collect-action-ledger.0.json"
v7_ledger1 = v7_compiler_root / "collect-action-ledger.1.json"
v7_ledger2 = v7_compiler_root / "collect-action-ledger.2.json"

fixed = {
    v7_contract: "3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9",
    v7_material: "5f11f4d2adfa8f05d8ed0fe94cc112f2a838e8dac05d78a6826bfb31a21fe9d0",
    v7_runner: "b525f6a0a60866593380a27d3f0103c72edd447e8b9faf736a65e88463225405",
    v7_receipt: "952979818b58fee40f5a37fb2b802fae3e1985cfe3fdcf68d8042d094b7a6c10",
    v7_manifest: "b9dfca7c0c51392870b25b41b0bcb782d04acbc5d1e8cae414ceceb5b7673af1",
    v7_binding: "76ac9fcf37a8e513dd68e6b23c55bf2ad2a269bf4a4b3c491637cdd0f8d9f695",
    v7_preflight_status: "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    v7_snapshot: "6f80fe9f25fa07a453ad4f00d91c248777dc6f6a662c0a99328a7e9e538db982",
    v7_preflight_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v7_compile_status: "aa335af767b126c3151f774b24dbb74fb99f1127edc1ccfba9dd7910baad9c3d",
    v7_configure_argv: "6f839a530c4acbb70009391d9e625c0a0d34f0b5a7e099049a1f01dc5ac40ab5",
    v7_build_argv: "d6140dfc79145c29540c2bb09d6f869705dfdb4afe07a87e3c1eca95224d5e00",
    v7_configure_rc: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v7_build_rc: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v7_build_log: "b1fc1d39e6e7b2dda13f68677978ef5f51ee1ab0787add97a6e24ac87a593708",
    v7_ledger0: "08ffb3f625cd2d5ba4ef74f718e755276bd5dcf965a3ad2c1ccdde3b22a38194",
    v7_ledger1: "37208f0e5ad6584421672cbc6a9b2d5acef89a0936c6b52fde57c9a629b3172a",
    v7_ledger2: "02535cc21816318d4bf899f490de0300a12ed4df36d4f8caaa936709d0b77322",
    v7_collect_count: "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
    v7_collect_snapshot: "6f80fe9f25fa07a453ad4f00d91c248777dc6f6a662c0a99328a7e9e538db982",
    warning_source: "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c",
    owner_contract: "4c31de3670df477e8b8a08d7c5d7873d43c73a3748b20cb96a18af43283555a4",
    adapter: "11e75f704c1eb2894c1aa97a6ea23bada931cc752eff8953b54bebdee83166e5",
}

for path, expected in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("v7/root-fix file missing or aliased: " + str(path))
    if sha256_bytes(read_bytes_stable(path)) != expected:
        raise SystemExit("v7/root-fix byte drift: " + str(path))

build_stat = v7_build_root.lstat()
if (
    not stat.S_ISDIR(build_stat.st_mode)
    or stat.S_ISLNK(build_stat.st_mode)
    or v7_build_root.resolve(strict=True) != v7_build_root.absolute()
):
    raise SystemExit("compile-v7 build root missing or aliased")

contract_value = json.loads(read_bytes_stable(v7_contract))
if (
    contract_value.get("schema_version") != 2
    or contract_value.get("task_id") != "qwen-f32-alu-families-compile-v7"
):
    raise SystemExit("compile-v7 contract schema/task mismatch")

receipt, receipt_sha, _ = read_json_same_bytes(v7_receipt)
manifest, manifest_sha, _ = read_json_same_bytes(v7_manifest)
binding, binding_sha, _ = read_json_same_bytes(v7_binding)
snapshot, snapshot_sha, snapshot_bytes = read_json_same_bytes(v7_snapshot)
collect_snapshot, collect_snapshot_sha, collect_snapshot_bytes = read_json_same_bytes(
    v7_collect_snapshot
)
if (
    receipt_sha != fixed[v7_receipt]
    or manifest_sha != fixed[v7_manifest]
    or binding_sha != fixed[v7_binding]
    or snapshot_sha != fixed[v7_snapshot]
    or collect_snapshot_sha != fixed[v7_collect_snapshot]
    or snapshot_bytes != collect_snapshot_bytes
    or snapshot != collect_snapshot
    or read_bytes_stable(v7_preflight_status) != b"PASS\n"
    or read_bytes_stable(v7_preflight_count) != b"0\n"
):
    raise SystemExit("compile-v7 preflight/snapshot closure mismatch")
if (
    receipt.get("task_id") != "qwen-f32-alu-families-compile-v7"
    or receipt.get("build_count") != 0
    or receipt.get("build_root_absent") is not True
    or receipt.get("warning_expected_rows") != 25
    or receipt.get("invocations", {}).get("cmake_configure") != 0
    or receipt.get("invocations", {}).get("cmake_build") != 0
    or manifest.get("receipt_sha256") != receipt_sha
    or binding.get("receipt_sha256") != receipt_sha
    or binding.get("bound_artifacts_sha256") != manifest_sha
    or binding.get("content_addressed_snapshot_sha256") != snapshot_sha
):
    raise SystemExit("compile-v7 preflight semantic mismatch")
reopened = revalidate_bound_artifacts(root, manifest["artifacts"])
if reopened.get("artifact_count") != manifest.get("artifact_count"):
    raise SystemExit("compile-v7 preflight artifact reopen mismatch")

compile_status = read_bytes_stable(v7_compile_status)
expected_compile_status = (
    b"FAIL rc=1 stage=collect-build-evidence-audit "
    b"evidence_complete=0 cleanup_rc=0\n"
)
if compile_status != expected_compile_status:
    raise SystemExit("compile-v7 collect terminal status mismatch")
if (
    read_bytes_stable(v7_configure_rc) != b"0\n"
    or read_bytes_stable(v7_build_rc) != b"0\n"
    or read_bytes_stable(v7_collect_count) != b"1\n"
):
    raise SystemExit("compile-v7 configure/build/count mismatch")

configure_argv = read_json_same_bytes(v7_configure_argv)[0]
build_argv = read_json_same_bytes(v7_build_argv)[0]
pinned_cmake = (
    "/home/lyg/PA/ysyx-workbench/npu/version_0820/"
    "tmp/tools/cmake-3.31.12/bin/cmake"
)
for action, kind in ((configure_argv, "cmake-configure"), (build_argv, "cmake-build")):
    if (
        action.get("kind") != kind
        or action.get("argv", [None])[0] != pinned_cmake
        or action.get("executable") != pinned_cmake
        or action.get("executable_sha256")
        != "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
        or action.get("cwd") != str(root)
    ):
        raise SystemExit("compile-v7 absolute CMake argv mismatch")
if (
    "-DCMAKE_BUILD_TYPE=Release" not in configure_argv["argv"]
    or "-DNPU_VERILATOR_JOBS=1" not in configure_argv["argv"]
    or "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG" not in configure_argv["argv"]
    or "--parallel" not in build_argv["argv"]
    or "1" not in build_argv["argv"]
    or "--verbose" not in build_argv["argv"]
):
    raise SystemExit("compile-v7 Release/O3/j1 argv mismatch")

ledger0, ledger0_sha, _ = read_json_same_bytes(v7_ledger0)
ledger1, ledger1_sha, _ = read_json_same_bytes(v7_ledger1)
ledger2, ledger2_sha, _ = read_json_same_bytes(v7_ledger2)
zero_counts = {
    "cmake-configure": 0,
    "cmake-build": 0,
    "binary": 0,
    "model": 0,
    "qwen": 0,
    "synthesis": 0,
    "sta": 0,
    "ppa": 0,
}
relative = lambda path: path.resolve(strict=True).relative_to(root).as_posix()
if (
    ledger0.get("snapshot_index") != 0
    or ledger0.get("counts") != zero_counts
    or ledger0.get("ordered_actions") != []
    or ledger1.get("snapshot_index") != 1
    or ledger1.get("prior_snapshot_sha256") != ledger0_sha
    or ledger1.get("prior_snapshot_path") != relative(v7_ledger0)
    or ledger1.get("admission_argv_sha256") != fixed[v7_configure_argv]
    or ledger1.get("counts") != {**zero_counts, "cmake-configure": 1}
    or ledger1.get("ordered_actions") != ["cmake-configure"]
    or ledger2.get("snapshot_index") != 2
    or ledger2.get("prior_snapshot_sha256") != ledger1_sha
    or ledger2.get("prior_snapshot_path") != relative(v7_ledger1)
    or ledger2.get("admission_argv_sha256") != fixed[v7_build_argv]
    or ledger2.get("prior_action_rc_sha256") != fixed[v7_configure_rc]
    or ledger2.get("counts")
    != {**zero_counts, "cmake-configure": 1, "cmake-build": 1}
    or ledger2.get("ordered_actions") != ["cmake-configure", "cmake-build"]
):
    raise SystemExit("compile-v7 append-only action chain mismatch")

expected_warnings = []
for raw in read_bytes_stable(warning_source).decode().splitlines():
    category, path, line_no, column = raw.split("\t")
    expected_warnings.append((category, path, int(line_no), int(column)))
build_text = read_bytes_stable(v7_build_log).decode("utf-8", errors="replace")
primary = re.compile(r"^%Warning-([A-Z0-9_]+):\s+(.+?):([0-9]+):([0-9]+):")
actual_warnings = []
other_diagnostics = []
for raw in build_text.splitlines():
    match = primary.match(raw)
    if match:
        absolute = pathlib.Path(match.group(2)).resolve(strict=True)
        actual_warnings.append(
            (
                match.group(1),
                absolute.relative_to(root).as_posix(),
                int(match.group(3)),
                int(match.group(4)),
            )
        )
        continue
    if re.search(
        r"(^|[\s:])(%Warning(?:-[A-Z0-9_]+)?|warning:|"
        r"%Error(?:-[A-Z0-9_]+)?|error:|fatal error:)",
        raw,
        re.IGNORECASE,
    ):
        other_diagnostics.append(raw)
missing = list(
    (collections.Counter(expected_warnings) - collections.Counter(actual_warnings)).elements()
)
extra = list(
    (collections.Counter(actual_warnings) - collections.Counter(expected_warnings)).elements()
)
expected_extra = [
    (
        "UNUSEDSIGNAL",
        "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v",
        346,
        18,
    )
]
raw_extra = (
    "%Warning-UNUSEDSIGNAL: "
    "/home/lyg/PA/ysyx-workbench/npu/version_0820/rtl/"
    "TensorNpuVectorF32Adapter.v:346:18: Bits of signal are not used: "
    "'dst_nb3_ext_w'[127:64]"
)
if (
    len(expected_warnings) != 25
    or len(actual_warnings) != 26
    or missing != []
    or extra != expected_extra
    or other_diagnostics != []
    or build_text.count(raw_extra) != 1
):
    raise SystemExit(
        "compile-v7 exact warning delta mismatch missing="
        + repr(missing)
        + " extra="
        + repr(extra)
        + " other="
        + repr(other_diagnostics)
    )

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
        raise SystemExit("live frozen input is special: " + str(path))
    data = read_bytes_stable(path)
    if path.suffix == ".json":
        json.loads(data)
    return {
        "type": "regular",
        "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
        "sha256": sha256_bytes(data),
        "size_bytes": len(data),
    }

allowed_changes = {
    "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md": (
        "1f1cd0a4971826f2ddcf939bd3f796c5986088bb66eac107e4937d396e14e376",
        fixed[owner_contract],
    ),
    "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v": (
        "3de215650ff39f6649b21e37864cfce102ba6de824cccdbb8be2b124b6246cff",
        fixed[adapter],
    ),
}
changed = []
for relative, record in snapshot["files"].items():
    live = capture(root / relative)
    if relative in allowed_changes:
        old_sha, new_sha = allowed_changes[relative]
        if record.get("type") != "regular" or record.get("sha256") != old_sha:
            raise SystemExit("compile-v7 baseline for allowed change mismatch: " + relative)
        if live.get("type") != "regular" or live.get("sha256") != new_sha:
            raise SystemExit("compile-v13 allowed production change mismatch: " + relative)
        if live == record:
            raise SystemExit("declared production change did not change bytes: " + relative)
        changed.append(relative)
    elif live != record:
        raise SystemExit("production/frozen input drift outside v8 scope: " + relative)
for absolute, record in snapshot["external"].items():
    if capture(pathlib.Path(absolute)) != record:
        raise SystemExit("external tool drift since compile-v7: " + absolute)
if changed != sorted(allowed_changes):
    raise SystemExit("compile-v13 exact production change set mismatch")

adapter_text = read_bytes_stable(adapter).decode("utf-8")
owner_text = read_bytes_stable(owner_contract).decode("utf-8")
term_line = "        (dst_nb3_ext_w[127:64] != 64'd0) ||\n"

def strip_comments(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", source)

term_pattern = re.compile(
    r"\(\s*dst_nb3_ext_w\s*\[\s*127\s*:\s*64\s*\]\s*"
    r"!=\s*64'd0\s*\)"
)
upper_slice_pattern = re.compile(
    r"dst_nb3_ext_w\s*\[\s*127\s*:\s*64\s*\]"
)

def admission_checker(source):
    plain = strip_comments(source)
    assignments = list(
        re.finditer(r"\bassign\s+iova_reject_w\s*=\s*(.*?);", plain, re.DOTALL)
    )
    if len(assignments) != 1:
        return False
    expression = assignments[0].group(1)
    if len(term_pattern.findall(expression)) != 1:
        return False
    if len(upper_slice_pattern.findall(plain)) != 1:
        return False
    declaration = source.find("wire [127:0] dst_nb3_ext_w;")
    assignment_end = source.find(";", source.find("assign iova_reject_w", declaration))
    if declaration < 0 or assignment_end < 0:
        return False
    target_region = source[declaration:assignment_end]
    if re.search(r"verilator\s+lint_(?:off|on)\s+UNUSEDSIGNAL", target_region):
        return False
    return True

if term_line not in adapter_text or not admission_checker(adapter_text):
    raise SystemExit("live adapter terminal-stride admission term missing/non-semantic")

removed = adapter_text.replace(term_line, "", 1)
moved = removed.replace(
    "    wire [63:0] source_base_min_w;",
    "    wire dst_nb3_overflow_probe_w;\n"
    "    assign dst_nb3_overflow_probe_w = "
    "(dst_nb3_ext_w[127:64] != 64'd0);\n\n"
    "    wire [63:0] source_base_min_w;",
    1,
)
wrong_slice = adapter_text.replace(
    "dst_nb3_ext_w[127:64] != 64'd0",
    "dst_nb3_ext_w[126:63] != 64'd0",
    1,
)
wrong_value = adapter_text.replace(
    "dst_nb3_ext_w[127:64] != 64'd0",
    "dst_nb3_ext_w[127:64] != 64'd1",
    1,
)
comment_only = adapter_text.replace(
    term_line,
    "        // (dst_nb3_ext_w[127:64] != 64'd0) ||\n",
    1,
)
waiver = adapter_text.replace(
    "    assign dst_nb1_ext_w =",
    "    /* verilator lint_off UNUSEDSIGNAL */\n"
    "    /* verilator lint_on UNUSEDSIGNAL */\n"
    "    assign dst_nb1_ext_w =",
    1,
)
dummy = adapter_text.replace(
    "    assign dst_nb1_ext_w =",
    "    wire dst_nb3_upper_dummy_w;\n"
    "    assign dst_nb3_upper_dummy_w = |dst_nb3_ext_w[127:64];\n"
    "    assign dst_nb1_ext_w =",
    1,
)
mutations = {
    "remove_term": removed,
    "move_outside_live_admission": moved,
    "wrong_slice": wrong_slice,
    "wrong_value": wrong_value,
    "comment_only_decoy": comment_only,
    "warning_waiver": waiver,
    "dummy_consumer": dummy,
}
mutations_rejected = {
    name: not admission_checker(mutant) for name, mutant in mutations.items()
}
if not all(mutations_rejected.values()):
    raise SystemExit("terminal-stride directed mutation unexpectedly accepted")

heading_lines = [
    "## V8.1 阶段 1：需求冻结",
    "## V8.2a 阶段 2a：协议规则",
    "## V8.2b 阶段 2b：状态机",
    "## V8.2c 阶段 2c：不变量",
    "## V8.2d 阶段 2d：数据通路约束",
    "## V8.2e 阶段 2e：RTL 级 topology（九项冻结）",
]
heading_ids = ["V8.1", "V8.2a", "V8.2b", "V8.2c", "V8.2d", "V8.2e"]
invariant_ids = ["V8-I1", "V8-I2", "V8-I3", "V8-I4", "V8-I5"]
topology_ordinals = list(range(1, 10))
semantic_tokens = [
    "dst_nb3_ext_w[127:64]",
    "64'd0",
    "iova_reject_w",
    "25",
    "26",
    "warning",
    "waiver",
]
structure_identity = {
    "heading_ids": heading_ids,
    "invariant_ids": invariant_ids,
    "semantic_tokens": semantic_tokens,
    "topology_ordinals": topology_ordinals,
}
structure_id_sha256 = hashlib.sha256(
    json.dumps(structure_identity, sort_keys=True, separators=(",", ":")).encode()
).hexdigest()
expected_structure_id_sha256 = (
    "b9d4366c26b281bea20b8f3c459a4128e150be157afdbb7e1857580f7d81b0c3"
)
if structure_id_sha256 != expected_structure_id_sha256:
    raise SystemExit("V8 stable structure ID drift")

def visible_markdown_lines(text):
    visible = []
    fence = None
    for index, line in enumerate(text.splitlines()):
        stripped = line.lstrip()
        while stripped.startswith(">"):
            stripped = stripped[1:].lstrip()
        marker = stripped[:3]
        if marker in {"```", "~~~"}:
            if fence is None:
                fence = marker
            elif fence == marker:
                fence = None
            continue
        if fence is None:
            visible.append((index, line))
    if fence is not None:
        return None
    return visible

def document_structure_checker(text):
    visible = visible_markdown_lines(text)
    if visible is None:
        return False, {"reason": "unterminated-fence"}
    exact_positions = {}
    for expected in heading_lines:
        positions = [index for index, line in visible if line == expected]
        if len(positions) != 1:
            return False, {"reason": "heading-cardinality", "heading": expected,
                           "count": len(positions)}
        exact_positions[expected] = positions[0]
    observed_heading_positions = [exact_positions[value] for value in heading_lines]
    if observed_heading_positions != sorted(observed_heading_positions):
        return False, {"reason": "heading-order"}

    section_start = observed_heading_positions[0]
    section_end = None
    for index, line in visible:
        if index <= section_start:
            continue
        if line.startswith("# "):
            section_end = index
            break
        if line.startswith("## V") and line not in heading_lines:
            section_end = index
            break
    if section_end is None:
        section_end = len(text.splitlines())
    if any(index >= section_end for index in observed_heading_positions):
        return False, {"reason": "heading-outside-v8-section"}

    section_visible = [
        (index, line) for index, line in visible
        if section_start <= index < section_end
    ]
    section_text = "\n".join(line for _, line in section_visible)
    observed_invariants = []
    invariant_rows = {}
    for _, line in section_visible:
        fields = [field.strip() for field in line.split("|")]
        if len(fields) >= 4 and fields[1].startswith("V8-I"):
            observed_invariants.append(fields[1])
            invariant_rows[fields[1]] = line
    if observed_invariants != invariant_ids:
        return False, {"reason": "invariant-id-census",
                       "observed": observed_invariants}

    topology_start = exact_positions[heading_lines[-1]]
    observed_topology = []
    for index, line in section_visible:
        if index <= topology_start:
            continue
        stripped = line.strip()
        prefix, separator, _ = stripped.partition(". ")
        if separator and prefix.isdigit():
            observed_topology.append(int(prefix))
    if observed_topology != topology_ordinals:
        return False, {"reason": "topology-ordinal-census",
                       "observed": observed_topology}

    for token in semantic_tokens[:3]:
        if token not in section_text:
            return False, {"reason": "semantic-token-missing", "token": token}
    invariant_i5 = invariant_rows["V8-I5"]
    for token in semantic_tokens[3:]:
        if token not in invariant_i5:
            return False, {"reason": "warning-token-missing-in-v8-i5",
                           "token": token}
    return True, {
        "section_start_line": section_start + 1,
        "section_end_line_exclusive": section_end + 1,
        "heading_ids": heading_ids,
        "heading_lines": heading_lines,
        "heading_line_numbers": [value + 1 for value in observed_heading_positions],
        "invariant_ids": observed_invariants,
        "topology_ordinals": observed_topology,
        "semantic_tokens_present": semantic_tokens,
        "stable_structure_id_sha256": structure_id_sha256,
        "parser": "fenced-code-aware-markdown-line-parser-v1",
    }

doc_pass, doc_structure = document_structure_checker(owner_text)
if not doc_pass:
    raise SystemExit("owner contract V8 structural freeze mismatch: " + repr(doc_structure))

def replace_line_once(text, expected, replacement):
    lines = text.splitlines(keepends=True)
    matches = [index for index, line in enumerate(lines) if line.rstrip("\r\n") == expected]
    if len(matches) != 1:
        raise SystemExit("directed doc mutation source line mismatch: " + expected)
    index = matches[0]
    newline = "\n" if lines[index].endswith("\n") else ""
    lines[index] = replacement + newline
    return "".join(lines)

missing_heading = replace_line_once(owner_text, heading_lines[1], "")
reordered_heading = owner_text.replace(heading_lines[1], "V8-HEADING-SWAP", 1)
reordered_heading = reordered_heading.replace(heading_lines[2], heading_lines[1], 1)
reordered_heading = reordered_heading.replace("V8-HEADING-SWAP", heading_lines[2], 1)
duplicate_heading = owner_text.replace(
    heading_lines[0] + "\n", heading_lines[0] + "\n" + heading_lines[0] + "\n", 1
)
missing_invariant = owner_text.replace("| V8-I3 |", "| V8-IX |", 1)
missing_topology = owner_text.replace(
    "9. **function/显式硬件**", "10. **function/显式硬件**", 1
)
i5_line = next(
    line for line in owner_text.splitlines() if line.startswith("| V8-I5 |")
)
changed_warning_numbers = replace_line_once(
    owner_text, i5_line, i5_line.replace("25", "24").replace("26", "27")
)

outside_lines = owner_text.splitlines(keepends=True)
visible_for_decoy = visible_markdown_lines(owner_text)
section_start_for_decoy = next(
    index for index, line in visible_for_decoy if line == heading_lines[0]
)
section_end_for_decoy = next(
    index for index, line in visible_for_decoy
    if index > section_start_for_decoy
    and line.startswith("## V")
    and line not in heading_lines
)
for index in range(section_start_for_decoy, section_end_for_decoy):
    outside_lines[index] = outside_lines[index].replace(
        "dst_nb3_ext_w[127:64]", "dst_nb3_ext_w[126:63]"
    )
outside_lines.insert(
    section_end_for_decoy + 1,
    "<!-- archival decoy: dst_nb3_ext_w[127:64] 64'd0 iova_reject_w -->\n",
)
outside_v8_archival_decoy = "".join(outside_lines)

document_mutations = {
    "missing_heading": missing_heading,
    "reordered_heading": reordered_heading,
    "duplicate_heading": duplicate_heading,
    "missing_invariant": missing_invariant,
    "missing_topology_item": missing_topology,
    "changed_warning_25_26": changed_warning_numbers,
    "comment_archival_decoy_outside_v8": outside_v8_archival_decoy,
}
document_mutations_rejected = {
    name: not document_structure_checker(mutant)[0]
    for name, mutant in document_mutations.items()
}
if not all(document_mutations_rejected.values()):
    raise SystemExit("V8 document structural mutation unexpectedly accepted")

atomic_write_json(
    output,
    {
        "schema": "qwen-f32-alu-families-compile-v13-compile-v7-root-fix-audit-v1",
        "task_id": "qwen-f32-alu-families-compile-v13",
        "pass": True,
        "compile_v7": {
            "contract_sha256": fixed[v7_contract],
            "material_sha256": fixed[v7_material],
            "runner_sha256": fixed[v7_runner],
            "preflight_receipt_sha256": receipt_sha,
            "preflight_manifest_sha256": manifest_sha,
            "preflight_binding_sha256": binding_sha,
            "preflight_status_sha256": fixed[v7_preflight_status],
            "preflight_snapshot_sha256": snapshot_sha,
            "preflight_bound_artifact_count": reopened["artifact_count"],
            "compile_status_sha256": fixed[v7_compile_status],
            "compile_status": expected_compile_status.decode().strip(),
            "configure_rc": 0,
            "build_rc": 0,
            "build_count": 1,
            "append_only_ledger_sha256": [ledger0_sha, ledger1_sha, ledger2_sha],
            "ordered_actions": ["cmake-configure", "cmake-build"],
            "binary_runs": 0,
            "model_runs": 0,
            "qwen_runs": 0,
            "synthesis": 0,
            "sta": 0,
            "ppa": 0,
            "expected_warning_rows": 25,
            "actual_warning_rows": 26,
            "warning_missing": [],
            "warning_extra": [list(item) for item in expected_extra],
            "other_diagnostics": [],
            "build_log_sha256": fixed[v7_build_log],
        },
        "production_change_scope": {
            "baseline_snapshot_sha256": snapshot_sha,
            "changed_paths": changed,
            "unchanged_frozen_paths": len(snapshot["files"]) - len(changed),
            "external_tool_count": len(snapshot["external"]),
            "owner_contract_sha256": fixed[owner_contract],
            "adapter_sha256": fixed[adapter],
        },
        "overflow_admission": {
            "module": "TensorNpuVectorF32Adapter",
            "signal": "dst_nb3_ext_w[127:64]",
            "predicate": "iova_reject_w",
            "exact_live_term_count": 1,
            "ports_changed": 0,
            "state_registers_added": 0,
            "fsm_states_added": 0,
            "gmem_owners_added": 0,
            "warning_waivers_added": 0,
            "dummy_consumers_added": 0,
            "mutations_rejected": mutations_rejected,
        },
        "phase_topology_freeze": {
            "whole_file_sha256": fixed[owner_contract],
            "stable_structure_id_sha256": structure_id_sha256,
            "structure": doc_structure,
            "heading_count": len(heading_ids),
            "invariant_count": len(invariant_ids),
            "topology_item_count": len(topology_ordinals),
            "document_mutations_rejected": document_mutations_rejected,
        },
        "warning_oracle": {
            "expected_tsv_sha256": fixed[warning_source],
            "expected_rows": 25,
            "updated_to_26": False,
        },
    },
)
PY
}

audit_compile_v6_failure() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V6_FAILURE_AUDIT" \
        "$COMPILE_V6_CONTRACT" "$COMPILE_V6_MATERIAL" "$COMPILE_V6_RUNNER" \
        "$COMPILE_V6_LOG_ROOT" "$COMPILE_V6_COMPILER_ROOT" \
        "$COMPILE_V6_BUILD_ROOT" "$COMPILE_V5_CONTRACT" "$COMPILE_V5_MATERIAL" \
        "$COMPILE_V5_RUNNER" "$COMPILE_V5_LOG_ROOT" \
        "$COMPILE_V5_COMPILER_ROOT" "$COMPILE_V5_BUILD_ROOT" <<'PY'
import hashlib
import json
import os
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json,
    read_bytes_stable,
    read_json_same_bytes,
)

(
    output,
    v6_contract,
    v6_material,
    v6_runner,
    v6_log_root,
    v6_compiler_root,
    v6_build_root,
    v5_contract,
    v5_material,
    v5_runner,
    v5_log_root,
    v5_compiler_root,
    v5_build_root,
) = map(pathlib.Path, sys.argv[3:16])

v6_status = v6_log_root / "preflight.status"
v6_count = v6_compiler_root / "staging/preflight-build.count"
v6_snapshot = v6_compiler_root / "staging/frozen-inputs.pre.json"
v5_status = v5_log_root / "preflight.status"
v5_count = v5_compiler_root / "staging/preflight-build.count"
v5_snapshot = v5_compiler_root / "staging/frozen-inputs.pre.json"

fixed = {
    v6_contract: "8737f230d7e0716717c9b4600e73c4dfe901bdce8c51b01e6d05fd1230ce09c3",
    v6_material: "63a00b5f172c964362a08d60b4fb098a30287e5a6a2267d95c93837d0e6005c3",
    v6_runner: "a42e48ca6f05037c06d54e000953306ab959a57d8945ab3f63ece8ca612c830a",
    v6_status: "be169b5dd1b5fd8f6f617470b21b9c4782cc49c69db6b6d2e9c83e707a76eeb5",
    v6_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v6_snapshot: "ca26791ab50b19bc6d1bda8d0422f82a6431fd89d6afcd5872fc6336d81f3308",
    v5_contract: "4dd365fc4858f9ecb0838a3f978321283ba378a2cb481f3715f6aaa2eb1b00f7",
    v5_material: "a47349d1bedf3c26f9fffad84a1eef2084b1ef019abb3663c75aa70235410f31",
    v5_runner: "c4c84db3e17d1bfa29fd31448b0d4f7df0c2d159ef88ea5b701a76f7b1de816c",
    v5_status: "e5b67181496437a35668c3bd1025b3e9e21e939d2f71ca29d5a03858bb8c5046",
    v5_count: "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa",
    v5_snapshot: "a0cbf76a8a5d392e436ae3852fc95cbe5193a93afdb04e742ad989cc846254cf",
}


def exact_tree(directory):
    observed_root = directory.lstat()
    if (
        not stat.S_ISDIR(observed_root.st_mode)
        or stat.S_ISLNK(observed_root.st_mode)
        or directory.resolve(strict=True) != directory.absolute()
    ):
        raise SystemExit("frozen evidence root missing/aliased: " + str(directory))
    directories = []
    regular_files = []
    fingerprints = {
        ".": [
            observed_root.st_dev,
            observed_root.st_ino,
            stat.S_IFMT(observed_root.st_mode),
            stat.S_IMODE(observed_root.st_mode),
            observed_root.st_nlink,
            observed_root.st_size,
            observed_root.st_mtime_ns,
            observed_root.st_ctime_ns,
        ]
    }
    for path in sorted(directory.rglob("*")):
        observed = path.lstat()
        relative = path.relative_to(directory).as_posix()
        if stat.S_ISLNK(observed.st_mode):
            raise SystemExit("frozen evidence tree symlink: " + str(path))
        if stat.S_ISDIR(observed.st_mode):
            directories.append(relative)
        elif stat.S_ISREG(observed.st_mode):
            regular_files.append(relative)
        else:
            raise SystemExit("frozen evidence tree special member: " + str(path))
        fingerprints[relative] = [
            observed.st_dev,
            observed.st_ino,
            stat.S_IFMT(observed.st_mode),
            stat.S_IMODE(observed.st_mode),
            observed.st_nlink,
            observed.st_size,
            observed.st_mtime_ns,
            observed.st_ctime_ns,
        ]
    return {
        "directory_membership": directories,
        "regular_file_membership": regular_files,
        "fingerprints": fingerprints,
    }


before = {
    "v6_log": exact_tree(v6_log_root),
    "v6_compiler": exact_tree(v6_compiler_root),
    "v5_log": exact_tree(v5_log_root),
    "v5_compiler": exact_tree(v5_compiler_root),
}

for path, expected in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("frozen predecessor file missing/aliased: " + str(path))
    if hashlib.sha256(read_bytes_stable(path)).hexdigest() != expected:
        raise SystemExit("frozen predecessor byte drift: " + str(path))

v6_contract_json = json.loads(read_bytes_stable(v6_contract))
v5_contract_json = json.loads(read_bytes_stable(v5_contract))
v6_snapshot_json, v6_snapshot_sha, _ = read_json_same_bytes(v6_snapshot)
v5_snapshot_json, v5_snapshot_sha, _ = read_json_same_bytes(v5_snapshot)
if (
    v6_contract_json.get("schema_version") != 2
    or v6_contract_json.get("task_id") != "qwen-f32-alu-families-compile-v6"
    or v6_contract_json.get("task_kind") != "verification"
    or v6_snapshot_json.get("schema")
       != "qwen-f32-alu-families-compile-v6-frozen-inputs-v1"
    or v6_snapshot_json.get("task_id") != "qwen-f32-alu-families-compile-v6"
    or v6_snapshot_sha != fixed[v6_snapshot]
):
    raise SystemExit("compile-v6 contract/snapshot schema mismatch")
if (
    v5_contract_json.get("schema_version") != 2
    or v5_contract_json.get("task_id") != "qwen-f32-alu-families-compile-v5"
    or v5_contract_json.get("task_kind") != "verification"
    or v5_snapshot_json.get("schema")
       != "qwen-f32-alu-families-compile-v5-frozen-inputs-v1"
    or v5_snapshot_json.get("task_id") != "qwen-f32-alu-families-compile-v5"
    or v5_snapshot_sha != fixed[v5_snapshot]
):
    raise SystemExit("compile-v5 contract/snapshot schema mismatch")

v6_expected_status = (
    b"FAIL rc=1 stage=preflight-compile-v5-failure-closure "
    b"evidence_complete=0 cleanup_rc=0\n"
)
v5_expected_status = (
    b"FAIL rc=1 stage=preflight-compile-v4-failure-closure "
    b"evidence_complete=0 cleanup_rc=0\n"
)
if read_bytes_stable(v6_status) != v6_expected_status:
    raise SystemExit("compile-v6 failure status semantic mismatch")
if read_bytes_stable(v5_status) != v5_expected_status:
    raise SystemExit("compile-v5 failure status semantic mismatch")
if read_bytes_stable(v6_count) != b"0\n" or read_bytes_stable(v5_count) != b"0\n":
    raise SystemExit("predecessor preflight build count is not zero")
if os.path.lexists(v6_build_root) or os.path.lexists(v5_build_root):
    raise SystemExit("predecessor build root unexpectedly exists")

after = {
    "v6_log": exact_tree(v6_log_root),
    "v6_compiler": exact_tree(v6_compiler_root),
    "v5_log": exact_tree(v5_log_root),
    "v5_compiler": exact_tree(v5_compiler_root),
}
if before != after:
    raise SystemExit("predecessor direct census changed between windows")

expected_log = {
    "directory_membership": [],
    "regular_file_membership": ["preflight.status"],
}
expected_compiler = {
    "directory_membership": ["sealed", "staging", "work"],
    "regular_file_membership": [
        "staging/frozen-inputs.pre.json",
        "staging/preflight-build.count",
    ],
}
for name in ("v6_log", "v5_log"):
    for key, expected in expected_log.items():
        if after[name][key] != expected:
            raise SystemExit(name + " direct census mismatch key=" + key)
for name in ("v6_compiler", "v5_compiler"):
    for key, expected in expected_compiler.items():
        if after[name][key] != expected:
            raise SystemExit(name + " direct census mismatch key=" + key)

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v6-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "admission_method": "whole-runner-sha-status-schema-and-direct-filesystem-census",
    "bash_function_boundary_inference": False,
    "census_windows": 2,
    "compile_v6": {
        "contract_sha256": fixed[v6_contract],
        "material_sha256": fixed[v6_material],
        "runner_sha256": fixed[v6_runner],
        "preflight_status_sha256": fixed[v6_status],
        "preflight_build_count_sha256": fixed[v6_count],
        "preflight_snapshot_sha256": fixed[v6_snapshot],
        "status": v6_expected_status.decode().strip(),
        "raw_marker": (
            "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V6][FAIL] "
            "compile-v5 directory/file census conflation proof mismatch"
        ),
        "root_cause": (
            "regex-based Bash function extraction terminated inside a Python heredoc"
        ),
        "build_count": 0,
        "build_root_absent": True,
        "cmake_version": 0,
        "cmake_configure": 0,
        "cmake_build": 0,
        "verilator": 0,
        "make": 0,
        "binary_runs": 0,
        "model_runs": 0,
        "qwen_runs": 0,
        "synthesis": 0,
        "sta": 0,
        "ppa": 0,
        "collect_executed": False,
        "classifier_regression_executed": False,
        "ledger_regression_executed": False,
        "log_census": after["v6_log"],
        "compiler_census": after["v6_compiler"],
    },
    "compile_v5": {
        "contract_sha256": fixed[v5_contract],
        "material_sha256": fixed[v5_material],
        "runner_sha256": fixed[v5_runner],
        "preflight_status_sha256": fixed[v5_status],
        "preflight_build_count_sha256": fixed[v5_count],
        "preflight_snapshot_sha256": fixed[v5_snapshot],
        "status": v5_expected_status.decode().strip(),
        "build_count": 0,
        "build_root_absent": True,
        "log_census": after["v5_log"],
        "compiler_census": after["v5_compiler"],
    },
})
PY
}

audit_compile_v4_classifier() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V4_CLASSIFIER_AUDIT" \
        "$COMPILE_V4_CONTRACT" "$COMPILE_V4_MATERIAL" "$COMPILE_V4_RUNNER" \
        "$COMPILE_V4_LOG_ROOT" "$COMPILE_V4_COMPILER_ROOT" \
        "$COMPILE_V4_BUILD_ROOT" <<'PY'
import hashlib
import os
import pathlib
import shutil
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import atomic_write_json, read_bytes_stable

output, contract, material, runner, log_root, compiler_root, build_root = map(
    pathlib.Path, sys.argv[3:10]
)
status_path = log_root / "preflight.status"
count_path = compiler_root / "staging/preflight-build.count"
expected_directories = {"sealed", "staging", "work"}
expected_regular_files = {"staging/preflight-build.count"}
expected_count_sha256 = "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"

fixed = {
    contract: "bafa967a2f92be4a412fada106ee5b3fb7343ccf5d3ef24953c4bb87c6584a62",
    material: "b778196d1e3d7a22164f164bd9a6a278640bfd87b9c20d38ce7ea3c9ee0b898c",
    runner: "83a859278c4a4976e8704707d331e424695b8f1c894be30c3b34fe453f42cbc7",
    status_path: "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51",
    count_path: expected_count_sha256,
}
for path, expected in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("compile-v4 frozen evidence missing/aliased: " + str(path))
    if hashlib.sha256(read_bytes_stable(path)).hexdigest() != expected:
        raise SystemExit("compile-v4 frozen evidence byte drift: " + str(path))

expected_status = (
    b"FAIL rc=1 stage=preflight-frozen-hash-admission "
    b"evidence_complete=0 cleanup_rc=0\n"
)
if read_bytes_stable(status_path) != expected_status:
    raise SystemExit("compile-v4 failure status semantic mismatch")
if os.path.lexists(build_root):
    raise SystemExit("compile-v4 build root unexpectedly exists")

def fingerprint(observed):
    return {
        "device": observed.st_dev,
        "inode": observed.st_ino,
        "file_type": stat.S_IFMT(observed.st_mode),
        "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
        "nlink": observed.st_nlink,
        "size": observed.st_size,
        "mtime_ns": observed.st_mtime_ns,
        "ctime_ns": observed.st_ctime_ns,
    }

def rejected(reason, **details):
    return {"accepted": False, "reason": reason, **details}

def census_tree(path):
    try:
        root_stat = path.lstat()
    except OSError as exc:
        return None, rejected("ambiguous-root-lstat", error=type(exc).__name__)
    if stat.S_ISLNK(root_stat.st_mode):
        return None, rejected("symlink-root")
    if not stat.S_ISDIR(root_stat.st_mode):
        return None, rejected("non-directory-root")
    try:
        if path.resolve(strict=True) != path.absolute():
            return None, rejected("aliased-root")
    except OSError as exc:
        return None, rejected("ambiguous-root-resolution", error=type(exc).__name__)

    directories = {}
    regular_files = {}
    inode_owners = {(root_stat.st_dev, root_stat.st_ino): "."}
    pending = [path]
    while pending:
        current = pending.pop()
        try:
            entries = sorted(os.scandir(current), key=lambda item: item.name)
        except OSError as exc:
            return None, rejected(
                "ambiguous-member-census", path=str(current), error=type(exc).__name__
            )
        for entry in entries:
            member = pathlib.Path(entry.path)
            relative = member.relative_to(path).as_posix()
            try:
                observed = member.lstat()
            except OSError as exc:
                return None, rejected(
                    "ambiguous-member-lstat", path=relative, error=type(exc).__name__
                )
            if stat.S_ISLNK(observed.st_mode):
                return None, rejected("symlink-member", path=relative)
            inode_key = (observed.st_dev, observed.st_ino)
            if inode_key in inode_owners:
                return None, rejected(
                    "aliased-member", path=relative, alias_of=inode_owners[inode_key]
                )
            inode_owners[inode_key] = relative
            if stat.S_ISDIR(observed.st_mode):
                directories[relative] = fingerprint(observed)
                pending.append(member)
            elif stat.S_ISREG(observed.st_mode):
                regular_files[relative] = fingerprint(observed)
            else:
                return None, rejected("special-member", path=relative)
    return {
        "root": fingerprint(root_stat),
        "directories": directories,
        "regular_files": regular_files,
    }, None

def classify_compile_v4_root(path, between_windows=None):
    first, first_error = census_tree(path)
    if first_error is not None:
        return first_error
    first_dirs = set(first["directories"])
    first_files = set(first["regular_files"])
    if expected_regular_files & first_dirs or expected_directories & first_files:
        return rejected(
            "file-directory-class-collision",
            directories=sorted(first_dirs),
            regular_files=sorted(first_files),
        )
    if first_dirs != expected_directories:
        return rejected(
            "directory-membership-mismatch",
            directories=sorted(first_dirs),
            expected=sorted(expected_directories),
        )
    if first_files != expected_regular_files:
        return rejected(
            "regular-file-membership-mismatch",
            regular_files=sorted(first_files),
            expected=sorted(expected_regular_files),
        )

    candidate_count = path / "staging/preflight-build.count"
    try:
        first_count_bytes = read_bytes_stable(candidate_count)
    except (OSError, RuntimeError) as exc:
        return rejected("ambiguous-count-read", error=type(exc).__name__)
    first_count_sha = hashlib.sha256(first_count_bytes).hexdigest()
    if first_count_bytes != b"0\n":
        return rejected("count-bytes-mismatch", count_sha256=first_count_sha)
    if first_count_sha != expected_count_sha256:
        return rejected("count-hash-mismatch", count_sha256=first_count_sha)

    if between_windows is not None:
        between_windows()
    second, second_error = census_tree(path)
    if second_error is not None:
        return rejected("second-window-rejected", second_window=second_error)
    if first != second:
        return rejected(
            "census-window-drift",
            first_directories=sorted(first["directories"]),
            second_directories=sorted(second["directories"]),
            first_regular_files=sorted(first["regular_files"]),
            second_regular_files=sorted(second["regular_files"]),
        )
    try:
        second_count_bytes = read_bytes_stable(candidate_count)
    except (OSError, RuntimeError) as exc:
        return rejected("ambiguous-second-count-read", error=type(exc).__name__)
    second_count_sha = hashlib.sha256(second_count_bytes).hexdigest()
    if second_count_bytes != first_count_bytes or second_count_sha != first_count_sha:
        return rejected("count-window-drift", count_sha256=second_count_sha)
    return {
        "accepted": True,
        "reason": "exact-directory-and-regular-file-census",
        "directory_membership": sorted(first_dirs),
        "regular_file_membership": sorted(first_files),
        "count_bytes": "0\\n",
        "count_sha256": first_count_sha,
        "census_windows": 2,
        "fingerprint_stable": True,
    }

fixtures = output.parent / "compile-v4-classifier-regression-fixtures"
if os.path.lexists(fixtures):
    raise SystemExit("compile-v4 classifier fixture root already exists")
fixtures.mkdir(mode=0o700)

def make_exact(name, count_bytes=b"0\n"):
    candidate = fixtures / name
    (candidate / "sealed").mkdir(parents=True, mode=0o700)
    (candidate / "staging").mkdir(mode=0o700)
    (candidate / "work").mkdir(mode=0o700)
    (candidate / "staging/preflight-build.count").write_bytes(count_bytes)
    return candidate

try:
    exact = make_exact("exact")
    missing_directory = make_exact("missing-directory")
    (missing_directory / "work").rmdir()
    extra_directory = make_exact("extra-directory")
    (extra_directory / "extra").mkdir(mode=0o700)
    renamed_directory = make_exact("renamed-directory")
    (renamed_directory / "work").rename(renamed_directory / "workspace")
    extra_member = make_exact("extra-member")
    (extra_member / "unexpected.bin").write_bytes(b"extra\n")
    nested_member = make_exact("nested-member")
    (nested_member / "sealed/nested").mkdir(mode=0o700)
    (nested_member / "sealed/nested/value").write_bytes(b"nested\n")
    symlink_target = fixtures / "symlink-target"
    symlink_target.mkdir(mode=0o700)
    symlink_member = make_exact("symlink-member")
    (symlink_member / "sealed/alias").symlink_to(symlink_target, target_is_directory=True)
    class_collision = make_exact("class-collision")
    (class_collision / "staging/preflight-build.count").unlink()
    (class_collision / "staging/preflight-build.count").mkdir(mode=0o700)
    changed_count = make_exact("changed-count", b"1\n")
    substituted = make_exact("two-window-substitution")
    replacement_count = fixtures / "replacement-count"
    replacement_count.write_bytes(b"0\n")

    def substitute_between_windows():
        os.replace(replacement_count, substituted / "staging/preflight-build.count")

    symlink_root_target = make_exact("symlink-root-target")
    symlink_root = fixtures / "symlink-root"
    symlink_root.symlink_to(symlink_root_target, target_is_directory=True)
    regression = {
        "exact": classify_compile_v4_root(exact),
        "missing_directory": classify_compile_v4_root(missing_directory),
        "extra_directory": classify_compile_v4_root(extra_directory),
        "renamed_directory": classify_compile_v4_root(renamed_directory),
        "extra_member": classify_compile_v4_root(extra_member),
        "nested_member": classify_compile_v4_root(nested_member),
        "symlink_member": classify_compile_v4_root(symlink_member),
        "file_directory_class_collision": classify_compile_v4_root(class_collision),
        "changed_count_bytes": classify_compile_v4_root(changed_count),
        "two_window_substitution": classify_compile_v4_root(
            substituted, substitute_between_windows
        ),
        "symlink_root": classify_compile_v4_root(symlink_root),
    }
finally:
    shutil.rmtree(fixtures)

expected_acceptance = {name: name == "exact" for name in regression}
observed_acceptance = {
    name: result.get("accepted") for name, result in regression.items()
}
if observed_acceptance != expected_acceptance:
    raise SystemExit("compile-v4 classifier regression acceptance mismatch")
if regression["two_window_substitution"].get("reason") != "census-window-drift":
    raise SystemExit("compile-v4 two-window substitution was not rejected as drift")
if regression["changed_count_bytes"].get("reason") != "count-bytes-mismatch":
    raise SystemExit("compile-v4 changed count bytes were not rejected")
if regression["file_directory_class_collision"].get("reason") != (
    "file-directory-class-collision"
):
    raise SystemExit("compile-v4 file/directory class collision was not rejected")
if regression["symlink_member"].get("reason") != "symlink-member":
    raise SystemExit("compile-v4 symlink member was not rejected")

classification = classify_compile_v4_root(compiler_root)
if classification.get("accepted") is not True:
    raise SystemExit("compile-v4 immutable classifier rejected: " + repr(classification))

def exact_log_tree(directory):
    observed = directory.lstat()
    if (
        not stat.S_ISDIR(observed.st_mode)
        or stat.S_ISLNK(observed.st_mode)
        or directory.resolve(strict=True) != directory.absolute()
    ):
        raise SystemExit("compile-v4 log root missing/aliased")
    members = []
    for path in directory.rglob("*"):
        item = path.lstat()
        if not stat.S_ISREG(item.st_mode) or stat.S_ISLNK(item.st_mode):
            raise SystemExit("compile-v4 log root member is not a regular file")
        members.append(path.relative_to(directory).as_posix())
    return sorted(members)

if exact_log_tree(log_root) != ["preflight.status"]:
    raise SystemExit("compile-v4 log-root exact membership mismatch")

source = read_bytes_stable(runner).decode("utf-8")
reject = 'path_absent "$COMPILE_V3_BUILD_ROOT" || fail "compile-v3 immutable build root exists"'
snapshot_stage = 'task_run_status_stage "preflight-input-snapshot"'
if source.count(reject) != 1 or source.count(snapshot_stage) != 1:
    raise SystemExit("compile-v4 predecessor admission control-flow marker mismatch")
if source.index(reject) >= source.index(snapshot_stage):
    raise SystemExit("compile-v4 failure predicate was not before input snapshot")

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v4-classifier-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "compile_v4": {
        "contract_sha256": fixed[contract],
        "material_sha256": fixed[material],
        "runner_sha256": fixed[runner],
        "preflight_status_sha256": fixed[status_path],
        "preflight_build_count_sha256": fixed[count_path],
        "status": expected_status.decode().strip(),
        "build_count": 0,
        "build_root_absent": True,
        "cmake_version": 0,
        "cmake_configure": 0,
        "cmake_build": 0,
        "verilator": 0,
        "make": 0,
        "binary_runs": 0,
        "model_runs": 0,
        "qwen_runs": 0,
        "synthesis": 0,
        "sta": 0,
        "ppa": 0,
        "collect_executed": False,
        "directory_membership": classification["directory_membership"],
        "regular_file_membership": classification["regular_file_membership"],
        "count_bytes": classification["count_bytes"],
        "count_sha256": classification["count_sha256"],
        "census_windows": classification["census_windows"],
        "fingerprint_stable": classification["fingerprint_stable"],
        "classifier_regression": regression,
        "classifier_regression_acceptance": expected_acceptance,
        "classifier_regression_passed": len(regression),
        "classifier_regression_total": len(regression),
        "external_action_count": 0,
    },
})
PY
}

audit_compile_v3_failure() {
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$COMPILE_V3_FAILURE_AUDIT" \
        "$COMPILE_V3_LOG_ROOT" "$COMPILE_V3_COMPILER_ROOT" \
        "$COMPILE_V3_BUILD_ROOT" "$COMPILE_V3_RUNNER" <<'PY'
import hashlib
import os
import pathlib
import shutil
import stat
import sys

root = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, sys.argv[2])
from qwen_f32_alu_build_identity import (
    atomic_write_json,
    read_bytes_stable,
    read_json_same_bytes,
    revalidate_bound_artifacts,
)

output = pathlib.Path(sys.argv[3])
log_root = pathlib.Path(sys.argv[4])
compiler_root = pathlib.Path(sys.argv[5])
build_root = pathlib.Path(sys.argv[6])
runner_path = pathlib.Path(sys.argv[7])

fixed = {
    root / "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v3.json":
        "581ca491054d997a210b9cbc1de6776d6117978981710a09fc2d180c6d1654e6",
    root / "npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v3-material.md":
        "6ff06cd9ca76a879735d7a3a1fe7eceb0765afb678cf73638f3d295e11036da2",
    runner_path:
        "537bdef17dd05e8b572b889c2694943385b442ba55ce3422d562284808531c74",
    log_root / "preflight.receipt.json":
        "6b98f0fcbccd47d461225672a7e578c9f6f89ced8e5155412e3f6717a6bff5d6",
    log_root / "preflight.bound-artifacts.json":
        "ddac7e7d0dc47e566d6939bd1a8281da1327c11786e3e154e0a3b9120d2665d7",
    log_root / "preflight.final-binding.json":
        "c3940df9a218d3ac1b93b82467fa7f9411c7863d6cc17f35bde87b0cc03561d3",
    log_root / "preflight.status":
        "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431",
    log_root / "compile.status":
        "2856e07c603ed85e496181f60f17540d1f3cf89687752ff5ea50dc7fcf26e663",
    log_root / "cmake-configure.argv.json":
        "d2079ae5d3a9fa818efd87e7ea7c7b95b47a6e79d4afc14db7536d7cea5e4516",
    compiler_root / "collect-inputs.pre.json":
        "022195ce62b7f4044437030bac025d9443dd312c5bd63c431c5cd31829930f12",
    compiler_root / "collect-build.count":
        "4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865",
    compiler_root / "collect-action-ledger.json":
        "d1fffeac1a381827fd6aefe4c54752b0226ba4f3cbf8deea85e3f986db09c59c",
}
for path, expected in fixed.items():
    observed = path.lstat()
    if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
        raise SystemExit("compile-v3 frozen evidence missing/aliased: " + str(path))
    if hashlib.sha256(read_bytes_stable(path)).hexdigest() != expected:
        raise SystemExit("compile-v3 frozen evidence byte drift: " + str(path))

receipt, receipt_sha, _ = read_json_same_bytes(log_root / "preflight.receipt.json")
manifest, manifest_sha, _ = read_json_same_bytes(log_root / "preflight.bound-artifacts.json")
binding, binding_sha, _ = read_json_same_bytes(log_root / "preflight.final-binding.json")
snapshot_path = compiler_root / (
    "sealed/frozen-inputs."
    "022195ce62b7f4044437030bac025d9443dd312c5bd63c431c5cd31829930f12.json"
)
snapshot, snapshot_sha, _ = read_json_same_bytes(snapshot_path)
if (
    receipt_sha != fixed[log_root / "preflight.receipt.json"]
    or manifest_sha != fixed[log_root / "preflight.bound-artifacts.json"]
    or binding_sha != fixed[log_root / "preflight.final-binding.json"]
    or snapshot_sha !=
       "022195ce62b7f4044437030bac025d9443dd312c5bd63c431c5cd31829930f12"
    or read_bytes_stable(log_root / "preflight.status") != b"PASS\n"
    or read_bytes_stable(log_root / "preflight.expected-status") != b"PASS\n"
    or read_bytes_stable(log_root / "preflight.receipt.sha256") !=
       f"{receipt_sha}  preflight.receipt.json\n".encode()
):
    raise SystemExit("compile-v3 preflight identity/status closure mismatch")
if (
    receipt.get("schema") != "qwen-f32-alu-families-compile-v3-preflight-receipt-v1"
    or receipt.get("task_id") != "qwen-f32-alu-families-compile-v3"
    or receipt.get("build_count") != 0
    or receipt.get("build_root_absent") is not True
    or receipt.get("actual_configured_argv") != "GAP"
    or receipt.get("compile_membership_status") != "GAP"
    or receipt.get("invocations", {}).get("cmake_configure") != 0
    or receipt.get("invocations", {}).get("cmake_build") != 0
    or receipt.get("invocations", {}).get("binary") != 0
    or receipt.get("evidence_complete") != 1
):
    raise SystemExit("compile-v3 preflight semantic boundary mismatch")
if (
    manifest.get("receipt_sha256") != receipt_sha
    or binding.get("receipt_sha256") != receipt_sha
    or binding.get("bound_artifacts_sha256") != manifest_sha
    or binding.get("content_addressed_snapshot_sha256") != snapshot_sha
):
    raise SystemExit("compile-v3 preflight binding mismatch")
revalidate_bound_artifacts(root, manifest["artifacts"])

collect_snapshot, collect_snapshot_sha, _ = read_json_same_bytes(
    compiler_root / "collect-inputs.pre.json"
)
if collect_snapshot_sha != snapshot_sha or collect_snapshot != snapshot:
    raise SystemExit("compile-v3 collect/preflight input snapshot mismatch")
if read_bytes_stable(log_root / "compile.status") != (
    b"FAIL rc=1 stage=collect-cmake-configure evidence_complete=0 cleanup_rc=0\n"
):
    raise SystemExit("compile-v3 failure status mismatch")
if read_bytes_stable(compiler_root / "collect-build.count") != b"1\n":
    raise SystemExit("compile-v3 attempted build-count identity mismatch")

argv = read_json_same_bytes(log_root / "cmake-configure.argv.json")[0]
expected_argv = [
    "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/tools/cmake-3.31.12/bin/cmake",
    "-S", "/home/lyg/PA/ysyx-workbench/npu/version_0820/runtime/llama-npu-backend",
    "-B", "/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/build/"
          "qwen-f32-alu-families-compile-v3/cmake",
    "-G", "Unix Makefiles", "-DCMAKE_BUILD_TYPE=Release",
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "-DCMAKE_VERBOSE_MAKEFILE=ON",
    "-DCMAKE_CXX_COMPILER=/usr/bin/c++", "-DCMAKE_AR=/usr/bin/ar",
    "-DCMAKE_RANLIB=/usr/bin/ranlib", "-DCMAKE_MAKE_PROGRAM=/usr/bin/make",
    "-DVERILATOR_EXECUTABLE=/usr/bin/verilator",
    "-DNPU_VERILATED_MDIR=/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/build/"
    "qwen-f32-alu-families-compile-v3/verilated",
    "-DNPU_VERILATOR_JOBS=1", "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG",
]
if (
    argv.get("schema") != "qwen-f32-alu-families-compile-v3-actual-argv-v1"
    or argv.get("kind") != "cmake-configure"
    or argv.get("cwd") != str(root)
    or argv.get("argv") != expected_argv
    or argv.get("executable_sha256") !=
       "d8ed20c9688adaf5ee8d387072424aa732c5f589e860347e0dfa51cca37dc863"
):
    raise SystemExit("compile-v3 sealed configure argv mismatch")

ledger = read_json_same_bytes(compiler_root / "collect-action-ledger.json")[0]
zero_counts = {
    "cmake-configure": 0, "cmake-build": 0, "binary": 0, "model": 0,
    "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0,
}
if (
    ledger.get("schema") != "qwen-f32-alu-families-compile-v3-action-ledger-v1"
    or ledger.get("task_id") != "qwen-f32-alu-families-compile-v3"
    or ledger.get("counts") != zero_counts
    or ledger.get("ordered_actions") != []
):
    raise SystemExit("compile-v3 initial ledger semantic mismatch")

runner_source = read_bytes_stable(runner_path).decode("utf-8")
initial_writer = "atomic_write_json(pathlib.Path(sys.argv[2])"
second_writer = "atomic_write_json(ledger_path, ledger)"
if runner_source.count(initial_writer) != 1 or runner_source.count(second_writer) != 1:
    raise SystemExit("compile-v3 whole-runner ledger writer token mismatch")

def regular_files(directory):
    values = set()
    for path in directory.rglob("*"):
        observed = path.lstat()
        if stat.S_ISDIR(observed.st_mode) and not stat.S_ISLNK(observed.st_mode):
            continue
        if not stat.S_ISREG(observed.st_mode) or stat.S_ISLNK(observed.st_mode):
            raise SystemExit("compile-v3 evidence tree alias/special: " + str(path))
        values.add(path.relative_to(root).as_posix())
    return values

manifest_paths = set(manifest["artifacts"])
log_prefix = log_root.relative_to(root).as_posix() + "/"
compiler_prefix = compiler_root.relative_to(root).as_posix() + "/"
expected_log_files = {path for path in manifest_paths if path.startswith(log_prefix)}
expected_log_files.update({
    log_prefix + "preflight.bound-artifacts.json",
    log_prefix + "preflight.expected-status",
    log_prefix + "preflight.final-binding.json",
    log_prefix + "preflight.status",
    log_prefix + "compile.status",
    log_prefix + "cmake-configure.argv.json",
})
expected_compiler_files = {
    path for path in manifest_paths if path.startswith(compiler_prefix)
}
expected_compiler_files.update({
    compiler_prefix + "collect-action-ledger.json",
    compiler_prefix + "collect-build.count",
    compiler_prefix + "collect-inputs.pre.json",
})
if regular_files(log_root) != expected_log_files:
    raise SystemExit("compile-v3 log-root exact membership mismatch")
if regular_files(compiler_root) != expected_compiler_files:
    raise SystemExit("compile-v3 compiler-root exact membership mismatch")

def root_fingerprint(observed):
    return {
        "device": observed.st_dev,
        "inode": observed.st_ino,
        "file_type": stat.S_IFMT(observed.st_mode),
        "mode": f"{stat.S_IMODE(observed.st_mode):04o}",
        "nlink": observed.st_nlink,
        "size": observed.st_size,
        "mtime_ns": observed.st_mtime_ns,
        "ctime_ns": observed.st_ctime_ns,
    }

def classify_predecessor_build_root(path, between_scans=None):
    try:
        observed_before = path.lstat()
    except FileNotFoundError:
        return {
            "accepted": True,
            "state": "absent",
            "reason": "path-absent",
            "entry_count": 0,
            "census_windows": 2,
            "fingerprint_stable": True,
        }
    except OSError as exc:
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "ambiguous-lstat",
            "error": type(exc).__name__,
        }
    if stat.S_ISLNK(observed_before.st_mode):
        return {"accepted": False, "state": "rejected", "reason": "symlink-root"}
    if not stat.S_ISDIR(observed_before.st_mode):
        return {"accepted": False, "state": "rejected", "reason": "non-directory-root"}
    try:
        resolved = path.resolve(strict=True)
    except OSError as exc:
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "ambiguous-resolution",
            "error": type(exc).__name__,
        }
    if resolved != path.absolute():
        return {"accepted": False, "state": "rejected", "reason": "aliased-root"}

    def census():
        try:
            return sorted(entry.name for entry in os.scandir(path)), path.lstat()
        except OSError as exc:
            return exc, None

    first_entries, first_stat = census()
    if isinstance(first_entries, OSError):
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "ambiguous-first-census",
            "error": type(first_entries).__name__,
        }
    if between_scans is not None:
        between_scans()
    second_entries, second_stat = census()
    if isinstance(second_entries, OSError):
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "ambiguous-second-census",
            "error": type(second_entries).__name__,
        }
    fingerprint_before = root_fingerprint(observed_before)
    fingerprint_first = root_fingerprint(first_stat)
    fingerprint_second = root_fingerprint(second_stat)
    if (
        first_entries != second_entries
        or fingerprint_before != fingerprint_first
        or fingerprint_first != fingerprint_second
    ):
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "ambiguous-census",
            "first_entries": first_entries,
            "second_entries": second_entries,
            "fingerprint_stable": False,
        }
    if first_entries:
        return {
            "accepted": False,
            "state": "rejected",
            "reason": "nonempty-root",
            "entries": first_entries,
            "entry_count": len(first_entries),
            "census_windows": 2,
            "fingerprint_stable": True,
        }
    return {
        "accepted": True,
        "state": "empty-created-before-command",
        "reason": "exact-empty-directory-census",
        "entry_count": 0,
        "census_windows": 2,
        "fingerprint_stable": True,
        "root_fingerprint": fingerprint_second,
    }

fixture_root = output.parent / "predecessor-root-regression-fixtures"
if os.path.lexists(fixture_root):
    raise SystemExit("predecessor root regression fixture already exists")
fixture_root.mkdir(mode=0o700)
try:
    empty_target = fixture_root / "empty-target"
    empty_target.mkdir(mode=0o700)
    exact_empty = fixture_root / "exact-empty"
    exact_empty.mkdir(mode=0o700)
    file_root = fixture_root / "file-root"
    file_root.write_bytes(b"not-a-directory\n")
    symlink_root = fixture_root / "symlink-root"
    symlink_root.symlink_to(empty_target, target_is_directory=True)
    nested_root = fixture_root / "nested-root"
    nested_root.mkdir(mode=0o700)
    (nested_root / "child").mkdir(mode=0o700)
    ambiguous_root = fixture_root / "ambiguous-root"
    ambiguous_root.mkdir(mode=0o700)

    def mutate_between_census_windows():
        (ambiguous_root / "appeared-between-windows").write_bytes(b"mutation\n")

    root_regression = {
        "absent": classify_predecessor_build_root(fixture_root / "absent-root"),
        "exact_empty": classify_predecessor_build_root(exact_empty),
        "file": classify_predecessor_build_root(file_root),
        "symlink": classify_predecessor_build_root(symlink_root),
        "nested_entry": classify_predecessor_build_root(nested_root),
        "ambiguous": classify_predecessor_build_root(
            ambiguous_root, mutate_between_census_windows
        ),
    }
finally:
    shutil.rmtree(fixture_root)

expected_acceptance = {
    "absent": True,
    "exact_empty": True,
    "file": False,
    "symlink": False,
    "nested_entry": False,
    "ambiguous": False,
}
if {
    name: result.get("accepted") for name, result in root_regression.items()
} != expected_acceptance:
    raise SystemExit("predecessor build-root classifier regression mismatch")
if root_regression["absent"].get("state") != "absent":
    raise SystemExit("absent predecessor root classifier state mismatch")
if root_regression["exact_empty"].get("state") != "empty-created-before-command":
    raise SystemExit("exact-empty predecessor root classifier state mismatch")
if root_regression["ambiguous"].get("reason") != "ambiguous-census":
    raise SystemExit("ambiguous predecessor root census mutation was not rejected")

build_root_classification = classify_predecessor_build_root(build_root)
if build_root_classification.get("accepted") is not True:
    raise SystemExit(
        "compile-v3 predecessor build root rejected: " + repr(build_root_classification)
    )

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-compile-v3-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "compile_v3": {
        "contract_sha256": fixed[root / "npu/version_0820/tmp/contracts/"
                                   "qwen-f32-alu-families-compile-v3.json"],
        "material_sha256": fixed[root / "npu/version_0820/tmp/contracts/"
                                   "qwen-f32-alu-families-compile-v3-material.md"],
        "runner_sha256": fixed[runner_path],
        "preflight_receipt_sha256": receipt_sha,
        "preflight_manifest_sha256": manifest_sha,
        "preflight_binding_sha256": binding_sha,
        "preflight_snapshot_sha256": snapshot_sha,
        "preflight_status_sha256": fixed[log_root / "preflight.status"],
        "compile_status_sha256": fixed[log_root / "compile.status"],
        "configure_argv_sha256": fixed[log_root / "cmake-configure.argv.json"],
        "collect_snapshot_sha256": collect_snapshot_sha,
        "build_count_sha256": fixed[compiler_root / "collect-build.count"],
        "initial_ledger_sha256": fixed[compiler_root / "collect-action-ledger.json"],
        "status": "FAIL rc=1 stage=collect-cmake-configure evidence_complete=0 cleanup_rc=0",
        "build_count": 1,
        "cmake_configure_executed": 0,
        "cmake_build_executed": 0,
        "binary_runs": 0,
        "model_runs": 0,
        "qwen_runs": 0,
        "synthesis": 0,
        "sta": 0,
        "ppa": 0,
        "build_root_state": build_root_classification["state"],
        "build_root_admissible": True,
        "build_root_entry_count": build_root_classification["entry_count"],
        "build_root_census_windows": build_root_classification["census_windows"],
        "build_root_fingerprint_stable":
            build_root_classification["fingerprint_stable"],
        "root_classifier_regression": root_regression,
        "root_classifier_regression_acceptance": expected_acceptance,
        "external_action_count": 0,
        "root_cause": "same fresh-only ledger output used by two atomic_write_json calls",
        "failure_before_subshell_execution": True,
        "log_file_count": len(expected_log_files),
        "compiler_file_count": len(expected_compiler_files),
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
    "schema": "qwen-f32-alu-families-compile-v13-cmake-tool-v4-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
    "schema": "qwen-f32-alu-families-compile-v13-warning-oracle-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
snapshot_assignments = re.findall(
    r'(?m)^COLLECT_ACTION_LEDGER_([012])="\$COMPILER_ROOT/'
    r'(collect-action-ledger\.[012]\.json)"$', source
)
if snapshot_assignments != [
    ("0", "collect-action-ledger.0.json"),
    ("1", "collect-action-ledger.1.json"),
    ("2", "collect-action-ledger.2.json"),
]:
    raise SystemExit("collect snapshot filename/cardinality mismatch")
writer_blocks = re.findall(
    r'(?ms)^[ \t]*\# COLLECT_LEDGER_WRITERS_BEGIN[ \t]*$\n(.*?)'
    r'^[ \t]*\# COLLECT_LEDGER_WRITERS_END[ \t]*$', source
)
if len(writer_blocks) != 1:
    raise SystemExit("collect ledger writer sentinel cardinality mismatch")
writers = writer_blocks[0]
if (
    writers.count("atomic_write_json(pathlib.Path(sys.argv[2]), initial)") != 1
    or writers.count("atomic_write_json(output_path, next_ledger)") != 1
    or "atomic_write_json(prior_path" in writers
    or "atomic_write_json(ledger_path" in writers
    or writers.count('"cmake-configure": (ledger0, ledger1, 0, 1)') != 1
    or writers.count('"cmake-build": (ledger1, ledger2, 1, 2)') != 1
):
    raise SystemExit("collect ledger single-writer/static transition mismatch")
atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-collect-policy-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
    "snapshot_filenames": [
        "collect-action-ledger.0.json",
        "collect-action-ledger.1.json",
        "collect-action-ledger.2.json",
    ],
    "snapshot_writer_sites": 2,
    "snapshot_output_cardinality": {"0": 1, "1": 1, "2": 1},
    "snapshot_overwrite_sites": 0,
    "configure_before_build": True,
    "pass": True,
})
PY
}

audit_collect_ledger_regression() {
    mkdir -m 700 -- "$LEDGER_REGRESSION_ROOT"
    python3 - "$NPU_ROOT/scripts" "$LEDGER_REGRESSION_OLD" \
        "$LEDGER_REGRESSION_0" "$LEDGER_REGRESSION_1" \
        "$LEDGER_REGRESSION_2" "$LEDGER_REGRESSION_AUDIT" <<'PY'
import pathlib
import sys

sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    IdentityError,
    atomic_write_json,
    read_json_same_bytes,
)

old_path = pathlib.Path(sys.argv[2])
snapshot_paths = [pathlib.Path(value) for value in sys.argv[3:6]]
output = pathlib.Path(sys.argv[6])
zero_counts = {
    "cmake-configure": 0, "cmake-build": 0, "binary": 0, "model": 0,
    "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0,
}

old_initial = {
    "schema": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
    "snapshot_index": 0,
    "counts": dict(zero_counts),
    "ordered_actions": [],
}
old_first_sha = atomic_write_json(old_path, old_initial)
old_rejected = False
old_error = ""
try:
    atomic_write_json(old_path, {
        **old_initial,
        "snapshot_index": 1,
        "counts": {**zero_counts, "cmake-configure": 1},
        "ordered_actions": ["cmake-configure"],
    })
except IdentityError as exc:
    old_error = str(exc)
    old_rejected = old_error.startswith("fresh atomic output already exists:")
if not old_rejected:
    raise SystemExit("mutable same-path ledger regression was unexpectedly accepted")
old_value, old_after_sha, _ = read_json_same_bytes(old_path)
if old_value != old_initial or old_after_sha != old_first_sha:
    raise SystemExit("rejected mutable ledger attempt changed original bytes")

snapshots = []
prior_path = None
prior_sha = None
for index, path in enumerate(snapshot_paths):
    if index == 0:
        counts = dict(zero_counts)
        ordered = []
        admitted = None
    elif index == 1:
        counts = {**zero_counts, "cmake-configure": 1}
        ordered = ["cmake-configure"]
        admitted = "cmake-configure"
    else:
        counts = {**zero_counts, "cmake-configure": 1, "cmake-build": 1}
        ordered = ["cmake-configure", "cmake-build"]
        admitted = "cmake-build"
    value = {
        "schema": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
        "snapshot_index": index,
        "admitted_action": admitted,
        "prior_snapshot_path": str(prior_path) if prior_path is not None else None,
        "prior_snapshot_sha256": prior_sha,
        "counts": counts,
        "ordered_actions": ordered,
    }
    digest = atomic_write_json(path, value)
    reopened, reopened_sha, _ = read_json_same_bytes(path)
    if reopened != value or reopened_sha != digest:
        raise SystemExit("fresh snapshot regression reopen mismatch")
    snapshots.append({"path": str(path), "sha256": digest, "snapshot_index": index})
    prior_path = path
    prior_sha = digest

atomic_write_json(output, {
    "schema": "qwen-f32-alu-families-compile-v13-ledger-regression-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "pass": True,
    "old_same_path_second_write_rejected": old_rejected,
    "old_same_path_original_preserved": True,
    "old_same_path_error": old_error,
    "old_same_path_sha256": old_after_sha,
    "three_distinct_fresh_paths_passed": True,
    "fresh_snapshot_count": len(snapshots),
    "fresh_snapshots": snapshots,
    "exact_order": ["cmake-configure", "cmake-build"],
    "cmake_invocations": 0,
    "verilator_invocations": 0,
    "make_invocations": 0,
    "binary_runs": 0,
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
    "schema": "qwen-f32-alu-families-compile-v13-process-audit-v1",
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
        "$CMAKE_TOOL_V4_AUDIT" "$COMPILE_V12_ORDER_AUDIT"
        "$COMPILE_V11_FAILURE_AUDIT"
        "$COMPILE_V10_FAILURE_AUDIT"
        "$COMPILE_V9_FAILURE_AUDIT"
        "$COMPILE_V8_FAILURE_AUDIT"
        "$COMPILE_V7_ROOT_FIX_AUDIT"
        "$COMPILE_V6_FAILURE_AUDIT"
        "$COMPILE_V4_CLASSIFIER_AUDIT"
        "$COMPILE_V3_FAILURE_AUDIT"
        "$EXPECTED_WARNING_COPY" "$WARNING_ORACLE_AUDIT" "$COLLECT_POLICY_AUDIT"
        "$LEDGER_REGRESSION_OLD" "$LEDGER_REGRESSION_0"
        "$LEDGER_REGRESSION_1" "$LEDGER_REGRESSION_2"
        "$LEDGER_REGRESSION_AUDIT"
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
    "frozen-inputs.pre.json": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "frozen-inputs.post.json": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "v11-closure-audit.json": "qwen-f32-alu-families-compile-v13-v11-closure-v1",
    "cmake-tool-v4-audit.json": "qwen-f32-alu-families-compile-v13-cmake-tool-v4-audit-v1",
    "compile-v12-order-audit.json": "qwen-f32-alu-families-compile-v13-compile-v12-order-audit-v1",
    "compile-v11-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v11-failure-audit-v1",
    "compile-v10-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v10-failure-audit-v1",
    "compile-v9-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v9-failure-audit-v1",
    "compile-v8-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v8-failure-audit-v1",
    "compile-v7-root-fix-audit.json": "qwen-f32-alu-families-compile-v13-compile-v7-root-fix-audit-v1",
    "compile-v6-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v6-failure-audit-v1",
    "compile-v4-classifier-audit.json": "qwen-f32-alu-families-compile-v13-compile-v4-classifier-audit-v1",
    "compile-v3-failure-audit.json": "qwen-f32-alu-families-compile-v13-compile-v3-failure-audit-v1",
    "warning-oracle-audit.json": "qwen-f32-alu-families-compile-v13-warning-oracle-v1",
    "collect-policy-audit.json": "qwen-f32-alu-families-compile-v13-collect-policy-v1",
    "mutable-ledger.json": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
    "collect-action-ledger.0.json": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
    "collect-action-ledger.1.json": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
    "collect-action-ledger.2.json": "qwen-f32-alu-families-compile-v13-ledger-regression-sample-v1",
    "collect-ledger-regression.json": "qwen-f32-alu-families-compile-v13-ledger-regression-v1",
    "preflight-process-audit.json": "qwen-f32-alu-families-compile-v13-process-audit-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    schema = schemas.get(path.name)
    if path.parent.name == "sealed":
        schema = "qwen-f32-alu-families-compile-v13-frozen-inputs-v1"
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
compile_v12 = parsed["compile-v12-order-audit.json"]
compile_v11 = parsed["compile-v11-failure-audit.json"]
compile_v10 = parsed["compile-v10-failure-audit.json"]
compile_v9 = parsed["compile-v9-failure-audit.json"]
compile_v8 = parsed["compile-v8-failure-audit.json"]
compile_v7 = parsed["compile-v7-root-fix-audit.json"]
compile_v6 = parsed["compile-v6-failure-audit.json"]
compile_v4 = parsed["compile-v4-classifier-audit.json"]
compile_v3 = parsed["compile-v3-failure-audit.json"]
ledger_regression = parsed["collect-ledger-regression.json"]
cmake = parsed["cmake-source-identity.json"]
process = parsed["preflight-process-audit.json"]
expected_order_mutations = {
    "missing_s_row", "extra_s_row", "duplicate_s_row", "class_collision_or_substitution",
    "reordered_s_rows", "reordered_c_design_arguments", "duplicate_c_row", "missing_c_row",
    "comment_or_decoy_text",
}
if (compile_v12.get("pass") is not True or
        compile_v12.get("compile_v12", {}).get("runner_sha256") !=
        "a5eee002ccbecb1855b75d0d28d4f780c4b8e1588fa5ae33c0773c165ea76bc5" or
        compile_v12.get("compile_v12", {}).get("preflight_status") != "PASS" or
        compile_v12.get("compile_v12", {}).get("configure_rc") != 0 or
        compile_v12.get("compile_v12", {}).get("build_rc") != 0 or
        compile_v12.get("compile_v12", {}).get("build_count") != 1 or
        compile_v12.get("compile_v12", {}).get("warning_rows") != 25 or
        any(compile_v12.get("compile_v12", {}).get(name) != 0 for name in
            ["binary_runs", "model_runs", "qwen_runs", "synthesis", "sta", "ppa"]) or
        compile_v12.get("verfiles", {}).get("c_row_count") != 1 or
        compile_v12.get("verfiles", {}).get("s_row_count") != 23 or
        compile_v12.get("verfiles", {}).get("s_unique_count") != 23 or
        compile_v12.get("verfiles", {}).get("s_membership") !=
        {"design": 21, "control": 1, "tool": 1} or
        compile_v12.get("verfiles", {}).get("s_rows_lexicographic") is not True or
        compile_v12.get("verfiles", {}).get("c_design_order") != "cmake-declaration-order" or
        compile_v12.get("verfiles", {}).get("c_pinned_argv") is not True or
        compile_v12.get("old_compile_v12_oracle", {}).get("accepted") is not False or
        compile_v12.get("old_compile_v12_oracle", {}).get("reject_reason") !=
        "lexicographic-s-order-compared-to-cmake-c-design-order" or
        set(compile_v12.get("mutations_rejected", {})) != expected_order_mutations or
        not all(compile_v12.get("mutations_rejected", {}).values())):
    raise SystemExit("compile-v12 S/C dual-order closure mismatch")
if (warning.get("pass") is not True or warning.get("expected_row_count") != 25 or
        warning.get("expected_tsv_sha256") != "832d5dab72b87cafea80870d8e269d740e56d6beed7c7f5d6d7325aa53c1018c" or
        not all(warning.get("mutations_rejected", {}).values()) or
        policy.get("pass") is not True or policy.get("lifecycle_actions") != ["cmake-configure", "cmake-build"] or
        policy.get("snapshot_filenames") != ["collect-action-ledger.0.json",
                                              "collect-action-ledger.1.json",
                                              "collect-action-ledger.2.json"] or
        policy.get("snapshot_output_cardinality") != {"0": 1, "1": 1, "2": 1} or
        policy.get("snapshot_overwrite_sites") != 0 or
        policy.get("configure_before_build") is not True or
        compile_v11.get("pass") is not True or
        compile_v11.get("compile_v11", {}).get("runner_sha256") !=
        "6428042d5c33bbf6323fd720a4e9fb741b07c2c8e5040bce495d9fef575d8675" or
        compile_v11.get("compile_v11", {}).get("preflight_status_sha256") !=
        "0868e62dc3bd073d3af46c92d4071ac91858e52fe3854d099d6acb7f4582a1d8" or
        compile_v11.get("compile_v11", {}).get("preflight_build_count_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v11.get("compile_v11", {}).get("preflight_snapshot_sha256") !=
        "4219908d70287527105209788a80ed6ccc8da36f52b865fc425b8714308755b0" or
        compile_v11.get("compile_v11", {}).get("preflight_rc") != 1 or
        compile_v11.get("compile_v11", {}).get("build_root_absent") is not True or
        compile_v11.get("compile_v11", {}).get("compile_v10_audit_published") is not False or
        any(value != 0 for value in
            compile_v11.get("compile_v11", {}).get("zero_actions", {}).values()) or
        compile_v11.get("root_cause", {}).get("algorithm") !=
        "longest-common-prefix-and-nonoverlapping-longest-common-suffix" or
        compile_v11.get("root_cause", {}).get("malformed_length") != 61 or
        compile_v11.get("root_cause", {}).get("correct_length") != 64 or
        compile_v11.get("root_cause", {}).get("common_prefix_length") != 15 or
        compile_v11.get("root_cause", {}).get("common_suffix_length") != 46 or
        compile_v11.get("root_cause", {}).get("malformed_middle_slice") != "" or
        compile_v11.get("root_cause", {}).get("correct_middle_slice") != "ee6" or
        compile_v11.get("root_cause", {}).get("predecessor_manual_middle_slice") != "e6e" or
        compile_v10.get("pass") is not True or
        compile_v10.get("compile_v10", {}).get("runner_sha256") !=
        "498913a752f0c7c2c7da9292cb353f47254a486459b5e7053da1665d8b602d47" or
        compile_v10.get("compile_v10", {}).get("preflight_status_sha256") !=
        "9b01b2d6e6d27adecfdd3563b57b4ac02bd0fa7ce5492fe87f0f79fc5bb0e873" or
        compile_v10.get("compile_v10", {}).get("preflight_build_count_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v10.get("compile_v10", {}).get("preflight_snapshot_sha256") !=
        "2c5c72621c6fd4df084bf5e90245926721d59d5e5c0fc39508003e98ec5c2a5a" or
        compile_v10.get("compile_v10", {}).get("compile_v9_failure_audit_sha256") !=
        "85cb9470c5aabdde4d5b997c7091b1cb5f989a7ed381708570e6c96ebfc1f474" or
        compile_v10.get("compile_v10", {}).get("bash_n_count") != 1 or
        compile_v10.get("compile_v10", {}).get("bash_n_rc") != 0 or
        compile_v10.get("compile_v10", {}).get("preflight_count") != 1 or
        compile_v10.get("compile_v10", {}).get("preflight_rc") != 1 or
        compile_v10.get("compile_v10", {}).get("build_root_absent") is not True or
        compile_v10.get("compile_v10", {}).get("structure_checker_executed") is not False or
        compile_v10.get("compile_v10", {}).get("document_mutations_executed") != 0 or
        compile_v10.get("compile_v10", {}).get("rtl_mutations_executed") != 0 or
        any(value != 0 for value in
            compile_v10.get("compile_v10", {}).get("zero_actions", {}).values()) or
        set(compile_v10.get("compile_v10", {}).get("zero_actions", {})) != {
            "collect", "cmake_configure", "cmake_build", "verilator", "make",
            "binary_runs", "model_runs", "qwen_runs", "synthesis", "sta", "ppa"} or
        compile_v10.get("root_cause", {}).get("class") !=
        "python-expected-sha-literal-typo" or
        compile_v10.get("root_cause", {}).get("malformed_literal") !=
        "9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v10.get("root_cause", {}).get("malformed_type") != "str" or
        compile_v10.get("root_cause", {}).get("malformed_length") != 61 or
        compile_v10.get("root_cause", {}).get("malformed_repr") !=
        "'9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa'" or
        compile_v10.get("root_cause", {}).get(
            "malformed_ascii_only_lower_hex") is not True or
        compile_v10.get("root_cause", {}).get("correct_literal") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v10.get("root_cause", {}).get("correct_type") != "str" or
        compile_v10.get("root_cause", {}).get("correct_length") != 64 or
        compile_v10.get("root_cause", {}).get("correct_repr") !=
        "'9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa'" or
        compile_v10.get("root_cause", {}).get(
            "correct_ascii_only_lower_hex") is not True or
        compile_v10.get("root_cause", {}).get("algorithm") !=
        "longest-common-prefix-and-nonoverlapping-longest-common-suffix" or
        compile_v10.get("root_cause", {}).get("common_prefix_length") != 15 or
        compile_v10.get("root_cause", {}).get("common_suffix_length") != 46 or
        compile_v10.get("root_cause", {}).get("malformed_middle_slice") != "" or
        compile_v10.get("root_cause", {}).get("correct_middle_slice") != "ee6" or
        compile_v10.get("root_cause", {}).get("standard_library_hashlib_sha256") is not True or
        compile_v10.get("root_cause", {}).get("python_type_or_equality_issue") is not False or
        compile_v10.get("root_cause", {}).get("rtl_or_compile_failure") is not False or
        compile_v10.get("root_cause", {}).get("malformed_ascii_code_points") !=
        [ord(character) for character in
         "9a271f2a916b0b6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"] or
        compile_v10.get("root_cause", {}).get("correct_ascii_code_points") !=
        [ord(character) for character in
         "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"] or
        compile_v10.get("frozen_inputs", {}).get("log_regular_files") !=
        ["preflight.status"] or
        compile_v10.get("frozen_inputs", {}).get("compiler_directories") !=
        ["sealed", "staging", "work"] or
        compile_v10.get("frozen_inputs", {}).get("compiler_regular_files") != [
            "staging/compile-v9-failure-audit.json",
            "staging/frozen-inputs.pre.json",
            "staging/preflight-build.count"] or
        compile_v9.get("pass") is not True or
        compile_v9.get("compile_v9", {}).get("preflight_status_sha256") !=
        "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51" or
        compile_v9.get("compile_v9", {}).get("preflight_build_count_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v9.get("compile_v9", {}).get("build_root_absent") is not True or
        compile_v9.get("compile_v9", {}).get("input_snapshot_published") is not False or
        compile_v9.get("compile_v9", {}).get("structure_checker_executed") is not False or
        compile_v9.get("compile_v9", {}).get("document_mutations_executed") != 0 or
        compile_v9.get("compile_v9", {}).get("rtl_mutations_executed") != 0 or
        compile_v9.get("compile_v9", {}).get("collect_executed") is not False or
        any(compile_v9.get("compile_v9", {}).get(name) != 0 for name in [
            "cmake_configure", "cmake_build", "verilator", "make", "binary_runs",
            "model_runs", "qwen_runs", "synthesis", "sta", "ppa"]) or
        compile_v9.get("root_cause", {}).get("class") !=
        "unexplained-shell-hash-false-negative" or
        compile_v9.get("root_cause", {}).get(
            "direct_post_failure_observation_bound_by_compile_v8_closure") is not True or
        compile_v9.get("root_cause", {}).get("rtl_or_compile_failure") is not False or
        compile_v8.get("pass") is not True or
        compile_v8.get("compile_v8", {}).get("preflight_status_sha256") !=
        "79184a20fea5d869495b2837d43f99b0334d69f785c14ae678b15180dca4d789" or
        compile_v8.get("compile_v8", {}).get("preflight_snapshot_sha256") !=
        "e8eac94ac0810b896b7d27af7e6a6d53971e038fece3fb11c6d27ec1f8df41d6" or
        compile_v8.get("compile_v8", {}).get("preflight_build_count") != 0 or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("window_count") != 2 or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("content_classification") !=
        "exact-zero-line" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("observed_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("expected_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("fingerprint_stable") is not True or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("expected_sha256_type") != "str" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("expected_sha256_length") != 64 or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("expected_sha256_repr") !=
        "'9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa'" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get(
                "expected_sha256_ascii_code_points") !=
        [ord(character) for character in
         "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"] or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("observed_sha256_type") != "str" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("observed_sha256_length") != 64 or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("observed_sha256_repr") !=
        "'9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa'" or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get(
                "observed_sha256_ascii_code_points") !=
        [ord(character) for character in
         "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa"] or
        compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_audit", {}).get("hash_implementation") !=
        "python-stdlib-hashlib.sha256(bytes).hexdigest" or
        set(compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_mutations_rejected", {})) != {
                "changed_bytes", "symlink", "special_non_file",
                "replacement_between_windows",
                "malformed_61_character_expected_literal"} or
        not all(compile_v8.get("compile_v8", {}).get(
            "preflight_build_count_mutations_rejected", {}).values()) or
        compile_v8.get("compile_v8", {}).get("build_root_absent") is not True or
        compile_v8.get("compile_v8", {}).get("root_fix_audit_published") is not False or
        compile_v8.get("compile_v8", {}).get("collect_executed") is not False or
        any(compile_v8.get("compile_v8", {}).get(name) != 0 for name in [
            "cmake_configure", "cmake_build", "verilator", "make", "binary_runs",
            "model_runs", "qwen_runs", "synthesis", "sta", "ppa"]) or
        compile_v8.get("root_cause", {}).get("class") !=
        "doc-evidence-parser-false-negative" or
        compile_v8.get("root_cause", {}).get("parenthesized_live_term_count_in_doc") != 1 or
        compile_v8.get("root_cause", {}).get("parenthesized_live_term_required_minimum") != 2 or
        compile_v8.get("root_cause", {}).get(
            "unsealed_pre_root_checks_must_not_be_called_pass") is not True or
        compile_v7.get("pass") is not True or
        compile_v7.get("compile_v7", {}).get("preflight_status_sha256") !=
        "c26de83abdc9496cd1301470918ec39ecca1cf389ef0ae1c6504da1800d1c431" or
        compile_v7.get("compile_v7", {}).get("compile_status_sha256") !=
        "aa335af767b126c3151f774b24dbb74fb99f1127edc1ccfba9dd7910baad9c3d" or
        compile_v7.get("compile_v7", {}).get("configure_rc") != 0 or
        compile_v7.get("compile_v7", {}).get("build_rc") != 0 or
        compile_v7.get("compile_v7", {}).get("build_count") != 1 or
        compile_v7.get("compile_v7", {}).get("expected_warning_rows") != 25 or
        compile_v7.get("compile_v7", {}).get("actual_warning_rows") != 26 or
        compile_v7.get("compile_v7", {}).get("warning_missing") != [] or
        compile_v7.get("compile_v7", {}).get("warning_extra") != [[
            "UNUSEDSIGNAL", "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v", 346, 18]] or
        compile_v7.get("compile_v7", {}).get("binary_runs") != 0 or
        compile_v7.get("production_change_scope", {}).get("changed_paths") != [
            "npu/version_0820/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md",
            "npu/version_0820/rtl/TensorNpuVectorF32Adapter.v"] or
        compile_v7.get("overflow_admission", {}).get("exact_live_term_count") != 1 or
        set(compile_v7.get("overflow_admission", {}).get(
            "mutations_rejected", {})) != {
                "remove_term", "move_outside_live_admission", "wrong_slice",
                "wrong_value", "comment_only_decoy", "warning_waiver",
                "dummy_consumer"} or
        not all(compile_v7.get("overflow_admission", {}).get(
            "mutations_rejected", {}).values()) or
        compile_v7.get("phase_topology_freeze", {}).get(
            "stable_structure_id_sha256") !=
        "b9d4366c26b281bea20b8f3c459a4128e150be157afdbb7e1857580f7d81b0c3" or
        compile_v7.get("phase_topology_freeze", {}).get("heading_count") != 6 or
        compile_v7.get("phase_topology_freeze", {}).get("invariant_count") != 5 or
        compile_v7.get("phase_topology_freeze", {}).get("topology_item_count") != 9 or
        set(compile_v7.get("phase_topology_freeze", {}).get(
            "document_mutations_rejected", {})) != {
                "missing_heading", "reordered_heading", "duplicate_heading",
                "missing_invariant", "missing_topology_item",
                "changed_warning_25_26", "comment_archival_decoy_outside_v8"} or
        not all(compile_v7.get("phase_topology_freeze", {}).get(
            "document_mutations_rejected", {}).values()) or
        compile_v7.get("warning_oracle", {}).get("expected_rows") != 25 or
        compile_v7.get("warning_oracle", {}).get("updated_to_26") is not False or
        compile_v6.get("pass") is not True or
        compile_v6.get("admission_method") !=
        "whole-runner-sha-status-schema-and-direct-filesystem-census" or
        compile_v6.get("bash_function_boundary_inference") is not False or
        compile_v6.get("census_windows") != 2 or
        compile_v6.get("compile_v6", {}).get("preflight_status_sha256") !=
        "be169b5dd1b5fd8f6f617470b21b9c4782cc49c69db6b6d2e9c83e707a76eeb5" or
        compile_v6.get("compile_v6", {}).get("preflight_snapshot_sha256") !=
        "ca26791ab50b19bc6d1bda8d0422f82a6431fd89d6afcd5872fc6336d81f3308" or
        compile_v6.get("compile_v6", {}).get("build_count") != 0 or
        compile_v6.get("compile_v6", {}).get("collect_executed") is not False or
        compile_v6.get("compile_v6", {}).get("classifier_regression_executed") is not False or
        compile_v6.get("compile_v6", {}).get("ledger_regression_executed") is not False or
        compile_v6.get("compile_v6", {}).get("cmake_configure") != 0 or
        compile_v6.get("compile_v6", {}).get("compiler_census", {}).get(
            "directory_membership") != ["sealed", "staging", "work"] or
        compile_v6.get("compile_v6", {}).get("compiler_census", {}).get(
            "regular_file_membership") != [
                "staging/frozen-inputs.pre.json", "staging/preflight-build.count"] or
        compile_v6.get("compile_v5", {}).get("preflight_status_sha256") !=
        "e5b67181496437a35668c3bd1025b3e9e21e939d2f71ca29d5a03858bb8c5046" or
        compile_v6.get("compile_v5", {}).get("build_count") != 0 or
        compile_v4.get("pass") is not True or
        compile_v4.get("compile_v4", {}).get("preflight_status_sha256") !=
        "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51" or
        compile_v4.get("compile_v4", {}).get("build_count") != 0 or
        compile_v4.get("compile_v4", {}).get("collect_executed") is not False or
        compile_v4.get("compile_v4", {}).get("cmake_configure") != 0 or
        compile_v4.get("compile_v4", {}).get("directory_membership") !=
        ["sealed", "staging", "work"] or
        compile_v4.get("compile_v4", {}).get("regular_file_membership") !=
        ["staging/preflight-build.count"] or
        compile_v4.get("compile_v4", {}).get("count_bytes") != "0\\n" or
        compile_v4.get("compile_v4", {}).get("census_windows") != 2 or
        compile_v4.get("compile_v4", {}).get("fingerprint_stable") is not True or
        compile_v4.get("compile_v4", {}).get("classifier_regression_passed") != 11 or
        compile_v4.get("compile_v4", {}).get("classifier_regression_total") != 11 or
        not all(compile_v4.get("compile_v4", {}).get(
            "classifier_regression_acceptance", {}).get(name) == (name == "exact")
            for name in [
                "exact", "missing_directory", "extra_directory",
                "renamed_directory", "extra_member", "nested_member",
                "symlink_member", "file_directory_class_collision",
                "changed_count_bytes", "two_window_substitution", "symlink_root",
            ]) or
        compile_v3.get("pass") is not True or
        compile_v3.get("compile_v3", {}).get("compile_status_sha256") !=
        "2856e07c603ed85e496181f60f17540d1f3cf89687752ff5ea50dc7fcf26e663" or
        compile_v3.get("compile_v3", {}).get("cmake_configure_executed") != 0 or
        compile_v3.get("compile_v3", {}).get("build_root_admissible") is not True or
        compile_v3.get("compile_v3", {}).get("build_root_state") not in
        {"absent", "empty-created-before-command"} or
        compile_v3.get("compile_v3", {}).get("build_root_entry_count") != 0 or
        compile_v3.get("compile_v3", {}).get("external_action_count") != 0 or
        compile_v3.get("compile_v3", {}).get(
            "root_classifier_regression_acceptance") != {
                "absent": True,
                "exact_empty": True,
                "file": False,
                "symlink": False,
                "nested_entry": False,
                "ambiguous": False,
            } or
        ledger_regression.get("pass") is not True or
        ledger_regression.get("old_same_path_second_write_rejected") is not True or
        ledger_regression.get("old_same_path_original_preserved") is not True or
        ledger_regression.get("three_distinct_fresh_paths_passed") is not True or
        ledger_regression.get("fresh_snapshot_count") != 3 or
        ledger_regression.get("exact_order") != ["cmake-configure", "cmake-build"] or
        ledger_regression.get("cmake_invocations") != 0 or
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

runner_relative = "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v13.sh"
receipt = {
    "schema": "qwen-f32-alu-families-compile-v13-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "contract_sha256": "80e3f66d119949b2142b2a3f5f3ec56eea656bac27c6d2c4734f2016eee841ed",
    "material_sha256": "797e46c6f34ae05bb52d2f62662e142d3c2440290377af012cf62a6dbc43b005",
    "runner_sha256": pre["files"][runner_relative]["sha256"],
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "content_addressed_snapshot": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "warning_expected_sha256": warning["expected_tsv_sha256"],
    "warning_expected_rows": 25,
    "warning_mutations_rejected": warning["mutations_rejected"],
    "compile_v12_order_closure": {
        "compile_v12": compile_v12["compile_v12"],
        "verfiles": compile_v12["verfiles"],
        "old_compile_v12_oracle": compile_v12["old_compile_v12_oracle"],
        "mutations_rejected": compile_v12["mutations_rejected"],
    },
    "compile_v11_failure_closure": {
        "compile_v11": compile_v11["compile_v11"],
        "root_cause": compile_v11["root_cause"],
        "frozen_inputs": compile_v11["frozen_inputs"],
    },
    "compile_v10_failure_closure": {
        "compile_v10": compile_v10["compile_v10"],
        "root_cause": compile_v10["root_cause"],
        "frozen_inputs": compile_v10["frozen_inputs"],
    },
    "compile_v9_failure_closure": {
        "compile_v9": compile_v9["compile_v9"],
        "root_cause": compile_v9["root_cause"],
        "frozen_inputs": compile_v9["frozen_inputs"],
    },
    "compile_v8_failure_closure": {
        "compile_v8": compile_v8["compile_v8"],
        "root_cause": compile_v8["root_cause"],
        "frozen_inputs": compile_v8["frozen_inputs"],
    },
    "compile_v7_root_fix": {
        "compile_v7": compile_v7["compile_v7"],
        "production_change_scope": compile_v7["production_change_scope"],
        "overflow_admission": compile_v7["overflow_admission"],
        "phase_topology_freeze": compile_v7["phase_topology_freeze"],
        "warning_oracle": compile_v7["warning_oracle"],
    },
    "compile_v6_failure_closure": {
        "admission_method": compile_v6["admission_method"],
        "bash_function_boundary_inference":
            compile_v6["bash_function_boundary_inference"],
        "census_windows": compile_v6["census_windows"],
        "compile_v6": compile_v6["compile_v6"],
        "compile_v5": compile_v6["compile_v5"],
    },
    "compile_v4_classifier_closure": compile_v4["compile_v4"],
    "compile_v3_failure_closure": compile_v3["compile_v3"],
    "predecessor_build_root_policy": {
        "accepted_states": ["absent", "empty-created-before-command"],
        "actual_state": compile_v3["compile_v3"]["build_root_state"],
        "exact_entry_count": compile_v3["compile_v3"]["build_root_entry_count"],
        "census_windows": compile_v3["compile_v3"]["build_root_census_windows"],
        "root_classifier_regression_acceptance":
            compile_v3["compile_v3"]["root_classifier_regression_acceptance"],
    },
    "collect_ledger_policy": {
        "snapshot_filenames": policy["snapshot_filenames"],
        "snapshot_output_cardinality": policy["snapshot_output_cardinality"],
        "snapshot_overwrite_sites": policy["snapshot_overwrite_sites"],
        "configure_before_build": policy["configure_before_build"],
    },
    "collect_ledger_regression": {
        "old_same_path_second_write_rejected":
            ledger_regression["old_same_path_second_write_rejected"],
        "old_same_path_original_preserved":
            ledger_regression["old_same_path_original_preserved"],
        "three_distinct_fresh_paths_passed":
            ledger_regression["three_distinct_fresh_paths_passed"],
        "fresh_snapshot_count": ledger_regression["fresh_snapshot_count"],
        "exact_order": ledger_regression["exact_order"],
        "cmake_invocations": 0,
    },
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
    root, receipt_path, "qwen-f32-alu-families-compile-v13-preflight-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {
    "schema": "qwen-f32-alu-families-compile-v13-preflight-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
    "schema": "qwen-f32-alu-families-compile-v13-preflight-final-binding-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
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
      pre["files"][runner_relative]["sha256"],
      compile_v3["compile_v3"]["build_root_state"])
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
if read_bytes_stable(root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v13/staging/preflight-build.count") != b"0\n":
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
    local predecessor_root_state="$6"
    TERMINAL_SUCCESS=1
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V13][PREFLIGHT-PASS] build_count=0 build_root_absent=1 cmake_version=0 cmake_configure=0 cmake_build=0 ninja=0 verilator=0 verilator_generation=0 make=0 model_make=0 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 owned_background_jobs=0 compile_v12_configure_rc=0 compile_v12_build_rc=0 compile_v12_collect_status=FAIL-order-oracle compile_v12_s_rows=23-unique-lexicographic compile_v12_c_rows=1 compile_v12_c_design_order=21-cmake-declaration compile_v12_old_order_conflation_rejected=1 compile_v12_order_mutations=9/9 compile_v12_binary_runs=0 compile_v12_model_runs=0 compile_v12_qwen_runs=0 compile_v11_preflight=FAIL-manual-middle-slice compile_v11_status_sha256=$COMPILE_V11_PREFLIGHT_STATUS_SHA256 compile_v11_runner_sha256=$COMPILE_V11_RUNNER_SHA256 compile_v11_bad_sha_len=61 compile_v11_good_sha_len=64 compile_v11_lcp=15 compile_v11_lcs=46 compile_v11_bad_middle=empty compile_v11_good_middle=ee6 compile_v11_manual_middle=e6e compile_v11_structure_checker=0 compile_v11_doc_mutations=0 compile_v11_rtl_mutations=0 compile_v11_collect=0 compile_v10_preflight=FAIL-python-sha-literal-typo compile_v10_status_sha256=$COMPILE_V10_PREFLIGHT_STATUS_SHA256 compile_v10_runner_sha256=$COMPILE_V10_RUNNER_SHA256 compile_v10_bad_sha_type=str compile_v10_bad_sha_len=61 compile_v10_good_sha_type=str compile_v10_good_sha_len=64 compile_v10_lcp=15 compile_v10_lcs=46 compile_v10_bad_middle=empty compile_v10_good_middle=ee6 compile_v10_structure_checker=0 compile_v10_doc_mutations=0 compile_v10_rtl_mutations=0 compile_v10_collect=0 compile_v9_preflight=FAIL-shell-hash-false-negative compile_v9_status_sha256=$COMPILE_V9_PREFLIGHT_STATUS_SHA256 compile_v9_runner_sha256=$COMPILE_V9_RUNNER_SHA256 compile_v9_build_count=0 compile_v9_structure_checker=0 compile_v9_doc_mutations=0 compile_v9_rtl_mutations=0 compile_v9_collect=0 compile_v8_preflight=FAIL-doc-parser compile_v8_status_sha256=$COMPILE_V8_PREFLIGHT_STATUS_SHA256 compile_v8_runner_sha256=$COMPILE_V8_RUNNER_SHA256 compile_v8_snapshot_sha256=$COMPILE_V8_PREFLIGHT_SNAPSHOT_SHA256 compile_v8_build_count=0 compile_v8_count_audit=PASS compile_v8_count_expected_sha256=$COMPILE_V8_PREFLIGHT_BUILD_COUNT_SHA256 compile_v8_count_observed_sha256=$COMPILE_V8_PREFLIGHT_BUILD_COUNT_SHA256 compile_v8_count_bytes=exact-zero-line compile_v8_count_windows=2 compile_v8_count_fingerprint_stable=1 compile_v8_count_mutations=5/5 compile_v8_collect=0 compile_v8_root_fix_audit_published=0 compile_v7_preflight=PASS compile_v7_collect=FAIL-warning-extra compile_v7_configure_rc=0 compile_v7_build_rc=0 compile_v7_warning_rows=25+1 compile_v7_extra=dst_nb3_ext_w[127:64] production_changes=doc+adapter owner_doc_sha256=$OWNER_CONTRACT_SHA256 adapter_sha256=$ADAPTER_SHA256 v8_structure_id_sha256=$V8_STRUCTURE_ID_SHA256 v8_headings=6/6 v8_invariants=5/5 v8_topology=9/9 v8_doc_mutations=7/7 overflow_admission_term=1 overflow_mutations=7/7 expected_warning_updated_to_26=0 compile_v6_failure=bound compile_v6_status_sha256=$COMPILE_V6_PREFLIGHT_STATUS_SHA256 compile_v6_runner_sha256=$COMPILE_V6_RUNNER_SHA256 compile_v6_snapshot_sha256=$COMPILE_V6_PREFLIGHT_SNAPSHOT_SHA256 compile_v6_direct_census=PASS compile_v6_function_boundary_inference=0 compile_v5_status_sha256=$COMPILE_V5_PREFLIGHT_STATUS_SHA256 compile_v5_runner_sha256=$COMPILE_V5_RUNNER_SHA256 compile_v4_classifier=PASS compile_v4_status_sha256=$COMPILE_V4_PREFLIGHT_STATUS_SHA256 compile_v4_runner_sha256=$COMPILE_V4_RUNNER_SHA256 compile_v4_directory_census=3-exact compile_v4_regular_file_census=1-exact compile_v4_census_windows=2 compile_v4_classifier_regressions=11/11 compile_v3_failure=bound compile_v3_status_sha256=$COMPILE_V3_COMPILE_STATUS_SHA256 compile_v3_initial_ledger_sha256=$COMPILE_V3_INITIAL_LEDGER_SHA256 compile_v3_build_root_state=$predecessor_root_state compile_v3_build_root_entries=0 compile_v3_external_actions=0 compile_v3_root_classifier_regressions=6/6 ledger_old_pattern_rejected=1 ledger_three_fresh_snapshots=PASS ledger_snapshot_writers=1+1+1 ledger_snapshot_overwrites=0 ledger_order=configure-before-build cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 cmake_size=$PINNED_CMAKE_SIZE cmake_mode=0755 cmake_tree_entries=8173 cmake_tree_sha256=$PINNED_CMAKE_TREE_SHA256 cmake_v4_receipt_sha256=$CMAKE_V4_RECEIPT_SHA256 cmake_v4_manifest_sha256=$CMAKE_V4_MANIFEST_SHA256 cmake_v4_binding_sha256=$CMAKE_V4_BINDING_SHA256 cmake_v4_status_sha256=$CMAKE_V4_STATUS_SHA256 compile_v2_status_sha256=$COMPILE_V2_STATUS_SHA256 warning_expected_sha256=$WARNING_EXPECTED_SHA256 warning_rows=25-exact warning_mutations=7/7 cmake_source_count=21 frozen_cmake_template=PASS actual_configured_argv=GAP compile_membership=GAP verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN contract_sha256=$CONTRACT_SHA256 runner_sha256=$runner_sha receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha snapshot_sha256=$snapshot_sha"
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
    require_exact_hash "$NPU_ROOT/docs/QWEN_F32_ALU_OWNER_RTL_CONTRACT.md" \
        "$OWNER_CONTRACT_SHA256"
    require_exact_hash "$NPU_ROOT/rtl/TensorNpuVectorF32Adapter.v" "$ADAPTER_SHA256"
    require_exact_hash "$COMPILE_V12_CONTRACT" "$COMPILE_V12_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V12_MATERIAL" "$COMPILE_V12_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V12_RUNNER" "$COMPILE_V12_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/preflight.status" "$COMPILE_V12_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/preflight.receipt.json" "$COMPILE_V12_PREFLIGHT_RECEIPT_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/preflight.bound-artifacts.json" "$COMPILE_V12_PREFLIGHT_MANIFEST_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/preflight.final-binding.json" "$COMPILE_V12_PREFLIGHT_BINDING_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/sealed/frozen-inputs.$COMPILE_V12_PREFLIGHT_SNAPSHOT_SHA256.json" \
        "$COMPILE_V12_PREFLIGHT_SNAPSHOT_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/compile.status" "$COMPILE_V12_COMPILE_STATUS_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-configure.rc" "$COMPILE_V12_COMMAND_RC_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-build.rc" "$COMPILE_V12_COMMAND_RC_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/collect-build.count" "$COMPILE_V12_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-configure.log" "$COMPILE_V12_CONFIGURE_LOG_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-build.log" "$COMPILE_V12_BUILD_LOG_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-configure.argv.json" "$COMPILE_V12_CONFIGURE_ARGV_SHA256"
    require_exact_hash "$COMPILE_V12_LOG_ROOT/cmake-build.argv.json" "$COMPILE_V12_BUILD_ARGV_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/collect-action-ledger.0.json" "$COMPILE_V12_LEDGER_0_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/collect-action-ledger.1.json" "$COMPILE_V12_LEDGER_1_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/collect-action-ledger.2.json" "$COMPILE_V12_LEDGER_2_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/staging/cmake-source-identity.json" "$COMPILE_V12_CMAKE_IDENTITY_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/actual-warning-census.tsv" "$COMPILE_V12_WARNING_SHA256"
    require_exact_hash "$COMPILE_V12_COMPILER_ROOT/build-diagnostic-audit.json" "$COMPILE_V12_DIAGNOSTIC_SHA256"
    require_exact_hash "$COMPILE_V12_VERFILES" "$COMPILE_V12_VERFILES_SHA256"
    require_exact_hash "$COMPILE_V12_BUILD_ROOT/verilated/VTensorNpuCoprocessor__ALL.a" "$COMPILE_V12_ARCHIVE_SHA256"
    require_exact_hash "$COMPILE_V12_BUILD_ROOT/cmake/test-npu-backend" "$COMPILE_V12_BINARY_SHA256"
    require_exact_hash "$COMPILE_V12_BUILD_ROOT/cmake/libggml-npu.so" "$COMPILE_V12_DSO_SHA256"
    require_exact_hash "$COMPILE_V11_CONTRACT" "$COMPILE_V11_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V11_MATERIAL" "$COMPILE_V11_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V11_RUNNER" "$COMPILE_V11_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V11_LOG_ROOT/preflight.status" \
        "$COMPILE_V11_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V11_COMPILER_ROOT/staging/preflight-build.count" \
        "$COMPILE_V11_PREFLIGHT_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V11_COMPILER_ROOT/staging/frozen-inputs.pre.json" \
        "$COMPILE_V11_PREFLIGHT_SNAPSHOT_SHA256"
    path_absent "$COMPILE_V11_BUILD_ROOT" || fail "compile-v11 immutable build root exists"
    require_exact_hash "$COMPILE_V10_CONTRACT" "$COMPILE_V10_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V10_MATERIAL" "$COMPILE_V10_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V10_RUNNER" "$COMPILE_V10_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V10_LOG_ROOT/preflight.status" \
        "$COMPILE_V10_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V10_COMPILER_ROOT/staging/preflight-build.count" \
        "$COMPILE_V10_PREFLIGHT_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V10_COMPILER_ROOT/staging/frozen-inputs.pre.json" \
        "$COMPILE_V10_PREFLIGHT_SNAPSHOT_SHA256"
    require_exact_hash "$COMPILE_V10_COMPILER_ROOT/staging/compile-v9-failure-audit.json" \
        "$COMPILE_V10_COMPILE_V9_AUDIT_SHA256"
    path_absent "$COMPILE_V10_BUILD_ROOT" || fail "compile-v10 immutable build root exists"
    require_exact_hash "$COMPILE_V9_CONTRACT" "$COMPILE_V9_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V9_MATERIAL" "$COMPILE_V9_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V9_RUNNER" "$COMPILE_V9_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V9_LOG_ROOT/preflight.status" \
        "$COMPILE_V9_PREFLIGHT_STATUS_SHA256"
    path_absent "$COMPILE_V9_BUILD_ROOT" || fail "compile-v9 immutable build root exists"
    require_exact_hash "$COMPILE_V8_CONTRACT" "$COMPILE_V8_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V8_MATERIAL" "$COMPILE_V8_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V8_RUNNER" "$COMPILE_V8_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V8_LOG_ROOT/preflight.status" \
        "$COMPILE_V8_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V8_COMPILER_ROOT/staging/frozen-inputs.pre.json" \
        "$COMPILE_V8_PREFLIGHT_SNAPSHOT_SHA256"
    path_absent "$COMPILE_V8_BUILD_ROOT" || fail "compile-v8 immutable build root exists"
    require_exact_hash "$COMPILE_V7_CONTRACT" "$COMPILE_V7_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V7_MATERIAL" "$COMPILE_V7_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V7_RUNNER" "$COMPILE_V7_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/preflight.receipt.json" \
        "$COMPILE_V7_PREFLIGHT_RECEIPT_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/preflight.bound-artifacts.json" \
        "$COMPILE_V7_PREFLIGHT_MANIFEST_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/preflight.final-binding.json" \
        "$COMPILE_V7_PREFLIGHT_BINDING_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/preflight.status" \
        "$COMPILE_V7_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/compile.status" \
        "$COMPILE_V7_COMPILE_STATUS_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/cmake-configure.argv.json" \
        "$COMPILE_V7_CONFIGURE_ARGV_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/cmake-build.argv.json" \
        "$COMPILE_V7_BUILD_ARGV_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/cmake-configure.rc" \
        "$COMPILE_V7_COMMAND_RC_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/cmake-build.rc" \
        "$COMPILE_V7_COMMAND_RC_SHA256"
    require_exact_hash "$COMPILE_V7_LOG_ROOT/cmake-build.log" \
        "$COMPILE_V7_BUILD_LOG_SHA256"
    require_exact_hash "$COMPILE_V7_COMPILER_ROOT/collect-action-ledger.0.json" \
        "$COMPILE_V7_LEDGER_0_SHA256"
    require_exact_hash "$COMPILE_V7_COMPILER_ROOT/collect-action-ledger.1.json" \
        "$COMPILE_V7_LEDGER_1_SHA256"
    require_exact_hash "$COMPILE_V7_COMPILER_ROOT/collect-action-ledger.2.json" \
        "$COMPILE_V7_LEDGER_2_SHA256"
    require_exact_hash "$COMPILE_V7_COMPILER_ROOT/collect-build.count" \
        "$COMPILE_V7_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V7_COMPILER_ROOT/collect-inputs.pre.json" \
        "$COMPILE_V7_COLLECT_SNAPSHOT_SHA256"
    require_exact_hash "$COMPILE_V6_CONTRACT" "$COMPILE_V6_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V6_MATERIAL" "$COMPILE_V6_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V6_RUNNER" "$COMPILE_V6_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V6_LOG_ROOT/preflight.status" \
        "$COMPILE_V6_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V6_COMPILER_ROOT/staging/preflight-build.count" \
        "$COMPILE_V6_PREFLIGHT_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V6_COMPILER_ROOT/staging/frozen-inputs.pre.json" \
        "$COMPILE_V6_PREFLIGHT_SNAPSHOT_SHA256"
    path_absent "$COMPILE_V6_BUILD_ROOT" || fail "compile-v6 immutable build root exists"
    require_exact_hash "$COMPILE_V5_CONTRACT" "$COMPILE_V5_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V5_MATERIAL" "$COMPILE_V5_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V5_RUNNER" "$COMPILE_V5_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V5_LOG_ROOT/preflight.status" \
        "$COMPILE_V5_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V5_COMPILER_ROOT/staging/preflight-build.count" \
        "$COMPILE_V5_PREFLIGHT_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V5_COMPILER_ROOT/staging/frozen-inputs.pre.json" \
        "$COMPILE_V5_PREFLIGHT_SNAPSHOT_SHA256"
    path_absent "$COMPILE_V5_BUILD_ROOT" || fail "compile-v5 immutable build root exists"
    require_exact_hash "$COMPILE_V4_CONTRACT" "$COMPILE_V4_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V4_MATERIAL" "$COMPILE_V4_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V4_RUNNER" "$COMPILE_V4_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V4_LOG_ROOT/preflight.status" "$COMPILE_V4_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V4_COMPILER_ROOT/staging/preflight-build.count" \
        "$COMPILE_V4_PREFLIGHT_BUILD_COUNT_SHA256"
    path_absent "$COMPILE_V4_BUILD_ROOT" || fail "compile-v4 immutable build root exists"
    require_exact_hash "$COMPILE_V3_CONTRACT" "$COMPILE_V3_CONTRACT_SHA256"
    require_exact_hash "$COMPILE_V3_MATERIAL" "$COMPILE_V3_MATERIAL_SHA256"
    require_exact_hash "$COMPILE_V3_RUNNER" "$COMPILE_V3_RUNNER_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/preflight.receipt.json" "$COMPILE_V3_PREFLIGHT_RECEIPT_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/preflight.bound-artifacts.json" "$COMPILE_V3_PREFLIGHT_MANIFEST_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/preflight.final-binding.json" "$COMPILE_V3_PREFLIGHT_BINDING_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/preflight.status" "$COMPILE_V3_PREFLIGHT_STATUS_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/compile.status" "$COMPILE_V3_COMPILE_STATUS_SHA256"
    require_exact_hash "$COMPILE_V3_LOG_ROOT/cmake-configure.argv.json" "$COMPILE_V3_CONFIGURE_ARGV_SHA256"
    require_exact_hash "$COMPILE_V3_COMPILER_ROOT/collect-inputs.pre.json" "$COMPILE_V3_COLLECT_SNAPSHOT_SHA256"
    require_exact_hash "$COMPILE_V3_COMPILER_ROOT/collect-build.count" "$COMPILE_V3_BUILD_COUNT_SHA256"
    require_exact_hash "$COMPILE_V3_COMPILER_ROOT/collect-action-ledger.json" "$COMPILE_V3_INITIAL_LEDGER_SHA256"
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

    task_run_status_stage "preflight-compile-v12-order-closure"
    audit_compile_v12_order

    task_run_status_stage "preflight-compile-v11-failure-closure"
    audit_compile_v11_failure

    task_run_status_stage "preflight-compile-v10-failure-closure"
    audit_compile_v10_failure

    task_run_status_stage "preflight-compile-v9-failure-closure"
    audit_compile_v9_failure

    task_run_status_stage "preflight-compile-v8-failure-closure"
    audit_compile_v8_failure

    task_run_status_stage "preflight-compile-v7-root-fix"
    audit_compile_v7_root_fix

    task_run_status_stage "preflight-compile-v6-failure-closure"
    audit_compile_v6_failure

    task_run_status_stage "preflight-compile-v4-classifier"
    audit_compile_v4_classifier

    task_run_status_stage "preflight-compile-v3-failure-closure"
    audit_compile_v3_failure

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

    task_run_status_stage "preflight-collect-ledger-regression"
    audit_collect_ledger_regression

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
    local receipt_sha manifest_sha binding_sha snapshot_sha runner_sha predecessor_root_state
    seal_result=$(seal_preflight)
    read -r receipt_sha manifest_sha binding_sha snapshot_sha runner_sha predecessor_root_state <<<"$seal_result"
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
    [[ "$predecessor_root_state" == "absent" ||
       "$predecessor_root_state" == "empty-created-before-command" ]] ||
        fail "invalid predecessor root state=$predecessor_root_state"
    publish_preflight_marker "$receipt_sha" "$manifest_sha" "$binding_sha" "$snapshot_sha" \
        "$runner_sha" "$predecessor_root_state"
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
        "80e3f66d119949b2142b2a3f5f3ec56eea656bac27c6d2c4734f2016eee841ed" or
        receipt.get("material_sha256") !=
        "797e46c6f34ae05bb52d2f62662e142d3c2440290377af012cf62a6dbc43b005" or
        receipt.get("compile_v12_order_closure", {}).get(
            "compile_v12", {}).get("runner_sha256") !=
        "a5eee002ccbecb1855b75d0d28d4f780c4b8e1588fa5ae33c0773c165ea76bc5" or
        receipt.get("compile_v12_order_closure", {}).get(
            "compile_v12", {}).get("build_count") != 1 or
        receipt.get("compile_v12_order_closure", {}).get(
            "verfiles", {}).get("s_row_count") != 23 or
        receipt.get("compile_v12_order_closure", {}).get(
            "verfiles", {}).get("s_rows_lexicographic") is not True or
        receipt.get("compile_v12_order_closure", {}).get(
            "verfiles", {}).get("c_row_count") != 1 or
        receipt.get("compile_v12_order_closure", {}).get(
            "verfiles", {}).get("c_design_order") != "cmake-declaration-order" or
        receipt.get("compile_v12_order_closure", {}).get(
            "old_compile_v12_oracle", {}).get("accepted") is not False or
        set(receipt.get("compile_v12_order_closure", {}).get(
            "mutations_rejected", {})) != {
                "missing_s_row", "extra_s_row", "duplicate_s_row",
                "class_collision_or_substitution", "reordered_s_rows",
                "reordered_c_design_arguments", "duplicate_c_row", "missing_c_row",
                "comment_or_decoy_text"} or
        not all(receipt.get("compile_v12_order_closure", {}).get(
            "mutations_rejected", {}).values()) or
        receipt.get("compile_v11_failure_closure", {}).get(
            "compile_v11", {}).get("preflight_status_sha256") !=
        "0868e62dc3bd073d3af46c92d4071ac91858e52fe3854d099d6acb7f4582a1d8" or
        receipt.get("compile_v11_failure_closure", {}).get(
            "compile_v11", {}).get("preflight_rc") != 1 or
        receipt.get("compile_v11_failure_closure", {}).get(
            "root_cause", {}).get("common_prefix_length") != 15 or
        receipt.get("compile_v11_failure_closure", {}).get(
            "root_cause", {}).get("common_suffix_length") != 46 or
        receipt.get("compile_v11_failure_closure", {}).get(
            "root_cause", {}).get("malformed_middle_slice") != "" or
        receipt.get("compile_v11_failure_closure", {}).get(
            "root_cause", {}).get("correct_middle_slice") != "ee6" or
        receipt.get("compile_v10_failure_closure", {}).get(
            "compile_v10", {}).get("preflight_status_sha256") !=
        "9b01b2d6e6d27adecfdd3563b57b4ac02bd0fa7ce5492fe87f0f79fc5bb0e873" or
        receipt.get("compile_v10_failure_closure", {}).get(
            "compile_v10", {}).get("preflight_rc") != 1 or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("malformed_length") != 61 or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("correct_length") != 64 or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("common_prefix_length") != 15 or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("common_suffix_length") != 46 or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("malformed_middle_slice") != "" or
        receipt.get("compile_v10_failure_closure", {}).get(
            "root_cause", {}).get("correct_middle_slice") != "ee6" or
        receipt.get("compile_v9_failure_closure", {}).get(
            "compile_v9", {}).get("preflight_status_sha256") !=
        "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51" or
        receipt.get("compile_v9_failure_closure", {}).get(
            "compile_v9", {}).get("collect_executed") is not False or
        receipt.get("compile_v9_failure_closure", {}).get(
            "root_cause", {}).get("class") !=
        "unexplained-shell-hash-false-negative" or
        receipt.get("compile_v8_failure_closure", {}).get(
            "compile_v8", {}).get("preflight_status_sha256") !=
        "79184a20fea5d869495b2837d43f99b0334d69f785c14ae678b15180dca4d789" or
        receipt.get("compile_v8_failure_closure", {}).get(
            "compile_v8", {}).get("collect_executed") is not False or
        receipt.get("compile_v8_failure_closure", {}).get(
            "compile_v8", {}).get("preflight_build_count_audit", {}).get(
                "observed_sha256") !=
        "9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa" or
        not all(receipt.get("compile_v8_failure_closure", {}).get(
            "compile_v8", {}).get(
                "preflight_build_count_mutations_rejected", {}).values()) or
        receipt.get("compile_v7_root_fix", {}).get(
            "phase_topology_freeze", {}).get("stable_structure_id_sha256") !=
        "b9d4366c26b281bea20b8f3c459a4128e150be157afdbb7e1857580f7d81b0c3" or
        not all(receipt.get("compile_v7_root_fix", {}).get(
            "phase_topology_freeze", {}).get(
                "document_mutations_rejected", {}).values()) or
        not all(receipt.get("compile_v7_root_fix", {}).get(
            "overflow_admission", {}).get("mutations_rejected", {}).values()) or
        receipt.get("compile_v6_failure_closure", {}).get(
            "bash_function_boundary_inference") is not False or
        receipt.get("compile_v6_failure_closure", {}).get("census_windows") != 2 or
        receipt.get("compile_v6_failure_closure", {}).get(
            "compile_v6", {}).get("preflight_status_sha256") !=
        "be169b5dd1b5fd8f6f617470b21b9c4782cc49c69db6b6d2e9c83e707a76eeb5" or
        receipt.get("compile_v6_failure_closure", {}).get(
            "compile_v6", {}).get("build_count") != 0 or
        receipt.get("compile_v6_failure_closure", {}).get(
            "compile_v6", {}).get("collect_executed") is not False or
        receipt.get("compile_v6_failure_closure", {}).get(
            "compile_v5", {}).get("preflight_status_sha256") !=
        "e5b67181496437a35668c3bd1025b3e9e21e939d2f71ca29d5a03858bb8c5046" or
        receipt.get("compile_v4_classifier_closure", {}).get("preflight_status_sha256") !=
        "e33bbcfd04d022f8cf3f15f786db0475ec8f6d4200fe5cea937a28b973877c51" or
        receipt.get("compile_v4_classifier_closure", {}).get("build_count") != 0 or
        receipt.get("compile_v4_classifier_closure", {}).get("collect_executed") is not False or
        receipt.get("compile_v4_classifier_closure", {}).get("directory_membership") !=
        ["sealed", "staging", "work"] or
        receipt.get("compile_v4_classifier_closure", {}).get("regular_file_membership") !=
        ["staging/preflight-build.count"] or
        receipt.get("compile_v4_classifier_closure", {}).get("classifier_regression_passed") != 11 or
        receipt.get("compile_v3_failure_closure", {}).get("compile_status_sha256") !=
        "2856e07c603ed85e496181f60f17540d1f3cf89687752ff5ea50dc7fcf26e663" or
        receipt.get("compile_v3_failure_closure", {}).get("cmake_configure_executed") != 0 or
        receipt.get("compile_v3_failure_closure", {}).get("build_root_admissible") is not True or
        receipt.get("compile_v3_failure_closure", {}).get("build_root_state") not in
        {"absent", "empty-created-before-command"} or
        receipt.get("compile_v3_failure_closure", {}).get("build_root_entry_count") != 0 or
        receipt.get("compile_v3_failure_closure", {}).get("external_action_count") != 0 or
        receipt.get("predecessor_build_root_policy", {}).get("accepted_states") !=
        ["absent", "empty-created-before-command"] or
        receipt.get("predecessor_build_root_policy", {}).get("actual_state") !=
        receipt.get("compile_v3_failure_closure", {}).get("build_root_state") or
        receipt.get("collect_ledger_policy", {}).get("snapshot_filenames") !=
        ["collect-action-ledger.0.json", "collect-action-ledger.1.json",
         "collect-action-ledger.2.json"] or
        receipt.get("collect_ledger_policy", {}).get("snapshot_overwrite_sites") != 0 or
        receipt.get("collect_ledger_regression", {}).get(
            "old_same_path_second_write_rejected") is not True or
        receipt.get("collect_ledger_regression", {}).get(
            "three_distinct_fresh_paths_passed") is not True or
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

# COLLECT_LEDGER_WRITERS_BEGIN
initialize_collect_ledger() {
    python3 - "$NPU_ROOT/scripts" "$COLLECT_ACTION_LEDGER_0" <<'PY'
import pathlib
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import atomic_write_json

initial = {
    "schema": "qwen-f32-alu-families-compile-v13-action-ledger-v2",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "snapshot_index": 0,
    "publication_role": "pre-action",
    "admitted_action": None,
    "prior_snapshot_path": None,
    "prior_snapshot_sha256": None,
    "admission_argv_path": None,
    "admission_argv_sha256": None,
    "prior_action_rc_path": None,
    "prior_action_rc_sha256": None,
    "counts": {"cmake-configure": 0, "cmake-build": 0, "binary": 0,
               "model": 0, "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0},
    "ordered_actions": [],
}
atomic_write_json(pathlib.Path(sys.argv[2]), initial)
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
    python3 - "$NPU_ROOT/scripts" "$COLLECT_ACTION_LEDGER_0" \
        "$COLLECT_ACTION_LEDGER_1" "$COLLECT_ACTION_LEDGER_2" "$kind" \
        "$REPO_ROOT" "$argv_json" "$LOG_ROOT/cmake-configure.rc" "$@" <<'PY'
import hashlib
import pathlib
import stat
import sys
sys.path.insert(0, sys.argv[1])
from qwen_f32_alu_build_identity import (
    atomic_write_json, read_bytes_stable, read_json_same_bytes, sha256_bytes,
)

ledger0 = pathlib.Path(sys.argv[2])
ledger1 = pathlib.Path(sys.argv[3])
ledger2 = pathlib.Path(sys.argv[4])
kind = sys.argv[5]
cwd = pathlib.Path(sys.argv[6]).resolve(strict=True)
argv_path = pathlib.Path(sys.argv[7])
configure_rc_path = pathlib.Path(sys.argv[8])
argv = sys.argv[9:]
transitions = {
    "cmake-configure": (ledger0, ledger1, 0, 1),
    "cmake-build": (ledger1, ledger2, 1, 2),
}
if kind not in transitions:
    raise SystemExit("forbidden collect action")
prior_path, output_path, prior_index, output_index = transitions[kind]

zero_counts = {
    "cmake-configure": 0, "cmake-build": 0, "binary": 0, "model": 0,
    "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0,
}

def relative(path):
    return path.resolve(strict=False).relative_to(cwd).as_posix()

def expected_snapshot(index):
    if index == 0:
        return dict(zero_counts), [], None, "pre-action"
    if index == 1:
        return ({**zero_counts, "cmake-configure": 1},
                ["cmake-configure"], "cmake-configure", "configure-admission")
    if index == 2:
        return ({**zero_counts, "cmake-configure": 1, "cmake-build": 1},
                ["cmake-configure", "cmake-build"], "cmake-build", "build-admission")
    raise SystemExit("invalid collect snapshot index")

def validate_snapshot(path, index, expected_prior_path=None, expected_prior_sha=None):
    value, digest, _ = read_json_same_bytes(path)
    counts, ordered, admitted, role = expected_snapshot(index)
    if (
        value.get("schema") != "qwen-f32-alu-families-compile-v13-action-ledger-v2"
        or value.get("task_id") != "qwen-f32-alu-families-compile-v13"
        or value.get("snapshot_index") != index
        or value.get("publication_role") != role
        or value.get("admitted_action") != admitted
        or value.get("counts") != counts
        or value.get("ordered_actions") != ordered
        or value.get("prior_snapshot_path") != expected_prior_path
        or value.get("prior_snapshot_sha256") != expected_prior_sha
    ):
        raise SystemExit("collect snapshot schema/task/action/count/order mismatch")
    if index == 0:
        if any(value.get(field) is not None for field in (
            "admission_argv_path", "admission_argv_sha256",
            "prior_action_rc_path", "prior_action_rc_sha256",
        )):
            raise SystemExit("initial snapshot contains action bindings")
    else:
        bound_argv = cwd / value["admission_argv_path"]
        if sha256_bytes(read_bytes_stable(bound_argv)) != value.get("admission_argv_sha256"):
            raise SystemExit("snapshot admission argv binding mismatch")
        if index == 1 and (value.get("prior_action_rc_path") is not None or
                           value.get("prior_action_rc_sha256") is not None):
            raise SystemExit("configure admission has unexpected prior rc binding")
    return value, digest

ledger0_value, ledger0_sha = validate_snapshot(ledger0, 0)
if prior_index == 0:
    prior_value, prior_sha = ledger0_value, ledger0_sha
else:
    prior_value, prior_sha = validate_snapshot(
        ledger1, 1, relative(ledger0), ledger0_sha
    )
    if read_bytes_stable(configure_rc_path) != b"0\n":
        raise SystemExit("build admission requires configure rc0")

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
argv_sha = atomic_write_json(argv_path, {
    "schema": "qwen-f32-alu-families-compile-v13-actual-argv-v1",
    "kind": kind, "cwd": str(cwd), "argv": argv,
    "executable": str(executable), "executable_sha256": hashlib.sha256(data).hexdigest(),
    "executable_mode": "0755", "executable_size": len(data),
    "environment": {"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
})
counts, ordered, admitted, role = expected_snapshot(output_index)
next_ledger = {
    "schema": "qwen-f32-alu-families-compile-v13-action-ledger-v2",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "snapshot_index": output_index,
    "publication_role": role,
    "admitted_action": admitted,
    "prior_snapshot_path": relative(prior_path),
    "prior_snapshot_sha256": prior_sha,
    "admission_argv_path": relative(argv_path),
    "admission_argv_sha256": argv_sha,
    "prior_action_rc_path": relative(configure_rc_path) if output_index == 2 else None,
    "prior_action_rc_sha256": (
        sha256_bytes(read_bytes_stable(configure_rc_path)) if output_index == 2 else None
    ),
    "counts": counts,
    "ordered_actions": ordered,
}
atomic_write_json(output_path, next_ledger)
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
# COLLECT_LEDGER_WRITERS_END

audit_collect_evidence() {
    resolve_tools
    mkdir -m 700 -- "$NORMALIZED_DEPFILE_ROOT"
    python3 - "$REPO_ROOT" "$NPU_ROOT/scripts" "$BUILD_ROOT" "$CMAKE_BUILD_ROOT" \
        "$VERILATED_ROOT" "$VERILATOR_ROOT" "$VERILATOR_BIN_EXE" \
        "$EXPECTED_WARNING_COPY" "$LOG_ROOT/cmake-build.log" \
        "$COLLECT_ACTION_LEDGER_0" "$COLLECT_ACTION_LEDGER_1" \
        "$COLLECT_ACTION_LEDGER_2" \
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
ledger0_path = pathlib.Path(sys.argv[10])
ledger1_path = pathlib.Path(sys.argv[11])
ledger2_path = pathlib.Path(sys.argv[12])
configure_argv_path = pathlib.Path(sys.argv[13])
build_argv_path = pathlib.Path(sys.argv[14])
configure_rc = pathlib.Path(sys.argv[15])
build_rc = pathlib.Path(sys.argv[16])
normalized_root = pathlib.Path(sys.argv[17])
command_output = pathlib.Path(sys.argv[18])
actual_warning_output = pathlib.Path(sys.argv[19])
warning_output = pathlib.Path(sys.argv[20])
membership_output = pathlib.Path(sys.argv[21])
depfile_output = pathlib.Path(sys.argv[22])
artifact_output = pathlib.Path(sys.argv[23])
design_rel = sys.argv[24:]

ledger0, ledger0_sha, _ = read_json_same_bytes(ledger0_path)
ledger1, ledger1_sha, _ = read_json_same_bytes(ledger1_path)
ledger2, ledger2_sha, _ = read_json_same_bytes(ledger2_path)
zero_counts = {"cmake-configure": 0, "cmake-build": 0, "binary": 0,
               "model": 0, "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0}
relative = lambda path: path.resolve(strict=True).relative_to(root).as_posix()
if (ledger0.get("schema") != "qwen-f32-alu-families-compile-v13-action-ledger-v2" or
        ledger0.get("task_id") != "qwen-f32-alu-families-compile-v13" or
        ledger0.get("snapshot_index") != 0 or ledger0.get("publication_role") != "pre-action" or
        ledger0.get("admitted_action") is not None or ledger0.get("prior_snapshot_path") is not None or
        ledger0.get("prior_snapshot_sha256") is not None or ledger0.get("counts") != zero_counts or
        ledger0.get("ordered_actions") != [] or
        ledger1.get("schema") != "qwen-f32-alu-families-compile-v13-action-ledger-v2" or
        ledger1.get("task_id") != "qwen-f32-alu-families-compile-v13" or
        ledger1.get("snapshot_index") != 1 or ledger1.get("publication_role") != "configure-admission" or
        ledger1.get("admitted_action") != "cmake-configure" or
        ledger1.get("prior_snapshot_path") != relative(ledger0_path) or
        ledger1.get("prior_snapshot_sha256") != ledger0_sha or
        ledger1.get("admission_argv_path") != relative(configure_argv_path) or
        ledger1.get("admission_argv_sha256") != sha256_bytes(read_bytes_stable(configure_argv_path)) or
        ledger1.get("prior_action_rc_path") is not None or
        ledger1.get("prior_action_rc_sha256") is not None or
        ledger1.get("counts") != {**zero_counts, "cmake-configure": 1} or
        ledger1.get("ordered_actions") != ["cmake-configure"] or
        ledger2.get("schema") != "qwen-f32-alu-families-compile-v13-action-ledger-v2" or
        ledger2.get("task_id") != "qwen-f32-alu-families-compile-v13" or
        ledger2.get("snapshot_index") != 2 or ledger2.get("publication_role") != "build-admission" or
        ledger2.get("admitted_action") != "cmake-build" or
        ledger2.get("prior_snapshot_path") != relative(ledger1_path) or
        ledger2.get("prior_snapshot_sha256") != ledger1_sha or
        ledger2.get("admission_argv_path") != relative(build_argv_path) or
        ledger2.get("admission_argv_sha256") != sha256_bytes(read_bytes_stable(build_argv_path)) or
        ledger2.get("prior_action_rc_path") != relative(configure_rc) or
        ledger2.get("prior_action_rc_sha256") != sha256_bytes(read_bytes_stable(configure_rc)) or
        ledger2.get("counts") != {**zero_counts, "cmake-configure": 1, "cmake-build": 1} or
        ledger2.get("ordered_actions") != ["cmake-configure", "cmake-build"] or
        read_bytes_stable(configure_rc) != b"0\n" or read_bytes_stable(build_rc) != b"0\n"):
    raise SystemExit("collect action ledger chain/return-code mismatch")
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
    "schema": "qwen-f32-alu-families-compile-v13-build-diagnostics-v1",
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
verfiles_data = read_bytes_stable(verfiles)
try:
    verfiles_text = verfiles_data.decode("utf-8")
except UnicodeDecodeError as exc:
    raise SystemExit("actual __verFiles.dat is not UTF-8: " + str(exc))
if "\0" in verfiles_text:
    raise SystemExit("actual __verFiles.dat NUL rejected")
verfiles_lines = verfiles_text.splitlines()
description = "# DESCRIPTION: Verilator output: Timestamp data for --skip-identical.  Delete at will."
if not verfiles_lines or verfiles_lines[0] != description:
    raise SystemExit("actual __verFiles.dat description mismatch")
rows = []
c_payloads = []
comment_count = 0
for index, line in enumerate(verfiles_lines):
    if line.startswith("#"):
        comment_count += 1
        if index != 0 or line != description:
            raise SystemExit("actual __verFiles.dat comment/decoy rejected")
        continue
    fields = shlex.split(line, comments=False, posix=True)
    if not fields or fields[0] not in {"C", "S", "T"}:
        raise SystemExit("actual __verFiles.dat unknown/decoy row rejected")
    if fields[0] == "C":
        if len(fields) != 2:
            raise SystemExit("actual __verFiles.dat C row shape mismatch")
        c_payloads.append(fields[1])
        continue
    if len(fields) != 8 or any(not value.isdigit() for value in fields[1:7]):
        raise SystemExit("actual __verFiles.dat row shape mismatch")
    path = pathlib.Path(fields[-1])
    if not path.is_absolute() or str(path.resolve(strict=True)) != fields[-1]:
        raise SystemExit("actual __verFiles.dat noncanonical path rejected")
    if fields[0] == "S":
        rows.append(fields[-1])
    elif not path.is_relative_to(verilated_root):
        raise SystemExit("actual __verFiles.dat T row escaped generated root")
owners = {path: name for name, values in expected_groups.items() for path in values}
expected_s_rows = sorted(owners)
if (comment_count != 1 or len(c_payloads) != 1 or len(owners) != 23 or
        len(rows) != 23 or len(set(rows)) != 23 or set(rows) != set(owners)):
    raise SystemExit("actual __verFiles.dat exact C/S 21+1+1 membership mismatch")
if rows != expected_s_rows:
    raise SystemExit("actual __verFiles.dat S row lexicographic order mismatch")
c_argv = shlex.split(c_payloads[0], comments=False, posix=True)
expected_c_prefix = [
    "--cc", "-O3", "-Wall", "-Wno-fatal", "--no-assert", "--no-trace",
    "-I" + str(root / "npu/version_0820/rtl"), "--Mdir", str(verilated_root),
    "--top-module", "TensorNpuCoprocessor", "-CFLAGS", "-O3", "-DNDEBUG",
    "-march=native", "-fPIC",
]
if c_argv != expected_c_prefix + expected_groups["design"]:
    raise SystemExit("actual __verFiles.dat C argv/21-source CMake order mismatch")
atomic_write_json(membership_output, {
    "schema": "qwen-f32-alu-families-compile-v13-elaboration-membership-v1",
    "verfiles_path": str(verfiles), "verfiles_sha256": sha256_bytes(verfiles_data),
    "raw_s_row_count": len(rows), "raw_s_rows": rows,
    "classes": expected_groups, "class_counts": {"design": 21, "control": 1, "tool": 1},
    "raw_c_row_count": len(c_payloads), "c_argv": c_argv,
    "compile_membership_status": "PASS", "s_rows_lexicographic": True,
    "c_design_order": "cmake-declaration-order", "c_pinned_argv": True,
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
    "schema": "qwen-f32-alu-families-compile-v13-object-depfile-closure-v1",
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
    "schema": "qwen-f32-alu-families-compile-v13-actual-command-ledger-v1",
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
    "schema": "qwen-f32-alu-families-compile-v13-build-artifact-manifest-v1",
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
        "$COLLECT_ACTION_LEDGER_0" "$COLLECT_ACTION_LEDGER_1" \
        "$COLLECT_ACTION_LEDGER_2" "$COLLECT_SNAPSHOT_PRE" "$COLLECT_SNAPSHOT_POST" \
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
    "collect-action-ledger.0.json": "qwen-f32-alu-families-compile-v13-action-ledger-v2",
    "collect-action-ledger.1.json": "qwen-f32-alu-families-compile-v13-action-ledger-v2",
    "collect-action-ledger.2.json": "qwen-f32-alu-families-compile-v13-action-ledger-v2",
    "collect-inputs.pre.json": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "collect-inputs.post.json": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "collect-inputs.prestatus.json": "qwen-f32-alu-families-compile-v13-frozen-inputs-v1",
    "collect-process-audit.json": "qwen-f32-alu-families-compile-v13-process-audit-v1",
    "actual-command-ledger.json": "qwen-f32-alu-families-compile-v13-actual-command-ledger-v1",
    "build-diagnostic-audit.json": "qwen-f32-alu-families-compile-v13-build-diagnostics-v1",
    "elaboration-membership.json": "qwen-f32-alu-families-compile-v13-elaboration-membership-v1",
    "object-depfile-closure.json": "qwen-f32-alu-families-compile-v13-object-depfile-closure-v1",
    "build-artifact-manifest.json": "qwen-f32-alu-families-compile-v13-build-artifact-manifest-v1",
    "cmake-configure.argv.json": "qwen-f32-alu-families-compile-v13-actual-argv-v1",
    "cmake-build.argv.json": "qwen-f32-alu-families-compile-v13-actual-argv-v1",
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
ledger_paths = {
    path.name: path for path in artifact_paths
    if path.name.startswith("collect-action-ledger.")
}
ledger0 = parsed["collect-action-ledger.0.json"]
ledger1 = parsed["collect-action-ledger.1.json"]
ledger2 = parsed["collect-action-ledger.2.json"]
ledger0_sha = sha256_bytes(read_bytes_stable(ledger_paths["collect-action-ledger.0.json"]))
ledger1_sha = sha256_bytes(read_bytes_stable(ledger_paths["collect-action-ledger.1.json"]))
ledger2_sha = sha256_bytes(read_bytes_stable(ledger_paths["collect-action-ledger.2.json"]))
configure_argv_path = next(path for path in artifact_paths if path.name == "cmake-configure.argv.json")
build_argv_path = next(path for path in artifact_paths if path.name == "cmake-build.argv.json")
configure_rc_path = next(path for path in artifact_paths if path.name == "cmake-configure.rc")
relative = lambda path: path.resolve(strict=True).relative_to(root).as_posix()
zero_counts = {"cmake-configure": 0, "cmake-build": 0, "binary": 0,
               "model": 0, "qwen": 0, "synthesis": 0, "sta": 0, "ppa": 0}
if (
    any(ledger.get("schema") != "qwen-f32-alu-families-compile-v13-action-ledger-v2"
        or ledger.get("task_id") != "qwen-f32-alu-families-compile-v13"
        for ledger in (ledger0, ledger1, ledger2))
    or ledger0.get("snapshot_index") != 0
    or ledger0.get("counts") != zero_counts
    or ledger0.get("ordered_actions") != []
    or ledger1.get("snapshot_index") != 1
    or ledger1.get("prior_snapshot_path") != relative(ledger_paths["collect-action-ledger.0.json"])
    or ledger1.get("prior_snapshot_sha256") != ledger0_sha
    or ledger1.get("admission_argv_path") != relative(configure_argv_path)
    or ledger1.get("admission_argv_sha256") != sha256_bytes(read_bytes_stable(configure_argv_path))
    or ledger1.get("counts") != {**zero_counts, "cmake-configure": 1}
    or ledger1.get("ordered_actions") != ["cmake-configure"]
    or ledger2.get("snapshot_index") != 2
    or ledger2.get("prior_snapshot_path") != relative(ledger_paths["collect-action-ledger.1.json"])
    or ledger2.get("prior_snapshot_sha256") != ledger1_sha
    or ledger2.get("admission_argv_path") != relative(build_argv_path)
    or ledger2.get("admission_argv_sha256") != sha256_bytes(read_bytes_stable(build_argv_path))
    or ledger2.get("prior_action_rc_path") != relative(configure_rc_path)
    or ledger2.get("prior_action_rc_sha256") != sha256_bytes(read_bytes_stable(configure_rc_path))
    or ledger2.get("counts") != {**zero_counts, "cmake-configure": 1, "cmake-build": 1}
    or ledger2.get("ordered_actions") != ["cmake-configure", "cmake-build"]
):
    raise SystemExit("compile append-only ledger chain semantic mismatch")
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
        membership.get("raw_s_row_count") != 23 or membership.get("raw_c_row_count") != 1 or
        membership.get("s_rows_lexicographic") is not True or
        membership.get("c_design_order") != "cmake-declaration-order" or
        membership.get("c_pinned_argv") is not True or
        warnings.get("actual_warning_rows") != 25 or warnings.get("error_count") != 0 or
        closure.get("compiler_argv_exact") is not True or closure.get("normalized_strict_parser") != "PASS" or
        build_manifest.get("binary_execution_count") != 0 or
        build_manifest.get("wave_trace_coverage_file_count") != 0 or
        process.get("owned_background_jobs") != 0):
    raise SystemExit("compile evidence semantic mismatch")

receipt = {
    "schema": "qwen-f32-alu-families-compile-v13-compile-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v13",
    "contract_sha256": "80e3f66d119949b2142b2a3f5f3ec56eea656bac27c6d2c4734f2016eee841ed",
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
    "actual_membership": {"design": 21, "control": 1, "tool": 1,
                          "s_rows": 23, "c_rows": 1},
    "s_rows_lexicographic": True,
    "c_design_order": "cmake-declaration-order",
    "collect_action_ledger_chain": [
        {"path": relative(ledger_paths["collect-action-ledger.0.json"]),
         "sha256": ledger0_sha, "snapshot_index": 0,
         "ordered_actions": ledger0["ordered_actions"]},
        {"path": relative(ledger_paths["collect-action-ledger.1.json"]),
         "sha256": ledger1_sha, "snapshot_index": 1,
         "prior_snapshot_sha256": ledger1["prior_snapshot_sha256"],
         "admission_argv_sha256": ledger1["admission_argv_sha256"],
         "ordered_actions": ledger1["ordered_actions"]},
        {"path": relative(ledger_paths["collect-action-ledger.2.json"]),
         "sha256": ledger2_sha, "snapshot_index": 2,
         "prior_snapshot_sha256": ledger2["prior_snapshot_sha256"],
         "admission_argv_sha256": ledger2["admission_argv_sha256"],
         "prior_action_rc_sha256": ledger2["prior_action_rc_sha256"],
         "ordered_actions": ledger2["ordered_actions"]},
    ],
    "collect_action_ledger_append_only": True,
    "collect_action_ledger_overwrites": 0,
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
    root, receipt_path, "qwen-f32-alu-families-compile-v13-compile-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {"schema": "qwen-f32-alu-families-compile-v13-compile-bound-artifacts-v1",
            "task_id": "qwen-f32-alu-families-compile-v13", "artifact_count": len(bound),
            "artifacts": bound, "artifact_identity": revalidate_bound_artifacts(root, bound),
            "receipt_sha256": receipt_sha}
atomic_write_json(manifest_path, manifest)
_, manifest_sha, _ = read_json_same_bytes(manifest_path)
atomic_write_bytes(expected_path, b"PASS\n")
binding = {"schema": "qwen-f32-alu-families-compile-v13-compile-final-binding-v1",
           "task_id": "qwen-f32-alu-families-compile-v13", "receipt_sha256": receipt_sha,
           "receipt_sidecar_sha256": sha256_bytes(sidecar), "bound_artifacts_sha256": manifest_sha,
           "build_artifact_manifest_sha256": receipt["build_artifact_manifest_sha256"],
           "linked_binary_sha256": receipt["linked_binary_sha256"],
           "collect_action_ledger_snapshot_sha256": [ledger0_sha, ledger1_sha, ledger2_sha],
           "collect_action_ledger_append_only": True,
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
        binding.get("collect_action_ledger_snapshot_sha256") !=
        [record.get("sha256") for record in receipt.get("collect_action_ledger_chain", [])] or
        receipt.get("collect_action_ledger_append_only") is not True or
        receipt.get("collect_action_ledger_overwrites") != 0 or
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
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V13][COMPILE-PASS-CANDIDATE] build_count=1 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 wave_trace_coverage_files=0 actual_configured_argv=1 collect_ledger_snapshots=0+1+2 collect_ledger_append_only=1 collect_ledger_overwrites=0 collect_order=configure-before-build cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 compile_membership=21+1+1 s_rows=23-unique-lexicographic c_rows=1 c_design_order=21-cmake-declaration objects=$object_count depfiles=$depfile_count objects_depfiles=exact warning_census=25-exact warning_expected_sha256=$WARNING_EXPECTED_SHA256 linked_binary_sha256=$binary_sha verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha"
}

run_collect() {
    [[ -d "$LOG_ROOT" && ! -L "$LOG_ROOT" ]] || fail "preflight log root missing/aliased"
    [[ -d "$COMPILER_ROOT" && ! -L "$COMPILER_ROOT" ]] || fail "preflight compiler root missing/aliased"
    path_absent "$BUILD_ROOT" || fail "fresh build root already exists=$BUILD_ROOT"
    path_absent "$COMPILE_STATUS" || fail "compile status already exists"
    path_absent "$COLLECT_BUILD_COUNT" || fail "collect build count already exists"
    path_absent "$COLLECT_ACTION_LEDGER_0" || fail "collect ledger snapshot0 already exists"
    path_absent "$COLLECT_ACTION_LEDGER_1" || fail "collect ledger snapshot1 already exists"
    path_absent "$COLLECT_ACTION_LEDGER_2" || fail "collect ledger snapshot2 already exists"

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
