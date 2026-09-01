#include "ggml-backend.h"
#include "ggml.h"
#include "npu-audit-api.h"
#include "npu-verilator-runner.h"
#include "qwen-q8-gemv-manifest.generated.h"
#include "qwen-remaining-manifest.generated.h"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <set>
#include <vector>

namespace {

using remaining_node = qwen_remaining_manifest::canonical_node;
using remaining_profile = qwen_remaining_manifest::profile;
using tensor_spec = qwen_remaining_manifest::tensor_spec;

constexpr std::size_t kAlignment = 32;
constexpr std::uint64_t kBindingBase = 0x43300000ULL;
constexpr std::uint64_t kDispatchBase = 0x43310000ULL;
constexpr std::array<std::uint32_t, 12> kExecutionProfiles = {
    17U,  // CPY / non-zero source view
    21U,  // CONT / non-zero source view and row stride
    16U,  // CPY / empty D=18432 lifecycle
    18U,  // CPY / empty D=262144 lifecycle
    0U,   // UNARY / public unary-glu family
    10U,  // RMS_NORM / public norm-sum family
    15U,  // SSM_CONV
    20U,  // CONT / public mover-set family
    23U,  // SET_ROWS / old-destination raw shadow
    25U,  // F16 attention
    27U,  // ROPE
    29U,  // SOFT_MAX / public reduce-softmax family
};

static_assert(qwen_remaining_manifest::kOwnerCount == 13);
static_assert(qwen_remaining_manifest::kProfileCount == 30);
static_assert(qwen_remaining_manifest::kCanonicalNodeCount == 433);
static_assert(qwen_remaining_manifest::kExistingOwnerNodeCount == 646);
static_assert(qwen_remaining_manifest::kRequiredNonmetadataCount == 1080);
static_assert(qwen_remaining_manifest::kSamplerArgmaxNodeCount == 1);

int checks = 0;

bool check(bool condition, const char * message) {
    ++checks;
    if (!condition) {
        std::fprintf(stderr,
                     "[NPU-BACKEND-REMAINING][FAIL] check=%d message=%s\n",
                     checks, message);
    }
    return condition;
}

const remaining_profile * profile_by_id(std::uint32_t profile_id) {
    for (const auto & profile : qwen_remaining_manifest::kProfiles) {
        if (profile.profile_id == profile_id) {
            return &profile;
        }
    }
    return nullptr;
}

const remaining_node * representative_for_profile(std::uint32_t profile_id) {
    for (const auto & node : qwen_remaining_manifest::kCanonicalNodes) {
        if (node.profile_id == profile_id) {
            return &node;
        }
    }
    return nullptr;
}

bool apply_tensor_spec(
        ggml_tensor * tensor,
        const tensor_spec & spec,
        ggml_tensor * view_root = nullptr) {
    if (tensor == nullptr ||
        (spec.view_present && view_root == nullptr) ||
        (!spec.view_present && view_root != nullptr)) {
        return false;
    }
    tensor->type = static_cast<enum ggml_type>(spec.type_id);
    tensor->op = static_cast<enum ggml_op>(spec.op_id);
    tensor->flags = spec.flags;
    tensor->view_src = view_root;
    tensor->view_offs = spec.view_offs;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        tensor->ne[dimension] = spec.ne[dimension];
        tensor->nb[dimension] = spec.nb[dimension];
    }
    static_assert(sizeof(tensor->op_params) == 64,
                  "canonical-v5 op_params width changed");
    std::memcpy(tensor->op_params, spec.op_params.data(),
                spec.op_params.size());
    return true;
}

bool apply_q8_gemv_tensor_spec(
        ggml_tensor * tensor,
        const qwen_q8_gemv_manifest::tensor_spec & spec) {
    if (tensor == nullptr || spec.view_present) {
        return false;
    }
    tensor->type = static_cast<enum ggml_type>(spec.type_id);
    tensor->op = static_cast<enum ggml_op>(spec.op_id);
    tensor->flags = spec.flags;
    tensor->view_src = nullptr;
    tensor->view_offs = spec.view_offs;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        tensor->ne[dimension] = spec.ne[dimension];
        tensor->nb[dimension] = spec.nb[dimension];
    }
    static_assert(sizeof(tensor->op_params) == 64,
                  "canonical-v5 op_params width changed");
    std::memcpy(tensor->op_params, spec.op_params.data(),
                spec.op_params.size());
    return true;
}

ggml_npu_canonical_node_binding_v1 make_binding(
        const remaining_node & node) {
    ggml_npu_canonical_node_binding_v1 binding = {};
    binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
    binding.graph_node_index = node.graph_node_index;
    std::memcpy(binding.canonical_id, node.canonical_id.data(),
                node.canonical_id.size());
    return binding;
}

struct backend_api {
    ggml_backend_reg_t registry = nullptr;
    ggml_backend_dev_t device = nullptr;
    ggml_backend_t backend = nullptr;
    ggml_backend_npu_audit_begin_v2_fn audit_begin = nullptr;
    ggml_backend_npu_audit_end_v2_fn audit_end = nullptr;
    ggml_backend_npu_canonical_binding_begin_v1_fn binding_begin = nullptr;
    ggml_backend_npu_canonical_binding_bind_v1_fn binding_bind = nullptr;
    ggml_backend_npu_canonical_binding_seal_v1_fn binding_seal = nullptr;

    bool load(const char * path) {
        registry = ggml_backend_load(path);
        if (registry == nullptr) {
            return false;
        }
        device = ggml_backend_reg_dev_get(registry, 0);
        audit_begin = reinterpret_cast<ggml_backend_npu_audit_begin_v2_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_AUDIT_BEGIN_V2_PROC));
        audit_end = reinterpret_cast<ggml_backend_npu_audit_end_v2_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_AUDIT_END_V2_PROC));
        binding_begin = reinterpret_cast<
            ggml_backend_npu_canonical_binding_begin_v1_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
        binding_bind = reinterpret_cast<
            ggml_backend_npu_canonical_binding_bind_v1_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
        binding_seal = reinterpret_cast<
            ggml_backend_npu_canonical_binding_seal_v1_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
        if (device == nullptr || audit_begin == nullptr ||
            audit_end == nullptr || binding_begin == nullptr ||
            binding_bind == nullptr || binding_seal == nullptr) {
            return false;
        }
        backend = ggml_backend_dev_init(device, nullptr);
        return backend != nullptr;
    }

    void close() {
        if (backend != nullptr) {
            ggml_backend_free(backend);
            backend = nullptr;
        }
        if (registry != nullptr) {
            ggml_backend_unload(registry);
            registry = nullptr;
        }
    }
};

npu_exact_tensor_descriptor copy_descriptor(const tensor_spec & spec) {
    npu_exact_tensor_descriptor result = {};
    result.type_id = spec.type_id;
    result.op_id = spec.op_id;
    result.flags = spec.flags;
    result.view_present = spec.view_present;
    result.view_off = spec.view_offs;
    result.ne = spec.ne;
    result.nb = spec.nb;
    result.op_params = spec.op_params;
    return result;
}

npu_exact_profile copy_profile(const remaining_profile & profile) {
    npu_exact_profile result = {};
    result.manifest_profile_id = profile.profile_id;
    result.owner_profile_id = profile.owner_profile_id;
    result.owner = static_cast<npu_exact_owner>(profile.owner_id);
    result.source_count = profile.source_count;
    result.dst = copy_descriptor(profile.dst);
    for (std::size_t index = 0; index < result.sources.size(); ++index) {
        result.sources[index] = copy_descriptor(profile.sources[index]);
    }
    return result;
}

struct metadata_op {
    ggml_tensor * dst = nullptr;
    std::array<ggml_tensor *, 3> sources = {};
    std::array<ggml_tensor *, 4> view_roots = {};
};

metadata_op make_metadata_op(
        ggml_context * context,
        const remaining_profile & profile) {
    metadata_op result = {};
    result.dst = ggml_new_tensor_1d(context, GGML_TYPE_F32, 1);
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        result.sources[index] =
            ggml_new_tensor_1d(context, GGML_TYPE_F32, 1);
    }
    if (profile.dst.view_present) {
        result.view_roots[0] =
            ggml_new_tensor_1d(context, GGML_TYPE_I8, 1);
    }
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        if (profile.sources[index].view_present) {
            result.view_roots[index + 1] =
                ggml_new_tensor_1d(context, GGML_TYPE_I8, 1);
        }
    }
    if (!apply_tensor_spec(result.dst, profile.dst, result.view_roots[0])) {
        return {};
    }
    std::memset(result.dst->src, 0, sizeof(result.dst->src));
    for (std::size_t index = 0; index < profile.source_count; ++index) {
        if (!apply_tensor_spec(
                result.sources[index], profile.sources[index],
                result.view_roots[index + 1])) {
            return {};
        }
        result.dst->src[index] = result.sources[index];
    }
    return result;
}

void apply_names(metadata_op * op, const remaining_node & node) {
    ggml_set_name(op->dst, node.dst_name);
    for (std::size_t index = 0; index < node.source_count; ++index) {
        ggml_set_name(op->sources[index], node.source_names[index]);
    }
}

struct command_expectation {
    std::uint64_t element_count;
    std::uint32_t outer_count;
    std::uint64_t src0_stride;
    std::uint64_t src1_stride;
    std::uint64_t src2_stride;
    std::uint64_t dst_stride;
    std::uint32_t scalar0;
    std::uint64_t dst_view_off;
    std::array<std::uint64_t, 3> source_view_offs;
    std::size_t dst_backing_bytes;
    std::array<std::size_t, 3> source_backing_bytes;
};

