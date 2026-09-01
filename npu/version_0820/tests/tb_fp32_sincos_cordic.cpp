#include "VTensorNpuFp32SincosCordic.h"
#include "verilated.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>

namespace {

std::uint32_t bits(float value) {
    std::uint32_t result = 0;
    static_assert(sizeof(result) == sizeof(value));
    std::memcpy(&result, &value, sizeof(result));
    return result;
}

float value(std::uint32_t raw) {
    float result = 0.0F;
    std::memcpy(&result, &raw, sizeof(result));
    return result;
}

void tick(VTensorNpuFp32SincosCordic & top) {
    top.clk_i = 0;
    top.eval();
    top.clk_i = 1;
    top.eval();
}

[[noreturn]] void fail(const char * message) {
    std::fprintf(stderr, "[NPU-FP32-SINCOS-CORDIC][FAIL] %s\n", message);
    std::exit(1);
}

struct response {
    std::uint32_t sin_bits = 0;
    std::uint32_t cos_bits = 0;
    bool error = false;
};

response transact(VTensorNpuFp32SincosCordic & top, std::uint32_t angle,
                  unsigned expected_cycles = 49) {
    if (!top.req_ready_o) {
        fail("request interface was not ready in IDLE");
    }
    top.angle_bits_i = angle;
    top.req_valid_i = 1;
    tick(top);
    top.req_valid_i = 0;

    unsigned cycles = 0;
    while (!top.rsp_valid_o && cycles < 80) {
        tick(top);
        ++cycles;
    }
    if (!top.rsp_valid_o || cycles != expected_cycles) {
        std::fprintf(stderr,
                     "angle_bits=%08x observed_response_cycles=%u valid=%u\n",
                     angle, cycles, static_cast<unsigned>(top.rsp_valid_o));
        fail("response latency changed from the fixed 49-cycle contract");
    }
    response result = {
        top.sin_bits_o,
        top.cos_bits_o,
        static_cast<bool>(top.error_o),
    };

    // A held terminal may not mutate or reopen the request interface.
    top.rsp_ready_i = 0;
    for (unsigned hold = 0; hold < 3; ++hold) {
        tick(top);
        if (!top.rsp_valid_o || top.req_ready_o ||
            top.sin_bits_o != result.sin_bits ||
            top.cos_bits_o != result.cos_bits ||
            static_cast<bool>(top.error_o) != result.error) {
            fail("held response was not stable");
        }
    }
    top.rsp_ready_i = 1;
    tick(top);
    top.rsp_ready_i = 0;
    if (top.rsp_valid_o || !top.req_ready_o) {
        fail("response consumption did not return to IDLE");
    }
    return result;
}

} // namespace

int main(int argc, char ** argv) {
    Verilated::commandArgs(argc, argv);
    VTensorNpuFp32SincosCordic top;
    top.clk_i = 0;
    top.rst_i = 1;
    top.req_valid_i = 0;
    top.angle_bits_i = 0;
    top.rsp_ready_i = 0;
    tick(top);
    tick(top);
    top.rst_i = 0;
    top.eval();

    constexpr float pi = 3.14159265358979323846F;
    const std::array<float, 15> finite_cases = {
        0.0F,
        -0.0F,
        pi / 6.0F,
        -pi / 6.0F,
        pi / 2.0F,
        -pi / 2.0F,
        pi,
        -pi,
        1.0F,
        -1.0F,
        1.0e-7F,
        100.0F,
        -12345.625F,
        131071.0F,
        262143.0F,
    };

    float max_sin_error = 0.0F;
    float max_cos_error = 0.0F;
    for (float angle : finite_cases) {
        const response got = transact(top, bits(angle));
        if (got.error) {
            fail("finite input raised error");
        }
        const float got_sin = value(got.sin_bits);
        const float got_cos = value(got.cos_bits);
        const float sin_error = std::fabs(got_sin - std::sin(angle));
        const float cos_error = std::fabs(got_cos - std::cos(angle));
        max_sin_error = std::max(max_sin_error, sin_error);
        max_cos_error = std::max(max_cos_error, cos_error);
        if (sin_error > 2.0e-6F || cos_error > 2.0e-6F) {
            std::fprintf(
                stderr,
                "angle=%a got_sin=%a ref_sin=%a got_cos=%a ref_cos=%a\n",
                static_cast<double>(angle), static_cast<double>(got_sin),
                static_cast<double>(std::sin(angle)),
                static_cast<double>(got_cos),
                static_cast<double>(std::cos(angle)));
            fail("finite numerical error exceeded 2e-6");
        }
    }

    // Exercise every frequency lane of the frozen Qwen IMROPE contract at
    // representative positions through the full n_ctx_orig bound.  theta is
    // advanced with a binary32 multiply exactly as the pinned CPU loop does.
    const std::array<std::int32_t, 10> rope_positions = {
        0, 1, 2, 31, 127, 255, 1023, 4095, 32767, 262143,
    };
    const float theta_scale = std::pow(10000000.0F, -2.0F / 64.0F);
    for (std::int32_t position : rope_positions) {
        float theta = static_cast<float>(position);
        for (unsigned lane = 0; lane < 32; ++lane) {
            const response got = transact(top, bits(theta));
            if (got.error) {
                fail("frozen ROPE theta raised error");
            }
            const float sin_error =
                std::fabs(value(got.sin_bits) - std::sin(theta));
            const float cos_error =
                std::fabs(value(got.cos_bits) - std::cos(theta));
            max_sin_error = std::max(max_sin_error, sin_error);
            max_cos_error = std::max(max_cos_error, cos_error);
            if (sin_error > 2.0e-6F || cos_error > 2.0e-6F) {
                std::fprintf(
                    stderr,
                    "position=%d lane=%u theta=%a sin_error=%g "
                    "cos_error=%g\n",
                    position, lane, static_cast<double>(theta),
                    static_cast<double>(sin_error),
                    static_cast<double>(cos_error));
                fail("frozen ROPE theta error exceeded 2e-6");
            }
            theta *= theta_scale;
        }
    }

    const response infinity = transact(
        top, bits(std::numeric_limits<float>::infinity()), 0);
    const response quiet_nan = transact(
        top, bits(std::numeric_limits<float>::quiet_NaN()), 0);
    if (!infinity.error || !quiet_nan.error ||
        infinity.sin_bits != 0x7fc00000U ||
        infinity.cos_bits != 0x7fc00000U ||
        quiet_nan.sin_bits != 0x7fc00000U ||
        quiet_nan.cos_bits != 0x7fc00000U) {
        fail("non-finite input was not rejected with canonical quiet NaNs");
    }

    std::printf(
        "[NPU-FP32-SINCOS-CORDIC][PASS] cases=%zu rope_positions=%zu "
        "rope_lanes=32 cycles=49 max_abs_sin=%g max_abs_cos=%g "
        "held_response=3 nonfinite=2\n",
        finite_cases.size() + rope_positions.size() * 32,
        rope_positions.size(), static_cast<double>(max_sin_error),
        static_cast<double>(max_cos_error));
    return 0;
}
