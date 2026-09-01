#ifndef LLAMA_NPU_FUNCTIONAL_COMMAND_DPI_H
#define LLAMA_NPU_FUNCTIONAL_COMMAND_DPI_H

#include <cstddef>
#include <cstdint>

#include <svdpi.h>

// Scalar-only image of the command resident in TensorNpuFunctionalCommandDpi.
// Tensor/ggml pointers are intentionally absent.  The numerical functional
// unit can reach bytes only through the thread-local checked-copy context
// registered by the owning SystemTop transaction.
struct npu_functional_command {
    bool abi_valid = false;
    bool windows_generation_valid = false;
    std::uint32_t kernel_id = 0;
    std::uint32_t command_flags = 0;
    std::uint32_t vector_op = 0;
    std::uint32_t vector_flags = 0;
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
    std::uint32_t scratch_bytes = 0;
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
};

// One-call result returned to the clocked SystemVerilog child.  read_words and
// write_words count semantic 32-bit words.  Packed Q8_0 weights are counted as
// q8_blocks instead, so the frozen byte equations are:
//   read_bytes  = read_words * 4 + q8_blocks * 34
//   write_bytes = write_words * 4
struct npu_functional_command_result {
    bool success = false;
    std::uint32_t error_code = 0;
    std::uint32_t error_class = 0;
    std::uint64_t read_words = 0;
    std::uint64_t write_words = 0;
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint64_t q8_blocks = 0;
    std::uint64_t q8_mac_count = 0;
    std::uint64_t vector_elements = 0;
    std::uint32_t callback_errors = 0;

    // C++-side transport evidence.  These fields are not part of the DPI ABI;
    // they allow the resident harness/unit tests to prove that all payload
    // access went through checked callbacks.
    std::uint64_t callback_read_calls = 0;
    std::uint64_t callback_write_calls = 0;
    std::uint64_t callback_read_bytes = 0;
    std::uint64_t callback_write_bytes = 0;
};

class npu_functional_command_capability_context {
public:
    virtual ~npu_functional_command_capability_context() = default;

    // Implementations must perform overflow-safe capability/window/permission
    // checks before copying.  No implementation may interpret tensor payload.
    virtual bool checked_read(
        std::uint64_t address,
        void * destination,
        std::size_t bytes) = 0;
    virtual bool checked_write(
        std::uint64_t address,
        const void * source,
        std::size_t bytes) = 0;

    // Called exactly once after a production DPI invocation returns.  This is
    // control/ledger evidence only; the command image contains scalars and
    // IOVAs, never host tensor pointers.  Unit-test contexts may retain the
    // default no-op implementation.
    virtual void command_completed(
        const npu_functional_command &,
        const npu_functional_command_result &) {}
};

// One resident SystemTop transaction owns exactly one context per thread.
// Nested/cross-transaction registration is rejected rather than silently
// replacing the active capability set.
class npu_functional_command_scope {
public:
    explicit npu_functional_command_scope(
        npu_functional_command_capability_context * context);
    ~npu_functional_command_scope();

    npu_functional_command_scope(const npu_functional_command_scope &) = delete;
    npu_functional_command_scope & operator=(
        const npu_functional_command_scope &) = delete;

    bool active() const;

private:
    npu_functional_command_capability_context * context_ = nullptr;
    bool active_ = false;
};

// C++ entry used by the dedicated numerical/capability unit test.  Production
// reaches the same implementation only through npu_functional_command_execute.
bool npu_functional_command_execute_cpp(
    const npu_functional_command * command,
    npu_functional_command_result * result);

// Frozen scalar-only DPI-C ABI consumed by rtl/TensorNpuFunctionalCommandDpi.sv.
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
    unsigned int * callback_errors);

#endif
