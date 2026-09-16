#include "npu-compiled-bundle.h"
#include "npu-system-session.h"
#include "npu_service_mailbox_abi.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <string>
#include <utility>
#include <vector>

namespace {

// Raw IEEE-754 payloads only: all arithmetic is performed by RTL.
constexpr std::array<std::uint32_t, 16> kInput0 = {
    0x3f800000U, 0xbf800000U, 0x40600000U, 0x41200000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
};
constexpr std::array<std::uint32_t, 16> kInput1 = {
    0x40000000U, 0x3f000000U, 0xbfa00000U, 0xc0a00000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
};
constexpr std::array<std::uint32_t, 16> kIntermediateGolden = {
    0x40400000U, 0xbf000000U, 0x40100000U, 0x40a00000U,
    0x40400000U, 0x40400000U, 0x40400000U, 0x40400000U,
    0x40400000U, 0x40400000U, 0x40400000U, 0x40400000U,
    0x40400000U, 0x40400000U, 0x40400000U, 0x40400000U,
};
constexpr std::array<std::uint32_t, 16> kOutputGolden = {
    0x40800000U, 0x3f000002U, 0x40500001U, 0x40c00001U,
    0x40800001U, 0x40800001U, 0x40800002U, 0x40800002U,
    0x40800002U, 0x40800002U, 0x40800002U, 0x40800003U,
    0x40800003U, 0x40800003U, 0x40800004U, 0x40800004U,
};
constexpr std::array<std::pair<const char *, std::uint64_t>, 5>
    kBufferBases = {{
        {"input0", 0x0000000310000000ULL},
        {"input1", 0x0000000520000000ULL},
        {"intermediate", 0x0000000630000000ULL},
        {"bias", 0x0000000640000000ULL},
        {"output", 0x0000000730000000ULL},
    }};

struct owned_buffer {
    std::string id;
    npu_compiled_buffer_kind kind = npu_compiled_buffer_kind::input;
    std::uint64_t base = 0U;
    std::uint32_t permissions = 0U;
    std::vector<std::uint8_t> bytes;
};

std::uint32_t load_le32(const std::uint8_t * bytes) {
    return static_cast<std::uint32_t>(bytes[0]) |
           (static_cast<std::uint32_t>(bytes[1]) << 8U) |
           (static_cast<std::uint32_t>(bytes[2]) << 16U) |
           (static_cast<std::uint32_t>(bytes[3]) << 24U);
}

std::uint64_t load_le64(const std::uint8_t * bytes) {
    std::uint64_t value = 0U;
    for (std::size_t index = 0; index < 8U; ++index) {
        value |= static_cast<std::uint64_t>(bytes[index]) << (8U * index);
    }
    return value;
}

void store_le32(std::uint8_t * bytes, std::uint32_t value) {
    for (std::size_t index = 0; index < 4U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (std::size_t index = 0; index < 8U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

std::uint32_t rotate_right(std::uint32_t value, unsigned amount) {
    return (value >> amount) | (value << (32U - amount));
}

// The production loader independently verifies this digest before dispatch.
// This small local implementation lets the test derive a controlled static
// capability-reject record without adding OpenSSL or a compiler-side fixture.
class sha256_state {
public:
    void update(const std::uint8_t * bytes, std::size_t size) {
        total_ += size;
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
            digest[word * 4U] = static_cast<std::uint8_t>(state_[word] >> 24U);
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
                static_cast<std::uint32_t>(block[4U * index]) << 24U |
                static_cast<std::uint32_t>(block[4U * index + 1U]) << 16U |
                static_cast<std::uint32_t>(block[4U * index + 2U]) << 8U |
                static_cast<std::uint32_t>(block[4U * index + 3U]);
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
            const std::uint32_t ch = (e & f) ^ (~e & g);
            const std::uint32_t t1 = h + s1 + ch + k[index] + words[index];
            const std::uint32_t s0 = rotate_right(a, 2U) ^
                rotate_right(a, 13U) ^ rotate_right(a, 22U);
            const std::uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            const std::uint32_t t2 = s0 + maj;
            h = g; g = f; f = e; e = d + t1;
            d = c; c = b; b = a; a = t1 + t2;
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

void refresh_command_payload_hash(std::vector<std::uint8_t> * image) {
    sha256_state state;
    state.update(image->data() + NPU_COMPILED_COMMAND_HEADER_BYTES,
                 image->size() - NPU_COMPILED_COMMAND_HEADER_BYTES);
    const auto digest = state.finish();
    std::copy(digest.begin(), digest.end(), image->begin() + 32U);
}

std::uint64_t buffer_base(const std::string & id) {
    const auto found = std::find_if(
        kBufferBases.begin(), kBufferBases.end(),
        [&](const auto & entry) { return id == entry.first; });
    return found == kBufferBases.end() ? 0U : found->second;
}

owned_buffer * find_buffer(
        std::vector<owned_buffer> * buffers,
        const std::string & id) {
    if (buffers == nullptr) return nullptr;
    const auto found = std::find_if(
        buffers->begin(), buffers->end(),
        [&](const owned_buffer & buffer) { return buffer.id == id; });
    return found == buffers->end() ? nullptr : &*found;
}

template <std::size_t N>
bool store_words(
        std::vector<owned_buffer> * buffers,
        const std::string & id,
        const std::array<std::uint32_t, N> & words) {
    owned_buffer * buffer = find_buffer(buffers, id);
    if (buffer == nullptr || buffer->bytes.size() != N * 4U) return false;
    for (std::size_t index = 0; index < N; ++index) {
        store_le32(buffer->bytes.data() + index * 4U, words[index]);
    }
    return true;
}

template <std::size_t N>
bool check_words(
        std::vector<owned_buffer> * buffers,
        const std::string & id,
        const std::array<std::uint32_t, N> & expected) {
    owned_buffer * buffer = find_buffer(buffers, id);
    if (buffer == nullptr || buffer->bytes.size() != N * 4U) return false;
    for (std::size_t index = 0; index < N; ++index) {
        const std::uint32_t actual =
            load_le32(buffer->bytes.data() + index * 4U);
        if (actual != expected[index]) {
            std::fprintf(stderr,
                         "[NPU-COMPILED-SYSTEM][MISMATCH] buffer=%s "
                         "lane=%zu got=0x%08x expected=0x%08x\n",
                         id.c_str(), index, actual, expected[index]);
            return false;
        }
    }
    return true;
}

bool initialize_raw_tensors(std::vector<owned_buffer> * buffers) {
    if (buffers == nullptr) return false;
    for (owned_buffer & buffer : *buffers) {
        if (buffer.kind != npu_compiled_buffer_kind::weight) {
            std::fill(buffer.bytes.begin(), buffer.bytes.end(), 0xa5U);
        }
    }
    return store_words(buffers, "input0", kInput0) &&
           store_words(buffers, "input1", kInput1);
}

bool prepare_submission(
        const std::string & directory,
        npu_compiled_bundle * bundle,
        std::vector<std::uint8_t> * command_image,
        std::vector<owned_buffer> * buffers,
        npu_system_submission * submission) {
    if (bundle == nullptr || command_image == nullptr || buffers == nullptr ||
        submission == nullptr) return false;
    npu_compiled_bundle_diagnostic diagnostic = {};
    if (!npu_compiled_bundle_load(directory, bundle, &diagnostic)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][LOAD-FAIL] error=%s path=%s "
                     "detail=%s\n",
                     npu_compiled_bundle_error_string(diagnostic.error),
                     diagnostic.path.c_str(), diagnostic.detail.c_str());
        return false;
    }
    if (bundle->graph_name != "tiny-two-vector-add" ||
        bundle->commands.size() != 2U || bundle->buffers.size() != 5U) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAIL] unexpected tiny graph\n");
        return false;
    }
    buffers->clear();
    buffers->reserve(bundle->buffers.size());
    std::vector<npu_compiled_named_binding> bindings;
    bindings.reserve(bundle->buffers.size());
    for (const npu_compiled_buffer_info & info : bundle->buffers) {
        const std::uint64_t base = buffer_base(info.id);
        if (base == 0U || info.size > SIZE_MAX || info.alignment == 0U ||
            (base & (info.alignment - 1U)) != 0U) return false;
        owned_buffer buffer = {};
        buffer.id = info.id;
        buffer.kind = info.kind;
        buffer.base = base;
        buffer.permissions = info.permissions;
        buffer.bytes.assign(static_cast<std::size_t>(info.size), 0U);
        if (info.kind == npu_compiled_buffer_kind::weight) {
            if (info.weights_offset > bundle->weights.size() ||
                info.size > bundle->weights.size() -
                                static_cast<std::size_t>(info.weights_offset)) {
                return false;
            }
            std::copy_n(bundle->weights.begin() +
                            static_cast<std::size_t>(info.weights_offset),
                        static_cast<std::size_t>(info.size),
                        buffer.bytes.begin());
        }
        buffers->push_back(std::move(buffer));
        bindings.push_back({info.id, base, info.size, info.permissions});
    }
    if (!npu_compiled_bundle_relocate(
            bundle, bindings.data(), bindings.size(), command_image,
            &diagnostic)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][RELOCATE-FAIL] error=%s "
                     "path=%s detail=%s\n",
                     npu_compiled_bundle_error_string(diagnostic.error),
                     diagnostic.path.c_str(), diagnostic.detail.c_str());
        return false;
    }
    submission->relocated_command_image = command_image;
    submission->buffers.clear();
    for (owned_buffer & buffer : *buffers) {
        submission->buffers.push_back(
            {buffer.id, buffer.base, buffer.permissions, &buffer.bytes});
    }
    submission->commands.clear();
    submission->max_cycles = 0U;
    for (std::size_t index = 0; index < bundle->commands.size(); ++index) {
        const npu_compiled_command_info & source = bundle->commands[index];
        if (source.owner != npu_compiled_command_owner::f32_alu ||
            source.cycle_upper_bound == 0U ||
            source.cycle_upper_bound >
                std::numeric_limits<std::uint64_t>::max() -
                    submission->max_cycles) {
            return false;
        }
        submission->max_cycles += source.cycle_upper_bound;
        npu_system_command_contract contract = {};
        contract.owner = npu_system_command_owner::f32_alu;
        contract.expected_outcome = npu_system_expected_outcome::success;
        contract.expected_npu_error_code = 0U;
        contract.identity.kernel_id = source.identity.kernel_id;
        contract.identity.command_flags = source.identity.command_flags;
        contract.identity.context_id = source.identity.context_id;
        contract.identity.sequence_id = source.identity.sequence_id;
        contract.identity.producer_id = source.identity.producer_id;
        contract.identity.user_tag = source.identity.user_tag;
        contract.identity.covered_node_count =
            source.identity.covered_node_count;
        contract.identity.node_hash_lo = source.identity.node_hash_lo;
        contract.identity.node_hash_hi = source.identity.node_hash_hi;
        contract.identity.local_profile = source.identity.local_profile;
        contract.f32_alu.request_groups = source.f32_alu.request_groups;
        contract.f32_alu.response_groups = source.f32_alu.response_groups;
        contract.f32_alu.read_groups = source.f32_alu.read_groups;
        contract.f32_alu.write_groups = source.f32_alu.write_groups;
        contract.f32_alu.input_words = source.f32_alu.input_words;
        contract.f32_alu.output_words = source.f32_alu.output_words;
        contract.f32_alu.read_bytes = source.f32_alu.read_bytes;
        contract.f32_alu.write_bytes = source.f32_alu.write_bytes;
        contract.f32_alu.completion_vector_elements =
            source.f32_alu.completion_vector_elements;
        contract.f32_alu.expected_starts = source.f32_alu.expected_starts;
        submission->commands.push_back(contract);
    }
    return initialize_raw_tensors(buffers);
}

