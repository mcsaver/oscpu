#ifndef LLAMA_NPU_AUDIT_API_H
#define LLAMA_NPU_AUDIT_API_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define GGML_NPU_AUDIT_ABI_VERSION 1u
#define GGML_NPU_AUDIT_BEGIN_PROC "ggml_backend_npu_audit_begin_v1"
#define GGML_NPU_AUDIT_END_PROC   "ggml_backend_npu_audit_end_v1"
#define GGML_NPU_AUDIT_V2_ABI_VERSION 2u
#define GGML_NPU_AUDIT_BEGIN_V2_PROC "ggml_backend_npu_audit_begin_v2"
#define GGML_NPU_AUDIT_END_V2_PROC   "ggml_backend_npu_audit_end_v2"
#define GGML_NPU_CANONICAL_BINDING_ABI_VERSION 1u
#define GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC \
    "ggml_backend_npu_canonical_binding_begin_v1"
#define GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC \
    "ggml_backend_npu_canonical_binding_bind_v1"
#define GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC \
    "ggml_backend_npu_canonical_binding_seal_v1"
#define GGML_NPU_CANONICAL_COMMAND_FLAGS 0x00000011u
#define GGML_NPU_CANONICAL_CONTEXT_ID_V1 0x43414e01u
#define GGML_NPU_RTL_SELF_TEST_ABI_VERSION 1u
#define GGML_NPU_RTL_SELF_TEST_PROC "ggml_backend_npu_rtl_self_test_v1"
#define GGML_NPU_F32_ADD_SELF_TEST_ABI_VERSION 2u
#define GGML_NPU_F32_ADD_SELF_TEST_PROC \
    "ggml_backend_npu_f32_add_self_test_v2"
#define GGML_NPU_F32_ALU_SELF_TEST_ABI_VERSION 3u
#define GGML_NPU_F32_ALU_SELF_TEST_PROC \
    "ggml_backend_npu_f32_alu_self_test_v3"
#define GGML_NPU_F32_ALU_SELF_TEST_V4_ABI_VERSION 4u
#define GGML_NPU_F32_ALU_SELF_TEST_V4_PROC \
    "ggml_backend_npu_f32_alu_self_test_v4"
#define GGML_NPU_REPRESENTATIVE_AUDIT_V4_ABI_VERSION 4u
#define GGML_NPU_REPRESENTATIVE_AUDIT_BEGIN_V4_PROC \
    "ggml_backend_npu_representative_audit_begin_v4"
#define GGML_NPU_REPRESENTATIVE_AUDIT_END_V4_PROC \
    "ggml_backend_npu_representative_audit_end_v4"
#define GGML_NPU_REPRESENTATIVE_AUDIT_VALIDATE_V4_PROC \
    "ggml_backend_npu_representative_audit_validate_v4"

#define GGML_NPU_F32_ADD_MODE_POSITIVE            0u
#define GGML_NPU_F32_ADD_MODE_UNKNOWN_KERNEL      1u
#define GGML_NPU_F32_ADD_MODE_OUT_OF_RANGE_4MOD8  2u
#define GGML_NPU_F32_ADD_MODE_REQ_READY_LOW       3u
#define GGML_NPU_F32_ADD_MODE_OVERPERMISSION      4u

// v3 profile mode is orthogonal to profile_id.  Positive is valid for every
// P00--P18 row; the remaining modes form the bounded dynamic reject matrix.
#define GGML_NPU_F32_ALU_MODE_POSITIVE              0u
#define GGML_NPU_F32_ALU_MODE_UNKNOWN_KERNEL        1u
#define GGML_NPU_F32_ALU_MODE_INVALID_PROFILE       2u
#define GGML_NPU_F32_ALU_MODE_OP_PROFILE_COLLISION  3u
#define GGML_NPU_F32_ALU_MODE_SUMMARY_MISMATCH      4u
#define GGML_NPU_F32_ALU_MODE_SCALAR_MISMATCH       5u
#define GGML_NPU_F32_ALU_MODE_OUT_OF_RANGE_4MOD8    6u
#define GGML_NPU_F32_ALU_MODE_OVERLAP               7u
#define GGML_NPU_F32_ALU_MODE_OVERPERMISSION        8u
#define GGML_NPU_F32_ALU_MODE_REQ_READY_LOW         9u
#define GGML_NPU_F32_ALU_PROFILE_COUNT              19u
#define GGML_NPU_F32_ALU_PROFILE_MASK               0x0007ffffu

