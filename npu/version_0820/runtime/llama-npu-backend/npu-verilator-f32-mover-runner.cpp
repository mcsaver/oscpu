#include "npu-verilator-runner.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

namespace {

constexpr std::uint32_t kKernelGetRowsF32 = 0x514e0003U;
constexpr std::uint32_t kKernelRepeatF32 = 0x514e0004U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kCapabilityEpoch = 1U;
constexpr std::uint32_t kDtypeF32 = 1U;
constexpr std::uint64_t kSrcIova = 0x0000000810000004ULL;
constexpr std::uint64_t kIndexIova = 0x0000000920000004ULL;
constexpr std::uint64_t kDstIova = 0x0000000a30000004ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;
constexpr std::uint64_t kMinimumCycleUpperBound = 10000000ULL;
constexpr std::uint64_t kMaximumCycleUpperBound = 1000000000ULL;

enum mover_runner_error : std::uint32_t {
    mover_runner_ok = 0,
    mover_runner_allocation = 0x180,
    mover_runner_timeout = 0x181,
    mover_runner_reset_interface = 0x182,
    mover_runner_command_interface = 0x183,
    mover_runner_request_protocol = 0x184,
    mover_runner_response_protocol = 0x185,
    mover_runner_completion_protocol = 0x186,
    mover_runner_completion_identity = 0x187,
    mover_runner_completion_framing = 0x188,
    mover_runner_memory_bounds = 0x189,
    mover_runner_result_coverage = 0x18a,
    mover_runner_terminal_mismatch = 0x18b,
    mover_runner_recovery = 0x18c,
    mover_runner_profile = 0x18d,
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

bool semantic_span(
        std::uint64_t count,
        std::uint64_t stride,
        std::uint64_t row_bytes,
        std::uint64_t * result) {
    if (count == 0 || result == nullptr) {
        return false;
    }
    std::uint64_t prefix = 0;
    return checked_mul(count - 1, stride, &prefix) &&
           checked_add(prefix, row_bytes, result);
}

bool aligned_window(
        std::uint64_t logical_base,
        std::uint64_t logical_bytes,
        std::uint64_t * window_base,
        std::uint64_t * window_bytes) {
    if (window_base == nullptr || window_bytes == nullptr) {
        return false;
    }
    *window_base = logical_base & ~std::uint64_t{7};
    if (logical_bytes == 0) {
        *window_bytes = 0;
        return true;
    }
    std::uint64_t logical_end = 0;
    std::uint64_t rounded_end = 0;
    if (!checked_add(logical_base, logical_bytes, &logical_end) ||
        !checked_add(logical_end, 7, &rounded_end)) {
        return false;
    }
    rounded_end &= ~std::uint64_t{7};
    if (rounded_end <= *window_base) {
        return false;
    }
    *window_bytes = rounded_end - *window_base;
    return (*window_bytes & 7U) == 0;
}

bool finalize_profile(npu_f32_mover_profile * profile) {
    if (profile == nullptr || profile->profile_id >= 6 ||
        profile->element_count < 1 || profile->element_count > 262144) {
        return false;
    }
    std::uint64_t row_bytes = 0;
    if (!checked_mul(profile->element_count, 4, &row_bytes) ||
        profile->src_row_stride < row_bytes ||
        profile->dst_row_stride < row_bytes ||
        (profile->src_row_stride & 3U) != 0 ||
        (profile->index_stride & 3U) != 0 ||
        (profile->dst_row_stride & 3U) != 0 ||
        (profile->dst_outer_stride & 3U) != 0) {
        return false;
    }

    std::uint64_t expected_src_bytes = 0;
    std::uint64_t expected_index_bytes = 0;
    std::uint64_t expected_dst_bytes = 0;
    std::uint64_t source_words = 0;
    std::uint64_t total_elements = 0;
    std::uint64_t read_requests = 0;
    if (profile->owner == npu_f32_mover_owner::get_rows) {
        if (profile->index_count > 16 || profile->outer_count != 0 ||
            profile->repeat_count != 0 || profile->dst_outer_stride != 0 ||
            profile->index_stride < 4 ||
            (profile->index_count != 0 && profile->source_row_count < 1) ||
            !semantic_span(1, profile->src_row_stride, row_bytes,
                           &expected_src_bytes)) {
            return false;
        }
        if (profile->index_count == 0) {
            expected_index_bytes = 0;
            expected_dst_bytes = 0;
            source_words = 0;
            total_elements = 0;
            read_requests = 0;
        } else {
            if (!semantic_span(
                    profile->source_row_count, profile->src_row_stride,
                    row_bytes, &expected_src_bytes) ||
                !semantic_span(
                    profile->index_count, profile->index_stride, 4,
                    &expected_index_bytes) ||
                !semantic_span(
                    profile->index_count, profile->dst_row_stride, row_bytes,
                    &expected_dst_bytes) ||
                !checked_mul(profile->element_count, profile->index_count,
                             &source_words) ||
                !checked_add(source_words, profile->index_count,
                             &read_requests)) {
                return false;
            }
            total_elements = source_words;
        }
    } else if (profile->owner == npu_f32_mover_owner::repeat) {
        if (profile->source_row_count != 0 || profile->index_count != 0 ||
            profile->outer_count < 1 || profile->outer_count > 16 ||
            profile->repeat_count < 1 || profile->repeat_count > 128 ||
            profile->index_stride != 0) {
            return false;
        }
        std::uint64_t repeat_plane = 0;
        std::uint64_t repeat_prefix = 0;
        if (!checked_mul(
                profile->repeat_count - 1, profile->dst_row_stride,
                &repeat_prefix) ||
            !checked_add(repeat_prefix, row_bytes, &repeat_plane) ||
            profile->dst_outer_stride < repeat_plane ||
            !semantic_span(
                profile->outer_count, profile->src_row_stride, row_bytes,
                &expected_src_bytes) ||
            !semantic_span(
                profile->outer_count, profile->dst_outer_stride, repeat_plane,
                &expected_dst_bytes) ||
            !checked_mul(profile->element_count, profile->outer_count,
                         &source_words) ||
            !checked_mul(source_words, profile->repeat_count,
                         &total_elements)) {
            return false;
        }
        expected_index_bytes = 0;
        read_requests = source_words;
    } else {
        return false;
    }
    std::uint64_t expected_read_bytes = 0;
    std::uint64_t expected_write_bytes = 0;
    if (!checked_mul(read_requests, 4, &expected_read_bytes) ||
        !checked_mul(total_elements, 4, &expected_write_bytes) ||
        profile->src_bytes != expected_src_bytes ||
        profile->index_bytes != expected_index_bytes ||
        profile->dst_bytes != expected_dst_bytes) {
        return false;
    }

    std::uint64_t request_count = 0;
    std::uint64_t scaled = 0;
    std::uint64_t bound = 0;
    if (!checked_add(read_requests, total_elements, &request_count) ||
        !checked_mul(request_count, 16, &scaled) ||
        !checked_add(1000000, scaled, &bound)) {
        bound = kMaximumCycleUpperBound;
    }
    if (bound < kMinimumCycleUpperBound) {
        bound = kMinimumCycleUpperBound;
    }
    if (bound > kMaximumCycleUpperBound) {
        bound = kMaximumCycleUpperBound;
    }
    profile->expected_read_bytes = expected_read_bytes;
    profile->expected_write_bytes = expected_write_bytes;
    profile->expected_elements = total_elements;
    profile->expected_read_requests = read_requests;
    profile->expected_write_requests = total_elements;
    profile->cycle_upper_bound = bound;
    return true;
}

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
               error_class == other.error_class && kernel_id == other.kernel_id &&
               command_flags == other.command_flags &&
               vector_flags == other.vector_flags && context_id == other.context_id &&
               sequence_id == other.sequence_id && producer_id == other.producer_id &&
               user_tag == other.user_tag &&
               covered_node_count == other.covered_node_count &&
               node_hash_lo == other.node_hash_lo && node_hash_hi == other.node_hash_hi &&
               npu_cycles == other.npu_cycles &&
               gmem_read_bytes == other.gmem_read_bytes &&
               gmem_write_bytes == other.gmem_write_bytes &&
               q8_mac_count == other.q8_mac_count &&
               vector_element_count == other.vector_element_count &&
               state_update_count == other.state_update_count;
    }
};

