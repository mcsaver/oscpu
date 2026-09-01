#!/usr/bin/env bash
set -euo pipefail

# Qwen F32 ALU families compile-v7：fresh O3/no-assert/no-trace compile-only
# provenance collector。--preflight 必须保持 build-free；--collect 只能在后续显式
# continuation 下执行，且永远不运行生成的 model、backend binary 或 Qwen workload。

REPO_ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
NPU_ROOT="$REPO_ROOT/npu/version_0820"
TASK_ID="qwen-f32-alu-families-compile-v7"
RUNNER_REL="npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v7.sh"
RUNNER="$REPO_ROOT/$RUNNER_REL"
LOG_ROOT="$NPU_ROOT/tmp/logs/$TASK_ID"
COMPILER_ROOT="$NPU_ROOT/tmp/compiler/$TASK_ID"
BUILD_ROOT="$NPU_ROOT/tmp/build/$TASK_ID"
STAGING_ROOT="$COMPILER_ROOT/staging"
SEALED_ROOT="$COMPILER_ROOT/sealed"
WORK_ROOT="$COMPILER_ROOT/work"

STATUS_HELPER="$REPO_ROOT/scripts/task-run-status.sh"
STATUS_HELPER_TEST="$REPO_ROOT/scripts/tests/test-task-run-status.sh"
CONTRACT="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v7.json"
MATERIAL="$NPU_ROOT/tmp/contracts/qwen-f32-alu-families-compile-v7-material.md"
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

CONTRACT_SHA256="3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9"
MATERIAL_SHA256="5f11f4d2adfa8f05d8ed0fe94cc112f2a838e8dac05d78a6826bfb31a21fe9d0"
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
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v7.json
    npu/version_0820/tmp/contracts/qwen-f32-alu-families-compile-v7-material.md
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
    npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v7.sh
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
    npu/version_0820/tmp/logs/qwen-f32-alu-cmake-tool-v4
    npu/version_0820/tmp/tools/cmake-3.31.12
)

export PYTHONDONTWRITEBYTECODE=1
export LC_ALL=C

STATUS_HELPER_OBSERVED=$(sha256sum "$STATUS_HELPER")
[[ "${STATUS_HELPER_OBSERVED%% *}" == "$STATUS_HELPER_SHA256" ]] || {
    printf '%s\n' \
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V7][FAIL] status helper hash mismatch before source" >&2
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
    printf '%s\n' "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V7][FAIL] $*" >&2
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
    "schema": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-v11-closure-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-compile-v6-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-compile-v4-classifier-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-compile-v3-failure-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-cmake-tool-v4-audit-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-warning-oracle-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-collect-policy-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
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
        "schema": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
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
    "schema": "qwen-f32-alu-families-compile-v7-ledger-regression-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-process-audit-v1",
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
        "$CMAKE_TOOL_V4_AUDIT" "$COMPILE_V6_FAILURE_AUDIT"
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
    "frozen-inputs.pre.json": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "frozen-inputs.post.json": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "cmake-source-identity.json": "qwen-f32-alu-build-identity-v1",
    "v11-closure-audit.json": "qwen-f32-alu-families-compile-v7-v11-closure-v1",
    "cmake-tool-v4-audit.json": "qwen-f32-alu-families-compile-v7-cmake-tool-v4-audit-v1",
    "compile-v6-failure-audit.json": "qwen-f32-alu-families-compile-v7-compile-v6-failure-audit-v1",
    "compile-v4-classifier-audit.json": "qwen-f32-alu-families-compile-v7-compile-v4-classifier-audit-v1",
    "compile-v3-failure-audit.json": "qwen-f32-alu-families-compile-v7-compile-v3-failure-audit-v1",
    "warning-oracle-audit.json": "qwen-f32-alu-families-compile-v7-warning-oracle-v1",
    "collect-policy-audit.json": "qwen-f32-alu-families-compile-v7-collect-policy-v1",
    "mutable-ledger.json": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
    "collect-action-ledger.0.json": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
    "collect-action-ledger.1.json": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
    "collect-action-ledger.2.json": "qwen-f32-alu-families-compile-v7-ledger-regression-sample-v1",
    "collect-ledger-regression.json": "qwen-f32-alu-families-compile-v7-ledger-regression-v1",
    "preflight-process-audit.json": "qwen-f32-alu-families-compile-v7-process-audit-v1",
}
artifacts = {}
parsed = {}
for path in artifact_paths:
    schema = schemas.get(path.name)
    if path.parent.name == "sealed":
        schema = "qwen-f32-alu-families-compile-v7-frozen-inputs-v1"
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
compile_v6 = parsed["compile-v6-failure-audit.json"]
compile_v4 = parsed["compile-v4-classifier-audit.json"]
compile_v3 = parsed["compile-v3-failure-audit.json"]
ledger_regression = parsed["collect-ledger-regression.json"]
cmake = parsed["cmake-source-identity.json"]
process = parsed["preflight-process-audit.json"]
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

