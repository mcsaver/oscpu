#include "npu-command-abi.h"
#include "npu-verilator-runner.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <vector>

namespace {

int g_checks = 0;
int g_failures = 0;

bool check(bool condition, const char * label) {
    ++g_checks;
    if (!condition) {
        ++g_failures;
        std::fprintf(stderr, "[NPU-COMMAND-ABI][FAIL] %s\n", label);
    }
    return condition;
}

npu_exact_command_contract make_command() {
    npu_exact_command_contract command = {};
    command.abi_valid = 1U;
    command.windows_generation_valid = 1U;
    command.kernel_id = 0x514e0010U;
    command.vector_op = 0x11223344U;
    command.local_profile = 0x55667788U;
    command.command_flags = 0x00000011U;
    command.context_id = 0x43414e01U;
    command.capability_epoch = 1U;
    command.node_count = 3U;
    command.sequence_id = 0x0123456789abcdefULL;
    command.producer_id = 0xfedcba9876543210ULL;
    command.user_tag = 0x0f1e2d3c4b5a6978ULL;
    command.node_hash_lo = 0x1020304050607080ULL;
    command.node_hash_hi = 0x8877665544332211ULL;
    command.deadline_cycles = 0x100000001ULL;
    command.src0_iova = 0x1020U;
    command.src1_iova = 0x2010U;
    command.src2_iova = 0U;
    command.dst_iova = 0x3008U;
    command.scratch_iova = 0U;
    command.element_count = 0x123456789ULL;
    command.outer_count = 7U;
    command.dtype = 1U;
    command.src0_stride = 0x40U;
    command.src1_stride = 0x80U;
    command.src2_stride = 0U;
    command.dst_stride = 0x100U;
    command.scalar0 = 0x3f800000U;
    command.scalar1 = 0x40000000U;
    command.scratch_bytes = 0U;
    command.rope_position = 19U;
    command.src0_window_base = 0x1000U;
    command.src0_window_size = 0x100U;
    command.src0_window_perm = 1U;
    command.src1_window_base = 0x2000U;
    command.src1_window_size = 0x80U;
    command.src1_window_perm = 1U;
    command.dst_window_base = 0x3000U;
    command.dst_window_size = 0x40U;
    command.dst_window_perm = 2U;
    return command;
}

npu_exact_command_contract make_template_command() {
    npu_exact_command_contract command = make_command();
    command.src0_iova = 0x20U;
    command.src1_iova = 0x10U;
    command.dst_iova = 0x08U;
    command.src0_window_base = 0U;
    command.src1_window_base = 0U;
    command.dst_window_base = 0U;
    return command;
}

std::uint64_t load_le64(const std::uint8_t * bytes) {
    std::uint64_t value = 0;
    for (unsigned index = 0; index < 8U; ++index) {
        value |= static_cast<std::uint64_t>(bytes[index]) << (8U * index);
    }
    return value;
}

void store_le64(std::uint8_t * bytes, std::uint64_t value) {
    for (unsigned index = 0; index < 8U; ++index) {
        bytes[index] = static_cast<std::uint8_t>(value >> (8U * index));
    }
}

std::vector<npu_command_abi_relocation> primary_relocations() {
    return {
        {10U, 0U, 0x20U},
        {23U, 0U, 0U},
        {11U, 1U, 0x10U},
        {26U, 1U, 0U},
        {13U, 2U, 0x08U},
        {28U, 2U, 0U},
    };
}

std::vector<npu_command_abi_buffer_binding> bindings() {
    return {
        {0x0000001010000000ULL, 0x200U, 1U},
        {0x0000002020000000ULL, 0x100U, 1U},
        {0x0000003030000000ULL, 0x100U, 2U},
    };
}

std::vector<std::uint8_t> image_for(
        const npu_exact_command_contract & command,
        std::size_t command_offset = 16U) {
    npu_command_abi_bytes encoded = {};
    if (!npu_command_abi_encode_le(&command, &encoded)) {
        return {};
    }
    std::vector<std::uint8_t> image(
        command_offset + encoded.size() + 13U, 0xa5U);
    std::copy(encoded.begin(), encoded.end(),
              image.begin() + static_cast<std::ptrdiff_t>(command_offset));
    return image;
}

void expect_relocation_error(
        const char * label,
        const std::vector<std::uint8_t> & image,
        std::size_t command_offset,
        const std::vector<npu_command_abi_relocation> & relocations,
        const std::vector<npu_command_abi_buffer_binding> & runtime_bindings,
        npu_command_abi_error expected) {
    std::vector<std::uint8_t> shadow = {0xdeU, 0xadU, 0xbeU, 0xefU};
    const std::vector<std::uint8_t> before = shadow;
    npu_command_abi_diagnostic diagnostic = {};
    const bool result = npu_command_abi_relocate_private_shadow(
        image.empty() ? nullptr : image.data(), image.size(), command_offset,
        relocations.empty() ? nullptr : relocations.data(),
        relocations.size(),
        runtime_bindings.empty() ? nullptr : runtime_bindings.data(),
        runtime_bindings.size(), &shadow, &diagnostic);
    check(!result, label);
    check(diagnostic.error == expected, label);
    check(shadow == before, label);
}

void test_pack_unpack_and_le() {
    npu_exact_command_contract command = make_command();
    npu_command_abi_words words = {};
    npu_command_abi_diagnostic diagnostic = {};
    check(npu_command_abi_pack_words(&command, &words, &diagnostic),
          "pack representative command");
    check(diagnostic.error == npu_command_abi_error::none,
          "successful pack clears diagnostic");
    check(words[0] == 0x00000011514e0010ULL,
          "word0 packs flags/kernel");
    check(words[1] == 0x0000000143414e01ULL,
          "word1 packs epoch/context");
    check(words[5] == 0x1122334400000003ULL,
          "word5 packs vector-op/node-count");
    check(words[9] == 0x0000000755667788ULL,
          "word9 packs outer/profile");
    check(words[16] == 0x3f80000000000001ULL,
          "word16 packs scalar0/dtype");
    check(words[17] == 0x0000000040000000ULL,
          "word17 packs scratch-bytes/scalar1");
    check(words[18] == 19U, "word18 reserves its upper half");
    check(words[25] == 0x97U, "word25 packs validity/permissions");

    npu_command_abi_bytes bytes = {};
    check(npu_command_abi_encode_le(&command, &bytes, &diagnostic),
          "encode representative command");
    const std::array<std::uint8_t, 8> word0_le = {
        0x10U, 0x00U, 0x4eU, 0x51U,
        0x11U, 0x00U, 0x00U, 0x00U,
    };
    check(std::equal(word0_le.begin(), word0_le.end(), bytes.begin()),
          "wire bytes are explicitly little-endian");
    check(load_le64(bytes.data() + 25U * 8U) == 0x97U,
          "permission word little-endian decode");

    npu_exact_command_contract decoded = {};
    check(npu_command_abi_decode_le(
              bytes.data(), bytes.size(), &decoded, &diagnostic),
          "decode representative command");
    npu_command_abi_words roundtrip = {};
    check(npu_command_abi_pack_words(&decoded, &roundtrip, &diagnostic),
          "repack decoded command");
    check(roundtrip == words, "all 30 wire words round-trip");
    check(!decoded.dst_shadow_readable,
          "host-only destination readability is not synthesized from wire");
    check(npu_command_abi_validate_contract(&command, &diagnostic),
          "representative command validates");
    check(npu_command_abi_validate_words(&words, &diagnostic),
          "representative words validate");
    check(npu_command_abi_validate_le(
              bytes.data(), bytes.size(), &diagnostic),
          "representative bytes validate");

    npu_exact_command_contract malformed = command;
    malformed.abi_valid = 2U;
    npu_command_abi_words untouched_words = {};
    untouched_words.fill(0xccccccccccccccccULL);
    const npu_command_abi_words words_before = untouched_words;
    check(!npu_command_abi_pack_words(
              &malformed, &untouched_words, &diagnostic),
          "unrepresentable boolean rejected");
    check(untouched_words == words_before,
          "failed pack leaves output words untouched");

    npu_command_abi_words reserved = words;
    reserved[18] |= 1ULL << 32U;
    decoded = make_command();
    const std::uint64_t decoded_sequence_before = decoded.sequence_id;
    check(!npu_command_abi_unpack_words(&reserved, &decoded, &diagnostic),
          "word18 reserved bits rejected");
    check(diagnostic.error ==
              npu_command_abi_error::reserved_bits_nonzero &&
          diagnostic.word_index == 18U,
          "word18 rejection is diagnosed");
    check(decoded.sequence_id == decoded_sequence_before,
          "failed unpack leaves command untouched");
    reserved = words;
    reserved[25] |= 1ULL << 8U;
    check(!npu_command_abi_validate_words(&reserved, &diagnostic),
          "word25 reserved bits rejected");
    check(diagnostic.word_index == 25U,
          "word25 rejection is diagnosed");
    check(!npu_command_abi_decode_le(
              bytes.data(), bytes.size() - 1U, &decoded, &diagnostic),
          "short byte descriptor rejected");
    check(diagnostic.error == npu_command_abi_error::command_buffer_range,
          "short descriptor range is diagnosed");
}

void test_strict_validation() {
    npu_command_abi_diagnostic diagnostic = {};
    npu_exact_command_contract command = make_command();

    command.abi_valid = 0U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::invalid_validity,
          "production validation requires validity bits");