// This table is the frozen public-Coprocessor submission contract.  It is
// deliberately independent of the implementation's field derivation: a
// generated-global profile may select a row, but it can never become the
// public local profile or silently alter a stride/window sentinel.
static constexpr std::array<command_expectation, 30>
kExpectedCommands = {{
    {16, 1, 64, 0, 64, 64, 0, 0, {0, 0, 0}, 64, {64, 0, 0}},
    {1, 16, 4, 0, 4, 4, 0, 0, {0, 0, 0}, 64, {64, 0, 0}},
    {6144, 1, 24576, 0, 24576, 24576, 0, 0,
     {0, 0, 0}, 24576, {24576, 0, 0}},
    {1, 16, 4, 0, 64, 4, 0, 0, {0, 0, 0}, 64, {64, 0, 0}},
    {128, 16, 512, 0, 8192, 512, 0, 0,
     {0, 0, 0}, 8192, {8192, 0, 0}},
    {2048, 1, 8192, 0, 8192, 8192, 0, 0,
     {0, 0, 0}, 8192, {8192, 0, 0}},
    {1024, 1, 4096, 0, 4096, 4096, 0x358637bdU, 0,
     {0, 0, 0}, 4096, {4096, 0, 0}},
    {128, 16, 512, 0, 4, 512, 0x358637bdU, 0,
     {0, 0, 0}, 8192, {8192, 0, 0}},
    {1024, 1, 4096, 0, 4096, 4096, 0x358637bdU, 0,
     {0, 0, 0}, 4096, {4096, 0, 0}},
    {256, 8, 2048, 0, 16384, 1024, 0x358637bdU, 0,
     {0, 0, 0}, 8192, {16384, 0, 0}},
    {256, 2, 1024, 0, 2048, 1024, 0x358637bdU, 0,
     {0, 0, 0}, 2048, {2048, 0, 0}},
    {128, 16, 512, 0, 24576, 512, 0x358637bdU, 0,
     {8192, 0, 0}, 8192, {24576, 0, 0}},
    {128, 16, 512, 0, 24576, 512, 0x358637bdU, 0,
     {0, 0, 0}, 8192, {24576, 0, 0}},
    {1, 2048, 512, 0, 65536, 4, 0, 0,
     {0, 0, 0}, 8192, {1048576, 0, 0}},
    {3584, 1, 14336, 14336, 14336, 14336, 0, 0,
     {0, 0, 0}, 14336, {14336, 14336, 0}},
    {6144, 1, 16, 16, 98304, 24576, 0, 0,
     {0, 0, 0}, 24576, {98304, 98304, 0}},
    {18432, 0, 73728, 73728, 0, 73728, 0, 73728,
     {0, 73728, 0}, 73728, {73728, 73728, 0}},
    {18432, 1, 16, 73728, 0, 73728, 0, 0,
     {4, 0, 0}, 73728, {98304, 73728, 0}},
    {262144, 0, 1048576, 1048576, 0, 1048576, 0, 1048576,
     {0, 1048576, 0}, 1048576, {1048576, 1048576, 0}},
    {262144, 1, 512, 1048576, 0, 1048576, 0, 0,
     {0, 0, 0}, 1048576, {1048576, 1048576, 0}},
    {2048, 1, 1024, 0, 0, 8192, 0, 0,
     {0, 0, 0}, 8192, {8192, 0, 0}},
    {2048, 1, 2048, 0, 0, 8192, 0, 0,
     {1024, 0, 0}, 8192, {16384, 0, 0}},
    {4, 6144, 12, 4, 0, 16, 0, 0,
     {0, 0, 0}, 98304, {73728, 24576, 0}},
    {512, 256, 2048, 8, 1024, 1024, 256, 0,
     {0, 0, 0}, 262144, {2048, 8, 262144}},
    {1, 131072, 4, 4096, 2, 2, 256, 0,
     {0, 0, 0}, 262144, {2048, 4096, 262144}},
    {256, 8, 1024, 8192, 0, 1024, 10, 0,
     {0, 0, 0}, 8192, {262144, 8192, 0}},
    {256, 8, 512, 1024, 0, 1024, 0, 0,
     {0, 0, 0}, 8192, {262144, 8192, 0}},
    {256, 8, 1024, 16, 0, 1024, 0, 0,
     {0, 0, 0}, 8192, {8192, 16, 0}},
    {256, 2, 1024, 16, 0, 1024, 0, 0,
     {0, 0, 0}, 2048, {2048, 16, 0}},
    {256, 8, 1024, 1024, 0, 1024, 0x3d800000U, 0,
     {0, 0, 0}, 8192, {8192, 1024, 0}},
}};

bool run_route_tests() {
    static constexpr std::array<std::uint32_t, 30> kExpectedKernels = {
        0x514e0005U, 0x514e0005U, 0x514e0005U, 0x514e0005U,
        0x514e0005U, 0x514e0005U,
        0x514e0011U, 0x514e0011U, 0x514e0011U, 0x514e0011U,
        0x514e0011U, 0x514e0011U, 0x514e0011U, 0x514e0011U,
        0x514e0006U, 0x514e0022U,
        0x514e0007U, 0x514e0007U, 0x514e0007U, 0x514e0007U,
        0x514e0007U, 0x514e0007U, 0x514e0007U,
        0x514e0008U, 0x514e0008U,
        0x514e0009U, 0x514e0009U,
        0x514e000aU, 0x514e000aU,
        0x514e0011U,
    };
    static constexpr std::array<std::uint32_t, 30> kExpectedOperations = {
        15U, 13U, 10U, 7U, 10U, 7U,
        4U, 4U, 4U, 4U, 4U, 5U, 5U, 1U, 2U, 76U,
        34U, 34U, 34U, 34U, 35U, 35U, 22U,
        42U, 42U, 29U, 29U, 48U, 48U, 6U,
    };
    static constexpr std::array<std::uint32_t, 30> kExpectedLocalProfiles = {
        2U, 5U, 4U, 0U, 3U, 1U,
        0U, 1U, 0U, 3U, 2U, 4U, 4U, 0U, 6U, 0U,
        3U, 4U, 5U, 6U, 1U, 2U, 0U, 8U, 7U,
        0U, 1U, 0U, 1U, 0U,
    };
    bool passed = true;
    std::array<std::size_t, 13> owner_profiles = {};
    constexpr std::uint64_t kSrc0Base = 0x0000000310000000ULL;
    constexpr std::uint64_t kSrc1Base = 0x0000000520000000ULL;
    constexpr std::uint64_t kDstBase = 0x0000000730000000ULL;
    for (const auto & generated : qwen_remaining_manifest::kProfiles) {
        npu_exact_profile profile = copy_profile(generated);
        const std::size_t id = generated.profile_id;
        const std::size_t owner =
            static_cast<std::size_t>(generated.owner_id);
        passed &= check(id < kExpectedKernels.size() &&
                            owner < owner_profiles.size() &&
                            npu_exact_finalize_profile(&profile),
                        "generated exact profile did not finalize");
        if (id < kExpectedKernels.size()) {
            passed &= check(
                profile.manifest_profile_id == id &&
                profile.public_kernel_id == kExpectedKernels[id] &&
                profile.public_vector_op == kExpectedOperations[id] &&
                profile.public_local_profile == kExpectedLocalProfiles[id],
                "global profile leaked into public local route");
            const command_expectation & expected = kExpectedCommands[id];
            const npu_macro_identity identity = {
                profile.public_local_profile,
                0x00000011U,
                0x43414e01U,
                0x8102030405060708ULL,
                0xf112131415161718ULL,
                0xe122232425262728ULL,
                0xd132333435363738ULL,
                0xc142434445464748ULL,
            };
            npu_exact_command_contract command = {};
            const std::uint32_t set_slot =
                generated.owner_id ==
                    qwen_remaining_manifest::owner::kSetRows ? 5U : 0U;
            passed &= check(npu_exact_build_command_contract(
                                &profile, &identity, set_slot,
                                &expected.source_backing_bytes,
                                expected.dst_backing_bytes, &command),
                            "exact public command did not materialize");
            passed &= check(
                command.abi_valid == 1U &&
                command.windows_generation_valid == 1U &&
                command.kernel_id == kExpectedKernels[id] &&
                command.vector_op == kExpectedOperations[id] &&
                command.local_profile == kExpectedLocalProfiles[id] &&
                command.command_flags == 0x00000011U &&
                command.context_id == 0x43414e01U &&
                command.capability_epoch == 1U &&
                command.node_count == 1U &&
                command.sequence_id == identity.sequence_id &&
                command.producer_id == identity.producer_id &&
                command.user_tag == identity.user_tag &&
                command.node_hash_lo == identity.node_hash_lo &&
                command.node_hash_hi == identity.node_hash_hi &&
                command.deadline_cycles == 0 &&
                command.scratch_iova == 0 &&
                command.scratch_bytes == 0,
                "canonical/full256 macro identity field mismatch");
            passed &= check(
                command.element_count == expected.element_count &&
                command.outer_count == expected.outer_count &&
                command.dtype == 1U &&
                command.src0_stride == expected.src0_stride &&
                command.src1_stride == expected.src1_stride &&
                command.src2_stride == expected.src2_stride &&
                command.dst_stride == expected.dst_stride &&
                command.scalar0 == expected.scalar0 &&
                command.scalar1 == set_slot &&
                command.rope_position == 0,
                "exact public geometry/stride/scalar field mismatch");
            const bool is_set_rows =
                generated.owner_id ==
                    qwen_remaining_manifest::owner::kSetRows;
            passed &= check(
                command.src0_iova ==
                    kSrc0Base + expected.source_view_offs[0] &&
                command.src1_iova ==
                    (generated.source_count >= 2U ?
                         kSrc1Base + expected.source_view_offs[1] : 0U) &&
                command.src2_iova ==
                    (is_set_rows ?
                         kDstBase + expected.dst_view_off : 0U) &&
                command.dst_iova ==
                    kDstBase + expected.dst_view_off &&
                command.src0_window_base == kSrc0Base &&
                command.src0_window_size ==
                    expected.source_backing_bytes[0] &&
                command.src0_window_perm == 1U &&
                command.src1_window_base ==
                    (generated.source_count >= 2U ? kSrc1Base : 0U) &&
                command.src1_window_size ==
                    expected.source_backing_bytes[1] &&
                command.src1_window_perm == 1U &&
                command.dst_window_base == kDstBase &&
                command.dst_window_size == expected.dst_backing_bytes &&
                command.dst_window_perm == 2U &&
                command.dst_shadow_readable == is_set_rows,
                "raw backing window/IOVA/permission field mismatch");
        }
        if (owner < owner_profiles.size()) {
            ++owner_profiles[owner];
        }
    }
    for (const auto & generated_owner : qwen_remaining_manifest::kOwners) {
        const std::size_t owner =
            static_cast<std::size_t>(generated_owner.owner_id);
        passed &= check(owner < owner_profiles.size() &&
                            owner_profiles[owner] ==
                                generated_owner.profile_count,
                        "owner/profile census mismatch");
    }

    npu_exact_profile unknown =
        copy_profile(qwen_remaining_manifest::kProfiles[0]);
    unknown.manifest_profile_id = 30U;
    passed &= check(!npu_exact_finalize_profile(&unknown),
                    "unknown generated-global profile was accepted");
    npu_exact_profile malformed =
        copy_profile(qwen_remaining_manifest::kProfiles[0]);
    malformed.dst.op_params[63] ^= 1U;
    passed &= check(!npu_exact_finalize_profile(&malformed),
                    "noncanonical full64B op_params were accepted");
    npu_exact_profile ownerless =
        copy_profile(qwen_remaining_manifest::kProfiles[0]);
    ownerless.owner = static_cast<npu_exact_owner>(13U);
    passed &= check(!npu_exact_finalize_profile(&ownerless),
                    "unknown owner silently fell back to a public kernel");

    npu_exact_profile set_profile =
        copy_profile(qwen_remaining_manifest::kProfiles[23]);
    passed &= check(npu_exact_finalize_profile(&set_profile),
                    "SET_ROWS command-negative profile did not finalize");
    npu_macro_identity set_identity = {
        set_profile.public_local_profile,
        0x00000011U,
        0x43414e01U,
        0x8102030405060708ULL,
        0xf112131415161718ULL,
        0xe122232425262728ULL,
        0xd132333435363738ULL,
        0xc142434445464748ULL,
    };
    npu_exact_command_contract rejected_command = {};
    auto short_set_backing =
        kExpectedCommands[23].source_backing_bytes;
    short_set_backing[2] -= 8U;
    passed &= check(!npu_exact_build_command_contract(
                         &set_profile, &set_identity, 5U,
                         &short_set_backing,
                         kExpectedCommands[23].dst_backing_bytes,
                         &rejected_command),
                    "undersized SET_ROWS old-dst backing was accepted");
    passed &= check(!npu_exact_build_command_contract(
                         &set_profile, &set_identity, 256U,
                         &kExpectedCommands[23].source_backing_bytes,
                         kExpectedCommands[23].dst_backing_bytes,
                         &rejected_command),
                    "out-of-range SET_ROWS slot entered a command");
    set_identity.context_id ^= 1U;
    passed &= check(!npu_exact_build_command_contract(
                         &set_profile, &set_identity, 5U,
                         &kExpectedCommands[23].source_backing_bytes,
                         kExpectedCommands[23].dst_backing_bytes,
                         &rejected_command),
                    "noncanonical command context was accepted");

    npu_exact_profile valid =
        copy_profile(qwen_remaining_manifest::kProfiles[0]);
    passed &= check(npu_exact_finalize_profile(&valid),
                    "runner-negative base profile did not finalize");
    npu_macro_identity identity = {
        valid.public_local_profile,
        0x00000011U,
        0x43414e01U,
        0x0102030405060708ULL,
        0x1112131415161718ULL,
        31ULL,
        0x2122232425262728ULL,
        0x3132333435363738ULL,
    };
    std::array<npu_exact_raw_allocation, 3> sources = {};
    npu_exact_private_destination destination = {};
    npu_verilator_exact_result runner_result = {};
    identity.command_flags ^= 1U;
    passed &= check(!npu_verilator_execute_exact(
                         &valid, &identity, &sources,
                         &destination, &runner_result) &&
                        !runner_result.passed,
                    "wrong full256 command identity reached RTL");
    identity.command_flags ^= 1U;
    ++valid.public_local_profile;
    identity.profile_id = valid.public_local_profile;
    passed &= check(!npu_verilator_execute_exact(
                         &valid, &identity, &sources,
                         &destination, &runner_result) &&
                        !runner_result.passed,
                    "wrong public-local profile reached RTL");
    return passed;
}