bool make_recoverable_fault_submission(
        const npu_system_submission & success,
        const std::vector<std::uint8_t> & success_image,
        std::vector<std::uint8_t> * fault_image,
        npu_system_submission * fault) {
    if (fault_image == nullptr || fault == nullptr ||
        success.commands.empty()) return false;
    *fault_image = success_image;
    const std::size_t word0_offset = NPU_COMPILED_COMMAND_HEADER_BYTES;
    const std::uint64_t word0 = load_le64(
        fault_image->data() + word0_offset);
    store_le64(fault_image->data() + word0_offset,
               (word0 & 0xffffffff00000000ULL) | 0xdeadbeefU);
    refresh_command_payload_hash(fault_image);
    *fault = success;
    fault->relocated_command_image = fault_image;
    fault->commands[0].identity.kernel_id = 0xdeadbeefU;
    fault->commands[0].expected_outcome =
        npu_system_expected_outcome::recoverable_npu_fault;
    fault->commands[0].expected_npu_error_code = 14U;
    fault->commands[0].f32_alu = {};
    return true;
}

bool make_mixed_zero_submission(
        const npu_system_submission & nonzero,
        const std::vector<std::uint8_t> & nonzero_image,
        std::vector<std::uint8_t> * mixed_image,
        npu_system_submission * mixed) {
    if (mixed_image == nullptr || mixed == nullptr ||
        nonzero.commands.size() != 2U) return false;
    *mixed_image = nonzero_image;
    const std::size_t record_offset =
        NPU_COMPILED_COMMAND_HEADER_BYTES +
        NPU_COMPILED_COMMAND_RECORD_BYTES;
    const auto put_word = [&](std::size_t word, std::uint64_t value) {
        store_le64(mixed_image->data() + record_offset +
                       word * sizeof(std::uint64_t),
                   value);
    };
    // A real P17 empty SCALE descriptor: unary source, rooted zero-byte
    // src0/dst windows, no strides, no child start and no portal traffic.
    put_word(5U, (std::uint64_t{4U} << 32U) | 1U);
    put_word(9U, (std::uint64_t{1U} << 32U) | 17U);
    put_word(11U, 0U);
    put_word(15U, 0U);
    put_word(16U, 1U);
    put_word(19U, 0U);
    put_word(20U, 0U);
    put_word(22U, 0U);
    put_word(24U, 0U);
    put_word(25U, 0x87U);
    put_word(26U, 0U);
    put_word(27U, 0U);
    put_word(29U, 0U);
    refresh_command_payload_hash(mixed_image);
    *mixed = nonzero;
    mixed->relocated_command_image = mixed_image;
    mixed->commands[1].identity.local_profile = 17U;
    mixed->commands[1].f32_alu = {};
    return true;
}