    command = make_command();
    command.scratch_iova = 0x4000U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::scratch_without_window,
          "v1 scratch address fails closed without a window");

    command = make_command();
    command.scratch_bytes = 64U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::scratch_without_window,
          "v1 scratch bytes fail closed without a window");

    command = make_command();
    command.src0_window_perm = 3U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::invalid_permission,
          "source write permission rejected");

    command = make_command();
    command.src1_window_perm = 0U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::invalid_permission,
          "absent src1 permission requires an absent tuple");

    command = make_command();
    command.src0_window_base =
        std::numeric_limits<std::uint64_t>::max() - 3U;
    command.src0_window_size = 8U;
    command.src0_iova = command.src0_window_base;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::arithmetic_overflow,
          "window-end overflow rejected");

    command = make_command();
    command.dst_iova = command.dst_window_base + command.dst_window_size;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error ==
              npu_command_abi_error::address_window_mismatch,
          "one-past-window address rejected");

    command = make_command();
    command.src2_iova = 0x9000U;
    check(!npu_command_abi_validate_contract(&command, &diagnostic) &&
          diagnostic.error == npu_command_abi_error::src2_not_window_alias,
          "src2 outside all declared windows rejected");

    command.src2_iova = command.dst_window_base + 0x10U;
    check(npu_command_abi_validate_contract(&command, &diagnostic),
          "src2 numeric alias of destination window validates");

    command = make_command();
    command.src0_window_size = 0U;
    command.src0_iova = command.src0_window_base + 4U;
    check(npu_command_abi_validate_contract(&command, &diagnostic),
          "zero-length window may retain a semantic lane address");
}

