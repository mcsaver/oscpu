#ifndef LLAMA_NPU_VERILATOR_RUNNER_H
#define LLAMA_NPU_VERILATOR_RUNNER_H

#include <array>
#include <cstddef>
#include <cstdint>

struct npu_verilator_self_test_result {
    bool passed = false;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t output_bytes = 0;
    std::uint32_t error_code = 0;
};

// 该入口只负责公开端口上的描述符、LMEM 字节和时钟握手。算术结果必须
// 来自 Verilated TensorNpuCoprocessor，禁止在 host 侧重算矩阵乘法。
bool npu_verilator_run_mm2_self_test(npu_verilator_self_test_result * result);

enum class npu_f32_add_mode : std::uint32_t {
    positive = 0,
    unknown_kernel = 1,
    out_of_range_4mod8 = 2,
    req_ready_low_timeout = 3,
    overpermission = 4,
};

struct npu_verilator_f32_add_result {
    bool passed = false;
    bool controlled_reject = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t result_bytes = 0;
};

// 固定 16 个 uint32 raw bits；host 只负责 byte window 与 ready-valid，
// 不得把 bit pattern 转成 float 或在 host 侧生成数值结果。
bool npu_verilator_execute_f32_add(
        const std::uint32_t * src0_bits,
        const std::uint32_t * src1_bits,
        std::uint32_t * dst_bits,
        npu_verilator_f32_add_result * result);

bool npu_verilator_run_f32_add_self_test(
        npu_f32_add_mode mode,
        npu_verilator_f32_add_result * result);

struct npu_f32_alu_tensor_descriptor {
    std::array<std::uint32_t, 4> ne = {};
    std::array<std::uint64_t, 4> nb = {};
    std::uint64_t view_off = 0;
    bool view_present = false;
};

struct npu_f32_alu_profile {
    std::uint32_t profile_id = 0;
    std::uint32_t vector_op = 0;
    std::uint32_t scalar0 = 0;
    bool src1_present = false;
    npu_f32_alu_tensor_descriptor dst = {};
    npu_f32_alu_tensor_descriptor src0 = {};
    npu_f32_alu_tensor_descriptor src1 = {};
    std::uint64_t element_count = 0;
    std::uint64_t outer_count = 0;
    std::uint64_t total_elements = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t cycle_upper_bound = 0;
};

struct npu_f32_alu_span {
    std::uint64_t logical_hi = 0;
    std::uint64_t beat_lo = 0;
    std::uint64_t beat_hi = 0;
};

// Transaction identity carried through fields that the RTL completion
// actually echoes.  Synthetic self-test identities occupy a textual `rep:`
// namespace and never set REQUIRED.  Production supplies a canonical identity
// whose four 64-bit fields carry all 32 SHA-256 bytes and sets REQUIRED.
struct npu_f32_alu_representative_identity {
    std::uint32_t profile_id = 0;
    std::uint32_t command_flags = 0;
    std::uint32_t context_id = 0;
    std::uint64_t sequence_id = 0;
    std::uint64_t producer_id = 0;
    std::uint64_t user_tag = 0;
    std::uint64_t node_hash_lo = 0;
    std::uint64_t node_hash_hi = 0;
};

// The completion wire identity is shared by every canonical macro kernel.
// The historical name remains the ABI-compatible storage type for the F32
// representative tests; production Q8 uses the neutral alias below.
using npu_macro_identity = npu_f32_alu_representative_identity;

