#include "npu-host-runtime.h"

#include <algorithm>
#include <cstring>
#include <exception>
#include <limits>
#include <new>
#include <sstream>
#include <utility>

namespace {

constexpr std::uint64_t kArenaBase = 0x0000000100000000ULL;
constexpr std::uint32_t kReadPermission = 1U;
constexpr std::uint32_t kWritePermission = 2U;

bool is_power_of_two(std::uint64_t value) {
    return value != 0U && (value & (value - 1U)) == 0U;
}

bool checked_add(
        std::uint64_t left,
        std::uint64_t right,
        std::uint64_t * output) {
    if (output == nullptr ||
        right > std::numeric_limits<std::uint64_t>::max() - left) {
        return false;
    }
    *output = left + right;
    return true;
}

bool checked_align_up(
        std::uint64_t value,
        std::uint64_t alignment,
        std::uint64_t * output) {
    if (!is_power_of_two(alignment) || output == nullptr) return false;
    const std::uint64_t mask = alignment - 1U;
    if (value > std::numeric_limits<std::uint64_t>::max() - mask) {
        return false;
    }
    *output = (value + mask) & ~mask;
    return true;
}

bool checked_pointer_end(
        const std::uint8_t * bytes,
        std::size_t size,
        std::uintptr_t * begin,
        std::uintptr_t * end) {
    if (begin == nullptr || end == nullptr ||
        (size != 0U && bytes == nullptr)) {
        return false;
    }
    const std::uintptr_t address = reinterpret_cast<std::uintptr_t>(bytes);
    if (size > std::numeric_limits<std::uintptr_t>::max() - address) {
        return false;
    }
    *begin = address;
    *end = address + size;
    return true;
}

bool ranges_overlap(
        std::uintptr_t left_begin,
        std::uintptr_t left_end,
        std::uintptr_t right_begin,
        std::uintptr_t right_end) {
    return left_begin < right_end && right_begin < left_end;
}

}  // namespace

namespace {

class npu_host_system_session_executor final
    : public npu_host_runtime_executor {
public:
    explicit npu_host_system_session_executor(npu_system_session & session)
        : session_(session) {}

    bool submit(
            const npu_system_submission & submission,
            npu_system_dispatch_result * result,
            std::string * failure) override {
        const bool success = session_.dispatch(submission, result);
        if (failure != nullptr) {
            *failure = success ? std::string() : session_.failure();
        }
        return success;
    }

private:
    npu_system_session & session_;
};

}  // namespace

class npu_host_runtime::impl {
public:
    impl(int argc, char ** argv)
        : system_session_(
              std::make_unique<npu_system_session>(argc, argv)),
          system_executor_(
              std::make_unique<npu_host_system_session_executor>(
                  *system_session_)),
          executor_(system_executor_.get()) {
        if (!system_session_->ready()) {
            last_error_ = system_session_->fatal() ?
                npu_host_runtime_error::system_session_fatal :
                npu_host_runtime_error::system_session_not_ready;
            failure_ = system_session_->failure();
        }
    }

    explicit impl(npu_host_runtime_executor & executor)
        : executor_(&executor) {}

    bool execute(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request,
            npu_host_runtime_result * result) {
        if (result != nullptr) *result = {};
        last_error_ = npu_host_runtime_error::none;
        failure_.clear();

        try {
            if (fatal()) {
                return fail(npu_host_runtime_error::system_session_fatal,
                            system_session_->failure());
            }
            if (!ready()) {
                return fail(npu_host_runtime_error::system_session_not_ready,
                            system_session_ == nullptr ?
                                "host executor is unavailable" :
                                system_session_->failure());
            }

            // Treat only the immutable artifact bytes as provenance.  The
            // caller-visible parsed vectors are never trusted: re-parse,
            // re-hash and semantically validate them into a fresh canonical
            // bundle before consuming owner/workload/publication metadata.
            npu_compiled_bundle canonical;
            npu_compiled_bundle_diagnostic diagnostic = {};
            if (!npu_compiled_bundle_revalidate(
                    &bundle, &canonical, &diagnostic)) {
                std::ostringstream detail;
                detail << "bundle provenance revalidation failed: "
                       << npu_compiled_bundle_error_string(diagnostic.error)
                       << " path=" << diagnostic.path
                       << " detail=" << diagnostic.detail;
                return fail(npu_host_runtime_error::bundle_provenance,
                            detail.str());
            }
            return execute_checked(canonical, request, result);
        } catch (const std::bad_alloc &) {
            return fail(npu_host_runtime_error::allocation_failure,
                        "cannot allocate a private dispatch arena");
        } catch (const std::exception & exception) {
            return fail(npu_host_runtime_error::invalid_bundle,
                        std::string("host-runtime exception: ") +
                            exception.what());
        } catch (...) {
            return fail(npu_host_runtime_error::invalid_bundle,
                        "unknown host-runtime exception");
        }
    }

