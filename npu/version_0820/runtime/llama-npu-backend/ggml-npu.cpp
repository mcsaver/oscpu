#include "ggml-backend-impl.h"
#include "npu-audit-api.h"
#include "npu-verilator-runner.h"
#include "qwen-f32-alu-manifest.generated.h"
#include "qwen-f32-gather-repeat-manifest.generated.h"
#include "qwen-q8-gemv-manifest.generated.h"
#include "qwen-remaining-manifest.generated.h"
#include "qwen-sampler-argmax-profile.generated.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>
#include <set>
#include <unordered_map>
#include <vector>

namespace {

enum class audit_generation : std::uint32_t {
    none = 0,
    v1 = 1,
    v2 = 2,
    representative_v4 = 4,
};

enum class canonical_kernel_owner : std::uint32_t {
    none = 0,
    f32_alu = 1,
    q8_get_rows = 2,
    q8_gemv = 3,
    f32_get_rows = 4,
    f32_repeat = 5,
    unary = 6,
    rms_norm = 7,
    l2_norm = 8,
    sum_rows = 9,
    glu = 10,
    ssm_conv = 11,
    cpy = 12,
    cont = 13,
    concat = 14,
    set_rows = 15,
    f16_attention_mul_mat = 16,
    rope = 17,
    soft_max = 18,
    sampler_argmax = 19,
};

struct canonical_node_state {
    std::array<std::uint8_t, 32> canonical_id = {};
    std::uint64_t graph_node_index = 0;
    std::uint32_t profile_id = 0;
    canonical_kernel_owner owner = canonical_kernel_owner::none;
    bool enqueued = false;
    bool completed = false;
};

struct system_transport_ledger {
    std::uint64_t system_transactions = 0;
    std::uint64_t system_cycles = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t cpu_config_commands = 0;
    std::uint64_t cpu_tensor_commands = 0;
    std::uint64_t cpu_terminals = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint64_t public_commands = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t required_issued = 0;
    std::uint64_t required_completed = 0;
    std::uint64_t cpu_pid_identity_mismatch = 0;
    std::uint64_t macro_identity_mismatch = 0;
    std::uint64_t cpu_memory_separate = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t expected_first_request_hold_cycles = 0;
    std::uint64_t q8_portal_transactions = 0;
    std::uint64_t q8_portal_request_groups = 0;
    std::uint64_t q8_portal_response_groups = 0;
    std::uint64_t q8_portal_blocks = 0;
    std::uint64_t q8_portal_bytes = 0;
    std::uint64_t q8_portal_raw_copy_bytes = 0;
    std::uint64_t q8_portal_first_request_hold_cycles = 0;
    std::uint64_t q8_portal_expected_first_holds = 0;
    std::uint64_t q8_portal_expected_request_groups = 0;
    std::uint64_t q8_portal_expected_blocks = 0;
    std::uint64_t q8_portal_expected_bytes = 0;
    std::uint64_t q8_portal_protocol_errors = 0;
    std::uint64_t q8_portal_latency_mismatches = 0;
    std::uint64_t q8_portal_payload_stability_mismatches = 0;
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    std::uint64_t f32_alu_portal_expected_first_holds = 0;
    std::uint64_t f32_mover_portal_expected_first_holds = 0;
    std::uint64_t sampler_argmax_transactions = 0;
    std::uint64_t sampler_argmax_elements = 0;
    std::uint64_t sampler_argmax_read_bytes = 0;
    std::uint64_t sampler_argmax_scalar_write_bytes = 0;
    std::uint64_t sampler_argmax_sampled_tokens = 0;
    std::uint64_t sampler_argmax_host_scalar_copy_bytes = 0;
    std::uint64_t sampler_argmax_full_vocab_host_exports = 0;
    std::uint64_t sampler_argmax_full_vocab_host_export_bytes = 0;
    std::uint64_t sampler_argmax_cpu_candidate_scans = 0;
    std::uint64_t sampler_argmax_invalid_tokens = 0;
    npu_system_functional_command_result functional_command = {};
};

struct npu_backend_context {
    audit_generation active_audit = audit_generation::none;
    ggml_npu_audit_snapshot_v1 audit_v1 = {};
    ggml_npu_audit_snapshot_v2 audit_v2 = {};
    system_transport_ledger system_ledger = {};
    ggml_npu_representative_audit_snapshot_v4 representative_v4 = {};
    std::uint64_t canonical_binding_id = 0;
    std::uint64_t canonical_expected_nodes = 0;
    bool canonical_binding_building = false;
    bool canonical_binding_sealed = false;
    std::unordered_map<const ggml_tensor *, canonical_node_state>
        canonical_nodes;
    std::set<std::array<std::uint8_t, 32>> canonical_ids;
    std::set<std::uint64_t> canonical_graph_indices;

    npu_backend_context() {
        audit_v1.abi_version = GGML_NPU_AUDIT_ABI_VERSION;
        audit_v2.abi_version = GGML_NPU_AUDIT_V2_ABI_VERSION;
        representative_v4.abi_version =
            GGML_NPU_REPRESENTATIVE_AUDIT_V4_ABI_VERSION;
    }
};

static_assert(sizeof(ggml_npu_audit_snapshot_v1) == 72,
              "unexpected NPU audit v1 ABI layout");
static_assert(sizeof(ggml_npu_audit_snapshot_v2) == 192,
              "unexpected NPU audit v2 ABI layout");
static_assert(sizeof(ggml_npu_canonical_node_binding_v1) == 48,
              "unexpected NPU canonical binding v1 ABI layout");
static_assert(sizeof(ggml_npu_rtl_self_test_result_v1) == 32,
              "unexpected NPU RTL self-test ABI layout");
static_assert(sizeof(ggml_npu_f32_add_self_test_result_v2) == 136,
              "unexpected NPU F32 self-test ABI layout");
static_assert(sizeof(ggml_npu_f32_alu_self_test_result_v3) == 160,
              "unexpected NPU F32 ALU self-test ABI layout");
static_assert(sizeof(ggml_npu_f32_alu_representative_identity_v4) == 56,
              "unexpected NPU representative identity v4 ABI layout");
static_assert(sizeof(ggml_npu_f32_alu_self_test_result_v4) == 304,
              "unexpected NPU F32 ALU self-test v4 ABI layout");
static_assert(sizeof(ggml_npu_representative_audit_snapshot_v4) == 1256,
              "unexpected NPU representative audit v4 ABI layout");
static_assert(qwen_q8_gemv_manifest::kProfileCount == 10,
              "unexpected canonical-v5 Q8 GEMV profile count");
static_assert(qwen_q8_gemv_manifest::kCanonicalNodeCount == 187,
              "unexpected canonical-v5 Q8 GEMV node count");
static_assert(qwen_f32_mover_manifest::kProfileCount == 6,
              "unexpected canonical-v5 F32 mover profile count");
static_assert(qwen_f32_mover_manifest::kCanonicalNodeCount == 91,
              "unexpected canonical-v5 F32 mover node count");
static_assert(qwen_f32_mover_manifest::kGetRowsNodeCount == 73,
              "unexpected canonical-v5 F32 GET_ROWS node count");
static_assert(qwen_f32_mover_manifest::kRepeatNodeCount == 18,
              "unexpected canonical-v5 F32 REPEAT node count");
static_assert(qwen_remaining_manifest::kOwnerCount == 13,
              "unexpected canonical-v5 remaining owner count");
static_assert(qwen_remaining_manifest::kProfileCount == 30,
              "unexpected canonical-v5 remaining profile count");
static_assert(qwen_remaining_manifest::kCanonicalNodeCount == 433,
              "unexpected canonical-v5 remaining node count");
static_assert(qwen_remaining_manifest::kExistingOwnerNodeCount == 646,
              "unexpected existing canonical owner count");
static_assert(qwen_remaining_manifest::kSamplerArgmaxNodeCount == 1,
              "unexpected sampler ARGMAX owner count");
static_assert(qwen_remaining_manifest::kRequiredNonmetadataCount == 1080,
              "unexpected final canonical required count");
static_assert(qwen_sampler_argmax_manifest::kProfileCount == 1,
              "unexpected strict sampler ARGMAX profile count");
static_assert(qwen_sampler_argmax_manifest::kArgmaxNodeCount == 1,
              "unexpected strict sampler ARGMAX node count");
static_assert(qwen_sampler_argmax_manifest::kManifestCounts.total == 1714,
              "unexpected strict sampler graph node count");
static_assert(qwen_sampler_argmax_manifest::kManifestCounts.required == 1080,
              "unexpected strict sampler required count");

static ggml_npu_f32_alu_representative_identity_v4 npu_export_identity(
        const npu_f32_alu_representative_identity & identity) {
    ggml_npu_f32_alu_representative_identity_v4 exported = {};
    exported.profile_id = identity.profile_id;
    exported.command_flags = identity.command_flags;
    exported.context_id = identity.context_id;
    exported.sequence_id = identity.sequence_id;
    exported.producer_id = identity.producer_id;
    exported.user_tag = identity.user_tag;
    exported.node_hash_lo = identity.node_hash_lo;
    exported.node_hash_hi = identity.node_hash_hi;
    return exported;
}

static bool npu_identity_equal(
        const ggml_npu_f32_alu_representative_identity_v4 & lhs,
        const ggml_npu_f32_alu_representative_identity_v4 & rhs) {
    return lhs.profile_id == rhs.profile_id &&
           lhs.command_flags == rhs.command_flags &&
           lhs.context_id == rhs.context_id &&
           lhs.reserved == 0 && rhs.reserved == 0 &&
           lhs.sequence_id == rhs.sequence_id &&
           lhs.producer_id == rhs.producer_id &&
           lhs.user_tag == rhs.user_tag &&
           lhs.node_hash_lo == rhs.node_hash_lo &&
           lhs.node_hash_hi == rhs.node_hash_hi;
}

static bool npu_internal_identity_equal(
        const npu_f32_alu_representative_identity & lhs,
        const npu_f32_alu_representative_identity & rhs) {
    return lhs.profile_id == rhs.profile_id &&
           lhs.command_flags == rhs.command_flags &&
           lhs.context_id == rhs.context_id &&
           lhs.sequence_id == rhs.sequence_id &&
           lhs.producer_id == rhs.producer_id &&
           lhs.user_tag == rhs.user_tag &&
           lhs.node_hash_lo == rhs.node_hash_lo &&
           lhs.node_hash_hi == rhs.node_hash_hi;
}

static std::uint64_t npu_load_le64(
        const std::array<std::uint8_t, 32> & digest,
        std::size_t offset) {
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        value |= static_cast<std::uint64_t>(digest[offset + index]) <<
                 (8 * index);
    }
    return value;
}

// The four echoed 64-bit fields carry the complete canonical SHA-256.  The
// first 128 bits remain in the ABI-named node-hash pair; the remaining half is
// carried in sequence/producer.  user_tag is the deterministic graph index.
static npu_f32_alu_representative_identity npu_canonical_wire_identity(
        const canonical_node_state & binding) {
    return {
        binding.owner == canonical_kernel_owner::f32_alu ?
            binding.profile_id : 0,
        GGML_NPU_CANONICAL_COMMAND_FLAGS,
        GGML_NPU_CANONICAL_CONTEXT_ID_V1,
        npu_load_le64(binding.canonical_id, 16),
        npu_load_le64(binding.canonical_id, 24),
        binding.graph_node_index,
        npu_load_le64(binding.canonical_id, 0),
        npu_load_le64(binding.canonical_id, 8),
    };
}

static void npu_clear_canonical_binding(npu_backend_context * context) {
    if (context == nullptr) {
        return;
    }
    context->canonical_binding_id = 0;
    context->canonical_expected_nodes = 0;
    context->canonical_binding_building = false;
    context->canonical_binding_sealed = false;
    context->canonical_nodes.clear();
    context->canonical_ids.clear();
    context->canonical_graph_indices.clear();
}

static bool npu_expected_identity(
        std::uint32_t profile_id,
        ggml_npu_f32_alu_representative_identity_v4 * expected) {
    npu_f32_alu_representative_identity internal = {};
    if (expected == nullptr ||
        !npu_f32_alu_representative_identity_by_profile(
            profile_id, &internal)) {
        return false;
    }
    *expected = npu_export_identity(internal);
    return true;
}

static ggml_guid_t npu_guid() {
    static ggml_guid guid = {
        0x4e, 0x50, 0x55, 0x2d, 0x52, 0x56, 0x36, 0x34,
        0x2d, 0x56, 0x45, 0x52, 0x49, 0x4c, 0x41, 0x54,
    };
    return &guid;
}

static bool npu_is_metadata_op(enum ggml_op op) {
    switch (op) {
        case GGML_OP_NONE:
        case GGML_OP_RESHAPE:
        case GGML_OP_VIEW:
        case GGML_OP_PERMUTE:
        case GGML_OP_TRANSPOSE:
            return true;
        default:
            return false;
    }
}

static bool npu_op_params_are_zero(const ggml_tensor * op) {
    const auto * bytes = reinterpret_cast<const std::uint8_t *>(op->op_params);
    for (std::size_t index = 0; index < sizeof(op->op_params); ++index) {
        if (bytes[index] != 0) {
            return false;
        }
    }
    return true;
}