bool make_fatal_timeout_submission(
        const npu_system_submission & success,
        const std::vector<std::uint8_t> & success_image,
        std::vector<std::uint8_t> * fatal_image,
        npu_system_submission * fatal) {
    if (fatal_image == nullptr || fatal == nullptr ||
        success.commands.empty()) return false;
    *fatal_image = success_image;
    const std::size_t deadline_offset =
        NPU_COMPILED_COMMAND_HEADER_BYTES + 8U * sizeof(std::uint64_t);
    store_le64(fatal_image->data() + deadline_offset, 1U);
    refresh_command_payload_hash(fatal_image);
    *fatal = success;
    fatal->relocated_command_image = fatal_image;
    // A runtime failure is never required to have been predicted by the host
    // contract.  The session still waits for and verifies the precise fatal
    // completion before permanently poisoning itself.
    return true;
}

bool same_counters(
        const npu_system_counters & a,
        const npu_system_counters & b) {
    return a.cycles == b.cycles && a.commits == b.commits &&
        a.config_accepts == b.config_accepts &&
        a.launch_accepts == b.launch_accepts &&
        a.macro_terminals == b.macro_terminals &&
        a.portal_requests == b.portal_requests &&
        a.portal_responses == b.portal_responses &&
        a.portal_reads == b.portal_reads &&
        a.portal_writes == b.portal_writes &&
        a.portal_input_words == b.portal_input_words &&
        a.portal_output_words == b.portal_output_words &&
        a.portal_read_bytes == b.portal_read_bytes &&
        a.portal_write_bytes == b.portal_write_bytes &&
        a.rtl_macro_commands == b.rtl_macro_commands &&
        a.rtl_f32_starts == b.rtl_f32_starts &&
        a.rtl_macro_completions == b.rtl_macro_completions &&
        a.rtl_error_clears == b.rtl_error_clears &&
        a.traps == b.traps && a.exits == b.exits;
}

