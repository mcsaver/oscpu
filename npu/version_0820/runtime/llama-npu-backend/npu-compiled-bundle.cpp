#include "npu-compiled-bundle.h"

#include <nlohmann/json.hpp>

#include <algorithm>
#include <array>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <limits>
#include <map>
#include <new>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <tuple>
#include <utility>

namespace {

using json = nlohmann::json;

constexpr std::array<std::uint8_t, 8> kCommandMagic = {{
    'N', 'P', 'U', 'C', 'M', 'D', 0U, 0U,
}};
constexpr char kMetadataSchema[] = "npu-artifact-bundle-v3";
constexpr char kGraphSchema[] = "npu-compiler-graph-v3";
constexpr char kF32WorkloadSchema[] = "f32-alu-v1";
constexpr std::uint32_t kF32AluKernelId = 0x514e0010U;
constexpr std::size_t kCommandPayloadHashOffset = 32U;
constexpr std::size_t kSha256Bytes = 32U;
constexpr std::size_t kNoIndex = static_cast<std::size_t>(-1);
constexpr std::uint32_t kRelocatableWords[] = {
    10U, 11U, 12U, 13U, 23U, 26U, 28U,
};

struct window_pair {
    std::uint32_t address_word;
    std::uint32_t base_word;
    std::uint32_t size_word;
};

constexpr std::array<window_pair, 3> kWindowPairs = {{
    {10U, 23U, 24U},
    {11U, 26U, 27U},
    {13U, 28U, 29U},
}};

void clear_diagnostic(npu_compiled_bundle_diagnostic * diagnostic) {
    if (diagnostic != nullptr) {
        *diagnostic = {};
    }
}

bool fail(
        npu_compiled_bundle_diagnostic * diagnostic,
        npu_compiled_bundle_error error,
        std::string path,
        std::string detail,
        std::size_t command_index = kNoIndex,
        std::size_t relocation_index = kNoIndex,
        const npu_command_abi_diagnostic * command_abi = nullptr) {
    if (diagnostic != nullptr) {
        diagnostic->error = error;
        diagnostic->path = std::move(path);
        diagnostic->detail = std::move(detail);
        diagnostic->command_index = command_index;
        diagnostic->relocation_index = relocation_index;
        diagnostic->command_abi = command_abi == nullptr ?
            npu_command_abi_diagnostic{} : *command_abi;
    }
    return false;
}

std::string indexed_path(const char * prefix, std::size_t index) {
    return std::string(prefix) + "[" + std::to_string(index) + "]";
}

std::uint16_t load_le16(const std::uint8_t * bytes) {
    return static_cast<std::uint16_t>(bytes[0]) |
           static_cast<std::uint16_t>(bytes[1]) << 8U;
}

std::uint32_t load_le32(const std::uint8_t * bytes) {
    std::uint32_t value = 0U;
    for (unsigned index = 0; index < 4U; ++index) {
        value |= static_cast<std::uint32_t>(bytes[index]) << (8U * index);
    }
    return value;
}

std::uint64_t load_le64(const std::uint8_t * bytes) {
    std::uint64_t value = 0U;
    for (unsigned index = 0; index < 8U; ++index) {
        value |= static_cast<std::uint64_t>(bytes[index]) << (8U * index);
    }
    return value;
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (unsigned index = 0; index < 8U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

std::uint32_t rotate_right(std::uint32_t value, unsigned amount) {
    return (value >> amount) | (value << (32U - amount));
}

class sha256_state {
public:
    sha256_state() = default;

    void update(const std::uint8_t * bytes, std::size_t size) {
        if (size == 0U) {
            return;
        }
        if (bytes == nullptr ||
            size > std::numeric_limits<std::uint64_t>::max() - total_bytes_) {
            throw std::length_error("SHA-256 input length overflow");
        }
        total_bytes_ += static_cast<std::uint64_t>(size);
        while (size != 0U) {
            const std::size_t take = std::min(size, block_.size() - buffered_);
            std::memcpy(block_.data() + buffered_, bytes, take);
            buffered_ += take;
            bytes += take;
            size -= take;
            if (buffered_ == block_.size()) {
                transform(block_.data());
                buffered_ = 0U;
            }
        }
    }

    std::array<std::uint8_t, kSha256Bytes> finish() {
        const std::uint64_t bit_count = total_bytes_ * 8U;
        block_[buffered_++] = 0x80U;
        if (buffered_ > 56U) {
            std::fill(block_.begin() + static_cast<std::ptrdiff_t>(buffered_),
                      block_.end(), 0U);
            transform(block_.data());
            buffered_ = 0U;
        }
        std::fill(block_.begin() + static_cast<std::ptrdiff_t>(buffered_),
                  block_.begin() + 56, 0U);
        for (unsigned index = 0; index < 8U; ++index) {
            block_[63U - index] =
                static_cast<std::uint8_t>(bit_count >> (8U * index));
        }
        transform(block_.data());
        std::array<std::uint8_t, kSha256Bytes> digest = {};
        for (std::size_t word = 0; word < state_.size(); ++word) {
            digest[4U * word + 0U] =
                static_cast<std::uint8_t>(state_[word] >> 24U);
            digest[4U * word + 1U] =
                static_cast<std::uint8_t>(state_[word] >> 16U);
            digest[4U * word + 2U] =
                static_cast<std::uint8_t>(state_[word] >> 8U);
            digest[4U * word + 3U] =
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
                static_cast<std::uint32_t>(block[4U * index]) << 24U |
                static_cast<std::uint32_t>(block[4U * index + 1U]) << 16U |
                static_cast<std::uint32_t>(block[4U * index + 2U]) << 8U |
                static_cast<std::uint32_t>(block[4U * index + 3U]);
        }
        for (unsigned index = 16U; index < 64U; ++index) {
            const std::uint32_t s0 =
                rotate_right(words[index - 15U], 7U) ^
                rotate_right(words[index - 15U], 18U) ^
                (words[index - 15U] >> 3U);
            const std::uint32_t s1 =
                rotate_right(words[index - 2U], 17U) ^
                rotate_right(words[index - 2U], 19U) ^
                (words[index - 2U] >> 10U);
            words[index] = words[index - 16U] + s0 +
                           words[index - 7U] + s1;
        }
        std::uint32_t a = state_[0];
        std::uint32_t b = state_[1];
        std::uint32_t c = state_[2];
        std::uint32_t d = state_[3];
        std::uint32_t e = state_[4];
        std::uint32_t f = state_[5];
        std::uint32_t g = state_[6];
        std::uint32_t h = state_[7];
        for (unsigned index = 0; index < 64U; ++index) {
            const std::uint32_t sigma1 =
                rotate_right(e, 6U) ^ rotate_right(e, 11U) ^
                rotate_right(e, 25U);
            const std::uint32_t choose = (e & f) ^ (~e & g);
            const std::uint32_t temporary1 =
                h + sigma1 + choose + k[index] + words[index];
            const std::uint32_t sigma0 =
                rotate_right(a, 2U) ^ rotate_right(a, 13U) ^
                rotate_right(a, 22U);
            const std::uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
            const std::uint32_t temporary2 = sigma0 + majority;
            h = g;
            g = f;
            f = e;
            e = d + temporary1;
            d = c;
            c = b;
            b = a;
            a = temporary1 + temporary2;
        }
        state_[0] += a;
        state_[1] += b;
        state_[2] += c;
        state_[3] += d;
        state_[4] += e;
        state_[5] += f;
        state_[6] += g;
        state_[7] += h;
    }

    std::array<std::uint32_t, 8> state_ = {{
        0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU,
        0x510e527fU, 0x9b05688cU, 0x1f83d9abU, 0x5be0cd19U,
    }};
    std::array<std::uint8_t, 64> block_ = {};
    std::size_t buffered_ = 0U;
    std::uint64_t total_bytes_ = 0U;
};

std::array<std::uint8_t, kSha256Bytes> sha256(
        const std::uint8_t * bytes,
        std::size_t size) {
    sha256_state state;
    state.update(bytes, size);
    return state.finish();
}

std::array<std::uint8_t, kSha256Bytes> sha256(
        const std::vector<std::uint8_t> & bytes) {
    return sha256(bytes.empty() ? nullptr : bytes.data(), bytes.size());
}

std::array<std::uint8_t, kSha256Bytes> sha256(const std::string & text) {
    return sha256(
        text.empty() ? nullptr :
            reinterpret_cast<const std::uint8_t *>(text.data()),
        text.size());
}

bool parse_hash(
        const json & value,
        const std::string & path,
        std::array<std::uint8_t, kSha256Bytes> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!value.is_string() || output == nullptr) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path, "expected SHA-256 string");
    }
    const std::string text = value.get<std::string>();
    if (text.size() != 64U) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_hash,
            path, "expected 64 lowercase hexadecimal digits");
    }
    std::array<std::uint8_t, kSha256Bytes> candidate = {};
    for (std::size_t index = 0; index < candidate.size(); ++index) {
        const char high = text[2U * index];
        const char low = text[2U * index + 1U];
        const auto nibble = [](char character) -> int {
            if (character >= '0' && character <= '9') {
                return character - '0';
            }
            if (character >= 'a' && character <= 'f') {
                return character - 'a' + 10;
            }
            return -1;
        };
        const int high_value = nibble(high);
        const int low_value = nibble(low);
        if (high_value < 0 || low_value < 0) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_hash,
                path, "expected 64 lowercase hexadecimal digits");
        }
        candidate[index] = static_cast<std::uint8_t>(
            (high_value << 4) | low_value);
    }
    *output = candidate;
    return true;
}

bool read_file(
        const std::filesystem::path & path,
        std::vector<std::uint8_t> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::ifstream stream(path, std::ios::binary | std::ios::ate);
    if (!stream) {
        return fail(
            diagnostic, npu_compiled_bundle_error::file_open,
            path.string(), "cannot open artifact");
    }
    const std::ifstream::pos_type end = stream.tellg();
    if (end < 0 ||
        static_cast<std::uintmax_t>(end) >
            std::numeric_limits<std::size_t>::max()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::file_size,
            path.string(), "artifact is not representable in memory");
    }
    const std::size_t size = static_cast<std::size_t>(end);
    std::vector<std::uint8_t> candidate(size);
    stream.seekg(0, std::ios::beg);
    if (size != 0U &&
        !stream.read(
            reinterpret_cast<char *>(candidate.data()),
            static_cast<std::streamsize>(size))) {
        return fail(
            diagnostic, npu_compiled_bundle_error::file_read,
            path.string(), "short or failed artifact read");
    }
    output->swap(candidate);
    return true;
}

bool exact_keys(
        const json & value,
        std::initializer_list<const char *> expected,
        const std::string & path,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!value.is_object()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path, "expected object");
    }
    std::set<std::string> expected_keys;
    for (const char * key : expected) {
        expected_keys.insert(key);
    }
    std::set<std::string> actual_keys;
    for (auto iterator = value.begin(); iterator != value.end(); ++iterator) {
        actual_keys.insert(iterator.key());
    }
    if (actual_keys != expected_keys) {
        std::ostringstream detail;
        detail << "unexpected object keys";
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_keys,
            path, detail.str());
    }
    return true;
}

bool json_string(
        const json & value,
        const std::string & path,
        std::string * output,
        npu_compiled_bundle_diagnostic * diagnostic,
        bool allow_empty = false) {
    if (!value.is_string()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path, "expected string");
    }
    const std::string candidate = value.get<std::string>();
    if ((!allow_empty && candidate.empty()) ||
        candidate.find('\0') != std::string::npos) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_value,
            path, "empty strings and NUL are forbidden");
    }
    *output = candidate;
    return true;
}

bool json_u64(
        const json & value,
        const std::string & path,
        std::uint64_t minimum,
        std::uint64_t maximum,
        std::uint64_t * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::uint64_t candidate = 0U;
    if (value.is_number_unsigned()) {
        candidate = value.get<std::uint64_t>();
    } else if (value.is_number_integer()) {
        const std::int64_t signed_value = value.get<std::int64_t>();
        if (signed_value < 0) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_range,
                path, "negative integer is forbidden");
        }
        candidate = static_cast<std::uint64_t>(signed_value);
    } else {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path, "expected integer");
    }
    if (candidate < minimum || candidate > maximum) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_range,
            path, "integer outside permitted range");
    }
    *output = candidate;
    return true;
}

bool valid_buffer_id(const std::string & identifier) {
    if (identifier.empty() || identifier.size() > 64U ||
        !((identifier[0] >= 'A' && identifier[0] <= 'Z') ||
          (identifier[0] >= 'a' && identifier[0] <= 'z'))) {
        return false;
    }
    for (std::size_t index = 1U; index < identifier.size(); ++index) {
        const char character = identifier[index];
        if (!((character >= 'A' && character <= 'Z') ||
              (character >= 'a' && character <= 'z') ||
              (character >= '0' && character <= '9') ||
              character == '_' || character == '.' || character == '-')) {
            return false;
        }
    }
    return true;
}

bool ascii_lower(char value) {
    return value >= 'a' && value <= 'z';
}

bool ascii_digit(char value) {
    return value >= '0' && value <= '9';
}

bool valid_provenance_label(const std::string & value) {
    if (value.empty() || value.size() > 64U || !ascii_lower(value.front())) {
        return false;
    }
    return std::all_of(
        value.begin() + 1, value.end(), [](char character) {
            return ascii_lower(character) || ascii_digit(character) ||
                   character == '_' || character == '-';
        });
}

