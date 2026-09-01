#include "npu-verilator-runner.h"

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
#include "VTensorNpuCoprocessor.h"
#include "verilated.h"
#endif

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <memory>
#include <vector>

namespace {

constexpr std::uint64_t kMm2Command = 0x0a5434db0200355bULL;
constexpr std::uint64_t kInputWord = 0x0000000004030201ULL;
constexpr std::uint64_t kWeightWord = 0x0000000008070605ULL;
constexpr std::uint64_t kExpectedOutput0 = 0x0000001600000013ULL;
constexpr std::uint64_t kExpectedOutput1 = 0x000000320000002bULL;
constexpr std::uint64_t kExpectedTiuCycles = 29;
constexpr std::uint64_t kExpectedOutputBytes = 16;
constexpr std::uint32_t kInputBase = 0;
constexpr std::uint32_t kWeightBase = 64;
constexpr std::uint32_t kOutputBase = 128;
constexpr std::uint64_t kMaxClockCycles = 512;

constexpr std::size_t kF32ElementCount = 16;
constexpr std::size_t kF32WindowBytes = 64;
constexpr std::uint64_t kF32Src0Base = 0x0000000000001000ULL;
constexpr std::uint64_t kF32Src1Base = 0x0000000000002000ULL;
constexpr std::uint64_t kF32DstBase = 0x0000000000003000ULL;
constexpr std::uint64_t kF32OutOfRangeBase = kF32Src0Base + 4;
constexpr std::uint64_t kF32MaxClockCycles = 8192;
constexpr std::uint64_t kF32AluMaxClockCycles = 220000000ULL;
constexpr std::uint64_t kF32AluSrc0Base = 0x0000000100000000ULL;
constexpr std::uint64_t kF32AluSrc1Base = 0x0000000200000000ULL;
constexpr std::uint64_t kF32AluDstBase = 0x0000000300000000ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr std::uint64_t kResponseLatencyBound = 16;
constexpr unsigned kCompletionBackpressureCycles = 4;

constexpr std::uint32_t kMacroKernelVectorF32 = 0x514e0010U;
constexpr std::uint32_t kMacroUnknownKernel = 0xdeadbeefU;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
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

constexpr std::uint32_t kCompletionMagic = 0x514e5043U;
constexpr std::uint16_t kCompletionAbiMajor = 1;
constexpr std::uint16_t kCompletionAbiMinorV1 = 0;
constexpr std::uint16_t kRepresentativeCompletionAbiMinor = 1;
constexpr std::uint16_t kCompletionSize = 128;

constexpr std::uint32_t kNpuErrMacroCapability = 14;
constexpr std::uint32_t kNpuErrMacroIova = 16;
constexpr std::uint32_t kNpuErrMacroTimeout = 17;
constexpr std::uint32_t kAbiErrorCapability = 3;
constexpr std::uint32_t kAbiErrorIova = 5;
constexpr std::uint32_t kAbiErrorTimeout = 10;

constexpr std::array<std::uint32_t, kF32ElementCount> kF32Input0 = {
    0x00000000U, 0x3f800000U, 0x40000000U, 0x40400000U,
    0x40800000U, 0x40a00000U, 0x40c00000U, 0x40e00000U,
    0xbf800000U, 0xc0000000U, 0xc0400000U, 0xc0800000U,
    0x41000000U, 0x41800000U, 0x42000000U, 0x42800000U,
};
constexpr std::array<std::uint32_t, kF32ElementCount> kF32Input1 = {
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
};
constexpr std::array<std::uint32_t, kF32ElementCount> kF32Expected = {
    0x3f800000U, 0x40000000U, 0x40400000U, 0x40800000U,
    0x40a00000U, 0x40c00000U, 0x40e00000U, 0x41000000U,
    0x00000000U, 0xbf800000U, 0xc0000000U, 0xc0400000U,
    0x41100000U, 0x41880000U, 0x42040000U, 0x42820000U,
};

// 冻结的四个 TR descriptor word：continuous layout，shape=(1,2,1,2)，
// 输入为 signed E8，输出为 signed E32。固定常量避免 host 侧生成 oracle。
constexpr std::array<std::uint64_t, 4> kInputDescriptor = {
    0x0810000000000000ULL,
    0x0001000200010002ULL,
    0x0000000200000001ULL,
    0x0000000400000002ULL,
};
constexpr std::array<std::uint64_t, 4> kWeightDescriptor = {
    0x0810000000000040ULL,
    0x0001000200010002ULL,
    0x0000000200000001ULL,
    0x0000000400000002ULL,
};
constexpr std::array<std::uint64_t, 4> kOutputDescriptor = {
    0x2810000000000080ULL,
    0x0001000200010002ULL,
    0x0000000200000001ULL,
    0x0000000400000002ULL,
};

enum runner_error : std::uint32_t {
    runner_ok = 0,
    runner_allocation = 0x100,
    runner_timeout = 0x101,
    runner_reset_interface = 0x102,
    runner_descriptor_interface = 0x103,
    runner_lmem_interface = 0x104,
    runner_command_interface = 0x105,
    runner_completion_interface = 0x106,
    runner_result_mismatch = 0x107,
    runner_counter_mismatch = 0x108,
    runner_f32_request_protocol = 0x109,
    runner_f32_response_protocol = 0x10a,
    runner_f32_completion_protocol = 0x10b,
    runner_f32_completion_identity = 0x10c,
    runner_f32_completion_framing = 0x10d,
    runner_f32_mode_mismatch = 0x10e,
    runner_f32_memory_bounds = 0x10f,
    runner_f32_recovery = 0x110,
    runner_f32_profile = 0x111,
    runner_f32_span = 0x112,
};

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

template <std::size_t N>
void store_le16(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint16_t value) {
    bytes[offset + 0] = static_cast<std::uint8_t>(value);
    bytes[offset + 1] = static_cast<std::uint8_t>(value >> 8);
}

template <std::size_t N>
void store_le32(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint32_t value) {
    for (std::size_t index = 0; index < 4; ++index) {
        bytes[offset + index] =
            static_cast<std::uint8_t>(value >> (index * 8));
    }
}

template <std::size_t N>
void store_le64(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint64_t value) {
    for (std::size_t index = 0; index < 8; ++index) {
        bytes[offset + index] =
            static_cast<std::uint8_t>(value >> (index * 8));
    }
}

template <std::size_t N>
std::uint16_t load_le16(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    return static_cast<std::uint16_t>(bytes[offset + 0]) |
           (static_cast<std::uint16_t>(bytes[offset + 1]) << 8);
}

template <std::size_t N>
std::uint32_t load_le32(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    std::uint32_t value = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        value |= static_cast<std::uint32_t>(bytes[offset + index])
                 << (index * 8);
    }
    return value;
}

template <std::size_t N>
std::uint64_t load_le64(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        value |= static_cast<std::uint64_t>(bytes[offset + index])
                 << (index * 8);
    }
    return value;
}

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
struct macro_submission {
    npu_f32_add_mode mode = npu_f32_add_mode::positive;
    std::uint32_t kernel_id = kMacroKernelVectorF32;
    std::uint32_t command_flags = kCanonicalCommandFlags;
    std::uint64_t src0_iova = kF32Src0Base;
    std::uint64_t src0_window_base = kF32Src0Base;
    std::uint32_t src0_window_perm = 1;
    std::uint32_t src1_window_perm = 1;
    std::uint32_t dst_window_perm = 2;

    explicit macro_submission(npu_f32_add_mode selected_mode)
        : mode(selected_mode) {
        if (mode == npu_f32_add_mode::unknown_kernel) {
            kernel_id = kMacroUnknownKernel;
        }
        if (mode == npu_f32_add_mode::out_of_range_4mod8) {
            src0_iova = kF32OutOfRangeBase;
            src0_window_base = kF32OutOfRangeBase;
        }
        if (mode == npu_f32_add_mode::overpermission) {
            // All descriptor fields remain valid; source0 RW is the only
            // mutation so the IOVA rejection proves exact least privilege.
            src0_window_perm = 3;
        }
    }
};

struct completion_snapshot {
    std::uint32_t legacy_producer_id = 0;
    std::uint32_t legacy_npu_required = 0;
    std::uint32_t legacy_opclass = 0;
    std::uint32_t error = 0;
    std::uint32_t error_code = 0;
    std::uint32_t is_macro = 0;
    std::uint32_t status = 0;
    std::uint32_t error_class = 0;
    std::uint32_t kernel_id = 0;
    std::uint32_t command_flags = 0;
    std::uint32_t vector_flags = 0;
    std::uint32_t context_id = 0;
    std::uint64_t sequence_id = 0;
    std::uint64_t producer_id = 0;
    std::uint64_t user_tag = 0;
    std::uint32_t covered_node_count = 0;
    std::uint64_t node_hash_lo = 0;
    std::uint64_t node_hash_hi = 0;
    std::uint64_t npu_cycles = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t vector_element_count = 0;
    std::uint64_t state_update_count = 0;

    bool operator==(const completion_snapshot & other) const {
        return legacy_producer_id == other.legacy_producer_id &&
               legacy_npu_required == other.legacy_npu_required &&
               legacy_opclass == other.legacy_opclass &&
               error == other.error &&
               error_code == other.error_code &&
               is_macro == other.is_macro &&
               status == other.status &&
               error_class == other.error_class &&
               kernel_id == other.kernel_id &&
               command_flags == other.command_flags &&
               vector_flags == other.vector_flags &&
               context_id == other.context_id &&
               sequence_id == other.sequence_id &&
               producer_id == other.producer_id &&
               user_tag == other.user_tag &&
               covered_node_count == other.covered_node_count &&
               node_hash_lo == other.node_hash_lo &&
               node_hash_hi == other.node_hash_hi &&
               npu_cycles == other.npu_cycles &&
               gmem_read_bytes == other.gmem_read_bytes &&
               gmem_write_bytes == other.gmem_write_bytes &&
               q8_mac_count == other.q8_mac_count &&
               vector_element_count == other.vector_element_count &&
               state_update_count == other.state_update_count;
    }
};

completion_snapshot capture_completion(const VTensorNpuCoprocessor & top) {
    completion_snapshot snapshot = {};
    snapshot.legacy_producer_id = top.completion_producer_id_o;
    snapshot.legacy_npu_required = top.completion_npu_required_o;
    snapshot.legacy_opclass = top.completion_opclass_o;
    snapshot.error = top.completion_error_o;
    snapshot.error_code = top.completion_error_code_o;
    snapshot.is_macro = top.completion_is_macro_o;
    snapshot.status = top.completion_macro_status_o;
    snapshot.error_class = top.completion_macro_error_class_o;
    snapshot.kernel_id = top.completion_macro_kernel_id_o;
    snapshot.command_flags = top.completion_macro_command_flags_o;
    snapshot.vector_flags = top.completion_macro_vector_flags_o;
    snapshot.context_id = top.completion_macro_context_id_o;
    snapshot.sequence_id = top.completion_macro_sequence_id_o;
    snapshot.producer_id = top.completion_macro_producer_id_o;
    snapshot.user_tag = top.completion_macro_user_tag_o;
    snapshot.covered_node_count =
        top.completion_macro_covered_node_count_o;
    snapshot.node_hash_lo = top.completion_macro_node_hash_lo_o;
    snapshot.node_hash_hi = top.completion_macro_node_hash_hi_o;
    snapshot.npu_cycles = top.completion_macro_npu_cycles_o;
    snapshot.gmem_read_bytes = top.completion_macro_gmem_read_bytes_o;
    snapshot.gmem_write_bytes = top.completion_macro_gmem_write_bytes_o;
    snapshot.q8_mac_count = top.completion_macro_q8_mac_count_o;
    snapshot.vector_element_count =
        top.completion_macro_vector_element_count_o;
    snapshot.state_update_count =
        top.completion_macro_state_update_count_o;
    return snapshot;
}

bool completion_identity_matches(
        const completion_snapshot & snapshot,
        const macro_submission & submission) {
    return snapshot.is_macro == 1 &&
           snapshot.legacy_producer_id == 0 &&
           snapshot.legacy_npu_required == (submission.command_flags & 1U) &&
           snapshot.legacy_opclass == 0 &&
           snapshot.kernel_id == submission.kernel_id &&
           snapshot.command_flags == submission.command_flags &&
           snapshot.context_id == kMacroContextId &&
           snapshot.sequence_id == kMacroSequenceId &&
           snapshot.producer_id == kMacroProducerId &&
           snapshot.user_tag == kMacroUserTag &&
           snapshot.covered_node_count == 1 &&
           snapshot.node_hash_lo == kMacroNodeHashLo &&
           snapshot.node_hash_hi == kMacroNodeHashHi;
}

using completion_record = std::array<std::uint8_t, kCompletionSize>;
static_assert(sizeof(completion_record) == 128,
              "completion v1/v4 framing must remain exactly 128 bytes");

completion_record serialize_completion(const completion_snapshot & snapshot) {
    completion_record record = {};
    store_le32(record, 0x00, kCompletionMagic);
    store_le16(record, 0x04, kCompletionAbiMajor);
    store_le16(record, 0x06, kCompletionAbiMinorV1);
    store_le16(record, 0x08, kCompletionSize);
    store_le16(record, 0x0a, 0);
    store_le32(record, 0x10, snapshot.error_class);
    store_le32(record, 0x14, snapshot.kernel_id);
    store_le32(record, 0x18, snapshot.command_flags);
    store_le32(record, 0x1c, snapshot.context_id);
    store_le64(record, 0x20, snapshot.sequence_id);
    store_le64(record, 0x28, snapshot.producer_id);
    store_le64(record, 0x30, snapshot.user_tag);
    store_le32(record, 0x38, snapshot.covered_node_count);
    store_le32(record, 0x3c, 0);
    store_le64(record, 0x40, snapshot.node_hash_lo);
    store_le64(record, 0x48, snapshot.node_hash_hi);
    store_le64(record, 0x50, snapshot.npu_cycles);
    store_le64(record, 0x58, snapshot.gmem_read_bytes);
    store_le64(record, 0x60, snapshot.gmem_write_bytes);
    store_le64(record, 0x68, snapshot.q8_mac_count);
    store_le64(record, 0x70, snapshot.vector_element_count);
    store_le64(record, 0x78, snapshot.state_update_count);
    // Terminal status is the publication field and is deliberately written
    // after framing, identity and counters.
    store_le32(record, 0x0c, snapshot.status);
    return record;
}

