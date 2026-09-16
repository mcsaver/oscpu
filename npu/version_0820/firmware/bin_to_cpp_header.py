#!/usr/bin/env python3
"""Convert the linked RV64 service firmware into a deterministic C++ header."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


def parse_int(text: str) -> int:
    return int(text, 0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--load-address", required=True, type=parse_int)
    parser.add_argument("--entry-address", required=True, type=parse_int)
    parser.add_argument("--mailbox-address", required=True, type=parse_int)
    parser.add_argument("--command-address", required=True, type=parse_int)
    parser.add_argument("--completion-address", required=True, type=parse_int)
    args = parser.parse_args()

    image = args.input.read_bytes()
    if not image:
        raise SystemExit("firmware image is empty")
    if len(image) > 0x1000:
        raise SystemExit(
            f"firmware image is {len(image)} bytes; 4 KiB aperture exceeded"
        )
    if len(image) % 4:
        raise SystemExit("firmware image is not a whole number of RV64 words")
    if args.entry_address != args.load_address:
        raise SystemExit("flat image entry must equal its load address")

    rows = []
    for offset in range(0, len(image), 12):
        chunk = image[offset : offset + 12]
        rows.append("        " + ", ".join(f"0x{byte:02x}" for byte in chunk))
    rows_text = ",\n".join(rows)

    digest = hashlib.sha256(image).hexdigest()
    text = f"""// Generated from npu_service.S; do not edit.
#ifndef NPU_RV64_SERVICE_FIRMWARE_IMAGE_H
#define NPU_RV64_SERVICE_FIRMWARE_IMAGE_H

#include <array>
#include <cstddef>
#include <cstdint>

namespace npu::rv64_service_firmware_v1 {{

inline constexpr std::uint64_t kLoadAddress = 0x{args.load_address:016x}ULL;
inline constexpr std::uint64_t kEntryAddress = 0x{args.entry_address:016x}ULL;
inline constexpr std::uint64_t kMailboxAddress = 0x{args.mailbox_address:016x}ULL;
inline constexpr std::uint64_t kCommandAddress = 0x{args.command_address:016x}ULL;
inline constexpr std::uint64_t kCompletionAddress =
    0x{args.completion_address:016x}ULL;
inline constexpr char kImageSha256[] = "{digest}";
inline constexpr std::array<std::uint8_t, {len(image)}> kImage = {{{{
{rows_text}
}}}};
inline constexpr std::size_t kImageBytes = kImage.size();

}}  // namespace npu::rv64_service_firmware_v1

#endif  // NPU_RV64_SERVICE_FIRMWARE_IMAGE_H
"""

    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(text, encoding="utf-8", newline="\n")
    temporary.replace(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
