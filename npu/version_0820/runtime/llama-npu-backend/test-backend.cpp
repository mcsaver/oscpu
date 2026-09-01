#include "ggml-backend.h"
#include "ggml.h"
#include "npu-audit-api.h"
#include "qwen-f32-alu-manifest.generated.h"
#include "qwen-q8-gemv-manifest.generated.h"
#include "qwen-sampler-argmax-profile.generated.h"

#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <set>
#include <utility>
#include <vector>

namespace {

int checks = 0;
const char * check_phase = "NPU-BACKEND-ABI";

constexpr std::array<std::uint32_t, 16> kF32Input0 = {
    0x00000000U, 0x3f800000U, 0x40000000U, 0x40400000U,
    0x40800000U, 0x40a00000U, 0x40c00000U, 0x40e00000U,
    0xbf800000U, 0xc0000000U, 0xc0400000U, 0xc0800000U,
    0x41000000U, 0x41800000U, 0x42000000U, 0x42800000U,
};
constexpr std::array<std::uint32_t, 16> kF32Input1 = {
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
    0x3f800000U, 0x3f800000U, 0x3f800000U, 0x3f800000U,
};
constexpr std::array<std::uint32_t, 16> kF32Expected = {
    0x3f800000U, 0x40000000U, 0x40400000U, 0x40800000U,
    0x40a00000U, 0x40c00000U, 0x40e00000U, 0x41000000U,
    0x00000000U, 0xbf800000U, 0xc0000000U, 0xc0400000U,
    0x41100000U, 0x41880000U, 0x42040000U, 0x42820000U,
};

struct test_tensor_descriptor {
    std::array<std::int64_t, 4> ne;
    std::array<std::size_t, 4> nb;
    std::size_t view_off;
    bool view_present;
};

struct test_profile {
    std::uint32_t profile_id;
    enum ggml_op op;
    std::uint32_t scalar0;
    bool src1_present;
    test_tensor_descriptor dst;
    test_tensor_descriptor src0;
    test_tensor_descriptor src1;
    std::uint64_t total_elements;
    std::uint64_t expected_read_bytes;
    std::uint64_t expected_write_bytes;
    std::uint64_t cycle_upper_bound;
};

constexpr test_tensor_descriptor test_tensor(
        std::array<std::int64_t, 4> ne,
        std::array<std::size_t, 4> nb,
        std::size_t view_off = 0,
        bool view_present = false) {
    return {ne, nb, view_off, view_present};
}

constexpr test_profile test_row(
        std::uint32_t profile_id,
        enum ggml_op op,
        std::uint32_t scalar0,
        bool src1_present,
        test_tensor_descriptor dst,
        test_tensor_descriptor src0,
        test_tensor_descriptor src1 = {}) {
    const std::uint64_t total =
        static_cast<std::uint64_t>(dst.ne[0]) * dst.ne[1] *
        dst.ne[2] * dst.ne[3];
    return {
        profile_id, op, scalar0, src1_present, dst, src0, src1, total,
        (src1_present ? 8ULL : 4ULL) * total,
        4ULL * total,
        32ULL + (src1_present ? 565ULL : 548ULL) * total,
    };
}

constexpr auto kTestT16 = test_tensor(
    {16,1,1,1}, {4,64,64,64});
constexpr auto kTestT1024 = test_tensor(
    {1024,1,1,1}, {4,4096,4096,4096});
constexpr auto kTestT128x128x16 = test_tensor(
    {128,128,16,1}, {4,512,65536,1048576});
constexpr auto kTestT128x1x16 = test_tensor(
    {128,1,16,1}, {4,512,512,8192});
constexpr auto kTestT128x16 = test_tensor(
    {128,16,1,1}, {4,512,8192,8192});

constexpr std::array<test_profile, 19> kTestProfiles = {{
    test_row(0, GGML_OP_ADD, 0, true, kTestT16,
        test_tensor({16,1,1,1},{4,64,64,64},0,true), kTestT16),
    test_row(1, GGML_OP_ADD, 0, true, kTestT1024,
        kTestT1024, kTestT1024),
    test_row(2, GGML_OP_ADD, 0, true, kTestT1024,
        test_tensor({1024,1,1,1},{4,4096,4096,4096},0,true), kTestT1024),
    test_row(3, GGML_OP_ADD, 0, true, kTestT128x128x16,
        kTestT128x128x16, kTestT128x128x16),
    test_row(4, GGML_OP_MUL, 0, true, kTestT16, kTestT16, kTestT16),
    test_row(5, GGML_OP_MUL, 0, true, kTestT1024,
        kTestT1024, kTestT1024),
    test_row(6, GGML_OP_MUL, 0, true, kTestT128x128x16,
        kTestT128x128x16,
        test_tensor({128,1,16,1},{4,8192,512,8192},0,true)),
    test_row(7, GGML_OP_MUL, 0, true, kTestT128x1x16,
        kTestT128x1x16,
        test_tensor({1,1,16,1},{4,4,4,64},0,true)),
    test_row(8, GGML_OP_MUL, 0, true, kTestT128x128x16,
        kTestT128x128x16,
        test_tensor({1,128,16,1},{512,4,512,8192},0,true)),
    test_row(9, GGML_OP_MUL, 0, true, kTestT128x128x16,
        test_tensor({128,128,16,1},{4,512,65536,1048576},0,true),
        test_tensor({1,1,16,1},{4,4,4,64})),
    test_row(10, GGML_OP_MUL, 0, true, kTestT128x16,
        kTestT128x16, test_tensor({128,1,1,1},{4,512,512,512})),
    test_row(11, GGML_OP_MUL, 0, true, kTestT128x16,
        kTestT128x16, kTestT128x16),
    test_row(12, GGML_OP_MUL, 0, true,
        test_tensor({2048,1,1,1},{4,8192,8192,8192}),
        test_tensor({2048,1,1,1},{4,8192,8192,8192}),
        test_tensor({2048,1,1,1},{4,8192,8192,8192})),
    test_row(13, GGML_OP_MUL, 0, true,
        test_tensor({256,2,1,1},{4,1024,2048,2048}),
        test_tensor({256,2,1,1},{4,1024,2048,2048}),
        test_tensor({256,1,1,1},{4,1024,1024,1024})),
    test_row(14, GGML_OP_MUL, 0, true,
        test_tensor({256,8,1,1},{4,1024,8192,8192}),
        test_tensor({256,8,1,1},{4,1024,8192,8192}),
        test_tensor({256,1,1,1},{4,1024,1024,1024})),
    test_row(15, GGML_OP_SUB, 0, true, kTestT128x1x16,
        test_tensor({128,1,16,1},{4,24576,512,24576},16384,true),
        test_tensor({128,1,16,1},{4,4,512,8192},0,true)),
    test_row(16, GGML_OP_SCALE, 0x3db504f3U, false,
        kTestT128x16, kTestT128x16),
    test_row(17, GGML_OP_SCALE, 0, false,
        test_tensor({18432,1,1,1},{4,73728,73728,73728},0,true),
        test_tensor({18432,1,1,1},{4,73728,73728,73728},0,true)),
    test_row(18, GGML_OP_SCALE, 0, false,
        test_tensor({262144,1,1,1},{4,1048576,1048576,1048576},0,true),
        test_tensor({262144,1,1,1},{4,1048576,1048576,1048576},0,true)),
}};

bool checked_add(std::uint64_t lhs, std::uint64_t rhs,
                 std::uint64_t * result) {
    if (result == nullptr ||
        rhs > std::numeric_limits<std::uint64_t>::max() - lhs) {
        return false;
    }
    *result = lhs + rhs;
    return true;
}

bool checked_mul(std::uint64_t lhs, std::uint64_t rhs,
                 std::uint64_t * result) {
    if (result == nullptr ||
        (lhs != 0 && rhs > std::numeric_limits<std::uint64_t>::max() / lhs)) {
        return false;
    }
    *result = lhs * rhs;
    return true;
}

bool test_source_span(
        const test_tensor_descriptor & descriptor,
        std::uint64_t * beat_lo,
        std::uint64_t * beat_hi) {
    if (beat_lo == nullptr || beat_hi == nullptr) {
        return false;
    }
    std::uint64_t logical_hi = descriptor.view_off;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        if (descriptor.ne[dimension] <= 0) {
            return false;
        }
        std::uint64_t term = 0;
        if (!checked_mul(
                static_cast<std::uint64_t>(descriptor.ne[dimension] - 1),
                descriptor.nb[dimension], &term) ||
            !checked_add(logical_hi, term, &logical_hi)) {
            return false;
        }
    }
    std::uint64_t rounded = 0;
    if (!checked_add(logical_hi, 4, &logical_hi) ||
        !checked_add(logical_hi, 7, &rounded)) {
        return false;
    }
    *beat_lo = descriptor.view_off & ~std::uint64_t{7};
    *beat_hi = rounded & ~std::uint64_t{7};
    return *beat_lo < *beat_hi;
}

bool check(bool condition, const char * message) {
    ++checks;
    if (!condition) {
        std::fprintf(stderr, "[%s][FAIL] check=%d message=%s\n",
                     check_phase, checks, message);
        return false;
    }
    return true;
}

bool check_exact_audit(const ggml_npu_audit_snapshot_v2 & snapshot) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "v2 audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1, "required_seen mismatch");
    passed &= check(snapshot.assigned_to_npu == 1, "assigned mismatch");
    passed &= check(snapshot.required_enqueued == 1, "enqueued mismatch");
    passed &= check(snapshot.required_successfully_covered == 1,
                    "success coverage mismatch");
    passed &= check(snapshot.executed_by_verilator == 1,
                    "Verilator execution mismatch");
    passed &= check(snapshot.commands_accepted == 1,
                    "commands_accepted mismatch");
    passed &= check(snapshot.commands_terminal_success == 1,
                    "terminal success mismatch");
    passed &= check(snapshot.commands_terminal_failure == 0,
                    "unexpected terminal failure");
    passed &= check(snapshot.unsupported_required == 0,
                    "unexpected unsupported required");
    passed &= check(snapshot.cpu_fallback_attempts == 0,
                    "CPU fallback attempt detected");
    passed &= check(snapshot.host_tensor_ops == 0,
                    "host tensor operation detected");
    passed &= check(snapshot.coverage_missing == 0 &&
                    snapshot.coverage_duplicate == 0 &&
                    snapshot.coverage_hash_mismatch == 0,
                    "coverage closure mismatch");
    passed &= check(snapshot.completion_identity_mismatch == 0,
                    "completion identity mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                    snapshot.gmem_errors == 0 &&
                    snapshot.timeout_errors == 0,
                    "RTL terminal counters nonzero");
    passed &= check(snapshot.rtl_cycles > 0, "RTL cycles were zero");
    passed &= check(snapshot.gmem_read_bytes == 0,
                    "GMEM read byte mismatch");
    passed &= check(snapshot.gmem_write_bytes == 0,
                    "GMEM write byte mismatch");
    passed &= check(snapshot.vector_elements == 16,
                    "vector element mismatch");
    return passed;
}

bool check_exact_q8_audit(const ggml_npu_audit_snapshot_v2 & snapshot) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "Q8 v2 audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                    snapshot.assigned_to_npu == 1,
                    "Q8 required/assigned mismatch");
    passed &= check(snapshot.required_enqueued == 1 &&
                    snapshot.required_successfully_covered == 1 &&
                    snapshot.executed_by_verilator == 1,
                    "Q8 exact coverage ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                    snapshot.commands_terminal_success == 1 &&
                    snapshot.commands_terminal_failure == 0,
                    "Q8 terminal ledger mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                    snapshot.cpu_fallback_attempts == 0 &&
                    snapshot.host_tensor_ops == 0,
                    "Q8 fallback/host/unsupported counter nonzero");
    passed &= check(snapshot.coverage_missing == 0 &&
                    snapshot.coverage_duplicate == 0 &&
                    snapshot.coverage_hash_mismatch == 0 &&
                    snapshot.completion_identity_mismatch == 0,
                    "Q8 canonical completion ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                    snapshot.gmem_errors == 0 &&
                    snapshot.timeout_errors == 0,
                    "Q8 RTL terminal counters nonzero");
    passed &= check(snapshot.rtl_cycles > 0, "Q8 RTL cycles were zero");
    passed &= check(snapshot.gmem_read_bytes == 1296,
                    "Q8 pure-RTL real-GMEM read byte mismatch");
    passed &= check(snapshot.gmem_write_bytes == 4096,
                    "Q8 raw F32 write byte mismatch");
    passed &= check(snapshot.vector_elements == 1024,
                    "Q8 output element mismatch");
    return passed;
}

bool check_exact_q8_gemv_audit(
        const ggml_npu_audit_snapshot_v2 & snapshot) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "Q8 GEMV v2 audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                    snapshot.assigned_to_npu == 1 &&
                    snapshot.required_enqueued == 1 &&
                    snapshot.required_successfully_covered == 1 &&
                    snapshot.executed_by_verilator == 1,
                    "Q8 GEMV required completion ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                    snapshot.commands_terminal_success == 1 &&
                    snapshot.commands_terminal_failure == 0,
                    "Q8 GEMV terminal ledger mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                    snapshot.cpu_fallback_attempts == 0 &&
                    snapshot.host_tensor_ops == 0,
                    "Q8 GEMV fallback/host/unsupported counter nonzero");
    passed &= check(snapshot.coverage_missing == 0 &&
                    snapshot.coverage_duplicate == 0 &&
                    snapshot.coverage_hash_mismatch == 0 &&
                    snapshot.completion_identity_mismatch == 0,
                    "Q8 GEMV canonical identity ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                    snapshot.gmem_errors == 0 &&
                    snapshot.timeout_errors == 0,
                    "Q8 GEMV RTL terminal counters nonzero");
    passed &= check(snapshot.rtl_cycles > 0,
                    "Q8 GEMV RTL cycles were zero");
    passed &= check(snapshot.gmem_read_bytes == 4104,
                    "Q8 GEMV aligned activation GMEM read byte mismatch");
    passed &= check(snapshot.gmem_write_bytes == 64,
                    "Q8 GEMV raw F32 write byte mismatch");
    passed &= check(snapshot.vector_elements == 16,
                    "Q8 GEMV output element mismatch");
    return passed;
}

bool check_exact_q8_gemv_empty_audit(
        const ggml_npu_audit_snapshot_v2 & snapshot) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "empty Q8 GEMV v2 audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                    snapshot.assigned_to_npu == 1 &&
                    snapshot.required_enqueued == 1 &&
                    snapshot.required_successfully_covered == 1 &&
                    snapshot.executed_by_verilator == 1,
                    "empty Q8 GEMV required completion ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                    snapshot.commands_terminal_success == 1 &&
                    snapshot.commands_terminal_failure == 0,
                    "empty Q8 GEMV terminal ledger mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                    snapshot.cpu_fallback_attempts == 0 &&
                    snapshot.host_tensor_ops == 0,
                    "empty Q8 GEMV fallback/host/unsupported counter nonzero");
    passed &= check(snapshot.coverage_missing == 0 &&
                    snapshot.coverage_duplicate == 0 &&
                    snapshot.coverage_hash_mismatch == 0 &&
                    snapshot.completion_identity_mismatch == 0,
                    "empty Q8 GEMV canonical identity ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                    snapshot.gmem_errors == 0 &&
                    snapshot.timeout_errors == 0,
                    "empty Q8 GEMV RTL terminal counters nonzero");
    passed &= check(snapshot.rtl_cycles > 0,
                    "empty Q8 GEMV RTL cycles were zero");
    passed &= check(snapshot.gmem_read_bytes == 0 &&
                    snapshot.gmem_write_bytes == 0 &&
                    snapshot.vector_elements == 0,
                    "empty Q8 GEMV physical-work ledger was nonzero");
    return passed;
}

bool check_exact_sampler_argmax_audit(
        const ggml_npu_audit_snapshot_v2 & snapshot,
        std::uint64_t expected_read_bytes,
        std::uint64_t expected_elements) {
    bool passed = true;
    passed &= check(snapshot.abi_version == GGML_NPU_AUDIT_V2_ABI_VERSION,
                    "sampler ARGMAX v2 audit ABI mismatch");
    passed &= check(snapshot.required_seen == 1 &&
                        snapshot.assigned_to_npu == 1 &&
                        snapshot.required_enqueued == 1 &&
                        snapshot.required_successfully_covered == 1 &&
                        snapshot.executed_by_verilator == 1,
                    "sampler ARGMAX required completion ledger mismatch");
    passed &= check(snapshot.commands_accepted == 1 &&
                        snapshot.commands_terminal_success == 1 &&
                        snapshot.commands_terminal_failure == 0,
                    "sampler ARGMAX terminal ledger mismatch");
    passed &= check(snapshot.unsupported_required == 0 &&
                        snapshot.cpu_fallback_attempts == 0 &&
                        snapshot.host_tensor_ops == 0,
                    "sampler ARGMAX fallback/host/unsupported counter nonzero");
    passed &= check(snapshot.coverage_missing == 0 &&
                        snapshot.coverage_duplicate == 0 &&
                        snapshot.coverage_hash_mismatch == 0 &&
                        snapshot.completion_identity_mismatch == 0,
                    "sampler ARGMAX canonical identity ledger mismatch");
    passed &= check(snapshot.rtl_failures == 0 &&
                        snapshot.gmem_errors == 0 &&
                        snapshot.timeout_errors == 0,
                    "sampler ARGMAX RTL terminal counters nonzero");
    passed &= check(snapshot.rtl_cycles > 0,
                    "sampler ARGMAX RTL cycles were zero");
    passed &= check(snapshot.gmem_read_bytes == expected_read_bytes,
                    "sampler ARGMAX full-vocabulary read byte mismatch");
    passed &= check(snapshot.gmem_write_bytes == 4,
                    "sampler ARGMAX scalar write byte mismatch");
    passed &= check(snapshot.vector_elements == expected_elements,
                    "sampler ARGMAX scanned element mismatch");
    return passed;
}

