#include "npu-compiled-backend-api.h"

#include "ggml-backend-impl.h"
#include "ggml-impl.h"
#include "npu-compiled-bundle.h"
#include "npu-host-runtime.h"
#include "npu-ggml-manifest.h"

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <mutex>
#include <new>
#include <sstream>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

namespace {

constexpr std::uint64_t kContextMagic = 0x4e5055434f4d5031ULL;
constexpr std::uint32_t kF32AluKernel = 0x514e0010U;
constexpr std::uint32_t kF32Dtype = 1U;
constexpr std::size_t kMissingIndex = static_cast<std::size_t>(-1);

struct compiled_node_binding {
    bool bound = false;
    std::uint64_t artifact_node_id = 0U;
    ggml_tensor * tensor = nullptr;
    std::int32_t graph_index = -1;
    void * sealed_data = nullptr;
    std::size_t sealed_nbytes = 0U;
};

struct compiled_buffer_binding {
    bool bound = false;
    ggml_tensor * tensor = nullptr;
    std::uint64_t tensor_offset = 0U;
    std::uint64_t bytes = 0U;
    void * sealed_data = nullptr;
    std::size_t sealed_nbytes = 0U;
    std::uintptr_t sealed_begin = 0U;
    std::uintptr_t sealed_end = 0U;
};

struct full_graph_node_snapshot {
    ggml_tensor * tensor = nullptr;
    std::array<ggml_tensor *, GGML_MAX_SRC> sources = {};
    enum ggml_op op = GGML_OP_NONE;
    std::int32_t flags = 0;
};

struct compiled_backend_context {
    std::uint64_t magic = kContextMagic;
    ggml_npu_compiled_plan_state_v1 state =
        GGML_NPU_COMPILED_PLAN_EMPTY_V1;
    ggml_npu_compiled_plan_error_v1 error =
        GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1;
    std::string failure;
    npu_compiled_bundle bundle;
    npu_ggml_manifest_plan manifest_plan;
    std::vector<compiled_node_binding> nodes;
    std::vector<compiled_buffer_binding> buffers;
    ggml_cgraph * full_graph = nullptr;
    std::vector<full_graph_node_snapshot> full_graph_nodes;
    std::unique_ptr<npu_host_runtime> runtime;
    std::uint64_t compute_attempts = 0U;
    std::uint64_t execute_calls = 0U;
    std::uint64_t successful_bundles = 0U;
    std::uint64_t last_generation = 0U;
};

struct pointer_range {
    std::uintptr_t begin = 0U;
    std::uintptr_t end = 0U;
    std::size_t buffer_index = 0U;
};

std::mutex g_registry_mutex;
compiled_backend_context * g_live_context = nullptr;
compiled_backend_context * g_active_context = nullptr;
thread_local std::string g_last_error_copy;

ggml_guid_t compiled_guid() {
    static ggml_guid guid = {
        0x4e, 0x50, 0x55, 0x2d, 0x43, 0x4f, 0x4d, 0x50,
        0x49, 0x4c, 0x45, 0x44, 0x2d, 0x56, 0x31, 0x00,
    };
    return &guid;
}

bool is_metadata_op(enum ggml_op op) {
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

void set_error(
        compiled_backend_context * context,
        ggml_npu_compiled_plan_error_v1 error,
        const std::string & failure) noexcept {
    if (context == nullptr) {
        return;
    }
    context->error = error;
    try {
        context->failure = failure;
    } catch (...) {
        context->failure.clear();
    }
}

void set_error(
        compiled_backend_context * context,
        ggml_npu_compiled_plan_error_v1 error,
        const char * failure) noexcept {
    if (context == nullptr) {
        return;
    }
    context->error = error;
    try {
        context->failure = failure == nullptr ? "" : failure;
    } catch (...) {
        context->failure.clear();
    }
}

void clear_error(compiled_backend_context * context) noexcept {
    if (context != nullptr) {
        context->error = GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1;
        context->failure.clear();
    }
}

compiled_backend_context * context_from_backend(ggml_backend_t backend) {
    if (backend == nullptr || backend->guid != compiled_guid() ||
        backend->context == nullptr) {
        return nullptr;
    }
    auto * context =
        static_cast<compiled_backend_context *>(backend->context);
    if (context->magic != kContextMagic) {
        return nullptr;
    }
    return context;
}

void record_backend_exception(
        ggml_backend_t backend,
        ggml_npu_compiled_plan_error_v1 error,
        const char * failure) noexcept {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        set_error(context_from_backend(backend), error, failure);
    } catch (...) {
        // There is no safe observable context if even the registry mutex
        // cannot be acquired.  Never allow a C ABI exception to escape.
    }
}

std::string bundle_failure(
        const npu_compiled_bundle_diagnostic & diagnostic) {
    std::ostringstream stream;
    stream << npu_compiled_bundle_error_string(diagnostic.error);
    if (!diagnostic.path.empty()) {
        stream << " at " << diagnostic.path;
    }
    if (!diagnostic.detail.empty()) {
        stream << ": " << diagnostic.detail;
    }
    if (diagnostic.command_index != kMissingIndex) {
        stream << " (command " << diagnostic.command_index << ')';
    }
    if (diagnostic.relocation_index != kMissingIndex) {
        stream << " (relocation " << diagnostic.relocation_index << ')';
    }
    return stream.str();
}

void reset_plan(compiled_backend_context * context) {
    if (context == nullptr) {
        return;
    }
    if (g_active_context == context) {
        g_active_context = nullptr;
    }
    context->runtime.reset();
    context->bundle = npu_compiled_bundle();
    context->manifest_plan = npu_ggml_manifest_plan();
    context->nodes.clear();
    context->buffers.clear();
    context->full_graph = nullptr;
    context->full_graph_nodes.clear();
    context->state = GGML_NPU_COMPILED_PLAN_EMPTY_V1;
    context->compute_attempts = 0U;
    context->execute_calls = 0U;
    context->successful_bundles = 0U;
    context->last_generation = 0U;
    clear_error(context);
}

bool tensor_static_range(
        const ggml_tensor * tensor,
        std::uint64_t offset,
        std::uint64_t bytes,
        std::size_t * tensor_nbytes,
        std::string * failure) {
    if (tensor == nullptr) {
        if (failure != nullptr) {
            *failure = "tensor is null";
        }
        return false;
    }
    const std::size_t nbytes = ggml_nbytes(tensor);
    if (offset > static_cast<std::uint64_t>(nbytes) ||
        bytes > static_cast<std::uint64_t>(nbytes) - offset ||
        offset > static_cast<std::uint64_t>(
            std::numeric_limits<std::size_t>::max()) ||
        bytes > static_cast<std::uint64_t>(
            std::numeric_limits<std::size_t>::max())) {
        if (failure != nullptr) {
            *failure = "bound byte range exceeds tensor storage";
        }
        return false;
    }

    if (tensor_nbytes != nullptr) {
        *tensor_nbytes = nbytes;
    }
    return true;
}

bool tensor_host_range(
        const ggml_tensor * tensor,
        std::uint64_t offset,
        std::uint64_t bytes,
        std::uintptr_t * begin,
        std::uintptr_t * end,
        std::size_t * tensor_nbytes,
        std::string * failure) {
    if (!tensor_static_range(
            tensor, offset, bytes, tensor_nbytes, failure)) {
        return false;
    }
    if (tensor->data == nullptr) {
        if (failure != nullptr) {
            *failure = "tensor data is null";
        }
        return false;
    }
    if (tensor->buffer != nullptr &&
        !ggml_backend_buffer_is_host(tensor->buffer)) {
        if (failure != nullptr) {
            *failure = "tensor buffer is not host-accessible";
        }
        return false;
    }
    const std::uintptr_t base =
        reinterpret_cast<std::uintptr_t>(tensor->data);
    if (offset > std::numeric_limits<std::uintptr_t>::max() - base) {
        if (failure != nullptr) {
            *failure = "tensor pointer plus offset overflows";
        }
        return false;
    }
    const std::uintptr_t range_begin =
        base + static_cast<std::uintptr_t>(offset);
    if (bytes > std::numeric_limits<std::uintptr_t>::max() - range_begin) {
        if (failure != nullptr) {
            *failure = "tensor byte range overflows";
        }
        return false;
    }
    if (begin != nullptr) {
        *begin = range_begin;
    }
    if (end != nullptr) {
        *end = range_begin + static_cast<std::uintptr_t>(bytes);
    }
    return true;
}

std::size_t find_buffer(
        const npu_compiled_bundle & bundle,
        const std::string & id) {
    for (std::size_t index = 0; index < bundle.buffers.size(); ++index) {
        if (bundle.buffers[index].id == id) {
            return index;
        }
    }
    return kMissingIndex;
}

const npu_compiled_relocation_info * find_relocation(
        const npu_compiled_bundle & bundle,
        std::size_t command_index,
        std::uint32_t word_index) {
    const npu_compiled_relocation_info * found = nullptr;
    for (const npu_compiled_relocation_info & relocation :
         bundle.relocations) {
        if (relocation.command_index == command_index &&
            relocation.word_index == word_index) {
            if (found != nullptr) {
                return nullptr;
            }
            found = &relocation;
        }
    }
    return found;
}

bool resolve_role_buffer(
        const compiled_backend_context & context,
        std::size_t command_index,
        std::uint32_t address_word,
        std::uint32_t window_word,
        bool required,
        std::size_t * buffer_index,
        std::string * failure) {
    const npu_compiled_relocation_info * address = find_relocation(
        context.bundle, command_index, address_word);
    const npu_compiled_relocation_info * window = find_relocation(
        context.bundle, command_index, window_word);
    if (address == nullptr && window == nullptr && !required) {
        *buffer_index = kMissingIndex;
        return true;
    }
    if (address == nullptr || window == nullptr ||
        address->kind != npu_compiled_relocation_kind::iova64 ||
        window->kind != npu_compiled_relocation_kind::window_base64 ||
        address->buffer_id != window->buffer_id) {
        if (failure != nullptr) {
            std::ostringstream stream;
            stream << "command " << command_index << " words "
                   << address_word << '/' << window_word
                   << " are not one paired BufferId role";
            *failure = stream.str();
        }
        return false;
    }
    const std::size_t index = find_buffer(
        context.bundle, address->buffer_id);
    if (index == kMissingIndex) {
        if (failure != nullptr) {
            *failure = "paired relocation references an unknown BufferId";
        }
        return false;
    }
    *buffer_index = index;
    return true;
}

bool params_are_zero(const ggml_tensor * tensor) {
    const auto * bytes = reinterpret_cast<const std::uint8_t *>(
        tensor->op_params);
    for (std::size_t index = 0U; index < sizeof(tensor->op_params);
         ++index) {
        if (bytes[index] != 0U) {
            return false;
        }
    }
    return true;
}

bool dense_flat_f32_tensor(
        const ggml_tensor * tensor,
        std::uint64_t total_elements,
        std::uint64_t logical_bytes) {
    return tensor != nullptr && tensor->type == GGML_TYPE_F32 &&
        tensor->view_src == nullptr && tensor->view_offs == 0U &&
        ggml_nelements(tensor) >= 0 &&
        static_cast<std::uint64_t>(ggml_nelements(tensor)) ==
            total_elements &&
        ggml_nbytes(tensor) == logical_bytes &&
        ggml_is_contiguous(tensor);
}

bool p00_src0_view_tensor(
        const ggml_tensor * tensor,
        std::uint64_t total_elements,
        std::uint64_t logical_bytes,
        bool require_storage) {
    if (tensor == nullptr || tensor->type != GGML_TYPE_F32 ||
        tensor->view_src == nullptr || tensor->src[0] != tensor->view_src ||
        tensor->view_offs != 0U || ggml_nelements(tensor) < 0 ||
        static_cast<std::uint64_t>(ggml_nelements(tensor)) != total_elements ||
        ggml_nbytes(tensor) != logical_bytes || !ggml_is_contiguous(tensor)) {
        return false;
    }
    const ggml_tensor * root = tensor->view_src;
    if (!dense_flat_f32_tensor(root, total_elements, logical_bytes)) {
        return false;
    }
    if (!require_storage) {
        return tensor->data == nullptr || root->data == nullptr ||
            tensor->data == root->data;
    }
    return tensor->data != nullptr && root->data != nullptr &&
        tensor->data == root->data;
}

bool publication_covers(
        const npu_compiled_bundle & bundle,
        const std::string & buffer_id) {
    for (const npu_compiled_publication_entry & entry :
         bundle.publications) {
        if (entry.buffer_id == buffer_id) {
            return true;
        }
    }
    return false;
}

bool validate_buffer_bindings(
        compiled_backend_context * context,
        bool require_storage,
        bool sealed_snapshot,
        std::string * failure,
        ggml_npu_compiled_plan_error_v1 * error) {
    std::vector<pointer_range> ranges;
    try {
        ranges.reserve(context->buffers.size());
    } catch (const std::bad_alloc &) {
        *failure = "could not allocate buffer range validation state";
        *error = GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1;
        return false;
    }

    for (std::size_t index = 0U; index < context->buffers.size(); ++index) {
        const compiled_buffer_binding & binding = context->buffers[index];
        const npu_compiled_buffer_info & metadata =
            context->bundle.buffers[index];
        if (!binding.bound) {
            std::ostringstream stream;
            stream << "missing buffer binding for " << metadata.id;
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_INCOMPLETE_PLAN_V1;
            return false;
        }
        if (binding.bytes != metadata.size) {
            std::ostringstream stream;
            stream << "buffer " << metadata.id
                   << " does not bind its exact artifact size";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1;
            return false;
        }

        std::size_t nbytes = 0U;
        std::string range_failure;
        if (!tensor_static_range(
                binding.tensor,
                binding.tensor_offset,
                binding.bytes,
                &nbytes,
                &range_failure)) {
            std::ostringstream stream;
            stream << "buffer " << metadata.id << ": " << range_failure;
            *failure = stream.str();
            *error = sealed_snapshot
                ? GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1
                : GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1;
            return false;
        }
        if (!require_storage) {
            continue;
        }

        std::uintptr_t begin = 0U;
        std::uintptr_t end = 0U;
        if (!tensor_host_range(
                binding.tensor,
                binding.tensor_offset,
                binding.bytes,
                &begin,
                &end,
                &nbytes,
                &range_failure)) {
            std::ostringstream stream;
            stream << "buffer " << metadata.id << ": " << range_failure;
            *failure = stream.str();
            *error = sealed_snapshot
                ? GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1
                : GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1;
            return false;
        }
        if (sealed_snapshot &&
            (binding.sealed_data != binding.tensor->data ||
             binding.sealed_nbytes != nbytes ||
             binding.sealed_begin != begin || binding.sealed_end != end)) {
            std::ostringstream stream;
            stream << "buffer " << metadata.id
                   << " storage changed after plan seal";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1;
            return false;
        }
        // Only input/output ranges become caller-owned raw capabilities.
        // GGML may legally reuse the storage of a bundle-private transient
        // after its source dies; that storage is never exposed to the host
        // runtime, whose transient lives in its private arena.
        if (metadata.kind == npu_compiled_buffer_kind::input ||
            metadata.kind == npu_compiled_buffer_kind::output) {
            ranges.push_back({begin, end, index});
        }

        if (metadata.kind == npu_compiled_buffer_kind::weight) {
            if (metadata.weights_offset > context->bundle.weights.size() ||
                metadata.size > context->bundle.weights.size() -
                    metadata.weights_offset) {
                *failure = "weight metadata exceeds weights.bin";
                *error = GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1;
                return false;
            }
            const auto * actual = reinterpret_cast<const std::uint8_t *>(
                begin);
            const auto * expected = context->bundle.weights.data() +
                static_cast<std::size_t>(metadata.weights_offset);
            if (std::memcmp(
                    actual,
                    expected,
                    static_cast<std::size_t>(metadata.size)) != 0) {
                std::ostringstream stream;
                stream << "weight buffer " << metadata.id
                       << " differs from weights.bin";
                *failure = stream.str();
                *error = GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1;
                return false;
            }
        }
    }

    std::sort(
        ranges.begin(),
        ranges.end(),
        [](const pointer_range & left, const pointer_range & right) {
            if (left.begin != right.begin) {
                return left.begin < right.begin;
            }
            if (left.end != right.end) {
                return left.end < right.end;
            }
            return left.buffer_index < right.buffer_index;
        });
    for (std::size_t index = 1U; index < ranges.size(); ++index) {
        if (ranges[index - 1U].end > ranges[index].begin) {
            std::ostringstream stream;
            stream << "artifact buffers "
                   << context->bundle.buffers[
                          ranges[index - 1U].buffer_index].id
                   << " and "
                   << context->bundle.buffers[ranges[index].buffer_index].id
                   << " overlap in host storage";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1;
            return false;
        }
    }
    return true;
}

bool validate_graph_contract(
        compiled_backend_context * context,
        bool require_storage,
        bool sealed_snapshot,
        std::string * failure,
        ggml_npu_compiled_plan_error_v1 * error) {
    std::unordered_set<ggml_tensor *> consumed;
    std::unordered_set<std::size_t> transient_destinations;
    std::vector<std::size_t> transient_producers;
    try {
        consumed.reserve(context->nodes.size() * 2U);
        transient_destinations.reserve(context->nodes.size());
        transient_producers.assign(
            context->bundle.buffers.size(), kMissingIndex);
    } catch (const std::bad_alloc &) {
        *failure = "could not allocate graph-contract validation state";
        *error = GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1;
        return false;
    }

    std::int32_t previous_graph_index = -1;
    for (std::size_t command_index = 0U;
         command_index < context->bundle.commands.size();
         ++command_index) {
        const npu_compiled_command_info & command =
            context->bundle.commands[command_index];
        const compiled_node_binding & node_binding =
            context->nodes[command_index];
        if (!node_binding.bound) {
            std::ostringstream stream;
            stream << "missing node binding for artifact node "
                   << command.node_ids[0];
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_INCOMPLETE_PLAN_V1;
            return false;
        }
        if (node_binding.graph_index <= previous_graph_index) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " graph index does not strictly follow artifact "
                      "command order";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        previous_graph_index = node_binding.graph_index;
        ggml_tensor * node = node_binding.tensor;
        if (node == nullptr ||
            (node->flags & GGML_TENSOR_FLAG_COMPUTE) == 0 ||
            is_metadata_op(node->op)) {
            std::ostringstream stream;
            stream << "artifact node " << command.node_ids[0]
                   << " is not one allocated GGML compute node";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_NODE_BINDING_V1;
            return false;
        }
        if (require_storage && node->data == nullptr) {
            std::ostringstream stream;
            stream << "artifact node " << command.node_ids[0]
                   << " has no allocated storage";
            *failure = stream.str();
            *error = sealed_snapshot
                ? GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1
                : GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1;
            return false;
        }
        const std::size_t node_nbytes = ggml_nbytes(node);
        if (sealed_snapshot &&
            (node_binding.sealed_data != node->data ||
             node_binding.sealed_nbytes != node_nbytes)) {
            std::ostringstream stream;
            stream << "artifact node " << command.node_ids[0]
                   << " storage changed after plan seal";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1;
            return false;
        }

        npu_command_abi_words words = {};
        npu_compiled_bundle_diagnostic diagnostic = {};
        if (!npu_compiled_bundle_decode_record(
                context->bundle.command_template,
                command_index,
                &words,
                &diagnostic)) {
            std::ostringstream stream;
            stream << "could not decode command " << command_index << ": "
                   << bundle_failure(diagnostic);
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }

        const std::uint32_t kernel_id =
            static_cast<std::uint32_t>(words[0]);
        const std::uint32_t vector_op =
            static_cast<std::uint32_t>(words[5] >> 32U);
        const std::uint32_t outer_count =
            static_cast<std::uint32_t>(words[9] >> 32U);
        const std::uint32_t local_profile =
            static_cast<std::uint32_t>(words[9]);
        const std::uint64_t element_count = words[15];
        const std::uint32_t dtype =
            static_cast<std::uint32_t>(words[16]);
        const std::uint32_t scalar0 =
            static_cast<std::uint32_t>(words[16] >> 32U);
        if (kernel_id != kF32AluKernel || dtype != kF32Dtype ||
            local_profile != 0U || vector_op != 1U ||
            element_count != 16U || outer_count != 1U || scalar0 != 0U) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " is unsupported: compiled backend v1 supports "
                      "descriptor-compatible dense F32 ADD slice only";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        const std::uint64_t total_elements =
            element_count * static_cast<std::uint64_t>(outer_count);
        if (ggml_nelements(node) < 0 ||
            static_cast<std::uint64_t>(ggml_nelements(node)) !=
                total_elements ||
            total_elements > std::numeric_limits<std::uint64_t>::max() /
                sizeof(float)) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " element_count*outer_count does not match its node";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        const std::uint64_t logical_bytes =
            total_elements * sizeof(float);
        if (element_count > std::numeric_limits<std::uint64_t>::max() /
                sizeof(float)) {
            *failure = "F32 ALU row byte count overflows u64";
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        const std::uint64_t row_bytes = element_count * sizeof(float);

        std::size_t src0_index = kMissingIndex;
        std::size_t src1_index = kMissingIndex;
        std::size_t dst_index = kMissingIndex;
        if (!resolve_role_buffer(
                *context, command_index, 10U, 23U, true,
                &src0_index, failure) ||
            !resolve_role_buffer(
                *context, command_index, 11U, 26U, false,
                &src1_index, failure) ||
            !resolve_role_buffer(
                *context, command_index, 13U, 28U, true,
                &dst_index, failure)) {
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        if (words[12] != 0U || words[14] != 0U) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " uses an unsupported src2 or scratch address";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }

        const npu_compiled_relocation_info * src0_address =
            find_relocation(context->bundle, command_index, 10U);
        const npu_compiled_relocation_info * src0_window =
            find_relocation(context->bundle, command_index, 23U);
        const npu_compiled_relocation_info * src1_address =
            find_relocation(context->bundle, command_index, 11U);
        const npu_compiled_relocation_info * src1_window =
            find_relocation(context->bundle, command_index, 26U);
        const npu_compiled_relocation_info * dst_address =
            find_relocation(context->bundle, command_index, 13U);
        const npu_compiled_relocation_info * dst_window =
            find_relocation(context->bundle, command_index, 28U);
        if (src0_address == nullptr || src0_window == nullptr ||
            dst_address == nullptr || dst_window == nullptr ||
            src0_address->addend != 0U || src0_window->addend != 0U ||
            dst_address->addend != 0U || dst_window->addend != 0U ||
            words[19] != row_bytes || words[20] != row_bytes ||
            words[21] != 0U || words[22] != row_bytes ||
            words[24] != logical_bytes || words[29] != logical_bytes) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " is outside descriptor-compatible profile 0 "
                      "addressing";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }

        const compiled_buffer_binding & src0 = context->buffers[src0_index];
        const compiled_buffer_binding & dst = context->buffers[dst_index];
        const npu_compiled_buffer_info & src0_metadata =
            context->bundle.buffers[src0_index];
        const npu_compiled_buffer_info & dst_metadata =
            context->bundle.buffers[dst_index];
        const bool authority_p00_view_source = p00_src0_view_tensor(
            src0.tensor, total_elements, logical_bytes, require_storage);
        const bool private_chain_source = command_index != 0U &&
            src0_metadata.kind == npu_compiled_buffer_kind::transient &&
            dense_flat_f32_tensor(
                src0.tensor, total_elements, logical_bytes);
        if (node->src[0] == nullptr || src0.tensor != node->src[0] ||
            dst.tensor != node || src0.tensor_offset != 0U ||
            dst.tensor_offset != 0U || src0.bytes != logical_bytes ||
            dst.bytes != logical_bytes ||
            (!authority_p00_view_source && !private_chain_source) ||
            !dense_flat_f32_tensor(
                dst.tensor, total_elements, logical_bytes)) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " src0/dst relocation roles do not match exact "
                      "P00 T16 VIEW src0 and contiguous F32 destination";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }

        if (node->op != GGML_OP_ADD || src1_index == kMissingIndex) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " does not match the P00-shaped F32 ADD slice";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }

