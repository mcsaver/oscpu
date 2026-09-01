// SPDX-License-Identifier: MIT
//
// Simulation functional unit for TensorNpuQ8RowTileFunctionalCore.
//
// This translation unit has no allocation/address/transport API.  Its only
// inputs are packed raw Q8_0 blocks supplied by RTL through DPI-C.  Arithmetic
// follows ggml b10507 ggml_vec_dot_q8_0_q8_0_generic in strict block order:
//
//   sumi  = int32 dot(qx, qy)
//   scale = RN32(fp32(dx) * fp32(dy))
//   term  = RN32(fp32(sumi) * scale)
//   acc   = RN32(acc + term)
//
// Each FP32 operation is isolated in a noinline helper, has exactly one
// arithmetic operator, and is compiled with -fno-fast-math,
// -ffp-contract=off, and -frounding-math.  No FMA or reassociation is used.

#include <svdpi.h>

#include <cfenv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>

namespace {

constexpr int kStatusOk = 0;
constexpr int kStatusNonfiniteScale = 1;
constexpr int kStatusDotRange = 2;
constexpr int kStatusFp32Numeric = 3;
constexpr int kStatusContract = 4;
constexpr std::uint32_t kQ8BlockBits = 272;
constexpr std::uint32_t kQ8Elements = 32;
constexpr int kFatalFpExceptions = FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW;

#if defined(__GNUC__) || defined(__clang__)
#define NPU_NOINLINE __attribute__((noinline))
#else
#define NPU_NOINLINE
#endif

class ScopedRoundToNearest final {
  public:
    ScopedRoundToNearest() noexcept : saved_(std::fegetround()) {
        valid_ = saved_ != -1 && std::fesetround(FE_TONEAREST) == 0;
    }

    ~ScopedRoundToNearest() {
        if (valid_ && saved_ != FE_TONEAREST) {
            (void) std::fesetround(saved_);
        }
    }

    ScopedRoundToNearest(const ScopedRoundToNearest &) = delete;
    ScopedRoundToNearest & operator=(const ScopedRoundToNearest &) = delete;

    bool valid() const noexcept { return valid_; }

  private:
    int saved_ = -1;
    bool valid_ = false;
};

std::uint32_t raw_float_bits(float value) noexcept {
    std::uint32_t bits = 0;
    static_assert(sizeof(bits) == sizeof(value));
    std::memcpy(&bits, &value, sizeof(bits));
    return bits;
}

float float_from_raw_bits(std::uint32_t bits) noexcept {
    float value = 0.0F;
    static_assert(sizeof(bits) == sizeof(value));
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}

std::uint32_t read_packed_bits(const svBitVecVal * words,
                               std::uint64_t bit_offset,
                               unsigned width) noexcept {
    const std::size_t word_index = static_cast<std::size_t>(bit_offset >> 5U);
    const unsigned shift = static_cast<unsigned>(bit_offset & 31U);
    std::uint64_t joined = static_cast<std::uint32_t>(words[word_index]);
    if (shift + width > 32U) {
        joined |= static_cast<std::uint64_t>(
                      static_cast<std::uint32_t>(words[word_index + 1U]))
                  << 32U;
    }
    const std::uint64_t mask = width == 32U
                             ? std::numeric_limits<std::uint32_t>::max()
                             : ((std::uint64_t{1} << width) - 1U);
    return static_cast<std::uint32_t>((joined >> shift) & mask);
}

bool fp16_to_finite_float(std::uint16_t half_bits, float * value) noexcept {
    const std::uint32_t sign = static_cast<std::uint32_t>(half_bits >> 15U);
    const std::uint32_t exponent = (half_bits >> 10U) & 0x1fU;
    std::uint32_t fraction = half_bits & 0x03ffU;
    std::uint32_t fp32_bits = sign << 31U;

    if (exponent == 0x1fU) {
        return false;
    }
    if (exponent == 0U) {
        if (fraction == 0U) {
            *value = float_from_raw_bits(fp32_bits);
            return true;
        }
        int unbiased_exponent = -14;
        while ((fraction & 0x0400U) == 0U) {
            fraction <<= 1U;
            --unbiased_exponent;
        }
        fraction &= 0x03ffU;
        fp32_bits |= static_cast<std::uint32_t>(unbiased_exponent + 127)
                     << 23U;
        fp32_bits |= fraction << 13U;
    } else {
        fp32_bits |= (exponent + 112U) << 23U;
        fp32_bits |= fraction << 13U;
    }
    *value = float_from_raw_bits(fp32_bits);
    return true;
}

NPU_NOINLINE bool multiply_rn32(float lhs, float rhs,
                                float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float product_rn = lhs_rn * rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float published = product_rn;
    if (exceptions != 0 || !std::isfinite(published)) {
        return false;
    }
    *result = published;
    return true;
}

NPU_NOINLINE bool add_rn32(float lhs, float rhs, float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float sum_rn = lhs_rn + rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float published = sum_rn;
    if (exceptions != 0 || !std::isfinite(published)) {
        return false;
    }
    *result = published;
    return true;
}

int signed_q8(std::uint32_t raw_byte) noexcept {
    return raw_byte < 128U ? static_cast<int>(raw_byte)
                           : static_cast<int>(raw_byte) - 256;
}

}  // namespace

