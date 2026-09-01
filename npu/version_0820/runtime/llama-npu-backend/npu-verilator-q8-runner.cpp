#include "npu-verilator-runner.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <vector>

namespace {

constexpr std::uint32_t kKernelGetRowsQ8 = 0x514e0001U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCapabilityEpoch = 1;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kDtypeF32 = 1;

constexpr std::uint32_t kEmbeddingDim = 1024;
constexpr std::uint32_t kGatheredRows = 1;
constexpr std::uint32_t kVocabularyRows = 248320;
constexpr std::uint64_t kTableRowStride = 1088;
constexpr std::uint64_t kIndexStride = 4;
constexpr std::uint64_t kDstRowStride = 4096;
constexpr std::uint64_t kTableBytes =
    static_cast<std::uint64_t>(kVocabularyRows) * kTableRowStride;
constexpr std::uint64_t kIndexBytes = 4;
constexpr std::uint64_t kDstBytes = 4096;

// These widened, deliberately unaligned IOVAs are frozen by the focused RTL
// qualification.  They prove that neither descriptor admission nor sparse
// last-row request generation truncates the real Qwen embedding footprint.
constexpr std::uint64_t kTableIova = 0x0000000120000002ULL;
constexpr std::uint64_t kTableWindowBase = 0x0000000120000000ULL;
constexpr std::uint64_t kTableWindowSize = 0x00000000101a8008ULL;
constexpr std::uint64_t kIndexIova = 0x0000000240000005ULL;
constexpr std::uint64_t kIndexWindowBase = 0x0000000240000000ULL;
constexpr std::uint64_t kIndexWindowSize = 16;
constexpr std::uint64_t kDstIova = 0x0000000000000900ULL;
constexpr std::uint64_t kDstWindowBase = kDstIova;
constexpr std::uint64_t kDstWindowSize = kDstBytes;

constexpr std::uint64_t kExpectedReadBytes = 1296;
constexpr std::uint64_t kExpectedWriteBytes = 4096;
constexpr std::uint64_t kExpectedElements = 1024;
constexpr std::uint64_t kExpectedReadRequests = 162;
constexpr std::uint64_t kExpectedWriteRequests = 1024;
constexpr std::uint64_t kCycleUpperBound = 200000;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;

constexpr std::uint32_t kNpuErrMacroIova = 16;
constexpr std::uint32_t kAbiErrorIova = 5;

enum q8_runner_error : std::uint32_t {
    q8_runner_ok = 0,
    q8_runner_allocation = 0x120,
    q8_runner_timeout = 0x121,
    q8_runner_reset_interface = 0x122,
    q8_runner_command_interface = 0x123,
    q8_runner_request_protocol = 0x124,
    q8_runner_response_protocol = 0x125,
    q8_runner_completion_protocol = 0x126,
    q8_runner_completion_identity = 0x127,
    q8_runner_completion_framing = 0x128,
    q8_runner_memory_bounds = 0x129,
    q8_runner_result_coverage = 0x12a,
    q8_runner_terminal_mismatch = 0x12b,
    q8_runner_recovery = 0x12c,
    q8_runner_profile = 0x12d,
    q8_runner_controlled_reject = 0x12e,
};

#if 0 // Isolated historical direct-Coprocessor harness; never production.
struct completion_snapshot {
    std::uint32_t legacy_producer_id = 0;
    std::uint32_t legacy_npu_required = 0;
    std::uint32_t legacy_opclass = 0;
    std::uint32_t error = 0;
    std::uint32_t error_code = 0;
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

