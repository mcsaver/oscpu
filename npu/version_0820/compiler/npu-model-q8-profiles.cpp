#include "npu-verilator-runner.h"
namespace {
constexpr std::uint32_t kKernelGetRowsQ8 = 0x514e0001U;
constexpr std::uint32_t kCanonicalCommandFlags = 0x00000011U;
constexpr std::uint32_t kCapabilityEpoch = 1;
constexpr std::uint32_t kCanonicalContextId = 0x43414e01U;
constexpr std::uint32_t kDtypeF32 = 1;

constexpr std::uint32_t kEmbeddingDim = 1024;
constexpr std::uint32_t kGatheredRows = 1;
constexpr std::uint32_t kVocabularyRows = 248320;
constexpr std::uint64_t kTableRowStride = 1088;
constexpr std::uint64_t kIndexStride = 4;
constexpr std::uint64_t kDstRowStride = 4096;
constexpr std::uint64_t kTableBytes =
    static_cast<std::uint64_t>(kVocabularyRows) * kTableRowStride;
constexpr std::uint64_t kIndexBytes = 4;
constexpr std::uint64_t kDstBytes = 4096;

// These widened, deliberately unaligned IOVAs are frozen by the focused RTL
// qualification.  They prove that neither descriptor admission nor sparse
// last-row request generation truncates the real Qwen embedding footprint.
constexpr std::uint64_t kTableIova = 0x0000000120000002ULL;
constexpr std::uint64_t kTableWindowBase = 0x0000000120000000ULL;
constexpr std::uint64_t kTableWindowSize = 0x00000000101a8008ULL;
constexpr std::uint64_t kIndexIova = 0x0000000240000005ULL;
constexpr std::uint64_t kIndexWindowBase = 0x0000000240000000ULL;
constexpr std::uint64_t kIndexWindowSize = 16;
constexpr std::uint64_t kDstIova = 0x0000000000000900ULL;
constexpr std::uint64_t kDstWindowBase = kDstIova;
constexpr std::uint64_t kDstWindowSize = kDstBytes;

constexpr std::uint64_t kExpectedReadBytes = 1296;
constexpr std::uint64_t kExpectedWriteBytes = 4096;
constexpr std::uint64_t kExpectedElements = 1024;
constexpr std::uint64_t kExpectedReadRequests = 162;
constexpr std::uint64_t kExpectedWriteRequests = 1024;
constexpr std::uint64_t kCycleUpperBound = 200000;
constexpr std::uint64_t kResponseLatencyCycles = 2;
constexpr unsigned kCompletionBackpressureCycles = 4;

constexpr std::uint32_t kNpuErrMacroIova = 16;
constexpr std::uint32_t kAbiErrorIova = 5;


}
bool npu_q8_get_rows_profile_v1(npu_q8_get_rows_profile * profile) {
    if (profile == nullptr) {
        return false;
    }
    *profile = {
        0,
        kEmbeddingDim,
        kGatheredRows,
        kVocabularyRows,
        kTableRowStride,
        kIndexStride,
        kDstRowStride,
        kTableBytes,
        kIndexBytes,
        kDstBytes,
        kExpectedReadBytes,
        kExpectedWriteBytes,
        kExpectedElements,
        kCycleUpperBound,
    };
    return true;
}
