#include "npu-verilator-runner.h"
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
#include "npu-functional-command-dpi.h"
#endif

#include "VNpcTensorNpuSystemTop.h"
#include "VNpcTensorNpuSystemTop__Dpi.h"
#include "verilated.h"
#include "svdpi.h"

#include <dlfcn.h>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <memory>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <vector>

// NpcSimTop reaches its instruction/data memory through these DPI callbacks.
// Every production invocation owns an independent CPU aperture; the callback
// target is thread-local so unrelated backend threads cannot share program or
// descriptor bytes.  NPU GMEM is deliberately not reachable through this
// interface and remains handled by the raw windows below.
class npu_exact_dpi_context {
public:
    virtual ~npu_exact_dpi_context() = default;
    virtual bool cpu_read(
        std::uint64_t address,
        std::uint32_t bytes,
        std::uint64_t * value) = 0;
    virtual bool cpu_write(
        std::uint64_t address,
        std::uint64_t value,
        std::uint64_t mask) = 0;
    virtual void cpu_commit(std::uint64_t pc, std::uint32_t instruction) = 0;
    virtual void cpu_trap(std::uint32_t cause, std::uint64_t pc) = 0;
    virtual std::uint64_t cpu_cycles() const = 0;
    virtual std::uint64_t cpu_commits() const = 0;
};

thread_local npu_exact_dpi_context * g_npu_exact_dpi_context = nullptr;

extern "C" int npc_ifetch_sized(
        unsigned long long address,
        unsigned int bytes,
        unsigned long long * data,
        svBit * error) {
    if (data != nullptr) {
        *data = 0;
    }
    std::uint64_t value = 0;
    const bool ok = g_npu_exact_dpi_context != nullptr && data != nullptr &&
                    g_npu_exact_dpi_context->cpu_read(
                        address, bytes, &value);
    if (data != nullptr) {
        *data = value;
    }
    if (error != nullptr) {
        *error = ok ? 0 : 1;
    }
    return 0;
}

extern "C" int npc_mem_read_sized(
        unsigned long long address,
        unsigned int bytes,
        unsigned long long * data,
        svBit * error) {
    return npc_ifetch_sized(address, bytes, data, error);
}

extern "C" int npc_mem_write(
        unsigned long long address,
        unsigned long long data,
        unsigned long long mask,
        svBit * error) {
    const bool ok = g_npu_exact_dpi_context != nullptr &&
                    g_npu_exact_dpi_context->cpu_write(
                        address, data, mask);
    if (error != nullptr) {
        *error = ok ? 0 : 1;
    }
    return 0;
}

extern "C" void npc_commit_event(
        unsigned long long pc,
        unsigned int instruction,
        unsigned long long,
        unsigned int,
        unsigned int,
        unsigned long long,
        unsigned int) {
    if (g_npu_exact_dpi_context != nullptr) {
        g_npu_exact_dpi_context->cpu_commit(pc, instruction);
    }
}

extern "C" void npc_exit_event(
        unsigned int,
        unsigned int,
        unsigned int,
        unsigned long long,
        unsigned long long) {}

extern "C" unsigned long long npc_current_cycles() {
    return g_npu_exact_dpi_context == nullptr ? 0 :
        g_npu_exact_dpi_context->cpu_cycles();
}

extern "C" unsigned long long npc_current_commits() {
    return g_npu_exact_dpi_context == nullptr ? 0 :
        g_npu_exact_dpi_context->cpu_commits();
}

extern "C" void npc_mmio_load_event() {}

extern "C" void npc_trap_event(
        unsigned int cause,
        unsigned long long pc,
        unsigned long long) {
    if (g_npu_exact_dpi_context != nullptr) {
        g_npu_exact_dpi_context->cpu_trap(cause, pc);
    }
}

extern "C" void npc_handled_trap_event(
        unsigned int,
        unsigned int cause,
        unsigned long long pc,
        unsigned long long) {
    if (g_npu_exact_dpi_context != nullptr) {
        g_npu_exact_dpi_context->cpu_trap(cause, pc);
    }
}

extern "C" void npc_arch_csr_event(
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long) {}

extern "C" void npc_arch_fpr_event(
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long, unsigned long long,
        unsigned long long, unsigned long long) {}

extern "C" void npc_uart_event(
        unsigned int, unsigned int, unsigned int, unsigned int,
        unsigned long long, unsigned int, unsigned long long) {}

extern "C" int npc_uart_rx_pop(unsigned int * data) {
    if (data != nullptr) {
        *data = 0;
    }
    return 0;
}

extern "C" void npc_irq_event(unsigned int, unsigned int) {}

extern "C" int npc_virtio_blk_read(
        unsigned int,
        unsigned long long * data,
        svBit * error,
        svBit * interrupt) {
    if (data != nullptr) {
        *data = 0;
    }
    if (error != nullptr) {
        *error = 1;
    }
    if (interrupt != nullptr) {
        *interrupt = 0;
    }
    return 0;
}

extern "C" int npc_virtio_blk_write(
        unsigned int,
        unsigned long long,
        unsigned long long,
        svBit * error,
        svBit * interrupt) {
    if (error != nullptr) {
        *error = 1;
    }
    if (interrupt != nullptr) {
        *interrupt = 0;
    }
    return 0;
}

extern "C" int npc_virtio_blk_irq(svBit * interrupt) {
    if (interrupt != nullptr) {
        *interrupt = 0;
    }
    return 0;
}