// Per-transaction proof emitted by the simulation-only command-DPI child.
// The old GMEM and raw portal transports must stay idle while this ledger is
// enabled.  Callback counters prove that the numerical TU reached tensor
// bytes only through the checked resident capability boundary.
struct npu_system_functional_command_result {
    bool enabled = false;
    std::uint64_t dispatches = 0;
    std::uint64_t completions = 0;
    std::uint64_t successes = 0;
    std::uint64_t failures = 0;
    std::uint64_t read_words = 0;
    std::uint64_t write_words = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint64_t q8_blocks = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t expected_read_words = 0;
    std::uint64_t expected_write_words = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_q8_blocks = 0;
    std::uint64_t expected_q8_mac_count = 0;
    std::uint64_t expected_vector_elements = 0;
    std::uint64_t callback_read_calls = 0;
    std::uint64_t callback_write_calls = 0;
    std::uint64_t callback_read_bytes = 0;
    std::uint64_t callback_write_bytes = 0;
    std::uint64_t callback_errors = 0;
    std::uint64_t command_mismatches = 0;
    std::uint64_t protocol_errors = 0;
    std::uint64_t old_gmem_requests = 0;
    std::uint64_t old_gmem_responses = 0;
    std::uint64_t old_q8_portal_transactions = 0;
    std::uint64_t old_f32_alu_portal_transactions = 0;
    std::uint64_t old_f32_mover_portal_transactions = 0;
};

// Per-transaction proof ledger for the raw Q8_0 block portal.  These are byte
// transport counters only: no field represents host-side dequantization,
// dot-product work, accumulation, or destination generation.
struct npu_system_q8_portal_result {
    std::uint64_t transactions = 0;
    std::uint64_t request_groups = 0;
    std::uint64_t response_groups = 0;
    std::uint64_t blocks = 0;
    std::uint64_t bytes = 0;
    std::uint64_t raw_copy_bytes = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t expected_request_groups = 0;
    std::uint64_t expected_blocks = 0;
    std::uint64_t expected_bytes = 0;
    std::uint64_t protocol_errors = 0;
    std::uint64_t latency_mismatches = 0;
    std::uint64_t payload_stability_mismatches = 0;
    // Kept inside this copied envelope so the existing Q8 adapter result ABI
    // carries command-DPI evidence without changing legacy runner files.
    npu_system_functional_command_result functional_command = {};
};

// Common ledger for a raw 32-bit word portal.  The host side of this
// contract is byte transport only: reads memcpy one raw word from a registered
// source capability and writes memcpy the RTL-produced raw word into the
// transaction-private destination shadow.  None of these counters represent
// host-side tensor arithmetic.
struct npu_system_raw32_portal_result {
    std::uint64_t transactions = 0;
    std::uint64_t request_groups = 0;
    std::uint64_t response_groups = 0;
    std::uint64_t read_groups = 0;
    std::uint64_t write_groups = 0;
    std::uint64_t read_words = 0;
    std::uint64_t write_words = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint64_t raw_read_copy_bytes = 0;
    std::uint64_t raw_write_copy_bytes = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t expected_request_groups = 0;
    std::uint64_t expected_response_groups = 0;
    std::uint64_t expected_read_groups = 0;
    std::uint64_t expected_write_groups = 0;
    std::uint64_t expected_read_words = 0;
    std::uint64_t expected_write_words = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t protocol_errors = 0;
    std::uint64_t latency_mismatches = 0;
    std::uint64_t payload_stability_mismatches = 0;
    // Analogous copied envelope for F32 ALU/mover adapter results.
    npu_system_functional_command_result functional_command = {};
};

enum class npu_f32_alu_mode : std::uint32_t {
    positive = 0,
    unknown_kernel = 1,
    invalid_profile = 2,
    op_profile_collision = 3,
    summary_mismatch = 4,
    scalar_mismatch = 5,
    out_of_range_4mod8 = 6,
    overlap = 7,
    overpermission = 8,
    req_ready_low_timeout = 9,
};

struct npu_verilator_f32_alu_result {
    bool passed = false;
    bool controlled_reject = false;
    bool private_shadow_committed = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    bool completion_emitted = false;
    bool completion_accepted = false;
    bool representative_identity_match = false;
    std::uint32_t profile_id = 0;
    std::uint32_t submitted_profile_id = 0;
    std::uint32_t observed_profile_id = 0;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t cycle_upper_bound = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t result_bytes = 0;
    std::uint64_t required_issued_delta = 0;
    std::uint64_t required_completed_delta = 0;
    bool system_transport = false;
    bool cpu_memory_separate = false;
    bool cpu_terminal_identity_match = false;
    std::uint64_t system_cycles = 0;
    std::uint64_t public_commands_accepted = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t cpu_config_commands_accepted = 0;
    std::uint64_t cpu_tensor_commands_accepted = 0;
    std::uint64_t cpu_terminals_accepted = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint32_t cpu_launch_instruction = 0;
    std::uint32_t cpu_launch_pid = 0;
    npu_system_q8_portal_result q8_portal = {};
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    npu_f32_alu_representative_identity submitted_identity = {};
    npu_f32_alu_representative_identity returned_identity = {};
};