    npu_host_runtime_error last_error() const { return last_error_; }
    const std::string & failure() const { return failure_; }

    bool ready() const {
        return executor_ != nullptr &&
            (system_session_ == nullptr || system_session_->ready());
    }

    bool fatal() const {
        return system_session_ != nullptr && system_session_->fatal();
    }

    npu_host_runtime_status status() const {
        npu_host_runtime_status result = {};
        result.next_generation = generation_available_ ? next_generation_ : 0U;
        result.submitted_generations = submitted_generations_;
        result.successful_bundles = successful_bundles_;
        result.publication_transactions = publication_transactions_;
        result.production_session = system_session_ != nullptr;
        result.ready = ready();
        result.fatal = fatal();
        if (system_session_ != nullptr) {
            result.session = system_session_->status();
        }
        return result;
    }

private:
    struct arena_buffer {
        std::string id;
        npu_compiled_buffer_kind kind = npu_compiled_buffer_kind::input;
        std::uint64_t base = 0U;
        std::uint32_t permissions = 0U;
        std::vector<std::uint8_t> bytes;
    };

    struct external_range {
        std::string id;
        std::uintptr_t begin = 0U;
        std::uintptr_t end = 0U;
    };

    struct publication_copy {
        std::size_t arena_index = 0U;
        std::size_t output_index = 0U;
        std::size_t source_offset = 0U;
        std::size_t target_offset = 0U;
        std::size_t bytes = 0U;
    };

    struct interval {
        std::uint64_t begin = 0U;
        std::uint64_t end = 0U;
    };

    bool fail(npu_host_runtime_error error, const std::string & detail) {
        last_error_ = error;
        failure_ = detail;
        return false;
    }

    const npu_compiled_buffer_info * find_buffer_info(
            const npu_compiled_bundle & bundle,
            const std::string & id) const {
        const auto found = std::find_if(
            bundle.buffers.begin(), bundle.buffers.end(),
            [&](const npu_compiled_buffer_info & item) {
                return item.id == id;
            });
        return found == bundle.buffers.end() ? nullptr : &*found;
    }

    std::size_t find_arena_buffer(
            const std::vector<arena_buffer> & arena,
            const std::string & id) const {
        const auto found = std::find_if(
            arena.begin(), arena.end(),
            [&](const arena_buffer & item) { return item.id == id; });
        return found == arena.end() ? static_cast<std::size_t>(-1) :
            static_cast<std::size_t>(found - arena.begin());
    }

    std::size_t find_output(
            const npu_host_runtime_request & request,
            const std::string & id) const {
        const auto found = std::find_if(
            request.outputs.begin(), request.outputs.end(),
            [&](const npu_host_output_binding & item) {
                return item.buffer_id == id;
            });
        return found == request.outputs.end() ? static_cast<std::size_t>(-1) :
            static_cast<std::size_t>(found - request.outputs.begin());
    }

    const npu_host_input_binding * find_input(
            const npu_host_runtime_request & request,
            const std::string & id) const {
        const auto found = std::find_if(
            request.inputs.begin(), request.inputs.end(),
            [&](const npu_host_input_binding & item) {
                return item.buffer_id == id;
            });
        return found == request.inputs.end() ? nullptr : &*found;
    }