// Exact test-only oracle from ggml-cpu/vec.h::ggml_vec_argmax_f32.  The
// production backend and runner never call this function and see only raw
// tensor bits plus one I32 destination scalar.
std::uint32_t test_only_ggml_argmax_f32(
        const std::uint32_t * bits,
        std::size_t elements) {
    float max_value = -std::numeric_limits<float>::infinity();
    std::uint32_t index = 0;
    for (std::size_t element = 0; element < elements; ++element) {
        float value = 0.0F;
        std::memcpy(&value, bits + element, sizeof(value));
        max_value = max_value > value ? max_value : value;
        if (max_value == value) {
            index = static_cast<std::uint32_t>(element);
        }
    }
    return index;
}

bool apply_q8_gemv_tensor_spec(
        ggml_tensor * tensor,
        const qwen_q8_gemv_manifest::tensor_spec & spec,
        ggml_tensor * view_root = nullptr) {
    if (tensor == nullptr || (spec.view_present && view_root == nullptr)) {
        return false;
    }
    tensor->type = static_cast<enum ggml_type>(spec.type_id);
    tensor->op = static_cast<enum ggml_op>(spec.op_id);
    tensor->flags = spec.flags;
    tensor->view_src = spec.view_present ? view_root : nullptr;
    tensor->view_offs = spec.view_offs;
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        tensor->ne[dimension] = spec.ne[dimension];
        tensor->nb[dimension] = spec.nb[dimension];
    }
    static_assert(sizeof(tensor->op_params) == 64,
                  "canonical-v5 op_params width changed");
    std::memcpy(tensor->op_params, spec.op_params.data(),
                spec.op_params.size());
    return true;
}

ggml_tensor * make_q8_gemv_profile_op(
        ggml_context * context,
        const qwen_q8_gemv_manifest::profile & profile) {
    ggml_tensor * weight = ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.weight.type_id),
        profile.weight.ne[0], profile.weight.ne[1],
        profile.weight.ne[2], profile.weight.ne[3]);
    ggml_tensor * activation = ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.activation.type_id),
        profile.activation.ne[0], profile.activation.ne[1],
        profile.activation.ne[2], profile.activation.ne[3]);
    ggml_tensor * dst = ggml_new_tensor_4d(
        context, static_cast<enum ggml_type>(profile.dst.type_id),
        profile.dst.ne[0], profile.dst.ne[1],
        profile.dst.ne[2], profile.dst.ne[3]);
    ggml_tensor * activation_root = profile.activation.view_present ?
        ggml_new_tensor_1d(context, GGML_TYPE_F32,
                           profile.activation.ne[0]) : nullptr;
    if (!apply_q8_gemv_tensor_spec(weight, profile.weight) ||
        !apply_q8_gemv_tensor_spec(
            activation, profile.activation, activation_root) ||
        !apply_q8_gemv_tensor_spec(dst, profile.dst)) {
        return nullptr;
    }
    std::memset(dst->src, 0, sizeof(dst->src));
    dst->src[0] = weight;
    dst->src[1] = activation;
    return dst;
}

ggml_tensor * make_profile_tensor(
        ggml_context * context,
        const test_tensor_descriptor & descriptor,
        bool allow_null_data = false) {
    std::uint64_t beat_lo = 0;
    std::uint64_t beat_hi = 0;
    if (!test_source_span(descriptor, &beat_lo, &beat_hi) ||
        beat_hi % 4 != 0 || beat_hi > std::numeric_limits<std::size_t>::max()) {
        return nullptr;
    }
    ggml_tensor * tensor = nullptr;
    ggml_tensor * allocation = nullptr;
    if (descriptor.view_present) {
        allocation = ggml_new_tensor_1d(
            context, GGML_TYPE_F32,
            static_cast<std::int64_t>(beat_hi / 4));
        tensor = ggml_view_4d(
            context,
            allocation,
            descriptor.ne[0], descriptor.ne[1],
            descriptor.ne[2], descriptor.ne[3],
            descriptor.nb[1], descriptor.nb[2], descriptor.nb[3],
            descriptor.view_off);
    } else {
        tensor = ggml_new_tensor_4d(
            context, GGML_TYPE_F32,
            descriptor.ne[0], descriptor.ne[1],
            descriptor.ne[2], descriptor.ne[3]);
        allocation = tensor;
    }
    if (tensor == nullptr || allocation == nullptr ||
        (!allow_null_data && allocation->data == nullptr)) {
        return nullptr;
    }
    for (std::size_t dimension = 0; dimension < 4; ++dimension) {
        tensor->ne[dimension] = descriptor.ne[dimension];
        tensor->nb[dimension] = descriptor.nb[dimension];
    }
    tensor->view_offs = descriptor.view_off;
    if (allocation->data != nullptr) {
        std::memset(allocation->data, 0, static_cast<std::size_t>(beat_hi));
    }
    return tensor;
}

ggml_tensor * make_profile_op(
        ggml_context * context,
        const test_profile & profile,
        bool allow_null_data = false) {
    ggml_tensor * dst = make_profile_tensor(
        context, profile.dst, allow_null_data);
    ggml_tensor * src0 = make_profile_tensor(
        context, profile.src0, allow_null_data);
    ggml_tensor * src1 = profile.src1_present ?
        make_profile_tensor(context, profile.src1, allow_null_data) : nullptr;
    if (dst == nullptr || src0 == nullptr ||
        (profile.src1_present && src1 == nullptr)) {
        return nullptr;
    }
    dst->op = profile.op;
    std::memset(dst->src, 0, sizeof(dst->src));
    dst->src[0] = src0;
    dst->src[1] = src1;
    std::memset(dst->op_params, 0, sizeof(dst->op_params));
    std::memcpy(dst->op_params, &profile.scalar0, sizeof(profile.scalar0));
    dst->flags |= GGML_TENSOR_FLAG_COMPUTE;
    return dst;
}

bool raw_output_is_zero(const ggml_tensor * tensor, std::size_t bytes) {
    if (tensor == nullptr || tensor->data == nullptr || ggml_nbytes(tensor) < bytes) {
        return false;
    }
    const auto * raw = static_cast<const std::uint8_t *>(tensor->data);
    for (std::size_t index = 0; index < bytes; ++index) {
        if (raw[index] != 0) {
            return false;
        }
    }
    return true;
}

bool parse_canonical_id(
        const char * text,
        std::array<std::uint8_t, 32> * canonical_id) {
    if (text == nullptr || canonical_id == nullptr ||
        std::strlen(text) != 64) {
        return false;
    }
    auto nibble = [](char ch) -> int {
        if (ch >= '0' && ch <= '9') {
            return ch - '0';
        }
        if (ch >= 'a' && ch <= 'f') {
            return ch - 'a' + 10;
        }
        return -1;
    };
    bool nonzero = false;
    for (std::size_t index = 0; index < canonical_id->size(); ++index) {
        const int high = nibble(text[2*index]);
        const int low = nibble(text[2*index + 1]);
        if (high < 0 || low < 0) {
            return false;
        }
        (*canonical_id)[index] =
            static_cast<std::uint8_t>((high << 4) | low);
        nonzero |= (*canonical_id)[index] != 0;
    }
    return nonzero;
}

bool representative_identity_matches(
        std::uint32_t profile_id,
        const ggml_npu_f32_alu_representative_identity_v4 & identity) {
    const std::uint64_t repeated_profile =
        (static_cast<std::uint64_t>(profile_id) << 32) | profile_id;
    return identity.profile_id == profile_id &&
           identity.command_flags == 0x00000010u &&
           identity.context_id == (0x52500000u | profile_id) &&
           identity.reserved == 0 &&
           identity.sequence_id ==
               (0x5250524550000000ULL | profile_id) &&
           identity.producer_id ==
               (0x5250524f44000000ULL | profile_id) &&
           identity.user_tag ==
               (0x5250544147000000ULL | profile_id) &&
           identity.node_hash_lo ==
               (0x9e3779b97f4a7c15ULL ^ profile_id) &&
           identity.node_hash_hi ==
               (0xd1b54a32d192ed03ULL ^ repeated_profile);
}

int run_f32_alu_graph_test(
        const char * backend_path,
        bool zero_binding_only = false) {
    check_phase = "NPU-BACKEND-F32-ALU-GRAPH";
    checks = 0;
    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 30;
    }
    ggml_backend_dev_t device = ggml_backend_reg_dev_get(registry, 0);
    auto audit_begin = reinterpret_cast<
        ggml_backend_npu_representative_audit_begin_v4_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_REPRESENTATIVE_AUDIT_BEGIN_V4_PROC));
    auto audit_end = reinterpret_cast<
        ggml_backend_npu_representative_audit_end_v4_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_REPRESENTATIVE_AUDIT_END_V4_PROC));
    auto audit_validate = reinterpret_cast<
        ggml_backend_npu_representative_audit_validate_v4_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_REPRESENTATIVE_AUDIT_VALIDATE_V4_PROC));
    auto binding_begin = reinterpret_cast<
        ggml_backend_npu_canonical_binding_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
    auto binding_bind = reinterpret_cast<
        ggml_backend_npu_canonical_binding_bind_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
    auto binding_seal = reinterpret_cast<
        ggml_backend_npu_canonical_binding_seal_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
    if (!check(device != nullptr, "missing device") ||
        !check(audit_begin != nullptr && audit_end != nullptr &&
                   audit_validate != nullptr && binding_begin != nullptr &&
                   binding_bind != nullptr && binding_seal != nullptr,
               "missing representative audit v4 procs")) {
        ggml_backend_unload(registry);
        return 31;
    }
    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    ggml_init_params parameters = {
        64 * 1024 * 1024,
        nullptr,
        zero_binding_only,
    };
    ggml_context * context = ggml_init(parameters);
    if (!check(backend != nullptr, "backend init failed") ||
        !check(context != nullptr, "context init failed")) {
        if (context != nullptr) {
            ggml_free(context);
        }
        if (backend != nullptr) {
            ggml_backend_free(backend);
        }
        ggml_backend_unload(registry);
        return 32;
    }

    ggml_cgraph * graph = ggml_new_graph(context);
    std::vector<ggml_tensor *> outputs;
    bool passed = check(graph != nullptr, "graph allocation failed");
    for (const test_profile & profile : kTestProfiles) {
        ggml_tensor * op = make_profile_op(
            context, profile, zero_binding_only);
        passed &= check(op != nullptr, "profile tensor allocation failed");
        if (op == nullptr) {
            break;
        }
        void * saved_dst = op->data;
        void * saved_src0 = op->src[0]->data;
        void * saved_src1 = profile.src1_present ? op->src[1]->data : nullptr;
        op->data = nullptr;
        op->src[0]->data = nullptr;
        if (profile.src1_present) {
            op->src[1]->data = nullptr;
        }
        passed &= check(ggml_backend_dev_supports_op(device, op),
                        "metadata-only profile predicate rejected");
        op->data = saved_dst;
        op->src[0]->data = saved_src0;
        if (profile.src1_present) {
            op->src[1]->data = saved_src1;
        }
        outputs.push_back(op);
        ggml_build_forward_expand(graph, op);
    }

    if (outputs.size() == kTestProfiles.size()) {
        ggml_tensor * p00 = outputs[0];
        const std::size_t saved_nb = p00->src[0]->nb[1];
        p00->src[0]->nb[1] = saved_nb + 4;
        passed &= check(!ggml_backend_dev_supports_op(device, p00),
                        "stride mutation was accepted");
        p00->src[0]->nb[1] = saved_nb;
        const std::size_t saved_off = p00->src[0]->view_offs;
        p00->src[0]->view_offs = saved_off + 8;
        passed &= check(!ggml_backend_dev_supports_op(device, p00),
                        "view offset mutation was accepted");
        p00->src[0]->view_offs = saved_off;
        ggml_tensor * p04 = outputs[4];
        const enum ggml_op saved_op = p04->op;
        p04->op = GGML_OP_ADD;
        passed &= check(!ggml_backend_dev_supports_op(device, p04),
                        "op/profile collision was accepted");
        p04->op = saved_op;
        ggml_tensor * p16 = outputs[16];
        auto * scale_bytes =
            reinterpret_cast<std::uint8_t *>(p16->op_params);
        scale_bytes[4] = 1;
        passed &= check(!ggml_backend_dev_supports_op(device, p16),
                        "SCALE raw tail mutation was accepted");
        scale_bytes[4] = 0;

        ggml_tensor * p17 = outputs[17];
        ggml_tensor * p17_src0 = p17->src[0];
        const auto saved_p17_ne = std::array<std::int64_t, 4>{
            p17->ne[0], p17->ne[1], p17->ne[2], p17->ne[3]};
        const auto saved_p17_nb = std::array<std::size_t, 4>{
            p17->nb[0], p17->nb[1], p17->nb[2], p17->nb[3]};
        const auto saved_p17_src0_ne = std::array<std::int64_t, 4>{
            p17_src0->ne[0], p17_src0->ne[1], p17_src0->ne[2],
            p17_src0->ne[3]};
        const auto saved_p17_src0_nb = std::array<std::size_t, 4>{
            p17_src0->nb[0], p17_src0->nb[1], p17_src0->nb[2],
            p17_src0->nb[3]};
        char saved_p17_name[GGML_MAX_NAME] = {};
        char saved_p17_src0_name[GGML_MAX_NAME] = {};
        ggml_tensor * const saved_p17_view_src = p17->view_src;
        ggml_tensor * const p17_shared_root = p17_src0->view_src;
        char saved_p17_root_name[GGML_MAX_NAME] = {};
        std::memcpy(saved_p17_name, p17->name, sizeof(saved_p17_name));
        std::memcpy(saved_p17_src0_name, p17_src0->name,
                    sizeof(saved_p17_src0_name));
        std::memcpy(saved_p17_root_name, p17_shared_root->name,
                    sizeof(saved_p17_root_name));
        for (ggml_tensor * tensor : {p17, p17_src0}) {
            tensor->ne[0] = 0;
            tensor->ne[1] = tensor->ne[2] = tensor->ne[3] = 1;
            tensor->nb[0] = 4;
            tensor->nb[1] = tensor->nb[2] = tensor->nb[3] = 0;
        }
        ggml_set_name(p17, "cache_r_l0 (reshaped) (view) (view)");
        ggml_set_name(p17_src0, "cache_r_l0 (reshaped) (view)");
        ggml_set_name(p17_shared_root, "cache_r_l0");
        passed &= check(!ggml_backend_dev_supports_op(device, p17),
                        "P17 zero with split view roots was accepted");
        p17->view_src = p17_shared_root;
        passed &= check(ggml_backend_dev_supports_op(device, p17),
                        "canonical P17 zero descriptor was rejected");

        ggml_npu_canonical_node_binding_v1 zero_binding = {};
        zero_binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
        const char * p17_canonical_id = nullptr;
        for (const auto & frozen :
             ggml_npu_generated::kQwenF32AluCanonicalNodes) {
            if (frozen.zero_cardinality_allowed &&
                frozen.graph_node_index == 5U && frozen.profile_id == 17U) {
                p17_canonical_id = frozen.canonical_id_hex;
                break;
            }
        }
        std::array<std::uint8_t, 32> parsed_p17_id = {};
        passed &= check(parse_canonical_id(
                            p17_canonical_id, &parsed_p17_id),
                        "missing generated P17 zero canonical ID");
        std::memcpy(zero_binding.canonical_id, parsed_p17_id.data(),
                    parsed_p17_id.size());
        zero_binding.graph_node_index = 6;
        passed &= check(binding_begin(backend, 0x1701U, 1U) &&
                            !binding_bind(
                                backend, 0x1701U, p17, &zero_binding),
                        "gapped P17 zero graph index was accepted");
        zero_binding.graph_node_index = 5;
        zero_binding.canonical_id[0] ^= 1U;
        passed &= check(binding_begin(backend, 0x1704U, 1U) &&
                            !binding_bind(
                                backend, 0x1704U, p17, &zero_binding),
                        "wrong P17 zero canonical ID was accepted");
        zero_binding.canonical_id[0] ^= 1U;
        zero_binding.graph_node_index = 5;
        passed &= check(binding_begin(backend, 0x1702U, 1U) &&
                            binding_bind(
                                backend, 0x1702U, p17, &zero_binding) &&
                            binding_seal(backend, 0x1702U),
                        "canonical P17 zero binding was rejected");
        passed &= check(binding_begin(backend, 0x1703U, 1U),
                        "P17 cleanup binding begin failed");
        zero_binding.graph_node_index = 6;
        passed &= check(!binding_bind(
                            backend, 0x1703U, p17, &zero_binding),
                        "P17 cleanup reject did not clear binding");
        ggml_set_name(p17, "noncanonical empty scale");
        passed &= check(!ggml_backend_dev_supports_op(device, p17),
                        "arbitrary zero SCALE name was accepted");

        for (std::size_t dimension = 0; dimension < 4; ++dimension) {
            p17->ne[dimension] = saved_p17_ne[dimension];
            p17->nb[dimension] = saved_p17_nb[dimension];
            p17_src0->ne[dimension] = saved_p17_src0_ne[dimension];
            p17_src0->nb[dimension] = saved_p17_src0_nb[dimension];
        }
        ggml_set_name(p17, saved_p17_name);
        ggml_set_name(p17_src0, saved_p17_src0_name);
        ggml_set_name(p17_shared_root, saved_p17_root_name);
        p17->view_src = saved_p17_view_src;

        ggml_tensor * p18 = outputs[18];
        ggml_tensor * p18_src0 = p18->src[0];
        ggml_tensor * const saved_p18_view_src = p18->view_src;
        ggml_tensor * const p18_shared_root = p18_src0->view_src;
        const auto saved_p18_ne = std::array<std::int64_t, 4>{
            p18->ne[0], p18->ne[1], p18->ne[2], p18->ne[3]};
        const auto saved_p18_nb = std::array<std::size_t, 4>{
            p18->nb[0], p18->nb[1], p18->nb[2], p18->nb[3]};
        const auto saved_p18_src0_ne = std::array<std::int64_t, 4>{
            p18_src0->ne[0], p18_src0->ne[1], p18_src0->ne[2],
            p18_src0->ne[3]};
        const auto saved_p18_src0_nb = std::array<std::size_t, 4>{
            p18_src0->nb[0], p18_src0->nb[1], p18_src0->nb[2],
            p18_src0->nb[3]};
        char saved_p18_name[GGML_MAX_NAME] = {};
        char saved_p18_src0_name[GGML_MAX_NAME] = {};
        char saved_p18_root_name[GGML_MAX_NAME] = {};
        std::memcpy(saved_p18_name, p18->name, sizeof(saved_p18_name));
        std::memcpy(saved_p18_src0_name, p18_src0->name,
                    sizeof(saved_p18_src0_name));
        std::memcpy(saved_p18_root_name, p18_shared_root->name,
                    sizeof(saved_p18_root_name));
        for (ggml_tensor * tensor : {p18, p18_src0}) {
            tensor->ne[0] = 0;
            tensor->ne[1] = tensor->ne[2] = tensor->ne[3] = 1;
            tensor->nb[0] = 4;
            tensor->nb[1] = tensor->nb[2] = tensor->nb[3] = 0;
        }
        ggml_set_name(p18, "cache_s_l0 (reshaped) (view) (view)");
        ggml_set_name(p18_src0, "cache_s_l0 (reshaped) (view)");
        ggml_set_name(p18_shared_root, "cache_s_l0");
        p18->view_src = p18_shared_root;
        passed &= check(ggml_backend_dev_supports_op(device, p18),
                        "canonical P18 zero descriptor was rejected");
        p18_shared_root->ne[0] = 18432;
        passed &= check(!ggml_backend_dev_supports_op(device, p18),
                        "P18 zero with P17 root layout was accepted");
        p18_shared_root->ne[0] = 262144;
        for (std::size_t dimension = 0; dimension < 4; ++dimension) {
            p18->ne[dimension] = saved_p18_ne[dimension];
            p18->nb[dimension] = saved_p18_nb[dimension];
            p18_src0->ne[dimension] = saved_p18_src0_ne[dimension];
            p18_src0->nb[dimension] = saved_p18_src0_nb[dimension];
        }
        ggml_set_name(p18, saved_p18_name);
        ggml_set_name(p18_src0, saved_p18_src0_name);
        ggml_set_name(p18_shared_root, saved_p18_root_name);
        p18->view_src = saved_p18_view_src;
    }

    if (zero_binding_only) {
        ggml_free(context);
        ggml_backend_free(backend);
        ggml_backend_unload(registry);
        if (!passed) {
            return 33;
        }
        std::printf(
            "[NPU-BACKEND-F32-ZERO-BINDING][PASS] "
            "canonical_p17_p18=2 split_root_rejected=1 "
            "root_layout_rejected=1 gapped_index_rejected=1 "
            "canonical_id_rejected=1 arbitrary_name_rejected=1\n");
        return 0;
    }

    std::uint64_t expected_read = 0;
    std::uint64_t expected_write = 0;
    std::uint64_t expected_elements = 0;
    for (const test_profile & profile : kTestProfiles) {
        expected_read += profile.expected_read_bytes;
        expected_write += profile.expected_write_bytes;
        expected_elements += profile.total_elements;
    }

    passed &= check(audit_begin(backend, 0x1900, 19),
                    "19-profile audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "19-profile graph compute failed");
    ggml_npu_representative_audit_snapshot_v4 snapshot = {};
    passed &= check(audit_end(backend, 0x1900, &snapshot),
                    "19-profile audit did not close");
    passed &= check(audit_validate(&snapshot),
                    "closed representative snapshot rejected");
    passed &= check(snapshot.command_accepted_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK &&
                    snapshot.completion_emitted_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK &&
                    snapshot.completion_accepted_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK &&
                    snapshot.raw_dst_committed_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK &&
                    snapshot.representative_covered_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK &&
                    snapshot.returned_identity_mask ==
                        GGML_NPU_F32_ALU_PROFILE_MASK,
                    "five-stage identity set mismatch");
    passed &= check(snapshot.commands_accepted == 19 &&
                    snapshot.completions_emitted == 19 &&
                    snapshot.completions_accepted == 19 &&
                    snapshot.raw_destinations_committed == 19 &&
                    snapshot.representative_transactions_passed == 19 &&
                    snapshot.ordered_count == 19,
                    "five-stage cardinality mismatch");
    passed &= check(snapshot.required_issued_delta == 0 &&
                    snapshot.required_completed_delta == 0,
                    "representatives polluted top required counters");
    passed &= check(
        snapshot.predecessor_representative_transactions_passed == 1 &&
        snapshot.verified_canonical_completed == 0 &&
        snapshot.verified_canonical_remaining == 1080,
        "representative/canonical domains collapsed");
    for (std::uint32_t profile_id = 0;
         profile_id < GGML_NPU_F32_ALU_PROFILE_COUNT; ++profile_id) {
        passed &= check(representative_identity_matches(
                            profile_id,
                            snapshot.returned_identities[profile_id]),
                        "returned representative identity mismatch");
    }

    ggml_npu_representative_audit_snapshot_v4 mutation = snapshot;
    ++mutation.duplicate_replay_rejections;
    passed &= check(!audit_validate(&mutation),
                    "duplicate replay mutation was accepted");
    mutation = snapshot;
    ++mutation.wrong_profile_rejections;
    passed &= check(!audit_validate(&mutation),
                    "wrong-profile mutation was accepted");
    mutation = snapshot;
    mutation.completion_accepted_mask &= ~1u;
    passed &= check(!audit_validate(&mutation),
                    "missing identity mutation was accepted");
    mutation = snapshot;
    ++mutation.extra_identity_rejections;
    passed &= check(!audit_validate(&mutation),
                    "extra identity mutation was accepted");
    mutation = snapshot;
    mutation.returned_identities[3].node_hash_hi ^= 1u;
    passed &= check(!audit_validate(&mutation),
                    "identity substitution mutation was accepted");
    mutation = snapshot;
    ++mutation.reordered_profile_rejections;
    passed &= check(!audit_validate(&mutation),
                    "reordered-profile collision was accepted");
    for (std::size_t index = 0; index < outputs.size(); ++index) {
        passed &= check(raw_output_is_zero(
                            outputs[index],
                            static_cast<std::size_t>(
                                kTestProfiles[index].expected_write_bytes)),
                        "raw output was not all-zero fixed oracle");
    }

    ggml_free(context);
    ggml_backend_free(backend);
    ggml_backend_unload(registry);
    if (!passed) {
        return 33;
    }
    std::printf(
        "[NPU-BACKEND-F32-ALU-GRAPH-V4][PASS] profiles=19 "
        "stage_mask=0x%05x representatives=19 predecessor_representatives=1 "
        "verified_canonical_completed=0 remaining=1080 required_delta=0/0 "
        "read=%llu write=%llu elements=%llu\n",
        snapshot.representative_covered_mask,
        static_cast<unsigned long long>(expected_read),
        static_cast<unsigned long long>(expected_write),
        static_cast<unsigned long long>(expected_elements));
    return 0;
}