// Machine-visible copy of the RTL P00--P18 table and its checked source-span
// operation.  No function in this interface converts raw bits to float.
bool npu_f32_alu_profile_by_id(
        std::uint32_t profile_id,
        npu_f32_alu_profile * profile);
bool npu_f32_alu_source_span(
        const npu_f32_alu_tensor_descriptor & descriptor,
        npu_f32_alu_span * span);
bool npu_f32_alu_representative_identity_by_profile(
        std::uint32_t profile_id,
        npu_f32_alu_representative_identity * identity);

// Raw-only production path.  Source pointers name allocation bases (not view
// pointers); only [beat_lo,beat_hi) is copied into simulated GMEM.  dst_shadow
// is transaction-private caller storage and receives bytes only after exact
// SUCCESS/identity/framing/counter closure.
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
        npu_verilator_f32_alu_result * result);

bool npu_verilator_run_f32_alu_self_test(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result);

// Explicitly isolated legacy/direct-port probe.  Production positive profile
// tests must not use this entry; it is available only so historical negative
// protocol fixtures can opt into the separately built direct self-test DSO.
bool npu_verilator_run_direct_f32_alu_self_test(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result);

struct npu_q8_get_rows_profile {
    std::uint32_t profile_id = 0;
    std::uint32_t embedding_dim = 0;
    std::uint32_t gathered_rows = 0;
    std::uint32_t vocabulary_rows = 0;
    std::uint64_t table_row_stride = 0;
    std::uint64_t index_stride = 0;
    std::uint64_t dst_row_stride = 0;
    std::uint64_t table_bytes = 0;
    std::uint64_t index_bytes = 0;
    std::uint64_t dst_bytes = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_elements = 0;
    std::uint64_t cycle_upper_bound = 0;
};

struct npu_verilator_q8_get_rows_result {
    bool passed = false;
    bool controlled_reject = false;
    bool private_shadow_committed = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    bool completion_emitted = false;
    bool completion_accepted = false;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t cycle_upper_bound = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t result_bytes = 0;
    std::uint64_t required_issued_delta = 0;
    std::uint64_t required_completed_delta = 0;
    bool system_transport = false;
    bool cpu_memory_separate = false;
    bool cpu_terminal_identity_match = false;
    std::uint64_t system_cycles = 0;
    std::uint64_t public_commands_accepted = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t cpu_config_commands_accepted = 0;
    std::uint64_t cpu_tensor_commands_accepted = 0;
    std::uint64_t cpu_terminals_accepted = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint32_t cpu_launch_instruction = 0;
    std::uint32_t cpu_launch_pid = 0;
    npu_system_q8_portal_result q8_portal = {};
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    npu_macro_identity submitted_identity = {};
    npu_macro_identity returned_identity = {};
};

// Frozen canonical-v5 embedding profile: GET_ROWS(Q8_0 table, I32 index) to
// private F32 output, D=1024/N=1/V=248320.  Source bytes are served directly
// from the caller's raw allocation through registered GMEM windows; the host
// never dequantizes or otherwise performs tensor arithmetic.
bool npu_q8_get_rows_profile_v1(npu_q8_get_rows_profile * profile);

bool npu_verilator_execute_q8_get_rows(
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * table_allocation,
        std::size_t table_allocation_bytes,
        const std::uint8_t * index_allocation,
        std::size_t index_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_q8_get_rows_result * result);