bool run_manifest_and_matcher_tests(
        backend_api & api,
        ggml_context * context,
        std::array<metadata_op, qwen_remaining_manifest::kProfileCount> * ops,
        std::uint64_t * next_binding_id) {
    if (ops == nullptr || next_binding_id == nullptr) {
        return false;
    }
    bool passed = true;
    for (const auto & profile : qwen_remaining_manifest::kProfiles) {
        metadata_op op = make_metadata_op(context, profile);
        const remaining_node * representative =
            representative_for_profile(profile.profile_id);
        if (op.dst != nullptr && representative != nullptr) {
            apply_names(&op, *representative);
        }
        (*ops)[profile.profile_id] = op;
        passed &= check(op.dst != nullptr && representative != nullptr &&
                            profile.source_count ==
                                representative->source_count &&
                            ggml_backend_dev_supports_op(api.device, op.dst),
                        "one of 30 exact metadata profiles was not admitted");
    }

    std::set<std::array<std::uint8_t, 32>> canonical_ids;
    std::set<std::uint32_t> graph_indices;
    std::array<std::size_t, 13> owner_nodes = {};
    for (const auto & node : qwen_remaining_manifest::kCanonicalNodes) {
        const remaining_profile * profile = profile_by_id(node.profile_id);
        metadata_op * op = profile == nullptr ? nullptr :
            &(*ops)[profile->profile_id];
        if (op != nullptr && op->dst != nullptr) {
            apply_names(op, node);
        }
        canonical_ids.insert(node.canonical_id);
        graph_indices.insert(node.graph_node_index);
        const std::size_t owner = static_cast<std::size_t>(node.owner_id);
        if (owner < owner_nodes.size()) {
            ++owner_nodes[owner];
        }
        const auto binding = make_binding(node);
        passed &= check(
            profile != nullptr && op != nullptr && op->dst != nullptr &&
            profile->owner_id == node.owner_id &&
            profile->source_count == node.source_count &&
            api.binding_begin(api.backend, *next_binding_id, 1) &&
            api.binding_bind(api.backend, *next_binding_id,
                             op->dst, &binding) &&
            api.binding_seal(api.backend, *next_binding_id),
            "one of 433 canonical ID/index/profile/name bindings failed");
        ++*next_binding_id;
    }
    passed &= check(canonical_ids.size() ==
                        qwen_remaining_manifest::kCanonicalNodeCount &&
                    graph_indices.size() ==
                        qwen_remaining_manifest::kCanonicalNodeCount,
                    "canonical ID/index uniqueness census mismatch");
    for (const auto & owner : qwen_remaining_manifest::kOwners) {
        const std::size_t index = static_cast<std::size_t>(owner.owner_id);
        passed &= check(index < owner_nodes.size() &&
                            owner_nodes[index] == owner.node_count,
                        "canonical owner/node census mismatch");
    }

    const remaining_node & node =
        qwen_remaining_manifest::kCanonicalNodes[0];
    metadata_op & op = (*ops)[node.profile_id];
    apply_names(&op, node);
    const auto good_binding = make_binding(node);
    auto bad_identity = good_binding;
    bad_identity.canonical_id[31] ^= 0x80U;
    passed &= check(api.binding_begin(
                        api.backend, (*next_binding_id), 1) &&
                        !api.binding_bind(
                            api.backend, (*next_binding_id),
                            op.dst, &bad_identity),
                    "unknown canonical identity was accepted");
    ++*next_binding_id;
    auto bad_index = good_binding;
    bad_index.graph_node_index =
        std::numeric_limits<std::uint64_t>::max();
    passed &= check(api.binding_begin(
                        api.backend, (*next_binding_id), 1) &&
                        !api.binding_bind(
                            api.backend, (*next_binding_id),
                            op.dst, &bad_index),
                    "canonical graph-index mismatch was accepted");
    ++*next_binding_id;
    passed &= check(api.binding_begin(
                        api.backend, (*next_binding_id), 2) &&
                        api.binding_bind(
                            api.backend, (*next_binding_id),
                            op.dst, &good_binding) &&
                        !api.binding_bind(
                            api.backend, (*next_binding_id),
                            op.dst, &good_binding),
                    "duplicate canonical binding was accepted");
    ++*next_binding_id;

    const enum ggml_type saved_type = op.sources[0]->type;
    op.sources[0]->type = GGML_TYPE_F16;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact source type was admitted");
    op.sources[0]->type = saved_type;
    const enum ggml_op saved_op = op.dst->op;
    op.dst->op = GGML_OP_ADD;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact operation was admitted");
    op.dst->op = saved_op;
    const auto saved_flags = op.dst->flags;
    op.dst->flags ^= GGML_TENSOR_FLAG_COMPUTE;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact tensor flags were admitted");
    op.dst->flags = saved_flags;
    const std::int64_t saved_ne = op.dst->ne[0];
    ++op.dst->ne[0];
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact extent was admitted");
    op.dst->ne[0] = saved_ne;
    const std::size_t saved_nb = op.sources[0]->nb[1];
    ++op.sources[0]->nb[1];
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact stride was admitted");
    op.sources[0]->nb[1] = saved_nb;
    ggml_tensor * saved_view = op.sources[0]->view_src;
    op.sources[0]->view_src = saved_view == nullptr ?
        op.dst : nullptr;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact view presence was admitted");
    op.sources[0]->view_src = saved_view;
    const std::size_t saved_view_off = op.sources[0]->view_offs;
    op.sources[0]->view_offs ^= 8U;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact view offset was admitted");
    op.sources[0]->view_offs = saved_view_off;
    auto * params = reinterpret_cast<std::uint8_t *>(op.dst->op_params);
    params[63] ^= 1U;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong full64B op_params tail was admitted");
    params[63] ^= 1U;
    ggml_set_name(op.dst, "not-a-canonical-v5-name");
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong canonical destination name was admitted");
    apply_names(&op, node);
    ggml_tensor * saved_source = op.dst->src[0];
    op.dst->src[0] = nullptr;
    passed &= check(!ggml_backend_dev_supports_op(api.device, op.dst),
                    "wrong exact arity was admitted");
    op.dst->src[0] = saved_source;

    passed &= check(api.binding_begin(
                        api.backend, (*next_binding_id), 1) &&
                        !api.audit_begin(
                            api.backend, kDispatchBase, 1, 1),
                    "audit accepted a missing canonical binding");
    ++*next_binding_id;
    return passed;
}

