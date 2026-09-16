#include "npu-system-session.h"

#include "npu-command-abi.h"
#include "npu-compiled-bundle.h"
#include "npu-rv64-service-firmware-image.h"
#include "npu_service_mailbox_abi.h"

#include "VNpcTensorNpuSystemTop.h"
#include "VNpcTensorNpuSystemTop__Dpi.h"
#include "verilated.h"

#include <algorithm>
#include <cstdio>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <memory>
#include <new>
#include <string>
#include <utility>
#include <vector>

namespace firmware = npu::rv64_service_firmware_v1;

namespace {

constexpr std::uint64_t kCpuBase = 0x80000000ULL;
constexpr std::size_t kCpuBytes = 8192U;
constexpr std::uint64_t kNcBase = NPU_SERVICE_MAILBOX_ADDRESS;
constexpr std::size_t kNcBytes = NPU_SERVICE_COPY_ADDRESS - kNcBase +
    NPU_SERVICE_MAX_COMMANDS * NPU_SERVICE_COPY_STRIDE;
constexpr std::uint64_t kLaunchBits =
    (std::uint64_t{0x0bf0305bU} << 32U) | 0x0220305bU;
constexpr std::uint32_t kLaunchLo = 0x0220305bU;
constexpr std::uint32_t kLaunchHi = 0x0bf0305bU;
constexpr std::uint32_t kConfigIndexMask = 0x01f00000U;
constexpr std::uint32_t kConfigFixedMask = ~kConfigIndexMask;
constexpr std::uint32_t kConfigFixedBits = 0x0a03cfdbU;
constexpr std::uint32_t kRecoveryClearBits = 0x0be04fdbU;
constexpr std::uint32_t kF32AluKernel = 0x514e0010U;
constexpr std::size_t kLaneCount = 8U;
constexpr std::uint64_t kBootCycleLimit = 20000U;

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

bool range_contains(
        std::uint64_t base,
        std::size_t size,
        std::uint64_t address,
        std::size_t bytes) {
    if (address < base) {
        return false;
    }
    const std::uint64_t offset = address - base;
    return offset <= size && bytes <= size - static_cast<std::size_t>(offset);
}

std::uint32_t load_le32(const std::uint8_t * bytes) {
    return static_cast<std::uint32_t>(bytes[0]) |
           (static_cast<std::uint32_t>(bytes[1]) << 8U) |
           (static_cast<std::uint32_t>(bytes[2]) << 16U) |
           (static_cast<std::uint32_t>(bytes[3]) << 24U);
}

std::uint64_t load_le64(const std::uint8_t * bytes) {
    std::uint64_t value = 0U;
    for (std::size_t index = 0; index < 8U; ++index) {
        value |= static_cast<std::uint64_t>(bytes[index]) << (8U * index);
    }
    return value;
}

void store_le16(std::uint8_t * bytes, std::uint16_t value) {
    bytes[0] = static_cast<std::uint8_t>(value);
    bytes[1] = static_cast<std::uint8_t>(value >> 8U);
}

void store_le32(std::uint8_t * bytes, std::uint32_t value) {
    for (std::size_t index = 0; index < 4U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (std::size_t index = 0; index < 8U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

template <typename Wide>
std::uint64_t portal_lane_address(const Wide & words, std::size_t lane) {
    return static_cast<std::uint64_t>(words[lane * 2U]) |
           (static_cast<std::uint64_t>(words[lane * 2U + 1U]) << 32U);
}

bool find_firmware_launch_pc(std::uint64_t * pc) {
    std::size_t match = 0U;
    unsigned matches = 0U;
    for (std::size_t offset = 0U; offset + 8U <= firmware::kImageBytes;
         offset += 4U) {
        if (load_le32(firmware::kImage.data() + offset) == kLaunchLo &&
            load_le32(firmware::kImage.data() + offset + 4U) == kLaunchHi) {
            match = offset;
            ++matches;
        }
    }
    if (pc == nullptr || matches != 1U) {
        return false;
    }
    *pc = firmware::kLoadAddress + match;
    return true;
}

bool same_identity(
        const npu_system_command_identity & lhs,
        const npu_system_command_identity & rhs) {
    return lhs.kernel_id == rhs.kernel_id &&
           lhs.command_flags == rhs.command_flags &&
           lhs.context_id == rhs.context_id &&
           lhs.sequence_id == rhs.sequence_id &&
           lhs.producer_id == rhs.producer_id &&
           lhs.user_tag == rhs.user_tag &&
           lhs.covered_node_count == rhs.covered_node_count &&
           lhs.node_hash_lo == rhs.node_hash_lo &&
           lhs.node_hash_hi == rhs.node_hash_hi &&
           lhs.local_profile == rhs.local_profile;
}

npu_system_command_identity identity_from_words(
        const npu_command_abi_words & words) {
    npu_system_command_identity identity = {};
    identity.kernel_id = static_cast<std::uint32_t>(words[0]);
    identity.command_flags = static_cast<std::uint32_t>(words[0] >> 32U);
    identity.context_id = static_cast<std::uint32_t>(words[1]);
    identity.sequence_id = words[2];
    identity.producer_id = words[3];
    identity.user_tag = words[4];
    identity.covered_node_count = static_cast<std::uint32_t>(words[5]);
    identity.node_hash_lo = words[6];
    identity.node_hash_hi = words[7];
    identity.local_profile = static_cast<std::uint32_t>(words[9]);
    return identity;
}

npu_system_counters counter_delta(
        const npu_system_counters & after,
        const npu_system_counters & before) {
#define NPU_COUNTER_DELTA(field) result.field = after.field - before.field
    npu_system_counters result = {};
    NPU_COUNTER_DELTA(cycles);
    NPU_COUNTER_DELTA(commits);
    NPU_COUNTER_DELTA(config_accepts);
    NPU_COUNTER_DELTA(launch_accepts);
    NPU_COUNTER_DELTA(macro_terminals);
    NPU_COUNTER_DELTA(portal_requests);
    NPU_COUNTER_DELTA(portal_responses);
    NPU_COUNTER_DELTA(portal_reads);
    NPU_COUNTER_DELTA(portal_writes);
    NPU_COUNTER_DELTA(portal_input_words);
    NPU_COUNTER_DELTA(portal_output_words);
    NPU_COUNTER_DELTA(portal_read_bytes);
    NPU_COUNTER_DELTA(portal_write_bytes);
    NPU_COUNTER_DELTA(gmem_read_bytes);
    NPU_COUNTER_DELTA(gmem_write_bytes);
    NPU_COUNTER_DELTA(q8_blocks);
    NPU_COUNTER_DELTA(mover_read_bytes);
    NPU_COUNTER_DELTA(mover_write_bytes);
    NPU_COUNTER_DELTA(vector_elements);
    NPU_COUNTER_DELTA(dma_starts);
    NPU_COUNTER_DELTA(dma_completions);
    NPU_COUNTER_DELTA(dma_read_bytes);
    NPU_COUNTER_DELTA(dma_write_bytes);
    NPU_COUNTER_DELTA(rtl_macro_commands);
    NPU_COUNTER_DELTA(rtl_f32_starts);
    NPU_COUNTER_DELTA(rtl_macro_completions);
    NPU_COUNTER_DELTA(rtl_error_clears);
    NPU_COUNTER_DELTA(traps);
    NPU_COUNTER_DELTA(exits);
#undef NPU_COUNTER_DELTA
    return result;
}

struct dpi_target {
    virtual ~dpi_target() = default;
    virtual bool read_instruction(
        std::uint64_t, std::uint32_t, std::uint64_t *) = 0;
    virtual bool read_data(
        std::uint64_t, std::uint32_t, std::uint64_t *) = 0;
    virtual bool write_data(
        std::uint64_t, std::uint64_t, std::uint64_t) = 0;
    virtual void commit(std::uint64_t, std::uint32_t) = 0;
    virtual void trap(std::uint32_t, std::uint64_t) = 0;
    virtual void exit_event() = 0;
    virtual std::uint64_t cycles() const = 0;
    virtual std::uint64_t commits() const = 0;
};

// The DPI symbols are process-global.  Refusing a second live target is part
// of the execution ABI: silently routing one model's memory callbacks into a
// different session would violate both command ownership and IOVA isolation.
dpi_target * g_dpi_target = nullptr;

}  // namespace

class npu_system_session::impl final : public dpi_target {
public:
    impl(int argc, char ** argv)
        : nc_memory_(kNcBytes, 0U) {
        if (g_dpi_target != nullptr) {
            set_fatal(npu_system_session_error::router_busy,
                      "another SystemTop DPI session is already live");
            return;
        }
        g_dpi_target = this;
        owns_router_ = true;

        if (firmware::kLoadAddress != kCpuBase ||
            firmware::kEntryAddress != kCpuBase ||
            firmware::kMailboxAddress != NPU_SERVICE_MAILBOX_ADDRESS ||
            firmware::kCommandAddress != NPU_SERVICE_COMMAND_ADDRESS ||
            firmware::kCompletionAddress != NPU_SERVICE_COMPLETION_ADDRESS ||
            firmware::kImageBytes > cpu_memory_.size()) {
            set_fatal(npu_system_session_error::firmware_image,
                      "fixed firmware image does not match the service ABI");
            return;
        }
        if (!find_firmware_launch_pc(&firmware_launch_pc_)) {
            set_fatal(npu_system_session_error::firmware_image,
                      "fixed firmware must contain one exact LO/HI launch pair");
            return;
        }
        std::copy(firmware::kImage.begin(), firmware::kImage.end(),
                  cpu_memory_.begin());

        try {
            context_ = std::make_unique<VerilatedContext>();
            if (argc > 0 && argv != nullptr) {
                context_->commandArgs(argc, argv);
            }
            top_ = std::make_unique<VNpcTensorNpuSystemTop>(context_.get());
            constructor_count_ = 1U;
        } catch (const std::bad_alloc &) {
            set_fatal(npu_system_session_error::allocation_failure,
                      "cannot allocate the persistent SystemTop model");
            return;
        }

        top_->clk = 0U;
        top_->rst = 1U;
        drive_inputs();
        top_->eval();
        for (unsigned reset_cycle = 0; reset_cycle < 8U; ++reset_cycle) {
            if (!tick()) {
                return;
            }
        }
        top_->rst = 0U;
        ++reset_release_count_;
        drive_inputs();
        top_->eval();

        const std::uint64_t deadline = counters_.cycles + kBootCycleLimit;
        while (!fatal_ && mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET) == 0U &&
               counters_.cycles < deadline) {
            if (!tick()) {
                return;
            }
        }
        if (!fatal_ && mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET) != 1U) {
            set_fatal(npu_system_session_error::boot_timeout,
                      "fixed firmware did not publish boot_count=1");
            return;
        }
        booted_ = !fatal_;
    }

    ~impl() override {
        if (top_ != nullptr) {
            top_->final();
        }
        if (owns_router_ && g_dpi_target == this) {
            g_dpi_target = nullptr;
        }
    }

    bool ready() const { return booted_ && !fatal_; }
    bool fatal() const { return fatal_; }
    npu_system_session_error last_error() const { return last_error_; }
    const std::string & failure() const { return failure_; }

    npu_system_session_status status() const {
        npu_system_session_status result = {};
        result.booted = booted_;
        result.fatal = fatal_;
        result.constructor_count = constructor_count_;
        result.reset_release_count = reset_release_count_;
        result.boot_count = mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET);
        result.last_generation = last_generation_;
        result.mailbox_state = mailbox32(NPU_SERVICE_MB_STATE_OFFSET);
        result.mailbox_error = mailbox32(NPU_SERVICE_MB_ERROR_OFFSET);
        result.npu_error_code = top_ == nullptr ? 0U :
            static_cast<std::uint8_t>(top_->npu_error_code_o);
        result.counters = snapshot();
        return result;
    }

