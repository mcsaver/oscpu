#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Sequence


_ANSI_ESCAPE_RE = re.compile(
    r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x1b\x07]*(?:\x07|\x1b\\))"
)
_FINISH_ARGUMENT_RE = re.compile(r"\$finish\b\s*\(([^)]*)\)", re.DOTALL)
_FAIL_MARKER_RE = re.compile(r"(?<![A-Za-z0-9_])FAIL(?![A-Za-z0-9_])")
_ERROR_COUNT_RE = re.compile(r"\berrors\s*=\s*([+-]?\d+)\b", re.IGNORECASE)
_ERROR_DIAGNOSTIC_RE = re.compile(r"^(?:ERROR:|%Error(?:[-:]))", re.MULTILINE)
_STRING_SENTINEL = "S"


def strip_ansi(text: str) -> str:
    """移除日志中的 ANSI 控制序列，避免颜色码破坏整行判定。"""

    return _ANSI_ESCAPE_RE.sub("", text)


def _mask_sv_comments_and_strings(source_text: str) -> str:
    """以空格遮罩 SV 注释和字符串，同时保留换行与源码位置。"""

    masked = list(source_text)
    index = 0
    state = "code"

    while index < len(source_text):
        char = source_text[index]
        following = source_text[index + 1] if index + 1 < len(source_text) else ""

        if state == "code":
            if char == "/" and following == "/":
                masked[index] = masked[index + 1] = " "
                index += 2
                state = "line_comment"
                continue
            if char == "/" and following == "*":
                masked[index] = masked[index + 1] = " "
                index += 2
                state = "block_comment"
                continue
            if char == '"':
                masked[index] = _STRING_SENTINEL
                index += 1
                state = "string"
                continue
            index += 1
            continue

        if state == "line_comment":
            if char == "\n":
                state = "code"
            else:
                masked[index] = " "
            index += 1
            continue

        if state == "block_comment":
            if char == "*" and following == "/":
                masked[index] = masked[index + 1] = " "
                index += 2
                state = "code"
                continue
            if char != "\n":
                masked[index] = " "
            index += 1
            continue

        if char == "\\" and following:
            masked[index] = _STRING_SENTINEL
            if following != "\n":
                masked[index + 1] = _STRING_SENTINEL
            index += 2
            continue
        if char == '"':
            masked[index] = _STRING_SENTINEL
            index += 1
            state = "code"
            continue
        if char != "\n":
            masked[index] = _STRING_SENTINEL
        index += 1

    return "".join(masked)


def legacy_failure_finish(source_text: str) -> bool:
    """判断源码是否包含旧式的失败 ``$finish(...)`` 调用。"""

    code_text = _mask_sv_comments_and_strings(source_text)
    for match in _FINISH_ARGUMENT_RE.finditer(code_text):
        argument = match.group(1).strip()
        # 只有空参数和字面量 0 表示成功；表达式即使可能求值为 0 也不可信。
        if argument not in ("", "0"):
            return True
    return False


def classify(
    test_name: str,
    source_text: str,
    log_text: str,
    compile_rc: int,
    sim_rc: int,
) -> list[str]:
    """返回 module TB 的全部失败原因；空列表表示结果可信且成功。"""

    reasons: list[str] = []
    normalized_log = strip_ansi(log_text)

    if compile_rc != 0:
        reasons.append(f"compile returned nonzero status {compile_rc}")
    if sim_rc != 0:
        reasons.append(f"simulation returned nonzero status {sim_rc}")
    if _FAIL_MARKER_RE.search(normalized_log):
        reasons.append("log contains a FAIL marker")
    if _ERROR_DIAGNOSTIC_RE.search(normalized_log):
        reasons.append("log contains an ERROR diagnostic")

    nonzero_error_count = next(
        (
            int(match.group(1))
            for match in _ERROR_COUNT_RE.finditer(normalized_log)
            if int(match.group(1)) != 0
        ),
        None,
    )
    if nonzero_error_count is not None:
        reasons.append(f"log reports errors={nonzero_error_count}")

    accepted_pass_lines = {
        f"PASS {test_name}",
        f"[PASS] {test_name}",
    }
    if not any(line in accepted_pass_lines for line in normalized_log.splitlines()):
        reasons.append(f"missing exact PASS line for {test_name}")

    if legacy_failure_finish(source_text):
        reasons.append("source contains a nonzero or expression $finish(...) argument")

    return reasons


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Classify one module testbench result")
    parser.add_argument("--test", required=True)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--compile-rc", required=True, type=int)
    parser.add_argument("--sim-rc", required=True, type=int)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)

    try:
        source_text = args.source.read_text(encoding="utf-8")
        log_text = args.log.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        print(f"input error: {error}", file=sys.stderr)
        return 2

    reasons = classify(
        args.test,
        source_text,
        log_text,
        args.compile_rc,
        args.sim_rc,
    )
    for reason in reasons:
        print(reason, file=sys.stderr)
    return 1 if reasons else 0


if __name__ == "__main__":
    raise SystemExit(main())