bool valid_canonical_id(const std::string & value) {
    if (value.size() == 64U &&
        std::all_of(value.begin(), value.end(), [](char character) {
            return ascii_digit(character) ||
                   (character >= 'a' && character <= 'f');
        })) {
        return true;
    }
    if (value.size() < 3U || value.size() > 128U ||
        !ascii_lower(value.front())) {
        return false;
    }
    bool previous_separator = false;
    for (std::size_t index = 1U; index < value.size(); ++index) {
        const char character = value[index];
        const bool separator = character == '.' || character == '_' ||
                               character == ':' || character == '/' ||
                               character == '-';
        if (!ascii_lower(character) && !ascii_digit(character) && !separator) {
            return false;
        }
        if (separator && previous_separator) {
            return false;
        }
        previous_separator = separator;
    }
    return !previous_separator;
}

bool valid_source_schema(const std::string & value) {
    if (value.empty() || value.size() > 128U || !ascii_lower(value.front())) {
        return false;
    }
    bool previous_hyphen = false;
    for (char character : value) {
        if (!ascii_lower(character) && !ascii_digit(character) &&
            character != '-') {
            return false;
        }
        if (character == '-' && previous_hyphen) {
            return false;
        }
        previous_hyphen = character == '-';
    }
    const std::size_t version = value.rfind("-v");
    if (version == std::string::npos || version == 0U ||
        version + 2U >= value.size() || value[version - 1U] == '-') {
        return false;
    }
    if (value[version + 2U] == '0') {
        return false;
    }
    return std::all_of(
        value.begin() + static_cast<std::ptrdiff_t>(version + 2U),
        value.end(), ascii_digit);
}

bool valid_source_commit(const std::string & value) {
    if (value.size() != 40U && value.size() != 64U) {
        return false;
    }
    return std::all_of(value.begin(), value.end(), [](char character) {
        return ascii_digit(character) ||
               (character >= 'a' && character <= 'f');
    });
}

bool valid_origin_kind(const std::string & value) {
    return value == "graph_input" || value == "graph_output" ||
           value == "graph_node" || value == "constant" ||
           value == "compiler_transient";
}

bool power_of_two(std::uint64_t value) {
    return value != 0U && (value & (value - 1U)) == 0U;
}

bool checked_add(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (rhs > std::numeric_limits<std::uint64_t>::max() - lhs) {
        return false;
    }
    *result = lhs + rhs;
    return true;
}

bool validate_command_file(
        const std::vector<std::uint8_t> & command,
        std::uint32_t * command_count,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (command.size() < NPU_COMPILED_COMMAND_HEADER_BYTES) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_size,
            "$command.bin", "truncated command header");
    }
    if (!std::equal(kCommandMagic.begin(), kCommandMagic.end(), command.begin())) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_magic,
            "$command.bin.magic", "expected NPUCMD\\0\\0");
    }
    const std::uint16_t major = load_le16(command.data() + 8U);
    const std::uint16_t minor = load_le16(command.data() + 10U);
    if (major != NPU_COMPILED_BUNDLE_ABI_MAJOR ||
        minor != NPU_COMPILED_BUNDLE_ABI_MINOR) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_version,
            "$command.bin.version", "unsupported command ABI version");
    }
    if (load_le16(command.data() + 12U) !=
        NPU_COMPILED_COMMAND_HEADER_BYTES) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_header_size,
            "$command.bin.header_size", "ABI 1.1 header must be 64 bytes");
    }
    if (load_le16(command.data() + 14U) !=
        NPU_COMPILED_COMMAND_RECORD_BYTES) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_record_size,
            "$command.bin.record_size", "ABI 1.1 record must be 240 bytes");
    }
    const std::uint32_t count = load_le32(command.data() + 16U);
    if (count == 0U) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_count,
            "$command.bin.command_count", "at least one command is required");
    }
    if (load_le32(command.data() + 20U) != 0U) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_flags,
            "$command.bin.flags", "reserved flags must be zero");
    }
    const std::uint64_t payload_size = load_le64(command.data() + 24U);
    const std::uint64_t expected_payload_size =
        static_cast<std::uint64_t>(count) *
        NPU_COMPILED_COMMAND_RECORD_BYTES;
    if (payload_size != expected_payload_size ||
        payload_size > std::numeric_limits<std::size_t>::max() -
            NPU_COMPILED_COMMAND_HEADER_BYTES ||
        command.size() != NPU_COMPILED_COMMAND_HEADER_BYTES +
            static_cast<std::size_t>(payload_size)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_size,
            "$command.bin.payload_size", "count, payload, and file size disagree");
    }
    const auto actual_hash = sha256(
        command.data() + NPU_COMPILED_COMMAND_HEADER_BYTES,
        static_cast<std::size_t>(payload_size));
    if (!std::equal(
            actual_hash.begin(), actual_hash.end(),
            command.begin() +
                static_cast<std::ptrdiff_t>(kCommandPayloadHashOffset))) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_payload_hash,
            "$command.bin.payload_sha256", "payload hash mismatch");
    }
    *command_count = count;
    return true;
}

bool parse_canonical_metadata(
        const std::vector<std::uint8_t> & metadata_bytes,
        json * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (metadata_bytes.empty()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", "metadata is empty");
    }
    const std::string source(
        reinterpret_cast<const char *>(metadata_bytes.data()),
        metadata_bytes.size());
    bool duplicate_key = false;
    std::vector<std::set<std::string>> object_keys;
    const json::parser_callback_t callback =
        [&duplicate_key, &object_keys](
                int,
                json::parse_event_t event,
                json & parsed) -> bool {
            if (event == json::parse_event_t::object_start) {
                object_keys.emplace_back();
            } else if (event == json::parse_event_t::key) {
                if (object_keys.empty() || !parsed.is_string()) {
                    duplicate_key = true;
                } else if (!object_keys.back().insert(
                               parsed.get<std::string>()).second) {
                    duplicate_key = true;
                }
            } else if (event == json::parse_event_t::object_end) {
                if (object_keys.empty()) {
                    duplicate_key = true;
                } else {
                    object_keys.pop_back();
                }
            }
            return true;
        };
    json parsed;
    try {
        parsed = json::parse(source, callback, true, false);
    } catch (const json::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", exception.what());
    }
    if (duplicate_key || !object_keys.empty()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_duplicate_key,
            "$metadata.json", "duplicate or malformed object key stack");
    }
    std::string canonical;
    try {
        canonical = parsed.dump(
            -1, ' ', false,
            json::error_handler_t::strict);
    } catch (const json::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", exception.what());
    }
    if (canonical != source) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_noncanonical,
            "$metadata.json", "metadata is not canonical compact JSON");
    }
    *output = std::move(parsed);
    return true;
}

bool parse_permission(
        const json & value,
        const std::string & path,
        std::uint32_t * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::string text;
    if (!json_string(value, path, &text, diagnostic)) {
        return false;
    }
    if (text == "r") {
        *output = static_cast<std::uint32_t>(
            npu_command_abi_permission::read);
    } else if (text == "w") {
        *output = static_cast<std::uint32_t>(
            npu_command_abi_permission::write);
    } else if (text == "rw") {
        *output = static_cast<std::uint32_t>(
            npu_command_abi_permission::read_write);
    } else {
        return fail(
            diagnostic, npu_compiled_bundle_error::buffer_permission,
            path, "expected r, w, or rw");
    }
    return true;
}

bool parse_buffer_kind(
        const std::string & text,
        npu_compiled_buffer_kind * output) {
    if (text == "input") {
        *output = npu_compiled_buffer_kind::input;
    } else if (text == "output") {
        *output = npu_compiled_buffer_kind::output;
    } else if (text == "scratch") {
        *output = npu_compiled_buffer_kind::scratch;
    } else if (text == "transient") {
        *output = npu_compiled_buffer_kind::transient;
    } else if (text == "weight") {
        *output = npu_compiled_buffer_kind::weight;
    } else {
        return false;
    }
    return true;
}

bool parse_artifact_entry(
        const json & value,
        const std::string & path,
        std::uint64_t * size,
        std::array<std::uint8_t, kSha256Bytes> * hash,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!exact_keys(value, {"bytes", "sha256"}, path, diagnostic) ||
        !json_u64(
            value.at("bytes"), path + ".bytes", 0U,
            std::numeric_limits<std::uint64_t>::max(), size, diagnostic) ||
        !parse_hash(value.at("sha256"), path + ".sha256", hash, diagnostic)) {
        return false;
    }
    return true;
}

bool parse_abi(
        const json & value,
        npu_compiled_bundle_diagnostic * diagnostic) {
    const std::string path = "$metadata.abi";
    if (!exact_keys(
            value,
            {"major", "minor", "endianness", "command_header_bytes",
             "command_record_words", "weight_alignment"},
            path, diagnostic)) {
        return false;
    }
    std::uint64_t major = 0U;
    std::uint64_t minor = 0U;
    std::uint64_t header_bytes = 0U;
    std::uint64_t record_words = 0U;
    std::uint64_t weight_alignment = 0U;
    std::string endianness;
    if (!json_u64(value.at("major"), path + ".major", 0U, 0xffffU, &major, diagnostic) ||
        !json_u64(value.at("minor"), path + ".minor", 0U, 0xffffU, &minor, diagnostic) ||
        !json_string(value.at("endianness"), path + ".endianness", &endianness, diagnostic) ||
        !json_u64(
            value.at("command_header_bytes"), path + ".command_header_bytes",
            0U, std::numeric_limits<std::uint64_t>::max(), &header_bytes, diagnostic) ||
        !json_u64(
            value.at("command_record_words"), path + ".command_record_words",
            0U, std::numeric_limits<std::uint64_t>::max(), &record_words, diagnostic) ||
        !json_u64(
            value.at("weight_alignment"), path + ".weight_alignment",
            0U, std::numeric_limits<std::uint64_t>::max(), &weight_alignment, diagnostic)) {
        return false;
    }
    if (major != NPU_COMPILED_BUNDLE_ABI_MAJOR ||
        minor != NPU_COMPILED_BUNDLE_ABI_MINOR ||
        endianness != "little" ||
        header_bytes != NPU_COMPILED_COMMAND_HEADER_BYTES ||
        record_words != NPU_COMMAND_ABI_WORD_COUNT ||
        weight_alignment != NPU_COMPILED_WEIGHT_ALIGNMENT) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_value,
            path, "metadata ABI constants do not match 1.1");
    }
    return true;
}

bool parse_runtime_service(
        const json & value,
        npu_compiled_runtime_service_abi * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    const std::string path = "$metadata.runtime";
    if (!exact_keys(value, {"service_abi"}, path, diagnostic) ||
        !exact_keys(
            value.at("service_abi"), {"major", "minor"},
            path + ".service_abi", diagnostic)) {
        return false;
    }
    std::uint64_t major = 0U;
    std::uint64_t minor = 0U;
    if (!json_u64(
            value.at("service_abi").at("major"),
            path + ".service_abi.major", 0U, 0xffffU,
            &major, diagnostic) ||
        !json_u64(
            value.at("service_abi").at("minor"),
            path + ".service_abi.minor", 0U, 0xffffU,
            &minor, diagnostic)) {
        return false;
    }
    if (major != NPU_COMPILED_RUNTIME_SERVICE_ABI_MAJOR ||
        minor != NPU_COMPILED_RUNTIME_SERVICE_ABI_MINOR) {
        return fail(
            diagnostic, npu_compiled_bundle_error::runtime_abi,
            path + ".service_abi",
            "fixed RV64 service ABI must be exactly 1.1");
    }
    output->major = static_cast<std::uint16_t>(major);
    output->minor = static_cast<std::uint16_t>(minor);
    return true;
}

bool parse_buffers(
        const json & value,
        std::vector<npu_compiled_buffer_info> * output,
        std::map<std::string, std::size_t> * by_id,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!value.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            "$metadata.buffers", "expected array");
    }
    std::vector<npu_compiled_buffer_info> candidate;
    std::map<std::string, std::size_t> candidate_by_id;
    std::string previous_id;
    for (std::size_t index = 0; index < value.size(); ++index) {
        const std::string path = indexed_path("$metadata.buffers", index);
        const json & row = value[index];
        if (!row.is_object() || !row.contains("kind") ||
            !row.at("kind").is_string()) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_type,
                path, "buffer kind is required");
        }
        const std::string kind_text = row.at("kind").get<std::string>();
        const bool is_weight = kind_text == "weight";
        if (is_weight) {
            if (!exact_keys(
                    row,
                    {"alignment", "id", "kind", "permissions", "sha256",
                     "size", "weights_offset"},
                    path, diagnostic)) {
                return false;
            }
        } else if (!exact_keys(
                       row,
                       {"alignment", "id", "kind", "permissions", "size"},
                       path, diagnostic)) {
            return false;
        }
        npu_compiled_buffer_info buffer;
        if (!json_string(row.at("id"), path + ".id", &buffer.id, diagnostic)) {
            return false;
        }
        if (!valid_buffer_id(buffer.id)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_value,
                path + ".id", "invalid BufferId");
        }
        if (!previous_id.empty() && buffer.id <= previous_id) {
            return fail(
                diagnostic,
                buffer.id == previous_id ?
                    npu_compiled_bundle_error::buffer_duplicate :
                    npu_compiled_bundle_error::buffer_order,
                path + ".id", "buffers must be strictly sorted by BufferId");
        }
        previous_id = buffer.id;
        if (!parse_buffer_kind(kind_text, &buffer.kind)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_kind,
                path + ".kind", "unknown buffer kind");
        }
        if (!json_u64(
                row.at("size"), path + ".size", 1U,
                std::numeric_limits<std::uint64_t>::max(),
                &buffer.size, diagnostic) ||
            !json_u64(
                row.at("alignment"), path + ".alignment",
                NPU_COMPILED_WEIGHT_ALIGNMENT, 1ULL << 31U,
                &buffer.alignment, diagnostic) ||
            !parse_permission(
                row.at("permissions"), path + ".permissions",
                &buffer.permissions, diagnostic)) {
            return false;
        }
        if (!power_of_two(buffer.alignment)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_alignment,
                path + ".alignment", "alignment must be a power of two");
        }
        if (buffer.kind == npu_compiled_buffer_kind::output &&
            buffer.permissions != static_cast<std::uint32_t>(
                npu_command_abi_permission::write)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_permission,
                path + ".permissions",
                "output buffers must be write-only publication targets");
        }
        if (is_weight) {
            if (buffer.permissions != static_cast<std::uint32_t>(
                    npu_command_abi_permission::read)) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::buffer_permission,
                    path + ".permissions", "weights must be read-only");
            }
            if (!json_u64(
                    row.at("weights_offset"), path + ".weights_offset",
                    0U, std::numeric_limits<std::uint64_t>::max(),
                    &buffer.weights_offset, diagnostic) ||
                !parse_hash(
                    row.at("sha256"), path + ".sha256",
                    &buffer.sha256, diagnostic)) {
                return false;
            }
            if (buffer.weights_offset % buffer.alignment != 0U) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::buffer_alignment,
                    path + ".weights_offset", "weight offset is misaligned");
            }
        }
        candidate_by_id.emplace(buffer.id, candidate.size());
        candidate.push_back(std::move(buffer));
    }
    output->swap(candidate);
    by_id->swap(candidate_by_id);
    return true;
}