int run_q8_get_rows_graph_test(
        const char * backend_path,
        const char * canonical_text) {
    check_phase = "NPU-BACKEND-Q8-GET-ROWS";
    checks = 0;
    constexpr std::size_t kAlignment = 32;
    constexpr std::size_t kTableBytes = 270172160;
    constexpr std::size_t kIndexStorageBytes = 32;
    constexpr std::size_t kDstBytes = 4096;
    constexpr std::size_t kRowBytes = 1088;
    constexpr std::uint32_t kVocabulary = 248320;
    constexpr std::uint32_t kLastId = kVocabulary - 1;
    constexpr std::array<std::uint8_t, 7> kQ8Pattern = {
        0x80, 0xfe, 0xff, 0x00, 0x01, 0x02, 0x7f,
    };
    constexpr std::array<std::uint32_t, 7> kQ8Expected = {
        0xc3000000U, 0xc0000000U, 0xbf800000U, 0x00000000U,
        0x3f800000U, 0x40000000U, 0x42fe0000U,
    };

    std::array<std::uint8_t, 32> canonical_id = {};
    if (!check(parse_canonical_id(canonical_text, &canonical_id),
               "expected lowercase Q8 canonical ID")) {
        return 50;
    }

    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 51;
    }
    ggml_backend_dev_t device = ggml_backend_reg_dev_get(registry, 0);
    auto audit_begin_v2 = reinterpret_cast<ggml_backend_npu_audit_begin_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_BEGIN_V2_PROC));
    auto audit_end_v2 = reinterpret_cast<ggml_backend_npu_audit_end_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_END_V2_PROC));
    auto binding_begin = reinterpret_cast<
        ggml_backend_npu_canonical_binding_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
    auto binding_bind = reinterpret_cast<
        ggml_backend_npu_canonical_binding_bind_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
    auto binding_seal = reinterpret_cast<
        ggml_backend_npu_canonical_binding_seal_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
    if (!check(device != nullptr, "missing NPU device") ||
        !check(audit_begin_v2 != nullptr && audit_end_v2 != nullptr &&
                   binding_begin != nullptr && binding_bind != nullptr &&
                   binding_seal != nullptr,
               "missing Q8 canonical/audit procs")) {
        ggml_backend_unload(registry);
        return 52;
    }

    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    ggml_init_params parameters = {
        4 * 1024 * 1024,
        nullptr,
        true,
    };
    ggml_context * context = ggml_init(parameters);
    void * table_storage = std::aligned_alloc(kAlignment, kTableBytes);
    void * index_storage = std::aligned_alloc(
        kAlignment, kIndexStorageBytes);
    void * dst_storage = std::aligned_alloc(kAlignment, kDstBytes);
    ggml_backend_buffer_t table_buffer = nullptr;
    ggml_backend_buffer_t index_buffer = nullptr;
    ggml_backend_buffer_t dst_buffer = nullptr;

    auto cleanup = [&]() {
        if (table_buffer != nullptr) {
            ggml_backend_buffer_free(table_buffer);
        }
        if (index_buffer != nullptr) {
            ggml_backend_buffer_free(index_buffer);
        }
        if (dst_buffer != nullptr) {
            ggml_backend_buffer_free(dst_buffer);
        }
        if (context != nullptr) {
            ggml_free(context);
        }
        std::free(table_storage);
        std::free(index_storage);
        std::free(dst_storage);
        if (backend != nullptr) {
            ggml_backend_free(backend);
        }
        ggml_backend_unload(registry);
    };

    if (!check(backend != nullptr && context != nullptr,
               "Q8 backend/context initialization failed") ||
        !check(table_storage != nullptr && index_storage != nullptr &&
                   dst_storage != nullptr,
               "Q8 aligned external allocation failed")) {
        cleanup();
        return 53;
    }

    ggml_tensor * table =
        ggml_new_tensor_2d(context, GGML_TYPE_Q8_0, 1024, kVocabulary);
    ggml_tensor * indices =
        ggml_new_tensor_1d(context, GGML_TYPE_I32, 1);
    ggml_tensor * rows = ggml_get_rows(context, table, indices);
    ggml_set_name(table, "token_embd.weight");
    ggml_set_name(indices, "inp_tokens");
    ggml_set_name(rows, "model.input_embed");
    ggml_set_input(indices);
    ggml_cgraph * graph = ggml_new_graph(context);
    ggml_build_forward_expand(graph, rows);

    bool passed = true;
    passed &= check(table != nullptr && indices != nullptr && rows != nullptr &&
                        graph != nullptr,
                    "real ggml GET_ROWS graph construction failed");
    passed &= check(table->type == GGML_TYPE_Q8_0 &&
                        table->ne[0] == 1024 &&
                        table->ne[1] == kVocabulary &&
                        table->ne[2] == 1 && table->ne[3] == 1 &&
                        table->nb[0] == 34 && table->nb[1] == 1088 &&
                        table->nb[2] == kTableBytes &&
                        table->nb[3] == kTableBytes &&
                        ggml_nbytes(table) == kTableBytes,
                    "Q8 table descriptor differs from canonical v5");
    passed &= check(indices->type == GGML_TYPE_I32 &&
                        indices->ne[0] == 1 && indices->ne[1] == 1 &&
                        indices->nb[0] == 4 && indices->nb[1] == 4 &&
                        ggml_nbytes(indices) == 4,
                    "Q8 index descriptor differs from canonical v5");
    passed &= check(rows->op == GGML_OP_GET_ROWS &&
                        rows->type == GGML_TYPE_F32 &&
                        rows->ne[0] == 1024 && rows->ne[1] == 1 &&
                        rows->nb[0] == 4 && rows->nb[1] == 4096 &&
                        ggml_nbytes(rows) == kDstBytes &&
                        (rows->flags & GGML_TENSOR_FLAG_COMPUTE) != 0,
                    "Q8 destination descriptor differs from canonical v5");
    bool op_params_zero = true;
    for (std::uint8_t byte : rows->op_params) {
        op_params_zero &= byte == 0;
    }
    passed &= check(op_params_zero, "GET_ROWS op_params were not all zero");

    if (!passed) {
        cleanup();
        return 54;
    }

    table_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, table_storage, kTableBytes, kTableBytes);
    index_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, index_storage, kIndexStorageBytes, 4);
    dst_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, dst_storage, kDstBytes, kDstBytes);
    passed &= check(table_buffer != nullptr && index_buffer != nullptr &&
                        dst_buffer != nullptr,
                    "Q8 mapped buffer creation failed");
    if (passed) {
        passed &= check(
            ggml_backend_tensor_alloc(table_buffer, table, table_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 table tensor attachment failed");
        passed &= check(
            ggml_backend_tensor_alloc(index_buffer, indices, index_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 index tensor attachment failed");
        passed &= check(
            ggml_backend_tensor_alloc(dst_buffer, rows, dst_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 destination tensor attachment failed");
    }
    if (!passed) {
        cleanup();
        return 55;
    }

    auto * table_raw = static_cast<std::uint8_t *>(table_storage);
    auto * index_raw = static_cast<std::uint8_t *>(index_storage);
    auto * dst_raw = static_cast<std::uint8_t *>(dst_storage);
    const std::size_t last_row_offset =
        static_cast<std::size_t>(kLastId) * kRowBytes;
    for (std::size_t block = 0; block < 32; ++block) {
        const std::size_t block_offset = last_row_offset + block * 34;
        table_raw[block_offset] = 0x00;
        table_raw[block_offset + 1] = 0x3c;
        for (std::size_t lane = 0; lane < 32; ++lane) {
            const std::size_t element = block * 32 + lane;
            table_raw[block_offset + 2 + lane] =
                kQ8Pattern[element % kQ8Pattern.size()];
        }
    }
    std::memset(index_raw, 0, kIndexStorageBytes);
    std::memset(dst_raw, 0xa5, kDstBytes);

    auto make_binding = [&](std::uint64_t graph_node_index) {
        ggml_npu_canonical_node_binding_v1 binding = {};
        binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
        binding.graph_node_index = graph_node_index;
        std::memcpy(binding.canonical_id, canonical_id.data(),
                    canonical_id.size());
        return binding;
    };
    auto q8_binding = make_binding(0);

    // Exact metadata is a separate obligation from the canonical semantic SHA.
    // Every mutation invalidates the entire binding cohort before execution.
    const enum ggml_type saved_table_type = table->type;
    table->type = GGML_TYPE_Q4_0;
    passed &= check(!ggml_backend_dev_supports_op(device, rows),
                    "bad Q8 source dtype was accepted");
    passed &= check(binding_begin(backend, 200, 1),
                    "bad-source-dtype binding begin failed");
    passed &= check(!binding_bind(backend, 200, rows, &q8_binding),
                    "bad Q8 source dtype acquired canonical binding");
    passed &= check(!binding_seal(backend, 200),
                    "bad-source-dtype cohort sealed");
    table->type = saved_table_type;

    const enum ggml_type saved_index_type = indices->type;
    indices->type = GGML_TYPE_F32;
    passed &= check(!ggml_backend_dev_supports_op(device, rows),
                    "bad Q8 index dtype was accepted");
    passed &= check(binding_begin(backend, 201, 1),
                    "bad-index-dtype binding begin failed");
    passed &= check(!binding_bind(backend, 201, rows, &q8_binding),
                    "bad Q8 index dtype acquired canonical binding");
    passed &= check(!binding_seal(backend, 201),
                    "bad-index-dtype cohort sealed");
    indices->type = saved_index_type;

    const std::int64_t saved_dst_ne0 = rows->ne[0];
    rows->ne[0] = 1000;
    passed &= check(!ggml_backend_dev_supports_op(device, rows),
                    "bad Q8 destination shape was accepted");
    passed &= check(binding_begin(backend, 202, 1),
                    "bad-shape binding begin failed");
    passed &= check(!binding_bind(backend, 202, rows, &q8_binding),
                    "bad Q8 shape acquired canonical binding");
    passed &= check(!binding_seal(backend, 202),
                    "bad-shape cohort sealed");
    rows->ne[0] = saved_dst_ne0;

    auto * op_params = reinterpret_cast<std::uint8_t *>(rows->op_params);
    op_params[0] = 1;
    passed &= check(!ggml_backend_dev_supports_op(device, rows),
                    "nonzero Q8 op_params were accepted");
    op_params[0] = 0;

    // Missing binding is rejected before graph execution can start.
    passed &= check(!audit_begin_v2(backend, 300, 1, 1),
                    "Q8 v2 audit accepted missing binding");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 graph executed without active bound audit");

    // Dynamic ID OOB is the one post-admission negative: RTL scans both
    // unaligned index beats, then emits IOVA/class-5 with zero source/write.
    std::uint32_t invalid_id = kVocabulary;
    std::memcpy(index_raw, &invalid_id, sizeof(invalid_id));
    std::memset(dst_raw, 0xa5, kDstBytes);
    passed &= check(binding_begin(backend, 203, 1),
                    "Q8 OOB binding begin failed");
    passed &= check(binding_bind(backend, 203, rows, &q8_binding),
                    "Q8 OOB exact binding failed");
    passed &= check(binding_seal(backend, 203),
                    "Q8 OOB binding seal failed");
    passed &= check(audit_begin_v2(backend, 301, 1, 1),
                    "Q8 OOB v2 audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 out-of-range index unexpectedly succeeded");
    ggml_npu_audit_snapshot_v2 oob_snapshot = {};
    passed &= check(!audit_end_v2(backend, 301, &oob_snapshot),
                    "Q8 OOB audit unexpectedly closed as success");
    passed &= check(oob_snapshot.required_seen == 1 &&
                        oob_snapshot.assigned_to_npu == 1 &&
                        oob_snapshot.required_enqueued == 1 &&
                        oob_snapshot.required_successfully_covered == 0 &&
                        oob_snapshot.executed_by_verilator == 0,
                    "Q8 OOB required ledger mismatch");
    passed &= check(oob_snapshot.commands_accepted == 1 &&
                        oob_snapshot.commands_terminal_success == 0 &&
                        oob_snapshot.commands_terminal_failure == 1 &&
                        oob_snapshot.gmem_read_bytes == 16 &&
                        oob_snapshot.gmem_write_bytes == 0 &&
                        oob_snapshot.vector_elements == 0,
                    "Q8 OOB terminal/traffic mismatch");
    passed &= check(oob_snapshot.coverage_missing == 1 &&
                        oob_snapshot.coverage_duplicate == 0 &&
                        oob_snapshot.coverage_hash_mismatch == 0 &&
                        oob_snapshot.completion_identity_mismatch == 0 &&
                        oob_snapshot.rtl_failures == 1,
                    "Q8 OOB fail-closed counters mismatch");
    passed &= check(oob_snapshot.cpu_fallback_attempts == 0 &&
                        oob_snapshot.host_tensor_ops == 0 &&
                        oob_snapshot.gmem_errors == 0 &&
                        oob_snapshot.timeout_errors == 0,
                    "Q8 OOB escaped into fallback/host/error class");
    bool oob_destination_private = true;
    for (std::size_t byte = 0; byte < kDstBytes; ++byte) {
        oob_destination_private &= dst_raw[byte] == 0xa5;
    }
    passed &= check(oob_destination_private,
                    "Q8 OOB partially published destination");

    // Positive production path: real ggml graph -> canonical REQUIRED command
    // -> RTL raw dequantization -> exact completion -> private publication.
    std::uint32_t valid_id = kLastId;
    std::memcpy(index_raw, &valid_id, sizeof(valid_id));
    std::memset(dst_raw, 0xa5, kDstBytes);
    passed &= check(ggml_backend_dev_supports_op(device, rows),
                    "exact Q8 GET_ROWS predicate rejected");
    passed &= check(binding_begin(backend, 204, 1),
                    "Q8 positive binding begin failed");
    passed &= check(binding_bind(backend, 204, rows, &q8_binding),
                    "Q8 positive canonical binding failed");
    passed &= check(binding_seal(backend, 204),
                    "Q8 positive binding seal failed");
    passed &= check(audit_begin_v2(backend, 302, 1, 1),
                    "Q8 positive v2 audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "real Q8 ggml graph compute failed");
    ggml_npu_audit_snapshot_v2 positive_snapshot = {};
    passed &= check(audit_end_v2(backend, 302, &positive_snapshot),
                    "Q8 positive v2 audit did not close");
    passed &= check_exact_q8_audit(positive_snapshot);
    bool raw_oracle_matches = true;
    for (std::size_t element = 0; element < 1024; ++element) {
        std::uint32_t actual = 0;
        std::memcpy(&actual, dst_raw + element * 4, sizeof(actual));
        raw_oracle_matches &=
            actual == kQ8Expected[element % kQ8Expected.size()];
    }
    passed &= check(raw_oracle_matches,
                    "Q8 raw FP32 1024-word oracle mismatch");

    // A sealed node is single-use per audit.  The second graph compute must
    // stop before a second REQUIRED command or destination publication.
    std::memset(dst_raw, 0xa5, kDstBytes);
    passed &= check(binding_begin(backend, 205, 1),
                    "Q8 duplicate binding begin failed");
    passed &= check(binding_bind(backend, 205, rows, &q8_binding),
                    "Q8 duplicate binding insert failed");
    passed &= check(binding_seal(backend, 205),
                    "Q8 duplicate binding seal failed");
    passed &= check(audit_begin_v2(backend, 303, 1, 1),
                    "Q8 duplicate v2 audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "Q8 first duplicate-probe execution failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 duplicate execution was accepted");
    ggml_npu_audit_snapshot_v2 duplicate_snapshot = {};
    passed &= check(!audit_end_v2(backend, 303, &duplicate_snapshot),
                    "Q8 duplicate audit unexpectedly closed");
    passed &= check(duplicate_snapshot.coverage_duplicate == 1 &&
                        duplicate_snapshot.required_enqueued == 1 &&
                        duplicate_snapshot.required_successfully_covered == 1 &&
                        duplicate_snapshot.executed_by_verilator == 1 &&
                        duplicate_snapshot.commands_accepted == 1 &&
                        duplicate_snapshot.commands_terminal_success == 1 &&
                        duplicate_snapshot.commands_terminal_failure == 0 &&
                        duplicate_snapshot.cpu_fallback_attempts == 0 &&
                        duplicate_snapshot.host_tensor_ops == 0,
                    "Q8 duplicate ledger did not fail closed");

    if (passed) {
        std::printf(
            "[NPU-BACKEND-Q8-GET-ROWS][PASS] graph=ggml_backend_graph_compute "
            "shape=D1024/N1/V248320/stride1088 index=V-1 "
            "owner=q8-get-rows-not-P00 required_delta=1/1 "
            "required_enqueued=%llu required_completed=%llu executed=%llu "
            "commands=1/1/0 read=1296 write=4096 elements=1024 "
            "raw_fp32=1024/1024 identity=full256 "
            "cpu_fallback_attempts=%llu host_tensor_arithmetic=%llu "
            "negatives=missing-binding+bad-src-dtype+bad-index-dtype+bad-shape+"
            "bad-op-params+index-oob+duplicate-execution canonical_id=%s\n",
            static_cast<unsigned long long>(
                positive_snapshot.required_enqueued),
            static_cast<unsigned long long>(
                positive_snapshot.required_successfully_covered),
            static_cast<unsigned long long>(
                positive_snapshot.executed_by_verilator),
            static_cast<unsigned long long>(
                positive_snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(positive_snapshot.host_tensor_ops),
            canonical_text);
    }

    cleanup();
    return passed ? 0 : 56;
}

int run_q8_gemv_graph_test(
        const char * backend_path,
        const char * canonical_text) {
    check_phase = "NPU-BACKEND-Q8-GEMV";
    checks = 0;
    constexpr std::size_t kAlignment = 32;
    constexpr std::uint32_t kK = 1024;
    constexpr std::uint32_t kM = 16;
    constexpr std::size_t kActivationBytes = 4096;
    constexpr std::size_t kWeightRowBytes = 1088;
    constexpr std::size_t kWeightBytes = 17408;
    constexpr std::size_t kDstBytes = 64;
    constexpr std::uint32_t kGraphNodeIndex = 28;
    constexpr std::array<std::uint32_t, 16> kExpected = {
        0x473d6500U, 0xc5fc0800U, 0x00000000U, 0x00000000U,
        0x00000000U, 0x00000000U, 0x00000000U, 0x00000000U,
        0x00000000U, 0x00000000U, 0x00000000U, 0x00000000U,
        0x00000000U, 0x00000000U, 0x00000000U, 0x00000000U,
    };
    constexpr std::array<std::uint32_t, 8> kActivationBlock0 = {
        0xc2fe0000U, 0xc2800000U, 0xbf800000U, 0x00000000U,
        0x3f800000U, 0x427c0000U, 0x42800000U, 0x42fe0000U,
    };
    constexpr std::array<std::uint8_t, 8> kWeightBlock0 = {
        0x81U, 0xc0U, 0xffU, 0x00U, 0x01U, 0x3fU, 0x40U, 0x7fU,
    };

    const qwen_q8_gemv_manifest::profile * minimal_profile = nullptr;
    const qwen_q8_gemv_manifest::canonical_node * minimal_node = nullptr;
    const qwen_q8_gemv_manifest::profile * terminal_profile = nullptr;
    const qwen_q8_gemv_manifest::canonical_node * terminal_node = nullptr;
    for (const auto & profile : qwen_q8_gemv_manifest::kProfiles) {
        if (profile.k == kK && profile.m == kM) {
            if (minimal_profile != nullptr) {
                return 60;
            }
            minimal_profile = &profile;
        }
        if (profile.profile_id == 9U && profile.k == kK &&
            profile.m == 248320U) {
            if (terminal_profile != nullptr) {
                return 60;
            }
            terminal_profile = &profile;
        }
    }
    std::size_t zero_cardinality_count = 0;
    for (const auto & node : qwen_q8_gemv_manifest::kCanonicalNodes) {
        zero_cardinality_count += node.allow_zero_cardinality ? 1U : 0U;
        if (node.graph_node_index == kGraphNodeIndex) {
            if (minimal_node != nullptr) {
                return 61;
            }
            minimal_node = &node;
        }
        if (node.graph_node_index == 1710U) {
            if (terminal_node != nullptr) {
                return 61;
            }
            terminal_node = &node;
        }
    }

    std::array<std::uint8_t, 32> canonical_id = {};
    if (!check(parse_canonical_id(canonical_text, &canonical_id),
               "expected lowercase Q8 GEMV canonical ID") ||
        !check(minimal_profile != nullptr && minimal_node != nullptr &&
                   minimal_profile->profile_id == 1 &&
                   minimal_node->profile_id == minimal_profile->profile_id &&
                   minimal_node->canonical_id == canonical_id,
               "Q8 GEMV canonical M16/K1024 identity mismatch") ||
        !check(terminal_profile != nullptr && terminal_node != nullptr &&
                   terminal_node->profile_id == terminal_profile->profile_id &&
                   terminal_node->allow_zero_cardinality &&
                   zero_cardinality_count == 1U &&
                   std::strcmp(terminal_node->dst_name, "result_output") == 0 &&
                   std::strcmp(
                       terminal_node->weight_name, "token_embd.weight") == 0 &&
                   std::strcmp(
                       terminal_node->activation_name, "result_norm") == 0,
               "Q8 GEMV canonical terminal-empty identity mismatch")) {
        return 62;
    }

    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 63;
    }
    ggml_backend_dev_t device = ggml_backend_reg_dev_get(registry, 0);
    auto audit_begin_v2 = reinterpret_cast<ggml_backend_npu_audit_begin_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_BEGIN_V2_PROC));
    auto audit_end_v2 = reinterpret_cast<ggml_backend_npu_audit_end_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_END_V2_PROC));
    auto binding_begin = reinterpret_cast<
        ggml_backend_npu_canonical_binding_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
    auto binding_bind = reinterpret_cast<
        ggml_backend_npu_canonical_binding_bind_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
    auto binding_seal = reinterpret_cast<
        ggml_backend_npu_canonical_binding_seal_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
    if (!check(device != nullptr, "missing NPU device") ||
        !check(audit_begin_v2 != nullptr && audit_end_v2 != nullptr &&
                   binding_begin != nullptr && binding_bind != nullptr &&
                   binding_seal != nullptr,
               "missing Q8 GEMV canonical/audit procs")) {
        ggml_backend_unload(registry);
        return 64;
    }

    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    ggml_init_params parameters = {
        8 * 1024 * 1024,
        nullptr,
        true,
    };
    ggml_context * context = ggml_init(parameters);
    void * activation_storage =
        std::aligned_alloc(kAlignment, kActivationBytes);
    void * weight_storage = std::aligned_alloc(kAlignment, kWeightBytes);
    void * dst_storage = std::aligned_alloc(kAlignment, kDstBytes);
    ggml_backend_buffer_t activation_buffer = nullptr;
    ggml_backend_buffer_t weight_buffer = nullptr;
    ggml_backend_buffer_t dst_buffer = nullptr;

    auto cleanup = [&]() {
        if (activation_buffer != nullptr) {
            ggml_backend_buffer_free(activation_buffer);
        }
        if (weight_buffer != nullptr) {
            ggml_backend_buffer_free(weight_buffer);
        }
        if (dst_buffer != nullptr) {
            ggml_backend_buffer_free(dst_buffer);
        }
        if (context != nullptr) {
            ggml_free(context);
        }
        std::free(activation_storage);
        std::free(weight_storage);
        std::free(dst_storage);
        if (backend != nullptr) {
            ggml_backend_free(backend);
        }
        ggml_backend_unload(registry);
    };

    if (!check(backend != nullptr && context != nullptr,
               "Q8 GEMV backend/context initialization failed") ||
        !check(activation_storage != nullptr && weight_storage != nullptr &&
                   dst_storage != nullptr,
               "Q8 GEMV aligned external allocation failed")) {
        cleanup();
        return 65;
    }

    ggml_tensor * weights =
        ggml_new_tensor_2d(context, GGML_TYPE_Q8_0, kK, kM);
    ggml_tensor * activation =
        ggml_new_tensor_2d(context, GGML_TYPE_F32, kK, 1);
    ggml_tensor * output = ggml_mul_mat(context, weights, activation);
    ggml_set_name(weights, "blk.0.ssm_alpha.weight");
    ggml_set_name(activation, "attn_norm-0");
    ggml_set_name(output, "node_28");
    ggml_cgraph * graph = ggml_new_graph(context);
    ggml_build_forward_expand(graph, output);
    bool passed = true;
    passed &= check(weights != nullptr && activation != nullptr &&
                        output != nullptr && graph != nullptr &&
                        ggml_graph_n_nodes(graph) == 1 &&
                        ggml_graph_node(graph, 0) == output,
                    "real ggml_mul_mat graph construction failed");
    passed &= check(apply_q8_gemv_tensor_spec(
                        weights, minimal_profile->weight) &&
                        apply_q8_gemv_tensor_spec(
                            activation, minimal_profile->activation) &&
                        apply_q8_gemv_tensor_spec(
                            output, minimal_profile->dst),
                    "canonical M16/K1024 metadata application failed");
    passed &= check(output->src[0] == weights &&
                        output->src[1] == activation &&
                        output->op == GGML_OP_MUL_MAT &&
                        weights->type == GGML_TYPE_Q8_0 &&
                        activation->type == GGML_TYPE_F32 &&
                        ggml_nbytes(weights) == kWeightBytes &&
                        ggml_nbytes(activation) == kActivationBytes &&
                        ggml_nbytes(output) == kDstBytes,
                    "Q8 GEMV GGML source/layout relation changed");
    if (!passed) {
        cleanup();
        return 66;
    }

    activation_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, activation_storage, kActivationBytes, kActivationBytes);
    weight_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, weight_storage, kWeightBytes, kWeightBytes);
    dst_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, dst_storage, kDstBytes, kDstBytes);
    passed &= check(activation_buffer != nullptr && weight_buffer != nullptr &&
                        dst_buffer != nullptr,
                    "Q8 GEMV mapped buffer creation failed");
    if (passed) {
        passed &= check(
            ggml_backend_tensor_alloc(
                activation_buffer, activation, activation_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 GEMV activation attachment failed");
        passed &= check(
            ggml_backend_tensor_alloc(
                weight_buffer, weights, weight_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 GEMV weight attachment failed");
        passed &= check(
            ggml_backend_tensor_alloc(dst_buffer, output, dst_storage) ==
                GGML_STATUS_SUCCESS,
            "Q8 GEMV destination attachment failed");
    }
    if (!passed) {
        cleanup();
        return 67;
    }

    auto * activation_raw =
        static_cast<std::uint8_t *>(activation_storage);
    auto * weight_raw = static_cast<std::uint8_t *>(weight_storage);
    auto * dst_raw = static_cast<std::uint8_t *>(dst_storage);
    auto store_u16_le = [](std::uint8_t * destination, std::uint16_t value) {
        destination[0] = static_cast<std::uint8_t>(value);
        destination[1] = static_cast<std::uint8_t>(value >> 8);
    };
    auto store_u32_le = [](std::uint8_t * destination, std::uint32_t value) {
        for (std::size_t byte = 0; byte < 4; ++byte) {
            destination[byte] =
                static_cast<std::uint8_t>(value >> (8 * byte));
        }
    };
    auto load_u32_le = [](const std::uint8_t * source) {
        std::uint32_t value = 0;
        for (std::size_t byte = 0; byte < 4; ++byte) {
            value |= static_cast<std::uint32_t>(source[byte]) << (8 * byte);
        }
        return value;
    };

    std::memset(activation_raw, 0, kActivationBytes);
    std::memset(weight_raw, 0, kWeightBytes);
    std::memset(dst_raw, 0xa5, kDstBytes);
    for (std::size_t lane = 0; lane < kActivationBlock0.size(); ++lane) {
        store_u32_le(activation_raw + lane * 4, kActivationBlock0[lane]);
    }
    for (std::size_t lane = 32; lane < 64; ++lane) {
        store_u32_le(activation_raw + lane * 4, 0x42fe0000U);
    }

    store_u16_le(weight_raw, 0x3c00U);
    for (std::size_t lane = 0; lane < kWeightBlock0.size(); ++lane) {
        weight_raw[2 + lane] = kWeightBlock0[lane];
    }
    store_u16_le(weight_raw + 34, 0x3c00U);
    std::memset(weight_raw + 36, 0x01, 32);
    store_u16_le(weight_raw + kWeightRowBytes, 0x3800U);
    std::memset(weight_raw + kWeightRowBytes + 2, 0x02, 32);
    store_u16_le(weight_raw + kWeightRowBytes + 34, 0xc000U);
    std::memset(weight_raw + kWeightRowBytes + 36, 0x01, 32);
    // Rows 2..15 retain explicit zero scale and payload bytes.  The destination
    // starts poisoned, and the runner requires one four-byte response per row.

    std::array<ggml_tensor *, qwen_q8_gemv_manifest::kProfileCount>
        profile_ops = {};
    for (const auto & profile : qwen_q8_gemv_manifest::kProfiles) {
        profile_ops[profile.profile_id] =
            make_q8_gemv_profile_op(context, profile);
        const qwen_q8_gemv_manifest::canonical_node * representative = nullptr;
        for (const auto & node : qwen_q8_gemv_manifest::kCanonicalNodes) {
            if (node.profile_id == profile.profile_id) {
                representative = &node;
                break;
            }
        }
        if (profile_ops[profile.profile_id] != nullptr &&
            representative != nullptr) {
            ggml_set_name(
                profile_ops[profile.profile_id], representative->dst_name);
            ggml_set_name(
                profile_ops[profile.profile_id]->src[0],
                representative->weight_name);
            ggml_set_name(
                profile_ops[profile.profile_id]->src[1],
                representative->activation_name);
        }
        passed &= check(profile_ops[profile.profile_id] != nullptr &&
                            representative != nullptr &&
                            ggml_backend_dev_supports_op(
                                device, profile_ops[profile.profile_id]),
                        "frozen Q8 GEMV profile was not admitted");
    }

    auto make_binding = [](
            const qwen_q8_gemv_manifest::canonical_node & node) {
        ggml_npu_canonical_node_binding_v1 binding = {};
        binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
        binding.graph_node_index = node.graph_node_index;
        std::memcpy(binding.canonical_id, node.canonical_id.data(),
                    node.canonical_id.size());
        return binding;
    };
    std::set<std::array<std::uint8_t, 32>> unique_ids;
    std::set<std::uint32_t> unique_indices;
    std::uint64_t cohort = 1000;
    for (const auto & node : qwen_q8_gemv_manifest::kCanonicalNodes) {
        unique_ids.insert(node.canonical_id);
        unique_indices.insert(node.graph_node_index);
        ggml_tensor * exact_op = profile_ops[node.profile_id];
        ggml_set_name(exact_op, node.dst_name);
        ggml_set_name(exact_op->src[0], node.weight_name);
        ggml_set_name(exact_op->src[1], node.activation_name);
        const auto binding = make_binding(node);
        passed &= check(binding_begin(backend, cohort, 1),
                        "Q8 GEMV exact-set binding begin failed");
        passed &= check(binding_bind(
                            backend, cohort, exact_op, &binding),
                        "Q8 GEMV exact canonical/profile binding failed");
        passed &= check(binding_seal(backend, cohort),
                        "Q8 GEMV exact-set binding seal failed");
        ++cohort;
    }
    passed &= check(unique_ids.size() ==
                        qwen_q8_gemv_manifest::kCanonicalNodeCount &&
                        unique_indices.size() ==
                        qwen_q8_gemv_manifest::kCanonicalNodeCount,
                    "Q8 GEMV generated canonical set is not unique");

    auto minimal_binding = make_binding(*minimal_node);
    const auto & other_node = qwen_q8_gemv_manifest::kCanonicalNodes.front();
    const qwen_q8_gemv_manifest::canonical_node * same_profile_other = nullptr;
    for (const auto & node : qwen_q8_gemv_manifest::kCanonicalNodes) {
        if (node.profile_id == minimal_node->profile_id &&
            node.graph_node_index != minimal_node->graph_node_index) {
            same_profile_other = &node;
            break;
        }
    }
    passed &= check(same_profile_other != nullptr,
                    "Q8 GEMV same-profile identity probe is missing");
    auto bad_identity = minimal_binding;
    bad_identity.canonical_id[0] ^= 0x80U;
    passed &= check(binding_begin(backend, cohort, 1),
                    "unknown-ID binding begin failed");
    passed &= check(!binding_bind(
                        backend, cohort, output, &bad_identity),
                    "unknown Q8 GEMV canonical ID was accepted");
    ++cohort;

    auto bad_index = minimal_binding;
    bad_index.graph_node_index = std::numeric_limits<std::uint64_t>::max();
    passed &= check(binding_begin(backend, cohort, 1),
                    "bad-index binding begin failed");
    passed &= check(!binding_bind(backend, cohort, output, &bad_index),
                    "Q8 GEMV canonical graph-index mismatch was accepted");
    ++cohort;

    auto cross_identity = minimal_binding;
    std::memcpy(cross_identity.canonical_id, other_node.canonical_id.data(),
                other_node.canonical_id.size());
    passed &= check(binding_begin(backend, cohort, 1),
                    "cross-identity binding begin failed");
    passed &= check(!binding_bind(
                        backend, cohort, output, &cross_identity),
                    "Q8 GEMV identity/index collision was accepted");
    ++cohort;

    if (same_profile_other != nullptr) {
        const auto same_profile_binding = make_binding(*same_profile_other);
        passed &= check(binding_begin(backend, cohort, 1),
                        "same-profile identity binding begin failed");
        passed &= check(!binding_bind(
                            backend, cohort, output, &same_profile_binding),
                        "same-profile tensor names masqueraded as another node");
        ++cohort;
    }

    passed &= check(binding_begin(backend, cohort, 1),
                    "profile-collision binding begin failed");
    passed &= check(!binding_bind(
                        backend, cohort, profile_ops[other_node.profile_id],
                        &minimal_binding),
                    "Q8 GEMV canonical/profile collision was accepted");
    ++cohort;

    ggml_set_name(output, "not-a-canonical-v5-node");
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "profile-only Q8 GEMV node identity was admitted");
    ggml_set_name(output, minimal_node->dst_name);
    const enum ggml_type saved_weight_type = weights->type;
    weights->type = GGML_TYPE_F16;
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "F16 attention MUL_MAT entered Q8 GEMV owner");
    weights->type = saved_weight_type;
    const enum ggml_type saved_activation_type = activation->type;
    activation->type = GGML_TYPE_F16;
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "bad Q8 GEMV activation dtype was admitted");
    activation->type = saved_activation_type;
    const std::int64_t saved_dst_ne0 = output->ne[0];
    output->ne[0] = 15;
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "bad Q8 GEMV destination shape was admitted");
    output->ne[0] = saved_dst_ne0;
    const std::size_t saved_weight_nb1 = weights->nb[1];
    weights->nb[1] += 34;
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "bad Q8 GEMV packed-row bound was admitted");
    weights->nb[1] = saved_weight_nb1;
    auto * output_params =
        reinterpret_cast<std::uint8_t *>(output->op_params);
    output_params[0] = 1;
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "bad Q8 GEMV op_params were admitted");
    output_params[0] = 0;
    std::swap(output->src[0], output->src[1]);
    passed &= check(!ggml_backend_dev_supports_op(device, output),
                    "reversed GGML Q8 GEMV source relation was admitted");
    std::swap(output->src[0], output->src[1]);

    // The missing-binding path must stop before a command is issued.
    passed &= check(!audit_begin_v2(backend, 2000, 1, 1),
                    "Q8 GEMV audit accepted missing canonical binding");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 GEMV graph executed without an active audit");

    // Host address overflow is rejected before enqueue and before any raw read.
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, output, &minimal_binding) &&
                        binding_seal(backend, cohort),
                    "Q8 GEMV overflow binding failed");
    ++cohort;
    passed &= check(audit_begin_v2(backend, 2001, 1, 1),
                    "Q8 GEMV overflow audit begin failed");
    void * saved_activation_data = activation->data;
    activation->data = reinterpret_cast<void *>(
        std::numeric_limits<std::uintptr_t>::max() - 1024);
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 GEMV host-range overflow was accepted");
    activation->data = saved_activation_data;
    ggml_npu_audit_snapshot_v2 overflow_snapshot = {};
    passed &= check(!audit_end_v2(backend, 2001, &overflow_snapshot) &&
                        overflow_snapshot.required_enqueued == 0 &&
                        overflow_snapshot.commands_accepted == 0 &&
                        overflow_snapshot.executed_by_verilator == 0 &&
                        overflow_snapshot.coverage_missing == 1 &&
                        overflow_snapshot.rtl_failures == 1,
                    "Q8 GEMV overflow did not fail before enqueue");

    // Aliased source storage is also rejected before public RTL submission.
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, output, &minimal_binding) &&
                        binding_seal(backend, cohort),
                    "Q8 GEMV alias binding failed");
    ++cohort;
    passed &= check(audit_begin_v2(backend, 2002, 1, 1),
                    "Q8 GEMV alias audit begin failed");
    activation->data = weights->data;
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 GEMV aliased source storage was accepted");
    activation->data = saved_activation_data;
    ggml_npu_audit_snapshot_v2 alias_snapshot = {};
    passed &= check(!audit_end_v2(backend, 2002, &alias_snapshot) &&
                        alias_snapshot.required_enqueued == 0 &&
                        alias_snapshot.commands_accepted == 0 &&
                        alias_snapshot.coverage_missing == 1 &&
                        alias_snapshot.rtl_failures == 1,
                    "Q8 GEMV alias did not fail before enqueue");

    std::memset(dst_raw, 0xa5, kDstBytes);
    passed &= check(ggml_backend_dev_supports_op(device, output),
                    "exact Q8 GEMV predicate rejected");
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, output, &minimal_binding) &&
                        binding_seal(backend, cohort),
                    "Q8 GEMV positive canonical binding failed");
    ++cohort;
    passed &= check(audit_begin_v2(backend, 2003, 1, 1),
                    "Q8 GEMV positive audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "real ggml_mul_mat Q8 GEMV compute failed");
    ggml_npu_audit_snapshot_v2 positive_snapshot = {};
    passed &= check(audit_end_v2(backend, 2003, &positive_snapshot),
                    "Q8 GEMV positive audit did not close");
    passed &= check_exact_q8_gemv_audit(positive_snapshot);
    bool raw_oracle_matches = true;
    for (std::size_t row = 0; row < kExpected.size(); ++row) {
        raw_oracle_matches &=
            load_u32_le(dst_raw + row * 4) == kExpected[row];
    }
    passed &= check(raw_oracle_matches,
                    "Q8 GEMV hard-coded 16-row raw oracle mismatch");

    std::memset(dst_raw, 0xa5, kDstBytes);
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, output, &minimal_binding) &&
                        binding_seal(backend, cohort),
                    "Q8 GEMV duplicate binding failed");
    passed &= check(audit_begin_v2(backend, 2004, 1, 1),
                    "Q8 GEMV duplicate audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "Q8 GEMV first duplicate-probe compute failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "Q8 GEMV duplicate execution was accepted");
    ggml_npu_audit_snapshot_v2 duplicate_snapshot = {};
    passed &= check(!audit_end_v2(backend, 2004, &duplicate_snapshot) &&
                        duplicate_snapshot.coverage_duplicate == 1 &&
                        duplicate_snapshot.required_enqueued == 1 &&
                        duplicate_snapshot.required_successfully_covered == 1 &&
                        duplicate_snapshot.executed_by_verilator == 1 &&
                        duplicate_snapshot.commands_accepted == 1 &&
                        duplicate_snapshot.commands_terminal_success == 1 &&
                        duplicate_snapshot.commands_terminal_failure == 0 &&
                        duplicate_snapshot.cpu_fallback_attempts == 0 &&
                        duplicate_snapshot.host_tensor_ops == 0,
                    "Q8 GEMV duplicate ledger did not fail closed");

    // The frozen Qwen terminal logits node is a real dynamic N=0 MUL_MAT.
    // It remains a required Q8 GEMV command with full canonical identity, but
    // its strictly validated zero-cardinality descriptor performs no physical
    // activation/weight/destination traffic and starts no GEMV portal work.
    ggml_tensor * terminal_weights = ggml_new_tensor_2d(
        context, GGML_TYPE_Q8_0, terminal_profile->k, terminal_profile->m);
    ggml_tensor * terminal_activation = ggml_new_tensor_2d(
        context, GGML_TYPE_F32, terminal_profile->k, 0);
    passed &= check(terminal_weights != nullptr &&
                        terminal_activation != nullptr &&
                        apply_q8_gemv_tensor_spec(
                            terminal_weights, terminal_profile->weight) &&
                        apply_q8_gemv_tensor_spec(
                            terminal_activation,
                            terminal_profile->activation),
                    "terminal-empty Q8 GEMV source construction failed");
    terminal_activation->ne[1] = 0;
    terminal_activation->nb[2] = 0;
    terminal_activation->nb[3] = 0;
    ggml_tensor * terminal_output =
        ggml_mul_mat(context, terminal_weights, terminal_activation);
    passed &= check(terminal_output != nullptr &&
                        apply_q8_gemv_tensor_spec(
                            terminal_output, terminal_profile->dst),
                    "terminal-empty Q8 GEMV destination construction failed");
    terminal_output->ne[1] = 0;
    terminal_output->nb[2] = 0;
    terminal_output->nb[3] = 0;
    ggml_set_name(terminal_weights, terminal_node->weight_name);
    ggml_set_name(terminal_activation, terminal_node->activation_name);
    ggml_set_name(terminal_output, terminal_node->dst_name);
    ggml_cgraph * terminal_graph = ggml_new_graph(context);
    if (terminal_graph != nullptr) {
        ggml_graph_add_node(terminal_graph, terminal_output);
    }
    passed &= check(terminal_graph != nullptr &&
                        ggml_graph_n_nodes(terminal_graph) == 1 &&
                        ggml_graph_node(terminal_graph, 0) == terminal_output &&
                        terminal_output->op == GGML_OP_MUL_MAT &&
                        terminal_output->src[0] == terminal_weights &&
                        terminal_output->src[1] == terminal_activation &&
                        ggml_nbytes(terminal_weights) ==
                            terminal_profile->weight_bytes &&
                        ggml_nbytes(terminal_activation) == 0 &&
                        ggml_nbytes(terminal_output) == 0 &&
                        terminal_weights->data == nullptr &&
                        terminal_activation->data == nullptr &&
                        terminal_output->data == nullptr,
                    "terminal-empty Q8 GEMV graph/layout was not exact");
    passed &= check(ggml_backend_dev_supports_op(device, terminal_output),
                    "exact canonical terminal-empty Q8 GEMV was not admitted");

    const std::int64_t terminal_saved_dst_ne1 = terminal_output->ne[1];
    terminal_output->ne[1] = 1;
    passed &= check(!ggml_backend_dev_supports_op(device, terminal_output),
                    "half-empty terminal Q8 GEMV destination was admitted");
    terminal_output->ne[1] = terminal_saved_dst_ne1;
    const std::int64_t terminal_saved_activation_ne1 =
        terminal_activation->ne[1];
    terminal_activation->ne[1] = 1;
    passed &= check(!ggml_backend_dev_supports_op(device, terminal_output),
                    "half-empty terminal Q8 GEMV activation was admitted");
    terminal_activation->ne[1] = terminal_saved_activation_ne1;
    const std::size_t terminal_saved_dst_nb2 = terminal_output->nb[2];
    terminal_output->nb[2] = terminal_profile->dst.nb[2];
    passed &= check(!ggml_backend_dev_supports_op(device, terminal_output),
                    "bad terminal-empty Q8 GEMV tail stride was admitted");
    terminal_output->nb[2] = terminal_saved_dst_nb2;
    ggml_set_name(terminal_output, "not-result_output");
    passed &= check(!ggml_backend_dev_supports_op(device, terminal_output),
                    "bad terminal-empty Q8 GEMV name was admitted");
    ggml_set_name(terminal_output, terminal_node->dst_name);

    const auto terminal_binding = make_binding(*terminal_node);
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, terminal_output,
                            &terminal_binding) &&
                        binding_seal(backend, cohort),
                    "terminal-empty Q8 GEMV canonical binding failed");
    ++cohort;
    passed &= check(audit_begin_v2(backend, 2010, 1, 1),
                    "terminal-empty Q8 GEMV audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, terminal_graph) ==
                        GGML_STATUS_SUCCESS,
                    "terminal-empty Q8 GEMV real command failed");
    ggml_npu_audit_snapshot_v2 terminal_snapshot = {};
    passed &= check(audit_end_v2(backend, 2010, &terminal_snapshot),
                    "terminal-empty Q8 GEMV audit did not close");
    passed &= check_exact_q8_gemv_empty_audit(terminal_snapshot);

    if (passed) {
        std::printf(
            "[NPU-BACKEND-Q8-GEMV-TERMINAL-EMPTY][PASS] "
            "graph_node=1710 profile=9 shape=M248320/K1024/N0 "
            "owner=q8-gemv system=1 required=1/1 commands=1/1/0 "
            "portal_transaction=1 portal_groups=0 read=0 write=0 "
            "q8_macs=0 elements=0 identity=full256 "
            "cpu_fallback_attempts=%llu host_tensor_arithmetic=%llu "
            "negatives=half-empty+tail-stride+name\n",
            static_cast<unsigned long long>(
                terminal_snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(terminal_snapshot.host_tensor_ops));
        std::printf(
            "[NPU-BACKEND-Q8-GEMV][PASS] graph=real-ggml_mul_mat "
            "shape=M16/K1024/B32 owner=q8-gemv-not-f32-alu-not-get-rows "
            "canonical_set=187 profiles=10 excluded_f16=12 "
            "required_delta=1/1 required_enqueued=%llu "
            "required_completed=%llu executed=%llu commands=1/1/0 "
            "read=4104 write=64 q8_macs=16384 elements=16 "
            "raw_fp32=16/16 identity=full256 "
            "cpu_fallback_attempts=%llu host_tensor_arithmetic=%llu "
            "negatives=missing-binding+bad-name-dtype-shape-opparams-source+"
            "unknown-id+identity-index-profile-collision+overflow+alias+"
            "duplicate-execution canonical_id=%s\n",
            static_cast<unsigned long long>(
                positive_snapshot.required_enqueued),
            static_cast<unsigned long long>(
                positive_snapshot.required_successfully_covered),
            static_cast<unsigned long long>(
                positive_snapshot.executed_by_verilator),
            static_cast<unsigned long long>(
                positive_snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(positive_snapshot.host_tensor_ops),
            canonical_text);
    }

    cleanup();
    return passed ? 0 : 68;
}

int run_sampler_argmax_graph_test(const char * backend_path) {
    check_phase = "NPU-BACKEND-SAMPLER-ARGMAX";
    checks = 0;
    const auto & profile = qwen_sampler_argmax_manifest::kProfile;
    constexpr std::size_t kAlignment = 32;
    constexpr std::size_t kDstStorageBytes = 32;
    const std::size_t elements = static_cast<std::size_t>(profile.src0_ne[0]);
    const std::size_t source_bytes = elements * sizeof(std::uint32_t);
    const std::uint64_t expected_read_bytes =
        (static_cast<std::uint64_t>(source_bytes) + 4U + 7U) &
        ~std::uint64_t{7};
    static_assert(qwen_sampler_argmax_manifest::kProfileCount == 1,
                  "strict sampler profile count changed");
    static_assert(qwen_sampler_argmax_manifest::kArgmaxNodeCount == 1,
                  "strict sampler canonical node count changed");
    static_assert(
        qwen_sampler_argmax_manifest::kManifestCounts.total == 1714,
        "fresh strict graph node count changed");
    static_assert(
        qwen_sampler_argmax_manifest::kManifestCounts.required == 1080,
        "fresh strict graph required count changed");

    bool passed = true;
    passed &= check(elements == 248320 && source_bytes == 993280 &&
                        source_bytes % kAlignment == 0,
                    "generated sampler vocabulary/storage count changed");
    passed &= check(profile.graph_node_index == 1713 &&
                        profile.source_node_index == 1712 &&
                        profile.profile_id == 0 &&
                        profile.op_id == static_cast<std::uint32_t>(
                            GGML_OP_ARGMAX) &&
                        profile.dst_type_id == static_cast<std::uint32_t>(
                            GGML_TYPE_I32) &&
                        profile.src0_type_id == static_cast<std::uint32_t>(
                            GGML_TYPE_F32),
                    "generated canonical sampler identity/profile changed");
    if (!passed) {
        return 80;
    }

    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "sampler ARGMAX dynamic backend load failed")) {
        return 81;
    }
    ggml_backend_dev_t device = ggml_backend_reg_dev_get(registry, 0);
    auto audit_begin_v2 = reinterpret_cast<ggml_backend_npu_audit_begin_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_BEGIN_V2_PROC));
    auto audit_end_v2 = reinterpret_cast<ggml_backend_npu_audit_end_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_END_V2_PROC));
    auto binding_begin = reinterpret_cast<
        ggml_backend_npu_canonical_binding_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
    auto binding_bind = reinterpret_cast<
        ggml_backend_npu_canonical_binding_bind_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
    auto binding_seal = reinterpret_cast<
        ggml_backend_npu_canonical_binding_seal_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
    if (!check(device != nullptr, "missing sampler ARGMAX NPU device") ||
        !check(audit_begin_v2 != nullptr && audit_end_v2 != nullptr &&
                   binding_begin != nullptr && binding_bind != nullptr &&
                   binding_seal != nullptr,
               "missing sampler ARGMAX canonical/audit procs")) {
        ggml_backend_unload(registry);
        return 82;
    }

    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    ggml_init_params parameters = {
        1024 * 1024,
        nullptr,
        true,
    };
    ggml_context * context = ggml_init(parameters);
    void * source_storage = std::aligned_alloc(kAlignment, source_bytes);
    void * dst_storage = std::aligned_alloc(kAlignment, kDstStorageBytes);
    ggml_backend_buffer_t source_buffer = nullptr;
    ggml_backend_buffer_t dst_buffer = nullptr;

    auto cleanup = [&]() {
        if (source_buffer != nullptr) {
            ggml_backend_buffer_free(source_buffer);
        }
        if (dst_buffer != nullptr) {
            ggml_backend_buffer_free(dst_buffer);
        }
        if (context != nullptr) {
            ggml_free(context);
        }
        std::free(source_storage);
        std::free(dst_storage);
        if (backend != nullptr) {
            ggml_backend_free(backend);
        }
        ggml_backend_unload(registry);
    };

    if (!check(backend != nullptr && context != nullptr,
               "sampler ARGMAX backend/context initialization failed") ||
        !check(source_storage != nullptr && dst_storage != nullptr,
               "sampler ARGMAX aligned external allocation failed")) {
        cleanup();
        return 83;
    }

    ggml_tensor * logits = ggml_new_tensor_1d(
        context, GGML_TYPE_F32, static_cast<std::int64_t>(elements));
    ggml_tensor * argmax = logits == nullptr ? nullptr :
        ggml_argmax(context, logits);
    if (logits != nullptr) {
        ggml_set_name(logits, profile.src0_name);
    }
    if (argmax != nullptr) {
        ggml_set_name(argmax, profile.dst_name);
        ggml_set_output(argmax);
    }
    ggml_cgraph * graph = ggml_new_graph(context);
    if (graph != nullptr && argmax != nullptr) {
        ggml_build_forward_expand(graph, argmax);
    }
    if (logits != nullptr && argmax != nullptr) {
        logits->flags = profile.src0_flags;
        argmax->flags = profile.dst_flags;
        for (std::size_t dimension = 0; dimension < 4; ++dimension) {
            logits->ne[dimension] = profile.src0_ne[dimension];
            logits->nb[dimension] = profile.src0_nb[dimension];
            argmax->ne[dimension] = profile.dst_ne[dimension];
            argmax->nb[dimension] = profile.dst_nb[dimension];
        }
    }

    bool op_params_zero = argmax != nullptr;
    if (argmax != nullptr) {
        for (std::uint8_t byte : argmax->op_params) {
            op_params_zero &= byte == 0;
        }
    }
    passed &= check(logits != nullptr && argmax != nullptr && graph != nullptr &&
                        ggml_graph_n_nodes(graph) == 1 &&
                        ggml_graph_node(graph, 0) == argmax,
                    "real ggml_argmax graph construction failed");
    passed &= check(logits != nullptr &&
                        logits->type == GGML_TYPE_F32 &&
                        logits->ne[0] == 248320 && logits->ne[1] == 1 &&
                        logits->ne[2] == 1 && logits->ne[3] == 1 &&
                        logits->nb[0] == 4 && logits->nb[1] == source_bytes &&
                        logits->nb[2] == source_bytes &&
                        logits->nb[3] == source_bytes &&
                        ggml_nbytes(logits) == source_bytes &&
                        std::strcmp(logits->name, profile.src0_name) == 0,
                    "sampler ARGMAX source differs from generated profile");
    passed &= check(argmax != nullptr &&
                        argmax->op == GGML_OP_ARGMAX &&
                        argmax->type == GGML_TYPE_I32 &&
                        argmax->src[0] == logits && argmax->src[1] == nullptr &&
                        argmax->ne[0] == 1 && argmax->ne[1] == 1 &&
                        argmax->ne[2] == 1 && argmax->ne[3] == 1 &&
                        argmax->nb[0] == 4 && argmax->nb[1] == 4 &&
                        argmax->nb[2] == 4 && argmax->nb[3] == 4 &&
                        ggml_nbytes(argmax) == 4 && op_params_zero &&
                        std::strcmp(argmax->name, profile.dst_name) == 0,
                    "sampler ARGMAX destination is not one I32 scalar");
    if (!passed) {
        cleanup();
        return 84;
    }

    source_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, source_storage, source_bytes, source_bytes);
    dst_buffer = ggml_backend_dev_buffer_from_host_ptr(
        device, dst_storage, kDstStorageBytes, 4);
    passed &= check(source_buffer != nullptr && dst_buffer != nullptr,
                    "sampler ARGMAX mapped buffer creation failed");
    if (passed) {
        passed &= check(
            ggml_backend_tensor_alloc(source_buffer, logits, source_storage) ==
                GGML_STATUS_SUCCESS,
            "sampler ARGMAX source tensor attachment failed");
        passed &= check(
            ggml_backend_tensor_alloc(dst_buffer, argmax, dst_storage) ==
                GGML_STATUS_SUCCESS,
            "sampler ARGMAX destination tensor attachment failed");
    }
    if (!passed) {
        cleanup();
        return 85;
    }

    std::vector<std::uint32_t> logits_bits(elements, 0xbf800000U);
    logits_bits[0] = 0x00000000U;
    logits_bits[123456] = 0x42c80000U;
    logits_bits[elements - 1] = 0x42c80000U;
    const std::uint32_t reference_token = test_only_ggml_argmax_f32(
        logits_bits.data(), logits_bits.size());
    std::memcpy(source_storage, logits_bits.data(), source_bytes);
    std::memset(dst_storage, 0xa5, kDstStorageBytes);
    passed &= check(reference_token == elements - 1,
                    "test-only ggml_vec_argmax_f32 tie oracle changed");
    passed &= check(ggml_backend_dev_supports_op(device, argmax),
                    "exact canonical sampler ARGMAX predicate rejected");

    ggml_npu_canonical_node_binding_v1 canonical_binding = {};
    canonical_binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
    canonical_binding.graph_node_index = profile.graph_node_index;
    std::memcpy(canonical_binding.canonical_id, profile.canonical_id.data(),
                profile.canonical_id.size());

    std::uint64_t cohort = 3000;
    ggml_set_name(argmax, "not-greedy_argmax");
    passed &= check(!ggml_backend_dev_supports_op(device, argmax),
                    "bad sampler ARGMAX name was admitted");
    passed &= check(binding_begin(backend, cohort, 1),
                    "bad-name sampler binding begin failed");
    passed &= check(!binding_bind(
                        backend, cohort, argmax, &canonical_binding),
                    "bad-name sampler acquired canonical binding");
    passed &= check(!binding_seal(backend, cohort),
                    "bad-name sampler cohort sealed");
    ggml_set_name(argmax, profile.dst_name);
    ++cohort;

    auto bad_canonical = canonical_binding;
    bad_canonical.canonical_id[0] ^= 1U;
    passed &= check(binding_begin(backend, cohort, 1),
                    "bad-canonical sampler binding begin failed");
    passed &= check(!binding_bind(backend, cohort, argmax, &bad_canonical),
                    "bad sampler canonical ID was accepted");
    passed &= check(!binding_seal(backend, cohort),
                    "bad-canonical sampler cohort sealed");
    ++cohort;

    passed &= check(!audit_begin_v2(backend, 4000, 1, 1),
                    "sampler ARGMAX audit accepted missing binding");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_FAILED,
                    "sampler ARGMAX graph executed without active audit");

    std::memset(dst_storage, 0xa5, kDstStorageBytes);
    passed &= check(binding_begin(backend, cohort, 1) &&
                        binding_bind(
                            backend, cohort, argmax, &canonical_binding) &&
                        binding_seal(backend, cohort),
                    "sampler ARGMAX positive canonical binding failed");
    passed &= check(audit_begin_v2(backend, 4001, 1, 1),
                    "sampler ARGMAX positive audit begin failed");
    passed &= check(ggml_backend_graph_compute(backend, graph) ==
                        GGML_STATUS_SUCCESS,
                    "real ggml_argmax NPU compute failed");
    ggml_npu_audit_snapshot_v2 snapshot = {};
    passed &= check(audit_end_v2(backend, 4001, &snapshot),
                    "sampler ARGMAX positive audit did not close");
    passed &= check_exact_sampler_argmax_audit(
        snapshot, expected_read_bytes, elements);

    std::int32_t actual_token = -1;
    std::memcpy(&actual_token, dst_storage, sizeof(actual_token));
    std::size_t untouched_tail_bytes = 0;
    const auto * dst_raw = static_cast<const std::uint8_t *>(dst_storage);
    for (std::size_t index = sizeof(actual_token);
         index < kDstStorageBytes; ++index) {
        untouched_tail_bytes += dst_raw[index] == 0xa5 ? 1U : 0U;
    }
    passed &= check(actual_token == static_cast<std::int32_t>(reference_token),
                    "NPU sampler token differs from test-only CPU oracle");
    passed &= check(untouched_tail_bytes ==
                        kDstStorageBytes - sizeof(actual_token),
                    "sampler ARGMAX wrote beyond one I32 scalar");
    passed &= check(std::memcmp(
                        source_storage, logits_bits.data(), source_bytes) == 0,
                    "sampler ARGMAX modified the F32 logits source");

    if (passed) {
        std::printf(
            "[NPU-BACKEND-SAMPLER-ARGMAX][PASS] "
            "graph=real-ggml_argmax graph_node=%u source_node=%u profile=%u "
            "shape=V%zu-to-I32-scalar owner=sampler-argmax "
            "required_delta=1/1 required_enqueued=%llu "
            "required_completed=%llu executed=%llu commands=1/1/0 "
            "read=%llu write=%llu elements=%llu token=%d/%u "
            "output_bytes=4 tail_untouched=%zu/%zu identity=full256 "
            "oracle=ggml_vec_argmax_f32-test-only "
            "full_vocab_host_exports=0 cpu_candidate_scans=0 "
            "cpu_fallback_attempts=%llu host_tensor_arithmetic=%llu "
            "negatives=missing-binding+bad-name+bad-canonical "
            "canonical_id=%s\n",
            profile.graph_node_index, profile.source_node_index,
            profile.profile_id, elements,
            static_cast<unsigned long long>(snapshot.required_enqueued),
            static_cast<unsigned long long>(
                snapshot.required_successfully_covered),
            static_cast<unsigned long long>(snapshot.executed_by_verilator),
            static_cast<unsigned long long>(snapshot.gmem_read_bytes),
            static_cast<unsigned long long>(snapshot.gmem_write_bytes),
            static_cast<unsigned long long>(snapshot.vector_elements),
            actual_token, reference_token, untouched_tail_bytes,
            kDstStorageBytes - sizeof(actual_token),
            static_cast<unsigned long long>(
                snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(snapshot.host_tensor_ops),
            qwen_sampler_argmax_manifest::kCanonicalIdHex);
    }

    cleanup();
    return passed ? 0 : 86;
}