        const compiled_buffer_binding & src1 =
            context->buffers[src1_index];
        if (src1_address == nullptr || src1_window == nullptr ||
            src1_address->addend != 0U || src1_window->addend != 0U ||
            words[27] != logical_bytes || node->src[1] == nullptr ||
            src1.tensor != node->src[1] || src1.tensor_offset != 0U ||
            src1.bytes != logical_bytes ||
            !dense_flat_f32_tensor(
                src1.tensor, total_elements, logical_bytes) ||
            !params_are_zero(node)) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " src1/op_params do not match the P00-shaped ADD";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        consumed.insert(node->src[1]);

        const auto validate_transient_source = [
                &context, &transient_producers, command_index,
                failure, error](
                    std::size_t buffer_index,
                    ggml_tensor * source,
                    const char * role) {
            const npu_compiled_buffer_info & metadata =
                context->bundle.buffers[buffer_index];
            if (metadata.kind != npu_compiled_buffer_kind::transient) {
                return true;
            }
            const std::size_t producer =
                transient_producers[buffer_index];
            if (producer == kMissingIndex || producer >= command_index ||
                context->nodes[producer].tensor != source) {
                std::ostringstream stream;
                stream << "command " << command_index << ' ' << role
                       << " transient " << metadata.id
                       << " is not the exact tensor produced by one "
                          "strictly earlier bound command";
                *failure = stream.str();
                *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
                return false;
            }
            return true;
        };
        if (!validate_transient_source(
                src0_index, node->src[0], "src0") ||
            !validate_transient_source(
                src1_index, node->src[1], "src1")) {
            return false;
        }
        for (std::size_t source = 2U; source < GGML_MAX_SRC; ++source) {
            if (node->src[source] != nullptr) {
                std::ostringstream stream;
                stream << "command " << command_index
                       << " has unsupported GGML sources beyond src1";
                *failure = stream.str();
                *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
                return false;
            }
        }
        consumed.insert(node->src[0]);