bool parse_command_identity(
        const json & value,
        const std::string & path,
        npu_compiled_command_identity * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!exact_keys(
            value,
            {"kernel_id", "command_flags", "context_id", "sequence_id",
             "producer_id", "user_tag", "covered_node_count",
             "node_hash_lo", "node_hash_hi", "local_profile"},
            path, diagnostic)) {
        return false;
    }
    npu_compiled_command_identity candidate;
    std::uint64_t integer = 0U;
    const auto parse_u32 = [&](const char * key, std::uint32_t * field) {
        if (!json_u64(
                value.at(key), path + "." + key, 0U, 0xffffffffU,
                &integer, diagnostic)) {
            return false;
        }
        *field = static_cast<std::uint32_t>(integer);
        return true;
    };
    const auto parse_u64 = [&](const char * key, std::uint64_t * field) {
        return json_u64(
            value.at(key), path + "." + key, 0U,
            std::numeric_limits<std::uint64_t>::max(), field, diagnostic);
    };
    if (!parse_u32("kernel_id", &candidate.kernel_id) ||
        !parse_u32("command_flags", &candidate.command_flags) ||
        !parse_u32("context_id", &candidate.context_id) ||
        !parse_u64("sequence_id", &candidate.sequence_id) ||
        !parse_u64("producer_id", &candidate.producer_id) ||
        !parse_u64("user_tag", &candidate.user_tag) ||
        !parse_u32("covered_node_count", &candidate.covered_node_count) ||
        !parse_u64("node_hash_lo", &candidate.node_hash_lo) ||
        !parse_u64("node_hash_hi", &candidate.node_hash_hi) ||
        !parse_u32("local_profile", &candidate.local_profile)) {
        return false;
    }
    *output = candidate;
    return true;
}

bool parse_f32_workload(
        const json & value,
        const std::string & path,
        npu_compiled_f32_alu_workload * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!exact_keys(
            value,
            {"schema", "request_groups", "response_groups", "read_groups",
             "write_groups", "input_words", "output_words", "read_bytes",
             "write_bytes", "completion_vector_elements", "expected_starts"},
            path, diagnostic)) {
        return false;
    }
    std::string schema;
    if (!json_string(value.at("schema"), path + ".schema", &schema, diagnostic) ||
        schema != kF32WorkloadSchema) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_workload,
            path + ".schema", "expected f32-alu-v1");
    }
    npu_compiled_f32_alu_workload candidate;
    const auto parse_u64 = [&](const char * key, std::uint64_t * field) {
        return json_u64(
            value.at(key), path + "." + key, 0U,
            std::numeric_limits<std::uint64_t>::max(), field, diagnostic);
    };
    if (!parse_u64("request_groups", &candidate.request_groups) ||
        !parse_u64("response_groups", &candidate.response_groups) ||
        !parse_u64("read_groups", &candidate.read_groups) ||
        !parse_u64("write_groups", &candidate.write_groups) ||
        !parse_u64("input_words", &candidate.input_words) ||
        !parse_u64("output_words", &candidate.output_words) ||
        !parse_u64("read_bytes", &candidate.read_bytes) ||
        !parse_u64("write_bytes", &candidate.write_bytes) ||
        !parse_u64(
            "completion_vector_elements",
            &candidate.completion_vector_elements) ||
        !json_u64(
            value.at("expected_starts"), path + ".expected_starts",
            0U, 1U, &candidate.expected_starts, diagnostic)) {
        return false;
    }

    std::uint64_t groups = 0U;
    if (!checked_add(candidate.read_groups, candidate.write_groups, &groups) ||
        groups != candidate.request_groups ||
        candidate.response_groups != candidate.request_groups) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_workload,
            path, "request=read+write and response=request are required");
    }
    if (candidate.input_words >
            std::numeric_limits<std::uint64_t>::max() / 4U ||
        candidate.read_bytes != candidate.input_words * 4U ||
        candidate.output_words >
            std::numeric_limits<std::uint64_t>::max() / 4U ||
        candidate.write_bytes != candidate.output_words * 4U) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_workload,
            path, "byte counts must be checked word counts times four");
    }
    if (candidate.expected_starts == 0U &&
        (candidate.request_groups != 0U || candidate.response_groups != 0U ||
         candidate.read_groups != 0U || candidate.write_groups != 0U ||
         candidate.input_words != 0U || candidate.output_words != 0U ||
         candidate.read_bytes != 0U || candidate.write_bytes != 0U ||
         candidate.completion_vector_elements != 0U)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_workload,
            path, "zero expected starts requires an all-zero workload ledger");
    }
    *output = candidate;
    return true;
}

bool validate_command_identity(
        const std::uint8_t * record,
        const npu_compiled_command_identity & identity,
        const std::string & path,
        std::size_t command_index,
        npu_compiled_bundle_diagnostic * diagnostic) {
    const std::array<std::uint64_t, 10> expected = {{
        static_cast<std::uint32_t>(load_le64(record + 0U * 8U)),
        static_cast<std::uint32_t>(load_le64(record + 0U * 8U) >> 32U),
        static_cast<std::uint32_t>(load_le64(record + 1U * 8U)),
        load_le64(record + 2U * 8U),
        load_le64(record + 3U * 8U),
        load_le64(record + 4U * 8U),
        static_cast<std::uint32_t>(load_le64(record + 5U * 8U)),
        load_le64(record + 6U * 8U),
        load_le64(record + 7U * 8U),
        static_cast<std::uint32_t>(load_le64(record + 9U * 8U)),
    }};
    const std::array<std::uint64_t, 10> actual = {{
        identity.kernel_id, identity.command_flags, identity.context_id,
        identity.sequence_id, identity.producer_id, identity.user_tag,
        identity.covered_node_count, identity.node_hash_lo,
        identity.node_hash_hi, identity.local_profile,
    }};
    static constexpr std::array<const char *, 10> names = {{
        "kernel_id", "command_flags", "context_id", "sequence_id",
        "producer_id", "user_tag", "covered_node_count", "node_hash_lo",
        "node_hash_hi", "local_profile",
    }};
    for (std::size_t field = 0U; field < expected.size(); ++field) {
        if (actual[field] != expected[field]) {
            return fail(
                diagnostic, npu_compiled_bundle_error::command_identity,
                path + "." + names[field],
                "identity does not match immutable descriptor",
                command_index);
        }
    }
    return true;
}

bool parse_commands(
        const json & value,
        std::uint32_t file_command_count,
        const std::vector<std::uint8_t> & command_bytes,
        std::vector<npu_compiled_command_info> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!value.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            "$metadata.commands", "expected array");
    }
    if (value.size() != file_command_count) {
        return fail(
            diagnostic, npu_compiled_bundle_error::command_count,
            "$metadata.commands", "metadata count does not match command.bin");
    }
    std::set<std::string> names;
    std::vector<npu_compiled_command_info> candidate;
    candidate.reserve(value.size());
    std::uint64_t total_cycle_upper_bound = 0U;
    for (std::size_t index = 0; index < value.size(); ++index) {
        const std::string path = indexed_path("$metadata.commands", index);
        const json & row = value[index];
        if (!exact_keys(
                row,
                {"cycle_upper_bound", "descriptor_sha256", "index", "name",
                 "node_ids", "node_sha256", "owner", "identity", "workload"},
                path, diagnostic)) {
            return false;
        }
        npu_compiled_command_info command;
        std::uint64_t integer = 0U;
        if (!json_u64(
                row.at("index"), path + ".index", 0U, 0xffffffffU,
                &integer, diagnostic)) {
            return false;
        }
        command.index = static_cast<std::uint32_t>(integer);
        if (command.index != index) {
            return fail(
                diagnostic, npu_compiled_bundle_error::command_order,
                path + ".index", "commands must use contiguous ordered indices");
        }
        if (!json_u64(
                row.at("cycle_upper_bound"), path + ".cycle_upper_bound",
                1U, std::numeric_limits<std::uint64_t>::max(),
                &command.cycle_upper_bound, diagnostic)) {
            return false;
        }
        if (!checked_add(
                total_cycle_upper_bound, command.cycle_upper_bound,
                &total_cycle_upper_bound)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_range,
                path + ".cycle_upper_bound",
                "aggregate command cycle upper bound overflows u64");
        }
        if (!json_string(row.at("name"), path + ".name", &command.name, diagnostic)) {
            return false;
        }
        if (!names.insert(command.name).second) {
            return fail(
                diagnostic, npu_compiled_bundle_error::command_duplicate,
                path + ".name", "duplicate command name");
        }
        std::string owner;
        if (!json_string(row.at("owner"), path + ".owner", &owner, diagnostic)) {
            return false;
        }
        if (owner != "f32_alu") {
            return fail(
                diagnostic, npu_compiled_bundle_error::command_owner,
                path + ".owner", "only f32_alu is supported");
        }
        command.owner = npu_compiled_command_owner::f32_alu;
        if (!parse_command_identity(
                row.at("identity"), path + ".identity",
                &command.identity, diagnostic) ||
            !parse_f32_workload(
                row.at("workload"), path + ".workload",
                &command.f32_alu, diagnostic)) {
            return false;
        }
        if (command.identity.kernel_id != kF32AluKernelId) {
            return fail(
                diagnostic, npu_compiled_bundle_error::kernel_id,
                path + ".identity.kernel_id",
                "f32_alu requires kernel 0x514e0010", index);
        }
        if (!parse_hash(
                row.at("descriptor_sha256"), path + ".descriptor_sha256",
                &command.descriptor_sha256, diagnostic) ||
            !parse_hash(
                row.at("node_sha256"), path + ".node_sha256",
                &command.node_sha256, diagnostic)) {
            return false;
        }
        const json & raw_node_ids = row.at("node_ids");
        if (!raw_node_ids.is_array() || raw_node_ids.empty() ||
            raw_node_ids.size() > 0xffffffffULL) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_type,
                path + ".node_ids", "expected non-empty u64 array");
        }
        sha256_state node_hash;
        command.node_ids.reserve(raw_node_ids.size());
        for (std::size_t node_index = 0;
             node_index < raw_node_ids.size(); ++node_index) {
            std::uint64_t node_id = 0U;
            if (!json_u64(
                    raw_node_ids[node_index],
                    path + ".node_ids[" + std::to_string(node_index) + "]",
                    0U, std::numeric_limits<std::uint64_t>::max(),
                    &node_id, diagnostic)) {
                return false;
            }
            std::array<std::uint8_t, 8> encoded = {};
            store_le64(encoded.data(), node_id);
            node_hash.update(encoded.data(), encoded.size());
            command.node_ids.push_back(node_id);
        }
        if (node_hash.finish() != command.node_sha256) {
            return fail(
                diagnostic, npu_compiled_bundle_error::node_hash,
                path + ".node_sha256", "hash does not match node_ids");
        }

        const std::size_t record_offset =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            index * NPU_COMPILED_COMMAND_RECORD_BYTES;
        const std::uint8_t * record = command_bytes.data() + record_offset;
        if (sha256(record, NPU_COMPILED_COMMAND_RECORD_BYTES) !=
            command.descriptor_sha256) {
            return fail(
                diagnostic, npu_compiled_bundle_error::descriptor_hash,
                path + ".descriptor_sha256",
                "hash does not match command record", index);
        }
        if (load_le64(record + 8U * 8U) != 0U) {
            return fail(diagnostic, npu_compiled_bundle_error::metadata_value,
                        "$command.bin.records[" + std::to_string(index) + "][8]",
                        "current F32 portal requires deadline=0; use metadata cycle_upper_bound", index);
        }
        const std::uint64_t word5 = load_le64(record + 5U * 8U);
        if (!validate_command_identity(
                record, command.identity, path + ".identity",
                index, diagnostic)) {
            return false;
        }
        if (static_cast<std::uint32_t>(word5) != command.node_ids.size()) {
            return fail(
                diagnostic, npu_compiled_bundle_error::node_count,
                path + ".node_ids", "does not match descriptor word 5", index);
        }
        if (load_le64(record + 6U * 8U) !=
                load_le64(command.node_sha256.data()) ||
            load_le64(record + 7U * 8U) !=
                load_le64(command.node_sha256.data() + 8U)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::node_hash,
                path + ".node_sha256", "does not match descriptor words 6/7", index);
        }
        candidate.push_back(std::move(command));
    }
    output->swap(candidate);
    return true;
}