int run_abi_test(int argc, char ** argv) {
    check_phase = "NPU-BACKEND-ABI";
    checks = 0;
    std::array<std::uint8_t, 32> canonical_id = {};
    if (!check(argc == 4 &&
                   std::strcmp(argv[2], "--canonical-id") == 0 &&
                   parse_canonical_id(argv[3], &canonical_id),
               "expected backend DSO path plus a lowercase canonical ID")) {
        return 2;
    }

    ggml_backend_reg_t registry = ggml_backend_load(argv[1]);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 3;
    }
    if (!check(std::strcmp(ggml_backend_reg_name(registry), "NPU") == 0,
               "registry name mismatch") ||
        !check(ggml_backend_reg_dev_count(registry) == 1,
               "device count mismatch")) {
        ggml_backend_unload(registry);
        return 4;
    }

    ggml_backend_dev_t device = ggml_backend_reg_dev_get(registry, 0);
    if (!check(device != nullptr, "missing NPU device") ||
        !check(std::strcmp(ggml_backend_dev_name(device), "NPU") == 0,
               "device name mismatch") ||
        !check(ggml_backend_dev_type(device) == GGML_BACKEND_DEVICE_TYPE_ACCEL,
               "device type mismatch")) {
        ggml_backend_unload(registry);
        return 5;
    }

    auto audit_begin = reinterpret_cast<ggml_backend_npu_audit_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_BEGIN_PROC));
    auto audit_end = reinterpret_cast<ggml_backend_npu_audit_end_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_END_PROC));
    auto audit_begin_v2 = reinterpret_cast<ggml_backend_npu_audit_begin_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_BEGIN_V2_PROC));
    auto audit_end_v2 = reinterpret_cast<ggml_backend_npu_audit_end_v2_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_AUDIT_END_V2_PROC));
    auto binding_begin = reinterpret_cast<
        ggml_backend_npu_canonical_binding_begin_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BEGIN_V1_PROC));
    auto binding_bind = reinterpret_cast<
        ggml_backend_npu_canonical_binding_bind_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_BIND_V1_PROC));
    auto binding_seal = reinterpret_cast<
        ggml_backend_npu_canonical_binding_seal_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_CANONICAL_BINDING_SEAL_V1_PROC));
    if (!check(audit_begin != nullptr, "missing v1 audit begin proc") ||
        !check(audit_end != nullptr, "missing v1 audit end proc") ||
        !check(audit_begin_v2 != nullptr, "missing v2 audit begin proc") ||
        !check(audit_end_v2 != nullptr, "missing v2 audit end proc") ||
        !check(binding_begin != nullptr, "missing canonical binding begin proc") ||
        !check(binding_bind != nullptr, "missing canonical binding bind proc") ||
        !check(binding_seal != nullptr, "missing canonical binding seal proc")) {
        ggml_backend_unload(registry);
        return 6;
    }

    ggml_backend_t backend = ggml_backend_dev_init(device, nullptr);
    if (!check(backend != nullptr, "backend init failed")) {
        ggml_backend_unload(registry);
        return 7;
    }

    ggml_init_params parameters = {
        2 * 1024 * 1024,
        nullptr,
        false,
    };
    ggml_context * context = ggml_init(parameters);
    if (!check(context != nullptr, "ggml context init failed")) {
        ggml_backend_free(backend);
        ggml_backend_unload(registry);
        return 8;
    }

    ggml_tensor * a4 = ggml_new_tensor_1d(context, GGML_TYPE_F32, 4);
    ggml_tensor * b4 = ggml_new_tensor_1d(context, GGML_TYPE_F32, 4);
    ggml_tensor * metadata = ggml_reshape_1d(context, a4, 4);
    ggml_tensor * unsupported_add = ggml_add(context, a4, b4);
    ggml_tensor * a16_storage =
        ggml_new_tensor_1d(context, GGML_TYPE_F32, 16);
    ggml_tensor * a16 = ggml_view_4d(
        context, a16_storage, 16, 1, 1, 1, 64, 64, 64, 0);
    ggml_tensor * b16 = ggml_new_tensor_1d(context, GGML_TYPE_F32, 16);
    ggml_tensor * exact_add = ggml_add(context, a16, b16);
    ggml_tensor * collision_mul = make_profile_op(
        context, kTestProfiles[4]);
    metadata->flags |= GGML_TENSOR_FLAG_COMPUTE;
    unsupported_add->flags |= GGML_TENSOR_FLAG_COMPUTE;
    exact_add->flags |= GGML_TENSOR_FLAG_COMPUTE;
    if (collision_mul != nullptr) {
        collision_mul->flags |= GGML_TENSOR_FLAG_COMPUTE;
    }

    std::memcpy(a16->data, kF32Input0.data(), sizeof(kF32Input0));
    std::memcpy(b16->data, kF32Input1.data(), sizeof(kF32Input1));

    ggml_cgraph * metadata_graph = ggml_new_graph(context);
    ggml_build_forward_expand(metadata_graph, metadata);
    ggml_cgraph * unsupported_graph = ggml_new_graph(context);
    ggml_build_forward_expand(unsupported_graph, unsupported_add);
    ggml_cgraph * exact_graph = ggml_new_graph(context);
    ggml_build_forward_expand(exact_graph, exact_add);
    ggml_cgraph * collision_graph = ggml_new_graph(context);
    if (collision_mul != nullptr) {
        ggml_build_forward_expand(collision_graph, collision_mul);
    }

    bool passed = true;
    passed &= check(!ggml_backend_dev_supports_op(device, unsupported_add),
                    "4-element ADD must be unsupported");
    passed &= check(ggml_backend_dev_supports_op(device, exact_add),
                    "exact F32 ADD[16] predicate rejected");
    passed &= check(collision_mul != nullptr &&
                    ggml_backend_dev_supports_op(device, collision_mul),
                    "exact F32 MUL[16] collision probe rejected");
    void * saved_a16_data = a16->data;
    void * saved_b16_data = b16->data;
    void * saved_exact_data = exact_add->data;
    a16->data = nullptr;
    b16->data = nullptr;
    exact_add->data = nullptr;
    passed &= check(ggml_backend_dev_supports_op(device, exact_add),
                    "metadata-only P00 predicate required raw storage");
    a16->data = saved_a16_data;
    b16->data = saved_b16_data;
    exact_add->data = saved_exact_data;
    passed &= check(
        ggml_backend_graph_compute(backend, metadata_graph) ==
            GGML_STATUS_FAILED,
        "graph without audit begin must fail");

    // Existing v1 metadata/MM2-era ABI behavior remains intact.
    passed &= check(audit_begin(backend, 11, 0, 0),
                    "metadata audit begin failed");
    passed &= check(
        ggml_backend_graph_compute(backend, metadata_graph) ==
            GGML_STATUS_SUCCESS,
        "metadata graph under audit failed");
    ggml_npu_audit_snapshot_v1 metadata_snapshot = {};
    passed &= check(audit_end(backend, 11, &metadata_snapshot),
                    "metadata audit end failed");
    passed &= check(metadata_snapshot.abi_version ==
                        GGML_NPU_AUDIT_ABI_VERSION,
                    "v1 audit ABI mismatch");
    passed &= check(metadata_snapshot.executed_by_verilator == 0,
                    "metadata counted as RTL execution");

    passed &= check(audit_begin(backend, 12, 1, 1),
                    "unsupported audit begin failed");
    passed &= check(
        ggml_backend_graph_compute(backend, unsupported_graph) ==
            GGML_STATUS_FAILED,
        "unsupported arithmetic graph must fail");
    ggml_npu_audit_snapshot_v1 unsupported_v1_snapshot = {};
    passed &= check(!audit_end(backend, 12, &unsupported_v1_snapshot),
                    "failed arithmetic v1 audit must not pass");
    passed &= check(unsupported_v1_snapshot.unsupported_required == 1,
                    "v1 unsupported count mismatch");
    passed &= check(unsupported_v1_snapshot.executed_by_verilator == 0,
                    "unsupported op counted as RTL execution");

    passed &= check(audit_begin(backend, 13, 0, 0),
                    "v1 audit did not recover after failure");
    ggml_npu_audit_snapshot_v1 recovery_snapshot = {};
    passed &= check(audit_end(backend, 13, &recovery_snapshot),
                    "v1 audit recovery end failed");

    auto make_binding = [&](std::uint64_t graph_node_index) {
        ggml_npu_canonical_node_binding_v1 binding = {};
        binding.abi_version = GGML_NPU_CANONICAL_BINDING_ABI_VERSION;
        binding.graph_node_index = graph_node_index;
        std::memcpy(binding.canonical_id, canonical_id.data(),
                    canonical_id.size());
        return binding;
    };

    // Audit v2 is inseparable from a complete, unique canonical node binding.
    check_phase = "NPU-BACKEND-CANONICAL-BINDING";
    passed &= check(!audit_begin_v2(backend, 20, 1, 1),
                    "v2 audit accepted a missing canonical binding");

    auto binding_30 = make_binding(30);
    passed &= check(binding_begin(backend, 100, 2),
                    "duplicate-pointer binding begin failed");
    passed &= check(binding_bind(backend, 100, exact_add, &binding_30),
                    "first duplicate-pointer binding failed");
    auto binding_31 = make_binding(31);
    passed &= check(!binding_bind(backend, 100, exact_add, &binding_31),
                    "duplicate tensor pointer was accepted");
    passed &= check(!binding_seal(backend, 100),
                    "invalid duplicate-pointer batch sealed");

    passed &= check(binding_begin(backend, 101, 2),
                    "profile-collision binding begin failed");
    passed &= check(binding_bind(backend, 101, exact_add, &binding_30),
                    "first profile-collision binding failed");
    passed &= check(!binding_bind(
                        backend, 101, collision_mul, &binding_31),
                    "canonical identity/profile collision was accepted");
    passed &= check(!binding_seal(backend, 101),
                    "identity/profile-colliding batch sealed");

    passed &= check(binding_begin(backend, 102, 1),
                    "missing-node binding begin failed");
    passed &= check(binding_bind(backend, 102, exact_add, &binding_30),
                    "missing-node binding insert failed");
    passed &= check(binding_seal(backend, 102),
                    "missing-node binding seal failed");
    passed &= check(audit_begin_v2(backend, 30, 1, 1),
                    "missing-node audit begin failed");
    passed &= check(
        ggml_backend_graph_compute(backend, collision_graph) ==
            GGML_STATUS_FAILED,
        "unbound graph node unexpectedly executed");
    ggml_npu_audit_snapshot_v2 missing_snapshot = {};
    passed &= check(!audit_end_v2(backend, 30, &missing_snapshot),
                    "missing-node audit unexpectedly closed");
    passed &= check(missing_snapshot.coverage_missing == 1 &&
                    missing_snapshot.required_enqueued == 0 &&
                    missing_snapshot.required_successfully_covered == 0 &&
                    missing_snapshot.executed_by_verilator == 0,
                    "missing-node ledger mismatch");

    passed &= check(binding_begin(backend, 103, 1),
                    "duplicate-completion binding begin failed");
    passed &= check(binding_bind(backend, 103, exact_add, &binding_30),
                    "duplicate-completion binding insert failed");
    passed &= check(binding_seal(backend, 103),
                    "duplicate-completion binding seal failed");
    passed &= check(audit_begin_v2(backend, 31, 1, 1),
                    "duplicate-completion audit begin failed");
    passed &= check(
        ggml_backend_graph_compute(backend, exact_graph) ==
            GGML_STATUS_SUCCESS,
        "first canonical execution failed");
    passed &= check(
        ggml_backend_graph_compute(backend, exact_graph) ==
            GGML_STATUS_FAILED,
        "duplicate canonical execution was accepted");
    ggml_npu_audit_snapshot_v2 duplicate_snapshot = {};
    passed &= check(!audit_end_v2(backend, 31, &duplicate_snapshot),
                    "duplicate-completion audit unexpectedly closed");
    passed &= check(duplicate_snapshot.coverage_duplicate == 1 &&
                    duplicate_snapshot.required_enqueued == 1 &&
                    duplicate_snapshot.required_successfully_covered == 1 &&
                    duplicate_snapshot.executed_by_verilator == 1,
                    "duplicate-completion ledger mismatch");

    // Real ggml graph production lowering: a manifest-derived canonical P00
    // identity launches one REQUIRED RTL transaction and publishes raw F32.
    check_phase = "NPU-BACKEND-F32-ADD";
    passed &= check(binding_begin(backend, 104, 1),
                    "exact canonical binding begin failed");
    passed &= check(binding_bind(backend, 104, exact_add, &binding_30),
                    "exact canonical binding insert failed");
    passed &= check(binding_seal(backend, 104),
                    "exact canonical binding seal failed");
    passed &= check(audit_begin_v2(backend, 21, 1, 1),
                    "exact v2 audit begin failed");
    passed &= check(
        ggml_backend_graph_compute(backend, exact_graph) ==
            GGML_STATUS_SUCCESS,
        "exact ADD[16] graph failed");
    ggml_npu_audit_snapshot_v2 exact_snapshot = {};
    passed &= check(audit_end_v2(backend, 21, &exact_snapshot),
                    "exact v2 audit did not close");
    passed &= check_exact_audit(exact_snapshot);
    std::array<std::uint32_t, 16> exact_output = {};
    std::memcpy(exact_output.data(), exact_add->data, sizeof(exact_output));
    passed &= check(exact_output == kF32Expected,
                    "exact ADD[16] raw-bit oracle mismatch");
    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-ADD][PASS] required_enqueued=%llu "
            "required_completed=%llu executed=%llu commands_accepted=%llu "
            "completion_success=%llu completion_failure=%llu "
            "coverage_missing=%llu coverage_duplicate=%llu "
            "coverage_hash_mismatch=%llu completion_identity_mismatch=%llu "
            "gmem_errors=%llu timeout_errors=%llu "
            "cpu_fallback_attempts=%llu host_tensor_arithmetic=%llu "
            "read_bytes=%llu write_bytes=%llu elements=%llu "
            "required_rtl_delta=1/1 canonical_id=%s\n",
            static_cast<unsigned long long>(exact_snapshot.required_enqueued),
            static_cast<unsigned long long>(
                exact_snapshot.required_successfully_covered),
            static_cast<unsigned long long>(
                exact_snapshot.executed_by_verilator),
            static_cast<unsigned long long>(exact_snapshot.commands_accepted),
            static_cast<unsigned long long>(
                exact_snapshot.commands_terminal_success),
            static_cast<unsigned long long>(
                exact_snapshot.commands_terminal_failure),
            static_cast<unsigned long long>(exact_snapshot.coverage_missing),
            static_cast<unsigned long long>(exact_snapshot.coverage_duplicate),
            static_cast<unsigned long long>(
                exact_snapshot.coverage_hash_mismatch),
            static_cast<unsigned long long>(
                exact_snapshot.completion_identity_mismatch),
            static_cast<unsigned long long>(exact_snapshot.gmem_errors),
            static_cast<unsigned long long>(exact_snapshot.timeout_errors),
            static_cast<unsigned long long>(
                exact_snapshot.cpu_fallback_attempts),
            static_cast<unsigned long long>(exact_snapshot.host_tensor_ops),
            static_cast<unsigned long long>(exact_snapshot.gmem_read_bytes),
            static_cast<unsigned long long>(exact_snapshot.gmem_write_bytes),
            static_cast<unsigned long long>(exact_snapshot.vector_elements),
            argv[3]);
    }

    // An unsupported shape cannot create a canonical exact-profile binding,
    // so v2 admission fails before any command or arithmetic starts.
    check_phase = "NPU-BACKEND-F32-ADD-UNSUPPORTED";
    passed &= check(binding_begin(backend, 105, 1),
                    "unsupported binding begin failed");
    auto unsupported_binding = make_binding(4);
    passed &= check(!binding_bind(
                        backend, 105, unsupported_add,
                        &unsupported_binding),
                    "unsupported shape acquired a canonical binding");
    passed &= check(!binding_seal(backend, 105),
                    "unsupported binding batch sealed");
    passed &= check(!audit_begin_v2(backend, 22, 1, 1),
                    "unsupported v2 admission unexpectedly succeeded");
    passed &= check(
        ggml_backend_graph_compute(backend, unsupported_graph) ==
            GGML_STATUS_FAILED,
        "unsupported shape unexpectedly executed");
    if (passed) {
        std::printf(
            "[NPU-BACKEND-F32-ADD-UNSUPPORTED][PASS] shape=4 "
            "admission=fail required_enqueued=0 required_completed=0 "
            "executed=0 commands=0 cpu_fallback_attempts=not_observed "
            "host_tensor_arithmetic=not_observed\n");
    }

    ggml_free(context);
    ggml_backend_free(backend);
    ggml_backend_unload(registry);

    if (!passed) {
        return 9;
    }
    std::printf(
        "[NPU-BACKEND-ABI][PASS] checks=%d metadata=preserved "
        "exact16=required-canonical-verilated "
        "canonical-binding=duplicate+missing+profile-collision-fail-closed "
        "unsupported=fail-closed audit=v1+v2\n",
        checks);
    return 0;
}