        if (dst_metadata.kind == npu_compiled_buffer_kind::transient) {
            if (transient_producers[dst_index] != kMissingIndex) {
                std::ostringstream stream;
                stream << "transient destination " << dst_metadata.id
                       << " has multiple dense-slice producers";
                *failure = stream.str();
                *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
                return false;
            }
            transient_producers[dst_index] = command_index;
            transient_destinations.insert(dst_index);
        } else if (dst_metadata.kind != npu_compiled_buffer_kind::output) {
            std::ostringstream stream;
            stream << "command " << command_index
                   << " destination is neither transient nor output";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
    }

    for (std::size_t command_index = 0U;
         command_index < context->nodes.size(); ++command_index) {
        const ggml_tensor * node = context->nodes[command_index].tensor;
        std::size_t dst_index = kMissingIndex;
        if (!resolve_role_buffer(
                *context, command_index, 13U, 28U, true,
                &dst_index, failure)) {
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        const npu_compiled_buffer_info & destination =
            context->bundle.buffers[dst_index];
        const bool terminal = consumed.find(
            const_cast<ggml_tensor *>(node)) == consumed.end();
        if (terminal &&
            (destination.kind != npu_compiled_buffer_kind::output ||
             !publication_covers(context->bundle, destination.id))) {
            std::ostringstream stream;
            stream << "terminal command " << command_index
                   << " is not a published output";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
        if (destination.kind == npu_compiled_buffer_kind::transient &&
            terminal) {
            std::ostringstream stream;
            stream << "transient destination " << destination.id
                   << " is not consumed by a later bound compute node";
            *failure = stream.str();
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
    }

    for (std::size_t index : transient_destinations) {
        bool is_consumed = false;
        for (const compiled_node_binding & binding : context->nodes) {
            if (consumed.find(binding.tensor) != consumed.end() &&
                context->buffers[index].tensor == binding.tensor) {
                is_consumed = true;
                break;
            }
        }
        if (!is_consumed) {
            *failure = "artifact transient is not in the bound compute chain";
            *error = GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1;
            return false;
        }
    }
    return true;
}

bool validate_plan(
        compiled_backend_context * context,
        bool require_storage,
        bool sealed_snapshot,
        std::string * failure,
        ggml_npu_compiled_plan_error_v1 * error) {
    if (!validate_buffer_bindings(
            context, require_storage, sealed_snapshot, failure, error)) {
        return false;
    }
    return validate_graph_contract(
        context, require_storage, sealed_snapshot, failure, error);
}

bool validate_full_graph_at_seal(
        compiled_backend_context * context,
        ggml_cgraph * graph,
        std::string * failure) {
    if (graph == nullptr) {
        *failure = "seal requires the complete original GGML graph";
        return false;
    }
    const int graph_nodes = ggml_graph_n_nodes(graph);
    if (graph_nodes < 0) {
        *failure = "full graph reports a negative node count";
        return false;
    }

    std::unordered_set<const ggml_tensor *> bound_nodes;
    std::vector<bool> consumed_by_bound(context->nodes.size(), false);
    try {
        bound_nodes.reserve(context->nodes.size());
        for (const compiled_node_binding & binding : context->nodes) {
            if (binding.graph_index < 0 ||
                binding.graph_index >= graph_nodes ||
                ggml_graph_node(graph, binding.graph_index) !=
                    binding.tensor ||
                !bound_nodes.insert(binding.tensor).second) {
                *failure =
                    "bound node pointer does not match its whole-graph index";
                return false;
            }
        }
    } catch (const std::bad_alloc &) {
        *failure = "could not allocate whole-graph seal state";
        return false;
    }

    const std::int32_t first_index = context->nodes.front().graph_index;
    const std::int32_t last_index = context->nodes.back().graph_index;
    for (std::int32_t graph_index = first_index;
         graph_index <= last_index; ++graph_index) {
        const ggml_tensor * node = ggml_graph_node(graph, graph_index);
        if (node != nullptr &&
            (node->flags & GGML_TENSOR_FLAG_COMPUTE) != 0 &&
            !is_metadata_op(node->op) &&
            bound_nodes.count(node) == 0U) {
            *failure =
                "an unbound compute node splits the compiled command range";
            return false;
        }
    }

    for (int graph_index = 0; graph_index < graph_nodes; ++graph_index) {
        const ggml_tensor * consumer = ggml_graph_node(graph, graph_index);
        if (consumer == nullptr) {
            *failure = "full graph contains a null node";
            return false;
        }
        for (std::size_t source = 0U; source < GGML_MAX_SRC; ++source) {
            const ggml_tensor * producer = consumer->src[source];
            if (producer == nullptr || bound_nodes.count(producer) == 0U) {
                continue;
            }
            std::size_t producer_index = kMissingIndex;
            std::size_t consumer_index = kMissingIndex;
            for (std::size_t command_index = 0U;
                 command_index < context->nodes.size(); ++command_index) {
                if (context->nodes[command_index].tensor == producer) {
                    producer_index = command_index;
                }
                if (context->nodes[command_index].tensor == consumer) {
                    consumer_index = command_index;
                }
            }
            if (producer_index == kMissingIndex) {
                *failure = "bound producer lookup failed";
                return false;
            }

            std::size_t dst_index = kMissingIndex;
            if (!resolve_role_buffer(
                    *context, producer_index, 13U, 28U, true,
                    &dst_index, failure)) {
                return false;
            }
            const npu_compiled_buffer_info & destination =
                context->bundle.buffers[dst_index];
            if (consumer_index != kMissingIndex) {
                if (consumer_index <= producer_index) {
                    *failure =
                        "bound compute dependency contradicts command order";
                    return false;
                }
                consumed_by_bound[producer_index] = true;
            } else if (destination.kind ==
                       npu_compiled_buffer_kind::transient) {
                *failure =
                    "private transient has a consumer outside the compiled "
                    "bundle";
                return false;
            }
        }
    }

    for (std::size_t command_index = 0U;
         command_index < context->nodes.size(); ++command_index) {
        std::size_t dst_index = kMissingIndex;
        if (!resolve_role_buffer(
                *context, command_index, 13U, 28U, true,
                &dst_index, failure)) {
            return false;
        }
        const npu_compiled_buffer_info & destination =
            context->bundle.buffers[dst_index];
        if (destination.kind == npu_compiled_buffer_kind::transient &&
            !consumed_by_bound[command_index]) {
            *failure =
                "private transient is not consumed by a later bundle command";
            return false;
        }
        if (!consumed_by_bound[command_index] &&
            destination.kind != npu_compiled_buffer_kind::output) {
            *failure = "terminal bundle command is not an output";
            return false;
        }
    }
    return true;
}

bool snapshot_full_graph(
        compiled_backend_context * context,
        ggml_cgraph * graph,
        std::string * failure) {
    const int graph_nodes = ggml_graph_n_nodes(graph);
    std::vector<full_graph_node_snapshot> candidate;
    try {
        candidate.reserve(static_cast<std::size_t>(graph_nodes));
        for (int index = 0; index < graph_nodes; ++index) {
            ggml_tensor * tensor = ggml_graph_node(graph, index);
            full_graph_node_snapshot snapshot;
            snapshot.tensor = tensor;
            snapshot.op = tensor->op;
            snapshot.flags = tensor->flags;
            for (std::size_t source = 0U; source < GGML_MAX_SRC; ++source) {
                snapshot.sources[source] = tensor->src[source];
            }
            candidate.push_back(snapshot);
        }
    } catch (const std::bad_alloc &) {
        *failure = "could not allocate full-graph snapshot";
        return false;
    }
    context->full_graph = graph;
    context->full_graph_nodes.swap(candidate);
    return true;
}

bool revalidate_full_graph_snapshot(
        compiled_backend_context * context,
        std::string * failure) {
    if (context->full_graph == nullptr ||
        ggml_graph_n_nodes(context->full_graph) !=
            static_cast<int>(context->full_graph_nodes.size())) {
        *failure = "sealed full graph no longer has its original node count";
        return false;
    }
    for (std::size_t index = 0U;
         index < context->full_graph_nodes.size(); ++index) {
        const full_graph_node_snapshot & snapshot =
            context->full_graph_nodes[index];
        ggml_tensor * tensor = ggml_graph_node(
            context->full_graph, static_cast<int>(index));
        if (tensor != snapshot.tensor || tensor == nullptr ||
            tensor->op != snapshot.op || tensor->flags != snapshot.flags) {
            std::ostringstream stream;
            stream << "full graph node " << index
                   << " changed after plan seal";
            *failure = stream.str();
            return false;
        }
        for (std::size_t source = 0U; source < GGML_MAX_SRC; ++source) {
            if (tensor->src[source] != snapshot.sources[source]) {
                std::ostringstream stream;
                stream << "full graph node " << index << " source "
                       << source << " changed after plan seal";
                *failure = stream.str();
                return false;
            }
        }
    }
    if (context->manifest_plan.proof &&
        !npu_ggml_manifest_revalidate(context->manifest_plan, context->full_graph, failure))
        return false;
    return validate_full_graph_at_seal(
        context, context->full_graph, failure);
}

bool validate_graph_instance(
        compiled_backend_context * context,
        ggml_cgraph * graph,
        std::string * failure) {
    if (graph == nullptr) {
        *failure = "graph is null";
        return false;
    }
    const int graph_nodes = ggml_graph_n_nodes(graph);
    if (graph_nodes < 0) {
        *failure = "graph reports a negative node count";
        return false;
    }

    std::vector<const ggml_tensor *> compute_nodes;
    std::unordered_set<const ggml_tensor *> compute_lineage;
    try {
        compute_nodes.reserve(context->nodes.size());
        compute_lineage.reserve(context->nodes.size() * 2U);
        for (const compiled_node_binding & binding : context->nodes) {
            compute_lineage.insert(binding.tensor);
        }
    } catch (const std::bad_alloc &) {
        *failure = "could not allocate graph preflight state";
        return false;
    }

    for (int graph_index = 0; graph_index < graph_nodes; ++graph_index) {
        ggml_tensor * node = ggml_graph_node(graph, graph_index);
        if (node == nullptr) {
            *failure = "graph contains a null node";
            return false;
        }
        if (is_metadata_op(node->op)) {
            for (std::size_t source = 0U; source < GGML_MAX_SRC; ++source) {
                if (node->src[source] != nullptr &&
                    compute_lineage.find(node->src[source]) !=
                        compute_lineage.end()) {
                    *failure =
                        "v1 rejects metadata nodes derived from compiled "
                        "compute results";
                    return false;
                }
            }
            continue;
        }
        if ((node->flags & GGML_TENSOR_FLAG_COMPUTE) == 0) {
            continue;
        }
        if (context->manifest_plan.proof && compute_lineage.count(node) == 0U) {
            int original_index = -1;
            for (std::size_t i = 0; i < context->full_graph_nodes.size(); ++i)
                if (context->full_graph_nodes[i].tensor == node) original_index = static_cast<int>(i);
            std::ostringstream stream;
            stream << "required NPU node graph_index=" << original_index
                   << " name=" << ggml_get_name(node) << " op=" << ggml_op_name(node->op)
                   << " is not covered by this compiled artifact; CPU tensor fallback is forbidden";
            *failure = stream.str();
            return false;
        }
        compute_nodes.push_back(node);
    }

    if (compute_nodes.size() != context->nodes.size()) {
        std::ostringstream stream;
        stream << "graph split has " << compute_nodes.size()
               << " compiled compute nodes, expected "
               << context->nodes.size() << "; ops=";
        for (const ggml_tensor * node : compute_nodes) {
            stream << ' ' << ggml_op_name(node->op) << '@' << node;
        }
        stream << "; expected=";
        for (const compiled_node_binding & binding : context->nodes) {
            stream << ' ' << binding.tensor;
        }
        *failure = stream.str();
        return false;
    }
    for (std::size_t command_index = 0U;
         command_index < context->nodes.size(); ++command_index) {
        if (compute_nodes[command_index] !=
            context->nodes[command_index].tensor) {
            std::ostringstream stream;
            stream << "graph split compute pointer at local index "
                   << command_index
                   << " does not match artifact command order";
            *failure = stream.str();
            return false;
        }
    }
    return true;
}

void snapshot_plan(compiled_backend_context * context) {
    for (compiled_node_binding & binding : context->nodes) {
        binding.sealed_data = binding.tensor->data;
        binding.sealed_nbytes = ggml_nbytes(binding.tensor);
    }
    for (compiled_buffer_binding & binding : context->buffers) {
        std::uintptr_t begin = 0U;
        std::uintptr_t end = 0U;
        std::size_t nbytes = 0U;
        std::string unused;
        const bool valid = tensor_host_range(
            binding.tensor,
            binding.tensor_offset,
            binding.bytes,
            &begin,
            &end,
            &nbytes,
            &unused);
        GGML_ASSERT(valid);
        binding.sealed_data = binding.tensor->data;
        binding.sealed_nbytes = nbytes;
        binding.sealed_begin = begin;
        binding.sealed_end = end;
    }
}

enum ggml_status compiled_graph_compute(
        ggml_backend_t backend,
        ggml_cgraph * graph) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return GGML_STATUS_FAILED;
        }
        ggml_cgraph artifact_graph = {};
        ++context->compute_attempts;
        if (context->state != GGML_NPU_COMPILED_PLAN_SEALED_V1 ||
            g_active_context != context) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
                "compiled graph_compute requires this backend's active "
                "sealed plan");
            return GGML_STATUS_FAILED;
        }

        std::string failure;
        ggml_npu_compiled_plan_error_v1 error =
            GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1;
        if (!revalidate_full_graph_snapshot(context, &failure)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_MISMATCH_V1,
                std::move(failure));
            return GGML_STATUS_FAILED;
        }
        if (graph == nullptr && context->manifest_plan.proof &&
            context->state == GGML_NPU_COMPILED_PLAN_SEALED_V1) {
            artifact_graph = ggml_graph_view(context->full_graph,
                context->nodes.front().graph_index, context->nodes.back().graph_index + 1);
            graph = &artifact_graph;
        }
        if (!validate_graph_instance(context, graph, &failure)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_MISMATCH_V1,
                std::move(failure));
            return GGML_STATUS_FAILED;
        }
        const bool have_runtime = context->runtime != nullptr;
        if (!validate_plan(
                context, true, have_runtime, &failure, &error)) {
            set_error(context, error, std::move(failure));
            return GGML_STATUS_FAILED;
        }

        if (!have_runtime) {
            std::unique_ptr<npu_host_runtime> runtime(
                new (std::nothrow) npu_host_runtime());
            if (runtime == nullptr) {
                set_error(
                    context,
                    GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
                    "could not allocate production host runtime");
                return GGML_STATUS_ALLOC_FAILED;
            }
            if (!runtime->ready() || runtime->fatal()) {
                std::ostringstream stream;
                stream << npu_host_runtime_error_string(
                              runtime->last_error())
                       << ": " << runtime->failure();
                set_error(
                    context,
                    GGML_NPU_COMPILED_PLAN_ERROR_RUNTIME_NOT_READY_V1,
                    stream.str());
                return GGML_STATUS_FAILED;
            }
            snapshot_plan(context);
            context->runtime = std::move(runtime);
        }

        npu_host_runtime_request request;
        request.inputs.reserve(context->bundle.buffers.size());
        request.outputs.reserve(context->bundle.buffers.size());
        for (std::size_t index = 0U;
             index < context->bundle.buffers.size(); ++index) {
            const npu_compiled_buffer_info & metadata =
                context->bundle.buffers[index];
            const compiled_buffer_binding & binding =
                context->buffers[index];
            auto * data = static_cast<std::uint8_t *>(binding.tensor->data) +
                static_cast<std::size_t>(binding.tensor_offset);
            if (metadata.kind == npu_compiled_buffer_kind::input) {
                request.inputs.push_back({
                    metadata.id,
                    data,
                    static_cast<std::size_t>(metadata.size),
                });
            } else if (metadata.kind ==
                       npu_compiled_buffer_kind::output) {
                request.outputs.push_back({
                    metadata.id,
                    data,
                    static_cast<std::size_t>(metadata.size),
                });
            }
        }

        ++context->execute_calls;
        npu_host_runtime_result result = {};
        if (!context->runtime->execute(
                context->bundle, request, &result)) {
            std::ostringstream stream;
            stream << npu_host_runtime_error_string(
                          context->runtime->last_error())
                   << ": " << context->runtime->failure();
            if (result.submitted) {
                stream << " generation=" << result.generation
                       << " completed=" << result.executor.completed
                       << " mailbox_error=" << result.executor.mailbox_error;
                if (result.executor.completed != 0U) {
                    const auto index = result.executor.completed - 1U;
                    stream << " command=" << index;
                    if (index < context->bundle.provenance_nodes.size())
                        stream << " canonical=" << context->bundle.provenance_nodes[index].canonical_id;
                    stream << " completion_status=" << result.executor.completion_status
                           << " mcause=" << result.executor.fault_cause
                           << " mtval=0x" << std::hex << result.executor.fault_tval
                           << " mepc=0x" << result.executor.fault_pc << std::dec;
                }
            }
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_RUNTIME_EXECUTE_V1,
                stream.str());
            return GGML_STATUS_FAILED;
        }
        if (!result.submitted || !result.published ||
            result.generation == 0U) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_RUNTIME_EXECUTE_V1,
                "host runtime reported success without one published "
                "generation");
            return GGML_STATUS_FAILED;
        }
        ++context->successful_bundles;
        context->last_generation = result.generation;
        clear_error(context);
        return GGML_STATUS_SUCCESS;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed during compiled graph_compute");
        return GGML_STATUS_ALLOC_FAILED;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception during compiled graph_compute");
        return GGML_STATUS_FAILED;
    }
}