static bool npu_tensor_matches_descriptor(
        const ggml_tensor * tensor,
        const npu_f32_alu_tensor_descriptor & descriptor) {
    if (tensor == nullptr || tensor->type != GGML_TYPE_F32 ||
        (tensor->view_src != nullptr) != descriptor.view_present ||
        tensor->view_offs != descriptor.view_off) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (tensor->ne[dimension] != descriptor.ne[dimension] ||
            tensor->nb[dimension] != descriptor.nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_profile_op_matches(
        const npu_f32_alu_profile & profile,
        enum ggml_op op) {
    return (profile.vector_op == 1 && op == GGML_OP_ADD) ||
           (profile.vector_op == 2 && op == GGML_OP_MUL) ||
           (profile.vector_op == 3 && op == GGML_OP_SUB) ||
           (profile.vector_op == 4 && op == GGML_OP_SCALE);
}

static bool npu_profile_params_match(
        const ggml_tensor * op,
        const npu_f32_alu_profile & profile) {
    if (!profile.src1_present) {
        const auto * bytes =
            reinterpret_cast<const std::uint8_t *>(op->op_params);
        const std::uint32_t scalar0 =
            static_cast<std::uint32_t>(bytes[0]) |
            (static_cast<std::uint32_t>(bytes[1]) << 8) |
            (static_cast<std::uint32_t>(bytes[2]) << 16) |
            (static_cast<std::uint32_t>(bytes[3]) << 24);
        if (scalar0 != profile.scalar0) {
            return false;
        }
        for (std::size_t index = 4; index < sizeof(op->op_params); ++index) {
            if (bytes[index] != 0) {
                return false;
            }
        }
        return true;
    }
    return npu_op_params_are_zero(op);
}

static bool npu_profile_matches_metadata(
        const ggml_tensor * op,
        const npu_f32_alu_profile & profile) {
    if (op == nullptr || !npu_profile_op_matches(profile, op->op) ||
        op->src[0] == nullptr ||
        !npu_tensor_matches_descriptor(op, profile.dst) ||
        !npu_tensor_matches_descriptor(op->src[0], profile.src0) ||
        !npu_profile_params_match(op, profile)) {
        return false;
    }
    if (profile.src1_present) {
        if (op->src[1] == nullptr ||
            !npu_tensor_matches_descriptor(op->src[1], profile.src1)) {
            return false;
        }
    } else if (op->src[1] != nullptr) {
        return false;
    }
    for (std::size_t index = profile.src1_present ? 2 : 1;
         index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

static bool npu_zero_scale_tensor_descriptor(const ggml_tensor * tensor) {
    return tensor != nullptr && tensor->type == GGML_TYPE_F32 &&
           tensor->view_src != nullptr && tensor->view_offs == 0U &&
           tensor->ne[0] == 0 && tensor->ne[1] == 1 &&
           tensor->ne[2] == 1 && tensor->ne[3] == 1 &&
           tensor->nb[0] == 4U && tensor->nb[1] == 0U &&
           tensor->nb[2] == 0U && tensor->nb[3] == 0U;
}

static bool npu_zero_scale_names_match(
        const ggml_tensor * op,
        const ggml_npu_generated::qwen_f32_alu_canonical_node & frozen) {
    if (op == nullptr || op->src[0] == nullptr) {
        return false;
    }
    return std::strcmp(op->name, frozen.dst_name) == 0 &&
           std::strcmp(op->src[0]->name, frozen.src0_name) == 0;
}

static const ggml_tensor * npu_ultimate_view_root(
        const ggml_tensor * tensor) {
    // A real ggml view chain is shallow.  The hard bound also makes a forged
    // cycle fail closed without dereferencing indefinitely.
    for (std::size_t depth = 0; tensor != nullptr && depth < 16U; ++depth) {
        if (tensor->view_src == nullptr) {
            return tensor;
        }
        tensor = tensor->view_src;
    }
    return nullptr;
}

static bool npu_zero_scale_lineage_matches(
        const ggml_tensor * op,
        const ggml_npu_generated::qwen_f32_alu_canonical_node & frozen) {
    if (op == nullptr || op->src[0] == nullptr) {
        return false;
    }
    const ggml_tensor * dst_root = npu_ultimate_view_root(op);
    const ggml_tensor * src0_root = npu_ultimate_view_root(op->src[0]);
    if (dst_root == nullptr || dst_root != src0_root ||
        dst_root->type != GGML_TYPE_F32 || dst_root->view_src != nullptr ||
        dst_root->view_offs != 0U) {
        return false;
    }
    const std::int64_t elements = frozen.profile_id == 17U ? 18432 : 262144;
    const std::size_t row_bytes =
        frozen.profile_id == 17U ? 73728U : 1048576U;
    const char * suffix = std::strstr(frozen.src0_name, " (reshaped)");
    const std::size_t root_name_bytes = suffix == nullptr ? 0U :
        static_cast<std::size_t>(suffix - frozen.src0_name);
    return root_name_bytes != 0U &&
           std::strlen(dst_root->name) == root_name_bytes &&
           std::memcmp(dst_root->name, frozen.src0_name, root_name_bytes) == 0 &&
           dst_root->ne[0] == elements && dst_root->ne[1] == 1 &&
           dst_root->ne[2] == 1 && dst_root->ne[3] == 1 &&
           dst_root->nb[0] == 4U && dst_root->nb[1] == row_bytes &&
           dst_root->nb[2] == row_bytes && dst_root->nb[3] == row_bytes;
}

static bool npu_match_zero_scale_profile(
        const ggml_tensor * op,
        npu_f32_alu_profile * matched_profile) {
    if (op == nullptr || op->op != GGML_OP_SCALE || op->src[0] == nullptr ||
        !npu_zero_scale_tensor_descriptor(op) ||
        !npu_zero_scale_tensor_descriptor(op->src[0]) ||
        op->src[1] != nullptr) {
        return false;
    }
    for (std::size_t index = 1; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    for (const auto & frozen :
         ggml_npu_generated::kQwenF32AluCanonicalNodes) {
        npu_f32_alu_profile profile = {};
        if (!frozen.zero_cardinality_allowed ||
            !npu_zero_scale_names_match(op, frozen) ||
            !npu_zero_scale_lineage_matches(op, frozen) ||
            !npu_f32_alu_profile_by_id(frozen.profile_id, &profile) ||
            !npu_profile_params_match(op, profile)) {
            continue;
        }
        if (matched_profile != nullptr) {
            *matched_profile = profile;
        }
        return true;
    }
    return false;
}

static bool npu_zero_scale_canonical_binding_matches(
        const ggml_tensor * op,
        std::uint64_t graph_node_index,
        std::uint32_t profile_id,
        const std::array<std::uint8_t, 32> & canonical_id) {
    for (const auto & frozen :
         ggml_npu_generated::kQwenF32AluCanonicalNodes) {
        if (!frozen.zero_cardinality_allowed ||
            frozen.graph_node_index != graph_node_index ||
            frozen.profile_id != profile_id ||
            !npu_zero_scale_names_match(op, frozen)) {
            continue;
        }
        bool id_matches = std::strlen(frozen.canonical_id_hex) == 64U;
        for (std::size_t byte = 0; id_matches && byte < 32U; ++byte) {
            const auto nibble = [](char value) -> int {
                return value >= '0' && value <= '9' ? value - '0' :
                       value >= 'a' && value <= 'f' ? value - 'a' + 10 : -1;
            };
            const int hi = nibble(frozen.canonical_id_hex[byte * 2U]);
            const int lo = nibble(frozen.canonical_id_hex[byte * 2U + 1U]);
            id_matches = hi >= 0 && lo >= 0 &&
                canonical_id[byte] ==
                    static_cast<std::uint8_t>((hi << 4) | lo);
        }
        if (id_matches) {
            return true;
        }
    }
    return false;
}

// This predicate is intentionally metadata-only: scheduler probes may carry
// null data.  Storage and alias/publication checks occur only in execution.
static bool npu_match_f32_alu_profile(
        const ggml_tensor * op,
        npu_f32_alu_profile * matched_profile) {
    bool matched = false;
    npu_f32_alu_profile selected = {};
    for (std::uint32_t profile_id = 0;
         profile_id < GGML_NPU_F32_ALU_PROFILE_COUNT; ++profile_id) {
        npu_f32_alu_profile candidate = {};
        if (!npu_f32_alu_profile_by_id(profile_id, &candidate)) {
            return false;
        }
        if (npu_profile_matches_metadata(op, candidate)) {
            if (matched) {
                return false;
            }
            matched = true;
            selected = candidate;
        }
    }
    npu_f32_alu_profile zero_candidate = {};
    if (npu_match_zero_scale_profile(op, &zero_candidate)) {
        if (matched) {
            return false;
        }
        matched = true;
        selected = zero_candidate;
    }
    if (matched && matched_profile != nullptr) {
        *matched_profile = selected;
    }
    return matched;
}

static bool npu_tensor_exact_layout(
        const ggml_tensor * tensor,
        enum ggml_type type,
        const std::array<std::int64_t, 4> & ne,
        const std::array<std::size_t, 4> & nb) {
    if (tensor == nullptr || tensor->type != type ||
        tensor->view_src != nullptr || tensor->view_offs != 0) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (tensor->ne[dimension] != ne[dimension] ||
            tensor->nb[dimension] != nb[dimension]) {
            return false;
        }
    }
    return true;
}

// Canonical-v5 has exactly one Q8_0 GET_ROWS node.  Canonical identity and
// descriptor identity are independent evidence: binding proves the semantic
// node, while this predicate proves the frozen dtype/shape/stride/op contract.
static bool npu_match_q8_get_rows_profile(
        const ggml_tensor * op,
        npu_q8_get_rows_profile * matched_profile) {
    npu_q8_get_rows_profile profile = {};
    if (!npu_q8_get_rows_profile_v1(&profile) || op == nullptr ||
        op->op != GGML_OP_GET_ROWS ||
        !npu_op_params_are_zero(op) ||
        !npu_tensor_exact_layout(
            op,
            GGML_TYPE_F32,
            {1024, 1, 1, 1},
            {4, 4096, 4096, 4096}) ||
        !npu_tensor_exact_layout(
            op->src[0],
            GGML_TYPE_Q8_0,
            {1024, 248320, 1, 1},
            {34, 1088, 270172160, 270172160}) ||
        !npu_tensor_exact_layout(
            op->src[1],
            GGML_TYPE_I32,
            {1, 1, 1, 1},
            {4, 4, 4, 4})) {
        return false;
    }
    for (std::size_t index = 2; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    if (profile.embedding_dim != 1024 || profile.gathered_rows != 1 ||
        profile.vocabulary_rows != 248320 ||
        profile.table_row_stride != 1088 || profile.index_stride != 4 ||
        profile.dst_row_stride != 4096 ||
        profile.table_bytes != 270172160 || profile.index_bytes != 4 ||
        profile.dst_bytes != 4096) {
        return false;
    }
    if (matched_profile != nullptr) {
        *matched_profile = profile;
    }
    return true;
}

static bool npu_q8_gemv_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_q8_gemv_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (tensor->ne[dimension] != spec.ne[dimension] ||
            tensor->nb[dimension] != spec.nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_q8_gemv_zero_batch_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_q8_gemv_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    return tensor->ne[0] == spec.ne[0] && tensor->ne[1] == 0 &&
           tensor->ne[2] == spec.ne[2] && tensor->ne[3] == spec.ne[3] &&
           tensor->nb[0] == spec.nb[0] && tensor->nb[1] == spec.nb[1] &&
           tensor->nb[2] == 0 && tensor->nb[3] == 0;
}

static bool npu_q8_gemv_profile_from_manifest(
        const qwen_q8_gemv_manifest::profile & manifest_profile,
        std::uint32_t command_rows,
        npu_q8_gemv_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    npu_q8_gemv_profile candidate = {};
    candidate.profile_id = manifest_profile.profile_id;
    candidate.k = manifest_profile.k;
    candidate.m = manifest_profile.m;
    candidate.command_rows = command_rows;
    candidate.block_count = manifest_profile.block_count;
    candidate.activation_bytes = manifest_profile.activation_bytes;
    candidate.weight_row_stride = manifest_profile.weight_row_stride;
    candidate.weight_bytes = manifest_profile.weight_bytes;
    candidate.dst_row_stride = manifest_profile.dst_row_stride;
    candidate.dst_bytes = manifest_profile.dst_bytes;
    if (!npu_q8_gemv_finalize_profile(&candidate)) {
        return false;
    }
    *profile = candidate;
    return true;
}

static bool npu_q8_gemv_profile_matches_metadata(
        const ggml_tensor * op,
        const qwen_q8_gemv_manifest::profile & manifest_profile) {
    if (op == nullptr || op->src[0] == nullptr || op->src[1] == nullptr ||
        !npu_q8_gemv_tensor_matches(op, manifest_profile.dst) ||
        !npu_q8_gemv_tensor_matches(op->src[0], manifest_profile.weight) ||
        !npu_q8_gemv_tensor_matches(
            op->src[1], manifest_profile.activation)) {
        return false;
    }
    for (std::size_t index = 2; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

static bool npu_q8_gemv_zero_profile_matches_metadata(
        const ggml_tensor * op,
        const qwen_q8_gemv_manifest::profile & manifest_profile) {
    if (op == nullptr || op->src[0] == nullptr || op->src[1] == nullptr ||
        !npu_q8_gemv_zero_batch_tensor_matches(op, manifest_profile.dst) ||
        !npu_q8_gemv_tensor_matches(op->src[0], manifest_profile.weight) ||
        !npu_q8_gemv_zero_batch_tensor_matches(
            op->src[1], manifest_profile.activation)) {
        return false;
    }
    for (std::size_t index = 2; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

// Metadata selects one frozen runtime profile.  Canonical binding below is a
// separate check against the exact 187-node semantic identity table.
static bool npu_match_q8_gemv_profile(
        const ggml_tensor * op,
        npu_q8_gemv_profile * matched_profile) {
    bool matched = false;
    npu_q8_gemv_profile selected = {};
    for (const auto & manifest_profile :
         qwen_q8_gemv_manifest::kProfiles) {
        const bool full_metadata =
            npu_q8_gemv_profile_matches_metadata(op, manifest_profile);
        const bool zero_metadata =
            npu_q8_gemv_zero_profile_matches_metadata(op, manifest_profile);
        if (!full_metadata && !zero_metadata) {
            continue;
        }
        bool names_match = false;
        bool zero_cardinality = false;
        for (const auto & canonical_node :
             qwen_q8_gemv_manifest::kCanonicalNodes) {
            const bool exact_names =
                canonical_node.profile_id == manifest_profile.profile_id &&
                std::strcmp(op->name, canonical_node.dst_name) == 0 &&
                std::strcmp(
                    op->src[0]->name, canonical_node.weight_name) == 0 &&
                std::strcmp(
                    op->src[1]->name,
                    canonical_node.activation_name) == 0;
            if (exact_names &&
                (full_metadata ||
                 (zero_metadata && canonical_node.allow_zero_cardinality))) {
                names_match = true;
                zero_cardinality = zero_metadata;
            }
        }
        if (!names_match) {
            continue;
        }
        npu_q8_gemv_profile candidate = {};
        if (matched || !npu_q8_gemv_profile_from_manifest(
                           manifest_profile,
                           zero_cardinality ? 0U : manifest_profile.m,
                           &candidate)) {
            return false;
        }
        matched = true;
        selected = candidate;
    }
    if (matched && matched_profile != nullptr) {
        *matched_profile = selected;
    }
    return matched;
}

static bool npu_q8_gemv_canonical_matches(
        const ggml_tensor * op,
        const std::array<std::uint8_t, 32> & canonical_id,
        std::uint64_t graph_node_index,
        std::uint32_t profile_id) {
    if (op == nullptr || op->src[0] == nullptr || op->src[1] == nullptr) {
        return false;
    }
    for (const auto & node : qwen_q8_gemv_manifest::kCanonicalNodes) {
        const bool id_equal = node.canonical_id == canonical_id;
        const bool index_equal = node.graph_node_index == graph_node_index;
        if (id_equal && index_equal) {
            return node.profile_id == profile_id &&
                   std::strcmp(op->name, node.dst_name) == 0 &&
                   std::strcmp(op->src[0]->name, node.weight_name) == 0 &&
                   std::strcmp(
                       op->src[1]->name, node.activation_name) == 0;
        }
    }
    return false;
}

static bool npu_f32_mover_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_f32_mover_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (tensor->ne[dimension] != spec.ne[dimension] ||
            tensor->nb[dimension] != spec.nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_f32_mover_zero_batch_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_f32_mover_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    return tensor->ne[0] == spec.ne[0] && tensor->ne[1] == 0 &&
           tensor->ne[2] == spec.ne[2] && tensor->ne[3] == spec.ne[3] &&
           tensor->nb[0] == spec.nb[0] && tensor->nb[1] == spec.nb[1] &&
           tensor->nb[2] == 0 && tensor->nb[3] == 0;
}

static bool npu_f32_mover_zero_index_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_f32_mover_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    return tensor->ne[0] == 0 && tensor->ne[1] == spec.ne[1] &&
           tensor->ne[2] == spec.ne[2] && tensor->ne[3] == spec.ne[3] &&
           tensor->nb[0] == spec.nb[0] && tensor->nb[1] == 0 &&
           tensor->nb[2] == 0 && tensor->nb[3] == 0;
}

static bool npu_f32_mover_profile_from_manifest(
        const qwen_f32_mover_manifest::profile & manifest_profile,
        npu_f32_mover_profile * profile) {
    if (profile == nullptr ||
        manifest_profile.owner > qwen_f32_mover_manifest::kOwnerRepeat) {
        return false;
    }
    npu_f32_mover_profile candidate = {};
    candidate.profile_id = manifest_profile.profile_id;
    candidate.owner = manifest_profile.owner ==
                              qwen_f32_mover_manifest::kOwnerGetRows ?
        npu_f32_mover_owner::get_rows : npu_f32_mover_owner::repeat;
    candidate.element_count = manifest_profile.element_count;
    candidate.source_row_count = manifest_profile.source_row_count;
    candidate.index_count = manifest_profile.index_count;
    candidate.outer_count = manifest_profile.outer_count;
    candidate.repeat_count = manifest_profile.repeat_count;
    candidate.src_bytes = manifest_profile.src_bytes;
    candidate.index_bytes = manifest_profile.index_bytes;
    candidate.dst_bytes = manifest_profile.dst_bytes;
    candidate.src_row_stride = manifest_profile.src_row_stride;
    candidate.index_stride = manifest_profile.index_stride;
    candidate.dst_row_stride = manifest_profile.dst_row_stride;
    candidate.dst_outer_stride = manifest_profile.dst_outer_stride;
    if (!npu_f32_mover_finalize_profile(&candidate)) {
        return false;
    }
    *profile = candidate;
    return true;
}

static bool npu_f32_mover_profile_matches_metadata(
        const ggml_tensor * op,
        const qwen_f32_mover_manifest::profile & manifest_profile) {
    if (op == nullptr || op->src[0] == nullptr ||
        !npu_f32_mover_tensor_matches(op, manifest_profile.dst) ||
        !npu_f32_mover_tensor_matches(op->src[0], manifest_profile.src0) ||
        (op->src[1] != nullptr) != manifest_profile.src1_present ||
        (manifest_profile.src1_present &&
         !npu_f32_mover_tensor_matches(
             op->src[1], manifest_profile.src1))) {
        return false;
    }
    for (std::size_t index = manifest_profile.src1_present ? 2 : 1;
         index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

static bool npu_f32_mover_zero_profile_matches_metadata(
        const ggml_tensor * op,
        const qwen_f32_mover_manifest::profile & manifest_profile) {
    if (manifest_profile.owner != qwen_f32_mover_manifest::kOwnerGetRows ||
        !manifest_profile.src1_present || op == nullptr ||
        op->src[0] == nullptr || op->src[1] == nullptr ||
        !npu_f32_mover_zero_batch_tensor_matches(
            op, manifest_profile.dst) ||
        !npu_f32_mover_tensor_matches(op->src[0], manifest_profile.src0) ||
        !npu_f32_mover_zero_index_tensor_matches(
            op->src[1], manifest_profile.src1)) {
        return false;
    }
    for (std::size_t index = 2; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

static bool npu_f32_mover_names_match(
        const ggml_tensor * op,
        const qwen_f32_mover_manifest::canonical_node & node) {
    return op != nullptr && op->src[0] != nullptr &&
           std::strcmp(op->name, node.dst_name) == 0 &&
           std::strcmp(op->src[0]->name, node.src0_name) == 0 &&
           ((op->src[1] == nullptr && node.src1_name[0] == '\0') ||
            (op->src[1] != nullptr &&
             std::strcmp(op->src[1]->name, node.src1_name) == 0));
}

// Metadata, exact tensor names, and canonical identity remain three separate
// obligations.  This matcher admits only one of the six machine-derived
// profiles, while binding below proves one exact node from the 91-row table.
static bool npu_match_f32_mover_profile(
        const ggml_tensor * op,
        npu_f32_mover_profile * matched_profile) {
    bool matched = false;
    npu_f32_mover_profile selected = {};
    for (const auto & manifest_profile :
         qwen_f32_mover_manifest::kProfiles) {
        const bool full_metadata =
            npu_f32_mover_profile_matches_metadata(op, manifest_profile);
        const bool zero_metadata =
            npu_f32_mover_zero_profile_matches_metadata(op, manifest_profile);
        if (!full_metadata && !zero_metadata) {
            continue;
        }
        bool names_match = false;
        bool zero_cardinality = false;
        for (const auto & canonical_node :
             qwen_f32_mover_manifest::kCanonicalNodes) {
            const bool exact_names =
                canonical_node.owner == manifest_profile.owner &&
                canonical_node.profile_id == manifest_profile.profile_id &&
                npu_f32_mover_names_match(op, canonical_node);
            if (exact_names &&
                (full_metadata ||
                 (zero_metadata && canonical_node.allow_zero_cardinality))) {
                names_match = true;
                zero_cardinality = zero_metadata;
            }
        }
        npu_f32_mover_profile candidate = {};
        if (!names_match || matched ||
            !npu_f32_mover_profile_from_manifest(
                manifest_profile, &candidate)) {
            return false;
        }
        if (zero_cardinality) {
            candidate.source_row_count = 0;
            candidate.index_count = 0;
            candidate.index_bytes = 0;
            candidate.dst_bytes = 0;
            if (!npu_f32_mover_finalize_profile(&candidate)) {
                return false;
            }
        }
        matched = true;
        selected = candidate;
    }
    if (matched && matched_profile != nullptr) {
        *matched_profile = selected;
    }
    return matched;
}

static bool npu_f32_mover_canonical_matches(
        const ggml_tensor * op,
        const std::array<std::uint8_t, 32> & canonical_id,
        std::uint64_t graph_node_index,
        const npu_f32_mover_profile & profile) {
    const std::uint32_t owner =
        profile.owner == npu_f32_mover_owner::get_rows ?
            qwen_f32_mover_manifest::kOwnerGetRows :
            qwen_f32_mover_manifest::kOwnerRepeat;
    for (const auto & node : qwen_f32_mover_manifest::kCanonicalNodes) {
        if (node.canonical_id == canonical_id &&
            node.graph_node_index == graph_node_index) {
            return node.owner == owner &&
                   node.profile_id == profile.profile_id &&
                   npu_f32_mover_names_match(op, node);
        }
    }
    return false;
}

struct npu_sampler_argmax_profile {
    std::uint32_t profile_id = 0;
    std::uint64_t element_count = 0;
};

// Backend-sampler initialization probes ARGMAX with a generic contiguous
// one-million-element tensor before the real Qwen graph exists.  Admit that
// metadata envelope here; the separately sealed canonical binding below still
// restricts execution to the one audited 248320-logit greedy node.
static bool npu_match_sampler_argmax_profile(
        const ggml_tensor * op,
        npu_sampler_argmax_profile * matched_profile) {
    if (op == nullptr || op->op != GGML_OP_ARGMAX ||
        op->type != GGML_TYPE_I32 || op->src[0] == nullptr ||
        op->src[0]->type != GGML_TYPE_F32 ||
        std::strcmp(op->name, "greedy_argmax") != 0 ||
        !npu_op_params_are_zero(op) || op->view_src != nullptr ||
        op->view_offs != 0 || op->ne[0] != 1 || op->ne[1] != 1 ||
        op->ne[2] != 1 || op->ne[3] != 1 || op->nb[0] != 4 ||
        op->nb[1] != 4 || op->nb[2] != 4 || op->nb[3] != 4) {
        return false;
    }
    for (std::size_t index = 1; index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    const ggml_tensor * src = op->src[0];
    const std::int64_t elements = src->ne[0];
    if (elements <= 0 || elements > 1048576 || src->ne[1] != 1 ||
        src->ne[2] != 1 || src->ne[3] != 1 || src->nb[0] != 4 ||
        static_cast<std::uint64_t>(elements) >
            std::numeric_limits<std::size_t>::max() / 4U) {
        return false;
    }
    const std::size_t contiguous_bytes =
        static_cast<std::size_t>(elements) * 4U;
    if (src->nb[1] != contiguous_bytes || src->nb[2] != contiguous_bytes ||
        src->nb[3] != contiguous_bytes) {
        return false;
    }
    if (matched_profile != nullptr) {
        matched_profile->profile_id = 0U;
        matched_profile->element_count =
            static_cast<std::uint64_t>(elements);
    }
    return true;
}

static bool npu_sampler_argmax_canonical_matches(
        const ggml_tensor * op,
        const std::array<std::uint8_t, 32> & canonical_id,
        std::uint64_t graph_node_index,
        const npu_sampler_argmax_profile & runtime_profile) {
    const auto & frozen = qwen_sampler_argmax_manifest::kProfile;
    if (op == nullptr || op->src[0] == nullptr ||
        runtime_profile.profile_id != frozen.profile_id ||
        runtime_profile.element_count !=
            static_cast<std::uint64_t>(frozen.src0_ne[0]) ||
        graph_node_index != frozen.graph_node_index ||
        canonical_id != frozen.canonical_id ||
        static_cast<std::uint32_t>(op->op) != frozen.op_id ||
        static_cast<std::uint32_t>(op->type) != frozen.dst_type_id ||
        static_cast<std::uint32_t>(op->src[0]->type) !=
            frozen.src0_type_id ||
        static_cast<std::uint32_t>(op->flags) != frozen.dst_flags ||
        static_cast<std::uint32_t>(op->src[0]->flags) !=
            frozen.src0_flags ||
        std::strcmp(op->name, frozen.dst_name) != 0 ||
        std::strcmp(op->src[0]->name, frozen.src0_name) != 0) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (op->ne[dimension] != frozen.dst_ne[dimension] ||
            op->nb[dimension] != frozen.dst_nb[dimension] ||
            op->src[0]->ne[dimension] != frozen.src0_ne[dimension] ||
            op->src[0]->nb[dimension] != frozen.src0_nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_remaining_tensor_matches(
        const ggml_tensor * tensor,
        const qwen_remaining_manifest::tensor_spec & spec) {
    static_assert(sizeof(((ggml_tensor *) nullptr)->op_params) == 64,
                  "canonical-v5 op_params width changed");
    if (tensor == nullptr ||
        static_cast<std::uint32_t>(tensor->type) != spec.type_id ||
        static_cast<std::uint32_t>(tensor->op) != spec.op_id ||
        static_cast<std::uint32_t>(tensor->flags) != spec.flags ||
        (tensor->view_src != nullptr) != spec.view_present ||
        tensor->view_offs != spec.view_offs ||
        std::memcmp(tensor->op_params, spec.op_params.data(),
                    spec.op_params.size()) != 0) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (tensor->ne[dimension] != spec.ne[dimension] ||
            tensor->nb[dimension] != spec.nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_remaining_owner_from_manifest(
        qwen_remaining_manifest::owner owner,
        npu_exact_owner * converted) {
    if (converted == nullptr) {
        return false;
    }
    switch (owner) {
        case qwen_remaining_manifest::owner::kUnary:
            *converted = npu_exact_owner::unary;
            return true;
        case qwen_remaining_manifest::owner::kRmsNorm:
            *converted = npu_exact_owner::rms_norm;
            return true;
        case qwen_remaining_manifest::owner::kL2Norm:
            *converted = npu_exact_owner::l2_norm;
            return true;
        case qwen_remaining_manifest::owner::kSumRows:
            *converted = npu_exact_owner::sum_rows;
            return true;
        case qwen_remaining_manifest::owner::kGlu:
            *converted = npu_exact_owner::glu;
            return true;
        case qwen_remaining_manifest::owner::kSsmConv:
            *converted = npu_exact_owner::ssm_conv;
            return true;
        case qwen_remaining_manifest::owner::kCpy:
            *converted = npu_exact_owner::cpy;
            return true;
        case qwen_remaining_manifest::owner::kCont:
            *converted = npu_exact_owner::cont;
            return true;
        case qwen_remaining_manifest::owner::kConcat:
            *converted = npu_exact_owner::concat;
            return true;
        case qwen_remaining_manifest::owner::kSetRows:
            *converted = npu_exact_owner::set_rows;
            return true;
        case qwen_remaining_manifest::owner::kF16AttentionMulMat:
            *converted = npu_exact_owner::f16_attention_mul_mat;
            return true;
        case qwen_remaining_manifest::owner::kRope:
            *converted = npu_exact_owner::rope;
            return true;
        case qwen_remaining_manifest::owner::kSoftMax:
            *converted = npu_exact_owner::soft_max;
            return true;
    }
    return false;
}

static canonical_kernel_owner npu_remaining_canonical_owner(
        npu_exact_owner owner) {
    switch (owner) {
        case npu_exact_owner::unary:
            return canonical_kernel_owner::unary;
        case npu_exact_owner::rms_norm:
            return canonical_kernel_owner::rms_norm;
        case npu_exact_owner::l2_norm:
            return canonical_kernel_owner::l2_norm;
        case npu_exact_owner::sum_rows:
            return canonical_kernel_owner::sum_rows;
        case npu_exact_owner::glu:
            return canonical_kernel_owner::glu;
        case npu_exact_owner::ssm_conv:
            return canonical_kernel_owner::ssm_conv;
        case npu_exact_owner::cpy:
            return canonical_kernel_owner::cpy;
        case npu_exact_owner::cont:
            return canonical_kernel_owner::cont;
        case npu_exact_owner::concat:
            return canonical_kernel_owner::concat;
        case npu_exact_owner::set_rows:
            return canonical_kernel_owner::set_rows;
        case npu_exact_owner::f16_attention_mul_mat:
            return canonical_kernel_owner::f16_attention_mul_mat;
        case npu_exact_owner::rope:
            return canonical_kernel_owner::rope;
        case npu_exact_owner::soft_max:
            return canonical_kernel_owner::soft_max;
    }
    return canonical_kernel_owner::none;
}

static npu_exact_tensor_descriptor npu_remaining_descriptor(
        const qwen_remaining_manifest::tensor_spec & spec) {
    npu_exact_tensor_descriptor descriptor = {};
    descriptor.type_id = spec.type_id;
    descriptor.op_id = spec.op_id;
    descriptor.flags = spec.flags;
    descriptor.view_present = spec.view_present;
    descriptor.view_off = spec.view_offs;
    descriptor.ne = spec.ne;
    descriptor.nb = spec.nb;
    descriptor.op_params = spec.op_params;
    return descriptor;
}

static bool npu_remaining_profile_from_manifest(
        const qwen_remaining_manifest::profile & manifest_profile,
        npu_exact_profile * profile) {
    if (profile == nullptr || manifest_profile.source_count > 3U) {
        return false;
    }
    npu_exact_profile candidate = {};
    candidate.manifest_profile_id = manifest_profile.profile_id;
    candidate.owner_profile_id = manifest_profile.owner_profile_id;
    if (!npu_remaining_owner_from_manifest(
            manifest_profile.owner_id, &candidate.owner)) {
        return false;
    }
    candidate.source_count = manifest_profile.source_count;
    candidate.dst = npu_remaining_descriptor(manifest_profile.dst);
    for (std::size_t index = 0; index < candidate.sources.size(); ++index) {
        candidate.sources[index] =
            npu_remaining_descriptor(manifest_profile.sources[index]);
    }
    if (!npu_exact_finalize_profile(&candidate) ||
        manifest_profile.public_kernel_id != candidate.public_kernel_id) {
        return false;
    }
    const bool generated_operation_is_public =
        candidate.owner == npu_exact_owner::unary ||
        candidate.owner == npu_exact_owner::rms_norm ||
        candidate.owner == npu_exact_owner::l2_norm ||
        candidate.owner == npu_exact_owner::sum_rows ||
        candidate.owner == npu_exact_owner::glu ||
        candidate.owner == npu_exact_owner::soft_max;
    const bool generated_profile_is_public =
        candidate.owner != npu_exact_owner::cpy &&
        candidate.owner != npu_exact_owner::cont &&
        candidate.owner != npu_exact_owner::concat &&
        candidate.owner != npu_exact_owner::set_rows;
    if ((generated_operation_is_public &&
         manifest_profile.local_operation != candidate.public_vector_op) ||
        (generated_profile_is_public &&
         manifest_profile.local_profile !=
             candidate.public_local_profile)) {
        return false;
    }
    *profile = candidate;
    return true;
}

static bool npu_remaining_profile_matches_metadata(
        const ggml_tensor * op,
        const qwen_remaining_manifest::profile & manifest_profile) {
    if (op == nullptr || manifest_profile.source_count > 3U ||
        !npu_remaining_tensor_matches(op, manifest_profile.dst)) {
        return false;
    }
    for (std::size_t index = 0; index < manifest_profile.source_count;
         ++index) {
        if (!npu_remaining_tensor_matches(
                op->src[index], manifest_profile.sources[index])) {
            return false;
        }
    }
    for (std::size_t index = manifest_profile.source_count;
         index < GGML_MAX_SRC; ++index) {
        if (op->src[index] != nullptr) {
            return false;
        }
    }
    return true;
}

static bool npu_remaining_names_match(
        const ggml_tensor * op,
        const qwen_remaining_manifest::canonical_node & node) {
    if (op == nullptr || node.source_count > 3U ||
        std::strcmp(op->name, node.dst_name) != 0) {
        return false;
    }
    for (std::size_t index = 0; index < node.source_count; ++index) {
        if (op->src[index] == nullptr ||
            std::strcmp(op->src[index]->name,
                        node.source_names[index]) != 0) {
            return false;
        }
    }
    return true;
}

static bool npu_match_remaining_profile(
        const ggml_tensor * op,
        npu_exact_profile * matched_profile) {
    bool matched = false;
    npu_exact_profile selected = {};
    for (const auto & manifest_profile :
         qwen_remaining_manifest::kProfiles) {
        if (!npu_remaining_profile_matches_metadata(
                op, manifest_profile)) {
            continue;
        }
        bool names_match = false;
        for (const auto & canonical_node :
             qwen_remaining_manifest::kCanonicalNodes) {
            names_match |=
                canonical_node.profile_id == manifest_profile.profile_id &&
                canonical_node.owner_id == manifest_profile.owner_id &&
                npu_remaining_names_match(op, canonical_node);
        }
        npu_exact_profile candidate = {};
        if (!names_match || matched ||
            !npu_remaining_profile_from_manifest(
                manifest_profile, &candidate)) {
            return false;
        }
        matched = true;
        selected = candidate;
    }
    if (matched && matched_profile != nullptr) {
        *matched_profile = selected;
    }
    return matched;
}

static bool npu_remaining_canonical_matches(
        const ggml_tensor * op,
        const std::array<std::uint8_t, 32> & canonical_id,
        std::uint64_t graph_node_index,
        const npu_exact_profile & profile) {
    for (const auto & node : qwen_remaining_manifest::kCanonicalNodes) {
        if (node.canonical_id == canonical_id &&
            node.graph_node_index == graph_node_index) {
            npu_exact_owner node_owner = npu_exact_owner::unary;
            return npu_remaining_owner_from_manifest(
                       node.owner_id, &node_owner) &&
                   node_owner == profile.owner &&
                   node.profile_id == profile.manifest_profile_id &&
                   npu_remaining_names_match(op, node);
        }
    }
    return false;
}

static bool npu_source_allocation(
        const ggml_tensor * tensor,
        const npu_f32_alu_tensor_descriptor & descriptor,
        const std::uint8_t ** allocation,
        std::size_t * allocation_bytes) {
    if (tensor == nullptr || tensor->data == nullptr ||
        allocation == nullptr || allocation_bytes == nullptr) {
        return false;
    }
    const ggml_tensor * root = tensor;
    if (descriptor.view_present) {
        root = tensor->view_src;
        if (root == nullptr || root->data == nullptr ||
            descriptor.view_off > ggml_nbytes(root)) {
            return false;
        }
        const auto * root_bytes =
            static_cast<const std::uint8_t *>(root->data);
        if (static_cast<const std::uint8_t *>(tensor->data) !=
            root_bytes + descriptor.view_off) {
            return false;
        }
    }
    npu_f32_alu_span span = {};
    const std::size_t root_bytes = ggml_nbytes(root);
    if (!npu_f32_alu_source_span(descriptor, &span) ||
        span.beat_hi > root_bytes) {
        return false;
    }
    *allocation = static_cast<const std::uint8_t *>(root->data);
    *allocation_bytes = root_bytes;
    return true;
}

struct npu_exact_host_allocation {
    ggml_tensor * root = nullptr;
    std::uint8_t * bytes = nullptr;
    std::size_t size = 0;
};

static bool npu_exact_host_allocation_for(
        ggml_tensor * tensor,
        const npu_exact_tensor_descriptor & descriptor,
        npu_exact_host_allocation * allocation) {
    if (tensor == nullptr || allocation == nullptr ||
        (tensor->view_src != nullptr) != descriptor.view_present ||
        tensor->view_offs != descriptor.view_off) {
        return false;
    }
    ggml_tensor * root = descriptor.view_present ? tensor->view_src : tensor;
    if (root == nullptr || root->view_src != nullptr) {
        return false;
    }
    const std::size_t bytes = ggml_nbytes(root);
    if (descriptor.view_off > bytes ||
        (bytes != 0 && root->data == nullptr)) {
        return false;
    }
    auto * root_bytes = static_cast<std::uint8_t *>(root->data);
    if (tensor->data !=
        (root_bytes == nullptr ? nullptr : root_bytes + descriptor.view_off)) {
        return false;
    }
    allocation->root = root;
    allocation->bytes = root_bytes;
    allocation->size = bytes;
    return true;
}

static bool npu_exact_same_storage(
        const npu_exact_host_allocation & lhs,
        const npu_exact_host_allocation & rhs) {
    return lhs.root == rhs.root && lhs.bytes == rhs.bytes &&
           lhs.size == rhs.size;
}

static bool npu_exact_same_byte_range(
        const npu_exact_host_allocation & lhs,
        const npu_exact_host_allocation & rhs) {
    return lhs.bytes == rhs.bytes && lhs.size == rhs.size;
}

static bool npu_exact_same_runtime_layout(
        const ggml_tensor * lhs,
        const ggml_tensor * rhs) {
    if (lhs == nullptr || rhs == nullptr || lhs->type != rhs->type) {
        return false;
    }
    for (std::size_t dimension = 0; dimension < GGML_MAX_DIMS;
         ++dimension) {
        if (lhs->ne[dimension] != rhs->ne[dimension] ||
            lhs->nb[dimension] != rhs->nb[dimension]) {
            return false;
        }
    }
    return true;
}

static bool npu_exact_owner_can_inplace(npu_exact_owner owner) {
    // This is the frozen exact-owner subset of ggml_op_can_inplace() used by
    // the pinned gallocr.  The remaining exact owners either change layout or
    // have multi-allocation update semantics and must stay disjoint.
    return owner == npu_exact_owner::unary ||
           owner == npu_exact_owner::rms_norm ||
           owner == npu_exact_owner::rope ||
           owner == npu_exact_owner::soft_max;
}

static bool npu_is_backend(ggml_backend_t backend) {
    return backend != nullptr &&
           backend->guid != nullptr &&
           ggml_guid_matches(backend->guid, npu_guid());
}

static bool npu_audit_is_active(const npu_backend_context * context) {
    return context != nullptr &&
           context->active_audit != audit_generation::none;
}

extern "C" bool ggml_backend_npu_canonical_binding_begin_v1(
        ggml_backend_t backend,
        uint64_t binding_id,
        uint64_t expected_nodes) {
    if (!npu_is_backend(backend) || binding_id == 0) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context)) {
        return false;
    }
    npu_clear_canonical_binding(context);
    context->canonical_binding_id = binding_id;
    context->canonical_expected_nodes = expected_nodes;
    context->canonical_binding_building = true;
    return true;
}

extern "C" bool ggml_backend_npu_canonical_binding_bind_v1(
        ggml_backend_t backend,
        uint64_t binding_id,
        const ggml_tensor * node,
        const ggml_npu_canonical_node_binding_v1 * binding) {
    if (!npu_is_backend(backend)) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context) ||
        !context->canonical_binding_building ||
        context->canonical_binding_sealed ||
        context->canonical_binding_id != binding_id || node == nullptr ||
        binding == nullptr ||
        binding->abi_version != GGML_NPU_CANONICAL_BINDING_ABI_VERSION ||
        binding->reserved != 0 ||
        context->canonical_nodes.size() >=
            context->canonical_expected_nodes) {
        if (context != nullptr && !npu_audit_is_active(context)) {
            npu_clear_canonical_binding(context);
        }
        return false;
    }

    npu_f32_alu_profile f32_profile = {};
    npu_q8_get_rows_profile q8_profile = {};
    npu_q8_gemv_profile q8_gemv_profile = {};
    npu_f32_mover_profile f32_mover_profile = {};
    npu_sampler_argmax_profile sampler_argmax_profile = {};
    npu_exact_profile remaining_profile = {};
    std::array<std::uint8_t, 32> canonical_id = {};
    std::memcpy(canonical_id.data(), binding->canonical_id,
                canonical_id.size());
    bool nonzero = false;
    for (std::uint8_t byte : canonical_id) {
        nonzero |= byte != 0;
    }
    const bool matches_f32 = npu_match_f32_alu_profile(node, &f32_profile);
    const bool matches_zero_f32 = matches_f32 &&
        npu_zero_scale_tensor_descriptor(node);
    const bool matches_q8 = npu_match_q8_get_rows_profile(node, &q8_profile);
    const bool matches_q8_gemv =
        npu_match_q8_gemv_profile(node, &q8_gemv_profile);
    const bool matches_f32_mover =
        npu_match_f32_mover_profile(node, &f32_mover_profile);
    const bool matches_sampler_argmax =
        npu_match_sampler_argmax_profile(node, &sampler_argmax_profile);
    const bool matches_remaining =
        npu_match_remaining_profile(node, &remaining_profile);
    const unsigned owner_count = static_cast<unsigned>(matches_f32) +
                                 static_cast<unsigned>(matches_q8) +
                                 static_cast<unsigned>(matches_q8_gemv) +
                                 static_cast<unsigned>(matches_f32_mover) +
                                 static_cast<unsigned>(
                                     matches_sampler_argmax) +
                                 static_cast<unsigned>(matches_remaining);
    if (!nonzero || owner_count != 1 ||
        (matches_zero_f32 &&
         !npu_zero_scale_canonical_binding_matches(
             node, binding->graph_node_index, f32_profile.profile_id,
             canonical_id)) ||
        (matches_q8_gemv &&
         !npu_q8_gemv_canonical_matches(
             node, canonical_id, binding->graph_node_index,
             q8_gemv_profile.profile_id)) ||
        (matches_f32_mover &&
         !npu_f32_mover_canonical_matches(
             node, canonical_id, binding->graph_node_index,
             f32_mover_profile)) ||
        (matches_sampler_argmax &&
         !npu_sampler_argmax_canonical_matches(
             node, canonical_id, binding->graph_node_index,
             sampler_argmax_profile)) ||
        (matches_remaining &&
         !npu_remaining_canonical_matches(
             node, canonical_id, binding->graph_node_index,
             remaining_profile)) ||
        context->canonical_nodes.count(node) != 0 ||
        context->canonical_ids.count(canonical_id) != 0 ||
        context->canonical_graph_indices.count(binding->graph_node_index) != 0) {
        npu_clear_canonical_binding(context);
        return false;
    }

    canonical_node_state state = {};
    state.canonical_id = canonical_id;
    state.graph_node_index = binding->graph_node_index;
    state.owner = matches_f32 ? canonical_kernel_owner::f32_alu :
                  matches_q8 ? canonical_kernel_owner::q8_get_rows :
                  matches_q8_gemv ? canonical_kernel_owner::q8_gemv :
                  matches_sampler_argmax ?
                      canonical_kernel_owner::sampler_argmax :
                  matches_remaining ? npu_remaining_canonical_owner(
                                          remaining_profile.owner) :
                  f32_mover_profile.owner == npu_f32_mover_owner::get_rows ?
                      canonical_kernel_owner::f32_get_rows :
                      canonical_kernel_owner::f32_repeat;
    state.profile_id = matches_f32 ? f32_profile.profile_id :
                       matches_q8 ? q8_profile.profile_id :
                       matches_q8_gemv ? q8_gemv_profile.profile_id :
                       matches_sampler_argmax ?
                           sampler_argmax_profile.profile_id :
                       matches_remaining ?
                           remaining_profile.manifest_profile_id :
                                         f32_mover_profile.profile_id;
    context->canonical_nodes.emplace(node, state);
    context->canonical_ids.insert(canonical_id);
    context->canonical_graph_indices.insert(binding->graph_node_index);
    return true;
}

extern "C" bool ggml_backend_npu_canonical_binding_seal_v1(
        ggml_backend_t backend,
        uint64_t binding_id) {
    if (!npu_is_backend(backend)) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context) ||
        !context->canonical_binding_building ||
        context->canonical_binding_sealed ||
        context->canonical_binding_id != binding_id ||
        context->canonical_nodes.size() !=
            context->canonical_expected_nodes ||
        context->canonical_ids.size() != context->canonical_nodes.size() ||
        context->canonical_graph_indices.size() !=
            context->canonical_nodes.size()) {
        if (context != nullptr && !npu_audit_is_active(context)) {
            npu_clear_canonical_binding(context);
        }
        return false;
    }
    context->canonical_binding_building = false;
    context->canonical_binding_sealed = true;
    return true;
}

enum class representative_stage : std::uint32_t {
    command_accepted = 0,
    completion_emitted = 1,
    completion_accepted = 2,
    raw_dst_committed = 3,
    representative_covered = 4,
};

static std::uint32_t * npu_stage_mask(
        ggml_npu_representative_audit_snapshot_v4 * snapshot,
        representative_stage stage) {
    switch (stage) {
        case representative_stage::command_accepted:
            return &snapshot->command_accepted_mask;
        case representative_stage::completion_emitted:
            return &snapshot->completion_emitted_mask;
        case representative_stage::completion_accepted:
            return &snapshot->completion_accepted_mask;
        case representative_stage::raw_dst_committed:
            return &snapshot->raw_dst_committed_mask;
        case representative_stage::representative_covered:
            return &snapshot->representative_covered_mask;
    }
    return nullptr;
}

static std::uint32_t npu_previous_stage_mask(
        const ggml_npu_representative_audit_snapshot_v4 & snapshot,
        representative_stage stage) {
    switch (stage) {
        case representative_stage::command_accepted:
            return GGML_NPU_F32_ALU_PROFILE_MASK;
        case representative_stage::completion_emitted:
            return snapshot.command_accepted_mask;
        case representative_stage::completion_accepted:
            return snapshot.completion_emitted_mask;
        case representative_stage::raw_dst_committed:
            return snapshot.completion_accepted_mask;
        case representative_stage::representative_covered:
            return snapshot.raw_dst_committed_mask;
    }
    return 0;
}

static bool npu_insert_representative_stage(
        ggml_npu_representative_audit_snapshot_v4 * snapshot,
        representative_stage stage,
        std::uint32_t profile_id,
        const ggml_npu_f32_alu_representative_identity_v4 & identity) {
    if (snapshot == nullptr || profile_id >= GGML_NPU_F32_ALU_PROFILE_COUNT) {
        if (snapshot != nullptr) {
            ++snapshot->extra_identity_rejections;
        }
        return false;
    }
    ggml_npu_f32_alu_representative_identity_v4 expected = {};
    if (!npu_expected_identity(profile_id, &expected)) {
        ++snapshot->rtl_failures;
        return false;
    }
    if (identity.profile_id != profile_id) {
        ++snapshot->wrong_profile_rejections;
        return false;
    }
    if (!npu_identity_equal(identity, expected)) {
        ++snapshot->identity_substitution_rejections;
        return false;
    }

    const std::uint32_t bit = 1u << profile_id;
    std::uint32_t * mask = npu_stage_mask(snapshot, stage);
    if (mask == nullptr) {
        ++snapshot->rtl_failures;
        return false;
    }
    if (stage != representative_stage::command_accepted &&
        (npu_previous_stage_mask(*snapshot, stage) & bit) == 0) {
        ++snapshot->missing_identity_rejections;
        return false;
    }
    if ((*mask & bit) != 0) {
        ++snapshot->duplicate_replay_rejections;
        return false;
    }

    if (stage == representative_stage::completion_emitted) {
        if (snapshot->ordered_count != profile_id) {
            ++snapshot->reordered_profile_rejections;
            return false;
        }
        snapshot->returned_identities[profile_id] = identity;
        snapshot->returned_identity_mask |= bit;
        ++snapshot->ordered_count;
    }

    *mask |= bit;
    switch (stage) {
        case representative_stage::command_accepted:
            ++snapshot->commands_accepted;
            break;
        case representative_stage::completion_emitted:
            ++snapshot->completions_emitted;
            break;
        case representative_stage::completion_accepted:
            ++snapshot->completions_accepted;
            break;
        case representative_stage::raw_dst_committed:
            ++snapshot->raw_destinations_committed;
            break;
        case representative_stage::representative_covered:
            ++snapshot->representative_transactions_passed;
            break;
    }
    return true;
}

static std::uint32_t npu_missing_profile_count(std::uint32_t mask) {
    std::uint32_t missing =
        GGML_NPU_F32_ALU_PROFILE_MASK & ~mask;
    std::uint32_t count = 0;
    while (missing != 0) {
        count += missing & 1u;
        missing >>= 1;
    }
    return count;
}

static bool npu_validate_representative_snapshot(
        const ggml_npu_representative_audit_snapshot_v4 & snapshot) {
    if (snapshot.abi_version !=
            GGML_NPU_REPRESENTATIVE_AUDIT_V4_ABI_VERSION ||
        snapshot.expected_profiles != GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.command_accepted_mask != GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.completion_emitted_mask != GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.completion_accepted_mask != GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.raw_dst_committed_mask != GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.representative_covered_mask !=
            GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.returned_identity_mask != GGML_NPU_F32_ALU_PROFILE_MASK ||
        snapshot.ordered_count != GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.commands_accepted != GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.completions_emitted != GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.completions_accepted != GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.raw_destinations_committed !=
            GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.representative_transactions_passed !=
            GGML_NPU_F32_ALU_PROFILE_COUNT ||
        snapshot.required_issued_delta != 0 ||
        snapshot.required_completed_delta != 0 ||
        snapshot.duplicate_replay_rejections != 0 ||
        snapshot.wrong_profile_rejections != 0 ||
        snapshot.missing_identity_rejections != 0 ||
        snapshot.extra_identity_rejections != 0 ||
        snapshot.identity_substitution_rejections != 0 ||
        snapshot.reordered_profile_rejections != 0 ||
        snapshot.unsupported_rejections != 0 ||
        snapshot.rtl_failures != 0 ||
        snapshot.predecessor_representative_transactions_passed != 1 ||
        snapshot.verified_canonical_completed != 0 ||
        snapshot.verified_canonical_remaining != 1080) {
        return false;
    }
    for (std::uint32_t profile_id = 0;
         profile_id < GGML_NPU_F32_ALU_PROFILE_COUNT; ++profile_id) {
        ggml_npu_f32_alu_representative_identity_v4 expected = {};
        if (!npu_expected_identity(profile_id, &expected) ||
            !npu_identity_equal(
                snapshot.returned_identities[profile_id], expected)) {
            return false;
        }
    }
    return true;
}

static bool npu_prepare_raw_publication(
        ggml_npu_representative_audit_snapshot_v4 * snapshot,
        std::uint32_t profile_id,
        const ggml_npu_f32_alu_representative_identity_v4 & identity) {
    if (snapshot == nullptr || profile_id >= GGML_NPU_F32_ALU_PROFILE_COUNT) {
        if (snapshot != nullptr) {
            ++snapshot->extra_identity_rejections;
        }
        return false;
    }
    ggml_npu_f32_alu_representative_identity_v4 expected = {};
    if (!npu_expected_identity(profile_id, &expected)) {
        ++snapshot->rtl_failures;
        return false;
    }
    if (identity.profile_id != profile_id) {
        ++snapshot->wrong_profile_rejections;
        return false;
    }
    if (!npu_identity_equal(identity, expected)) {
        ++snapshot->identity_substitution_rejections;
        return false;
    }
    const std::uint32_t bit = 1u << profile_id;
    if ((snapshot->completion_accepted_mask & bit) == 0) {
        ++snapshot->missing_identity_rejections;
        return false;
    }
    if ((snapshot->raw_dst_committed_mask & bit) != 0) {
        ++snapshot->duplicate_replay_rejections;
        return false;
    }
    return true;
}

static void npu_note_unsupported(npu_backend_context * context) {
    if (context->active_audit == audit_generation::v1) {
        ++context->audit_v1.unsupported_required;
    } else if (context->active_audit == audit_generation::v2) {
        ++context->audit_v2.unsupported_required;
    } else if (context->active_audit ==
               audit_generation::representative_v4) {
        ++context->representative_v4.unsupported_rejections;
    }
}

static void npu_note_rtl_failure(npu_backend_context * context) {
    if (context->active_audit == audit_generation::v1) {
        ++context->audit_v1.rtl_failures;
    } else if (context->active_audit == audit_generation::v2) {
        ++context->audit_v2.rtl_failures;
    } else if (context->active_audit ==
               audit_generation::representative_v4) {
        ++context->representative_v4.rtl_failures;
    }
}

static void npu_accumulate_raw32_portal(
        npu_system_raw32_portal_result * total,
        const npu_system_raw32_portal_result & value) {
    total->transactions += value.transactions;
    total->request_groups += value.request_groups;
    total->response_groups += value.response_groups;
    total->read_groups += value.read_groups;
    total->write_groups += value.write_groups;
    total->read_words += value.read_words;
    total->write_words += value.write_words;
    total->read_bytes += value.read_bytes;
    total->write_bytes += value.write_bytes;
    total->raw_read_copy_bytes += value.raw_read_copy_bytes;
    total->raw_write_copy_bytes += value.raw_write_copy_bytes;
    total->first_request_hold_cycles +=
        value.first_request_hold_cycles;
    total->expected_request_groups += value.expected_request_groups;
    total->expected_response_groups += value.expected_response_groups;
    total->expected_read_groups += value.expected_read_groups;
    total->expected_write_groups += value.expected_write_groups;
    total->expected_read_words += value.expected_read_words;
    total->expected_write_words += value.expected_write_words;
    total->expected_read_bytes += value.expected_read_bytes;
    total->expected_write_bytes += value.expected_write_bytes;
    total->protocol_errors += value.protocol_errors;
    total->latency_mismatches += value.latency_mismatches;
    total->payload_stability_mismatches +=
        value.payload_stability_mismatches;
}

[[maybe_unused]] static bool npu_raw32_portal_matches(
        const npu_system_raw32_portal_result & portal,
        std::uint64_t request_groups,
        std::uint64_t read_groups,
        std::uint64_t write_groups,
        std::uint64_t read_words,
        std::uint64_t write_words) {
    const std::uint64_t read_bytes = read_words * 4U;
    const std::uint64_t write_bytes = write_words * 4U;
    return portal.transactions == 1U &&
           portal.request_groups == request_groups &&
           portal.response_groups == request_groups &&
           portal.read_groups == read_groups &&
           portal.write_groups == write_groups &&
           portal.read_words == read_words &&
           portal.write_words == write_words &&
           portal.read_bytes == read_bytes &&
           portal.write_bytes == write_bytes &&
           portal.raw_read_copy_bytes == read_bytes &&
           portal.raw_write_copy_bytes == write_bytes &&
           portal.first_request_hold_cycles ==
               (request_groups == 0U ? 0U : 1U) &&
           portal.expected_request_groups == request_groups &&
           portal.expected_response_groups == request_groups &&
           portal.expected_read_groups == read_groups &&
           portal.expected_write_groups == write_groups &&
           portal.expected_read_words == read_words &&
           portal.expected_write_words == write_words &&
           portal.expected_read_bytes == read_bytes &&
           portal.expected_write_bytes == write_bytes &&
           portal.protocol_errors == 0U &&
           portal.latency_mismatches == 0U &&
           portal.payload_stability_mismatches == 0U;
}

static bool npu_q8_portal_matches(
        const npu_system_q8_portal_result & portal,
        std::uint64_t request_groups,
        std::uint64_t blocks,
        std::uint64_t bytes) {
    return portal.transactions == 1U &&
           portal.request_groups == request_groups &&
           portal.response_groups == request_groups &&
           portal.blocks == blocks && portal.bytes == bytes &&
           portal.raw_copy_bytes == bytes &&
           portal.first_request_hold_cycles ==
               (request_groups == 0U ? 0U : 1U) &&
           portal.expected_request_groups == request_groups &&
           portal.expected_blocks == blocks &&
           portal.expected_bytes == bytes &&
           portal.protocol_errors == 0U &&
           portal.latency_mismatches == 0U &&
           portal.payload_stability_mismatches == 0U;
}

static bool npu_raw32_portal_inactive(
        const npu_system_raw32_portal_result & portal) {
    return portal.transactions == 0U &&
           portal.request_groups == 0U &&
           portal.response_groups == 0U &&
           portal.read_groups == 0U &&
           portal.write_groups == 0U &&
           portal.read_words == 0U && portal.write_words == 0U &&
           portal.read_bytes == 0U && portal.write_bytes == 0U &&
           portal.raw_read_copy_bytes == 0U &&
           portal.raw_write_copy_bytes == 0U &&
           portal.first_request_hold_cycles == 0U &&
           portal.expected_request_groups == 0U &&
           portal.expected_response_groups == 0U &&
           portal.expected_read_groups == 0U &&
           portal.expected_write_groups == 0U &&
           portal.expected_read_words == 0U &&
           portal.expected_write_words == 0U &&
           portal.expected_read_bytes == 0U &&
           portal.expected_write_bytes == 0U &&
           portal.protocol_errors == 0U &&
           portal.latency_mismatches == 0U &&
           portal.payload_stability_mismatches == 0U;
}

static bool npu_q8_portal_inactive(
        const npu_system_q8_portal_result & portal) {
    return portal.transactions == 0U && portal.request_groups == 0U &&
           portal.response_groups == 0U && portal.blocks == 0U &&
           portal.bytes == 0U && portal.raw_copy_bytes == 0U &&
           portal.first_request_hold_cycles == 0U &&
           portal.expected_request_groups == 0U &&
           portal.expected_blocks == 0U && portal.expected_bytes == 0U &&
           portal.protocol_errors == 0U &&
           portal.latency_mismatches == 0U &&
           portal.payload_stability_mismatches == 0U;
}

static const npu_system_functional_command_result &
npu_functional_command_ledger(const npu_verilator_f32_alu_result & result) {
    return result.f32_alu_portal.functional_command;
}

static const npu_system_functional_command_result &
npu_functional_command_ledger(
        const npu_verilator_q8_get_rows_result & result) {
    return result.q8_portal.functional_command;
}

static const npu_system_functional_command_result &
npu_functional_command_ledger(const npu_verilator_q8_gemv_result & result) {
    return result.q8_portal.functional_command;
}

static const npu_system_functional_command_result &
npu_functional_command_ledger(const npu_verilator_f32_mover_result & result) {
    return result.f32_mover_portal.functional_command;
}

static const npu_system_functional_command_result &
npu_functional_command_ledger(const npu_verilator_exact_result & result) {
    return result.functional_command;
}

static bool npu_functional_command_inactive(
        const npu_system_functional_command_result & command) {
    return !command.enabled && command.dispatches == 0U &&
           command.completions == 0U && command.successes == 0U &&
           command.failures == 0U && command.read_words == 0U &&
           command.write_words == 0U && command.read_bytes == 0U &&
           command.write_bytes == 0U && command.q8_blocks == 0U &&
           command.q8_mac_count == 0U && command.vector_elements == 0U &&
           command.callback_read_calls == 0U &&
           command.callback_write_calls == 0U &&
           command.callback_read_bytes == 0U &&
           command.callback_write_bytes == 0U &&
           command.callback_errors == 0U &&
           command.command_mismatches == 0U &&
           command.protocol_errors == 0U &&
           command.old_gmem_requests == 0U &&
           command.old_gmem_responses == 0U &&
           command.old_q8_portal_transactions == 0U &&
           command.old_f32_alu_portal_transactions == 0U &&
           command.old_f32_mover_portal_transactions == 0U;
}

static void npu_accumulate_functional_command(
        npu_system_functional_command_result * destination,
        const npu_system_functional_command_result & source) {
    destination->enabled = destination->enabled || source.enabled;
#define NPU_ACCUMULATE_FUNCTIONAL_FIELD(field) \
    destination->field += source.field
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(dispatches);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(completions);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(successes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(failures);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(read_words);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(write_words);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(read_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(write_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(q8_blocks);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(q8_mac_count);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(vector_elements);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_read_words);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_write_words);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_read_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_write_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_q8_blocks);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_q8_mac_count);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(expected_vector_elements);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(callback_read_calls);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(callback_write_calls);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(callback_read_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(callback_write_bytes);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(callback_errors);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(command_mismatches);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(protocol_errors);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(old_gmem_requests);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(old_gmem_responses);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(old_q8_portal_transactions);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(old_f32_alu_portal_transactions);
    NPU_ACCUMULATE_FUNCTIONAL_FIELD(old_f32_mover_portal_transactions);
#undef NPU_ACCUMULATE_FUNCTIONAL_FIELD
}

template <typename Result>
static void npu_note_system_transport(
        npu_backend_context * context,
        const Result & result) {
    if (context == nullptr ||
        context->active_audit != audit_generation::v2) {
        return;
    }
    system_transport_ledger & ledger = context->system_ledger;
    ledger.system_transactions += result.system_transport ? 1U : 0U;
    ledger.system_cycles += result.system_cycles;
    ledger.rtl_cycles += result.rtl_cycles;
    ledger.cpu_config_commands +=
        result.cpu_config_commands_accepted;
    ledger.cpu_tensor_commands +=
        result.cpu_tensor_commands_accepted;
    ledger.cpu_terminals += result.cpu_terminals_accepted;
    ledger.cpu_config_commits += result.cpu_config_commits;
    ledger.cpu_launch_commits += result.cpu_launch_commits;
    ledger.public_commands += result.public_commands_accepted;
    ledger.public_completions += result.public_completions;
    ledger.public_errors += result.public_errors;
    ledger.required_issued += result.required_issued_delta;
    ledger.required_completed += result.required_completed_delta;
    ledger.cpu_pid_identity_mismatch +=
        result.cpu_terminal_identity_match ? 0U : 1U;
    ledger.macro_identity_mismatch +=
        result.completion_identity_match ? 0U : 1U;
    ledger.cpu_memory_separate += result.cpu_memory_separate ? 1U : 0U;
    ledger.first_request_hold_cycles += result.first_request_hold_cycles;
    ledger.expected_first_request_hold_cycles +=
        result.gmem_requests_accepted != 0U ? 1U : 0U;
    ledger.q8_portal_transactions += result.q8_portal.transactions;
    ledger.q8_portal_request_groups += result.q8_portal.request_groups;
    ledger.q8_portal_response_groups += result.q8_portal.response_groups;
    ledger.q8_portal_blocks += result.q8_portal.blocks;
    ledger.q8_portal_bytes += result.q8_portal.bytes;
    ledger.q8_portal_raw_copy_bytes += result.q8_portal.raw_copy_bytes;
    ledger.q8_portal_first_request_hold_cycles +=
        result.q8_portal.first_request_hold_cycles;
    ledger.q8_portal_expected_first_holds +=
        result.q8_portal.expected_request_groups != 0U ? 1U : 0U;
    ledger.q8_portal_expected_request_groups +=
        result.q8_portal.expected_request_groups;
    ledger.q8_portal_expected_blocks +=
        result.q8_portal.expected_blocks;
    ledger.q8_portal_expected_bytes += result.q8_portal.expected_bytes;
    ledger.q8_portal_protocol_errors += result.q8_portal.protocol_errors;
    ledger.q8_portal_latency_mismatches +=
        result.q8_portal.latency_mismatches;
    ledger.q8_portal_payload_stability_mismatches +=
        result.q8_portal.payload_stability_mismatches;
    npu_accumulate_raw32_portal(
        &ledger.f32_alu_portal, result.f32_alu_portal);
    npu_accumulate_raw32_portal(
        &ledger.f32_mover_portal, result.f32_mover_portal);
    ledger.f32_alu_portal_expected_first_holds +=
        result.f32_alu_portal.expected_request_groups != 0U ? 1U : 0U;
    ledger.f32_mover_portal_expected_first_holds +=
        result.f32_mover_portal.expected_request_groups != 0U ? 1U : 0U;
    const auto & functional = npu_functional_command_ledger(result);
    if (functional.dispatches >
        std::numeric_limits<std::uint64_t>::max() -
            context->audit_v2.host_tensor_ops) {
        // Saturation is fail-closed because audit_end_v2 requires this counter
        // to be exactly zero.  It also avoids wrapping a reintroduced host
        // numerical path back to an apparently clean value.
        context->audit_v2.host_tensor_ops =
            std::numeric_limits<std::uint64_t>::max();
    } else {
        context->audit_v2.host_tensor_ops += functional.dispatches;
    }
    npu_accumulate_functional_command(&ledger.functional_command, functional);
}

static void npu_note_runner_result(
        npu_backend_context * context,
        const npu_verilator_f32_alu_result & result) {
    if (context->active_audit == audit_generation::v1) {
        context->audit_v1.rtl_cycles += result.rtl_cycles;
        context->audit_v1.dma_bytes +=
            result.gmem_read_bytes + result.gmem_write_bytes;
        return;
    }
    if (context->active_audit == audit_generation::representative_v4) {
        context->representative_v4.required_issued_delta +=
            result.required_issued_delta;
        context->representative_v4.required_completed_delta +=
            result.required_completed_delta;
        return;
    }
    npu_note_system_transport(context, result);
    context->audit_v2.commands_accepted += result.commands_accepted;
    context->audit_v2.commands_terminal_success +=
        result.commands_terminal_success;
    context->audit_v2.commands_terminal_failure +=
        result.commands_terminal_failure;
    context->audit_v2.rtl_cycles += result.rtl_cycles;
    context->audit_v2.gmem_read_bytes += result.gmem_read_bytes;
    context->audit_v2.gmem_write_bytes += result.gmem_write_bytes;
    context->audit_v2.vector_elements += result.vector_elements;
    if (!result.completion_identity_match) {
        ++context->audit_v2.completion_identity_mismatch;
    }
    if (result.completion_error_class == 6) {
        ++context->audit_v2.gmem_errors;
    }
    if (result.completion_error_class == 10) {
        ++context->audit_v2.timeout_errors;
    }
}

static void npu_note_runner_result(
        npu_backend_context * context,
        const npu_verilator_q8_get_rows_result & result) {
    if (context->active_audit != audit_generation::v2) {
        npu_note_rtl_failure(context);
        return;
    }
    npu_note_system_transport(context, result);
    context->audit_v2.commands_accepted += result.commands_accepted;
    context->audit_v2.commands_terminal_success +=
        result.commands_terminal_success;
    context->audit_v2.commands_terminal_failure +=
        result.commands_terminal_failure;
    context->audit_v2.rtl_cycles += result.rtl_cycles;
    context->audit_v2.gmem_read_bytes += result.gmem_read_bytes;
    context->audit_v2.gmem_write_bytes += result.gmem_write_bytes;
    context->audit_v2.vector_elements += result.vector_elements;
    if (!result.completion_identity_match) {
        ++context->audit_v2.completion_identity_mismatch;
    }
    if (result.completion_error_class == 6) {
        ++context->audit_v2.gmem_errors;
    }
    if (result.completion_error_class == 10) {
        ++context->audit_v2.timeout_errors;
    }
}

static void npu_note_runner_result(
        npu_backend_context * context,
        const npu_verilator_q8_gemv_result & result) {
    if (context->active_audit != audit_generation::v2) {
        npu_note_rtl_failure(context);
        return;
    }
    npu_note_system_transport(context, result);
    context->audit_v2.commands_accepted += result.commands_accepted;
    context->audit_v2.commands_terminal_success +=
        result.commands_terminal_success;
    context->audit_v2.commands_terminal_failure +=
        result.commands_terminal_failure;
    context->audit_v2.rtl_cycles += result.rtl_cycles;
    context->audit_v2.gmem_read_bytes += result.gmem_read_bytes;
    context->audit_v2.gmem_write_bytes += result.gmem_write_bytes;
    context->audit_v2.vector_elements += result.vector_elements;
    if (!result.completion_identity_match) {
        ++context->audit_v2.completion_identity_mismatch;
    }
    if (result.completion_error_class == 6) {
        ++context->audit_v2.gmem_errors;
    }
    if (result.completion_error_class == 10) {
        ++context->audit_v2.timeout_errors;
    }
}

static void npu_note_runner_result(
        npu_backend_context * context,
        const npu_verilator_f32_mover_result & result) {
    if (context->active_audit != audit_generation::v2) {
        npu_note_rtl_failure(context);
        return;
    }
    npu_note_system_transport(context, result);
    context->audit_v2.commands_accepted += result.commands_accepted;
    context->audit_v2.commands_terminal_success +=
        result.commands_terminal_success;
    context->audit_v2.commands_terminal_failure +=
        result.commands_terminal_failure;
    context->audit_v2.rtl_cycles += result.rtl_cycles;
    context->audit_v2.gmem_read_bytes += result.gmem_read_bytes;
    context->audit_v2.gmem_write_bytes += result.gmem_write_bytes;
    context->audit_v2.vector_elements += result.vector_elements;
    if (!result.completion_identity_match) {
        ++context->audit_v2.completion_identity_mismatch;
    }
    if (result.completion_error_class == 6) {
        ++context->audit_v2.gmem_errors;
    }
    if (result.completion_error_class == 10) {
        ++context->audit_v2.timeout_errors;
    }
}

static void npu_note_runner_result(
        npu_backend_context * context,
        const npu_verilator_exact_result & result) {
    if (context->active_audit != audit_generation::v2) {
        npu_note_rtl_failure(context);
        return;
    }
    npu_note_system_transport(context, result);
    context->audit_v2.commands_accepted += result.commands_accepted;
    context->audit_v2.commands_terminal_success +=
        result.commands_terminal_success;
    context->audit_v2.commands_terminal_failure +=
        result.commands_terminal_failure;
    context->audit_v2.rtl_cycles += result.rtl_cycles;
    context->audit_v2.gmem_read_bytes += result.gmem_read_bytes;
    context->audit_v2.gmem_write_bytes += result.gmem_write_bytes;
    context->audit_v2.vector_elements += result.vector_elements;
    if (!result.completion_identity_match) {
        ++context->audit_v2.completion_identity_mismatch;
    }
    if (result.completion_error_class == 6) {
        ++context->audit_v2.gmem_errors;
    }
    if (result.completion_error_class == 10) {
        ++context->audit_v2.timeout_errors;
    }
}

static bool npu_execute_exact_f32_alu(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_f32_alu_profile & profile,
        canonical_node_state * canonical_binding) {
    const bool zero_cardinality =
        npu_zero_scale_tensor_descriptor(node) &&
        npu_match_zero_scale_profile(node, nullptr);
    const std::uint8_t * src0_allocation = nullptr;
    const std::uint8_t * src1_allocation = nullptr;
    std::size_t src0_allocation_bytes = 0;
    std::size_t src1_allocation_bytes = 0;
    if (node == nullptr ||
        (!zero_cardinality && (node->data == nullptr ||
        ggml_nbytes(node) < profile.expected_write_bytes ||
        !npu_source_allocation(node->src[0], profile.src0,
                               &src0_allocation,
                               &src0_allocation_bytes) ||
        (profile.src1_present &&
         !npu_source_allocation(node->src[1], profile.src1,
                                &src1_allocation,
                                &src1_allocation_bytes))))) {
        npu_note_rtl_failure(context);
        return false;
    }

    std::vector<std::uint8_t> private_shadow(
        zero_cardinality ? 0U :
        static_cast<std::size_t>(profile.expected_write_bytes), 0xa5);

    const bool canonical_required =
        context->active_audit == audit_generation::v2;
    if (canonical_required != (canonical_binding != nullptr)) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (zero_cardinality && canonical_binding == nullptr) {
        npu_note_rtl_failure(context);
        return false;
    }

    npu_f32_alu_representative_identity canonical_identity = {};
    if (canonical_required) {
        if (canonical_binding->owner != canonical_kernel_owner::f32_alu ||
            canonical_binding->profile_id != profile.profile_id) {
            ++context->audit_v2.coverage_hash_mismatch;
            return false;
        }
        if (canonical_binding->enqueued || canonical_binding->completed) {
            ++context->audit_v2.coverage_duplicate;
            return false;
        }
        canonical_binding->enqueued = true;
        canonical_identity = npu_canonical_wire_identity(*canonical_binding);
    }

    npu_verilator_f32_alu_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_f32_alu(
        profile.profile_id,
        canonical_required ? &canonical_identity : nullptr,
        zero_cardinality,
        src0_allocation,
        src0_allocation_bytes,
        src1_allocation,
        src1_allocation_bytes,
        zero_cardinality ? nullptr : private_shadow.data(),
        private_shadow.size(),
        &runner_result);
    npu_note_runner_result(context, runner_result);

    bool canonical_identity_ok = true;
    if (canonical_required) {
        context->audit_v2.required_enqueued +=
            runner_result.required_issued_delta;
        canonical_identity_ok =
            npu_internal_identity_equal(
                runner_result.submitted_identity, canonical_identity) &&
            npu_internal_identity_equal(
                runner_result.returned_identity, canonical_identity);
        if (!canonical_identity_ok) {
            ++context->audit_v2.coverage_hash_mismatch;
        }
        if (runner_result.required_issued_delta > 1 ||
            runner_result.required_completed_delta > 1) {
            ++context->audit_v2.coverage_duplicate;
        }
    }

    bool representative_ledger_ok = true;
    if (context->active_audit == audit_generation::representative_v4) {
        const ggml_npu_f32_alu_representative_identity_v4 submitted =
            npu_export_identity(runner_result.submitted_identity);
        const ggml_npu_f32_alu_representative_identity_v4 returned =
            npu_export_identity(runner_result.returned_identity);
        if (runner_result.commands_accepted == 1) {
            representative_ledger_ok &= npu_insert_representative_stage(
                &context->representative_v4,
                representative_stage::command_accepted,
                profile.profile_id,
                submitted);
        } else {
            representative_ledger_ok = false;
        }
        if (runner_result.completion_emitted) {
            representative_ledger_ok &= npu_insert_representative_stage(
                &context->representative_v4,
                representative_stage::completion_emitted,
                profile.profile_id,
                returned);
        } else {
            representative_ledger_ok = false;
        }
        if (runner_result.completion_accepted) {
            representative_ledger_ok &= npu_insert_representative_stage(
                &context->representative_v4,
                representative_stage::completion_accepted,
                profile.profile_id,
                returned);
        } else {
            representative_ledger_ok = false;
        }
    }

    const auto & functional = npu_functional_command_ledger(runner_result);
    const std::uint64_t executed_elements =
        zero_cardinality ? 0U : profile.total_elements;
    const std::uint64_t portal_groups = (executed_elements + 7U) / 8U;
    const std::uint64_t portal_read_words = executed_elements *
        (profile.src1_present ? 2U : 1U);
    const std::uint64_t portal_write_words = executed_elements;
    const bool matching_success =
        runner_returned && runner_result.passed && representative_ledger_ok &&
        canonical_identity_ok &&
        runner_result.profile_id == profile.profile_id &&
        runner_result.submitted_profile_id == profile.profile_id &&
        runner_result.observed_profile_id == profile.profile_id &&
        runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.public_commands_accepted == 1 &&
        runner_result.public_completions == 1 &&
        runner_result.public_errors == 0 &&
        runner_result.cpu_config_commands_accepted == 30 &&
        runner_result.cpu_tensor_commands_accepted == 31 &&
        runner_result.cpu_terminals_accepted == 31 &&
        runner_result.cpu_config_commits == 30 &&
        runner_result.cpu_launch_commits == 1 &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.system_cycles > 0 &&
        runner_result.private_shadow_committed == !zero_cardinality &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        (canonical_required ?
            !runner_result.representative_identity_match :
            runner_result.representative_identity_match) &&
        runner_result.completion_status == 0 &&
        runner_result.completion_error_class == 0 &&
        runner_result.completion_error_code == 0 &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable &&
        runner_result.recovery_clean &&
        runner_result.commands_accepted == 1 &&
        runner_result.commands_terminal_success == 1 &&
        runner_result.commands_terminal_failure == 0 &&
        runner_result.gmem_read_bytes == 0U &&
        runner_result.gmem_write_bytes == 0U &&
        runner_result.gmem_requests_accepted == 0U &&
        runner_result.gmem_responses_accepted == 0U &&
        runner_result.first_request_hold_cycles == 0U &&
        runner_result.vector_elements == executed_elements &&
        runner_result.f32_start_count == (zero_cardinality ? 0U : 1U) &&
        runner_result.result_bytes ==
            (zero_cardinality ? 0U : profile.expected_write_bytes) &&
        // expected_read_bytes is the legacy beat-aligned GMEM footprint;
        // the raw32 portal instead counts only tensor words actually copied.
        // They are deliberately different metrics and must not be equated.
        (zero_cardinality ||
         profile.expected_write_bytes == portal_write_words * 4U) &&
        npu_functional_command_inactive(functional) &&
        npu_raw32_portal_matches(
            runner_result.f32_alu_portal,
            portal_groups * 2U,
            portal_groups,
            portal_groups,
            portal_read_words,
            portal_write_words) &&
        npu_raw32_portal_inactive(runner_result.f32_mover_portal) &&
        npu_q8_portal_inactive(runner_result.q8_portal) &&
        runner_result.required_issued_delta ==
            (canonical_required ? 1U : 0U) &&
        runner_result.required_completed_delta ==
            (canonical_required ? 1U : 0U) &&
        runner_result.rtl_cycles > 0 &&
        runner_result.rtl_cycles <= profile.cycle_upper_bound;

    if (!matching_success) {
        npu_note_rtl_failure(context);
        return false;
    }

    ggml_npu_f32_alu_representative_identity_v4 returned_identity = {};
    if (context->active_audit == audit_generation::representative_v4) {
        returned_identity = npu_export_identity(runner_result.returned_identity);
        if (!npu_prepare_raw_publication(
                &context->representative_v4,
                profile.profile_id,
                returned_identity)) {
            npu_note_rtl_failure(context);
            return false;
        }
    }

    // A zero-cardinality command proves control completion only; it must not
    // publish a destination or perform host-side arithmetic/copying.
    if (!zero_cardinality) {
        std::memcpy(node->data, private_shadow.data(), private_shadow.size());
    }
    if (context->active_audit == audit_generation::representative_v4) {
        if (!npu_insert_representative_stage(
                &context->representative_v4,
                representative_stage::raw_dst_committed,
                profile.profile_id,
                returned_identity) ||
            !npu_insert_representative_stage(
                &context->representative_v4,
                representative_stage::representative_covered,
                profile.profile_id,
                returned_identity)) {
            npu_note_rtl_failure(context);
            return false;
        }
        return true;
    }
    if (context->active_audit == audit_generation::v1) {
        ++context->audit_v1.executed_by_verilator;
    } else {
        canonical_binding->completed = true;
        ++context->audit_v2.executed_by_verilator;
        ++context->audit_v2.required_successfully_covered;
    }
    return true;
}

static bool npu_host_ranges_disjoint(
        const void * lhs,
        std::size_t lhs_bytes,
        const void * rhs,
        std::size_t rhs_bytes) {
    if (lhs == nullptr || rhs == nullptr || lhs_bytes == 0 || rhs_bytes == 0) {
        return false;
    }
    const std::uintptr_t lhs_lo = reinterpret_cast<std::uintptr_t>(lhs);
    const std::uintptr_t rhs_lo = reinterpret_cast<std::uintptr_t>(rhs);
    if (lhs_bytes > std::numeric_limits<std::uintptr_t>::max() - lhs_lo ||
        rhs_bytes > std::numeric_limits<std::uintptr_t>::max() - rhs_lo) {
        return false;
    }
    const std::uintptr_t lhs_hi = lhs_lo + lhs_bytes;
    const std::uintptr_t rhs_hi = rhs_lo + rhs_bytes;
    return lhs_hi <= rhs_lo || rhs_hi <= lhs_lo;
}

static bool npu_exact_host_ranges_overlap(
        const void * lhs,
        std::size_t lhs_bytes,
        const void * rhs,
        std::size_t rhs_bytes) {
    if (lhs_bytes == 0 || rhs_bytes == 0) {
        return false;
    }
    if (lhs == nullptr || rhs == nullptr) {
        return true;
    }
    const std::uintptr_t lhs_lo = reinterpret_cast<std::uintptr_t>(lhs);
    const std::uintptr_t rhs_lo = reinterpret_cast<std::uintptr_t>(rhs);
    if (lhs_bytes > std::numeric_limits<std::uintptr_t>::max() - lhs_lo ||
        rhs_bytes > std::numeric_limits<std::uintptr_t>::max() - rhs_lo) {
        return true;
    }
    const std::uintptr_t lhs_hi = lhs_lo + lhs_bytes;
    const std::uintptr_t rhs_hi = rhs_lo + rhs_bytes;
    return lhs_lo < rhs_hi && rhs_lo < lhs_hi;
}

static bool npu_execute_exact_q8_get_rows(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_q8_get_rows_profile & profile,
        canonical_node_state * canonical_binding) {
    if (context == nullptr || node == nullptr || canonical_binding == nullptr ||
        context->active_audit != audit_generation::v2 ||
        canonical_binding->owner != canonical_kernel_owner::q8_get_rows ||
        canonical_binding->profile_id != profile.profile_id ||
        node->data == nullptr || node->src[0] == nullptr ||
        node->src[0]->data == nullptr || node->src[1] == nullptr ||
        node->src[1]->data == nullptr ||
        ggml_nbytes(node) != profile.dst_bytes ||
        ggml_nbytes(node->src[0]) != profile.table_bytes ||
        ggml_nbytes(node->src[1]) != profile.index_bytes ||
        !npu_host_ranges_disjoint(
            node->src[0]->data, ggml_nbytes(node->src[0]),
            node->src[1]->data, ggml_nbytes(node->src[1])) ||
        !npu_host_ranges_disjoint(
            node->src[0]->data, ggml_nbytes(node->src[0]),
            node->data, ggml_nbytes(node)) ||
        !npu_host_ranges_disjoint(
            node->src[1]->data, ggml_nbytes(node->src[1]),
            node->data, ggml_nbytes(node))) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (canonical_binding->enqueued || canonical_binding->completed) {
        ++context->audit_v2.coverage_duplicate;
        return false;
    }
    canonical_binding->enqueued = true;
    const npu_macro_identity canonical_identity =
        npu_canonical_wire_identity(*canonical_binding);

    std::vector<std::uint8_t> private_shadow(
        static_cast<std::size_t>(profile.dst_bytes), 0xa5);
    npu_verilator_q8_get_rows_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_q8_get_rows(
        &canonical_identity,
        static_cast<const std::uint8_t *>(node->src[0]->data),
        ggml_nbytes(node->src[0]),
        static_cast<const std::uint8_t *>(node->src[1]->data),
        ggml_nbytes(node->src[1]),
        private_shadow.data(),
        private_shadow.size(),
        &runner_result);
    npu_note_runner_result(context, runner_result);
    context->audit_v2.required_enqueued +=
        runner_result.required_issued_delta;

    const bool canonical_identity_ok =
        npu_internal_identity_equal(
            runner_result.submitted_identity, canonical_identity) &&
        npu_internal_identity_equal(
            runner_result.returned_identity, canonical_identity);
    if (!canonical_identity_ok) {
        ++context->audit_v2.coverage_hash_mismatch;
    }
    if (runner_result.required_issued_delta > 1 ||
        runner_result.required_completed_delta > 1) {
        ++context->audit_v2.coverage_duplicate;
    }

    const auto & functional = npu_functional_command_ledger(runner_result);

    const bool matching_success =
        runner_returned && runner_result.passed &&
        !runner_result.controlled_reject && canonical_identity_ok &&
        runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.public_commands_accepted == 1 &&
        runner_result.public_completions == 1 &&
        runner_result.public_errors == 0 &&
        runner_result.cpu_config_commands_accepted == 30 &&
        runner_result.cpu_tensor_commands_accepted == 31 &&
        runner_result.cpu_terminals_accepted == 31 &&
        runner_result.cpu_config_commits == 30 &&
        runner_result.cpu_launch_commits == 1 &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.system_cycles > 0 &&
        runner_result.private_shadow_committed &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        runner_result.completion_status == 0 &&
        runner_result.completion_error_class == 0 &&
        runner_result.completion_error_code == 0 &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable && runner_result.recovery_clean &&
        runner_result.commands_accepted == 1 &&
        runner_result.commands_terminal_success == 1 &&
        runner_result.commands_terminal_failure == 0 &&
        runner_result.gmem_read_bytes == profile.expected_read_bytes &&
        runner_result.gmem_write_bytes == profile.expected_write_bytes &&
        runner_result.vector_elements == profile.expected_elements &&
        runner_result.q8_mac_count == 0 &&
        runner_result.f32_start_count == 0 &&
        runner_result.gmem_requests_accepted > 0U &&
        runner_result.gmem_responses_accepted ==
            runner_result.gmem_requests_accepted &&
        runner_result.first_request_hold_cycles == 1U &&
        npu_functional_command_inactive(functional) &&
        npu_q8_portal_inactive(runner_result.q8_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_alu_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_mover_portal) &&
        runner_result.result_bytes == profile.dst_bytes &&
        runner_result.required_issued_delta == 1 &&
        runner_result.required_completed_delta == 1 &&
        runner_result.rtl_cycles > 0 &&
        runner_result.rtl_cycles <= profile.cycle_upper_bound;
    if (!matching_success) {
        npu_note_rtl_failure(context);
        return false;
    }

    // This is publication of already-computed raw bits, not host tensor
    // arithmetic.  The caller-visible destination is untouched on any earlier
    // rejection or terminal failure.
    std::memcpy(node->data, private_shadow.data(), private_shadow.size());
    canonical_binding->completed = true;
    ++context->audit_v2.executed_by_verilator;
    ++context->audit_v2.required_successfully_covered;
    return true;
}

static bool npu_execute_exact_q8_gemv(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_q8_gemv_profile & profile,
        canonical_node_state * canonical_binding) {
    const bool empty = profile.command_rows == 0;
    const std::size_t runtime_activation_bytes =
        empty ? 0 : static_cast<std::size_t>(profile.activation_bytes);
    const std::size_t runtime_dst_bytes =
        empty ? 0 : static_cast<std::size_t>(profile.dst_bytes);
    if (context == nullptr || node == nullptr || canonical_binding == nullptr ||
        context->active_audit != audit_generation::v2 ||
        canonical_binding->owner != canonical_kernel_owner::q8_gemv ||
        canonical_binding->profile_id != profile.profile_id ||
        node->src[0] == nullptr || node->src[1] == nullptr ||
        ggml_nbytes(node) != runtime_dst_bytes ||
        ggml_nbytes(node->src[0]) != profile.weight_bytes ||
        ggml_nbytes(node->src[1]) != runtime_activation_bytes) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (!empty &&
        (node->data == nullptr || node->src[0]->data == nullptr ||
         node->src[1]->data == nullptr ||
         !npu_host_ranges_disjoint(
             node->src[0]->data, ggml_nbytes(node->src[0]),
             node->src[1]->data, ggml_nbytes(node->src[1])) ||
         !npu_host_ranges_disjoint(
             node->src[0]->data, ggml_nbytes(node->src[0]),
             node->data, ggml_nbytes(node)) ||
         !npu_host_ranges_disjoint(
             node->src[1]->data, ggml_nbytes(node->src[1]),
             node->data, ggml_nbytes(node)))) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (canonical_binding->enqueued || canonical_binding->completed) {
        ++context->audit_v2.coverage_duplicate;
        return false;
    }
    canonical_binding->enqueued = true;
    const npu_macro_identity canonical_identity =
        npu_canonical_wire_identity(*canonical_binding);

    std::vector<std::uint8_t> private_shadow(
        runtime_dst_bytes, 0xa5);
    npu_verilator_q8_gemv_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_q8_gemv(
        &profile,
        &canonical_identity,
        empty ? nullptr :
            static_cast<const std::uint8_t *>(node->src[1]->data),
        empty ? 0 : ggml_nbytes(node->src[1]),
        empty ? nullptr :
            static_cast<const std::uint8_t *>(node->src[0]->data),
        empty ? 0 : ggml_nbytes(node->src[0]),
        empty ? nullptr : private_shadow.data(),
        empty ? 0 : private_shadow.size(),
        &runner_result);
    npu_note_runner_result(context, runner_result);
    context->audit_v2.required_enqueued +=
        runner_result.required_issued_delta;

    const bool canonical_identity_ok =
        npu_internal_identity_equal(
            runner_result.submitted_identity, canonical_identity) &&
        npu_internal_identity_equal(
            runner_result.returned_identity, canonical_identity);
    if (!canonical_identity_ok) {
        ++context->audit_v2.coverage_hash_mismatch;
    }
    if (runner_result.required_issued_delta > 1 ||
        runner_result.required_completed_delta > 1) {
        ++context->audit_v2.coverage_duplicate;
    }

    const auto & functional = npu_functional_command_ledger(runner_result);
    const std::uint64_t q8_portal_tiles =
        (static_cast<std::uint64_t>(profile.command_rows) + 3U) / 4U;
    const std::uint64_t q8_portal_request_groups =
        q8_portal_tiles * profile.block_count;
    const std::uint64_t q8_portal_blocks =
        static_cast<std::uint64_t>(profile.command_rows) * profile.block_count;
    const std::uint64_t q8_portal_bytes = q8_portal_blocks * 34U;
    const std::uint64_t expected_gmem_requests =
        profile.expected_read_requests + profile.expected_write_requests;

    const bool matching_success =
        runner_returned && runner_result.passed &&
        !runner_result.controlled_reject && canonical_identity_ok &&
        runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.public_commands_accepted == 1 &&
        runner_result.public_completions == 1 &&
        runner_result.public_errors == 0 &&
        runner_result.cpu_config_commands_accepted == 30 &&
        runner_result.cpu_tensor_commands_accepted == 31 &&
        runner_result.cpu_terminals_accepted == 31 &&
        runner_result.cpu_config_commits == 30 &&
        runner_result.cpu_launch_commits == 1 &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.system_cycles > 0 &&
        runner_result.private_shadow_committed &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        runner_result.completion_status == 0 &&
        runner_result.completion_error_class == 0 &&
        runner_result.completion_error_code == 0 &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable && runner_result.recovery_clean &&
        runner_result.commands_accepted == 1 &&
        runner_result.commands_terminal_success == 1 &&
        runner_result.commands_terminal_failure == 0 &&
        runner_result.gmem_read_bytes == profile.expected_read_bytes &&
        runner_result.gmem_write_bytes == profile.expected_write_bytes &&
        runner_result.vector_elements == profile.expected_elements &&
        runner_result.q8_mac_count == profile.expected_q8_macs &&
        runner_result.f32_start_count == 0 &&
        runner_result.gmem_requests_accepted == expected_gmem_requests &&
        runner_result.gmem_responses_accepted == expected_gmem_requests &&
        runner_result.first_request_hold_cycles == (empty ? 0U : 1U) &&
        npu_functional_command_inactive(functional) &&
        npu_q8_portal_matches(
            runner_result.q8_portal,
            q8_portal_request_groups,
            q8_portal_blocks,
            q8_portal_bytes) &&
        npu_raw32_portal_inactive(runner_result.f32_alu_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_mover_portal) &&
        runner_result.result_bytes == runtime_dst_bytes &&
        runner_result.required_issued_delta == 1 &&
        runner_result.required_completed_delta == 1 &&
        runner_result.rtl_cycles > 0 &&
        runner_result.rtl_cycles <= profile.cycle_upper_bound;
    if (!matching_success) {
        std::fprintf(
            stderr,
            "[NPU-Q8-GEMV-RUNNER][FAIL] profile=%u command_rows=%u "
            "runner_returned=%u passed=%u controlled_reject=%u "
            "runner_error=0x%x system=%u public=%llu/%llu/%llu "
            "commands=%llu/%llu/%llu required=%llu/%llu "
            "read=%llu/%llu write=%llu/%llu macs=%llu/%llu "
            "elements=%llu/%llu cycles=%llu identity=%u/%u/%u\n",
            profile.profile_id, profile.command_rows,
            runner_returned ? 1U : 0U, runner_result.passed ? 1U : 0U,
            runner_result.controlled_reject ? 1U : 0U,
            runner_result.runner_error_code,
            runner_result.system_transport ? 1U : 0U,
            static_cast<unsigned long long>(
                runner_result.public_commands_accepted),
            static_cast<unsigned long long>(runner_result.public_completions),
            static_cast<unsigned long long>(runner_result.public_errors),
            static_cast<unsigned long long>(runner_result.commands_accepted),
            static_cast<unsigned long long>(
                runner_result.commands_terminal_success),
            static_cast<unsigned long long>(
                runner_result.commands_terminal_failure),
            static_cast<unsigned long long>(
                runner_result.required_issued_delta),
            static_cast<unsigned long long>(
                runner_result.required_completed_delta),
            static_cast<unsigned long long>(runner_result.gmem_read_bytes),
            static_cast<unsigned long long>(profile.expected_read_bytes),
            static_cast<unsigned long long>(runner_result.gmem_write_bytes),
            static_cast<unsigned long long>(profile.expected_write_bytes),
            static_cast<unsigned long long>(runner_result.q8_mac_count),
            static_cast<unsigned long long>(profile.expected_q8_macs),
            static_cast<unsigned long long>(runner_result.vector_elements),
            static_cast<unsigned long long>(profile.expected_elements),
            static_cast<unsigned long long>(runner_result.rtl_cycles),
            canonical_identity_ok ? 1U : 0U,
            runner_result.completion_identity_match ? 1U : 0U,
            runner_result.cpu_terminal_identity_match ? 1U : 0U);
        npu_note_rtl_failure(context);
        return false;
    }

    if (!empty) {
        std::memcpy(node->data, private_shadow.data(), private_shadow.size());
    }
    canonical_binding->completed = true;
    ++context->audit_v2.executed_by_verilator;
    ++context->audit_v2.required_successfully_covered;
    return true;
}

static bool npu_execute_exact_f32_mover(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_f32_mover_profile & profile,
        canonical_node_state * canonical_binding) {
    const canonical_kernel_owner expected_owner =
        profile.owner == npu_f32_mover_owner::get_rows ?
            canonical_kernel_owner::f32_get_rows :
            canonical_kernel_owner::f32_repeat;
    const bool empty_get =
        profile.owner == npu_f32_mover_owner::get_rows &&
        profile.index_count == 0;
    if (context == nullptr || node == nullptr || canonical_binding == nullptr ||
        context->active_audit != audit_generation::v2 ||
        canonical_binding->owner != expected_owner ||
        canonical_binding->profile_id != profile.profile_id ||
        node->src[0] == nullptr ||
        ggml_nbytes(node) != profile.dst_bytes ||
        ggml_nbytes(node->src[0]) != profile.src_bytes ||
        (profile.owner == npu_f32_mover_owner::get_rows &&
         (node->src[1] == nullptr ||
          ggml_nbytes(node->src[1]) != profile.index_bytes)) ||
        (profile.owner == npu_f32_mover_owner::repeat &&
         node->src[1] != nullptr)) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (!empty_get &&
        (node->data == nullptr || node->src[0]->data == nullptr ||
         (profile.owner == npu_f32_mover_owner::get_rows &&
          node->src[1]->data == nullptr))) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (!empty_get &&
        (!npu_host_ranges_disjoint(
             node->src[0]->data, ggml_nbytes(node->src[0]),
             node->data, ggml_nbytes(node)) ||
         (profile.owner == npu_f32_mover_owner::get_rows &&
          (!npu_host_ranges_disjoint(
               node->src[0]->data, ggml_nbytes(node->src[0]),
               node->src[1]->data, ggml_nbytes(node->src[1])) ||
           !npu_host_ranges_disjoint(
               node->src[1]->data, ggml_nbytes(node->src[1]),
               node->data, ggml_nbytes(node)))))) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (canonical_binding->enqueued || canonical_binding->completed) {
        ++context->audit_v2.coverage_duplicate;
        return false;
    }
    canonical_binding->enqueued = true;
    const npu_macro_identity canonical_identity =
        npu_canonical_wire_identity(*canonical_binding);

    std::vector<std::uint8_t> private_shadow(
        static_cast<std::size_t>(profile.dst_bytes), 0xa5);
    npu_verilator_f32_mover_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_f32_mover(
        &profile,
        &canonical_identity,
        empty_get ? nullptr :
            static_cast<const std::uint8_t *>(node->src[0]->data),
        empty_get ? 0 : ggml_nbytes(node->src[0]),
        empty_get || profile.owner == npu_f32_mover_owner::repeat ? nullptr :
            static_cast<const std::uint8_t *>(node->src[1]->data),
        empty_get || profile.owner == npu_f32_mover_owner::repeat ? 0 :
            ggml_nbytes(node->src[1]),
        empty_get ? nullptr : private_shadow.data(),
        empty_get ? 0 : private_shadow.size(),
        &runner_result);
    npu_note_runner_result(context, runner_result);
    context->audit_v2.required_enqueued +=
        runner_result.required_issued_delta;

    const bool canonical_identity_ok =
        npu_internal_identity_equal(
            runner_result.submitted_identity, canonical_identity) &&
        npu_internal_identity_equal(
            runner_result.returned_identity, canonical_identity);
    if (!canonical_identity_ok) {
        ++context->audit_v2.coverage_hash_mismatch;
    }
    if (runner_result.required_issued_delta > 1 ||
        runner_result.required_completed_delta > 1) {
        ++context->audit_v2.coverage_duplicate;
    }

    const auto & functional = npu_functional_command_ledger(runner_result);
    const std::uint64_t mover_element_groups =
        (static_cast<std::uint64_t>(profile.element_count) + 15U) / 16U;
    const bool mover_get_rows =
        profile.owner == npu_f32_mover_owner::get_rows;
    const std::uint64_t mover_index_groups = mover_get_rows ?
        (static_cast<std::uint64_t>(profile.index_count) + 15U) / 16U : 0U;
    const std::uint64_t mover_source_groups = mover_get_rows ?
        static_cast<std::uint64_t>(profile.index_count) *
            mover_element_groups :
        static_cast<std::uint64_t>(profile.outer_count) *
            mover_element_groups;
    const std::uint64_t mover_write_groups = mover_get_rows ?
        mover_source_groups :
        static_cast<std::uint64_t>(profile.outer_count) *
            profile.repeat_count * mover_element_groups;
    const std::uint64_t mover_read_words = mover_get_rows ?
        static_cast<std::uint64_t>(profile.index_count) +
            profile.expected_elements :
        profile.expected_read_requests;
    const std::uint64_t mover_request_groups =
        mover_index_groups + mover_source_groups + mover_write_groups;
    const bool matching_success =
        runner_returned && runner_result.passed &&
        !runner_result.controlled_reject && canonical_identity_ok &&
        runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.public_commands_accepted == 1 &&
        runner_result.public_completions == 1 &&
        runner_result.public_errors == 0 &&
        runner_result.cpu_config_commands_accepted == 30 &&
        runner_result.cpu_tensor_commands_accepted == 31 &&
        runner_result.cpu_terminals_accepted == 31 &&
        runner_result.cpu_config_commits == 30 &&
        runner_result.cpu_launch_commits == 1 &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.system_cycles > 0 &&
        runner_result.private_shadow_committed &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        runner_result.completion_status == 0 &&
        runner_result.completion_error_class == 0 &&
        runner_result.completion_error_code == 0 &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable && runner_result.recovery_clean &&
        runner_result.commands_accepted == 1 &&
        runner_result.commands_terminal_success == 1 &&
        runner_result.commands_terminal_failure == 0 &&
        runner_result.gmem_read_bytes == 0U &&
        runner_result.gmem_write_bytes == 0U &&
        runner_result.vector_elements == profile.expected_elements &&
        runner_result.q8_mac_count == 0 &&
        runner_result.f32_start_count == 0 &&
        runner_result.gmem_requests_accepted == 0U &&
        runner_result.gmem_responses_accepted == 0U &&
        runner_result.first_request_hold_cycles == 0U &&
        runner_result.result_bytes == profile.dst_bytes &&
        profile.expected_read_bytes == mover_read_words * 4U &&
        profile.expected_write_bytes == profile.expected_elements * 4U &&
        npu_functional_command_inactive(functional) &&
        npu_raw32_portal_matches(
            runner_result.f32_mover_portal,
            mover_request_groups,
            mover_index_groups + mover_source_groups,
            mover_write_groups,
            mover_read_words,
            profile.expected_elements) &&
        npu_raw32_portal_inactive(runner_result.f32_alu_portal) &&
        npu_q8_portal_inactive(runner_result.q8_portal) &&
        runner_result.required_issued_delta == 1 &&
        runner_result.required_completed_delta == 1 &&
        runner_result.rtl_cycles > 0 &&
        runner_result.rtl_cycles <= profile.cycle_upper_bound;
    if (!matching_success) {
        npu_note_rtl_failure(context);
        return false;
    }

    // The runner has already checked unique byte coverage in a private GMEM
    // shadow.  Publishing those raw bits is not host tensor arithmetic.
    if (!empty_get) {
        std::memcpy(node->data, private_shadow.data(), private_shadow.size());
    }
    canonical_binding->completed = true;
    ++context->audit_v2.executed_by_verilator;
    ++context->audit_v2.required_successfully_covered;
    return true;
}

static bool npu_execute_exact_sampler_argmax(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_sampler_argmax_profile & profile,
        canonical_node_state * canonical_binding) {
    if (context == nullptr || node == nullptr || canonical_binding == nullptr ||
        context->active_audit != audit_generation::v2 ||
        canonical_binding->owner != canonical_kernel_owner::sampler_argmax ||
        canonical_binding->profile_id != profile.profile_id ||
        profile.element_count == 0U || profile.element_count > 1048576U ||
        node->data == nullptr || node->src[0] == nullptr ||
        node->src[0]->data == nullptr || ggml_nbytes(node) != 4U ||
        ggml_nbytes(node->src[0]) != profile.element_count * 4U ||
        !npu_host_ranges_disjoint(
            node->src[0]->data, ggml_nbytes(node->src[0]),
            node->data, ggml_nbytes(node))) {
        npu_note_rtl_failure(context);
        return false;
    }
    if (canonical_binding->enqueued || canonical_binding->completed) {
        ++context->audit_v2.coverage_duplicate;
        return false;
    }
    canonical_binding->enqueued = true;
    const npu_macro_identity canonical_identity =
        npu_canonical_wire_identity(*canonical_binding);

    std::uint32_t private_token = std::numeric_limits<std::uint32_t>::max();
    npu_verilator_f32_argmax_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_f32_argmax(
        static_cast<const std::uint32_t *>(node->src[0]->data),
        static_cast<std::size_t>(profile.element_count),
        &canonical_identity, &private_token, &runner_result);
    npu_note_runner_result(context, runner_result);
    context->audit_v2.required_enqueued +=
        runner_result.required_issued_delta;

    system_transport_ledger & ledger = context->system_ledger;
    ledger.sampler_argmax_transactions +=
        runner_result.system_transport ? 1U : 0U;
    ledger.sampler_argmax_elements += runner_result.vector_elements;
    ledger.sampler_argmax_read_bytes += runner_result.gmem_read_bytes;
    ledger.sampler_argmax_scalar_write_bytes +=
        runner_result.gmem_write_bytes;
    const bool token_in_range = private_token < profile.element_count;
    ledger.sampler_argmax_invalid_tokens += token_in_range ? 0U : 1U;

    const bool canonical_identity_ok =
        npu_internal_identity_equal(
            runner_result.submitted_identity, canonical_identity) &&
        npu_internal_identity_equal(
            runner_result.returned_identity, canonical_identity);
    if (!canonical_identity_ok) {
        ++context->audit_v2.coverage_hash_mismatch;
    }
    if (runner_result.required_issued_delta > 1U ||
        runner_result.required_completed_delta > 1U) {
        ++context->audit_v2.coverage_duplicate;
    }

    const std::uint64_t logical_source_bytes = profile.element_count * 4U;
    const std::uint64_t expected_physical_read_bytes =
        (logical_source_bytes + 4U + 7U) & ~std::uint64_t{7};
    const auto & functional = npu_functional_command_ledger(runner_result);
    const bool matching_success =
        runner_returned && runner_result.passed &&
        !runner_result.controlled_reject && canonical_identity_ok &&
        token_in_range && runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.public_commands_accepted == 1U &&
        runner_result.public_completions == 1U &&
        runner_result.public_errors == 0U &&
        runner_result.cpu_config_commands_accepted == 30U &&
        runner_result.cpu_tensor_commands_accepted == 31U &&
        runner_result.cpu_terminals_accepted == 31U &&
        runner_result.cpu_config_commits == 30U &&
        runner_result.cpu_launch_commits == 1U &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.system_cycles > 0U &&
        runner_result.private_shadow_committed &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        runner_result.completion_status == 0U &&
        runner_result.completion_error_class == 0U &&
        runner_result.completion_error_code == 0U &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable && runner_result.recovery_clean &&
        runner_result.commands_accepted == 1U &&
        runner_result.commands_terminal_success == 1U &&
        runner_result.commands_terminal_failure == 0U &&
        runner_result.gmem_read_bytes == expected_physical_read_bytes &&
        runner_result.gmem_write_bytes == 4U &&
        runner_result.vector_elements == profile.element_count &&
        runner_result.q8_mac_count == 0U &&
        runner_result.state_update_count == 0U &&
        runner_result.f32_start_count == 0U &&
        runner_result.gmem_requests_accepted ==
            expected_physical_read_bytes / 8U + 1U &&
        runner_result.gmem_responses_accepted ==
            runner_result.gmem_requests_accepted &&
        runner_result.first_request_hold_cycles == 1U &&
        npu_functional_command_inactive(functional) &&
        npu_q8_portal_inactive(runner_result.q8_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_alu_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_mover_portal) &&
        runner_result.result_bytes == 4U &&
        runner_result.required_issued_delta == 1U &&
        runner_result.required_completed_delta == 1U &&
        runner_result.rtl_cycles > 0U &&
        runner_result.rtl_cycles <= runner_result.cycle_upper_bound;
    if (!matching_success) {
        npu_note_rtl_failure(context);
        return false;
    }

    // The only host-visible sampler product is one already-computed I32 token
    // index.  No logit or candidate is scanned or materialized by this code.
    std::memcpy(node->data, &private_token, sizeof(private_token));
    ++ledger.sampler_argmax_sampled_tokens;
    ledger.sampler_argmax_host_scalar_copy_bytes += sizeof(private_token);
    canonical_binding->completed = true;
    ++context->audit_v2.executed_by_verilator;
    ++context->audit_v2.required_successfully_covered;
    return true;
}

static bool npu_execute_exact_remaining(
        npu_backend_context * context,
        ggml_tensor * node,
        const npu_exact_profile & profile,
        canonical_node_state * canonical_binding) {
    const canonical_kernel_owner expected_owner =
        npu_remaining_canonical_owner(profile.owner);
    if (context == nullptr) {
        return false;
    }
    const auto fail_stage = [&](const char * stage) {
        std::fprintf(
            stderr,
            "[NPU-BACKEND-EXACT][FAIL] stage=%s manifest_profile=%u "
            "local_profile=%u owner=%u sources=%u node=%s op=%s "
            "canonical_owner=%u expected_owner=%u canonical_profile=%u "
            "enqueued=%u completed=%u\n",
            stage,
            static_cast<unsigned>(profile.manifest_profile_id),
            static_cast<unsigned>(profile.public_local_profile),
            static_cast<unsigned>(profile.owner),
            static_cast<unsigned>(profile.source_count),
            node != nullptr ? node->name : "<null>",
            node != nullptr ? ggml_op_name(node->op) : "<null>",
            canonical_binding != nullptr ?
                static_cast<unsigned>(canonical_binding->owner) : 0U,
            static_cast<unsigned>(expected_owner),
            canonical_binding != nullptr ?
                static_cast<unsigned>(canonical_binding->profile_id) : 0U,
            canonical_binding != nullptr && canonical_binding->enqueued ? 1U : 0U,
            canonical_binding != nullptr && canonical_binding->completed ? 1U : 0U);
        npu_note_rtl_failure(context);
        return false;
    };
    if (node == nullptr || canonical_binding == nullptr ||
        context->active_audit != audit_generation::v2 ||
        expected_owner == canonical_kernel_owner::none ||
        canonical_binding->owner != expected_owner ||
        canonical_binding->profile_id != profile.manifest_profile_id ||
        profile.source_count < 1U || profile.source_count > 3U) {
        return fail_stage("contract");
    }

    npu_exact_host_allocation dst_allocation = {};
    std::array<npu_exact_host_allocation, 3> source_allocations = {};
    if (!npu_exact_host_allocation_for(
            node, profile.dst, &dst_allocation)) {
        return fail_stage("dst-allocation");
    }
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        if (!npu_exact_host_allocation_for(
                node->src[index], profile.sources[index],
                &source_allocations[index])) {
            return fail_stage(index == 0U ? "src0-allocation" :
                              (index == 1U ? "src1-allocation" :
                                             "src2-allocation"));
        }
    }

    const bool cpy_old_dst = profile.owner == npu_exact_owner::cpy;
    const bool set_old_dst = profile.owner == npu_exact_owner::set_rows;
    if ((cpy_old_dst &&
         !npu_exact_same_storage(source_allocations[1], dst_allocation)) ||
        (set_old_dst &&
         !npu_exact_same_storage(source_allocations[2], dst_allocation))) {
        return fail_stage("old-dst-storage");
    }
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        const bool old_dst_alias =
            (cpy_old_dst && index == 1U) ||
            (set_old_dst && index == 2U);
        const bool gallocr_inplace_alias =
            index == 0U && npu_exact_owner_can_inplace(profile.owner) &&
            !profile.sources[index].view_present &&
            !profile.dst.view_present &&
            npu_exact_same_byte_range(
                source_allocations[index], dst_allocation) &&
            node->src[index]->data == node->data &&
            npu_exact_same_runtime_layout(node->src[index], node);
        const bool allowed_dst_alias =
            old_dst_alias || gallocr_inplace_alias;
        if (!allowed_dst_alias && npu_exact_host_ranges_overlap(
                source_allocations[index].bytes,
                source_allocations[index].size,
                dst_allocation.bytes, dst_allocation.size)) {
            return fail_stage("source-dst-overlap");
        }
        for (std::size_t other = index + 1;
             other < profile.source_count; ++other) {
            if (npu_exact_host_ranges_overlap(
                    source_allocations[index].bytes,
                    source_allocations[index].size,
                    source_allocations[other].bytes,
                    source_allocations[other].size)) {
                return fail_stage("source-source-overlap");
            }
        }
    }

    if (canonical_binding->enqueued || canonical_binding->completed) {
        ++context->audit_v2.coverage_duplicate;
        return false;
    }
    canonical_binding->enqueued = true;
    npu_macro_identity canonical_identity =
        npu_canonical_wire_identity(*canonical_binding);
    canonical_identity.profile_id = profile.public_local_profile;

    std::vector<std::uint8_t> private_shadow(dst_allocation.size, 0xa5);
    if (dst_allocation.size != 0) {
        std::memcpy(private_shadow.data(), dst_allocation.bytes,
                    dst_allocation.size);
    }
    std::array<npu_exact_raw_allocation, 3> raw_sources = {};
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        raw_sources[index] = {
            source_allocations[index].bytes,
            source_allocations[index].size,
        };
    }
    npu_exact_private_destination private_destination = {
        private_shadow.data(), private_shadow.size(),
    };
    npu_verilator_exact_result runner_result = {};
    const bool runner_returned = npu_verilator_execute_exact(
        &profile, &canonical_identity, &raw_sources,
        &private_destination, &runner_result);
    npu_note_runner_result(context, runner_result);
    context->audit_v2.required_enqueued +=
        runner_result.required_issued_delta;

    const bool canonical_identity_ok =
        npu_internal_identity_equal(
            runner_result.submitted_identity, canonical_identity) &&
        npu_internal_identity_equal(
            runner_result.returned_identity, canonical_identity);
    if (!canonical_identity_ok) {
        ++context->audit_v2.coverage_hash_mismatch;
    }
    if (runner_result.required_issued_delta > 1 ||
        runner_result.required_completed_delta > 1) {
        ++context->audit_v2.coverage_duplicate;
    }
    const auto & functional = npu_functional_command_ledger(runner_result);
    std::uint64_t expected_requests = 0;
    if (profile.expected_read_requests >
        std::numeric_limits<std::uint64_t>::max() -
            profile.expected_write_requests) {
        return fail_stage("request-count-overflow");
    }
    expected_requests = profile.expected_read_requests +
                        profile.expected_write_requests;
    const bool matching_success =
        runner_returned && runner_result.passed &&
        !runner_result.controlled_reject && canonical_identity_ok &&
        runner_result.manifest_profile_id == profile.manifest_profile_id &&
        runner_result.submitted_local_profile ==
            profile.public_local_profile &&
        runner_result.observed_local_profile ==
            profile.public_local_profile &&
        runner_result.system_transport &&
        runner_result.cpu_memory_separate &&
        runner_result.cpu_terminal_identity_match &&
        runner_result.cpu_config_commands_accepted == 30 &&
        runner_result.cpu_tensor_commands_accepted == 31 &&
        runner_result.cpu_terminals_accepted == 31 &&
        runner_result.cpu_config_commits == 30 &&
        runner_result.cpu_launch_commits == 1 &&
        runner_result.cpu_launch_instruction == 0x0220305bU &&
        runner_result.private_shadow_committed &&
        runner_result.completion_emitted &&
        runner_result.completion_accepted &&
        runner_result.completion_status == 0 &&
        runner_result.completion_error_class == 0 &&
        runner_result.completion_error_code == 0 &&
        runner_result.completion_identity_match &&
        runner_result.completion_framing_valid &&
        runner_result.completion_stable && runner_result.recovery_clean &&
        runner_result.commands_accepted == 1 &&
        runner_result.commands_terminal_success == 1 &&
        runner_result.commands_terminal_failure == 0 &&
        runner_result.public_commands_accepted == 1 &&
        runner_result.public_completions == 1 &&
        runner_result.public_errors == 0 &&
        runner_result.gmem_read_bytes == profile.expected_read_bytes &&
        runner_result.gmem_write_bytes == profile.expected_write_bytes &&
        runner_result.vector_elements == profile.expected_elements &&
        runner_result.q8_mac_count == profile.expected_q8_macs &&
        runner_result.state_update_count == profile.expected_state_updates &&
        runner_result.gmem_requests_accepted == expected_requests &&
        runner_result.gmem_responses_accepted == expected_requests &&
        npu_functional_command_inactive(functional) &&
        npu_q8_portal_inactive(runner_result.q8_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_alu_portal) &&
        npu_raw32_portal_inactive(runner_result.f32_mover_portal) &&
        runner_result.result_bytes == profile.expected_write_bytes &&
        runner_result.required_issued_delta == 1 &&
        runner_result.required_completed_delta == 1 &&
        runner_result.rtl_cycles > 0 &&
        runner_result.rtl_cycles <= profile.cycle_upper_bound;
    if (!matching_success) {
        std::fprintf(
            stderr,
            "[NPU-BACKEND-EXACT][RUNNER-DIAG] returned=%u passed=%u "
            "reject=%u identity=%u profile=%u/%u/%u transport=%u "
            "cpu=%u/%u config=%llu tensor=%llu terminals=%llu "
            "commits=%llu/%llu instruction=0x%08x private=%u "
            "completion=%u/%u status=%u class=%u code=%u "
            "completion_identity=%u framing=%u stable=%u recovery=%u "
            "commands=%llu/%llu/%llu public=%llu/%llu/%llu "
            "traffic=%llu/%llu/%llu/%llu/%llu requests=%llu/%llu "
            "expected=%llu/%llu/%llu/%llu/%llu/%llu inactive=%u/%u/%u/%u "
            "result_bytes=%llu required=%llu/%llu cycles=%llu/%llu\n",
            runner_returned ? 1U : 0U, runner_result.passed ? 1U : 0U,
            runner_result.controlled_reject ? 1U : 0U,
            canonical_identity_ok ? 1U : 0U,
            static_cast<unsigned>(runner_result.manifest_profile_id),
            static_cast<unsigned>(runner_result.submitted_local_profile),
            static_cast<unsigned>(runner_result.observed_local_profile),
            runner_result.system_transport ? 1U : 0U,
            runner_result.cpu_memory_separate ? 1U : 0U,
            runner_result.cpu_terminal_identity_match ? 1U : 0U,
            static_cast<unsigned long long>(
                runner_result.cpu_config_commands_accepted),
            static_cast<unsigned long long>(
                runner_result.cpu_tensor_commands_accepted),
            static_cast<unsigned long long>(
                runner_result.cpu_terminals_accepted),
            static_cast<unsigned long long>(runner_result.cpu_config_commits),
            static_cast<unsigned long long>(runner_result.cpu_launch_commits),
            runner_result.cpu_launch_instruction,
            runner_result.private_shadow_committed ? 1U : 0U,
            runner_result.completion_emitted ? 1U : 0U,
            runner_result.completion_accepted ? 1U : 0U,
            static_cast<unsigned>(runner_result.completion_status),
            static_cast<unsigned>(runner_result.completion_error_class),
            static_cast<unsigned>(runner_result.completion_error_code),
            runner_result.completion_identity_match ? 1U : 0U,
            runner_result.completion_framing_valid ? 1U : 0U,
            runner_result.completion_stable ? 1U : 0U,
            runner_result.recovery_clean ? 1U : 0U,
            static_cast<unsigned long long>(runner_result.commands_accepted),
            static_cast<unsigned long long>(
                runner_result.commands_terminal_success),
            static_cast<unsigned long long>(
                runner_result.commands_terminal_failure),
            static_cast<unsigned long long>(
                runner_result.public_commands_accepted),
            static_cast<unsigned long long>(runner_result.public_completions),
            static_cast<unsigned long long>(runner_result.public_errors),
            static_cast<unsigned long long>(runner_result.gmem_read_bytes),
            static_cast<unsigned long long>(runner_result.gmem_write_bytes),
            static_cast<unsigned long long>(runner_result.vector_elements),
            static_cast<unsigned long long>(runner_result.q8_mac_count),
            static_cast<unsigned long long>(runner_result.state_update_count),
            static_cast<unsigned long long>(
                runner_result.gmem_requests_accepted),
            static_cast<unsigned long long>(
                runner_result.gmem_responses_accepted),
            static_cast<unsigned long long>(profile.expected_read_bytes),
            static_cast<unsigned long long>(profile.expected_write_bytes),
            static_cast<unsigned long long>(profile.expected_elements),
            static_cast<unsigned long long>(profile.expected_q8_macs),
            static_cast<unsigned long long>(profile.expected_state_updates),
            static_cast<unsigned long long>(expected_requests),
            npu_functional_command_inactive(functional) ? 1U : 0U,
            npu_q8_portal_inactive(runner_result.q8_portal) ? 1U : 0U,
            npu_raw32_portal_inactive(
                runner_result.f32_alu_portal) ? 1U : 0U,
            npu_raw32_portal_inactive(
                runner_result.f32_mover_portal) ? 1U : 0U,
            static_cast<unsigned long long>(runner_result.result_bytes),
            static_cast<unsigned long long>(
                runner_result.required_issued_delta),
            static_cast<unsigned long long>(
                runner_result.required_completed_delta),
            static_cast<unsigned long long>(runner_result.rtl_cycles),
            static_cast<unsigned long long>(profile.cycle_upper_bound));
        return fail_stage("runner-contract");
    }

    // Both copies are byte publication only: the private allocation is seeded
    // from the old raw destination before RTL, then becomes public only after
    // exact SUCCESS/identity/framing/counter closure.
    if (dst_allocation.size != 0) {
        std::memcpy(dst_allocation.bytes, private_shadow.data(),
                    dst_allocation.size);
    }
    canonical_binding->completed = true;
    ++context->audit_v2.executed_by_verilator;
    ++context->audit_v2.required_successfully_covered;
    return true;
}

extern "C" bool ggml_backend_npu_audit_begin_v1(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint64_t required_seen,
        uint64_t assigned_to_npu) {
    if (!npu_is_backend(backend) || required_seen != assigned_to_npu) {
        return false;
    }

    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context)) {
        return false;
    }

    context->audit_v1 = {};
    context->audit_v1.abi_version = GGML_NPU_AUDIT_ABI_VERSION;
    context->audit_v1.dispatch_id = dispatch_id;
    context->audit_v1.required_seen = required_seen;
    context->audit_v1.assigned_to_npu = assigned_to_npu;
    context->active_audit = audit_generation::v1;
    return true;
}

extern "C" bool ggml_backend_npu_audit_end_v1(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_audit_snapshot_v1 * snapshot) {
    if (!npu_is_backend(backend) || snapshot == nullptr) {
        return false;
    }

    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || context->active_audit != audit_generation::v1 ||
        context->audit_v1.dispatch_id != dispatch_id) {
        return false;
    }

    *snapshot = context->audit_v1;
    context->active_audit = audit_generation::none;
    return snapshot->unsupported_required == 0 &&
           snapshot->rtl_failures == 0 &&
           snapshot->required_seen == snapshot->assigned_to_npu &&
           snapshot->assigned_to_npu == snapshot->executed_by_verilator;
}

extern "C" bool ggml_backend_npu_audit_begin_v2(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint64_t required_seen,
        uint64_t assigned_to_npu) {
    if (!npu_is_backend(backend) || required_seen != assigned_to_npu) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context) ||
        !context->canonical_binding_sealed ||
        context->canonical_binding_building ||
        context->canonical_expected_nodes != required_seen ||
        context->canonical_nodes.size() != required_seen ||
        context->canonical_ids.size() != required_seen ||
        context->canonical_graph_indices.size() != required_seen) {
        if (context != nullptr && !npu_audit_is_active(context)) {
            npu_clear_canonical_binding(context);
        }
        return false;
    }
    for (auto & entry : context->canonical_nodes) {
        entry.second.enqueued = false;
        entry.second.completed = false;
    }
    context->audit_v2 = {};
    context->audit_v2.abi_version = GGML_NPU_AUDIT_V2_ABI_VERSION;
    context->audit_v2.dispatch_id = dispatch_id;
    context->audit_v2.required_seen = required_seen;
    context->audit_v2.assigned_to_npu = assigned_to_npu;
    context->system_ledger = {};
    context->active_audit = audit_generation::v2;
    return true;
}

extern "C" bool ggml_backend_npu_audit_end_v2(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_audit_snapshot_v2 * snapshot) {
    if (!npu_is_backend(backend) || snapshot == nullptr) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || context->active_audit != audit_generation::v2 ||
        context->audit_v2.dispatch_id != dispatch_id) {
        return false;
    }

    ggml_npu_audit_snapshot_v2 closed = context->audit_v2;
    for (const auto & entry : context->canonical_nodes) {
        if (!entry.second.enqueued || !entry.second.completed) {
            ++closed.coverage_missing;
        }
    }
    if (closed.required_successfully_covered > closed.required_seen) {
        closed.coverage_duplicate +=
            closed.required_successfully_covered - closed.required_seen;
    }
    *snapshot = closed;
    const system_transport_ledger ledger = context->system_ledger;
    const bool audit_ok =
           snapshot->required_seen == snapshot->assigned_to_npu &&
           snapshot->assigned_to_npu == snapshot->required_enqueued &&
           snapshot->required_enqueued ==
               snapshot->required_successfully_covered &&
           snapshot->required_successfully_covered ==
               snapshot->executed_by_verilator &&
           snapshot->unsupported_required == 0 &&
           snapshot->cpu_fallback_attempts == 0 &&
           snapshot->host_tensor_ops == 0 &&
           snapshot->coverage_missing == 0 &&
           snapshot->coverage_duplicate == 0 &&
           snapshot->coverage_hash_mismatch == 0 &&
           snapshot->completion_identity_mismatch == 0 &&
           snapshot->commands_accepted == snapshot->required_enqueued &&
           snapshot->commands_terminal_success ==
               snapshot->required_successfully_covered &&
           snapshot->commands_terminal_failure == 0 &&
           snapshot->rtl_failures == 0 &&
           snapshot->gmem_errors == 0 &&
           snapshot->timeout_errors == 0;
    const bool products_safe =
        snapshot->required_seen <=
            std::numeric_limits<std::uint64_t>::max() / 31U;
    const auto raw32_portal_ok = [](
            const npu_system_raw32_portal_result & portal,
            std::uint64_t expected_first_holds) {
        return portal.request_groups == portal.expected_request_groups &&
               portal.response_groups ==
                   portal.expected_response_groups &&
               portal.expected_response_groups ==
                   portal.expected_request_groups &&
               portal.read_groups == portal.expected_read_groups &&
               portal.write_groups == portal.expected_write_groups &&
               portal.read_words == portal.expected_read_words &&
               portal.write_words == portal.expected_write_words &&
               portal.read_bytes == portal.expected_read_bytes &&
               portal.write_bytes == portal.expected_write_bytes &&
               portal.raw_read_copy_bytes ==
                   portal.expected_read_bytes &&
               portal.raw_write_copy_bytes ==
                   portal.expected_write_bytes &&
               portal.first_request_hold_cycles == expected_first_holds &&
               expected_first_holds <= portal.transactions &&
               portal.protocol_errors == 0U &&
               portal.latency_mismatches == 0U &&
               portal.payload_stability_mismatches == 0U;
    };
    std::uint64_t expected_q8_portal_transactions = 0U;
    std::uint64_t expected_f32_alu_portal_transactions = 0U;
    std::uint64_t expected_f32_mover_portal_transactions = 0U;
    std::uint64_t expected_sampler_argmax_transactions = 0U;
    for (const auto & entry : context->canonical_nodes) {
        switch (entry.second.owner) {
        case canonical_kernel_owner::q8_gemv:
            ++expected_q8_portal_transactions;
            break;
        case canonical_kernel_owner::f32_alu:
            ++expected_f32_alu_portal_transactions;
            break;
        case canonical_kernel_owner::f32_get_rows:
        case canonical_kernel_owner::f32_repeat:
            ++expected_f32_mover_portal_transactions;
            break;
        case canonical_kernel_owner::sampler_argmax:
            ++expected_sampler_argmax_transactions;
            break;
        default:
            break;
        }
    }
    const bool portal_owner_partition_ok =
        context->canonical_nodes.size() == snapshot->required_seen &&
        expected_q8_portal_transactions <= snapshot->required_seen &&
        expected_f32_alu_portal_transactions <= snapshot->required_seen &&
        expected_f32_mover_portal_transactions <= snapshot->required_seen &&
        expected_q8_portal_transactions +
            expected_f32_alu_portal_transactions <= snapshot->required_seen &&
        expected_q8_portal_transactions +
            expected_f32_alu_portal_transactions +
            expected_f32_mover_portal_transactions +
            expected_sampler_argmax_transactions <= snapshot->required_seen;
    const auto & functional = ledger.functional_command;
    const bool functional_ok = npu_functional_command_inactive(functional);
    const std::uint64_t sampler_argmax_elements = static_cast<std::uint64_t>(
        qwen_sampler_argmax_manifest::kProfile.src0_ne[0]);
    const std::uint64_t sampler_argmax_read_bytes =
        (sampler_argmax_elements * 4U + 4U + 7U) & ~std::uint64_t{7};
    const bool sampler_argmax_ok =
        expected_sampler_argmax_transactions <= snapshot->required_seen &&
        ledger.sampler_argmax_transactions ==
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_elements == sampler_argmax_elements *
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_read_bytes == sampler_argmax_read_bytes *
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_scalar_write_bytes == 4U *
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_sampled_tokens ==
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_host_scalar_copy_bytes == 4U *
            expected_sampler_argmax_transactions &&
        ledger.sampler_argmax_full_vocab_host_exports == 0U &&
        ledger.sampler_argmax_full_vocab_host_export_bytes == 0U &&
        ledger.sampler_argmax_cpu_candidate_scans == 0U &&
        ledger.sampler_argmax_invalid_tokens == 0U;
    const bool system_ok = products_safe && portal_owner_partition_ok &&
        ledger.system_transactions == snapshot->required_seen &&
        ((snapshot->required_seen == 0U && ledger.system_cycles == 0U &&
          ledger.rtl_cycles == 0U) ||
         (snapshot->required_seen != 0U && ledger.system_cycles > 0U &&
          ledger.rtl_cycles > 0U)) &&
        ledger.cpu_config_commands == 30U * snapshot->required_seen &&
        ledger.cpu_tensor_commands == 31U * snapshot->required_seen &&
        ledger.cpu_terminals == 31U * snapshot->required_seen &&
        ledger.cpu_config_commits == 30U * snapshot->required_seen &&
        ledger.cpu_launch_commits == snapshot->required_seen &&
        ledger.public_commands == snapshot->required_seen &&
        ledger.public_completions == snapshot->required_seen &&
        ledger.public_errors == 0 &&
        ledger.required_issued == snapshot->required_seen &&
        ledger.required_completed == snapshot->required_seen &&
        ledger.cpu_pid_identity_mismatch == 0 &&
        ledger.macro_identity_mismatch == 0 &&
        ledger.cpu_memory_separate == snapshot->required_seen &&
        ledger.first_request_hold_cycles ==
            ledger.expected_first_request_hold_cycles &&
        ledger.q8_portal_request_groups ==
            ledger.q8_portal_expected_request_groups &&
        ledger.q8_portal_response_groups ==
            ledger.q8_portal_expected_request_groups &&
        ledger.q8_portal_blocks == ledger.q8_portal_expected_blocks &&
        ledger.q8_portal_bytes == ledger.q8_portal_expected_bytes &&
        ledger.q8_portal_raw_copy_bytes == ledger.q8_portal_expected_bytes &&
        ledger.q8_portal_first_request_hold_cycles ==
            ledger.q8_portal_expected_first_holds &&
        ledger.q8_portal_expected_first_holds <=
            ledger.q8_portal_transactions &&
        ledger.q8_portal_protocol_errors == 0 &&
        ledger.q8_portal_latency_mismatches == 0 &&
        ledger.q8_portal_payload_stability_mismatches == 0 &&
        ledger.q8_portal_transactions ==
            expected_q8_portal_transactions &&
        ledger.f32_alu_portal.transactions ==
            expected_f32_alu_portal_transactions &&
        ledger.f32_mover_portal.transactions ==
            expected_f32_mover_portal_transactions &&
        raw32_portal_ok(
            ledger.f32_alu_portal,
            ledger.f32_alu_portal_expected_first_holds) &&
        raw32_portal_ok(
            ledger.f32_mover_portal,
            ledger.f32_mover_portal_expected_first_holds) &&
        sampler_argmax_ok && functional_ok;
    std::printf(
        "[NPU-SYSTEM-LEDGER][%s] dispatch=%llu "
        "system_transactions=%llu required_seen=%llu "
        "system_cycles=%llu rtl_cycles=%llu "
        "cpu_config_commands=%llu cpu_tensor_commands=%llu "
        "cpu_terminals=%llu cpu_config_commits=%llu "
        "cpu_launch_commits=%llu public_commands=%llu "
        "public_completions=%llu public_errors=%llu "
        "required_issued=%llu required_completed=%llu "
        "cpu_pid_identity_mismatch=%llu macro_identity_mismatch=%llu "
        "cpu_memory_separate=%llu first_request_hold_cycles=%llu "
        "expected_first_request_hold_cycles=%llu "
        "q8_portal_transactions=%llu q8_portal_requests=%llu "
        "q8_portal_responses=%llu q8_portal_blocks=%llu "
        "q8_portal_bytes=%llu q8_portal_raw_copy_bytes=%llu "
        "q8_portal_first_hold_cycles=%llu "
        "q8_portal_expected_first_holds=%llu "
        "q8_portal_expected_transactions=%llu "
        "q8_portal_expected_requests=%llu "
        "q8_portal_expected_blocks=%llu q8_portal_expected_bytes=%llu "
        "q8_portal_protocol_errors=%llu "
        "q8_portal_latency_mismatches=%llu "
        "q8_portal_payload_stability_mismatches=%llu\n",
        audit_ok && system_ok ? "PASS" : "FAIL",
        static_cast<unsigned long long>(dispatch_id),
        static_cast<unsigned long long>(ledger.system_transactions),
        static_cast<unsigned long long>(snapshot->required_seen),
        static_cast<unsigned long long>(ledger.system_cycles),
        static_cast<unsigned long long>(ledger.rtl_cycles),
        static_cast<unsigned long long>(ledger.cpu_config_commands),
        static_cast<unsigned long long>(ledger.cpu_tensor_commands),
        static_cast<unsigned long long>(ledger.cpu_terminals),
        static_cast<unsigned long long>(ledger.cpu_config_commits),
        static_cast<unsigned long long>(ledger.cpu_launch_commits),
        static_cast<unsigned long long>(ledger.public_commands),
        static_cast<unsigned long long>(ledger.public_completions),
        static_cast<unsigned long long>(ledger.public_errors),
        static_cast<unsigned long long>(ledger.required_issued),
        static_cast<unsigned long long>(ledger.required_completed),
        static_cast<unsigned long long>(
            ledger.cpu_pid_identity_mismatch),
        static_cast<unsigned long long>(ledger.macro_identity_mismatch),
        static_cast<unsigned long long>(ledger.cpu_memory_separate),
        static_cast<unsigned long long>(
            ledger.first_request_hold_cycles),
        static_cast<unsigned long long>(
            ledger.expected_first_request_hold_cycles),
        static_cast<unsigned long long>(ledger.q8_portal_transactions),
        static_cast<unsigned long long>(ledger.q8_portal_request_groups),
        static_cast<unsigned long long>(ledger.q8_portal_response_groups),
        static_cast<unsigned long long>(ledger.q8_portal_blocks),
        static_cast<unsigned long long>(ledger.q8_portal_bytes),
        static_cast<unsigned long long>(ledger.q8_portal_raw_copy_bytes),
        static_cast<unsigned long long>(
            ledger.q8_portal_first_request_hold_cycles),
        static_cast<unsigned long long>(
            ledger.q8_portal_expected_first_holds),
        static_cast<unsigned long long>(expected_q8_portal_transactions),
        static_cast<unsigned long long>(
            ledger.q8_portal_expected_request_groups),
        static_cast<unsigned long long>(ledger.q8_portal_expected_blocks),
        static_cast<unsigned long long>(ledger.q8_portal_expected_bytes),
        static_cast<unsigned long long>(ledger.q8_portal_protocol_errors),
        static_cast<unsigned long long>(
            ledger.q8_portal_latency_mismatches),
        static_cast<unsigned long long>(
            ledger.q8_portal_payload_stability_mismatches));
    const auto print_raw32_portal = [](
            const char * owner,
            std::uint64_t marker_dispatch_id,
            const npu_system_raw32_portal_result & portal,
            std::uint64_t expected_transactions,
            std::uint64_t expected_first_holds,
            bool passed) {
        std::printf(
            "[NPU-RAW32-PORTAL-LEDGER][%s] owner=%s "
            "dispatch=%llu "
            "transactions=%llu expected_transactions=%llu "
            "request_groups=%llu response_groups=%llu "
            "read_groups=%llu write_groups=%llu read_words=%llu "
            "write_words=%llu read_bytes=%llu write_bytes=%llu "
            "raw_read_copy_bytes=%llu raw_write_copy_bytes=%llu "
            "first_hold_cycles=%llu expected_first_holds=%llu "
            "expected_request_groups=%llu expected_response_groups=%llu "
            "expected_read_groups=%llu expected_write_groups=%llu "
            "expected_read_words=%llu expected_write_words=%llu "
            "expected_read_bytes=%llu expected_write_bytes=%llu "
            "protocol_errors=%llu latency_mismatches=%llu "
            "payload_stability_mismatches=%llu\n",
            passed ? "PASS" : "FAIL", owner,
            static_cast<unsigned long long>(marker_dispatch_id),
            static_cast<unsigned long long>(portal.transactions),
            static_cast<unsigned long long>(expected_transactions),
            static_cast<unsigned long long>(portal.request_groups),
            static_cast<unsigned long long>(portal.response_groups),
            static_cast<unsigned long long>(portal.read_groups),
            static_cast<unsigned long long>(portal.write_groups),
            static_cast<unsigned long long>(portal.read_words),
            static_cast<unsigned long long>(portal.write_words),
            static_cast<unsigned long long>(portal.read_bytes),
            static_cast<unsigned long long>(portal.write_bytes),
            static_cast<unsigned long long>(portal.raw_read_copy_bytes),
            static_cast<unsigned long long>(portal.raw_write_copy_bytes),
            static_cast<unsigned long long>(
                portal.first_request_hold_cycles),
            static_cast<unsigned long long>(expected_first_holds),
            static_cast<unsigned long long>(
                portal.expected_request_groups),
            static_cast<unsigned long long>(
                portal.expected_response_groups),
            static_cast<unsigned long long>(portal.expected_read_groups),
            static_cast<unsigned long long>(portal.expected_write_groups),
            static_cast<unsigned long long>(portal.expected_read_words),
            static_cast<unsigned long long>(portal.expected_write_words),
            static_cast<unsigned long long>(portal.expected_read_bytes),
            static_cast<unsigned long long>(portal.expected_write_bytes),
            static_cast<unsigned long long>(portal.protocol_errors),
            static_cast<unsigned long long>(portal.latency_mismatches),
            static_cast<unsigned long long>(
                portal.payload_stability_mismatches));
    };
    print_raw32_portal(
        "f32_alu", dispatch_id, ledger.f32_alu_portal,
        expected_f32_alu_portal_transactions,
        ledger.f32_alu_portal_expected_first_holds,
        ledger.f32_alu_portal.transactions ==
            expected_f32_alu_portal_transactions && raw32_portal_ok(
            ledger.f32_alu_portal,
            ledger.f32_alu_portal_expected_first_holds));
    print_raw32_portal(
        "f32_mover", dispatch_id, ledger.f32_mover_portal,
        expected_f32_mover_portal_transactions,
        ledger.f32_mover_portal_expected_first_holds,
        ledger.f32_mover_portal.transactions ==
            expected_f32_mover_portal_transactions && raw32_portal_ok(
            ledger.f32_mover_portal,
            ledger.f32_mover_portal_expected_first_holds));
    std::printf(
        "[NPU-SAMPLER-ARGMAX-LEDGER][%s] dispatch=%llu "
        "transactions=%llu expected_transactions=%llu "
        "elements=%llu expected_elements=%llu read_bytes=%llu "
        "expected_read_bytes=%llu scalar_write_bytes=%llu "
        "expected_scalar_write_bytes=%llu sampled_tokens=%llu "
        "expected_sampled_tokens=%llu host_scalar_copy_bytes=%llu "
        "full_vocab_host_exports=%llu full_vocab_host_export_bytes=%llu "
        "cpu_candidate_scans=%llu invalid_tokens=%llu\n",
        audit_ok && system_ok ? "PASS" : "FAIL",
        static_cast<unsigned long long>(dispatch_id),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_transactions),
        static_cast<unsigned long long>(
            expected_sampler_argmax_transactions),
        static_cast<unsigned long long>(ledger.sampler_argmax_elements),
        static_cast<unsigned long long>(sampler_argmax_elements *
            expected_sampler_argmax_transactions),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_read_bytes),
        static_cast<unsigned long long>(sampler_argmax_read_bytes *
            expected_sampler_argmax_transactions),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_scalar_write_bytes),
        static_cast<unsigned long long>(4U *
            expected_sampler_argmax_transactions),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_sampled_tokens),
        static_cast<unsigned long long>(
            expected_sampler_argmax_transactions),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_host_scalar_copy_bytes),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_full_vocab_host_exports),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_full_vocab_host_export_bytes),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_cpu_candidate_scans),
        static_cast<unsigned long long>(
            ledger.sampler_argmax_invalid_tokens));
    std::printf(
        "[NPU-FUNCTIONAL-COMMAND-LEDGER][%s] dispatch=%llu "
        "command_dispatches=%llu command_completions=%llu "
        "successes=%llu failures=%llu read_words=%llu write_words=%llu "
        "read_bytes=%llu write_bytes=%llu q8_blocks=%llu q8_macs=%llu "
        "vector_elements=%llu expected_read_words=%llu "
        "expected_write_words=%llu expected_read_bytes=%llu "
        "expected_write_bytes=%llu expected_q8_blocks=%llu "
        "expected_q8_macs=%llu expected_vector_elements=%llu "
        "callback_read_calls=%llu callback_write_calls=%llu "
        "callback_read_bytes=%llu callback_write_bytes=%llu "
        "callback_errors=%llu command_mismatches=%llu protocol_errors=%llu "
        "old_gmem_requests=%llu old_gmem_responses=%llu "
        "old_q8_portal_transactions=%llu "
        "old_f32_alu_portal_transactions=%llu "
        "old_f32_mover_portal_transactions=%llu\n",
        audit_ok && system_ok ? "PASS" : "FAIL",
        static_cast<unsigned long long>(dispatch_id),
        static_cast<unsigned long long>(functional.dispatches),
        static_cast<unsigned long long>(functional.completions),
        static_cast<unsigned long long>(functional.successes),
        static_cast<unsigned long long>(functional.failures),
        static_cast<unsigned long long>(functional.read_words),
        static_cast<unsigned long long>(functional.write_words),
        static_cast<unsigned long long>(functional.read_bytes),
        static_cast<unsigned long long>(functional.write_bytes),
        static_cast<unsigned long long>(functional.q8_blocks),
        static_cast<unsigned long long>(functional.q8_mac_count),
        static_cast<unsigned long long>(functional.vector_elements),
        static_cast<unsigned long long>(functional.expected_read_words),
        static_cast<unsigned long long>(functional.expected_write_words),
        static_cast<unsigned long long>(functional.expected_read_bytes),
        static_cast<unsigned long long>(functional.expected_write_bytes),
        static_cast<unsigned long long>(functional.expected_q8_blocks),
        static_cast<unsigned long long>(functional.expected_q8_mac_count),
        static_cast<unsigned long long>(
            functional.expected_vector_elements),
        static_cast<unsigned long long>(functional.callback_read_calls),
        static_cast<unsigned long long>(functional.callback_write_calls),
        static_cast<unsigned long long>(functional.callback_read_bytes),
        static_cast<unsigned long long>(functional.callback_write_bytes),
        static_cast<unsigned long long>(functional.callback_errors),
        static_cast<unsigned long long>(functional.command_mismatches),
        static_cast<unsigned long long>(functional.protocol_errors),
        static_cast<unsigned long long>(functional.old_gmem_requests),
        static_cast<unsigned long long>(functional.old_gmem_responses),
        static_cast<unsigned long long>(
            functional.old_q8_portal_transactions),
        static_cast<unsigned long long>(
            functional.old_f32_alu_portal_transactions),
        static_cast<unsigned long long>(
            functional.old_f32_mover_portal_transactions));
    context->active_audit = audit_generation::none;
    context->system_ledger = {};
    npu_clear_canonical_binding(context);
    return audit_ok && system_ok;
}