bool completion_framing_matches(
        const completion_record & record,
        const completion_snapshot & snapshot) {
    return load_le32(record, 0x00) == kCompletionMagic &&
           load_le16(record, 0x04) == kCompletionAbiMajor &&
           load_le16(record, 0x06) == kCompletionAbiMinorV1 &&
           load_le16(record, 0x08) == kCompletionSize &&
           load_le16(record, 0x0a) == 0 &&
           load_le32(record, 0x0c) == snapshot.status &&
           load_le32(record, 0x10) == snapshot.error_class &&
           load_le32(record, 0x14) == snapshot.kernel_id &&
           load_le32(record, 0x18) == snapshot.command_flags &&
           load_le32(record, 0x1c) == snapshot.context_id &&
           load_le64(record, 0x20) == snapshot.sequence_id &&
           load_le64(record, 0x28) == snapshot.producer_id &&
           load_le64(record, 0x30) == snapshot.user_tag &&
           load_le32(record, 0x38) == snapshot.covered_node_count &&
           load_le32(record, 0x3c) == 0 &&
           load_le64(record, 0x40) == snapshot.node_hash_lo &&
           load_le64(record, 0x48) == snapshot.node_hash_hi &&
           load_le64(record, 0x50) == snapshot.npu_cycles &&
           load_le64(record, 0x58) == snapshot.gmem_read_bytes &&
           load_le64(record, 0x60) == snapshot.gmem_write_bytes &&
           load_le64(record, 0x68) == snapshot.q8_mac_count &&
           load_le64(record, 0x70) == snapshot.vector_element_count &&
           load_le64(record, 0x78) == snapshot.state_update_count;
}

bool representative_profile_encodable(
        const completion_snapshot & snapshot) {
    return (snapshot.vector_flags & ~0x1fU) == 0 &&
           snapshot.vector_flags < kF32AluProfiles.size();
}

// v4 keeps the frozen 128-byte record.  A valid representative completion
// advances only the minor version and consumes the existing 16-bit reserved
// word for the RTL-returned profile; invalid-profile error completions retain
// the predecessor v1.0 zero-reserved framing.
completion_record serialize_representative_completion(
        const completion_snapshot & snapshot) {
    completion_record record = serialize_completion(snapshot);
    if (representative_profile_encodable(snapshot)) {
        store_le16(record, 0x06, kRepresentativeCompletionAbiMinor);
        store_le16(
            record, 0x0a,
            static_cast<std::uint16_t>(snapshot.vector_flags));
    }
    return record;
}

bool representative_completion_framing_matches(
        const completion_record & record,
        const completion_snapshot & snapshot) {
    const bool profile_encodable = representative_profile_encodable(snapshot);
    const std::uint16_t expected_minor = profile_encodable ?
        kRepresentativeCompletionAbiMinor : kCompletionAbiMinorV1;
    const std::uint16_t expected_profile = profile_encodable ?
        static_cast<std::uint16_t>(snapshot.vector_flags) : 0;
    return load_le32(record, 0x00) == kCompletionMagic &&
           load_le16(record, 0x04) == kCompletionAbiMajor &&
           load_le16(record, 0x06) == expected_minor &&
           load_le16(record, 0x08) == kCompletionSize &&
           load_le16(record, 0x0a) == expected_profile &&
           load_le32(record, 0x0c) == snapshot.status &&
           load_le32(record, 0x10) == snapshot.error_class &&
           load_le32(record, 0x14) == snapshot.kernel_id &&
           load_le32(record, 0x18) == snapshot.command_flags &&
           load_le32(record, 0x1c) == snapshot.context_id &&
           load_le64(record, 0x20) == snapshot.sequence_id &&
           load_le64(record, 0x28) == snapshot.producer_id &&
           load_le64(record, 0x30) == snapshot.user_tag &&
           load_le32(record, 0x38) == snapshot.covered_node_count &&
           load_le32(record, 0x3c) == 0 &&
           load_le64(record, 0x40) == snapshot.node_hash_lo &&
           load_le64(record, 0x48) == snapshot.node_hash_hi &&
           load_le64(record, 0x50) == snapshot.npu_cycles &&
           load_le64(record, 0x58) == snapshot.gmem_read_bytes &&
           load_le64(record, 0x60) == snapshot.gmem_write_bytes &&
           load_le64(record, 0x68) == snapshot.q8_mac_count &&
           load_le64(record, 0x70) == snapshot.vector_element_count &&
           load_le64(record, 0x78) == snapshot.state_update_count;
}

class coprocessor_harness {
public:
    explicit coprocessor_harness(npu_verilator_self_test_result * result)
        : result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())) {
        drive_idle_inputs();
        top_->eval();
    }

    ~coprocessor_harness() {
        top_->final();
    }

    bool run() {
        if (!reset()) {
            return false;
        }
        if (!write_descriptor(8, kOutputDescriptor) ||
            !write_descriptor(9, kInputDescriptor) ||
            !write_descriptor(10, kWeightDescriptor)) {
            return false;
        }
        if (!write_lmem(kInputBase, kInputWord) ||
            !write_lmem(kWeightBase, kWeightWord) ||
            !write_lmem(kOutputBase, 0xdeadbeefdeadbeefULL) ||
            !write_lmem(kOutputBase + 8, 0xdeadbeefdeadbeefULL)) {
            return false;
        }
        if (!run_mm2_command()) {
            return false;
        }

        std::uint64_t output0 = 0;
        std::uint64_t output1 = 0;
        if (!read_lmem(kOutputBase, &output0) ||
            !read_lmem(kOutputBase + 8, &output1)) {
            return false;
        }
        if (output0 != kExpectedOutput0 || output1 != kExpectedOutput1) {
            return fail(runner_result_mismatch);
        }
        if (top_->command_count_o != 1 ||
            top_->completion_count_o != 1 ||
            top_->error_count_o != 0 ||
            top_->npu_required_issued_o != 1 ||
            top_->npu_required_completed_o != 1 ||
            top_->tiu_cycles_o != kExpectedTiuCycles ||
            top_->dma_cycles_o != 0 ||
            top_->dma_bytes_o != 0) {
            return fail(runner_counter_mismatch);
        }

        if (output_bytes_ != kExpectedOutputBytes) {
            return fail(runner_result_mismatch);
        }
        result_->passed = true;
        result_->rtl_cycles = top_->tiu_cycles_o;
        result_->output_bytes = output_bytes_;
        result_->error_code = runner_ok;
        return true;
    }

private:
    void drive_idle_inputs() {
        top_->clk = 0;
        top_->rst = 0;
        top_->cmd_valid_i = 0;
        top_->cmd_is_64_i = 0;
        top_->cmd_bits_i = 0;
        top_->cmd_rs_value_i = 0;
        top_->cmd_producer_id_i = 0;
        top_->cmd_npu_required_i = 0;
        top_->cmd_opclass_i = 0;
        top_->macro_cmd_valid_i = 0;
        top_->macro_abi_valid_i = 0;
        top_->macro_kernel_id_i = 0;
        top_->macro_command_flags_i = 0;
        top_->macro_context_id_i = 0;
        top_->macro_capability_epoch_i = 0;
        top_->macro_sequence_id_i = 0;
        top_->macro_producer_id_i = 0;
        top_->macro_user_tag_i = 0;
        top_->macro_node_count_i = 0;
        top_->macro_node_hash_lo_i = 0;
        top_->macro_node_hash_hi_i = 0;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 0;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = 0;
        top_->macro_src1_iova_i = 0;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = 0;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = 0;
        top_->macro_outer_count_i = 0;
        top_->macro_dtype_i = 0;
        top_->macro_src0_stride_i = 0;
        top_->macro_src1_stride_i = 0;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = 0;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = 0;
        top_->macro_src0_window_size_i = 0;
        top_->macro_src0_window_perm_i = 0;
        top_->macro_src1_window_base_i = 0;
        top_->macro_src1_window_size_i = 0;
        top_->macro_src1_window_perm_i = 0;
        top_->macro_dst_window_base_i = 0;
        top_->macro_dst_window_size_i = 0;
        top_->macro_dst_window_perm_i = 0;
        top_->macro_windows_generation_valid_i = 0;
        top_->completion_ready_i = 0;
        top_->desc_write_valid_i = 0;
        top_->desc_write_id_i = 0;
        top_->desc_write_word_i = 0;
        top_->desc_write_data_i = 0;
        top_->host_lmem_rd_valid_i = 0;
        top_->host_lmem_rd_addr_i = 0;
        top_->host_lmem_rd_bytes_i = 0;
        top_->host_lmem_wr_valid_i = 0;
        top_->host_lmem_wr_addr_i = 0;
        top_->host_lmem_wr_data_i = 0;
        top_->host_lmem_wr_strb_i = 0;
        top_->gmem_req_ready_i = 1;
        top_->gmem_rsp_valid_i = 0;
        top_->gmem_rsp_rdata_i = 0;
        top_->gmem_rsp_error_i = 0;
        top_->sync_tag_ack_i = 0;
        top_->error_clear_i = 0;
    }

    bool tick() {
        if (clock_cycles_ >= kMaxClockCycles) {
            return fail(runner_timeout);
        }
        top_->clk = 0;
        top_->eval();
        context_->timeInc(1);
        top_->clk = 1;
        top_->eval();
        context_->timeInc(1);
        top_->clk = 0;
        top_->eval();
        ++clock_cycles_;
        return true;
    }

    bool reset() {
        top_->rst = 1;
        for (unsigned index = 0; index < 4; ++index) {
            if (!tick()) {
                return false;
            }
        }
        top_->rst = 0;
        for (unsigned index = 0; index < 2; ++index) {
            if (!tick()) {
                return false;
            }
        }
        if (!top_->cmd_ready_o || !top_->desc_write_ready_o ||
            top_->busy_o || top_->error_o || top_->completion_valid_o) {
            return fail(runner_reset_interface);
        }
        return true;
    }

    bool write_descriptor(
            std::uint8_t id,
            const std::array<std::uint64_t, 4> & descriptor) {
        for (std::size_t word = 0; word < descriptor.size(); ++word) {
            top_->desc_write_valid_i = 1;
            top_->desc_write_id_i = id;
            top_->desc_write_word_i = static_cast<std::uint8_t>(word);
            top_->desc_write_data_i = descriptor[word];
            top_->eval();
            if (!top_->desc_write_ready_o || top_->desc_write_error_o ||
                top_->desc_write_error_code_o != 0) {
                return fail(runner_descriptor_interface);
            }
            if (!tick()) {
                return false;
            }
            top_->desc_write_valid_i = 0;
            top_->desc_write_id_i = 0;
            top_->desc_write_word_i = 0;
            top_->desc_write_data_i = 0;
            top_->eval();
        }
        return true;
    }

    bool write_lmem(std::uint32_t address, std::uint64_t data) {
        top_->host_lmem_wr_valid_i = 1;
        top_->host_lmem_wr_addr_i = address;
        top_->host_lmem_wr_data_i = data;
        top_->host_lmem_wr_strb_i = 0xff;
        top_->eval();
        if (!top_->host_lmem_ready_o || top_->host_lmem_wr_oob_o) {
            return fail(runner_lmem_interface);
        }
        if (!tick()) {
            return false;
        }
        top_->host_lmem_wr_valid_i = 0;
        top_->host_lmem_wr_addr_i = 0;
        top_->host_lmem_wr_data_i = 0;
        top_->host_lmem_wr_strb_i = 0;
        top_->eval();
        return true;
    }

    bool read_lmem(std::uint32_t address, std::uint64_t * data) {
        top_->host_lmem_rd_valid_i = 1;
        top_->host_lmem_rd_addr_i = address;
        top_->host_lmem_rd_bytes_i = 8;
        top_->eval();
        if (!top_->host_lmem_ready_o || top_->host_lmem_rd_oob_o) {
            return fail(runner_lmem_interface);
        }
        *data = top_->host_lmem_rd_data_o;
        output_bytes_ += 8;
        top_->host_lmem_rd_valid_i = 0;
        top_->host_lmem_rd_addr_i = 0;
        top_->host_lmem_rd_bytes_i = 0;
        top_->eval();
        return true;
    }

    bool run_mm2_command() {
        top_->cmd_valid_i = 1;
        top_->cmd_is_64_i = 1;
        top_->cmd_bits_i = kMm2Command;
        top_->cmd_rs_value_i = 0;
        top_->cmd_producer_id_i = 0x35;
        top_->cmd_npu_required_i = 1;
        top_->cmd_opclass_i = 0x21;
        top_->completion_ready_i = 0;
        top_->eval();
        if (!top_->cmd_ready_o || top_->error_o || top_->completion_valid_o) {
            return fail(runner_command_interface);
        }
        if (!tick()) {
            return false;
        }
        top_->cmd_valid_i = 0;
        top_->cmd_is_64_i = 0;
        top_->cmd_bits_i = 0;
        top_->cmd_producer_id_i = 0;
        top_->cmd_npu_required_i = 0;
        top_->cmd_opclass_i = 0;
        top_->eval();

        while (!top_->completion_valid_o) {
            if (!tick()) {
                return false;
            }
        }
        if (top_->completion_producer_id_o != 0x35 ||
            !top_->completion_npu_required_o ||
            top_->completion_opclass_o != 0x21) {
            return fail(runner_completion_interface);
        }
        if (top_->completion_error_o || top_->completion_error_code_o != 0) {
            const std::uint32_t rtl_error_code = top_->completion_error_code_o;
            return fail(rtl_error_code == 0
                            ? static_cast<std::uint32_t>(runner_completion_interface)
                            : rtl_error_code);
        }

        top_->completion_ready_i = 1;
        if (!tick()) {
            return false;
        }
        top_->completion_ready_i = 0;
        top_->eval();
        if (top_->completion_valid_o || !top_->cmd_ready_o || top_->error_o) {
            return fail(runner_completion_interface);
        }
        return true;
    }

    bool fail(std::uint32_t error_code) {
        result_->passed = false;
        result_->rtl_cycles = top_->tiu_cycles_o;
        result_->output_bytes = output_bytes_;
        result_->error_code = error_code;
        return false;
    }

    npu_verilator_self_test_result * result_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> top_;
    std::uint64_t clock_cycles_ = 0;
    std::uint64_t output_bytes_ = 0;
};