// Canonical-v5 Q8_0 weight x F32 activation GEMV.  GGML names the packed
// weights src0 and the activation src1; the public Coprocessor ABI deliberately
// reverses those two operands so its src0 window is contiguous F32 and its
// src1 window is strided Q8_0.  profile_id is runtime-only ownership metadata:
// the frozen RTL vector_flags field remains zero for kernel 0x514e0002.
struct npu_q8_gemv_profile {
    std::uint32_t profile_id = 0;
    std::uint32_t k = 0;
    std::uint32_t m = 0;
    // Runtime rows sent on the public descriptor.  Frozen graph profiles use
    // command_rows == m; the single canonical terminal N=0 variant uses zero
    // while preserving the original weight-M/profile identity.
    std::uint32_t command_rows = 0;
    std::uint32_t block_count = 0;
    std::uint64_t activation_bytes = 0;
    std::uint64_t weight_row_stride = 0;
    std::uint64_t weight_bytes = 0;
    std::uint64_t dst_row_stride = 0;
    std::uint64_t dst_bytes = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_read_requests = 0;
    std::uint64_t expected_write_requests = 0;
    std::uint64_t expected_q8_macs = 0;
    std::uint64_t expected_elements = 0;
    std::uint64_t cycle_upper_bound = 0;
};

struct npu_verilator_q8_gemv_result {
    bool passed = false;
    bool controlled_reject = false;
    bool private_shadow_committed = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    bool completion_emitted = false;
    bool completion_accepted = false;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t cycle_upper_bound = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t result_bytes = 0;
    std::uint64_t required_issued_delta = 0;
    std::uint64_t required_completed_delta = 0;
    bool system_transport = false;
    bool cpu_memory_separate = false;
    bool cpu_terminal_identity_match = false;
    std::uint64_t system_cycles = 0;
    std::uint64_t public_commands_accepted = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t cpu_config_commands_accepted = 0;
    std::uint64_t cpu_tensor_commands_accepted = 0;
    std::uint64_t cpu_terminals_accepted = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint32_t cpu_launch_instruction = 0;
    std::uint32_t cpu_launch_pid = 0;
    npu_system_q8_portal_result q8_portal = {};
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    npu_macro_identity submitted_identity = {};
    npu_macro_identity returned_identity = {};
};

// Validates the exact frozen public descriptor equations and fills only the
// derived traffic/counter/cycle fields.  It never observes tensor data.
bool npu_q8_gemv_finalize_profile(npu_q8_gemv_profile * profile);

// Raw transport only: activation/weight bytes are served to the Verilated
// Coprocessor GMEM port and the destination is transaction-private until an
// exact SUCCESS/identity/REQUIRED/counter closure.  No host GEMV or float
// conversion is permitted in this interface or implementation.
bool npu_verilator_execute_q8_gemv(
        const npu_q8_gemv_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * activation_allocation,
        std::size_t activation_allocation_bytes,
        const std::uint8_t * weight_allocation,
        std::size_t weight_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_q8_gemv_result * result);

enum class npu_f32_mover_owner : std::uint32_t {
    get_rows = 0,
    repeat = 1,
};

// Frozen-v5 raw F32 gather/repeat descriptor.  The runtime profile id belongs
// only to the manifest matcher; both public kernels keep vector_flags/profile
// zero on the wire.  All byte counters are semantic payload counters, matching
// the public Coprocessor completion contract (one 4-byte word per GMEM request).
struct npu_f32_mover_profile {
    std::uint32_t profile_id = 0;
    npu_f32_mover_owner owner = npu_f32_mover_owner::get_rows;
    std::uint32_t element_count = 0;
    std::uint32_t source_row_count = 0;
    std::uint32_t index_count = 0;
    std::uint32_t outer_count = 0;
    std::uint32_t repeat_count = 0;
    std::uint64_t src_bytes = 0;
    std::uint64_t index_bytes = 0;
    std::uint64_t dst_bytes = 0;
    std::uint64_t src_row_stride = 0;
    std::uint64_t index_stride = 0;
    std::uint64_t dst_row_stride = 0;
    std::uint64_t dst_outer_stride = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_elements = 0;
    std::uint64_t expected_read_requests = 0;
    std::uint64_t expected_write_requests = 0;
    std::uint64_t cycle_upper_bound = 0;
};