extern "C" bool ggml_backend_npu_representative_audit_begin_v4(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        uint32_t expected_profiles) {
    if (!npu_is_backend(backend) ||
        expected_profiles != GGML_NPU_F32_ALU_PROFILE_COUNT) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr || npu_audit_is_active(context)) {
        return false;
    }
    context->representative_v4 = {};
    context->representative_v4.abi_version =
        GGML_NPU_REPRESENTATIVE_AUDIT_V4_ABI_VERSION;
    context->representative_v4.expected_profiles = expected_profiles;
    context->representative_v4.dispatch_id = dispatch_id;
    // Historical v11 proved one representative only.  No exact canonical
    // identity is completed by either that predecessor or this synthetic set.
    context->representative_v4.
        predecessor_representative_transactions_passed = 1;
    context->representative_v4.verified_canonical_completed = 0;
    context->representative_v4.verified_canonical_remaining = 1080;
    context->active_audit = audit_generation::representative_v4;
    return true;
}

extern "C" bool ggml_backend_npu_representative_audit_validate_v4(
        const ggml_npu_representative_audit_snapshot_v4 * snapshot) {
    return snapshot != nullptr &&
           npu_validate_representative_snapshot(*snapshot);
}

extern "C" bool ggml_backend_npu_representative_audit_end_v4(
        ggml_backend_t backend,
        uint64_t dispatch_id,
        ggml_npu_representative_audit_snapshot_v4 * snapshot) {
    if (!npu_is_backend(backend) || snapshot == nullptr) {
        return false;
    }
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (context == nullptr ||
        context->active_audit != audit_generation::representative_v4 ||
        context->representative_v4.dispatch_id != dispatch_id) {
        return false;
    }

    ggml_npu_representative_audit_snapshot_v4 closed =
        context->representative_v4;
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.command_accepted_mask);
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.completion_emitted_mask);
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.completion_accepted_mask);
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.raw_dst_committed_mask);
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.representative_covered_mask);
    closed.missing_identity_rejections +=
        npu_missing_profile_count(closed.returned_identity_mask);
    *snapshot = closed;
    context->active_audit = audit_generation::none;
    return npu_validate_representative_snapshot(*snapshot);
}