namespace {

constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kMacroDtypeF32 = 1U;
constexpr std::uint64_t kSrc0Iova = 0x0000000310000000ULL;
constexpr std::uint64_t kSrc1Iova = 0x0000000520000000ULL;
constexpr std::uint64_t kDstIova = 0x0000000730000000ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2ULL;
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
constexpr std::uint32_t kFunctionalQ8GetRowsKernel = 0x514e0001U;
constexpr std::uint32_t kFunctionalQ8GemvKernel = 0x514e0002U;
constexpr std::uint32_t kFunctionalF32GetRowsKernel = 0x514e0003U;
constexpr std::uint32_t kFunctionalF32RepeatKernel = 0x514e0004U;
constexpr std::uint32_t kFunctionalMoverKernel = 0x514e0007U;
constexpr std::uint32_t kFunctionalSetRowsKernel = 0x514e0008U;
constexpr std::uint32_t kFunctionalVectorF32Kernel = 0x514e0010U;
constexpr std::uint64_t kFunctionalQ8BlockBytes = 34U;
constexpr std::uint64_t kFunctionalQ8BlockElements = 32U;
#endif
#if defined(NPU_SYSTEM_Q8_PORTAL)
constexpr std::uint32_t kQ8PortalKernel = 0x514e0002U;
constexpr std::uint32_t kQ8PortalRowLanes = 4U;
constexpr std::uint32_t kQ8PortalMacLanes = 32U;
constexpr std::uint32_t kQ8PortalBlockBytes = 34U;
constexpr std::uint32_t kQ8PortalResponseWords = 34U;
constexpr std::uint32_t kQ8PortalAddressWords = 8U;
constexpr std::uint32_t kQ8PortalResponseLatencyCycles = 2U;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
constexpr std::uint32_t kF32AluPortalKernel = 0x514e0010U;
constexpr std::uint32_t kF32AluPortalLanes = 8U;
constexpr std::uint32_t kF32AluPortalResponseLatencyCycles = 2U;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
constexpr std::uint32_t kF32MoverGetRowsKernel = 0x514e0003U;
constexpr std::uint32_t kF32MoverRepeatKernel = 0x514e0004U;
constexpr std::uint32_t kF32MoverPortalLanes = 16U;
constexpr std::uint32_t kF32MoverPortalResponseLatencyCycles = 2U;
#endif
constexpr std::uint64_t kCpuBase = 0x80000000ULL;
constexpr std::size_t kCpuBytes = 8192U;
constexpr std::uint64_t kDescriptorAddress = kCpuBase + 0x700ULL;
constexpr std::uint32_t kAddiCpuBase = 0x00100093U;
constexpr std::uint32_t kSlliCpuBase = 0x01f09093U;
constexpr std::uint32_t kNop = 0x00000013U;
constexpr std::uint32_t kLaunchLo = 0x0220305bU;
constexpr std::uint32_t kLaunchHi = 0x0bf0305bU;
constexpr std::uint32_t kPark = 0x0000006fU;
constexpr std::uint64_t kLaunchBits =
    (static_cast<std::uint64_t>(kLaunchHi) << 32U) | kLaunchLo;
constexpr std::uint64_t kFirstConfigPc = kCpuBase + 16ULL;
constexpr std::uint64_t kLaunchPc = kCpuBase + 8ULL + 30ULL * 16ULL;
constexpr std::uint64_t kCpuBootstrapAllowance = 20000ULL;

enum exact_runner_error : std::uint32_t {
    exact_runner_ok = 0,
    exact_runner_allocation = 0x1a0,
    exact_runner_timeout = 0x1a1,
    exact_runner_reset_interface = 0x1a2,
    exact_runner_command_interface = 0x1a3,
    exact_runner_request_protocol = 0x1a4,
    exact_runner_response_protocol = 0x1a5,
    exact_runner_completion_protocol = 0x1a6,
    exact_runner_completion_identity = 0x1a7,
    exact_runner_completion_framing = 0x1a8,
    exact_runner_memory_bounds = 0x1a9,
    exact_runner_result_coverage = 0x1aa,
    exact_runner_terminal_mismatch = 0x1ab,
    exact_runner_recovery = 0x1ac,
    exact_runner_profile = 0x1ad,
    exact_runner_cpu_memory = 0x1ae,
    exact_runner_cpu_protocol = 0x1af,
    exact_runner_cpu_commit = 0x1b0,
    exact_runner_cpu_terminal = 0x1b1,
    exact_runner_first_request_hold = 0x1b2,
    exact_runner_q8_portal_contract = 0x1b3,
    exact_runner_q8_portal_request = 0x1b4,
    exact_runner_q8_portal_response = 0x1b5,
    exact_runner_q8_portal_memory = 0x1b6,
    exact_runner_q8_portal_counter = 0x1b7,
    exact_runner_f32_alu_portal_contract = 0x1b8,
    exact_runner_f32_alu_portal_request = 0x1b9,
    exact_runner_f32_alu_portal_response = 0x1ba,
    exact_runner_f32_alu_portal_memory = 0x1bb,
    exact_runner_f32_alu_portal_counter = 0x1bc,
    exact_runner_f32_mover_portal_contract = 0x1bd,
    exact_runner_f32_mover_portal_request = 0x1be,
    exact_runner_f32_mover_portal_response = 0x1bf,
    exact_runner_f32_mover_portal_memory = 0x1c0,
    exact_runner_f32_mover_portal_counter = 0x1c1,
    exact_runner_functional_contract = 0x1c2,
    exact_runner_functional_callback = 0x1c3,
    exact_runner_functional_ledger = 0x1c4,
};

bool checked_add(
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

bool checked_mul(
        std::uint64_t lhs,
        std::uint64_t rhs,
        std::uint64_t * result) {
    if (result == nullptr ||
        (lhs != 0 &&
         rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *result = lhs * rhs;
    return true;
}

#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
bool derive_functional_command_ledger(
        const npu_exact_command_contract & command,
        npu_functional_command_result * expected) {
    if (expected == nullptr) {
        return false;
    }
    *expected = {};
    switch (command.kernel_id) {
        case kFunctionalVectorF32Kernel: {
            npu_f32_alu_profile profile = {};
            if (!npu_f32_alu_profile_by_id(
                    command.local_profile, &profile) ||
                command.vector_op != profile.vector_op ||
                command.scalar0 != profile.scalar0 ||
                command.element_count != profile.element_count ||
                command.outer_count != profile.outer_count) {
                return false;
            }
            expected->read_words = profile.total_elements *
                (profile.src1_present ? 2U : 1U);
            expected->write_words = profile.total_elements;
            expected->vector_elements = profile.total_elements;
            break;
        }
        case kFunctionalQ8GemvKernel: {
            if (command.vector_op != 0U || command.local_profile != 0U ||
                command.element_count == 0U || command.outer_count == 0U ||
                command.element_count % kFunctionalQ8BlockElements != 0U) {
                return false;
            }
            const std::uint64_t blocks_per_row =
                command.element_count / kFunctionalQ8BlockElements;
            expected->read_words = command.element_count;
            expected->write_words = command.outer_count;
            if (!checked_mul(command.outer_count, blocks_per_row,
                             &expected->q8_blocks) ||
                !checked_mul(command.outer_count, command.element_count,
                             &expected->q8_mac_count)) {
                return false;
            }
            expected->vector_elements = command.outer_count;
            break;
        }
        case kFunctionalQ8GetRowsKernel: {
            if (command.vector_op != 0U || command.local_profile != 0U ||
                command.element_count == 0U || command.outer_count == 0U ||
                command.element_count % kFunctionalQ8BlockElements != 0U) {
                return false;
            }
            const std::uint64_t blocks_per_row =
                command.element_count / kFunctionalQ8BlockElements;
            expected->read_words = command.outer_count;
            if (!checked_mul(command.element_count, command.outer_count,
                             &expected->write_words) ||
                !checked_mul(command.outer_count, blocks_per_row,
                             &expected->q8_blocks)) {
                return false;
            }
            expected->vector_elements = expected->write_words;
            break;
        }
        case kFunctionalF32GetRowsKernel: {
            if (command.vector_op != 0U || command.local_profile != 0U ||
                command.element_count == 0U) {
                return false;
            }
            if (command.outer_count == 0U) {
                std::uint64_t row_bytes = 0U;
                return (command.element_count == 1024U ||
                        command.element_count == 18432U ||
                        command.element_count == 262144U) &&
                       checked_mul(command.element_count, 4U, &row_bytes) &&
                       command.scalar0 == 0U &&
                       command.src1_iova != 0U &&
                       command.src0_stride == row_bytes &&
                       command.src1_stride == 4U &&
                       command.src2_stride == 0U &&
                       command.dst_stride == row_bytes &&
                       command.src0_window_size == 0U &&
                       command.src1_window_size == 0U &&
                       command.dst_window_size == 0U &&
                       command.src1_window_perm == 1U;
            }
            std::uint64_t elements = 0;
            if (!checked_mul(command.element_count, command.outer_count,
                             &elements) ||
                !checked_add(command.outer_count, elements,
                             &expected->read_words)) {
                return false;
            }
            expected->write_words = elements;
            expected->vector_elements = elements;
            break;
        }
        case kFunctionalF32RepeatKernel:
            if (command.vector_op != 0U || command.local_profile != 0U ||
                command.element_count == 0U || command.outer_count == 0U ||
                command.scalar0 == 0U ||
                !checked_mul(command.element_count, command.outer_count,
                             &expected->read_words) ||
                !checked_mul(expected->read_words, command.scalar0,
                             &expected->write_words)) {
                return false;
            }
            expected->vector_elements = expected->write_words;
            break;
        case kFunctionalMoverKernel: {
            if ((command.local_profile == 0U && command.vector_op != 22U) ||
                ((command.local_profile == 1U ||
                  command.local_profile == 2U) &&
                 command.vector_op != 35U) ||
                (command.local_profile >= 3U &&
                 command.local_profile <= 6U &&
                 command.vector_op != 34U) ||
                command.local_profile > 6U) {
                return false;
            }
            constexpr std::array<std::uint64_t, 7> kElements = {
                24576U, 2048U, 2048U, 0U, 18432U, 0U, 262144U,
            };
            expected->read_words = kElements[command.local_profile];
            expected->write_words = kElements[command.local_profile];
            expected->vector_elements = kElements[command.local_profile];
            break;
        }
        case kFunctionalSetRowsKernel:
            if (command.vector_op != 42U ||
                (command.local_profile != 7U &&
                 command.local_profile != 8U)) {
                return false;
            }
            expected->read_words =
                command.local_profile == 7U ? 1536U : 514U;
            expected->write_words = 256U;
            expected->vector_elements = 512U;
            break;
        default:
            return false;
    }
    std::uint64_t nonq8_read_bytes = 0;
    std::uint64_t q8_read_bytes = 0;
    return checked_mul(expected->read_words, 4U, &nonq8_read_bytes) &&
           checked_mul(expected->q8_blocks, kFunctionalQ8BlockBytes,
                       &q8_read_bytes) &&
           checked_add(nonq8_read_bytes, q8_read_bytes,
                       &expected->read_bytes) &&
           checked_mul(expected->write_words, 4U,
                       &expected->write_bytes);
}
#endif

bool checked_product(
        const std::array<std::int64_t, 4> & ne,
        std::uint64_t * product) {
    if (product == nullptr) {
        return false;
    }
    std::uint64_t value = 1;
    for (std::int64_t extent : ne) {
        if (extent < 0 ||
            !checked_mul(value, static_cast<std::uint64_t>(extent), &value)) {
            return false;
        }
    }
    *product = value;
    return true;
}

std::uint64_t type_bytes(std::uint32_t type_id) {
    switch (type_id) {
        case 0U:  // GGML_TYPE_F32
        case 26U: // GGML_TYPE_I32
            return 4;
        case 1U:  // GGML_TYPE_F16
            return 2;
        case 27U: // GGML_TYPE_I64
            return 8;
        default:
            return 0;
    }
}

bool tensor_span(
        const npu_exact_tensor_descriptor & descriptor,
        std::uint64_t * logical_low,
        std::uint64_t * logical_high) {
    if (logical_low == nullptr || logical_high == nullptr ||
        (!descriptor.view_present && descriptor.view_off != 0)) {
        return false;
    }
    const std::uint64_t width = type_bytes(descriptor.type_id);
    if (width == 0) {
        return false;
    }
    std::uint64_t count = 0;
    if (!checked_product(descriptor.ne, &count)) {
        return false;
    }
    *logical_low = descriptor.view_off;
    if (count == 0) {
        *logical_high = descriptor.view_off;
        return true;
    }
    std::uint64_t high = descriptor.view_off;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (descriptor.ne[dimension] <= 0) {
            return false;
        }
        std::uint64_t term = 0;
        if (!checked_mul(
                static_cast<std::uint64_t>(descriptor.ne[dimension] - 1),
                descriptor.nb[dimension], &term) ||
            !checked_add(high, term, &high)) {
            return false;
        }
    }
    return checked_add(high, width, logical_high);
}

bool descriptor_backing_floor(
        const npu_exact_tensor_descriptor & descriptor,
        std::uint64_t * backing_floor,
        bool * logically_empty = nullptr) {
    if (backing_floor == nullptr) {
        return false;
    }
    std::uint64_t low = 0;
    std::uint64_t high = 0;
    std::uint64_t count = 0;
    if (!tensor_span(descriptor, &low, &high) ||
        !checked_product(descriptor.ne, &count)) {
        return false;
    }
    std::uint64_t required = high;
    for (std::uint64_t stride : descriptor.nb) {
        if (stride > required) {
            required = stride;
        }
    }
    if ((required & 7U) != 0U) {
        return false;
    }
    *backing_floor = required;
    if (logically_empty != nullptr) {
        *logically_empty = count == 0;
    }
    return true;
}

bool effective_backing_bytes(
        const npu_exact_tensor_descriptor & descriptor,
        std::size_t supplied_bytes,
        std::uint64_t * effective_bytes) {
    if (effective_bytes == nullptr) {
        return false;
    }
    std::uint64_t floor = 0;
    bool logically_empty = false;
    if (!descriptor_backing_floor(
            descriptor, &floor, &logically_empty)) {
        return false;
    }
    const std::uint64_t supplied =
        static_cast<std::uint64_t>(supplied_bytes);
    if (supplied != 0 && (supplied < floor || (supplied & 7U) != 0U)) {
        return false;
    }
    if (supplied == 0 && !logically_empty) {
        return false;
    }
    // A zero-element GGML tensor can report a zero logical byte count even
    // though the frozen public profile reserves a backing region (CPY's
    // empty-cache sentinels are the concrete case).  Advertising that frozen
    // raw region is safe because the exact owner emits no transaction for the
    // empty tensor; the host never fabricates tensor values.
    *effective_bytes = supplied == 0 ? floor : supplied;
    return (*effective_bytes & 7U) == 0U;
}

bool all_zero_after(
        const std::array<std::uint8_t, 64> & bytes,
        std::size_t first) {
    for (std::size_t index = first; index < bytes.size(); ++index) {
        if (bytes[index] != 0) {
            return false;
        }
    }
    return true;
}

std::uint32_t load_le32(
        const std::array<std::uint8_t, 64> & bytes,
        std::size_t offset = 0) {
    std::uint32_t value = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        value |= static_cast<std::uint32_t>(bytes[offset + index]) <<
                 (8 * index);
    }
    return value;
}

bool set_expected_route(
        npu_exact_profile * profile,
        std::uint32_t expected_global,
        std::uint32_t kernel,
        std::uint32_t operation,
        std::uint32_t local_profile) {
    if (profile == nullptr ||
        profile->manifest_profile_id != expected_global) {
        return false;
    }
    profile->public_kernel_id = kernel;
    profile->public_vector_op = operation;
    profile->public_local_profile = local_profile;
    return true;
}

bool resolve_public_route(npu_exact_profile * profile) {
    if (profile == nullptr || profile->manifest_profile_id >= 30U) {
        return false;
    }
    const std::uint32_t owner_profile = profile->owner_profile_id;
    switch (profile->owner) {
        case npu_exact_owner::unary: {
            static constexpr std::array<std::uint32_t, 6> kOperations = {
                15U, 13U, 10U, 7U, 10U, 7U,
            };
            static constexpr std::array<std::uint32_t, 6> kLocalProfiles = {
                2U, 5U, 4U, 0U, 3U, 1U,
            };
            return owner_profile < kOperations.size() &&
                   set_expected_route(
                       profile, owner_profile, 0x514e0005U,
                       kOperations[owner_profile],
                       kLocalProfiles[owner_profile]);
        }
        case npu_exact_owner::rms_norm: {
            static constexpr std::array<std::uint32_t, 5> kLocalProfiles = {
                0U, 1U, 0U, 3U, 2U,
            };
            return owner_profile < kLocalProfiles.size() &&
                   set_expected_route(
                       profile, 6U + owner_profile, 0x514e0011U, 4U,
                       kLocalProfiles[owner_profile]);
        }
        case npu_exact_owner::l2_norm:
            return owner_profile < 2U && set_expected_route(
                profile, 11U + owner_profile, 0x514e0011U, 5U, 4U);
        case npu_exact_owner::sum_rows:
            return owner_profile == 0U && set_expected_route(
                profile, 13U, 0x514e0011U, 1U, 0U);
        case npu_exact_owner::glu:
            return owner_profile == 0U && set_expected_route(
                profile, 14U, 0x514e0006U, 2U, 6U);
        case npu_exact_owner::ssm_conv:
            return owner_profile == 0U && set_expected_route(
                profile, 15U, 0x514e0022U, 76U, 0U);
        case npu_exact_owner::cpy:
            return owner_profile < 4U && set_expected_route(
                profile, 16U + owner_profile, 0x514e0007U, 34U,
                3U + owner_profile);
        case npu_exact_owner::cont:
            return owner_profile < 2U && set_expected_route(
                profile, 20U + owner_profile, 0x514e0007U, 35U,
                1U + owner_profile);
        case npu_exact_owner::concat:
            return owner_profile == 0U && set_expected_route(
                profile, 22U, 0x514e0007U, 22U, 0U);
        case npu_exact_owner::set_rows:
            return owner_profile < 2U && set_expected_route(
                profile, 23U + owner_profile, 0x514e0008U, 42U,
                owner_profile == 0U ? 8U : 7U);
        case npu_exact_owner::f16_attention_mul_mat:
            return owner_profile < 2U && set_expected_route(
                profile, 25U + owner_profile, 0x514e0009U, 29U,
                owner_profile);
        case npu_exact_owner::rope:
            return owner_profile < 2U && set_expected_route(
                profile, 27U + owner_profile, 0x514e000aU, 48U,
                owner_profile);
        case npu_exact_owner::soft_max:
            return owner_profile == 0U && set_expected_route(
                profile, 29U, 0x514e0011U, 6U, 0U);
    }
    return false;
}

bool derive_expected_counters(npu_exact_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    std::uint64_t dst_count = 0;
    std::array<std::uint64_t, 3> source_counts = {};
    if (!checked_product(profile->dst.ne, &dst_count)) {
        return false;
    }
    for (std::uint32_t index = 0; index < profile->source_count; ++index) {
        if (!checked_product(profile->sources[index].ne,
                             &source_counts[index])) {
            return false;
        }
    }
    std::uint64_t read_bytes = 0;
    std::uint64_t write_bytes = 0;
    std::uint64_t work = 0;
    std::uint64_t read_requests = 0;
    std::uint64_t write_requests = 0;
    switch (profile->owner) {
        case npu_exact_owner::unary:
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
            if (profile->source_count != 1U ||
                source_counts[0] != dst_count ||
                !checked_mul(dst_count, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            read_requests = dst_count;
            write_requests = dst_count;
            break;
        case npu_exact_owner::glu:
            if (profile->source_count != 2U ||
                source_counts[0] != dst_count ||
                source_counts[1] != dst_count ||
                !checked_mul(dst_count, 8, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            if (!checked_mul(dst_count, 2, &read_requests)) {
                return false;
            }
            write_requests = dst_count;
            break;
        case npu_exact_owner::sum_rows:
            if (profile->source_count != 1U ||
                !checked_mul(source_counts[0], 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes) ||
                (source_counts[0] & 1U) != 0) {
                return false;
            }
            work = source_counts[0];
            read_requests = source_counts[0] / 2;
            write_requests = dst_count;
            break;
        case npu_exact_owner::ssm_conv: {
            std::uint64_t source_total = 0;
            if (profile->source_count != 2U ||
                !checked_add(source_counts[0], source_counts[1],
                             &source_total) ||
                !checked_mul(source_total, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes) ||
                (source_total & 1U) != 0) {
                return false;
            }
            work = write_bytes;
            read_requests = source_total / 2;
            write_requests = dst_count;
            break;
        }
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
            if ((profile->owner == npu_exact_owner::cont &&
                 profile->source_count != 1U) ||
                (profile->owner != npu_exact_owner::cont &&
                 profile->source_count != 2U) ||
                !checked_mul(dst_count, 4, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            read_requests = dst_count;
            write_requests = dst_count;
            break;
        case npu_exact_owner::set_rows:
            if (profile->source_count != 3U || dst_count != 131072U) {
                return false;
            }
            read_bytes = profile->owner_profile_id == 0U ? 2056U : 6144U;
            write_bytes = 1024U;
            work = 512U;
            read_requests = profile->owner_profile_id == 0U ? 513U : 1024U;
            write_requests = 512U;
            break;
        case npu_exact_owner::f16_attention_mul_mat:
            if (profile->source_count != 2U || dst_count != 2048U) {
                return false;
            }
            read_bytes = 1056768U;
            write_bytes = 8192U;
            work = 2048U;
            read_requests = 132096U;
            write_requests = 2048U;
            break;
        case npu_exact_owner::rope:
            if (profile->source_count != 2U ||
                (dst_count != 2048U && dst_count != 512U)) {
                return false;
            }
            read_requests = dst_count == 2048U ? 1026U : 258U;
            write_requests = dst_count == 2048U ? 1280U : 320U;
            if (!checked_mul(read_requests, 8, &read_bytes) ||
                !checked_mul(dst_count, 4, &write_bytes)) {
                return false;
            }
            work = dst_count;
            break;
        case npu_exact_owner::soft_max:
            if (profile->source_count != 2U || dst_count != 2048U) {
                return false;
            }
            read_bytes = 9216U;
            write_bytes = 8192U;
            work = 2048U;
            read_requests = 1152U;
            write_requests = 1024U;
            break;
    }

    std::uint64_t request_total = 0;
    std::uint64_t scaled = 0;
    std::uint64_t cycle_bound = 0;
    if (!checked_add(read_requests, write_requests, &request_total) ||
        !checked_mul(request_total, 128U, &scaled) ||
        !checked_add(2000000U, scaled, &cycle_bound)) {
        cycle_bound = 1500000000ULL;
    }
    if (cycle_bound > 1500000000ULL) {
        cycle_bound = 1500000000ULL;
    }
    profile->expected_read_bytes = read_bytes;
    profile->expected_write_bytes = write_bytes;
    profile->expected_elements = work;
    profile->expected_read_requests = read_requests;
    profile->expected_write_requests = write_requests;
    profile->expected_q8_macs = 0;
    profile->expected_state_updates = 0;
    profile->cycle_upper_bound = cycle_bound;
    return true;
}

bool validate_profile_metadata(const npu_exact_profile & profile) {
    static constexpr std::array<std::uint32_t, 13> kOpIds = {
        91U, 25U, 28U, 15U, 100U, 76U, 34U,
        35U, 22U, 42U, 29U, 48U, 46U,
    };
    const std::size_t owner_index =
        static_cast<std::size_t>(profile.owner);
    if (owner_index >= kOpIds.size() ||
        profile.dst.op_id != kOpIds[owner_index] ||
        profile.dst.flags != 16U ||
        profile.source_count < 1U || profile.source_count > 3U) {
        return false;
    }
    for (std::uint32_t index = profile.source_count;
         index < profile.sources.size(); ++index) {
        const auto & empty = profile.sources[index];
        if (empty.type_id != 0 || empty.op_id != 0 || empty.flags != 0 ||
            empty.view_present || empty.view_off != 0) {
            return false;
        }
    }
    switch (profile.owner) {
        case npu_exact_owner::unary:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) ==
                       profile.public_vector_op &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 0x358637bdU &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::sum_rows:
        case npu_exact_owner::ssm_conv:
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
            return profile.dst.type_id == 0U &&
                   all_zero_after(profile.dst.op_params, 0);
        case npu_exact_owner::glu:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 2U &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::set_rows:
            return profile.dst.type_id == 1U &&
                   profile.sources[0].type_id == 0U &&
                   profile.sources[1].type_id == 27U &&
                   profile.sources[2].type_id == 1U &&
                   all_zero_after(profile.dst.op_params, 0);
        case npu_exact_owner::f16_attention_mul_mat:
            return profile.dst.type_id == 0U &&
                   profile.sources[0].type_id == 1U &&
                   profile.sources[1].type_id == 0U &&
                   load_le32(profile.dst.op_params) ==
                       (profile.owner_profile_id == 0U ? 10U : 0U) &&
                   all_zero_after(profile.dst.op_params, 4);
        case npu_exact_owner::rope:
            return profile.dst.type_id == 0U &&
                   profile.sources[0].type_id == 0U &&
                   profile.sources[1].type_id == 26U;
        case npu_exact_owner::soft_max:
            return profile.dst.type_id == 0U &&
                   load_le32(profile.dst.op_params) == 0x3d800000U &&
                   all_zero_after(profile.dst.op_params, 8);
    }
    return false;
}

struct completion_snapshot {
    std::uint32_t terminal_producer_id = 0;
    std::uint32_t terminal_error = 0;
    std::uint32_t terminal_error_code = 0;
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
#if defined(NPU_SYSTEM_Q8_PORTAL)
    std::uint64_t q8_portal_request_count = 0;
    std::uint64_t q8_portal_response_count = 0;
    std::uint64_t q8_portal_block_count = 0;
    std::uint64_t q8_portal_byte_count = 0;
    std::uint32_t q8_portal_outstanding = 0;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    std::uint64_t f32_alu_portal_request_groups = 0;
    std::uint64_t f32_alu_portal_response_groups = 0;
    std::uint64_t f32_alu_portal_read_groups = 0;
    std::uint64_t f32_alu_portal_write_groups = 0;
    std::uint64_t f32_alu_portal_input_words = 0;
    std::uint64_t f32_alu_portal_output_words = 0;
    std::uint64_t f32_alu_portal_read_bytes = 0;
    std::uint64_t f32_alu_portal_write_bytes = 0;
    std::uint32_t f32_alu_portal_outstanding = 0;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    std::uint64_t f32_mover_portal_request_groups = 0;
    std::uint64_t f32_mover_portal_response_groups = 0;
    std::uint64_t f32_mover_portal_read_groups = 0;
    std::uint64_t f32_mover_portal_write_groups = 0;
    std::uint64_t f32_mover_portal_read_words = 0;
    std::uint64_t f32_mover_portal_write_words = 0;
    std::uint64_t f32_mover_portal_read_bytes = 0;
    std::uint64_t f32_mover_portal_write_bytes = 0;
    std::uint32_t f32_mover_portal_outstanding = 0;
#endif

    bool operator==(const completion_snapshot & other) const {
        return terminal_producer_id == other.terminal_producer_id &&
               terminal_error == other.terminal_error &&
               terminal_error_code == other.terminal_error_code &&
               is_macro == other.is_macro && status == other.status &&
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
               state_update_count == other.state_update_count
#if defined(NPU_SYSTEM_Q8_PORTAL)
               && q8_portal_request_count ==
                      other.q8_portal_request_count
               && q8_portal_response_count ==
                      other.q8_portal_response_count
               && q8_portal_block_count == other.q8_portal_block_count
               && q8_portal_byte_count == other.q8_portal_byte_count
               && q8_portal_outstanding == other.q8_portal_outstanding
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
               && f32_alu_portal_request_groups ==
                      other.f32_alu_portal_request_groups
               && f32_alu_portal_response_groups ==
                      other.f32_alu_portal_response_groups
               && f32_alu_portal_read_groups ==
                      other.f32_alu_portal_read_groups
               && f32_alu_portal_write_groups ==
                      other.f32_alu_portal_write_groups
               && f32_alu_portal_input_words ==
                      other.f32_alu_portal_input_words
               && f32_alu_portal_output_words ==
                      other.f32_alu_portal_output_words
               && f32_alu_portal_read_bytes ==
                      other.f32_alu_portal_read_bytes
               && f32_alu_portal_write_bytes ==
                      other.f32_alu_portal_write_bytes
               && f32_alu_portal_outstanding ==
                      other.f32_alu_portal_outstanding
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
               && f32_mover_portal_request_groups ==
                      other.f32_mover_portal_request_groups
               && f32_mover_portal_response_groups ==
                      other.f32_mover_portal_response_groups
               && f32_mover_portal_read_groups ==
                      other.f32_mover_portal_read_groups
               && f32_mover_portal_write_groups ==
                      other.f32_mover_portal_write_groups
               && f32_mover_portal_read_words ==
                      other.f32_mover_portal_read_words
               && f32_mover_portal_write_words ==
                      other.f32_mover_portal_write_words
               && f32_mover_portal_read_bytes ==
                      other.f32_mover_portal_read_bytes
               && f32_mover_portal_write_bytes ==
                      other.f32_mover_portal_write_bytes
               && f32_mover_portal_outstanding ==
                      other.f32_mover_portal_outstanding
#endif
               ;
    }
};

completion_snapshot capture_completion(const VNpcTensorNpuSystemTop & top) {
    completion_snapshot snapshot = {};
    snapshot.terminal_producer_id = top.npu_terminal_producer_id_o;
    snapshot.terminal_error = top.npu_terminal_error_o;
    snapshot.terminal_error_code = top.npu_terminal_error_code_o;
    snapshot.is_macro = top.macro_completion_valid_o;
    snapshot.status = top.macro_completion_status_o;
    snapshot.error_class = top.macro_completion_error_class_o;
    snapshot.kernel_id = top.macro_completion_kernel_id_o;
    snapshot.command_flags = top.macro_completion_command_flags_o;
    snapshot.vector_flags = top.macro_completion_vector_flags_o;
    snapshot.context_id = top.macro_completion_context_id_o;
    snapshot.sequence_id = top.macro_completion_sequence_id_o;
    snapshot.producer_id = top.completion_macro_producer_id_o;
    snapshot.user_tag = top.macro_completion_user_tag_o;
    snapshot.covered_node_count = top.macro_completion_covered_node_count_o;
    snapshot.node_hash_lo = top.macro_completion_node_hash_lo_o;
    snapshot.node_hash_hi = top.macro_completion_node_hash_hi_o;
    snapshot.npu_cycles = top.macro_completion_npu_cycles_o;
    snapshot.gmem_read_bytes = top.macro_completion_gmem_read_bytes_o;
    snapshot.gmem_write_bytes = top.macro_completion_gmem_write_bytes_o;
    snapshot.q8_mac_count = top.macro_completion_q8_mac_count_o;
    snapshot.vector_element_count =
        top.macro_completion_vector_element_count_o;
    snapshot.state_update_count =
        top.macro_completion_state_update_count_o;
#if defined(NPU_SYSTEM_Q8_PORTAL)
    snapshot.q8_portal_request_count = top.q8_portal_request_count_o;
    snapshot.q8_portal_response_count = top.q8_portal_response_count_o;
    snapshot.q8_portal_block_count = top.q8_portal_block_count_o;
    snapshot.q8_portal_byte_count = top.q8_portal_byte_count_o;
    snapshot.q8_portal_outstanding = top.q8_portal_outstanding_o;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    snapshot.f32_alu_portal_request_groups =
        top.f32_alu_portal_request_groups_o;
    snapshot.f32_alu_portal_response_groups =
        top.f32_alu_portal_response_groups_o;
    snapshot.f32_alu_portal_read_groups =
        top.f32_alu_portal_read_groups_o;
    snapshot.f32_alu_portal_write_groups =
        top.f32_alu_portal_write_groups_o;
    snapshot.f32_alu_portal_input_words =
        top.f32_alu_portal_input_words_o;
    snapshot.f32_alu_portal_output_words =
        top.f32_alu_portal_output_words_o;
    snapshot.f32_alu_portal_read_bytes =
        top.f32_alu_portal_read_bytes_o;
    snapshot.f32_alu_portal_write_bytes =
        top.f32_alu_portal_write_bytes_o;
    snapshot.f32_alu_portal_outstanding =
        top.f32_alu_portal_outstanding_o;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    snapshot.f32_mover_portal_request_groups =
        top.f32_mover_portal_request_groups_o;
    snapshot.f32_mover_portal_response_groups =
        top.f32_mover_portal_response_groups_o;
    snapshot.f32_mover_portal_read_groups =
        top.f32_mover_portal_read_groups_o;
    snapshot.f32_mover_portal_write_groups =
        top.f32_mover_portal_write_groups_o;
    snapshot.f32_mover_portal_read_words =
        top.f32_mover_portal_read_words_o;
    snapshot.f32_mover_portal_write_words =
        top.f32_mover_portal_write_words_o;
    snapshot.f32_mover_portal_read_bytes =
        top.f32_mover_portal_read_bytes_o;
    snapshot.f32_mover_portal_write_bytes =
        top.f32_mover_portal_write_bytes_o;
    snapshot.f32_mover_portal_outstanding =
        top.f32_mover_portal_outstanding_o;
#endif
    return snapshot;
}

#if defined(NPU_SYSTEM_Q8_PORTAL) || \
    defined(NPU_SYSTEM_F32_ALU_PORTAL) || \
    defined(NPU_SYSTEM_F32_MOVER_PORTAL)
template <typename Wide>
std::uint64_t portal_load_lane_address(
        const Wide & words,
        std::size_t lane) {
    const std::size_t low_word = lane * 2U;
    return static_cast<std::uint64_t>(words[low_word]) |
           (static_cast<std::uint64_t>(words[low_word + 1U]) << 32U);
}
#endif

template <std::size_t N>
void store_le32(
        std::array<std::uint8_t, N> * bytes,
        std::size_t offset,
        std::uint32_t value) {
    for (std::size_t index = 0; index < 4; ++index) {
        (*bytes)[offset + index] =
            static_cast<std::uint8_t>(value >> (8 * index));
    }
}

template <std::size_t N>
void store_le64(
        std::array<std::uint8_t, N> * bytes,
        std::size_t offset,
        std::uint64_t value) {
    for (std::size_t index = 0; index < 8; ++index) {
        (*bytes)[offset + index] =
            static_cast<std::uint8_t>(value >> (8 * index));
    }
}

template <std::size_t N>
std::uint32_t load_le32(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    std::uint32_t value = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        value |= static_cast<std::uint32_t>(bytes[offset + index]) <<
                 (8 * index);
    }
    return value;
}

template <std::size_t N>
std::uint64_t load_le64(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        value |= static_cast<std::uint64_t>(bytes[offset + index]) <<
                 (8 * index);
    }
    return value;
}

bool completion_frame_valid(const completion_snapshot & snapshot) {
    std::array<std::uint8_t, 128> record = {};
    store_le32(&record, 0x00, 0x514e5043U);
    record[0x04] = 1;
    record[0x08] = 128;
    store_le32(&record, 0x0c, snapshot.status);
    store_le32(&record, 0x10, snapshot.error_class);
    store_le32(&record, 0x14, snapshot.kernel_id);
    store_le32(&record, 0x18, snapshot.command_flags);
    store_le32(&record, 0x1c, snapshot.context_id);
    store_le64(&record, 0x20, snapshot.sequence_id);
    store_le64(&record, 0x28, snapshot.producer_id);
    store_le64(&record, 0x30, snapshot.user_tag);
    store_le32(&record, 0x38, snapshot.covered_node_count);
    store_le64(&record, 0x40, snapshot.node_hash_lo);
    store_le64(&record, 0x48, snapshot.node_hash_hi);
    store_le64(&record, 0x50, snapshot.npu_cycles);
    store_le64(&record, 0x58, snapshot.gmem_read_bytes);
    store_le64(&record, 0x60, snapshot.gmem_write_bytes);
    store_le64(&record, 0x68, snapshot.q8_mac_count);
    store_le64(&record, 0x70, snapshot.vector_element_count);
    store_le64(&record, 0x78, snapshot.state_update_count);
    return load_le32(record, 0x00) == 0x514e5043U &&
           record[0x04] == 1U && record[0x05] == 0U &&
           record[0x06] == 0U && record[0x07] == 0U &&
           record[0x08] == 128U && record[0x09] == 0U &&
           record[0x0a] == 0U && record[0x0b] == 0U &&
           load_le32(record, 0x0c) == snapshot.status &&
           load_le32(record, 0x10) == snapshot.error_class &&
           load_le32(record, 0x14) == snapshot.kernel_id &&
           load_le32(record, 0x18) == snapshot.command_flags &&
           load_le32(record, 0x1c) == snapshot.context_id &&
           load_le64(record, 0x20) == snapshot.sequence_id &&
           load_le64(record, 0x28) == snapshot.producer_id &&
           load_le64(record, 0x30) == snapshot.user_tag &&
           load_le32(record, 0x38) == snapshot.covered_node_count &&
           load_le32(record, 0x3c) == 0U &&
           load_le64(record, 0x40) == snapshot.node_hash_lo &&
           load_le64(record, 0x48) == snapshot.node_hash_hi &&
           load_le64(record, 0x50) == snapshot.npu_cycles &&
           load_le64(record, 0x58) == snapshot.gmem_read_bytes &&
           load_le64(record, 0x60) == snapshot.gmem_write_bytes &&
           load_le64(record, 0x68) == snapshot.q8_mac_count &&
           load_le64(record, 0x70) == snapshot.vector_element_count &&
           load_le64(record, 0x78) == snapshot.state_update_count;
}

bool identity_equal(
        const npu_macro_identity & lhs,
        const npu_macro_identity & rhs) {
    return lhs.profile_id == rhs.profile_id &&
           lhs.command_flags == rhs.command_flags &&
           lhs.context_id == rhs.context_id &&
           lhs.sequence_id == rhs.sequence_id &&
           lhs.producer_id == rhs.producer_id &&
           lhs.user_tag == rhs.user_tag &&
           lhs.node_hash_lo == rhs.node_hash_lo &&
           lhs.node_hash_hi == rhs.node_hash_hi;
}

bool functional_command_result_inactive(
        const npu_system_functional_command_result & result) {
    return !result.enabled && result.dispatches == 0U &&
           result.completions == 0U && result.successes == 0U &&
           result.failures == 0U && result.read_words == 0U &&
           result.write_words == 0U && result.read_bytes == 0U &&
           result.write_bytes == 0U && result.q8_blocks == 0U &&
           result.q8_mac_count == 0U && result.vector_elements == 0U &&
           result.expected_read_words == 0U &&
           result.expected_write_words == 0U &&
           result.expected_read_bytes == 0U &&
           result.expected_write_bytes == 0U &&
           result.expected_q8_blocks == 0U &&
           result.expected_q8_mac_count == 0U &&
           result.expected_vector_elements == 0U &&
           result.callback_read_calls == 0U &&
           result.callback_write_calls == 0U &&
           result.callback_read_bytes == 0U &&
           result.callback_write_bytes == 0U &&
           result.callback_errors == 0U &&
           result.command_mismatches == 0U &&
           result.protocol_errors == 0U &&
           result.old_gmem_requests == 0U &&
           result.old_gmem_responses == 0U &&
           result.old_q8_portal_transactions == 0U &&
           result.old_f32_alu_portal_transactions == 0U &&
           result.old_f32_mover_portal_transactions == 0U;
}

struct raw_window {
    std::uint64_t region_base = 0;
    const std::uint8_t * read_bytes = nullptr;
    std::uint8_t * write_bytes = nullptr;
    std::size_t allocation_bytes = 0;
    std::uint64_t window_base = 0;
    std::uint64_t window_bytes = 0;
    bool readable = false;
    bool writable = false;
};

bool beat_in_window(
        std::uint64_t address,
        const raw_window & window) {
    return window.window_bytes >= 8 &&
           address >= window.window_base &&
           address - window.window_base <= window.window_bytes - 8;
}

std::uint64_t load_raw_beat(
        std::uint64_t address,
        const raw_window & window) {
    std::uint64_t value = 0;
    for (std::size_t lane = 0; lane < 8; ++lane) {
        const std::uint64_t physical = address + lane;
        if (physical >= window.region_base &&
            physical - window.region_base < window.allocation_bytes) {
            const std::size_t offset = static_cast<std::size_t>(
                physical - window.region_base);
            value |= static_cast<std::uint64_t>(window.read_bytes[offset]) <<
                     (8 * lane);
        }
    }
    return value;
}

bool raw_word_in_window(
        std::uint64_t address,
        const raw_window & window,
        bool require_read,
        bool require_write) {
    std::uint64_t address_end = 0;
    std::uint64_t window_end = 0;
    return (address & 3U) == 0U &&
           (!require_read ||
            (window.readable && window.read_bytes != nullptr)) &&
           (!require_write ||
            (window.writable && window.write_bytes != nullptr)) &&
           checked_add(address, 4U, &address_end) &&
           checked_add(window.window_base, window.window_bytes,
                       &window_end) &&
           address >= window.window_base && address_end <= window_end &&
           address >= window.region_base &&
           address - window.region_base <= window.allocation_bytes &&
           4U <= window.allocation_bytes -
               static_cast<std::size_t>(address - window.region_base);
}

std::uint32_t load_raw_word(
        std::uint64_t address,
        const raw_window & window) {
    std::uint32_t value = 0;
    const std::size_t offset = static_cast<std::size_t>(
        address - window.region_base);
    std::memcpy(&value, window.read_bytes + offset, sizeof(value));
    return value;
}

class dpi_scope_guard {
public:
    explicit dpi_scope_guard(npu_exact_dpi_context * context) {
        if (context == nullptr || g_npu_exact_dpi_context != nullptr) {
            throw std::runtime_error("nested exact SystemTop DPI context");
        }
        g_npu_exact_dpi_context = context;
    }

    ~dpi_scope_guard() {
        g_npu_exact_dpi_context = nullptr;
    }

    dpi_scope_guard(const dpi_scope_guard &) = delete;
    dpi_scope_guard & operator=(const dpi_scope_guard &) = delete;
};

std::uint32_t encode_ld(
        unsigned destination,
        unsigned base,
        unsigned immediate) {
    return ((immediate & 0xfffU) << 20U) | (base << 15U) |
           (3U << 12U) | (destination << 7U) | 3U;
}

std::uint32_t encode_config(unsigned index, unsigned source) {
    return (5U << 25U) | (index << 20U) | (source << 15U) |
           (4U << 12U) | (31U << 7U) | 0x5bU;
}

class exact_harness final :
        public npu_exact_dpi_context
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        ,
        public npu_functional_command_capability_context {
#else
        {
#endif
public:
    exact_harness(
            const npu_exact_profile & profile,
            const npu_macro_identity & identity,
            const std::array<npu_exact_raw_allocation, 3> & sources,
            npu_exact_private_destination * dst,
            npu_verilator_exact_result * result)
        : profile_(profile),
          identity_(identity),
          sources_(sources),
          dst_(dst),
          result_(result),
          dpi_guard_(this),
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
          functional_scope_(this),
#endif
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VNpcTensorNpuSystemTop>(context_.get())) {
        expected_required_issued_ = 1;
        expected_required_completed_ = 1;
        expected_public_completions_ = 1;
        expected_macro_completions_ = 1;
        inputs_valid_ = prepare_windows() && prepare_write_coverage();
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        inputs_valid_ = functional_scope_.active() && inputs_valid_ &&
                        prepare_functional_command_contract();
#endif
        inputs_valid_ = inputs_valid_ && prepare_cpu_program();
        drive_idle_inputs();
        top_->eval();
    }

    exact_harness(
            const npu_system_transaction & transaction,
            npu_verilator_exact_result * result)
        : identity_(transaction.identity),
          dst_(nullptr),
          result_(result),
          dpi_guard_(this),
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
          functional_scope_(this),
#endif
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VNpcTensorNpuSystemTop>(context_.get())) {
        inputs_valid_ = prepare_materialized_transaction(transaction);
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        inputs_valid_ = functional_scope_.active() && inputs_valid_;
#endif
        inputs_valid_ = inputs_valid_ && prepare_cpu_program();
        drive_idle_inputs();
        top_->eval();
    }

    ~exact_harness() {
        top_->final();
    }

    bool run() {
        result_->manifest_profile_id = profile_.manifest_profile_id;
        result_->submitted_local_profile = profile_.public_local_profile;
        result_->submitted_identity = identity_;
        result_->cycle_upper_bound = profile_.cycle_upper_bound;
        if (!inputs_valid_) {
            return fail(input_error_code_);
        }
        if (!reset()) {
            return false;
        }
        snapshot_counter_baseline();
        while (!completion_snapshot_seen_) {
            if (!tick()) {
                return false;
            }
        }
        if (response_.occupied) {
            return fail(exact_runner_response_protocol);
        }
#if defined(NPU_SYSTEM_Q8_PORTAL)
        if (portal_response_.occupied) {
            return portal_fail(exact_runner_q8_portal_response);
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        if (f32_alu_portal_response_.occupied) {
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_response);
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        if (f32_mover_portal_response_.occupied) {
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_response);
        }
#endif

        const completion_snapshot snapshot = accepted_snapshot_;
        result_->completion_emitted = true;
        result_->observed_local_profile = snapshot.vector_flags;
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
        result_->completion_identity_match = identity_matches(snapshot);
        if (!result_->completion_identity_match ||
            !identity_equal(result_->submitted_identity,
                            result_->returned_identity)) {
            return fail(exact_runner_completion_identity);
        }
        result_->completion_framing_valid = completion_frame_valid(snapshot);
        if (!result_->completion_framing_valid) {
            return fail(exact_runner_completion_framing);
        }
        if (!recover_after_accepted_completion()) {
            return fail(exact_runner_recovery);
        }
        // Backend-visible counters and completion acceptance are published
        // only after the real SystemTop CPU terminal handshake.
        snapshot_result(snapshot);
        if (!first_request_hold_matches()) {
            return fail(exact_runner_first_request_hold);
        }
#if defined(NPU_SYSTEM_Q8_PORTAL)
        if (!q8_portal_matches(snapshot)) {
            return portal_fail(exact_runner_q8_portal_counter);
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        if (!f32_alu_portal_matches(snapshot)) {
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_counter);
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        if (!f32_mover_portal_matches(snapshot)) {
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_counter);
        }
#endif
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        if (!functional_command_ledger_matches(snapshot)) {
            ++functional_protocol_errors_;
            return fail(exact_runner_functional_ledger);
        }
#else
        if (!functional_command_result_inactive(result_->functional_command)) {
            return fail(exact_runner_functional_ledger);
        }
#endif
        if (!validate_terminal(snapshot)) {
            std::fprintf(
                stderr,
                "[NPU-EXACT-TERMINAL][FAIL] kernel=0x%08x outer=%u "
                "terminal=%u status=%u class=%u code=%u "
                "commands=%llu/%llu/%llu expected_macro=%llu "
                "public=%llu/%llu/%llu expected=%llu/%llu "
                "required=%llu/%llu expected=%llu/%llu f32=%llu/%llu "
                "cpu=%llu/%llu/%llu commits=%llu/%llu "
                "requests=%llu/%llu expected=%llu+%llu "
                "read=%llu/%llu write=%llu/%llu macs=%llu/%llu "
                "elements=%llu/%llu cycles=%llu/%llu written=%llu/%llu "
                "hold=%u memory=%u terminal_identity=%u system=%u\n",
                command_.kernel_id, command_.outer_count,
                snapshot.terminal_error, snapshot.status,
                snapshot.error_class, snapshot.terminal_error_code,
                static_cast<unsigned long long>(result_->commands_accepted),
                static_cast<unsigned long long>(
                    result_->commands_terminal_success),
                static_cast<unsigned long long>(
                    result_->commands_terminal_failure),
                static_cast<unsigned long long>(
                    expected_macro_completions_),
                static_cast<unsigned long long>(
                    result_->public_commands_accepted),
                static_cast<unsigned long long>(result_->public_completions),
                static_cast<unsigned long long>(result_->public_errors),
                static_cast<unsigned long long>(
                    expected_public_completions_),
                static_cast<unsigned long long>(expected_public_errors_),
                static_cast<unsigned long long>(
                    result_->required_issued_delta),
                static_cast<unsigned long long>(
                    result_->required_completed_delta),
                static_cast<unsigned long long>(expected_required_issued_),
                static_cast<unsigned long long>(expected_required_completed_),
                static_cast<unsigned long long>(result_->f32_start_count),
                static_cast<unsigned long long>(expected_f32_starts_),
                static_cast<unsigned long long>(
                    result_->cpu_config_commands_accepted),
                static_cast<unsigned long long>(
                    result_->cpu_tensor_commands_accepted),
                static_cast<unsigned long long>(
                    result_->cpu_terminals_accepted),
                static_cast<unsigned long long>(result_->cpu_config_commits),
                static_cast<unsigned long long>(result_->cpu_launch_commits),
                static_cast<unsigned long long>(
                    result_->gmem_requests_accepted),
                static_cast<unsigned long long>(
                    result_->gmem_responses_accepted),
                static_cast<unsigned long long>(
                    profile_.expected_read_requests),
                static_cast<unsigned long long>(
                    profile_.expected_write_requests),
                static_cast<unsigned long long>(snapshot.gmem_read_bytes),
                static_cast<unsigned long long>(
                    profile_.expected_read_bytes),
                static_cast<unsigned long long>(snapshot.gmem_write_bytes),
                static_cast<unsigned long long>(
                    profile_.expected_write_bytes),
                static_cast<unsigned long long>(snapshot.q8_mac_count),
                static_cast<unsigned long long>(profile_.expected_q8_macs),
                static_cast<unsigned long long>(
                    snapshot.vector_element_count),
                static_cast<unsigned long long>(profile_.expected_elements),
                static_cast<unsigned long long>(snapshot.npu_cycles),
                static_cast<unsigned long long>(profile_.cycle_upper_bound),
                static_cast<unsigned long long>(written_bytes_),
                static_cast<unsigned long long>(
                    expected_semantic_written_bytes_),
                request_hold_observed_ ? 1U : 0U,
                result_->cpu_memory_separate ? 1U : 0U,
                result_->cpu_terminal_identity_match ? 1U : 0U,
                result_->system_transport ? 1U : 0U);
            return fail(exact_runner_terminal_mismatch);
        }
        if (snapshot.terminal_error != 0 || snapshot.status != 0 ||
            snapshot.error_class != 0) {
            if (expected_success_) {
                return fail(exact_runner_terminal_mismatch);
            }
            result_->controlled_reject = true;
            result_->result_bytes = 0;
            result_->private_shadow_committed = false;
            result_->passed = true;
            result_->runner_error_code = exact_runner_ok;
            return true;
        }
        if (!expected_success_) {
            return fail(exact_runner_terminal_mismatch);
        }
        for (std::size_t index = 0; index < expected_write_.size(); ++index) {
            if (write_seen_[index] != expected_write_[index]) {
                return fail(exact_runner_result_coverage);
            }
        }
        result_->result_bytes = written_bytes_;
        result_->private_shadow_committed = true;
        result_->passed = true;
        result_->runner_error_code = exact_runner_ok;
        return true;
    }

    bool cpu_read(
            std::uint64_t address,
            std::uint32_t bytes,
            std::uint64_t * value) override {
        if (value == nullptr || bytes == 0 || bytes > 8 ||
            address < kCpuBase) {
            cpu_memory_error_ = true;
            return false;
        }
        const std::uint64_t offset = address - kCpuBase;
        if (offset > cpu_memory_.size() ||
            bytes > cpu_memory_.size() - offset) {
            cpu_memory_error_ = true;
            return false;
        }
        *value = 0;
        for (std::uint32_t index = 0; index < bytes; ++index) {
            *value |= static_cast<std::uint64_t>(
                          cpu_memory_[static_cast<std::size_t>(offset) +
                                      index]) <<
                      (8U * index);
        }
        return true;
    }

    bool cpu_write(
            std::uint64_t address,
            std::uint64_t value,
            std::uint64_t mask) override {
        if (address < kCpuBase) {
            cpu_memory_error_ = true;
            return false;
        }
        const std::uint64_t offset = address - kCpuBase;
        for (unsigned lane = 0; lane < 8; ++lane) {
            if (((mask >> lane) & 1U) == 0) {
                continue;
            }
            if (offset > cpu_memory_.size() ||
                lane >= cpu_memory_.size() - offset) {
                cpu_memory_error_ = true;
                return false;
            }
            cpu_memory_[static_cast<std::size_t>(offset) + lane] =
                static_cast<std::uint8_t>(value >> (8U * lane));
            cpu_write_observed_ = true;
        }
        return true;
    }

#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    bool checked_read(
            std::uint64_t address,
            void * destination,
            std::size_t bytes) override {
        if (destination == nullptr || bytes == 0U) {
            return false;
        }
        const raw_window * selected = nullptr;
        if (raw_range_in_window(address, bytes, src0_, true, false)) {
            selected = &src0_;
        } else if (raw_range_in_window(
                       address, bytes, src1_, true, false)) {
            selected = &src1_;
        } else if (raw_range_in_window(
                       address, bytes, dst_window_, true, false)) {
            selected = &dst_window_;
        }
        if (selected == nullptr) {
            return false;
        }
        const std::size_t offset = static_cast<std::size_t>(
            address - selected->region_base);
        std::memcpy(destination, selected->read_bytes + offset, bytes);
        return true;
    }

    bool checked_write(
            std::uint64_t address,
            const void * source,
            std::size_t bytes) override {
        if (source == nullptr || bytes == 0U ||
            !raw_range_in_window(
                address, bytes, dst_window_, false, true)) {
            return false;
        }
        const std::size_t offset = static_cast<std::size_t>(
            address - dst_window_.region_base);
        if (offset > expected_write_.size() ||
            bytes > expected_write_.size() - offset) {
            return false;
        }
        for (std::size_t byte = 0; byte < bytes; ++byte) {
            if (expected_write_[offset + byte] != 1U ||
                write_seen_[offset + byte] != 0U) {
                return false;
            }
        }
        std::memcpy(dst_window_.write_bytes + offset, source, bytes);
        for (std::size_t byte = 0; byte < bytes; ++byte) {
            write_seen_[offset + byte] = 1U;
        }
        written_bytes_ += bytes;
        return true;
    }

    void command_completed(
            const npu_functional_command & command,
            const npu_functional_command_result & command_result) override {
        ++functional_dispatches_;
        ++functional_completions_;
        if (functional_result_seen_) {
            ++functional_command_mismatches_;
            return;
        }
        functional_result_seen_ = true;
        functional_actual_ = command_result;
        if (!functional_command_matches(command)) {
            ++functional_command_mismatches_;
        }
    }
#endif

    void cpu_commit(
            std::uint64_t,
            std::uint32_t) override {
        ++cpu_commit_callbacks_;
    }

    void cpu_trap(
            std::uint32_t,
            std::uint64_t) override {
        cpu_trap_observed_ = true;
    }

    std::uint64_t cpu_cycles() const override {
        return cpu_cycle_counter_;
    }

    std::uint64_t cpu_commits() const override {
        return cpu_commit_callbacks_;
    }

private:
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    static bool raw_range_in_window(
            std::uint64_t address,
            std::size_t bytes,
            const raw_window & window,
            bool require_read,
            bool require_write) {
        std::uint64_t end = 0;
        std::uint64_t window_end = 0;
        return bytes != 0U &&
               (!require_read ||
                (window.readable && window.read_bytes != nullptr)) &&
               (!require_write ||
                (window.writable && window.write_bytes != nullptr)) &&
               checked_add(address, bytes, &end) &&
               checked_add(window.window_base, window.window_bytes,
                           &window_end) &&
               address >= window.window_base && end <= window_end &&
               address >= window.region_base &&
               address - window.region_base <= window.allocation_bytes &&
               bytes <= window.allocation_bytes -
                   static_cast<std::size_t>(address - window.region_base);
    }

    bool functional_command_matches(
            const npu_functional_command & observed) const {
        return observed.abi_valid == (command_.abi_valid != 0U) &&
               observed.windows_generation_valid ==
                   (command_.windows_generation_valid != 0U) &&
               observed.kernel_id == command_.kernel_id &&
               observed.command_flags == command_.command_flags &&
               observed.vector_op == command_.vector_op &&
               observed.vector_flags == command_.local_profile &&
               observed.context_id == command_.context_id &&
               observed.capability_epoch == command_.capability_epoch &&
               observed.node_count == command_.node_count &&
               observed.sequence_id == command_.sequence_id &&
               observed.producer_id == command_.producer_id &&
               observed.user_tag == command_.user_tag &&
               observed.node_hash_lo == command_.node_hash_lo &&
               observed.node_hash_hi == command_.node_hash_hi &&
               observed.deadline_cycles == command_.deadline_cycles &&
               observed.src0_iova == command_.src0_iova &&
               observed.src1_iova == command_.src1_iova &&
               observed.src2_iova == command_.src2_iova &&
               observed.dst_iova == command_.dst_iova &&
               observed.scratch_iova == command_.scratch_iova &&
               observed.element_count == command_.element_count &&
               observed.outer_count == command_.outer_count &&
               observed.dtype == command_.dtype &&
               observed.src0_stride == command_.src0_stride &&
               observed.src1_stride == command_.src1_stride &&
               observed.src2_stride == command_.src2_stride &&
               observed.dst_stride == command_.dst_stride &&
               observed.scalar0 == command_.scalar0 &&
               observed.scalar1 == command_.scalar1 &&
               command_.scratch_bytes <=
                   std::numeric_limits<std::uint32_t>::max() &&
               observed.scratch_bytes == command_.scratch_bytes &&
               observed.rope_position == command_.rope_position &&
               observed.src0_window_base == command_.src0_window_base &&
               observed.src0_window_size == command_.src0_window_size &&
               observed.src0_window_perm == command_.src0_window_perm &&
               observed.src1_window_base == command_.src1_window_base &&
               observed.src1_window_size == command_.src1_window_size &&
               observed.src1_window_perm == command_.src1_window_perm &&
               observed.dst_window_base == command_.dst_window_base &&
               observed.dst_window_size == command_.dst_window_size &&
               observed.dst_window_perm == command_.dst_window_perm;
    }
#endif

    struct response_slot {
        bool occupied = false;
        bool active = false;
        bool write = false;
        std::uint64_t address = 0;
        std::uint64_t data = 0;
        std::uint8_t wstrb = 0;
        std::uint64_t due_cycle = 0;
    };

#if defined(NPU_SYSTEM_Q8_PORTAL)
    struct portal_response_slot {
        bool occupied = false;
        bool active = false;
        std::uint32_t mask = 0;
        std::array<std::uint32_t, kQ8PortalResponseWords> blocks = {};
        std::uint64_t due_cycle = 0;
    };
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    struct f32_alu_portal_response_slot {
        bool occupied = false;
        bool active = false;
        std::uint32_t mask = 0;
        std::array<std::uint32_t, kF32AluPortalLanes> src0 = {};
        std::array<std::uint32_t, kF32AluPortalLanes> src1 = {};
        std::uint64_t due_cycle = 0;
    };
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    struct f32_mover_portal_response_slot {
        bool occupied = false;
        bool active = false;
        std::uint32_t mask = 0;
        std::array<std::uint32_t, kF32MoverPortalLanes> data = {};
        std::uint64_t due_cycle = 0;
    };

    enum class mover_portal_phase : std::uint32_t {
        index_read = 0,
        source_read = 1,
        destination_write = 2,
        done = 3,
    };
#endif

#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    bool prepare_functional_command_contract() {
        if (functional_contract_prepared_) {
            return true;
        }
        functional_contract_prepared_ = true;
        npu_functional_command_result expected = {};
        if (!derive_functional_command_ledger(command_, &expected)) {
            functional_command_enabled_ = false;
            return true;
        }
        functional_command_enabled_ = true;
        functional_expected_ = expected;
        result_->functional_command.enabled = true;

        // A command-DPI transaction owns all tensor payload.  Old GMEM and
        // all three raw portal transports are required to remain quiescent;
        // completion byte counters carry the semantic callback ledger.
        portal_contract_ = {};
        f32_alu_portal_contract_ = {};
        f32_mover_portal_contract_ = {};
        reject_contract_.f32_alu_portal = {};
        reject_contract_.f32_mover_portal = {};
        profile_.expected_read_bytes = expected.read_bytes;
        profile_.expected_write_bytes = expected.write_bytes;
        profile_.expected_elements = expected.vector_elements;
        profile_.expected_q8_macs = expected.q8_mac_count;
        profile_.expected_read_requests = 0U;
        profile_.expected_write_requests = 0U;
        // The fast command child replaces the legacy physical owner start
        // pulse.  Its work is proved by the child dispatch/completion pair
        // and the semantic command ledger, so the old owner counter must be
        // quiescent just like GMEM and the raw portals.
        expected_f32_starts_ = 0U;
        validate_f32_starts_ = true;
        require_unique_read_beats_ = false;
        require_f32_halfbeat_wstrb_ = false;
        validate_source_read_requests_ = false;
        expected_source_read_requests_ = {};
        if (expected.write_bytes != expected_semantic_written_bytes_) {
            input_error_code_ = exact_runner_functional_contract;
            return false;
        }

        // GET_ROWS controlled OOB is the only phase-1 data-dependent reject.
        // The numerical child reports the complete index-vector semantic
        // ledger while callback evidence separately records how many indices
        // were consumed before the first invalid value.
        if (reject_contract_.enabled &&
            (command_.kernel_id == kFunctionalQ8GetRowsKernel ||
             command_.kernel_id == kFunctionalF32GetRowsKernel)) {
            reject_contract_.expected_read_bytes =
                static_cast<std::uint64_t>(command_.outer_count) * 4U;
            reject_contract_.expected_write_bytes = 0U;
            reject_contract_.expected_vector_elements = 0U;
            reject_contract_.expected_q8_macs = 0U;
            reject_contract_.expected_state_updates = 0U;
            reject_contract_.expected_read_requests = 0U;
            reject_contract_.expected_write_requests = 0U;
            reject_contract_.validate_source_read_requests = false;
            reject_contract_.expected_source_read_requests = {};
        }
        return true;
    }
#endif

    bool prepare_materialized_transaction(
            const npu_system_transaction & transaction) {
        command_ = transaction.command;
        profile_.manifest_profile_id = transaction.manifest_profile_id;
        profile_.public_kernel_id = command_.kernel_id;
        profile_.public_vector_op = command_.vector_op;
        profile_.public_local_profile = command_.local_profile;
        profile_.expected_read_bytes = transaction.expected_read_bytes;
        profile_.expected_write_bytes = transaction.expected_write_bytes;
        profile_.expected_elements =
            transaction.expected_vector_elements;
        profile_.expected_q8_macs = transaction.expected_q8_macs;
        profile_.expected_state_updates =
            transaction.expected_state_updates;
        profile_.expected_read_requests =
            transaction.expected_read_requests;
        profile_.expected_write_requests =
            transaction.expected_write_requests;
        profile_.cycle_upper_bound = transaction.cycle_upper_bound;
        expected_success_ = transaction.expect_success;
        expected_status_ = transaction.expected_status;
        expected_error_class_ = transaction.expected_error_class;
        expected_error_code_ = transaction.expected_error_code;
        expected_f32_starts_ = transaction.expected_f32_starts;
        validate_f32_starts_ = true;
        expected_required_issued_ =
            transaction.expected_required_issued;
        expected_required_completed_ =
            transaction.expected_required_completed;
        expected_public_completions_ =
            transaction.expected_public_completions;
        expected_public_errors_ = transaction.expected_public_errors;
        expected_macro_completions_ =
            transaction.expected_macro_completions;
        require_unique_read_beats_ =
            transaction.require_unique_read_beats;
        require_f32_halfbeat_wstrb_ =
            transaction.require_f32_halfbeat_wstrb;
        validate_source_read_requests_ =
            transaction.validate_source_read_requests;
        expected_source_read_requests_ =
            transaction.expected_source_read_requests;
        portal_contract_ = transaction.q8_portal;
        f32_alu_portal_contract_ = transaction.f32_alu_portal;
        f32_mover_portal_contract_ = transaction.f32_mover_portal;
        reject_contract_ = transaction.controlled_reject;

        if (result_ == nullptr || profile_.cycle_upper_bound == 0 ||
            command_.abi_valid != 1U ||
            command_.windows_generation_valid != 1U ||
            command_.capability_epoch != kCapabilityEpoch ||
            command_.node_count == 0 ||
            identity_.profile_id != command_.local_profile ||
            identity_.command_flags != command_.command_flags ||
            identity_.context_id != command_.context_id ||
            identity_.sequence_id != command_.sequence_id ||
            identity_.producer_id != command_.producer_id ||
            identity_.user_tag != command_.user_tag ||
            identity_.node_hash_lo != command_.node_hash_lo ||
            identity_.node_hash_hi != command_.node_hash_hi ||
            transaction.expected_write_mask_bytes !=
                transaction.destination.allocation_bytes ||
            (transaction.expected_write_mask_bytes != 0 &&
             transaction.expected_write_mask == nullptr)) {
            return false;
        }

        const auto valid_window = [](
                const npu_system_raw_window & window,
                std::uint64_t command_base,
                std::uint64_t command_size,
                std::uint32_t command_permission,
                bool destination) {
            if (window.window_base != command_base ||
                window.window_bytes != command_size ||
                (window.window_base & 7U) != 0U ||
                (window.window_bytes & 7U) != 0U ||
                command_permission > 3U) {
                return false;
            }
            if (window.readable && window.allocation_bytes != 0 &&
                window.read_bytes == nullptr) {
                return false;
            }
            if (window.writable && window.allocation_bytes != 0 &&
                window.write_bytes == nullptr) {
                return false;
            }
            if (destination) {
                return command_permission == 2U && window.writable;
            }
            if (command_permission == 0U) {
                return window.window_bytes == 0U &&
                       window.allocation_bytes == 0U &&
                       !window.readable && !window.writable;
            }
            return command_permission == 1U && window.readable &&
                   !window.writable;
        };
        if (command_.src0_window_perm != 1U ||
            command_.src1_window_perm > 1U ||
            !valid_window(
                transaction.sources[0], command_.src0_window_base,
                command_.src0_window_size, command_.src0_window_perm,
                false) ||
            !valid_window(
                transaction.sources[1], command_.src1_window_base,
                command_.src1_window_size, command_.src1_window_perm,
                false) ||
            !valid_window(
                transaction.destination, command_.dst_window_base,
                command_.dst_window_size, command_.dst_window_perm,
                true) ||
            transaction.destination.readable !=
                command_.dst_shadow_readable) {
            return false;
        }
        src0_ = {
            transaction.sources[0].region_base,
            transaction.sources[0].read_bytes,
            transaction.sources[0].write_bytes,
            transaction.sources[0].allocation_bytes,
            transaction.sources[0].window_base,
            transaction.sources[0].window_bytes,
            transaction.sources[0].readable,
            transaction.sources[0].writable,
        };
        src1_ = {
            transaction.sources[1].region_base,
            transaction.sources[1].read_bytes,
            transaction.sources[1].write_bytes,
            transaction.sources[1].allocation_bytes,
            transaction.sources[1].window_base,
            transaction.sources[1].window_bytes,
            transaction.sources[1].readable,
            transaction.sources[1].writable,
        };
        dst_window_ = {
            transaction.destination.region_base,
            transaction.destination.read_bytes,
            transaction.destination.write_bytes,
            transaction.destination.allocation_bytes,
            transaction.destination.window_base,
            transaction.destination.window_bytes,
            transaction.destination.readable,
            transaction.destination.writable,
        };
        expected_write_.clear();
        if (transaction.expected_write_mask_bytes != 0) {
            expected_write_.assign(
                transaction.expected_write_mask,
                transaction.expected_write_mask +
                    transaction.expected_write_mask_bytes);
        }
        write_seen_.assign(transaction.expected_write_mask_bytes, 0);
        std::uint64_t expected_written = 0;
        for (std::uint8_t value : expected_write_) {
            if (value > 1U) {
                return false;
            }
            expected_written += value;
        }
        expected_semantic_written_bytes_ =
            transaction.expected_semantic_write_bytes != 0U ?
                transaction.expected_semantic_write_bytes :
                transaction.expected_write_bytes;
        if (expected_written != expected_semantic_written_bytes_) {
            return false;
        }
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        if (!prepare_functional_command_contract()) {
            return false;
        }
#endif
        if (!prepare_q8_portal_contract()) {
            input_error_code_ = exact_runner_q8_portal_contract;
            return false;
        }
        if (!prepare_f32_alu_portal_contract()) {
            input_error_code_ = exact_runner_f32_alu_portal_contract;
            return false;
        }
        if (!prepare_f32_mover_portal_contract()) {
            input_error_code_ = exact_runner_f32_mover_portal_contract;
            return false;
        }
        const unsigned enabled_portals =
            (portal_contract_.enabled ? 1U : 0U) +
            (f32_alu_portal_contract_.enabled ? 1U : 0U) +
            (f32_mover_portal_contract_.enabled ? 1U : 0U);
        if (enabled_portals > 1U) {
            input_error_code_ = exact_runner_profile;
            return false;
        }
        return true;
    }

    bool prepare_q8_portal_contract() {
        const bool zero_contract =
            portal_contract_.row_lanes == 0U &&
            portal_contract_.mac_lanes == 0U &&
            portal_contract_.block_bytes == 0U &&
            portal_contract_.blocks_per_row == 0U &&
            portal_contract_.response_latency_cycles == 0U &&
            portal_contract_.expected_request_groups == 0U &&
            portal_contract_.expected_blocks == 0U &&
            portal_contract_.expected_bytes == 0U;
#if !defined(NPU_SYSTEM_Q8_PORTAL)
        return !portal_contract_.enabled && zero_contract;
#else
        const bool q8_kernel = command_.kernel_id == kQ8PortalKernel;
        if (!portal_contract_.enabled) {
            return zero_contract && (!q8_kernel
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
                   || functional_command_enabled_
#endif
                   );
        }
        const bool empty = command_.outer_count == 0U;
        if (!q8_kernel || command_.vector_op != 0U ||
            command_.local_profile != 0U ||
            command_.dtype != kMacroDtypeF32 ||
            command_.element_count == 0U ||
            (command_.element_count % kQ8PortalMacLanes) != 0U ||
            portal_contract_.row_lanes != kQ8PortalRowLanes ||
            portal_contract_.mac_lanes != kQ8PortalMacLanes ||
            portal_contract_.block_bytes != kQ8PortalBlockBytes ||
            portal_contract_.response_latency_cycles !=
                kQ8PortalResponseLatencyCycles ||
            portal_contract_.blocks_per_row !=
                command_.element_count / kQ8PortalMacLanes ||
            !src1_.readable || src1_.writable ||
            command_.src1_iova != src1_.region_base ||
            command_.src1_window_perm != 1U ||
            !validate_source_read_requests_ ||
            expected_source_read_requests_[1] != 0U) {
            return false;
        }

        std::uint64_t row_bytes = 0;
        std::uint64_t tile_numerator = 0;
        std::uint64_t tiles = 0;
        std::uint64_t expected_groups = 0;
        std::uint64_t expected_blocks = 0;
        std::uint64_t expected_bytes = 0;
        std::uint64_t semantic_bytes = 0;
        std::uint64_t semantic_end = 0;
        std::uint64_t window_end = 0;
        if (!checked_mul(
                portal_contract_.blocks_per_row,
                kQ8PortalBlockBytes, &row_bytes) ||
            command_.src1_stride != row_bytes) {
            return false;
        }
        if (empty) {
            if (src1_.read_bytes != nullptr || src1_.allocation_bytes != 0U ||
                src1_.window_bytes != 0U ||
                command_.src1_window_size != 0U ||
                portal_contract_.expected_request_groups != 0U ||
                portal_contract_.expected_blocks != 0U ||
                portal_contract_.expected_bytes != 0U) {
                return false;
            }
            first_portal_request_hold_pending_ = false;
            result_->q8_portal.transactions = 1U;
            result_->q8_portal.expected_request_groups = 0U;
            result_->q8_portal.expected_blocks = 0U;
            result_->q8_portal.expected_bytes = 0U;
            return true;
        }
        if (src1_.read_bytes == nullptr || src1_.allocation_bytes == 0U ||
            !checked_add(
                command_.outer_count, kQ8PortalRowLanes - 1U,
                &tile_numerator)) {
            return false;
        }
        tiles = tile_numerator / kQ8PortalRowLanes;
        if (!checked_mul(
                tiles, portal_contract_.blocks_per_row,
                &expected_groups) ||
            !checked_mul(
                command_.outer_count, portal_contract_.blocks_per_row,
                &expected_blocks) ||
            !checked_mul(
                expected_blocks, kQ8PortalBlockBytes, &expected_bytes) ||
            !checked_mul(
                command_.outer_count, command_.src1_stride,
                &semantic_bytes) ||
            !checked_add(
                command_.src1_iova, semantic_bytes, &semantic_end) ||
            !checked_add(
                src1_.window_base, src1_.window_bytes, &window_end) ||
            semantic_bytes != src1_.allocation_bytes ||
            semantic_end > window_end ||
            portal_contract_.expected_request_groups != expected_groups ||
            portal_contract_.expected_blocks != expected_blocks ||
            portal_contract_.expected_bytes != expected_bytes) {
            return false;
        }

        first_portal_request_hold_pending_ = true;
        result_->q8_portal.transactions = 1U;
        result_->q8_portal.expected_request_groups = expected_groups;
        result_->q8_portal.expected_blocks = expected_blocks;
        result_->q8_portal.expected_bytes = expected_bytes;
        return true;
#endif
    }

    static bool raw32_contract_is_zero(
            const npu_system_raw32_portal_contract & contract) {
        return contract.lanes == 0U &&
               contract.response_latency_cycles == 0U &&
               contract.expected_request_groups == 0U &&
               contract.expected_response_groups == 0U &&
               contract.expected_read_groups == 0U &&
               contract.expected_write_groups == 0U &&
               contract.expected_read_words == 0U &&
               contract.expected_write_words == 0U &&
               contract.expected_read_bytes == 0U &&
               contract.expected_write_bytes == 0U;
    }

    static bool raw32_contract_has_consistent_totals(
            const npu_system_raw32_portal_contract & contract) {
        std::uint64_t groups = 0;
        std::uint64_t read_bytes = 0;
        std::uint64_t write_bytes = 0;
        return checked_add(
                   contract.expected_read_groups,
                   contract.expected_write_groups, &groups) &&
               checked_mul(
                   contract.expected_read_words, 4U, &read_bytes) &&
               checked_mul(
                   contract.expected_write_words, 4U, &write_bytes) &&
               contract.expected_request_groups == groups &&
               contract.expected_response_groups == groups &&
               contract.expected_read_bytes == read_bytes &&
               contract.expected_write_bytes == write_bytes;
    }

    bool prepare_f32_alu_portal_contract() {
#if !defined(NPU_SYSTEM_F32_ALU_PORTAL)
        return !f32_alu_portal_contract_.enabled &&
               raw32_contract_is_zero(f32_alu_portal_contract_);
#else
        const bool alu_kernel =
            command_.kernel_id == kF32AluPortalKernel;
        if (!f32_alu_portal_contract_.enabled) {
            return raw32_contract_is_zero(f32_alu_portal_contract_) &&
                   (!alu_kernel
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
                    || functional_command_enabled_
#endif
                   );
        }
        npu_f32_alu_profile profile = {};
        if (!alu_kernel ||
            !npu_f32_alu_profile_by_id(command_.local_profile, &profile)) {
            return false;
        }
        const bool zero_cardinality =
            (command_.local_profile == 17U ||
             command_.local_profile == 18U) &&
            profile_.manifest_profile_id == command_.local_profile &&
            command_.element_count == 0U && command_.outer_count == 1U;
        if (zero_cardinality) {
            const bool rooted_zero_windows =
                command_.src0_iova == src0_.region_base &&
                command_.dst_iova == dst_window_.region_base &&
                src0_.region_base != 0U && dst_window_.region_base != 0U &&
                (src0_.region_base & 7U) == 0U &&
                (dst_window_.region_base & 7U) == 0U &&
                src0_.window_base == src0_.region_base &&
                dst_window_.window_base == dst_window_.region_base &&
                src0_.window_bytes == 0U &&
                dst_window_.window_bytes == 0U &&
                src0_.allocation_bytes == 0U &&
                dst_window_.allocation_bytes == 0U &&
                src0_.readable && !src0_.writable &&
                dst_window_.writable && !dst_window_.readable;
            if (command_.vector_op != profile.vector_op ||
                command_.scalar0 != 0U ||
                command_.dtype != kMacroDtypeF32 ||
                command_.src1_iova != 0U ||
                command_.src0_stride != 0U ||
                command_.src1_stride != 0U ||
                command_.dst_stride != 0U ||
                !rooted_zero_windows ||
                src1_.region_base != 0U || src1_.window_base != 0U ||
                src1_.window_bytes != 0U ||
                src1_.allocation_bytes != 0U ||
                src1_.readable || src1_.writable ||
                f32_alu_portal_contract_.lanes != kF32AluPortalLanes ||
                f32_alu_portal_contract_.response_latency_cycles !=
                    kF32AluPortalResponseLatencyCycles ||
                !raw32_contract_has_consistent_totals(
                    f32_alu_portal_contract_) ||
                f32_alu_portal_contract_.expected_request_groups != 0U ||
                f32_alu_portal_contract_.expected_read_groups != 0U ||
                f32_alu_portal_contract_.expected_write_groups != 0U ||
                profile_.expected_elements != 0U ||
                profile_.expected_read_bytes != 0U ||
                profile_.expected_write_bytes != 0U ||
                profile_.expected_read_requests != 0U ||
                profile_.expected_write_requests != 0U ||
                expected_semantic_written_bytes_ != 0U ||
                expected_f32_starts_ != 0U) {
                return false;
            }
            f32_alu_profile_ = profile;
            f32_alu_first_request_hold_pending_ = false;
            result_->f32_alu_portal.transactions = 1U;
            return true;
        }
        if (command_.element_count == 0U ||
            command_.outer_count == 0U ||
            command_.vector_op != profile.vector_op ||
            command_.scalar0 != profile.scalar0 ||
            command_.dtype != kMacroDtypeF32 ||
            command_.element_count != profile.element_count ||
            command_.outer_count != profile.outer_count ||
            command_.src0_iova !=
                src0_.region_base + profile.src0.view_off ||
            command_.src1_iova != (profile.src1_present ?
                src1_.region_base + profile.src1.view_off : 0U) ||
            command_.dst_iova != dst_window_.region_base ||
            command_.src0_stride != profile.src0.nb[1] ||
            command_.src1_stride !=
                (profile.src1_present ? profile.src1.nb[1] : 0U) ||
            command_.dst_stride != profile.dst.nb[1] ||
            f32_alu_portal_contract_.lanes != kF32AluPortalLanes ||
            f32_alu_portal_contract_.response_latency_cycles !=
                kF32AluPortalResponseLatencyCycles ||
            !raw32_contract_has_consistent_totals(
                f32_alu_portal_contract_) ||
            profile.total_elements == 0U ||
            profile.total_elements >
                std::numeric_limits<std::uint64_t>::max() -
                    (kF32AluPortalLanes - 1U) ||
            profile_.expected_read_bytes != 0U ||
            profile_.expected_write_bytes != 0U ||
            profile_.expected_read_requests != 0U ||
            profile_.expected_write_requests != 0U) {
            return false;
        }
        const std::uint64_t groups =
            (profile.total_elements + kF32AluPortalLanes - 1U) /
            kF32AluPortalLanes;
        std::uint64_t request_groups = 0;
        std::uint64_t input_words = 0;
        std::uint64_t output_bytes = 0;
        if (!checked_mul(groups, 2U, &request_groups) ||
            !checked_mul(
                profile.total_elements,
                profile.src1_present ? 2U : 1U, &input_words) ||
            !checked_mul(profile.total_elements, 4U, &output_bytes) ||
            f32_alu_portal_contract_.expected_request_groups !=
                request_groups ||
            f32_alu_portal_contract_.expected_read_groups != groups ||
            f32_alu_portal_contract_.expected_write_groups != groups ||
            f32_alu_portal_contract_.expected_read_words != input_words ||
            f32_alu_portal_contract_.expected_write_words !=
                profile.total_elements ||
            f32_alu_portal_contract_.expected_write_bytes != output_bytes ||
            expected_semantic_written_bytes_ != output_bytes ||
            !src0_.readable || src0_.writable ||
            (profile.src1_present &&
             (!src1_.readable || src1_.writable)) ||
            (!profile.src1_present &&
             (src1_.allocation_bytes != 0U || src1_.window_bytes != 0U)) ||
            !dst_window_.writable || dst_window_.readable) {
            return false;
        }
        f32_alu_profile_ = profile;
        f32_alu_first_request_hold_pending_ = request_groups != 0U;
        result_->f32_alu_portal.transactions = 1U;
        return true;
#endif
    }

    bool prepare_f32_mover_portal_contract() {
#if !defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        return !f32_mover_portal_contract_.enabled &&
               raw32_contract_is_zero(f32_mover_portal_contract_);
#else
        const bool get_rows = command_.kernel_id == kF32MoverGetRowsKernel;
        const bool repeat = command_.kernel_id == kF32MoverRepeatKernel;
        if (!f32_mover_portal_contract_.enabled) {
            return raw32_contract_is_zero(f32_mover_portal_contract_) &&
                   ((!get_rows && !repeat)
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
                    || functional_command_enabled_
#endif
                   );
        }
        if ((!get_rows && !repeat) || command_.local_profile != 0U ||
            command_.vector_op != 0U || command_.dtype != kMacroDtypeF32 ||
            command_.element_count == 0U ||
            f32_mover_portal_contract_.lanes != kF32MoverPortalLanes ||
            f32_mover_portal_contract_.response_latency_cycles !=
                kF32MoverPortalResponseLatencyCycles ||
            !raw32_contract_has_consistent_totals(
                f32_mover_portal_contract_) ||
            profile_.expected_read_bytes != 0U ||
            profile_.expected_write_bytes != 0U ||
            profile_.expected_read_requests != 0U ||
            profile_.expected_write_requests != 0U ||
            !src0_.readable || src0_.writable ||
            !dst_window_.writable || dst_window_.readable) {
            return false;
        }
        const std::uint64_t element_groups =
            (command_.element_count + kF32MoverPortalLanes - 1U) /
            kF32MoverPortalLanes;
        const std::uint64_t index_groups = get_rows ?
            (static_cast<std::uint64_t>(command_.outer_count) +
             kF32MoverPortalLanes - 1U) / kF32MoverPortalLanes : 0U;
        std::uint64_t source_groups = 0;
        std::uint64_t write_groups = 0;
        std::uint64_t read_groups = 0;
        std::uint64_t request_groups = 0;
        std::uint64_t source_words = 0;
        std::uint64_t write_words = 0;
        std::uint64_t read_words = 0;
        const std::uint64_t repeat_count = get_rows ? 1U : command_.scalar0;
        if ((!get_rows && repeat_count == 0U) ||
            !checked_mul(command_.outer_count, element_groups,
                         &source_groups) ||
            !checked_mul(source_groups, repeat_count, &write_groups) ||
            !checked_add(index_groups, source_groups, &read_groups) ||
            !checked_add(read_groups, write_groups, &request_groups) ||
            !checked_mul(command_.outer_count, command_.element_count,
                         &source_words) ||
            !checked_mul(source_words, repeat_count, &write_words) ||
            !checked_add(
                get_rows ? command_.outer_count : 0U,
                source_words, &read_words) ||
            f32_mover_portal_contract_.expected_request_groups !=
                request_groups ||
            f32_mover_portal_contract_.expected_read_groups != read_groups ||
            f32_mover_portal_contract_.expected_write_groups !=
                write_groups ||
            f32_mover_portal_contract_.expected_read_words != read_words ||
            f32_mover_portal_contract_.expected_write_words != write_words ||
            expected_semantic_written_bytes_ !=
                f32_mover_portal_contract_.expected_write_bytes ||
            (get_rows && command_.outer_count != 0U &&
             (!src1_.readable || src1_.writable)) ||
            (repeat && src1_.allocation_bytes != 0U)) {
            return false;
        }
        f32_mover_get_rows_ = get_rows;
        f32_mover_portal_phase_ =
            request_groups == 0U ? mover_portal_phase::done :
            (get_rows ? mover_portal_phase::index_read :
                        mover_portal_phase::source_read);
        f32_mover_first_request_hold_pending_ = request_groups != 0U;
        result_->f32_mover_portal.transactions = 1U;
        return true;
#endif
    }

    bool select_terminal_contract(
            const completion_snapshot & snapshot) {
        if (snapshot.terminal_error == 0) {
            return expected_success_;
        }
        if (!expected_success_) {
            return true;
        }
        if (!reject_contract_.enabled) {
            return false;
        }
        expected_success_ = false;
        profile_.expected_read_bytes =
            reject_contract_.expected_read_bytes;
        profile_.expected_write_bytes =
            reject_contract_.expected_write_bytes;
        profile_.expected_elements =
            reject_contract_.expected_vector_elements;
        profile_.expected_q8_macs = reject_contract_.expected_q8_macs;
        profile_.expected_state_updates =
            reject_contract_.expected_state_updates;
        profile_.expected_read_requests =
            reject_contract_.expected_read_requests;
        profile_.expected_write_requests =
            reject_contract_.expected_write_requests;
        expected_f32_starts_ = reject_contract_.expected_f32_starts;
        expected_required_issued_ =
            reject_contract_.expected_required_issued;
        expected_required_completed_ =
            reject_contract_.expected_required_completed;
        expected_public_completions_ =
            reject_contract_.expected_public_completions;
        expected_public_errors_ =
            reject_contract_.expected_public_errors;
        expected_macro_completions_ =
            reject_contract_.expected_macro_completions;
        expected_status_ = reject_contract_.expected_status;
        expected_error_class_ = reject_contract_.expected_error_class;
        expected_error_code_ = reject_contract_.expected_error_code;
        validate_source_read_requests_ =
            reject_contract_.validate_source_read_requests;
        expected_source_read_requests_ =
            reject_contract_.expected_source_read_requests;
        expected_semantic_written_bytes_ =
            reject_contract_.expected_write_bytes;
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        if (functional_command_enabled_) {
            functional_expected_ = {};
            functional_expected_.read_words =
                reject_contract_.expected_read_bytes / 4U;
            functional_expected_.read_bytes =
                reject_contract_.expected_read_bytes;
            functional_expected_.write_words =
                reject_contract_.expected_write_bytes / 4U;
            functional_expected_.write_bytes =
                reject_contract_.expected_write_bytes;
            functional_expected_.q8_mac_count =
                reject_contract_.expected_q8_macs;
            functional_expected_.vector_elements =
                reject_contract_.expected_vector_elements;
        }
#endif
        if (reject_contract_.f32_alu_portal.enabled) {
            f32_alu_portal_contract_ =
                reject_contract_.f32_alu_portal;
        }
        if (reject_contract_.f32_mover_portal.enabled) {
            f32_mover_portal_contract_ =
                reject_contract_.f32_mover_portal;
        }
        return true;
    }

    bool cpu_region_contains(
            std::uint64_t address,
            std::size_t bytes) const {
        if (address < kCpuBase) {
            return false;
        }
        const std::uint64_t offset = address - kCpuBase;
        return offset <= cpu_memory_.size() &&
               bytes <= cpu_memory_.size() - offset;
    }

    bool put_cpu32(std::uint64_t address, std::uint32_t value) {
        if (!cpu_region_contains(address, sizeof(value))) {
            return false;
        }
        const std::size_t offset =
            static_cast<std::size_t>(address - kCpuBase);
        for (unsigned index = 0; index < 4; ++index) {
            cpu_memory_[offset + index] =
                static_cast<std::uint8_t>(value >> (8U * index));
        }
        return true;
    }

    bool put_cpu64(std::uint64_t address, std::uint64_t value) {
        if (!cpu_region_contains(address, sizeof(value))) {
            return false;
        }
        const std::size_t offset =
            static_cast<std::size_t>(address - kCpuBase);
        for (unsigned index = 0; index < 8; ++index) {
            cpu_memory_[offset + index] =
                static_cast<std::uint8_t>(value >> (8U * index));
        }
        return true;
    }

    bool prepare_cpu_program() {
        if (command_.scratch_bytes >
                std::numeric_limits<std::uint32_t>::max() ||
            command_.src0_window_perm > 3U ||
            command_.src1_window_perm > 3U ||
            command_.dst_window_perm > 3U) {
            return false;
        }
        const std::uint64_t packed_permissions =
            (command_.abi_valid ? 1ULL : 0ULL) |
            (command_.windows_generation_valid ? 2ULL : 0ULL) |
            (static_cast<std::uint64_t>(command_.src0_window_perm) << 2U) |
            (static_cast<std::uint64_t>(command_.src1_window_perm) << 4U) |
            (static_cast<std::uint64_t>(command_.dst_window_perm) << 6U);
        descriptor_words_ = {
            (static_cast<std::uint64_t>(command_.command_flags) << 32U) |
                command_.kernel_id,
            (static_cast<std::uint64_t>(command_.capability_epoch) << 32U) |
                command_.context_id,
            command_.sequence_id,
            command_.producer_id,
            command_.user_tag,
            (static_cast<std::uint64_t>(command_.vector_op) << 32U) |
                command_.node_count,
            command_.node_hash_lo,
            command_.node_hash_hi,
            command_.deadline_cycles,
            (static_cast<std::uint64_t>(command_.outer_count) << 32U) |
                command_.local_profile,
            command_.src0_iova,
            command_.src1_iova,
            command_.src2_iova,
            command_.dst_iova,
            command_.scratch_iova,
            command_.element_count,
            (static_cast<std::uint64_t>(command_.scalar0) << 32U) |
                command_.dtype,
            (command_.scratch_bytes << 32U) | command_.scalar1,
            command_.rope_position,
            command_.src0_stride,
            command_.src1_stride,
            command_.src2_stride,
            command_.dst_stride,
            command_.src0_window_base,
            command_.src0_window_size,
            packed_permissions,
            command_.src1_window_base,
            command_.src1_window_size,
            command_.dst_window_base,
            command_.dst_window_size,
        };
        // The descriptor must preserve the owner contract.  Binary owners use
        // 0x97; legacy unary F32 profiles correctly use 0x87 with an absent
        // src1 aperture.  Admission in the frozen public adapter validates
        // the owner-specific value.
        if ((packed_permissions != 0x97ULL &&
             packed_permissions != 0x87ULL) ||
            command_.src0_window_perm != 1U ||
            command_.dst_window_perm != 2U) {
            return false;
        }

        cpu_memory_.fill(0);
        if (!put_cpu32(kCpuBase, kAddiCpuBase) ||
            !put_cpu32(kCpuBase + 4U, kSlliCpuBase)) {
            return false;
        }
        std::uint64_t pc = kCpuBase + 8U;
        for (unsigned index = 0; index < descriptor_words_.size(); ++index) {
            const unsigned immediate = static_cast<unsigned>(
                kDescriptorAddress - kCpuBase + 8ULL * index);
            if (immediate > 0x7ffU ||
                !put_cpu64(kDescriptorAddress + 8ULL * index,
                           descriptor_words_[index]) ||
                !put_cpu32(pc, encode_ld(2U, 1U, immediate)) ||
                !put_cpu32(pc + 4U, kNop) ||
                !put_cpu32(pc + 8U, encode_config(index, 2U)) ||
                !put_cpu32(pc + 12U, kNop)) {
                return false;
            }
            pc += 16U;
        }
        return pc == kLaunchPc &&
               put_cpu32(pc, kLaunchLo) &&
               put_cpu32(pc + 4U, kLaunchHi) &&
               put_cpu32(pc + 8U, kPark);
    }

    bool prepare_one_window(
            const npu_exact_tensor_descriptor & descriptor,
            std::uint64_t region_base,
            const npu_exact_raw_allocation & allocation,
            std::uint64_t expected_window_base,
            std::uint64_t expected_window_bytes,
            raw_window * window) {
        if (window == nullptr) {
            return false;
        }
        std::uint64_t low = 0;
        std::uint64_t high = 0;
        std::uint64_t count = 0;
        if (!tensor_span(descriptor, &low, &high) ||
            !checked_product(descriptor.ne, &count) ||
            high > allocation.size ||
            (allocation.size != 0 && allocation.bytes == nullptr) ||
            expected_window_base != region_base ||
            (expected_window_bytes & 7U) != 0U ||
            (count != 0 && expected_window_bytes < high)) {
            return false;
        }
        window->region_base = region_base;
        window->read_bytes = allocation.bytes;
        window->allocation_bytes = allocation.size;
        window->window_base = expected_window_base;
        window->window_bytes = expected_window_bytes;
        window->readable = true;
        return true;
    }

    bool load_set_slot(std::uint32_t * slot) const {
        if (slot == nullptr || profile_.owner != npu_exact_owner::set_rows ||
            sources_[1].bytes == nullptr ||
            profile_.sources[1].view_off > sources_[1].size ||
            sources_[1].size - profile_.sources[1].view_off < 8) {
            return false;
        }
        std::uint64_t raw_slot = 0;
        std::memcpy(&raw_slot,
                    sources_[1].bytes + profile_.sources[1].view_off,
                    sizeof(raw_slot));
        if (raw_slot >= 256U) {
            return false;
        }
        *slot = static_cast<std::uint32_t>(raw_slot);
        return true;
    }

    bool prepare_windows() {
        if (dst_ == nullptr || dst_->bytes == nullptr || dst_->size == 0) {
            return false;
        }
        if (profile_.owner == npu_exact_owner::set_rows) {
            if (!load_set_slot(&set_slot_)) {
                return false;
            }
        }
        std::array<std::size_t, 3> source_backing_bytes = {};
        for (std::size_t index = 0; index < sources_.size(); ++index) {
            source_backing_bytes[index] = sources_[index].size;
        }
        if (!npu_exact_build_command_contract(
                &profile_, &identity_, set_slot_, &source_backing_bytes,
                dst_->size, &command_) ||
            !prepare_one_window(
                profile_.sources[0], kSrc0Iova, sources_[0],
                command_.src0_window_base, command_.src0_window_size,
                &src0_) ||
            (profile_.source_count >= 2U &&
             !prepare_one_window(
                 profile_.sources[1], kSrc1Iova, sources_[1],
                 command_.src1_window_base, command_.src1_window_size,
                 &src1_))) {
            return false;
        }
        if (profile_.source_count == 1U) {
            src1_.region_base = 0;
            src1_.window_base = 0;
            src1_.window_bytes = 0;
            src1_.readable = true;
        }
        if ((profile_.owner == npu_exact_owner::cpy &&
             (sources_[1].size != dst_->size ||
              (dst_->size != 0 &&
               (sources_[1].bytes == nullptr ||
                std::memcmp(sources_[1].bytes, dst_->bytes,
                            dst_->size) != 0)))) ||
            (profile_.owner == npu_exact_owner::set_rows &&
             (sources_[2].size != dst_->size ||
              (dst_->size != 0 &&
               (sources_[2].bytes == nullptr ||
                std::memcmp(sources_[2].bytes, dst_->bytes,
                            dst_->size) != 0))))) {
            return false;
        }
        std::uint64_t dst_low = 0;
        std::uint64_t dst_high = 0;
        if (!tensor_span(profile_.dst, &dst_low, &dst_high) ||
            dst_high > dst_->size ||
            command_.dst_window_base != kDstIova ||
            command_.dst_window_size < dst_high) {
            return false;
        }
        dst_window_.region_base = kDstIova;
        dst_window_.read_bytes = dst_->bytes;
        dst_window_.write_bytes = dst_->bytes;
        dst_window_.allocation_bytes = dst_->size;
        dst_window_.window_base = command_.dst_window_base;
        dst_window_.window_bytes = command_.dst_window_size;
        dst_window_.readable = command_.dst_shadow_readable;
        dst_window_.writable = true;
        return profile_.source_count < 3U ||
               profile_.owner == npu_exact_owner::set_rows;
    }

    bool mark_element(std::uint64_t offset, std::uint64_t width) {
        if (offset > expected_write_.size() ||
            width > expected_write_.size() - offset) {
            return false;
        }
        for (std::uint64_t byte = 0; byte < width; ++byte) {
            const std::size_t index = static_cast<std::size_t>(offset + byte);
            if (expected_write_[index] != 0) {
                return false;
            }
            expected_write_[index] = 1;
            ++expected_semantic_written_bytes_;
        }
        return true;
    }

    bool prepare_write_coverage() {
        expected_write_.assign(dst_->size, 0);
        write_seen_.assign(dst_->size, 0);
        expected_semantic_written_bytes_ = 0;
        const std::uint64_t width = type_bytes(profile_.dst.type_id);
        if (width == 0) {
            return false;
        }
        if (profile_.owner == npu_exact_owner::set_rows) {
            for (std::uint64_t index = 0; index < 512U; ++index) {
                std::uint64_t element = 0;
                if (profile_.owner_profile_id == 0U) {
                    if (!checked_mul(set_slot_, 512U, &element) ||
                        !checked_add(element, index, &element)) {
                        return false;
                    }
                } else {
                    if (!checked_mul(index, 256U, &element) ||
                        !checked_add(element, set_slot_, &element)) {
                        return false;
                    }
                }
                std::uint64_t offset = 0;
                if (!checked_mul(element, 2U, &offset) ||
                    !checked_add(offset, profile_.dst.view_off, &offset) ||
                    !mark_element(offset, 2U)) {
                    return false;
                }
            }
            return true;
        }
        for (std::uint64_t i3 = 0;
             i3 < static_cast<std::uint64_t>(profile_.dst.ne[3]); ++i3) {
            for (std::uint64_t i2 = 0;
                 i2 < static_cast<std::uint64_t>(profile_.dst.ne[2]); ++i2) {
                for (std::uint64_t i1 = 0;
                     i1 < static_cast<std::uint64_t>(profile_.dst.ne[1]);
                     ++i1) {
                    for (std::uint64_t i0 = 0;
                         i0 < static_cast<std::uint64_t>(profile_.dst.ne[0]);
                         ++i0) {
                        std::uint64_t offset = profile_.dst.view_off;
                        std::uint64_t term = 0;
                        if (!checked_mul(i0, profile_.dst.nb[0], &term) ||
                            !checked_add(offset, term, &offset) ||
                            !checked_mul(i1, profile_.dst.nb[1], &term) ||
                            !checked_add(offset, term, &offset) ||
                            !checked_mul(i2, profile_.dst.nb[2], &term) ||
                            !checked_add(offset, term, &offset) ||
                            !checked_mul(i3, profile_.dst.nb[3], &term) ||
                            !checked_add(offset, term, &offset) ||
                            !mark_element(offset, width)) {
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }

    void drive_idle_inputs() {
        top_->clk = 0;
        top_->rst = 0;
        top_->terminal_allow_i = 1;
        top_->gmem_req_ready_i = 0;
        top_->gmem_rsp_valid_i = 0;
        top_->gmem_rsp_rdata_i = 0;
        top_->gmem_rsp_error_i = 0;
#if defined(NPU_SYSTEM_Q8_PORTAL)
        top_->q8_portal_req_ready_i = 0;
        top_->q8_portal_rsp_valid_i = 0;
        top_->q8_portal_rsp_mask_i = 0;
        for (std::size_t word = 0; word < kQ8PortalResponseWords;
             ++word) {
            top_->q8_portal_rsp_blocks_i[word] = 0;
        }
        top_->q8_portal_rsp_error_i = 0;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        top_->f32_alu_portal_req_ready_i = 0;
        top_->f32_alu_portal_rsp_valid_i = 0;
        top_->f32_alu_portal_rsp_mask_i = 0;
        for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            top_->f32_alu_portal_rsp_src0_data_i[lane] = 0;
            top_->f32_alu_portal_rsp_src1_data_i[lane] = 0;
        }
        top_->f32_alu_portal_rsp_error_i = 0;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        top_->f32_mover_portal_req_ready_i = 0;
        top_->f32_mover_portal_rsp_valid_i = 0;
        top_->f32_mover_portal_rsp_mask_i = 0;
        for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            top_->f32_mover_portal_rsp_rdata_i[lane] = 0;
        }
        top_->f32_mover_portal_rsp_error_i = 0;
#endif
    }

#if defined(NPU_SYSTEM_Q8_PORTAL)
    void drive_portal_inputs() {
        top_->q8_portal_req_ready_i =
            portal_contract_.enabled && !portal_response_.occupied &&
                    !first_portal_request_hold_pending_
                ? 1
                : 0;
        top_->q8_portal_rsp_valid_i = portal_response_.active ? 1 : 0;
        top_->q8_portal_rsp_mask_i =
            portal_response_.active ? portal_response_.mask : 0U;
        for (std::size_t word = 0; word < kQ8PortalResponseWords;
             ++word) {
            top_->q8_portal_rsp_blocks_i[word] =
                portal_response_.active ? portal_response_.blocks[word] : 0U;
        }
        top_->q8_portal_rsp_error_i = 0;
    }
#endif

#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    void drive_f32_alu_portal_inputs() {
        top_->f32_alu_portal_req_ready_i =
            f32_alu_portal_contract_.enabled &&
                    !f32_alu_portal_response_.occupied &&
                    !f32_alu_first_request_hold_pending_
                ? 1 : 0;
        top_->f32_alu_portal_rsp_valid_i =
            f32_alu_portal_response_.active ? 1 : 0;
        top_->f32_alu_portal_rsp_mask_i =
            f32_alu_portal_response_.active ?
                f32_alu_portal_response_.mask : 0U;
        for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            top_->f32_alu_portal_rsp_src0_data_i[lane] =
                f32_alu_portal_response_.active ?
                    f32_alu_portal_response_.src0[lane] : 0U;
            top_->f32_alu_portal_rsp_src1_data_i[lane] =
                f32_alu_portal_response_.active ?
                    f32_alu_portal_response_.src1[lane] : 0U;
        }
        top_->f32_alu_portal_rsp_error_i = 0;
    }
#endif

#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    void drive_f32_mover_portal_inputs() {
        top_->f32_mover_portal_req_ready_i =
            f32_mover_portal_contract_.enabled &&
                    !f32_mover_portal_response_.occupied &&
                    !f32_mover_first_request_hold_pending_
                ? 1 : 0;
        top_->f32_mover_portal_rsp_valid_i =
            f32_mover_portal_response_.active ? 1 : 0;
        top_->f32_mover_portal_rsp_mask_i =
            f32_mover_portal_response_.active ?
                f32_mover_portal_response_.mask : 0U;
        for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            top_->f32_mover_portal_rsp_rdata_i[lane] =
                f32_mover_portal_response_.active ?
                    f32_mover_portal_response_.data[lane] : 0U;
        }
        top_->f32_mover_portal_rsp_error_i = 0;
    }
#endif

    void drive_memory_inputs() {
        // Keep ready low until the first request is actually visible.  The
        // first valid payload is therefore held for exactly one full cycle;
        // check_unaccepted_request_hold() then releases this per-transaction
        // gate permanently.  Later stalls are only real response-slot
        // backpressure, not an artificial periodic performance tax.
        top_->gmem_req_ready_i =
            !response_.occupied && !first_request_hold_pending_ ? 1 : 0;
        top_->gmem_rsp_valid_i = response_.active ? 1 : 0;
        top_->gmem_rsp_rdata_i = response_.active ? response_.data : 0;
        top_->gmem_rsp_error_i = 0;
#if defined(NPU_SYSTEM_Q8_PORTAL)
        drive_portal_inputs();
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        drive_f32_alu_portal_inputs();
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        drive_f32_mover_portal_inputs();
#endif
    }

    bool tick() {
        if (clock_cycles_ >=
            profile_.cycle_upper_bound + kCpuBootstrapAllowance) {
            return fail(exact_runner_timeout);
        }
        // The preceding falling-edge eval already settled this cycle's raw
        // memory inputs and all low-phase outputs.  Sampling them here avoids
        // the former duplicate clk=0 eval while preserving the real edge
        // ordering below.
        const bool request_valid = top_->gmem_req_valid_o != 0;
        const bool request_ready = top_->gmem_req_ready_i != 0;
        const bool request_fire = request_valid && request_ready;
        const bool response_fire =
            response_.active && top_->gmem_rsp_ready_o != 0;
#if defined(NPU_SYSTEM_Q8_PORTAL)
        const bool portal_request_valid =
            top_->q8_portal_req_valid_o != 0;
        const bool portal_request_ready =
            top_->q8_portal_req_ready_i != 0;
        const bool portal_request_fire =
            portal_request_valid && portal_request_ready;
        const bool portal_response_fire =
            portal_response_.active && top_->q8_portal_rsp_ready_o != 0;
        const std::uint32_t portal_request_mask =
            top_->q8_portal_req_mask_o;
        std::array<std::uint64_t, kQ8PortalRowLanes>
            portal_request_addresses = {};
        for (std::size_t lane = 0; lane < kQ8PortalRowLanes; ++lane) {
            portal_request_addresses[lane] = portal_load_lane_address(
                top_->q8_portal_req_addr_o, lane);
        }
        if ((!portal_contract_.enabled &&
             (portal_request_valid || top_->q8_portal_rsp_ready_o != 0 ||
              top_->q8_portal_outstanding_o != 0)) ||
            (portal_contract_.enabled && top_->rst == 0 &&
             (top_->q8_portal_outstanding_o != 0) !=
                 portal_response_.occupied)) {
            return portal_fail(exact_runner_q8_portal_request);
        }
        if (!check_portal_request_hold(
                portal_request_valid, portal_request_ready,
                portal_request_mask, portal_request_addresses)) {
            ++portal_payload_stability_mismatches_;
            return portal_fail(exact_runner_q8_portal_request);
        }
        if (!check_portal_response_hold()) {
            ++portal_payload_stability_mismatches_;
            return portal_fail(exact_runner_q8_portal_response);
        }
        portal_response_slot accepted_portal = {};
        if (portal_request_fire) {
            if (portal_response_.occupied) {
                return portal_fail(exact_runner_q8_portal_request);
            }
            if (!prepare_portal_response(
                    portal_request_mask, portal_request_addresses,
                    &accepted_portal)) {
                return portal_fail(portal_prepare_error_code_);
            }
            accepted_portal.occupied = true;
            accepted_portal.due_cycle = clock_cycles_ +
                portal_contract_.response_latency_cycles;
        }
        if (portal_response_fire && !portal_response_.occupied) {
            return portal_fail(exact_runner_q8_portal_response);
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        const bool f32_alu_request_valid =
            top_->f32_alu_portal_req_valid_o != 0;
        const bool f32_alu_request_ready =
            top_->f32_alu_portal_req_ready_i != 0;
        const bool f32_alu_request_fire =
            f32_alu_request_valid && f32_alu_request_ready;
        const bool f32_alu_response_fire =
            f32_alu_portal_response_.active &&
            top_->f32_alu_portal_rsp_ready_o != 0;
        const bool f32_alu_request_write =
            top_->f32_alu_portal_req_write_o != 0;
        const std::uint32_t f32_alu_request_mask =
            top_->f32_alu_portal_req_mask_o;
        std::array<std::uint64_t, kF32AluPortalLanes>
            f32_alu_request_src0 = {};
        std::array<std::uint64_t, kF32AluPortalLanes>
            f32_alu_request_src1 = {};
        std::array<std::uint64_t, kF32AluPortalLanes>
            f32_alu_request_dst = {};
        std::array<std::uint32_t, kF32AluPortalLanes>
            f32_alu_request_wdata = {};
        for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            f32_alu_request_src0[lane] = portal_load_lane_address(
                top_->f32_alu_portal_req_src0_addr_o, lane);
            f32_alu_request_src1[lane] = portal_load_lane_address(
                top_->f32_alu_portal_req_src1_addr_o, lane);
            f32_alu_request_dst[lane] = portal_load_lane_address(
                top_->f32_alu_portal_req_dst_addr_o, lane);
            f32_alu_request_wdata[lane] =
                top_->f32_alu_portal_req_wdata_o[lane];
        }
        if ((!f32_alu_portal_contract_.enabled &&
             (f32_alu_request_valid ||
              top_->f32_alu_portal_rsp_ready_o != 0 ||
              top_->f32_alu_portal_outstanding_o != 0 ||
              top_->f32_alu_portal_request_groups_o != 0 ||
              top_->f32_alu_portal_response_groups_o != 0 ||
              top_->f32_alu_portal_read_groups_o != 0 ||
              top_->f32_alu_portal_write_groups_o != 0 ||
              top_->f32_alu_portal_input_words_o != 0 ||
              top_->f32_alu_portal_output_words_o != 0 ||
              top_->f32_alu_portal_read_bytes_o != 0 ||
              top_->f32_alu_portal_write_bytes_o != 0)) ||
            (f32_alu_portal_contract_.enabled && top_->rst == 0 &&
             (top_->f32_alu_portal_outstanding_o != 0) !=
                 f32_alu_portal_response_.occupied)) {
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_request);
        }
        if (!check_f32_alu_request_hold(
                f32_alu_request_valid, f32_alu_request_ready,
                f32_alu_request_write, f32_alu_request_mask,
                f32_alu_request_src0, f32_alu_request_src1,
                f32_alu_request_dst, f32_alu_request_wdata)) {
            ++f32_alu_payload_stability_mismatches_;
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_request);
        }
        if (!check_f32_alu_response_hold()) {
            ++f32_alu_payload_stability_mismatches_;
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_response);
        }
        f32_alu_portal_response_slot accepted_f32_alu = {};
        if (f32_alu_request_fire) {
            if (f32_alu_portal_response_.occupied ||
                !prepare_f32_alu_portal_response(
                    f32_alu_request_write, f32_alu_request_mask,
                    f32_alu_request_src0, f32_alu_request_src1,
                    f32_alu_request_dst, f32_alu_request_wdata,
                    &accepted_f32_alu)) {
                return f32_alu_portal_fail(
                    exact_runner_f32_alu_portal_request);
            }
            accepted_f32_alu.occupied = true;
            accepted_f32_alu.due_cycle = clock_cycles_ +
                f32_alu_portal_contract_.response_latency_cycles;
        }
        if (f32_alu_response_fire &&
            !f32_alu_portal_response_.occupied) {
            return f32_alu_portal_fail(
                exact_runner_f32_alu_portal_response);
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        const bool f32_mover_request_valid =
            top_->f32_mover_portal_req_valid_o != 0;
        const bool f32_mover_request_ready =
            top_->f32_mover_portal_req_ready_i != 0;
        const bool f32_mover_request_fire =
            f32_mover_request_valid && f32_mover_request_ready;
        const bool f32_mover_response_fire =
            f32_mover_portal_response_.active &&
            top_->f32_mover_portal_rsp_ready_o != 0;
        const bool f32_mover_request_write =
            top_->f32_mover_portal_req_write_o != 0;
        const std::uint32_t f32_mover_request_mask =
            top_->f32_mover_portal_req_mask_o;
        std::array<std::uint64_t, kF32MoverPortalLanes>
            f32_mover_request_address = {};
        std::array<std::uint32_t, kF32MoverPortalLanes>
            f32_mover_request_wdata = {};
        for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            f32_mover_request_address[lane] = portal_load_lane_address(
                top_->f32_mover_portal_req_addr_o, lane);
            f32_mover_request_wdata[lane] =
                top_->f32_mover_portal_req_wdata_o[lane];
        }
        if ((!f32_mover_portal_contract_.enabled &&
             (f32_mover_request_valid ||
              top_->f32_mover_portal_rsp_ready_o != 0 ||
              top_->f32_mover_portal_outstanding_o != 0 ||
              top_->f32_mover_portal_request_groups_o != 0 ||
              top_->f32_mover_portal_response_groups_o != 0 ||
              top_->f32_mover_portal_read_groups_o != 0 ||
              top_->f32_mover_portal_write_groups_o != 0 ||
              top_->f32_mover_portal_read_words_o != 0 ||
              top_->f32_mover_portal_write_words_o != 0 ||
              top_->f32_mover_portal_read_bytes_o != 0 ||
              top_->f32_mover_portal_write_bytes_o != 0)) ||
            (f32_mover_portal_contract_.enabled && top_->rst == 0 &&
             (top_->f32_mover_portal_outstanding_o != 0) !=
                 f32_mover_portal_response_.occupied)) {
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_request);
        }
        if (!check_f32_mover_request_hold(
                f32_mover_request_valid, f32_mover_request_ready,
                f32_mover_request_write, f32_mover_request_mask,
                f32_mover_request_address, f32_mover_request_wdata)) {
            ++f32_mover_payload_stability_mismatches_;
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_request);
        }
        if (!check_f32_mover_response_hold()) {
            ++f32_mover_payload_stability_mismatches_;
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_response);
        }
        f32_mover_portal_response_slot accepted_f32_mover = {};
        if (f32_mover_request_fire) {
            if (f32_mover_portal_response_.occupied ||
                !prepare_f32_mover_portal_response(
                    f32_mover_request_write, f32_mover_request_mask,
                    f32_mover_request_address, f32_mover_request_wdata,
                    &accepted_f32_mover)) {
                return f32_mover_portal_fail(
                    exact_runner_f32_mover_portal_request);
            }
            accepted_f32_mover.occupied = true;
            accepted_f32_mover.due_cycle = clock_cycles_ +
                f32_mover_portal_contract_.response_latency_cycles;
        }
        if (f32_mover_response_fire &&
            !f32_mover_portal_response_.occupied) {
            return f32_mover_portal_fail(
                exact_runner_f32_mover_portal_response);
        }
