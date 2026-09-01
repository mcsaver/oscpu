// SPDX-License-Identifier: MIT
//
// Simulation-only numerical functional unit for the production command-DPI
// path.  This translation unit is the sole host-language location allowed to
// perform tensor arithmetic.  It never receives or discovers a ggml/tensor
// pointer: every payload byte crosses the thread-local checked-copy boundary.

#include "npu-functional-command-dpi.h"

#include <array>
#include <cfenv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>
#include <new>
#include <utility>
#include <vector>

namespace {

constexpr std::uint32_t kKernelQ8GetRows = 0x514e0001U;
constexpr std::uint32_t kKernelQ8Gemv = 0x514e0002U;
constexpr std::uint32_t kKernelF32GetRows = 0x514e0003U;
constexpr std::uint32_t kKernelF32Repeat = 0x514e0004U;
constexpr std::uint32_t kKernelMover = 0x514e0007U;
constexpr std::uint32_t kKernelSetRows = 0x514e0008U;
constexpr std::uint32_t kKernelVectorF32 = 0x514e0010U;

constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kDtypeF32 = 1U;
constexpr std::uint32_t kQ8BlockElements = 32U;
constexpr std::uint32_t kQ8BlockBytes = 34U;

constexpr std::uint32_t kErrorMacroCapability = 14U;
constexpr std::uint32_t kErrorMacroLayout = 15U;
constexpr std::uint32_t kErrorMacroIova = 16U;
constexpr std::uint32_t kErrorMacroProtocol = 18U;
constexpr std::uint32_t kErrorClassCapability = 3U;
constexpr std::uint32_t kErrorClassLayout = 4U;
constexpr std::uint32_t kErrorClassIova = 5U;
constexpr std::uint32_t kErrorClassProtocol = 11U;

constexpr int kFatalFpExceptions = FE_INVALID | FE_DIVBYZERO | FE_OVERFLOW;

#if defined(__GNUC__) || defined(__clang__)
#define NPU_NOINLINE __attribute__((noinline))
#else
#define NPU_NOINLINE
#endif

thread_local npu_functional_command_capability_context *
    g_functional_capabilities = nullptr;

bool checked_add(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * value) noexcept {
    if (value == nullptr ||
        rhs > std::numeric_limits<std::uint64_t>::max() - lhs) {
        return false;
    }
    *value = lhs + rhs;
    return true;
}

bool checked_mul(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * value) noexcept {
    if (value == nullptr ||
        (lhs != 0U &&
         rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *value = lhs * rhs;
    return true;
}

bool checked_size(std::uint64_t value, std::size_t * size) noexcept {
    if (size == nullptr || value > std::numeric_limits<std::size_t>::max()) {
        return false;
    }
    *size = static_cast<std::size_t>(value);
    return true;
}

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

bool finite_fp32_bits(std::uint32_t bits) noexcept {
    return ((bits >> 23U) & 0xffU) != 0xffU;
}

class scoped_round_to_nearest final {
public:
    scoped_round_to_nearest() noexcept : saved_(std::fegetround()) {
        valid_ = saved_ != -1 && std::fesetround(FE_TONEAREST) == 0;
    }

    ~scoped_round_to_nearest() {
        if (valid_ && saved_ != FE_TONEAREST) {
            (void) std::fesetround(saved_);
        }
    }

    scoped_round_to_nearest(const scoped_round_to_nearest &) = delete;
    scoped_round_to_nearest & operator=(
        const scoped_round_to_nearest &) = delete;

    bool valid() const noexcept { return valid_; }

private:
    int saved_ = -1;
    bool valid_ = false;
};

NPU_NOINLINE bool add_rn32(float lhs, float rhs, float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float value_rn = lhs_rn + rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float value = value_rn;
    if (result == nullptr || exceptions != 0 || !std::isfinite(value)) {
        return false;
    }
    *result = value;
    return true;
}

NPU_NOINLINE bool sub_rn32(float lhs, float rhs, float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float value_rn = lhs_rn - rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float value = value_rn;
    if (result == nullptr || exceptions != 0 || !std::isfinite(value)) {
        return false;
    }
    *result = value;
    return true;
}

NPU_NOINLINE bool mul_rn32(float lhs, float rhs, float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float value_rn = lhs_rn * rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float value = value_rn;
    if (result == nullptr || exceptions != 0 || !std::isfinite(value)) {
        return false;
    }
    *result = value;
    return true;
}

NPU_NOINLINE bool div_rn32(float lhs, float rhs, float * result) noexcept {
    (void) std::feclearexcept(FE_ALL_EXCEPT);
    volatile float lhs_rn = lhs;
    volatile float rhs_rn = rhs;
    volatile float value_rn = lhs_rn / rhs_rn;
    const int exceptions = std::fetestexcept(kFatalFpExceptions);
    const float value = value_rn;
    if (result == nullptr || exceptions != 0 || !std::isfinite(value)) {
        return false;
    }
    *result = value;
    return true;
}

bool fp16_to_finite_float(
        std::uint16_t half_bits,
        float * value) noexcept {
    if (value == nullptr) {
        return false;
    }
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

// Bit-for-bit port of TensorNpuFp32ToFp16's finite RNE path.
bool fp32_to_fp16_rne(
        std::uint32_t bits,
        std::uint16_t * half) noexcept {
    if (half == nullptr) {
        return false;
    }
    const std::uint32_t sign = bits >> 31U;
    const std::uint32_t exponent = (bits >> 23U) & 0xffU;
    const std::uint32_t fraction = bits & 0x007fffffU;
    if (exponent == 0xffU) {
        return false;
    }
    if (exponent == 0U) {
        *half = static_cast<std::uint16_t>(sign << 15U);
        return true;
    }

    int half_exponent = static_cast<int>(exponent) - 127 + 15;
    const std::uint32_t significand = 0x00800000U | fraction;
    if (half_exponent >= 31) {
        return false;
    }
    if (half_exponent <= 0) {
        if (half_exponent < -10) {
            *half = static_cast<std::uint16_t>(sign << 15U);
            return true;
        }
        const unsigned shift = static_cast<unsigned>(14 - half_exponent);
        std::uint32_t retained = (significand >> shift) & 0x7ffU;
        const bool guard = ((significand >> (shift - 1U)) & 1U) != 0U;
        const std::uint32_t low_mask = shift <= 1U ? 0U :
            ((std::uint32_t{1} << (shift - 1U)) - 1U);
        const bool sticky = (significand & low_mask) != 0U;
        if (guard && (sticky || (retained & 1U) != 0U)) {
            ++retained;
        }
        if ((retained & 0x400U) != 0U) {
            *half = static_cast<std::uint16_t>((sign << 15U) | 0x0400U);
        } else {
            *half = static_cast<std::uint16_t>(
                (sign << 15U) | (retained & 0x03ffU));
        }
        return true;
    }

    std::uint32_t retained = significand >> 13U;
    const bool guard = ((significand >> 12U) & 1U) != 0U;
    const bool sticky = (significand & 0x0fffU) != 0U;
    if (guard && (sticky || (retained & 1U) != 0U)) {
        ++retained;
    }
    if ((retained & 0x0800U) != 0U) {
        ++half_exponent;
        if (half_exponent >= 31) {
            return false;
        }
        retained = 0x0400U;
    }
    *half = static_cast<std::uint16_t>(
        (sign << 15U) |
        (static_cast<std::uint32_t>(half_exponent) << 10U) |
        (retained & 0x03ffU));
    return true;
}

// Deterministic IEEE binary32 -> signed integer RMM (ties to maximum
// magnitude).  Quantizer callers additionally require the public Q8 range.
bool fp32_to_q8_rmm(std::uint32_t bits, std::int8_t * value) noexcept {
    if (value == nullptr || !finite_fp32_bits(bits)) {
        return false;
    }
    const bool negative = (bits >> 31U) != 0U;
    const std::uint32_t exponent = (bits >> 23U) & 0xffU;
    const std::uint32_t fraction = bits & 0x007fffffU;
    if (exponent == 0U) {
        *value = 0;
        return true;
    }
    const int unbiased = static_cast<int>(exponent) - 127;
    const std::uint32_t significand = 0x00800000U | fraction;
    std::uint64_t magnitude = 0;
    if (unbiased < -1) {
        magnitude = 0;
    } else if (unbiased == -1) {
        magnitude = 1;
    } else if (unbiased >= 23) {
        if (unbiased >= 63) {
            return false;
        }
        magnitude = static_cast<std::uint64_t>(significand)
                    << static_cast<unsigned>(unbiased - 23);
    } else {
        const unsigned shift = static_cast<unsigned>(23 - unbiased);
        magnitude = significand >> shift;
        const std::uint32_t remainder_mask =
            (std::uint32_t{1} << shift) - 1U;
        const std::uint32_t remainder = significand & remainder_mask;
        const std::uint32_t half = std::uint32_t{1} << (shift - 1U);
        if (remainder >= half) {
            ++magnitude;
        }
    }
    if (magnitude > 127U) {
        return false;
    }
    const std::int32_t signed_value = negative ?
        -static_cast<std::int32_t>(magnitude) :
         static_cast<std::int32_t>(magnitude);
    *value = static_cast<std::int8_t>(signed_value);
    return true;
}

class execution final {
public:
    execution(
            const npu_functional_command & command,
            npu_functional_command_result * result) noexcept
        : command_(command), result_(result) {}

    bool read(
            std::uint64_t address,
            void * destination,
            std::size_t bytes) noexcept {
        if (destination == nullptr || bytes == 0U ||
            g_functional_capabilities == nullptr ||
            !g_functional_capabilities->checked_read(
                address, destination, bytes)) {
            ++result_->callback_errors;
            fail(kErrorMacroIova, kErrorClassIova);
            return false;
        }
        ++result_->callback_read_calls;
        result_->callback_read_bytes += bytes;
        return true;
    }

    bool write(
            std::uint64_t address,
            const void * source,
            std::size_t bytes) noexcept {
        if (source == nullptr || bytes == 0U ||
            g_functional_capabilities == nullptr ||
            !g_functional_capabilities->checked_write(
                address, source, bytes)) {
            ++result_->callback_errors;
            fail(kErrorMacroIova, kErrorClassIova);
            return false;
        }
        ++result_->callback_write_calls;
        result_->callback_write_bytes += bytes;
        return true;
    }

    bool read_u32(std::uint64_t address, std::uint32_t * value) noexcept {
        return read(address, value, sizeof(*value));
    }

    bool read_u64(std::uint64_t address, std::uint64_t * value) noexcept {
        return read(address, value, sizeof(*value));
    }

    void fail(std::uint32_t code, std::uint32_t error_class) noexcept {
        result_->success = false;
        if (result_->error_code == 0U) {
            result_->error_code = code;
            result_->error_class = error_class;
        }
    }

    bool layout(bool condition) noexcept {
        if (!condition) {
            fail(kErrorMacroLayout, kErrorClassLayout);
        }
        return condition;
    }

    bool numeric(bool condition) noexcept {
        if (!condition) {
            fail(kErrorMacroProtocol, kErrorClassProtocol);
        }
        return condition;
    }

    bool publish_ledger(
            std::uint64_t read_words,
            std::uint64_t write_words,
            std::uint64_t q8_blocks,
            std::uint64_t q8_macs,
            std::uint64_t vector_elements) noexcept {
        std::uint64_t word_read_bytes = 0;
        std::uint64_t block_read_bytes = 0;
        std::uint64_t read_bytes = 0;
        std::uint64_t write_bytes = 0;
        if (!checked_mul(read_words, 4U, &word_read_bytes) ||
            !checked_mul(q8_blocks, kQ8BlockBytes, &block_read_bytes) ||
            !checked_add(word_read_bytes, block_read_bytes, &read_bytes) ||
            !checked_mul(write_words, 4U, &write_bytes)) {
            fail(kErrorMacroProtocol, kErrorClassProtocol);
            return false;
        }
        result_->read_words = read_words;
        result_->write_words = write_words;
        result_->read_bytes = read_bytes;
        result_->write_bytes = write_bytes;
        result_->q8_blocks = q8_blocks;
        result_->q8_mac_count = q8_macs;
        result_->vector_elements = vector_elements;
        return true;
    }

    const npu_functional_command & command() const noexcept {
        return command_;
    }

private:
    const npu_functional_command & command_;
    npu_functional_command_result * result_;
};

bool address_at(
        std::uint64_t base,
        std::uint64_t index,
        std::uint64_t stride,
        std::uint64_t * address) noexcept {
    std::uint64_t offset = 0;
    return checked_mul(index, stride, &offset) &&
           checked_add(base, offset, address);
}

bool common_command_valid(const npu_functional_command & command) noexcept {
    return command.abi_valid && command.windows_generation_valid &&
           (command.command_flags == 0x00000010U ||
            command.command_flags == 0x00000011U) &&
           command.capability_epoch == kCapabilityEpoch &&
           command.node_count != 0U && command.dtype == kDtypeF32 &&
           command.scratch_iova == 0U && command.scratch_bytes == 0U &&
           command.rope_position == 0U &&
           command.src0_window_perm == 1U &&
           command.dst_window_perm == 2U &&
           command.src0_iova != 0U && command.dst_iova != 0U;
}

struct f32_descriptor {
    std::array<std::uint32_t, 4> ne;
    std::array<std::uint64_t, 4> nb;
};

struct f32_profile {
    std::uint32_t op;
    std::uint32_t scalar;
    bool src1_present;
    f32_descriptor dst;
    f32_descriptor src0;
    f32_descriptor src1;
};

constexpr f32_descriptor f32_desc(
        std::array<std::uint32_t, 4> ne,
        std::array<std::uint64_t, 4> nb) {
    return {ne, nb};
}

constexpr auto kT16 = f32_desc({16,1,1,1},{4,64,64,64});
constexpr auto kT1024 = f32_desc({1024,1,1,1},{4,4096,4096,4096});
constexpr auto kT128x128x16 =
    f32_desc({128,128,16,1},{4,512,65536,1048576});
constexpr auto kT128x1x16 =
    f32_desc({128,1,16,1},{4,512,512,8192});
constexpr auto kT128x16 =
    f32_desc({128,16,1,1},{4,512,8192,8192});

constexpr std::array<f32_profile, 19> kF32Profiles = {{
    {1,0,true,kT16,f32_desc({16,1,1,1},{4,64,64,64}),kT16},
    {1,0,true,kT1024,kT1024,kT1024},
    {1,0,true,kT1024,kT1024,kT1024},
    {1,0,true,kT128x128x16,kT128x128x16,kT128x128x16},
    {2,0,true,kT16,kT16,kT16},
    {2,0,true,kT1024,kT1024,kT1024},
    {2,0,true,kT128x128x16,kT128x128x16,
        f32_desc({128,1,16,1},{4,8192,512,8192})},
    {2,0,true,kT128x1x16,kT128x1x16,
        f32_desc({1,1,16,1},{4,4,4,64})},
    {2,0,true,kT128x128x16,kT128x128x16,
        f32_desc({1,128,16,1},{512,4,512,8192})},
    {2,0,true,kT128x128x16,kT128x128x16,
        f32_desc({1,1,16,1},{4,4,4,64})},
    {2,0,true,kT128x16,kT128x16,
        f32_desc({128,1,1,1},{4,512,512,512})},
    {2,0,true,kT128x16,kT128x16,kT128x16},
    {2,0,true,f32_desc({2048,1,1,1},{4,8192,8192,8192}),
        f32_desc({2048,1,1,1},{4,8192,8192,8192}),
        f32_desc({2048,1,1,1},{4,8192,8192,8192})},
    {2,0,true,f32_desc({256,2,1,1},{4,1024,2048,2048}),
        f32_desc({256,2,1,1},{4,1024,2048,2048}),
        f32_desc({256,1,1,1},{4,1024,1024,1024})},
    {2,0,true,f32_desc({256,8,1,1},{4,1024,8192,8192}),
        f32_desc({256,8,1,1},{4,1024,8192,8192}),
        f32_desc({256,1,1,1},{4,1024,1024,1024})},
    {3,0,true,kT128x1x16,
        f32_desc({128,1,16,1},{4,24576,512,24576}),
        f32_desc({128,1,16,1},{4,4,512,8192})},
    {4,0x3db504f3U,false,kT128x16,kT128x16,{}},
    {4,0,false,f32_desc({18432,1,1,1},{4,73728,73728,73728}),
        f32_desc({18432,1,1,1},{4,73728,73728,73728}),{}},
    {4,0,false,f32_desc({262144,1,1,1},{4,1048576,1048576,1048576}),
        f32_desc({262144,1,1,1},{4,1048576,1048576,1048576}),{}},
}};

bool descriptor_elements(
        const f32_descriptor & descriptor,
        std::uint64_t * elements) noexcept {
    std::uint64_t value = 1U;
    for (std::uint32_t dimension : descriptor.ne) {
        if (dimension == 0U || !checked_mul(value, dimension, &value)) {
            return false;
        }
    }
    *elements = value;
    return true;
}

bool f32_source_address(
        std::uint64_t base,
        const f32_descriptor & source,
        const std::array<std::uint64_t, 4> & coordinate,
        std::uint64_t * address) noexcept {
    std::uint64_t value = base;
    for (std::size_t dimension = 0; dimension < 4U; ++dimension) {
        if (source.ne[dimension] == 0U) {
            return false;
        }
        std::uint64_t term = 0;
        if (!checked_mul(
                coordinate[dimension] % source.ne[dimension],
                source.nb[dimension], &term) ||
            !checked_add(value, term, &value)) {
            return false;
        }
    }
    *address = value;
    return true;
}

bool execute_vector_f32(execution * run) {
    const npu_functional_command & command = run->command();
    if (!run->layout(
            command.vector_flags < kF32Profiles.size() &&
            command.vector_op >= 1U && command.vector_op <= 4U)) {
        return false;
    }
    const f32_profile & profile = kF32Profiles[command.vector_flags];
    std::uint64_t total = 0;
    std::uint64_t outer = 1;
    for (std::size_t dimension = 1; dimension < 4U; ++dimension) {
        if (!checked_mul(outer, profile.dst.ne[dimension], &outer)) {
            return run->layout(false);
        }
    }
    if (!descriptor_elements(profile.dst, &total) ||
        !run->layout(
            command.vector_op == profile.op &&
            command.scalar0 == profile.scalar &&
            command.element_count == profile.dst.ne[0] &&
            command.outer_count == outer &&
            command.src0_stride == profile.src0.nb[1] &&
            command.dst_stride == profile.dst.nb[1] &&
            command.src1_window_perm ==
                (profile.src1_present ? 1U : 0U) &&
            command.src1_stride ==
                (profile.src1_present ? profile.src1.nb[1] : 0U) &&
            (profile.src1_present ? command.src1_iova != 0U :
                (command.src1_iova == 0U &&
                 command.src1_window_base == 0U &&
                 command.src1_window_size == 0U)))) {
        return false;
    }
    if (command.vector_op == 4U &&
        !run->numeric(finite_fp32_bits(command.scalar0))) {
        return false;
    }

    std::size_t output_count = 0;
    if (!checked_size(total, &output_count)) {
        return run->layout(false);
    }
    std::vector<std::uint32_t> output(output_count, 0U);
    std::array<std::uint64_t, 4> coordinate = {};
    for (std::uint64_t flat = 0; flat < total; ++flat) {
        std::uint64_t quotient = flat;
        for (std::size_t dimension = 0; dimension < 4U; ++dimension) {
            coordinate[dimension] = quotient % profile.dst.ne[dimension];
            quotient /= profile.dst.ne[dimension];
        }
        std::uint64_t src0_address = 0;
        std::uint64_t src1_address = 0;
        std::uint32_t src0_bits = 0;
        std::uint32_t src1_bits = command.scalar0;
        if (!f32_source_address(
                command.src0_iova, profile.src0, coordinate,
                &src0_address) ||
            !run->read_u32(src0_address, &src0_bits) ||
            !run->numeric(finite_fp32_bits(src0_bits))) {
            return false;
        }
        if (profile.src1_present &&
            (!f32_source_address(
                 command.src1_iova, profile.src1, coordinate,
                 &src1_address) ||
             !run->read_u32(src1_address, &src1_bits) ||
             !run->numeric(finite_fp32_bits(src1_bits)))) {
            return false;
        }
        const float src0 = float_from_raw_bits(src0_bits);
        const float src1 = float_from_raw_bits(src1_bits);
        float value = 0.0F;
        const bool numeric_ok =
            command.vector_op == 1U ? add_rn32(src0, src1, &value) :
            command.vector_op == 2U ? mul_rn32(src0, src1, &value) :
            command.vector_op == 3U ? sub_rn32(src0, src1, &value) :
                                      mul_rn32(src0, src1, &value);
        if (!run->numeric(numeric_ok)) {
            return false;
        }
        output[static_cast<std::size_t>(flat)] = raw_float_bits(value);
    }

    std::uint64_t output_bytes_u64 = 0;
    std::size_t output_bytes = 0;
    if (!checked_mul(total, 4U, &output_bytes_u64) ||
        !checked_size(output_bytes_u64, &output_bytes) ||
        (output_bytes != 0U &&
         !run->write(command.dst_iova, output.data(), output_bytes))) {
        return false;
    }
    const std::uint64_t read_words = total *
        (profile.src1_present ? 2U : 1U);
    return run->publish_ledger(
        read_words, total, 0U, 0U, total);
}

using raw_q8_block = std::array<std::uint8_t, kQ8BlockBytes>;

int signed_q8(std::uint8_t raw) noexcept {
    return raw < 128U ? static_cast<int>(raw) :
                        static_cast<int>(raw) - 256;
}

bool quantize_activation_block(
        const std::uint32_t * words,
        raw_q8_block * block) noexcept {
    if (words == nullptr || block == nullptr) {
        return false;
    }
    std::uint32_t amax_bits = 0U;
    for (std::size_t index = 0; index < kQ8BlockElements; ++index) {
        if (!finite_fp32_bits(words[index])) {
            return false;
        }
        const std::uint32_t magnitude = words[index] & 0x7fffffffU;
        if (magnitude > amax_bits) {
            amax_bits = magnitude;
        }
    }

    float scale = 0.0F;
    if (!div_rn32(
            float_from_raw_bits(amax_bits),
            float_from_raw_bits(0x42fe0000U), &scale)) {
        return false;
    }
    const std::uint32_t scale_bits = raw_float_bits(scale);
    std::uint16_t stored_scale = 0U;
    if (!fp32_to_fp16_rne(scale_bits, &stored_scale)) {
        return false;
    }
    (*block)[0] = static_cast<std::uint8_t>(stored_scale);
    (*block)[1] = static_cast<std::uint8_t>(stored_scale >> 8U);

    float inverse = 0.0F;
    if ((scale_bits & 0x7fffffffU) != 0U &&
        !div_rn32(float_from_raw_bits(0x3f800000U), scale, &inverse)) {
        return false;
    }
    for (std::size_t index = 0; index < kQ8BlockElements; ++index) {
        float scaled = 0.0F;
        std::int8_t quantized = 0;
        if (!mul_rn32(float_from_raw_bits(words[index]), inverse, &scaled) ||
            !fp32_to_q8_rmm(raw_float_bits(scaled), &quantized)) {
            return false;
        }
        (*block)[2U + index] = static_cast<std::uint8_t>(quantized);
    }
    return true;
}

bool execute_q8_gemv(execution * run) {
    const npu_functional_command & command = run->command();
    if (!run->layout(
            command.vector_op == 0U && command.vector_flags == 0U &&
            command.element_count != 0U &&
            (command.element_count % kQ8BlockElements) == 0U &&
            command.outer_count != 0U && command.src1_iova != 0U &&
            command.src1_window_perm == 1U &&
            command.src0_stride == 0U && command.src2_stride == 0U &&
            command.src1_stride ==
                (command.element_count / kQ8BlockElements) * kQ8BlockBytes &&
            command.dst_stride == 4U)) {
        return false;
    }
    const std::uint64_t block_count =
        command.element_count / kQ8BlockElements;
    std::uint64_t activation_bytes_u64 = 0;
    std::size_t activation_words = 0;
    std::size_t activation_bytes = 0;
    if (!checked_mul(command.element_count, 4U, &activation_bytes_u64) ||
        !checked_size(command.element_count, &activation_words) ||
        !checked_size(activation_bytes_u64, &activation_bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint32_t> activation(activation_words, 0U);
    if (!run->read(
            command.src0_iova, activation.data(), activation_bytes)) {
        return false;
    }
    std::size_t block_count_size = 0;
    if (!checked_size(block_count, &block_count_size)) {
        return run->layout(false);
    }
    std::vector<raw_q8_block> quantized(block_count_size);
    for (std::size_t block = 0; block < block_count_size; ++block) {
        if (!run->numeric(quantize_activation_block(
                activation.data() + block * kQ8BlockElements,
                &quantized[block]))) {
            return false;
        }
    }

    std::size_t output_count = command.outer_count;
    std::vector<std::uint32_t> output(output_count, 0U);
    std::uint64_t row_bytes_u64 = 0;
    std::size_t row_bytes = 0;
    if (!checked_mul(block_count, kQ8BlockBytes, &row_bytes_u64) ||
        !checked_size(row_bytes_u64, &row_bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint8_t> weight_row(row_bytes, 0U);
    for (std::uint64_t row = 0; row < command.outer_count; ++row) {
        std::uint64_t weight_address = 0;
        if (!address_at(
                command.src1_iova, row, command.src1_stride,
                &weight_address) ||
            !run->read(weight_address, weight_row.data(), row_bytes)) {
            return false;
        }
        float accumulator = float_from_raw_bits(0x00000000U);
        for (std::size_t block = 0; block < block_count_size; ++block) {
            const std::uint8_t * weight =
                weight_row.data() + block * kQ8BlockBytes;
            const raw_q8_block & activation_block = quantized[block];
            const std::uint16_t activation_scale_bits =
                static_cast<std::uint16_t>(activation_block[0]) |
                (static_cast<std::uint16_t>(activation_block[1]) << 8U);
            const std::uint16_t weight_scale_bits =
                static_cast<std::uint16_t>(weight[0]) |
                (static_cast<std::uint16_t>(weight[1]) << 8U);
            float activation_scale = 0.0F;
            float weight_scale = 0.0F;
            if (!run->numeric(
                    fp16_to_finite_float(
                        activation_scale_bits, &activation_scale) &&
                    fp16_to_finite_float(
                        weight_scale_bits, &weight_scale))) {
                return false;
            }
            std::int32_t dot = 0;
            for (std::size_t element = 0;
                 element < kQ8BlockElements; ++element) {
                dot += signed_q8(activation_block[2U + element]) *
                       signed_q8(weight[2U + element]);
            }
            volatile float dot_rn = static_cast<float>(dot);
            float scale = 0.0F;
            float term = 0.0F;
            float next = 0.0F;
            if (!run->numeric(
                    mul_rn32(weight_scale, activation_scale, &scale) &&
                    mul_rn32(dot_rn, scale, &term) &&
                    add_rn32(accumulator, term, &next))) {
                return false;
            }
            accumulator = next;
        }
        output[static_cast<std::size_t>(row)] =
            raw_float_bits(accumulator);
    }

    std::uint64_t output_bytes_u64 = 0;
    std::size_t output_bytes = 0;
    std::uint64_t weight_blocks = 0;
    std::uint64_t q8_macs = 0;
    if (!checked_mul(command.outer_count, 4U, &output_bytes_u64) ||
        !checked_size(output_bytes_u64, &output_bytes) ||
        !checked_mul(command.outer_count, block_count, &weight_blocks) ||
        !checked_mul(command.outer_count, command.element_count, &q8_macs) ||
        !run->write(command.dst_iova, output.data(), output_bytes)) {
        return false;
    }
    return run->publish_ledger(
        command.element_count, command.outer_count, weight_blocks,
        q8_macs, command.outer_count);
}

bool execute_q8_get_rows(execution * run) {
    const npu_functional_command & command = run->command();
    if (!run->layout(
            command.vector_op == 0U && command.vector_flags == 0U &&
            command.element_count != 0U &&
            (command.element_count % kQ8BlockElements) == 0U &&
            command.outer_count != 0U && command.scalar0 != 0U &&
            command.src1_iova != 0U && command.src1_window_perm == 1U &&
            command.src0_stride ==
                (command.element_count / kQ8BlockElements) * kQ8BlockBytes &&
            command.src1_stride == 4U &&
            command.dst_stride == command.element_count * 4U)) {
        return false;
    }
    const std::uint64_t block_count =
        command.element_count / kQ8BlockElements;
    std::uint64_t total_elements = 0;
    std::uint64_t output_bytes_u64 = 0;
    std::size_t output_elements = 0;
    std::size_t output_bytes = 0;
    if (!checked_mul(
            command.element_count, command.outer_count, &total_elements) ||
        !checked_mul(total_elements, 4U, &output_bytes_u64) ||
        !checked_size(total_elements, &output_elements) ||
        !checked_size(output_bytes_u64, &output_bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint32_t> indices(command.outer_count, 0U);
    for (std::uint64_t index = 0; index < command.outer_count; ++index) {
        std::uint64_t address = 0;
        if (!address_at(
                command.src1_iova, index, command.src1_stride, &address) ||
            !run->read_u32(
                address, &indices[static_cast<std::size_t>(index)])) {
            return false;
        }
        const std::int32_t signed_index = static_cast<std::int32_t>(
            indices[static_cast<std::size_t>(index)]);
        if (signed_index < 0 ||
            static_cast<std::uint32_t>(signed_index) >= command.scalar0) {
            run->fail(kErrorMacroIova, kErrorClassIova);
            return run->publish_ledger(
                command.outer_count, 0U, 0U, 0U, 0U) && false;
        }
    }

    std::vector<std::uint32_t> output(output_elements, 0U);
    raw_q8_block block = {};
    for (std::uint64_t row = 0; row < command.outer_count; ++row) {
        const std::uint64_t table_row = indices[static_cast<std::size_t>(row)];
        std::uint64_t row_address = 0;
        if (!address_at(
                command.src0_iova, table_row, command.src0_stride,
                &row_address)) {
            return run->layout(false);
        }
        for (std::uint64_t block_index = 0;
             block_index < block_count; ++block_index) {
            std::uint64_t block_offset = 0;
            std::uint64_t block_address = 0;
            if (!checked_mul(
                    block_index, kQ8BlockBytes, &block_offset) ||
                !checked_add(row_address, block_offset, &block_address) ||
                !run->read(block_address, block.data(), block.size())) {
                return false;
            }
            const std::uint16_t scale_bits =
                static_cast<std::uint16_t>(block[0]) |
                (static_cast<std::uint16_t>(block[1]) << 8U);
            float scale = 0.0F;
            if (!run->numeric(fp16_to_finite_float(scale_bits, &scale))) {
                return false;
            }
            for (std::size_t element = 0;
                 element < kQ8BlockElements; ++element) {
                volatile float q_rn = static_cast<float>(
                    signed_q8(block[2U + element]));
                float value = 0.0F;
                if (!run->numeric(mul_rn32(q_rn, scale, &value))) {
                    return false;
                }
                const std::uint64_t flat =
                    row * command.element_count +
                    block_index * kQ8BlockElements + element;
                output[static_cast<std::size_t>(flat)] =
                    raw_float_bits(value);
            }
        }
    }
    if (!run->write(command.dst_iova, output.data(), output_bytes)) {
        return false;
    }
    std::uint64_t q8_blocks = 0;
    if (!checked_mul(command.outer_count, block_count, &q8_blocks)) {
        return run->layout(false);
    }
    return run->publish_ledger(
        command.outer_count, total_elements, q8_blocks, 0U,
        total_elements);
}

bool execute_f32_get_rows(execution * run) {
    const npu_functional_command & command = run->command();
    if (command.outer_count == 0U) {
        std::uint64_t row_bytes = 0U;
        const bool empty_profile =
            (command.element_count == 18432U ||
             command.element_count == 262144U) &&
            checked_mul(command.element_count, 4U, &row_bytes) &&
            command.vector_op == 0U && command.vector_flags == 0U &&
            command.scalar0 == 0U && command.src1_iova != 0U &&
            command.src0_stride == row_bytes &&
            command.src1_stride == 4U &&
            command.src2_stride == 0U &&
            command.dst_stride == row_bytes &&
            command.src0_window_size == 0U &&
            command.src1_window_size == 0U &&
            command.dst_window_size == 0U &&
            command.src1_window_perm == 1U;
        if (!run->layout(empty_profile)) {
            return false;
        }
        // Canonical F32 GET_ROWS profiles 1 and 3 are real REQUIRED no-ops:
        // their tensors have zero backing/output spans and therefore perform
        // no capability callback while still completing exactly once.
        return run->publish_ledger(0U, 0U, 0U, 0U, 0U);
    }
    if (!run->layout(
            command.vector_op == 0U && command.vector_flags == 0U &&
            command.element_count != 0U && command.outer_count != 0U &&
            command.scalar0 != 0U && command.src1_iova != 0U &&
            command.src1_window_perm == 1U && command.src1_stride == 4U &&
            command.src0_stride >= command.element_count * 4U &&
            command.dst_stride >= command.element_count * 4U)) {
        return false;
    }
    std::vector<std::uint32_t> indices(command.outer_count, 0U);
    for (std::uint64_t index = 0; index < command.outer_count; ++index) {
        std::uint64_t address = 0;
        if (!address_at(command.src1_iova, index, 4U, &address) ||
            !run->read_u32(
                address, &indices[static_cast<std::size_t>(index)])) {
            return false;
        }
        const std::int32_t signed_index = static_cast<std::int32_t>(
            indices[static_cast<std::size_t>(index)]);
        if (signed_index < 0 ||
            static_cast<std::uint32_t>(signed_index) >= command.scalar0) {
            run->fail(kErrorMacroIova, kErrorClassIova);
            return run->publish_ledger(
                command.outer_count, 0U, 0U, 0U, 0U) && false;
        }
    }

    std::uint64_t total_elements = 0;
    std::uint64_t row_bytes_u64 = 0;
    std::size_t row_bytes = 0;
    if (!checked_mul(
            command.element_count, command.outer_count, &total_elements) ||
        !checked_mul(command.element_count, 4U, &row_bytes_u64) ||
        !checked_size(row_bytes_u64, &row_bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint8_t> output(
        static_cast<std::size_t>(total_elements * 4U), 0U);
    for (std::uint64_t row = 0; row < command.outer_count; ++row) {
        std::uint64_t source_address = 0;
        if (!address_at(
                command.src0_iova,
                indices[static_cast<std::size_t>(row)],
                command.src0_stride, &source_address) ||
            !run->read(
                source_address,
                output.data() + static_cast<std::size_t>(row) * row_bytes,
                row_bytes)) {
            return false;
        }
    }
    for (std::uint64_t row = 0; row < command.outer_count; ++row) {
        std::uint64_t destination_address = 0;
        if (!address_at(
                command.dst_iova, row, command.dst_stride,
                &destination_address) ||
            !run->write(
                destination_address,
                output.data() + static_cast<std::size_t>(row) * row_bytes,
                row_bytes)) {
            return false;
        }
    }
    return run->publish_ledger(
        command.outer_count + total_elements, total_elements,
        0U, 0U, total_elements);
}

bool execute_f32_repeat(execution * run) {
    const npu_functional_command & command = run->command();
    if (!run->layout(
            command.vector_op == 0U && command.vector_flags == 0U &&
            command.element_count != 0U && command.outer_count != 0U &&
            command.scalar0 != 0U && command.src1_iova == 0U &&
            command.src1_window_base == 0U &&
            command.src1_window_size == 0U &&
            command.src0_stride >= command.element_count * 4U &&
            command.dst_stride >= command.element_count * 4U &&
            command.src2_stride >= command.dst_stride * command.scalar0)) {
        return false;
    }
    std::uint64_t source_elements = 0;
    std::uint64_t output_elements = 0;
    std::uint64_t row_bytes_u64 = 0;
    std::size_t row_bytes = 0;
    if (!checked_mul(
            command.element_count, command.outer_count, &source_elements) ||
        !checked_mul(source_elements, command.scalar0, &output_elements) ||
        !checked_mul(command.element_count, 4U, &row_bytes_u64) ||
        !checked_size(row_bytes_u64, &row_bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint8_t> row_data(row_bytes, 0U);
    for (std::uint64_t outer = 0; outer < command.outer_count; ++outer) {
        std::uint64_t source_address = 0;
        if (!address_at(
                command.src0_iova, outer, command.src0_stride,
                &source_address) ||
            !run->read(source_address, row_data.data(), row_data.size())) {
            return false;
        }
        std::uint64_t outer_offset = 0;
        if (!checked_mul(outer, command.src2_stride, &outer_offset)) {
            return run->layout(false);
        }
        for (std::uint64_t repeat = 0; repeat < command.scalar0; ++repeat) {
            std::uint64_t repeat_offset = 0;
            std::uint64_t destination_address = 0;
            if (!checked_mul(repeat, command.dst_stride, &repeat_offset) ||
                !checked_add(command.dst_iova, outer_offset,
                             &destination_address) ||
                !checked_add(destination_address, repeat_offset,
                             &destination_address) ||
                !run->write(
                    destination_address, row_data.data(), row_data.size())) {
                return false;
            }
        }
    }
    return run->publish_ledger(
        source_elements, output_elements, 0U, 0U, output_elements);
}

bool copy_word_to_output(
        execution * run,
        std::uint64_t source_address,
        std::vector<std::uint8_t> * output,
        std::uint64_t output_word) {
    std::uint64_t output_offset_u64 = 0;
    std::size_t output_offset = 0;
    std::uint32_t value = 0;
    if (output == nullptr ||
        !checked_mul(output_word, 4U, &output_offset_u64) ||
        !checked_size(output_offset_u64, &output_offset) ||
        output_offset > output->size() ||
        4U > output->size() - output_offset ||
        !run->read_u32(source_address, &value)) {
        return false;
    }
    std::memcpy(output->data() + output_offset, &value, sizeof(value));
    return true;
}

bool execute_generic_mover(execution * run) {
    const npu_functional_command & command = run->command();
    const std::uint32_t profile = command.vector_flags;
    const bool route_ok =
        (profile == 0U && command.vector_op == 22U) ||
        ((profile == 1U || profile == 2U) && command.vector_op == 35U) ||
        (profile >= 3U && profile <= 6U && command.vector_op == 34U);
    if (!run->layout(
            route_ok && command.src1_window_perm == 1U &&
            command.src2_iova == 0U && command.src2_stride == 0U &&
            command.scalar0 == 0U && command.scalar1 == 0U)) {
        return false;
    }

    std::uint64_t elements = 0;
    std::uint64_t bytes_u64 = 0;
    std::uint64_t expected_element_count = 0;
    std::uint32_t expected_outer_count = 0;
    std::uint64_t expected_src0_stride = 0;
    std::uint64_t expected_src1_stride = 0;
    std::uint64_t expected_dst_stride = 0;
    switch (profile) {
        case 0U:
            elements = 24576U;
            bytes_u64 = 98304U;
            expected_element_count = 4U;
            expected_outer_count = 6144U;
            expected_src0_stride = 12U;
            expected_src1_stride = 4U;
            expected_dst_stride = 16U;
            break;
        case 1U:
            elements = 2048U;
            bytes_u64 = 8192U;
            expected_element_count = 2048U;
            expected_outer_count = 1U;
            expected_src0_stride = 1024U;
            expected_dst_stride = 8192U;
            break;
        case 2U:
            elements = 2048U;
            bytes_u64 = 8192U;
            expected_element_count = 2048U;
            expected_outer_count = 1U;
            expected_src0_stride = 2048U;
            expected_dst_stride = 8192U;
            break;
        case 3U:
            expected_element_count = 18432U;
            expected_src0_stride = 73728U;
            expected_src1_stride = 73728U;
            expected_dst_stride = 73728U;
            break;
        case 4U:
            elements = 18432U;
            bytes_u64 = 73728U;
            expected_element_count = 18432U;
            expected_outer_count = 1U;
            expected_src0_stride = 16U;
            expected_src1_stride = 73728U;
            expected_dst_stride = 73728U;
            break;
        case 5U:
            expected_element_count = 262144U;
            expected_src0_stride = 1048576U;
            expected_src1_stride = 1048576U;
            expected_dst_stride = 1048576U;
            break;
        case 6U:
            elements = 262144U;
            bytes_u64 = 1048576U;
            expected_element_count = 262144U;
            expected_outer_count = 1U;
            expected_src0_stride = 512U;
            expected_src1_stride = 1048576U;
            expected_dst_stride = 1048576U;
            break;
        default:
            return run->layout(false);
    }
    if (!run->layout(
            command.element_count == expected_element_count &&
            command.outer_count == expected_outer_count &&
            command.src0_stride == expected_src0_stride &&
            command.src1_stride == expected_src1_stride &&
            command.dst_stride == expected_dst_stride &&
            ((profile == 1U || profile == 2U) ?
                command.src1_iova == 0U : command.src1_iova != 0U))) {
        return false;
    }
    if (elements == 0U) {
        return run->publish_ledger(0U, 0U, 0U, 0U, 0U);
    }

    std::size_t bytes = 0;
    if (!checked_size(bytes_u64, &bytes)) {
        return run->layout(false);
    }
    std::vector<std::uint8_t> output(bytes, 0U);
    if (profile == 0U) {
        // CONCAT [3,6144] + [1,6144] -> [4,6144].
        for (std::uint64_t row = 0; row < 6144U; ++row) {
            for (std::uint64_t column = 0; column < 3U; ++column) {
                std::uint64_t row_offset = 0;
                std::uint64_t column_offset = 0;
                std::uint64_t address = 0;
                if (!checked_mul(row, 12U, &row_offset) ||
                    !checked_mul(column, 4U, &column_offset) ||
                    !checked_add(command.src0_iova, row_offset, &address) ||
                    !checked_add(address, column_offset, &address) ||
                    !copy_word_to_output(
                        run, address, &output, row * 4U + column)) {
                    return false;
                }
            }
            std::uint64_t address = 0;
            if (!address_at(command.src1_iova, row, 4U, &address) ||
                !copy_word_to_output(
                    run, address, &output, row * 4U + 3U)) {
                return false;
            }
        }
    } else if (profile == 1U || profile == 2U) {
        // CONT flattens the frozen [256,8] view in i0-fast order.
        for (std::uint64_t row = 0; row < 8U; ++row) {
            for (std::uint64_t column = 0; column < 256U; ++column) {
                std::uint64_t row_offset = 0;
                std::uint64_t column_offset = 0;
                std::uint64_t address = 0;
                if (!checked_mul(
                        row, expected_src0_stride, &row_offset) ||
                    !checked_mul(column, 4U, &column_offset) ||
                    !checked_add(command.src0_iova, row_offset, &address) ||
                    !checked_add(address, column_offset, &address) ||
                    !copy_word_to_output(
                        run, address, &output, row * 256U + column)) {
                    return false;
                }
            }
        }
    } else if (profile == 4U) {
        // CPY flattens the view [3,6144] whose row pitch is 16 bytes.
        for (std::uint64_t row = 0; row < 6144U; ++row) {
            for (std::uint64_t column = 0; column < 3U; ++column) {
                std::uint64_t row_offset = 0;
                std::uint64_t column_offset = 0;
                std::uint64_t address = 0;
                if (!checked_mul(row, 16U, &row_offset) ||
                    !checked_mul(column, 4U, &column_offset) ||
                    !checked_add(command.src0_iova, row_offset, &address) ||
                    !checked_add(address, column_offset, &address) ||
                    !copy_word_to_output(
                        run, address, &output, row * 3U + column)) {
                    return false;
                }
            }
        }
    } else {
        // Frozen P6 is naturally contiguous despite its 4-D source shape.
        if (!run->read(command.src0_iova, output.data(), output.size())) {
            return false;
        }
    }
    if (!run->write(command.dst_iova, output.data(), output.size())) {
        return false;
    }
    return run->publish_ledger(
        bytes_u64 / 4U, bytes_u64 / 4U, 0U, 0U, elements);
}

bool execute_set_rows(execution * run) {
    const npu_functional_command & command = run->command();
    const bool transposed = command.vector_flags == 7U;
    const bool native = command.vector_flags == 8U;
    if (!run->layout(
            (transposed || native) && command.vector_op == 42U &&
            command.src1_iova != 0U && command.src2_iova == command.dst_iova &&
            command.src1_window_perm == 1U &&
            command.scalar0 == 256U && command.scalar1 < 256U &&
            (transposed ?
                (command.element_count == 1U &&
                 command.outer_count == 131072U &&
                 command.src0_stride == 4U &&
                 command.src1_stride == 4096U &&
                 command.src2_stride == 2U &&
                 command.dst_stride == 2U) :
                (command.element_count == 512U &&
                 command.outer_count == 256U &&
                 command.src0_stride == 2048U &&
                 command.src1_stride == 8U &&
                 command.src2_stride == 1024U &&
                 command.dst_stride == 1024U)))) {
        return false;
    }

    std::array<std::uint16_t, 512> converted = {};
    std::array<std::uint64_t, 512> indices = {};
    for (std::uint64_t element = 0; element < converted.size(); ++element) {
        std::uint64_t value_address = 0;
        std::uint32_t value_bits = 0;
        if (!address_at(command.src0_iova, element, 4U, &value_address) ||
            !run->read_u32(value_address, &value_bits) ||
            !run->numeric(
                finite_fp32_bits(value_bits) &&
                fp32_to_fp16_rne(
                    value_bits,
                    &converted[static_cast<std::size_t>(element)]))) {
            return false;
        }
    }
    const std::uint64_t index_count = transposed ? 512U : 1U;
    for (std::uint64_t position = 0; position < index_count; ++position) {
        std::uint64_t index_address = 0;
        if (!address_at(command.src1_iova, position, 8U, &index_address) ||
            !run->read_u64(
                index_address,
                &indices[static_cast<std::size_t>(position)])) {
            return false;
        }
        std::uint64_t expected = command.scalar1;
        if (transposed &&
            (!checked_mul(position, 256U, &expected) ||
             !checked_add(expected, command.scalar1, &expected))) {
            return run->layout(false);
        }
        if (!run->layout(indices[static_cast<std::size_t>(position)] ==
                         expected)) {
            return false;
        }
    }

    // All payload and numeric validation completed before the first private
    // destination write.  A later callback failure still cannot contaminate
    // caller-visible storage because the harness publishes only on SUCCESS.
    for (std::uint64_t element = 0; element < converted.size(); ++element) {
        std::uint64_t destination_element = 0;
        if (transposed) {
            destination_element = indices[static_cast<std::size_t>(element)];
        } else if (!checked_mul(
                       command.scalar1, 512U, &destination_element) ||
                   !checked_add(
                       destination_element, element,
                       &destination_element)) {
            return run->layout(false);
        }
        std::uint64_t byte_offset = 0;
        std::uint64_t destination_address = 0;
        if (!checked_mul(destination_element, 2U, &byte_offset) ||
            !checked_add(command.dst_iova, byte_offset,
                         &destination_address) ||
            !run->write(
                destination_address,
                &converted[static_cast<std::size_t>(element)],
                sizeof(std::uint16_t))) {
            return false;
        }
    }
    const std::uint64_t read_bytes = 2048U + index_count * 8U;
    return run->publish_ledger(
        read_bytes / 4U, 256U, 0U, 0U, 512U);
}

bool dispatch_command(execution * run) {
    switch (run->command().kernel_id) {
        case kKernelQ8Gemv:
            return execute_q8_gemv(run);
        case kKernelQ8GetRows:
            return execute_q8_get_rows(run);
        case kKernelVectorF32:
            return execute_vector_f32(run);
        case kKernelF32GetRows:
            return execute_f32_get_rows(run);
        case kKernelF32Repeat:
            return execute_f32_repeat(run);
        case kKernelMover:
            return execute_generic_mover(run);
        case kKernelSetRows:
            return execute_set_rows(run);
        default:
            run->fail(kErrorMacroCapability, kErrorClassCapability);
            return false;
    }
}

} // namespace

npu_functional_command_scope::npu_functional_command_scope(
        npu_functional_command_capability_context * context)
    : context_(context) {
    if (context_ != nullptr && g_functional_capabilities == nullptr) {
        g_functional_capabilities = context_;
        active_ = true;
    }
}

npu_functional_command_scope::~npu_functional_command_scope() {
    if (active_ && g_functional_capabilities == context_) {
        g_functional_capabilities = nullptr;
    }
}

bool npu_functional_command_scope::active() const {
    return active_;
}

bool npu_functional_command_execute_cpp(
        const npu_functional_command * command,
        npu_functional_command_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (command == nullptr) {
        result->error_code = kErrorMacroLayout;
        result->error_class = kErrorClassLayout;
        return false;
    }
    execution run(*command, result);
    if (g_functional_capabilities == nullptr) {
        result->callback_errors = 1U;
        run.fail(kErrorMacroIova, kErrorClassIova);
        return false;
    }
    if (!common_command_valid(*command)) {
        run.fail(kErrorMacroLayout, kErrorClassLayout);
        return false;
    }
    scoped_round_to_nearest rounding;
    if (!rounding.valid()) {
        run.fail(kErrorMacroProtocol, kErrorClassProtocol);
        return false;
    }

    try {
        const bool completed = dispatch_command(&run);
        if (!completed || result->error_code != 0U ||
            result->error_class != 0U || result->callback_errors != 0U) {
            result->success = false;
            return false;
        }
        std::uint64_t expected_nonq8_read = 0;
        std::uint64_t expected_q8_read = 0;
        std::uint64_t expected_read = 0;
        std::uint64_t expected_write = 0;
        if (!checked_mul(result->read_words, 4U,
                         &expected_nonq8_read) ||
            !checked_mul(result->q8_blocks, kQ8BlockBytes,
                         &expected_q8_read) ||
            !checked_add(expected_nonq8_read, expected_q8_read,
                         &expected_read) ||
            !checked_mul(result->write_words, 4U, &expected_write) ||
            result->read_bytes != expected_read ||
            result->write_bytes != expected_write ||
            result->callback_read_bytes != result->read_bytes ||
            result->callback_write_bytes != result->write_bytes) {
            run.fail(kErrorMacroProtocol, kErrorClassProtocol);
            return false;
        }
        result->success = true;
        return true;
    } catch (const std::bad_alloc &) {
        run.fail(kErrorMacroProtocol, kErrorClassProtocol);
        return false;
    } catch (...) {
        run.fail(kErrorMacroProtocol, kErrorClassProtocol);
        return false;
    }
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
    npu_functional_command command = {};
    command.abi_valid = abi_valid != 0;
    command.windows_generation_valid = windows_generation_valid != 0;
    command.kernel_id = kernel_id;
    command.command_flags = command_flags;
    command.vector_op = vector_op;
    command.vector_flags = vector_flags;
    command.context_id = context_id;
    command.capability_epoch = capability_epoch;
    command.node_count = node_count;
    command.sequence_id = sequence_id;
    command.producer_id = producer_id;
    command.user_tag = user_tag;
    command.node_hash_lo = node_hash_lo;
    command.node_hash_hi = node_hash_hi;
    command.deadline_cycles = deadline_cycles;
    command.src0_iova = src0_iova;
    command.src1_iova = src1_iova;
    command.src2_iova = src2_iova;
    command.dst_iova = dst_iova;
    command.scratch_iova = scratch_iova;
    command.element_count = element_count;
    command.outer_count = outer_count;
    command.dtype = dtype;
    command.src0_stride = src0_stride;
    command.src1_stride = src1_stride;
    command.src2_stride = src2_stride;
    command.dst_stride = dst_stride;
    command.scalar0 = scalar0;
    command.scalar1 = scalar1;
    command.scratch_bytes = scratch_bytes;
    command.rope_position = rope_position;
    command.src0_window_base = src0_window_base;
    command.src0_window_size = src0_window_size;
    command.src0_window_perm = src0_window_perm;
    command.src1_window_base = src1_window_base;
    command.src1_window_size = src1_window_size;
    command.src1_window_perm = src1_window_perm;
    command.dst_window_base = dst_window_base;
    command.dst_window_size = dst_window_size;
    command.dst_window_perm = dst_window_perm;

    npu_functional_command_result result = {};
    (void) npu_functional_command_execute_cpp(&command, &result);
    if (g_functional_capabilities != nullptr) {
        g_functional_capabilities->command_completed(command, result);
    }
    if (success != nullptr) {
        *success = result.success ? 1 : 0;
    }
    if (error_code != nullptr) {
        *error_code = result.error_code;
    }
    if (error_class != nullptr) {
        *error_class = result.error_class;
    }
    if (read_words != nullptr) {
        *read_words = result.read_words;
    }
    if (write_words != nullptr) {
        *write_words = result.write_words;
    }
    if (read_bytes != nullptr) {
        *read_bytes = result.read_bytes;
    }
    if (write_bytes != nullptr) {
        *write_bytes = result.write_bytes;
    }
    if (q8_blocks != nullptr) {
        *q8_blocks = result.q8_blocks;
    }
    if (q8_mac_count != nullptr) {
        *q8_mac_count = result.q8_mac_count;
    }
    if (vector_elements != nullptr) {
        *vector_elements = result.vector_elements;
    }
    if (callback_errors != nullptr) {
        *callback_errors = result.callback_errors;
    }
}
