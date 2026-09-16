#ifndef LLAMA_NPU_COMPILED_BACKEND_API_H
#define LLAMA_NPU_COMPILED_BACKEND_API_H

#include "ggml-backend.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Version 1 is deliberately a plan API, not an operator-profile API.  A
// caller must first load a compiler artifact and then prove its exact mapping
// to one concrete GGML graph before the device advertises any compute node.
#define GGML_NPU_COMPILED_PLAN_API_VERSION 1U
#define GGML_NPU_COMPILED_GRAPH_API_VERSION 2U
#define GGML_NPU_COMPILED_PLAN_BIND_GRAPH_V2_PROC \
    "ggml_backend_npu_compiled_plan_bind_graph_v2"
#define GGML_NPU_COMPILED_PLAN_LAUNCH_V2_PROC \
    "ggml_backend_npu_compiled_plan_launch_v2"


#define GGML_NPU_COMPILED_PLAN_LOAD_V1_PROC \
    "ggml_backend_npu_compiled_plan_load_v1"
#define GGML_NPU_COMPILED_PLAN_BIND_NODE_V1_PROC \
    "ggml_backend_npu_compiled_plan_bind_node_v1"
#define GGML_NPU_COMPILED_PLAN_BIND_BUFFER_V1_PROC \
    "ggml_backend_npu_compiled_plan_bind_buffer_v1"
#define GGML_NPU_COMPILED_PLAN_SEAL_V1_PROC \
    "ggml_backend_npu_compiled_plan_seal_v1"
#define GGML_NPU_COMPILED_PLAN_CLEAR_V1_PROC \
    "ggml_backend_npu_compiled_plan_clear_v1"
#define GGML_NPU_COMPILED_PLAN_STATUS_V1_PROC \
    "ggml_backend_npu_compiled_plan_status_v1"
#define GGML_NPU_COMPILED_PLAN_LAST_ERROR_V1_PROC \
    "ggml_backend_npu_compiled_plan_last_error_v1"

enum ggml_npu_compiled_plan_state_v1 {
    GGML_NPU_COMPILED_PLAN_EMPTY_V1 = 0,
    GGML_NPU_COMPILED_PLAN_LOADED_V1 = 1,
    GGML_NPU_COMPILED_PLAN_SEALED_V1 = 2,
};

enum ggml_npu_compiled_plan_error_v1 {
    GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1 = 0,
    GGML_NPU_COMPILED_PLAN_ERROR_INVALID_BACKEND_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_INVALID_ARGUMENT_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_BUNDLE_LOAD_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_UNSUPPORTED_BUNDLE_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_UNKNOWN_NODE_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_DUPLICATE_NODE_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_NODE_BINDING_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_UNKNOWN_BUFFER_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_DUPLICATE_BUFFER_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_INCOMPLETE_PLAN_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_ACTIVE_PLAN_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_RUNTIME_NOT_READY_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_MISMATCH_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_RUNTIME_EXECUTE_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
    GGML_NPU_COMPILED_PLAN_ERROR_PROVENANCE_V2,

};

// Snapshot suitable for diagnostics and tests.  Seal is allocation-agnostic:
// runtime_ready and the generation counters remain zero until the first
// complete graph_compute passes its post-scheduler storage preflight and
// constructs the production host runtime.  Earlier preflight failures may
// increment compute_attempts, but never execute_calls or a generation.
struct ggml_npu_compiled_plan_status_v1 {
    uint32_t abi_version;
    uint32_t state;
    uint32_t last_error;
    uint32_t runtime_ready;
    uint32_t runtime_fatal;
    uint32_t is_active_plan;
    uint32_t reserved0;
    uint32_t reserved1;
    uint64_t command_count;
    uint64_t buffer_count;
    uint64_t bound_node_count;
    uint64_t bound_buffer_count;
    uint64_t compute_attempts;
    uint64_t execute_calls;
    uint64_t successful_bundles;
    uint64_t last_generation;
    uint64_t next_generation;
    uint64_t submitted_generations;
};

typedef bool (*ggml_backend_npu_compiled_plan_load_v1_t)(
        ggml_backend_t backend,
        const char * bundle_directory);

typedef bool (*ggml_backend_npu_compiled_plan_bind_node_v1_t)(
        ggml_backend_t backend,
        uint64_t artifact_node_id,
        struct ggml_tensor * tensor,
        int32_t graph_index);