struct ggml_backend;
typedef struct ggml_backend * ggml_backend_t;
struct ggml_tensor;

typedef struct ggml_npu_audit_snapshot_v1 {
    uint32_t abi_version;
    uint32_t reserved;
    uint64_t dispatch_id;
    uint64_t required_seen;
    uint64_t assigned_to_npu;
    uint64_t executed_by_verilator;
    uint64_t unsupported_required;
    uint64_t rtl_failures;
    uint64_t rtl_cycles;
    uint64_t dma_bytes;
} ggml_npu_audit_snapshot_v1;

typedef bool (*ggml_backend_npu_audit_begin_v1_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint64_t required_seen,
        uint64_t assigned_to_npu);

typedef bool (*ggml_backend_npu_audit_end_v1_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_audit_snapshot_v1 * snapshot);

// v1 保持逐字节不变；闭合 required-node 审计只通过新增 v2 暴露。
typedef struct ggml_npu_audit_snapshot_v2 {
    uint32_t abi_version;
    uint32_t reserved;
    uint64_t dispatch_id;
    uint64_t required_seen;
    uint64_t assigned_to_npu;
    uint64_t required_enqueued;
    uint64_t required_successfully_covered;
    uint64_t executed_by_verilator;
    uint64_t unsupported_required;
    uint64_t cpu_fallback_attempts;
    uint64_t host_tensor_ops;
    uint64_t commands_accepted;
    uint64_t commands_terminal_success;
    uint64_t commands_terminal_failure;
    uint64_t coverage_missing;
    uint64_t coverage_duplicate;
    uint64_t coverage_hash_mismatch;
    uint64_t completion_identity_mismatch;
    uint64_t rtl_failures;
    uint64_t gmem_errors;
    uint64_t timeout_errors;
    uint64_t rtl_cycles;
    uint64_t gmem_read_bytes;
    uint64_t gmem_write_bytes;
    uint64_t vector_elements;
} ggml_npu_audit_snapshot_v2;

typedef bool (*ggml_backend_npu_audit_begin_v2_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint64_t required_seen,
        uint64_t assigned_to_npu);

typedef bool (*ggml_backend_npu_audit_end_v2_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_audit_snapshot_v2 * snapshot);

// A strict caller computes the canonical SHA-256 from the actual graph node's
// semantic key, then binds that digest to the exact ggml_tensor pointer before
// scheduler allocation.  The backend derives and freezes the unique P00--P18
// execution profile from the node metadata; callers never bind a profile by
// assertion.  A batch is single-use and audit v2 refuses an unsealed, stale,
// incomplete, duplicate-pointer, duplicate-digest, or profile-colliding batch.
typedef struct ggml_npu_canonical_node_binding_v1 {
    uint32_t abi_version;
    uint32_t reserved;
    uint64_t graph_node_index;
    uint8_t canonical_id[32];
} ggml_npu_canonical_node_binding_v1;

typedef bool (*ggml_backend_npu_canonical_binding_begin_v1_fn)(
        ggml_backend_t backend,
        uint64_t binding_id,
        uint64_t expected_nodes);

typedef bool (*ggml_backend_npu_canonical_binding_bind_v1_fn)(
        ggml_backend_t backend,
        uint64_t binding_id,
        const struct ggml_tensor * node,
        const ggml_npu_canonical_node_binding_v1 * binding);

typedef bool (*ggml_backend_npu_canonical_binding_seal_v1_fn)(
        ggml_backend_t backend,
        uint64_t binding_id);

