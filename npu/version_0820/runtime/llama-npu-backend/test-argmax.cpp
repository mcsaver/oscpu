#include "npu-verilator-runner.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <limits>
#include <vector>

namespace {

constexpr std::uint32_t kCommandFlags = 0x00000011U;
constexpr std::uint32_t kContextId = 0x43414e01U;

npu_macro_identity make_identity(std::uint64_t ordinal) {
    npu_macro_identity identity = {};
    identity.profile_id = 0U;
    identity.command_flags = kCommandFlags;
    identity.context_id = kContextId;
    identity.sequence_id = 0x6172676d00000000ULL | ordinal;
    identity.producer_id = 0x70726f6400000000ULL | ordinal;
    identity.user_tag = 0x7461670000000000ULL | ordinal;
    identity.node_hash_lo = 0x6e6f646500000000ULL | ordinal;
    identity.node_hash_hi = 0x6861736800000000ULL | ordinal;
    return identity;
}

std::uint64_t expected_read_bytes(std::size_t elements) {
    const std::uint64_t logical_end = 4U +
        static_cast<std::uint64_t>(elements) * 4U;
    return (logical_end + 7U) & ~std::uint64_t{7};
}

// Exact test-only oracle from ggml-cpu/vec.h::ggml_vec_argmax_f32.  This is
// deliberately outside the production runner; production sees only raw bits.
std::uint32_t ggml_cpu_reference_argmax(
        const std::uint32_t * bits,
        std::size_t elements) {
    float max_value = -std::numeric_limits<float>::infinity();
    std::uint32_t index = 0U;
    for (std::size_t i = 0; i < elements; ++i) {
        float value = 0.0F;
        std::memcpy(&value, bits + i, sizeof(value));
        max_value = max_value > value ? max_value : value;
        if (max_value == value) {
            index = static_cast<std::uint32_t>(i);
        }
    }
    return index;
}

bool portals_quiescent(const npu_verilator_f32_argmax_result & result) {
    return result.q8_portal.transactions == 0U &&
           result.q8_portal.request_groups == 0U &&
           result.q8_portal.response_groups == 0U &&
           result.f32_alu_portal.transactions == 0U &&
           result.f32_alu_portal.request_groups == 0U &&
           result.f32_alu_portal.response_groups == 0U &&
           result.f32_mover_portal.transactions == 0U &&
           result.f32_mover_portal.request_groups == 0U &&
           result.f32_mover_portal.response_groups == 0U &&
           !result.functional_command.enabled &&
           result.functional_command.dispatches == 0U &&
           result.functional_command.completions == 0U;
}

bool run_positive_case(
        const char * name,
        const std::uint32_t * bits,
        std::size_t elements,
        std::uint32_t expected_index,
        std::uint64_t ordinal,
        bool print_case) {
    const npu_macro_identity identity = make_identity(ordinal);
    std::uint32_t actual_index = 0xffffffffU;
    npu_verilator_f32_argmax_result result = {};
    const bool executed = npu_verilator_execute_f32_argmax(
        bits, elements, &identity, &actual_index, &result);
    const std::uint32_t reference_index =
        ggml_cpu_reference_argmax(bits, elements);
    const std::uint64_t read_bytes = expected_read_bytes(elements);
    const std::uint64_t read_requests = read_bytes / 8U;
    const bool passed = executed && result.passed &&
        !result.controlled_reject && result.private_shadow_committed &&
        reference_index == expected_index &&
        actual_index == reference_index && result.result_bytes == 4U &&
        result.system_transport && result.cpu_memory_separate &&
        result.cpu_terminal_identity_match &&
        result.completion_identity_match &&
        result.completion_framing_valid && result.completion_stable &&
        result.recovery_clean && result.completion_emitted &&
        result.completion_accepted && result.completion_status == 0U &&
        result.completion_error_class == 0U &&
        result.completion_error_code == 0U && result.rtl_cycles > 0U &&
        result.gmem_read_bytes == read_bytes &&
        result.gmem_write_bytes == 4U &&
        result.vector_elements == elements && result.q8_mac_count == 0U &&
        result.state_update_count == 0U && result.f32_start_count == 0U &&
        result.commands_accepted == 1U &&
        result.commands_terminal_success == 1U &&
        result.commands_terminal_failure == 0U &&
        result.public_commands_accepted == 1U &&
        result.public_completions == 1U && result.public_errors == 0U &&
        result.cpu_config_commands_accepted == 30U &&
        result.cpu_tensor_commands_accepted == 31U &&
        result.cpu_terminals_accepted == 31U &&
        result.cpu_config_commits == 30U &&
        result.cpu_launch_commits == 1U &&
        result.gmem_requests_accepted == read_requests + 1U &&
        result.gmem_responses_accepted == read_requests + 1U &&
        result.required_issued_delta == 1U &&
        result.required_completed_delta == 1U &&
        result.returned_identity.sequence_id == identity.sequence_id &&
        result.returned_identity.producer_id == identity.producer_id &&
        result.returned_identity.user_tag == identity.user_tag &&
        result.returned_identity.node_hash_lo == identity.node_hash_lo &&
        result.returned_identity.node_hash_hi == identity.node_hash_hi &&
        portals_quiescent(result);
    if (!passed || print_case) {
        std::printf(
            "[NPU-F32-ARGMAX-CASE][%s] name=%s elements=%zu "
            "index=%u/%u/%u read_bytes=%llu/%llu requests=%llu/%llu "
            "system=%u cpu=30+1+31 required=%llu/%llu cycles=%llu "
            "runner_error=0x%x\n",
            passed ? "PASS" : "FAIL", name, elements, actual_index,
            reference_index, expected_index,
            static_cast<unsigned long long>(result.gmem_read_bytes),
            static_cast<unsigned long long>(read_bytes),
            static_cast<unsigned long long>(result.gmem_requests_accepted),
            static_cast<unsigned long long>(read_requests + 1U),
            result.system_transport ? 1U : 0U,
            static_cast<unsigned long long>(result.required_issued_delta),
            static_cast<unsigned long long>(result.required_completed_delta),
            static_cast<unsigned long long>(result.rtl_cycles),
            result.runner_error_code);
    }
    return passed;
}

bool run_reject_case(
        npu_f32_argmax_self_test_mode mode,
        const char * name,
        std::uint32_t expected_code) {
    npu_verilator_f32_argmax_result result = {};
    const bool executed = npu_verilator_run_f32_argmax_self_test(mode, &result);
    const bool passed = executed && result.passed && result.controlled_reject &&
        !result.private_shadow_committed && result.result_bytes == 0U &&
        result.system_transport && result.cpu_memory_separate &&
        result.cpu_terminal_identity_match && result.completion_stable &&
        result.recovery_clean && result.completion_status == expected_code &&
        result.completion_error_code == expected_code &&
        result.gmem_read_bytes == 0U && result.gmem_write_bytes == 0U &&
        result.vector_elements == 0U && result.q8_mac_count == 0U &&
        result.gmem_requests_accepted == 0U &&
        result.gmem_responses_accepted == 0U &&
        result.required_issued_delta == 1U &&
        result.required_completed_delta == 0U &&
        result.public_commands_accepted == 1U &&
        result.public_completions == 0U && result.public_errors == 1U &&
        result.commands_terminal_success == 0U &&
        result.commands_terminal_failure == 1U &&
        result.cpu_config_commands_accepted == 30U &&
        result.cpu_tensor_commands_accepted == 31U &&
        result.cpu_terminals_accepted == 31U &&
        result.cpu_config_commits == 30U &&
        result.cpu_launch_commits == 1U && portals_quiescent(result);
    std::printf(
        "[NPU-F32-ARGMAX-REJECT][%s] name=%s code=%u/%u "
        "traffic=%llu/%llu required=%llu/%llu system=%u "
        "runner_error=0x%x\n",
        passed ? "PASS" : "FAIL", name, result.completion_error_code,
        expected_code,
        static_cast<unsigned long long>(result.gmem_requests_accepted),
        static_cast<unsigned long long>(result.gmem_responses_accepted),
        static_cast<unsigned long long>(result.required_issued_delta),
        static_cast<unsigned long long>(result.required_completed_delta),
        result.system_transport ? 1U : 0U, result.runner_error_code);
    return passed;
}

} // namespace