extern "C" bool ggml_backend_npu_rtl_self_test_v1(
        ggml_npu_rtl_self_test_result_v1 * result) {
    if (result == nullptr) {
        return false;
    }

    *result = {};
    result->abi_version = GGML_NPU_RTL_SELF_TEST_ABI_VERSION;
    npu_verilator_self_test_result runner_result = {};
    const bool passed = npu_verilator_run_mm2_self_test(&runner_result);
    result->passed = runner_result.passed ? 1u : 0u;
    result->rtl_cycles = runner_result.rtl_cycles;
    result->output_bytes = runner_result.output_bytes;
    result->error_code = runner_result.error_code;
    return passed && runner_result.passed;
}

extern "C" bool ggml_backend_npu_f32_add_self_test_v2(
        uint32_t mode,
        ggml_npu_f32_add_self_test_result_v2 * result) {
    if (result == nullptr ||
        mode > GGML_NPU_F32_ADD_MODE_OVERPERMISSION) {
        return false;
    }
    *result = {};
    result->abi_version = GGML_NPU_F32_ADD_SELF_TEST_ABI_VERSION;
    result->mode = mode;

    npu_verilator_f32_add_result runner_result = {};
    const bool returned = npu_verilator_run_f32_add_self_test(
        static_cast<npu_f32_add_mode>(mode), &runner_result);
    result->passed = runner_result.passed ? 1u : 0u;
    result->controlled_reject = runner_result.controlled_reject ? 1u : 0u;
    result->completion_status = runner_result.completion_status;
    result->completion_error_class = runner_result.completion_error_class;
    result->completion_error_code = runner_result.completion_error_code;
    result->runner_error_code = runner_result.runner_error_code;
    result->rtl_cycles = runner_result.rtl_cycles;
    result->gmem_read_bytes = runner_result.gmem_read_bytes;
    result->gmem_write_bytes = runner_result.gmem_write_bytes;
    result->vector_elements = runner_result.vector_elements;
    result->f32_start_count = runner_result.f32_start_count;
    result->commands_accepted = runner_result.commands_accepted;
    result->commands_terminal_success =
        runner_result.commands_terminal_success;
    result->commands_terminal_failure =
        runner_result.commands_terminal_failure;
    result->gmem_requests_accepted = runner_result.gmem_requests_accepted;
    result->gmem_responses_accepted = runner_result.gmem_responses_accepted;
    result->result_bytes = runner_result.result_bytes;
    result->completion_identity_match =
        runner_result.completion_identity_match ? 1u : 0u;
    result->completion_framing_valid =
        runner_result.completion_framing_valid ? 1u : 0u;
    result->completion_stable =
        runner_result.completion_stable ? 1u : 0u;
    result->recovery_clean = runner_result.recovery_clean ? 1u : 0u;
    return returned && runner_result.passed;
}

