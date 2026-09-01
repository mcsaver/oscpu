#include "ggml-backend.h"
#include "ggml.h"
#include "npu-audit-api.h"
#include "qwen-f32-gather-repeat-manifest.generated.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <set>
#include <vector>

namespace {

using mover_profile = qwen_f32_mover_manifest::profile;
using mover_node = qwen_f32_mover_manifest::canonical_node;
using tensor_spec = qwen_f32_mover_manifest::tensor_spec;

constexpr std::size_t kAlignment = 32;
constexpr std::uint64_t kBindingBase = 0xf3200000ULL;
constexpr std::uint64_t kDispatchBase = 0xf3300000ULL;
constexpr std::uint32_t kGetGraphIndex = 1709;
constexpr std::uint32_t kEmptyGetGraphIndex = 9;
constexpr std::uint32_t kRepeatGraphIndex = 42;

constexpr std::array<std::uint32_t, 16> kRawPattern = {
    0x00000000U, 0x80000000U, 0x00000001U, 0x007fffffU,
    0x00800000U, 0x3f000000U, 0x3f800000U, 0xbf800000U,
    0x7f7fffffU, 0xff7fffffU, 0x7f800000U, 0xff800000U,
    0x7fc12345U, 0xffc54321U, 0x41200000U, 0xc2480000U,
};

int checks = 0;

bool check(bool condition, const char * message) {
    ++checks;
    if (!condition) {
        std::fprintf(stderr,
                     "[NPU-BACKEND-F32-MOVER][FAIL] check=%d message=%s\n",
                     checks, message);
    }
    return condition;
}

void store_u32_le(std::uint8_t * destination, std::uint32_t value) {
    for (std::size_t byte = 0; byte < 4; ++byte) {
        destination[byte] =
            static_cast<std::uint8_t>(value >> (8 * byte));
    }
}

std::uint32_t load_u32_le(const std::uint8_t * source) {
    std::uint32_t value = 0;
    for (std::size_t byte = 0; byte < 4; ++byte) {
        value |= static_cast<std::uint32_t>(source[byte]) << (8 * byte);
    }
    return value;
}

bool apply_tensor_spec(
        ggml_tensor * tensor,
        const tensor_spec & spec,
        ggml_tensor * view_root = nullptr) {
    if (tensor == nullptr || (spec.view_present && view_root == nullptr)) {
        return false;
    }
    tensor->type = static_cast<enum ggml_type>(spec.type_id);
    tensor->op = static_cast<enum ggml_op>(spec.op_id);
    tensor->flags = spec.flags;
    tensor->view_src = spec.view_present ? view_root : nullptr;
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

const mover_profile * profile_by_id(std::uint32_t profile_id) {
    for (const auto & profile : qwen_f32_mover_manifest::kProfiles) {
        if (profile.profile_id == profile_id) {
            return &profile;
        }
    }
    return nullptr;
}

const mover_node * node_by_index(std::uint32_t graph_node_index) {
    for (const auto & node : qwen_f32_mover_manifest::kCanonicalNodes) {
        if (node.graph_node_index == graph_node_index) {
            return &node;
        }
    }
    return nullptr;
}

const mover_node * representative_for_profile(std::uint32_t profile_id) {
    for (const auto & node : qwen_f32_mover_manifest::kCanonicalNodes) {
        if (node.profile_id == profile_id) {
            return &node;
        }
    }
    return nullptr;
}

ggml_npu_canonical_node_binding_v1 make_binding(const mover_node & node) {
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

bool exact_success_audit(
        const ggml_npu_audit_snapshot_v2 & snapshot,
        std::uint64_t elements) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                        snapshot.assigned_to_npu == 1 &&
                        snapshot.required_enqueued == 1 &&
                        snapshot.required_successfully_covered == 1 &&
                        snapshot.executed_by_verilator == 1,
                    "REQUIRED execution ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                        snapshot.commands_terminal_success == 1 &&
                        snapshot.commands_terminal_failure == 0,
                    "command completion ledger mismatch");
    passed &= check(snapshot.gmem_read_bytes == 0 &&
                        snapshot.gmem_write_bytes == 0 &&
                        snapshot.vector_elements == elements,
                    "pure-RTL macro GMEM/element counters mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                        snapshot.cpu_fallback_attempts == 0 &&
                        snapshot.host_tensor_ops == 0,
                    "fallback or host tensor arithmetic detected");
    passed &= check(snapshot.coverage_missing == 0 &&
                        snapshot.coverage_duplicate == 0 &&
                        snapshot.coverage_hash_mismatch == 0 &&
                        snapshot.completion_identity_mismatch == 0,
                    "canonical/full256 completion ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                        snapshot.gmem_errors == 0 &&
                        snapshot.timeout_errors == 0 &&
                        snapshot.rtl_cycles > 0,
                    "RTL terminal status mismatch");
    return passed;
}

ggml_tensor * make_metadata_op(
        ggml_context * context,
        const mover_profile & profile) {
    ggml_tensor * dst = ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.dst.type_id),
        profile.dst.ne[0], profile.dst.ne[1],
        profile.dst.ne[2], profile.dst.ne[3]);
    ggml_tensor * src0 = ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.src0.type_id),
        profile.src0.ne[0], profile.src0.ne[1],
        profile.src0.ne[2], profile.src0.ne[3]);
    ggml_tensor * src1 = profile.src1_present ? ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.src1.type_id),
        profile.src1.ne[0], profile.src1.ne[1],
        profile.src1.ne[2], profile.src1.ne[3]) : nullptr;
    ggml_tensor * src0_root = profile.src0.view_present ?
        ggml_new_tensor_1d(context, GGML_TYPE_F32, 1) : nullptr;
    ggml_tensor * src1_root =
        profile.src1_present && profile.src1.view_present ?
            ggml_new_tensor_1d(context, GGML_TYPE_I32, 1) : nullptr;
    if (!apply_tensor_spec(dst, profile.dst) ||
        !apply_tensor_spec(src0, profile.src0, src0_root) ||
        (profile.src1_present &&
         !apply_tensor_spec(src1, profile.src1, src1_root))) {
        return nullptr;
    }
    std::memset(dst->src, 0, sizeof(dst->src));
    dst->src[0] = src0;
    dst->src[1] = src1;
    return dst;
}