const char * backend_name(ggml_backend_t) {
    return "NPU-COMPILED";
}

void backend_free(ggml_backend_t backend) {
    if (backend == nullptr) {
        return;
    }
    std::unique_ptr<npu_host_runtime> runtime;
    compiled_backend_context * context = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        context = context_from_backend(backend);
        if (context != nullptr) {
            if (g_active_context == context) {
                g_active_context = nullptr;
            }
            if (g_live_context == context) {
                g_live_context = nullptr;
            }
            runtime = std::move(context->runtime);
            context->magic = 0U;
            backend->context = nullptr;
        }
    }
    delete context;
    delete backend;
}

const ggml_backend_i backend_interface = {
    backend_name,
    backend_free,
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
    compiled_graph_compute,
    nullptr,
    nullptr,
    nullptr,
};

const char * device_name(ggml_backend_dev_t) {
    return "NPU-COMPILED";
}

const char * device_description(ggml_backend_dev_t) {
    return "Compiled-bundle-only RISC-V Tensor NPU backend";
}

void device_memory(ggml_backend_dev_t, std::size_t * free, std::size_t * total) {
    if (free != nullptr) {
        *free = 0U;
    }
    if (total != nullptr) {
        *total = 0U;
    }
}

enum ggml_backend_dev_type device_type(ggml_backend_dev_t) {
    return GGML_BACKEND_DEVICE_TYPE_ACCEL;
}