#endif
        const bool command_fire = top_->rst == 0 &&
            top_->cpu_tensor_cmd_valid_o != 0 &&
            top_->cpu_tensor_cmd_ready_o != 0;
        const bool terminal_fire = top_->rst == 0 &&
            top_->npu_terminal_valid_o != 0 &&
            top_->npu_terminal_ready_o != 0;
        const std::uint64_t command_bits = top_->cpu_tensor_cmd_bits_o;
        const std::uint8_t command_pid =
            top_->cpu_tensor_cmd_producer_id_o;
        const std::uint8_t terminal_pid =
            top_->npu_terminal_producer_id_o;
        const std::uint8_t terminal_error = top_->npu_terminal_error_o;
        const std::uint8_t terminal_error_code =
            top_->npu_terminal_error_code_o;
        const bool terminal_macro_valid =
            top_->macro_completion_valid_o != 0;
        const bool terminal_identity_match =
            top_->npu_identity_match_o != 0;
        const bool descriptor_resident_before =
            top_->direct_f32_desc_resident_o != 0;
        if (!check_unaccepted_request_hold(request_valid, request_ready) ||
            (request_fire && response_.occupied)) {
            return fail(exact_runner_request_protocol);
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
        if (terminal_fire && terminal_macro_valid) {
            if (completion_snapshot_seen_) {
                return fail(exact_runner_completion_protocol);
            }
            const completion_snapshot sampled = capture_completion(*top_);
            if (!select_terminal_contract(sampled)) {
                std::fprintf(
                    stderr,
                    "[NPU-EXACT-RUNNER][TERMINAL-MISMATCH] "
                    "manifest_profile=%u local_profile=%u kernel=0x%08x "
                    "expected_success=%u terminal_pid=%u terminal_error=%u "
                    "terminal_error_code=%u is_macro=%u status=%u "
                    "error_class=%u returned_kernel=0x%08x "
                    "returned_local_profile=%u identity_wire_match=%u "
                    "src0=0x%016llx src0_window=0x%016llx+%llu/p%u "
                    "src1=0x%016llx src1_window=0x%016llx+%llu/p%u "
                    "dst=0x%016llx dst_window=0x%016llx+%llu/p%u\n",
                    profile_.manifest_profile_id,
                    profile_.public_local_profile,
                    command_.kernel_id,
                    expected_success_ ? 1U : 0U,
                    static_cast<unsigned>(terminal_pid),
                    static_cast<unsigned>(terminal_error),
                    static_cast<unsigned>(terminal_error_code),
                    sampled.is_macro,
                    sampled.status,
                    sampled.error_class,
                    sampled.kernel_id,
                    sampled.vector_flags,
                    terminal_identity_match ? 1U : 0U,
                    static_cast<unsigned long long>(command_.src0_iova),
                    static_cast<unsigned long long>(
                        command_.src0_window_base),
                    static_cast<unsigned long long>(
                        command_.src0_window_size),
                    command_.src0_window_perm,
                    static_cast<unsigned long long>(command_.src1_iova),
                    static_cast<unsigned long long>(
                        command_.src1_window_base),
                    static_cast<unsigned long long>(
                        command_.src1_window_size),
                    command_.src1_window_perm,
                    static_cast<unsigned long long>(command_.dst_iova),
                    static_cast<unsigned long long>(
                        command_.dst_window_base),
                    static_cast<unsigned long long>(
                        command_.dst_window_size),
                    command_.dst_window_perm);
                return fail(exact_runner_terminal_mismatch);
            }
            accepted_snapshot_ = sampled;
            completion_snapshot_seen_ = true;
            completion_identity_match_at_accept_ = terminal_identity_match;
            // Production keeps terminal credit asserted.  Capture the full
            // public payload atomically on the real terminal handshake;
            // held-valid stability is covered by the isolated SystemTop TB.
            result_->completion_stable = true;
        }
        top_->clk = 1;
        top_->eval();
        context_->timeInc(1);
        ++cpu_cycle_counter_;
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
#if defined(NPU_SYSTEM_Q8_PORTAL)
        if (portal_response_fire) {
            portal_response_ = {};
            ++portal_response_groups_;
        }
        if (portal_request_fire) {
            portal_response_ = accepted_portal;
            ++portal_request_groups_;
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        if (f32_alu_response_fire) {
            f32_alu_portal_response_ = {};
            ++f32_alu_response_groups_;
        }
        if (f32_alu_request_fire) {
            f32_alu_portal_response_ = accepted_f32_alu;
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        if (f32_mover_response_fire) {
            f32_mover_portal_response_ = {};
            ++f32_mover_response_groups_;
        }
        if (f32_mover_request_fire) {
            f32_mover_portal_response_ = accepted_f32_mover;
        }
#endif
        if (command_fire && !handle_command_fire(
                command_bits, command_pid, descriptor_resident_before)) {
            return false;
        }
        if (terminal_fire && !handle_terminal_fire(
                terminal_pid, terminal_error, terminal_error_code,
                terminal_macro_valid, terminal_identity_match)) {
            return false;
        }
        if (top_->rst == 0 && top_->cpu_commit0_valid_o != 0 &&
            !handle_cpu_commit()) {
            return false;
        }
        top_->clk = 0;
        ++clock_cycles_;
        if (response_.occupied && !response_.active &&
            clock_cycles_ >= response_.due_cycle) {
            response_.active = true;
        }
#if defined(NPU_SYSTEM_Q8_PORTAL)
        if (portal_response_.occupied && !portal_response_.active &&
            clock_cycles_ >= portal_response_.due_cycle) {
            if (clock_cycles_ != portal_response_.due_cycle) {
                ++portal_latency_mismatches_;
                return portal_fail(exact_runner_q8_portal_response);
            }
            portal_response_.active = true;
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        if (f32_alu_portal_response_.occupied &&
            !f32_alu_portal_response_.active &&
            clock_cycles_ >= f32_alu_portal_response_.due_cycle) {
            if (clock_cycles_ != f32_alu_portal_response_.due_cycle) {
                ++f32_alu_latency_mismatches_;
                return f32_alu_portal_fail(
                    exact_runner_f32_alu_portal_response);
            }
            f32_alu_portal_response_.active = true;
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        if (f32_mover_portal_response_.occupied &&
            !f32_mover_portal_response_.active &&
            clock_cycles_ >= f32_mover_portal_response_.due_cycle) {
            if (clock_cycles_ != f32_mover_portal_response_.due_cycle) {
                ++f32_mover_latency_mismatches_;
                return f32_mover_portal_fail(
                    exact_runner_f32_mover_portal_response);
            }
            f32_mover_portal_response_.active = true;
        }
#endif
        // Prepare the next cycle before evaluating the actual falling edge.
        // This keeps response latency indexed by the same clock_cycles_ value
        // as the original three-eval loop, while also allowing the
        // negedge-latched CPU clock gate to observe a real high-to-low
        // transition.
        drive_memory_inputs();
        top_->eval();
        context_->timeInc(1);
        return true;
    }

    bool handle_command_fire(
            std::uint64_t bits,
            std::uint8_t producer,
            bool descriptor_resident_before) {
        if (cpu_tensor_commands_accepted_ >= command_pids_.size() ||
            top_->cpu_tensor_serialize_o == 0) {
            return fail(exact_runner_cpu_protocol);
        }
        const std::size_t ordinal =
            static_cast<std::size_t>(cpu_tensor_commands_accepted_);
        command_pids_[ordinal] = producer;
        if (ordinal < descriptor_words_.size()) {
            const std::uint64_t expected = encode_config(
                static_cast<unsigned>(ordinal), 2U);
            if (bits != expected || descriptor_resident_before ||
                top_->descriptor_expected_index_o != ordinal + 1U ||
                ((ordinal < descriptor_words_.size() - 1U) &&
                 top_->direct_f32_desc_resident_o != 0) ||
                ((ordinal == descriptor_words_.size() - 1U) &&
                 top_->direct_f32_desc_resident_o == 0)) {
                return fail(exact_runner_cpu_protocol);
            }
            ++cpu_config_commands_accepted_;
        } else {
            if (bits != kLaunchBits || !descriptor_resident_before ||
                top_->descriptor_inflight_o == 0 ||
                top_->direct_f32_desc_resident_o != 0) {
                return fail(exact_runner_cpu_protocol);
            }
            launch_cpu_pid_ = producer;
            launch_command_seen_ = true;
            // CPU terminal PID and full 64-bit macro producer identity are
            // separate domains and are checked at their actual handshakes.
            top_->terminal_allow_i = 1;
        }
        ++cpu_tensor_commands_accepted_;
        return true;
    }

    bool handle_terminal_fire(
            std::uint8_t producer,
            std::uint8_t error,
            std::uint8_t error_code,
            bool macro_completion_valid,
            bool identity_match) {
        if (cpu_terminals_accepted_ >= cpu_tensor_commands_accepted_ ||
            cpu_terminals_accepted_ >= command_pids_.size() ||
            producer != command_pids_[cpu_terminals_accepted_]) {
            return fail(exact_runner_cpu_terminal);
        }
        const bool macro_terminal =
            cpu_terminals_accepted_ == descriptor_words_.size();
        if ((!macro_terminal && (error != 0 || error_code != 0)) ||
            (macro_terminal &&
             (error != (expected_success_ ? 0U : 1U) ||
              error_code != expected_error_code_))) {
            return fail(exact_runner_cpu_terminal);
        }
        ++cpu_terminals_accepted_;
        if (macro_terminal) {
            if (!launch_command_seen_ ||
                producer != launch_cpu_pid_ ||
                !macro_completion_valid || !identity_match) {
                return fail(exact_runner_cpu_terminal);
            }
            macro_terminal_fired_ = true;
            result_->completion_accepted = true;
        }
        return true;
    }

    bool handle_cpu_commit() {
        const std::uint64_t pc = top_->cpu_commit0_pc_o;
        const std::uint32_t instruction = top_->cpu_commit0_inst_o;
        if (pc >= kFirstConfigPc &&
            pc <= kFirstConfigPc + 29ULL * 16ULL &&
            ((pc - kFirstConfigPc) % 16ULL) == 0) {
            const std::size_t index = static_cast<std::size_t>(
                (pc - kFirstConfigPc) / 16ULL);
            if (config_commit_seen_[index] ||
                instruction != encode_config(
                    static_cast<unsigned>(index), 2U) ||
                top_->cpu_commit0_rd_en_o != 0 ||
                top_->cpu_commit0_exception_o != 0) {
                return fail(exact_runner_cpu_commit);
            }
            config_commit_seen_[index] = true;
            ++cpu_config_commits_;
        } else if (pc == kLaunchPc) {
            if (launch_commit_seen_ || !macro_terminal_fired_ ||
                instruction != kLaunchLo ||
                top_->cpu_commit0_rd_en_o != 0 ||
                top_->cpu_commit0_exception_o !=
                    (expected_success_ ? 0U : 1U)) {
                return fail(exact_runner_cpu_commit);
            }
            launch_commit_seen_ = true;
            launch_commit_instruction_ = instruction;
            ++cpu_launch_commits_;
        }
        return true;
    }

    bool check_unaccepted_request_hold(bool valid, bool ready) {
        if (valid && !ready) {
            request_hold_observed_ = true;
            if (first_request_hold_pending_) {
                // No response can precede the first accepted request.  Clear
                // the one-shot only after observing valid under backpressure;
                // drive_memory_inputs() will raise ready for the next cycle.
                if (response_.occupied) {
                    return false;
                }
                first_request_hold_pending_ = false;
                ++first_request_hold_cycles_;
            }
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
                return false;
            }
        } else {
            unaccepted_request_held_ = false;
        }
        return true;
    }

#if defined(NPU_SYSTEM_Q8_PORTAL)
    bool check_portal_request_hold(
            bool valid,
            bool ready,
            std::uint32_t mask,
            const std::array<std::uint64_t, kQ8PortalRowLanes> & addresses) {
        if (portal_request_held_) {
            if (!valid || held_portal_request_mask_ != mask ||
                held_portal_request_addresses_ != addresses) {
                return false;
            }
            if (ready) {
                portal_request_held_ = false;
            }
        }
        if (valid && !ready) {
            if (first_portal_request_hold_pending_) {
                if (portal_response_.occupied) {
                    return false;
                }
                first_portal_request_hold_pending_ = false;
                ++first_portal_request_hold_cycles_;
            }
            if (!portal_request_held_) {
                portal_request_held_ = true;
                held_portal_request_mask_ = mask;
                held_portal_request_addresses_ = addresses;
            }
        }
        return true;
    }

    bool check_portal_response_hold() const {
        if (!portal_response_.active) {
            if (top_->q8_portal_rsp_valid_i != 0 ||
                top_->q8_portal_rsp_mask_i != 0 ||
                top_->q8_portal_rsp_error_i != 0) {
                return false;
            }
            for (std::size_t word = 0; word < kQ8PortalResponseWords;
                 ++word) {
                if (top_->q8_portal_rsp_blocks_i[word] != 0U) {
                    return false;
                }
            }
            return true;
        }
        if (top_->q8_portal_rsp_valid_i == 0 ||
            top_->q8_portal_rsp_mask_i != portal_response_.mask) {
            return false;
        }
        for (std::size_t word = 0; word < kQ8PortalResponseWords;
             ++word) {
            if (top_->q8_portal_rsp_blocks_i[word] !=
                portal_response_.blocks[word]) {
                return false;
            }
        }
        return top_->q8_portal_rsp_error_i == 0;
    }

    bool prepare_portal_response(
            std::uint32_t mask,
            const std::array<std::uint64_t, kQ8PortalRowLanes> & addresses,
            portal_response_slot * response) {
        portal_prepare_error_code_ = exact_runner_q8_portal_request;
        if (response == nullptr || !portal_contract_.enabled || mask == 0U ||
            portal_request_groups_ >=
                portal_contract_.expected_request_groups ||
            portal_expected_row_base_ >= command_.outer_count ||
            portal_expected_block_index_ >=
                portal_contract_.blocks_per_row) {
            return false;
        }

        std::uint32_t expected_mask = 0;
        for (std::uint32_t lane = 0; lane < kQ8PortalRowLanes; ++lane) {
            if (portal_expected_row_base_ + lane < command_.outer_count) {
                expected_mask |= 1U << lane;
            }
        }
        if (mask != expected_mask) {
            return false;
        }

        response->mask = mask;
        response->blocks.fill(0U);
        for (std::size_t lane = 0; lane < kQ8PortalRowLanes; ++lane) {
            const bool active = (mask & (1U << lane)) != 0U;
            if (!active) {
                if (addresses[lane] != 0U) {
                    return false;
                }
                continue;
            }

            std::uint64_t row_offset = 0;
            std::uint64_t block_offset = 0;
            std::uint64_t expected_address = 0;
            const std::uint64_t row = portal_expected_row_base_ + lane;
            if (!checked_mul(row, command_.src1_stride, &row_offset) ||
                !checked_mul(
                    portal_expected_block_index_, kQ8PortalBlockBytes,
                    &block_offset) ||
                !checked_add(
                    command_.src1_iova, row_offset, &expected_address) ||
                !checked_add(
                    expected_address, block_offset, &expected_address) ||
                expected_address < src1_.region_base) {
                portal_prepare_error_code_ = exact_runner_q8_portal_memory;
                return false;
            }
            if (addresses[lane] != expected_address) {
                return false;
            }

            const std::uint64_t allocation_offset =
                expected_address - src1_.region_base;
            std::uint64_t block_end = 0;
            std::uint64_t window_end = 0;
            if (allocation_offset > src1_.allocation_bytes ||
                kQ8PortalBlockBytes >
                    src1_.allocation_bytes - allocation_offset ||
                portal_blocks_copied_ >=
                    portal_contract_.expected_blocks ||
                portal_raw_copy_bytes_ >
                    portal_contract_.expected_bytes -
                        kQ8PortalBlockBytes ||
                !checked_add(
                    expected_address, kQ8PortalBlockBytes, &block_end) ||
                !checked_add(
                    src1_.window_base, src1_.window_bytes, &window_end) ||
                expected_address < src1_.window_base ||
                block_end > window_end) {
                portal_prepare_error_code_ = exact_runner_q8_portal_memory;
                return false;
            }

            std::array<std::uint8_t, kQ8PortalBlockBytes> raw_block = {};
            std::memcpy(
                raw_block.data(),
                src1_.read_bytes +
                    static_cast<std::size_t>(allocation_offset),
                raw_block.size());
            for (std::size_t byte = 0; byte < raw_block.size(); ++byte) {
                const std::size_t bit = lane * 272U + byte * 8U;
                const std::size_t word = bit / 32U;
                const unsigned shift = static_cast<unsigned>(bit % 32U);
                response->blocks[word] |=
                    static_cast<std::uint32_t>(raw_block[byte]) << shift;
            }
            ++portal_blocks_copied_;
            portal_raw_copy_bytes_ += raw_block.size();
        }

        if (portal_expected_block_index_ + 1U ==
            portal_contract_.blocks_per_row) {
            portal_expected_block_index_ = 0;
            portal_expected_row_base_ += kQ8PortalRowLanes;
        } else {
            ++portal_expected_block_index_;
        }
        return true;
    }
#endif

    bool commit_raw32_portal_write(
            std::uint64_t address,
            std::uint32_t value,
            std::uint64_t * raw_copy_bytes) {
        if (raw_copy_bytes == nullptr ||
            !raw_word_in_window(address, dst_window_, false, true)) {
            return false;
        }
        const std::size_t offset = static_cast<std::size_t>(
            address - dst_window_.region_base);
        if (offset > expected_write_.size() ||
            4U > expected_write_.size() - offset) {
            return false;
        }
        for (std::size_t byte = 0; byte < 4U; ++byte) {
            if (expected_write_[offset + byte] != 1U ||
                write_seen_[offset + byte] != 0U) {
                return false;
            }
        }
        std::memcpy(dst_window_.write_bytes + offset, &value, sizeof(value));
        for (std::size_t byte = 0; byte < 4U; ++byte) {
            write_seen_[offset + byte] = 1U;
        }
        written_bytes_ += 4U;
        *raw_copy_bytes += 4U;
        return true;
    }

#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    bool f32_alu_expected_addresses(
            std::uint64_t flat,
            std::uint64_t * src0_address,
            std::uint64_t * src1_address,
            std::uint64_t * dst_address) const {
        if (src0_address == nullptr || src1_address == nullptr ||
            dst_address == nullptr) {
            return false;
        }
        std::array<std::uint64_t, 4> coordinate = {};
        std::uint64_t quotient = flat;
        for (std::size_t dimension = 0; dimension < 4U; ++dimension) {
            if (f32_alu_profile_.src0.ne[dimension] == 0U) {
                return false;
            }
            coordinate[dimension] =
                quotient % f32_alu_profile_.src0.ne[dimension];
            quotient /= f32_alu_profile_.src0.ne[dimension];
        }
        std::uint64_t src0 = src0_.window_base;
        std::uint64_t src1 = src1_.window_base;
        if (!checked_add(src0, f32_alu_profile_.src0.view_off, &src0) ||
            (f32_alu_profile_.src1_present &&
             !checked_add(src1, f32_alu_profile_.src1.view_off, &src1))) {
            return false;
        }
        for (std::size_t dimension = 0; dimension < 4U; ++dimension) {
            std::uint64_t term = 0;
            if (!checked_mul(
                    coordinate[dimension],
                    f32_alu_profile_.src0.nb[dimension], &term) ||
                !checked_add(src0, term, &src0)) {
                return false;
            }
            if (f32_alu_profile_.src1_present) {
                if (f32_alu_profile_.src1.ne[dimension] == 0U ||
                    !checked_mul(
                        coordinate[dimension] %
                            f32_alu_profile_.src1.ne[dimension],
                        f32_alu_profile_.src1.nb[dimension], &term) ||
                    !checked_add(src1, term, &src1)) {
                    return false;
                }
            }
        }
        std::uint64_t dst_offset = 0;
        if (!checked_mul(flat, 4U, &dst_offset) ||
            !checked_add(dst_window_.window_base, dst_offset,
                         dst_address)) {
            return false;
        }
        *src0_address = src0;
        *src1_address = f32_alu_profile_.src1_present ? src1 : 0U;
        return true;
    }

    bool check_f32_alu_request_hold(
            bool valid,
            bool ready,
            bool write,
            std::uint32_t mask,
            const std::array<std::uint64_t, kF32AluPortalLanes> & src0,
            const std::array<std::uint64_t, kF32AluPortalLanes> & src1,
            const std::array<std::uint64_t, kF32AluPortalLanes> & dst,
            const std::array<std::uint32_t, kF32AluPortalLanes> & wdata) {
        if (f32_alu_request_held_) {
            if (!valid || write != f32_alu_held_write_ ||
                mask != f32_alu_held_mask_ ||
                src0 != f32_alu_held_src0_ ||
                src1 != f32_alu_held_src1_ ||
                dst != f32_alu_held_dst_ ||
                wdata != f32_alu_held_wdata_) {
                return false;
            }
            if (ready) {
                f32_alu_request_held_ = false;
            }
        }
        if (valid && !ready) {
            if (f32_alu_first_request_hold_pending_) {
                if (f32_alu_portal_response_.occupied) {
                    return false;
                }
                f32_alu_first_request_hold_pending_ = false;
                ++f32_alu_first_request_hold_cycles_;
            }
            if (!f32_alu_request_held_) {
                f32_alu_request_held_ = true;
                f32_alu_held_write_ = write;
                f32_alu_held_mask_ = mask;
                f32_alu_held_src0_ = src0;
                f32_alu_held_src1_ = src1;
                f32_alu_held_dst_ = dst;
                f32_alu_held_wdata_ = wdata;
            }
        }
        return true;
    }

    bool check_f32_alu_response_hold() const {
        if (!f32_alu_portal_response_.active) {
            if (top_->f32_alu_portal_rsp_valid_i != 0 ||
                top_->f32_alu_portal_rsp_mask_i != 0 ||
                top_->f32_alu_portal_rsp_error_i != 0) {
                return false;
            }
            for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
                if (top_->f32_alu_portal_rsp_src0_data_i[lane] != 0U ||
                    top_->f32_alu_portal_rsp_src1_data_i[lane] != 0U) {
                    return false;
                }
            }
            return true;
        }
        if (top_->f32_alu_portal_rsp_valid_i == 0 ||
            top_->f32_alu_portal_rsp_mask_i !=
                f32_alu_portal_response_.mask ||
            top_->f32_alu_portal_rsp_error_i != 0) {
            return false;
        }
        for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            if (top_->f32_alu_portal_rsp_src0_data_i[lane] !=
                    f32_alu_portal_response_.src0[lane] ||
                top_->f32_alu_portal_rsp_src1_data_i[lane] !=
                    f32_alu_portal_response_.src1[lane]) {
                return false;
            }
        }
        return true;
    }

    bool prepare_f32_alu_portal_response(
            bool write,
            std::uint32_t mask,
            const std::array<std::uint64_t, kF32AluPortalLanes> & src0,
            const std::array<std::uint64_t, kF32AluPortalLanes> & src1,
            const std::array<std::uint64_t, kF32AluPortalLanes> & dst,
            const std::array<std::uint32_t, kF32AluPortalLanes> & wdata,
            f32_alu_portal_response_slot * response) {
        if (response == nullptr || !f32_alu_portal_contract_.enabled ||
            mask == 0U || write != f32_alu_expect_write_ ||
            f32_alu_request_groups_ >=
                f32_alu_portal_contract_.expected_request_groups ||
            f32_alu_batch_base_ >= f32_alu_profile_.total_elements) {
            return false;
        }
        std::uint32_t expected_mask = 0;
        for (std::uint32_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            if (f32_alu_batch_base_ + lane <
                f32_alu_profile_.total_elements) {
                expected_mask |= 1U << lane;
            }
        }
        if (mask != expected_mask) {
            return false;
        }
        response->mask = mask;
        response->src0.fill(0U);
        response->src1.fill(0U);
        std::uint64_t active_words = 0;
        for (std::size_t lane = 0; lane < kF32AluPortalLanes; ++lane) {
            const bool active = (mask & (1U << lane)) != 0U;
            if (!active) {
                if (src0[lane] != 0U || src1[lane] != 0U ||
                    dst[lane] != 0U || wdata[lane] != 0U) {
                    return false;
                }
                continue;
            }
            ++active_words;
            std::uint64_t expected_src0 = 0;
            std::uint64_t expected_src1 = 0;
            std::uint64_t expected_dst = 0;
            if (!f32_alu_expected_addresses(
                    f32_alu_batch_base_ + lane,
                    &expected_src0, &expected_src1, &expected_dst)) {
                return false;
            }
            if (!write) {
                if (src0[lane] != expected_src0 ||
                    src1[lane] != expected_src1 || dst[lane] != 0U ||
                    wdata[lane] != 0U ||
                    !raw_word_in_window(src0[lane], src0_, true, false) ||
                    (f32_alu_profile_.src1_present &&
                     !raw_word_in_window(src1[lane], src1_, true, false))) {
                    return false;
                }
                response->src0[lane] = load_raw_word(src0[lane], src0_);
                f32_alu_raw_read_copy_bytes_ += 4U;
                if (f32_alu_profile_.src1_present) {
                    response->src1[lane] =
                        load_raw_word(src1[lane], src1_);
                    f32_alu_raw_read_copy_bytes_ += 4U;
                }
            } else {
                if (src0[lane] != 0U || src1[lane] != 0U ||
                    dst[lane] != expected_dst ||
                    !commit_raw32_portal_write(
                        dst[lane], wdata[lane],
                        &f32_alu_raw_write_copy_bytes_)) {
                    return false;
                }
            }
        }
        ++f32_alu_request_groups_;
        if (write) {
            ++f32_alu_write_groups_;
            f32_alu_write_words_ += active_words;
            f32_alu_expect_write_ = false;
            f32_alu_batch_base_ += kF32AluPortalLanes;
        } else {
            ++f32_alu_read_groups_;
            f32_alu_read_words_ += active_words *
                (f32_alu_profile_.src1_present ? 2U : 1U);
            f32_alu_expect_write_ = true;
        }
        return true;
    }
