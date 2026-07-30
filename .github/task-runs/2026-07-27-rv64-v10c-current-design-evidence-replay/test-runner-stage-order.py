#!/usr/bin/env python3
"""Fail closed if current-design replay publication order regresses."""

from __future__ import annotations

import pathlib
import re
import sys


RUNNER = pathlib.Path(__file__).with_name(
    "run-current-design-evidence-replay.sh"
)
REQUIRED_ORDER = (
    "control-event-module-aggregate",
    "functional-aggregate-current",
    "control-event-architecture",
    "candidate-and-census-current",
    "control-event-sq-retry",
    "control-event-gap-boundary",
    "control-event-index",
    "control-event-index-verify",
    "debt-ledger-current",
    "closed-evidence-currentness",
)


def stage_order(text: str) -> list[str]:
    return re.findall(
        r"^run_stage ([a-z0-9-]+)(?:\s|$)", text, re.MULTILINE
    )


def validate(stages: list[str]) -> None:
    missing = [stage for stage in REQUIRED_ORDER if stage not in stages]
    if missing:
        raise ValueError(f"missing required stages: {missing}")
    positions = [stages.index(stage) for stage in REQUIRED_ORDER]
    if positions != sorted(positions):
        raise ValueError(
            "current-design publication order is invalid: "
            + " -> ".join(REQUIRED_ORDER)
        )


def main() -> int:
    live_stages = stage_order(RUNNER.read_text(encoding="utf-8"))
    validate(live_stages)

    negative_fixtures: list[tuple[str, list[str]]] = []

    # The candidate must read the newly published architecture manifest.
    candidate_before_architecture = live_stages.copy()
    candidate_before_architecture.remove("candidate-and-census-current")
    architecture_index = candidate_before_architecture.index(
        "control-event-architecture"
    )
    candidate_before_architecture.insert(
        architecture_index, "candidate-and-census-current"
    )
    negative_fixtures.append(
        ("candidate-before-architecture", candidate_before_architecture)
    )

    # The debt ledger and closed-evidence audit may consume the index only
    # after both publication and explicit verification have completed.
    missing_index_verify = live_stages.copy()
    missing_index_verify.remove("control-event-index-verify")
    negative_fixtures.append(("missing-index-verify", missing_index_verify))

    verify_after_ledger = live_stages.copy()
    verify_after_ledger.remove("control-event-index-verify")
    ledger_index = verify_after_ledger.index("debt-ledger-current")
    verify_after_ledger.insert(
        ledger_index + 1, "control-event-index-verify"
    )
    negative_fixtures.append(("verify-after-ledger", verify_after_ledger))

    for label, negative in negative_fixtures:
        try:
            validate(negative)
        except ValueError:
            print(f"[V10C-STAGE-ORDER-NEGATIVE] {label} rejected")
        else:
            print(
                "[V10C-STAGE-ORDER-FAIL] "
                f"negative fixture accepted label={label}"
            )
            return 1

    print(
        "[V10C-STAGE-ORDER-PASS] module-aggregate -> functional-aggregate "
        "-> architecture -> candidate/census -> SQ-retry binding -> "
        "GAP audit -> index-build -> index-verify -> ledger -> currentness"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
