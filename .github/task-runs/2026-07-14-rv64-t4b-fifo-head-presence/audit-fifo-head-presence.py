#!/usr/bin/env python3
"""审计 T4B FIFO head presence 的源码拓扑，并用自变异证明门禁会拒错。"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


TASK_DIR = Path(__file__).resolve().parent
REPO_ROOT = TASK_DIR.parents[2]
DEFAULT_SOURCE = REPO_ROOT / "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v"


def has(pattern: str, text: str) -> bool:
    return re.search(pattern, text, flags=re.DOTALL) is not None


def audit(text: str) -> list[str]:
    errors: list[str] = []
    checks = {
        "registered_projection_declared": r"\breg\s+head_valid_q\s*;",
        "output_only_from_projection": r"assign\s+head_valid_o\s*=\s*head_valid_q\s*;",
        "reset_clears_projection": (
            r"if\s*\(rst\)\s*begin.*?count_q\s*<=\s*FIFO_COUNT_ZERO\s*;"
            r".*?head_valid_q\s*<=\s*1'b0\s*;"
        ),
        "clear_clears_projection": (
            r"else\s+if\s*\(clear_i\)\s*begin.*?count_q\s*<=\s*FIFO_COUNT_ZERO\s*;"
            r".*?head_valid_q\s*<=\s*1'b0\s*;"
        ),
        "enqueue_sets_projection": (
            r"2'b10\s*:\s*begin.*?count_q\s*<=\s*count_q\s*\+\s*FIFO_COUNT_ONE\s*;"
            r".*?head_valid_q\s*<=\s*1'b1\s*;.*?end"
        ),
        "pop_projects_post_occupancy": (
            r"2'b01\s*:\s*begin.*?count_q\s*<=\s*count_q\s*-\s*FIFO_COUNT_ONE\s*;"
            r".*?head_valid_q\s*<=\s*\(count_q\s*>\s*FIFO_COUNT_ONE\)\s*;.*?end"
        ),
        "swap_and_idle_hold_projection": (
            r"default\s*:\s*begin.*?count_q\s*<=\s*count_q\s*;"
            r".*?head_valid_q\s*<=\s*head_valid_q\s*;.*?end"
        ),
        "independent_equivalence_assertion": (
            r"head_valid_q\s*!==\s*\(count_q\s*!=\s*FIFO_COUNT_ZERO\)"
            r".*?\[T4B-FIFO-HEAD-PRESENCE\]"
        ),
        "underflow_checks_only_normal_event": (
            r"if\s*\(!rst\s*&&\s*!clear_i\s*&&\s*pop_i\s*&&"
            r"\s*\(count_q\s*==\s*FIFO_COUNT_ZERO\)\)"
        ),
        "overflow_checks_only_normal_event": (
            r"if\s*\(!rst\s*&&\s*!clear_i\s*&&\s*enqueue_i\s*&&\s*!pop_i\s*&&"
            r"\s*\(count_q\s*==\s*FETCH_PACKET_COUNT\[FETCH_COUNT_W-1:0\]\)\)"
        ),
        "action_controls_fail_closed_on_unknown": (
            r"clear_i\s*===\s*1'b0.*?clear_i\s*===\s*1'b1.*?"
            r"enqueue_i\s*===\s*1'b0.*?enqueue_i\s*===\s*1'b1.*?"
            r"pop_i\s*===\s*1'b0.*?pop_i\s*===\s*1'b1.*?"
            r"\[CONTRACT-FIFO-CONTROL-KNOWN\]"
        ),
    }
    for name, pattern in checks.items():
        if not has(pattern, text):
            errors.append(name)

    if has(r"assign\s+head_valid_o\s*=\s*\(?\s*count_q\s*!?=", text):
        errors.append("legacy_count_comparator_still_drives_output")
    if len(re.findall(r"assign\s+head_valid_o\s*=", text)) != 1:
        errors.append("head_valid_output_driver_count_not_one")
    return errors


def mutate_once(text: str, old: str, new: str, name: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"mutation {name}: expected one match, got {text.count(old)}")
    return text.replace(old, new, 1)


def run_self_test(text: str) -> dict[str, list[str]]:
    mutations = {
        "restore_count_comparator": mutate_once(
            text,
            "assign head_valid_o = head_valid_q;",
            "assign head_valid_o = (count_q != FIFO_COUNT_ZERO);",
            "restore_count_comparator",
        ),
        "enqueue_fails_to_set": mutate_once(
            text,
            "2'b10: begin\n          count_q <= count_q + FIFO_COUNT_ONE;\n"
            "          head_valid_q <= 1'b1;",
            "2'b10: begin\n          count_q <= count_q + FIFO_COUNT_ONE;\n"
            "          head_valid_q <= 1'b0;",
            "enqueue_fails_to_set",
        ),
        "pop_always_clears": mutate_once(
            text,
            "head_valid_q <= (count_q > FIFO_COUNT_ONE);",
            "head_valid_q <= 1'b0;",
            "pop_always_clears",
        ),
        "swap_drops_presence": mutate_once(
            text,
            "head_valid_q <= head_valid_q;",
            "head_valid_q <= 1'b0;",
            "swap_drops_presence",
        ),
        "remove_equivalence_guard": mutate_once(
            text,
            "if (!rst && (head_valid_q !== (count_q != FIFO_COUNT_ZERO))) begin",
            "if (1'b0) begin",
            "remove_equivalence_guard",
        ),
        "underflow_ignores_clear_priority": mutate_once(
            text,
            "if (!rst && !clear_i && pop_i && (count_q == FIFO_COUNT_ZERO)) begin",
            "if (!rst && pop_i && (count_q == FIFO_COUNT_ZERO)) begin",
            "underflow_ignores_clear_priority",
        ),
        "overflow_ignores_clear_priority": mutate_once(
            text,
            "if (!rst && !clear_i && enqueue_i && !pop_i &&",
            "if (!rst && enqueue_i && !pop_i &&",
            "overflow_ignores_clear_priority",
        ),
        "remove_control_knownness_guard": mutate_once(
            text,
            "$error(\"[CONTRACT-FIFO-CONTROL-KNOWN] FIFO action control contains X/Z\");",
            "$error(\"[MUTATED-FIFO-CONTROL-KNOWN] FIFO action control contains X/Z\");",
            "remove_control_knownness_guard",
        ),
    }
    results: dict[str, list[str]] = {}
    for name, mutated in mutations.items():
        mutation_errors = audit(mutated)
        if not mutation_errors:
            raise AssertionError(f"audit accepted mutation: {name}")
        results[name] = mutation_errors
    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    text = args.source.read_text(encoding="utf-8")
    errors = audit(text)
    report: dict[str, object] = {
        "source": str(args.source),
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
    }
    if args.self_test and not errors:
        report["rejected_mutations"] = run_self_test(text)
    rendered = json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
