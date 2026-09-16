#include "npu-host-runtime.h"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <string>
#include <utility>
#include <vector>

namespace {

struct named_bytes {
    std::string id;
    std::vector<std::uint8_t> bytes;
};

bool check(bool condition, const char * message) {
    if (!condition) {
        std::fprintf(stderr, "[NPU-HOST-RUNTIME][FAIL] %s\n", message);
    }
    return condition;
}

const npu_compiled_buffer_info * find_info(
        const npu_compiled_bundle & bundle,
        const std::string & id,
        std::size_t * index = nullptr) {
    const auto found = std::find_if(
        bundle.buffers.begin(), bundle.buffers.end(),
        [&](const npu_compiled_buffer_info & item) { return item.id == id; });
    if (found == bundle.buffers.end()) return nullptr;
    if (index != nullptr) {
        *index = static_cast<std::size_t>(found - bundle.buffers.begin());
    }
    return &*found;
}

const npu_host_input_binding * find_input(
        const npu_host_runtime_request & request,
        const std::string & id) {
    const auto found = std::find_if(
        request.inputs.begin(), request.inputs.end(),
        [&](const npu_host_input_binding & item) {
            return item.buffer_id == id;
        });
    return found == request.inputs.end() ? nullptr : &*found;
}

std::uint8_t output_pattern(
        std::size_t buffer_index,
        std::size_t byte_index,
        std::uint8_t seed) {
    return static_cast<std::uint8_t>(
        seed + buffer_index * 29U + byte_index * 7U);
}

bool identities_match(
        const npu_system_command_identity & actual,
        const npu_compiled_command_identity & expected) {
    return actual.kernel_id == expected.kernel_id &&
        actual.command_flags == expected.command_flags &&
        actual.context_id == expected.context_id &&
        actual.sequence_id == expected.sequence_id &&
        actual.producer_id == expected.producer_id &&
        actual.user_tag == expected.user_tag &&
        actual.covered_node_count == expected.covered_node_count &&
        actual.node_hash_lo == expected.node_hash_lo &&
        actual.node_hash_hi == expected.node_hash_hi &&
        actual.local_profile == expected.local_profile;
}

bool workloads_match(
        const npu_system_f32_alu_contract & actual,
        const npu_compiled_f32_alu_workload & expected) {
    return actual.request_groups == expected.request_groups &&
        actual.response_groups == expected.response_groups &&
        actual.read_groups == expected.read_groups &&
        actual.write_groups == expected.write_groups &&
        actual.input_words == expected.input_words &&
        actual.output_words == expected.output_words &&
        actual.read_bytes == expected.read_bytes &&
        actual.write_bytes == expected.write_bytes &&
        actual.completion_vector_elements ==
            expected.completion_vector_elements &&
        actual.expected_starts == expected.expected_starts;
}

class fake_executor final : public npu_host_runtime_executor {
public:
    enum class mode {
        success,
        fail_second_command,
    };

    fake_executor(
            const npu_compiled_bundle & expected_bundle,
            const npu_host_runtime_request & external_request)
        : bundle_(expected_bundle), external_request_(external_request) {}

    void set_mode(mode value) { mode_ = value; }

    bool submit(
            const npu_system_submission & submission,
            npu_system_dispatch_result * result,
            std::string * failure) override {
        ++submit_count;
        observed_generations.push_back(submission.generation);
        if (!validate_submission(submission)) {
            if (failure != nullptr) {
                *failure = "fake executor observed an invalid private submission";
            }
            return false;
        }

        const std::uint8_t seed = mode_ == mode::success ? 0x31U : 0xc7U;
        for (std::size_t index = 0U; index < bundle_.buffers.size(); ++index) {
            if (bundle_.buffers[index].kind !=
                npu_compiled_buffer_kind::output) {
                continue;
            }
            std::vector<std::uint8_t> * target =
                submission.buffers[index].bytes;
            for (std::size_t byte = 0U; byte < target->size(); ++byte) {
                (*target)[byte] = output_pattern(index, byte, seed);
            }
        }

        if (result != nullptr) {
            *result = {};
            result->generation = submission.generation;
            result->completed = mode_ == mode::success ?
                static_cast<std::uint32_t>(submission.commands.size()) : 1U;
            result->mailbox_error = mode_ == mode::success ? 0U : 8U;
            result->completion_status = mode_ == mode::success ? 0U : 1U;
        }
        if (mode_ == mode::fail_second_command) {
            if (failure != nullptr) {
                *failure = "second command failed after private output writes";
            }
            return false;
        }
        if (failure != nullptr) failure->clear();
        return true;
    }