void test_relocation_success() {
    const npu_exact_command_contract command = make_template_command();
    const std::size_t command_offset = 16U;
    const std::vector<std::uint8_t> image =
        image_for(command, command_offset);
    const std::vector<npu_command_abi_relocation> relocations =
        primary_relocations();
    const std::vector<npu_command_abi_buffer_binding> runtime_bindings =
        bindings();
    std::vector<std::uint8_t> shadow = {1U, 2U, 3U};
    npu_command_abi_diagnostic diagnostic = {};
    check(npu_command_abi_relocate_private_shadow(
              image.data(), image.size(), command_offset,
              relocations.data(), relocations.size(),
              runtime_bindings.data(), runtime_bindings.size(),
              &shadow, &diagnostic),
          "paired relocation succeeds");
    check(diagnostic.error == npu_command_abi_error::none,
          "successful relocation clears diagnostic");
    check(shadow.size() == image.size(),
          "private shadow covers the complete input image");
    check(std::equal(
              shadow.begin(),
              shadow.begin() + static_cast<std::ptrdiff_t>(command_offset),
              image.begin()),
          "relocation preserves image prefix");
    check(std::equal(
              shadow.begin() + static_cast<std::ptrdiff_t>(
                  command_offset + NPU_COMMAND_ABI_BYTES),
              shadow.end(),
              image.begin() + static_cast<std::ptrdiff_t>(
                  command_offset + NPU_COMMAND_ABI_BYTES)),
          "relocation preserves image suffix");
    check(load_le64(shadow.data() + command_offset + 10U * 8U) ==
              runtime_bindings[0].base + 0x20U,
          "src0 address relocated in LE shadow");
    check(load_le64(shadow.data() + command_offset + 23U * 8U) ==
              runtime_bindings[0].base,
          "src0 window base relocated as a pair");
    check(load_le64(shadow.data() + command_offset + 11U * 8U) ==
              runtime_bindings[1].base + 0x10U,
          "src1 address relocated");
    check(load_le64(shadow.data() + command_offset + 13U * 8U) ==
              runtime_bindings[2].base + 0x08U,
          "destination address relocated");
    check(image[command_offset + 10U * 8U] == 0x20U,
          "input image remains immutable");
    check(npu_command_abi_validate_le(
              shadow.data() + command_offset, NPU_COMMAND_ABI_BYTES,
              &diagnostic),
          "relocated descriptor passes strict validation");

    std::vector<std::uint8_t> in_place_shadow = image;
    check(npu_command_abi_relocate_private_shadow(
              in_place_shadow.data(), in_place_shadow.size(), command_offset,
              relocations.data(), relocations.size(),
              runtime_bindings.data(), runtime_bindings.size(),
              &in_place_shadow, &diagnostic),
          "private shadow may also own the immutable source bytes");
    check(load_le64(
              in_place_shadow.data() + command_offset + 10U * 8U) ==
              runtime_bindings[0].base + 0x20U,
          "in-place owner still commits only the validated candidate");

    npu_exact_command_contract alias_command = make_template_command();
    alias_command.src2_iova = alias_command.dst_window_base + 0x10U;
    std::vector<std::uint8_t> alias_image =
        image_for(alias_command, command_offset);
    std::vector<npu_command_abi_relocation> alias_relocations = relocations;
    alias_relocations.push_back({12U, 2U, 0x10U});
    std::vector<npu_command_abi_buffer_binding> alias_bindings =
        runtime_bindings;
    alias_bindings[2].permissions = 3U;
    check(npu_command_abi_relocate_private_shadow(
              alias_image.data(), alias_image.size(), command_offset,
              alias_relocations.data(), alias_relocations.size(),
              alias_bindings.data(), alias_bindings.size(),
              &shadow, &diagnostic),
          "src2 explicit destination-window alias relocates");
    check(load_le64(shadow.data() + command_offset + 12U * 8U) ==
              alias_bindings[2].base + 0x10U,
          "src2 alias uses selected binding/addend");

    // No-relocation validation is useful for already-fixed IOVA images.
    std::vector<std::uint8_t> fixed_shadow;
    check(npu_command_abi_relocate_private_shadow(
              image.data(), image.size(), command_offset,
              nullptr, 0U, nullptr, 0U, &fixed_shadow, &diagnostic),
          "fixed-I/O descriptor copies through the validated shadow path");
    check(fixed_shadow == image,
          "zero-relocation private shadow equals fixed input image");
}