extern "C" bool ggml_backend_npu_f32_alu_self_test_v3(
        uint32_t profile_id,
        uint32_t mode,
        ggml_npu_f32_alu_self_test_result_v3 * result) {
    if (result == nullptr ||
        profile_id >= GGML_NPU_F32_ALU_PROFILE_COUNT ||
        mode > GGML_NPU_F32_ALU_MODE_REQ_READY_LOW) {
        return false;
    }
    *result = {};
    result->abi_version = GGML_NPU_F32_ALU_SELF_TEST_ABI_VERSION;
    result->profile_id = profile_id;
    result->mode = mode;

    npu_verilator_f32_alu_result runner_result = {};
    const bool returned = npu_verilator_run_f32_alu_self_test(
        profile_id, static_cast<npu_f32_alu_mode>(mode), &runner_result);
    result->passed = runner_result.passed ? 1u : 0u;
    result->controlled_reject =
        runner_result.controlled_reject ? 1u : 0u;
    result->completion_status = runner_result.completion_status;
    result->completion_error_class = runner_result.completion_error_class;
    result->completion_error_code = runner_result.completion_error_code;
    result->runner_error_code = runner_result.runner_error_code;
    result->raw_dst_committed =
        runner_result.private_shadow_committed ? 1u : 0u;
    result->completion_identity_match =
        runner_result.completion_identity_match ? 1u : 0u;
    result->completion_framing_valid =
        runner_result.completion_framing_valid ? 1u : 0u;
    result->completion_stable =
        runner_result.completion_stable ? 1u : 0u;
    result->recovery_clean = runner_result.recovery_clean ? 1u : 0u;
    result->rtl_cycles = runner_result.rtl_cycles;
    result->cycle_upper_bound = runner_result.cycle_upper_bound;
    result->gmem_read_bytes = runner_result.gmem_read_bytes;
    result->gmem_write_bytes = runner_result.gmem_write_bytes;
    result->vector_elements = runner_result.vector_elements;
    result->f32_start_count = runner_result.f32_start_count;
    result->commands_accepted = runner_result.commands_accepted;
    result->commands_terminal_success =
        runner_result.commands_terminal_success;
    result->commands_terminal_failure =
        runner_result.commands_terminal_failure;
    result->gmem_requests_accepted =
        runner_result.gmem_requests_accepted;
    result->gmem_responses_accepted =
        runner_result.gmem_responses_accepted;
    result->result_bytes = runner_result.result_bytes;
    return returned && runner_result.passed;
}