struct npu_verilator_f32_mover_result {
    bool passed = false;
    bool controlled_reject = false;
    bool private_shadow_committed = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    bool completion_emitted = false;
    bool completion_accepted = false;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t cycle_upper_bound = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t result_bytes = 0;
    std::uint64_t required_issued_delta = 0;
    std::uint64_t required_completed_delta = 0;
    bool system_transport = false;
    bool cpu_memory_separate = false;
    bool cpu_terminal_identity_match = false;
    std::uint64_t system_cycles = 0;
    std::uint64_t public_commands_accepted = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t cpu_config_commands_accepted = 0;
    std::uint64_t cpu_tensor_commands_accepted = 0;
    std::uint64_t cpu_terminals_accepted = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint32_t cpu_launch_instruction = 0;
    std::uint32_t cpu_launch_pid = 0;
    npu_system_q8_portal_result q8_portal = {};
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    npu_macro_identity submitted_identity = {};
    npu_macro_identity returned_identity = {};
};

bool npu_f32_mover_finalize_profile(npu_f32_mover_profile * profile);

// Raw transport only.  The host serves bytes to the public macro GMEM port and
// publishes the private destination only after exact terminal/identity/ledger
// closure.  Empty GET_ROWS accepts null/zero host allocations and must complete
// with no GMEM request.
bool npu_verilator_execute_f32_mover(
        const npu_f32_mover_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * src_allocation,
        std::size_t src_allocation_bytes,
        const std::uint8_t * index_allocation,
        std::size_t index_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_f32_mover_result * result);

// Canonical-v5 owners which are not part of the historical 646-node runtime
// set.  These numeric values intentionally mirror only the generated manifest
// owner table.  They are not public Coprocessor operation/profile numbers.
enum class npu_exact_owner : std::uint32_t {
    unary = 0,
    rms_norm = 1,
    l2_norm = 2,
    sum_rows = 3,
    glu = 4,
    ssm_conv = 5,
    cpy = 6,
    cont = 7,
    concat = 8,
    set_rows = 9,
    f16_attention_mul_mat = 10,
    rope = 11,
    soft_max = 12,
};

// Exact metadata copied from qwen-remaining-manifest.generated.h.  The runner
// never receives ggml_tensor and never interprets floating-point payloads.
// Region offsets are relative to the raw allocation base supplied below.
struct npu_exact_tensor_descriptor {
    std::uint32_t type_id = 0;
    std::uint32_t op_id = 0;
    std::uint32_t flags = 0;
    bool view_present = false;
    std::uint64_t view_off = 0;
    std::array<std::int64_t, 4> ne = {};
    std::array<std::uint64_t, 4> nb = {};
    std::array<std::uint8_t, 64> op_params = {};
};

struct npu_exact_profile {
    std::uint32_t manifest_profile_id = 0;
    std::uint32_t owner_profile_id = 0;
    npu_exact_owner owner = npu_exact_owner::unary;
    std::uint32_t source_count = 0;
    npu_exact_tensor_descriptor dst = {};
    std::array<npu_exact_tensor_descriptor, 3> sources = {};

    // Derived only by npu_exact_finalize_profile().  The public route is kept
    // separate from the generated global profile id so vector_flags always
    // carries the exact local profile expected by the resident RTL owner.
    std::uint32_t public_kernel_id = 0;
    std::uint32_t public_vector_op = 0;
    std::uint32_t public_local_profile = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_elements = 0;
    std::uint64_t expected_read_requests = 0;
    std::uint64_t expected_write_requests = 0;
    std::uint64_t expected_q8_macs = 0;
    std::uint64_t expected_state_updates = 0;
    std::uint64_t cycle_upper_bound = 0;
};

struct npu_exact_raw_allocation {
    const std::uint8_t * bytes = nullptr;
    std::size_t size = 0;
};

struct npu_exact_private_destination {
    // This is transaction-private storage initialized by a raw memcpy of the
    // destination allocation.  It becomes caller-visible only after the
    // backend validates the returned SUCCESS/identity/counter ledger.
    std::uint8_t * bytes = nullptr;
    std::size_t size = 0;
};