void device_properties(
        ggml_backend_dev_t device,
        ggml_backend_dev_props * properties) {
    if (properties == nullptr) {
        return;
    }
    properties->name = device_name(device);
    properties->description = device_description(device);
    device_memory(device, &properties->memory_free, &properties->memory_total);
    properties->type = device_type(device);
    properties->device_id = nullptr;
    properties->caps = {
        false,
        false,
        true,
        false,
        true,
    };
}

ggml_backend_buffer_type_t device_buffer_type(ggml_backend_dev_t) {
    return ggml_backend_cpu_buffer_type();
}

ggml_backend_buffer_t device_buffer_from_host(
        ggml_backend_dev_t,
        void * pointer,
        std::size_t size,
        std::size_t) {
    if (pointer == nullptr && size != 0U) {
        return nullptr;
    }
    return ggml_backend_cpu_buffer_from_ptr(pointer, size);
}

bool device_supports_op(
        ggml_backend_dev_t,
        const ggml_tensor * op) {
    if (op == nullptr) {
        return false;
    }
    if (is_metadata_op(op->op)) {
        return true;
    }
    std::lock_guard<std::mutex> lock(g_registry_mutex);
    if (g_active_context == nullptr ||
        g_active_context->state != GGML_NPU_COMPILED_PLAN_SEALED_V1) {
        return false;
    }
    // Canonical manifests define required NPU work. Keep every original
    // compute node on this device so an uncovered node fails graph_compute
    // instead of silently becoming a CPU tensor fallback.
    if (g_active_context->manifest_plan.proof) {
        for (const auto & node : g_active_context->full_graph_nodes)
            if (node.tensor == op) return true;
    }
    for (const compiled_node_binding & binding : g_active_context->nodes) {
        if (binding.tensor == op) {
            return true;
        }
    }
    return false;
}