bool run_manifest_and_negative_tests(
        backend_api & api,
        ggml_context * context,
        std::array<ggml_tensor *, qwen_f32_mover_manifest::kProfileCount> *
            profile_ops,
        std::uint64_t * next_binding_id) {
    if (profile_ops == nullptr || next_binding_id == nullptr) {
        return false;
    }
    bool passed = true;
    std::set<std::array<std::uint8_t, 32>> unique_ids;
    std::set<std::uint32_t> unique_indices;
    std::size_t get_count = 0;
    std::size_t repeat_count = 0;
    std::size_t empty_count = 0;
    std::size_t zero_cardinality_count = 0;

    for (const auto & profile : qwen_f32_mover_manifest::kProfiles) {
        const mover_node * representative =
            representative_for_profile(profile.profile_id);
        ggml_tensor * op = make_metadata_op(context, profile);
        (*profile_ops)[profile.profile_id] = op;
        if (op != nullptr && representative != nullptr) {
            ggml_set_name(op, representative->dst_name);
            ggml_set_name(op->src[0], representative->src0_name);
            if (op->src[1] != nullptr) {
                ggml_set_name(op->src[1], representative->src1_name);
            }
        }
        passed &= check(op != nullptr && representative != nullptr &&
                            ggml_backend_dev_supports_op(api.device, op),
                        "machine-derived F32 mover profile was not admitted");
    }

    for (const auto & node : qwen_f32_mover_manifest::kCanonicalNodes) {
        const mover_profile * profile = profile_by_id(node.profile_id);
        ggml_tensor * op = (*profile_ops)[node.profile_id];
        unique_ids.insert(node.canonical_id);
        unique_indices.insert(node.graph_node_index);
        get_count += node.owner == qwen_f32_mover_manifest::kOwnerGetRows;
        repeat_count += node.owner == qwen_f32_mover_manifest::kOwnerRepeat;
        empty_count += profile != nullptr &&
                       profile->owner ==
                           qwen_f32_mover_manifest::kOwnerGetRows &&
                       profile->index_count == 0;
        zero_cardinality_count += node.allow_zero_cardinality ? 1U : 0U;
        if (op != nullptr) {
            ggml_set_name(op, node.dst_name);
            ggml_set_name(op->src[0], node.src0_name);
            if (op->src[1] != nullptr) {
                ggml_set_name(op->src[1], node.src1_name);
            }
        }
        const auto binding = make_binding(node);
        const bool src1_ref_valid =
            (node.owner == qwen_f32_mover_manifest::kOwnerRepeat &&
             node.src1_ref_kind == qwen_f32_mover_manifest::kRefNone) ||
            (node.owner == qwen_f32_mover_manifest::kOwnerGetRows &&
             (node.src1_ref_kind ==
                  qwen_f32_mover_manifest::kRefExternal ||
              (node.src1_ref_kind == qwen_f32_mover_manifest::kRefNode &&
               node.src1_ref_index < node.graph_node_index)));
        passed &= check(profile != nullptr &&
                            profile->owner == node.owner &&
                            node.src0_ref_kind ==
                                qwen_f32_mover_manifest::kRefNode &&
                            node.src0_ref_index < node.graph_node_index &&
                            src1_ref_valid,
                        "generated owner/source-reference relation changed");
        passed &= check(api.binding_begin(
                            api.backend, *next_binding_id, 1) &&
                            api.binding_bind(
                                api.backend, *next_binding_id, op, &binding) &&
                            api.binding_seal(api.backend, *next_binding_id),
                        "exact F32 mover canonical binding failed");
        ++*next_binding_id;
    }
    passed &= check(unique_ids.size() ==
                        qwen_f32_mover_manifest::kCanonicalNodeCount &&
                        unique_indices.size() ==
                        qwen_f32_mover_manifest::kCanonicalNodeCount &&
                        get_count ==
                        qwen_f32_mover_manifest::kGetRowsNodeCount &&
                        repeat_count ==
                        qwen_f32_mover_manifest::kRepeatNodeCount &&
                        empty_count == 36 && zero_cardinality_count == 1,
                    "91-node owner/identity/empty census mismatch");

    const mover_node * get_node = node_by_index(kGetGraphIndex);
    const mover_node * repeat_node = node_by_index(kRepeatGraphIndex);
    ggml_tensor * get_op = get_node == nullptr ? nullptr :
        (*profile_ops)[get_node->profile_id];
    ggml_tensor * repeat_op = repeat_node == nullptr ? nullptr :
        (*profile_ops)[repeat_node->profile_id];
    if (!check(get_node != nullptr && repeat_node != nullptr &&
                   get_op != nullptr && repeat_op != nullptr,
               "negative-test canonical representatives missing")) {
        return false;
    }
    ggml_set_name(get_op, get_node->dst_name);
    ggml_set_name(get_op->src[0], get_node->src0_name);
    ggml_set_name(get_op->src[1], get_node->src1_name);
    ggml_set_name(repeat_op, repeat_node->dst_name);
    ggml_set_name(repeat_op->src[0], repeat_node->src0_name);
    const auto get_binding = make_binding(*get_node);

    auto unknown = get_binding;
    unknown.canonical_id[0] ^= 0x80U;
    passed &= check(api.binding_begin(api.backend, *next_binding_id, 1) &&
                        !api.binding_bind(
                            api.backend, *next_binding_id, get_op, &unknown),
                    "unknown canonical ID was accepted");
    ++*next_binding_id;
    auto bad_index = get_binding;
    bad_index.graph_node_index = std::numeric_limits<std::uint64_t>::max();
    passed &= check(api.binding_begin(api.backend, *next_binding_id, 1) &&
                        !api.binding_bind(
                            api.backend, *next_binding_id, get_op, &bad_index),
                    "canonical graph-index mismatch was accepted");
    ++*next_binding_id;
    auto cross = get_binding;
    std::memcpy(cross.canonical_id, repeat_node->canonical_id.data(),
                repeat_node->canonical_id.size());
    passed &= check(api.binding_begin(api.backend, *next_binding_id, 1) &&
                        !api.binding_bind(
                            api.backend, *next_binding_id, get_op, &cross),
                    "cross-owner identity/index collision was accepted");
    ++*next_binding_id;
    passed &= check(api.binding_begin(api.backend, *next_binding_id, 1) &&
                        !api.binding_bind(
                            api.backend, *next_binding_id,
                            repeat_op, &get_binding),
                    "cross-owner canonical/profile collision was accepted");
    ++*next_binding_id;

    ggml_set_name(get_op, "not-a-canonical-v5-name");
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong canonical tensor name was admitted");
    ggml_set_name(get_op, get_node->dst_name);
    const enum ggml_type saved_type = get_op->src[0]->type;
    get_op->src[0]->type = GGML_TYPE_F16;
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong GET_ROWS source dtype was admitted");
    get_op->src[0]->type = saved_type;
    const std::int64_t saved_ne = get_op->ne[0];
    get_op->ne[0] += 1;
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong F32 mover shape was admitted");
    get_op->ne[0] = saved_ne;
    const std::size_t saved_nb = get_op->src[0]->nb[0];
    get_op->src[0]->nb[0] += 4;
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong F32 mover stride was admitted");
    get_op->src[0]->nb[0] = saved_nb;
    const auto saved_flags = get_op->flags;
    get_op->flags ^= GGML_TENSOR_FLAG_COMPUTE;
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong F32 mover flags were admitted");
    get_op->flags = saved_flags;
    ggml_tensor * saved_view = get_op->src[0]->view_src;
    get_op->src[0]->view_src = repeat_op->src[0];
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong F32 mover view relation was admitted");
    get_op->src[0]->view_src = saved_view;
    auto * params = reinterpret_cast<std::uint8_t *>(get_op->op_params);
    params[63] ^= 1U;
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong F32 mover op_params were admitted");
    params[63] ^= 1U;
    std::swap(get_op->src[0], get_op->src[1]);
    passed &= check(!ggml_backend_dev_supports_op(api.device, get_op),
                    "wrong GET_ROWS source ordering was admitted");
    std::swap(get_op->src[0], get_op->src[1]);

    passed &= check(!api.audit_begin(api.backend, kDispatchBase, 1, 1),
                    "audit accepted missing canonical binding");
    return passed;
}

