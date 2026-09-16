#include "npu-compiled-bundle.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

int g_checks = 0;
int g_failures = 0;

bool check(bool condition, const char * label) {
    ++g_checks;
    if (!condition) {
        ++g_failures;
        std::fprintf(stderr, "[NPU-COMPILED-BUNDLE][FAIL] %s\n", label);
    }
    return condition;
}

std::uint32_t rotate_right(std::uint32_t value, unsigned amount) {
    return (value >> amount) | (value << (32U - amount));
}

class sha256_state {
public:
    void update(const std::uint8_t * bytes, std::size_t size) {
        if (size > std::numeric_limits<std::uint64_t>::max() - total_) {
            throw std::length_error("SHA-256 input length overflow");
        }
        total_ += static_cast<std::uint64_t>(size);
        while (size != 0U) {
            const std::size_t take = std::min(size, block_.size() - used_);
            std::memcpy(block_.data() + used_, bytes, take);
            used_ += take;
            bytes += take;
            size -= take;
            if (used_ == block_.size()) {
                transform(block_.data());
                used_ = 0U;
            }
        }
    }

    std::array<std::uint8_t, 32> finish() {
        const std::uint64_t bits = total_ * 8U;
        block_[used_++] = 0x80U;
        if (used_ > 56U) {
            std::fill(block_.begin() + static_cast<std::ptrdiff_t>(used_),
                      block_.end(), 0U);
            transform(block_.data());
            used_ = 0U;
        }
        std::fill(block_.begin() + static_cast<std::ptrdiff_t>(used_),
                  block_.begin() + 56, 0U);
        for (unsigned index = 0; index < 8U; ++index) {
            block_[63U - index] =
                static_cast<std::uint8_t>(bits >> (8U * index));
        }
        transform(block_.data());
        std::array<std::uint8_t, 32> digest = {};
        for (std::size_t word = 0; word < state_.size(); ++word) {
            digest[word * 4U] =
                static_cast<std::uint8_t>(state_[word] >> 24U);
            digest[word * 4U + 1U] =
                static_cast<std::uint8_t>(state_[word] >> 16U);
            digest[word * 4U + 2U] =
                static_cast<std::uint8_t>(state_[word] >> 8U);
            digest[word * 4U + 3U] =
                static_cast<std::uint8_t>(state_[word]);
        }
        return digest;
    }

private:
    void transform(const std::uint8_t * block) {
        static constexpr std::array<std::uint32_t, 64> k = {{
            0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U,
            0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
            0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
            0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
            0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU,
            0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
            0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
            0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
            0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
            0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
            0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U,
            0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
            0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U,
            0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
            0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
            0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U,
        }};
        std::array<std::uint32_t, 64> words = {};
        for (unsigned index = 0; index < 16U; ++index) {
            words[index] =
                static_cast<std::uint32_t>(block[index * 4U]) << 24U |
                static_cast<std::uint32_t>(block[index * 4U + 1U]) << 16U |
                static_cast<std::uint32_t>(block[index * 4U + 2U]) << 8U |
                static_cast<std::uint32_t>(block[index * 4U + 3U]);
        }
        for (unsigned index = 16U; index < 64U; ++index) {
            const std::uint32_t s0 = rotate_right(words[index - 15U], 7U) ^
                rotate_right(words[index - 15U], 18U) ^
                (words[index - 15U] >> 3U);
            const std::uint32_t s1 = rotate_right(words[index - 2U], 17U) ^
                rotate_right(words[index - 2U], 19U) ^
                (words[index - 2U] >> 10U);
            words[index] = words[index - 16U] + s0 +
                           words[index - 7U] + s1;
        }
        std::uint32_t a = state_[0], b = state_[1], c = state_[2], d = state_[3];
        std::uint32_t e = state_[4], f = state_[5], g = state_[6], h = state_[7];
        for (unsigned index = 0; index < 64U; ++index) {
            const std::uint32_t s1 = rotate_right(e, 6U) ^
                rotate_right(e, 11U) ^ rotate_right(e, 25U);
            const std::uint32_t choose = (e & f) ^ (~e & g);
            const std::uint32_t temporary1 =
                h + s1 + choose + k[index] + words[index];
            const std::uint32_t s0 = rotate_right(a, 2U) ^
                rotate_right(a, 13U) ^ rotate_right(a, 22U);
            const std::uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
            const std::uint32_t temporary2 = s0 + majority;
            h = g; g = f; f = e; e = d + temporary1;
            d = c; c = b; b = a; a = temporary1 + temporary2;
        }
        state_[0] += a; state_[1] += b; state_[2] += c; state_[3] += d;
        state_[4] += e; state_[5] += f; state_[6] += g; state_[7] += h;
    }

    std::array<std::uint32_t, 8> state_ = {{
        0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU,
        0x510e527fU, 0x9b05688cU, 0x1f83d9abU, 0x5be0cd19U,
    }};
    std::array<std::uint8_t, 64> block_ = {};
    std::size_t used_ = 0U;
    std::uint64_t total_ = 0U;
};

std::array<std::uint8_t, 32> sha256_bytes(
        const std::uint8_t * bytes,
        std::size_t size) {
    sha256_state state;
    state.update(bytes, size);
    return state.finish();
}

std::string digest_hex(const std::array<std::uint8_t, 32> & digest) {
    static constexpr char digits[] = "0123456789abcdef";
    std::string result(64U, '0');
    for (std::size_t index = 0U; index < digest.size(); ++index) {
        result[index * 2U] = digits[digest[index] >> 4U];
        result[index * 2U + 1U] = digits[digest[index] & 0xfU];
    }
    return result;
}

std::string sha256_hex(const std::uint8_t * bytes, std::size_t size) {
    return digest_hex(sha256_bytes(bytes, size));
}

std::string sha256_hex(const std::string & text) {
    return sha256_hex(
        reinterpret_cast<const std::uint8_t *>(text.data()), text.size());
}

struct temporary_tree {
    std::filesystem::path path;

    ~temporary_tree() {
        std::error_code ignored;
        std::filesystem::remove_all(path, ignored);
    }
};

temporary_tree make_temporary_tree() {
    const auto nonce = std::chrono::high_resolution_clock::now()
                           .time_since_epoch()
                           .count();
    temporary_tree tree = {
        std::filesystem::temp_directory_path() /
        ("npu-compiled-bundle-test-" + std::to_string(nonce)),
    };
    std::filesystem::create_directories(tree.path);
    return tree;
}

void copy_artifact(
        const std::filesystem::path & source_directory,
        const std::filesystem::path & destination_directory,
        const char * name) {
    std::filesystem::create_directories(destination_directory);
    std::filesystem::copy_file(
        source_directory / name, destination_directory / name,
        std::filesystem::copy_options::overwrite_existing);
}

void copy_bundle(
        const std::filesystem::path & source,
        const std::filesystem::path & destination) {
    copy_artifact(source, destination, "command.bin");
    copy_artifact(source, destination, "weights.bin");
    copy_artifact(source, destination, "metadata.json");
}

std::string read_text_file(const std::filesystem::path & path) {
    std::ifstream stream(path, std::ios::binary | std::ios::ate);
    if (!stream) {
        throw std::runtime_error("cannot read " + path.string());
    }
    const std::ifstream::pos_type end = stream.tellg();
    if (end < 0) {
        throw std::runtime_error("cannot size " + path.string());
    }
    std::string text(static_cast<std::size_t>(end), '\0');
    stream.seekg(0, std::ios::beg);
    if (!text.empty() &&
        !stream.read(text.data(), static_cast<std::streamsize>(text.size()))) {
        throw std::runtime_error("short read " + path.string());
    }
    return text;
}

