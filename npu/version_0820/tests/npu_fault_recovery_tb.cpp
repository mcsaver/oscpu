#include "VTensorNpuCoprocessor.h"
#include "verilated.h"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>

namespace {

constexpr std::uint8_t kFatalMask = 0x80;
constexpr std::uint8_t kErrNone = 0;
constexpr std::uint8_t kErrIllegalEncoding = 1;
constexpr std::uint8_t kErrDescIncomplete = 5;
constexpr std::uint8_t kErrMacroAbi = 13;
constexpr std::uint8_t kErrMacroCapability = 14;
constexpr std::uint32_t kKernelGetRowsQ8 = 0x514e0001u;

[[noreturn]] void fail(const std::string &message) {
    std::cerr << "[NPU-FAULT-RECOVERY][FAIL] " << message << '\n';
    std::exit(EXIT_FAILURE);
}

void require(bool condition, const std::string &message) {
    if (!condition) {
        fail(message);
    }
}

template <std::size_t Words>
void zero_wide(VlWide<Words> &value) {
    std::fill(value.data(), value.data() + Words, 0u);
}

std::uint32_t encode_config(std::uint32_t subop, std::uint32_t rs,
                            std::uint32_t imm5) {
    return (5u << 25) | ((subop & 0x1fu) << 20) |
           ((rs & 0x1fu) << 15) | (4u << 12) |
           ((imm5 & 0x1fu) << 7) | 0x5bu;
}

std::uint64_t encode_mm2(std::uint32_t variant, std::uint32_t dst,
                         std::uint32_t src0, std::uint32_t src1,
                         std::uint32_t src2) {
    const std::uint32_t hi =
        (5u << 25) | (5u << 20) | ((dst & 0x1fu) << 15) |
        (3u << 12) | ((src0 & 0x1fu) << 7) | 0x5bu;
    const std::uint32_t lo =
        (1u << 25) | ((variant & 0x7u) << 22) |
        ((src2 & 0x1fu) << 15) | (3u << 12) |
        ((src1 & 0x1fu) << 7) | 0x5bu;
    return (static_cast<std::uint64_t>(hi) << 32) | lo;
}

class Harness {
  public:
    Harness()
        : context_(std::make_unique<VerilatedContext>()),
          dut_(std::make_unique<VTensorNpuCoprocessor>(context_.get())) {
        context_->randReset(0);
        initialize_inputs();
        dut_->eval();
    }

    ~Harness() { dut_->final(); }

    VTensorNpuCoprocessor &dut() { return *dut_; }

    void tick() {
        dut_->clk = 0;
        dut_->eval();
        context_->timeInc(1);
        dut_->clk = 1;
        dut_->eval();
        context_->timeInc(1);
        dut_->clk = 0;
        dut_->eval();
    }

    void reset() {
        dut_->cmd_valid_i = 0;
        dut_->completion_ready_i = 0;
        dut_->error_clear_i = 0;
        dut_->rst = 1;
        for (int i = 0; i < 4; ++i) {
            tick();
        }
        dut_->rst = 0;
        tick();
        require(dut_->cmd_ready_o == 1, "reset did not expose command ready");
        require(dut_->error_o == 0, "reset retained sticky error");
        require(dut_->error_code_o == kErrNone,
                "reset retained a tagged error code");
        require(dut_->error_clear_ready_o == 0,
                "reset advertised an error clear");
    }

    void issue(bool is64, std::uint64_t bits, std::uint8_t producer,
               bool required, std::uint8_t opclass,
               std::uint64_t rs_value = 0) {
        require(dut_->cmd_ready_o == 1, "command offered while not ready");
        dut_->cmd_is_64_i = is64;
        dut_->cmd_bits_i = bits;
        dut_->cmd_rs_value_i = rs_value;
        dut_->cmd_producer_id_i = producer;
        dut_->cmd_npu_required_i = required;
        dut_->cmd_opclass_i = opclass;
        dut_->cmd_valid_i = 1;
        tick();
        dut_->cmd_valid_i = 0;
        dut_->eval();
    }

    void issue_macro(std::uint32_t kernel, bool abi_valid,
                     std::uint64_t sequence, std::uint64_t producer) {
        require(dut_->macro_cmd_ready_o == 1,
                "macro command offered while not ready");
        dut_->macro_abi_valid_i = abi_valid;
        dut_->macro_kernel_id_i = kernel;
        dut_->macro_command_flags_i = 0x11;
        dut_->macro_capability_epoch_i = 1;
        dut_->macro_sequence_id_i = sequence;
        dut_->macro_producer_id_i = producer;
        dut_->macro_node_count_i = 1;
        dut_->macro_cmd_valid_i = 1;
        tick();
        dut_->macro_cmd_valid_i = 0;
        dut_->eval();
    }