// output_bytes 是由公开 LMEM 端口读回并与冻结常量比较的结果字节数；
// error_code 为 0 时表示 RTL、握手、timeout 和常量 oracle 均通过。
typedef struct ggml_npu_rtl_self_test_result_v1 {
    uint32_t abi_version;
    uint32_t passed;
    uint64_t rtl_cycles;
    uint64_t output_bytes;
    uint32_t error_code;
    uint32_t reserved;
} ggml_npu_rtl_self_test_result_v1;

typedef bool (*ggml_backend_npu_rtl_self_test_v1_fn)(
        ggml_npu_rtl_self_test_result_v1 * result);

// 五个 mode 各自新建 Verilated top。positive 必须产生 fixed raw-bit
// oracle；四个 negative 必须产生受控 terminal failure 并清除 sticky error。
typedef struct ggml_npu_f32_add_self_test_result_v2 {
    uint32_t abi_version;
    uint32_t mode;
    uint32_t passed;
    uint32_t controlled_reject;
    uint32_t completion_status;
    uint32_t completion_error_class;
    uint32_t completion_error_code;
    uint32_t runner_error_code;
    uint64_t rtl_cycles;
    uint64_t gmem_read_bytes;
    uint64_t gmem_write_bytes;
    uint64_t vector_elements;
    uint64_t f32_start_count;
    uint64_t commands_accepted;
    uint64_t commands_terminal_success;
    uint64_t commands_terminal_failure;
    uint64_t gmem_requests_accepted;
    uint64_t gmem_responses_accepted;
    uint64_t result_bytes;
    uint32_t completion_identity_match;
    uint32_t completion_framing_valid;
    uint32_t completion_stable;
    uint32_t recovery_clean;
} ggml_npu_f32_add_self_test_result_v2;

typedef bool (*ggml_backend_npu_f32_add_self_test_v2_fn)(
        uint32_t mode,
        ggml_npu_f32_add_self_test_result_v2 * result);

// v3 preserves every v2 completion/owner observation, adds the exact profile
// identity and distinguishes private-shadow completion from raw publication.
// A positive call validates one representative transaction only; it never
// increments the canonical-node-completed set.
typedef struct ggml_npu_f32_alu_self_test_result_v3 {
    uint32_t abi_version;
    uint32_t profile_id;
    uint32_t mode;
    uint32_t passed;
    uint32_t controlled_reject;
    uint32_t completion_status;
    uint32_t completion_error_class;
    uint32_t completion_error_code;
    uint32_t runner_error_code;
    uint32_t raw_dst_committed;
    uint32_t completion_identity_match;
    uint32_t completion_framing_valid;
    uint32_t completion_stable;
    uint32_t recovery_clean;
    uint32_t reserved0;
    uint32_t reserved1;
    uint64_t rtl_cycles;
    uint64_t cycle_upper_bound;
    uint64_t gmem_read_bytes;
    uint64_t gmem_write_bytes;
    uint64_t vector_elements;
    uint64_t f32_start_count;
    uint64_t commands_accepted;
    uint64_t commands_terminal_success;
    uint64_t commands_terminal_failure;
    uint64_t gmem_requests_accepted;
    uint64_t gmem_responses_accepted;
    uint64_t result_bytes;
} ggml_npu_f32_alu_self_test_result_v3;

typedef bool (*ggml_backend_npu_f32_alu_self_test_v3_fn)(
        uint32_t profile_id,
        uint32_t mode,
        ggml_npu_f32_alu_self_test_result_v3 * result);

// v4 is additive: the predecessor v3 symbol and 160-byte record remain
// available.  A representative identity is a synthetic `rep:` transaction,
// never a canonical graph ID and never an NPU_REQUIRED command.
typedef struct ggml_npu_f32_alu_representative_identity_v4 {
    uint32_t profile_id;
    uint32_t command_flags;
    uint32_t context_id;
    uint32_t reserved;
    uint64_t sequence_id;
    uint64_t producer_id;
    uint64_t user_tag;
    uint64_t node_hash_lo;
    uint64_t node_hash_hi;
} ggml_npu_f32_alu_representative_identity_v4;