    bool dispatch(
            const npu_system_submission & submission,
            npu_system_dispatch_result * result) {
        if (result != nullptr) {
            *result = {};
            result->generation = submission.generation;
        }
        if (fatal_) {
            last_error_ = npu_system_session_error::session_fatal;
            failure_ = "persistent SystemTop session is fatal: " + fatal_reason_;
            return false;
        }
        last_error_ = npu_system_session_error::none;
        failure_.clear();
        if (!booted_ || top_ == nullptr) {
            return reject(npu_system_session_error::session_fatal,
                          "persistent SystemTop session is not booted");
        }
        if (submission.generation == 0U ||
            submission.relocated_command_image == nullptr ||
            submission.max_cycles == 0U || submission.commands.empty() ||
            submission.commands.size() > NPU_SERVICE_MAX_COMMANDS) {
            return reject(npu_system_session_error::invalid_submission,
                          "submission fields/count/cycle budget are invalid");
        }
        if (submission.generation <= last_generation_) {
            return reject(npu_system_session_error::stale_generation,
                          "generation must be strictly monotonic in one boot");
        }

        std::vector<npu_command_abi_words> descriptors;
        std::vector<runtime_buffer> buffers;
        if (!validate_commands(submission, &descriptors) ||
            !validate_buffers(submission, descriptors, &buffers) ||
            !validate_copies(submission, buffers)) {
            return false;
        }

        const npu_system_counters before = snapshot();
        descriptors_ = std::move(descriptors);
        contracts_ = submission.commands;
        buffers_ = std::move(buffers);
        copies_ = submission.copies;
        dma_issued_.assign(copies_.size(),0);
        observed_.assign(contracts_.size(), {});
        cpu_producer_ids_.assign(contracts_.size(), 0U);
        response_ = {};
        active_command_ = kNoCommand;
        fault_terminal_seen_ = false;
        fault_terminal_fatal_ = false;
        fault_terminal_code_ = 0U;
        recovery_clear_command_seen_ = false;
        recovery_clear_terminal_seen_ = false;
        fault_trap_count_ = 0U;
        active_generation_ = submission.generation;
        generation_config_base_ = counters_.config_accepts;
        generation_launch_base_ = counters_.launch_accepts;
        generation_terminal_base_ = counters_.macro_terminals;
        dispatch_active_ = true;
        last_progress_cycle_ = counters_.cycles;
        progress_completed_ = 0;

        const std::size_t command_offset = static_cast<std::size_t>(
            NPU_SERVICE_COMMAND_ADDRESS - kNcBase);
        const std::size_t command_bytes =
            contracts_.size() * NPU_SERVICE_COMMAND_STRIDE;
        std::copy_n(
            submission.relocated_command_image->begin() +
                NPU_COMPILED_COMMAND_HEADER_BYTES,
            command_bytes, nc_memory_.begin() + command_offset);
        const std::size_t completion_offset = static_cast<std::size_t>(
            NPU_SERVICE_COMPLETION_ADDRESS - kNcBase);
        std::fill_n(nc_memory_.begin() + completion_offset,
                    contracts_.size() * NPU_SERVICE_COMPLETION_STRIDE, 0U);

        put_nc32(NPU_SERVICE_MB_MAGIC_OFFSET, NPU_SERVICE_MAILBOX_MAGIC);
        put_nc16(NPU_SERVICE_MB_ABI_MAJOR_OFFSET, NPU_SERVICE_ABI_MAJOR);
        put_nc16(NPU_SERVICE_MB_ABI_MINOR_OFFSET, NPU_SERVICE_ABI_MINOR);
        put_nc32(NPU_SERVICE_MB_COUNT_OFFSET,
                 static_cast<std::uint32_t>(contracts_.size()));
        put_nc32(NPU_SERVICE_MB_COMMAND_STRIDE_OFFSET,
                 NPU_SERVICE_COMMAND_STRIDE);
        put_nc32(NPU_SERVICE_MB_RESERVED0_OFFSET,
                 copies_.empty() ? 0U : NPU_SERVICE_FLAG_RAW_COPIES);
        for (std::size_t i = 0; i < copies_.size(); ++i) {
            const std::size_t offset = NPU_SERVICE_COPY_ADDRESS - kNcBase +
                i * NPU_SERVICE_COPY_STRIDE;
            put_nc64(offset + 0, copies_[i].before.src);
            put_nc64(offset + 8, copies_[i].before.dst);
            put_nc64(offset + 16, copies_[i].before.bytes);
            put_nc64(offset + 24, copies_[i].after.src);
            put_nc64(offset + 32, copies_[i].after.dst);
            put_nc64(offset + 40, copies_[i].after.bytes);
        }
        put_nc64(NPU_SERVICE_MB_GENERATION_OFFSET, submission.generation);
        put_nc64(NPU_SERVICE_MB_COMMAND_BASE_OFFSET,
                 NPU_SERVICE_COMMAND_ADDRESS);
        put_nc64(NPU_SERVICE_MB_COMPLETION_BASE_OFFSET,
                 NPU_SERVICE_COMPLETION_ADDRESS);
        put_nc32(NPU_SERVICE_MB_COMPLETED_OFFSET, 0U);
        put_nc32(NPU_SERVICE_MB_ERROR_OFFSET, NPU_SERVICE_ERROR_NONE);
        // Doorbell/state is deliberately the final host write.
        put_nc32(NPU_SERVICE_MB_STATE_OFFSET, NPU_SERVICE_STATE_READY);

        const std::uint64_t deadline = submission.max_cycles >
                std::numeric_limits<std::uint64_t>::max() - counters_.cycles ?
            std::numeric_limits<std::uint64_t>::max() :
            counters_.cycles + submission.max_cycles;
        while (!fatal_ && counters_.cycles < deadline) {
            const std::uint32_t state = mailbox32(
                NPU_SERVICE_MB_STATE_OFFSET);
            if (state == NPU_SERVICE_STATE_DONE ||
                state == NPU_SERVICE_STATE_ERROR) {
                break;
            }
            if (!tick()) {
                break;
            }
        }
        const std::uint32_t final_state = mailbox32(
            NPU_SERVICE_MB_STATE_OFFSET);
        if (!fatal_ && final_state != NPU_SERVICE_STATE_DONE &&
            final_state != NPU_SERVICE_STATE_ERROR) {
            set_fatal(npu_system_session_error::timeout,
                      "timeout waiting for fixed firmware completion");
        }

        bool success = false;
        bool matched_recoverable_fault = false;
        bool matched_fatal_fault = false;
        if (!fatal_ && final_state == NPU_SERVICE_STATE_DONE) {
            success = verify_dispatch(before);
        } else if (!fatal_ && final_state == NPU_SERVICE_STATE_ERROR) {
            const std::uint32_t error = mailbox32(
                NPU_SERVICE_MB_ERROR_OFFSET);
            if (error == NPU_SERVICE_ERROR_NPU_FAULT) {
                matched_recoverable_fault = verify_fault(before, false);
            } else if (error == NPU_SERVICE_ERROR_NPU_FATAL) {
                matched_fatal_fault = verify_fault(before, true);
            } else {
                set_fatal(npu_system_session_error::firmware_error,
                          "firmware published malformed mailbox ERROR=" +
                              std::to_string(error));
            }
        }
        if (success || matched_recoverable_fault || matched_fatal_fault) {
            last_generation_ = submission.generation;
        }
        const npu_system_counters after = snapshot();
        if (result != nullptr) {
            result->mailbox_state = mailbox32(NPU_SERVICE_MB_STATE_OFFSET);
            result->mailbox_error = mailbox32(NPU_SERVICE_MB_ERROR_OFFSET);
            result->completed = mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET);
            result->boot_count = mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET);
            if (result->completed != 0U) {
                const std::size_t completion = static_cast<std::size_t>(
                    NPU_SERVICE_COMPLETION_ADDRESS - kNcBase) +
                    (result->completed - 1U) * NPU_SERVICE_COMPLETION_STRIDE;
                result->completion_status = load_le32(
                    nc_memory_.data() + completion +
                    NPU_SERVICE_CPL_STATUS_OFFSET);
                result->fault_tval = load_le64(
                    nc_memory_.data() + completion +
                    NPU_SERVICE_CPL_FAULT_TVAL_OFFSET);
                result->fault_pc = load_le64(
                    nc_memory_.data() + completion +
                    NPU_SERVICE_CPL_FAULT_PC_OFFSET);
                result->fault_cause = load_le64(
                    nc_memory_.data() + completion +
                    NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET);
            }
            result->before = before;
            result->after = after;
            result->delta = counter_delta(after, before);
            for (const runtime_buffer & buffer : buffers_) {
                result->buffers.push_back(buffer.activity);
            }
        }
        dispatch_active_ = false;
        buffer_cache_ = {};
        buffers_.clear();
        descriptors_.clear();
        contracts_.clear();
        observed_.clear();
        cpu_producer_ids_.clear();
        active_command_ = kNoCommand;
        if (matched_recoverable_fault) {
            last_error_ = npu_system_session_error::recoverable_npu_fault;
            failure_ = "firmware reported a precise recoverable NPU fault";
            return false;
        }
        if (matched_fatal_fault) {
            set_fatal(npu_system_session_error::fatal_npu_fault,
                      "firmware reported a reset-required NPU fault");
            return false;
        }
        return success;
    }

    bool read_instruction(
            std::uint64_t address,
            std::uint32_t bytes,
            std::uint64_t * value) override {
        if (value == nullptr || bytes == 0U || bytes > 8U ||
            !range_contains(kCpuBase, cpu_memory_.size(), address, bytes)) {
            return set_fatal(npu_system_session_error::cpu_memory,
                             "RV64 instruction fetch escaped firmware image");
        }
        *value = read_bytes(cpu_memory_,
                            static_cast<std::size_t>(address - kCpuBase),
                            bytes);
        return true;
    }

    bool read_data(
            std::uint64_t address,
            std::uint32_t bytes,
            std::uint64_t * value) override {
        if (value == nullptr || bytes == 0U || bytes > 8U) {
            return set_fatal(npu_system_session_error::cpu_memory,
                             "invalid RV64 data-read request");
        }
        if (address == NPU_SERVICE_DMA_MMIO_ADDRESS + 32 && bytes == 8) {
            *value = dma_status(); return true;
        }
        if (range_contains(kNcBase, nc_memory_.size(), address, bytes)) {
            *value = read_bytes(nc_memory_,
                                static_cast<std::size_t>(address - kNcBase),
                                bytes);
            return true;
        }
        if (range_contains(kCpuBase, cpu_memory_.size(), address, bytes)) {
            *value = read_bytes(cpu_memory_,
                                static_cast<std::size_t>(address - kCpuBase),
                                bytes);
            return true;
        }
        return set_fatal(npu_system_session_error::cpu_memory,
                         "RV64 data read escaped firmware/NC apertures");
    }

    bool write_data(
            std::uint64_t address,
            std::uint64_t value,
            std::uint64_t mask) override {
        if (range_contains(NPU_SERVICE_DMA_MMIO_ADDRESS, 32, address, 8))
            return dma_mmio_write(address,value,mask);
        if (!range_contains(kNcBase, nc_memory_.size(), address, 1U)) {
            return set_fatal(npu_system_session_error::cpu_memory,
                             "RV64 data write escaped firmware/NC/DMA MMIO apertures");
        }
        const std::size_t offset = static_cast<std::size_t>(address - kNcBase);
        for (std::size_t byte = 0; byte < 8U; ++byte) {
            if ((mask & (std::uint64_t{1} << byte)) == 0U) {
                continue;
            }
            if (offset + byte >= nc_memory_.size()) {
                return set_fatal(npu_system_session_error::cpu_memory,
                                 "RV64 masked write crossed NC aperture");
            }
            nc_memory_[offset + byte] =
                static_cast<std::uint8_t>(value >> (8U * byte));
        }
        return true;
    }

    void commit(std::uint64_t, std::uint32_t) override {
        ++counters_.commits;
    }

    void trap(std::uint32_t cause, std::uint64_t) override {
        ++counters_.traps;
        if (dispatch_active_ && fault_terminal_seen_ &&
            cause == NPU_SERVICE_NPU_FAULT_MCAUSE) {
            ++fault_trap_count_;
            return;
        }
        set_fatal(npu_system_session_error::unexpected_trap,
                  "fixed firmware took unexpected trap cause=" +
                      std::to_string(cause));
    }

    void exit_event() override {
        ++counters_.exits;
        set_fatal(npu_system_session_error::unexpected_trap,
                  "fixed firmware emitted an exit event");
    }

    std::uint64_t cycles() const override { return counters_.cycles; }
    std::uint64_t commits() const override { return counters_.commits; }