bool device_supports_buffer(
        ggml_backend_dev_t,
        ggml_backend_buffer_type_t buffer_type) {
    return buffer_type != nullptr && ggml_backend_buft_is_host(buffer_type);
}

ggml_backend_t device_init_backend(
        ggml_backend_dev_t device,
        const char *) {
    std::lock_guard<std::mutex> lock(g_registry_mutex);
    if (g_live_context != nullptr) {
        return nullptr;
    }
    auto * context = new (std::nothrow) compiled_backend_context;
    if (context == nullptr) {
        return nullptr;
    }
    auto * backend = new (std::nothrow) ggml_backend {
        compiled_guid(),
        backend_interface,
        device,
        context,
    };
    if (backend == nullptr) {
        delete context;
        return nullptr;
    }
    g_live_context = context;
    return backend;
}

const ggml_backend_device_i device_interface = {
    device_name,
    device_description,
    device_memory,
    device_type,
    device_properties,
    device_init_backend,
    device_buffer_type,
    nullptr,
    device_buffer_from_host,
    device_supports_op,
    device_supports_buffer,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
};

const char * registry_name(ggml_backend_reg_t) {
    return "NPU-COMPILED";
}

std::size_t registry_device_count(ggml_backend_reg_t) {
    return 1U;
}

ggml_backend_dev_t registry_device(
        ggml_backend_reg_t registry,
        std::size_t index) {
    if (index != 0U) {
        return nullptr;
    }
    static ggml_backend_device device = {
        device_interface,
        registry,
        nullptr,
    };
    return &device;
}