bool parse_nullable_canonical_id(
        const json & value,
        const std::string & path,
        bool * present,
        std::string * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (value.is_null()) {
        *present = false;
        output->clear();
        return true;
    }
    std::string candidate;
    if (!json_string(value, path, &candidate, diagnostic) ||
        !valid_canonical_id(candidate)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_format,
            path,
            "expected null, lowercase segmented id, or lowercase SHA-256 id");
    }
    *present = true;
    *output = std::move(candidate);
    return true;
}

bool same_provenance_origin(
        const npu_compiled_provenance_origin & lhs,
        const npu_compiled_provenance_origin & rhs) {
    return lhs.kind == rhs.kind && lhs.index == rhs.index &&
           lhs.has_canonical_id == rhs.has_canonical_id &&
           lhs.canonical_id == rhs.canonical_id &&
           lhs.tensor_descriptor_sha256 == rhs.tensor_descriptor_sha256;
}

bool parse_provenance_origin(
        const json & row,
        const std::string & path,
        const char * kind_key,
        const char * index_key,
        const char * canonical_key,
        const char * descriptor_key,
        npu_compiled_provenance_origin * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    npu_compiled_provenance_origin candidate;
    if (!json_string(
            row.at(kind_key), path + "." + kind_key,
            &candidate.kind, diagnostic) ||
        !valid_origin_kind(candidate.kind)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_format,
            path + "." + kind_key, "unknown provenance origin kind");
    }
    if (!json_u64(
            row.at(index_key), path + "." + index_key, 0U,
            std::numeric_limits<std::uint64_t>::max(),
            &candidate.index, diagnostic) ||
        !parse_nullable_canonical_id(
            row.at(canonical_key), path + "." + canonical_key,
            &candidate.has_canonical_id, &candidate.canonical_id,
            diagnostic) ||
        !parse_hash(
            row.at(descriptor_key), path + "." + descriptor_key,
            &candidate.tensor_descriptor_sha256, diagnostic)) {
        return false;
    }
    *output = std::move(candidate);
    return true;
}

bool parse_provenance(
        const json & value,
        const std::vector<npu_compiled_buffer_info> & buffers,
        const std::map<std::string, std::size_t> & buffer_by_id,
        const std::vector<npu_compiled_command_info> & commands,
        npu_compiled_provenance_source * source_output,
        std::vector<npu_compiled_node_binding> * node_output,
        std::vector<npu_compiled_buffer_binding> * buffer_output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    const std::string path = "$metadata.provenance";
    if (!exact_keys(
            value, {"source", "node_bindings", "buffer_bindings"},
            path, diagnostic)) {
        return false;
    }

    const json & raw_source = value.at("source");
    if (!exact_keys(
            raw_source,
            {"schema", "manifest_sha256", "raw_sha256", "profile",
             "source_commit", "graph_scope", "graph_ir_schema",
             "graph_ir_sha256"},
            path + ".source", diagnostic)) {
        return false;
    }
    npu_compiled_provenance_source source;
    if (!json_string(
            raw_source.at("schema"), path + ".source.schema",
            &source.schema, diagnostic) ||
        !valid_source_schema(source.schema)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_format,
            path + ".source.schema",
            "expected lowercase hyphenated schema ending in -vN");
    }
    if (!parse_hash(
            raw_source.at("manifest_sha256"),
            path + ".source.manifest_sha256",
            &source.manifest_sha256, diagnostic) ||
        !parse_hash(
            raw_source.at("raw_sha256"),
            path + ".source.raw_sha256",
            &source.raw_sha256, diagnostic) ||
        !json_string(
            raw_source.at("graph_ir_schema"),
            path + ".source.graph_ir_schema",
            &source.graph_ir_schema, diagnostic) ||
        !valid_source_schema(source.graph_ir_schema) ||
        !parse_hash(
            raw_source.at("graph_ir_sha256"),
            path + ".source.graph_ir_sha256",
            &source.graph_ir_sha256, diagnostic) ||
        !json_string(
            raw_source.at("profile"), path + ".source.profile",
            &source.profile, diagnostic) ||
        !valid_canonical_id(source.profile) ||
        !json_string(
            raw_source.at("graph_scope"), path + ".source.graph_scope",
            &source.graph_scope, diagnostic) ||
        !valid_canonical_id(source.graph_scope)) {
        if (diagnostic != nullptr &&
            diagnostic->error != npu_compiled_bundle_error::none) {
            return false;
        }
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_format,
            path + ".source",
            "graph IR schema, profile, or graph_scope has invalid format");
    }
    if (raw_source.at("source_commit").is_null()) {
        source.has_source_commit = false;
    } else {
        if (!json_string(
                raw_source.at("source_commit"),
                path + ".source.source_commit",
                &source.source_commit, diagnostic) ||
            !valid_source_commit(source.source_commit)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_format,
                path + ".source.source_commit",
                "expected null or lowercase 40/64 digit commit");
        }
        source.has_source_commit = true;
    }

    std::vector<std::uint64_t> flattened_nodes;
    std::map<std::uint64_t, const npu_compiled_command_info *> command_by_node;
    for (const npu_compiled_command_info & command : commands) {
        for (std::uint64_t node_id : command.node_ids) {
            if (!command_by_node.emplace(node_id, &command).second) {
                return fail(
                    diagnostic,
                    npu_compiled_bundle_error::provenance_node_duplicate,
                    path + ".node_bindings",
                    "command node_ids are not globally unique");
            }
            flattened_nodes.push_back(node_id);
        }
    }
    const json & raw_nodes = value.at("node_bindings");
    if (!raw_nodes.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path + ".node_bindings", "expected array");
    }
    std::vector<npu_compiled_node_binding> nodes;
    nodes.reserve(raw_nodes.size());
    std::set<std::uint64_t> artifact_ids;
    std::set<std::string> canonical_ids;
    std::set<std::uint64_t> manifest_indices;
    std::set<std::uint64_t> artifact_schedule_positions;
    std::set<std::uint64_t> source_schedule_positions;
    for (std::size_t index = 0U; index < raw_nodes.size(); ++index) {
        const std::string node_path =
            indexed_path("$metadata.provenance.node_bindings", index);
        const json & row = raw_nodes[index];
        if (!exact_keys(
                row,
                {"artifact_node_id", "canonical_id", "manifest_graph_index",
                 "source_descriptor_sha256", "command_descriptor_sha256",
                 "artifact_schedule_position", "source_schedule_position",
                 "profile_family", "profile_id"},
                node_path, diagnostic)) {
            return false;
        }
        npu_compiled_node_binding node;
        if (!json_u64(
                row.at("artifact_node_id"), node_path + ".artifact_node_id",
                0U, std::numeric_limits<std::uint64_t>::max(),
                &node.artifact_node_id, diagnostic) ||
            !json_string(
                row.at("canonical_id"), node_path + ".canonical_id",
                &node.canonical_id, diagnostic) ||
            !json_u64(
                row.at("manifest_graph_index"),
                node_path + ".manifest_graph_index", 0U,
                std::numeric_limits<std::uint64_t>::max(),
                &node.manifest_graph_index, diagnostic) ||
            !parse_hash(
                row.at("source_descriptor_sha256"),
                node_path + ".source_descriptor_sha256",
                &node.source_descriptor_sha256, diagnostic) ||
            !parse_hash(
                row.at("command_descriptor_sha256"),
                node_path + ".command_descriptor_sha256",
                &node.command_descriptor_sha256, diagnostic) ||
            !json_u64(
                row.at("artifact_schedule_position"),
                node_path + ".artifact_schedule_position", 0U,
                std::numeric_limits<std::uint64_t>::max(),
                &node.artifact_schedule_position, diagnostic) ||
            !json_u64(
                row.at("source_schedule_position"),
                node_path + ".source_schedule_position", 0U,
                std::numeric_limits<std::uint64_t>::max(),
                &node.source_schedule_position, diagnostic) ||
            !json_string(
                row.at("profile_family"), node_path + ".profile_family",
                &node.profile_family, diagnostic) ||
            !json_string(
                row.at("profile_id"), node_path + ".profile_id",
                &node.profile_id, diagnostic)) {
            return false;
        }
        if (!valid_canonical_id(node.canonical_id) ||
            !valid_provenance_label(node.profile_family) ||
            !valid_provenance_label(node.profile_id)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_format,
                node_path, "invalid canonical id or profile label");
        }
        if (!artifact_ids.insert(node.artifact_node_id).second ||
            !canonical_ids.insert(node.canonical_id).second ||
            !manifest_indices.insert(node.manifest_graph_index).second ||
            !artifact_schedule_positions.insert(
                node.artifact_schedule_position).second ||
            !source_schedule_positions.insert(
                node.source_schedule_position).second) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_node_duplicate,
                node_path, "node provenance identity is not globally unique");
        }
        nodes.push_back(std::move(node));
    }
    if (nodes.size() != flattened_nodes.size()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_node_coverage,
            path + ".node_bindings",
            "bindings do not exactly cover command node_ids");
    }
    const std::set<std::uint64_t> expected_artifact_ids(
        flattened_nodes.begin(), flattened_nodes.end());
    if (artifact_ids != expected_artifact_ids) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_node_coverage,
            path + ".node_bindings",
            "artifact_node_id set differs from command node_ids");
    }
    for (std::size_t index = 0U; index < nodes.size(); ++index) {
        const npu_compiled_node_binding & node = nodes[index];
        const std::string node_path =
            indexed_path("$metadata.provenance.node_bindings", index);
        if (node.artifact_schedule_position != index ||
            node.artifact_node_id != flattened_nodes[index]) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_node_order,
                node_path,
                "bindings must follow contiguous command node schedule order");
        }
        const auto command = command_by_node.find(node.artifact_node_id);
        if (command == command_by_node.end()) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_node_coverage,
                node_path + ".artifact_node_id",
                "artifact node is not covered by a command");
        }
        if (node.command_descriptor_sha256 !=
            command->second->descriptor_sha256) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_node_descriptor,
                node_path + ".command_descriptor_sha256",
                "hash does not match the descriptor covering this node");
        }
    }

    const json & raw_buffers = value.at("buffer_bindings");
    if (!raw_buffers.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path + ".buffer_bindings", "expected array");
    }
    std::vector<npu_compiled_buffer_binding> provenance_buffers;
    provenance_buffers.reserve(raw_buffers.size());
    std::set<std::string> binding_ids;
    std::set<std::string> logical_canonical_ids;
    std::string previous_buffer_id;
    for (std::size_t index = 0U; index < raw_buffers.size(); ++index) {
        const std::string buffer_path =
            indexed_path("$metadata.provenance.buffer_bindings", index);
        const json & row = raw_buffers[index];
        if (!exact_keys(
                row,
                {"buffer_id", "origin_kind", "origin_index", "canonical_id",
                 "tensor_descriptor_sha256", "storage_origin_kind",
                 "storage_origin_index", "storage_canonical_id",
                 "storage_tensor_descriptor_sha256", "alias_offset",
                 "logical_size", "storage_size"},
                buffer_path, diagnostic)) {
            return false;
        }
        npu_compiled_buffer_binding binding;
        if (!json_string(
                row.at("buffer_id"), buffer_path + ".buffer_id",
                &binding.buffer_id, diagnostic) ||
            !valid_buffer_id(binding.buffer_id)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_format,
                buffer_path + ".buffer_id", "invalid BufferId");
        }
        if (!binding_ids.insert(binding.buffer_id).second) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_buffer_duplicate,
                buffer_path + ".buffer_id", "duplicate buffer binding");
        }
        if (!previous_buffer_id.empty() &&
            binding.buffer_id <= previous_buffer_id) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_buffer_order,
                buffer_path + ".buffer_id",
                "buffer bindings must be strictly sorted by BufferId");
        }
        previous_buffer_id = binding.buffer_id;
        if (!parse_provenance_origin(
                row, buffer_path, "origin_kind", "origin_index",
                "canonical_id", "tensor_descriptor_sha256",
                &binding.logical, diagnostic) ||
            !parse_provenance_origin(
                row, buffer_path, "storage_origin_kind",
                "storage_origin_index", "storage_canonical_id",
                "storage_tensor_descriptor_sha256",
                &binding.storage, diagnostic) ||
            !json_u64(
                row.at("alias_offset"), buffer_path + ".alias_offset",
                0U, std::numeric_limits<std::uint64_t>::max(),
                &binding.alias_offset, diagnostic) ||
            !json_u64(
                row.at("logical_size"), buffer_path + ".logical_size",
                1U, std::numeric_limits<std::uint64_t>::max(),
                &binding.logical_size, diagnostic) ||
            !json_u64(
                row.at("storage_size"), buffer_path + ".storage_size",
                1U, std::numeric_limits<std::uint64_t>::max(),
                &binding.storage_size, diagnostic)) {
            return false;
        }
        if (binding.logical.has_canonical_id &&
            !logical_canonical_ids.insert(binding.logical.canonical_id).second) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_buffer_duplicate,
                buffer_path + ".canonical_id",
                "duplicate logical canonical id");
        }
        if (binding.alias_offset >= binding.storage_size ||
            binding.logical_size >
                binding.storage_size - binding.alias_offset) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_buffer_range,
                buffer_path,
                "logical alias range lies outside normalized storage root");
        }
        const auto artifact_buffer = buffer_by_id.find(binding.buffer_id);
        if (artifact_buffer == buffer_by_id.end()) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_buffer_coverage,
                buffer_path + ".buffer_id",
                "binding names no artifact buffer");
        }
        if (binding.storage_size != buffers[artifact_buffer->second].size) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_buffer_range,
                buffer_path + ".storage_size",
                "storage_size must equal artifact buffer size");
        }
        if (same_provenance_origin(binding.logical, binding.storage) &&
            (binding.alias_offset != 0U ||
             binding.logical_size != binding.storage_size)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::provenance_buffer_range,
                buffer_path,
                "non-view origin requires a complete zero-offset range");
        }
        provenance_buffers.push_back(std::move(binding));
    }
    if (provenance_buffers.size() != buffers.size() ||
        binding_ids.size() != buffer_by_id.size()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::provenance_buffer_coverage,
            path + ".buffer_bindings",
            "bindings do not exactly cover artifact buffers");
    }
    for (const auto & buffer : buffers) {
        if (binding_ids.find(buffer.id) == binding_ids.end()) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::provenance_buffer_coverage,
                path + ".buffer_bindings",
                "artifact buffer is missing provenance");
        }
    }

    *source_output = std::move(source);
    node_output->swap(nodes);
    buffer_output->swap(provenance_buffers);
    return true;
}