// Every metadata buffer, including transient and weight buffers, must be
// bound.  tensor_offset and bytes describe a byte range in the tensor's
// logical layout; tensor->data may still be null before scheduler allocation.
// bytes must exactly equal the artifact buffer size.  Only input/output
// ranges become external host-runtime capabilities.  Weight bytes are used
// solely to prove identity with weights.bin and transient storage stays
// private to the host runtime.
typedef bool (*ggml_backend_npu_compiled_plan_bind_buffer_v1_t)(
        ggml_backend_t backend,
        const char * buffer_id,
        struct ggml_tensor * tensor,
        uint64_t tensor_offset,
        uint64_t bytes);

typedef bool (*ggml_backend_npu_compiled_plan_seal_v1_t)(
        ggml_backend_t backend,
        struct ggml_cgraph * full_graph);

// full_graph is the caller-owned original graph, before scheduler splitting.
// Its graph object, node tensors, and source links must remain alive and
// unchanged until clear_v1 or backend destruction.  Seal uses it to prove
// whole-graph indices and to reject private-transient consumers outside the
// bundle; graph_compute revalidates the saved node/source snapshot.  V1
// accepts only the synthetic P00-shaped dense F32 ADD contract. The first
// complete split must expose host-accessible, non-overlapping external
// input/output storage; private transient storage may be recycled by GGML.

typedef bool (*ggml_backend_npu_compiled_plan_clear_v1_t)(
        ggml_backend_t backend);

typedef bool (*ggml_backend_npu_compiled_plan_status_v1_t)(
        ggml_backend_t backend,
        struct ggml_npu_compiled_plan_status_v1 * status);

// The returned UTF-8 string is a thread-local copy and remains valid until
// this function is called again on the same thread.
typedef const char * (*ggml_backend_npu_compiled_plan_last_error_v1_t)(
        ggml_backend_t backend);

// After load_v1, bind_graph_v2 resolves every artifact node and buffer from
// the exact compiler manifest and complete original GGML graph, then seals.
// Canonical identities, schedules, descriptors and source/VIEW/storage edges
// are checked. Storage is not needed yet. A failed bind grants no admission.
// Graph/tensors must remain alive. V1 manual binding is for synthetic fixtures.
// Canonical scheduler admission keeps all required original nodes on NPU;
// a split containing uncovered nodes fails instead of falling back to CPU.
// launch_v2 explicitly executes only the compiler-selected slice.
typedef bool (*ggml_backend_npu_compiled_plan_bind_graph_v2_t)(
        ggml_backend_t backend, const char * manifest_path,
        struct ggml_cgraph * full_graph);

// Execute only the artifact subgraph. External inputs must already be ready.
// No scheduler or CPU tensor backend is invoked. Invalid plans fail closed.
typedef enum ggml_status (*ggml_backend_npu_compiled_plan_launch_v2_t)(
        ggml_backend_t backend);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_bind_graph_v2(
        ggml_backend_t backend, const char * manifest_path,
        struct ggml_cgraph * full_graph);
GGML_BACKEND_API enum ggml_status ggml_backend_npu_compiled_plan_launch_v2(
        ggml_backend_t backend);

GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_load_v1(
        ggml_backend_t backend,
        const char * bundle_directory);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_bind_node_v1(
        ggml_backend_t backend,
        uint64_t artifact_node_id,
        struct ggml_tensor * tensor,
        int32_t graph_index);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_bind_buffer_v1(
        ggml_backend_t backend,
        const char * buffer_id,
        struct ggml_tensor * tensor,
        uint64_t tensor_offset,
        uint64_t bytes);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_seal_v1(
        ggml_backend_t backend,
        struct ggml_cgraph * full_graph);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_clear_v1(
        ggml_backend_t backend);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_status_v1(
        ggml_backend_t backend,
        struct ggml_npu_compiled_plan_status_v1 * status);
GGML_BACKEND_API const char * ggml_backend_npu_compiled_plan_last_error_v1(
        ggml_backend_t backend);


#define GGML_NPU_COMPILED_PLAN_AUDIT_V2_PROC "ggml_backend_npu_compiled_plan_audit_v2"
struct ggml_npu_compiled_plan_audit_v2 {
    uint64_t constructor_count, reset_release_count, boot_count;
    uint64_t launch_accepts, macro_terminals, rtl_starts;
    uint64_t portal_requests, portal_responses, read_bytes, write_bytes;
};
typedef bool (*ggml_backend_npu_compiled_plan_audit_v2_t)(
        ggml_backend_t backend, struct ggml_npu_compiled_plan_audit_v2 * result);
GGML_BACKEND_API bool ggml_backend_npu_compiled_plan_audit_v2(
        ggml_backend_t backend, struct ggml_npu_compiled_plan_audit_v2 * result);

GGML_BACKEND_API ggml_backend_reg_t ggml_backend_npu_compiled_reg(void);

#ifdef __cplusplus
}
#endif

#endif