private:
    static constexpr std::size_t kNoCommand =
        static_cast<std::size_t>(-1);

    struct runtime_buffer {
        std::string id;
        std::uint64_t base = 0U;
        std::uint32_t permissions = 0U;
        std::vector<std::uint8_t> * bytes = nullptr;
        bool written = false;
        npu_system_buffer_activity activity = {};
    };

    struct portal_response {
        bool occupied = false;
        std::uint8_t mask = 0U;
        std::size_t command = kNoCommand;
        std::array<std::uint32_t, kLaneCount> src0 = {};
        std::array<std::uint32_t, kLaneCount> src1 = {};
    };

    struct command_observed {
        std::uint64_t request_groups = 0U;
        std::uint64_t response_groups = 0U;
        std::uint64_t read_groups = 0U;
        std::uint64_t write_groups = 0U;
        std::uint64_t input_words = 0U;
        std::uint64_t output_words = 0U;
        std::uint64_t read_bytes = 0U;
        std::uint64_t write_bytes = 0U;
        std::uint64_t gmem_reads = 0, gmem_writes = 0, gmem_responses = 0;
        std::uint64_t gmem_read_bytes = 0, gmem_write_bytes = 0;
        std::uint64_t q8_groups = 0, q8_responses = 0, q8_blocks = 0;
        npu_system_f32_alu_contract mover = {};
    };

    bool reject(npu_system_session_error error, const std::string & message) {
        last_error_ = error;
        failure_ = message;
        return false;
    }

    bool set_fatal(
            npu_system_session_error error,
            const std::string & message) {
        if (!fatal_) {
            fatal_ = true;
            fatal_reason_ = message;
            last_error_ = error;
            failure_ = message;
        }
        return false;
    }

    bool validate_commands(
            const npu_system_submission & submission,
            std::vector<npu_command_abi_words> * output) {
        const std::size_t expected_bytes =
            NPU_COMPILED_COMMAND_HEADER_BYTES +
            submission.commands.size() * NPU_SERVICE_COMMAND_STRIDE;
        if (output == nullptr ||
            submission.relocated_command_image->size() != expected_bytes) {
            return reject(npu_system_session_error::command_image,
                          "relocated command image size/count mismatch");
        }
        std::vector<npu_command_abi_words> candidate;
        try {
            candidate.reserve(submission.commands.size());
        } catch (const std::bad_alloc &) {
            return reject(npu_system_session_error::allocation_failure,
                          "cannot allocate decoded descriptor table");
        }
        for (std::size_t index = 0; index < submission.commands.size();
             ++index) {
            npu_command_abi_words words = {};
            npu_compiled_bundle_diagnostic bundle_diagnostic = {};
            npu_command_abi_diagnostic abi_diagnostic = {};
            if (!npu_compiled_bundle_decode_record(
                    *submission.relocated_command_image, index, &words,
                    &bundle_diagnostic) ||
                !npu_command_abi_validate_words(&words, &abi_diagnostic)) {
                return reject(
                    npu_system_session_error::command_image,
                    "command[" + std::to_string(index) +
                        "] failed compiled/command ABI validation");
            }
            const npu_system_command_contract & contract =
                submission.commands[index];
            const bool controlled_capability_reject =
                contract.owner == npu_system_command_owner::f32_alu &&
                contract.expected_outcome ==
                    npu_system_expected_outcome::recoverable_npu_fault &&
                contract.expected_npu_error_code == 14U &&
                contract.f32_alu.request_groups == 0U &&
                contract.f32_alu.response_groups == 0U &&
                contract.f32_alu.read_groups == 0U &&
                contract.f32_alu.write_groups == 0U &&
                contract.f32_alu.expected_starts == 0U;
            const auto kernel = static_cast<std::uint32_t>(words[0]);
            const bool owner_ok =
                (contract.owner == npu_system_command_owner::f32_alu &&
                 (kernel == kF32AluKernel || controlled_capability_reject)) ||
                (contract.owner == npu_system_command_owner::q8_get_rows && kernel == 0x514e0001U) ||
                (contract.owner == npu_system_command_owner::q8_gemv && kernel == 0x514e0002U) ||
                (contract.owner == npu_system_command_owner::f32_mover &&
                 (kernel == 0x514e0003U || kernel == 0x514e0004U)) ||
                (contract.owner == npu_system_command_owner::exact &&
                 (kernel == 0x514e0005U || kernel == 0x514e0006U || kernel == 0x514e0007U || kernel == 0x514e0008U || kernel == 0x514e0009U || kernel == 0x514e000aU || kernel == 0x514e0011U || kernel == 0x514e0022U)) ||
                (contract.owner == npu_system_command_owner::argmax && kernel == 0x514e0030U);
            if (!owner_ok) {
                return reject(
                    npu_system_session_error::unsupported_owner,
                    "command[" + std::to_string(index) +
                        "] has no matching production RTL owner");
            }
            if (!same_identity(identity_from_words(words), contract.identity)) {
                return reject(
                    npu_system_session_error::command_contract,
                    "command[" + std::to_string(index) +
                        "] identity differs from the dispatch contract");
            }
            const npu_system_f32_alu_contract & f32 = contract.f32_alu;
            if (f32.request_groups != f32.read_groups + f32.write_groups ||
                f32.response_groups != f32.request_groups ||
                f32.read_bytes != f32.input_words * 4U ||
                f32.write_bytes != f32.output_words * 4U ||
                f32.expected_starts > 1U ||
                (f32.expected_starts == 0U &&
                 (f32.request_groups != 0U || f32.response_groups != 0U ||
                  f32.read_groups != 0U || f32.write_groups != 0U ||
                  f32.input_words != 0U || f32.output_words != 0U ||
                  f32.read_bytes != 0U || f32.write_bytes != 0U ||
                  f32.completion_vector_elements != 0U))) {
                return reject(
                    npu_system_session_error::command_contract,
                    "command[" + std::to_string(index) +
                        "] has an internally inconsistent F32 portal contract");
            }
            const bool expected_fatal =
                contract.expected_outcome ==
                    npu_system_expected_outcome::fatal_npu_fault;
            const bool expected_fault =
                contract.expected_outcome !=
                    npu_system_expected_outcome::success;
            if ((!expected_fault && contract.expected_npu_error_code != 0U) ||
                (expected_fault && contract.expected_npu_error_code == 0U) ||
                (expected_fault &&
                 ((contract.expected_npu_error_code & 0x80U) != 0U) !=
                     expected_fatal)) {
                return reject(
                    npu_system_session_error::command_contract,
                    "command[" + std::to_string(index) +
                        "] has an inconsistent expected NPU outcome");
            }
            candidate.push_back(words);
        }
        *output = std::move(candidate);
        return true;
    }

    bool validate_copies(const npu_system_submission & submission,
                         const std::vector<runtime_buffer> & buffers) {
        if (!submission.copies.empty() &&
            submission.copies.size() != submission.commands.size())
            return reject(npu_system_session_error::buffer_capability, "copy table count mismatch");
        for (const auto & pair : submission.copies) for (const auto & c : {pair.before, pair.after}) {
            std::uint64_t src_end = 0, dst_end = 0;
            if (!c.bytes) {
                if (c.src || c.dst) return reject(npu_system_session_error::buffer_capability, "empty copy has addresses");
                continue;
            }
            if (!checked_add(c.src, c.bytes, &src_end) || !checked_add(c.dst, c.bytes, &dst_end) ||
                !window_registered(buffers, c.src, c.bytes, 1) ||
                !window_registered(buffers, c.dst, c.bytes, 2) ||
                (c.src < dst_end && c.dst < src_end))
                return reject(npu_system_session_error::buffer_capability, "copy ranges overlap or escape capabilities");
        }
        return true;
    }

    bool validate_buffers(
            const npu_system_submission & submission,
            const std::vector<npu_command_abi_words> & descriptors,
            std::vector<runtime_buffer> * output) {
        if (output == nullptr || submission.buffers.empty()) {
            return reject(npu_system_session_error::buffer_capability,
                          "submission has no registered raw buffers");
        }
        std::vector<runtime_buffer> candidate;
        try {
            candidate.reserve(submission.buffers.size());
        } catch (const std::bad_alloc &) {
            return reject(npu_system_session_error::allocation_failure,
                          "cannot allocate raw-buffer capability table");
        }
        for (const npu_system_raw_buffer & source : submission.buffers) {
            if (source.id.empty() || source.bytes == nullptr ||
                source.permissions == 0U || source.permissions > 3U ||
                source.bytes->empty()) {
                return reject(npu_system_session_error::buffer_capability,
                              "invalid raw-buffer capability");
            }
            std::uint64_t end = 0U;
            if (!checked_add(source.base, source.bytes->size(), &end)) {
                return reject(npu_system_session_error::buffer_capability,
                              "raw-buffer capability address overflow");
            }
            for (const runtime_buffer & previous : candidate) {
                if (previous.id == source.id) {
                    return reject(npu_system_session_error::buffer_capability,
                                  "duplicate raw BufferId " + source.id);
                }
                const std::uint64_t previous_end =
                    previous.base + previous.bytes->size();
                if (source.base < previous_end && previous.base < end) {
                    return reject(npu_system_session_error::buffer_capability,
                                  "overlapping raw-buffer capabilities");
                }
            }
            runtime_buffer buffer = {};
            buffer.id = source.id;
            buffer.base = source.base;
            buffer.permissions = source.permissions;
            buffer.bytes = source.bytes;
            buffer.activity.id = source.id;
            candidate.push_back(std::move(buffer));
        }

        for (std::size_t index = 0; index < descriptors.size(); ++index) {
            const npu_command_abi_words & words = descriptors[index];
            const std::uint32_t packed = static_cast<std::uint32_t>(words[25]);
            if (!window_registered(candidate, words[23], words[24],
                                   (packed >> 2U) & 3U) ||
                !window_registered(candidate, words[26], words[27],
                                   (packed >> 4U) & 3U) ||
                !window_registered(candidate, words[28], words[29],
                                   (packed >> 6U) & 3U)) {
                return reject(
                    npu_system_session_error::buffer_capability,
                    "command[" + std::to_string(index) +
                        "] window escaped registered raw buffers");
            }
        }
        *output = std::move(candidate);
        return true;
    }

    static bool window_registered(
            const std::vector<runtime_buffer> & buffers,
            std::uint64_t base,
            std::uint64_t size,
            std::uint32_t permission) {
        if (permission == 0U) {
            return base == 0U && size == 0U;
        }
        if (size == 0U) {
            // Exact unary/norm and REPEAT retain the ABI's read-only,
            // absent src1 window (base=address=size=0); it grants no byte.
            if (base == 0U) return true;
            // A zero-cardinality VIEW may lie inside a merged allocation.
            // Its aligned zero-byte capability must lie in that allocation
            // (including its end); it still grants no readable/writable byte.
            return base != 0U && (base & 7U) == 0U &&
                std::any_of(
                    buffers.begin(), buffers.end(),
                    [&](const runtime_buffer & buffer) {
                        return (buffer.permissions & permission) == permission &&
                            range_contains(buffer.base, buffer.bytes->size(), base, 0);
                    });
        }
        if (size > SIZE_MAX) {
            return false;
        }
        return std::any_of(
            buffers.begin(), buffers.end(),
            [&](const runtime_buffer & buffer) {
                return (buffer.permissions & permission) == permission &&
                    range_contains(buffer.base, buffer.bytes->size(), base,
                                   static_cast<std::size_t>(size));
            });
    }

    std::array<runtime_buffer *, 4> buffer_cache_ = {};
    std::size_t buffer_cache_next_ = 0;
    runtime_buffer * find_buffer(
            std::uint64_t address,
            std::size_t bytes,
            std::uint32_t permission) {
        for (auto * b : buffer_cache_) if (b &&
            (b->permissions & permission) == permission &&
            range_contains(b->base, b->bytes->size(), address, bytes)) return b;
        const auto found = std::find_if(
            buffers_.begin(), buffers_.end(),
            [&](const runtime_buffer & buffer) {
                return (buffer.permissions & permission) == permission &&
                    range_contains(buffer.base, buffer.bytes->size(), address,
                                   bytes);
            });
        if (found == buffers_.end()) return nullptr;
        buffer_cache_[buffer_cache_next_++ % buffer_cache_.size()] = &*found;
        return &*found;
    }

    bool read_raw32(std::uint64_t address, std::uint32_t * value) {
        runtime_buffer * buffer = find_buffer(address, 4U, 1U);
        if (buffer == nullptr || value == nullptr) {
            return set_fatal(
                npu_system_session_error::buffer_capability,
                "F32 read escaped a registered readable buffer");
        }
        *value = load_le32(buffer->bytes->data() +
                           static_cast<std::size_t>(address - buffer->base));
        ++buffer->activity.read_words;
        if (buffer->written) {
            ++buffer->activity.reads_after_write;
        }
        return true;
    }

    bool write_raw32(std::uint64_t address, std::uint32_t value) {
        runtime_buffer * buffer = find_buffer(address, 4U, 2U);
        if (buffer == nullptr) {
            return set_fatal(
                npu_system_session_error::buffer_capability,
                "F32 write escaped a registered writable buffer");
        }
        store_le32(buffer->bytes->data() +
                       static_cast<std::size_t>(address - buffer->base),
                   value);
        ++buffer->activity.write_words;
        buffer->written = true;
        return true;
    }

    bool prepare_portal_response(portal_response * accepted) {
        if (accepted == nullptr || active_command_ >= observed_.size()) {
            return set_fatal(npu_system_session_error::portal_protocol,
                             "F32 request has no active command owner");
        }
        if (contracts_[active_command_].owner != npu_system_command_owner::f32_alu)
            return memory_fail("owner unexpectedly requested F32 ALU portal");
        const bool binary = descriptors_[active_command_][26] != 0U;
        const bool write = top_->f32_alu_portal_req_write_o != 0U;
        const std::uint8_t mask = top_->f32_alu_portal_req_mask_o;
        if (mask == 0U) {
            return set_fatal(npu_system_session_error::portal_protocol,
                             "F32 portal published an empty request mask");
        }
        accepted->mask = mask;
        accepted->command = active_command_;
        std::uint64_t active_lanes = 0U;
        for (std::size_t lane = 0; lane < kLaneCount; ++lane) {
            const bool active = (mask & (1U << lane)) != 0U;
            const std::uint64_t src0 = portal_lane_address(
                top_->f32_alu_portal_req_src0_addr_o, lane);
            const std::uint64_t src1 = portal_lane_address(
                top_->f32_alu_portal_req_src1_addr_o, lane);
            const std::uint64_t dst = portal_lane_address(
                top_->f32_alu_portal_req_dst_addr_o, lane);
            const std::uint32_t wdata =
                top_->f32_alu_portal_req_wdata_o[lane];
            if (!active) {
                if (src0 != 0U || src1 != 0U || dst != 0U || wdata != 0U) {
                    return set_fatal(
                        npu_system_session_error::portal_protocol,
                        "inactive F32 portal lane carried payload");
                }
                continue;
            }
            ++active_lanes;
            if (write) {
                if (src0 != 0U || src1 != 0U || dst == 0U ||
                    !command_range(dst, 4, true) || !write_raw32(dst, wdata)) {
                    return false;
                }
            } else if (dst != 0U || wdata != 0U || src0 == 0U ||
                       (binary ? src1 == 0U : src1 != 0U) ||
                       !command_range(src0, 4, false) ||
                       !read_raw32(src0, &accepted->src0[lane]) ||
                       (binary && (!command_range(src1, 4, false) ||
                        !read_raw32(src1, &accepted->src1[lane])))) {
                return false;
            }
        }
        command_observed & observed = observed_[active_command_];
        ++observed.request_groups;
        ++counters_.portal_requests;
        if (write) {
            ++observed.write_groups;
            observed.output_words += active_lanes;
            observed.write_bytes += active_lanes * 4U;
            ++counters_.portal_writes;
            counters_.portal_output_words += active_lanes;
            counters_.portal_write_bytes += active_lanes * 4U;
        } else {
            ++observed.read_groups;
            observed.input_words += active_lanes * (binary ? 2U : 1U);
            observed.read_bytes += active_lanes * (binary ? 8U : 4U);
            ++counters_.portal_reads;
            counters_.portal_input_words += active_lanes * (binary ? 2U : 1U);
            counters_.portal_read_bytes += active_lanes * (binary ? 8U : 4U);
        }
        return true;
    }

    bool capture_command() {
        const std::uint64_t bits = top_->cpu_tensor_cmd_bits_o;
        if (bits == kLaunchBits) {
            const std::uint64_t launched =
                counters_.launch_accepts - generation_launch_base_;
            if (launched >= descriptors_.size() ||
                counters_.config_accepts - generation_config_base_ !=
                    (launched + 1U) * NPU_COMMAND_ABI_WORD_COUNT ||
                active_command_ != kNoCommand) {
                return set_fatal(
                    npu_system_session_error::portal_protocol,
                    "launch did not follow exactly 30 ordered CONFIGs");
            }
            active_command_ = static_cast<std::size_t>(launched);
            last_progress_cycle_ = counters_.cycles;
            if (contracts_.size() > 2)
                std::fprintf(stderr, "[NPU-SERVICE][LAUNCH] generation=%llu command=%zu graph_index=%llu kernel=%08x cycle=%llu\n",
                    (unsigned long long)active_generation_, active_command_,
                    (unsigned long long)contracts_[active_command_].identity.user_tag,
                    contracts_[active_command_].identity.kernel_id,
                    (unsigned long long)counters_.cycles);
            cpu_producer_ids_[active_command_] =
                static_cast<std::uint8_t>(
                    top_->cpu_tensor_cmd_producer_id_o);
            ++counters_.launch_accepts;
            return true;
        }
        const std::uint32_t low = static_cast<std::uint32_t>(bits);
        if ((bits >> 32U) == 0U && low == kRecoveryClearBits) {
            if (!fault_terminal_seen_ || fault_terminal_fatal_ ||
                recovery_clear_command_seen_) {
                return set_fatal(
                    npu_system_session_error::portal_protocol,
                    "unexpected or repeated architectural CONFIG-30 clear");
            }
            recovery_clear_command_seen_ = true;
            return true;
        }
        if ((bits >> 32U) != 0U ||
            (low & kConfigFixedMask) != kConfigFixedBits) {
            return set_fatal(npu_system_session_error::portal_protocol,
                             "RV64 emitted an unsupported Tensor instruction");
        }
        const std::uint32_t index = (low & kConfigIndexMask) >> 20U;
        const std::uint64_t ordinal =
            counters_.config_accepts - generation_config_base_;
        if (ordinal / NPU_COMMAND_ABI_WORD_COUNT >= descriptors_.size() ||
            index != ordinal % NPU_COMMAND_ABI_WORD_COUNT) {
            return set_fatal(npu_system_session_error::portal_protocol,
                             "firmware CONFIG order was not 0..29");
        }
        ++counters_.config_accepts;
        return true;
    }

    bool capture_terminal() {
        if (top_->macro_completion_valid_o == 0U) {
            if (top_->npu_terminal_error_o != 0U ||
                top_->npu_terminal_error_code_o != 0U) {
                return set_fatal(
                    npu_system_session_error::terminal_mismatch,
                    "non-macro Tensor instruction completed with error");
            }
            if (recovery_clear_command_seen_) {
                if (recovery_clear_terminal_seen_) {
                    return set_fatal(
                        npu_system_session_error::terminal_mismatch,
                        "architectural CONFIG-30 clear completed twice");
                }
                recovery_clear_terminal_seen_ = true;
            }
            return true;
        }
        if (active_command_ >= contracts_.size()) {
            return set_fatal(npu_system_session_error::terminal_mismatch,
                             "NPU terminal has no active command");
        }
        const npu_system_command_contract & contract =
            contracts_[active_command_];
        const npu_system_command_identity actual = {
            top_->macro_completion_kernel_id_o,
            top_->macro_completion_command_flags_o,
            top_->macro_completion_context_id_o,
            top_->macro_completion_sequence_id_o,
            top_->completion_macro_producer_id_o,
            top_->macro_completion_user_tag_o,
            top_->macro_completion_covered_node_count_o,
            top_->macro_completion_node_hash_lo_o,
            top_->macro_completion_node_hash_hi_o,
            top_->macro_completion_vector_flags_o,
        };
        if (top_->npu_identity_match_o == 0U ||
            !same_identity(actual, contract.identity)) {
            return set_fatal(npu_system_session_error::terminal_mismatch,
                             "NPU terminal identity mismatch");
        }
        if (top_->npu_terminal_error_o != 0U) {
            const std::uint8_t code = static_cast<std::uint8_t>(
                top_->npu_terminal_error_code_o);
            const bool fatal = (code & 0x80U) != 0U;
            const npu_system_expected_outcome expected =
                fatal ? npu_system_expected_outcome::fatal_npu_fault :
                        npu_system_expected_outcome::recoverable_npu_fault;
            const bool explicitly_expected = contract.expected_outcome !=
                npu_system_expected_outcome::success;
            if ((explicitly_expected &&
                 (contract.expected_outcome != expected ||
                  contract.expected_npu_error_code != code)) ||
                fault_terminal_seen_) {
                return set_fatal(
                    npu_system_session_error::terminal_mismatch,
                    "unexpected NPU terminal error classification/code");
            }
            fault_terminal_seen_ = true;
            fault_terminal_fatal_ = fatal;
            fault_terminal_code_ = code;
            ++counters_.macro_terminals;
            active_command_ = kNoCommand;
            return true;
        }
        if (contract.expected_outcome !=
                npu_system_expected_outcome::success ||
            top_->npu_terminal_error_code_o != 0U ||
            top_->macro_completion_status_o != 0U ||
            top_->macro_completion_error_class_o != 0U ||
            top_->macro_completion_gmem_read_bytes_o != contract.memory.gmem_read_bytes ||
            top_->macro_completion_gmem_write_bytes_o != contract.memory.gmem_write_bytes ||
            top_->macro_completion_q8_mac_count_o != contract.memory.q8_macs ||
            top_->macro_completion_vector_element_count_o !=
                (contract.owner == npu_system_command_owner::f32_alu ?
                 contract.f32_alu.completion_vector_elements : contract.memory.vector_elements) ||
            top_->macro_completion_state_update_count_o != contract.memory.state_updates) {
            return set_fatal(npu_system_session_error::terminal_mismatch,
                             "NPU terminal identity/status/accounting mismatch");
        }
        const command_observed & observed = observed_[active_command_];
        const npu_system_f32_alu_contract & expected = contract.f32_alu;
        if (observed.request_groups != expected.request_groups ||
            observed.response_groups != expected.response_groups ||
            observed.read_groups != expected.read_groups ||
            observed.write_groups != expected.write_groups ||
            observed.input_words != expected.input_words ||
            observed.output_words != expected.output_words ||
            observed.read_bytes != expected.read_bytes ||
            observed.write_bytes != expected.write_bytes ||
            top_->f32_alu_portal_outstanding_o != 0U ||
            (expected.expected_starts != 0U &&
             (top_->f32_alu_portal_request_groups_o !=
                  expected.request_groups ||
              top_->f32_alu_portal_response_groups_o !=
                  expected.response_groups ||
              top_->f32_alu_portal_read_groups_o != expected.read_groups ||
              top_->f32_alu_portal_write_groups_o != expected.write_groups ||
              top_->f32_alu_portal_input_words_o != expected.input_words ||
              top_->f32_alu_portal_output_words_o != expected.output_words ||
              top_->f32_alu_portal_read_bytes_o != expected.read_bytes ||
              top_->f32_alu_portal_write_bytes_o != expected.write_bytes))) {
            return set_fatal(npu_system_session_error::terminal_mismatch,
                             "F32 portal traffic differs from command contract");
        }
        if (!verify_memory_owner(observed, contract.memory)) return false;
        if (contracts_.size() > 2)
            std::fprintf(stderr, "[NPU-SERVICE][TERMINAL] generation=%llu command=%zu graph_index=%llu cycles=%llu\n",
                (unsigned long long)active_generation_, active_command_,
                (unsigned long long)contract.identity.user_tag,
                (unsigned long long)(counters_.cycles - last_progress_cycle_));
        last_progress_cycle_ = counters_.cycles;
        counters_.vector_elements += top_->macro_completion_vector_element_count_o;
        ++counters_.macro_terminals;
        active_command_ = kNoCommand;
        return true;
    }