    std::size_t submit_count = 0U;
    bool saw_fully_private_arena = false;
    bool saw_exact_metadata_contracts = false;
    bool saw_checked_cycle_sum = false;
    std::vector<std::uint64_t> observed_generations;

private:
    bool validate_submission(const npu_system_submission & submission) {
        if (submission.generation == 0U ||
            submission.relocated_command_image == nullptr ||
            submission.relocated_command_image == &bundle_.command_template ||
            submission.buffers.size() != bundle_.buffers.size() ||
            submission.commands.size() != bundle_.commands.size()) {
            return false;
        }

        std::uint64_t cycle_sum = 0U;
        for (std::size_t index = 0U; index < bundle_.commands.size(); ++index) {
            const npu_compiled_command_info & expected = bundle_.commands[index];
            if (expected.cycle_upper_bound == 0U ||
                expected.cycle_upper_bound >
                    std::numeric_limits<std::uint64_t>::max() - cycle_sum) {
                return false;
            }
            cycle_sum += expected.cycle_upper_bound;
            const npu_system_command_contract & actual =
                submission.commands[index];
            if (actual.owner != npu_system_command_owner::f32_alu ||
                actual.expected_outcome !=
                    npu_system_expected_outcome::success ||
                actual.expected_npu_error_code != 0U ||
                !identities_match(actual.identity, expected.identity) ||
                !workloads_match(actual.f32_alu, expected.f32_alu)) {
                return false;
            }
        }
        saw_exact_metadata_contracts = true;
        saw_checked_cycle_sum = submission.max_cycles == cycle_sum;
        if (!saw_checked_cycle_sum) return false;

        std::uint64_t prior_end = 0U;
        for (std::size_t index = 0U; index < bundle_.buffers.size(); ++index) {
            const npu_compiled_buffer_info & info = bundle_.buffers[index];
            const npu_system_raw_buffer & actual = submission.buffers[index];
            if (actual.id != info.id || actual.permissions != info.permissions ||
                actual.bytes == nullptr || actual.bytes->size() != info.size ||
                actual.base == 0U ||
                (actual.base & (info.alignment - 1U)) != 0U ||
                (index != 0U && actual.base < prior_end) ||
                info.size > std::numeric_limits<std::uint64_t>::max() -
                                actual.base) {
                return false;
            }
            prior_end = actual.base + info.size;

            for (const npu_host_input_binding & external :
                 external_request_.inputs) {
                if (actual.bytes->data() == external.bytes) return false;
            }
            for (const npu_host_output_binding & external :
                 external_request_.outputs) {
                if (actual.bytes->data() == external.bytes) return false;
            }

            if (info.kind == npu_compiled_buffer_kind::input) {
                const npu_host_input_binding * input =
                    find_input(external_request_, info.id);
                if (input == nullptr ||
                    !std::equal(actual.bytes->begin(), actual.bytes->end(),
                                input->bytes)) {
                    return false;
                }
            } else if (info.kind == npu_compiled_buffer_kind::weight) {
                if (info.weights_offset > bundle_.weights.size() ||
                    info.size > bundle_.weights.size() -
                                    static_cast<std::size_t>(
                                        info.weights_offset) ||
                    !std::equal(
                        actual.bytes->begin(), actual.bytes->end(),
                        bundle_.weights.begin() +
                            static_cast<std::size_t>(info.weights_offset))) {
                    return false;
                }
            }
        }
        saw_fully_private_arena = true;
        return true;
    }

