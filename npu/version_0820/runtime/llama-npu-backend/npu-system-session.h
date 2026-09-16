#ifndef LLAMA_NPU_SYSTEM_SESSION_H
#define LLAMA_NPU_SYSTEM_SESSION_H

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// A synchronous, single-owner SystemTop service session.  The implementation
// owns one RV64 CPU + NPU model for its whole lifetime and boots the fixed
// service firmware exactly once. Every supported owner uses the real RTL
// datapath; the host memory callbacks perform raw byte transport only.

enum class npu_system_command_owner : std::uint32_t {
    f32_alu = 0U,
    q8_get_rows, q8_gemv, f32_mover, exact, argmax,
};

enum class npu_system_expected_outcome : std::uint32_t {
    success = 0U,
    recoverable_npu_fault,
    fatal_npu_fault,
};

struct npu_system_command_identity {
    std::uint32_t kernel_id = 0U;
    std::uint32_t command_flags = 0U;
    std::uint32_t context_id = 0U;
    std::uint64_t sequence_id = 0U;
    std::uint64_t producer_id = 0U;
    std::uint64_t user_tag = 0U;
    std::uint32_t covered_node_count = 0U;
    std::uint64_t node_hash_lo = 0U;
    std::uint64_t node_hash_hi = 0U;
    std::uint32_t local_profile = 0U;
};

struct npu_system_f32_alu_contract {
    std::uint64_t request_groups = 0U;
    std::uint64_t response_groups = 0U;
    std::uint64_t read_groups = 0U;
    std::uint64_t write_groups = 0U;
    std::uint64_t input_words = 0U;
    std::uint64_t output_words = 0U;
    std::uint64_t read_bytes = 0U;
    std::uint64_t write_bytes = 0U;
    std::uint64_t completion_vector_elements = 0U;
    // Exact RTL F32 datapath starts for this macro.  A successful
    // zero-cardinality command has zero; a non-empty command has one.  This is
    // compiler-owned metadata, not something the runtime infers from shape.
    std::uint64_t expected_starts = 0U;
};

// Independent per-owner raw transport and hardware completion ledger.
struct npu_system_memory_contract {
    std::uint64_t gmem_reads = 0, gmem_writes = 0;
    std::uint64_t gmem_read_bytes = 0, gmem_write_bytes = 0;
    std::uint64_t q8_groups = 0, q8_blocks = 0, q8_macs = 0;
    std::uint64_t vector_elements = 0, state_updates = 0;
    npu_system_f32_alu_contract mover = {};
};

struct npu_system_command_contract {
    npu_system_command_owner owner = npu_system_command_owner::f32_alu;
    npu_system_expected_outcome expected_outcome =
        npu_system_expected_outcome::success;
    // Exact terminal error code, including bit 7's fatal/reset-required tag.
    // It is zero for success.
    std::uint8_t expected_npu_error_code = 0U;
    npu_system_command_identity identity = {};
    npu_system_f32_alu_contract f32_alu = {};
    npu_system_memory_contract memory = {};
    std::uint64_t max_cycles = 0;
};

// bytes is borrowed for the duration of dispatch().  A writable capability
// must point at dispatch-private storage: the session mutates raw bytes only
// in response to an accepted RTL portal write and never performs tensor or
// floating-point arithmetic on the host.
struct npu_system_raw_buffer {
    std::string id;
    std::uint64_t base = 0U;
    std::uint32_t permissions = 0U;  // read=1, write=2
    std::vector<std::uint8_t> * bytes = nullptr;
};

struct npu_system_raw_copy {
    std::uint64_t src = 0, dst = 0, bytes = 0;
};
struct npu_system_command_copies {
    npu_system_raw_copy before = {}, after = {};
};

struct npu_system_submission {
    std::uint64_t generation = 0U;
    const std::vector<std::uint8_t> * relocated_command_image = nullptr;
    std::vector<npu_system_raw_buffer> buffers;
    std::vector<npu_system_command_contract> commands;
    std::vector<npu_system_command_copies> copies;
    std::uint64_t max_cycles = 300000U;
};