const npu_system_buffer_activity * find_activity(
        const npu_system_dispatch_result & result,
        const std::string & id) {
    const auto found = std::find_if(
        result.buffers.begin(), result.buffers.end(),
        [&](const npu_system_buffer_activity & item) { return item.id == id; });
    return found == result.buffers.end() ? nullptr : &*found;
}

bool check_generation(
        const npu_system_dispatch_result & result,
        std::vector<owned_buffer> * buffers) {
    const npu_system_buffer_activity * intermediate =
        find_activity(result, "intermediate");
    return result.mailbox_state == NPU_SERVICE_STATE_DONE &&
        result.mailbox_error == NPU_SERVICE_ERROR_NONE &&
        result.completed == 2U && result.boot_count == 1U &&
        result.delta.config_accepts == 60U &&
        result.delta.launch_accepts == 2U &&
        result.delta.macro_terminals == 2U &&
        result.delta.portal_requests == 8U &&
        result.delta.portal_responses == 8U &&
        result.delta.portal_reads == 4U &&
        result.delta.portal_writes == 4U &&
        result.delta.portal_input_words == 64U &&
        result.delta.portal_output_words == 32U &&
        result.delta.portal_read_bytes == 256U &&
        result.delta.portal_write_bytes == 128U &&
        result.delta.rtl_macro_commands == 2U &&
        result.delta.rtl_f32_starts == 2U &&
        result.delta.rtl_macro_completions == 2U &&
        result.delta.rtl_error_clears == 0U &&
        result.delta.traps == 0U && result.delta.exits == 0U &&
        intermediate != nullptr && intermediate->write_words == 16U &&
        intermediate->read_words == 16U &&
        intermediate->reads_after_write == 16U &&
        check_words(buffers, "intermediate", kIntermediateGolden) &&
        check_words(buffers, "output", kOutputGolden);
}

