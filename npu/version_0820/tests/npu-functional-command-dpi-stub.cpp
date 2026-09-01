// SPDX-License-Identifier: MIT
//
// Deterministic test-only implementation of the functional-command DPI ABI.
// It validates the complete registered identity/descriptor and returns fixed
// ledgers for protocol tests.  It performs no tensor or numerical operation.

#include <svdpi.h>

#include <cstdint>

namespace {

constexpr std::uint32_t kKernelId = 0x514eff01U;
constexpr std::uint32_t kCommandFlags = 0x00000011U;
constexpr std::uint32_t kVectorOp = 0x00000023U;
constexpr std::uint32_t kFirstMode = 0x00000010U;
constexpr std::uint32_t kLastMode = 0x00000014U;
constexpr std::uint32_t kContextId = 0x434d4401U;
constexpr std::uint32_t kCapabilityEpoch = 0x00000007U;
constexpr std::uint32_t kNodeCount = 3U;
constexpr std::uint64_t kSequenceBase = 0x0102030405060700ULL;
constexpr std::uint64_t kProducerId = 0x1112131415161718ULL;
constexpr std::uint64_t kUserTag = 0x2122232425262728ULL;
constexpr std::uint64_t kNodeHashLo = 0x3132333435363738ULL;
constexpr std::uint64_t kNodeHashHi = 0x4142434445464748ULL;
constexpr std::uint64_t kDeadlineCycles = 0x0000000000010000ULL;
constexpr std::uint64_t kSrc0Iova = 0x0000000010000040ULL;
constexpr std::uint64_t kSrc1Iova = 0x0000000020000080ULL;
constexpr std::uint64_t kSrc2Iova = 0x00000000300000c0ULL;
constexpr std::uint64_t kDstIova = 0x0000000040000100ULL;
constexpr std::uint64_t kScratchIova = 0x0000000050000000ULL;
constexpr std::uint64_t kElementCount = 32ULL;
constexpr std::uint32_t kOuterCount = 2U;
constexpr std::uint32_t kDtype = 1U;
constexpr std::uint64_t kSrc0Stride = 4ULL;
constexpr std::uint64_t kSrc1Stride = 64ULL;
constexpr std::uint64_t kSrc2Stride = 128ULL;
constexpr std::uint64_t kDstStride = 256ULL;
constexpr std::uint32_t kScalar0 = 0x3f000000U;
constexpr std::uint32_t kScalar1 = 0xbf800000U;
constexpr std::uint32_t kScratchBytes = 4096U;
constexpr std::uint32_t kRopePosition = 7U;
constexpr std::uint64_t kSrc0WindowBase = 0x0000000010000000ULL;
constexpr std::uint64_t kSrc0WindowSize = 4096ULL;
constexpr std::uint32_t kSrc0WindowPerm = 1U;
constexpr std::uint64_t kSrc1WindowBase = 0x0000000020000000ULL;
constexpr std::uint64_t kSrc1WindowSize = 4096ULL;
constexpr std::uint32_t kSrc1WindowPerm = 1U;
constexpr std::uint64_t kDstWindowBase = 0x0000000040000000ULL;
constexpr std::uint64_t kDstWindowSize = 8192ULL;
constexpr std::uint32_t kDstWindowPerm = 2U;

constexpr std::uint64_t kReadWords = 96ULL;
constexpr std::uint64_t kWriteWords = 32ULL;
constexpr std::uint64_t kQ8Blocks = 4ULL;
constexpr std::uint64_t kReadBytes =
    (kReadWords * 4ULL) + (kQ8Blocks * 34ULL);
constexpr std::uint64_t kWriteBytes = kWriteWords * 4ULL;
constexpr std::uint64_t kQ8MacCount = 128ULL;
constexpr std::uint64_t kVectorElements = 32ULL;

constexpr std::uint32_t kDpiErrorCode = 0x0000e101U;
constexpr std::uint32_t kDpiErrorClass = 0x0000e201U;
constexpr std::uint32_t kDescriptorErrorCode = 0x0000ed01U;
constexpr std::uint32_t kDescriptorErrorClass = 0x0000ed02U;

std::uint64_t g_call_count = 0ULL;

}  // namespace

extern "C" void npu_functional_command_stub_reset() {
    g_call_count = 0ULL;
}

extern "C" unsigned long long npu_functional_command_stub_call_count() {
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
    *error_code = 0U;
    *error_class = 0U;
    *read_words = 0ULL;
    *write_words = 0ULL;
    *read_bytes = 0ULL;
    *write_bytes = 0ULL;
    *q8_blocks = 0ULL;
    *q8_mac_count = 0ULL;
    *vector_elements = 0ULL;
    *callback_errors = 0U;

    const bool descriptor_matches =
        abi_valid == static_cast<svBit>(1U)
        && windows_generation_valid == static_cast<svBit>(1U)
        && kernel_id == kKernelId
        && command_flags == kCommandFlags
        && vector_op == kVectorOp
        && vector_flags >= kFirstMode && vector_flags <= kLastMode
        && context_id == kContextId
        && capability_epoch == kCapabilityEpoch
        && node_count == kNodeCount
        && sequence_id == (kSequenceBase
                           | static_cast<std::uint64_t>(vector_flags))
        && producer_id == kProducerId
        && user_tag == kUserTag
        && node_hash_lo == kNodeHashLo
        && node_hash_hi == kNodeHashHi
        && deadline_cycles == kDeadlineCycles
        && src0_iova == kSrc0Iova
        && src1_iova == kSrc1Iova
        && src2_iova == kSrc2Iova
        && dst_iova == kDstIova
        && scratch_iova == kScratchIova
        && element_count == kElementCount
        && outer_count == kOuterCount
        && dtype == kDtype
        && src0_stride == kSrc0Stride
        && src1_stride == kSrc1Stride
        && src2_stride == kSrc2Stride
        && dst_stride == kDstStride
        && scalar0 == kScalar0
        && scalar1 == kScalar1
        && scratch_bytes == kScratchBytes
        && rope_position == kRopePosition
        && src0_window_base == kSrc0WindowBase
        && src0_window_size == kSrc0WindowSize
        && src0_window_perm == kSrc0WindowPerm
        && src1_window_base == kSrc1WindowBase
        && src1_window_size == kSrc1WindowSize
        && src1_window_perm == kSrc1WindowPerm
        && dst_window_base == kDstWindowBase
        && dst_window_size == kDstWindowSize
        && dst_window_perm == kDstWindowPerm;

    if (!descriptor_matches) {
        *error_code = kDescriptorErrorCode;
        *error_class = kDescriptorErrorClass;
        return;
    }

    if (vector_flags == 0x00000011U) {
        *error_code = kDpiErrorCode;
        *error_class = kDpiErrorClass;
        return;
    }

    *success = static_cast<svBit>(1U);
    *read_words = kReadWords;
    *write_words = kWriteWords;
    *read_bytes = kReadBytes;
    *write_bytes = kWriteBytes;
    *q8_blocks = kQ8Blocks;
    *q8_mac_count = kQ8MacCount;
    *vector_elements = kVectorElements;

    if (vector_flags == 0x00000012U) {
        *read_bytes = kReadBytes - 1ULL;
    } else if (vector_flags == 0x00000013U) {
        *callback_errors = 2U;
    } else if (vector_flags == 0x00000014U) {
        *error_code = 0x0000e301U;
        *error_class = 0x0000e401U;
    }
}