    bool validate_bundle_header(const npu_compiled_bundle & bundle) {
        if (bundle.buffers.empty() || bundle.commands.empty() ||
            bundle.command_template.empty() || bundle.metadata_json.empty()) {
            return fail(npu_host_runtime_error::invalid_bundle,
                        "loaded bundle is structurally empty");
        }
        if (bundle.runtime_service.major !=
                NPU_COMPILED_RUNTIME_SERVICE_ABI_MAJOR ||
            bundle.runtime_service.minor !=
                NPU_COMPILED_RUNTIME_SERVICE_ABI_MINOR) {
            return fail(npu_host_runtime_error::runtime_service_abi,
                        "bundle runtime service ABI is not 1.1");
        }
        if (bundle.publication_mode !=
            npu_compiled_publication_mode::bundle_atomic) {
            return fail(npu_host_runtime_error::publication_mode,
                        "only bundle_atomic publication is supported");
        }
        for (std::size_t index = 0U; index < bundle.buffers.size(); ++index) {
            const npu_compiled_buffer_info & info = bundle.buffers[index];
            if (info.id.empty() || info.size == 0U ||
                info.size > std::numeric_limits<std::size_t>::max() ||
                !is_power_of_two(info.alignment) || info.permissions == 0U) {
                return fail(npu_host_runtime_error::invalid_bundle,
                            "bundle contains an invalid buffer capability");
            }
            for (std::size_t previous = 0U; previous < index; ++previous) {
                if (bundle.buffers[previous].id == info.id) {
                    return fail(npu_host_runtime_error::invalid_bundle,
                                "bundle contains a duplicate BufferId");
                }
            }
        }
        return true;
    }

    bool validate_external_bindings(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request) {
        std::vector<external_range> ranges;
        ranges.reserve(request.inputs.size() + request.outputs.size());

        for (std::size_t index = 0U; index < request.inputs.size(); ++index) {
            const npu_host_input_binding & binding = request.inputs[index];
            const npu_compiled_buffer_info * info =
                find_buffer_info(bundle, binding.buffer_id);
            if (info == nullptr || info->kind != npu_compiled_buffer_kind::input ||
                binding.size != info->size ||
                (binding.size != 0U && binding.bytes == nullptr)) {
                return fail(npu_host_runtime_error::input_binding,
                            "input binding does not exactly match metadata");
            }
            for (std::size_t previous = 0U; previous < index; ++previous) {
                if (request.inputs[previous].buffer_id == binding.buffer_id) {
                    return fail(npu_host_runtime_error::input_binding,
                                "duplicate input binding");
                }
            }
            external_range range = {};
            range.id = binding.buffer_id;
            if (!checked_pointer_end(binding.bytes, binding.size,
                                     &range.begin, &range.end)) {
                return fail(npu_host_runtime_error::input_binding,
                            "input pointer range overflows uintptr_t");
            }
            ranges.push_back(std::move(range));
        }

        for (std::size_t index = 0U; index < request.outputs.size(); ++index) {
            const npu_host_output_binding & binding = request.outputs[index];
            const npu_compiled_buffer_info * info =
                find_buffer_info(bundle, binding.buffer_id);
            if (info == nullptr || info->kind != npu_compiled_buffer_kind::output ||
                binding.size != info->size ||
                (binding.size != 0U && binding.bytes == nullptr)) {
                return fail(npu_host_runtime_error::output_binding,
                            "output binding does not exactly match metadata");
            }
            for (std::size_t previous = 0U; previous < index; ++previous) {
                if (request.outputs[previous].buffer_id == binding.buffer_id) {
                    return fail(npu_host_runtime_error::output_binding,
                                "duplicate output binding");
                }
            }
            external_range range = {};
            range.id = binding.buffer_id;
            if (!checked_pointer_end(binding.bytes, binding.size,
                                     &range.begin, &range.end)) {
                return fail(npu_host_runtime_error::output_binding,
                            "output pointer range overflows uintptr_t");
            }
            ranges.push_back(std::move(range));
        }

        for (const npu_compiled_buffer_info & info : bundle.buffers) {
            if (info.kind == npu_compiled_buffer_kind::input &&
                find_input(request, info.id) == nullptr) {
                return fail(npu_host_runtime_error::input_binding,
                            "required input binding is missing");
            }
            if (info.kind == npu_compiled_buffer_kind::output &&
                find_output(request, info.id) == static_cast<std::size_t>(-1)) {
                return fail(npu_host_runtime_error::output_binding,
                            "required output binding is missing");
            }
        }

        for (std::size_t right = 0U; right < ranges.size(); ++right) {
            for (std::size_t left = 0U; left < right; ++left) {
                if (ranges_overlap(ranges[left].begin, ranges[left].end,
                                   ranges[right].begin, ranges[right].end)) {
                    return fail(npu_host_runtime_error::binding_overlap,
                                "external raw bindings overlap");
                }
            }
        }
        return true;
    }