int run_rtl_self_test(const char * backend_path) {
    check_phase = "NPU-BACKEND-RTL";
    checks = 0;
    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 10;
    }

    auto self_test = reinterpret_cast<ggml_backend_npu_rtl_self_test_v1_fn>(
        ggml_backend_reg_get_proc_address(
            registry, GGML_NPU_RTL_SELF_TEST_PROC));
    if (!check(self_test != nullptr, "missing Verilated RTL self-test proc")) {
        ggml_backend_unload(registry);
        return 11;
    }

    ggml_npu_rtl_self_test_result_v1 result = {};
    bool passed = true;
    passed &= check(self_test(&result),
                    "Verilated RTL self-test returned failure");
    passed &= check(result.abi_version ==
                        GGML_NPU_RTL_SELF_TEST_ABI_VERSION,
                    "RTL self-test ABI mismatch");
    passed &= check(result.passed == 1, "RTL self-test did not report passed=1");
    passed &= check(result.rtl_cycles == 29, "RTL TIU cycle count mismatch");
    passed &= check(result.output_bytes == 16, "RTL output byte count mismatch");
    passed &= check(result.error_code == 0,
                    "RTL self-test error code was nonzero");
    ggml_backend_unload(registry);

    if (!passed) {
        return 12;
    }
    std::printf("[NPU-BACKEND-RTL][PASS] cycles=%llu bytes=%llu error=%u\n",
                static_cast<unsigned long long>(result.rtl_cycles),
                static_cast<unsigned long long>(result.output_bytes),
                result.error_code);
    return 0;
}