void test_relocation_fail_closed() {
    const std::size_t command_offset = 16U;
    const npu_exact_command_contract command = make_template_command();
    const std::vector<std::uint8_t> image =
        image_for(command, command_offset);
    const std::vector<npu_command_abi_relocation> good_relocations =
        primary_relocations();
    const std::vector<npu_command_abi_buffer_binding> good_bindings =
        bindings();

    std::vector<npu_command_abi_relocation> changed = good_relocations;
    changed[0].word_index = 30U;
    expect_relocation_error(
        "word index >=30 fails closed", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_word_range);

    changed = good_relocations;
    changed[0].word_index = 24U;
    expect_relocation_error(
        "window-size word is not relocatable", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_word_unsupported);

    changed = good_relocations;
    changed[0].word_index = 14U;
    expect_relocation_error(
        "scratch word is not relocatable in v1", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_word_unsupported);

    changed = good_relocations;
    changed.push_back(changed.front());
    expect_relocation_error(
        "duplicate word relocation fails closed", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_duplicate_word);

    changed = good_relocations;
    changed[0].addend = 0x28U;
    expect_relocation_error(
        "template word must equal relocation addend", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_template_mismatch);

    changed = good_relocations;
    changed[0].binding_index = 3U;
    expect_relocation_error(
        "binding index out of range fails closed", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_binding_range);

    changed = good_relocations;
    changed.erase(changed.begin() + 1);
    expect_relocation_error(
        "missing address/base pair fails closed", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_pair_missing);

    changed = good_relocations;
    changed[1].binding_index = 1U;
    expect_relocation_error(
        "pair binding mismatch fails closed", image, command_offset,
        changed, good_bindings,
        npu_command_abi_error::relocation_pair_binding_mismatch);

    std::vector<npu_command_abi_buffer_binding> changed_bindings =
        good_bindings;
    changed_bindings[0].size = 0x80U;
    expect_relocation_error(
        "declared window larger than binding fails closed", image,
        command_offset, good_relocations, changed_bindings,
        npu_command_abi_error::relocation_buffer_range);

    changed_bindings = good_bindings;
    changed_bindings[0].permissions = 0U;
    expect_relocation_error(
        "binding missing descriptor read permission fails closed", image,
        command_offset, good_relocations, changed_bindings,
        npu_command_abi_error::relocation_permission);

    changed_bindings = good_bindings;
    changed_bindings[0].base =
        std::numeric_limits<std::uint64_t>::max() - 0x10U;
    changed_bindings[0].size = 0x10U;
    changed = good_relocations;
    changed[0].addend = 0x20U;
    expect_relocation_error(
        "binding base plus addend overflow fails closed", image,
        command_offset, changed, changed_bindings,
        npu_command_abi_error::arithmetic_overflow);

    expect_relocation_error(
        "misaligned descriptor offset fails closed", image,
        command_offset + 1U, good_relocations, good_bindings,
        npu_command_abi_error::command_buffer_alignment);

    std::vector<std::uint8_t> short_image(NPU_COMMAND_ABI_BYTES - 1U, 0U);
    expect_relocation_error(
        "descriptor outside command buffer fails closed", short_image,
        0U, good_relocations, good_bindings,
        npu_command_abi_error::command_buffer_range);

    npu_exact_command_contract alias_command = make_template_command();
    alias_command.src2_iova = alias_command.dst_window_base + 0x10U;
    const std::vector<std::uint8_t> alias_image =
        image_for(alias_command, command_offset);
    expect_relocation_error(
        "nonzero src2 requires explicit alias relocation", alias_image,
        command_offset, good_relocations, good_bindings,
        npu_command_abi_error::relocation_src2_missing);

    changed = good_relocations;
    changed.push_back({12U, 2U, 0x10U});
    expect_relocation_error(
        "src2 alias binding requires read permission", alias_image,
        command_offset, changed, good_bindings,
        npu_command_abi_error::relocation_permission);

    changed_bindings = good_bindings;
    changed_bindings.push_back({0x0000004040000000ULL, 0x100U, 1U});
    changed = good_relocations;
    changed.push_back({12U, 3U, 0x10U});
    expect_relocation_error(
        "src2 cannot bind an undeclared fourth window", alias_image,
        command_offset, changed, changed_bindings,
        npu_command_abi_error::src2_not_window_alias);

    std::vector<std::uint8_t> reserved_image = image;
    const std::size_t reserved_word_offset =
        command_offset + 25U * NPU_COMMAND_ABI_WORD_BYTES;
    store_le64(
        reserved_image.data() + reserved_word_offset,
        load_le64(reserved_image.data() + reserved_word_offset) |
            (1ULL << 8U));
    expect_relocation_error(
        "reserved wire bit rejects before relocation", reserved_image,
        command_offset, good_relocations, good_bindings,
        npu_command_abi_error::reserved_bits_nonzero);
}

}  // namespace