std::vector<std::uint8_t> read_binary_file(
        const std::filesystem::path & path) {
    std::ifstream stream(path, std::ios::binary | std::ios::ate);
    if (!stream) {
        throw std::runtime_error("cannot read " + path.string());
    }
    const std::ifstream::pos_type end = stream.tellg();
    if (end < 0) {
        throw std::runtime_error("cannot size " + path.string());
    }
    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(end));
    stream.seekg(0, std::ios::beg);
    if (!bytes.empty() &&
        !stream.read(
            reinterpret_cast<char *>(bytes.data()),
            static_cast<std::streamsize>(bytes.size()))) {
        throw std::runtime_error("short read " + path.string());
    }
    return bytes;
}

void write_text_file(
        const std::filesystem::path & path,
        const std::string & text) {
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    if (!stream ||
        (!text.empty() &&
         !stream.write(text.data(), static_cast<std::streamsize>(text.size())))) {
        throw std::runtime_error("cannot write " + path.string());
    }
}

void write_binary_file(
        const std::filesystem::path & path,
        const std::vector<std::uint8_t> & bytes) {
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    if (!stream ||
        (!bytes.empty() &&
         !stream.write(
             reinterpret_cast<const char *>(bytes.data()),
             static_cast<std::streamsize>(bytes.size())))) {
        throw std::runtime_error("cannot write " + path.string());
    }
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (std::size_t index = 0U; index < 8U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

bool replace_once(
        std::string * text,
        const std::string & before,
        const std::string & after) {
    if (text == nullptr) {
        return false;
    }
    const std::size_t position = text->find(before);
    if (position == std::string::npos) {
        return false;
    }
    text->replace(position, before.size(), after);
    return true;
}

bool resign_metadata(std::string * metadata) {
    if (metadata == nullptr) {
        return false;
    }
    static const std::string marker = "\"bundle_id\":\"";
    const std::size_t key = metadata->find(marker);
    if (key == std::string::npos) {
        return false;
    }
    const std::size_t value = key + marker.size();
    const std::size_t closing_quote = value + 64U;
    if (closing_quote >= metadata->size() ||
        (*metadata)[closing_quote] != '"') {
        return false;
    }
    std::string core = *metadata;
    const std::size_t after_field = closing_quote + 1U;
    if (after_field < core.size() && core[after_field] == ',') {
        core.erase(key, after_field - key + 1U);
    } else if (key != 0U && core[key - 1U] == ',') {
        core.erase(key - 1U, after_field - key + 1U);
    } else {
        return false;
    }
    metadata->replace(value, 64U, sha256_hex(core));
    return true;
}

struct metadata_mutation {
    const char * name;
    const char * before;
    const char * after;
    npu_compiled_bundle_error expected;
};

npu_compiled_bundle make_sentinel_bundle() {
    npu_compiled_bundle bundle;
    bundle.command_template = {0xdeU, 0xadU, 0xbeU, 0xefU};
    bundle.weights = {0x11U, 0x22U};
    bundle.metadata_json = {0x33U, 0x44U, 0x55U};
    bundle.graph_name = "sentinel-graph";
    bundle.bundle_id = "sentinel";
    npu_compiled_buffer_info buffer;
    buffer.id = "sentinel-buffer";
    buffer.kind = npu_compiled_buffer_kind::scratch;
    buffer.size = 13U;
    buffer.alignment = 128U;
    buffer.permissions = 3U;
    buffer.weights_offset = 7U;
    buffer.sha256[0] = 0xa1U;
    bundle.buffers.push_back(buffer);
    npu_compiled_command_info command;
    command.index = 9U;
    command.name = "sentinel-command";
    command.node_ids = {41U, 42U};
    command.node_sha256[0] = 0xa2U;
    command.descriptor_sha256[0] = 0xa3U;
    command.cycle_upper_bound = 43U;
    command.owner = static_cast<npu_compiled_command_owner>(99U);
    command.identity = {
        1U, 2U, 3U, 4U, 5U, 6U, 7U, 8U, 9U, 10U,
    };
    command.f32_alu = {
        11U, 12U, 13U, 14U, 15U,
        16U, 17U, 18U, 19U, 20U,
    };
    bundle.commands.push_back(command);
    bundle.relocations.push_back({
        21U, 22U, npu_compiled_relocation_kind::window_base64,
        "sentinel-relocation", 23U,
    });
    bundle.runtime_service = {24U, 25U};
    bundle.publication_mode =
        static_cast<npu_compiled_publication_mode>(99U);
    bundle.publications.push_back({"sentinel-publication", 26U, 27U, 28U});
    bundle.provenance_source.schema = "sentinel-source-v1";
    bundle.provenance_source.manifest_sha256[0] = 0xb1U;
    bundle.provenance_source.raw_sha256[0] = 0xb2U;
    bundle.provenance_source.graph_ir_schema = "sentinel-ir-v1";
    bundle.provenance_source.graph_ir_sha256[0] = 0xb3U;
    bundle.provenance_source.profile = "sentinel:profile";
    bundle.provenance_source.has_source_commit = true;
    bundle.provenance_source.source_commit = "sentinel-commit";
    bundle.provenance_source.graph_scope = "sentinel:scope";
    npu_compiled_node_binding node;
    node.artifact_node_id = 31U;
    node.canonical_id = "sentinel:node";
    node.manifest_graph_index = 32U;
    node.source_descriptor_sha256[0] = 0xb4U;
    node.command_descriptor_sha256[0] = 0xb5U;
    node.artifact_schedule_position = 33U;
    node.source_schedule_position = 34U;
    node.profile_family = "sentinel_family";
    node.profile_id = "sentinel_profile";
    bundle.provenance_nodes.push_back(node);
    npu_compiled_buffer_binding provenance_buffer;
    provenance_buffer.buffer_id = "sentinel-provenance-buffer";
    provenance_buffer.logical.kind = "sentinel-logical";
    provenance_buffer.logical.index = 35U;
    provenance_buffer.logical.has_canonical_id = true;
    provenance_buffer.logical.canonical_id = "sentinel:logical";
    provenance_buffer.logical.tensor_descriptor_sha256[0] = 0xb6U;
    provenance_buffer.storage.kind = "sentinel-storage";
    provenance_buffer.storage.index = 36U;
    provenance_buffer.storage.has_canonical_id = true;
    provenance_buffer.storage.canonical_id = "sentinel:storage";
    provenance_buffer.storage.tensor_descriptor_sha256[0] = 0xb7U;
    provenance_buffer.alias_offset = 37U;
    provenance_buffer.logical_size = 38U;
    provenance_buffer.storage_size = 39U;
    bundle.provenance_buffers.push_back(provenance_buffer);
    return bundle;
}

bool bundle_output_is_sentinel(const npu_compiled_bundle & bundle) {
    if (bundle.command_template !=
            std::vector<std::uint8_t>({0xdeU, 0xadU, 0xbeU, 0xefU}) ||
        bundle.weights != std::vector<std::uint8_t>({0x11U, 0x22U}) ||
        bundle.metadata_json !=
            std::vector<std::uint8_t>({0x33U, 0x44U, 0x55U}) ||
        bundle.graph_name != "sentinel-graph" ||
        bundle.bundle_id != "sentinel" ||
        bundle.buffers.size() != 1U || bundle.commands.size() != 1U ||
        bundle.relocations.size() != 1U || bundle.publications.size() != 1U ||
        bundle.provenance_nodes.size() != 1U ||
        bundle.provenance_buffers.size() != 1U) {
        return false;
    }
    const npu_compiled_buffer_info & buffer = bundle.buffers[0];
    const npu_compiled_command_info & command = bundle.commands[0];
    const npu_compiled_relocation_info & relocation = bundle.relocations[0];
    const npu_compiled_publication_entry & publication = bundle.publications[0];
    const npu_compiled_node_binding & node = bundle.provenance_nodes[0];
    const npu_compiled_buffer_binding & provenance_buffer =
        bundle.provenance_buffers[0];
    return buffer.id == "sentinel-buffer" &&
           buffer.kind == npu_compiled_buffer_kind::scratch &&
           buffer.size == 13U && buffer.alignment == 128U &&
           buffer.permissions == 3U && buffer.weights_offset == 7U &&
           buffer.sha256[0] == 0xa1U &&
           command.index == 9U && command.name == "sentinel-command" &&
           command.node_ids == std::vector<std::uint64_t>({41U, 42U}) &&
           command.node_sha256[0] == 0xa2U &&
           command.descriptor_sha256[0] == 0xa3U &&
           command.cycle_upper_bound == 43U &&
           command.owner == static_cast<npu_compiled_command_owner>(99U) &&
           command.identity.kernel_id == 1U &&
           command.identity.command_flags == 2U &&
           command.identity.context_id == 3U &&
           command.identity.sequence_id == 4U &&
           command.identity.producer_id == 5U &&
           command.identity.user_tag == 6U &&
           command.identity.covered_node_count == 7U &&
           command.identity.node_hash_lo == 8U &&
           command.identity.node_hash_hi == 9U &&
           command.identity.local_profile == 10U &&
           command.f32_alu.request_groups == 11U &&
           command.f32_alu.response_groups == 12U &&
           command.f32_alu.read_groups == 13U &&
           command.f32_alu.write_groups == 14U &&
           command.f32_alu.input_words == 15U &&
           command.f32_alu.output_words == 16U &&
           command.f32_alu.read_bytes == 17U &&
           command.f32_alu.write_bytes == 18U &&
           command.f32_alu.completion_vector_elements == 19U &&
           command.f32_alu.expected_starts == 20U &&
           relocation.command_index == 21U &&
           relocation.word_index == 22U &&
           relocation.kind == npu_compiled_relocation_kind::window_base64 &&
           relocation.buffer_id == "sentinel-relocation" &&
           relocation.addend == 23U &&
           bundle.runtime_service.major == 24U &&
           bundle.runtime_service.minor == 25U &&
           bundle.publication_mode ==
               static_cast<npu_compiled_publication_mode>(99U) &&
           publication.buffer_id == "sentinel-publication" &&
           publication.source_offset == 26U &&
           publication.target_offset == 27U && publication.bytes == 28U &&
           bundle.provenance_source.schema == "sentinel-source-v1" &&
           bundle.provenance_source.manifest_sha256[0] == 0xb1U &&
           bundle.provenance_source.raw_sha256[0] == 0xb2U &&
           bundle.provenance_source.graph_ir_schema == "sentinel-ir-v1" &&
           bundle.provenance_source.graph_ir_sha256[0] == 0xb3U &&
           bundle.provenance_source.profile == "sentinel:profile" &&
           bundle.provenance_source.has_source_commit &&
           bundle.provenance_source.source_commit == "sentinel-commit" &&
           bundle.provenance_source.graph_scope == "sentinel:scope" &&
           node.artifact_node_id == 31U &&
           node.canonical_id == "sentinel:node" &&
           node.manifest_graph_index == 32U &&
           node.source_descriptor_sha256[0] == 0xb4U &&
           node.command_descriptor_sha256[0] == 0xb5U &&
           node.artifact_schedule_position == 33U &&
           node.source_schedule_position == 34U &&
           node.profile_family == "sentinel_family" &&
           node.profile_id == "sentinel_profile" &&
           provenance_buffer.buffer_id == "sentinel-provenance-buffer" &&
           provenance_buffer.logical.kind == "sentinel-logical" &&
           provenance_buffer.logical.index == 35U &&
           provenance_buffer.logical.has_canonical_id &&
           provenance_buffer.logical.canonical_id == "sentinel:logical" &&
           provenance_buffer.logical.tensor_descriptor_sha256[0] == 0xb6U &&
           provenance_buffer.storage.kind == "sentinel-storage" &&
           provenance_buffer.storage.index == 36U &&
           provenance_buffer.storage.has_canonical_id &&
           provenance_buffer.storage.canonical_id == "sentinel:storage" &&
           provenance_buffer.storage.tensor_descriptor_sha256[0] == 0xb7U &&
           provenance_buffer.alias_offset == 37U &&
           provenance_buffer.logical_size == 38U &&
           provenance_buffer.storage_size == 39U;
}

void test_one_metadata_mutation(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch,
        const metadata_mutation & mutation,
        bool resign = true) {
    const std::filesystem::path damaged = scratch / mutation.name;
    copy_bundle(primary, damaged);
    const std::filesystem::path metadata_path = damaged / "metadata.json";
    std::string metadata = read_text_file(metadata_path);
    const bool replaced = replace_once(
        &metadata, mutation.before, mutation.after);
    check(replaced, (std::string(mutation.name) + " mutation located").c_str());
    if (!replaced) {
        return;
    }
    if (resign) {
        const bool resigned = resign_metadata(&metadata);
        check(resigned,
              (std::string(mutation.name) + " metadata re-signed").c_str());
        if (!resigned) {
            return;
        }
    }
    write_text_file(metadata_path, metadata);

    npu_compiled_bundle output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(!npu_compiled_bundle_load(
              damaged.string(), &output, &diagnostic),
          (std::string(mutation.name) + " rejected").c_str());
    check(diagnostic.error == mutation.expected,
          (std::string(mutation.name) + " exact diagnostic").c_str());
    check(bundle_output_is_sentinel(output),
          (std::string(mutation.name) + " output unchanged").c_str());
}

void test_real_style_provenance_values(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch) {
    const std::filesystem::path changed = scratch / "real-style-provenance";
    copy_bundle(primary, changed);
    const std::filesystem::path metadata_path = changed / "metadata.json";
    std::string metadata = read_text_file(metadata_path);
    const std::string hash_canonical =
        "1e3d" + std::string(60U, 'a');
    const std::string source_descriptor =
        "b044" + std::string(60U, 'c');
    const bool canonical_replaced = replace_once(
        &metadata,
        "\"canonical_id\":\"synthetic:tiny/node/add-inputs\"",
        "\"canonical_id\":\"" + hash_canonical + "\"");
    const bool source_descriptor_replaced = replace_once(
        &metadata,
        "\"source_descriptor_sha256\":\"0ac080e5ea95662dfdb885073277cd19533e15c0b42f14deb9985d1242d8504e\"",
        "\"source_descriptor_sha256\":\"" + source_descriptor + "\"");
    const bool source_position_replaced = replace_once(
        &metadata,
        "\"source_schedule_position\":0},{\"artifact_node_id\":4098",
        "\"source_schedule_position\":15},{\"artifact_node_id\":4098");
    check(canonical_replaced && source_descriptor_replaced &&
              source_position_replaced,
          "real-style provenance vector located");
    if (!canonical_replaced || !source_descriptor_replaced ||
        !source_position_replaced) {
        return;
    }
    const bool resigned = resign_metadata(&metadata);
    check(resigned, "real-style provenance vector re-signed");
    if (!resigned) {
        return;
    }
    write_text_file(metadata_path, metadata);
    npu_compiled_bundle bundle;
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(npu_compiled_bundle_load(
              changed.string(), &bundle, &diagnostic),
          "numeric-leading SHA-256 canonical id accepted");
    check(diagnostic.error == npu_compiled_bundle_error::none,
          "real-style provenance clears diagnostic");
    check(bundle.provenance_nodes.size() == 2U &&
              bundle.provenance_nodes[0].canonical_id == hash_canonical &&
              bundle.provenance_nodes[0].artifact_schedule_position == 0U &&
              bundle.provenance_nodes[0].source_schedule_position == 15U &&
              bundle.provenance_nodes[0].source_descriptor_sha256 !=
                  bundle.provenance_nodes[0].command_descriptor_sha256,
          "source identity and artifact identity remain independent");
}

void test_output_without_producer(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch) {
    const std::filesystem::path damaged = scratch / "publication-no-producer";
    copy_bundle(primary, damaged);
    const std::filesystem::path metadata_path = damaged / "metadata.json";
    std::string metadata = read_text_file(metadata_path);
    const bool address_replaced = replace_once(
        &metadata,
        "{\"addend\":0,\"buffer_id\":\"output\",\"command_index\":1,"
        "\"kind\":\"iova64\",\"word_index\":13}",
        "{\"addend\":0,\"buffer_id\":\"intermediate\",\"command_index\":1,"
        "\"kind\":\"iova64\",\"word_index\":13}");
    const bool window_replaced = replace_once(
        &metadata,
        "{\"addend\":0,\"buffer_id\":\"output\",\"command_index\":1,"
        "\"kind\":\"window_base64\",\"word_index\":28}",
        "{\"addend\":0,\"buffer_id\":\"intermediate\",\"command_index\":1,"
        "\"kind\":\"window_base64\",\"word_index\":28}");
    check(address_replaced && window_replaced,
          "publication producer mutation located paired dst relocations");
    if (!address_replaced || !window_replaced) {
        return;
    }
    const bool resigned = resign_metadata(&metadata);
    check(resigned, "publication producer mutation metadata re-signed");
    if (!resigned) {
        return;
    }
    write_text_file(metadata_path, metadata);
    npu_compiled_bundle output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(!npu_compiled_bundle_load(
              damaged.string(), &output, &diagnostic),
          "published output without dst producer rejected");
    check(diagnostic.error ==
              npu_compiled_bundle_error::publication_producer,
          "missing publication producer has exact diagnostic");
    check(bundle_output_is_sentinel(output),
          "missing publication producer leaves full output unchanged");
}

void test_publication_beyond_destination_window(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch) {
    const std::filesystem::path damaged =
        scratch / "publication-unwritten-source";
    copy_bundle(primary, damaged);
    const std::filesystem::path command_path = damaged / "command.bin";
    const std::filesystem::path metadata_path = damaged / "metadata.json";
    std::vector<std::uint8_t> command = read_binary_file(command_path);
    const std::size_t second_record =
        NPU_COMPILED_COMMAND_HEADER_BYTES +
        NPU_COMPILED_COMMAND_RECORD_BYTES;
    check(
        command.size() == NPU_COMPILED_COMMAND_HEADER_BYTES +
            2U * NPU_COMPILED_COMMAND_RECORD_BYTES,
        "publication unwritten mutation found two command records");
    if (command.size() != NPU_COMPILED_COMMAND_HEADER_BYTES +
            2U * NPU_COMPILED_COMMAND_RECORD_BYTES) {
        return;
    }

    const std::string old_descriptor_hash = sha256_hex(
        command.data() + second_record,
        NPU_COMPILED_COMMAND_RECORD_BYTES);
    const std::string old_artifact_hash = sha256_hex(
        command.data(), command.size());
    store_le64(command.data() + second_record + 29U * 8U, 32U);
    const auto payload_hash = sha256_bytes(
        command.data() + NPU_COMPILED_COMMAND_HEADER_BYTES,
        command.size() - NPU_COMPILED_COMMAND_HEADER_BYTES);
    std::copy(
        payload_hash.begin(), payload_hash.end(), command.begin() + 32U);
    const std::string new_descriptor_hash = sha256_hex(
        command.data() + second_record,
        NPU_COMPILED_COMMAND_RECORD_BYTES);
    const std::string new_artifact_hash = sha256_hex(
        command.data(), command.size());

    std::string metadata = read_text_file(metadata_path);
    const bool descriptor_replaced = replace_once(
        &metadata, old_descriptor_hash, new_descriptor_hash);
    const bool provenance_descriptor_replaced = replace_once(
        &metadata, old_descriptor_hash, new_descriptor_hash);
    const bool artifact_replaced = replace_once(
        &metadata, old_artifact_hash, new_artifact_hash);
    check(
        descriptor_replaced && provenance_descriptor_replaced &&
            artifact_replaced,
        "publication unwritten mutation updated command/provenance/artifact hashes");
    if (!descriptor_replaced || !provenance_descriptor_replaced ||
        !artifact_replaced) {
        return;
    }
    const bool resigned = resign_metadata(&metadata);
    check(resigned, "publication unwritten mutation metadata re-signed");
    if (!resigned) {
        return;
    }
    write_binary_file(command_path, command);
    write_text_file(metadata_path, metadata);

    npu_compiled_bundle output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(
        !npu_compiled_bundle_load(
            damaged.string(), &output, &diagnostic),
        "64-byte publication from 32-byte destination window rejected");
    check(
        diagnostic.error ==
            npu_compiled_bundle_error::publication_unwritten_source,
        "unwritten publication source has exact diagnostic");
    check(
        bundle_output_is_sentinel(output),
        "unwritten publication source leaves full output unchanged");
}

std::vector<npu_compiled_named_binding> tiny_bindings() {
    return {
        {"input0", 0x1000U, 64U, 1U},
        {"input1", 0x2000U, 64U, 1U},
        {"intermediate", 0x3000U, 64U, 3U},
        {"output", 0x4000U, 64U, 2U},
        {"bias", 0x5000U, 64U, 1U},
    };
}

void test_positive(const std::filesystem::path & directory) {
    npu_compiled_bundle bundle;
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(npu_compiled_bundle_load(
              directory.string(), &bundle, &diagnostic),
          "load Python-generated bundle");
    check(diagnostic.error == npu_compiled_bundle_error::none,
          "successful load clears diagnostic");
    check(bundle.graph_name == "tiny-two-vector-add",
          "graph name parsed");
    check(bundle.commands.size() == 2U,
          "two commands parsed");
    check(bundle.buffers.size() == 5U,
          "five buffers parsed");
    check(bundle.relocations.size() == 12U,
          "twelve relocations parsed");
    check(bundle.weights.size() == 64U,
          "raw weight image retained");
    check(bundle.command_template.size() == 544U,
          "header plus two 240-byte records retained");
    check(bundle.command_template[8] == 1U &&
              bundle.command_template[9] == 0U &&
              bundle.command_template[10] == 1U &&
              bundle.command_template[11] == 0U,
          "command header ABI is exactly 1.1");
    check(bundle.runtime_service.major == 1U,
          "runtime service ABI major parsed");
    check(bundle.runtime_service.minor == 1U,
          "runtime service ABI minor parsed");
    check(bundle.publication_mode ==
              npu_compiled_publication_mode::bundle_atomic,
          "bundle-atomic publication mode parsed");
    check(bundle.publications.size() == 1U,
          "one publication entry parsed");
    if (!bundle.publications.empty()) {
        check(bundle.publications[0].buffer_id == "output",
              "publication BufferId parsed");
        check(bundle.publications[0].source_offset == 0U,
              "publication source offset parsed");
        check(bundle.publications[0].target_offset == 0U,
              "publication target offset parsed");
        check(bundle.publications[0].bytes == 64U,
              "publication byte count parsed");
    }
    check(bundle.provenance_source.schema ==
              "synthetic-graph-manifest-v1",
          "synthetic source schema retained");
    check(bundle.provenance_source.graph_ir_schema ==
              "synthetic-npu-graph-ir-v1",
          "GraphIR schema retained");
    check(bundle.provenance_source.profile ==
              "synthetic:p00-dense-add",
          "synthetic source profile retained");
    check(!bundle.provenance_source.has_source_commit &&
              bundle.provenance_source.source_commit.empty(),
          "synthetic fixture does not fabricate source commit");
    check(bundle.provenance_source.graph_scope ==
              "synthetic:tiny-two-vector-add",
          "source graph scope retained");
    check(bundle.provenance_nodes.size() == 2U,
          "two provenance node bindings parsed");
    if (bundle.provenance_nodes.size() == 2U) {
        const npu_compiled_node_binding & first =
            bundle.provenance_nodes[0];
        const npu_compiled_node_binding & second =
            bundle.provenance_nodes[1];
        check(first.artifact_node_id == 4097U &&
                  second.artifact_node_id == 4098U,
              "provenance node ids exactly follow artifact schedule");
        check(first.artifact_schedule_position == 0U &&
                  second.artifact_schedule_position == 1U,
              "artifact schedule positions retained");
        check(first.source_schedule_position == 0U &&
                  second.source_schedule_position == 1U,
              "source schedule positions retained independently");
        check(first.source_descriptor_sha256 !=
                  first.command_descriptor_sha256,
              "source and command descriptor identities remain distinct");
        check(first.canonical_id == "synthetic:tiny/node/add-inputs" &&
                  first.profile_family == "vector_f32" &&
                  first.profile_id == "p00",
              "node canonical identity and profile retained");
    }
    check(bundle.provenance_buffers.size() == bundle.buffers.size(),
          "provenance buffers exactly cover artifact buffers");
    if (!bundle.provenance_buffers.empty()) {
        const npu_compiled_buffer_binding & first =
            bundle.provenance_buffers.front();
        check(first.buffer_id == "bias",
              "provenance buffers retain canonical BufferId order");
        check(first.logical.kind == "constant" &&
                  first.storage.kind == "constant" &&
                  first.logical.has_canonical_id &&
                  first.storage.has_canonical_id,
              "logical and normalized storage origins retained");
        check(first.alias_offset == 0U && first.logical_size == 64U &&
                  first.storage_size == 64U,
              "non-view provenance retains complete storage range");
    }

    npu_command_abi_words template_words = {};
    check(npu_compiled_bundle_decode_record(
              bundle.command_template, 0U, &template_words, &diagnostic),
          "decode immutable template record");
    check(template_words[10] == 0U && template_words[23] == 0U,
          "template contains relocation addends");
    check((template_words[5] & 0xffffffffULL) == 1U,
          "template node_count is one");

    if (bundle.commands.size() == 2U) {
        const npu_compiled_command_info & first_info = bundle.commands[0];
        const npu_compiled_command_info & second_info = bundle.commands[1];
        check(first_info.owner == npu_compiled_command_owner::f32_alu,
              "first owner is structured f32_alu");
        check(second_info.owner == npu_compiled_command_owner::f32_alu,
              "second owner is structured f32_alu");
        check(first_info.cycle_upper_bound == 100000U,
              "first cycle upper bound parsed");
        check(second_info.cycle_upper_bound == 100000U,
              "second cycle upper bound parsed");

        const auto check_identity = [](const npu_compiled_command_identity & identity,
                                       std::uint64_t sequence,
                                       std::uint64_t producer,
                                       std::uint64_t tag,
                                       std::uint64_t node_hash_lo,
                                       std::uint64_t node_hash_hi,
                                       const char * prefix) {
            check(identity.kernel_id == 0x514e0010U,
                  (std::string(prefix) + " identity kernel_id").c_str());
            check(identity.command_flags == 17U,
                  (std::string(prefix) + " identity command_flags").c_str());
            check(identity.context_id == 7U,
                  (std::string(prefix) + " identity context_id").c_str());
            check(identity.sequence_id == sequence,
                  (std::string(prefix) + " identity sequence_id").c_str());
            check(identity.producer_id == producer,
                  (std::string(prefix) + " identity producer_id").c_str());
            check(identity.user_tag == tag,
                  (std::string(prefix) + " identity user_tag").c_str());
            check(identity.covered_node_count == 1U,
                  (std::string(prefix) + " identity covered_node_count").c_str());
            check(identity.node_hash_lo == node_hash_lo,
                  (std::string(prefix) + " identity node_hash_lo").c_str());
            check(identity.node_hash_hi == node_hash_hi,
                  (std::string(prefix) + " identity node_hash_hi").c_str());
            check(identity.local_profile == 0U,
                  (std::string(prefix) + " identity local_profile").c_str());
        };
        check_identity(
            first_info.identity, 1U, 8193U, 12289U,
            5517907049662474317ULL, 782441576604488098ULL, "first");
        check_identity(
            second_info.identity, 2U, 8194U, 12290U,
            13356075832101734903ULL, 3714291919916234388ULL, "second");

        const auto check_workload = [](const npu_compiled_f32_alu_workload & work,
                                       const char * prefix) {
            check(work.request_groups == 4U,
                  (std::string(prefix) + " workload request_groups").c_str());
            check(work.response_groups == 4U,
                  (std::string(prefix) + " workload response_groups").c_str());
            check(work.read_groups == 2U,
                  (std::string(prefix) + " workload read_groups").c_str());
            check(work.write_groups == 2U,
                  (std::string(prefix) + " workload write_groups").c_str());
            check(work.input_words == 32U,
                  (std::string(prefix) + " workload input_words").c_str());
            check(work.output_words == 16U,
                  (std::string(prefix) + " workload output_words").c_str());
            check(work.read_bytes == 128U,
                  (std::string(prefix) + " workload read_bytes").c_str());
            check(work.write_bytes == 64U,
                  (std::string(prefix) + " workload write_bytes").c_str());
            check(work.completion_vector_elements == 16U,
                  (std::string(prefix) +
                   " workload completion_vector_elements").c_str());
            check(work.expected_starts == 1U,
                  (std::string(prefix) + " workload expected_starts").c_str());
        };
        check_workload(first_info.f32_alu, "first");
        check_workload(second_info.f32_alu, "second");

        npu_compiled_bundle parsed_tamper = bundle;
        parsed_tamper.commands[0].owner =
            static_cast<npu_compiled_command_owner>(99U);
        parsed_tamper.commands[0].identity.producer_id = 0xdeadbeefU;
        parsed_tamper.commands[0].f32_alu.request_groups = 999U;
        parsed_tamper.commands[0].cycle_upper_bound = 1U;
        parsed_tamper.publications[0].bytes = 1U;
        parsed_tamper.provenance_source.graph_scope = "tampered:scope";
        parsed_tamper.provenance_nodes[0].source_schedule_position = 999U;
        parsed_tamper.provenance_buffers[0].logical_size = 1U;
        npu_compiled_bundle canonical;
        check(npu_compiled_bundle_revalidate(
                  &parsed_tamper, &canonical, &diagnostic),
              "revalidation ignores mutable parsed provenance");
        check(diagnostic.error == npu_compiled_bundle_error::none,
              "successful revalidation clears diagnostic");
        check(canonical.commands[0].owner ==
                  npu_compiled_command_owner::f32_alu &&
              canonical.commands[0].identity.producer_id == 8193U &&
              canonical.commands[0].f32_alu.request_groups == 4U &&
              canonical.commands[0].cycle_upper_bound == 100000U &&
              canonical.publications[0].bytes == 64U &&
              canonical.provenance_source.graph_scope ==
                  "synthetic:tiny-two-vector-add" &&
              canonical.provenance_nodes[0].source_schedule_position == 0U &&
              canonical.provenance_buffers[0].logical_size == 64U,
              "revalidation restores all canonical metadata including provenance");

        npu_compiled_bundle invalid_immutable = bundle;
        invalid_immutable.metadata_json.push_back('\n');
        npu_compiled_bundle unchanged = make_sentinel_bundle();
        check(!npu_compiled_bundle_revalidate(
                  &invalid_immutable, &unchanged, &diagnostic),
              "revalidation rejects changed immutable bytes");
        check(diagnostic.error ==
                  npu_compiled_bundle_error::metadata_noncanonical,
              "revalidation immutable-byte failure is exact");
        check(bundle_output_is_sentinel(unchanged),
              "failed revalidation leaves output unchanged");
    }

    const auto bindings = tiny_bindings();
    std::vector<std::uint8_t> relocated = {0xa5U, 0x5aU};
    check(npu_compiled_bundle_relocate(
              &bundle, bindings.data(), bindings.size(),
              &relocated, &diagnostic),
          "relocate all commands into private shadow");
    check(diagnostic.error == npu_compiled_bundle_error::none,
          "successful relocation clears diagnostic");
    check(relocated.size() == bundle.command_template.size() &&
              relocated != bundle.command_template,
          "relocated image is complete and distinct");

    npu_command_abi_words first = {};
    npu_command_abi_words second = {};
    check(npu_compiled_bundle_decode_record(
              relocated, 0U, &first, &diagnostic) &&
          npu_compiled_bundle_decode_record(
              relocated, 1U, &second, &diagnostic),
          "relocated payload hash and both records validate");
    check(first[10] == 0x1000U && first[11] == 0x2000U &&
              first[13] == 0x3000U,
          "first command IOVAs relocated");
    check(first[23] == 0x1000U && first[26] == 0x2000U &&
              first[28] == 0x3000U,
          "first command windows relocated");
    check(second[10] == 0x3000U && second[11] == 0x5000U &&
              second[13] == 0x4000U,
          "second command IOVAs relocated");
    check(second[23] == 0x3000U && second[26] == 0x5000U &&
              second[28] == 0x4000U,
          "second command windows relocated");
    check(static_cast<std::uint32_t>(first[0]) == 0x514e0010U &&
              static_cast<std::uint32_t>(second[0]) == 0x514e0010U,
          "both descriptors retain VECTOR_F32 kernel");
    check(static_cast<std::uint32_t>(first[5] >> 32U) == 1U &&
              static_cast<std::uint32_t>(second[5] >> 32U) == 1U,
          "both descriptors retain ADD vector operation");
}

void test_binding_failures(const std::filesystem::path & directory) {
    npu_compiled_bundle bundle;
    npu_compiled_bundle_diagnostic diagnostic = {};
    if (!check(npu_compiled_bundle_load(
                   directory.string(), &bundle, &diagnostic),
               "load bundle for binding negative tests")) {
        return;
    }
    auto bindings = tiny_bindings();
    bindings.push_back({"ghost", 0x6000U, 64U, 1U});
    std::vector<std::uint8_t> output = {0xdeU, 0xadU};
    const std::vector<std::uint8_t> before = output;
    check(!npu_compiled_bundle_relocate(
              &bundle, bindings.data(), bindings.size(),
              &output, &diagnostic),
          "unknown BufferId binding rejected");
    check(diagnostic.error == npu_compiled_bundle_error::binding_unknown,
          "unknown binding has exact diagnostic");
    check(output == before,
          "unknown binding leaves private shadow unchanged");

    bindings = tiny_bindings();
    bindings[0].base = std::numeric_limits<std::uint64_t>::max() - 63U;
    output = {0xcaU, 0xfeU};
    const std::vector<std::uint8_t> overflow_before = output;
    check(!npu_compiled_bundle_relocate(
              &bundle, bindings.data(), bindings.size(),
              &output, &diagnostic),
          "u64 binding overflow rejected");
    check(diagnostic.error == npu_compiled_bundle_error::binding_overflow,
          "overflow has exact diagnostic");
    check(output == overflow_before,
          "overflow leaves private shadow unchanged");
}


void test_unsupported_hardware_deadline(
        const std::filesystem::path & primary, const std::filesystem::path & scratch) {
    const auto damaged = scratch / "hardware-deadline";
    copy_bundle(primary, damaged);
    auto command = read_binary_file(damaged / "command.bin");
    auto metadata = read_text_file(damaged / "metadata.json");
    const auto offset = NPU_COMPILED_COMMAND_HEADER_BYTES;
    const auto old_record = sha256_hex(command.data() + offset, NPU_COMPILED_COMMAND_RECORD_BYTES);
    const auto old_file = sha256_hex(command.data(), command.size());
    store_le64(command.data() + offset + 8U * 8U, 9072U);
    const auto payload = sha256_bytes(command.data() + offset, command.size() - offset);
    std::copy(payload.begin(), payload.end(), command.begin() + 32U);
    const auto new_record = sha256_hex(command.data() + offset, NPU_COMPILED_COMMAND_RECORD_BYTES);
    check(replace_once(&metadata, old_record, new_record), "deadline command hash updated");
    check(replace_once(&metadata, old_record, new_record), "deadline provenance hash updated");
    check(replace_once(&metadata, old_file, sha256_hex(command.data(), command.size())),
          "deadline file hash updated");
    check(resign_metadata(&metadata), "deadline bundle re-signed");
    write_binary_file(damaged / "command.bin", command);
    write_text_file(damaged / "metadata.json", metadata);
    auto output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(!npu_compiled_bundle_load(damaged.string(), &output, &diagnostic),
          "unsupported deadline rejected even with consistent artifact hashes");
    check(diagnostic.error == npu_compiled_bundle_error::metadata_value &&
          diagnostic.command_index == 0 &&
          diagnostic.path == "$command.bin.records[0][8]",
          "hardware deadline failure identifies exact command field");
    check(bundle_output_is_sentinel(output), "deadline rejection is atomic");
}

void test_hash_failure(
        const std::filesystem::path & directory,
        const std::filesystem::path & scratch) {
    const std::filesystem::path damaged = scratch / "damaged";
    copy_bundle(directory, damaged);
    const std::filesystem::path command_path = damaged / "command.bin";
    std::fstream command(
        command_path, std::ios::binary | std::ios::in | std::ios::out);
    command.seekg(-1, std::ios::end);
    char byte = 0;
    command.read(&byte, 1);
    byte ^= 1;
    command.seekp(-1, std::ios::end);
    command.write(&byte, 1);
    command.close();

    npu_compiled_bundle output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(!npu_compiled_bundle_load(
              damaged.string(), &output, &diagnostic),
          "damaged command payload rejected");
    check(diagnostic.error ==
              npu_compiled_bundle_error::command_payload_hash,
          "payload hash failure has exact diagnostic");
    check(bundle_output_is_sentinel(output),
          "hash failure leaves bundle output unchanged");
}

void test_command_version_failure(
        const std::filesystem::path & directory,
        const std::filesystem::path & scratch) {
    const std::filesystem::path damaged = scratch / "command-version";
    copy_bundle(directory, damaged);
    const std::filesystem::path command_path = damaged / "command.bin";
    std::fstream command(
        command_path, std::ios::binary | std::ios::in | std::ios::out);
    command.seekp(10, std::ios::beg);
    const char wrong_minor = 2;
    command.write(&wrong_minor, 1);
    command.close();

    npu_compiled_bundle output = make_sentinel_bundle();
    npu_compiled_bundle_diagnostic diagnostic = {};
    check(!npu_compiled_bundle_load(
              damaged.string(), &output, &diagnostic),
          "command header ABI other than 1.1 rejected");
    check(diagnostic.error == npu_compiled_bundle_error::command_version,
          "command header ABI failure has exact diagnostic");
    check(bundle_output_is_sentinel(output),
          "command header ABI failure leaves output unchanged");
}

void test_cross_bundle_failure(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch) {
    const std::filesystem::path mixed = scratch / "mixed";
    copy_bundle(primary, mixed);
    const std::filesystem::path weights_path = mixed / "weights.bin";
    std::fstream weights(
        weights_path, std::ios::binary | std::ios::in | std::ios::out);
    char byte = 0;
    weights.read(&byte, 1);
    byte ^= 1;
    weights.seekp(0, std::ios::beg);
    weights.write(&byte, 1);
    weights.close();

    npu_compiled_bundle_diagnostic diagnostic = {};
    npu_compiled_bundle output = make_sentinel_bundle();
    check(!npu_compiled_bundle_load(
              mixed.string(), &output, &diagnostic),
          "cross-bundle artifact mix rejected");
    check(diagnostic.error == npu_compiled_bundle_error::artifact_hash,
          "cross-bundle mix rejected by whole-file hash");
    check(bundle_output_is_sentinel(output),
          "cross-bundle failure leaves output unchanged");
}

void test_v3_metadata_failures(
        const std::filesystem::path & primary,
        const std::filesystem::path & scratch) {
    static const std::vector<metadata_mutation> mutations = {
        {
            "metadata-abi",
            "\"abi\":{\"command_header_bytes\":64,\"command_record_words\":30,\"endianness\":\"little\",\"major\":1,\"minor\":1",
            "\"abi\":{\"command_header_bytes\":64,\"command_record_words\":30,\"endianness\":\"little\",\"major\":1,\"minor\":2",
            npu_compiled_bundle_error::metadata_value,
        },
        {
            "schema-v2",
            "\"schema\":\"npu-artifact-bundle-v3\"}",
            "\"schema\":\"npu-artifact-bundle-v2\"}",
            npu_compiled_bundle_error::metadata_schema,
        },
        {
            "runtime-abi",
            "\"runtime\":{\"service_abi\":{\"major\":1,\"minor\":1}},\"schema\"",
            "\"runtime\":{\"service_abi\":{\"major\":1,\"minor\":2}},\"schema\"",
            npu_compiled_bundle_error::runtime_abi,
        },
        {
            "runtime-extra-key",
            "\"runtime\":{\"service_abi\"",
            "\"runtime\":{\"extra\":0,\"service_abi\"",
            npu_compiled_bundle_error::metadata_keys,
        },
        {
            "provenance-source-schema",
            "\"schema\":\"synthetic-graph-manifest-v1\",\"source_commit\":null",
            "\"schema\":\"Synthetic-graph-manifest-v1\",\"source_commit\":null",
            npu_compiled_bundle_error::provenance_format,
        },
        {
            "provenance-graph-ir-schema",
            "\"graph_ir_schema\":\"synthetic-npu-graph-ir-v1\"",
            "\"graph_ir_schema\":\"synthetic-npu-graph-ir-v0\"",
            npu_compiled_bundle_error::provenance_format,
        },
        {
            "provenance-node-command-descriptor",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputs\",\"command_descriptor_sha256\":\"cb894735d903b17c2e93b0c61b503f87e37b77f0f8b165e113a63884ef2d66df\"",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputs\",\"command_descriptor_sha256\":\"0000000000000000000000000000000000000000000000000000000000000000\"",
            npu_compiled_bundle_error::provenance_node_descriptor,
        },
        {
            "provenance-node-canonical-duplicate",
            "\"canonical_id\":\"synthetic:tiny/node/add-bias\"",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputs\"",
            npu_compiled_bundle_error::provenance_node_duplicate,
        },
        {
            "provenance-artifact-schedule-duplicate",
            "\"artifact_node_id\":4098,\"artifact_schedule_position\":1",
            "\"artifact_node_id\":4098,\"artifact_schedule_position\":0",
            npu_compiled_bundle_error::provenance_node_duplicate,
        },
        {
            "provenance-source-schedule-duplicate",
            "\"source_schedule_position\":1}],\"source\"",
            "\"source_schedule_position\":0}],\"source\"",
            npu_compiled_bundle_error::provenance_node_duplicate,
        },
        {
            "provenance-node-coverage",
            "\"artifact_node_id\":4098,\"artifact_schedule_position\":1",
            "\"artifact_node_id\":4099,\"artifact_schedule_position\":1",
            npu_compiled_bundle_error::provenance_node_coverage,
        },
        {
            "provenance-buffer-duplicate",
            "\"alias_offset\":0,\"buffer_id\":\"input0\"",
            "\"alias_offset\":0,\"buffer_id\":\"bias\"",
            npu_compiled_bundle_error::provenance_buffer_duplicate,
        },
        {
            "provenance-buffer-coverage",
            "\"alias_offset\":0,\"buffer_id\":\"output\",\"canonical_id\"",
            "\"alias_offset\":0,\"buffer_id\":\"zghost\",\"canonical_id\"",
            npu_compiled_bundle_error::provenance_buffer_coverage,
        },
        {
            "provenance-alias-range",
            "\"alias_offset\":0,\"buffer_id\":\"bias\"",
            "\"alias_offset\":64,\"buffer_id\":\"bias\"",
            npu_compiled_bundle_error::provenance_buffer_range,
        },
        {
            "provenance-storage-size",
            "\"storage_origin_kind\":\"constant\",\"storage_size\":64",
            "\"storage_origin_kind\":\"constant\",\"storage_size\":65",
            npu_compiled_bundle_error::provenance_buffer_range,
        },
        {
            "provenance-canonical-format",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputs\"",
            "\"canonical_id\":\"Qwen Node 0\"",
            npu_compiled_bundle_error::provenance_format,
        },
        {
            "unsupported-owner",
            "\"owner\":\"f32_alu\"",
            "\"owner\":\"bogus\"",
            npu_compiled_bundle_error::command_owner,
        },
        {
            "owner-kernel-pair",
            "\"kernel_id\":1364066320",
            "\"kernel_id\":1364066321",
            npu_compiled_bundle_error::kernel_id,
        },
        {
            "identity-producer",
            "\"producer_id\":8193",
            "\"producer_id\":8195",
            npu_compiled_bundle_error::command_identity,
        },
        {
            "identity-local-profile",
            "\"local_profile\":0",
            "\"local_profile\":1",
            npu_compiled_bundle_error::command_identity,
        },
        {
            "workload-group-equation",
            "\"read_groups\":2",
            "\"read_groups\":3",
            npu_compiled_bundle_error::command_workload,
        },
        {
            "workload-byte-equation",
            "\"read_bytes\":128",
            "\"read_bytes\":129",
            npu_compiled_bundle_error::command_workload,
        },
        {
            "workload-zero-start",
            "\"expected_starts\":1",
            "\"expected_starts\":0",
            npu_compiled_bundle_error::command_workload,
        },
        {
            "workload-too-many-starts",
            "\"expected_starts\":1",
            "\"expected_starts\":2",
            npu_compiled_bundle_error::metadata_range,
        },
        {
            "workload-schema",
            "\"schema\":\"f32-alu-v1\"",
            "\"schema\":\"f32-alu-v0\"",
            npu_compiled_bundle_error::command_workload,
        },
        {
            "zero-cycle-budget",
            "\"cycle_upper_bound\":100000",
            "\"cycle_upper_bound\":0",
            npu_compiled_bundle_error::metadata_range,
        },
        {
            "cycle-budget-overflow",
            "\"cycle_upper_bound\":100000",
            "\"cycle_upper_bound\":18446744073709551615",
            npu_compiled_bundle_error::metadata_range,
        },
        {
            "publication-mode",
            "\"mode\":\"bundle_atomic\"",
            "\"mode\":\"per_entry\"",
            npu_compiled_bundle_error::publication_mode,
        },
        {
            "publication-zero-bytes",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\",\"bytes\":0",
            npu_compiled_bundle_error::metadata_range,
        },
        {
            "publication-range",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":64",
            npu_compiled_bundle_error::publication_range,
        },
        {
            "publication-non-output",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\"",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"input0\"",
            npu_compiled_bundle_error::publication_buffer,
        },
        {
            "publication-missing-output",
            "\"publication\":{\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            "\"publication\":{\"entries\":[]",
            npu_compiled_bundle_error::publication_coverage,
        },
        {
            "publication-duplicate",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0},{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            npu_compiled_bundle_error::publication_duplicate,
        },
        {
            "publication-order",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":32,\"target_offset\":32},{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":0,\"target_offset\":0}]",
            npu_compiled_bundle_error::publication_order,
        },
        {
            "publication-source-overlap",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":0,\"target_offset\":0},{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":0,\"target_offset\":32}]",
            npu_compiled_bundle_error::publication_coverage,
        },
        {
            "publication-target-overlap",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":64,\"source_offset\":0,\"target_offset\":0}]",
            "\"entries\":[{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":0,\"target_offset\":0},{\"buffer_id\":\"output\",\"bytes\":32,\"source_offset\":32,\"target_offset\":31}]",
            npu_compiled_bundle_error::publication_coverage,
        },
        {
            "output-overpermission",
            "\"id\":\"output\",\"kind\":\"output\",\"permissions\":\"w\"",
            "\"id\":\"output\",\"kind\":\"output\",\"permissions\":\"rw\"",
            npu_compiled_bundle_error::buffer_permission,
        },
        {
            "transient-read-before-write",
            "\"id\":\"input0\",\"kind\":\"input\"",
            "\"id\":\"input0\",\"kind\":\"transient\"",
            npu_compiled_bundle_error::transient_read_before_write,
        },
        {
            "src2-current-dst-read-before-write",
            "{\"addend\":0,\"buffer_id\":\"input1\",\"command_index\":0,\"kind\":\"iova64\",\"word_index\":11},{\"addend\":0,\"buffer_id\":\"intermediate\",\"command_index\":0,\"kind\":\"iova64\",\"word_index\":13}",
            "{\"addend\":0,\"buffer_id\":\"input1\",\"command_index\":0,\"kind\":\"iova64\",\"word_index\":11},{\"addend\":0,\"buffer_id\":\"intermediate\",\"command_index\":0,\"kind\":\"iova64\",\"word_index\":12},{\"addend\":0,\"buffer_id\":\"intermediate\",\"command_index\":0,\"kind\":\"iova64\",\"word_index\":13}",
            npu_compiled_bundle_error::transient_read_before_write,
        },
    };
    for (const metadata_mutation & mutation : mutations) {
        test_one_metadata_mutation(primary, scratch, mutation);
    }
    test_real_style_provenance_values(primary, scratch);
    test_output_without_producer(primary, scratch);
    test_publication_beyond_destination_window(primary, scratch);

    static const std::vector<metadata_mutation> unsigned_changes = {
        {
            "bundle-id-closes-runtime",
            "\"runtime\":{\"service_abi\":{\"major\":1,\"minor\":1}}",
            "\"runtime\":{\"service_abi\":{\"major\":1,\"minor\":2}}",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-owner",
            "\"owner\":\"f32_alu\"",
            "\"owner\":\"bogus\"",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-identity",
            "\"producer_id\":8193",
            "\"producer_id\":8195",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-workload",
            "\"expected_starts\":1",
            "\"expected_starts\":0",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-cycle-budget",
            "\"cycle_upper_bound\":100000",
            "\"cycle_upper_bound\":99999",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-publication",
            "\"mode\":\"bundle_atomic\"",
            "\"mode\":\"per_entry\"",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-graph-ir",
            "\"graph_ir_sha256\":\"0185828e65721597d86909ac3c81ef579f3ca14616f64c7565761280f5397a17\"",
            "\"graph_ir_sha256\":\"1185828e65721597d86909ac3c81ef579f3ca14616f64c7565761280f5397a17\"",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-node-provenance",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputs\"",
            "\"canonical_id\":\"synthetic:tiny/node/add-inputz\"",
            npu_compiled_bundle_error::bundle_id,
        },
        {
            "bundle-id-closes-buffer-provenance",
            "\"alias_offset\":0,\"buffer_id\":\"bias\"",
            "\"alias_offset\":1,\"buffer_id\":\"bias\"",
            npu_compiled_bundle_error::bundle_id,
        },
    };
    for (const metadata_mutation & mutation : unsigned_changes) {
        test_one_metadata_mutation(primary, scratch, mutation, false);
    }
}

}  // namespace

int main(int argc, char ** argv) {
    if (argc != 2) {
        std::fprintf(
            stderr,
            "usage: %s PYTHON_BUNDLE\n",
            argc == 0 ? "test-compiled-bundle" : argv[0]);
        return 2;
    }
    try {
        const std::filesystem::path primary(argv[1]);
        temporary_tree scratch = make_temporary_tree();
        test_positive(primary);
        test_v3_metadata_failures(primary, scratch.path);
        test_binding_failures(primary);
        test_command_version_failure(primary, scratch.path);
        test_hash_failure(primary, scratch.path);
        test_unsupported_hardware_deadline(primary, scratch.path);
        test_cross_bundle_failure(primary, scratch.path);
    } catch (const std::exception & exception) {
        ++g_failures;
        std::fprintf(
            stderr, "[NPU-COMPILED-BUNDLE][EXCEPTION] %s\n",
            exception.what());
    }
    std::printf(
        "[NPU-COMPILED-BUNDLE] checks=%d failures=%d\n",
        g_checks, g_failures);
    return g_failures == 0 ? 0 : 1;
}
