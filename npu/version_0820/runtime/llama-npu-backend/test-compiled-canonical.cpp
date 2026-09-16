#include "npu-compiled-backend-api.h"
#include "ggml.h"
#include <nlohmann/json.hpp>
#include <array>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>

using json = nlohmann::json;
static unsigned checks = 0;
static void check(bool ok, const std::string & detail) {
    ++checks;
    if (!ok) throw std::runtime_error(detail);
}
static json read_json(const std::string & path) {
    std::ifstream in(path);
    check(in.good(), "open " + path);
    return json::parse(in);
}

// Reconstruct the captured complete GGML descriptor graph, without evaluating
// any of its tensors. Only the selected P00 buffers receive storage. This is
// a source-manifest replay test, not a live llama token-generation claim.
struct replay_graph {
    ggml_context * context = nullptr;
    ggml_cgraph * graph = nullptr;
    std::vector<ggml_tensor *> nodes, external;
    ~replay_graph() { if (context) ggml_free(context); }
    ggml_tensor * resolve(const json & ref) {
        if (ref.is_null()) return nullptr;
        return (ref.at("kind") == "node" ? nodes : external).at(ref.at("index").get<std::size_t>());
    }
    void build(const json & manifest) {
        context = ggml_init({8 * 1024 * 1024, nullptr, true});
        check(context != nullptr, "allocate descriptor context");
        auto create = [&](const json & rows, std::vector<ggml_tensor *> & tensors) {
            for (const auto & row : rows) {
                const auto & d = row.at("descriptor");
                std::int64_t ne[4];
                for (int i = 0; i < 4; ++i) ne[i] = d.at("ne")[i];
                auto * t = ggml_new_tensor(context, static_cast<ggml_type>(d.at("type_id").get<int>()), 4, ne);
                check(t != nullptr, "allocate tensor descriptor");
                t->op = static_cast<ggml_op>(d.at("op_id").get<int>());
                t->flags = d.at("flags");
                for (int i = 0; i < 4; ++i) t->nb[i] = d.at("nb")[i];
                t->view_offs = d.at("view_offs");
                ggml_set_name(t, d.at("name").get<std::string>().c_str());
                const auto params = d.at("op_params_hex").get<std::string>();
                auto * bytes = reinterpret_cast<unsigned char *>(t->op_params);
                for (std::size_t i = 0; i < sizeof(t->op_params); ++i)
                    bytes[i] = static_cast<unsigned char>(std::stoul(params.substr(i * 2, 2), nullptr, 16));
                tensors.push_back(t);
            }
        };
        create(manifest.at("nodes"), nodes);
        create(manifest.at("external_tensors"), external);
        auto link = [&](const json & rows, const std::vector<ggml_tensor *> & tensors) {
            for (std::size_t i = 0; i < rows.size(); ++i) {
                auto * t = tensors[i];
                t->view_src = resolve(rows[i].at("descriptor").at("view_src"));
                for (const auto & src : rows[i].at("sources"))
                    t->src[src.at("slot").get<std::size_t>()] = resolve(src.at("ref"));
            }
        };
        link(manifest.at("nodes"), nodes);
        link(manifest.at("external_tensors"), external);
        graph = ggml_new_graph_custom(context, nodes.size() + 32, false);
        for (auto * t : nodes) ggml_graph_add_node(graph, t);
    }
};