    bool operator==(const completion_snapshot & other) const {
        return legacy_producer_id == other.legacy_producer_id &&
               legacy_npu_required == other.legacy_npu_required &&
               legacy_opclass == other.legacy_opclass &&
               error == other.error && error_code == other.error_code &&
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
               state_update_count == other.state_update_count;
    }
};

completion_snapshot capture_completion(const VTensorNpuCoprocessor & top) {
    completion_snapshot snapshot = {};
    snapshot.legacy_producer_id = top.completion_producer_id_o;
    snapshot.legacy_npu_required = top.completion_npu_required_o;
    snapshot.legacy_opclass = top.completion_opclass_o;
    snapshot.error = top.completion_error_o;
    snapshot.error_code = top.completion_error_code_o;
    snapshot.is_macro = top.completion_is_macro_o;
    snapshot.status = top.completion_macro_status_o;
    snapshot.error_class = top.completion_macro_error_class_o;
    snapshot.kernel_id = top.completion_macro_kernel_id_o;
    snapshot.command_flags = top.completion_macro_command_flags_o;
    snapshot.vector_flags = top.completion_macro_vector_flags_o;
    snapshot.context_id = top.completion_macro_context_id_o;
    snapshot.sequence_id = top.completion_macro_sequence_id_o;
    snapshot.producer_id = top.completion_macro_producer_id_o;
    snapshot.user_tag = top.completion_macro_user_tag_o;
    snapshot.covered_node_count =
        top.completion_macro_covered_node_count_o;
    snapshot.node_hash_lo = top.completion_macro_node_hash_lo_o;
    snapshot.node_hash_hi = top.completion_macro_node_hash_hi_o;
    snapshot.npu_cycles = top.completion_macro_npu_cycles_o;
    snapshot.gmem_read_bytes = top.completion_macro_gmem_read_bytes_o;
    snapshot.gmem_write_bytes = top.completion_macro_gmem_write_bytes_o;
    snapshot.q8_mac_count = top.completion_macro_q8_mac_count_o;
    snapshot.vector_element_count =
        top.completion_macro_vector_element_count_o;
    snapshot.state_update_count =
        top.completion_macro_state_update_count_o;
    return snapshot;
}

template <std::size_t N>
void store_le16(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint16_t value) {
    bytes[offset] = static_cast<std::uint8_t>(value);
    bytes[offset + 1] = static_cast<std::uint8_t>(value >> 8);
}

template <std::size_t N>
void store_le32(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint32_t value) {
    for (std::size_t index = 0; index < 4; ++index) {
        bytes[offset + index] = static_cast<std::uint8_t>(value >> (8 * index));
    }
}

template <std::size_t N>
void store_le64(
        std::array<std::uint8_t, N> & bytes,
        std::size_t offset,
        std::uint64_t value) {
    for (std::size_t index = 0; index < 8; ++index) {
        bytes[offset + index] = static_cast<std::uint8_t>(value >> (8 * index));
    }
}

template <std::size_t N>
std::uint16_t load_le16(
        const std::array<std::uint8_t, N> & bytes,
        std::size_t offset) {
    return static_cast<std::uint16_t>(bytes[offset]) |
           (static_cast<std::uint16_t>(bytes[offset + 1]) << 8);
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

using completion_record = std::array<std::uint8_t, 128>;

completion_record serialize_completion(const completion_snapshot & snapshot) {
    completion_record record = {};
    store_le32(record, 0x00, 0x514e5043U);
    store_le16(record, 0x04, 1);
    store_le16(record, 0x06, 0);
    store_le16(record, 0x08, 128);
    store_le16(record, 0x0a, 0);
    store_le32(record, 0x10, snapshot.error_class);
    store_le32(record, 0x14, snapshot.kernel_id);
    store_le32(record, 0x18, snapshot.command_flags);
    store_le32(record, 0x1c, snapshot.context_id);
    store_le64(record, 0x20, snapshot.sequence_id);
    store_le64(record, 0x28, snapshot.producer_id);
    store_le64(record, 0x30, snapshot.user_tag);
    store_le32(record, 0x38, snapshot.covered_node_count);
    store_le32(record, 0x3c, 0);
    store_le64(record, 0x40, snapshot.node_hash_lo);
    store_le64(record, 0x48, snapshot.node_hash_hi);
    store_le64(record, 0x50, snapshot.npu_cycles);
    store_le64(record, 0x58, snapshot.gmem_read_bytes);
    store_le64(record, 0x60, snapshot.gmem_write_bytes);
    store_le64(record, 0x68, snapshot.q8_mac_count);
    store_le64(record, 0x70, snapshot.vector_element_count);
    store_le64(record, 0x78, snapshot.state_update_count);
    // Status is the terminal publication field and is serialized last.
    store_le32(record, 0x0c, snapshot.status);
    return record;
}

bool framing_matches(
        const completion_record & record,
        const completion_snapshot & snapshot) {
    return load_le32(record, 0x00) == 0x514e5043U &&
           load_le16(record, 0x04) == 1 &&
           load_le16(record, 0x06) == 0 &&
           load_le16(record, 0x08) == 128 &&
           load_le16(record, 0x0a) == 0 &&
           load_le32(record, 0x0c) == snapshot.status &&
           load_le32(record, 0x10) == snapshot.error_class &&
           load_le32(record, 0x14) == snapshot.kernel_id &&
           load_le32(record, 0x18) == snapshot.command_flags &&
           load_le32(record, 0x1c) == snapshot.context_id &&
           load_le64(record, 0x20) == snapshot.sequence_id &&
           load_le64(record, 0x28) == snapshot.producer_id &&
           load_le64(record, 0x30) == snapshot.user_tag &&
           load_le32(record, 0x38) == snapshot.covered_node_count &&
           load_le32(record, 0x3c) == 0 &&
           load_le64(record, 0x40) == snapshot.node_hash_lo &&
           load_le64(record, 0x48) == snapshot.node_hash_hi &&
           load_le64(record, 0x50) == snapshot.npu_cycles &&
           load_le64(record, 0x58) == snapshot.gmem_read_bytes &&
           load_le64(record, 0x60) == snapshot.gmem_write_bytes &&
           load_le64(record, 0x68) == snapshot.q8_mac_count &&
           load_le64(record, 0x70) == snapshot.vector_element_count &&
           load_le64(record, 0x78) == snapshot.state_update_count;
}

bool identity_equal(const npu_macro_identity & lhs,
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

class q8_get_rows_harness {
public:
    q8_get_rows_harness(
            const npu_q8_get_rows_profile & profile,
            const npu_macro_identity & identity,
            const std::uint8_t * table_allocation,
            std::size_t table_allocation_bytes,
            const std::uint8_t * index_allocation,
            std::size_t index_allocation_bytes,
            std::uint8_t * dst_shadow,
            std::size_t dst_shadow_bytes,
            npu_verilator_q8_get_rows_result * result)
        : profile_(profile),
          identity_(identity),
          table_allocation_(table_allocation),
          table_allocation_bytes_(table_allocation_bytes),
          index_allocation_(index_allocation),
          index_allocation_bytes_(index_allocation_bytes),
          dst_shadow_(dst_shadow),
          dst_shadow_bytes_(dst_shadow_bytes),
          result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())),
          dst_window_(static_cast<std::size_t>(profile.dst_bytes), 0xa5),
          dst_write_seen_(static_cast<std::size_t>(profile.dst_bytes), 0) {
        inputs_valid_ =
            table_allocation_ != nullptr &&
            table_allocation_bytes_ == profile_.table_bytes &&
            index_allocation_ != nullptr &&
            index_allocation_bytes_ == profile_.index_bytes &&
            dst_shadow_ != nullptr &&
            dst_shadow_bytes_ == profile_.dst_bytes;
        drive_idle_inputs();
        top_->eval();
    }

    ~q8_get_rows_harness() {
        top_->final();
    }

    bool run() {
        result_->submitted_identity = identity_;
        result_->cycle_upper_bound = profile_.cycle_upper_bound;
        if (!inputs_valid_) {
            return fail(q8_runner_profile);
        }
        if (!reset() || !submit()) {
            return false;
        }
        while (!top_->completion_valid_o) {
            if (!tick()) {
                return false;
            }
        }
        if (response_.occupied) {
            return fail(q8_runner_response_protocol);
        }

        const completion_snapshot snapshot = capture_completion(*top_);
        result_->completion_emitted = true;
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
        if (!hold_and_check_completion(snapshot)) {
            return false;
        }
        result_->completion_identity_match = identity_matches(snapshot);
        if (!result_->completion_identity_match ||
            !identity_equal(result_->submitted_identity,
                            result_->returned_identity)) {
            return fail(q8_runner_completion_identity);
        }
        const completion_record record = serialize_completion(snapshot);
        result_->completion_framing_valid = framing_matches(record, snapshot);
        if (!result_->completion_framing_valid) {
            return fail(q8_runner_completion_framing);
        }
        snapshot_result(snapshot);
        if (!validate_terminal(snapshot)) {
            return fail(q8_runner_terminal_mismatch);
        }
        if (!consume_completion_and_recover(snapshot)) {
            return fail(q8_runner_recovery);
        }

        if (snapshot.error != 0) {
            result_->controlled_reject = true;
            result_->runner_error_code = q8_runner_controlled_reject;
            return false;
        }
        if (written_bytes_ != profile_.dst_bytes) {
            return fail(q8_runner_result_coverage);
        }
        for (std::uint8_t seen : dst_write_seen_) {
            if (seen != 1) {
                return fail(q8_runner_result_coverage);
            }
        }
        std::memcpy(dst_shadow_, dst_window_.data(), dst_window_.size());
        result_->result_bytes = dst_window_.size();
        result_->private_shadow_committed = true;
        result_->passed = true;
        result_->runner_error_code = q8_runner_ok;
        return true;
    }

private:
    struct response_slot {
        bool occupied = false;
        bool active = false;
        bool write = false;
        std::uint64_t address = 0;
        std::uint64_t data = 0;
        std::uint8_t wstrb = 0;
        std::uint64_t due_cycle = 0;
    };

    void drive_idle_inputs() {
        top_->clk = 0;
        top_->rst = 0;
        top_->cmd_valid_i = 0;
        top_->cmd_is_64_i = 0;
        top_->cmd_bits_i = 0;
        top_->cmd_rs_value_i = 0;
        top_->cmd_producer_id_i = 0;
        top_->cmd_npu_required_i = 0;
        top_->cmd_opclass_i = 0;
        drive_macro_idle();
        top_->completion_ready_i = 0;
        top_->desc_write_valid_i = 0;
        top_->desc_write_id_i = 0;
        top_->desc_write_word_i = 0;
        top_->desc_write_data_i = 0;
        top_->host_lmem_rd_valid_i = 0;
        top_->host_lmem_rd_addr_i = 0;
        top_->host_lmem_rd_bytes_i = 0;
        top_->host_lmem_wr_valid_i = 0;
        top_->host_lmem_wr_addr_i = 0;
        top_->host_lmem_wr_data_i = 0;
        top_->host_lmem_wr_strb_i = 0;
        top_->gmem_req_ready_i = 0;
        top_->gmem_rsp_valid_i = 0;
        top_->gmem_rsp_rdata_i = 0;
        top_->gmem_rsp_error_i = 0;
        top_->sync_tag_ack_i = 0;
        top_->error_clear_i = 0;
    }

    void drive_macro_idle() {
        top_->macro_cmd_valid_i = 0;
        top_->macro_abi_valid_i = 0;
        top_->macro_kernel_id_i = 0;
        top_->macro_command_flags_i = 0;
        top_->macro_context_id_i = 0;
        top_->macro_capability_epoch_i = 0;
        top_->macro_sequence_id_i = 0;
        top_->macro_producer_id_i = 0;
        top_->macro_user_tag_i = 0;
        top_->macro_node_count_i = 0;
        top_->macro_node_hash_lo_i = 0;
        top_->macro_node_hash_hi_i = 0;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 0;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = 0;
        top_->macro_src1_iova_i = 0;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = 0;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = 0;
        top_->macro_outer_count_i = 0;
        top_->macro_dtype_i = 0;
        top_->macro_src0_stride_i = 0;
        top_->macro_src1_stride_i = 0;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = 0;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = 0;
        top_->macro_src0_window_size_i = 0;
        top_->macro_src0_window_perm_i = 0;
        top_->macro_src1_window_base_i = 0;
        top_->macro_src1_window_size_i = 0;
        top_->macro_src1_window_perm_i = 0;
        top_->macro_dst_window_base_i = 0;
        top_->macro_dst_window_size_i = 0;
        top_->macro_dst_window_perm_i = 0;
        top_->macro_windows_generation_valid_i = 0;
    }

    void drive_submission() {
        top_->macro_cmd_valid_i = 1;
        top_->macro_abi_valid_i = 1;
        top_->macro_kernel_id_i = kKernelGetRowsQ8;
        top_->macro_command_flags_i = identity_.command_flags;
        top_->macro_context_id_i = identity_.context_id;
        top_->macro_capability_epoch_i = kCapabilityEpoch;
        top_->macro_sequence_id_i = identity_.sequence_id;
        top_->macro_producer_id_i = identity_.producer_id;
        top_->macro_user_tag_i = identity_.user_tag;
        top_->macro_node_count_i = 1;
        top_->macro_node_hash_lo_i = identity_.node_hash_lo;
        top_->macro_node_hash_hi_i = identity_.node_hash_hi;
        top_->macro_deadline_cycles_i = 0;
        top_->macro_vector_op_i = 0;
        top_->macro_vector_flags_i = 0;
        top_->macro_src0_iova_i = kTableIova;
        top_->macro_src1_iova_i = kIndexIova;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = kDstIova;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = profile_.embedding_dim;
        top_->macro_outer_count_i = profile_.gathered_rows;
        top_->macro_dtype_i = kDtypeF32;
        top_->macro_src0_stride_i = profile_.table_row_stride;
        top_->macro_src1_stride_i = profile_.index_stride;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = profile_.dst_row_stride;
        top_->macro_scalar0_i = profile_.vocabulary_rows;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = kTableWindowBase;
        top_->macro_src0_window_size_i = kTableWindowSize;
        top_->macro_src0_window_perm_i = 1;
        top_->macro_src1_window_base_i = kIndexWindowBase;
        top_->macro_src1_window_size_i = kIndexWindowSize;
        top_->macro_src1_window_perm_i = 1;
        top_->macro_dst_window_base_i = kDstWindowBase;
        top_->macro_dst_window_size_i = kDstWindowSize;
        top_->macro_dst_window_perm_i = 2;
        top_->macro_windows_generation_valid_i = 1;
    }

    void drive_memory_inputs() {
        top_->gmem_req_ready_i = 1;
        top_->gmem_rsp_valid_i = response_.active ? 1 : 0;
        top_->gmem_rsp_rdata_i = response_.active ? response_.data : 0;
        top_->gmem_rsp_error_i = 0;
    }

    bool tick() {
        if (clock_cycles_ >= profile_.cycle_upper_bound + 32) {
            return fail(q8_runner_timeout);
        }
        if (response_.occupied && !response_.active &&
            clock_cycles_ >= response_.due_cycle) {
            response_.active = true;
        }
        top_->clk = 0;
        drive_memory_inputs();
        top_->eval();
        const bool request_valid = top_->gmem_req_valid_o != 0;
        const bool request_ready = top_->gmem_req_ready_i != 0;
        const bool request_fire = request_valid && request_ready;
        const bool response_fire = response_.active &&
                                   top_->gmem_rsp_ready_o != 0;
        if (!check_unaccepted_request_hold(request_valid, request_ready)) {
            return false;
        }
        if (request_fire && response_.occupied) {
            return fail(q8_runner_request_protocol);
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
        top_->clk = 1;
        top_->eval();
        context_->timeInc(1);
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
        top_->clk = 0;
        top_->eval();
        context_->timeInc(1);
        ++clock_cycles_;
        return true;
    }

    bool check_unaccepted_request_hold(bool valid, bool ready) {
        if (valid && !ready) {
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
                return fail(q8_runner_request_protocol);
            }
        } else {
            unaccepted_request_held_ = false;
        }
        return true;
    }

    static bool beat_in_window(
            std::uint64_t address,
            std::uint64_t base,
            std::uint64_t size) {
        return size >= 8 && address >= base && address - base <= size - 8;
    }

    static bool byte_in_logical_allocation(
            std::uint64_t address,
            std::uint64_t logical_base,
            std::size_t allocation_bytes,
            std::size_t * offset) {
        if (address < logical_base ||
            address - logical_base >= allocation_bytes) {
            return false;
        }
        *offset = static_cast<std::size_t>(address - logical_base);
        return true;
    }

    std::uint64_t load_raw_beat(
            std::uint64_t address,
            std::uint64_t logical_base,
            const std::uint8_t * allocation,
            std::size_t allocation_bytes) const {
        std::uint64_t value = 0;
        for (std::size_t lane = 0; lane < 8; ++lane) {
            std::size_t offset = 0;
            if (byte_in_logical_allocation(
                    address + lane, logical_base,
                    allocation_bytes, &offset)) {
                value |= static_cast<std::uint64_t>(allocation[offset]) <<
                         (8 * lane);
            }
        }
        return value;
    }

    bool prepare_response(response_slot * request) {
        if (request == nullptr || (request->address & 7U) != 0) {
            return fail(q8_runner_request_protocol);
        }
        if (request->write) {
            if ((request->wstrb != 0x0f && request->wstrb != 0xf0) ||
                !beat_in_window(request->address,
                                kDstWindowBase, kDstWindowSize)) {
                return fail(q8_runner_memory_bounds);
            }
            return true;
        }
        if (request->wstrb != 0) {
            return fail(q8_runner_request_protocol);
        }
        if (beat_in_window(request->address,
                           kTableWindowBase, kTableWindowSize)) {
            request->data = load_raw_beat(
                request->address, kTableIova,
                table_allocation_, table_allocation_bytes_);
            return true;
        }
        if (beat_in_window(request->address,
                           kIndexWindowBase, kIndexWindowSize)) {
            request->data = load_raw_beat(
                request->address, kIndexIova,
                index_allocation_, index_allocation_bytes_);
            return true;
        }
        return fail(q8_runner_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        if (!beat_in_window(request.address,
                            kDstWindowBase, kDstWindowSize)) {
            return fail(q8_runner_memory_bounds);
        }
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) == 0) {
                continue;
            }
            const std::uint64_t physical = request.address + lane;
            if (physical < kDstIova || physical - kDstIova >= kDstBytes) {
                return fail(q8_runner_memory_bounds);
            }
            const std::size_t offset =
                static_cast<std::size_t>(physical - kDstIova);
            if (dst_write_seen_[offset] != 0) {
                return fail(q8_runner_result_coverage);
            }
            dst_write_seen_[offset] = 1;
            ++written_bytes_;
            dst_window_[offset] = static_cast<std::uint8_t>(
                request.data >> (8 * lane));
        }
        return true;
    }

    bool reset() {
        top_->rst = 1;
        for (unsigned index = 0; index < 4; ++index) {
            if (!tick()) {
                return false;
            }
        }
        top_->rst = 0;
        for (unsigned index = 0; index < 2; ++index) {
            if (!tick()) {
                return false;
            }
        }
        if (!top_->cmd_ready_o || !top_->macro_cmd_ready_o ||
            top_->busy_o || top_->error_o || top_->completion_valid_o ||
            top_->gmem_req_valid_o || top_->gmem_rsp_ready_o ||
            response_.occupied) {
            return fail(q8_runner_reset_interface);
        }
        return true;
    }

    bool submit() {
        command_count_before_ = top_->macro_command_count_o;
        f32_start_count_before_ = top_->macro_f32_start_count_o;
        completion_count_before_ = top_->macro_completion_count_o;
        required_issued_before_ = top_->npu_required_issued_o;
        required_completed_before_ = top_->npu_required_completed_o;
        drive_submission();
        top_->eval();
        if (!top_->macro_cmd_ready_o || top_->completion_valid_o ||
            top_->busy_o || top_->error_o) {
            return fail(q8_runner_command_interface);
        }
        if (!tick()) {
            return false;
        }
        drive_macro_idle();
        top_->eval();
        update_required_deltas();
        if (result_->required_issued_delta != 1 ||
            result_->required_completed_delta != 0) {
            return fail(q8_runner_completion_protocol);
        }
        return true;
    }

    bool hold_and_check_completion(const completion_snapshot & snapshot) {
        result_->completion_stable = true;
        top_->completion_ready_i = 0;
        const std::uint64_t expected_completed = snapshot.error ? 0 : 1;
        for (unsigned index = 0; index < kCompletionBackpressureCycles;
             ++index) {
            if (result_->completion_accepted ||
                result_->private_shadow_committed ||
                !top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(q8_runner_completion_protocol);
            }
            if (!tick()) {
                return false;
            }
            update_required_deltas();
            if (result_->required_issued_delta != 1 ||
                result_->required_completed_delta != expected_completed ||
                !top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(q8_runner_completion_protocol);
            }
        }
        return true;
    }

    bool identity_matches(const completion_snapshot & snapshot) const {
        return snapshot.is_macro == 1 &&
               snapshot.legacy_producer_id == 0 &&
               snapshot.legacy_npu_required ==
                   (identity_.command_flags & 1U) &&
               snapshot.legacy_opclass == 0 &&
               snapshot.kernel_id == kKernelGetRowsQ8 &&
               snapshot.command_flags == identity_.command_flags &&
               snapshot.vector_flags == 0 &&
               snapshot.context_id == identity_.context_id &&
               snapshot.sequence_id == identity_.sequence_id &&
               snapshot.producer_id == identity_.producer_id &&
               snapshot.user_tag == identity_.user_tag &&
               snapshot.covered_node_count == 1 &&
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
        result_->completion_status = snapshot.status;
        result_->completion_error_class = snapshot.error_class;
        result_->completion_error_code = snapshot.error_code;
        result_->rtl_cycles = snapshot.npu_cycles;
        result_->gmem_read_bytes = snapshot.gmem_read_bytes;
        result_->gmem_write_bytes = snapshot.gmem_write_bytes;
        result_->vector_elements = snapshot.vector_element_count;
        result_->q8_mac_count = snapshot.q8_mac_count;
        result_->f32_start_count =
            top_->macro_f32_start_count_o - f32_start_count_before_;
        result_->commands_accepted =
            top_->macro_command_count_o - command_count_before_;
        result_->commands_terminal_success =
            top_->macro_completion_count_o - completion_count_before_;
        result_->commands_terminal_failure = snapshot.error ? 1 : 0;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        update_required_deltas();
    }

    bool validate_terminal(const completion_snapshot & snapshot) const {
        if (snapshot.status != snapshot.error_code ||
            result_->commands_accepted != 1 ||
            result_->gmem_requests_accepted !=
                result_->gmem_responses_accepted ||
            result_->required_issued_delta != 1 ||
            result_->q8_mac_count != 0 ||
            result_->f32_start_count != 0 ||
            snapshot.state_update_count != 0 ||
            snapshot.npu_cycles == 0 ||
            snapshot.npu_cycles > profile_.cycle_upper_bound) {
            return false;
        }
        if (snapshot.error == 0) {
            return snapshot.status == 0 && snapshot.error_class == 0 &&
                   snapshot.gmem_read_bytes == profile_.expected_read_bytes &&
                   snapshot.gmem_write_bytes == profile_.expected_write_bytes &&
                   snapshot.vector_element_count == profile_.expected_elements &&
                   result_->commands_terminal_success == 1 &&
                   result_->commands_terminal_failure == 0 &&
                   result_->required_completed_delta == 1 &&
                   result_->gmem_requests_accepted ==
                       kExpectedReadRequests + kExpectedWriteRequests &&
                   written_bytes_ == profile_.dst_bytes;
        }
        return snapshot.status == kNpuErrMacroIova &&
               snapshot.error_class == kAbiErrorIova &&
               snapshot.gmem_read_bytes == kIndexWindowSize &&
               snapshot.gmem_write_bytes == 0 &&
               snapshot.vector_element_count == 0 &&
               result_->commands_terminal_success == 0 &&
               result_->commands_terminal_failure == 1 &&
               result_->required_completed_delta == 0 &&
               result_->gmem_requests_accepted == 2 &&
               written_bytes_ == 0;
    }

    bool consume_completion_and_recover(
            const completion_snapshot & snapshot) {
        if (!top_->completion_valid_o || result_->completion_accepted ||
            result_->private_shadow_committed ||
            !(capture_completion(*top_) == snapshot)) {
            return false;
        }
        top_->completion_ready_i = 1;
        top_->eval();
        if (!top_->completion_valid_o ||
            !(capture_completion(*top_) == snapshot)) {
            return false;
        }
        if (!tick()) {
            return false;
        }
        result_->completion_accepted = true;
        top_->completion_ready_i = 0;
        top_->eval();
        if (top_->completion_valid_o) {
            return false;
        }
        if (snapshot.error != 0) {
            if (!top_->error_o || top_->error_code_o == 0) {
                return false;
            }
            top_->error_clear_i = 1;
            if (!tick()) {
                return false;
            }
            top_->error_clear_i = 0;
            top_->eval();
        }
        update_required_deltas();
        const std::uint64_t expected_completed = snapshot.error ? 0 : 1;
        if (result_->required_issued_delta != 1 ||
            result_->required_completed_delta != expected_completed) {
            return false;
        }
        result_->recovery_clean =
            !top_->busy_o && !top_->error_o &&
            !top_->completion_valid_o && top_->cmd_ready_o &&
            top_->macro_cmd_ready_o && !top_->gmem_req_valid_o &&
            !top_->gmem_rsp_ready_o && !response_.occupied;
        return result_->recovery_clean;
    }

    bool fail(std::uint32_t error_code) {
        result_->passed = false;
        result_->runner_error_code = error_code;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        return false;
    }

    npu_q8_get_rows_profile profile_;
    npu_macro_identity identity_;
    const std::uint8_t * table_allocation_;
    std::size_t table_allocation_bytes_;
    const std::uint8_t * index_allocation_;
    std::size_t index_allocation_bytes_;
    std::uint8_t * dst_shadow_;
    std::size_t dst_shadow_bytes_;
    npu_verilator_q8_get_rows_result * result_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> top_;
    std::vector<std::uint8_t> dst_window_;
    std::vector<std::uint8_t> dst_write_seen_;
    response_slot response_ = {};
    bool inputs_valid_ = false;
    bool unaccepted_request_held_ = false;
    std::uint32_t held_request_write_ = 0;
    std::uint64_t held_request_address_ = 0;
    std::uint64_t held_request_data_ = 0;
    std::uint32_t held_request_wstrb_ = 0;
    std::uint64_t written_bytes_ = 0;
    std::uint64_t clock_cycles_ = 0;
    std::uint64_t gmem_requests_accepted_ = 0;
    std::uint64_t gmem_responses_accepted_ = 0;
    std::uint64_t command_count_before_ = 0;
    std::uint64_t f32_start_count_before_ = 0;
    std::uint64_t completion_count_before_ = 0;
    std::uint64_t required_issued_before_ = 0;
    std::uint64_t required_completed_before_ = 0;
};
#endif