bool relocatable_word(std::uint32_t word) {
    return std::find(
        std::begin(kRelocatableWords), std::end(kRelocatableWords), word) !=
        std::end(kRelocatableWords);
}

bool expected_relocation_kind(
        std::uint32_t word,
        npu_compiled_relocation_kind * kind) {
    if (word == 10U || word == 11U || word == 12U || word == 13U) {
        *kind = npu_compiled_relocation_kind::iova64;
        return true;
    }
    if (word == 23U || word == 26U || word == 28U) {
        *kind = npu_compiled_relocation_kind::window_base64;
        return true;
    }
    return false;
}

bool parse_relocations(
        const json & value,
        const std::map<std::string, std::size_t> & buffer_by_id,
        const std::vector<npu_compiled_buffer_info> & buffers,
        std::size_t command_count,
        std::vector<npu_compiled_relocation_info> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (!value.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            "$metadata.relocations", "expected array");
    }
    std::vector<npu_compiled_relocation_info> candidate;
    candidate.reserve(value.size());
    std::pair<std::uint32_t, std::uint32_t> previous = {};
    bool have_previous = false;
    for (std::size_t index = 0; index < value.size(); ++index) {
        const std::string path = indexed_path("$metadata.relocations", index);
        const json & row = value[index];
        if (!exact_keys(
                row,
                {"addend", "buffer_id", "command_index", "kind", "word_index"},
                path, diagnostic)) {
            return false;
        }
        npu_compiled_relocation_info relocation;
        std::uint64_t integer = 0U;
        if (!json_u64(
                row.at("command_index"), path + ".command_index",
                0U, 0xffffffffU, &integer, diagnostic)) {
            return false;
        }
        relocation.command_index = static_cast<std::uint32_t>(integer);
        if (relocation.command_index >= command_count) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_command,
                path + ".command_index", "outside command table",
                relocation.command_index, index);
        }
        if (!json_u64(
                row.at("word_index"), path + ".word_index",
                0U, NPU_COMMAND_ABI_WORD_COUNT - 1U,
                &integer, diagnostic)) {
            return false;
        }
        relocation.word_index = static_cast<std::uint32_t>(integer);
        if (!relocatable_word(relocation.word_index)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_word,
                path + ".word_index", "word is not relocatable",
                relocation.command_index, index);
        }
        const std::pair<std::uint32_t, std::uint32_t> key = {
            relocation.command_index, relocation.word_index,
        };
        if (have_previous && key <= previous) {
            return fail(
                diagnostic,
                key == previous ?
                    npu_compiled_bundle_error::relocation_duplicate :
                    npu_compiled_bundle_error::relocation_order,
                path, "relocations must be strictly sorted by command/word",
                relocation.command_index, index);
        }
        previous = key;
        have_previous = true;
        std::string kind_text;
        if (!json_string(row.at("kind"), path + ".kind", &kind_text, diagnostic)) {
            return false;
        }
        npu_compiled_relocation_kind expected_kind;
        if (!expected_relocation_kind(relocation.word_index, &expected_kind) ||
            (kind_text != "iova64" && kind_text != "window_base64")) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_kind,
                path + ".kind", "unknown relocation kind",
                relocation.command_index, index);
        }
        relocation.kind = kind_text == "iova64" ?
            npu_compiled_relocation_kind::iova64 :
            npu_compiled_relocation_kind::window_base64;
        if (relocation.kind != expected_kind) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_kind,
                path + ".kind", "kind is invalid for target word",
                relocation.command_index, index);
        }
        if (!json_string(
                row.at("buffer_id"), path + ".buffer_id",
                &relocation.buffer_id, diagnostic) ||
            !valid_buffer_id(relocation.buffer_id)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_value,
                path + ".buffer_id", "invalid BufferId",
                relocation.command_index, index);
        }
        const auto buffer_iterator = buffer_by_id.find(relocation.buffer_id);
        if (buffer_iterator == buffer_by_id.end()) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_buffer,
                path + ".buffer_id", "unknown BufferId",
                relocation.command_index, index);
        }
        if (!json_u64(
                row.at("addend"), path + ".addend", 0U,
                std::numeric_limits<std::uint64_t>::max(),
                &relocation.addend, diagnostic)) {
            return false;
        }
        const npu_compiled_buffer_info & buffer =
            buffers[buffer_iterator->second];
        if (relocation.addend >= buffer.size) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_range,
                path + ".addend", "addend is outside buffer",
                relocation.command_index, index);
        }
        const bool needs_read =
            relocation.word_index == 10U ||
            relocation.word_index == 11U ||
            relocation.word_index == 12U ||
            relocation.word_index == 23U ||
            relocation.word_index == 26U;
        const bool needs_write =
            relocation.word_index == 13U ||
            relocation.word_index == 28U;
        if ((needs_read &&
             (buffer.permissions & static_cast<std::uint32_t>(
                 npu_command_abi_permission::read)) == 0U) ||
            (needs_write &&
             (buffer.permissions & static_cast<std::uint32_t>(
                 npu_command_abi_permission::write)) == 0U)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_permission,
                path + ".buffer_id", "buffer lacks relocation permission",
                relocation.command_index, index);
        }
        candidate.push_back(std::move(relocation));
    }
    output->swap(candidate);
    return true;
}

bool publication_partition_complete(
        std::vector<std::pair<std::uint64_t, std::uint64_t>> intervals,
        std::uint64_t buffer_size,
        const std::string & path,
        const char * space,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::sort(intervals.begin(), intervals.end());
    std::uint64_t next = 0U;
    for (const auto & interval : intervals) {
        if (interval.first != next || interval.second <= interval.first) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_coverage,
                path, std::string(space) +
                    " ranges must cover without gaps or overlaps");
        }
        next = interval.second;
    }
    if (next != buffer_size) {
        return fail(
            diagnostic, npu_compiled_bundle_error::publication_coverage,
            path, std::string(space) +
                " ranges must cover the complete output buffer");
    }
    return true;
}

bool parse_publication(
        const json & value,
        const std::map<std::string, std::size_t> & buffer_by_id,
        const std::vector<npu_compiled_buffer_info> & buffers,
        npu_compiled_publication_mode * mode,
        std::vector<npu_compiled_publication_entry> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    const std::string path = "$metadata.publication";
    if (!exact_keys(value, {"entries", "mode"}, path, diagnostic)) {
        return false;
    }
    std::string mode_text;
    if (!json_string(value.at("mode"), path + ".mode", &mode_text, diagnostic) ||
        mode_text != "bundle_atomic") {
        return fail(
            diagnostic, npu_compiled_bundle_error::publication_mode,
            path + ".mode", "only bundle_atomic publication is supported");
    }
    const json & entries = value.at("entries");
    if (!entries.is_array()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_type,
            path + ".entries", "expected array");
    }

    using publication_key =
        std::tuple<std::string, std::uint64_t, std::uint64_t, std::uint64_t>;
    publication_key previous;
    bool have_previous = false;
    std::vector<npu_compiled_publication_entry> candidate;
    candidate.reserve(entries.size());
    std::map<std::string,
             std::vector<std::pair<std::uint64_t, std::uint64_t>>>
        source_intervals;
    std::map<std::string,
             std::vector<std::pair<std::uint64_t, std::uint64_t>>>
        target_intervals;
    for (std::size_t index = 0U; index < entries.size(); ++index) {
        const std::string entry_path =
            indexed_path("$metadata.publication.entries", index);
        const json & row = entries[index];
        if (!exact_keys(
                row,
                {"buffer_id", "source_offset", "target_offset", "bytes"},
                entry_path, diagnostic)) {
            return false;
        }
        npu_compiled_publication_entry entry;
        if (!json_string(
                row.at("buffer_id"), entry_path + ".buffer_id",
                &entry.buffer_id, diagnostic) ||
            !valid_buffer_id(entry.buffer_id)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::metadata_value,
                entry_path + ".buffer_id", "invalid BufferId");
        }
        if (!json_u64(
                row.at("source_offset"), entry_path + ".source_offset",
                0U, std::numeric_limits<std::uint64_t>::max(),
                &entry.source_offset, diagnostic) ||
            !json_u64(
                row.at("target_offset"), entry_path + ".target_offset",
                0U, std::numeric_limits<std::uint64_t>::max(),
                &entry.target_offset, diagnostic) ||
            !json_u64(
                row.at("bytes"), entry_path + ".bytes", 1U,
                std::numeric_limits<std::uint64_t>::max(),
                &entry.bytes, diagnostic)) {
            return false;
        }
        const publication_key key = {
            entry.buffer_id, entry.target_offset,
            entry.source_offset, entry.bytes,
        };
        if (have_previous && key <= previous) {
            return fail(
                diagnostic,
                key == previous ?
                    npu_compiled_bundle_error::publication_duplicate :
                    npu_compiled_bundle_error::publication_order,
                entry_path,
                "publication entries must be strictly sorted by "
                "buffer/target/source/bytes");
        }
        previous = key;
        have_previous = true;

        const auto found = buffer_by_id.find(entry.buffer_id);
        if (found == buffer_by_id.end()) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_buffer,
                entry_path + ".buffer_id", "unknown BufferId");
        }
        const npu_compiled_buffer_info & buffer = buffers[found->second];
        if (buffer.kind != npu_compiled_buffer_kind::output) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_buffer,
                entry_path + ".buffer_id",
                "publication may reference only output buffers");
        }
        if (buffer.permissions != static_cast<std::uint32_t>(
                npu_command_abi_permission::write)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_permission,
                entry_path + ".buffer_id",
                "publication output must be write-only");
        }
        std::uint64_t source_end = 0U;
        std::uint64_t target_end = 0U;
        if (!checked_add(entry.source_offset, entry.bytes, &source_end) ||
            !checked_add(entry.target_offset, entry.bytes, &target_end) ||
            source_end > buffer.size || target_end > buffer.size) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_range,
                entry_path, "publication range is outside output buffer");
        }
        source_intervals[entry.buffer_id].push_back(
            {entry.source_offset, source_end});
        target_intervals[entry.buffer_id].push_back(
            {entry.target_offset, target_end});
        candidate.push_back(std::move(entry));
    }

    for (const npu_compiled_buffer_info & buffer : buffers) {
        if (buffer.kind != npu_compiled_buffer_kind::output) {
            continue;
        }
        const std::string buffer_path =
            path + ".entries(" + buffer.id + ")";
        if (!publication_partition_complete(
                source_intervals[buffer.id], buffer.size,
                buffer_path, "source", diagnostic) ||
            !publication_partition_complete(
                target_intervals[buffer.id], buffer.size,
                buffer_path, "target", diagnostic)) {
            return false;
        }
    }
    *mode = npu_compiled_publication_mode::bundle_atomic;
    output->swap(candidate);
    return true;
}

bool validate_weight_image(
        const std::vector<std::uint8_t> & weights,
        const std::vector<npu_compiled_buffer_info> & buffers,
        npu_compiled_bundle_diagnostic * diagnostic) {
    if (weights.size() % NPU_COMPILED_WEIGHT_ALIGNMENT != 0U) {
        return fail(
            diagnostic, npu_compiled_bundle_error::buffer_alignment,
            "$weights.bin", "file size is not a multiple of 64 bytes");
    }
    struct weight_range {
        std::uint64_t begin;
        std::uint64_t end;
        std::size_t buffer_index;
    };
    std::vector<weight_range> ranges;
    for (std::size_t index = 0; index < buffers.size(); ++index) {
        const npu_compiled_buffer_info & buffer = buffers[index];
        if (buffer.kind != npu_compiled_buffer_kind::weight) {
            continue;
        }
        if (buffer.weights_offset > weights.size() ||
            buffer.size > weights.size() - buffer.weights_offset) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_range,
                indexed_path("$metadata.buffers", index),
                "weight range is outside weights.bin");
        }
        const auto actual_hash = sha256(
            weights.data() + static_cast<std::size_t>(buffer.weights_offset),
            static_cast<std::size_t>(buffer.size));
        if (actual_hash != buffer.sha256) {
            return fail(
                diagnostic, npu_compiled_bundle_error::weight_hash,
                indexed_path("$metadata.buffers", index) + ".sha256",
                "weight object hash mismatch");
        }
        ranges.push_back({
            buffer.weights_offset,
            buffer.weights_offset + buffer.size,
            index,
        });
    }
    std::sort(
        ranges.begin(), ranges.end(),
        [&buffers](const weight_range & lhs, const weight_range & rhs) {
            if (lhs.begin != rhs.begin) {
                return lhs.begin < rhs.begin;
            }
            if (lhs.end != rhs.end) {
                return lhs.end < rhs.end;
            }
            return buffers[lhs.buffer_index].id <
                   buffers[rhs.buffer_index].id;
        });
    for (std::size_t index = 1U; index < ranges.size(); ++index) {
        const weight_range & previous = ranges[index - 1U];
        const weight_range & current = ranges[index];
        if (current.begin >= previous.end) {
            continue;
        }
        const npu_compiled_buffer_info & previous_buffer =
            buffers[previous.buffer_index];
        const npu_compiled_buffer_info & current_buffer =
            buffers[current.buffer_index];
        const bool exact_dedup =
            current.begin == previous.begin &&
            current.end == previous.end &&
            current_buffer.sha256 == previous_buffer.sha256;
        if (!exact_dedup) {
            return fail(
                diagnostic, npu_compiled_bundle_error::buffer_overlap,
                "$metadata.buffers", "weight objects overlap without exact dedup");
        }
    }
    std::vector<std::pair<std::uint64_t, std::uint64_t>> unique_ranges;
    for (const weight_range & range : ranges) {
        const std::pair<std::uint64_t, std::uint64_t> pair = {
            range.begin, range.end,
        };
        if (unique_ranges.empty() || unique_ranges.back() != pair) {
            unique_ranges.push_back(pair);
        }
    }
    std::size_t cursor = 0U;
    for (const auto & range : unique_ranges) {
        const std::size_t begin = static_cast<std::size_t>(range.first);
        const std::size_t end = static_cast<std::size_t>(range.second);
        if (std::any_of(
                weights.begin() + static_cast<std::ptrdiff_t>(cursor),
                weights.begin() + static_cast<std::ptrdiff_t>(begin),
                [](std::uint8_t byte) { return byte != 0U; })) {
            return fail(
                diagnostic, npu_compiled_bundle_error::weight_padding,
                "$weights.bin", "non-zero inter-object padding");
        }
        cursor = std::max(cursor, end);
    }
    if (std::any_of(
            weights.begin() + static_cast<std::ptrdiff_t>(cursor),
            weights.end(),
            [](std::uint8_t byte) { return byte != 0U; })) {
        return fail(
            diagnostic, npu_compiled_bundle_error::weight_padding,
            "$weights.bin", "non-zero trailing padding");
    }
    return true;
}