struct mapped_tensor {
    void * storage = nullptr;
    std::size_t storage_bytes = 0;
    ggml_backend_buffer_t buffer = nullptr;

    bool allocate(
            backend_api & api,
            ggml_tensor * tensor,
            std::size_t logical_bytes,
            std::size_t allocation_bytes = 0) {
        storage_bytes = allocation_bytes == 0 ? logical_bytes : allocation_bytes;
        if (tensor == nullptr || logical_bytes == 0 ||
            storage_bytes < logical_bytes || storage_bytes % kAlignment != 0) {
            return false;
        }
        storage = std::aligned_alloc(kAlignment, storage_bytes);
        if (storage == nullptr) {
            return false;
        }
        buffer = ggml_backend_dev_buffer_from_host_ptr(
            api.device, storage, storage_bytes, logical_bytes);
        return buffer != nullptr &&
               ggml_backend_tensor_alloc(buffer, tensor, storage) ==
                   GGML_STATUS_SUCCESS;
    }

    void release() {
        if (buffer != nullptr) {
            ggml_backend_buffer_free(buffer);
            buffer = nullptr;
        }
        std::free(storage);
        storage = nullptr;
    }
};

bool bind_and_begin(
        backend_api & api,
        const mover_node & node,
        ggml_tensor * op,
        std::uint64_t binding_id,
        std::uint64_t dispatch_id) {
    const auto binding = make_binding(node);
    return api.binding_begin(api.backend, binding_id, 1) &&
           api.binding_bind(api.backend, binding_id, op, &binding) &&
           api.binding_seal(api.backend, binding_id) &&
           api.audit_begin(api.backend, dispatch_id, 1, 1);
}