    void wait_completion(int limit = 64) {
        for (int cycle = 0; cycle < limit; ++cycle) {
            if (dut_->completion_valid_o) {
                return;
            }
            tick();
        }
        fail("completion watchdog expired");
    }

    void accept_completion() {
        require(dut_->completion_valid_o == 1,
                "attempted to accept an absent completion");
        dut_->completion_ready_i = 1;
        tick();
        dut_->completion_ready_i = 0;
        dut_->eval();
        require(dut_->completion_valid_o == 0,
                "completion remained valid after acceptance");
    }

  private:
    void initialize_inputs() {
        dut_->clk = 0;
        dut_->rst = 1;
        dut_->cmd_valid_i = 0;
        dut_->cmd_is_64_i = 0;
        dut_->cmd_bits_i = 0;
        dut_->cmd_rs_value_i = 0;
        dut_->cmd_producer_id_i = 0;
        dut_->cmd_npu_required_i = 0;
        dut_->cmd_opclass_i = 0;

        dut_->macro_cmd_valid_i = 0;
        dut_->macro_abi_valid_i = 0;
        dut_->macro_kernel_id_i = 0;
        dut_->macro_command_flags_i = 0;
        dut_->macro_context_id_i = 0;
        dut_->macro_capability_epoch_i = 0;
        dut_->macro_sequence_id_i = 0;
        dut_->macro_producer_id_i = 0;
        dut_->macro_user_tag_i = 0;
        dut_->macro_node_count_i = 0;
        dut_->macro_node_hash_lo_i = 0;
        dut_->macro_node_hash_hi_i = 0;
        dut_->macro_deadline_cycles_i = 0;
        dut_->macro_vector_op_i = 0;
        dut_->macro_vector_flags_i = 0;
        dut_->macro_src0_iova_i = 0;
        dut_->macro_src1_iova_i = 0;
        dut_->macro_src2_iova_i = 0;
        dut_->macro_dst_iova_i = 0;
        dut_->macro_scratch_iova_i = 0;
        dut_->macro_element_count_i = 0;
        dut_->macro_outer_count_i = 0;
        dut_->macro_dtype_i = 0;
        dut_->macro_src0_stride_i = 0;
        dut_->macro_src1_stride_i = 0;
        dut_->macro_src2_stride_i = 0;
        dut_->macro_dst_stride_i = 0;
        dut_->macro_scalar0_i = 0;
        dut_->macro_scalar1_i = 0;
        dut_->macro_scratch_bytes_i = 0;
        dut_->macro_rope_position_i = 0;
        dut_->macro_src0_window_base_i = 0;
        dut_->macro_src0_window_size_i = 0;
        dut_->macro_src0_window_perm_i = 0;
        dut_->macro_src1_window_base_i = 0;
        dut_->macro_src1_window_size_i = 0;
        dut_->macro_src1_window_perm_i = 0;
        dut_->macro_dst_window_base_i = 0;
        dut_->macro_dst_window_size_i = 0;
        dut_->macro_dst_window_perm_i = 0;
        dut_->macro_windows_generation_valid_i = 0;

        dut_->completion_ready_i = 0;
        dut_->desc_write_valid_i = 0;
        dut_->desc_write_id_i = 0;
        dut_->desc_write_word_i = 0;
        dut_->desc_write_data_i = 0;
        dut_->host_lmem_rd_valid_i = 0;
        dut_->host_lmem_rd_addr_i = 0;
        dut_->host_lmem_rd_bytes_i = 0;
        dut_->host_lmem_wr_valid_i = 0;
        dut_->host_lmem_wr_addr_i = 0;
        dut_->host_lmem_wr_data_i = 0;
        dut_->host_lmem_wr_strb_i = 0;

        dut_->gmem_req_ready_i = 0;
        dut_->gmem_rsp_valid_i = 0;
        dut_->gmem_rsp_rdata_i = 0;
        dut_->gmem_rsp_error_i = 0;
        dut_->q8_portal_req_ready_i = 0;
        dut_->q8_portal_rsp_valid_i = 0;
        dut_->q8_portal_rsp_mask_i = 0;
        zero_wide(dut_->q8_portal_rsp_blocks_i);
        dut_->q8_portal_rsp_error_i = 0;
        dut_->f32_alu_portal_req_ready_i = 0;
        dut_->f32_alu_portal_rsp_valid_i = 0;
        dut_->f32_alu_portal_rsp_mask_i = 0;
        zero_wide(dut_->f32_alu_portal_rsp_src0_data_i);
        zero_wide(dut_->f32_alu_portal_rsp_src1_data_i);
        dut_->f32_alu_portal_rsp_error_i = 0;
        dut_->f32_mover_portal_req_ready_i = 0;
        dut_->f32_mover_portal_rsp_valid_i = 0;
        dut_->f32_mover_portal_rsp_mask_i = 0;
        zero_wide(dut_->f32_mover_portal_rsp_rdata_i);
        dut_->f32_mover_portal_rsp_error_i = 0;
        dut_->sync_tag_ack_i = 0;
        dut_->error_clear_i = 0;
    }