    bool build_arena(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request,
            std::vector<arena_buffer> * arena,
            std::vector<npu_compiled_named_binding> * relocations) {
        if (arena == nullptr || relocations == nullptr) {
            return fail(npu_host_runtime_error::arena_range,
                        "null private-arena destination");
        }
        arena->clear();
        relocations->clear();
        arena->reserve(bundle.buffers.size());
        relocations->reserve(bundle.buffers.size());

        std::uint64_t cursor = kArenaBase;
        for (const npu_compiled_buffer_info & info : bundle.buffers) {
            std::uint64_t base = 0U;
            std::uint64_t end = 0U;
            if (!checked_align_up(cursor, info.alignment, &base)) {
                return fail(npu_host_runtime_error::arena_alignment,
                            "cannot align a private IOVA capability");
            }
            if (!checked_add(base, info.size, &end) || end <= base) {
                return fail(npu_host_runtime_error::arena_range,
                            "private IOVA capability overflows");
            }

            arena_buffer buffer = {};
            buffer.id = info.id;
            buffer.kind = info.kind;
            buffer.base = base;
            buffer.permissions = info.permissions;
            buffer.bytes.assign(static_cast<std::size_t>(info.size), 0U);

            if (info.kind == npu_compiled_buffer_kind::input) {
                const npu_host_input_binding * input =
                    find_input(request, info.id);
                if (input == nullptr) {
                    return fail(npu_host_runtime_error::input_binding,
                                "input disappeared during arena construction");
                }
                std::memcpy(buffer.bytes.data(), input->bytes, input->size);
            } else if (info.kind == npu_compiled_buffer_kind::weight) {
                std::uint64_t weight_end = 0U;
                if (!checked_add(info.weights_offset, info.size, &weight_end) ||
                    weight_end > bundle.weights.size()) {
                    return fail(npu_host_runtime_error::weight_range,
                                "weight buffer escapes immutable weights.bin");
                }
                std::copy_n(
                    bundle.weights.begin() +
                        static_cast<std::size_t>(info.weights_offset),
                    static_cast<std::size_t>(info.size),
                    buffer.bytes.begin());
            }

            arena->push_back(std::move(buffer));
            relocations->push_back(
                {info.id, base, info.size, info.permissions});
            cursor = end;
        }
        return true;
    }