bool run_real_get_rows(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    constexpr std::size_t kElements = 1024;
    constexpr std::size_t kSrcBytes = kElements * 4;
    constexpr std::size_t kIndexBytes = 4;
    const mover_node * node = node_by_index(kGetGraphIndex);
    const mover_profile * profile = node == nullptr ? nullptr :
        profile_by_id(node->profile_id);
    if (!check(node != nullptr && profile != nullptr &&
                   profile->profile_id == 4 &&
                   profile->owner == qwen_f32_mover_manifest::kOwnerGetRows,
               "terminal F32 GET_ROWS profile missing")) {
        return false;
    }

    ggml_init_params parameters = {2 * 1024 * 1024, nullptr, true};
    ggml_context * context = ggml_init(parameters);
    if (!check(context != nullptr, "GET_ROWS context allocation failed")) {
        return false;
    }
    ggml_tensor * source =
        ggml_new_tensor_2d(context, GGML_TYPE_F32, kElements, 1);
    ggml_tensor * indices =
        ggml_new_tensor_1d(context, GGML_TYPE_I32, 1);
    ggml_tensor * output = ggml_get_rows(context, source, indices);
    ggml_cgraph * graph = ggml_new_graph(context);
    ggml_build_forward_expand(graph, output);
    bool passed = true;
    passed &= check(source != nullptr && indices != nullptr &&
                        output != nullptr && graph != nullptr &&
                        ggml_graph_n_nodes(graph) == 1 &&
                        ggml_graph_node(graph, 0) == output,
                    "real ggml_get_rows graph construction failed");
    passed &= check(apply_tensor_spec(source, profile->src0) &&
                        apply_tensor_spec(indices, profile->src1) &&
                        apply_tensor_spec(output, profile->dst),
                    "terminal GET_ROWS exact metadata application failed");
    ggml_set_name(source, node->src0_name);
    ggml_set_name(indices, node->src1_name);
    ggml_set_name(output, node->dst_name);
    passed &= check(output->src[0] == source && output->src[1] == indices &&
                        output->op == GGML_OP_GET_ROWS &&
                        ggml_nbytes(source) == kSrcBytes &&
                        ggml_nbytes(indices) == kIndexBytes &&
                        ggml_nbytes(output) == kSrcBytes &&
                        ggml_backend_dev_supports_op(api.device, output),
                    "real GET_ROWS exact source/layout relation changed");

    mapped_tensor source_map;
    mapped_tensor index_map;
    mapped_tensor output_map;
    passed &= check(source_map.allocate(api, source, kSrcBytes),
                    "GET_ROWS source mapping failed");
    passed &= check(index_map.allocate(api, indices, kIndexBytes, kAlignment),
                    "GET_ROWS index mapping failed");
    passed &= check(output_map.allocate(api, output, kSrcBytes),
                    "GET_ROWS output mapping failed");
    if (!passed) {
        output_map.release();
        index_map.release();
        source_map.release();
        ggml_free(context);
        return false;
    }

    auto * src = static_cast<std::uint8_t *>(source_map.storage);
    auto * ids = static_cast<std::uint8_t *>(index_map.storage);
    auto * dst = static_cast<std::uint8_t *>(output_map.storage);
    for (std::size_t index = 0; index < kElements; ++index) {
        store_u32_le(src + index * 4, kRawPattern[index % kRawPattern.size()]);
    }
    store_u32_le(ids, 0);
    std::memset(dst, 0xa5, kSrcBytes);

    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "GET_ROWS positive bind/audit begin failed");
    const std::uint64_t positive_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "real F32 ggml_get_rows compute failed");
    ggml_npu_audit_snapshot_v2 snapshot = {};
    passed &= check(api.audit_end(
                        api.backend, positive_dispatch, &snapshot),
                    "GET_ROWS positive audit failed to close");
    passed &= exact_success_audit(snapshot, 1024);
    bool raw_match = true;
    for (std::size_t index = 0; index < kElements; ++index) {
        raw_match &= load_u32_le(dst + index * 4) ==
                     kRawPattern[index % kRawPattern.size()];
    }
    passed &= check(raw_match,
                    "GET_ROWS poisoned full-output raw-bit oracle mismatch");

    // The public adapter pre-scans the signed I32 id.  V=1 makes id=1 an
    // exact bounds failure: no source read, no write, and no publication.
    store_u32_le(ids, 1);
    std::memset(dst, 0xa5, kSrcBytes);
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "GET_ROWS bounds-negative bind/audit begin failed");
    const std::uint64_t bounds_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_FAILED,
                    "out-of-range F32 GET_ROWS index was accepted");
    ggml_npu_audit_snapshot_v2 bounds_snapshot = {};
    const bool bounds_closed =
        api.audit_end(api.backend, bounds_dispatch, &bounds_snapshot);
    const bool bounds_ledger =
        !bounds_closed && bounds_snapshot.required_seen == 1 &&
        bounds_snapshot.assigned_to_npu == 1 &&
        bounds_snapshot.required_enqueued == 1 &&
        bounds_snapshot.required_successfully_covered == 0 &&
        bounds_snapshot.executed_by_verilator == 0 &&
        bounds_snapshot.commands_accepted == 1 &&
        bounds_snapshot.commands_terminal_success == 0 &&
        bounds_snapshot.commands_terminal_failure == 1 &&
        bounds_snapshot.gmem_read_bytes == 0 &&
        bounds_snapshot.gmem_write_bytes == 0 &&
        bounds_snapshot.vector_elements == 0 &&
        bounds_snapshot.coverage_missing == 1 &&
        bounds_snapshot.coverage_duplicate == 0 &&
        bounds_snapshot.coverage_hash_mismatch == 0 &&
        bounds_snapshot.completion_identity_mismatch == 0 &&
        bounds_snapshot.rtl_failures == 1 &&
        bounds_snapshot.gmem_errors == 0 &&
        bounds_snapshot.timeout_errors == 0 &&
        bounds_snapshot.cpu_fallback_attempts == 0 &&
        bounds_snapshot.host_tensor_ops == 0;
    if (!bounds_ledger) {
        std::fprintf(
            stderr,
            "[NPU-BACKEND-F32-MOVER][DIAG] bounds closed=%u "
            "enqueued=%llu covered=%llu executed=%llu commands=%llu/%llu/%llu "
            "read=%llu write=%llu elements=%llu missing=%llu rtl_failures=%llu "
            "gmem_errors=%llu timeout=%llu fallback=%llu host=%llu\n",
            static_cast<unsigned>(bounds_closed),
            static_cast<unsigned long long>(bounds_snapshot.required_enqueued),
            static_cast<unsigned long long>(
                bounds_snapshot.required_successfully_covered),
            static_cast<unsigned long long>(bounds_snapshot.executed_by_verilator),
            static_cast<unsigned long long>(bounds_snapshot.commands_accepted),
            static_cast<unsigned long long>(
                bounds_snapshot.commands_terminal_success),
            static_cast<unsigned long long>(
                bounds_snapshot.commands_terminal_failure),
            static_cast<unsigned long long>(bounds_snapshot.gmem_read_bytes),
            static_cast<unsigned long long>(bounds_snapshot.gmem_write_bytes),
            static_cast<unsigned long long>(bounds_snapshot.vector_elements),
            static_cast<unsigned long long>(bounds_snapshot.coverage_missing),
            static_cast<unsigned long long>(bounds_snapshot.rtl_failures),
            static_cast<unsigned long long>(bounds_snapshot.gmem_errors),
            static_cast<unsigned long long>(bounds_snapshot.timeout_errors),
            static_cast<unsigned long long>(
                bounds_snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(bounds_snapshot.host_tensor_ops));
    }
    passed &= check(bounds_ledger,
                    "GET_ROWS bounds failure ledger mismatch");
    bool poison_intact = true;
    for (std::size_t index = 0; index < kSrcBytes; ++index) {
        poison_intact &= dst[index] == 0xa5U;
    }
    passed &= check(poison_intact,
                    "GET_ROWS failure published private destination bytes");
    store_u32_le(ids, 0);

    // Host range overflow and aliasing both stop before REQUIRED enqueue.
    void * saved_source_data = source->data;
    source->data = reinterpret_cast<void *>(
        std::numeric_limits<std::uintptr_t>::max() - 1024);
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "GET_ROWS overflow bind/audit begin failed");
    const std::uint64_t overflow_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_FAILED,
                    "GET_ROWS host range overflow was accepted");
    source->data = saved_source_data;
    ggml_npu_audit_snapshot_v2 overflow_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, overflow_dispatch, &overflow_snapshot) &&
                        overflow_snapshot.required_enqueued == 0 &&
                        overflow_snapshot.commands_accepted == 0 &&
                        overflow_snapshot.executed_by_verilator == 0 &&
                        overflow_snapshot.coverage_missing == 1,
                    "GET_ROWS overflow did not fail before enqueue");

    void * saved_index_data = indices->data;
    indices->data = source->data;
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "GET_ROWS alias bind/audit begin failed");
    const std::uint64_t alias_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_FAILED,
                    "GET_ROWS aliased source/index storage was accepted");
    indices->data = saved_index_data;
    ggml_npu_audit_snapshot_v2 alias_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, alias_dispatch, &alias_snapshot) &&
                        alias_snapshot.required_enqueued == 0 &&
                        alias_snapshot.commands_accepted == 0 &&
                        alias_snapshot.coverage_missing == 1,
                    "GET_ROWS alias did not fail before enqueue");

    std::memset(dst, 0xa5, kSrcBytes);
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "GET_ROWS duplicate bind/audit begin failed");
    const std::uint64_t duplicate_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_SUCCESS &&
                        ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_FAILED,
                    "GET_ROWS duplicate execution was not fail-closed");
    ggml_npu_audit_snapshot_v2 duplicate_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, duplicate_dispatch,
                         &duplicate_snapshot) &&
                        duplicate_snapshot.coverage_duplicate == 1 &&
                        duplicate_snapshot.required_enqueued == 1 &&
                        duplicate_snapshot.required_successfully_covered == 1 &&
                        duplicate_snapshot.executed_by_verilator == 1 &&
                        duplicate_snapshot.cpu_fallback_attempts == 0 &&
                        duplicate_snapshot.host_tensor_ops == 0,
                    "GET_ROWS duplicate ledger mismatch");

    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-GET-ROWS][PASS] graph=real-ggml_get_rows "
            "shape=D1024/N1/V1 raw_fp32=1024/1024 poisoned_output=covered "
            "required_issued=1 required_completed=1 commands=1/1/0 "
            "gmem_read=0 gmem_write=0 portal_read=4100 portal_write=4096 "
            "portal_groups=129 elements=1024 "
            "identity=full256 private_commit=success-only "
            "cpu_fallback_attempts=0 host_tensor_arithmetic=0 "
            "negatives=index-bounds+overflow+alias+duplicate\n");
    }

    output_map.release();
    index_map.release();
    source_map.release();
    ggml_free(context);
    return passed;
}

