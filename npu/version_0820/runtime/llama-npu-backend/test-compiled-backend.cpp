#include "npu-compiled-backend-api.h"

#include "ggml.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

namespace {

int g_checks = 0;

constexpr std::array<std::uint32_t, 16> kInput0Generation1 = {
    0x3f800000U, 0xbf800000U, 0x40600000U, 0x41200000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
};

constexpr std::array<std::uint32_t, 16> kInput1Generation1 = {
    0x40000000U, 0x3f000000U, 0xbfa00000U, 0xc0a00000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
};

constexpr std::array<std::uint32_t, 16> kOutputGeneration1 = {
    0x40800000U, 0x3f000002U, 0x40500001U, 0x40c00001U,
    0x40800001U, 0x40800001U, 0x40800002U, 0x40800002U,
    0x40800002U, 0x40800002U, 0x40800002U, 0x40800003U,
    0x40800003U, 0x40800003U, 0x40800004U, 0x40800004U,
};

constexpr std::array<std::uint32_t, 16> kZeroInput = {};

constexpr std::array<std::uint32_t, 16> kOutputGeneration2 = {
    0x3f800000U, 0x3f800001U, 0x3f800002U, 0x3f800003U,
    0x3f800004U, 0x3f800005U, 0x3f800006U, 0x3f800007U,
    0x3f800008U, 0x3f800009U, 0x3f80000aU, 0x3f80000bU,
    0x3f80000cU, 0x3f80000dU, 0x3f80000eU, 0x3f80000fU,
};

bool check(bool condition, const char * message) {
    ++g_checks;
    if (!condition) {
        std::fprintf(stderr, "[NPU-COMPILED-BACKEND][FAIL] %s\n", message);
    }
    return condition;
}

void store_le32(std::uint8_t * bytes, std::uint32_t value) {
    for (std::size_t index = 0U; index < 4U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

std::uint32_t load_le32(const std::uint8_t * bytes) {
    return static_cast<std::uint32_t>(bytes[0]) |
        (static_cast<std::uint32_t>(bytes[1]) << 8U) |
        (static_cast<std::uint32_t>(bytes[2]) << 16U) |
        (static_cast<std::uint32_t>(bytes[3]) << 24U);
}

template <std::size_t N>
bool store_words(
        ggml_tensor * tensor,
        const std::array<std::uint32_t, N> & words) {
    if (tensor == nullptr || tensor->data == nullptr ||
        ggml_nbytes(tensor) != N * 4U) {
        return false;
    }
    auto * bytes = static_cast<std::uint8_t *>(tensor->data);
    for (std::size_t index = 0U; index < N; ++index) {
        store_le32(bytes + index * 4U, words[index]);
    }
    return true;
}

template <std::size_t N>
bool check_words(
        const ggml_tensor * tensor,
        const std::array<std::uint32_t, N> & expected) {
    if (tensor == nullptr || tensor->data == nullptr ||
        ggml_nbytes(tensor) != N * 4U) {
        return false;
    }
    const auto * bytes = static_cast<const std::uint8_t *>(tensor->data);
    for (std::size_t index = 0U; index < N; ++index) {
        const std::uint32_t actual = load_le32(bytes + index * 4U);
        if (actual != expected[index]) {
            std::fprintf(
                stderr,
                "[NPU-COMPILED-BACKEND][MISMATCH] lane=%zu "
                "got=0x%08x expected=0x%08x\n",
                index,
                actual,
                expected[index]);
            return false;
        }
    }
    return true;
}

struct tiny_graph {
    ggml_context * context = nullptr;
    ggml_tensor * input0_root = nullptr;
    ggml_tensor * input0 = nullptr;
    ggml_tensor * input1 = nullptr;
    ggml_tensor * bias = nullptr;
    ggml_tensor * cpu_input = nullptr;
    ggml_tensor * cpu_prefix = nullptr;
    ggml_tensor * intermediate = nullptr;
    ggml_tensor * output = nullptr;
    ggml_tensor * metadata = nullptr;
    ggml_cgraph * graph = nullptr;
    int intermediate_index = -1;
    int output_index = -1;
};

bool make_tiny_graph(tiny_graph * result, bool no_alloc = false) {
    if (result == nullptr) {
        return false;
    }
    ggml_init_params parameters = {
        2U * 1024U * 1024U,
        nullptr,
        no_alloc,
    };
    result->context = ggml_init(parameters);
    if (result->context == nullptr) {
        return false;
    }
    result->input0_root = ggml_new_tensor_1d(
        result->context, GGML_TYPE_F32, 16);
    result->input0 = ggml_view_1d(
        result->context, result->input0_root, 16, 0U);
    result->input1 = ggml_new_tensor_1d(
        result->context, GGML_TYPE_F32, 16);
    result->bias = ggml_new_tensor_1d(
        result->context, GGML_TYPE_F32, 16);
    result->cpu_input = ggml_new_tensor_1d(
        result->context, GGML_TYPE_F32, 16);
    result->cpu_prefix = ggml_sqr(result->context, result->cpu_input);
    result->intermediate = ggml_add(
        result->context, result->input0, result->input1);
    result->output = ggml_add(
        result->context, result->intermediate, result->bias);
    result->metadata = ggml_reshape_1d(
        result->context, result->input0, 16);
    result->graph = ggml_new_graph(result->context);
    if (result->input0_root == nullptr || result->input0 == nullptr ||
        result->input1 == nullptr ||
        result->bias == nullptr || result->cpu_input == nullptr ||
        result->cpu_prefix == nullptr ||
        result->intermediate == nullptr ||
        result->output == nullptr || result->metadata == nullptr ||
        result->graph == nullptr) {
        return false;
    }
    ggml_set_input(result->input0_root);
    ggml_set_input(result->input1);
    ggml_set_input(result->bias);
    ggml_set_input(result->cpu_input);
    // The production raw request contract forbids input/output capability
    // aliasing.  Keep the three external/read-only artifact leaves live so
    // GGML's allocator cannot recycle one into the published output.
    ggml_set_output(result->input0_root);
    ggml_set_output(result->input1);
    ggml_set_output(result->bias);
    ggml_set_output(result->output);
    ggml_build_forward_expand(result->graph, result->cpu_prefix);
    ggml_build_forward_expand(result->graph, result->output);
    const int count = ggml_graph_n_nodes(result->graph);
    for (int index = 0; index < count; ++index) {
        ggml_tensor * node = ggml_graph_node(result->graph, index);
        if (node == result->intermediate) {
            result->intermediate_index = index;
        } else if (node == result->output) {
            result->output_index = index;
        }
    }
    return result->intermediate_index > 0 &&
        result->output_index == result->intermediate_index + 1;
}

bool bind_nodes(
        ggml_backend_t backend,
        const tiny_graph & graph,
        ggml_backend_npu_compiled_plan_bind_node_v1_t bind_node) {
    return bind_node(
               backend, 4097U, graph.intermediate,
               graph.intermediate_index) &&
        bind_node(backend, 4098U, graph.output, graph.output_index);
}

bool bind_buffers(
        ggml_backend_t backend,
        const tiny_graph & graph,
        ggml_backend_npu_compiled_plan_bind_buffer_v1_t bind_buffer,
        bool swap_destinations = false) {
    ggml_tensor * intermediate = swap_destinations
        ? graph.output : graph.intermediate;
    ggml_tensor * output = swap_destinations
        ? graph.intermediate : graph.output;
    return bind_buffer(backend, "bias", graph.bias, 0U, 64U) &&
        bind_buffer(backend, "input0", graph.input0, 0U, 64U) &&
        bind_buffer(backend, "input1", graph.input1, 0U, 64U) &&
        bind_buffer(backend, "intermediate", intermediate, 0U, 64U) &&
        bind_buffer(backend, "output", output, 0U, 64U);
}

bool load_and_bind(
        ggml_backend_t backend,
        const char * bundle_directory,
        const tiny_graph & graph,
        ggml_backend_npu_compiled_plan_load_v1_t load,
        ggml_backend_npu_compiled_plan_bind_node_v1_t bind_node,
        ggml_backend_npu_compiled_plan_bind_buffer_v1_t bind_buffer) {
    return load(backend, bundle_directory) &&
        bind_nodes(backend, graph, bind_node) &&
        bind_buffers(backend, graph, bind_buffer);
}

} // namespace

int main(int argc, char ** argv) {
    if (argc != 4) {
        std::fprintf(
            stderr,
            "usage: %s COMPILED_BACKEND_DSO BUNDLE_DIR "
            "GGML_BACKEND_DIR\n",
            argv[0]);
        return 2;
    }

    ggml_backend_reg_t registry = ggml_backend_load(argv[1]);
    if (!check(registry != nullptr, "compiled backend DSO did not load")) {
        return 1;
    }
    ggml_backend_dev_t device = registry == nullptr
        ? nullptr : ggml_backend_reg_dev_get(registry, 0U);
    auto load = reinterpret_cast<
        ggml_backend_npu_compiled_plan_load_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_LOAD_V1_PROC));
    auto bind_node = reinterpret_cast<
        ggml_backend_npu_compiled_plan_bind_node_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_BIND_NODE_V1_PROC));
    auto bind_buffer = reinterpret_cast<
        ggml_backend_npu_compiled_plan_bind_buffer_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_BIND_BUFFER_V1_PROC));
    auto seal = reinterpret_cast<
        ggml_backend_npu_compiled_plan_seal_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_SEAL_V1_PROC));
    auto clear = reinterpret_cast<
        ggml_backend_npu_compiled_plan_clear_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_CLEAR_V1_PROC));
    auto status = reinterpret_cast<
        ggml_backend_npu_compiled_plan_status_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_STATUS_V1_PROC));
    auto last_error = reinterpret_cast<
        ggml_backend_npu_compiled_plan_last_error_v1_t>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_COMPILED_PLAN_LAST_ERROR_V1_PROC));

    if (!check(
            std::strcmp(ggml_backend_reg_name(registry),
                        "NPU-COMPILED") == 0,
            "compiled registry name mismatch") ||
        !check(device != nullptr, "missing compiled device") ||
        !check(load != nullptr && bind_node != nullptr &&
                   bind_buffer != nullptr && seal != nullptr &&
                   clear != nullptr && status != nullptr &&
                   last_error != nullptr,
               "versioned compiled-plan proc API is incomplete")) {
        ggml_backend_unload(registry);
        return 1;
    }

    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    tiny_graph graph;
    if (!check(backend != nullptr, "compiled backend init failed") ||
        !check(make_tiny_graph(&graph), "could not construct tiny GGML graph")) {
        if (backend != nullptr) {
            ggml_backend_free(backend);
        }
        if (graph.context != nullptr) {
            ggml_free(graph.context);
        }
        ggml_backend_unload(registry);
        return 1;
    }
    if (!check(
            store_words(graph.bias, kOutputGeneration2),
            "could not initialize GGML weight from frozen weights.bin bytes")) {
        ggml_backend_free(backend);
        ggml_free(graph.context);
        ggml_backend_unload(registry);
        return 1;
    }

    bool passed = true;
    ggml_npu_compiled_plan_status_v1 snapshot = {};
    passed &= check(
        graph.input0->view_src == graph.input0_root &&
            graph.input0->src[0] == graph.input0_root &&
            graph.input0->view_offs == 0U &&
            graph.input0->data == graph.input0_root->data,
        "positive P00 T16 metadata VIEW alias was not constructed exactly");
    passed &= check(
        ggml_backend_dev_supports_op(device, graph.metadata),
        "metadata op was not advertised without a plan");
    passed &= check(
        !ggml_backend_dev_supports_op(device, graph.intermediate) &&
            !ggml_backend_dev_supports_op(device, graph.output),
        "compute op was advertised without a sealed plan");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.abi_version == GGML_NPU_COMPILED_PLAN_API_VERSION &&
            snapshot.state == GGML_NPU_COMPILED_PLAN_EMPTY_V1,
        "initial compiled-plan status mismatch");

    passed &= check(
        !load(backend, "/definitely/not/a/compiled/npu/bundle"),
        "missing bundle directory was accepted");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_BUNDLE_LOAD_V1 &&
            std::strlen(last_error(backend)) != 0U,
        "bundle-load failure was not observable");

    passed &= check(load(backend, argv[2]), "valid bundle load failed");
    passed &= check(
        !bind_node(backend, 0xdeadbeefU, graph.intermediate, 0),
        "unknown artifact node id was accepted");
    passed &= check(
        !bind_buffer(backend, "unknown", graph.input0, 0U, 64U),
        "unknown BufferId was accepted");
    passed &= check(
        !bind_buffer(backend, "input0", graph.input0, 0U, 60U),
        "non-exact artifact buffer size was accepted");
    passed &= check(
        !seal(backend, graph.graph), "incomplete plan unexpectedly sealed");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.state == GGML_NPU_COMPILED_PLAN_LOADED_V1 &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_INCOMPLETE_PLAN_V1 &&
            snapshot.next_generation == 0U,
        "incomplete seal started a production runtime");

    passed &= check(clear(backend), "clear after incomplete plan failed");
    passed &= check(
        load(backend, argv[2]), "reload for command-order test failed");
    passed &= check(
        bind_node(
            backend, 4097U, graph.intermediate, graph.output_index) &&
            bind_node(
                backend, 4098U, graph.output, graph.intermediate_index) &&
            bind_buffers(backend, graph, bind_buffer),
        "could not construct reversed command-order negative plan");
    passed &= check(
        !seal(backend, graph.graph),
        "reversed command/graph order was accepted");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1 &&
            snapshot.next_generation == 0U,
        "command-order mismatch was not rejected before runtime");

    passed &= check(clear(backend), "clear after command-order test failed");
    passed &= check(load(backend, argv[2]), "reload for edge test failed");
    passed &= check(
        bind_nodes(backend, graph, bind_node) &&
            bind_buffers(backend, graph, bind_buffer, true),
        "could not construct swapped-edge negative plan");
    passed &= check(
        !seal(backend, graph.graph),
        "relocation-to-GGML edge mismatch was accepted");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1 &&
            snapshot.next_generation == 0U,
        "edge mismatch was not rejected before runtime construction");

    passed &= check(clear(backend), "clear before P00 VIEW tests failed");
    passed &= check(
        load_and_bind(
            backend, argv[2], graph, load, bind_node, bind_buffer),
        "binding for wrong VIEW root negative failed");
    graph.input0->view_src = graph.input1;
    passed &= check(
        !seal(backend, graph.graph),
        "P00 src0 VIEW with a root inconsistent with src[0] was accepted");
    graph.input0->view_src = graph.input0_root;
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1 &&
            snapshot.next_generation == 0U,
        "wrong P00 VIEW root was not rejected before runtime construction");

    passed &= check(clear(backend), "clear after wrong VIEW root failed");
    passed &= check(
        load_and_bind(
            backend, argv[2], graph, load, bind_node, bind_buffer),
        "binding for nonzero VIEW offset negative failed");
    const std::size_t saved_view_offset = graph.input0->view_offs;
    graph.input0->view_offs = 4U;
    passed &= check(
        !seal(backend, graph.graph),
        "P00 src0 VIEW with a nonzero offset was accepted");
    graph.input0->view_offs = saved_view_offset;

    passed &= check(clear(backend), "clear after nonzero VIEW offset failed");
    passed &= check(
        load_and_bind(
            backend, argv[2], graph, load, bind_node, bind_buffer),
        "binding for wrong VIEW shape negative failed");
    const std::int64_t saved_view_ne0 = graph.input0->ne[0];
    graph.input0->ne[0] = 8;
    passed &= check(
        !seal(backend, graph.graph),
        "P00 src0 VIEW with a non-T16 shape was accepted");
    graph.input0->ne[0] = saved_view_ne0;

    passed &= check(clear(backend), "clear after wrong VIEW shape failed");
    passed &= check(
        load_and_bind(
            backend, argv[2], graph, load, bind_node, bind_buffer),
        "binding for wrong VIEW source edge negative failed");
    ggml_tensor * saved_src0 = graph.intermediate->src[0];
    graph.intermediate->src[0] = graph.input0_root;
    passed &= check(
        !seal(backend, graph.graph),
        "P00 ADD bypassing its metadata VIEW source was accepted");
    graph.intermediate->src[0] = saved_src0;
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1 &&
            snapshot.next_generation == 0U,
        "wrong P00 source edge was not rejected before runtime construction");

    passed &= check(clear(backend), "clear after edge mismatch failed");
    passed &= check(load(backend, argv[2]), "reload for weight test failed");
    const std::uint8_t saved_weight_byte =
        static_cast<std::uint8_t *>(graph.bias->data)[0];
    static_cast<std::uint8_t *>(graph.bias->data)[0] ^= 0x01U;
    passed &= check(
        bind_nodes(backend, graph, bind_node) &&
            bind_buffers(backend, graph, bind_buffer),
        "could not construct weight-identity negative plan");
    passed &= check(
        seal(backend, graph.graph),
        "static seal rejected an otherwise valid graph with storage present");
    ggml_cgraph * weight_split = ggml_new_graph(graph.context);
    ggml_build_forward_expand(weight_split, graph.output);
    passed &= check(
        ggml_backend_graph_compute(backend, weight_split) ==
            GGML_STATUS_FAILED,
        "GGML weight bytes differing from weights.bin reached execution");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1 &&
            snapshot.execute_calls == 0U &&
            snapshot.next_generation == 0U,
        "weight identity failure did not remain preflight-only");
    static_cast<std::uint8_t *>(graph.bias->data)[0] = saved_weight_byte;

    passed &= check(clear(backend), "clear before transient fan-out test failed");
    passed &= check(
        load_and_bind(
            backend, argv[2], graph, load, bind_node, bind_buffer),
        "binding for transient fan-out negative failed");
    ggml_tensor * transient_cpu_consumer = ggml_sqr(
        graph.context, graph.intermediate);
    ggml_cgraph * fanout_graph = ggml_new_graph(graph.context);
    ggml_build_forward_expand(fanout_graph, graph.cpu_prefix);
    ggml_build_forward_expand(fanout_graph, graph.output);
    ggml_build_forward_expand(fanout_graph, transient_cpu_consumer);
    passed &= check(
        !seal(backend, fanout_graph),
        "private transient fan-out to an unbound CPU node was accepted");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_GRAPH_CONTRACT_V1 &&
            snapshot.next_generation == 0U,
        "transient fan-out was not rejected before runtime construction");

    passed &= check(clear(backend), "clear before scheduler plan failed");
    tiny_graph scheduled_graph;
    if (!check(
            make_tiny_graph(&scheduled_graph, true),
            "could not construct no-alloc scheduler graph")) {
        ggml_backend_free(backend);
        ggml_free(graph.context);
        ggml_backend_unload(registry);
        return 1;
    }
    passed &= check(
        scheduled_graph.input0->data == nullptr &&
            scheduled_graph.input0_root->data == nullptr &&
            scheduled_graph.input1->data == nullptr &&
            scheduled_graph.bias->data == nullptr &&
            scheduled_graph.intermediate->data == nullptr &&
            scheduled_graph.output->data == nullptr,
        "no-alloc graph unexpectedly had storage before admission");
    passed &= check(
        load_and_bind(
            backend, argv[2], scheduled_graph,
            load, bind_node, bind_buffer),
        "no-alloc compiled graph binding failed");
    passed &= check(
        !ggml_backend_dev_supports_op(
            device, scheduled_graph.intermediate),
        "loaded but unsealed no-alloc node was advertised");
    const bool scheduler_plan_sealed =
        seal(backend, scheduled_graph.graph);
    if (!scheduler_plan_sealed) {
        std::fprintf(
            stderr, "[NPU-COMPILED-BACKEND][SEAL] %s\n",
            last_error(backend));
    }
    passed &= check(
        scheduler_plan_sealed, "no-alloc scheduler plan seal failed");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.state == GGML_NPU_COMPILED_PLAN_SEALED_V1 &&
            snapshot.is_active_plan == 1U &&
            snapshot.runtime_ready == 0U &&
            snapshot.runtime_fatal == 0U &&
            snapshot.command_count == 2U &&
            snapshot.buffer_count == 5U &&
            snapshot.bound_node_count == 2U &&
            snapshot.bound_buffer_count == 5U &&
            snapshot.next_generation == 0U,
        "static sealed plan constructed runtime before allocation");
    passed &= check(
        ggml_backend_dev_supports_op(
            device, scheduled_graph.intermediate) &&
            ggml_backend_dev_supports_op(device, scheduled_graph.output),
        "sealed no-alloc node pointers were not advertised");

    ggml_cgraph * compiled_split = ggml_new_graph(scheduled_graph.context);
    ggml_build_forward_expand(compiled_split, scheduled_graph.output);
    ggml_cgraph * partial_graph = ggml_new_graph(scheduled_graph.context);
    ggml_build_forward_expand(partial_graph, scheduled_graph.intermediate);
    passed &= check(
        ggml_backend_graph_compute(backend, scheduled_graph.graph) ==
            GGML_STATUS_FAILED,
        "whole graph with an unbound CPU prefix was accepted by NPU backend");
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 1U &&
            snapshot.execute_calls == 0U &&
            snapshot.runtime_ready == 0U &&
            snapshot.next_generation == 0U,
        "CPU-prefix preflight constructed runtime or consumed generation");
    passed &= check(
        ggml_backend_graph_compute(backend, partial_graph) ==
            GGML_STATUS_FAILED,
        "partial bundle graph was accepted");
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 2U &&
            snapshot.execute_calls == 0U &&
            snapshot.runtime_ready == 0U &&
            snapshot.next_generation == 0U,
        "partial graph preflight constructed runtime or consumed generation");

    ggml_tensor * extra = ggml_add(
        scheduled_graph.context,
        scheduled_graph.input0,
        scheduled_graph.input1);
    ggml_tensor * wrong_terminal = ggml_add(
        scheduled_graph.context, scheduled_graph.output, extra);
    ggml_cgraph * wrong_graph = ggml_new_graph(scheduled_graph.context);
    ggml_build_forward_expand(wrong_graph, wrong_terminal);
    passed &= check(
        !ggml_backend_dev_supports_op(device, extra) &&
            !ggml_backend_dev_supports_op(device, wrong_terminal),
        "unbound graph node pointer was advertised");
    passed &= check(
        ggml_backend_graph_compute(backend, wrong_graph) ==
            GGML_STATUS_FAILED,
        "wrong/partial graph instance was accepted");
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 3U &&
            snapshot.execute_calls == 0U &&
            snapshot.runtime_ready == 0U &&
            snapshot.next_generation == 0U,
        "wrong graph preflight constructed runtime or consumed generation");

    ggml_backend_t second_backend = ggml_backend_dev_init(device, nullptr);
    passed &= check(
        second_backend == nullptr,
        "device created a second live backend with ambiguous supports_op");
    passed &= check(
        ggml_backend_dev_supports_op(device, scheduled_graph.output),
        "failed second init unregistered the active plan");

    ggml_backend_load_all_from_path(argv[3]);
    ggml_backend_t cpu_backend = ggml_backend_init_by_type(
        GGML_BACKEND_DEVICE_TYPE_CPU, nullptr);
    ggml_backend_t scheduler_backends[] = {backend, cpu_backend};
    ggml_backend_sched_t scheduler = cpu_backend == nullptr
        ? nullptr
        : ggml_backend_sched_new(
              scheduler_backends, nullptr, 2,
              GGML_DEFAULT_GRAPH_SIZE, false, true);
    passed &= check(
        cpu_backend != nullptr && scheduler != nullptr,
        "could not construct NPU+CPU GGML scheduler");
    if (scheduler != nullptr) {
        ggml_backend_sched_set_tensor_backend(
            scheduler, scheduled_graph.input0_root, backend);
        ggml_backend_sched_set_tensor_backend(
            scheduler, scheduled_graph.input1, backend);
        ggml_backend_sched_set_tensor_backend(
            scheduler, scheduled_graph.bias, backend);
    }
    const bool allocated = scheduler != nullptr &&
        ggml_backend_sched_alloc_graph(
            scheduler, scheduled_graph.graph);
    passed &= check(allocated, "scheduler could not allocate no-alloc graph");
    if (allocated) {
        passed &= check(
            ggml_backend_sched_get_tensor_backend(
                scheduler, scheduled_graph.cpu_prefix) == cpu_backend &&
                ggml_backend_sched_get_tensor_backend(
                    scheduler, scheduled_graph.intermediate) == backend &&
                ggml_backend_sched_get_tensor_backend(
                    scheduler, scheduled_graph.output) == backend,
            "scheduler did not form one CPU-prefix/NPU-bundle split");
        passed &= check(
            scheduled_graph.input0->data != nullptr &&
                scheduled_graph.input0_root->data != nullptr &&
                scheduled_graph.input0->data ==
                    scheduled_graph.input0_root->data &&
                scheduled_graph.input1->data != nullptr &&
                scheduled_graph.bias->data != nullptr &&
                scheduled_graph.intermediate->data != nullptr &&
                scheduled_graph.output->data != nullptr,
            "scheduler allocation did not materialize bound storage");
    }

    passed &= check(
        store_words(scheduled_graph.bias, kOutputGeneration2) &&
            store_words(
                scheduled_graph.input0, kInput0Generation1) &&
            store_words(
                scheduled_graph.input1, kInput1Generation1),
        "generation-1 scheduler tensors could not be initialized");
    if (scheduled_graph.cpu_input->data != nullptr) {
        std::memset(
            scheduled_graph.cpu_input->data, 0,
            ggml_nbytes(scheduled_graph.cpu_input));
    }
    if (scheduled_graph.output->data != nullptr) {
        std::memset(
            scheduled_graph.output->data, 0xa5,
            ggml_nbytes(scheduled_graph.output));
    }
    const enum ggml_status generation1_status = scheduler == nullptr
        ? GGML_STATUS_FAILED
        : ggml_backend_sched_graph_compute(
              scheduler, scheduled_graph.graph);
    if (generation1_status != GGML_STATUS_SUCCESS) {
        std::fprintf(
            stderr, "[NPU-COMPILED-BACKEND][SCHEDULER] %s\n",
            last_error(backend));
    }
    passed &= check(
        generation1_status == GGML_STATUS_SUCCESS,
        "generation-1 scheduler execution failed");
    passed &= check(
        check_words(scheduled_graph.output, kOutputGeneration1),
        "generation-1 scheduler output mismatch");
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 4U &&
            snapshot.execute_calls == 1U &&
            snapshot.successful_bundles == 1U &&
            snapshot.runtime_ready == 1U &&
            snapshot.last_generation == 1U &&
            snapshot.next_generation == 2U &&
            snapshot.submitted_generations == 1U,
        "generation-1 scheduler/backend/runtime accounting mismatch");

    void * saved_bias_data = scheduled_graph.bias->data;
    scheduled_graph.bias->data = scheduled_graph.input0->data;
    passed &= check(
        ggml_backend_graph_compute(backend, compiled_split) ==
            GGML_STATUS_FAILED,
        "post-runtime tensor storage mutation was accepted");
    scheduled_graph.bias->data = saved_bias_data;
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 5U &&
            snapshot.execute_calls == 1U &&
            snapshot.next_generation == 2U &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_TENSOR_CHANGED_V1,
        "tensor storage mutation consumed a runtime generation");

    auto * weight_bytes = static_cast<std::uint8_t *>(
        scheduled_graph.bias->data);
    if (weight_bytes != nullptr) {
        weight_bytes[0] ^= 0x01U;
    }
    passed &= check(
        ggml_backend_graph_compute(backend, compiled_split) ==
            GGML_STATUS_FAILED,
        "post-runtime weight content mutation was accepted");
    if (weight_bytes != nullptr) {
        weight_bytes[0] ^= 0x01U;
    }
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 6U &&
            snapshot.execute_calls == 1U &&
            snapshot.next_generation == 2U &&
            snapshot.last_error ==
                GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1,
        "weight mutation consumed a runtime generation");

    passed &= check(
        store_words(scheduled_graph.input0, kZeroInput) &&
            store_words(scheduled_graph.input1, kZeroInput),
        "generation-2 scheduler inputs could not be initialized");
    if (scheduled_graph.output->data != nullptr) {
        std::memset(
            scheduled_graph.output->data, 0x5a,
            ggml_nbytes(scheduled_graph.output));
    }
    const enum ggml_status generation2_status = scheduler == nullptr
        ? GGML_STATUS_FAILED
        : ggml_backend_sched_graph_compute(
              scheduler, scheduled_graph.graph);
    if (generation2_status != GGML_STATUS_SUCCESS) {
        std::fprintf(
            stderr, "[NPU-COMPILED-BACKEND][SCHEDULER] %s\n",
            last_error(backend));
    }
    passed &= check(
        generation2_status == GGML_STATUS_SUCCESS,
        "generation-2 scheduler execution failed");
    passed &= check(
        check_words(scheduled_graph.output, kOutputGeneration2),
        "generation-2 scheduler output mismatch");
    passed &= check(
        status(backend, &snapshot) && snapshot.compute_attempts == 7U &&
            snapshot.execute_calls == 2U &&
            snapshot.successful_bundles == 2U &&
            snapshot.last_generation == 2U &&
            snapshot.next_generation == 3U &&
            snapshot.submitted_generations == 2U,
        "persistent runtime was rebuilt or generation accounting diverged");

    passed &= check(clear(backend), "clearing sealed plan failed");
    passed &= check(
        !ggml_backend_dev_supports_op(device, scheduled_graph.output) &&
            ggml_backend_dev_supports_op(device, scheduled_graph.metadata),
        "clear did not unregister compute-only admission");
    passed &= check(
        status(backend, &snapshot) &&
            snapshot.state == GGML_NPU_COMPILED_PLAN_EMPTY_V1 &&
            snapshot.is_active_plan == 0U &&
            snapshot.runtime_ready == 0U,
        "cleared plan status mismatch");

    if (scheduler != nullptr) {
        ggml_backend_sched_free(scheduler);
    }
    if (cpu_backend != nullptr) {
        ggml_backend_free(cpu_backend);
    }
    ggml_backend_free(backend);
    ggml_backend_t replacement_backend =
        ggml_backend_dev_init(device, nullptr);
    passed &= check(
        replacement_backend != nullptr,
        "freeing the live backend did not release device ownership");
    if (replacement_backend != nullptr) {
        ggml_backend_free(replacement_backend);
    }
    ggml_free(scheduled_graph.context);
    ggml_free(graph.context);
    ggml_backend_unload(registry);
    if (!passed) {
        return 1;
    }
    std::printf(
        "[NPU-COMPILED-BACKEND][PASS] checks=%d generations=2 "
        "whole_bundle_executes=2 cpu_fallbacks=0\n",
        g_checks);
    return 0;
}
