#include "npu-verilator-runner.h"

#include <cstdint>
#include <cstdio>

namespace {

bool functional_inactive(
        const npu_system_functional_command_result & command) {
    return !command.enabled && command.dispatches == 0U &&
           command.completions == 0U && command.successes == 0U &&
           command.failures == 0U && command.read_words == 0U &&
           command.write_words == 0U && command.read_bytes == 0U &&
           command.write_bytes == 0U && command.q8_blocks == 0U &&
           command.q8_mac_count == 0U && command.vector_elements == 0U &&
           command.expected_read_words == 0U &&
           command.expected_write_words == 0U &&
           command.expected_read_bytes == 0U &&
           command.expected_write_bytes == 0U &&
           command.expected_q8_blocks == 0U &&
           command.expected_q8_mac_count == 0U &&
           command.expected_vector_elements == 0U &&
           command.callback_read_calls == 0U &&
           command.callback_write_calls == 0U &&
           command.callback_read_bytes == 0U &&
           command.callback_write_bytes == 0U &&
           command.callback_errors == 0U &&
           command.command_mismatches == 0U &&
           command.protocol_errors == 0U &&
           command.old_gmem_requests == 0U &&
           command.old_gmem_responses == 0U &&
           command.old_q8_portal_transactions == 0U &&
           command.old_f32_alu_portal_transactions == 0U &&
           command.old_f32_mover_portal_transactions == 0U;
}

bool portal_zero_transaction(const npu_system_raw32_portal_result & portal) {
    return portal.transactions == 1U && portal.request_groups == 0U &&
           portal.response_groups == 0U && portal.read_groups == 0U &&
           portal.write_groups == 0U && portal.read_words == 0U &&
           portal.write_words == 0U && portal.read_bytes == 0U &&
           portal.write_bytes == 0U && portal.raw_read_copy_bytes == 0U &&
           portal.raw_write_copy_bytes == 0U &&
           portal.first_request_hold_cycles == 0U &&
           portal.expected_request_groups == 0U &&
           portal.expected_response_groups == 0U &&
           portal.expected_read_groups == 0U &&
           portal.expected_write_groups == 0U &&
           portal.expected_read_words == 0U &&
           portal.expected_write_words == 0U &&
           portal.expected_read_bytes == 0U &&
           portal.expected_write_bytes == 0U &&
           portal.protocol_errors == 0U &&
           portal.latency_mismatches == 0U &&
           portal.payload_stability_mismatches == 0U &&
           functional_inactive(portal.functional_command);
}

bool run_profile(std::uint32_t profile_id) {
    npu_f32_alu_representative_identity identity = {};
    identity.profile_id = profile_id;
    identity.command_flags = 0x00000011U;
    identity.context_id = 0x43414e01U;
    identity.sequence_id = 0x1000U + profile_id;
    identity.producer_id = 0x2000U + profile_id;
    identity.user_tag = 0x3000U + profile_id;
    identity.node_hash_lo = 0x4000U + profile_id;
    identity.node_hash_hi = 0x5000U + profile_id;
    npu_verilator_f32_alu_result result = {};
    const bool executed = npu_verilator_execute_f32_alu(
        profile_id, &identity, true,
        nullptr, 0U, nullptr, 0U, nullptr, 0U, &result);
    const bool passed = executed && result.passed &&
        result.system_transport && result.cpu_memory_separate &&
        result.cpu_terminal_identity_match &&
        result.completion_emitted && result.completion_accepted &&
        result.completion_identity_match &&
        result.completion_framing_valid && result.completion_stable &&
        result.recovery_clean && !result.private_shadow_committed &&
        result.result_bytes == 0U && result.vector_elements == 0U &&
        result.f32_start_count == 0U && result.gmem_read_bytes == 0U &&
        result.gmem_write_bytes == 0U &&
        result.gmem_requests_accepted == 0U &&
        result.gmem_responses_accepted == 0U &&
        result.commands_accepted == 1U &&
        result.commands_terminal_success == 1U &&
        result.commands_terminal_failure == 0U &&
        result.public_commands_accepted == 1U &&
        result.public_completions == 1U && result.public_errors == 0U &&
        result.required_issued_delta == 1U &&
        result.required_completed_delta == 1U &&
        result.cpu_config_commands_accepted == 30U &&
        result.cpu_tensor_commands_accepted == 31U &&
        result.cpu_terminals_accepted == 31U &&
        result.cpu_config_commits == 30U &&
        result.cpu_launch_commits == 1U &&
        portal_zero_transaction(result.f32_alu_portal) &&
        result.f32_mover_portal.transactions == 0U &&
        result.q8_portal.transactions == 0U;
    if (!passed) {
        std::printf(
            "[NPU-F32-ZERO-SYSTEM][DETAIL] emitted=%u accepted=%u id=%u "
            "frame=%u stable=%u recovery=%u private=%u terminal=%llu/%llu "
            "public=%llu/%llu/%llu cpu=%llu/%llu/%llu/%llu/%llu\n",
            result.completion_emitted, result.completion_accepted,
            result.completion_identity_match,
            result.completion_framing_valid, result.completion_stable,
            result.recovery_clean, result.private_shadow_committed,
            static_cast<unsigned long long>(result.commands_accepted),
            static_cast<unsigned long long>(
                result.commands_terminal_success),
            static_cast<unsigned long long>(result.public_commands_accepted),
            static_cast<unsigned long long>(result.public_completions),
            static_cast<unsigned long long>(result.public_errors),
            static_cast<unsigned long long>(
                result.cpu_config_commands_accepted),
            static_cast<unsigned long long>(
                result.cpu_tensor_commands_accepted),
            static_cast<unsigned long long>(result.cpu_terminals_accepted),
            static_cast<unsigned long long>(result.cpu_config_commits),
            static_cast<unsigned long long>(result.cpu_launch_commits));
    }
    std::printf(
        "[NPU-F32-ZERO-SYSTEM][%s] profile=P%02u executed=%u passed=%u "
        "error=0x%x system=%llu "
        "required=%llu/%llu portal_tx=%llu groups=%llu words=%llu/%llu "
        "bytes=%llu/%llu f32_start=%llu result_bytes=%llu\n",
        passed ? "PASS" : "FAIL", profile_id,
        static_cast<unsigned>(executed), static_cast<unsigned>(result.passed),
        result.runner_error_code,
        static_cast<unsigned long long>(result.system_transport ? 1U : 0U),
        static_cast<unsigned long long>(result.required_issued_delta),
        static_cast<unsigned long long>(result.required_completed_delta),
        static_cast<unsigned long long>(result.f32_alu_portal.transactions),
        static_cast<unsigned long long>(result.f32_alu_portal.request_groups),
        static_cast<unsigned long long>(result.f32_alu_portal.read_words),
        static_cast<unsigned long long>(result.f32_alu_portal.write_words),
        static_cast<unsigned long long>(result.f32_alu_portal.read_bytes),
        static_cast<unsigned long long>(result.f32_alu_portal.write_bytes),
        static_cast<unsigned long long>(result.f32_start_count),
        static_cast<unsigned long long>(result.result_bytes));
    return passed;
}

} // namespace

int main() {
    npu_verilator_f32_alu_result rejected = {};
    const bool generic_rejected = !npu_verilator_execute_f32_alu(
        16U, nullptr, true,
        nullptr, 0U, nullptr, 0U, nullptr, 0U, &rejected);
    const bool noncanonical_rejected = !npu_verilator_execute_f32_alu(
        17U, nullptr, true,
        nullptr, 0U, nullptr, 0U, nullptr, 0U, &rejected);
    if (!generic_rejected || !noncanonical_rejected ||
        !run_profile(17U) || !run_profile(18U)) {
        return 1;
    }
    std::printf(
        "[NPU-F32-ZERO-SYSTEM][PASS] profiles=2 "
        "generic_rejected=1 noncanonical_rejected=1\n");
    return 0;
}