#endif

#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    bool check_f32_mover_request_hold(
            bool valid,
            bool ready,
            bool write,
            std::uint32_t mask,
            const std::array<std::uint64_t, kF32MoverPortalLanes> & address,
            const std::array<std::uint32_t, kF32MoverPortalLanes> & wdata) {
        if (f32_mover_request_held_) {
            if (!valid || write != f32_mover_held_write_ ||
                mask != f32_mover_held_mask_ ||
                address != f32_mover_held_address_ ||
                wdata != f32_mover_held_wdata_) {
                return false;
            }
            if (ready) {
                f32_mover_request_held_ = false;
            }
        }
        if (valid && !ready) {
            if (f32_mover_first_request_hold_pending_) {
                if (f32_mover_portal_response_.occupied) {
                    return false;
                }
                f32_mover_first_request_hold_pending_ = false;
                ++f32_mover_first_request_hold_cycles_;
            }
            if (!f32_mover_request_held_) {
                f32_mover_request_held_ = true;
                f32_mover_held_write_ = write;
                f32_mover_held_mask_ = mask;
                f32_mover_held_address_ = address;
                f32_mover_held_wdata_ = wdata;
            }
        }
        return true;
    }

    bool check_f32_mover_response_hold() const {
        if (!f32_mover_portal_response_.active) {
            if (top_->f32_mover_portal_rsp_valid_i != 0 ||
                top_->f32_mover_portal_rsp_mask_i != 0 ||
                top_->f32_mover_portal_rsp_error_i != 0) {
                return false;
            }
            for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
                if (top_->f32_mover_portal_rsp_rdata_i[lane] != 0U) {
                    return false;
                }
            }
            return true;
        }
        if (top_->f32_mover_portal_rsp_valid_i == 0 ||
            top_->f32_mover_portal_rsp_mask_i !=
                f32_mover_portal_response_.mask ||
            top_->f32_mover_portal_rsp_error_i != 0) {
            return false;
        }
        for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            if (top_->f32_mover_portal_rsp_rdata_i[lane] !=
                f32_mover_portal_response_.data[lane]) {
                return false;
            }
        }
        return true;
    }

    bool prepare_f32_mover_portal_response(
            bool write,
            std::uint32_t mask,
            const std::array<std::uint64_t, kF32MoverPortalLanes> & address,
            const std::array<std::uint32_t, kF32MoverPortalLanes> & wdata,
            f32_mover_portal_response_slot * response) {
        if (response == nullptr || !f32_mover_portal_contract_.enabled ||
            mask == 0U ||
            f32_mover_portal_phase_ == mover_portal_phase::done ||
            f32_mover_request_groups_ >=
                f32_mover_portal_contract_.expected_request_groups) {
            return false;
        }
        const bool expected_write =
            f32_mover_portal_phase_ ==
                mover_portal_phase::destination_write;
        const std::uint64_t base_position =
            f32_mover_portal_phase_ == mover_portal_phase::index_read ?
                f32_mover_index_position_ : f32_mover_element_position_;
        const std::uint64_t limit =
            f32_mover_portal_phase_ == mover_portal_phase::index_read ?
                command_.outer_count : command_.element_count;
        std::uint32_t expected_mask = 0;
        for (std::uint32_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            if (base_position + lane < limit) {
                expected_mask |= 1U << lane;
            }
        }
        if (write != expected_write || mask != expected_mask) {
            return false;
        }
        response->mask = mask;
        response->data.fill(0U);
        std::uint64_t active_words = 0;
        std::uint64_t get_source_row_base = 0;
        bool get_source_row_base_valid = false;
        for (std::size_t lane = 0; lane < kF32MoverPortalLanes; ++lane) {
            const bool active = (mask & (1U << lane)) != 0U;
            if (!active) {
                if (address[lane] != 0U || wdata[lane] != 0U) {
                    return false;
                }
                continue;
            }
            ++active_words;
            std::uint64_t expected_address = 0;
            std::uint64_t offset = 0;
            if (f32_mover_portal_phase_ ==
                    mover_portal_phase::index_read) {
                if (!checked_mul(
                        f32_mover_index_position_ + lane,
                        command_.src1_stride, &offset) ||
                    !checked_add(command_.src1_iova, offset,
                                 &expected_address) ||
                    address[lane] != expected_address ||
                    wdata[lane] != 0U ||
                    !raw_word_in_window(address[lane], src1_, true, false)) {
                    return false;
                }
                response->data[lane] = load_raw_word(address[lane], src1_);
                f32_mover_raw_read_copy_bytes_ += 4U;
            } else if (!expected_write) {
                if (!f32_mover_get_rows_) {
                    std::uint64_t outer_offset = 0;
                    if (!checked_mul(
                            f32_mover_outer_position_,
                            command_.src0_stride, &outer_offset) ||
                        !checked_mul(
                            f32_mover_element_position_ + lane, 4U,
                            &offset) ||
                        !checked_add(command_.src0_iova, outer_offset,
                                     &expected_address) ||
                        !checked_add(expected_address, offset,
                                     &expected_address)) {
                        return false;
                    }
                } else {
                    std::uint64_t element_offset = 0;
                    if (!checked_mul(
                            f32_mover_element_position_ + lane, 4U,
                            &element_offset) ||
                        address[lane] < command_.src0_iova + element_offset) {
                        return false;
                    }
                    const std::uint64_t row_offset =
                        address[lane] - command_.src0_iova - element_offset;
                    if (command_.src0_stride == 0U ||
                        (row_offset % command_.src0_stride) != 0U ||
                        row_offset / command_.src0_stride >=
                            command_.scalar0) {
                        return false;
                    }
                    if (!get_source_row_base_valid) {
                        get_source_row_base = row_offset;
                        get_source_row_base_valid = true;
                    } else if (get_source_row_base != row_offset) {
                        return false;
                    }
                    expected_address = address[lane];
                }
                if (address[lane] != expected_address ||
                    wdata[lane] != 0U ||
                    !raw_word_in_window(address[lane], src0_, true, false)) {
                    return false;
                }
                response->data[lane] = load_raw_word(address[lane], src0_);
                f32_mover_raw_read_copy_bytes_ += 4U;
            } else {
                std::uint64_t row_offset = 0;
                std::uint64_t repeat_offset = 0;
                if (f32_mover_get_rows_) {
                    if (!checked_mul(
                            f32_mover_index_position_ +
                                f32_mover_index_lane_,
                            command_.dst_stride, &row_offset)) {
                        return false;
                    }
                } else if (!checked_mul(
                               f32_mover_outer_position_,
                               command_.src2_stride, &row_offset) ||
                           !checked_mul(
                               f32_mover_repeat_position_,
                               command_.dst_stride, &repeat_offset) ||
                           !checked_add(row_offset, repeat_offset,
                                        &row_offset)) {
                    return false;
                }
                if (!checked_mul(
                        f32_mover_element_position_ + lane, 4U, &offset) ||
                    !checked_add(command_.dst_iova, row_offset,
                                 &expected_address) ||
                    !checked_add(expected_address, offset,
                                 &expected_address) ||
                    address[lane] != expected_address ||
                    !commit_raw32_portal_write(
                        address[lane], wdata[lane],
                        &f32_mover_raw_write_copy_bytes_)) {
                    return false;
                }
            }
        }
        ++f32_mover_request_groups_;
        if (expected_write) {
            ++f32_mover_write_groups_;
            f32_mover_write_words_ += active_words;
            if (f32_mover_get_rows_) {
                if (f32_mover_element_position_ + active_words <
                    command_.element_count) {
                    f32_mover_element_position_ += active_words;
                    f32_mover_portal_phase_ =
                        mover_portal_phase::source_read;
                } else if (f32_mover_index_lane_ + 1U <
                           f32_mover_index_group_count_) {
                    ++f32_mover_index_lane_;
                    f32_mover_element_position_ = 0U;
                    f32_mover_portal_phase_ =
                        mover_portal_phase::source_read;
                } else if (f32_mover_index_position_ +
                               f32_mover_index_group_count_ <
                           command_.outer_count) {
                    f32_mover_index_position_ +=
                        f32_mover_index_group_count_;
                    f32_mover_index_lane_ = 0U;
                    f32_mover_element_position_ = 0U;
                    f32_mover_portal_phase_ =
                        mover_portal_phase::index_read;
                } else {
                    f32_mover_portal_phase_ = mover_portal_phase::done;
                }
            } else if (f32_mover_repeat_position_ + 1U <
                       command_.scalar0) {
                ++f32_mover_repeat_position_;
            } else if (f32_mover_element_position_ + active_words <
                       command_.element_count) {
                f32_mover_repeat_position_ = 0U;
                f32_mover_element_position_ += active_words;
                f32_mover_portal_phase_ = mover_portal_phase::source_read;
            } else if (f32_mover_outer_position_ + 1U <
                       command_.outer_count) {
                ++f32_mover_outer_position_;
                f32_mover_repeat_position_ = 0U;
                f32_mover_element_position_ = 0U;
                f32_mover_portal_phase_ = mover_portal_phase::source_read;
            } else {
                f32_mover_portal_phase_ = mover_portal_phase::done;
            }
        } else {
            ++f32_mover_read_groups_;
            f32_mover_read_words_ += active_words;
            if (f32_mover_portal_phase_ == mover_portal_phase::index_read) {
                f32_mover_index_group_count_ = active_words;
                f32_mover_index_lane_ = 0U;
                f32_mover_element_position_ = 0U;
                f32_mover_portal_phase_ = mover_portal_phase::source_read;
            } else {
                f32_mover_repeat_position_ = 0U;
                f32_mover_portal_phase_ =
                    mover_portal_phase::destination_write;
            }
        }
        return true;
    }
