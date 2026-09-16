#ifndef NPU_GGML_MANIFEST_H
#define NPU_GGML_MANIFEST_H
#include "npu-compiled-bundle.h"
#include "ggml.h"
#include <memory>
#include <string>
#include <vector>

// Immutable manifest/live-graph correspondence. No tensor computation and no
// address-dependent command encoding occurs here.
struct npu_ggml_manifest_plan {
    struct state;
    std::shared_ptr<const state> proof;
    std::vector<ggml_tensor *> nodes;   // artifact command order
    std::vector<ggml_tensor *> buffers; // artifact buffer order, logical tensors
    std::vector<int> graph_indices;
};

bool npu_ggml_manifest_bind(
    const npu_compiled_bundle & bundle, const char * manifest_path,
    ggml_cgraph * full_graph, npu_ggml_manifest_plan * result,
    std::string * failure);
bool npu_ggml_manifest_revalidate(
    const npu_ggml_manifest_plan & plan, ggml_cgraph * full_graph,
    std::string * failure);
#endif