// Fully materialized public macro submission.  Keeping this integer-only
// contract outside the harness makes every one of the 30 exact profiles
// unit-testable, including view IOVAs, raw backing windows and SET_ROWS'
// dst/src2 alias, before any Verilated clock is advanced.
struct npu_exact_command_contract {
    std::uint32_t abi_valid = 0;
    std::uint32_t windows_generation_valid = 0;
    std::uint32_t kernel_id = 0;
    std::uint32_t vector_op = 0;
    std::uint32_t local_profile = 0;
    std::uint32_t command_flags = 0;
    std::uint32_t context_id = 0;
    std::uint32_t capability_epoch = 0;
    std::uint32_t node_count = 0;
    std::uint64_t sequence_id = 0;
    std::uint64_t producer_id = 0;
    std::uint64_t user_tag = 0;
    std::uint64_t node_hash_lo = 0;
    std::uint64_t node_hash_hi = 0;
    std::uint64_t deadline_cycles = 0;
    std::uint64_t src0_iova = 0;
    std::uint64_t src1_iova = 0;
    std::uint64_t src2_iova = 0;
    std::uint64_t dst_iova = 0;
    std::uint64_t scratch_iova = 0;
    std::uint64_t element_count = 0;
    std::uint32_t outer_count = 0;
    std::uint32_t dtype = 0;
    std::uint64_t src0_stride = 0;
    std::uint64_t src1_stride = 0;
    std::uint64_t src2_stride = 0;
    std::uint64_t dst_stride = 0;
    std::uint32_t scalar0 = 0;
    std::uint32_t scalar1 = 0;
    std::uint64_t scratch_bytes = 0;
    std::uint32_t rope_position = 0;
    std::uint64_t src0_window_base = 0;
    std::uint64_t src0_window_size = 0;
    std::uint32_t src0_window_perm = 0;
    std::uint64_t src1_window_base = 0;
    std::uint64_t src1_window_size = 0;
    std::uint32_t src1_window_perm = 0;
    std::uint64_t dst_window_base = 0;
    std::uint64_t dst_window_size = 0;
    std::uint32_t dst_window_perm = 0;
    bool dst_shadow_readable = false;
};

struct npu_verilator_exact_result {
    bool passed = false;
    bool controlled_reject = false;
    bool private_shadow_committed = false;
    bool completion_identity_match = false;
    bool completion_framing_valid = false;
    bool completion_stable = false;
    bool recovery_clean = false;
    bool completion_emitted = false;
    bool completion_accepted = false;
    bool system_transport = false;
    bool cpu_memory_separate = false;
    bool cpu_terminal_identity_match = false;
    std::uint32_t manifest_profile_id = 0;
    std::uint32_t submitted_local_profile = 0;
    std::uint32_t observed_local_profile = 0;
    std::uint32_t completion_status = 0;
    std::uint32_t completion_error_class = 0;
    std::uint32_t completion_error_code = 0;
    std::uint32_t runner_error_code = 0;
    std::uint64_t rtl_cycles = 0;
    std::uint64_t system_cycles = 0;
    std::uint64_t cycle_upper_bound = 0;
    std::uint64_t gmem_read_bytes = 0;
    std::uint64_t gmem_write_bytes = 0;
    std::uint64_t vector_elements = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t state_update_count = 0;
    std::uint64_t f32_start_count = 0;
    std::uint64_t commands_accepted = 0;
    std::uint64_t commands_terminal_success = 0;
    std::uint64_t commands_terminal_failure = 0;
    std::uint64_t public_commands_accepted = 0;
    std::uint64_t public_completions = 0;
    std::uint64_t public_errors = 0;
    std::uint64_t cpu_config_commands_accepted = 0;
    std::uint64_t cpu_tensor_commands_accepted = 0;
    std::uint64_t cpu_terminals_accepted = 0;
    std::uint64_t cpu_config_commits = 0;
    std::uint64_t cpu_launch_commits = 0;
    std::uint32_t cpu_launch_instruction = 0;
    std::uint32_t cpu_launch_pid = 0;
    std::uint64_t gmem_requests_accepted = 0;
    std::uint64_t gmem_responses_accepted = 0;
    std::uint64_t first_request_hold_cycles = 0;
    std::uint64_t result_bytes = 0;
    std::uint64_t required_issued_delta = 0;
    std::uint64_t required_completed_delta = 0;
    npu_system_q8_portal_result q8_portal = {};
    npu_system_raw32_portal_result f32_alu_portal = {};
    npu_system_raw32_portal_result f32_mover_portal = {};
    npu_system_functional_command_result functional_command = {};
    npu_macro_identity submitted_identity = {};
    npu_macro_identity returned_identity = {};
};

