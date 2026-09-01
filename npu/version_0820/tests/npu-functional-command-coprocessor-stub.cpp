// SPDX-License-Identifier: MIT
//
// Test-only deterministic command-level DPI implementation for the
// Coprocessor integration test.  It validates the complete resident command
// descriptor and returns exact semantic ledgers.  It performs no numerical or
// tensor-memory work.

#include <svdpi.h>

#include <cstdint>

namespace {

constexpr std::uint32_t kFlags = 0x00000011U;
constexpr std::uint32_t kEpoch = 1U;
constexpr std::uint32_t kDtypeF32 = 1U;
constexpr std::uint32_t kKernelGemv = 0x514e0002U;
constexpr std::uint32_t kKernelVectorF32 = 0x514e0010U;
constexpr std::uint64_t kGemvSequence = 0x4455667788001001ULL;
constexpr std::uint64_t kF32Sequence = 0x4455667788002001ULL;
constexpr std::uint64_t kF32ZeroLedgerSequence = 0x4455667788004001ULL;
constexpr std::uint64_t kF32CallbackSequence = 0x4455667788005001ULL;

std::uint64_t g_call_count = 0ULL;

bool common_matches(
        svBit abi_valid,
        svBit windows_generation_valid,
        unsigned int command_flags,
        unsigned int capability_epoch,
        unsigned int node_count,
        unsigned long long deadline_cycles,
        unsigned long long src2_iova,
        unsigned long long scratch_iova,
        unsigned int dtype,
        unsigned long long src2_stride,
        unsigned int scalar0,
        unsigned int scalar1,
        unsigned int scratch_bytes,
        unsigned int rope_position,
        unsigned int src0_window_perm,
        unsigned int src1_window_perm,
        unsigned int dst_window_perm) noexcept {
    return abi_valid == static_cast<svBit>(1U)
        && windows_generation_valid == static_cast<svBit>(1U)
        && command_flags == kFlags
        && capability_epoch == kEpoch
        && node_count == 1U
        && deadline_cycles == 0ULL
        && src2_iova == 0ULL
        && scratch_iova == 0ULL
        && dtype == kDtypeF32
        && src2_stride == 0ULL
        && scalar0 == 0U
        && scalar1 == 0U
        && scratch_bytes == 0U
        && rope_position == 0U
        && src0_window_perm == 1U
        && src1_window_perm == 1U
        && dst_window_perm == 2U;
}

}  // namespace

extern "C" void npu_functional_coprocessor_stub_reset() {
    g_call_count = 0ULL;
}

extern "C" unsigned long long
npu_functional_coprocessor_stub_call_count() {
    return static_cast<unsigned long long>(g_call_count);
}