static_assert(kResponseLatencyCycles >= 1, "same-cycle GMEM response forbidden");
static_assert(kResponseLatencyCycles <= kResponseLatencyBound,
              "GMEM response latency exceeds B_rsp");

class f32_add_harness {
public:
    f32_add_harness(
            npu_f32_add_mode mode,
            const std::uint32_t * src0_bits,
            const std::uint32_t * src1_bits,
            std::uint32_t * dst_bits,
            bool check_fixed_oracle,
            npu_verilator_f32_add_result * result)
        : mode_(mode),
          submission_(mode),
          src0_bits_(src0_bits),
          src1_bits_(src1_bits),
          dst_bits_(dst_bits),
          check_fixed_oracle_(check_fixed_oracle),
          result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())) {
        drive_idle_inputs();
        load_input_windows();
        top_->eval();
    }

    ~f32_add_harness() {
        top_->final();
    }

    bool run() {
        if (!reset() || !submit()) {
            return false;
        }

        while (!top_->completion_valid_o) {
            if (!tick()) {
                return false;
            }
        }
        if (response_.occupied) {
            return fail(runner_f32_response_protocol);
        }

        const completion_snapshot snapshot = capture_completion(*top_);
        if (!hold_and_check_completion(snapshot)) {
            return false;
        }

        result_->completion_identity_match =
            completion_identity_matches(snapshot, submission_);
        if (!result_->completion_identity_match) {
            return fail(runner_f32_completion_identity);
        }

        const completion_record record = serialize_completion(snapshot);
        result_->completion_framing_valid =
            completion_framing_matches(record, snapshot);
        if (!result_->completion_framing_valid) {
            return fail(runner_f32_completion_framing);
        }

        snapshot_result(snapshot);
        if (!validate_mode(snapshot)) {
            return fail(runner_f32_mode_mismatch);
        }
        if (!consume_completion_and_recover(snapshot.error != 0)) {
            return fail(runner_f32_recovery);
        }

        if (mode_ == npu_f32_add_mode::positive) {
            for (std::size_t index = 0; index < kF32ElementCount; ++index) {
                dst_bits_[index] = load_le32(dst_window_, index * 4);
                if (check_fixed_oracle_ && dst_bits_[index] != kF32Expected[index]) {
                    return fail(runner_result_mismatch);
                }
            }
            result_->result_bytes = kF32WindowBytes;
        }

        result_->passed = true;
        result_->runner_error_code = runner_ok;
        return true;
    }

private:
    struct response_slot {
        bool occupied = false;
        bool active = false;
        bool write = false;
        std::uint64_t address = 0;
        std::uint64_t data = 0;
        std::uint8_t wstrb = 0;
        std::uint64_t due_cycle = 0;
    };

    void drive_idle_inputs() {
        top_->clk = 0;
        top_->rst = 0;
        top_->cmd_valid_i = 0;
        top_->cmd_is_64_i = 0;
        top_->cmd_bits_i = 0;
        top_->cmd_rs_value_i = 0;
        top_->cmd_producer_id_i = 0;
        top_->cmd_npu_required_i = 0;
        top_->cmd_opclass_i = 0;
        drive_macro_idle();
        top_->completion_ready_i = 0;
        top_->desc_write_valid_i = 0;
        top_->desc_write_id_i = 0;
        top_->desc_write_word_i = 0;
        top_->desc_write_data_i = 0;
        top_->host_lmem_rd_valid_i = 0;
        top_->host_lmem_rd_addr_i = 0;
        top_->host_lmem_rd_bytes_i = 0;
        top_->host_lmem_wr_valid_i = 0;
        top_->host_lmem_wr_addr_i = 0;
        top_->host_lmem_wr_data_i = 0;
        top_->host_lmem_wr_strb_i = 0;
        top_->gmem_req_ready_i = 0;
        top_->gmem_rsp_valid_i = 0;
        top_->gmem_rsp_rdata_i = 0;
        top_->gmem_rsp_error_i = 0;
        top_->sync_tag_ack_i = 0;
        top_->error_clear_i = 0;
    }

    void drive_macro_idle() {
        top_->macro_cmd_valid_i = 0;
        top_->macro_abi_valid_i = 0;
        top_->macro_kernel_id_i = 0;
        top_->macro_command_flags_i = 0;
        top_->macro_context_id_i = 0;
        top_->macro_capability_epoch_i = 0;
        top_->macro_sequence_id_i = 0;
        top_->macro_producer_id_i = 0;
        top_->macro_user_tag_i = 0;
        top_->macro_node_count_i = 0;
        top_->macro_node_hash_lo_i = 0;
        top_->macro_node_hash_hi_i = 0;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 0;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = 0;
        top_->macro_src1_iova_i = 0;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = 0;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = 0;
        top_->macro_outer_count_i = 0;
        top_->macro_dtype_i = 0;
        top_->macro_src0_stride_i = 0;
        top_->macro_src1_stride_i = 0;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = 0;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = 0;
        top_->macro_src0_window_size_i = 0;
        top_->macro_src0_window_perm_i = 0;
        top_->macro_src1_window_base_i = 0;
        top_->macro_src1_window_size_i = 0;
        top_->macro_src1_window_perm_i = 0;
        top_->macro_dst_window_base_i = 0;
        top_->macro_dst_window_size_i = 0;
        top_->macro_dst_window_perm_i = 0;
        top_->macro_windows_generation_valid_i = 0;
    }

    void drive_submission() {
        top_->macro_cmd_valid_i = 1;
        top_->macro_abi_valid_i = 1;
        top_->macro_kernel_id_i = submission_.kernel_id;
        top_->macro_command_flags_i = submission_.command_flags;
        top_->macro_context_id_i = kMacroContextId;
        top_->macro_capability_epoch_i = kMacroCapabilityEpoch;
        top_->macro_sequence_id_i = kMacroSequenceId;
        top_->macro_producer_id_i = kMacroProducerId;
        top_->macro_user_tag_i = kMacroUserTag;
        top_->macro_node_count_i = 1;
        top_->macro_node_hash_lo_i = kMacroNodeHashLo;
        top_->macro_node_hash_hi_i = kMacroNodeHashHi;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 1;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = submission_.src0_iova;
        top_->macro_src1_iova_i = kF32Src1Base;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = kF32DstBase;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = kF32ElementCount;
        top_->macro_outer_count_i = 1;
        top_->macro_dtype_i = 1;
        top_->macro_src0_stride_i = kF32WindowBytes;
        top_->macro_src1_stride_i = kF32WindowBytes;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = kF32WindowBytes;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = submission_.src0_window_base;
        top_->macro_src0_window_size_i = kF32WindowBytes;
        top_->macro_src0_window_perm_i = submission_.src0_window_perm;
        top_->macro_src1_window_base_i = kF32Src1Base;
        top_->macro_src1_window_size_i = kF32WindowBytes;
        top_->macro_src1_window_perm_i = submission_.src1_window_perm;
        top_->macro_dst_window_base_i = kF32DstBase;
        top_->macro_dst_window_size_i = kF32WindowBytes;
        top_->macro_dst_window_perm_i = submission_.dst_window_perm;
        top_->macro_windows_generation_valid_i = 1;
    }

    void load_input_windows() {
        src0_window_.fill(0);
        src1_window_.fill(0);
        dst_window_.fill(0xa5);
        for (std::size_t index = 0; index < kF32ElementCount; ++index) {
            store_le32(src0_window_, index * 4, src0_bits_[index]);
            store_le32(src1_window_, index * 4, src1_bits_[index]);
        }
    }

    void drive_memory_inputs() {
        top_->gmem_req_ready_i =
            (mode_ == npu_f32_add_mode::req_ready_low_timeout) ? 0 : 1;
        top_->gmem_rsp_valid_i = response_.active ? 1 : 0;
        top_->gmem_rsp_rdata_i = response_.active ? response_.data : 0;
        top_->gmem_rsp_error_i = 0;
    }

    bool tick() {
        if (clock_cycles_ >= kF32MaxClockCycles) {
            return fail(runner_timeout);
        }
        if (response_.occupied && !response_.active &&
            clock_cycles_ >= response_.due_cycle) {
            response_.active = true;
        }

        top_->clk = 0;
        drive_memory_inputs();
        top_->eval();

        const bool request_valid = top_->gmem_req_valid_o != 0;
        const bool request_ready = top_->gmem_req_ready_i != 0;
        const bool request_fire = request_valid && request_ready;
        const bool response_fire = response_.active &&
                                   (top_->gmem_rsp_ready_o != 0);

        if (!check_unaccepted_request_hold(request_valid, request_ready)) {
            return false;
        }
        if (request_fire && response_.occupied) {
            return fail(runner_f32_request_protocol);
        }

        response_slot accepted_request = {};
        if (request_fire) {
            accepted_request.occupied = true;
            accepted_request.write = top_->gmem_req_write_o != 0;
            accepted_request.address = top_->gmem_req_addr_o;
            accepted_request.data = top_->gmem_req_wdata_o;
            accepted_request.wstrb = top_->gmem_req_wstrb_o;
            accepted_request.due_cycle =
                clock_cycles_ + kResponseLatencyCycles;
            if (!prepare_response(&accepted_request)) {
                return false;
            }
        }

        top_->clk = 1;
        top_->eval();
        context_->timeInc(1);

        if (response_fire) {
            if (response_.write && !commit_write(response_)) {
                return false;
            }
            response_ = {};
            ++gmem_responses_accepted_;
        }
        if (request_fire) {
            response_ = accepted_request;
            ++gmem_requests_accepted_;
        }

        top_->clk = 0;
        top_->eval();
        context_->timeInc(1);
        ++clock_cycles_;
        return true;
    }

    bool check_unaccepted_request_hold(bool valid, bool ready) {
        if (valid && !ready) {
            if (!unaccepted_request_held_) {
                unaccepted_request_held_ = true;
                held_request_write_ = top_->gmem_req_write_o;
                held_request_address_ = top_->gmem_req_addr_o;
                held_request_data_ = top_->gmem_req_wdata_o;
                held_request_wstrb_ = top_->gmem_req_wstrb_o;
            } else if (held_request_write_ != top_->gmem_req_write_o ||
                       held_request_address_ != top_->gmem_req_addr_o ||
                       held_request_data_ != top_->gmem_req_wdata_o ||
                       held_request_wstrb_ != top_->gmem_req_wstrb_o) {
                return fail(runner_f32_request_protocol);
            }
        } else {
            // Watchdog cancellation is legal: stability is required only
            // while valid remains asserted before the cancellation edge.
            unaccepted_request_held_ = false;
        }
        return true;
    }

    bool prepare_response(response_slot * request) {
        if ((request->address & 7U) != 0) {
            return fail(runner_f32_request_protocol);
        }
        if (request->write) {
            if ((request->wstrb != 0x0f && request->wstrb != 0xf0) ||
                !address_in_window(request->address, kF32DstBase)) {
                return fail(runner_f32_memory_bounds);
            }
            return true;
        }
        if (request->wstrb != 0) {
            return fail(runner_f32_request_protocol);
        }
        if (address_in_window(request->address, kF32Src0Base)) {
            request->data = load_window_word(
                src0_window_, request->address - kF32Src0Base);
            return true;
        }
        if (address_in_window(request->address, kF32Src1Base)) {
            request->data = load_window_word(
                src1_window_, request->address - kF32Src1Base);
            return true;
        }
        return fail(runner_f32_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        if (!address_in_window(request.address, kF32DstBase)) {
            return fail(runner_f32_memory_bounds);
        }
        const std::size_t offset =
            static_cast<std::size_t>(request.address - kF32DstBase);
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) != 0) {
                dst_window_[offset + lane] = static_cast<std::uint8_t>(
                    request.data >> (lane * 8));
            }
        }
        return true;
    }

    static bool address_in_window(
            std::uint64_t address,
            std::uint64_t base) {
        return address >= base && address <= base + kF32WindowBytes - 8;
    }

    static std::uint64_t load_window_word(
            const std::array<std::uint8_t, kF32WindowBytes> & window,
            std::uint64_t offset) {
        return load_le64(window, static_cast<std::size_t>(offset));
    }

    bool reset() {
        top_->rst = 1;
        for (unsigned index = 0; index < 4; ++index) {
            if (!tick()) {
                return false;
            }
        }
        top_->rst = 0;
        for (unsigned index = 0; index < 2; ++index) {
            if (!tick()) {
                return false;
            }
        }
        if (!top_->cmd_ready_o || !top_->macro_cmd_ready_o ||
            top_->busy_o || top_->error_o || top_->completion_valid_o ||
            top_->gmem_req_valid_o || top_->gmem_rsp_ready_o ||
            response_.occupied) {
            return fail(runner_reset_interface);
        }
        return true;
    }

    bool submit() {
        command_count_before_ = top_->macro_command_count_o;
        f32_start_count_before_ = top_->macro_f32_start_count_o;
        completion_count_before_ = top_->macro_completion_count_o;
        drive_submission();
        top_->eval();
        if (!top_->macro_cmd_ready_o || top_->completion_valid_o ||
            top_->busy_o || top_->error_o) {
            return fail(runner_command_interface);
        }
        if (!tick()) {
            return false;
        }
        drive_macro_idle();
        top_->eval();
        return true;
    }

    bool hold_and_check_completion(const completion_snapshot & snapshot) {
        result_->completion_stable = true;
        top_->completion_ready_i = 0;
        for (unsigned index = 0;
             index < kCompletionBackpressureCycles;
             ++index) {
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(runner_f32_completion_protocol);
            }
            if (!tick()) {
                return false;
            }
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(runner_f32_completion_protocol);
            }
        }
        return true;
    }

    void snapshot_result(const completion_snapshot & snapshot) {
        result_->completion_status = snapshot.status;
        result_->completion_error_class = snapshot.error_class;
        result_->completion_error_code = snapshot.error_code;
        result_->rtl_cycles = snapshot.npu_cycles;
        result_->gmem_read_bytes = snapshot.gmem_read_bytes;
        result_->gmem_write_bytes = snapshot.gmem_write_bytes;
        result_->vector_elements = snapshot.vector_element_count;
        result_->f32_start_count =
            top_->macro_f32_start_count_o - f32_start_count_before_;
        result_->commands_accepted =
            top_->macro_command_count_o - command_count_before_;
        result_->commands_terminal_success =
            top_->macro_completion_count_o - completion_count_before_;
        result_->commands_terminal_failure = snapshot.error ? 1 : 0;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
    }

    bool validate_mode(const completion_snapshot & snapshot) {
        if (result_->commands_accepted != 1 ||
            snapshot.status != snapshot.error_code ||
            gmem_requests_accepted_ != gmem_responses_accepted_) {
            return false;
        }
        switch (mode_) {
            case npu_f32_add_mode::positive:
                result_->controlled_reject = false;
                return snapshot.error == 0 &&
                       snapshot.status == 0 &&
                       snapshot.error_class == 0 &&
                       snapshot.gmem_read_bytes == 128 &&
                       snapshot.gmem_write_bytes == 64 &&
                       snapshot.vector_element_count == 16 &&
                       result_->f32_start_count == 1 &&
                       result_->commands_terminal_success == 1 &&
                       result_->commands_terminal_failure == 0 &&
                       gmem_requests_accepted_ == 32;
            case npu_f32_add_mode::unknown_kernel:
                result_->controlled_reject = true;
                return snapshot.error == 1 &&
                       snapshot.status == kNpuErrMacroCapability &&
                       snapshot.error_class == kAbiErrorCapability &&
                       snapshot.gmem_read_bytes == 0 &&
                       snapshot.gmem_write_bytes == 0 &&
                       snapshot.vector_element_count == 0 &&
                       result_->f32_start_count == 0 &&
                       result_->commands_terminal_success == 0 &&
                       result_->commands_terminal_failure == 1 &&
                       gmem_requests_accepted_ == 0;
            case npu_f32_add_mode::out_of_range_4mod8:
                result_->controlled_reject = true;
                return snapshot.error == 1 &&
                       snapshot.status == kNpuErrMacroIova &&
                       snapshot.error_class == kAbiErrorIova &&
                       snapshot.gmem_read_bytes == 0 &&
                       snapshot.gmem_write_bytes == 0 &&
                       snapshot.vector_element_count == 0 &&
                       result_->f32_start_count == 0 &&
                       result_->commands_terminal_success == 0 &&
                       result_->commands_terminal_failure == 1 &&
                       gmem_requests_accepted_ == 0;
            case npu_f32_add_mode::overpermission:
                result_->controlled_reject = true;
                return snapshot.error == 1 &&
                       snapshot.status == kNpuErrMacroIova &&
                       snapshot.error_class == kAbiErrorIova &&
                       snapshot.gmem_read_bytes == 0 &&
                       snapshot.gmem_write_bytes == 0 &&
                       snapshot.vector_element_count == 0 &&
                       result_->f32_start_count == 0 &&
                       result_->commands_terminal_success == 0 &&
                       result_->commands_terminal_failure == 1 &&
                       gmem_requests_accepted_ == 0;
            case npu_f32_add_mode::req_ready_low_timeout:
                result_->controlled_reject = true;
                return snapshot.error == 1 &&
                       snapshot.status == kNpuErrMacroTimeout &&
                       snapshot.error_class == kAbiErrorTimeout &&
                       snapshot.gmem_read_bytes == 0 &&
                       snapshot.gmem_write_bytes == 0 &&
                       snapshot.vector_element_count == 0 &&
                       result_->f32_start_count == 1 &&
                       result_->commands_terminal_success == 0 &&
                       result_->commands_terminal_failure == 1 &&
                       gmem_requests_accepted_ == 0 &&
                       !unaccepted_request_held_;
            default:
                return false;
        }
    }

    bool consume_completion_and_recover(bool terminal_error) {
        top_->completion_ready_i = 1;
        if (!tick()) {
            return false;
        }
        top_->completion_ready_i = 0;
        top_->eval();
        if (top_->completion_valid_o) {
            return false;
        }

        if (terminal_error) {
            if (!top_->error_o || top_->error_code_o == 0) {
                return false;
            }
            top_->error_clear_i = 1;
            if (!tick()) {
                return false;
            }
            top_->error_clear_i = 0;
            top_->eval();
        }

        result_->recovery_clean =
            !top_->busy_o && !top_->error_o &&
            !top_->completion_valid_o && top_->cmd_ready_o &&
            top_->macro_cmd_ready_o && !top_->gmem_req_valid_o &&
            !top_->gmem_rsp_ready_o && !response_.occupied;
        return result_->recovery_clean;
    }

    bool fail(std::uint32_t error_code) {
        result_->passed = false;
        result_->runner_error_code = error_code;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        return false;
    }

    npu_f32_add_mode mode_;
    macro_submission submission_;
    const std::uint32_t * src0_bits_;
    const std::uint32_t * src1_bits_;
    std::uint32_t * dst_bits_;
    bool check_fixed_oracle_;
    npu_verilator_f32_add_result * result_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> top_;
    std::array<std::uint8_t, kF32WindowBytes> src0_window_ = {};
    std::array<std::uint8_t, kF32WindowBytes> src1_window_ = {};
    std::array<std::uint8_t, kF32WindowBytes> dst_window_ = {};
    response_slot response_ = {};
    bool unaccepted_request_held_ = false;
    std::uint32_t held_request_write_ = 0;
    std::uint64_t held_request_address_ = 0;
    std::uint64_t held_request_data_ = 0;
    std::uint32_t held_request_wstrb_ = 0;
    std::uint64_t clock_cycles_ = 0;
    std::uint64_t gmem_requests_accepted_ = 0;
    std::uint64_t gmem_responses_accepted_ = 0;
    std::uint64_t command_count_before_ = 0;
    std::uint64_t f32_start_count_before_ = 0;
    std::uint64_t completion_count_before_ = 0;
};
#endif

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

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
struct f32_alu_submission {
    npu_f32_alu_mode mode = npu_f32_alu_mode::positive;
    npu_f32_alu_representative_identity identity = {};
    std::uint32_t kernel_id = kMacroKernelVectorF32;
    std::uint32_t vector_op = 0;
    std::uint32_t vector_flags = 0;
    std::uint32_t scalar0 = 0;
    std::uint64_t element_count = 0;
    std::uint32_t outer_count = 0;
    std::uint64_t src0_stride = 0;
    std::uint64_t src1_stride = 0;
    std::uint64_t dst_stride = 0;
    std::uint64_t src0_iova = 0;
    std::uint64_t src1_iova = 0;
    std::uint64_t dst_iova = kF32AluDstBase;
    std::uint64_t src0_window_base = kF32AluSrc0Base;
    std::uint64_t src1_window_base = kF32AluSrc1Base;
    std::uint64_t dst_window_base = kF32AluDstBase;
    std::uint64_t src0_window_size = 0;
    std::uint64_t src1_window_size = 0;
    std::uint64_t dst_window_size = 0;
    std::uint32_t src0_window_perm = 1;
    std::uint32_t src1_window_perm = 0;
    std::uint32_t dst_window_perm = 2;