extern "C" bool ggml_backend_npu_f32_alu_self_test_v4(
        uint32_t profile_id,
        uint32_t mode,
        ggml_npu_f32_alu_self_test_result_v4 * result) {
    if (result == nullptr ||
        profile_id >= GGML_NPU_F32_ALU_PROFILE_COUNT ||
        mode > GGML_NPU_F32_ALU_MODE_REQ_READY_LOW) {
        return false;
    }
    *result = {};
    result->abi_version = GGML_NPU_F32_ALU_SELF_TEST_V4_ABI_VERSION;
    result->profile_id = profile_id;
    result->mode = mode;

    npu_verilator_f32_alu_result runner_result = {};
    const bool returned = npu_verilator_run_f32_alu_self_test(
        profile_id, static_cast<npu_f32_alu_mode>(mode), &runner_result);
    result->passed = runner_result.passed ? 1u : 0u;
    result->controlled_reject =
        runner_result.controlled_reject ? 1u : 0u;
    result->private_shadow_committed =
        runner_result.private_shadow_committed ? 1u : 0u;
    result->completion_emitted =
        runner_result.completion_emitted ? 1u : 0u;
    result->completion_accepted =
        runner_result.completion_accepted ? 1u : 0u;
    result->representative_identity_match =
        runner_result.representative_identity_match ? 1u : 0u;
    result->completion_identity_match =
        runner_result.completion_identity_match ? 1u : 0u;
    result->completion_framing_valid =
        runner_result.completion_framing_valid ? 1u : 0u;
    result->completion_stable =
        runner_result.completion_stable ? 1u : 0u;
    result->recovery_clean = runner_result.recovery_clean ? 1u : 0u;
    result->submitted_profile_id = runner_result.submitted_profile_id;
    result->observed_profile_id = runner_result.observed_profile_id;
    result->completion_status = runner_result.completion_status;
    result->completion_error_class = runner_result.completion_error_class;
    result->completion_error_code = runner_result.completion_error_code;
    result->runner_error_code = runner_result.runner_error_code;
    result->rtl_cycles = runner_result.rtl_cycles;
    result->cycle_upper_bound = runner_result.cycle_upper_bound;
    result->gmem_read_bytes = runner_result.gmem_read_bytes;
    result->gmem_write_bytes = runner_result.gmem_write_bytes;
    result->vector_elements = runner_result.vector_elements;
    result->f32_start_count = runner_result.f32_start_count;
    result->commands_accepted = runner_result.commands_accepted;
    result->commands_terminal_success =
        runner_result.commands_terminal_success;
    result->commands_terminal_failure =
        runner_result.commands_terminal_failure;
    result->gmem_requests_accepted = runner_result.gmem_requests_accepted;
    result->gmem_responses_accepted = runner_result.gmem_responses_accepted;
    result->result_bytes = runner_result.result_bytes;
    result->required_issued_delta = runner_result.required_issued_delta;
    result->required_completed_delta = runner_result.required_completed_delta;
    result->submitted_identity =
        npu_export_identity(runner_result.submitted_identity);
    result->returned_identity =
        npu_export_identity(runner_result.returned_identity);
    return returned && runner_result.passed;
}

