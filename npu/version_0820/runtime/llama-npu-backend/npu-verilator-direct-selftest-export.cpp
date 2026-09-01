#include "npu-verilator-runner.h"

#include <cstdint>

// Linked only into the explicitly non-production direct-port self-test DSO.
// The production backend has no ELF dependency on this library or on the
// direct Coprocessor model and loads these shims only for an explicit legacy
// self-test API call.
extern "C" bool npu_direct_selftest_mm2_v1(
        npu_verilator_self_test_result * result) {
    return npu_verilator_run_mm2_self_test(result);
}

extern "C" bool npu_direct_selftest_f32_add_execute_v1(
        const std::uint32_t * src0_bits,
        const std::uint32_t * src1_bits,
        std::uint32_t * dst_bits,
        npu_verilator_f32_add_result * result) {
    return npu_verilator_execute_f32_add(
        src0_bits, src1_bits, dst_bits, result);
}

extern "C" bool npu_direct_selftest_f32_add_v1(
        npu_f32_add_mode mode,
        npu_verilator_f32_add_result * result) {
    return npu_verilator_run_f32_add_self_test(mode, result);
}

extern "C" bool npu_direct_selftest_f32_alu_v1(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result) {
    return npu_verilator_run_f32_alu_self_test(
        profile_id, mode, result);
}
