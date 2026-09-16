#include "npu-compiled-bundle.h"
#include "npu-host-runtime.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

namespace {

// These are raw IEEE-754 payloads.  The host test performs no floating-point
// or tensor arithmetic; expected results are frozen bit-exact vectors.
constexpr std::array<std::uint32_t, 16> kInput0Generation1 = {
    0x3f800000U, 0xbf800000U, 0x40600000U, 0x41200000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
};

constexpr std::array<std::uint32_t, 16> kInput1Generation1 = {
    0x40000000U, 0x3f000000U, 0xbfa00000U, 0xc0a00000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
    0x40000000U, 0x40000000U, 0x40000000U, 0x40000000U,
};

constexpr std::array<std::uint32_t, 16> kOutputGeneration1 = {
    0x40800000U, 0x3f000002U, 0x40500001U, 0x40c00001U,
    0x40800001U, 0x40800001U, 0x40800002U, 0x40800002U,
    0x40800002U, 0x40800002U, 0x40800002U, 0x40800003U,
    0x40800003U, 0x40800003U, 0x40800004U, 0x40800004U,
};

constexpr std::array<std::uint32_t, 16> kZeroInput = {};

// With both generation-2 inputs at +0, command 1 produces +0 and command 2
// publishes the immutable raw bias image.  These are the exact weights.bin
// payloads, not values calculated by the host.
constexpr std::array<std::uint32_t, 16> kOutputGeneration2 = {
    0x3f800000U, 0x3f800001U, 0x3f800002U, 0x3f800003U,
    0x3f800004U, 0x3f800005U, 0x3f800006U, 0x3f800007U,
    0x3f800008U, 0x3f800009U, 0x3f80000aU, 0x3f80000bU,
    0x3f80000cU, 0x3f80000dU, 0x3f80000eU, 0x3f80000fU,
};

void store_le32(std::uint8_t * bytes, std::uint32_t value) {
    for (std::size_t index = 0U; index < 4U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

std::uint32_t load_le32(const std::uint8_t * bytes) {
    return static_cast<std::uint32_t>(bytes[0]) |
        (static_cast<std::uint32_t>(bytes[1]) << 8U) |
        (static_cast<std::uint32_t>(bytes[2]) << 16U) |
        (static_cast<std::uint32_t>(bytes[3]) << 24U);
}

template <std::size_t N>
bool store_words(
        std::vector<std::uint8_t> * destination,
        const std::array<std::uint32_t, N> & words) {
    if (destination == nullptr || destination->size() != N * 4U) {
        return false;
    }
    for (std::size_t index = 0U; index < N; ++index) {
        store_le32(destination->data() + index * 4U, words[index]);
    }
    return true;
}

template <std::size_t N>
bool check_words(
        const std::vector<std::uint8_t> & actual,
        const std::array<std::uint32_t, N> & expected,
        std::uint64_t generation) {
    if (actual.size() != N * 4U) return false;
    for (std::size_t index = 0U; index < N; ++index) {
        const std::uint32_t word = load_le32(actual.data() + index * 4U);
        if (word != expected[index]) {
            std::fprintf(
                stderr,
                "[NPU-HOST-RUNTIME-SYSTEM][MISMATCH] generation=%llu "
                "lane=%zu got=0x%08x expected=0x%08x\n",
                static_cast<unsigned long long>(generation), index,
                word, expected[index]);
            return false;
        }
    }
    return true;
}

bool check(bool condition, const char * message) {
    if (!condition) {
        std::fprintf(stderr,
                     "[NPU-HOST-RUNTIME-SYSTEM][FAIL] %s\n", message);
    }
    return condition;
}

const npu_compiled_buffer_info * find_buffer(
        const npu_compiled_bundle & bundle,
        const std::string & id) {
    const auto found = std::find_if(
        bundle.buffers.begin(), bundle.buffers.end(),
        [&](const npu_compiled_buffer_info & item) { return item.id == id; });
    return found == bundle.buffers.end() ? nullptr : &*found;
}

bool verify_bundle_shape(const npu_compiled_bundle & bundle) {
    const npu_compiled_buffer_info * input0 = find_buffer(bundle, "input0");
    const npu_compiled_buffer_info * input1 = find_buffer(bundle, "input1");
    const npu_compiled_buffer_info * output = find_buffer(bundle, "output");
    return bundle.graph_name == "tiny-two-vector-add" &&
        bundle.commands.size() == 2U && bundle.publications.size() == 1U &&
        bundle.publication_mode ==
            npu_compiled_publication_mode::bundle_atomic &&
        input0 != nullptr && input1 != nullptr && output != nullptr &&
        input0->kind == npu_compiled_buffer_kind::input &&
        input1->kind == npu_compiled_buffer_kind::input &&
        output->kind == npu_compiled_buffer_kind::output &&
        input0->size == 64U && input1->size == 64U && output->size == 64U &&
        bundle.publications[0].buffer_id == "output" &&
        bundle.publications[0].source_offset == 0U &&
        bundle.publications[0].target_offset == 0U &&
        bundle.publications[0].bytes == 64U;
}

bool verify_dispatch(
        const npu_host_runtime_result & result,
        std::uint64_t generation,
        std::size_t publication_entries) {
    return result.generation == generation && result.submitted &&
        result.published &&
        result.published_entries == publication_entries &&
        result.executor.generation == generation &&
        result.executor.completed == 2U &&
        result.executor.boot_count == 1U &&
        result.executor.mailbox_error == 0U &&
        result.executor.completion_status == 0U &&
        result.executor.delta.config_accepts ==
            2U * NPU_COMMAND_ABI_WORD_COUNT &&
        result.executor.delta.launch_accepts == 2U &&
        result.executor.delta.macro_terminals == 2U &&
        result.executor.delta.rtl_macro_commands == 2U &&
        result.executor.delta.rtl_f32_starts == 2U &&
        result.executor.delta.rtl_macro_completions == 2U &&
        result.executor.delta.rtl_error_clears == 0U &&
        result.executor.delta.traps == 0U &&
        result.executor.delta.exits == 0U;
}

bool verify_persistent_status(
        const npu_host_runtime_status & status,
        std::uint64_t expected_last_generation,
        std::uint64_t expected_successes) {
    return status.production_session && status.ready && !status.fatal &&
        status.next_generation == expected_last_generation + 1U &&
        status.submitted_generations == expected_successes &&
        status.successful_bundles == expected_successes &&
        status.publication_transactions == expected_successes &&
        status.session.booted && !status.session.fatal &&
        status.session.constructor_count == 1U &&
        status.session.reset_release_count == 1U &&
        status.session.boot_count == 1U &&
        status.session.last_generation == expected_last_generation &&
        status.session.mailbox_error == 0U;
}

}  // namespace

int main(int argc, char ** argv) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s BUNDLE_DIR\n", argv[0]);
        return 2;
    }