static const char * npu_backend_name(ggml_backend_t) {
    return "NPU";
}

static void npu_backend_free(ggml_backend_t backend) {
    delete static_cast<npu_backend_context *>(backend->context);
    delete backend;
}

static ggml_status npu_backend_graph_compute(
        ggml_backend_t backend,
        ggml_cgraph * graph) {
    auto * context = static_cast<npu_backend_context *>(backend->context);
    if (!npu_audit_is_active(context) || graph == nullptr) {
        return GGML_STATUS_FAILED;
    }

    const int node_count = ggml_graph_n_nodes(graph);
    for (int index = 0; index < node_count; ++index) {
        ggml_tensor * node = ggml_graph_node(graph, index);
        if (node == nullptr) {
            npu_note_rtl_failure(context);
            return GGML_STATUS_FAILED;
        }
        if ((node->flags & GGML_TENSOR_FLAG_COMPUTE) == 0) {
            continue;
        }
        if (npu_is_metadata_op(node->op)) {
            continue;
        }
        npu_f32_alu_profile f32_profile = {};
        npu_q8_get_rows_profile q8_profile = {};
        npu_q8_gemv_profile q8_gemv_profile = {};
        npu_f32_mover_profile f32_mover_profile = {};
        npu_sampler_argmax_profile sampler_argmax_profile = {};
        npu_exact_profile remaining_profile = {};
        const bool matches_f32 =
            npu_match_f32_alu_profile(node, &f32_profile);
        const bool matches_q8 =
            npu_match_q8_get_rows_profile(node, &q8_profile);
        const bool matches_q8_gemv =
            npu_match_q8_gemv_profile(node, &q8_gemv_profile);
        const bool matches_f32_mover =
            npu_match_f32_mover_profile(node, &f32_mover_profile);
        const bool matches_sampler_argmax =
            npu_match_sampler_argmax_profile(
                node, &sampler_argmax_profile);
        const bool matches_remaining =
            npu_match_remaining_profile(node, &remaining_profile);
        const unsigned owner_count = static_cast<unsigned>(matches_f32) +
                                     static_cast<unsigned>(matches_q8) +
                                     static_cast<unsigned>(matches_q8_gemv) +
                                     static_cast<unsigned>(matches_f32_mover) +
                                     static_cast<unsigned>(
                                         matches_sampler_argmax) +
                                     static_cast<unsigned>(matches_remaining);
        if (owner_count != 1) {
            npu_note_unsupported(context);
            return GGML_STATUS_FAILED;
        }
        canonical_node_state * canonical_binding = nullptr;
        if (context->active_audit == audit_generation::v2) {
            auto binding = context->canonical_nodes.find(node);
            if (binding == context->canonical_nodes.end()) {
                npu_note_rtl_failure(context);
                return GGML_STATUS_FAILED;
            }
            canonical_binding = &binding->second;
            const canonical_kernel_owner expected_owner = matches_f32 ?
                canonical_kernel_owner::f32_alu : matches_q8 ?
                canonical_kernel_owner::q8_get_rows :
                matches_q8_gemv ? canonical_kernel_owner::q8_gemv :
                matches_sampler_argmax ?
                    canonical_kernel_owner::sampler_argmax :
                matches_f32_mover &&
                    f32_mover_profile.owner ==
                        npu_f32_mover_owner::get_rows ?
                    canonical_kernel_owner::f32_get_rows :
                matches_f32_mover ? canonical_kernel_owner::f32_repeat :
                    npu_remaining_canonical_owner(remaining_profile.owner);
            const std::uint32_t expected_profile = matches_f32 ?
                f32_profile.profile_id : matches_q8 ?
                q8_profile.profile_id : matches_q8_gemv ?
                q8_gemv_profile.profile_id : matches_sampler_argmax ?
                sampler_argmax_profile.profile_id : matches_f32_mover ?
                f32_mover_profile.profile_id :
                remaining_profile.manifest_profile_id;
            if (canonical_binding->owner != expected_owner ||
                canonical_binding->profile_id != expected_profile) {
                ++context->audit_v2.coverage_hash_mismatch;
                return GGML_STATUS_FAILED;
            }
        }
        const bool executed = matches_f32 ?
            npu_execute_exact_f32_alu(
                context, node, f32_profile, canonical_binding) :
            matches_q8 ? npu_execute_exact_q8_get_rows(
                context, node, q8_profile, canonical_binding) :
            matches_q8_gemv ? npu_execute_exact_q8_gemv(
                context, node, q8_gemv_profile, canonical_binding) :
            matches_sampler_argmax ? npu_execute_exact_sampler_argmax(
                context, node, sampler_argmax_profile,
                canonical_binding) :
            matches_f32_mover ? npu_execute_exact_f32_mover(
                context, node, f32_mover_profile, canonical_binding) :
            npu_execute_exact_remaining(
                context, node, remaining_profile, canonical_binding);
        if (!executed) {
            return GGML_STATUS_FAILED;
        }
    }

    return GGML_STATUS_SUCCESS;
}