bool validate_descriptor_relocations(
        const std::vector<std::uint8_t> & command_bytes,
        const std::vector<npu_compiled_buffer_info> & buffers,
        const std::map<std::string, std::size_t> & buffer_by_id,
        const std::vector<npu_compiled_command_info> & commands,
        const std::vector<npu_compiled_relocation_info> & relocations,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::vector<std::array<std::size_t, NPU_COMMAND_ABI_WORD_COUNT>> by_word(
        commands.size());
    for (auto & table : by_word) {
        table.fill(kNoIndex);
    }
    for (std::size_t index = 0; index < relocations.size(); ++index) {
        const npu_compiled_relocation_info & relocation = relocations[index];
        by_word[relocation.command_index][relocation.word_index] = index;
    }
    for (std::size_t command_index = 0;
         command_index < commands.size(); ++command_index) {
        const std::size_t record_offset =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            command_index * NPU_COMPILED_COMMAND_RECORD_BYTES;
        const std::uint8_t * record = command_bytes.data() + record_offset;
        npu_command_abi_diagnostic abi_diagnostic = {};
        if (!npu_command_abi_validate_le(
                record, NPU_COMPILED_COMMAND_RECORD_BYTES,
                &abi_diagnostic)) {
            return fail(
                diagnostic, npu_compiled_bundle_error::command_abi,
                indexed_path("$metadata.commands", command_index),
                npu_command_abi_error_string(abi_diagnostic.error),
                command_index, kNoIndex, &abi_diagnostic);
        }
        for (std::uint32_t word : kRelocatableWords) {
            const std::size_t relocation_index = by_word[command_index][word];
            const std::uint64_t value = load_le64(record + word * 8U);
            if (relocation_index == kNoIndex) {
                if (value != 0U) {
                    return fail(
                        diagnostic,
                        npu_compiled_bundle_error::relocation_pair,
                        indexed_path("$metadata.commands", command_index),
                        "non-zero address word lacks relocation",
                        command_index);
                }
                continue;
            }
            if (value != relocations[relocation_index].addend) {
                return fail(
                    diagnostic,
                    npu_compiled_bundle_error::relocation_template,
                    indexed_path("$metadata.relocations", relocation_index),
                    "template word does not equal relocation addend",
                    command_index, relocation_index);
            }
        }
        for (std::size_t pair_index = 0;
             pair_index < kWindowPairs.size(); ++pair_index) {
            const window_pair & pair = kWindowPairs[pair_index];
            const std::size_t address_index =
                by_word[command_index][pair.address_word];
            const std::size_t base_index =
                by_word[command_index][pair.base_word];
            if ((address_index == kNoIndex) != (base_index == kNoIndex)) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::relocation_pair,
                    indexed_path("$metadata.commands", command_index),
                    "address and window-base relocations must be paired",
                    command_index,
                    address_index == kNoIndex ? base_index : address_index);
            }
            if (address_index == kNoIndex) {
                continue;
            }
            const npu_compiled_relocation_info & address =
                relocations[address_index];
            const npu_compiled_relocation_info & base =
                relocations[base_index];
            if (address.buffer_id != base.buffer_id) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::relocation_pair,
                    indexed_path("$metadata.commands", command_index),
                    "address and window base bind different buffers",
                    command_index, address_index);
            }
            const npu_compiled_buffer_info & buffer =
                buffers.at(buffer_by_id.at(base.buffer_id));
            const std::uint64_t window_size =
                load_le64(record + pair.size_word * 8U);
            if (window_size == 0U ||
                base.addend > buffer.size ||
                window_size > buffer.size - base.addend ||
                address.addend < base.addend ||
                address.addend - base.addend >= window_size) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::relocation_range,
                    indexed_path("$metadata.commands", command_index),
                    "compiled address/window lies outside BufferId",
                    command_index, address_index);
            }
        }
        const std::size_t src2_index = by_word[command_index][12U];
        if (src2_index != kNoIndex) {
            const npu_compiled_relocation_info & src2 = relocations[src2_index];
            bool aliases_window = false;
            for (const window_pair & pair : kWindowPairs) {
                const std::size_t primary_index =
                    by_word[command_index][pair.address_word];
                const std::size_t base_index =
                    by_word[command_index][pair.base_word];
                if (primary_index == kNoIndex || base_index == kNoIndex ||
                    relocations[primary_index].buffer_id != src2.buffer_id) {
                    continue;
                }
                const std::uint64_t start = relocations[base_index].addend;
                const std::uint64_t size =
                    load_le64(record + pair.size_word * 8U);
                if (src2.addend >= start &&
                    src2.addend - start < size) {
                    aliases_window = true;
                    break;
                }
            }
            if (!aliases_window) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::relocation_src2,
                    indexed_path("$metadata.relocations", src2_index),
                    "src2 does not alias a declared window",
                    command_index, src2_index);
            }
        }
    }
    return true;
}

bool validate_publication_producers(
        const std::vector<std::uint8_t> & command_bytes,
        const std::vector<npu_compiled_buffer_info> & buffers,
        const std::vector<npu_compiled_relocation_info> & relocations,
        const std::vector<npu_compiled_publication_entry> & publications,
        npu_compiled_bundle_diagnostic * diagnostic) {
    using relative_interval = std::pair<std::uint64_t, std::uint64_t>;
    std::map<std::string, std::vector<relative_interval>> produced;
    for (std::size_t address_index = 0U;
         address_index < relocations.size(); ++address_index) {
        const npu_compiled_relocation_info & address =
            relocations[address_index];
        if (address.word_index != 13U) {
            continue;
        }

        const auto window = std::find_if(
            relocations.begin(), relocations.end(),
            [&address](const npu_compiled_relocation_info & relocation) {
                return relocation.command_index == address.command_index &&
                    relocation.word_index == 28U;
            });
        if (window == relocations.end() ||
            window->buffer_id != address.buffer_id) {
            continue;
        }
        const auto buffer = std::find_if(
            buffers.begin(), buffers.end(),
            [&address](const npu_compiled_buffer_info & item) {
                return item.id == address.buffer_id;
            });
        const std::size_t record_offset =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            static_cast<std::size_t>(address.command_index) *
                NPU_COMPILED_COMMAND_RECORD_BYTES;
        if (buffer == buffers.end() ||
            record_offset > command_bytes.size() ||
            NPU_COMPILED_COMMAND_RECORD_BYTES >
                command_bytes.size() - record_offset) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::publication_producer,
                indexed_path("$metadata.relocations", address_index),
                "destination producer does not resolve to one command/buffer",
                address.command_index, address_index);
        }
        const std::uint64_t window_size = load_le64(
            command_bytes.data() + record_offset + 29U * 8U);
        std::uint64_t window_end = 0U;
        if (window_size == 0U ||
            !checked_add(window->addend, window_size, &window_end) ||
            window_end > buffer->size ||
            address.addend < window->addend ||
            address.addend >= window_end) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::publication_producer,
                indexed_path("$metadata.relocations", address_index),
                "destination write window is invalid or excludes dst IOVA",
                address.command_index, address_index);
        }
        if (buffer->kind == npu_compiled_buffer_kind::output) {
            produced[buffer->id].push_back({
                window->addend, window_end,
            });
        }
    }
    for (std::size_t index = 0U; index < buffers.size(); ++index) {
        const npu_compiled_buffer_info & buffer = buffers[index];
        if (buffer.kind == npu_compiled_buffer_kind::output &&
            produced.count(buffer.id) == 0U) {
            return fail(
                diagnostic, npu_compiled_bundle_error::publication_producer,
                indexed_path("$metadata.buffers", index),
                "published output has no paired destination IOVA/window "
                "relocation producer");
        }
    }

    for (auto & item : produced) {
        std::vector<relative_interval> & ranges = item.second;
        std::sort(ranges.begin(), ranges.end());
        std::vector<relative_interval> merged;
        merged.reserve(ranges.size());
        for (const relative_interval & range : ranges) {
            if (!merged.empty() && range.first <= merged.back().second) {
                merged.back().second = std::max(
                    merged.back().second, range.second);
            } else {
                merged.push_back(range);
            }
        }
        ranges.swap(merged);
    }

    for (std::size_t index = 0U; index < publications.size(); ++index) {
        const npu_compiled_publication_entry & publication =
            publications[index];
        std::uint64_t publication_end = 0U;
        if (!checked_add(
                publication.source_offset,
                publication.bytes,
                &publication_end)) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::publication_unwritten_source,
                indexed_path("$metadata.publication.entries", index),
                "publication source range overflows u64");
        }
        std::uint64_t cursor = publication.source_offset;
        const auto found = produced.find(publication.buffer_id);
        if (found != produced.end()) {
            for (const relative_interval & range : found->second) {
                if (range.second <= cursor) {
                    continue;
                }
                if (range.first > cursor) {
                    break;
                }
                cursor = std::min(
                    publication_end,
                    std::max(cursor, range.second));
                if (cursor == publication_end) {
                    break;
                }
            }
        }
        if (cursor != publication_end) {
            std::ostringstream detail;
            detail << "publication source range ["
                   << publication.source_offset << ',' << publication_end
                   << ") contains unwritten bytes starting at " << cursor;
            return fail(
                diagnostic,
                npu_compiled_bundle_error::publication_unwritten_source,
                indexed_path("$metadata.publication.entries", index),
                detail.str());
        }
    }
    return true;
}