const char * f32_mode_name(std::uint32_t mode) {
    switch (mode) {
        case GGML_NPU_F32_ADD_MODE_POSITIVE:
            return "positive";
        case GGML_NPU_F32_ADD_MODE_UNKNOWN_KERNEL:
            return "unknown-kernel";
        case GGML_NPU_F32_ADD_MODE_OUT_OF_RANGE_4MOD8:
            return "out-of-range-4mod8";
        case GGML_NPU_F32_ADD_MODE_REQ_READY_LOW:
            return "req-ready-low";
        case GGML_NPU_F32_ADD_MODE_OVERPERMISSION:
            return "overpermission";
        default:
            return "invalid";
    }
}

int run_f32_mode_test(const char * backend_path, std::uint32_t mode) {
    check_phase = "NPU-BACKEND-F32-MODE";
    checks = 0;
    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 20;
    }
    auto self_test =
        reinterpret_cast<ggml_backend_npu_f32_add_self_test_v2_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_F32_ADD_SELF_TEST_PROC));
    if (!check(self_test != nullptr, "missing F32 ADD self-test v2 proc")) {
        ggml_backend_unload(registry);
        return 21;
    }

    ggml_npu_f32_add_self_test_result_v2 result = {};
    bool passed = true;
    passed &= check(self_test(mode, &result), "F32 ADD mode returned failure");
    passed &= check(result.abi_version ==
                        GGML_NPU_F32_ADD_SELF_TEST_ABI_VERSION,
                    "F32 ADD self-test ABI mismatch");
    passed &= check(result.mode == mode, "F32 ADD mode echo mismatch");
    passed &= check(result.passed == 1, "F32 ADD mode passed was zero");
    passed &= check(result.runner_error_code == 0,
                    "F32 ADD runner error was nonzero");
    passed &= check(result.commands_accepted == 1,
                    "F32 ADD accepted count mismatch");
    passed &= check(result.completion_identity_match == 1 &&
                    result.completion_framing_valid == 1 &&
                    result.completion_stable == 1 &&
                    result.recovery_clean == 1,
                    "completion hold/framing/recovery mismatch");
    passed &= check(result.gmem_requests_accepted ==
                        result.gmem_responses_accepted,
                    "GMEM request/response count mismatch");
    passed &= check(result.rtl_cycles > 0, "F32 ADD RTL cycles were zero");

    if (mode == GGML_NPU_F32_ADD_MODE_POSITIVE) {
        passed &= check(result.controlled_reject == 0,
                        "positive mode reported reject");
        passed &= check(result.completion_status == 0 &&
                        result.completion_error_class == 0 &&
                        result.completion_error_code == 0,
                        "positive terminal payload mismatch");
        passed &= check(result.gmem_read_bytes == 0 &&
                        result.gmem_write_bytes == 0 &&
                        result.vector_elements == 16 &&
                        result.f32_start_count == 1,
                        "positive work counters mismatch");
        passed &= check(result.commands_terminal_success == 1 &&
                        result.commands_terminal_failure == 0 &&
                        result.gmem_requests_accepted == 0 &&
                        result.result_bytes == 64,
                        "positive command/GMEM counters mismatch");
    } else {
        std::uint32_t expected_status = 0;
        std::uint32_t expected_class = 0;
        std::uint64_t expected_f32_starts = 0;
        if (mode == GGML_NPU_F32_ADD_MODE_UNKNOWN_KERNEL) {
            expected_status = 14;
            expected_class = 3;
        } else if (mode == GGML_NPU_F32_ADD_MODE_OUT_OF_RANGE_4MOD8) {
            expected_status = 16;
            expected_class = 5;
        } else if (mode == GGML_NPU_F32_ADD_MODE_OVERPERMISSION) {
            expected_status = 16;
            expected_class = 5;
        } else {
            expected_status = 17;
            expected_class = 10;
            expected_f32_starts = 1;
        }
        passed &= check(result.controlled_reject == 1,
                        "negative mode did not report controlled reject");
        passed &= check(result.completion_status == expected_status &&
                        result.completion_error_code == expected_status &&
                        result.completion_error_class == expected_class,
                        "negative terminal payload mismatch");
        passed &= check(result.gmem_read_bytes == 0 &&
                        result.gmem_write_bytes == 0 &&
                        result.vector_elements == 0 &&
                        result.f32_start_count == expected_f32_starts,
                        "negative work counters mismatch");
        passed &= check(result.commands_terminal_success == 0 &&
                        result.commands_terminal_failure == 1 &&
                        result.gmem_requests_accepted == 0 &&
                        result.result_bytes == 0,
                        "negative command/GMEM counters mismatch");
    }
    ggml_backend_unload(registry);
    if (!passed) {
        return 22;
    }
    std::printf(
        "[NPU-BACKEND-F32-MODE][PASS] mode=%s status=%u class=%u "
        "f32_starts=%llu read=%llu write=%llu elements=%llu "
        "requests=%llu responses=%llu stable=%u recovery=%u\n",
        f32_mode_name(mode),
        result.completion_status,
        result.completion_error_class,
        static_cast<unsigned long long>(result.f32_start_count),
        static_cast<unsigned long long>(result.gmem_read_bytes),
        static_cast<unsigned long long>(result.gmem_write_bytes),
        static_cast<unsigned long long>(result.vector_elements),
        static_cast<unsigned long long>(result.gmem_requests_accepted),
        static_cast<unsigned long long>(result.gmem_responses_accepted),
        result.completion_stable,
        result.recovery_clean);
    return 0;
}