static const ggml_backend_i npu_backend_interface = {
    npu_backend_name,
    npu_backend_free,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    npu_backend_graph_compute,
    nullptr,
    nullptr,
    nullptr,
};

static const char * npu_device_name(ggml_backend_dev_t) {
    return "NPU";
}

static const char * npu_device_description(ggml_backend_dev_t) {
    return "Verilated RISC-V Tensor NPU coprocessor";
}

static void npu_device_memory(ggml_backend_dev_t, size_t * free, size_t * total) {
    *free = 0;
    *total = 0;
}

static enum ggml_backend_dev_type npu_device_type(ggml_backend_dev_t) {
    return GGML_BACKEND_DEVICE_TYPE_ACCEL;
}

static void npu_device_properties(
        ggml_backend_dev_t device,
        ggml_backend_dev_props * properties) {
    properties->name = npu_device_name(device);
    properties->description = npu_device_description(device);
    properties->type = npu_device_type(device);
    properties->device_id = nullptr;
    npu_device_memory(device, &properties->memory_free, &properties->memory_total);
    properties->caps = {
        false,
        false,
        true,
        false,
        true,
    };
}

static ggml_backend_buffer_type_t npu_device_buffer_type(ggml_backend_dev_t) {
    return ggml_backend_cpu_buffer_type();
}

static ggml_backend_buffer_t npu_device_buffer_from_host(
        ggml_backend_dev_t,
        void * pointer,
        size_t size,
        size_t) {
    return ggml_backend_cpu_buffer_from_ptr(pointer, size);
}

static bool npu_device_supports_op(
        ggml_backend_dev_t,
        const ggml_tensor * op) {
    return op != nullptr &&
           (npu_is_metadata_op(op->op) ||
            npu_match_f32_alu_profile(op, nullptr) ||
            npu_match_q8_get_rows_profile(op, nullptr) ||
            npu_match_q8_gemv_profile(op, nullptr) ||
            npu_match_f32_mover_profile(op, nullptr) ||
            npu_match_sampler_argmax_profile(op, nullptr) ||
            npu_match_remaining_profile(op, nullptr));
}

static bool npu_device_supports_buffer(
        ggml_backend_dev_t,
        ggml_backend_buffer_type_t buffer_type) {
    return ggml_backend_buft_is_host(buffer_type);
}

static ggml_backend_t npu_device_init_backend(
        ggml_backend_dev_t device,
        const char *) {
    auto * context = new (std::nothrow) npu_backend_context;
    if (context == nullptr) {
        return nullptr;
    }

    auto * backend = new (std::nothrow) ggml_backend {
        npu_guid(),
        npu_backend_interface,
        device,
        context,
    };
    if (backend == nullptr) {
        delete context;
    }
    return backend;
}

static const ggml_backend_device_i npu_device_interface = {
    npu_device_name,
    npu_device_description,
    npu_device_memory,
    npu_device_type,
    npu_device_properties,
    npu_device_init_backend,
    npu_device_buffer_type,
    nullptr,
    npu_device_buffer_from_host,
    npu_device_supports_op,
    npu_device_supports_buffer,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
};

static const char * npu_registry_name(ggml_backend_reg_t) {
    return "NPU";
}

static size_t npu_registry_device_count(ggml_backend_reg_t) {
    return 1;
}

static ggml_backend_dev_t npu_registry_device(
        ggml_backend_reg_t registry,
        size_t index) {
    if (index != 0) {
        return nullptr;
    }
    static ggml_backend_device device = {
        npu_device_interface,
        registry,
        nullptr,
    };
    return &device;
}

static void * npu_registry_proc_address(ggml_backend_reg_t, const char * name) {
    if (name == nullptr) {
        return nullptr;
    }
    if (std::strcmp(name, GGML_NPU_AUDIT_BEGIN_PROC) == 0) {
        return reinterpret_cast<void *>(ggml_backend_npu_audit_begin_v1);
    }
    if (std::strcmp(name, GGML_NPU_AUDIT_END_PROC) == 0) {
        return reinterpret_cast<void *>(ggml_backend_npu_audit_end_v1);
    }
    if (std::strcmp(name, GGML_NPU_AUDIT_BEGIN_V2_PROC) == 0) {
        return reinterpret_cast<void *>(ggml_backend_npu_audit_begin_v2);
    }
    if (std::strcmp(name, GGML_NPU_AUDIT_END_V2_PROC) == 0) {
        return reinterpret_cast<void *>(ggml_backend_npu_audit_end_v2);
    }
    if (std::strcmp(
            name, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_canonical_binding_begin_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_canonical_binding_bind_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_canonical_binding_seal_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_REPRESENTATIVE_AUDIT_BEGIN_V4_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_representative_audit_begin_v4);
    }
    if (std::strcmp(
            name, GGML_NPU_REPRESENTATIVE_AUDIT_END_V4_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_representative_audit_end_v4);
    }
    if (std::strcmp(
            name, GGML_NPU_REPRESENTATIVE_AUDIT_VALIDATE_V4_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_representative_audit_validate_v4);
    }
    if (std::strcmp(name, GGML_NPU_RTL_SELF_TEST_PROC) == 0) {
        return reinterpret_cast<void *>(ggml_backend_npu_rtl_self_test_v1);
    }
    if (std::strcmp(name, GGML_NPU_F32_ADD_SELF_TEST_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_f32_add_self_test_v2);
    }
    if (std::strcmp(name, GGML_NPU_F32_ALU_SELF_TEST_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_f32_alu_self_test_v3);
    }
    if (std::strcmp(name, GGML_NPU_F32_ALU_SELF_TEST_V4_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_f32_alu_self_test_v4);
    }
    return nullptr;
}

static const ggml_backend_reg_i npu_registry_interface = {
    npu_registry_name,
    npu_registry_device_count,
    npu_registry_device,
    npu_registry_proc_address,
};

static ggml_backend_reg_t npu_registry() {
    static ggml_backend_reg registry = {
        GGML_BACKEND_API_VERSION,
        npu_registry_interface,
        nullptr,
    };
    return &registry;
}

static int npu_backend_score() {
    return 1;
}

} // namespace

GGML_BACKEND_DL_IMPL(npu_registry)
GGML_BACKEND_DL_SCORE_IMPL(npu_backend_score)