bool run_empty_get_profile(
        backend_api & api,
        const mover_profile & profile,
        const mover_node & node,
        std::uint64_t binding_id,
        std::uint64_t dispatch_id) {
    ggml_init_params parameters = {2 * 1024 * 1024, nullptr, true};
    ggml_context * context = ggml_init(parameters);
    if (!check(context != nullptr, "empty GET context allocation failed")) {
        return false;
    }
    ggml_tensor * src_root = ggml_new_tensor_1d(context, GGML_TYPE_F32, 1);
    ggml_tensor * ids_root = ggml_new_tensor_1d(context, GGML_TYPE_I32, 1);
    ggml_tensor * source = ggml_new_tensor_2d(
        context, GGML_TYPE_F32, profile.element_count, 1);
    ggml_tensor * indices =
        ggml_new_tensor_1d(context, GGML_TYPE_I32, 0);
    ggml_tensor * output = ggml_get_rows(context, source, indices);
    ggml_cgraph * graph = ggml_new_graph(context);
    ggml_build_forward_expand(graph, output);
    bool passed = true;
    passed &= check(source != nullptr && indices != nullptr &&
                        output != nullptr && graph != nullptr,
                    "real empty ggml_get_rows graph construction failed");
    passed &= check(apply_tensor_spec(source, profile.src0, src_root) &&
                        apply_tensor_spec(indices, profile.src1, ids_root) &&
                        apply_tensor_spec(output, profile.dst),
                    "empty GET exact metadata application failed");
    ggml_set_name(source, node.src0_name);
    ggml_set_name(indices, node.src1_name);
    ggml_set_name(output, node.dst_name);
    passed &= check(output->src[0] == source && output->src[1] == indices &&
                        ggml_nbytes(source) == profile.src_bytes &&
                        ggml_nbytes(indices) == 0 &&
                        ggml_nbytes(output) == 0 &&
                        source->data == nullptr && indices->data == nullptr &&
                        output->data == nullptr &&
                        ggml_backend_dev_supports_op(api.device, output),
                    "empty GET zero-storage/profile relation changed");
    passed &= check(bind_and_begin(
                        api, node, output, binding_id, dispatch_id),
                    "empty GET bind/audit begin failed");
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "empty GET did not complete successfully");
    ggml_npu_audit_snapshot_v2 snapshot = {};
    passed &= check(api.audit_end(api.backend, dispatch_id, &snapshot),
                    "empty GET audit failed to close");
    passed &= exact_success_audit(snapshot, 0);
    ggml_free(context);
    return passed;
}