    f32_alu_submission(
            const npu_f32_alu_profile & profile,
            npu_f32_alu_mode selected_mode,
            const npu_f32_alu_representative_identity * transaction_identity)
        : mode(selected_mode),
          identity(transaction_identity != nullptr ?
                   *transaction_identity :
                   representative_identity(profile.profile_id)),
          vector_op(profile.vector_op),
          vector_flags(profile.profile_id),
          scalar0(profile.scalar0),
          element_count(profile.element_count),
          outer_count(static_cast<std::uint32_t>(profile.outer_count)),
          src0_stride(profile.src0.nb[1]),
          src1_stride(profile.src1_present ? profile.src1.nb[1] : 0),
          dst_stride(profile.dst.nb[1]),
          src0_iova(kF32AluSrc0Base + profile.src0.view_off),
          src1_iova(profile.src1_present ?
                    kF32AluSrc1Base + profile.src1.view_off : 0),
          src0_window_perm(1),
          src1_window_perm(profile.src1_present ? 1U : 0U),
          dst_window_perm(2) {
        npu_f32_alu_span src0_span = {};
        npu_f32_alu_span src1_span = {};
        if (source_span_checked(profile.src0, &src0_span)) {
            src0_window_size = src0_span.beat_hi;
        }
        if (profile.src1_present &&
            source_span_checked(profile.src1, &src1_span)) {
            src1_window_size = src1_span.beat_hi;
        } else if (!profile.src1_present) {
            src1_window_base = 0;
        }
        dst_window_size = profile.expected_write_bytes;

        switch (mode) {
            case npu_f32_alu_mode::unknown_kernel:
                kernel_id = kMacroUnknownKernel;
                break;
            case npu_f32_alu_mode::invalid_profile:
                vector_flags = 31;
                break;
            case npu_f32_alu_mode::op_profile_collision:
                vector_op = profile.vector_op == 1 ? 2 : 1;
                break;
            case npu_f32_alu_mode::summary_mismatch:
                ++element_count;
                break;
            case npu_f32_alu_mode::scalar_mismatch:
                scalar0 ^= 1U;
                break;
            case npu_f32_alu_mode::out_of_range_4mod8:
                src0_window_base += 4;
                src0_iova = src0_window_base + profile.src0.view_off;
                break;
            case npu_f32_alu_mode::overlap:
                dst_window_base = kF32AluSrc0Base + src0_span.beat_lo;
                dst_iova = dst_window_base;
                break;
            case npu_f32_alu_mode::overpermission:
                src0_window_perm = 3;
                break;
            case npu_f32_alu_mode::positive:
            case npu_f32_alu_mode::req_ready_low_timeout:
                break;
        }
    }
};
#endif

bool tensor_element_count(
        const npu_f32_alu_tensor_descriptor & descriptor,
        std::uint64_t * count) {
    if (count == nullptr) {
        return false;
    }
    *count = 1;
    for (std::uint32_t extent : descriptor.ne) {
        if (extent == 0 || !checked_mul_u64(*count, extent, count)) {
            return false;
        }
    }
    return true;
}

void decode_coordinates(
        std::uint64_t flat,
        const npu_f32_alu_tensor_descriptor & descriptor,
        std::array<std::uint32_t, 4> * coordinates) {
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        (*coordinates)[dimension] = static_cast<std::uint32_t>(
            flat % descriptor.ne[dimension]);
        flat /= descriptor.ne[dimension];
    }
}

bool descriptor_offset(
        const npu_f32_alu_tensor_descriptor & descriptor,
        const std::array<std::uint32_t, 4> & coordinates,
        std::uint64_t * offset) {
    if (offset == nullptr) {
        return false;
    }
    *offset = descriptor.view_off;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        std::uint64_t term = 0;
        if (coordinates[dimension] >= descriptor.ne[dimension] ||
            !checked_mul_u64(coordinates[dimension],
                             descriptor.nb[dimension], &term) ||
            !checked_add_u64(*offset, term, offset)) {
            return false;
        }
    }
    return true;
}

std::uint64_t row_major_index(
        const npu_f32_alu_tensor_descriptor & descriptor,
        const std::array<std::uint32_t, 4> & coordinates) {
    std::uint64_t index = coordinates[3];
    for (std::size_t dimension = 3; dimension > 0; --dimension) {
        index = index * descriptor.ne[dimension - 1] +
                coordinates[dimension - 1];
    }
    return index;
}

// Sixteen finite, nonzero signed powers of two, generated entirely as raw
// IEEE-754 bit fields.  ADD/SUB by +0 and MUL by +1 preserve these bits
// exactly; no host floating-point expression or arithmetic is used.
std::uint32_t distinguishable_raw_bits(
        std::uint64_t linear,
        const std::array<std::uint32_t, 4> & coordinates) {
    const std::uint32_t mixed = static_cast<std::uint32_t>(
        linear ^ (linear >> 4) ^
        (static_cast<std::uint64_t>(coordinates[0]) * 3ULL) ^
        (static_cast<std::uint64_t>(coordinates[1]) * 5ULL) ^
        (static_cast<std::uint64_t>(coordinates[2]) * 9ULL) ^
        (static_cast<std::uint64_t>(coordinates[3]) * 13ULL));
    const std::uint32_t selector = mixed & 15U;
    const std::uint32_t sign = (selector & 8U) != 0 ? 0x80000000U : 0U;
    const std::uint32_t exponent = 120U + (selector & 7U);
    return sign | (exponent << 23);
}

