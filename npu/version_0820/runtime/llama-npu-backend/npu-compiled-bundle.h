#ifndef LLAMA_NPU_COMPILED_BUNDLE_H
#define LLAMA_NPU_COMPILED_BUNDLE_H

#include "npu-command-abi.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

constexpr std::size_t NPU_COMPILED_COMMAND_HEADER_BYTES = 64U;
constexpr std::size_t NPU_COMPILED_COMMAND_RECORD_BYTES =
    NPU_COMMAND_ABI_BYTES;
constexpr std::uint16_t NPU_COMPILED_BUNDLE_ABI_MAJOR = 1U;
constexpr std::uint16_t NPU_COMPILED_BUNDLE_ABI_MINOR = 1U;
constexpr std::uint64_t NPU_COMPILED_WEIGHT_ALIGNMENT = 64U;
constexpr std::uint16_t NPU_COMPILED_RUNTIME_SERVICE_ABI_MAJOR = 1U;
constexpr std::uint16_t NPU_COMPILED_RUNTIME_SERVICE_ABI_MINOR = 1U;

enum class npu_compiled_buffer_kind : std::uint32_t {
    input = 0U,
    output,
    scratch,
    transient,
    weight,
};

struct npu_compiled_buffer_info {
    std::string id;
    npu_compiled_buffer_kind kind = npu_compiled_buffer_kind::input;
    std::uint64_t size = 0U;
    std::uint64_t alignment = 0U;
    std::uint32_t permissions = 0U;
    std::uint64_t weights_offset = 0U;
    std::array<std::uint8_t, 32> sha256 = {};
};

enum class npu_compiled_command_owner : std::uint32_t {
    f32_alu = 0U,
};

// Immutable command identity echoed by the CPU/NPU completion path.  These
// ten values are compiler-owned metadata, but the loader accepts them only
// when each value exactly matches its corresponding descriptor field.
struct npu_compiled_command_identity {
    std::uint32_t kernel_id = 0U;
    std::uint32_t command_flags = 0U;
    std::uint32_t context_id = 0U;
    std::uint64_t sequence_id = 0U;
    std::uint64_t producer_id = 0U;
    std::uint64_t user_tag = 0U;
    std::uint32_t covered_node_count = 0U;
    std::uint64_t node_hash_lo = 0U;
    std::uint64_t node_hash_hi = 0U;
    std::uint32_t local_profile = 0U;
};

// Exact proof ledger expected from the currently supported raw F32 portal.
// Every field is a checked u64; the runtime consumes this contract rather
// than re-deriving traffic counts from descriptor shape.
struct npu_compiled_f32_alu_workload {
    std::uint64_t request_groups = 0U;
    std::uint64_t response_groups = 0U;
    std::uint64_t read_groups = 0U;
    std::uint64_t write_groups = 0U;
    std::uint64_t input_words = 0U;
    std::uint64_t output_words = 0U;
    std::uint64_t read_bytes = 0U;
    std::uint64_t write_bytes = 0U;
    std::uint64_t completion_vector_elements = 0U;
    std::uint64_t expected_starts = 0U;
};

struct npu_compiled_command_info {
    std::uint32_t index = 0U;
    std::string name;
    std::vector<std::uint64_t> node_ids;
    std::array<std::uint8_t, 32> node_sha256 = {};
    std::array<std::uint8_t, 32> descriptor_sha256 = {};
    std::uint64_t cycle_upper_bound = 0U;
    npu_compiled_command_owner owner =
        npu_compiled_command_owner::f32_alu;
    npu_compiled_command_identity identity = {};
    npu_compiled_f32_alu_workload f32_alu = {};
};

enum class npu_compiled_relocation_kind : std::uint32_t {
    iova64 = 0U,
    window_base64,
};

struct npu_compiled_relocation_info {
    std::uint32_t command_index = 0U;
    std::uint32_t word_index = 0U;
    npu_compiled_relocation_kind kind =
        npu_compiled_relocation_kind::iova64;
    std::string buffer_id;
    std::uint64_t addend = 0U;
};