// Fully materialized input to the one production SystemTop transport.  Owner
// adapters may derive these integer/raw-byte fields from their frozen profile,
// but only this transport executes the descriptor program and services GMEM.
struct npu_system_raw_window {
    std::uint64_t region_base = 0;
    const std::uint8_t * read_bytes = nullptr;
    std::uint8_t * write_bytes = nullptr;
    std::size_t allocation_bytes = 0;
    std::uint64_t window_base = 0;
    std::uint64_t window_bytes = 0;
    bool readable = false;
    bool writable = false;
};

struct npu_system_raw32_portal_contract {
    bool enabled = false;
    std::uint32_t lanes = 0;
    std::uint32_t response_latency_cycles = 0;
    std::uint64_t expected_request_groups = 0;
    std::uint64_t expected_response_groups = 0;
    std::uint64_t expected_read_groups = 0;
    std::uint64_t expected_write_groups = 0;
    std::uint64_t expected_read_words = 0;
    std::uint64_t expected_write_words = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
};

// Some public kernels can reject after reading raw tensor metadata (for
// example, an out-of-range GET_ROWS index).  The host must not inspect or
// interpret those tensor bytes to predict the branch.  Instead the transport
// accepts exactly one predeclared error ledger and selects it only from the
// real raw completion's error bit.
struct npu_system_reject_contract {
    bool enabled = false;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_vector_elements = 0;
    std::uint64_t expected_q8_macs = 0;
    std::uint64_t expected_state_updates = 0;
    std::uint64_t expected_read_requests = 0;
    std::uint64_t expected_write_requests = 0;
    std::uint64_t expected_f32_starts = 0;
    std::uint64_t expected_required_issued = 0;
    std::uint64_t expected_required_completed = 0;
    std::uint64_t expected_public_completions = 0;
    std::uint64_t expected_public_errors = 1;
    std::uint64_t expected_macro_completions = 0;
    std::uint32_t expected_status = 0;
    std::uint32_t expected_error_class = 0;
    std::uint32_t expected_error_code = 0;
    bool validate_source_read_requests = false;
    std::array<std::uint64_t, 2> expected_source_read_requests = {};
    npu_system_raw32_portal_contract f32_alu_portal = {};
    npu_system_raw32_portal_contract f32_mover_portal = {};
};

struct npu_system_q8_portal_contract {
    bool enabled = false;
    std::uint32_t row_lanes = 0;
    std::uint32_t mac_lanes = 0;
    std::uint32_t block_bytes = 0;
    std::uint32_t blocks_per_row = 0;
    std::uint32_t response_latency_cycles = 0;
    std::uint64_t expected_request_groups = 0;
    std::uint64_t expected_blocks = 0;
    std::uint64_t expected_bytes = 0;
};