int run_f32_alu_mode_test(
        const char * backend_path,
        std::uint32_t profile_id,
        std::uint32_t mode) {
    check_phase = "NPU-BACKEND-F32-ALU-V4";
    checks = 0;
    if (!check(profile_id < kTestProfiles.size(), "profile ID out of range") ||
        !check(mode <= GGML_NPU_F32_ALU_MODE_REQ_READY_LOW,
               "mode out of range")) {
        return 40;
    }
    ggml_backend_reg_t registry = ggml_backend_load(backend_path);
    if (!check(registry != nullptr, "dynamic backend load failed")) {
        return 41;
    }
    auto self_test =
        reinterpret_cast<ggml_backend_npu_f32_alu_self_test_v4_fn>(
            ggml_backend_reg_get_proc_address(
                registry, GGML_NPU_F32_ALU_SELF_TEST_V4_PROC));
    if (!check(self_test != nullptr, "missing F32 ALU self-test v4 proc")) {
        ggml_backend_unload(registry);
        return 42;
    }

    const test_profile & profile = kTestProfiles[profile_id];
    ggml_npu_f32_alu_self_test_result_v4 result = {};
    bool passed = true;
    passed &= check(self_test(profile_id, mode, &result),
                    "F32 ALU v4 call returned failure");
    passed &= check(result.abi_version ==
                        GGML_NPU_F32_ALU_SELF_TEST_V4_ABI_VERSION,
                    "F32 ALU v4 ABI mismatch");
    passed &= check(result.profile_id == profile_id && result.mode == mode,
                    "profile/mode echo mismatch");
    passed &= check(result.passed == 1 && result.runner_error_code == 0,
                    "runner did not report exact pass");
    passed &= check(result.commands_accepted == 1,
                    "accepted command count mismatch");
    passed &= check(result.completion_identity_match == 1 &&
                    result.completion_framing_valid == 1 &&
                    result.completion_stable == 1 &&
                    result.recovery_clean == 1,
                    "completion identity/framing/hold/recovery mismatch");
    passed &= check(result.completion_emitted == 1 &&
                    result.completion_accepted == 1,
                    "completion emitted/accepted stages collapsed");
    passed &= check(result.submitted_profile_id ==
                        result.observed_profile_id,
                    "RTL-returned profile mismatch");
    passed &= check(result.required_issued_delta == 0 &&
                    result.required_completed_delta == 0,
                    "representative polluted required counters");
    passed &= check(result.gmem_requests_accepted ==
                        result.gmem_responses_accepted,
                    "GMEM request/response mismatch");
    passed &= check(result.rtl_cycles > 0, "zero RTL cycle count");

    if (mode == GGML_NPU_F32_ALU_MODE_POSITIVE) {
        passed &= check(result.controlled_reject == 0 &&
                        result.private_shadow_committed == 1,
                        "positive did not commit private shadow");
        passed &= check(result.submitted_profile_id == profile_id &&
                        result.observed_profile_id == profile_id &&
                        result.representative_identity_match == 1 &&
                        representative_identity_matches(
                            profile_id, result.submitted_identity) &&
                        representative_identity_matches(
                            profile_id, result.returned_identity),
                        "positive representative identity mismatch");
        passed &= check(result.completion_status == 0 &&
                        result.completion_error_class == 0 &&
                        result.completion_error_code == 0,
                        "positive terminal payload mismatch");
        passed &= check(result.gmem_read_bytes == 0 &&
                        result.gmem_write_bytes == 0 &&
                        result.vector_elements == profile.total_elements,
                        "positive pure-RTL raw32-portal/GMEM ledger mismatch");
        passed &= check(result.commands_terminal_success == 1 &&
                        result.commands_terminal_failure == 0 &&
                        result.f32_start_count == 1 &&
                        result.result_bytes == profile.expected_write_bytes &&
                        result.gmem_requests_accepted == 0 &&
                        result.gmem_responses_accepted == 0,
                        "positive raw32-portal owner counters mismatch");
        passed &= check(result.cycle_upper_bound ==
                            profile.cycle_upper_bound &&
                        result.rtl_cycles <= result.cycle_upper_bound,
                        "positive cycle bound mismatch");
    } else {
        std::uint32_t expected_status = 15;
        std::uint32_t expected_class = 4;
        std::uint64_t expected_starts = 0;
        if (mode == GGML_NPU_F32_ALU_MODE_UNKNOWN_KERNEL) {
            expected_status = 14;
            expected_class = 3;
        } else if (mode == GGML_NPU_F32_ALU_MODE_OUT_OF_RANGE_4MOD8 ||
                   mode == GGML_NPU_F32_ALU_MODE_OVERLAP ||
                   mode == GGML_NPU_F32_ALU_MODE_OVERPERMISSION) {
            expected_status = 16;
            expected_class = 5;
        } else if (mode == GGML_NPU_F32_ALU_MODE_REQ_READY_LOW) {
            expected_status = 17;
            expected_class = 10;
            expected_starts = 1;
        }
        passed &= check(result.controlled_reject == 1 &&
                        result.private_shadow_committed == 0,
                        "negative mode committed output");
        passed &= check(result.completion_status == expected_status &&
                        result.completion_error_code == expected_status &&
                        result.completion_error_class == expected_class,
                        "negative terminal payload mismatch");
        passed &= check(result.gmem_read_bytes == 0 &&
                        result.gmem_write_bytes == 0 &&
                        result.vector_elements == 0 &&
                        result.result_bytes == 0,
                        "negative mode reported work/result bytes");
        passed &= check(result.commands_terminal_success == 0 &&
                        result.commands_terminal_failure == 1 &&
                        result.f32_start_count == expected_starts &&
                        result.gmem_requests_accepted == 0,
                        "negative owner counters mismatch");
    }
    ggml_backend_unload(registry);
    if (!passed) {
        return 43;
    }
    std::printf(
        "[NPU-BACKEND-F32-ALU-V4][PASS] profile=P%02u mode=%u "
        "status=%u class=%u read=%llu write=%llu elements=%llu "
        "cycles=%llu bound=%llu private_shadow=%u emitted=%u accepted=%u "
        "observed_profile=%u required_delta=%llu/%llu\n",
        profile_id, mode, result.completion_status,
        result.completion_error_class,
        static_cast<unsigned long long>(result.gmem_read_bytes),
        static_cast<unsigned long long>(result.gmem_write_bytes),
        static_cast<unsigned long long>(result.vector_elements),
        static_cast<unsigned long long>(result.rtl_cycles),
        static_cast<unsigned long long>(result.cycle_upper_bound),
        result.private_shadow_committed,
        result.completion_emitted,
        result.completion_accepted,
        result.observed_profile_id,
        static_cast<unsigned long long>(result.required_issued_delta),
        static_cast<unsigned long long>(result.required_completed_delta));
    return 0;
}