bool checked_add(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        rhs > std::numeric_limits<std::uint64_t>::max() - lhs) {
        return false;
    }
    *result = lhs + rhs;
    return true;
}

bool checked_mul(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        (lhs != 0 &&
         rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *result = lhs * rhs;
    return true;
}

std::uint64_t scalar_bytes(std::uint32_t type_id) {
    switch (type_id) {
        case 0U:
        case 24U:
        case 26U:
            return type_id == 24U ? 1U : 4U;
        case 1U:
            return 2U;
        case 27U:
            return 8U;
        default:
            return 0;
    }
}

bool required_root_bytes(
        const tensor_spec & spec,
        std::uint64_t * bytes) {
    if (bytes == nullptr) {
        return false;
    }
    const std::uint64_t width = scalar_bytes(spec.type_id);
    if (width == 0) {
        return false;
    }
    std::uint64_t count = 1;
    for (std::int64_t extent : spec.ne) {
        if (extent < 0 ||
            !checked_mul(count, static_cast<std::uint64_t>(extent),
                         &count)) {
            return false;
        }
    }
    std::uint64_t high = spec.view_offs;
    if (count != 0) {
        for (std::size_t dimension = 0; dimension < 4; ++dimension) {
            std::uint64_t term = 0;
            if (spec.ne[dimension] <= 0 ||
                !checked_mul(
                    static_cast<std::uint64_t>(spec.ne[dimension] - 1),
                    spec.nb[dimension], &term) ||
                !checked_add(high, term, &high)) {
                return false;
            }
        }
        if (!checked_add(high, width, &high)) {
            return false;
        }
    }
    for (std::uint64_t stride : spec.nb) {
        if (stride > high) {
            high = stride;
        }
    }
    *bytes = high;
    return true;
}

struct mapped_tensor {
    ggml_tensor * tensor = nullptr;
    void * storage = nullptr;
    std::size_t storage_bytes = 0;
    ggml_backend_buffer_t buffer = nullptr;

    bool allocate(backend_api & api, ggml_tensor * root) {
        tensor = root;
        const std::size_t logical_bytes =
            root == nullptr ? 0 : ggml_nbytes(root);
        // Real scheduler graphs legitimately leave a zero-cardinality root
        // without a backing allocation.  Preserve that exact null/zero
        // contract in the directed fixture instead of fabricating storage.
        if (root != nullptr && logical_bytes == 0) {
            return root->data == nullptr;
        }
        if (logical_bytes >
                std::numeric_limits<std::size_t>::max() -
                    (kAlignment - 1)) {
            return false;
        }
        storage_bytes =
            (logical_bytes + kAlignment - 1) & ~(kAlignment - 1);
        storage = std::aligned_alloc(kAlignment, storage_bytes);
        if (storage == nullptr) {
            return false;
        }
        buffer = ggml_backend_dev_buffer_from_host_ptr(
            api.device, storage, storage_bytes, logical_bytes);
        return buffer != nullptr &&
               ggml_backend_tensor_alloc(buffer, root, storage) ==
                   GGML_STATUS_SUCCESS;
    }

    void release() {
        if (buffer != nullptr) {
            ggml_backend_buffer_free(buffer);
            buffer = nullptr;
        }
        std::free(storage);
        storage = nullptr;
        tensor = nullptr;
        storage_bytes = 0;
    }
};

ggml_tensor * make_byte_root(
        ggml_context * context,
        std::uint64_t bytes) {
    if (context == nullptr || bytes == 0 ||
        bytes > static_cast<std::uint64_t>(
                    std::numeric_limits<std::int64_t>::max())) {
        return nullptr;
    }
    return ggml_new_tensor_1d(
        context, GGML_TYPE_I8, static_cast<std::int64_t>(bytes));
}

void store_u64_le(std::uint8_t * destination, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte) {
        destination[byte] =
            static_cast<std::uint8_t>(value >> (8 * byte));
    }
}

void store_u32_le(std::uint8_t * destination, std::uint32_t value) {
    for (std::size_t byte = 0; byte < 4; ++byte) {
        destination[byte] =
            static_cast<std::uint8_t>(value >> (8 * byte));
    }
}

std::uint8_t view_pattern(std::size_t offset) {
    return static_cast<std::uint8_t>(
        ((offset * 29U) ^ (offset >> 8U) ^ (offset >> 12U) ^ 0x5aU) &
        0xffU);
}

std::uint32_t load_u32_le(const std::uint8_t * source) {
    std::uint32_t value = 0;
    for (std::size_t byte = 0; byte < 4; ++byte) {
        value |= static_cast<std::uint32_t>(source[byte]) << (8 * byte);
    }
    return value;
}

struct execution_fixture {
    const remaining_profile * profile = nullptr;
    const remaining_node * node = nullptr;
    ggml_context * context = nullptr;
    ggml_tensor * dst = nullptr;
    std::array<ggml_tensor *, 3> sources = {};
    ggml_tensor * dst_root = nullptr;
    std::array<ggml_tensor *, 3> source_roots = {};
    ggml_cgraph * graph = nullptr;
    std::vector<mapped_tensor> mappings;

    bool create(backend_api & api, std::uint32_t profile_id) {
        profile = profile_by_id(profile_id);
        node = representative_for_profile(profile_id);
        if (profile == nullptr || node == nullptr) {
            return false;
        }
        ggml_init_params parameters = {4 * 1024 * 1024, nullptr, true};
        context = ggml_init(parameters);
        if (context == nullptr) {
            return false;
        }
        dst = ggml_new_tensor_1d(context, GGML_TYPE_F32, 1);
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            sources[index] =
                ggml_new_tensor_1d(context, GGML_TYPE_F32, 1);
        }
        if (dst == nullptr) {
            return false;
        }
        dst->op = static_cast<enum ggml_op>(profile->dst.op_id);
        dst->flags = profile->dst.flags;
        std::memset(dst->src, 0, sizeof(dst->src));
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            if (sources[index] == nullptr) {
                return false;
            }
            dst->src[index] = sources[index];
        }
        graph = ggml_new_graph(context);
        ggml_build_forward_expand(graph, dst);
        if (graph == nullptr || ggml_graph_n_nodes(graph) != 1 ||
            ggml_graph_node(graph, 0) != dst) {
            return false;
        }

        const bool alias_old_dst =
            profile->owner_id == qwen_remaining_manifest::owner::kCpy ||
            profile->owner_id == qwen_remaining_manifest::owner::kSetRows;
        const std::size_t alias_source =
            profile->owner_id == qwen_remaining_manifest::owner::kCpy ?
                1U : 2U;
        if (alias_old_dst) {
            if (alias_source >= profile->source_count) {
                return false;
            }
            if (!profile->sources[alias_source].view_present) {
                source_roots[alias_source] = sources[alias_source];
                dst_root = source_roots[alias_source];
            } else {
                std::uint64_t dst_bytes = 0;
                std::uint64_t source_bytes = 0;
                if (!required_root_bytes(profile->dst, &dst_bytes) ||
                    !required_root_bytes(
                        profile->sources[alias_source], &source_bytes)) {
                    return false;
                }
                const std::uint64_t common_bytes =
                    dst_bytes > source_bytes ? dst_bytes : source_bytes;
                dst_root = make_byte_root(context, common_bytes);
                source_roots[alias_source] = dst_root;
            }
        }

        if (profile->dst.view_present && dst_root == nullptr) {
            std::uint64_t bytes = 0;
            if (!required_root_bytes(profile->dst, &bytes)) {
                return false;
            }
            dst_root = make_byte_root(context, bytes);
        } else if (!profile->dst.view_present) {
            dst_root = dst;
        }
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            if (source_roots[index] != nullptr) {
                continue;
            }
            if (profile->sources[index].view_present) {
                std::uint64_t bytes = 0;
                if (!required_root_bytes(profile->sources[index], &bytes)) {
                    return false;
                }
                source_roots[index] = make_byte_root(context, bytes);
            } else {
                source_roots[index] = sources[index];
            }
        }
        if (dst_root == nullptr ||
            !apply_tensor_spec(
                dst, profile->dst,
                profile->dst.view_present ? dst_root : nullptr)) {
            return false;
        }
        std::memset(dst->src, 0, sizeof(dst->src));
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            if (source_roots[index] == nullptr ||
                !apply_tensor_spec(
                    sources[index], profile->sources[index],
                    profile->sources[index].view_present ?
                        source_roots[index] : nullptr)) {
                return false;
            }
            dst->src[index] = sources[index];
        }
        ggml_set_name(dst, node->dst_name);
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            ggml_set_name(sources[index], node->source_names[index]);
        }
        if (!ggml_backend_dev_supports_op(api.device, dst)) {
            return false;
        }

        std::set<ggml_tensor *> unique_roots;
        unique_roots.insert(dst_root);
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            unique_roots.insert(source_roots[index]);
        }
        mappings.reserve(unique_roots.size());
        for (ggml_tensor * root : unique_roots) {
            mappings.emplace_back();
            if (!mappings.back().allocate(api, root)) {
                return false;
            }
        }
        if (profile->dst.view_present &&
            ggml_backend_view_init(dst) != GGML_STATUS_SUCCESS) {
            return false;
        }
        for (std::size_t index = 0; index < profile->source_count; ++index) {
            if (profile->sources[index].view_present &&
                ggml_backend_view_init(sources[index]) !=
                    GGML_STATUS_SUCCESS) {
                return false;
            }
        }
        return dst->data != nullptr;
    }

    void reset_raw() {
        for (auto & mapping : mappings) {
            if (mapping.storage_bytes != 0) {
                std::memset(mapping.storage,
                            mapping.tensor == dst_root ? 0xa5 : 0x00,
                            mapping.storage_bytes);
                if ((profile->profile_id == 17U ||
                     profile->profile_id == 21U) &&
                    mapping.tensor == source_roots[0]) {
                    auto * bytes =
                        static_cast<std::uint8_t *>(mapping.storage);
                    for (std::size_t offset = 0;
                         offset < mapping.storage_bytes; ++offset) {
                        bytes[offset] = view_pattern(offset);
                    }
                }
            }
        }
    }

    bool bind_and_begin(
            backend_api & api,
            std::uint64_t binding_id,
            std::uint64_t dispatch_id) const {
        const auto binding = make_binding(*node);
        return api.binding_begin(api.backend, binding_id, 1) &&
               api.binding_bind(
                   api.backend, binding_id, dst, &binding) &&
               api.binding_seal(api.backend, binding_id) &&
               api.audit_begin(api.backend, dispatch_id, 1, 1);
    }

    void release() {
        for (auto iterator = mappings.rbegin();
             iterator != mappings.rend(); ++iterator) {
            iterator->release();
        }
        mappings.clear();
        if (context != nullptr) {
            ggml_free(context);
            context = nullptr;
        }
    }
};