    bool build_contracts(
            const npu_compiled_bundle & bundle,
            std::vector<npu_system_command_contract> * contracts,
            std::uint64_t * max_cycles) {
        if (contracts == nullptr || max_cycles == nullptr) {
            return fail(npu_host_runtime_error::invalid_bundle,
                        "null command-contract destination");
        }
        contracts->clear();
        contracts->reserve(bundle.commands.size());
        *max_cycles = 0U;
        for (const npu_compiled_command_info & source : bundle.commands) {
            if (source.owner != npu_compiled_command_owner::f32_alu) {
                return fail(npu_host_runtime_error::unsupported_owner,
                            "bundle requests an unsupported command owner");
            }
            if (source.cycle_upper_bound == 0U ||
                !checked_add(*max_cycles, source.cycle_upper_bound,
                             max_cycles)) {
                return fail(npu_host_runtime_error::command_cycle_bound,
                            "command cycle upper bounds are zero or overflow");
            }
            npu_system_command_contract contract = {};
            contract.owner = npu_system_command_owner::f32_alu;
            contract.expected_outcome = npu_system_expected_outcome::success;
            contract.expected_npu_error_code = 0U;
            contract.identity.kernel_id = source.identity.kernel_id;
            contract.identity.command_flags = source.identity.command_flags;
            contract.identity.context_id = source.identity.context_id;
            contract.identity.sequence_id = source.identity.sequence_id;
            contract.identity.producer_id = source.identity.producer_id;
            contract.identity.user_tag = source.identity.user_tag;
            contract.identity.covered_node_count =
                source.identity.covered_node_count;
            contract.identity.node_hash_lo = source.identity.node_hash_lo;
            contract.identity.node_hash_hi = source.identity.node_hash_hi;
            contract.identity.local_profile = source.identity.local_profile;
            contract.f32_alu.request_groups = source.f32_alu.request_groups;
            contract.f32_alu.response_groups = source.f32_alu.response_groups;
            contract.f32_alu.read_groups = source.f32_alu.read_groups;
            contract.f32_alu.write_groups = source.f32_alu.write_groups;
            contract.f32_alu.input_words = source.f32_alu.input_words;
            contract.f32_alu.output_words = source.f32_alu.output_words;
            contract.f32_alu.read_bytes = source.f32_alu.read_bytes;
            contract.f32_alu.write_bytes = source.f32_alu.write_bytes;
            contract.f32_alu.completion_vector_elements =
                source.f32_alu.completion_vector_elements;
            // This value is compiler-owned.  In particular, zero-cardinality
            // P17/P18 commands carry zero; never infer it from command count.
            contract.f32_alu.expected_starts =
                source.f32_alu.expected_starts;
            contracts->push_back(std::move(contract));
        }
        return true;
    }

    bool exact_partition(
            std::vector<interval> intervals,
            std::uint64_t size) const {
        std::sort(
            intervals.begin(), intervals.end(),
            [](const interval & left, const interval & right) {
                return left.begin < right.begin ||
                    (left.begin == right.begin && left.end < right.end);
            });
        std::uint64_t cursor = 0U;
        for (const interval & item : intervals) {
            if (item.begin != cursor || item.end <= item.begin) return false;
            cursor = item.end;
        }
        return cursor == size;
    }

    bool build_publication_plan(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request,
            const std::vector<arena_buffer> & arena,
            std::vector<publication_copy> * plan) {
        if (plan == nullptr) {
            return fail(npu_host_runtime_error::publication_entry,
                        "null publication-plan destination");
        }
        plan->clear();
        plan->reserve(bundle.publications.size());
        for (const npu_compiled_publication_entry & entry :
             bundle.publications) {
            const std::size_t arena_index =
                find_arena_buffer(arena, entry.buffer_id);
            const std::size_t output_index =
                find_output(request, entry.buffer_id);
            if (arena_index == static_cast<std::size_t>(-1) ||
                output_index == static_cast<std::size_t>(-1) ||
                arena[arena_index].kind != npu_compiled_buffer_kind::output ||
                entry.bytes == 0U ||
                entry.source_offset >
                    std::numeric_limits<std::size_t>::max() ||
                entry.target_offset >
                    std::numeric_limits<std::size_t>::max() ||
                entry.bytes > std::numeric_limits<std::size_t>::max()) {
                return fail(npu_host_runtime_error::publication_entry,
                            "invalid bundle_atomic publication entry");
            }
            std::uint64_t source_end = 0U;
            std::uint64_t target_end = 0U;
            if (!checked_add(entry.source_offset, entry.bytes, &source_end) ||
                !checked_add(entry.target_offset, entry.bytes, &target_end) ||
                source_end > arena[arena_index].bytes.size() ||
                target_end > request.outputs[output_index].size) {
                return fail(npu_host_runtime_error::publication_entry,
                            "publication entry escapes a raw output buffer");
            }
            plan->push_back({
                arena_index,
                output_index,
                static_cast<std::size_t>(entry.source_offset),
                static_cast<std::size_t>(entry.target_offset),
                static_cast<std::size_t>(entry.bytes),
            });
        }

        for (std::size_t output_index = 0U;
             output_index < request.outputs.size(); ++output_index) {
            std::vector<interval> sources;
            std::vector<interval> targets;
            for (const publication_copy & copy : *plan) {
                if (copy.output_index != output_index) continue;
                sources.push_back({
                    static_cast<std::uint64_t>(copy.source_offset),
                    static_cast<std::uint64_t>(copy.source_offset + copy.bytes),
                });
                targets.push_back({
                    static_cast<std::uint64_t>(copy.target_offset),
                    static_cast<std::uint64_t>(copy.target_offset + copy.bytes),
                });
            }
            const std::uint64_t output_size =
                request.outputs[output_index].size;
            if (!exact_partition(std::move(sources), output_size) ||
                !exact_partition(std::move(targets), output_size)) {
                return fail(npu_host_runtime_error::publication_entry,
                            "publication entries do not exactly partition output");
            }
        }
        return true;
    }