#endif

    bool prepare_response(response_slot * request) {
        if (request == nullptr || (request->address & 7U) != 0) {
            return fail(exact_runner_request_protocol);
        }
        if (request->write) {
            if (request->wstrb == 0 ||
                (require_f32_halfbeat_wstrb_ &&
                 request->wstrb != 0x0fU &&
                 request->wstrb != 0xf0U) ||
                !beat_in_window(request->address, dst_window_)) {
                return fail(exact_runner_memory_bounds);
            }
            return true;
        }
        if (request->wstrb != 0 || top_->gmem_req_wdata_o != 0) {
            return fail(exact_runner_request_protocol);
        }
        if (require_unique_read_beats_ &&
            !read_beats_seen_.insert(request->address).second) {
            return fail(exact_runner_result_coverage);
        }
        if (src0_.readable && beat_in_window(request->address, src0_)) {
            request->data = load_raw_beat(request->address, src0_);
            ++source_read_requests_[0];
            return true;
        }
        if (src1_.readable && beat_in_window(request->address, src1_)) {
#if defined(NPU_SYSTEM_Q8_PORTAL)
            if (portal_contract_.enabled) {
                // Packed Q8 weights are portal-only in production.  Serving
                // even one weight beat through raw GMEM would hide a routing
                // regression and invalidate both transport ledgers.
                return portal_fail(exact_runner_q8_portal_request);
            }
#endif
            request->data = load_raw_beat(request->address, src1_);
            ++source_read_requests_[1];
            return true;
        }
        if (dst_window_.readable &&
            beat_in_window(request->address, dst_window_)) {
            request->data = load_raw_beat(request->address, dst_window_);
            return true;
        }
        return fail(exact_runner_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        if (!beat_in_window(request.address, dst_window_)) {
            return fail(exact_runner_memory_bounds);
        }
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) == 0) {
                continue;
            }
            const std::uint64_t physical = request.address + lane;
            if (physical < dst_window_.region_base ||
                physical - dst_window_.region_base >=
                    dst_window_.allocation_bytes) {
                return fail(exact_runner_memory_bounds);
            }
            const std::size_t offset = static_cast<std::size_t>(
                physical - dst_window_.region_base);
            if (expected_write_[offset] != 1 || write_seen_[offset] != 0) {
                return fail(exact_runner_result_coverage);
            }
            write_seen_[offset] = 1;
            dst_window_.write_bytes[offset] = static_cast<std::uint8_t>(
                request.data >> (8 * lane));
            ++written_bytes_;
        }
        return true;
    }

    bool reset() {
        top_->rst = 1;
        top_->terminal_allow_i = 1;
        for (unsigned index = 0; index < 10; ++index) {
            if (!tick()) {
                return false;
            }
        }
        if (top_->direct_f32_desc_resident_o != 0 ||
            top_->descriptor_inflight_o != 0 ||
            top_->descriptor_expected_index_o != 0 ||
            top_->launch_cpu_pid_o != 0 ||
            top_->macro_completion_valid_o != 0 ||
            top_->npu_terminal_valid_o != 0 ||
            top_->gmem_req_valid_o != 0 || response_.occupied) {
            return fail(exact_runner_reset_interface);
        }
#if defined(NPU_SYSTEM_Q8_PORTAL)
        if (top_->q8_portal_req_valid_o != 0 ||
            top_->q8_portal_rsp_ready_o != 0 ||
            top_->q8_portal_request_count_o != 0 ||
            top_->q8_portal_response_count_o != 0 ||
            top_->q8_portal_block_count_o != 0 ||
            top_->q8_portal_byte_count_o != 0 ||
            top_->q8_portal_outstanding_o != 0 ||
            portal_response_.occupied) {
            return portal_fail(exact_runner_reset_interface);
        }
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        if (top_->f32_alu_portal_req_valid_o != 0 ||
            top_->f32_alu_portal_rsp_ready_o != 0 ||
            top_->f32_alu_portal_request_groups_o != 0 ||
            top_->f32_alu_portal_response_groups_o != 0 ||
            top_->f32_alu_portal_read_groups_o != 0 ||
            top_->f32_alu_portal_write_groups_o != 0 ||
            top_->f32_alu_portal_input_words_o != 0 ||
            top_->f32_alu_portal_output_words_o != 0 ||
            top_->f32_alu_portal_read_bytes_o != 0 ||
            top_->f32_alu_portal_write_bytes_o != 0 ||
            top_->f32_alu_portal_outstanding_o != 0 ||
            f32_alu_portal_response_.occupied) {
            return f32_alu_portal_fail(exact_runner_reset_interface);
        }
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        if (top_->f32_mover_portal_req_valid_o != 0 ||
            top_->f32_mover_portal_rsp_ready_o != 0 ||
            top_->f32_mover_portal_request_groups_o != 0 ||
            top_->f32_mover_portal_response_groups_o != 0 ||
            top_->f32_mover_portal_read_groups_o != 0 ||
            top_->f32_mover_portal_write_groups_o != 0 ||
            top_->f32_mover_portal_read_words_o != 0 ||
            top_->f32_mover_portal_write_words_o != 0 ||
            top_->f32_mover_portal_read_bytes_o != 0 ||
            top_->f32_mover_portal_write_bytes_o != 0 ||
            top_->f32_mover_portal_outstanding_o != 0 ||
            f32_mover_portal_response_.occupied) {
            return f32_mover_portal_fail(exact_runner_reset_interface);
        }
#endif
        top_->rst = 0;
        top_->eval();
        return true;
    }

    void snapshot_counter_baseline() {
        npu_command_count_before_ = top_->npu_command_count_o;
        npu_completion_count_before_ = top_->npu_completion_count_o;
        npu_error_count_before_ = top_->npu_error_count_o;
        command_count_before_ = top_->npu_macro_command_count_o;
        f32_start_count_before_ = top_->npu_macro_f32_start_count_o;
        completion_count_before_ = top_->npu_macro_completion_count_o;
        required_issued_before_ = top_->npu_required_issued_o;
        required_completed_before_ = top_->npu_required_completed_o;
    }

    bool identity_matches(const completion_snapshot & snapshot) const {
        return snapshot.is_macro == 1 &&
               completion_identity_match_at_accept_ &&
               launch_command_seen_ &&
               snapshot.terminal_producer_id == launch_cpu_pid_ &&
               snapshot.kernel_id == profile_.public_kernel_id &&
               snapshot.command_flags == identity_.command_flags &&
               snapshot.vector_flags == profile_.public_local_profile &&
               snapshot.context_id == identity_.context_id &&
               snapshot.sequence_id == identity_.sequence_id &&
               snapshot.producer_id == identity_.producer_id &&
               snapshot.user_tag == identity_.user_tag &&
               snapshot.covered_node_count == command_.node_count &&
               snapshot.node_hash_lo == identity_.node_hash_lo &&
               snapshot.node_hash_hi == identity_.node_hash_hi;
    }

    void update_required_deltas() {
        result_->required_issued_delta =
            top_->npu_required_issued_o - required_issued_before_;
        result_->required_completed_delta =
            top_->npu_required_completed_o - required_completed_before_;
    }

    void snapshot_result(const completion_snapshot & snapshot) {
        result_snapshot_taken_ = true;
        result_->completion_status = snapshot.status;
        result_->completion_error_class = snapshot.error_class;
        result_->completion_error_code = snapshot.terminal_error_code;
        result_->rtl_cycles = snapshot.npu_cycles;
        result_->system_cycles = clock_cycles_;
        result_->gmem_read_bytes = snapshot.gmem_read_bytes;
        result_->gmem_write_bytes = snapshot.gmem_write_bytes;
        result_->vector_elements = snapshot.vector_element_count;
        result_->q8_mac_count = snapshot.q8_mac_count;
        result_->state_update_count = snapshot.state_update_count;
        result_->f32_start_count =
            top_->npu_macro_f32_start_count_o - f32_start_count_before_;
        result_->commands_accepted =
            top_->npu_macro_command_count_o - command_count_before_;
        result_->commands_terminal_success =
            top_->npu_macro_completion_count_o - completion_count_before_;
        result_->commands_terminal_failure =
            snapshot.terminal_error ? 1 : 0;
        result_->public_commands_accepted =
            top_->npu_command_count_o - npu_command_count_before_;
        result_->public_completions =
            top_->npu_completion_count_o - npu_completion_count_before_;
        result_->public_errors =
            top_->npu_error_count_o - npu_error_count_before_;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        result_->first_request_hold_cycles = first_request_hold_cycles_;
#if defined(NPU_SYSTEM_Q8_PORTAL)
        snapshot_q8_portal_result(snapshot);
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        snapshot_f32_alu_portal_result(snapshot);
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        snapshot_f32_mover_portal_result(snapshot);
#endif
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        snapshot_functional_command_result();
#endif
        result_->cpu_config_commands_accepted =
            cpu_config_commands_accepted_;
        result_->cpu_tensor_commands_accepted =
            cpu_tensor_commands_accepted_;
        result_->cpu_terminals_accepted = cpu_terminals_accepted_;
        result_->cpu_config_commits = cpu_config_commits_;
        result_->cpu_launch_commits = cpu_launch_commits_;
        result_->cpu_launch_pid = launch_cpu_pid_;
        result_->cpu_launch_instruction = launch_commit_instruction_;
        result_->cpu_memory_separate = !cpu_memory_error_;
        result_->cpu_terminal_identity_match = launch_command_seen_ &&
            macro_terminal_fired_ && launch_commit_seen_ &&
            snapshot.terminal_producer_id == launch_cpu_pid_;
        result_->system_transport = true;
        update_required_deltas();
    }

