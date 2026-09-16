#include "npu-rv64-service-firmware-image.h"
#include "npu_service_mailbox_abi.h"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <utility>
#include <vector>

namespace firmware = npu::rv64_service_firmware_v1;

namespace {

constexpr std::uint32_t kNop = 0x00000013U;
constexpr std::uint32_t kLaunchLo = 0x0220305bU;
constexpr std::uint32_t kLaunchHi = 0x0bf0305bU;
constexpr std::uint32_t kConfigIndexMask = 0x01f00000U;
constexpr std::uint32_t kConfigFixedMask = ~kConfigIndexMask;
constexpr std::uint32_t kConfigFixedBits = 0x0a03cfdbU;
constexpr std::uint32_t kRecoveryClear = 0x0be04fdbU;
constexpr std::uint32_t kLastGenerationInit = 0x00000b93U;
constexpr std::uint32_t kGenerationLoad = 0x01843a83U;
constexpr std::uint32_t kLastGenerationAccept = 0x000a8b93U;
constexpr std::uint32_t kBadGenerationCode = 0x00700293U;
constexpr std::uint32_t kPollReadyLoad = 0x00842283U;
constexpr std::uint32_t kTrapGuardZero = 0x00000c13U;
constexpr std::uint32_t kTrapGuardSet = 0x00100c13U;
constexpr std::uint32_t kCause24 = 0x01800e13U;
constexpr std::uint32_t kVersionShift = 0x02035e13U;
constexpr std::uint32_t kVersionMask = 0x03fe7e13U;
constexpr std::uint32_t kVersionOne = 0x00100e93U;
constexpr std::uint32_t kNpuFaultMailboxCode = 0x00800e13U;
constexpr std::uint32_t kNpuFatalPreciseCode = 0x00900e13U;
constexpr std::uint32_t kNpuFatalUntrustedCode = 0x00900293U;
constexpr std::uint32_t kMailboxErrorState = 0x00400293U;
constexpr std::uint32_t kFenceRwW = 0x0310000fU;
constexpr std::uint32_t kMret = 0x30200073U;
constexpr std::uint32_t kFatalSpin = 0x0000006fU;

bool fail(const char * message) {
    std::fprintf(stderr, "[NPU-RV64-FIRMWARE][FAIL] %s\n", message);
    return false;
}

std::uint32_t read_word(std::size_t offset) {
    return static_cast<std::uint32_t>(firmware::kImage[offset]) |
           (static_cast<std::uint32_t>(firmware::kImage[offset + 1]) << 8U) |
           (static_cast<std::uint32_t>(firmware::kImage[offset + 2]) << 16U) |
           (static_cast<std::uint32_t>(firmware::kImage[offset + 3]) << 24U);
}

std::uint32_t encode_ld(unsigned index) {
    const unsigned immediate = index * sizeof(std::uint64_t);
    return ((immediate & 0xfffU) << 20U) | (9U << 15U) | (3U << 12U) |
           (7U << 7U) | 3U;
}

bool is_beq(
        std::uint32_t word,
        unsigned source0,
        unsigned source1) {
    return (word & 0x7fU) == 0x63U &&
           ((word >> 12U) & 7U) == 0U &&
           ((word >> 15U) & 31U) == source0 &&
           ((word >> 20U) & 31U) == source1;
}

bool is_bne(
        std::uint32_t word,
        unsigned source0,
        unsigned source1) {
    return (word & 0x7fU) == 0x63U &&
           ((word >> 12U) & 7U) == 1U &&
           ((word >> 15U) & 31U) == source0 &&
           ((word >> 20U) & 31U) == source1;
}

bool is_blt(
        std::uint32_t word,
        unsigned source0,
        unsigned source1) {
    return (word & 0x7fU) == 0x63U &&
           ((word >> 12U) & 7U) == 4U &&
           ((word >> 15U) & 31U) == source0 &&
           ((word >> 20U) & 31U) == source1;
}

bool is_bgeu(
        std::uint32_t word,
        unsigned source0,
        unsigned source1) {
    return (word & 0x7fU) == 0x63U &&
           ((word >> 12U) & 7U) == 7U &&
           ((word >> 15U) & 31U) == source0 &&
           ((word >> 20U) & 31U) == source1;
}

bool is_csr(
        std::uint32_t word,
        unsigned funct3,
        unsigned destination,
        unsigned source,
        unsigned csr) {
    return (word & 0x7fU) == 0x73U &&
           ((word >> 12U) & 7U) == funct3 &&
           ((word >> 7U) & 31U) == destination &&
           ((word >> 15U) & 31U) == source &&
           ((word >> 20U) & 0xfffU) == csr;
}

bool is_tensor_config(
        std::uint32_t word,
        unsigned index,
        unsigned source) {
    return (word & 0x7fU) == 0x5bU &&
           ((word >> 25U) & 0x7fU) == 5U &&
           ((word >> 20U) & 31U) == index &&
           ((word >> 15U) & 31U) == source &&
           ((word >> 12U) & 7U) == 4U &&
           ((word >> 7U) & 31U) == 31U;
}

bool is_sd(
        std::uint32_t word,
        unsigned source,
        unsigned base,
        unsigned byte_offset) {
    const unsigned immediate =
        ((word >> 25U) & 0x7fU) << 5U | ((word >> 7U) & 0x1fU);
    return (word & 0x7fU) == 0x23U &&
           ((word >> 12U) & 7U) == 3U &&
           ((word >> 20U) & 31U) == source &&
           ((word >> 15U) & 31U) == base &&
           immediate == byte_offset;
}

bool is_sw(
        std::uint32_t word,
        unsigned source,
        unsigned base,
        unsigned byte_offset) {
    const unsigned immediate =
        ((word >> 25U) & 0x7fU) << 5U | ((word >> 7U) & 0x1fU);
    return (word & 0x7fU) == 0x23U &&
           ((word >> 12U) & 7U) == 2U &&
           ((word >> 20U) & 31U) == source &&
           ((word >> 15U) & 31U) == base &&
           immediate == byte_offset;
}

bool branch_target(
        std::size_t offset,
        std::uint32_t word,
        std::size_t * target) {
    std::uint32_t immediate =
        ((word >> 31U) & 1U) << 12U |
        ((word >> 7U) & 1U) << 11U |
        ((word >> 25U) & 0x3fU) << 5U |
        ((word >> 8U) & 0x0fU) << 1U;
    std::int32_t signed_immediate = static_cast<std::int32_t>(immediate);
    if ((immediate & 0x1000U) != 0U) {
        signed_immediate -= 0x2000;
    }
    const std::int64_t decoded =
        static_cast<std::int64_t>(offset) + signed_immediate;
    if (decoded < 0 ||
        decoded + 4 > static_cast<std::int64_t>(firmware::kImageBytes)) {
        return false;
    }
    *target = static_cast<std::size_t>(decoded);
    return true;
}

bool pc_relative_address_before(
        std::size_t consumer_offset,
        std::size_t * target) {
    if (consumer_offset < 8U) {
        return false;
    }
    const std::size_t auipc_offset = consumer_offset - 8U;
    const std::uint32_t auipc = read_word(auipc_offset);
    const std::uint32_t addi = read_word(consumer_offset - 4U);
    if ((auipc & 0x7fU) != 0x17U ||
        ((auipc >> 7U) & 31U) != 5U ||
        (addi & 0x7fU) != 0x13U ||
        ((addi >> 12U) & 7U) != 0U ||
        ((addi >> 7U) & 31U) != 5U ||
        ((addi >> 15U) & 31U) != 5U) {
        return false;
    }
    const std::int64_t upper = static_cast<std::int32_t>(
        auipc & 0xfffff000U);
    std::int32_t lower = static_cast<std::int32_t>(addi) >> 20U;
    const std::int64_t address =
        static_cast<std::int64_t>(firmware::kLoadAddress + auipc_offset) +
        upper + lower;
    if (address < static_cast<std::int64_t>(firmware::kLoadAddress) ||
        address + 4 > static_cast<std::int64_t>(
            firmware::kLoadAddress + firmware::kImageBytes)) {
        return false;
    }
    *target = static_cast<std::size_t>(
        address - static_cast<std::int64_t>(firmware::kLoadAddress));
    return true;
}

bool check_layout() {
    if (firmware::kLoadAddress != 0x80000000ULL ||
        firmware::kEntryAddress != firmware::kLoadAddress) {
        return fail("flat image is not entered at 0x80000000");
    }
    if (firmware::kImageBytes == 0 || firmware::kImageBytes > 0x1000 ||
        (firmware::kImageBytes & 3U) != 0U) {
        return fail("image does not fit the 4 KiB, 32-bit instruction aperture");
    }
    if (firmware::kMailboxAddress != NPU_SERVICE_MAILBOX_ADDRESS ||
        firmware::kCommandAddress != NPU_SERVICE_COMMAND_ADDRESS ||
        firmware::kCompletionAddress != NPU_SERVICE_COMPLETION_ADDRESS) {
        return fail("embedded mailbox addresses differ from the source ABI");
    }
    if (NPU_SERVICE_COMMAND_STRIDE != 30U * sizeof(std::uint64_t) ||
        NPU_SERVICE_COMPLETION_STRIDE !=
            sizeof(npu_service_completion_v1) ||
        NPU_SERVICE_MAX_COMMANDS !=
            (NPU_SERVICE_COMPLETION_ADDRESS -
             NPU_SERVICE_COMMAND_ADDRESS) /
                NPU_SERVICE_COMMAND_STRIDE) {
        return fail("mailbox region sizing or record stride drifted");
    }
    if (NPU_SERVICE_ABI_MAJOR != 1 || NPU_SERVICE_ABI_MINOR != 3 ||
        NPU_SERVICE_NPU_FAULT_MCAUSE != 24 ||
        NPU_SERVICE_NPU_FAULT_MTVAL_VERSION != 1 ||
        NPU_SERVICE_COMPLETION_STATUS_SUCCESS != 0 ||
        NPU_SERVICE_COMPLETION_STATUS_NPU_FAULT != 1 ||
        NPU_SERVICE_COMPLETION_STATUS_NPU_FATAL != 2 ||
        offsetof(npu_service_completion_v1, fault_tval) != 40U ||
        offsetof(npu_service_completion_v1, fault_pc) != 48U ||
        offsetof(npu_service_completion_v1, fault_cause) != 56U) {
        return fail("mailbox ABI 1.3 precise-fault fields drifted");
    }
    return true;
}

bool check_generation_gate() {
    std::vector<std::size_t> initializes;
    std::vector<std::size_t> loads;
    std::vector<std::size_t> zero_gates;
    std::vector<std::size_t> repeat_gates;
    std::vector<std::size_t> accepts;

    for (std::size_t offset = 0; offset + 4 <= firmware::kImageBytes;
         offset += 4) {
        const std::uint32_t word = read_word(offset);
        if (word == kLastGenerationInit) {
            initializes.push_back(offset);
        } else if (word == kGenerationLoad) {
            loads.push_back(offset);
        } else if (is_beq(word, 21U, 0U)) {
            zero_gates.push_back(offset);
        } else if (is_bgeu(word, 23U, 21U)) {
            repeat_gates.push_back(offset);
        } else if (word == kLastGenerationAccept) {
            accepts.push_back(offset);
        }
    }

    if (initializes.size() != 1 || loads.size() != 1 ||
        zero_gates.size() != 1 || repeat_gates.size() != 1 ||
        accepts.size() != 1) {
        return fail("image lacks one complete monotonic generation gate");
    }
    if (!(initializes[0] < loads[0] &&
          loads[0] < zero_gates[0] &&
          zero_gates[0] < repeat_gates[0] &&
          repeat_gates[0] < accepts[0])) {
        return fail("last_generation is updated before generation is accepted");
    }

    std::size_t zero_target = 0;
    std::size_t repeat_target = 0;
    if (!branch_target(zero_gates[0], read_word(zero_gates[0]),
                       &zero_target) ||
        !branch_target(repeat_gates[0], read_word(repeat_gates[0]),
                       &repeat_target) ||
        zero_target != repeat_target ||
        read_word(zero_target) != kBadGenerationCode) {
        return fail("zero/stale generation does not converge on BAD_GENERATION");
    }
    return true;
}

bool check_tensor_encoding() {
    std::vector<std::pair<unsigned, std::size_t>> configs;
    std::vector<std::size_t> recovery_clears;
    std::size_t tensor_config_count = 0;
    std::vector<std::size_t> launches;

    for (std::size_t offset = 0; offset + 4 <= firmware::kImageBytes;
         offset += 4) {
        const std::uint32_t word = read_word(offset);
        if ((word & kConfigFixedMask) == kConfigFixedBits &&
            is_tensor_config(
                word,
                static_cast<unsigned>((word & kConfigIndexMask) >> 20U),
                7U)) {
            configs.emplace_back(
                static_cast<unsigned>((word & kConfigIndexMask) >> 20U),
                offset);
        }
        for (unsigned index = 0; index < 32U; ++index) {
            if (is_tensor_config(word, index, 7U) ||
                is_tensor_config(word, index, 0U)) {
                ++tensor_config_count;
                break;
            }
        }
        if (word == kRecoveryClear &&
            is_tensor_config(word, 30U, 0U)) {
            recovery_clears.push_back(offset);
        }
        if (word == kLaunchLo && offset + 8 <= firmware::kImageBytes &&
            read_word(offset + 4) == kLaunchHi) {
            launches.push_back(offset);
        }
    }

    if (configs.size() != NPU_SERVICE_COMMAND_WORDS) {
        return fail("image does not contain exactly 30 CONFIG instructions");
    }
    for (unsigned index = 0; index < configs.size(); ++index) {
        const std::size_t offset = configs[index].second;
        if (configs[index].first != index) {
            return fail("CONFIG indices are not the unique ordered range 0..29");
        }
        if (offset < 8 || offset + 4 >= firmware::kImageBytes ||
            read_word(offset - 8) != encode_ld(index) ||
            read_word(offset - 4) != kNop ||
            read_word(offset + 4) != kNop) {
            return fail("CONFIG no longer has the qualified LD/NOP/CONFIG/NOP shape");
        }
        if (index != 0 && offset != configs[index - 1].second + 16U) {
            return fail("CONFIG sequence is not a static 16-byte-per-word block");
        }
    }

    if (launches.size() != 1) {
        return fail("image does not contain exactly one fixed LO/HI launch pair");
    }
    const std::size_t launch = launches.front();
    if (((firmware::kLoadAddress + launch) & 7U) != 0U ||
        launch != configs.back().second + 8U) {
        return fail("LO/HI pair is not adjacent, aligned, and immediately after CONFIG");
    }
    if (recovery_clears.size() != 1 || tensor_config_count != 31U ||
        recovery_clears.front() <= launch) {
        return fail("image lacks one distinct post-launch CONFIG-30 rs1=x0 recovery command");
    }
    return true;
}

bool check_precise_trap_recovery() {
    std::vector<std::size_t> mtvec_writes;
    std::vector<std::size_t> mcause_reads;
    std::vector<std::size_t> mtval_reads;
    std::vector<std::size_t> mepc_reads;
    std::vector<std::size_t> mepc_writes;
    std::vector<std::size_t> guard_zeroes;
    std::vector<std::size_t> guard_sets;
    std::vector<std::size_t> guard_branches;
    std::vector<std::size_t> cause_branches;
    std::vector<std::size_t> version_branches;
    std::vector<std::size_t> fatal_tag_branches;
    std::vector<std::size_t> fatal_exit_branches;
    std::vector<std::size_t> recovery_clears;
    std::vector<std::size_t> fault_codes;
    std::vector<std::size_t> precise_fatal_codes;
    std::vector<std::size_t> untrusted_fatal_codes;
    std::vector<std::size_t> mrets;
    std::vector<std::size_t> fatal_spins;
    std::vector<std::size_t> failure_tval_stores;
    std::vector<std::size_t> failure_pc_stores;
    std::vector<std::size_t> failure_cause_stores;

    for (std::size_t offset = 0; offset + 4 <= firmware::kImageBytes;
         offset += 4) {
        const std::uint32_t word = read_word(offset);
        if (is_csr(word, 1U, 0U, 5U, 0x305U)) {
            mtvec_writes.push_back(offset);
        }
        if (is_csr(word, 2U, 5U, 0U, 0x342U)) {
            mcause_reads.push_back(offset);
        }
        if (is_csr(word, 2U, 6U, 0U, 0x343U)) {
            mtval_reads.push_back(offset);
        }
        if (is_csr(word, 2U, 7U, 0U, 0x341U)) {
            mepc_reads.push_back(offset);
        }
        if (is_csr(word, 1U, 0U, 5U, 0x341U)) {
            mepc_writes.push_back(offset);
        }
        if (word == kTrapGuardZero) {
            guard_zeroes.push_back(offset);
        }
        if (word == kTrapGuardSet) {
            guard_sets.push_back(offset);
        }
        if (is_bne(word, 24U, 0U)) {
            guard_branches.push_back(offset);
        }
        if (is_bne(word, 5U, 28U)) {
            cause_branches.push_back(offset);
        }
        if (is_bne(word, 28U, 29U)) {
            version_branches.push_back(offset);
        }
        if (is_blt(word, 25U, 0U)) {
            fatal_tag_branches.push_back(offset);
        }
        if (is_bne(word, 30U, 0U)) {
            fatal_exit_branches.push_back(offset);
        }
        if (word == kRecoveryClear && is_tensor_config(word, 30U, 0U)) {
            recovery_clears.push_back(offset);
        }
        if (word == kNpuFaultMailboxCode) {
            fault_codes.push_back(offset);
        }
        if (word == kNpuFatalPreciseCode) {
            precise_fatal_codes.push_back(offset);
        }
        if (word == kNpuFatalUntrustedCode) {
            untrusted_fatal_codes.push_back(offset);
        }
        if (word == kMret) {
            mrets.push_back(offset);
        }
        if (word == kFatalSpin) {
            fatal_spins.push_back(offset);
        }
        if (is_sd(word, 25U, 22U, NPU_SERVICE_CPL_FAULT_TVAL_OFFSET)) {
            failure_tval_stores.push_back(offset);
        }
        if (is_sd(word, 26U, 22U, NPU_SERVICE_CPL_FAULT_PC_OFFSET)) {
            failure_pc_stores.push_back(offset);
        }
        if (is_sd(word, 27U, 22U, NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET)) {
            failure_cause_stores.push_back(offset);
        }
    }

    if (mtvec_writes.size() != 1 || mcause_reads.size() != 1 ||
        mtval_reads.size() != 1 || mepc_reads.size() != 1 ||
        mepc_writes.size() != 1 || guard_zeroes.size() != 2 ||
        guard_sets.size() != 1 || guard_branches.size() != 1 ||
        cause_branches.size() != 1 || version_branches.size() != 1 ||
        fatal_tag_branches.size() != 1 || fatal_exit_branches.size() != 1 ||
        recovery_clears.size() != 1 ||
        fault_codes.size() != 1 || precise_fatal_codes.size() != 1 ||
        untrusted_fatal_codes.size() != 1 ||
        mrets.size() != 1 || fatal_spins.size() != 1 ||
        failure_tval_stores.size() != 1 ||
        failure_pc_stores.size() != 1 ||
        failure_cause_stores.size() != 1) {
        return fail("image lacks one complete guarded precise-fault recovery path");
    }

    std::size_t mtvec_target = 0;
    std::size_t mepc_target = 0;
    if (!pc_relative_address_before(mtvec_writes.front(), &mtvec_target) ||
        mtvec_target != guard_branches.front()) {
        return fail("mtvec is not initialized to the guarded trap entry");
    }
    if (!pc_relative_address_before(mepc_writes.front(), &mepc_target) ||
        read_word(mepc_target) != kPollReadyLoad ||
        mepc_target >= recovery_clears.front()) {
        return fail("recoverable fault does not redirect mepc to mailbox poll");
    }

    std::vector<std::size_t> fatal_edges = {
        guard_branches.front(),
        cause_branches.front(),
        version_branches.front(),
    };
    for (const std::size_t branch : fatal_edges) {
        std::size_t target = 0;
        if (!branch_target(branch, read_word(branch), &target) ||
            target != untrusted_fatal_codes.front()) {
            return fail("re-entry/cause/version gate does not converge on untrusted NPU_FATAL");
        }
    }
    const std::size_t untrusted = untrusted_fatal_codes.front();
    if (untrusted + 20U != fatal_spins.front() ||
        !is_sw(read_word(untrusted + 4U), 5U, 8U,
               NPU_SERVICE_MB_ERROR_OFFSET) ||
        read_word(untrusted + 8U) != kMailboxErrorState ||
        read_word(untrusted + 12U) != kFenceRwW ||
        !is_sw(read_word(untrusted + 16U), 5U, 8U,
               NPU_SERVICE_MB_STATE_OFFSET)) {
        return fail("untrusted traps can clear, write a command completion, or return");
    }
    std::size_t tagged_fatal_target = 0;
    if (!branch_target(fatal_tag_branches.front(),
                       read_word(fatal_tag_branches.front()),
                       &tagged_fatal_target) ||
        tagged_fatal_target != precise_fatal_codes.front()) {
        return fail("valid fatal tag does not enter the precise fatal completion path");
    }
    std::size_t fatal_exit_target = 0;
    if (!branch_target(fatal_exit_branches.front(),
                       read_word(fatal_exit_branches.front()),
                       &fatal_exit_target) ||
        fatal_exit_target != fatal_spins.front()) {
        return fail("precise fatal completion can escape without reset");
    }

    if (guard_branches.front() + 4U != guard_sets.front() ||
        read_word(cause_branches.front() - 4U) != kCause24 ||
        read_word(version_branches.front() - 12U) != kVersionShift ||
        read_word(version_branches.front() - 8U) != kVersionMask ||
        read_word(version_branches.front() - 4U) != kVersionOne) {
        return fail("trap gate no longer enforces mcause 24 plus mtval format v1");
    }

    if (!(guard_zeroes.front() < mtvec_writes.front() &&
          mtvec_writes.front() < guard_branches.front() &&
          guard_branches.front() < mcause_reads.front() &&
          mcause_reads.front() < mtval_reads.front() &&
          mtval_reads.front() < mepc_reads.front() &&
          mepc_reads.front() < fatal_tag_branches.front() &&
          fatal_tag_branches.front() < recovery_clears.front() &&
          recovery_clears.front() < fault_codes.front() &&
          fault_codes.front() < precise_fatal_codes.front() &&
          precise_fatal_codes.front() < failure_tval_stores.front() &&
          failure_tval_stores.front() < failure_pc_stores.front() &&
          failure_pc_stores.front() < failure_cause_stores.front() &&
          failure_cause_stores.front() < mepc_writes.front() &&
          mepc_writes.front() < guard_zeroes.back() &&
          guard_zeroes.back() < mrets.front() &&
          mrets.front() < untrusted_fatal_codes.front() &&
          untrusted_fatal_codes.front() < fatal_spins.front())) {
        return fail("trap recovery ordering can replay or publish before CONFIG-30 clear");
    }
    return true;
}

}  // namespace

int main() {
    if (!check_layout() || !check_generation_gate() ||
        !check_tensor_encoding() || !check_precise_trap_recovery()) {
        return 1;
    }
    std::printf(
        "[NPU-RV64-FIRMWARE][PASS] abi=1.3 image_bytes=%zu monotonic_generation=1 "
        "config=30 launch_pair=1 recovery_clear=1 guarded_trap=1 "
        "mailbox=0x%llx command_stride=%u max_commands=%u\n",
        firmware::kImageBytes,
        static_cast<unsigned long long>(firmware::kMailboxAddress),
        NPU_SERVICE_COMMAND_STRIDE,
        NPU_SERVICE_MAX_COMMANDS);
    return 0;
}