void * registry_proc_address(ggml_backend_reg_t, const char * name) {
    if (name == nullptr) {
        return nullptr;
    }
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_AUDIT_V2_PROC) == 0)
        return reinterpret_cast<void *>(ggml_backend_npu_compiled_plan_audit_v2);
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_BIND_GRAPH_V2_PROC) == 0)
        return reinterpret_cast<void *>(ggml_backend_npu_compiled_plan_bind_graph_v2);
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_LAUNCH_V2_PROC) == 0)
        return reinterpret_cast<void *>(ggml_backend_npu_compiled_plan_launch_v2);
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_LOAD_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_load_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_COMPILED_PLAN_BIND_NODE_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_bind_node_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_COMPILED_PLAN_BIND_BUFFER_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_bind_buffer_v1);
    }
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_SEAL_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_seal_v1);
    }
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_CLEAR_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_clear_v1);
    }
    if (std::strcmp(name, GGML_NPU_COMPILED_PLAN_STATUS_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_status_v1);
    }
    if (std::strcmp(
            name, GGML_NPU_COMPILED_PLAN_LAST_ERROR_V1_PROC) == 0) {
        return reinterpret_cast<void *>(
            ggml_backend_npu_compiled_plan_last_error_v1);
    }
    return nullptr;
}

const ggml_backend_reg_i registry_interface = {
    registry_name,
    registry_device_count,
    registry_device,
    registry_proc_address,
};

int backend_score() {
    return 1;
}

} // namespace

extern "C" bool ggml_backend_npu_compiled_plan_load_v1(
        ggml_backend_t backend,
        const char * bundle_directory) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        reset_plan(context);
        if (bundle_directory == nullptr || bundle_directory[0] == '\0') {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_ARGUMENT_V1,
                "bundle directory is empty");
            return false;
        }

        npu_compiled_bundle candidate;
        npu_compiled_bundle_diagnostic diagnostic = {};
        if (!npu_compiled_bundle_load(
                bundle_directory, &candidate, &diagnostic)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_BUNDLE_LOAD_V1,
                bundle_failure(diagnostic));
            return false;
        }
        std::unordered_set<std::uint64_t> node_ids;
        node_ids.reserve(candidate.commands.size());
        for (std::size_t index = 0U; index < candidate.commands.size();
             ++index) {
            const npu_compiled_command_info & command =
                candidate.commands[index];
            if (command.index != index ||
                command.owner != npu_compiled_command_owner::f32_alu ||
                command.node_ids.size() != 1U ||
                command.identity.kernel_id != kF32AluKernel) {
                std::ostringstream stream;
                stream << "command " << index
                       << " is not one-node f32_alu";
                set_error(
                    context,
                    GGML_NPU_COMPILED_PLAN_ERROR_UNSUPPORTED_BUNDLE_V1,
                    stream.str());
                return false;
            }
            if (!node_ids.insert(command.node_ids[0]).second) {
                set_error(
                    context,
                    GGML_NPU_COMPILED_PLAN_ERROR_UNSUPPORTED_BUNDLE_V1,
                    "artifact node ids are not globally unique");
                return false;
            }
        }
        if (candidate.commands.empty() || candidate.buffers.empty()) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_UNSUPPORTED_BUNDLE_V1,
                "compiled plan cannot be empty");
            return false;
        }

        context->nodes.assign(
            candidate.commands.size(), compiled_node_binding());
        context->buffers.assign(
            candidate.buffers.size(), compiled_buffer_binding());
        context->bundle = std::move(candidate);
        context->state = GGML_NPU_COMPILED_PLAN_LOADED_V1;
        clear_error(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while loading compiled plan");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while loading compiled plan");
        return false;
    }
}

extern "C" bool ggml_backend_npu_compiled_plan_bind_node_v1(
        ggml_backend_t backend,
        std::uint64_t artifact_node_id,
        ggml_tensor * tensor,
        std::int32_t graph_index) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        if (context->bundle.provenance_source.schema == "qwen-npu-graph-manifest-v2") {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_PROVENANCE_V2,
                      "canonical artifacts require bind_graph_v2; manual bindings cannot prove provenance");
            return false;
        }
        if (context->state != GGML_NPU_COMPILED_PLAN_LOADED_V1) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
                "node binding requires a loaded unsealed plan");
            return false;
        }
        if (tensor == nullptr || graph_index < 0) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_ARGUMENT_V1,
                "node tensor is null or graph index is negative");
            return false;
        }

        std::size_t command_index = kMissingIndex;
        for (std::size_t index = 0U;
             index < context->bundle.commands.size(); ++index) {
            if (context->bundle.commands[index].node_ids[0] ==
                artifact_node_id) {
                command_index = index;
                break;
            }
        }
        if (command_index == kMissingIndex) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_UNKNOWN_NODE_V1,
                "artifact node id is not in the loaded bundle");
            return false;
        }
        if (context->nodes[command_index].bound) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_DUPLICATE_NODE_V1,
                "artifact node id is already bound");
            return false;
        }
        for (const compiled_node_binding & binding : context->nodes) {
            if (binding.bound &&
                (binding.tensor == tensor ||
                 binding.graph_index == graph_index)) {
                set_error(
                    context,
                    GGML_NPU_COMPILED_PLAN_ERROR_DUPLICATE_NODE_V1,
                    "GGML node pointer or graph index is already bound");
                return false;
            }
        }
        if (tensor->buffer != nullptr &&
            !ggml_backend_buffer_is_host(tensor->buffer)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_NODE_BINDING_V1,
                "node tensor is allocated in non-host-accessible storage");
            return false;
        }
        context->nodes[command_index] = {
            true,
            artifact_node_id,
            tensor,
            graph_index,
            nullptr,
            0U,
        };
        clear_error(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while binding compiled node");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while binding compiled node");
        return false;
    }
}

extern "C" bool ggml_backend_npu_compiled_plan_bind_buffer_v1(
        ggml_backend_t backend,
        const char * buffer_id,
        ggml_tensor * tensor,
        std::uint64_t tensor_offset,
        std::uint64_t bytes) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        if (context->bundle.provenance_source.schema == "qwen-npu-graph-manifest-v2") {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_PROVENANCE_V2,
                      "canonical artifacts require bind_graph_v2; manual bindings cannot prove provenance");
            return false;
        }
        if (context->state != GGML_NPU_COMPILED_PLAN_LOADED_V1) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
                "buffer binding requires a loaded unsealed plan");
            return false;
        }
        if (buffer_id == nullptr || buffer_id[0] == '\0' ||
            tensor == nullptr) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_ARGUMENT_V1,
                "buffer id or tensor is invalid");
            return false;
        }
        const std::size_t buffer_index = find_buffer(
            context->bundle, buffer_id);
        if (buffer_index == kMissingIndex) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_UNKNOWN_BUFFER_V1,
                "BufferId is not in the loaded bundle");
            return false;
        }
        if (context->buffers[buffer_index].bound) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_DUPLICATE_BUFFER_V1,
                "BufferId is already bound");
            return false;
        }
        if (bytes != context->bundle.buffers[buffer_index].size) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1,
                "bound bytes must exactly equal artifact buffer size");
            return false;
        }
        std::string range_failure;
        if (!tensor_static_range(
                tensor,
                tensor_offset,
                bytes,
                nullptr,
                &range_failure)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_BUFFER_BINDING_V1,
                std::move(range_failure));
            return false;
        }
        context->buffers[buffer_index] = {
            true,
            tensor,
            tensor_offset,
            bytes,
            nullptr,
            0U,
            0U,
            0U,
        };
        clear_error(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while binding compiled buffer");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while binding compiled buffer");
        return false;
    }
}

