#include "npu-ggml-manifest.h"
#include <nlohmann/json.hpp>
#include <array>
#include <fstream>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>
#include <unordered_map>

using json = nlohmann::json;

struct npu_ggml_manifest_plan::state {
    json manifest;
    std::vector<ggml_tensor *> nodes;
    std::vector<ggml_tensor *> external;
    std::unordered_map<const ggml_tensor *, json> refs;
};

namespace {
void require(bool ok, const std::string & path, const std::string & detail) {
    if (!ok) throw std::runtime_error("MANIFEST_BIND at " + path + ": " + detail);
}
std::string hex(const std::uint8_t * bytes, std::size_t size) {
    static const char alphabet[] = "0123456789abcdef";
    std::string result;
    result.reserve(size * 2);
    for (std::size_t i = 0; i < size; ++i) {
        result += alphabet[bytes[i] >> 4];
        result += alphabet[bytes[i] & 15];
    }
    return result;
}
std::string hex(const std::array<std::uint8_t, 32> & value) {
    return hex(value.data(), value.size());
}
std::string digest(const json & value) {
    const std::string bytes = value.dump(-1, ' ', false);
    return hex(npu_compiled_sha256(bytes.data(), bytes.size()));
}
json ref_for(const npu_ggml_manifest_plan::state & state,
             const ggml_tensor * tensor, const std::string & path) {
    if (tensor == nullptr) return nullptr;
    const auto it = state.refs.find(tensor);
    require(it != state.refs.end(), path, "tensor is not in the original graph registry");
    return it->second;
}
ggml_tensor * resolve(const npu_ggml_manifest_plan::state & state,
                      const json & ref, const std::string & path) {
    require(ref.is_object() && ref.size() == 2 && ref.contains("kind") &&
            ref.contains("index") && ref.at("index").is_number_unsigned(),
            path, "invalid tensor reference");
    const auto index = ref.at("index").get<std::uint64_t>();
    const auto & list = ref.at("kind") == "node" ? state.nodes : state.external;
    require(ref.at("kind") == "node" || ref.at("kind") == "external",
            path, "unknown reference kind");
    require(index < list.size() && list[index] != nullptr, path, "unresolved tensor reference");
    return list[index];
}
json descriptor(const npu_ggml_manifest_plan::state & state,
                const ggml_tensor * tensor, const std::string & path) {
    require(tensor != nullptr, path, "null tensor");
    require(tensor->op >= GGML_OP_NONE && tensor->op < GGML_OP_COUNT &&
            tensor->type >= GGML_TYPE_F32 && tensor->type < GGML_TYPE_COUNT,
            path, "invalid GGML op/type enum");
    json ne = json::array(), nb = json::array();
    for (int i = 0; i < GGML_MAX_DIMS; ++i) {
        ne.push_back(tensor->ne[i]);
        nb.push_back(tensor->nb[i]);
    }
    return {
        {"flags", tensor->flags}, {"name", ggml_get_name(tensor)},
        {"ne", ne}, {"nb", nb}, {"op_id", tensor->op},
        {"op_name", ggml_op_name(tensor->op)}, {"op_desc", ggml_op_desc(tensor)},
        {"type_id", tensor->type}, {"type_name", ggml_type_name(tensor->type)},
        {"op_params_hex", hex(reinterpret_cast<const std::uint8_t *>(tensor->op_params),
                              sizeof(tensor->op_params))},
        {"view_offs", tensor->view_offs},
        {"view_src", ref_for(state, tensor->view_src, path + ".view_src")},
    };
}
void compare(const json & actual, const json & expected, const std::string & path) {
    require(actual.size() == expected.size(), path, "descriptor fields differ");
    for (auto it = actual.begin(); it != actual.end(); ++it) {
        require(expected.contains(it.key()) && expected.at(it.key()) == it.value(),
                path + "." + it.key(), "live GGML descriptor differs from compiler source");
    }
}
void validate_live(const npu_ggml_manifest_plan::state & state, ggml_cgraph * graph) {
    require(graph != nullptr && ggml_graph_n_nodes(graph) == static_cast<int>(state.nodes.size()),
            "$graph", "whole graph node count changed");
    for (std::size_t i = 0; i < state.nodes.size(); ++i) {
        require(ggml_graph_node(graph, static_cast<int>(i)) == state.nodes[i],
                "$graph.nodes[" + std::to_string(i) + "]", "node pointer/order changed");
    }
    const auto check_list = [&](const char * field, const std::vector<ggml_tensor *> & tensors) {
        const auto & rows = state.manifest.at(field);
        for (std::size_t i = 0; i < rows.size(); ++i) {
            const std::string path = std::string("$manifest.") + field + "[" + std::to_string(i) + "]";
            const auto * tensor = tensors[i];
            compare(descriptor(state, tensor, path), rows[i].at("descriptor"), path + ".descriptor");
            const auto & sources = rows[i].at("sources");
            require(sources.is_array() && sources.size() <= GGML_MAX_SRC, path, "invalid source count");
            for (std::size_t slot = 0; slot < GGML_MAX_SRC; ++slot) {
                const std::string src_path = path + ".sources[" + std::to_string(slot) + "]";
                if (slot >= sources.size()) {
                    require(tensor->src[slot] == nullptr, src_path, "extra live source");
                    continue;
                }
                require(sources[slot].at("slot") == slot &&
                        resolve(state, sources[slot].at("ref"), src_path) == tensor->src[slot],
                        src_path, "source pointer/slot differs from manifest");
                compare(descriptor(state, tensor->src[slot], src_path),
                        sources[slot].at("descriptor"), src_path + ".descriptor");
            }
        }
    };
    check_list("nodes", state.nodes);
    check_list("external_tensors", state.external);
}
void register_external(npu_ggml_manifest_plan::state & state, const json & ref,
                       ggml_tensor * tensor, const std::string & path) {
    if (ref.is_null()) {
        require(tensor == nullptr, path, "unexpected tensor for null reference");
        return;
    }
    require(tensor != nullptr, path, "missing live tensor");
    const auto kind = ref.at("kind").get<std::string>();
    const auto index = ref.at("index").get<std::uint64_t>();
    if (kind == "node") {
        require(index < state.nodes.size() && state.nodes[index] == tensor,
                path, "wrong graph node reference");
        return;
    }
    require(kind == "external" && index < state.external.size(), path, "unknown external index");
    require(state.external[index] == nullptr || state.external[index] == tensor,
            path, "external index resolves to multiple pointers");
    const auto found = state.refs.find(tensor);
    require(found == state.refs.end() || found->second == ref,
            path, "one tensor resolves to multiple identities");
    state.external[index] = tensor;
    state.refs[tensor] = ref;
}
const json & origin_row(const npu_ggml_manifest_plan::state & state,
                        const npu_compiled_provenance_origin & origin,
                        const std::string & path) {
    const auto & rows = state.manifest.at(origin.kind == "graph_node" ? "nodes" : "external_tensors");
    require(origin.kind == "graph_node" || origin.kind == "constant", path, "unsupported origin");
    require(origin.index < rows.size(), path, "origin index out of range");
    const auto & row = rows[origin.index];
    require(digest(row.at("descriptor")) == hex(origin.tensor_descriptor_sha256),
            path, "tensor descriptor hash mismatch");
    if (origin.kind == "graph_node") {
        require(origin.has_canonical_id && origin.canonical_id == row.at("canonical_id"),
                path, "canonical origin mismatch");
    } else {
        require(!origin.has_canonical_id, path, "constant has a node identity");
    }
    return row;
}
ggml_tensor * origin_tensor(const npu_ggml_manifest_plan::state & state,
                            const npu_compiled_provenance_origin & origin,
                            const std::string & path) {
    origin_row(state, origin, path);
    return resolve(state, {{"kind", origin.kind == "graph_node" ? "node" : "external"},
                           {"index", origin.index}}, path);
}
} // namespace