struct npu_system_transaction {
    std::uint32_t manifest_profile_id = 0;
    npu_exact_command_contract command = {};
    npu_macro_identity identity = {};
    std::array<npu_system_raw_window, 2> sources = {};
    npu_system_raw_window destination = {};
    const std::uint8_t * expected_write_mask = nullptr;
    std::size_t expected_write_mask_bytes = 0;
    // Destination bytes which must be written in the private shadow before
    // publication.  This is deliberately independent of completion GMEM
    // bytes because raw32 portal traffic bypasses the public GMEM channel.
    // Zero preserves the historical non-portal interpretation, where the
    // semantic byte total equals expected_write_bytes.
    std::uint64_t expected_semantic_write_bytes = 0;
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    std::uint64_t expected_vector_elements = 0;
    std::uint64_t expected_q8_macs = 0;
    std::uint64_t expected_state_updates = 0;
    std::uint64_t expected_read_requests = 0;
    std::uint64_t expected_write_requests = 0;
    std::uint64_t expected_f32_starts = 0;
    std::uint64_t expected_required_issued = 0;
    std::uint64_t expected_required_completed = 0;
    std::uint64_t expected_public_completions = 1;
    std::uint64_t expected_public_errors = 0;
    std::uint64_t expected_macro_completions = 1;
    std::uint32_t expected_status = 0;
    std::uint32_t expected_error_class = 0;
    std::uint32_t expected_error_code = 0;
    std::uint64_t cycle_upper_bound = 0;
    bool expect_success = true;
    bool require_unique_read_beats = false;
    bool require_f32_halfbeat_wstrb = false;
    bool validate_source_read_requests = false;
    std::array<std::uint64_t, 2> expected_source_read_requests = {};
    npu_system_q8_portal_contract q8_portal = {};
    npu_system_raw32_portal_contract f32_alu_portal = {};
    npu_system_raw32_portal_contract f32_mover_portal = {};
    npu_system_reject_contract controlled_reject = {};
};

// Resolves all 30 generated profiles through the frozen public mapping and
// derives integer-only byte/request/work bounds.  Unknown owner/profile/route
// combinations fail closed; generated global ids are never used on the wire.
bool npu_exact_finalize_profile(npu_exact_profile * profile);

bool npu_exact_build_command_contract(
        const npu_exact_profile * profile,
        const npu_macro_identity * canonical_identity,
        std::uint32_t set_rows_slot,
        const std::array<std::size_t, 3> * source_backing_bytes,
        std::size_t dst_backing_bytes,
        npu_exact_command_contract * command);

bool npu_verilator_execute_system_transaction(
        const npu_system_transaction * transaction,
        npu_verilator_exact_result * result);

// Strict-sampler transaction: scan one contiguous F32 logits vector in RTL
// and publish only the winning I32 token index.  The caller supplies raw bits
// and a canonical transaction identity; it never supplies or receives an
// FP32 value.  Source base is intentionally 4 mod 8 in the production runner
// so the same path proves both lower- and upper-half beat selection.
// The comparison loop is bit-for-bit behavioral parity with the repository's
// ggml_vec_argmax_f32 oracle: MAX(current, value), followed by == to update
// the index.  Equal values (including signed zero) therefore choose the last
// index, and NaN follows that oracle's reset-without-index-update behavior.
using npu_verilator_f32_argmax_result = npu_verilator_exact_result;

enum class npu_f32_argmax_self_test_mode : std::uint32_t {
    positive = 0,
    invalid_stride = 1,
    invalid_window = 2,
    overlap = 3,
};

bool npu_verilator_execute_f32_argmax(
        const std::uint32_t * logits_bits,
        std::size_t element_count,
        const npu_macro_identity * transaction_identity,
        std::uint32_t * token_index,
        npu_verilator_f32_argmax_result * result);

// Focused fail-closed descriptor qualification.  Positive mode is a small
// raw-bit vector; the remaining modes require a zero-traffic public error
// completion and no destination publication.
bool npu_verilator_run_f32_argmax_self_test(
        npu_f32_argmax_self_test_mode mode,
        npu_verilator_f32_argmax_result * result);

// Production RV64-SystemTop transport for the remaining owners.  Each call
// constructs a private CPU DPI program/descriptor aperture and executes real
// 30 x LD+CONFIG plus adjacent LO/HI instructions.  C++ drives only clock,
// reset, terminal backpressure, and raw GMEM responses.  src2 is accepted only
// for SET_ROWS and aliases the private old-destination shadow; public windows
// remain src0/read, src1/read, dst/write.
bool npu_verilator_execute_exact(
        const npu_exact_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::array<npu_exact_raw_allocation, 3> * sources,
        npu_exact_private_destination * dst_shadow,
        npu_verilator_exact_result * result);

#endif