    const npu_compiled_bundle & bundle_;
    const npu_host_runtime_request & external_request_;
    mode mode_ = mode::success;
};

bool build_external_bindings(
        const npu_compiled_bundle & bundle,
        std::vector<named_bytes> * inputs,
        std::vector<named_bytes> * outputs,
        npu_host_runtime_request * request) {
    if (inputs == nullptr || outputs == nullptr || request == nullptr) {
        return false;
    }
    std::size_t input_count = 0U;
    std::size_t output_count = 0U;
    for (const npu_compiled_buffer_info & info : bundle.buffers) {
        input_count += info.kind == npu_compiled_buffer_kind::input ? 1U : 0U;
        output_count += info.kind == npu_compiled_buffer_kind::output ? 1U : 0U;
    }
    if (input_count == 0U || output_count == 0U) return false;
    inputs->clear();
    outputs->clear();
    inputs->reserve(input_count);
    outputs->reserve(output_count);
    for (std::size_t index = 0U; index < bundle.buffers.size(); ++index) {
        const npu_compiled_buffer_info & info = bundle.buffers[index];
        if (info.size > std::numeric_limits<std::size_t>::max()) return false;
        if (info.kind == npu_compiled_buffer_kind::input) {
            named_bytes value = {};
            value.id = info.id;
            value.bytes.resize(static_cast<std::size_t>(info.size));
            for (std::size_t byte = 0U; byte < value.bytes.size(); ++byte) {
                value.bytes[byte] = static_cast<std::uint8_t>(
                    0x11U + index * 13U + byte * 3U);
            }
            inputs->push_back(std::move(value));
        } else if (info.kind == npu_compiled_buffer_kind::output) {
            named_bytes value = {};
            value.id = info.id;
            value.bytes.assign(static_cast<std::size_t>(info.size), 0xa5U);
            outputs->push_back(std::move(value));
        }
    }
    request->inputs.clear();
    request->outputs.clear();
    for (const named_bytes & input : *inputs) {
        request->inputs.push_back(
            {input.id, input.bytes.data(), input.bytes.size()});
    }
    for (named_bytes & output : *outputs) {
        request->outputs.push_back(
            {output.id, output.bytes.data(), output.bytes.size()});
    }
    return true;
}

std::vector<std::vector<std::uint8_t>> snapshot(
        const std::vector<named_bytes> & buffers) {
    std::vector<std::vector<std::uint8_t>> result;
    result.reserve(buffers.size());
    for (const named_bytes & buffer : buffers) {
        result.push_back(buffer.bytes);
    }
    return result;
}

bool matches_snapshot(
        const std::vector<named_bytes> & buffers,
        const std::vector<std::vector<std::uint8_t>> & expected) {
    if (buffers.size() != expected.size()) return false;
    for (std::size_t index = 0U; index < buffers.size(); ++index) {
        if (buffers[index].bytes != expected[index]) return false;
    }
    return true;
}

bool verify_success_publication(
        const npu_compiled_bundle & bundle,
        const std::vector<std::vector<std::uint8_t>> & before,
        const std::vector<named_bytes> & outputs) {
    if (before.size() != outputs.size()) return false;
    std::vector<std::vector<std::uint8_t>> expected = before;
    for (const npu_compiled_publication_entry & entry : bundle.publications) {
        std::size_t buffer_index = 0U;
        if (find_info(bundle, entry.buffer_id, &buffer_index) == nullptr) {
            return false;
        }
        const auto output = std::find_if(
            outputs.begin(), outputs.end(),
            [&](const named_bytes & item) { return item.id == entry.buffer_id; });
        if (output == outputs.end()) return false;
        const std::size_t output_index =
            static_cast<std::size_t>(output - outputs.begin());
        if (entry.target_offset > expected[output_index].size() ||
            entry.bytes > expected[output_index].size() -
                              static_cast<std::size_t>(entry.target_offset)) {
            return false;
        }
        for (std::size_t byte = 0U;
             byte < static_cast<std::size_t>(entry.bytes); ++byte) {
            expected[output_index][
                static_cast<std::size_t>(entry.target_offset) + byte] =
                output_pattern(
                    buffer_index,
                    static_cast<std::size_t>(entry.source_offset) + byte,
                    0x31U);
        }
    }
    return matches_snapshot(outputs, expected);
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
            "[NPU-HOST-RUNTIME][LOAD-FAIL] error=%s path=%s detail=%s\n",
            npu_compiled_bundle_error_string(diagnostic.error),
            diagnostic.path.c_str(), diagnostic.detail.c_str());
        return 1;
    }
    if (!check(bundle.commands.size() >= 2U &&
                   !bundle.publications.empty(),
               "test bundle lacks two commands or publication entries")) {
        return 1;
    }

    std::vector<named_bytes> inputs;
    std::vector<named_bytes> outputs;
    npu_host_runtime_request request;
    if (!check(build_external_bindings(
                   bundle, &inputs, &outputs, &request),
               "cannot construct external raw bindings")) {
        return 1;
    }
    const auto input_before = snapshot(inputs);
    const auto output_poison = snapshot(outputs);

    fake_executor executor(bundle, request);
    npu_host_runtime runtime(executor);
    if (!check(runtime.ready() && !runtime.fatal(),
               "injected executor runtime is not ready")) {
        return 1;
    }

    npu_host_runtime_request missing_input = request;
    missing_input.inputs.pop_back();
    npu_host_runtime_result preflight_result = {};
    if (!check(!runtime.execute(bundle, missing_input, &preflight_result) &&
                   runtime.last_error() ==
                       npu_host_runtime_error::input_binding &&
                   executor.submit_count == 0U &&
                   !preflight_result.submitted &&
                   !preflight_result.published &&
                   runtime.status().next_generation == 1U &&
                   matches_snapshot(outputs, output_poison),
               "preflight failure submitted or changed external output")) {
        return 1;
    }

    // Parsed side tables are untrusted.  Revalidation must reconstruct these
    // fields from the three immutable byte vectors before contract generation.
    npu_compiled_bundle untrusted_view = bundle;
    untrusted_view.commands[0].identity.local_profile ^= 0xffffffffU;
    untrusted_view.commands[0].f32_alu.expected_starts ^= 1U;
    untrusted_view.commands[0].cycle_upper_bound = 0U;
    untrusted_view.publications.clear();

    npu_host_runtime_result success_result = {};
    executor.set_mode(fake_executor::mode::success);
    if (!check(runtime.execute(untrusted_view, request, &success_result),
               runtime.failure().c_str()) ||
        !check(success_result.generation == 1U &&
                   success_result.submitted && success_result.published &&
                   success_result.published_entries ==
                       bundle.publications.size() &&
                   executor.submit_count == 1U &&
                   executor.saw_fully_private_arena &&
                   executor.saw_exact_metadata_contracts &&
                   executor.saw_checked_cycle_sum &&
                   matches_snapshot(inputs, input_before) &&
                   verify_success_publication(
                       bundle, output_poison, outputs),
               "successful bundle was not published exactly once")) {
        return 1;
    }

    const auto published_output = snapshot(outputs);
    executor.set_mode(fake_executor::mode::fail_second_command);
    npu_host_runtime_result failed_result = {};
    if (!check(!runtime.execute(bundle, request, &failed_result) &&
                   runtime.last_error() ==
                       npu_host_runtime_error::executor_failure &&
                   failed_result.generation == 2U &&
                   failed_result.submitted && !failed_result.published &&
                   failed_result.published_entries == 0U &&
                   executor.submit_count == 2U &&
                   matches_snapshot(inputs, input_before) &&
                   matches_snapshot(outputs, published_output),
               "second-command failure leaked private output")) {
        return 1;
    }

    const npu_host_runtime_status final = runtime.status();
    if (!check(final.next_generation == 3U &&
                   final.submitted_generations == 2U &&
                   final.successful_bundles == 1U &&
                   final.publication_transactions == 1U &&
                   !final.production_session && final.ready && !final.fatal &&
                   executor.observed_generations ==
                       std::vector<std::uint64_t>({1U, 2U}),
               "automatic generation or publication accounting mismatch")) {
        return 1;
    }

    std::printf(
        "[NPU-HOST-RUNTIME][PASS] bundle_id=%s preflight_submit=0 "
        "private_arena=1 canonical_metadata=1 cycle_sum=1 "
        "generation1_publish=1 generation2_failure_publish=0 "
        "publish_transactions=1 external_failure_unchanged=1\n",
        bundle.bundle_id.c_str());
    return 0;
}