bool validate_transient_dataflow(
        const std::vector<std::uint8_t> & command_bytes,
        const std::vector<npu_compiled_buffer_info> & buffers,
        const std::map<std::string, std::size_t> & buffer_by_id,
        const std::vector<npu_compiled_command_info> & commands,
        const std::vector<npu_compiled_relocation_info> & relocations,
        npu_compiled_bundle_diagnostic * diagnostic) {
    using relative_interval = std::pair<std::uint64_t, std::uint64_t>;
    std::vector<std::array<std::size_t, NPU_COMMAND_ABI_WORD_COUNT>> by_word(
        commands.size());
    for (auto & table : by_word) {
        table.fill(kNoIndex);
    }
    for (std::size_t index = 0U; index < relocations.size(); ++index) {
        const npu_compiled_relocation_info & relocation = relocations[index];
        by_word[relocation.command_index][relocation.word_index] = index;
    }

    std::map<std::string, std::vector<relative_interval>> prior_writes;
    const auto require_prior_write = [
            &prior_writes, &buffers, &buffer_by_id, diagnostic](
                const std::string & identifier,
                std::uint64_t begin,
                std::uint64_t end,
                std::size_t command_index,
                std::size_t relocation_index) {
        const auto buffer_iterator = buffer_by_id.find(identifier);
        if (buffer_iterator == buffer_by_id.end() ||
            buffers[buffer_iterator->second].kind !=
                npu_compiled_buffer_kind::transient) {
            return true;
        }
        std::vector<relative_interval> available =
            prior_writes[identifier];
        std::sort(available.begin(), available.end());
        std::uint64_t cursor = begin;
        for (const relative_interval & interval : available) {
            if (interval.second <= cursor) {
                continue;
            }
            if (interval.first > cursor) {
                break;
            }
            cursor = std::min(end, std::max(cursor, interval.second));
            if (cursor == end) {
                return true;
            }
        }
        std::ostringstream detail;
        detail << "transient " << identifier << " read range ["
               << begin << ',' << end
               << ") is not fully written by strictly earlier "
                  "destination windows; first unwritten byte is "
               << cursor;
        return fail(
            diagnostic,
            npu_compiled_bundle_error::transient_read_before_write,
            indexed_path("$metadata.relocations", relocation_index),
            detail.str(), command_index, relocation_index);
    };
    for (std::size_t command_index = 0U;
         command_index < commands.size(); ++command_index) {
        const std::size_t record_offset =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            command_index * NPU_COMPILED_COMMAND_RECORD_BYTES;
        const std::uint8_t * record = command_bytes.data() + record_offset;

        for (std::size_t pair_index = 0U; pair_index < 2U; ++pair_index) {
            const window_pair & pair = kWindowPairs[pair_index];
            const std::size_t address_index =
                by_word[command_index][pair.address_word];
            const std::size_t base_index =
                by_word[command_index][pair.base_word];
            if (address_index == kNoIndex || base_index == kNoIndex) {
                continue;
            }
            const npu_compiled_relocation_info & address =
                relocations[address_index];
            const auto buffer_iterator = buffer_by_id.find(address.buffer_id);
            if (buffer_iterator == buffer_by_id.end() ||
                buffers[buffer_iterator->second].kind !=
                    npu_compiled_buffer_kind::transient) {
                continue;
            }

            const npu_compiled_relocation_info & base =
                relocations[base_index];
            const std::uint64_t read_size =
                load_le64(record + pair.size_word * 8U);
            std::uint64_t read_end = 0U;
            if (read_size == 0U ||
                !checked_add(base.addend, read_size, &read_end) ||
                read_end > buffers[buffer_iterator->second].size) {
                return fail(
                    diagnostic,
                    npu_compiled_bundle_error::transient_read_before_write,
                    indexed_path("$metadata.relocations", base_index),
                    "transient read window is invalid",
                    command_index, base_index);
            }

            if (!require_prior_write(
                    address.buffer_id, base.addend, read_end,
                    command_index, address_index)) {
                return false;
            }
        }

        const std::size_t src2_index = by_word[command_index][12U];
        if (src2_index != kNoIndex) {
            const npu_compiled_relocation_info & src2 =
                relocations[src2_index];
            bool found_alias = false;
            for (const window_pair & pair : kWindowPairs) {
                const std::size_t address_index =
                    by_word[command_index][pair.address_word];
                const std::size_t base_index =
                    by_word[command_index][pair.base_word];
                if (address_index == kNoIndex || base_index == kNoIndex ||
                    relocations[address_index].buffer_id != src2.buffer_id) {
                    continue;
                }
                const npu_compiled_relocation_info & base =
                    relocations[base_index];
                const std::uint64_t window_size =
                    load_le64(record + pair.size_word * 8U);
                std::uint64_t window_end = 0U;
                if (window_size == 0U ||
                    !checked_add(base.addend, window_size, &window_end)) {
                    return fail(
                        diagnostic,
                        npu_compiled_bundle_error::transient_read_before_write,
                        indexed_path("$metadata.relocations", base_index),
                        "src2 alias window is empty or overflows u64",
                        command_index, base_index);
                }
                if (src2.addend < base.addend ||
                    src2.addend >= window_end) {
                    continue;
                }
                found_alias = true;
                if (!require_prior_write(
                        src2.buffer_id, base.addend, window_end,
                        command_index, src2_index)) {
                    return false;
                }
            }
            if (!found_alias) {
                return fail(
                    diagnostic,
                    npu_compiled_bundle_error::relocation_src2,
                    indexed_path("$metadata.relocations", src2_index),
                    "src2 does not alias a declared window",
                    command_index, src2_index);
            }
        }

        const window_pair & destination = kWindowPairs[2U];
        const std::size_t address_index =
            by_word[command_index][destination.address_word];
        const std::size_t base_index =
            by_word[command_index][destination.base_word];
        if (address_index == kNoIndex || base_index == kNoIndex) {
            continue;
        }
        const npu_compiled_relocation_info & address =
            relocations[address_index];
        const auto buffer_iterator = buffer_by_id.find(address.buffer_id);
        if (buffer_iterator == buffer_by_id.end() ||
            buffers[buffer_iterator->second].kind !=
                npu_compiled_buffer_kind::transient) {
            continue;
        }
        const npu_compiled_relocation_info & base = relocations[base_index];
        const std::uint64_t write_size =
            load_le64(record + destination.size_word * 8U);
        std::uint64_t write_end = 0U;
        if (write_size == 0U ||
            !checked_add(base.addend, write_size, &write_end) ||
            write_end > buffers[buffer_iterator->second].size) {
            return fail(
                diagnostic,
                npu_compiled_bundle_error::transient_read_before_write,
                indexed_path("$metadata.relocations", base_index),
                "transient destination write window is invalid",
                command_index, base_index);
        }
        prior_writes[address.buffer_id].push_back({base.addend, write_end});
    }
    return true;
}

bool parse_and_validate_bundle(
        const std::vector<std::uint8_t> & command_bytes,
        const std::vector<std::uint8_t> & weights,
        const std::vector<std::uint8_t> & metadata_bytes,
        npu_compiled_bundle * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    std::uint32_t command_count = 0U;
    if (!validate_command_file(command_bytes, &command_count, diagnostic)) {
        return false;
    }
    json root;
    if (!parse_canonical_metadata(metadata_bytes, &root, diagnostic) ||
        !exact_keys(
            root,
            {"schema", "bundle_id", "abi", "artifacts", "buffers",
             "commands", "graph", "publication", "provenance",
             "relocations", "runtime"},
            "$metadata", diagnostic)) {
        return false;
    }
    std::string schema;
    if (!json_string(root.at("schema"), "$metadata.schema", &schema, diagnostic) ||
        schema != kMetadataSchema) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_schema,
            "$metadata.schema", "expected npu-artifact-bundle-v3");
    }
    if (!parse_abi(root.at("abi"), diagnostic)) {
        return false;
    }
    if (!exact_keys(
            root.at("artifacts"), {"command.bin", "weights.bin"},
            "$metadata.artifacts", diagnostic)) {
        return false;
    }
    std::uint64_t command_size = 0U;
    std::uint64_t weights_size = 0U;
    std::array<std::uint8_t, kSha256Bytes> expected_command_hash = {};
    std::array<std::uint8_t, kSha256Bytes> expected_weights_hash = {};
    if (!parse_artifact_entry(
            root.at("artifacts").at("command.bin"),
            "$metadata.artifacts.command.bin", &command_size,
            &expected_command_hash, diagnostic) ||
        !parse_artifact_entry(
            root.at("artifacts").at("weights.bin"),
            "$metadata.artifacts.weights.bin", &weights_size,
            &expected_weights_hash, diagnostic)) {
        return false;
    }
    if (command_size != command_bytes.size() ||
        weights_size != weights.size()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::artifact_size,
            "$metadata.artifacts", "artifact size does not match metadata");
    }
    if (sha256(command_bytes) != expected_command_hash ||
        sha256(weights) != expected_weights_hash) {
        return fail(
            diagnostic, npu_compiled_bundle_error::artifact_hash,
            "$metadata.artifacts", "whole-file SHA-256 mismatch");
    }
    if (!exact_keys(
            root.at("graph"), {"name", "source_schema"},
            "$metadata.graph", diagnostic)) {
        return false;
    }
    std::string graph_name;
    std::string source_schema;
    if (!json_string(
            root.at("graph").at("name"), "$metadata.graph.name",
            &graph_name, diagnostic) ||
        !json_string(
            root.at("graph").at("source_schema"),
            "$metadata.graph.source_schema", &source_schema, diagnostic)) {
        return false;
    }
    if (source_schema != kGraphSchema) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_schema,
            "$metadata.graph.source_schema",
            "expected npu-compiler-graph-v3");
    }

    std::array<std::uint8_t, kSha256Bytes> parsed_bundle_hash = {};
    if (!parse_hash(
            root.at("bundle_id"), "$metadata.bundle_id",
            &parsed_bundle_hash, diagnostic)) {
        return false;
    }
    json core = root;
    core.erase("bundle_id");
    const std::string core_canonical = core.dump(
        -1, ' ', false, json::error_handler_t::strict);
    if (sha256(core_canonical) != parsed_bundle_hash) {
        return fail(
            diagnostic, npu_compiled_bundle_error::bundle_id,
            "$metadata.bundle_id", "bundle_id does not match canonical metadata core");
    }

    npu_compiled_bundle candidate;
    candidate.command_template = command_bytes;
    candidate.weights = weights;
    candidate.metadata_json = metadata_bytes;
    candidate.graph_name = std::move(graph_name);
    candidate.bundle_id = root.at("bundle_id").get<std::string>();
    std::map<std::string, std::size_t> buffer_by_id;
    if (!parse_runtime_service(
            root.at("runtime"), &candidate.runtime_service, diagnostic) ||
        !parse_buffers(
            root.at("buffers"), &candidate.buffers,
            &buffer_by_id, diagnostic) ||
        !parse_publication(
            root.at("publication"), buffer_by_id, candidate.buffers,
            &candidate.publication_mode, &candidate.publications,
            diagnostic) ||
        !validate_weight_image(weights, candidate.buffers, diagnostic) ||
        !parse_commands(
            root.at("commands"), command_count, command_bytes,
            &candidate.commands, diagnostic) ||
        !parse_provenance(
            root.at("provenance"), candidate.buffers, buffer_by_id,
            candidate.commands, &candidate.provenance_source,
            &candidate.provenance_nodes, &candidate.provenance_buffers,
            diagnostic) ||
        !parse_relocations(
            root.at("relocations"), buffer_by_id, candidate.buffers,
            candidate.commands.size(), &candidate.relocations, diagnostic) ||
        !validate_descriptor_relocations(
            command_bytes, candidate.buffers, buffer_by_id,
            candidate.commands, candidate.relocations, diagnostic) ||
        !validate_transient_dataflow(
            command_bytes, candidate.buffers, buffer_by_id,
            candidate.commands, candidate.relocations, diagnostic) ||
        !validate_publication_producers(
            command_bytes, candidate.buffers, candidate.relocations,
            candidate.publications, diagnostic)) {
        return false;
    }
    *output = std::move(candidate);
    return true;
}

struct bound_interval {
    std::uint64_t begin;
    std::uint64_t end;
    std::size_t buffer_index;
};

bool exact_weight_alias(
        const bound_interval & lhs,
        const bound_interval & rhs,
        const std::vector<npu_compiled_buffer_info> & buffers) {
    const npu_compiled_buffer_info & left = buffers[lhs.buffer_index];
    const npu_compiled_buffer_info & right = buffers[rhs.buffer_index];
    return lhs.begin == rhs.begin && lhs.end == rhs.end &&
           left.kind == npu_compiled_buffer_kind::weight &&
           right.kind == npu_compiled_buffer_kind::weight &&
           left.weights_offset == right.weights_offset &&
           left.sha256 == right.sha256;
}

}  // namespace

std::array<std::uint8_t, 32> npu_compiled_sha256(const void * data, std::size_t size) {
    return sha256(static_cast<const std::uint8_t *>(data), size);
}


bool npu_compiled_bundle_load(
        const std::string & directory,
        npu_compiled_bundle * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (output == nullptr || directory.empty()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::null_argument,
            "$bundle", "directory and output are required");
    }
    try {
        const std::filesystem::path root(directory);
        std::vector<std::uint8_t> command;
        std::vector<std::uint8_t> weights;
        std::vector<std::uint8_t> metadata;
        if (!read_file(root / "command.bin", &command, diagnostic) ||
            !read_file(root / "weights.bin", &weights, diagnostic) ||
            !read_file(root / "metadata.json", &metadata, diagnostic)) {
            return false;
        }
        npu_compiled_bundle candidate;
        if (!parse_and_validate_bundle(
                command, weights, metadata, &candidate, diagnostic)) {
            return false;
        }
        *output = std::move(candidate);
        clear_diagnostic(diagnostic);
        return true;
    } catch (const std::bad_alloc &) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bundle", "allocation failure");
    } catch (const std::length_error & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bundle", exception.what());
    } catch (const json::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", exception.what());
    } catch (const std::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::file_read,
            "$bundle", exception.what());
    }
}

bool npu_compiled_bundle_revalidate(
        const npu_compiled_bundle * input,
        npu_compiled_bundle * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (input == nullptr || output == nullptr) {
        return fail(
            diagnostic, npu_compiled_bundle_error::null_argument,
            "$bundle", "input and canonical output are required");
    }
    try {
        npu_compiled_bundle candidate;
        if (!parse_and_validate_bundle(
                input->command_template, input->weights,
                input->metadata_json, &candidate, diagnostic)) {
            return false;
        }
        *output = std::move(candidate);
        clear_diagnostic(diagnostic);
        return true;
    } catch (const std::bad_alloc &) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bundle", "allocation failure");
    } catch (const std::length_error & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bundle", exception.what());
    } catch (const json::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", exception.what());
    } catch (const std::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_value,
            "$bundle", exception.what());
    }
}