void copy_system_result(
        const npu_verilator_exact_result & source,
        npu_verilator_q8_get_rows_result * destination) {
    destination->passed = source.passed;
    destination->controlled_reject = source.controlled_reject;
    destination->private_shadow_committed =
        source.private_shadow_committed;
    destination->completion_identity_match =
        source.completion_identity_match;
    destination->completion_framing_valid =
        source.completion_framing_valid;
    destination->completion_stable = source.completion_stable;
    destination->recovery_clean = source.recovery_clean;
    destination->completion_emitted = source.completion_emitted;
    destination->completion_accepted = source.completion_accepted;
    destination->completion_status = source.completion_status;
    destination->completion_error_class = source.completion_error_class;
    destination->completion_error_code = source.completion_error_code;
    destination->rtl_cycles = source.rtl_cycles;
    destination->cycle_upper_bound = source.cycle_upper_bound;
    destination->gmem_read_bytes = source.gmem_read_bytes;
    destination->gmem_write_bytes = source.gmem_write_bytes;
    destination->vector_elements = source.vector_elements;
    destination->q8_mac_count = source.q8_mac_count;
    destination->f32_start_count = source.f32_start_count;
    destination->commands_accepted = source.commands_accepted;
    destination->commands_terminal_success =
        source.commands_terminal_success;
    destination->commands_terminal_failure =
        source.commands_terminal_failure;
    destination->gmem_requests_accepted =
        source.gmem_requests_accepted;
    destination->gmem_responses_accepted =
        source.gmem_responses_accepted;
    destination->first_request_hold_cycles =
        source.first_request_hold_cycles;
    destination->result_bytes = source.result_bytes;
    destination->required_issued_delta = source.required_issued_delta;
    destination->required_completed_delta =
        source.required_completed_delta;
    destination->system_transport = source.system_transport;
    destination->cpu_memory_separate = source.cpu_memory_separate;
    destination->cpu_terminal_identity_match =
        source.cpu_terminal_identity_match;
    destination->system_cycles = source.system_cycles;
    destination->public_commands_accepted =
        source.public_commands_accepted;
    destination->public_completions = source.public_completions;
    destination->public_errors = source.public_errors;
    destination->cpu_config_commands_accepted =
        source.cpu_config_commands_accepted;
    destination->cpu_tensor_commands_accepted =
        source.cpu_tensor_commands_accepted;
    destination->cpu_terminals_accepted =
        source.cpu_terminals_accepted;
    destination->cpu_config_commits = source.cpu_config_commits;
    destination->cpu_launch_commits = source.cpu_launch_commits;
    destination->cpu_launch_instruction = source.cpu_launch_instruction;
    destination->cpu_launch_pid = source.cpu_launch_pid;
    destination->q8_portal = source.q8_portal;
    destination->submitted_identity = source.submitted_identity;
    destination->returned_identity = source.returned_identity;
}

} // namespace