completion_snapshot capture_completion(const VTensorNpuCoprocessor & top) {
    return {
        top.completion_producer_id_o,
        top.completion_npu_required_o,
        top.completion_opclass_o,
        top.completion_error_o,
        top.completion_error_code_o,
        top.completion_is_macro_o,
        top.completion_macro_status_o,
        top.completion_macro_error_class_o,
        top.completion_macro_kernel_id_o,
        top.completion_macro_command_flags_o,
        top.completion_macro_vector_flags_o,
        top.completion_macro_context_id_o,
        top.completion_macro_sequence_id_o,
        top.completion_macro_producer_id_o,
        top.completion_macro_user_tag_o,
        top.completion_macro_covered_node_count_o,
        top.completion_macro_node_hash_lo_o,
        top.completion_macro_node_hash_hi_o,
        top.completion_macro_npu_cycles_o,
        top.completion_macro_gmem_read_bytes_o,
        top.completion_macro_gmem_write_bytes_o,
        top.completion_macro_q8_mac_count_o,
        top.completion_macro_vector_element_count_o,
        top.completion_macro_state_update_count_o,
    };
}

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
           record[0x04] == 1 && record[0x05] == 0 &&
           record[0x06] == 0 && record[0x07] == 0 &&
           record[0x08] == 128 && record[0x09] == 0 &&
           record[0x0a] == 0 && record[0x0b] == 0 &&
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

