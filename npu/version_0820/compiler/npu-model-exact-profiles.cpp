#include "npu-verilator-runner.h"
#include <limits>
#include <cstring>
namespace {
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kMacroDtypeF32 = 1U;
constexpr std::uint64_t kSrc0Iova = 0x0000000310000000ULL;
constexpr std::uint64_t kSrc1Iova = 0x0000000520000000ULL;
constexpr std::uint64_t kDstIova = 0x0000000730000000ULL;
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
bool checked_product(
        const std::array<std::int64_t, 4> & ne,
        std::uint64_t * product) {
    if (product == nullptr) {
        return false;
    }
    std::uint64_t value = 1;
    for (std::int64_t extent : ne) {
        if (extent < 0 ||
            !checked_mul(value, static_cast<std::uint64_t>(extent), &value)) {
            return false;
        }
    }
    *product = value;
    return true;
}

std::uint64_t type_bytes(std::uint32_t type_id) {
    switch (type_id) {
        case 0U:  // GGML_TYPE_F32
        case 26U: // GGML_TYPE_I32
            return 4;
        case 1U:  // GGML_TYPE_F16
            return 2;
        case 27U: // GGML_TYPE_I64
            return 8;
        default:
            return 0;
    }
}

bool tensor_span(
        const npu_exact_tensor_descriptor & descriptor,
        std::uint64_t * logical_low,
        std::uint64_t * logical_high) {
    if (logical_low == nullptr || logical_high == nullptr ||
        (!descriptor.view_present && descriptor.view_off != 0)) {
        return false;
    }
    const std::uint64_t width = type_bytes(descriptor.type_id);
    if (width == 0) {
        return false;
    }
    std::uint64_t count = 0;
    if (!checked_product(descriptor.ne, &count)) {
        return false;
    }
    *logical_low = descriptor.view_off;
    if (count == 0) {
        *logical_high = descriptor.view_off;
        return true;
    }
    std::uint64_t high = descriptor.view_off;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (descriptor.ne[dimension] <= 0) {
            return false;
        }
        std::uint64_t term = 0;
        if (!checked_mul(
                static_cast<std::uint64_t>(descriptor.ne[dimension] - 1),
                descriptor.nb[dimension], &term) ||
            !checked_add(high, term, &high)) {
            return false;
        }
    }
    return checked_add(high, width, logical_high);
}

bool descriptor_backing_floor(
        const npu_exact_tensor_descriptor & descriptor,
        std::uint64_t * backing_floor,
        bool * logically_empty = nullptr) {
    if (backing_floor == nullptr) {
        return false;
    }
    std::uint64_t low = 0;
    std::uint64_t high = 0;
    std::uint64_t count = 0;
    if (!tensor_span(descriptor, &low, &high) ||
        !checked_product(descriptor.ne, &count)) {
        return false;
    }
    std::uint64_t required = high;
    for (std::uint64_t stride : descriptor.nb) {
        if (stride > required) {
            required = stride;
        }
    }
    if ((required & 7U) != 0U) {
        return false;
    }
    *backing_floor = required;
    if (logically_empty != nullptr) {
        *logically_empty = count == 0;
    }
    return true;
}

bool effective_backing_bytes(
        const npu_exact_tensor_descriptor & descriptor,
        std::size_t supplied_bytes,
        std::uint64_t * effective_bytes) {
    if (effective_bytes == nullptr) {
        return false;
    }
    std::uint64_t floor = 0;
    bool logically_empty = false;
    if (!descriptor_backing_floor(
            descriptor, &floor, &logically_empty)) {
        return false;
    }
    const std::uint64_t supplied =
        static_cast<std::uint64_t>(supplied_bytes);
    if (supplied != 0 && (supplied < floor || (supplied & 7U) != 0U)) {
        return false;
    }
    if (supplied == 0 && !logically_empty) {
        return false;
    }
    // A zero-element GGML tensor can report a zero logical byte count even
    // though the frozen public profile reserves a backing region (CPY's
    // empty-cache sentinels are the concrete case).  Advertising that frozen
    // raw region is safe because the exact owner emits no transaction for the
    // empty tensor; the host never fabricates tensor values.
    *effective_bytes = supplied == 0 ? floor : supplied;
    return (*effective_bytes & 7U) == 0U;
}

bool all_zero_after(
        const std::array<std::uint8_t, 64> & bytes,
        std::size_t first) {
    for (std::size_t index = first; index < bytes.size(); ++index) {
        if (bytes[index] != 0) {
            return false;
        }
    }
    return true;
}