bool npu_q8_get_rows_profile_v1(npu_q8_get_rows_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    *profile = {
        0,
        kEmbeddingDim,
        kGatheredRows,
        kVocabularyRows,
        kTableRowStride,
        kIndexStride,
        kDstRowStride,
        kTableBytes,
        kIndexBytes,
        kDstBytes,
        kExpectedReadBytes,
        kExpectedWriteBytes,
        kExpectedElements,
        kCycleUpperBound,
    };
    return true;
}

bool npu_verilator_execute_q8_get_rows(
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * table_allocation,
        std::size_t table_allocation_bytes,
        const std::uint8_t * index_allocation,
        std::size_t index_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_q8_get_rows_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    npu_q8_get_rows_profile profile = {};
    if (!npu_q8_get_rows_profile_v1(&profile) ||
        canonical_identity == nullptr) {
        result->runner_error_code = q8_runner_profile;
        return false;
    }
    const bool digest_is_nonzero =
        canonical_identity->sequence_id != 0 ||
        canonical_identity->producer_id != 0 ||
        canonical_identity->node_hash_lo != 0 ||
        canonical_identity->node_hash_hi != 0;
    if (canonical_identity->profile_id != 0 ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        !digest_is_nonzero) {
        result->runner_error_code = q8_runner_profile;
        return false;
    }
    if (table_allocation == nullptr ||
        table_allocation_bytes != profile.table_bytes ||
        index_allocation == nullptr ||
        index_allocation_bytes != profile.index_bytes ||
        dst_shadow == nullptr || dst_shadow_bytes != profile.dst_bytes) {
        result->runner_error_code = q8_runner_profile;
        return false;
    }

    try {
        std::vector<std::uint8_t> private_dst(
            static_cast<std::size_t>(profile.dst_bytes), 0xa5U);
        std::vector<std::uint8_t> expected_write(
            static_cast<std::size_t>(profile.dst_bytes), 1U);
        npu_system_transaction transaction = {};
        transaction.manifest_profile_id = profile.profile_id;
        transaction.identity = *canonical_identity;
        transaction.command = {
            1U, 1U, kKernelGetRowsQ8, 0U, 0U,
            canonical_identity->command_flags,
            canonical_identity->context_id, kCapabilityEpoch, 1U,
            canonical_identity->sequence_id,
            canonical_identity->producer_id,
            canonical_identity->user_tag,
            canonical_identity->node_hash_lo,
            canonical_identity->node_hash_hi,
            0U, kTableIova, kIndexIova, 0U, kDstIova, 0U,
            profile.embedding_dim, profile.gathered_rows, kDtypeF32,
            profile.table_row_stride, profile.index_stride, 0U,
            profile.dst_row_stride, profile.vocabulary_rows, 0U,
            0U, 0U,
            kTableWindowBase, kTableWindowSize, 1U,
            kIndexWindowBase, kIndexWindowSize, 1U,
            kDstWindowBase, kDstWindowSize, 2U, false,
        };
        transaction.sources[0] = {
            kTableIova, table_allocation, nullptr,
            table_allocation_bytes,
            kTableWindowBase, kTableWindowSize, true, false,
        };
        transaction.sources[1] = {
            kIndexIova, index_allocation, nullptr,
            index_allocation_bytes,
            kIndexWindowBase, kIndexWindowSize, true, false,
        };
        transaction.destination = {
            kDstIova, nullptr, private_dst.data(), private_dst.size(),
            kDstWindowBase, kDstWindowSize, false, true,
        };
        transaction.expected_write_mask = expected_write.data();
        transaction.expected_write_mask_bytes = expected_write.size();
        transaction.expected_read_bytes = profile.expected_read_bytes;
        transaction.expected_write_bytes = profile.expected_write_bytes;
        transaction.expected_vector_elements = profile.expected_elements;
        transaction.expected_read_requests = kExpectedReadRequests;
        transaction.expected_write_requests = kExpectedWriteRequests;
        transaction.expected_required_issued = 1U;
        transaction.expected_required_completed = 1U;
        transaction.expected_public_completions = 1U;
        transaction.expected_macro_completions = 1U;
        transaction.cycle_upper_bound = profile.cycle_upper_bound;
        transaction.require_f32_halfbeat_wstrb = true;
        transaction.validate_source_read_requests = true;
        transaction.expected_source_read_requests = {160U, 2U};
        transaction.controlled_reject = {
            true,
            kIndexWindowSize, 0U, 0U, 0U, 0U,
            2U, 0U, 0U,
            1U, 0U, 0U, 1U, 0U,
            kNpuErrMacroIova, kAbiErrorIova, kNpuErrMacroIova,
        };
        transaction.controlled_reject.validate_source_read_requests = true;
        transaction.controlled_reject.expected_source_read_requests = {
            0U, 2U,
        };

        npu_verilator_exact_result system_result = {};
        const bool executed = npu_verilator_execute_system_transaction(
            &transaction, &system_result);
        copy_system_result(system_result, result);
        if (!executed) {
            result->passed = false;
            result->runner_error_code = q8_runner_terminal_mismatch;
            return false;
        }
        if (system_result.controlled_reject) {
            result->passed = false;
            result->private_shadow_committed = false;
            result->result_bytes = 0;
            result->runner_error_code = q8_runner_controlled_reject;
            return false;
        }
        std::memcpy(dst_shadow, private_dst.data(), private_dst.size());
        result->private_shadow_committed = true;
        result->result_bytes = private_dst.size();
        result->runner_error_code = q8_runner_ok;
        return true;
    } catch (...) {
        result->passed = false;
        result->runner_error_code = q8_runner_allocation;
        return false;
    }
}