extern "C" int npu_q8_row_tile_compute(
    unsigned int row_lanes,
    unsigned int max_blocks,
    unsigned int block_count,
    const svBitVecVal * activation_blocks,
    const svBitVecVal * weight_blocks,
    unsigned int lane_mask,
    svBitVecVal * result_bits) {
    if (activation_blocks == nullptr || weight_blocks == nullptr
        || result_bits == nullptr || row_lanes == 0U || row_lanes > 8U
        || max_blocks == 0U || max_blocks > 128U || block_count == 0U
        || block_count > max_blocks || lane_mask == 0U
        || (lane_mask >> row_lanes) != 0U) {
        return kStatusContract;
    }

    for (unsigned int lane = 0; lane < row_lanes; ++lane) {
        result_bits[lane] = 0U;
    }

    ScopedRoundToNearest rounding_scope;
    if (!rounding_scope.valid()) {
        return kStatusContract;
    }

    for (unsigned int lane = 0; lane < row_lanes; ++lane) {
        if ((lane_mask & (1U << lane)) == 0U) {
            continue;
        }

        float accumulator = float_from_raw_bits(0x00000000U);
        for (unsigned int block = 0; block < block_count; ++block) {
            const std::uint64_t activation_base =
                static_cast<std::uint64_t>(block) * kQ8BlockBits;
            const std::uint64_t weight_base =
                (static_cast<std::uint64_t>(lane) * max_blocks + block)
                * kQ8BlockBits;

            const std::uint16_t activation_scale_bits =
                static_cast<std::uint16_t>(read_packed_bits(
                    activation_blocks, activation_base, 16U));
            const std::uint16_t weight_scale_bits =
                static_cast<std::uint16_t>(read_packed_bits(
                    weight_blocks, weight_base, 16U));

            float activation_scale = 0.0F;
            float weight_scale = 0.0F;
            if (!fp16_to_finite_float(activation_scale_bits,
                                      &activation_scale)
                || !fp16_to_finite_float(weight_scale_bits, &weight_scale)) {
                return kStatusNonfiniteScale;
            }

            std::int64_t dot_wide = 0;
            for (unsigned int element = 0; element < kQ8Elements;
                 ++element) {
                const std::uint64_t byte_offset = 16U + element * 8U;
                const int activation_q = signed_q8(read_packed_bits(
                    activation_blocks, activation_base + byte_offset, 8U));
                const int weight_q = signed_q8(read_packed_bits(
                    weight_blocks, weight_base + byte_offset, 8U));
                dot_wide += static_cast<std::int64_t>(activation_q)
                          * static_cast<std::int64_t>(weight_q);
            }
            if (dot_wide < std::numeric_limits<std::int32_t>::min()
                || dot_wide > std::numeric_limits<std::int32_t>::max()) {
                return kStatusDotRange;
            }

            // A 32-element signed-Q8 dot is bounded by 2^19, so this int32
            // conversion is exact in binary32, matching TensorNpuInt32ToFp32.
            volatile float dot_float_rn = static_cast<float>(
                static_cast<std::int32_t>(dot_wide));
            const float dot_float = dot_float_rn;

            float scale_product = 0.0F;
            if (!multiply_rn32(weight_scale, activation_scale,
                               &scale_product)) {
                return kStatusFp32Numeric;
            }

            float term = 0.0F;
            if (!multiply_rn32(dot_float, scale_product, &term)) {
                return kStatusFp32Numeric;
            }

            float next_accumulator = 0.0F;
            if (!add_rn32(accumulator, term, &next_accumulator)) {
                return kStatusFp32Numeric;
            }
            accumulator = next_accumulator;
        }
        result_bits[lane] = raw_float_bits(accumulator);
    }
    return kStatusOk;
}