bool npu_ggml_manifest_bind(
        const npu_compiled_bundle & bundle, const char * manifest_path,
        ggml_cgraph * graph, npu_ggml_manifest_plan * result, std::string * failure) {
    try {
        require(result != nullptr && failure != nullptr && manifest_path != nullptr &&
                manifest_path[0] != 0 && graph != nullptr, "$arguments", "null/empty argument");
        require(bundle.provenance_source.schema == "qwen-npu-graph-manifest-v2",
                "$bundle.provenance.source.schema", "canonical Qwen source required");
        std::ifstream input(manifest_path, std::ios::binary | std::ios::ate);
        require(input.good(), "$manifest", "cannot open manifest");
        const auto size = input.tellg();
        require(size > 0 && size <= 64 * 1024 * 1024, "$manifest", "manifest size outside limit");
        std::string bytes(static_cast<std::size_t>(size), '\0');
        input.seekg(0);
        require(bool(input.read(bytes.data(), size)), "$manifest", "short read");
        const auto envelope = json::parse(bytes);
        require(envelope.dump(-1, ' ', false) + "\n" == bytes, "$manifest",
                "noncanonical JSON encoding (including duplicate keys)");
        require(envelope.at("schema") == "qwen-npu-graph-manifest-envelope-v2",
                "$manifest.schema", "unsupported manifest envelope");
        auto state = std::make_shared<npu_ggml_manifest_plan::state>();
        state->manifest = envelope.at("manifest");
        const auto & manifest = state->manifest;
        const auto & provenance = bundle.provenance_source;
        const std::string manifest_hash = digest(manifest);
        require(envelope.at("manifest_sha256") == manifest_hash &&
                manifest_hash == hex(provenance.manifest_sha256),
                "$manifest.manifest_sha256", "manifest does not match the compiled bundle");
        require(manifest.at("schema") == provenance.schema &&
                manifest.at("raw_sha256") == hex(provenance.raw_sha256) &&
                manifest.at("header").at("bindings").at("profile") == provenance.profile &&
                manifest.at("header").at("bindings").at("source_commit") == provenance.source_commit &&
                provenance.has_source_commit &&
                manifest.at("header").at("graph").at("scope") == provenance.graph_scope,
                "$bundle.provenance.source", "source identity mismatch");
        const auto & nodes = manifest.at("nodes");
        const auto & external = manifest.at("external_tensors");
        require(nodes.size() <= static_cast<std::size_t>(std::numeric_limits<int>::max()) &&
                ggml_graph_n_nodes(graph) == static_cast<int>(nodes.size()),
                "$graph", "expected complete pre-scheduler manifest graph");
        state->nodes.reserve(nodes.size());
        state->external.resize(external.size(), nullptr);
        for (std::size_t i = 0; i < nodes.size(); ++i) {
            auto * tensor = ggml_graph_node(graph, static_cast<int>(i));
            require(tensor != nullptr && nodes[i].at("index") == i,
                    "$graph.nodes", "null tensor or noncontiguous index");
            require(state->refs.emplace(tensor, json{{"kind", "node"}, {"index", i}}).second,
                    "$graph.nodes", "duplicate tensor pointer");
            state->nodes.push_back(tensor);
        }
        // Resolve externals from graph edges, then external edges/view roots.
        // No caller-supplied index-to-pointer mapping is trusted.
        const auto scan = [&](const json & row, ggml_tensor * tensor, const std::string & path) {
            const auto & sources = row.at("sources");
            require(sources.size() <= GGML_MAX_SRC, path, "too many sources");
            for (std::size_t slot = 0; slot < sources.size(); ++slot)
                register_external(*state, sources[slot].at("ref"), tensor->src[slot], path);
            register_external(*state, row.at("descriptor").at("view_src"), tensor->view_src, path);
        };
        for (std::size_t i = 0; i < nodes.size(); ++i)
            scan(nodes[i], state->nodes[i], "$graph.nodes[" + std::to_string(i) + "]");
        std::set<std::size_t> scanned;
        bool progress = true;
        while (progress) {
            progress = false;
            for (std::size_t i = 0; i < external.size(); ++i) {
                if (state->external[i] && scanned.insert(i).second) {
                    scan(external[i], state->external[i], "$graph.external[" + std::to_string(i) + "]");
                    progress = true;
                }
            }
        }
        require(scanned.size() == external.size(), "$graph.external", "unresolved external tensor");
        validate_live(*state, graph);

        npu_ggml_manifest_plan candidate;
        for (std::size_t i = 0; i < bundle.commands.size(); ++i) {
            const auto & binding = bundle.provenance_nodes.at(i);
            const std::string path = "$bundle.node_bindings[" + std::to_string(i) + "]";
            require(binding.manifest_graph_index < nodes.size() &&
                    binding.artifact_schedule_position == i, path, "invalid schedule/index");
            const auto & node = nodes[binding.manifest_graph_index];
            require(binding.canonical_id == node.at("canonical_id") &&
                    digest(node.at("semantic_key")) == binding.canonical_id &&
                    digest(json{{"descriptor", node.at("descriptor")}, {"sources", node.at("sources")}})
                        == hex(binding.source_descriptor_sha256),
                    path, "canonical/source descriptor identity mismatch");
            std::uint64_t schedule = 0;
            for (std::size_t k = 0; k < binding.manifest_graph_index; ++k)
                if (nodes[k].at("classification") != "metadata") ++schedule;
            require(schedule == binding.source_schedule_position, path, "source schedule mismatch");
            candidate.nodes.push_back(state->nodes[binding.manifest_graph_index]);
            candidate.graph_indices.push_back(static_cast<int>(binding.manifest_graph_index));
        }
        for (const auto & buffer : bundle.buffers) {
            const npu_compiled_buffer_binding * binding = nullptr;
            for (const auto & item : bundle.provenance_buffers)
                if (item.buffer_id == buffer.id) binding = &item;
            require(binding != nullptr, "$bundle.buffers." + buffer.id, "missing provenance");
            const std::string path = "$bundle.buffers." + buffer.id;
            auto * logical = origin_tensor(*state, binding->logical, path + ".logical");
            auto * storage = origin_tensor(*state, binding->storage, path + ".storage");
            require((logical->view_src ? logical->view_src : logical) == storage &&
                    logical->view_offs == binding->alias_offset &&
                    ggml_nbytes(logical) == binding->logical_size &&
                    ggml_nbytes(storage) == binding->storage_size &&
                    binding->storage_size == buffer.size,
                    path, "VIEW/storage normalization mismatch");
            // Current executable backend admits only whole-root offset-zero P00.
            require(binding->alias_offset == 0 && binding->logical_size == buffer.size,
                    path, "unsupported nonzero/subrange view");
            candidate.buffers.push_back(logical);
        }
        candidate.proof = std::move(state);
        *result = std::move(candidate);
        failure->clear();
        return true;
    } catch (const std::exception & error) {
        if (failure) *failure = error.what();
        return false;
    }
}
bool npu_ggml_manifest_revalidate(
        const npu_ggml_manifest_plan & plan, ggml_cgraph * graph, std::string * failure) {
    try {
        require(plan.proof != nullptr, "$plan", "missing canonical graph proof");
        validate_live(*plan.proof, graph);
        return true;
    } catch (const std::exception & error) {
        if (failure) *failure = error.what();
        return false;
    }
}