bool run_empty_gets(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    const mover_node * empty_18432 = node_by_index(kEmptyGetGraphIndex);
    const mover_profile * profile_18432 = empty_18432 == nullptr ? nullptr :
        profile_by_id(empty_18432->profile_id);
    const mover_profile * profile_262144 = profile_by_id(3);
    const mover_node * empty_262144 = representative_for_profile(3);
    bool passed = check(empty_18432 != nullptr && profile_18432 != nullptr &&
                            profile_18432->profile_id == 1 &&
                            profile_18432->index_count == 0 &&
                            empty_262144 != nullptr &&
                            profile_262144 != nullptr &&
                            profile_262144->index_count == 0,
                        "two empty GET profiles missing");
    if (!passed) {
        return false;
    }
    passed &= run_empty_get_profile(
        api, *profile_18432, *empty_18432,
        (*next_binding_id)++, (*next_dispatch_id)++);
    passed &= run_empty_get_profile(
        api, *profile_262144, *empty_262144,
        (*next_binding_id)++, (*next_dispatch_id)++);
    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-GET-ROWS-EMPTY][PASS] profiles=2 "
            "canonical_nodes=36 shapes=D18432/N0+D262144/N0 "
            "real_dispatches=2 commands=2/2/0 read=0 write=0 elements=0 "
            "required_issued=2 required_completed=2 identity=full256 "
            "cpu_fallback_attempts=0 host_tensor_arithmetic=0\n");
    }
    return passed;
}

