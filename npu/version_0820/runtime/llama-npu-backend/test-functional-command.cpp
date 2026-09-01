#include "npu-functional-command-dpi.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <utility>
#include <vector>

namespace {

constexpr std::uint64_t kSrc0 = 0x10000000ULL;
constexpr std::uint64_t kSrc1 = 0x20000000ULL;
constexpr std::uint64_t kDst = 0x30000000ULL;

struct region {
    std::uint64_t base = 0;
    std::vector<std::uint8_t> * bytes = nullptr;
    bool readable = false;
    bool writable = false;
};

class test_context final : public npu_functional_command_capability_context {
public:
    std::array<region, 3> regions = {};

    bool checked_read(
            std::uint64_t address,
            void * destination,
            std::size_t bytes) override {
        region * selected = find(address, bytes, true, false);
        if (selected == nullptr || destination == nullptr) {
            return false;
        }
        std::memcpy(destination,
                    selected->bytes->data() + (address - selected->base),
                    bytes);
        return true;
    }

    bool checked_write(
            std::uint64_t address,
            const void * source,
            std::size_t bytes) override {
        region * selected = find(address, bytes, false, true);
        if (selected == nullptr || source == nullptr) {
            return false;
        }
        std::memcpy(selected->bytes->data() + (address - selected->base),
                    source, bytes);
        return true;
    }

private:
    region * find(
            std::uint64_t address,
            std::size_t bytes,
            bool read,
            bool write) {
        if (bytes == 0U) {
            return nullptr;
        }
        for (region & candidate : regions) {
            if ((read && !candidate.readable) ||
                (write && !candidate.writable) ||
                candidate.bytes == nullptr || address < candidate.base) {
                continue;
            }
            const std::uint64_t offset = address - candidate.base;
            if (offset <= candidate.bytes->size() &&
                bytes <= candidate.bytes->size() - offset) {
                return &candidate;
            }
        }
        return nullptr;
    }
};

void store32(std::vector<std::uint8_t> * bytes,
             std::size_t offset,
             std::uint32_t value) {
    std::memcpy(bytes->data() + offset, &value, sizeof(value));
}

std::uint32_t load32(const std::vector<std::uint8_t> & bytes,
                     std::size_t offset) {
    std::uint32_t value = 0;
    std::memcpy(&value, bytes.data() + offset, sizeof(value));
    return value;
}

void store64(std::vector<std::uint8_t> * bytes,
             std::size_t offset,
             std::uint64_t value) {
    std::memcpy(bytes->data() + offset, &value, sizeof(value));
}

npu_functional_command base_command(
        std::uint32_t kernel,
        std::uint64_t src0_bytes,
        std::uint64_t src1_bytes,
        std::uint64_t dst_bytes) {
    npu_functional_command command = {};
    command.abi_valid = true;
    command.windows_generation_valid = true;
    command.kernel_id = kernel;
    command.command_flags = 0x10U;
    command.context_id = 0x43414e01U;
    command.capability_epoch = 1U;
    command.node_count = 1U;
    command.sequence_id = 1U;
    command.producer_id = 2U;
    command.user_tag = 3U;
    command.node_hash_lo = 4U;
    command.node_hash_hi = 5U;
    command.src0_iova = kSrc0;
    command.src1_iova = src1_bytes == 0U ? 0U : kSrc1;
    command.dst_iova = kDst;
    command.dtype = 1U;
    command.src0_window_base = kSrc0;
    command.src0_window_size = src0_bytes;
    command.src0_window_perm = 1U;
    command.src1_window_base = src1_bytes == 0U ? 0U : kSrc1;
    command.src1_window_size = src1_bytes;
    command.src1_window_perm = src1_bytes == 0U ? 0U : 1U;
    command.dst_window_base = kDst;
    command.dst_window_size = dst_bytes;
    command.dst_window_perm = 2U;
    return command;
}

bool exact_ledger(
        const npu_functional_command_result & result,
        std::uint64_t read_words,
        std::uint64_t write_words,
        std::uint64_t q8_blocks,
        std::uint64_t q8_macs,
        std::uint64_t elements) {
    return result.success && result.error_code == 0U &&
           result.error_class == 0U && result.callback_errors == 0U &&
           result.read_words == read_words &&
           result.write_words == write_words &&
           result.read_bytes == read_words * 4U + q8_blocks * 34U &&
           result.write_bytes == write_words * 4U &&
           result.q8_blocks == q8_blocks &&
           result.q8_mac_count == q8_macs &&
           result.vector_elements == elements &&
           result.callback_read_bytes == result.read_bytes &&
           result.callback_write_bytes == result.write_bytes;
}

bool run_command(
        const npu_functional_command & command,
        std::vector<std::uint8_t> * src0,
        std::vector<std::uint8_t> * src1,
        std::vector<std::uint8_t> * dst,
        npu_functional_command_result * result) {
    test_context context;
    context.regions = {{
        {kSrc0, src0, true, false},
        {kSrc1, src1, src1 != nullptr, false},
        {kDst, dst, false, true},
    }};
    npu_functional_command_scope scope(&context);
    return scope.active() &&
           npu_functional_command_execute_cpp(&command, result);
}

bool test_vector_add() {
    std::vector<std::uint8_t> src0(64U, 0U);
    std::vector<std::uint8_t> src1(64U, 0U);
    std::vector<std::uint8_t> dst(64U, 0xa5U);
    for (std::size_t index = 0; index < 16U; ++index) {
        store32(&src0, index * 4U, 0x3f800000U);
        store32(&src1, index * 4U, 0x40000000U);
    }
    auto command = base_command(0x514e0010U, 64U, 64U, 64U);
    command.vector_op = 1U;
    command.element_count = 16U;
    command.outer_count = 1U;
    command.src0_stride = 64U;
    command.src1_stride = 64U;
    command.dst_stride = 64U;
    npu_functional_command_result result = {};
    if (!run_command(command, &src0, &src1, &dst, &result) ||
        !exact_ledger(result, 32U, 16U, 0U, 0U, 16U)) {
        return false;
    }
    for (std::size_t index = 0; index < 16U; ++index) {
        if (load32(dst, index * 4U) != 0x40400000U) {
            return false;
        }
    }
    return true;
}

bool test_q8_gemv() {
    std::vector<std::uint8_t> activation(128U, 0U);
    std::vector<std::uint8_t> weights(68U, 0U);
    std::vector<std::uint8_t> dst(8U, 0xa5U);
    for (std::size_t index = 0; index < 32U; ++index) {
        store32(&activation, index * 4U, 0x3f800000U);
        weights[2U + index] = 1U;
        weights[36U + index] = (index & 1U) == 0U ? 1U : 0xffU;
    }
    weights[0] = 0x00U;
    weights[1] = 0x3cU;
    weights[34] = 0x00U;
    weights[35] = 0x3cU;
    auto command = base_command(0x514e0002U, 128U, 68U, 8U);
    command.element_count = 32U;
    command.outer_count = 2U;
    command.src1_stride = 34U;
    command.dst_stride = 4U;
    npu_functional_command_result result = {};
    if (!run_command(command, &activation, &weights, &dst, &result) ||
        !exact_ledger(result, 32U, 2U, 2U, 64U, 2U)) {
        return false;
    }
    // Frozen non-zero b10507 oracle: all-one row followed by balanced signs.
    return load32(dst, 0U) == 0x41fffc00U &&
           load32(dst, 4U) == 0x00000000U;
}

bool test_q8_get_rows_and_oob() {
    std::vector<std::uint8_t> table(34U, 0U);
    std::vector<std::uint8_t> index(4U, 0U);
    std::vector<std::uint8_t> dst(128U, 0xa5U);
    table[0] = 0x00U;
    table[1] = 0x3cU;
    std::fill(table.begin() + 2, table.end(), 1U);
    auto command = base_command(0x514e0001U, 34U, 4U, 128U);
    command.element_count = 32U;
    command.outer_count = 1U;
    command.src0_stride = 34U;
    command.src1_stride = 4U;
    command.dst_stride = 128U;
    command.scalar0 = 1U;
    npu_functional_command_result result = {};
    if (!run_command(command, &table, &index, &dst, &result) ||
        !exact_ledger(result, 1U, 32U, 1U, 0U, 32U)) {
        return false;
    }
    for (std::size_t element = 0; element < 32U; ++element) {
        if (load32(dst, element * 4U) != 0x3f800000U) {
            return false;
        }
    }

    store32(&index, 0U, 1U);
    std::fill(dst.begin(), dst.end(), 0xa5U);
    test_context context;
    context.regions = {{
        {kSrc0, &table, true, false},
        {kSrc1, &index, true, false},
        {kDst, &dst, false, true},
    }};
    npu_functional_command_scope scope(&context);
    result = {};
    const bool returned = npu_functional_command_execute_cpp(
        &command, &result);
    return scope.active() && !returned && !result.success &&
           result.error_code == 16U && result.error_class == 5U &&
           result.read_words == 1U && result.read_bytes == 4U &&
           result.write_bytes == 0U &&
           result.callback_read_bytes == 4U &&
           std::all_of(dst.begin(), dst.end(),
                       [](std::uint8_t byte) { return byte == 0xa5U; });
}

bool test_f32_get_repeat() {
    std::vector<std::uint8_t> source(32U, 0U);
    std::vector<std::uint8_t> indices(8U, 0U);
    std::vector<std::uint8_t> gathered(32U, 0xa5U);
    for (std::size_t index = 0; index < 8U; ++index) {
        store32(&source, index * 4U,
                0x3f800000U + static_cast<std::uint32_t>(index));
    }
    store32(&indices, 0U, 1U);
    store32(&indices, 4U, 0U);
    auto get = base_command(0x514e0003U, 32U, 8U, 32U);
    get.element_count = 4U;
    get.outer_count = 2U;
    get.src0_stride = 16U;
    get.src1_stride = 4U;
    get.dst_stride = 16U;
    get.scalar0 = 2U;
    npu_functional_command_result result = {};
    if (!run_command(get, &source, &indices, &gathered, &result) ||
        !exact_ledger(result, 10U, 8U, 0U, 0U, 8U) ||
        std::memcmp(gathered.data(), source.data() + 16U, 16U) != 0 ||
        std::memcmp(gathered.data() + 16U, source.data(), 16U) != 0) {
        return false;
    }

    std::vector<std::uint8_t> repeated(96U, 0xa5U);
    auto repeat = base_command(0x514e0004U, 32U, 0U, 96U);
    repeat.element_count = 4U;
    repeat.outer_count = 2U;
    repeat.scalar0 = 3U;
    repeat.src0_stride = 16U;
    repeat.dst_stride = 16U;
    repeat.src2_stride = 48U;
    result = {};
    if (!run_command(repeat, &source, nullptr, &repeated, &result) ||
        !exact_ledger(result, 8U, 24U, 0U, 0U, 24U)) {
        return false;
    }
    for (std::size_t outer = 0; outer < 2U; ++outer) {
        for (std::size_t copy = 0; copy < 3U; ++copy) {
            if (std::memcmp(repeated.data() + outer * 48U + copy * 16U,
                            source.data() + outer * 16U, 16U) != 0) {
                return false;
            }
        }
    }
    return true;
}

bool test_f32_get_empty_profiles() {
    for (const std::uint64_t elements : {18432ULL, 262144ULL}) {
        std::vector<std::uint8_t> source;
        std::vector<std::uint8_t> indices;
        std::vector<std::uint8_t> destination;
        auto command = base_command(0x514e0003U, 0U, 0U, 0U);
        command.src1_iova = kSrc1;
        command.src1_window_base = kSrc1;
        command.src1_window_perm = 1U;
        command.element_count = elements;
        command.outer_count = 0U;
        command.src0_stride = elements * 4U;
        command.src1_stride = 4U;
        command.dst_stride = elements * 4U;
        npu_functional_command_result result = {};
        if (!run_command(
                command, &source, &indices, &destination, &result) ||
            !exact_ledger(result, 0U, 0U, 0U, 0U, 0U) ||
            result.callback_read_calls != 0U ||
            result.callback_write_calls != 0U) {
            return false;
        }
    }
    return true;
}

bool test_generic_mover_and_set_rows() {
    std::vector<std::uint8_t> source(8192U, 0U);
    std::vector<std::uint8_t> moved(8192U, 0xa5U);
    for (std::size_t index = 0; index < source.size(); ++index) {
        source[index] = static_cast<std::uint8_t>((index * 17U) & 0xffU);
    }
    auto mover = base_command(0x514e0007U, 8192U, 0U, 8192U);
    mover.vector_op = 35U;
    mover.vector_flags = 1U;
    mover.element_count = 2048U;
    mover.outer_count = 1U;
    mover.src0_stride = 1024U;
    mover.src1_stride = 0U;
    mover.dst_stride = 8192U;
    // Public CONT keeps the sentinel permission bit despite a zero window.
    mover.src1_window_perm = 1U;
    npu_functional_command_result result = {};
    if (!run_command(mover, &source, nullptr, &moved, &result) ||
        !exact_ledger(result, 2048U, 2048U, 0U, 0U, 2048U) ||
        moved != source) {
        return false;
    }

    std::vector<std::uint8_t> values(2048U, 0U);
    std::vector<std::uint8_t> index(8U, 0U);
    std::vector<std::uint8_t> destination(262144U, 0U);
    for (std::size_t element = 0; element < 512U; ++element) {
        store32(&values, element * 4U, 0x3f800000U);
    }
    constexpr std::uint32_t slot = 3U;
    store64(&index, 0U, slot);
    auto set_rows = base_command(
        0x514e0008U, values.size(), index.size(), destination.size());
    set_rows.vector_op = 42U;
    set_rows.vector_flags = 8U;
    set_rows.src2_iova = kDst;
    set_rows.element_count = 512U;
    set_rows.outer_count = 256U;
    set_rows.src0_stride = 2048U;
    set_rows.src1_stride = 8U;
    set_rows.src2_stride = 1024U;
    set_rows.dst_stride = 1024U;
    set_rows.scalar0 = 256U;
    set_rows.scalar1 = slot;
    result = {};
    if (!run_command(
            set_rows, &values, &index, &destination, &result) ||
        !exact_ledger(result, 514U, 256U, 0U, 0U, 512U)) {
        return false;
    }
    const std::size_t start = slot * 1024U;
    for (std::size_t element = 0; element < 512U; ++element) {
        std::uint16_t value = 0U;
        std::memcpy(&value, destination.data() + start + element * 2U,
                    sizeof(value));
        if (value != 0x3c00U) {
            return false;
        }
    }
    return true;
}

bool test_fail_closed_scope_and_nonfinite() {
    std::vector<std::uint8_t> src0(64U, 0U);
    std::vector<std::uint8_t> src1(64U, 0U);
    std::vector<std::uint8_t> dst(64U, 0xa5U);
    auto command = base_command(0x514e0010U, 64U, 64U, 64U);
    command.vector_op = 1U;
    command.element_count = 16U;
    command.outer_count = 1U;
    command.src0_stride = 64U;
    command.src1_stride = 64U;
    command.dst_stride = 64U;
    npu_functional_command_result result = {};
    if (npu_functional_command_execute_cpp(&command, &result) ||
        result.callback_errors != 1U || result.error_code != 16U ||
        result.error_class != 5U) {
        return false;
    }
    store32(&src0, 0U, 0x7f800000U);
    test_context context;
    context.regions = {{
        {kSrc0, &src0, true, false},
        {kSrc1, &src1, true, false},
        {kDst, &dst, false, true},
    }};
    npu_functional_command_scope scope(&context);
    result = {};
    const bool returned = npu_functional_command_execute_cpp(
        &command, &result);
    return scope.active() && !returned && !result.success &&
           result.error_code == 18U && result.error_class == 11U &&
           result.callback_write_bytes == 0U &&
           std::all_of(dst.begin(), dst.end(),
                       [](std::uint8_t byte) { return byte == 0xa5U; });
}

} // namespace

int main() {
    const std::array<std::pair<const char *, bool (*)()>, 8> tests = {{
        {"vector_add", test_vector_add},
        {"q8_gemv_nonzero", test_q8_gemv},
        {"q8_get_rows_oob", test_q8_get_rows_and_oob},
        {"f32_get_repeat", test_f32_get_repeat},
        {"f32_get_empty_profiles", test_f32_get_empty_profiles},
        {"generic_mover_set_rows", test_generic_mover_and_set_rows},
        {"fail_closed", test_fail_closed_scope_and_nonfinite},
        {"repeat_determinism", test_f32_get_repeat},
    }};
    std::uint32_t passed = 0U;
    for (const auto & test : tests) {
        const bool ok = test.second();
        std::printf("[NPU-FUNCTIONAL-UNIT][%s] case=%s\n",
                    ok ? "PASS" : "FAIL", test.first);
        passed += ok ? 1U : 0U;
    }
    std::printf(
        "[NPU-FUNCTIONAL-UNIT][%s] cases=%u/%zu host_transport_arithmetic=0\n",
        passed == tests.size() ? "PASS" : "FAIL", passed, tests.size());
    return passed == tests.size() ? 0 : 1;
}