bool exact_success_audit(
        const ggml_npu_audit_snapshot_v2 & snapshot,
        const npu_exact_profile & profile) {
    bool passed = true;
    passed &= check(snapshot.abi_version ==
                        GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "execution audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                        snapshot.assigned_to_npu == 1 &&
                        snapshot.required_enqueued == 1 &&
                        snapshot.required_successfully_covered == 1 &&
                        snapshot.executed_by_verilator == 1,
                    "REQUIRED execution ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                        snapshot.commands_terminal_success == 1 &&
                        snapshot.commands_terminal_failure == 0,
                    "macro terminal ledger mismatch");
    passed &= check(snapshot.gmem_read_bytes ==
                            profile.expected_read_bytes &&
                        snapshot.gmem_write_bytes ==
                            profile.expected_write_bytes &&
                        snapshot.vector_elements ==
                            profile.expected_elements,
                    "raw GMEM/work counter mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                        snapshot.cpu_fallback_attempts == 0 &&
                        snapshot.host_tensor_ops == 0,
                    "unsupported/fallback/host arithmetic detected");
    passed &= check(snapshot.coverage_missing == 0 &&
                        snapshot.coverage_duplicate == 0 &&
                        snapshot.coverage_hash_mismatch == 0 &&
                        snapshot.completion_identity_mismatch == 0,
                    "canonical/full256 coverage ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                        snapshot.gmem_errors == 0 &&
                        snapshot.timeout_errors == 0 &&
                        snapshot.rtl_cycles > 0,
                    "RTL completion status mismatch");
    return passed;
}

bool check_literal_output(const execution_fixture & fixture) {
    if (fixture.dst == nullptr || fixture.dst->data == nullptr ||
        fixture.profile == nullptr) {
        return false;
    }
    const auto * bytes =
        static_cast<const std::uint8_t *>(fixture.dst->data);
    const std::size_t byte_count = ggml_nbytes(fixture.dst);
    if (fixture.profile->profile_id == 17U ||
        fixture.profile->profile_id == 21U) {
        const tensor_spec & source = fixture.profile->sources[0];
        bool match = (byte_count & 3U) == 0 && source.ne[0] > 0;
        const std::size_t ne0 = static_cast<std::size_t>(source.ne[0]);
        for (std::size_t offset = 0; match && offset < byte_count;
             ++offset) {
            const std::size_t element = offset >> 2U;
            const std::size_t byte = offset & 3U;
            const std::size_t i0 = element % ne0;
            const std::size_t i1 = element / ne0;
            const std::size_t source_offset =
                static_cast<std::size_t>(source.view_offs) +
                i0 * static_cast<std::size_t>(source.nb[0]) +
                i1 * static_cast<std::size_t>(source.nb[1]) + byte;
            const std::uint8_t expected = view_pattern(source_offset);
            match &= bytes[offset] == expected;
            if (!match) {
                std::fprintf(
                    stderr,
                    "[NPU-BACKEND-REMAINING][ORACLE-DIAG] "
                    "profile=%u offset=%zu source_offset=%zu "
                    "expected=0x%02x actual=0x%02x\n",
                    fixture.profile->profile_id, offset, source_offset,
                    expected, bytes[offset]);
            }
        }
        return match;
    }
    if (fixture.profile->profile_id == 0U ||
        fixture.profile->profile_id == 29U) {
        const std::uint32_t expected =
            fixture.profile->profile_id == 0U ?
                0x3f317218U : 0x3b800000U;
        bool match = (byte_count & 3U) == 0;
        for (std::size_t offset = 0; offset < byte_count; offset += 4) {
            match &= load_u32_le(bytes + offset) == expected;
            if (!match) {
                std::fprintf(
                    stderr,
                    "[NPU-BACKEND-REMAINING][ORACLE-DIAG] "
                    "profile=%u offset=%zu expected=0x%08x actual=0x%08x\n",
                    fixture.profile->profile_id, offset, expected,
                    load_u32_le(bytes + offset));
                break;
            }
        }
        return match;
    }
    if (fixture.profile->profile_id == 23U) {
        const auto * root = static_cast<const std::uint8_t *>(
            fixture.dst_root->data);
        const std::size_t root_bytes = ggml_nbytes(fixture.dst_root);
        bool match = root != nullptr && root_bytes == 262144U;
        for (std::size_t offset = 0; offset < root_bytes; ++offset) {
            match &= root[offset] == (offset < 1024U ? 0x00U : 0xa5U);
            if (!match) {
                std::fprintf(
                    stderr,
                    "[NPU-BACKEND-REMAINING][ORACLE-DIAG] "
                    "profile=23 offset=%zu expected=0x%02x actual=0x%02x\n",
                    offset, offset < 1024U ? 0x00U : 0xa5U,
                    root == nullptr ? 0xffU : root[offset]);
                break;
            }
        }
        return match;
    }
    bool match = true;
    for (std::size_t offset = 0; offset < byte_count; ++offset) {
        match &= bytes[offset] == 0U;
        if (!match) {
            std::fprintf(
                stderr,
                "[NPU-BACKEND-REMAINING][ORACLE-DIAG] "
                "profile=%u offset=%zu expected=0x00 actual=0x%02x\n",
                fixture.profile->profile_id, offset, bytes[offset]);
            break;
        }
    }
    return match;
}

bool run_positive_graphs(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    bool passed = true;
    for (std::uint32_t profile_id : kExecutionProfiles) {
        execution_fixture fixture;
        const bool created = fixture.create(api, profile_id);
        passed &= check(created,
                        "physical-family ggml graph fixture creation failed");
        if (!created) {
            fixture.release();
            continue;
        }
        fixture.reset_raw();
        npu_exact_profile profile = copy_profile(*fixture.profile);
        passed &= check(npu_exact_finalize_profile(&profile),
                        "execution profile did not finalize");
        const std::uint64_t binding_id = (*next_binding_id)++;
        const std::uint64_t dispatch_id = (*next_dispatch_id)++;
        passed &= check(fixture.bind_and_begin(
                            api, binding_id, dispatch_id),
                        "physical-family bind/audit begin failed");
        passed &= check(ggml_backend_graph_compute(
                            api.backend, fixture.graph) ==
                            GGML_STATUS_SUCCESS,
                        "physical-family production graph dispatch failed");
        ggml_npu_audit_snapshot_v2 snapshot = {};
        passed &= check(api.audit_end(
                            api.backend, dispatch_id, &snapshot),
                        "physical-family exact audit did not close");
        passed &= exact_success_audit(snapshot, profile);
        passed &= check(check_literal_output(fixture),
                        "pre-frozen standalone raw output oracle mismatch");
        if (passed) {
            std::printf(
                "[NPU-BACKEND-REMAINING][PASS-GRAPH] "
                "profile=%u kernel=0x%08x op=%u local=%u "
                "read=%llu write=%llu work=%llu identity=full256 "
                "private_commit=success-only host_float=0\n",
                profile.manifest_profile_id, profile.public_kernel_id,
                profile.public_vector_op, profile.public_local_profile,
                static_cast<unsigned long long>(
                    profile.expected_read_bytes),
                static_cast<unsigned long long>(
                    profile.expected_write_bytes),
                static_cast<unsigned long long>(profile.expected_elements));
        }
        fixture.release();
    }
    return passed;
}