bool store_raw_word(
        std::vector<std::uint8_t> * bytes,
        std::uint64_t offset,
        std::uint32_t value) {
    if (bytes == nullptr || offset > bytes->size() ||
        bytes->size() - static_cast<std::size_t>(offset) < 4) {
        return false;
    }
    for (std::size_t lane = 0; lane < 4; ++lane) {
        (*bytes)[static_cast<std::size_t>(offset) + lane] =
            static_cast<std::uint8_t>(value >> (lane * 8));
    }
    return true;
}

bool fill_descriptor_raw(
        const npu_f32_alu_tensor_descriptor & descriptor,
        bool use_distinguishable,
        std::uint32_t constant,
        std::vector<std::uint8_t> * allocation) {
    std::uint64_t count = 0;
    if (!tensor_element_count(descriptor, &count)) {
        return false;
    }
    for (std::uint64_t flat = 0; flat < count; ++flat) {
        std::array<std::uint32_t, 4> coordinates = {};
        std::uint64_t offset = 0;
        decode_coordinates(flat, descriptor, &coordinates);
        if (!descriptor_offset(descriptor, coordinates, &offset)) {
            return false;
        }
        const std::uint32_t bits = use_distinguishable ?
            distinguishable_raw_bits(flat, coordinates) : constant;
        if (!store_raw_word(allocation, offset, bits)) {
            return false;
        }
    }
    return true;
}

std::uint32_t descriptor_pattern_at_output(
        const npu_f32_alu_tensor_descriptor & source,
        const std::array<std::uint32_t, 4> & output_coordinates) {
    std::array<std::uint32_t, 4> source_coordinates = {};
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        source_coordinates[dimension] =
            output_coordinates[dimension] % source.ne[dimension];
    }
    return distinguishable_raw_bits(
        row_major_index(source, source_coordinates), source_coordinates);
}

bool prepare_identity_oracle(
        const npu_f32_alu_profile & profile,
        std::vector<std::uint8_t> * src0,
        std::vector<std::uint8_t> * src1,
        std::vector<std::uint8_t> * expected) {
    constexpr std::uint32_t kPositiveZero = 0x00000000U;
    constexpr std::uint32_t kNegativeZero = 0x80000000U;
    constexpr std::uint32_t kPositiveOne = 0x3f800000U;
    constexpr std::uint32_t kNegativeOne = 0xbf800000U;

    bool src0_distinguishable = false;
    bool src1_distinguishable = false;
    if (profile.vector_op == 1 || profile.vector_op == 3) {
        src0_distinguishable = true;
    } else if (profile.vector_op == 2) {
        src1_distinguishable =
            profile.profile_id == 6 || profile.profile_id == 7 ||
            profile.profile_id == 8 || profile.profile_id == 9 ||
            profile.profile_id == 10 || profile.profile_id == 13 ||
            profile.profile_id == 14;
        src0_distinguishable = !src1_distinguishable;
    }

    const std::uint32_t src0_constant =
        profile.vector_op == 2 ? kPositiveOne : kPositiveZero;
    const std::uint32_t src1_constant =
        profile.vector_op == 2 ? kPositiveOne : kPositiveZero;
    if (!fill_descriptor_raw(profile.src0, src0_distinguishable,
                             src0_constant, src0)) {
        return false;
    }
    if (profile.src1_present &&
        !fill_descriptor_raw(profile.src1, src1_distinguishable,
                             src1_constant, src1)) {
        return false;
    }

    for (std::uint64_t flat = 0; flat < profile.total_elements; ++flat) {
        std::array<std::uint32_t, 4> coordinates = {};
        decode_coordinates(flat, profile.dst, &coordinates);
        std::uint32_t expected_bits = 0;
        if (profile.vector_op == 1 || profile.vector_op == 3) {
            expected_bits = descriptor_pattern_at_output(
                profile.src0, coordinates);
        } else if (profile.vector_op == 2) {
            expected_bits = src1_distinguishable ?
                descriptor_pattern_at_output(profile.src1, coordinates) :
                descriptor_pattern_at_output(profile.src0, coordinates);
        } else if (profile.profile_id == 16) {
            const std::uint32_t input = (flat & 1U) == 0 ?
                kPositiveOne : kPositiveZero;
            std::uint64_t offset = 0;
            if (!descriptor_offset(profile.src0, coordinates, &offset) ||
                !store_raw_word(src0, offset, input)) {
                return false;
            }
            expected_bits = (flat & 1U) == 0 ?
                profile.scalar0 : kPositiveZero;
        } else {
            const std::uint32_t input = (flat & 1U) == 0 ?
                kPositiveOne : kNegativeOne;
            std::uint64_t offset = 0;
            if (!descriptor_offset(profile.src0, coordinates, &offset) ||
                !store_raw_word(src0, offset, input)) {
                return false;
            }
            expected_bits = (flat & 1U) == 0 ?
                kPositiveZero : kNegativeZero;
        }
        if (!store_raw_word(expected, flat * 4, expected_bits)) {
            return false;
        }
    }

    // These explicit probes make the intended coverage fail closed even if a
    // future table row accidentally collapses to a uniform pattern.
    if (profile.total_elements < 2 || expected->size() < 8) {
        return false;
    }
    const std::size_t last = expected->size() - 4;
    return std::memcmp(expected->data(), expected->data() + last, 4) != 0 ||
           std::memcmp(expected->data() + last - 4,
                       expected->data() + last, 4) != 0;
}

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
class f32_alu_harness {
public:
    f32_alu_harness(
            const npu_f32_alu_profile & profile,
            npu_f32_alu_mode mode,
            const npu_f32_alu_representative_identity * transaction_identity,
            const std::uint8_t * src0_allocation,
            std::size_t src0_allocation_bytes,
            const std::uint8_t * src1_allocation,
            std::size_t src1_allocation_bytes,
            std::uint8_t * dst_shadow,
            std::size_t dst_shadow_bytes,
            const std::uint8_t * expected_shadow,
            std::size_t expected_shadow_bytes,
            npu_verilator_f32_alu_result * result)
        : profile_(profile),
          mode_(mode),
          submission_(profile, mode, transaction_identity),
          src0_allocation_(src0_allocation),
          src0_allocation_bytes_(src0_allocation_bytes),
          src1_allocation_(src1_allocation),
          src1_allocation_bytes_(src1_allocation_bytes),
          dst_shadow_(dst_shadow),
          dst_shadow_bytes_(dst_shadow_bytes),
          expected_shadow_(expected_shadow),
          expected_shadow_bytes_(expected_shadow_bytes),
          result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())) {
        inputs_valid_ = source_span_checked(profile_.src0, &src0_span_);
        if (profile_.src1_present) {
            inputs_valid_ = inputs_valid_ &&
                source_span_checked(profile_.src1, &src1_span_);
        }
        if (inputs_valid_) {
            src0_window_.assign(
                static_cast<std::size_t>(src0_span_.beat_hi), 0);
            if (profile_.src1_present) {
                src1_window_.assign(
                    static_cast<std::size_t>(src1_span_.beat_hi), 0);
            }
            dst_window_.assign(
                static_cast<std::size_t>(profile_.expected_write_bytes),
                0xa5);
            inputs_valid_ = load_input_windows();
        }
        drive_idle_inputs();
        top_->eval();
    }

    ~f32_alu_harness() {
        top_->final();
    }

    bool run() {
        result_->profile_id = profile_.profile_id;
        result_->submitted_profile_id = submission_.vector_flags;
        result_->submitted_identity = submission_.identity;
        result_->submitted_identity.profile_id = submission_.vector_flags;
        result_->cycle_upper_bound = profile_.cycle_upper_bound;
        if (!inputs_valid_) {
            return fail(runner_f32_span);
        }
        if (!reset() || !submit()) {
            return false;
        }
        while (!top_->completion_valid_o) {
            if (!tick()) {
                return false;
            }
        }
        if (response_.occupied) {
            return fail(runner_f32_response_protocol);
        }

        const completion_snapshot snapshot = capture_completion(*top_);
        result_->completion_emitted = true;
        result_->observed_profile_id = snapshot.vector_flags;
        result_->returned_identity = {
            snapshot.vector_flags,
            snapshot.command_flags,
            snapshot.context_id,
            snapshot.sequence_id,
            snapshot.producer_id,
            snapshot.user_tag,
            snapshot.node_hash_lo,
            snapshot.node_hash_hi,
        };
        if (!hold_and_check_completion(snapshot)) {
            return false;
        }
        result_->completion_identity_match = identity_matches(snapshot);
        result_->representative_identity_match =
            representative_identity_matches(snapshot);
        if (!result_->completion_identity_match) {
            return fail(runner_f32_completion_identity);
        }
        const completion_record record =
            serialize_representative_completion(snapshot);
        result_->completion_framing_valid =
            representative_completion_framing_matches(record, snapshot);
        if (!result_->completion_framing_valid) {
            return fail(runner_f32_completion_framing);
        }
        snapshot_result(snapshot);
        if (!validate_mode(snapshot)) {
            return fail(runner_f32_mode_mismatch);
        }
        if (!consume_completion_and_recover(snapshot, snapshot.error != 0)) {
            return fail(runner_f32_recovery);
        }

        if (mode_ == npu_f32_alu_mode::positive) {
            if (!result_->completion_accepted ||
                (is_required_transaction() ?
                    result_->representative_identity_match :
                    !result_->representative_identity_match)) {
                return fail(runner_f32_completion_identity);
            }
            if (expected_shadow_ != nullptr &&
                (expected_shadow_bytes_ != dst_window_.size() ||
                 std::memcmp(expected_shadow_, dst_window_.data(),
                             dst_window_.size()) != 0)) {
                return fail(runner_result_mismatch);
            }
            std::memcpy(dst_shadow_, dst_window_.data(), dst_window_.size());
            result_->result_bytes = dst_window_.size();
            result_->private_shadow_committed = true;
        }
        result_->passed = true;
        result_->runner_error_code = runner_ok;
        return true;
    }