    npu_compiled_bundle bundle;
    npu_compiled_bundle_diagnostic diagnostic = {};
    if (!npu_compiled_bundle_load(argv[1], &bundle, &diagnostic)) {
        std::fprintf(
            stderr,
            "[NPU-HOST-RUNTIME-SYSTEM][LOAD-FAIL] error=%s path=%s "
            "detail=%s\n",
            npu_compiled_bundle_error_string(diagnostic.error),
            diagnostic.path.c_str(), diagnostic.detail.c_str());
        return 1;
    }
    if (!check(verify_bundle_shape(bundle),
               "unexpected tiny v2 bundle shape")) {
        return 1;
    }

    std::vector<std::uint8_t> input0(64U, 0U);
    std::vector<std::uint8_t> input1(64U, 0U);
    std::vector<std::uint8_t> output(64U, 0xa5U);
    if (!check(store_words(&input0, kInput0Generation1) &&
                   store_words(&input1, kInput1Generation1),
               "cannot initialize generation-1 raw inputs")) {
        return 1;
    }

    npu_host_runtime_request request;
    request.inputs = {
        {"input0", input0.data(), input0.size()},
        {"input1", input1.data(), input1.size()},
    };
    request.outputs = {
        {"output", output.data(), output.size()},
    };

    // This is the production constructor.  The test never sees or assembles a
    // npu_system_submission; the runtime owns its persistent SystemTop.
    npu_host_runtime runtime(argc, argv);
    if (!check(runtime.ready() && !runtime.fatal(),
               runtime.failure().c_str()) ||
        !check(verify_persistent_status(runtime.status(), 0U, 0U),
               "production session did not boot exactly once")) {
        return 1;
    }

    npu_host_runtime_result generation1 = {};
    if (!check(runtime.execute(bundle, request, &generation1),
               runtime.failure().c_str()) ||
        !check(verify_dispatch(
                   generation1, 1U, bundle.publications.size()),
               "generation 1 did not fully complete and publish") ||
        !check(check_words(output, kOutputGeneration1, 1U),
               "generation-1 raw output mismatch") ||
        !check(verify_persistent_status(runtime.status(), 1U, 1U),
               "generation-1 persistence/accounting mismatch")) {
        return 1;
    }

    if (!check(store_words(&input0, kZeroInput) &&
                   store_words(&input1, kZeroInput),
               "cannot initialize generation-2 raw inputs")) {
        return 1;
    }
    std::fill(output.begin(), output.end(), 0x5aU);

    npu_host_runtime_result generation2 = {};
    if (!check(runtime.execute(bundle, request, &generation2),
               runtime.failure().c_str()) ||
        !check(verify_dispatch(
                   generation2, 2U, bundle.publications.size()),
               "generation 2 did not fully complete and publish") ||
        !check(check_words(output, kOutputGeneration2, 2U),
               "generation-2 raw output mismatch") ||
        !check(verify_persistent_status(runtime.status(), 2U, 2U),
               "SystemTop was reconstructed or rebooted between generations")) {
        return 1;
    }

    const npu_host_runtime_status final = runtime.status();
    std::printf(
        "[NPU-HOST-RUNTIME-SYSTEM][PASS] bundle_id=%s generations=2 "
        "commands=4 publications=2 constructors=%llu reset_releases=%llu "
        "boot_count=%llu host_tensor_arithmetic=0\n",
        bundle.bundle_id.c_str(),
        static_cast<unsigned long long>(final.session.constructor_count),
        static_cast<unsigned long long>(final.session.reset_release_count),
        static_cast<unsigned long long>(final.session.boot_count));
    return 0;
}