    std::unique_ptr<VerilatedContext> context_;
    std::unique_ptr<VTensorNpuCoprocessor> dut_;
};

void test_recoverable_static_decode(Harness &harness) {
    auto &dut = harness.dut();
    harness.reset();

    harness.issue(false, 0x00000013u, 0xa5, true, 0x5a);
    harness.wait_completion();
    require(dut.completion_error_o == 1,
            "illegal command completed without error");
    require(dut.completion_error_code_o == kErrIllegalEncoding,
            "static decode error was not tagged recoverable");
    require(dut.completion_producer_id_o == 0xa5,
            "recoverable terminal lost ProducerId");
    require(dut.completion_npu_required_o == 1,
            "recoverable terminal lost required bit");
    require(dut.completion_opclass_o == 0x5a,
            "recoverable terminal lost opclass");
    require(dut.error_clear_ready_o == 0,
            "clear became ready before terminal acceptance");
    require(dut.gmem_req_valid_o == 0 &&
                dut.q8_portal_req_valid_o == 0 &&
                dut.f32_alu_portal_req_valid_o == 0 &&
                dut.f32_mover_portal_req_valid_o == 0,
            "static decode error leaked a memory/portal request");

    dut.error_clear_i = 1;
    harness.tick();
    dut.error_clear_i = 0;
    dut.eval();
    require(dut.completion_valid_o == 1 &&
                dut.completion_error_code_o == kErrIllegalEncoding,
            "early clear mutated the held terminal");

    harness.accept_completion();
    require(dut.error_o == 1, "recoverable error did not enter sticky hold");
    require(dut.error_code_o == kErrIllegalEncoding,
            "sticky recoverable code changed after terminal acceptance");
    require(dut.error_clear_ready_o == 1,
            "recoverable ERROR_HOLD did not advertise clear readiness");
    require(dut.cmd_ready_o == 0,
            "command ready escaped recoverable ERROR_HOLD");

    dut.error_clear_i = 1;
    harness.tick();
    dut.error_clear_i = 0;
    dut.eval();
    require(dut.error_o == 0 && dut.error_code_o == kErrNone &&
                dut.error_clear_ready_o == 0 && dut.cmd_ready_o == 1,
            "accepted recoverable clear did not restore IDLE");

    harness.issue(false, encode_config(1, 3, 0), 0x35, false, 0x11,
                  0x0123456789abcdefULL);
    harness.wait_completion();
    require(dut.completion_error_o == 0 &&
                dut.completion_error_code_o == kErrNone &&
                dut.completion_producer_id_o == 0x35,
            "legal command did not complete after recoverable clear");
    harness.accept_completion();
    require(dut.cmd_ready_o == 1 && dut.error_o == 0,
            "post-clear success did not return to clean IDLE");
}

void clear_recoverable_error(Harness &harness, const std::string &context) {
    auto &dut = harness.dut();
    harness.accept_completion();
    require(dut.error_o == 1 && dut.error_clear_ready_o == 1,
            context + ": recoverable error did not reach clearable hold");
    dut.error_clear_i = 1;
    harness.tick();
    dut.error_clear_i = 0;
    dut.eval();
    require(dut.error_o == 0 && dut.error_code_o == kErrNone &&
                dut.error_clear_ready_o == 0 && dut.macro_cmd_ready_o == 1,
            context + ": clear did not restore clean IDLE");
}

void test_recoverable_macro_prelaunch(Harness &harness) {
    auto &dut = harness.dut();
    harness.reset();

    // A known kernel with invalid framing must fail in ST_MACRO_START before
    // any adapter receives start.  The frozen terminal remains clearable.
    harness.issue_macro(kKernelGetRowsQ8, false, 0x1020304050607080ULL,
                        0x8877665544332211ULL);
    harness.wait_completion();
    require(dut.completion_is_macro_o == 1 && dut.completion_error_o == 1 &&
                dut.completion_error_code_o == kErrMacroAbi,
            "prelaunch macro ABI rejection was not recoverable");
    require(dut.completion_macro_sequence_id_o ==
                    0x1020304050607080ULL &&
                dut.completion_macro_producer_id_o ==
                    0x8877665544332211ULL,
            "macro ABI terminal lost transaction identity");
    require(dut.gmem_req_valid_o == 0 &&
                dut.q8_portal_req_valid_o == 0 &&
                dut.f32_alu_portal_req_valid_o == 0 &&
                dut.f32_mover_portal_req_valid_o == 0 &&
                dut.q8_portal_outstanding_o == 0 &&
                dut.f32_alu_portal_outstanding_o == 0 &&
                dut.f32_mover_portal_outstanding_o == 0,
            "macro ABI rejection started memory or portal traffic");
    clear_recoverable_error(harness, "macro ABI rejection");

    // An unsupported kernel has no selected child at all, so capability
    // rejection is independently proven recoverable and clearable.
    harness.issue_macro(0xdeadbeefu, true, 0x1111222233334444ULL,
                        0xaaaabbbbccccddddULL);
    harness.wait_completion();
    require(dut.completion_is_macro_o == 1 && dut.completion_error_o == 1 &&
                dut.completion_error_code_o == kErrMacroCapability,
            "prelaunch macro capability rejection was not recoverable");
    require(dut.gmem_req_valid_o == 0 &&
                dut.q8_portal_req_valid_o == 0 &&
                dut.f32_alu_portal_req_valid_o == 0 &&
                dut.f32_mover_portal_req_valid_o == 0,
            "macro capability rejection emitted traffic");
    clear_recoverable_error(harness, "macro capability rejection");
}

void test_fatal_runtime_error(Harness &harness) {
    auto &dut = harness.dut();
    harness.reset();

    // A syntactically legal MM2 command starts the engine.  Reset left every
    // referenced descriptor incomplete, so the child reports a runtime
    // failure.  Until a complete late-transaction silence proof exists, this
    // class is intentionally fatal even though this particular fixture emits
    // no GMEM request.
    harness.issue(true, encode_mm2(0, 8, 9, 10, 0), 0xc6, true, 0x21);
    harness.wait_completion();
    const auto expected =
        static_cast<std::uint8_t>(kFatalMask | kErrDescIncomplete);
    require(dut.completion_error_o == 1,
            "incomplete MM2 descriptors did not fail");
    require(dut.completion_error_code_o == expected,
            "engine-started error was not tagged fatal");
    require(dut.error_clear_ready_o == 0,
            "fatal terminal advertised clear before acceptance");
    require(dut.gmem_req_valid_o == 0,
            "incomplete MM2 descriptor emitted GMEM traffic");

    harness.tick();
    require(dut.completion_valid_o == 1 &&
                dut.completion_error_code_o == expected,
            "fatal terminal changed under backpressure");
    harness.accept_completion();
    require(dut.error_o == 1 && dut.error_code_o == expected,
            "fatal error did not remain tagged in ERROR_HOLD");
    require(dut.error_clear_ready_o == 0 && dut.cmd_ready_o == 0,
            "fatal ERROR_HOLD exposed a recovery path");

    dut.error_clear_i = 1;
    for (int cycle = 0; cycle < 3; ++cycle) {
        harness.tick();
        require(dut.error_o == 1 && dut.error_code_o == expected &&
                    dut.error_clear_ready_o == 0 && dut.cmd_ready_o == 0,
                "fatal error was cleared without reset");
    }
    dut.error_clear_i = 0;
    dut.eval();

    harness.reset();
    require(dut.cmd_ready_o == 1 && dut.error_o == 0,
            "reset did not recover a fatal NPU lifecycle");
}

} // namespace

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Harness harness;
    test_recoverable_static_decode(harness);
    test_recoverable_macro_prelaunch(harness);
    test_fatal_runtime_error(harness);
    std::cout << "[NPU-FAULT-RECOVERY][PASS] recoverable-decode=1 "
                 "recoverable-macro-abi=1 recoverable-macro-capability=1 "
                 "post-clear-success=1 fatal-runtime=1 fatal-clear-blocked=1\n";
    return EXIT_SUCCESS;
}
