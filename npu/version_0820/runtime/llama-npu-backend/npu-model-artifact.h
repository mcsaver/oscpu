#ifndef NPU_MODEL_ARTIFACT_H
#define NPU_MODEL_ARTIFACT_H
#include "npu-system-session.h"
#include "npu-command-abi.h"
#include "npu-compiled-bundle.h"
#include <nlohmann/json.hpp>
#include <string>
#include <vector>
using npu_model_json = nlohmann::ordered_json;

struct npu_model_binding {
    const std::uint8_t * input = nullptr;
    std::uint8_t * output = nullptr;
    std::size_t bytes = 0;
};
struct npu_model_buffer {
    std::string id, kind;
    std::uint64_t bytes = 0, weight_offset = 0, base = 0;
    std::uint32_t permissions = 0;
    std::int64_t binding = -1;
};
struct npu_model_reloc {
    std::uint32_t command = 0, word = 0, buffer = 0;
    std::uint64_t addend = 0;
};
struct npu_model_publication {
    std::uint32_t buffer = 0, binding = 0;
    std::uint64_t offset = 0, bytes = 0;
};
struct npu_model_command {
    std::string canonical_id, name, op;
    std::uint64_t graph_index = 0, max_cycles = 0;
    npu_system_command_contract contract = {};
};
struct npu_model_copy_reloc {
    std::uint32_t command = 0, phase = 0, src_buffer = 0, dst_buffer = 0;
    std::uint64_t src_offset = 0, dst_offset = 0, bytes = 0;
};
struct npu_model_metadata {
    std::string schema = "npu-compiled-model-v1", command_sha256, weights_sha256;
    std::vector<npu_model_buffer> buffers;
    std::vector<npu_model_reloc> relocations;
    std::vector<npu_model_command> commands;
    std::vector<npu_model_copy_reloc> copies;
    std::vector<npu_model_publication> publications;
};
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_system_command_identity, kernel_id, command_flags, context_id, sequence_id, producer_id, user_tag, covered_node_count, node_hash_lo, node_hash_hi, local_profile)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_system_f32_alu_contract, request_groups, response_groups, read_groups, write_groups, input_words, output_words, read_bytes, write_bytes, completion_vector_elements, expected_starts)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_system_memory_contract, gmem_reads, gmem_writes, gmem_read_bytes, gmem_write_bytes, q8_groups, q8_blocks, q8_macs, vector_elements, state_updates, mover)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_system_command_contract, owner, expected_outcome, expected_npu_error_code, identity, f32_alu, memory, max_cycles)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_buffer, id, kind, bytes, weight_offset, base, permissions, binding)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_reloc, command, word, buffer, addend)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_publication, buffer, binding, offset, bytes)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_command, canonical_id, name, op, graph_index, max_cycles, contract)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_copy_reloc, command, phase, src_buffer, dst_buffer, src_offset, dst_offset, bytes)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(npu_model_metadata, schema, command_sha256, weights_sha256, buffers, relocations, commands, copies, publications)

std::string npu_model_hash(const void * bytes, std::size_t size);
std::vector<std::uint8_t> npu_model_command_image(const std::vector<npu_command_abi_words> & words);
bool npu_model_execute(const std::string & directory, const std::string & expected_metadata_sha256,
    const std::vector<npu_model_binding> & bindings, npu_system_session & session,
    std::uint64_t generation, npu_system_dispatch_result * result, std::string * error);
#endif