bool check_mixed_zero_generation(
        const npu_system_dispatch_result & result,
        std::vector<owned_buffer> * buffers) {
    const npu_system_buffer_activity * intermediate =
        find_activity(result, "intermediate");
    const owned_buffer * output = find_buffer(buffers, "output");
    return result.mailbox_state == NPU_SERVICE_STATE_DONE &&
        result.mailbox_error == NPU_SERVICE_ERROR_NONE &&
        result.completed == 2U && result.boot_count == 1U &&
        result.delta.config_accepts == 60U &&
        result.delta.launch_accepts == 2U &&
        result.delta.macro_terminals == 2U &&
        result.delta.portal_requests == 4U &&
        result.delta.portal_responses == 4U &&
        result.delta.portal_reads == 2U &&
        result.delta.portal_writes == 2U &&
        result.delta.portal_input_words == 32U &&
        result.delta.portal_output_words == 16U &&
        result.delta.portal_read_bytes == 128U &&
        result.delta.portal_write_bytes == 64U &&
        result.delta.rtl_macro_commands == 2U &&
        result.delta.rtl_f32_starts == 1U &&
        result.delta.rtl_macro_completions == 2U &&
        result.delta.rtl_error_clears == 0U &&
        result.delta.traps == 0U && result.delta.exits == 0U &&
        intermediate != nullptr && intermediate->write_words == 16U &&
        intermediate->read_words == 0U &&
        intermediate->reads_after_write == 0U &&
        output != nullptr &&
        std::all_of(output->bytes.begin(), output->bytes.end(),
                    [](std::uint8_t byte) { return byte == 0xa5U; }) &&
        check_words(buffers, "intermediate", kIntermediateGolden);
}

bool same_buffer_bytes(
        const std::vector<owned_buffer> & buffers,
        const std::vector<std::vector<std::uint8_t>> & before) {
    if (buffers.size() != before.size()) return false;
    for (std::size_t index = 0; index < buffers.size(); ++index) {
        if (buffers[index].bytes != before[index]) return false;
    }
    return true;
}

}  // namespace

