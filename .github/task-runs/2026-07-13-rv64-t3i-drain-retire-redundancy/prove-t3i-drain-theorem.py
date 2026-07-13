#!/usr/bin/env python3
"""Prove the legal-domain ROB-empty/retire-count implication used by T3I."""

from __future__ import annotations

import itertools
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[T3I-DRAIN-PROOF] FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def require(pattern: str, text: str, label: str) -> None:
    if re.search(pattern, text, re.MULTILINE | re.DOTALL) is None:
        fail(f"RTL premise missing: {label}")


def assignment_rhs(signal: str, text: str) -> str:
    """Return one continuous-assignment RHS without crossing its semicolon."""

    starts = list(
        re.finditer(
            rf"^[ \t]*assign[ \t]+{re.escape(signal)}[ \t]*=",
            text,
            re.MULTILINE,
        )
    )
    if len(starts) != 1:
        fail(f"expected exactly one assignment for {signal}, found {len(starts)}")
    rhs_start = starts[0].end()
    rhs_end = text.find(";", rhs_start)
    if rhs_end < 0:
        fail(f"unterminated assignment for {signal}")
    return text[rhs_start:rhs_end]


def strip_balanced_outer_parens(expression: str) -> str:
    """Strip only parentheses that enclose the complete expression."""

    result = expression.strip()
    while result.startswith("("):
        depth = 0
        matching_index = -1
        for index, char in enumerate(result):
            if char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth < 0:
                    fail("unbalanced parentheses in continuous assignment")
                if depth == 0:
                    matching_index = index
                    break
        if matching_index < 0:
            fail("unbalanced parentheses in continuous assignment")
        if matching_index != len(result) - 1:
            break
        result = result[1:-1].strip()
    return result


def top_level_logical_conjuncts(signal: str, expression: str) -> list[str]:
    """Fail closed unless the assignment RHS is a top-level pure ``&&`` tree.

    Leaves may contain parenthesized expressions, but retaining the textual
    count guard while appending ``|| 1'b1`` must not satisfy the theorem
    premise.
    """

    text = strip_balanced_outer_parens(expression)
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack: list[str] = []
    conjuncts: list[str] = []
    start = 0
    index = 0
    while index < len(text):
        char = text[index]
        if char in pairs:
            stack.append(pairs[char])
            index += 1
            continue
        if char in pairs.values():
            if not stack or stack.pop() != char:
                fail(f"{signal} has unbalanced delimiters")
            index += 1
            continue
        if not stack:
            token = text[index : index + 2]
            if token == "&&":
                conjunct = text[start:index].strip()
                if not conjunct:
                    fail(f"{signal} has an empty top-level conjunct")
                conjuncts.append(conjunct)
                index += 2
                start = index
                continue
            if token == "||":
                fail(
                    f"{signal} contains top-level logical OR; "
                    "the count guard is not guaranteed necessary"
                )
            if char in "?:":
                fail(
                    f"{signal} contains a top-level ternary operator; "
                    "the count guard is not guaranteed necessary"
                )
            if char in "|&":
                fail(f"{signal} contains a non-logical top-level operator")
            if char == '"':
                fail(f"{signal} contains an unsupported string literal")
        index += 1
    if stack:
        fail(f"{signal} has unbalanced delimiters")
    final = text[start:].strip()
    if not final:
        fail(f"{signal} has an empty final top-level conjunct")
    conjuncts.append(final)
    if len(conjuncts) < 2:
        fail(f"{signal} is not a top-level logical conjunction")
    return conjuncts


def canonical_conjunct(expression: str) -> str:
    """Normalize one isolated conjunct for an exact premise check."""

    return re.sub(r"\s+", "", strip_balanced_outer_parens(expression))


def require_exact_top_level_conjunct(
    signal: str,
    conjuncts: list[str],
    expected: str,
    label: str,
) -> None:
    matches = [
        item for item in conjuncts if canonical_conjunct(item) == expected
    ]
    if len(matches) != 1:
        fail(
            f"RTL premise missing: {label} must be exactly one "
            f"top-level && conjunct (found {len(matches)})"
        )


