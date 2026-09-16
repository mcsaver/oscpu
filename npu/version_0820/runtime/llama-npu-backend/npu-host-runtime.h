#ifndef LLAMA_NPU_HOST_RUNTIME_H
#define LLAMA_NPU_HOST_RUNTIME_H

#include "npu-compiled-bundle.h"
#include "npu-system-session.h"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// Borrowed raw capabilities supplied by the backend for one synchronous
// invocation.  Inputs are copied into a private arena before submission.
// Outputs are never exposed to the executor and are changed only after the
// complete bundle has succeeded.
struct npu_host_input_binding {
    std::string buffer_id;
    const std::uint8_t * bytes = nullptr;
    std::size_t size = 0U;
};

struct npu_host_output_binding {
    std::string buffer_id;
    std::uint8_t * bytes = nullptr;
    std::size_t size = 0U;
};

struct npu_host_runtime_request {
    std::vector<npu_host_input_binding> inputs;
    std::vector<npu_host_output_binding> outputs;
};

// Trusted adapter seam between the atomic host layer and a persistent
// execution service.  It exists so the same host logic can be tested without
// constructing SystemTop.  Backend clients cannot use this interface to ask
// npu_host_runtime to execute an arbitrary image or hand-written contract:
// only execute(bundle, request) is public on the runtime itself.
class npu_host_runtime_executor {
public:
    virtual ~npu_host_runtime_executor() = default;

    virtual bool submit(
            const npu_system_submission & submission,
            npu_system_dispatch_result * result,
            std::string * failure) = 0;
};

enum class npu_host_runtime_error : std::uint32_t {
    none = 0U,
    bundle_provenance,
    invalid_bundle,
    runtime_service_abi,
    publication_mode,
    input_binding,
    output_binding,
    binding_overlap,
    arena_alignment,
    arena_range,
    weight_range,
    publication_entry,
    unsupported_owner,
    command_cycle_bound,
    relocation,
    allocation_failure,
    generation_exhausted,
    system_session_not_ready,
    system_session_fatal,
    executor_failure,
    executor_protocol,
};

struct npu_host_runtime_result {
    std::uint64_t generation = 0U;
    bool submitted = false;
    bool published = false;
    std::size_t published_entries = 0U;
    npu_system_dispatch_result executor = {};
};

struct npu_host_runtime_status {
    // Zero means UINT64_MAX was already submitted and the counter is
    // exhausted.  Preflight failures do not consume a generation; every call
    // that reaches the executor does, irrespective of its outcome.
    std::uint64_t next_generation = 1U;
    std::uint64_t submitted_generations = 0U;
    std::uint64_t successful_bundles = 0U;
    std::uint64_t publication_transactions = 0U;
    bool production_session = false;
    bool ready = false;
    bool fatal = false;
    npu_system_session_status session = {};
};

// Synchronous single-owner host runtime.  For each call it constructs a new
// checked, aligned private IOVA arena for every metadata buffer, relocates the
// immutable command template into that arena, translates compiler-owned v2
// command metadata into exact session contracts, and submits once.  Only a
// full successful bundle may perform its bundle_atomic publication entries.
class npu_host_runtime {
public:
    // Production path: owns exactly one persistent SystemTop session and its
    // adapter.  Boot/reset failures are observable through ready(), fatal(),
    // last_error(), failure(), and status() before the first execute().
    explicit npu_host_runtime(int argc = 0, char ** argv = nullptr);

    // Trusted test seam.  Production backend code must use the constructor
    // above and therefore never assembles npu_system_submission itself.
    explicit npu_host_runtime(npu_host_runtime_executor & executor);
    ~npu_host_runtime();

    npu_host_runtime(const npu_host_runtime &) = delete;
    npu_host_runtime & operator=(const npu_host_runtime &) = delete;

    bool execute(
            const npu_compiled_bundle & bundle,
            const npu_host_runtime_request & request,
            npu_host_runtime_result * result = nullptr);

    bool ready() const;
    bool fatal() const;
    npu_host_runtime_error last_error() const;
    const std::string & failure() const;
    npu_host_runtime_status status() const;

private:
    class impl;
    std::unique_ptr<impl> impl_;
};

const char * npu_host_runtime_error_string(npu_host_runtime_error error);

#endif