#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    void snapshot_functional_command_result() {
        auto & ledger = result_->functional_command;
        ledger.enabled = functional_command_enabled_;
        ledger.dispatches = functional_dispatches_;
        ledger.completions = functional_completions_;
        ledger.successes = functional_result_seen_ &&
            functional_actual_.success ? 1U : 0U;
        ledger.failures = functional_result_seen_ &&
            !functional_actual_.success ? 1U : 0U;
        ledger.read_words = functional_actual_.read_words;
        ledger.write_words = functional_actual_.write_words;
        ledger.read_bytes = functional_actual_.read_bytes;
        ledger.write_bytes = functional_actual_.write_bytes;
        ledger.q8_blocks = functional_actual_.q8_blocks;
        ledger.q8_mac_count = functional_actual_.q8_mac_count;
        ledger.vector_elements = functional_actual_.vector_elements;
        ledger.expected_read_words = functional_expected_.read_words;
        ledger.expected_write_words = functional_expected_.write_words;
        ledger.expected_read_bytes = functional_expected_.read_bytes;
        ledger.expected_write_bytes = functional_expected_.write_bytes;
        ledger.expected_q8_blocks = functional_expected_.q8_blocks;
        ledger.expected_q8_mac_count =
            functional_expected_.q8_mac_count;
        ledger.expected_vector_elements =
            functional_expected_.vector_elements;
        ledger.callback_read_calls =
            functional_actual_.callback_read_calls;
        ledger.callback_write_calls =
            functional_actual_.callback_write_calls;
        ledger.callback_read_bytes =
            functional_actual_.callback_read_bytes;
        ledger.callback_write_bytes =
            functional_actual_.callback_write_bytes;
        ledger.callback_errors = functional_actual_.callback_errors;
        ledger.command_mismatches = functional_command_mismatches_;
        ledger.protocol_errors = functional_protocol_errors_;
        if (functional_command_enabled_) {
            ledger.old_gmem_requests = gmem_requests_accepted_;
            ledger.old_gmem_responses = gmem_responses_accepted_;
            ledger.old_q8_portal_transactions =
                result_->q8_portal.transactions;
            ledger.old_f32_alu_portal_transactions =
                result_->f32_alu_portal.transactions;
            ledger.old_f32_mover_portal_transactions =
                result_->f32_mover_portal.transactions;
        }
        result_->q8_portal.functional_command = ledger;
        result_->f32_alu_portal.functional_command = ledger;
        result_->f32_mover_portal.functional_command = ledger;
    }

    bool functional_command_ledger_matches(
            const completion_snapshot & snapshot) const {
        if (!functional_command_enabled_) {
            return !functional_result_seen_ &&
                   functional_dispatches_ == 0U &&
                   functional_completions_ == 0U &&
                   functional_command_mismatches_ == 0U;
        }
        const bool success_shape = expected_success_ ?
            (functional_actual_.success &&
             functional_actual_.error_code == 0U &&
             functional_actual_.error_class == 0U &&
             functional_actual_.callback_read_bytes ==
                 functional_actual_.read_bytes &&
             functional_actual_.callback_write_bytes ==
                 functional_actual_.write_bytes) :
            (!functional_actual_.success &&
             functional_actual_.error_code == expected_error_code_ &&
             functional_actual_.error_class == expected_error_class_ &&
             functional_actual_.callback_write_bytes == 0U &&
             functional_actual_.callback_read_bytes <=
                 functional_actual_.read_bytes);
        return functional_result_seen_ && functional_dispatches_ == 1U &&
               functional_completions_ == 1U &&
               functional_command_mismatches_ == 0U &&
               functional_actual_.callback_errors == 0U && success_shape &&
               functional_actual_.read_words ==
                   functional_expected_.read_words &&
               functional_actual_.write_words ==
                   functional_expected_.write_words &&
               functional_actual_.read_bytes ==
                   functional_expected_.read_bytes &&
               functional_actual_.write_bytes ==
                   functional_expected_.write_bytes &&
               functional_actual_.q8_blocks ==
                   functional_expected_.q8_blocks &&
               functional_actual_.q8_mac_count ==
                   functional_expected_.q8_mac_count &&
               functional_actual_.vector_elements ==
                   functional_expected_.vector_elements &&
               snapshot.gmem_read_bytes == functional_actual_.read_bytes &&
               snapshot.gmem_write_bytes == functional_actual_.write_bytes &&
               snapshot.q8_mac_count ==
                   functional_actual_.q8_mac_count &&
               snapshot.vector_element_count ==
                   functional_actual_.vector_elements &&
               gmem_requests_accepted_ == 0U &&
               gmem_responses_accepted_ == 0U;
    }
