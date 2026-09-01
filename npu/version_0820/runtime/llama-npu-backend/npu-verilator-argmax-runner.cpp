#include "npu-verilator-runner.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>

namespace {

constexpr std::uint32_t kKernelF32Argmax = 0x514e0030U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kDtypeF32 = 1U;
constexpr std::size_t kMaximumElements = 1048576U;
constexpr std::uint64_t kSrcIova = 0x0000000b40000004ULL;
constexpr std::uint64_t kDstIova = 0x0000000c50000004ULL;
constexpr std::uint32_t kErrorClassLayout = 4U;
constexpr std::uint32_t kErrorClassIova = 5U;
constexpr std::uint32_t kErrorCodeLayout = 15U;
constexpr std::uint32_t kErrorCodeIova = 16U;

bool checked_mul_size(
        std::size_t lhs,
        std::size_t rhs,
        std::size_t * value) {
    if (value == nullptr ||
        (lhs != 0U && rhs > std::numeric_limits<std::size_t>::max() / lhs)) {
        return false;
    }
    *value = lhs * rhs;
    return true;
}

bool aligned_window(
        std::uint64_t logical_base,
        std::uint64_t logical_bytes,
        std::uint64_t * window_base,
        std::uint64_t * window_bytes) {
    if (window_base == nullptr || window_bytes == nullptr ||
        logical_bytes == 0U ||
        logical_bytes > std::numeric_limits<std::uint64_t>::max() -
                            logical_base) {
        return false;
    }
    *window_base = logical_base & ~std::uint64_t{7};
    const std::uint64_t logical_end = logical_base + logical_bytes;
    if (logical_end > std::numeric_limits<std::uint64_t>::max() - 7U) {
        return false;
    }
    const std::uint64_t rounded_end = (logical_end + 7U) &
                                      ~std::uint64_t{7};
    if (rounded_end <= *window_base) {
        return false;
    }
    *window_bytes = rounded_end - *window_base;
    return (*window_bytes & 7U) == 0U;
}

bool identity_valid(const npu_macro_identity & identity) {
    return identity.profile_id == 0U &&
           identity.command_flags == kCanonicalCommandFlags &&
           identity.context_id == kCanonicalContextId &&
           (identity.node_hash_lo != 0U || identity.node_hash_hi != 0U);
}

bool execute_impl(
        const std::uint32_t * logits_bits,
        std::size_t element_count,
        const npu_macro_identity * transaction_identity,
        npu_f32_argmax_self_test_mode mode,
        std::uint32_t * token_index,
        npu_verilator_f32_argmax_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (logits_bits == nullptr || element_count == 0U ||
        element_count > kMaximumElements || transaction_identity == nullptr ||
        !identity_valid(*transaction_identity) ||
        (mode == npu_f32_argmax_self_test_mode::positive &&
         token_index == nullptr)) {
        result->runner_error_code = 0x1c0U;
        return false;
    }

    std::size_t source_bytes = 0;
    if (!checked_mul_size(element_count, sizeof(std::uint32_t),
                          &source_bytes)) {
        result->runner_error_code = 0x1c0U;
        return false;
    }
    std::uint64_t src_window_base = 0;
    std::uint64_t src_window_bytes = 0;
    std::uint64_t dst_window_base = 0;
    std::uint64_t dst_window_bytes = 0;
    if (!aligned_window(kSrcIova, source_bytes, &src_window_base,
                        &src_window_bytes) ||
        !aligned_window(kDstIova, sizeof(std::uint32_t), &dst_window_base,
                        &dst_window_bytes)) {
        result->runner_error_code = 0x1c0U;
        return false;
    }

    std::array<std::uint8_t, sizeof(std::uint32_t)> private_dst = {
        0xa5U, 0xa5U, 0xa5U, 0xa5U,
    };
    std::array<std::uint8_t, sizeof(std::uint32_t)> expected_write = {
        1U, 1U, 1U, 1U,
    };

    npu_system_transaction transaction = {};
    transaction.manifest_profile_id = 0U;
    transaction.identity = *transaction_identity;
    npu_exact_command_contract & command = transaction.command;
    command.abi_valid = 1U;
    command.windows_generation_valid = 1U;
    command.kernel_id = kKernelF32Argmax;
    command.vector_op = 0U;
    command.local_profile = 0U;
    command.command_flags = transaction_identity->command_flags;
    command.context_id = transaction_identity->context_id;
    command.capability_epoch = kCapabilityEpoch;
    command.node_count = 1U;
    command.sequence_id = transaction_identity->sequence_id;
    command.producer_id = transaction_identity->producer_id;
    command.user_tag = transaction_identity->user_tag;
    command.node_hash_lo = transaction_identity->node_hash_lo;
    command.node_hash_hi = transaction_identity->node_hash_hi;
    command.src0_iova = kSrcIova;
    command.dst_iova = kDstIova;
    command.element_count = element_count;
    command.outer_count = 1U;
    command.dtype = kDtypeF32;
    command.src0_stride = 4U;
    command.dst_stride = 4U;
    command.src0_window_base = src_window_base;
    command.src0_window_size = src_window_bytes;
    command.src0_window_perm = 1U;
    command.dst_window_base = dst_window_base;
    command.dst_window_size = dst_window_bytes;
    command.dst_window_perm = 2U;

    transaction.sources[0] = {
        kSrcIova,
        reinterpret_cast<const std::uint8_t *>(logits_bits),
        nullptr,
        source_bytes,
        src_window_base,
        src_window_bytes,
        true,
        false,
    };
    transaction.destination = {
        kDstIova,
        nullptr,
        private_dst.data(),
        private_dst.size(),
        dst_window_base,
        dst_window_bytes,
        false,
        true,
    };
    transaction.expected_write_mask = expected_write.data();
    transaction.expected_write_mask_bytes = expected_write.size();
    transaction.expected_semantic_write_bytes = sizeof(std::uint32_t);
    transaction.expected_read_bytes = src_window_bytes;
    transaction.expected_write_bytes = sizeof(std::uint32_t);
    transaction.expected_vector_elements = element_count;
    transaction.expected_read_requests = src_window_bytes / 8U;
    transaction.expected_write_requests = 1U;
    transaction.expected_f32_starts = 0U;
    transaction.expected_required_issued = 1U;
    transaction.expected_required_completed = 1U;
    transaction.expected_public_completions = 1U;
    transaction.expected_public_errors = 0U;
    transaction.expected_macro_completions = 1U;
    transaction.cycle_upper_bound =
        1000000U + (transaction.expected_read_requests + 1U) * 32U;
    transaction.require_unique_read_beats = true;
    transaction.require_f32_halfbeat_wstrb = true;
    transaction.validate_source_read_requests = true;
    transaction.expected_source_read_requests = {
        transaction.expected_read_requests,
        0U,
    };

    if (mode != npu_f32_argmax_self_test_mode::positive) {
        expected_write.fill(0U);
        transaction.expected_semantic_write_bytes = 0U;
        transaction.expected_read_bytes = 0U;
        transaction.expected_write_bytes = 0U;
        transaction.expected_vector_elements = 0U;
        transaction.expected_read_requests = 0U;
        transaction.expected_write_requests = 0U;
        transaction.expected_required_completed = 0U;
        transaction.expected_public_completions = 0U;
        transaction.expected_public_errors = 1U;
        transaction.expected_macro_completions = 0U;
        transaction.expect_success = false;
        transaction.require_unique_read_beats = false;
        transaction.require_f32_halfbeat_wstrb = false;
        transaction.validate_source_read_requests = true;
        transaction.expected_source_read_requests = {0U, 0U};
        if (mode == npu_f32_argmax_self_test_mode::invalid_stride) {
            command.src0_stride = 8U;
            transaction.expected_status = kErrorCodeLayout;
            transaction.expected_error_class = kErrorClassLayout;
            transaction.expected_error_code = kErrorCodeLayout;
        } else if (mode ==
                   npu_f32_argmax_self_test_mode::invalid_window) {
            if (command.src0_window_size < 16U) {
                result->runner_error_code = 0x1c0U;
                return false;
            }
            command.src0_window_size -= 8U;
            transaction.sources[0].window_bytes = command.src0_window_size;
            transaction.expected_status = kErrorCodeIova;
            transaction.expected_error_class = kErrorClassIova;
            transaction.expected_error_code = kErrorCodeIova;
        } else if (mode == npu_f32_argmax_self_test_mode::overlap) {
            command.dst_iova = kSrcIova;
            command.dst_window_base = src_window_base;
            command.dst_window_size = 8U;
            transaction.destination.region_base = kSrcIova;
            transaction.destination.window_base = src_window_base;
            transaction.destination.window_bytes = 8U;
            transaction.expected_status = kErrorCodeIova;
            transaction.expected_error_class = kErrorClassIova;
            transaction.expected_error_code = kErrorCodeIova;
        } else {
            result->runner_error_code = 0x1c0U;
            return false;
        }
    }

    const bool executed = npu_verilator_execute_system_transaction(
        &transaction, result);
    if (!executed || !result->passed) {
        return false;
    }
    if (mode != npu_f32_argmax_self_test_mode::positive) {
        return result->controlled_reject &&
               !result->private_shadow_committed &&
               result->result_bytes == 0U;
    }
    if (result->controlled_reject || !result->private_shadow_committed ||
        result->result_bytes != sizeof(std::uint32_t)) {
        result->passed = false;
        result->runner_error_code = 0x1c1U;
        return false;
    }
    std::memcpy(token_index, private_dst.data(), sizeof(*token_index));
    return true;
}

} // namespace