    void consume_generation() {
        ++submitted_generations_;
        if (next_generation_ == std::numeric_limits<std::uint64_t>::max()) {
            next_generation_ = 0U;
            generation_available_ = false;
        } else {
            ++next_generation_;
        }
    }

    bool execute_checked(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request,
            npu_host_runtime_result * result) {
        if (!generation_available_) {
            return fail(npu_host_runtime_error::generation_exhausted,
                        "automatic generation counter is exhausted");
        }
        if (!validate_bundle_header(bundle) ||
            !validate_external_bindings(bundle, request)) {
            return false;
        }

        std::vector<arena_buffer> arena;
        std::vector<npu_compiled_named_binding> relocation_bindings;
        if (!build_arena(bundle, request, &arena, &relocation_bindings)) {
            return false;
        }

        std::vector<publication_copy> publication_plan;
        if (!build_publication_plan(
                bundle, request, arena, &publication_plan)) {
            return false;
        }

        std::vector<npu_system_command_contract> contracts;
        std::uint64_t max_cycles = 0U;
        if (!build_contracts(bundle, &contracts, &max_cycles)) return false;

        std::vector<std::uint8_t> relocated_command_image;
        npu_compiled_bundle_diagnostic relocation_diagnostic = {};
        if (!npu_compiled_bundle_relocate(
                &bundle, relocation_bindings.data(),
                relocation_bindings.size(), &relocated_command_image,
                &relocation_diagnostic)) {
            std::ostringstream detail;
            detail << "bundle relocation failed: "
                   << npu_compiled_bundle_error_string(
                          relocation_diagnostic.error)
                   << " path=" << relocation_diagnostic.path
                   << " detail=" << relocation_diagnostic.detail;
            return fail(npu_host_runtime_error::relocation, detail.str());
        }

        npu_system_submission submission = {};
        submission.generation = next_generation_;
        submission.relocated_command_image = &relocated_command_image;
        submission.commands = std::move(contracts);
        submission.max_cycles = max_cycles;
        submission.buffers.reserve(arena.size());
        for (arena_buffer & buffer : arena) {
            submission.buffers.push_back({
                buffer.id, buffer.base, buffer.permissions, &buffer.bytes,
            });
        }

        if (result != nullptr) {
            result->generation = submission.generation;
            result->submitted = true;
        }
        npu_system_dispatch_result executor_result = {};
        std::string executor_failure;
        bool executor_success = false;
        try {
            executor_success = executor_->submit(
                submission, &executor_result, &executor_failure);
        } catch (const std::exception & exception) {
            executor_failure = std::string("executor threw: ") +
                exception.what();
        } catch (...) {
            executor_failure = "executor threw an unknown exception";
        }
        consume_generation();
        if (result != nullptr) result->executor = executor_result;

        // A production session's fatal state is authoritative even if a
        // defective adapter were ever to report success.  Re-check at the
        // commit point so fatal hardware state can never publish raw outputs.
        if (fatal()) {
            return fail(npu_host_runtime_error::system_session_fatal,
                        executor_failure.empty() ?
                            system_session_->failure() : executor_failure);
        }
        if (!executor_success) {
            if (executor_failure.empty()) {
                executor_failure = "executor rejected or failed the bundle";
            }
            return fail(npu_host_runtime_error::executor_failure,
                        executor_failure);
        }
        if (executor_result.generation != submission.generation ||
            executor_result.completed != submission.commands.size() ||
            executor_result.mailbox_error != 0U ||
            executor_result.completion_status != 0U) {
            return fail(npu_host_runtime_error::executor_protocol,
                        "executor success did not prove full-bundle completion");
        }

        // All potentially failing work, including exact partition validation,
        // completed before this point.  No executor can observe these external
        // pointers; publication is the sole commit point.
        for (const publication_copy & copy : publication_plan) {
            const arena_buffer & source = arena[copy.arena_index];
            const npu_host_output_binding & target =
                request.outputs[copy.output_index];
            std::memcpy(target.bytes + copy.target_offset,
                        source.bytes.data() + copy.source_offset,
                        copy.bytes);
        }
        ++successful_bundles_;
        ++publication_transactions_;
        if (result != nullptr) {
            result->published = true;
            result->published_entries = publication_plan.size();
        }
        return true;
    }

