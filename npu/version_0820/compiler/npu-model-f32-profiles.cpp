#include "npu-verilator-runner.h"
#include <limits>
namespace {
constexpr std::uint32_t kRepresentativeCommandFlags = 0x00000010U;
constexpr std::uint32_t kMacroCapabilityEpoch = 0x00000001U;
constexpr std::uint32_t kMacroContextId = 0x13579bdfU;
constexpr std::uint64_t kMacroSequenceId = 0x0123456789abcdefULL;
constexpr std::uint64_t kMacroProducerId = 0xfedcba9876543210ULL;
constexpr std::uint64_t kMacroUserTag = 0x55aa55aa12345678ULL;
constexpr std::uint64_t kMacroNodeHashLo = 0x243f6a8885a308d3ULL;
constexpr std::uint64_t kMacroNodeHashHi = 0x13198a2e03707344ULL;

constexpr std::uint32_t kRepresentativeContextBase = 0x52500000U;
constexpr std::uint64_t kRepresentativeSequenceBase =
    0x5250524550000000ULL;
constexpr std::uint64_t kRepresentativeProducerBase =
    0x5250524f44000000ULL;
constexpr std::uint64_t kRepresentativeUserTagBase =
    0x5250544147000000ULL;
constexpr std::uint64_t kRepresentativeNodeHashLoBase =
    0x9e3779b97f4a7c15ULL;
constexpr std::uint64_t kRepresentativeNodeHashHiBase =
    0xd1b54a32d192ed03ULL;

constexpr npu_f32_alu_tensor_descriptor f32_tensor(
        std::array<std::uint32_t, 4> ne,
        std::array<std::uint64_t, 4> nb,
        std::uint64_t view_off = 0,
        bool view_present = false) {
    return {ne, nb, view_off, view_present};
}

constexpr std::uint64_t f32_source_address(
        const npu_f32_alu_tensor_descriptor & source,
        std::uint32_t coordinate0,
        std::uint32_t coordinate1,
        std::uint32_t coordinate2,
        std::uint32_t coordinate3) {
    return source.view_off +
           static_cast<std::uint64_t>(coordinate0 % source.ne[0]) *
               source.nb[0] +
           static_cast<std::uint64_t>(coordinate1 % source.ne[1]) *
               source.nb[1] +
           static_cast<std::uint64_t>(coordinate2 % source.ne[2]) *
               source.nb[2] +
           static_cast<std::uint64_t>(coordinate3 % source.ne[3]) *
               source.nb[3];
}

constexpr std::uint64_t f32_expected_read_requests(
        const npu_f32_alu_tensor_descriptor & dst,
        const npu_f32_alu_tensor_descriptor & src0,
        bool src1_present,
        const npu_f32_alu_tensor_descriptor & src1) {
    const std::uint64_t total =
        static_cast<std::uint64_t>(dst.ne[0]) * dst.ne[1] *
        dst.ne[2] * dst.ne[3];
    if (!src1_present) {
        return total;
    }

    bool src0_cache_valid = false;
    bool src1_cache_valid = false;
    std::uint64_t src0_cache_tag = 0;
    std::uint64_t src1_cache_tag = 0;
    std::uint64_t read_requests = 0;
    // Nested loops make destination dimension 0 the fastest-moving
    // coordinate, exactly matching the RTL's row-major flat-index walk.
    for (std::uint32_t coordinate3 = 0; coordinate3 < dst.ne[3];
         ++coordinate3) {
        for (std::uint32_t coordinate2 = 0; coordinate2 < dst.ne[2];
             ++coordinate2) {
            for (std::uint32_t coordinate1 = 0; coordinate1 < dst.ne[1];
                 ++coordinate1) {
                for (std::uint32_t coordinate0 = 0;
                     coordinate0 < dst.ne[0]; ++coordinate0) {
                    const std::uint64_t src0_tag =
                        f32_source_address(
                            src0, coordinate0, coordinate1,
                            coordinate2, coordinate3) >> 3;
                    const std::uint64_t src1_tag =
                        f32_source_address(
                            src1, coordinate0, coordinate1,
                            coordinate2, coordinate3) >> 3;
                    const bool src0_hit =
                        src0_cache_valid && src0_cache_tag == src0_tag;
                    const bool src1_hit =
                        src1_cache_valid && src1_cache_tag == src1_tag;
                    if (src0_hit && src1_hit) {
                        continue;
                    }

                    // A single-source hit deliberately follows the canonical
                    // two-read fallback; both caches refill on those reads.
                    read_requests += 2;
                    src0_cache_valid = true;
                    src1_cache_valid = true;
                    src0_cache_tag = src0_tag;
                    src1_cache_tag = src1_tag;
                }
            }
        }
    }
    return read_requests;
}

constexpr npu_f32_alu_profile f32_profile(
        std::uint32_t profile_id,
        std::uint32_t vector_op,
        std::uint32_t scalar0,
        bool src1_present,
        npu_f32_alu_tensor_descriptor dst,
        npu_f32_alu_tensor_descriptor src0,
        npu_f32_alu_tensor_descriptor src1 = {}) {
    const std::uint64_t outer =
        static_cast<std::uint64_t>(dst.ne[1]) * dst.ne[2] * dst.ne[3];
    const std::uint64_t total =
        static_cast<std::uint64_t>(dst.ne[0]) * outer;
    return {
        profile_id, vector_op, scalar0, src1_present, dst, src0, src1,
        dst.ne[0], outer, total,
        // Physical reads depend on the command-local pair-cache walk and are
        // filled by the independent derived profile table below.
        0ULL,
        4ULL * total,
        32ULL + (src1_present ? 565ULL : 548ULL) * total,
    };
}

constexpr auto kT16 = f32_tensor(
    {16, 1, 1, 1}, {4, 64, 64, 64});
constexpr auto kT1024 = f32_tensor(
    {1024, 1, 1, 1}, {4, 4096, 4096, 4096});
constexpr auto kT128x128x16 = f32_tensor(
    {128, 128, 16, 1}, {4, 512, 65536, 1048576});
constexpr auto kT128x1x16 = f32_tensor(
    {128, 1, 16, 1}, {4, 512, 512, 8192});
constexpr auto kT128x16 = f32_tensor(
    {128, 16, 1, 1}, {4, 512, 8192, 8192});

constexpr std::array<npu_f32_alu_profile, 19> kF32AluProfiles = {{
    f32_profile(0, 1, 0, true, kT16,
        f32_tensor({16,1,1,1},{4,64,64,64},0,true), kT16),
    f32_profile(1, 1, 0, true, kT1024, kT1024, kT1024),
    f32_profile(2, 1, 0, true, kT1024,
        f32_tensor({1024,1,1,1},{4,4096,4096,4096},0,true), kT1024),
    f32_profile(3, 1, 0, true, kT128x128x16,
        kT128x128x16, kT128x128x16),
    f32_profile(4, 2, 0, true, kT16, kT16, kT16),
    f32_profile(5, 2, 0, true, kT1024, kT1024, kT1024),
    f32_profile(6, 2, 0, true, kT128x128x16, kT128x128x16,
        f32_tensor({128,1,16,1},{4,8192,512,8192},0,true)),
    f32_profile(7, 2, 0, true, kT128x1x16, kT128x1x16,
        f32_tensor({1,1,16,1},{4,4,4,64},0,true)),
    f32_profile(8, 2, 0, true, kT128x128x16, kT128x128x16,
        f32_tensor({1,128,16,1},{512,4,512,8192},0,true)),
    f32_profile(9, 2, 0, true, kT128x128x16,
        f32_tensor({128,128,16,1},{4,512,65536,1048576},0,true),
        f32_tensor({1,1,16,1},{4,4,4,64})),
    f32_profile(10, 2, 0, true, kT128x16, kT128x16,
        f32_tensor({128,1,1,1},{4,512,512,512})),
    f32_profile(11, 2, 0, true, kT128x16, kT128x16, kT128x16),
    f32_profile(12, 2, 0, true,
        f32_tensor({2048,1,1,1},{4,8192,8192,8192}),
        f32_tensor({2048,1,1,1},{4,8192,8192,8192}),
        f32_tensor({2048,1,1,1},{4,8192,8192,8192})),
    f32_profile(13, 2, 0, true,
        f32_tensor({256,2,1,1},{4,1024,2048,2048}),
        f32_tensor({256,2,1,1},{4,1024,2048,2048}),
        f32_tensor({256,1,1,1},{4,1024,1024,1024})),
    f32_profile(14, 2, 0, true,
        f32_tensor({256,8,1,1},{4,1024,8192,8192}),
        f32_tensor({256,8,1,1},{4,1024,8192,8192}),
        f32_tensor({256,1,1,1},{4,1024,1024,1024})),
    f32_profile(15, 3, 0, true, kT128x1x16,
        f32_tensor({128,1,16,1},{4,24576,512,24576},16384,true),
        f32_tensor({128,1,16,1},{4,4,512,8192},0,true)),
    f32_profile(16, 4, 0x3db504f3U, false, kT128x16, kT128x16),
    f32_profile(17, 4, 0, false,
        f32_tensor({18432,1,1,1},{4,73728,73728,73728},0,true),
        f32_tensor({18432,1,1,1},{4,73728,73728,73728},0,true)),
    f32_profile(18, 4, 0, false,
        f32_tensor({262144,1,1,1},{4,1048576,1048576,1048576},0,true),
        f32_tensor({262144,1,1,1},{4,1048576,1048576,1048576},0,true)),
}};

constexpr std::uint64_t kF32P00ExpectedReadRequests =
    f32_expected_read_requests(
        kF32AluProfiles[0].dst,
        kF32AluProfiles[0].src0,
        kF32AluProfiles[0].src1_present,
        kF32AluProfiles[0].src1);
static_assert(kF32P00ExpectedReadRequests * 8 == 128);
static_assert(kF32P00ExpectedReadRequests == 16);
static_assert(kF32P00ExpectedReadRequests +
              kF32AluProfiles[0].expected_write_bytes / 4 == 32);

const std::array<npu_f32_alu_profile, 19> & derived_f32_alu_profiles() {
    static const std::array<npu_f32_alu_profile, 19> profiles = [] {
        auto derived = kF32AluProfiles;
        for (auto & profile : derived) {
            const std::uint64_t read_requests = f32_expected_read_requests(
                profile.dst, profile.src0,
                profile.src1_present, profile.src1);
            profile.expected_read_bytes = 8ULL * read_requests;
        }
        return derived;
    }();
    return profiles;
}

bool checked_add_u64(
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

bool checked_mul_u64(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        (lhs != 0 && rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *result = lhs * rhs;
    return true;
}

bool source_span_checked(
        const npu_f32_alu_tensor_descriptor & descriptor,
        npu_f32_alu_span * span) {
    if (span == nullptr) {
        return false;
    }
    std::uint64_t logical_hi = descriptor.view_off;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (descriptor.ne[dimension] == 0) {
            return false;
        }
        std::uint64_t term = 0;
        if (!checked_mul_u64(descriptor.ne[dimension] - 1,
                             descriptor.nb[dimension], &term) ||
            !checked_add_u64(logical_hi, term, &logical_hi)) {
            return false;
        }
    }
    if (!checked_add_u64(logical_hi, 4, &logical_hi)) {
        return false;
    }
    std::uint64_t rounded = 0;
    if (!checked_add_u64(logical_hi, 7, &rounded)) {
        return false;
    }
    span->logical_hi = logical_hi;
    span->beat_lo = descriptor.view_off & ~std::uint64_t{7};
    span->beat_hi = rounded & ~std::uint64_t{7};
    return span->beat_lo < span->beat_hi;
}

constexpr npu_f32_alu_representative_identity representative_identity(
        std::uint32_t profile_id) {
    const std::uint64_t repeated_profile =
        (static_cast<std::uint64_t>(profile_id) << 32) | profile_id;
    return {
        profile_id,
        kRepresentativeCommandFlags,
        kRepresentativeContextBase | profile_id,
        kRepresentativeSequenceBase | profile_id,
        kRepresentativeProducerBase | profile_id,
        kRepresentativeUserTagBase | profile_id,
        kRepresentativeNodeHashLoBase ^ profile_id,
        kRepresentativeNodeHashHiBase ^ repeated_profile,
    };
}

}
bool npu_f32_alu_profile_by_id(
        std::uint32_t profile_id,
        npu_f32_alu_profile * profile) {
    const auto & profiles = derived_f32_alu_profiles();
    if (profile == nullptr || profile_id >= profiles.size()) {
        return false;
    }
    *profile = profiles[profile_id];
    return profile->profile_id == profile_id;
}
bool npu_f32_alu_representative_identity_by_profile(
        std::uint32_t profile_id,
        npu_f32_alu_representative_identity * identity) {
    if (identity == nullptr || profile_id >= kF32AluProfiles.size()) {
        return false;
    }
    *identity = representative_identity(profile_id);
    return identity->profile_id == profile_id &&
           identity->command_flags == kRepresentativeCommandFlags &&
           (identity->command_flags & 1U) == 0;
}
bool npu_f32_alu_source_span(
        const npu_f32_alu_tensor_descriptor & descriptor,
        npu_f32_alu_span * span) {
    return source_span_checked(descriptor, span);
}