class f32_mover_harness {
public:
    f32_mover_harness(
            const npu_f32_mover_profile & profile,
            const npu_macro_identity & identity,
            const std::uint8_t * src_allocation,
            std::size_t src_allocation_bytes,
            const std::uint8_t * index_allocation,
            std::size_t index_allocation_bytes,
            std::uint8_t * dst_shadow,
            std::size_t dst_shadow_bytes,
            npu_verilator_f32_mover_result * result)
        : profile_(profile),
          identity_(identity),
          src_allocation_(src_allocation),
          src_allocation_bytes_(src_allocation_bytes),
          index_allocation_(index_allocation),
          index_allocation_bytes_(index_allocation_bytes),
          dst_shadow_(dst_shadow),
          dst_shadow_bytes_(dst_shadow_bytes),
          result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())),
          dst_window_(static_cast<std::size_t>(profile.dst_bytes), 0xa5),
          dst_write_seen_(static_cast<std::size_t>(profile.dst_bytes), 0) {
        const bool empty_get = is_empty_get();
        inputs_valid_ =
            aligned_window(kSrcIova, empty_get ? 0 : profile_.src_bytes,
                           &src_window_base_, &src_window_bytes_) &&
            aligned_window(kIndexIova, empty_get ? 0 : profile_.index_bytes,
                           &index_window_base_, &index_window_bytes_) &&
            aligned_window(kDstIova, profile_.dst_bytes,
                           &dst_window_base_, &dst_window_bytes_);
        if (empty_get) {
            inputs_valid_ &= src_allocation_ == nullptr &&
                             src_allocation_bytes_ == 0 &&
                             index_allocation_ == nullptr &&
                             index_allocation_bytes_ == 0 &&
                             dst_shadow_ == nullptr && dst_shadow_bytes_ == 0;
        } else {
            inputs_valid_ &= src_allocation_ != nullptr &&
                             src_allocation_bytes_ == profile_.src_bytes &&
                             dst_shadow_ != nullptr &&
                             dst_shadow_bytes_ == profile_.dst_bytes;
            if (profile_.owner == npu_f32_mover_owner::get_rows) {
                inputs_valid_ &= index_allocation_ != nullptr &&
                                 index_allocation_bytes_ == profile_.index_bytes;
            } else {
                inputs_valid_ &= index_allocation_ == nullptr &&
                                 index_allocation_bytes_ == 0;
            }
        }
        drive_idle_inputs();
        top_->eval();
    }

    ~f32_mover_harness() {
        top_->final();
    }

    bool run() {
        result_->submitted_identity = identity_;
        result_->cycle_upper_bound = profile_.cycle_upper_bound;
        if (!inputs_valid_) {
            return fail(mover_runner_profile);
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
            return fail(mover_runner_response_protocol);
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
            return fail(mover_runner_completion_identity);
        }
        result_->completion_framing_valid = completion_frame_valid(snapshot);
        if (!result_->completion_framing_valid) {
            return fail(mover_runner_completion_framing);
        }
        snapshot_result(snapshot);
        if (!validate_terminal(snapshot)) {
            return fail(mover_runner_terminal_mismatch);
        }
        if (!consume_completion_and_recover(snapshot)) {
            return fail(mover_runner_recovery);
        }
        if (written_bytes_ != profile_.dst_bytes) {
            return fail(mover_runner_result_coverage);
        }
        for (std::uint8_t seen : dst_write_seen_) {
            if (seen != 1) {
                return fail(mover_runner_result_coverage);
            }
        }
        if (!dst_window_.empty()) {
            std::memcpy(dst_shadow_, dst_window_.data(), dst_window_.size());
        }
        result_->result_bytes = dst_window_.size();
        result_->private_shadow_committed = true;
        result_->passed = true;
        result_->runner_error_code = mover_runner_ok;
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

    bool is_empty_get() const {
        return profile_.owner == npu_f32_mover_owner::get_rows &&
               profile_.index_count == 0;
    }

    std::uint32_t kernel_id() const {
        return profile_.owner == npu_f32_mover_owner::get_rows ?
            kKernelGetRowsF32 : kKernelRepeatF32;
    }

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
        const bool empty_get = is_empty_get();
        top_->macro_cmd_valid_i = 1;
        top_->macro_abi_valid_i = 1;
        top_->macro_kernel_id_i = kernel_id();
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
        top_->macro_src0_iova_i = kSrcIova;
        top_->macro_src1_iova_i =
            profile_.owner == npu_f32_mover_owner::get_rows ? kIndexIova : 0;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = kDstIova;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = profile_.element_count;
        top_->macro_outer_count_i =
            profile_.owner == npu_f32_mover_owner::get_rows ?
                profile_.index_count : profile_.outer_count;
        top_->macro_dtype_i = kDtypeF32;
        top_->macro_src0_stride_i = profile_.src_row_stride;
        top_->macro_src1_stride_i = profile_.index_stride;
        top_->macro_src2_stride_i = profile_.dst_outer_stride;
        top_->macro_dst_stride_i = profile_.dst_row_stride;
        top_->macro_scalar0_i =
            profile_.owner == npu_f32_mover_owner::get_rows ?
                profile_.source_row_count : profile_.repeat_count;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = src_window_base_;
        top_->macro_src0_window_size_i = empty_get ? 0 : src_window_bytes_;
        top_->macro_src0_window_perm_i = 1;
        top_->macro_src1_window_base_i =
            profile_.owner == npu_f32_mover_owner::get_rows ?
                index_window_base_ : 0;
        top_->macro_src1_window_size_i = empty_get ? 0 : index_window_bytes_;
        top_->macro_src1_window_perm_i = 1;
        top_->macro_dst_window_base_i = dst_window_base_;
        top_->macro_dst_window_size_i = dst_window_bytes_;
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
            return fail(mover_runner_timeout);
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
        const bool response_fire =
            response_.active && top_->gmem_rsp_ready_o != 0;
        if (!check_unaccepted_request_hold(request_valid, request_ready)) {
            return false;
        }
        if (request_fire && response_.occupied) {
            return fail(mover_runner_request_protocol);
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
                return fail(mover_runner_request_protocol);
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

    static std::uint64_t load_raw_beat(
            std::uint64_t address,
            std::uint64_t logical_base,
            const std::uint8_t * allocation,
            std::size_t allocation_bytes) {
        std::uint64_t value = 0;
        for (std::size_t lane = 0; lane < 8; ++lane) {
            const std::uint64_t physical = address + lane;
            if (physical >= logical_base &&
                physical - logical_base < allocation_bytes) {
                value |= static_cast<std::uint64_t>(
                             allocation[static_cast<std::size_t>(
                                 physical - logical_base)]) <<
                         (8 * lane);
            }
        }
        return value;
    }

    bool prepare_response(response_slot * request) {
        if (request == nullptr || (request->address & 7U) != 0) {
            return fail(mover_runner_request_protocol);
        }
        if (request->write) {
            if ((request->wstrb != 0x0f && request->wstrb != 0xf0) ||
                !beat_in_window(
                    request->address, dst_window_base_, dst_window_bytes_)) {
                return fail(mover_runner_memory_bounds);
            }
            ++write_requests_;
            return true;
        }
        if (request->wstrb != 0 || top_->gmem_req_wdata_o != 0) {
            return fail(mover_runner_request_protocol);
        }
        if (beat_in_window(request->address, src_window_base_, src_window_bytes_)) {
            request->data = load_raw_beat(
                request->address, kSrcIova,
                src_allocation_, src_allocation_bytes_);
            ++src_read_requests_;
            return true;
        }
        if (profile_.owner == npu_f32_mover_owner::get_rows &&
            beat_in_window(
                request->address, index_window_base_, index_window_bytes_)) {
            request->data = load_raw_beat(
                request->address, kIndexIova,
                index_allocation_, index_allocation_bytes_);
            ++index_read_requests_;
            return true;
        }
        return fail(mover_runner_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        std::size_t strobed = 0;
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) == 0) {
                continue;
            }
            ++strobed;
            const std::uint64_t physical = request.address + lane;
            if (physical < kDstIova ||
                physical - kDstIova >= profile_.dst_bytes) {
                return fail(mover_runner_memory_bounds);
            }
            const std::size_t offset = static_cast<std::size_t>(
                physical - kDstIova);
            if (dst_write_seen_[offset] != 0) {
                return fail(mover_runner_result_coverage);
            }
            dst_write_seen_[offset] = 1;
            dst_window_[offset] = static_cast<std::uint8_t>(
                request.data >> (8 * lane));
            ++written_bytes_;
        }
        return strobed == 4 || fail(mover_runner_result_coverage);
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
            return fail(mover_runner_reset_interface);
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
            top_->busy_o || top_->error_o || !tick()) {
            return fail(mover_runner_command_interface);
        }
        drive_macro_idle();
        top_->eval();
        update_required_deltas();
        if (result_->required_issued_delta != 1 ||
            result_->required_completed_delta != 0) {
            return fail(mover_runner_completion_protocol);
        }
        return true;
    }

    bool hold_and_check_completion(const completion_snapshot & snapshot) {
        result_->completion_stable = true;
        top_->completion_ready_i = 0;
        for (unsigned index = 0; index < kCompletionBackpressureCycles; ++index) {
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot) || !tick()) {
                result_->completion_stable = false;
                return fail(mover_runner_completion_protocol);
            }
            update_required_deltas();
            if (result_->required_issued_delta != 1 ||
                result_->required_completed_delta != 1 ||
                !top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(mover_runner_completion_protocol);
            }
        }
        return true;
    }

    bool identity_matches(const completion_snapshot & snapshot) const {
        return snapshot.is_macro == 1 && snapshot.legacy_producer_id == 0 &&
               snapshot.legacy_npu_required == (identity_.command_flags & 1U) &&
               snapshot.legacy_opclass == 0 && snapshot.kernel_id == kernel_id() &&
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
        const std::uint64_t expected_requests =
            profile_.expected_read_requests + profile_.expected_write_requests;
        const std::uint64_t expected_source_reads =
            profile_.owner == npu_f32_mover_owner::get_rows ?
                profile_.expected_elements :
                profile_.expected_read_requests;
        const std::uint64_t expected_index_reads =
            profile_.owner == npu_f32_mover_owner::get_rows ?
                profile_.index_count : 0;
        return snapshot.error == 0 && snapshot.status == 0 &&
               snapshot.error_code == 0 && snapshot.error_class == 0 &&
               result_->commands_accepted == 1 &&
               result_->commands_terminal_success == 1 &&
               result_->commands_terminal_failure == 0 &&
               result_->required_issued_delta == 1 &&
               result_->required_completed_delta == 1 &&
               result_->gmem_requests_accepted == expected_requests &&
               result_->gmem_requests_accepted == result_->gmem_responses_accepted &&
               src_read_requests_ == expected_source_reads &&
               index_read_requests_ == expected_index_reads &&
               write_requests_ == profile_.expected_write_requests &&
               snapshot.gmem_read_bytes == profile_.expected_read_bytes &&
               snapshot.gmem_write_bytes == profile_.expected_write_bytes &&
               snapshot.q8_mac_count == 0 &&
               snapshot.vector_element_count == profile_.expected_elements &&
               snapshot.state_update_count == 0 && result_->f32_start_count == 0 &&
               snapshot.npu_cycles > 0 &&
               snapshot.npu_cycles <= profile_.cycle_upper_bound &&
               written_bytes_ == profile_.dst_bytes;
    }

    bool consume_completion_and_recover(const completion_snapshot & snapshot) {
        if (!top_->completion_valid_o || !(capture_completion(*top_) == snapshot)) {
            return false;
        }
        top_->completion_ready_i = 1;
        top_->eval();
        if (!top_->completion_valid_o || !(capture_completion(*top_) == snapshot) ||
            !tick()) {
            return false;
        }
        result_->completion_accepted = true;
        top_->completion_ready_i = 0;
        top_->eval();
        update_required_deltas();
        result_->recovery_clean =
            !top_->busy_o && !top_->error_o && !top_->completion_valid_o &&
            top_->cmd_ready_o && top_->macro_cmd_ready_o &&
            !top_->gmem_req_valid_o && !top_->gmem_rsp_ready_o &&
            !response_.occupied && result_->required_issued_delta == 1 &&
            result_->required_completed_delta == 1;
        return result_->recovery_clean;
    }

    bool fail(std::uint32_t error_code) {
        // Preserve an already-emitted terminal failure as audit evidence even
        // when the positive-only success validator rejects it.  This never
        // converts a failure into success or publishes destination bytes; it
        // only prevents the fail-closed path from erasing the Coprocessor's
        // accepted-command, raw-traffic, identity, and terminal-error ledger.
        if (top_ != nullptr && top_->completion_valid_o) {
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
            result_->completion_identity_match = identity_matches(snapshot) &&
                identity_equal(result_->submitted_identity,
                               result_->returned_identity);
            result_->completion_framing_valid =
                completion_frame_valid(snapshot);
            snapshot_result(snapshot);
            result_->controlled_reject = snapshot.error != 0;
        }
        result_->passed = false;
        result_->runner_error_code = error_code;
        result_->gmem_requests_accepted = gmem_requests_accepted_;
        result_->gmem_responses_accepted = gmem_responses_accepted_;
        return false;
    }

    npu_f32_mover_profile profile_;
    npu_macro_identity identity_;
    const std::uint8_t * src_allocation_;
    std::size_t src_allocation_bytes_;
    const std::uint8_t * index_allocation_;
    std::size_t index_allocation_bytes_;
    std::uint8_t * dst_shadow_;
    std::size_t dst_shadow_bytes_;
    npu_verilator_f32_mover_result * result_;
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
    std::uint64_t src_window_base_ = 0;
    std::uint64_t src_window_bytes_ = 0;
    std::uint64_t index_window_base_ = 0;
    std::uint64_t index_window_bytes_ = 0;
    std::uint64_t dst_window_base_ = 0;
    std::uint64_t dst_window_bytes_ = 0;
    std::uint64_t written_bytes_ = 0;
    std::uint64_t src_read_requests_ = 0;
    std::uint64_t index_read_requests_ = 0;
    std::uint64_t write_requests_ = 0;
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
        npu_verilator_f32_mover_result * destination) {
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
    destination->f32_alu_portal = source.f32_alu_portal;
    destination->f32_mover_portal = source.f32_mover_portal;
    destination->submitted_identity = source.submitted_identity;
    destination->returned_identity = source.returned_identity;
}

} // namespace