int main(int argc, char ** argv) {
    if (argc != 2) {
        std::fprintf(stderr,
                     "usage: %s <compiled-bundle-directory>\n",
                     argc > 0 ? argv[0] : "test-compiled-bundle-system");
        return 2;
    }
    npu_compiled_bundle bundle = {};
    std::vector<std::uint8_t> command_image;
    std::vector<owned_buffer> buffers;
    npu_system_submission submission = {};
    if (!prepare_submission(argv[1], &bundle, &command_image, &buffers,
                            &submission)) return 1;

    npu_system_session session(argc, argv);
    if (!session.ready()) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][BOOT-FAIL] error=%s detail=%s\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str());
        return 1;
    }
    const npu_system_session_status boot = session.status();
    if (boot.constructor_count != 1U || boot.reset_release_count != 1U ||
        boot.boot_count != 1U || boot.fatal) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAIL] lifecycle mismatch\n");
        return 1;
    }

    submission.generation = 1U;
    npu_system_dispatch_result generation1 = {};
    if (!session.dispatch(submission, &generation1) ||
        !check_generation(generation1, &buffers)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][GEN1-FAIL] error=%s detail=%s\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str());
        return 1;
    }

    const npu_system_session_status before_stale = session.status();
    std::vector<std::vector<std::uint8_t>> buffer_snapshot;
    for (const owned_buffer & buffer : buffers) {
        buffer_snapshot.push_back(buffer.bytes);
    }
    npu_system_dispatch_result stale = {};
    if (session.dispatch(submission, &stale) ||
        session.last_error() != npu_system_session_error::stale_generation ||
        session.fatal() ||
        !same_counters(before_stale.counters, session.status().counters) ||
        !same_buffer_bytes(buffers, buffer_snapshot)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAIL] stale generation was not "
                     "rejected without activity\n");
        return 1;
    }

    if (!initialize_raw_tensors(&buffers)) return 1;
    std::vector<std::uint8_t> mixed_image;
    npu_system_submission mixed_submission = {};
    if (!make_mixed_zero_submission(
            submission, command_image, &mixed_image, &mixed_submission)) {
        return 1;
    }
    mixed_submission.generation = 2U;
    npu_system_dispatch_result mixed_result = {};
    if (!session.dispatch(mixed_submission, &mixed_result) ||
        !check_mixed_zero_generation(mixed_result, &buffers)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][MIXED-ZERO-FAIL] error=%s "
                     "detail=%s starts=%llu\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str(),
                     static_cast<unsigned long long>(
                         mixed_result.delta.rtl_f32_starts));
        return 1;
    }

    std::vector<std::uint8_t> fault_image;
    npu_system_submission fault_submission = {};
    if (!make_recoverable_fault_submission(
            submission, command_image, &fault_image, &fault_submission)) {
        return 1;
    }
    fault_submission.generation = 3U;
    buffer_snapshot.clear();
    for (const owned_buffer & buffer : buffers) {
        buffer_snapshot.push_back(buffer.bytes);
    }
    npu_system_dispatch_result recovered_fault = {};
    if (session.dispatch(fault_submission, &recovered_fault) ||
        session.last_error() !=
            npu_system_session_error::recoverable_npu_fault ||
        session.fatal() || recovered_fault.boot_count != 1U ||
        recovered_fault.mailbox_state != NPU_SERVICE_STATE_ERROR ||
        recovered_fault.mailbox_error != NPU_SERVICE_ERROR_NPU_FAULT ||
        recovered_fault.completed != 1U ||
        recovered_fault.completion_status !=
            NPU_SERVICE_COMPLETION_STATUS_NPU_FAULT ||
        recovered_fault.fault_cause != NPU_SERVICE_NPU_FAULT_MCAUSE ||
        ((recovered_fault.fault_tval >>
              NPU_SERVICE_NPU_FAULT_VERSION_SHIFT) &
             NPU_SERVICE_NPU_FAULT_VERSION_MASK) !=
            NPU_SERVICE_NPU_FAULT_MTVAL_VERSION ||
        (recovered_fault.fault_tval >>
             NPU_SERVICE_NPU_FAULT_FATAL_BIT) != 0U ||
        ((recovered_fault.fault_tval >> 56U) & 0x7fU) != 14U ||
        recovered_fault.fault_pc == 0U ||
        recovered_fault.delta.config_accepts != 30U ||
        recovered_fault.delta.launch_accepts != 1U ||
        recovered_fault.delta.macro_terminals != 1U ||
        recovered_fault.delta.portal_requests != 0U ||
        recovered_fault.delta.portal_responses != 0U ||
        recovered_fault.delta.portal_reads != 0U ||
        recovered_fault.delta.portal_writes != 0U ||
        recovered_fault.delta.rtl_macro_commands != 1U ||
        recovered_fault.delta.rtl_f32_starts != 0U ||
        recovered_fault.delta.rtl_macro_completions != 0U ||
        recovered_fault.delta.rtl_error_clears != 1U ||
        recovered_fault.delta.traps == 0U ||
        !same_buffer_bytes(buffers, buffer_snapshot) ||
        session.status().last_generation != 3U ||
        session.status().boot_count != 1U) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAULT-FAIL] error=%s detail=%s "
                     "mailbox=%u status=%u clears=%llu traps=%llu\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str(), recovered_fault.mailbox_error,
                     recovered_fault.completion_status,
                     static_cast<unsigned long long>(
                         recovered_fault.delta.rtl_error_clears),
                     static_cast<unsigned long long>(
                         recovered_fault.delta.traps));
        return 1;
    }

    if (!initialize_raw_tensors(&buffers)) return 1;
    submission.generation = 4U;
    npu_system_dispatch_result generation4 = {};
    if (!session.dispatch(submission, &generation4) ||
        !check_generation(generation4, &buffers)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][GEN4-FAIL] error=%s detail=%s\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str());
        return 1;
    }

    const npu_system_session_status final = session.status();
    if (final.constructor_count != 1U || final.reset_release_count != 1U ||
        final.boot_count != 1U || final.last_generation != 4U || final.fatal ||
        final.counters.config_accepts != 210U ||
        final.counters.launch_accepts != 7U ||
        final.counters.macro_terminals != 7U ||
        final.counters.rtl_macro_commands != 7U ||
        final.counters.rtl_f32_starts != 5U ||
        final.counters.rtl_macro_completions != 6U ||
        final.counters.rtl_error_clears != 1U) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAIL] final session mismatch\n");
        return 1;
    }

    std::vector<std::uint8_t> fatal_image;
    npu_system_submission fatal_submission = {};
    if (!make_fatal_timeout_submission(
            submission, command_image, &fatal_image, &fatal_submission)) {
        return 1;
    }
    fatal_submission.generation = 5U;
    npu_system_dispatch_result fatal_result = {};
    if (session.dispatch(fatal_submission, &fatal_result) ||
        session.last_error() != npu_system_session_error::fatal_npu_fault ||
        !session.fatal() || fatal_result.boot_count != 1U ||
        fatal_result.mailbox_state != NPU_SERVICE_STATE_ERROR ||
        fatal_result.mailbox_error != NPU_SERVICE_ERROR_NPU_FATAL ||
        fatal_result.completed != 1U ||
        fatal_result.completion_status !=
            NPU_SERVICE_COMPLETION_STATUS_NPU_FATAL ||
        fatal_result.fault_cause != NPU_SERVICE_NPU_FAULT_MCAUSE ||
        (fatal_result.fault_tval >>
             NPU_SERVICE_NPU_FAULT_FATAL_BIT) != 1U ||
        fatal_result.delta.config_accepts != 30U ||
        fatal_result.delta.launch_accepts != 1U ||
        fatal_result.delta.macro_terminals != 1U ||
        fatal_result.delta.rtl_error_clears != 0U ||
        fatal_result.delta.traps != 1U ||
        session.status().last_generation != 5U ||
        session.status().boot_count != 1U) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FATAL-FAIL] error=%s detail=%s "
                     "mailbox=%u status=%u code=0x%02llx traps=%llu\n",
                     npu_system_session_error_string(session.last_error()),
                     session.failure().c_str(), fatal_result.mailbox_error,
                     fatal_result.completion_status,
                     static_cast<unsigned long long>(
                         (fatal_result.fault_tval >> 56U) & 0xffU),
                     static_cast<unsigned long long>(fatal_result.delta.traps));
        return 1;
    }
    const npu_system_counters fatal_counters = session.status().counters;
    submission.generation = 6U;
    if (session.dispatch(submission, nullptr) ||
        session.last_error() != npu_system_session_error::session_fatal ||
        !same_counters(fatal_counters, session.status().counters)) {
        std::fprintf(stderr,
                     "[NPU-COMPILED-SYSTEM][FAIL] fatal session was reused\n");
        return 1;
    }
    std::printf(
        "[NPU-COMPILED-SYSTEM][PASS] bundle_id=%s constructors=1 "
        "reset_releases=1 boot_count=1 accepted_generations=5 "
        "successful_generations=3 mixed_zero_cardinality=1 stale_reject=1 "
        "recoverable_fault=1 fatal_fault=1 fatal_reuse_reject=1 "
        "successful_commands=6 "
        "host_tensor_arithmetic=0\n",
        bundle.bundle_id.c_str());
    return 0;
}