bool npu_verilator_execute_f32_argmax(
        const std::uint32_t * logits_bits,
        std::size_t element_count,
        const npu_macro_identity * transaction_identity,
        std::uint32_t * token_index,
        npu_verilator_f32_argmax_result * result) {
    return execute_impl(
        logits_bits, element_count, transaction_identity,
        npu_f32_argmax_self_test_mode::positive, token_index, result);
}

bool npu_verilator_run_f32_argmax_self_test(
        npu_f32_argmax_self_test_mode mode,
        npu_verilator_f32_argmax_result * result) {
    static constexpr std::array<std::uint32_t, 4> kInput = {
        0x3f800000U, // +1.0
        0x40400000U, // +3.0, expected winner
        0x40000000U, // +2.0
        0xbf800000U, // -1.0
    };
    const npu_macro_identity identity = {
        0U,
        kCanonicalCommandFlags,
        kCanonicalContextId,
        0x6172676d61780001ULL,
        0x6172676d61780002ULL,
        0x6172676d61780003ULL,
        0x6172676d61780004ULL,
        0x6172676d61780005ULL,
    };
    std::uint32_t token = 0xffffffffU;
    const bool executed = execute_impl(
        kInput.data(), kInput.size(), &identity, mode, &token, result);
    if (!executed) {
        return false;
    }
    if (mode == npu_f32_argmax_self_test_mode::positive && token != 1U) {
        result->passed = false;
        result->runner_error_code = 0x1c2U;
        return false;
    }
    return true;
}