typedef struct ggml_npu_f32_alu_self_test_result_v4 {
    uint32_t abi_version;
    uint32_t profile_id;
    uint32_t mode;
    uint32_t passed;
    uint32_t controlled_reject;
    uint32_t private_shadow_committed;
    uint32_t completion_emitted;
    uint32_t completion_accepted;
    uint32_t representative_identity_match;
    uint32_t completion_identity_match;
    uint32_t completion_framing_valid;
    uint32_t completion_stable;
    uint32_t recovery_clean;
    uint32_t submitted_profile_id;
    uint32_t observed_profile_id;
    uint32_t completion_status;
    uint32_t completion_error_class;
    uint32_t completion_error_code;
    uint32_t runner_error_code;
    uint32_t reserved;
    uint64_t rtl_cycles;
    uint64_t cycle_upper_bound;
    uint64_t gmem_read_bytes;
    uint64_t gmem_write_bytes;
    uint64_t vector_elements;
    uint64_t f32_start_count;
    uint64_t commands_accepted;
    uint64_t commands_terminal_success;
    uint64_t commands_terminal_failure;
    uint64_t gmem_requests_accepted;
    uint64_t gmem_responses_accepted;
    uint64_t result_bytes;
    uint64_t required_issued_delta;
    uint64_t required_completed_delta;
    ggml_npu_f32_alu_representative_identity_v4 submitted_identity;
    ggml_npu_f32_alu_representative_identity_v4 returned_identity;
} ggml_npu_f32_alu_self_test_result_v4;

typedef bool (*ggml_backend_npu_f32_alu_self_test_v4_fn)(
        uint32_t profile_id,
        uint32_t mode,
        ggml_npu_f32_alu_self_test_result_v4 * result);

// Five independently de-duplicated masks preserve command acceptance,
// completion emission, the actual valid&&ready edge, backend raw publication,
// and representative coverage.  Returned identities are recorded when the
// RTL completion is first emitted; ordered_count is independent of the set.
typedef struct ggml_npu_representative_audit_snapshot_v4 {
    uint32_t abi_version;
    uint32_t expected_profiles;
    uint64_t dispatch_id;
    uint32_t command_accepted_mask;
    uint32_t completion_emitted_mask;
    uint32_t completion_accepted_mask;
    uint32_t raw_dst_committed_mask;
    uint32_t representative_covered_mask;
    uint32_t returned_identity_mask;
    uint32_t ordered_count;
    uint32_t reserved;
    uint64_t commands_accepted;
    uint64_t completions_emitted;
    uint64_t completions_accepted;
    uint64_t raw_destinations_committed;
    uint64_t representative_transactions_passed;
    uint64_t required_issued_delta;
    uint64_t required_completed_delta;
    uint64_t duplicate_replay_rejections;
    uint64_t wrong_profile_rejections;
    uint64_t missing_identity_rejections;
    uint64_t extra_identity_rejections;
    uint64_t identity_substitution_rejections;
    uint64_t reordered_profile_rejections;
    uint64_t unsupported_rejections;
    uint64_t rtl_failures;
    uint64_t predecessor_representative_transactions_passed;
    uint64_t verified_canonical_completed;
    uint64_t verified_canonical_remaining;
    ggml_npu_f32_alu_representative_identity_v4
        returned_identities[GGML_NPU_F32_ALU_PROFILE_COUNT];
} ggml_npu_representative_audit_snapshot_v4;

typedef bool (*ggml_backend_npu_representative_audit_begin_v4_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint32_t expected_profiles);

typedef bool (*ggml_backend_npu_representative_audit_end_v4_fn)(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_representative_audit_snapshot_v4 * snapshot);

typedef bool (*ggml_backend_npu_representative_audit_validate_v4_fn)(
        const ggml_npu_representative_audit_snapshot_v4 * snapshot);

#ifdef __cplusplus
}
#endif

#endif
