#include "npu-verilator-runner.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

namespace {

constexpr std::uint32_t kKernelQ8Gemv = 0x514e0002U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCapabilityEpoch = 1;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kDtypeF32 = 1;
constexpr std::uint32_t kProfileCount = 10;
constexpr std::uint32_t kPortalRowLanes = 4;
constexpr std::uint32_t kPortalMacLanes = 32;
constexpr std::uint32_t kPortalBlockBytes = 34;
constexpr std::uint32_t kPortalResponseLatencyCycles = 2;

// Deliberately unaligned, disjoint 64-bit IOVAs exercise every aligned-beat
// endpoint proof in the public Coprocessor.  Logical allocation bytes are
// supplied directly by the caller; only the at-most-seven padding bytes in a
// registered window read as zero.
constexpr std::uint64_t kActivationIova = 0x0000000310000004ULL;
constexpr std::uint64_t kWeightIova = 0x0000000520000002ULL;
constexpr std::uint64_t kDstIova = 0x0000000730000004ULL;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;
constexpr std::uint64_t kMinimumCycleUpperBound = 10000000ULL;
constexpr std::uint64_t kMaximumCycleUpperBound = 1100000000ULL;

enum gemv_runner_error : std::uint32_t {
    gemv_runner_ok = 0,
    gemv_runner_allocation = 0x160,
    gemv_runner_timeout = 0x161,
    gemv_runner_reset_interface = 0x162,
    gemv_runner_command_interface = 0x163,
    gemv_runner_request_protocol = 0x164,
    gemv_runner_response_protocol = 0x165,
    gemv_runner_completion_protocol = 0x166,
    gemv_runner_completion_identity = 0x167,
    gemv_runner_completion_framing = 0x168,
    gemv_runner_memory_bounds = 0x169,
    gemv_runner_result_coverage = 0x16a,
    gemv_runner_terminal_mismatch = 0x16b,
    gemv_runner_recovery = 0x16c,
    gemv_runner_profile = 0x16d,
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

bool finalize_profile(npu_q8_gemv_profile * profile) {
    if (profile == nullptr || profile->profile_id >= kProfileCount ||
        profile->k < 32 || profile->k > 4096 ||
        (profile->k & 31U) != 0 ||
        profile->m < 1 || profile->m > 248320 ||
        (profile->command_rows != 0 && profile->command_rows != profile->m) ||
        profile->block_count != profile->k / 32 ||
        profile->dst_row_stride != 4) {
        return false;
    }
    std::uint64_t activation_bytes = 0;
    std::uint64_t weight_row_bytes = 0;
    std::uint64_t weight_bytes = 0;
    std::uint64_t dst_bytes = 0;
    if (!checked_mul(profile->k, 4, &activation_bytes) ||
        !checked_mul(profile->block_count, 34, &weight_row_bytes) ||
        !checked_mul(profile->m, weight_row_bytes, &weight_bytes) ||
        !checked_mul(profile->m, 4, &dst_bytes) ||
        profile->activation_bytes != activation_bytes ||
        profile->weight_row_stride != weight_row_bytes ||
        profile->weight_bytes != weight_bytes ||
        profile->dst_bytes != dst_bytes) {
        return false;
    }

    const bool empty = profile->command_rows == 0;
    const std::uint64_t transfer_activation_bytes =
        empty ? 0 : activation_bytes;
    std::uint64_t transfer_weight_bytes = 0;
    std::uint64_t transfer_dst_bytes = 0;
    std::uint64_t transfer_q8_macs = 0;
    if (!checked_mul(profile->command_rows, weight_row_bytes,
                     &transfer_weight_bytes) ||
        !checked_mul(profile->command_rows, 4, &transfer_dst_bytes) ||
        !checked_mul(profile->command_rows, profile->k,
                     &transfer_q8_macs)) {
        return false;
    }

    std::uint64_t activation_window_base = 0;
    std::uint64_t activation_window_bytes = 0;
    std::uint64_t weight_window_base = 0;
    std::uint64_t weight_window_bytes = 0;
    std::uint64_t dst_window_base = 0;
    std::uint64_t dst_window_bytes = 0;
    if (!aligned_window(
            kActivationIova, transfer_activation_bytes,
            &activation_window_base, &activation_window_bytes) ||
        !aligned_window(
            kWeightIova, transfer_weight_bytes,
            &weight_window_base, &weight_window_bytes) ||
        !aligned_window(
            kDstIova, transfer_dst_bytes,
            &dst_window_base, &dst_window_bytes)) {
        return false;
    }
    // The bases are used here to make accidental mapping changes visible to
    // static analysis even though only the spans feed expected traffic.
    if ((activation_window_base & 7U) != 0 ||
        (weight_window_base & 7U) != 0 ||
        (dst_window_base & 7U) != 0 ||
        dst_window_bytes < transfer_dst_bytes) {
        return false;
    }

    std::uint64_t work = 0;
    std::uint64_t scaled_work = 0;
    std::uint64_t derived_cycle_bound = 0;
    if (!checked_mul(profile->command_rows, profile->block_count, &work) ||
        !checked_mul(work, 1024, &scaled_work) ||
        !checked_add(1000000, scaled_work, &derived_cycle_bound)) {
        derived_cycle_bound = kMaximumCycleUpperBound;
    }
    if (derived_cycle_bound < kMinimumCycleUpperBound) {
        derived_cycle_bound = kMinimumCycleUpperBound;
    }
    if (derived_cycle_bound > kMaximumCycleUpperBound) {
        derived_cycle_bound = kMaximumCycleUpperBound;
    }

    // Portal-enabled production never reports packed Q8 weight copies as raw
    // GMEM traffic.  The completion byte ledger records the physical aligned
    // activation window; the deliberately half-beat IOVA therefore exposes
    // one extra eight-byte read.  Logical K*4 payload coverage is proved by
    // the adapter's separate activation-word contract.
    profile->expected_read_bytes = activation_window_bytes;
    profile->expected_write_bytes = transfer_dst_bytes;
    profile->expected_read_requests = activation_window_bytes / 8U;
    profile->expected_write_requests = profile->command_rows;
    profile->expected_q8_macs = transfer_q8_macs;
    profile->expected_elements = profile->command_rows;
    profile->cycle_upper_bound = derived_cycle_bound;
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
    snapshot.covered_node_count = top.completion_macro_covered_node_count_o;
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
        std::array<std::uint8_t, N> * bytes,
        std::size_t offset,
        std::uint16_t value) {
    (*bytes)[offset] = static_cast<std::uint8_t>(value);
    (*bytes)[offset + 1] = static_cast<std::uint8_t>(value >> 8);
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

bool completion_frame_valid(const completion_snapshot & snapshot) {
    std::array<std::uint8_t, 128> record = {};
    store_le32(&record, 0x00, 0x514e5043U);
    store_le16(&record, 0x04, 1);
    store_le16(&record, 0x06, 0);
    store_le16(&record, 0x08, 128);
    store_le16(&record, 0x0a, 0);
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

class q8_gemv_harness {
public:
    q8_gemv_harness(
            const npu_q8_gemv_profile & profile,
            const npu_macro_identity & identity,
            const std::uint8_t * activation_allocation,
            std::size_t activation_allocation_bytes,
            const std::uint8_t * weight_allocation,
            std::size_t weight_allocation_bytes,
            std::uint8_t * dst_shadow,
            std::size_t dst_shadow_bytes,
            npu_verilator_q8_gemv_result * result)
        : profile_(profile),
          identity_(identity),
          activation_allocation_(activation_allocation),
          activation_allocation_bytes_(activation_allocation_bytes),
          weight_allocation_(weight_allocation),
          weight_allocation_bytes_(weight_allocation_bytes),
          dst_shadow_(dst_shadow),
          dst_shadow_bytes_(dst_shadow_bytes),
          result_(result),
          context_(std::make_unique<VerilatedContext>()),
          top_(std::make_unique<VTensorNpuCoprocessor>(context_.get())),
          dst_window_(static_cast<std::size_t>(profile.dst_bytes), 0xa5),
          dst_write_seen_(static_cast<std::size_t>(profile.dst_bytes), 0) {
        inputs_valid_ =
            activation_allocation_ != nullptr &&
            activation_allocation_bytes_ == profile_.activation_bytes &&
            weight_allocation_ != nullptr &&
            weight_allocation_bytes_ == profile_.weight_bytes &&
            dst_shadow_ != nullptr && dst_shadow_bytes_ == profile_.dst_bytes &&
            aligned_window(
                kActivationIova, profile_.activation_bytes,
                &activation_window_base_, &activation_window_bytes_) &&
            aligned_window(
                kWeightIova, profile_.weight_bytes,
                &weight_window_base_, &weight_window_bytes_) &&
            aligned_window(
                kDstIova, profile_.dst_bytes,
                &dst_window_base_, &dst_window_bytes_);
        drive_idle_inputs();
        top_->eval();
    }

    ~q8_gemv_harness() {
        top_->final();
    }

    bool run() {
        result_->submitted_identity = identity_;
        result_->cycle_upper_bound = profile_.cycle_upper_bound;
        if (!inputs_valid_) {
            return fail(gemv_runner_profile);
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
            return fail(gemv_runner_response_protocol);
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
            return fail(gemv_runner_completion_identity);
        }
        result_->completion_framing_valid =
            completion_frame_valid(snapshot);
        if (!result_->completion_framing_valid) {
            return fail(gemv_runner_completion_framing);
        }
        snapshot_result(snapshot);
        if (!validate_terminal(snapshot)) {
            return fail(gemv_runner_terminal_mismatch);
        }
        if (!consume_completion_and_recover(snapshot)) {
            return fail(gemv_runner_recovery);
        }
        if (snapshot.error != 0) {
            result_->controlled_reject = true;
            return false;
        }
        if (written_bytes_ != profile_.dst_bytes) {
            return fail(gemv_runner_result_coverage);
        }
        for (std::uint8_t seen : dst_write_seen_) {
            if (seen != 1) {
                return fail(gemv_runner_result_coverage);
            }
        }
        std::memcpy(dst_shadow_, dst_window_.data(), dst_window_.size());
        result_->result_bytes = dst_window_.size();
        result_->private_shadow_committed = true;
        result_->passed = true;
        result_->runner_error_code = gemv_runner_ok;
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
        top_->macro_kernel_id_i = kKernelQ8Gemv;
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
        // Frozen ABI order differs from GGML: activation first, weights second.
        top_->macro_src0_iova_i = kActivationIova;
        top_->macro_src1_iova_i = kWeightIova;
        top_->macro_src2_iova_i = 0;
        top_->macro_dst_iova_i = kDstIova;
        top_->macro_scratch_iova_i = 0;
        top_->macro_element_count_i = profile_.k;
        top_->macro_outer_count_i = profile_.m;
        top_->macro_dtype_i = kDtypeF32;
        top_->macro_src0_stride_i = 0;
        top_->macro_src1_stride_i = profile_.weight_row_stride;
        top_->macro_src2_stride_i = 0;
        top_->macro_dst_stride_i = profile_.dst_row_stride;
        top_->macro_scalar0_i = 0;
        top_->macro_scalar1_i = 0;
        top_->macro_scratch_bytes_i = 0;
        top_->macro_rope_position_i = 0;
        top_->macro_src0_window_base_i = activation_window_base_;
        top_->macro_src0_window_size_i = activation_window_bytes_;
        top_->macro_src0_window_perm_i = 1;
        top_->macro_src1_window_base_i = weight_window_base_;
        top_->macro_src1_window_size_i = weight_window_bytes_;
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
            return fail(gemv_runner_timeout);
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
            return fail(gemv_runner_request_protocol);
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
                return fail(gemv_runner_request_protocol);
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
                const std::size_t offset =
                    static_cast<std::size_t>(physical - logical_base);
                value |= static_cast<std::uint64_t>(allocation[offset]) <<
                         (8 * lane);
            }
        }
        return value;
    }

    bool prepare_response(response_slot * request) {
        if (request == nullptr || (request->address & 7U) != 0) {
            return fail(gemv_runner_request_protocol);
        }
        if (request->write) {
            if ((request->wstrb != 0x0f && request->wstrb != 0xf0) ||
                !beat_in_window(
                    request->address, dst_window_base_, dst_window_bytes_)) {
                return fail(gemv_runner_memory_bounds);
            }
            return true;
        }
        if (request->wstrb != 0 || top_->gmem_req_wdata_o != 0) {
            return fail(gemv_runner_request_protocol);
        }
        if (!read_beats_seen_.insert(request->address).second) {
            return fail(gemv_runner_request_protocol);
        }
        if (beat_in_window(
                request->address,
                activation_window_base_, activation_window_bytes_)) {
            request->data = load_raw_beat(
                request->address, kActivationIova,
                activation_allocation_, activation_allocation_bytes_);
            return true;
        }
        if (beat_in_window(
                request->address, weight_window_base_, weight_window_bytes_)) {
            request->data = load_raw_beat(
                request->address, kWeightIova,
                weight_allocation_, weight_allocation_bytes_);
            return true;
        }
        return fail(gemv_runner_memory_bounds);
    }

    bool commit_write(const response_slot & request) {
        if (!beat_in_window(
                request.address, dst_window_base_, dst_window_bytes_)) {
            return fail(gemv_runner_memory_bounds);
        }
        std::size_t strobed = 0;
        for (std::size_t lane = 0; lane < 8; ++lane) {
            if ((request.wstrb & (1U << lane)) == 0) {
                continue;
            }
            ++strobed;
            const std::uint64_t physical = request.address + lane;
            if (physical < kDstIova ||
                physical - kDstIova >= profile_.dst_bytes) {
                return fail(gemv_runner_memory_bounds);
            }
            const std::size_t offset =
                static_cast<std::size_t>(physical - kDstIova);
            if (dst_write_seen_[offset] != 0) {
                return fail(gemv_runner_result_coverage);
            }
            dst_write_seen_[offset] = 1;
            ++written_bytes_;
            dst_window_[offset] = static_cast<std::uint8_t>(
                request.data >> (8 * lane));
        }
        if (strobed != 4) {
            return fail(gemv_runner_result_coverage);
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
            return fail(gemv_runner_reset_interface);
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
            return fail(gemv_runner_command_interface);
        }
        if (!tick()) {
            return false;
        }
        drive_macro_idle();
        top_->eval();
        update_required_deltas();
        if (result_->required_issued_delta != 1 ||
            result_->required_completed_delta != 0) {
            return fail(gemv_runner_completion_protocol);
        }
        return true;
    }

    bool hold_and_check_completion(const completion_snapshot & snapshot) {
        result_->completion_stable = true;
        top_->completion_ready_i = 0;
        const std::uint64_t expected_completed = snapshot.error ? 0 : 1;
        for (unsigned index = 0; index < kCompletionBackpressureCycles;
             ++index) {
            if (!top_->completion_valid_o ||
                !(capture_completion(*top_) == snapshot)) {
                result_->completion_stable = false;
                return fail(gemv_runner_completion_protocol);
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
                return fail(gemv_runner_completion_protocol);
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
               snapshot.kernel_id == kKernelQ8Gemv &&
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
            profile_.expected_read_bytes / 8 + profile_.m;
        return snapshot.error == 0 && snapshot.status == 0 &&
               snapshot.error_code == 0 && snapshot.error_class == 0 &&
               result_->commands_accepted == 1 &&
               result_->commands_terminal_success == 1 &&
               result_->commands_terminal_failure == 0 &&
               result_->required_issued_delta == 1 &&
               result_->required_completed_delta == 1 &&
               result_->gmem_requests_accepted == expected_requests &&
               result_->gmem_requests_accepted ==
                   result_->gmem_responses_accepted &&
               read_beats_seen_.size() ==
                   profile_.expected_read_bytes / 8 &&
               snapshot.gmem_read_bytes == profile_.expected_read_bytes &&
               snapshot.gmem_write_bytes == profile_.expected_write_bytes &&
               snapshot.q8_mac_count == profile_.expected_q8_macs &&
               snapshot.vector_element_count == profile_.expected_elements &&
               snapshot.state_update_count == 0 &&
               result_->f32_start_count == 0 &&
               snapshot.npu_cycles > 0 &&
               snapshot.npu_cycles <= profile_.cycle_upper_bound &&
               written_bytes_ == profile_.dst_bytes;
    }

    bool consume_completion_and_recover(
            const completion_snapshot & snapshot) {
        if (!top_->completion_valid_o ||
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
        update_required_deltas();
        if (result_->required_issued_delta != 1 ||
            result_->required_completed_delta != 1) {
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

    npu_q8_gemv_profile profile_;
    npu_macro_identity identity_;
    const std::uint8_t * activation_allocation_;
    std::size_t activation_allocation_bytes_;
    const std::uint8_t * weight_allocation_;
    std::size_t weight_allocation_bytes_;
    std::uint8_t * dst_shadow_;
    std::size_t dst_shadow_bytes_;
    npu_verilator_q8_gemv_result * result_;
    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> top_;
    std::vector<std::uint8_t> dst_window_;
    std::vector<std::uint8_t> dst_write_seen_;
    std::unordered_set<std::uint64_t> read_beats_seen_;
    response_slot response_ = {};
    bool inputs_valid_ = false;
    bool unaccepted_request_held_ = false;
    std::uint32_t held_request_write_ = 0;
    std::uint64_t held_request_address_ = 0;
    std::uint64_t held_request_data_ = 0;
    std::uint32_t held_request_wstrb_ = 0;
    std::uint64_t activation_window_base_ = 0;
    std::uint64_t activation_window_bytes_ = 0;
    std::uint64_t weight_window_base_ = 0;
    std::uint64_t weight_window_bytes_ = 0;
    std::uint64_t dst_window_base_ = 0;
    std::uint64_t dst_window_bytes_ = 0;
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
        npu_verilator_q8_gemv_result * destination) {
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
    destination->runner_error_code = source.runner_error_code;
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

bool npu_q8_gemv_finalize_profile(npu_q8_gemv_profile * profile) {
    return finalize_profile(profile);
}

bool npu_verilator_execute_q8_gemv(
        const npu_q8_gemv_profile * profile,
        const npu_macro_identity * canonical_identity,
        const std::uint8_t * activation_allocation,
        std::size_t activation_allocation_bytes,
        const std::uint8_t * weight_allocation,
        std::size_t weight_allocation_bytes,
        std::uint8_t * dst_shadow,
        std::size_t dst_shadow_bytes,
        npu_verilator_q8_gemv_result * result) {
    if (result == nullptr) {
        return false;
    }
    *result = {};
    if (profile == nullptr || canonical_identity == nullptr) {
        result->runner_error_code = gemv_runner_profile;
        return false;
    }
    npu_q8_gemv_profile checked_profile = *profile;
    const bool digest_is_nonzero =
        canonical_identity->sequence_id != 0 ||
        canonical_identity->producer_id != 0 ||
        canonical_identity->node_hash_lo != 0 ||
        canonical_identity->node_hash_hi != 0;
    if (!finalize_profile(&checked_profile) ||
        checked_profile.expected_read_bytes != profile->expected_read_bytes ||
        checked_profile.expected_write_bytes != profile->expected_write_bytes ||
        checked_profile.expected_read_requests !=
            profile->expected_read_requests ||
        checked_profile.expected_write_requests !=
            profile->expected_write_requests ||
        checked_profile.expected_q8_macs != profile->expected_q8_macs ||
        checked_profile.expected_elements != profile->expected_elements ||
        checked_profile.cycle_upper_bound != profile->cycle_upper_bound ||
        canonical_identity->profile_id != 0 ||
        canonical_identity->command_flags != kCanonicalCommandFlags ||
        canonical_identity->context_id != kCanonicalContextId ||
        !digest_is_nonzero) {
        result->runner_error_code = gemv_runner_profile;
        return false;
    }
    const bool empty = checked_profile.command_rows == 0;
    if ((empty &&
         (activation_allocation != nullptr || activation_allocation_bytes != 0 ||
          weight_allocation != nullptr || weight_allocation_bytes != 0 ||
          dst_shadow != nullptr || dst_shadow_bytes != 0)) ||
        (!empty &&
         (activation_allocation == nullptr ||
          activation_allocation_bytes != checked_profile.activation_bytes ||
          weight_allocation == nullptr ||
          weight_allocation_bytes != checked_profile.weight_bytes ||
          dst_shadow == nullptr ||
          dst_shadow_bytes != checked_profile.dst_bytes))) {
        result->runner_error_code = gemv_runner_profile;
        return false;
    }

    try {
        const std::uint64_t transfer_activation_bytes =
            empty ? 0 : checked_profile.activation_bytes;
        const std::uint64_t transfer_weight_bytes =
            empty ? 0 : checked_profile.weight_bytes;
        const std::uint64_t transfer_dst_bytes =
            empty ? 0 : checked_profile.dst_bytes;
        std::uint64_t activation_window_base = 0;
        std::uint64_t activation_window_bytes = 0;
        std::uint64_t weight_window_base = 0;
        std::uint64_t weight_window_bytes = 0;
        std::uint64_t dst_window_base = 0;
        std::uint64_t dst_window_bytes = 0;
        if (!aligned_window(
                kActivationIova, transfer_activation_bytes,
                &activation_window_base, &activation_window_bytes) ||
            !aligned_window(
                kWeightIova, transfer_weight_bytes,
                &weight_window_base, &weight_window_bytes) ||
            !aligned_window(
                kDstIova, transfer_dst_bytes,
                &dst_window_base, &dst_window_bytes)) {
            result->runner_error_code = gemv_runner_profile;
            return false;
        }
        std::uint64_t portal_tile_numerator = 0;
        std::uint64_t portal_tiles = 0;
        std::uint64_t portal_request_groups = 0;
        std::uint64_t portal_blocks = 0;
        std::uint64_t portal_bytes = 0;
        if (!checked_add(
                checked_profile.command_rows, kPortalRowLanes - 1U,
                &portal_tile_numerator)) {
            result->runner_error_code = gemv_runner_profile;
            return false;
        }
        portal_tiles = portal_tile_numerator / kPortalRowLanes;
        if (!checked_mul(
                portal_tiles, checked_profile.block_count,
                &portal_request_groups) ||
            !checked_mul(
                checked_profile.command_rows, checked_profile.block_count,
                &portal_blocks) ||
            !checked_mul(portal_blocks, kPortalBlockBytes, &portal_bytes)) {
            result->runner_error_code = gemv_runner_profile;
            return false;
        }
        std::vector<std::uint8_t> private_dst(
            static_cast<std::size_t>(transfer_dst_bytes), 0xa5U);
        std::vector<std::uint8_t> expected_write(
            static_cast<std::size_t>(transfer_dst_bytes), 1U);
        npu_system_transaction transaction = {};
        transaction.manifest_profile_id = checked_profile.profile_id;
        transaction.identity = *canonical_identity;
        npu_exact_command_contract & command = transaction.command;
        command.abi_valid = 1U;
        command.windows_generation_valid = 1U;
        command.kernel_id = kKernelQ8Gemv;
        command.vector_op = 0U;
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
        command.src0_iova = empty ? activation_window_base : kActivationIova;
        command.src1_iova = empty ? weight_window_base : kWeightIova;
        command.dst_iova = empty ? dst_window_base : kDstIova;
        command.element_count = checked_profile.k;
        command.outer_count = checked_profile.command_rows;
        command.dtype = kDtypeF32;
        command.src1_stride = checked_profile.weight_row_stride;
        command.dst_stride = checked_profile.dst_row_stride;
        command.src0_window_base = activation_window_base;
        command.src0_window_size = activation_window_bytes;
        command.src0_window_perm = 1U;
        command.src1_window_base = weight_window_base;
        command.src1_window_size = weight_window_bytes;
        command.src1_window_perm = 1U;
        command.dst_window_base = dst_window_base;
        command.dst_window_size = dst_window_bytes;
        command.dst_window_perm = 2U;
        transaction.sources[0] = {
            command.src0_iova, activation_allocation, nullptr,
            activation_allocation_bytes,
            activation_window_base, activation_window_bytes, true, false,
        };
        transaction.sources[1] = {
            command.src1_iova, weight_allocation, nullptr,
            weight_allocation_bytes,
            weight_window_base, weight_window_bytes, true, false,
        };
        transaction.destination = {
            command.dst_iova, nullptr, private_dst.data(), private_dst.size(),
            dst_window_base, dst_window_bytes, false, true,
        };
        transaction.expected_write_mask = expected_write.data();
        transaction.expected_write_mask_bytes = expected_write.size();
        // Weights leave the raw GMEM channel entirely.  The System harness
        // copies each RTL-addressed 34-byte Q8_0 block through the portal;
        // raw GMEM retains only the aligned activation reads and F32 writes.
        transaction.expected_read_bytes =
            checked_profile.expected_read_bytes;
        transaction.expected_write_bytes =
            checked_profile.expected_write_bytes;
        transaction.expected_vector_elements =
            checked_profile.expected_elements;
        transaction.expected_q8_macs = checked_profile.expected_q8_macs;
        transaction.expected_read_requests =
            checked_profile.expected_read_requests;
        transaction.expected_write_requests =
            checked_profile.expected_write_requests;
        transaction.expected_required_issued = 1U;
        transaction.expected_required_completed = 1U;
        transaction.expected_public_completions = 1U;
        transaction.expected_macro_completions = 1U;
        transaction.cycle_upper_bound = checked_profile.cycle_upper_bound;
        transaction.require_unique_read_beats = true;
        transaction.require_f32_halfbeat_wstrb = true;
        transaction.validate_source_read_requests = true;
        transaction.expected_source_read_requests = {
            checked_profile.expected_read_requests,
            0U,
        };
        transaction.q8_portal.enabled = true;
        transaction.q8_portal.row_lanes = kPortalRowLanes;
        transaction.q8_portal.mac_lanes = kPortalMacLanes;
        transaction.q8_portal.block_bytes = kPortalBlockBytes;
        transaction.q8_portal.blocks_per_row = checked_profile.block_count;
        transaction.q8_portal.response_latency_cycles =
            kPortalResponseLatencyCycles;
        transaction.q8_portal.expected_request_groups =
            portal_request_groups;
        transaction.q8_portal.expected_blocks = portal_blocks;
        transaction.q8_portal.expected_bytes = portal_bytes;

        npu_verilator_exact_result system_result = {};
        const bool executed = npu_verilator_execute_system_transaction(
            &transaction, &system_result);
        copy_system_result(system_result, result);
        if (!executed || system_result.controlled_reject) {
            result->passed = false;
            if (result->runner_error_code == gemv_runner_ok) {
                result->runner_error_code = gemv_runner_terminal_mismatch;
            }
            return false;
        }
        if (!empty) {
            std::memcpy(dst_shadow, private_dst.data(), private_dst.size());
        }
        result->private_shadow_committed = true;
        result->result_bytes = private_dst.size();
        result->runner_error_code = gemv_runner_ok;
        return true;
    } catch (...) {
        result->passed = false;
        result->runner_error_code = gemv_runner_allocation;
        return false;
    }
}