bool parse_u32(const char * argument, std::uint32_t * value) {
    if (argument == nullptr || value == nullptr || argument[0] == '\0') {
        return false;
    }
    char * end = nullptr;
    const unsigned long parsed = std::strtoul(argument, &end, 10);
    if (end == argument || *end != '\0' ||
        parsed > std::numeric_limits<std::uint32_t>::max()) {
        return false;
    }
    *value = static_cast<std::uint32_t>(parsed);
    return true;
}

bool parse_f32_mode(const char * argument, std::uint32_t * mode) {
    if (std::strcmp(argument, "--f32-add-positive") == 0) {
        *mode = GGML_NPU_F32_ADD_MODE_POSITIVE;
    } else if (std::strcmp(argument, "--f32-add-unknown-kernel") == 0) {
        *mode = GGML_NPU_F32_ADD_MODE_UNKNOWN_KERNEL;
    } else if (std::strcmp(argument, "--f32-add-out-of-range") == 0) {
        *mode = GGML_NPU_F32_ADD_MODE_OUT_OF_RANGE_4MOD8;
    } else if (std::strcmp(argument, "--f32-add-req-ready-low") == 0) {
        *mode = GGML_NPU_F32_ADD_MODE_REQ_READY_LOW;
    } else if (std::strcmp(argument, "--f32-add-overpermission") == 0) {
        *mode = GGML_NPU_F32_ADD_MODE_OVERPERMISSION;
    } else {
        return false;
    }
    return true;
}

} // namespace

int main(int argc, char ** argv) {
    if (argc == 3 &&
        std::strcmp(argv[2], "--f32-zero-binding") == 0) {
        return run_f32_alu_graph_test(argv[1], true);
    }
    if (argc == 3 &&
        std::strcmp(argv[2], "--sampler-argmax-graph") == 0) {
        return run_sampler_argmax_graph_test(argv[1]);
    }
    if (argc == 4 &&
        std::strcmp(argv[2], "--q8-gemv-graph") == 0) {
        return run_q8_gemv_graph_test(argv[1], argv[3]);
    }
    if (argc == 4 &&
        std::strcmp(argv[2], "--q8-get-rows-graph") == 0) {
        return run_q8_get_rows_graph_test(argv[1], argv[3]);
    }
    if (argc == 3 &&
        std::strcmp(argv[2], "--f32-alu-graph") == 0) {
        return run_f32_alu_graph_test(argv[1]);
    }
    if (argc == 4 &&
        std::strcmp(argv[2], "--f32-alu-profile") == 0) {
        std::uint32_t profile_id = 0;
        if (parse_u32(argv[3], &profile_id)) {
            return run_f32_alu_mode_test(
                argv[1], profile_id, GGML_NPU_F32_ALU_MODE_POSITIVE);
        }
        return 44;
    }
    if (argc == 5 &&
        std::strcmp(argv[2], "--f32-alu-negative") == 0) {
        std::uint32_t profile_id = 0;
        std::uint32_t mode = 0;
        if (parse_u32(argv[3], &profile_id) &&
            parse_u32(argv[4], &mode)) {
            return run_f32_alu_mode_test(argv[1], profile_id, mode);
        }
        return 45;
    }
    if (argc == 3 && std::strcmp(argv[2], "--rtl-self-test") == 0) {
        return run_rtl_self_test(argv[1]);
    }
    if (argc == 3) {
        std::uint32_t mode = 0;
        if (parse_f32_mode(argv[2], &mode)) {
            return run_f32_mode_test(argv[1], mode);
        }
    }
    return run_abi_test(argc, argv);
}
