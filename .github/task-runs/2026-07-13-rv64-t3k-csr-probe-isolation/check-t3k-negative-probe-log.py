#!/usr/bin/env python3
"""Fail-closed audit for the T3K CSR equivalence assertion-negative log."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
import re
import sys


MARKER = "[T3K-NEGATIVE-LOG-CHECK]"
SELFTEST_MARKER = "[T3K-NEGATIVE-LOG-SELFTEST]"
ASSERT_MARKER = "[CSR-LEGAL-VIEW-EQUIV]"
PREMISE_MARKER = "[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1"
INNER_PASS = "[PASS] tb_t3k_csr_equiv_negative"
RUNNER_REASON = "log contains an ERROR diagnostic"
ANSI_RE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x1b\x07]*(?:\x07|\x1b\\))")
ERROR_LINE_RE = re.compile(r"^ERROR:.*$", re.MULTILINE)
RESULT_FAIL_RE = re.compile(r"^\[RESULT\] FAIL status=([1-9][0-9]*)$", re.MULTILINE)


class LogError(RuntimeError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def require(condition: bool, code: str, message: str) -> None:
    if not condition:
        raise LogError(code, message)


@dataclass(frozen=True)
class Contract:
    compile_rc: int
    sim_rc: int
    classifier_rc: int


def audit_text(raw: str, contract: Contract) -> None:
    text = ANSI_RE.sub("", raw)
    require(contract.compile_rc == 0, "E_COMPILE_RC", f"compile_rc={contract.compile_rc}, wanted 0")
    require(contract.sim_rc == 0, "E_SIM_RC", f"sim_rc={contract.sim_rc}, wanted 0 so ERROR is the sole rejection cause")
    require(
        contract.classifier_rc == 1,
        "E_CLASSIFIER_RC",
        f"classifier_rc={contract.classifier_rc}, wanted semantic rejection status 1",
    )

    require(
        text.count(PREMISE_MARKER) == 1,
        "E_PREMISE_COUNT",
        f"non-vacuous premise marker count={text.count(PREMISE_MARKER)}, wanted 1",
    )
    require(
        text.count(ASSERT_MARKER) == 1,
        "E_ASSERT_MARKER_COUNT",
        f"assertion marker count={text.count(ASSERT_MARKER)}, wanted 1",
    )
    error_lines = ERROR_LINE_RE.findall(text)
    require(
        len(error_lines) == 1 and ASSERT_MARKER in error_lines[0],
        "E_ERROR_LINE_EXACT",
        f"expected exactly one ERROR line carrying {ASSERT_MARKER}, got {error_lines}",
    )
    require(
        text.splitlines().count(INNER_PASS) == 1,
        "E_INNER_PASS_COUNT",
        "negative harness must continue to one exact inner PASS after the assertion",
    )
    require(
        text.find(PREMISE_MARKER) < text.find(error_lines[0]) < text.find(INNER_PASS),
        "E_EVENT_ORDER",
        "expected premise -> assertion ERROR -> inner PASS order",
    )
    require(
        text.splitlines().count(RUNNER_REASON) == 1,
        "E_RUNNER_REASON",
        "module result checker must report the ERROR diagnostic exactly once",
    )
    extra_reasons = [
        line for line in text.splitlines()
        if line.startswith((
            "compile returned nonzero",
            "simulation returned nonzero",
            "log contains a FAIL marker",
            "log reports errors=",
            "missing exact PASS line",
            "source contains a nonzero",
        ))
    ]
    require(
        not extra_reasons,
        "E_EXTRA_RUNNER_REASON",
        f"ERROR diagnostic must be the sole module-runner rejection reason: {extra_reasons}",
    )
    require(
        len(RESULT_FAIL_RE.findall(text)) == 1,
        "E_RESULT_FAIL_COUNT",
        "wrapper must emit exactly one nonzero [RESULT] FAIL line",
    )
    require(
        text.splitlines().count("[RESULT] PASS") == 0,
        "E_RESULT_FALSE_GREEN",
        "negative evidence contains [RESULT] PASS",
    )
    compile_lines = [line for line in text.splitlines() if line.startswith("[COMPILE] ")]
    require(len(compile_lines) == 1, "E_COMPILE_LINE", f"compile line count={len(compile_lines)}, wanted 1")
    require(
        "-DOOO_ASSERT" in compile_lines[0]
        and "CsrFile.v" in compile_lines[0]
        and "tb-t3k-csr-equiv-negative.sv" in compile_lines[0],
        "E_COMPILE_PROVENANCE",
        f"compile line lacks assertion/source provenance: {compile_lines[0]}",
    )
    forbidden = (
        "[T3K-NEGATIVE-HARNESS-SETUP-ERROR]",
        "[T3K-NEGATIVE-HARNESS-PREMISE-ERROR]",
        "[T3K-SOURCE-CONTRACT] FAIL",
    )
    present = [item for item in forbidden if item in text]
    require(not present, "E_FORBIDDEN_MARKER", f"negative log contains harness/setup failures: {present}")


def exercise_fail_closed(text: str, contract: Contract) -> None:
    cases = (
        ("missing-assert", text.replace(ASSERT_MARKER, "[REMOVED-ASSERT]", 1), "E_ASSERT_MARKER_COUNT"),
        ("duplicate-assert", text + f"\nERROR: duplicate {ASSERT_MARKER}\n", "E_ASSERT_MARKER_COUNT"),
        ("missing-premise", text.replace(PREMISE_MARKER, "[REMOVED-PREMISE]", 1), "E_PREMISE_COUNT"),
        ("false-green", text.replace("[RESULT] FAIL status=1", "[RESULT] PASS", 1), "E_RESULT_FAIL_COUNT"),
        ("missing-reason", text.replace(RUNNER_REASON, "removed runner reason", 1), "E_RUNNER_REASON"),
    )
    for label, mutated, expected_code in cases:
        try:
            audit_text(mutated, contract)
        except LogError as error:
            require(
                error.code == expected_code,
                "E_SELFTEST_WRONG_REJECTION",
                f"{label} rejected as {error.code}, expected {expected_code}",
            )
        else:
            raise LogError("E_SELFTEST_FALSE_GREEN", f"{label} mutation was accepted")
    for label, mutated_contract, expected_code in (
        ("sim-nonzero", Contract(contract.compile_rc, 1, contract.classifier_rc), "E_SIM_RC"),
        ("classifier-input-error", Contract(contract.compile_rc, contract.sim_rc, 2), "E_CLASSIFIER_RC"),
    ):
        try:
            audit_text(text, mutated_contract)
        except LogError as error:
            require(
                error.code == expected_code,
                "E_SELFTEST_WRONG_REJECTION",
                f"{label} rejected as {error.code}, expected {expected_code}",
            )
        else:
            raise LogError("E_SELFTEST_FALSE_GREEN", f"{label} status mutation was accepted")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", required=True, type=Path)
    parser.add_argument("--compile-rc", required=True, type=int)
    parser.add_argument("--sim-rc", required=True, type=int)
    parser.add_argument("--classifier-rc", required=True, type=int)
    parser.add_argument("--exercise-fail-closed", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    contract = Contract(args.compile_rc, args.sim_rc, args.classifier_rc)
    try:
        text = args.log.read_text(encoding="utf-8")
        audit_text(text, contract)
        if args.exercise_fail_closed:
            exercise_fail_closed(text, contract)
    except (OSError, UnicodeError, LogError) as error:
        code = error.code if isinstance(error, LogError) else "E_IO"
        print(f"{MARKER} FAIL {code}: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(
        f"{MARKER} PASS assertion={ASSERT_MARKER} premise=reachable "
        f"compile_rc={args.compile_rc} sim_rc={args.sim_rc} classifier_rc={args.classifier_rc}"
    )
    if args.exercise_fail_closed:
        print(
            f"{SELFTEST_MARKER} PASS missing=RED duplicate=RED false_green=RED "
            "missing_reason=RED sim_nonzero=RED classifier_input_error=RED"
        )


if __name__ == "__main__":
    main()