bool run_terminal_empty_get(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    const mover_node * node = node_by_index(kGetGraphIndex);
    const mover_profile * frozen = node == nullptr ? nullptr :
        profile_by_id(node->profile_id);
    bool passed = check(node != nullptr && frozen != nullptr &&
                            node->allow_zero_cardinality &&
                            frozen->profile_id == 4 &&
                            frozen->index_count == 1,
                        "terminal zero-cardinality GET_ROWS owner missing");
    if (!passed) {
        return false;
    }

    mover_profile dynamic = *frozen;
    dynamic.source_row_count = 0;
    dynamic.index_count = 0;
    dynamic.index_bytes = 0;
    dynamic.dst_bytes = 0;
    dynamic.dst.ne[1] = 0;
    dynamic.dst.nb[2] = 0;
    dynamic.dst.nb[3] = 0;
    dynamic.src1.ne[0] = 0;
    dynamic.src1.nb[1] = 0;
    dynamic.src1.nb[2] = 0;
    dynamic.src1.nb[3] = 0;

    ggml_init_params parameters = {2 * 1024 * 1024, nullptr, true};
    ggml_context * context = ggml_init(parameters);
    ggml_tensor * probe = context == nullptr ? nullptr :
        make_metadata_op(context, dynamic);
    if (probe != nullptr) {
        ggml_set_name(probe, node->dst_name);
        ggml_set_name(probe->src[0], node->src0_name);
        ggml_set_name(probe->src[1], node->src1_name);
    }
    passed &= check(probe != nullptr &&
                        ggml_backend_dev_supports_op(api.device, probe),
                    "terminal zero-cardinality GET_ROWS was not admitted");
    if (probe != nullptr) {
        probe->ne[1] = 1;
        passed &= check(!ggml_backend_dev_supports_op(api.device, probe),
                        "half-empty GET_ROWS destination was admitted");
        probe->ne[1] = 0;
        probe->nb[2] = 4;
        passed &= check(!ggml_backend_dev_supports_op(api.device, probe),
                        "empty GET_ROWS tail stride was not exact");
        probe->nb[2] = 0;
        ggml_set_name(probe, "not-terminal-result_norm");
        passed &= check(!ggml_backend_dev_supports_op(api.device, probe),
                        "noncanonical terminal-empty name was admitted");
    }
    if (context != nullptr) {
        ggml_free(context);
    }

    passed &= run_empty_get_profile(
        api, dynamic, *node, (*next_binding_id)++, (*next_dispatch_id)++);
    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-GET-ROWS-TERMINAL-EMPTY][PASS] "
            "graph_node=1709 profile=4 shape=D1024/N0 owner=f32-get-rows "
            "system=1 required=1/1 portal_transaction=1 portal_groups=0 "
            "read=0 write=0 elements=0 identity=full256 "
            "negatives=half-empty+tail-stride+name\n");
    }
    return passed;
}