struct npu_system_counters {
    std::uint64_t cycles = 0U;
    std::uint64_t commits = 0U;
    std::uint64_t config_accepts = 0U;
    std::uint64_t launch_accepts = 0U;
    std::uint64_t macro_terminals = 0U;
    std::uint64_t portal_requests = 0U;
    std::uint64_t portal_responses = 0U;
    std::uint64_t portal_reads = 0U;
    std::uint64_t portal_writes = 0U;
    std::uint64_t portal_input_words = 0U;
    std::uint64_t portal_output_words = 0U;
    std::uint64_t portal_read_bytes = 0U;
    std::uint64_t portal_write_bytes = 0U;
    std::uint64_t gmem_read_bytes = 0U, gmem_write_bytes = 0U;
    std::uint64_t q8_blocks = 0U, mover_read_bytes = 0U, mover_write_bytes = 0U;
    std::uint64_t vector_elements = 0U;
    std::uint64_t dma_starts = 0, dma_completions = 0, dma_read_bytes = 0, dma_write_bytes = 0;
    std::uint64_t rtl_macro_commands = 0U;
    std::uint64_t rtl_f32_starts = 0U;
    std::uint64_t rtl_macro_completions = 0U;
    std::uint64_t rtl_error_clears = 0U;
    std::uint64_t traps = 0U;
    std::uint64_t exits = 0U;
};

struct npu_system_buffer_activity {
    std::string id;
    std::uint64_t read_words = 0U;
    std::uint64_t write_words = 0U;
    std::uint64_t reads_after_write = 0U;
};

struct npu_system_dispatch_result {
    std::uint64_t generation = 0U;
    std::uint32_t mailbox_state = 0U;
    std::uint32_t mailbox_error = 0U;
    std::uint32_t completed = 0U;
    std::uint64_t boot_count = 0U;
    std::uint32_t completion_status = 0U;
    std::uint64_t fault_tval = 0U;
    std::uint64_t fault_pc = 0U;
    std::uint64_t fault_cause = 0U;
    npu_system_counters before = {};
    npu_system_counters after = {};
    npu_system_counters delta = {};
    std::vector<npu_system_buffer_activity> buffers;
};

enum class npu_system_session_error : std::uint32_t {
    none = 0U,
    router_busy,
    allocation_failure,
    firmware_image,
    boot_timeout,
    session_fatal,
    invalid_submission,
    stale_generation,
    command_image,
    command_contract,
    unsupported_owner,
    buffer_capability,
    timeout,
    firmware_error,
    recoverable_npu_fault,
    fatal_npu_fault,
    cpu_memory,
    portal_protocol,
    unexpected_owner,
    terminal_mismatch,
    completion_mismatch,
    unexpected_trap,
};

struct npu_system_session_status {
    bool booted = false;
    bool fatal = false;
    std::uint64_t constructor_count = 0U;
    std::uint64_t reset_release_count = 0U;
    std::uint64_t boot_count = 0U;
    std::uint64_t last_generation = 0U;
    std::uint32_t mailbox_state = 0U;
    std::uint32_t mailbox_error = 0U;
    std::uint8_t npu_error_code = 0U;
    npu_system_counters counters = {};
};

class npu_system_session {
public:
    explicit npu_system_session(int argc = 0, char ** argv = nullptr);
    ~npu_system_session();

    npu_system_session(const npu_system_session &) = delete;
    npu_system_session & operator=(const npu_system_session &) = delete;

    bool ready() const;
    bool fatal() const;
    npu_system_session_error last_error() const;
    const std::string & failure() const;
    npu_system_session_status status() const;

    // generation must be nonzero and strictly greater than every generation
    // accepted by firmware in this boot epoch; a recoverable fault consumes
    // its generation too.  Validation and stale-owner
    // rejection happen before mailbox or caller buffer mutation.
    bool dispatch(
            const npu_system_submission & submission,
            npu_system_dispatch_result * result = nullptr);

private:
    class impl;
    std::unique_ptr<impl> impl_;
};

const char * npu_system_session_error_string(npu_system_session_error error);

#endif
