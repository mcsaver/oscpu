#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <dlfcn.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>

struct common_sampler;

namespace {

using accept_fn = void (*)(common_sampler *, int, bool);

[[noreturn]] void trace_fail(const char * message) {
    std::fprintf(stderr, "[QWEN-TOKEN-CAPTURE][FAIL] %s\n", message);
    std::_Exit(125);
}

accept_fn resolve_accept() {
    void * symbol = dlsym(
        RTLD_NEXT,
        "_Z21common_sampler_acceptP14common_samplerib");
    if (symbol == nullptr) {
        trace_fail("cannot resolve common_sampler_accept");
    }
    return reinterpret_cast<accept_fn>(symbol);
}

void append_token(const char * path, int token) {
    const int fd = open(path, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0600);
    if (fd < 0) {
        trace_fail("cannot open token trace");
    }

    char line[48];
    const int size = std::snprintf(line, sizeof(line), "%d\n", token);
    if (size <= 0 || size >= static_cast<int>(sizeof(line))) {
        close(fd);
        trace_fail("cannot format token trace");
    }

    int written = 0;
    while (written < size) {
        const ssize_t rc = write(fd, line + written, size - written);
        if (rc > 0) {
            written += static_cast<int>(rc);
            continue;
        }
        if (rc < 0 && errno == EINTR) {
            continue;
        }
        close(fd);
        trace_fail("cannot write token trace");
    }

    if (close(fd) != 0) {
        trace_fail("cannot close token trace");
    }
}

std::uint64_t monotonic_nanoseconds() {
    struct timespec value = {};
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0 ||
        value.tv_sec < 0 || value.tv_nsec < 0 ||
        value.tv_nsec >= 1000000000L) {
        trace_fail("cannot read monotonic clock");
    }
    return static_cast<std::uint64_t>(value.tv_sec) * 1000000000ULL +
           static_cast<std::uint64_t>(value.tv_nsec);
}

void append_timing(const char * path, const char * kind,
                   std::uint64_t nanoseconds) {
    const int fd = open(path, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0600);
    if (fd < 0) {
        trace_fail("cannot open timing trace");
    }

    char line[96];
    const int size = std::snprintf(
        line, sizeof(line), "%s=%llu\n", kind,
        static_cast<unsigned long long>(nanoseconds));
    if (size <= 0 || size >= static_cast<int>(sizeof(line))) {
        close(fd);
        trace_fail("cannot format timing trace");
    }

    int written = 0;
    while (written < size) {
        const ssize_t rc = write(fd, line + written, size - written);
        if (rc > 0) {
            written += static_cast<int>(rc);
            continue;
        }
        if (rc < 0 && errno == EINTR) {
            continue;
        }
        close(fd);
        trace_fail("cannot write timing trace");
    }
    if (close(fd) != 0) {
        trace_fail("cannot close timing trace");
    }
}

} // namespace

// LD_PRELOAD interposition records accepted prompt and generated token IDs.
// It does not inspect logits, tensor storage, or model arithmetic.
void common_sampler_accept(common_sampler * sampler, int token, bool generated) {
    static const accept_fn real_accept = resolve_accept();
    static bool prompt_start_recorded = false;
    real_accept(sampler, token, generated);

    const char * trace_path = std::getenv(
        generated ? "QWEN_TOKEN_TRACE_PATH" :
                    "QWEN_PROMPT_TOKEN_TRACE_PATH");
    if (trace_path != nullptr && trace_path[0] != '\0') {
        append_token(trace_path, token);
    }

    const char * timing_path = std::getenv("QWEN_TIMING_TRACE_PATH");
    if (timing_path != nullptr && timing_path[0] != '\0') {
        const std::uint64_t now = monotonic_nanoseconds();
        if (!generated && !prompt_start_recorded) {
            append_timing(timing_path, "prompt_start_ns", now);
            prompt_start_recorded = true;
        }
        if (generated) {
            append_timing(timing_path, "generated_ns", now);
        }
    }
}
