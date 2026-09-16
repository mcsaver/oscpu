#include "npu-verilator-runner.h"
#include <limits>
namespace {
constexpr std::uint32_t kKernelGetRowsF32 = 0x514e0003U;
constexpr std::uint32_t kKernelRepeatF32 = 0x514e0004U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kDtypeF32 = 1U;
constexpr std::uint64_t kSrcIova = 0x0000000810000004ULL;
constexpr std::uint64_t kIndexIova = 0x0000000920000004ULL;
constexpr std::uint64_t kDstIova = 0x0000000a30000004ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;
constexpr std::uint64_t kMinimumCycleUpperBound = 10000000ULL;
constexpr std::uint64_t kMaximumCycleUpperBound = 1000000000ULL;

enum mover_runner_error : std::uint32_t {
    mover_runner_ok = 0,
    mover_runner_allocation = 0x180,
    mover_runner_timeout = 0x181,
    mover_runner_reset_interface = 0x182,
    mover_runner_command_interface = 0x183,
    mover_runner_request_protocol = 0x184,
    mover_runner_response_protocol = 0x185,
    mover_runner_completion_protocol = 0x186,
    mover_runner_completion_identity = 0x187,
    mover_runner_completion_framing = 0x188,
    mover_runner_memory_bounds = 0x189,
    mover_runner_result_coverage = 0x18a,
    mover_runner_terminal_mismatch = 0x18b,
    mover_runner_recovery = 0x18c,
    mover_runner_profile = 0x18d,
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

bool semantic_span(
        std::uint64_t count,
        std::uint64_t stride,
        std::uint64_t row_bytes,
        std::uint64_t * result) {
    if (count == 0 || result == nullptr) {
        return false;
    }
    std::uint64_t prefix = 0;
    return checked_mul(count - 1, stride, &prefix) &&
           checked_add(prefix, row_bytes, result);
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

bool finalize_profile(npu_f32_mover_profile * profile) {
    if (profile == nullptr || profile->profile_id >= 6 ||
        profile->element_count < 1 || profile->element_count > 262144) {
        return false;
    }
    std::uint64_t row_bytes = 0;
    if (!checked_mul(profile->element_count, 4, &row_bytes) ||
        profile->src_row_stride < row_bytes ||
        profile->dst_row_stride < row_bytes ||
        (profile->src_row_stride & 3U) != 0 ||
        (profile->index_stride & 3U) != 0 ||
        (profile->dst_row_stride & 3U) != 0 ||
        (profile->dst_outer_stride & 3U) != 0) {
        return false;
    }

    std::uint64_t expected_src_bytes = 0;
    std::uint64_t expected_index_bytes = 0;
    std::uint64_t expected_dst_bytes = 0;
    std::uint64_t source_words = 0;
    std::uint64_t total_elements = 0;
    std::uint64_t read_requests = 0;
    if (profile->owner == npu_f32_mover_owner::get_rows) {
        if (profile->index_count > 16 || profile->outer_count != 0 ||
            profile->repeat_count != 0 || profile->dst_outer_stride != 0 ||
            profile->index_stride < 4 ||
            (profile->index_count != 0 && profile->source_row_count < 1) ||
            !semantic_span(1, profile->src_row_stride, row_bytes,
                           &expected_src_bytes)) {
            return false;
        }
        if (profile->index_count == 0) {
            expected_index_bytes = 0;
            expected_dst_bytes = 0;
            source_words = 0;
            total_elements = 0;
            read_requests = 0;
        } else {
            if (!semantic_span(
                    profile->source_row_count, profile->src_row_stride,
                    row_bytes, &expected_src_bytes) ||
                !semantic_span(
                    profile->index_count, profile->index_stride, 4,
                    &expected_index_bytes) ||
                !semantic_span(
                    profile->index_count, profile->dst_row_stride, row_bytes,
                    &expected_dst_bytes) ||
                !checked_mul(profile->element_count, profile->index_count,
                             &source_words) ||
                !checked_add(source_words, profile->index_count,
                             &read_requests)) {
                return false;
            }
            total_elements = source_words;
        }
    } else if (profile->owner == npu_f32_mover_owner::repeat) {
        if (profile->source_row_count != 0 || profile->index_count != 0 ||
            profile->outer_count < 1 || profile->outer_count > 16 ||
            profile->repeat_count < 1 || profile->repeat_count > 128 ||
            profile->index_stride != 0) {
            return false;
        }
        std::uint64_t repeat_plane = 0;
        std::uint64_t repeat_prefix = 0;
        if (!checked_mul(
                profile->repeat_count - 1, profile->dst_row_stride,
                &repeat_prefix) ||
            !checked_add(repeat_prefix, row_bytes, &repeat_plane) ||
            profile->dst_outer_stride < repeat_plane ||
            !semantic_span(
                profile->outer_count, profile->src_row_stride, row_bytes,
                &expected_src_bytes) ||
            !semantic_span(
                profile->outer_count, profile->dst_outer_stride, repeat_plane,
                &expected_dst_bytes) ||
            !checked_mul(profile->element_count, profile->outer_count,
                         &source_words) ||
            !checked_mul(source_words, profile->repeat_count,
                         &total_elements)) {
            return false;
        }
        expected_index_bytes = 0;
        read_requests = source_words;
    } else {
        return false;
    }
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    if (!checked_mul(read_requests, 4, &expected_read_bytes) ||
        !checked_mul(total_elements, 4, &expected_write_bytes) ||
        profile->src_bytes != expected_src_bytes ||
        profile->index_bytes != expected_index_bytes ||
        profile->dst_bytes != expected_dst_bytes) {
        return false;
    }

    std::uint64_t request_count = 0;
    std::uint64_t scaled = 0;
    std::uint64_t bound = 0;
    if (!checked_add(read_requests, total_elements, &request_count) ||
        !checked_mul(request_count, 16, &scaled) ||
        !checked_add(1000000, scaled, &bound)) {
        bound = kMaximumCycleUpperBound;
    }
    if (bound < kMinimumCycleUpperBound) {
        bound = kMinimumCycleUpperBound;
    }
    if (bound > kMaximumCycleUpperBound) {
        bound = kMaximumCycleUpperBound;
    }
    profile->expected_read_bytes = expected_read_bytes;
    profile->expected_write_bytes = expected_write_bytes;
    profile->expected_elements = total_elements;
    profile->expected_read_requests = read_requests;
    profile->expected_write_requests = total_elements;
    profile->cycle_upper_bound = bound;
    return true;
}



}
bool npu_f32_mover_finalize_profile(npu_f32_mover_profile * profile) {
    return finalize_profile(profile);
}
