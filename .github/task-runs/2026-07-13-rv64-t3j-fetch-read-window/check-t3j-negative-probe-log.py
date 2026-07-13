#!/usr/bin/env python3
"""Fail-closed audit for one T3J assertion-negative module-TB log."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import re
from pathlib import Path
import sys


MARKER = "[T3J-NEGATIVE-LOG-CHECK]"
SELFTEST_MARKER = "[T3J-NEGATIVE-LOG-SELFTEST]"
ANSI_RE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x1b\x07]*(?:\x07|\x1b\\))")
ERROR_LINE_RE = re.compile(r"^ERROR:.*$", re.MULTILINE)
RESULT_FAIL_RE = re.compile(r"^\[RESULT\] FAIL status=([1-9][0-9]*)$", re.MULTILINE)


class ProbeLogError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def require(condition: bool, code: str, message: str) -> None:
    if not condition:
        raise ProbeLogError(code, message)


@dataclass(frozen=True)
class ProbeContract:
    expected_marker: str
    forbidden_marker: str
    expected_define: str
    forbidden_define: str
    make_rc: int


def audit_text(raw_text: str, contract: ProbeContract) -> None:
    text = ANSI_RE.sub("", raw_text)
    expected_count = text.count(contract.expected_marker)
    require(
        expected_count == 1,
        "E_EXPECTED_MARKER_COUNT",
        f"expected marker count={expected_count}, wanted 1: {contract.expected_marker}",
    )
    forbidden_count = text.count(contract.forbidden_marker)
    require(
        forbidden_count == 0,
        "E_FORBIDDEN_MARKER",
        f"forbidden marker count={forbidden_count}, wanted 0: {contract.forbidden_marker}",
    )

    error_lines = ERROR_LINE_RE.findall(text)
    require(
        len(error_lines) == 1 and contract.expected_marker in error_lines[0],
        "E_ERROR_LINE_EXACT",
        f"expected one ERROR line carrying only the target contract marker, got {error_lines}",
    )
    require(
        text.splitlines().count("[PASS] tb_ooo_fetch_packet_cache") == 1,
        "E_INNER_PASS_COUNT",
        "negative probe must reach exactly one inner TB PASS line so the global runner is tested",
    )
    require(
        len(RESULT_FAIL_RE.findall(text)) == 1,
        "E_RESULT_FAIL_COUNT",
        "global module runner must emit exactly one nonzero [RESULT] FAIL status line",
    )
    require(
        text.splitlines().count("[RESULT] PASS") == 0,
        "E_RESULT_FALSE_GREEN",
        "global module runner emitted [RESULT] PASS for an assertion error",
    )
    require(
        text.splitlines().count("log contains an ERROR diagnostic") == 1,
        "E_RUNNER_ERROR_REASON",
        "check_tb_result.py must report the ERROR diagnostic exactly once",
    )
    compile_lines = [line for line in text.splitlines() if line.startswith("[COMPILE] ")]
    require(len(compile_lines) == 1, "E_COMPILE_LINE", f"compile line count={len(compile_lines)}, wanted 1")
    require(
        f"-D{contract.expected_define}" in compile_lines[0],
        "E_EXPECTED_DEFINE",
        f"compile command lacks -D{contract.expected_define}",
    )
    require(
        f"-D{contract.forbidden_define}" not in compile_lines[0],
        "E_FORBIDDEN_DEFINE",
        f"compile command also enables -D{contract.forbidden_define}",
    )
    require(contract.make_rc != 0, "E_MAKE_FALSE_GREEN", f"make returned {contract.make_rc}, expected nonzero")


def exercise_fail_closed(text: str, contract: ProbeContract) -> None:
    cases = (
        (
            "missing",
            text.replace(contract.expected_marker, "[T3J-REMOVED-MARKER]", 1),
            "E_EXPECTED_MARKER_COUNT",
        ),
        (
            "duplicate",
            text + f"\nERROR: synthetic duplicate {contract.expected_marker}\n",
            "E_EXPECTED_MARKER_COUNT",
        ),
        (
            "forbidden",
            text + f"\nERROR: synthetic forbidden {contract.forbidden_marker}\n",
            "E_FORBIDDEN_MARKER",
        ),
    )
    for label, mutated, expected_code in cases:
        try:
            audit_text(mutated, contract)
        except ProbeLogError as error:
            require(
                error.code == expected_code,
                "E_SELFTEST_WRONG_REJECTION",
                f"{label} mutation rejected as {error.code}, expected {expected_code}",
            )
        else:
            raise ProbeLogError("E_SELFTEST_FALSE_GREEN", f"{label} marker mutation was accepted")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--expected-marker", required=True)
    parser.add_argument("--forbidden-marker", required=True)
    parser.add_argument("--expected-define", required=True)
    parser.add_argument("--forbidden-define", required=True)
    parser.add_argument("--make-rc", required=True, type=int)
    parser.add_argument("--exercise-fail-closed", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        text = args.log.read_text(encoding="utf-8")
        contract = ProbeContract(
            args.expected_marker,
            args.forbidden_marker,
            args.expected_define,
            args.forbidden_define,
            args.make_rc,
        )
        audit_text(text, contract)
        if args.exercise_fail_closed:
            exercise_fail_closed(text, contract)
    except (OSError, UnicodeError, ProbeLogError) as error:
        code = error.code if isinstance(error, ProbeLogError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"{MARKER} PASS marker={args.expected_marker} make_rc={args.make_rc} "
        "inner_pass=1 result_fail=1"
    )
    if args.exercise_fail_closed:
        print(f"{SELFTEST_MARKER} PASS missing=RED duplicate=RED forbidden=RED")


if __name__ == "__main__":
    main()