#endif

    bool first_request_hold_matches() const {
        std::uint64_t expected_requests = 0;
        return checked_add(
                   profile_.expected_read_requests,
                   profile_.expected_write_requests, &expected_requests) &&
               first_request_hold_cycles_ ==
                   (expected_requests == 0 ? 0U : 1U);
    }

#if defined(NPU_SYSTEM_Q8_PORTAL)
    void snapshot_q8_portal_result(const completion_snapshot & snapshot) {
        result_->q8_portal.transactions =
            portal_contract_.enabled ? 1U : 0U;
        result_->q8_portal.request_groups =
            snapshot.q8_portal_request_count;
        result_->q8_portal.response_groups =
            snapshot.q8_portal_response_count;
        result_->q8_portal.blocks = snapshot.q8_portal_block_count;
        result_->q8_portal.bytes = snapshot.q8_portal_byte_count;
        result_->q8_portal.raw_copy_bytes = portal_raw_copy_bytes_;
        result_->q8_portal.first_request_hold_cycles =
            first_portal_request_hold_cycles_;
        result_->q8_portal.expected_request_groups =
            portal_contract_.expected_request_groups;
        result_->q8_portal.expected_blocks =
            portal_contract_.expected_blocks;
        result_->q8_portal.expected_bytes =
            portal_contract_.expected_bytes;
        result_->q8_portal.protocol_errors = portal_protocol_errors_;
        result_->q8_portal.latency_mismatches =
            portal_latency_mismatches_;
        result_->q8_portal.payload_stability_mismatches =
            portal_payload_stability_mismatches_;
    }

    bool q8_portal_matches(const completion_snapshot & snapshot) const {
        if (!portal_contract_.enabled) {
            return snapshot.q8_portal_request_count == 0U &&
                   snapshot.q8_portal_response_count == 0U &&
                   snapshot.q8_portal_block_count == 0U &&
                   snapshot.q8_portal_byte_count == 0U &&
                   snapshot.q8_portal_outstanding == 0U &&
                   portal_request_groups_ == 0U &&
                   portal_response_groups_ == 0U &&
                   portal_blocks_copied_ == 0U &&
                   portal_raw_copy_bytes_ == 0U &&
                   first_portal_request_hold_cycles_ == 0U &&
                   portal_protocol_errors_ == 0U &&
                   portal_latency_mismatches_ == 0U &&
                   portal_payload_stability_mismatches_ == 0U;
        }
        return snapshot.q8_portal_request_count ==
                   portal_contract_.expected_request_groups &&
               snapshot.q8_portal_response_count ==
                   portal_contract_.expected_request_groups &&
               snapshot.q8_portal_block_count ==
                   portal_contract_.expected_blocks &&
               snapshot.q8_portal_byte_count ==
                   portal_contract_.expected_bytes &&
               snapshot.q8_portal_outstanding == 0U &&
               portal_request_groups_ ==
                   portal_contract_.expected_request_groups &&
               portal_response_groups_ ==
                   portal_contract_.expected_request_groups &&
               portal_blocks_copied_ == portal_contract_.expected_blocks &&
               portal_raw_copy_bytes_ == portal_contract_.expected_bytes &&
               first_portal_request_hold_cycles_ ==
                   (portal_contract_.expected_request_groups == 0U ? 0U : 1U) &&
               portal_expected_block_index_ == 0U &&
               portal_expected_row_base_ >= command_.outer_count &&
               portal_protocol_errors_ == 0U &&
               portal_latency_mismatches_ == 0U &&
               portal_payload_stability_mismatches_ == 0U;
    }
#endif

#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    void snapshot_f32_alu_portal_result(
            const completion_snapshot & snapshot) {
        auto & portal = result_->f32_alu_portal;
        portal.transactions =
            f32_alu_portal_contract_.enabled ? 1U : 0U;
        portal.request_groups = snapshot.f32_alu_portal_request_groups;
        portal.response_groups = snapshot.f32_alu_portal_response_groups;
        portal.read_groups = snapshot.f32_alu_portal_read_groups;
        portal.write_groups = snapshot.f32_alu_portal_write_groups;
        portal.read_words = snapshot.f32_alu_portal_input_words;
        portal.write_words = snapshot.f32_alu_portal_output_words;
        portal.read_bytes = snapshot.f32_alu_portal_read_bytes;
        portal.write_bytes = snapshot.f32_alu_portal_write_bytes;
        portal.raw_read_copy_bytes = f32_alu_raw_read_copy_bytes_;
        portal.raw_write_copy_bytes = f32_alu_raw_write_copy_bytes_;
        portal.first_request_hold_cycles =
            f32_alu_first_request_hold_cycles_;
        portal.expected_request_groups =
            f32_alu_portal_contract_.expected_request_groups;
        portal.expected_response_groups =
            f32_alu_portal_contract_.expected_response_groups;
        portal.expected_read_groups =
            f32_alu_portal_contract_.expected_read_groups;
        portal.expected_write_groups =
            f32_alu_portal_contract_.expected_write_groups;
        portal.expected_read_words =
            f32_alu_portal_contract_.expected_read_words;
        portal.expected_write_words =
            f32_alu_portal_contract_.expected_write_words;
        portal.expected_read_bytes =
            f32_alu_portal_contract_.expected_read_bytes;
        portal.expected_write_bytes =
            f32_alu_portal_contract_.expected_write_bytes;
        portal.protocol_errors = f32_alu_protocol_errors_;
        portal.latency_mismatches = f32_alu_latency_mismatches_;
        portal.payload_stability_mismatches =
            f32_alu_payload_stability_mismatches_;
    }

    bool f32_alu_portal_matches(
            const completion_snapshot & snapshot) const {
        if (!f32_alu_portal_contract_.enabled) {
            return snapshot.f32_alu_portal_request_groups == 0U &&
                   snapshot.f32_alu_portal_response_groups == 0U &&
                   snapshot.f32_alu_portal_read_groups == 0U &&
                   snapshot.f32_alu_portal_write_groups == 0U &&
                   snapshot.f32_alu_portal_input_words == 0U &&
                   snapshot.f32_alu_portal_output_words == 0U &&
                   snapshot.f32_alu_portal_read_bytes == 0U &&
                   snapshot.f32_alu_portal_write_bytes == 0U &&
                   snapshot.f32_alu_portal_outstanding == 0U &&
                   f32_alu_request_groups_ == 0U &&
                   f32_alu_response_groups_ == 0U &&
                   f32_alu_raw_read_copy_bytes_ == 0U &&
                   f32_alu_raw_write_copy_bytes_ == 0U &&
                   f32_alu_first_request_hold_cycles_ == 0U &&
                   f32_alu_protocol_errors_ == 0U &&
                   f32_alu_latency_mismatches_ == 0U &&
                   f32_alu_payload_stability_mismatches_ == 0U;
        }
        return snapshot.f32_alu_portal_request_groups ==
                   f32_alu_portal_contract_.expected_request_groups &&
               snapshot.f32_alu_portal_response_groups ==
                   f32_alu_portal_contract_.expected_response_groups &&
               snapshot.f32_alu_portal_read_groups ==
                   f32_alu_portal_contract_.expected_read_groups &&
               snapshot.f32_alu_portal_write_groups ==
                   f32_alu_portal_contract_.expected_write_groups &&
               snapshot.f32_alu_portal_input_words ==
                   f32_alu_portal_contract_.expected_read_words &&
               snapshot.f32_alu_portal_output_words ==
                   f32_alu_portal_contract_.expected_write_words &&
               snapshot.f32_alu_portal_read_bytes ==
                   f32_alu_portal_contract_.expected_read_bytes &&
               snapshot.f32_alu_portal_write_bytes ==
                   f32_alu_portal_contract_.expected_write_bytes &&
               snapshot.f32_alu_portal_outstanding == 0U &&
               f32_alu_request_groups_ ==
                   f32_alu_portal_contract_.expected_request_groups &&
               f32_alu_response_groups_ ==
                   f32_alu_portal_contract_.expected_response_groups &&
               f32_alu_read_groups_ ==
                   f32_alu_portal_contract_.expected_read_groups &&
               f32_alu_write_groups_ ==
                   f32_alu_portal_contract_.expected_write_groups &&
               f32_alu_read_words_ ==
                   f32_alu_portal_contract_.expected_read_words &&
               f32_alu_write_words_ ==
                   f32_alu_portal_contract_.expected_write_words &&
               f32_alu_raw_read_copy_bytes_ ==
                   f32_alu_portal_contract_.expected_read_bytes &&
               f32_alu_raw_write_copy_bytes_ ==
                   f32_alu_portal_contract_.expected_write_bytes &&
               f32_alu_first_request_hold_cycles_ ==
                   (f32_alu_portal_contract_.expected_request_groups == 0U ?
                        0U : 1U) &&
               f32_alu_batch_base_ >=
                   f32_alu_portal_contract_.expected_write_words &&
               !f32_alu_expect_write_ &&
               f32_alu_protocol_errors_ == 0U &&
               f32_alu_latency_mismatches_ == 0U &&
               f32_alu_payload_stability_mismatches_ == 0U;
    }
#endif

#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    void snapshot_f32_mover_portal_result(
            const completion_snapshot & snapshot) {
        auto & portal = result_->f32_mover_portal;
        portal.transactions =
            f32_mover_portal_contract_.enabled ? 1U : 0U;
        portal.request_groups = snapshot.f32_mover_portal_request_groups;
        portal.response_groups = snapshot.f32_mover_portal_response_groups;
        portal.read_groups = snapshot.f32_mover_portal_read_groups;
        portal.write_groups = snapshot.f32_mover_portal_write_groups;
        portal.read_words = snapshot.f32_mover_portal_read_words;
        portal.write_words = snapshot.f32_mover_portal_write_words;
        portal.read_bytes = snapshot.f32_mover_portal_read_bytes;
        portal.write_bytes = snapshot.f32_mover_portal_write_bytes;
        portal.raw_read_copy_bytes = f32_mover_raw_read_copy_bytes_;
        portal.raw_write_copy_bytes = f32_mover_raw_write_copy_bytes_;
        portal.first_request_hold_cycles =
            f32_mover_first_request_hold_cycles_;
        portal.expected_request_groups =
            f32_mover_portal_contract_.expected_request_groups;
        portal.expected_response_groups =
            f32_mover_portal_contract_.expected_response_groups;
        portal.expected_read_groups =
            f32_mover_portal_contract_.expected_read_groups;
        portal.expected_write_groups =
            f32_mover_portal_contract_.expected_write_groups;
        portal.expected_read_words =
            f32_mover_portal_contract_.expected_read_words;
        portal.expected_write_words =
            f32_mover_portal_contract_.expected_write_words;
        portal.expected_read_bytes =
            f32_mover_portal_contract_.expected_read_bytes;
        portal.expected_write_bytes =
            f32_mover_portal_contract_.expected_write_bytes;
        portal.protocol_errors = f32_mover_protocol_errors_;
        portal.latency_mismatches = f32_mover_latency_mismatches_;
        portal.payload_stability_mismatches =
            f32_mover_payload_stability_mismatches_;
    }

    bool f32_mover_portal_matches(
            const completion_snapshot & snapshot) const {
        if (!f32_mover_portal_contract_.enabled) {
            return snapshot.f32_mover_portal_request_groups == 0U &&
                   snapshot.f32_mover_portal_response_groups == 0U &&
                   snapshot.f32_mover_portal_read_groups == 0U &&
                   snapshot.f32_mover_portal_write_groups == 0U &&
                   snapshot.f32_mover_portal_read_words == 0U &&
                   snapshot.f32_mover_portal_write_words == 0U &&
                   snapshot.f32_mover_portal_read_bytes == 0U &&
                   snapshot.f32_mover_portal_write_bytes == 0U &&
                   snapshot.f32_mover_portal_outstanding == 0U &&
                   f32_mover_request_groups_ == 0U &&
                   f32_mover_response_groups_ == 0U &&
                   f32_mover_raw_read_copy_bytes_ == 0U &&
                   f32_mover_raw_write_copy_bytes_ == 0U &&
                   f32_mover_first_request_hold_cycles_ == 0U &&
                   f32_mover_protocol_errors_ == 0U &&
                   f32_mover_latency_mismatches_ == 0U &&
                   f32_mover_payload_stability_mismatches_ == 0U;
        }
        return snapshot.f32_mover_portal_request_groups ==
                   f32_mover_portal_contract_.expected_request_groups &&
               snapshot.f32_mover_portal_response_groups ==
                   f32_mover_portal_contract_.expected_response_groups &&
               snapshot.f32_mover_portal_read_groups ==
                   f32_mover_portal_contract_.expected_read_groups &&
               snapshot.f32_mover_portal_write_groups ==
                   f32_mover_portal_contract_.expected_write_groups &&
               snapshot.f32_mover_portal_read_words ==
                   f32_mover_portal_contract_.expected_read_words &&
               snapshot.f32_mover_portal_write_words ==
                   f32_mover_portal_contract_.expected_write_words &&
               snapshot.f32_mover_portal_read_bytes ==
                   f32_mover_portal_contract_.expected_read_bytes &&
               snapshot.f32_mover_portal_write_bytes ==
                   f32_mover_portal_contract_.expected_write_bytes &&
               snapshot.f32_mover_portal_outstanding == 0U &&
               f32_mover_request_groups_ ==
                   f32_mover_portal_contract_.expected_request_groups &&
               f32_mover_response_groups_ ==
                   f32_mover_portal_contract_.expected_response_groups &&
               f32_mover_read_groups_ ==
                   f32_mover_portal_contract_.expected_read_groups &&
               f32_mover_write_groups_ ==
                   f32_mover_portal_contract_.expected_write_groups &&
               f32_mover_read_words_ ==
                   f32_mover_portal_contract_.expected_read_words &&
               f32_mover_write_words_ ==
                   f32_mover_portal_contract_.expected_write_words &&
               f32_mover_raw_read_copy_bytes_ ==
                   f32_mover_portal_contract_.expected_read_bytes &&
               f32_mover_raw_write_copy_bytes_ ==
                   f32_mover_portal_contract_.expected_write_bytes &&
               f32_mover_first_request_hold_cycles_ ==
                   (f32_mover_portal_contract_.expected_request_groups == 0U ?
                        0U : 1U) &&
               (!expected_success_ ||
                f32_mover_portal_phase_ == mover_portal_phase::done) &&
               f32_mover_protocol_errors_ == 0U &&
               f32_mover_latency_mismatches_ == 0U &&
               f32_mover_payload_stability_mismatches_ == 0U;
    }
#endif

    bool validate_terminal(const completion_snapshot & snapshot) const {
        std::uint64_t expected_requests = 0;
        return checked_add(
                   profile_.expected_read_requests,
                   profile_.expected_write_requests, &expected_requests) &&
               snapshot.terminal_error == (expected_success_ ? 0U : 1U) &&
               snapshot.status == expected_status_ &&
               snapshot.terminal_error_code == expected_error_code_ &&
               snapshot.error_class == expected_error_class_ &&
               result_->commands_accepted == 1 &&
               result_->commands_terminal_success ==
                   expected_macro_completions_ &&
               result_->commands_terminal_failure ==
                   (expected_success_ ? 0U : 1U) &&
               result_->public_commands_accepted == 1 &&
               result_->public_completions ==
                   expected_public_completions_ &&
               result_->public_errors == expected_public_errors_ &&
               result_->required_issued_delta ==
                   expected_required_issued_ &&
               result_->required_completed_delta ==
                   expected_required_completed_ &&
               (!validate_f32_starts_ ||
                result_->f32_start_count == expected_f32_starts_) &&
               result_->cpu_config_commands_accepted == 30 &&
               result_->cpu_tensor_commands_accepted == 31 &&
               result_->cpu_terminals_accepted == 31 &&
               result_->cpu_config_commits == 30 &&
               result_->cpu_launch_commits == 1 &&
               result_->cpu_launch_instruction == kLaunchLo &&
               result_->cpu_memory_separate &&
               result_->cpu_terminal_identity_match &&
               result_->system_transport &&
               cpu_commit_callbacks_ >= 31 &&
               !cpu_memory_error_ && !cpu_write_observed_ &&
               !cpu_trap_observed_ &&
               result_->gmem_requests_accepted == expected_requests &&
               result_->gmem_responses_accepted == expected_requests &&
               (!require_unique_read_beats_ ||
                read_beats_seen_.size() ==
                    profile_.expected_read_requests) &&
               (!validate_source_read_requests_ ||
                source_read_requests_ ==
                    expected_source_read_requests_) &&
               snapshot.gmem_read_bytes == profile_.expected_read_bytes &&
               snapshot.gmem_write_bytes == profile_.expected_write_bytes &&
               snapshot.q8_mac_count == profile_.expected_q8_macs &&
               snapshot.vector_element_count == profile_.expected_elements &&
               snapshot.state_update_count ==
                   profile_.expected_state_updates &&
               snapshot.npu_cycles > 0 &&
               snapshot.npu_cycles <= profile_.cycle_upper_bound &&
               written_bytes_ == expected_semantic_written_bytes_ &&
               (expected_requests == 0 || request_hold_observed_);
    }

    bool recover_after_accepted_completion() {
        if (!completion_snapshot_seen_ ||
            !result_->completion_accepted || !macro_terminal_fired_ ||
            top_->terminal_allow_i == 0) {
            return false;
        }
        while (!launch_commit_seen_) {
            if (!tick()) {
                return false;
            }
        }
        update_required_deltas();
        result_->recovery_clean =
            result_->required_issued_delta == expected_required_issued_ &&
            result_->required_completed_delta ==
                expected_required_completed_ &&
            top_->macro_completion_valid_o == 0 &&
            top_->npu_terminal_valid_o == 0 &&
            top_->descriptor_inflight_o == 0 &&
            top_->direct_f32_desc_resident_o == 0 &&
            top_->descriptor_expected_index_o == 0 &&
            top_->launch_cpu_pid_o == 0 &&
            top_->gmem_req_valid_o == 0 &&
            top_->gmem_rsp_ready_o == 0 && !response_.occupied
#if defined(NPU_SYSTEM_Q8_PORTAL)
            && top_->q8_portal_req_valid_o == 0
            && top_->q8_portal_rsp_ready_o == 0
            && top_->q8_portal_outstanding_o == 0
            && !portal_response_.occupied
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
            && top_->f32_alu_portal_req_valid_o == 0
            && top_->f32_alu_portal_rsp_ready_o == 0
            && top_->f32_alu_portal_outstanding_o == 0
            && !f32_alu_portal_response_.occupied
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
            && top_->f32_mover_portal_req_valid_o == 0
            && top_->f32_mover_portal_rsp_ready_o == 0
            && top_->f32_mover_portal_outstanding_o == 0
            && !f32_mover_portal_response_.occupied
#endif
            ;
        return result_->recovery_clean;
    }

#if defined(NPU_SYSTEM_Q8_PORTAL)
    void snapshot_q8_portal_failure_result() {
        result_->q8_portal.transactions =
            portal_contract_.enabled ? 1U : 0U;
        result_->q8_portal.request_groups = portal_request_groups_;
        result_->q8_portal.response_groups = portal_response_groups_;
        result_->q8_portal.blocks = portal_blocks_copied_;
        result_->q8_portal.bytes = portal_raw_copy_bytes_;
        result_->q8_portal.raw_copy_bytes = portal_raw_copy_bytes_;
        result_->q8_portal.first_request_hold_cycles =
            first_portal_request_hold_cycles_;
        result_->q8_portal.expected_request_groups =
            portal_contract_.expected_request_groups;
        result_->q8_portal.expected_blocks =
            portal_contract_.expected_blocks;
        result_->q8_portal.expected_bytes =
            portal_contract_.expected_bytes;
        result_->q8_portal.protocol_errors = portal_protocol_errors_;
        result_->q8_portal.latency_mismatches =
            portal_latency_mismatches_;
        result_->q8_portal.payload_stability_mismatches =
            portal_payload_stability_mismatches_;
    }

    bool portal_fail(std::uint32_t error_code) {
        ++portal_protocol_errors_;
        return fail(error_code);
    }
#endif