bool run_inplace_graphs(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    bool passed = true;
    constexpr std::array<std::uint32_t, 4> kInplaceProfiles = {
        0U, 8U, 27U, 29U,
    };
    for (std::uint32_t profile_id : kInplaceProfiles) {
        bool case_passed = true;
        execution_fixture fixture;
        const bool created = fixture.create(api, profile_id);
        case_passed &= check(created, "in-place fixture creation failed");
        if (!created) {
            fixture.release();
            passed = false;
            continue;
        }
        fixture.reset_raw();
        const bool layout_ready =
            fixture.sources[0] != nullptr && fixture.dst_root != nullptr &&
            fixture.source_roots[0] != nullptr &&
            fixture.source_roots[0]->data != fixture.dst_root->data &&
            ggml_nbytes(fixture.sources[0]) == ggml_nbytes(fixture.dst) &&
            ggml_nbytes(fixture.source_roots[0]) ==
                ggml_nbytes(fixture.dst_root);
        case_passed &= check(
            layout_ready, "in-place source/destination layout mismatch");
        if (!layout_ready) {
            fixture.release();
            passed = false;
            continue;
        }
        std::memset(fixture.source_roots[0]->data, 0x7f,
                    ggml_nbytes(fixture.source_roots[0]));
        std::memset(
            fixture.dst_root->data, 0, ggml_nbytes(fixture.dst_root));
        void * saved_source_data = fixture.sources[0]->data;
        fixture.sources[0]->data = fixture.dst_root->data;

        npu_exact_profile profile = copy_profile(*fixture.profile);
        case_passed &= check(npu_exact_finalize_profile(&profile),
                             "in-place profile did not finalize");
        const std::uint64_t binding_id = (*next_binding_id)++;
        const std::uint64_t dispatch_id = (*next_dispatch_id)++;
        const bool begun = fixture.bind_and_begin(
            api, binding_id, dispatch_id);
        case_passed &= check(begun, "in-place bind/audit begin failed");
        enum ggml_status compute_status = GGML_STATUS_FAILED;
        if (begun) {
            compute_status = ggml_backend_graph_compute(
                api.backend, fixture.graph);
        }
        fixture.sources[0]->data = saved_source_data;
        case_passed &= check(compute_status == GGML_STATUS_SUCCESS,
                             "in-place production graph dispatch failed");

        ggml_npu_audit_snapshot_v2 snapshot = {};
        const bool closed = begun && api.audit_end(
            api.backend, dispatch_id, &snapshot);
        case_passed &= check(closed, "in-place exact audit did not close");
        if (closed) {
            case_passed &= exact_success_audit(snapshot, profile);
        }
        case_passed &= check(check_literal_output(fixture),
                             "in-place raw output oracle mismatch");
        if (case_passed) {
            const char * owner = profile_id == 0U ? "unary" :
                (profile_id == 8U ? "rms-norm" :
                 (profile_id == 27U ? "rope" : "softmax"));
            std::printf(
                "[NPU-BACKEND-REMAINING][PASS-INPLACE] profile=%u "
                "owner=%s alias=src0-dst-exact layout=same "
                "private_commit=success-only host_float=0\n",
                profile_id, owner);
        }
        fixture.release();
        passed &= case_passed;
    }
    return passed;
}

int run_q8_portal_max_graph(const char * backend_path) {
    checks = 0;
    constexpr std::uint32_t kProfileId = 9U;
    constexpr std::uint32_t kK = 1024U;
    constexpr std::uint32_t kM = 248320U;
    constexpr std::uint32_t kBlocksPerRow = 32U;
    constexpr std::size_t kActivationBytes = 4096U;
    constexpr std::size_t kWeightRowBytes = 1088U;
    constexpr std::size_t kWeightBytes = 270172160U;
    constexpr std::size_t kDstBytes = 993280U;
    constexpr std::uint64_t kRawReadBytes = 4104U;
    constexpr std::uint64_t kPortalRequestGroups = 1986560U;
    constexpr std::uint64_t kPortalBlocks = 7946240U;
    constexpr std::uint64_t kPortalBytes = 270172160U;
    constexpr std::uint64_t kQ8Macs = 254279680U;
    constexpr std::array<std::uint32_t, 4> kActivationPattern = {
        0x3f800000U, 0xbf800000U, 0x3f000000U, 0xbe800000U,
    };

    const qwen_q8_gemv_manifest::profile * profile = nullptr;
    const qwen_q8_gemv_manifest::canonical_node * node = nullptr;
    std::size_t node_matches = 0;
    for (const auto & candidate : qwen_q8_gemv_manifest::kProfiles) {
        if (candidate.profile_id == kProfileId) {
            profile = &candidate;
        }
    }
    for (const auto & candidate : qwen_q8_gemv_manifest::kCanonicalNodes) {
        if (candidate.profile_id == kProfileId) {
            node = &candidate;
            ++node_matches;
        }
    }
    bool passed = check(
        profile != nullptr && node != nullptr && node_matches == 1U &&
            profile->k == kK && profile->m == kM &&
            profile->block_count == kBlocksPerRow &&
            profile->activation_bytes == kActivationBytes &&
            profile->weight_row_stride == kWeightRowBytes &&
            profile->weight_bytes == kWeightBytes &&
            profile->dst_bytes == kDstBytes &&
            ((static_cast<std::uint64_t>(profile->m) + 3U) / 4U) *
                    profile->block_count == kPortalRequestGroups &&
            static_cast<std::uint64_t>(profile->m) *
                    profile->block_count == kPortalBlocks &&
            profile->weight_bytes == kPortalBytes &&
            static_cast<std::uint64_t>(profile->m) * profile->k == kQ8Macs,
        "Q8 portal max generated profile/canonical identity mismatch");
    if (!passed) {
        return 74;
    }

    backend_api api;
    if (!check(api.load(backend_path),
               "Q8 portal max dynamic backend/API load failed")) {
        api.close();
        return 75;
    }
    ggml_init_params parameters = {4U * 1024U * 1024U, nullptr, true};
    ggml_context * context = ggml_init(parameters);
    void * activation_storage =
        std::aligned_alloc(kAlignment, kActivationBytes);
    void * weight_storage = std::aligned_alloc(kAlignment, kWeightBytes);
    void * dst_storage = std::aligned_alloc(kAlignment, kDstBytes);
    ggml_backend_buffer_t activation_buffer = nullptr;
    ggml_backend_buffer_t weight_buffer = nullptr;
    ggml_backend_buffer_t dst_buffer = nullptr;
    auto cleanup = [&]() {
        if (activation_buffer != nullptr) {
            ggml_backend_buffer_free(activation_buffer);
        }
        if (weight_buffer != nullptr) {
            ggml_backend_buffer_free(weight_buffer);
        }
        if (dst_buffer != nullptr) {
            ggml_backend_buffer_free(dst_buffer);
        }
        if (context != nullptr) {
            ggml_free(context);
        }
        std::free(activation_storage);
        std::free(weight_storage);
        std::free(dst_storage);
        api.close();
    };
    passed &= check(
        context != nullptr && activation_storage != nullptr &&
            weight_storage != nullptr && dst_storage != nullptr,
        "Q8 portal max context/raw allocation failed");
    if (!passed) {
        cleanup();
        return 76;
    }

    ggml_tensor * weights =
        ggml_new_tensor_2d(context, GGML_TYPE_Q8_0, kK, kM);
    ggml_tensor * activation =
        ggml_new_tensor_2d(context, GGML_TYPE_F32, kK, 1);
    ggml_tensor * output = ggml_mul_mat(context, weights, activation);
    passed &= check(
        weights != nullptr && activation != nullptr && output != nullptr,
        "Q8 portal max GGML tensor construction failed");
    if (passed) {
        ggml_set_name(weights, node->weight_name);
        ggml_set_name(activation, node->activation_name);
        ggml_set_name(output, node->dst_name);
    }
    ggml_cgraph * graph = passed ? ggml_new_graph(context) : nullptr;
    if (graph != nullptr) {
        ggml_build_forward_expand(graph, output);
    }
    passed &= check(
        graph != nullptr && ggml_graph_n_nodes(graph) == 1 &&
            ggml_graph_node(graph, 0) == output &&
            apply_q8_gemv_tensor_spec(weights, profile->weight) &&
            apply_q8_gemv_tensor_spec(activation, profile->activation) &&
            apply_q8_gemv_tensor_spec(output, profile->dst) &&
            output->src[0] == weights && output->src[1] == activation &&
            ggml_nbytes(weights) == kWeightBytes &&
            ggml_nbytes(activation) == kActivationBytes &&
            ggml_nbytes(output) == kDstBytes &&
            ggml_backend_dev_supports_op(api.device, output),
        "Q8 portal max exact GGML graph was not admitted");
    if (!passed) {
        cleanup();
        return 77;
    }

    activation_buffer = ggml_backend_dev_buffer_from_host_ptr(
        api.device, activation_storage, kActivationBytes, kActivationBytes);
    weight_buffer = ggml_backend_dev_buffer_from_host_ptr(
        api.device, weight_storage, kWeightBytes, kWeightBytes);
    dst_buffer = ggml_backend_dev_buffer_from_host_ptr(
        api.device, dst_storage, kDstBytes, kDstBytes);
    passed &= check(
        activation_buffer != nullptr && weight_buffer != nullptr &&
            dst_buffer != nullptr &&
            ggml_backend_tensor_alloc(
                activation_buffer, activation, activation_storage) ==
                GGML_STATUS_SUCCESS &&
            ggml_backend_tensor_alloc(
                weight_buffer, weights, weight_storage) ==
                GGML_STATUS_SUCCESS &&
            ggml_backend_tensor_alloc(dst_buffer, output, dst_storage) ==
                GGML_STATUS_SUCCESS,
        "Q8 portal max raw backing attachment failed");
    if (!passed) {
        cleanup();
        return 78;
    }

    auto * activation_raw =
        static_cast<std::uint8_t *>(activation_storage);
    auto * weight_raw = static_cast<std::uint8_t *>(weight_storage);
    auto * dst_raw = static_cast<std::uint8_t *>(dst_storage);
    for (std::size_t element = 0; element < kK; ++element) {
        store_u32_le(
            activation_raw + element * 4U,
            kActivationPattern[element % kActivationPattern.size()]);
    }
    std::memset(weight_raw, 0, kWeightBytes);
    for (std::size_t block = 0; block < kPortalBlocks; ++block) {
        // Frozen raw-only portal fixture: fp16 scale=1.0 and all 32 signed
        // q8 payload bytes zero.  This still traverses the real quantizer,
        // SIMD dot, scale, accumulator and writeback states; the pre-frozen
        // raw F32 oracle for every row is +0 (0x00000000).
        weight_raw[block * 34U] = 0x00U;
        weight_raw[block * 34U + 1U] = 0x3cU;
    }
    std::memset(dst_raw, 0xa5, kDstBytes);

    ggml_npu_canonical_node_binding_v1 binding = {};
    binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
    binding.graph_node_index = node->graph_node_index;
    std::memcpy(binding.canonical_id, node->canonical_id.data(),
                node->canonical_id.size());
    constexpr std::uint64_t kBindingId = 0x5138504f5254414cULL;
    constexpr std::uint64_t kDispatchId = 0x51384d4158504552ULL;
    passed &= check(
        api.binding_begin(api.backend, kBindingId, 1U) &&
            api.binding_bind(api.backend, kBindingId, output, &binding) &&
            api.binding_seal(api.backend, kBindingId) &&
            api.audit_begin(api.backend, kDispatchId, 1U, 1U),
        "Q8 portal max canonical binding/audit begin failed");
    if (!passed) {
        cleanup();
        return 79;
    }

    const auto wall_begin = std::chrono::steady_clock::now();
    const enum ggml_status compute_status =
        ggml_backend_graph_compute(api.backend, graph);
    const auto wall_end = std::chrono::steady_clock::now();
    ggml_npu_audit_snapshot_v2 snapshot = {};
    const bool audit_closed =
        api.audit_end(api.backend, kDispatchId, &snapshot);
    const std::uint64_t wall_us = static_cast<std::uint64_t>(
        std::chrono::duration_cast<std::chrono::microseconds>(
            wall_end - wall_begin).count());
    passed &= check(
        compute_status == GGML_STATUS_SUCCESS && audit_closed &&
            snapshot.required_seen == 1U && snapshot.assigned_to_npu == 1U &&
            snapshot.required_enqueued == 1U &&
            snapshot.required_successfully_covered == 1U &&
            snapshot.executed_by_verilator == 1U &&
            snapshot.commands_accepted == 1U &&
            snapshot.commands_terminal_success == 1U &&
            snapshot.commands_terminal_failure == 0U &&
            snapshot.unsupported_required == 0U &&
            snapshot.cpu_fallback_attempts == 0U &&
            snapshot.host_tensor_ops == 0U &&
            snapshot.coverage_missing == 0U &&
            snapshot.coverage_duplicate == 0U &&
            snapshot.coverage_hash_mismatch == 0U &&
            snapshot.completion_identity_mismatch == 0U &&
            snapshot.rtl_failures == 0U && snapshot.gmem_errors == 0U &&
            snapshot.timeout_errors == 0U && snapshot.rtl_cycles > 0U &&
            snapshot.gmem_read_bytes == kRawReadBytes &&
            snapshot.gmem_write_bytes == kDstBytes &&
            snapshot.vector_elements == kM,
        "Q8 portal max production/audit counter mismatch");

    std::size_t oracle_rows = 0;
    for (std::size_t row = 0; row < kM; ++row) {
        oracle_rows += load_u32_le(dst_raw + row * 4U) == 0x00000000U;
    }
    passed &= check(
        oracle_rows == kM,
        "Q8 portal max pre-frozen raw output oracle mismatch");
    if (passed) {
        std::printf(
            "[NPU-BACKEND-Q8-PORTAL-MAX][PASS] "
            "graph=real-ggml_mul_mat profile=9 M=248320 K=1024 B=32 "
            "system_transport=1 cpu_config=30 cpu_tensor=31 "
            "cpu_terminals=31 cpu_commits=30/1 public=1/1 required=1/1 "
            "raw_read=4104 raw_write=993280 q8_macs=254279680 "
            "elements=248320 portal_requests=1986560 "
            "portal_responses=1986560 portal_blocks=7946240 "
            "portal_bytes=270172160 raw_copy_bytes=270172160 "
            "oracle_zero=%zu/248320 rtl_cycles=%llu wall_us=%llu "
            "cpu_fallback_attempts=0 host_tensor_arithmetic=0\n",
            oracle_rows,
            static_cast<unsigned long long>(snapshot.rtl_cycles),
            static_cast<unsigned long long>(wall_us));
    }
    cleanup();
    return passed ? 0 : 80;
}