extern "C" bool ggml_backend_npu_compiled_plan_seal_v1(
        ggml_backend_t backend,
        ggml_cgraph * full_graph) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        if (context->bundle.provenance_source.schema == "qwen-npu-graph-manifest-v2") {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_PROVENANCE_V2,
                      "canonical artifacts require bind_graph_v2; manual bindings cannot prove provenance");
            return false;
        }
        if (context->state != GGML_NPU_COMPILED_PLAN_LOADED_V1) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
                "seal requires a loaded unsealed plan");
            return false;
        }
        if (g_active_context != nullptr && g_active_context != context) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_ACTIVE_PLAN_V1,
                "another compiled backend owns the device plan registry");
            return false;
        }

        std::string failure;
        ggml_npu_compiled_plan_error_v1 error =
            GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1;
        if (!validate_plan(context, false, false, &failure, &error)) {
            set_error(context, error, std::move(failure));
            return false;
        }
        if (!validate_full_graph_at_seal(context, full_graph, &failure)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1,
                std::move(failure));
            return false;
        }
        if (!snapshot_full_graph(context, full_graph, &failure)) {
            set_error(
                context,
                GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
                std::move(failure));
            return false;
        }

        context->state = GGML_NPU_COMPILED_PLAN_SEALED_V1;
        g_active_context = context;
        clear_error(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while sealing compiled plan");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while sealing compiled plan");
        return false;
    }
}

extern "C" bool ggml_backend_npu_compiled_plan_clear_v1(
        ggml_backend_t backend) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        reset_plan(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while clearing compiled plan");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while clearing compiled plan");
        return false;
    }
}

extern "C" bool ggml_backend_npu_compiled_plan_status_v1(
        ggml_backend_t backend,
        ggml_npu_compiled_plan_status_v1 * status) {
    if (status == nullptr) {
        return false;
    }
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            return false;
        }
        ggml_npu_compiled_plan_status_v1 candidate = {};
        candidate.abi_version = GGML_NPU_COMPILED_PLAN_API_VERSION;
        candidate.state = context->state;
        candidate.last_error = context->error;
        candidate.is_active_plan = g_active_context == context ? 1U : 0U;
        candidate.command_count = context->bundle.commands.size();
        candidate.buffer_count = context->bundle.buffers.size();
        candidate.compute_attempts = context->compute_attempts;
        candidate.execute_calls = context->execute_calls;
        candidate.successful_bundles = context->successful_bundles;
        candidate.last_generation = context->last_generation;
        for (const compiled_node_binding & binding : context->nodes) {
            candidate.bound_node_count += binding.bound ? 1U : 0U;
        }
        for (const compiled_buffer_binding & binding : context->buffers) {
            candidate.bound_buffer_count += binding.bound ? 1U : 0U;
        }
        if (context->runtime != nullptr) {
            const npu_host_runtime_status runtime_status =
                context->runtime->status();
            candidate.runtime_ready = runtime_status.ready ? 1U : 0U;
            candidate.runtime_fatal = runtime_status.fatal ? 1U : 0U;
            candidate.next_generation = runtime_status.next_generation;
            candidate.submitted_generations =
                runtime_status.submitted_generations;
        }
        *status = candidate;
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while reading compiled plan status");
        return false;
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while reading compiled plan status");
        return false;
    }
}

extern "C" const char * ggml_backend_npu_compiled_plan_last_error_v1(
        ggml_backend_t backend) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        compiled_backend_context * context = context_from_backend(backend);
        if (context == nullptr) {
            g_last_error_copy = "invalid compiled backend";
        } else {
            g_last_error_copy = context->failure;
        }
    } catch (const std::bad_alloc &) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
            "allocation failed while copying compiled backend error");
        return "could not retrieve compiled backend error";
    } catch (...) {
        record_backend_exception(
            backend,
            GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
            "internal exception while copying compiled backend error");
        return "could not retrieve compiled backend error";
    }
    return g_last_error_copy.c_str();
}

extern "C" ggml_backend_reg_t ggml_backend_npu_compiled_reg(void) {
    static ggml_backend_reg registry = {
        GGML_BACKEND_API_VERSION,
        registry_interface,
        nullptr,
    };
    return &registry;
}

GGML_BACKEND_DL_IMPL(ggml_backend_npu_compiled_reg)
GGML_BACKEND_DL_SCORE_IMPL(backend_score)

extern "C" bool ggml_backend_npu_compiled_plan_bind_graph_v2(
        ggml_backend_t backend, const char * manifest_path, ggml_cgraph * full_graph) {
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        auto * context = context_from_backend(backend);
        if (!context) return false;
        if (context->state != GGML_NPU_COMPILED_PLAN_LOADED_V1) {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_INVALID_STATE_V1,
                      "bind_graph_v2 requires a loaded unsealed plan");
            return false;
        }
        context->nodes.assign(context->bundle.commands.size(), compiled_node_binding());
        context->buffers.assign(context->bundle.buffers.size(), compiled_buffer_binding());
        context->manifest_plan = npu_ggml_manifest_plan();
        context->full_graph = nullptr;
        context->full_graph_nodes.clear();
        std::string failure;
        npu_ggml_manifest_plan candidate;
        if (!npu_ggml_manifest_bind(context->bundle, manifest_path, full_graph, &candidate, &failure)) {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_PROVENANCE_V2, failure);
            return false;
        }
        for (std::size_t i = 0; i < candidate.nodes.size(); ++i)
            context->nodes[i] = {true, context->bundle.commands[i].node_ids[0],
                                candidate.nodes[i], candidate.graph_indices[i], nullptr, 0};
        for (std::size_t i = 0; i < candidate.buffers.size(); ++i)
            context->buffers[i] = {true, candidate.buffers[i], 0,
                                  context->bundle.buffers[i].size, nullptr, 0, 0, 0};
        ggml_npu_compiled_plan_error_v1 error = GGML_NPU_COMPILED_PLAN_ERROR_NONE_V1;
        if (!validate_plan(context, false, false, &failure, &error)) {
            set_error(context, error, failure);
            return false;
        }
        if (!validate_full_graph_at_seal(context, full_graph, &failure) ||
            !snapshot_full_graph(context, full_graph, &failure)) {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1, failure);
            return false;
        }
        if (g_active_context != nullptr && g_active_context != context) {
            set_error(context, GGML_NPU_COMPILED_PLAN_ERROR_ACTIVE_PLAN_V1,
                      "another compiled plan owns the device");
            return false;
        }
        context->manifest_plan = std::move(candidate);
        context->state = GGML_NPU_COMPILED_PLAN_SEALED_V1;
        g_active_context = context;
        clear_error(context);
        return true;
    } catch (const std::bad_alloc &) {
        record_backend_exception(backend, GGML_NPU_COMPILED_PLAN_ERROR_ALLOCATION_V1,
                                 "allocation failed while resolving canonical graph");
    } catch (...) {
        record_backend_exception(backend, GGML_NPU_COMPILED_PLAN_ERROR_INTERNAL_EXCEPTION_V1,
                                 "internal exception while resolving canonical graph");
    }
    return false;
}

extern "C" enum ggml_status ggml_backend_npu_compiled_plan_launch_v2(ggml_backend_t backend) {
    return compiled_graph_compute(backend, nullptr);
}

extern "C" bool ggml_backend_npu_compiled_plan_audit_v2(
        ggml_backend_t backend, ggml_npu_compiled_plan_audit_v2 * result) {
    if (!result) return false;
    try {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        auto * context = context_from_backend(backend);
        if (!context) return false;
        ggml_npu_compiled_plan_audit_v2 value = {};
        if (context->runtime) {
            const auto session = context->runtime->status().session;
            value = {session.constructor_count, session.reset_release_count, session.boot_count,
                     session.counters.launch_accepts, session.counters.macro_terminals,
                     session.counters.rtl_f32_starts,
                     session.counters.portal_requests, session.counters.portal_responses,
                     session.counters.portal_read_bytes, session.counters.portal_write_bytes};
        }
        *result = value;
        return true;
    } catch (...) {
        return false;
    }
}