def decimal_define(name: str, text: str) -> int:
    matches = re.findall(
        rf"^\s*`define\s+{re.escape(name)}\s+(\d+)\s*(?://.*)?$",
        text,
        re.MULTILINE,
    )
    if len(matches) != 1:
        fail(f"expected exactly one decimal `define {name}, found {len(matches)}")
    return int(matches[0])


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: prove-t3i-drain-theorem.py REPO_ROOT")
    root = Path(sys.argv[1]).resolve()
    rob = (root / "npc/rv64/vsrc/writeback/OooRob.v").read_text()
    core = (root / "npc/rv64/vsrc/execute/OooAluCoreSlice.v").read_text()
    defines = (root / "npc/rv64/vsrc/include/define.v").read_text()

    commit0_conjuncts = top_level_logical_conjuncts(
        "commit0_fire_w", assignment_rhs("commit0_fire_w", rob)
    )
    require_exact_top_level_conjunct(
        "commit0_fire_w",
        commit0_conjuncts,
        "count_q!={ROB_COUNT_W{1'b0}}",
        "commit0 non-empty count guard",
    )
    commit1_conjuncts = top_level_logical_conjuncts(
        "commit1_fire_w", assignment_rhs("commit1_fire_w", rob)
    )
    require_exact_top_level_conjunct(
        "commit1_fire_w",
        commit1_conjuncts,
        "commit0_fire_w",
        "commit1 implies commit0",
    )
    require(
        r"^\s*commit0_fire_w\s*$",
        assignment_rhs("commit0_valid_o", rob),
        "commit0 output identity",
    )
    require(
        r"^\s*commit1_fire_w\s*$",
        assignment_rhs("commit1_valid_o", rob),
        "commit1 output identity",
    )
    require(
        r"^\s*count_q\s*$",
        assignment_rhs("count_o", rob),
        "ROB count output identity",
    )
    require(
        r"^\s*\{1'b0,\s*commit0_valid_o\}\s*"
        r"\+\s*\{1'b0,\s*commit1_valid_o\}\s*$",
        assignment_rhs("retire_count_o", core),
        "core retire count is the two ROB commit valids",
    )
    require(
        r"parameter\s+ROB_ENTRIES\s*=\s*\(1\s*<<\s*`OOO_ROB_INDEX_W\)",
        rob,
        "default ROB entries derive from OOO_ROB_INDEX_W",
    )

    rob_index_w = decimal_define("OOO_ROB_INDEX_W", defines)
    rob_entries = 1 << rob_index_w

    cases = 0
    for count in range(rob_entries + 1):
        for commit_ready, head_ready, lane1_ready in itertools.product(
            (False, True), repeat=3
        ):
            commit0 = commit_ready and count != 0 and head_ready
            commit1 = commit0 and count > 1 and lane1_ready
            retire_count = int(commit0) + int(commit1)
            if count == 0 and retire_count != 0:
                fail("counterexample to rob_count==0 -> retire_count==0")

            for issue_empty, synth_ret_clear, synth_drop_clear, mem_quiet in (
                itertools.product((False, True), repeat=4)
            ):
                old_drained = (
                    count == 0
                    and issue_empty
                    and retire_count == 0
                    and synth_ret_clear
                    and synth_drop_clear
                    and mem_quiet
                )
                simplified_drained = (
                    count == 0
                    and issue_empty
                    and synth_ret_clear
                    and synth_drop_clear
                    and mem_quiet
                )
                if old_drained != simplified_drained:
                    fail("legal-domain old/new drain formulas differ")
                cases += 1

    print(
        "[T3I-DRAIN-PROOF] PASS: RTL premises present; "
        f"commit0 top-level conjuncts={len(commit0_conjuncts)}; "
        f"commit1 top-level conjuncts={len(commit1_conjuncts)}; "
        f"ROB entries={rob_entries}; legal-domain equivalence cases={cases}"
    )


if __name__ == "__main__":
    main()