#include "npu-system-memory.inc"

    bool tick() {
        if (fatal_ || top_ == nullptr) {
            return false;
        }
        if (dispatch_active_) {
            const auto completed = mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET);
            if (completed != progress_completed_ && active_command_ == kNoCommand) {
                progress_completed_ = completed;
                last_progress_cycle_ = counters_.cycles;
            }
            std::uint64_t budget = 1000000;
            std::size_t owner = active_command_;
            if (owner < contracts_.size()) {
                budget = contracts_[owner].max_cycles;
            } else {
                owner = mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET);
                if (owner < copies_.size())
                    budget += (copies_[owner].before.bytes + copies_[owner].after.bytes) * 64;
            }
            if (budget && counters_.cycles - last_progress_cycle_ > budget)
                return set_fatal(npu_system_session_error::timeout, "command[" + std::to_string(owner) +
                    "] exceeded compiler operation/transport cycle budget " + std::to_string(budget));
        }
        const bool out_of_reset = top_->rst == 0U;
        const bool response_fire = out_of_reset && response_.occupied &&
            top_->f32_alu_portal_rsp_ready_o != 0U;
        const bool request_fire = out_of_reset &&
            top_->f32_alu_portal_req_valid_o != 0U &&
            top_->f32_alu_portal_req_ready_i != 0U;
        const bool command_fire = out_of_reset &&
            top_->cpu_tensor_cmd_valid_o != 0U &&
            top_->cpu_tensor_cmd_ready_o != 0U;
        const bool terminal_fire = out_of_reset &&
            top_->npu_terminal_valid_o != 0U &&
            top_->npu_terminal_ready_o != 0U;

        if (out_of_reset && !tick_memory_before_edge()) return false;
        if (out_of_reset && top_->npu_error_o != 0U &&
            !fault_terminal_seen_ &&
            !(terminal_fire && top_->npu_terminal_error_o != 0U)) {
            return set_fatal(
                npu_system_session_error::terminal_mismatch,
                "NPU entered error hold code=" +
                    std::to_string(static_cast<unsigned>(
                        top_->npu_error_code_o)));
        }

        // Credit a response on the same edge before validating a coincident
        // terminal, so each per-command contract observes its final response.
        if (response_fire) {
            if (response_.command >= observed_.size()) {
                return set_fatal(npu_system_session_error::portal_protocol,
                                 "F32 response owner is invalid");
            }
            ++observed_[response_.command].response_groups;
            ++counters_.portal_responses;
        }
        portal_response accepted = {};
        if (request_fire) {
            if (response_.occupied || !prepare_portal_response(&accepted)) {
                return false;
            }
            accepted.occupied = true;
        }
        if (command_fire && !capture_command()) {
            return false;
        }
        if (terminal_fire && !capture_terminal()) {
            return false;
        }
        if (out_of_reset && top_->npu_error_clear_pulse_o != 0U) {
            ++counters_.rtl_error_clears;
        }

        top_->clk = 1U;
        top_->eval();
        context_->timeInc(1U);
        ++counters_.cycles;
        if (response_fire) {
            response_ = {};
        }
        if (request_fire) {
            response_ = accepted;
        }
        memory_after_edge();
        top_->clk = 0U;
        drive_inputs();
        top_->eval();
        context_->timeInc(1U);
        return !fatal_;
    }

    bool verify_fault(
            const npu_system_counters & before,
            bool fatal_fault) {
        if (!fault_terminal_seen_ || fault_terminal_fatal_ != fatal_fault ||
            descriptors_.empty()) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "mailbox fault has no matching NPU terminal");
        }
        const std::size_t fault_index = static_cast<std::size_t>(
            counters_.macro_terminals - generation_terminal_base_ - 1U);
        if (fault_index >= descriptors_.size()) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "fault command does not match its contract");
        }
        const npu_system_command_contract & fault_contract =
            contracts_[fault_index];
        const bool explicitly_expected = fault_contract.expected_outcome !=
            npu_system_expected_outcome::success;
        if (explicitly_expected &&
            (fault_contract.expected_outcome !=
                 (fatal_fault ? npu_system_expected_outcome::fatal_npu_fault :
                                npu_system_expected_outcome::recoverable_npu_fault) ||
             fault_contract.expected_npu_error_code != fault_terminal_code_)) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "fault command does not match its contract");
        }
        const std::uint32_t expected_mailbox_error = fatal_fault ?
            NPU_SERVICE_ERROR_NPU_FATAL : NPU_SERVICE_ERROR_NPU_FAULT;
        const std::uint32_t expected_status = fatal_fault ?
            NPU_SERVICE_COMPLETION_STATUS_NPU_FATAL :
            NPU_SERVICE_COMPLETION_STATUS_NPU_FAULT;
        if (mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET) != 1U ||
            mailbox32(NPU_SERVICE_MB_ERROR_OFFSET) != expected_mailbox_error ||
            mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET) != fault_index + 1U) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "precise-fault mailbox fields mismatch");
        }
        const std::size_t offset = static_cast<std::size_t>(
            NPU_SERVICE_COMPLETION_ADDRESS - kNcBase) +
            fault_index * NPU_SERVICE_COMPLETION_STRIDE;
        const npu_command_abi_words & descriptor = descriptors_[fault_index];
        const std::uint64_t tval = load_le64(
            nc_memory_.data() + offset + NPU_SERVICE_CPL_FAULT_TVAL_OFFSET);
        const std::uint64_t pc = load_le64(
            nc_memory_.data() + offset + NPU_SERVICE_CPL_FAULT_PC_OFFSET);
        const std::uint64_t cause = load_le64(
            nc_memory_.data() + offset + NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET);
        const bool tval_fatal = (tval >> NPU_SERVICE_NPU_FAULT_FATAL_BIT) != 0U;
        const std::uint64_t tval_version =
            (tval >> NPU_SERVICE_NPU_FAULT_VERSION_SHIFT) &
            NPU_SERVICE_NPU_FAULT_VERSION_MASK;
        const std::uint8_t tval_code =
            static_cast<std::uint8_t>((tval >> 56U) & 0x7fU);
        const std::uint8_t tval_cpu_pid =
            static_cast<std::uint8_t>((tval >> 48U) & 0xffU);
        const std::uint8_t tval_opclass =
            static_cast<std::uint8_t>((tval >> 40U) & 0xffU);
        const bool tval_required = ((tval >> 39U) & 1U) != 0U;
        const bool tval_is_64 = ((tval >> 38U) & 1U) != 0U;
        if (load_le64(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_GENERATION_OFFSET) !=
                active_generation_ ||
            load_le32(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_INDEX_OFFSET) != fault_index ||
            load_le32(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_STATUS_OFFSET) != expected_status ||
            load_le64(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_SEQUENCE_OFFSET) != descriptor[2] ||
            load_le64(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_PRODUCER_OFFSET) != descriptor[3] ||
            load_le64(nc_memory_.data() + offset +
                      NPU_SERVICE_CPL_USER_TAG_OFFSET) != descriptor[4] ||
            tval_fatal != fatal_fault ||
            tval_version != NPU_SERVICE_NPU_FAULT_MTVAL_VERSION ||
            tval_code != (fault_terminal_code_ & 0x7fU) || pc == 0U ||
            tval_cpu_pid != cpu_producer_ids_[fault_index] ||
            tval_opclass != 1U || !tval_required || !tval_is_64 ||
            static_cast<std::uint32_t>(tval) != kLaunchLo ||
            pc != firmware_launch_pc_ ||
            cause != NPU_SERVICE_NPU_FAULT_MCAUSE || fault_trap_count_ != 1U) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "precise-fault completion/mtval fields mismatch");
        }

        const npu_system_counters delta = counter_delta(snapshot(), before);
        npu_system_f32_alu_contract aggregate = {};
        std::uint64_t completed_prefix_starts = 0U;
        for (std::size_t index = 0; index <= fault_index; ++index) {
            aggregate.request_groups += contracts_[index].f32_alu.request_groups;
            aggregate.response_groups += contracts_[index].f32_alu.response_groups;
            aggregate.read_groups += contracts_[index].f32_alu.read_groups;
            aggregate.write_groups += contracts_[index].f32_alu.write_groups;
            aggregate.input_words += contracts_[index].f32_alu.input_words;
            aggregate.output_words += contracts_[index].f32_alu.output_words;
            aggregate.read_bytes += contracts_[index].f32_alu.read_bytes;
            aggregate.write_bytes += contracts_[index].f32_alu.write_bytes;
            aggregate.expected_starts +=
                contracts_[index].f32_alu.expected_starts;
            if (index < fault_index) {
                completed_prefix_starts +=
                    contracts_[index].f32_alu.expected_starts;
            }
        }
        const bool fault_start_count_matches = explicitly_expected ?
            delta.rtl_f32_starts == aggregate.expected_starts :
            (delta.rtl_f32_starts >= completed_prefix_starts &&
             delta.rtl_f32_starts <= aggregate.expected_starts);
        if (delta.config_accepts !=
                (fault_index + 1U) * NPU_COMMAND_ABI_WORD_COUNT ||
            delta.launch_accepts != fault_index + 1U ||
            delta.macro_terminals != fault_index + 1U ||
            (explicitly_expected &&
             (delta.portal_requests != aggregate.request_groups ||
              delta.portal_responses != aggregate.response_groups ||
              delta.portal_reads != aggregate.read_groups ||
              delta.portal_writes != aggregate.write_groups ||
              delta.portal_input_words != aggregate.input_words ||
              delta.portal_output_words != aggregate.output_words ||
              delta.portal_read_bytes != aggregate.read_bytes ||
            delta.portal_write_bytes != aggregate.write_bytes)) ||
            delta.rtl_macro_commands != fault_index + 1U ||
            !fault_start_count_matches ||
            delta.rtl_macro_completions != fault_index ||
            delta.rtl_error_clears != (fatal_fault ? 0U : 1U) ||
            delta.traps == 0U || delta.exits != 0U ||
            recovery_clear_command_seen_ == fatal_fault ||
            recovery_clear_terminal_seen_ == fatal_fault) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "precise-fault counter/recovery mismatch");
        }
        if (!fatal_fault &&
            (top_->npu_error_o != 0U ||
             top_->direct_f32_desc_resident_o != 0U ||
             top_->descriptor_inflight_o != 0U ||
             top_->descriptor_expected_index_o != 0U ||
             top_->launch_cpu_pid_o != 0U)) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "recoverable fault did not leave clean state");
        }
        return true;
    }

    bool verify_dispatch(const npu_system_counters & before) {
        if (mailbox64(NPU_SERVICE_MB_BOOT_COUNT_OFFSET) != 1U ||
            mailbox32(NPU_SERVICE_MB_COMPLETED_OFFSET) != contracts_.size() ||
            mailbox32(NPU_SERVICE_MB_ERROR_OFFSET) != NPU_SERVICE_ERROR_NONE) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "mailbox boot/completed/error mismatch");
        }
        const npu_system_counters after = snapshot();
        const npu_system_counters delta = counter_delta(after, before);
        std::uint64_t copy_count = 0, copy_bytes = 0;
        for (std::size_t i=0;i<copies_.size();++i) {
            const unsigned expected = (copies_[i].before.bytes ? 1:0) | (copies_[i].after.bytes ? 2:0);
            if (dma_issued_[i] != expected)
                return set_fatal(npu_system_session_error::completion_mismatch,"firmware omitted a compiled DMA transfer");
            copy_count += (expected&1 ? 1:0) + (expected&2 ? 1:0);
            copy_bytes += copies_[i].before.bytes + copies_[i].after.bytes;
        }
        if (delta.dma_starts != copy_count || delta.dma_completions != copy_count ||
            delta.dma_write_bytes != copy_bytes || dma_inflight_ || dma_pending_ || dma_response_.occupied)
            return set_fatal(npu_system_session_error::completion_mismatch,"DMA aggregate ledger mismatch");
        npu_system_f32_alu_contract aggregate = {};
        for (const npu_system_command_contract & command : contracts_) {
            aggregate.request_groups += command.f32_alu.request_groups;
            aggregate.response_groups += command.f32_alu.response_groups;
            aggregate.read_groups += command.f32_alu.read_groups;
            aggregate.write_groups += command.f32_alu.write_groups;
            aggregate.input_words += command.f32_alu.input_words;
            aggregate.output_words += command.f32_alu.output_words;
            aggregate.read_bytes += command.f32_alu.read_bytes;
            aggregate.write_bytes += command.f32_alu.write_bytes;
            aggregate.expected_starts += command.f32_alu.expected_starts;
        }
        if (delta.config_accepts !=
                contracts_.size() * NPU_COMMAND_ABI_WORD_COUNT ||
            delta.launch_accepts != contracts_.size() ||
            delta.macro_terminals != contracts_.size() ||
            delta.portal_requests != aggregate.request_groups ||
            delta.portal_responses != aggregate.response_groups ||
            delta.portal_reads != aggregate.read_groups ||
            delta.portal_writes != aggregate.write_groups ||
            delta.portal_input_words != aggregate.input_words ||
            delta.portal_output_words != aggregate.output_words ||
            delta.portal_read_bytes != aggregate.read_bytes ||
            delta.portal_write_bytes != aggregate.write_bytes ||
            delta.rtl_macro_commands != contracts_.size() ||
            delta.rtl_f32_starts != aggregate.expected_starts ||
            delta.rtl_macro_completions != contracts_.size() ||
            delta.rtl_error_clears != 0U || delta.traps != 0U ||
            delta.exits != 0U) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "submission aggregate counter mismatch");
        }
        if (response_.occupied || active_command_ != kNoCommand ||
            top_->f32_alu_portal_outstanding_o != 0U ||
            top_->direct_f32_desc_resident_o != 0U ||
            top_->descriptor_inflight_o != 0U ||
            top_->descriptor_expected_index_o != 0U ||
            top_->launch_cpu_pid_o != 0U || top_->npu_error_o != 0U) {
            return set_fatal(npu_system_session_error::completion_mismatch,
                             "SystemTop state was not clean after DONE");
        }
        for (std::size_t index = 0; index < descriptors_.size(); ++index) {
            const std::size_t offset = static_cast<std::size_t>(
                NPU_SERVICE_COMPLETION_ADDRESS - kNcBase) +
                index * NPU_SERVICE_COMPLETION_STRIDE;
            const npu_command_abi_words & descriptor = descriptors_[index];
            if (load_le64(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_GENERATION_OFFSET) !=
                    active_generation_ ||
                load_le32(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_INDEX_OFFSET) != index ||
                load_le32(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_STATUS_OFFSET) != 0U ||
                load_le64(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_SEQUENCE_OFFSET) != descriptor[2] ||
                load_le64(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_PRODUCER_OFFSET) != descriptor[3] ||
                load_le64(nc_memory_.data() + offset +
                          NPU_SERVICE_CPL_USER_TAG_OFFSET) != descriptor[4]) {
                return set_fatal(
                    npu_system_session_error::completion_mismatch,
                    "firmware completion record identity mismatch");
            }
        }
        return true;
    }

    npu_system_counters snapshot() const {
        npu_system_counters result = counters_;
        if (top_ != nullptr) {
            result.rtl_macro_commands = top_->npu_macro_command_count_o;
            result.rtl_f32_starts = top_->npu_macro_f32_start_count_o;
            result.rtl_macro_completions =
                top_->npu_macro_completion_count_o;
        }
        return result;
    }

    void drive_inputs() {
        if (top_ == nullptr) {
            return;
        }
        top_->terminal_allow_i = 1U;
        drive_memory_inputs();
        top_->f32_alu_portal_req_ready_i =
            top_->rst == 0U && dispatch_active_ && !response_.occupied ?
            1U : 0U;
        top_->f32_alu_portal_rsp_valid_i = response_.occupied ? 1U : 0U;
        top_->f32_alu_portal_rsp_mask_i =
            response_.occupied ? response_.mask : 0U;
        top_->f32_alu_portal_rsp_error_i = 0U;
        for (std::size_t lane = 0; lane < kLaneCount; ++lane) {
            top_->f32_alu_portal_rsp_src0_data_i[lane] =
                response_.occupied ? response_.src0[lane] : 0U;
            top_->f32_alu_portal_rsp_src1_data_i[lane] =
                response_.occupied ? response_.src1[lane] : 0U;
        }

    }

    template <typename Memory>
    static std::uint64_t read_bytes(
            const Memory & memory,
            std::size_t offset,
            std::size_t bytes) {
        std::uint64_t value = 0U;
        for (std::size_t index = 0; index < bytes; ++index) {
            value |= static_cast<std::uint64_t>(memory[offset + index]) <<
                     (8U * index);
        }
        return value;
    }

    void put_nc16(std::size_t offset, std::uint16_t value) {
        store_le16(nc_memory_.data() + offset, value);
    }
    void put_nc32(std::size_t offset, std::uint32_t value) {
        store_le32(nc_memory_.data() + offset, value);
    }
    void put_nc64(std::size_t offset, std::uint64_t value) {
        store_le64(nc_memory_.data() + offset, value);
    }
    std::uint32_t mailbox32(std::size_t offset) const {
        return load_le32(nc_memory_.data() + offset);
    }
    std::uint64_t mailbox64(std::size_t offset) const {
        return load_le64(nc_memory_.data() + offset);
    }

    bool owns_router_ = false;
    bool booted_ = false;
    bool fatal_ = false;
    bool dispatch_active_ = false;
    npu_system_session_error last_error_ = npu_system_session_error::none;
    std::string failure_;
    std::string fatal_reason_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VNpcTensorNpuSystemTop> top_;
    std::array<std::uint8_t, kCpuBytes> cpu_memory_ = {};
    std::vector<std::uint8_t> nc_memory_;
    std::vector<runtime_buffer> buffers_;
    std::vector<npu_command_abi_words> descriptors_;
    std::vector<npu_system_command_contract> contracts_;
    std::vector<npu_system_command_copies> copies_;
    std::vector<command_observed> observed_;
    std::vector<std::uint8_t> cpu_producer_ids_;
    portal_response response_ = {};
    npu_system_counters counters_ = {};
    std::uint64_t constructor_count_ = 0U;
    std::uint64_t reset_release_count_ = 0U;
    std::uint64_t firmware_launch_pc_ = 0U;
    std::uint64_t last_generation_ = 0U;
    std::uint64_t last_progress_cycle_ = 0U;
    std::uint32_t progress_completed_ = 0;
    std::uint64_t active_generation_ = 0U;
    std::uint64_t generation_config_base_ = 0U;
    std::uint64_t generation_launch_base_ = 0U;
    std::uint64_t generation_terminal_base_ = 0U;
    std::size_t active_command_ = kNoCommand;
    bool fault_terminal_seen_ = false;
    bool fault_terminal_fatal_ = false;
    std::uint8_t fault_terminal_code_ = 0U;
    bool recovery_clear_command_seen_ = false;
    bool recovery_clear_terminal_seen_ = false;
    std::uint64_t fault_trap_count_ = 0U;
};