bool run_execution_negatives(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    bool passed = true;

    execution_fixture alias_fixture;
    if (!check(alias_fixture.create(api, 0U),
               "alias-negative fixture creation failed")) {
        alias_fixture.release();
        return false;
    }
    alias_fixture.reset_raw();
    void * saved_source_data = alias_fixture.sources[0]->data;
    alias_fixture.sources[0]->data =
        static_cast<std::uint8_t *>(alias_fixture.dst_root->data) + 4U;
    const std::uint64_t alias_dispatch = (*next_dispatch_id)++;
    passed &= check(alias_fixture.bind_and_begin(
                        api, (*next_binding_id)++, alias_dispatch),
                    "alias-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, alias_fixture.graph) ==
                        GGML_STATUS_FAILED,
                    "overlapping source/destination allocation was accepted");
    alias_fixture.sources[0]->data = saved_source_data;
    ggml_npu_audit_snapshot_v2 alias_snapshot = {};
    passed &= check(!api.audit_end(
                        api.backend, alias_dispatch, &alias_snapshot) &&
                        alias_snapshot.required_enqueued == 0 &&
                        alias_snapshot.required_successfully_covered == 0 &&
                        alias_snapshot.executed_by_verilator == 0 &&
                        alias_snapshot.commands_accepted == 0 &&
                        alias_snapshot.commands_terminal_success == 0 &&
                        alias_snapshot.commands_terminal_failure == 0 &&
                        alias_snapshot.gmem_read_bytes == 0 &&
                        alias_snapshot.gmem_write_bytes == 0 &&
                        alias_snapshot.vector_elements == 0 &&
                        alias_snapshot.rtl_cycles == 0 &&
                        alias_snapshot.coverage_missing == 1 &&
                        alias_snapshot.rtl_failures == 1,
                    "alias rejection did not precede REQUIRED enqueue");
    const auto * alias_dst = static_cast<const std::uint8_t *>(
        alias_fixture.dst_root->data);
    bool alias_poison = true;
    for (std::size_t index = 0;
         index < ggml_nbytes(alias_fixture.dst_root); ++index) {
        alias_poison &= alias_dst[index] == 0xa5U;
    }
    passed &= check(alias_poison,
                    "alias failure published destination bytes");
    alias_fixture.release();

    execution_fixture owner_alias_fixture;
    if (!check(owner_alias_fixture.create(api, 14U),
               "owner-alias-negative fixture creation failed")) {
        owner_alias_fixture.release();
        return false;
    }
    owner_alias_fixture.reset_raw();
    void * saved_owner_source_data = owner_alias_fixture.sources[0]->data;
    owner_alias_fixture.sources[0]->data =
        owner_alias_fixture.dst_root->data;
    const std::uint64_t owner_alias_dispatch = (*next_dispatch_id)++;
    passed &= check(owner_alias_fixture.bind_and_begin(
                        api, (*next_binding_id)++, owner_alias_dispatch),
                    "owner-alias-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, owner_alias_fixture.graph) ==
                        GGML_STATUS_FAILED,
                    "non-inplace owner exact destination alias was accepted");
    owner_alias_fixture.sources[0]->data = saved_owner_source_data;
    ggml_npu_audit_snapshot_v2 owner_alias_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, owner_alias_dispatch,
                        &owner_alias_snapshot) &&
                        owner_alias_snapshot.required_enqueued == 0 &&
                        owner_alias_snapshot.required_successfully_covered == 0 &&
                        owner_alias_snapshot.executed_by_verilator == 0 &&
                        owner_alias_snapshot.commands_accepted == 0 &&
                        owner_alias_snapshot.commands_terminal_success == 0 &&
                        owner_alias_snapshot.commands_terminal_failure == 0 &&
                        owner_alias_snapshot.gmem_read_bytes == 0 &&
                        owner_alias_snapshot.gmem_write_bytes == 0 &&
                        owner_alias_snapshot.vector_elements == 0 &&
                        owner_alias_snapshot.rtl_cycles == 0 &&
                        owner_alias_snapshot.coverage_missing == 1 &&
                        owner_alias_snapshot.rtl_failures == 1,
                    "owner alias rejection did not precede REQUIRED enqueue");
    const auto * owner_alias_dst = static_cast<const std::uint8_t *>(
        owner_alias_fixture.dst_root->data);
    bool owner_alias_poison = true;
    for (std::size_t index = 0;
         index < ggml_nbytes(owner_alias_fixture.dst_root); ++index) {
        owner_alias_poison &= owner_alias_dst[index] == 0xa5U;
    }
    passed &= check(owner_alias_poison,
                    "owner alias failure published destination bytes");
    owner_alias_fixture.release();

    execution_fixture source_alias_fixture;
    if (!check(source_alias_fixture.create(api, 14U),
               "source-alias-negative fixture creation failed")) {
        source_alias_fixture.release();
        return false;
    }
    source_alias_fixture.reset_raw();
    void * saved_source1_data = source_alias_fixture.sources[1]->data;
    source_alias_fixture.sources[1]->data =
        source_alias_fixture.source_roots[0]->data;
    const std::uint64_t source_alias_dispatch = (*next_dispatch_id)++;
    passed &= check(source_alias_fixture.bind_and_begin(
                        api, (*next_binding_id)++, source_alias_dispatch),
                    "source-alias-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, source_alias_fixture.graph) ==
                        GGML_STATUS_FAILED,
                    "source/source exact alias was accepted");
    source_alias_fixture.sources[1]->data = saved_source1_data;
    ggml_npu_audit_snapshot_v2 source_alias_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, source_alias_dispatch,
                        &source_alias_snapshot) &&
                        source_alias_snapshot.required_enqueued == 0 &&
                        source_alias_snapshot.required_successfully_covered == 0 &&
                        source_alias_snapshot.executed_by_verilator == 0 &&
                        source_alias_snapshot.commands_accepted == 0 &&
                        source_alias_snapshot.commands_terminal_success == 0 &&
                        source_alias_snapshot.commands_terminal_failure == 0 &&
                        source_alias_snapshot.gmem_read_bytes == 0 &&
                        source_alias_snapshot.gmem_write_bytes == 0 &&
                        source_alias_snapshot.vector_elements == 0 &&
                        source_alias_snapshot.rtl_cycles == 0 &&
                        source_alias_snapshot.coverage_missing == 1 &&
                        source_alias_snapshot.rtl_failures == 1,
                    "source alias rejection did not precede REQUIRED enqueue");
    const auto * source_alias_dst = static_cast<const std::uint8_t *>(
        source_alias_fixture.dst_root->data);
    bool source_alias_poison = true;
    for (std::size_t index = 0;
         index < ggml_nbytes(source_alias_fixture.dst_root); ++index) {
        source_alias_poison &= source_alias_dst[index] == 0xa5U;
    }
    passed &= check(source_alias_poison,
                    "source alias failure published destination bytes");
    source_alias_fixture.release();

    execution_fixture view_alias_fixture;
    if (!check(view_alias_fixture.create(api, 1U),
               "view-alias-negative fixture creation failed")) {
        view_alias_fixture.release();
        return false;
    }
    view_alias_fixture.reset_raw();
    passed &= check(
        view_alias_fixture.profile->sources[0].view_present &&
            view_alias_fixture.profile->sources[0].view_offs == 0U &&
            ggml_nbytes(view_alias_fixture.source_roots[0]) ==
                ggml_nbytes(view_alias_fixture.dst_root),
        "view-alias-negative is not an exact zero-offset root alias");
    void * saved_view_root_data =
        view_alias_fixture.source_roots[0]->data;
    void * saved_view_data = view_alias_fixture.sources[0]->data;
    view_alias_fixture.source_roots[0]->data =
        view_alias_fixture.dst_root->data;
    view_alias_fixture.sources[0]->data =
        view_alias_fixture.dst_root->data;
    const std::uint64_t view_alias_dispatch = (*next_dispatch_id)++;
    passed &= check(view_alias_fixture.bind_and_begin(
                        api, (*next_binding_id)++, view_alias_dispatch),
                    "view-alias-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, view_alias_fixture.graph) ==
                        GGML_STATUS_FAILED,
                    "zero-offset view destination alias was accepted");
    view_alias_fixture.sources[0]->data = saved_view_data;
    view_alias_fixture.source_roots[0]->data = saved_view_root_data;
    ggml_npu_audit_snapshot_v2 view_alias_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, view_alias_dispatch,
                         &view_alias_snapshot) &&
                        view_alias_snapshot.required_enqueued == 0 &&
                        view_alias_snapshot.required_successfully_covered == 0 &&
                        view_alias_snapshot.executed_by_verilator == 0 &&
                        view_alias_snapshot.commands_accepted == 0 &&
                        view_alias_snapshot.commands_terminal_success == 0 &&
                        view_alias_snapshot.commands_terminal_failure == 0 &&
                        view_alias_snapshot.gmem_read_bytes == 0 &&
                        view_alias_snapshot.gmem_write_bytes == 0 &&
                        view_alias_snapshot.vector_elements == 0 &&
                        view_alias_snapshot.rtl_cycles == 0 &&
                        view_alias_snapshot.coverage_missing == 1 &&
                        view_alias_snapshot.rtl_failures == 1,
                    "view alias rejection did not precede REQUIRED enqueue");
    const auto * view_alias_dst = static_cast<const std::uint8_t *>(
        view_alias_fixture.dst_root->data);
    bool view_alias_poison = true;
    for (std::size_t index = 0;
         index < ggml_nbytes(view_alias_fixture.dst_root); ++index) {
        view_alias_poison &= view_alias_dst[index] == 0xa5U;
    }
    passed &= check(view_alias_poison,
                    "view alias failure published destination bytes");
    view_alias_fixture.release();

    execution_fixture duplicate_fixture;
    if (!check(duplicate_fixture.create(api, 0U),
               "duplicate-negative fixture creation failed")) {
        duplicate_fixture.release();
        return false;
    }
    duplicate_fixture.reset_raw();
    const std::uint64_t duplicate_dispatch = (*next_dispatch_id)++;
    passed &= check(duplicate_fixture.bind_and_begin(
                        api, (*next_binding_id)++, duplicate_dispatch),
                    "duplicate-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, duplicate_fixture.graph) ==
                        GGML_STATUS_SUCCESS &&
                        ggml_backend_graph_compute(
                            api.backend, duplicate_fixture.graph) ==
                            GGML_STATUS_FAILED,
                    "duplicate canonical execution was not rejected");
    ggml_npu_audit_snapshot_v2 duplicate_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, duplicate_dispatch,
                         &duplicate_snapshot) &&
                        duplicate_snapshot.required_enqueued == 1 &&
                        duplicate_snapshot.required_successfully_covered == 1 &&
                        duplicate_snapshot.executed_by_verilator == 1 &&
                        duplicate_snapshot.coverage_duplicate == 1 &&
                        duplicate_snapshot.cpu_fallback_attempts == 0 &&
                        duplicate_snapshot.host_tensor_ops == 0,
                    "duplicate execution ledger mismatch");
    duplicate_fixture.release();

    execution_fixture error_fixture;
    if (!check(error_fixture.create(api, 23U),
               "error-negative SET_ROWS fixture creation failed")) {
        error_fixture.release();
        return false;
    }
    error_fixture.reset_raw();
    store_u64_le(
        static_cast<std::uint8_t *>(error_fixture.sources[1]->data), 256U);
    const std::uint64_t error_dispatch = (*next_dispatch_id)++;
    passed &= check(error_fixture.bind_and_begin(
                        api, (*next_binding_id)++, error_dispatch),
                    "error-negative bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(
                        api.backend, error_fixture.graph) ==
                        GGML_STATUS_FAILED,
                    "out-of-range SET_ROWS physical slot was accepted");
    ggml_npu_audit_snapshot_v2 error_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, error_dispatch, &error_snapshot) &&
                        error_snapshot.required_enqueued == 0 &&
                        error_snapshot.commands_accepted == 0 &&
                        error_snapshot.gmem_write_bytes == 0 &&
                        error_snapshot.coverage_missing == 1 &&
                        error_snapshot.rtl_failures == 1,
                    "SET_ROWS preflight error ledger mismatch");
    const auto * error_dst = static_cast<const std::uint8_t *>(
        error_fixture.dst_root->data);
    bool error_poison = true;
    for (std::size_t index = 0;
         index < ggml_nbytes(error_fixture.dst_root); ++index) {
        error_poison &= error_dst[index] == 0xa5U;
    }
    passed &= check(error_poison,
                    "SET_ROWS failure published private destination");
    error_fixture.release();
    return passed;
}

} // namespace

