#include "npu-command-abi.h"

#include "npu-verilator-runner.h"

#include <limits>
#include <new>
#include <stdexcept>
#include <utility>

namespace {

constexpr std::uint32_t kSrc0AddressWord = 10U;
constexpr std::uint32_t kSrc1AddressWord = 11U;
constexpr std::uint32_t kSrc2AddressWord = 12U;
constexpr std::uint32_t kDstAddressWord = 13U;
constexpr std::uint32_t kScratchAddressWord = 14U;
constexpr std::uint32_t kSrc0WindowBaseWord = 23U;
constexpr std::uint32_t kSrc0WindowSizeWord = 24U;
constexpr std::uint32_t kPermissionsWord = 25U;
constexpr std::uint32_t kSrc1WindowBaseWord = 26U;
constexpr std::uint32_t kSrc1WindowSizeWord = 27U;
constexpr std::uint32_t kDstWindowBaseWord = 28U;
constexpr std::uint32_t kDstWindowSizeWord = 29U;
constexpr std::size_t kNoRelocation = static_cast<std::size_t>(-1);

struct window_words {
    std::uint32_t address;
    std::uint32_t base;
    std::uint32_t size;
    unsigned permission_shift;
};

constexpr std::array<window_words, 3> kWindowWords = {{
    {kSrc0AddressWord, kSrc0WindowBaseWord, kSrc0WindowSizeWord, 2U},
    {kSrc1AddressWord, kSrc1WindowBaseWord, kSrc1WindowSizeWord, 4U},
    {kDstAddressWord, kDstWindowBaseWord, kDstWindowSizeWord, 6U},
}};

void clear_diagnostic(npu_command_abi_diagnostic * diagnostic) {
    if (diagnostic != nullptr) {
        *diagnostic = {};
    }
}

bool fail(
        npu_command_abi_diagnostic * diagnostic,
        npu_command_abi_error error,
        std::uint32_t word_index = UINT32_MAX,
        std::size_t relocation_index = kNoRelocation) {
    if (diagnostic != nullptr) {
        diagnostic->error = error;
        diagnostic->word_index = word_index;
        diagnostic->relocation_index = relocation_index;
    }
    return false;
}

bool checked_add(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        rhs > std::numeric_limits<std::uint64_t>::max() - lhs) {
        return false;
    }
    *result = lhs + rhs;
    return true;
}

bool wire_fields_representable(
        const npu_exact_command_contract & command,
        npu_command_abi_diagnostic * diagnostic) {
    if (command.abi_valid > 1U ||
        command.windows_generation_valid > 1U) {
        return fail(
            diagnostic, npu_command_abi_error::invalid_boolean,
            kPermissionsWord);
    }
    if (command.scratch_bytes >
        std::numeric_limits<std::uint32_t>::max()) {
        return fail(
            diagnostic, npu_command_abi_error::field_out_of_range, 17U);
    }
    if (command.src0_window_perm > 3U ||
        command.src1_window_perm > 3U ||
        command.dst_window_perm > 3U) {
        return fail(
            diagnostic, npu_command_abi_error::field_out_of_range,
            kPermissionsWord);
    }
    return true;
}

bool validate_one_window(
        std::uint64_t address,
        std::uint64_t base,
        std::uint64_t size,
        std::uint32_t word_index,
        npu_command_abi_diagnostic * diagnostic,
        bool empty_cpy = false) {
    std::uint64_t end = 0;
    if (!checked_add(base, size, &end)) {
        return fail(
            diagnostic, npu_command_abi_error::arithmetic_overflow,
            word_index);
    }
    // Existing zero-cardinality profiles intentionally own no bytes.  Their
    // semantic FP32/Q8 address may still select a lane within the aligned
    // beat named by base; no byte is accessible while size remains zero.
    if ((size == 0U &&
         ((base & 7U) != 0U || (address & ~std::uint64_t{7}) != base)) ||
        (size != 0U &&
         (address < base || address > end || (address == end && !empty_cpy)))) {
        return fail(
            diagnostic, npu_command_abi_error::address_window_mismatch,
            word_index);
    }
    return true;
}

bool address_in_window(
        std::uint64_t address,
        std::uint64_t base,
        std::uint64_t size) {
    if (size == 0U) {
        return (base & 7U) == 0U &&
               (address & ~std::uint64_t{7}) == base;
    }
    std::uint64_t end = 0;
    return checked_add(base, size, &end) &&
           address >= base && address < end;
}