template<class T> static T proc(ggml_backend_reg_t reg, const char * name) {
    const auto value = reinterpret_cast<T>(ggml_backend_reg_get_proc_address(reg, name));
    check(value != nullptr, std::string("missing proc ") + name);
    return value;
}
int main(int argc, char ** argv) {
    if (argc != 4) {
        std::fprintf(stderr, "usage: %s compiled-backend.so bundle-dir exact-manifest.json\n", argv[0]);
        return 2;
    }
    ggml_backend_t backend = nullptr;
    try {
        auto reg = ggml_backend_load(argv[1]);
        check(reg != nullptr, "load compiled DSO");
        backend = ggml_backend_dev_init(ggml_backend_reg_dev_get(reg, 0), nullptr);
        check(backend != nullptr, "create compiled backend");
        const auto load = proc<ggml_backend_npu_compiled_plan_load_v1_t>(reg, GGML_NPU_COMPILED_PLAN_LOAD_V1_PROC);
        const auto bind = proc<ggml_backend_npu_compiled_plan_bind_graph_v2_t>(reg, GGML_NPU_COMPILED_PLAN_BIND_GRAPH_V2_PROC);
        const auto launch = proc<ggml_backend_npu_compiled_plan_launch_v2_t>(reg, GGML_NPU_COMPILED_PLAN_LAUNCH_V2_PROC);
        const auto manual = proc<ggml_backend_npu_compiled_plan_bind_node_v1_t>(reg, GGML_NPU_COMPILED_PLAN_BIND_NODE_V1_PROC);
        const auto status = proc<ggml_backend_npu_compiled_plan_status_v1_t>(reg, GGML_NPU_COMPILED_PLAN_STATUS_V1_PROC);
        const auto error = proc<ggml_backend_npu_compiled_plan_last_error_v1_t>(reg, GGML_NPU_COMPILED_PLAN_LAST_ERROR_V1_PROC);
        const auto audit = proc<ggml_backend_npu_compiled_plan_audit_v2_t>(reg, GGML_NPU_COMPILED_PLAN_AUDIT_V2_PROC);
        const auto clear = proc<ggml_backend_npu_compiled_plan_clear_v1_t>(reg, GGML_NPU_COMPILED_PLAN_CLEAR_V1_PROC);
        auto success = [&](bool ok) { check(ok, error(backend)); };
        replay_graph replay;
        replay.build(read_json(argv[3]).at("manifest"));
        const auto metadata = read_json(std::string(argv[2]) + "/metadata.json");
        const auto index = metadata.at("provenance").at("node_bindings")[0].at("manifest_graph_index").get<int>();
        auto * output = replay.nodes.at(index);
        auto * view = output->src[0];
        auto * root = view->view_src;
        auto * bias = output->src[1];
        check(root && bias && ggml_nbytes(output) == 64, "canonical P00 graph slice");
        auto snapshot = [&]() {
            ggml_npu_compiled_plan_status_v1 result = {};
            check(status(backend, &result), "status");
            return result;
        };
        auto zero_effect = [&]() {
            auto s = snapshot();
            check(!s.runtime_ready && !s.execute_calls && !s.submitted_generations && !s.is_active_plan,
                  "bad provenance must not create runtime, consume generation, or grant admission");
        };
        success(load(backend, argv[2]));
        check(!manual(backend, index, output, index), "v1 must not bypass canonical provenance");
        zero_effect();
        const std::string name = ggml_get_name(view);
        ggml_set_name(view, "wrong-canonical-view");
        check(!bind(backend, argv[3], replay.graph), "changed VIEW name must fail");
        check(std::string(error(backend)).find(".name") != std::string::npos, error(backend));
        zero_effect();
        ggml_set_name(view, name.c_str());
        const auto stride = bias->nb[1];
        bias->nb[1] += 4;
        check(!bind(backend, argv[3], replay.graph), "changed weight layout must fail");
        zero_effect();
        bias->nb[1] = stride;
        auto * saved_root = view->view_src;
        view->view_src = bias;
        check(!bind(backend, argv[3], replay.graph), "wrong VIEW root must fail");
        zero_effect();
        view->view_src = saved_root;
        auto * saved_src = output->src[1];
        output->src[1] = root;
        check(!bind(backend, argv[3], replay.graph), "wrong constant edge must fail");
        zero_effect();
        output->src[1] = saved_src;
        success(bind(backend, argv[3], replay.graph));
        check(snapshot().is_active_plan && !snapshot().runtime_ready, "no-alloc canonical seal");
        check(ggml_backend_supports_op(backend, root),
              "uncovered required producer stays on strict NPU admission");
        check(ggml_backend_graph_compute(backend, replay.graph) == GGML_STATUS_FAILED,
              "full graph cannot execute a partial artifact or fall back");
        check(std::string(error(backend)).find("CPU tensor fallback is forbidden") != std::string::npos &&
              !snapshot().runtime_ready && snapshot().submitted_generations == 0,
              "uncovered canonical node reports exact error before runtime creation");


        std::array<float, 16> input = {}, weight = {}, actual = {}, expected = {};
        std::ifstream weights(std::string(argv[2]) + "/weights.bin", std::ios::binary);
        check(bool(weights.read(reinterpret_cast<char *>(weight.data()), 64)), "raw GGUF weight bytes");
        root->data = view->data = input.data();
        bias->data = weight.data();
        output->data = actual.data();
        auto sentinel = [&]() { std::memset(actual.data(), 0xa5, 64); };
        auto preserved = [&]() {
            std::array<unsigned char, 64> value;
            value.fill(0xa5);
            return std::memcmp(actual.data(), value.data(), 64) == 0;
        };
        sentinel();
        reinterpret_cast<unsigned char *>(weight.data())[0] ^= 1;
        check(launch(backend) == GGML_STATUS_FAILED, "wrong weight bytes must fail before launch");
        check(snapshot().last_error == GGML_NPU_COMPILED_PLAN_ERROR_WEIGHT_IDENTITY_V1 &&
              !snapshot().runtime_ready && snapshot().submitted_generations == 0 && preserved(),
              "weight mismatch precise error and zero side effects");
        reinterpret_cast<unsigned char *>(weight.data())[0] ^= 1;
        for (int generation = 1; generation <= 2; ++generation) {
            input.fill(generation == 1 ? 0.0f : 1.0f);
            // Independent test oracle only; production never evaluates a tensor on CPU.
            for (int lane = 0; lane < 16; ++lane) expected[lane] = input[lane] + weight[lane];
            sentinel();
            success(launch(backend) == GGML_STATUS_SUCCESS);
            check(std::memcmp(actual.data(), expected.data(), 64) == 0, "bitwise F32 P00 output");
            const auto s = snapshot();
            check(s.last_generation == static_cast<unsigned>(generation) &&
                  s.execute_calls == static_cast<unsigned>(generation) &&
                  s.successful_bundles == static_cast<unsigned>(generation),
                  "one whole artifact execution per generation");
        }
        ggml_npu_compiled_plan_audit_v2 evidence = {};
        check(audit(backend, &evidence), "audit");
        check(evidence.constructor_count == 1 && evidence.reset_release_count == 1 &&
              evidence.boot_count == 1 && evidence.launch_accepts == 2 &&
              evidence.rtl_starts == 2 && evidence.macro_terminals == 2,
              "two launches reuse one fixed firmware/SystemTop boot");
        sentinel();
        const auto old_param = root->op_params[0];
        root->op_params[0] ^= 1;
        check(launch(backend) == GGML_STATUS_FAILED, "mutated producer semantics after seal must fail");
        check(snapshot().submitted_generations == 2 && preserved(), "post-seal failure preserves output/generation");
        root->op_params[0] = old_param;
        check(clear(backend), "clear plan before destroying graph");
        ggml_backend_free(backend);
        backend = nullptr;
        std::printf("[NPU-COMPILED-CANONICAL][PASS] checks=%u source=exact-manifest-replay "
                    "commands=1 generations=2 constructors=1 resets=1 boots=1 cpu_tensor_fallbacks=0\n", checks);
        return 0;
    } catch (const std::exception & e) {
        std::fprintf(stderr, "[NPU-COMPILED-CANONICAL][FAIL] %s\n", e.what());
        if (backend) ggml_backend_free(backend);
        return 1;
    }
}