private:
    struct response_slot {
        bool occupied = false;
        bool active = false;
        bool write = false;
        std::uint64_t address = 0;
        std::uint64_t data = 0;
        std::uint8_t wstrb = 0;
        std::uint64_t due_cycle = 0;
    };

    bool load_input_windows() {
        if (src0_allocation_ == nullptr ||
            src0_allocation_bytes_ < src0_span_.beat_hi ||
            dst_shadow_ == nullptr ||
            dst_shadow_bytes_ != profile_.expected_write_bytes) {
            return false;
        }
        const std::size_t src0_lo =
            static_cast<std::size_t>(src0_span_.beat_lo);
        const std::size_t src0_count =
            static_cast<std::size_t>(src0_span_.beat_hi - src0_span_.beat_lo);
        std::memcpy(src0_window_.data() + src0_lo,
                    src0_allocation_ + src0_lo, src0_count);
        if (!profile_.src1_present) {
            return src1_allocation_ == nullptr && src1_allocation_bytes_ == 0;
        }
        if (src1_allocation_ == nullptr ||
            src1_allocation_bytes_ < src1_span_.beat_hi) {
            return false;
        }
        const std::size_t src1_lo =
            static_cast<std::size_t>(src1_span_.beat_lo);
        const std::size_t src1_count =
            static_cast<std::size_t>(src1_span_.beat_hi - src1_span_.beat_lo);
        std::memcpy(src1_window_.data() + src1_lo,
                    src1_allocation_ + src1_lo, src1_count);
        return true;
    }

    void drive_idle_inputs() {
        top_->clk = 0;
        top_->rst = 0;
        top_->cmd_valid_i = 0;
        top_->cmd_is_64_i = 0;
        top_->cmd_bits_i = 0;
        top_->cmd_rs_value_i = 0;
        top_->cmd_producer_id_i = 0;
        top_->cmd_npu_required_i = 0;
        top_->cmd_opclass_i = 0;
        drive_macro_idle();
        top_->completion_ready_i = 0;
        top_->desc_write_valid_i = 0;
        top_->desc_write_id_i = 0;
        top_->desc_write_word_i = 0;
        top_->desc_write_data_i = 0;
        top_->host_lmem_rd_valid_i = 0;
        top_->host_lmem_rd_addr_i = 0;
        top_->host_lmem_rd_bytes_i = 0;
        top_->host_lmem_wr_valid_i = 0;
        top_->host_lmem_wr_addr_i = 0;
        top_->host_lmem_wr_data_i = 0;
        top_->host_lmem_wr_strb_i = 0;
        top_->gmem_req_ready_i = 0;
        top_->gmem_rsp_valid_i = 0;
        top_->gmem_rsp_rdata_i = 0;
        top_->gmem_rsp_error_i = 0;
        top_->sync_tag_ack_i = 0;
        top_->error_clear_i = 0;
    }

    void drive_macro_idle() {
        top_->macro_cmd_valid_i = 0;
        top_->macro_abi_valid_i = 0;
        top_->macro_kernel_id_i = 0;
        top_->macro_command_flags_i = 0;
        top_->macro_context_id_i = 0;
        top_->macro_capability_epoch_i = 0;
        top_->macro_sequence_id_i = 0;
        top_->macro_producer_id_i = 0;
        top_->macro_user_tag_i = 0;
        top_->macro_node_count_i = 0;
        top_->macro_node_hash_lo_i = 0;
        top_->macro_node_hash_hi_i = 0;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 0;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = 0;
        top_->macro_src1_iova_i = 0;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = 0;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = 0;
        top_->macro_outer_count_i = 0;
        top_->macro_dtype_i = 0;
        top_->macro_src0_stride_i = 0;
        top_->macro_src1_stride_i = 0;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = 0;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = 0;
        top_->macro_src0_window_size_i = 0;
        top_->macro_src0_window_perm_i = 0;
        top_->macro_src1_window_base_i = 0;
        top_->macro_src1_window_size_i = 0;
        top_->macro_src1_window_perm_i = 0;
        top_->macro_dst_window_base_i = 0;
        top_->macro_dst_window_size_i = 0;
        top_->macro_dst_window_perm_i = 0;
        top_->macro_windows_generation_valid_i = 0;
    }

    void drive_submission() {
        top_->macro_cmd_valid_i = 1;
        top_->macro_abi_valid_i = 1;
        top_->macro_kernel_id_i = submission_.kernel_id;
        top_->macro_command_flags_i = submission_.identity.command_flags;
        top_->macro_context_id_i = submission_.identity.context_id;
        top_->macro_capability_epoch_i = kMacroCapabilityEpoch;
        top_->macro_sequence_id_i = submission_.identity.sequence_id;
        top_->macro_producer_id_i = submission_.identity.producer_id;
        top_->macro_user_tag_i = submission_.identity.user_tag;
        top_->macro_node_count_i = 1;
        top_->macro_node_hash_lo_i = submission_.identity.node_hash_lo;
        top_->macro_node_hash_hi_i = submission_.identity.node_hash_hi;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = submission_.vector_op;
        top_->macro_vector_flags_i = submission_.vector_flags;
        top_->macro_src0_iova_i = submission_.src0_iova;
        top_->macro_src1_iova_i = submission_.src1_iova;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = submission_.dst_iova;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = submission_.element_count;
        top_->macro_outer_count_i = submission_.outer_count;
        top_->macro_dtype_i = 1;
        top_->macro_src0_stride_i = submission_.src0_stride;
        top_->macro_src1_stride_i = submission_.src1_stride;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = submission_.dst_stride;
        top_->macro_scalar0_i = submission_.scalar0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = submission_.src0_window_base;
        top_->macro_src0_window_size_i = submission_.src0_window_size;
        top_->macro_src0_window_perm_i = submission_.src0_window_perm;
        top_->macro_src1_window_base_i = submission_.src1_window_base;
        top_->macro_src1_window_size_i = submission_.src1_window_size;
        top_->macro_src1_window_perm_i = submission_.src1_window_perm;
        top_->macro_dst_window_base_i = submission_.dst_window_base;
        top_->macro_dst_window_size_i = submission_.dst_window_size;
        top_->macro_dst_window_perm_i = submission_.dst_window_perm;
        top_->macro_windows_generation_valid_i = 1;
    }

    void drive_memory_inputs() {
        top_->gmem_req_ready_i =
            mode_ == npu_f32_alu_mode::req_ready_low_timeout ? 0 : 1;
        top_->gmem_rsp_valid_i = response_.active ? 1 : 0;
        top_->gmem_rsp_rdata_i = response_.active ? response_.data : 0;
        top_->gmem_rsp_error_i = 0;
    }

    bool tick() {
        if (clock_cycles_ >= kF32AluMaxClockCycles) {
            return fail(runner_timeout);
        }
        if (response_.occupied && !response_.active &&
            clock_cycles_ >= response_.due_cycle) {
            response_.active = true;
        }
        top_->clk = 0;
        drive_memory_inputs();
        top_->eval();
        const bool request_valid = top_->gmem_req_valid_o != 0;
        const bool request_ready = top_->gmem_req_ready_i != 0;
        const bool request_fire = request_valid && request_ready;
        const bool response_fire = response_.active &&
                                   top_->gmem_rsp_ready_o != 0;
        if (!check_unaccepted_request_hold(request_valid, request_ready)) {
            return false;
        }
        if (request_fire && response_.occupied) {
            return fail(runner_f32_request_protocol);
        }
        response_slot accepted = {};
        if (request_fire) {
            accepted.occupied = true;
            accepted.write = top_->gmem_req_write_o != 0;
            accepted.address = top_->gmem_req_addr_o;
            accepted.data = top_->gmem_req_wdata_o;
            accepted.wstrb = top_->gmem_req_wstrb_o;
            accepted.due_cycle = clock_cycles_ + kResponseLatencyCycles;
            if (!prepare_response(&accepted)) {
                return false;
            }
        }
        top_->clk = 1;
        top_->eval();
        context_->timeInc(1);
        if (response_fire) {
            if (response_.write && !commit_write(response_)) {
                return false;
            }
            response_ = {};
            ++gmem_responses_accepted_;
        }
        if (request_fire) {
            response_ = accepted;
            ++gmem_requests_accepted_;
        }
        top_->clk = 0;
        top_->eval();
        context_->timeInc(1);
        ++clock_cycles_;
        return true;
    }

    bool check_unaccepted_request_hold(bool valid, bool ready) {
        if (valid && !ready) {
            if (!unaccepted_request_held_) {
                unaccepted_request_held_ = true;
                held_request_write_ = top_->gmem_req_write_o;
                held_request_address_ = top_->gmem_req_addr_o;
                held_request_data_ = top_->gmem_req_wdata_o;
                held_request_wstrb_ = top_->gmem_req_wstrb_o;
            } else if (held_request_write_ != top_->gmem_req_write_o ||
                       held_request_address_ != top_->gmem_req_addr_o ||
                       held_request_data_ != top_->gmem_req_wdata_o ||
                       held_request_wstrb_ != top_->gmem_req_wstrb_o) {
                return fail(runner_f32_request_protocol);
            }
        } else {
            unaccepted_request_held_ = false;
        }
        return true;
    }

    static bool address_in_window(
            std::uint64_t address,
            std::uint64_t base,
            std::size_t size) {
        return size >= 8 && address >= base &&
               address - base <= static_cast<std::uint64_t>(size - 8);
    }

    static std::uint64_t load_vector_word(
            const std::vector<std::uint8_t> & window,
            std::size_t offset) {
        std::uint64_t value = 0;
        for (std::size_t lane = 0; lane < 8; ++lane) {
            value |= static_cast<std::uint64_t>(window[offset + lane])
                     << (lane * 8);
        }
        return value;
    }

    bool prepare_response(response_slot * request) {
        if ((request->address & 7U) != 0) {
            return fail(runner_f32_request_protocol);
        }
        if (request->write) {
            if ((request->wstrb != 0x0f && request->wstrb != 0xf0) ||
                !address_in_window(request->address,
                                   submission_.dst_window_base,
                                   dst_window_.size())) {
                return fail(runner_f32_memory_bounds);
            }
            return true;
        }
        if (request->wstrb != 0) {
            return fail(runner_f32_request_protocol);
        }
        if (address_in_window(request->address,
                              submission_.src0_window_base,
                              src0_window_.size())) {
            request->data = load_vector_word(
                src0_window_, static_cast<std::size_t>(
                    request->address - submission_.src0_window_base));
            return true;
        }
        if (profile_.src1_present &&
            address_in_window(request->address,
                              submission_.src1_window_base,
                              src1_window_.size())) {
            request->data = load_vector_word(
                src1_window_, static_cast<std::size_t>(
                    request->address - submission_.src1_window_base));
            return true;
        }
        return fail(runner_f32_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        if (!address_in_window(request.address,
                               submission_.dst_window_base,
                               dst_window_.size())) {
            return fail(runner_f32_memory_bounds);
        }
        const std::size_t offset = static_cast<std::size_t>(
            request.address - submission_.dst_window_base);
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) != 0) {
                dst_window_[offset + lane] = static_cast<std::uint8_t>(
                    request.data >> (lane * 8));
            }
        }
        return true;
    }

    bool reset() {
        top_->rst = 1;
        for (unsigned index = 0; index < 4; ++index) {
            if (!tick()) {
                return false;
            }
        }
        top_->rst = 0;
        for (unsigned index = 0; index < 2; ++index) {
            if (!tick()) {
                return false;
            }
        }
        if (!top_->cmd_ready_o || !top_->macro_cmd_ready_o ||
            top_->busy_o || top_->error_o || top_->completion_valid_o ||
            top_->gmem_req_valid_o || top_->gmem_rsp_ready_o ||
            response_.occupied) {
            return fail(runner_reset_interface);
        }
        return true;
    }

    bool submit() {
        command_count_before_ = top_->macro_command_count_o;
        f32_start_count_before_ = top_->macro_f32_start_count_o;
        completion_count_before_ = top_->macro_completion_count_o;
        required_issued_before_ = top_->npu_required_issued_o;
        required_completed_before_ = top_->npu_required_completed_o;
        drive_submission();
        top_->eval();
        if (!top_->macro_cmd_ready_o || top_->completion_valid_o ||
            top_->busy_o || top_->error_o) {
            return fail(runner_command_interface);
        }
        if (!tick()) {
            return false;
        }
        drive_macro_idle();
        top_->eval();
        update_required_deltas();
        if (result_->required_issued_delta !=
                (is_required_transaction() ? 1U : 0U) ||
            result_->required_completed_delta != 0) {
            return fail(runner_f32_completion_protocol);
        }
        return true;
    }

    bool hold_and_check_completion(const completion_snapshot & snapshot) {
        result_->completion_stable = true;
        top_->completion_ready_i = 0;
        for (unsigned index = 0; index < kCompletionBackpressureCycles;
             ++index) {
            if (result_->completion_accepted ||
                result_->private_shadow_committed) {
                return fail(runner_f32_completion_protocol);
            }
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(runner_f32_completion_protocol);
            }
            if (!tick()) {
                return false;
            }
            update_required_deltas();
            const std::uint64_t expected_required =
                is_required_transaction() ? 1U : 0U;
            if (result_->required_issued_delta != expected_required ||
                result_->required_completed_delta != expected_required) {
                return fail(runner_f32_completion_protocol);
            }
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(runner_f32_completion_protocol);
            }
        }
        return true;
    }

    bool identity_matches(const completion_snapshot & snapshot) const {
        return snapshot.is_macro == 1 &&
               snapshot.legacy_producer_id == 0 &&
               snapshot.legacy_npu_required ==
                   (submission_.identity.command_flags & 1U) &&
               snapshot.legacy_opclass == 0 &&
               snapshot.kernel_id == submission_.kernel_id &&
               snapshot.command_flags == submission_.identity.command_flags &&
               snapshot.vector_flags == submission_.vector_flags &&
               snapshot.context_id == submission_.identity.context_id &&
               snapshot.sequence_id == submission_.identity.sequence_id &&
               snapshot.producer_id == submission_.identity.producer_id &&
               snapshot.user_tag == submission_.identity.user_tag &&
               snapshot.covered_node_count == 1 &&
               snapshot.node_hash_lo == submission_.identity.node_hash_lo &&
               snapshot.node_hash_hi == submission_.identity.node_hash_hi;
    }

    bool representative_identity_matches(
            const completion_snapshot & snapshot) const {
        const npu_f32_alu_representative_identity expected =
            representative_identity(profile_.profile_id);
        return snapshot.kernel_id == kMacroKernelVectorF32 &&
               snapshot.vector_flags == expected.profile_id &&
               snapshot.command_flags == expected.command_flags &&
               snapshot.context_id == expected.context_id &&
               snapshot.sequence_id == expected.sequence_id &&
               snapshot.producer_id == expected.producer_id &&
               snapshot.user_tag == expected.user_tag &&
               snapshot.covered_node_count == 1 &&
               snapshot.node_hash_lo == expected.node_hash_lo &&
               snapshot.node_hash_hi == expected.node_hash_hi;
    }

    bool is_required_transaction() const {
        return (submission_.identity.command_flags & 1U) != 0;
    }

    void update_required_deltas() {
        result_->required_issued_delta =
            top_->npu_required_issued_o - required_issued_before_;
        result_->required_completed_delta =
            top_->npu_required_completed_o - required_completed_before_;
    }

    void snapshot_result(const completion_snapshot & snapshot) {
        result_->completion_status = snapshot.status;
        result_->completion_error_class = snapshot.error_class;
        result_->completion_error_code = snapshot.error_code;
        result_->rtl_cycles = snapshot.npu_cycles;
        result_->gmem_read_bytes = snapshot.gmem_read_bytes;
        result_->gmem_write_bytes = snapshot.gmem_write_bytes;
        result_->vector_elements = snapshot.vector_element_count;
        result_->f32_start_count =
            top_->macro_f32_start_count_o - f32_start_count_before_;
        result_->commands_accepted =
            top_->macro_command_count_o - command_count_before_;
        result_->commands_terminal_success =
            top_->macro_completion_count_o - completion_count_before_;
        result_->commands_terminal_failure = snapshot.error ? 1 : 0;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        update_required_deltas();
    }

    bool validate_mode(const completion_snapshot & snapshot) {
        const std::uint64_t expected_required =
            is_required_transaction() ? 1U : 0U;
        if (result_->commands_accepted != 1 ||
            snapshot.status != snapshot.error_code ||
            gmem_requests_accepted_ != gmem_responses_accepted_ ||
            result_->required_issued_delta != expected_required ||
            result_->required_completed_delta != expected_required ||
            result_->observed_profile_id != result_->submitted_profile_id) {
            return false;
        }
        if (mode_ == npu_f32_alu_mode::positive) {
            const std::uint64_t expected_requests =
                profile_.expected_read_bytes / 8 +
                profile_.expected_write_bytes / 4;
            result_->controlled_reject = false;
            return snapshot.error == 0 && snapshot.status == 0 &&
                   snapshot.error_class == 0 &&
                   snapshot.gmem_read_bytes == profile_.expected_read_bytes &&
                   snapshot.gmem_write_bytes == profile_.expected_write_bytes &&
                   snapshot.vector_element_count == profile_.total_elements &&
                   snapshot.npu_cycles > 0 &&
                   snapshot.npu_cycles <= profile_.cycle_upper_bound &&
                   result_->f32_start_count == 1 &&
                   result_->commands_terminal_success == 1 &&
                   result_->commands_terminal_failure == 0 &&
                   (is_required_transaction() ?
                        !result_->representative_identity_match :
                        result_->representative_identity_match) &&
                   gmem_requests_accepted_ == expected_requests;
        }

        result_->controlled_reject = true;
        std::uint32_t expected_status = 15;
        std::uint32_t expected_class = 4;
        std::uint64_t expected_starts = 0;
        if (mode_ == npu_f32_alu_mode::unknown_kernel) {
            expected_status = kNpuErrMacroCapability;
            expected_class = kAbiErrorCapability;
        } else if (mode_ == npu_f32_alu_mode::out_of_range_4mod8 ||
                   mode_ == npu_f32_alu_mode::overlap ||
                   mode_ == npu_f32_alu_mode::overpermission) {
            expected_status = kNpuErrMacroIova;
            expected_class = kAbiErrorIova;
        } else if (mode_ == npu_f32_alu_mode::req_ready_low_timeout) {
            expected_status = kNpuErrMacroTimeout;
            expected_class = kAbiErrorTimeout;
            expected_starts = 1;
        }
        return snapshot.error == 1 &&
               snapshot.status == expected_status &&
               snapshot.error_class == expected_class &&
               snapshot.gmem_read_bytes == 0 &&
               snapshot.gmem_write_bytes == 0 &&
               snapshot.vector_element_count == 0 &&
               result_->f32_start_count == expected_starts &&
               result_->commands_terminal_success == 0 &&
               result_->commands_terminal_failure == 1 &&
               gmem_requests_accepted_ == 0;
    }

    bool consume_completion_and_recover(
            const completion_snapshot & snapshot,
            bool terminal_error) {
        if (!top_->completion_valid_o || result_->completion_accepted ||
            result_->private_shadow_committed ||
            !(capture_completion(*top_) == snapshot)) {
            return false;
        }
        top_->completion_ready_i = 1;
        top_->eval();
        if (!top_->completion_valid_o ||
            !(capture_completion(*top_) == snapshot)) {
            return false;
        }
        if (!tick()) {
            return false;
        }
        result_->completion_accepted = true;
        top_->completion_ready_i = 0;
        top_->eval();
        if (top_->completion_valid_o) {
            return false;
        }
        if (terminal_error) {
            if (!top_->error_o || top_->error_code_o == 0) {
                return false;
            }
            top_->error_clear_i = 1;
            if (!tick()) {
                return false;
            }
            top_->error_clear_i = 0;
            top_->eval();
        }
        update_required_deltas();
        const std::uint64_t expected_required =
            is_required_transaction() ? 1U : 0U;
        if (result_->required_issued_delta != expected_required ||
            result_->required_completed_delta != expected_required) {
            return false;
        }
        result_->recovery_clean =
            !top_->busy_o && !top_->error_o &&
            !top_->completion_valid_o && top_->cmd_ready_o &&
            top_->macro_cmd_ready_o && !top_->gmem_req_valid_o &&
            !top_->gmem_rsp_ready_o && !response_.occupied;
        return result_->recovery_clean;
    }

    bool fail(std::uint32_t error_code) {
        result_->passed = false;
        result_->runner_error_code = error_code;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        return false;
    }

    npu_f32_alu_profile profile_;
    npu_f32_alu_mode mode_;
    f32_alu_submission submission_;
    const std::uint8_t * src0_allocation_;
    std::size_t src0_allocation_bytes_;
    const std::uint8_t * src1_allocation_;
    std::size_t src1_allocation_bytes_;
    std::uint8_t * dst_shadow_;
    std::size_t dst_shadow_bytes_;
    const std::uint8_t * expected_shadow_;
    std::size_t expected_shadow_bytes_;
    npu_verilator_f32_alu_result * result_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> top_;
    npu_f32_alu_span src0_span_ = {};
    npu_f32_alu_span src1_span_ = {};
    std::vector<std::uint8_t> src0_window_;
    std::vector<std::uint8_t> src1_window_;
    std::vector<std::uint8_t> dst_window_;
    response_slot response_ = {};
    bool inputs_valid_ = false;
    bool unaccepted_request_held_ = false;
    std::uint32_t held_request_write_ = 0;
    std::uint64_t held_request_address_ = 0;
    std::uint64_t held_request_data_ = 0;
    std::uint32_t held_request_wstrb_ = 0;
    std::uint64_t clock_cycles_ = 0;
    std::uint64_t gmem_requests_accepted_ = 0;
    std::uint64_t gmem_responses_accepted_ = 0;
    std::uint64_t command_count_before_ = 0;
    std::uint64_t f32_start_count_before_ = 0;
    std::uint64_t completion_count_before_ = 0;
    std::uint64_t required_issued_before_ = 0;
    std::uint64_t required_completed_before_ = 0;
};
#endif