std::uint32_t permission_from_words(
        const npu_command_abi_words & words,
        unsigned shift) {
    return static_cast<std::uint32_t>((words[kPermissionsWord] >> shift) &
                                      3ULL);
}

bool is_relocatable_word(std::uint32_t word_index) {
    switch (word_index) {
        case kSrc0AddressWord:
        case kSrc1AddressWord:
        case kSrc2AddressWord:
        case kDstAddressWord:
        case kSrc0WindowBaseWord:
        case kSrc1WindowBaseWord:
        case kDstWindowBaseWord:
            return true;
        default:
            return false;
    }
}

std::uint64_t load_le64(const std::uint8_t * bytes) {
    std::uint64_t value = 0;
    for (unsigned byte = 0; byte < 8U; ++byte) {
        value |= static_cast<std::uint64_t>(bytes[byte]) << (8U * byte);
    }
    return value;
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (unsigned byte = 0; byte < 8U; ++byte) {
        bytes[byte] = static_cast<std::uint8_t>(value >> (8U * byte));
    }
}

}  // namespace

bool npu_command_abi_pack_words(
        const npu_exact_command_contract * command,
        npu_command_abi_words * words,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (command == nullptr || words == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    if (!wire_fields_representable(*command, diagnostic)) {
        return false;
    }

    const std::uint64_t permissions =
        static_cast<std::uint64_t>(command->abi_valid) |
        (static_cast<std::uint64_t>(command->windows_generation_valid) << 1U) |
        (static_cast<std::uint64_t>(command->src0_window_perm) << 2U) |
        (static_cast<std::uint64_t>(command->src1_window_perm) << 4U) |
        (static_cast<std::uint64_t>(command->dst_window_perm) << 6U);
    npu_command_abi_words candidate = {{
        (static_cast<std::uint64_t>(command->command_flags) << 32U) |
            command->kernel_id,
        (static_cast<std::uint64_t>(command->capability_epoch) << 32U) |
            command->context_id,
        command->sequence_id,
        command->producer_id,
        command->user_tag,
        (static_cast<std::uint64_t>(command->vector_op) << 32U) |
            command->node_count,
        command->node_hash_lo,
        command->node_hash_hi,
        command->deadline_cycles,
        (static_cast<std::uint64_t>(command->outer_count) << 32U) |
            command->local_profile,
        command->src0_iova,
        command->src1_iova,
        command->src2_iova,
        command->dst_iova,
        command->scratch_iova,
        command->element_count,
        (static_cast<std::uint64_t>(command->scalar0) << 32U) |
            command->dtype,
        (command->scratch_bytes << 32U) | command->scalar1,
        command->rope_position,
        command->src0_stride,
        command->src1_stride,
        command->src2_stride,
        command->dst_stride,
        command->src0_window_base,
        command->src0_window_size,
        permissions,
        command->src1_window_base,
        command->src1_window_size,
        command->dst_window_base,
        command->dst_window_size,
    }};
    *words = candidate;
    return true;
}

bool npu_command_abi_unpack_words(
        const npu_command_abi_words * words,
        npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (words == nullptr || command == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    if (((*words)[18] >> 32U) != 0U) {
        return fail(
            diagnostic, npu_command_abi_error::reserved_bits_nonzero, 18U);
    }
    if (((*words)[kPermissionsWord] >> 8U) != 0U) {
        return fail(
            diagnostic, npu_command_abi_error::reserved_bits_nonzero,
            kPermissionsWord);
    }

    npu_exact_command_contract candidate = {};
    candidate.kernel_id = static_cast<std::uint32_t>((*words)[0]);
    candidate.command_flags = static_cast<std::uint32_t>((*words)[0] >> 32U);
    candidate.context_id = static_cast<std::uint32_t>((*words)[1]);
    candidate.capability_epoch =
        static_cast<std::uint32_t>((*words)[1] >> 32U);
    candidate.sequence_id = (*words)[2];
    candidate.producer_id = (*words)[3];
    candidate.user_tag = (*words)[4];
    candidate.node_count = static_cast<std::uint32_t>((*words)[5]);
    candidate.vector_op = static_cast<std::uint32_t>((*words)[5] >> 32U);
    candidate.node_hash_lo = (*words)[6];
    candidate.node_hash_hi = (*words)[7];
    candidate.deadline_cycles = (*words)[8];
    candidate.local_profile = static_cast<std::uint32_t>((*words)[9]);
    candidate.outer_count = static_cast<std::uint32_t>((*words)[9] >> 32U);
    candidate.src0_iova = (*words)[10];
    candidate.src1_iova = (*words)[11];
    candidate.src2_iova = (*words)[12];
    candidate.dst_iova = (*words)[13];
    candidate.scratch_iova = (*words)[14];
    candidate.element_count = (*words)[15];
    candidate.dtype = static_cast<std::uint32_t>((*words)[16]);
    candidate.scalar0 = static_cast<std::uint32_t>((*words)[16] >> 32U);
    candidate.scalar1 = static_cast<std::uint32_t>((*words)[17]);
    candidate.scratch_bytes =
        static_cast<std::uint32_t>((*words)[17] >> 32U);
    candidate.rope_position = static_cast<std::uint32_t>((*words)[18]);
    candidate.src0_stride = (*words)[19];
    candidate.src1_stride = (*words)[20];
    candidate.src2_stride = (*words)[21];
    candidate.dst_stride = (*words)[22];
    candidate.src0_window_base = (*words)[23];
    candidate.src0_window_size = (*words)[24];
    candidate.abi_valid =
        static_cast<std::uint32_t>((*words)[25] & 1U);
    candidate.windows_generation_valid =
        static_cast<std::uint32_t>(((*words)[25] >> 1U) & 1U);
    candidate.src0_window_perm =
        static_cast<std::uint32_t>(((*words)[25] >> 2U) & 3U);
    candidate.src1_window_perm =
        static_cast<std::uint32_t>(((*words)[25] >> 4U) & 3U);
    candidate.dst_window_perm =
        static_cast<std::uint32_t>(((*words)[25] >> 6U) & 3U);
    candidate.src1_window_base = (*words)[26];
    candidate.src1_window_size = (*words)[27];
    candidate.dst_window_base = (*words)[28];
    candidate.dst_window_size = (*words)[29];
    // dst_shadow_readable is a host capability property, not a wire bit.
    candidate.dst_shadow_readable = false;
    *command = candidate;
    return true;
}

bool npu_command_abi_encode_le(
        const npu_exact_command_contract * command,
        npu_command_abi_bytes * bytes,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (command == nullptr || bytes == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    npu_command_abi_words words = {};
    if (!npu_command_abi_pack_words(command, &words, diagnostic)) {
        return false;
    }
    npu_command_abi_bytes candidate = {};
    for (std::size_t word = 0; word < words.size(); ++word) {
        store_le64(candidate.data() + word * NPU_COMMAND_ABI_WORD_BYTES,
                   words[word]);
    }
    *bytes = candidate;
    return true;
}

bool npu_command_abi_decode_le(
        const std::uint8_t * bytes,
        std::size_t byte_count,
        npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (bytes == nullptr || command == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    if (byte_count != NPU_COMMAND_ABI_BYTES) {
        return fail(diagnostic, npu_command_abi_error::command_buffer_range);
    }
    npu_command_abi_words words = {};
    for (std::size_t word = 0; word < words.size(); ++word) {
        words[word] = load_le64(
            bytes + word * NPU_COMMAND_ABI_WORD_BYTES);
    }
    return npu_command_abi_unpack_words(&words, command, diagnostic);
}

bool npu_command_abi_validate_contract(
        const npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (command == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    if (!wire_fields_representable(*command, diagnostic)) {
        return false;
    }
    if (command->abi_valid != 1U ||
        command->windows_generation_valid != 1U) {
        return fail(
            diagnostic, npu_command_abi_error::invalid_validity,
            kPermissionsWord);
    }
    if (command->scratch_iova != 0U || command->scratch_bytes != 0U) {
        return fail(
            diagnostic, npu_command_abi_error::scratch_without_window,
            command->scratch_iova != 0U ? kScratchAddressWord : 17U);
    }
    if (command->src0_window_perm !=
            static_cast<std::uint32_t>(npu_command_abi_permission::read) ||
        (command->src1_window_perm !=
             static_cast<std::uint32_t>(npu_command_abi_permission::none) &&
         command->src1_window_perm !=
             static_cast<std::uint32_t>(npu_command_abi_permission::read)) ||
        command->dst_window_perm !=
            static_cast<std::uint32_t>(npu_command_abi_permission::write)) {
        return fail(
            diagnostic, npu_command_abi_error::invalid_permission,
            kPermissionsWord);
    }
    if (command->src1_window_perm == 0U &&
        (command->src1_iova != 0U ||
         command->src1_window_base != 0U ||
         command->src1_window_size != 0U)) {
        return fail(
            diagnostic, npu_command_abi_error::invalid_permission,
            kSrc1AddressWord);
    }
    // Frozen empty CPY views point one past the backing allocation. Their
    // outer_count=0 macro performs no memory operation; nonempty commands
    // retain the strict half-open address bound.
    const bool empty_cpy = command->kernel_id == 0x514e0007U &&
        command->vector_op == 34U && command->outer_count == 0U &&
        (command->local_profile == 3U || command->local_profile == 5U);
    if (!validate_one_window(
            command->src0_iova, command->src0_window_base,
            command->src0_window_size, kSrc0AddressWord, diagnostic, empty_cpy) ||
        !validate_one_window(
            command->src1_iova, command->src1_window_base,
            command->src1_window_size, kSrc1AddressWord, diagnostic, empty_cpy) ||
        !validate_one_window(
            command->dst_iova, command->dst_window_base,
            command->dst_window_size, kDstAddressWord, diagnostic, empty_cpy)) {
        return false;
    }
    if (command->src2_iova != 0U &&
        !address_in_window(
            command->src2_iova, command->src0_window_base,
            command->src0_window_size) &&
        !address_in_window(
            command->src2_iova, command->src1_window_base,
            command->src1_window_size) &&
        !address_in_window(
            command->src2_iova, command->dst_window_base,
            command->dst_window_size)) {
        return fail(
            diagnostic, npu_command_abi_error::src2_not_window_alias,
            kSrc2AddressWord);
    }
    return true;
}

bool npu_command_abi_validate_words(
        const npu_command_abi_words * words,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (words == nullptr) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    npu_exact_command_contract command = {};
    if (!npu_command_abi_unpack_words(words, &command, diagnostic)) {
        return false;
    }
    return npu_command_abi_validate_contract(&command, diagnostic);
}

bool npu_command_abi_validate_le(
        const std::uint8_t * bytes,
        std::size_t byte_count,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    npu_exact_command_contract command = {};
    if (!npu_command_abi_decode_le(
            bytes, byte_count, &command, diagnostic)) {
        return false;
    }
    return npu_command_abi_validate_contract(&command, diagnostic);
}

bool npu_command_abi_relocate_private_shadow(
        const std::uint8_t * command_buffer,
        std::size_t command_buffer_size,
        std::size_t command_offset,
        const npu_command_abi_relocation * relocations,
        std::size_t relocation_count,
        const npu_command_abi_buffer_binding * bindings,
        std::size_t binding_count,
        std::vector<std::uint8_t> * private_shadow,
        npu_command_abi_diagnostic * diagnostic) {
    clear_diagnostic(diagnostic);
    if (command_buffer == nullptr || private_shadow == nullptr ||
        (relocation_count != 0U && relocations == nullptr)) {
        return fail(diagnostic, npu_command_abi_error::null_argument);
    }
    if ((command_offset & (NPU_COMMAND_ABI_WORD_BYTES - 1U)) != 0U) {
        return fail(
            diagnostic, npu_command_abi_error::command_buffer_alignment);
    }
    if (command_offset > command_buffer_size ||
        NPU_COMMAND_ABI_BYTES > command_buffer_size - command_offset) {
        return fail(diagnostic, npu_command_abi_error::command_buffer_range);
    }

    npu_command_abi_words words = {};
    for (std::size_t word = 0; word < words.size(); ++word) {
        words[word] = load_le64(
            command_buffer + command_offset +
            word * NPU_COMMAND_ABI_WORD_BYTES);
    }
    // Reject unknown reserved bits before considering runtime bindings.
    npu_exact_command_contract wire_command = {};
    if (!npu_command_abi_unpack_words(&words, &wire_command, diagnostic)) {
        return false;
    }

    std::array<bool, NPU_COMMAND_ABI_WORD_COUNT> present = {};
    std::array<std::size_t, NPU_COMMAND_ABI_WORD_COUNT> record_index = {};
    std::array<std::uint32_t, NPU_COMMAND_ABI_WORD_COUNT> binding_index = {};
    std::array<std::uint64_t, NPU_COMMAND_ABI_WORD_COUNT> addend = {};
    record_index.fill(kNoRelocation);
    binding_index.fill(UINT32_MAX);

    for (std::size_t index = 0; index < relocation_count; ++index) {
        const npu_command_abi_relocation & relocation = relocations[index];
        if (relocation.word_index >= NPU_COMMAND_ABI_WORD_COUNT) {
            return fail(
                diagnostic, npu_command_abi_error::relocation_word_range,
                relocation.word_index, index);
        }
        if (!is_relocatable_word(relocation.word_index)) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_word_unsupported,
                relocation.word_index, index);
        }
        if (present[relocation.word_index]) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_duplicate_word,
                relocation.word_index, index);
        }
        if (relocation.binding_index >= binding_count ||
            bindings == nullptr) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_binding_range,
                relocation.word_index, index);
        }
        const npu_command_abi_buffer_binding & binding =
            bindings[relocation.binding_index];
        std::uint64_t binding_end = 0;
        std::uint64_t relocated_value = 0;
        if (binding.permissions >
            static_cast<std::uint32_t>(
                npu_command_abi_permission::read_write)) {
            return fail(
                diagnostic, npu_command_abi_error::invalid_permission,
                relocation.word_index, index);
        }
        if (!checked_add(binding.base, binding.size, &binding_end) ||
            !checked_add(
                binding.base, relocation.addend, &relocated_value)) {
            return fail(
                diagnostic, npu_command_abi_error::arithmetic_overflow,
                relocation.word_index, index);
        }
        if (words[relocation.word_index] != relocation.addend) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_template_mismatch,
                relocation.word_index, index);
        }
        present[relocation.word_index] = true;
        record_index[relocation.word_index] = index;
        binding_index[relocation.word_index] = relocation.binding_index;
        addend[relocation.word_index] = relocation.addend;
        words[relocation.word_index] = relocated_value;
    }

    for (const window_words & window : kWindowWords) {
        const bool address_present = present[window.address];
        const bool base_present = present[window.base];
        if (address_present != base_present) {
            const std::uint32_t missing_pair_word =
                address_present ? window.base : window.address;
            const std::size_t index = address_present ?
                record_index[window.address] : record_index[window.base];
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_pair_missing,
                missing_pair_word, index);
        }
        if (!address_present) {
            continue;
        }
        if (binding_index[window.address] != binding_index[window.base]) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_pair_binding_mismatch,
                window.address, record_index[window.address]);
        }

        const std::uint32_t selected_binding =
            binding_index[window.address];
        const npu_command_abi_buffer_binding & binding =
            bindings[selected_binding];
        const std::uint64_t window_offset = addend[window.base];
        const std::uint64_t address_offset = addend[window.address];
        const std::uint64_t window_size = words[window.size];
        if (window_offset > binding.size ||
            window_size > binding.size - window_offset ||
            (window_size == 0U &&
             (address_offset >= binding.size ||
              ((binding.base + address_offset) & ~std::uint64_t{7}) !=
                  binding.base + window_offset)) ||
            (window_size != 0U &&
             (address_offset < window_offset ||
              address_offset - window_offset >= window_size))) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_buffer_range,
                window.address, record_index[window.address]);
        }
        const std::uint32_t requested =
            permission_from_words(words, window.permission_shift);
        if ((binding.permissions & requested) != requested) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_permission,
                window.address, record_index[window.address]);
        }
    }

    if (present[kSrc2AddressWord]) {
        const std::uint32_t selected_binding =
            binding_index[kSrc2AddressWord];
        const npu_command_abi_buffer_binding & binding =
            bindings[selected_binding];
        if ((binding.permissions &
             static_cast<std::uint32_t>(
                 npu_command_abi_permission::read)) == 0U) {
            return fail(
                diagnostic,
                npu_command_abi_error::relocation_permission,
                kSrc2AddressWord, record_index[kSrc2AddressWord]);
        }

        bool aliases_declared_window = false;
        for (const window_words & window : kWindowWords) {
            if (!address_in_window(
                    words[kSrc2AddressWord], words[window.base],
                    words[window.size])) {
                continue;
            }
            if (present[window.address]) {
                aliases_declared_window =
                    binding_index[window.address] == selected_binding;
            } else {
                std::uint64_t binding_end = 0;
                std::uint64_t window_end = 0;
                aliases_declared_window =
                    checked_add(binding.base, binding.size, &binding_end) &&
                    checked_add(
                        words[window.base], words[window.size], &window_end) &&
                    words[window.base] >= binding.base &&
                    window_end <= binding_end;
            }
            if (aliases_declared_window) {
                break;
            }
        }
        if (!aliases_declared_window) {
            return fail(
                diagnostic,
                npu_command_abi_error::src2_not_window_alias,
                kSrc2AddressWord, record_index[kSrc2AddressWord]);
        }
    } else if (words[kSrc2AddressWord] != 0U) {
        return fail(
            diagnostic, npu_command_abi_error::relocation_src2_missing,
            kSrc2AddressWord);
    }

    if (!npu_command_abi_validate_words(&words, diagnostic)) {
        return false;
    }

    try {
        std::vector<std::uint8_t> candidate(
            command_buffer, command_buffer + command_buffer_size);
        for (std::size_t word = 0; word < words.size(); ++word) {
            store_le64(
                candidate.data() + command_offset +
                    word * NPU_COMMAND_ABI_WORD_BYTES,
                words[word]);
        }
        private_shadow->swap(candidate);
    } catch (const std::bad_alloc &) {
        return fail(diagnostic, npu_command_abi_error::allocation_failure);
    } catch (const std::length_error &) {
        return fail(diagnostic, npu_command_abi_error::allocation_failure);
    }
    clear_diagnostic(diagnostic);
    return true;
}