npu_system_session::npu_system_session(int argc, char ** argv)
    : impl_(std::make_unique<impl>(argc, argv)) {}

npu_system_session::~npu_system_session() = default;

bool npu_system_session::ready() const {
    return impl_ != nullptr && impl_->ready();
}

bool npu_system_session::fatal() const {
    return impl_ == nullptr || impl_->fatal();
}

npu_system_session_error npu_system_session::last_error() const {
    return impl_ == nullptr ? npu_system_session_error::allocation_failure :
                             impl_->last_error();
}

const std::string & npu_system_session::failure() const {
    static const std::string kMissingImpl = "session implementation missing";
    return impl_ == nullptr ? kMissingImpl : impl_->failure();
}

npu_system_session_status npu_system_session::status() const {
    return impl_ == nullptr ? npu_system_session_status{} : impl_->status();
}

bool npu_system_session::dispatch(
        const npu_system_submission & submission,
        npu_system_dispatch_result * result) {
    return impl_ != nullptr && impl_->dispatch(submission, result);
}

const char * npu_system_session_error_string(npu_system_session_error error) {
    switch (error) {
        case npu_system_session_error::none: return "none";
        case npu_system_session_error::router_busy: return "DPI router busy";
        case npu_system_session_error::allocation_failure: return "allocation failure";
        case npu_system_session_error::firmware_image: return "firmware image mismatch";
        case npu_system_session_error::boot_timeout: return "firmware boot timeout";
        case npu_system_session_error::session_fatal: return "session fatal";
        case npu_system_session_error::invalid_submission: return "invalid submission";
        case npu_system_session_error::stale_generation: return "stale generation";
        case npu_system_session_error::command_image: return "invalid command image";
        case npu_system_session_error::command_contract: return "command contract mismatch";
        case npu_system_session_error::unsupported_owner: return "unsupported command owner";
        case npu_system_session_error::buffer_capability: return "buffer capability violation";
        case npu_system_session_error::timeout: return "dispatch timeout";
        case npu_system_session_error::firmware_error: return "firmware error";
        case npu_system_session_error::recoverable_npu_fault: return "recoverable NPU fault";
        case npu_system_session_error::fatal_npu_fault: return "fatal NPU fault";
        case npu_system_session_error::cpu_memory: return "CPU memory violation";
        case npu_system_session_error::portal_protocol: return "portal protocol violation";
        case npu_system_session_error::unexpected_owner: return "unexpected memory owner";
        case npu_system_session_error::terminal_mismatch: return "terminal mismatch";
        case npu_system_session_error::completion_mismatch: return "completion mismatch";
        case npu_system_session_error::unexpected_trap: return "unexpected firmware trap";
    }
    return "unknown session error";
}