std::uint32_t load_le32(
        const std::array<std::uint8_t, 64> & bytes,
        std::size_t offset = 0) {
    std::uint32_t value = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        value |= static_cast<std::uint32_t>(bytes[offset + index]) <<
                 (8 * index);
    }
    return value;
}

bool set_expected_route(
        npu_exact_profile * profile,
        std::uint32_t expected_global,
        std::uint32_t kernel,
        std::uint32_t operation,
        std::uint32_t local_profile) {
    if (profile == nullptr ||
        profile->manifest_profile_id != expected_global) {
        return false;
    }
    profile->public_kernel_id = kernel;
    profile->public_vector_op = operation;
    profile->public_local_profile = local_profile;
    return true;
}

bool resolve_public_route(npu_exact_profile * profile) {
    if (profile == nullptr || profile->manifest_profile_id >= 30U) {
        return false;
    }
    const std::uint32_t owner_profile = profile->owner_profile_id;
    switch (profile->owner) {
        case npu_exact_owner::unary: {
            static constexpr std::array<std::uint32_t, 6> kOperations = {
                15U, 13U, 10U, 7U, 10U, 7U,
            };
            static constexpr std::array<std::uint32_t, 6> kLocalProfiles = {
                2U, 5U, 4U, 0U, 3U, 1U,
            };
            return owner_profile < kOperations.size() &&
                   set_expected_route(
                       profile, owner_profile, 0x514e0005U,
                       kOperations[owner_profile],
                       kLocalProfiles[owner_profile]);
        }
        case npu_exact_owner::rms_norm: {
            static constexpr std::array<std::uint32_t, 5> kLocalProfiles = {
                0U, 1U, 0U, 3U, 2U,
            };
            return owner_profile < kLocalProfiles.size() &&
                   set_expected_route(
                       profile, 6U + owner_profile, 0x514e0011U, 4U,
                       kLocalProfiles[owner_profile]);
        }
        case npu_exact_owner::l2_norm:
            return owner_profile < 2U && set_expected_route(
                profile, 11U + owner_profile, 0x514e0011U, 5U, 4U);
        case npu_exact_owner::sum_rows:
            return owner_profile == 0U && set_expected_route(
                profile, 13U, 0x514e0011U, 1U, 0U);
        case npu_exact_owner::glu:
            return owner_profile == 0U && set_expected_route(
                profile, 14U, 0x514e0006U, 2U, 6U);
        case npu_exact_owner::ssm_conv:
            return owner_profile == 0U && set_expected_route(
                profile, 15U, 0x514e0022U, 76U, 0U);
        case npu_exact_owner::cpy:
            return owner_profile < 4U && set_expected_route(
                profile, 16U + owner_profile, 0x514e0007U, 34U,
                3U + owner_profile);
        case npu_exact_owner::cont:
            return owner_profile < 2U && set_expected_route(
                profile, 20U + owner_profile, 0x514e0007U, 35U,
                1U + owner_profile);
        case npu_exact_owner::concat:
            return owner_profile == 0U && set_expected_route(
                profile, 22U, 0x514e0007U, 22U, 0U);
        case npu_exact_owner::set_rows:
            return owner_profile < 2U && set_expected_route(
                profile, 23U + owner_profile, 0x514e0008U, 42U,
                owner_profile == 0U ? 8U : 7U);
        case npu_exact_owner::f16_attention_mul_mat:
            return owner_profile < 2U && set_expected_route(
                profile, 25U + owner_profile, 0x514e0009U, 29U,
                owner_profile);
        case npu_exact_owner::rope:
            return owner_profile < 2U && set_expected_route(
                profile, 27U + owner_profile, 0x514e000aU, 48U,
                owner_profile);
        case npu_exact_owner::soft_max:
            return owner_profile == 0U && set_expected_route(
                profile, 29U, 0x514e0011U, 6U, 0U);
    }
    return false;
}