bool run_real_repeat(
        backend_api & api,
        std::uint64_t * next_binding_id,
        std::uint64_t * next_dispatch_id) {
    constexpr std::size_t kD = 128;
    constexpr std::size_t kR = 128;
    constexpr std::size_t kO = 16;
    constexpr std::size_t kSrcBytes = kD * kO * 4;
    constexpr std::size_t kDstBytes = kD * kR * kO * 4;
    const mover_node * node = node_by_index(kRepeatGraphIndex);
    const mover_profile * profile = node == nullptr ? nullptr :
        profile_by_id(node->profile_id);
    if (!check(node != nullptr && profile != nullptr &&
                   profile->profile_id == 5 &&
                   profile->owner == qwen_f32_mover_manifest::kOwnerRepeat,
               "canonical REPEAT profile missing")) {
        return false;
    }

    ggml_init_params parameters = {2 * 1024 * 1024, nullptr, true};
    ggml_context * context = ggml_init(parameters);
    if (!check(context != nullptr, "REPEAT context allocation failed")) {
        return false;
    }
    ggml_tensor * base =
        ggml_new_tensor_2d(context, GGML_TYPE_F32, kD, kO);
    ggml_tensor * source = ggml_permute(context, base, 0, 2, 1, 3);
    ggml_tensor * output =
        ggml_repeat_4d(context, source, kD, kR, kO, 1);
    ggml_cgraph * graph = ggml_new_graph(context);
    ggml_build_forward_expand(graph, output);
    bool passed = true;
    passed &= check(base != nullptr && source != nullptr &&
                        output != nullptr && graph != nullptr &&
                        source->op == GGML_OP_PERMUTE &&
                        source->view_src == base &&
                        output->op == GGML_OP_REPEAT,
                    "real ggml_permute->ggml_repeat graph construction failed");
    passed &= check(apply_tensor_spec(source, profile->src0, base) &&
                        apply_tensor_spec(output, profile->dst),
                    "canonical REPEAT metadata application failed");
    ggml_set_name(source, node->src0_name);
    ggml_set_name(output, node->dst_name);
    passed &= check(output->src[0] == source && output->src[1] == nullptr &&
                        ggml_nbytes(source) == kSrcBytes &&
                        ggml_nbytes(output) == kDstBytes &&
                        ggml_backend_dev_supports_op(api.device, output),
                    "canonical REPEAT source/layout relation changed");

    mapped_tensor source_map;
    mapped_tensor output_map;
    passed &= check(source_map.allocate(api, base, kSrcBytes),
                    "REPEAT source mapping failed");
    passed &= check(ggml_backend_view_init(source) == GGML_STATUS_SUCCESS &&
                        source->data == base->data,
                    "REPEAT permuted view mapping failed");
    passed &= check(output_map.allocate(api, output, kDstBytes),
                    "REPEAT output mapping failed");
    if (!passed) {
        output_map.release();
        source_map.release();
        ggml_free(context);
        return false;
    }

    auto * src = static_cast<std::uint8_t *>(source_map.storage);
    auto * dst = static_cast<std::uint8_t *>(output_map.storage);
    for (std::size_t outer = 0; outer < kO; ++outer) {
        for (std::size_t element = 0; element < kD; ++element) {
            const std::size_t pattern =
                (outer * 5 + element) % kRawPattern.size();
            store_u32_le(src + outer * 512 + element * 4,
                         kRawPattern[pattern]);
        }
    }
    std::memset(dst, 0xa5, kDstBytes);
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "REPEAT positive bind/audit begin failed");
    const std::uint64_t dispatch_id = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "full canonical F32 ggml_repeat compute failed");
    ggml_npu_audit_snapshot_v2 snapshot = {};
    passed &= check(api.audit_end(api.backend, dispatch_id, &snapshot),
                    "REPEAT positive audit failed to close");
    passed &= exact_success_audit(snapshot, 262144);
    bool raw_match = true;
    for (std::size_t outer = 0; outer < kO; ++outer) {
        for (std::size_t repeat = 0; repeat < kR; ++repeat) {
            for (std::size_t element = 0; element < kD; ++element) {
                const std::size_t pattern =
                    (outer * 5 + element) % kRawPattern.size();
                const std::size_t offset =
                    outer * 65536 + repeat * 512 + element * 4;
                raw_match &= load_u32_le(dst + offset) ==
                             kRawPattern[pattern];
            }
        }
    }
    passed &= check(raw_match,
                    "REPEAT poisoned 1MiB raw-bit oracle mismatch");

    void * saved_source_data = source->data;
    source->data = output->data;
    passed &= check(bind_and_begin(
                        api, *node, output,
                        (*next_binding_id)++, (*next_dispatch_id)++),
                    "REPEAT alias bind/audit begin failed");
    const std::uint64_t alias_dispatch = *next_dispatch_id - 1;
    passed &= check(ggml_backend_graph_compute(api.backend, graph) ==
                        GGML_STATUS_FAILED,
                    "REPEAT source/destination alias was accepted");
    source->data = saved_source_data;
    ggml_npu_audit_snapshot_v2 alias_snapshot = {};
    passed &= check(!api.audit_end(
                         api.backend, alias_dispatch, &alias_snapshot) &&
                        alias_snapshot.required_enqueued == 0 &&
                        alias_snapshot.commands_accepted == 0 &&
                        alias_snapshot.coverage_missing == 1,
                    "REPEAT alias did not fail before enqueue");

    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-REPEAT][PASS] "
            "graph=real-ggml_permute-to-ggml_repeat "
            "shape=[128,1,16]->[128,128,16] raw_fp32=262144/262144 "
            "poisoned_output=1048576/1048576 required_issued=1 "
            "required_completed=1 commands=1/1/0 gmem_read=0 gmem_write=0 "
            "portal_read=8192 portal_write=1048576 portal_groups=16512 "
            "elements=262144 identity=full256 "
            "private_commit=success-only cpu_fallback_attempts=0 "
            "host_tensor_arithmetic=0 negative=alias\n");
    }

    output_map.release();
    source_map.release();
    ggml_free(context);
    return passed;
}

} // namespace

int main(int argc, char ** argv) {
    if (!check(argc == 2, "expected backend DSO path")) {
        return 70;
    }
    backend_api api;
    if (!check(api.load(argv[1]), "dynamic backend/API load failed")) {
        api.close();
        return 71;
    }
    ggml_init_params metadata_parameters = {
        8 * 1024 * 1024,
        nullptr,
        true,
    };
    ggml_context * metadata_context = ggml_init(metadata_parameters);
    if (!check(metadata_context != nullptr,
               "metadata context allocation failed")) {
        api.close();
        return 72;
    }
    std::array<ggml_tensor *, qwen_f32_mover_manifest::kProfileCount>
        profile_ops = {};
    std::uint64_t next_binding_id = kBindingBase;
    std::uint64_t next_dispatch_id = kDispatchBase + 1;
    bool passed = run_manifest_and_negative_tests(
        api, metadata_context, &profile_ops, &next_binding_id);
    passed &= run_real_get_rows(
        api, &next_binding_id, &next_dispatch_id);
    passed &= run_empty_gets(
        api, &next_binding_id, &next_dispatch_id);
    passed &= run_terminal_empty_get(
        api, &next_binding_id, &next_dispatch_id);
    passed &= run_real_repeat(
        api, &next_binding_id, &next_dispatch_id);
    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-MOVER][PASS] canonical_set=91 "
            "get_rows=73 repeat=18 empty_get=36 profiles=6 "
            "owners=f32-get-rows+f32-repeat-exclusive-from-f32-alu+q8-get+q8-gemv "
            "actual_graphs=get1024+empty18432+empty262144+terminal-empty1024+repeat1MiB "
            "required_issued=5 required_completed=5 identity=full256 "
            "cpu_fallback_attempts=0 host_tensor_arithmetic=0 "
            "canonical_sha=%s profile_sha=%s checks=%d\n",
            qwen_f32_mover_manifest::kCanonicalSetSha256,
            qwen_f32_mover_manifest::kProfileSetSha256,
            checks);
    }
    ggml_free(metadata_context);
    api.close();
    return passed ? 0 : 73;
}