int main(int argc, char ** argv) {
    if (argc == 3 && std::strcmp(argv[2], "--q8-portal-max") == 0) {
        return run_q8_portal_max_graph(argv[1]);
    }
    if (!check(argc == 2, "expected backend DSO path")) {
        return 70;
    }
    backend_api api;
    if (!check(api.load(argv[1]), "dynamic backend/API load failed")) {
        api.close();
        return 71;
    }
    bool passed = run_route_tests();
    ggml_init_params metadata_parameters = {
        16 * 1024 * 1024,
        nullptr,
        true,
    };
    ggml_context * metadata_context = ggml_init(metadata_parameters);
    if (!check(metadata_context != nullptr,
               "metadata context allocation failed")) {
        api.close();
        return 72;
    }
    std::array<metadata_op, qwen_remaining_manifest::kProfileCount> ops = {};
    std::uint64_t next_binding_id = kBindingBase;
    std::uint64_t next_dispatch_id = kDispatchBase + 1;
    passed &= run_manifest_and_matcher_tests(
        api, metadata_context, &ops, &next_binding_id);
    passed &= run_positive_graphs(
        api, &next_binding_id, &next_dispatch_id);
    passed &= run_inplace_graphs(
        api, &next_binding_id, &next_dispatch_id);
    passed &= run_execution_negatives(
        api, &next_binding_id, &next_dispatch_id);
    if (passed) {
        std::printf(
            "[NPU-BACKEND-REMAINING][PASS] canonical=433 profiles=30 "
            "owners=13 required_partition=646+433+1=1080 "
            "actual_graphs=unary+unary-inplace+rms+rms-inplace+ssm+cpy-empty2+cpy-view+cont+cont-view+set+attention+rope+rope-inplace+softmax+softmax-inplace "
            "route=global-to-public-local-explicit identity=full256 "
            "raw_transport_only=1 private_commit=success-only "
            "cpu_fallback_attempts=0 host_tensor_arithmetic=0 "
            "negatives=missing-binding+identity+profile+layout+alias-partial+alias-owner+alias-source-source+alias-view+duplicate+error "
            "canonical_sha=%s profile_sha=%s checks=%d\n",
            qwen_remaining_manifest::kCanonicalSetSha256,
            qwen_remaining_manifest::kProfileSetSha256,
            checks);
    }
    ggml_free(metadata_context);
    api.close();
    return passed ? 0 : 73;
}