#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    void snapshot_f32_alu_portal_failure_result() {
        auto & portal = result_->f32_alu_portal;
        portal.transactions =
            f32_alu_portal_contract_.enabled ? 1U : 0U;
        portal.request_groups = f32_alu_request_groups_;
        portal.response_groups = f32_alu_response_groups_;
        portal.read_groups = f32_alu_read_groups_;
        portal.write_groups = f32_alu_write_groups_;
        portal.read_words = f32_alu_read_words_;
        portal.write_words = f32_alu_write_words_;
        portal.read_bytes = f32_alu_raw_read_copy_bytes_;
        portal.write_bytes = f32_alu_raw_write_copy_bytes_;
        portal.raw_read_copy_bytes = f32_alu_raw_read_copy_bytes_;
        portal.raw_write_copy_bytes = f32_alu_raw_write_copy_bytes_;
        portal.first_request_hold_cycles =
            f32_alu_first_request_hold_cycles_;
        portal.expected_request_groups =
            f32_alu_portal_contract_.expected_request_groups;
        portal.expected_response_groups =
            f32_alu_portal_contract_.expected_response_groups;
        portal.expected_read_groups =
            f32_alu_portal_contract_.expected_read_groups;
        portal.expected_write_groups =
            f32_alu_portal_contract_.expected_write_groups;
        portal.expected_read_words =
            f32_alu_portal_contract_.expected_read_words;
        portal.expected_write_words =
            f32_alu_portal_contract_.expected_write_words;
        portal.expected_read_bytes =
            f32_alu_portal_contract_.expected_read_bytes;
        portal.expected_write_bytes =
            f32_alu_portal_contract_.expected_write_bytes;
        portal.protocol_errors = f32_alu_protocol_errors_;
        portal.latency_mismatches = f32_alu_latency_mismatches_;
        portal.payload_stability_mismatches =
            f32_alu_payload_stability_mismatches_;
    }

    bool f32_alu_portal_fail(std::uint32_t error_code) {
        ++f32_alu_protocol_errors_;
        return fail(error_code);
    }
#endif

#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    void snapshot_f32_mover_portal_failure_result() {
        auto & portal = result_->f32_mover_portal;
        portal.transactions =
            f32_mover_portal_contract_.enabled ? 1U : 0U;
        portal.request_groups = f32_mover_request_groups_;
        portal.response_groups = f32_mover_response_groups_;
        portal.read_groups = f32_mover_read_groups_;
        portal.write_groups = f32_mover_write_groups_;
        portal.read_words = f32_mover_read_words_;
        portal.write_words = f32_mover_write_words_;
        portal.read_bytes = f32_mover_raw_read_copy_bytes_;
        portal.write_bytes = f32_mover_raw_write_copy_bytes_;
        portal.raw_read_copy_bytes = f32_mover_raw_read_copy_bytes_;
        portal.raw_write_copy_bytes = f32_mover_raw_write_copy_bytes_;
        portal.first_request_hold_cycles =
            f32_mover_first_request_hold_cycles_;
        portal.expected_request_groups =
            f32_mover_portal_contract_.expected_request_groups;
        portal.expected_response_groups =
            f32_mover_portal_contract_.expected_response_groups;
        portal.expected_read_groups =
            f32_mover_portal_contract_.expected_read_groups;
        portal.expected_write_groups =
            f32_mover_portal_contract_.expected_write_groups;
        portal.expected_read_words =
            f32_mover_portal_contract_.expected_read_words;
        portal.expected_write_words =
            f32_mover_portal_contract_.expected_write_words;
        portal.expected_read_bytes =
            f32_mover_portal_contract_.expected_read_bytes;
        portal.expected_write_bytes =
            f32_mover_portal_contract_.expected_write_bytes;
        portal.protocol_errors = f32_mover_protocol_errors_;
        portal.latency_mismatches = f32_mover_latency_mismatches_;
        portal.payload_stability_mismatches =
            f32_mover_payload_stability_mismatches_;
    }

    bool f32_mover_portal_fail(std::uint32_t error_code) {
        ++f32_mover_protocol_errors_;
        return fail(error_code);
    }
#endif

    bool fail(std::uint32_t error_code) {
        // A terminal already accepted from SystemTop is real execution
        // evidence even when a subsequent recovery or contract check fails.
        // Preserve that sampled lifecycle/identity/counter payload instead of
        // collapsing the result back to an all-zero pre-dispatch failure.
        if (!result_snapshot_taken_ && completion_snapshot_seen_ &&
            result_->completion_accepted) {
            snapshot_result(accepted_snapshot_);
        }
        result_->passed = false;
        result_->runner_error_code = error_code;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        result_->first_request_hold_cycles = first_request_hold_cycles_;
#if defined(NPU_SYSTEM_Q8_PORTAL)
        snapshot_q8_portal_failure_result();
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
        snapshot_f32_alu_portal_failure_result();
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
        snapshot_f32_mover_portal_failure_result();
#endif
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
        snapshot_functional_command_result();
#endif
        return false;
    }

    npu_exact_profile profile_;
    npu_macro_identity identity_;
    std::array<npu_exact_raw_allocation, 3> sources_;
    npu_exact_private_destination * dst_;
    npu_verilator_exact_result * result_;
    dpi_scope_guard dpi_guard_;
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    npu_functional_command_scope functional_scope_;
#endif
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VNpcTensorNpuSystemTop> top_;
    npu_exact_command_contract command_ = {};
    std::array<std::uint64_t, 30> descriptor_words_ = {};
    std::array<std::uint8_t, 31> command_pids_ = {};
    std::array<bool, 30> config_commit_seen_ = {};
    std::array<std::uint8_t, kCpuBytes> cpu_memory_ = {};
    raw_window src0_ = {};
    raw_window src1_ = {};
    raw_window dst_window_ = {};
    std::vector<std::uint8_t> expected_write_;
    std::vector<std::uint8_t> write_seen_;
    std::unordered_set<std::uint64_t> read_beats_seen_;
    std::array<std::uint64_t, 2> source_read_requests_ = {};
    std::array<std::uint64_t, 2> expected_source_read_requests_ = {};
    response_slot response_ = {};
#if defined(NPU_SYSTEM_Q8_PORTAL)
    portal_response_slot portal_response_ = {};
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    f32_alu_portal_response_slot f32_alu_portal_response_ = {};
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    f32_mover_portal_response_slot f32_mover_portal_response_ = {};
#endif
    npu_system_q8_portal_contract portal_contract_ = {};
    npu_system_raw32_portal_contract f32_alu_portal_contract_ = {};
    npu_system_raw32_portal_contract f32_mover_portal_contract_ = {};
    completion_snapshot accepted_snapshot_ = {};
    bool inputs_valid_ = false;
    bool unaccepted_request_held_ = false;
    bool first_request_hold_pending_ = true;
    bool request_hold_observed_ = false;
#if defined(NPU_SYSTEM_Q8_PORTAL)
    bool first_portal_request_hold_pending_ = false;
    bool portal_request_held_ = false;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    bool f32_alu_first_request_hold_pending_ = false;
    bool f32_alu_request_held_ = false;
    bool f32_alu_held_write_ = false;
    bool f32_alu_expect_write_ = false;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    bool f32_mover_first_request_hold_pending_ = false;
    bool f32_mover_request_held_ = false;
    bool f32_mover_held_write_ = false;
    bool f32_mover_get_rows_ = false;
#endif
    bool cpu_memory_error_ = false;
    bool cpu_write_observed_ = false;
    bool cpu_trap_observed_ = false;
    bool launch_command_seen_ = false;
    bool completion_snapshot_seen_ = false;
    bool completion_identity_match_at_accept_ = false;
    bool macro_terminal_fired_ = false;
    bool launch_commit_seen_ = false;
    bool expected_success_ = true;
    bool validate_f32_starts_ = false;
    bool require_unique_read_beats_ = false;
    bool require_f32_halfbeat_wstrb_ = false;
    bool validate_source_read_requests_ = false;
    std::uint32_t held_request_write_ = 0;
    std::uint32_t first_request_hold_cycles_ = 0;
    std::uint64_t held_request_address_ = 0;
    std::uint64_t held_request_data_ = 0;
    std::uint32_t held_request_wstrb_ = 0;
    std::uint32_t set_slot_ = 0;
    std::uint32_t input_error_code_ = exact_runner_profile;
    std::uint64_t written_bytes_ = 0;
    std::uint64_t expected_semantic_written_bytes_ = 0;
    std::uint64_t clock_cycles_ = 0;
    std::uint64_t cpu_cycle_counter_ = 0;
    std::uint64_t cpu_commit_callbacks_ = 0;
    std::uint64_t cpu_config_commands_accepted_ = 0;
    std::uint64_t cpu_tensor_commands_accepted_ = 0;
    std::uint64_t cpu_terminals_accepted_ = 0;
    std::uint64_t cpu_config_commits_ = 0;
    std::uint64_t cpu_launch_commits_ = 0;
    std::uint64_t gmem_requests_accepted_ = 0;
    std::uint64_t gmem_responses_accepted_ = 0;
#if defined(NPU_SYSTEM_Q8_PORTAL)
    std::uint32_t held_portal_request_mask_ = 0;
    std::uint32_t portal_prepare_error_code_ =
        exact_runner_q8_portal_request;
    std::array<std::uint64_t, kQ8PortalRowLanes>
        held_portal_request_addresses_ = {};
    std::uint64_t portal_expected_row_base_ = 0;
    std::uint64_t portal_expected_block_index_ = 0;
    std::uint64_t portal_request_groups_ = 0;
    std::uint64_t portal_response_groups_ = 0;
    std::uint64_t portal_blocks_copied_ = 0;
    std::uint64_t portal_raw_copy_bytes_ = 0;
    std::uint64_t first_portal_request_hold_cycles_ = 0;
    std::uint64_t portal_protocol_errors_ = 0;
    std::uint64_t portal_latency_mismatches_ = 0;
    std::uint64_t portal_payload_stability_mismatches_ = 0;
#endif
#if defined(NPU_SYSTEM_F32_ALU_PORTAL)
    npu_f32_alu_profile f32_alu_profile_ = {};
    std::uint32_t f32_alu_held_mask_ = 0;
    std::array<std::uint64_t, kF32AluPortalLanes>
        f32_alu_held_src0_ = {};
    std::array<std::uint64_t, kF32AluPortalLanes>
        f32_alu_held_src1_ = {};
    std::array<std::uint64_t, kF32AluPortalLanes>
        f32_alu_held_dst_ = {};
    std::array<std::uint32_t, kF32AluPortalLanes>
        f32_alu_held_wdata_ = {};
    std::uint64_t f32_alu_batch_base_ = 0;
    std::uint64_t f32_alu_request_groups_ = 0;
    std::uint64_t f32_alu_response_groups_ = 0;
    std::uint64_t f32_alu_read_groups_ = 0;
    std::uint64_t f32_alu_write_groups_ = 0;
    std::uint64_t f32_alu_read_words_ = 0;
    std::uint64_t f32_alu_write_words_ = 0;
    std::uint64_t f32_alu_raw_read_copy_bytes_ = 0;
    std::uint64_t f32_alu_raw_write_copy_bytes_ = 0;
    std::uint64_t f32_alu_first_request_hold_cycles_ = 0;
    std::uint64_t f32_alu_protocol_errors_ = 0;
    std::uint64_t f32_alu_latency_mismatches_ = 0;
    std::uint64_t f32_alu_payload_stability_mismatches_ = 0;
#endif
#if defined(NPU_SYSTEM_F32_MOVER_PORTAL)
    mover_portal_phase f32_mover_portal_phase_ =
        mover_portal_phase::done;
    std::uint32_t f32_mover_held_mask_ = 0;
    std::array<std::uint64_t, kF32MoverPortalLanes>
        f32_mover_held_address_ = {};
    std::array<std::uint32_t, kF32MoverPortalLanes>
        f32_mover_held_wdata_ = {};
    std::uint64_t f32_mover_index_position_ = 0;
    std::uint64_t f32_mover_index_lane_ = 0;
    std::uint64_t f32_mover_index_group_count_ = 0;
    std::uint64_t f32_mover_element_position_ = 0;
    std::uint64_t f32_mover_outer_position_ = 0;
    std::uint64_t f32_mover_repeat_position_ = 0;
    std::uint64_t f32_mover_request_groups_ = 0;
    std::uint64_t f32_mover_response_groups_ = 0;
    std::uint64_t f32_mover_read_groups_ = 0;
    std::uint64_t f32_mover_write_groups_ = 0;
    std::uint64_t f32_mover_read_words_ = 0;
    std::uint64_t f32_mover_write_words_ = 0;
    std::uint64_t f32_mover_raw_read_copy_bytes_ = 0;
    std::uint64_t f32_mover_raw_write_copy_bytes_ = 0;
    std::uint64_t f32_mover_first_request_hold_cycles_ = 0;
    std::uint64_t f32_mover_protocol_errors_ = 0;
    std::uint64_t f32_mover_latency_mismatches_ = 0;
    std::uint64_t f32_mover_payload_stability_mismatches_ = 0;
#endif
    std::uint64_t npu_command_count_before_ = 0;
    std::uint64_t npu_completion_count_before_ = 0;
    std::uint64_t npu_error_count_before_ = 0;
    std::uint64_t command_count_before_ = 0;
    std::uint64_t f32_start_count_before_ = 0;
    std::uint64_t completion_count_before_ = 0;
    std::uint64_t required_issued_before_ = 0;
    std::uint64_t required_completed_before_ = 0;
    std::uint64_t expected_f32_starts_ = 0;
    std::uint64_t expected_required_issued_ = 0;
    std::uint64_t expected_required_completed_ = 0;
    std::uint64_t expected_public_completions_ = 0;
    std::uint64_t expected_public_errors_ = 0;
    std::uint64_t expected_macro_completions_ = 0;
    std::uint32_t expected_status_ = 0;
    std::uint32_t expected_error_class_ = 0;
    std::uint32_t expected_error_code_ = 0;
    npu_system_reject_contract reject_contract_ = {};
#if defined(NPU_SYSTEM_FUNCTIONAL_COMMAND)
    npu_functional_command_result functional_expected_ = {};
    npu_functional_command_result functional_actual_ = {};
    bool functional_contract_prepared_ = false;
    bool functional_command_enabled_ = false;
    bool functional_result_seen_ = false;
    std::uint64_t functional_dispatches_ = 0;
    std::uint64_t functional_completions_ = 0;
    std::uint64_t functional_command_mismatches_ = 0;
    std::uint64_t functional_protocol_errors_ = 0;
#endif
    bool result_snapshot_taken_ = false;
    std::uint32_t launch_commit_instruction_ = 0;
    std::uint8_t launch_cpu_pid_ = 0;
};

} // namespace

bool npu_exact_finalize_profile(npu_exact_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    npu_exact_profile candidate = *profile;
    if (!resolve_public_route(&candidate) ||
        !validate_profile_metadata(candidate) ||
        !derive_expected_counters(&candidate)) {
        return false;
    }
    std::uint64_t outer = 1;
    for (std::size_t dimension = 1; dimension < 4; ++dimension) {
        if (candidate.dst.ne[dimension] < 0 ||
            !checked_mul(
                outer,
                static_cast<std::uint64_t>(candidate.dst.ne[dimension]),
                &outer)) {
            return false;
        }
    }
    if (candidate.dst.ne[0] < 0 ||
        outer > std::numeric_limits<std::uint32_t>::max()) {
        return false;
    }
    *profile = candidate;
    return true;
}

bool npu_exact_build_command_contract(
        const npu_exact_profile * profile,
        const npu_macro_identity * canonical_identity,
        std::uint32_t set_rows_slot,
        const std::array<std::size_t, 3> * source_backing_bytes,
        std::size_t dst_backing_bytes,
        npu_exact_command_contract * command) {
    if (profile == nullptr || canonical_identity == nullptr ||
        source_backing_bytes == nullptr || command == nullptr) {
        return false;
    }
    npu_exact_profile checked = *profile;
    if (!npu_exact_finalize_profile(&checked) ||
        checked.public_kernel_id != profile->public_kernel_id ||
        checked.public_vector_op != profile->public_vector_op ||
        checked.public_local_profile != profile->public_local_profile ||
        canonical_identity->profile_id != checked.public_local_profile ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        (canonical_identity->sequence_id == 0 &&
         canonical_identity->producer_id == 0 &&
         canonical_identity->user_tag == 0 &&
         canonical_identity->node_hash_lo == 0 &&
         canonical_identity->node_hash_hi == 0) ||
        (checked.owner == npu_exact_owner::set_rows &&
         set_rows_slot >= 256U)) {
        return false;
    }
    for (std::size_t index = checked.source_count;
         index < source_backing_bytes->size(); ++index) {
        if ((*source_backing_bytes)[index] != 0) {
            return false;
        }
    }

    std::array<std::uint64_t, 3> effective_sources = {};
    for (std::size_t index = 0; index < checked.source_count; ++index) {
        if (!effective_backing_bytes(
                checked.sources[index], (*source_backing_bytes)[index],
                &effective_sources[index])) {
            return false;
        }
    }
    std::uint64_t effective_dst = 0;
    if (!effective_backing_bytes(
            checked.dst, dst_backing_bytes, &effective_dst) ||
        (checked.owner == npu_exact_owner::cpy &&
         effective_sources[1] != effective_dst) ||
        (checked.owner == npu_exact_owner::set_rows &&
         effective_sources[2] != effective_dst)) {
        return false;
    }

    std::uint64_t outer = 1;
    for (std::size_t dimension = 1; dimension < 4; ++dimension) {
        if (!checked_mul(
                outer,
                static_cast<std::uint64_t>(checked.dst.ne[dimension]),
                &outer)) {
            return false;
        }
    }
    std::uint64_t src0_iova = 0;
    std::uint64_t src1_iova = 0;
    std::uint64_t dst_iova = 0;
    if (!checked_add(kSrc0Iova, checked.sources[0].view_off,
                     &src0_iova) ||
        (checked.source_count >= 2U &&
         !checked_add(kSrc1Iova, checked.sources[1].view_off,
                      &src1_iova)) ||
        !checked_add(kDstIova, checked.dst.view_off, &dst_iova)) {
        return false;
    }

    std::uint64_t src2_stride = 0;
    switch (checked.owner) {
        case npu_exact_owner::unary:
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
        case npu_exact_owner::sum_rows:
        case npu_exact_owner::glu:
        case npu_exact_owner::ssm_conv:
            src2_stride = checked.sources[0].nb[2];
            break;
        case npu_exact_owner::set_rows:
            src2_stride = checked.dst.nb[1];
            break;
        case npu_exact_owner::cpy:
        case npu_exact_owner::cont:
        case npu_exact_owner::concat:
        case npu_exact_owner::f16_attention_mul_mat:
        case npu_exact_owner::rope:
        case npu_exact_owner::soft_max:
            src2_stride = 0;
            break;
    }

    std::uint32_t scalar0 = 0;
    switch (checked.owner) {
        case npu_exact_owner::rms_norm:
        case npu_exact_owner::l2_norm:
        case npu_exact_owner::f16_attention_mul_mat:
        case npu_exact_owner::soft_max:
            scalar0 = load_le32(checked.dst.op_params);
            break;
        case npu_exact_owner::set_rows:
            scalar0 = 256U;
            break;
        default:
            scalar0 = 0;
            break;
    }

    npu_exact_command_contract candidate = {};
    candidate.abi_valid = 1U;
    candidate.windows_generation_valid = 1U;
    candidate.kernel_id = checked.public_kernel_id;
    candidate.vector_op = checked.public_vector_op;
    candidate.local_profile = checked.public_local_profile;
    candidate.command_flags = canonical_identity->command_flags;
    candidate.context_id = canonical_identity->context_id;
    candidate.capability_epoch = kCapabilityEpoch;
    candidate.node_count = 1U;
    candidate.sequence_id = canonical_identity->sequence_id;
    candidate.producer_id = canonical_identity->producer_id;
    candidate.user_tag = canonical_identity->user_tag;
    candidate.node_hash_lo = canonical_identity->node_hash_lo;
    candidate.node_hash_hi = canonical_identity->node_hash_hi;
    candidate.deadline_cycles = 0;
    candidate.src0_iova = src0_iova;
    candidate.src1_iova =
        checked.source_count >= 2U ? src1_iova : 0;
    candidate.src2_iova =
        checked.owner == npu_exact_owner::set_rows ? dst_iova : 0;
    candidate.dst_iova = dst_iova;
    candidate.scratch_iova = 0;
    candidate.element_count =
        static_cast<std::uint64_t>(checked.dst.ne[0]);
    candidate.outer_count = static_cast<std::uint32_t>(outer);
    candidate.dtype = kMacroDtypeF32;
    candidate.src0_stride = checked.sources[0].nb[1];
    candidate.src1_stride = checked.source_count >= 2U ?
        checked.sources[1].nb[1] : 0;
    candidate.src2_stride = src2_stride;
    candidate.dst_stride = checked.dst.nb[1];
    candidate.scalar0 = scalar0;
    candidate.scalar1 =
        checked.owner == npu_exact_owner::set_rows ? set_rows_slot : 0;
    candidate.scratch_bytes = 0;
    candidate.rope_position = 0;
    candidate.src0_window_base = kSrc0Iova;
    candidate.src0_window_size = effective_sources[0];
    candidate.src0_window_perm = 1U;
    candidate.src1_window_base =
        checked.source_count >= 2U ? kSrc1Iova : 0;
    candidate.src1_window_size =
        checked.source_count >= 2U ? effective_sources[1] : 0;
    candidate.src1_window_perm = 1U;
    candidate.dst_window_base = kDstIova;
    candidate.dst_window_size = effective_dst;
    candidate.dst_window_perm = 2U;
    candidate.dst_shadow_readable =
        checked.owner == npu_exact_owner::set_rows;
    *command = candidate;
    return true;
}

bool npu_verilator_execute_exact(
        const npu_exact_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::array<npu_exact_raw_allocation, 3> * sources,
        npu_exact_private_destination * dst_shadow,
        npu_verilator_exact_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (profile == nullptr || canonical_identity == nullptr ||
        sources == nullptr || dst_shadow == nullptr) {
        result->runner_error_code = exact_runner_profile;
        return false;
    }
    npu_exact_profile checked_profile = *profile;
    const bool digest_is_nonzero =
        canonical_identity->sequence_id != 0 ||
        canonical_identity->producer_id != 0 ||
        canonical_identity->node_hash_lo != 0 ||
        canonical_identity->node_hash_hi != 0;
    if (!npu_exact_finalize_profile(&checked_profile) ||
        checked_profile.public_kernel_id != profile->public_kernel_id ||
        checked_profile.public_vector_op != profile->public_vector_op ||
        checked_profile.public_local_profile !=
            profile->public_local_profile ||
        checked_profile.expected_read_bytes !=
            profile->expected_read_bytes ||
        checked_profile.expected_write_bytes !=
            profile->expected_write_bytes ||
        checked_profile.expected_elements != profile->expected_elements ||
        checked_profile.expected_read_requests !=
            profile->expected_read_requests ||
        checked_profile.expected_write_requests !=
            profile->expected_write_requests ||
        checked_profile.cycle_upper_bound != profile->cycle_upper_bound ||
        canonical_identity->profile_id !=
            checked_profile.public_local_profile ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        !digest_is_nonzero) {
        result->runner_error_code = exact_runner_profile;
        return false;
    }
    try {
        exact_harness harness(
            checked_profile, *canonical_identity, *sources,
            dst_shadow, result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = exact_runner_allocation;
        return false;
    }
}

bool npu_verilator_execute_system_transaction(
        const npu_system_transaction * transaction,
        npu_verilator_exact_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (transaction == nullptr) {
        result->runner_error_code = exact_runner_profile;
        return false;
    }
    try {
        exact_harness harness(*transaction, result);
        return harness.run();
    } catch (...) {
        result->passed = false;
        result->runner_error_code = exact_runner_allocation;
        return false;
    }
}

namespace {

void * npu_direct_selftest_symbol(const char * symbol) {
    if (symbol == nullptr) {
        return nullptr;
    }
    static void * handle = []() -> void * {
        Dl_info info = {};
        if (dladdr(
                reinterpret_cast<const void *>(
                    &npu_verilator_execute_system_transaction),
                &info) == 0 || info.dli_fname == nullptr) {
            return nullptr;
        }
        std::string path(info.dli_fname);
        const std::size_t slash = path.find_last_of('/');
        if (slash == std::string::npos) {
            return nullptr;
        }
        path.resize(slash + 1U);
        path += "libnpu-direct-selftests.so";
        return dlopen(path.c_str(), RTLD_NOW | RTLD_LOCAL);
    }();
    return handle == nullptr ? nullptr : dlsym(handle, symbol);
}

} // namespace

bool npu_verilator_run_mm2_self_test(
        npu_verilator_self_test_result * result) {
    using function_type = bool (*)(npu_verilator_self_test_result *);
    const auto function = reinterpret_cast<function_type>(
        npu_direct_selftest_symbol("npu_direct_selftest_mm2_v1"));
    if (function == nullptr) {
        if (result != nullptr) {
            *result = {};
            result->error_code = 0xffffffffU;
        }
        return false;
    }
    return function(result);
}

bool npu_verilator_execute_f32_add(
        const std::uint32_t * src0_bits,
        const std::uint32_t * src1_bits,
        std::uint32_t * dst_bits,
        npu_verilator_f32_add_result * result) {
    using function_type = bool (*)(
        const std::uint32_t *, const std::uint32_t *, std::uint32_t *,
        npu_verilator_f32_add_result *);
    const auto function = reinterpret_cast<function_type>(
        npu_direct_selftest_symbol(
            "npu_direct_selftest_f32_add_execute_v1"));
    if (function == nullptr) {
        if (result != nullptr) {
            *result = {};
            result->runner_error_code = 0xffffffffU;
        }
        return false;
    }
    return function(src0_bits, src1_bits, dst_bits, result);
}

bool npu_verilator_run_f32_add_self_test(
        npu_f32_add_mode mode,
        npu_verilator_f32_add_result * result) {
    using function_type = bool (*)(
        npu_f32_add_mode, npu_verilator_f32_add_result *);
    const auto function = reinterpret_cast<function_type>(
        npu_direct_selftest_symbol("npu_direct_selftest_f32_add_v1"));
    if (function == nullptr) {
        if (result != nullptr) {
            *result = {};
            result->runner_error_code = 0xffffffffU;
        }
        return false;
    }
    return function(mode, result);
}

bool npu_verilator_run_direct_f32_alu_self_test(
        std::uint32_t profile_id,
        npu_f32_alu_mode mode,
        npu_verilator_f32_alu_result * result) {
    using function_type = bool (*)(
        std::uint32_t, npu_f32_alu_mode,
        npu_verilator_f32_alu_result *);
    const auto function = reinterpret_cast<function_type>(
        npu_direct_selftest_symbol("npu_direct_selftest_f32_alu_v1"));
    if (function == nullptr) {
        if (result != nullptr) {
            *result = {};
            result->runner_error_code = 0xffffffffU;
        }
        return false;
    }
    return function(profile_id, mode, result);
}