bool derive_expected_counters(npu_exact_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    std::uint64_t dst_count = 0;
    std::array<std::uint64_t, 3> source_counts = {};
    if (!checked_product(profile->dst.ne, &dst_count)) {
        return false;
    }
    for (std::uint32_t index = 0; index < profile->source_count; ++index) {
        if (!checked_product(profile->sources[index].ne,
                             &source_counts[index])) {
            return false;
        }
    }
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint64_t work = 0;
    std::uint64_t read_requests = 0;
    std::uint64_t write_requests = 0;
    switch (profile->owner) {
        case npu_exact_owner::unary:
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
            if (profile->source_count != 1U ||
                source_counts[0] != dst_count ||
                !checked_mul(dst_count, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            read_requests = dst_count;
            write_requests = dst_count;
            break;
        case npu_exact_owner::glu:
            if (profile->source_count != 2U ||
                source_counts[0] != dst_count ||
                source_counts[1] != dst_count ||
                !checked_mul(dst_count, 8, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            if (!checked_mul(dst_count, 2, &read_requests)) {
                return false;
            }
            write_requests = dst_count;
            break;
        case npu_exact_owner::sum_rows:
            if (profile->source_count != 1U ||
                !checked_mul(source_counts[0], 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes) ||
                (source_counts[0] & 1U) != 0) {
                return false;
            }
            work = source_counts[0];
            read_requests = source_counts[0] / 2;
            write_requests = dst_count;
            break;
        case npu_exact_owner::ssm_conv: {
            std::uint64_t source_total = 0;
            if (profile->source_count != 2U ||
                !checked_add(source_counts[0], source_counts[1],
                             &source_total) ||
                !checked_mul(source_total, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes) ||
                (source_total & 1U) != 0) {
                return false;
            }
            work = write_bytes;
            read_requests = source_total / 2;
            write_requests = dst_count;
            break;
        }
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
            if ((profile->owner == npu_exact_owner::cont &&
                 profile->source_count != 1U) ||
                (profile->owner != npu_exact_owner::cont &&
                 profile->source_count != 2U) ||
                !checked_mul(dst_count, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            read_requests = dst_count;
            write_requests = dst_count;
            break;
        case npu_exact_owner::set_rows:
            if (profile->source_count != 3U || dst_count != 131072U) {
                return false;
            }
            read_bytes = profile->owner_profile_id == 0U ? 2056U : 6144U;
            write_bytes = 1024U;
            work = 512U;
            read_requests = profile->owner_profile_id == 0U ? 513U : 1024U;
            write_requests = 512U;
            break;
        case npu_exact_owner::f16_attention_mul_mat:
            if (profile->source_count != 2U || dst_count != 2048U) {
                return false;
            }
            read_bytes = 1056768U;
            write_bytes = 8192U;
            work = 2048U;
            read_requests = 132096U;
            write_requests = 2048U;
            break;
        case npu_exact_owner::rope:
            if (profile->source_count != 2U ||
                (dst_count != 2048U && dst_count != 512U)) {
                return false;
            }
            read_requests = dst_count == 2048U ? 1026U : 258U;
            write_requests = dst_count == 2048U ? 1280U : 320U;
            if (!checked_mul(read_requests, 8, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            break;
        case npu_exact_owner::soft_max:
            if (profile->source_count != 2U || dst_count != 2048U) {
                return false;
            }
            read_bytes = 9216U;
            write_bytes = 8192U;
            work = 2048U;
            read_requests = 1152U;
            write_requests = 1024U;
            break;
    }

    std::uint64_t request_total = 0;
    std::uint64_t scaled = 0;
    std::uint64_t cycle_bound = 0;
    if (!checked_add(read_requests, write_requests, &request_total) ||
        !checked_mul(request_total, 128U, &scaled) ||
        !checked_add(2000000U, scaled, &cycle_bound)) {
        cycle_bound = 1500000000ULL;
    }
    if (cycle_bound > 1500000000ULL) {
        cycle_bound = 1500000000ULL;
    }
    profile->expected_read_bytes = read_bytes;
    profile->expected_write_bytes = write_bytes;
    profile->expected_elements = work;
    profile->expected_read_requests = read_requests;
    profile->expected_write_requests = write_requests;
    profile->expected_q8_macs = 0;
    profile->expected_state_updates = 0;
    profile->cycle_upper_bound = cycle_bound;
    return true;
}

bool validate_profile_metadata(const npu_exact_profile & profile) {
    static constexpr std::array<std::uint32_t, 13> kOpIds = {
        91U, 25U, 28U, 15U, 100U, 76U, 34U,
        35U, 22U, 42U, 29U, 48U, 46U,
    };
    const std::size_t owner_index =
        static_cast<std::size_t>(profile.owner);
    if (owner_index >= kOpIds.size() ||
        profile.dst.op_id != kOpIds[owner_index] ||
        profile.dst.flags != 16U ||
        profile.source_count < 1U || profile.source_count > 3U) {
        return false;
    }
    for (std::uint32_t index = profile.source_count;
         index < profile.sources.size(); ++index) {
        const auto & empty = profile.sources[index];
        if (empty.type_id != 0 || empty.op_id != 0 || empty.flags != 0 ||
            empty.view_present || empty.view_off != 0) {
            return false;
        }
    }
    switch (profile.owner) {
        case npu_exact_owner::unary:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) ==
                       profile.public_vector_op &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 0x358637bdU &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::sum_rows:
        case npu_exact_owner::ssm_conv:
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
            return profile.dst.type_id == 0U &&
                   all_zero_after(profile.dst.op_params, 0);
        case npu_exact_owner::glu:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 2U &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::set_rows:
            return profile.dst.type_id == 1U &&
                   profile.sources[0].type_id == 0U &&
                   profile.sources[1].type_id == 27U &&
                   profile.sources[2].type_id == 1U &&
                   all_zero_after(profile.dst.op_params, 0);
        case npu_exact_owner::f16_attention_mul_mat:
            return profile.dst.type_id == 0U &&
                   profile.sources[0].type_id == 1U &&
                   profile.sources[1].type_id == 0U &&
                   load_le32(profile.dst.op_params) ==
                       (profile.owner_profile_id == 0U ? 10U : 0U) &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::rope:
            return profile.dst.type_id == 0U &&
                   profile.sources[0].type_id == 0U &&
                   profile.sources[1].type_id == 26U;
        case npu_exact_owner::soft_max:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 0x3d800000U &&
                   all_zero_after(profile.dst.op_params, 8);
    }
    return false;
}


}
bool npu_exact_finalize_profile(npu_exact_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    npu_exact_profile candidate = *profile;
    if (!resolve_public_route(&candidate) ||
        !validate_profile_metadata(candidate) ||
        !derive_expected_counters(&candidate)) {
        return false;
    }
    std::uint64_t outer = 1;
    for (std::size_t dimension = 1; dimension < 4; ++dimension) {
        if (candidate.dst.ne[dimension] < 0 ||
            !checked_mul(
                outer,
                static_cast<std::uint64_t>(candidate.dst.ne[dimension]),
                &outer)) {
            return false;
        }
    }
    if (candidate.dst.ne[0] < 0 ||
        outer > std::numeric_limits<std::uint32_t>::max()) {
        return false;
    }
    *profile = candidate;
    return true;
}

bool npu_exact_build_command_contract(
        const npu_exact_profile * profile,
        const npu_macro_identity * canonical_identity,
        std::uint32_t set_rows_slot,
        const std::array<std::size_t, 3> * source_backing_bytes,
        std::size_t dst_backing_bytes,
        npu_exact_command_contract * command) {
    if (profile == nullptr || canonical_identity == nullptr ||
        source_backing_bytes == nullptr || command == nullptr) {
        return false;
    }
    npu_exact_profile checked = *profile;
    if (!npu_exact_finalize_profile(&checked) ||
        checked.public_kernel_id != profile->public_kernel_id ||
        checked.public_vector_op != profile->public_vector_op ||
        checked.public_local_profile != profile->public_local_profile ||
        canonical_identity->profile_id != checked.public_local_profile ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        (canonical_identity->sequence_id == 0 &&
         canonical_identity->producer_id == 0 &&
         canonical_identity->user_tag == 0 &&
         canonical_identity->node_hash_lo == 0 &&
         canonical_identity->node_hash_hi == 0) ||
        (checked.owner == npu_exact_owner::set_rows &&
         set_rows_slot >= 256U)) {
        return false;
    }
    for (std::size_t index = checked.source_count;
         index < source_backing_bytes->size(); ++index) {
        if ((*source_backing_bytes)[index] != 0) {
            return false;
        }
    }

    std::array<std::uint64_t, 3> effective_sources = {};
    for (std::size_t index = 0; index < checked.source_count; ++index) {
        if (!effective_backing_bytes(
                checked.sources[index], (*source_backing_bytes)[index],
                &effective_sources[index])) {
            return false;
        }
    }
    std::uint64_t effective_dst = 0;
    if (!effective_backing_bytes(
            checked.dst, dst_backing_bytes, &effective_dst) ||
        (checked.owner == npu_exact_owner::cpy &&
         effective_sources[1] != effective_dst) ||
        (checked.owner == npu_exact_owner::set_rows &&
         effective_sources[2] != effective_dst)) {
        return false;
    }

    std::uint64_t outer = 1;
    for (std::size_t dimension = 1; dimension < 4; ++dimension) {
        if (!checked_mul(
                outer,
                static_cast<std::uint64_t>(checked.dst.ne[dimension]),
                &outer)) {
            return false;
        }
    }
    std::uint64_t src0_iova = 0;
    std::uint64_t src1_iova = 0;
    std::uint64_t dst_iova = 0;
    if (!checked_add(kSrc0Iova, checked.sources[0].view_off,
                     &src0_iova) ||
        (checked.source_count >= 2U &&
         !checked_add(kSrc1Iova, checked.sources[1].view_off,
                      &src1_iova)) ||
        !checked_add(kDstIova, checked.dst.view_off, &dst_iova)) {
        return false;
    }

    std::uint64_t src2_stride = 0;
    switch (checked.owner) {
        case npu_exact_owner::unary:
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
        case npu_exact_owner::sum_rows:
        case npu_exact_owner::glu:
        case npu_exact_owner::ssm_conv:
            src2_stride = checked.sources[0].nb[2];
            break;
        case npu_exact_owner::set_rows:
            src2_stride = checked.dst.nb[1];
            break;
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
        case npu_exact_owner::f16_attention_mul_mat:
        case npu_exact_owner::rope:
        case npu_exact_owner::soft_max:
            src2_stride = 0;
            break;
    }

    std::uint32_t scalar0 = 0;
    switch (checked.owner) {
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
        case npu_exact_owner::f16_attention_mul_mat:
        case npu_exact_owner::soft_max:
            scalar0 = load_le32(checked.dst.op_params);
            break;
        case npu_exact_owner::set_rows:
            scalar0 = 256U;
            break;
        default:
            scalar0 = 0;
            break;
    }

    npu_exact_command_contract candidate = {};
    candidate.abi_valid = 1U;
    candidate.windows_generation_valid = 1U;
    candidate.kernel_id = checked.public_kernel_id;
    candidate.vector_op = checked.public_vector_op;
    candidate.local_profile = checked.public_local_profile;
    candidate.command_flags = canonical_identity->command_flags;
    candidate.context_id = canonical_identity->context_id;
    candidate.capability_epoch = kCapabilityEpoch;
    candidate.node_count = 1U;
    candidate.sequence_id = canonical_identity->sequence_id;
    candidate.producer_id = canonical_identity->producer_id;
    candidate.user_tag = canonical_identity->user_tag;
    candidate.node_hash_lo = canonical_identity->node_hash_lo;
    candidate.node_hash_hi = canonical_identity->node_hash_hi;
    candidate.deadline_cycles = 0;
    candidate.src0_iova = src0_iova;
    candidate.src1_iova =
        checked.source_count >= 2U ? src1_iova : 0;
    candidate.src2_iova =
        checked.owner == npu_exact_owner::set_rows ? dst_iova : 0;
    candidate.dst_iova = dst_iova;
    candidate.scratch_iova = 0;
    candidate.element_count =
        static_cast<std::uint64_t>(checked.dst.ne[0]);
    candidate.outer_count = static_cast<std::uint32_t>(outer);
    candidate.dtype = kMacroDtypeF32;
    candidate.src0_stride = checked.sources[0].nb[1];
    candidate.src1_stride = checked.source_count >= 2U ?
        checked.sources[1].nb[1] : 0;
    candidate.src2_stride = src2_stride;
    candidate.dst_stride = checked.dst.nb[1];
    candidate.scalar0 = scalar0;
    candidate.scalar1 =
        checked.owner == npu_exact_owner::set_rows ? set_rows_slot : 0;
    candidate.scratch_bytes = 0;
    candidate.rope_position = 0;
    candidate.src0_window_base = kSrc0Iova;
    candidate.src0_window_size = effective_sources[0];
    candidate.src0_window_perm = 1U;
    candidate.src1_window_base =
        checked.source_count >= 2U ? kSrc1Iova : 0;
    candidate.src1_window_size =
        checked.source_count >= 2U ? effective_sources[1] : 0;
    candidate.src1_window_perm = 1U;
    candidate.dst_window_base = kDstIova;
    candidate.dst_window_size = effective_dst;
    candidate.dst_window_perm = 2U;
    candidate.dst_shadow_readable =
        checked.owner == npu_exact_owner::set_rows;
    *command = candidate;
    return true;
}