struct npu_compiled_runtime_service_abi {
    std::uint16_t major = 0U;
    std::uint16_t minor = 0U;
};

enum class npu_compiled_publication_mode : std::uint32_t {
    bundle_atomic = 0U,
};

// Publication copies already-computed raw bytes from a private output shadow
// to the corresponding external output capability.  Source and target ranges
// independently form an exact partition of every output buffer.
struct npu_compiled_publication_entry {
    std::string buffer_id;
    std::uint64_t source_offset = 0U;
    std::uint64_t target_offset = 0U;
    std::uint64_t bytes = 0U;
};

// Canonical compiler provenance.  source_commit is deliberately nullable so
// synthetic fixtures can identify themselves without fabricating a Git id.
struct npu_compiled_provenance_source {
    std::string schema;
    std::array<std::uint8_t, 32> manifest_sha256 = {};
    std::array<std::uint8_t, 32> raw_sha256 = {};
    std::string graph_ir_schema;
    std::array<std::uint8_t, 32> graph_ir_sha256 = {};
    std::string profile;
    bool has_source_commit = false;
    std::string source_commit;
    std::string graph_scope;
};

struct npu_compiled_node_binding {
    std::uint64_t artifact_node_id = 0U;
    std::string canonical_id;
    std::uint64_t manifest_graph_index = 0U;
    std::array<std::uint8_t, 32> source_descriptor_sha256 = {};
    std::array<std::uint8_t, 32> command_descriptor_sha256 = {};
    std::uint64_t artifact_schedule_position = 0U;
    std::uint64_t source_schedule_position = 0U;
    std::string profile_family;
    std::string profile_id;
};

struct npu_compiled_provenance_origin {
    std::string kind;
    std::uint64_t index = 0U;
    bool has_canonical_id = false;
    std::string canonical_id;
    std::array<std::uint8_t, 32> tensor_descriptor_sha256 = {};
};

// The logical and storage origins live in one binding.  A view therefore does
// not require a second overlapping runtime capability: buffer.size and
// storage_size name the normalized root, and the logical range is checked
// within it using alias_offset/logical_size.
struct npu_compiled_buffer_binding {
    std::string buffer_id;
    npu_compiled_provenance_origin logical = {};
    npu_compiled_provenance_origin storage = {};
    std::uint64_t alias_offset = 0U;
    std::uint64_t logical_size = 0U;
    std::uint64_t storage_size = 0U;
};

// Immutable artifact template.  command_template includes the 64-byte file
// header.  The firmware consumes records beginning at byte 64 after relocate.
struct npu_compiled_bundle {
    std::vector<std::uint8_t> command_template;
    std::vector<std::uint8_t> weights;
    std::vector<std::uint8_t> metadata_json;
    std::string graph_name;
    std::string bundle_id;
    std::vector<npu_compiled_buffer_info> buffers;
    std::vector<npu_compiled_command_info> commands;
    std::vector<npu_compiled_relocation_info> relocations;
    npu_compiled_runtime_service_abi runtime_service = {};
    npu_compiled_publication_mode publication_mode =
        npu_compiled_publication_mode::bundle_atomic;
    std::vector<npu_compiled_publication_entry> publications;
    npu_compiled_provenance_source provenance_source = {};
    std::vector<npu_compiled_node_binding> provenance_nodes;
    std::vector<npu_compiled_buffer_binding> provenance_buffers;
};

// Shared byte hash for compiler provenance at the live GGML boundary.
std::array<std::uint8_t, 32> npu_compiled_sha256(const void * data, std::size_t size);

// Runtime-owned registered capability.  v3 requires exact size and permission
// equality with metadata, so a larger or more permissive allocation cannot
// silently broaden the compiled command's authority.
struct npu_compiled_named_binding {
    std::string buffer_id;
    std::uint64_t base = 0U;
    std::uint64_t size = 0U;
    std::uint32_t permissions = 0U;
};