extern "C" void npu_functional_command_execute(
    svBit abi_valid,
    svBit windows_generation_valid,
    unsigned int kernel_id,
    unsigned int command_flags,
    unsigned int vector_op,
    unsigned int vector_flags,
    unsigned int context_id,
    unsigned int capability_epoch,
    unsigned int node_count,
    unsigned long long sequence_id,
    unsigned long long producer_id,
    unsigned long long user_tag,
    unsigned long long node_hash_lo,
    unsigned long long node_hash_hi,
    unsigned long long deadline_cycles,
    unsigned long long src0_iova,
    unsigned long long src1_iova,
    unsigned long long src2_iova,
    unsigned long long dst_iova,
    unsigned long long scratch_iova,
    unsigned long long element_count,
    unsigned int outer_count,
    unsigned int dtype,
    unsigned long long src0_stride,
    unsigned long long src1_stride,
    unsigned long long src2_stride,
    unsigned long long dst_stride,
    unsigned int scalar0,
    unsigned int scalar1,
    unsigned int scratch_bytes,
    unsigned int rope_position,
    unsigned long long src0_window_base,
    unsigned long long src0_window_size,
    unsigned int src0_window_perm,
    unsigned long long src1_window_base,
    unsigned long long src1_window_size,
    unsigned int src1_window_perm,
    unsigned long long dst_window_base,
    unsigned long long dst_window_size,
    unsigned int dst_window_perm,
    svBit * success,
    unsigned int * error_code,
    unsigned int * error_class,
    unsigned long long * read_words,
    unsigned long long * write_words,
    unsigned long long * read_bytes,
    unsigned long long * write_bytes,
    unsigned long long * q8_blocks,
    unsigned long long * q8_mac_count,
    unsigned long long * vector_elements,
    unsigned int * callback_errors) {
    if (success == nullptr || error_code == nullptr || error_class == nullptr
        || read_words == nullptr || write_words == nullptr
        || read_bytes == nullptr || write_bytes == nullptr
        || q8_blocks == nullptr || q8_mac_count == nullptr
        || vector_elements == nullptr || callback_errors == nullptr) {
        return;
    }

    ++g_call_count;
    *success = static_cast<svBit>(0U);
    *error_code = 0x0000000bU;
    *error_class = 11U;
    *read_words = 0ULL;
    *write_words = 0ULL;
    *read_bytes = 0ULL;
    *write_bytes = 0ULL;
    *q8_blocks = 0ULL;
    *q8_mac_count = 0ULL;
    *vector_elements = 0ULL;
    *callback_errors = 0U;

    const bool common = common_matches(
        abi_valid,
        windows_generation_valid,
        command_flags,
        capability_epoch,
        node_count,
        deadline_cycles,
        src2_iova,
        scratch_iova,
        dtype,
        src2_stride,
        scalar0,
        scalar1,
        scratch_bytes,
        rope_position,
        src0_window_perm,
        src1_window_perm,
        dst_window_perm);

    const std::uint64_t sequence_low =
        static_cast<std::uint64_t>(sequence_id & 0xffffffffULL);
    const bool gemv_matches = common
        && kernel_id == kKernelGemv
        && vector_op == 0U
        && vector_flags == 0U
        && sequence_id == kGemvSequence
        && context_id == 0xcafe1001U
        && producer_id == (0x1122334400000000ULL | sequence_low)
        && user_tag == (0x5566778800000000ULL | sequence_low)
        && node_hash_lo == (0x8899aabb00000000ULL | sequence_low)
        && node_hash_hi == (0xccddeeff00000000ULL | sequence_low)
        && src0_iova == 0x0000000000001104ULL
        && src1_iova == 0x0000000000001802ULL
        && dst_iova == 0x0000000000002104ULL
        && element_count == 64ULL
        && outer_count == 5U
        && src0_stride == 0ULL
        && src1_stride == 72ULL
        && dst_stride == 4ULL
        && src0_window_base == 0x0000000000001000ULL
        && src0_window_size == 0x400ULL
        && src1_window_base == 0x0000000000001800ULL
        && src1_window_size == 0x200ULL
        && dst_window_base == 0x0000000000002000ULL
        && dst_window_size == 0x200ULL;

    const bool f32_descriptor_matches = common
        && kernel_id == kKernelVectorF32
        && vector_op == 1U
        && vector_flags == 0U
        && (sequence_id == kF32Sequence
            || sequence_id == kF32ZeroLedgerSequence
            || sequence_id == kF32CallbackSequence)
        && context_id == 0x43414e01U
        && producer_id == (0x8877660000000000ULL | sequence_low)
        && user_tag == (0x1234560000000000ULL | sequence_low)
        && node_hash_lo == (0x1122330000000000ULL | sequence_low)
        && node_hash_hi == (0x4455660000000000ULL | sequence_low)
        && src0_iova == 0x0000000000001000ULL
        && src1_iova == 0x0000000000004000ULL
        && dst_iova == 0x0000000000008000ULL
        && element_count == 16ULL
        && outer_count == 1U
        && src0_stride == 64ULL
        && src1_stride == 64ULL
        && dst_stride == 64ULL
        && src0_window_base == 0x0000000000001000ULL
        && src0_window_size == 64ULL
        && src1_window_base == 0x0000000000004000ULL
        && src1_window_size == 64ULL
        && dst_window_base == 0x0000000000008000ULL
        && dst_window_size == 64ULL;

    if (gemv_matches) {
        *success = static_cast<svBit>(1U);
        *error_code = 0U;
        *error_class = 0U;
        *read_words = 64ULL;
        *write_words = 5ULL;
        *q8_blocks = 10ULL;
        *read_bytes = (64ULL * 4ULL) + (10ULL * 34ULL);
        *write_bytes = 5ULL * 4ULL;
        *q8_mac_count = 320ULL;
        *vector_elements = 5ULL;
    } else if (f32_descriptor_matches && sequence_id == kF32Sequence) {
        *success = static_cast<svBit>(1U);
        *error_code = 0U;
        *error_class = 0U;
        *read_words = 32ULL;
        *write_words = 16ULL;
        *read_bytes = 32ULL * 4ULL;
        *write_bytes = 16ULL * 4ULL;
        *q8_blocks = 0ULL;
        *q8_mac_count = 0ULL;
        *vector_elements = 16ULL;
    } else if (f32_descriptor_matches
               && sequence_id == kF32ZeroLedgerSequence) {
        // The generic child accepts this as a closed all-zero success ledger.
        // The Coprocessor must reject it against the independent P00 contract.
        *success = static_cast<svBit>(1U);
        *error_code = 0U;
        *error_class = 0U;
    } else if (f32_descriptor_matches
               && sequence_id == kF32CallbackSequence) {
        // callback_errors has priority in the child and must become private
        // F003 regardless of this otherwise well-framed runtime failure.
        *success = static_cast<svBit>(0U);
        *error_code = 16U;
        *error_class = 5U;
        *callback_errors = 1U;
    }
}