runner_relative = "npu/version_0820/scripts/run-qwen-f32-alu-families-compile-v7.sh"
receipt = {
    "schema": "qwen-f32-alu-families-compile-v7-preflight-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
    "contract_sha256": "3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9",
    "material_sha256": "5f11f4d2adfa8f05d8ed0fe94cc112f2a838e8dac05d78a6826bfb31a21fe9d0",
    "runner_sha256": pre["files"][runner_relative]["sha256"],
    "frozen_input_identity_sha256": pre["identity_sha256"],
    "frozen_input_file_count": pre["file_count"],
    "content_addressed_snapshot": content_path.relative_to(root).as_posix(),
    "content_addressed_snapshot_sha256": content_sha,
    "warning_expected_sha256": warning["expected_tsv_sha256"],
    "warning_expected_rows": 25,
    "warning_mutations_rejected": warning["mutations_rejected"],
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
    root, receipt_path, "qwen-f32-alu-families-compile-v7-preflight-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {
    "schema": "qwen-f32-alu-families-compile-v7-preflight-bound-artifacts-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
    "schema": "qwen-f32-alu-families-compile-v7-preflight-final-binding-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
if read_bytes_stable(root / "npu/version_0820/tmp/compiler/qwen-f32-alu-families-compile-v7/staging/preflight-build.count") != b"0\n":
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
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V7][PREFLIGHT-PASS] build_count=0 build_root_absent=1 cmake_version=0 cmake_configure=0 cmake_build=0 ninja=0 verilator=0 verilator_generation=0 make=0 model_make=0 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 owned_background_jobs=0 compile_v6_failure=bound compile_v6_status_sha256=$COMPILE_V6_PREFLIGHT_STATUS_SHA256 compile_v6_runner_sha256=$COMPILE_V6_RUNNER_SHA256 compile_v6_snapshot_sha256=$COMPILE_V6_PREFLIGHT_SNAPSHOT_SHA256 compile_v6_direct_census=PASS compile_v6_function_boundary_inference=0 compile_v5_status_sha256=$COMPILE_V5_PREFLIGHT_STATUS_SHA256 compile_v5_runner_sha256=$COMPILE_V5_RUNNER_SHA256 compile_v4_classifier=PASS compile_v4_status_sha256=$COMPILE_V4_PREFLIGHT_STATUS_SHA256 compile_v4_runner_sha256=$COMPILE_V4_RUNNER_SHA256 compile_v4_directory_census=3-exact compile_v4_regular_file_census=1-exact compile_v4_census_windows=2 compile_v4_classifier_regressions=11/11 compile_v3_failure=bound compile_v3_status_sha256=$COMPILE_V3_COMPILE_STATUS_SHA256 compile_v3_initial_ledger_sha256=$COMPILE_V3_INITIAL_LEDGER_SHA256 compile_v3_build_root_state=$predecessor_root_state compile_v3_build_root_entries=0 compile_v3_external_actions=0 compile_v3_root_classifier_regressions=6/6 ledger_old_pattern_rejected=1 ledger_three_fresh_snapshots=PASS ledger_snapshot_writers=1+1+1 ledger_snapshot_overwrites=0 ledger_order=configure-before-build cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 cmake_size=$PINNED_CMAKE_SIZE cmake_mode=0755 cmake_tree_entries=8173 cmake_tree_sha256=$PINNED_CMAKE_TREE_SHA256 cmake_v4_receipt_sha256=$CMAKE_V4_RECEIPT_SHA256 cmake_v4_manifest_sha256=$CMAKE_V4_MANIFEST_SHA256 cmake_v4_binding_sha256=$CMAKE_V4_BINDING_SHA256 cmake_v4_status_sha256=$CMAKE_V4_STATUS_SHA256 compile_v2_status_sha256=$COMPILE_V2_STATUS_SHA256 warning_expected_sha256=$WARNING_EXPECTED_SHA256 warning_rows=25-exact warning_mutations=7/7 cmake_source_count=21 frozen_cmake_template=PASS actual_configured_argv=GAP compile_membership=GAP verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN contract_sha256=$CONTRACT_SHA256 runner_sha256=$runner_sha receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha snapshot_sha256=$snapshot_sha"
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
        "3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9" or
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
    "schema": "qwen-f32-alu-families-compile-v7-action-ledger-v2",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
        value.get("schema") != "qwen-f32-alu-families-compile-v7-action-ledger-v2"
        or value.get("task_id") != "qwen-f32-alu-families-compile-v7"
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
    "schema": "qwen-f32-alu-families-compile-v7-actual-argv-v1",
    "kind": kind, "cwd": str(cwd), "argv": argv,
    "executable": str(executable), "executable_sha256": hashlib.sha256(data).hexdigest(),
    "executable_mode": "0755", "executable_size": len(data),
    "environment": {"LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1"},
})
counts, ordered, admitted, role = expected_snapshot(output_index)
next_ledger = {
    "schema": "qwen-f32-alu-families-compile-v7-action-ledger-v2",
    "task_id": "qwen-f32-alu-families-compile-v7",
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
if (ledger0.get("schema") != "qwen-f32-alu-families-compile-v7-action-ledger-v2" or
        ledger0.get("task_id") != "qwen-f32-alu-families-compile-v7" or
        ledger0.get("snapshot_index") != 0 or ledger0.get("publication_role") != "pre-action" or
        ledger0.get("admitted_action") is not None or ledger0.get("prior_snapshot_path") is not None or
        ledger0.get("prior_snapshot_sha256") is not None or ledger0.get("counts") != zero_counts or
        ledger0.get("ordered_actions") != [] or
        ledger1.get("schema") != "qwen-f32-alu-families-compile-v7-action-ledger-v2" or
        ledger1.get("task_id") != "qwen-f32-alu-families-compile-v7" or
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
        ledger2.get("schema") != "qwen-f32-alu-families-compile-v7-action-ledger-v2" or
        ledger2.get("task_id") != "qwen-f32-alu-families-compile-v7" or
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
    "schema": "qwen-f32-alu-families-compile-v7-build-diagnostics-v1",
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
    "schema": "qwen-f32-alu-families-compile-v7-elaboration-membership-v1",
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
    "schema": "qwen-f32-alu-families-compile-v7-object-depfile-closure-v1",
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
    "schema": "qwen-f32-alu-families-compile-v7-actual-command-ledger-v1",
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
    "schema": "qwen-f32-alu-families-compile-v7-build-artifact-manifest-v1",
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
    "collect-action-ledger.0.json": "qwen-f32-alu-families-compile-v7-action-ledger-v2",
    "collect-action-ledger.1.json": "qwen-f32-alu-families-compile-v7-action-ledger-v2",
    "collect-action-ledger.2.json": "qwen-f32-alu-families-compile-v7-action-ledger-v2",
    "collect-inputs.pre.json": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "collect-inputs.post.json": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "collect-inputs.prestatus.json": "qwen-f32-alu-families-compile-v7-frozen-inputs-v1",
    "collect-process-audit.json": "qwen-f32-alu-families-compile-v7-process-audit-v1",
    "actual-command-ledger.json": "qwen-f32-alu-families-compile-v7-actual-command-ledger-v1",
    "build-diagnostic-audit.json": "qwen-f32-alu-families-compile-v7-build-diagnostics-v1",
    "elaboration-membership.json": "qwen-f32-alu-families-compile-v7-elaboration-membership-v1",
    "object-depfile-closure.json": "qwen-f32-alu-families-compile-v7-object-depfile-closure-v1",
    "build-artifact-manifest.json": "qwen-f32-alu-families-compile-v7-build-artifact-manifest-v1",
    "cmake-configure.argv.json": "qwen-f32-alu-families-compile-v7-actual-argv-v1",
    "cmake-build.argv.json": "qwen-f32-alu-families-compile-v7-actual-argv-v1",
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
    any(ledger.get("schema") != "qwen-f32-alu-families-compile-v7-action-ledger-v2"
        or ledger.get("task_id") != "qwen-f32-alu-families-compile-v7"
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
        warnings.get("actual_warning_rows") != 25 or warnings.get("error_count") != 0 or
        closure.get("compiler_argv_exact") is not True or closure.get("normalized_strict_parser") != "PASS" or
        build_manifest.get("binary_execution_count") != 0 or
        build_manifest.get("wave_trace_coverage_file_count") != 0 or
        process.get("owned_background_jobs") != 0):
    raise SystemExit("compile evidence semantic mismatch")

receipt = {
    "schema": "qwen-f32-alu-families-compile-v7-compile-receipt-v1",
    "task_id": "qwen-f32-alu-families-compile-v7",
    "contract_sha256": "3d9119640876ccb447428c9044de7f3775fb0820ef7ab72099b604457f671ac9",
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
    root, receipt_path, "qwen-f32-alu-families-compile-v7-compile-receipt-v1")
bound[sidecar_path.relative_to(root).as_posix()] = build_artifact_record(root, sidecar_path, None)
manifest = {"schema": "qwen-f32-alu-families-compile-v7-compile-bound-artifacts-v1",
            "task_id": "qwen-f32-alu-families-compile-v7", "artifact_count": len(bound),
            "artifacts": bound, "artifact_identity": revalidate_bound_artifacts(root, bound),
            "receipt_sha256": receipt_sha}
atomic_write_json(manifest_path, manifest)
_, manifest_sha, _ = read_json_same_bytes(manifest_path)
atomic_write_bytes(expected_path, b"PASS\n")
binding = {"schema": "qwen-f32-alu-families-compile-v7-compile-final-binding-v1",
           "task_id": "qwen-f32-alu-families-compile-v7", "receipt_sha256": receipt_sha,
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
        "[NPU-QWEN-F32-ALU-FAMILIES-COMPILE-V7][COMPILE-PASS-CANDIDATE] build_count=1 binary_runs=0 model_runs=0 qwen_runs=0 synthesis=0 sta=0 ppa=0 wave_trace_coverage_files=0 actual_configured_argv=1 collect_ledger_snapshots=0+1+2 collect_ledger_append_only=1 collect_ledger_overwrites=0 collect_order=configure-before-build cmake_path=$PINNED_CMAKE_EXE cmake_sha256=$PINNED_CMAKE_SHA256 compile_membership=21+1+1 objects=$object_count depfiles=$depfile_count objects_depfiles=exact warning_census=25-exact warning_expected_sha256=$WARNING_EXPECTED_SHA256 linked_binary_sha256=$binary_sha verified_canonical_completed=0 remaining=1079 dynamic=GAP qwen=GAP deadline_edge=GAP backend_concurrency=CONDITIONAL_UNKNOWN receipt_sha256=$receipt_sha manifest_sha256=$manifest_sha binding_sha256=$binding_sha"
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