bool npu_f32_mover_finalize_profile(npu_f32_mover_profile * profile) {
    return finalize_profile(profile);
}

bool npu_verilator_execute_f32_mover(
        const npu_f32_mover_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * src_allocation,
        std::size_t src_allocation_bytes,
        const std::uint8_t * index_allocation,
        std::size_t index_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_f32_mover_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (profile == nullptr || canonical_identity == nullptr) {
        result->runner_error_code = mover_runner_profile;
        return false;
    }
    npu_f32_mover_profile checked = *profile;
    const bool digest_nonzero =
        canonical_identity->sequence_id != 0 ||
        canonical_identity->producer_id != 0 ||
        canonical_identity->node_hash_lo != 0 ||
        canonical_identity->node_hash_hi != 0;
    if (!finalize_profile(&checked) ||
        checked.expected_read_bytes != profile->expected_read_bytes ||
        checked.expected_write_bytes != profile->expected_write_bytes ||
        checked.expected_elements != profile->expected_elements ||
        checked.expected_read_requests != profile->expected_read_requests ||
        checked.expected_write_requests != profile->expected_write_requests ||
        checked.cycle_upper_bound != profile->cycle_upper_bound ||
        canonical_identity->profile_id != 0 ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        !digest_nonzero) {
        result->runner_error_code = mover_runner_profile;
        return false;
    }
    const bool empty_get =
        checked.owner == npu_f32_mover_owner::get_rows &&
        checked.index_count == 0;
    const bool get_rows =
        checked.owner == npu_f32_mover_owner::get_rows;
    if ((empty_get &&
         (src_allocation != nullptr || src_allocation_bytes != 0 ||
          index_allocation != nullptr || index_allocation_bytes != 0 ||
          dst_shadow != nullptr || dst_shadow_bytes != 0)) ||
        (!empty_get &&
         (src_allocation == nullptr ||
          src_allocation_bytes != checked.src_bytes ||
          dst_shadow == nullptr || dst_shadow_bytes != checked.dst_bytes ||
          (get_rows &&
           (index_allocation == nullptr ||
            index_allocation_bytes != checked.index_bytes)) ||
          (!get_rows &&
           (index_allocation != nullptr || index_allocation_bytes != 0))))) {
        result->runner_error_code = mover_runner_profile;
        return false;
    }

    try {
        std::uint64_t src_window_base = 0;
        std::uint64_t src_window_bytes = 0;
        std::uint64_t index_window_base = 0;
        std::uint64_t index_window_bytes = 0;
        std::uint64_t dst_window_base = 0;
        std::uint64_t dst_window_bytes = 0;
        if (!aligned_window(
                kSrcIova, empty_get ? 0U : checked.src_bytes,
                &src_window_base, &src_window_bytes) ||
            !aligned_window(
                kIndexIova,
                (empty_get || !get_rows) ? 0U : checked.index_bytes,
                &index_window_base, &index_window_bytes) ||
            !aligned_window(
                kDstIova, checked.dst_bytes,
                &dst_window_base, &dst_window_bytes)) {
            result->runner_error_code = mover_runner_profile;
            return false;
        }
        std::vector<std::uint8_t> private_dst(
            static_cast<std::size_t>(checked.dst_bytes), 0xa5U);
        std::vector<std::uint8_t> expected_write(
            static_cast<std::size_t>(checked.dst_bytes), 1U);
        npu_system_transaction transaction = {};
        transaction.manifest_profile_id = checked.profile_id;
        transaction.identity = *canonical_identity;
        npu_exact_command_contract & command = transaction.command;
        command.abi_valid = 1U;
        command.windows_generation_valid = 1U;
        command.kernel_id = get_rows ? kKernelGetRowsF32 : kKernelRepeatF32;
        command.local_profile = 0U;
        command.command_flags = canonical_identity->command_flags;
        command.context_id = canonical_identity->context_id;
        command.capability_epoch = kCapabilityEpoch;
        command.node_count = 1U;
        command.sequence_id = canonical_identity->sequence_id;
        command.producer_id = canonical_identity->producer_id;
        command.user_tag = canonical_identity->user_tag;
        command.node_hash_lo = canonical_identity->node_hash_lo;
        command.node_hash_hi = canonical_identity->node_hash_hi;
        command.src0_iova = kSrcIova;
        command.src1_iova = get_rows ? kIndexIova : 0U;
        command.dst_iova = kDstIova;
        command.element_count = checked.element_count;
        command.outer_count = get_rows ?
            checked.index_count : checked.outer_count;
        command.dtype = kDtypeF32;
        command.src0_stride = checked.src_row_stride;
        command.src1_stride = checked.index_stride;
        command.src2_stride = checked.dst_outer_stride;
        command.dst_stride = checked.dst_row_stride;
        command.scalar0 = get_rows ?
            checked.source_row_count : checked.repeat_count;
        command.src0_window_base = src_window_base;
        command.src0_window_size = empty_get ? 0U : src_window_bytes;
        command.src0_window_perm = 1U;
        command.src1_window_base = get_rows ? index_window_base : 0U;
        command.src1_window_size =
            (empty_get || !get_rows) ? 0U : index_window_bytes;
        command.src1_window_perm = 1U;
        command.dst_window_base = dst_window_base;
        command.dst_window_size = dst_window_bytes;
        command.dst_window_perm = 2U;
        transaction.sources[0] = {
            kSrcIova, src_allocation, nullptr, src_allocation_bytes,
            src_window_base, empty_get ? 0U : src_window_bytes,
            true, false,
        };
        transaction.sources[1] = {
            get_rows ? kIndexIova : 0U,
            index_allocation, nullptr, index_allocation_bytes,
            get_rows ? index_window_base : 0U,
            (empty_get || !get_rows) ? 0U : index_window_bytes,
            true, false,
        };
        transaction.destination = {
            kDstIova, nullptr,
            private_dst.empty() ? nullptr : private_dst.data(),
            private_dst.size(), dst_window_base, dst_window_bytes,
            false, true,
        };
        transaction.expected_write_mask =
            expected_write.empty() ? nullptr : expected_write.data();
        transaction.expected_write_mask_bytes = expected_write.size();
        transaction.expected_semantic_write_bytes =
            checked.expected_write_bytes;
        // All tensor words use the raw32 mover portal in production.  Keep
        // the public GMEM completion/request ledger at zero and account raw
        // copies exclusively in f32_mover_portal.
        transaction.expected_read_bytes = 0U;
        transaction.expected_write_bytes = 0U;
        transaction.expected_vector_elements = checked.expected_elements;
        transaction.expected_read_requests = 0U;
        transaction.expected_write_requests = 0U;
        transaction.expected_required_issued = 1U;
        transaction.expected_required_completed = 1U;
        transaction.expected_public_completions = 1U;
        transaction.expected_macro_completions = 1U;
        transaction.cycle_upper_bound = checked.cycle_upper_bound;
        const std::uint64_t element_groups =
            (static_cast<std::uint64_t>(checked.element_count) + 15U) /
            16U;
        const std::uint64_t index_groups = get_rows ?
            (static_cast<std::uint64_t>(checked.index_count) + 15U) /
                16U :
            0U;
        const std::uint64_t source_groups = get_rows ?
            static_cast<std::uint64_t>(checked.index_count) *
                element_groups :
            static_cast<std::uint64_t>(checked.outer_count) *
                element_groups;
        const std::uint64_t write_groups = get_rows ? source_groups :
            static_cast<std::uint64_t>(checked.outer_count) *
                checked.repeat_count * element_groups;
        const std::uint64_t read_words = get_rows ?
            static_cast<std::uint64_t>(checked.index_count) +
                checked.expected_elements :
            checked.expected_read_requests;
        transaction.f32_mover_portal = {
            true,
            16U,
            2U,
            index_groups + source_groups + write_groups,
            index_groups + source_groups + write_groups,
            index_groups + source_groups,
            write_groups,
            read_words,
            checked.expected_elements,
            read_words * 4U,
            checked.expected_elements * 4U,
        };
        if (get_rows && !empty_get) {
            transaction.controlled_reject = {
                true,
                0U, 0U, 0U, 0U, 0U,
                0U, 0U, 0U,
                1U, 0U, 0U, 1U, 0U,
                15U, 4U, 15U,
            };
            transaction.controlled_reject.f32_mover_portal = {
                true,
                16U,
                2U,
                1U,
                1U,
                1U,
                0U,
                checked.index_count,
                0U,
                static_cast<std::uint64_t>(checked.index_count) * 4U,
                0U,
            };
        }

        npu_verilator_exact_result system_result = {};
        const bool executed = npu_verilator_execute_system_transaction(
            &transaction, &system_result);
        copy_system_result(system_result, result);
        if (!executed || system_result.controlled_reject) {
            result->passed = false;
            result->private_shadow_committed = false;
            result->result_bytes = 0;
            result->runner_error_code = mover_runner_terminal_mismatch;
            return false;
        }
        if (!private_dst.empty()) {
            std::memcpy(dst_shadow, private_dst.data(), private_dst.size());
        }
        result->private_shadow_committed = true;
        result->result_bytes = private_dst.size();
        result->runner_error_code = mover_runner_ok;
        return true;
    } catch (...) {
        result->passed = false;
        result->runner_error_code = mover_runner_allocation;
        return false;
    }
}