extern "C" int npc_ifetch_sized(
        unsigned long long address,
        unsigned int bytes,
        unsigned long long * data,
        svBit * error) {
    std::uint64_t value = 0U;
    const bool ok = g_dpi_target != nullptr && data != nullptr &&
        g_dpi_target->read_instruction(address, bytes, &value);
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
    std::uint64_t value = 0U;
    const bool ok = g_dpi_target != nullptr && data != nullptr &&
        g_dpi_target->read_data(address, bytes, &value);
    if (data != nullptr) {
        *data = value;
    }
    if (error != nullptr) {
        *error = ok ? 0 : 1;
    }
    return 0;
}

extern "C" int npc_mem_write(
        unsigned long long address,
        unsigned long long data,
        unsigned long long mask,
        svBit * error) {
    const bool ok = g_dpi_target != nullptr &&
        g_dpi_target->write_data(address, data, mask);
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
    if (g_dpi_target != nullptr) {
        g_dpi_target->commit(pc, instruction);
    }
}

extern "C" unsigned long long npc_current_cycles() {
    return g_dpi_target == nullptr ? 0U : g_dpi_target->cycles();
}

extern "C" unsigned long long npc_current_commits() {
    return g_dpi_target == nullptr ? 0U : g_dpi_target->commits();
}

extern "C" void npc_exit_event(
        unsigned int,
        unsigned int,
        unsigned int,
        unsigned long long,
        unsigned long long) {
    if (g_dpi_target != nullptr) {
        g_dpi_target->exit_event();
    }
}

extern "C" void npc_mmio_load_event() {}

extern "C" void npc_trap_event(
        unsigned int cause,
        unsigned long long pc,
        unsigned long long) {
    if (g_dpi_target != nullptr) {
        g_dpi_target->trap(cause, pc);
    }
}

extern "C" void npc_handled_trap_event(
        unsigned int,
        unsigned int cause,
        unsigned long long pc,
        unsigned long long) {
    if (g_dpi_target != nullptr) {
        g_dpi_target->trap(cause, pc);
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
        *data = 0U;
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
        *data = 0U;
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
