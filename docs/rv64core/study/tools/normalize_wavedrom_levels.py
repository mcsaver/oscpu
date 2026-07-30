#!/usr/bin/env python3
"""规范学习讲义中的 WaveDrom 二值保持编码。

WaveDrom 使用 ``.`` 表示延续上一电平。连续写 ``00`` 或 ``11`` 会产生视觉上的
窄毛刺；本工具只修改 wavedrom fenced block 内的 ``wave`` 字段，保留其余文本格式。
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


SCRIPT = Path(__file__).resolve()
STUDY_ROOT = SCRIPT.parents[1]
WAVEDROM_RE = re.compile(r"```wavedrom\s*\n(.*?)\n```", re.DOTALL)
WAVE_FIELD_RE = re.compile(r'("wave"\s*:\s*")([^"]*)(")')


def normalize_binary_holds(wave: str) -> str:
    normalized: list[str] = []
    active_level: str | None = None
    for token in wave:
        if token in {"0", "1"}:
            if token == active_level:
                normalized.append(".")
            else:
                normalized.append(token)
                active_level = token
        else:
            normalized.append(token)
            if token != ".":
                active_level = None
    return "".join(normalized)


def normalize_document(text: str) -> tuple[str, int]:
    changed_fields = 0

    def replace_block(block_match: re.Match[str]) -> str:
        nonlocal changed_fields
        body = block_match.group(1)

        def replace_field(field_match: re.Match[str]) -> str:
            nonlocal changed_fields
            wave = field_match.group(2)
            normalized = normalize_binary_holds(wave)
            if normalized != wave:
                changed_fields += 1
            return f"{field_match.group(1)}{normalized}{field_match.group(3)}"

        normalized_body = WAVE_FIELD_RE.sub(replace_field, body)
        return block_match.group(0).replace(body, normalized_body, 1)

    return WAVEDROM_RE.sub(replace_block, text), changed_fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--write",
        action="store_true",
        help="写回规范化结果；默认只检查并在需要修改时返回非零",
    )
    args = parser.parse_args()

    changed_files = 0
    changed_fields = 0
    for path in sorted(STUDY_ROOT.glob("[0-9][0-9]-*.md")):
        original = path.read_text(encoding="utf-8")
        normalized, field_count = normalize_document(original)
        if not field_count:
            continue
        changed_files += 1
        changed_fields += field_count
        if args.write:
            path.write_text(normalized, encoding="utf-8")
        print(
            f"[wavedrom-levels] {'fixed' if args.write else 'needs-fix'} "
            f"{path.relative_to(STUDY_ROOT)} fields={field_count}"
        )

    print(
        f"[wavedrom-levels] files={changed_files} fields={changed_fields} "
        f"mode={'write' if args.write else 'check'}"
    )
    if changed_fields and not args.write:
        print("[wavedrom-levels] FAIL")
        return 1
    print("[wavedrom-levels] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