#if defined(NPU_PRODUCTION_SYSTEM_RUNNER)
void copy_system_result(
        const npu_verilator_exact_result & source,
        npu_verilator_f32_alu_result * destination) {
    destination->passed = source.passed;
    destination->controlled_reject = source.controlled_reject;
    destination->private_shadow_committed =
        source.private_shadow_committed;
    destination->completion_identity_match =
        source.completion_identity_match;
    destination->completion_framing_valid =
        source.completion_framing_valid;
    destination->completion_stable = source.completion_stable;
    destination->recovery_clean = source.recovery_clean;
    destination->completion_emitted = source.completion_emitted;
    destination->completion_accepted = source.completion_accepted;
    destination->profile_id = source.manifest_profile_id;
    destination->submitted_profile_id = source.submitted_local_profile;
    destination->observed_profile_id = source.observed_local_profile;
    destination->completion_status = source.completion_status;
    destination->completion_error_class = source.completion_error_class;
    destination->completion_error_code = source.completion_error_code;
    destination->rtl_cycles = source.rtl_cycles;
    destination->cycle_upper_bound = source.cycle_upper_bound;
    destination->gmem_read_bytes = source.gmem_read_bytes;
    destination->gmem_write_bytes = source.gmem_write_bytes;
    destination->vector_elements = source.vector_elements;
    destination->f32_start_count = source.f32_start_count;
    destination->commands_accepted = source.commands_accepted;
    destination->commands_terminal_success =
        source.commands_terminal_success;
    destination->commands_terminal_failure =
        source.commands_terminal_failure;
    destination->gmem_requests_accepted =
        source.gmem_requests_accepted;
    destination->gmem_responses_accepted =
        source.gmem_responses_accepted;
    destination->first_request_hold_cycles =
        source.first_request_hold_cycles;
    destination->result_bytes = source.result_bytes;
    destination->required_issued_delta = source.required_issued_delta;
    destination->required_completed_delta =
        source.required_completed_delta;
    destination->system_transport = source.system_transport;
    destination->cpu_memory_separate = source.cpu_memory_separate;
    destination->cpu_terminal_identity_match =
        source.cpu_terminal_identity_match;
    destination->system_cycles = source.system_cycles;
    destination->public_commands_accepted =
        source.public_commands_accepted;
    destination->public_completions = source.public_completions;
    destination->public_errors = source.public_errors;
    destination->cpu_config_commands_accepted =
        source.cpu_config_commands_accepted;
    destination->cpu_tensor_commands_accepted =
        source.cpu_tensor_commands_accepted;
    destination->cpu_terminals_accepted =
        source.cpu_terminals_accepted;
    destination->cpu_config_commits = source.cpu_config_commits;
    destination->cpu_launch_commits = source.cpu_launch_commits;
    destination->cpu_launch_instruction = source.cpu_launch_instruction;
    destination->cpu_launch_pid = source.cpu_launch_pid;
    destination->q8_portal = source.q8_portal;
    destination->f32_alu_portal = source.f32_alu_portal;
    destination->f32_mover_portal = source.f32_mover_portal;
    destination->submitted_identity = source.submitted_identity;
    destination->returned_identity = source.returned_identity;
}
#endif

} // namespace

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
bool npu_verilator_run_mm2_self_test(npu_verilator_self_test_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    try {
        coprocessor_harness harness(result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->error_code = runner_allocation;
        return false;
    }
}

bool npu_verilator_execute_f32_add(
        const std::uint32_t * src0_bits,
        const std::uint32_t * src1_bits,
        std::uint32_t * dst_bits,
        npu_verilator_f32_add_result * result) {
    if (src0_bits == nullptr || src1_bits == nullptr || dst_bits == nullptr ||
        result == nullptr) {
        return false;
    }
    *result = {};
    try {
        f32_add_harness harness(
            npu_f32_add_mode::positive,
            src0_bits,
            src1_bits,
            dst_bits,
            false,
            result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}

bool npu_verilator_run_f32_add_self_test(
        npu_f32_add_mode mode,
        npu_verilator_f32_add_result * result) {
    if (result == nullptr ||
        static_cast<std::uint32_t>(mode) >
            static_cast<std::uint32_t>(
                npu_f32_add_mode::overpermission)) {
        return false;
    }
    *result = {};
    std::array<std::uint32_t, kF32ElementCount> output = {};
    try {
        f32_add_harness harness(
            mode,
            kF32Input0.data(),
            kF32Input1.data(),
            output.data(),
            true,
            result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}
#endif

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

#if defined(NPU_PRODUCTION_SYSTEM_RUNNER)
bool npu_verilator_execute_f32_alu(
        std::uint32_t profile_id,
        const npu_f32_alu_representative_identity * canonical_identity,
        bool zero_cardinality,
        const std::uint8_t * src0_allocation,
        std::size_t src0_allocation_bytes,
        const std::uint8_t * src1_allocation,
        std::size_t src1_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_f32_alu_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    npu_f32_alu_profile profile = {};
    if (!npu_f32_alu_profile_by_id(profile_id, &profile)) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    if (zero_cardinality && profile_id != 17U && profile_id != 18U) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    const bool canonical_required = canonical_identity != nullptr;
    if (zero_cardinality && !canonical_required) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    const npu_f32_alu_representative_identity transaction_identity =
        canonical_required ? *canonical_identity :
                             representative_identity(profile_id);
    const bool digest_is_nonzero =
        transaction_identity.sequence_id != 0 ||
        transaction_identity.producer_id != 0 ||
        transaction_identity.node_hash_lo != 0 ||
        transaction_identity.node_hash_hi != 0;
    if (transaction_identity.profile_id != profile_id ||
        transaction_identity.command_flags !=
            (canonical_required ? kCanonicalCommandFlags :
                                  kRepresentativeCommandFlags) ||
        (canonical_required &&
         transaction_identity.context_id != 0x43414e01U) ||
        !digest_is_nonzero) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    npu_f32_alu_span src0_span = {};
    npu_f32_alu_span src1_span = {};
    if ((!zero_cardinality && !source_span_checked(profile.src0, &src0_span)) ||
        (profile.src1_present &&
         !zero_cardinality && !source_span_checked(profile.src1, &src1_span)) ||
        (!zero_cardinality && (src0_allocation == nullptr ||
         src0_allocation_bytes < src0_span.beat_hi)) ||
        (!zero_cardinality && profile.src1_present &&
         (src1_allocation == nullptr ||
          src1_allocation_bytes < src1_span.beat_hi)) ||
        (!profile.src1_present &&
         (src1_allocation != nullptr || src1_allocation_bytes != 0)) ||
        (!zero_cardinality && (dst_shadow == nullptr ||
         dst_shadow_bytes != profile.expected_write_bytes)) ||
        (zero_cardinality &&
         (src0_allocation != nullptr || src0_allocation_bytes != 0U ||
          src1_allocation != nullptr || src1_allocation_bytes != 0U ||
          dst_shadow != nullptr || dst_shadow_bytes != 0U))) {
        result->runner_error_code = runner_f32_span;
        return false;
    }
    try {
        std::vector<std::uint8_t> src0_window(
            zero_cardinality ? 0U :
            static_cast<std::size_t>(src0_span.beat_hi), 0U);
        const std::size_t src0_lo =
            static_cast<std::size_t>(src0_span.beat_lo);
        const std::size_t src0_count = static_cast<std::size_t>(
            src0_span.beat_hi - src0_span.beat_lo);
        if (!zero_cardinality) {
            std::memcpy(src0_window.data() + src0_lo,
                        src0_allocation + src0_lo, src0_count);
        }
        std::vector<std::uint8_t> src1_window;
        if (profile.src1_present) {
            src1_window.assign(
                static_cast<std::size_t>(src1_span.beat_hi), 0U);
            const std::size_t src1_lo =
                static_cast<std::size_t>(src1_span.beat_lo);
            const std::size_t src1_count = static_cast<std::size_t>(
                src1_span.beat_hi - src1_span.beat_lo);
            std::memcpy(src1_window.data() + src1_lo,
                        src1_allocation + src1_lo, src1_count);
        }
        std::vector<std::uint8_t> private_dst(
            zero_cardinality ? 0U :
            static_cast<std::size_t>(profile.expected_write_bytes), 0xa5U);
        std::vector<std::uint8_t> expected_write(
            zero_cardinality ? 0U :
            static_cast<std::size_t>(profile.expected_write_bytes), 1U);
        npu_system_transaction transaction = {};
        transaction.manifest_profile_id = profile.profile_id;
        transaction.identity = transaction_identity;
        npu_exact_command_contract & command = transaction.command;
        command.abi_valid = 1U;
        command.windows_generation_valid = 1U;
        command.kernel_id = kMacroKernelVectorF32;
        command.vector_op = profile.vector_op;
        command.local_profile = profile.profile_id;
        command.command_flags = transaction_identity.command_flags;
        command.context_id = transaction_identity.context_id;
        command.capability_epoch = kMacroCapabilityEpoch;
        command.node_count = 1U;
        command.sequence_id = transaction_identity.sequence_id;
        command.producer_id = transaction_identity.producer_id;
        command.user_tag = transaction_identity.user_tag;
        command.node_hash_lo = transaction_identity.node_hash_lo;
        command.node_hash_hi = transaction_identity.node_hash_hi;
        command.src0_iova = zero_cardinality ? kF32AluSrc0Base :
            kF32AluSrc0Base + profile.src0.view_off;
        command.src1_iova = profile.src1_present ?
            kF32AluSrc1Base + profile.src1.view_off : 0U;
        command.dst_iova = kF32AluDstBase;
        command.element_count = zero_cardinality ? 0U : profile.element_count;
        command.outer_count = zero_cardinality ? 1U :
            static_cast<std::uint32_t>(profile.outer_count);
        command.dtype = 1U;
        command.src0_stride = zero_cardinality ? 0U : profile.src0.nb[1];
        command.src1_stride = profile.src1_present ? profile.src1.nb[1] : 0U;
        command.dst_stride = zero_cardinality ? 0U : profile.dst.nb[1];
        command.scalar0 = profile.scalar0;
        command.src0_window_base = kF32AluSrc0Base;
        command.src0_window_size = zero_cardinality ? 0U : src0_span.beat_hi;
        command.src0_window_perm = 1U;
        command.src1_window_base =
            profile.src1_present ? kF32AluSrc1Base : 0U;
        command.src1_window_size =
            profile.src1_present ? src1_span.beat_hi : 0U;
        // The public F32 adapter requires a genuinely absent unary source;
        // binary profiles encode 0x97 and unary P16--P18 encode 0x87.
        command.src1_window_perm = profile.src1_present ? 1U : 0U;
        command.dst_window_base = kF32AluDstBase;
        command.dst_window_size = zero_cardinality ? 0U :
            profile.expected_write_bytes;
        command.dst_window_perm = 2U;
        transaction.sources[0] = {
            kF32AluSrc0Base,
            zero_cardinality ? nullptr : src0_window.data(), nullptr,
            src0_window.size(),
            kF32AluSrc0Base,
            zero_cardinality ? 0U : src0_span.beat_hi,
            true, false,
        };
        transaction.sources[1] = {
            profile.src1_present ? kF32AluSrc1Base : 0U,
            profile.src1_present ? src1_window.data() : nullptr,
            nullptr, src1_window.size(),
            profile.src1_present ? kF32AluSrc1Base : 0U,
            profile.src1_present ? src1_span.beat_hi : 0U,
            profile.src1_present, false,
        };
        transaction.destination = {
            kF32AluDstBase, nullptr,
            zero_cardinality ? nullptr : private_dst.data(),
            private_dst.size(), kF32AluDstBase,
            zero_cardinality ? 0U : profile.expected_write_bytes,
            false, true,
        };
        transaction.expected_write_mask = expected_write.data();
        transaction.expected_write_mask_bytes = expected_write.size();
        transaction.expected_semantic_write_bytes =
            zero_cardinality ? 0U : profile.expected_write_bytes;
        // The production raw32 portal owns every tensor word.  The public
        // macro GMEM completion ledger must consequently remain identically
        // zero even though semantic destination coverage is still complete.
        transaction.expected_read_bytes = 0U;
        transaction.expected_write_bytes = 0U;
        transaction.expected_vector_elements =
            zero_cardinality ? 0U : profile.total_elements;
        transaction.expected_read_requests = 0U;
        transaction.expected_write_requests = 0U;
        transaction.expected_f32_starts = zero_cardinality ? 0U : 1U;
        transaction.expected_required_issued = canonical_required ? 1U : 0U;
        transaction.expected_required_completed =
            canonical_required ? 1U : 0U;
        transaction.expected_public_completions = 1U;
        transaction.expected_macro_completions = 1U;
        transaction.cycle_upper_bound = profile.cycle_upper_bound;
        const std::uint64_t portal_elements =
            zero_cardinality ? 0U : profile.total_elements;
        const std::uint64_t portal_groups = (portal_elements + 7U) / 8U;
        transaction.f32_alu_portal = {
            true,
            8U,
            2U,
            portal_groups * 2U,
            portal_groups * 2U,
            portal_groups,
            portal_groups,
            portal_elements * (profile.src1_present ? 2U : 1U),
            portal_elements,
            portal_elements * (profile.src1_present ? 8U : 4U),
            portal_elements * 4U,
        };

        const std::uint64_t effective_elements =
            static_cast<std::uint64_t>(command.element_count) *
            command.outer_count;
        if ((zero_cardinality &&
             ((profile.profile_id != 17U && profile.profile_id != 18U) ||
              effective_elements != 0U)) ||
            (!zero_cardinality &&
             effective_elements != profile.total_elements)) {
            result->runner_error_code = runner_f32_profile;
            return false;
        }

        npu_verilator_exact_result system_result = {};
        const bool executed = npu_verilator_execute_system_transaction(
            &transaction, &system_result);
        copy_system_result(system_result, result);
        result->representative_identity_match = !canonical_required &&
            system_result.completion_identity_match;
        if (!executed || system_result.controlled_reject) {
            result->passed = false;
            // Preserve the shared SystemTop transport's fail-closed reason.
            // Collapsing every transport/protocol failure into the adapter's
            // mode mismatch makes a pre-launch CPU failure indistinguishable
            // from a genuine controlled-mode mismatch.
            result->runner_error_code = system_result.runner_error_code != 0 ?
                system_result.runner_error_code : runner_f32_mode_mismatch;
            return false;
        }
        if (zero_cardinality) {
            // The exact runner's empty expected-write mask is a successful
            // semantic closure, but the backend-facing result must not claim
            // that any destination shadow was committed or published.
            result->private_shadow_committed = false;
            result->result_bytes = 0U;
        } else {
            std::memcpy(dst_shadow, private_dst.data(), private_dst.size());
            result->private_shadow_committed = true;
            result->result_bytes = private_dst.size();
        }
        result->runner_error_code = runner_ok;
        return true;
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}

bool npu_verilator_run_f32_alu_self_test(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result) {
    if (result == nullptr ||
        static_cast<std::uint32_t>(mode) >
            static_cast<std::uint32_t>(
                npu_f32_alu_mode::req_ready_low_timeout)) {
        return false;
    }
    // Negative direct-port protocol mutations remain an explicit, isolated
    // non-production probe.  Every positive profile below uses the real
    // SystemTop CPU descriptor/launch transport.
    if (mode != npu_f32_alu_mode::positive) {
        return npu_verilator_run_direct_f32_alu_self_test(
            profile_id, mode, result);
    }

    *result = {};
    npu_f32_alu_profile profile = {};
    npu_f32_alu_span src0_span = {};
    npu_f32_alu_span src1_span = {};
    if (!npu_f32_alu_profile_by_id(profile_id, &profile) ||
        !npu_f32_alu_source_span(profile.src0, &src0_span) ||
        (profile.src1_present &&
         !npu_f32_alu_source_span(profile.src1, &src1_span))) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    try {
        std::vector<std::uint8_t> src0(
            static_cast<std::size_t>(src0_span.beat_hi), 0U);
        std::vector<std::uint8_t> src1;
        if (profile.src1_present) {
            src1.assign(
                static_cast<std::size_t>(src1_span.beat_hi), 0U);
        }
        std::vector<std::uint8_t> dst(
            static_cast<std::size_t>(profile.expected_write_bytes), 0xa5U);
        std::vector<std::uint8_t> expected(dst.size(), 0xa5U);
        if (!prepare_identity_oracle(profile, &src0, &src1, &expected)) {
            result->runner_error_code = runner_result_mismatch;
            return false;
        }
        const bool executed = npu_verilator_execute_f32_alu(
            profile_id,
            nullptr,
            false,
            src0.data(), src0.size(),
            profile.src1_present ? src1.data() : nullptr,
            src1.size(),
            dst.data(), dst.size(),
            result);
        if (!executed) {
            return false;
        }
        if (dst != expected) {
            result->passed = false;
            result->private_shadow_committed = false;
            result->runner_error_code = runner_result_mismatch;
            return false;
        }
        std::fprintf(
            stdout,
            "[NPU-SYSTEM-PROFILE][PASS] profile=P%02u dispatch=1 "
            "system_transactions=%u cpu_config_commands=%llu "
            "cpu_tensor_commands=%llu cpu_terminals=%llu "
            "cpu_config_commits=%llu cpu_launch_commits=%llu "
            "public_commands=%llu public_completions=%llu "
            "public_errors=%llu required_issued=%llu "
            "required_completed=%llu cpu_pid_identity_mismatch=%u "
            "macro_identity_mismatch=%u cpu_memory_separate=%u "
            "first_request_hold_cycles=%llu "
            "alu_portal_req=%llu alu_portal_rsp=%llu "
            "alu_portal_read_words=%llu alu_portal_write_words=%llu "
            "alu_portal_read_bytes=%llu alu_portal_write_bytes=%llu "
            "functional_dispatch=%llu functional_completion=%llu "
            "functional_success=%llu functional_failure=%llu "
            "functional_read_words=%llu functional_write_words=%llu "
            "functional_read_bytes=%llu functional_write_bytes=%llu "
            "functional_vector_elements=%llu functional_callback_errors=%llu "
            "functional_command_mismatches=%llu functional_protocol_errors=%llu "
            "old_gmem_req=%llu old_gmem_rsp=%llu old_q8_portal=%llu "
            "old_f32_alu_portal=%llu old_f32_mover_portal=%llu "
            "raw_oracle=1 rtl_cycles=%llu system_cycles=%llu "
            "read=%llu write=%llu elements=%llu\n",
            profile_id,
            result->system_transport ? 1U : 0U,
            static_cast<unsigned long long>(
                result->cpu_config_commands_accepted),
            static_cast<unsigned long long>(
                result->cpu_tensor_commands_accepted),
            static_cast<unsigned long long>(result->cpu_terminals_accepted),
            static_cast<unsigned long long>(result->cpu_config_commits),
            static_cast<unsigned long long>(result->cpu_launch_commits),
            static_cast<unsigned long long>(
                result->public_commands_accepted),
            static_cast<unsigned long long>(result->public_completions),
            static_cast<unsigned long long>(result->public_errors),
            static_cast<unsigned long long>(result->required_issued_delta),
            static_cast<unsigned long long>(result->required_completed_delta),
            result->cpu_terminal_identity_match ? 0U : 1U,
            result->completion_identity_match ? 0U : 1U,
            result->cpu_memory_separate ? 1U : 0U,
            static_cast<unsigned long long>(
                result->first_request_hold_cycles),
            static_cast<unsigned long long>(
                result->f32_alu_portal.request_groups),
            static_cast<unsigned long long>(
                result->f32_alu_portal.response_groups),
            static_cast<unsigned long long>(
                result->f32_alu_portal.read_words),
            static_cast<unsigned long long>(
                result->f32_alu_portal.write_words),
            static_cast<unsigned long long>(
                result->f32_alu_portal.read_bytes),
            static_cast<unsigned long long>(
                result->f32_alu_portal.write_bytes),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.dispatches),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.completions),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.successes),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.failures),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.read_words),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.write_words),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.read_bytes),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.write_bytes),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.vector_elements),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.callback_errors),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.command_mismatches),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.protocol_errors),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.old_gmem_requests),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.old_gmem_responses),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.
                    old_q8_portal_transactions),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.
                    old_f32_alu_portal_transactions),
            static_cast<unsigned long long>(
                result->f32_alu_portal.functional_command.
                    old_f32_mover_portal_transactions),
            static_cast<unsigned long long>(result->rtl_cycles),
            static_cast<unsigned long long>(result->system_cycles),
            static_cast<unsigned long long>(result->gmem_read_bytes),
            static_cast<unsigned long long>(result->gmem_write_bytes),
            static_cast<unsigned long long>(result->vector_elements));
        return result->passed;
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}
#endif

