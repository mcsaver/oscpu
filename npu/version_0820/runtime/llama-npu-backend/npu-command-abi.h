#ifndef LLAMA_NPU_COMMAND_ABI_H
#define LLAMA_NPU_COMMAND_ABI_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

struct npu_exact_command_contract;

// This is the one wire layout consumed by NpcTensorNpuSystemTop's ordered
// CONFIG register file.  It is deliberately expressed as words and bytes,
// rather than as a packed C++ struct: neither host endianness nor compiler
// padding is part of the ABI.
constexpr std::size_t NPU_COMMAND_ABI_WORD_COUNT = 30U;
constexpr std::size_t NPU_COMMAND_ABI_WORD_BYTES = 8U;
constexpr std::size_t NPU_COMMAND_ABI_BYTES =
    NPU_COMMAND_ABI_WORD_COUNT * NPU_COMMAND_ABI_WORD_BYTES;

using npu_command_abi_words =
    std::array<std::uint64_t, NPU_COMMAND_ABI_WORD_COUNT>;
using npu_command_abi_bytes =
    std::array<std::uint8_t, NPU_COMMAND_ABI_BYTES>;

enum class npu_command_abi_permission : std::uint32_t {
    none = 0U,
    read = 1U,
    write = 2U,
    read_write = 3U,
};

enum class npu_command_abi_error : std::uint32_t {
    none = 0U,
    null_argument,
    invalid_boolean,
    field_out_of_range,
    reserved_bits_nonzero,
    invalid_validity,
    invalid_permission,
    scratch_without_window,
    arithmetic_overflow,
    address_window_mismatch,
    src2_not_window_alias,
    command_buffer_range,
    command_buffer_alignment,
    relocation_word_range,
    relocation_word_unsupported,
    relocation_binding_range,
    relocation_duplicate_word,
    relocation_template_mismatch,
    relocation_pair_missing,
    relocation_pair_binding_mismatch,
    relocation_buffer_range,
    relocation_permission,
    relocation_src2_missing,
    allocation_failure,
};

struct npu_command_abi_diagnostic {
    npu_command_abi_error error = npu_command_abi_error::none;
    std::size_t relocation_index = static_cast<std::size_t>(-1);
    std::uint32_t word_index = UINT32_MAX;
};

// A binding is a runtime-owned IOVA allocation/capability.  permissions uses
// the same read=1/write=2 bits as the descriptor.  A command may expose a
// smaller window inside a binding, but never a larger one.
struct npu_command_abi_buffer_binding {
    std::uint64_t base = 0;
    std::uint64_t size = 0;
    std::uint32_t permissions = 0;
};

// The bundle layer selects the command and resolves a named field to a word.
// This ABI layer intentionally accepts only the resolved word index.  The
// relocated value is binding.base + addend, with checked unsigned arithmetic.
struct npu_command_abi_relocation {
    std::uint32_t word_index = UINT32_MAX;
    std::uint32_t binding_index = UINT32_MAX;
    std::uint64_t addend = 0;
};

// Encode/decode only enforce wire representability and reserved-bit rules.
// They intentionally do not require abi_valid=1, so controlled-rejection RTL
// tests can still transport malformed descriptors.  Production callers must
// additionally use one of the validate functions below; relocation does so
// unconditionally.
bool npu_command_abi_pack_words(
        const npu_exact_command_contract * command,
        npu_command_abi_words * words,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_unpack_words(
        const npu_command_abi_words * words,
        npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_encode_le(
        const npu_exact_command_contract * command,
        npu_command_abi_bytes * bytes,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_decode_le(
        const std::uint8_t * bytes,
        std::size_t byte_count,
        npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_validate_contract(
        const npu_exact_command_contract * command,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_validate_words(
        const npu_command_abi_words * words,
        npu_command_abi_diagnostic * diagnostic = nullptr);

bool npu_command_abi_validate_le(
        const std::uint8_t * bytes,
        std::size_t byte_count,
        npu_command_abi_diagnostic * diagnostic = nullptr);

// Copy the complete input image, relocate one descriptor at command_offset,
// validate the resulting descriptor and atomically replace private_shadow.
// On every failure (including allocation failure), private_shadow is left
// byte-for-byte unchanged.  Address and window-base relocation pairs are:
//   src0: 10 <-> 23, src1: 11 <-> 26, dst: 13 <-> 28.
// src2 word 12 has no own window and is accepted only as an explicit alias of
// one declared src0/src1/dst binding.  v1 has no scratch window, so word 14
// cannot be relocated and its final value must be zero.
bool npu_command_abi_relocate_private_shadow(
        const std::uint8_t * command_buffer,
        std::size_t command_buffer_size,
        std::size_t command_offset,
        const npu_command_abi_relocation * relocations,
        std::size_t relocation_count,
        const npu_command_abi_buffer_binding * bindings,
        std::size_t binding_count,
        std::vector<std::uint8_t> * private_shadow,
        npu_command_abi_diagnostic * diagnostic = nullptr);

const char * npu_command_abi_error_string(npu_command_abi_error error);

#endif