int main() {
    static constexpr std::array<std::uint32_t, 3> kPositive = {
        0x3f800000U, 0x40400000U, 0x40000000U,
    };
    static constexpr std::array<std::uint32_t, 3> kTie = {
        0x40800000U, 0x40800000U, 0x40400000U,
    };
    static constexpr std::array<std::uint32_t, 4> kNan = {
        0x7fc00001U, 0xff800000U, 0x7fa00002U, 0x3f800000U,
    };
    static constexpr std::array<std::uint32_t, 3> kAllNan = {
        0x7fc00001U, 0xffc00002U, 0x7fa00003U,
    };
    static constexpr std::array<std::uint32_t, 4> kNegativeZero = {
        0xc0000000U, 0x80000000U, 0xbf800000U, 0x00000000U,
    };
    static constexpr std::array<std::uint32_t, 3> kInfinityTie = {
        0x7f800000U, 0x7f800000U, 0x7f7fffffU,
    };
    static constexpr std::array<std::uint32_t, 1> kSingle = {
        0xff800000U,
    };

    bool ok = true;
    ok = run_positive_case("positive", kPositive.data(), kPositive.size(),
                           1U, 1U, true) && ok;
    ok = run_positive_case("tie-last-index", kTie.data(), kTie.size(),
                           1U, 2U, true) && ok;
    ok = run_positive_case("nan-chain-followed-by-value", kNan.data(),
                           kNan.size(),
                           3U, 3U, true) && ok;
    ok = run_positive_case("all-nan-keeps-initial-index", kAllNan.data(),
                           kAllNan.size(), 0U, 4U, true) && ok;
    ok = run_positive_case("negative-signed-zero", kNegativeZero.data(),
                           kNegativeZero.size(), 3U, 5U, true) && ok;
    ok = run_positive_case("positive-infinity-tie", kInfinityTie.data(),
                           kInfinityTie.size(), 1U, 6U, true) && ok;
    ok = run_positive_case("single", kSingle.data(), kSingle.size(),
                           0U, 7U, true) && ok;

    static constexpr std::array<std::uint32_t, 3> kNanReset = {
        0x41200000U, 0x7fc00001U, 0xc0a00000U,
    };
    static constexpr std::array<std::uint32_t, 3> kTrailingNan = {
        0xbf800000U, 0x40000000U, 0x7fc00001U,
    };
    ok = run_positive_case("nan-resets-running-max", kNanReset.data(),
                           kNanReset.size(), 2U, 8U, true) && ok;
    ok = run_positive_case("trailing-nan-keeps-index", kTrailingNan.data(),
                           kTrailingNan.size(), 1U, 9U, true) && ok;

    std::vector<std::uint32_t> full_vocab(248320U, 0xbf800000U);
    full_vocab[123456U] = 0x42280000U;
    ok = run_positive_case("qwen35-full-vocab", full_vocab.data(),
                           full_vocab.size(), 123456U, 10U, true) && ok;

    std::vector<std::uint32_t> generic_million(1000000U, 0xc0000000U);
    generic_million[777777U] = 0x42c80000U;
    ok = run_positive_case("generic-1m", generic_million.data(),
                           generic_million.size(), 777777U, 11U, true) && ok;

    ok = run_reject_case(npu_f32_argmax_self_test_mode::invalid_stride,
                         "invalid-stride", 15U) && ok;
    ok = run_reject_case(npu_f32_argmax_self_test_mode::invalid_window,
                         "invalid-window", 16U) && ok;
    ok = run_reject_case(npu_f32_argmax_self_test_mode::overlap,
                         "overlap", 16U) && ok;

    std::printf(
        "[NPU-F32-ARGMAX][%s] kernel=0x514e0030 owner=f32-argmax "
        "positive_cases=11 reject_cases=3 actual_vocab=248320 "
        "generic_probe=1000000 oracle=ggml_vec_argmax_f32 "
        "semantics=equal-last+signed-zero-last+nan-max-reset "
        "full_sequential_scan=1 "
        "unaligned_4mod8=1 system_top=1 rv64_config=30 launch=1 "
        "terminal=31 private_commit=success-only q8_macs=0 "
        "runner_host_tensor_arithmetic=0 cpu_reference=test-only "
        "cpu_fallback_attempts=0\n",
        ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}