#if !defined(NPU_PRODUCTION_SYSTEM_RUNNER)
bool npu_verilator_run_f32_alu_self_test(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result) {
    if (result == nullptr ||
        static_cast<std::uint32_t>(mode) >
            static_cast<std::uint32_t>(
                npu_f32_alu_mode::req_ready_low_timeout)) {
        return false;
    }
    *result = {};
    npu_f32_alu_profile profile = {};
    npu_f32_alu_span src0_span = {};
    npu_f32_alu_span src1_span = {};
    if (!npu_f32_alu_profile_by_id(profile_id, &profile) ||
        !npu_f32_alu_source_span(profile.src0, &src0_span) ||
        (profile.src1_present &&
         !npu_f32_alu_source_span(profile.src1, &src1_span))) {
        result->runner_error_code = runner_f32_profile;
        return false;
    }
    try {
        std::vector<std::uint8_t> src0(
            static_cast<std::size_t>(src0_span.beat_hi), 0);
        std::vector<std::uint8_t> src1;
        if (profile.src1_present) {
            src1.assign(static_cast<std::size_t>(src1_span.beat_hi), 0);
        }
        std::vector<std::uint8_t> dst(
            static_cast<std::size_t>(profile.expected_write_bytes), 0xa5);
        std::vector<std::uint8_t> expected(
            static_cast<std::size_t>(profile.expected_write_bytes), 0xa5);
        if (!prepare_identity_oracle(
                profile, &src0, &src1, &expected)) {
            result->runner_error_code = runner_result_mismatch;
            return false;
        }
        f32_alu_harness harness(
            profile,
            mode,
            nullptr,
            src0.data(),
            src0.size(),
            profile.src1_present ? src1.data() : nullptr,
            src1.size(),
            dst.data(),
            dst.size(),
            mode == npu_f32_alu_mode::positive ? expected.data() : nullptr,
            mode == npu_f32_alu_mode::positive ? expected.size() : 0,
            result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = runner_allocation;
        return false;
    }
}
#endif