    std::unique_ptr<npu_system_session> system_session_;
    std::unique_ptr<npu_host_system_session_executor> system_executor_;
    npu_host_runtime_executor * executor_ = nullptr;
    npu_host_runtime_error last_error_ = npu_host_runtime_error::none;
    std::string failure_;
    std::uint64_t next_generation_ = 1U;
    std::uint64_t submitted_generations_ = 0U;
    std::uint64_t successful_bundles_ = 0U;
    std::uint64_t publication_transactions_ = 0U;
    bool generation_available_ = true;
};

npu_host_runtime::npu_host_runtime(int argc, char ** argv)
    : impl_(std::make_unique<impl>(argc, argv)) {}

npu_host_runtime::npu_host_runtime(npu_host_runtime_executor & executor)
    : impl_(std::make_unique<impl>(executor)) {}

npu_host_runtime::~npu_host_runtime() = default;

bool npu_host_runtime::execute(
        const npu_compiled_bundle & bundle,
        const npu_host_runtime_request & request,
        npu_host_runtime_result * result) {
    return impl_->execute(bundle, request, result);
}

bool npu_host_runtime::ready() const {
    return impl_->ready();
}

bool npu_host_runtime::fatal() const {
    return impl_->fatal();
}

npu_host_runtime_error npu_host_runtime::last_error() const {
    return impl_->last_error();
}

const std::string & npu_host_runtime::failure() const {
    return impl_->failure();
}

npu_host_runtime_status npu_host_runtime::status() const {
    return impl_->status();
}

const char * npu_host_runtime_error_string(npu_host_runtime_error error) {
    switch (error) {
        case npu_host_runtime_error::none: return "none";
        case npu_host_runtime_error::bundle_provenance:
            return "bundle provenance failure";
        case npu_host_runtime_error::invalid_bundle: return "invalid bundle";
        case npu_host_runtime_error::runtime_service_abi:
            return "runtime service ABI mismatch";
        case npu_host_runtime_error::publication_mode:
            return "unsupported publication mode";
        case npu_host_runtime_error::input_binding:
            return "invalid input binding";
        case npu_host_runtime_error::output_binding:
            return "invalid output binding";
        case npu_host_runtime_error::binding_overlap:
            return "overlapping external bindings";
        case npu_host_runtime_error::arena_alignment:
            return "private arena alignment failure";
        case npu_host_runtime_error::arena_range:
            return "private arena range failure";
        case npu_host_runtime_error::weight_range:
            return "weight range failure";
        case npu_host_runtime_error::publication_entry:
            return "invalid publication entry";
        case npu_host_runtime_error::unsupported_owner:
            return "unsupported command owner";
        case npu_host_runtime_error::command_cycle_bound:
            return "invalid command cycle upper bound";
        case npu_host_runtime_error::relocation: return "relocation failure";
        case npu_host_runtime_error::allocation_failure:
            return "allocation failure";
        case npu_host_runtime_error::generation_exhausted:
            return "generation exhausted";
        case npu_host_runtime_error::system_session_not_ready:
            return "system session not ready";
        case npu_host_runtime_error::system_session_fatal:
            return "system session fatal";
        case npu_host_runtime_error::executor_failure:
            return "executor failure";
        case npu_host_runtime_error::executor_protocol:
            return "executor protocol failure";
    }
    return "unknown host-runtime error";
}
