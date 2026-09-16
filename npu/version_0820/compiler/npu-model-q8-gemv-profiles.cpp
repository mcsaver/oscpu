#include "npu-verilator-runner.h"
#include <limits>
namespace {
constexpr std::uint32_t kKernelQ8Gemv = 0x514e0002U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCapabilityEpoch = 1;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kDtypeF32 = 1;
constexpr std::uint32_t kProfileCount = 10;
constexpr std::uint32_t kPortalRowLanes = 4;
constexpr std::uint32_t kPortalMacLanes = 32;
constexpr std::uint32_t kPortalBlockBytes = 34;
constexpr std::uint32_t kPortalResponseLatencyCycles = 2;

// Deliberately unaligned, disjoint 64-bit IOVAs exercise every aligned-beat
// endpoint proof in the public Coprocessor.  Logical allocation bytes are
// supplied directly by the caller; only the at-most-seven padding bytes in a
// registered window read as zero.
constexpr std::uint64_t kActivationIova = 0x0000000310000004ULL;
constexpr std::uint64_t kWeightIova = 0x0000000520000002ULL;
constexpr std::uint64_t kDstIova = 0x0000000730000004ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;
constexpr std::uint64_t kMinimumCycleUpperBound = 10000000ULL;
constexpr std::uint64_t kMaximumCycleUpperBound = 1100000000ULL;

enum gemv_runner_error : std::uint32_t {
    gemv_runner_ok = 0,
    gemv_runner_allocation = 0x160,
    gemv_runner_timeout = 0x161,
    gemv_runner_reset_interface = 0x162,
    gemv_runner_command_interface = 0x163,
    gemv_runner_request_protocol = 0x164,
    gemv_runner_response_protocol = 0x165,
    gemv_runner_completion_protocol = 0x166,
    gemv_runner_completion_identity = 0x167,
    gemv_runner_completion_framing = 0x168,
    gemv_runner_memory_bounds = 0x169,
    gemv_runner_result_coverage = 0x16a,
    gemv_runner_terminal_mismatch = 0x16b,
    gemv_runner_recovery = 0x16c,
    gemv_runner_profile = 0x16d,
};

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

bool checked_mul(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        (lhs != 0 &&
         rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *result = lhs * rhs;
    return true;
}

bool aligned_window(
        std::uint64_t logical_base,
        std::uint64_t logical_bytes,
        std::uint64_t * window_base,
        std::uint64_t * window_bytes) {
    if (window_base == nullptr || window_bytes == nullptr) {
        return false;
    }
    *window_base = logical_base & ~std::uint64_t{7};
    if (logical_bytes == 0) {
        *window_bytes = 0;
        return true;
    }
    std::uint64_t logical_end = 0;
    std::uint64_t rounded_end = 0;
    if (!checked_add(logical_base, logical_bytes, &logical_end) ||
        !checked_add(logical_end, 7, &rounded_end)) {
        return false;
    }
    rounded_end &= ~std::uint64_t{7};
    if (rounded_end <= *window_base) {
        return false;
    }
    *window_bytes = rounded_end - *window_base;
    return (*window_bytes & 7U) == 0;
}

bool finalize_profile(npu_q8_gemv_profile * profile) {
    if (profile == nullptr || profile->profile_id >= kProfileCount ||
        profile->k < 32 || profile->k > 4096 ||
        (profile->k & 31U) != 0 ||
        profile->m < 1 || profile->m > 248320 ||
        (profile->command_rows != 0 && profile->command_rows != profile->m) ||
        profile->block_count != profile->k / 32 ||
        profile->dst_row_stride != 4) {
        return false;
    }
    std::uint64_t activation_bytes = 0;
    std::uint64_t weight_row_bytes = 0;
    std::uint64_t weight_bytes = 0;
    std::uint64_t dst_bytes = 0;
    if (!checked_mul(profile->k, 4, &activation_bytes) ||
        !checked_mul(profile->block_count, 34, &weight_row_bytes) ||
        !checked_mul(profile->m, weight_row_bytes, &weight_bytes) ||
        !checked_mul(profile->m, 4, &dst_bytes) ||
        profile->activation_bytes != activation_bytes ||
        profile->weight_row_stride != weight_row_bytes ||
        profile->weight_bytes != weight_bytes ||
        profile->dst_bytes != dst_bytes) {
        return false;
    }

    const bool empty = profile->command_rows == 0;
    const std::uint64_t transfer_activation_bytes =
        empty ? 0 : activation_bytes;
    std::uint64_t transfer_weight_bytes = 0;
    std::uint64_t transfer_dst_bytes = 0;
    std::uint64_t transfer_q8_macs = 0;
    if (!checked_mul(profile->command_rows, weight_row_bytes,
                     &transfer_weight_bytes) ||
        !checked_mul(profile->command_rows, 4, &transfer_dst_bytes) ||
        !checked_mul(profile->command_rows, profile->k,
                     &transfer_q8_macs)) {
        return false;
    }

    std::uint64_t activation_window_base = 0;
    std::uint64_t activation_window_bytes = 0;
    std::uint64_t weight_window_base = 0;
    std::uint64_t weight_window_bytes = 0;
    std::uint64_t dst_window_base = 0;
    std::uint64_t dst_window_bytes = 0;
    if (!aligned_window(
            kActivationIova, transfer_activation_bytes,
            &activation_window_base, &activation_window_bytes) ||
        !aligned_window(
            kWeightIova, transfer_weight_bytes,
            &weight_window_base, &weight_window_bytes) ||
        !aligned_window(
            kDstIova, transfer_dst_bytes,
            &dst_window_base, &dst_window_bytes)) {
        return false;
    }
    // The bases are used here to make accidental mapping changes visible to
    // static analysis even though only the spans feed expected traffic.
    if ((activation_window_base & 7U) != 0 ||
        (weight_window_base & 7U) != 0 ||
        (dst_window_base & 7U) != 0 ||
        dst_window_bytes < transfer_dst_bytes) {
        return false;
    }

    std::uint64_t work = 0;
    std::uint64_t scaled_work = 0;
    std::uint64_t derived_cycle_bound = 0;
    if (!checked_mul(profile->command_rows, profile->block_count, &work) ||
        !checked_mul(work, 1024, &scaled_work) ||
        !checked_add(1000000, scaled_work, &derived_cycle_bound)) {
        derived_cycle_bound = kMaximumCycleUpperBound;
    }
    if (derived_cycle_bound < kMinimumCycleUpperBound) {
        derived_cycle_bound = kMinimumCycleUpperBound;
    }
    if (derived_cycle_bound > kMaximumCycleUpperBound) {
        derived_cycle_bound = kMaximumCycleUpperBound;
    }

    // Portal-enabled production never reports packed Q8 weight copies as raw
    // GMEM traffic.  The completion byte ledger records the physical aligned
    // activation window; the deliberately half-beat IOVA therefore exposes
    // one extra eight-byte read.  Logical K*4 payload coverage is proved by
    // the adapter's separate activation-word contract.
    profile->expected_read_bytes = activation_window_bytes;
    profile->expected_write_bytes = transfer_dst_bytes;
    profile->expected_read_requests = activation_window_bytes / 8U;
    profile->expected_write_requests = profile->command_rows;
    profile->expected_q8_macs = transfer_q8_macs;
    profile->expected_elements = profile->command_rows;
    profile->cycle_upper_bound = derived_cycle_bound;
    return true;
}



}
bool npu_q8_gemv_finalize_profile(npu_q8_gemv_profile * profile) {
    return finalize_profile(profile);
}