enum class npu_compiled_bundle_error : std::uint32_t {
    none = 0U,
    null_argument,
    file_open,
    file_size,
    file_read,
    allocation_failure,
    command_magic,
    command_version,
    command_header_size,
    command_record_size,
    command_flags,
    command_size,
    command_payload_hash,
    json_parse,
    json_duplicate_key,
    metadata_noncanonical,
    metadata_schema,
    metadata_keys,
    metadata_type,
    metadata_range,
    metadata_value,
    metadata_hash,
    bundle_id,
    artifact_size,
    artifact_hash,
    buffer_duplicate,
    buffer_order,
    buffer_kind,
    buffer_alignment,
    buffer_permission,
    buffer_range,
    buffer_overlap,
    weight_hash,
    weight_padding,
    command_count,
    command_order,
    command_duplicate,
    descriptor_hash,
    kernel_id,
    command_owner,
    command_identity,
    command_workload,
    node_hash,
    node_count,
    runtime_abi,
    publication_mode,
    publication_order,
    publication_duplicate,
    publication_buffer,
    publication_permission,
    publication_range,
    publication_coverage,
    publication_producer,
    publication_unwritten_source,
    relocation_order,
    relocation_duplicate,
    relocation_command,
    relocation_word,
    relocation_kind,
    relocation_buffer,
    relocation_range,
    relocation_template,
    relocation_pair,
    relocation_src2,
    binding_unknown,
    binding_duplicate,
    binding_missing,
    binding_size,
    binding_alignment,
    binding_permission,
    binding_overflow,
    binding_overlap,
    command_abi,
    transient_read_before_write,
    provenance_format,
    provenance_node_duplicate,
    provenance_node_order,
    provenance_node_coverage,
    provenance_node_descriptor,
    provenance_buffer_duplicate,
    provenance_buffer_order,
    provenance_buffer_coverage,
    provenance_buffer_range,
};

struct npu_compiled_bundle_diagnostic {
    npu_compiled_bundle_error error = npu_compiled_bundle_error::none;
    std::string path;
    std::string detail;
    std::size_t command_index = static_cast<std::size_t>(-1);
    std::size_t relocation_index = static_cast<std::size_t>(-1);
    npu_command_abi_diagnostic command_abi = {};
};

// Reads command.bin, weights.bin, and metadata.json from directory.  All
// structural and cryptographic checks complete before output is replaced.
bool npu_compiled_bundle_load(
        const std::string & directory,
        npu_compiled_bundle * output,
        npu_compiled_bundle_diagnostic * diagnostic = nullptr);

// Re-parse the immutable three-file byte images and return canonical parsed
// fields.  Public struct fields are never authority: production callers must
// consume owner/workload/publication data only from this canonical output.
// input and output may alias; on failure output remains byte-for-byte intact.
bool npu_compiled_bundle_revalidate(
        const npu_compiled_bundle * input,
        npu_compiled_bundle * output,
        npu_compiled_bundle_diagnostic * diagnostic = nullptr);

// Resolve every relocation through BufferId and use npu-command-abi's private
// shadow primitive for each record.  The returned full command image receives
// a new payload SHA-256.  On failure output is byte-for-byte unchanged; the
// caller must therefore ring a doorbell only after this function returns true.
bool npu_compiled_bundle_relocate(
        const npu_compiled_bundle * bundle,
        const npu_compiled_named_binding * bindings,
        std::size_t binding_count,
        std::vector<std::uint8_t> * output,
        npu_compiled_bundle_diagnostic * diagnostic = nullptr);

bool npu_compiled_bundle_decode_record(
        const std::vector<std::uint8_t> & command_image,
        std::size_t command_index,
        npu_command_abi_words * words,
        npu_compiled_bundle_diagnostic * diagnostic = nullptr);

const char * npu_compiled_bundle_error_string(
        npu_compiled_bundle_error error);

#endif