int main() {
    static_assert(NPU_COMMAND_ABI_WORD_COUNT == 30U,
                  "CONFIG descriptor word count changed");
    static_assert(NPU_COMMAND_ABI_BYTES == 240U,
                  "CONFIG descriptor byte count changed");
    {
        auto c = make_command();
        c.kernel_id = 0x514e0007U; c.vector_op = 34U;
        c.local_profile = 3U; c.outer_count = 0;
        c.src1_iova = c.src1_window_base + c.src1_window_size;
        c.dst_iova = c.dst_window_base + c.dst_window_size;
        check(npu_command_abi_validate_contract(&c), "empty CPY end views retain zero-access capability");
        c.local_profile = 5U;
        check(npu_command_abi_validate_contract(&c), "empty state CPY end view accepted");
        c.outer_count = 1;
        check(!npu_command_abi_validate_contract(&c), "nonempty CPY cannot access end of backing");
        c.outer_count = 0; c.local_profile = 4;
        check(!npu_command_abi_validate_contract(&c), "nonempty profile cannot borrow empty CPY exception");
        c.local_profile = 3; ++c.dst_iova;
        check(!npu_command_abi_validate_contract(&c), "empty CPY cannot exceed one-past-end address");
    }
    test_pack_unpack_and_le();
    test_strict_validation();
    test_relocation_success();
    test_relocation_fail_closed();
    check(npu_command_abi_error_string(
              npu_command_abi_error::relocation_pair_missing) != nullptr,
          "diagnostic error has a stable string");
    if (g_failures != 0) {
        std::fprintf(stderr,
                     "[NPU-COMMAND-ABI][FAIL] checks=%d failures=%d\n",
                     g_checks, g_failures);
        return 1;
    }
    std::printf(
        "[NPU-COMMAND-ABI][PASS] checks=%d words=30 bytes=240 "
        "le=explicit relocation=paired+private-shadow+fail-closed\n",
        g_checks);
    return 0;
}