bool npu_compiled_bundle_relocate(
        const npu_compiled_bundle * bundle,
        const npu_compiled_named_binding * bindings,
        std::size_t binding_count,
        std::vector<std::uint8_t> * output,
        npu_compiled_bundle_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (bundle == nullptr || output == nullptr ||
        (binding_count != 0U && bindings == nullptr)) {
        return fail(
            diagnostic, npu_compiled_bundle_error::null_argument,
            "$bindings", "bundle, bindings, and output must be valid");
    }
    if (binding_count > std::numeric_limits<std::uint32_t>::max()) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_range,
            "$bindings", "too many bindings");
    }
    try {
        // Do not trust a mutable public struct.  Re-parse the immutable bytes
        // and close their hashes immediately before any runtime capability is
        // considered.
        npu_compiled_bundle validated;
        if (!npu_compiled_bundle_revalidate(
                bundle, &validated, diagnostic)) {
            return false;
        }
        std::map<std::string, std::size_t> buffer_by_id;
        for (std::size_t index = 0; index < validated.buffers.size(); ++index) {
            buffer_by_id.emplace(validated.buffers[index].id, index);
        }
        std::set<std::string> required_ids;
        for (const npu_compiled_relocation_info & relocation :
             validated.relocations) {
            required_ids.insert(relocation.buffer_id);
        }

        std::map<std::string, std::uint32_t> binding_by_id;
        std::vector<npu_command_abi_buffer_binding> abi_bindings;
        abi_bindings.reserve(binding_count);
        std::vector<bound_interval> intervals;
        for (std::size_t index = 0; index < binding_count; ++index) {
            const npu_compiled_named_binding & binding = bindings[index];
            const auto buffer_iterator = buffer_by_id.find(binding.buffer_id);
            if (buffer_iterator == buffer_by_id.end()) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_unknown,
                    "$bindings[" + std::to_string(index) + "].buffer_id",
                    "binding names an unknown BufferId");
            }
            if (!binding_by_id.emplace(
                    binding.buffer_id,
                    static_cast<std::uint32_t>(index)).second) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_duplicate,
                    "$bindings[" + std::to_string(index) + "].buffer_id",
                    "duplicate BufferId binding");
            }
            const npu_compiled_buffer_info & buffer =
                validated.buffers[buffer_iterator->second];
            if (binding.size != buffer.size) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_size,
                    "$bindings[" + std::to_string(index) + "].size",
                    "binding size must exactly match metadata");
            }
            if (binding.permissions != buffer.permissions) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_permission,
                    "$bindings[" + std::to_string(index) + "].permissions",
                    "binding permissions must exactly match metadata");
            }
            if (binding.base % buffer.alignment != 0U) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_alignment,
                    "$bindings[" + std::to_string(index) + "].base",
                    "binding base violates metadata alignment");
            }
            std::uint64_t end = 0U;
            if (!checked_add(binding.base, binding.size, &end)) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_overflow,
                    "$bindings[" + std::to_string(index) + "].base",
                    "base + size overflows u64");
            }
            abi_bindings.push_back({
                binding.base, binding.size, binding.permissions,
            });
            if (required_ids.count(binding.buffer_id) != 0U) {
                intervals.push_back({
                    binding.base, end, buffer_iterator->second,
                });
            }
        }
        for (const std::string & required : required_ids) {
            if (binding_by_id.count(required) == 0U) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_missing,
                    "$bindings", "missing required BufferId " + required);
            }
        }
        std::sort(
            intervals.begin(), intervals.end(),
            [&validated](const bound_interval & lhs,
                         const bound_interval & rhs) {
                if (lhs.begin != rhs.begin) {
                    return lhs.begin < rhs.begin;
                }
                if (lhs.end != rhs.end) {
                    return lhs.end < rhs.end;
                }
                return validated.buffers[lhs.buffer_index].id <
                       validated.buffers[rhs.buffer_index].id;
            });
        for (std::size_t index = 1U; index < intervals.size(); ++index) {
            const bound_interval & previous = intervals[index - 1U];
            const bound_interval & current = intervals[index];
            if (current.begin < previous.end &&
                !exact_weight_alias(
                    previous, current, validated.buffers)) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::binding_overlap,
                    "$bindings", "runtime buffer capabilities overlap");
            }
        }

        std::vector<std::vector<npu_command_abi_relocation>> command_relocations(
            validated.commands.size());
        for (const npu_compiled_relocation_info & relocation :
             validated.relocations) {
            command_relocations[relocation.command_index].push_back({
                relocation.word_index,
                binding_by_id.at(relocation.buffer_id),
                relocation.addend,
            });
        }
        std::vector<std::uint8_t> candidate = validated.command_template;
        for (std::size_t command_index = 0;
             command_index < validated.commands.size(); ++command_index) {
            const std::size_t offset =
                NPU_COMPILED_COMMAND_HEADER_BYTES +
                command_index * NPU_COMPILED_COMMAND_RECORD_BYTES;
            std::vector<std::uint8_t> record(
                candidate.begin() + static_cast<std::ptrdiff_t>(offset),
                candidate.begin() + static_cast<std::ptrdiff_t>(
                    offset + NPU_COMPILED_COMMAND_RECORD_BYTES));
            std::vector<std::uint8_t> relocated_record;
            const std::vector<npu_command_abi_relocation> & relocations =
                command_relocations[command_index];
            npu_command_abi_diagnostic abi_diagnostic = {};
            if (!npu_command_abi_relocate_private_shadow(
                    record.data(), record.size(), 0U,
                    relocations.empty() ? nullptr : relocations.data(),
                    relocations.size(),
                    abi_bindings.empty() ? nullptr : abi_bindings.data(),
                    abi_bindings.size(), &relocated_record,
                    &abi_diagnostic)) {
                return fail(
                    diagnostic, npu_compiled_bundle_error::command_abi,
                    indexed_path("$metadata.commands", command_index),
                    npu_command_abi_error_string(abi_diagnostic.error),
                    command_index, abi_diagnostic.relocation_index,
                    &abi_diagnostic);
            }
            std::copy(
                relocated_record.begin(), relocated_record.end(),
                candidate.begin() + static_cast<std::ptrdiff_t>(offset));
        }
        const auto payload_hash = sha256(
            candidate.data() + NPU_COMPILED_COMMAND_HEADER_BYTES,
            candidate.size() - NPU_COMPILED_COMMAND_HEADER_BYTES);
        std::copy(
            payload_hash.begin(), payload_hash.end(),
            candidate.begin() +
                static_cast<std::ptrdiff_t>(kCommandPayloadHashOffset));
        std::uint32_t relocated_count = 0U;
        if (!validate_command_file(
                candidate, &relocated_count, diagnostic) ||
            relocated_count != validated.commands.size()) {
            return false;
        }
        output->swap(candidate);
        clear_diagnostic(diagnostic);
        return true;
    } catch (const std::bad_alloc &) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bindings", "allocation failure");
    } catch (const std::length_error & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::allocation_failure,
            "$bindings", exception.what());
    } catch (const json::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::json_parse,
            "$metadata.json", exception.what());
    } catch (const std::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_value,
            "$bundle", exception.what());
    }
}

bool npu_compiled_bundle_decode_record(
        const std::vector<std::uint8_t> & command_image,
        std::size_t command_index,
        npu_command_abi_words * words,
        npu_compiled_bundle_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (words == nullptr) {
        return fail(
            diagnostic, npu_compiled_bundle_error::null_argument,
            "$command.bin", "output words are required");
    }
    try {
        std::uint32_t command_count = 0U;
        if (!validate_command_file(
                command_image, &command_count, diagnostic)) {
            return false;
        }
        if (command_index >= command_count) {
            return fail(
                diagnostic, npu_compiled_bundle_error::relocation_command,
                "$command.bin.command_index", "outside command table",
                command_index);
        }
        const std::size_t offset =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            command_index * NPU_COMPILED_COMMAND_RECORD_BYTES;
        npu_command_abi_words candidate = {};
        for (std::size_t word = 0; word < candidate.size(); ++word) {
            candidate[word] = load_le64(
                command_image.data() + offset + word * 8U);
        }
        *words = candidate;
        clear_diagnostic(diagnostic);
        return true;
    } catch (const std::exception & exception) {
        return fail(
            diagnostic, npu_compiled_bundle_error::metadata_value,
            "$command.bin", exception.what());
    }
}

const char * npu_compiled_bundle_error_string(
        npu_compiled_bundle_error error) {
    switch (error) {
        case npu_compiled_bundle_error::none: return "none";
        case npu_compiled_bundle_error::null_argument: return "null argument";
        case npu_compiled_bundle_error::file_open: return "file open failure";
        case npu_compiled_bundle_error::file_size: return "invalid file size";
        case npu_compiled_bundle_error::file_read: return "file read failure";
        case npu_compiled_bundle_error::allocation_failure: return "allocation failure";
        case npu_compiled_bundle_error::command_magic: return "invalid command magic";
        case npu_compiled_bundle_error::command_version: return "unsupported command version";
        case npu_compiled_bundle_error::command_header_size: return "invalid command header size";
        case npu_compiled_bundle_error::command_record_size: return "invalid command record size";
        case npu_compiled_bundle_error::command_flags: return "invalid command flags";
        case npu_compiled_bundle_error::command_size: return "invalid command size";
        case npu_compiled_bundle_error::command_payload_hash: return "command payload hash mismatch";
        case npu_compiled_bundle_error::json_parse: return "JSON parse failure";
        case npu_compiled_bundle_error::json_duplicate_key: return "duplicate JSON key";
        case npu_compiled_bundle_error::metadata_noncanonical: return "noncanonical metadata";
        case npu_compiled_bundle_error::metadata_schema: return "metadata schema mismatch";
        case npu_compiled_bundle_error::metadata_keys: return "metadata object keys mismatch";
        case npu_compiled_bundle_error::metadata_type: return "metadata type mismatch";
        case npu_compiled_bundle_error::metadata_range: return "metadata integer out of range";
        case npu_compiled_bundle_error::metadata_value: return "invalid metadata value";
        case npu_compiled_bundle_error::metadata_hash: return "invalid metadata hash";
        case npu_compiled_bundle_error::bundle_id: return "bundle id mismatch";
        case npu_compiled_bundle_error::artifact_size: return "artifact size mismatch";
        case npu_compiled_bundle_error::artifact_hash: return "artifact hash mismatch";
        case npu_compiled_bundle_error::buffer_duplicate: return "duplicate buffer";
        case npu_compiled_bundle_error::buffer_order: return "buffer order mismatch";
        case npu_compiled_bundle_error::buffer_kind: return "invalid buffer kind";
        case npu_compiled_bundle_error::buffer_alignment: return "invalid buffer alignment";
        case npu_compiled_bundle_error::buffer_permission: return "invalid buffer permission";
        case npu_compiled_bundle_error::buffer_range: return "buffer range mismatch";
        case npu_compiled_bundle_error::buffer_overlap: return "buffer overlap";
        case npu_compiled_bundle_error::weight_hash: return "weight hash mismatch";
        case npu_compiled_bundle_error::weight_padding: return "nonzero weight padding";
        case npu_compiled_bundle_error::command_count: return "command count mismatch";
        case npu_compiled_bundle_error::command_order: return "command order mismatch";
        case npu_compiled_bundle_error::command_duplicate: return "duplicate command";
        case npu_compiled_bundle_error::descriptor_hash: return "descriptor hash mismatch";
        case npu_compiled_bundle_error::kernel_id: return "kernel id mismatch";
        case npu_compiled_bundle_error::command_owner: return "unsupported command owner";
        case npu_compiled_bundle_error::command_identity: return "command identity mismatch";
        case npu_compiled_bundle_error::command_workload: return "invalid command workload";
        case npu_compiled_bundle_error::node_hash: return "node hash mismatch";
        case npu_compiled_bundle_error::node_count: return "node count mismatch";
        case npu_compiled_bundle_error::runtime_abi: return "runtime service ABI mismatch";
        case npu_compiled_bundle_error::publication_mode: return "invalid publication mode";
        case npu_compiled_bundle_error::publication_order: return "publication order mismatch";
        case npu_compiled_bundle_error::publication_duplicate: return "duplicate publication";
        case npu_compiled_bundle_error::publication_buffer: return "invalid publication buffer";
        case npu_compiled_bundle_error::publication_permission: return "invalid publication permission";
        case npu_compiled_bundle_error::publication_range: return "publication range mismatch";
        case npu_compiled_bundle_error::publication_coverage: return "publication coverage mismatch";
        case npu_compiled_bundle_error::publication_producer: return "publication producer mismatch";
        case npu_compiled_bundle_error::publication_unwritten_source: return "publication source contains unwritten bytes";
        case npu_compiled_bundle_error::relocation_order: return "relocation order mismatch";
        case npu_compiled_bundle_error::relocation_duplicate: return "duplicate relocation";
        case npu_compiled_bundle_error::relocation_command: return "relocation command out of range";
        case npu_compiled_bundle_error::relocation_word: return "invalid relocation word";
        case npu_compiled_bundle_error::relocation_kind: return "invalid relocation kind";
        case npu_compiled_bundle_error::relocation_buffer: return "unknown relocation buffer";
        case npu_compiled_bundle_error::relocation_range: return "relocation range mismatch";
        case npu_compiled_bundle_error::relocation_template: return "relocation template mismatch";
        case npu_compiled_bundle_error::relocation_pair: return "relocation pair mismatch";
        case npu_compiled_bundle_error::relocation_src2: return "src2 relocation mismatch";
        case npu_compiled_bundle_error::binding_unknown: return "unknown binding";
        case npu_compiled_bundle_error::binding_duplicate: return "duplicate binding";
        case npu_compiled_bundle_error::binding_missing: return "missing binding";
        case npu_compiled_bundle_error::binding_size: return "binding size mismatch";
        case npu_compiled_bundle_error::binding_alignment: return "binding alignment mismatch";
        case npu_compiled_bundle_error::binding_permission: return "binding permission mismatch";
        case npu_compiled_bundle_error::binding_overflow: return "binding address overflow";
        case npu_compiled_bundle_error::binding_overlap: return "binding overlap";
        case npu_compiled_bundle_error::command_abi: return "command ABI rejection";
        case npu_compiled_bundle_error::transient_read_before_write: return "transient read precedes complete write";
        case npu_compiled_bundle_error::provenance_format: return "invalid provenance format";
        case npu_compiled_bundle_error::provenance_node_duplicate: return "duplicate provenance node identity";
        case npu_compiled_bundle_error::provenance_node_order: return "provenance node order mismatch";
        case npu_compiled_bundle_error::provenance_node_coverage: return "provenance node coverage mismatch";
        case npu_compiled_bundle_error::provenance_node_descriptor: return "provenance command descriptor mismatch";
        case npu_compiled_bundle_error::provenance_buffer_duplicate: return "duplicate provenance buffer identity";
        case npu_compiled_bundle_error::provenance_buffer_order: return "provenance buffer order mismatch";
        case npu_compiled_bundle_error::provenance_buffer_coverage: return "provenance buffer coverage mismatch";
        case npu_compiled_bundle_error::provenance_buffer_range: return "provenance buffer range mismatch";
    }
    return "unknown compiled bundle error";
}