const char * npu_command_abi_error_string(npu_command_abi_error error) {
    switch (error) {
        case npu_command_abi_error::none:
            return "none";
        case npu_command_abi_error::null_argument:
            return "null argument";
        case npu_command_abi_error::invalid_boolean:
            return "invalid boolean field";
        case npu_command_abi_error::field_out_of_range:
            return "field out of range";
        case npu_command_abi_error::reserved_bits_nonzero:
            return "reserved bits are nonzero";
        case npu_command_abi_error::invalid_validity:
            return "descriptor validity bits are not set";
        case npu_command_abi_error::invalid_permission:
            return "invalid permission";
        case npu_command_abi_error::scratch_without_window:
            return "scratch address has no v1 window";
        case npu_command_abi_error::arithmetic_overflow:
            return "unsigned address arithmetic overflow";
        case npu_command_abi_error::address_window_mismatch:
            return "address is outside its declared window";
        case npu_command_abi_error::src2_not_window_alias:
            return "src2 is not an explicit declared-window alias";
        case npu_command_abi_error::command_buffer_range:
            return "command descriptor is outside the buffer";
        case npu_command_abi_error::command_buffer_alignment:
            return "command descriptor is not 8-byte aligned";
        case npu_command_abi_error::relocation_word_range:
            return "relocation word index is outside the descriptor";
        case npu_command_abi_error::relocation_word_unsupported:
            return "descriptor word is not relocatable";
        case npu_command_abi_error::relocation_binding_range:
            return "relocation binding index is out of range";
        case npu_command_abi_error::relocation_duplicate_word:
            return "descriptor word has duplicate relocations";
        case npu_command_abi_error::relocation_template_mismatch:
            return "descriptor template does not contain relocation addend";
        case npu_command_abi_error::relocation_pair_missing:
            return "address/window-base relocation pair is incomplete";
        case npu_command_abi_error::relocation_pair_binding_mismatch:
            return "address/window-base pair uses different bindings";
        case npu_command_abi_error::relocation_buffer_range:
            return "relocated address/window exceeds its binding";
        case npu_command_abi_error::relocation_permission:
            return "binding permissions do not cover the descriptor";
        case npu_command_abi_error::relocation_src2_missing:
            return "nonzero src2 is missing an explicit alias relocation";
        case npu_command_abi_error::allocation_failure:
            return "private-shadow allocation failed";
    }
    return "unknown npu command ABI error";
}
